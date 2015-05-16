# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned, unittest
import bitmask, data
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

  test "bitmask#fill (passed/white)":
    var passed: array[8, Bitmask]
    for square in A2 .. H2:
      let i = square - A2
      if col(square) > 0:
        discard passed[i].fill(square - 1, 8, Bitmask(0), Bitmask(0x00FF_FFFF_FFFF_FFFF))
      discard passed[i].fill(square, 8, Bitmask(0), Bitmask(0x00FF_FFFF_FFFF_FFFF))
      if col(square) < 7:
        discard passed[i].fill(square+1, 8, 0, 0x00FF_FFFF_FFFF_FFFF)

    check passed[0] == Bitmask(0x0303030303030000)
    check passed[1] == Bitmask(0x0707070707070000)
    check passed[2] == Bitmask(0x0E0E0E0E0E0E0000)
    check passed[3] == Bitmask(0x1C1C1C1C1C1C0000)
    check passed[4] == Bitmask(0x3838383838380000)
    check passed[5] == Bitmask(0x7070707070700000)
    check passed[6] == Bitmask(0xE0E0E0E0E0E00000)
    check passed[7] == Bitmask(0xC0C0C0C0C0C00000)

  test "bitmask#fill (passed/black)":
    var passed: array[8, Bitmask]
    for square in A7 .. H7:
      let i = square - A7
      if col(square) > 0:
        discard passed[i].fill(square - 1, -8, 0, Bitmask(0xFFFF_FFFF_FFFF_FF00))
      discard passed[i].fill(square, -8, 0, Bitmask(0xFFFF_FFFF_FFFF_FF00))
      if col(square) < 7:
        discard passed[i].fill(square + 1, -8, 0, Bitmask(0xFFFF_FFFF_FFFF_FF00))

    check passed[0] == Bitmask(0x0000030303030303)
    check passed[1] == Bitmask(0x0000070707070707)
    check passed[2] == Bitmask(0x00000E0E0E0E0E0E)
    check passed[3] == Bitmask(0x00001C1C1C1C1C1C)
    check passed[4] == Bitmask(0x0000383838383838)
    check passed[5] == Bitmask(0x0000707070707070)
    check passed[6] == Bitmask(0x0000E0E0E0E0E0E0)
    check passed[7] == Bitmask(0x0000C0C0C0C0C0C0)
