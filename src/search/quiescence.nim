# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned
import types, data, play, move, position, evaluate
import generate, generate/captures, generate/checks, generate/evasions
import position, position/moves, position/cache, position/exchange
from params import pieceValue

echo "Hello, from Search Quiescence ;-)"

#------------------------------------------------------------------------------
proc searchQuiescence*(self: ptr Position, alpha, beta, iteration: int, inCheck: bool): int =
  let ply = ply()
  var alpha = alpha

  # Reset principal variation.
  game.pv[ply].size = 0

  # Return if it's time to stop search.
  if (ply >= MaxPly): ### or engine.clock.halt:
    return self.evaluate

  # Insufficient material and repetition/perpetual check pruning.
  if self.insufficient or self.repetition or self.fifty:
    return 0

  # If you pick up a starving dog and make him prosperous, he will not
  # bite you. This is the principal difference between a dog and a man.
  # ―- Mark Twain
  let isPrincipal = ((beta - alpha) > 1)

  # Use fixed depth for caching.
  var depth = 0
  if (not inCheck) and (iteration > 0):
    dec(depth)

  # Probe cache.
  var staticScore = alpha
  var cached = self.probe
  if cached != nil:
    if int(cached.depth) >= depth:
      staticScore = uncache(int(cached.score), ply)
      if ((cached.flags == cacheExact) and isPrincipal) or
         ((cached.flags == cacheBeta)  and (staticScore >= beta)) or
         ((cached.flags == cacheAlpha) and (staticScore <= alpha)):
        return staticScore

  if not inCheck:
    staticScore = self.evaluate
    if staticScore >= beta:
      self.cache(Move(0), staticScore, depth, ply, cacheBeta)
      return staticScore
    if isPrincipal:
      alpha = max(alpha, staticScore)

  # Generate check evasions or captures.
  var gen = newGen(self, ply)
  if inCheck:
    discard gen.generateEvasions
  else:
    discard gen.generateCaptures
  gen.quickRank

  var cacheFlags = cacheAlpha
  var moveCount = 0
  var bestMove = Move(0)
  var move = gen.nextMove

  while move != 0:
    if ((not inCheck) and (self.exchange(move) < 0)) or (not gen.isValid(move)):
      move = gen.nextMove
      continue

    let position = self.makeMove(move)
    inc(moveCount)
    let giveCheck = position.isInCheck(position.color)

    # Prune useless captures -- but make sure it's not a capture move that checks.
    if (not inCheck) and (not giveCheck) and (not isPrincipal) and (not move.isPromo) and
       ((staticScore + pieceValue[move.capture()] + 72) < alpha):
      position.undoLastMove
      move = gen.nextMove
      continue

    result = -position.searchQuiescence(-beta, -alpha, iteration + 1, giveCheck)
    position.undoLastMove

    if result > alpha:
      alpha = result
      bestMove = move
      if alpha >= beta:
        self.cache(bestMove, result, depth, ply, cacheBeta)
        game.qnodes += moveCount
        return
      cacheFlags = cacheExact

    # if engine.clock.halt {
    #   game.qnodes += moveCount
    #   return alpha

    move = gen.nextMove
  # endwhile

  if (not inCheck) and (iteration < 1):
    gen = newGen(self, ply).generateChecks.quickRank
    move = gen.nextMove
    while move != 0:
      if (self.exchange(move) < 0) or (not gen.isValid(move)):
        move = gen.nextMove
        continue

      let position = self.makeMove(move)
      inc(moveCount)
      result = -position.searchQuiescence(-beta, -alpha, iteration + 1, position.isInCheck(position.color))
      position.undoLastMove

      if result > alpha:
        alpha = result
        bestMove = move
        if alpha >= beta:
          self.cache(bestMove, result, depth, ply, cacheBeta)
          game.qnodes += moveCount
          return
        cacheFlags = cacheExact

      # if engine.clock.halt:
      #   game.qnodes += moveCount
      #   return alpha

      move = gen.nextMove
    # endwhile


  game.qnodes += moveCount

  result = alpha
  if inCheck and moveCount == 0:
    result = -Checkmate + ply

  self.cache(bestMove, result, depth, ply, cacheFlags)
