# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned, unittest
import data, bitmask, move, play, position, position/targets, position/moves

suite "PositionTargets":
  test "position_targets000":
    # Pawn targets.
    let p = newGame("Kd1,e2", "Ke8,d4").start

    check p.targets(E2) == (bit[E3] or bit[E4]) # e3,e4
    check p.targets(D4) == bit[D3]              # d3

  test "position_targets010":
    let p = newGame("Kd1,e2,d3", "Ke8,d4,e4").start

    check p.targets(E2) == bit[E3]              # e3
    check p.targets(D3) == bit[E4]              # e4
    check p.targets(D4) == maskNone             # None.
    check p.targets(E4) == (bit[D3] or bit[E3]) # d3,e3

  test "position_targets020":
    let p = newGame("Kd1,e2", "Ke8,d3,f3").start

    check p.targets(E2) == (bit[D3] or bit[E3] or bit[E4] or bit[F3]) # d3,e3,e4,f3
    check p.targets(D3) == (bit[E2] or bit[D2])                       # e2,d2
    check p.targets(F3) == (bit[E2] or bit[F2])                       # e2,f2

  test "position_targets030":
    var p = newGame("Kd1,e2", "Ke8,d4").start
    p = p.makeMove(newEnpassant(p, E2, E4)) # Creates en-passant on e3.

    check p.targets(E4) == bit[E5]              # e5
    check p.targets(D4) == (bit[D3] or bit[E3]) # d3, e3 (en-passant).

  test "position_targets040":
    # Pawn attacks.
    let p = newGame("Ke1,a3,b3,c3,d3,e3,f3,g3,h3", "Ke8,a6,b6,c6,d6,e6,f6,g6,h6").start

    check p.pawnAttacks(White) == (bit[A4] or bit[B4] or bit[C4] or bit[D4] or bit[E4] or bit[F4] or bit[G4] or bit[H4])
    check p.pawnAttacks(Black) == (bit[A5] or bit[B5] or bit[C5] or bit[D5] or bit[E5] or bit[F5] or bit[G5] or bit[H5])

  # Opposite-colored bishops.
  test "position_targets050":
    let p = newGame("Ke1,Bc1", "Ke8,Bc8").start
    check p.oppositeBishops == true

  test "position_targets060":
    let p = newGame("Kc4,Bd4", "Ke8,Bd5").start
    check p.oppositeBishops == true

  test "position_targets070":
    let p = newGame("Kc4,Bd4", "Ke8,Be5").start
    check p.oppositeBishops == false

  test "position_targets080":
    let p = newGame("Ke1,Bc1", "Ke8,Bf8").start
    check p.oppositeBishops == false

