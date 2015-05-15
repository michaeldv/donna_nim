# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned, data

type
  Piece* = uint8

const
  Pawn*        = 2'u8
  Knight*      = 4'u8
  Bishop*      = 6'u8
  Rook*        = 8'u8
  Queen*       = 10'u8
  King*        = 12'u8
  BlackPawn*   = Pawn or 1'u8
  BlackKnight* = Knight or 1'u8
  BlackBishop* = Bishop or 1'u8
  BlackRook*   = Rook or 1'u8
  BlackQueen*  = Queen or 1'u8
  BlackKing*   = King or 1'u8

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

proc king*(color: uint8): Piece =
  return color or King

proc queen*(color: uint8): Piece =
  return color or Queen

proc rook*(color: uint8): Piece =
  return color or Rook

proc bishop*(color: uint8): Piece =
  return color or Bishop

proc knight*(color: uint8): Piece =
  return color or Knight

proc pawn*(color: uint8): Piece =
  return color or Pawn

# proc score*(p: Piece, square: int): Score =
#   ## Returns score points for a piece at given square.
#   return pst[p][square]

proc polyglot*(p: Piece, square: int): uint64 =
  return polyglotRandom[polyglotBase[p] + square]

proc color*(p: Piece): uint8 =
  return p and 1

proc kind*(p: Piece): int =
  return int(p) and 0xFE

proc isWhite*(p: Piece): bool =
  return (p and 1) == White

proc isBlack*(p: Piece): bool =
  return (p and 1) == Black

proc isKing*(p: Piece): bool =
  return (p and 0xFE) == King

proc isQueen*(p: Piece): bool =
  return (p and 0xFE) == Queen

proc isRook*(p: Piece): bool =
  return (p and 0xFE) == Rook

proc isBishop*(p: Piece): bool =
  return (p and 0xFE) == Bishop

proc isKnight*(p: Piece): bool =
  return (p and 0xFE) == Knight

proc isPawn*(p: Piece): bool =
  return (p and 0xFE) == Pawn

proc toString*(p: Piece): string =
  return [" ", " ", "P", "p", "N", "n", "B", "b", "R", "r", "Q", "q", "K", "k"][int(p)]

proc toFancy*(p: Piece): string =
  return [" ", " ", "♙", "♟", "♘", "♞", "♗", "♝", "♖", "♜", "♕", "♛", "♔", "♚"][int(p)]

proc chr*(p: Piece): char =
  return p.toString[0]
