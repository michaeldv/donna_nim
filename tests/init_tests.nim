# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned, unittest
import bitmask, data, init, play

suite "Init":
  test "init#000":
    check maskBlock[C3][H8] == (bit[D4] or bit[E5] or bit[F6] or bit[G7] or bit[H8])
    check maskBlock[C3][C8] == (bit[C4] or bit[C5] or bit[C6] or bit[C7] or bit[C8])
    check maskBlock[C3][A5] == (bit[B4] or bit[A5])
    check maskBlock[C3][A3] == (bit[B3] or bit[A3])
    check maskBlock[C3][A1] == (bit[B2] or bit[A1])
    check maskBlock[C3][C1] == (bit[C2] or bit[C1])
    check maskBlock[C3][E1] == (bit[D2] or bit[E1])
    check maskBlock[C3][H3] == (bit[D3] or bit[E3] or bit[F3] or bit[G3] or bit[H3])
    check maskBlock[C3][E7] == maskNone

  test "init#010":
    check maskEvade[C3][H8] == (not bit[B2])
    check maskEvade[C3][C8] == (not bit[C2])
    check maskEvade[C3][A5] == (not bit[D2])
    check maskEvade[C3][A3] == (not bit[D3])
    check maskEvade[C3][A1] == (not bit[D4])
    check maskEvade[C3][C1] == (not bit[C4])
    check maskEvade[C3][E1] == (not bit[B4])
    check maskEvade[C3][H3] == (not bit[B3])
    check maskEvade[C3][E7] == maskFull

  test "init#020":
    check maskPawn[White][A3] == bit[B2]
    check maskPawn[White][D5] == (bit[C4] or bit[E4])
    check maskPawn[White][F8] == (bit[E7] or bit[G7])
    check maskPawn[Black][H4] == bit[G5]
    check maskPawn[Black][C5] == (bit[B6] or bit[D6])
    check maskPawn[Black][B1] == (bit[A2] or bit[C2])

  # Same file.
  test "init#030":
    check maskStraight[A2][A5] == maskFile[0]
    check maskStraight[H6][H1] == maskFile[7]
    # Same rank.
    check maskStraight[A2][F2] == maskRank[1]
    check maskStraight[H6][B6] == maskRank[5]
    # Edge cases.
    check maskStraight[A1][C5] == maskNone # Random squares.
    check maskStraight[E4][E4] == maskNone # Same square.

  # Same diagonal.
  test "init#040":
    check maskDiagonal[C4][F7] == (bit[A2] or bit[B3] or bit[C4] or bit[D5] or bit[E6] or bit[F7] or bit[G8])
    check maskDiagonal[F6][H8] == maskA1H8
    check maskDiagonal[F1][H3] == (bit[F1] or bit[G2] or bit[H3])
    # Same anti-diagonal.
    check maskDiagonal[C2][B3] == (bit[D1] or bit[C2] or bit[B3] or bit[A4])
    check maskDiagonal[F3][B7] == maskH1A8
    check maskDiagonal[H3][D7] == (bit[H3] or bit[G4] or bit[F5] or bit[E6] or bit[D7] or bit[C8])
    # Edge cases.
    check maskDiagonal[A2][G4] == maskNone # Random squares.
    check maskDiagonal[E4][E4] == maskNone # Same square.

    # Material base tests.

  # Bare kings.
  test "init_material#000":
    let balance = materialBalance[King] + materialBalance[BlackKing]
    check balance == 0
    check materialBase[balance].flags == uint8(materialDraw)
    # check materialBase[balance].endgame == nil

    let p = newGame("Ke1", "Ke8").start
    check p.balance == balance

  # No pawns, king with a minor.
  test "init_material#010":
    let balance = materialBalance[Bishop]
    check materialBase[balance].flags == uint8(materialDraw)
    # check materialBase[balance].endgame == nil

    let p = newGame("Ke1,Bc1", "Ke8").start
    check p.balance == balance

  test "init_material#015":
    let balance = materialBalance[Bishop] + materialBalance[BlackKnight]
    check materialBase[balance].flags == uint8(materialDraw)
    # check materialBase[balance].endgame == nil

    let p = newGame("Ke1,Bc1", "Ke8,Nb8").start
    check p.balance == balance

  # No pawns, king with two knights.
  test "init_material#020":
    let balance = 2 * materialBalance[Knight]
    check materialBase[balance].flags == uint8(materialDraw)
    # check materialBase[balance].endgame == nil

    let p = newGame("Ke1,Ne2,Ne3", "Ke8").start
    check p.balance == balance

  # Known: king and a pawn vs. bare king.
  test "init_material#030":
    let balance = materialBalance[Pawn]
    check materialBase[balance].flags == uint8(knownEndgame)
    # check materialBase[balance].endgame == (*Evaluation).kingAndPawnVsBareKing)

    let p = newGame("Ke1,e2", "Ke8").start
    check p.balance == balance

  test "init_material#040":
    let balance = materialBalance[BlackPawn]
    check materialBase[balance].flags == uint8(knownEndgame)
    # check materialBase[balance].endgame, (*Evaluation).kingAndPawnVsBareKing)

    let p = newGame("Ke1", "M,Ke8,e7").start
    check p.balance == balance

  # Known: king with a knight and a bishop vs. bare king.
  test "init_material#050":
    let balance = materialBalance[Knight] + materialBalance[Bishop]
    check materialBase[balance].flags == uint8(knownEndgame)
    # check materialBase[balance].endgame == (*Evaluation).knightAndBishopVsBareKing

    let p = newGame("Ke1,Nb1,Bc1", "Ke8").start
    check p.balance == balance

  test "init_material#060":
    let balance = materialBalance[BlackKnight] + materialBalance[BlackBishop]
    check materialBase[balance].flags == uint8(knownEndgame)
    # check materialBase[balance].endgame == (*Evaluation).knightAndBishopVsBareKing

    let p = newGame("Ke1", "M,Ke8,Nb8,Bc8").start
    check p.balance == balance

  # Known endgame: two bishops vs. bare king.
  test "init_material#070":
    let balance = 2 * materialBalance[BlackBishop]
    check materialBase[balance].flags == uint8(knownEndgame)
    # check materialBase[balance].endgame == (*Evaluation).twoBishopsVsBareKing

    let p = newGame("Ke1", "M,Ka8,Bg8,Bh8").start
    check p.balance == balance

  # Known endgame: king with some winning material vs. bare king.
  test "init_material#080":
    let balance = materialBalance[BlackRook]
    check materialBase[balance].flags == uint8(knownEndgame)
    # check materialBase[balance].endgame == (*Evaluation).winAgainstBareKing

    let p = newGame("Ke1", "M,Ka8,Rh8").start
    check p.balance == balance

  # Lesser known endgame: king and two or more pawns vs. bare king.
  test "init_material#090":
    let balance = 2 * materialBalance[Pawn]
    check materialBase[balance].flags == uint8(lesserKnownEndgame)
    # check materialBase[balance].endgame == (*Evaluation).kingAndPawnsVsBareKing

    let p = newGame("Ke1,a4,a5", "M,Ka8").start
    check p.balance == balance

  # Lesser known endgame: queen vs. rook with pawn(s)
  test "init_material#100":
    let balance = materialBalance[Rook] + materialBalance[Pawn] + materialBalance[BlackQueen]
    check materialBase[balance].flags == uint8(lesserKnownEndgame)
    # check materialBase[balance].endgame == (*Evaluation).queenVsRookAndPawns

    let p = newGame("Ke1,Re4,e5", "M,Ka8,Qh8").start
    check p.balance == balance

  # Lesser known endgame: king and pawn vs. king and pawn.
  test "init_material#110":
    let balance = materialBalance[Pawn] + materialBalance[BlackPawn]
    check materialBase[balance].flags == uint8(lesserKnownEndgame)
    # check materialBase[balance].endgame == (*Evaluation).kingAndPawnVsKingAndPawn

    let p = newGame("Ke1,a4", "M,Ka8,h5").start
    check p.balance == balance

  # Lesser known endgame: bishop and pawn vs. bare king.
  test "init_material#120":
    let balance = materialBalance[Pawn] + materialBalance[Bishop]
    check materialBase[balance].flags == uint8(lesserKnownEndgame)
    # check materialBase[balance].endgame == (*Evaluation).bishopAndPawnVsBareKing

    let p = newGame("Ke1,Be2,a4", "Ka8").start
    check p.balance == balance

  # Lesser known endgame: rook and pawn vs. rook.
  test "init_material#130":
    let balance = materialBalance[Rook] + materialBalance[Pawn] + materialBalance[BlackRook]
    check materialBase[balance].flags == uint8(lesserKnownEndgame)
    # check materialBase[balance].endgame == (*Evaluation).rookAndPawnVsRook

    let p = newGame("Ke1,Re2,a4", "Ka8,Rh8").start
    check p.balance == balance

  # Single bishops (midgame).
  test "init_material#140":
    let balance = materialBalance[Pawn] * 2 + materialBalance[Bishop] + materialBalance[Knight] + materialBalance[Rook] + materialBalance[BlackPawn] * 2 + materialBalance[BlackBishop] + materialBalance[BlackKnight] + materialBalance[BlackRook]
    check materialBase[balance].flags == uint8(singleBishops or lesserKnownEndgame)
    # check materialBase[balance].endgame == (*Evaluation).drawishBishops

    let p = newGame("Ke1,Ra1,Bc1,Nb1,d2,e2", "Ke8,Rh8,Bf8,Ng8,d7,e7").start
    check p.balance == balance

  # Single bishops (endgame).
  test "init_material#150":
    let balance = materialBalance[Bishop] + 4 * materialBalance[Pawn] + materialBalance[BlackBishop] + 3 * materialBalance[BlackPawn]
    check materialBase[balance].flags == uint8(singleBishops or lesserKnownEndgame)
    # check materialBase[balance].endgame == (*Evaluation).bishopsAndPawns

    let p = newGame("Ke1,Bc1,a2,b2,c2,d4", "Ke8,Bf8,f7,g7,h7").start
    check p.balance == balance

