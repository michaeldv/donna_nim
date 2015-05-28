# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE filself.

import unsigned
import types, bitmask, data, init, piece, params, play, score, utils, position/targets

echo "Hello from Evaluate Pawns;-)"

#------------------------------------------------------------------------------
proc pawnStructure*(self: ptr Evaluation, color: uint8): Score =
  ## Calculates extra bonus and penalty based on pawn structure. Specifically,
  ## a bonus is awarded for passed pawns, and penalty applied for isolated and
  ## doubled pawns.
  let hisPawns = self.position.outposts[pawn(color)]
  let herPawns = self.position.outposts[pawn(color xor 1)]
  self.pawns.passers[color] = 0

  # Encourage center pawn moves in the opening.
  var pawns = hisPawns

  while pawns != 0:
    let square = pawns.pop
    let (row, col) = coordinate(square)

    # Penalty if the pawn is isolated, i.e. has no friendly pawns on adjacent files.
    # The penalty goes up if isolated pawn is exposed on semi-open file.
    let isolated = (maskIsolated[col] and hisPawns).empty
    let exposed = (maskInFront[color][square] and herPawns).empty
    if isolated:
      if not exposed:
        discard result.subtract(penaltyIsolatedPawn[col])
      else:
        discard result.subtract(penaltyWeakIsolatedPawn[col])

    # Penalty if the pawn is doubled, i.e. there is another friendly pawn in front
    # of us. The penalty goes up if doubled pawns are isolated.
    let doubled = ((maskInFront[color][square] and hisPawns) != 0)
    if doubled:
      discard result.subtract(penaltyDoubledPawn[col])

    # Bonus if the pawn is supported by friendly pawn(s) on the same or previous ranks.
    let supported = ((maskIsolated[col] and (maskRank[row] or maskRank[row].pushed(color xor 1)) and hisPawns) != 0)
    if supported:
      let flipped = flip(color, square)
      discard result.add((bonusSupportedPawn[flipped], bonusSupportedPawn[flipped]))

    # The pawn is passed if a) there are no enemy pawns in the same
    # and adjacent columns; and b) there are no same color pawns in
    # front of us.
    let passed = ((maskPassed[color][square] and herPawns).empty and (not doubled))
    if passed:
      self.pawns.passers[color].set(square)

    # Penalty if the pawn is backward.
    var backward = false
    if (not passed) and (not supported) and (not isolated):

      # Backward pawn should not be attacking enemy pawns.
      if (pawnMoves[color][square] and herPawns).empty:

        # Backward pawn should not have friendly pawns behind.
        if (maskPassed[color xor 1][square] and maskIsolated[col] and hisPawns).empty:

          # Backward pawn should face enemy pawns on the next two ranks
          # preventing its advance.
          let enemy = pawnMoves[color][square].pushed(color)
          if ((enemy or enemy.pushed(color)) and herPawns) != 0:
            backward = true
            if not exposed:
              discard result.subtract(penaltyBackwardPawn[col])
            else:
              discard result.subtract(penaltyWeakBackwardPawn[col])

    # Bonus if the pawn has good chance to become a passed pawn.
    if exposed and supported and (not passed) and (not backward):
      let his = (maskPassed[color xor 1][square + eight[color]] and maskIsolated[col] and hisPawns)
      let her = (maskPassed[color][square] and maskIsolated[col] and herPawns)
      if his.count >= her.count:
        discard result.add(bonusSemiPassedPawn[rank(color, square)])

    #- Encourage center pawn moves.
    #- if maskCenter.on(square):
    #-   result.midgame += bonusPawn[0][flip(color, square)] div 2

proc pawnPassers*(self: ptr Evaluation, color: uint8): Score =
  let p = self.position

  var pawns = self.pawns.passers[color]
  while pawns != 0:
    let square = pawns.pop
    let rank = rank(color, square)
    var bonus = bonusPassedPawn[rank]

    if rank > A2H2:
      var extra = extraPassedPawn[rank]
      let nextSquare = square + eight[color]

      # Adjust endgame bonus based on how close the kings are from the
      # step forward square.
      bonus.endgame += (distance[p.king[color xor 1]][nextSquare] * 5 - distance[p.king[color]][nextSquare] * 2) * extra

      # Check if the pawn can step forward.
      if p.board.off(nextSquare):
        var boost = 0

        # Assume all squares in front of the pawn are under attack.
        var attacked = maskInFront[color][square]
        let protected = (attacked and self.attacks[color])

        # Boost the bonus if squares in front of the pawn are protected.
        if protected == attacked:
          boost += 6 # All squares.
        elif protected.on(nextSquare):
          boost += 4 # Next square only.

        # Check who is attacking the squares in front of the pawn including
        # queen and rook x-ray attacks from behind.
        let enemy = (maskInFront[color xor 1][square] and (p.outposts[queen(color xor 1)] or p.outposts[rook(color xor 1)]))
        if enemy.empty or (enemy and p.rookMoves(square)).empty:

          # Since nobody attacks the pawn from behind adjust the attacked
          # bitmask to only include squares attacked or occupied by the enemy.
          attacked = attacked and (self.attacks[color xor 1] or p.outposts[color xor 1])

        # Boost the bonus if passed pawn is free to advance to the 8th rank
        # or at least safely step forward.
        if attacked.empty:
          boost += 15 # Remaining squares are not under attack.
        elif attacked.off(nextSquare):
          boost += 9  # Next square is not under attack.

        if boost > 0:
          discard bonus.adjust(extra * boost)

    discard result.add(bonus)
  # endwhile

#------------------------------------------------------------------------------
proc analyzePawns*(self: ptr Evaluation): ptr Evaluation {.discardable.} =
  let key = self.position.pawnId

  # Since pawn hash is fairly small we can use much faster 32-bit index.
  let index = uint32(key) mod uint32(len(game.pawnCache)) # 8192 * 2
  self.pawns = game.pawnCache[index].addr

  if self.pawns.id != key:
    let white = self.pawnStructure(White)
    let black = self.pawnStructure(Black)

    # white.apply(weights[1]); black.apply(weights[1]) # <-- Pawn structure weight.
    discard self.pawns.score.clear().add(white).subtract(black)
    self.pawns.id = key

    # Force full king shelter evaluation since any legit king square
    # will be viewed as if the king has moved.
    self.pawns.king[White] = 0xFF
    self.pawns.king[Black] = 0xFF

  self.score.add(self.pawns.score)

  return self

#------------------------------------------------------------------------------
proc analyzePassers*(self: ptr Evaluation): ptr Evaluation {.discardable.} =
  let white = self.pawnPassers(White)
  let black = self.pawnPassers(Black)

  # white.apply(weights[2]); black.apply(weights[2]) # <-- Passed pawns weight.
  self.score.add(white).subtract(black)

  return self
