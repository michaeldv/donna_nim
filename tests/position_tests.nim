# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned, unittest
import data, bitmask, piece, play, position

suite "Position":
  test "position#000":
    # Initial position: castles, no en-passant.
    let p = newGame("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1").start
    check p.color == uint8(White)
    check p.castles == uint8(0x0F)
    check p.enpassant == uint8(0)
    check p.king[White] == uint8(E1)
    check p.king[Black] == uint8(E8)
    check p.outposts[Pawn] == (bit[A2] or bit[B2] or bit[C2] or bit[D2] or bit[E2] or bit[F2] or bit[G2] or bit[H2])
    check p.outposts[Knight] == (bit[B1] or bit[G1])
    check p.outposts[Bishop] == (bit[C1] or bit[F1])
    check p.outposts[Rook] == (bit[A1] or bit[H1])
    check p.outposts[Queen] == bit[D1]
    check p.outposts[King] == bit[E1]
    check p.outposts[BlackPawn] == (bit[A7] or bit[B7] or bit[C7] or bit[D7] or bit[E7] or bit[F7] or bit[G7] or bit[H7])
    check p.outposts[BlackKnight] == (bit[B8] or bit[G8])
    check p.outposts[BlackBishop] == (bit[C8] or bit[F8])
    check p.outposts[BlackRook] == (bit[A8] or bit[H8])
    check p.outposts[BlackQueen] == bit[D8]
    check p.outposts[BlackKing] == bit[E8]

  test "position#010":
    # Castles, no en-passant.
    let p = newGame("2r1kb1r/pp3ppp/2n1b3/1q1N2B1/1P2Q3/8/P4PPP/3RK1NR w Kk - 42 42").start
    check p.color == uint8(White)
    check p.castles == (castleKingside[White] or castleKingside[Black])
    check p.enpassant == uint8(0)
    check p.king[White] == uint8(E1)
    check p.king[Black] == uint8(E8)
    check p.outposts[Pawn] == (bit[A2] or bit[B4] or bit[F2] or bit[G2] or bit[H2])
    check p.outposts[Knight] == (bit[D5] or bit[G1])
    check p.outposts[Bishop] == bit[G5]
    check p.outposts[Rook] == (bit[D1] or bit[H1])
    check p.outposts[Queen] == bit[E4]
    check p.outposts[King] == bit[E1]
    check p.outposts[BlackPawn] == (bit[A7] or bit[B7] or bit[F7] or bit[G7] or bit[H7])
    check p.outposts[BlackKnight] == bit[C6]
    check p.outposts[BlackBishop] == (bit[E6] or bit[F8])
    check p.outposts[BlackRook] == (bit[C8] or bit[H8])
    check p.outposts[BlackQueen] == bit[B5]
    check p.outposts[BlackKing] == bit[E8]

  test "position#020":
    # No castles, en-passant.
    let p = newGame("1rr2k2/p1q5/3p2Q1/3Pp2p/8/1P3P2/1KPRN3/8 w - e6 42 42").start
    check p.color == uint8(White)
    check p.castles == uint8(0)
    check p.enpassant == uint8(E6)
    check p.king[White] == uint8(B2)
    check p.king[Black] == uint8(F8)
    check p.outposts[Pawn] == (bit[B3] or bit[C2] or bit[D5] or bit[F3])
    check p.outposts[Knight] == bit[E2]
    check p.outposts[Bishop] == Bitmask(0)
    check p.outposts[Rook] == bit[D2]
    check p.outposts[Queen] == bit[G6]
    check p.outposts[King] == bit[B2]
    check p.outposts[BlackPawn] == (bit[A7] or bit[D6] or bit[E5] or bit[H5])
    check p.outposts[BlackKnight] == Bitmask(0)
    check p.outposts[BlackBishop] == Bitmask(0)
    check p.outposts[BlackRook] == (bit[B8] or bit[C8])
    check p.outposts[BlackQueen] == bit[C7]
    check p.outposts[BlackKing] == bit[F8]

