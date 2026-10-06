; Chicken Run sound test (GB, PD) - music/SFX data $4887-$7200

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
    db 127 ; priority
    dw Pat184
    db 3 ; ch4, Blank  (SFX $00)
    db 50 ; priority
    dw Sfx01
    db 2 ; ch2, Pickup  (SFX $01)
    db 50 ; priority
    dw Sfx02
    db 2 ; ch2, Put down  (SFX $02)
    db 50 ; priority
    dw Sfx03
    db 2 ; ch2, Get Corn1  (SFX $03)
    db 50 ; priority
    dw Sfx04
    db 2 ; ch2, Get Corn2  (SFX $04)
    db 50 ; priority
    dw Sfx05
    db 2 ; ch2, Drop Corn1  (SFX $05)
    db 50 ; priority
    dw Sfx06
    db 2 ; ch2, Drop Corn2  (SFX $06)
    db 50 ; priority
    dw Sfx07
    db 2 ; ch2, Trafficlght  (SFX $07)
    db 50 ; priority
    dw Sfx08
    db 2 ; ch2, Spring  (SFX $08)
    db 50 ; priority
    dw Sfx09
    db 2 ; ch2, Big spring  (SFX $09)
    db 50 ; priority
    dw Sfx0A
    db 3 ; ch4, Hole Dig  (SFX $0A)
    db 50 ; priority
    dw Sfx0B
    db 2 ; ch2, Hole Drop  (SFX $0B)
    db 50 ; priority
    dw Sfx0C
    db 2 ; ch2, Hole up  (SFX $0C)
    db 50 ; priority
    dw Sfx0D
    db 3 ; ch4, Switch clk  (SFX $0D)
    db 50 ; priority
    dw Sfx0E
    db 3 ; ch4, Key ins  (SFX $0E)
    db 50 ; priority
    dw Sfx0F
    db 3 ; ch4, Trap open  (SFX $0F)
    db 50 ; priority
    dw Sfx10
    db 3 ; ch4, Steam Vent  (SFX $10)
    db 100 ; priority
    dw Sfx11
    db 2 ; ch2, siren  (SFX $11)
    db 50 ; priority
    dw Sfx12
    db 2 ; ch2, Ch. escape  (SFX $12)
    db 50 ; priority
    dw Sfx13
    db 3 ; ch4, Elec shock  (SFX $13)
    db 50 ; priority
    dw Sfx14
    db 3 ; ch4, land, soft  (SFX $14)
    db 50 ; priority
    dw Sfx15
    db 3 ; ch4, land hard  (SFX $15)
    db 50 ; priority
    dw Sfx16
    db 2 ; ch2, Dazed  (SFX $16)
    db 50 ; priority
    dw Sfx17
    db 3 ; ch4, move cursor  (SFX $17)
    db 50 ; priority
    dw Sfx18
    db 2 ; ch2, select  (SFX $18)
    db 50 ; priority
    dw Sfx19
    db 3 ; ch4, error  (SFX $19)
    db 50 ; priority
    dw Sfx1A
    db 2 ; ch2  (SFX $1A)
    db 50 ; priority
    dw Sfx1B
    db 2 ; ch2  (SFX $1B)
    db 50 ; priority
    dw Sfx1C
    db 2 ; ch2  (SFX $1C)

Sfx01:
    NOTE 2, C7, $39
    NOTE 2, E7, $39
    NOTE 2, G7, $39
    KEYOFF 4
    SFXEND

Sfx02:
    NOTE 2, G6, $39
    NOTE 2, E6, $39
    NOTE 2, C6, $39
    KEYOFF 4
    SFXEND

Sfx03:
    NOTE 10, G6, $3A
    SFXEND

Sfx04:
    NOTE 2, A6, $3B
    KEYOFF 15
    SFXEND

Sfx05:
    NOTE 10, C5, $3A
    SFXEND

Sfx06:
    NOTE 2, D5, $3B
    KEYOFF 15
    SFXEND

Sfx07:
    NOTE 2, E7, $3C
    KEYOFF 2
    NOTE 2, B6, $3C
    KEYOFF 2
    NOTE 2, Fs7, $3C
    KEYOFF 2
    SFXEND

Sfx08:
    NOTE 40, B4, $3D
    SFXEND

Sfx09:
    NOTE 2, C5, $3D
    KEYOFF 50
    SFXEND

Sfx0A:
    NOTE 5, $24, $06
    KEYOFF 10
    SFXEND

Sfx0B:
    NOTE 6, G5, $3E
    KEYOFF 6
    SFXEND

Sfx0C:
    NOTE 6, A6, $43
    KEYOFF 6
    SFXEND

Sfx0D:
    NOTE 2, $24, $08
    NOTE 4, $24, $00
    NOTE 2, $24, $09
    KEYOFF 4
    SFXEND

Sfx0E:
    NOTE 10, $24, $0A
    KEYOFF 4
    SFXEND

Sfx0F:
    NOTE 6, $24, $0B
    KEYOFF 6
    SFXEND

Sfx10:
    NOTE 25, $24, $0C
    KEYOFF 35
    SFXEND

Sfx11:
    NOTE 30, G5, $3F
    KEYOFF 3
    SFXEND

Sfx12:
    NOTE 3, F6, $03
    KEYOFF 1
    NOTE 1, F6, $03
    KEYOFF 1
    NOTE 1, F6, $03
    KEYOFF 1
    NOTE 3, F6, $03
    KEYOFF 1
    NOTE 3, F6, $03
    KEYOFF 1
    NOTE 3, C6, $03
    KEYOFF 1
    NOTE 3, F6, $03
    KEYOFF 1
    NOTE 15, F6, $06
    SFXEND

Sfx13:
    NOTE 40, $30, $0D
    KEYOFF 10
    SFXEND

Sfx14:
    NOTE 2, $24, $0E
    KEYOFF 10
    SFXEND

Sfx15:
    NOTE 12, $24, $0E
    SFXEND

Sfx16:
    NOTE 50, C7, $41
    KEYOFF 50
    SFXEND

Sfx17:
    NOTE 4, $24, $0F
    KEYOFF 4
    SFXEND

Sfx18:
    NOTE 40, G5, $42
    SFXEND

Sfx19:
    NOTE 5, $24, $10
    KEYOFF 5
    SFXEND

Sfx1A:
    NOTE 2, G5, $03
    NOTE 2, B5, $03
    NOTE 2, D6, $03
    KEYOFF 4
    SFXEND

Sfx1B:
    NOTE 2, C6, $03
    NOTE 2, D6, $03
    NOTE 2, E6, $03
    NOTE 2, Fs6, $03
    NOTE 2, E6, $03
    NOTE 2, D6, $03
    NOTE 2, C6, $03
    KEYOFF 4
    SFXEND

Sfx1C:
    NOTE 2, C5, $03
    NOTE 2, E6, $03
    NOTE 2, G5, $03
    NOTE 2, C6, $03
    NOTE 2, C5, $03
    NOTE 2, E6, $03
    NOTE 2, G5, $03
    NOTE 2, C6, $03
    NOTE 2, C5, $03
    NOTE 2, E6, $03
    NOTE 2, G5, $03
    NOTE 2, C6, $03
    NOTE 2, C5, $03
    NOTE 2, E6, $03
    NOTE 2, G5, $03
    NOTE 2, C6, $03
    NOTE 2, C5, $03
    NOTE 2, E6, $03
    NOTE 2, G5, $03
    NOTE 2, C6, $03
    KEYOFF 4
    SFXEND

SongTable:
    ; song $00: Music off
    dw Song00_Ch1, Song00_Ch2, Song00_Ch3, Song00_Ch4
    db 8 ; tempo (frames per tick)
    dw Morph_7009 - 2 ; wave morph
    dw Wave_6FF9 ; wave
    ; song $01: Title
    dw Song01_Ch1, Song01_Ch2, Song01_Ch3, Song01_Ch4
    db 7 ; tempo (frames per tick)
    dw Morph_708D - 2 ; wave morph
    dw Wave_7045 ; wave
    ; song $02: Briefing
    dw Song02_Ch1, Song02_Ch2, Song02_Ch3, Song02_Ch4
    db 8 ; tempo (frames per tick)
    dw Morph_7055 - 2 ; wave morph
    dw Wave_7045 ; wave
    ; song $03: Daytime 1
    dw Song03_Ch1, Song03_Ch2, Song03_Ch3, Song03_Ch4
    db 8 ; tempo (frames per tick)
    dw Morph_714A - 2 ; wave morph
    dw Wave_7025 ; wave
    ; song $04: Daytime 2
    dw Song04_Ch1, Song04_Ch2, Song04_Ch3, Song04_Ch4
    db 7 ; tempo (frames per tick)
    dw Morph_706B - 2 ; wave morph
    dw Wave_705B ; wave
    ; song $05: Pie 1
    dw Song05_Ch1, Song05_Ch2, Song05_Ch3, Song05_Ch4
    db 6 ; tempo (frames per tick)
    dw Morph_714A - 2 ; wave morph
    dw Wave_7025 ; wave
    ; song $06: Pie 2
    dw Song06_Ch1, Song06_Ch2, Song06_Ch3, Song06_Ch4
    db 9 ; tempo (frames per tick)
    dw Morph_714A - 2 ; wave morph
    dw Wave_7025 ; wave
    ; song $07: Success
    dw Song07_Ch1, Song07_Ch2, Song07_Ch3, Song07_Ch4
    db 7 ; tempo (frames per tick)
    dw Morph_706B - 2 ; wave morph
    dw Wave_705B ; wave
    ; song $08: Gameover
    dw Song08_Ch1, Song08_Ch2, Song08_Ch3, Song08_Ch4
    db 12 ; tempo (frames per tick)
    dw Morph_7055 - 2 ; wave morph
    dw Wave_7045 ; wave

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
    dw Pat104                   ; $68
    dw Pat105                   ; $69
    dw Pat106                   ; $6A
    dw Pat107                   ; $6B
    dw Pat108                   ; $6C
    dw Pat109                   ; $6D
    dw Pat110                   ; $6E
    dw Pat111                   ; $6F
    dw Pat112                   ; $70
    dw Pat113                   ; $71
    dw Pat114                   ; $72
    dw Pat115                   ; $73
    dw Pat116                   ; $74
    dw Pat117                   ; $75
    dw Pat118                   ; $76
    dw Pat119                   ; $77
    dw Pat120                   ; $78
    dw Pat121                   ; $79
    dw Pat122                   ; $7A
    dw Pat123                   ; $7B
    dw Pat124                   ; $7C
    dw Pat125                   ; $7D
    dw Pat126                   ; $7E
    dw Pat127                   ; $7F
    dw Pat128                   ; $80
    dw Pat129                   ; $81
    dw Pat130                   ; $82
    dw Pat131                   ; $83
    dw Pat132                   ; $84
    dw Pat133                   ; $85
    dw Pat134                   ; $86
    dw Pat135                   ; $87
    dw Pat136                   ; $88
    dw Pat137                   ; $89
    dw Pat138                   ; $8A
    dw Pat139                   ; $8B
    dw Pat140                   ; $8C
    dw Pat141                   ; $8D
    dw Pat142                   ; $8E
    dw Pat143                   ; $8F
    dw Pat144                   ; $90
    dw Pat145                   ; $91
    dw Pat146                   ; $92
    dw Pat147                   ; $93
    dw Pat148                   ; $94
    dw Pat149                   ; $95
    dw Pat150                   ; $96
    dw Pat151                   ; $97
    dw Pat152                   ; $98
    dw Pat153                   ; $99
    dw Pat154                   ; $9A
    dw Pat155                   ; $9B
    dw Pat156                   ; $9C
    dw Pat157                   ; $9D
    dw Pat158                   ; $9E
    dw Pat159                   ; $9F
    dw Pat160                   ; $A0
    dw Pat161                   ; $A1
    dw Pat162                   ; $A2
    dw Pat163                   ; $A3
    dw Pat164                   ; $A4
    dw Pat165                   ; $A5
    dw Pat166                   ; $A6
    dw Pat167                   ; $A7
    dw Pat168                   ; $A8
    dw Pat169                   ; $A9
    dw Pat170                   ; $AA
    dw Pat171                   ; $AB
    dw Pat172                   ; $AC
    dw Pat173                   ; $AD
    dw Pat175                   ; $AE
    dw Pat175                   ; $AF
    dw Pat176                   ; $B0
    dw Pat177                   ; $B1
    dw Pat178                   ; $B2
    dw Pat179                   ; $B3
    dw Pat180                   ; $B4
    dw Pat181                   ; $B5
    dw Pat182                   ; $B6
    dw Pat183                   ; $B7
    dw Pat184                   ; $B8
    dw Pat184                   ; $B9
    dw Pat184                   ; $BA
    dw Pat184                   ; $BB
    dw Pat184                   ; $BC
    dw Pat184                   ; $BD
    dw Pat190                   ; $BE
    dw Pat191                   ; $BF
    dw Pat192                   ; $C0
    dw Pat193                   ; $C1
    dw Pat194                   ; $C2
    dw Pat195                   ; $C3
    dw Pat196                   ; $C4

InstrumentTable:
    dw Ins00                    ; $00
    dw Ins01                    ; $01
    dw Ins01                    ; $02
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
    dw Ins24                    ; $18
    dw Ins25                    ; $19
    dw Ins26                    ; $1A
    dw Ins27                    ; $1B
    dw Ins28                    ; $1C
    dw Ins29                    ; $1D
    dw Ins28                    ; $1E
    dw Ins31                    ; $1F
    dw Ins32                    ; $20
    dw Ins33                    ; $21
    dw Ins34                    ; $22
    dw Ins35                    ; $23
    dw Ins36                    ; $24
    dw Ins37                    ; $25
    dw Ins38                    ; $26
    dw Ins39                    ; $27
    dw Ins40                    ; $28
    dw Ins41                    ; $29
    dw Ins42                    ; $2A
    dw Ins43                    ; $2B
    dw Ins44                    ; $2C
    dw Ins45                    ; $2D
    dw Ins46                    ; $2E
    dw Ins47                    ; $2F
    dw Ins48                    ; $30
    dw Ins49                    ; $31
    dw Ins50                    ; $32
    dw Ins51                    ; $33
    dw Ins52                    ; $34
    dw Ins53                    ; $35
    dw Ins54                    ; $36
    dw Ins55                    ; $37
    dw Ins56                    ; $38
    dw Ins57                    ; $39
    dw Ins58                    ; $3A
    dw Ins59                    ; $3B
    dw Ins60                    ; $3C
    dw Ins61                    ; $3D
    dw Ins62                    ; $3E
    dw Ins63                    ; $3F
    dw Ins64                    ; $40
    dw Ins65                    ; $41
    dw Ins66                    ; $42
    dw Ins67                    ; $43

NoiseInstrumentTable:
    dw NoiseIns00               ; $00
    dw NoiseIns01               ; $01
    dw NoiseIns02               ; $02
    dw NoiseIns03               ; $03
    dw NoiseIns04               ; $04
    dw NoiseIns05               ; $05
    dw NoiseIns06               ; $06
    dw NoiseIns06               ; $07
    dw NoiseIns08               ; $08
    dw NoiseIns09               ; $09
    dw NoiseIns10               ; $0A
    dw NoiseIns11               ; $0B
    dw NoiseIns12               ; $0C
    dw NoiseIns13               ; $0D
    dw NoiseIns14               ; $0E
    dw NoiseIns15               ; $0F
    dw NoiseIns16               ; $10

Song01_Ch1:
    STEP 0, $05
    STEP 0, $06
    STEP 0, $07
    STEP 0, $06
    STEP 0, $05
    STEP 0, $08
    STEP 0, $15
    STEP 0, $10
    STEP 0, $14
    STEP 0, $14
    STEP 0, $18
    STEP 0, $14
    STEP 0, $14
    STEP 0, $19
    STEP 2, $07
    STEP 2, $06
    STEP 2, $05
    STEP 2, $08
    STEP 2, $15
    STEP 2, $10
    STEP 2, $14
    STEP 2, $14
    STEP 2, $18
    STEP 2, $14
    STEP 2, $14
    STEP 2, $19
    STEP -2, $07
    STEP -2, $06
    STEP -2, $05
    STEP -2, $08
    STEP -2, $15
    STEP -2, $10
    STEP -2, $14
    STEP -2, $14
    STEP -2, $18
    STEP -2, $14
    STEP -2, $14
    STEP -2, $16

Song01_Ch2:
    STEP 0, $32
    STEP 0, $33
    STEP 0, $32
    STEP 0, $33
    STEP 0, $34
    STEP 0, $43
    STEP 0, $44
    STEP 0, $45
    STEP -4, $43
    STEP 0, $44
    STEP 0, $45
    STEP 0, $46
    STEP 0, $47
    STEP 2, $32
    STEP 2, $33
    STEP 2, $34
    STEP 2, $43
    STEP 2, $44
    STEP 2, $45
    STEP -2, $43
    STEP 2, $44
    STEP 2, $45
    STEP 2, $46
    STEP 2, $47
    STEP -2, $32
    STEP -2, $33
    STEP -2, $34
    STEP -2, $43
    STEP -2, $44
    STEP -2, $45
    STEP -6, $43
    STEP -2, $44
    STEP -2, $45
    STEP -2, $46
    STEP -2, $1A

Song01_Ch3:
    STEP 0, $17
    STEP 0, $00
    STEP 0, $00
    STEP 0, $1B
    STEP 0, $1C
    STEP 0, $1D
    STEP 0, $1E
    STEP 0, $1F
    STEP 0, $1C
    STEP 0, $20
    STEP 0, $2B
    STEP 0, $2C
    STEP 0, $2D
    STEP 0, $2B
    STEP 0, $2F
    STEP 0, $31
    STEP 0, $00
    STEP 2, $1B
    STEP 2, $1C
    STEP 2, $1D
    STEP 2, $1E
    STEP 2, $1F
    STEP 2, $1C
    STEP 2, $20
    STEP 2, $2B
    STEP 2, $2C
    STEP 2, $2D
    STEP 2, $2B
    STEP 2, $2F
    STEP 2, $31
    STEP -2, $00
    STEP -2, $1B
    STEP -2, $1C
    STEP -2, $1D
    STEP -2, $1E
    STEP -2, $1F
    STEP -2, $1C
    STEP -2, $20
    STEP -2, $2B
    STEP -2, $2C
    STEP -2, $2D
    STEP -2, $2B
    STEP -2, $2F
    STEP -2, $30

Song01_Ch4:
    STEP 0, $48

Song02_Ch1:
    STEP 0, $09
    STEP 0, $0A
    STEP 0, $0B
    STEP 0, $0C
    STEP 0, $09
    STEP 0, $0A
    STEP 0, $0B
    STEP 0, $0C
    STEP 3, $09
    STEP 3, $0A
    STEP 3, $0B
    STEP 3, $0C
    STEP 3, $09
    STEP 3, $0A
    STEP 3, $0B
    STEP 3, $21

Song02_Ch2:
    STEP 0, $11
    STEP 0, $12
    STEP 0, $11
    STEP 0, $13
    STEP 0, $11
    STEP 0, $12
    STEP 0, $11
    STEP 0, $13
    STEP 3, $11
    STEP 3, $12
    STEP 3, $11
    STEP 3, $13
    STEP 3, $11
    STEP 3, $12
    STEP 3, $11
    STEP 3, $22

Song02_Ch3:
    STEP 12, $0D
    STEP 12, $0E
    STEP 12, $0F
    STEP 12, $24
    STEP 12, $0D
    STEP 12, $0E
    STEP 12, $0F
    STEP 12, $24
    STEP 3, $0D
    STEP 3, $0E
    STEP 3, $0F
    STEP 3, $24
    STEP 3, $0D
    STEP 3, $0E
    STEP 3, $0F
    STEP 3, $23

Song02_Ch4:
    STEP 0, $25

Song03_Ch1:
    STEP 0, $26
    STEP 0, $27
    STEP 0, $28
    STEP 0, $26
    STEP 0, $27
    STEP 0, $28
    STEP 5, $26
    STEP 5, $27
    STEP 5, $28
    STEP 0, $26
    STEP 0, $27
    STEP 0, $28
    STEP 0, $26
    STEP 0, $27
    STEP 0, $28
    STEP 0, $26
    STEP 0, $27
    STEP 0, $28
    STEP 5, $26
    STEP 0, $3F
    STEP 0, $28
    STEP 7, $26
    STEP 0, $4D
    STEP 5, $28
    STEP 0, $26
    STEP 0, $27
    STEP 0, $28
    STEP 0, $26
    STEP 0, $27
    STEP 0, $28
    STEP 5, $26
    STEP 0, $3F
    STEP 0, $28
    STEP 7, $26
    STEP 0, $4D
    STEP 5, $28
    STEP 0, $4F
    STEP 0, $50
    STEP 0, $51

Song03_Ch2:
    STEP 0, $29
    STEP 0, $2A
    STEP 0, $35
    STEP 0, $29
    STEP 0, $2A
    STEP 0, $35
    STEP 5, $29
    STEP 5, $2A
    STEP 5, $35
    STEP 0, $29
    STEP 0, $2A
    STEP 0, $35
    STEP 0, $29
    STEP 0, $2A
    STEP 0, $35
    STEP 0, $29
    STEP 0, $2A
    STEP 0, $35
    STEP 5, $29
    STEP 0, $42
    STEP 0, $35
    STEP 7, $29
    STEP 0, $4E
    STEP 5, $35
    STEP 0, $29
    STEP 0, $2A
    STEP 0, $35
    STEP 0, $29
    STEP 0, $2A
    STEP 0, $35
    STEP 5, $29
    STEP 0, $42
    STEP 0, $35
    STEP 7, $29
    STEP 0, $4E
    STEP 5, $35
    STEP 0, $52
    STEP 0, $53
    STEP 0, $54

Song03_Ch3:
    STEP 0, $17
    STEP 0, $00
    STEP 0, $36
    STEP 0, $37
    STEP 0, $38
    STEP 0, $39
    STEP 5, $37
    STEP 5, $38
    STEP 5, $39
    STEP 0, $37
    STEP 0, $38
    STEP 0, $39
    STEP 0, $3A
    STEP 0, $00
    STEP 0, $00
    STEP 0, $3B
    STEP 0, $3C
    STEP 0, $3D
    STEP 0, $3E
    STEP 0, $40
    STEP 0, $41
    STEP 0, $49
    STEP 0, $4A
    STEP 0, $4B
    STEP 0, $4C
    STEP 0, $00
    STEP 0, $00
    STEP 0, $3B
    STEP 0, $3C
    STEP 0, $3D
    STEP 0, $3E
    STEP 0, $40
    STEP 0, $41
    STEP 0, $49
    STEP 0, $4A
    STEP 0, $4B
    STEP 0, $55
    STEP 0, $56
    STEP 0, $57

Song03_Ch4:
    STEP 0, $58

Song04_Ch1:
    STEP 0, $59
    STEP 0, $59
    STEP 0, $59
    STEP 0, $59
    STEP 0, $5A
    STEP 0, $59
    STEP 0, $59
    STEP 0, $5B
    STEP 0, $5C
    STEP 0, $5D
    STEP 0, $5E

Song04_Ch2:
    STEP 0, $66
    STEP 0, $67
    STEP 0, $68
    STEP 0, $67
    STEP 0, $69
    STEP 0, $6A
    STEP 0, $6B
    STEP 0, $6C

Song04_Ch3:
    STEP 0, $5F
    STEP 12, $60
    STEP 12, $61
    STEP 12, $60
    STEP 12, $62
    STEP 12, $63
    STEP 12, $64
    STEP 0, $65

Song04_Ch4:
    STEP 0, $6D

Song05_Ch1:
    STEP 0, $6E
    STEP 0, $6E
    STEP 0, $71
    STEP 0, $72
    STEP 0, $6E
    STEP 0, $6E
    STEP 0, $73
    STEP 0, $74
    STEP 0, $75
    STEP 0, $75
    STEP 0, $76
    STEP 0, $76
    STEP 0, $77
    STEP -8, $6E
    STEP -8, $6E
    STEP 0, $78
    STEP 0, $79
    STEP 1, $79
    STEP 0, $7A
    STEP 0, $7B
    STEP 0, $7C
    STEP 0, $7D
    STEP 0, $7A
    STEP 0, $7B
    STEP 0, $7C
    STEP 0, $98

Song05_Ch2:
    STEP 0, $70
    STEP 0, $70
    STEP 0, $8D
    STEP 2, $8D
    STEP 0, $70
    STEP 0, $70
    STEP 0, $8D
    STEP 2, $8D
    STEP 0, $8E
    STEP 0, $8E
    STEP -3, $8E
    STEP -3, $8E
    STEP 0, $8F
    STEP 0, $90
    STEP 0, $90
    STEP 0, $91
    STEP 0, $92
    STEP 1, $92
    STEP 0, $93
    STEP 0, $94
    STEP 0, $93
    STEP -5, $93
    STEP 0, $93
    STEP 0, $94
    STEP 0, $93
    STEP -5, $97

Song05_Ch3:
    STEP 0, $6F
    STEP 0, $6F
    STEP 0, $7E
    STEP 2, $7E
    STEP 0, $6F
    STEP 0, $6F
    STEP 0, $7F
    STEP 0, $80
    STEP 0, $81
    STEP 0, $81
    STEP 0, $82
    STEP 0, $83
    STEP 0, $84
    STEP 0, $85
    STEP 0, $86
    STEP 0, $87
    STEP 0, $88
    STEP 0, $89
    STEP 0, $8A
    STEP 0, $8B
    STEP 0, $8A
    STEP 0, $8C
    STEP 0, $8A
    STEP 0, $8B
    STEP 0, $8A
    STEP 0, $96

Song05_Ch4:
    STEP 0, $95

Song06_Ch1:
    STEP 0, $99
    STEP 0, $99
    STEP 5, $99
    STEP 0, $99
    STEP 0, $9A
    STEP 0, $9B
    STEP 0, $99
    STEP 0, $99
    STEP 5, $99
    STEP 0, $99
    STEP 0, $9A
    STEP 0, $9B
    STEP 0, $99
    STEP 0, $99
    STEP 5, $99
    STEP 0, $99
    STEP 0, $9A
    STEP 0, $9B
    STEP 0, $99
    STEP 0, $99
    STEP 5, $99
    STEP 0, $99
    STEP 0, $9A
    STEP 0, $9B
    STEP 0, $99
    STEP 0, $99
    STEP 5, $99
    STEP 0, $99
    STEP 0, $9A
    STEP 0, $9B
    STEP 0, $99
    STEP 0, $99
    STEP 5, $99
    STEP 0, $99
    STEP 0, $9A
    STEP 0, $A9

Song06_Ch2:
    STEP 0, $9C
    STEP 0, $9C
    STEP 5, $9C
    STEP 0, $9C
    STEP 0, $9D
    STEP 0, $9E
    STEP 0, $9C
    STEP 0, $9C
    STEP 5, $9C
    STEP 0, $9C
    STEP 0, $9D
    STEP 0, $9E
    STEP 0, $9C
    STEP 0, $9C
    STEP 5, $9C
    STEP 0, $9C
    STEP 0, $9D
    STEP 0, $9E
    STEP 0, $9C
    STEP 0, $9C
    STEP 5, $9C
    STEP 0, $9C
    STEP 0, $9D
    STEP 0, $9E
    STEP 0, $9C
    STEP 0, $9C
    STEP 5, $9C
    STEP 0, $9C
    STEP 0, $9D
    STEP 0, $9E
    STEP 0, $9C
    STEP 0, $9C
    STEP 5, $9C
    STEP 0, $9C
    STEP 0, $9D
    STEP 0, $AA

Song06_Ch3:
    STEP 0, $AC
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 0, $A0
    STEP 0, $A1
    STEP 5, $A0
    STEP 0, $A2
    STEP 0, $A3
    STEP 0, $A0
    STEP 0, $A0
    STEP 0, $A0
    STEP 0, $A1
    STEP 0, $A2
    STEP 0, $A3
    STEP 0, $A6
    STEP 0, $A4
    STEP 0, $A4
    STEP 5, $A4
    STEP 0, $A4
    STEP 0, $A6
    STEP 0, $A0
    STEP 0, $A7
    STEP 0, $A7
    STEP 0, $A7
    STEP 0, $A7
    STEP 0, $A7
    STEP 0, $A7
    STEP 0, $A8
    STEP 0, $A8
    STEP 0, $A8
    STEP 0, $A8
    STEP 0, $A8
    STEP 0, $AB

Song06_Ch4:
    STEP 0, $AD

Song07_Ch1:
    STEP 0, $B1
    STEP 0, $B2
    STEP 0, $B3
    STEP 0, $04

Song07_Ch2:
    STEP -12, $B4
    STEP -12, $B5
    STEP 0, $B6
    STEP 0, $04

Song07_Ch3:
    STEP 0, $AF
    STEP 0, $B0
    STEP 0, $02

Song07_Ch4:
    STEP 0, $B7
    STEP 0, $04

Song08_Ch1:
    STEP 0, $BE
    STEP 0, $BF
    STEP 0, $04

Song08_Ch2:
    STEP 0, $C0
    STEP 0, $C1
    STEP 0, $04

Song08_Ch3:
    STEP 0, $C2
    STEP 0, $C3
    STEP 0, $02

Song08_Ch4:
    STEP 0, $C4
    STEP 0, $04

Song00_Ch1_Loop:
    STEP 0, $04

Song00_Ch1:
    STEP 0, $01

Song00_Ch2:
    STEP 0, $01

Song00_Ch3:
    STEP 0, $02

Song00_Ch4:
    STEP 0, $03

Pat000:
    HOLD 16
    PATEND

Pat001:
    NOTE 16, C2, $00
    SONGJUMP Song00_Ch1_Loop

Pat002:
    NOTE 16, C2, $01
    SONGJUMP Song00_Ch1_Loop

Pat003:
    NOTE 16, $00, $00
    SONGJUMP Song00_Ch1_Loop

Pat004:
    HOLD 16
    SONGJUMP Song00_Ch1_Loop

Pat005:
    NOTE 2, C3, $03
    NOTE 2, G4, $09
    NOTE 2, E3, $03
    NOTE 2, G4, $09
    NOTE 2, G3, $03
    NOTE 2, G4, $09
    NOTE 2, E3, $03
    NOTE 2, G4, $09
    PATEND

Pat006:
    NOTE 2, F3, $03
    NOTE 2, A4, $0F
    NOTE 2, D3, $03
    NOTE 1, A4, $0F
    NOTE 1, A3, $03
    NOTE 2, G3, $03
    NOTE 2, F3, $03
    NOTE 2, E3, $03
    NOTE 2, D3, $03
    PATEND

Pat007:
    NOTE 2, C3, $03
    NOTE 2, G4, $09
    NOTE 2, E3, $03
    NOTE 2, G4, $09
    NOTE 2, A3, $03
    NOTE 2, G4, $09
    NOTE 2, G3, $03
    NOTE 2, G4, $09
    PATEND

Pat008:
    NOTE 2, F3, $03
    NOTE 2, A4, $0F
    NOTE 2, G3, $03
    NOTE 2, B4, $0F
    NOTE 2, C3, $03
    NOTE 2, E4, $0F
    NOTE 2, C3, $03
    NOTE 2, E3, $03
    NOTE 2, F3, $03
    NOTE 2, A4, $0F
    NOTE 2, E3, $03
    NOTE 2, C5, $06
    NOTE 2, D3, $03
    NOTE 2, B4, $0F
    NOTE 2, G2, $03
    NOTE 2, B4, $0F
    NOTE 2, A2, $03
    NOTE 2, A4, $07
    NOTE 2, C3, $03
    NOTE 2, G4, $09
    NOTE 2, D3, $03
    NOTE 6, D2, $03
    NOTE 2, G2, $03
    NOTE 2, G4, $09
    NOTE 2, G2, $03
    NOTE 2, G4, $09
    NOTE 2, A2, $03
    NOTE 2, A4, $07
    NOTE 2, C3, $03
    NOTE 2, A4, $07
    NOTE 2, F3, $03
    NOTE 2, A4, $0F
    NOTE 2, F3, $03
    NOTE 2, A4, $0F
    NOTE 2, E3, $03
    NOTE 2, G4, $09
    NOTE 2, E3, $03
    NOTE 2, G4, $09
    NOTE 2, Ds3, $03
    NOTE 2, G4, $0F
    NOTE 2, G3, $03
    NOTE 2, G4, $0F
    NOTE 2, F3, $03
    NOTE 2, A4, $0F
    NOTE 2, A3, $03
    NOTE 2, A4, $0F
    NOTE 2, G3, $03
    NOTE 2, G4, $2D
    NOTE 2, D3, $03
    NOTE 2, G4, $2D
    NOTE 8, G2, $03
    NOTE 2, G2, $03
    NOTE 2, G4, $2D
    NOTE 2, G2, $03
    NOTE 2, G4, $2D
    NOTE 2, G2, $03
    NOTE 2, G4, $06
    NOTE 2, G2, $03
    NOTE 2, G4, $06
    PATEND

Pat016:
    NOTE 2, F3, $03
    NOTE 2, C5, $09
    NOTE 2, E3, $03
    NOTE 2, C5, $09
    NOTE 2, D3, $03
    NOTE 2, C5, $09
    NOTE 2, F3, $03
    NOTE 2, A4, $0F
    NOTE 2, E2, $03
    NOTE 4, B4, $09
    NOTE 2, Gs2, $03
    NOTE 8, A2, $03
    HOLD 12
    NOTE 4, Gs2, $03
    NOTE 8, G2, $03
    NOTE 4, G2, $03
    NOTE 2, C4, $1D
    NOTE 1, C4, $1D
    NOTE 1, C4, $1D
    PATEND

Pat020:
    NOTE 2, C3, $03
    NOTE 2, E5, $0F
    NOTE 2, C4, $1D
    NOTE 4, As2, $03
    NOTE 2, C4, $1D
    NOTE 4, A2, $03
    PATEND

Pat021:
    NOTE 2, G2, $03
    NOTE 2, G4, $09
    NOTE 2, G2, $03
    NOTE 2, G4, $09
    NOTE 2, G2, $03
    NOTE 2, G4, $09
    NOTE 2, G2, $03
    NOTE 2, G4, $09
    NOTE 2, G2, $03
    NOTE 2, A4, $0F
    NOTE 2, G2, $03
    NOTE 2, A4, $0F
    NOTE 2, G2, $03
    NOTE 2, A4, $0F
    NOTE 2, G2, $03
    NOTE 2, G4, $09
    NOTE 2, G2, $03
    NOTE 2, G4, $09
    NOTE 2, G2, $03
    NOTE 2, G4, $09
    NOTE 2, G2, $03
    NOTE 2, E4, $0F
    NOTE 2, G2, $03
    NOTE 2, E4, $0F
    PATEND

Pat022:
    NOTE 2, G3, $03
    NOTE 2, As4, $0B
    NOTE 2, Ds3, $03
    NOTE 2, G4, $0F
    NOTE 2, F3, $03
    NOTE 2, A4, $0F
    NOTE 2, D3, $03
    NOTE 2, F4, $0B
    NOTE 2, Ds3, $03
    NOTE 2, D3, $03
    NOTE 2, C3, $03
    NOTE 2, As2, $03
    NOTE 4, A2, $03
    NOTE 4, A3, $03
    SONGJUMP Song01_Ch1

Pat023:
    NOTE 16, C4, $01
    PATEND

Pat024:
    NOTE 2, Gs2, $03
    NOTE 2, F4, $07
    NOTE 2, F2, $03
    NOTE 2, F4, $07
    NOTE 2, As2, $03
    NOTE 2, C4, $1D
    NOTE 2, G2, $03
    NOTE 1, C4, $1D
    NOTE 1, C4, $1D
    PATEND

Pat025:
    NOTE 2, G3, $03
    NOTE 2, As4, $0B
    NOTE 2, Ds3, $03
    NOTE 2, G4, $0F
    NOTE 2, F3, $03
    NOTE 2, A4, $0F
    NOTE 2, D3, $03
    NOTE 2, F4, $0B
    NOTE 2, Ds3, $03
    NOTE 2, D3, $03
    NOTE 2, C3, $03
    NOTE 2, As2, $03
    NOTE 4, A2, $03
    NOTE 4, A3, $03
    PATEND

Pat026:
    NOTE 2, G4, $0F
    NOTE 2, F5, $0B
    NOTE 2, Ds5, $0B
    NOTE 2, A4, $08
    NOTE 4, A4, $06
    NOTE 4, Cs5, $31
    SONGJUMP Song01_Ch2

Pat027:
    HOLD 12
    NOTE 1, C6, $2C
    KEYOFF 1
    NOTE 1, D6, $2C
    KEYOFF 1
    PATEND

Pat028:
    NOTE 4, E6, $2C
    NOTE 1, F6, $2C
    KEYOFF 2
    NOTE 1, G6, $2C
    NOTE 4, E6, $2C
    NOTE 1, D6, $2C
    KEYOFF 1
    NOTE 1, C6, $2C
    KEYOFF 1
    PATEND

Pat029:
    NOTE 1, A5, $2C
    NOTE 2, C6, $2C
    KEYOFF 1
    NOTE 1, C6, $2C
    KEYOFF 1
    NOTE 1, F5, $2C
    KEYOFF 1
    NOTE 3, G5, $2C
    KEYOFF 3
    NOTE 1, C6, $2C
    NOTE 1, B5, $2C
    PATEND

Pat030:
    NOTE 2, A5, $2C
    KEYOFF 1
    NOTE 1, B5, $2C
    NOTE 1, A5, $2C
    KEYOFF 1
    NOTE 1, G5, $2C
    KEYOFF 1
    NOTE 1, E5, $2C
    KEYOFF 1
    NOTE 1, D5, $2C
    KEYOFF 1
    NOTE 1, C5, $2C
    KEYOFF 1
    NOTE 2, D5, $2C
    PATEND

Pat031:
    NOTE 8, E5, $2C
    KEYOFF 4
    NOTE 2, C6, $2C
    NOTE 2, D6, $2C
    PATEND

Pat032:
    NOTE 1, A6, $2C
    KEYOFF 1
    NOTE 4, B6, $2C
    NOTE 2, C7, $2C
    NOTE 2, G6, $2C
    KEYOFF 4
    NOTE 1, G6, $2C
    NOTE 1, A6, $2C
    NOTE 3, As6, $2C
    NOTE 1, A6, $2C
    NOTE 1, As6, $2C
    KEYOFF 1
    NOTE 1, C7, $2C
    KEYOFF 1
    NOTE 1, As6, $2C
    KEYOFF 1
    NOTE 1, A6, $2C
    KEYOFF 1
    NOTE 1, G6, $2C
    KEYOFF 1
    NOTE 1, F6, $2C
    KEYOFF 1
    NOTE 10, G6, $2C
    KEYOFF 2
    NOTE 3, G5, $2E
    NOTE 1, C6, $2E
    NOTE 3, D6, $2E
    KEYOFF 1
    NOTE 3, D6, $2E
    KEYOFF 1
    NOTE 4, D6, $2E
    NOTE 3, G5, $2E
    NOTE 1, D6, $2E
    NOTE 3, E6, $2E
    KEYOFF 1
    NOTE 3, E6, $2E
    KEYOFF 1
    NOTE 3, E6, $2E
    KEYOFF 1
    NOTE 3, C6, $2E
    NOTE 1, G6, $2E
    NOTE 5, A6, $2E
    KEYOFF 1
    NOTE 1, A6, $2E
    KEYOFF 1
    NOTE 4, C7, $2E
    NOTE 3, B6, $2E
    NOTE 1, C7, $2E
    NOTE 4, G6, $2E
    NOTE 1, A6, $2E
    KEYOFF 1
    NOTE 1, G6, $2E
    NOTE 1, F6, $2E
    NOTE 4, E6, $2E
    NOTE 3, G5, $2E
    NOTE 1, C6, $2E
    NOTE 3, D6, $2E
    KEYOFF 1
    NOTE 2, D6, $2E
    KEYOFF 1
    NOTE 1, E6, $2E
    NOTE 1, D6, $2E
    KEYOFF 1
    NOTE 1, C6, $2E
    KEYOFF 1
    NOTE 1, A5, $2E
    KEYOFF 1
    NOTE 1, C6, $2E
    KEYOFF 1
    HOLD 2
    NOTE 2, E6, $2E
    KEYOFF 2
    NOTE 2, Gs6, $2E
    NOTE 8, C7, $32
    HOLD 10
    KEYOFF 2
    NOTE 3, C6, $2E
    NOTE 1, D6, $2E
    NOTE 1, E6, $2E
    KEYOFF 1
    NOTE 4, F6, $2E
    NOTE 1, G6, $2E
    KEYOFF 1
    NOTE 3, E6, $2E
    KEYOFF 1
    NOTE 3, D6, $2E
    KEYOFF 1
    PATEND

Pat043:
    NOTE 2, C5, $1B
    NOTE 4, C5, $1B
    NOTE 4, Ds5, $1B
    NOTE 2, C5, $14
    NOTE 4, C5, $14
    PATEND

Pat044:
    NOTE 2, C5, $1B
    NOTE 4, C5, $1B
    NOTE 6, Ds5, $1B
    NOTE 2, C5, $26
    NOTE 2, Ds5, $26
    PATEND

Pat045:
    NOTE 3, F5, $26
    KEYOFF 1
    NOTE 2, F5, $26
    KEYOFF 1
    NOTE 1, G5, $26
    NOTE 2, F5, $26
    NOTE 2, Ds5, $26
    NOTE 2, C5, $26
    NOTE 2, As4, $26
    PATEND

Pat046:
    KEYOFF 16
    PATEND

Pat047:
    NOTE 2, C5, $1B
    NOTE 4, C5, $1B
    NOTE 6, Ds5, $1B
    NOTE 2, G5, $26
    NOTE 2, A5, $26
    NOTE 4, As5, $26
    NOTE 2, C6, $26
    KEYOFF 1
    NOTE 1, As5, $26
    NOTE 2, A5, $26
    NOTE 2, G5, $26
    NOTE 2, A5, $26
    NOTE 2, F5, $26
    PATEND

Pat048:
    NOTE 2, G5, $26
    NOTE 2, A5, $26
    NOTE 2, As5, $26
    NOTE 2, C6, $26
    NOTE 4, Cs6, $26
    NOTE 2, A5, $26
    KEYOFF 2
    SONGJUMP Song01_Ch3

Pat049:
    NOTE 2, G5, $26
    NOTE 2, A5, $26
    NOTE 2, As5, $26
    NOTE 2, C6, $26
    NOTE 4, Cs6, $26
    NOTE 2, A5, $26
    KEYOFF 2
    PATEND

Pat050:
    HOLD 2
    NOTE 4, C4, $1D
    NOTE 4, C4, $1D
    NOTE 4, C4, $1D
    NOTE 2, C4, $1D
    PATEND

Pat051:
    HOLD 2
    NOTE 4, C4, $1D
    NOTE 4, C4, $1D
    NOTE 1, C4, $1D
    NOTE 1, C4, $1D
    NOTE 2, C4, $1D
    NOTE 2, C4, $1D
    PATEND

Pat052:
    NOTE 2, C5, $22
    NOTE 2, C4, $1D
    NOTE 2, D5, $22
    NOTE 2, C4, $1D
    NOTE 2, C5, $22
    NOTE 2, C4, $1D
    NOTE 2, B4, $22
    NOTE 2, C4, $1D
    NOTE 2, A4, $22
    NOTE 2, C4, $1D
    NOTE 2, A4, $22
    NOTE 2, C4, $1D
    NOTE 2, E4, $22
    NOTE 1, C4, $1D
    NOTE 1, C4, $1D
    NOTE 2, C4, $1D
    NOTE 2, C4, $1D
    NOTE 2, F4, $22
    NOTE 2, C4, $1D
    NOTE 2, E4, $22
    NOTE 2, C4, $1D
    NOTE 2, D4, $22
    NOTE 2, C4, $1D
    NOTE 1, D4, $22
    KEYOFF 1
    NOTE 2, C4, $1D
    NOTE 2, C5, $22
    NOTE 2, C4, $1D
    NOTE 2, C5, $22
    NOTE 4, C4, $1D
    NOTE 1, C4, $1D
    NOTE 1, C4, $1D
    NOTE 2, C4, $1D
    NOTE 2, C4, $1D
    NOTE 2, C5, $22
    NOTE 2, C4, $1D
    NOTE 2, D5, $22
    NOTE 1, C4, $1D
    NOTE 1, E5, $22
    NOTE 2, C5, $22
    NOTE 2, C4, $1D
    NOTE 2, C5, $22
    NOTE 2, C4, $1D
    NOTE 2, F5, $22
    NOTE 2, C4, $1D
    NOTE 2, F5, $22
    NOTE 2, C4, $1D
    NOTE 2, E4, $22
    NOTE 1, C4, $1D
    NOTE 1, C4, $1D
    NOTE 2, C4, $1D
    NOTE 2, C4, $1D
    NOTE 2, G5, $22
    NOTE 2, C4, $1D
    NOTE 2, G5, $22
    NOTE 2, C4, $1D
    NOTE 2, F5, $22
    NOTE 2, C4, $1D
    NOTE 2, F5, $22
    NOTE 2, C4, $1D
    NOTE 2, C5, $22
    NOTE 2, C4, $1D
    NOTE 2, C5, $22
    NOTE 2, C4, $1D
    NOTE 4, B4, $0F
    NOTE 3, G3, $22
    NOTE 1, C4, $22
    NOTE 4, C4, $22
    NOTE 1, G4, $20
    NOTE 1, A4, $20
    NOTE 1, G4, $20
    NOTE 1, D4, $20
    NOTE 8, B3, $22
    NOTE 4, C4, $22
    NOTE 4, B3, $22
    NOTE 4, A3, $22
    NOTE 4, G3, $22
    NOTE 6, F4, $22
    NOTE 2, F4, $22
    NOTE 4, A4, $22
    NOTE 2, G4, $22
    NOTE 2, A4, $22
    NOTE 2, E5, $22
    NOTE 1, C5, $22
    NOTE 1, G4, $22
    NOTE 1, F5, $22
    KEYOFF 1
    NOTE 1, D5, $22
    NOTE 1, B4, $22
    NOTE 4, C5, $22
    NOTE 3, G3, $22
    NOTE 1, C4, $22
    NOTE 2, F4, $20
    NOTE 2, A4, $20
    NOTE 2, E4, $20
    NOTE 1, A4, $20
    NOTE 1, E4, $20
    NOTE 2, D4, $20
    NOTE 2, C4, $20
    NOTE 2, A3, $20
    NOTE 2, C4, $20
    HOLD 2
    NOTE 4, B4, $2F
    NOTE 2, B4, $2F
    NOTE 8, C5, $30
    HOLD 12
    NOTE 4, C5, $0F
    PATEND

Pat067:
    NOTE 8, G4, $2F
    NOTE 8, G4, $30
    PATEND

Pat068:
    NOTE 2, C4, $20
    NOTE 1, C4, $20
    KEYOFF 3
    NOTE 4, G4, $31
    NOTE 2, Ds4, $20
    NOTE 2, F4, $20
    NOTE 1, Ds4, $20
    NOTE 1, D4, $20
    PATEND

Pat069:
    NOTE 2, C4, $20
    NOTE 1, C4, $20
    KEYOFF 3
    NOTE 4, G4, $31
    NOTE 2, Ds4, $20
    NOTE 2, C4, $1D
    NOTE 1, C4, $1D
    NOTE 1, C4, $1D
    PATEND

Pat070:
    NOTE 2, G4, $20
    NOTE 2, C4, $1D
    NOTE 2, Ds4, $20
    NOTE 2, C4, $1D
    NOTE 2, F4, $20
    NOTE 2, C4, $1D
    NOTE 2, D4, $20
    NOTE 1, C4, $1D
    NOTE 1, C4, $1D
    PATEND

Pat071:
    NOTE 2, G4, $0F
    NOTE 2, F5, $0B
    NOTE 2, Ds5, $0B
    NOTE 2, A4, $08
    NOTE 4, A4, $06
    NOTE 4, Cs5, $31
    PATEND

Pat072:
    NOTE 2, $18, $00
    NOTE 2, $24, $01
    HOLD 2
    NOTE 2, $24, $01
    HOLD 2
    NOTE 2, $24, $01
    HOLD 2
    NOTE 2, $24, $01
    HOLD 2
    NOTE 2, $24, $01
    HOLD 2
    NOTE 2, $24, $01
    HOLD 2
    NOTE 1, $24, $01
    NOTE 1, $24, $01
    NOTE 2, $24, $01
    NOTE 2, $24, $01
    SONGJUMP Song01_Ch4

Pat009:
    NOTE 4, Fs2, $05
    NOTE 2, A2, $05
    KEYOFF 2
    NOTE 1, Cs3, $05
    KEYOFF 1
    NOTE 1, C3, $05
    KEYOFF 1
    NOTE 2, B2, $05
    KEYOFF 2
    PATEND

Pat010:
    NOTE 4, Fs2, $05
    NOTE 2, A2, $05
    KEYOFF 2
    NOTE 2, A4, $21
    NOTE 2, B4, $21
    NOTE 2, A4, $21
    NOTE 1, A4, $21
    NOTE 1, D4, $21
    PATEND

Pat011:
    NOTE 4, Fs2, $05
    NOTE 2, A2, $05
    KEYOFF 2
    NOTE 1, Cs3, $05
    KEYOFF 1
    NOTE 1, C3, $05
    KEYOFF 1
    NOTE 2, B2, $05
    NOTE 2, Ds3, $05
    PATEND

Pat012:
    NOTE 2, Cs3, $05
    NOTE 2, Gs4, $22
    NOTE 2, Fs4, $22
    KEYOFF 2
    NOTE 2, F4, $22
    KEYOFF 4
    NOTE 2, Cs2, $05
    PATEND

Pat013:
    NOTE 4, C5, $01
    NOTE 1, Fs5, $2C
    KEYOFF 1
    NOTE 1, Gs5, $2C
    KEYOFF 1
    NOTE 1, A5, $2C
    KEYOFF 7
    PATEND

Pat014:
    HOLD 4
    NOTE 1, Fs5, $2C
    KEYOFF 1
    NOTE 1, Gs5, $2C
    KEYOFF 1
    NOTE 1, A5, $2C
    KEYOFF 1
    NOTE 1, B5, $2C
    KEYOFF 1
    NOTE 1, A5, $2C
    KEYOFF 1
    NOTE 1, A5, $2C
    NOTE 1, D5, $2C
    PATEND

Pat015:
    NOTE 1, Cs5, $2C
    KEYOFF 3
    NOTE 1, Fs5, $2C
    KEYOFF 1
    NOTE 1, Gs5, $2C
    KEYOFF 1
    NOTE 1, A5, $2C
    KEYOFF 7
    PATEND

Pat036:
    NOTE 1, Fs5, $2C
    KEYOFF 1
    NOTE 1, Gs5, $2C
    KEYOFF 1
    NOTE 1, A5, $2C
    NOTE 1, A5, $2C
    NOTE 1, B5, $2C
    KEYOFF 1
    NOTE 1, Cs6, $2C
    KEYOFF 7
    PATEND

Pat017:
    NOTE 2, Fs4, $00
    NOTE 4, Fs4, $07
    NOTE 1, Fs5, $21
    NOTE 3, Fs5, $21
    NOTE 4, Fs4, $09
    NOTE 2, Fs4, $09
    PATEND

Pat018:
    HOLD 2
    NOTE 4, Fs4, $07
    NOTE 1, Fs5, $21
    NOTE 3, Fs5, $21
    NOTE 2, Fs5, $21
    NOTE 2, C5, $09
    NOTE 1, C5, $09
    NOTE 1, C5, $09
    PATEND

Pat019:
    HOLD 2
    NOTE 2, B4, $20
    NOTE 2, A4, $20
    KEYOFF 2
    NOTE 2, Gs4, $20
    KEYOFF 6
    PATEND

Pat033:
    NOTE 2, Cs3, $05
    NOTE 2, Gs4, $22
    NOTE 2, Fs4, $22
    KEYOFF 2
    NOTE 2, F4, $22
    KEYOFF 4
    NOTE 2, Cs2, $05
    SONGJUMP Song02_Ch1

Pat034:
    HOLD 2
    NOTE 2, B4, $20
    NOTE 2, A4, $20
    KEYOFF 2
    NOTE 2, Gs4, $20
    KEYOFF 6
    SONGJUMP Song02_Ch2

Pat035:
    NOTE 1, Fs5, $2C
    KEYOFF 1
    NOTE 1, Gs5, $2C
    KEYOFF 1
    NOTE 1, A5, $2C
    NOTE 1, A5, $2C
    NOTE 1, B5, $2C
    KEYOFF 1
    NOTE 1, Cs6, $2C
    KEYOFF 7
    SONGJUMP Song02_Ch3

Pat037:
    NOTE 2, $24, $05
    NOTE 1, $24, $05
    NOTE 1, $24, $05
    NOTE 4, $24, $05
    NOTE 6, $24, $05
    NOTE 2, $24, $05
    NOTE 2, $24, $05
    NOTE 1, $24, $05
    NOTE 1, $24, $05
    NOTE 4, $24, $05
    NOTE 4, $24, $05
    NOTE 2, $24, $05
    NOTE 1, $24, $05
    NOTE 1, $24, $05
    SONGJUMP Song02_Ch4

Pat038:
    NOTE 2, C2, $03
    NOTE 1, C5, $33
    NOTE 2, C3, $03
    NOTE 1, C5, $34
    NOTE 2, As2, $03
    NOTE 1, C5, $33
    NOTE 2, G2, $03
    NOTE 1, C5, $34
    NOTE 2, C2, $03
    NOTE 1, C5, $33
    NOTE 1, C3, $03
    PATEND

Pat039:
    HOLD 1
    NOTE 1, C5, $34
    NOTE 2, As2, $03
    NOTE 1, C5, $33
    NOTE 2, G2, $03
    NOTE 1, C5, $34
    NOTE 2, C2, $03
    NOTE 1, C5, $33
    NOTE 2, C3, $03
    NOTE 1, C5, $34
    NOTE 2, As2, $03
    PATEND

Pat040:
    NOTE 1, C5, $33
    NOTE 2, G2, $03
    NOTE 1, C5, $34
    NOTE 2, C2, $03
    NOTE 1, C5, $33
    NOTE 2, C3, $03
    NOTE 1, C5, $34
    NOTE 2, As2, $03
    NOTE 1, C5, $33
    NOTE 2, G2, $03
    NOTE 1, C5, $34
    PATEND

Pat041:
    NOTE 3, C5, $33
    NOTE 3, C5, $1D
    NOTE 3, C5, $33
    NOTE 3, C5, $1D
    NOTE 3, C5, $33
    NOTE 1, C5, $1D
    PATEND

Pat042:
    HOLD 2
    NOTE 3, C5, $33
    NOTE 3, C5, $1D
    NOTE 3, C5, $33
    NOTE 3, C5, $1D
    NOTE 2, C5, $33
    PATEND

Pat053:
    HOLD 1
    NOTE 3, C5, $1D
    NOTE 3, C5, $33
    NOTE 3, C5, $1D
    NOTE 3, C5, $33
    NOTE 2, C5, $1D
    NOTE 1, C5, $1D
    PATEND

Pat054:
    HOLD 15
    NOTE 1, C5, $2E
    PATEND

Pat055:
    NOTE 1, E5, $2E
    KEYOFF 1
    NOTE 1, E5, $2E
    NOTE 2, F5, $2E
    NOTE 1, Fs5, $2E
    NOTE 2, G5, $2E
    NOTE 1, Ds5, $2E
    NOTE 1, E5, $2E
    KEYOFF 1
    NOTE 1, C6, $2E
    NOTE 1, E6, $2E
    KEYOFF 1
    NOTE 1, E6, $2E
    NOTE 1, F6, $2E
    PATEND

Pat056:
    HOLD 1
    NOTE 1, Fs6, $2E
    NOTE 2, G6, $2E
    NOTE 1, Ds6, $2E
    NOTE 1, E6, $2E
    KEYOFF 1
    NOTE 1, A5, $2E
    NOTE 8, C6, $2E
    PATEND

Pat057:
    HOLD 4
    KEYOFF 3
    NOTE 2, Fs5, $1B
    NOTE 1, G5, $1B
    NOTE 2, Fs5, $1B
    NOTE 1, G5, $1B
    NOTE 2, Fs5, $1B
    NOTE 1, G5, $1B
    PATEND

Pat058:
    NOTE 7, C6, $1B
    KEYOFF 9
    PATEND

Pat059:
    NOTE 1, G5, $26
    NOTE 1, A5, $26
    NOTE 1, G5, $26
    NOTE 1, A5, $26
    NOTE 1, G5, $26
    NOTE 1, A5, $26
    NOTE 1, G5, $26
    NOTE 1, A5, $26
    NOTE 1, G5, $26
    NOTE 1, A5, $26
    NOTE 1, G5, $26
    NOTE 1, A5, $26
    NOTE 2, C6, $26
    NOTE 1, E5, $26
    NOTE 1, G5, $26
    PATEND

Pat060:
    HOLD 1
    NOTE 1, C5, $26
    NOTE 2, E5, $26
    NOTE 1, G4, $26
    NOTE 2, C5, $26
    NOTE 1, G4, $26
    NOTE 8, C5, $27
    PATEND

Pat061:
    HOLD 7
    KEYOFF 9
    PATEND

Pat062:
    NOTE 3, Ds5, $27
    NOTE 7, C5, $26
    KEYOFF 2
    NOTE 3, A5, $27
    NOTE 1, Ds5, $26
    PATEND

Pat063:
    HOLD 1
    NOTE 1, F5, $09
    NOTE 2, Ds3, $03
    NOTE 1, F5, $06
    NOTE 2, C3, $03
    NOTE 1, F5, $09
    NOTE 2, C2, $03
    NOTE 1, C5, $06
    NOTE 2, C3, $03
    NOTE 1, C5, $09
    NOTE 2, As2, $03
    PATEND

Pat064:
    HOLD 6
    KEYOFF 2
    NOTE 8, C6, $26
    PATEND

Pat065:
    HOLD 8
    KEYOFF 2
    NOTE 3, E6, $26
    NOTE 3, A6, $26
    PATEND

Pat066:
    HOLD 2
    NOTE 3, F5, $06
    NOTE 3, F5, $1D
    NOTE 3, C5, $06
    NOTE 3, F5, $1D
    NOTE 2, C5, $06
    PATEND

Pat073:
    NOTE 16, G6, $27
    PATEND

Pat074:
    HOLD 5
    NOTE 3, Fs6, $26
    NOTE 8, F6, $26
    PATEND

Pat075:
    HOLD 5
    KEYOFF 2
    NOTE 3, A5, $27
    NOTE 3, As5, $26
    NOTE 3, B5, $26
    PATEND

Pat076:
    NOTE 2, C6, $26
    KEYOFF 14
    PATEND

Pat077:
    HOLD 1
    NOTE 1, G5, $09
    NOTE 2, F3, $03
    NOTE 1, G5, $06
    NOTE 2, D3, $03
    NOTE 1, F5, $09
    NOTE 2, F2, $03
    NOTE 1, F5, $06
    NOTE 2, F3, $03
    NOTE 1, F5, $09
    NOTE 2, Ds3, $03
    PATEND

Pat078:
    HOLD 2
    NOTE 3, G5, $06
    NOTE 3, G5, $1D
    NOTE 3, F5, $06
    NOTE 3, F5, $1D
    NOTE 2, F5, $06
    PATEND

Pat079:
    NOTE 2, C2, $03
    NOTE 3, E5, $0F
    NOTE 1, E5, $0F
    NOTE 2, E2, $03
    NOTE 3, G5, $09
    NOTE 1, G5, $09
    NOTE 2, F2, $03
    NOTE 2, A4, $0F
    PATEND

Pat080:
    HOLD 1
    NOTE 1, A4, $0F
    NOTE 2, Fs2, $03
    NOTE 3, A4, $0A
    NOTE 1, A4, $0A
    NOTE 8, G2, $03
    PATEND

Pat081:
    HOLD 7
    NOTE 3, G2, $03
    NOTE 3, A2, $03
    NOTE 3, B2, $03
    SONGJUMP Song03_Ch1

Pat082:
    NOTE 2, C7, $1F
    NOTE 1, C7, $1F
    NOTE 2, C5, $1D
    NOTE 1, C7, $1F
    NOTE 2, C7, $1F
    NOTE 1, C7, $1F
    NOTE 2, C5, $1D
    NOTE 1, C7, $1F
    NOTE 2, C7, $1F
    NOTE 1, C7, $1F
    NOTE 1, C5, $1D
    PATEND

Pat083:
    HOLD 1
    NOTE 1, C7, $1F
    NOTE 2, C7, $1F
    NOTE 1, C7, $1F
    NOTE 2, C5, $1D
    NOTE 1, C7, $1F
    NOTE 2, C7, $1F
    NOTE 1, C7, $1F
    NOTE 2, C5, $1D
    NOTE 1, C7, $1F
    NOTE 2, C7, $1F
    PATEND

Pat084:
    NOTE 1, C7, $1F
    NOTE 2, C5, $1D
    NOTE 1, C7, $1F
    NOTE 2, C7, $1F
    NOTE 1, C7, $1F
    NOTE 2, C5, $1D
    NOTE 1, C7, $1F
    NOTE 2, C7, $1F
    NOTE 1, C7, $1F
    NOTE 1, C5, $1D
    NOTE 1, C5, $1D
    NOTE 1, C5, $1D
    SONGJUMP Song03_Ch2

Pat085:
    NOTE 6, E6, $17
    NOTE 6, D6, $17
    NOTE 4, C6, $18
    PATEND

Pat086:
    HOLD 2
    NOTE 8, As5, $19
    NOTE 1, Ds5, $26
    NOTE 2, E5, $26
    KEYOFF 1
    NOTE 2, E5, $26
    PATEND

Pat087:
    NOTE 1, Ds5, $26
    NOTE 1, E5, $26
    KEYOFF 1
    NOTE 1, Ds5, $26
    NOTE 2, E5, $27
    NOTE 1, Ds5, $26
    NOTE 2, C5, $26
    NOTE 1, G4, $26
    NOTE 2, Ds5, $27
    NOTE 3, E5, $26
    KEYOFF 1
    SONGJUMP Song03_Ch3

Pat088:
    NOTE 3, $0C, $02
    NOTE 3, $0C, $01
    NOTE 3, $0C, $02
    NOTE 3, $0C, $01
    NOTE 3, $0C, $02
    NOTE 3, $0C, $01
    NOTE 3, $0C, $02
    NOTE 3, $0C, $01
    NOTE 3, $0C, $02
    NOTE 3, $0C, $01
    NOTE 3, $0C, $02
    NOTE 3, $0C, $01
    NOTE 3, $0C, $02
    NOTE 3, $0C, $01
    NOTE 3, $0C, $02
    NOTE 2, $0C, $01
    NOTE 1, $0C, $01
    SONGJUMP Song03_Ch4

Pat089:
    NOTE 2, C2, $03
    NOTE 1, C2, $03
    NOTE 2, C4, $1D
    NOTE 1, C2, $03
    NOTE 2, F2, $03
    NOTE 1, F2, $03
    NOTE 2, C4, $1D
    NOTE 1, F2, $03
    NOTE 2, E2, $03
    NOTE 1, E2, $03
    NOTE 2, C4, $1D
    NOTE 1, E2, $03
    NOTE 2, D2, $03
    NOTE 1, D2, $03
    NOTE 2, C4, $1D
    NOTE 1, G2, $03
    PATEND

Pat090:
    NOTE 2, C2, $03
    NOTE 1, C2, $03
    NOTE 2, C4, $1D
    NOTE 1, C2, $03
    NOTE 2, As2, $03
    NOTE 1, As2, $03
    NOTE 2, C4, $1D
    NOTE 1, As2, $03
    NOTE 2, A2, $03
    NOTE 1, A2, $03
    NOTE 2, C4, $1D
    NOTE 1, A2, $03
    NOTE 2, D2, $03
    NOTE 1, D2, $03
    NOTE 2, C4, $1D
    NOTE 1, D2, $03
    NOTE 2, G2, $03
    NOTE 1, G2, $03
    NOTE 2, C4, $1D
    NOTE 1, G2, $03
    NOTE 2, D2, $03
    NOTE 1, D2, $03
    NOTE 2, C4, $1D
    NOTE 1, D2, $03
    NOTE 2, G2, $03
    NOTE 1, B3, $1D
    NOTE 2, B3, $1D
    NOTE 1, B3, $1D
    NOTE 2, A2, $03
    NOTE 1, B3, $1D
    NOTE 2, B2, $03
    NOTE 1, B3, $1D
    PATEND

Pat091:
    NOTE 2, C2, $03
    NOTE 1, C2, $03
    NOTE 2, C4, $1D
    NOTE 1, C2, $03
    NOTE 2, As2, $03
    NOTE 1, As2, $03
    NOTE 2, C4, $1D
    NOTE 1, As2, $03
    NOTE 2, A2, $03
    NOTE 1, A2, $03
    NOTE 2, C4, $1D
    NOTE 1, A2, $03
    NOTE 2, D2, $03
    NOTE 1, D2, $03
    NOTE 2, C4, $1D
    NOTE 1, D2, $03
    NOTE 2, G2, $03
    NOTE 1, G2, $03
    NOTE 2, C4, $1D
    NOTE 1, G2, $03
    NOTE 2, D2, $03
    NOTE 1, D2, $03
    NOTE 2, C4, $1D
    NOTE 1, D2, $03
    NOTE 3, G2, $03
    NOTE 3, G2, $03
    NOTE 3, A2, $03
    NOTE 3, F2, $03
    PATEND

Pat092:
    NOTE 3, E3, $03
    NOTE 3, E3, $03
    NOTE 6, E3, $03
    NOTE 3, D3, $03
    NOTE 2, B2, $03
    NOTE 1, D3, $03
    NOTE 6, E3, $03
    NOTE 2, E3, $03
    NOTE 1, E3, $03
    NOTE 3, E3, $03
    NOTE 3, E3, $03
    NOTE 3, D3, $03
    NOTE 6, E3, $03
    NOTE 6, G3, $03
    PATEND

Pat093:
    NOTE 2, C2, $03
    NOTE 1, C2, $03
    NOTE 2, C4, $1D
    NOTE 1, E2, $03
    NOTE 2, F2, $03
    NOTE 1, F2, $03
    NOTE 2, C4, $1D
    NOTE 1, F2, $03
    NOTE 2, E2, $03
    NOTE 1, E2, $03
    NOTE 2, C4, $1D
    NOTE 1, E2, $03
    NOTE 2, G2, $03
    NOTE 1, G2, $03
    NOTE 2, C4, $1D
    NOTE 1, G2, $03
    NOTE 3, C3, $05
    KEYON 3
    NOTE 3, F3, $05
    NOTE 3, Ds3, $05
    NOTE 12, Gs3, $05
    NOTE 12, F3, $05
    NOTE 12, D3, $05
    PATEND

Pat094:
    NOTE 3, G2, $03
    NOTE 3, G2, $03
    NOTE 6, G2, $03
    NOTE 2, G2, $03
    NOTE 1, A2, $03
    NOTE 2, B2, $03
    NOTE 1, A2, $03
    NOTE 6, G2, $03
    NOTE 2, G2, $03
    NOTE 1, A2, $03
    NOTE 2, B2, $03
    NOTE 1, A2, $03
    NOTE 2, B2, $03
    NOTE 1, C3, $03
    NOTE 2, D3, $03
    NOTE 1, C3, $03
    NOTE 2, B2, $03
    NOTE 1, C3, $03
    NOTE 2, B2, $03
    NOTE 1, A2, $03
    NOTE 2, G2, $03
    NOTE 1, F2, $03
    NOTE 2, E2, $03
    NOTE 1, D2, $03
    SONGJUMP Song04_Ch1

Pat095:
    NOTE 6, C5, $13
    NOTE 6, F5, $13
    NOTE 5, E5, $12
    NOTE 7, D5, $12
    NOTE 3, C5, $13
    NOTE 3, C5, $13
    NOTE 6, F5, $13
    NOTE 5, E5, $12
    NOTE 4, D5, $12
    NOTE 3, G5, $2E
    PATEND

Pat096:
    NOTE 5, C5, $2E
    KEYOFF 1
    NOTE 11, C5, $2E
    KEYOFF 1
    NOTE 2, B4, $2E
    NOTE 1, C5, $2E
    NOTE 2, A4, $2E
    NOTE 1, B4, $2E
    NOTE 5, C5, $2E
    KEYOFF 1
    NOTE 8, C5, $2E
    KEYOFF 1
    NOTE 2, B4, $2E
    NOTE 1, C5, $2E
    NOTE 2, D5, $2E
    KEYOFF 1
    NOTE 2, E5, $2E
    NOTE 1, F5, $2E
    PATEND

Pat097:
    NOTE 4, G5, $2E
    KEYOFF 2
    NOTE 6, C5, $2E
    KEYOFF 3
    NOTE 3, A5, $2E
    NOTE 3, F5, $2E
    NOTE 2, E5, $2E
    KEYOFF 1
    NOTE 13, D5, $2E
    KEYOFF 5
    NOTE 6, G4, $2E
    PATEND

Pat098:
    NOTE 5, G5, $2E
    KEYOFF 1
    NOTE 8, C5, $2E
    KEYOFF 1
    NOTE 3, C6, $2E
    NOTE 3, A5, $2E
    NOTE 2, F5, $2E
    NOTE 1, E5, $2E
    NOTE 12, D5, $2E
    KEYOFF 6
    NOTE 2, E5, $2E
    KEYOFF 1
    NOTE 2, F5, $2E
    KEYOFF 1
    PATEND

Pat099:
    NOTE 3, B5, $14
    NOTE 3, B5, $14
    NOTE 6, B5, $14
    NOTE 3, A5, $14
    NOTE 2, Fs5, $14
    NOTE 1, A5, $14
    NOTE 6, B5, $14
    NOTE 2, B5, $14
    NOTE 1, B5, $14
    NOTE 3, B5, $14
    NOTE 3, B5, $14
    NOTE 3, A5, $14
    NOTE 6, B5, $14
    NOTE 6, D6, $14
    PATEND

Pat100:
    NOTE 3, E5, $2E
    NOTE 3, C6, $2E
    NOTE 3, A5, $2E
    NOTE 3, C6, $2E
    NOTE 3, G5, $2E
    NOTE 3, C6, $2E
    NOTE 2, B4, $2E
    NOTE 1, C5, $2E
    NOTE 2, A4, $2E
    NOTE 1, B4, $2E
    NOTE 2, C5, $2E
    KEYOFF 1
    NOTE 2, C5, $2E
    KEYOFF 1
    NOTE 2, C5, $2E
    NOTE 1, B4, $2E
    NOTE 2, C5, $2E
    NOTE 1, D5, $2E
    NOTE 12, Ds5, $2E
    NOTE 12, F5, $2E
    NOTE 12, Fs5, $2E
    PATEND

Pat101:
    NOTE 2, G5, $2E
    KEYOFF 1
    NOTE 2, G5, $2E
    KEYOFF 1
    NOTE 2, G5, $2E
    KEYOFF 4
    NOTE 1, G5, $2E
    KEYOFF 1
    NOTE 1, A5, $2E
    NOTE 1, B5, $2E
    KEYOFF 1
    NOTE 1, A5, $2E
    NOTE 2, G5, $2E
    KEYOFF 4
    NOTE 1, G5, $2E
    KEYOFF 1
    NOTE 1, A5, $2E
    NOTE 1, B5, $2E
    KEYOFF 1
    NOTE 1, A5, $2E
    NOTE 1, B5, $2E
    KEYOFF 1
    NOTE 1, C6, $2E
    NOTE 1, D6, $2E
    KEYOFF 1
    NOTE 1, C6, $2E
    NOTE 1, B5, $2E
    KEYOFF 1
    NOTE 1, C6, $2E
    NOTE 1, B5, $2E
    KEYOFF 1
    NOTE 1, A5, $2E
    NOTE 1, G5, $2E
    KEYOFF 1
    NOTE 1, F5, $2E
    NOTE 1, E5, $2E
    KEYOFF 1
    NOTE 1, D5, $2E
    SONGJUMP Song04_Ch3

Pat102:
    NOTE 3, G4, $21
    NOTE 3, C5, $21
    NOTE 3, A4, $21
    NOTE 3, C5, $21
    NOTE 3, G4, $21
    NOTE 3, C5, $21
    NOTE 3, F4, $21
    NOTE 3, B4, $21
    NOTE 3, G4, $21
    NOTE 3, C5, $21
    NOTE 3, A4, $21
    NOTE 3, C5, $21
    NOTE 3, G4, $21
    NOTE 3, C5, $21
    NOTE 3, F4, $21
    NOTE 3, B3, $21
    PATEND

Pat103:
    NOTE 3, C4, $21
    NOTE 6, G4, $21
    NOTE 2, C4, $21
    NOTE 1, F4, $21
    NOTE 3, G4, $21
    NOTE 3, C4, $21
    NOTE 3, F4, $21
    NOTE 6, B3, $21
    NOTE 3, C4, $21
    NOTE 3, F4, $21
    NOTE 2, C4, $21
    NOTE 1, F4, $21
    NOTE 3, G4, $21
    NOTE 3, C4, $21
    NOTE 3, F4, $21
    NOTE 3, B3, $21
    PATEND

Pat104:
    NOTE 3, E4, $21
    NOTE 3, C4, $21
    NOTE 3, G4, $21
    NOTE 2, C4, $21
    NOTE 1, E4, $21
    NOTE 3, F4, $21
    NOTE 3, C4, $21
    NOTE 3, F4, $21
    NOTE 3, C4, $21
    NOTE 3, D4, $21
    NOTE 2, D4, $21
    NOTE 1, G4, $21
    NOTE 3, F4, $21
    NOTE 3, E4, $21
    NOTE 3, D4, $21
    NOTE 3, G3, $21
    NOTE 3, A3, $21
    NOTE 3, B3, $21
    PATEND

Pat105:
    NOTE 3, G4, $21
    NOTE 2, C4, $21
    NOTE 1, E4, $21
    NOTE 3, F4, $21
    NOTE 3, C4, $21
    NOTE 3, F4, $21
    NOTE 3, C5, $21
    NOTE 3, A4, $21
    NOTE 2, F4, $21
    NOTE 1, E4, $21
    NOTE 3, G4, $21
    NOTE 2, G4, $21
    NOTE 1, G4, $21
    NOTE 3, F4, $21
    NOTE 2, F4, $21
    NOTE 1, F4, $21
    NOTE 3, G4, $21
    NOTE 3, B3, $21
    NOTE 3, G4, $21
    NOTE 3, G4, $21
    PATEND

Pat106:
    NOTE 3, F4, $1F
    NOTE 3, F4, $1F
    NOTE 3, F4, $1F
    NOTE 2, F4, $1F
    NOTE 1, F4, $1F
    NOTE 3, F4, $1F
    NOTE 3, F4, $1F
    NOTE 3, F4, $1F
    NOTE 2, F4, $1F
    NOTE 1, F4, $1F
    NOTE 3, F4, $1F
    NOTE 3, F4, $1F
    NOTE 3, F4, $1F
    NOTE 2, F4, $1F
    NOTE 1, F4, $1F
    NOTE 3, F4, $1F
    NOTE 1, F4, $1F
    NOTE 1, F4, $1F
    NOTE 1, F4, $1F
    NOTE 1, F4, $1F
    NOTE 1, F4, $1F
    NOTE 1, F4, $1F
    NOTE 1, F4, $1F
    NOTE 1, F4, $1F
    NOTE 1, F4, $1F
    PATEND

Pat107:
    NOTE 6, G3, $22
    NOTE 6, A3, $22
    NOTE 6, G3, $22
    NOTE 6, F3, $22
    NOTE 3, C4, $22
    NOTE 3, C4, $22
    NOTE 2, C4, $22
    NOTE 1, B3, $22
    NOTE 2, C4, $22
    NOTE 1, D4, $22
    NOTE 12, Ds4, $22
    NOTE 12, F4, $22
    NOTE 12, Fs4, $22
    PATEND

Pat108:
    NOTE 2, G5, $21
    KEYOFF 1
    NOTE 2, G5, $21
    KEYOFF 1
    NOTE 2, G5, $21
    KEYOFF 4
    NOTE 1, G5, $21
    KEYOFF 1
    NOTE 1, A5, $21
    NOTE 1, B5, $21
    KEYOFF 1
    NOTE 1, A5, $21
    NOTE 2, G5, $21
    KEYOFF 4
    NOTE 1, G5, $21
    KEYOFF 1
    NOTE 1, A5, $21
    NOTE 1, B5, $21
    KEYOFF 1
    NOTE 1, A5, $21
    NOTE 1, B5, $21
    KEYOFF 1
    NOTE 1, C6, $21
    NOTE 1, D6, $21
    KEYOFF 1
    NOTE 1, C6, $21
    NOTE 1, B5, $21
    KEYOFF 1
    NOTE 1, C6, $21
    NOTE 1, B5, $21
    KEYOFF 1
    NOTE 1, A5, $21
    NOTE 1, G5, $21
    KEYOFF 1
    NOTE 1, F5, $21
    NOTE 1, E5, $21
    KEYOFF 1
    NOTE 1, D5, $21
    SONGJUMP Song04_Ch2

Pat109:
    NOTE 3, $24, $02
    NOTE 3, $24, $01
    NOTE 3, $24, $02
    NOTE 3, $24, $01
    NOTE 3, $24, $02
    NOTE 3, $24, $01
    NOTE 2, $24, $02
    NOTE 1, $24, $02
    NOTE 3, $24, $01
    SONGJUMP Song04_Ch4

Pat110:
    NOTE 4, E3, $04
    NOTE 4, B3, $04
    NOTE 4, Fs3, $04
    NOTE 2, B3, $04
    NOTE 2, B2, $04
    PATEND

Pat111:
    NOTE 3, E5, $35
    NOTE 1, E5, $36
    KEYOFF 4
    NOTE 3, Ds5, $37
    NOTE 1, Ds5, $38
    KEYOFF 4
    PATEND

Pat112:
    NOTE 4, E3, $1E
    NOTE 4, E4, $1D
    NOTE 3, E3, $1E
    NOTE 1, E3, $1E
    NOTE 2, E4, $1D
    NOTE 2, E3, $1E
    PATEND

Pat113:
    NOTE 2, E2, $04
    NOTE 2, Gs2, $04
    NOTE 2, B2, $04
    NOTE 2, E3, $04
    NOTE 2, Cs3, $04
    NOTE 2, B2, $04
    NOTE 2, A2, $04
    NOTE 2, Gs2, $04
    PATEND

Pat114:
    NOTE 2, Fs2, $04
    NOTE 2, As2, $04
    NOTE 2, Cs3, $04
    NOTE 2, E3, $04
    NOTE 2, B2, $04
    NOTE 2, A2, $04
    NOTE 2, Gs2, $04
    NOTE 2, Fs2, $04
    PATEND

Pat115:
    NOTE 4, E2, $04
    NOTE 4, Gs2, $04
    NOTE 4, A2, $04
    NOTE 2, A2, $04
    NOTE 2, Cs3, $04
    PATEND

Pat116:
    NOTE 4, Fs2, $04
    NOTE 4, As2, $04
    NOTE 8, B2, $04
    PATEND

Pat117:
    NOTE 2, G2, $04
    NOTE 2, G2, $04
    NOTE 4, C3, $1C
    NOTE 2, G2, $04
    NOTE 2, G2, $04
    NOTE 2, C3, $1C
    NOTE 1, C3, $1C
    NOTE 1, C3, $1C
    PATEND

Pat118:
    NOTE 4, B2, $04
    NOTE 4, B2, $04
    NOTE 4, B2, $04
    NOTE 4, B2, $04
    PATEND

Pat119:
    NOTE 4, B2, $04
    NOTE 4, B2, $04
    NOTE 4, B2, $04
    NOTE 4, B2, $04
    PATEND

Pat120:
    NOTE 4, Gs2, $04
    NOTE 4, C3, $04
    NOTE 4, Cs3, $04
    NOTE 4, F3, $04
    PATEND

Pat121:
    NOTE 16, Ds3, $05
    PATEND

Pat122:
    NOTE 2, A2, $04
    NOTE 4, Cs3, $04
    NOTE 2, A2, $04
    NOTE 4, D3, $04
    NOTE 4, Fs3, $04
    PATEND

Pat123:
    NOTE 4, E3, $04
    NOTE 4, E3, $04
    NOTE 8, A2, $04
    PATEND

Pat124:
    NOTE 2, A2, $04
    NOTE 4, Cs3, $04
    NOTE 2, A2, $04
    NOTE 4, D3, $04
    NOTE 4, B2, $04
    PATEND

Pat125:
    NOTE 4, E3, $04
    NOTE 4, B2, $04
    NOTE 2, E3, $04
    NOTE 2, E2, $04
    NOTE 4, E2, $04
    PATEND

Pat126:
    NOTE 2, Gs5, $12
    NOTE 2, Gs5, $12
    NOTE 2, B5, $12
    NOTE 2, B5, $12
    NOTE 3, A5, $13
    NOTE 5, A5, $13
    PATEND

Pat127:
    HOLD 3
    NOTE 8, Gs5, $15
    NOTE 5, A5, $13
    PATEND

Pat128:
    HOLD 3
    NOTE 7, As5, $15
    NOTE 2, B5, $13
    NOTE 4, B5, $13
    PATEND

Pat129:
    NOTE 2, G5, $27
    NOTE 1, G5, $26
    KEYOFF 1
    NOTE 2, As5, $26
    NOTE 2, B5, $26
    NOTE 2, G5, $27
    NOTE 1, G5, $26
    KEYOFF 1
    NOTE 2, E5, $26
    NOTE 1, D5, $26
    KEYOFF 1
    PATEND

Pat130:
    NOTE 14, B3, $26
    NOTE 1, E5, $2C
    NOTE 1, Fs5, $2C
    PATEND

Pat131:
    NOTE 3, Gs5, $2C
    NOTE 3, A5, $2C
    NOTE 2, B5, $2C
    NOTE 3, Gs5, $2C
    NOTE 3, Fs5, $2C
    NOTE 2, E5, $2C
    PATEND

Pat132:
    NOTE 3, Cs5, $2C
    NOTE 3, E5, $2C
    NOTE 2, A4, $2C
    NOTE 6, B4, $2C
    KEYOFF 2
    PATEND

Pat133:
    NOTE 3, C5, $2E
    NOTE 6, Ds5, $2E
    KEYOFF 1
    NOTE 2, Gs5, $2E
    NOTE 2, G5, $2E
    NOTE 2, F5, $2E
    PATEND

Pat134:
    NOTE 3, C5, $2E
    NOTE 6, Ds5, $2E
    KEYOFF 1
    NOTE 2, F5, $2E
    NOTE 2, Ds5, $2E
    NOTE 2, C5, $2E
    PATEND

Pat135:
    NOTE 4, C5, $2E
    NOTE 4, Ds5, $2E
    NOTE 4, Cs5, $2E
    NOTE 4, F5, $2E
    PATEND

Pat136:
    NOTE 8, Ds5, $2E
    NOTE 1, Ds5, $1B
    NOTE 1, F5, $1B
    NOTE 1, Gs5, $1B
    NOTE 1, F5, $1B
    NOTE 4, Gs5, $1B
    PATEND

Pat137:
    NOTE 8, E5, $2E
    NOTE 1, E5, $1B
    NOTE 1, Fs5, $1B
    NOTE 1, A5, $1B
    NOTE 1, Fs5, $1B
    NOTE 2, A5, $1B
    NOTE 1, A5, $2E
    NOTE 1, B5, $2E
    PATEND

Pat138:
    NOTE 2, Cs6, $2E
    NOTE 4, E6, $2E
    NOTE 2, A5, $2E
    NOTE 4, Fs6, $2E
    NOTE 4, A6, $2E
    PATEND

Pat139:
    NOTE 2, Cs6, $2E
    KEYOFF 2
    NOTE 2, B5, $2E
    KEYOFF 2
    NOTE 2, A5, $2E
    NOTE 1, A3, $2E
    KEYOFF 1
    NOTE 1, A3, $2E
    KEYOFF 3
    PATEND

Pat140:
    NOTE 3, B6, $2E
    NOTE 1, A6, $2E
    NOTE 2, B6, $2E
    NOTE 2, Cs7, $2E
    NOTE 4, B6, $2E
    KEYOFF 4
    PATEND

Pat141:
    NOTE 2, C3, $1C
    NOTE 2, E4, $06
    NOTE 2, G4, $1D
    NOTE 2, E4, $06
    NOTE 2, C3, $1C
    NOTE 2, Cs4, $0F
    NOTE 2, G4, $1D
    NOTE 2, Cs4, $0F
    PATEND

Pat142:
    NOTE 2, C3, $1C
    NOTE 2, G4, $06
    NOTE 2, E3, $1D
    NOTE 2, G4, $06
    NOTE 2, C3, $1C
    NOTE 2, G4, $06
    NOTE 2, E3, $1D
    NOTE 2, G4, $06
    PATEND

Pat143:
    NOTE 2, C3, $1C
    NOTE 2, E4, $09
    NOTE 2, E3, $1D
    NOTE 2, E4, $09
    NOTE 2, C3, $1C
    NOTE 2, Fs4, $09
    NOTE 2, E3, $1D
    NOTE 2, Fs4, $09
    PATEND

Pat144:
    NOTE 1, Gs3, $22
    NOTE 1, C4, $22
    NOTE 1, Ds4, $22
    NOTE 1, Gs4, $22
    NOTE 1, Gs3, $22
    NOTE 1, C4, $22
    NOTE 1, Ds4, $22
    NOTE 1, Gs4, $22
    NOTE 1, Ds4, $22
    NOTE 1, As4, $22
    NOTE 1, Cs5, $22
    NOTE 1, Ds5, $22
    NOTE 1, Ds4, $22
    NOTE 1, As4, $22
    NOTE 1, Cs5, $22
    NOTE 1, Ds5, $22
    PATEND

Pat145:
    NOTE 1, Gs3, $22
    NOTE 1, C4, $22
    NOTE 1, Ds4, $22
    NOTE 1, Gs4, $22
    NOTE 1, Gs3, $22
    NOTE 1, C4, $22
    NOTE 1, Ds4, $22
    NOTE 1, Gs4, $22
    NOTE 1, Cs4, $22
    NOTE 1, F4, $22
    NOTE 1, Gs4, $22
    NOTE 1, Cs5, $22
    NOTE 1, F4, $22
    NOTE 1, Gs4, $22
    NOTE 1, Cs5, $22
    NOTE 1, F5, $22
    PATEND

Pat146:
    NOTE 1, G2, $22
    NOTE 1, As2, $22
    NOTE 1, Ds3, $22
    NOTE 1, G3, $22
    NOTE 1, As3, $22
    NOTE 1, Ds4, $22
    NOTE 1, G4, $22
    NOTE 1, Ds3, $22
    NOTE 1, Ds4, $22
    NOTE 1, F4, $22
    NOTE 1, Gs4, $22
    NOTE 1, F4, $22
    NOTE 4, Gs4, $22
    PATEND

Pat147:
    NOTE 2, C3, $1C
    NOTE 2, A4, $06
    NOTE 2, E3, $1D
    NOTE 2, A4, $06
    NOTE 2, C3, $1C
    NOTE 2, A4, $09
    NOTE 2, E3, $1D
    NOTE 2, A4, $09
    PATEND

Pat148:
    NOTE 2, C3, $1C
    NOTE 2, Gs4, $0F
    NOTE 2, E3, $1D
    NOTE 2, Gs4, $0F
    NOTE 2, C3, $1C
    NOTE 2, E4, $09
    NOTE 2, E3, $1D
    NOTE 2, E4, $09
    PATEND

Pat149:
    NOTE 2, $0C, $02
    NOTE 1, $0C, $02
    NOTE 1, $0C, $02
    NOTE 2, $0C, $05
    NOTE 2, $0C, $02
    NOTE 2, $0C, $02
    NOTE 1, $0C, $02
    NOTE 1, $0C, $02
    NOTE 2, $0C, $05
    NOTE 2, $0C, $02
    NOTE 2, $0C, $02
    NOTE 1, $0C, $02
    NOTE 1, $0C, $02
    NOTE 2, $0C, $05
    NOTE 2, $0C, $02
    NOTE 2, $0C, $02
    NOTE 1, $0C, $02
    NOTE 1, $0C, $02
    NOTE 2, $0C, $05
    NOTE 1, $0C, $05
    NOTE 1, $0C, $05
    SONGJUMP Song05_Ch4

Pat150:
    NOTE 3, B6, $2E
    NOTE 1, A6, $2E
    NOTE 2, B6, $2E
    NOTE 2, Cs7, $2E
    NOTE 4, B6, $2E
    KEYOFF 4
    SONGJUMP Song05_Ch3

Pat151:
    NOTE 2, C3, $1C
    NOTE 2, A4, $06
    NOTE 2, E3, $1D
    NOTE 2, A4, $06
    NOTE 2, C3, $1C
    NOTE 2, A4, $09
    NOTE 2, E3, $1D
    NOTE 2, A4, $09
    SONGJUMP Song05_Ch2

Pat152:
    NOTE 4, E3, $04
    NOTE 4, B2, $04
    NOTE 2, E3, $04
    NOTE 2, E2, $04
    NOTE 4, E2, $04
    SONGJUMP Song05_Ch1

Pat153:
    NOTE 2, As2, $03
    NOTE 2, D3, $03
    NOTE 2, F3, $03
    NOTE 2, G3, $03
    NOTE 2, Gs3, $03
    NOTE 2, G3, $03
    NOTE 2, F3, $03
    NOTE 2, D3, $03
    PATEND

Pat154:
    NOTE 2, F2, $03
    NOTE 2, A2, $03
    NOTE 2, C3, $03
    NOTE 2, F3, $03
    NOTE 2, Ds2, $03
    NOTE 2, G2, $03
    NOTE 2, As2, $03
    NOTE 2, Ds3, $03
    PATEND

Pat155:
    NOTE 2, As2, $03
    NOTE 2, D3, $03
    NOTE 2, F3, $03
    NOTE 2, As3, $03
    NOTE 2, F2, $03
    NOTE 2, G2, $03
    NOTE 2, Gs2, $03
    NOTE 2, A2, $03
    PATEND

Pat156:
    NOTE 2, As4, $06
    NOTE 1, G4, $1D
    NOTE 3, As4, $06
    NOTE 2, G4, $1D
    NOTE 2, As4, $06
    NOTE 1, G4, $1D
    NOTE 2, As4, $06
    NOTE 1, As4, $06
    NOTE 2, G4, $1D
    PATEND

Pat157:
    NOTE 2, F5, $06
    NOTE 1, G4, $1D
    NOTE 3, F5, $06
    NOTE 2, G4, $1D
    NOTE 2, Ds5, $06
    NOTE 1, G4, $1D
    NOTE 2, Ds5, $06
    NOTE 1, Ds5, $06
    NOTE 2, G4, $1D
    PATEND

Pat158:
    NOTE 2, As4, $06
    NOTE 1, G4, $1D
    NOTE 3, As4, $06
    NOTE 2, G4, $1D
    NOTE 2, A4, $0F
    NOTE 1, G4, $1D
    NOTE 2, A4, $0F
    NOTE 1, A4, $0F
    NOTE 1, G4, $1D
    NOTE 1, A4, $0F
    PATEND

Pat159:
    NOTE 2, C3, $1E
    NOTE 2, E4, $1D
    NOTE 2, A4, $0F
    NOTE 1, E4, $1D
    NOTE 1, A4, $0F
    KEYOFF 1
    NOTE 1, G4, $0F
    NOTE 2, E4, $1D
    NOTE 2, G4, $0F
    NOTE 2, E4, $1D
    PATEND

Pat160:
    NOTE 1, As5, $26
    KEYOFF 1
    NOTE 2, As5, $27
    KEYOFF 2
    NOTE 1, G5, $26
    NOTE 1, F5, $26
    NOTE 1, As5, $26
    KEYOFF 1
    NOTE 1, As5, $27
    KEYOFF 1
    NOTE 1, As5, $26
    NOTE 1, G5, $26
    NOTE 1, F5, $26
    NOTE 1, As5, $26
    PATEND

Pat161:
    HOLD 1
    KEYOFF 1
    NOTE 2, As5, $26
    KEYOFF 2
    NOTE 1, G5, $26
    NOTE 1, F5, $26
    NOTE 1, As5, $26
    KEYOFF 1
    NOTE 1, C6, $26
    KEYOFF 1
    NOTE 1, Cs6, $26
    NOTE 1, C6, $26
    NOTE 1, As5, $26
    NOTE 1, G5, $26
    PATEND

Pat162:
    NOTE 1, As5, $26
    NOTE 1, Gs5, $26
    NOTE 1, F5, $26
    KEYOFF 1
    NOTE 1, F5, $26
    NOTE 1, D5, $26
    NOTE 1, F5, $26
    KEYOFF 1
    NOTE 1, As4, $26
    NOTE 1, D5, $26
    NOTE 1, As4, $26
    NOTE 1, F4, $26
    KEYOFF 1
    NOTE 1, D5, $26
    NOTE 1, Ds5, $26
    NOTE 1, E5, $26
    PATEND

Pat163:
    NOTE 2, F5, $26
    NOTE 1, A5, $26
    KEYOFF 1
    NOTE 1, C6, $26
    NOTE 1, F6, $26
    NOTE 1, E6, $26
    NOTE 2, Ds6, $27
    NOTE 1, Cs6, $26
    NOTE 1, Ds6, $26
    NOTE 1, F6, $26
    NOTE 1, Cs6, $26
    NOTE 1, As4, $26
    NOTE 1, Gs5, $26
    NOTE 1, A5, $26
    PATEND

Pat164:
    NOTE 2, D5, $1B
    NOTE 2, Ds5, $1B
    NOTE 2, D5, $1B
    NOTE 2, Ds5, $1B
    NOTE 2, D5, $1B
    NOTE 1, Ds5, $1B
    NOTE 1, D5, $1B
    KEYOFF 4
    PATEND

Pat165:
    NOTE 2, As5, $1B
    NOTE 1, As5, $1B
    NOTE 1, G6, $1B
    NOTE 2, F6, $1B
    NOTE 1, G6, $1B
    NOTE 2, As5, $1B
    NOTE 2, As5, $1B
    NOTE 1, G6, $1B
    NOTE 2, F6, $1B
    NOTE 2, G6, $1B
    PATEND

Pat166:
    NOTE 2, As5, $1B
    NOTE 2, G5, $1B
    NOTE 2, F5, $1B
    NOTE 1, G5, $1B
    NOTE 3, As5, $1B
    NOTE 1, G5, $1B
    NOTE 2, F5, $1B
    NOTE 3, G5, $1B
    PATEND

Pat167:
    NOTE 1, As5, $26
    NOTE 1, As5, $27
    KEYOFF 1
    NOTE 1, As5, $26
    NOTE 1, As5, $27
    KEYOFF 1
    NOTE 1, As5, $26
    NOTE 1, As5, $27
    KEYOFF 1
    NOTE 1, As5, $26
    NOTE 1, As5, $27
    KEYOFF 1
    NOTE 1, As5, $26
    NOTE 1, As5, $26
    NOTE 1, G5, $26
    NOTE 1, F5, $26
    PATEND

Pat168:
    NOTE 1, As5, $26
    NOTE 1, G5, $26
    NOTE 1, F5, $26
    NOTE 1, As5, $26
    NOTE 1, G5, $26
    NOTE 1, F5, $26
    NOTE 1, As5, $26
    NOTE 1, G5, $26
    NOTE 1, F5, $26
    NOTE 1, As5, $26
    NOTE 1, G5, $26
    NOTE 1, F5, $26
    NOTE 1, As5, $26
    NOTE 1, G5, $26
    NOTE 1, F5, $26
    NOTE 1, D5, $26
    PATEND

Pat169:
    NOTE 2, As2, $03
    NOTE 2, D3, $03
    NOTE 2, F3, $03
    NOTE 2, As3, $03
    NOTE 2, F2, $03
    NOTE 2, G2, $03
    NOTE 2, Gs2, $03
    NOTE 2, A2, $03
    SONGJUMP Song06_Ch1

Pat170:
    NOTE 2, As4, $06
    NOTE 1, G4, $1D
    NOTE 3, As4, $06
    NOTE 2, G4, $1D
    NOTE 2, A4, $0F
    NOTE 1, G4, $1D
    NOTE 2, A4, $0F
    NOTE 1, A4, $0F
    NOTE 1, G4, $1D
    NOTE 1, A4, $0F
    SONGJUMP Song06_Ch2

Pat171:
    NOTE 1, As5, $26
    NOTE 1, G5, $26
    NOTE 1, F5, $26
    NOTE 1, As5, $26
    NOTE 1, G5, $26
    NOTE 1, F5, $26
    NOTE 1, As5, $26
    NOTE 1, G5, $26
    NOTE 1, F5, $26
    NOTE 1, As5, $26
    NOTE 1, G5, $26
    NOTE 1, F5, $26
    NOTE 1, As5, $26
    NOTE 1, G5, $26
    NOTE 1, F5, $26
    NOTE 1, D5, $26
    SONGJUMP Song06_Ch3

Pat172:
    NOTE 16, C5, $01
    PATEND

Pat173:
    NOTE 2, $24, $02
    NOTE 2, $24, $01
    NOTE 2, $24, $02
    NOTE 2, $24, $01
    NOTE 2, $24, $02
    NOTE 2, $24, $01
    NOTE 2, $24, $02
    NOTE 2, $24, $01
    SONGJUMP Song06_Ch4

Pat175:
    NOTE 3, D6, $2E
    NOTE 1, E6, $2E
    NOTE 1, Fs6, $2E
    KEYOFF 1
    NOTE 4, A6, $2E
    NOTE 2, D6, $2E
    NOTE 4, B6, $2E
    PATEND

Pat176:
    NOTE 4, D7, $2E
    NOTE 3, Cs7, $2E
    NOTE 1, A6, $2E
    NOTE 1, Cs7, $2E
    KEYOFF 1
    NOTE 2, E7, $2E
    NOTE 3, D7, $2E
    KEYOFF 1
    PATEND

Pat177:
    NOTE 2, A2, $03
    NOTE 2, D5, $06
    NOTE 2, D2, $03
    NOTE 2, D5, $06
    NOTE 2, A2, $03
    NOTE 2, D5, $06
    NOTE 2, G2, $03
    NOTE 2, D5, $09
    PATEND

Pat178:
    NOTE 2, Gs2, $03
    NOTE 2, D5, $09
    NOTE 2, A2, $03
    NOTE 2, Cs5, $0F
    NOTE 2, Cs3, $03
    NOTE 2, Cs5, $0F
    NOTE 2, D3, $03
    NOTE 2, Fs4, $0F
    PATEND

Pat179:
    NOTE 16, D2, $03
    PATEND

Pat180:
    NOTE 2, G4, $22
    NOTE 1, E4, $22
    NOTE 1, Cs4, $22
    NOTE 1, D4, $22
    NOTE 1, Fs4, $22
    NOTE 1, A4, $22
    NOTE 1, Fs4, $22
    NOTE 1, D4, $22
    NOTE 1, Fs4, $22
    NOTE 1, A4, $22
    NOTE 1, Fs4, $22
    NOTE 1, B5, $22
    NOTE 1, G5, $22
    NOTE 1, D5, $22
    NOTE 1, B4, $22
    PATEND

Pat181:
    NOTE 1, B5, $22
    NOTE 1, G5, $22
    NOTE 1, D5, $22
    NOTE 1, B4, $22
    NOTE 1, A4, $22
    NOTE 1, Cs5, $22
    NOTE 1, E5, $22
    NOTE 1, Cs5, $22
    NOTE 1, A4, $22
    NOTE 1, Cs5, $22
    NOTE 1, E5, $22
    NOTE 1, Cs5, $22
    NOTE 4, D5, $22
    PATEND

Pat182:
    NOTE 16, A4, $2F
    PATEND

Pat183:
    NOTE 2, $24, $02
    NOTE 2, $24, $01
    NOTE 2, $24, $FF
    NOTE 2, $24, $01
    NOTE 2, $24, $FF
    NOTE 2, $24, $01
    NOTE 2, $24, $FF
    NOTE 2, $24, $01
    NOTE 2, $24, $FF
    NOTE 2, $24, $01
    NOTE 2, $24, $FF
    NOTE 2, $24, $01
    NOTE 2, $24, $FF
    NOTE 2, $24, $01
    NOTE 2, $24, $FF
    NOTE 2, $24, $01
    NOTE 2, $24, $01
    PATEND

Pat190:
    NOTE 2, C3, $05
    NOTE 1, Ds4, $0B
    NOTE 2, Ds3, $05
    NOTE 1, Ds4, $06
    NOTE 1, F3, $05
    NOTE 1, C4, $09
    NOTE 2, C3, $05
    NOTE 1, Ds4, $0B
    NOTE 2, Ds3, $05
    NOTE 1, Ds4, $06
    NOTE 1, F3, $05
    NOTE 1, C4, $09
    PATEND

Pat191:
    NOTE 8, G2, $05
    NOTE 8, C3, $05
    PATEND

Pat192:
    NOTE 3, C2, $05
    NOTE 3, Ds2, $05
    NOTE 2, F2, $05
    NOTE 3, C2, $05
    NOTE 3, Ds2, $05
    NOTE 2, F2, $05
    PATEND

Pat193:
    NOTE 8, B3, $31
    NOTE 8, E4, $31
    PATEND

Pat194:
    NOTE 1, F5, $2C
    NOTE 1, Fs5, $2C
    NOTE 1, G5, $2C
    NOTE 1, C6, $2C
    KEYOFF 1
    NOTE 1, G5, $2C
    NOTE 1, C6, $2C
    KEYOFF 3
    NOTE 1, G5, $2C
    NOTE 1, C6, $2C
    NOTE 1, As5, $2C
    NOTE 1, A5, $2C
    NOTE 1, G5, $2C
    NOTE 1, F5, $2C
    PATEND

Pat195:
    NOTE 8, Fs5, $40
    NOTE 4, C5, $2C
    KEYOFF 2
    PATEND

Pat196:
    NOTE 1, $24, $02
    NOTE 2, $24, $05
    NOTE 1, $24, $05
    NOTE 1, $24, $02
    NOTE 1, $24, $02
    NOTE 1, $24, $05
    NOTE 1, $24, $05
    NOTE 1, $24, $02
    NOTE 2, $24, $05
    NOTE 1, $24, $05
    NOTE 1, $24, $02
    NOTE 1, $24, $02
    NOTE 1, $24, $05
    NOTE 1, $24, $05
    NOTE 8, $24, $05
    NOTE 8, $24, $05
    PATEND

Pat184:
    HOLD 1
    PATEND

    ; $68FE-$6905: 8 unreferenced bytes
    db $00, $00, $3C, $30, $33, $00, $00, $00

OrphanTab_6906:
    TB 1, $01
    TB 1, $00
    TLOOP OrphanTab_6906

Comb_690D:
    TB 255, $00 ; freq table only
    TLOOP Comb_690D

Comb_6912:
    TB 255, $01 ; note only
    TLOOP Comb_6912

Comb_6917:
    TB 255, $02 ; note + freq table
    TLOOP Comb_6917

Arp_691C:
    TB 255, $00 ; +0
    TLOOP Arp_691C

Freq_6921:
    TW 255, 0
    TLOOP Freq_6921

OrphanTab_6927:
    TB 255, $00
    TLOOP OrphanTab_6927

OrphanTab_692C:
    TW 20, 0

OrphanTab_692C_Loop:
    TW 2, 1
    TW 2, -1
    TW 2, -1
    TW 2, 1
    TLOOP OrphanTab_692C_Loop

OrphanTab_693E:
    TW 3, 10
    TW 3, -10
    TW 3, -10
    TW 3, 10
    TLOOP OrphanTab_693E

OrphanTab_694D:
    TW 3, 5
    TW 3, -5
    TW 3, -5
    TW 3, 5
    TLOOP OrphanTab_694D

Freq_695C:
    TW 20, 0

Freq_695F:
    TW 3, 2
    TW 3, -2
    TW 3, -2
    TW 3, 2
    TLOOP Freq_695F

Freq_696E:
    TW 3, 1
    TW 3, -1
    TW 3, -1
    TW 3, 1
    TLOOP Freq_696E

Freq_697D:
    TW 1, 1
    TW 2, 0
    TW 1, -1
    TW 2, 0
    TW 1, -1
    TW 2, 0
    TW 1, 1
    TW 2, 0
    TLOOP Freq_697D

Freq_6998:
    TW 1, -12
    TW 6, 2

Freq_699E:
    TW 3, 2
    TW 3, -2
    TW 3, -2
    TW 3, 2
    TW 2, 2
    TW 2, -2
    TW 2, -2
    TW 2, 2
    TW 2, 3
    TW 2, -3
    TW 2, -3
    TW 2, 3
    TW 2, 4
    TW 2, -4
    TW 2, -4
    TW 2, 4
    TW 2, 5
    TW 2, -5
    TW 2, -5
    TW 2, 5
    TW 2, 6
    TW 2, -6
    TW 2, -6
    TW 2, 6
    TW 2, 7
    TW 2, -7
    TW 2, -7
    TW 2, 7
    TW 2, 8
    TW 2, -8
    TW 2, -8
    TW 2, 8
    TW 2, 12
    TW 2, -12
    TW 2, -12
    TW 2, 12

Freq_699E_L0:
    TW 2, 16
    TW 2, -16
    TW 2, -16
    TW 2, 16
    TLOOP Freq_699E_L0

Vol_6A19:
    TB 1, $60 ; 25%
    TB 1, $40 ; 50%

Vol_6A19_L0:
    TB 255, $20 ; 100%
    TLOOP Vol_6A19_L0

Vol_6A22:
    TB 255, $20 ; 100%
    TLOOP Vol_6A22

Vol_6A27:
    TB 255, $40 ; 50%
    TLOOP Vol_6A27

Vol_6A2C:
    TB 255, $60 ; 25%
    TLOOP Vol_6A2C

Ins00:
    INS_TONE $80, $01, $01, Arp_691C, Freq_6921, Comb_6912 ; $00

NoiseIns00:
    INS_NOISE $00, $01, $01, Noise_6E12, Arp_691C ; $00

Ins01:
    INS_WAVE BlankVol, BlankVol, Arp_691C, Freq_6921, Comb_6917 ; $01, $02

Ins03:
    INS_TONE $80, $F2, $31, Arp_6A54, Freq_696E, Comb_6917 ; $03

Arp_6A54:
    TB 1, $0C ; +12

Arp_6A54_L0:
    TB 4, $00 ; +0
    TB 3, $0C ; +12
    TLOOP Arp_6A54_L0

Ins04:
    INS_TONE $60, $F2, $11, Arp_6A66, Freq_695F, Comb_6917 ; $04

Arp_6A66:
    TB 6, $00 ; +0
    TB 6, $0C ; +12
    TLOOP Arp_6A66

Ins05:
    INS_TONE $60, $F5, $61, Arp_6A76, Freq_695F, Comb_6917 ; $05

Arp_6A76:
    TB 1, $0C ; +12
    TB 1, $00 ; +0
    TB 1, $0C ; +12
    TB 1, $00 ; +0
    TB 255, $00 ; +0
    TLOOP Arp_6A76

Ins06:
    INS_TONE $60, $A3, $11, Arp_6B2E, Freq_6921, Comb_6917 ; $06

Ins51:
    INS_TONE $60, $82, $11, Arp_6A95, Freq_6921, Comb_6917 ; $33

Arp_6A95:
    TB 1, $00 ; +0
    TB 1, $04 ; +4
    TB 1, $07 ; +7
    TLOOP Arp_6A95

Ins07:
    INS_TONE $60, $A3, $11, Arp_6B37, Freq_6921, Comb_6917 ; $07

Ins08:
    INS_TONE $60, $A3, $11, Arp_6B40, Freq_6921, Comb_6917 ; $08

Ins09:
    INS_TONE $60, $A3, $11, Arp_6B49, Freq_6921, Comb_6917 ; $09

Ins52:
    INS_TONE $60, $82, $11, Arp_6AC2, Freq_6921, Comb_6917 ; $34

Arp_6AC2:
    TB 1, $00 ; +0
    TB 1, $05 ; +5
    TB 1, $09 ; +9
    TLOOP Arp_6AC2

Ins10:
    INS_TONE $60, $A3, $11, Arp_6B52, Freq_6921, Comb_6917 ; $0A

Ins11:
    INS_TONE $60, $A3, $11, Arp_6B5B, Freq_6921, Comb_6917 ; $0B

Ins12:
    INS_TONE $60, $A3, $11, Arp_6B64, Freq_6921, Comb_6917 ; $0C (unused)

Ins13:
    INS_TONE $60, $A3, $11, Arp_6B6F, Freq_6921, Comb_6917 ; $0D (unused)

Ins14:
    INS_TONE $60, $A3, $11, Arp_6B7A, Freq_6921, Comb_6917 ; $0E (unused)

Ins15:
    INS_TONE $60, $A3, $11, Arp_6B85, Freq_6921, Comb_6917 ; $0F

Ins45:
    INS_TONE $60, $A3, $11, Arp_6B25, Freq_6921, Comb_6917 ; $2D

Ins47:
    INS_TONE $40, $C7, $11, Arp_6B49, Freq_6921, Comb_6917 ; $2F

Ins48:
    INS_TONE $40, $C7, $11, Arp_6B5B, Freq_6921, Comb_6917 ; $30

Ins49:
    INS_TONE $40, $C7, $11, Arp_6B85, Freq_6921, Comb_6917 ; $31

Arp_6B25:
    TB 2, $00 ; +0
    TB 2, $05 ; +5
    TB 2, $07 ; +7
    TLOOP Arp_6B25

Arp_6B2E:
    TB 2, $00 ; +0
    TB 2, $04 ; +4
    TB 2, $07 ; +7
    TLOOP Arp_6B2E

Arp_6B37:
    TB 2, $00 ; +0
    TB 2, $03 ; +3
    TB 2, $07 ; +7
    TLOOP Arp_6B37

Arp_6B40:
    TB 2, $00 ; +0
    TB 2, $05 ; +5
    TB 2, $08 ; +8
    TLOOP Arp_6B40

Arp_6B49:
    TB 2, $00 ; +0
    TB 2, $05 ; +5
    TB 2, $09 ; +9
    TLOOP Arp_6B49

Arp_6B52:
    TB 2, $00 ; +0
    TB 2, $03 ; +3
    TB 2, $09 ; +9
    TLOOP Arp_6B52

Arp_6B5B:
    TB 2, $00 ; +0
    TB 2, $04 ; +4
    TB 2, $09 ; +9
    TLOOP Arp_6B5B

Arp_6B64:
    TB 2, $00 ; +0
    TB 2, $03 ; +3
    TB 2, $07 ; +7
    TB 2, $0A ; +10
    TLOOP Arp_6B64

Arp_6B6F:
    TB 2, $00 ; +0
    TB 2, $04 ; +4
    TB 2, $07 ; +7
    TB 2, $0A ; +10
    TLOOP Arp_6B6F

Arp_6B7A:
    TB 2, $00 ; +0
    TB 2, $04 ; +4
    TB 2, $07 ; +7
    TB 2, $0B ; +11
    TLOOP Arp_6B7A

Arp_6B85:
    TB 2, $00 ; +0
    TB 2, $03 ; +3
    TB 2, $08 ; +8
    TLOOP Arp_6B85

Arp_6B8E:
    TB 2, $00 ; +0
    TB 2, $03 ; +3
    TB 2, $0A ; +10
    TLOOP Arp_6B8E

Ins32:
    INS_TONE $80, $A4, $31, Arp_6BA9, Freq_697D, Comb_6917 ; $20

Ins33:
    INS_TONE $80, $82, $11, Arp_6BA9, Freq_697D, Comb_6917 ; $21

Arp_6BA9:
    TB 1, $00 ; +0
    TB 1, $0C ; +12
    TLOOP Arp_6BA9

Ins34:
    INS_TONE $80, $78, $83, Arp_691C, Freq_699E, Comb_6917 ; $22

Ins35:
    INS_TONE $40, $78, $83, Arp_691C, Freq_6998, Comb_6917 ; $23 (unused)

Ins36:
    INS_TONE $80, $A8, $A4, Arp_691C, Freq_695C, Comb_6917 ; $24 (unused)

Ins37:
    INS_TONE $80, $A8, $A4, Arp_691C, Freq_6BD4, Comb_6917 ; $25 (unused)

Freq_6BD4:
    TW 1, -20
    TW 5, 4
    TLOOP Freq_695C

Ins44:
    INS_WAVE Vol_6A19, Vol_6A2C, Arp_691C, Freq_697D, Comb_6917 ; $2C

Ins64:
    INS_WAVE Vol_6A19, Vol_6A2C, Arp_6BF1, Freq_697D, Comb_6917 ; $40

Arp_6BF1:
    TB 4, $00 ; +0
    TB 4, $01 ; +1
    TLOOP Arp_6BF1

Ins46:
    INS_WAVE Vol_6A19, Vol_6A2C, Arp_6C02, Freq_697D, Comb_6917 ; $2E

Arp_6C02:
    TB 1, $FD ; -3
    TB 1, $FE ; -2
    TB 1, $FF ; -1

Arp_6C02_L0:
    TB 255, $00 ; +0
    TLOOP Arp_6C02_L0

Ins16:
    INS_WAVE Vol_6D03, Vol_6A2C, Arp_6CAD, Freq_6921, Comb_6917 ; $10 (unused)

Ins17:
    INS_WAVE Vol_6D03, Vol_6A2C, Arp_6CB4, Freq_6921, Comb_6917 ; $11 (unused)

Ins18:
    INS_WAVE Vol_6D03, Vol_6A2C, Arp_6CBB, Freq_6921, Comb_6917 ; $12

Ins19:
    INS_WAVE Vol_6D03, Vol_6A2C, Arp_6CC2, Freq_6921, Comb_6917 ; $13

Ins20:
    INS_WAVE Vol_6D03, Vol_6A2C, Arp_6CC9, Freq_6921, Comb_6917 ; $14

Ins21:
    INS_WAVE Vol_6D03, Vol_6A2C, Arp_6CD0, Freq_6921, Comb_6917 ; $15

Ins22:
    INS_WAVE Vol_6D03, Vol_6A2C, Arp_6CD7, Freq_6921, Comb_6917 ; $16 (unused)

Ins23:
    INS_WAVE Vol_6D03, Vol_6A2C, Arp_6CDE, Freq_6921, Comb_6917 ; $17

Ins24:
    INS_WAVE Vol_6D03, Vol_6A2C, Arp_6CE5, Freq_6921, Comb_6917 ; $18

Ins25:
    INS_WAVE Vol_6D03, Vol_6A2C, Arp_6CEC, Freq_6921, Comb_6917 ; $19

Ins26:
    INS_WAVE Vol_6D03, Vol_6A2C, Arp_6CF3, Freq_6921, Comb_6917 ; $1A (unused)

Ins27:
    INS_WAVE Vol_6D03, Vol_6A2C, Arp_6CFA, Freq_6921, Comb_6917 ; $1B

Ins53:
    INS_WAVE Vol_6D01, Vol_6A2C, Arp_6B2E, Freq_6921, Comb_6917 ; $35

Ins54:
    INS_WAVE Vol_6D01, Vol_6A2C, Arp_6B5B, Freq_6921, Comb_6917 ; $36

Ins55:
    INS_WAVE Vol_6D01, Vol_6A2C, Arp_6B85, Freq_6921, Comb_6917 ; $37

Ins56:
    INS_WAVE Vol_6D01, Vol_6A2C, Arp_6B8E, Freq_6921, Comb_6917 ; $38

Arp_6CAD:
    TB 2, $00 ; +0
    TB 2, $01 ; +1
    TLOOP Arp_6CAD

Arp_6CB4:
    TB 2, $00 ; +0
    TB 2, $02 ; +2
    TLOOP Arp_6CB4

Arp_6CBB:
    TB 2, $00 ; +0
    TB 2, $03 ; +3
    TLOOP Arp_6CBB

Arp_6CC2:
    TB 2, $00 ; +0
    TB 2, $04 ; +4
    TLOOP Arp_6CC2

Arp_6CC9:
    TB 2, $00 ; +0
    TB 2, $05 ; +5
    TLOOP Arp_6CC9

Arp_6CD0:
    TB 2, $00 ; +0
    TB 2, $06 ; +6
    TLOOP Arp_6CD0

Arp_6CD7:
    TB 2, $00 ; +0
    TB 2, $07 ; +7
    TLOOP Arp_6CD7

Arp_6CDE:
    TB 2, $00 ; +0
    TB 2, $08 ; +8
    TLOOP Arp_6CDE

Arp_6CE5:
    TB 2, $00 ; +0
    TB 2, $09 ; +9
    TLOOP Arp_6CE5

Arp_6CEC:
    TB 2, $00 ; +0
    TB 2, $0A ; +10
    TLOOP Arp_6CEC

Arp_6CF3:
    TB 2, $00 ; +0
    TB 2, $0B ; +11
    TLOOP Arp_6CF3

Arp_6CFA:
    TB 2, $00 ; +0
    TB 2, $0C ; +12
    TLOOP Arp_6CFA

Vol_6D01:
    TB 4, $20 ; 100%

Vol_6D03:
    TB 4, $20 ; 100%
    TB 8, $40 ; 50%
    TB 255, $60 ; 25%
    TLOOP BlankVol

Ins38:
    INS_WAVE Vol_6A22, Vol_6A2C, Arp_691C, Freq_6DB2, Comb_6917 ; $26

Ins39:
    INS_WAVE Vol_6A22, Vol_6A2C, Arp_691C, Freq_6DAC, Comb_6917 ; $27

Ins42:
    INS_WAVE Vol_6D34, Vol_6A2C, Arp_691C, Freq_6DB2, Comb_6917 ; $2A (unused)

Ins43:
    INS_WAVE Vol_6D34, Vol_6A2C, Arp_691C, Freq_6DAC, Comb_6917 ; $2B (unused)

Vol_6D34:
    TB 2, $20 ; 100%

Vol_6D34_L0:
    TB 255, $40 ; 50%
    TLOOP Vol_6D34_L0

Ins28:
    INS_TONE $80, $E1, $21, Arp_6D59, Freq_6D44, Comb_690D ; $1C, $1E

Freq_6D44:
    TW 1, 1100
    TW 1, 100
    TW 255, -80
    TLOOP Freq_6D44

Ins29:
    INS_TONE $80, $F1, $21, Arp_6D59, Freq_6D60, Comb_690D ; $1D

Arp_6D59:
    TB 1, $00 ; +0
    TB 1, $02 ; +2
    TLOOP Arp_6D59

Freq_6D60:
    TW 1, 1700
    TW 2, -60

Freq_6D60_L0:
    TW 1, 100
    TW 255, -60
    TLOOP Freq_6D60_L0

Ins31:
    INS_TONE $80, $51, $21, Arp_6D87, Freq_6D78, Comb_690D ; $1F

Freq_6D78:
    TW 1, 4060
    TW 1, -1
    TW 1, -4060

Freq_6D78_L0:
    TW 255, 0
    TLOOP Freq_6D78_L0

Arp_6D87:
    TB 1, $00 ; +0
    TB 1, $FF ; -1
    TB 1, $FE ; -2
    TB 1, $FD ; -3
    TLOOP Arp_6D87

Ins40:
    INS_WAVE Vol_6A22, Vol_6A2C, Arp_691C, Freq_697D, Comb_6917 ; $28 (unused)

Ins41:
    INS_WAVE Vol_6A27, Vol_6A2C, Arp_691C, Freq_697D, Comb_6917 ; $29 (unused)

    ; $6DA6-$6DAB: 6 unreferenced bytes
    db $32, $00, $00, $00, $B2, $6D

Freq_6DAC:
    TW 1, -10
    TW 5, 2

Freq_6DB2:
    TW 12, 0

Freq_6DB2_L0:
    TW 3, 1
    TW 3, -1
    TW 3, -1
    TW 3, 1
    TW 3, 2
    TW 3, -2
    TW 3, -2
    TW 3, 2
    TW 3, 3
    TW 3, -3
    TW 3, -3
    TW 3, 3
    TLOOP Freq_6DB2_L0

OrphanIns_6DDC:
    INS_TONE $80, $01, $00, Arp_691C, Freq_6921, Comb_6917 ; not in the instrument table

NoiseIns02:
    INS_NOISE $00, $51, $91, Noise_6DEC, Arp_691C ; $02

Noise_6DEC:
    TB 255, $44
    TLOOP Noise_6DEC

NoiseIns04:
    INS_NOISE $00, $47, $01, Noise_6DFF, Arp_691C ; $04 (unused)

NoiseIns03:
    INS_NOISE $20, $41, $01, Noise_6DFF, Noise_6DFF ; $03 (unused)

Noise_6DFF:
    TB 255, $13
    TLOOP Noise_6DFF

NoiseIns05:
    INS_NOISE $80, $71, $01, Noise_6E12, Arp_691C ; $05

NoiseIns01:
    INS_NOISE $80, $44, $01, Noise_6E12, Arp_691C ; $01

Noise_6E12:
    TB 255, $32
    TLOOP Noise_6E12

OrphanTab_6E17:
    TB 2, $37
    TB 255, $32
    TLOOP OrphanTab_6E17

Ins50:
    INS_WAVE Vol_6A19, Vol_6A2C, Arp_691C, Freq_6E28, Comb_6EB8 ; $32

Freq_6E28:
    TW 1, 1
    TW 2, 0
    TW 1, -1
    TW 2, 0
    TW 1, -1
    TW 2, 0
    TW 1, 1
    TW 2, 0
    TW 1, 1
    TW 2, 0
    TW 1, -1
    TW 2, 0
    TW 1, -1
    TW 2, 0
    TW 1, 1
    TW 2, 0
    TW 1, 1
    TW 2, 0
    TW 1, -1
    TW 2, 0
    TW 1, -1
    TW 2, 0
    TW 1, 1
    TW 2, 0

Freq_6E28_L0:
    TW 1, -1
    TW 2, 0
    TLOOP Freq_6E28_L0

Ins57:
    INS_TONE $C0, $E8, $81, Arp_691C, Freq_6921, Comb_6912 ; $39

Ins60:
    INS_TONE $80, $F1, $21, Arp_6E8B, Freq_6921, Comb_6912 ; $3C

Arp_6E8B:
    TB 4, $00 ; +0
    TLOOP Arp_6E8B

Ins58:
    INS_TONE $00, $F1, $E2, Arp_6EA2, Freq_6921, Comb_6912 ; $3A

Ins59:
    INS_TONE $40, $F1, $E2, Arp_6EAD, Freq_6921, Comb_6912 ; $3B

Arp_6EA2:
    TB 1, $02 ; +2
    TB 1, $04 ; +4
    TB 1, $06 ; +6
    TB 2, $08 ; +8
    TLOOP Arp_6EA2

Arp_6EAD:
    TB 1, $08 ; +8
    TB 1, $06 ; +6
    TB 1, $04 ; +4
    TB 2, $02 ; +2
    TLOOP Arp_6EAD

Comb_6EB8:
    TB 36, $02 ; note + freq table

Comb_6EB8_L0:
    TB 1, $01 ; note only
    TB 1, $02 ; note + freq table
    TLOOP Comb_6EB8_L0

Ins61:
    INS_TONE $60, $F3, $F4, Arp_6ECA, Freq_6ED5, Comb_6EB8_L0 ; $3D

Arp_6ECA:
    TB 1, $00 ; +0
    TB 1, $01 ; +1
    TB 1, $02 ; +2
    TB 1, $01 ; +1
    TLOOP Arp_6ECA

Freq_6ED5:
    TW 4, 6
    TW 4, -3
    TLOOP Freq_6ED5

NoiseIns06:
    INS_NOISE $80, $89, $81, Noise_6EE5, Arp_691C ; $06, $07

Noise_6EE5:
    TB 2, $34
    TB 2, $46
    TB 2, $45
    TB 2, $44
    TB 2, $43
    TB 2, $42
    TB 255, $41
    TLOOP Noise_6EE5

Ins67:
    INS_TONE $80, $89, $91, Arp_691C, Freq_6EFF, Comb_6917 ; $43

Freq_6EFF:
    TW 255, -10
    TLOOP Freq_6F34

NoiseIns08:
    INS_NOISE $80, $F1, $E1, Noise_6F13, Arp_691C ; $08

NoiseIns09:
    INS_NOISE $80, $F1, $31, Noise_6F18, Arp_691C ; $09

Noise_6F13:
    TB 8, $33
    TLOOP Noise_6F13

Noise_6F18:
    TB 255, $42
    TLOOP Noise_6F18

NoiseIns11:
    INS_NOISE $04, $A1, $A1, Noise_6F24, Arp_691C ; $0B

Noise_6F24:
    TB 6, $42
    TB 6, $46
    TLOOP Noise_6F24

Ins62:
    INS_TONE $80, $89, $91, Arp_691C, Freq_6F34, Comb_6917 ; $3E

Freq_6F34:
    TW 255, 8
    TLOOP Freq_6F34

NoiseIns10:
    INS_NOISE $80, $C8, $41, Noise_6F41, Arp_691C ; $0A

Noise_6F41:
    TB 5, $1A
    TB 255, $28
    TLOOP Noise_6F41

NoiseIns12:
    INS_NOISE $80, $19, $E3, Noise_6F4F, Arp_691C ; $0C

Noise_6F4F:
    TB 255, $30
    TLOOP Noise_6F4F

Ins63:
    INS_TONE $00, $A8, $81, Arp_691C, Freq_6F5D, Comb_6917 ; $3F

Freq_6F5D:
    TW 5, 10
    TW 5, -10
    TLOOP Freq_6F5D

NoiseIns13:
    INS_NOISE $80, $88, $41, Noise_6F6D, Arp_691C ; $0D

Noise_6F6D:
    TB 3, $3B
    TB 1, $3D
    TB 2, $3B
    TB 1, $3D
    TB 6, $3B
    TB 2, $3D
    TB 4, $3B
    TB 1, $3D
    TB 8, $3B
    TB 2, $3D
    TB 2, $3B
    TB 1, $3D
    TLOOP Noise_6F6D

NoiseIns14:
    INS_NOISE $80, $F1, $A1, Noise_6F8F, Arp_691C ; $0E

Noise_6F8F:
    TB 2, $46
    TB 2, $45
    TLOOP Noise_6F8F

Ins65:
    INS_TONE $80, $A8, $A4, Arp_6F9F, Freq_6FB6, Comb_6917 ; $41

Arp_6F9F:
    TB 1, $00 ; +0
    TB 1, $01 ; +1
    TB 1, $02 ; +2
    TB 1, $03 ; +3
    TB 1, $04 ; +4
    TB 1, $05 ; +5
    TB 1, $04 ; +4
    TB 1, $03 ; +3
    TB 1, $02 ; +2
    TB 1, $01 ; +1
    TLOOP Arp_6F9F

Freq_6FB6:
    TW 10, 1
    TW 10, -1
    TLOOP Freq_6FB6

NoiseIns15:
    INS_NOISE $80, $F2, $41, Noise_6FC6, Arp_691C ; $0F

Noise_6FC6:
    TB 3, $28
    TLOOP Noise_6FC6

NoiseIns16:
    INS_NOISE $80, $F1, $11, Noise_6FD2, Arp_691C ; $10

Noise_6FD2:
    TB 255, $3B
    TLOOP Noise_6FD2

Ins66:
    INS_TONE $40, $F3, $11, Arp_6FF0, Freq_6FE0, Comb_6FE9 ; $42

Freq_6FE0:
    TW 5, 5
    TW 5, -5
    TLOOP Freq_6FE0

Comb_6FE9:
    TB 4, $01 ; note only
    TB 1, $02 ; note + freq table
    TLOOP Comb_6FE9

Arp_6FF0:
    TB 4, $00 ; +0
    TB 4, $05 ; +5
    TB 4, $0C ; +12
    TLOOP Arp_6FF0

Wave_6FF9:
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

Morph_7009:
    MORPH 255, $30, $00
    TLOOP Morph_7009

    ; $700F-$701B: 13 unreferenced bytes
    db $7A, $EF, $EC, $B7, $55, $41, $02, $36, $BD, $CC, $DD, $BA, $72

OrphanMorph_701C:
    MORPH 2, $33, $56

OrphanMorph_701C_Loop:
    MORPH 255, $30, $7A
    TLOOP OrphanMorph_701C_Loop

Wave_7025:
    db $A0, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

    ; $7035-$7044: 16 unreferenced bytes
    db $AE, $FF, $EE, $FF, $ED, $DD, $DD, $B7, $31, $01, $34, $32, $33, $31, $00, $05

Wave_7045:
    db $FE, $DB, $97, $63, $10, $03, $59, $BE, $FE, $DB, $97, $63, $10, $03, $58, $BD

Morph_7055:
    MORPH 255, $30, $FE
    TLOOP Morph_7055

Wave_705B:
    db $BD, $DD, $CA, $86, $42, $22, $34, $69, $BD, $DD, $CA, $86, $42, $22, $34, $79

Morph_706B:
    MORPH 224, $30, $BD
    TLOOP Morph_706B

    ; $7071-$7080: 16 unreferenced bytes
    db $CE, $FF, $EB, $95, $31, $00, $13, $69, $CE, $FF, $EB, $85, $31, $00, $13, $69

OrphanMorph_7081:
    MORPH 255, $30, $CE
    TLOOP OrphanMorph_7081

OrphanMorph_7087:
    MORPH 220, $30, $AE
    TLOOP OrphanMorph_7087

Morph_708D:
    MORPH 224, $30, $FE
    MORPH 224, $30, $FE

Morph_708D_L0:
    MORPH 224, $30, $FE
    MORPH 224, $30, $FE
    MORPH 224, $30, $FE
    MORPH 112, $30, $FE
    MORPH 7, $30, $CE
    MORPH 7, $31, $FF
    MORPH 7, $32, $EB
    MORPH 7, $33, $95
    MORPH 7, $34, $31
    MORPH 7, $35, $00
    MORPH 7, $36, $13
    MORPH 7, $37, $69
    MORPH 7, $38, $CE
    MORPH 7, $39, $FF
    MORPH 7, $3A, $EB
    MORPH 7, $3B, $85
    MORPH 7, $3C, $31
    MORPH 7, $3D, $00
    MORPH 7, $3E, $13
    MORPH 7, $3F, $69
    MORPH 224, $30, $CE
    MORPH 224, $30, $CE
    MORPH 224, $30, $CE
    MORPH 112, $30, $CE
    MORPH 7, $30, $00
    MORPH 7, $31, $11
    MORPH 7, $32, $22
    MORPH 7, $33, $33
    MORPH 7, $34, $44
    MORPH 7, $35, $55
    MORPH 7, $36, $66
    MORPH 7, $37, $77
    MORPH 7, $38, $88
    MORPH 7, $39, $99
    MORPH 7, $3A, $AA
    MORPH 7, $3B, $BB
    MORPH 7, $3C, $CC
    MORPH 7, $3D, $DD
    MORPH 7, $3E, $EE
    MORPH 7, $3F, $FF
    MORPH 224, $30, $7D
    MORPH 224, $30, $7D
    MORPH 224, $30, $7D
    MORPH 224, $30, $7D
    MORPH 7, $30, $FE
    MORPH 7, $31, $DB
    MORPH 7, $32, $97
    MORPH 7, $33, $63
    MORPH 7, $34, $10
    MORPH 7, $35, $03
    MORPH 7, $36, $59
    MORPH 7, $37, $BE
    MORPH 7, $38, $FE
    MORPH 7, $39, $DB
    MORPH 7, $3A, $97
    MORPH 7, $3B, $63
    MORPH 7, $3C, $10
    MORPH 7, $3D, $03
    MORPH 7, $3E, $58
    MORPH 7, $3F, $BD
    TLOOP Morph_708D_L0

Morph_714A:
    MORPH 8, $30, $A0
    MORPH 8, $30, $AA
    MORPH 8, $31, $A0
    MORPH 8, $31, $AA
    MORPH 8, $32, $A0
    MORPH 8, $32, $AA
    MORPH 8, $33, $A0
    MORPH 8, $33, $AA
    MORPH 8, $34, $A0
    MORPH 8, $34, $AA
    MORPH 8, $35, $A0
    MORPH 8, $35, $AA
    MORPH 8, $36, $A0
    MORPH 8, $36, $AA
    MORPH 8, $37, $A0
    MORPH 8, $37, $AA
    MORPH 8, $38, $A0
    MORPH 8, $38, $AA
    MORPH 8, $39, $A0
    MORPH 8, $39, $AA
    MORPH 8, $3A, $A0
    MORPH 8, $3A, $AA
    MORPH 8, $3B, $A0
    MORPH 8, $3B, $AA
    MORPH 8, $3C, $A0
    MORPH 8, $3C, $AA
    MORPH 8, $3D, $A0
    MORPH 8, $3D, $AA
    MORPH 8, $3E, $A0
    MORPH 8, $3E, $AA
    MORPH 8, $3F, $A0
    MORPH 8, $3F, $00
    MORPH 8, $3E, $A0
    MORPH 8, $3E, $00
    MORPH 8, $3D, $A0
    MORPH 8, $3D, $00
    MORPH 8, $3C, $A0
    MORPH 8, $3C, $00
    MORPH 8, $3B, $A0
    MORPH 8, $3B, $00
    MORPH 8, $3A, $A0
    MORPH 8, $3A, $00
    MORPH 8, $39, $A0
    MORPH 8, $39, $00
    MORPH 8, $38, $A0
    MORPH 8, $38, $00
    MORPH 8, $37, $A0
    MORPH 8, $37, $00
    MORPH 8, $36, $A0
    MORPH 8, $36, $00
    MORPH 8, $35, $A0
    MORPH 8, $35, $00
    MORPH 8, $34, $A0
    MORPH 8, $34, $00
    MORPH 8, $33, $A0
    MORPH 8, $33, $00
    MORPH 8, $32, $A0
    MORPH 8, $32, $00
    MORPH 8, $31, $A0
    MORPH 8, $31, $00
    TLOOP Morph_714A
