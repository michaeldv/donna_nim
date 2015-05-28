# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned, unittest
import types, params, data, play, move
import search, search/tree, search/quiescence

suite "Search":

  # Mate in 2.

  test "search#000":
    # The very first chess puzzle I had solved as a kid.
    let move = newGame("Kf8,Rh1,g6", "Kh8,Bg8,g7,h7").start.solve(3)
    check move.toString == "Rh1-h6"

  test "search#020":
    let move = newGame("Kf4,Qc2,Nc5", "Kd4").start.solve(3)
    check move.toString == "Nc5-b7"

  test "search#030":
    let move = newGame("Kf2,Qf7,Nf3", "Kg4").start.solve(3)
    check move.toString == "Qf7-f6"

  test "search#040":
    let move = newGame("Kc3,Qc2,Ra4", "Kb5").start.solve(3)
    check move.toString == "Qc2-g6"

  test "search#050":
    let move = newGame("Ke5,Qc1,Rf3,Bg2", "Ke2,Nd5,Nb1").start.solve(3)
    check move.toString == "Rf3-d3"

  test "search#060":
    let move = newGame("Kf1,Qa8,Bf7,Ng2", "Kg4").start.solve(3)
    check move.toString == "Qa8-b8"

  test "search#070":
    let move = newGame("Ke5,Rd3,Bb1", "Kh7").start.solve(3)
    check move.toString == "Ke5-f6"

  # Puzzles with pawns.

  test "search#080":
    let move = newGame("Kg3,Bc1,Nc3,Bg2", "Kg1,Re1,e3").start.solve(3)
    check move.toString == "Bc1-a3"

  test "search#090":
    let move = newGame("Kf2,Qb8,Be7,f3", "Kh5,h6,g5").start.solve(3)
    check move.toString == "Qb8-b1"

  test "search#100":
    let move = newGame("Ke6,Qg3,b3,c2", "Ke4,e7,f5").start.solve(3)
    check move.toString == "b3-b4"

  test "search#110":
    let move = newGame("Kf1,Qh6,Nd2,Nf2", "Kc1,c2,c3").start.solve(3)
    check move.toString == "Qh6-a6"

  test "search#120":
    let move = newGame("Kd5,Qc8,c5,e5,g6", "Ke7,d7").start.solve(3)
    check move.toString == "Kd5-e4"

  test "search#130":
    let move = newGame("Ke7,Rf8,Ba3,Bc2,e5,g5", "Kg7,c3,h7").start.solve(3)
    check move.toString == "Ba3-c1"

  test "search#140":
    let move = newGame("Kc6,Rh4,Bb5,a3,c2,d3", "Ka5,c5,d4,h5").start.solve(3)
    check move.toString == "c2-c4"

  test "search#150":
    let move = newGame("Kb4,Qg7,Nc1", "Kb1").start.solve(3)
    check move.toString == "Kb4-c3"

  test "search#160":
    let move = newGame("Ka8,Qc4,b7", "Ka5").start.solve(3)
    check move.toString == "b7-b8B"

  test "search#170":
    let move = newGame("Kf8,Rc6,Be4,Nd7,c7", "Ke6,d6").start.solve(3)
    check move.toString == "c7-c8R"

  test "search#180":
    let move = newGame("Kc6,c7", "Ka7").start.solve(3)
    check move.toString == "c7-c8R"

  test "search#190":
    let move = newGame("Kc4,a7,c7", "Ka5").start.solve(3)
    check move.toString == "c7-c8N"

  test "search#195":
    let move = newGame("Ke1,Rf1,Rh1", "Ka1").start.solve(3)
    check move.toString == "Rf1-f2"

  test "search#196":
    let move = newGame("Ke1,Ra1,Rb1", "Kg1").start.solve(3)
    check move.toString == "Rb1-b2"

  # Mate in 3.

  test "search#200":
    let move = newGame("Kf8,Re7,Nd5", "Kh8,Bh5").start.solve(5)
    check move.toString == "Re7-g7"

  test "search#210":
    let move = newGame("Kf8,Bf7,Nf3,e5", "Kh8,e6,h7").start.solve(5)
    check move.toString == "Bf7-g8"

  test "search#220":
    let move = newGame("Kf3,h7", "Kh1,h3").start.solve(5)
    check move.toString == "h7-h8R"

  test "search#230":
    let move = newGame("Kd8,c7,e4,f7", "Ke6,e5").start.solve(5)
    check move.toString == "f7-f8R"

  test "search#240":
    let move = newGame("Kh3,f7,g7", "Kh6").start.solve(5)
    check move.toString == "g7-g8Q"

  test "search#250":
    let move = newGame("Ke4,c7,d6,e7,f6,g7", "Ke6").start.solve(5)
    check move.toString == "e7-e8B"


  # Mate in 4.

  test "search#260":
    let move = newGame("Kf6,Nf8,Nh6", "Kh8,f7,h7").start.solve(7)
    check move.toString == "Nf8-e6"

  test "search#270":
    let move = newGame("Kf2,e7", "Kh1,d2").start.solve(7)
    check move.toString == "e7-e8R"

  test "search#280":
    let move = newGame("Kc1,Nb4,a2", "Ka1,b5").start.solve(7)
    check move.toString == "a2-a4"

  test "search#290":
    let move = newGame("Kh6,Rd3,h7", "Kh8,Bd7").start.solve(7)
    check move.toString == "Rd3-d6"

  test "search#300":
    let move = newGame("Kc6,Bc1,Ne5", "Kc8,Ra8,a7,a6").start.solve(7)
    check move.toString == "Ne5-f7"

  # Perft.

  test "perft#000":
    let p = newGame().start
    check p.perft(0) == 1'i64

  test "perft#010":
    let p = newGame().start
    check p.perft(1) == 20'i64

  test "perft#020":
    let p = newGame().start
    check p.perft(2) == 400'i64

  test "perft#030":
    let p = newGame().start
    check p.perft(3) == 8_902'i64

  test "perft#040":
    let p = newGame().start
    check p.perft(4) == 197_281'i64

  test "perft#050":
    let p = newGame().start
    check p.perft(5) == 4_865_609'i64

