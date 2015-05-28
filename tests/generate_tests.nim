# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned, unittest
import types, data, bitmask, piece, move, play, position, position/moves
import generate, generate/root, generate/captures

suite "Generate":
  test "generate#010":
    # Default move ordering.
    let game = newGame("Ka1,a2,b3,c4,d2,e6,f5,g4,h3", "Kc1")
    let gen = newMoveGen(game.start).generateMoves.rank(Move(0))
    check gen.allMoves == "[a2-a3 a2-a4 d2-d3 d2-d4 b3-b4 h3-h4 c4-c5 g4-g5 f5-f6 e6-e7 Ka1-b1 Ka1-b2]"

  # LVA/MVV capture ordering.
  test "generate#110":
    let p = newGame("Kd4,e4,Nf4,Bc4,Ra5,Qh5", "Kd8,Qd5").start
    let gen = newMoveGen(p).generateCaptures.rank(Move(0))

    check gen.allMoves == "[e4xd5 Nf4xd5 Bc4xd5 Ra5xd5 Qh5xd5 Kd4xd5]"

  test "generate#120":
    let p = newGame("Kd4,e4,Nf4,Bc4,Ra5,Qh5", "Kd8,Qd5,Rf5").start
    let gen = newMoveGen(p).generateCaptures.rank(Move(0))

    check gen.allMoves == "[e4xd5 Nf4xd5 Bc4xd5 Ra5xd5 Kd4xd5 e4xf5 Qh5xf5]"

  test "generate#130":
    let p = newGame("Kd4,e4,Nf4,Bc4,Ra5,Qh5", "Kd8,Qd5,Rf5,Bg6").start
    let gen = newMoveGen(p).generateCaptures.rank(Move(0))

    check gen.allMoves == "[e4xd5 Nf4xd5 Bc4xd5 Ra5xd5 Kd4xd5 e4xf5 Qh5xf5 Nf4xg6 Qh5xg6]"

  test "generate#140":
    let p = newGame("Kd4,e4,Nf4,Bc4,Ra5,Qh5", "Kd8,Qd5,Rf5,Bg6,Nh3").start
    let gen = newMoveGen(p).generateCaptures().rank(Move(0))

    check gen.allMoves == "[e4xd5 Nf4xd5 Bc4xd5 Ra5xd5 Kd4xd5 e4xf5 Qh5xf5 Nf4xg6 Qh5xg6 Nf4xh3 Qh5xh3]"

  test "generate#150":
    let p = newGame("Kd4,e4,Nf4,Bc4,Ra5,Qh5", "Kd8,Qd5,Rf5,Bg6,Nh3,e2").start
    let gen = newMoveGen(p).generateCaptures.rank(Move(0))

    check gen.allMoves == "[e4xd5 Nf4xd5 Bc4xd5 Ra5xd5 Kd4xd5 e4xf5 Qh5xf5 Nf4xg6 Qh5xg6 Nf4xh3 Qh5xh3 Nf4xe2 Bc4xe2 Qh5xe2]"

  # Vaditaing generated moves.
  test "generate#200":
    var p = newGame("Ke1,Qe2,d2", "Ke8,e4").start
    p = p.makeMove(newEnpassant(p, D2, D4))

    # No e4xd3 en-passant capture.
    let black = newMoveGen(p).generateMoves.validOnly
    check black.allMoves == "[e4-e3 Ke8-d7 Ke8-e7 Ke8-f7 Ke8-d8 Ke8-f8]"

  test "generate#210":
    var p = newGame("Ke1,Qg2,d2", "Ka8,e4").start
    p = p.makeMove(newEnpassant(p, D2, D4))

    # Neither e4-e3 nor e4xd3 en-passant capture.
    let black = newMoveGen(p).generateMoves.validOnly
    check black.allMoves == "[Ka8-a7 Ka8-b7 Ka8-b8]"
