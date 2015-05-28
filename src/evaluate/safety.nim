# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE filself.

import unsigned
import types, bitmask, data, init, piece, params, score, utils, position/targets

echo "Hello from Evaluate Safety;-)"

#------------------------------------------------------------------------------
proc kingSafety(self: ptr Evaluation, color: uint8): Score =
  let p = self.position
  let enemy = color xor 1

  if self.safety[color].threats > 0:
    let square = int(p.king[color])
    var safetyIndex = 0

    # Find squares around the king that are being attacked by the
    # enemy and defended by our king only.
    let defended = self.attacks[pawn(color)] or self.attacks[knight(color)] or
                   self.attacks[bishop(color)] or self.attacks[rook(color)] or
                   self.attacks[queen(color)]
    let weak = self.attacks[king(color)] and self.attacks[enemy] and (not defended)

    # Find possible queen checks on weak squares around the king. We only consider
    # squares where the queen is protected and can't be captured by the king.
    var protected = self.attacks[pawn(enemy)] or self.attacks[knight(enemy)] or
                    self.attacks[bishop(enemy)] or self.attacks[rook(enemy)] or
                    self.attacks[king(enemy)]
    var checks = weak and self.attacks[queen(enemy)] and protected and (not p.outposts[enemy])
    if checks != 0:
      safetyIndex += bonusCloseCheck[Queen div 2] * checks.count

    # Find possible rook checks within king's home zone. Unlike queen we must only
    # consider squares where the rook actually gives a check.
    protected = self.attacks[pawn(enemy)] or self.attacks[knight(enemy)] or
                self.attacks[bishop(enemy)] or self.attacks[queen(enemy)] or
                self.attacks[king(enemy)]
    checks = weak and self.attacks[rook(enemy)] and protected and (not p.outposts[enemy])
    checks = checks and rookMagicMoves[square][0]
    if checks != 0:
      safetyIndex += bonusCloseCheck[Rook div 2] * checks.count

    # Double safety index if the enemy has right to move.
    if p.color == enemy:
      safetyIndex *= 2

    # Out of all squares available for enemy pieces select the ones that are
    # not under our attack.
    let safe = not (self.attacks[color] or p.outposts[enemy])

    # Are there any safe squares from where enemy Knight could give us a check?
    checks = knightMoves[square] and safe and self.attacks[knight(enemy)]
    if not checks.empty:
      safetyIndex += bonusDistanceCheck[Knight div 2] * checks.count

    # Are there any safe squares from where enemy Bishop could give us a check?
    let safeBishopMoves = p.bishopMoves(square) and safe
    checks = safeBishopMoves and self.attacks[bishop(enemy)]
    if not checks.empty:
      safetyIndex += bonusDistanceCheck[Bishop div 2] * checks.count

    # Are there any safe squares from where enemy Rook could give us a check?
    let safeRookMoves = p.rookMoves(square) and safe
    checks = safeRookMoves and self.attacks[rook(enemy)]
    if not checks.empty:
      safetyIndex += bonusDistanceCheck[Rook div 2] * checks.count

    # Are there any safe squares from where enemy Queen could give us a check?
    checks = (safeBishopMoves or safeRookMoves) and self.attacks[queen(enemy)]
    if not checks.empty:
      safetyIndex += bonusDistanceCheck[Queen div 2] * checks.count

    let threatIndex = (self.safety[color].attacks + weak.count) * 2 +
                      min(12, (self.safety[color].attackers * self.safety[color].threats) div 3)                     

    result.midgame -= kingSafetyDelta[min(63, safetyIndex + threatIndex)]

#------------------------------------------------------------------------------
proc kingCoverBonus(self: ptr Evaluation, color: uint8, square, flipped: int): int =
  let (row, col) = coordinate(flipped)
  let fr = max(0, col - 1)
  let to = min(7, col + 1)
  result = onePawn + (onePawn div 3)

  # Get friendly pawns adjacent and in front of the king.
  let adjacent = maskIsolated[col] and maskRank[row(square)]
  let pawns = self.position.outposts[pawn(color)] and (adjacent or maskPassed[color][square])

  # For each of the cover files find the closest friendly pawn. The penalty
  # is carried if the pawn is missing or is too far from the king (more than
  # one rank apart).
  for column in fr .. to:
    let cover = pawns and maskFile[column]
    if not cover.empty:
      let closest = rank(color, cover.closest(color))
      result -= penaltyCover[closest - row]
    else:
      result -= coverMissing.midgame

#------------------------------------------------------------------------------
proc kingCover(self: ptr Evaluation, color: uint8): Score =
  let p = self.position
  let square = int(self.position.king[color])

  # Calculate relative square for the king so we could treat black king
  # as white. Don't bother with the cover if the king is too far.
  let flipped = flip(color xor 1, square)
  if flipped > H3:
    return

  # If we still have castle rights encourage castle pawns to stay intact
  # by scoring least safe castle.
  result.midgame = self.kingCoverBonus(color, square, flipped)

  if (p.castles and castleKingside[color]) != 0:
    result.midgame = max(result.midgame, self.kingCoverBonus(color, homeKing[color] + 2, G1))

  if (p.castles and castleQueenside[color]) != 0:
    result.midgame = max(result.midgame, self.kingCoverBonus(color, homeKing[color] - 2, C1))


#------------------------------------------------------------------------------
proc kingPawnProximity(self: ptr Evaluation, color: uint8): int =
  ## Calculates endgame penalty to encourage a king stay closer to friendly pawns.
  var pawns = self.position.outposts[pawn(color)]
  if (not pawns.empty) and (pawns and self.attacks[king(color)]).empty:
    var proximity = 8
    let king = self.position.king[color]

    while pawns != 0:
      proximity = min(proximity, distance[king][pawns.pop])

    result = -kingByPawn.endgame * (proximity - 1)

#------------------------------------------------------------------------------
proc analyzeSafety*(self: ptr Evaluation): ptr Evaluation {.discardable.} =
  let oppositeBishops = self.position.oppositeBishops

  # Any pawn move invalidates king's square in the pawns hash so that we
  # could detect it here.
  let whiteKingMoved = self.position.king[White] != self.pawns.king[White]
  let blackKingMoved = self.position.king[Black] != self.pawns.king[Black]

  # If the king has moved then recalculate king/pawn proximity and update
  # cover score and king square in the pawn cache.
  if whiteKingMoved:
    self.pawns.cover[White] = self.kingCover(White)
    self.pawns.cover[White].endgame += self.kingPawnProximity(White)
    self.pawns.king[White] = self.position.king[White]

  if blackKingMoved:
    self.pawns.cover[Black] = self.kingCover(Black)
    self.pawns.cover[Black].endgame += self.kingPawnProximity(Black)
    self.pawns.king[Black] = self.position.king[Black]

  # Fetch king cover score from the pawn cache.
  let cover: Total = (
    white: self.pawns.cover[White],
    black: self.pawns.cover[Black]
  )

  # Compute king's safety for both sides.
  var safety: Total = (
    white: self.kingSafety(White),
    black: self.kingSafety(Black)
  )

  if oppositeBishops and ((self.material.flags and whiteKingSafety) != 0) and (safety.white.midgame < -onePawn div 10 * 8):
    safety.white.midgame -= bishopDanger.midgame
  if oppositeBishops and ((self.material.flags and blackKingSafety) != 0) and (safety.black.midgame < -onePawn div 10 * 8):
    safety.black.midgame -= bishopDanger.midgame


  # Apply weights by mapping Black to our king safety index [3], and White
  # to enemy's king safety index [4].
  # cover.white.apply(weights[3+color])
  # cover.black.apply(weights[4-color])
  # safety.white.apply(weights[3+color])
  # safety.black.apply(weights[4-color])
  discard self.score.add(cover.white).add(safety.white).subtract(cover.black).subtract(safety.black)

