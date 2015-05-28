# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned
import types, data, init, params, score, position/targets
import evaluate/pawns, evaluate/pieces, evaluate/threats, evaluate/safety

echo "Hello from Evaluate ;-)"
var eval: Evaluation

#------------------------------------------------------------------------------
proc init(self: ptr Evaluation, p: ptr Position): ptr Evaluation =
  self.position = p

  # Initialize the score with incremental PST value and right to move.
  self.score = p.tally
  if p.color == White:
    discard self.score.add(rightToMove)
  else:
    discard self.score.subtract(rightToMove)

  # Set up king and pawn attacks for both sides.
  self.attacks[King] = p.kingAttacks(White)
  self.attacks[Pawn] = p.pawnAttacks(White)
  self.attacks[BlackKing] = p.kingAttacks(Black)
  self.attacks[BlackPawn] = p.pawnAttacks(Black)

  # Overall attacks for both sides include kings and pawns so far.
  self.attacks[White] = self.attacks[King] or self.attacks[Pawn]
  self.attacks[Black] = self.attacks[BlackKing] or self.attacks[BlackPawn]

  return self

#------------------------------------------------------------------------------
proc wrapUp(self: ptr Evaluation): ptr Evaluation {.discardable.} =

  # Adjust the endgame score if we have lesser known endgame.
  # if (self.score.endgame != 0) and ((self.material.flags and lesserKnownEndgame) != 0):
  #   self.inspectEndgame

  # Flip the sign for black so that blended evaluation score always
  # represents the white sidself.
  if self.position.color == Black:
    self.score.midgame = -self.score.midgame
    self.score.endgame = -self.score.endgame

  return self

#------------------------------------------------------------------------------
proc run(self: ptr Evaluation): int =
  self.material = materialBase[self.position.balance].addr

  self.score.add(self.material.score)
  if (self.material.flags and knownEndgame) != 0:
    # return self.evaluateEndgame()
    discard

  self.analyzePawns
  self.analyzePieces
  self.analyzeThreats
  self.analyzeSafety
  self.analyzePassers
  self.wrapUp

  return self.score.blended(self.material.phase)

# The following statement is true. The previous statement is false. Main position
# evaluation method that returns single blended score.
#------------------------------------------------------------------------------
proc evaluate*(p: ptr Position): int =
  eval.reset
  eval.addr.init(p).run
