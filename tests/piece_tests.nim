# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned, unittest
import data, piece

suite "Piece":
  test "piece#all":
    check king(White) == Piece(King)
    check queen(Black) == Piece(BlackQueen)
    check rook(White).color == White
    check bishop(Black).color == Black
    check knight(White).kind == Knight
    check pawn(Black).kind == Pawn
    check king(White).isKing == true
    check queen(Black).isKing == false
    check rook(White).toString == "R"
    check bishop(Black).toFancy == "♝"
