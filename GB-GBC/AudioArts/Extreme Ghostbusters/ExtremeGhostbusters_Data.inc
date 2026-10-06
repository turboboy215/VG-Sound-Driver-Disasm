; Extreme Ghostbusters (E) (GBC) - music/SFX data $48E2-$7B50

    ; $48E2-$48F8: 23 unreferenced bytes
    db $CB, $27, $CB, $27, $CB, $27, $CB, $27, $F6, $08, $EA, $BF, $C0, $C9, $7B, $EA
    db $DD, $C0, $7A, $EA, $DE, $C0, $C9

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
    dw Pat280
    db 3 ; ch4  (SFX $00)
    db 100 ; priority
    dw Sfx01
    db 3 ; ch4  (SFX $01)
    db 100 ; priority
    dw Sfx02
    db 3 ; ch4  (SFX $02)
    db 127 ; priority
    dw Sfx03
    db 2 ; ch2  (SFX $03)
    db 20 ; priority
    dw Sfx04
    db 3 ; ch4  (SFX $04)
    db 20 ; priority
    dw Sfx05
    db 3 ; ch4  (SFX $05)
    db 100 ; priority
    dw Sfx06
    db 3 ; ch4  (SFX $06)
    db 110 ; priority
    dw Sfx07
    db 2 ; ch2  (SFX $07)
    db 110 ; priority
    dw Sfx08
    db 2 ; ch2  (SFX $08)
    db 110 ; priority
    dw Sfx09
    db 2 ; ch2  (SFX $09)
    db 50 ; priority
    dw Sfx0A
    db 2 ; ch2  (SFX $0A)
    db 110 ; priority
    dw Sfx0B
    db 2 ; ch2  (SFX $0B)
    db 110 ; priority
    dw Sfx0C
    db 2 ; ch2  (SFX $0C)
    db 100 ; priority
    dw Sfx0D
    db 2 ; ch2  (SFX $0D)
    db 120 ; priority
    dw Sfx0E
    db 2 ; ch2  (SFX $0E)
    db 20 ; priority
    dw Sfx0F
    db 2 ; ch2  (SFX $0F)
    db 50 ; priority
    dw Sfx10
    db 2 ; ch2  (SFX $10)
    db 50 ; priority
    dw Sfx11
    db 2 ; ch2  (SFX $11)

Sfx11:
    NOTE 4, C5, $42
    NOTE 4, C4, $42
    KEYOFF 2
    SFXEND

Ins72:
    INS_TONE $00, $F2, $11, Arp_4A5A, Freq_49EB, Comb_7395 ; $48

Freq_49EB:
    TW 20, -20

Freq_49EB_L0:
    TW 4, 4
    TW 4, -6
    TLOOP Freq_49EB_L0

Sfx10:
    NOTE 20, G4, $48
    SFXEND

Sfx0F:
    NOTE 30, A4, $47
    SFXEND

Ins71:
    INS_TONE $60, $E3, $11, Arp_739A, Freq_4A0C, Comb_4A76 ; $47

Freq_4A0C:
    TW 255, 2
    TLOOP Freq_4A0C

Sfx0E:
    NOTE 20, C4, $44
    NOTE 40, C4, $45
    NOTE 40, C4, $46
    SFXEND

Freq_4A1E:
    TW 1, 1000
    TW 20, 50
    TLOOP Freq_4A1E

Freq_4A27:
    TW 1, 2000

Freq_4A27_L0:
    TW 2, -20
    TW 1, 5
    TLOOP Freq_4A27_L0

Freq_4A33:
    TW 1, 1500

Freq_4A33_L0:
    TW 5, -20
    TW 2, 30
    TLOOP Freq_4A33_L0

Ins68:
    INS_TONE $00, $39, $11, Arp_4A5A, Freq_4A1E, Comb_738B ; $44

Ins69:
    INS_TONE $60, $F8, $11, Arp_4A5A, Freq_4A27, Comb_738B ; $45

Ins70:
    INS_TONE $80, $F5, $11, Arp_4A5A, Freq_4A33, Comb_738B ; $46

Arp_4A5A:
    TB 1, $00 ; +0
    TB 1, $01 ; +1
    TLOOP Arp_4A5A

Sfx0D:
    NOTE 50, C6, $43
    SFXEND

Sfx0B:
    NOTE 80, G6, $42
    SFXEND

Ins67:
    INS_TONE $60, $F2, $11, Arp_4A7D, Freq_4A84, Comb_7395 ; $43

Comb_4A76:
    TB 1, $01 ; note only
    TB 1, $02 ; note + freq table
    TLOOP Comb_4A76

Arp_4A7D:
    TB 1, $00 ; +0
    TB 1, $02 ; +2
    TLOOP Arp_4A7D

Freq_4A84:
    TW 5, -50
    TW 2, 10
    TLOOP Freq_4A84

Ins66:
    INS_TONE $80, $F6, $11, Arp_4A96, Freq_4AA1, Comb_7384 ; $42

Arp_4A96:
    TB 3, $00 ; +0
    TB 3, $05 ; +5
    TB 3, $07 ; +7
    TB 3, $0C ; +12
    TLOOP Arp_4A96

Freq_4AA1:
    TW 1, 1400

Freq_4AA1_L0:
    TW 255, 3
    TLOOP Freq_4AA1_L0

Sfx0A:
    NOTE 3, C4, $41
    NOTE 3, G3, $41
    NOTE 3, C3, $41
    KEYOFF 2
    SFXEND

Ins65:
    INS_TONE $60, $F6, $11, Arp_739A, Freq_739F, Comb_7390 ; $41

Sfx0C:
    NOTE 2, G6, $06
    KEYOFF 4
    NOTE 2, G6, $06
    KEYOFF 2
    SFXEND

Sfx07:
    NOTE 12, E6, $3E
    KEYON 12
    SFXEND

Ins62:
    INS_TONE $80, $F1, $C3, Arp_739A, Freq_4ADF, Comb_7395 ; $3E

Freq_4ADF:
    TW 255, -50
    TLOOP Freq_4ADF

Sfx08:
    NOTE 25, C5, $3F
    KEYOFF 25
    SFXEND

Ins63:
    INS_TONE $00, $39, $F3, Arp_739A, Freq_4AF6, Comb_7395 ; $3F

Freq_4AF6:
    TW 8, 10
    TW 8, -8
    TW 1, -50
    TLOOP Freq_4AF6

Ins64:
    INS_TONE $00, $39, $F3, Arp_739A, Freq_4B13, Comb_7395 ; $40

Sfx09:
    NOTE 8, G3, $40
    KEYOFF 30
    SFXEND

Freq_4B13:
    TW 8, 50

Freq_4B13_L0:
    TW 5, 5
    TW 5, -8
    TW 1, -20
    TLOOP Freq_4B13_L0

Sfx03:
    NOTE 3, C6, $3D
    NOTE 3, Ds6, $3D
    NOTE 20, G6, $3D
    SFXEND

Ins61:
    INS_TONE $80, $E2, $01, Arp_4B37, Freq_739F, Comb_7395 ; $3D

Arp_4B37:
    TB 1, $00 ; +0
    TB 1, $0C ; +12
    TB 1, $01 ; +1
    TB 1, $0D ; +13
    TLOOP Arp_4B37

Sfx02:
    NOTE 5, $24, $06
    KEYOFF 5
    SFXEND

NoiseIns06:
    INS_NOISE $80, $F1, $11, Noise_4B51, Arp_739A ; $06

Noise_4B51:
    TB 255, $3B
    TLOOP Noise_4B51

Sfx01:
    NOTE 4, $24, $07
    KEYOFF 4
    SFXEND

NoiseIns07:
    INS_NOISE $80, $F2, $41, Noise_4B65, Arp_739A ; $07

Noise_4B65:
    TB 3, $28
    TLOOP Noise_4B65

NoiseIns08:
    INS_NOISE $80, $59, $51, Noise_4B71, Arp_739A ; $08

Noise_4B71:
    TB 2, $46
    TB 2, $45
    TB 2, $34
    TB 2, $33
    TB 2, $32
    TB 2, $31
    TB 255, $40
    TLOOP Noise_4B71

Sfx04:
    NOTE 8, $24, $08
    KEYOFF 2
    SFXEND

NoiseIns09:
    INS_NOISE $80, $E1, $21, Noise_4B91, Arp_739A ; $09

Noise_4B91:
    TB 3, $53
    TB 255, $55
    TLOOP Noise_4B91

Sfx05:
    NOTE 10, $24, $09
    SFXEND

Sfx06:
    NOTE 40, $24, $0A
    SFXEND

NoiseIns10:
    INS_NOISE $80, $B4, $21, Noise_4BAB, Arp_739A ; $0A

Noise_4BAB:
    TB 1, $54
    TB 1, $52
    TB 1, $44
    TB 1, $42
    TB 1, $34
    TB 1, $32
    TB 1, $24
    TB 1, $22
    TLOOP Noise_4BAB

SongTable:
    db 1, %1111 ; tempo, channel mask
    dw Song00_Ch1, Song00_Ch2, Song00_Ch3, Song00_Ch4
    dw Morph_7889 - 2, Wave_7879 ; wave morph, wave
    db 8, %1111 ; tempo, channel mask
    dw Song01_Ch1, Song01_Ch2, Song01_Ch3, Song01_Ch4
    dw Morph_795A - 2, Wave_788F ; wave morph, wave
    db 8, %1111 ; tempo, channel mask
    dw Song02_Ch1, Song02_Ch2, Song02_Ch3, Song02_Ch4
    dw Morph_795A - 2, Wave_788F ; wave morph, wave
    db 6, %1111 ; tempo, channel mask
    dw Song03_Ch1, Song03_Ch2, Song03_Ch3, Song03_Ch4
    dw Morph_795A - 2, Wave_788F ; wave morph, wave
    db 7, %1111 ; tempo, channel mask
    dw Song04_Ch1, Song04_Ch2, Song04_Ch3, Song04_Ch4
    dw Morph_795A - 2, Wave_788F ; wave morph, wave
    db 15, %1111 ; tempo, channel mask
    dw Song05_Ch1, Song05_Ch2, Song05_Ch3, Song05_Ch4
    dw Morph_795A - 2, Wave_788F ; wave morph, wave
    db 5, %1111 ; tempo, channel mask
    dw Song06_Ch1, Song06_Ch2, Song06_Ch3, Song06_Ch4
    dw Morph_795A - 2, Wave_788F ; wave morph, wave
    db 5, %1111 ; tempo, channel mask
    dw Song07_Ch1, Song07_Ch2, Song07_Ch3, Song07_Ch4
    dw Morph_795A - 2, Wave_788F ; wave morph, wave
    db 7, %1111 ; tempo, channel mask
    dw Song08_Ch1, Song08_Ch2, Song08_Ch3, Song08_Ch4
    dw Morph_795A - 2, Wave_788F ; wave morph, wave
    db 7, %1111 ; tempo, channel mask
    dw Song09_Ch1, Song09_Ch2, Song09_Ch3, Song09_Ch4
    dw Morph_795A - 2, Wave_788F ; wave morph, wave

PatternTable:
    dw Pat000                   ; $00
    dw Pat001                   ; $01
    dw Pat002                   ; $02
    dw Pat003                   ; $03
    dw Pat004                   ; $04
    dw Pat005                   ; $05
    dw Song01_Ch1               ; $06
    dw Pat007                   ; $07
    dw Song01_Ch1               ; $08
    dw Pat009                   ; $09
    dw Pat010                   ; $0A
    dw Pat011                   ; $0B
    dw Song01_Ch3               ; $0C
    dw Song01_Ch3               ; $0D
    dw Song01_Ch3               ; $0E
    dw Pat015                   ; $0F
    dw Pat016                   ; $10
    dw Pat017                   ; $11
    dw Pat018                   ; $12
    dw Pat019                   ; $13
    dw Pat020                   ; $14
    dw Pat021                   ; $15
    dw Pat022                   ; $16
    dw Pat023                   ; $17
    dw Song02_Ch1               ; $18
    dw Song02_Ch1               ; $19
    dw Pat026                   ; $1A
    dw Pat027                   ; $1B
    dw Pat028                   ; $1C
    dw Pat029                   ; $1D
    dw Song02_Ch2               ; $1E
    dw Pat031                   ; $1F
    dw Song02_Ch2               ; $20
    dw Pat033                   ; $21
    dw Song02_Ch2               ; $22
    dw Pat035                   ; $23
    dw Pat036                   ; $24
    dw Song02_Ch2               ; $25
    dw Pat038                   ; $26
    dw Pat039                   ; $27
    dw Song02_Ch2               ; $28
    dw Pat041                   ; $29
    dw Pat042                   ; $2A
    dw Song02_Ch3               ; $2B
    dw Pat044                   ; $2C
    dw Song02_Ch3               ; $2D
    dw Pat046                   ; $2E
    dw Song02_Ch3               ; $2F
    dw Pat048                   ; $30
    dw Pat049                   ; $31
    dw Song02_Ch3               ; $32
    dw Song02_Ch3               ; $33
    dw Song02_Ch3               ; $34
    dw Song02_Ch3               ; $35
    dw Pat054                   ; $36
    dw Pat055                   ; $37
    dw Pat056                   ; $38
    dw Pat057                   ; $39
    dw Pat058                   ; $3A
    dw Pat059                   ; $3B
    dw Song02_Ch4               ; $3C
    dw Pat061                   ; $3D
    dw Pat062                   ; $3E
    dw Pat063                   ; $3F
    dw Pat064                   ; $40
    dw Pat065                   ; $41
    dw Song02_Ch4               ; $42
    dw Pat067                   ; $43
    dw Pat068                   ; $44
    dw Pat069                   ; $45
    dw Song03_Ch1               ; $46
    dw Song03_Ch1               ; $47
    dw Song03_Ch1               ; $48
    dw Song03_Ch1               ; $49
    dw Song03_Ch1               ; $4A
    dw Pat075                   ; $4B
    dw Song03_Ch1               ; $4C
    dw Song03_Ch1               ; $4D
    dw Pat078                   ; $4E
    dw Song03_Ch1               ; $4F
    dw Pat080                   ; $50
    dw Pat081                   ; $51
    dw Song03_Ch2               ; $52
    dw Pat083                   ; $53
    dw Song03_Ch2               ; $54
    dw Song03_Ch2               ; $55
    dw Song03_Ch2               ; $56
    dw Song03_Ch2               ; $57
    dw Song03_Ch2               ; $58
    dw Song03_Ch2               ; $59
    dw Song03_Ch2               ; $5A
    dw Song03_Ch2               ; $5B
    dw Song03_Ch2               ; $5C
    dw Song03_Ch2               ; $5D
    dw Song03_Ch2               ; $5E
    dw Song03_Ch2               ; $5F
    dw Pat096                   ; $60
    dw Pat097                   ; $61
    dw Pat098                   ; $62
    dw Pat099                   ; $63
    dw Pat100                   ; $64
    dw Pat101                   ; $65
    dw Song03_Ch3               ; $66
    dw Pat103                   ; $67
    dw Song03_Ch3               ; $68
    dw Song03_Ch3               ; $69
    dw Song03_Ch3               ; $6A
    dw Song03_Ch3               ; $6B
    dw Song03_Ch3               ; $6C
    dw Song03_Ch3               ; $6D
    dw Pat110                   ; $6E
    dw Song03_Ch3               ; $6F
    dw Pat112                   ; $70
    dw Song07_Ch1               ; $71
    dw Pat114                   ; $72
    dw Song03_Ch4               ; $73
    dw Pat116                   ; $74
    dw Pat117                   ; $75
    dw Song03_Ch4               ; $76
    dw Song03_Ch4               ; $77
    dw Pat120                   ; $78
    dw Pat121                   ; $79
    dw Pat122                   ; $7A
    dw Pat123                   ; $7B
    dw Pat124                   ; $7C
    dw Pat125                   ; $7D
    dw Pat126                   ; $7E
    dw Song03_Ch4               ; $7F
    dw Pat128                   ; $80
    dw Pat129                   ; $81
    dw Song04_Ch1               ; $82
    dw Pat131                   ; $83
    dw Song04_Ch2               ; $84
    dw Pat133                   ; $85
    dw Song04_Ch2               ; $86
    dw Song04_Ch2               ; $87
    dw Song04_Ch2               ; $88
    dw Song04_Ch2               ; $89
    dw Song04_Ch2               ; $8A
    dw Pat139                   ; $8B
    dw Song04_Ch2               ; $8C
    dw Song04_Ch2               ; $8D
    dw Song04_Ch2               ; $8E
    dw Pat143                   ; $8F
    dw Song04_Ch2               ; $90
    dw Song04_Ch2               ; $91
    dw Song04_Ch2               ; $92
    dw Pat147                   ; $93
    dw Pat148                   ; $94
    dw Song04_Ch3               ; $95
    dw Song04_Ch3               ; $96
    dw Pat151                   ; $97
    dw Song04_Ch3               ; $98
    dw Song04_Ch3               ; $99
    dw Song04_Ch3               ; $9A
    dw Song04_Ch3               ; $9B
    dw Song04_Ch3               ; $9C
    dw Pat157                   ; $9D
    dw Pat158                   ; $9E
    dw Song04_Ch3               ; $9F
    dw Song04_Ch3               ; $A0
    dw Song04_Ch3               ; $A1
    dw Song04_Ch3               ; $A2
    dw Song04_Ch3               ; $A3
    dw Song04_Ch3               ; $A4
    dw Pat165                   ; $A5
    dw Pat166                   ; $A6
    dw Song04_Ch4               ; $A7
    dw Pat168                   ; $A8
    dw Pat169                   ; $A9
    dw Pat170                   ; $AA
    dw Pat171                   ; $AB
    dw Pat172                   ; $AC
    dw Pat173                   ; $AD
    dw Song04_Ch4               ; $AE
    dw Song04_Ch4               ; $AF
    dw Pat176                   ; $B0
    dw Pat177                   ; $B1
    dw Pat178                   ; $B2
    dw Pat179                   ; $B3
    dw Pat180                   ; $B4
    dw Pat181                   ; $B5
    dw Pat182                   ; $B6
    dw Pat183                   ; $B7
    dw Pat184                   ; $B8
    dw Pat185                   ; $B9
    dw Pat186                   ; $BA
    dw Pat187                   ; $BB
    dw Pat188                   ; $BC
    dw Pat189                   ; $BD
    dw Pat190                   ; $BE
    dw Pat191                   ; $BF
    dw Pat192                   ; $C0
    dw Pat193                   ; $C1
    dw Pat194                   ; $C2
    dw Pat195                   ; $C3
    dw Pat196                   ; $C4
    dw Pat197                   ; $C5
    dw Pat198                   ; $C6
    dw Pat199                   ; $C7
    dw Pat200                   ; $C8
    dw Pat201                   ; $C9
    dw Pat202                   ; $CA
    dw Pat203                   ; $CB
    dw Pat204                   ; $CC
    dw Song06_Ch1               ; $CD
    dw Pat206                   ; $CE
    dw Pat207                   ; $CF
    dw Pat208                   ; $D0
    dw Pat209                   ; $D1
    dw Pat210                   ; $D2
    dw Pat211                   ; $D3
    dw Pat212                   ; $D4
    dw Pat213                   ; $D5
    dw Pat214                   ; $D6
    dw Pat215                   ; $D7
    dw Pat216                   ; $D8
    dw Pat217                   ; $D9
    dw Pat218                   ; $DA
    dw Pat219                   ; $DB
    dw Pat220                   ; $DC
    dw Pat221                   ; $DD
    dw Pat222                   ; $DE
    dw Pat223                   ; $DF
    dw Pat224                   ; $E0
    dw Song08_Ch2               ; $E1
    dw Song08_Ch2               ; $E2
    dw Song08_Ch2               ; $E3
    dw Pat228                   ; $E4
    dw Song08_Ch2               ; $E5
    dw Pat230                   ; $E6
    dw Pat231                   ; $E7
    dw Pat232                   ; $E8
    dw Pat233                   ; $E9
    dw Pat234                   ; $EA
    dw Pat235                   ; $EB
    dw Pat236                   ; $EC
    dw Pat237                   ; $ED
    dw Pat238                   ; $EE
    dw Song08_Ch4               ; $EF
    dw Song08_Ch4               ; $F0
    dw Song08_Ch4               ; $F1
    dw Song08_Ch4               ; $F2
    dw Song08_Ch4               ; $F3
    dw Pat244                   ; $F4
    dw Pat245                   ; $F5
    dw Pat246                   ; $F6
    dw Song09_Ch1               ; $F7
    dw Song09_Ch1               ; $F8
    dw Pat249                   ; $F9
    dw Song09_Ch1               ; $FA
    dw Pat251                   ; $FB
    dw Pat252                   ; $FC
    dw Song09_Ch2               ; $FD
    dw Song09_Ch2               ; $FE
    dw Song09_Ch2               ; $FF
    dw Song09_Ch2               ; $100
    dw Song09_Ch2               ; $101
    dw Song09_Ch2               ; $102
    dw Pat259                   ; $103
    dw Pat260                   ; $104
    dw Pat261                   ; $105
    dw Song09_Ch3               ; $106
    dw Song09_Ch3               ; $107
    dw Song09_Ch3               ; $108
    dw Pat265                   ; $109
    dw Pat266                   ; $10A
    dw Pat267                   ; $10B
    dw Pat268                   ; $10C
    dw Pat269                   ; $10D
    dw Pat270                   ; $10E
    dw Song09_Ch4               ; $10F
    dw Pat272                   ; $110
    dw Pat273                   ; $111
    dw Pat274                   ; $112
    dw Song09_Ch4               ; $113
    dw Song09_Ch4               ; $114
    dw Pat277                   ; $115
    dw Pat278                   ; $116
    dw Pat279                   ; $117
    dw Pat280                   ; $118
    dw Pat280                   ; $119
    dw Pat280                   ; $11A
    dw Pat283                   ; $11B
    dw Pat280                   ; $11C
    dw Pat280                   ; $11D
    dw Pat280                   ; $11E
    dw Pat287                   ; $11F

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
    dw Ins00                    ; $2F
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
    dw Ins59                    ; $3C
    dw Ins61                    ; $3D
    dw Ins62                    ; $3E
    dw Ins63                    ; $3F
    dw Ins64                    ; $40
    dw Ins65                    ; $41
    dw Ins66                    ; $42
    dw Ins67                    ; $43
    dw Ins68                    ; $44
    dw Ins69                    ; $45
    dw Ins70                    ; $46
    dw Ins71                    ; $47
    dw Ins72                    ; $48

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

Song00_Ch1_Loop:
    STEP 0, $004

Song00_Ch1:
    STEP 0, $001

Song00_Ch2:
    STEP 0, $001

Song00_Ch3:
    STEP 0, $002

Song00_Ch4:
    STEP 0, $003

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

Song01_Ch2:
    STEP 0, $005
    STEP 0, $005
    STEP 0, $007
    STEP 0, $007
    STEP 0, $007
    STEP 0, $007
    STEP 0, $009
    STEP 0, $00A

Pat005:
    NOTE 4, Fs2, $05
    NOTE 8, B2, $05
    NOTE 8, B2, $05
    NOTE 8, B2, $05
    NOTE 4, A2, $05
    NOTE 4, Fs2, $05
    NOTE 8, B2, $05
    NOTE 8, B2, $05
    NOTE 8, B2, $05
    NOTE 4, A2, $05
    PATEND

Pat007:
    NOTE 2, Fs2, $05
    NOTE 2, Cs2, $22
    NOTE 2, B2, $05
    NOTE 2, Fs2, $22
    NOTE 2, D2, $22
    NOTE 2, Cs2, $22
    NOTE 2, B2, $05
    NOTE 2, Fs2, $22
    NOTE 4, A2, $22
    NOTE 2, B2, $05
    NOTE 2, Fs2, $22
    NOTE 2, D2, $22
    NOTE 2, Cs2, $22
    NOTE 2, A2, $05
    NOTE 2, B2, $22
    NOTE 2, Fs2, $05
    NOTE 2, Cs2, $22
    NOTE 2, B2, $05
    NOTE 2, D2, $22
    NOTE 2, Cs2, $22
    NOTE 2, B2, $22
    NOTE 2, B2, $05
    NOTE 2, Fs2, $22
    NOTE 2, A2, $22
    NOTE 2, B2, $22
    NOTE 2, B2, $05
    NOTE 2, Fs2, $22
    NOTE 2, D2, $22
    NOTE 2, Cs2, $22
    NOTE 2, A2, $05
    NOTE 2, B2, $22
    PATEND

Pat009:
    NOTE 2, D3, $22
    NOTE 2, Cs3, $22
    NOTE 8, B2, $22
    NOTE 4, Fs2, $22
    NOTE 2, D3, $22
    NOTE 2, Cs3, $22
    NOTE 8, B2, $22
    NOTE 4, Fs2, $22
    NOTE 4, A2, $22
    NOTE 2, Cs3, $22
    NOTE 10, B2, $22
    NOTE 8, A2, $22
    NOTE 2, Fs2, $22
    NOTE 2, Fs2, $22
    NOTE 2, D3, $22
    NOTE 2, Cs3, $22
    PATEND

Pat010:
    NOTE 16, A2, $22
    NOTE 2, D3, $22
    NOTE 1, Cs3, $22
    NOTE 1, A2, $22
    NOTE 12, B2, $22
    NOTE 2, D3, $22
    NOTE 2, Cs3, $22
    NOTE 8, B2, $22
    NOTE 4, B2, $05
    NOTE 4, D5, $06
    NOTE 2, B2, $05
    NOTE 6, Cs5, $08
    NOTE 4, A2, $05
    SONGJUMP Song01_Ch2

Song01_Ch1:
    STEP 0, $00B
    STEP 0, $00B
    STEP 0, $00B
    STEP 0, $00B
    STEP 0, $00B
    STEP 0, $00B
    STEP 0, $00F
    STEP 0, $010

Pat011:
    NOTE 64, B4, $30
    PATEND

Pat015:
    NOTE 16, B4, $30
    NOTE 8, A4, $39
    NOTE 8, Fs4, $30
    NOTE 16, B4, $30
    NOTE 8, A4, $39
    NOTE 8, Fs4, $30
    PATEND

Pat016:
    NOTE 16, B4, $30
    NOTE 8, A4, $39
    NOTE 8, Fs4, $30
    NOTE 16, B4, $30
    NOTE 8, A4, $39
    NOTE 8, Fs4, $30
    SONGJUMP Song01_Ch1

Song01_Ch3:
    STEP 0, $011
    STEP 0, $012
    STEP 0, $013
    STEP 0, $014
    STEP 0, $013
    STEP 0, $014
    STEP 0, $015
    STEP 0, $016

    ; $50C4-$50C5: 2 unreferenced bytes
    db $EF, $7B

Pat017:
    NOTE 2, D6, $1B
    NOTE 2, Cs6, $1B
    NOTE 2, B5, $1B
    NOTE 2, D6, $1B
    NOTE 2, Cs6, $1B
    NOTE 2, B5, $1B
    NOTE 2, A5, $1B
    NOTE 2, Fs5, $1B
    NOTE 2, A5, $1B
    NOTE 2, B5, $1B
    NOTE 1, Fs5, $1B
    KEYOFF 1
    NOTE 2, Fs5, $1B
    NOTE 2, D6, $1B
    NOTE 2, Cs6, $1B
    NOTE 4, B5, $1B
    NOTE 2, D6, $1B
    NOTE 2, Cs6, $1B
    NOTE 2, B5, $1B
    NOTE 2, D6, $1B
    NOTE 2, Cs6, $1B
    NOTE 2, B5, $1B
    NOTE 2, A5, $1B
    NOTE 2, Fs5, $1B
    NOTE 2, A5, $1B
    NOTE 2, B5, $1B
    NOTE 1, Fs5, $1B
    KEYOFF 1
    NOTE 2, Fs5, $1B
    NOTE 2, D6, $1B
    NOTE 2, Cs6, $1B
    NOTE 4, B5, $1B
    PATEND

Pat018:
    NOTE 2, D6, $1B
    NOTE 2, Cs6, $1B
    NOTE 2, B5, $1B
    NOTE 2, D6, $1B
    NOTE 2, Cs6, $1B
    NOTE 2, B5, $1B
    NOTE 2, A5, $1B
    NOTE 2, Fs5, $1B
    NOTE 2, A5, $1B
    NOTE 2, B5, $1B
    NOTE 1, Fs5, $1B
    KEYOFF 1
    NOTE 2, Fs5, $1B
    NOTE 2, D6, $1B
    NOTE 2, Cs6, $1B
    NOTE 4, B5, $1B
    NOTE 2, D6, $1B
    NOTE 2, Cs6, $1B
    NOTE 2, B5, $1B
    NOTE 2, D6, $1B
    NOTE 2, Cs6, $1B
    NOTE 2, B5, $1B
    NOTE 2, A5, $1B
    NOTE 2, Fs5, $1B
    NOTE 2, A5, $1B
    NOTE 2, B5, $1B
    NOTE 1, Fs5, $1B
    KEYOFF 1
    NOTE 2, Fs5, $1B
    NOTE 2, D6, $1B
    NOTE 2, Cs6, $1B
    NOTE 4, B5, $1B
    PATEND

Pat019:
    NOTE 2, D6, $26
    NOTE 2, Cs6, $26
    NOTE 2, B5, $26
    NOTE 2, Fs5, $26
    NOTE 2, D6, $27
    NOTE 2, Cs6, $26
    NOTE 2, B5, $26
    NOTE 2, Fs5, $26
    NOTE 4, A5, $26
    NOTE 1, Fs5, $26
    KEYOFF 1
    NOTE 2, Fs5, $26
    NOTE 2, D6, $27
    NOTE 2, Cs6, $26
    NOTE 4, B5, $26
    NOTE 2, D6, $1B
    NOTE 2, Cs6, $1B
    NOTE 2, B5, $1B
    NOTE 2, D6, $1B
    NOTE 2, Cs6, $1B
    NOTE 2, B5, $1B
    NOTE 2, A5, $1B
    NOTE 2, Fs5, $1B
    NOTE 2, A5, $1B
    NOTE 2, B5, $1B
    NOTE 1, Fs5, $1B
    KEYOFF 1
    NOTE 2, Fs5, $1B
    NOTE 2, D6, $1B
    NOTE 2, Cs6, $1B
    NOTE 4, B5, $1B
    PATEND

Pat020:
    NOTE 2, D6, $27
    NOTE 2, Cs6, $26
    NOTE 2, B5, $26
    NOTE 2, A5, $26
    NOTE 2, Fs5, $26
    KEYOFF 2
    NOTE 1, A5, $26
    KEYOFF 1
    NOTE 4, B5, $26
    NOTE 3, D6, $26
    KEYOFF 1
    NOTE 1, D6, $26
    KEYOFF 1
    NOTE 1, Cs6, $26
    KEYOFF 1
    NOTE 2, Cs6, $26
    NOTE 4, B5, $26
    NOTE 2, D6, $27
    NOTE 2, Cs6, $26
    NOTE 2, B5, $26
    NOTE 2, A5, $26
    NOTE 16, Fs5, $26
    NOTE 4, D6, $26
    NOTE 4, Cs6, $26
    PATEND

Pat021:
    NOTE 2, D6, $26
    NOTE 2, Cs6, $26
    NOTE 8, B5, $27
    NOTE 4, Fs5, $26
    NOTE 2, D6, $27
    NOTE 2, Cs6, $26
    NOTE 8, B5, $3B
    NOTE 4, Fs5, $26
    NOTE 2, B5, $26
    KEYOFF 2
    NOTE 2, Cs6, $27
    NOTE 10, B5, $3B
    NOTE 8, A5, $3B
    NOTE 1, Fs5, $26
    KEYOFF 1
    NOTE 2, Fs5, $26
    NOTE 2, D6, $26
    NOTE 2, Cs6, $26
    PATEND

Pat022:
    NOTE 16, B4, $3B
    NOTE 2, D5, $3B
    NOTE 1, Cs5, $3B
    NOTE 1, A4, $3B
    NOTE 12, B4, $3B
    NOTE 2, D5, $3B
    NOTE 2, Cs5, $3B
    NOTE 8, Fs4, $3B
    NOTE 4, B4, $3B
    NOTE 4, Fs5, $1B
    NOTE 4, Fs5, $1B
    NOTE 2, Fs5, $1B
    NOTE 1, B5, $1B
    KEYOFF 1
    NOTE 2, B5, $1B
    NOTE 2, Cs6, $1B
    SONGJUMP Song01_Ch3

Song01_Ch4:
    STEP 0, $017
    STEP 0, $017
    STEP 0, $017
    STEP 0, $01A
    STEP 0, $017
    STEP 0, $01A
    STEP 0, $01B
    STEP 0, $01C

Pat023:
    NOTE 1, $30, $02
    NOTE 1, $48, $03
    NOTE 1, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $30, $01
    NOTE 1, $48, $03
    NOTE 1, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $48, $03
    NOTE 1, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $48, $03
    NOTE 2, $30, $01
    NOTE 2, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $48, $03
    NOTE 1, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $30, $01
    NOTE 1, $48, $03
    NOTE 1, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $48, $03
    NOTE 1, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $48, $03
    NOTE 2, $30, $01
    NOTE 2, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $48, $03
    NOTE 1, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $30, $01
    NOTE 1, $48, $03
    NOTE 1, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $48, $03
    NOTE 1, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $48, $03
    NOTE 2, $30, $01
    NOTE 2, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $48, $03
    NOTE 1, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $30, $01
    NOTE 1, $48, $03
    NOTE 1, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $48, $03
    NOTE 1, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $48, $03
    NOTE 2, $30, $01
    NOTE 2, $48, $03
    PATEND

Pat026:
    NOTE 1, $30, $02
    NOTE 1, $48, $03
    NOTE 1, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $30, $01
    NOTE 1, $48, $03
    NOTE 1, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $48, $03
    NOTE 1, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $48, $03
    db $02 ; part of note
NoiseCtl_5379:
    db $30, $01 ; part of note
    NOTE 2, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $48, $03
    NOTE 1, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $30, $01
    NOTE 1, $48, $03
    NOTE 1, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $48, $03
    NOTE 1, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $48, $03
    NOTE 2, $30, $01
    NOTE 2, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $48, $03
    NOTE 1, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $30, $01
    NOTE 1, $48, $03
    NOTE 1, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $48, $03
    NOTE 1, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $48, $03
    NOTE 2, $30, $01
    NOTE 2, $48, $03
    NOTE 2, $30, $02
    NOTE 1, $30, $01
    NOTE 1, $30, $01
    NOTE 1, $30, $01
    NOTE 1, $48, $03
    NOTE 1, $48, $03
    NOTE 1, $30, $02
    NOTE 1, $48, $03
    NOTE 1, $30, $01
    NOTE 1, $30, $01
    NOTE 1, $30, $01
    NOTE 2, $30, $01
    NOTE 2, $30, $01
    PATEND

Pat027:
    NOTE 3, $30, $02
    NOTE 1, $30, $02
    NOTE 3, $30, $01
    NOTE 3, $30, $02
    NOTE 2, $30, $02
    NOTE 3, $30, $01
    NOTE 1, $30, $01
    NOTE 3, $30, $02
    NOTE 1, $30, $02
    NOTE 3, $30, $01
    NOTE 3, $30, $02
    NOTE 2, $30, $02
    NOTE 4, $30, $01
    NOTE 3, $30, $02
    NOTE 1, $30, $02
    NOTE 3, $30, $01
    NOTE 3, $30, $02
    NOTE 2, $30, $02
    NOTE 3, $30, $01
    NOTE 1, $30, $01
    NOTE 3, $30, $02
    NOTE 1, $30, $02
    NOTE 2, $30, $01
    NOTE 1, $30, $01
    NOTE 3, $30, $02
    NOTE 2, $30, $02
    NOTE 1, $30, $01
    NOTE 1, $30, $01
    NOTE 2, $30, $01
    PATEND

Pat028:
    NOTE 3, $30, $02
    NOTE 1, $30, $02
    NOTE 3, $30, $01
    NOTE 3, $30, $02
    NOTE 2, $30, $02
    NOTE 3, $30, $01
    NOTE 1, $30, $01
    NOTE 3, $30, $02
    NOTE 1, $30, $02
    NOTE 3, $30, $01
    NOTE 3, $30, $02
    NOTE 2, $30, $02
    NOTE 4, $30, $01
    NOTE 3, $30, $02
    NOTE 1, $30, $02
    NOTE 3, $30, $01
    NOTE 3, $30, $02
    NOTE 2, $30, $02
    NOTE 3, $30, $01
    NOTE 1, $30, $01
    NOTE 3, $30, $02
    NOTE 1, $30, $02
    NOTE 2, $30, $01
    NOTE 1, $30, $01
    NOTE 3, $30, $02
    NOTE 2, $30, $02
    NOTE 1, $30, $01
    NOTE 1, $30, $01
    NOTE 2, $30, $01
    SONGJUMP Song01_Ch4

Song02_Ch1:
    STEP 0, $01D
    STEP 0, $01D
    STEP 0, $01F
    STEP 0, $01F
    STEP 0, $01F
    STEP 0, $026
    STEP 0, $027
    STEP 0, $029
    STEP 0, $021
    STEP 0, $023
    STEP 0, $024

    ; $54D8-$54D9: 2 unreferenced bytes
    db $6F, $6D

Pat029:
    NOTE 4, D2, $05
    NOTE 4, F2, $04
    NOTE 3, As2, $05
    NOTE 3, A2, $04
    NOTE 2, G2, $05
    NOTE 4, D2, $04
    NOTE 4, F2, $05
    NOTE 3, As2, $04
    NOTE 5, A2, $05
    NOTE 4, D2, $04
    NOTE 4, F2, $05
    NOTE 3, As2, $04
    NOTE 3, A2, $05
    NOTE 2, G2, $04
    NOTE 4, D2, $05
    NOTE 4, F2, $04
    NOTE 3, As2, $05
    NOTE 5, A2, $04
    PATEND

Pat031:
    NOTE 2, F2, $05
    NOTE 2, F4, $1C
    NOTE 2, Gs2, $04
    NOTE 2, F4, $1D
    NOTE 2, Cs3, $05
    NOTE 1, F4, $1C
    NOTE 3, C3, $04
    NOTE 2, As2, $05
    NOTE 2, F2, $04
    NOTE 2, F4, $1C
    NOTE 2, Gs2, $05
    NOTE 2, F4, $1D
    NOTE 2, Cs3, $04
    NOTE 1, F4, $1C
    NOTE 3, C3, $05
    NOTE 2, F4, $1D
    NOTE 2, F2, $04
    NOTE 2, F4, $1C
    NOTE 2, Gs2, $05
    NOTE 2, F4, $1D
    NOTE 2, Cs3, $04
    NOTE 1, F4, $1C
    NOTE 3, C3, $05
    NOTE 2, As2, $04
    NOTE 2, F2, $05
    NOTE 2, F4, $1C
    NOTE 2, Gs2, $04
    NOTE 2, F4, $1D
    NOTE 2, Cs3, $05
    NOTE 1, F4, $1C
    NOTE 3, C3, $04
    NOTE 2, F4, $1D
    PATEND

Pat038:
    NOTE 2, F2, $05
    NOTE 4, F4, $1C
    NOTE 4, F4, $1D
    NOTE 4, F4, $1C
    NOTE 4, F4, $1D
    NOTE 4, F4, $1C
    NOTE 4, F4, $1D
    NOTE 4, F4, $1C
    NOTE 4, F4, $1D
    NOTE 4, F4, $1C
    NOTE 4, F4, $1D
    NOTE 4, F4, $1C
    NOTE 4, F4, $1D
    NOTE 4, F4, $1C
    NOTE 4, F4, $1D
    NOTE 4, F4, $1C
    NOTE 2, F4, $1D
    PATEND

Pat039:
    HOLD 2
    NOTE 4, F4, $1C
    NOTE 4, F4, $1D
    NOTE 4, F4, $1C
    NOTE 4, F4, $1D
    NOTE 4, F4, $1C
    NOTE 4, F4, $1D
    NOTE 4, F4, $1C
    NOTE 4, F4, $1D
    NOTE 4, F4, $1C
    NOTE 4, F4, $1D
    NOTE 4, F4, $1C
    NOTE 4, F4, $1D
    NOTE 4, F4, $1C
    NOTE 4, F4, $1D
    NOTE 4, F4, $1C
    NOTE 2, F4, $1D
    PATEND

Pat041:
    HOLD 2
    NOTE 4, D4, $1C
    NOTE 4, D4, $1D
    NOTE 4, D4, $1C
    NOTE 4, D4, $1D
    NOTE 4, D4, $1C
    NOTE 4, D4, $1D
    NOTE 4, D4, $1C
    NOTE 4, D4, $1D
    NOTE 4, D4, $1C
    NOTE 4, D4, $1D
    NOTE 4, D4, $1C
    NOTE 4, D4, $1D
    NOTE 4, D4, $1C
    NOTE 10, D4, $1D
    PATEND

Pat033:
    NOTE 2, F2, $05
    NOTE 2, F4, $1C
    NOTE 2, Gs2, $04
    NOTE 2, F4, $1D
    NOTE 2, Cs3, $05
    NOTE 1, F4, $1C
    NOTE 3, C3, $04
    NOTE 2, As2, $05
    NOTE 2, F2, $04
    NOTE 2, F4, $1C
    NOTE 2, Gs2, $05
    NOTE 2, F4, $1D
    NOTE 2, Cs3, $04
    NOTE 1, F4, $1C
    NOTE 3, C3, $05
    NOTE 2, F4, $1D
    NOTE 2, G2, $04
    NOTE 2, G4, $1C
    NOTE 2, As2, $05
    NOTE 2, G4, $1D
    NOTE 2, Ds3, $04
    NOTE 1, G4, $1C
    NOTE 3, D3, $05
    NOTE 2, C3, $04
    NOTE 2, G2, $05
    NOTE 2, G4, $1C
    NOTE 2, As2, $04
    NOTE 2, G4, $1D
    NOTE 2, Ds3, $05
    NOTE 1, G4, $1C
    NOTE 3, D3, $04
    NOTE 2, G4, $1D
    PATEND

Pat035:
    NOTE 4, E2, $05
    NOTE 4, G2, $04
    NOTE 3, C3, $05
    NOTE 3, B2, $04
    NOTE 2, A2, $05
    NOTE 4, E2, $04
    NOTE 4, G2, $05
    NOTE 3, C3, $04
    NOTE 5, B2, $05
    NOTE 4, D3, $04
    NOTE 4, F2, $05
    NOTE 3, As2, $04
    NOTE 3, A2, $05
    NOTE 2, G2, $04
    NOTE 4, D3, $05
    NOTE 4, F2, $04
    NOTE 3, As2, $05
    NOTE 5, A2, $04
    PATEND

Pat036:
    NOTE 4, D2, $05
    NOTE 4, F2, $04
    NOTE 3, As2, $05
    NOTE 3, A2, $04
    NOTE 2, G2, $05
    NOTE 4, D2, $04
    NOTE 4, F2, $05
    NOTE 3, As2, $04
    NOTE 5, A2, $05
    NOTE 4, D2, $04
    NOTE 4, F2, $05
    NOTE 3, As2, $04
    NOTE 3, A2, $05
    NOTE 2, G2, $04
    NOTE 4, D2, $05
    NOTE 4, F2, $04
    NOTE 3, As2, $05
    NOTE 5, A2, $04
    SONGJUMP Song02_Ch1

Song02_Ch2:
    STEP 0, $02A
    STEP 0, $02A
    STEP 0, $02C
    STEP 0, $02C
    STEP 0, $02C
    STEP 0, $02C
    STEP 0, $02C
    STEP 0, $036
    STEP 0, $02E
    STEP 0, $030
    STEP 0, $031

    ; $5703-$5704: 2 unreferenced bytes
    db $79, $00

Pat042:
    NOTE 1, D4, $07
    NOTE 7, D4, $30
    NOTE 1, F4, $09
    NOTE 5, F4, $39
    NOTE 1, E4, $07
    NOTE 1, E4, $30
    NOTE 1, D4, $07
    NOTE 7, D4, $30
    NOTE 1, F4, $09
    NOTE 7, F4, $39
    NOTE 1, D4, $07
    NOTE 7, D4, $30
    NOTE 1, F4, $09
    NOTE 5, F4, $39
    NOTE 1, E4, $07
    NOTE 1, E4, $30
    NOTE 1, D4, $07
    NOTE 7, D4, $30
    NOTE 1, F4, $09
    NOTE 7, F4, $39
    PATEND

Pat044:
    NOTE 1, F4, $07
    NOTE 7, F4, $30
    NOTE 1, Gs4, $09
    NOTE 5, Gs4, $39
    NOTE 1, G4, $07
    NOTE 1, G4, $30
    NOTE 1, F4, $07
    NOTE 7, F4, $30
    NOTE 1, Gs4, $09
    NOTE 7, Gs4, $39
    NOTE 1, F4, $07
    NOTE 7, F4, $30
    NOTE 1, Gs4, $09
    NOTE 5, Gs4, $39
    NOTE 1, G4, $07
    NOTE 1, G4, $30
    NOTE 1, F4, $07
    NOTE 7, F4, $30
    NOTE 1, Gs4, $09
    NOTE 7, Gs4, $39
    PATEND

Pat054:
    NOTE 1, F4, $07
    NOTE 7, F4, $30
    NOTE 1, F4, $09
    NOTE 5, F4, $39
    NOTE 1, E4, $07
    NOTE 1, E4, $30
    NOTE 1, D4, $07
    NOTE 7, D4, $30
    NOTE 1, F4, $09
    NOTE 7, F4, $39
    NOTE 1, D4, $07
    NOTE 7, D4, $30
    NOTE 1, F4, $09
    NOTE 5, F4, $39
    NOTE 1, E4, $07
    NOTE 1, E4, $30
    NOTE 1, D4, $07
    NOTE 7, D4, $30
    NOTE 1, F4, $09
    NOTE 7, F4, $39
    PATEND

Pat046:
    NOTE 1, F4, $07
    NOTE 7, F4, $30
    NOTE 1, Gs4, $09
    NOTE 5, Gs4, $39
    NOTE 1, G4, $07
    NOTE 1, G4, $30
    NOTE 1, F4, $07
    NOTE 7, F4, $30
    NOTE 1, Gs4, $09
    NOTE 7, Gs4, $39
    NOTE 1, G4, $07
    NOTE 7, G4, $30
    NOTE 1, As4, $09
    NOTE 5, As4, $39
    NOTE 1, A4, $07
    NOTE 1, A4, $30
    NOTE 1, G4, $07
    NOTE 7, G4, $30
    NOTE 1, As4, $09
    NOTE 7, As4, $39
    PATEND

Pat048:
    NOTE 1, E4, $07
    NOTE 7, E4, $30
    NOTE 1, G4, $09
    NOTE 5, G4, $39
    NOTE 1, Fs4, $07
    NOTE 1, Fs4, $30
    NOTE 1, E4, $07
    NOTE 7, E4, $30
    NOTE 1, G4, $09
    NOTE 7, G4, $39
    NOTE 1, D4, $07
    NOTE 7, D4, $30
    NOTE 1, F4, $09
    NOTE 5, F4, $39
    NOTE 1, E4, $07
    NOTE 1, E4, $30
    NOTE 1, D4, $07
    NOTE 7, D4, $30
    NOTE 1, F4, $09
    NOTE 7, F4, $39
    PATEND

Pat049:
    NOTE 1, D4, $07
    NOTE 7, D4, $30
    NOTE 1, F4, $09
    NOTE 5, F4, $39
    NOTE 1, E4, $07
    NOTE 1, E4, $30
    NOTE 1, D4, $07
    NOTE 7, D4, $30
    NOTE 1, F4, $09
    NOTE 7, F4, $39
    NOTE 1, D4, $07
    NOTE 7, D4, $30
    NOTE 1, F4, $09
    NOTE 5, F4, $39
    NOTE 1, E4, $07
    NOTE 1, E4, $30
    NOTE 1, D4, $07
    NOTE 7, D4, $30
    NOTE 1, F4, $09
    NOTE 7, F4, $39
    SONGJUMP Song02_Ch2

Song02_Ch3:
    STEP 0, $037
    STEP 0, $038
    STEP 0, $039
    STEP 0, $03A
    STEP 0, $03F
    STEP 0, $040
    STEP 0, $041
    STEP 0, $043
    STEP 0, $03B
    STEP 0, $03D
    STEP 0, $03E

    ; $58A1-$58A2: 2 unreferenced bytes
    db $62, $61

Pat055:
    NOTE 1, D4, $1B
    NOTE 1, E4, $1B
    NOTE 2, F4, $1B
    NOTE 2, G4, $1B
    NOTE 2, A4, $1B
    NOTE 3, F4, $1B
    NOTE 1, D4, $1B
    NOTE 4, D4, $1B
    NOTE 1, D4, $1B
    NOTE 1, E4, $1B
    NOTE 2, F4, $1B
    NOTE 2, G4, $1B
    NOTE 2, A4, $1B
    NOTE 8, F4, $1B
    NOTE 1, D4, $1B
    NOTE 1, E4, $1B
    NOTE 2, F4, $1B
    NOTE 2, G4, $1B
    NOTE 2, A4, $1B
    NOTE 3, F4, $1B
    NOTE 1, D4, $1B
    NOTE 4, D4, $1B
    NOTE 1, D4, $1B
    NOTE 1, E4, $1B
    NOTE 2, F4, $1B
    NOTE 3, F4, $1B
    NOTE 1, E4, $1B
    NOTE 1, F4, $1B
    NOTE 2, E4, $1B
    NOTE 2, C4, $1B
    NOTE 1, As3, $1B
    NOTE 2, C4, $1B
    PATEND

Pat056:
    NOTE 1, D4, $1B
    NOTE 1, E4, $1B
    NOTE 2, F4, $1B
    NOTE 2, G4, $1B
    NOTE 2, A4, $1B
    NOTE 3, F4, $1B
    NOTE 1, D4, $1B
    NOTE 4, D4, $1B
    NOTE 1, D4, $1B
    NOTE 1, E4, $1B
    NOTE 2, F4, $1B
    NOTE 2, G4, $1B
    NOTE 2, A4, $1B
    NOTE 8, F4, $1B
    NOTE 1, F4, $1B
    NOTE 1, E4, $1B
    NOTE 2, D4, $1B
    NOTE 2, C4, $1B
    NOTE 2, A3, $1B
    NOTE 3, As3, $1B
    NOTE 1, A3, $1B
    NOTE 4, A3, $1B
    NOTE 1, C4, $1B
    NOTE 1, A3, $1B
    NOTE 2, G3, $1B
    NOTE 3, A3, $1B
    NOTE 1, C4, $1B
    NOTE 1, F4, $1B
    NOTE 7, D4, $1B
    PATEND

Pat057:
    NOTE 1, F4, $1B
    NOTE 1, G4, $1B
    NOTE 2, Gs4, $1B
    NOTE 2, As4, $1B
    NOTE 2, C5, $1B
    NOTE 3, Gs4, $1B
    NOTE 1, F4, $1B
    NOTE 4, F4, $1B
    NOTE 1, F4, $1B
    NOTE 1, G4, $1B
    NOTE 2, Gs4, $1B
    NOTE 2, As4, $1B
    NOTE 2, C5, $1B
    NOTE 8, Gs4, $1B
    NOTE 1, F4, $1B
    NOTE 1, G4, $1B
    NOTE 2, Gs4, $1B
    NOTE 2, As4, $1B
    NOTE 2, C5, $1B
    NOTE 3, Gs4, $1B
    NOTE 1, F4, $1B
    NOTE 4, F4, $1B
    NOTE 1, F4, $1B
    NOTE 1, G4, $1B
    NOTE 2, Gs4, $1B
    NOTE 3, Gs4, $1B
    NOTE 1, G4, $1B
    NOTE 1, Gs4, $1B
    NOTE 2, G4, $1B
    NOTE 2, Cs4, $1B
    NOTE 1, Ds4, $1B
    NOTE 2, F4, $1B
    PATEND

Pat058:
    NOTE 1, Gs4, $1B
    NOTE 1, G4, $1B
    NOTE 2, F4, $1B
    NOTE 2, Gs4, $1B
    NOTE 2, C5, $1B
    NOTE 3, Gs4, $1B
    NOTE 1, F4, $1B
    NOTE 4, F4, $1B
    NOTE 1, F4, $1B
    NOTE 1, G4, $1B
    NOTE 2, Gs4, $1B
    NOTE 2, As4, $1B
    NOTE 2, C5, $1B
    NOTE 8, Gs4, $1B
    NOTE 1, Gs5, $1B
    NOTE 1, As5, $1B
    NOTE 2, C6, $1B
    NOTE 1, Gs5, $1B
    NOTE 1, As5, $1B
    NOTE 2, C6, $1B
    NOTE 3, F6, $1B
    NOTE 3, C6, $1B
    NOTE 2, As5, $1B
    NOTE 1, Gs5, $1B
    NOTE 1, As5, $1B
    NOTE 2, C6, $1B
    NOTE 1, Gs5, $1B
    NOTE 1, As5, $1B
    NOTE 2, C6, $1B
    NOTE 1, G6, $1B
    NOTE 1, Gs6, $1B
    NOTE 1, G6, $1B
    NOTE 3, F6, $1B
    NOTE 2, Ds6, $1B
    PATEND

Pat063:
    NOTE 1, Gs5, $1B
    NOTE 1, As5, $1B
    NOTE 2, C6, $1B
    NOTE 1, Gs5, $1B
    NOTE 1, As5, $1B
    NOTE 2, C6, $1B
    NOTE 3, F6, $1B
    NOTE 3, C6, $1B
    NOTE 2, As5, $1B
    NOTE 1, Gs5, $1B
    NOTE 1, As5, $1B
    NOTE 2, C6, $1B
    NOTE 1, Gs5, $1B
    NOTE 1, As5, $1B
    NOTE 2, C6, $1B
    NOTE 1, G6, $1B
    NOTE 1, Gs6, $1B
    NOTE 1, G6, $1B
    NOTE 3, F6, $1B
    NOTE 2, Ds6, $1B
    NOTE 1, Gs5, $1B
    NOTE 1, As5, $1B
    NOTE 2, C6, $1B
    NOTE 1, Gs5, $1B
    NOTE 1, As5, $1B
    NOTE 2, C6, $1B
    NOTE 3, F6, $1B
    NOTE 3, C6, $1B
    NOTE 2, As5, $1B
    NOTE 1, Gs5, $1B
    NOTE 1, As5, $1B
    NOTE 2, C6, $1B
    NOTE 1, Gs5, $1B
    NOTE 1, As5, $1B
    NOTE 2, C6, $1B
    NOTE 1, G6, $1B
    NOTE 1, Gs6, $1B
    NOTE 1, G6, $1B
    NOTE 3, F6, $1B
    NOTE 2, Ds6, $1B
    PATEND

Pat064:
    NOTE 14, F5, $1B
    NOTE 2, Ds6, $1B
    NOTE 14, C6, $1B
    NOTE 2, Ds6, $1B
    NOTE 14, F5, $1B
    NOTE 2, Ds6, $1B
    NOTE 3, C6, $1B
    NOTE 2, As5, $1B
    NOTE 1, Gs5, $1B
    NOTE 2, G5, $1B
    NOTE 1, F5, $1B
    NOTE 2, Ds5, $1B
    NOTE 5, Ds5, $1B
    PATEND

Pat065:
    NOTE 14, F5, $1B
    NOTE 2, Ds6, $1B
    NOTE 3, C6, $1B
    NOTE 2, As5, $1B
    NOTE 1, Gs5, $1B
    NOTE 2, G5, $1B
    NOTE 1, F5, $1B
    NOTE 2, Ds5, $1B
    NOTE 5, Ds5, $1B
    NOTE 14, F5, $1B
    NOTE 2, Ds4, $1B
    NOTE 14, F4, $1B
    NOTE 2, Ds4, $1B
    PATEND

Pat067:
    NOTE 4, F4, $1B
    KEYOFF 9
    KEYOFF 5
    KEYOFF 14
    NOTE 2, D4, $2D
    KEYOFF 2
    NOTE 4, D3, $28
    NOTE 6, F3, $29
    KEYOFF 4
    KEYOFF 14
    PATEND

Pat059:
    NOTE 2, F4, $2D
    KEYOFF 2
    NOTE 4, F3, $28
    NOTE 8, Gs3, $29
    NOTE 2, F4, $2D
    KEYOFF 2
    NOTE 4, F3, $28
    NOTE 8, Gs3, $29
    NOTE 2, G4, $2D
    KEYOFF 2
    NOTE 4, G3, $28
    NOTE 8, As3, $29
    NOTE 2, G4, $2D
    KEYOFF 2
    NOTE 4, G3, $28
    NOTE 8, As3, $29
    PATEND

Pat061:
    NOTE 2, E4, $2D
    KEYOFF 2
    NOTE 4, E3, $28
    NOTE 8, G3, $29
    NOTE 2, E4, $2D
    KEYOFF 2
    NOTE 4, E3, $28
    NOTE 8, G3, $29
    NOTE 2, D4, $2D
    KEYOFF 2
    NOTE 4, D3, $28
    NOTE 8, F3, $29
    NOTE 2, D4, $2D
    KEYOFF 2
    NOTE 4, D3, $28
    NOTE 8, F3, $29
    PATEND

Pat062:
    NOTE 14, D3, $2A
    NOTE 2, E3, $2A
    NOTE 16, D3, $2A
    NOTE 14, D3, $2A
    NOTE 2, E3, $2A
    NOTE 4, D3, $2A
    NOTE 4, C3, $2A
    NOTE 3, F4, $1B
    NOTE 1, E4, $1B
    NOTE 1, F4, $1B
    NOTE 1, E4, $1B
    NOTE 2, C4, $1B
    SONGJUMP Song02_Ch3

Song02_Ch4:
    STEP 0, $044
    STEP 0, $045
    STEP 0, $045
    STEP 0, $045
    STEP 0, $045
    STEP 0, $045
    STEP 0, $04E
    STEP 0, $050
    STEP 0, $045
    STEP 0, $045
    STEP 0, $04B

    ; $5BB3-$5BB4: 2 unreferenced bytes
    db $00, $66

Pat068:
    HOLD 64
    PATEND

Pat069:
    HOLD 64
    PATEND

Pat078:
    HOLD 4
    NOTE 1, $26, $03
    NOTE 7, $26, $03
    NOTE 1, $26, $03
    NOTE 7, $26, $03
    NOTE 1, $26, $03
    NOTE 7, $26, $03
    NOTE 1, $26, $03
    NOTE 7, $26, $03
    NOTE 1, $26, $03
    NOTE 7, $26, $03
    NOTE 1, $26, $03
    NOTE 7, $26, $03
    NOTE 1, $26, $03
    NOTE 7, $26, $03
    NOTE 1, $26, $03
    NOTE 3, $26, $03
    PATEND

Pat080:
    HOLD 4
    NOTE 1, $23, $03
    NOTE 7, $23, $03
    NOTE 1, $23, $03
    NOTE 7, $23, $03
    NOTE 1, $23, $03
    NOTE 7, $23, $03
    NOTE 1, $23, $03
    NOTE 7, $23, $03
    NOTE 1, $23, $03
    NOTE 7, $23, $03
    NOTE 1, $23, $03
    NOTE 7, $23, $03
    NOTE 1, $23, $03
    NOTE 7, $23, $03
    NOTE 1, $23, $03
    NOTE 3, $23, $03
    PATEND

Pat075:
    HOLD 64
    SONGJUMP Song02_Ch4

Song03_Ch1:
    STEP 0, $053
    STEP 0, $053
    STEP 0, $053
    STEP 0, $053
    STEP 0, $053
    STEP 0, $053
    STEP 0, $051
    STEP 0, $051
    STEP 0, $051
    STEP 0, $051
    STEP 0, $051
    STEP 0, $051
    STEP 0, $051
    STEP 0, $051
    STEP 0, $051
    STEP 0, $051
    STEP 0, $051
    STEP 0, $051
    STEP 0, $051
    STEP 0, $060

    ; $5C76-$5C77: 2 unreferenced bytes
    db $65, $61

Pat083:
    NOTE 64, C5, $00
    PATEND

Pat081:
    NOTE 16, C4, $39
    NOTE 16, C4, $38
    NOTE 32, C4, $30
    PATEND

Pat096:
    KEYOFF 64
    SONGJUMP Song03_Ch1

Song03_Ch2:
    STEP 0, $061
    STEP 0, $061
    STEP 0, $061
    STEP 0, $06E
    STEP 0, $06E
    STEP 0, $06E
    STEP 0, $061
    STEP 0, $067
    STEP 0, $067
    STEP 0, $067
    STEP 0, $067
    STEP 0, $067
    STEP 0, $067
    STEP 0, $067
    STEP 0, $067
    STEP 0, $067
    STEP 0, $067
    STEP 0, $06E
    STEP 0, $06E
    STEP 0, $070

    ; $5CDB-$5CDC: 2 unreferenced bytes
    db $00, $63

Pat097:
    NOTE 2, C2, $04
    NOTE 2, C2, $04
    NOTE 10, C2, $04
    NOTE 2, F2, $04
    NOTE 2, Ds2, $04
    NOTE 12, Ds2, $04
    NOTE 2, F2, $04
    NOTE 2, Ds2, $04
    NOTE 2, D2, $04
    NOTE 12, C2, $04
    NOTE 2, F2, $04
    NOTE 2, Ds2, $04
    NOTE 2, D2, $04
    NOTE 10, C2, $04
    PATEND

Pat110:
    HOLD 8
    NOTE 2, D5, $1F
    NOTE 2, D5, $1F
    NOTE 52, D5, $1F
    PATEND

Pat103:
    NOTE 2, C2, $04
    NOTE 2, C2, $04
    NOTE 4, C2, $04
    NOTE 6, D5, $1F
    NOTE 2, F2, $04
    NOTE 2, Ds2, $04
    NOTE 6, Ds2, $04
    NOTE 6, D5, $1F
    NOTE 2, F2, $04
    NOTE 2, Ds2, $04
    NOTE 2, D2, $04
    NOTE 4, C2, $04
    NOTE 6, D5, $1F
    NOTE 2, F2, $04
    NOTE 2, Ds2, $04
    NOTE 2, D2, $04
    NOTE 4, C2, $04
    NOTE 8, D5, $1F
    PATEND

Pat112:
    HOLD 8
    NOTE 2, D5, $1F
    NOTE 2, D5, $1F
    NOTE 52, D5, $1F
    SONGJUMP Song03_Ch2

Song07_Ch1:
    STEP 0, $062
    STEP 0, $004

Pat098:
    NOTE 2, Ds2, $04
    NOTE 2, Ds3, $04
    NOTE 2, C4, $1D
    NOTE 2, Ds2, $04
    NOTE 2, Ds3, $04
    NOTE 2, Ds2, $04
    NOTE 2, C4, $1D
    NOTE 2, Ds3, $04
    NOTE 2, Cs2, $04
    NOTE 2, Cs3, $04
    NOTE 2, C4, $1D
    NOTE 2, Cs2, $04
    NOTE 2, Ds3, $04
    NOTE 2, Cs2, $04
    NOTE 2, C4, $1D
    NOTE 2, As2, $04
    NOTE 2, Ds2, $04
    NOTE 2, Ds3, $04
    NOTE 2, C4, $1D
    NOTE 2, Ds2, $04
    NOTE 2, Ds3, $04
    NOTE 2, Ds2, $04
    NOTE 2, C4, $1D
    NOTE 2, Ds3, $04
    NOTE 2, Fs2, $04
    NOTE 2, Fs3, $04
    NOTE 2, C4, $1D
    NOTE 2, As2, $04
    NOTE 2, Gs2, $04
    NOTE 2, Gs3, $04
    NOTE 2, C4, $1D
    NOTE 2, As3, $04
    NOTE 16, Ds2, $04
    PATEND

Song07_Ch2:
    STEP 0, $063
    STEP 0, $004

Pat099:
    NOTE 2, Ds3, $21
    NOTE 1, Ds3, $21
    NOTE 1, Ds3, $21
    NOTE 2, Ds3, $21
    NOTE 2, Ds4, $21
    NOTE 2, Ds3, $21
    NOTE 1, Ds3, $21
    NOTE 1, Ds3, $21
    NOTE 2, Ds3, $21
    NOTE 2, Ds4, $21
    NOTE 2, Cs3, $21
    NOTE 1, Cs3, $21
    NOTE 1, Cs3, $21
    NOTE 2, Cs3, $21
    NOTE 2, Cs4, $21
    NOTE 2, Cs3, $21
    NOTE 1, Cs3, $21
    NOTE 1, Cs3, $21
    NOTE 2, Cs3, $21
    NOTE 2, Cs4, $21
    NOTE 2, Ds3, $21
    NOTE 1, Ds3, $21
    NOTE 1, Ds3, $21
    NOTE 2, Ds3, $21
    NOTE 2, Ds4, $21
    NOTE 2, Ds3, $21
    NOTE 1, Ds3, $21
    NOTE 1, Ds3, $21
    NOTE 2, Ds3, $21
    NOTE 2, Ds4, $21
    NOTE 2, Fs3, $21
    NOTE 1, Fs3, $21
    NOTE 1, Fs3, $21
    NOTE 2, Fs3, $21
    NOTE 2, Fs4, $21
    NOTE 2, Gs3, $21
    NOTE 1, Gs3, $21
    NOTE 1, Gs3, $21
    NOTE 2, Gs3, $21
    NOTE 2, Gs4, $21
    NOTE 16, Ds3, $21
    PATEND

Song07_Ch3:
    STEP 0, $064
    STEP 0, $002

Pat100:
    NOTE 2, Fs4, $26
    KEYOFF 2
    NOTE 2, Fs4, $26
    KEYOFF 2
    NOTE 4, Gs4, $27
    NOTE 4, Fs4, $26
    NOTE 1, Ds5, $26
    KEYOFF 1
    NOTE 2, Cs5, $26
    NOTE 2, Ds5, $26
    KEYOFF 2
    NOTE 4, Fs5, $27
    NOTE 2, Gs5, $26
    KEYOFF 2
    NOTE 1, As5, $26
    KEYOFF 1
    NOTE 1, Gs5, $26
    NOTE 1, Fs5, $26
    NOTE 1, Gs5, $26
    NOTE 1, As5, $26
    NOTE 2, Gs5, $26
    NOTE 2, As5, $26
    KEYOFF 2
    NOTE 2, As5, $26
    KEYOFF 2
    NOTE 4, Ds6, $27
    NOTE 2, As5, $26
    KEYOFF 2
    NOTE 2, Gs5, $26
    NOTE 2, Fs5, $26
    NOTE 2, Gs5, $26
    NOTE 2, As5, $26
    NOTE 9, Ds5, $26
    KEYOFF 7
    PATEND

Song07_Ch4:
    STEP 0, $065
    STEP 0, $004

Pat101:
    NOTE 2, $32, $02
    NOTE 2, $32, $03
    NOTE 2, $32, $01
    NOTE 2, $32, $03
    NOTE 2, $32, $02
    NOTE 2, $32, $02
    NOTE 2, $32, $01
    NOTE 2, $32, $03
    NOTE 2, $32, $02
    NOTE 2, $32, $03
    NOTE 2, $32, $01
    NOTE 2, $32, $03
    NOTE 2, $32, $02
    NOTE 2, $32, $02
    NOTE 2, $32, $01
    NOTE 2, $32, $03
    NOTE 2, $32, $02
    NOTE 2, $32, $03
    NOTE 2, $32, $01
    NOTE 2, $32, $03
    NOTE 2, $32, $02
    NOTE 2, $32, $02
    NOTE 2, $32, $01
    NOTE 2, $32, $03
    NOTE 2, $32, $02
    NOTE 2, $32, $03
    NOTE 2, $32, $01
    NOTE 2, $32, $03
    NOTE 2, $32, $02
    NOTE 2, $32, $02
    NOTE 2, $32, $01
    NOTE 2, $32, $03
    NOTE 16, $32, $02
    PATEND

Song03_Ch3:
    STEP 0, $072
    STEP 0, $072
    STEP 0, $074
    STEP 0, $075
    STEP 0, $075
    STEP 0, $075
    STEP 0, $072
    STEP 0, $072
    STEP 0, $078
    STEP 0, $078
    STEP 0, $079
    STEP 0, $07A
    STEP 0, $07A
    STEP 0, $07E
    STEP 0, $07B
    STEP 0, $07C
    STEP 0, $07D
    STEP 0, $079
    STEP 0, $079
    STEP 0, $080

    ; $5F6A-$5F6B: 2 unreferenced bytes
    db $00, $00

Pat114:
    NOTE 14, C3, $2A
    NOTE 2, F3, $2D
    NOTE 14, Ds3, $2A
    NOTE 2, F3, $2D
    NOTE 32, C3, $2A
    PATEND

Pat116:
    NOTE 14, C3, $2A
    NOTE 2, F3, $2D
    NOTE 14, Ds3, $2A
    NOTE 2, F3, $2D
    NOTE 16, C3, $2A
    NOTE 2, Ds2, $2B
    NOTE 2, D2, $2A
    NOTE 12, C2, $2A
    PATEND

Pat117:
    HOLD 64
    PATEND

Pat120:
    NOTE 6, C3, $2A
    NOTE 2, As3, $2B
    NOTE 4, C4, $2C
    KEYOFF 2
    NOTE 2, F3, $2D
    NOTE 8, Ds3, $2A
    NOTE 6, Ds4, $2A
    NOTE 2, F3, $2D
    NOTE 8, C3, $2A
    NOTE 2, C4, $1B
    NOTE 2, C4, $1B
    NOTE 4, C4, $1B
    NOTE 2, C5, $1B
    NOTE 2, C5, $1B
    NOTE 4, C5, $1B
    NOTE 2, C6, $1B
    NOTE 2, C6, $1B
    NOTE 4, C6, $1B
    PATEND

Pat121:
    HOLD 12
    KEYOFF 28
    NOTE 2, C4, $1B
    NOTE 2, C4, $1B
    NOTE 4, C4, $1B
    NOTE 2, C5, $1B
    NOTE 2, C5, $1B
    NOTE 4, C5, $1B
    NOTE 2, C6, $1B
    NOTE 2, C6, $1B
    NOTE 4, C6, $1B
    PATEND

Pat122:
    NOTE 16, C4, $26
    NOTE 16, Ds4, $26
    NOTE 4, D4, $26
    NOTE 4, Ds4, $27
    NOTE 2, C4, $1B
    NOTE 2, C4, $1B
    NOTE 4, C4, $1B
    NOTE 2, C5, $1B
    NOTE 2, C5, $1B
    NOTE 4, C5, $1B
    NOTE 2, C6, $1B
    NOTE 2, C6, $1B
    NOTE 4, C6, $1B
    PATEND

Pat126:
    NOTE 6, C4, $27
    NOTE 10, Ds4, $27
    NOTE 2, Ds4, $27
    NOTE 4, F4, $27
    NOTE 10, Ds4, $27
    NOTE 8, C4, $27
    NOTE 2, C4, $1B
    NOTE 2, C4, $1B
    NOTE 4, C4, $1B
    NOTE 2, C5, $1B
    NOTE 2, C5, $1B
    NOTE 4, C5, $1B
    NOTE 2, C6, $1B
    NOTE 2, C6, $1B
    NOTE 4, C6, $1B
    PATEND

Pat123:
    NOTE 6, C4, $26
    NOTE 6, G4, $27
    NOTE 4, F4, $27
    NOTE 6, Ds4, $26
    NOTE 6, Gs4, $27
    NOTE 4, F4, $27
    NOTE 4, D4, $26
    NOTE 4, Ds4, $27
    NOTE 2, C4, $1B
    NOTE 2, C4, $1B
    NOTE 4, C4, $1B
    NOTE 2, C5, $1B
    NOTE 2, C5, $1B
    NOTE 4, C5, $1B
    NOTE 2, C6, $1B
    NOTE 2, C6, $1B
    NOTE 4, C6, $1B
    PATEND

Pat124:
    NOTE 6, C4, $26
    NOTE 6, G4, $27
    NOTE 2, G4, $27
    NOTE 2, F4, $27
    NOTE 2, Ds4, $26
    NOTE 4, F4, $27
    NOTE 6, Gs4, $27
    NOTE 4, F4, $27
    NOTE 4, D4, $26
    NOTE 4, Ds4, $27
    NOTE 2, C4, $1B
    NOTE 2, C4, $1B
    NOTE 4, C4, $1B
    NOTE 2, C5, $1B
    NOTE 2, C5, $1B
    NOTE 4, C5, $1B
    NOTE 2, C6, $1B
    NOTE 2, C6, $1B
    NOTE 4, C6, $1B
    PATEND

Pat125:
    NOTE 6, G4, $27
    NOTE 10, F4, $27
    NOTE 2, Ds4, $27
    NOTE 4, F4, $27
    NOTE 10, Ds4, $27
    NOTE 8, C4, $27
    NOTE 2, C4, $1B
    NOTE 2, C4, $1B
    NOTE 4, C4, $1B
    NOTE 2, C5, $1B
    NOTE 2, C5, $1B
    NOTE 4, C5, $1B
    NOTE 2, C6, $1B
    NOTE 2, C6, $1B
    NOTE 4, C6, $1B
    PATEND

Pat128:
    HOLD 64
    SONGJUMP Song03_Ch3

Song03_Ch4:
    STEP 0, $081

Pat129:
    NOTE 2, $24, $01
    NOTE 2, $24, $01
    NOTE 12, $24, $01
    NOTE 2, $24, $03
    NOTE 14, $24, $03
    NOTE 2, $24, $01
    NOTE 2, $24, $01
    NOTE 12, $24, $01
    NOTE 2, $24, $03
    NOTE 14, $24, $03
    SONGJUMP Song03_Ch4

Song04_Ch1:
    STEP 0, $083
    STEP 0, $083
    STEP 0, $085
    STEP 0, $085
    STEP 0, $085
    STEP 0, $083
    STEP 0, $083
    STEP 0, $085
    STEP 0, $085
    STEP 0, $08B
    STEP 0, $08B
    STEP 0, $08B
    STEP 0, $085
    STEP 0, $085
    STEP 0, $083
    STEP 0, $083
    STEP 0, $083
    STEP 0, $08F
    STEP 0, $08F
    STEP 0, $08F
    STEP 0, $08F
    STEP 0, $08F
    STEP 0, $093

    ; $6166-$6167: 2 unreferenced bytes
    db $00, $00

Pat131:
    NOTE 2, C3, $04
    NOTE 12, C3, $05
    NOTE 2, C3, $04
    NOTE 2, A2, $04
    NOTE 12, A2, $05
    NOTE 2, A2, $04
    NOTE 2, C3, $04
    NOTE 12, C3, $05
    NOTE 2, C3, $04
    NOTE 2, A2, $04
    NOTE 12, A2, $05
    NOTE 2, E3, $04
    PATEND

Pat133:
    NOTE 2, D3, $04
    NOTE 12, D3, $05
    NOTE 2, D3, $04
    NOTE 2, G2, $04
    NOTE 12, G2, $05
    NOTE 2, G2, $04
    NOTE 2, D3, $04
    NOTE 12, D3, $05
    NOTE 2, D3, $04
    NOTE 2, G2, $04
    NOTE 12, G2, $05
    NOTE 2, E3, $04
    PATEND

Pat139:
    NOTE 2, C3, $04
    NOTE 4, C3, $05
    NOTE 4, G3, $05
    NOTE 4, G3, $05
    NOTE 2, C3, $04
    NOTE 2, A2, $04
    NOTE 4, A2, $05
    NOTE 4, E3, $05
    NOTE 4, E3, $05
    NOTE 2, A2, $04
    NOTE 2, C3, $04
    NOTE 4, C3, $05
    NOTE 4, G3, $05
    NOTE 4, G3, $05
    NOTE 2, C3, $04
    NOTE 2, A2, $04
    NOTE 4, A2, $05
    NOTE 4, E3, $05
    NOTE 4, E3, $05
    NOTE 2, E3, $04
    PATEND

Pat143:
    NOTE 2, C3, $04
    NOTE 6, C3, $05
    NOTE 4, G3, $05
    NOTE 2, E3, $04
    NOTE 2, C3, $04
    NOTE 2, A2, $04
    NOTE 4, A2, $05
    NOTE 4, C3, $04
    NOTE 4, D3, $04
    NOTE 2, A2, $04
    NOTE 2, C3, $04
    NOTE 4, C3, $05
    NOTE 2, G3, $05
    NOTE 4, G3, $04
    NOTE 2, E3, $04
    NOTE 2, C3, $04
    NOTE 2, A2, $04
    NOTE 8, A2, $05
    NOTE 2, G3, $04
    NOTE 2, F3, $04
    NOTE 2, E3, $04
    PATEND

Pat147:
    NOTE 2, C3, $04
    NOTE 6, C3, $05
    NOTE 4, G3, $05
    NOTE 2, E3, $04
    NOTE 2, C3, $04
    NOTE 2, A2, $04
    NOTE 4, A2, $05
    NOTE 4, C3, $04
    NOTE 4, D3, $04
    NOTE 2, A2, $04
    NOTE 2, C3, $04
    NOTE 4, C3, $05
    NOTE 2, G3, $05
    NOTE 4, G3, $04
    NOTE 2, E3, $04
    NOTE 2, C3, $04
    NOTE 2, A2, $04
    NOTE 8, A2, $05
    NOTE 2, G3, $04
    NOTE 2, F3, $04
    NOTE 2, E3, $04
    SONGJUMP Song04_Ch1

Song04_Ch2:
    STEP 0, $094
    STEP 0, $094
    STEP 0, $097
    STEP 0, $097
    STEP 0, $097
    STEP 0, $094
    STEP 0, $094
    STEP 0, $097
    STEP 0, $097
    STEP 0, $09D
    STEP 0, $09D
    STEP 0, $09E
    STEP 0, $097
    STEP 0, $097
    STEP 0, $094
    STEP 0, $094
    STEP 0, $094
    STEP 0, $09D
    STEP 0, $09D
    STEP 0, $09D
    STEP 0, $09D
    STEP 0, $09D
    STEP 0, $0A5

    ; $62CD-$62CE: 2 unreferenced bytes
    db $65, $73

Pat148:
    HOLD 64
    PATEND

Pat151:
    NOTE 1, F5, $34
    NOTE 1, F5, $34
    NOTE 1, F5, $34
    NOTE 1, F5, $34
    NOTE 1, F5, $34
    NOTE 1, F5, $34
    NOTE 1, F5, $34
    NOTE 1, F5, $34
    NOTE 1, F5, $34
    NOTE 1, F5, $34
    NOTE 1, F5, $34
    NOTE 1, F5, $34
    NOTE 4, E5, $38
    NOTE 1, D5, $39
    NOTE 1, D5, $39
    NOTE 1, D5, $39
    NOTE 1, D5, $39
    NOTE 1, D5, $39
    NOTE 1, D5, $39
    NOTE 1, D5, $39
    NOTE 1, D5, $39
    NOTE 1, D5, $39
    NOTE 1, D5, $39
    NOTE 1, D5, $39
    NOTE 1, D5, $39
    NOTE 1, E5, $38
    KEYOFF 1
    NOTE 2, D5, $39
    NOTE 1, F5, $34
    NOTE 1, F5, $34
    NOTE 1, F5, $34
    NOTE 1, F5, $34
    NOTE 1, F5, $34
    NOTE 1, F5, $34
    NOTE 1, F5, $34
    NOTE 1, F5, $34
    NOTE 1, F5, $34
    NOTE 1, F5, $34
    NOTE 1, F5, $34
    NOTE 1, F5, $34
    NOTE 1, E5, $38
    KEYOFF 1
    NOTE 2, F5, $34
    NOTE 1, D5, $39
    NOTE 1, D5, $39
    NOTE 1, D5, $39
    NOTE 1, D5, $39
    NOTE 1, D5, $39
    NOTE 1, D5, $39
    NOTE 1, D5, $39
    NOTE 1, D5, $39
    NOTE 1, D5, $39
    NOTE 1, D5, $39
    NOTE 1, D5, $39
    NOTE 1, D5, $39
    NOTE 2, F5, $34
    NOTE 2, E5, $38
    PATEND

Pat157:
    NOTE 2, E5, $1F
    NOTE 2, E5, $1F
    NOTE 2, E5, $1F
    NOTE 6, E5, $1F
    NOTE 6, C4, $1D
    NOTE 2, A5, $1F
    NOTE 2, A5, $1F
    NOTE 6, A5, $1F
    NOTE 6, C4, $1D
    NOTE 2, E5, $1F
    NOTE 2, E5, $1F
    NOTE 6, E5, $1F
    NOTE 6, C4, $1D
    NOTE 2, A5, $1F
    NOTE 2, A5, $1F
    NOTE 6, A5, $1F
    NOTE 4, C4, $1D
    PATEND

Pat158:
    NOTE 2, E5, $1F
    NOTE 2, E5, $1F
    NOTE 2, E5, $1F
    NOTE 6, E5, $1F
    NOTE 6, C4, $1D
    NOTE 2, A5, $1F
    NOTE 2, A5, $1F
    NOTE 6, A5, $1F
    NOTE 6, C4, $1D
    NOTE 2, E5, $1F
    NOTE 2, E5, $1F
    NOTE 6, E5, $1F
    NOTE 4, C4, $1D
    NOTE 2, C5, $1C
    NOTE 2, A5, $1F
    NOTE 2, A5, $1F
    NOTE 2, A5, $1F
    NOTE 2, C5, $1C
    NOTE 2, C5, $1C
    NOTE 2, C4, $1D
    NOTE 2, C5, $1C
    PATEND

Pat165:
    NOTE 2, E5, $1F
    NOTE 2, E5, $1F
    NOTE 2, E5, $1F
    NOTE 6, E5, $1F
    NOTE 6, C4, $1D
    NOTE 2, A5, $1F
    NOTE 2, A5, $1F
    NOTE 6, A5, $1F
    NOTE 6, C4, $1D
    NOTE 2, E5, $1F
    NOTE 2, E5, $1F
    NOTE 6, E5, $1F
    NOTE 6, C4, $1D
    NOTE 2, A5, $1F
    NOTE 2, A5, $1F
    NOTE 6, A5, $1F
    NOTE 4, C4, $1D
    SONGJUMP Song04_Ch2

Song04_Ch3:
    STEP 0, $0A6
    STEP 0, $0A8
    STEP 0, $0A9
    STEP 0, $0AA
    STEP 0, $0AB
    STEP 0, $0B2
    STEP 0, $0A8
    STEP 0, $0AC
    STEP 0, $0AD
    STEP 0, $0B1
    STEP 0, $0B1
    STEP 0, $0B0
    STEP 0, $0AC
    STEP 0, $0AD
    STEP 0, $0B2
    STEP 0, $0A8
    STEP 0, $0A6
    STEP 0, $0B3
    STEP 0, $0B4
    STEP 0, $0B4
    STEP 0, $0B5
    STEP 0, $0B6
    STEP 0, $0B7

    ; $6482-$6483: 2 unreferenced bytes
    db $F6, $BF

Pat166:
    HOLD 64
    PATEND

Pat168:
    NOTE 1, C6, $3B
    KEYOFF 1
    NOTE 3, C6, $3B
    KEYOFF 1
    NOTE 2, C6, $3B
    NOTE 2, D6, $3C
    NOTE 2, E6, $3B
    NOTE 4, C6, $3B
    NOTE 1, A5, $3B
    KEYOFF 1
    NOTE 3, A5, $3B
    KEYOFF 1
    NOTE 2, A5, $3B
    NOTE 2, C6, $3C
    NOTE 2, D6, $3B
    NOTE 3, C6, $3B
    KEYOFF 1
    NOTE 1, C6, $3B
    KEYOFF 1
    NOTE 3, C6, $3B
    KEYOFF 1
    NOTE 2, C6, $3B
    NOTE 2, D6, $3C
    NOTE 2, E6, $3B
    NOTE 4, C6, $3B
    NOTE 1, A5, $3B
    KEYOFF 1
    NOTE 3, A5, $3B
    KEYOFF 1
    NOTE 2, A5, $3B
    NOTE 2, F5, $3B
    NOTE 2, G5, $3B
    NOTE 2, F5, $3C
    NOTE 2, E5, $3B
    PATEND

Pat169:
    NOTE 12, F5, $3B
    NOTE 4, F5, $3C
    NOTE 12, D5, $3B
    NOTE 4, E5, $3B
    NOTE 12, D5, $3B
    NOTE 2, D5, $3B
    NOTE 2, E5, $3B
    NOTE 12, G5, $3B
    NOTE 2, F5, $3B
    NOTE 2, E5, $3B
    PATEND

Pat170:
    NOTE 12, F5, $3B
    NOTE 4, F5, $3C
    NOTE 12, D5, $3B
    NOTE 4, E5, $3B
    NOTE 12, D5, $3B
    NOTE 2, D5, $3B
    NOTE 2, E5, $3C
    NOTE 12, G5, $3B
    NOTE 2, F5, $3B
    NOTE 2, E5, $3B
    PATEND

Pat171:
    NOTE 12, F5, $3B
    NOTE 4, E5, $3C
    NOTE 6, D5, $3B
    NOTE 6, G5, $3B
    NOTE 1, E5, $3B
    KEYOFF 1
    NOTE 2, D5, $3C
    NOTE 12, F5, $3B
    NOTE 1, E5, $3B
    KEYOFF 1
    NOTE 2, F5, $3B
    NOTE 6, G5, $3B
    NOTE 1, G5, $3B
    KEYOFF 1
    NOTE 1, G5, $3B
    KEYOFF 1
    NOTE 1, G5, $3B
    KEYOFF 1
    NOTE 2, F5, $3C
    NOTE 2, D5, $3B
    PATEND

Pat178:
    NOTE 1, C6, $3B
    KEYOFF 1
    NOTE 3, C6, $3B
    KEYOFF 1
    NOTE 2, C6, $3B
    NOTE 2, D6, $3C
    NOTE 2, E6, $3B
    NOTE 4, C6, $3B
    NOTE 1, A5, $3B
    KEYOFF 1
    NOTE 3, A5, $3B
    KEYOFF 1
    NOTE 2, A5, $3B
    NOTE 2, C6, $3C
    NOTE 2, D6, $3B
    NOTE 3, C6, $3B
    KEYOFF 1
    NOTE 1, C6, $3B
    KEYOFF 1
    NOTE 3, C6, $3B
    KEYOFF 1
    NOTE 2, C6, $3B
    NOTE 2, D6, $3C
    NOTE 2, E6, $3B
    NOTE 4, C6, $3B
    NOTE 1, A5, $3B
    KEYOFF 1
    NOTE 3, A5, $3B
    KEYOFF 1
    NOTE 2, A5, $3B
    NOTE 2, C6, $3C
    NOTE 2, D6, $3B
    NOTE 4, C6, $3B
    PATEND

Pat172:
    NOTE 1, F5, $3B
    KEYOFF 1
    NOTE 4, F5, $3B
    NOTE 2, F5, $3B
    NOTE 2, E5, $3C
    NOTE 2, D5, $3B
    NOTE 4, C5, $3B
    NOTE 12, D5, $3B
    NOTE 2, D5, $3B
    NOTE 2, E5, $3B
    NOTE 1, F5, $3B
    NOTE 1, E5, $3B
    NOTE 1, F5, $3B
    KEYOFF 1
    NOTE 2, F5, $3B
    NOTE 2, F5, $3C
    NOTE 1, E5, $3B
    KEYOFF 1
    NOTE 2, D5, $3B
    NOTE 4, C5, $3B
    NOTE 4, G5, $3B
    NOTE 4, F5, $3B
    NOTE 4, E5, $3B
    NOTE 4, D5, $3B
    PATEND

Pat173:
    NOTE 1, F5, $3B
    KEYOFF 1
    NOTE 3, F5, $3B
    KEYOFF 1
    NOTE 2, F5, $3B
    NOTE 2, E5, $3C
    NOTE 2, D5, $3B
    NOTE 4, C5, $3B
    NOTE 2, D5, $3B
    KEYOFF 2
    NOTE 2, C5, $3B
    KEYOFF 2
    NOTE 4, G4, $3B
    NOTE 2, D5, $3B
    NOTE 2, E5, $3B
    NOTE 1, F5, $3B
    NOTE 1, E5, $3B
    NOTE 1, F5, $3B
    KEYOFF 1
    NOTE 2, F5, $3C
    NOTE 1, E5, $3B
    NOTE 1, F5, $3B
    NOTE 2, E5, $3B
    NOTE 1, D5, $3B
    KEYOFF 1
    NOTE 4, C5, $3B
    NOTE 2, G5, $3B
    KEYOFF 2
    NOTE 2, G5, $3B
    NOTE 1, F5, $3B
    KEYOFF 1
    NOTE 2, A5, $3C
    NOTE 2, C6, $3B
    NOTE 2, D6, $3B
    NOTE 2, F6, $3B
    PATEND

Pat177:
    NOTE 2, C6, $1B
    NOTE 10, C6, $1B
    NOTE 4, D6, $1B
    NOTE 6, D6, $1B
    NOTE 6, C6, $1B
    NOTE 4, E6, $1B
    NOTE 2, C6, $1B
    NOTE 10, C6, $1B
    NOTE 4, D6, $1B
    NOTE 6, D6, $1B
    NOTE 6, E6, $1B
    NOTE 4, C6, $1B
    PATEND

Pat176:
    NOTE 2, C6, $1B
    NOTE 10, C6, $1B
    NOTE 4, D6, $1B
    NOTE 6, D6, $1B
    NOTE 6, C6, $1B
    NOTE 4, E6, $1B
    NOTE 6, C6, $1B
    NOTE 2, G5, $1B
    NOTE 2, A5, $1B
    NOTE 2, G5, $1B
    NOTE 4, C5, $1B
    NOTE 6, E5, $1B
    NOTE 6, E5, $1B
    NOTE 4, D5, $1B
    PATEND

Pat179:
    NOTE 10, G5, $1B
    KEYOFF 2
    NOTE 4, G5, $1B
    NOTE 10, E5, $1B
    KEYOFF 2
    NOTE 4, E5, $1B
    NOTE 10, G5, $1B
    KEYOFF 2
    NOTE 2, G5, $1B
    NOTE 2, A5, $1B
    NOTE 10, E5, $1B
    KEYOFF 2
    NOTE 2, F5, $1B
    NOTE 2, E5, $1B
    PATEND

Pat180:
    NOTE 8, G5, $1B
    db $04, $28 ; part of note
Noise_66DA:
    db $1B ; part of note
    NOTE 4, G5, $1B
    NOTE 12, E5, $1B
    NOTE 4, E5, $1B
    NOTE 8, G5, $1B
    NOTE 2, E5, $1B
    NOTE 2, C5, $1B
    NOTE 2, G5, $1B
    NOTE 2, A5, $1B
    NOTE 12, E5, $1B
    NOTE 2, F5, $1B
    NOTE 2, E5, $1B
    PATEND

Pat181:
    NOTE 8, G5, $1B
    NOTE 4, E5, $1B
    NOTE 4, G5, $1B
    NOTE 2, E5, $1B
    NOTE 10, A4, $1B
    NOTE 4, E5, $1B
    NOTE 8, G5, $1B
    NOTE 4, E5, $1B
    NOTE 4, G5, $1B
    NOTE 2, E5, $1B
    NOTE 14, A5, $1B
    PATEND

Pat182:
    NOTE 8, G5, $1B
    NOTE 4, E5, $1B
    NOTE 4, G5, $1B
    NOTE 2, E5, $1B
    NOTE 10, A4, $1B
    NOTE 4, E5, $1B
    NOTE 8, G5, $1B
    NOTE 4, E5, $1B
    NOTE 4, G5, $1B
    NOTE 16, A5, $1B
    PATEND

Pat183:
    KEYOFF 64
    SONGJUMP Song04_Ch3

Song04_Ch4:
    STEP 0, $0B8

Pat184:
    NOTE 2, $3C, $02
    NOTE 4, $3C, $02
    NOTE 2, $3C, $02
    NOTE 2, $3C, $03
    NOTE 2, $3C, $03
    NOTE 4, $30, $01
    NOTE 2, $3C, $02
    NOTE 4, $3C, $02
    NOTE 2, $3C, $02
    NOTE 2, $3C, $03
    NOTE 2, $3C, $03
    NOTE 4, $30, $01
    NOTE 2, $3C, $02
    NOTE 4, $3C, $02
    NOTE 2, $3C, $02
    NOTE 2, $3C, $03
    NOTE 2, $3C, $03
    NOTE 4, $30, $01
    NOTE 6, $3C, $02
    NOTE 2, $3C, $02
    NOTE 2, $3C, $03
    NOTE 2, $3C, $03
    NOTE 2, $30, $01
    NOTE 2, $3C, $02
    SONGJUMP Song04_Ch4

Song05_Ch1:
    STEP 0, $0BA
    STEP 0, $0BB
    STEP 0, $0BC
    STEP 0, $0BD
    STEP 0, $0BE
    STEP 0, $0BC
    STEP 0, $0BD
    STEP 0, $0B9

    ; $67B2-$67B3: 2 unreferenced bytes
    db $20, $08

Pat186:
    NOTE 3, Gs2, $20
    NOTE 3, Gs2, $21
    NOTE 2, Gs2, $21
    PATEND

Pat187:
    NOTE 3, As2, $20
    NOTE 3, As2, $21
    NOTE 2, As2, $21
    PATEND

Pat188:
    NOTE 3, G2, $20
    NOTE 3, G2, $21
    NOTE 2, G2, $21
    PATEND

Pat189:
    NOTE 3, F2, $20
    NOTE 3, F2, $21
    NOTE 2, F2, $21
    PATEND

Pat190:
    NOTE 3, Gs2, $20
    NOTE 3, Gs2, $21
    NOTE 2, Gs2, $20
    PATEND

Pat185:
    NOTE 3, G2, $20
    NOTE 3, G2, $21
    NOTE 2, G2, $21
    SONGJUMP Song05_Ch1

Song05_Ch2:
    STEP 0, $0C0
    STEP 0, $0C1
    STEP 0, $0C2
    STEP 0, $0C3
    STEP 0, $0C0
    STEP 0, $0C2
    STEP 0, $0C3
    STEP 0, $0BF

    ; $6812-$6813: 2 unreferenced bytes
    db $00, $78

Pat192:
    NOTE 8, Gs4, $34
    PATEND

Pat193:
    NOTE 8, As4, $3A
    PATEND

Pat194:
    NOTE 8, G4, $32
    PATEND

Pat195:
    NOTE 8, F4, $39
    PATEND

Pat191:
    NOTE 8, G4, $32
    SONGJUMP Song05_Ch2

Song05_Ch3:
    STEP 0, $0C5
    STEP 0, $0C6
    STEP 0, $0C7
    STEP 0, $0C8
    STEP 0, $0C9
    STEP 0, $0CA
    STEP 0, $0CB
    STEP 0, $0C4

    ; $684A-$684B: 2 unreferenced bytes
    db $00, $78

Pat197:
    NOTE 1, D5, $3B
    NOTE 2, Ds5, $3C
    NOTE 5, C5, $3B
    PATEND

Pat198:
    NOTE 1, F5, $3B
    NOTE 2, Ds5, $3B
    NOTE 3, D5, $3B
    NOTE 2, Ds5, $3B
    PATEND

Pat199:
    NOTE 8, C5, $3B
    PATEND

Pat200:
    HOLD 8
    PATEND

Pat201:
    NOTE 8, Gs5, $3B
    PATEND

Pat202:
    NOTE 8, G5, $3B
    PATEND

Pat203:
    NOTE 6, F5, $3B
    NOTE 2, Ds5, $3B
    PATEND

Pat196:
    NOTE 1, D5, $3C
    NOTE 2, Ds5, $3B
    NOTE 5, C5, $3B
    SONGJUMP Song05_Ch3

Song05_Ch4:
    STEP 0, $0CC
    STEP 0, $0CE ; (dead: after the song jump)
    STEP 0, $0CE ; (dead: after the song jump)
    STEP 0, $0CE ; (dead: after the song jump)
    STEP 0, $0CE ; (dead: after the song jump)
    STEP 0, $0CE ; (dead: after the song jump)
    STEP 0, $0CE ; (dead: after the song jump)
    STEP 0, $0CC ; (dead: after the song jump)

    ; $68A5-$68A6: 2 unreferenced bytes
    db $12, $01

Pat204:
    NOTE 2, $30, $02
    NOTE 1, $32, $03
    NOTE 3, $32, $03
    NOTE 2, $30, $01
    SONGJUMP Song05_Ch4

Pat206:
    NOTE 2, C6, $02
    NOTE 1, D6, $03
    NOTE 3, D6, $03
    NOTE 2, C6, $01
    PATEND

Song06_Ch1:
    STEP 0, $0D1
    STEP 0, $0D4
    STEP 0, $0D2
    STEP 0, $0D3
    STEP 0, $0D2
    STEP 0, $0D3
    STEP 0, $0D4
    STEP 0, $0D4
    STEP 0, $0D5
    STEP 0, $0D5
    STEP 0, $0D6
    STEP 0, $0CF
    STEP 0, $0CF
    STEP 0, $0D0

    ; $68FB-$68FC: 2 unreferenced bytes
    db $78, $FC

Pat209:
    KEYOFF 48
    PATEND

Pat212:
    HOLD 16
    NOTE 26, D4, $21
    NOTE 2, D4, $21
    NOTE 2, D4, $21
    NOTE 2, D4, $21
    PATEND

Pat210:
    NOTE 24, D4, $30
    NOTE 24, G3, $31
    PATEND

Pat211:
    NOTE 24, G3, $39
    NOTE 24, A3, $32
    PATEND

Pat213:
    NOTE 3, A4, $20
    NOTE 3, A4, $21
    NOTE 3, As4, $20
    NOTE 3, As4, $21
    NOTE 3, G4, $20
    NOTE 3, G4, $21
    NOTE 3, A4, $20
    NOTE 3, A4, $21
    NOTE 3, As4, $20
    NOTE 4, As4, $21
    NOTE 3, As4, $21
    NOTE 6, A4, $20
    NOTE 2, A4, $21
    NOTE 2, A4, $21
    NOTE 2, A4, $21
    NOTE 2, A4, $21
    PATEND

Pat214:
    NOTE 3, A4, $20
    NOTE 3, A4, $21
    NOTE 3, As4, $20
    NOTE 3, As4, $21
    NOTE 3, G4, $20
    NOTE 3, G4, $21
    NOTE 3, A4, $20
    NOTE 3, A4, $21
    NOTE 3, G4, $20
    NOTE 7, G4, $21
    NOTE 3, D4, $20
    NOTE 3, D4, $21
    NOTE 2, D4, $21
    NOTE 2, D4, $21
    NOTE 2, D4, $21
    NOTE 2, D4, $21
    PATEND

Pat207:
    NOTE 3, C5, $20
    NOTE 3, C5, $21
    NOTE 3, Cs5, $20
    NOTE 3, Cs5, $21
    NOTE 3, As4, $20
    NOTE 3, As4, $21
    NOTE 3, C5, $20
    NOTE 3, C5, $21
    NOTE 3, Cs5, $20
    NOTE 4, Cs5, $21
    NOTE 3, Cs5, $21
    NOTE 6, C5, $20
    NOTE 2, C5, $21
    NOTE 2, C5, $21
    NOTE 2, C5, $21
    NOTE 2, C5, $21
    PATEND

Pat208:
    NOTE 3, C5, $20
    NOTE 3, C5, $21
    NOTE 3, Cs5, $20
    NOTE 3, Cs5, $21
    NOTE 3, As4, $20
    NOTE 3, As4, $21
    NOTE 3, C5, $20
    NOTE 3, C5, $21
    NOTE 3, As4, $20
    NOTE 7, As4, $21
    NOTE 3, F4, $20
    NOTE 3, F4, $21
    NOTE 2, F4, $21
    NOTE 2, F4, $21
    NOTE 2, F4, $21
    NOTE 2, F4, $21
    SONGJUMP Song06_Ch1

Song06_Ch2:
    STEP 0, $0D9
    STEP 0, $0D9
    STEP 0, $0D9
    STEP 0, $0D9
    STEP 0, $0D9
    STEP 0, $0D9
    STEP 0, $0D9
    STEP 0, $0D9
    STEP 0, $0D9
    STEP 0, $0D9
    STEP 0, $0D9
    STEP 0, $0D7
    STEP 0, $0D7
    STEP 0, $0D8

    ; $6A1B-$6A1C: 2 unreferenced bytes
    db $78, $00

Pat217:
    NOTE 2, D2, $04
    NOTE 2, D2, $04
    NOTE 2, D2, $04
    NOTE 2, D4, $1D
    NOTE 2, D2, $04
    NOTE 2, D2, $04
    NOTE 2, C3, $04
    NOTE 2, D2, $04
    NOTE 2, D2, $04
    NOTE 2, D4, $1D
    NOTE 2, A2, $04
    NOTE 2, D4, $1D
    NOTE 2, D2, $04
    NOTE 2, D2, $04
    NOTE 2, D2, $04
    NOTE 2, D4, $1D
    NOTE 2, D2, $04
    NOTE 2, D2, $04
    NOTE 2, C3, $04
    NOTE 2, D2, $04
    NOTE 2, D2, $04
    NOTE 2, D4, $1D
    NOTE 2, A2, $04
    NOTE 2, D4, $1D
    PATEND

Pat215:
    NOTE 2, F2, $04
    NOTE 2, F2, $04
    NOTE 2, F2, $04
    NOTE 2, F4, $1D
    NOTE 2, F2, $04
    NOTE 2, F2, $04
    NOTE 2, Ds3, $04
    NOTE 2, F2, $04
    NOTE 2, F2, $04
    NOTE 2, F4, $1D
    NOTE 2, C3, $04
    NOTE 2, F4, $1D
    NOTE 2, F2, $04
    NOTE 2, F2, $04
    NOTE 2, F2, $04
    NOTE 2, F4, $1D
    NOTE 2, F2, $04
    NOTE 2, F2, $04
    NOTE 2, Ds3, $04
    NOTE 2, F2, $04
    NOTE 2, F2, $04
    NOTE 2, F4, $1D
    NOTE 2, C3, $04
    NOTE 2, F4, $1D
    PATEND

Pat216:
    NOTE 2, F2, $04
    NOTE 2, F2, $04
    NOTE 2, F2, $04
    NOTE 2, F4, $1D
    NOTE 2, F2, $04
    NOTE 2, F2, $04
    NOTE 2, Ds3, $04
    NOTE 2, F2, $04
    NOTE 2, F2, $04
    NOTE 2, F4, $1D
    NOTE 2, C3, $04
    NOTE 2, F4, $1D
    NOTE 2, F2, $04
    NOTE 2, F2, $04
    NOTE 2, F2, $04
    NOTE 2, F4, $1D
    NOTE 2, F2, $04
    NOTE 2, F2, $04
    NOTE 2, Ds3, $04
    NOTE 2, F2, $04
    NOTE 2, F2, $04
    NOTE 2, F4, $1D
    NOTE 2, C3, $04
    NOTE 2, F4, $1D
    SONGJUMP Song06_Ch2

Song06_Ch3:
    STEP 0, $0DC
    STEP 0, $0DC
    STEP 0, $0DC
    STEP 0, $0DC
    STEP 0, $0DC
    STEP 0, $0DC
    STEP 0, $0DC
    STEP 0, $0DC
    STEP 0, $0DC
    STEP 0, $0DC
    STEP 0, $0DC
    STEP 0, $0DA
    STEP 0, $0DA
    STEP 0, $0DB

    ; $6B32-$6B33: 2 unreferenced bytes
    db $20, $63

Pat220:
    NOTE 1, D4, $26
    KEYOFF 1
    NOTE 1, D4, $26
    KEYOFF 1
    NOTE 2, D4, $26
    NOTE 2, D5, $26
    NOTE 1, D4, $26
    KEYOFF 1
    NOTE 2, D4, $26
    NOTE 2, C5, $26
    NOTE 1, D4, $26
    KEYOFF 1
    NOTE 2, D4, $26
    NOTE 2, As4, $26
    NOTE 2, A4, $26
    NOTE 2, G4, $26
    NOTE 1, D4, $26
    KEYOFF 1
    NOTE 1, D4, $26
    KEYOFF 1
    NOTE 2, D4, $26
    NOTE 2, D5, $26
    NOTE 1, D4, $26
    KEYOFF 1
    NOTE 2, D4, $26
    NOTE 2, C5, $26
    NOTE 1, D4, $26
    KEYOFF 1
    NOTE 2, D4, $26
    NOTE 2, As4, $26
    NOTE 2, A4, $26
    NOTE 2, G4, $26
    PATEND

Pat218:
    NOTE 1, F4, $26
    KEYOFF 1
    NOTE 1, F4, $26
    KEYOFF 1
    NOTE 2, F4, $26
    NOTE 2, F5, $26
    NOTE 1, F4, $26
    KEYOFF 1
    NOTE 2, F4, $26
    NOTE 2, Ds5, $26
    NOTE 1, F4, $26
    KEYOFF 1
    NOTE 2, F4, $26
    NOTE 2, Cs5, $26
    NOTE 2, C5, $26
    NOTE 2, As4, $26
    NOTE 1, F4, $26
    KEYOFF 1
    NOTE 1, F4, $26
    KEYOFF 1
    NOTE 2, F4, $26
    NOTE 2, F5, $26
    NOTE 1, F4, $26
    KEYOFF 1
    NOTE 2, F4, $26
    NOTE 2, Ds5, $26
    NOTE 1, F4, $26
    KEYOFF 1
    NOTE 2, F4, $26
    NOTE 2, Cs5, $26
    NOTE 2, C5, $26
    NOTE 2, As4, $26
    PATEND

Pat219:
    NOTE 1, F4, $26
    KEYOFF 1
    NOTE 1, F4, $26
    KEYOFF 1
    NOTE 2, F4, $26
    NOTE 2, F5, $26
    NOTE 1, F4, $26
    KEYOFF 1
    NOTE 2, F4, $26
    NOTE 2, Ds5, $26
    NOTE 1, F4, $26
    KEYOFF 1
    NOTE 2, F4, $26
    NOTE 2, Cs5, $26
    NOTE 2, C5, $26
    NOTE 2, As4, $26
    NOTE 1, F4, $26
    KEYOFF 1
    NOTE 1, F4, $26
    KEYOFF 1
    NOTE 2, F4, $26
    NOTE 2, F5, $26
    NOTE 1, F4, $26
    KEYOFF 1
    NOTE 2, F4, $26
    NOTE 2, Ds5, $26
    NOTE 1, F4, $26
    KEYOFF 1
    NOTE 2, F4, $26
    NOTE 2, Cs5, $26
    NOTE 2, C5, $26
    NOTE 2, As4, $26
    SONGJUMP Song06_Ch3

Song06_Ch4:
    STEP 0, $0DF
    STEP 0, $0DF
    STEP 0, $0DF
    STEP 0, $0DF
    STEP 0, $0DF
    STEP 0, $0DF
    STEP 0, $0DF
    STEP 0, $0DF
    STEP 0, $0DF
    STEP 0, $0DF
    STEP 0, $0DF
    STEP 0, $0DD
    STEP 0, $0DD
    STEP 0, $0DE

    ; $6C79-$6C7A: 2 unreferenced bytes
    db $00, $00

Pat223:
    NOTE 4, $30, $02
    NOTE 2, $30, $02
    NOTE 4, $24, $01
    NOTE 2, $30, $02
    NOTE 4, $30, $02
    NOTE 2, $30, $02
    NOTE 2, $24, $01
    NOTE 2, $30, $02
    NOTE 2, $24, $01
    NOTE 4, $30, $02
    NOTE 2, $30, $02
    NOTE 4, $24, $01
    NOTE 2, $30, $02
    NOTE 4, $30, $02
    NOTE 2, $30, $02
    NOTE 2, $24, $01
    NOTE 2, $30, $02
    NOTE 2, $24, $01
    PATEND

Pat221:
    NOTE 4, $33, $02
    NOTE 2, $33, $02
    NOTE 4, $27, $01
    NOTE 2, $33, $02
    NOTE 4, $33, $02
    NOTE 2, $33, $02
    NOTE 2, $27, $01
    NOTE 2, $33, $02
    NOTE 2, $27, $01
    NOTE 4, $33, $02
    NOTE 2, $33, $02
    NOTE 4, $27, $01
    NOTE 2, $33, $02
    NOTE 4, $33, $02
    NOTE 2, $33, $02
    NOTE 2, $27, $01
    NOTE 2, $33, $02
    NOTE 2, $27, $01
    PATEND

Pat222:
    NOTE 4, $33, $02
    NOTE 2, $33, $02
    NOTE 4, $27, $01
    NOTE 2, $33, $02
    NOTE 4, $33, $02
    NOTE 2, $33, $02
    NOTE 2, $27, $01
    NOTE 2, $33, $02
    NOTE 2, $27, $01
    NOTE 4, $33, $02
    NOTE 2, $33, $02
    NOTE 4, $27, $01
    NOTE 2, $33, $02
    NOTE 4, $33, $02
    NOTE 2, $33, $02
    NOTE 2, $27, $01
    NOTE 2, $33, $02
    NOTE 2, $27, $01
    SONGJUMP Song06_Ch4

Song08_Ch1:
    STEP 0, $0E0
    STEP 0, $0E0
    STEP 0, $0E0
    STEP 0, $0E0
    STEP 0, $0E0
    STEP 0, $0E0
    STEP 0, $0E0
    STEP 0, $0E0
    STEP 0, $0E4
    STEP 0, $0E4
    STEP 2, $0E4
    STEP 2, $0E4
    STEP 3, $0E4
    STEP 3, $0E4
    STEP 5, $0E4
    STEP 5, $0E6

    ; $6D62-$6D63: 2 unreferenced bytes
    db $00, $00

Pat224:
    NOTE 2, E5, $07
    NOTE 2, E5, $07
    NOTE 4, E5, $30
    NOTE 4, E5, $07
    NOTE 6, E5, $30
    NOTE 4, E5, $07
    NOTE 2, E5, $07
    NOTE 4, E5, $07
    NOTE 4, E5, $30
    PATEND

Pat228:
    NOTE 2, E4, $07
    NOTE 2, E4, $07
    NOTE 2, E4, $1D
    NOTE 2, E4, $07
    NOTE 2, E4, $07
    NOTE 2, E4, $07
    NOTE 2, E4, $1D
    NOTE 2, E4, $07
    NOTE 2, E4, $07
    NOTE 2, E4, $07
    NOTE 2, E4, $1D
    NOTE 2, E4, $07
    NOTE 2, E4, $07
    NOTE 2, E4, $07
    NOTE 2, E4, $1D
    NOTE 2, E4, $07
    PATEND

Pat230:
    NOTE 2, E4, $07
    NOTE 2, E4, $07
    NOTE 2, E4, $1D
    NOTE 2, E4, $07
    NOTE 2, E4, $07
    NOTE 2, E4, $07
    NOTE 2, E4, $1D
    NOTE 2, E4, $07
    NOTE 2, E4, $07
    NOTE 2, E4, $07
    NOTE 2, E4, $1D
    NOTE 2, E4, $07
    NOTE 2, E4, $07
    NOTE 2, E4, $07
    NOTE 2, E4, $1D
    NOTE 2, E4, $07
    SONGJUMP Song08_Ch1

Song08_Ch2:
    STEP 0, $0E7
    STEP 0, $0E7
    STEP 0, $0E8
    STEP 0, $0E9
    STEP 0, $0E8
    STEP 0, $0E9
    STEP 0, $0EA
    STEP 0, $0EA
    STEP 0, $0EB
    STEP 0, $0EC
    STEP 2, $0EB
    STEP 2, $0EC
    STEP 3, $0EB
    STEP 3, $0EC
    STEP 5, $0EB
    STEP 5, $0ED

    ; $6E24-$6E25: 2 unreferenced bytes
    db $5F, $5F

Pat231:
    HOLD 32
    PATEND

Pat233:
    NOTE 2, E4, $22
    NOTE 2, Ds4, $22
    NOTE 24, E4, $22
    KEYOFF 4
    PATEND

Pat234:
    NOTE 32, E2, $22
    PATEND

Pat235:
    NOTE 2, E4, $20
    NOTE 2, E4, $20
    NOTE 2, Fs4, $20
    NOTE 12, G4, $20
    NOTE 2, E4, $20
    NOTE 2, Fs4, $20
    NOTE 2, G4, $20
    NOTE 2, As3, $20
    NOTE 2, B3, $20
    KEYOFF 4
    PATEND

Pat236:
    NOTE 2, E4, $20
    NOTE 2, E4, $20
    NOTE 2, Fs4, $20
    NOTE 12, G4, $20
    NOTE 2, E4, $20
    NOTE 2, Fs4, $20
    NOTE 2, G4, $20
    NOTE 2, A4, $20
    NOTE 2, G4, $20
    NOTE 2, Fs4, $20
    NOTE 2, G4, $20
    PATEND

Pat237:
    NOTE 2, E4, $20
    NOTE 2, E4, $20
    NOTE 2, Fs4, $20
    NOTE 12, G4, $20
    NOTE 2, E4, $20
    NOTE 2, Fs4, $20
    NOTE 2, G4, $20
    NOTE 2, A4, $20
    NOTE 2, G4, $20
    NOTE 2, Fs4, $20
    NOTE 2, G4, $20
    SONGJUMP Song08_Ch2

Pat232:
    NOTE 2, G4, $22
    NOTE 2, E4, $22
    NOTE 24, G4, $22
    KEYOFF 4
    PATEND

Song08_Ch3:
    STEP 0, $0EE
    STEP 0, $0EE
    STEP 0, $0EE
    STEP 0, $0EE
    STEP 0, $0EE
    STEP 0, $0EE
    STEP 0, $0EE
    STEP 0, $0EE
    STEP 0, $0EE
    STEP 0, $0EE
    STEP 2, $0EE
    STEP 2, $0EE
    STEP 3, $0EE
    STEP 3, $0EE
    STEP 5, $0EE
    STEP 5, $0F4

    ; $6EE9-$6EEA: 2 unreferenced bytes
    db $6F, $72

Pat238:
    NOTE 2, E3, $3B
    NOTE 2, B3, $3B
    NOTE 2, E4, $3B
    NOTE 2, B3, $3B
    NOTE 2, Fs4, $3B
    NOTE 2, C4, $3B
    NOTE 2, G4, $3B
    NOTE 2, E4, $3B
    NOTE 2, E3, $3B
    NOTE 2, B3, $3B
    NOTE 2, E4, $3B
    NOTE 2, B3, $3B
    NOTE 2, Fs4, $3B
    NOTE 2, C4, $3B
    NOTE 2, G4, $3B
    NOTE 2, Ds4, $3B
    PATEND

Pat244:
    NOTE 2, E3, $3B
    NOTE 2, B3, $3B
    NOTE 2, E4, $3B
    NOTE 2, B3, $3B
    NOTE 2, Fs4, $3B
    NOTE 2, C4, $3B
    NOTE 2, G4, $3B
    NOTE 2, E4, $3B
    NOTE 2, E3, $3B
    NOTE 2, B3, $3B
    NOTE 2, E4, $3B
    NOTE 2, B3, $3B
    NOTE 2, Fs4, $3B
    NOTE 2, C4, $3B
    NOTE 2, G4, $3B
    NOTE 2, Ds4, $3B
    SONGJUMP Song08_Ch3

Song08_Ch4:
    STEP 0, $0F5
    STEP 0, $0F5
    STEP 0, $0F6
    STEP 0, $0F6
    STEP 0, $0F6
    STEP 0, $0F6
    STEP 0, $0F6
    STEP 0, $0F6
    STEP 0, $0F9
    STEP 0, $0F9
    STEP 0, $0F9
    STEP 0, $0F9
    STEP 0, $0F9
    STEP 0, $0F9
    STEP 0, $0F9
    STEP 0, $0FB

    ; $6F8F-$6F90: 2 unreferenced bytes
    db $2E, $00

Pat245:
    NOTE 2, $37, $03
    NOTE 12, $37, $03
    NOTE 2, $37, $03
    NOTE 2, $37, $03
    NOTE 12, $37, $03
    NOTE 2, $37, $03
    PATEND

Pat246:
    NOTE 2, $37, $03
    NOTE 12, $37, $03
    NOTE 2, $37, $03
    NOTE 2, $37, $03
    NOTE 12, $37, $03
    NOTE 2, $37, $03
    PATEND

Pat249:
    NOTE 2, $37, $03
    NOTE 2, $37, $03
    NOTE 8, $39, $01
    NOTE 2, $39, $01
    NOTE 2, $37, $03
    NOTE 2, $37, $03
    NOTE 2, $37, $03
    NOTE 8, $39, $01
    NOTE 2, $39, $01
    NOTE 2, $37, $03
    PATEND

Pat251:
    NOTE 2, $37, $03
    NOTE 2, $37, $03
    NOTE 8, $39, $01
    NOTE 2, $39, $01
    NOTE 2, $37, $03
    NOTE 2, $37, $03
    NOTE 2, $37, $03
    NOTE 8, $39, $01
    NOTE 2, $39, $01
    NOTE 2, $37, $03
    SONGJUMP Song08_Ch4

Song09_Ch1:
    STEP 0, $0FC
    STEP 0, $0FC
    STEP 0, $0FC
    STEP 0, $0FC
    STEP 0, $0FC
    STEP 0, $0FC
    STEP 0, $0FC
    STEP 0, $0FC
    STEP 0, $0FC
    STEP 0, $0FC
    STEP 0, $0FC
    STEP 0, $0FC
    STEP 0, $103
    STEP 0, $0FC
    STEP 0, $0FC
    STEP 0, $0FC
    STEP 0, $104

    ; $703B-$703C: 2 unreferenced bytes
    db $00, $60

Pat252:
    NOTE 1, C2, $04
    NOTE 1, C2, $04
    NOTE 1, C3, $04
    NOTE 1, C2, $04
    NOTE 1, F2, $04
    NOTE 1, F3, $04
    NOTE 1, Fs2, $04
    NOTE 1, G2, $04
    NOTE 1, C2, $04
    NOTE 1, C2, $04
    NOTE 1, C3, $04
    NOTE 1, C2, $04
    NOTE 1, F2, $04
    NOTE 1, F3, $04
    NOTE 1, Fs2, $04
    NOTE 1, G2, $04
    NOTE 1, C2, $04
    NOTE 1, C2, $04
    NOTE 1, C3, $04
    NOTE 1, C2, $04
    NOTE 1, F2, $04
    NOTE 1, F3, $04
    NOTE 1, Fs2, $04
    NOTE 1, G2, $04
    NOTE 1, C2, $04
    NOTE 1, C2, $04
    NOTE 1, C3, $04
    NOTE 1, C2, $04
    NOTE 1, F2, $04
    NOTE 1, F3, $04
    NOTE 1, Fs2, $04
    NOTE 1, G2, $04
    PATEND

Pat259:
    NOTE 1, F2, $04
    NOTE 1, F2, $04
    NOTE 1, F3, $04
    NOTE 1, F2, $04
    NOTE 1, As2, $04
    NOTE 1, As3, $04
    NOTE 1, B2, $04
    NOTE 1, C3, $04
    NOTE 1, F2, $04
    NOTE 1, F2, $04
    NOTE 1, F3, $04
    NOTE 1, F2, $04
    NOTE 1, As2, $04
    NOTE 1, As3, $04
    NOTE 1, B2, $04
    NOTE 1, C3, $04
    NOTE 1, F2, $04
    NOTE 1, F2, $04
    NOTE 1, F3, $04
    NOTE 1, F2, $04
    NOTE 1, As2, $04
    NOTE 1, As3, $04
    NOTE 1, B2, $04
    NOTE 1, C3, $04
    NOTE 1, F2, $04
    NOTE 1, F2, $04
    NOTE 1, F3, $04
    NOTE 1, F2, $04
    NOTE 1, As2, $04
    NOTE 1, As3, $04
    NOTE 1, B2, $04
    NOTE 1, C3, $04
    PATEND

Pat260:
    NOTE 1, F2, $04
    NOTE 1, F2, $04
    NOTE 1, F3, $04
    NOTE 1, F2, $04
    NOTE 1, As2, $04
    NOTE 1, As3, $04
    NOTE 1, B2, $04
    NOTE 1, C3, $04
    NOTE 1, F2, $04
    NOTE 1, F2, $04
    NOTE 1, F3, $04
    NOTE 1, F2, $04
    NOTE 1, As2, $04
    NOTE 1, As3, $04
    NOTE 1, B2, $04
    NOTE 1, C3, $04
    NOTE 1, F2, $04
    NOTE 1, F2, $04
    NOTE 1, F3, $04
    NOTE 1, F2, $04
    NOTE 1, As2, $04
    NOTE 1, As3, $04
    NOTE 1, B2, $04
    NOTE 1, C3, $04
    NOTE 1, F2, $04
    NOTE 1, F2, $04
    NOTE 1, F3, $04
    NOTE 1, F2, $04
    NOTE 1, As2, $04
    NOTE 1, As3, $04
    NOTE 1, B2, $04
    NOTE 1, C3, $04
    SONGJUMP Song09_Ch1

Song09_Ch2:
    STEP 0, $105
    STEP 0, $105
    STEP 0, $105
    STEP 0, $105
    STEP 0, $105
    STEP 0, $105
    STEP 0, $105
    STEP 0, $105
    STEP 0, $105
    STEP 0, $109
    STEP 0, $10A
    STEP 0, $10B
    STEP 0, $10C
    STEP 0, $109
    STEP 0, $10A
    STEP 0, $10B
    STEP 0, $10D

    ; $71A6-$71A7: 2 unreferenced bytes
    db $03, $78

Pat261:
    NOTE 1, C3, $04
    NOTE 1, C3, $04
    NOTE 1, C4, $04
    NOTE 1, C3, $04
    NOTE 1, F3, $04
    NOTE 1, F4, $04
    NOTE 1, Fs3, $04
    NOTE 1, G3, $04
    NOTE 1, C3, $04
    NOTE 1, C3, $04
    NOTE 1, C4, $04
    NOTE 1, C3, $04
    NOTE 1, F3, $04
    NOTE 1, F4, $04
    NOTE 1, Fs3, $04
    NOTE 1, G3, $04
    NOTE 1, C3, $04
    NOTE 1, C3, $04
    NOTE 1, C4, $04
    NOTE 1, C3, $04
    NOTE 1, F3, $04
    NOTE 1, F4, $04
    NOTE 1, Fs3, $04
    NOTE 1, G3, $04
    NOTE 1, C3, $04
    NOTE 1, C3, $04
    NOTE 1, C4, $04
    NOTE 1, C3, $04
    NOTE 1, F3, $04
    NOTE 1, F4, $04
    NOTE 1, Fs3, $04
    NOTE 1, G3, $04
    PATEND

Pat265:
    NOTE 32, G4, $38
    PATEND

Pat266:
    NOTE 32, As4, $34
    PATEND

Pat267:
    NOTE 32, C5, $30
    PATEND

Pat268:
    NOTE 16, C5, $39
    NOTE 16, As4, $39
    PATEND

Pat269:
    NOTE 16, C5, $39
    NOTE 16, As4, $39
    SONGJUMP Song09_Ch2

Song09_Ch3:
    STEP 0, $10E
    STEP 0, $10E
    STEP 0, $10E
    STEP 0, $110
    STEP 0, $111
    STEP 0, $10E
    STEP 0, $110
    STEP 0, $111
    STEP 0, $10E
    STEP 0, $112
    STEP 0, $112
    STEP 0, $112
    STEP 0, $115
    STEP 0, $112
    STEP 0, $112
    STEP 0, $112
    STEP 0, $116

    ; $7269-$726A: 2 unreferenced bytes
    db $6E, $6F

Pat270:
    HOLD 32
    PATEND

Pat272:
    NOTE 1, Ds6, $26
    NOTE 1, C6, $26
    NOTE 1, B5, $26
    NOTE 1, C6, $26
    NOTE 1, Ds6, $26
    NOTE 1, C6, $26
    NOTE 1, B5, $26
    NOTE 1, C6, $26
    NOTE 1, Ds6, $26
    NOTE 1, C6, $26
    NOTE 1, B5, $26
    NOTE 1, C6, $26
    NOTE 1, Ds6, $26
    NOTE 1, C6, $26
    NOTE 1, B5, $26
    NOTE 1, C6, $26
    NOTE 16, Gs5, $2D
    PATEND

Pat273:
    NOTE 30, G5, $2C
    KEYOFF 2
    PATEND

Pat274:
    NOTE 32, C4, $26
    PATEND

Pat277:
    NOTE 32, F3, $26
    PATEND

Pat278:
    NOTE 32, F3, $26
    SONGJUMP Song09_Ch3

Song09_Ch4:
    STEP 0, $117
    STEP 0, $117
    STEP 0, $117
    STEP 0, $117
    STEP 0, $117
    STEP 0, $117
    STEP 0, $117
    STEP 0, $117
    STEP 0, $117
    STEP 0, $11B
    STEP 0, $11B
    STEP 0, $11B
    STEP 0, $11B
    STEP 0, $11B
    STEP 0, $11B
    STEP 0, $11B
    STEP 0, $11F

    ; $72FA-$72FB: 2 unreferenced bytes
    db $30, $31

Pat279:
    HOLD 32
    PATEND

Pat283:
    HOLD 2
    NOTE 1, $37, $03
    NOTE 1, $37, $03
    NOTE 2, $37, $01
    NOTE 1, $37, $03
    NOTE 3, $37, $03
    NOTE 1, $37, $03
    NOTE 1, $37, $03
    NOTE 2, $37, $01
    NOTE 1, $37, $03
    NOTE 3, $37, $03
    NOTE 1, $37, $03
    NOTE 1, $37, $03
    NOTE 2, $37, $01
    NOTE 1, $37, $03
    NOTE 3, $37, $03
    NOTE 1, $37, $03
    NOTE 1, $37, $03
    NOTE 2, $37, $01
    NOTE 1, $37, $03
    NOTE 1, $37, $03
    PATEND

Pat287:
    HOLD 2
    NOTE 1, $37, $03
    NOTE 1, $37, $03
    NOTE 2, $37, $01
    NOTE 1, $37, $03
    NOTE 3, $37, $03
    NOTE 1, $37, $03
    NOTE 1, $37, $03
    NOTE 2, $37, $01
    NOTE 1, $37, $03
    NOTE 3, $37, $03
    NOTE 1, $37, $03
    NOTE 1, $37, $03
    NOTE 2, $37, $01
    NOTE 1, $37, $03
    NOTE 3, $37, $03
    NOTE 1, $37, $03
    NOTE 1, $37, $03
    NOTE 2, $37, $01
    NOTE 1, $37, $03
    NOTE 1, $37, $03
    SONGJUMP Song09_Ch4

Pat280:
    HOLD 1
    PATEND

    ; $7382-$7383: 2 unreferenced bytes
    db $00, $00

Comb_7384:
    TB 1, $01 ; note only
    TB 1, $00 ; freq table only
    TLOOP Comb_7384

Comb_738B:
    TB 255, $00 ; freq table only
    TLOOP Comb_738B

Comb_7390:
    TB 255, $01 ; note only
    TLOOP Comb_7390

Comb_7395:
    TB 255, $02 ; note + freq table
    TLOOP Comb_7395

Arp_739A:
    TB 255, $00 ; +0
    TLOOP Arp_739A

Freq_739F:
    TW 255, 0
    TLOOP Freq_739F

OrphanTab_73A5:
    TB 255, $00
    TLOOP OrphanTab_73A5

OrphanTab_73AA:
    TW 20, 0

OrphanTab_73AA_Loop:
    TW 2, 1
    TW 2, -1
    TW 2, -1
    TW 2, 1
    TLOOP OrphanTab_73AA_Loop

OrphanTab_73BC:
    TW 3, 10
    TW 3, -10
    TW 3, -10
    TW 3, 10
    TLOOP OrphanTab_73BC

Freq_73CB:
    TW 3, 5
    TW 3, -5
    TW 3, -5
    TW 3, 5
    TLOOP Freq_73CB

Freq_766E_L0:
    TW 20, 0

Freq_73DD:
    TW 3, 2
    TW 3, -2
    TW 3, -2
    TW 3, 2
    TLOOP Freq_73DD

Freq_73EC:
    TW 3, 1
    TW 3, -1
    TW 3, -1
    TW 3, 1
    TLOOP Freq_73EC

Freq_73FB:
    TW 1, 1
    TW 2, 0
    TW 1, -1
    TW 2, 0
    TW 1, -1
    TW 2, 0
    TW 1, 1
    TW 2, 0
    TLOOP Freq_73FB

Freq_7416:
    TW 1, -12
    TW 6, 2

Freq_741C:
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

Freq_741C_L0:
    TW 2, 16
    TW 2, -16
    TW 2, -16
    TW 2, 16
    TLOOP Freq_741C_L0

Vol_7497:
    TB 2, $60 ; 25%
    TB 2, $40 ; 50%
    TB 8, $20 ; 100%
    TB 2, $40 ; 50%
    TB 2, $60 ; 25%
    TLOOP BlankVol

Vol_74A4:
    TB 255, $20 ; 100%
    TLOOP Vol_74A4

Vol_74A9:
    TB 255, $40 ; 50%
    TLOOP Vol_74A9

Vol_74AE:
    TB 255, $60 ; 25%
    TLOOP Vol_74AE

Ins00:
    INS_TONE $80, $01, $01, Arp_739A, Freq_739F, Comb_7390 ; $00, $2F

NoiseIns00:
    INS_NOISE $00, $01, $01, Arp_739A, Arp_739A ; $00

Ins01:
    INS_WAVE BlankVol, BlankVol, Arp_739A, Freq_739F, Comb_7395 ; $01, $02

Ins46:
    INS_WAVE Vol_7497, BlankVol, Arp_739A, Freq_739F, Comb_7390 ; $2E (unused)

Ins03:
    INS_TONE $80, $F2, $11, Arp_74E0, Freq_73DD, Comb_7395 ; $03 (unused)

Arp_74E0:
    TB 3, $00 ; +0
    TB 3, $0C ; +12
    TLOOP Arp_74E0

Ins04:
    INS_TONE $60, $F2, $11, Arp_739A, Freq_73DD, Comb_7390 ; $04

Ins05:
    INS_TONE $60, $F3, $11, Arp_739A, Freq_73CB, Comb_7395 ; $05

Ins06:
    INS_TONE $60, $84, $11, Arp_75C8, Freq_739F, Comb_7390 ; $06

Ins52:
    INS_TONE $00, $48, $43, Arp_75C8, Freq_73EC, Comb_7395 ; $34

Ins07:
    INS_TONE $60, $84, $11, Arp_75D1, Freq_739F, Comb_7390 ; $07

Ins48:
    INS_TONE $00, $48, $43, Arp_75D1, Freq_73EC, Comb_7395 ; $30

Ins08:
    INS_TONE $60, $84, $11, Arp_75DA, Freq_739F, Comb_7390 ; $08

Ins09:
    INS_TONE $60, $84, $11, Arp_75E3, Freq_739F, Comb_7390 ; $09

Ins56:
    INS_TONE $60, $48, $43, Arp_75DA, Freq_73EC, Comb_7395 ; $38

Ins57:
    INS_TONE $60, $48, $43, Arp_75E3, Freq_73EC, Comb_7395 ; $39

Ins10:
    INS_TONE $60, $84, $11, Arp_75EC, Freq_739F, Comb_7390 ; $0A (unused)

Ins51:
    INS_TONE $60, $48, $43, Arp_75EC, Freq_73EC, Comb_7395 ; $33 (unused)

Ins11:
    INS_TONE $60, $84, $11, Arp_75F5, Freq_739F, Comb_7390 ; $0B (unused)

Ins55:
    INS_TONE $60, $48, $43, Arp_75F5, Freq_73EC, Comb_7395 ; $37 (unused)

Ins12:
    INS_TONE $60, $84, $11, Arp_75FE, Freq_739F, Comb_7390 ; $0C (unused)

Ins49:
    INS_TONE $60, $48, $43, Arp_75FE, Freq_73EC, Comb_7395 ; $31

Ins13:
    INS_TONE $60, $84, $11, Arp_7609, Freq_739F, Comb_7390 ; $0D (unused)

Ins53:
    INS_TONE $60, $68, $63, Arp_7609, Freq_73EC, Comb_7395 ; $35 (unused)

Ins14:
    INS_TONE $60, $84, $11, Arp_7614, Freq_739F, Comb_7390 ; $0E (unused)

Ins54:
    INS_TONE $60, $48, $43, Arp_7614, Freq_73EC, Comb_7395 ; $36 (unused)

Ins15:
    INS_TONE $60, $84, $11, Arp_761F, Freq_739F, Comb_7390 ; $0F (unused)

Ins58:
    INS_TONE $60, $48, $43, Arp_7628, Freq_73EC, Comb_7395 ; $3A

Ins50:
    INS_TONE $60, $48, $43, Arp_761F, Freq_73EC, Comb_7395 ; $32

Ins30:
    INS_TONE $60, $84, $11, Arp_75BF, Freq_739F, Comb_7390 ; $1E (unused)

Arp_75BF:
    TB 2, $00 ; +0
    TB 2, $07 ; +7
    TB 2, $0A ; +10
    TLOOP Arp_75BF

Arp_75C8:
    TB 2, $00 ; +0
    TB 2, $04 ; +4
    TB 2, $07 ; +7
    TLOOP Arp_75C8

Arp_75D1:
    TB 2, $00 ; +0
    TB 2, $03 ; +3
    TB 2, $07 ; +7
    TLOOP Arp_75D1

Arp_75DA:
    TB 2, $00 ; +0
    TB 2, $05 ; +5
    TB 2, $08 ; +8
    TLOOP Arp_75DA

Arp_75E3:
    TB 2, $00 ; +0
    TB 2, $05 ; +5
    TB 2, $09 ; +9
    TLOOP Arp_75E3

Arp_75EC:
    TB 2, $00 ; +0
    TB 2, $03 ; +3
    TB 2, $09 ; +9
    TLOOP Arp_75EC

Arp_75F5:
    TB 2, $00 ; +0
    TB 2, $04 ; +4
    TB 2, $09 ; +9
    TLOOP Arp_75F5

Arp_75FE:
    TB 2, $00 ; +0
    TB 2, $03 ; +3
    TB 2, $07 ; +7
    TB 2, $0A ; +10
    TLOOP Arp_75FE

Arp_7609:
    TB 2, $00 ; +0
    TB 2, $04 ; +4
    TB 2, $07 ; +7
    TB 2, $0A ; +10
    TLOOP Arp_7609

Arp_7614:
    TB 2, $00 ; +0
    TB 2, $04 ; +4
    TB 2, $07 ; +7
    TB 2, $0B ; +11
    TLOOP Arp_7614

Arp_761F:
    TB 2, $00 ; +0
    TB 2, $03 ; +3
    TB 2, $08 ; +8
    TLOOP Arp_761F

Arp_7628:
    TB 2, $00 ; +0
    TB 2, $02 ; +2
    TB 2, $07 ; +7
    TLOOP Arp_7628

Ins32:
    INS_TONE $80, $C2, $11, Arp_7643, Freq_73FB, Comb_7390 ; $20

Ins33:
    INS_TONE $80, $62, $11, Arp_7643, Freq_739F, Comb_7390 ; $21

Arp_7643:
    TB 1, $00 ; +0
    TB 1, $0C ; +12
    TLOOP Arp_7643

Ins34:
    INS_TONE $40, $78, $83, Arp_739A, Freq_741C, Comb_7395 ; $22

Ins35:
    INS_TONE $40, $78, $83, Arp_739A, Freq_7416, Comb_7395 ; $23 (unused)

Ins36:
    INS_TONE $80, $88, $82, Arp_739A, Freq_73FB, Comb_7395 ; $24 (unused)

Ins37:
    INS_TONE $80, $88, $83, Arp_739A, Freq_766E, Comb_7395 ; $25 (unused)

Freq_766E:
    TW 1, -20
    TW 5, 4
    TLOOP Freq_766E_L0

Ins44:
    INS_WAVE Vol_74A4, Vol_74AE, Arp_768B, Freq_73FB, Comb_7390 ; $2C

Ins45:
    INS_WAVE Vol_74A4, Vol_74AE, Arp_7692, Freq_73FB, Comb_7390 ; $2D

Arp_768B:
    TB 4, $00 ; +0
    TB 4, $01 ; +1
    TLOOP Arp_768B

Arp_7692:
    TB 4, $00 ; +0
    TB 4, $02 ; +2
    TLOOP Arp_7692

Ins16:
    INS_WAVE Vol_7765, Vol_74AE, Arp_7711, Freq_739F, Comb_7395 ; $10 (unused)

Ins17:
    INS_WAVE Vol_7765, Vol_74AE, Arp_7718, Freq_739F, Comb_7395 ; $11 (unused)

Ins18:
    INS_WAVE Vol_7765, Vol_74AE, Arp_771F, Freq_739F, Comb_7395 ; $12 (unused)

Ins19:
    INS_WAVE Vol_7765, Vol_74AE, Arp_7726, Freq_739F, Comb_7395 ; $13 (unused)

Ins20:
    INS_WAVE Vol_7765, Vol_74AE, Arp_772D, Freq_739F, Comb_7395 ; $14 (unused)

Ins21:
    INS_WAVE Vol_7765, Vol_74AE, Arp_7734, Freq_739F, Comb_7395 ; $15 (unused)

Ins22:
    INS_WAVE Vol_7765, Vol_74AE, Arp_773B, Freq_739F, Comb_7395 ; $16 (unused)

Ins23:
    INS_WAVE Vol_7765, Vol_74AE, Arp_7742, Freq_739F, Comb_7395 ; $17 (unused)

Ins24:
    INS_WAVE Vol_7765, Vol_74AE, Arp_7749, Freq_739F, Comb_7395 ; $18 (unused)

Ins25:
    INS_WAVE Vol_7765, Vol_74AE, Arp_7750, Freq_739F, Comb_7395 ; $19 (unused)

Ins26:
    INS_WAVE Vol_7765, Vol_74AE, Arp_7757, Freq_739F, Comb_7395 ; $1A (unused)

Ins27:
    INS_WAVE Vol_7765, Vol_74AE, Arp_775E, Freq_73FB, Comb_7395 ; $1B

Arp_7711:
    TB 2, $00 ; +0
    TB 2, $01 ; +1
    TLOOP Arp_7711

Arp_7718:
    TB 2, $00 ; +0
    TB 2, $02 ; +2
    TLOOP Arp_7718

Arp_771F:
    TB 2, $00 ; +0
    TB 2, $03 ; +3
    TLOOP Arp_771F

Arp_7726:
    TB 2, $00 ; +0
    TB 2, $04 ; +4
    TLOOP Arp_7726

Arp_772D:
    TB 2, $00 ; +0
    TB 2, $05 ; +5
    TLOOP Arp_772D

Arp_7734:
    TB 2, $00 ; +0
    TB 2, $06 ; +6
    TLOOP Arp_7734

Arp_773B:
    TB 2, $00 ; +0
    TB 2, $07 ; +7
    TLOOP Arp_773B

Arp_7742:
    TB 2, $00 ; +0
    TB 2, $08 ; +8
    TLOOP Arp_7742

Arp_7749:
    TB 2, $00 ; +0
    TB 2, $09 ; +9
    TLOOP Arp_7749

Arp_7750:
    TB 2, $00 ; +0
    TB 2, $0A ; +10
    TLOOP Arp_7750

Arp_7757:
    TB 2, $00 ; +0
    TB 2, $0B ; +11
    TLOOP Arp_7757

Arp_775E:
    TB 2, $00 ; +0
    TB 2, $0C ; +12
    TLOOP Arp_775E

Vol_7765:
    TB 2, $20 ; 100%
    TB 255, $40 ; 50%
    TLOOP Vol_7765

Vol_776C:
    TB 16, $20 ; 100%
    TB 16, $40 ; 50%
    TB 255, $60 ; 25%
    TLOOP BlankVol

Ins38:
    INS_WAVE Vol_77A7, Vol_74AE, Arp_739A, Freq_7825, Comb_7395 ; $26

Ins59:
    INS_WAVE Vol_776C, Vol_74AE, Arp_739A, Freq_73EC, Comb_7395 ; $3B, $3C

Ins39:
    INS_WAVE Vol_74A9, Vol_74AE, Arp_739A, Freq_781F, Comb_7395 ; $27

Ins42:
    INS_WAVE Vol_77A7, Vol_74AE, Arp_739A, Freq_7825, Comb_7395 ; $2A

Ins43:
    INS_WAVE Vol_77A7, Vol_74AE, Arp_739A, Freq_781F, Comb_7395 ; $2B

Vol_77A7:
    TB 2, $20 ; 100%

Vol_77A7_L0:
    TB 255, $40 ; 50%
    TLOOP Vol_77A7_L0

Ins28:
    INS_TONE $80, $E1, $21, Arp_77CC, Freq_77B7, Comb_738B ; $1C

Freq_77B7:
    TW 1, 1100
    TW 1, 100
    TW 255, -80
    TLOOP Freq_77B7

Ins29:
    INS_TONE $80, $F2, $21, Arp_77CC, Freq_77D3, Comb_738B ; $1D

Arp_77CC:
    TB 1, $00 ; +0
    TB 1, $02 ; +2
    TLOOP Arp_77CC

Freq_77D3:
    TW 1, 1700
    TW 2, -60

Freq_77D3_L0:
    TW 1, 100
    TW 255, -60
    TLOOP Freq_77D3_L0

Ins31:
    INS_TONE $80, $51, $21, Arp_77FA, Freq_77EB, Comb_738B ; $1F

Freq_77EB:
    TW 1, 4060
    TW 1, -1
    TW 1, -4060

Freq_77EB_L0:
    TW 255, 0
    TLOOP Freq_77EB_L0

Arp_77FA:
    TB 1, $00 ; +0
    TB 1, $FF ; -1
    TB 1, $FE ; -2
    TB 1, $FD ; -3
    TLOOP Arp_77FA

Ins40:
    INS_WAVE Vol_74A4, Vol_74AE, Arp_739A, Freq_73FB, Comb_7390 ; $28

Ins41:
    INS_WAVE Vol_74A9, Vol_74AE, Arp_739A, Freq_73FB, Comb_7390 ; $29

    ; $7819-$781E: 6 unreferenced bytes
    db $32, $00, $00, $00, $25, $78

Freq_781F:
    TW 1, -5
    TW 5, 1

Freq_7825:
    TW 20, 0

Freq_7825_L0:
    TW 3, 2
    TW 3, -2
    TW 3, -2
    TW 3, 2
    TLOOP Freq_7825_L0

OrphanIns_7837:
    INS_TONE $80, $01, $00, Arp_739A, Freq_739F, Comb_7395 ; not in the instrument table

NoiseIns02:
    INS_NOISE $00, $51, $91, Noise_7847, Arp_739A ; $02

Noise_7847:
    TB 255, $44
    TLOOP Noise_7847

NoiseIns04:
    INS_NOISE $00, $47, $01, Noise_785A, Arp_739A ; $04 (unused)

NoiseIns03:
    INS_NOISE $20, $41, $01, Noise_785A, Noise_785A ; $03

Noise_785A:
    TB 255, $13
    TLOOP Noise_785A

NoiseIns01:
    INS_NOISE $80, $44, $01, Noise_7866, Arp_739A ; $01

Noise_7866:
    TB 255, $32
    TLOOP Noise_7866

NoiseIns05:
    INS_NOISE $80, $71, $01, Noise_7872, Arp_739A ; $05 (unused)

Noise_7872:
    TB 2, $45
    TB 255, $32
    TLOOP Noise_7872

Wave_7879:
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

Morph_7889:
    MORPH 255, $30, $00
    TLOOP Morph_7889

Wave_788F:
    db $C0, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

    ; $789F-$78B1: 19 unreferenced bytes
    db $AE, $FF, $EE, $FF, $ED, $DD, $DD, $B7, $31, $01, $34, $32, $33, $31, $00, $05
    db $88, $88, $9B

OrphanIns_78B2:
    INS_NOISE $CE, $FF, $FF, Ins03+4, Song04_Ch4+3 ; not in the instrument table

    ; $78B9-$78BE: 6 unreferenced bytes
    db $76, $54, $21, $11, $24, $67

OrphanIns_78BF:
    INS_NOISE $45, $10, $3A, $66DA, $5379 ; not in the instrument table

    ; $78C6-$78DB: 22 unreferenced bytes
    db $56, $AC, $62, $28, $B5, $37, $87, $42, $00, $00, $11, $33, $55, $77, $99, $BB
    db $DD, $FF, $DD, $BB, $99, $77

OrphanMorph_78DC:
    MORPH 85, $33, $11

OrphanMorph_78DC_Loop:
    MORPH 240, $30, $00
    TLOOP OrphanMorph_78DC_Loop

OrphanMorph_78E5:
    MORPH 248, $30, $45
    TLOOP OrphanMorph_78E5

OrphanMorph_78EB:
    MORPH 192, $30, $77
    TLOOP OrphanMorph_78EB

OrphanMorph_78F1:
    MORPH 6, $30, $AE
    MORPH 6, $31, $FF
    MORPH 6, $32, $EE
    MORPH 6, $33, $FF
    MORPH 6, $34, $ED
    MORPH 6, $35, $DD
    MORPH 6, $36, $DD
    MORPH 6, $37, $B7
    MORPH 6, $38, $31
    MORPH 6, $39, $01
    MORPH 6, $3A, $34
    MORPH 6, $3B, $32
    MORPH 6, $3C, $33
    MORPH 6, $3D, $31
    MORPH 6, $3E, $00
    MORPH 96, $3F, $05
    MORPH 6, $30, $88
    MORPH 6, $31, $88
    MORPH 6, $32, $9B
    MORPH 6, $33, $CE
    MORPH 6, $34, $FF
    MORPH 6, $35, $FF
    MORPH 6, $36, $DA
    MORPH 6, $37, $74
    MORPH 6, $38, $45
    MORPH 6, $39, $67
    MORPH 6, $3A, $76
    MORPH 6, $3B, $54
    MORPH 6, $3C, $21
    MORPH 6, $3D, $11
    MORPH 6, $3E, $24
    MORPH 96, $3F, $67
    TLOOP OrphanMorph_78F1

OrphanMorph_7954:
    MORPH 220, $30, $AE
    TLOOP OrphanMorph_7954

Morph_795A:
    MORPH 7, $30, $C0
    MORPH 7, $30, $CC
    MORPH 7, $31, $C0
    MORPH 7, $31, $CC
    MORPH 7, $32, $C0
    MORPH 7, $32, $CC
    MORPH 7, $33, $C0
    MORPH 7, $33, $CC
    MORPH 7, $34, $C0
    MORPH 7, $34, $CC
    MORPH 7, $35, $C0
    MORPH 7, $35, $CC
    MORPH 7, $36, $C0
    MORPH 7, $36, $CC
    MORPH 7, $37, $C0
    MORPH 7, $37, $CC
    MORPH 7, $38, $C0
    MORPH 7, $38, $CC
    MORPH 7, $39, $C0
    MORPH 7, $39, $CC
    MORPH 7, $3A, $C0
    MORPH 7, $3A, $CC
    MORPH 7, $3B, $C0
    MORPH 7, $3B, $CC
    MORPH 7, $3C, $C0
    MORPH 7, $3C, $CC
    MORPH 7, $3D, $C0
    MORPH 7, $3D, $CC
    MORPH 7, $3E, $C0
    MORPH 7, $3E, $CC
    MORPH 7, $3F, $C0
    MORPH 7, $3F, $00
    MORPH 7, $3E, $C0
    MORPH 7, $3E, $00
    MORPH 7, $3D, $C0
    MORPH 7, $3D, $00
    MORPH 7, $3C, $C0
    MORPH 7, $3C, $00
    MORPH 7, $3B, $C0
    MORPH 7, $3B, $00
    MORPH 7, $3A, $C0
    MORPH 7, $3A, $00
    MORPH 7, $39, $C0
    MORPH 7, $39, $00
    MORPH 7, $38, $C0
    MORPH 7, $38, $00
    MORPH 7, $37, $C0
    MORPH 7, $37, $00
    MORPH 7, $36, $C0
    MORPH 7, $36, $00
    MORPH 7, $35, $C0
    MORPH 7, $35, $00
    MORPH 7, $34, $C0
    MORPH 7, $34, $00
    MORPH 7, $33, $C0
    MORPH 7, $33, $00
    MORPH 7, $32, $C0
    MORPH 7, $32, $00
    MORPH 7, $31, $C0
    MORPH 7, $31, $00
    TLOOP Morph_795A

    ; $7A11-$7A20: 16 unreferenced bytes
    db $78, $88, $76, $53, $21, $00, $01, $24, $68, $AC, $DF, $FF, $FE, $DC, $B9, $88

OrphanMorph_7A21:
    MORPH 80, $3F, $88
    MORPH 1, $30, $A8
    MORPH 1, $31, $65
    MORPH 1, $32, $44
    MORPH 1, $33, $67
    MORPH 1, $34, $AC
    MORPH 1, $35, $DE
    MORPH 1, $36, $ED
    MORPH 1, $37, $CA
    MORPH 1, $38, $98
    MORPH 1, $39, $64
    MORPH 1, $3A, $20
    MORPH 1, $3B, $00
    MORPH 1, $3C, $13
    MORPH 1, $3D, $68
    MORPH 1, $3E, $AC
    MORPH 81, $3F, $CB
    MORPH 1, $30, $30
    MORPH 1, $31, $04
    MORPH 1, $32, $9C
    MORPH 1, $33, $B8
    MORPH 1, $34, $42
    MORPH 1, $35, $37
    MORPH 1, $36, $AC
    MORPH 1, $37, $B8
    MORPH 1, $38, $54
    MORPH 1, $39, $59
    MORPH 1, $3A, $CC
    MORPH 1, $3B, $B8
    MORPH 1, $3C, $66
    MORPH 1, $3D, $8A
    MORPH 1, $3E, $CD
    MORPH 81, $3F, $B7
    MORPH 1, $30, $AB
    MORPH 1, $31, $60
    MORPH 1, $32, $06
    MORPH 1, $33, $B9
    MORPH 1, $34, $41
    MORPH 1, $35, $5A
    MORPH 1, $36, $B7
    MORPH 1, $37, $34
    MORPH 1, $38, $9C
    MORPH 1, $39, $A6
    MORPH 1, $3A, $57
    MORPH 1, $3B, $BC
    MORPH 1, $3C, $96
    MORPH 1, $3D, $7A
    MORPH 1, $3E, $CB
    MORPH 81, $3F, $87
    MORPH 1, $30, $A7
    MORPH 1, $31, $04
    MORPH 1, $32, $A5
    MORPH 1, $33, $18
    MORPH 1, $34, $94
    MORPH 1, $35, $4A
    MORPH 1, $36, $84
    MORPH 1, $37, $7A
    MORPH 1, $38, $75
    MORPH 1, $39, $9A
    MORPH 1, $3A, $77
    MORPH 1, $3B, $B9
    MORPH 1, $3C, $79
    MORPH 1, $3D, $B9
    MORPH 1, $3E, $8B
    MORPH 81, $3F, $B9
    MORPH 1, $30, $13
    MORPH 1, $31, $80
    MORPH 1, $32, $94
    MORPH 1, $33, $49
    MORPH 1, $34, $38
    MORPH 1, $35, $75
    MORPH 1, $36, $A5
    MORPH 1, $37, $78
    MORPH 1, $38, $6A
    MORPH 1, $39, $79
    MORPH 1, $3A, $A8
    MORPH 1, $3B, $A9
    MORPH 1, $3C, $9B
    MORPH 1, $3D, $9B
    MORPH 1, $3E, $AA
    MORPH 81, $3F, $BB
    MORPH 1, $30, $78
    MORPH 1, $31, $88
    MORPH 1, $32, $76
    MORPH 1, $33, $53
    MORPH 1, $34, $21
    MORPH 1, $35, $00
    MORPH 1, $36, $01
    MORPH 1, $37, $24
    MORPH 1, $38, $68
    MORPH 1, $39, $AC
    MORPH 1, $3A, $DF
    MORPH 1, $3B, $FF
    MORPH 1, $3C, $FE
    MORPH 1, $3D, $DC
    MORPH 1, $3E, $B9
    TLOOP OrphanMorph_7A21

TheEnd:
    db "-- THE END --" ; end-of-data marker left by the converter
