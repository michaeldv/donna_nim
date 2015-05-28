# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned
import types, data, play, bitmask, piece, move, position, evaluate
import generate, generate/root, generate/evasions
import position, position/moves, position/cache
import search/quiescence

echo "Hello, from Search Tree ;-)"

#------------------------------------------------------------------------------
proc searchTree*(self: ptr Position, alpha, beta, depth: int): int =
  let ply = ply()
  var alpha = alpha
  var beta = beta

  # Reset principal variation.
  game.pv[ply].size = 0

  # Return if it's time to stop search.
  if (ply >= MaxPly): ### or engine.clock.halt:
    return self.evaluate

  # Insufficient material and repetition/perpetual check pruning.
  if self.insufficient or self.repetition or self.fifty:
    return 0

  # Checkmate distance pruning.
  let score = abs(ply - Checkmate) 
  if score < beta:
    beta = score
    if score <= alpha:
      return alpha

  # Initialize node search conditions.
  let isNull = self.isNull
  let inCheck = self.isInCheck(self.color)
  let isPrincipal = ((beta - alpha) > 1)

  # Probe cache.
  let cached = self.probe
  var cachedMove = Move(0)
  var staticScore = UnknownScore
  if cached != nil:
    cachedMove = cached.move
    if int(cached.depth) >= depth:
      staticScore = uncache(int(cached.score), ply)
      if ((cached.flags == cacheExact) and isPrincipal) or
         ((cached.flags == cacheBeta) and (staticScore >= beta)) or
         ((cached.flags == cacheAlpha) and (staticScore <= alpha)):
        if (staticScore >= beta) and (not inCheck) and (cachedMove != 0) and cachedMove.isQuiet:
          game.saveGood(depth, cachedMove)
        return staticScore


  # Quiescence search.
  if (not inCheck) and (depth < 1):
    return self.searchQuiescence(alpha, beta, 0, inCheck)

  if staticScore == UnknownScore:
    staticScore = self.evaluate

  # Razoring and futility margin pruning.
  if (not inCheck) and (not isPrincipal):

    # No razoring if pawns are on 7th rank.
    if (cachedMove == Move(0)) and (depth < 8) and (self.outposts[pawn(self.color)] and mask7th[self.color]).empty:
      # Special case for razoring at low depths.
      proc razoringMargin(depth: int): int {.inline.} =
        512 + 64 * (depth - 1)

      if (depth <= 2) and (staticScore <= (alpha - razoringMargin(5))):
        return self.searchQuiescence(alpha, beta, 0, inCheck)

      let score = self.searchQuiescence(alpha, beta + 1, 0, inCheck)
      if score <= alpha - razoringMargin(depth):
        return score

    # Futility pruning is only applicable if we don't have winning score
    # yet and there are pieces other than pawns.
    if (not isNull) and (depth < 14) and (abs(beta) < (Checkmate - MaxPly)) and
       (self.outposts[self.color] and (not (self.outposts[king(self.color)] or self.outposts[pawn(self.color)]))).dirty:
      # Largest conceivable positional gain.
      let gain = staticScore - (256 * depth)
      if gain >= beta:
        return gain

    # Null move pruning.
    if (not isNull) and (depth > 1) and (self.outposts[self.color].count > 5):
      let position = self.makeNullMove
      inc(game.nodes)
      let nullScore = -position.searchTree(-beta, -beta + 1, depth - 1 - 3)
      position.undoNullMove

      if nullScore >= beta:
        if abs(nullScore) >= (Checkmate - MaxPly):
          return beta
        return nullScore

  # Internal iterative deepening.
  if (not inCheck) and (cachedMove == Move(0)) and (depth > 4):
    var newDepth = depth div 2
    if isPrincipal:
      newDepth = depth - 2

    discard self.searchTree(alpha, beta, newDepth)

    let cached = self.probe
    if cached != nil:
      cachedMove = cached.move

  let gen = newGen(self, ply)
  if inCheck:
    discard gen.generateEvasions.quickRank
  else:
    discard gen.generateMoves.rank(cachedMove)

  var cacheFlags = cacheAlpha
  var bestMove = Move(0)
  var moveCount = 0
  var quietMoveCount = 0

  var move = gen.nextMove
  while move != 0:
    if not gen.isValid(move):
      move = gen.nextMove
      continue

    let position = self.makeMove(move)
    inc(moveCount)
    var newDepth = depth - 1

    # Search depth extension.
    let giveCheck = position.isInCheck(position.color)
    if giveCheck:
      inc(newDepth)

    # Late move reduction.
    var lateMoveReduction = false
    if (depth >= 3) and (not isPrincipal) and (not inCheck) and (not giveCheck) and move.isQuiet:
      inc(quietMoveCount)
      if (newDepth > 0) and (quietMoveCount >= 8):
        dec(newDepth)
        lateMoveReduction = true
        if (quietMoveCount >= 16):
          dec(newDepth)
          if quietMoveCount >= 24:
            dec(newDepth)

    # Start search with full window.
    if moveCount == 1:
      result = -position.searchTree(-beta, -alpha, newDepth)
    elif lateMoveReduction:
      result = -position.searchTree(-alpha - 1, -alpha, newDepth)

      # Verify late move reduction and re-run the search if necessary.
      if result > alpha:
        result = -position.searchTree(-alpha - 1, -alpha, newDepth + 1)
    else:
      if newDepth < 1:
        result = -position.searchQuiescence(-alpha - 1, -alpha, 0, giveCheck)
      else:
        result = -position.searchTree(-alpha - 1, -alpha, newDepth)

      # If zero window failed try full window.
      if (result > alpha) and (result < beta):
        result = -position.searchTree(-beta, -alpha, newDepth)

    position.undoLastMove()

    # if engine.clock.halt:
    #   game.nodes += moveCount
    #   #Log("searchTree at %d (%s): move %s (%d) score %d alpha %d\n", depth, C(self.color), move, moveCount, score, alpha)
    #   return alpha

    if result > alpha:
      alpha = result
      bestMove = move
      cacheFlags = cacheExact
      game.saveBest(ply, move)

      if alpha >= beta:
        cacheFlags = cacheBeta
        break # Stop searching. Happiness is right next to you.

    move = gen.nextMove
  # endwhile

  game.nodes += moveCount

  if moveCount == 0:
    if inCheck:
      alpha = -Checkmate + ply
    else:
      alpha = 0
  elif (result >= beta) and (not inCheck):
    game.saveGood(depth, bestMove)

  result = alpha
  self.cache(bestMove, result, depth, ply, cacheFlags)
