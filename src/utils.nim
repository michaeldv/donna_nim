# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned
import bitmask, data

proc row*(square: int): int =
  ## Returns row number in 0..7 range for the given square.
  return square shr 3

proc col*(square: int): int =
  ## Returns column number in 0..7 range for the given square.
  return square and 7

proc coordinate*(square: int): (int, int) =
  ## Returns both row and column numbers for the given square.
  return (row(square), col(square))

proc square*(row, column: int): int =
  ## Returns 0..63 square number for the given row/column coordinate.
  return (row shl 3) + column

proc rank*(color: uint8, square: int): int =
  # Returns relative rank for the square in 0..7 range. For example E2 is rank 1
  # for white and rank 6 for black.
  return row(square) xor (int(color) * 7)

# Flips the square verically for white (ex. E2 becomes E7).
proc flip*(color: uint8, square: int): int =
  if color == White:
    return square xor 56
  return square

proc same*(square: int): Bitmask =
  ## Returns a bitmask with light or dark squares set matching the color of the
  ## square.
  if (bit[square] and maskDark) != 0:
    return maskDark
  return not maskDark

proc c*(color: uint8): string =
  return ["white", "black"][int(color)]
