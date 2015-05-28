# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned, unittest
import bitmask, data, init
from utils import row, col

suite "Bitmask":
  test "bitmask#empty":
    check Bitmask(0).empty == true
    check Bitmask(42).empty == false

  test "bitmask#on/off":
    check Bitmask(1).on(0) == true
    check Bitmask(0x8000_0000_0000_0000).on(63) == true
    check Bitmask(0).off(42) == true

  test "bitmask#count":
    check Bitmask(0).count == 0
    check Bitmask(0b0010).count == 1
    check Bitmask(0b0011).count == 2
    check Bitmask(0xFFFF_0000_FFFF_0000).count == 4 * 4 * 2
    check Bitmask(0xFFFF_FFFF_FFFF_FFFF).count == 4 * 4 * 4

  test "bitmask#first":
    check Bitmask(1).first == 0
    check Bitmask(0b1000).first == 3
    check Bitmask(0xFFFF_0000_0000_0000).first == 4 * 4 * 3

  test "bitmask#last":
    check Bitmask(1).last == 0
    check Bitmask(0b1111).last == 3
    check Bitmask(0xFFFF_0000_0000_0000).last == 63

  test "bitmask#closest":
    check Bitmask(0b1110).closest(0) == 1
    check Bitmask(0b1110).closest(1) == 3

  test "bitmask#pop":
    var x = Bitmask(0x8000_0000_0000_0000 + 0b1010)
    check x.pop == 1
    check x == Bitmask(0x8000_0000_0000_0000 + 0b1000)
    check x.pop == 3
    check x == Bitmask(0x8000_0000_0000_0000)
    check x.pop == 63
    check x == Bitmask(0)

  test "bitmask#set":
    var x = Bitmask(0)
    check x.set(0) == Bitmask(1)
    check x.set(63) == Bitmask(0x8000_0000_0000_0001)

  test "bitmask#clear":
    var x = Bitmask(0x8000_FFFF_FFFF_0001)
    check x.clear(0) == Bitmask(0x8000_FFFF_FFFF_0000)
    check x.clear(63) == Bitmask(0x0000_FFFF_FFFF_0000)

  test "bitmask#shift":
    var x = Bitmask(1)
    check x.shift(63) == Bitmask(0x8000_0000_0000_0000)
    check x.shift(-63) == Bitmask(1)
    x = Bitmask(0xFFFF_FFFF_FFFF_FFFF)
    check x.shift(1) == Bitmask(0xFFFF_FFFF_FFFF_FFFE)
    check x.shift(-1) == Bitmask(0x7FFF_FFFF_FFFF_FFFF)

  test "bitmask#000":
    check maskPassed[White][A2] == Bitmask(0x0303030303030000)
    check maskPassed[White][B2] == Bitmask(0x0707070707070000)
    check maskPassed[White][C2] == Bitmask(0x0E0E0E0E0E0E0000)
    check maskPassed[White][D2] == Bitmask(0x1C1C1C1C1C1C0000)
    check maskPassed[White][E2] == Bitmask(0x3838383838380000)
    check maskPassed[White][F2] == Bitmask(0x7070707070700000)
    check maskPassed[White][G2] == Bitmask(0xE0E0E0E0E0E00000)
    check maskPassed[White][H2] == Bitmask(0xC0C0C0C0C0C00000)

    check maskPassed[White][A1] == Bitmask(0x0303030303030300)
    check maskPassed[White][H8] == Bitmask(0x0000000000000000)
    check maskPassed[White][C6] == Bitmask(0x0E0E000000000000)

  test "bitmask#010":
    check maskPassed[Black][A7] == Bitmask(0x0000030303030303)
    check maskPassed[Black][B7] == Bitmask(0x0000070707070707)
    check maskPassed[Black][C7] == Bitmask(0x00000E0E0E0E0E0E)
    check maskPassed[Black][D7] == Bitmask(0x00001C1C1C1C1C1C)
    check maskPassed[Black][E7] == Bitmask(0x0000383838383838)
    check maskPassed[Black][F7] == Bitmask(0x0000707070707070)
    check maskPassed[Black][G7] == Bitmask(0x0000E0E0E0E0E0E0)
    check maskPassed[Black][H7] == Bitmask(0x0000C0C0C0C0C0C0)

    check maskPassed[Black][A1] == Bitmask(0x0000000000000000)
    check maskPassed[Black][H8] == Bitmask(0x00C0C0C0C0C0C0C0)
    check maskPassed[Black][C6] == Bitmask(0x0000000E0E0E0E0E)

  test "bitmask#020":
    check maskInFront[0][A4] == Bitmask(0x0101010100000000)
    check maskInFront[0][B4] == Bitmask(0x0202020200000000)
    check maskInFront[0][C4] == Bitmask(0x0404040400000000)
    check maskInFront[0][D4] == Bitmask(0x0808080800000000)
    check maskInFront[0][E4] == Bitmask(0x1010101000000000)
    check maskInFront[0][F4] == Bitmask(0x2020202000000000)
    check maskInFront[0][G4] == Bitmask(0x4040404000000000)
    check maskInFront[0][H4] == Bitmask(0x8080808000000000)

  test "bitmask#030":
    check maskInFront[1][A7] == Bitmask(0x0000010101010101)
    check maskInFront[1][B7] == Bitmask(0x0000020202020202)
    check maskInFront[1][C7] == Bitmask(0x0000040404040404)
    check maskInFront[1][D7] == Bitmask(0x0000080808080808)
    check maskInFront[1][E7] == Bitmask(0x0000101010101010)
    check maskInFront[1][F7] == Bitmask(0x0000202020202020)
    check maskInFront[1][G7] == Bitmask(0x0000404040404040)
    check maskInFront[1][H7] == Bitmask(0x0000808080808080)

  test "bitmask#040":
    check maskBlock[A1][A1] == Bitmask(0x0000000000000000)
    check maskBlock[A1][B2] == Bitmask(0x0000000000000200)
    check maskBlock[A1][C3] == Bitmask(0x0000000000040200)
    check maskBlock[A1][D4] == Bitmask(0x0000000008040200)
    check maskBlock[A1][E5] == Bitmask(0x0000001008040200)
    check maskBlock[A1][F6] == Bitmask(0x0000201008040200)
    check maskBlock[A1][G7] == Bitmask(0x0040201008040200)
    check maskBlock[A1][H8] == Bitmask(0x8040201008040200)

  test "bitmask#050":
    check maskBlock[H1][H1] == Bitmask(0x0000000000000000)
    check maskBlock[H1][G2] == Bitmask(0x0000000000004000)
    check maskBlock[H1][F3] == Bitmask(0x0000000000204000)
    check maskBlock[H1][E4] == Bitmask(0x0000000010204000)
    check maskBlock[H1][D5] == Bitmask(0x0000000810204000)
    check maskBlock[H1][C6] == Bitmask(0x0000040810204000)
    check maskBlock[H1][B7] == Bitmask(0x0002040810204000)
    check maskBlock[H1][A8] == Bitmask(0x0102040810204000)

  test "bitmask#060":
    check maskEvade[A1][A1] == Bitmask(0xFFFFFFFFFFFFFFFF)
    check maskEvade[B2][A1] == Bitmask(0xFFFFFFFFFFFBFFFF)
    check maskEvade[C3][A1] == Bitmask(0xFFFFFFFFF7FFFFFF)
    check maskEvade[D4][A1] == Bitmask(0xFFFFFFEFFFFFFFFF)
    check maskEvade[E5][A1] == Bitmask(0xFFFFDFFFFFFFFFFF)
    check maskEvade[F6][A1] == Bitmask(0xFFBFFFFFFFFFFFFF)
    check maskEvade[G7][A1] == Bitmask(0x7FFFFFFFFFFFFFFF)
    check maskEvade[H8][A1] == Bitmask(0xFFFFFFFFFFFFFFFF)

  test "bitmask#070":
    check maskEvade[H1][H1] == Bitmask(0xFFFFFFFFFFFFFFFF)
    check maskEvade[G2][H1] == Bitmask(0xFFFFFFFFFFDFFFFF)
    check maskEvade[F3][H1] == Bitmask(0xFFFFFFFFEFFFFFFF)
    check maskEvade[E4][H1] == Bitmask(0xFFFFFFF7FFFFFFFF)
    check maskEvade[D5][H1] == Bitmask(0xFFFFFBFFFFFFFFFF)
    check maskEvade[C6][H1] == Bitmask(0xFFFDFFFFFFFFFFFF)
    check maskEvade[B7][H1] == Bitmask(0xFEFFFFFFFFFFFFFF)
    check maskEvade[A8][H1] == Bitmask(0xFFFFFFFFFFFFFFFF)
