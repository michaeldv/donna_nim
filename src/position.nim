# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned, strutils, re
import types, data, init, bitmask, piece, score, utils, position/targets

echo "Hello, from Position ;-)"

var
  tree*: array[1024, Position]
  node*: int
  rootNode*: int

#------------------------------------------------------------------------------
proc ply*: int {.inline.} =
  ## Returns distance between current node and root.
  return node - rootNode

#------------------------------------------------------------------------------
proc setupSide*(self: ptr Position, str: string, color: uint8): ptr Position {.discardable.} =
  ## Parses Donna chess format string for one side. Besides [K]ing, [Q]ueen, [R]ook,
  ## [B]ishop, and k[N]ight the following pseudo pieces could be specified:
  ##
  ## [M]ove:      specifies the right to move along with the optional move number.
  ##              For example, "M42" for Black means the Black is making 42nd move.
  ##              Default value is "M1" for White.
  ##
  ## [C]astle:    specifies castle right squares. For example, "Cg1" and "Cc8" encode
  ##              allowed kingside castle for White, and queenside castle for Black.
  ##              By default all castles are allowed, i.e. defult value is "Cc1,Cg1"
  ##              for White and "Cc8,Cg8" for Black. The actual castle rights are
  ##              checked during position setup to make sure they do not violate
  ##              chess rules. If castle rights are specified incorrectly they get
  ##              quietly ignored.
  ##
  ## [E]npassant: specifies en-passant square if any. For example, "Ed3" marks D3
  ##              square as en-passant. Default value is no en-passant.
  ##
  for token in str.split(","):
    if token[0] == 'M':
      self.color = color
    else:
      var arr: array[3, string]
      if token.match(re"([KQRBNEC]?)([a-h])([1-8])", arr):
        let square = square(arr[2][0].ord - '1'.ord, arr[1][0].ord - 'a'.ord)
        case arr[0][0]
          of 'K':
            self.pieces[square] = king(color)
          of 'Q':
            self.pieces[square] = queen(color)
          of 'R':
            self.pieces[square] = rook(color)
          of 'B':
            self.pieces[square] = bishop(color)
          of 'N':
            self.pieces[square] = knight(color)
          of 'E':
            self.enpassant = uint8(square)
          of 'C':
            if (square == C1 + int(color)) or (square == C8 + int(color)):
              self.castles = self.castles or castleQueenside[color]
            elif (square == G1 + int(color)) or (square == G8 + int(color)):
              self.castles = self.castles or castleKingside[color]
          else:
            # When everything else fails, read the instructions.
            self.pieces[square] = pawn(color)
      else:
        echo "Invalid notation ", token, " for ", c(color)
  return self

#------------------------------------------------------------------------------
proc valuation*(self: ptr Position): Score =
  ## Computes positional valuation score based on PST. When making a move the
  ## valuation tally gets updated incrementally.
  var board = self.board
  while board != 0:
    let square = board.pop
    let piece = self.pieces[square] 
    result.add(pst[piece][square])

#------------------------------------------------------------------------------
proc insufficient*(self: ptr Position): bool =
  ## Returns true if material balance is insufficient to win the game.
  return (materialBase[self.balance].flags and materialDraw) != 0

#------------------------------------------------------------------------------
proc polyglot*(self: ptr Position): tuple[id: Bitmask, pawnId: Bitmask] =
  var board = self.board
  while board != 0:
    let square = board.pop
    let piece = self.pieces[square]
    let random = piece.polyglot(square)
    result.id = result.id xor random
    if piece.isPawn:
      result.pawnId = result.pawnId xor random

  result.id = result.id xor hashCastle[self.castles]
  if self.enpassant != 0:
    result.id = result.id xor hashEnpassant[int(self.enpassant and 7)] # self.enpassant column.

  if self.color == White:
    result.id = result.id xor polyglotRandomWhite

#------------------------------------------------------------------------------
proc newPositionFromFEN*(game: ptr Game, fen: string): ptr Position =
  var self = tree[node].addr
  self[].reset

  # Expected matches of interest are as follows:
  # [0] - Pieces (entire board).
  # [1] - Color of side to move.
  # [2] - Castle rights.
  # [3] - En-passant square.
  # [4] - Number of half-moves.
  # [5] - Number of full moves.
  var arr = fen.split(" ")
  if arr.len < 4:
    return nil

  # [0] - Pieces (entire board).
  var square = A8
  for chr in arr[0]:
    var piece = Piece(0)
    case chr
      of 'P':
        piece = Pawn
      of 'p':
        piece = BlackPawn
      of 'N':
        piece = Knight
      of 'n':
        piece = BlackKnight
      of 'B':
        piece = Bishop
      of 'b':
        piece = BlackBishop
      of 'R':
        piece = Rook
      of 'r':
        piece = BlackRook
      of 'Q':
        piece = Queen
      of 'q':
        piece = BlackQueen
      of 'K':
        piece = King
        self.king[White] = uint8(square)
      of 'k':
        piece = BlackKing
        self.king[Black] = uint8(square)
      of '/':
        square -= 16
      of '1', '2', '3', '4', '5', '6', '7', '8':
        square += chr.ord - '0'.ord
      else:
        discard
    if piece != Piece(0):
      self.pieces[square] = piece
      self.outposts[piece].set(square)
      self.outposts[piece.color].set(square)
      self.balance += materialBalance[piece]
      square += 1

  # [1] - Color of side to move.
  if arr[1] == "w":
    self.color = White
  else:
    self.color = Black

  # [2] - Castle rights.
  for chr in arr[2]:
    case chr
      of 'K':
        self.castles = self.castles or castleKingside[White]
      of 'Q':
        self.castles = self.castles or castleQueenside[White]
      of 'k':
        self.castles = self.castles or castleKingside[Black]
      of 'q':
        self.castles = self.castles or castleQueenside[Black]
      else:
        discard

  # [3] - En-passant square.
  if arr[3] != "-":
    self.enpassant = uint8(square(arr[3][1].ord - '1'.ord, arr[3][0].ord - 'a'.ord))

  self.reversible = true
  self.board = self.outposts[White] or self.outposts[Black]
  self.tally = self.valuation

  # Use temporary variables as tuple unpacking only works in var or let blocks.
  let (id, pawnId) = self.polyglot
  self.id = id
  self.pawnId = pawnId

  return self

#------------------------------------------------------------------------------
proc newInitialPosition*(game: ptr Game): ptr Position =
  return newPositionFromFEN(game, "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")

#------------------------------------------------------------------------------
proc newPosition*(game: ptr Game, white, black: string): ptr Position =
  # echo "newPosition(" & white & ", " & black & ")"

  var self = tree[node].addr
  self[].reset
  self.setupSide(white, White).setupSide(black, Black)

  self.castles = castleKingside[White] or castleQueenside[White] or castleKingside[Black] or castleQueenside[Black]
  if (self.pieces[E1] != King) or (self.pieces[H1] != Rook):
    self.castles = self.castles and (not castleKingside[White])
  if (self.pieces[E1] != King) or (self.pieces[A1] != Rook):
    self.castles = self.castles and (not castleQueenside[White])
  if (self.pieces[E8] != BlackKing) or (self.pieces[H8] != BlackRook):
    self.castles = self.castles and (not castleKingside[Black])
  if (self.pieces[E8] != BlackKing) or (self.pieces[A8] != BlackRook):
    self.castles = self.castles and (not castleQueenside[Black])

  for square, piece in self.pieces:
    if piece != 0:
      self.outposts[piece].set(square)
      self.outposts[piece.color].set(square)
      if piece.isKing:
        self.king[piece.color] = uint8(square)
      self.balance += materialBalance[piece]

  self.reversible = true
  self.board = self.outposts[White] or self.outposts[Black]
  self.tally = self.valuation

  # Use temporary variables as tuple unpacking only works in var or let blocks.
  let (id, pawnId) = self.polyglot
  self.id = id
  self.pawnId = pawnId

  return self

#------------------------------------------------------------------------------
proc canCastle*(self: ptr Position, color: uint8): tuple[k: bool, q: bool] =
  # Start off with simple checks.
  var kingside = ((self.castles and castleKingside[color]) != 0) and ((gapKing[color] and self.board) == 0)
  var queenside = ((self.castles and castleQueenside[color]) != 0) and ((gapQueen[color] and self.board) == 0)

  # If it still looks like the castles are possible perform more expensive
  # final check.
  if kingside or queenside:
    let attacks = self.allAttacks(color xor 1)
    kingside = kingside and ((castleKing[color] and attacks) == 0)
    queenside = queenside and ((castleQueen[color] and attacks) == 0)

  return (kingside, queenside)

#------------------------------------------------------------------------------
proc toString*(self: ptr Position): string =
  result = "  a b c d e f g h"
  result &= "\n" # TODO: Check/color
  for row in countdown(7, 0):
    result.add(chr('1'.ord + row))
    for col in 0..7:
      result.add(' ')
      let piece = self.pieces[square(row, col)]
      if piece != 0:
        result &= piece.toFancy
      else:
        result &= "⋅"
    result &= "\n"
