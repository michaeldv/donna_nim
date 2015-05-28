# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned
import types, data, init, bitmask, piece, move
import position, position/moves, position/targets
import generate

#------------------------------------------------------------------------------
proc addPawnMoves*(self: ptr MoveGen, square: int, targets: Bitmask): ptr MoveGen {.discardable.} =
  var outposts = targets

  while outposts != 0:
    let target = outposts.pop
    if (target > H1) and (target < A8):
      self.add(newPawnMove(self.p, square, target))
    else: # Promotion.
      let promo = newPromotion(self.p, square, target)
      self.add(promo[0]).add(promo[1]).add(promo[2]).add(promo[3])

  return self

#------------------------------------------------------------------------------
proc addKingMoves*(self: ptr MoveGen, square: int, targets: Bitmask): ptr MoveGen {.discardable.} =
  var outposts = targets

  while outposts != 0:
    let target = outposts.pop
    if abs(square - target) == 2:
      self.add(newCastle(self.p, square, target))
    else:
      self.add(newMove(self.p, square, target))

  return self

#------------------------------------------------------------------------------
proc addPieceMoves*(self: ptr MoveGen, square: int, targets: Bitmask): ptr MoveGen {.discardable.} =
  var outposts = targets

  while outposts != 0:
    self.add(newMove(self.p, square, outposts.pop))

  return self

#------------------------------------------------------------------------------
proc pawnMoves*(self: ptr MoveGen, color: uint8): ptr MoveGen {.discardable.} =
  let p = self.p
  var pawns = p.outposts[pawn(color)]

  while pawns != 0:
    let square = pawns.pop
    self.addPawnMoves(square, p.targets(square))

  return self

#------------------------------------------------------------------------------
proc pieceMoves*(self: ptr MoveGen, color: uint8): ptr MoveGen {.discardable.} =
  ## Go over all pieces except pawns and the king.
  let p = self.p
  var outposts = p.outposts[color] and (not p.outposts[pawn(color)]) and (not p.outposts[king(color)])

  while outposts != 0:
    let square = outposts.pop
    self.addPieceMoves(square, p.targets(square))

  return self

#------------------------------------------------------------------------------
proc kingMoves*(self: ptr MoveGen, color: uint8): ptr MoveGen {.discardable.} =
  let p = self.p

  if p.outposts[king(color)] != 0:
    let square = int(p.king[color])
    self.addKingMoves(square, p.targets(square))

    let (kingside, queenside) = p.canCastle(color)
    if kingside:
      self.addKingMoves(square, bit[G1 + 56 * int(color)])

    if queenside:
      self.addKingMoves(square, bit[C1 + 56 * int(color)])

  return self
