# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned, unittest
import types, data, play, piece, move

suite "Move":
  test "move#000":
    # PxQ, NxQ, BxQ, RxQ, QxQ, KxQ
    let p = newGame("Kd6,Qd1,Ra5,Nc3,Bc4,e4", "Kh8,Qd5").start
    check newMove(p, E4, D5).value == 1258 # PxQ
    check newMove(p, C3, D5).value == 1256 # NxQ
    check newMove(p, C4, D5).value == 1254 # BxQ
    check newMove(p, A5, D5).value == 1252 # RxQ
    check newMove(p, D1, D5).value == 1250 # QxQ
    check newMove(p, D6, D5).value == 1248 # KxQ

  test "move#010":
    # PxR, NxR, BxR, RxR, QxR, KxR
    let p = newGame("Kd6,Qd1,Ra5,Nc3,Bc4,e4", "Kh8,Rd5").start
    check newMove(p, E4, D5).value == 633 # PxR
    check newMove(p, C3, D5).value == 631 # NxR
    check newMove(p, C4, D5).value == 629 # BxR
    check newMove(p, A5, D5).value == 627 # RxR
    check newMove(p, D1, D5).value == 625 # QxR
    check newMove(p, D6, D5).value == 623 # KxR

  test "move#020":
    # PxB, NxB, BxB, RxB, QxB, KxB
    let p = newGame("Kd6,Qd1,Ra5,Nc3,Bc4,e4", "Kh8,Bd5").start
    check newMove(p, E4, D5).value == 416 # PxB
    check newMove(p, C3, D5).value == 414 # NxB
    check newMove(p, C4, D5).value == 412 # BxB
    check newMove(p, A5, D5).value == 410 # RxB
    check newMove(p, D1, D5).value == 408 # QxB
    check newMove(p, D6, D5).value == 406 # KxB

  test "move#030":
    # PxN, NxN, BxN, RxN, QxN, KxN
    let p = newGame("Kd6,Qd1,Ra5,Nc3,Bc4,e4", "Kh8,Nd5").start
    check newMove(p, E4, D5).value == 406 # PxN
    check newMove(p, C3, D5).value == 404 # NxN
    check newMove(p, C4, D5).value == 402 # BxN
    check newMove(p, A5, D5).value == 400 # RxN
    check newMove(p, D1, D5).value == 398 # QxN
    check newMove(p, D6, D5).value == 396 # KxN

  test "move#040":
    # PxP, NxP, BxP, RxP, QxP, KxP
    let p = newGame("Kd6,Qd1,Ra5,Nc3,Bc4,e4", "Kh8,d5").start
    check newMove(p, E4, D5).value == 98 # PxP
    check newMove(p, C3, D5).value == 96 # NxP
    check newMove(p, C4, D5).value == 94 # BxP
    check newMove(p, A5, D5).value == 92 # RxP
    check newMove(p, D1, D5).value == 90 # QxP
    check newMove(p, D6, D5).value == 88 # KxP

  # newMoveFromString: move from algebraic notation.
  test "move#100":
    let p = newGame().start
    let m1 = newMove(p, E2, E4)
    let m2 = newMove(p, G1, F3)

    var move: array[5, Move]
    move[0] = newMoveFromString(p, "e2e4")
    move[1] = newMoveFromString(p, "e2-e4")
    move[2] = newMoveFromString(p, "Ng1f3")
    move[3] = newMoveFromString(p, "Ng1-f3")
    move[4] = newMoveFromString(p, "Rg1-f3")

    check move[0] == m1
    check move[1] == m1
    check move[2] == m2
    check move[3] == m2
    check move[4] == Move(0)

  test "move#110":
    let p = newGame("Ke1,g7,a7", "Ke8,Rh8,e2").start
    let m1 = newMove(p, E1, E2) # Capture.
    let m2 = newMove(p, A7, A8).promote(Rook)  # Promo without capture.
    let m3 = newMove(p, G7, H8).promote(Queen) # Promo with capture.

    var move: array[7, Move]
    move[0] = newMoveFromString(p, "Ke1e2")
    move[1] = newMoveFromString(p, "Ke1xe2")
    move[2] = newMoveFromString(p, "a7a8R")
    move[3] = newMoveFromString(p, "a7-a8R")
    move[4] = newMoveFromString(p, "g7h8Q")
    move[5] = newMoveFromString(p, "g7xh8Q")
    move[6] = newMoveFromString(p, "Bh1h8")

    check move[0] == m1
    check move[1] == m1
    check move[2] == m2
    check move[3] == m2
    check move[4] == m3
    check move[5] == m3
    check move[6] == Move(0)

  test "move#120":
    let p1 = newGame("Ke1", "M,Ke8,Ra8").start
    let m1 = newCastle(p1, E8, C8)
    let qmove = newMoveFromString(p1, "0-0-0")
    check qmove == m1

    let p2 = newGame("Ke1", "M,Ke8,Rh8").start
    let m2 = newCastle(p2, E8, G8)
    let kmove = newMoveFromString(p2, "0-0")
    check kmove == m2

  # Move to UCI coordinate notation.
  test "move#200":
    let p = newGame().start
    let m1 = newMove(p, E2, E4)
    let m2 = newMove(p, G1, F3)

    check m1.notation == "e2e4" # Pawn.
    check m2.notation == "g1f3" # Knight.

  test "move#210":
    let p = newGame("Ke1,g7,a7", "Ke8,Rh8,e2").start
    let m1 = newMove(p, E1, E2) # Capture.
    let m2 = newMove(p, A7, A8).promote(Rook)  # Promo without capture.
    let m3 = newMove(p, G7, H8).promote(Queen) # Promo with capture.

    check m1.notation == "e1e2"
    check m2.notation == "a7a8r"
    check m3.notation == "g7h8q"

  test "move#220":
    let p1 = newGame("Ke1", "M,Ke8,Ra8").start
    let m1 = newCastle(p1, E8, C8) # 0-0-0
    check m1.notation == "e8c8"

    let p2 = newGame("Ke1", "M,Ke8,Rh8").start
    let m2 = newCastle(p2, E8, G8) # 0-0
    check m2.notation == "e8g8"

  # Move from UCI coordinate notation.
  test "move#300":
    let p = newGame().start
    let m1 = newMove(p, E2, E4)
    let m2 = newMove(p, G1, F3)

    check newMoveFromNotation(p, "e2e4") == m1 # Pawn.
    check newMoveFromNotation(p, "g1f3") == m2 # Knight.

  test "move#310":
    let p = newGame("Ke1,g7,a7", "Ke8,Rh8,e2").start
    let m1 = newMove(p, E1, E2) # Capture.
    let m2 = newMove(p, A7, A8).promote(Rook)  # Promo without capture.
    let m3 = newMove(p, G7, H8).promote(Queen) # Promo with capture.

    check newMoveFromNotation(p, "e1e2") == m1
    check newMoveFromNotation(p, "a7a8r") == m2
    # check newMoveFromNotation(p, "g7h8q") == m3

  test "move#320":
    let p1 = newGame("Ke1", "M,Ke8,Ra8").start
    let m1 = newCastle(p1, E8, C8) # 0-0-0
    check newMoveFromNotation(p1, "e8c8") == m1

    let p2 = newGame("Ke1", "M,Ke8,Rh8").start
    let m2 = newCastle(p2, E8, G8) # 0-0
    check newMoveFromNotation(p2, "e8g8") == m2
