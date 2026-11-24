; Epoch sound driver type 2: register and RAM names.
; The including file defines SOUND_RAM first ($CC00 Ohasuta, $DF00 Doraemon,
; $CF00 Sylvanian). EQUs only.

DEF rNR10          EQU $FF10
DEF rNR11          EQU $FF11
DEF rNR12          EQU $FF12
DEF rNR13          EQU $FF13
DEF rNR14          EQU $FF14
DEF rNR21          EQU $FF16
DEF rNR22          EQU $FF17
DEF rNR23          EQU $FF18
DEF rNR24          EQU $FF19
DEF rNR30          EQU $FF1A
DEF rNR31          EQU $FF1B
DEF rNR32          EQU $FF1C
DEF rNR33          EQU $FF1D
DEF rNR34          EQU $FF1E
DEF rNR41          EQU $FF20
DEF rNR42          EQU $FF21
DEF rNR43          EQU $FF22
DEF rNR44          EQU $FF23
DEF rNR50          EQU $FF24
DEF rNR51          EQU $FF25
DEF rNR52          EQU $FF26
DEF _AUD3WAVERAM   EQU $FF30

DEF wMusicId               EQU SOUND_RAM + $00   ; music id; $FF = no music
DEF wSfxId                 EQU SOUND_RAM + $01   ; SFX id; $FF = no SFX
DEF wMusHdrHi              EQU SOUND_RAM + $02   ; Mus_Init scratch: song header pointer (big-endian)
DEF wMusHdrLo              EQU SOUND_RAM + $03
DEF wMusCh1Env             EQU SOUND_RAM + $04   ; ch1 instrument NR12 (envelope)
DEF wMusCh1RestNR14        EQU SOUND_RAM + $05   ; ch1 instrument byte 3: NR14 value written by $E0
DEF wMusCh2Env             EQU SOUND_RAM + $06   ; ch2 instrument NR22
DEF wMusCh2RestNR24        EQU SOUND_RAM + $07   ; ch2 instrument byte 2: NR24 value written by $E0
DEF wMusCh3Level           EQU SOUND_RAM + $08   ; ch3 instrument NR32 (output level)
DEF wMusCh3RestFlag        EQU SOUND_RAM + $09   ; ch3 instrument byte 1: <>0 = $E0 turns NR30 off
DEF wMusCh4NR42            EQU SOUND_RAM + $0A   ; ch4 drum entry: NR42
DEF wMusCh4NR43            EQU SOUND_RAM + $0B   ; ch4 drum entry: NR43
DEF wMusCh4NR44            EQU SOUND_RAM + $0C   ; ch4 drum entry: NR44 (| $80 on key-on)
DEF wMusCh1Count           EQU SOUND_RAM + $0D   ; frames left in the current row
DEF wMusCh2Count           EQU SOUND_RAM + $0E
DEF wMusCh3Count           EQU SOUND_RAM + $0F
DEF wMusCh4Count           EQU SOUND_RAM + $10
DEF wMusCh1FreqLo          EQU SOUND_RAM + $11   ; base frequency of the current note
DEF wMusCh1FreqHi          EQU SOUND_RAM + $12
DEF wMusCh2FreqLo          EQU SOUND_RAM + $13
DEF wMusCh2FreqHi          EQU SOUND_RAM + $14
DEF wMusCh3FreqLo          EQU SOUND_RAM + $15
DEF wMusCh3FreqHi          EQU SOUND_RAM + $16
DEF wMusCh1PtrHi           EQU SOUND_RAM + $17   ; track pointers, big-endian
DEF wMusCh1PtrLo           EQU SOUND_RAM + $18
DEF wMusCh2PtrHi           EQU SOUND_RAM + $19
DEF wMusCh2PtrLo           EQU SOUND_RAM + $1A
DEF wMusCh3PtrHi           EQU SOUND_RAM + $1B
DEF wMusCh3PtrLo           EQU SOUND_RAM + $1C
DEF wMusCh4PtrHi           EQU SOUND_RAM + $1D
DEF wMusCh4PtrLo           EQU SOUND_RAM + $1E
DEF wMusCh1LoopHi          EQU SOUND_RAM + $1F   ; loop points set by $FF $00, big-endian
DEF wMusCh1LoopLo          EQU SOUND_RAM + $20
DEF wMusCh2LoopHi          EQU SOUND_RAM + $21
DEF wMusCh2LoopLo          EQU SOUND_RAM + $22
DEF wMusCh3LoopHi          EQU SOUND_RAM + $23
DEF wMusCh3LoopLo          EQU SOUND_RAM + $24
DEF wMusCh4LoopHi          EQU SOUND_RAM + $25
DEF wMusCh4LoopLo          EQU SOUND_RAM + $26
DEF wMusCh1End             EQU SOUND_RAM + $27   ; track ended: ch1 $03, ch2 $0C, ch3 $30, ch4 $C0
DEF wMusCh2End             EQU SOUND_RAM + $28
DEF wMusCh3End             EQU SOUND_RAM + $29
DEF wMusCh4End             EQU SOUND_RAM + $2A
DEF wMusCh1ModMode         EQU SOUND_RAM + $2B   ; pitch modulation mode ($F2), 0 = off
DEF wMusCh2ModMode         EQU SOUND_RAM + $2C
DEF wMusCh3ModMode         EQU SOUND_RAM + $2D
DEF wMusCh1ModDelay        EQU SOUND_RAM + $2E   ; frames before modulation starts
DEF wMusCh2ModDelay        EQU SOUND_RAM + $2F
DEF wMusCh3ModDelay        EQU SOUND_RAM + $30
DEF wMusCh1ModDelayInit    EQU SOUND_RAM + $31
DEF wMusCh2ModDelayInit    EQU SOUND_RAM + $32
DEF wMusCh3ModDelayInit    EQU SOUND_RAM + $33
DEF wMusCh1ModCount        EQU SOUND_RAM + $34   ; modulation steps left
DEF wMusCh2ModCount        EQU SOUND_RAM + $35
DEF wMusCh3ModCount        EQU SOUND_RAM + $36
DEF wMusCh1ModCountInit    EQU SOUND_RAM + $37
DEF wMusCh2ModCountInit    EQU SOUND_RAM + $38
DEF wMusCh3ModCountInit    EQU SOUND_RAM + $39
DEF wMusCh1ModPtrHi        EQU SOUND_RAM + $3A   ; next modulation step, big-endian
DEF wMusCh1ModPtrLo        EQU SOUND_RAM + $3B
DEF wMusCh2ModPtrHi        EQU SOUND_RAM + $3C
DEF wMusCh2ModPtrLo        EQU SOUND_RAM + $3D
DEF wMusCh3ModPtrHi        EQU SOUND_RAM + $3E
DEF wMusCh3ModPtrLo        EQU SOUND_RAM + $3F
DEF wCh1Lock               EQU SOUND_RAM + $40   ; channel lock, shared: 0 music owns, 1 SFX owns, 2 music must restore
DEF wCh2Lock               EQU SOUND_RAM + $41
DEF wCh3Lock               EQU SOUND_RAM + $42
DEF wCh4Lock               EQU SOUND_RAM + $43
DEF wMusCh1InstHi          EQU SOUND_RAM + $44   ; current instrument entry, big-endian
DEF wMusCh1InstLo          EQU SOUND_RAM + $45
DEF wMusCh2InstHi          EQU SOUND_RAM + $46
DEF wMusCh2InstLo          EQU SOUND_RAM + $47
DEF wMusCh3InstHi          EQU SOUND_RAM + $48
DEF wMusCh3InstLo          EQU SOUND_RAM + $49
DEF wMusCh1Pan             EQU SOUND_RAM + $4A   ; last $F1 value: 0 both, 1 left only, 2 right only
DEF wMusCh2Pan             EQU SOUND_RAM + $4B
DEF wMusCh3Pan             EQU SOUND_RAM + $4C
DEF wMusCh4Pan             EQU SOUND_RAM + $4D
DEF wMusCh1ModBuf          EQU SOUND_RAM + $4E   ; 18 bytes: modulation steps copied by $F2
DEF wMusCh2ModBuf          EQU SOUND_RAM + $60   ; 18 bytes
DEF wMusCh3ModBuf          EQU SOUND_RAM + $72   ; 18 bytes ($72-$83)
DEF wSfxHdrHi              EQU SOUND_RAM + $85   ; Sfx_Init scratch: SFX header pointer (big-endian)
DEF wSfxHdrLo              EQU SOUND_RAM + $86
DEF wSfxCh1Env             EQU SOUND_RAM + $87   ; SFX copies of the music fields above
DEF wSfxCh1RestNR14        EQU SOUND_RAM + $88
DEF wSfxCh2Env             EQU SOUND_RAM + $89
DEF wSfxCh2RestNR24        EQU SOUND_RAM + $8A
DEF wSfxCh3Level           EQU SOUND_RAM + $8B
DEF wSfxCh3RestFlag        EQU SOUND_RAM + $8C
DEF wSfxCh4NR42            EQU SOUND_RAM + $8D
DEF wSfxCh4NR43            EQU SOUND_RAM + $8E
DEF wSfxCh4NR44            EQU SOUND_RAM + $8F
DEF wSfxCh1Count           EQU SOUND_RAM + $90
DEF wSfxCh2Count           EQU SOUND_RAM + $91
DEF wSfxCh3Count           EQU SOUND_RAM + $92
DEF wSfxCh4Count           EQU SOUND_RAM + $93
DEF wSfxCh1FreqLo          EQU SOUND_RAM + $94
DEF wSfxCh1FreqHi          EQU SOUND_RAM + $95
DEF wSfxCh2FreqLo          EQU SOUND_RAM + $96
DEF wSfxCh2FreqHi          EQU SOUND_RAM + $97
DEF wSfxCh3FreqLo          EQU SOUND_RAM + $98
DEF wSfxCh3FreqHi          EQU SOUND_RAM + $99
DEF wSfxCh1PtrHi           EQU SOUND_RAM + $9A
DEF wSfxCh1PtrLo           EQU SOUND_RAM + $9B
DEF wSfxCh2PtrHi           EQU SOUND_RAM + $9C
DEF wSfxCh2PtrLo           EQU SOUND_RAM + $9D
DEF wSfxCh3PtrHi           EQU SOUND_RAM + $9E
DEF wSfxCh3PtrLo           EQU SOUND_RAM + $9F
DEF wSfxCh4PtrHi           EQU SOUND_RAM + $A0
DEF wSfxCh4PtrLo           EQU SOUND_RAM + $A1
DEF wSfxCh1LoopHi          EQU SOUND_RAM + $A2
DEF wSfxCh1LoopLo          EQU SOUND_RAM + $A3
DEF wSfxCh2LoopHi          EQU SOUND_RAM + $A4
DEF wSfxCh2LoopLo          EQU SOUND_RAM + $A5
DEF wSfxCh3LoopHi          EQU SOUND_RAM + $A6
DEF wSfxCh3LoopLo          EQU SOUND_RAM + $A7
DEF wSfxCh4LoopHi          EQU SOUND_RAM + $A8
DEF wSfxCh4LoopLo          EQU SOUND_RAM + $A9
DEF wSfxCh1End             EQU SOUND_RAM + $AA
DEF wSfxCh2End             EQU SOUND_RAM + $AB
DEF wSfxCh3End             EQU SOUND_RAM + $AC
DEF wSfxCh4End             EQU SOUND_RAM + $AD
DEF wSfxCh1ModMode         EQU SOUND_RAM + $AE
DEF wSfxCh2ModMode         EQU SOUND_RAM + $AF
DEF wSfxCh3ModMode         EQU SOUND_RAM + $B0
DEF wSfxCh1ModDelay        EQU SOUND_RAM + $B1
DEF wSfxCh2ModDelay        EQU SOUND_RAM + $B2
DEF wSfxCh3ModDelay        EQU SOUND_RAM + $B3
DEF wSfxCh1ModDelayInit    EQU SOUND_RAM + $B4
DEF wSfxCh2ModDelayInit    EQU SOUND_RAM + $B5
DEF wSfxCh3ModDelayInit    EQU SOUND_RAM + $B6
DEF wSfxCh1ModCount        EQU SOUND_RAM + $B7
DEF wSfxCh2ModCount        EQU SOUND_RAM + $B8
DEF wSfxCh3ModCount        EQU SOUND_RAM + $B9
DEF wSfxCh1ModCountInit    EQU SOUND_RAM + $BA
DEF wSfxCh2ModCountInit    EQU SOUND_RAM + $BB
DEF wSfxCh3ModCountInit    EQU SOUND_RAM + $BC
DEF wSfxCh1ModPtrHi        EQU SOUND_RAM + $BD
DEF wSfxCh1ModPtrLo        EQU SOUND_RAM + $BE
DEF wSfxCh2ModPtrHi        EQU SOUND_RAM + $BF
DEF wSfxCh2ModPtrLo        EQU SOUND_RAM + $C0
DEF wSfxCh3ModPtrHi        EQU SOUND_RAM + $C1
DEF wSfxCh3ModPtrLo        EQU SOUND_RAM + $C2
DEF wSfxCh1ModBuf          EQU SOUND_RAM + $C3   ; 18 bytes
DEF wSfxCh2ModBuf          EQU SOUND_RAM + $D5   ; 18 bytes
DEF wSfxCh3ModBuf          EQU SOUND_RAM + $E7   ; 18 bytes ($E7-$F8; the last byte is wMusBusy in version C)
DEF wMusBusy               EQU SOUND_RAM + $F8   ; version C: 1 while Mus_Init runs, Mus_Update does nothing
DEF wSfxBusy               EQU SOUND_RAM + $F9   ; version C: 1 while Sfx_Init runs
DEF wMusEndPtrA            EQU SOUND_RAM + $FA   ; song header word 5, stored byte-swapped and never read
DEF wMusEndPtrB            EQU SOUND_RAM + $FB
DEF wSfxEndPtrA            EQU SOUND_RAM + $FC   ; SFX header word 5, same
DEF wSfxEndPtrB            EQU SOUND_RAM + $FD
DEF wMusCh4NoiseHi         EQU SOUND_RAM + $FE   ; current drum entry, big-endian
DEF wMusCh4NoiseLo         EQU SOUND_RAM + $FF
