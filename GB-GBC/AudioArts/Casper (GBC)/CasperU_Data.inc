; Casper (U) (GBC) - music/SFX data $4868-$675C

BlankVol:
    TB 33, $00 ; mute
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
    db 2 ; ch2  (SFX $00)
    dw Sfx01
    db 2 ; ch2  (SFX $01)
    dw Sfx02
    db 3 ; ch4  (SFX $02)
    dw Sfx03
    db 3 ; ch4  (SFX $03)
    dw Sfx04
    db 2 ; ch2  (SFX $04)
    dw Sfx05
    db 3 ; ch4  (SFX $05)
    dw Sfx06
    db 2 ; ch2  (SFX $06)
    dw Sfx07
    db 2 ; ch2  (SFX $07)
    dw Sfx08
    db 3 ; ch4  (SFX $08)
    dw Sfx09
    db 3 ; ch4  (SFX $09)
    dw Sfx0A
    db 3 ; ch4  (SFX $0A)
    dw Sfx0B
    db 3 ; ch4  (SFX $0B)
    dw Sfx0C
    db 3 ; ch4  (SFX $0C)
    dw Sfx0D
    db 3 ; ch4  (SFX $0D)
    dw Sfx0E
    db 3 ; ch4  (SFX $0E)
    dw Sfx0F
    db 2 ; ch2  (SFX $0F)
    dw Sfx10
    db 3 ; ch4  (SFX $10)
    dw Sfx11
    db 3 ; ch4  (SFX $11)
    dw Sfx12
    db 3 ; ch4  (SFX $12)
    dw Sfx13
    db 2 ; ch2  (SFX $13)
    dw Sfx14
    db 3 ; ch4  (SFX $14)
    dw Sfx15
    db 2 ; ch2  (SFX $15)
    dw Sfx16
    db 2 ; ch2  (SFX $16)
    dw Sfx17
    db 2 ; ch2  (SFX $17)
    dw Sfx18
    db 3 ; ch4  (SFX $18)

SongTable:
    dw Song00_Ch1, Song00_Ch1, Song00_Ch1, Song00_Ch1
    db 6 ; tempo (frames per tick)
    dw Wave_66E0 ; wave
    dw Song01_Ch1, Song01_Ch2, Song01_Ch3, Song01_Ch4
    db 9 ; tempo (frames per tick)
    dw Wave_66E0 ; wave
    dw Song02_Ch1, Song02_Ch2, Song02_Ch3, Song02_Ch4
    db 8 ; tempo (frames per tick)
    dw Wave_6720 ; wave
    dw Song03_Ch1, Song03_Ch2, Song03_Ch3, Song03_Ch4
    db 7 ; tempo (frames per tick)
    dw Wave_6740 ; wave
    db $00, $00, $32, $00, $00, $00, $32, $00, $00, $00, $32 ; (not a valid song)

    ; $4980-$4984: 5 unreferenced bytes
    db $00, $00, $00, $32, $00

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
    dw Ins24                    ; $18
    dw Ins25                    ; $19
    dw Ins26                    ; $1A
    dw Ins27                    ; $1B
    dw Ins28                    ; $1C
    dw Ins29                    ; $1D
    dw Ins30                    ; $1E
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

NoiseInstrumentTable:
    dw NoiseIns00               ; $00
    dw NoiseIns01               ; $01
    dw NoiseIns02               ; $02
    dw NoiseIns03               ; $03
    dw NoiseIns04               ; $04
    dw NoiseIns05               ; $05
    dw NoiseIns06               ; $06
    dw NoiseIns07               ; $07
    dw NoiseIns08               ; $08
    dw NoiseIns09               ; $09
    dw NoiseIns10               ; $0A
    dw NoiseIns11               ; $0B
    dw NoiseIns12               ; $0C
    dw NoiseIns13               ; $0D
    dw NoiseIns14               ; $0E
    dw NoiseIns15               ; $0F
    dw NoiseIns16               ; $10
    dw NoiseIns17               ; $11
    dw NoiseIns18               ; $12
    dw NoiseIns19               ; $13
    dw Ins53+2                  ; $14
    dw $0000                    ; $15

    ; $4AC5-$4AC5: 1 unreferenced byte
    db $00

Song00_Ch1:
    STEP 0, $053

Song01_Ch1:
    STEP -3, $00D, $FF
    STEP 0, $002
    STEP 0, $003
    STEP 0, $003
    STEP 0, $003
    STEP 0, $003
    STEP 0, $003
    STEP 0, $003
    STEP 0, $003
    STEP 0, $004
    STEP 0, $004
    STEP 3, $004
    STEP 3, $004
    STEP 0, $010
    STEP 0, $011
    STEP 2, $010
    STEP 2, $011
    STEP 0, $002
    STEP 2, $002
    STEP 2, $003
    STEP 2, $003
    STEP 2, $004
    STEP 2, $004
    STEP 2, $010
    STEP 2, $011
    STEP 0, $010
    STEP 0, $016

Song01_Ch2:
    STEP -3, $00E, $FF
    STEP 0, $001
    STEP 0, $006
    STEP 0, $006
    STEP 0, $006
    STEP 0, $006
    STEP 0, $031
    STEP 0, $007
    STEP 0, $007
    STEP 0, $007
    STEP 0, $007
    STEP 3, $007
    STEP 3, $007
    STEP 0, $012
    STEP 0, $013
    STEP 2, $012
    STEP 2, $013
    STEP 0, $001
    STEP 2, $001
    STEP 2, $007
    STEP 2, $007
    STEP 2, $007
    STEP 2, $007
    STEP 2, $012
    STEP 2, $013
    STEP 0, $012
    STEP 0, $017

Song01_Ch3:
    STEP -3, $005, $FF
    STEP 0, $005
    STEP 0, $01A
    STEP -12, $01A, $FF
    STEP 0, $008
    STEP 0, $009
    STEP 0, $005
    STEP 0, $01A
    STEP 0, $00C
    STEP 0, $00A
    STEP 0, $00B
    STEP 3, $008
    STEP 3, $009
    STEP 12, $014
    STEP 12, $015
    STEP 2, $014
    STEP 2, $015
    STEP 0, $005
    STEP 2, $005
    STEP 2, $01A
    STEP 2, $01A
    STEP 2, $00A
    STEP 2, $00B
    STEP 2, $014
    STEP 2, $015
    STEP 12, $014
    STEP 12, $018

Song01_Ch4:
    STEP 0, $000
    STEP 0, $000
    STEP 0, $000
    STEP 0, $000
    STEP 0, $000
    STEP 0, $000
    STEP 0, $000
    STEP 0, $00F
    STEP 0, $00F
    STEP 0, $00F
    STEP 0, $00F
    STEP 0, $00F
    STEP 0, $00F
    STEP 0, $00F
    STEP 0, $00F
    STEP 0, $00F
    STEP 0, $00F
    STEP 0, $000
    STEP 0, $000

Song01_Ch4_Loop:
    STEP 0, $019

Song02_Ch1:
    STEP 0, $022
    STEP 0, $022
    STEP 0, $023
    STEP 0, $024
    STEP 0, $025
    STEP 0, $026
    STEP 0, $023
    STEP 0, $024
    STEP 0, $025
    STEP 0, $026
    STEP 0, $022
    STEP 0, $022
    STEP 0, $022
    STEP 0, $022
    STEP 2, $02A
    STEP 2, $02B
    STEP 2, $02A
    STEP 2, $02B
    STEP 0, $025
    STEP 0, $02D

Song02_Ch2:
    STEP 0, $01B
    STEP 0, $01B
    STEP 0, $01B
    STEP 0, $01B
    STEP 0, $01C
    STEP 0, $01D
    STEP 0, $01B
    STEP 0, $01B
    STEP 0, $01C
    STEP 0, $01D
    STEP 0, $029
    STEP 0, $029
    STEP 2, $029
    STEP 2, $029
    STEP 2, $029
    STEP 2, $029
    STEP 2, $029
    STEP 2, $029
    STEP 0, $01C
    STEP 0, $02E

Song02_Ch3:
    STEP 0, $01E
    STEP 0, $01E
    STEP 0, $01F
    STEP 0, $01E
    STEP -12, $020, $FF
    STEP -12, $021, $FF
    STEP 0, $01F
    STEP 0, $01E
    STEP -12, $020, $FF
    STEP -12, $021, $FF
    STEP 0, $02C
    STEP 0, $02C
    STEP 0, $02C
    STEP 0, $02C
    STEP 2, $02C
    STEP 2, $02C
    STEP 2, $02C
    STEP 2, $02C
    STEP 2, $02C
    STEP 2, $02C
    STEP 2, $02C
    STEP 2, $02C
    STEP 2, $02C
    STEP 2, $02C
    STEP 2, $02C
    STEP 2, $02C
    STEP -12, $020, $FF
    STEP -12, $02F, $FF

Song02_Ch4:
    STEP 0, $027
    STEP 0, $028
    STEP 0, $028
    STEP 0, $028
    STEP 0, $028
    STEP 0, $028
    STEP 0, $028
    STEP 0, $028
    STEP 0, $028
    STEP 0, $028
    STEP 0, $027
    STEP 0, $027
    STEP 0, $028
    STEP 0, $028
    STEP 0, $028
    STEP 0, $028
    STEP 0, $028
    STEP 0, $028
    STEP 0, $028
    STEP 0, $030

Song03_Ch1:
    STEP 0, $04B
    STEP 0, $04B
    STEP 0, $04B
    STEP 0, $04B
    STEP 0, $039
    STEP 0, $03A
    STEP 0, $03B
    STEP 0, $03C
    STEP 0, $039
    STEP 0, $03A
    STEP 0, $03B
    STEP 0, $03C
    STEP 0, $03D
    STEP 0, $03E
    STEP 0, $03D
    STEP 0, $03F
    STEP 0, $03D
    STEP 0, $03E
    STEP 0, $03D
    STEP 0, $03F
    STEP 0, $039
    STEP 0, $03A
    STEP 0, $03B
    STEP 0, $03C
    STEP 0, $039
    STEP 0, $03A
    STEP 0, $03B
    STEP 0, $03C
    STEP 0, $03D
    STEP 0, $03E
    STEP 0, $03D
    STEP 0, $03F
    STEP 0, $03D
    STEP 0, $03E
    STEP 0, $03D
    STEP 0, $03F
    STEP 0, $040
    STEP 2, $041
    STEP 2, $03B
    STEP 0, $042
    STEP 0, $040
    STEP 2, $041
    STEP 2, $03B
    STEP 0, $042
    STEP 2, $04F
    STEP 2, $050
    STEP 2, $04F
    STEP 2, $051
    STEP 2, $04F
    STEP 2, $050
    STEP 2, $04F
    STEP 2, $052
    STEP 0, $04B
    STEP 0, $04B
    STEP 0, $04B
    STEP 0, $04B
    STEP 0, $04B
    STEP 0, $04B
    STEP 0, $04B
    STEP 0, $04B
    STEP 2, $047
    STEP 2, $048
    STEP 14, $047
    STEP 14, $048
    STEP 2, $047
    STEP 2, $048
    STEP -10, $047, $FF
    STEP 0, $049
    STEP 0, $039
    STEP 0, $03A
    STEP 0, $03B
    STEP 0, $03C
    STEP -2, $040, $FF
    STEP 0, $041
    STEP -2, $040, $FF
    STEP -2, $04E, $FF

Song03_Ch2:
    STEP 0, $043
    STEP -4, $045, $FF
    STEP 0, $043
    STEP 0, $044
    STEP 0, $043
    STEP -4, $045, $FF
    STEP 0, $043
    STEP 0, $044
    STEP 0, $043
    STEP -4, $045, $FF
    STEP 0, $043
    STEP 0, $044
    STEP 0, $043
    STEP -4, $045, $FF
    STEP 0, $043
    STEP 0, $044
    STEP 0, $043
    STEP -4, $045, $FF
    STEP 0, $043
    STEP 0, $044
    STEP 0, $043
    STEP -4, $045, $FF
    STEP 0, $043
    STEP 0, $044
    STEP 0, $043
    STEP -4, $045, $FF
    STEP 0, $043
    STEP 0, $044
    STEP 0, $043
    STEP -4, $045, $FF
    STEP 0, $043
    STEP 0, $044
    STEP 0, $039
    STEP 0, $03A
    STEP 0, $03B
    STEP 0, $03C
    STEP 2, $043
    STEP -2, $045, $FF
    STEP 2, $043
    STEP 2, $044
    STEP 2, $043
    STEP -2, $045, $FF
    STEP 2, $043
    STEP 2, $044
    STEP 2, $043
    STEP -2, $045, $FF
    STEP 2, $043
    STEP 2, $044
    STEP 2, $043
    STEP -2, $045, $FF
    STEP 2, $043
    STEP 2, $044
    STEP -12, $046, $FF
    STEP -12, $046, $FF
    STEP 0, $046
    STEP 0, $046
    STEP -12, $046, $FF
    STEP -12, $046, $FF
    STEP 0, $046
    STEP 0, $046
    STEP 2, $046
    STEP 2, $046
    STEP 2, $046
    STEP 2, $046
    STEP 2, $046
    STEP 2, $046
    STEP 2, $046
    STEP 2, $046
    STEP 0, $043
    STEP -4, $045, $FF
    STEP 0, $043
    STEP 0, $044
    STEP 0, $043
    STEP -4, $045, $FF
    STEP 0, $043
    STEP 0, $04D

Song03_Ch3:
    STEP -12, $032, $FF
    STEP -16, $032, $FF
    STEP -12, $032, $FF
    STEP -12, $033, $FF
    STEP -12, $032, $FF
    STEP -16, $032, $FF
    STEP -12, $032, $FF
    STEP -12, $033, $FF
    STEP -12, $032, $FF
    STEP -16, $032, $FF
    STEP -12, $032, $FF
    STEP -12, $033, $FF
    STEP -12, $032, $FF
    STEP -16, $032, $FF
    STEP -12, $032, $FF
    STEP -12, $034, $FF
    STEP -12, $032, $FF
    STEP -16, $032, $FF
    STEP -12, $032, $FF
    STEP -12, $034, $FF
    STEP -12, $032, $FF
    STEP -16, $032, $FF
    STEP -12, $032, $FF
    STEP -12, $033, $FF
    STEP -12, $032, $FF
    STEP -16, $032, $FF
    STEP -12, $032, $FF
    STEP -12, $033, $FF
    STEP -12, $032, $FF
    STEP -16, $032, $FF
    STEP -12, $032, $FF
    STEP -12, $034, $FF
    STEP -12, $032, $FF
    STEP -16, $032, $FF
    STEP -12, $032, $FF
    STEP -12, $034, $FF
    STEP -10, $032, $FF
    STEP -14, $032, $FF
    STEP -10, $032, $FF
    STEP -10, $033, $FF
    STEP -10, $032, $FF
    STEP -14, $032, $FF
    STEP -10, $032, $FF
    STEP -10, $033, $FF
    STEP -10, $032, $FF
    STEP -10, $032, $FF
    STEP -10, $032, $FF
    STEP -10, $033, $FF
    STEP -10, $032, $FF
    STEP -14, $032, $FF
    STEP -10, $032, $FF
    STEP -12, $035, $FF
    STEP -12, $036, $FF
    STEP -12, $036, $FF
    STEP -12, $036, $FF
    STEP -12, $037, $FF
    STEP -12, $036, $FF
    STEP -12, $036, $FF
    STEP -12, $036, $FF
    STEP -12, $037, $FF
    STEP -10, $036, $FF
    STEP -10, $036, $FF
    STEP -10, $036, $FF
    STEP -10, $037, $FF
    STEP -10, $036, $FF
    STEP -10, $036, $FF
    STEP -10, $036, $FF
    STEP -12, $038, $FF
    STEP -12, $032, $FF
    STEP -16, $032, $FF
    STEP -12, $032, $FF
    STEP -12, $033, $FF
    STEP -12, $032, $FF
    STEP -16, $032, $FF
    STEP -12, $032, $FF
    STEP -12, $04C, $FF

Song03_Ch4:
    STEP 0, $04A

Pat000:
    HOLD 64
    PATEND

Pat001:
    HOLD 4
    NOTE 8, G3, $02
    NOTE 8, Cs4, $02
    NOTE 8, G4, $02
    NOTE 32, Cs5, $02
    HOLD 4
    PATEND

Pat002:
    HOLD 8
    NOTE 8, As3, $02
    NOTE 8, E4, $02
    NOTE 8, As4, $02
    NOTE 30, E5, $03
    KEYOFF 2
    PATEND

Pat003:
    NOTE 6, C2, $01
    NOTE 2, G2, $01
    NOTE 6, C2, $01
    NOTE 2, G2, $01
    NOTE 6, C2, $01
    NOTE 2, G2, $01
    NOTE 6, Cs2, $01
    NOTE 2, Gs2, $01
    NOTE 6, C2, $01
    NOTE 2, G2, $01
    NOTE 6, C2, $01
    NOTE 2, G2, $01
    NOTE 6, C2, $01
    NOTE 2, G2, $01
    NOTE 4, Cs2, $01
    NOTE 4, Gs2, $01
    PATEND

Pat004:
    NOTE 6, C2, $01
    NOTE 2, G2, $01
    NOTE 2, C2, $01
    NOTE 2, Fs4, $09
    NOTE 2, G4, $09
    NOTE 2, G2, $01
    NOTE 6, C2, $01
    NOTE 2, G2, $01
    NOTE 2, Cs2, $01
    NOTE 4, Gs4, $09
    NOTE 2, Gs2, $01
    NOTE 6, C2, $01
    NOTE 2, G2, $01
    NOTE 4, C2, $01
    NOTE 2, C4, $09
    NOTE 2, G2, $01
    NOTE 6, C2, $01
    NOTE 2, G2, $01
    NOTE 4, Cs2, $01
    NOTE 4, Gs2, $01
    PATEND

Pat005:
    NOTE 32, G5, $04
    NOTE 4, G6, $04
    NOTE 4, E6, $04
    NOTE 4, Cs6, $04
    NOTE 4, As5, $04
    NOTE 4, G5, $04
    NOTE 4, E5, $04
    NOTE 4, Cs5, $04
    NOTE 4, As4, $04
    PATEND

Pat006:
    HOLD 4
    NOTE 16, G4, $02
    KEYON 8
    NOTE 8, C5, $02
    NOTE 16, G4, $02
    KEYON 8
    NOTE 4, Gs4, $02
    PATEND

Pat007:
    HOLD 2
    NOTE 1, G4, $05
    KEYON 1
    KEYON 2
    NOTE 2, Fs4, $07
    NOTE 1, G4, $07
    KEYOFF 1
    NOTE 8, G4, $05
    KEYON 1
    KEYON 1
    KEYON 2
    NOTE 2, G4, $07
    NOTE 1, Gs4, $07
    KEYOFF 1
    NOTE 4, C5, $05
    NOTE 4, C5, $06
    NOTE 1, G4, $05
    KEYON 1
    KEYON 2
    NOTE 2, Gs4, $07
    NOTE 1, G4, $07
    KEYOFF 1
    NOTE 4, G4, $05
    KEYON 4
    KEYON 1
    KEYON 1
    KEYON 2
    NOTE 2, Ds4, $07
    NOTE 1, Fs4, $07
    KEYOFF 1
    NOTE 4, Fs4, $05
    NOTE 2, Fs4, $05
    PATEND

Pat008:
    NOTE 4, C5, $04
    NOTE 2, G5, $04
    NOTE 2, Gs5, $04
    NOTE 2, G5, $04
    NOTE 2, Ds5, $04
    NOTE 2, F5, $04
    NOTE 2, G5, $04
    NOTE 4, Gs5, $04
    NOTE 4, Ds5, $04
    NOTE 4, D5, $04
    NOTE 4, G5, $04
    NOTE 4, C5, $04
    NOTE 2, C5, $04
    NOTE 2, D5, $04
    NOTE 2, Ds5, $04
    NOTE 2, C5, $04
    NOTE 2, Ds5, $04
    NOTE 2, G5, $04
    NOTE 8, Fs5, $04
    NOTE 8, Gs5, $04
    PATEND

Pat009:
    NOTE 4, G5, $04
    NOTE 2, G5, $04
    NOTE 2, Gs5, $04
    NOTE 2, G5, $04
    NOTE 2, C6, $04
    NOTE 2, G5, $04
    NOTE 2, Ds5, $04
    NOTE 4, Fs5, $04
    NOTE 4, C6, $04
    NOTE 4, Fs5, $04
    NOTE 4, G5, $04
    NOTE 4, C5, $04
    NOTE 2, Ds5, $04
    NOTE 2, G5, $04
    NOTE 2, C6, $04
    NOTE 2, D6, $04
    NOTE 2, Ds6, $04
    NOTE 2, G5, $04
    NOTE 8, Gs5, $04
    NOTE 8, Fs5, $04
    PATEND

Pat010:
    NOTE 8, G5, $15
    NOTE 4, C6, $08
    NOTE 4, G5, $08
    NOTE 8, Gs5, $17
    NOTE 8, Fs5, $08
    NOTE 8, G5, $17
    NOTE 4, Ds5, $08
    NOTE 4, C5, $08
    NOTE 16, Fs5, $16
    PATEND

Pat011:
    NOTE 8, G5, $15
    NOTE 4, C6, $08
    NOTE 4, Ds6, $08
    NOTE 8, Fs6, $08
    NOTE 8, G6, $16
    NOTE 8, G5, $17
    NOTE 4, Ds5, $08
    NOTE 4, G4, $08
    NOTE 16, Gs4, $16
    PATEND

Pat012:
    NOTE 32, C5, $00
    NOTE 32, C5, $00
    PATEND

Pat013:
    NOTE 8, C5, $0A
    NOTE 8, As3, $02
    NOTE 8, E4, $02
    NOTE 8, As4, $02
    NOTE 30, E5, $03
    KEYOFF 2
    PATEND

Pat014:
    NOTE 4, C5, $0A
    NOTE 8, G3, $02
    NOTE 8, Cs4, $02
    NOTE 8, G4, $02
    NOTE 32, Cs5, $02
    HOLD 4
    PATEND

Pat015:
    NOTE 4, $24, $00
    NOTE 4, $24, $01
    NOTE 4, $24, $02
    NOTE 2, $24, $02
    NOTE 2, $24, $02
    NOTE 4, $24, $00
    NOTE 4, $24, $01
    NOTE 4, $24, $02
    NOTE 2, $24, $02
    NOTE 2, $24, $02
    NOTE 4, $24, $00
    NOTE 4, $24, $01
    NOTE 4, $24, $02
    NOTE 2, $24, $02
    NOTE 2, $24, $02
    NOTE 4, $24, $00
    NOTE 4, $24, $01
    NOTE 4, $24, $02
    NOTE 2, $24, $02
    NOTE 1, $24, $02
    NOTE 1, $24, $02
    PATEND

Pat016:
    NOTE 4, Cs2, $01
    NOTE 2, Gs3, $09
    NOTE 2, Gs2, $01
    NOTE 4, Cs2, $01
    NOTE 2, Gs3, $09
    NOTE 2, Gs2, $01
    NOTE 4, D2, $01
    NOTE 2, A3, $09
    NOTE 2, A2, $01
    NOTE 4, D2, $01
    NOTE 2, A3, $09
    NOTE 2, A2, $01
    NOTE 4, Cs2, $01
    NOTE 2, Gs4, $09
    NOTE 2, Gs2, $01
    NOTE 4, Cs2, $01
    NOTE 2, Gs4, $09
    NOTE 2, Gs2, $01
    NOTE 4, D2, $01
    NOTE 2, A4, $09
    NOTE 2, A2, $01
    NOTE 2, D2, $01
    NOTE 2, D2, $01
    NOTE 2, Gs2, $01
    NOTE 2, A2, $01
    PATEND

Pat017:
    NOTE 4, Cs2, $01
    NOTE 1, Gs4, $09
    NOTE 1, G4, $09
    NOTE 2, Gs2, $01
    NOTE 4, Cs2, $01
    NOTE 2, Gs4, $09
    NOTE 2, Gs2, $01
    NOTE 4, D2, $01
    NOTE 1, A4, $09
    NOTE 1, Gs4, $09
    NOTE 2, A2, $01
    NOTE 4, D2, $01
    NOTE 2, D5, $09
    NOTE 2, A2, $01
    NOTE 4, Cs2, $01
    NOTE 1, Gs4, $09
    NOTE 1, G4, $09
    NOTE 2, Gs2, $01
    NOTE 4, Cs2, $01
    NOTE 2, Gs4, $09
    NOTE 2, Gs2, $01
    NOTE 4, D2, $01
    NOTE 2, D5, $09
    NOTE 2, A2, $01
    NOTE 2, D2, $01
    NOTE 2, D2, $01
    NOTE 2, Gs2, $01
    NOTE 2, A2, $01
    PATEND

Pat018:
    HOLD 2
    NOTE 1, Gs4, $05
    NOTE 1, Gs4, $05
    NOTE 2, Gs4, $05
    NOTE 4, Gs4, $05
    NOTE 4, Gs4, $05
    NOTE 4, Gs4, $05
    NOTE 1, A4, $05
    NOTE 1, A4, $05
    NOTE 2, A4, $05
    NOTE 4, A4, $05
    NOTE 4, A4, $05
    NOTE 4, A4, $06
    NOTE 1, Gs4, $05
    NOTE 1, Gs4, $05
    NOTE 2, Gs4, $05
    NOTE 4, Gs4, $05
    NOTE 4, Gs4, $05
    NOTE 4, Gs4, $05
    NOTE 1, A4, $05
    NOTE 1, A4, $05
    NOTE 2, A4, $05
    NOTE 2, As4, $05
    NOTE 8, A4, $06
    PATEND

Pat019:
    NOTE 2, Cs3, $07
    NOTE 1, Gs4, $05
    NOTE 1, Gs4, $05
    NOTE 2, Gs4, $05
    NOTE 4, Gs4, $05
    NOTE 4, Gs4, $05
    NOTE 2, Gs4, $05
    NOTE 2, D3, $07
    NOTE 1, A4, $05
    NOTE 1, A4, $05
    NOTE 2, A4, $05
    NOTE 4, A4, $05
    NOTE 4, A4, $05
    NOTE 2, A4, $06
    NOTE 2, Cs3, $07
    NOTE 1, Gs4, $05
    NOTE 1, Gs4, $05
    NOTE 2, Gs4, $05
    NOTE 4, Gs4, $05
    NOTE 4, Gs4, $05
    NOTE 2, Gs4, $05
    NOTE 2, D3, $07
    NOTE 1, A4, $05
    NOTE 1, A4, $05
    NOTE 2, A4, $05
    NOTE 2, As4, $05
    NOTE 8, A4, $06
    PATEND

Pat020:
    NOTE 8, Gs4, $08
    NOTE 8, F5, $16
    NOTE 16, D5, $08
    NOTE 8, Gs4, $08
    NOTE 8, Gs5, $08
    NOTE 16, A5, $16
    PATEND

Pat021:
    NOTE 8, Gs4, $08
    NOTE 6, E5, $08
    NOTE 1, Ds5, $08
    NOTE 1, E5, $08
    NOTE 6, D5, $08
    NOTE 1, Cs5, $08
    NOTE 1, D5, $08
    NOTE 5, A4, $08
    KEYOFF 1
    NOTE 1, A4, $08
    NOTE 1, B4, $08
    NOTE 8, Gs4, $08
    NOTE 6, Gs5, $08
    NOTE 1, G5, $08
    NOTE 1, Gs5, $08
    NOTE 4, A5, $08
    NOTE 4, F5, $08
    NOTE 8, D5, $08
    PATEND

Pat022:
    NOTE 4, Cs2, $01
    NOTE 1, Gs4, $09
    NOTE 1, G4, $09
    NOTE 2, Gs2, $01
    NOTE 4, Cs2, $01
    NOTE 2, Gs4, $09
    NOTE 2, Gs2, $01
    NOTE 4, D2, $01
    NOTE 1, A4, $09
    NOTE 1, Gs4, $09
    NOTE 2, A2, $01
    NOTE 4, D2, $01
    NOTE 2, D5, $09
    NOTE 2, A2, $01
    NOTE 4, Cs2, $01
    NOTE 1, Gs4, $09
    NOTE 1, G4, $09
    NOTE 2, Gs2, $01
    NOTE 4, Cs2, $01
    NOTE 2, Gs4, $09
    NOTE 2, Gs2, $01
    NOTE 4, D2, $01
    NOTE 2, D5, $09
    NOTE 2, A2, $01
    NOTE 2, D2, $01
    NOTE 2, D2, $01
    NOTE 2, Gs2, $01
    NOTE 2, A2, $01
    SONGJUMP Song01_Ch1

    ; $555D-$555D: 1 unreferenced byte
    db $00

Pat023:
    NOTE 2, Cs3, $07
    NOTE 1, Gs4, $05
    NOTE 1, Gs4, $05
    NOTE 2, Gs4, $05
    NOTE 4, Gs4, $05
    NOTE 4, Gs4, $05
    NOTE 2, Gs4, $05
    NOTE 2, D3, $07
    NOTE 1, A4, $05
    NOTE 1, A4, $05
    NOTE 2, A4, $05
    NOTE 4, A4, $05
    NOTE 4, A4, $05
    NOTE 2, A4, $06
    NOTE 2, Cs3, $07
    NOTE 1, Gs4, $05
    NOTE 1, Gs4, $05
    NOTE 2, Gs4, $05
    NOTE 4, Gs4, $05
    NOTE 4, Gs4, $05
    NOTE 2, Gs4, $05
    NOTE 2, D3, $07
    NOTE 1, A4, $05
    NOTE 1, A4, $05
    NOTE 2, A4, $05
    NOTE 2, As4, $05
    NOTE 8, A4, $06
    SONGJUMP Song01_Ch2

    ; $55B2-$55B2: 1 unreferenced byte
    db $00

Pat024:
    NOTE 8, Gs4, $08
    NOTE 6, E5, $08
    NOTE 1, Ds5, $08
    NOTE 1, E5, $08
    NOTE 6, D5, $08
    NOTE 1, Cs5, $08
    NOTE 1, D5, $08
    NOTE 5, A4, $08
    KEYOFF 1
    NOTE 1, A4, $08
    NOTE 1, B4, $08
    NOTE 8, Gs4, $08
    NOTE 6, Gs5, $08
    NOTE 1, G5, $08
    NOTE 1, Gs5, $08
    NOTE 4, A5, $08
    NOTE 4, F5, $08
    NOTE 4, D5, $08
    NOTE 4, A4, $08
    SONGJUMP Song01_Ch3

    ; $55EE-$55EE: 1 unreferenced byte
    db $00

Pat025:
    NOTE 4, $24, $00
    NOTE 4, $24, $01
    NOTE 4, $24, $02
    NOTE 2, $24, $02
    NOTE 2, $24, $02
    NOTE 4, $24, $00
    NOTE 4, $24, $01
    NOTE 4, $24, $02
    NOTE 2, $24, $02
    NOTE 2, $24, $02
    NOTE 4, $24, $00
    NOTE 4, $24, $01
    NOTE 4, $24, $02
    NOTE 2, $24, $02
    NOTE 2, $24, $02
    NOTE 4, $24, $00
    NOTE 4, $24, $01
    NOTE 4, $24, $02
    NOTE 2, $24, $02
    NOTE 1, $24, $02
    NOTE 1, $24, $02
    SONGJUMP Song01_Ch4_Loop

Pat026:
    NOTE 32, C5, $04
    KEYOFF 32
    PATEND

Pat027:
    NOTE 2, Ds2, $01
    NOTE 1, As4, $0C
    KEYON 2
    KEYON 1
    NOTE 2, F2, $01
    NOTE 1, As4, $0E
    KEYON 2
    KEYON 1
    NOTE 2, Fs2, $01
    NOTE 1, B4, $0D
    KEYON 2
    KEYON 1
    NOTE 2, Gs2, $01
    NOTE 1, Gs4, $0D
    NOTE 2, As2, $01
    NOTE 1, Gs4, $0D
    NOTE 2, Ds2, $01
    NOTE 1, As4, $0C
    KEYON 2
    KEYON 1
    NOTE 2, F2, $01
    NOTE 1, As4, $0E
    KEYON 2
    KEYON 1
    NOTE 2, Gs2, $01
    NOTE 1, B4, $0D
    NOTE 2, As2, $01
    NOTE 1, B4, $0D
    NOTE 3, Ds2, $01
    NOTE 1, Fs2, $01
    NOTE 1, F2, $01
    NOTE 1, E2, $01
    PATEND

Pat028:
    NOTE 2, B2, $01
    NOTE 1, D4, $12
    KEYON 2
    KEYON 1
    NOTE 2, A2, $01
    NOTE 1, D4, $12
    KEYON 2
    KEYON 1
    NOTE 2, As2, $01
    NOTE 1, Cs4, $12
    KEYON 2
    KEYON 1
    NOTE 2, Fs2, $01
    NOTE 1, Cs4, $12
    KEYON 2
    KEYON 1
    NOTE 2, G2, $01
    NOTE 1, F4, $0D
    KEYON 2
    KEYON 1
    NOTE 2, G3, $01
    NOTE 1, F4, $0D
    KEYON 2
    KEYON 1
    NOTE 2, Fs2, $01
    NOTE 1, Fs4, $0E
    KEYON 2
    KEYON 1
    NOTE 2, Fs2, $01
    NOTE 1, Fs4, $13
    KEYON 2
    KEYON 1
    PATEND

Pat029:
    NOTE 2, B2, $01
    NOTE 1, F4, $0D
    KEYON 2
    KEYON 1
    NOTE 2, A2, $01
    NOTE 1, F4, $0D
    KEYON 2
    KEYON 1
    NOTE 2, As2, $01
    NOTE 1, Cs4, $12
    KEYON 2
    KEYON 1
    NOTE 2, Fs2, $01
    NOTE 1, Cs4, $12
    KEYON 2
    KEYON 1
    NOTE 2, G2, $01
    NOTE 1, F4, $0D
    KEYON 2
    KEYON 1
    NOTE 2, G3, $01
    NOTE 1, F4, $0D
    KEYON 2
    KEYON 1
    NOTE 3, Fs2, $01
    NOTE 3, E2, $01
    NOTE 3, D2, $01
    NOTE 3, Cs2, $01
    PATEND

Pat030:
    NOTE 6, As4, $0B
    NOTE 6, A4, $0B
    NOTE 6, As4, $0B
    NOTE 6, B4, $0B
    NOTE 6, As4, $0B
    NOTE 6, A4, $0B
    NOTE 2, As4, $0B
    NOTE 1, B4, $0B
    NOTE 2, A4, $0B
    NOTE 1, As4, $0B
    KEYOFF 6
    PATEND

Pat031:
    KEYOFF 3
    NOTE 3, Gs5, $0B
    NOTE 2, Fs5, $0B
    NOTE 1, Gs5, $0B
    NOTE 1, Fs5, $0B
    KEYOFF 1
    NOTE 3, Gs5, $0B
    NOTE 1, Fs5, $0B
    NOTE 3, Gs5, $0B
    NOTE 3, A5, $0B
    NOTE 1, As5, $0B
    KEYOFF 5
    NOTE 2, A5, $0B
    NOTE 1, As5, $0B
    NOTE 2, A5, $0B
    NOTE 1, As5, $0B
    KEYOFF 2
    NOTE 1, A5, $0B
    NOTE 2, As5, $0B
    NOTE 1, Fs5, $0B
    NOTE 2, B5, $0B
    NOTE 1, As5, $0B
    KEYOFF 6
    PATEND

Pat032:
    NOTE 6, B5, $08
    NOTE 6, B6, $08
    NOTE 12, As6, $08
    NOTE 6, B5, $08
    NOTE 6, B6, $08
    NOTE 12, As6, $08
    PATEND

Pat033:
    NOTE 4, B5, $0B
    NOTE 1, G5, $0B
    NOTE 1, D5, $0B
    NOTE 4, B6, $0B
    NOTE 1, G5, $0B
    NOTE 1, D5, $0B
    NOTE 12, As6, $0B
    NOTE 4, B5, $0B
    NOTE 1, G5, $0B
    NOTE 1, D5, $0B
    NOTE 4, B6, $0B
    NOTE 1, G5, $0B
    NOTE 1, D5, $0B
    NOTE 1, As5, $0B
    NOTE 1, A5, $0B
    NOTE 1, As5, $0B
    NOTE 1, B5, $0B
    NOTE 1, As5, $0B
    NOTE 1, B5, $0B
    NOTE 1, C6, $0B
    NOTE 1, B5, $0B
    NOTE 1, C6, $0B
    NOTE 1, Cs6, $0B
    NOTE 1, C6, $0B
    NOTE 1, Cs6, $0B
    PATEND

Pat034:
    NOTE 48, C5, $0A
    PATEND

Pat035:
    HOLD 2
    NOTE 1, As3, $0F
    NOTE 2, Ds4, $0F
    NOTE 1, As4, $0F
    NOTE 2, A4, $10
    NOTE 1, F4, $0F
    KEYOFF 2
    NOTE 1, F4, $0F
    NOTE 2, Gs4, $10
    NOTE 1, F4, $0F
    KEYOFF 2
    NOTE 1, Gs4, $0F
    NOTE 2, Fs4, $10
    NOTE 1, Ds4, $0F
    NOTE 2, D4, $0F
    NOTE 1, As3, $0F
    KEYOFF 2
    NOTE 1, Ds4, $0F
    NOTE 2, Fs4, $0F
    NOTE 1, As4, $0F
    NOTE 2, A4, $10
    NOTE 1, F4, $0F
    KEYOFF 2
    NOTE 1, F4, $0F
    NOTE 2, Fs4, $10
    NOTE 1, Ds4, $0F
    NOTE 2, D4, $0F
    NOTE 1, Ds4, $0F
    NOTE 6, As4, $0C
    PATEND

Pat036:
    HOLD 2
    NOTE 1, As3, $0F
    NOTE 2, Ds4, $0F
    NOTE 1, As4, $0F
    NOTE 2, A4, $10
    NOTE 1, F4, $0F
    KEYOFF 2
    NOTE 1, F4, $0F
    NOTE 2, Gs4, $10
    NOTE 1, F4, $0F
    KEYOFF 2
    NOTE 1, Gs4, $0F
    NOTE 2, Fs4, $10
    NOTE 1, Ds4, $0F
    NOTE 2, D4, $0F
    NOTE 1, As3, $0F
    KEYOFF 2
    NOTE 1, Ds4, $0F
    NOTE 2, Fs4, $0F
    NOTE 1, As4, $0F
    NOTE 2, A4, $10
    NOTE 1, F4, $0F
    KEYOFF 2
    NOTE 1, F4, $0F
    NOTE 2, Fs4, $10
    NOTE 1, Ds4, $0F
    NOTE 2, D4, $0F
    NOTE 1, Ds4, $0F
    NOTE 3, As4, $0C
    NOTE 3, As4, $10
    PATEND

Pat037:
    NOTE 6, B4, $0F
    NOTE 6, B4, $11
    NOTE 2, As5, $0F
    KEYOFF 6
    NOTE 1, G4, $0F
    NOTE 1, Gs4, $0F
    NOTE 1, A4, $0F
    NOTE 1, As4, $0F
    NOTE 6, B4, $10
    NOTE 6, B4, $11
    NOTE 1, As5, $0F
    KEYOFF 1
    NOTE 1, A5, $0F
    NOTE 2, As5, $0F
    NOTE 2, B5, $0F
    KEYOFF 1
    NOTE 3, As5, $10
    KEYOFF 1
    PATEND

Pat038:
    NOTE 6, B4, $0F
    NOTE 6, B4, $11
    NOTE 2, As5, $0F
    KEYOFF 6
    NOTE 1, G4, $0F
    NOTE 1, Gs4, $0F
    NOTE 1, A4, $0F
    NOTE 1, As4, $0F
    NOTE 6, B4, $10
    NOTE 6, B4, $11
    NOTE 1, Fs4, $0F
    NOTE 1, F4, $0F
    NOTE 1, Fs4, $0F
    NOTE 1, Gs4, $0F
    NOTE 1, Fs4, $0F
    NOTE 1, Gs4, $0F
    NOTE 1, A4, $0F
    NOTE 1, Gs4, $0F
    NOTE 1, A4, $0F
    NOTE 1, As4, $0F
    NOTE 1, A4, $0F
    NOTE 1, As4, $0F
    PATEND

Pat039:
    NOTE 2, $18, $02
    NOTE 1, $18, $02
    NOTE 2, $18, $04
    NOTE 1, $18, $02
    NOTE 2, $18, $02
    NOTE 1, $18, $02
    NOTE 2, $18, $04
    NOTE 1, $18, $02
    NOTE 2, $18, $02
    NOTE 1, $18, $02
    NOTE 2, $18, $04
    NOTE 1, $18, $02
    NOTE 2, $18, $02
    NOTE 1, $18, $02
    NOTE 2, $18, $04
    NOTE 1, $18, $02
    NOTE 2, $18, $02
    NOTE 1, $18, $02
    NOTE 2, $18, $04
    NOTE 1, $18, $02
    NOTE 2, $18, $02
    NOTE 1, $18, $02
    NOTE 2, $18, $04
    NOTE 1, $18, $02
    NOTE 2, $18, $02
    NOTE 1, $18, $02
    NOTE 2, $18, $04
    NOTE 1, $18, $02
    NOTE 2, $18, $02
    NOTE 1, $18, $02
    NOTE 2, $18, $04
    NOTE 1, $18, $02
    PATEND

Pat040:
    NOTE 2, $18, $00
    NOTE 1, $18, $02
    NOTE 2, $18, $01
    NOTE 1, $18, $04
    NOTE 2, $18, $02
    NOTE 1, $18, $02
    NOTE 2, $18, $01
    NOTE 1, $18, $04
    NOTE 1, $18, $00
    NOTE 1, $18, $02
    NOTE 1, $18, $02
    NOTE 2, $18, $01
    NOTE 1, $18, $04
    NOTE 2, $18, $02
    NOTE 1, $18, $02
    NOTE 2, $18, $01
    NOTE 1, $18, $01
    NOTE 2, $18, $02
    NOTE 1, $18, $02
    NOTE 2, $18, $01
    NOTE 1, $18, $04
    NOTE 2, $18, $02
    NOTE 1, $18, $02
    NOTE 2, $18, $01
    NOTE 1, $18, $04
    NOTE 2, $18, $00
    NOTE 1, $18, $02
    NOTE 2, $18, $01
    NOTE 1, $18, $04
    NOTE 2, $18, $02
    NOTE 1, $18, $02
    NOTE 1, $18, $01
    NOTE 1, $18, $01
    NOTE 1, $18, $01
    PATEND

Pat041:
    NOTE 2, B2, $01
    NOTE 1, Fs4, $0C
    KEYON 2
    KEYON 1
    NOTE 2, Fs2, $01
    NOTE 1, Fs4, $0E
    KEYON 2
    KEYON 1
    NOTE 2, B2, $01
    NOTE 1, Fs4, $0C
    KEYON 2
    KEYON 1
    NOTE 2, Fs2, $01
    NOTE 1, E4, $0D
    KEYON 2
    NOTE 1, Fs4, $13
    NOTE 2, B2, $01
    NOTE 1, Fs4, $0C
    KEYON 2
    KEYON 1
    NOTE 2, Fs2, $01
    NOTE 1, Fs4, $0E
    KEYON 2
    KEYON 1
    NOTE 2, B2, $01
    NOTE 1, Fs4, $0C
    KEYON 2
    KEYON 1
    NOTE 2, Fs2, $01
    NOTE 1, E4, $0D
    KEYON 3
    PATEND

Pat042:
    NOTE 6, Fs4, $14
    NOTE 6, G4, $14
    NOTE 6, Fs4, $14
    NOTE 6, B4, $14
    NOTE 12, Fs4, $14
    KEYOFF 12
    PATEND

Pat043:
    NOTE 6, Fs4, $14
    NOTE 6, G4, $14
    NOTE 6, Fs4, $14
    NOTE 6, Cs5, $14
    NOTE 8, D5, $14
    KEYOFF 4
    NOTE 2, D5, $07
    NOTE 1, B4, $07
    NOTE 1, G4, $07
    KEYOFF 1
    NOTE 3, Fs4, $07
    NOTE 1, G4, $07
    NOTE 1, Fs4, $07
    KEYOFF 2
    PATEND

Pat044:
    NOTE 1, Fs4, $0B
    NOTE 1, B4, $0B
    NOTE 1, D5, $0B
    NOTE 1, Fs4, $0B
    NOTE 1, B4, $0B
    NOTE 1, D5, $0B
    NOTE 1, Fs4, $0B
    NOTE 1, B4, $0B
    NOTE 1, Cs5, $0B
    NOTE 1, Fs4, $0B
    NOTE 1, B4, $0B
    NOTE 1, Cs5, $0B
    NOTE 1, Fs4, $0B
    NOTE 1, B4, $0B
    NOTE 1, D5, $0B
    NOTE 1, Fs4, $0B
    NOTE 1, B4, $0B
    NOTE 1, D5, $0B
    NOTE 1, Fs4, $0B
    NOTE 1, B4, $0B
    NOTE 1, Cs5, $0B
    NOTE 1, Fs4, $0B
    NOTE 1, As4, $0B
    NOTE 1, Cs5, $0B
    PATEND

Pat045:
    NOTE 6, B4, $0F
    NOTE 6, B4, $11
    NOTE 2, As5, $0F
    KEYOFF 6
    NOTE 1, G4, $0F
    NOTE 1, Gs4, $0F
    NOTE 1, A4, $0F
    NOTE 1, As4, $0F
    NOTE 6, B4, $10
    NOTE 6, B4, $11
    NOTE 1, Fs4, $0F
    NOTE 1, F4, $0F
    NOTE 1, Fs4, $0F
    NOTE 1, Gs4, $0F
    NOTE 1, Fs4, $0F
    NOTE 1, Gs4, $0F
    NOTE 1, A4, $0F
    NOTE 1, Gs4, $0F
    NOTE 1, A4, $0F
    NOTE 1, As4, $0F
    NOTE 1, A4, $0F
    NOTE 1, As4, $0F
    SONGJUMP Song02_Ch1

    ; $5AEA-$5AEA: 1 unreferenced byte
    db $00

Pat046:
    NOTE 2, B2, $01
    NOTE 1, F4, $0D
    KEYON 2
    KEYON 1
    NOTE 2, A2, $01
    NOTE 1, F4, $0D
    KEYON 2
    KEYON 1
    NOTE 2, As2, $01
    NOTE 1, Cs4, $12
    KEYON 2
    KEYON 1
    NOTE 2, Fs2, $01
    NOTE 1, Cs4, $12
    KEYON 2
    KEYON 1
    NOTE 2, G2, $01
    NOTE 1, F4, $0D
    KEYON 2
    KEYON 1
    NOTE 2, G3, $01
    NOTE 1, F4, $0D
    KEYON 2
    KEYON 1
    NOTE 3, Fs2, $01
    NOTE 3, E2, $01
    NOTE 3, D2, $01
    NOTE 3, Cs2, $01
    SONGJUMP Song02_Ch2

    ; $5B36-$5B36: 1 unreferenced byte
    db $00

Pat047:
    NOTE 4, B5, $0B
    NOTE 1, G5, $0B
    NOTE 1, D5, $0B
    NOTE 4, B6, $0B
    NOTE 1, G5, $0B
    NOTE 1, D5, $0B
    NOTE 12, As6, $0B
    NOTE 4, B5, $0B
    NOTE 1, G5, $0B
    NOTE 1, D5, $0B
    NOTE 4, B6, $0B
    NOTE 1, G5, $0B
    NOTE 1, D5, $0B
    NOTE 1, As5, $0B
    NOTE 1, A5, $0B
    NOTE 1, As5, $0B
    NOTE 1, B5, $0B
    NOTE 1, As5, $0B
    NOTE 1, B5, $0B
    NOTE 1, C6, $0B
    NOTE 1, B5, $0B
    NOTE 1, C6, $0B
    NOTE 1, Cs6, $0B
    NOTE 1, C6, $0B
    NOTE 1, Cs6, $0B
    SONGJUMP Song02_Ch3

    ; $5B85-$5B85: 1 unreferenced byte
    db $00

Pat048:
    NOTE 2, $18, $00
    NOTE 1, $18, $02
    NOTE 2, $18, $01
    NOTE 1, $18, $04
    NOTE 2, $18, $02
    NOTE 1, $18, $02
    NOTE 2, $18, $01
    NOTE 1, $18, $04
    NOTE 1, $18, $00
    NOTE 1, $18, $02
    NOTE 1, $18, $02
    NOTE 2, $18, $01
    NOTE 1, $18, $04
    NOTE 2, $18, $02
    NOTE 1, $18, $02
    NOTE 2, $18, $01
    NOTE 1, $18, $01
    NOTE 2, $18, $02
    NOTE 1, $18, $02
    NOTE 2, $18, $01
    NOTE 1, $18, $04
    NOTE 2, $18, $02
    NOTE 1, $18, $02
    NOTE 2, $18, $01
    NOTE 1, $18, $04
    NOTE 2, $18, $00
    NOTE 1, $18, $02
    NOTE 2, $18, $01
    NOTE 1, $18, $04
    NOTE 2, $18, $02
    NOTE 1, $18, $02
    NOTE 1, $18, $01
    NOTE 1, $18, $01
    NOTE 1, $18, $01
    SONGJUMP Song02_Ch4

    ; $5BEF-$5BEF: 1 unreferenced byte
    db $00

Pat049:
    HOLD 4
    NOTE 4, G3, $02
    NOTE 4, As3, $02
    NOTE 4, Cs4, $02
    NOTE 4, E4, $02
    NOTE 4, G4, $02
    NOTE 4, As4, $02
    NOTE 32, Cs5, $02
    HOLD 4
    PATEND

Pat050:
    NOTE 2, As3, $18
    NOTE 2, As3, $18
    NOTE 2, C5, $19
    NOTE 2, F3, $18
    NOTE 2, As3, $18
    NOTE 2, As3, $18
    NOTE 2, C5, $19
    NOTE 2, F3, $18
    PATEND

Pat051:
    NOTE 2, Fs3, $18
    NOTE 2, Fs3, $18
    NOTE 2, C5, $19
    NOTE 2, Cs3, $18
    NOTE 2, F3, $18
    NOTE 2, A3, $18
    NOTE 2, C5, $19
    NOTE 2, F3, $18
    PATEND

Pat052:
    NOTE 2, Fs3, $18
    NOTE 2, Fs3, $18
    NOTE 2, C5, $19
    NOTE 2, Cs3, $18
    NOTE 2, F3, $18
    NOTE 2, A3, $18
    NOTE 2, C5, $19
    NOTE 1, C5, $19
    NOTE 1, C5, $19
    PATEND

Pat053:
    NOTE 2, Gs3, $18
    NOTE 2, Gs3, $18
    NOTE 2, C5, $19
    NOTE 2, Ds3, $18
    NOTE 2, G3, $18
    NOTE 2, Fs3, $18
    NOTE 2, F3, $18
    NOTE 2, E3, $18
    PATEND

Pat054:
    NOTE 2, E3, $18
    NOTE 1, E4, $18
    NOTE 1, E4, $18
    NOTE 2, C5, $19
    NOTE 2, B3, $18
    NOTE 2, E3, $18
    NOTE 2, E4, $18
    NOTE 2, C5, $19
    NOTE 2, B3, $18
    PATEND

Pat055:
    NOTE 2, E3, $18
    NOTE 1, E4, $18
    NOTE 1, E4, $18
    NOTE 2, C5, $19
    NOTE 2, B3, $18
    NOTE 2, E3, $18
    NOTE 2, E4, $18
    NOTE 2, C5, $19
    NOTE 1, C5, $19
    NOTE 1, C5, $19
    PATEND

Pat056:
    NOTE 2, Fs3, $18
    NOTE 2, Fs4, $18
    NOTE 2, Gs3, $18
    NOTE 2, Gs4, $18
    NOTE 2, A3, $18
    NOTE 2, A4, $18
    NOTE 2, As3, $18
    NOTE 2, As4, $18
    PATEND

Pat057:
    NOTE 1, F4, $1A
    NOTE 1, F4, $1B
    NOTE 1, F4, $1A
    NOTE 1, G4, $1A
    NOTE 1, F4, $1A
    NOTE 1, G4, $1B
    NOTE 1, Ds4, $1A
    NOTE 1, F4, $1B
    NOTE 1, D4, $1A
    NOTE 1, Ds4, $1B
    NOTE 1, C4, $1A
    NOTE 1, C4, $1B
    NOTE 1, D4, $1A
    NOTE 1, C4, $1B
    NOTE 1, Ds4, $1A
    NOTE 1, D4, $1B
    PATEND

Pat058:
    NOTE 1, Cs4, $1A
    NOTE 1, Cs4, $1B
    NOTE 1, Cs4, $1A
    NOTE 1, Ds4, $1A
    NOTE 1, Cs4, $1A
    NOTE 1, Cs4, $1B
    NOTE 1, C4, $1A
    NOTE 1, Cs4, $1B
    NOTE 1, As3, $1A
    NOTE 1, C4, $1B
    NOTE 1, C4, $1A
    NOTE 1, As3, $1B
    NOTE 1, Cs4, $1A
    NOTE 1, C4, $1B
    NOTE 1, Ds4, $1A
    NOTE 1, Cs4, $1B
    PATEND

Pat059:
    NOTE 1, F4, $1A
    NOTE 1, F4, $1B
    NOTE 1, F4, $1A
    NOTE 1, G4, $1A
    NOTE 1, F4, $1A
    NOTE 1, F4, $1B
    NOTE 1, Ds4, $1A
    NOTE 1, F4, $1B
    NOTE 1, D4, $1A
    NOTE 1, Ds4, $1B
    NOTE 1, Ds4, $1A
    NOTE 1, D4, $1B
    NOTE 1, F4, $1A
    NOTE 1, Ds4, $1B
    NOTE 1, D4, $1A
    NOTE 1, F4, $1B
    PATEND

Pat060:
    NOTE 1, Fs4, $1A
    NOTE 1, Fs4, $1B
    NOTE 1, Fs4, $1A
    NOTE 1, Gs4, $1A
    NOTE 1, Fs4, $1A
    NOTE 1, Fs4, $1B
    NOTE 1, Gs4, $1A
    NOTE 1, Fs4, $1B
    NOTE 1, As4, $1A
    NOTE 1, Gs4, $1B
    NOTE 1, Fs4, $1A
    NOTE 1, As4, $1B
    NOTE 1, F4, $1A
    NOTE 1, Fs4, $1B
    NOTE 1, A3, $1A
    NOTE 1, F4, $1B
    PATEND

Pat061:
    NOTE 4, As4, $1C
    NOTE 4, As4, $20
    NOTE 4, A5, $1C
    NOTE 4, A5, $21
    PATEND

Pat062:
    NOTE 4, As4, $1C
    NOTE 4, As4, $20
    NOTE 4, As5, $22
    NOTE 2, E5, $23
    KEYOFF 2
    PATEND

Pat063:
    NOTE 4, As4, $1C
    NOTE 4, F4, $1C
    NOTE 4, F4, $25
    NOTE 2, C5, $24
    KEYOFF 2
    PATEND

Pat064:
    NOTE 1, G4, $1A
    NOTE 1, G4, $1B
    NOTE 1, C4, $1A
    NOTE 1, G4, $1A
    NOTE 2, G4, $1B
    NOTE 1, F4, $1A
    NOTE 1, G4, $1B
    NOTE 1, E4, $1A
    NOTE 1, F4, $1B
    NOTE 1, D4, $1A
    NOTE 1, E4, $1B
    NOTE 1, E4, $1A
    NOTE 1, D4, $1B
    NOTE 1, F4, $1A
    NOTE 1, E4, $1B
    PATEND

Pat065:
    NOTE 1, Cs4, $1A
    NOTE 1, Cs4, $1B
    NOTE 1, Cs4, $1A
    NOTE 1, C4, $1A
    NOTE 1, Cs4, $1A
    NOTE 1, Cs4, $1B
    NOTE 1, C4, $1A
    NOTE 1, Cs4, $1B
    NOTE 1, As3, $1A
    NOTE 1, C4, $1B
    NOTE 1, C4, $1A
    NOTE 1, As3, $1B
    NOTE 1, Cs4, $1A
    NOTE 1, C4, $1B
    NOTE 1, Ds4, $1A
    NOTE 1, Cs4, $1B
    PATEND

Pat066:
    NOTE 1, Gs4, $1A
    NOTE 1, Gs4, $1B
    NOTE 1, Gs4, $1A
    NOTE 1, G4, $1A
    NOTE 1, Gs4, $1A
    NOTE 1, G4, $1B
    NOTE 1, Gs4, $1A
    NOTE 1, Gs4, $1B
    NOTE 1, F4, $1A
    NOTE 1, Gs4, $1B
    NOTE 1, Fs4, $1A
    NOTE 1, F4, $1B
    NOTE 1, G4, $1A
    NOTE 2, G4, $1B
    KEYOFF 1
    PATEND

Pat067:
    NOTE 2, G4, $1F
    NOTE 2, As4, $1D
    KEYOFF 2
    NOTE 2, As4, $1D
    NOTE 1, As4, $1E
    KEYOFF 1
    NOTE 2, G4, $1F
    NOTE 3, As4, $1D
    NOTE 1, G4, $1F
    PATEND

Pat068:
    NOTE 2, G4, $1F
    NOTE 2, Fs4, $1D
    KEYOFF 2
    NOTE 2, Fs4, $1D
    NOTE 1, F4, $1E
    KEYOFF 1
    NOTE 2, G4, $1F
    NOTE 2, F4, $1D
    NOTE 1, F4, $1E
    KEYOFF 1
    PATEND

Pat069:
    NOTE 2, G4, $1F
    NOTE 2, As4, $1D
    KEYOFF 2
    NOTE 2, As4, $1D
    NOTE 1, D5, $1E
    KEYOFF 1
    NOTE 2, G4, $1F
    NOTE 4, As4, $1D
    PATEND

Pat070:
    NOTE 2, E4, $1A
    NOTE 1, E5, $1A
    NOTE 1, E4, $1B
    NOTE 1, E4, $1B
    NOTE 1, E5, $1B
    NOTE 1, E4, $1A
    NOTE 1, E5, $1A
    NOTE 1, E4, $1B
    NOTE 1, E4, $1A
    NOTE 1, E5, $1A
    NOTE 1, E5, $1B
    NOTE 2, E4, $1A
    NOTE 1, E5, $1A
    NOTE 1, E4, $1B
    PATEND

Pat071:
    NOTE 2, B4, $1A
    NOTE 1, B4, $1B
    NOTE 1, Cs5, $1A
    NOTE 1, B4, $1A
    NOTE 1, B4, $1B
    NOTE 1, A4, $1A
    NOTE 1, Cs5, $1B
    NOTE 1, Gs4, $1A
    NOTE 1, A4, $1B
    NOTE 1, A4, $1A
    NOTE 1, Gs4, $1B
    NOTE 4, B4, $1A
    PATEND

Pat072:
    NOTE 1, E4, $1E
    KEYOFF 1
    NOTE 1, E5, $1E
    KEYOFF 1
    NOTE 1, B4, $1E
    KEYOFF 1
    NOTE 1, E5, $1E
    KEYOFF 1
    NOTE 1, E4, $1E
    KEYOFF 1
    NOTE 1, E5, $1E
    KEYOFF 1
    NOTE 1, B4, $1E
    KEYOFF 1
    NOTE 1, E5, $1E
    KEYOFF 1
    PATEND

Pat073:
    NOTE 1, Fs4, $1E
    KEYOFF 1
    NOTE 2, Fs4, $1D
    NOTE 1, E4, $1E
    KEYOFF 1
    NOTE 2, Fs4, $1D
    NOTE 1, D4, $1E
    KEYOFF 1
    NOTE 2, Fs4, $1D
    NOTE 1, Cs4, $1E
    KEYOFF 1
    NOTE 2, Fs4, $1D
    PATEND

Pat074:
    NOTE 2, $24, $06
    NOTE 2, $24, $02
    NOTE 2, $24, $05
    NOTE 2, $24, $04
    NOTE 2, $24, $06
    NOTE 2, $24, $02
    NOTE 2, $24, $05
    NOTE 1, $24, $02
    NOTE 1, $24, $06
    NOTE 2, $24, $06
    NOTE 2, $24, $02
    NOTE 2, $24, $05
    NOTE 2, $24, $04
    NOTE 2, $24, $06
    NOTE 2, $24, $02
    NOTE 2, $24, $05
    NOTE 1, $24, $02
    NOTE 1, $24, $06
    SONGJUMP Song03_Ch4

    ; $5F60-$5F60: 1 unreferenced byte
    db $00

Pat075:
    HOLD 16
    PATEND

Pat076:
    NOTE 2, Fs3, $18
    NOTE 2, Fs3, $18
    NOTE 2, C5, $19
    NOTE 2, Cs3, $18
    NOTE 2, F3, $18
    NOTE 2, A3, $18
    NOTE 2, C5, $19
    NOTE 2, F3, $18
    SONGJUMP Song03_Ch3

Pat077:
    NOTE 2, G4, $1F
    NOTE 2, Fs4, $1D
    KEYOFF 2
    NOTE 2, Fs4, $1D
    NOTE 1, F4, $1E
    KEYOFF 1
    NOTE 2, G4, $1F
    NOTE 2, F4, $1D
    NOTE 1, F4, $1E
    KEYOFF 1
    SONGJUMP Song03_Ch2

    ; $5F9D-$5F9D: 1 unreferenced byte
    db $00

Pat078:
    NOTE 1, Gs4, $1A
    NOTE 1, Gs4, $1B
    NOTE 1, Gs4, $1A
    NOTE 1, G4, $1A
    NOTE 1, Gs4, $1A
    NOTE 1, G4, $1B
    NOTE 1, Gs4, $1A
    NOTE 1, Gs4, $1B
    NOTE 1, F4, $1A
    NOTE 1, Gs4, $1B
    NOTE 1, Fs4, $1A
    NOTE 1, F4, $1B
    NOTE 1, G4, $1A
    NOTE 2, G4, $1B
    KEYOFF 1
    SONGJUMP Song03_Ch1

    ; $5FCD-$5FCD: 1 unreferenced byte
    db $00

Pat079:
    NOTE 4, As3, $26
    NOTE 4, As4, $26
    NOTE 4, A4, $26
    NOTE 4, B3, $26
    PATEND

Pat080:
    NOTE 4, As3, $26
    NOTE 4, As4, $26
    NOTE 4, E4, $26
    NOTE 2, F4, $26
    KEYOFF 2
    PATEND

Pat081:
    NOTE 4, As3, $26
    NOTE 4, F3, $26
    NOTE 4, C4, $26
    NOTE 4, F4, $26
    PATEND

Pat082:
    NOTE 4, As3, $26
    NOTE 4, F3, $26
    NOTE 4, C4, $26
    HOLD 4
    PATEND

Pat083:
    HOLD 64
    SONGJUMP Song00_Ch1

Sfx00:
    NOTE 2, E3, $27
    KEYOFF 2
    SFXEND

Sfx01:
    NOTE 1, G4, $28
    NOTE 1, B4, $2A
    NOTE 1, B4, $29
    SFXEND

Sfx02:
    NOTE 2, $18, $07
    KEYON 2
    SFXEND

Sfx03:
    NOTE 2, $18, $08
    KEYON 2
    SFXEND

Sfx04:
    NOTE 4, C5, $2B
    SFXEND

Sfx05:
    NOTE 3, $18, $09
    KEYOFF 3
    SFXEND

Sfx06:
    NOTE 4, F5, $2C
    KEYOFF 6
    SFXEND

Sfx07:
    NOTE 1, B3, $30
    NOTE 1, C4, $2D
    NOTE 1, C4, $2E
    NOTE 3, G4, $2F
    SFXEND

Sfx08:
    NOTE 20, $24, $0A

Sfx0A:
    NOTE 8, $24, $0B
    SFXEND

Sfx09:
    NOTE 4, $24, $0A

Sfx09_Loop:
    HOLD 4
    SFXLOOP Sfx09_Loop

Sfx0B:
    NOTE 2, $24, $0C
    KEYOFF 5
    NOTE 6, $24, $0B
    SFXEND

Sfx0C:
    NOTE 2, $24, $0D
    KEYOFF 9
    SFXEND

Sfx0D:
    NOTE 10, $24, $0E
    SFXEND

Sfx0E:
    NOTE 3, $24, $0F
    KEYON 2
    SFXEND

Sfx0F:
    NOTE 1, G2, $31
    KEYOFF 1
    NOTE 1, A2, $31
    KEYOFF 1
    NOTE 1, B2, $31
    KEYOFF 1
    NOTE 1, C3, $31
    KEYOFF 1
    NOTE 1, Cs3, $31
    KEYOFF 1
    SFXEND

Sfx10:
    NOTE 6, $18, $10
    SFXEND

Sfx11:
    NOTE 8, $18, $11
    KEYOFF 4
    SFXEND

Sfx12:
    NOTE 5, $18, $12
    KEYOFF 2
    SFXEND

Sfx13:
    NOTE 7, C4, $32
    SFXEND

Sfx14:
    NOTE 3, $18, $13
    SFXEND

Sfx15:
    NOTE 7, C4, $33
    KEYOFF 2
    SFXEND

Sfx16:
    NOTE 1, C7, $34
    SFXEND

Sfx17:
    NOTE 3, A5, $35
    SFXEND

Sfx18:
    NOTE 3, $24, $14
    SFXEND

Comb_60DB:
    TB 1, $00 ; freq table only
    TB 1, $01 ; note only
    TLOOP Comb_60DB

Comb_60E2:
    TB 255, $00 ; freq table only
    TLOOP Comb_60E2

OrphanTab_60E7:
    TB 255, $01
    TLOOP OrphanTab_60E7

Comb_60EC:
    TB 255, $02 ; note + freq table
    TLOOP Comb_60EC

Arp_60F1:
    TB 255, $00 ; +0
    TLOOP Arp_60F1

Freq_60F6:
    TW 255, 0
    TLOOP Freq_60F6

OrphanTab_60FC:
    TB 255, $00
    TLOOP OrphanTab_60FC

Ins00:
    INS_WAVE BlankVol, BlankVol, Arp_60F1, Freq_60F6, Comb_60EC ; $00

Ins11:
    INS_WAVE Vol_6115, BlankVol, Arp_60F1, Freq_611A, Comb_60EC ; $0B

Vol_6115:
    TB 255, $40 ; 50%
    TLOOP Vol_6115

Freq_611A:
    TW 20, 0

Freq_611A_L0:
    TW 2, 1
    TW 2, -1
    TW 2, -1
    TW 2, 1
    TLOOP Freq_611A_L0

Freq_612C:
    TW 3, 10
    TW 3, -10
    TW 3, -10
    TW 3, 10
    TLOOP Freq_612C

Freq_613B:
    TW 3, 5
    TW 3, -5
    TW 3, -5
    TW 3, 5
    TLOOP Freq_613B

Freq_614A:
    TW 3, 2
    TW 3, -2
    TW 3, -2
    TW 3, 2
    TLOOP Freq_614A

Freq_6159:
    TW 3, 1
    TW 3, -1
    TW 3, -1
    TW 3, 1
    TLOOP Freq_6159

Freq_6168:
    TW 1, -14
    TW 14, 1

Freq_616E:
    TW 3, 2
    TW 3, -2
    TW 3, -2
    TW 3, 2

Freq_617A:
    TW 3, 2
    TW 3, -2
    TW 3, -2
    TW 3, 2
    TW 3, 2
    TW 3, -2
    TW 3, -2
    TW 3, 2
    TW 3, 2
    TW 3, -2
    TW 3, -2
    TW 3, 2
    TW 3, 2
    TW 3, -2
    TW 3, -2
    TW 3, 2
    TW 3, 2
    TW 3, -2
    TW 3, -2

Freq_616E_L0:
    TW 4, -4
    TW 4, 2
    TLOOP Freq_616E_L0

Ins01:
    INS_TONE $80, $B7, $01, Arp_60F1, Freq_612C, Comb_60EC ; $01

Ins02:
    INS_TONE $D0, $A7, $01, Arp_61CE, Freq_614A, Comb_60EC ; $02

Arp_61CE:
    TB 2, $00 ; +0
    TB 1, $05 ; +5
    TB 1, $08 ; +8
    TB 1, $0C ; +12
    TLOOP Arp_61CE

Ins10:
    INS_TONE $80, $01, $00, Arp_60F1, Freq_60F6, Comb_60EC ; $0A

Ins03:
    INS_TONE $80, $58, $57, Arp_61CE, Freq_61EB, Comb_61F7 ; $03

Freq_61EB:
    TW 1, -50

Freq_61EB_L0:
    TW 3, -2
    TW 1, 1
    TLOOP Freq_61EB_L0

Comb_61F7:
    TB 60, $01 ; note only

Comb_61F7_L0:
    TB 1, $00 ; freq table only
    TB 1, $01 ; note only
    TB 1, $02 ; note + freq table
    TLOOP Comb_61F7_L0

OrphanTab_6202:
    TW 50, 0
    TW 255, -1
    TLOOP OrphanTab_6202

Ins05:
    INS_TONE $D0, $84, $01, Arp_61CE, Freq_6159, Comb_60EC ; $05

Ins06:
    INS_TONE $40, $A5, $01, Arp_61CE, Freq_621D, Comb_60DB ; $06

Freq_621D:
    TW 1, -200
    TW 255, -1
    TLOOP Freq_621D

Ins07:
    INS_TONE $D0, $78, $71, Arp_60F1, Freq_614A, Comb_60EC ; $07

Ins38:
    INS_TONE $80, $86, $46, Arp_60F1, Freq_613B, Comb_60EC ; $26

Ins09:
    INS_TONE $80, $83, $31, Arp_6241, Freq_614A, Comb_60EC ; $09

Arp_6241:
    TB 1, $00 ; +0
    TB 1, $0C ; +12
    TLOOP Arp_6241

Ins04:
    INS_WAVE Vol_62C7, BlankVol, Arp_6252, Freq_6159, Comb_60EC ; $04

Arp_6252:
    TB 1, $00 ; +0

Arp_6252_L0:
    TB 1, $0C ; +12
    TB 4, $00 ; +0
    TLOOP Arp_6252_L0

Ins08:
    INS_WAVE Vol_62BC, BlankVol, Arp_60F1, Freq_616E, Comb_60EC ; $08

Ins21:
    INS_WAVE Vol_62BC, BlankVol, Arp_60F1, Freq_6283, Comb_60EC ; $15

Ins22:
    INS_WAVE Vol_62BC, BlankVol, Arp_60F1, Freq_6168, Comb_60EC ; $16

Ins23:
    INS_WAVE Vol_62BC, BlankVol, Arp_60F1, Freq_617A, Comb_60EC ; $17

Freq_6283:
    TW 3, 2
    TW 3, -2
    TW 3, -2
    TW 3, 2
    TW 3, 2
    TW 3, -2
    TW 3, -2
    TW 3, 2
    TW 3, 2
    TW 3, -2
    TW 3, -2
    TW 3, 2
    TW 3, 2
    TW 3, -2
    TW 3, -2
    TW 3, 2
    TW 50, 2
    TW 1, 3
    TLOOP Freq_6283

Vol_62BC:
    TB 1, $60 ; 25%
    TB 1, $40 ; 50%
    TB 1, $20 ; 100%

Vol_62BC_L0:
    TB 255, $40 ; 50%
    TLOOP Vol_62BC_L0

Vol_62C7:
    TB 8, $20 ; 100%
    TB 8, $40 ; 50%
    TB 255, $60 ; 25%
    TB 255, $60 ; 25%
    TLOOP Vol_62C7

Ins12:
    INS_TONE $D0, $93, $01, Arp_62DB, Freq_60F6, Comb_60EC ; $0C

Arp_62DB:
    TB 2, $00 ; +0
    TB 2, $05 ; +5
    TB 2, $08 ; +8
    TLOOP Arp_62DB

Ins13:
    INS_TONE $D0, $93, $01, Arp_62ED, Freq_60F6, Comb_60EC ; $0D

Arp_62ED:
    TB 2, $00 ; +0
    TB 2, $03 ; +3
    TB 2, $06 ; +6
    TB 2, $09 ; +9
    TLOOP Arp_62ED

Ins14:
    INS_TONE $D0, $93, $01, Arp_6301, Freq_60F6, Comb_60EC ; $0E

Arp_6301:
    TB 2, $00 ; +0
    TB 2, $05 ; +5
    TB 2, $07 ; +7
    TLOOP Arp_6301

Ins18:
    INS_TONE $D0, $93, $01, Arp_6313, Freq_60F6, Comb_60EC ; $12

Arp_6313:
    TB 2, $00 ; +0
    TB 2, $05 ; +5
    TB 2, $09 ; +9
    TLOOP Arp_6313

Ins19:
    INS_TONE $D0, $93, $01, Arp_6325, Freq_60F6, Comb_60EC ; $13

Arp_6325:
    TB 2, $00 ; +0
    TB 2, $04 ; +4
    TB 2, $07 ; +7
    TLOOP Arp_6325

Freq_632E:
    TW 5, 0
    TW 1, -6

Freq_632E_L0:
    TW 4, 3
    TW 4, -3
    TLOOP Freq_632E_L0

Ins20:
    INS_TONE $80, $88, $87, Arp_6252, Freq_614A, Comb_60EC ; $14

Ins15:
    INS_TONE $40, $88, $71, Arp_60F1, Freq_632E, Comb_60EC ; $0F

Ins16:
    INS_TONE $40, $88, $71, Arp_60F1, Freq_6358, Comb_60EC ; $10

Freq_6358:
    TW 1, -10
    TW 5, 2
    TLOOP Freq_632E

Ins17:
    INS_TONE $40, $88, $71, Arp_60F1, Freq_636A, Comb_60EC ; $11

Freq_636A:
    TW 19, 7
    TW 2, 1
    TLOOP Freq_632E

Ins24:
    INS_WAVE Vol_637D, BlankVol, Arp_60F1, Freq_632E, Comb_60EC ; $18

Vol_637D:
    TB 2, $20 ; 100%
    TB 2, $40 ; 50%
    TB 6, $60 ; 25%
    TLOOP BlankVol

Ins25:
    INS_WAVE Vol_6390, BlankVol, Arp_60F1, Freq_6399, Comb_60E2 ; $19

Vol_6390:
    TB 1, $00 ; mute
    TB 3, $20 ; 100%
    TB 3, $40 ; 50%
    TLOOP BlankVol

Freq_6399:
    TW 1, 0
    TW 1, 1575
    TW 1, -196
    TW 1, -224
    TW 1, -232
    TW 1, -137
    TW 1, -76
    TLOOP Freq_6399

Ins26:
    INS_TONE $80, $B1, $01, Arp_63C3, Freq_6159, Comb_60EC ; $1A

Ins27:
    INS_TONE $80, $18, $81, Arp_63C3, Freq_6159, Comb_60EC ; $1B

Arp_63C3:
    TB 1, $00 ; +0
    TB 1, $0C ; +12
    TLOOP Arp_63C3

Ins28:
    INS_TONE $00, $78, $63, Arp_60F1, Freq_632E, Comb_60EC ; $1C

Ins32:
    INS_TONE $00, $78, $63, Arp_60F1, Freq_63DC, Comb_60EC ; $20

Freq_63DC:
    TW 7, 20
    TLOOP Freq_632E

Ins33:
    INS_TONE $00, $78, $63, Arp_60F1, Freq_63EB, Comb_60EC ; $21

Freq_63EB:
    TW 3, -16
    TW 4, -17
    TLOOP Freq_632E

Ins34:
    INS_TONE $00, $78, $63, Arp_60F1, Freq_63FD, Comb_60EC ; $22

Freq_63FD:
    TW 5, -8
    TW 2, -9
    TLOOP Freq_632E

Ins35:
    INS_TONE $00, $78, $63, Arp_60F1, Freq_640F, Comb_60EC ; $23

Freq_640F:
    TW 11, 1
    TW 3, 0
    TLOOP Freq_632E

Ins36:
    INS_TONE $00, $78, $63, Arp_60F1, Freq_6421, Comb_60EC ; $24

Freq_6421:
    TW 6, 9
    TW 1, 8
    TLOOP Freq_632E

Ins37:
    INS_TONE $00, $78, $63, Arp_60F1, Freq_6433, Comb_60EC ; $25

Freq_6433:
    TW 6, 18
    TW 1, 17
    TLOOP Freq_632E

Ins29:
    INS_TONE $D0, $A1, $37, Arp_6445, Freq_6159, Comb_60EC ; $1D

Arp_6445:
    TB 1, $00 ; +0
    TB 1, $04 ; +4
    TB 1, $07 ; +7
    TLOOP Arp_6445

Ins30:
    INS_TONE $40, $19, $71, Arp_60F1, Freq_632E, Comb_60EC ; $1E

Ins31:
    INS_TONE $80, $81, $71, Arp_60F1, Freq_6460, Comb_60E2 ; $1F

Freq_6460:
    TW 1, 768
    TW 1, -196
    TW 1, -224
    TW 1, -232
    TW 1, -1
    db $01 ; part of t3:freq
Freq_6460_L0:
    db $C8, $00 ; part of t3:freq
    TLOOP $6470

NoiseIns00:
    INS_NOISE $00, $81, $91, Noise_6483, Arp_60F1 ; $00

NoiseIns06:
    INS_NOISE $00, $51, $01, Noise_6483, Arp_60F1 ; $06

Noise_6483:
    TB 255, $44
    TLOOP Noise_6483

NoiseIns01:
    INS_NOISE $80, $91, $01, Noise_649D, Arp_60F1 ; $01

NoiseIns03:
    INS_NOISE $80, $65, $01, Noise_649D, Arp_60F1 ; $03 (unused)

NoiseIns05:
    INS_NOISE $80, $71, $01, Noise_649D, Arp_60F1 ; $05

Noise_649D:
    TB 1, $42
    TB 1, $43
    TLOOP Noise_649D

NoiseIns02:
    INS_NOISE $20, $41, $01, Noise_64AB, Noise_64AB ; $02

Noise_64AB:
    TB 255, $13
    TLOOP Noise_64AB

NoiseIns04:
    INS_NOISE $00, $47, $01, Noise_64AB, Arp_60F1 ; $04

OrphanIns_64B7:
    INS_NOISE $80, $F3, $F1, Noise_649D, Arp_60F1 ; not in the instrument table

Ins39:
    INS_TONE $80, $F8, $F1, Arp_60F1, Freq_64C7, Comb_60EC ; $27

Freq_64C7:
    TW 4, -80
    TW 1, 320
    TW 100, 35
    TLOOP Freq_64C7

Ins40:
    INS_TONE $D0, $59, $F1, Arp_64DC, Freq_64E3, Comb_60EC ; $28

Arp_64DC:
    TB 1, $00 ; +0
    TB 1, $01 ; +1
    TLOOP Arp_64DC

Freq_64E3:
    TW 3, 5
    TW 50, 10
    TLOOP Freq_64E3

Ins41:
    INS_TONE $80, $F1, $F1, Arp_64DC, Freq_64F5, Comb_60EC ; $29

Freq_64F5:
    TW 50, -100
    TLOOP Freq_64F5

Ins42:
    INS_TONE $00, $A9, $F1, Arp_64DC, Freq_60F6, Comb_60EC ; $2A

NoiseIns07:
    INS_NOISE $00, $C1, $01, Noise_651D, Noise_649D ; $07

NoiseIns09:
    INS_NOISE $00, $3B, $E2, Noise_6512, Arp_60F1 ; $09

Noise_6512:
    TB 5, $81
    TB 5, $42
    TB 5, $43
    TB 18, $62
    TLOOP Noise_6512

Noise_651D:
    TB 2, $42
    TB 2, $43
    TB 2, $42
    TB 1, $43
    TB 2, $53
    TB 2, $52
    TB 2, $53
    TB 8, $52
    TLOOP Noise_651D

NoiseIns08:
    INS_NOISE $00, $C1, $01, Noise_6537, Noise_649D ; $08

Noise_6537:
    TB 2, $53
    TB 2, $52
    TB 2, $53
    TB 1, $52
    TB 2, $42
    TB 2, $43
    TB 2, $42
    TB 8, $43
    TB 55, $65

Ins43:
    INS_TONE $80, $F2, $F1, Arp_6552, Freq_6569, Comb_60EC ; $2B

Arp_6552:
    TB 1, $00 ; +0
    TB 1, $03 ; +3
    TB 1, $06 ; +6
    TB 1, $03 ; +3
    TB 1, $06 ; +6
    TB 1, $09 ; +9
    TB 1, $06 ; +6
    TB 1, $09 ; +9

Arp_6552_L0:
    TB 4, $0C ; +12
    TB 4, $11 ; +17
    TLOOP Arp_6552_L0

Freq_6569:
    TW 1, 1
    TW 1, -1
    TLOOP Freq_6569

Ins44:
    INS_TONE $D0, $4A, $F3, Arp_657B, Freq_6582, Comb_60EC ; $2C

Arp_657B:
    TB 1, $00 ; +0
    TB 1, $01 ; +1
    TLOOP Arp_657B

Freq_6582:
    TW 4, 30
    TW 4, -30
    TLOOP Freq_6582

Ins45:
    INS_TONE $00, $F8, $F3, Arp_657B, Freq_6594, Comb_60EC ; $2D

Freq_6594:
    TW 5, 1
    TLOOP Freq_6594

Ins46:
    INS_TONE $40, $F8, $F3, Arp_657B, Freq_65A3, Comb_60EC ; $2E

Freq_65A3:
    TW 5, -20
    TLOOP Freq_65A3

Ins47:
    INS_TONE $80, $F2, $F3, Arp_657B, Freq_65B2, Comb_60EC ; $2F

Freq_65B2:
    TW 10, -60
    TLOOP Freq_65B2

Ins48:
    INS_TONE $80, $F7, $F3, Arp_657B, Freq_6399, Comb_60E2 ; $30

NoiseIns10:
    INS_NOISE $FF, $19, $C8, Noise_65C8, Arp_60F1 ; $0A

Noise_65C8:
    TB 3, $44
    TB 3, $56
    TLOOP Noise_65C8

NoiseIns11:
    INS_NOISE $80, $F6, $01, Noise_65E4, Arp_60F1 ; $0B

NoiseIns12:
    INS_NOISE $80, $F1, $F2, Noise_65DD, Arp_60F1 ; $0C

Noise_65DD:
    TB 12, $51
    TB 22, $3F
    TLOOP Noise_65DD

Noise_65E4:
    TB 255, $64
    TLOOP Noise_65E4

NoiseIns13:
    INS_NOISE $00, $4A, $F7, Noise_65F0, Arp_60F1 ; $0D

Noise_65F0:
    TB 3, $49
    TB 3, $4A
    TB 3, $4B
    TB 3, $4C
    TB 3, $4D
    TB 3, $4E

Noise_65F0_L0:
    TB 2, $4E
    TB 2, $2E
    TB 2, $3E
    TLOOP Noise_65F0_L0

NoiseIns14:
    INS_NOISE $00, $F5, $F7, Noise_660C, Arp_60F1 ; $0E

Noise_660C:
    TB 6, $10
    TB 6, $11
    TB 6, $12
    TB 6, $13
    TB 6, $44
    TB 6, $45
    TB 6, $46

Noise_660C_L0:
    TB 6, $47
    TLOOP Noise_660C_L0

NoiseIns15:
    INS_NOISE $00, $D1, $D1, Noise_6626, Arp_60F1 ; $0F

Noise_6626:
    TB 2, $38
    TB 8, $43
    TB 2, $3C
    TB 9, $3E
    TB 200, $5A
    TLOOP Noise_6626

Ins49:
    INS_TONE $80, $F9, $82, Arp_64DC, Freq_663C, Comb_60EC ; $31

Freq_663C:
    TW 3, 120
    TW 2, 5
    TLOOP Freq_663C

NoiseIns16:
    INS_NOISE $00, $F3, $D1, Noise_664C, Arp_60F1 ; $10

Noise_664C:
    TB 200, $5C
    TLOOP Noise_664C

NoiseIns17:
    INS_NOISE $00, $5A, $C1, Noise_6658, Arp_60F1 ; $11

Noise_6658:
    TB 3, $40
    TB 3, $41
    TB 3, $42
    TB 3, $43
    TB 3, $44
    TB 3, $45
    TB 3, $46
    TB 3, $47
    TB 200, $3C
    TLOOP Noise_6658

NoiseIns18:
    INS_NOISE $00, $7A, $C1, Noise_6674, Arp_60F1 ; $12

Noise_6674:
    TB 200, $30
    TLOOP Noise_6674

Ins50:
    INS_TONE $D0, $F3, $F3, Arp_60F1, Freq_6682, Comb_60EC ; $32

Freq_6682:
    TW 4, 30
    TW 4, -20
    TLOOP Freq_6682

NoiseIns19:
    INS_NOISE $80, $F1, $D1, Noise_6692, Arp_60F1 ; $13

Noise_6692:
    TB 3, $53
    TB 200, $5B
    TLOOP Noise_664C

Ins51:
    INS_TONE $00, $89, $F1, Arp_60F1, Freq_66A9, Comb_60EC ; $33

OrphanTab_66A2:
    TB 4, $00
    TB 1, $E8
    TLOOP OrphanTab_66A2

Freq_66A9:
    TW 8, 2
    TW 5, -200
    TW 20, 55
    TW 200, 6

    ; $66B5-$66B6: 2 unreferenced bytes
    db $AF, $66

Ins52:
    INS_TONE $00, $71, $F1, Arp_60F1, Freq_60F6, Comb_60EC ; $34

OrphanIns_66C0:
    INS_TONE $00, $F1, $F1, Arp_66C9, Freq_60F6, Comb_60EC ; not in the instrument table

Arp_66C9:
    TB 2, $00 ; +0
    TB 2, $05 ; +5
    TB 200, $0C ; +12

    ; $66CF-$66CF: 1 unreferenced byte
    db $00

Ins53:
    INS_TONE $DC, $64, $00, $C1F2, Freq_66DA, Arp_60F1 ; $35

Freq_66DA_L0:

    ; $66D9-$66D9: 1 unreferenced byte
    db $03

Freq_66DA:
    TW 57, 15560
    TLOOP Freq_66DA_L0

Wave_66E0:
    db $00, $35, $79, $BD, $DD, $B9, $75, $10, $00, $35, $79, $BD, $DD, $B9, $75, $10

    ; $66F0-$671F: 48 unreferenced bytes
    db $99, $F8, $87, $A7, $A9, $A3, $67, $88, $88, $39, $9B, $8A, $89, $8E, $BA, $A9
    db $00, $11, $22, $33, $44, $55, $66, $77, $88, $99, $AA, $BB, $CC, $DD, $EE, $FF
    db $01, $23, $45, $67, $89, $AB, $CD, $EF, $00, $44, $88, $00, $FF, $FF, $FF, $FF

Wave_6720:
    db $AF, $FE, $96, $56, $9B, $B9, $53, $46, $CF, $FD, $85, $57, $AB, $B8, $53, $47

    ; $6730-$673F: 16 unreferenced bytes
    db $AF, $96, $9B, $53, $CF, $85, $AB, $5C, $AF, $96, $9B, $53, $CF, $85, $AB, $53

Wave_6740:
    db $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $FF, $FF, $FF, $FF, $FF

TheEnd:
    db "-- THE END --" ; end-of-data marker left by the converter
