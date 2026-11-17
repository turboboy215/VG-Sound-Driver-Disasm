; Driver RAM, WRAM $DF00-$DF3D (Zoop) (62 bytes; the game clears it and seeds the random byte with $47)

DEF wSndRandom     EQU $DF00 ; 1
DEF wSndUnused01   EQU $DF01 ; 1
DEF wSfxTranspose  EQU $DF02 ; 1
DEF wSfxTimer      EQU $DF03 ; 1
DEF wSfxPtr        EQU $DF04 ; 2
DEF wSfxWaitAdd    EQU $DF06 ; 1
DEF wSfxOwnCh1     EQU $DF07 ; 1
DEF wSfxOwnCh2     EQU $DF08 ; 1
DEF wSfxOwnCh3     EQU $DF09 ; 1
DEF wSfxOwnCh4     EQU $DF0A ; 1
DEF wSfxHighPri    EQU $DF0B ; 1
DEF wMusNumDefs    EQU $DF0C ; 1
DEF wMusDefs       EQU $DF0D ; 2
DEF wMusPtr        EQU $DF0F ; 2
DEF wMusTimer      EQU $DF11 ; 1
DEF wMusUnused12   EQU $DF12 ; 1
DEF wMusUnused13   EQU $DF13 ; 1
DEF wMusPaused     EQU $DF14 ; 1
DEF wMusWave       EQU $DF15 ; 1
DEF wVoice1        EQU $DF16 ; 6
DEF wVoice2        EQU $DF1C ; 6
DEF wVoice3        EQU $DF22 ; 6
DEF wVoice4        EQU $DF28 ; 6
DEF wChanProg      EQU $DF2E ; 16
