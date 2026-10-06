; Ghosts 'n Goblins sound test (GB, PD) - music/SFX data $4866-$5BD7

BlankVol:
    TB 255, $00 ; mute
    TLOOP BlankVol

BlankPattern:
    PATEND

FreqTable:
    dw $002C, $009C, $0106, $016B, $01C9, $0223, $0277, $02C6 ; C2-G2
    dw $0312, $0356, $039B, $03DA, $0416, $044E, $0483, $04B5 ; Gs2-Ds3
    dw $04E5, $0511, $053B, $0563, $0589, $05AC, $05CE, $05ED ; E3-B3
    dw $060A, $0627, $0642, $065B, $0672, $0689, $069E, $06B2 ; C4-G4
    dw $06C4, $06D6, $06E7, $06F7, $0706, $0714, $0721, $072D ; Gs4-Ds5
    dw $0739, $0744, $074F, $0759, $0762, $076B, $0773, $077B ; E5-B5
    dw $0783, $078A, $0790, $0797, $079D, $07A2, $07A7, $07AC ; C6-G6
    dw $07B1, $07B6, $07BA, $07BE, $07C1, $07C4, $07C8, $07CB ; Gs6-Ds7
    dw $07CE, $07D1, $07D4, $07D6, $07D9, $07DB, $07DD, $07DF ; E7-B7

SfxTable:
    dw Sfx00
    db 2 ; ch2, Thrw weapn  (SFX $00)
    dw Sfx01
    db 2 ; ch2, Obj Appear  (SFX $01)
    dw Sfx02
    db 2 ; ch2, KillEnemy1  (SFX $02)
    dw Sfx03
    db 2 ; ch2, Pickup 1  (SFX $03)
    dw Sfx04
    db 2 ; ch2, Player hit  (SFX $04)
    dw Sfx05
    db 3 ; ch4, Weap expld  (SFX $05)
    dw Sfx06
    db 3 ; ch4, Kill Devil  (SFX $06)
    dw Sfx07
    db 3 ; ch4, Intro Bang  (SFX $07)
    dw Sfx08
    db 2 ; ch2, EnemyFire1  (SFX $08)
    dw Sfx09
    db 3 ; ch4, EnemyFire2  (SFX $09)
    dw Sfx0A
    db 2 ; ch2, KillEnemy2  (SFX $0A)
    dw Sfx0B
    db 2 ; ch2, Pickup 2  (SFX $0B)

SongTable:
    ; song $00: Music off
    dw Song00_Ch1, Song00_Ch2, Song00_Ch3, Song00_Ch4
    db 3 ; tempo (frames per tick)
    dw Morph_5A5D - 2 ; wave morph
    dw Wave_5A3D ; wave
    ; song $01: Levels 1&2
    dw Song01_Ch1, Song01_Ch2, Song01_Ch3, Song01_Ch4
    db 10 ; tempo (frames per tick)
    dw Morph_5A5D - 2 ; wave morph
    dw Wave_5A3D ; wave
    ; song $02: Levels 3&4
    dw Song02_Ch1, Song02_Ch2, Song02_Ch3, Song02_Ch4
    db 10 ; tempo (frames per tick)
    dw Morph_5B14 - 2 ; wave morph
    dw Wave_5A4D ; wave
    ; song $03: Levels 5&6
    dw Song03_Ch1, Song03_Ch2, Song03_Ch3, Song03_Ch4
    db 9 ; tempo (frames per tick)
    dw Morph_5A5D - 2 ; wave morph
    dw Wave_5A3D ; wave
    ; song $04: Level 7
    dw Song04_Ch1, Song04_Ch2, Song04_Ch3, Song04_Ch4
    db 5 ; tempo (frames per tick)
    dw Morph_5A5D - 2 ; wave morph
    dw Wave_5A3D ; wave
    ; song $05: Intro pt 1
    dw Song05_Ch1, Song05_Ch2, Song05_Ch3, Song05_Ch4
    db 7 ; tempo (frames per tick)
    dw Morph_5A5D - 2 ; wave morph
    dw Wave_5A3D ; wave
    ; song $06: Intro pt 2
    dw Song06_Ch1, Song06_Ch2, Song06_Ch3, Song06_Ch4
    db 1 ; tempo (frames per tick)
    dw Morph_5B14 - 2 ; wave morph
    dw Wave_5A4D ; wave
    ; song $07: Strt level
    dw Song07_Ch1, Song07_Ch2, Song07_Ch3, Song07_Ch4
    db 1 ; tempo (frames per tick)
    dw Morph_5B14 - 2 ; wave morph
    dw Wave_5A4D ; wave
    ; song $08: Lose life
    dw Song08_Ch1, Song08_Ch2, Song08_Ch3, Song08_Ch4
    db 4 ; tempo (frames per tick)
    dw Morph_5B14 - 2 ; wave morph
    dw Wave_5A4D ; wave
    ; song $09: Game over
    dw Song09_Ch1, Song09_Ch2, Song09_Ch3, Song09_Ch4
    db 4 ; tempo (frames per tick)
    dw Morph_5B14 - 2 ; wave morph
    dw Wave_5A4D ; wave
    ; song $0A: Win level
    dw Song10_Ch1, Song10_Ch2, Song10_Ch3, Song10_Ch4
    db 4 ; tempo (frames per tick)
    dw Morph_5A5D - 2 ; wave morph
    dw Wave_5A3D ; wave

PatternTable:
    dw Pat000                   ; $00
    dw Pat001                   ; $01
    dw Pat002                   ; $02
    dw Pat003                   ; $03
    dw Pat004                   ; $04
    dw Pat005                   ; $05
    dw Pat006                   ; $06
    dw Pat007                   ; $07
    dw Pat008                   ; $08
    dw Pat009                   ; $09
    dw Pat010                   ; $0A
    dw Pat011                   ; $0B
    dw Pat012                   ; $0C
    dw Pat013                   ; $0D
    dw Pat014                   ; $0E
    dw Pat015                   ; $0F
    dw Pat016                   ; $10
    dw Pat017                   ; $11
    dw Pat018                   ; $12
    dw Pat019                   ; $13
    dw Pat020                   ; $14
    dw Pat021                   ; $15
    dw Pat022                   ; $16
    dw Pat023                   ; $17
    dw Pat024                   ; $18
    dw Pat025                   ; $19
    dw Pat026                   ; $1A
    dw Pat027                   ; $1B
    dw Pat028                   ; $1C
    dw Pat029                   ; $1D
    dw Pat030                   ; $1E
    dw Pat031                   ; $1F
    dw Pat032                   ; $20
    dw Pat033                   ; $21
    dw Pat034                   ; $22
    dw Pat035                   ; $23
    dw Pat036                   ; $24
    dw Pat037                   ; $25
    dw Pat038                   ; $26
    dw Pat039                   ; $27
    dw Pat040                   ; $28
    dw Pat041                   ; $29
    dw Pat042                   ; $2A
    dw Pat043                   ; $2B
    dw Pat044                   ; $2C
    dw Pat045                   ; $2D
    dw Pat046                   ; $2E
    dw Pat047                   ; $2F
    dw Pat048                   ; $30
    dw Pat049                   ; $31
    dw Pat050                   ; $32
    dw Pat051                   ; $33
    dw Pat052                   ; $34
    dw Pat053                   ; $35
    dw Pat054                   ; $36
    dw Pat055                   ; $37
    dw Pat056                   ; $38
    dw Pat057                   ; $39
    dw Pat058                   ; $3A
    dw Pat059                   ; $3B
    dw Pat060                   ; $3C
    dw Pat061                   ; $3D
    dw Pat062                   ; $3E
    dw Pat063                   ; $3F
    dw Pat064                   ; $40
    dw Pat065                   ; $41
    dw Pat066                   ; $42
    dw Pat067                   ; $43
    dw Pat068                   ; $44
    dw Pat069                   ; $45
    dw Pat070                   ; $46
    dw Pat071                   ; $47
    dw Pat072                   ; $48
    dw Pat073                   ; $49
    dw Pat074                   ; $4A
    dw Pat075                   ; $4B
    dw Pat076                   ; $4C
    dw Pat077                   ; $4D
    dw Pat078                   ; $4E
    dw Pat079                   ; $4F
    dw Pat080                   ; $50
    dw Pat081                   ; $51
    dw Pat082                   ; $52
    dw Pat083                   ; $53
    dw Pat084                   ; $54
    dw Pat085                   ; $55
    dw Pat086                   ; $56
    dw Pat087                   ; $57
    dw Pat088                   ; $58
    dw Pat089                   ; $59
    dw Pat090                   ; $5A
    dw Pat091                   ; $5B
    dw Pat092                   ; $5C
    dw Pat093                   ; $5D
    dw Pat094                   ; $5E
    dw Pat095                   ; $5F
    dw Pat096                   ; $60
    dw Pat097                   ; $61
    dw Pat098                   ; $62
    dw Pat099                   ; $63
    dw Pat100                   ; $64
    dw Pat101                   ; $65
    dw Pat102                   ; $66
    dw Pat103                   ; $67

InstrumentTable:
    dw Ins00                    ; $00
    dw Ins01                    ; $01
    dw Ins02                    ; $02
    dw Ins03                    ; $03
    dw Ins04                    ; $04
    dw Ins05                    ; $05
    dw Ins06                    ; $06
    dw Ins07                    ; $07
    dw Ins08                    ; $08
    dw Ins09                    ; $09
    dw Ins10                    ; $0A
    dw Ins11                    ; $0B
    dw Ins12                    ; $0C
    dw Ins13                    ; $0D
    dw Ins14                    ; $0E
    dw Ins15                    ; $0F
    dw Ins16                    ; $10
    dw Ins17                    ; $11
    dw Ins18                    ; $12
    dw Ins19                    ; $13
    dw Ins20                    ; $14
    dw Ins21                    ; $15
    dw Ins22                    ; $16
    dw Ins23                    ; $17

NoiseInstrumentTable:
    dw NoiseIns00               ; $00
    dw NoiseIns01               ; $01
    dw NoiseIns02               ; $02
    dw NoiseIns03               ; $03
    dw NoiseIns04               ; $04

Song05_Ch1_Loop:
    STEP 0, $1C

Song00_Ch1:
    STEP 0, $65

Song00_Ch2:
    STEP 0, $65

Song00_Ch3:
    STEP 0, $66

Song00_Ch4:
    STEP 0, $67

Song01_Ch1:
    STEP 0, $01
    STEP 0, $02
    STEP 0, $01
    STEP 0, $02
    STEP 0, $03
    STEP 0, $04
    STEP 0, $05
    STEP 0, $06
    STEP 0, $07
    STEP 0, $08
    STEP 0, $09
    STEP 0, $0A

Song01_Ch2:
    STEP 0, $14
    STEP 0, $15
    STEP 0, $14
    STEP 0, $15
    STEP 0, $16
    STEP 0, $17
    STEP 0, $18
    STEP 0, $19
    STEP 0, $1A
    STEP -1, $1A
    STEP 3, $1A
    STEP 0, $1B

Song01_Ch3:
    STEP 0, $0B
    STEP 0, $0C
    STEP 0, $0B
    STEP 0, $0C
    STEP 0, $0D
    STEP 0, $0D
    STEP 0, $0E
    STEP 0, $0F
    STEP 0, $10
    STEP 0, $11
    STEP 0, $12
    STEP 0, $13

Song01_Ch4:
    STEP 0, $67

Song02_Ch3:
    STEP 0, $1D
    STEP 0, $1D
    STEP 5, $1D
    STEP 5, $1D
    STEP 0, $1D
    STEP 0, $1E
    STEP 0, $1F
    STEP 0, $1E
    STEP 0, $1D
    STEP 0, $1D
    STEP 5, $1D
    STEP 5, $31

Song02_Ch1:
    STEP 0, $20
    STEP 0, $21
    STEP 0, $20
    STEP 0, $22
    STEP 0, $23
    STEP 0, $24
    STEP 0, $25
    STEP 0, $26
    STEP 12, $20
    STEP 12, $21
    STEP 12, $20
    STEP 0, $27

Song02_Ch2:
    STEP 0, $28
    STEP 0, $29
    STEP 0, $2A
    STEP 0, $2B
    STEP 0, $2C
    STEP 0, $2D
    STEP 0, $2E
    STEP 0, $2F
    STEP 12, $28
    STEP 12, $29
    STEP 12, $2A
    STEP 0, $30

Song02_Ch4:
    STEP 0, $67

Song03_Ch1:
    STEP 0, $38
    STEP 0, $38
    STEP 5, $38
    STEP 5, $38
    STEP 7, $38
    STEP 8, $38
    STEP 7, $38
    STEP 0, $39

Song03_Ch2:
    STEP 0, $3A
    STEP 0, $3A
    STEP 5, $3A
    STEP 5, $3A
    STEP 0, $3B
    STEP 1, $3B
    STEP 0, $3C
    STEP 0, $3D

Song03_Ch3:
    STEP 0, $32
    STEP 0, $33
    STEP 5, $32
    STEP 5, $33
    STEP 0, $34
    STEP 0, $35
    STEP 0, $36
    STEP 0, $37

Song03_Ch4:
    STEP 0, $67

Song04_Ch1:
    STEP 0, $3E
    STEP 0, $3F
    STEP 0, $40
    STEP 0, $41
    STEP 0, $3E
    STEP 0, $3F
    STEP 0, $40
    STEP 0, $41
    STEP 2, $3E
    STEP 2, $3F
    STEP 2, $40
    STEP 2, $49

Song04_Ch2:
    STEP 0, $47
    STEP -1, $47
    STEP 0, $48
    STEP 0, $47
    STEP 0, $47
    STEP -1, $47
    STEP 0, $48
    STEP 0, $47
    STEP 2, $47
    STEP 1, $47
    STEP 2, $48
    STEP 2, $4A

Song04_Ch3:
    STEP 0, $42
    STEP 0, $43
    STEP 0, $44
    STEP 0, $45
    STEP 0, $42
    STEP 0, $43
    STEP 0, $44
    STEP 0, $45
    STEP 0, $46
    STEP 2, $43
    STEP 2, $44
    STEP 2, $4B

Song04_Ch4:
    STEP 0, $67

Song05_Ch1:
    STEP 0, $4C

Song05_Ch2:
    STEP 12, $4C

Song05_Ch3:
    STEP 0, $1C

Song05_Ch4:
    STEP 0, $67

Song06_Ch1:
    STEP 0, $4D
    STEP 0, $4E

Song06_Ch2:
    STEP 0, $4F
    STEP 0, $50

Song06_Ch3:
    STEP 0, $51
    STEP 0, $52

Song06_Ch4:
    STEP 0, $67

Song07_Ch1:
    STEP 0, $4E

Song07_Ch2:
    STEP 0, $50

Song07_Ch3:
    STEP 0, $52

Song07_Ch4:
    STEP 0, $67

Song08_Ch1:
    STEP 0, $53

Song08_Ch2:
    STEP 0, $54

Song08_Ch3:
    STEP -6, $55

Song08_Ch4:
    STEP 0, $67

Song09_Ch1:
    STEP 0, $56
    STEP -2, $56
    STEP 0, $58

Song09_Ch2:
    STEP 0, $57
    STEP -2, $57
    STEP 0, $59

Song09_Ch3:
    STEP 0, $5A

Song09_Ch4:
    STEP 0, $67

Song10_Ch1:
    STEP 0, $5B
    STEP 0, $5C
    STEP 0, $5D
    STEP 5, $5D
    STEP 0, $1C

Song10_Ch2:
    STEP 0, $5E
    STEP 0, $5F
    STEP 0, $60
    STEP 1, $60
    STEP 0, $1C

Song10_Ch3:
    STEP 12, $61
    STEP 12, $62
    STEP 12, $63
    STEP 0, $64
    STEP 0, $1C ; (dead: after the song jump)

Song10_Ch4:
    STEP 0, $67

Sfx00:
    NOTE 3, Gs5, $0E
    KEYOFF 1
    SFXEND

Sfx01:
    NOTE 4, Gs5, $0F
    KEYOFF 1
    SFXEND

Sfx02:
    NOTE 2, C5, $10
    NOTE 6, G5, $11
    SFXEND

Sfx0A:
    NOTE 1, G4, $10
    NOTE 3, G4, $11
    SFXEND

Sfx03:
    NOTE 3, Gs5, $12
    KEYOFF 1
    SFXEND

Sfx04:
    NOTE 2, C5, $13
    KEYOFF 2
    SFXEND

Sfx05:
    NOTE 10, $24, $00
    SFXEND

Sfx06:
    NOTE 10, $24, $01
    SFXEND

Sfx07:
    NOTE 12, $24, $02
    SFXEND

Sfx08:
    NOTE 3, C7, $14
    SFXEND

Sfx09:
    NOTE 3, $24, $03
    SFXEND

Sfx0B:
    NOTE 6, C5, $15
    SFXEND

Pat000:
    KEYOFF 16
    PATEND

Pat001:
    NOTE 1, A2, $01
    NOTE 1, C3, $01
    NOTE 1, E3, $01
    NOTE 1, E2, $01
    NOTE 1, A2, $01
    NOTE 1, E3, $01
    NOTE 2, E3, $01
    NOTE 1, A2, $01
    NOTE 1, C3, $01
    NOTE 1, E3, $01
    NOTE 1, E2, $01
    NOTE 1, A2, $01
    NOTE 1, E3, $01
    NOTE 2, E3, $01
    PATEND

Pat002:
    NOTE 1, Gs2, $01
    NOTE 1, B2, $01
    NOTE 1, E3, $01
    NOTE 1, E2, $01
    NOTE 1, Gs2, $01
    NOTE 1, E3, $01
    NOTE 2, E3, $01
    NOTE 1, Gs2, $01
    NOTE 1, B2, $01
    NOTE 1, E3, $01
    NOTE 1, E2, $01
    NOTE 1, Gs2, $01
    NOTE 1, E3, $01
    NOTE 2, E3, $01
    PATEND

Pat003:
    NOTE 1, A2, $01
    NOTE 1, C3, $01
    NOTE 1, E3, $01
    NOTE 1, E2, $01
    NOTE 1, A2, $01
    NOTE 1, C3, $01
    NOTE 1, E3, $01
    NOTE 1, E2, $01
    NOTE 1, A2, $01
    NOTE 1, D3, $01
    NOTE 1, F3, $01
    NOTE 1, D2, $01
    NOTE 1, A2, $01
    NOTE 1, D3, $01
    NOTE 1, F3, $01
    NOTE 1, D2, $01
    PATEND

Pat004:
    NOTE 1, A2, $01
    NOTE 1, F3, $01
    NOTE 1, A3, $01
    NOTE 1, D2, $01
    NOTE 1, A2, $01
    NOTE 1, F3, $01
    NOTE 1, A3, $01
    NOTE 1, D2, $01
    NOTE 1, A2, $01
    NOTE 1, F3, $01
    NOTE 1, A3, $01
    NOTE 1, Ds2, $01
    NOTE 1, A2, $01
    NOTE 1, F3, $01
    NOTE 1, A3, $01
    NOTE 1, Ds2, $01
    PATEND

Pat005:
    NOTE 1, B2, $01
    NOTE 1, B2, $01
    NOTE 2, B2, $01
    NOTE 1, Gs2, $01
    NOTE 1, B2, $01
    NOTE 1, E2, $01
    NOTE 1, E2, $01
    NOTE 1, B2, $01
    NOTE 1, B2, $01
    NOTE 2, B2, $01
    NOTE 1, A2, $01
    NOTE 1, C3, $01
    NOTE 1, E2, $01
    NOTE 1, E2, $01
    PATEND

Pat006:
    NOTE 1, Gs2, $01
    NOTE 1, Gs2, $01
    NOTE 4, Gs2, $01
    NOTE 1, Gs2, $01
    NOTE 1, Gs2, $01
    NOTE 1, E2, $01
    NOTE 1, E2, $01
    NOTE 1, F2, $01
    NOTE 1, Fs2, $01
    NOTE 1, G2, $01
    NOTE 1, Gs2, $01
    NOTE 1, A2, $01
    NOTE 1, B2, $01
    PATEND

Pat007:
    NOTE 2, A2, $01
    NOTE 1, E3, $01
    NOTE 2, E3, $01
    NOTE 1, A2, $01
    NOTE 1, E2, $01
    NOTE 1, E2, $01
    NOTE 2, A2, $01
    NOTE 1, E3, $01
    NOTE 2, E3, $01
    NOTE 1, A2, $01
    NOTE 1, E2, $01
    NOTE 1, E2, $01
    PATEND

Pat008:
    NOTE 2, Gs2, $01
    NOTE 1, B2, $01
    NOTE 2, B2, $01
    NOTE 1, Gs2, $01
    NOTE 1, E2, $01
    NOTE 1, E2, $01
    NOTE 2, Gs2, $01
    NOTE 1, B2, $01
    NOTE 2, B2, $01
    NOTE 1, Gs2, $01
    NOTE 1, E2, $01
    NOTE 1, E2, $01
    PATEND

Pat009:
    NOTE 2, F2, $01
    NOTE 1, A2, $01
    NOTE 2, A2, $01
    NOTE 1, F2, $01
    NOTE 1, F2, $01
    NOTE 1, F2, $01
    NOTE 2, F2, $01
    NOTE 1, A2, $01
    NOTE 2, A2, $01
    NOTE 1, F2, $01
    NOTE 1, F2, $01
    NOTE 1, F2, $01
    PATEND

Pat010:
    NOTE 2, Gs2, $01
    NOTE 1, B2, $01
    NOTE 2, B2, $01
    NOTE 1, Gs2, $01
    NOTE 1, Gs2, $01
    NOTE 1, Gs2, $01
    NOTE 1, D3, $01
    NOTE 1, D3, $01
    NOTE 1, D3, $01
    NOTE 1, D3, $01
    NOTE 1, D3, $01
    NOTE 1, D3, $01
    NOTE 2, B2, $01
    SONGJUMP Song01_Ch1

Pat011:
    KEYOFF 2
    NOTE 4, A5, $02
    NOTE 2, Gs5, $02
    NOTE 4, G5, $02
    NOTE 2, Fs5, $02
    NOTE 2, F5, $02
    PATEND

Pat012:
    NOTE 1, Ds5, $02
    NOTE 2, E5, $02
    NOTE 1, Ds5, $02
    NOTE 2, E5, $02
    NOTE 1, Ds5, $02
    NOTE 2, E5, $02
    NOTE 1, Ds4, $02
    NOTE 1, E4, $02
    NOTE 1, Ds4, $02
    NOTE 2, E4, $02
    NOTE 2, E4, $02
    PATEND

Pat013:
    NOTE 1, Gs5, $02
    NOTE 2, A5, $02
    NOTE 1, Gs5, $02
    NOTE 2, A5, $02
    KEYOFF 2
    NOTE 1, Gs5, $02
    NOTE 2, A5, $02
    NOTE 1, Gs5, $02
    NOTE 2, A5, $02
    KEYOFF 2
    PATEND

Pat014:
    NOTE 1, E5, $02
    NOTE 1, E5, $02
    NOTE 4, E5, $02
    NOTE 2, C6, $02
    NOTE 1, E5, $02
    NOTE 1, E5, $02
    NOTE 4, E5, $02
    NOTE 2, A4, $02
    PATEND

Pat015:
    NOTE 1, B5, $02
    NOTE 1, B5, $02
    NOTE 4, B5, $02
    NOTE 2, A5, $02
    NOTE 1, Gs5, $02
    NOTE 1, E5, $02
    NOTE 1, Ds5, $02
    NOTE 1, D5, $02
    NOTE 1, C5, $02
    NOTE 1, B4, $02
    NOTE 1, A4, $02
    NOTE 1, Gs4, $02
    PATEND

Pat016:
    NOTE 10, A5, $02
    NOTE 1, E6, $02
    NOTE 2, F6, $02
    NOTE 1, E6, $02
    NOTE 2, F6, $02
    PATEND

Pat017:
    NOTE 10, B5, $02
    NOTE 1, Ds6, $02
    NOTE 2, E6, $02
    NOTE 1, Ds6, $02
    NOTE 2, E6, $02
    PATEND

Pat018:
    NOTE 10, C5, $02
    NOTE 1, F5, $02
    NOTE 2, G5, $02
    NOTE 1, F5, $02
    NOTE 2, G5, $02
    PATEND

Pat019:
    NOTE 2, E5, $02
    KEYOFF 1
    NOTE 2, E4, $02
    KEYOFF 1
    NOTE 2, E5, $02
    KEYOFF 1
    NOTE 1, E4, $02
    NOTE 1, E4, $02
    NOTE 1, E4, $02
    NOTE 1, E5, $02
    NOTE 1, E5, $02
    NOTE 2, E4, $02
    SONGJUMP Song01_Ch3

Pat020:
    HOLD 2
    NOTE 4, E4, $03
    NOTE 2, E4, $03
    NOTE 4, E4, $03
    NOTE 2, E4, $03
    NOTE 2, E4, $03
    PATEND

Pat021:
    NOTE 1, Gs4, $04
    NOTE 2, Gs4, $04
    NOTE 1, Gs4, $04
    NOTE 2, Gs4, $04
    NOTE 1, Gs4, $04
    NOTE 7, Gs4, $04
    NOTE 2, B4, $05
    PATEND

Pat022:
    NOTE 1, C4, $06
    NOTE 2, C4, $06
    NOTE 1, C4, $06
    NOTE 1, C4, $06
    NOTE 1, C4, $06
    NOTE 1, C4, $06
    NOTE 1, C4, $06
    NOTE 1, Cs4, $06
    NOTE 2, Cs4, $06
    NOTE 1, Cs4, $06
    NOTE 1, Cs4, $06
    NOTE 1, Cs4, $06
    NOTE 1, Cs4, $06
    NOTE 1, Cs4, $06
    PATEND

Pat023:
    NOTE 1, D4, $06
    NOTE 2, D4, $06
    NOTE 1, D4, $06
    NOTE 1, D4, $06
    NOTE 1, D4, $06
    NOTE 1, D4, $06
    NOTE 1, D4, $06
    NOTE 1, Ds4, $06
    NOTE 2, Ds4, $06
    NOTE 1, Ds4, $06
    NOTE 1, Ds4, $06
    NOTE 1, Ds4, $06
    NOTE 1, Ds4, $06
    NOTE 1, Ds4, $06
    PATEND

Pat024:
    NOTE 1, E4, $07
    NOTE 1, E4, $07
    NOTE 4, E4, $07
    NOTE 2, F4, $07
    NOTE 1, E4, $07
    NOTE 1, E4, $07
    NOTE 4, E4, $07
    NOTE 2, Ds4, $07
    PATEND

Pat025:
    NOTE 1, E4, $07
    NOTE 1, E4, $07
    NOTE 4, E4, $07
    NOTE 2, F4, $07
    NOTE 8, E4, $07
    PATEND

Pat026:
    NOTE 16, A3, $08
    PATEND

Pat027:
    NOTE 3, B3, $08
    NOTE 3, B3, $08
    NOTE 3, B3, $08
    NOTE 1, B3, $06
    NOTE 1, B3, $06
    NOTE 1, B3, $06
    NOTE 1, B3, $06
    NOTE 1, B3, $06
    NOTE 2, B3, $06
    SONGJUMP Song01_Ch2

Pat028:
    HOLD 128
    SONGJUMP Song05_Ch1_Loop

Pat029:
    NOTE 1, C3, $09
    NOTE 1, C3, $09
    NOTE 1, C3, $09
    NOTE 1, Ds3, $09
    NOTE 1, C3, $09
    NOTE 1, C3, $09
    NOTE 1, C3, $09
    NOTE 1, Ds3, $09
    NOTE 1, C3, $09
    NOTE 1, C3, $09
    NOTE 1, C3, $09
    NOTE 1, Ds3, $09
    NOTE 1, C3, $09
    NOTE 1, C3, $09
    NOTE 1, C3, $09
    NOTE 1, Ds3, $09
    PATEND

Pat030:
    NOTE 1, F3, $09
    NOTE 1, F3, $09
    NOTE 1, F3, $09
    NOTE 1, Gs3, $09
    NOTE 1, F3, $09
    NOTE 1, F3, $09
    NOTE 1, F3, $09
    NOTE 1, Gs3, $09
    NOTE 1, G3, $09
    NOTE 1, G3, $09
    NOTE 1, G3, $09
    NOTE 1, B3, $09
    NOTE 1, G3, $09
    NOTE 1, G3, $09
    NOTE 1, G3, $09
    NOTE 1, B3, $09
    PATEND

Pat031:
    NOTE 1, G3, $09
    NOTE 1, G3, $09
    NOTE 1, G3, $09
    NOTE 1, B3, $09
    NOTE 1, G3, $09
    NOTE 1, G3, $09
    NOTE 1, G3, $09
    NOTE 1, B3, $09
    NOTE 1, F3, $09
    NOTE 1, F3, $09
    NOTE 1, F3, $09
    NOTE 1, Gs3, $09
    NOTE 1, F3, $09
    NOTE 1, F3, $09
    NOTE 1, F3, $09
    NOTE 1, Gs3, $09
    PATEND

Pat032:
    NOTE 8, C4, $08
    NOTE 5, B3, $08
    NOTE 1, As3, $08
    NOTE 1, A3, $08
    NOTE 1, F3, $08
    PATEND

Pat033:
    NOTE 8, Gs3, $08
    NOTE 3, G3, $08
    NOTE 3, As3, $08
    NOTE 2, B3, $08
    PATEND

Pat034:
    NOTE 8, Gs3, $08
    NOTE 3, G3, $08
    NOTE 3, As3, $08
    NOTE 2, D4, $08
    PATEND

Pat035:
    NOTE 8, Ds5, $08
    NOTE 3, C5, $08
    NOTE 3, B4, $08
    NOTE 2, C5, $08
    PATEND

Pat036:
    NOTE 8, Gs4, $08
    NOTE 8, D5, $08
    PATEND

Pat037:
    NOTE 8, G5, $08
    NOTE 3, F5, $08
    NOTE 3, Ds5, $08
    NOTE 2, F5, $08
    PATEND

Pat038:
    NOTE 8, D5, $08
    NOTE 8, B5, $08
    PATEND

Pat039:
    NOTE 8, Gs4, $08
    NOTE 3, G4, $08
    NOTE 3, D4, $08
    NOTE 2, B3, $08
    SONGJUMP Song02_Ch1

Pat040:
    NOTE 8, G3, $08
    NOTE 5, Fs3, $08
    NOTE 1, F3, $08
    NOTE 1, Ds3, $08
    NOTE 1, C3, $08
    PATEND

Pat041:
    NOTE 8, C3, $08
    NOTE 3, C3, $08
    NOTE 3, Ds3, $08
    NOTE 2, F3, $08
    PATEND

Pat042:
    NOTE 8, Gs3, $08
    NOTE 5, Gs3, $08
    NOTE 1, G3, $08
    NOTE 1, Fs3, $08
    NOTE 1, D3, $08
    PATEND

Pat043:
    NOTE 8, F3, $08
    NOTE 3, F3, $08
    NOTE 3, F3, $08
    NOTE 2, F3, $08
    PATEND

Pat044:
    NOTE 8, C5, $08
    NOTE 3, G4, $08
    NOTE 3, G4, $08
    NOTE 2, G4, $08
    PATEND

Pat045:
    NOTE 8, F4, $08
    NOTE 8, G4, $08
    PATEND

Pat046:
    NOTE 8, D5, $08
    NOTE 3, D5, $08
    NOTE 3, C5, $08
    NOTE 2, D5, $08
    PATEND

Pat047:
    NOTE 8, B4, $08
    NOTE 8, B4, $08
    PATEND

Pat048:
    NOTE 8, F4, $08
    NOTE 3, B3, $08
    NOTE 3, B4, $08
    NOTE 2, Ds4, $08
    SONGJUMP Song02_Ch2

Pat049:
    NOTE 1, C3, $09
    NOTE 1, C3, $09
    NOTE 1, C3, $09
    NOTE 1, Ds3, $09
    NOTE 1, C3, $09
    NOTE 1, C3, $09
    NOTE 1, C3, $09
    NOTE 1, Ds3, $09
    NOTE 1, C3, $09
    NOTE 1, C3, $09
    NOTE 1, C3, $09
    NOTE 1, Ds3, $09
    NOTE 1, C3, $09
    NOTE 1, C3, $09
    NOTE 1, C3, $09
    NOTE 1, Ds3, $09
    SONGJUMP Song02_Ch3

Pat050:
    NOTE 4, C5, $02
    NOTE 4, Fs5, $02
    NOTE 4, G5, $02
    NOTE 4, Cs5, $02
    PATEND

Pat051:
    NOTE 2, C5, $02
    NOTE 2, Fs5, $02
    NOTE 2, G5, $02
    NOTE 2, Cs5, $02
    NOTE 2, C5, $02
    NOTE 2, Fs5, $02
    NOTE 2, G5, $02
    NOTE 2, Cs5, $02
    PATEND

Pat052:
    NOTE 2, G4, $02
    NOTE 2, Fs4, $02
    NOTE 2, G5, $02
    NOTE 2, Fs5, $02
    NOTE 1, G4, $02
    NOTE 1, Fs4, $02
    NOTE 1, G5, $02
    NOTE 1, Fs5, $02
    NOTE 1, G4, $02
    NOTE 1, Fs4, $02
    NOTE 1, G5, $02
    NOTE 1, Fs5, $02
    PATEND

Pat053:
    NOTE 2, G4, $02
    NOTE 2, Fs4, $02
    NOTE 2, Gs5, $02
    NOTE 2, G5, $02
    NOTE 1, G4, $02
    NOTE 1, Fs4, $02
    NOTE 1, Gs5, $02
    NOTE 1, G5, $02
    NOTE 1, G4, $02
    NOTE 1, Fs4, $02
    NOTE 1, Gs5, $02
    NOTE 1, G5, $02
    PATEND

Pat054:
    NOTE 1, B4, $02
    NOTE 2, D5, $02
    NOTE 2, B4, $02
    KEYOFF 3
    NOTE 1, C5, $02
    NOTE 2, Ds5, $02
    NOTE 2, C5, $02
    KEYOFF 3
    PATEND

Pat055:
    NOTE 1, Ds3, $02
    NOTE 1, F3, $02
    NOTE 1, G3, $02
    NOTE 1, B3, $02
    NOTE 1, F3, $02
    NOTE 1, G3, $02
    NOTE 1, B3, $02
    NOTE 1, D4, $02
    NOTE 2, D5, $02
    NOTE 2, B4, $02
    NOTE 2, A4, $02
    NOTE 2, B4, $02
    SONGJUMP Song03_Ch3

Pat056:
    NOTE 1, C3, $01
    NOTE 1, C3, $01
    NOTE 1, C2, $01
    NOTE 1, C2, $01
    NOTE 1, C3, $01
    NOTE 1, C3, $01
    NOTE 1, C2, $01
    NOTE 1, C3, $01
    NOTE 1, C2, $01
    NOTE 1, C3, $01
    NOTE 1, C3, $01
    NOTE 1, C2, $01
    NOTE 1, C3, $01
    NOTE 1, C3, $01
    NOTE 1, C2, $01
    NOTE 1, C2, $01
    PATEND

Pat057:
    NOTE 1, Ds2, $01
    NOTE 1, F2, $01
    NOTE 1, G2, $01
    NOTE 1, B2, $01
    NOTE 1, F2, $01
    NOTE 1, G2, $01
    NOTE 1, B2, $01
    NOTE 1, D3, $01
    NOTE 2, G2, $01
    NOTE 2, G2, $01
    NOTE 1, G2, $01
    NOTE 1, F2, $01
    NOTE 1, Ds2, $01
    NOTE 1, D2, $01
    SONGJUMP Song03_Ch1

Pat058:
    NOTE 1, G3, $03
    NOTE 2, G3, $03
    NOTE 2, G3, $03
    NOTE 1, G3, $03
    NOTE 2, G3, $03
    NOTE 1, G3, $03
    NOTE 2, G3, $03
    NOTE 2, G3, $03
    NOTE 1, G3, $03
    NOTE 2, G3, $03
    PATEND

Pat059:
    NOTE 2, G3, $07
    NOTE 2, G3, $07
    NOTE 2, G3, $07
    NOTE 2, G3, $07
    NOTE 2, G3, $07
    NOTE 2, G3, $07
    NOTE 2, G3, $07
    NOTE 2, G3, $07
    PATEND

Pat060:
    NOTE 2, G4, $07
    NOTE 2, G4, $07
    NOTE 2, G4, $07
    NOTE 2, G4, $07
    NOTE 2, Gs4, $07
    NOTE 2, Gs4, $07
    NOTE 2, Gs4, $07
    NOTE 2, Gs4, $07
    PATEND

Pat061:
    NOTE 1, G4, $06
    NOTE 1, Fs4, $06
    NOTE 1, F4, $06
    NOTE 1, E4, $06
    NOTE 1, Ds4, $06
    NOTE 1, D4, $06
    NOTE 1, Cs4, $06
    NOTE 1, C4, $06
    NOTE 1, B3, $06
    NOTE 1, As3, $06
    NOTE 1, A3, $06
    NOTE 1, Gs3, $06
    NOTE 1, G3, $06
    NOTE 1, F3, $06
    NOTE 1, Ds3, $06
    NOTE 1, D3, $06
    SONGJUMP Song03_Ch2

Pat062:
    NOTE 1, Gs4, $0A
    NOTE 1, Ds4, $0A
    NOTE 1, Ds5, $0A
    NOTE 1, E5, $0A
    NOTE 1, B4, $0A
    NOTE 1, As4, $0A
    NOTE 1, Ds5, $0A
    NOTE 1, B4, $0A
    NOTE 1, Gs4, $0A
    NOTE 1, Ds4, $0A
    NOTE 1, Ds5, $0A
    NOTE 1, E5, $0A
    NOTE 1, B4, $0A
    NOTE 1, As4, $0A
    NOTE 1, Ds5, $0A
    NOTE 1, B4, $0A
    PATEND

Pat063:
    NOTE 1, G4, $0A
    NOTE 1, D4, $0A
    NOTE 1, D5, $0A
    NOTE 1, D4, $0A
    NOTE 1, A4, $0A
    NOTE 1, As4, $0A
    NOTE 1, D5, $0A
    NOTE 1, D4, $0A
    NOTE 1, G4, $0A
    NOTE 1, D4, $0A
    NOTE 1, D5, $0A
    NOTE 1, D4, $0A
    NOTE 1, As4, $0A
    NOTE 1, D4, $0A
    NOTE 1, D5, $0A
    NOTE 1, D4, $0A
    PATEND

Pat064:
    NOTE 1, D5, $0A
    NOTE 1, Cs4, $0A
    NOTE 1, Cs5, $0A
    NOTE 1, Cs4, $0A
    NOTE 1, As4, $0A
    NOTE 1, Cs4, $0A
    NOTE 1, Cs5, $0A
    NOTE 1, Cs4, $0A
    NOTE 1, G4, $0A
    NOTE 1, D4, $0A
    NOTE 1, D5, $0A
    NOTE 1, G4, $0A
    NOTE 1, B4, $0A
    NOTE 1, G4, $0A
    NOTE 1, D5, $0A
    NOTE 1, G4, $0A
    PATEND

Pat065:
    NOTE 1, Gs3, $0A
    NOTE 1, Gs4, $0A
    NOTE 1, Gs3, $0A
    NOTE 1, Gs4, $0A
    NOTE 1, G3, $0A
    NOTE 1, G4, $0A
    NOTE 1, Gs3, $0A
    NOTE 1, Gs4, $0A
    NOTE 1, Gs4, $0A
    NOTE 1, Ds4, $0A
    NOTE 1, Ds5, $0A
    NOTE 1, Ds4, $0A
    NOTE 1, As4, $0A
    NOTE 1, B4, $0A
    NOTE 1, Ds5, $0A
    NOTE 1, Ds4, $0A
    PATEND

Pat066:
    NOTE 14, Gs4, $02
    NOTE 2, Gs4, $02
    PATEND

Pat067:
    NOTE 14, G4, $02
    NOTE 2, G4, $02
    PATEND

Pat068:
    NOTE 4, Fs4, $02
    NOTE 2, Cs4, $02
    NOTE 2, Fs4, $02
    NOTE 4, G4, $02
    NOTE 2, D4, $02
    NOTE 2, G4, $02
    PATEND

Pat069:
    NOTE 2, G4, $02
    NOTE 2, Gs4, $02
    NOTE 2, G4, $02
    NOTE 4, Gs4, $02
    NOTE 2, Ds4, $02
    NOTE 2, B3, $02
    NOTE 2, Gs3, $02
    PATEND

Pat070:
    NOTE 10, As4, $02
    NOTE 2, C5, $02
    NOTE 2, Cs5, $02
    NOTE 2, A4, $02
    PATEND

Pat071:
    NOTE 1, Gs2, $01
    NOTE 1, Gs3, $01
    NOTE 1, Gs2, $01
    NOTE 1, Gs3, $01
    NOTE 6, Ds4, $03
    NOTE 1, Gs2, $01
    NOTE 1, Gs3, $01
    NOTE 4, Ds4, $03
    PATEND

Pat072:
    NOTE 1, Fs2, $01
    NOTE 1, Fs3, $01
    NOTE 1, Fs2, $01
    NOTE 1, Fs3, $01
    NOTE 6, As4, $04
    NOTE 1, G2, $01
    NOTE 1, G3, $01
    NOTE 4, B4, $04
    PATEND

Pat073:
    NOTE 1, Gs3, $0A
    NOTE 1, Gs4, $0A
    NOTE 1, Gs3, $0A
    NOTE 1, Gs4, $0A
    NOTE 1, G3, $0A
    NOTE 1, G4, $0A
    NOTE 1, Gs3, $0A
    NOTE 1, Gs4, $0A
    NOTE 1, Gs4, $0A
    NOTE 1, Ds4, $0A
    NOTE 1, Ds5, $0A
    NOTE 1, Ds4, $0A
    NOTE 1, As4, $0A
    NOTE 1, B4, $0A
    NOTE 1, Ds5, $0A
    NOTE 1, Ds4, $0A
    SONGJUMP Song04_Ch1

Pat074:
    NOTE 1, Gs2, $01
    NOTE 1, Gs3, $01
    NOTE 1, Gs2, $01
    NOTE 1, Gs3, $01
    NOTE 6, Ds4, $03
    NOTE 1, Gs2, $01
    NOTE 1, Gs3, $01
    NOTE 4, Ds4, $03
    SONGJUMP Song04_Ch2

Pat075:
    NOTE 2, G4, $02
    NOTE 2, Gs4, $02
    NOTE 2, G4, $02
    NOTE 4, Gs4, $02
    NOTE 2, Ds4, $02
    NOTE 2, B3, $02
    NOTE 2, Gs3, $02
    SONGJUMP Song04_Ch3

Pat076:
    NOTE 1, As2, $01
    NOTE 1, Cs3, $01
    NOTE 1, C3, $01
    NOTE 1, B2, $01
    NOTE 1, As2, $01
    KEYON 1
    NOTE 1, Cs3, $01
    NOTE 1, C3, $01
    NOTE 1, B2, $01
    NOTE 1, As2, $01
    NOTE 1, Cs3, $01
    NOTE 1, C3, $01
    NOTE 1, B2, $01
    NOTE 1, As2, $01
    KEYON 1
    NOTE 1, Cs3, $01
    NOTE 1, C3, $01
    NOTE 8, B2, $01
    SONGJUMP Song05_Ch1_Loop

Pat077:
    NOTE 8, Fs3, $06
    NOTE 8, B3, $06
    NOTE 8, D4, $06
    NOTE 8, B3, $06
    NOTE 8, D4, $06
    NOTE 8, Fs4, $06
    NOTE 8, D4, $06
    NOTE 8, Fs4, $06
    NOTE 8, B4, $06
    NOTE 8, Fs4, $06
    NOTE 8, B4, $06
    NOTE 8, D5, $06
    NOTE 8, B4, $06
    NOTE 8, D5, $06
    NOTE 8, E5, $06
    PATEND

Pat078:
    NOTE 7, Fs4, $0C
    NOTE 7, Fs4, $0C
    NOTE 28, Fs4, $0C
    NOTE 14, G4, $0C
    NOTE 14, Gs4, $0C
    NOTE 14, G4, $0C
    NOTE 14, Fs4, $0C
    NOTE 14, F4, $0C
    NOTE 21, Fs4, $0C
    NOTE 7, Fs3, $0C
    NOTE 112, Fs3, $0C
    KEYOFF 14
    SONGJUMP Song05_Ch1_Loop

Pat079:
    NOTE 8, D3, $06
    NOTE 8, Fs3, $06
    NOTE 8, B3, $06
    NOTE 8, Fs3, $06
    NOTE 8, B3, $06
    NOTE 8, D4, $06
    NOTE 8, B3, $06
    NOTE 8, D4, $06
    NOTE 8, Fs4, $06
    NOTE 8, E4, $06
    NOTE 8, Fs4, $06
    NOTE 8, B4, $06
    NOTE 8, Cs4, $06
    NOTE 8, B4, $06
    NOTE 8, Cs5, $06
    PATEND

Pat080:
    NOTE 7, B3, $0C
    NOTE 7, B3, $0C
    NOTE 28, B3, $0C
    NOTE 14, B3, $0C
    KEYON 14
    KEYON 14
    KEYON 14
    KEYON 14
    NOTE 21, As3, $0C
    NOTE 7, As3, $0C
    NOTE 112, As3, $0C
    KEYOFF 14
    SONGJUMP Song05_Ch1_Loop

Pat081:
    NOTE 24, D4, $02
    NOTE 24, Fs4, $02
    NOTE 24, B4, $02
    NOTE 24, Fs4, $02
    NOTE 24, E4, $02
    PATEND

Pat082:
    NOTE 7, B3, $0B
    NOTE 7, B3, $0B
    NOTE 28, B3, $0B
    NOTE 14, B3, $0B
    NOTE 14, D4, $0B
    NOTE 14, Ds4, $0B
    NOTE 14, E4, $0B
    NOTE 14, F4, $0B
    NOTE 21, Fs4, $0B
    NOTE 7, Fs3, $0B
    NOTE 56, Fs3, $0B
    KEYOFF 128
    SONGJUMP Song05_Ch1_Loop

Pat084:
    KEYOFF 2

Pat083:
    NOTE 1, F5, $0C
    NOTE 1, Fs5, $0C
    NOTE 1, G5, $0C
    NOTE 1, Ds5, $0C
    NOTE 1, E5, $0C
    NOTE 1, F5, $0C
    NOTE 1, Cs5, $0C
    NOTE 1, D5, $0C
    NOTE 1, Ds5, $0C
    NOTE 1, C5, $0C
    NOTE 1, B4, $0C
    NOTE 1, As4, $0C
    NOTE 1, A4, $0C
    NOTE 1, Gs4, $0C
    NOTE 1, G4, $0C
    NOTE 8, Fs4, $0C
    KEYOFF 8
    SONGJUMP Song05_Ch1_Loop

Pat085:
    NOTE 1, F5, $0B
    NOTE 1, Fs5, $0B
    NOTE 1, G5, $0B
    NOTE 1, Ds5, $0B
    NOTE 1, E5, $0B
    NOTE 1, F5, $0B
    NOTE 1, Cs5, $0B
    NOTE 1, D5, $0B
    NOTE 1, Ds5, $0B
    NOTE 1, C5, $0B
    NOTE 1, B4, $0B
    NOTE 1, As4, $0B
    NOTE 1, A4, $0B
    NOTE 1, Gs4, $0B
    NOTE 1, G4, $0B
    NOTE 8, Fs4, $0B
    KEYOFF 8
    SONGJUMP Song05_Ch1_Loop

Pat086:
    NOTE 1, B6, $06
    NOTE 1, As6, $06
    NOTE 1, A6, $06
    NOTE 1, Gs6, $01
    NOTE 1, G6, $06
    NOTE 1, Fs6, $06
    NOTE 1, F6, $06
    NOTE 1, E6, $06
    NOTE 1, Gs6, $06
    NOTE 1, G6, $06
    NOTE 1, Fs6, $06
    NOTE 1, F6, $06
    NOTE 1, E6, $06
    NOTE 1, Ds6, $06
    NOTE 1, D6, $06
    NOTE 1, Cs6, $06
    PATEND

Pat087:
    KEYOFF 2
    NOTE 1, B6, $06
    NOTE 1, As6, $06
    NOTE 1, A6, $06
    NOTE 1, Gs6, $01
    NOTE 1, G6, $06
    NOTE 1, Fs6, $06
    NOTE 1, F6, $06
    NOTE 1, E6, $06
    NOTE 1, Gs6, $06
    NOTE 1, G6, $06
    NOTE 1, Fs6, $06
    NOTE 1, F6, $06
    NOTE 1, E6, $06
    NOTE 1, Ds6, $06
    PATEND

Pat088:
    NOTE 2, B4, $08
    NOTE 2, B4, $08
    NOTE 8, B4, $08
    NOTE 4, B4, $08
    NOTE 6, D5, $08
    NOTE 6, D5, $08
    NOTE 4, D5, $08
    NOTE 16, Fs5, $08
    SONGJUMP Song05_Ch1_Loop

Pat089:
    NOTE 2, Fs4, $08
    NOTE 2, Fs4, $08
    NOTE 8, Fs4, $08
    NOTE 4, Fs4, $08
    NOTE 6, G4, $08
    NOTE 6, G4, $08
    NOTE 4, G4, $08
    NOTE 16, As3, $08
    SONGJUMP Song05_Ch1_Loop

Pat090:
    NOTE 4, Fs4, $0B
    NOTE 4, F4, $0B
    NOTE 4, E4, $0B
    NOTE 4, Ds4, $0B
    NOTE 4, D4, $0B
    NOTE 4, Cs4, $0B
    NOTE 4, C4, $0B
    NOTE 4, B3, $0B
    NOTE 2, B3, $0B
    NOTE 2, B3, $0B
    NOTE 8, B3, $0B
    NOTE 4, B3, $0B
    NOTE 6, G3, $0B
    NOTE 6, G3, $0B
    NOTE 4, G3, $0B
    NOTE 18, Fs3, $0B
    KEYOFF 1
    SONGJUMP Song05_Ch1_Loop

Pat091:
    NOTE 8, As2, $08
    NOTE 8, C3, $08
    PATEND

Pat092:
    NOTE 8, D3, $08
    NOTE 8, Ds3, $08
    PATEND

Pat093:
    NOTE 16, As2, $08
    PATEND

Pat094:
    NOTE 8, G4, $08
    NOTE 8, Gs4, $08
    PATEND

Pat095:
    NOTE 8, As4, $08
    NOTE 8, C5, $08
    PATEND

Pat096:
    NOTE 16, D5, $08
    PATEND

Pat097:
    NOTE 1, Ds5, $02
    NOTE 1, D5, $02
    NOTE 1, Ds5, $02
    NOTE 1, G4, $02
    NOTE 1, Ds5, $02
    NOTE 1, D5, $02
    NOTE 1, Ds5, $02
    NOTE 1, G4, $02
    NOTE 1, F5, $02
    NOTE 1, Ds5, $02
    NOTE 1, F5, $02
    NOTE 1, Gs4, $02
    NOTE 1, F5, $02
    NOTE 1, Ds5, $02
    NOTE 1, F5, $02
    NOTE 1, Gs4, $02
    PATEND

Pat098:
    NOTE 1, G5, $02
    NOTE 1, F5, $02
    NOTE 1, G5, $02
    NOTE 1, Ds5, $02
    NOTE 1, F5, $02
    NOTE 1, G5, $02
    NOTE 1, As4, $02
    NOTE 1, Gs5, $02
    NOTE 1, G5, $02
    NOTE 1, Gs5, $02
    NOTE 1, F5, $02
    NOTE 1, G5, $02
    NOTE 1, Gs5, $02
    NOTE 1, Gs5, $02
    NOTE 1, G5, $02
    NOTE 1, Gs5, $02
    PATEND

Pat099:
    NOTE 1, As4, $02
    NOTE 1, C5, $02
    NOTE 1, As4, $02
    NOTE 1, C5, $02
    NOTE 1, As4, $02
    NOTE 1, C5, $02
    NOTE 1, As4, $02
    NOTE 1, C5, $02
    NOTE 1, As4, $02
    NOTE 1, C5, $02
    NOTE 1, As4, $02
    NOTE 1, C5, $02
    NOTE 1, As4, $02
    NOTE 1, C5, $02
    NOTE 1, As4, $02
    NOTE 1, C5, $02
    PATEND

Pat100:
    NOTE 14, Ds5, $02
    KEYOFF 2
    SONGJUMP Song05_Ch1_Loop

Pat101:
    NOTE 128, C5, $16
    SONGJUMP Song00_Ch1

Pat102:
    NOTE 128, C5, $17
    SONGJUMP Song00_Ch3

Pat103:
    NOTE 128, $24, $04
    SONGJUMP Song00_Ch4

OrphanTab_57B6:
    TB 1, $01
    TB 1, $00
    TLOOP OrphanTab_57B6

OrphanTab_57BD:
    TB 255, $00
    TLOOP OrphanTab_57BD

OrphanTab_57C2:
    TB 255, $01
    TLOOP OrphanTab_57C2

Comb_57C7:
    TB 255, $02 ; note + freq table
    TLOOP Comb_57C7

Arp_57CC:
    TB 255, $00 ; +0
    TLOOP Arp_57CC

Freq_57D1:
    TW 255, 0
    TLOOP Freq_57D1

OrphanTab_57D7:
    TB 255, $00
    TLOOP OrphanTab_57D7

OrphanTab_57DC:
    TW 20, 0

OrphanTab_57DC_Loop:
    TW 2, 1
    TW 2, -1
    TW 2, -1
    TW 2, 1
    TLOOP OrphanTab_57DC_Loop

OrphanTab_57EE:
    TW 3, 10
    TW 3, -10
    TW 3, -10
    TW 3, 10
    TLOOP OrphanTab_57EE

OrphanTab_57FD:
    TW 3, 5
    TW 3, -5
    TW 3, -5
    TW 3, 5
    TLOOP OrphanTab_57FD

Freq_580C:
    TW 3, 2
    TW 3, -2
    TW 3, -2
    TW 3, 2
    TLOOP Freq_580C

Freq_581B:
    TW 3, 1
    TW 3, -1
    TW 3, -1
    TW 3, 1
    TLOOP Freq_581B

Ins00:
    INS_TONE $80, $01, $00, Arp_57CC, Freq_57D1, Comb_57C7 ; $00 (unused)

Ins01:
    INS_TONE $C0, $F2, $21, Arp_583C, Freq_57D1, Comb_57C7 ; $01

Arp_583C:
    TB 1, $0C ; +12
    TB 7, $00 ; +0
    TLOOP Arp_583C

Ins02:
    INS_WAVE Vol_584D, BlankVol, Arp_57CC, Freq_58C6, Comb_57C7 ; $02

Vol_584D:
    TB 255, $20 ; 100%
    TLOOP Vol_584D

Ins03:
    INS_TONE $00, $A7, $01, Arp_585B, Freq_581B, Comb_57C7 ; $03

Arp_585B:
    TB 1, $00 ; +0
    TB 1, $0C ; +12
    TB 1, $05 ; +5
    TB 1, $08 ; +8
    TLOOP Arp_585B

Ins04:
    INS_TONE $00, $A7, $01, Arp_586F, Freq_581B, Comb_57C7 ; $04

Arp_586F:
    TB 1, $00 ; +0
    TB 1, $03 ; +3
    TB 1, $08 ; +8
    TLOOP Arp_586F

Ins05:
    INS_TONE $40, $87, $01, Arp_5881, Freq_581B, Comb_57C7 ; $05

Arp_5881:
    TB 1, $00 ; +0
    TB 1, $03 ; +3
    TB 1, $05 ; +5
    TB 1, $09 ; +9
    TB 1, $0C ; +12
    TLOOP Arp_5881

Ins06:
    INS_TONE $40, $B2, $01, Arp_583C, Freq_581B, Comb_57C7 ; $06

Ins07:
    INS_TONE $00, $A7, $01, Arp_58A0, Freq_581B, Comb_57C7 ; $07

Arp_58A0:
    TB 1, $0C ; +12
    TB 1, $00 ; +0
    TB 1, $04 ; +4
    TB 1, $07 ; +7
    TLOOP Arp_58A0

Ins08:
    INS_TONE $00, $E7, $01, Arp_57CC, Freq_580C, Comb_57C7 ; $08

Ins12:
    INS_TONE $C0, $97, $01, Arp_57CC, Freq_58C6, Comb_57C7 ; $0C

Ins13:
    INS_TONE $00, $C5, $01, Arp_583C, Freq_57D1, Comb_57C7 ; $0D (unused)

Freq_58C6:
    TW 12, 0

Freq_58C6_L0:
    TW 3, 2
    TW 3, -2
    TW 3, -2
    TW 3, 2
    TW 3, 3
    TW 3, -3
    TW 3, -3
    TW 3, 3
    TW 3, 4
    TW 3, -4
    TW 3, -4
    TW 3, 4
    TLOOP Freq_58C6_L0

Ins09:
    INS_WAVE Vol_58FA, BlankVol, Arp_57CC, Freq_57D1, Comb_57C7 ; $09

Vol_58FA:
    TB 4, $20 ; 100%
    TB 255, $40 ; 50%
    TLOOP Vol_58FA

Ins10:
    INS_TONE $00, $88, $01, Arp_57CC, Freq_580C, Comb_57C7 ; $0A

Ins11:
    INS_WAVE Vol_5914, BlankVol, Arp_583C, Freq_58C6, Comb_57C7 ; $0B

Vol_5914:
    TB 20, $20 ; 100%
    TB 20, $40 ; 50%
    TB 255, $60 ; 25%
    TB 255, $60 ; 25%
    TLOOP BlankVol

Ins14:
    INS_TONE $00, $B8, $51, Arp_5928, Freq_57D1, Comb_57C7 ; $0E

Arp_5928:
    TB 1, $00 ; +0
    TB 1, $02 ; +2

Arp_5928_L0:
    TB 1, $07 ; +7
    TB 1, $06 ; +6
    TB 1, $03 ; +3
    TB 2, $00 ; +0
    TLOOP Arp_5928_L0

Ins15:
    INS_TONE $00, $B8, $61, Arp_57CC, Freq_5940, Comb_57C7 ; $0F

Freq_5940:
    TW 4, 10
    TW 4, -10
    TLOOP Freq_5940

Ins16:
    INS_TONE $00, $9B, $C1, Arp_596D, Freq_5964, Comb_57C7 ; $10

Ins17:
    INS_TONE $40, $C2, $C1, Arp_596D, Freq_595B, Comb_57C7 ; $11

Freq_595B:
    TW 1, 75

Freq_595B_L0:
    TW 10, -2
    TLOOP Freq_595B_L0

Freq_5964:
    TW 3, 5
    TW 3, 30
    TLOOP Freq_5964

Arp_596D:
    TB 1, $00 ; +0
    TB 1, $01 ; +1
    TLOOP Arp_596D

Ins18:
    INS_TONE $00, $E8, $71, Arp_5986, Freq_57D1, Comb_57C7 ; $12

Ins22:
    INS_TONE $80, $01, $01, Arp_5986, Freq_57D1, Comb_57C7 ; $16

Arp_5986:
    TB 3, $00 ; +0
    TB 2, $FD ; -3
    TB 3, $03 ; +3
    TB 2, $00 ; +0
    TB 3, $08 ; +8
    TB 2, $05 ; +5
    TB 12, $0B ; +11
    TLOOP Arp_5986

Ins19:
    INS_TONE $00, $E8, $A1, Arp_596D, Freq_59A0, Comb_57C7 ; $13

Freq_59A0:
    TW 2, 10
    TW 20, -5
    TLOOP Freq_59A0

NoiseIns00:
    INS_NOISE $00, $D2, $A1, Noise_59B7, Arp_57CC ; $00

NoiseIns04:
    INS_NOISE $00, $01, $01, Noise_59B7, Arp_57CC ; $04

Noise_59B7:
    TB 4, $51
    TB 4, $52
    TB 4, $53
    TB 255, $55
    TLOOP Noise_59B7

NoiseIns01:
    INS_NOISE $00, $F3, $A1, Noise_59C9, Arp_57CC ; $01

Noise_59C9:
    TB 2, $49
    TB 2, $4A
    TB 2, $4B
    TB 2, $4C
    TB 2, $4D
    TLOOP Noise_59C9

NoiseIns02:
    INS_NOISE $00, $F4, $81, Noise_59DD, Arp_57CC ; $02

Noise_59DD:
    TB 3, $24
    TB 3, $26
    TB 3, $34
    TB 3, $36
    TB 3, $44
    TB 3, $46
    TB 2, $54
    TB 2, $56
    TB 2, $64

Noise_59DD_L0:
    TB 20, $66
    TLOOP Noise_59DD_L0

NoiseIns03:
    INS_NOISE $00, $C1, $81, Noise_59FB, Arp_57CC ; $03

Noise_59FB:
    TB 1, $24
    TB 1, $26
    TB 1, $27
    TB 1, $35
    TB 1, $37
    TB 1, $45
    TLOOP Noise_59FB

Ins20:
    INS_TONE $00, $F1, $A1, Arp_57CC, Freq_5A13, Comb_57C7 ; $14

Freq_5A13:
    TW 50, -80
    TLOOP Freq_5A13

Ins21:
    INS_TONE $C0, $F2, $A1, Arp_5A22, Freq_57D1, Comb_57C7 ; $15

Arp_5A22:
    TB 3, $00 ; +0
    TB 3, $03 ; +3
    TB 3, $06 ; +6
    TB 3, $09 ; +9
    TB 3, $0C ; +12
    TB 3, $0F ; +15
    TB 3, $12 ; +18
    TLOOP Arp_5A22

Ins23:
    INS_WAVE BlankVol, BlankVol, Arp_57CC, Freq_57D1, Comb_57C7 ; $17

Wave_5A3D:
    db $C0, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

Wave_5A4D:
    db $C0, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

Morph_5A5D:
    MORPH 10, $30, $C0
    MORPH 10, $30, $CC
    MORPH 10, $31, $C0
    MORPH 10, $31, $CC
    MORPH 10, $32, $C0
    MORPH 10, $32, $CC
    MORPH 10, $33, $C0
    MORPH 10, $33, $CC
    MORPH 10, $34, $C0
    MORPH 10, $34, $CC
    MORPH 10, $35, $C0
    MORPH 10, $35, $CC
    MORPH 10, $36, $C0
    MORPH 10, $36, $CC
    MORPH 10, $37, $C0
    MORPH 10, $37, $CC
    MORPH 10, $38, $C0
    MORPH 10, $38, $CC
    MORPH 10, $39, $C0
    MORPH 10, $39, $CC
    MORPH 10, $3A, $C0
    MORPH 10, $3A, $CC
    MORPH 10, $3B, $C0
    MORPH 10, $3B, $CC
    MORPH 10, $3C, $C0
    MORPH 10, $3C, $CC
    MORPH 10, $3D, $C0
    MORPH 10, $3D, $CC
    MORPH 10, $3E, $C0
    MORPH 10, $3E, $CC
    MORPH 10, $3F, $C0
    MORPH 10, $3F, $00
    MORPH 10, $3E, $C0
    MORPH 10, $3E, $00
    MORPH 10, $3D, $C0
    MORPH 10, $3D, $00
    MORPH 10, $3C, $C0
    MORPH 10, $3C, $00
    MORPH 10, $3B, $C0
    MORPH 10, $3B, $00
    MORPH 10, $3A, $C0
    MORPH 10, $3A, $00
    MORPH 10, $39, $C0
    MORPH 10, $39, $00
    MORPH 10, $38, $C0
    MORPH 10, $38, $00
    MORPH 10, $37, $C0
    MORPH 10, $37, $00
    MORPH 10, $36, $C0
    MORPH 10, $36, $00
    MORPH 10, $35, $C0
    MORPH 10, $35, $00
    MORPH 10, $34, $C0
    MORPH 10, $34, $00
    MORPH 10, $33, $C0
    MORPH 10, $33, $00
    MORPH 10, $32, $C0
    MORPH 10, $32, $00
    MORPH 10, $31, $C0
    MORPH 10, $31, $00
    TLOOP Morph_5A5D

Morph_5B14:
    MORPH 10, $30, $F0
    MORPH 10, $30, $FF
    MORPH 10, $31, $F0
    MORPH 10, $31, $FF
    MORPH 10, $32, $F0
    MORPH 10, $32, $FF
    MORPH 10, $33, $F0
    MORPH 10, $33, $FF
    MORPH 10, $34, $F0
    MORPH 10, $34, $FF
    MORPH 10, $35, $F0
    MORPH 10, $35, $FF
    MORPH 10, $36, $F0
    MORPH 10, $36, $FF
    MORPH 10, $37, $F0
    MORPH 10, $37, $FF
    MORPH 10, $38, $F0
    MORPH 10, $38, $FF
    MORPH 10, $39, $F0
    MORPH 10, $39, $FF
    MORPH 10, $3A, $F0
    MORPH 10, $3A, $FF
    MORPH 10, $3B, $F0
    MORPH 10, $3B, $FF
    MORPH 10, $3C, $F0
    MORPH 10, $3C, $FF
    MORPH 10, $3D, $F0
    MORPH 10, $3D, $FF
    MORPH 10, $3E, $F0
    MORPH 10, $3E, $FF
    MORPH 10, $3F, $F0
    MORPH 10, $3F, $00
    MORPH 10, $3E, $F0
    MORPH 10, $3E, $00
    MORPH 10, $3D, $F0
    MORPH 10, $3D, $00
    MORPH 10, $3C, $F0
    MORPH 10, $3C, $00
    MORPH 10, $3B, $F0
    MORPH 10, $3B, $00
    MORPH 10, $3A, $F0
    MORPH 10, $3A, $00
    MORPH 10, $39, $F0
    MORPH 10, $39, $00
    MORPH 10, $38, $F0
    MORPH 10, $38, $00
    MORPH 10, $37, $F0
    MORPH 10, $37, $00
    MORPH 10, $36, $F0
    MORPH 10, $36, $00
    MORPH 10, $35, $F0
    MORPH 10, $35, $00
    MORPH 10, $34, $F0
    MORPH 10, $34, $00
    MORPH 10, $33, $F0
    MORPH 10, $33, $00
    MORPH 10, $32, $F0
    MORPH 10, $32, $00
    MORPH 10, $31, $F0
    MORPH 10, $31, $00
    TLOOP Morph_5B14

TheEnd:
    db "-- THE END --" ; end-of-data marker left by the converter
