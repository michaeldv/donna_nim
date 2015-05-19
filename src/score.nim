# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

type
  Score* = tuple[midgame, endgame: int]

var
  pst*: array[14, array[64, Score]]

# Reference methods that change the score receiver in place and return a
# pointer to the updated score.
#------------------------------------------------------------------------------
proc clear*(s: var Score): var Score {.discardable.} =
  s.midgame = 0
  s.endgame = 0

  return s

#------------------------------------------------------------------------------
proc add*(s: var Score, score: Score): var Score {.discardable.} =
  s.midgame += score.midgame
  s.endgame += score.endgame

  return s

#------------------------------------------------------------------------------
proc subtract*(s: var Score, score: Score): var Score {.discardable.} =
  s.midgame -= score.midgame
  s.endgame -= score.endgame

  return s

#------------------------------------------------------------------------------
proc apply*(s: var Score, weight: Score): var Score {.discardable.} =
  s.midgame = (s.midgame * weight.midgame) div 100
  s.endgame = (s.endgame * weight.endgame) div 100

  return s

#------------------------------------------------------------------------------
proc adjust*(s: var Score, n: int): var Score {.discardable.} =
  s.midgame += n
  s.endgame += n

  return s

# Value methods that return new updated score.
#------------------------------------------------------------------------------
proc plus*(s: Score, score: Score): Score =
  return (midgame: s.midgame + score.midgame, endgame: s.endgame + score.endgame)

#------------------------------------------------------------------------------
proc minus*(s: Score, score: Score): Score =
  return (midgame: s.midgame - score.midgame, endgame: s.endgame - score.endgame)

#------------------------------------------------------------------------------
proc times*(s: Score, n: int): Score =
  return (midgame: s.midgame * n, endgame: s.endgame * n)

#------------------------------------------------------------------------------
proc blended*(s: Score, phase: int): int =
  ## Calculates normalized score based on the game phase.
  return (s.midgame * phase + s.endgame * (256 - phase)) div 256
