; Carmageddon (GBC) - music/SFX data $45F5-$53F9

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
    dw Pat046
    db 3 ; ch4  (SFX $00)
    dw Pat047
    db 3 ; ch4  (SFX $01)
    dw Pat048
    db 3 ; ch4  (SFX $02)
    dw Pat049
    db 3 ; ch4  (SFX $03)
    dw Pat050
    db 3 ; ch4  (SFX $04)
    dw Pat051
    db 3 ; ch4  (SFX $05)
    dw Pat052
    db 3 ; ch4  (SFX $06)
    dw Pat053
    db 2 ; ch2  (SFX $07)
    dw Pat054
    db 2 ; ch2  (SFX $08)
    dw Pat055
    db 2 ; ch2  (SFX $09)
    dw Pat056
    db 2 ; ch2  (SFX $0A)
    dw Pat057
    db 2 ; ch2  (SFX $0B)
    dw Pat058
    db 2 ; ch2  (SFX $0C)
    dw Pat059
    db 2 ; ch2  (SFX $0D)
    dw Pat060
    db 3 ; ch4  (SFX $0E)
    dw Pat061
    db 2 ; ch2  (SFX $0F)

SongTable:
    dw Song00_Ch1, Song00_Ch2, Song00_Ch4
    dw Song01_Ch1, Song01_Ch2, Song01_Ch4
    dw Song02_Ch1, Song02_Ch2, Song02_Ch4
    db $00, $00, $00, $00, $2E, $00 ; (not a valid song)

Pat046:
    NOTE 6, $18, $03
    PATEND

NoiseIns03:
    INS_NOISE $00, $F3, $F1, Noise_46D9, NoiseCtl_52E7 ; $03

Noise_46D9:
    TB 2, $03

Noise_46D9_L0:
    TB 1, $47
    TB 1, $43
    TB 1, $33
    TLOOP Noise_46D9_L0

    ; $46E4-$46E6: 3 unreferenced bytes
    db $00, $2F, $00

Pat047:
    NOTE 6, $18, $04
    PATEND

NoiseIns04:
    INS_NOISE $00, $F3, $F1, Noise_46F2, NoiseCtl_52E7 ; $04

Noise_46F2:
    TB 1, $1B

Noise_46F2_L0:
    TB 100, $6B
    TLOOP Noise_46F2_L0

    ; $46F9-$46FB: 3 unreferenced bytes
    db $00, $30, $00

Pat048:
    NOTE 6, $18, $05
    PATEND

NoiseIns05:
    INS_NOISE $00, $F3, $F1, Noise_4707, NoiseCtl_52E7 ; $05

Noise_4707:
    TB 200, $6B
    TLOOP Noise_4707

    ; $470C-$470E: 3 unreferenced bytes
    db $00, $31, $00

Pat049:
    NOTE 2, $18, $06
    PATEND

NoiseIns06:
    INS_NOISE $00, $D1, $F1, Noise_471A, NoiseCtl_52E7 ; $06

Noise_471A:
    TB 1, $03

Noise_471A_L0:
    TB 1, $68
    TB 1, $69
    TB 1, $6B
    TB 1, $6C
    TLOOP Noise_471A_L0

    ; $4727-$4729: 3 unreferenced bytes
    db $00, $32, $00

Pat050:
    NOTE 2, $18, $07
    PATEND

NoiseIns07:
    INS_NOISE $00, $D1, $F1, Noise_4735, NoiseCtl_52E7 ; $07

Noise_4735:
    TB 2, $6F

Noise_4735_L0:
    TB 2, $6B
    TB 1, $6B
    TB 1, $6B
    TLOOP Noise_4735_L0

    ; $4740-$4742: 3 unreferenced bytes
    db $00, $33, $00

Pat051:
    NOTE 2, $18, $08
    PATEND

NoiseIns08:
    INS_NOISE $80, $D1, $F1, Noise_474E, NoiseCtl_52E7 ; $08

Noise_474E:
    TB 2, $6F
    TB 2, $13
    TLOOP Noise_474E

    ; $4755-$4757: 3 unreferenced bytes
    db $00, $34, $00

Pat052:
    NOTE 4, $18, $09
    PATEND

NoiseIns09:
    INS_NOISE $00, $A3, $F1, Noise_4763, NoiseCtl_52E7 ; $09

Noise_4763:
    TB 2, $13

Noise_4763_L0:
    TB 1, $17
    TB 1, $16
    TB 1, $14
    TLOOP Noise_4763_L0

    ; $476E-$4770: 3 unreferenced bytes
    db $00, $35, $00

Pat053:
    NOTE 3, C5, $14
    PATEND

Ins20:
    INS_TONE $80, $E2, $F1, Arp_477E, Freq_51CE, Comb_518B ; $14

Arp_477E:
    TB 2, $00 ; +0
    TB 2, $05 ; +5
    TB 2, $07 ; +7
    TB 2, $0C ; +12
    TLOOP Arp_477E

    ; $4789-$478B: 3 unreferenced bytes
    db $00, $36, $00

Pat054:
    NOTE 3, C5, $15
    PATEND

Ins21:
    INS_TONE $80, $E2, $F1, Arp_4799, Freq_51CE, Comb_518B ; $15

Arp_4799:
    TB 1, $00 ; +0
    TB 1, $02 ; +2
    TB 1, $04 ; +4
    TB 1, $06 ; +6
    TB 1, $08 ; +8
    TB 1, $0A ; +10
    TB 1, $0C ; +12
    TB 1, $0E ; +14
    TB 1, $10 ; +16
    TB 1, $12 ; +18
    TB 1, $14 ; +20
    TLOOP Arp_4799

    ; $47B2-$47B4: 3 unreferenced bytes
    db $00, $37, $00

Pat055:
    NOTE 5, G4, $16
    PATEND

Ins22:
    INS_TONE $40, $F3, $F1, Arp_47C2, Freq_47C7, Comb_518B ; $16

Arp_47C2:
    TB 200, $00 ; +0
    TLOOP Arp_47C2

Freq_47C7:
    TW 8, 40
    TW 8, -40
    TLOOP Freq_47C7

    ; $47D0-$47D2: 3 unreferenced bytes
    db $00, $38, $00

Pat056:
    NOTE 3, G5, $17
    KEYOFF 2
    PATEND

Ins23:
    INS_TONE $80, $8D, $81, Arp_47C2, Freq_47E2, Comb_518B ; $17

Freq_47E2:
    TW 2, -7
    TW 2, 7
    TLOOP Freq_47E2

    ; $47EB-$47ED: 3 unreferenced bytes
    db $00, $39, $00

Pat057:
    NOTE 3, A5, $17
    KEYOFF 2
    PATEND

    ; $47F4-$47F6: 3 unreferenced bytes
    db $00, $3A, $00

Pat058:
    NOTE 2, C6, $18
    PATEND

Ins24:
    INS_TONE $80, $71, $F1, Arp_47C2, Freq_51CE, Comb_518B ; $18

    ; $4804-$4806: 3 unreferenced bytes
    db $00, $3B, $00

Pat059:
    NOTE 3, E3, $19
    PATEND

Ins25:
    INS_TONE $C0, $F1, $F1, Arp_4814, Freq_51CE, Comb_518B ; $19

Arp_4814:
    TB 4, $00 ; +0
    TB 8, $F9 ; -7
    TLOOP Arp_4814

    ; $481B-$481D: 3 unreferenced bytes
    db $00, $3C, $00

Pat060:
    NOTE 1, $18, $0A
    KEYOFF 3
    PATEND

NoiseIns10:
    INS_NOISE $00, $4E, $C1, Noise_482B, NoiseCtl_52E7 ; $0A

Noise_482B:
    TB 5, $6F
    TB 5, $6B
    TB 5, $6F
    TB 5, $6B

Noise_482B_L0:
    TB 200, $6F
    TLOOP Noise_482B_L0

    ; $4838-$483A: 3 unreferenced bytes
    db $00, $3D, $00

Pat061:
    NOTE 4, C3, $1A
    KEYOFF 2
    PATEND

Ins26:
    INS_TONE $80, $C4, $51, Arp_47C2, Freq_484A, Comb_518B ; $1A

Freq_484A:
    TW 2, 15
    TW 2, -5
    TLOOP Freq_484A

Song00_Ch1:
    STEP 0, $01
    STEP 0, $01
    STEP 0, $01
    STEP 0, $02
    STEP 0, $01
    STEP 0, $01
    STEP 0, $01
    STEP 0, $02
    STEP 0, $01
    STEP 0, $01
    STEP 0, $01
    STEP 0, $02
    STEP 3, $01
    STEP 3, $01
    STEP 3, $01
    STEP 3, $02
    STEP 7, $01
    STEP 7, $01
    STEP 7, $01
    STEP 7, $02
    STEP 0, $01
    STEP 0, $01
    STEP 0, $01
    STEP 0, $02
    STEP 0, $01
    STEP 0, $01
    STEP 0, $01
    STEP 0, $02
    STEP 3, $01
    STEP 3, $01
    STEP 3, $01
    STEP 3, $02
    STEP 7, $01
    STEP 7, $01
    STEP 7, $01
    STEP 7, $02
    STEP 0, $01
    STEP 0, $01
    STEP 0, $01
    STEP 0, $02
    STEP -5, $01
    STEP -5, $01
    STEP -5, $01
    STEP 0, $0B

Song00_Ch2:
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 0, $05
    STEP 0, $06
    STEP 0, $05
    STEP 0, $07
    STEP 3, $05
    STEP 3, $06
    STEP 3, $05
    STEP 3, $07
    STEP 7, $05
    STEP 7, $06
    STEP 7, $05
    STEP 7, $07
    STEP 0, $05
    STEP 0, $06
    STEP 0, $05
    STEP 0, $07
    STEP 0, $08
    STEP 0, $06
    STEP 0, $09
    STEP 0, $07
    STEP 3, $08
    STEP 3, $06
    STEP 3, $09
    STEP 3, $07
    STEP 7, $08
    STEP 7, $06
    STEP 7, $09
    STEP 7, $07
    STEP 0, $05
    STEP 0, $06
    STEP 0, $05
    STEP 0, $07
    STEP 0, $0D
    STEP 0, $0D
    STEP 0, $0D
    STEP 0, $0C

Song00_Ch4:
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00

Song00_Ch4_Loop:
    STEP 0, $03
    STEP 0, $03
    STEP 0, $03
    STEP 0, $0A

Song01_Ch1:
    STEP 0, $0E
    STEP 0, $0F
    STEP 0, $0E
    STEP 0, $0F
    STEP 0, $0E
    STEP 0, $0E
    STEP 0, $0E
    STEP 0, $0F
    STEP 0, $0E
    STEP 0, $0E
    STEP 0, $0E
    STEP 0, $10
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 0, $11
    STEP 0, $0E
    STEP 0, $0F
    STEP 0, $0E
    STEP 0, $0F
    STEP 2, $0E
    STEP 2, $0F
    STEP 2, $0E
    STEP 2, $10
    STEP 7, $0E
    STEP 7, $0F
    STEP 2, $0E
    STEP 2, $0E
    STEP 7, $0E
    STEP 7, $0F
    STEP 2, $0E
    STEP 0, $0D
    STEP 0, $0D
    STEP 0, $0D
    STEP 2, $03
    STEP 5, $18

Song01_Ch2:
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 0, $12
    STEP 0, $13
    STEP 0, $12
    STEP 0, $14
    STEP 0, $12
    STEP 0, $13
    STEP 0, $12
    STEP 0, $14
    STEP 0, $12
    STEP 0, $12
    STEP 0, $12
    STEP 0, $14
    STEP 0, $12
    STEP 0, $13
    STEP 0, $12
    STEP 0, $14
    STEP 2, $12
    STEP 2, $13
    STEP 2, $12
    STEP 2, $14
    STEP 0, $15
    STEP 7, $12
    STEP -5, $15
    STEP -5, $12
    STEP 0, $15
    STEP 7, $12
    STEP -5, $15
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 2, $14
    STEP 5, $19

Song01_Ch4:
    STEP 0, $16
    STEP 0, $16
    STEP 0, $16
    STEP 0, $17

Song02_Ch1:
    STEP 0, $00
    STEP 0, $00
    STEP 0, $1D
    STEP 0, $1E
    STEP 0, $1F
    STEP 0, $20
    STEP 0, $21
    STEP 0, $22
    STEP 0, $23
    STEP 0, $24
    STEP 0, $25
    STEP 0, $24
    STEP 0, $25
    STEP 2, $24
    STEP 2, $25
    STEP 4, $24
    STEP 4, $25
    STEP 4, $26
    STEP 4, $26
    STEP 4, $26
    STEP 0, $28
    STEP 0, $29
    STEP 0, $28
    STEP 0, $2A
    STEP 0, $28
    STEP 0, $29
    STEP 0, $28
    STEP 0, $2C

Song02_Ch2:
    STEP 0, $27
    STEP 0, $27
    STEP 3, $27
    STEP 7, $27
    STEP 0, $27
    STEP 0, $27
    STEP 0, $27
    STEP 0, $27
    STEP 3, $27
    STEP 7, $27
    STEP 0, $1C
    STEP 0, $1C
    STEP 0, $1C
    STEP 2, $1C
    STEP 2, $1C
    STEP 4, $1C
    STEP 4, $1C
    STEP 4, $1C
    STEP 4, $1C
    STEP 4, $1C
    STEP 0, $1C
    STEP 0, $1C
    STEP 0, $1C
    STEP 0, $1C
    STEP 0, $1C
    STEP 0, $1C
    STEP 0, $1C
    STEP 0, $2D

Song02_Ch4:
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 0, $1B
    STEP 0, $1A
    STEP 0, $1A
    STEP 0, $1A
    STEP 0, $1A
    STEP 0, $1A
    STEP 0, $1A
    STEP 0, $1A
    STEP 0, $1A
    STEP 0, $1A
    STEP 0, $1A
    STEP 0, $1B
    STEP 0, $1A
    STEP 0, $1A
    STEP 0, $1A
    STEP 0, $1A
    STEP 0, $1A
    STEP 0, $1A
    STEP 0, $2B

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

InstrumentTable:
    dw Ins00                    ; $00
    dw Ins01                    ; $01
    dw Ins02                    ; $02
    dw Ins02                    ; $03
    dw Ins02                    ; $04
    dw Ins02                    ; $05
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
    dw Ins00                    ; $10
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

Pat000:
    HOLD 16
    PATEND

Pat001:
    NOTE 1, G3, $01
    NOTE 1, G2, $01
    NOTE 1, G3, $01
    NOTE 1, G2, $01
    NOTE 1, C5, $02
    NOTE 1, F3, $01
    NOTE 1, G2, $01
    NOTE 1, G3, $01
    NOTE 1, G2, $01
    NOTE 1, G2, $01
    NOTE 1, G3, $01
    NOTE 1, G2, $01
    NOTE 1, C5, $02
    NOTE 1, F3, $01
    NOTE 1, G2, $01
    NOTE 1, C5, $02
    PATEND

Pat002:
    NOTE 1, G3, $01
    NOTE 1, G2, $01
    NOTE 1, G3, $01
    NOTE 1, G2, $01
    NOTE 1, C5, $02
    NOTE 1, F3, $01
    NOTE 1, G2, $01
    NOTE 1, G3, $01
    NOTE 1, C5, $02
    NOTE 1, C5, $02
    NOTE 1, C5, $02
    NOTE 1, G3, $01
    NOTE 1, C5, $02
    NOTE 1, C5, $02
    NOTE 1, C5, $02
    NOTE 1, F3, $01
    PATEND

Pat005:
    NOTE 1, D5, $06
    NOTE 2, D5, $06
    NOTE 2, D5, $06
    NOTE 2, D5, $06
    NOTE 2, D5, $06
    NOTE 2, D5, $06
    NOTE 1, D5, $06
    NOTE 1, D5, $06
    NOTE 1, D5, $06
    NOTE 2, D5, $07
    PATEND

Pat006:
    NOTE 1, D5, $06
    NOTE 2, D5, $06
    NOTE 2, D5, $06
    NOTE 2, D5, $06
    NOTE 2, D5, $06
    NOTE 2, D5, $06
    NOTE 1, D5, $06
    NOTE 1, D5, $06
    NOTE 1, D5, $06
    NOTE 2, D5, $08
    PATEND

Pat007:
    NOTE 1, D5, $06
    NOTE 2, D5, $06
    NOTE 2, D5, $06
    NOTE 2, D5, $06
    NOTE 1, D5, $06
    NOTE 1, D5, $07
    NOTE 1, D5, $07
    NOTE 2, D5, $07
    NOTE 4, D5, $08
    PATEND

Pat008:
    NOTE 1, D5, $06
    NOTE 1, D5, $06
    NOTE 1, G4, $09
    NOTE 1, D5, $06
    NOTE 1, A4, $09
    NOTE 2, D5, $06
    NOTE 2, As4, $09
    NOTE 1, D5, $06
    NOTE 1, C5, $09
    NOTE 1, D5, $06
    NOTE 1, A4, $09
    NOTE 2, As4, $09
    NOTE 1, D4, $09
    PATEND

Pat009:
    NOTE 1, D5, $06
    NOTE 1, D5, $06
    NOTE 1, G4, $09
    NOTE 1, D5, $06
    NOTE 1, A4, $09
    NOTE 2, D5, $06
    NOTE 2, As4, $09
    NOTE 1, D5, $06
    NOTE 1, C5, $09
    NOTE 1, D5, $06
    NOTE 1, A4, $09
    NOTE 2, As4, $09
    NOTE 1, D5, $09
    PATEND

Pat003:
    NOTE 1, C3, $00
    NOTE 1, C3, $02
    NOTE 1, C3, $02
    NOTE 1, C3, $02
    NOTE 2, C3, $01
    NOTE 1, C3, $02
    NOTE 1, C3, $00
    NOTE 1, C3, $02
    NOTE 1, C3, $02
    NOTE 1, C3, $00
    NOTE 1, C3, $02
    NOTE 2, C3, $01
    NOTE 1, C3, $02
    NOTE 1, C3, $01
    PATEND

Pat004:
    NOTE 1, C3, $00
    NOTE 1, C3, $02
    NOTE 1, C3, $02
    NOTE 1, C3, $02
    NOTE 1, C3, $01
    NOTE 1, C3, $02
    NOTE 1, C3, $00
    NOTE 1, C3, $00
    NOTE 1, C3, $01
    NOTE 1, C3, $01
    NOTE 1, C3, $01
    NOTE 1, C3, $02
    NOTE 1, C3, $01
    NOTE 1, C3, $01
    NOTE 1, C3, $01
    NOTE 1, C3, $01
    PATEND

Pat010:
    NOTE 1, $0C, $00
    NOTE 1, $0C, $02
    NOTE 1, $0C, $02
    NOTE 1, $0C, $02
    NOTE 1, $0C, $01
    NOTE 1, $0C, $02
    NOTE 1, $0C, $00
    NOTE 1, $0C, $00
    NOTE 1, $0C, $01
    NOTE 1, $0C, $01
    NOTE 1, $0C, $01
    NOTE 1, $0C, $02
    NOTE 1, $0C, $01
    NOTE 1, $0C, $01
    NOTE 1, $0C, $01
    NOTE 1, $0C, $01
    SONGJUMP Song00_Ch4_Loop

    ; $4CB9-$4CB9: 1 unreferenced byte
    db $00

Pat011:
    HOLD 16
    SONGJUMP Song00_Ch1

    ; $4CBF-$4CBF: 1 unreferenced byte
    db $00

Pat012:
    NOTE 1, C3, $02
    NOTE 1, C3, $02
    NOTE 1, C3, $02
    NOTE 1, C3, $02
    NOTE 2, C3, $02
    NOTE 1, C3, $02
    NOTE 1, C3, $02
    NOTE 1, C3, $02
    NOTE 1, C3, $02
    NOTE 2, C3, $02
    NOTE 1, C3, $02
    NOTE 1, C3, $02
    NOTE 2, C4, $02
    SONGJUMP Song00_Ch2

    ; $4CEA-$4CEA: 1 unreferenced byte
    db $00

Pat013:
    NOTE 1, C3, $02
    NOTE 1, C3, $02
    NOTE 1, C3, $02
    NOTE 1, C3, $02
    NOTE 2, C3, $02
    NOTE 1, C3, $02
    NOTE 1, C3, $02
    NOTE 1, C3, $02
    NOTE 1, C3, $02
    NOTE 2, C3, $02
    NOTE 1, C3, $02
    NOTE 1, C3, $02
    NOTE 2, C4, $02
    PATEND

Pat014:
    NOTE 1, C3, $10
    NOTE 1, C5, $0C
    NOTE 2, C3, $10
    NOTE 3, C5, $0A
    NOTE 1, C4, $10
    NOTE 1, C3, $10
    NOTE 1, C5, $0C
    NOTE 2, C3, $10
    NOTE 1, Ds3, $10
    NOTE 2, F3, $10
    NOTE 1, C4, $10
    PATEND

Pat015:
    NOTE 1, C3, $10
    NOTE 1, C5, $0C
    NOTE 2, C3, $10
    NOTE 3, C5, $0A
    NOTE 1, Ds3, $10
    NOTE 1, F3, $10
    NOTE 1, C5, $0C
    NOTE 2, Ds3, $10
    NOTE 1, F3, $10
    NOTE 1, Ds3, $10
    NOTE 1, C5, $02
    NOTE 1, C5, $02
    PATEND

Pat016:
    NOTE 1, C3, $10
    NOTE 1, C5, $0C
    NOTE 2, C3, $10
    NOTE 3, C5, $0A
    NOTE 1, C4, $10
    NOTE 1, As3, $10
    NOTE 1, As3, $10
    NOTE 1, A3, $10
    NOTE 1, F3, $10
    NOTE 1, Ds3, $10
    NOTE 1, Ds3, $10
    NOTE 1, E3, $10
    NOTE 1, F3, $10
    PATEND

Pat024:
    NOTE 1, C3, $10
    NOTE 1, C5, $0C
    NOTE 2, C3, $10
    NOTE 3, C5, $0A
    NOTE 1, C4, $10
    NOTE 1, As3, $10
    NOTE 1, As3, $10
    NOTE 1, A3, $10
    NOTE 1, F3, $10
    NOTE 1, Ds3, $10
    NOTE 1, Ds3, $10
    NOTE 1, E3, $10
    NOTE 1, F3, $10
    SONGJUMP Song01_Ch1

    ; $4DAC-$4DAC: 1 unreferenced byte
    db $00

Pat017:
    HOLD 8
    NOTE 1, As4, $10
    NOTE 1, As4, $10
    NOTE 1, A4, $10
    NOTE 1, F4, $10
    NOTE 1, Ds4, $10
    NOTE 1, Ds4, $10
    NOTE 1, E4, $10
    NOTE 1, F4, $10
    PATEND

Pat018:
    NOTE 1, C5, $0B
    NOTE 1, C5, $0B
    NOTE 1, C5, $0B
    NOTE 1, C5, $0B
    NOTE 1, As5, $0C
    NOTE 1, G5, $0C
    NOTE 1, G5, $0C
    NOTE 1, G5, $0C
    NOTE 1, As5, $0C
    NOTE 1, As5, $0C
    NOTE 1, As5, $0C
    NOTE 1, A5, $0C
    NOTE 1, A5, $0C
    NOTE 1, A5, $0C
    NOTE 1, F5, $0C
    NOTE 1, F5, $0C
    PATEND

Pat019:
    NOTE 1, C5, $0B
    NOTE 1, C5, $0B
    NOTE 1, C5, $0B
    NOTE 1, C5, $0B
    NOTE 1, As5, $0C
    NOTE 1, G5, $0C
    NOTE 1, G5, $0C
    NOTE 1, G5, $0C
    NOTE 1, As5, $0C
    NOTE 1, As5, $0C
    NOTE 1, As5, $0C
    NOTE 1, As5, $0C
    NOTE 1, C6, $0D
    NOTE 1, C6, $0D
    NOTE 1, C6, $0D
    NOTE 1, C6, $0D
    PATEND

Pat020:
    NOTE 1, C5, $0B
    NOTE 1, C5, $0B
    NOTE 1, C5, $0B
    NOTE 1, C5, $0B
    NOTE 1, As5, $0C
    NOTE 1, G5, $0C
    NOTE 2, G5, $0C
    NOTE 1, As5, $0C
    NOTE 1, As5, $0C
    NOTE 1, A5, $0C
    NOTE 1, F5, $0C
    NOTE 1, Ds5, $0C
    NOTE 1, Ds5, $0C
    NOTE 1, E5, $0C
    NOTE 1, F5, $0C
    PATEND

Pat025:
    NOTE 1, C5, $0B
    NOTE 1, C5, $0B
    NOTE 1, C5, $0B
    NOTE 1, C5, $0B
    NOTE 1, As5, $0C
    NOTE 1, G5, $0C
    NOTE 2, G5, $0C
    NOTE 1, As5, $0C
    NOTE 1, As5, $0C
    NOTE 1, A5, $0C
    NOTE 1, F5, $0C
    NOTE 1, Ds5, $0C
    NOTE 1, Ds5, $0C
    NOTE 1, E5, $0C
    NOTE 1, F5, $0C
    SONGJUMP Song01_Ch2

    ; $4E88-$4E88: 1 unreferenced byte
    db $00

Pat021:
    NOTE 1, G5, $0E
    NOTE 2, F5, $0F
    NOTE 1, G4, $02
    NOTE 2, G5, $0E
    NOTE 3, F5, $0F
    NOTE 7, G5, $0E
    PATEND

Pat022:
    NOTE 1, $24, $00
    NOTE 1, $24, $02
    NOTE 1, $24, $02
    NOTE 1, $24, $02
    NOTE 2, $24, $01
    NOTE 1, $24, $02
    NOTE 1, $24, $00
    NOTE 1, $24, $00
    NOTE 1, $24, $02
    NOTE 1, $24, $01
    NOTE 1, $24, $02
    NOTE 1, $24, $00
    NOTE 1, $24, $00
    NOTE 1, $24, $02
    NOTE 1, $24, $01
    PATEND

Pat023:
    NOTE 1, $24, $00
    NOTE 1, $24, $02
    NOTE 1, $24, $02
    NOTE 1, $24, $02
    NOTE 2, $24, $01
    NOTE 1, $24, $02
    NOTE 1, $24, $00
    NOTE 1, $24, $01
    NOTE 1, $24, $02
    NOTE 1, $24, $02
    NOTE 1, $24, $02
    NOTE 1, $24, $01
    NOTE 1, $24, $02
    NOTE 1, $24, $01
    NOTE 1, $24, $01
    SONGJUMP Song01_Ch4

    ; $4EFA-$4EFA: 1 unreferenced byte
    db $00

Pat044:
    NOTE 2, A2, $12
    NOTE 1, D4, $11
    HOLD 1
    NOTE 1, C3, $12
    NOTE 1, D3, $12
    HOLD 1
    NOTE 1, C3, $12
    NOTE 1, D3, $12
    HOLD 1
    NOTE 1, D4, $11
    HOLD 5
    SONGJUMP Song02_Ch1

    ; $4F1B-$4F1B: 1 unreferenced byte
    db $00

Pat028:
    NOTE 1, D2, $01
    NOTE 1, D3, $01
    NOTE 1, F3, $01
    NOTE 1, D2, $01
    NOTE 1, G3, $02
    NOTE 1, D2, $01
    NOTE 1, A3, $01
    NOTE 1, G3, $01
    NOTE 1, D2, $01
    NOTE 1, D3, $01
    NOTE 1, G3, $01
    NOTE 1, D3, $01
    NOTE 1, A3, $02
    NOTE 1, D2, $01
    NOTE 1, G3, $01
    NOTE 1, F3, $02
    PATEND

Pat045:
    NOTE 1, D2, $01
    NOTE 1, D3, $01
    NOTE 1, F3, $01
    NOTE 1, D2, $01
    NOTE 1, G3, $02
    NOTE 1, D2, $01
    NOTE 1, A3, $01
    NOTE 1, G3, $01
    NOTE 1, D2, $01
    NOTE 1, D3, $01
    NOTE 1, G3, $01
    NOTE 1, D3, $01
    NOTE 1, A3, $02
    NOTE 1, D2, $01
    NOTE 1, G3, $01
    NOTE 1, F3, $02
    SONGJUMP Song02_Ch2

    ; $4F80-$4F80: 1 unreferenced byte
    db $00

Pat039:
    NOTE 2, D2, $01
    NOTE 2, D3, $01
    NOTE 2, D2, $01
    NOTE 2, D3, $01
    NOTE 2, D2, $01
    NOTE 2, D3, $01
    NOTE 2, D2, $01
    NOTE 2, D3, $01
    PATEND

Pat030:
    NOTE 1, D4, $12
    NOTE 1, D4, $12
    NOTE 1, D4, $12
    HOLD 5
    NOTE 8, D3, $11
    PATEND

Pat029:
    NOTE 1, D4, $12
    NOTE 1, D4, $12
    NOTE 1, D4, $12
    HOLD 13
    PATEND

Pat031:
    NOTE 1, D4, $12
    NOTE 1, D4, $12
    NOTE 1, D4, $12
    HOLD 3
    NOTE 2, C3, $12
    NOTE 8, D3, $11
    PATEND

Pat032:
    NOTE 1, D4, $12
    NOTE 1, F3, $12
    NOTE 1, D4, $12
    HOLD 1
    NOTE 1, F3, $12
    NOTE 1, D3, $12
    NOTE 2, C3, $12
    NOTE 4, D3, $11
    NOTE 4, D4, $11
    PATEND

Pat033:
    NOTE 1, D4, $12
    NOTE 1, F3, $12
    NOTE 1, D4, $12
    HOLD 1
    NOTE 1, F3, $12
    NOTE 1, D3, $12
    NOTE 2, C3, $12
    NOTE 1, D4, $12
    NOTE 1, F3, $12
    NOTE 1, D4, $12
    HOLD 1
    NOTE 4, D4, $11
    PATEND

Pat034:
    NOTE 1, D4, $12
    NOTE 1, F3, $12
    NOTE 1, D4, $12
    HOLD 1
    NOTE 1, F3, $12
    NOTE 1, D3, $12
    NOTE 2, C3, $12
    NOTE 1, D4, $12
    NOTE 1, F3, $12
    NOTE 1, D4, $12
    HOLD 1
    NOTE 1, F3, $12
    NOTE 1, D3, $12
    NOTE 2, C3, $12
    PATEND

Pat035:
    NOTE 1, D4, $12
    NOTE 1, F3, $12
    NOTE 1, D4, $11
    HOLD 1
    NOTE 1, F3, $12
    NOTE 1, D3, $12
    NOTE 1, C3, $13
    HOLD 1
    NOTE 1, D4, $12
    NOTE 1, F3, $12
    NOTE 1, D4, $11
    HOLD 1
    NOTE 1, F3, $12
    NOTE 1, D3, $12
    NOTE 1, C3, $13
    HOLD 1
    PATEND

Pat036:
    NOTE 1, D4, $11
    NOTE 1, G4, $12
    NOTE 1, D4, $11
    HOLD 1
    NOTE 2, F4, $12
    NOTE 2, C4, $13
    HOLD 1
    NOTE 1, A3, $12
    NOTE 1, D4, $11
    HOLD 1
    NOTE 4, A3, $12
    PATEND

Pat037:
    NOTE 1, D4, $11
    NOTE 1, C4, $12
    NOTE 1, D4, $11
    HOLD 1
    NOTE 2, G3, $12
    NOTE 2, C4, $13
    HOLD 1
    NOTE 1, D4, $12
    NOTE 1, D4, $11
    HOLD 1
    NOTE 4, D4, $12
    PATEND

Pat038:
    NOTE 2, D4, $11
    NOTE 1, D4, $11
    HOLD 7
    NOTE 1, D4, $11
    HOLD 5
    PATEND

Pat040:
    NOTE 2, A3, $12
    NOTE 1, D3, $12
    HOLD 1
    NOTE 1, F3, $12
    NOTE 1, G3, $12
    HOLD 1
    NOTE 1, As3, $12
    NOTE 1, A3, $12
    HOLD 1
    NOTE 1, D3, $12
    HOLD 2
    NOTE 1, E3, $12
    NOTE 1, D3, $12
    NOTE 1, C3, $12
    PATEND

Pat041:
    NOTE 2, D3, $12
    NOTE 1, D4, $11
    HOLD 1
    NOTE 1, F3, $12
    NOTE 1, G3, $12
    HOLD 1
    NOTE 1, As3, $12
    NOTE 1, A3, $12
    HOLD 1
    NOTE 1, D4, $11
    HOLD 5
    PATEND

Pat042:
    NOTE 2, A2, $12
    NOTE 1, D4, $11
    HOLD 1
    NOTE 1, C3, $12
    NOTE 1, D3, $12
    HOLD 1
    NOTE 1, C3, $12
    NOTE 1, D3, $12
    HOLD 1
    NOTE 1, D4, $11
    HOLD 5
    PATEND

Pat027:
    NOTE 2, $0C, $00
    NOTE 1, $0C, $02
    NOTE 1, $0C, $00
    NOTE 2, $0C, $01
    NOTE 1, $0C, $02
    NOTE 1, $0C, $02
    NOTE 2, $0C, $01
    NOTE 1, $0C, $01
    NOTE 1, $0C, $02
    NOTE 1, $0C, $01
    NOTE 1, $0C, $01
    NOTE 1, $0C, $01
    NOTE 1, $0C, $01
    PATEND

Pat043:
    NOTE 2, $0C, $00
    NOTE 1, $0C, $02
    NOTE 1, $0C, $02
    NOTE 1, $0C, $01
    NOTE 1, $0C, $02
    NOTE 1, $0C, $02
    NOTE 1, $0C, $01
    NOTE 2, $0C, $00
    NOTE 1, $0C, $02
    NOTE 1, $0C, $02
    NOTE 1, $0C, $01
    NOTE 1, $0C, $02
    NOTE 1, $0C, $02
    NOTE 1, $0C, $02
    SONGJUMP Song02_Ch4

    ; $515F-$515F: 1 unreferenced byte
    db $00

Pat026:
    NOTE 2, $0C, $00
    NOTE 1, $0C, $02
    NOTE 1, $0C, $02
    NOTE 1, $0C, $01
    NOTE 1, $0C, $02
    NOTE 1, $0C, $02
    NOTE 1, $0C, $01
    NOTE 2, $0C, $00
    NOTE 1, $0C, $02
    NOTE 1, $0C, $02
    NOTE 1, $0C, $01
    NOTE 1, $0C, $02
    NOTE 1, $0C, $02
    NOTE 1, $0C, $02
    PATEND

Comb_518B:
    TB 200, $02 ; note + freq table
    TLOOP Comb_518B

Arp_5190:
    TLOOP $00C8

    ; $5193-$5194: 2 unreferenced bytes
    db $90, $51

Freq_5195:
    TW 200, 0
    TLOOP Freq_5195

Ins00:
    INS_TONE $C0, $C1, $F1, Arp_51A4, Freq_5195, Comb_518B ; $00, $10

Arp_51A4:
    TB 1, $00 ; +0

Arp_51A4_L0:
    TB 240, $F4 ; -12
    TLOOP Arp_51A4_L0

Ins01:
    INS_TONE $C0, $C1, $F1, Arp_51BB, Freq_51C2, Comb_51B4 ; $01

Comb_51B4:
    TB 1, $00 ; freq table only

Comb_51B4_L0:
    TB 200, $01 ; note only
    TLOOP Comb_51B4_L0

Arp_51BB:
    TB 1, $00 ; +0

Arp_51BB_L0:
    TB 200, $00 ; +0
    TLOOP Arp_51BB_L0

Freq_51C2:
    TW 1, 7905
    TW 255, 0

Freq_51C2_L0:
    TW 50, 50
    TLOOP Freq_51C2_L0

Freq_51CE:
    TW 1, 1
    TW 1, -1
    TW 1, -1
    TW 1, 1
    TLOOP Freq_51CE

Ins06:
    INS_TONE $80, $C1, $F1, Arp_51E6, Freq_51CE, Comb_518B ; $06

Arp_51E6:
    TB 1, $F4 ; -12
    TB 1, $F9 ; -7
    TB 1, $FC ; -4
    TLOOP Arp_51E6

Ins07:
    INS_TONE $80, $C1, $F1, Arp_51F8, Freq_51CE, Comb_518B ; $07

Arp_51F8:
    TB 1, $F4 ; -12
    TB 1, $F8 ; -8
    TB 1, $FE ; -2
    TLOOP Arp_51F8

Ins11:
    INS_TONE $C0, $71, $F1, Arp_520A, Freq_5195, Comb_518B ; $0B

Arp_520A:
    TB 1, $FB ; -5
    TB 1, $F7 ; -9
    TB 1, $F4 ; -12
    TLOOP Arp_520A

Ins12:
    INS_TONE $C0, $71, $F1, Arp_52A3, Freq_5195, Comb_518B ; $0C

Ins13:
    INS_TONE $C0, $71, $F1, Arp_5225, Freq_5195, Comb_518B ; $0D

Arp_5225:
    TB 1, $F4 ; -12
    TB 1, $F9 ; -7
    TB 1, $FD ; -3
    TLOOP Arp_5225

Ins14:
    INS_TONE $40, $C4, $F1, Arp_5237, Freq_5195, Comb_518B ; $0E

Arp_5237:
    TB 1, $0C ; +12
    TB 1, $07 ; +7
    TB 1, $03 ; +3
    TB 1, $00 ; +0
    TB 1, $FB ; -5
    TB 1, $F7 ; -9
    TB 1, $F4 ; -12
    TLOOP Arp_5237

Ins15:
    INS_TONE $40, $C4, $F1, Arp_5251, Freq_5195, Comb_518B ; $0F

Arp_5251:
    TB 1, $0C ; +12
    TB 1, $07 ; +7
    TB 1, $04 ; +4
    TB 1, $00 ; +0
    TB 1, $FB ; -5
    TB 1, $F8 ; -8
    TB 1, $F4 ; -12
    TLOOP Arp_5251

Ins08:
    INS_TONE $80, $C8, $F1, Arp_526B, Freq_51CE, Comb_518B ; $08

Arp_526B:
    TB 1, $F4 ; -12
    TB 1, $F8 ; -8
    TB 1, $FB ; -5
    TLOOP Arp_526B

Ins02:
    INS_TONE $80, $D1, $F1, Arp_5190, Freq_527D, Comb_5286 ; $02, $03, $04, $05

Freq_527D:
    TW 1, 1500
    TW 10, -80
    TLOOP Freq_527D

Comb_5286:
    TB 200, $00 ; freq table only
    TLOOP Comb_5286

Ins10:
    INS_TONE $80, $D2, $F1, Arp_5190, Freq_5294, Comb_518B ; $0A

Freq_5294:
    TW 50, -70
    TLOOP Freq_5294

Ins09:
    INS_TONE $00, $E3, $F1, Arp_52A3, Freq_52AA, Comb_518B ; $09

Arp_52A3:
    TB 1, $F4 ; -12
    TB 1, $00 ; +0
    TLOOP Arp_52A3

Freq_52AA:
    TW 2, 3
    TW 2, -3
    TW 2, -3
    TW 2, 3
    TLOOP Freq_52AA

NoiseIns00:
    INS_NOISE $00, $A1, $F1, Noise_52C0, NoiseCtl_52E7 ; $00

Noise_52C0:
    TB 1, $00

Noise_52C0_L0:
    TB 2, $73
    TB 2, $63
    TLOOP Noise_52C0_L0

NoiseIns01:
    INS_NOISE $00, $72, $F1, Noise_52D0, NoiseCtl_52E7 ; $01

Noise_52D0:
    TB 1, $00
    TB 50, $42
    TLOOP Noise_52D0

NoiseIns02:
    INS_NOISE $00, $81, $F1, Noise_52DE, NoiseCtl_52E7 ; $02

Noise_52DE:
    TB 1, $00
    TB 1, $00
    TB 1, $20
    TLOOP Noise_52DE

NoiseCtl_52E7:
    TB 100, $00
    TLOOP NoiseCtl_52E7

Ins17:
    INS_TONE $80, $C1, $F1, Arp_52F5, Freq_51CE, Comb_518B ; $11

Arp_52F5:
    TB 1, $00 ; +0
    TB 1, $03 ; +3
    TB 1, $07 ; +7
    TB 1, $0C ; +12
    TB 1, $18 ; +24
    TLOOP Arp_52F5

Ins18:
    INS_TONE $80, $C1, $F1, Arp_530B, Freq_51CE, Comb_518B ; $12

Arp_530B:
    TB 1, $00 ; +0
    TB 1, $0C ; +12
    TB 1, $18 ; +24
    TB 1, $0C ; +12
    TLOOP Arp_530B

Ins19:
    INS_TONE $80, $C8, $F1, Arp_531F, Freq_51CE, Comb_518B ; $13

Arp_531F:
    TB 1, $00 ; +0
    TB 1, $04 ; +4
    TB 1, $07 ; +7
    TB 1, $0C ; +12
    TLOOP Arp_531F

; ---------------------------------------------------------------------------
; Engine drone: load a sawtooth into wave RAM and start ch3.
EngineOn::
    ld a, $00
    ldh [rNR30], a
    ld hl, EngineWave
    ld de, _AUD3WAVERAM

EngineOn_CopyWave:
    ld a, [hli]
    ld [de], a
    inc e
    ld a, e
    cp a, $40
    jr nz, EngineOn_CopyWave
    ld a, $FF
    ldh [rNR52], a
    ld a, $80
    ldh [rNR30], a
    ld a, $10
    ldh [rNR31], a
    ld a, $20
    ldh [rNR32], a
    ld a, $80
    ldh [rNR34], a
    ret

; ---------------------------------------------------------------------------
; Stop ch3.
EngineOff::
    ld a, $00
    ldh [rNR30], a
    ret

; ---------------------------------------------------------------------------
; DE -> freqval3 (added to the ch3 note by combine mode 2).
EnginePitch::
    ld d, $00
    ld hl, EnginePitchTable
    add hl, de
    add hl, de
    ld a, [hli]
    ldh [rNR33], a
    ld a, [hl]
    and a, $07
    ldh [rNR34], a
    ld a, $10
    ldh [rNR31], a
    ret

EngineWave:
    db $00, $11, $22, $33, $44, $55, $66, $77, $88, $99, $AA, $BB, $CC, $DD, $EE, $FF

EnginePitchTable:
    dw $0420, $042B, $0436, $0441, $044C, $0457, $0462, $046D
    dw $0478, $0483, $048E, $0499, $04A4, $04AF, $04BA, $04C5
    dw $04D0, $04DB, $04E6, $04F1, $04FC, $0507, $0512, $051D
    dw $0528, $0533, $053E, $0549, $0554, $055F, $056A, $0575
    dw $0580, $058B, $0596, $05A1, $05AC, $05B7, $05C2, $05CD
    dw $05D8, $05E3, $05EE, $05F9, $0604, $060F, $061A, $0625
    dw $0630, $063B, $0646, $0651, $065C, $0667, $0672, $067D
    dw $0688, $0693, $069E, $06A9, $06B4, $06BF, $06CA, $06D5
