; Colin McRae Rally (E) (GBC) - music/SFX data $47BA-$57AD

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
    db 3 ; ch4  (SFX $00)
    db 127 ; priority
    dw Sfx01
    db 3 ; ch4  (SFX $01)
    db 127 ; priority
    dw Sfx02
    db 3 ; ch4  (SFX $02)
    db 127 ; priority
    dw Sfx03
    db 2 ; ch2  (SFX $03)

Sfx03:
    NOTE 30, C5, $33
    SFXEND

SongTable:
    db 1, %1111 ; tempo, channel mask
    dw Song00_Ch1, Song00_Ch2, Song00_Ch3, Song00_Ch4
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db 1, %0100 ; tempo, channel mask
    dw Song01_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song00_Ch2
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0001 ; tempo, channel mask
    dw Song03_Ch1
    db $35, $56, $11, $56, $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0001 ; tempo, channel mask
    dw Song04_Ch1
    db $35, $56, $11, $56, $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0001 ; tempo, channel mask
    dw Song00_Ch1
    db $35, $56, $11, $56, $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song06_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song07_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %1010 ; tempo, channel mask
    dw Song08_Ch2, Song08_Ch4
    db $35, $56, $11, $56, $00, $00, $00, $00 ; (unused)
    db 1, %1010 ; tempo, channel mask
    dw Song09_Ch2, Song09_Ch4
    db $35, $56, $11, $56, $00, $00, $00, $00 ; (unused)
    db 1, %1000 ; tempo, channel mask
    dw Song10_Ch4
    db $35, $56, $11, $56, $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %1000 ; tempo, channel mask
    dw Song11_Ch4
    db $35, $56, $11, $56, $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %1000 ; tempo, channel mask
    dw Song12_Ch4
    db $35, $56, $11, $56, $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %1000 ; tempo, channel mask
    dw Song00_Ch4
    db $35, $56, $11, $56, $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0010 ; tempo, channel mask
    dw Song14_Ch2
    db $35, $56, $11, $56, $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song15_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song16_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song17_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song18_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song19_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song20_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song21_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song22_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song23_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song24_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song25_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song26_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song27_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 2, %0100 ; tempo, channel mask
    dw Song28_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 7, %1111 ; tempo, channel mask
    dw Song29_Ch1, Song29_Ch2, Song29_Ch3, Song29_Ch4
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db 1, %0100 ; tempo, channel mask
    dw Song30_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song31_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song32_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song33_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song34_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song35_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song36_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song37_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song38_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song39_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song40_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song41_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song42_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song43_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song01_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
    db $00, $00, $00, $00, $00, $00 ; (unused)
    db 1, %0100 ; tempo, channel mask
    dw Song43_Ch3
    dw Morph_5637 - 2, Wave_5611 ; wave morph, wave (not read by this driver)
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
    dw Ins00                    ; $0C
    dw Ins00                    ; $0D
    dw Ins00                    ; $0E
    dw Ins00                    ; $0F
    dw $0000                    ; $10
    dw $0000                    ; $11
    dw $0000                    ; $12
    dw $0000                    ; $13
    dw $0000                    ; $14
    dw $0000                    ; $15
    dw $0000                    ; $16
    dw $0000                    ; $17
    dw $0000                    ; $18
    dw $0000                    ; $19
    dw $0000                    ; $1A
    dw $0000                    ; $1B
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
    dw Ins00                    ; $2D
    dw Ins46                    ; $2E
    dw Ins47                    ; $2F
    dw Ins48                    ; $30
    dw Ins49                    ; $31
    dw Ins50                    ; $32
    dw Ins51                    ; $33

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

Song29_Ch1:
    STEP 0, $1E
    STEP 0, $00
    STEP 0, $1E
    STEP 0, $00
    STEP 0, $1E
    STEP 0, $00
    STEP 0, $1E
    STEP 0, $00
    STEP 0, $24
    STEP 0, $00
    STEP 0, $24
    STEP 0, $00
    STEP 0, $24
    STEP 0, $00
    STEP 0, $24
    STEP 0, $26

Song29_Ch2:
    STEP 0, $1F
    STEP 0, $1F
    STEP 0, $1F
    STEP 0, $00
    STEP 0, $25
    STEP 0, $23
    STEP 0, $23
    STEP 0, $23
    STEP 0, $27

Song29_Ch3:
    STEP 0, $1C
    STEP 0, $21
    STEP 0, $1C
    STEP 0, $22

Song29_Ch4:
    STEP 0, $1D

Pat038:
    NOTE 1, C6, $0B
    KEYON 1
    KEYON 1
    KEYON 1
    KEYON 1
    KEYON 1
    KEYON 1
    KEYON 1
    KEYON 1
    KEYON 1
    KEYON 1
    KEYON 1
    KEYON 1
    KEYON 1
    KEYON 1
    KEYON 1
    SONGJUMP Song29_Ch1

Pat037:
    HOLD 12
    NOTE 1, C6, $0B
    NOTE 1, C6, $0B
    NOTE 1, C6, $0B
    NOTE 1, C6, $0B
    PATEND

Pat028:
    NOTE 2, $24, $10 ; PCM sample $10
    NOTE 1, $24, $11 ; PCM sample $11
    NOTE 1, $24, $12 ; PCM sample $12
    NOTE 2, $24, $13 ; PCM sample $13
    NOTE 1, $24, $14 ; PCM sample $14
    NOTE 1, $24, $18 ; PCM sample $18
    NOTE 1, $24, $19 ; PCM sample $19
    NOTE 1, $24, $1A ; PCM sample $1A
    NOTE 2, $24, $10 ; PCM sample $10
    NOTE 2, $24, $13 ; PCM sample $13
    NOTE 1, $23, $17 ; PCM sample $17
    NOTE 1, $24, $11 ; PCM sample $11
    NOTE 2, $23, $10 ; PCM sample $10
    NOTE 1, $23, $11 ; PCM sample $11
    NOTE 1, $23, $12 ; PCM sample $12
    NOTE 2, $23, $13 ; PCM sample $13
    NOTE 2, $23, $10 ; PCM sample $10
    NOTE 1, $23, $11 ; PCM sample $11
    NOTE 1, $23, $12 ; PCM sample $12
    NOTE 2, $23, $13 ; PCM sample $13
    NOTE 1, $23, $15 ; PCM sample $15
    NOTE 1, $23, $16 ; PCM sample $16
    NOTE 1, $23, $17 ; PCM sample $17
    NOTE 1, $23, $18 ; PCM sample $18
    NOTE 2, $23, $10 ; PCM sample $10
    NOTE 1, $23, $11 ; PCM sample $11
    NOTE 1, $23, $12 ; PCM sample $12
    NOTE 2, $23, $13 ; PCM sample $13
    NOTE 1, $23, $14 ; PCM sample $14
    NOTE 1, $23, $18 ; PCM sample $18
    NOTE 1, $23, $19 ; PCM sample $19
    NOTE 1, $23, $1A ; PCM sample $1A
    NOTE 2, $23, $10 ; PCM sample $10
    NOTE 2, $23, $13 ; PCM sample $13
    NOTE 1, $23, $17 ; PCM sample $17
    NOTE 1, $23, $11 ; PCM sample $11
    PATEND

Pat033:
    NOTE 2, $23, $10 ; PCM sample $10
    NOTE 1, $23, $11 ; PCM sample $11
    NOTE 1, $23, $12 ; PCM sample $12
    NOTE 2, $23, $13 ; PCM sample $13
    NOTE 2, $23, $10 ; PCM sample $10
    NOTE 1, $23, $17 ; PCM sample $17
    NOTE 1, $23, $1A ; PCM sample $1A
    NOTE 1, $23, $17 ; PCM sample $17
    NOTE 1, $23, $1A ; PCM sample $1A
    NOTE 1, $23, $17 ; PCM sample $17
    NOTE 1, $23, $1A ; PCM sample $1A
    NOTE 1, $23, $17 ; PCM sample $17
    NOTE 1, $23, $1A ; PCM sample $1A
    PATEND

Pat034:
    NOTE 1, $23, $13 ; PCM sample $13
    NOTE 1, $23, $13 ; PCM sample $13
    NOTE 1, $23, $13 ; PCM sample $13
    NOTE 1, $23, $13 ; PCM sample $13
    NOTE 1, $23, $13 ; PCM sample $13
    NOTE 1, $23, $13 ; PCM sample $13
    NOTE 1, $23, $13 ; PCM sample $13
    NOTE 1, $23, $13 ; PCM sample $13
    NOTE 1, $23, $13 ; PCM sample $13
    NOTE 1, $23, $13 ; PCM sample $13
    NOTE 1, $23, $13 ; PCM sample $13
    NOTE 1, $23, $13 ; PCM sample $13
    NOTE 2, $23, $13 ; PCM sample $13
    NOTE 1, $23, $13 ; PCM sample $13
    NOTE 1, $23, $13 ; PCM sample $13
    SONGJUMP Song29_Ch3

Pat029:
    NOTE 1, $18, $02
    NOTE 1, $18, $03
    NOTE 1, $18, $03
    NOTE 1, $18, $03
    NOTE 2, $18, $01
    NOTE 1, $18, $03
    NOTE 1, $18, $03
    NOTE 1, $18, $03
    NOTE 1, $18, $03
    NOTE 1, $18, $02
    NOTE 1, $18, $02
    NOTE 2, $18, $01
    NOTE 1, $18, $03
    NOTE 1, $18, $03
    SONGJUMP Song29_Ch4

Pat030:
    NOTE 4, E2, $04
    KEYOFF 12
    PATEND

Pat036:
    NOTE 4, E2, $04
    NOTE 12, E4, $0A
    PATEND

Pat031:
    NOTE 1, E3, $06
    KEYOFF 1
    NOTE 1, E3, $06
    KEYOFF 1
    NOTE 2, E3, $07
    NOTE 1, E2, $06
    NOTE 2, E2, $07
    NOTE 1, E2, $06
    NOTE 2, E2, $07
    NOTE 1, E2, $06
    NOTE 1, E2, $06
    NOTE 1, E3, $06
    NOTE 1, E2, $06
    NOTE 1, E3, $07
    KEYOFF 1
    NOTE 1, E2, $06
    KEYOFF 1
    NOTE 1, E2, $06
    KEYOFF 1
    NOTE 1, E2, $06
    NOTE 2, E2, $07
    NOTE 1, E2, $06
    NOTE 1, E2, $07
    NOTE 1, E2, $06
    NOTE 1, E2, $06
    NOTE 1, E2, $06
    NOTE 1, F2, $06
    NOTE 1, F3, $06
    PATEND

Pat032:
    NOTE 4, E2, $04
    NOTE 2, E3, $07
    NOTE 1, E2, $06
    NOTE 2, E2, $07
    NOTE 1, E2, $06
    NOTE 2, E2, $07
    NOTE 1, E2, $06
    NOTE 1, E2, $06
    NOTE 1, E3, $06
    NOTE 1, E2, $06
    NOTE 1, E3, $07
    KEYOFF 1
    NOTE 1, E2, $06
    KEYOFF 1
    NOTE 1, E2, $06
    KEYOFF 1
    NOTE 1, E2, $06
    NOTE 2, E2, $07
    NOTE 1, E2, $06
    NOTE 1, E2, $07
    NOTE 1, E2, $06
    NOTE 1, E2, $06
    NOTE 1, E2, $06
    NOTE 1, F2, $06
    NOTE 1, F3, $06
    PATEND

Pat035:
    NOTE 1, E3, $08
    NOTE 1, E3, $09
    NOTE 1, E4, $08
    NOTE 1, E3, $09
    NOTE 1, E3, $08
    NOTE 1, E4, $09
    NOTE 1, E3, $08
    NOTE 1, E4, $08
    NOTE 1, E4, $09
    NOTE 1, E3, $08
    NOTE 1, E3, $08
    NOTE 1, E4, $09
    NOTE 1, E3, $08
    NOTE 1, E3, $09
    NOTE 1, F3, $08
    NOTE 1, E3, $09
    NOTE 1, E3, $08
    NOTE 1, F3, $09
    NOTE 1, E4, $08
    NOTE 1, E3, $09
    NOTE 1, E3, $08
    NOTE 1, E4, $08
    NOTE 1, E3, $09
    NOTE 1, E3, $08
    NOTE 1, E4, $09
    NOTE 1, E4, $08
    NOTE 1, E4, $08
    NOTE 1, E3, $08
    NOTE 1, E3, $08
    NOTE 1, E4, $09
    NOTE 1, F3, $08
    NOTE 1, F3, $09
    PATEND

Pat039:
    NOTE 1, E3, $08
    NOTE 1, E3, $09
    NOTE 1, E4, $08
    NOTE 1, E3, $09
    NOTE 1, E3, $08
    NOTE 1, E4, $09
    NOTE 1, E3, $08
    NOTE 1, E4, $08
    NOTE 1, E4, $09
    NOTE 1, E3, $08
    NOTE 1, E3, $08
    NOTE 1, E4, $09
    NOTE 1, E3, $08
    NOTE 1, E3, $09
    NOTE 1, F3, $08
    NOTE 1, E3, $09
    NOTE 1, E3, $08
    NOTE 1, F3, $09
    NOTE 1, E4, $08
    NOTE 1, E3, $09
    NOTE 1, E3, $08
    NOTE 1, E4, $08
    NOTE 1, E3, $09
    NOTE 1, E3, $08
    NOTE 1, E4, $09
    NOTE 1, E4, $08
    NOTE 1, E4, $08
    NOTE 1, E3, $08
    NOTE 1, E3, $08
    NOTE 1, E4, $09
    NOTE 1, F3, $08
    NOTE 1, F3, $09
    SONGJUMP Song29_Ch2

Pat000:
    HOLD 16
    PATEND

Pat001:
    NOTE 16, C2, $00
    SONGJUMP Song00_Ch1_Loop

Pat002:
    NOTE 16, $00, $00 ; PCM sample $00
    SONGJUMP Song00_Ch1_Loop

Pat003:
    NOTE 16, $00, $00
    SONGJUMP Song00_Ch1_Loop

Pat004:
    HOLD 16
    SONGJUMP Song00_Ch1_Loop

Song01_Ch3:
    STEP 0, $05
    STEP 0, $04

Pat005:
    NOTE 60, $24, $01 ; PCM sample $01
    PATEND

Song03_Ch1:
    STEP 0, $06
    STEP 0, $04

Pat006:
    NOTE 255, C2, $2E
    PATEND

Ins46:
    INS_TONE $40, $C8, $21, Arp_4EE0, Freq_5158, Comb_514E ; $2E

Arp_4EE0:
    TB 1, $00 ; +0
    TB 2, $05 ; +5
    TB 1, $00 ; +0
    TB 2, $05 ; +5
    TB 1, $00 ; +0
    TB 1, $05 ; +5
    TB 1, $00 ; +0
    TB 3, $05 ; +5
    TLOOP Arp_4EE0

Song04_Ch1:
    STEP 0, $07
    STEP 0, $04

Pat007:
    NOTE 255, C2, $2F
    PATEND

Ins47:
    INS_TONE $40, $C8, $21, Arp_4F04, Freq_5158, Comb_514E ; $2F

Arp_4F04:
    TB 1, $06 ; +6
    TB 1, $05 ; +5
    TB 1, $02 ; +2
    TB 1, $01 ; +1
    TB 1, $00 ; +0
    TB 1, $05 ; +5
    TB 1, $04 ; +4
    TB 1, $02 ; +2
    TB 1, $01 ; +1
    TB 2, $00 ; +0
    TLOOP Arp_4F04

Song06_Ch3:
    STEP 0, $08
    STEP 0, $04

Pat008:
    NOTE 1, $24, $02 ; PCM sample $02
    PATEND

Song07_Ch3:
    STEP 0, $09
    STEP 0, $04

Pat009:
    NOTE 1, $24, $03 ; PCM sample $03
    PATEND

Song08_Ch2:
    STEP 0, $0A
    STEP 0, $04

Pat010:
    NOTE 10, C5, $30
    PATEND

Ins48:
    INS_TONE $80, $D1, $21, Arp_4F3C, Freq_4F4F, Comb_514E ; $30

Arp_4F3C:
    TB 1, $00 ; +0
    TB 1, $01 ; +1
    TB 1, $00 ; +0
    TB 1, $01 ; +1
    TB 2, $00 ; +0
    TB 1, $01 ; +1
    TB 1, $00 ; +0
    TB 2, $01 ; +1
    TLOOP Arp_4F3C

Freq_4F4F:
    TW 255, -60
    TLOOP Freq_4F4F

Song08_Ch4:
    STEP 0, $0B
    STEP 0, $04

Pat011:
    NOTE 10, $24, $07
    PATEND

NoiseIns07:
    INS_NOISE $80, $62, $01, Noise_4F64, Arp_5153 ; $07

Noise_4F64:
    TB 2, $45
    TB 2, $44
    TB 2, $43
    TLOOP Noise_4F64

Song09_Ch2:
    STEP 0, $0C
    STEP 0, $04

Pat012:
    NOTE 10, G4, $31
    PATEND

Ins49:
    INS_TONE $80, $84, $21, Arp_4F3C, Freq_4F7E, Comb_514E ; $31

Freq_4F7E:
    TW 255, -50
    TLOOP Freq_4F4F

Song09_Ch4:
    STEP 0, $0D
    STEP 0, $04

Pat013:
    NOTE 10, $24, $08
    PATEND

NoiseIns08:
    INS_NOISE $80, $C2, $01, Noise_4F93, Arp_5153 ; $08

Noise_4F93:
    TB 2, $45
    TB 2, $44
    TB 2, $43
    TLOOP Noise_4F93

Song10_Ch4:
    STEP 0, $0E
    STEP 0, $04

Pat014:
    NOTE 255, $24, $09
    PATEND

NoiseIns09:
    INS_NOISE $80, $78, $01, Noise_4FAB, Arp_5153 ; $09

Noise_4FAB:
    TB 2, $54
    TB 2, $53
    TB 2, $52
    TLOOP Noise_4FAB

Song11_Ch4:
    STEP 0, $0F
    STEP 0, $04

Pat015:
    NOTE 255, $24, $0A
    PATEND

NoiseIns10:
    INS_NOISE $80, $58, $01, Noise_4FC3, Arp_5153 ; $0A

Noise_4FC3:
    TB 2, $45
    TB 2, $44
    TB 2, $43
    TLOOP Noise_4FC3

Song12_Ch4:
    STEP 0, $10
    STEP 0, $04

Pat016:
    NOTE 255, $24, $0B
    PATEND

NoiseIns11:
    INS_NOISE $80, $58, $01, Noise_4FDB, Arp_5153 ; $0B

Noise_4FDB:
    TB 2, $34
    TB 2, $33
    TB 2, $32
    TLOOP Noise_4FDB

Song14_Ch2:
    STEP 0, $11
    STEP 0, $04

Pat017:
    NOTE 30, C6, $32
    PATEND

Ins50:
    INS_TONE $60, $F1, $21, Arp_4FF5, Freq_5158, Comb_5149 ; $32

Arp_4FF5:
    TB 3, $07 ; +7
    TB 9, $00 ; +0
    TLOOP Arp_4FF5

Song30_Ch3:
    STEP 0, $2C
    STEP 0, $32
    STEP 0, $04

Song31_Ch3:
    STEP 0, $2D
    STEP 0, $32
    STEP 0, $04

Song32_Ch3:
    STEP 0, $2E
    STEP 0, $32
    STEP 0, $04

Song33_Ch3:
    STEP 0, $2F
    STEP 0, $32
    STEP 0, $04

Song34_Ch3:
    STEP 0, $30
    STEP 0, $32
    STEP 0, $04

Song35_Ch3:
    STEP 0, $2C
    STEP 0, $31
    STEP 0, $04

Song36_Ch3:
    STEP 0, $2D
    STEP 0, $31
    STEP 0, $04

Song37_Ch3:
    STEP 0, $2E
    STEP 0, $31
    STEP 0, $04

Song38_Ch3:
    STEP 0, $2F
    STEP 0, $31
    STEP 0, $04

Song39_Ch3:
    STEP 0, $30
    STEP 0, $31
    STEP 0, $04

Song40_Ch3:
    STEP 0, $33
    STEP 0, $31
    STEP 0, $04

Song41_Ch3:
    STEP 0, $33
    STEP 0, $32
    STEP 0, $04

Song42_Ch3:
    STEP 0, $34
    STEP 0, $31
    STEP 0, $04

Song43_Ch3:
    STEP 0, $34
    STEP 0, $32
    STEP 0, $04

Pat044:
    NOTE 16, $24, $09 ; PCM sample $09
    PATEND

Pat045:
    NOTE 14, $24, $0A ; PCM sample $0A
    PATEND

Pat046:
    NOTE 25, $24, $0B ; PCM sample $0B
    PATEND

Pat047:
    NOTE 21, $24, $0C ; PCM sample $0C
    PATEND

Pat048:
    NOTE 31, $24, $0D ; PCM sample $0D
    PATEND

Pat049:
    NOTE 27, $24, $05 ; PCM sample $05
    PATEND

Pat050:
    NOTE 28, $24, $06 ; PCM sample $06
    PATEND

Pat051:
    NOTE 27, $24, $1B ; PCM sample $1B
    PATEND

Pat052:
    NOTE 26, $24, $08 ; PCM sample $08
    PATEND

Song15_Ch3:
    STEP 0, $12
    STEP 0, $04

Song16_Ch3:
    STEP 0, $13
    STEP 0, $04

Song17_Ch3:
    STEP 0, $14
    STEP 0, $04

Song18_Ch3:
    STEP 0, $15
    STEP 0, $04

Song19_Ch3:
    STEP 0, $16
    STEP 0, $04

Song20_Ch3:
    STEP 0, $17
    STEP 0, $04

Song21_Ch3:
    STEP 0, $18
    STEP 0, $04

Song22_Ch3:
    STEP 0, $19
    STEP 0, $04

Song23_Ch3:
    STEP 0, $1A
    STEP 0, $04

Song24_Ch3:
    STEP 0, $1B
    STEP 0, $04

Song25_Ch3:
    STEP 0, $28
    STEP 0, $04

Song26_Ch3:
    STEP 0, $29
    STEP 0, $04

Song27_Ch3:
    STEP 0, $2A
    STEP 0, $04

Song28_Ch3:
    STEP 0, $2B
    STEP 0, $04

Pat018:
    NOTE 1, $24, $04 ; PCM sample $04
    PATEND

Pat019:
    NOTE 1, $24, $05 ; PCM sample $05
    PATEND

Pat020:
    NOTE 1, $24, $06 ; PCM sample $06
    PATEND

Pat021:
    NOTE 1, $24, $07 ; PCM sample $07
    PATEND

Pat022:
    NOTE 1, $24, $08 ; PCM sample $08
    PATEND

Pat023:
    NOTE 1, $24, $09 ; PCM sample $09
    PATEND

Pat024:
    NOTE 1, $24, $0A ; PCM sample $0A
    PATEND

Pat025:
    NOTE 1, $24, $0B ; PCM sample $0B
    PATEND

Pat026:
    NOTE 1, $24, $0C ; PCM sample $0C
    PATEND

Pat027:
    NOTE 1, $24, $0D ; PCM sample $0D
    PATEND

Pat040:
    NOTE 1, $24, $1B ; PCM sample $1B
    PATEND

Pat041:
    NOTE 1, $24, $1C ; PCM sample $1C
    PATEND

Pat042:
    NOTE 1, $24, $1D ; PCM sample $1D
    PATEND

Pat043:
    NOTE 1, $24, $1E ; PCM sample $1E
    PATEND

Ins51:
    INS_TONE $00, $F3, $21, Arp_50ED, Freq_5158, Comb_5149 ; $33

Arp_50ED:
    TB 1, $00 ; +0
    TB 1, $03 ; +3
    TB 1, $06 ; +6
    TB 1, $09 ; +9
    TB 1, $0C ; +12
    TB 2, $F4 ; -12
    TLOOP Arp_50ED

OrphanIns_50FC:
    INS_TONE $C0, $F3, $21, Arp_5105, Freq_5158, Comb_5149 ; not in the instrument table

Arp_5105:
    TB 4, $00 ; +0
    TB 4, $05 ; +5
    TB 4, $09 ; +9
    TB 4, $0C ; +12
    TLOOP Arp_5105

Sfx00:
    HOLD 1
    SFXEND

Sfx02:
    NOTE 5, $24, $0D
    KEYOFF 5
    SFXEND

NoiseIns13:
    INS_NOISE $80, $F1, $11, Noise_5124, Arp_5153 ; $0D

Noise_5124:
    TB 255, $3B
    TLOOP Noise_5124

Sfx01:
    NOTE 4, $24, $0C
    KEYOFF 4
    SFXEND

NoiseIns12:
    INS_NOISE $80, $F2, $41, Noise_5138, Arp_5153 ; $0C

Noise_5138:
    TB 3, $28
    TLOOP Noise_5138

OrphanTab_513D:
    TB 1, $01
    TB 1, $00
    TLOOP OrphanTab_513D

Comb_5144:
    TB 255, $00 ; freq table only
    TLOOP Comb_5144

Comb_5149:
    TB 255, $01 ; note only
    TLOOP Comb_5149

Comb_514E:
    TB 255, $02 ; note + freq table
    TLOOP Comb_514E

Arp_5153:
    TB 255, $00 ; +0
    TLOOP Arp_5153

Freq_5158:
    TW 255, 0
    TLOOP Freq_5158

OrphanTab_515E:
    TB 255, $00
    TLOOP OrphanTab_515E

OrphanTab_5163:
    TW 20, 0

OrphanTab_5163_Loop:
    TW 2, 1
    TW 2, -1
    TW 2, -1
    TW 2, 1
    TLOOP OrphanTab_5163_Loop

OrphanTab_5175:
    TW 3, 10
    TW 3, -10
    TW 3, -10
    TW 3, 10
    TLOOP OrphanTab_5175

OrphanTab_5184:
    TW 3, 5
    TW 3, -5
    TW 3, -5
    TW 3, 5
    TLOOP OrphanTab_5184

Freq_5193:
    TW 20, 0

Freq_529B_L0:
    TW 3, 2
    TW 3, -2
    TW 3, -2
    TW 3, 2
    TLOOP Freq_529B_L0

OrphanTab_51A5:
    TW 3, 1
    TW 3, -1
    TW 3, -1
    TW 3, 1
    TLOOP OrphanTab_51A5

Freq_51B4:
    TW 1, 1
    TW 2, 0
    TW 1, -1
    TW 2, 0
    TW 1, -1
    TW 2, 0
    TW 1, 1
    TW 2, 0
    TLOOP Freq_51B4

Freq_51CF:
    TW 1, -12
    TW 6, 2

Freq_51D5:
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

Freq_51D5_L0:
    TW 2, 16
    TW 2, -16
    TW 2, -16
    TW 2, 16
    TLOOP Freq_51D5_L0

Vol_5250:
    TB 2, $60 ; 25%
    TB 2, $40 ; 50%

Vol_5250_L0:
    TB 255, $20 ; 100%
    TLOOP Vol_5250_L0

Vol_5259:
    TB 255, $20 ; 100%
    TLOOP Vol_5259

Vol_525E:
    TB 255, $40 ; 50%
    TLOOP Vol_525E

Vol_5263:
    TB 255, $60 ; 25%
    TLOOP Vol_5263

Ins00:
    INS_TONE $80, $01, $01, Arp_5153, Freq_5158, Comb_5149 ; $00, $0C, $0D, $0E, $0F, $2D

NoiseIns00:
    INS_NOISE $00, $01, $01, Arp_5153, Arp_5153 ; $00

Ins01:
    INS_WAVE BlankVol, BlankVol, Arp_5153, Freq_5158, Comb_514E ; $01, $02 (unused)

Ins03:
    INS_TONE $80, $F2, $11, Arp_528B, Freq_529B_L0, Comb_514E ; $03 (unused)

Arp_528B:
    TB 3, $00 ; +0
    TB 3, $0C ; +12
    TLOOP Arp_528B

Ins04:
    INS_TONE $80, $F8, $21, Arp_5153, Freq_529B, Comb_514E ; $04

Freq_529B:
    TW 1, 200
    TW 5, -40
    TLOOP Freq_529B_L0

Ins05:
    INS_TONE $60, $F5, $11, Arp_52AD, Freq_529B_L0, Comb_514E ; $05 (unused)

Arp_52AD:
    TB 1, $00 ; +0
    TB 1, $0C ; +12
    TB 255, $00 ; +0
    TLOOP Arp_52AD

Ins32:
    INS_TONE $20, $C3, $11, Arp_5153, Freq_51B4, Comb_514E ; $20 (unused)

OrphanIns_52BF:
    INS_NOISE $20, $C3, $11, Arp_5153, NoiseCtl_52C7 ; not in the instrument table

    ; $52C6-$52C6: 1 unreferenced byte
    db $4D

NoiseCtl_52C7:
    TB 81, $01
    TB 244, $FF
    TB 4, $03
    TLOOP $B400

    ; $52D0-$52D0: 1 unreferenced byte
    db $51

Ins33:
    INS_TONE $80, $82, $11, Arp_52DA, Freq_51B4, Comb_514E ; $21 (unused)

Arp_52DA:
    TB 1, $00 ; +0
    TB 1, $0C ; +12
    TB 2, $00 ; +0
    TB 2, $0C ; +12
    TLOOP Arp_52DA

Ins34:
    INS_TONE $40, $78, $83, Arp_5153, Freq_51D5, Comb_514E ; $22 (unused)

Ins35:
    INS_TONE $40, $78, $83, Arp_5153, Freq_51CF, Comb_514E ; $23 (unused)

OrphanIns_52F7:
    INS_TONE $80, $F8, $F1, Arp_5300, Freq_5309, Comb_514E ; not in the instrument table

Arp_5300:
    TB 1, $00 ; +0
    TB 1, $02 ; +2
    TB 1, $04 ; +4
    TLOOP Arp_5300

Freq_5309:
    TW 255, 2
    TLOOP Freq_5309

OrphanIns_530F:
    INS_TONE $40, $F2, $F1, Arp_5318, Freq_5158, Comb_514E ; not in the instrument table

Arp_5318:
    TB 4, $00 ; +0
    TB 4, $03 ; +3
    TB 4, $06 ; +6
    TB 4, $09 ; +9
    TLOOP Arp_5318

Ins06:
    INS_TONE $80, $E1, $18, Arp_5153, Freq_5158, Comb_514E ; $06

Ins07:
    INS_TONE $80, $E2, $18, Arp_5153, Freq_5373, Comb_5379 ; $07

Ins08:
    INS_TONE $20, $E2, $18, Arp_5153, Freq_5158, Comb_514E ; $08

Ins09:
    INS_TONE $20, $38, $18, Arp_5153, Freq_5158, Comb_514E ; $09

Ins11:
    INS_TONE $80, $C1, $18, Arp_5153, Freq_5350, Comb_514E ; $0B

Freq_5350:
    TW 255, -30
    TLOOP Freq_5350

Ins10:
    INS_TONE $00, $58, $18, Arp_535F, Freq_536A, Comb_514E ; $0A

Arp_535F:
    TB 1, $00 ; +0
    TB 1, $03 ; +3
    TB 1, $07 ; +7
    TB 1, $0C ; +12
    TLOOP Arp_535F

Freq_536A:
    TW 60, 0
    TW 255, -1
    TLOOP Freq_536A

Freq_5373:
    TW 255, -2
    TLOOP Freq_5373

Comb_5379:
    TB 1, $01 ; note only
    TB 1, $02 ; note + freq table
    TLOOP Comb_5379

OrphanIns_5380:
    INS_TONE $C0, $C8, $41, Arp_5153, Freq_5389, Comb_514E ; not in the instrument table

Freq_5389:
    TW 1, 2
    TW 1, -2
    TLOOP Freq_5389

Ins36:
    INS_TONE $40, $67, $41, Arp_5153, Freq_5193, Comb_514E ; $24 (unused)

Ins37:
    INS_TONE $40, $67, $41, Arp_5153, Freq_53A4, Comb_514E ; $25 (unused)

Freq_53A4:
    TW 1, -20
    TW 5, 4
    TLOOP Freq_5193

Ins44:
    INS_WAVE Vol_5250, Vol_5263, Arp_5153, Freq_51B4, Comb_514E ; $2C (unused)

OrphanTab_53B7:
    TB 3, $00

OrphanTab_53B7_Loop:
    TB 255, $01
    TLOOP OrphanTab_53B7_Loop

    ; $53BE-$53BE: 1 unreferenced byte
    db $01

OrphanTab_53BF:
    TB 164, $06
    TB 2, $C4
    TB 255, $00
    TB 88, $51

Vol_53C7:
    TB 1, $60
    TB 1, $40

OrphanTab_53BF_Loop:
    TB 255, $20
    TLOOP OrphanTab_53BF_Loop

OrphanIns_53D0:
    INS_WAVE Vol_53C7, Vol_5263, Arp_5153, Freq_53DA, Comb_514E ; not in the instrument table

Freq_53DA:
    TW 1, -10
    TW 10, 1
    TLOOP Freq_51B4

    ; $53E3-$53EB: 9 unreferenced bytes
    db $04, $20, $08, $40, $FF, $60, $00, $BA, $47

Ins38:
    INS_WAVE Vol_5259, Vol_5263, Arp_53F6, Freq_54EB, Comb_514E ; $26 (unused)

Arp_53F6:
    TB 2, $F4 ; -12
    TB 255, $00 ; +0
    TLOOP Arp_53F6

Ins39:
    INS_WAVE Vol_5259, Vol_5263, Arp_5153, Freq_54E5, Comb_514E ; $27 (unused)

Ins42:
    INS_WAVE Vol_541B, Vol_5263, Arp_5153, Freq_54EB, Comb_514E ; $2A (unused)

Ins43:
    INS_WAVE Vol_541B, Vol_5263, Arp_5153, Freq_54E5, Comb_514E ; $2B (unused)

Vol_541B:
    TB 2, $20 ; 100%

Vol_541B_L0:
    TB 255, $40 ; 50%
    TLOOP Vol_541B_L0

OrphanIns_5422:
    INS_TONE $80, $F1, $21, Arp_5492, Freq_542B, Comb_514E ; not in the instrument table

Freq_542B:
    TW 255, -60
    TLOOP Freq_542B

Ins28:
    INS_TONE $80, $E1, $21, Arp_5492, Freq_543A, Comb_5144 ; $1C, $1E (unused)

Freq_543A:
    TW 1, 1100
    TW 1, 100
    TW 255, -80
    TLOOP Freq_543A

OrphanIns_5446:
    INS_TONE $80, $F5, $21, Arp_544F, Freq_5474, Comb_514E ; not in the instrument table

Arp_544F:
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
    TLOOP Arp_544F

Freq_5474:
    TW 255, -10

Freq_5474_L0:
    TW 3, 80
    TW 3, -80
    TLOOP Freq_5474_L0

OrphanIns_5480:
    INS_TONE $80, $F1, $21, Arp_5492, Freq_5499, Comb_5144 ; not in the instrument table

Ins29:
    INS_TONE $80, $F1, $21, Arp_5492, Freq_5499, Comb_5144 ; $1D (unused)

Arp_5492:
    TB 1, $00 ; +0
    TB 1, $02 ; +2
    TLOOP Arp_5492

Freq_5499:
    TW 1, 1700
    TW 2, -60

Freq_5499_L0:
    TW 1, 100
    TW 255, -60
    TLOOP Freq_5499_L0

Ins31:
    INS_TONE $80, $51, $21, Arp_54C0, Freq_54B1, Comb_5144 ; $1F (unused)

Freq_54B1:
    TW 1, 4060
    TW 1, -1
    TW 1, -4060

Freq_54B1_L0:
    TW 255, 0
    TLOOP Freq_54B1_L0

Arp_54C0:
    TB 1, $00 ; +0
    TB 1, $FF ; -1
    TB 1, $FE ; -2
    TB 1, $FD ; -3
    TLOOP Arp_54C0

Ins40:
    INS_WAVE Vol_5259, Vol_5263, Arp_5153, Freq_51B4, Comb_514E ; $28 (unused)

Ins41:
    INS_WAVE Vol_525E, Vol_5263, Arp_5153, Freq_51B4, Comb_514E ; $29 (unused)

    ; $54DF-$54E4: 6 unreferenced bytes
    db $32, $00, $00, $00, $EB, $54

Freq_54E5:
    TW 1, -10
    TW 5, 2

Freq_54EB:
    TW 12, 0

Freq_54EB_L0:
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
    TLOOP Freq_54EB_L0

OrphanIns_5515:
    INS_NOISE $00, $D1, $91, Noise_553A, Arp_5153 ; not in the instrument table

OrphanIns_551C:
    INS_NOISE $00, $F6, $91, Noise_5523, Arp_5153 ; not in the instrument table

Noise_5523:
    TB 3, $45

Noise_5523_L0:
    TB 1, $55
    TB 1, $54
    TB 1, $56
    TB 1, $54
    TB 2, $52
    TB 2, $53
    TB 2, $54
    TB 2, $55
    TB 2, $56
    TLOOP Noise_5523_L0

Noise_553A:
    TB 255, $45
    TLOOP Noise_553A

OrphanIns_553F:
    INS_NOISE $00, $B1, $91, Noise_5546, Arp_5153 ; not in the instrument table

Noise_5546:
    TB 1, $44
    TB 1, $45
    TB 1, $46
    TB 1, $47
    TLOOP Noise_5546

NoiseIns02:
    INS_NOISE $00, $41, $91, Noise_5558, Arp_5153 ; $02

Noise_5558:
    TB 255, $44
    TLOOP Noise_5558

NoiseIns04:
    INS_NOISE $00, $35, $01, Noise_556B, Arp_5153 ; $04 (unused)

NoiseIns03:
    INS_NOISE $20, $41, $01, Noise_556B, Noise_556B ; $03

Noise_556B:
    TB 255, $13
    TLOOP Noise_556B

NoiseIns01:
    INS_NOISE $80, $52, $01, Noise_5577, Arp_5153 ; $01

Noise_5577:
    TB 255, $32
    TLOOP Noise_5577

Noise_557C:
    TB 2, $42
    TB 255, $32
    TLOOP Noise_557C

NoiseIns06:
    INS_NOISE $80, $71, $01, Noise_557C, Arp_5153 ; $06 (unused)

OrphanIns_558A:
    INS_NOISE $80, $E1, $01, Noise_5591, Arp_5153 ; not in the instrument table

Noise_5591:
    TB 3, $44
    TB 255, $47
    TLOOP Noise_5591

OrphanIns_5598:
    INS_NOISE $80, $81, $01, Noise_559F, Arp_5153 ; not in the instrument table

Noise_559F:
    TB 2, $43
    TB 2, $45
    TLOOP Noise_559F

NoiseIns05:
    INS_NOISE $00, $F1, $C1, Noise_55AD, Arp_5153 ; $05 (unused)

Noise_55AD:
    TB 10, $28
    TLOOP Noise_55AD

OrphanIns_55B2:
    INS_TONE $80, $69, $E2, Arp_55D8, Freq_55DF, Comb_514E ; not in the instrument table

OrphanIns_55BB:
    INS_NOISE $60, $18, $18, Noise_55C4, $55CE ; not in the instrument table

    ; $55C2-$55C3: 2 unreferenced bytes
    db $4D, $51

Noise_55C4:
    TB 2, $00
    TB 1, $02
    TB 1, $FF
    TB 1, $FB
    db $00, $C4 ; part of tend
NoiseCtl_55CE:
    db $55 ; part of tend

OrphanTab_55CF:
    TW 4, 1
    TW 4, -1
    TLOOP OrphanTab_55CF

Arp_55D8:
    TB 1, $00 ; +0
    TB 1, $01 ; +1
    TLOOP Arp_55D8

Freq_55DF:
    TW 5, 0
    TW 5, 10
    TW 255, -2
    TLOOP Freq_55DF

OrphanIns_55EB:
    INS_NOISE $00, $49, $A1, Noise_55F2, Arp_5153 ; not in the instrument table

Noise_55F2:
    TB 1, $37
    TB 1, $36
    TB 1, $35
    TB 1, $34
    TB 1, $33
    TB 255, $32
    TLOOP Noise_55F2

    ; $5601-$5610: 16 unreferenced bytes
    db $F0, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

Wave_5611:
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

    ; $5621-$5630: 16 unreferenced bytes
    db $89, $73, $00, $48, $A8, $55, $AF, $FB, $87, $8A, $BA, $89, $98, $65, $55, $56

OrphanMorph_5631:
    MORPH 255, $30, $89
    TLOOP OrphanMorph_5631

Morph_5637:
    MORPH 255, $30, $00
    TLOOP Morph_5637

    ; $563D-$56F3: 183 unreferenced bytes
    db $0B, $30, $F0, $0B, $30, $FF, $0B, $31, $F0, $0B, $31, $FF, $0B, $32, $F0, $0B
    db $32, $FF, $0B, $33, $F0, $0B, $33, $FF, $0B, $34, $F0, $0B, $34, $FF, $0B, $35
    db $F0, $0B, $35, $FF, $0B, $36, $F0, $0B, $36, $FF, $0B, $37, $F0, $0B, $37, $FF
    db $0B, $38, $F0, $0B, $38, $FF, $0B, $39, $F0, $0B, $39, $FF, $0B, $3A, $F0, $0B
    db $3A, $FF, $0B, $3B, $F0, $0B, $3B, $FF, $0B, $3C, $F0, $0B, $3C, $FF, $0B, $3D
    db $F0, $0B, $3D, $FF, $0B, $3E, $F0, $0B, $3E, $FF, $0B, $3F, $F0, $0B, $3F, $00
    db $0B, $3E, $F0, $0B, $3E, $00, $0B, $3D, $F0, $0B, $3D, $00, $0B, $3C, $F0, $0B
    db $3C, $00, $0B, $3B, $F0, $0B, $3B, $00, $0B, $3A, $F0, $0B, $3A, $00, $0B, $39
    db $F0, $0B, $39, $00, $0B, $38, $F0, $0B, $38, $00, $0B, $37, $F0, $0B, $37, $00
    db $0B, $36, $F0, $0B, $36, $00, $0B, $35, $F0, $0B, $35, $00, $0B, $34, $F0, $0B
    db $34, $00, $0B, $33, $F0, $0B, $33, $00, $0B, $32, $F0, $0B, $32, $00, $0B, $31
    db $F0, $0B, $31, $00, $00, $3D, $56

PcmTable:
    db $00 ; priority
    dw Pcm00
    dw $0001 ; length in 16-byte blocks
    db BANK(Pcm00) ; PCM $00
    db $00 ; priority
    dw Pcm01
    dw $0116 ; length in 16-byte blocks
    db BANK(Pcm01) ; PCM $01
    db $00 ; priority
    dw Pcm02
    dw $00B7 ; length in 16-byte blocks
    db BANK(Pcm02) ; PCM $02
    db $00 ; priority
    dw Pcm03
    dw $0064 ; length in 16-byte blocks
    db BANK(Pcm03) ; PCM $03
    db $01 ; priority
    dw Pcm04
    dw $0060 ; length in 16-byte blocks
    db BANK(Pcm04) ; PCM $04
    db $01 ; priority
    dw Pcm05
    dw $0071 ; length in 16-byte blocks
    db BANK(Pcm05) ; PCM $05
    db $01 ; priority
    dw Pcm06
    dw $0076 ; length in 16-byte blocks
    db BANK(Pcm06) ; PCM $06
    db $01 ; priority
    dw Pcm07
    dw $005B ; length in 16-byte blocks
    db BANK(Pcm07) ; PCM $07
    db $01 ; priority
    dw Pcm08
    dw $006D ; length in 16-byte blocks
    db BANK(Pcm08) ; PCM $08
    db $01 ; priority
    dw Pcm09
    dw $003E ; length in 16-byte blocks
    db BANK(Pcm09) ; PCM $09
    db $01 ; priority
    dw Pcm0A
    dw $0034 ; length in 16-byte blocks
    db BANK(Pcm0A) ; PCM $0A
    db $01 ; priority
    dw Pcm0B
    dw $0067 ; length in 16-byte blocks
    db BANK(Pcm0B) ; PCM $0B
    db $01 ; priority
    dw Pcm0C
    dw $0059 ; length in 16-byte blocks
    db BANK(Pcm0C) ; PCM $0C
    db $01 ; priority
    dw Pcm0D
    dw $0083 ; length in 16-byte blocks
    db BANK(Pcm0D) ; PCM $0D
    db $01 ; priority
    dw Pcm0E
    dw $0001 ; length in 16-byte blocks
    db BANK(Pcm0E) ; PCM $0E
    db $01 ; priority
    dw Pcm0F
    dw $0001 ; length in 16-byte blocks
    db BANK(Pcm0F) ; PCM $0F
    db $01 ; priority
    dw Pcm10
    dw $002C ; length in 16-byte blocks
    db BANK(Pcm10) ; PCM $10
    db $01 ; priority
    dw Pcm11
    dw $0014 ; length in 16-byte blocks
    db BANK(Pcm11) ; PCM $11
    db $01 ; priority
    dw Pcm12
    dw $0017 ; length in 16-byte blocks
    db BANK(Pcm12) ; PCM $12
    db $01 ; priority
    dw Pcm13
    dw $002E ; length in 16-byte blocks
    db BANK(Pcm13) ; PCM $13
    db $01 ; priority
    dw Pcm14
    dw $0017 ; length in 16-byte blocks
    db BANK(Pcm14) ; PCM $14
    db $01 ; priority
    dw Pcm15
    dw $0013 ; length in 16-byte blocks
    db BANK(Pcm15) ; PCM $15
    db $01 ; priority
    dw Pcm16
    dw $0017 ; length in 16-byte blocks
    db BANK(Pcm16) ; PCM $16
    db $01 ; priority
    dw Pcm17
    dw $000C ; length in 16-byte blocks
    db BANK(Pcm17) ; PCM $17
    db $01 ; priority
    dw Pcm18
    dw $0014 ; length in 16-byte blocks
    db BANK(Pcm18) ; PCM $18
    db $01 ; priority
    dw Pcm19
    dw $0018 ; length in 16-byte blocks
    db BANK(Pcm19) ; PCM $19
    db $01 ; priority
    dw Pcm1A
    dw $0013 ; length in 16-byte blocks
    db BANK(Pcm1A) ; PCM $1A
    db $01 ; priority
    dw Pcm1B
    dw $0071 ; length in 16-byte blocks
    db BANK(Pcm1B) ; PCM $1B
    db $01 ; priority
    dw Pcm1C
    dw $00AA ; length in 16-byte blocks
    db BANK(Pcm1C) ; PCM $1C
    db $01 ; priority
    dw Pcm1D
    dw $00E2 ; length in 16-byte blocks
    db BANK(Pcm1D) ; PCM $1D
    db $01 ; priority
    dw Pcm1E
    dw $00D2 ; length in 16-byte blocks
    db BANK(Pcm1E) ; PCM $1E
