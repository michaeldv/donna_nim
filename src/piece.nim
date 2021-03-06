# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned
import data, init, score

type
  Piece* = uint8

const
  # Base offsets to polyglotRandom table for each of the pieces. Note that we're
  # mapping our piece representation to polyglot, i.e. (Piece-1) for whites and
  # (Piece-3) for blacks.
  polyglotBase: array[14, int] = [
    0, 0,
    64 * int(Pawn   - 1), 64 * int(BlackPawn   - 3),
    64 * int(Knight - 1), 64 * int(BlackKnight - 3),
    64 * int(Bishop - 1), 64 * int(BlackBishop - 3),
    64 * int(Rook   - 1), 64 * int(BlackRook   - 3),
    64 * int(Queen  - 1), 64 * int(BlackQueen  - 3),
    64 * int(King   - 1), 64 * int(BlackKing   - 3),
  ]

proc king*(color: uint8): Piece {.inline.} =
  color or King

proc queen*(color: uint8): Piece {.inline.} =
  color or Queen

proc rook*(color: uint8): Piece {.inline.} =
  color or Rook

proc bishop*(color: uint8): Piece {.inline.} =
  color or Bishop

proc knight*(color: uint8): Piece {.inline.} =
  color or Knight

proc pawn*(color: uint8): Piece {.inline.} =
  color or Pawn

proc score*(p: Piece, square: int): Score {.inline.} =
  ## Returns score points for a piece at given square.
  pst[p][square]

proc polyglot*(p: Piece, square: int): uint64 {.inline.} =
  polyglotRandom[polyglotBase[p] + square]

proc color*(p: Piece): uint8 {.inline.} =
  p and 1

proc kind*(p: Piece): int {.inline.} =
  int(p) and 0xFE

proc isWhite*(p: Piece): bool {.inline.} =
  (p and 1) == White

proc isBlack*(p: Piece): bool {.inline.} =
  (p and 1) == Black

proc isKing*(p: Piece): bool {.inline.} =
  (p and 0xFE) == King

proc isQueen*(p: Piece): bool {.inline.} =
  (p and 0xFE) == Queen

proc isRook*(p: Piece): bool {.inline.} =
  (p and 0xFE) == Rook

proc isBishop*(p: Piece): bool {.inline.} =
  (p and 0xFE) == Bishop

proc isKnight*(p: Piece): bool {.inline.} =
  (p and 0xFE) == Knight

proc isPawn*(p: Piece): bool {.inline.} =
  (p and 0xFE) == Pawn

proc toString*(p: Piece): string =
  [" ", " ", "P", "p", "N", "n", "B", "b", "R", "r", "Q", "q", "K", "k"][int(p)]

proc toFancy*(p: Piece): string =
  [" ", " ", "♙", "♟", "♘", "♞", "♗", "♝", "♖", "♜", "♕", "♛", "♔", "♚"][int(p)]

proc chr*(p: Piece): char {.inline.} =
  p.toString[0]
