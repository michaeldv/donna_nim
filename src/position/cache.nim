# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned
import types, play
from data import Checkmate, MaxPly

const
  cachedNone* = 0'u8
  cacheExact* = 1'u8
  cacheAlpha* = 2'u8 # Upper bound.
  cacheBeta*  = 4'u8 # Lower bound.

echo "Hello from Cache ;-) " & sizeof(CacheEntry).repr & " bytes"


#------------------------------------------------------------------------------
proc cacheUsage*(): int =
  for i in 0 ..< len(game.cache):
    if game.cache[i].id != 0'u32:
      inc(result)

#------------------------------------------------------------------------------
proc uncache*(score, ply: int): int =
  if (score > (Checkmate - MaxPly)) and (score <= Checkmate):
    return score - ply
  elif (score >= -Checkmate) and (score < -Checkmate + MaxPly):
    return score + ply

  return score

#------------------------------------------------------------------------------
proc cache*(self: ptr Position, move: Move, score, depth, ply: int, flags: uint8): ptr Position {.discardable.} =
  let cacheSize = len(game.cache)
  if cacheSize > 0:
    let index = int(self.id and uint64(cacheSize - 1))
    let entry = game.cache[index].addr

    if (depth > int(entry.depth)) or (game.token != entry.token):
      if (score > Checkmate - MaxPly) and (score <= Checkmate):
        entry.score = int16(score + ply)
      elif (score >= -Checkmate) and (score < -Checkmate + MaxPly):
        entry.score = int16(score - ply)
      else:
        entry.score = int16(score)

      let id = uint32(self.id shr 32)
      if (move != Move(0)) or (id != entry.id):
        entry.move = move
      entry.depth = int16(depth)
      entry.flags = flags
      entry.token = game.token
      entry.id = id

  return self

#------------------------------------------------------------------------------
proc probe*(self: ptr Position): ptr CacheEntry =
  let cacheSize = len(game.cache)
  if cacheSize > 0:
    let index = int(self.id and uint64(cacheSize - 1))
    let entry = game.cache[index].addr
    if entry.id == uint32(self.id shr 32):
      result = entry

#------------------------------------------------------------------------------
proc cachedMove*(self: ptr Position): Move =
  let cached = self.probe()
  if cached != nil:
    result = cached.move

# func (p *Position) probeCache() *CacheEntry {
#   if cacheSize = len(game.cache); cacheSize > 0 {
#     index = p.hash and uint64(cacheSize - 1)
#     if entry = &game.cache[index]; entry.id == uint32(p.hash >>32) {
#       return entry
#     }
#   }
#   return nil
# }
#
# func (p *Position) cachedMove() Move {
#   if cached = p.probeCache(); cached != nil {
#     return cached.move
#   }
#   return Move(0)
# }
