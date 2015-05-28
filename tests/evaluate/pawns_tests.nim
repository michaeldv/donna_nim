# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned, unittest
import types, params, play, evaluate

suite "EvaluatePawns":
  # Doubled pawns.
  test "evaluate_pawns#100":
    let p = newGame("Ke1,h2,h3", "Kd8,a7,a6").start
    let score = p.evaluate
    check score == rightToMove.endgame # Right to move only.

  test "evaluate_pawns#110":
    let p = newGame("Ke1,h2,h3", "Ke8,a7,h7").start
    let score = p.evaluate
    check score == -12

  test "evaluate_pawns#120":
    let p = newGame("Ke1,f4,f5", "Ke8,f7,h7").start
    let score = p.evaluate
    check score == -33

  # Passed pawns.
  test "evaluate_pawns#200":
    let p = newGame("Ke1,h4", "Ke8,h5").start # Blocked.
    let score = p.evaluate
    check score == 5

  test "evaluate_pawns#210":
    let p = newGame("Ke1,h4", "Ke8,g7").start # Can't pass.
    let score = p.evaluate
    check score == 1

  test "evaluate_pawns#220":
    let p = newGame("Ke1,e4", "Ke8,d6").start # Can't pass.
    let score = p.evaluate
    check score == -3

  test "evaluate_pawns#230":
    let p = newGame("Ke1,e5", "Ke8,e4").start # Both passing.
    let score = p.evaluate
    check score == 5

  test "evaluate_pawns#240":
    let p = newGame("Kd1,e5", "Ke8,d5").start # Both passing but white is closer.
    let score = p.evaluate
    check score == 26

  test "evaluate_pawns#240":
    let p = newGame("Ke1,a5", "Kd8,h7").start # Both passing but white is much closer.
    let score = p.evaluate
    check score == 97

  # Isolated pawns.
  test "evaluate_pawns#300":
    let p = newGame("Ke1,a5,c5", "Kd8,f4,h4").start # All pawns are isolated.
    let score = p.evaluate
    check score == 5

  test "evaluate_pawns#310":
    let p = newGame("Ke1,a2,c2,e2", "Ke8,a7,b7,c7").start # White pawns are isolated.
    let score = p.evaluate
    check score == -50

  # Rooks. (PENDING ENDGAME)
  # test "evaluate_pawns#400":
  #   let p = newGame("Ke1,Ra7", "Ke8,Rh3").start # White on 7th.
  #   let score = p.evaluate
  #   check score == 4
  #
  # test "evaluate_pawns#410":
  #   let p = newGame("Ke1,Rb1,Ng2,a2", "Ke8,Rh8,Nb7,h7").start # White on open file.
  #   let score = p.evaluate
  #   check score == 68

  test "evaluate_pawns#420":
    let p = newGame("Ke1,Rb1,a2,g2", "Ke8,Rh8,h7,b7").start # White on semi-open file.
    let score = p.evaluate
    check score == 103

  # King shield.
  test "evaluate_pawns#500":
    let p = newGame("Kg1,f2,g2,h2,Qa3,Na4", "Kg8,f7,g7,h7,Qa6,Na5").start # h2,g2,h2 == f7,g7,h7
    let score = p.evaluate
    check score == 8

  test "evaluate_pawns#505":
    let p = newGame("Kg1,f2,g2,h2,Qa3,Na4", "Kg8,f7,g6,h7,Qa6,Na5").start # h2,g2,h2 vs f7,G6,h7
    let score = p.evaluate
    check score == 13

  test "evaluate_pawns#510":
    let p = newGame("Kg1,f2,g2,h2,Qa3,Na4", "Kg8,f5,g6,h7,Qa6,Na5").start # h2,g2,h2 vs F5,G6,h7
    let score = p.evaluate
    check score == 27

  test "evaluate_pawns#520":
    let p = newGame("Kg1,f2,g2,h2,Qa3,Na4", "Kg8,a7,f7,g7,Qa6,Na5").start # h2,g2,h2 vs A7,f7,g7
    let score = p.evaluate
    check score == 47

  test "evaluate_pawns#530":
    let p = newGame("Kb1,a3,b2,c2,Qh3,Nh4", "Kb8,a7,b7,c7,Qh6,Nh5").start # A3,b2,c2 vs a7,b7,c7
    let score = p.evaluate
    check score == 2

  test "evaluate_pawns#540":
    let p = newGame("Kb1,a3,b4,c2,Qh3,Nh4", "Kb8,a7,b7,c7,Qh6,Nh5").start # A3,B4,c2 vs a7,b7,c7
    let score = p.evaluate
    check score == -10

  test "evaluate_pawns#550":
    let p = newGame("Kb1,b2,c2,h2,Qh3,Nh4", "Kb8,a7,b7,c7,Qh6,Nh5").start # b2,c2,H2 vs a7,b7,c7
    let score = p.evaluate
    check score == -31

  test "evaluate_pawns#560":
    let p = newGame("Ka1,a3,b2,Qc1,Nd2", "Kh8,g7,h6,Qf8,Ne7").start # a3,b2 == g7,h6
    let score = p.evaluate
    check score == 8

  test "evaluate_pawns#570":
    let p = newGame("Kb1,a2,c2,f2,g2,h2", "Kg8,a7,c7,f7,g7,h7").start # B2 hole but not enough power to bother.
    let score = p.evaluate
    check score == 5
