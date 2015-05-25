# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import bitmask, piece, score
from data import MaxPly, MaxDepth

type
  Move* = uint32
  MoveInfo* = tuple[fr, to: int, piece, capture: Piece]

  PawnEntry* = tuple[
    id:      uint64,                # Pawn hash key.
    score:   Score,                 # Static score for the given pawn structure.
    king:    array[2, uint8],       # King square for both sides.
    cover:   array[2, Score],       # King cover penalties for both sides.
    passers: array[2, Bitmask]      # Passed pawn bitmasks for both sides.
  ]

  PawnCache* = array[8192 * 2, PawnEntry]

  CacheEntry* = tuple[
    id:      uint32,
    move:    Move,
    score:   int16,
    depth:   int16,
    flags:   uint8,
    token:   uint8
  ]

  Cache* = seq[CacheEntry]

  History* = array[14, array[64, int]]
  Killers* = array[MaxPly, array[2, Move]]
  RootPv* =  tuple[moves: array[MaxPly, Move], size: int]
  Pv* =      array[MaxPly, RootPv]

  Game* = object
    nodes*:      int                # Number of regular nodes searched.
    qnodes*:     int                # Number of quiescence nodes searched.
    token*:      uint8              # Cache's expiration token.
    deepening*:  bool               # True when searching first root move.
    improving*:  bool               # True when root search score is not falling.
    volatility*: float32            # Root search stability count.
    initial*:    string             # Initial position (FEN or algebraic).
    history*:    History            # Good moves history.
    killers*:    Killers            # Killer moves.
    rootpv*:     RootPv             # Principal variation for root moves.
    pv*:         Pv                 # Principal variations for each ply.
    cache*:      Cache              # Transposition table.
    pawnCache*:  PawnCache          # Cache of pawn structures.

  Position* = object
    id*:         uint64             # Polyglot hash value for the position.
    pawnId*:     uint64             # Polyglot hash value for position's pawn structure.
    board*:      Bitmask            # Bitmask of all pieces on the board.
    king*:       array[2, uint8]    # King's square for both colors.
    pieces*:     array[64, Piece]   # Array of 64 squares with pieces on them.
    outposts*:   array[14, Bitmask] # Bitmasks of each piece on the board; [0] all white, [1] all black.
    tally*:      Score              # Positional valuation score based on PST.
    balance*:    int                # Material balance index.
    reversible*: bool               # Is this position reversible?
    color*:      uint8              # Side to make next move.
    enpassant*:  uint8              # En-passant square caused by previous move.
    castles*:    uint8              # Castle rights mask.

  # King safety information; used only in the middle game when there is enough
  # material to worry about the king safety.
  Safety* = tuple[
    fort:        Bitmask,           # Squares around the king plus one extra row in front.
    threats:     int,               # A sum of treats: each based on attacking piece type.
    attacks:     int,               # Number of attacks on squares adjacent to the king.
    attackers:   int                # Number of pieces attacking king's fort.
  ]

  # Helper structure used for evaluation tracking.
  Total* = tuple[
    white: Score,                   # Score for white.
    black: Score                    # Score for black.
  ]

  Evaluation* = object
    score*:      Score    # Current score.
    safety*:     array[2, Safety]    # King safety data for both sides.
    attacks*:    array[14, Bitmask]  # Attack bitmasks for all the pieces on the board.
    pawns*:      ptr PawnEntry       # Pointer to the pawn cache entry.
    material*:   ptr MaterialEntry   # Pointer to the matrial base entry.
    position*:   ptr Position        # Pointer to the position we're evaluating.

  Function* =
    proc(): int

  MaterialEntry* = tuple[
    score:   Score,                 # Score adjustment for the given material.
    endgame: Function,              # Function to analyze an endgame position.
    phase:   int,                   # Game phase based on available material.
    turf:    int,                   # Home turf score for the game opening.
    flags:   uint8                  # Evaluation flags based on material balance.
  ]
