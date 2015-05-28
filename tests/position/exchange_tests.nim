# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned, unittest
import types, params, data, play, move, position/exchange

suite "PositionExchange":
  test "position_exchange#000":
    let p = newGame("Kg1,c4,d4", "Kg8,d5,e6").start
    let exchange = p.exchange(newMove(p, C4, D5))
    check exchange == 0

  test "position_exchange#010":
    let p = newGame("Kg1,Qb3,Nc3,a2,b2,c4,d4,e4,f2,g2,h2", "Kg8,Qd8,Nf6,a7,b6,c6,d5,e6,f7,g7,h7").start
    let exchange = p.exchange(newMove(p, E4, D5))
    check exchange == 0

  test "position_exchange#020":
    let p = newGame("Kg1,Qb3,Nc3,Nf3,a2,b2,c4,d4,e4,f2,g2,h2", "Kg8,Qd8,Nd7,Nf6,a7,b6,c6,d5,e6,f7,g7,h7").start
    let exchange = p.exchange(newMove(p, E4, D5))
    check exchange == valuePawn.midgame
