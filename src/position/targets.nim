# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned
import types, data, init, bitmask, piece

#------------------------------------------------------------------------------
proc bishopMovesAt*(self: ptr Position, square: int, board: Bitmask): Bitmask =
  ## Returns a bitmask of possible Bishop moves from the given square wherees
  ## other pieces on the board are represented by the explicit parameter.  
  let magic = ((bishopMagic[square].mask and board) * bishopMagic[square].magic) shr 55
  return bishopMagicMoves[square][magic]

#------------------------------------------------------------------------------
proc rookMovesAt*(self: ptr Position, square: int, board: Bitmask): Bitmask =
  ## Returns a bitmask of possible Rook moves from the given square wherees other
  ## pieces on the board are represented by the explicit parameter.
  let magic = ((rookMagic[square].mask and board) * rookMagic[square].magic) shr 52
  return rookMagicMoves[square][magic]

#------------------------------------------------------------------------------
proc bishopMoves*(self: ptr Position, square: int): Bitmask =
  ## Returns a bitmask of possible Bishop moves from the given square.
  return self.bishopMovesAt(square, self.board)

#------------------------------------------------------------------------------
proc rookMoves*(self: ptr Position, square: int): Bitmask =
  ## Returns a bitmask of possible Rook moves from the given square.
  return self.rookMovesAt(square, self.board)

#------------------------------------------------------------------------------
proc attacksFor*(self: ptr Position, square: int, piece: Piece): Bitmask =
  case Piece(piece.kind)
    of Pawn:
      return pawnMoves[piece.color][square]
    of Knight:
      return knightMoves[square]
    of Bishop:
      return self.bishopMoves(square)
    of Rook:
      return self.rookMoves(square)
    of Queen:
      return self.bishopMoves(square) or self.rookMoves(square)
    of King:
      return kingMoves[square]
    else:
      discard
  return Bitmask(0)

#------------------------------------------------------------------------------
proc attacks*(self: ptr Position, square: int): Bitmask =
  return self.attacksFor(square, self.pieces[square])

#------------------------------------------------------------------------------
proc xrayAttacksFor*(self: ptr Position, square: int, piece: Piece): Bitmask =
  let color = piece.color

  case Piece(piece.kind)
    of Bishop:
      let board = self.board xor self.outposts[queen(color)]
      return self.bishopMovesAt(square, board)
    of Rook:
      let board= self.board xor self.outposts[rook(color)] xor self.outposts[queen(color)]
      return self.rookMovesAt(square, board)
    else:
      discard

  return self.attacksFor(square, piece)

#------------------------------------------------------------------------------
proc xrayAttacks*(self: ptr Position, square: int): Bitmask =
  return self.xrayAttacksFor(square, self.pieces[square])

#------------------------------------------------------------------------------
proc targetsFor*(self: ptr Position, square: int, piece: Piece): Bitmask =
  let color = piece.color

  if piece.isPawn:
    # Start with one square push, then try the second square.
    let empty = not self.board

    if color == White:
      result = result or ((bit[square] shl 8) and empty)
      result = result or ((result shl 8) and empty and maskRank[3])
    else:
      result = result or ((bit[square] shr 8) and empty)
      result = result or ((result shr 8) and empty and maskRank[4])

    result = result or (pawnMoves[color][square] and self.outposts[color xor 1])

    # If the last move set the en-passant square and it is diagonally adjacent
    # to the current pawn, then add en-passant to the pawn's attack targets.
    if (self.enpassant != 0) and maskPawn[color][self.enpassant].on(square):
      result = result or bit[self.enpassant]

  else:
    result = self.attacksFor(square, piece) and (not self.outposts[color])

#------------------------------------------------------------------------------
proc targets*(self: ptr Position, square: int): Bitmask =
  return self.targetsFor(square, self.pieces[square])

#------------------------------------------------------------------------------
proc pawnAttacks*(self: ptr Position, color: uint8): Bitmask =
  if color == White:
    result = (self.outposts[Pawn] and (not maskFile[0])) shl 7
    result = result or ((self.outposts[Pawn] and (not maskFile[7])) shl 9)
  else:
    result = (self.outposts[BlackPawn] and (not maskFile[0])) shr 9
    result = result or ((self.outposts[BlackPawn] and (not maskFile[7])) shr 7)

#------------------------------------------------------------------------------
proc knightAttacks*(self: ptr Position, color: uint8): Bitmask =
  var outposts = self.outposts[knight(color)]
  while outposts != 0:
    result = result or knightMoves[outposts.pop]

#------------------------------------------------------------------------------
proc bishopAttacks*(self: ptr Position, color: uint8): Bitmask =
  var outposts = self.outposts[bishop(color)]
  while outposts != 0:
    result = result or self.bishopMoves(outposts.pop)

#------------------------------------------------------------------------------
proc rookAttacks*(self: ptr Position, color: uint8): Bitmask =
  var outposts = self.outposts[rook(color)]
  while outposts != 0:
    result = result or self.rookMoves(outposts.pop)

#------------------------------------------------------------------------------
proc queenAttacks*(self: ptr Position, color: uint8): Bitmask =
  var outposts = self.outposts[queen(color)]
  while outposts != 0:
    let square = outposts.pop
    result = result or (self.rookMoves(square) or self.bishopMoves(square))

#------------------------------------------------------------------------------
proc kingAttacks*(self: ptr Position, color: uint8): Bitmask =
  return kingMoves[self.king[color]]

#------------------------------------------------------------------------------
proc allAttacks*(self: ptr Position, color: uint8): Bitmask =
  result = self.pawnAttacks(color) or self.knightAttacks(color) or self.kingAttacks(color)

  var outposts = self.outposts[bishop(color)] or self.outposts[queen(color)]
  while outposts != 0:
    result = result or self.bishopMoves(outposts.pop)

  outposts = self.outposts[rook(color)] or self.outposts[queen(color)]
  while outposts != 0:
    result = result or self.rookMoves(outposts.pop)

#------------------------------------------------------------------------------
proc attackers*(self: ptr Position, color: uint8, square: int, board: Bitmask): Bitmask =
  ## Returns a bitmask of pieces that attack given square. The resulting bitmask
  ## only counts pieces of requested color.
  ##
  ## This method is used in static exchange evaluation so instead of using current
  ## board bitmask (self.board) we pass the one that gets continuously updated during
  ## the evaluation.
  result = knightMoves[square] and self.outposts[knight(color)]
  result = result or (maskPawn[color][square] and self.outposts[pawn(color)])
  result = result or (kingMoves[square] and self.outposts[king(color)])
  result = result or (self.rookMovesAt(square, board) and (self.outposts[rook(color)] or self.outposts[queen(color)]))
  result = result or (self.bishopMovesAt(square, board) and (self.outposts[bishop(color)] or self.outposts[queen(color)]))

#------------------------------------------------------------------------------
proc isAttacked*(self: ptr Position, color: uint8, square: int): bool =
  return ((knightMoves[square] and self.outposts[knight(color)]) != 0) or
         ((maskPawn[color][square] and self.outposts[pawn(color)]) != 0) or
         ((kingMoves[square] and self.outposts[king(color)]) != 0) or
         ((self.rookMoves(square) and (self.outposts[rook(color)] or self.outposts[queen(color)])) != 0) or
         ((self.bishopMoves(square) and (self.outposts[bishop(color)] or self.outposts[queen(color)])) != 0)

#------------------------------------------------------------------------------
proc strongestPiece*(self: ptr Position, color: uint8, targets: Bitmask): Piece =
  if (targets and self.outposts[queen(color)]) != 0:
    return queen(color)
  if (targets and self.outposts[rook(color)]) != 0:
    return rook(color)
  if (targets and self.outposts[bishop(color)]) != 0:
    return bishop(color)
  if (targets and self.outposts[knight(color)]) != 0:
    return knight(color)
  if (targets and self.outposts[pawn(color)]) != 0:
    return pawn(color)
  return Piece(0)

#------------------------------------------------------------------------------
proc oppositeBishops*(self: ptr Position): bool =
  let bishops = self.outposts[Bishop] or self.outposts[BlackBishop]
  return ((bishops and maskDark) != 0) and ((bishops and (not maskDark)) != 0)
