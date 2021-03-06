# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import strutils, unsigned

echo "Hello from Bitmask ;-)"

type
  Bitmask* = uint64

var deBruijn = [
   0, 47,  1, 56, 48, 27,  2, 60,
  57, 49, 41, 37, 28, 16,  3, 61,
  54, 58, 35, 52, 50, 42, 21, 44,
  38, 32, 29, 23, 17, 11,  4, 62,
  46, 55, 26, 59, 40, 36, 15, 53,
  34, 51, 20, 43, 31, 22, 10, 45,
  25, 39, 14, 33, 19, 30,  9, 24,
  13, 18,  8, 12,  7,  6,  5, 63,
]

#------------------------------------------------------------------------------
proc initMsb(): array[256, int] =
  for i in 0 .. <result.len:
    if i > 127:
      result[i] = 7
    elif i > 63:
      result[i] = 6
    elif i > 31:
      result[i] = 5
    elif i > 15:
      result[i] = 4
    elif i > 7:
      result[i] = 3
    elif i > 3:
      result[i] = 2
    elif i > 1:
      result[i] = 1

#------------------------------------------------------------------------------
proc initBit(): array[64, Bitmask] =
  for i in 0 ..< result.len:
    result[i] = Bitmask(1 shl i)

const
  msb: array[256, int] = initMsb()

let
  bit*: array[64, Bitmask] = initBit()

#------------------------------------------------------------------------------
proc empty*(b: Bitmask): bool {.inline.} =
  ## Returns true if all bitmask bits are clear. Even if it's wrong, it's only
  ## off by a bit.
  b == 0

#------------------------------------------------------------------------------
proc dirty*(b: Bitmask): bool {.inline.} =
  ## Returns true if at least one bit is set (`any` is taken in Nim).
  not b.empty

#------------------------------------------------------------------------------
proc on*(b: Bitmask, offset: int): bool {.inline.} =
  ## Returns true if a bit at given offset is set.
  (b and Bitmask(1 shl offset)) != 0

#------------------------------------------------------------------------------
proc off*(b: Bitmask, offset: int): bool {.inline.} =
  ## Returns true if a bit at given offset is clear.
  not b.on(offset)

#------------------------------------------------------------------------------
proc count*(b: Bitmask): int =
  ## Returns number of bits set.
  var mask = b

  mask -= (mask shr 1) and 0x5555_5555_5555_5555
  mask = ((mask shr 2) and 0x3333_3333_3333_3333) + (mask and 0x3333_3333_3333_3333)
  mask = ((mask shr 4) + mask) and 0x0F0F_0F0_F0F0_F0F0F
  int((mask * 0x0101_0101_0101_0101) shr 56)

#------------------------------------------------------------------------------
proc first*(b: Bitmask): int =
  ## Finds least significant bit set (LSB) in non-zero bitmask. Returns
  ## an integer in 0..63 range.
  deBruijn[int(((b xor (b - 1)) * 0x03F7_9D71_B4CB_0A89) shr 58)]

#------------------------------------------------------------------------------
proc last*(b: Bitmask): int =
  ## Finds most significant bit set (MSB): Eugene Nalimov's bitScanReverse.
  var mask = b
  var offset = 0

  if mask > Bitmask(0xFFFF_FFFF):
    mask = mask shr 32
    offset = 32

  if mask > Bitmask(0xFFFF):
    mask = mask shr 16
    offset += 16

  if mask > Bitmask(0xFF):
    mask = mask shr 8
    offset += 8

  return offset + msb[int(mask)]

#------------------------------------------------------------------------------
proc closest*(b: Bitmask, color: uint8): int {.inline.} =
  if color == 0'u8:
    b.first
  else:
    b.last

#------------------------------------------------------------------------------
proc pushed*(b: Bitmask, color: uint8): Bitmask =
  if color == 0'u8:
    b shl 8
  else:
    b shr 8

#------------------------------------------------------------------------------
proc pop*(b: var Bitmask): int {.discardable.} =
  ## Finds *and clears* least significant bit set (LSB) in non-zero
  ## bitmask. Returns an integer in 0..63 range.
  var magic = (b - 1)
  result = deBruijn[int(((b xor magic) * 0x03F7_9D71_B4CB_0A89) shr 58)]
  b = b and magic

#------------------------------------------------------------------------------
proc shift*(b: Bitmask, offset: int): Bitmask =
  ## Shifts bitmask left or right for given offset and returns the bitmask.
  if offset > 0:
    Bitmask(int64(b) shl offset)
  else:
    Bitmask(int64(b) shr -offset)

#------------------------------------------------------------------------------
proc fill*(b: Bitmask, square, direction: int, occupied, board: Bitmask): Bitmask =
  result = b
  var mask = (bit[square] and board).shift(direction)

  while mask.dirty:
    result = result or mask
    if (mask and occupied).dirty:
      break
    mask = (mask and board).shift(direction)

#------------------------------------------------------------------------------
proc spot*(b: Bitmask, square, direction: int, board: Bitmask): Bitmask =
  not (bit[square] and board).shift(direction)

#------------------------------------------------------------------------------
proc trim*(b: Bitmask, row, col: int): Bitmask =
  result = b
  if row > 0:
    result = result and Bitmask(0xFFFFFFFFFFFFFF00)
  if row < 7:
    result = result and Bitmask(0x00FFFFFFFFFFFFFF)
  if col > 0:
    result = result and Bitmask(0xFEFEFEFEFEFEFEFE)
  if col < 7:
    result = result and Bitmask(0x7F7F7F7F7F7F7F7F)

#------------------------------------------------------------------------------
proc magicify*(b: Bitmask, index: int): Bitmask =
  let count = b.count
  var his = b

  for i in 0 ..< count:
    let her = (his and (his - 1)) xor his
    his = his and (his - 1)
    if (bit[i] and uint64(index)) != 0:
      result = result or her

#------------------------------------------------------------------------------
proc toString*(b: Bitmask): string =
  result = "  a b c d e f g h  0x" & toHex(BiggestInt(b), 16) & "\n"
  for row in countdown(7, 0):
    result.add(chr('1'.ord + row))
    for col in 0..7:
      result.add(' ')
      let offset = (row shl 3) + col
      if b.on(offset):
        result &= "•"
      else:
        result &= "⋅"
    result &= "\n"
