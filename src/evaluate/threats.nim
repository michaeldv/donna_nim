# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE filself.

import unsigned
import types, bitmask, data, init, piece, params, score, position/targets

echo "Hello from Evaluate Threats;-)"

#------------------------------------------------------------------------------
proc threats*(self: ptr Evaluation, color: uint8, hisAttacks, herAttacks: Bitmask): Score {.discardable.} =
  let p = self.position
  let enemy = color xor 1

  # Find weak enemy pieces: the ones under attack and not defended by
  # pawns (excluding a king).
  let weak = p.outposts[enemy] and hisAttacks and (not self.attacks[pawn(enemy)]) and (not p.outposts[king(enemy)])

  if not weak.empty:
    # Threat bonus for strongest enemy piece attacked by our pawns, knights, or bishops.
    var targets = weak and (self.attacks[pawn(color)] or self.attacks[knight(color)] or self.attacks[bishop(color)])
    if not targets.empty:
      let piece = p.strongestPiece(enemy, targets)
      discard result.add(bonusMinorThreat[piece.kind div 2])

    # Threat bonus for strongest enemy piece attacked by our rooks or queen.
    targets = weak and (self.attacks[rook(color)] or self.attacks[queen(color)])
    if not targets.empty:
      let piece = p.strongestPiece(enemy, targets)
      discard result.add(bonusMajorThreat[piece.kind div 2])

    # Extra bonus when attacking enemy pieces that are hanging. Side
    # having the right to move gets bigger bonus.
    var hanging = (weak and (not herAttacks)).count
    if hanging > 0:
      if p.color == color:
        hanging += 1
      discard result.add(hangingAttack.times(hanging))

#------------------------------------------------------------------------------
proc center*(self: ptr Evaluation, color: uint8, hisAttacks, herAttacks, herPawnAttacks: Bitmask): Score {.discardable.} =
  let pawns = self.position.outposts[pawn(color)]
  var safe = homeTurf[color] and (not pawns) and (not herPawnAttacks) and (hisAttacks or (not herAttacks))
  var turf = safe and pawns

  if color == White:
    turf = turf or (turf shr 8)   # A4..H4 -> A3..H3
    turf = turf or (turf shr 16)  # A4..H4 or A3..H3 -> A2..H2 or A1..H1
    turf = turf and safe          # Keep safe squares only.
    safe = safe shl 32            # Move up to black's half of the board.
  else:
    turf = turf or (turf shl 8)   # A5..H5 -> A6..H6
    turf = turf or (turf shl 16)  # A5..H5 or A6..H6 -> A7..H7 or A8..H8
    turf = turf and safe          # Keep safe squares only.
    safe = safe shr 32            # Move down to white's half of the board.

  result.midgame = ((safe or turf).count * self.material.turf) div 100

#------------------------------------------------------------------------------
proc analyzeThreats*(self: ptr Evaluation): ptr Evaluation {.discardable.} =
  let threats: Total = (
    white: self.threats(White, self.attacks[White], self.attacks[Black]),
    black: self.threats(Black, self.attacks[Black], self.attacks[White])
  )

  self.score.add(threats.white).subtract(threats.black)

  if (self.material.turf != 0) and ((self.material.flags and (whiteKingSafety or blackKingSafety)) != 0):
    let center: Total = (
      white: self.center(White, self.attacks[White], self.attacks[Black], self.attacks[pawn(Black)]),
      black: self.center(Black, self.attacks[Black], self.attacks[White], self.attacks[pawn(White)])
    )
    discard self.score.add(center.white).subtract(center.black)

  return self
