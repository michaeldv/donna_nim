# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned, unittest
import types, data, play, move, position/moves, position/cache

suite "PositionCache":
  test "position_cache#010":
    # engine.cacheSize = 0.5
    var p = newGame().start
    let move = newMove(p, E2, E4)
    p = p.makeMove(move).cache(move, 42, 1, 0, cacheExact)

    let cached = p.probe()
    check cached.move == move
    check cached.score == 42'i16
    check cached.depth == 1'i16
    check cached.flags == cacheExact
    check cached.id == uint32(p.id shr 32)

