# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned
import bitmask, init, data, piece, move, position/targets, utils
import generate, generate/helpers

#------------------------------------------------------------------------------
proc generateChecks*(self: ptr MoveGen): ptr MoveGen =
  ## Generates non-capturing checks.
  let p = self.p
  let color = p.color
  let enemy = color xor 1
  let square = int(p.king[enemy])

  # Non-capturing Knight checks.
  var checks = knightMoves[square]
  var outposts = p.outposts[knight(color)]
  while outposts != 0:
    let fr = outposts.pop
    self.addPieceMoves(fr, knightMoves[fr] and checks and (not p.board))

  # Non-capturing Bishop or Queen checks.
  checks = p.targetsFor(square, bishop(enemy))
  outposts = p.outposts[bishop(color)] or p.outposts[queen(color)]
  while outposts != 0:
    let fr = outposts.pop
    var targets = p.targetsFor(fr, bishop(enemy)) and checks and (not p.outposts[enemy])
    while targets != 0:
      let to = targets.pop
      let piece = p.pieces[to] 
      if piece == 0:
        # Empty square: simply move a bishop to check.
        self.add(newMove(p, fr, to))
      elif (piece.color == color) and (maskDiagonal[fr][square] != 0):
        # Non-empty square occupied by friendly piece on the same
        # diagonal: moving the piece away causes discovered check.
        case Piece(piece.kind)
          of Pawn:
            # Block pawn promotions (since they are treated as
            # captures) and en-passant captures.
            var prohibit = maskRank[0] or maskRank[7]
            if p.enpassant != 0:
              prohibit = prohibit or bit[p.enpassant]
            self.addPawnMoves(to, p.targets(to) and (not p.board) and (not prohibit))
            # NOTE without the discard Nim 0.11.2 results in
            # "...use of undeclared identifier 'LOCxxx'..."
            # error during C compilation.
            discard
          of King:
            # Make sure the king steps out of attack diaginal.
            self.addKingMoves(to, p.targets(to) and (not p.board) and (not maskBlock[fr][square]))
          else:
            self.addPieceMoves(to, p.targets(to) and (not p.board))

    if p.pieces[fr].isQueen:
      # Queen could move straight as a rook and check diagonally as a bishop
      # or move diagonally as a bishop and check straight as a rook.
      let targets = (p.targetsFor(fr, rook(color)) and checks) or
                    (p.targetsFor(fr, bishop(color)) and p.targetsFor(square, rook(color)))
      self.addPieceMoves(fr, targets and (not p.board))

  # Non-capturing Rook or Queen checks.
  checks = p.targetsFor(square, rook(enemy))
  outposts = p.outposts[rook(color)] or p.outposts[queen(color)]
  while outposts != 0:
    let fr = outposts.pop
    var targets = p.targetsFor(fr, rook(enemy)) and checks and (not p.outposts[enemy])
    while targets != 0:
      let to = targets.pop
      let piece = p.pieces[to]
      if piece == 0:
        # Empty square: simply move a rook to check.
        self.add(newMove(p, fr, to))
      elif piece.color == color:
        if maskStraight[fr][square] != 0:
          # Non-empty square occupied by friendly piece on the same
          # file or rank: moving the piece away causes discovered check.
          case Piece(piece.kind)
            of Pawn:
              # If pawn and rook share the same file then non-capturing
              # discovered check is not possible since the pawn is going
              # to stay on the same file no matter what.
              if col(fr) == col(to):
                continue
              # Block pawn promotions (since they are treated as captures)
              # and en-passant captures.
              var prohibit = maskRank[0] or maskRank[7]
              if p.enpassant != 0:
                prohibit = prohibit or bit[p.enpassant]
              self.addPawnMoves(to, p.targets(to) and (not p.board) and (not prohibit))
              # NOTE without the discard Nim 0.11.2 results in
              # "...use of undeclared identifier 'LOCxxx'..."
              # error during C compilation.
              discard
            of King:
              # Make sure the king steps out of attack file or rank.
              var prohibit = maskNone
              let row = row(fr)
              if row == row(square):
                prohibit = maskRank[row]
              else:
                prohibit = maskFile[col(square)]
              self.addKingMoves(to, p.targets(to) and (not p.board) and (not prohibit))
            else:
              self.addPieceMoves(to, p.targets(to) and (not p.board))

  # Non-capturing Pawn checks.
  outposts = p.outposts[pawn(color)] and maskIsolated[col(square)]
  while outposts != 0:
    let fr = outposts.pop
    var target = maskPawn[color][square] and p.targets(fr)
    if target != 0:
      self.add(newPawnMove(p, fr, target.pop))

  return self
