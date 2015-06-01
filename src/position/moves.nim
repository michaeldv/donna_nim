# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned
import types, data, init, bitmask, piece, move, score, position, position/targets

#------------------------------------------------------------------------------
proc movePiece(self: ptr Position, piece: Piece, fr, to: int): ptr Position {.discardable.} =
  self.pieces[fr] = 0
  self.pieces[to] = piece
  self.outposts[piece] = self.outposts[piece] xor (bit[fr] or bit[to])
  self.outposts[piece.color] = self.outposts[piece.color] xor (bit[fr] or bit[to])

  # Update position's hash values.
  let random = piece.polyglot(fr) xor piece.polyglot(to)
  self.id = self.id xor random
  if piece.isPawn:
    self.pawnId = self.pawnId xor random

  # Update positional score.
  self.tally.subtract(pst[piece][fr]).add(pst[piece][to])

  return self

#------------------------------------------------------------------------------
proc promotePawn(self: ptr Position, pawn: Piece, fr, to: int, promo: Piece): ptr Position {.discardable.} =
  self.pieces[fr] = 0
  self.pieces[to] = promo
  self.outposts[pawn] = self.outposts[pawn] xor bit[fr]
  self.outposts[promo] = self.outposts[promo] xor bit[to]
  self.outposts[pawn.color] = self.outposts[pawn.color] xor (bit[fr] or bit[to])

  # Update position's hash values and material balance.
  let random = pawn.polyglot(fr)
  self.id = self.id xor (random xor promo.polyglot(to))
  self.pawnId = self.pawnId xor random
  self.balance += materialBalance[promo] - materialBalance[pawn]

  # Update positional score.
  self.tally.subtract(pst[pawn][fr]).add(pst[promo][to])

  return self

#------------------------------------------------------------------------------
proc capturePiece(self: ptr Position, capture: Piece, fr, to: int): ptr Position {.discardable.} =
  self.outposts[capture] = self.outposts[capture] xor bit[to]
  self.outposts[capture.color] = self.outposts[capture.color] xor bit[to]

  # Update position's hash values and material balance.
  let random = capture.polyglot(to)
  self.id = self.id xor random
  if capture.isPawn:
    self.pawnId = self.pawnId xor random
  self.balance -= materialBalance[capture]

  # Update positional score.
  self.tally.subtract(pst[capture][to])

  return self

#------------------------------------------------------------------------------
proc captureEnpassant(self: ptr Position, capture: Piece, fr, to: int): ptr Position {.discardable.} =
  let enpassant = to - eight[capture.color xor 1]

  self.pieces[enpassant] = 0
  self.outposts[capture] = self.outposts[capture] xor bit[enpassant]
  self.outposts[capture.color] = self.outposts[capture.color] xor bit[enpassant]

  # Update position's hash values and material balance.
  let random = capture.polyglot(enpassant)
  self.id = self.id xor random
  self.pawnId = self.pawnId xor random
  self.balance -= materialBalance[capture]

  # Update positional score.
  self.tally.subtract(pst[capture][enpassant])

  return self

#------------------------------------------------------------------------------
proc makeMove*(self: ptr Position, move: Move): ptr Position =
  let color = move.color
  let (fr, to, piece, capture) = move.split

  # Copy over the contents of previous tree node to the current one.
  inc(node)
  tree[node] = self[] # => tree[node] = tree[node - 1]
  result = tree[node].addr

  result.enpassant = 0
  result.reversible = true

  if capture != 0:
    result.reversible = false
    if (to != 0) and (to == int(self.enpassant)):
      result.captureEnpassant(pawn(color xor 1), fr, to)
      result.id = result.id xor hashEnpassant[int(self.enpassant and 7)] # self.enpassant column.
    else:
      result.capturePiece(capture, fr, to)

  let promo = move.promo
  if promo == 0:
    result.movePiece(piece, fr, to)

    if piece.isKing:
      result.king[color] = uint8(to)
      if move.isCastle:
        result.reversible = false
        case to
          of G1:
            result.movePiece(Rook, H1, F1)
          of C1:
            result.movePiece(Rook, A1, D1)
          of G8:
            result.movePiece(BlackRook, H8, F8)
          of C8:
            result.movePiece(BlackRook, A8, D8)
          else:
            discard
    elif piece.isPawn:
      result.reversible = false
      if move.isEnpassant:
        result.enpassant = uint8(fr + eight[color]) # Save the en-passant square.
        result.id = result.id xor hashEnpassant[int(result.enpassant and 7)]
  else:
    result.reversible = false
    result.promotePawn(piece, fr, to, promo)

  # Set up the board bitmask, update castle rights, finish off incremental
  # id value, and flip the color.
  result.board = result.outposts[White] or result.outposts[Black]
  result.castles = result.castles and (castleRights[fr] and castleRights[to])
  result.id = result.id xor (hashCastle[self.castles] xor hashCastle[result.castles])
  result.id = result.id xor polyglotRandomWhite
  result.color = result.color xor 1 # <-- Flip side to move.

#------------------------------------------------------------------------------
proc makeNullMove*(self: ptr Position): ptr Position {.discardable.} =
  ## Makes "null" move by copying over previous node position (i.e. preserving all pieces
  ## intact) and flipping the color.
  inc(node)
  tree[node] = self[] # => tree[node] = tree[node - 1]
  result = tree[node].addr

  # Flipping side to move obviously invalidates the enpassant square.
  if result.enpassant != 0:
    result.id = result.id xor hashEnpassant[int(result.enpassant and 7)]
    result.enpassant = 0

    result.id = result.id xor polyglotRandomWhite
    result.color = result.color xor 1 # <-- Flip side to move.

#------------------------------------------------------------------------------
proc undoLastMove*(self: ptr Position): ptr Position {.discardable.} =
  ## Restores previous position effectively taking back the last move made.
  if node > 0:
    dec(node)
  return tree[node].addr

#------------------------------------------------------------------------------
proc undoNullMove*(self: ptr Position): ptr Position {.discardable.} =
  self.id = self.id xor polyglotRandomWhite
  self.color = self.color xor 1
  return self.undoLastMove

#------------------------------------------------------------------------------
proc isInCheck*(self: ptr Position, color: uint8): bool =
  return self.isAttacked(color xor 1, int(self.king[color]))

#------------------------------------------------------------------------------
proc isNull*(self: ptr Position): bool =
  return (node > 0) and (tree[node].board == tree[node - 1].board)

#------------------------------------------------------------------------------
proc fifty*(self: ptr Position): bool =
  if node < 100:
    return false

  var count = 0
  for previous in countdown(node - 1, 0):
    if not tree[previous].reversible:
      break
    inc(count)
    if count >= 100:
      break

  return count >= 100

#------------------------------------------------------------------------------
proc repetition*(self: ptr Position): bool =
  if (not self.reversible) or (node < 1):
    return false

  for previous in countdown(node - 1, 0):
    if not tree[previous].reversible:
      return false
    if tree[previous].id == self.id:
      return true

  return false

#------------------------------------------------------------------------------
proc thirdRepetition*(self: ptr Position): bool =
  if (not self.reversible) or (node < 4):
    return false

  var repetitions = 1
  for previous in countdown(node - 2, 0, 2):
    if (not tree[previous].reversible) or (not tree[previous + 1].reversible):
      return false
    if tree[previous].id == self.id:
      inc(repetitions)
      if repetitions == 3:
        return true

  return false

#------------------------------------------------------------------------------
proc isValid*(self: ptr Position, move: Move, pins: Bitmask): bool =
  ## Returns true if *non-evasion* move is valid, i.e. it is possible to make
  ## the move in current position without violating chess rules. If the king is
  ## in check the generator is expected to generate valid evasions where extra
  ## validation is not needed.
  let color = move.color # TODO: make color part of move split.
  let (fr, to, piece, capture) = move.split

  # For rare en-passant pawn captures we validate the move by actually
  # making it, and then taking it back.
  if (self.enpassant != 0) and (to == int(self.enpassant)) and capture.isPawn:
    let position = self.makeMove(move)
    result = not position.isInCheck(color)
    position.undoLastMove()
    return result

  # King's move is valid when a) the move is a castle or b) the destination
  # square is not being attacked by the opponent.
  if piece.isKing:
    return move.isCastle or (not self.isAttacked(color xor 1, to))

  proc between(fr, to, square: int): bool =
    # Returns true if the square resides between two other squares on the same line
    # or diagonal, including edge squares. For example, between(A1, H8, C3) is true.
    return (maskStraight[fr][to] or maskDiagonal[fr][to]).on(square)

  # For all other peices the move is valid when it doesn't cause a
  # check. For pinned sliders this includes moves along the pinning
  # file, rank, or diagonal.
  return (pins == 0) or pins.off(fr) or between(fr, to, int(self.king[color]))

#------------------------------------------------------------------------------
proc pinnedMask*(self: ptr Position, square: uint8): Bitmask =
  ## Returns a bitmask of all pinned pieces preventing a check for the king on
  ## given square. The color of the pieces match the color of the king.
  let color = self.pieces[square].color
  let enemy = color xor 1

  var attackers = (self.outposts[bishop(enemy)] or self.outposts[queen(enemy)]) and bishopMagicMoves[square][0]
  attackers = attackers or ((self.outposts[rook(enemy)] or self.outposts[queen(enemy)]) and rookMagicMoves[square][0])

  while attackers != 0:
    let attackSquare = attackers.pop
    let blockers = maskBlock[square][attackSquare] and (not bit[attackSquare]) and self.board

    if blockers.count == 1:
      result = result or (blockers and self.outposts[color]) # Only friendly pieces are pinned.
