# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned, unittest
import types, data, play, move

suite "Game":
  test "game#010":
    let game = newGame()
    let p = game.start

    let m0 = newMove(p, E2, E4)
    let m1 = newMove(p, E7, E5)
    let m2 = newMove(p, G1, F3)
    let m3 = newMove(p, B8, C6)
    let m4 = newMove(p, F1, B5)
    game.saveBest(0, m0)
    game.saveBest(1, m1)
    game.saveBest(2, m2)
    game.saveBest(3, m3)
    game.saveBest(4, m4)

    check game.pv[0].size == 1
    check game.pv[0].moves[0] == m0
    check game.pv[1].size == 2
    check game.pv[1].moves[0] == Move(0)
    check game.pv[1].moves[1] == m1
    check game.pv[2].size == 3
    check game.pv[2].moves[0] == Move(0)
    check game.pv[2].moves[1] == Move(0)
    check game.pv[2].moves[2] == m2
    check game.pv[3].size == 4
    check game.pv[3].moves[0] == Move(0)
    check game.pv[3].moves[1] == Move(0)
    check game.pv[3].moves[2] == Move(0)
    check game.pv[3].moves[3] == m3
    check game.pv[4].size == 5
    check game.pv[4].moves[0] == Move(0)
    check game.pv[4].moves[1] == Move(0)
    check game.pv[4].moves[2] == Move(0)
    check game.pv[4].moves[3] == Move(0)
    check game.pv[4].moves[4] == m4

    # for i in 0 .. 9:
    #   stdout.write i.repr & ": (" & game.pv[i].size.repr & ") "
    #   for j in 0 ..< game.pv[i].size:
    #       stdout.write "[" & game.pv[i].moves[j].toString & "] "
    #   stdout.write "\n"

    let m5 = newMove(p, A7, A6)
    game.saveBest(1, m5)

    # for i in 0 .. 9:
    #   stdout.write i.repr & ": (" & game.pv[i].size.repr & ") "
    #   for j in 0 ..< game.pv[i].size:
    #       stdout.write "[" & game.pv[i].moves[j].toString & "] "
    #   stdout.write "\n"

    check game.pv[0].size == 1
    check game.pv[0].moves[0] == m0
    check game.pv[1].size == 3                       # <--
    check game.pv[1].moves[0] == Move(0)
    check game.pv[1].moves[1] == m5                  # <--
    check game.pv[1].moves[2] == game.pv[2].moves[2] # <--
    check game.pv[2].size == 3
    check game.pv[2].moves[0] == Move(0)
    check game.pv[2].moves[1] == Move(0)
    check game.pv[2].moves[2] == m2
    check game.pv[3].size == 4
    check game.pv[3].moves[0] == Move(0)
    check game.pv[3].moves[1] == Move(0)
    check game.pv[3].moves[2] == Move(0)
    check game.pv[3].moves[3] == m3
    check game.pv[4].size == 5
    check game.pv[4].moves[0] == Move(0)
    check game.pv[4].moves[1] == Move(0)
    check game.pv[4].moves[2] == Move(0)
    check game.pv[4].moves[3] == Move(0)
    check game.pv[4].moves[4] == m4
