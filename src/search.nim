# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned
import types, data, play, move
import generate, generate/root
import position, position/moves, position/cache
import search/tree

echo "Hello, from Search ;-)"

#------------------------------------------------------------------------------
proc search*(self: ptr Position, alpha, beta, depth: int): int =
  ## Root node search. Basic principle is expressed by Boob's Law: you always find
  ## something in the last place you look.
  let inCheck = self.isInCheck(self.color)
  var cacheFlags = cacheAlpha
  var alpha = alpha
  var moveCount = 0
  var bestMove = Move(0)

  # Root move generator makes sure all generated moves are valid. The
  # best move found so far is always the first one we search.
  let gen = newRootGen(self, depth)
  if depth == 1:
    gen.generateRootMoves
  else:
    gen.rearrangeRootMoves
    if depth == 10: # Skip moves that failed all iterations so far.
      gen.cleanupRootMoves(depth)

  var move = gen.nextMove
  while move != 0:
    let position = self.makeMove(move)
    inc(moveCount)

    # if engine.uci:
    #   engine.uciMove(move, moveCount, depth)

    # Search depth extension.
    var newDepth = depth - 1
    if position.isInCheck(self.color xor 1): # Give check.
      inc(newDepth)

    if moveCount == 1:
      game.deepening = true
      result = -position.searchTree(-beta, -alpha, newDepth)
    else:
      game.deepening = false
      result = -position.searchTree(-alpha - 1, -alpha, newDepth)
      if result > alpha: # and result < beta:
        result = -position.searchTree(-beta, -alpha, newDepth)

    position.undoLastMove

    # if engine.clock.halt {
    #   #Log("searchRoot: bestMove %s pv[0][0] %s alpha %d\n", bestMove, game.pv[0][0], alpha)
    #   game.nodes += moveCount
    #   if engine.uci { # Report alpha as score since we're returning alpha.
    #     engine.uciScore(depth, alpha, alpha, beta)
    #   }
    #   return alpha
    # }

    if (moveCount == 1) or (result > alpha):
      bestMove = move
      cacheFlags = cacheExact
      game.saveBest(0, move)
      gen.scoreMove(depth, result)

      if moveCount > 1:
        game.volatility += 1.0
        # engine.debug("# new move %s depth %d volatility %.2f\n", move, depth, game.volatility)

      alpha = max(result, alpha)
      if alpha >= beta:
        cacheFlags = cacheBeta
        break
    else:
      gen.scoreMove(depth, -depth)

    move = gen.nextMove
  # endwhile


  if moveCount == 0:
    if inCheck:
      result = -Checkmate
    else:
      result = 0

    # if engine.uci:
    #   engine.uciScore(depth, score, alpha, beta)

    return


  game.nodes += moveCount
  if (result >= beta) and (not inCheck):
    game.saveGood(depth, bestMove)

  result = alpha
  self.cache(bestMove, result, depth, ply(), cacheFlags)

  # if engine.uci:
  #   engine.uciScore(depth, result, alpha, beta)


#------------------------------------------------------------------------------
proc solve*(self: ptr Position, depth: int): Move =
  ## Testing helper method to test root search.
  if depth != 1:
    newRootGen(self, 1).generateRootMoves

  discard self.search(-Checkmate, Checkmate, depth)
  return game.pv[0].moves[0]

#------------------------------------------------------------------------------
proc perft*(self: ptr Position, depth: int): int64 =
  if depth == 0:
    return 1

  let gen = newGen(self, depth).generateAllMoves
  var move = gen.nextMove
  while move != 0:
    if gen.isValid(move):
      let position = self.makeMove(move)
      result += position.perft(depth - 1)
      position.undoLastMove
    move = gen.nextMove
