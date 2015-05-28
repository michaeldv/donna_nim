# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned, unittest
import types, play, data, move
import generate, generate/helpers, generate/captures

suite "GenerateCaptures":
  # Piece captures.
  test "generate_captures#000":
    let p = newGame("Ka1,Qd1,Rh1,Bb3,Ne5", "Ka8,Qd8,Rh8,Be6,Ng6").start
    let white = newMoveGen(p).generateCaptures
    check white.allMoves == "[Qd1xd8 Rh1xh8 Bb3xe6 Ne5xg6]"

    p.color = Black
    let black = newMoveGen(p).generateCaptures
    check black.allMoves == "[Be6xb3 Ng6xe5 Qd8xd1 Rh8xh1]"

  # Pawn captures on rows 2-6 (no promotions).
  test "generate_captures#010":
    let p = newGame("Ka1,b3,c4,d5", "Ka8,a4,b5,c6,e6").start
    let white = newMoveGen(p).generateCaptures
    check white.allMoves == "[b3xa4 c4xb5 d5xc6 d5xe6]"

    p.color = Black
    let black = newMoveGen(p).generateCaptures
    check black.allMoves == "[a4xb3 b5xc4 c6xd5 e6xd5]"

  # Pawn captures with promotion, rows 1-7.
  test "generate_captures#020":
    let p = newGame("Ka1,Bh1,Ng1,a2,b7,e7", "Kb8,Rd8,Be8,Rf8,h2").start
    let white = newMoveGen(p).generateCaptures
    check white.allMoves == "[e7xd8Q e7xd8R e7xd8B e7xd8N e7xf8Q e7xf8R e7xf8B e7xf8N]"

    p.color = Black
    let black = newMoveGen(p).generateCaptures
    check black.allMoves == "[h2xg1Q h2xg1R h2xg1B h2xg1N Kb8xb7]"

  # Pawn promotions without capture, rows 1-7.
  test "generate_captures#030":
    let p = newGame("Ka1,a2,e7", "Ka8,Rd8,a7,h2").start
    let white = newMoveGen(p).generateCaptures
    check white.allMoves == "[e7xd8Q e7xd8R e7xd8B e7xd8N e7-e8Q e7-e8R e7-e8B e7-e8N]"

    p.color = Black
    let black = newMoveGen(p).generateCaptures
    check black.allMoves == "[h2-h1Q h2-h1R h2-h1B h2-h1N]"

  # Captures/promotions sort order.
  test "generate_captures#100":
    let p = newGame("Kg1,Qh4,Rg2,Rf1,Nd6,f7", "Kh8,Qc3,Rd8,Rd7,Ne6,a3,h7").start
    let gen = newMoveGen(p).generateCaptures
    check gen.allMoves == "[f7-f8Q f7-f8R f7-f8B f7-f8N Qh4xh7 Qh4xd8]"

  test "generate_captures#110":
    let p = newGame("Kg1,Qh4,Rg2,Rf1,Nd6,f7", "Kh8,Qc3,Rd8,Rd7,Ne6,a3,h7").start
    let gen = newMoveGen(p).generateCaptures.rank(Move(0))
    check gen.allMoves == "[f7-f8Q Qh4xd8 f7-f8R f7-f8B f7-f8N Qh4xh7]"

  test "generate_captures#120":
    let p = newGame("Kg1,Qh4,Rg2,Rf1,Nd6,f7", "Kh8,Qc3,Rd8,Rd7,Ne6,a3,h7").start
    let gen = newMoveGen(p).generateCaptures.quickRank()
    check gen.allMoves == "[f7-f8Q Qh4xd8 f7-f8R f7-f8B f7-f8N Qh4xh7]"
