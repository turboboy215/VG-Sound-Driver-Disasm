; Dukes of Hazzard sound test (GB, PD) - music/SFX data $48E4-$5CAA

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
    dw Sfx00
    db 3 ; ch4, Blank  (SFX $00)
    db 127 ; priority
    dw Sfx01
    db 3 ; ch4, Menu beep  (SFX $01)
    db 127 ; priority
    dw Sfx02
    db 2 ; ch2, select  (SFX $02)

Sfx01:
    NOTE 10, $24, $05
    SFXEND

Sfx02:
    NOTE 20, C5, $37
    SFXEND

SongTable:
    ; song $00: Music off
    db 1, %1111 ; tempo, channel mask
    dw Song00_Ch1, Song00_Ch2, Song00_Ch3, Song00_Ch4
    dw Morph_5BA2 - 2, Wave_5B7C ; wave morph, wave
    ; song $01: TITLE
    db 11, %1111 ; tempo, channel mask
    dw Song01_Ch1, Song01_Ch2, Song01_Ch3, Song01_Ch4
    dw Morph_5BA8 - 2, Wave_5B6C ; wave morph, wave
    ; song $02: ENGINE
    db 30, %0100 ; tempo, channel mask
    dw Song02_Ch3
    dw Morph_5C7E - 2, Wave_5C5F ; wave morph, wave
    db $00, $00, $00, $00, $00, $00 ; (unused)
    ; song $03: STOP ENGINE
    db 30, %0100 ; tempo, channel mask
    dw Song00_Ch3
    dw Morph_5C7E - 2, Wave_5C5F ; wave morph, wave
    db $00, $00, $00, $00, $00, $00 ; (unused)
    ; song $04: SIREN
    db 1, %0001 ; tempo, channel mask
    dw Song04_Ch1
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; (unused)
    ; song $05: STOP SIREN
    db 5, %0001 ; tempo, channel mask
    dw Song00_Ch1
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; (unused)
    ; song $06: TUNE 2
    db 7, %1111 ; tempo, channel mask
    dw Song06_Ch1, Song06_Ch2, Song06_Ch3, Song06_Ch4
    dw Morph_5B9C - 2, Wave_5B8C ; wave morph, wave
    ; song $07: SKID ON
    db 1, %1000 ; tempo, channel mask
    dw Song07_Ch4
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; (unused)
    ; song $08: SKID OFF
    db 1, %1000 ; tempo, channel mask
    dw Song08_Ch4
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; (unused)
    ; song $09: CARHITCAR
    db 1, %1010 ; tempo, channel mask
    dw Song09_Ch2, Song09_Ch4
    db $00, $00, $00, $00, $00, $00, $00, $00 ; (unused)
    ; song $0A: TNT EXPLSN
    db 1, %1010 ; tempo, channel mask
    dw Song10_Ch2, Song10_Ch4
    db $00, $00, $00, $00, $00, $00, $00, $00 ; (unused)
    ; song $0B: Bridge on
    db 1, %1000 ; tempo, channel mask
    dw Song11_Ch4
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; (unused)
    ; song $0C: Bridge off
    db 1, %1000 ; tempo, channel mask
    dw Song08_Ch4
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; (unused)
    ; song $0D: Collision1
    db 1, %1000 ; tempo, channel mask
    dw Song13_Ch4
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; (unused)
    ; song $0E: Collision2
    db 1, %1010 ; tempo, channel mask
    dw Song14_Ch2, Song14_Ch4
    db $00, $00, $00, $00, $00, $00, $00, $00 ; (unused)
    ; song $0F: Collision3
    db 1, %1010 ; tempo, channel mask
    dw Song15_Ch2, Song14_Ch4
    db $00, $00, $00, $00, $00, $00, $00, $00 ; (unused)
    ; song $10: Collision4
    db 1, %1010 ; tempo, channel mask
    dw Song16_Ch2, Song14_Ch4
    db $00, $00, $00, $00, $00, $00, $00, $00 ; (unused)
    ; song $11: Arrows
    db 1, %1000 ; tempo, channel mask
    dw Song17_Ch4
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; (unused)
    ; song $12: Horn
    db 1, %0010 ; tempo, channel mask
    dw Song18_Ch2
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; (unused)
    ; song $13: Horn 2
    db 1, %0011 ; tempo, channel mask
    dw Song18_Ch2, Song19_Ch2
    db $00, $00, $00, $00, $00, $00, $00, $00 ; (unused)
    ; song $14: Get Turbo
    db 1, %0010 ; tempo, channel mask
    dw Song20_Ch2
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; (unused)
    ; song $15: pickup 1
    db 1, %0010 ; tempo, channel mask
    dw Song21_Ch2
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; (unused)
    ; song $16: pickup 2
    db 1, %0010 ; tempo, channel mask
    dw Song22_Ch2
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; (unused)
    ; song $17: Siren down
    db 4, %0001 ; tempo, channel mask
    dw Song23_Ch1
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; (unused)
    ; song $18: skid v2
    db 4, %1010 ; tempo, channel mask
    dw Song24_Ch2, Song24_Ch4
    db $00, $00, $00, $00, $00, $00, $00, $00 ; (unused)
    ; song $19: skid v2 off
    db 4, %1010 ; tempo, channel mask
    dw Song00_Ch2, Song00_Ch4
    db $00, $00, $00, $00, $00, $00, $00, $00 ; (unused)
    ; song $1A: TRUCK ENGINE
    db 30, %0100 ; tempo, channel mask
    dw Song26_Ch3
    dw Morph_5C7E - 2, Wave_5C5F ; wave morph, wave
    db $00, $00, $00, $00, $00, $00 ; (unused)
    ; song $1B: STOP ENGINE
    db 30, %0100 ; tempo, channel mask
    dw Song00_Ch3
    dw Morph_5C84 - 2, Wave_5C5F+15 ; wave morph, wave
    db $00, $00, $00, $00, $00, $00 ; (unused)

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

Song01_Ch1:
    STEP 0, $05
    STEP 0, $06
    STEP 0, $07
    STEP 0, $08
    STEP 0, $09
    STEP 0, $0A
    STEP 0, $06
    STEP 0, $07
    STEP 0, $08
    STEP 0, $09
    STEP 0, $0B
    STEP 0, $0C
    STEP 0, $0D
    STEP 0, $15
    STEP 0, $25

Song01_Ch2:
    STEP 0, $0E
    STEP 0, $0F
    STEP 0, $10
    STEP 0, $11
    STEP 0, $12
    STEP 0, $14
    STEP 0, $0F
    STEP 0, $10
    STEP 0, $11
    STEP 0, $12
    STEP 0, $13
    STEP 0, $16
    STEP 0, $16
    STEP 0, $16
    STEP 0, $26

Song01_Ch3:
    STEP 0, $27
    STEP 0, $17
    STEP 0, $18
    STEP 0, $19
    STEP 0, $1A
    STEP 0, $1B
    STEP 0, $1C
    STEP 0, $18
    STEP 0, $19
    STEP 0, $1A
    STEP 0, $1D
    STEP 0, $1E
    STEP 0, $1F
    STEP 0, $20
    STEP 0, $21

Song01_Ch4:
    STEP 0, $22
    STEP 0, $22
    STEP 0, $22
    STEP 0, $22
    STEP 0, $22
    STEP 0, $23
    STEP 0, $22
    STEP 0, $22
    STEP 0, $22
    STEP 0, $22
    STEP 0, $22
    STEP 0, $22
    STEP 0, $22
    STEP 0, $22
    STEP 0, $24

Song06_Ch1:
    STEP 0, $2B
    STEP 0, $36
    STEP 0, $2C
    STEP 0, $2B
    STEP 0, $2D
    STEP 0, $2B
    STEP 0, $36
    STEP 0, $2B
    STEP 0, $2C
    STEP 0, $2B
    STEP 0, $2D
    STEP 0, $2E
    STEP 0, $2F
    STEP 0, $30
    STEP 0, $31
    STEP 0, $32

Song06_Ch2:
    STEP 0, $33
    STEP 0, $33
    STEP 0, $34
    STEP 0, $33
    STEP 0, $35
    STEP 0, $33
    STEP 0, $33
    STEP 0, $33
    STEP 0, $34
    STEP 0, $33
    STEP 0, $35
    STEP 0, $00
    STEP 0, $3E
    STEP 2, $3E
    STEP 0, $3F
    STEP 0, $40

Song06_Ch3:
    STEP 0, $46
    STEP 0, $00
    STEP 0, $37
    STEP 0, $38
    STEP 0, $39
    STEP 0, $3A
    STEP 0, $3B
    STEP 0, $3B
    STEP 0, $37
    STEP 0, $3B
    STEP 0, $3C
    STEP 0, $3D
    STEP 0, $41
    STEP 0, $42
    STEP 0, $43
    STEP 0, $44

Song06_Ch4:
    STEP 0, $45

Song09_Ch4:
    STEP 0, $48
    STEP 0, $04

Song09_Ch2:
    STEP 0, $49
    STEP 0, $04

Pat072:
    NOTE 15, $24, $08
    PATEND

Pat073:
    NOTE 15, C5, $31
    PATEND

Song10_Ch4:
    STEP 0, $4A
    STEP 0, $04

Song10_Ch2:
    STEP 0, $4B
    STEP 0, $04

Pat074:
    NOTE 90, $24, $09
    PATEND

Pat075:
    NOTE 90, G4, $32
    PATEND

Song11_Ch4:
    STEP 0, $4C

Pat076:
    NOTE 4, $30, $0A
    SONGJUMP Song11_Ch4

Song13_Ch4:
    STEP 0, $4D
    STEP 0, $04

Pat077:
    NOTE 10, $24, $0B
    PATEND

Song15_Ch2:
    STEP 12, $4E
    STEP 0, $04

Song14_Ch2:
    STEP 0, $4E
    STEP 0, $04

Song14_Ch4:
    STEP 0, $4F
    STEP 0, $04

Pat078:
    NOTE 3, C5, $33
    KEYOFF 3
    PATEND

Pat079:
    NOTE 8, $30, $0C
    KEYOFF 4
    PATEND

Song16_Ch2:
    STEP 0, $50
    STEP 0, $04

Pat080:
    NOTE 6, C6, $34
    KEYOFF 20
    PATEND

Song17_Ch4:
    STEP 0, $51
    STEP 0, $04

Pat081:
    NOTE 4, $24, $0D
    KEYOFF 16
    PATEND

Song18_Ch2:
    STEP 0, $52
    STEP 0, $04

Song19_Ch2:
    STEP 0, $53
    STEP 0, $52
    STEP 0, $04

Pat082:
    NOTE 8, G5, $35
    NOTE 8, E5, $35
    NOTE 12, C5, $35
    KEYOFF 3
    NOTE 12, C5, $35
    KEYOFF 3
    NOTE 8, C5, $35
    NOTE 8, D5, $35
    NOTE 8, E5, $35
    NOTE 8, F5, $35
    NOTE 12, G5, $35
    KEYOFF 4
    NOTE 12, G5, $35
    KEYOFF 4
    NOTE 12, G5, $35
    KEYOFF 4
    NOTE 16, E5, $35
    KEYOFF 2
    PATEND

Pat083:
    NOTE 1, G5, $35
    PATEND

Song20_Ch2:
    STEP 0, $54
    STEP 0, $04

Pat084:
    NOTE 40, G4, $36
    KEYOFF 8
    PATEND

Song21_Ch2:
    STEP 0, $55
    STEP 0, $04

Pat085:
    NOTE 40, G5, $38
    PATEND

Song22_Ch2:
    STEP 0, $56
    STEP 0, $04

Pat086:
    NOTE 40, C6, $39
    PATEND

Song07_Ch4:
    STEP 0, $47
    STEP 0, $04

Song08_Ch4:
    STEP 0, $03

Song02_Ch3:
    STEP 0, $28
    STEP 0, $04

Song26_Ch3:
    STEP 0, $5A
    STEP 0, $04

Song04_Ch1:
    STEP 0, $29

Song04_Ch1_Loop:
    STEP 0, $2A

Song23_Ch1:
    STEP 0, $57
    STEP 0, $04

Pat087:
    NOTE 20, Gs4, $3A
    KEYOFF 100
    PATEND

Song24_Ch2:
    STEP 0, $58
    STEP 0, $04

Pat088:
    NOTE 0, C5, $3B
    PATEND

Song24_Ch4:
    STEP 0, $59
    STEP 0, $04

Pat089:
    NOTE 0, $24, $0E
    PATEND

Ins59:
    INS_TONE $80, $68, $E2, Arp_5524, Freq_4E2C, Comb_551F ; $3B

Freq_4E2C:
    TW 3, 8
    TW 3, -8
    TLOOP Freq_4E2C

NoiseIns14:
    INS_NOISE $80, $58, $81, Noise_4E3C, Arp_5524 ; $0E

Noise_4E3C:
    TB 2, $45
    TB 2, $44
    TB 2, $43
    TB 2, $44
    TLOOP Noise_4E3C

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

Pat071:
    NOTE 1, $24, $07
    PATEND

NoiseIns07:
    INS_NOISE $80, $88, $81, Noise_4E76, Arp_5524 ; $07

Noise_4E76:
    TB 3, $52
    TLOOP Noise_4E76

Pat005:
    NOTE 2, C3, $05
    NOTE 2, As4, $2D
    NOTE 2, G2, $05
    NOTE 2, As4, $2D
    NOTE 2, C3, $05
    NOTE 1, As4, $2D
    NOTE 1, B2, $05
    NOTE 2, C3, $05
    NOTE 1, C3, $05
    NOTE 1, E3, $05
    PATEND

Pat006:
    NOTE 2, F3, $05
    NOTE 2, C5, $09
    NOTE 2, C3, $05
    NOTE 1, C5, $09
    NOTE 1, E3, $05
    NOTE 2, F3, $05
    NOTE 2, C5, $09
    NOTE 2, C3, $05
    NOTE 2, C5, $09
    PATEND

Pat037:
    NOTE 2, F3, $05
    NOTE 2, C5, $09
    NOTE 2, C3, $05
    NOTE 1, C5, $09
    NOTE 1, E3, $05
    NOTE 2, F3, $05
    NOTE 2, C5, $09
    NOTE 2, C3, $05
    NOTE 2, C5, $09
    SONGJUMP Song01_Ch1

Pat039:
    NOTE 16, C5, $02
    PATEND

Pat007:
    NOTE 2, F2, $05
    NOTE 2, A4, $0F
    NOTE 2, C3, $05
    NOTE 2, A4, $0F
    NOTE 2, F2, $05
    NOTE 1, A4, $0F
    NOTE 1, D3, $05
    NOTE 2, C3, $05
    NOTE 2, D3, $05
    PATEND

Pat008:
    NOTE 2, As2, $05
    NOTE 2, F4, $09
    NOTE 2, F3, $05
    NOTE 2, F4, $09
    NOTE 2, As2, $05
    NOTE 2, F4, $09
    NOTE 2, F3, $05
    NOTE 2, F4, $09
    PATEND

Pat009:
    NOTE 2, F3, $05
    NOTE 2, C4, $09
    NOTE 2, C3, $05
    NOTE 2, C4, $09
    NOTE 2, C3, $05
    NOTE 2, As4, $2D
    NOTE 2, G2, $05
    NOTE 2, As4, $2D
    PATEND

Pat010:
    NOTE 2, C3, $05
    NOTE 2, As4, $2D
    PATEND

Pat011:
    NOTE 2, F2, $05
    NOTE 2, C4, $09
    NOTE 2, C3, $05
    NOTE 2, C4, $09
    NOTE 2, F2, $05
    NOTE 2, C4, $09
    NOTE 2, C3, $05
    NOTE 2, C4, $09
    PATEND

Pat012:
    NOTE 2, C3, $05
    NOTE 2, As4, $2D
    NOTE 2, G2, $05
    NOTE 2, As4, $2D
    NOTE 2, C3, $05
    NOTE 1, As4, $2D
    NOTE 1, C3, $05
    NOTE 2, G2, $05
    NOTE 1, As4, $2D
    NOTE 1, A2, $05
    PATEND

Pat013:
    NOTE 2, C3, $05
    NOTE 2, As4, $2D
    NOTE 2, G2, $05
    NOTE 2, As4, $2D
    NOTE 2, C3, $05
    NOTE 1, As4, $2D
    NOTE 1, E2, $05
    NOTE 2, G2, $05
    NOTE 1, As4, $2D
    NOTE 1, A2, $05
    PATEND

Pat014:
    NOTE 1, G3, $20
    NOTE 2, C4, $20
    NOTE 1, G4, $20
    NOTE 1, C4, $1D
    NOTE 1, E4, $20
    NOTE 1, C4, $20
    NOTE 2, G4, $20
    NOTE 1, C4, $20
    NOTE 1, E4, $20
    NOTE 1, G4, $20
    NOTE 1, C4, $1D
    NOTE 1, E4, $20
    NOTE 1, G4, $20
    NOTE 1, F4, $20
    PATEND

Pat015:
    NOTE 1, A3, $20
    NOTE 1, C4, $20
    NOTE 1, F4, $20
    NOTE 1, A4, $20
    NOTE 1, C5, $1D
    NOTE 1, F4, $20
    NOTE 1, C4, $20
    NOTE 2, A4, $20
    NOTE 1, C4, $20
    NOTE 1, F4, $20
    NOTE 1, A4, $20
    NOTE 4, C5, $1D
    PATEND

Pat038:
    NOTE 1, A3, $20
    NOTE 1, C4, $20
    NOTE 1, F4, $20
    NOTE 1, A4, $20
    NOTE 1, C5, $1D
    NOTE 1, F4, $20
    NOTE 1, C4, $20
    NOTE 2, A4, $20
    NOTE 1, C4, $20
    NOTE 1, F4, $20
    NOTE 1, A4, $20
    NOTE 4, C5, $1D
    SONGJUMP Song01_Ch2

Pat016:
    NOTE 1, A3, $20
    NOTE 1, C4, $20
    NOTE 1, F4, $20
    NOTE 1, A4, $20
    NOTE 1, C5, $1D
    NOTE 1, F4, $20
    NOTE 1, C4, $20
    NOTE 2, F4, $20
    NOTE 1, C4, $20
    NOTE 1, F4, $20
    NOTE 1, A4, $20
    NOTE 2, C5, $1D
    NOTE 2, A4, $0F
    PATEND

Pat017:
    NOTE 1, As3, $20
    NOTE 1, D4, $20
    NOTE 1, F4, $20
    NOTE 1, As4, $20
    NOTE 1, C5, $1D
    NOTE 1, F4, $20
    NOTE 1, D4, $20
    NOTE 2, As4, $20
    NOTE 1, D4, $20
    NOTE 1, F4, $20
    NOTE 1, As4, $20
    NOTE 1, C5, $1D
    NOTE 1, F4, $20
    NOTE 2, D4, $20
    PATEND

Pat018:
    NOTE 1, A3, $20
    NOTE 1, C4, $20
    NOTE 1, F4, $20
    NOTE 1, A4, $20
    NOTE 1, C5, $1D
    NOTE 1, F4, $20
    NOTE 2, C4, $20
    NOTE 1, E4, $20
    NOTE 1, C4, $20
    NOTE 1, E4, $20
    NOTE 1, G4, $20
    NOTE 1, C5, $1D
    NOTE 1, E4, $20
    NOTE 2, C4, $20
    PATEND

Pat019:
    NOTE 1, A3, $20
    NOTE 1, C4, $20
    NOTE 1, F4, $20
    NOTE 1, A4, $20
    NOTE 1, C5, $1D
    NOTE 1, F4, $20
    NOTE 2, C4, $20
    NOTE 1, A3, $20
    NOTE 1, C4, $20
    NOTE 1, F4, $20
    NOTE 1, A4, $20
    NOTE 1, C5, $1D
    NOTE 1, F4, $20
    NOTE 2, C4, $20
    PATEND

Pat020:
    NOTE 4, G4, $20
    PATEND

Pat021:
    NOTE 2, C3, $05
    NOTE 2, As4, $2D
    NOTE 2, G2, $05
    NOTE 2, As4, $2D
    NOTE 2, C3, $05
    NOTE 2, As4, $2D
    NOTE 2, C3, $05
    NOTE 2, C5, $06
    PATEND

Pat022:
    HOLD 1
    NOTE 1, A3, $20
    NOTE 2, As3, $20
    NOTE 1, C5, $1D
    NOTE 1, E4, $20
    NOTE 1, C4, $20
    NOTE 2, G4, $20
    NOTE 1, E4, $20
    NOTE 1, C4, $20
    NOTE 1, G4, $20
    NOTE 1, C5, $1D
    NOTE 1, E4, $20
    NOTE 2, C4, $20
    PATEND

Pat023:
    HOLD 10
    NOTE 1, A5, $26
    NOTE 1, C6, $26
    NOTE 1, D6, $27
    NOTE 1, C6, $26
    NOTE 2, C6, $26
    PATEND

Pat024:
    NOTE 1, A5, $27
    NOTE 1, G5, $26
    NOTE 2, F5, $26
    KEYOFF 6
    NOTE 1, A5, $26
    NOTE 1, C6, $26
    NOTE 1, D6, $27
    NOTE 1, C6, $26
    NOTE 2, C6, $26
    PATEND

Pat025:
    NOTE 1, Gs5, $26
    NOTE 1, G5, $26
    NOTE 2, F5, $26
    KEYOFF 11
    NOTE 1, F5, $26
    PATEND

Pat026:
    NOTE 1, A5, $26
    NOTE 1, F5, $26
    NOTE 1, A5, $27
    NOTE 1, G5, $26
    NOTE 1, F5, $26
    KEYOFF 1
    NOTE 1, F5, $26
    NOTE 1, F5, $26
    NOTE 1, E5, $27
    NOTE 1, D5, $26
    NOTE 1, C5, $26
    KEYOFF 1
    NOTE 2, C5, $26
    NOTE 1, C5, $26
    NOTE 1, C5, $26
    PATEND

Pat027:
    NOTE 1, D5, $27
    NOTE 1, F5, $26
    NOTE 2, F5, $26
    PATEND

Pat028:
    NOTE 3, F5, $26
    KEYOFF 7
    NOTE 1, A5, $26
    NOTE 1, C6, $26
    NOTE 1, D6, $27
    NOTE 1, C6, $26
    NOTE 2, C6, $26
    PATEND

Pat029:
    NOTE 1, D5, $27
    NOTE 1, F5, $26
    NOTE 1, F5, $26
    KEYOFF 1
    NOTE 3, F5, $26
    KEYOFF 5
    NOTE 1, A5, $27
    NOTE 1, C6, $26
    NOTE 1, C6, $26
    KEYOFF 1
    PATEND

Pat030:
    NOTE 8, C6, $26
    KEYOFF 1
    NOTE 1, C6, $26
    NOTE 1, C6, $27
    NOTE 1, C6, $26
    NOTE 1, E6, $27
    NOTE 1, D6, $26
    NOTE 1, C6, $26
    NOTE 1, C6, $26
    PATEND

Pat031:
    HOLD 2
    KEYOFF 14
    PATEND

Pat032:
    NOTE 2, C6, $27
    NOTE 1, C6, $26
    NOTE 1, C6, $26
    NOTE 1, E6, $27
    NOTE 1, D6, $26
    NOTE 1, C6, $26
    KEYOFF 1
    NOTE 1, Gs5, $26
    NOTE 1, G5, $26
    NOTE 1, F5, $26
    NOTE 1, C5, $27
    NOTE 1, D5, $26
    NOTE 1, F5, $26
    NOTE 1, F5, $26
    NOTE 1, F5, $27
    PATEND

Pat033:
    HOLD 5
    KEYOFF 11
    SONGJUMP Song01_Ch3

Pat034:
    NOTE 2, $24, $02
    NOTE 2, $24, $03
    NOTE 2, $24, $01
    NOTE 2, $24, $03
    NOTE 2, $24, $02
    NOTE 2, $24, $03
    NOTE 2, $24, $01
    NOTE 2, $24, $03
    PATEND

Pat035:
    NOTE 4, $24, $02
    PATEND

Pat036:
    NOTE 2, $24, $02
    NOTE 2, $24, $03
    NOTE 2, $24, $01
    NOTE 2, $24, $03
    NOTE 2, $24, $02
    NOTE 2, $24, $03
    NOTE 2, $24, $01
    NOTE 2, $24, $03
    SONGJUMP Song01_Ch4

Pat043:
    NOTE 2, A2, $05
    NOTE 2, A4, $10
    NOTE 2, E3, $05
    NOTE 2, A4, $11
    NOTE 2, A2, $05
    NOTE 2, A4, $10
    NOTE 2, E3, $05
    NOTE 1, C3, $05
    NOTE 1, A4, $10
    PATEND

Pat044:
    NOTE 2, D3, $05
    NOTE 2, D5, $12
    NOTE 2, A3, $05
    NOTE 2, D5, $12
    NOTE 2, D3, $05
    NOTE 2, D5, $12
    NOTE 2, A3, $05
    NOTE 2, C3, $05
    PATEND

Pat045:
    NOTE 2, E3, $05
    NOTE 2, E4, $12
    NOTE 2, B3, $05
    NOTE 2, E4, $12
    NOTE 2, E3, $05
    NOTE 2, E4, $12
    NOTE 2, B3, $05
    NOTE 1, C4, $05
    NOTE 1, E4, $12
    PATEND

Pat046:
    NOTE 2, A2, $05
    NOTE 2, A4, $11
    NOTE 2, E3, $05
    NOTE 2, A4, $11
    NOTE 2, A2, $05
    NOTE 2, A2, $05
    NOTE 2, As2, $05
    NOTE 2, B2, $05
    PATEND

Pat047:
    NOTE 2, C3, $05
    NOTE 2, C5, $12
    NOTE 2, G2, $05
    NOTE 2, C5, $11
    NOTE 2, C3, $05
    NOTE 2, C5, $11
    NOTE 2, C3, $05
    NOTE 1, Cs3, $05
    NOTE 1, C5, $10
    PATEND

Pat048:
    NOTE 2, D3, $05
    NOTE 2, D4, $10
    NOTE 2, A2, $05
    NOTE 2, D4, $12
    NOTE 2, D3, $05
    NOTE 2, D4, $10
    NOTE 2, Ds3, $05
    NOTE 1, E3, $05
    NOTE 1, D4, $10
    PATEND

Pat049:
    NOTE 2, F3, $05
    NOTE 2, F4, $11
    NOTE 2, C3, $05
    NOTE 2, F4, $11
    NOTE 2, F3, $05
    NOTE 2, F4, $11
    NOTE 2, F3, $05
    NOTE 1, Fs3, $05
    NOTE 1, F4, $11
    PATEND

Pat050:
    NOTE 2, G3, $05
    NOTE 2, G4, $11
    NOTE 2, D3, $05
    NOTE 2, G4, $11
    NOTE 8, G2, $05
    SONGJUMP Song06_Ch1

Pat051:
    NOTE 2, A3, $20
    NOTE 1, A4, $24
    NOTE 1, A4, $24
    NOTE 1, A4, $25
    NOTE 1, A4, $24
    NOTE 1, A4, $24
    KEYOFF 1
    NOTE 1, A4, $25
    KEYOFF 1
    NOTE 1, A4, $30
    NOTE 1, G4, $20
    NOTE 1, E4, $20
    NOTE 1, D4, $20
    NOTE 2, C4, $20
    PATEND

Pat052:
    NOTE 2, D4, $20
    NOTE 1, A4, $24
    NOTE 1, A4, $24
    NOTE 1, A4, $25
    NOTE 1, A4, $24
    NOTE 1, A4, $24
    KEYOFF 1
    NOTE 1, A4, $25
    KEYOFF 1
    NOTE 1, A4, $30
    NOTE 1, G4, $20
    NOTE 1, E4, $20
    NOTE 1, D4, $20
    NOTE 2, C4, $20
    PATEND

Pat053:
    NOTE 2, E4, $20
    NOTE 1, E4, $24
    NOTE 1, E4, $24
    NOTE 1, E4, $24
    NOTE 1, E4, $24
    NOTE 1, E4, $24
    KEYOFF 1
    NOTE 1, E4, $25
    KEYOFF 1
    NOTE 1, A4, $30
    NOTE 1, G4, $20
    NOTE 1, E4, $20
    NOTE 1, D4, $20
    NOTE 2, C4, $20
    PATEND

Pat054:
    NOTE 2, A2, $05
    NOTE 2, A4, $11
    NOTE 2, E3, $05
    NOTE 2, A4, $11
    NOTE 2, A2, $05
    NOTE 2, A4, $10
    NOTE 1, E3, $05
    NOTE 1, A4, $10
    NOTE 2, C3, $05
    PATEND

Pat055:
    NOTE 4, Fs6, $14
    NOTE 4, Fs6, $14
    NOTE 4, Fs6, $13
    NOTE 1, Fs6, $13
    NOTE 1, Fs5, $13
    NOTE 1, E6, $13
    NOTE 1, E6, $13
    PATEND

Pat056:
    NOTE 2, A6, $14
    NOTE 1, A6, $13
    NOTE 1, A6, $13
    NOTE 1, A6, $13
    NOTE 1, G6, $13
    NOTE 2, E6, $13
    NOTE 2, C6, $13
    NOTE 4, Cs6, $14
    KEYOFF 2
    PATEND

Pat057:
    HOLD 2
    NOTE 4, B5, $13
    NOTE 2, B5, $13
    NOTE 2, B5, $13
    NOTE 1, B5, $13
    NOTE 1, C6, $13
    NOTE 1, B5, $13
    NOTE 1, A5, $13
    NOTE 1, A5, $13
    NOTE 1, G5, $13
    PATEND

Pat058:
    KEYOFF 16
    PATEND

Pat059:
    NOTE 2, E5, $14
    NOTE 1, E5, $13
    NOTE 1, E5, $13
    NOTE 2, E5, $13
    NOTE 2, Fs5, $13
    NOTE 2, G5, $14
    NOTE 1, G5, $13
    NOTE 1, G5, $13
    NOTE 1, Fs5, $13
    NOTE 1, E5, $13
    KEYOFF 2
    PATEND

Pat060:
    NOTE 2, B5, $14
    NOTE 1, B5, $13
    NOTE 1, B5, $13
    NOTE 1, B5, $13
    NOTE 1, B5, $13
    NOTE 2, B5, $13
    NOTE 1, C6, $14
    KEYOFF 1
    NOTE 1, C6, $13
    KEYOFF 1
    NOTE 1, C6, $13
    NOTE 1, G5, $13
    NOTE 1, G5, $13
    KEYOFF 1
    PATEND

Pat061:
    NOTE 2, A5, $14
    NOTE 1, A5, $13
    NOTE 1, A5, $13
    NOTE 1, A5, $13
    NOTE 1, A5, $13
    NOTE 1, A5, $13
    NOTE 1, A5, $13
    NOTE 2, A5, $14
    NOTE 2, A5, $13
    NOTE 2, As5, $13
    NOTE 2, B5, $13
    PATEND

Pat062:
    HOLD 2
    NOTE 4, E4, $20
    NOTE 4, E4, $20
    NOTE 4, E4, $20
    NOTE 1, E4, $20
    NOTE 1, E4, $20
    PATEND

Pat063:
    HOLD 2
    NOTE 4, F4, $20
    NOTE 4, Ds4, $20
    NOTE 4, C4, $20
    NOTE 2, C5, $20
    PATEND

Pat064:
    HOLD 2
    NOTE 4, D5, $20
    NOTE 2, C5, $20
    NOTE 8, B4, $20
    SONGJUMP Song06_Ch2

Pat065:
    NOTE 2, E5, $27
    NOTE 2, C6, $26
    NOTE 2, E5, $26
    NOTE 4, C6, $27
    NOTE 2, As5, $26
    NOTE 2, G5, $26
    NOTE 2, F5, $26
    PATEND

Pat066:
    NOTE 2, Fs5, $26
    NOTE 2, D5, $26
    NOTE 5, C5, $26
    KEYOFF 1
    NOTE 4, C5, $27
    NOTE 2, G4, $26
    PATEND

Pat067:
    NOTE 4, A4, $26
    NOTE 4, A4, $26
    NOTE 4, A4, $26
    NOTE 4, Gs4, $26
    PATEND

Pat068:
    NOTE 6, G4, $26
    NOTE 2, Fs4, $26
    NOTE 2, F4, $26
    KEYOFF 6
    SONGJUMP Song06_Ch3

Pat069:
    NOTE 2, $24, $04
    NOTE 2, $24, $06
    NOTE 2, $24, $04
    NOTE 2, $24, $06
    NOTE 2, $24, $04
    NOTE 2, $24, $06
    NOTE 2, $24, $04
    NOTE 2, $24, $06
    SONGJUMP Song06_Ch4

Pat070:
    NOTE 16, C5, $02
    PATEND

Pat040:
    NOTE 10, D3, $2E
    PATEND

Pat090:
    NOTE 10, C3, $3C
    PATEND

Pat041:
    NOTE 10, Gs4, $2F
    PATEND

Pat042:
    KEYOFF 22
    SONGJUMP Song04_Ch1_Loop

Ins56:
    INS_TONE $00, $F3, $21, Arp_54E6, Freq_5529, Comb_551A ; $38

Arp_54E6:
    TB 1, $00 ; +0
    TB 1, $03 ; +3
    TB 1, $06 ; +6
    TB 1, $09 ; +9
    TB 1, $0C ; +12
    TB 2, $F4 ; -12
    TLOOP Arp_54E6

Ins57:
    INS_TONE $C0, $F3, $21, Arp_54FE, Freq_5529, Comb_551A ; $39

Arp_54FE:
    TB 4, $00 ; +0
    TB 4, $05 ; +5
    TB 4, $09 ; +9
    TB 4, $0C ; +12
    TLOOP Arp_54FE

Sfx00:
    HOLD 1
    SFXEND

OrphanTab_550E:
    TB 1, $01
    TB 1, $00
    TLOOP OrphanTab_550E

Comb_5515:
    TB 255, $00 ; freq table only
    TLOOP Comb_5515

Comb_551A:
    TB 255, $01 ; note only
    TLOOP Comb_551A

Comb_551F:
    TB 255, $02 ; note + freq table
    TLOOP Comb_551F

Arp_5524:
    TB 255, $00 ; +0
    TLOOP Arp_5524

Freq_5529:
    TW 255, 0
    TLOOP Freq_5529

OrphanTab_552F:
    TB 255, $00
    TLOOP OrphanTab_552F

OrphanTab_5534:
    TW 20, 0

OrphanTab_5534_Loop:
    TW 2, 1
    TW 2, -1
    TW 2, -1
    TW 2, 1
    TLOOP OrphanTab_5534_Loop

OrphanTab_5546:
    TW 3, 10
    TW 3, -10
    TW 3, -10
    TW 3, 10
    TLOOP OrphanTab_5546

OrphanTab_5555:
    TW 3, 5
    TW 3, -5
    TW 3, -5
    TW 3, 5
    TLOOP OrphanTab_5555

Freq_5564:
    TW 20, 0

Freq_5567:
    TW 3, 2
    TW 3, -2
    TW 3, -2
    TW 3, 2
    TLOOP Freq_5567

OrphanTab_5576:
    TW 3, 1
    TW 3, -1
    TW 3, -1
    TW 3, 1
    TLOOP OrphanTab_5576

Freq_5585:
    TW 1, 1
    TW 2, 0
    TW 1, -1
    TW 2, 0
    TW 1, -1
    TW 2, 0
    TW 1, 1
    TW 2, 0
    TLOOP Freq_5585

Freq_55A0:
    TW 1, -12
    TW 6, 2

Freq_55A6:
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

Freq_55A6_L0:
    TW 2, 16
    TW 2, -16
    TW 2, -16
    TW 2, 16
    TLOOP Freq_55A6_L0

Vol_5621:
    TB 2, $60 ; 25%
    TB 2, $40 ; 50%

Vol_5621_L0:
    TB 255, $20 ; 100%
    TLOOP Vol_5621_L0

Vol_562A:
    TB 255, $20 ; 100%
    TLOOP Vol_562A

Vol_562F:
    TB 255, $40 ; 50%
    TLOOP Vol_562F

Vol_5634:
    TB 255, $60 ; 25%
    TLOOP Vol_5634

Ins00:
    INS_TONE $80, $01, $01, Arp_5524, Freq_5529, Comb_551A ; $00

NoiseIns00:
    INS_NOISE $00, $01, $01, Arp_5524, Arp_5524 ; $00

Ins01:
    INS_WAVE BlankVol, BlankVol, Arp_5524, Freq_5529, Comb_551F ; $01, $02

Ins03:
    INS_TONE $80, $F2, $11, Arp_565C, Freq_5567, Comb_551F ; $03 (unused)

Arp_565C:
    TB 3, $00 ; +0
    TB 3, $0C ; +12
    TLOOP Arp_565C

Ins04:
    INS_TONE $60, $F2, $11, Arp_5524, Freq_5567, Comb_551F ; $04 (unused)

Ins05:
    INS_TONE $60, $F5, $11, Arp_5675, Freq_5567, Comb_551F ; $05

Arp_5675:
    TB 1, $00 ; +0
    TB 1, $0C ; +12
    TB 255, $00 ; +0
    TLOOP Arp_5675

Ins06:
    INS_TONE $60, $A4, $11, Arp_56EC, Freq_5529, Comb_551F ; $06

Ins45:
    INS_TONE $60, $A4, $11, Arp_5690, Freq_5529, Comb_551F ; $2D

Arp_5690:
    TB 2, $00 ; +0
    TB 2, $02 ; +2
    TB 2, $06 ; +6
    TB 2, $09 ; +9
    TLOOP Arp_5690

Ins07:
    INS_TONE $60, $A4, $11, Arp_56F5, Freq_5529, Comb_551F ; $07 (unused)

Ins08:
    INS_TONE $60, $A4, $11, Arp_56FE, Freq_5529, Comb_551F ; $08 (unused)

Ins09:
    INS_TONE $60, $A4, $11, Arp_5707, Freq_5529, Comb_551F ; $09

Ins10:
    INS_TONE $60, $A4, $11, Arp_5710, Freq_5529, Comb_551F ; $0A (unused)

Ins11:
    INS_TONE $60, $A4, $11, Arp_5719, Freq_5529, Comb_551F ; $0B (unused)

Ins12:
    INS_TONE $60, $A4, $11, Arp_5722, Freq_5529, Comb_551F ; $0C (unused)

Ins13:
    INS_TONE $60, $A4, $11, Arp_572D, Freq_5529, Comb_551F ; $0D (unused)

Ins14:
    INS_TONE $60, $A4, $11, Arp_5738, Freq_5529, Comb_551F ; $0E (unused)

Ins15:
    INS_TONE $60, $A4, $11, Arp_5743, Freq_5529, Comb_551F ; $0F

Arp_56EC:
    TB 2, $00 ; +0
    TB 2, $04 ; +4
    TB 2, $07 ; +7
    TLOOP Arp_56EC

Arp_56F5:
    TB 2, $00 ; +0
    TB 2, $03 ; +3
    TB 2, $07 ; +7
    TLOOP Arp_56F5

Arp_56FE:
    TB 2, $00 ; +0
    TB 2, $05 ; +5
    TB 2, $08 ; +8
    TLOOP Arp_56FE

Arp_5707:
    TB 2, $00 ; +0
    TB 2, $05 ; +5
    TB 2, $09 ; +9
    TLOOP Arp_5707

Arp_5710:
    TB 2, $00 ; +0
    TB 2, $03 ; +3
    TB 2, $09 ; +9
    TLOOP Arp_5710

Arp_5719:
    TB 2, $00 ; +0
    TB 2, $04 ; +4
    TB 2, $09 ; +9
    TLOOP Arp_5719

Arp_5722:
    TB 2, $00 ; +0
    TB 2, $03 ; +3
    TB 2, $07 ; +7
    TB 2, $0A ; +10
    TLOOP Arp_5722

Arp_572D:
    TB 2, $00 ; +0
    TB 2, $04 ; +4
    TB 2, $07 ; +7
    TB 2, $0A ; +10
    TLOOP Arp_572D

Arp_5738:
    TB 2, $00 ; +0
    TB 2, $04 ; +4
    TB 2, $07 ; +7
    TB 2, $0B ; +11
    TLOOP Arp_5738

Arp_5743:
    TB 2, $00 ; +0
    TB 2, $03 ; +3
    TB 2, $08 ; +8
    TLOOP Arp_5743

Ins32:
    INS_TONE $20, $C3, $11, Arp_5524, Freq_5585, Comb_551F ; $20

Ins48:
    INS_TONE $20, $C3, $11, Arp_5524, Freq_575E, Comb_551F ; $30

Freq_575E:
    TW 1, -12
    TW 4, 3
    TLOOP Freq_5585

Ins33:
    INS_TONE $80, $82, $11, Arp_5770, Freq_5585, Comb_551F ; $21 (unused)

Arp_5770:
    TB 1, $00 ; +0
    TB 1, $0C ; +12
    TB 2, $00 ; +0
    TB 2, $0C ; +12
    TLOOP Arp_5770

Ins34:
    INS_TONE $40, $78, $83, Arp_5524, Freq_55A6, Comb_551F ; $22 (unused)

Ins35:
    INS_TONE $40, $78, $83, Arp_5524, Freq_55A0, Comb_551F ; $23 (unused)

Ins54:
    INS_TONE $80, $F8, $F1, Arp_5796, Freq_579F, Comb_551F ; $36

Arp_5796:
    TB 1, $00 ; +0
    TB 1, $02 ; +2
    TB 1, $04 ; +4
    TLOOP Arp_5796

Freq_579F:
    TW 255, 2
    TLOOP Freq_579F

Ins55:
    INS_TONE $40, $F2, $F1, Arp_57AE, Freq_5529, Comb_551F ; $37

Arp_57AE:
    TB 4, $00 ; +0
    TB 4, $03 ; +3
    TB 4, $06 ; +6
    TB 4, $09 ; +9
    TLOOP Arp_57AE

Ins53:
    INS_TONE $C0, $C8, $41, Arp_5524, Freq_57C2, Comb_551F ; $35

Freq_57C2:
    TW 1, 2
    TW 1, -2
    TLOOP Freq_57C2

Ins36:
    INS_TONE $40, $67, $41, Arp_5524, Freq_5564, Comb_551F ; $24

Ins37:
    INS_TONE $40, $67, $41, Arp_5524, Freq_57DD, Comb_551F ; $25

Freq_57DD:
    TW 1, -20
    TW 5, 4
    TLOOP Freq_5564

Ins44:
    INS_WAVE Vol_5621, Vol_5634, Arp_5524, Freq_5585, Comb_551F ; $2C (unused)

Ins16:
    INS_TONE $C0, $C3, $11, Arp_5809, Freq_5800, Comb_57F9 ; $10

Comb_57F9:
    TB 3, $00 ; freq table only

Comb_57F9_L0:
    TB 255, $01 ; note only
    TLOOP Comb_57F9_L0

Freq_5800:
    TW 1, 1700
    TW 2, -60
    TLOOP Freq_5529

Arp_5809:
    TB 1, $00 ; +0
    TB 1, $07 ; +7
    TLOOP Arp_5809

Ins17:
    INS_TONE $C0, $C3, $11, Arp_5819, Freq_5800, Comb_57F9 ; $11

Arp_5819:
    TB 1, $00 ; +0
    TB 1, $04 ; +4
    TB 1, $07 ; +7
    TB 1, $0C ; +12
    TLOOP Arp_5819

Ins18:
    INS_TONE $C0, $C3, $11, Arp_582D, Freq_5800, Comb_57F9 ; $12

Arp_582D:
    TB 1, $00 ; +0
    TB 1, $07 ; +7
    TB 1, $0C ; +12
    TLOOP Arp_582D

Ins19:
    INS_WAVE Vol_5840, Vol_5634, Arp_5524, Freq_5585, Comb_551F ; $13

Vol_5840:
    TB 1, $60 ; 25%
    TB 1, $40 ; 50%

Vol_5840_L0:
    TB 255, $20 ; 100%
    TLOOP Vol_5840_L0

Ins20:
    INS_WAVE Vol_5840, Vol_5634, Arp_5524, Freq_5853, Comb_551F ; $14

Freq_5853:
    TW 1, -10
    TW 10, 1
    TLOOP Freq_5585

Ins21:
    INS_WAVE Vol_58F6, Vol_5634, Arp_58C5, Freq_5529, Comb_551F ; $15 (unused)

Ins22:
    INS_WAVE Vol_58F6, Vol_5634, Arp_58CC, Freq_5529, Comb_551F ; $16 (unused)

Ins23:
    INS_WAVE Vol_58F6, Vol_5634, Arp_58D3, Freq_5529, Comb_551F ; $17 (unused)

Ins24:
    INS_WAVE Vol_58F6, Vol_5634, Arp_58DA, Freq_5529, Comb_551F ; $18 (unused)

Ins25:
    INS_WAVE Vol_58F6, Vol_5634, Arp_58E1, Freq_5529, Comb_551F ; $19 (unused)

Ins26:
    INS_WAVE Vol_58F6, Vol_5634, Arp_58E8, Freq_5529, Comb_551F ; $1A (unused)

Ins27:
    INS_WAVE Vol_58F6, Vol_5634, Arp_58EF, Freq_5529, Comb_551F ; $1B (unused)

OrphanTab_58A2:
    TB 2, $00
    TB 2, $01
    TLOOP OrphanTab_58A2

OrphanTab_58A9:
    TB 2, $00
    TB 2, $02
    TLOOP OrphanTab_58A9

OrphanTab_58B0:
    TB 2, $00
    TB 2, $03
    TLOOP OrphanTab_58B0

OrphanTab_58B7:
    TB 2, $00
    TB 2, $04
    TLOOP OrphanTab_58B7

OrphanTab_58BE:
    TB 2, $00
    TB 2, $05
    TLOOP OrphanTab_58BE

Arp_58C5:
    TB 2, $00 ; +0
    TB 2, $06 ; +6
    TLOOP Arp_58C5

Arp_58CC:
    TB 2, $00 ; +0
    TB 2, $07 ; +7
    TLOOP Arp_58CC

Arp_58D3:
    TB 2, $00 ; +0
    TB 2, $08 ; +8
    TLOOP Arp_58D3

Arp_58DA:
    TB 2, $00 ; +0
    TB 2, $09 ; +9
    TLOOP Arp_58DA

Arp_58E1:
    TB 2, $00 ; +0
    TB 2, $0A ; +10
    TLOOP Arp_58E1

Arp_58E8:
    TB 2, $00 ; +0
    TB 2, $0B ; +11
    TLOOP Arp_58E8

Arp_58EF:
    TB 2, $00 ; +0
    TB 2, $0C ; +12
    TLOOP Arp_58EF

Vol_58F6:
    TB 4, $20 ; 100%
    TB 8, $40 ; 50%
    TB 255, $60 ; 25%
    TLOOP BlankVol

Ins46:
    INS_WAVE Vol_562A, Vol_5634, Arp_5909, Freq_5529, Comb_551F ; $2E

Arp_5909:
    TB 1, $00 ; +0
    TB 1, $FE ; -2
    TB 1, $00 ; +0
    TB 1, $FB ; -5
    TLOOP Arp_5909

Ins60:
    INS_WAVE Vol_562A, Vol_5634, Arp_591E, Freq_5529, Comb_551F ; $3C

Arp_591E:
    TB 1, $00 ; +0
    TB 1, $03 ; +3
    TB 1, $01 ; +1
    TB 1, $FB ; -5
    TLOOP Arp_591E

Ins47:
    INS_TONE $80, $18, $18, Arp_5524, Freq_5932, Comb_551F ; $2F

Freq_5932:
    TW 1, 50
    TW 1, 40
    TW 1, 30
    TW 1, 20
    TW 1, 10
    TW 3, -1
    TW 13, -12
    TW 1, 9
    TLOOP Freq_5932

Ins58:
    INS_TONE $80, $C8, $C7, Arp_5524, Freq_5956, Comb_551F ; $3A

Freq_5956:
    TW 1, 50
    TW 1, 40
    TW 1, 30
    TW 1, 20
    TW 1, 10
    TW 3, -1
    TW 13, -12
    TW 1, -20
    TLOOP Freq_5956

    ; $5971-$5973: 3 unreferenced bytes
    db $00, $32, $59

Ins38:
    INS_WAVE Vol_562A, Vol_5634, Arp_597E, Freq_5A73, Comb_551F ; $26

Arp_597E:
    TB 2, $F4 ; -12
    TB 255, $00 ; +0
    TLOOP Arp_597E

Ins39:
    INS_WAVE Vol_562A, Vol_5634, Arp_5524, Freq_5A6D, Comb_551F ; $27

Ins42:
    INS_WAVE Vol_59A3, Vol_5634, Arp_5524, Freq_5A73, Comb_551F ; $2A (unused)

Ins43:
    INS_WAVE Vol_59A3, Vol_5634, Arp_5524, Freq_5A6D, Comb_551F ; $2B (unused)

Vol_59A3:
    TB 2, $20 ; 100%

Vol_59A3_L0:
    TB 255, $40 ; 50%
    TLOOP Vol_59A3_L0

Ins51:
    INS_TONE $80, $F1, $21, Arp_5A1A, Freq_59B3, Comb_551F ; $33

Freq_59B3:
    TW 255, -60
    TLOOP Freq_59B3

Ins28:
    INS_TONE $80, $E1, $21, Arp_5A1A, Freq_59C2, Comb_5515 ; $1C, $1E (unused)

Freq_59C2:
    TW 1, 1100
    TW 1, 100
    TW 255, -80
    TLOOP Freq_59C2

Ins50:
    INS_TONE $80, $F5, $21, Arp_59D7, Freq_59FC, Comb_551F ; $32

Arp_59D7:
    TB 2, $00 ; +0
    TB 1, $FE ; -2
    TB 1, $03 ; +3
    TB 1, $00 ; +0
    TB 2, $00 ; +0
    TB 2, $02 ; +2
    TB 1, $00 ; +0
    TB 2, $00 ; +0
    TB 1, $FE ; -2
    TB 1, $FF ; -1
    TB 1, $00 ; +0
    TB 1, $00 ; +0
    TB 2, $FD ; -3
    TB 1, $02 ; +2
    TB 2, $01 ; +1
    TB 1, $FF ; -1
    TB 2, $01 ; +1
    TLOOP Arp_59D7

Freq_59FC:
    TW 255, -10

Freq_59FC_L0:
    TW 3, 80
    TW 3, -80
    TLOOP Freq_59FC_L0

Ins49:
    INS_TONE $80, $F1, $21, Arp_5A1A, Freq_5A21, Comb_5515 ; $31

Ins29:
    INS_TONE $80, $F1, $21, Arp_5A1A, Freq_5A21, Comb_5515 ; $1D

Arp_5A1A:
    TB 1, $00 ; +0
    TB 1, $02 ; +2
    TLOOP Arp_5A1A

Freq_5A21:
    TW 1, 1700
    TW 2, -60

Freq_5A21_L0:
    TW 1, 100
    TW 255, -60
    TLOOP Freq_5A21_L0

Ins31:
    INS_TONE $80, $51, $21, Arp_5A48, Freq_5A39, Comb_5515 ; $1F (unused)

Freq_5A39:
    TW 1, 4060
    TW 1, -1
    TW 1, -4060

Freq_5A39_L0:
    TW 255, 0
    TLOOP Freq_5A39_L0

Arp_5A48:
    TB 1, $00 ; +0
    TB 1, $FF ; -1
    TB 1, $FE ; -2
    TB 1, $FD ; -3
    TLOOP Arp_5A48

Ins40:
    INS_WAVE Vol_562A, Vol_5634, Arp_5524, Freq_5585, Comb_551F ; $28 (unused)

Ins41:
    INS_WAVE Vol_562F, Vol_5634, Arp_5524, Freq_5585, Comb_551F ; $29 (unused)

    ; $5A67-$5A6C: 6 unreferenced bytes
    db $32, $00, $00, $00, $73, $5A

Freq_5A6D:
    TW 1, -10
    TW 5, 2

Freq_5A73:
    TW 12, 0

Freq_5A73_L0:
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
    TLOOP Freq_5A73_L0

NoiseIns08:
    INS_NOISE $00, $D1, $91, Noise_5AC2, Arp_5524 ; $08

NoiseIns09:
    INS_NOISE $00, $F6, $91, Noise_5AAB, Arp_5524 ; $09

Noise_5AAB:
    TB 3, $45

Noise_5AAB_L0:
    TB 1, $55
    TB 1, $54
    TB 1, $56
    TB 1, $54
    TB 2, $52
    TB 2, $53
    TB 2, $54
    TB 2, $55
    TB 2, $56
    TLOOP Noise_5AAB_L0

Noise_5AC2:
    TB 255, $45
    TLOOP Noise_5AC2

NoiseIns10:
    INS_NOISE $00, $B1, $91, Noise_5ACE, Arp_5524 ; $0A

Noise_5ACE:
    TB 1, $44
    TB 1, $45
    TB 1, $46
    TB 1, $47
    TLOOP Noise_5ACE

NoiseIns02:
    INS_NOISE $00, $51, $91, Noise_5AE0, Arp_5524 ; $02

Noise_5AE0:
    TB 255, $44
    TLOOP Noise_5AE0

NoiseIns04:
    INS_NOISE $00, $35, $01, Noise_5AF3, Arp_5524 ; $04

NoiseIns03:
    INS_NOISE $20, $41, $01, Noise_5AF3, Noise_5AF3 ; $03

Noise_5AF3:
    TB 255, $13
    TLOOP Noise_5AF3

NoiseIns01:
    INS_NOISE $80, $44, $01, Noise_5AFF, Arp_5524 ; $01

Noise_5AFF:
    TB 255, $32
    TLOOP Noise_5AFF

Noise_5B04:
    TB 2, $42
    TB 255, $32
    TLOOP Noise_5B04

NoiseIns06:
    INS_NOISE $80, $71, $01, Noise_5B04, Arp_5524 ; $06

NoiseIns11:
    INS_NOISE $80, $E1, $01, Noise_5B19, Arp_5524 ; $0B

Noise_5B19:
    TB 3, $44
    TB 255, $47
    TLOOP Noise_5B19

NoiseIns12:
    INS_NOISE $80, $81, $01, Noise_5B27, Arp_5524 ; $0C

Noise_5B27:
    TB 2, $43
    TB 2, $45
    TLOOP Noise_5B27

NoiseIns05:
    INS_NOISE $00, $F1, $C1, Noise_5B35, Arp_5524 ; $05

Noise_5B35:
    TB 10, $28
    TLOOP Noise_5B35

Ins52:
    INS_TONE $80, $69, $E2, Arp_5B43, Freq_5B4A, Comb_551F ; $34

Arp_5B43:
    TB 1, $00 ; +0
    TB 1, $01 ; +1
    TLOOP Arp_5B43

Freq_5B4A:
    TW 5, 0
    TW 5, 10
    TW 255, -2
    TLOOP Freq_5B4A

NoiseIns13:
    INS_NOISE $00, $49, $A1, Noise_5B5D, Arp_5524 ; $0D

Noise_5B5D:
    TB 1, $37
    TB 1, $36
    TB 1, $35
    TB 1, $34
    TB 1, $33
    TB 255, $32
    TLOOP Noise_5B5D

Wave_5B6C:
    db $F0, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

Wave_5B7C:
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

Wave_5B8C:
    db $89, $73, $00, $48, $A8, $55, $AF, $FB, $87, $8A, $BA, $89, $98, $65, $55, $56

Morph_5B9C:
    MORPH 255, $30, $89
    TLOOP Morph_5B9C

Morph_5BA2:
    MORPH 255, $30, $00
    TLOOP Morph_5BA2

Morph_5BA8:
    MORPH 11, $30, $F0
    MORPH 11, $30, $FF
    MORPH 11, $31, $F0
    MORPH 11, $31, $FF
    MORPH 11, $32, $F0
    MORPH 11, $32, $FF
    MORPH 11, $33, $F0
    MORPH 11, $33, $FF
    MORPH 11, $34, $F0
    MORPH 11, $34, $FF
    MORPH 11, $35, $F0
    MORPH 11, $35, $FF
    MORPH 11, $36, $F0
    MORPH 11, $36, $FF
    MORPH 11, $37, $F0
    MORPH 11, $37, $FF
    MORPH 11, $38, $F0
    MORPH 11, $38, $FF
    MORPH 11, $39, $F0
    MORPH 11, $39, $FF
    MORPH 11, $3A, $F0
    MORPH 11, $3A, $FF
    MORPH 11, $3B, $F0
    MORPH 11, $3B, $FF
    MORPH 11, $3C, $F0
    MORPH 11, $3C, $FF
    MORPH 11, $3D, $F0
    MORPH 11, $3D, $FF
    MORPH 11, $3E, $F0
    MORPH 11, $3E, $FF
    MORPH 11, $3F, $F0
    MORPH 11, $3F, $00
    MORPH 11, $3E, $F0
    MORPH 11, $3E, $00
    MORPH 11, $3D, $F0
    MORPH 11, $3D, $00
    MORPH 11, $3C, $F0
    MORPH 11, $3C, $00
    MORPH 11, $3B, $F0
    MORPH 11, $3B, $00
    MORPH 11, $3A, $F0
    MORPH 11, $3A, $00
    MORPH 11, $39, $F0
    MORPH 11, $39, $00
    MORPH 11, $38, $F0
    MORPH 11, $38, $00
    MORPH 11, $37, $F0
    MORPH 11, $37, $00
    MORPH 11, $36, $F0
    MORPH 11, $36, $00
    MORPH 11, $35, $F0
    MORPH 11, $35, $00
    MORPH 11, $34, $F0
    MORPH 11, $34, $00
    MORPH 11, $33, $F0
    MORPH 11, $33, $00
    MORPH 11, $32, $F0
    MORPH 11, $32, $00
    MORPH 11, $31, $F0
    MORPH 11, $31, $00
    TLOOP Morph_5BA8

Wave_5C5F:
    db $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF
    db $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; rest of Wave_5C5F+15

Morph_5C7E:
    MORPH 2, $30, $FF
    TLOOP Morph_5C7E

Morph_5C84:
    MORPH 1, $34, $F0
    MORPH 1, $34, $FF
    MORPH 1, $35, $F0
    MORPH 1, $35, $FF
    MORPH 1, $36, $F0
    MORPH 1, $36, $FF
    MORPH 1, $36, $F0
    MORPH 1, $36, $00
    MORPH 1, $35, $F0
    MORPH 1, $35, $00
    MORPH 1, $34, $F0
    MORPH 1, $34, $00
    TLOOP Morph_5C84
