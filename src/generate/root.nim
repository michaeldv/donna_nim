# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned
import types, play, move, position/moves
import generate, generate/helpers, generate/evasions

#------------------------------------------------------------------------------
proc generateMoves*(self: ptr MoveGen): ptr MoveGen {.discardable.} =
  let color = self.p.color
  return self.pawnMoves(color).pieceMoves(color).kingMoves(color)

#------------------------------------------------------------------------------
proc generateAllMoves*(self: ptr MoveGen): ptr MoveGen {.discardable.} =
  if self.p.isInCheck(self.p.color):
    return self.generateEvasions
  return self.generateMoves

#------------------------------------------------------------------------------
proc generateRootMoves*(self: ptr MoveGen): ptr MoveGen {.discardable.} =
  self.generateAllMoves
  if self.onlyMove:
    return self

  return self.validOnly.quickRank

#------------------------------------------------------------------------------
proc rearrangeRootMoves*(self: ptr MoveGen): ptr MoveGen {.discardable.} =
  if game.rootpv.size > 0:
    return self.reset.rootRank(game.rootpv.moves[0])
  return self.reset.rootRank(Move(0))

#------------------------------------------------------------------------------
proc cleanupRootMoves*(self: ptr MoveGen, depth: int): ptr MoveGen {.discardable.} =
  if self.size < 2:
    return self

  # Always preserve first higest ranking move.
  for i in 1 ..< self.tail:
    if self.list[i].score == -depth + 1:
      self.tail = i
      break

  return self.reset
