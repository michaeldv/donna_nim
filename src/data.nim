# Copyright (c) 2014-2015 by Michael Dvorkin. All Rights Reserved.
# Use of this source code is governed by a MIT-style license that can
# be found in the LICENSE file.

import unsigned
import bitmask

# The primary purpose of the DATA statement is to give names to constants;
# instead of referring to pi as 3.141592653589793 at every appearance, the
# variable PI can be given that value with a DATA statement and used instead
# of the longer form of the constant.
#
# This also simplifies modifying the program, should the value of pi change.
#
#                                      -― FORTRAN manual for Xerox Computers

type
  Magic* = tuple[mask, magic: uint64]

  GameStatus* = enum
    InProgress,     # Game is in progress.
    WhiteWon,       # White checkmated.
    BlackWon,       # Black checkmated.
    Stalemate,      # Draw by stalemate, forced or self-imposed.
    Insufficient,   # Draw by insufficient material.
    Repetition,     # Draw by repetition.
    FiftyMoves      # Draw by 50 moves rule.

# const = brains * looks * availability
const
  Version = "1.0"

  # Limits and conventions.
  White* = uint8(0)
  Black* = uint8(1)
  MaxPly* = 64
  MaxDepth* = 32
  Checkmate* = 0x7FFF - 1  # = 32,766
  UnknownScore* = 0x7FFF   # = 32,767
  WhiteWinning* = Checkmate / 10       # Decisive advantage for White.
  BlackWinning* = -Checkmate / 10 + 1  # Decisive advantage for Black.

  # Pieces.
  Pawn*        = 2
  Knight*      = 4
  Bishop*      = 6
  Rook*        = 8
  Queen*       = 10
  King*        = 12
  BlackPawn*   = Pawn or 1
  BlackKnight* = Knight or 1
  BlackBishop* = Bishop or 1
  BlackRook*   = Rook or 1
  BlackQueen*  = Queen or 1
  BlackKing*   = King or 1

  # Board squares.
  A1* =  0
  B1* =  1
  C1* =  2
  D1* =  3
  E1* =  4
  F1* =  5
  G1* =  6
  H1* =  7
  A2* =  8
  B2* =  9
  C2* = 10
  D2* = 11
  E2* = 12
  F2* = 13
  G2* = 14
  H2* = 15
  A3* = 16
  B3* = 17
  C3* = 18
  D3* = 19
  E3* = 20
  F3* = 21
  G3* = 22
  H3* = 23
  A4* = 24
  B4* = 25
  C4* = 26
  D4* = 27
  E4* = 28
  F4* = 29
  G4* = 30
  H4* = 31
  A5* = 32
  B5* = 33
  C5* = 34
  D5* = 35
  E5* = 36
  F5* = 37
  G5* = 38
  H5* = 39
  A6* = 40
  B6* = 41
  C6* = 42
  D6* = 43
  E6* = 44
  F6* = 45
  G6* = 46
  H6* = 47
  A7* = 48
  B7* = 49
  C7* = 50
  D7* = 51
  E7* = 52
  F7* = 53
  G7* = 54
  H7* = 55
  A8* = 56
  B8* = 57
  C8* = 58
  D8* = 59
  E8* = 60
  F8* = 61
  G8* = 62
  H8* = 63

  # Rank and file indices.
  A1H1* = 0
  A2H2* = 1
  A3H3* = 2
  A4H4* = 3
  A5H5* = 4
  A6H6* = 5
  A7H7* = 6
  A8H8* = 7
  A1A8* = 0
  B1B8* = 1
  C1C8* = 2
  D1D8* = 3
  E1E8* = 4
  F1F8* = 5
  G1G8* = 6
  H1H8* = 7

  # Evaluation flags.
  whiteKingSafety*    = 0x01  # Should we worry about white king's safety?
  blackKingSafety*    = 0x02  # Ditto for the black king.
  materialDraw*       = 0x04  # King vs. King (with minor)
  knownEndgame*       = 0x08  # Where we calculate exact score.
  lesserKnownEndgame* = 0x10  # Where we set score markdown value.
  singleBishops*      = 0x20  # Sides might have bishops on opposite color squares.

  maskNone* = Bitmask(0)
  maskFull* = Bitmask(0xFFFF_FFFF_FFFF_FFFF)
  maskDark* = Bitmask(0xAA55_AA55_AA55_AA55)
  maskA1H8* = Bitmask(0x8040_2010_0804_0201)
  maskH1A8* = Bitmask(0x0102_0408_1020_4080)

  maskRank*: array[8, Bitmask] = [
    Bitmask(0x00000000000000FF), Bitmask(0x000000000000FF00), Bitmask(0x0000000000FF0000), Bitmask(0x00000000FF000000),
    Bitmask(0x000000FF00000000), Bitmask(0x0000FF0000000000), Bitmask(0x00FF000000000000), Bitmask(0xFF00000000000000),
  ]

  maskFile*: array[8, Bitmask] = [
    Bitmask(0x0101010101010101), Bitmask(0x0202020202020202), Bitmask(0x0404040404040404), Bitmask(0x0808080808080808),
    Bitmask(0x1010101010101010), Bitmask(0x2020202020202020), Bitmask(0x4040404040404040), Bitmask(0x8080808080808080),
  ]

  maskIsolated*: array[8, Bitmask] = [
    Bitmask(0x0202020202020202), Bitmask(0x0505050505050505), Bitmask(0x0A0A0A0A0A0A0A0A), Bitmask(0x1414141414141414),
    Bitmask(0x2828282828282828), Bitmask(0x5050505050505050), Bitmask(0xA0A0A0A0A0A0A0A0), Bitmask(0x4040404040404040),
  ]

  castleKingside*: array[2, uint8] = [ 1'u8, 4'u8 ]
  castleQueenside*: array[2, uint8] = [ 2'u8, 8'u8 ]
  castleRights*: array[64, uint8] = [
    13'u8, 15'u8, 15'u8, 15'u8, 12'u8, 15'u8, 15'u8, 14'u8,
    15'u8, 15'u8, 15'u8, 15'u8, 15'u8, 15'u8, 15'u8, 15'u8,
    15'u8, 15'u8, 15'u8, 15'u8, 15'u8, 15'u8, 15'u8, 15'u8,
    15'u8, 15'u8, 15'u8, 15'u8, 15'u8, 15'u8, 15'u8, 15'u8,
    15'u8, 15'u8, 15'u8, 15'u8, 15'u8, 15'u8, 15'u8, 15'u8,
    15'u8, 15'u8, 15'u8, 15'u8, 15'u8, 15'u8, 15'u8, 15'u8,
    15'u8, 15'u8, 15'u8, 15'u8, 15'u8, 15'u8, 15'u8, 15'u8,
     7'u8, 15'u8, 15'u8, 15'u8,  3'u8, 15'u8, 15'u8, 11'u8,
  ]

  eight*: array[2, int] = [ 8, -8 ]
  homeKing*: array[2, int] = [ E1, E8 ]
  mask7th*: array [2, Bitmask] = [ maskRank[6], maskRank[1] ]
  mask8th*: array[2, Bitmask] = [ maskRank[7], maskRank[0] ]

  # Home turf in the center.
  homeTurf*: array[2, Bitmask] = [ Bitmask(0x000000003C3C3C00), Bitmask(0x003C3C3C00000000) ]

  materialBalance*: array[14, int] = [
    0, 0,
    2 * 2 * 3 * 3 * 3 * 3 * 9,     # Pawn
    2 * 2 * 3 * 3 * 3 * 3 * 9 * 9, # Black Pawn
    2 * 2 * 3 * 3 * 3 * 3,         # Knight
    2 * 2 * 3 * 3 * 3 * 3 * 3,     # Black Knight
    2 * 2 * 3 * 3,                 # Bishop
    2 * 2 * 3 * 3 * 3,             # Black Bishop
    2 * 2,                         # Rook
    2 * 2 * 3,                     # Black Rook
    1,                             # Queen
    1 * 2,                         # Black Queen
    0, 0,                          # Kings
  ]

let
  # Castle squares that should be *empty* in order for the castle to be valid.
  gapKing*: array[2, Bitmask] = [ bit[F1] or bit[G1], bit[F8] or bit[G8] ]
  gapQueen*: array[2, Bitmask] = [ bit[B1] or bit[C1] or bit[D1], bit[B8] or bit[C8] or bit[D8] ]

  # Castle squares that should be *safe* in order for the castle to be valid.
  castleKing*: array[2, Bitmask] = [ bit[E1] or bit[F1] or bit[G1], bit[E8] or bit[F8] or bit[G8] ]
  castleQueen*: array[2, Bitmask] = [ bit[C1] or bit[D1] or bit[E1], bit[C8] or bit[D8] or bit[E8] ]

  # Boxed rooks.
  kingBoxA*: array[2, Bitmask] = [ bit[D1] or bit[C1] or bit[B1], bit[D8] or bit[C8] or bit[B8] ]
  kingBoxH*: array[2, Bitmask] = [ bit[E1] or bit[F1] or bit[G1], bit[E8] or bit[F8] or bit[G8] ]
  rookBoxA*: array[2, Bitmask] = [ bit[A1] or bit[B1] or bit[C1], bit[A8] or bit[B8] or bit[C8] ]
  rookBoxH*: array[2, Bitmask] = [ bit[H1] or bit[G1] or bit[F1], bit[H8] or bit[G8] or bit[F8] ]

const
  # Default polyglot Random64 array (http:#hardy.uhasselt.be/Toga/book_format.html)
  # is split in four to avoid dealing with slices.
  polyglotRandom*: array[768, uint64] = [
    0x9D39247E33776D41'u64, 0x2AF7398005AAA5C7'u64, 0x44DB015024623547'u64, 0x9C15F73E62A76AE2'u64,
    0x75834465489C0C89'u64, 0x3290AC3A203001BF'u64, 0x0FBBAD1F61042279'u64, 0xE83A908FF2FB60CA'u64,
    0x0D7E765D58755C10'u64, 0x1A083822CEAFE02D'u64, 0x9605D5F0E25EC3B0'u64, 0xD021FF5CD13A2ED5'u64,
    0x40BDF15D4A672E32'u64, 0x011355146FD56395'u64, 0x5DB4832046F3D9E5'u64, 0x239F8B2D7FF719CC'u64,
    0x05D1A1AE85B49AA1'u64, 0x679F848F6E8FC971'u64, 0x7449BBFF801FED0B'u64, 0x7D11CDB1C3B7ADF0'u64,
    0x82C7709E781EB7CC'u64, 0xF3218F1C9510786C'u64, 0x331478F3AF51BBE6'u64, 0x4BB38DE5E7219443'u64,
    0xAA649C6EBCFD50FC'u64, 0x8DBD98A352AFD40B'u64, 0x87D2074B81D79217'u64, 0x19F3C751D3E92AE1'u64,
    0xB4AB30F062B19ABF'u64, 0x7B0500AC42047AC4'u64, 0xC9452CA81A09D85D'u64, 0x24AA6C514DA27500'u64,
    0x4C9F34427501B447'u64, 0x14A68FD73C910841'u64, 0xA71B9B83461CBD93'u64, 0x03488B95B0F1850F'u64,
    0x637B2B34FF93C040'u64, 0x09D1BC9A3DD90A94'u64, 0x3575668334A1DD3B'u64, 0x735E2B97A4C45A23'u64,
    0x18727070F1BD400B'u64, 0x1FCBACD259BF02E7'u64, 0xD310A7C2CE9B6555'u64, 0xBF983FE0FE5D8244'u64,
    0x9F74D14F7454A824'u64, 0x51EBDC4AB9BA3035'u64, 0x5C82C505DB9AB0FA'u64, 0xFCF7FE8A3430B241'u64,
    0x3253A729B9BA3DDE'u64, 0x8C74C368081B3075'u64, 0xB9BC6C87167C33E7'u64, 0x7EF48F2B83024E20'u64,
    0x11D505D4C351BD7F'u64, 0x6568FCA92C76A243'u64, 0x4DE0B0F40F32A7B8'u64, 0x96D693460CC37E5D'u64,
    0x42E240CB63689F2F'u64, 0x6D2BDCDAE2919661'u64, 0x42880B0236E4D951'u64, 0x5F0F4A5898171BB6'u64,
    0x39F890F579F92F88'u64, 0x93C5B5F47356388B'u64, 0x63DC359D8D231B78'u64, 0xEC16CA8AEA98AD76'u64,
    0x5355F900C2A82DC7'u64, 0x07FB9F855A997142'u64, 0x5093417AA8A7ED5E'u64, 0x7BCBC38DA25A7F3C'u64,
    0x19FC8A768CF4B6D4'u64, 0x637A7780DECFC0D9'u64, 0x8249A47AEE0E41F7'u64, 0x79AD695501E7D1E8'u64,
    0x14ACBAF4777D5776'u64, 0xF145B6BECCDEA195'u64, 0xDABF2AC8201752FC'u64, 0x24C3C94DF9C8D3F6'u64,
    0xBB6E2924F03912EA'u64, 0x0CE26C0B95C980D9'u64, 0xA49CD132BFBF7CC4'u64, 0xE99D662AF4243939'u64,
    0x27E6AD7891165C3F'u64, 0x8535F040B9744FF1'u64, 0x54B3F4FA5F40D873'u64, 0x72B12C32127FED2B'u64,
    0xEE954D3C7B411F47'u64, 0x9A85AC909A24EAA1'u64, 0x70AC4CD9F04F21F5'u64, 0xF9B89D3E99A075C2'u64,
    0x87B3E2B2B5C907B1'u64, 0xA366E5B8C54F48B8'u64, 0xAE4A9346CC3F7CF2'u64, 0x1920C04D47267BBD'u64,
    0x87BF02C6B49E2AE9'u64, 0x092237AC237F3859'u64, 0xFF07F64EF8ED14D0'u64, 0x8DE8DCA9F03CC54E'u64,
    0x9C1633264DB49C89'u64, 0xB3F22C3D0B0B38ED'u64, 0x390E5FB44D01144B'u64, 0x5BFEA5B4712768E9'u64,
    0x1E1032911FA78984'u64, 0x9A74ACB964E78CB3'u64, 0x4F80F7A035DAFB04'u64, 0x6304D09A0B3738C4'u64,
    0x2171E64683023A08'u64, 0x5B9B63EB9CEFF80C'u64, 0x506AACF489889342'u64, 0x1881AFC9A3A701D6'u64,
    0x6503080440750644'u64, 0xDFD395339CDBF4A7'u64, 0xEF927DBCF00C20F2'u64, 0x7B32F7D1E03680EC'u64,
    0xB9FD7620E7316243'u64, 0x05A7E8A57DB91B77'u64, 0xB5889C6E15630A75'u64, 0x4A750A09CE9573F7'u64,
    0xCF464CEC899A2F8A'u64, 0xF538639CE705B824'u64, 0x3C79A0FF5580EF7F'u64, 0xEDE6C87F8477609D'u64,
    0x799E81F05BC93F31'u64, 0x86536B8CF3428A8C'u64, 0x97D7374C60087B73'u64, 0xA246637CFF328532'u64,
    0x043FCAE60CC0EBA0'u64, 0x920E449535DD359E'u64, 0x70EB093B15B290CC'u64, 0x73A1921916591CBD'u64,
    0x56436C9FE1A1AA8D'u64, 0xEFAC4B70633B8F81'u64, 0xBB215798D45DF7AF'u64, 0x45F20042F24F1768'u64,
    0x930F80F4E8EB7462'u64, 0xFF6712FFCFD75EA1'u64, 0xAE623FD67468AA70'u64, 0xDD2C5BC84BC8D8FC'u64,
    0x7EED120D54CF2DD9'u64, 0x22FE545401165F1C'u64, 0xC91800E98FB99929'u64, 0x808BD68E6AC10365'u64,
    0xDEC468145B7605F6'u64, 0x1BEDE3A3AEF53302'u64, 0x43539603D6C55602'u64, 0xAA969B5C691CCB7A'u64,
    0xA87832D392EFEE56'u64, 0x65942C7B3C7E11AE'u64, 0xDED2D633CAD004F6'u64, 0x21F08570F420E565'u64,
    0xB415938D7DA94E3C'u64, 0x91B859E59ECB6350'u64, 0x10CFF333E0ED804A'u64, 0x28AED140BE0BB7DD'u64,
    0xC5CC1D89724FA456'u64, 0x5648F680F11A2741'u64, 0x2D255069F0B7DAB3'u64, 0x9BC5A38EF729ABD4'u64,
    0xEF2F054308F6A2BC'u64, 0xAF2042F5CC5C2858'u64, 0x480412BAB7F5BE2A'u64, 0xAEF3AF4A563DFE43'u64,
    0x19AFE59AE451497F'u64, 0x52593803DFF1E840'u64, 0xF4F076E65F2CE6F0'u64, 0x11379625747D5AF3'u64,
    0xBCE5D2248682C115'u64, 0x9DA4243DE836994F'u64, 0x066F70B33FE09017'u64, 0x4DC4DE189B671A1C'u64,
    0x51039AB7712457C3'u64, 0xC07A3F80C31FB4B4'u64, 0xB46EE9C5E64A6E7C'u64, 0xB3819A42ABE61C87'u64,
    0x21A007933A522A20'u64, 0x2DF16F761598AA4F'u64, 0x763C4A1371B368FD'u64, 0xF793C46702E086A0'u64,
    0xD7288E012AEB8D31'u64, 0xDE336A2A4BC1C44B'u64, 0x0BF692B38D079F23'u64, 0x2C604A7A177326B3'u64,
    0x4850E73E03EB6064'u64, 0xCFC447F1E53C8E1B'u64, 0xB05CA3F564268D99'u64, 0x9AE182C8BC9474E8'u64,
    0xA4FC4BD4FC5558CA'u64, 0xE755178D58FC4E76'u64, 0x69B97DB1A4C03DFE'u64, 0xF9B5B7C4ACC67C96'u64,
    0xFC6A82D64B8655FB'u64, 0x9C684CB6C4D24417'u64, 0x8EC97D2917456ED0'u64, 0x6703DF9D2924E97E'u64,
    0xC547F57E42A7444E'u64, 0x78E37644E7CAD29E'u64, 0xFE9A44E9362F05FA'u64, 0x08BD35CC38336615'u64,
    0x9315E5EB3A129ACE'u64, 0x94061B871E04DF75'u64, 0xDF1D9F9D784BA010'u64, 0x3BBA57B68871B59D'u64,
    0xD2B7ADEEDED1F73F'u64, 0xF7A255D83BC373F8'u64, 0xD7F4F2448C0CEB81'u64, 0xD95BE88CD210FFA7'u64,
    0x336F52F8FF4728E7'u64, 0xA74049DAC312AC71'u64, 0xA2F61BB6E437FDB5'u64, 0x4F2A5CB07F6A35B3'u64,
    0x87D380BDA5BF7859'u64, 0x16B9F7E06C453A21'u64, 0x7BA2484C8A0FD54E'u64, 0xF3A678CAD9A2E38C'u64,
    0x39B0BF7DDE437BA2'u64, 0xFCAF55C1BF8A4424'u64, 0x18FCF680573FA594'u64, 0x4C0563B89F495AC3'u64,
    0x40E087931A00930D'u64, 0x8CFFA9412EB642C1'u64, 0x68CA39053261169F'u64, 0x7A1EE967D27579E2'u64,
    0x9D1D60E5076F5B6F'u64, 0x3810E399B6F65BA2'u64, 0x32095B6D4AB5F9B1'u64, 0x35CAB62109DD038A'u64,
    0xA90B24499FCFAFB1'u64, 0x77A225A07CC2C6BD'u64, 0x513E5E634C70E331'u64, 0x4361C0CA3F692F12'u64,
    0xD941ACA44B20A45B'u64, 0x528F7C8602C5807B'u64, 0x52AB92BEB9613989'u64, 0x9D1DFA2EFC557F73'u64,
    0x722FF175F572C348'u64, 0x1D1260A51107FE97'u64, 0x7A249A57EC0C9BA2'u64, 0x04208FE9E8F7F2D6'u64,
    0x5A110C6058B920A0'u64, 0x0CD9A497658A5698'u64, 0x56FD23C8F9715A4C'u64, 0x284C847B9D887AAE'u64,
    0x04FEABFBBDB619CB'u64, 0x742E1E651C60BA83'u64, 0x9A9632E65904AD3C'u64, 0x881B82A13B51B9E2'u64,
    0x506E6744CD974924'u64, 0xB0183DB56FFC6A79'u64, 0x0ED9B915C66ED37E'u64, 0x5E11E86D5873D484'u64,
    0xF678647E3519AC6E'u64, 0x1B85D488D0F20CC5'u64, 0xDAB9FE6525D89021'u64, 0x0D151D86ADB73615'u64,
    0xA865A54EDCC0F019'u64, 0x93C42566AEF98FFB'u64, 0x99E7AFEABE000731'u64, 0x48CBFF086DDF285A'u64,
    0x7F9B6AF1EBF78BAF'u64, 0x58627E1A149BBA21'u64, 0x2CD16E2ABD791E33'u64, 0xD363EFF5F0977996'u64,
    0x0CE2A38C344A6EED'u64, 0x1A804AADB9CFA741'u64, 0x907F30421D78C5DE'u64, 0x501F65EDB3034D07'u64,
    0x37624AE5A48FA6E9'u64, 0x957BAF61700CFF4E'u64, 0x3A6C27934E31188A'u64, 0xD49503536ABCA345'u64,
    0x088E049589C432E0'u64, 0xF943AEE7FEBF21B8'u64, 0x6C3B8E3E336139D3'u64, 0x364F6FFA464EE52E'u64,
    0xD60F6DCEDC314222'u64, 0x56963B0DCA418FC0'u64, 0x16F50EDF91E513AF'u64, 0xEF1955914B609F93'u64,
    0x565601C0364E3228'u64, 0xECB53939887E8175'u64, 0xBAC7A9A18531294B'u64, 0xB344C470397BBA52'u64,
    0x65D34954DAF3CEBD'u64, 0xB4B81B3FA97511E2'u64, 0xB422061193D6F6A7'u64, 0x071582401C38434D'u64,
    0x7A13F18BBEDC4FF5'u64, 0xBC4097B116C524D2'u64, 0x59B97885E2F2EA28'u64, 0x99170A5DC3115544'u64,
    0x6F423357E7C6A9F9'u64, 0x325928EE6E6F8794'u64, 0xD0E4366228B03343'u64, 0x565C31F7DE89EA27'u64,
    0x30F5611484119414'u64, 0xD873DB391292ED4F'u64, 0x7BD94E1D8E17DEBC'u64, 0xC7D9F16864A76E94'u64,
    0x947AE053EE56E63C'u64, 0xC8C93882F9475F5F'u64, 0x3A9BF55BA91F81CA'u64, 0xD9A11FBB3D9808E4'u64,
    0x0FD22063EDC29FCA'u64, 0xB3F256D8ACA0B0B9'u64, 0xB03031A8B4516E84'u64, 0x35DD37D5871448AF'u64,
    0xE9F6082B05542E4E'u64, 0xEBFAFA33D7254B59'u64, 0x9255ABB50D532280'u64, 0xB9AB4CE57F2D34F3'u64,
    0x693501D628297551'u64, 0xC62C58F97DD949BF'u64, 0xCD454F8F19C5126A'u64, 0xBBE83F4ECC2BDECB'u64,
    0xDC842B7E2819E230'u64, 0xBA89142E007503B8'u64, 0xA3BC941D0A5061CB'u64, 0xE9F6760E32CD8021'u64,
    0x09C7E552BC76492F'u64, 0x852F54934DA55CC9'u64, 0x8107FCCF064FCF56'u64, 0x098954D51FFF6580'u64,
    0x23B70EDB1955C4BF'u64, 0xC330DE426430F69D'u64, 0x4715ED43E8A45C0A'u64, 0xA8D7E4DAB780A08D'u64,
    0x0572B974F03CE0BB'u64, 0xB57D2E985E1419C7'u64, 0xE8D9ECBE2CF3D73F'u64, 0x2FE4B17170E59750'u64,
    0x11317BA87905E790'u64, 0x7FBF21EC8A1F45EC'u64, 0x1725CABFCB045B00'u64, 0x964E915CD5E2B207'u64,
    0x3E2B8BCBF016D66D'u64, 0xBE7444E39328A0AC'u64, 0xF85B2B4FBCDE44B7'u64, 0x49353FEA39BA63B1'u64,
    0x1DD01AAFCD53486A'u64, 0x1FCA8A92FD719F85'u64, 0xFC7C95D827357AFA'u64, 0x18A6A990C8B35EBD'u64,
    0xCCCB7005C6B9C28D'u64, 0x3BDBB92C43B17F26'u64, 0xAA70B5B4F89695A2'u64, 0xE94C39A54A98307F'u64,
    0xB7A0B174CFF6F36E'u64, 0xD4DBA84729AF48AD'u64, 0x2E18BC1AD9704A68'u64, 0x2DE0966DAF2F8B1C'u64,
    0xB9C11D5B1E43A07E'u64, 0x64972D68DEE33360'u64, 0x94628D38D0C20584'u64, 0xDBC0D2B6AB90A559'u64,
    0xD2733C4335C6A72F'u64, 0x7E75D99D94A70F4D'u64, 0x6CED1983376FA72B'u64, 0x97FCAACBF030BC24'u64,
    0x7B77497B32503B12'u64, 0x8547EDDFB81CCB94'u64, 0x79999CDFF70902CB'u64, 0xCFFE1939438E9B24'u64,
    0x829626E3892D95D7'u64, 0x92FAE24291F2B3F1'u64, 0x63E22C147B9C3403'u64, 0xC678B6D860284A1C'u64,
    0x5873888850659AE7'u64, 0x0981DCD296A8736D'u64, 0x9F65789A6509A440'u64, 0x9FF38FED72E9052F'u64,
    0xE479EE5B9930578C'u64, 0xE7F28ECD2D49EECD'u64, 0x56C074A581EA17FE'u64, 0x5544F7D774B14AEF'u64,
    0x7B3F0195FC6F290F'u64, 0x12153635B2C0CF57'u64, 0x7F5126DBBA5E0CA7'u64, 0x7A76956C3EAFB413'u64,
    0x3D5774A11D31AB39'u64, 0x8A1B083821F40CB4'u64, 0x7B4A38E32537DF62'u64, 0x950113646D1D6E03'u64,
    0x4DA8979A0041E8A9'u64, 0x3BC36E078F7515D7'u64, 0x5D0A12F27AD310D1'u64, 0x7F9D1A2E1EBE1327'u64,
    0xDA3A361B1C5157B1'u64, 0xDCDD7D20903D0C25'u64, 0x36833336D068F707'u64, 0xCE68341F79893389'u64,
    0xAB9090168DD05F34'u64, 0x43954B3252DC25E5'u64, 0xB438C2B67F98E5E9'u64, 0x10DCD78E3851A492'u64,
    0xDBC27AB5447822BF'u64, 0x9B3CDB65F82CA382'u64, 0xB67B7896167B4C84'u64, 0xBFCED1B0048EAC50'u64,
    0xA9119B60369FFEBD'u64, 0x1FFF7AC80904BF45'u64, 0xAC12FB171817EEE7'u64, 0xAF08DA9177DDA93D'u64,
    0x1B0CAB936E65C744'u64, 0xB559EB1D04E5E932'u64, 0xC37B45B3F8D6F2BA'u64, 0xC3A9DC228CAAC9E9'u64,
    0xF3B8B6675A6507FF'u64, 0x9FC477DE4ED681DA'u64, 0x67378D8ECCEF96CB'u64, 0x6DD856D94D259236'u64,
    0xA319CE15B0B4DB31'u64, 0x073973751F12DD5E'u64, 0x8A8E849EB32781A5'u64, 0xE1925C71285279F5'u64,
    0x74C04BF1790C0EFE'u64, 0x4DDA48153C94938A'u64, 0x9D266D6A1CC0542C'u64, 0x7440FB816508C4FE'u64,
    0x13328503DF48229F'u64, 0xD6BF7BAEE43CAC40'u64, 0x4838D65F6EF6748F'u64, 0x1E152328F3318DEA'u64,
    0x8F8419A348F296BF'u64, 0x72C8834A5957B511'u64, 0xD7A023A73260B45C'u64, 0x94EBC8ABCFB56DAE'u64,
    0x9FC10D0F989993E0'u64, 0xDE68A2355B93CAE6'u64, 0xA44CFE79AE538BBE'u64, 0x9D1D84FCCE371425'u64,
    0x51D2B1AB2DDFB636'u64, 0x2FD7E4B9E72CD38C'u64, 0x65CA5B96B7552210'u64, 0xDD69A0D8AB3B546D'u64,
    0x604D51B25FBF70E2'u64, 0x73AA8A564FB7AC9E'u64, 0x1A8C1E992B941148'u64, 0xAAC40A2703D9BEA0'u64,
    0x764DBEAE7FA4F3A6'u64, 0x1E99B96E70A9BE8B'u64, 0x2C5E9DEB57EF4743'u64, 0x3A938FEE32D29981'u64,
    0x26E6DB8FFDF5ADFE'u64, 0x469356C504EC9F9D'u64, 0xC8763C5B08D1908C'u64, 0x3F6C6AF859D80055'u64,
    0x7F7CC39420A3A545'u64, 0x9BFB227EBDF4C5CE'u64, 0x89039D79D6FC5C5C'u64, 0x8FE88B57305E2AB6'u64,
    0xA09E8C8C35AB96DE'u64, 0xFA7E393983325753'u64, 0xD6B6D0ECC617C699'u64, 0xDFEA21EA9E7557E3'u64,
    0xB67C1FA481680AF8'u64, 0xCA1E3785A9E724E5'u64, 0x1CFC8BED0D681639'u64, 0xD18D8549D140CAEA'u64,
    0x4ED0FE7E9DC91335'u64, 0xE4DBF0634473F5D2'u64, 0x1761F93A44D5AEFE'u64, 0x53898E4C3910DA55'u64,
    0x734DE8181F6EC39A'u64, 0x2680B122BAA28D97'u64, 0x298AF231C85BAFAB'u64, 0x7983EED3740847D5'u64,
    0x66C1A2A1A60CD889'u64, 0x9E17E49642A3E4C1'u64, 0xEDB454E7BADC0805'u64, 0x50B704CAB602C329'u64,
    0x4CC317FB9CDDD023'u64, 0x66B4835D9EAFEA22'u64, 0x219B97E26FFC81BD'u64, 0x261E4E4C0A333A9D'u64,
    0x1FE2CCA76517DB90'u64, 0xD7504DFA8816EDBB'u64, 0xB9571FA04DC089C8'u64, 0x1DDC0325259B27DE'u64,
    0xCF3F4688801EB9AA'u64, 0xF4F5D05C10CAB243'u64, 0x38B6525C21A42B0E'u64, 0x36F60E2BA4FA6800'u64,
    0xEB3593803173E0CE'u64, 0x9C4CD6257C5A3603'u64, 0xAF0C317D32ADAA8A'u64, 0x258E5A80C7204C4B'u64,
    0x8B889D624D44885D'u64, 0xF4D14597E660F855'u64, 0xD4347F66EC8941C3'u64, 0xE699ED85B0DFB40D'u64,
    0x2472F6207C2D0484'u64, 0xC2A1E7B5B459AEB5'u64, 0xAB4F6451CC1D45EC'u64, 0x63767572AE3D6174'u64,
    0xA59E0BD101731A28'u64, 0x116D0016CB948F09'u64, 0x2CF9C8CA052F6E9F'u64, 0x0B090A7560A968E3'u64,
    0xABEEDDB2DDE06FF1'u64, 0x58EFC10B06A2068D'u64, 0xC6E57A78FBD986E0'u64, 0x2EAB8CA63CE802D7'u64,
    0x14A195640116F336'u64, 0x7C0828DD624EC390'u64, 0xD74BBE77E6116AC7'u64, 0x804456AF10F5FB53'u64,
    0xEBE9EA2ADF4321C7'u64, 0x03219A39EE587A30'u64, 0x49787FEF17AF9924'u64, 0xA1E9300CD8520548'u64,
    0x5B45E522E4B1B4EF'u64, 0xB49C3B3995091A36'u64, 0xD4490AD526F14431'u64, 0x12A8F216AF9418C2'u64,
    0x001F837CC7350524'u64, 0x1877B51E57A764D5'u64, 0xA2853B80F17F58EE'u64, 0x993E1DE72D36D310'u64,
    0xB3598080CE64A656'u64, 0x252F59CF0D9F04BB'u64, 0xD23C8E176D113600'u64, 0x1BDA0492E7E4586E'u64,
    0x21E0BD5026C619BF'u64, 0x3B097ADAF088F94E'u64, 0x8D14DEDB30BE846E'u64, 0xF95CFFA23AF5F6F4'u64,
    0x3871700761B3F743'u64, 0xCA672B91E9E4FA16'u64, 0x64C8E531BFF53B55'u64, 0x241260ED4AD1E87D'u64,
    0x106C09B972D2E822'u64, 0x7FBA195410E5CA30'u64, 0x7884D9BC6CB569D8'u64, 0x0647DFEDCD894A29'u64,
    0x63573FF03E224774'u64, 0x4FC8E9560F91B123'u64, 0x1DB956E450275779'u64, 0xB8D91274B9E9D4FB'u64,
    0xA2EBEE47E2FBFCE1'u64, 0xD9F1F30CCD97FB09'u64, 0xEFED53D75FD64E6B'u64, 0x2E6D02C36017F67F'u64,
    0xA9AA4D20DB084E9B'u64, 0xB64BE8D8B25396C1'u64, 0x70CB6AF7C2D5BCF0'u64, 0x98F076A4F7A2322E'u64,
    0xBF84470805E69B5F'u64, 0x94C3251F06F90CF3'u64, 0x3E003E616A6591E9'u64, 0xB925A6CD0421AFF3'u64,
    0x61BDD1307C66E300'u64, 0xBF8D5108E27E0D48'u64, 0x240AB57A8B888B20'u64, 0xFC87614BAF287E07'u64,
    0xEF02CDD06FFDB432'u64, 0xA1082C0466DF6C0A'u64, 0x8215E577001332C8'u64, 0xD39BB9C3A48DB6CF'u64,
    0x2738259634305C14'u64, 0x61CF4F94C97DF93D'u64, 0x1B6BACA2AE4E125B'u64, 0x758F450C88572E0B'u64,
    0x959F587D507A8359'u64, 0xB063E962E045F54D'u64, 0x60E8ED72C0DFF5D1'u64, 0x7B64978555326F9F'u64,
    0xFD080D236DA814BA'u64, 0x8C90FD9B083F4558'u64, 0x106F72FE81E2C590'u64, 0x7976033A39F7D952'u64,
    0xA4EC0132764CA04B'u64, 0x733EA705FAE4FA77'u64, 0xB4D8F77BC3E56167'u64, 0x9E21F4F903B33FD9'u64,
    0x9D765E419FB69F6D'u64, 0xD30C088BA61EA5EF'u64, 0x5D94337FBFAF7F5B'u64, 0x1A4E4822EB4D7A59'u64,
    0x6FFE73E81B637FB3'u64, 0xDDF957BC36D8B9CA'u64, 0x64D0E29EEA8838B3'u64, 0x08DD9BDFD96B9F63'u64,
    0x087E79E5A57D1D13'u64, 0xE328E230E3E2B3FB'u64, 0x1C2559E30F0946BE'u64, 0x720BF5F26F4D2EAA'u64,
    0xB0774D261CC609DB'u64, 0x443F64EC5A371195'u64, 0x4112CF68649A260E'u64, 0xD813F2FAB7F5C5CA'u64,
    0x660D3257380841EE'u64, 0x59AC2C7873F910A3'u64, 0xE846963877671A17'u64, 0x93B633ABFA3469F8'u64,
    0xC0C0F5A60EF4CDCF'u64, 0xCAF21ECD4377B28C'u64, 0x57277707199B8175'u64, 0x506C11B9D90E8B1D'u64,
    0xD83CC2687A19255F'u64, 0x4A29C6465A314CD1'u64, 0xED2DF21216235097'u64, 0xB5635C95FF7296E2'u64,
    0x22AF003AB672E811'u64, 0x52E762596BF68235'u64, 0x9AEBA33AC6ECC6B0'u64, 0x944F6DE09134DFB6'u64,
    0x6C47BEC883A7DE39'u64, 0x6AD047C430A12104'u64, 0xA5B1CFDBA0AB4067'u64, 0x7C45D833AFF07862'u64,
    0x5092EF950A16DA0B'u64, 0x9338E69C052B8E7B'u64, 0x455A4B4CFE30E3F5'u64, 0x6B02E63195AD0CF8'u64,
    0x6B17B224BAD6BF27'u64, 0xD1E0CCD25BB9C169'u64, 0xDE0C89A556B9AE70'u64, 0x50065E535A213CF6'u64,
    0x9C1169FA2777B874'u64, 0x78EDEFD694AF1EED'u64, 0x6DC93D9526A50E68'u64, 0xEE97F453F06791ED'u64,
    0x32AB0EDB696703D3'u64, 0x3A6853C7E70757A7'u64, 0x31865CED6120F37D'u64, 0x67FEF95D92607890'u64,
    0x1F2B1D1F15F6DC9C'u64, 0xB69E38A8965C6B65'u64, 0xAA9119FF184CCCF4'u64, 0xF43C732873F24C13'u64,
    0xFB4A3D794A9A80D2'u64, 0x3550C2321FD6109C'u64, 0x371F77E76BB8417E'u64, 0x6BFA9AAE5EC05779'u64,
    0xCD04F3FF001A4778'u64, 0xE3273522064480CA'u64, 0x9F91508BFFCFC14A'u64, 0x049A7F41061A9E60'u64,
    0xFCB6BE43A9F2FE9B'u64, 0x08DE8A1C7797DA9B'u64, 0x8F9887E6078735A1'u64, 0xB5B4071DBFC73A66'u64,
    0x230E343DFBA08D33'u64, 0x43ED7F5A0FAE657D'u64, 0x3A88A0FBBCB05C63'u64, 0x21874B8B4D2DBC4F'u64,
    0x1BDEA12E35F6A8C9'u64, 0x53C065C6C8E63528'u64, 0xE34A1D250E7A8D6B'u64, 0xD6B04D3B7651DD7E'u64,
    0x5E90277E7CB39E2D'u64, 0x2C046F22062DC67D'u64, 0xB10BB459132D0A26'u64, 0x3FA9DDFB67E2F199'u64,
    0x0E09B88E1914F7AF'u64, 0x10E8B35AF3EEAB37'u64, 0x9EEDECA8E272B933'u64, 0xD4C718BC4AE8AE5F'u64,
    0x81536D601170FC20'u64, 0x91B534F885818A06'u64, 0xEC8177F83F900978'u64, 0x190E714FADA5156E'u64,
    0xB592BF39B0364963'u64, 0x89C350C893AE7DC1'u64, 0xAC042E70F8B383F2'u64, 0xB49B52E587A1EE60'u64,
    0xFB152FE3FF26DA89'u64, 0x3E666E6F69AE2C15'u64, 0x3B544EBE544C19F9'u64, 0xE805A1E290CF2456'u64,
    0x24B33C9D7ED25117'u64, 0xE74733427B72F0C1'u64, 0x0A804D18B7097475'u64, 0x57E3306D881EDB4F'u64,
    0x4AE7D6A36EB5DBCB'u64, 0x2D8D5432157064C8'u64, 0xD1E649DE1E7F268B'u64, 0x8A328A1CEDFE552C'u64,
    0x07A3AEC79624C7DA'u64, 0x84547DDC3E203C94'u64, 0x990A98FD5071D263'u64, 0x1A4FF12616EEFC89'u64,
    0xF6F7FD1431714200'u64, 0x30C05B1BA332F41C'u64, 0x8D2636B81555A786'u64, 0x46C9FEB55D120902'u64,
    0xCCEC0A73B49C9921'u64, 0x4E9D2827355FC492'u64, 0x19EBB029435DCB0F'u64, 0x4659D2B743848A2C'u64,
    0x963EF2C96B33BE31'u64, 0x74F85198B05A2E7D'u64, 0x5A0F544DD2B1FB18'u64, 0x03727073C2E134B1'u64,
    0xC7F6AA2DE59AEA61'u64, 0x352787BAA0D7C22F'u64, 0x9853EAB63B5E0B35'u64, 0xABBDCDD7ED5C0860'u64,
    0xCF05DAF5AC8D77B0'u64, 0x49CAD48CEBF4A71E'u64, 0x7A4C10EC2158C4A6'u64, 0xD9E92AA246BF719E'u64,
    0x13AE978D09FE5557'u64, 0x730499AF921549FF'u64, 0x4E4B705B92903BA4'u64, 0xFF577222C14F0A3A'u64,
    0x55B6344CF97AAFAE'u64, 0xB862225B055B6960'u64, 0xCAC09AFBDDD2CDB4'u64, 0xDAF8E9829FE96B5F'u64,
    0xB5FDFC5D3132C498'u64, 0x310CB380DB6F7503'u64, 0xE87FBB46217A360E'u64, 0x2102AE466EBB1148'u64,
    0xF8549E1A3AA5E00D'u64, 0x07A69AFDCC42261A'u64, 0xC4C118BFE78FEAAE'u64, 0xF9F4892ED96BD438'u64,
    0x1AF3DBE25D8F45DA'u64, 0xF5B4B0B0D2DEEEB4'u64, 0x962ACEEFA82E1C84'u64, 0x046E3ECAAF453CE9'u64,
    0xF05D129681949A4C'u64, 0x964781CE734B3C84'u64, 0x9C2ED44081CE5FBD'u64, 0x522E23F3925E319E'u64,
    0x177E00F9FC32F791'u64, 0x2BC60A63A6F3B3F2'u64, 0x222BBFAE61725606'u64, 0x486289DDCC3D6780'u64,
    0x7DC7785B8EFDFC80'u64, 0x8AF38731C02BA980'u64, 0x1FAB64EA29A2DDF7'u64, 0xE4D9429322CD065A'u64,
    0x9DA058C67844F20C'u64, 0x24C0E332B70019B0'u64, 0x233003B5A6CFE6AD'u64, 0xD586BD01C5C217F6'u64,
    0x5E5637885F29BC2B'u64, 0x7EBA726D8C94094B'u64, 0x0A56A5F0BFE39272'u64, 0xD79476A84EE20D06'u64,
    0x9E4C1269BAA4BF37'u64, 0x17EFEE45B0DEE640'u64, 0x1D95B0A5FCF90BC6'u64, 0x93CBE0B699C2585D'u64,
    0x65FA4F227A2B6D79'u64, 0xD5F9E858292504D5'u64, 0xC2B5A03F71471A6F'u64, 0x59300222B4561E00'u64,
    0xCE2F8642CA0712DC'u64, 0x7CA9723FBB2E8988'u64, 0x2785338347F2BA08'u64, 0xC61BB3A141E50E8C'u64,
    0x150F361DAB9DEC26'u64, 0x9F6A419D382595F4'u64, 0x64A53DC924FE7AC9'u64, 0x142DE49FFF7A7C3D'u64,
    0x0C335248857FA9E7'u64, 0x0A9C32D5EAE45305'u64, 0xE6C42178C4BBB92E'u64, 0x71F1CE2490D20B07'u64,
    0xF1BCC3D275AFE51A'u64, 0xE728E8C83C334074'u64, 0x96FBF83A12884624'u64, 0x81A1549FD6573DA5'u64,
    0x5FA7867CAF35E149'u64, 0x56986E2EF3ED091B'u64, 0x917F1DD5F8886C61'u64, 0xD20D8C88C8FFE65F'u64,
  ]

  polyglotRandomCastle*: array[4, uint64] = [
    0x31D71DCE64B2C310'u64, # polyglotRandom[768] (white kingside)
    0xF165B587DF898190'u64, # polyglotRandom[769] (white queenside)
    0xA57E6339DD2CF3A0'u64, # polyglotRandom[770] (black kingside)
    0x1EF6E6DBB1961EC9'u64, # polyglotRandom[771] (black queenside)
  ]

  polyglotRandomEnpassant*: array[8, uint64] = [
    0x70CC73D90BC26E24'u64, # polyglotRandom[772 + A1]
    0xE21A6B35DF0C3AD7'u64, # polyglotRandom[772 + B1]
    0x003A93D8B2806962'u64, # polyglotRandom[772 + C1]
    0x1C99DED33CB890A1'u64, # polyglotRandom[772 + D1]
    0xCF3145DE0ADD4289'u64, # polyglotRandom[772 + E1]
    0xD0E4427A5514FB72'u64, # polyglotRandom[772 + F1]
    0x77C621CC9FB3A483'u64, # polyglotRandom[772 + G1]
    0x67A34DAC4356550B'u64, # polyglotRandom[772 + H1]
  ]

  polyglotRandomWhite* = 0xF8D626AAAF278509'u64 # polyglotRandom[780]

  # Nim 0.11.2 couldn't use some u64 literals issuing "Error: cannot convert -XXXXXX to uint64"
  # https:#github.com/Araq/Nim/issues/2731
  rookMagic*: array[64, Magic] = [
    (0x000101010101017E'u64, uint64(0xE580008110204000'u64)), (0x000202020202027C'u64, 0x0160002008011000'u64),
    (0x000404040404047A'u64, 0x3520080020000400'u64), (0x0008080808080876'u64, 0x6408080448002002'u64),
    (0x001010101010106E'u64, 0x1824080004020400'u64), (0x002020202020205E'u64, uint64(0x9E04088101020400'u64)),
    (0x004040404040403E'u64, uint64(0x8508008001000200'u64)), (0x008080808080807E'u64, 0x5A000040A4840201'u64),
    (0x0001010101017E00'u64, 0x0172800180504000'u64), (0x0002020202027C00'u64, 0x0094200020483000'u64),
    (0x0004040404047A00'u64, 0x0341400410000800'u64), (0x0008080808087600'u64, 0x007E040020041200'u64),
    (0x0010101010106E00'u64, 0x0042104404000800'u64), (0x0020202020205E00'u64, 0x00CC042090008400'u64),
    (0x0040404040403E00'u64, 0x00A88081000A0200'u64), (0x0080808080807E00'u64, 0x006C810180840100'u64),
    (0x00010101017E0100'u64, 0x0021150010208000'u64), (0x00020202027C0200'u64, 0x0000158060004000'u64),
    (0x00040404047A0400'u64, 0x0080BC2808402000'u64), (0x0008080808760800'u64, 0x00113E1000200800'u64),
    (0x00101010106E1000'u64, 0x0002510001010800'u64), (0x00202020205E2000'u64, 0x0008660814001200'u64),
    (0x00404040403E4000'u64, 0x0000760400408080'u64), (0x00808080807E8000'u64, 0x0004158180800300'u64),
    (0x000101017E010100'u64, 0x00C0826880004000'u64), (0x000202027C020200'u64, 0x0000803901002800'u64),
    (0x000404047A040400'u64, 0x0020005D88000400'u64), (0x0008080876080800'u64, 0x0000136A18001000'u64),
    (0x001010106E101000'u64, 0x0000053200100A00'u64), (0x002020205E202000'u64, 0x0004301AA0010400'u64),
    (0x004040403E404000'u64, 0x0001085C80048200'u64), (0x008080807E808000'u64, 0x000000BE04040100'u64),
    (0x0001017E01010100'u64, 0x0001042142401000'u64), (0x0002027C02020200'u64, 0x0140300036282000'u64),
    (0x0004047A04040400'u64, 0x0009802008801000'u64), (0x0008087608080800'u64, 0x0000201870841000'u64),
    (0x0010106E10101000'u64, 0x0002020926000A00'u64), (0x0020205E20202000'u64, 0x0004040078800200'u64),
    (0x0040403E40404000'u64, 0x0002000250900100'u64), (0x0080807E80808000'u64, 0x00008001B9800100'u64),
    (0x00017E0101010100'u64, 0x0240001090418000'u64), (0x00027C0202020200'u64, 0x0000100008334000'u64),
    (0x00047A0404040400'u64, 0x0060086000234800'u64), (0x0008760808080800'u64, 0x0088088011121000'u64),
    (0x00106E1010101000'u64, 0x000204000E1D2800'u64), (0x00205E2020202000'u64, 0x00020082002A0400'u64),
    (0x00403E4040404000'u64, 0x0006021050270A00'u64), (0x00807E8080808000'u64, 0x0000610002548080'u64),
    (0x007E010101010100'u64, 0x0401410280201A00'u64), (0x007C020202020200'u64, 0x0001408100104E00'u64),
    (0x007A040404040400'u64, 0x0020100980084480'u64), (0x0076080808080800'u64, 0x000A004808286E00'u64),
    (0x006E101010101000'u64, 0x0000100120024600'u64), (0x005E202020202000'u64, 0x0002000902008E00'u64),
    (0x003E404040404000'u64, 0x0001010800807200'u64), (0x007E808080808000'u64, 0x0002050400295A00'u64),
    (0x7E01010101010100'u64, 0x004100A080004257'u64), (0x7C02020202020200'u64, 0x000011008048C005'u64),
    (0x7A04040404040400'u64, uint64(0x8040441100086001'u64)), (0x7608080808080800'u64, uint64(0x8014400C02002066'u64)),
    (0x6E10101010101000'u64, 0x00080220010A010E'u64), (0x5E20202020202000'u64, 0x0002000810041162'u64),
    (0x3E40404040404000'u64, 0x00010486100110E4'u64), (0x7E80808080808000'u64, 0x000100020180406F'u64),
  ]

  bishopMagic*: array[64, Magic] = [
    (0x0040201008040200'u64, 0x00A08800240C0040'u64), (0x0000402010080400'u64, 0x0020085008088000'u64),
    (0x0000004020100A00'u64, 0x0080440306000000'u64), (0x0000000040221400'u64, 0x000C520480000000'u64),
    (0x0000000002442800'u64, 0x0024856000000000'u64), (0x0000000204085000'u64, 0x00091430A0000000'u64),
    (0x0000020408102000'u64, 0x0009081820C00000'u64), (0x0002040810204000'u64, 0x0005100400609000'u64),
    (0x0020100804020000'u64, 0x0000004448220400'u64), (0x0040201008040000'u64, 0x00001030010C0480'u64),
    (0x00004020100A0000'u64, 0x00003228120A0000'u64), (0x0000004022140000'u64, 0x00004C2082400000'u64),
    (0x0000000244280000'u64, 0x0000108D50000000'u64), (0x0000020408500000'u64, 0x0000128821100000'u64),
    (0x0002040810200000'u64, 0x00000A0410245000'u64), (0x0004081020400000'u64, 0x0000030180208800'u64),
    (0x0010080402000200'u64, 0x0050000820500C00'u64), (0x0020100804000400'u64, 0x0008010050180200'u64),
    (0x004020100A000A00'u64, 0x0150008A00200500'u64), (0x0000402214001400'u64, 0x000E000505090000'u64),
    (0x0000024428002800'u64, 0x0014001239200000'u64), (0x0002040850005000'u64, 0x0006000540186000'u64),
    (0x0004081020002000'u64, 0x0001000603502000'u64), (0x0008102040004000'u64, 0x0005000104480C00'u64),
    (0x0008040200020400'u64, 0x0011400048880200'u64), (0x0010080400040800'u64, 0x0008080020304800'u64),
    (0x0020100A000A1000'u64, 0x00241800B4000C00'u64), (0x0040221400142200'u64, 0x0020480010820040'u64),
    (0x0002442800284400'u64, 0x011484002E822000'u64), (0x0004085000500800'u64, 0x000C050044822000'u64),
    (0x0008102000201000'u64, 0x0010090020401800'u64), (0x0010204000402000'u64, 0x0004008004A10C00'u64),
    (0x0004020002040800'u64, 0x0044214001005000'u64), (0x0008040004081000'u64, 0x0008406000188200'u64),
    (0x00100A000A102000'u64, 0x0002043000120400'u64), (0x0022140014224000'u64, 0x0010280800120A00'u64),
    (0x0044280028440200'u64, 0x0040120A00802080'u64), (0x0008500050080400'u64, 0x0018282700021000'u64),
    (0x0010200020100800'u64, 0x0008400C00090C00'u64), (0x0020400040201000'u64, 0x0024200440050400'u64),
    (0x0002000204081000'u64, 0x004420104000A000'u64), (0x0004000408102000'u64, 0x0020085060000800'u64),
    (0x000A000A10204000'u64, 0x00090428D0011800'u64), (0x0014001422400000'u64, 0x00000A6248002C00'u64),
    (0x0028002844020000'u64, 0x000140820A000400'u64), (0x0050005008040200'u64, 0x0140900848400200'u64),
    (0x0020002010080400'u64, 0x000890400C000200'u64), (0x0040004020100800'u64, 0x0008240492000080'u64),
    (0x0000020408102000'u64, 0x0010104980400000'u64), (0x0000040810204000'u64, 0x0001480810300000'u64),
    (0x00000A1020400000'u64, 0x0000060410A80000'u64), (0x0000142240000000'u64, 0x0000000270150000'u64),
    (0x0000284402000000'u64, 0x000000808C540000'u64), (0x0000500804020000'u64, 0x00002010202C8000'u64),
    (0x0000201008040200'u64, 0x0020A00810210000'u64), (0x0000402010080400'u64, 0x0080801804828000'u64),
    (0x0002040810204000'u64, 0x0002420010C09000'u64), (0x0004081020400000'u64, 0x0000080828180400'u64),
    (0x000A102040000000'u64, 0x0000000890285800'u64), (0x0014224000000000'u64, 0x0000000008234900'u64),
    (0x0028440200000000'u64, 0x00000000A0244500'u64), (0x0050080402000000'u64, 0x0000022080900300'u64),
    (0x0020100804020000'u64, 0x0000005002301100'u64), (0x0040201008040200'u64, 0x0080881014040040'u64),
  ]

echo "Hello from Data ", H8, ";-)"