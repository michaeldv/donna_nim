# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned, strutils, re
import types, data, params, piece, utils, position

# Bits 00:00:00:FF => Source square (0 .. 63).
# Bits 00:00:FF:00 => Destination square (0 .. 63).
# Bits 00:0F:00:00 => Piece making the move.
# Bits 00:F0:00:00 => Captured piece if any.
# Bits 0F:00:00:00 => Promoted piece if any.
# Bits F0:00:00:00 => Castle and en-passant flags.
const
  xCapture   = 0x00F0_0000'u32
  xPromo     = 0x0F00_0000'u32
  xCastle    = 0x1000_0000'u32
  xEnpassant = 0x2000_0000'u32

# Moving pianos is dangerous. Moving pianos are dangerous.
#------------------------------------------------------------------------------
proc newMove*(p: ptr Position, fr, to: int): Move =
  let piece = p.pieces[fr]
  var capture = p.pieces[to]

  if (p.enpassant != 0) and (to == int(p.enpassant)) and piece.isPawn:
    capture = pawn(piece.color xor 1)

  return Move(uint32(fr) or uint32(to shl 8) or (uint32(piece) shl 16) or (uint32(capture) shl 20))

#------------------------------------------------------------------------------
proc newEnpassant*(p: ptr Position, fr, to: int): Move =
  return Move(uint32(fr) or uint32(to shl 8) or (uint32(p.pieces[fr]) shl 16) or xEnpassant)

#------------------------------------------------------------------------------
proc newCastle*(p: ptr Position, fr, to: int): Move =
  return Move(uint32(fr) or uint32(to shl 8) or (uint32(p.pieces[fr]) shl 16) or xCastle)

#------------------------------------------------------------------------------
proc newPawnMove*(p: ptr Position, fr, to: int): Move =
  if abs(fr - to) == 16:
    # Check if pawn jump causes en-passant. This is done by verifying
    # whether enemy pawns occupy squares ajacent to the target square.
    let pawns = p.outposts[pawn(p.color xor 1)]
    if (pawns and maskIsolated[col(to)] and maskRank[row(to)]) != 0:
      return newEnpassant(p, fr, to)

  return newMove(p, fr, to)

#------------------------------------------------------------------------------
proc fr*(m: Move): int {.inline.} =
  return m and 0xFF

#------------------------------------------------------------------------------
proc to*(m: Move): int {.inline.} =
  return (m shr 8) and 0xFF

#------------------------------------------------------------------------------
proc color*(m: Move): uint8 {.inline.} =
  return (m shr 16) and 1

#------------------------------------------------------------------------------
proc piece*(m: Move): Piece {.inline.} =
  return Piece((m shr 16) and 0x0F)

#------------------------------------------------------------------------------
proc capture*(m: Move): Piece {.inline.} =
  return Piece((m shr 20) and 0x0F)

#------------------------------------------------------------------------------
proc split*(m: Move): MoveInfo =
  return (m.fr, m.to, m.piece, m.capture)

#------------------------------------------------------------------------------
proc promo*(m: Move): Piece {.inline.} =
  return Piece((m shr 24) and 0x0F)

#------------------------------------------------------------------------------
proc promote*(m: Move, kind: uint8): Move =
  let piece = Piece(kind or m.color)
  return m or Move(uint32(piece) shl 24)

#------------------------------------------------------------------------------
proc newPromotion*(p: ptr Position, fr, to: int): array[4, Move] =
  return [
    newMove(p, fr, to).promote(Queen),
    newMove(p, fr, to).promote(Rook),
    newMove(p, fr, to).promote(Bishop),
    newMove(p, fr, to).promote(Knight),
  ]

#------------------------------------------------------------------------------
proc isCastle*(m: Move): bool {.inline.} =
  return (m and xCastle) != 0

#------------------------------------------------------------------------------
proc isCapture*(m: Move): bool {.inline.} =
  return (m and xCapture) != 0

#------------------------------------------------------------------------------
proc isEnpassant*(m: Move): bool {.inline.} =
  return (m and xEnpassant) != 0

#------------------------------------------------------------------------------
proc isPromo*(m: Move): bool {.inline.} =
  return (m and xPromo) != 0

#------------------------------------------------------------------------------
proc isQuiet*(m: Move): bool {.inline.} =
  ## Returns true if the move doesn't change material balance.
  return (m and (xCapture or xPromo)) == 0

#------------------------------------------------------------------------------
proc value*(m: Move): int =
  ## Capture value based on most valueable victim/least valueable attacker.
  result = pieceValue[m.capture] - m.piece.kind
  if m.isEnpassant:
    result += valuePawn.midgame
  elif m.isPromo:
    result += pieceValue[m.promo] - valuePawn.midgame

#------------------------------------------------------------------------------
proc newMoveFromNotation*(p: ptr Position, e2e4: string): Move =
  ## Decodes a string in coordinate notation and returns a move. The string is
  ## expected to be either 4 or 5 characters long (with promotion).
  let fr = square(e2e4[1].ord - '1'.ord, e2e4[0].ord - 'a'.ord)
  let to = square(e2e4[3].ord - '1'.ord, e2e4[2].ord - 'a'.ord)

  # Check if this is a castle.
  if p.pieces[fr].isKing and (abs(fr - to) == 2):
    return newCastle(p, fr, to)

  # Special handling for pawn pushes because they might cause en-passant
  # and result in promotion.
  if p.pieces[fr].isPawn:
    var move = newPawnMove(p, fr, to)
    if len(e2e4) > 4:
      case e2e4[4]
        of 'q', 'Q':
          move = move.promote(Queen)
        of 'r', 'R':
          move = move.promote(Rook)
        of 'b', 'B':
          move = move.promote(Bishop)
        of 'n', 'N':
          move = move.promote(Knight)
        else:
          discard
      return move

  return newMove(p, fr, to)

#------------------------------------------------------------------------------
proc newMoveFromString*(p: ptr Position, e2e4: string): Move =
  ## Decodes a string in long algebraic notation and returns a move. All invalid
  ## moves are discarded and returned as Move(0).
  var arr: array[6, string]
  if e2e4.match(re"([KkQqRrBbNn]?)([a-h])([1-8])[-x]?([a-h])([1-8])([QqRrBbNn]?)\+?[!\?]{0,2}", arr):
    let letter = arr[0]
    if len(letter) > 0:
      var piece: Piece

      # Validate optional piece character to make sure the actual piece it
      # represents is there.
      case letter
        of "K", "k":
          piece = king(p.color)
        of "Q", "q":
          piece = queen(p.color)
        of "R", "r":
          piece = rook(p.color)
        of "B", "b":
          piece = bishop(p.color)
        of "N", "n":
          piece = knight(p.color)
        else:
          discard
      let square = square(arr[2][0].ord - '1'.ord, arr[1][0].ord - 'a'.ord)
      if p.pieces[square] != piece:
        return Move(0)
    return newMoveFromNotation(p, arr[1] & arr[2] & arr[3] & arr[4] & arr[5])

  # Special castle move notation.
  if (e2e4 == "0-0") or (e2e4 == "0-0-0"):
    let (kingside, queenside) = p.canCastle(p.color)
    if (e2e4 == "0-0") and kingside:
      let fr = int(p.king[p.color])
      let to = G1 + int(p.color) * A8
      return newCastle(p, fr, to)
    if (e2e4 == "0-0-0") and queenside:
      let fr = int(p.king[p.color])
      let to = C1 + int(p.color) * A8
      return newCastle(p, fr, to)

  return Move(0)
  
#   # Before returning the move make sure it is valid in current position.
#   defer func() {
#     gen := NewMoveGen(p).generateAllMoves().validOnly()
#     validMoves = gen.allMoves()
#     if move != Move(0) && !gen.amongValid(move) {
#       move = Move(0)
#     }
#   }()

#------------------------------------------------------------------------------
proc notation*(m: Move): string =
  ## Returns string representation of the move in long coordinate notation as
  ## expected by UCI, ex. `g1f3`, `e4d5` or `h7h8q`.
  let (fr, to, _, _) = m.split
  result = ""
  result.add((col(fr) + 'a'.ord).chr)
  result.add((row(fr) + '1'.ord).chr)
  result.add((col(to) + 'a'.ord).chr)
  result.add((row(to) + '1'.ord).chr)
  if m.isPromo:
    result.add((m.promo.chr.ord + 32).chr)

#------------------------------------------------------------------------------
proc toString*(m: Move): string =
  ## Returns string representation of the move in long algebraic notation using
  ## ASCII characters only.
  let (fr, to, piece, capture) = m.split

  if m.isCastle:
    if to > fr:
      return "0-0"
    else:
      return "0-0-0"

  result = ""
  if not piece.isPawn:
    result.add(piece.chr.toUpper)
  result.add((col(fr) + 'a'.ord).chr)
  result.add((row(fr) + '1'.ord).chr)
  if capture == Piece(0):
    result.add('-')
  else:
    result.add('x')
  result.add((col(to) + 'a'.ord).chr)
  result.add((row(to) + '1'.ord).chr)
  if m.isPromo:
    result.add(m.promo.chr.toUpper)
