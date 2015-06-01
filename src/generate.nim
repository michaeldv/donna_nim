# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned, strutils, algorithm
import types, data, init, play, bitmask, piece, move, position, position/moves, position/targets

echo "Hello, from Generate ;-)"

type
  MoveWithScore* = tuple[move: Move, score: int]
  MoveGen* = object
    p*:    ptr Position
    list*: array[128, MoveWithScore]
    ply*:  int
    head*: int
    tail*: int
    pins*: Bitmask

# Move generator array contains one entry per ply. Last entry serves for utility
# move generation, ex. when converting string notations or determining a stalemate.
var moveList*: array[MaxPly + 1, MoveGen]

#------------------------------------------------------------------------------
proc newGen*(p: ptr Position, ply: int): ptr MoveGen =
  ## Returns "new" move generator for the given ply. Since move generator array
  ## is static we simply return a pointer to the existing array element re-initializing
  ## all its data.
  result = moveList[ply].addr
  result.p = p
  result.list.reset
  result.ply = ply
  result.head = 0
  result.tail = 0
  result.pins = p.pinnedMask(p.king[p.color])

#------------------------------------------------------------------------------
proc newMoveGen*(p: ptr Position): ptr MoveGen =
  ## Convenience method to return move generator for the current ply.
  return newGen(p, ply())

#------------------------------------------------------------------------------
proc newRootGen*(p: ptr Position, depth: int): ptr MoveGen =
  ## Returns new move generator for the initial step of iterative deepening
  ## (depth == 1) and existing one for subsequent iterations (depth > 1).
  if depth == 1:
    return newGen(p, 0) # Zero ply.
  return moveList[0].addr

#------------------------------------------------------------------------------
proc reset*(self: ptr MoveGen): ptr MoveGen {.discardable.} =
  self.head = 0
  return self

#------------------------------------------------------------------------------
proc size*(self: ptr MoveGen): int =
  return self.tail

#------------------------------------------------------------------------------
proc add*(self: ptr MoveGen, move: Move): ptr MoveGen {.discardable.} =
  self.list[self.tail].move = move
  inc(self.tail)
  return self

#------------------------------------------------------------------------------
proc remove*(self: ptr MoveGen): ptr MoveGen {.discardable.} =
  ## Removes current move from the list by copying over the ramaining moves. Head and
  ## tail pointers get decremented so that calling NexMove() works as expected.

  # Go's copy(self.list[self.head-1:], self.list[self.head:])
  # In Nim both slices should have the same length.
  self.list[self.head - 1 .. len(self.list) - 2] = self.list[self.head .. len(self.list) - 1]
  dec(self.head)
  dec(self.tail)
  return self

#------------------------------------------------------------------------------
proc onlyMove*(self: ptr MoveGen): bool =
  return self.tail == 1

#------------------------------------------------------------------------------
proc nextMove*(self: ptr MoveGen): Move =
  if self.head < self.tail:
    result = self.list[self.head].move
    inc(self.head)

#------------------------------------------------------------------------------
proc isValid*(self: ptr MoveGen, move: Move): bool =
  ## Returns true if the move is valid in current position i.e. it can be played
  ## without violating chess rules.
  return self.p.isValid(move, self.pins)

#------------------------------------------------------------------------------
proc validOnly*(self: ptr MoveGen): ptr MoveGen =
  ## Removes invalid moves from the generated list. We use in iterative deepening
  ## to avoid filtering out invalid moves on each iteration.
  var move = self.nextMove

  while move != 0:
    if not self.isValid(move):
      self.remove
    move = self.nextMove

  return self.reset

#------------------------------------------------------------------------------
proc anyValid*(self: ptr MoveGen): bool =
  ## Probes a list of generated moves and returns true if it contains at least
  ## one valid move.
  var move = self.nextMove

  while move != 0:
    if not self.isValid(move):
      return true
    move = self.nextMove

  return false

#------------------------------------------------------------------------------
proc amongValid*(self: ptr MoveGen, someMove: Move): bool =
  ## Probes valid-only list of generated moves and returns true if the given move
  ## is one of them.
  var move = self.nextMove

  while move != 0:
    if someMove == move:
      return true
    move = self.nextMove

  return false

#------------------------------------------------------------------------------
proc scoreMove*(self: ptr MoveGen, depth, score: int): ptr MoveGen {.discardable.} =
  # Assigns given score to the last move returned by the self.nextMove.
  let current = self.list[self.head - 1].addr

  if (depth == 1) or (current.score == score + 1):
    current.score = score
  elif (score != -depth) or ((score == -depth) and (current.score != score)):
    current.score += score # Fix up aspiration search drop.

  return self

#------------------------------------------------------------------------------
proc sort*(self: ptr MoveGen): ptr MoveGen =
  ## Sorts head/tail slice of the list.
  var slice = self.list[self.head .. self.tail - 1]

  slice.sort do (a, b: MoveWithScore) -> int:
    result = cmp(-a.score, -b.score)

  self.list[self.head .. self.tail - 1] = slice

  return self

#------------------------------------------------------------------------------
proc rank*(self: ptr MoveGen, bestMove: Move): ptr MoveGen {.discardable.} =
  if self.size < 2:
    return self

  for i in self.head ..< self.tail:
    let move = self.list[i].move
    if move == bestMove:
      self.list[i].score = 0xFFFF
    elif move.isCapture or move.isEnpassant or move.isPromo:
      self.list[i].score = 8192 + move.value
    elif move == game.killers[self.ply][0]:
      self.list[i].score = 4096
    elif move == game.killers[self.ply][1]:
      self.list[i].score = 2048
    else:
      self.list[i].score = game.good(move)

  return self.sort

#------------------------------------------------------------------------------
proc quickRank*(self: ptr MoveGen): ptr MoveGen {.discardable.} =
  if self.size < 2:
    return self

  for i in self.head ..< self.tail:
    let move = self.list[i].move
    if move.isCapture or move.isEnpassant or move.isPromo:
      self.list[i].score = 8192 + move.value
    else:
      self.list[i].score = game.good(move)

  return self.sort

#------------------------------------------------------------------------------
proc rootRank*(self: ptr MoveGen, bestMove: Move): ptr MoveGen {.discardable.} =
  if self.size < 2:
    return self

  # Find the best move and assign it the highest score.
  var best = -1
  var killer = -1
  var semikiller = -1
  var highest = -Checkmate

  for i in self.head ..< self.tail:
    let current = self.list[i].addr
    if current.move == bestMove:
      best = i
    elif current.move == game.killers[self.ply][0]:
      killer = i
    elif current.move == game.killers[self.ply][1]:
      semikiller = i

    current.score += (game.good(current.move) shr 3)
    if current.score > highest:
      highest = current.score

    if best != -1:
      self.list[best].score = highest + 10
    if killer != -1:
      self.list[killer].score = highest + 2
    if semikiller != -1:
      self.list[semikiller].score = highest + 1

  return self.sort

#------------------------------------------------------------------------------
proc allMoves*(self: ptr MoveGen): string =
  ## Returns a string of generated moves by continuously concatenating the NextMove()
  ## until the list is empty.
  var moves: seq[string] = @[]
  var move = self.nextMove

  while move != 0:
    moves.add(move.toString)
    move = self.nextMove

  self.reset # Restore head/tail pointers.
  return "[" & moves.join(" ") & "]"
