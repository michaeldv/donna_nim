# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned, strutils
import types, move, position
from data import MaxPly

echo "Hello, from Play ;-)"

var gameObject: Game
let game*: ptr Game = gameObject.addr

proc setupCache(self: ptr Game, megaBytes: float): ptr Game

#------------------------------------------------------------------------------
proc newGame*(args: varargs[string]): ptr Game =
  game.nodes = 0
  game.qnodes = 0
  game.token = 0
  game.deepening = false
  game.improving = false
  game.volatility = 0.0
  game.initial = ""
  game.history.reset
  game.killers.reset
  game.rootpv.reset
  game.pv.reset
  game.pawnCache.reset

  let params = len(args)
  if params == 1:
    game.initial = args[0]
  elif params == 2:
    game.initial = args[0] & " : " & args[1]

  return game.setupCache(4.0)

#------------------------------------------------------------------------------
proc position*(self: ptr Game): ptr Position =
  return tree[node].addr

#------------------------------------------------------------------------------
proc start*(self: ptr Game): ptr Position =
  tree.reset
  node = 0
  rootNode = 0

  if len(game.initial) == 0:
    return newInitialPosition(self)
  else:
    let sides = self.initial.split(" : ")
    if len(sides) == 2:
      return newPosition(self, sides[0], sides[1])
  return newPositionFromFEN(self, self.initial)  

#------------------------------------------------------------------------------
proc ready*(self: ptr Game): ptr Game =
  self.history.reset
  self.killers.reset
  self.rootpv.reset
  self.pv.reset
  self.deepening = false
  self.improving = true
  self.volatility = 0.0
  inc(self.token)

  rootNode = node

  return self

#------------------------------------------------------------------------------
proc saveBest*(self: ptr Game, ply: int, move: Move): ptr Game {.discardable.} =
  self.pv[ply].moves[ply] = move
  self.pv[ply].size = ply + 1

  let next = self.pv[ply].size
  if (next < MaxPly) and (self.pv[next].size > next):
    for i in next ..< self.pv[next].size:
      self.pv[ply].moves[i] = self.pv[next].moves[i]
      inc(self.pv[ply].size)

  return self

#------------------------------------------------------------------------------
proc saveGood*(self: ptr Game, depth: int, move: Move): ptr Game {.discardable.} =
  let ply = node - rootNode
  if move.isQuiet and (move != self.killers[ply][0]):
    self.killers[ply][1] = self.killers[ply][0]
    self.killers[ply][0] = move
    self.history[move.piece][move.to] += depth * depth

  return self

#------------------------------------------------------------------------------
proc good*(self: ptr Game, move: Move): int =
  ## Checks whether the move is among good moves captured so far and returns its
  ## history value.
  return self.history[move.piece][move.to]

#------------------------------------------------------------------------------
proc setupCache(self: ptr Game, megaBytes: float): ptr Game =
  ## Creates new or resets existing game cache (aka transposition table).
  if megaBytes > 0.0:
    let existing = len(self.cache)
    let byteSize = int(1024.0 * 1024.0 * megaBytes)
    let cacheSize = byteSize div sizeof(CacheEntry)

    if cacheSize != existing:
      if existing == 0:
        # Create brand new zero-initialized cache.
        self.cache = newSeq[CacheEntry](cacheSize)
      else:
        # Reallocate existing cache (shrink or expand).
        self.cache = cast[Cache](realloc(self.cache.addr, Natural(byteSize)))

    # Make sure the cache is all clear.
    for i in 0 ..< len(self.cache):
      self.cache[i] = (0'u32, Move(0), 0'i16, 0'i16, 0'u8, 0'u8)

  return self

#------------------------------------------------------------------------------
proc toString*(self: ptr Game): string =
  return self.position.toString
