# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned
import bitmask, piece, position, position/targets, utils
import generate, generate/helpers

#------------------------------------------------------------------------------
proc pawnCaptures*(self: ptr MoveGen, color: uint8): ptr MoveGen =
  ## Generates all pseudo-legal pawn captures and promotions.
  let p = self.p
  let enemy = p.outposts[color xor 1]
  var pawns = p.outposts[pawn(color)]

  while pawns != 0:
    let square = pawns.pop

    # For pawns on files 2-6 the moves include captures only,
    # while for pawns on the 7th file the moves include captures
    # as well as promotion on empty square in front of the pawn.
    if rank(color, square) != 6:
      self.addPawnMoves(square, p.targets(square) and enemy)
    else:
      self.addPawnMoves(square, p.targets(square))

  return self

#------------------------------------------------------------------------------
proc pieceCaptures*(self: ptr MoveGen, color: uint8): ptr MoveGen =
  ## Generates all pseudo-legal captures by pieces other than pawn.
  let p = self.p
  let enemy = p.outposts[color xor 1]
  var king = p.outposts[king(color)]
  var outposts = p.outposts[color] and (not p.outposts[pawn(color)]) and (not king)

  while outposts != 0:
    let square = outposts.pop
    self.addPieceMoves(square, p.targets(square) and enemy)

  if king != 0:
    let square = king.pop
    self.addKingMoves(square, p.targets(square) and enemy)

  return self

#------------------------------------------------------------------------------
proc generateCaptures*(self: ptr MoveGen): ptr MoveGen {.discardable.} =
  let color = self.p.color
  return self.pawnCaptures(color).pieceCaptures(color)

