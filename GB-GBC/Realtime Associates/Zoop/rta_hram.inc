; Driver RAM, HRAM $FF8A-$FFC7 (Star Wars - Super Return of the Jedi) (62 bytes; the game clears it and seeds the random byte with $47)

DEF hSndRandom     EQU $FF8A ; 1
DEF hSndUnused01   EQU $FF8B ; 1
DEF hSfxTranspose  EQU $FF8C ; 1
DEF hSfxTimer      EQU $FF8D ; 1
DEF hSfxPtr        EQU $FF8E ; 2
DEF hSfxWaitAdd    EQU $FF90 ; 1
DEF hSfxOwnCh1     EQU $FF91 ; 1
DEF hSfxOwnCh2     EQU $FF92 ; 1
DEF hSfxOwnCh3     EQU $FF93 ; 1
DEF hSfxOwnCh4     EQU $FF94 ; 1
DEF hSfxHighPri    EQU $FF95 ; 1
DEF hMusNumDefs    EQU $FF96 ; 1
DEF hMusDefs       EQU $FF97 ; 2
DEF hMusPtr        EQU $FF99 ; 2
DEF hMusTimer      EQU $FF9B ; 1
DEF hMusUnused12   EQU $FF9C ; 1
DEF hMusUnused13   EQU $FF9D ; 1
DEF hMusPaused     EQU $FF9E ; 1
DEF hMusWave       EQU $FF9F ; 1
DEF hVoice1        EQU $FFA0 ; 6
DEF hVoice2        EQU $FFA6 ; 6
DEF hVoice3        EQU $FFAC ; 6
DEF hVoice4        EQU $FFB2 ; 6
DEF hChanProg      EQU $FFB8 ; 16
