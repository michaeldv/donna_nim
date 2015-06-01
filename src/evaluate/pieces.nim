# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE filself.

import unsigned
import types, bitmask, data, init, piece, params, score, utils, position/targets

echo "Hello from Evaluate Pieces;-)"

type
  Mob = tuple[score, mobility: Score]

#------------------------------------------------------------------------------
proc enemyKingThreat(self: ptr Evaluation, piece: Piece, attacks: Bitmask) =
  ## Updates safety data used later on when evaluating king safety.
  let enemy = piece.color xor 1

  if (attacks and self.safety[enemy].fort) != 0:
    inc(self.safety[enemy].attackers)
    self.safety[enemy].threats += bonusKingThreat[piece.kind div 2]

    let mask = attacks and self.attacks[king(enemy)]
    if mask != 0:
      self.safety[enemy].attacks += mask.count

#------------------------------------------------------------------------------
proc knights(self: ptr Evaluation, color: uint8, maskSafe: Bitmask, threat: bool): Mob =
  let p = self.position
  let enemy = color xor 1
  var outposts = p.outposts[knight(color)]

  while outposts != 0:
    let square = outposts.pop
    let attacks = p.attacks(square)

    # Bonus for knight's mobility.
    result.mobility.add(mobilityKnight[(attacks and maskSafe).count])

    # Penalty if knight is attacked by enemy's pawn.
    if (maskPawn[enemy][square] and p.outposts[pawn(enemy)]) != 0:
      discard result.score.subtract(penaltyPawnThreat[Knight div 2])

    # Bonus if knight is behind friendly pawn.
    if (rank(color, square) < 4) and p.outposts[pawn(color)].on(square + eight[color]):
      discard result.score.add(behindPawn)

    # Extra bonus if knight is in the center. Increase the extra bonus
    # if the knight is supported by a pawn and can't be exchanged.
    var extra = extraKnight[flip(color, square)]
    if extra > 0:
      if p.pawnAttacks(color).on(square):
        extra += extra div 2 # Supported by a pawn.
        if p.outposts[knight(enemy)].empty and (same(square) and p.outposts[bishop(enemy)]).empty:
          extra += (extra * 2) div 3 # No knights or bishops to exchange.
      result.score.adjust(extra)

    # Track if knight attacks squares around enemy's king.
    if threat:
      self.enemyKingThreat(knight(color), attacks)

    # Update attack bitmask for the knight.
    self.attacks[knight(color)] = self.attacks[knight(color)] or attacks

#------------------------------------------------------------------------------
proc bishops(self: ptr Evaluation, color: uint8, maskSafe: Bitmask, threat: bool): Mob =
  let p = self.position
  let enemy = color xor 1
  var outposts = p.outposts[bishop(color)]

  while outposts != 0:
    let square = outposts.pop
    let attacks = p.xrayAttacks(square)

    # Bonus for bishop's mobility
    result.mobility.add(mobilityBishop[(attacks and maskSafe).count])

    # Penalty for light/dark-colored pawns restricting a bishop.
    let count = (same(square) and p.outposts[pawn(color)]).count
    if count > 0:
      discard result.score.subtract(bishopPawn.times(count))

    # Penalty if bishop is attacked by enemy's pawn.
    if (maskPawn[enemy][square] and p.outposts[pawn(enemy)]) != 0:
      discard result.score.subtract(penaltyPawnThreat[Bishop div 2])

    # Bonus if bishop is behind friendly pawn.
    if (rank(color, square) < 4) and p.outposts[pawn(color)].on(square + eight[color]):
      discard result.score.add(behindPawn)

    # Middle game penalty for boxed bishop.
    if self.material.phase > 160:
      if color == White:
        if ((square == C1) and p.pieces[D2].isPawn and (p.pieces[D3] != 0)) or
           ((square == F1) and p.pieces[E2].isPawn and (p.pieces[E3] != 0)):
          result.score.midgame -= bishopBoxed.midgame
      else:
        if ((square == C8) and p.pieces[D7].isPawn and (p.pieces[D6] != 0)) or
           ((square == F8) and p.pieces[E7].isPawn and (p.pieces[E6] != 0)):
          result.score.midgame -= bishopBoxed.midgame

    # Extra bonus if bishop is in the center. Increase the extra bonus
    # if the bishop is supported by a pawn and can't be exchanged.
    var extra = extraBishop[flip(color, square)]
    if extra > 0:
      if p.pawnAttacks(color).on(square):
        extra += extra div 2 # Supported by a pawn.
        if p.outposts[knight(enemy)].empty and (same(square) and p.outposts[bishop(enemy)]).empty:
          extra += (extra * 2) div 3 # No knights or bishops to exchangself.
      result.score.adjust(extra)

    # Track if bishop attacks squares around enemy's king.
    if threat:
      self.enemyKingThreat(bishop(color), attacks)

    # Update attack bitmask for the bishop.
    self.attacks[bishop(color)] = self.attacks[bishop(color)] or attacks

#------------------------------------------------------------------------------
proc rooks(self: ptr Evaluation, color: uint8, maskSafe: Bitmask, threat: bool): Mob =
  let p = self.position
  let enemy = color xor 1
  let hisPawns = p.outposts[pawn(color)]
  let herPawns = p.outposts[pawn(enemy)]
  var outposts = p.outposts[rook(color)]

  # Bonus if rook is on 7th rank and enemy's king trapped on 8th.
  let count = (outposts and mask7th[color]).count
  if (count > 0) and ((p.outposts[king(enemy)] and mask8th[color]) != 0):
    discard result.score.add(rookOn7th.times(count))

  while outposts != 0:
    let square = outposts.pop
    let attacks = p.xrayAttacks(square)

    # Bonus for rook's mobility
    let safeSquares = (attacks and maskSafe).count
    discard result.mobility.add(mobilityRook[safeSquares])

    # Penalty if rook is attacked by enemy's pawn.
    if (maskPawn[enemy][square] and herPawns) != 0:
      discard result.score.subtract(penaltyPawnThreat[Rook div 2])

    # Bonus if rook is attacking enemy's pawns.
    if rank(color, square) >= 4:
      let count = (attacks and herPawns).count
      if count > 0:
        discard result.score.add(rookOnPawn.times(count))

    # Bonuses if rook is on open or semi-open filself.
    let column = col(square)
    let isFileAjar = (hisPawns and maskFile[column]).empty
    if isFileAjar:
      if (herPawns and maskFile[column]).empty:
        discard result.score.add(rookOnOpen)
      else:
        discard result.score.add(rookOnSemiOpen)

    # Middle game penalty if a rook is boxed. Extra penalty if castle
    # rights have been lost.
    if (safeSquares <= 3) or (not isFileAjar):
      let kingSquare = int(p.king[color])
      let kingColumn = col(kingSquare)

      # Queenside box: king on D/C/B vs. rook on A/B/C files. Increase the
      # the penalty since no castle is possiblself.
      if (column < kingColumn) and rookBoxA[color].on(square) and kingBoxA[color].on(kingSquare):
        result.score.midgame -= (rookBoxed.midgame - safeSquares * 10) * 2

      # Kingside box: king on E/F/G vs. rook on H/G/F files.
      if (column > kingColumn) and rookBoxH[color].on(square) and kingBoxH[color].on(kingSquare):
        result.score.midgame -= (rookBoxed.midgame - safeSquares * 10)
        if (p.castles and castleKingside[color]).empty:
          result.score.midgame -= (rookBoxed.midgame - safeSquares * 10)

    # Track if rook attacks squares around enemy's king.
    if threat:
      self.enemyKingThreat(rook(color), attacks)

    # Update attack bitmask for the rook.
    self.attacks[rook(color)] = self.attacks[rook(color)] or attacks

#------------------------------------------------------------------------------
proc queens(self: ptr Evaluation, color: uint8, maskSafe: Bitmask, threat: bool): Mob =
  let p = self.position
  let enemy = color xor 1
  var outposts = p.outposts[queen(color)]

  # Bonus if queen is on 7th rank and enemy's king trapped on 8th.
  let count = (outposts and mask7th[color]).count
  if (count > 0) and ((p.outposts[king(enemy)] and mask8th[color]) != 0):
    discard result.score.add(queenOn7th.times(count))

  while outposts != 0:
    let square = outposts.pop()
    let attacks = p.attacks(square)

    # Bonus for queen's mobility.
    result.mobility.add(mobilityQueen[min(15, (attacks and maskSafe).count)])

    # Penalty if queen is attacked by enemy's pawn.
    if (maskPawn[enemy][square] and p.outposts[pawn(enemy)]) != 0:
      discard result.score.subtract(penaltyPawnThreat[Queen div 2])

    # Bonus if queen is out and attacking enemy's pawns.
    let count = (attacks and p.outposts[pawn(enemy)]).count
    if (count > 0) and (rank(color, square) > 3):
      discard result.score.add(queenOnPawn.times(count))

    # Track if queen attacks squares around enemy's king.
    if threat:
      self.enemyKingThreat(queen(color), attacks)

    # Update attack bitmask for the queen.
    self.attacks[queen(color)] = self.attacks[queen(color)] or attacks

#------------------------------------------------------------------------------
proc setupFort*(self: ptr Evaluation, color: uint8): Bitmask =
  ## Initializes the fort bitmask around king's squarself. For example, for a king on
  ## G1 the bitmask covers F1,F2,F3, G2,G3, and H1,H2,H3. For a king on a corner
  ## square, say H1, the bitmask covers F1,F2, G1,G2,G3, and H2,H3.
  result = self.attacks[king(color)] or self.attacks[king(color)].pushed(color)
  case self.position.king[color]
    of A1, A8:
      result = result or (self.attacks[king(color)] shl 1)
    of H1, H8:
      result = result or (self.attacks[king(color)] shr 1)
    else:
      discard

#------------------------------------------------------------------------------
proc analyzePieces*(self: ptr Evaluation): ptr Evaluation {.discardable.} =
  var knight, bishop, rook, queen, mobility: Total
  let p = self.position

  # Mobility masks for both sides exclude a) squares attacked by enemy's
  # pawns and b) squares occupied by friendly pawns and the king.
  var maskSafeForWhite = not (self.attacks[BlackPawn] or p.outposts[Pawn] or p.outposts[King])
  var maskSafeForBlack = not (self.attacks[Pawn] or p.outposts[BlackPawn] or p.outposts[BlackKing])

  # Initialize king fort bitmasks only when we need them.
  let isWhiteKingThreatened = ((self.material.flags and whiteKingSafety) != 0)
  let isBlackKingThreatened = ((self.material.flags and blackKingSafety) != 0)
  if isWhiteKingThreatened:
    self.safety[White].fort = self.setupFort(White)
  if isBlackKingThreatened:
    self.safety[Black].fort = self.setupFort(Black)

  # Evaluate white pieces except the queen.
  if p.outposts[Knight] != 0:
    let (score, mobile) = self.knights(White, maskSafeForWhite, isBlackKingThreatened)
    knight.white = score
    discard mobility.white.add(mobile)

  if p.outposts[Bishop] != 0:
    let (score, mobile) = self.bishops(White, maskSafeForWhite, isBlackKingThreatened)
    bishop.white = score
    discard mobility.white.add(mobile)

  if p.outposts[Rook] != 0:
    let (score, mobile) = self.rooks(White, maskSafeForWhite, isBlackKingThreatened)
    rook.white = score
    discard mobility.white.add(mobile)

  # Evaluate black pieces except the queen.
  if p.outposts[BlackKnight] != 0:
    let (score, mobile) = self.knights(Black, maskSafeForBlack, isWhiteKingThreatened)
    knight.black = score
    discard mobility.black.add(mobile)

  if p.outposts[BlackBishop] != 0:
    let (score, mobile) = self.bishops(Black, maskSafeForBlack, isWhiteKingThreatened)
    bishop.black = score
    discard mobility.black.add(mobile)

  if p.outposts[BlackRook] != 0:
    let (score, mobile) = self.rooks(Black, maskSafeForBlack, isWhiteKingThreatened)
    rook.black = score
    discard mobility.black.add(mobile)

  # Now that we've built all attack bitmasks we can adjust mobility to
  # exclude attacks by enemy's knights, bishops, and rooks and evaluate
  # the queens.
  if p.outposts[Queen] != 0:
    maskSafeForWhite = maskSafeForWhite and (not (self.attacks[BlackKnight] or self.attacks[BlackBishop] or self.attacks[BlackRook]))
    let (score, mobile) = self.queens(White, maskSafeForWhite, isBlackKingThreatened)
    queen.white = score
    discard mobility.white.add(mobile)

  if p.outposts[BlackQueen] != 0:
    maskSafeForBlack = maskSafeForBlack and (not (self.attacks[Knight] or self.attacks[Bishop] or self.attacks[Rook]))
    let (score, mobile) = self.queens(Black, maskSafeForBlack, isWhiteKingThreatened)
    queen.black = score
    discard mobility.black.add(mobile)

  # Update attack bitmasks for both sides.
  self.attacks[White] = self.attacks[White] or (self.attacks[Knight] or self.attacks[Bishop] or self.attacks[Rook] or self.attacks[Queen])
  self.attacks[Black] = self.attacks[Black] or (self.attacks[BlackKnight] or self.attacks[BlackBishop] or self.attacks[BlackRook] or self.attacks[BlackQueen])

  # Apply weights to the mobility scores.
  # mobility.white.apply(weights[0])
  # mobility.black.apply(weights[0])

  # Update cumulative score based on white vs. black bonuses and mobility.
  self.score.add(knight.white).add(bishop.white).add(rook.white).add(queen.white).add(mobility.white)
  self.score.subtract(knight.black).subtract(bishop.black).subtract(rook.black).subtract(queen.black).subtract(mobility.black)

  return self
