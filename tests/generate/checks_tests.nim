# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned, strutils, unittest
import data, play, piece, move, position/moves
import generate, generate/helpers, generate/checks

suite "GenerateChecks":
  # Knight.
  test "generate_checks#000":
    let p = newGame("Ka1,Nd7,Nf3,b3", "Kh7,Nd4,f6").start
    let white = newMoveGen(p).generateChecks
    check white.allMoves == "[Nf3-g5 Nd7-f8]"

    p.color = Black
    let black = newMoveGen(p).generateChecks
    check black.allMoves == "[Nd4-c2]"

  # Bishop.
  test "generate_checks#010":
    let p = newGame("Kh2,Ba2", "Kh7,Ba7").start
    let white = newMoveGen(p).generateChecks
    check white.allMoves == "[Ba2-b1 Ba2-g8]"

    p.color = Black
    let black = newMoveGen(p).generateChecks
    check black.allMoves == "[Ba7-g1 Ba7-b8]"

  test "generate_checks#020":
    let p = newGame("Kf4,Bc1", "Kc5,Bf8,h6,e3").start
    let white = newMoveGen(p).generateChecks
    check white.allMoves == "[Bc1-a3]"

    p.color = Black
    let black = newMoveGen(p).generateChecks
    check black.allMoves == "[Bf8-d6]"

  # Bishop: discovered non-capturing check with blocked diaginal.
  test "generate_checks#030":
    let p = newGame("Ka8,Ba1,Nb2,c3,f3", "Kh8,Bh1,Ng2").start
    let white = newMoveGen(p).generateChecks
    check white.allMoves == "[]"

    p.color = Black
    let black = newMoveGen(p).generateChecks
    check black.allMoves == "[]"

  # Bishop: discovered non-capturing check: Knight.
  test "generate_checks#040":
    let p = newGame("Ka8,Ba1,Nb2,a4,h4", "Kh8,Bh1,Ng2,c4,f4").start
    let white = newMoveGen(p).generateChecks
    check white.allMoves == "[Nb2-d1 Nb2-d3]"

    p.color = Black
    let black = newMoveGen(p).generateChecks
    check black.allMoves == "[Ng2-e1 Ng2-e3]"

  # Bishop: discovered non-capturing check: Rook.
  test "generate_checks#050":
    let p = newGame("Ka8,Qa1,Nb1,Rb2,b4,d2,e2", "Kh8,Qh1,Rg2,g4").start
    let white = newMoveGen(p).generateChecks
    check white.allMoves == "[Rb2-a2 Rb2-c2 Rb2-b3]"

    p.color = Black
    let black = newMoveGen(p).generateChecks
    check black.allMoves == "[Rg2-g1 Rg2-f2 Rg2-h2 Rg2-g3]"

  # Bishop: discovered non-capturing check: King.
  test "generate_checks#060":
    let p = newGame("Ke5,Qc3,c4,d3,e4", "Kh8,e6").start
    let white = newMoveGen(p).generateChecks
    check white.allMoves == "[Ke5-f4 Ke5-d5 Ke5-f5 Ke5-d6]"

  # Bishop: discovered non-capturing check: Pawn move.
  test "generate_checks#070":
    let p = newGame("Ka8,Ba1,c3", "Kh8,Bg2,e4").start
    let white = newMoveGen(p).generateChecks
    check white.allMoves == "[c3-c4]"

    p.color = Black
    let black = newMoveGen(p).generateChecks
    check black.allMoves == "[e4-e3]"

  # Bishop: discovered non-capturing check: Pawn jump.
  test "generate_checks#080":
    let p = newGame("Kh2,Bb1,c2", "Kh7,Bb8,c7").start
    let white = newMoveGen(p).generateChecks
    check white.allMoves == "[c2-c3 c2-c4]"

    p.color = Black
    let black = newMoveGen(p).generateChecks
    check black.allMoves == "[c7-c5 c7-c6]"

  # Bishop: discovered non-capturing check: no pawn promotions.
  test "generate_checks#090":
    let p = newGame("Kh7,Bb8,c7", "Kh2,Bb1,c2").start
    let white = newMoveGen(p).generateChecks
    check white.allMoves == "[]"

    p.color = Black
    let black = newMoveGen(p).generateChecks
    check black.allMoves == "[]"

  # Bishop: discovered non-capturing check: no enpassant captures.
  test "generate_checks#100":
    var p = newGame("Ka1,Bf4,e5", "M,Kb8,f7").start
    let white = newMoveGen(p.makeMove(newEnpassant(p, F7, F5))).generateChecks
    check white.allMoves == "[e5-e6]"

    p = newGame("Ka1,e2", "Kb8,Be5,d4").start
    let black = newMoveGen(p.makeMove(newEnpassant(p, E2, E4))).generateChecks
    check black.allMoves == "[d4-d3]"

  # Bishop: extra Rook moves for Queen.
  test "generate_checks#110":
    let p = newGame("Kb1,Qa1,f2,a2", "Kh1,Qa7,Nb8,a6").start
    let white = newMoveGen(p).generateChecks
    check white.allMoves == "[Qa1-h8 Kb1-b2 Kb1-c2]"

    p.color = Black
    let black = newMoveGen(p).generateChecks
    check black.allMoves == "[Qa7-b6 Qa7-h7 Qa7-b7]"

  # Pawns.
  test "generate_checks#120":
    let p = newGame("Kb5,f2,g2,h2", "Kg4,a7,b7,c7").start
    let white = newMoveGen(p).generateChecks
    check white.allMoves == "[f2-f3 h2-h3]"

    p.color = Black
    let black = newMoveGen(p).generateChecks
    check black.allMoves == "[a7-a6 c7-c6]"

  test "generate_checks#130":
    let p = newGame("Kb4,f2,g2,h2", "Kg5,a7,b7,c7").start
    let white = newMoveGen(p).generateChecks
    check white.allMoves == "[f2-f4 h2-h4]"

    p.color = Black
    let black = newMoveGen(p).generateChecks
    check black.allMoves == "[a7-a5 c7-c5]"

  test "generate_checks#140":
    let p = newGame("Kb4,c5,f2,g2,h2", "Kg5,a7,b7,c7,h4").start
    let white = newMoveGen(p).generateChecks
    check white.allMoves == "[f2-f4]"

    p.color = Black
    let black = newMoveGen(p).generateChecks
    check black.allMoves == "[a7-a5]"

  # Rook with pawn on the same rank (discovered check).
  test "generate_checks#150":
    let p = newGame("Ka4,Ra5,e5", "Kh5,Rh4,c4").start
    let white = newMoveGen(p).generateChecks
    check white.allMoves == "[e5-e6]"

    p.color = Black
    let black = newMoveGen(p).generateChecks
    check black.allMoves == "[c4-c3]"

  # Rook with pawn on the same file (no check).
  test "generate_checks#160":
    let p = newGame("Kh8,Ra8,a6", "Ka3,Rh1,h5").start
    let white = newMoveGen(p).generateChecks
    check white.allMoves == "[]"

    p.color = Black
    let black = newMoveGen(p).generateChecks
    check black.allMoves == "[]"

  # Rook with king on the same rank (discovered check).
  test "generate_checks#170":
    let p = newGame("Ke5,Ra5,d4,e4,f4", "Kh5").start
    let white = newMoveGen(p).generateChecks
    check white.allMoves == "[Ke5-d6 Ke5-e6 Ke5-f6]"

  # Rook with king on the same file (discovered check).
  test "generate_checks#170":
    let p = newGame("Kb5,Rb8,c4,c5,c6", "Kb1").start
    let white = newMoveGen(p).generateChecks
    check white.allMoves == "[Kb5-a4 Kb5-a5 Kb5-a6]"
