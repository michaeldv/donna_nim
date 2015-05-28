# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned, strutils, unittest
import data, play, piece, move, position/moves
import generate, generate/helpers, generate/evasions

suite "GenerateEvasions":
  # Check evasions (king retreats).
  test "generate_evasions#270":
    let p = newGame("Kh6,g7", "M,Kf8").start
    let black = newMoveGen(p).generateEvasions
    check black.allMoves == "[Kf8-e7 Kf8-f7 Kf8-e8 Kf8-g8]"

  # Check evasions (king retreats).
  test "generate_evasions#280":
    let p = newGame("Ka1", "Kf8,Nc4,b2").start
    let white = newMoveGen(p).generateEvasions
    check white.allMoves == "[Ka1-b1 Ka1-a2]"

  # Check evasions (king retreats).
  test "generate_evasions#290":
    let p = newGame("Ka1,h6,g7", "M,Kf8").start
    let black = newMoveGen(p).generateEvasions
    check black.allMoves == "[Kf8-e7 Kf8-f7 Kf8-e8 Kf8-g8]"

  # Check evasions (captures/blocks by major pieces).
  test "generate_evasions#300":
    let p = newGame("Ka5,Ra8", "M,Kg8,Qf6,Re6,Bc6,Bg7,Na6,Nb6,f7,g6,h5").start
    let black = newMoveGen(p).generateEvasions
    check black.allMoves == "[Kg8-h7 Na6-b8 Nb6xa8 Nb6-c8 Bc6xa8 Bc6-e8 Re6-e8 Qf6-d8 Bg7-f8]"

  # Check evasions (double check).
  test "generate_evasions#310":
    let p = newGame("Ka1,Ra8,Nf6", "M,Kg8,Qc6,Bb7,Nb6,f7,g6,h7").start
    let black = newMoveGen(p).generateEvasions
    check black.allMoves == "[Kg8-g7]"

  # Check evasions (double check).
  test "generate_evasions#320":
    let p = newGame("Ka1,Ra8,Be5", "M,Kh8,Qd5,Bb7,Nb6").start
    let black = newMoveGen(p).generateEvasions
    check black.allMoves == "[Kh8-h7]"

  # Check evasions (pawn captures).
  test "generate_evasions#330":
    let p = newGame("Kh6,Be5", "M,Kh8,d6").start
    let black = newMoveGen(p).generateEvasions
    check black.allMoves == "[Kh8-g8 d6xe5]"

  # Check evasions (pawn captures).
  test "generate_evasions#340":
    let p = newGame("Ke1,e2,f2,g2", "Kc3,Nf3").start
    let white = newMoveGen(p).generateEvasions
    check white.allMoves == "[Ke1-d1 Ke1-f1 e2xf3 g2xf3]"

  # Check evasions (pawn blocks).
  test "generate_evasions#350":
    let p = newGame("Kf8,Ba1", "M,Kh8,b3,c4,d5,e6,f7").start
    let black = newMoveGen(p).generateEvasions
    check black.allMoves == "[Kh8-h7 b3-b2 c4-c3 d5-d4 e6-e5 f7-f6]"

  # Check evasions (pawn blocks).
  test "generate_evasions#360":
    let p = newGame("Ka5,a4,b4,c4,d4,e4,f4,h4", "Kh8,Qh5").start
    let white = newMoveGen(p).generateEvasions
    check white.allMoves == "[Ka5-a6 Ka5-b6 b4-b5 c4-c5 d4-d5 e4-e5 f4-f5]"

  # Check evasions (pawn jumps).
  test "generate_evasions#365":
    let p = newGame("Ke1,Rh4", "M,Kh6,h7").start
    let white = newMoveGen(p).generateEvasions
    check white.allMoves == "[Kh6-g5 Kh6-g6 Kh6-g7]" # No h7-h5 jump.

  # Check evasions (en-passant pawn capture).
  test "generate_evasions#370":
    let game = newGame("Kd4,d5,f5", "M,Kd8,e7")
    let black = game.start
    let white = newMoveGen(black.makeMove(newEnpassant(black, E7, E5))).generateEvasions
    check white.allMoves == "[Kd4-c3 Kd4-d3 Kd4-e3 Kd4-c4 Kd4-e4 Kd4-c5 Kd4xe5 d5xe6 f5xe6]"

  # Check evasions (en-passant pawn capture).
  test "generate_evasions#380":
    let game = newGame("Kb1,b2", "Ka5,a4,c5,c4")
    let white = game.start
    let black = newMoveGen(white.makeMove(newEnpassant(white, B2, B4))).generateEvasions
    check black.allMoves == "[Ka5xb4 Ka5-b5 Ka5-a6 Ka5-b6 c5xb4 a4xb3 c4xb3]"

  # Check evasions (en-passant pawn capture).
  test "generate_evasions#385":
    let game = newGame("Ke4,c5,e5", "M,Ke7,d7")
    let black = game.start
    let white = newMoveGen(black.makeMove(newEnpassant(black, D7, D5))).generateEvasions

    var move = white.nextMove
    while move != 0:
      if move.piece == Pawn:
        check move.to == D6
        check move.color == White
        check Piece(move.capture) == Piece(BlackPawn)
        check Piece(move.promo) == Piece(0)
      move = white.nextMove

  # Check evasions (en-passant pawn capture).
  test "generate_evasions#386":
    let p = newGame("Kf1,Qa2", "M,Kf7,b2").start
    let black = newMoveGen(p).generateEvasions
    check black.allMoves.contains("b2-a1") == false

  # Check evasions (pawn jumps).
  test "generate_evasions#390":
    let p = newGame("Kh4,a2,b2,c2,d2,e2,f2,g2", "Kd8,Ra4").start
    let white = newMoveGen(p).generateEvasions
    check white.allMoves == "[Kh4-g3 Kh4-h3 Kh4-g5 Kh4-h5 b2-b4 c2-c4 d2-d4 e2-e4 f2-f4 g2-g4]"

  # Check evasions (pawn jumps).
  test "generate_evasions#400":
    let p = newGame("Kd8,Rh5", "M,Ka5,b7,c7,d7,e7,f7,g7,h7").start
    let black = newMoveGen(p).generateEvasions
    check black.allMoves == "[Ka5-a4 Ka5-b4 Ka5-a6 Ka5-b6 b7-b5 c7-c5 d7-d5 e7-e5 f7-f5 g7-g5]"

  # Check evasions (pawn jump, sets en-passant).
  test "generate_evasions#405":
    var p = newGame("Ke1,Qd4,d5", "M,Kg7,e7,g6,h7").start
    let black = newMoveGen(p).generateEvasions
    let e7e5 = black.list[black.head + 4].move
    check black.allMoves == "[Kg7-h6 Kg7-f7 Kg7-f8 Kg7-g8 e7-e5]"
    p = p.makeMove(e7e5)
    check p.enpassant == uint8(E6)

  # Check evasions (piece x piece captures).
  test "generate_evasions#410":
    let game = newGame("Ke1,Qd1,Rc7,Bd3,Nd4,c2,f2", "M,Kh8,Nb4")
    let black = game.start
    let white = newMoveGen(black.makeMove(newMove(black, B4, C2))).generateEvasions
    check white.allMoves == "[Ke1-f1 Ke1-d2 Ke1-e2 Qd1xc2 Bd3xc2 Nd4xc2 Rc7xc2]"

  # Check evasions (pawn x piece captures).
  test "generate_evasions#420":
    let game = newGame("Ke1,Qd1,Rd7,Bf1,Nc1,c2,d3,f2", "M,Kh8,Nb4")
    let black = game.start
    let white = newMoveGen(black.makeMove(newMove(black, B4, D3))).generateEvasions
    check white.allMoves == "[Ke1-d2 Ke1-e2 c2xd3 Nc1xd3 Qd1xd3 Bf1xd3 Rd7xd3]"

  # Check evasions (king x piece captures).
  test "generate_evasions#430":
    let game = newGame("Ke1,Qf7,f2", "M,Kh8,Qh4")
    let black = game.start
    let white = newMoveGen(black.makeMove(newMove(black, H4, F2))).generateEvasions
    check white.allMoves == "[Ke1-d1 Ke1xf2 Qf7xf2]"

  # Pawn promotion to block.
  test "generate_evasions#440":
    let game = newGame("Kf1,Qf3,Nf2", "Ka1,b2")
    let white = game.start
    let black = newMoveGen(white.makeMove(newMove(white, F3, D1))).generateEvasions
    check black.allMoves == "[Ka1-a2 b2-b1Q]"

  # Pawn promotion to block or capture.
  test "generate_evasions#450":
    let game = newGame("Kf1,Qf3,Nf2", "Ka1,b2,c2")
    let white = game.start
    let black = newMoveGen(white.makeMove(newMove(white, F3, D1))).generateEvasions
    check black.allMoves == "[Ka1-a2 c2xd1Q b2-b1Q c2-c1Q]"

  # Pawn promotion to capture.
  test "generate_evasions#460":
    let game = newGame("Kf1,Qf3,Nf2", "Kc1,c2,d2")
    let white = game.start
    let black = newMoveGen(white.makeMove(newMove(white, F3, D1))).generateEvasions
    check black.allMoves == "[Kc1-b2 c2xd1Q]"
