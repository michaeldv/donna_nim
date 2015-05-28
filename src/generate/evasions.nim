# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned
import init, data, utils, bitmask, piece, move
import position, position/targets, position/moves
import generate, generate/helpers

#------------------------------------------------------------------------------
proc generateEvasions*(self: ptr MoveGen): ptr MoveGen {.discardable.} =
  let p = self.p
  let color = p.color
  let enemy = p.color xor 1
  let square = int(p.king[color])

  # Find out what pieces are checking the king. Usually it's a single
  # piece but double check is also a possibility.
  var checkers = maskPawn[enemy][square] and p.outposts[pawn(enemy)]
  checkers = checkers or (p.targetsFor(square, knight(color)) and p.outposts[knight(enemy)])
  checkers = checkers or (p.targetsFor(square, bishop(color)) and (p.outposts[bishop(enemy)] or p.outposts[queen(enemy)]))
  checkers = checkers or (p.targetsFor(square, rook(color)) and (p.outposts[rook(enemy)] or p.outposts[queen(enemy)]))

  # Generate possible king retreats first, i.e. moves to squares not
  # occupied by friendly pieces and not attacked by the opponent.
  var retreats = p.targets(square) and (not p.allAttacks(enemy))

  # If the attacking piece is bishop, rook, or queen then exclude the
  # square behind the king using evasion mask. Note that knight's
  # evasion mask is full board so we only check if the attacking piece
  # is not a pawn.
  var attackSquare = checkers.pop
  if p.pieces[attackSquare] != pawn(enemy):
    retreats = retreats and maskEvade[square][attackSquare]

  # If checkers mask is not empty then we've got double check and
  # retreat is the only option.
  if checkers != 0:
    attackSquare = checkers.first
    if p.pieces[attackSquare] != pawn(enemy):
      retreats = retreats and maskEvade[square][attackSquare]
    return self.addPieceMoves(square, retreats)

  # Generate king retreats. Since castle is not an option there is no
  # reason to use addKingMoves().
  self.addPieceMoves(square, retreats)

  # Pawn captures: do we have any pawns available that could capture
  # the attacking piece?
  var pawns = maskPawn[color][attackSquare] and p.outposts[pawn(color)]
  while pawns != 0:
    var move = newMove(p, pawns.pop, attackSquare)
    if (attackSquare >= A8) or (attackSquare <= H1):
      move = move.promote(Queen)
    self.add(move)

  # Rare case when the check could be avoided by en-passant capture.
  # For example: Ke4, c5, e5 vs. Ke8, d7. Black's d7-d5+ could be
  # evaded by c5xd6 or e5xd6 en-passant captures.
  if p.enpassant != 0:
    let enpassant = attackSquare + eight[color]
    if enpassant == int(p.enpassant):
      var epawns = maskPawn[color][enpassant] and p.outposts[pawn(color)]
      while epawns != 0:
        self.add(newMove(p, epawns.pop, enpassant))

  # See if the check could be blocked or the attacked piece captured.
  let blocker = maskBlock[square][attackSquare] or bit[attackSquare]

  # Create masks for one-square pawn pushes and two-square jumps.
  var jumps = not p.board
  if color == White:
    pawns = (p.outposts[Pawn] shl 8) and (not p.board)
    jumps = jumps and (maskRank[3] and (pawns shl 8))
  else:
    pawns = (p.outposts[BlackPawn] shr 8) and (not p.board)
    jumps = jumps and (maskRank[4] and (pawns shr 8))
  pawns = pawns and blocker
  jumps = jumps and blocker

  # Handle one-square pawn pushes: promote to Queen if reached last rank.
  while pawns != 0:
    let to = pawns.pop
    let fr = to - eight[color]
    var move = newMove(p, fr, to) # Can't cause en-passant.
    if (to >= A8) or (to <= H1):
      move = move.promote(Queen)
    self.add(move)

  # Handle two-square pawn jumps that can cause en-passant.
  while jumps != 0:
    let to = jumps.pop
    let fr = to - 2 * eight[color]
    self.add(newPawnMove(p, fr, to))

  # What's left is to generate all possible knight, bishop, rook, and
  # queen moves that evade the check.
  var outposts = p.outposts[color] and (not p.outposts[pawn(color)]) and (not p.outposts[king(color)])
  while outposts != 0:
    let fr = outposts.pop
    let targets = p.targets(fr) and blocker
    self.addPieceMoves(fr, targets)

  return self
