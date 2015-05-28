# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned
import types, params, bitmask, move, position/targets
from data import Checkmate, Pawn

let exchangeScores: array[14, int] = [
  0, 0,                                           # Zero score for non-capture moves.
  valuePawn.midgame, valuePawn.midgame,           # Pawn/BlackPawn captures.
  valueKnight.midgame, valueKnight.midgame,       # Knight/BlackKinght captures.
  valueBishop.midgame, valueBishop.midgame,       # Bishop/BlackBishop captures.
  valueRook.midgame, valueRook.midgame,           # Rook/BlackRook captures.
  valueQueen.midgame, valueQueen.midgame,         # Queen/BlackQueen captures.
  valueQueen.midgame * 8, valueQueen.midgame * 8, # King/BlackKing specials.
]

#------------------------------------------------------------------------------
proc exchangeScore(self: ptr Position, color: uint8, to, score, extra: int, board: var Bitmask): int =
  ## Recursive helper method for the static exchange evaluation.
  var attackers = self.attackers(color, to, board) and board
  if attackers.empty:
    return score

  var fr = 0
  var best = Checkmate

  while attackers.dirty:
    let square = attackers.pop
    let index = self.pieces[square]
    if exchangeScores[index] < best:
      fr = square
      best = exchangeScores[index]

  if best != Checkmate:
    board = board xor bit[fr]

  return max(score, -self.exchangeScore(color xor 1, to, -(score + extra), best, board))

#------------------------------------------------------------------------------
proc exchange*(self: ptr Position, move: Move): int =
  ## Static exchange evaluation.
  var (fr, to, piece, capture) = move.split
  var score = exchangeScores[capture]

  let promo = move.promo
  if promo != 0:
    score += exchangeScores[promo] - exchangeScores[Pawn]
    piece = promo

  var board = self.board xor bit[fr]
  return -self.exchangeScore(piece.color xor 1, to, -score, exchangeScores[piece], board)
