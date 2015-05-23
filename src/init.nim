# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned
import types, bitmask, data, params, score, utils

var
  kingMoves*: array[64, Bitmask]
  knightMoves*: array[64, Bitmask]
  pawnMoves*: array[2, array[64, Bitmask]]
  rookMagicMoves*: array[64, array[4096, Bitmask]]
  bishopMagicMoves*: array[64, array[512, Bitmask]]

  # Mask to help with pawn structure evaluation.
  maskPassed*: array[2, array[64, Bitmask]]
  maskInFront*: array[2, array[64, Bitmask]]
  
  # Complete file or rank mask if both squares reside on on the same file
  # or rank.
  maskStraight*: array[64, array[64, Bitmask]]

  # Complete diagonal mask if both squares reside on on the same diagonal.
  maskDiagonal*: array[64, array[64, Bitmask]]

  # If a king on square [x] gets checked from square [y] it can evade the
  # check from all squares except maskEvade[x][y]. For example, if white
  # king on B2 gets checked by black bishop on G7 the king can't step back
  # to A1 (despite not being attacked by black).
  maskEvade*: array[64, array[64, Bitmask]]

  # If a king on square [x] gets checked from square [y] the check can be
  # evaded by moving a piece to maskBlock[x][y]. For example, if white
  # king on B2 gets checked by black bishop on G7 the check can be evaded
  # by moving white piece onto C3-G7 diagonal (including capture on G7).
  maskBlock*: array[64, array[64, Bitmask]]

  # Bitmask to indicate pawn attacks for a square. For example, C3 is being
  # attacked by white pawns on B2 and D2, and black pawns on B4 and D4.
  maskPawn*: array[2, array[64, Bitmask]]

  # Two arrays to simplify incremental polyglot hash computation.
  hashCastle*: array[16, uint64]
  hashEnpassant*: array[8, uint64]

  # Distance between two squares.
  distance*: array[64, array[64, int]]

  # Precomputed database of material imbalance scores, evaluation flags,
  # and endgame handlers. I wish they all could be California girls.
  materialBase*: array[2 * 2 * 3 * 3 * 3 * 3 * 3 * 3 * 9 * 9, MaterialEntry]

#------------------------------------------------------------------------------
proc setupMasks(square, target, row, col, r, c: int) =
  if row == r:
    if col < c:
      discard maskBlock[square][target].fill(square, 1, bit[target], maskFull)
      discard maskEvade[square][target].spot(square, -1, not maskFile[0])
    else:
      discard maskBlock[square][target].fill(square, -1, bit[target], maskFull)
      discard maskEvade[square][target].spot(square, 1, not maskFile[7])
    if col != c:
      maskStraight[square][target] = maskRank[r]
  elif col == c:
    if row < r:
      discard maskBlock[square][target].fill(square, 8, bit[target], maskFull)
      discard maskEvade[square][target].spot(square, -8, not maskRank[0])
    else:
      discard maskBlock[square][target].fill(square, -8, bit[target], maskFull)
      discard maskEvade[square][target].spot(square, 8, not maskRank[7])
    if row != r:
      maskStraight[square][target] = maskFile[c]
  elif r + col == row + c: # Diagonals (A1->H8).
    if col < c:
      discard maskBlock[square][target].fill(square, 9, bit[target], maskFull)
      discard maskEvade[square][target].spot(square, -9, (not maskRank[0]) and (not maskFile[0]))
    else:
      discard maskBlock[square][target].fill(square, -9, bit[target], maskFull)
      discard maskEvade[square][target].spot(square, 9, (not maskRank[7]) and (not maskFile[7]))
    let shift = (r - c) and 15
    if shift < 8: # A1-A8-H8
      maskDiagonal[square][target] = Bitmask(int64(maskA1H8) shl (8 * shift))
    else: # B1-H1-H7
      maskDiagonal[square][target] = Bitmask(int64(maskA1H8) shr (8 * (16 - shift)))
  elif row + col == r + c: # AntiDiagonals (H1->A8).
    if col < c:
      discard maskBlock[square][target].fill(square, -7, bit[target], maskFull)
      discard maskEvade[square][target].spot(square, 7, (not maskRank[7]) and (not maskFile[0]))
    else:
      discard maskBlock[square][target].fill(square, 7, bit[target], maskFull)
      discard maskEvade[square][target].spot(square, -7, (not maskRank[0]) and (not maskFile[7]))
    let shift = 7 xor (r + c)
    if shift < 8: # A8-A1-H1
      maskDiagonal[square][target] = Bitmask(int64(maskH1A8) shr (8 * shift))
    else:
      maskDiagonal[square][target] = Bitmask(int64(maskH1A8) shl (8 * (16 - shift)))

  # Default values are all 0 for maskBlock[square][target] and all 1 for maskEvade[square][target].
  if maskEvade[square][target] == 0:
    maskEvade[square][target] = maskFull

#------------------------------------------------------------------------------
proc createRookMask(square: int): Bitmask =
  let (row, col) = coordinate(square)
  result = (maskRank[row] or maskFile[col]) xor bit[square]
  discard result.trim(row, col)

#------------------------------------------------------------------------------
proc createBishopMask(square: int): Bitmask =
  let (row, col) = coordinate(square)

  var sq = square + 7
  if (sq <= H8) and (col(sq) == col - 1):
    result = maskDiagonal[square][sq]
  else:
    sq = square - 7
    if (sq >= A1) and (col(sq) == col + 1):
      result = maskDiagonal[square][sq]

  sq = square + 9
  if (sq <= H8) and (col(sq) == col + 1):
    result = result or maskDiagonal[square][sq]
  else:
    sq = square - 9
    if (sq >= A1) and (col(sq) == col - 1):
      result = result or maskDiagonal[square][sq]

  result = result xor bit[square]
  discard result.trim(row, col)
    
#------------------------------------------------------------------------------
proc createRookAttacks(square: int, mask: Bitmask): Bitmask =
  let (row, col) = coordinate(square)

  # North.
  for r in (row + 1) .. 7:
    let b = bit[square(r, col)]
    result = result or b
    if (mask and b).dirty:
      break

  # East.
  for c in (col + 1) .. 7:
    let b = bit[square(row, c)]
    result = result or b
    if (mask and b).dirty:
      break

  # South.
  for r in countdown(row - 1, 0):
    let b = bit[square(r, col)]
    result = result or b
    if (mask and b).dirty:
      break

  # West.
  for c in countdown(col - 1, 0):
    let b = bit[square(row, c)]
    result = result or b
    if (mask and b).dirty:
      break

#------------------------------------------------------------------------------
proc createBishopAttacks(square: int, mask: Bitmask): Bitmask =
  let (row, col) = coordinate(square)

  # North East.
  var r = row + 1
  var c = col + 1
  while (c <= 7) and (r <= 7):
    let b = bit[square(r, c)]
    result = result or b
    if (mask and b).dirty:
      break
    r += 1
    c += 1

  # South East.
  r = row - 1
  c = col + 1
  while (c <= 7) and (r >= 0):
    let b = bit[square(r, c)]
    result = result or b
    if (mask and b).dirty:
      break
    r -= 1
    c += 1

  # South West.
  r = row - 1
  c = col - 1
  while (c >= 0) and (r >= 0):
    let b = bit[square(r, c)]
    result = result or b
    if (mask and b).dirty:
      break
    r -= 1
    c -= 1

  # North West.
  r = row + 1
  c = col - 1
  while (c >= 0) and (r <= 7):
    let b = bit[square(r, c)]
    result = result or b
    if (mask and b).dirty:
      break
    r += 1
    c -= 1

#------------------------------------------------------------------------------
proc initMasks() =
  echo "initMasks()..."

  for sq in A1..H8:
    let (row, col) = coordinate(sq)

    # Distance, Blocks, Evasions, Straight, Diagonals, Knights, and Kings.
    for i in A1..H8:
      let (r, c) = coordinate(i)

      distance[sq][i] = max(abs(row - r), abs(col - c))
      setupMasks(sq, i, row, col, r, c)

      if (i == sq) or (abs(i - sq) > 17):
        continue # No king or knight can reach that far.

      if ((abs(r - row) == 2) and (abs(c - col) == 1)) or ((abs(r - row) == 1) and (abs(c - col) == 2)):
        discard knightMoves[sq].set(i)
      if (abs(r - row) <= 1) and (abs(c - col) <= 1):
        discard kingMoves[sq].set(i)

    # Rooks.
    var mask = createRookMask(sq)
    var bits = mask.count
    for i in 0 ..< int(bit[bits]):
      let bitmask = mask.magicify(i)
      let index = (bitmask * rookMagic[sq].magic) shr 52
      rookMagicMoves[sq][index] = createRookAttacks(sq, bitmask)

    # Bishops.
    mask = createBishopMask(sq)
    bits = mask.count
    for i in 0 ..< int(bit[bits]):
      let bitmask = mask.magicify(i)
      let index = (bitmask * bishopMagic[sq].magic) shr 55
      bishopMagicMoves[sq][index] = createBishopAttacks(sq, bitmask)

    # Pawns.
    if (row >= A2H2) and (row <= A7H7):
      if col > 0:
        discard pawnMoves[White][sq].set(square(row + 1, col - 1))
        discard pawnMoves[Black][sq].set(square(row - 1, col - 1))

      if col < 7:
        discard pawnMoves[White][sq].set(square(row + 1, col + 1))
        discard pawnMoves[Black][sq].set(square(row - 1, col + 1))

    # Pawn attacks.
    if row > 1: # White pawns cant attack first two ranks.
      if col != 0:
        maskPawn[White][sq] = maskPawn[White][sq] or bit[sq - 9]
      if col != 7:
        maskPawn[White][sq] = maskPawn[White][sq] or bit[sq - 7]

    if row < 6: # Black pawns can attack 7th and 8th ranks.
      if col != 0:
        maskPawn[Black][sq] = maskPawn[Black][sq] or bit[sq + 7]
      if col != 7:
        maskPawn[Black][sq] = maskPawn[Black][sq] or bit[sq + 9]

    # Vertical squares in front of a pawn.
    maskInFront[White][sq] = (maskBlock[sq][A8 + col] or bit[A8 + col]) and (not bit[sq])
    maskInFront[Black][sq] = (maskBlock[A1 + col][sq] or bit[A1 + col]) and (not bit[sq])

    # Masks to check for passed pawns.
    if col > 0:
      maskPassed[White][sq] = maskPassed[White][sq] or maskInFront[White][sq - 1]
      maskPassed[Black][sq] = maskPassed[Black][sq] or maskInFront[Black][sq - 1]
      maskPassed[White][sq - 1] = maskPassed[White][sq - 1] or maskInFront[White][sq]
      maskPassed[Black][sq - 1] = maskPassed[Black][sq - 1] or maskInFront[Black][sq]

    maskPassed[White][sq] = maskPassed[White][sq] or maskInFront[White][sq]
    maskPassed[Black][sq] = maskPassed[Black][sq] or maskInFront[Black][sq]

#------------------------------------------------------------------------------
proc initArrays() =
  echo "initArrays()..."
  # Castle hash values.
  for mask in 0'u8..15'u8:
    if (mask and castleKingside[White]) != 0:
      hashCastle[mask] = hashCastle[mask] xor polyglotRandomCastle[0]
    if (mask and castleQueenside[White]) != 0:
      hashCastle[mask] = hashCastle[mask] xor polyglotRandomCastle[1]
    if (mask and castleKingside[Black]) != 0:
      hashCastle[mask] = hashCastle[mask] xor polyglotRandomCastle[2]
    if (mask and castleQueenside[Black]) != 0:
      hashCastle[mask] = hashCastle[mask] xor polyglotRandomCastle[3]

  # Enpassant hash values.
  for col in A1..H1:
    hashEnpassant[col] = polyglotRandomEnpassant[col]

#------------------------------------------------------------------------------
proc initPST() =
  echo "initPST()..."
  for square in A1 .. H8:
    # White pieces: flip square index since bonus points have been
    # set up from black's point of view.
    let flip = square xor A8
    pst[Pawn][square]  .add((bonusPawn  [0][flip], bonusPawn  [1][flip])).add(valuePawn)
    pst[Knight][square].add((bonusKnight[0][flip], bonusKnight[1][flip])).add(valueKnight)
    pst[Bishop][square].add((bonusBishop[0][flip], bonusBishop[1][flip])).add(valueBishop)
    pst[Rook][square]  .add((bonusRook  [0][flip], bonusRook  [1][flip])).add(valueRook)
    pst[Queen][square] .add((bonusQueen [0][flip], bonusQueen [1][flip])).add(valueQueen)
    pst[King][square]  .add((bonusKing  [0][flip], bonusKing  [1][flip]))

    # Black pieces: use square index as is, and assign negative
    # values so we could use white + black without extra condition.
    pst[BlackPawn][square]  .subtract((bonusPawn  [0][square], bonusPawn  [1][square])).subtract(valuePawn)
    pst[BlackKnight][square].subtract((bonusKnight[0][square], bonusKnight[1][square])).subtract(valueKnight)
    pst[BlackBishop][square].subtract((bonusBishop[0][square], bonusBishop[1][square])).subtract(valueBishop)
    pst[BlackRook][square]  .subtract((bonusRook  [0][square], bonusRook  [1][square])).subtract(valueRook)
    pst[BlackQueen][square] .subtract((bonusQueen [0][square], bonusQueen [1][square])).subtract(valueQueen)
    pst[BlackKing][square]  .subtract((bonusKing  [0][square], bonusKing  [1][square]))

#------------------------------------------------------------------------------
proc endgames(wP, wN, wB, wR, wQ, bP, bN, bB, bR, bQ: int): tuple[flags: uint8, endgame: Function] =
# func endgames(wP, wN, wB, wR, wQ, bP, bN, bB, bR, bQ int) (flags uint8, endgame Function) {
  let wMinor = wN + wB
  let wMajor = wR + wQ
  let bMinor = bN + bB
  let bMajor = bR + bQ
  let allMinor = wMinor + bMinor
  let allMajor = wMajor + bMajor

  let noPawns = (wP + bP == 0)
  let bareKing = ((wP + wMinor + wMajor) * (bP + bMinor + bMajor) == 0) # Bare king (white, black or both).

  # Set king safety flags if the opposing side has a queen and at least one piece.
  if (wQ > 0) and (wN + wB + wR > 0):
    result.flags = result.flags or blackKingSafety

  if (bQ > 0) and (bN + bB + bR > 0):
    result.flags = result.flags or whiteKingSafety

  # Insufficient material endgames that don't require further evaluation:
  # 1) Two bare kings.
  if wP + bP + allMinor + allMajor == 0:
    result.flags = result.flags or materialDraw

  # 2) No pawns and king with a minor.
  elif noPawns and (allMajor == 0) and (wMinor < 2) and (bMinor < 2):
    result.flags = result.flags or materialDraw

  # 3) No pawns and king with two knights.
  elif noPawns and (allMajor == 0) and (allMinor == 2) and ((wN == 2) or (bN == 2)):
    result.flags = result.flags or materialDraw

  # Known endgame: king and a pawn vs. bare king.
  elif (wP + bP == 1) and (allMinor == 0) and (allMajor == 0):
    result.flags = result.flags or knownEndgame
    # endgame = (*Evaluation).kingAndPawnVsBareKing

  # Known endgame: king with a knight and a bishop vs. bare king.
  elif noPawns and (allMajor == 0) and (((wN == 1) and (wB == 1)) or ((bN == 1) and (bB == 1))):
    result.flags = result.flags or knownEndgame
    # endgame = (*Evaluation).knightAndBishopVsBareKing

  # Known endgame: two bishops vs. bare king.
  elif noPawns and (allMajor == 0) and (((wN == 0) and (wB == 2)) or ((bN == 0) and (bB == 2))):
    result.flags = result.flags or knownEndgame
    # endgame = (*Evaluation).twoBishopsVsBareKing

  # Known endgame: king with some winning material vs. bare king.
  elif bareKing and (allMajor > 0):
    result.flags = result.flags or knownEndgame
    # endgame = (*Evaluation).winAgainstBareKing

  # Lesser known endgame: king and two or more pawns vs. bare king.
  elif bareKing and (allMinor + allMajor == 0) and (wP + bP > 1):
    result.flags = result.flags or lesserKnownEndgame
    # endgame = (*Evaluation).kingAndPawnsVsBareKing

  # Lesser known endgame: queen vs. rook with pawn(s)
  elif ((wP + wMinor + wR) == 0 and (wQ == 1) and (bMinor + bQ == 0) and (bP > 0) and (bR == 1)) or
       ((bP + bMinor + bR) == 0 and (bQ == 1) and (wMinor + wQ == 0) and (wP > 0) and (wR == 1)):
    result.flags = result.flags or lesserKnownEndgame
    # endgame = (*Evaluation).queenVsRookAndPawns

  # Lesser known endgame: king and pawn vs. king and pawn.
  elif (allMinor + allMajor == 0) and (wP == 1) and (bP == 1):
    result.flags = result.flags or lesserKnownEndgame
    # endgame = (*Evaluation).kingAndPawnVsKingAndPawn

  # Lesser known endgame: bishop and pawn vs. bare king.
  elif bareKing and (allMajor == 0) and (allMinor == 1) and ((wB + wP == 2) or (bB + bP == 2)):
    result.flags = result.flags or lesserKnownEndgame
    # endgame = (*Evaluation).bishopAndPawnVsBareKing

  # Lesser known endgame: rook and pawn vs. rook.
  elif (allMinor == 0) and (wQ + bQ == 0) and ((wR + wP == 2) or (bR + bP == 2)):
    result.flags = result.flags or lesserKnownEndgame
    # endgame = (*Evaluation).rookAndPawnVsRook

  # Lesser known endgame: no pawns left.
  elif ((wP == 0) or (bP == 0)) and (wMajor - bMajor == 0) and (abs(wMinor - bMinor) <= 1):
    result.flags = result.flags or lesserKnownEndgame
    # endgame = (*Evaluation).noPawnsLeft

  # Lesser known endgame: single pawn with not a lot of material.
  elif ((wP == 1) or (bP == 1)) and (wMajor - bMajor == 0) and (abs(wMinor - bMinor) <= 1):
    result.flags = result.flags or lesserKnownEndgame
    # endgame = (*Evaluation).lastPawnLeft

  # Check for potential opposite-colored bishops.
  elif wB * bB == 1:
    result.flags = result.flags or singleBishops
    if (allMajor == 0) and (allMinor == 2):
      result.flags = result.flags or lesserKnownEndgame
      # endgame = (*Evaluation).bishopsAndPawns
    elif (result.flags and (whiteKingSafety or blackKingSafety)) == 0:
      result.flags = result.flags or lesserKnownEndgame
      # endgame = (*Evaluation).drawishBishops

#------------------------------------------------------------------------------
proc imbalance(w2, wP, wN, wB, wR, wQ, b2, bP, bN, bB, bR, bQ: int): int =
  ## Simplified second-degree polynomial material imbalance by Tord Romstad.
  proc polynom(x, a, b, c: int): int =
    a * (x * x) + (b + c) * x

  return polynom(w2,    0, (   0                                                                                    ),  1852) +
         polynom(wP,    2, (  39*w2 +                                      37*b2                                    ),  -162) +
         polynom(wN,   -4, (  35*w2 + 271*wP +                             10*b2 +  62*bP                           ), -1122) +
         polynom(wB,    0, (   0*w2 + 105*wP +   4*wN +                    57*b2 +  64*bP +  39*bN                  ),  -183) +
         polynom(wR, -141, ( -27*w2 +  -2*wP +  46*wN + 100*wB +           50*b2 +  40*bP +  23*bN + -22*bB         ),   249) +
         polynom(wQ,    0, (-177*w2 +  25*wP + 129*wN + 142*wB + -137*wR + 98*b2 + 105*bP + -39*bN + 141*bB + 274*bR),  -154)


#------------------------------------------------------------------------------
proc initMaterial() =
  echo "initMaterial()..."
  for wQ in 0 ..< 2:
    for bQ in 0 ..< 2:
      for wR in 0 ..< 3:
        for bR in 0 ..< 3:
          for wB in 0 ..< 3:
            for bB in 0 ..< 3:
              for wN in 0 ..< 3:
                for bN in 0 ..< 3:
                  for wP in 0 ..< 9:
                    for bP in 0 ..< 9:
                      let index = wQ * materialBalance[Queen] +
                        bQ * materialBalance[BlackQueen]  +
                        wR * materialBalance[Rook]        +
                        bR * materialBalance[BlackRook]   +
                        wB * materialBalance[Bishop]      +
                        bB * materialBalance[BlackBishop] +
                        wN * materialBalance[Knight]      +
                        bN * materialBalance[BlackKnight] +
                        wP * materialBalance[Pawn]        +
                        bP * materialBalance[BlackPawn]

                      # Compute game phase and home turf values.
                      materialBase[index].phase = 12 * (wN + bN + wB + bB) + 18 * (wR + bR) + 44 * (wQ + bQ)
                      materialBase[index].turf = (wN + bN + wB + bB) * 36

                      # Set up evaluation flags and endgame handlers.
                      let (flags, callback) = endgames(wP, wN, wB, wR, wQ, bP, bN, bB, bR, bQ)
                      materialBase[index].flags = flags
                      materialBase[index].endgame = callback

                      # Compute material imbalance scores.
                      if (wQ != bQ ) or (wR != bR) or (wB != bB) or (wN != bN) or (wP != bP):
                        let white = imbalance(wB div 2, wP, wN, wB, wR, wQ,  bB div 2, bP, bN, bB, bR, bQ)
                        let black = imbalance(bB div 2, bP, bN, bB, bR, bQ,  wB div 2, wP, wN, wB, wR, wQ)

                        let adjustment = (white - black) div 32
                        materialBase[index].score.midgame += adjustment
                        materialBase[index].score.endgame += adjustment

#------------------------------------------------------------------------------
proc init() =
  initMasks()
  initArrays()
  initPST()
  initMaterial()

echo "Hello from Init ;-)"
init()
