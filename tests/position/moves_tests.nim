# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned, unittest
import data, init, bitmask, play, move, position, position/moves

suite "PositionMoves":
  # En-passant tests.
  test "position_moves#010":
    var p = newGame("Ke1,e2", "Kg8,d7,f7").start
    check p.enpassant == uint8(0)

    p = p.makeMove(newMove(p, E2, E4))
    check p.enpassant == uint8(0)

    p = p.makeMove(newMove(p, D7, D5))
    check p.enpassant == uint8(0)

    p = p.makeMove(newMove(p, E4, E5))
    check p.enpassant == uint8(0)

    p = p.makeMove(newEnpassant(p, F7, F5))
    check p.enpassant == uint8(F6)

  # Castle tests.
  test "position_moves#030":
    let p = newGame("Ke1,Ra1,Rh1", "Ke8").start
    let (kingside, queenside) = p.canCastle(p.color)
    check kingside == true
    check queenside == true

  test "position_moves#031":
    let p = newGame("Ke1", "M,Ke8,Ra8,Rh8").start
    let (kingside, queenside) = p.canCastle(p.color)
    check kingside == true
    check queenside == true

  test "position_moves#040": # King checked.
    let p = newGame("Ke1,Ra1,Rh1", "Ke8,Bg3").start
    let (kingside, queenside) = p.canCastle(p.color)
    check kingside == false
    check queenside == false

  test "position_moves#041": # King checked.
    let p = newGame("Ke1,Bg6", "M,Ke8,Ra8,Rh8").start
    let (kingside, queenside) = p.canCastle(p.color)
    check kingside == false
    check queenside == false

  test "position_moves#050": # Attacked square.
    let p = newGame("Ke1,Ra1,Rh1", "Ke8,Bb3,Bh3").start
    let (kingside, queenside) = p.canCastle(p.color)
    check kingside == false
    check queenside == false

  test "position_moves#051": # Attacked square.
    let p = newGame("Ke1,Bb6,Bh6", "M,Ke8,Ra8,Rh8").start
    let (kingside, queenside) = p.canCastle(p.color)
    check kingside == false
    check queenside == false

  test "position_moves#060": # Wrong square.
    let p = newGame("Ke1,Ra8,Rh8", "Ke5").start
    let (kingside, queenside) = p.canCastle(p.color)
    check kingside == false
    check queenside == false

  test "position_moves#061": # Wrong square.
    let p = newGame("Ke2,Ra1,Rh1", "Ke8").start
    let (kingside, queenside) = p.canCastle(p.color)
    check kingside == false
    check queenside == false

  test "position_moves#062": # Wrong square.
    let p = newGame("Ke4", "M,Ke8,Ra1,Rh1").start
    let (kingside, queenside) = p.canCastle(p.color)
    check kingside == false
    check queenside == false

  test "position_moves#063": # Wrong square.
    let p = newGame("Ke4", "M,Ke7,Ra8,Rh8").start
    let (kingside, queenside) = p.canCastle(p.color)
    check kingside == false
    check queenside == false

  test "position_moves#070": # Missing rooks.
    let p = newGame("Ke1", "Ke8").start
    let (kingside, queenside) = p.canCastle(p.color)
    check kingside == false
    check queenside == false

  test "position_moves#071": # Missing rooks.
    let p = newGame("Ke1", "M,Ke8").start
    let (kingside, queenside) = p.canCastle(p.color)
    check kingside == false
    check queenside == false

  test "position_moves#080": # Rooks on wrong squares.
    let p = newGame("Ke1,Rb1", "Ke8").start
    let (kingside, queenside) = p.canCastle(p.color)
    check kingside == false
    check queenside == false

  test "position_moves#081": # Rooks on wrong squares.
    let p = newGame("Ke1,Rb1,Rh1", "Ke8").start
    let (kingside, queenside) = p.canCastle(p.color)
    check kingside == true
    check queenside == false

  test "position_moves#082": # Rooks on wrong squares.
    let p = newGame("Ke1,Ra1,Rf1", "Ke8").start
    let (kingside, queenside) = p.canCastle(p.color)
    check kingside == false
    check queenside == true

  test "position_moves#090": # Rook has moved.
    var p = newGame("Ke1,Ra1,Rh1", "Ke8").start
    p = p.makeMove(newMove(p, A1, A2))
    p = p.makeMove(newMove(p, E8, E7))
    p = p.makeMove(newMove(p, A2, A1))

    let (kingside, queenside) = p.canCastle(White)
    check kingside == true
    check queenside == false

  test "position_moves#091": # King has moved.
    var p = newGame("Ke1", "M,Ke8,Ra8,Rh8").start
    p = p.makeMove(newMove(p, E8, E7))
    p = p.makeMove(newMove(p, E1, E2))
    p = p.makeMove(newMove(p, E7, E8))

    let (kingside, queenside) = p.canCastle(Black)
    check kingside == false
    check queenside == false

  test "position_moves#092": # Rook is taken.
    var p = newGame("Ke1,Nb6", "Ke8,Ra8,Rh8").start
    p = p.makeMove(newMove(p, B6, A8))

    let (kingside, queenside) = p.canCastle(Black)
    check kingside == true
    check queenside == false

  test "position_moves#093": # Blocking kingside knight.
    let p = newGame("Ke1", "M,Ke8,Ra8,Rh8,Ng8").start

    let (kingside, queenside) = p.canCastle(Black)
    check kingside == false
    check queenside == true

  test "position_moves#094": # Blocking queenside knight.
    let p = newGame("Ke1", "M,Ke8,Ra8,Rh8,Nb8").start

    let (kingside, queenside) = p.canCastle(Black)
    check kingside == true
    check queenside == false

  # Straight repetition.
  test "position_moves#100":
    var p = newGame().start            # Initial 1.
    p = p.makeMove(newMove(p, G1, F3))
    p = p.makeMove(newMove(p, G8, F6)) # 1.
    check p.repetition() == false
    check p.thirdRepetition() == false

    p = p.makeMove(newMove(p, F3, G1))
    p = p.makeMove(newMove(p, F6, G8)) # Initial 2.
    check p.repetition() == true
    check p.thirdRepetition() == false

    p = p.makeMove(newMove(p, G1, F3))
    p = p.makeMove(newMove(p, G8, F6)) # 2.
    check p.repetition() == true
    check p.thirdRepetition() == false

    p = p.makeMove(newMove(p, F3, G1))
    p = p.makeMove(newMove(p, F6, G8)) # Initial 3.
    check p.repetition() == true
    check p.thirdRepetition() == true

    p = p.makeMove(newMove(p, G1, F3))
    p = p.makeMove(newMove(p, G8, F6)) # 3.
    check p.repetition() == true
    check p.thirdRepetition() == true

  # Repetition with some moves in between.
  test "position_moves#110":
    var p = newGame().start
    p = p.makeMove(newMove(p, E2, E4))
    p = p.makeMove(newMove(p, E7, E5))
    p = p.makeMove(newMove(p, G1, F3))
    p = p.makeMove(newMove(p, G8, F6)) # 1.
    p = p.makeMove(newMove(p, B1, C3))
    p = p.makeMove(newMove(p, B8, C6))
    p = p.makeMove(newMove(p, F1, C4))
    p = p.makeMove(newMove(p, F8, C5))
    p = p.makeMove(newMove(p, C3, B1))
    p = p.makeMove(newMove(p, C6, B8))
    p = p.makeMove(newMove(p, C4, F1))
    p = p.makeMove(newMove(p, C5, F8)) # 2.
    check p.repetition() == true
    check p.thirdRepetition() == false

    p = p.makeMove(newMove(p, F1, C4))
    p = p.makeMove(newMove(p, F8, C5))
    p = p.makeMove(newMove(p, B1, C3))
    p = p.makeMove(newMove(p, B8, C6))
    p = p.makeMove(newMove(p, C4, F1))
    p = p.makeMove(newMove(p, C5, F8))
    p = p.makeMove(newMove(p, C3, B1))
    p = p.makeMove(newMove(p, C6, B8)) # 3.
    check p.repetition() == true
    check p.thirdRepetition() == true

  # Irreversible 0-0.
  test "position_moves#120":
    var p = newGame("Ke1,Rh1,h2", "Ke8,Ra8,a7").start
    p = p.makeMove(newMove(p, H2, H4))
    p = p.makeMove(newMove(p, A7, A5)) # 1.
    p = p.makeMove(newMove(p, E1, E2))
    p = p.makeMove(newMove(p, E8, E7)) # King has moved.
    p = p.makeMove(newMove(p, E2, E1))
    p = p.makeMove(newMove(p, E7, E8)) # 2.
    p = p.makeMove(newMove(p, E1, E2))
    p = p.makeMove(newMove(p, E8, E7)) # King has moved again.
    p = p.makeMove(newMove(p, E2, E1))
    p = p.makeMove(newMove(p, E7, E8)) # 3.
    check p.repetition() == true
    check p.thirdRepetition() == false # <-- Lost 0-0 right.

    p = p.makeMove(newMove(p, E1, E2))
    p = p.makeMove(newMove(p, E8, E7)) # King has moved again.
    p = p.makeMove(newMove(p, E2, E1))
    p = p.makeMove(newMove(p, E7, E8)) # 4.
    check p.repetition() == true
    check p.thirdRepetition() == true  # <-- 3 time repetioion with lost 0-0 right.

  # 50 moves draw (no captures, no pawn moves).
  test "position_moves#130":
    var p = newGame("Kh8,Ra1", "Ka8,a7,b7").start
    let squares: array[64, int] = [
      A1, B1, C1, D1, E1, F1, G1, H1,
      H2, G2, F2, E2, D2, C2, B2, A2,
      A3, B3, C3, D3, E3, F3, G3, H3,
      H4, G4, F4, E4, D4, C4, B4, A4,
      A5, B5, C5, D5, E5, F5, G5, H5,
      H6, G6, F6, E6, D6, C6, B6, A6,
      A5, B5, C5, D5, E5, F5, G5, H5,
      H4, G4, F4, E4, D4, C4, B4, A4,
    ]

    # White rook is zigzaging while black king bounces back and forth.
    for move in 1 ..< len(squares):
      p = p.makeMove(newMove(p, squares[move - 1], squares[move]))
      if p.king[Black] == A8:
        p = p.makeMove(newMove(p, A8, B8))
      else:
        p = p.makeMove(newMove(p, B8, A8))
      check p.fifty() == (move >= 50)
  
  # Incremental hash recalculation tests (see book_test.go).
  test "position_moves#200":
    var p = newGame().start
    p = p.makeMove(newMove(p, E2, E4))
    let (id, pawnId) = p.polyglot

    check id == uint64(0x823C9B50FD114196)
    check id == p.id
    check pawnId == uint64(0x0B2D6B38C0B92E91)
    check pawnId == p.pawnId

    # check p.balance, len(materialBase) - 1)
    check p.enpassant == uint8(0)
    check p.castles == uint8(0x0F)

  test "position_moves#210": # 1. e4 d5
    var p = newGame().start
    p = p.makeMove(newMove(p, E2, E4))
    p = p.makeMove(newMove(p, D7, D5))
    let (id, pawnId) = p.polyglot

    check id == uint64(0x0756B94461C50FB0)
    check id == p.id
    check pawnId == uint64(0x76916F86F34AE5BE)
    check pawnId == p.pawnId

    # check p.balance, len(materialBase) - 1)
    check p.enpassant == uint8(0)
    check p.castles == uint8(0x0F)

  test "position_moves#220": # 1. e4 d5 2. e5
    var p = newGame().start
    p = p.makeMove(newMove(p, E2, E4))
    p = p.makeMove(newMove(p, D7, D5))
    p = p.makeMove(newMove(p, E4, E5))
    let (id, pawnId) = p.polyglot

    check id == uint64(0x662FAFB965DB29D4)
    check id == p.id
    check pawnId == uint64(0xEF3E5FD1587346D3)
    check pawnId == p.pawnId

    # check p.balance, len(materialBase) - 1)
    check p.enpassant == uint8(0)
    check p.castles == uint8(0x0F)

  test "position_moves#230": # 1. e4 d5 2. e5 f5 <-- Enpassant
    var p = newGame().start
    p = p.makeMove(newMove(p, E2, E4))
    p = p.makeMove(newMove(p, D7, D5))
    p = p.makeMove(newMove(p, E4, E5))
    p = p.makeMove(newEnpassant(p, F7, F5))
    let (id, pawnId) = p.polyglot

    check id == uint64(0x22A48B5A8E47FF78)
    check id == p.id
    check pawnId == uint64(0x83871FE249DCEE04)
    check pawnId == p.pawnId

    # check p.balance, len(materialBase) - 1)
    check p.enpassant == uint8(F6)
    check p.castles == uint8(0x0F)

  test "position_moves#240": # 1. e4 d5 2. e5 f5 3. Ke2 <-- White Castle
    var p = newGame().start
    p = p.makeMove(newMove(p, E2, E4))
    p = p.makeMove(newMove(p, D7, D5))
    p = p.makeMove(newMove(p, E4, E5))
    p = p.makeMove(newMove(p, F7, F5))
    p = p.makeMove(newMove(p, E1, E2))
    let (id, pawnId) = p.polyglot

    check id == uint64(0x652A607CA3F242C1)
    check id == p.id
    check pawnId == uint64(0x83871FE249DCEE04)
    check pawnId == p.pawnId

    # check p.balance, len(materialBase) - 1)
    check p.enpassant == uint8(0)
    check p.castles == (castleKingside[Black] or castleQueenside[Black])

  test "position_moves#250": # 1. e4 d5 2. e5 f5 3. Ke2 Kf7 <-- Black Castle
    var p = newGame().start
    p = p.makeMove(newMove(p, E2, E4))
    p = p.makeMove(newMove(p, D7, D5))
    p = p.makeMove(newMove(p, E4, E5))
    p = p.makeMove(newMove(p, F7, F5))
    p = p.makeMove(newMove(p, E1, E2))
    p = p.makeMove(newMove(p, E8, F7))
    let (id, pawnId) = p.polyglot

    check id == uint64(0x00FDD303C946BDD9)
    check id == p.id
    check pawnId == uint64(0x83871FE249DCEE04)
    check pawnId == p.pawnId

    # check p.balance, len(materialBase) - 1)
    check p.enpassant == uint8(0)
    check p.castles == uint8(0)

  test "position_moves#260": # 1. a2a4 b7b5 2. h2h4 b5b4 3. c2c4 <-- Enpassant
    var p = newGame().start
    p = p.makeMove(newMove(p, A2, A4))
    p = p.makeMove(newMove(p, B7, B5))
    p = p.makeMove(newMove(p, H2, H4))
    p = p.makeMove(newMove(p, B5, B4))
    p = p.makeMove(newEnpassant(p, C2, C4))
    let (id, pawnId) = p.polyglot

    check id == uint64(0x3C8123EA7B067637)
    check id == p.id
    check pawnId == uint64(0xB5AA405AF42E7052)
    check pawnId == p.pawnId

    # check p.balance, len(materialBase) - 1)
    check p.enpassant == uint8(C3)
    check p.castles == uint8(0x0F)

  test "position_moves#270": # 1. a2a4 b7b5 2. h2h4 b5b4 3. c2c4 b4xc3 4. Ra1a3 <-- Enpassant/Castle
    var p = newGame().start
    p = p.makeMove(newMove(p, A2, A4))
    p = p.makeMove(newMove(p, B7, B5))
    p = p.makeMove(newMove(p, H2, H4))
    p = p.makeMove(newMove(p, B5, B4))
    p = p.makeMove(newEnpassant(p, C2, C4))
    p = p.makeMove(newMove(p, B4, C3))
    p = p.makeMove(newMove(p, A1, A3))
    let (id, pawnId) = p.polyglot

    check id == uint64(0x5C3F9B829B279560)
    check id == p.id
    check pawnId == uint64(0xE214F040EAA135A0)
    check pawnId == p.pawnId

    # check p.balance == len(materialBase) - 1 - materialBalance[Pawn])
    check p.enpassant == uint8(0)
    check p.castles == (castleKingside[White] or castleKingside[Black] or castleQueenside[Black])

  # Incremental material hash calculation.  
  test "position_moves#280": # 1. e4 d5 2. e4xd5
    var p = newGame().start
    p = p.makeMove(newMove(p, E2, E4))
    p = p.makeMove(newMove(p, D7, D5))
    p = p.makeMove(newMove(p, E4, D5))

    check p.balance == (len(materialBase) - 1 - materialBalance[BlackPawn])

  test "position_moves#281": # 1. e4 d5 2. e4xd5 Ng8-f6 3. Nb1-c3 Nf6xd5
    var p = newGame().start
    p = p.makeMove(newMove(p, E2, E4))
    p = p.makeMove(newMove(p, D7, D5))
    p = p.makeMove(newMove(p, E4, D5))
    p = p.makeMove(newMove(p, G8, F6))
    p = p.makeMove(newMove(p, B1, C3))
    p = p.makeMove(newMove(p, F6, D5))

    check p.balance == (len(materialBase) - 1 - materialBalance[Pawn] - materialBalance[BlackPawn])

  test "position_moves#282": # 1. e4 d5 2. e4xd5 Ng8-f6 3. Nb1-c3 Nf6xd5 4. Nc3xd5 Qd8xd5
    var p = newGame().start
    p = p.makeMove(newMove(p, E2, E4))
    p = p.makeMove(newMove(p, D7, D5))
    p = p.makeMove(newMove(p, E4, D5))
    p = p.makeMove(newMove(p, G8, F6))
    p = p.makeMove(newMove(p, B1, C3))
    p = p.makeMove(newMove(p, F6, D5))
    p = p.makeMove(newMove(p, C3, D5))
    p = p.makeMove(newMove(p, D8, D5))

    check p.balance == (len(materialBase) - 1 - materialBalance[Pawn] - materialBalance[Knight] - materialBalance[BlackPawn] - materialBalance[BlackKnight])

  # Pawn promotion.
  test "position_moves#283":
    var p = newGame("Kh1", "M,Ka8,a2,b7").start
    check p.balance == (2 * materialBalance[BlackPawn])

    p = p.makeMove(newMove(p, A2, A1).promote(Rook))
    check p.balance == (materialBalance[BlackPawn] + materialBalance[BlackRook])

  # Last pawn promotion.
  test "position_moves#284":
    var p = newGame("Kh1", "M,Ka8,a2").start
    check p.balance == materialBalance[BlackPawn]

    p = p.makeMove(newMove(p, A2, A1).promote(Rook))
    check p.balance == materialBalance[BlackRook]

  # Pawn promotion with capture.
  test "position_moves#285":
    var p = newGame("Kh1,Nb1,Ng1", "M,Ka8,a2,b7").start
    check p.balance == (2 * materialBalance[Knight] + 2 * materialBalance[BlackPawn])

    p = p.makeMove(newMove(p, A2, B1).promote(Queen))
    check p.balance == (materialBalance[Knight] + materialBalance[BlackPawn] + materialBalance[BlackQueen])

  # Pawn promotion with last piece capture.
  test "position_moves#286":
    var p = newGame("Kh1,Nb1", "M,Ka8,a2,b7").start
    check p.balance == (materialBalance[Knight] + 2 * materialBalance[BlackPawn])

    p = p.makeMove(newMove(p, A2, B1).promote(Queen))
    check p.balance == (materialBalance[BlackPawn] + materialBalance[BlackQueen])

  # Last pawn promotion with capture.
  test "position_moves#287":
    var p = newGame("Kh1,Nb1,Ng1", "M,Ka8,a2").start
    check p.balance == (2 * materialBalance[Knight] + materialBalance[BlackPawn])

    p = p.makeMove(newMove(p, A2, B1).promote(Queen))
    check p.balance == (materialBalance[Knight] + materialBalance[BlackQueen])

  # Last pawn promotion with last piece capture.
  test "position_moves#288":
    var p = newGame("Kh1,Nb1", "M,Ka8,a2").start
    check p.balance == (materialBalance[Knight] + materialBalance[BlackPawn])

    p = p.makeMove(newMove(p, A2, B1).promote(Queen))
    check p.balance == materialBalance[BlackQueen]

  # Capture.
  test "position_moves#289":
    var p = newGame("Kh1,Nc3,Nf3", "M,Ka8,d4,e4").start
    check p.balance == (2 * materialBalance[Knight] + 2 * materialBalance[BlackPawn])

    p = p.makeMove(newMove(p, D4, C3))
    check p.balance == (materialBalance[Knight] + 2 * materialBalance[BlackPawn])

  # Last piece capture.
  test "position_moves#290":
    var p = newGame("Kh1,Nc3", "M,Ka8,d4,e4").start
    check p.balance == (materialBalance[Knight] + 2 * materialBalance[BlackPawn])

    p = p.makeMove(newMove(p, D4, C3))
    check p.balance == (2 * materialBalance[BlackPawn])

  # En-passant capture: 1. e2-e4 e7-e6 2. e4-e5 d7-d5 3. e4xd5
  test "position_moves#291":
    var p = newGame().start
    check p.balance == (len(materialBase) - 1)

    p = p.makeMove(newMove(p, E2, E4))
    p = p.makeMove(newMove(p, E7, E6))
    p = p.makeMove(newMove(p, E4, E5))
    p = p.makeMove(newEnpassant(p, D7, D5))
    p = p.makeMove(newMove(p, E5, D6))
    check p.balance == (len(materialBase) - 1 - materialBalance[BlackPawn])

  # Last pawn en-passant capture.
  test "position_moves#292":
    var p = newGame("Kh1,c2", "Ka8,d4").start
    check p.balance == (materialBalance[Pawn] + materialBalance[BlackPawn])

    p = p.makeMove(newEnpassant(p, C2, C4))
    p = p.makeMove(newMove(p, D4, C3))
    check p.balance == materialBalance[BlackPawn]

  # Unobstructed pins.
  test "position_moves#300":
    let p = newGame("Ka1,Qe1,Ra8,Rh8,Bb5", "Ke8,Re7,Bc8,Bf8,Nc6").start
    let pinned = p.pinnedMask(E8)

    check pinned == (bit[C6] or bit[C8] or bit[E7] or bit[F8])

  test "position_moves#310":
    let p = newGame("Ke4,Qe5,Rd5,Nd4,Nf4", "M,Ka7,Qe8,Ra4,Rh4,Ba8").start
    let pinned = p.pinnedMask(E4)

    check pinned == (bit[D5] or bit[E5] or bit[D4] or bit[F4])

  # Not a pin (friendly blockers).
  test "position_moves#320":
    let p = newGame("Ka1,Qe1,Ra8,Rh8,Bb5,Nb8,Ng8,e4", "Ke8,Re7,Bc8,Bf8,Nc6").start
    let pinned = p.pinnedMask(E8)

    check pinned == bit[C6]

  test "position_moves#330":
    let p = newGame("Ke4,Qe7,Rc6,Nb4,Ng4", "M,Ka7,Qe8,Ra4,Rh4,Ba8,c4,e6,f4").start
    let pinned = p.pinnedMask(E4)

    check pinned == bit[C6]

  # Not a pin (enemy blockers).
  test "position_moves#340":
    let p = newGame("Ka1,Qe1,Ra8,Rh8,Bb5", "Ke8,Re7,Rg8,Bc8,Bf8,Nc6,Nb8,e4").start
    let pinned = p.pinnedMask(E8)

    check pinned == bit[C6]

  test "position_moves#350":
    let p = newGame("Ke4,Qe7,Rc6,Nb4,Ng4,c4,e5,f4", "M,Ka7,Qe8,Ra4,Rh4,Ba8").start
    let pinned = p.pinnedMask(E4)

    check pinned == bit[C6]

  # Position after null move.
  test "position_moves#400":
    var p = newGame("Ke1,Qd1,d2,e2", "Kg8,Qf8,f7,g7").start
    p = p.makeNullMove()
    check p.isNull() == true

    p = p.undoNullMove()
    p = p.makeMove(newMove(p, E2, E4))
    check p.isNull() == false

  # isInCheck
  test "position_moves#410":
    var p = newGame().start
    p = p.makeMove(newMove(p, E2, E4))
    p = p.makeMove(newMove(p, F7, F6))
    let position = p.makeMove(newMove(p, D1, H5))

    check position.isInCheck(position.color) == true
    check position.isInCheck(p.color xor 1) == true

