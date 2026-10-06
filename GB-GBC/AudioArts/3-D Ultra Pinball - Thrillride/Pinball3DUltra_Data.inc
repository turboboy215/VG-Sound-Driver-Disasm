; 3-D Ultra Pinball: Thrillride (musicd.bin) - music/SFX data $48DF-$7905

    ; $48DF-$48F5: 23 unreferenced bytes
    db $CB, $27, $CB, $27, $CB, $27, $CB, $27, $F6, $08, $EA, $B3, $C5, $C9, $7B, $EA
    db $D1, $C5, $7A, $EA, $D2, $C5, $C9

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
    db 100 ; priority
    dw Sfx01
    db 3 ; ch4, ball fire  (SFX $01)
    db 100 ; priority
    dw Sfx02
    db 2 ; ch2, menu move  (SFX $02)
    db 100 ; priority
    dw Sfx03
    db 2 ; ch2, menu -no  (SFX $03)
    db 100 ; priority
    dw Sfx04
    db 2 ; ch2, menuselect  (SFX $04)
    db 100 ; priority
    dw Sfx05
    db 2 ; ch2, menu back  (SFX $05)
    db 100 ; priority
    dw Sfx06
    db 2 ; ch2, awardlit  (SFX $06)
    db 100 ; priority
    dw Sfx07
    db 2 ; ch2, combo1  (SFX $07)
    db 100 ; priority
    dw Sfx08
    db 2 ; ch2, combo2  (SFX $08)
    db 100 ; priority
    dw Sfx09
    db 2 ; ch2, combo3  (SFX $09)
    db 100 ; priority
    dw Sfx0A
    db 2 ; ch2, combo4  (SFX $0A)
    db 100 ; priority
    dw Sfx0B
    db 2 ; ch2, careful  (SFX $0B)
    db 100 ; priority
    dw Sfx0C
    db 2 ; ch2, danger  (SFX $0C)
    db 100 ; priority
    dw Sfx0D
    db 2 ; ch2, tilt  (SFX $0D)
    db 100 ; priority
    dw Sfx0E
    db 2 ; ch2, light on  (SFX $0E)
    db 100 ; priority
    dw Sfx0F
    db 2 ; ch2, lit  (SFX $0F)
    db 100 ; priority
    dw Sfx10
    db 2 ; ch2, fantasybit  (SFX $10)
    db 100 ; priority
    dw Sfx11
    db 2 ; ch2, lightsbit  (SFX $11)
    db 100 ; priority
    dw Sfx12
    db 2 ; ch2, multiball  (SFX $12)
    db 90 ; priority
    dw Sfx13
    db 2 ; ch2, multi1  (SFX $13)
    db 95 ; priority
    dw Sfx14
    db 2 ; ch2, scoopout  (SFX $14)
    db 100 ; priority
    dw Sfx15
    db 3 ; ch4, lockopen  (SFX $15)
    db 105 ; priority
    dw Sfx16
    db 2 ; ch2, superjack  (SFX $16)
    db 100 ; priority
    dw Sfx17
    db 2 ; ch2, balldrain  (SFX $17)
    db 100 ; priority
    dw Sfx18
    db 2 ; ch2, ballsave  (SFX $18)
    db 100 ; priority
    dw Sfx19
    db 2 ; ch2, shootagian  (SFX $19)
    db 10 ; priority
    dw Sfx1A
    db 3 ; ch4, flipper  (SFX $1A)
    db 100 ; priority
    dw Sfx1B
    db 2 ; ch2, bonustone1  (SFX $1B)
    db 100 ; priority
    dw Sfx1C
    db 2 ; ch2, bonustone2  (SFX $1C)
    db 100 ; priority
    dw Sfx1D
    db 2 ; ch2, bonustone3  (SFX $1D)
    db 100 ; priority
    dw Sfx1E
    db 2 ; ch2, bonustone4  (SFX $1E)
    db 100 ; priority
    dw Sfx1F
    db 2 ; ch2, bonustone5  (SFX $1F)
    db 100 ; priority
    dw Sfx20
    db 2 ; ch2, bonustone6  (SFX $20)
    db 100 ; priority
    dw Sfx21
    db 2 ; ch2, bonustone7  (SFX $21)
    db 100 ; priority
    dw Sfx22
    db 2 ; ch2, bonustone8  (SFX $22)
    db 100 ; priority
    dw Sfx23
    db 2 ; ch2, finalscore  (SFX $23)
    db 100 ; priority
    dw Sfx24
    db 2 ; ch2, charge  (SFX $24)
    db 100 ; priority
    dw Sfx25
    db 2 ; ch2, happytone  (SFX $25)
    db 100 ; priority
    dw Sfx26
    db 2 ; ch2, happybonus  (SFX $26)
    db 100 ; priority
    dw Sfx27
    db 2 ; ch2, stophit  (SFX $27)
    db 110 ; priority
    dw Sfx28
    db 2 ; ch2, stophitvic  (SFX $28)
    db 100 ; priority
    dw Sfx29
    db 2 ; ch2, popbrief  (SFX $29)
    db 100 ; priority
    dw Sfx2A
    db 2 ; ch2, popbrief2  (SFX $2A)
    db 100 ; priority
    dw Sfx2B
    db 2 ; ch2, snack1  (SFX $2B)
    db 100 ; priority
    dw Sfx2C
    db 2 ; ch2, snack2  (SFX $2C)
    db 100 ; priority
    dw Sfx2D
    db 2 ; ch2, snack3  (SFX $2D)
    db 50 ; priority
    dw Sfx2E
    db 3 ; ch4, wildramp  (SFX $2E)
    db 102 ; priority
    dw Sfx2F
    db 2 ; ch2, wildjack  (SFX $2F)
    db 104 ; priority
    dw Sfx30
    db 3 ; ch4, wildphoto  (SFX $30)
    db 105 ; priority
    dw Sfx31
    db 2 ; ch2, brassring  (SFX $31)
    db 100 ; priority
    dw Sfx32
    db 2 ; ch2, funtone  (SFX $32)
    db 100 ; priority
    dw Sfx33
    db 2 ; ch2, funstart  (SFX $33)
    db 100 ; priority
    dw Sfx34
    db 3 ; ch4, funlock  (SFX $34)
    db 100 ; priority
    dw Sfx35
    db 2 ; ch2, kisshit  (SFX $35)
    db 100 ; priority
    dw Sfx36
    db 2 ; ch2, kissdown  (SFX $36)
    db 100 ; priority
    dw Sfx37
    db 2 ; ch2, kissbozo  (SFX $37)
    db 120 ; priority
    dw Sfx38
    db 2 ; ch2, kissvic  (SFX $38)
    db 100 ; priority
    dw Sfx39
    db 2 ; ch2, bumpcar  (SFX $39)
    db 100 ; priority
    dw Sfx3A
    db 2 ; ch2, bumpscore  (SFX $3A)
    db 100 ; priority
    dw Sfx3B
    db 3 ; ch4, rocks  (SFX $3B)
    db 100 ; priority
    dw Sfx3C
    db 2 ; ch2, rivervic  (SFX $3C)
    db 100 ; priority
    dw Sfx3D
    db 2 ; ch2, falcon 1  (SFX $3D)
    db 100 ; priority
    dw Sfx3E
    db 2 ; ch2, lightbozo  (SFX $3E)
    db 100 ; priority
    dw Sfx3F
    db 2 ; ch2, flac bozo  (SFX $3F)
    db 100 ; priority
    dw Sfx40
    db 2 ; ch2, bear up  (SFX $40)
    db 100 ; priority
    dw Sfx41
    db 2 ; ch2, lighthit 2  (SFX $41)
    db 20 ; priority
    dw Sfx42
    db 2 ; ch2, spinner  (SFX $42)
    db 100 ; priority
    dw Sfx43
    db 3 ; ch4, orbit  (SFX $43)
    db 100 ; priority
    dw Sfx44
    db 2 ; ch2, fullboat  (SFX $44)
    db 100 ; priority
    dw Sfx45
    db 2 ; ch2, slingshot  (SFX $45)
    db 100 ; priority
    dw Sfx46
    db 2 ; ch2, kickback  (SFX $46)
    db 100 ; priority
    dw Sfx47
    db 2 ; ch2, park disp  (SFX $47)
    db 100 ; priority
    dw Sfx48
    db 3 ; ch4, RlrCoaste  (SFX $48)
    db 100 ; priority
    dw Sfx49
    db 2 ; ch2, thrilltune  (SFX $49)
    db 110 ; priority
    dw Sfx4A
    db 2 ; ch2, thrillfan  (SFX $4A)
    db 110 ; priority
    dw Sfx4B
    db 2 ; ch2, nightfan  (SFX $4B)
    db 100 ; priority
    dw Sfx4C
    db 2 ; ch2, yellowarrw  (SFX $4C)
    db 101 ; priority
    dw Sfx4D
    db 2 ; ch2, nightvic  (SFX $4D)
    db 101 ; priority
    dw Sfx4E
    db 2 ; ch2, hidefan  (SFX $4E)
    db 100 ; priority
    dw Sfx4F
    db 2 ; ch2, yoohoo  (SFX $4F)
    db 100 ; priority
    dw Sfx50
    db 2 ; ch2, magic  (SFX $50)
    db 100 ; priority
    dw Sfx51
    db 2 ; ch2, snackbonus  (SFX $51)
    db 100 ; priority
    dw Sfx52
    db 2 ; ch2, lightfan  (SFX $52)
    db 100 ; priority
    dw Sfx53
    db 3 ; ch4, lightbulb  (SFX $53)
    db 100 ; priority
    dw Sfx54
    db 2 ; ch2, powerup  (SFX $54)
    db 101 ; priority
    dw Sfx55
    db 2 ; ch2, victory  (SFX $55)
    db 10 ; priority
    dw Sfx56
    db 3 ; ch4, scoopenter  (SFX $56)
    db 10 ; priority
    dw Sfx57
    db 3 ; ch4, bump pop 1  (SFX $57)
    db 10 ; priority
    dw Sfx58
    db 3 ; ch4, bump pop 2  (SFX $58)

Sfx56:
    NOTE 3, $3C, $0F
    KEYOFF 2
    NOTE 3, $3C, $0F
    KEYOFF 2
    SFXEND

NoiseIns15:
    INS_NOISE $80, $F2, $21, Noise_5132, Arp_71E2 ; $0F

Sfx55:
    NOTE 10, A4, $49
    NOTE 10, D5, $49
    NOTE 10, A4, $49
    NOTE 20, D5, $49
    NOTE 10, A4, $49
    NOTE 10, D5, $49
    NOTE 10, A4, $49
    NOTE 10, D5, $49
    NOTE 5, A4, $49
    NOTE 5, E5, $49
    NOTE 5, A4, $49
    NOTE 5, F5, $49
    NOTE 5, A4, $49
    NOTE 5, G5, $49
    NOTE 5, A4, $49
    NOTE 5, A5, $49
    NOTE 5, A4, $49
    NOTE 5, C6, $49
    NOTE 5, A4, $49
    NOTE 10, D6, $49
    SFXEND

Sfx54:
    NOTE 30, C3, $4C
    KEYOFF 8
    SFXEND

Ins76:
    INS_TONE $80, $F8, $F1, Arp_4C52, Freq_4B54, Comb_71DD ; $4C

Freq_4B54:
    TW 60, 24
    TLOOP Freq_4B54

Sfx53:
    NOTE 20, $30, $0E
    SFXEND

NoiseIns14:
    INS_NOISE $80, $C4, $01, Noise_4B67, Arp_71E2 ; $0E

Noise_4B67:
    TB 255, $32
    TLOOP Noise_4B67

Sfx52:
    NOTE 5, G5, $3E
    NOTE 10, A5, $3E
    NOTE 5, D6, $3E
    NOTE 10, C6, $3E
    NOTE 5, G5, $3E
    NOTE 10, A5, $3E
    NOTE 5, C6, $3E
    NOTE 10, D6, $3E
    SFXEND

Sfx51:
    NOTE 2, E6, $49
    NOTE 2, Ds6, $40
    SFXEND

Sfx50:
    NOTE 2, A3, $49
    NOTE 2, B3, $49
    NOTE 2, Cs4, $49
    NOTE 2, D4, $49
    NOTE 2, Ds4, $49
    NOTE 2, E4, $49
    SFXEND

Sfx4F:
    NOTE 15, A5, $4A
    NOTE 15, D5, $4B
    SFXEND

Ins74:
    INS_TONE $C0, $F1, $71, Arp_71E2, Freq_4BC0, Comb_71DD ; $4A

Ins75:
    INS_TONE $C0, $F1, $71, Arp_71E2, $4BC4, Comb_71DD ; $4B

Freq_4BC0:
    TW 15, 2
    db $00 ; part of tend
Freq_4BC4:
    db $0F, $FE ; part of tend

    ; $4BC6-$4BC7: 2 unreferenced bytes
    db $FF, $00

Sfx4E:
    NOTE 5, D5, $49
    NOTE 5, D5, $49
    NOTE 5, D5, $49
    NOTE 5, D5, $49
    NOTE 10, F5, $49
    NOTE 10, E5, $49
    NOTE 20, F5, $49
    KEYOFF 5
    SFXEND

Sfx4D:
    NOTE 5, C4, $49
    NOTE 5, Ds4, $49
    NOTE 5, Fs4, $49
    NOTE 5, Ds4, $49
    NOTE 5, Fs4, $49
    NOTE 5, A4, $49
    NOTE 5, Fs4, $49
    NOTE 5, A4, $49
    NOTE 5, C5, $49
    NOTE 5, A4, $49
    NOTE 5, C5, $49
    NOTE 5, Ds5, $49
    NOTE 5, Fs5, $49
    KEYOFF 50
    SFXEND

Sfx4C:
    NOTE 4, E6, $36
    KEYOFF 4
    SFXEND

Sfx4B:
    NOTE 5, C5, $49
    NOTE 5, B4, $49
    NOTE 5, As4, $49
    NOTE 5, A5, $49
    NOTE 5, C5, $49
    NOTE 5, B4, $49
    NOTE 5, As4, $49
    NOTE 5, A5, $49
    NOTE 5, C5, $49
    NOTE 5, B4, $49
    NOTE 5, As4, $49
    NOTE 5, A5, $49
    NOTE 5, C5, $49
    NOTE 5, B4, $49
    NOTE 5, As4, $49
    NOTE 12, A5, $49
    SFXEND

Ins73:
    INS_TONE $80, $F1, $F4, Arp_4C52, Freq_71E7, Comb_71DD ; $49

Arp_4C52:
    TB 1, $00 ; +0
    TB 1, $0C ; +12
    TB 1, $01 ; +1
    TB 1, $0D ; +13
    TB 1, $00 ; +0
    TB 1, $0C ; +12
    TB 1, $FF ; -1
    TB 1, $0B ; +11
    TLOOP Arp_4C52

Sfx4A:
    NOTE 5, G5, $3E
    NOTE 5, C6, $3E
    NOTE 5, E6, $3E
    NOTE 10, G6, $3E
    NOTE 5, E6, $3E
    NOTE 18, C6, $3E
    SFXEND

Sfx49:
    NOTE 5, C6, $3E
    NOTE 5, E6, $3E
    NOTE 5, G5, $3E
    NOTE 5, G6, $3E
    KEYOFF 5
    SFXEND

Sfx48:
    NOTE 50, $24, $0D
    KEYOFF 50
    SFXEND

NoiseIns13:
    INS_NOISE $00, $1E, $C5, Noise_4C9A, Arp_71E2 ; $0D

Noise_4C9A:
    TB 2, $35
    TB 2, $55
    TLOOP Noise_4C9A

Sfx47:
    NOTE 3, C5, $3E
    NOTE 3, E5, $3E
    NOTE 3, G5, $3E
    NOTE 3, E5, $3E
    NOTE 3, G5, $3E
    NOTE 3, C6, $3E
    NOTE 3, G5, $3E
    NOTE 3, C6, $3E
    NOTE 3, E6, $3E
    NOTE 3, C6, $3E
    NOTE 3, E6, $3E
    NOTE 3, G6, $3E
    KEYOFF 4
    SFXEND

Sfx46:
    NOTE 30, G4, $48
    SFXEND

Ins72:
    INS_TONE $80, $F2, $71, Arp_71E2, Freq_4CD9, Comb_4CDF ; $48

Freq_4CD9:
    TW 255, 20
    TLOOP Freq_4CD9

Comb_4CDF:
    TB 4, $02 ; note + freq table

Comb_4CDF_L0:
    TB 1, $02 ; note + freq table
    TB 1, $01 ; note only
    TLOOP Comb_4CDF_L0

Sfx45:
    NOTE 15, G4, $47
    SFXEND

Ins71:
    INS_TONE $60, $F1, $71, Arp_71E2, Freq_4CF7, Comb_71DD ; $47

Freq_4CF7:
    TW 255, 15
    TLOOP Freq_4CF7

Sfx43:
    NOTE 10, $24, $0C
    KEYOFF 45
    SFXEND

Sfx44:
    NOTE 2, C5, $3E
    NOTE 2, D5, $3E
    NOTE 2, E5, $3E
    NOTE 2, F5, $3E
    NOTE 2, G5, $3E
    NOTE 2, A5, $3E
    NOTE 2, C6, $3E
    NOTE 2, D6, $3E
    NOTE 2, E6, $3E
    NOTE 2, F6, $3E
    NOTE 2, G6, $3E
    KEYOFF 8
    SFXEND

NoiseIns12:
    INS_NOISE $00, $19, $D4, Noise_4D32, Arp_71E2 ; $0C

Noise_4D32:
    TB 5, $44
    TB 5, $43
    TB 255, $31
    TLOOP Noise_4D32

Sfx42:
    NOTE 2, G6, $3A
    KEYOFF 1
    SFXEND

Sfx01:
    NOTE 16, $24, $06
    KEYOFF 12
    SFXEND

NoiseIns06:
    INS_NOISE $00, $F9, $B2, Noise_4D52, Arp_71E2 ; $06

Noise_4D52:
    TB 2, $66
    TB 2, $64
    TB 2, $56
    TB 2, $54
    TB 2, $46
    TB 2, $44
    TB 2, $36
    TB 2, $34
    TB 2, $26
    TB 2, $24
    TB 255, $24

Noise_4D52_L0:
    TB 20, $66
    TLOOP Noise_4D52_L0

Sfx02:
    NOTE 10, G5, $2D
    SFXEND

Ins45:
    INS_TONE $00, $F1, $71, Arp_71E2, Freq_71E7, Comb_71DD ; $2D

Sfx03:
    NOTE 5, C5, $2F
    NOTE 5, C4, $2F
    NOTE 5, C3, $2F
    SFXEND

Ins46:
    INS_TONE $40, $F1, $71, Arp_71E2, Freq_71E7, Comb_71DD ; $2E (unused)

Sfx04:
    NOTE 20, C6, $2F
    SFXEND

Ins47:
    INS_TONE $C0, $F1, $71, Arp_4DA0, Freq_71E7, Comb_71DD ; $2F

Arp_4DA0:
    TB 5, $00 ; +0
    TB 5, $07 ; +7
    TLOOP Arp_4DA0

Sfx05:
    NOTE 20, G5, $30
    SFXEND

Ins48:
    INS_TONE $C0, $F1, $71, Arp_4DB6, Freq_71E7, Comb_71DD ; $30

Arp_4DB6:
    TB 5, $00 ; +0
    TB 255, $FB ; -5
    TLOOP Arp_4DB6

Sfx06:
    NOTE 2, C6, $31
    NOTE 2, Cs6, $31
    NOTE 2, D6, $31
    NOTE 2, Ds6, $31
    NOTE 2, F6, $31
    NOTE 30, Fs6, $31
    SFXEND

Ins49:
    INS_TONE $60, $F3, $C1, Arp_4DDB, Freq_4DE8, Comb_71DD ; $31

Arp_4DDB:
    TB 1, $00 ; +0
    TB 2, $07 ; +7
    TB 2, $0C ; +12
    TB 2, $07 ; +7
    TB 2, $0C ; +12
    TLOOP Arp_4DDB

Freq_4DE8:
    TW 5, 0
    TW 1, 1
    TW 1, -1
    TLOOP Freq_4DE8

Sfx07:
    NOTE 4, A5, $32
    NOTE 4, A5, $32
    NOTE 8, D6, $32
    KEYOFF 8
    SFXEND

Sfx08:
    NOTE 4, A5, $32
    NOTE 4, A5, $32
    NOTE 4, D6, $32
    NOTE 4, E6, $32
    NOTE 8, F6, $32
    KEYOFF 8
    SFXEND

Sfx09:
    NOTE 4, A5, $32
    NOTE 4, A5, $32
    NOTE 4, D6, $32
    NOTE 4, E6, $32
    NOTE 4, F6, $32
    NOTE 4, E6, $32
    NOTE 8, F6, $32
    KEYOFF 8
    SFXEND

Sfx0A:
    NOTE 4, A5, $32
    NOTE 4, A5, $32
    NOTE 4, D6, $32
    NOTE 4, E6, $32
    NOTE 4, F6, $32
    NOTE 4, E6, $32
    NOTE 4, F6, $32
    NOTE 4, C6, $32
    NOTE 8, D6, $32
    KEYOFF 8
    SFXEND

Ins50:
    INS_TONE $60, $F3, $C1, Arp_4E59, Freq_4E66, Comb_71DD ; $32

Arp_4E59:
    TB 1, $00 ; +0
    TB 2, $07 ; +7
    TB 2, $0C ; +12
    TB 2, $07 ; +7
    TB 2, $0C ; +12
    TLOOP Arp_4E59

Freq_4E66:
    TW 5, 0
    TW 1, 1
    TW 1, -1
    TLOOP Freq_4E66

Sfx0B:
    NOTE 6, A5, $33
    KEYOFF 8
    NOTE 6, A5, $33
    KEYOFF 8
    SFXEND

Sfx0C:
    NOTE 6, A5, $33
    NOTE 6, A5, $33
    NOTE 8, A5, $33
    KEYOFF 8
    NOTE 6, A5, $33
    NOTE 6, A5, $33
    NOTE 8, A5, $33
    KEYOFF 8
    SFXEND

Sfx0D:
    NOTE 6, A5, $33
    NOTE 6, A5, $33
    NOTE 12, D5, $33
    KEYOFF 8
    NOTE 12, D5, $33
    KEYOFF 8
    NOTE 12, C5, $33
    KEYOFF 8
    SFXEND

Ins51:
    INS_TONE $80, $F3, $C1, Arp_4EB9, Freq_4EC6, Comb_71DD ; $33

Arp_4EB9:
    TB 1, $00 ; +0
    TB 2, $FD ; -3
    TB 2, $F3 ; -13
    TB 2, $FC ; -4
    TB 2, $F2 ; -14
    TLOOP Arp_4EB9

Freq_4EC6:
    TW 7, 0
    TW 1, 2
    TW 1, -2
    TLOOP Freq_4EC6

Sfx0E:
    NOTE 6, Cs6, $34
    NOTE 254, C2, $00
    PATEND ; SFX end: the driver reads the loop word ($F300) from the next bytes

Ins52:
    INS_TONE $00, $F3, $71, Arp_71E2, Freq_71E7, Comb_71DD ; $34

Sfx0F:
    NOTE 5, D6, $35
    KEYOFF 6
    NOTE 5, G6, $35
    NOTE 6, A6, $35
    KEYOFF 6
    NOTE 6, A6, $35
    KEYOFF 12
    SFXEND

Ins53:
    INS_TONE $00, $F3, $74, Arp_4F00, Freq_71E7, Comb_71DD ; $35

Arp_4F00:
    TB 2, $00 ; +0
    TB 2, $03 ; +3
    TLOOP Arp_4F00

Sfx10:
    NOTE 4, E4, $36
    SFXEND

Ins54:
    INS_TONE $80, $F1, $53, Arp_71E2, Freq_4F16, Comb_71DD ; $36

Freq_4F16:
    TW 5, 50
    TW 2, -10
    TLOOP Freq_4F16

Sfx11:
    NOTE 2, E5, $37
    KEYOFF 2
    SFXEND

Ins55:
    INS_TONE $80, $F9, $71, Arp_71E2, Freq_4F30, Comb_71DD ; $37

Freq_4F30:
    TW 5, 30
    TLOOP Freq_4F30

Sfx12:
    NOTE 30, E5, $38
    KEYOFF 6
    SFXEND

Ins56:
    INS_TONE $40, $F9, $A2, Arp_4F47, Freq_71E7, Comb_71DD ; $38

Arp_4F47:
    TB 4, $00 ; +0
    TB 4, $0C ; +12
    TB 4, $01 ; +1
    TB 4, $0D ; +13
    TB 4, $02 ; +2
    TB 4, $0E ; +14
    TB 4, $03 ; +3
    TB 4, $0F ; +15
    TB 4, $04 ; +4
    TB 4, $10 ; +16
    TB 4, $05 ; +5
    TB 4, $11 ; +17
    TB 4, $06 ; +6
    TB 4, $12 ; +18
    TB 4, $07 ; +7
    TB 4, $13 ; +19
    TB 4, $08 ; +8
    TB 4, $14 ; +20
    TB 4, $09 ; +9
    TB 4, $15 ; +21
    TB 4, $0A ; +10
    TB 4, $16 ; +22
    TLOOP Arp_4F47

Sfx13:
    NOTE 5, A5, $39
    KEYOFF 5
    NOTE 5, A5, $39
    NOTE 5, D5, $39
    NOTE 5, A5, $39
    NOTE 5, D6, $39
    KEYOFF 5
    SFXEND

Ins57:
    INS_TONE $80, $F9, $A2, Arp_4F95, Freq_71E7, Comb_71DD ; $39

Arp_4F95:
    TB 4, $00 ; +0
    TB 4, $0C ; +12
    TB 4, $01 ; +1
    TB 4, $0D ; +13
    TB 4, $02 ; +2
    TB 4, $0E ; +14
    TB 4, $03 ; +3
    TB 4, $0F ; +15
    TB 4, $04 ; +4
    TB 4, $10 ; +16
    TB 4, $05 ; +5
    TB 4, $11 ; +17
    TB 4, $06 ; +6
    TB 4, $12 ; +18
    TB 4, $07 ; +7
    TB 4, $13 ; +19
    TB 4, $08 ; +8
    TB 4, $14 ; +20
    TB 4, $09 ; +9
    TB 4, $15 ; +21
    TB 4, $0A ; +10
    TB 4, $16 ; +22
    TLOOP Arp_4F95

Sfx14:
    NOTE 5, D5, $39
    KEYOFF 5
    NOTE 5, A4, $39
    KEYOFF 5
    SFXEND

Ins58:
    INS_TONE $80, $F9, $21, Arp_4FDA, Freq_71E7, Comb_71DD ; $3A

Arp_4FDA:
    TB 4, $00 ; +0
    TB 4, $F4 ; -12
    TLOOP Arp_4FDA

Sfx15:
    NOTE 2, $18, $07
    KEYOFF 2
    NOTE 6, $17, $07
    SFXEND

NoiseIns07:
    INS_NOISE $80, $D1, $37, Noise_4FF3, Arp_71E2 ; $07

Noise_4FF3:
    TB 5, $52
    TB 255, $42
    TLOOP Noise_4FF3

Sfx16:
    NOTE 4, C5, $3B
    NOTE 4, D5, $3B
    NOTE 4, E5, $3B
    NOTE 4, F5, $3B
    NOTE 4, G5, $3B
    NOTE 4, A5, $3B
    NOTE 4, B5, $3B
    NOTE 4, C6, $3B
    NOTE 4, D6, $3B
    NOTE 4, C5, $3B
    NOTE 4, D5, $3B
    NOTE 4, E5, $3B
    NOTE 4, F5, $3B
    NOTE 4, G5, $3B
    NOTE 4, A5, $3B
    NOTE 4, B5, $3B
    NOTE 4, C6, $3B
    NOTE 8, D6, $3B
    NOTE 4, E6, $3B
    NOTE 4, F6, $3B
    NOTE 4, E6, $3B
    NOTE 4, D6, $3B
    NOTE 4, C6, $3B
    NOTE 18, D6, $3B
    SFXEND

Ins59:
    INS_TONE $60, $F3, $C1, Arp_504E, Freq_5059, Comb_71DD ; $3B

Arp_504E:
    TB 2, $00 ; +0
    TB 2, $0C ; +12
    TB 2, $00 ; +0
    TB 2, $F4 ; -12
    TLOOP Arp_504E

Freq_5059:
    TW 7, 0
    TW 1, 1
    TW 1, -1
    TLOOP Freq_5059

Sfx17:
    NOTE 15, As5, $3C
    NOTE 15, D5, $3C
    NOTE 15, As4, $3C
    SFXEND

Ins60:
    INS_TONE $20, $F3, $C1, Arp_507A, Freq_5091, Comb_71DD ; $3C

Arp_507A:
    TB 3, $00 ; +0
    TB 3, $FF ; -1
    TB 3, $FE ; -2
    TB 3, $FD ; -3
    TB 3, $FC ; -4
    TB 3, $FB ; -5
    TB 3, $FA ; -6
    TB 3, $F9 ; -7
    TB 3, $F8 ; -8
    TB 3, $F7 ; -9
    TLOOP Arp_507A

Freq_5091:
    TW 60, -24
    TLOOP Freq_5091

Sfx18:
    NOTE 15, As3, $3D
    NOTE 15, D4, $3D
    NOTE 15, As4, $3D
    SFXEND

Ins61:
    INS_TONE $20, $F3, $C1, Arp_50AC, Freq_50C3, Comb_71DD ; $3D

Arp_50AC:
    TB 3, $00 ; +0
    TB 3, $01 ; +1
    TB 3, $02 ; +2
    TB 3, $03 ; +3
    TB 3, $04 ; +4
    TB 3, $05 ; +5
    TB 3, $06 ; +6
    TB 3, $07 ; +7
    TB 3, $08 ; +8
    TB 3, $09 ; +9
    TLOOP Arp_50AC

Freq_50C3:
    TW 60, 8
    TLOOP Freq_50C3

Sfx19:
    NOTE 4, D4, $3E
    NOTE 4, F4, $3E
    NOTE 4, D4, $3E
    NOTE 4, G4, $3E
    NOTE 4, D4, $3E
    NOTE 4, A4, $3E
    NOTE 4, D4, $3E
    NOTE 4, As4, $3E
    NOTE 4, D4, $3E
    NOTE 4, C5, $3E
    NOTE 4, D4, $3E
    NOTE 8, D5, $3E
    KEYOFF 8
    SFXEND

Ins62:
    INS_TONE $C0, $F3, $C1, Arp_50FB, Freq_71E7, Comb_71DD ; $3E

Arp_50FB:
    TB 2, $0C ; +12
    TLOOP Arp_50FB

Sfx57:
    NOTE 3, $3C, $10
    KEYOFF 2
    SFXEND

Sfx58:
    NOTE 2, $3C, $10
    KEYOFF 1
    NOTE 2, $3C, $10
    KEYOFF 1
    SFXEND

NoiseIns16:
    INS_NOISE $80, $F1, $21, Noise_511C, Arp_71E2 ; $10

Noise_511C:
    TB 3, $45
    TB 255, $35
    TLOOP Noise_511C

Sfx1A:
    NOTE 3, $3C, $08
    KEYOFF 2
    SFXEND

NoiseIns08:
    INS_NOISE $80, $C1, $21, Noise_5132, Arp_71E2 ; $08

Noise_5132:
    TB 2, $52
    TB 255, $35
    TLOOP Noise_5132

Sfx1B:
    NOTE 4, D5, $3E
    KEYOFF 4
    SFXEND

Sfx1C:
    NOTE 4, E5, $3E
    KEYOFF 4
    SFXEND

Sfx1D:
    NOTE 4, F5, $3E
    KEYOFF 4
    SFXEND

Sfx1E:
    NOTE 4, G5, $3E
    KEYOFF 4
    SFXEND

Sfx1F:
    NOTE 4, A5, $3E
    KEYOFF 4
    SFXEND

Sfx20:
    NOTE 4, B5, $3E
    KEYOFF 4
    SFXEND

Sfx21:
    NOTE 4, C6, $3E
    KEYOFF 4
    SFXEND

Sfx22:
    NOTE 4, D6, $3E
    KEYOFF 4
    SFXEND

Sfx23:
    NOTE 5, F6, $3E
    NOTE 5, G6, $3E
    NOTE 5, A6, $3E
    NOTE 5, F6, $3E
    NOTE 5, G6, $3E
    NOTE 5, A6, $3E
    NOTE 5, F6, $3E
    NOTE 5, G6, $3E
    NOTE 5, A6, $3E
    NOTE 10, G6, $3E
    NOTE 10, F6, $3E
    KEYOFF 2
    SFXEND

Sfx24:
    NOTE 8, D6, $3F
    NOTE 8, D6, $3F
    KEYOFF 8
    SFXEND

Ins63:
    INS_TONE $C0, $F3, $C1, Arp_71E2, Freq_51B3, Comb_71DD ; $3F

Freq_51B3:
    TW 60, -24
    TLOOP Freq_51B3

Sfx25:
    NOTE 8, D4, $40
    KEYOFF 8
    SFXEND

Ins64:
    INS_TONE $C0, $F3, $C1, Arp_71E2, Freq_51CA, Comb_71DD ; $40

Freq_51CA:
    TW 60, 24
    TLOOP Freq_51CA

Sfx26:
    NOTE 4, D5, $40
    NOTE 4, E5, $40
    NOTE 4, F4, $40
    NOTE 4, G4, $40
    NOTE 4, A4, $40
    NOTE 4, As4, $40
    NOTE 4, C5, $40
    KEYOFF 4
    SFXEND

Sfx27:
    NOTE 4, G5, $41
    KEYOFF 4
    SFXEND

Ins65:
    INS_TONE $80, $F3, $C1, Arp_5201, Freq_51FB, Comb_71DD ; $41

Freq_51FB:
    TW 60, -24
    TLOOP Freq_51FB

Arp_5201:
    TB 2, $0C ; +12
    TB 2, $00 ; +0
    TB 2, $07 ; +7
    TLOOP Arp_5201

Sfx28:
    NOTE 4, G5, $41
    NOTE 4, C4, $41
    NOTE 4, G5, $41
    NOTE 4, C6, $41
    NOTE 4, G5, $41
    NOTE 8, F6, $41
    NOTE 8, G6, $41
    NOTE 8, F6, $41
    NOTE 8, G6, $41
    KEYOFF 4
    SFXEND

Sfx29:
    NOTE 4, Fs5, $42
    KEYOFF 4
    SFXEND

Ins66:
    INS_TONE $C0, $F3, $C1, Arp_5241, Freq_523B, Comb_71DD ; $42

Freq_523B:
    TW 5, -12
    TLOOP Freq_523B

Arp_5241:
    TB 2, $00 ; +0
    TB 2, $05 ; +5
    TLOOP Arp_5241

Sfx2A:
    NOTE 4, D5, $42
    NOTE 4, Fs4, $42
    KEYOFF 4
    SFXEND

Ins67:
    INS_TONE $40, $F3, $C1, Arp_5262, Freq_525C, Comb_71DD ; $43

Freq_525C:
    TW 50, 0
    TLOOP Freq_525C

Arp_5262:
    TB 2, $00 ; +0
    TB 2, $03 ; +3
    TB 2, $07 ; +7
    TB 2, $F4 ; -12
    TLOOP Arp_5262

Sfx2B:
    NOTE 4, Cs5, $43
    NOTE 4, Ds5, $43
    NOTE 4, Fs5, $43
    NOTE 4, Gs5, $43
    NOTE 4, As5, $43
    KEYOFF 4
    SFXEND

Sfx2C:
    NOTE 4, Cs5, $43
    NOTE 4, Ds5, $43
    NOTE 4, Fs5, $43
    NOTE 4, Gs5, $43
    NOTE 4, As5, $43
    NOTE 8, Gs5, $43
    NOTE 8, Fs5, $43
    KEYOFF 4
    SFXEND

Sfx2D:
    NOTE 4, Cs5, $43
    NOTE 4, Ds5, $43
    NOTE 4, Fs5, $43
    NOTE 4, Gs5, $43
    NOTE 4, As5, $43
    NOTE 8, Gs5, $43
    NOTE 8, Fs5, $43
    NOTE 4, Ds5, $43
    NOTE 4, Cs5, $43
    NOTE 8, Ds5, $43
    NOTE 4, Fs5, $43
    NOTE 4, Gs5, $43
    NOTE 8, Fs5, $43
    KEYOFF 4
    SFXEND

Sfx2E:
    NOTE 50, $24, $09
    KEYOFF 12
    SFXEND

NoiseIns09:
    INS_NOISE $00, $1D, $B2, Noise_52D6, Arp_71E2 ; $09

Noise_52D6:
    TB 10, $4A
    TB 10, $4A
    TB 10, $4A

Noise_52D6_L0:
    TB 20, $54
    TLOOP Noise_52D6_L0

Sfx2F:
    NOTE 4, Ds5, $43
    NOTE 4, Cs5, $43
    NOTE 4, Ds5, $43
    NOTE 8, As4, $43
    NOTE 4, Ds5, $43
    NOTE 4, Cs5, $43
    NOTE 4, Ds5, $43
    NOTE 8, As4, $43
    NOTE 4, Ds5, $43
    NOTE 4, Cs5, $43
    NOTE 4, Ds5, $43
    NOTE 8, As4, $43
    NOTE 12, Ds5, $43
    KEYOFF 4
    SFXEND

Sfx30:
    NOTE 12, $24, $0A
    KEYOFF 12
    SFXEND

NoiseIns10:
    INS_NOISE $00, $A2, $B2, Noise_531C, Arp_71E2 ; $0A

Noise_531C:
    TB 10, $4A
    TB 20, $24
    TLOOP Noise_531C

Ins68:
    INS_TONE $C0, $F3, $C1, Arp_532C, Freq_71E7, Comb_71DD ; $44

Arp_532C:
    TB 2, $00 ; +0
    TB 2, $05 ; +5
    TB 2, $09 ; +9
    TLOOP Arp_532C

Sfx31:
    NOTE 2, Cs5, $44
    NOTE 2, Ds5, $44
    NOTE 2, Fs5, $44
    NOTE 2, Gs5, $44
    NOTE 2, As5, $44
    NOTE 2, As5, $44
    NOTE 2, Gs5, $44
    NOTE 2, Fs5, $44
    NOTE 2, Ds5, $44
    NOTE 2, Cs5, $44
    KEYOFF 12
    SFXEND

Sfx32:
    NOTE 4, Cs6, $44
    KEYOFF 4
    SFXEND

Sfx33:
    NOTE 8, Ds5, $44
    NOTE 8, Ds5, $44
    NOTE 16, As5, $44
    NOTE 8, Fs5, $44
    NOTE 8, Fs5, $44
    NOTE 16, As6, $44
    NOTE 8, Ds5, $44
    NOTE 8, Ds5, $44
    NOTE 16, As5, $44
    NOTE 8, Fs5, $44
    NOTE 8, Fs5, $44
    NOTE 16, As6, $44
    KEYOFF 4
    SFXEND

Sfx34:
    NOTE 6, $17, $07
    NOTE 2, $18, $07
    KEYOFF 2
    SFXEND

Sfx35:
    NOTE 8, G6, $44
    KEYOFF 4
    SFXEND

Sfx36:
    NOTE 2, D6, $44
    NOTE 2, Cs5, $44
    NOTE 2, C4, $44
    NOTE 2, C3, $44
    NOTE 2, C2, $44
    KEYOFF 4
    SFXEND

Sfx37:
    NOTE 2, D5, $44
    NOTE 2, Cs5, $44
    NOTE 2, C5, $44
    NOTE 2, B5, $44
    NOTE 2, A5, $44
    NOTE 2, G5, $44
    NOTE 2, F5, $44
    NOTE 2, E5, $44
    NOTE 2, D5, $44
    NOTE 2, C5, $44
    NOTE 2, B4, $44
    NOTE 2, A4, $44
    NOTE 2, F4, $44
    NOTE 2, G4, $44
    NOTE 2, F4, $44
    NOTE 2, E4, $44
    NOTE 2, D4, $44
    NOTE 2, C4, $44
    NOTE 2, B3, $44
    NOTE 2, A3, $44
    NOTE 2, G3, $44
    NOTE 2, F3, $44
    NOTE 2, E3, $44
    NOTE 2, D3, $44
    NOTE 2, G4, $44
    NOTE 2, F4, $44
    NOTE 2, E4, $44
    NOTE 2, D4, $44
    NOTE 2, C4, $44
    NOTE 2, B3, $44
    NOTE 2, A3, $44
    NOTE 2, G3, $44
    NOTE 2, F3, $44
    NOTE 2, E3, $44
    NOTE 2, D3, $44
    KEYOFF 4
    SFXEND

Sfx38:
    NOTE 2, D3, $44
    NOTE 2, E3, $44
    NOTE 2, F3, $44
    NOTE 2, G3, $44
    NOTE 2, A3, $44
    NOTE 2, B3, $44
    NOTE 2, C4, $44
    NOTE 2, D4, $44
    NOTE 2, E4, $44
    NOTE 2, F4, $44
    NOTE 2, G4, $44
    NOTE 2, A4, $44
    NOTE 2, B4, $44
    NOTE 2, C5, $44
    NOTE 2, D5, $44
    NOTE 2, E5, $44
    NOTE 2, F5, $44
    NOTE 2, G5, $44
    NOTE 2, A5, $44
    NOTE 2, B5, $44
    NOTE 2, C6, $44
    NOTE 2, E6, $44
    NOTE 2, F6, $44
    NOTE 2, A6, $44
    NOTE 2, A4, $44
    NOTE 2, B4, $44
    NOTE 2, C5, $44
    NOTE 2, D5, $44
    NOTE 2, E5, $44
    NOTE 2, F5, $44
    NOTE 2, G5, $44
    NOTE 2, A5, $44
    NOTE 2, B5, $44
    NOTE 2, C6, $44
    NOTE 2, E6, $44
    NOTE 2, F6, $44
    NOTE 2, A6, $44
    NOTE 2, A4, $44
    NOTE 2, B4, $44
    NOTE 2, C5, $44
    NOTE 2, D5, $44
    NOTE 2, E5, $44
    NOTE 2, F5, $44
    NOTE 2, G5, $44
    NOTE 2, A5, $44
    NOTE 2, B5, $44
    NOTE 2, C6, $44
    NOTE 2, E6, $44
    NOTE 2, F6, $44
    NOTE 2, A6, $44
    NOTE 2, A4, $44
    NOTE 2, B4, $44
    NOTE 2, C5, $44
    NOTE 2, D5, $44
    NOTE 2, E5, $44
    NOTE 2, F5, $44
    NOTE 2, G5, $44
    NOTE 2, A5, $44
    NOTE 2, B5, $44
    NOTE 2, C6, $44
    NOTE 2, E6, $44
    NOTE 2, F6, $44
    NOTE 2, A6, $44
    KEYOFF 4
    SFXEND

Ins69:
    INS_TONE $C0, $F3, $C1, Arp_71E2, Freq_54E9, Comb_71DD ; $45

Freq_54E9:
    TW 60, -2
    TLOOP Freq_54E9

Sfx39:
    NOTE 4, Cs5, $45
    KEYOFF 4
    SFXEND

Sfx3A:
    NOTE 4, Cs5, $45
    NOTE 8, Cs6, $45
    NOTE 4, Cs5, $45
    NOTE 8, Cs6, $45
    NOTE 4, Cs5, $45
    NOTE 8, Cs6, $45
    NOTE 4, Cs5, $45
    NOTE 12, Cs6, $45
    KEYOFF 4
    SFXEND

Sfx3B:
    NOTE 15, $24, $0B
    KEYOFF 25
    SFXEND

NoiseIns11:
    INS_NOISE $00, $F4, $B2, Noise_5523, Arp_71E2 ; $0B

Noise_5523:
    TB 10, $44

Noise_5523_L0:
    TB 20, $55
    TLOOP Noise_5523_L0

Sfx3C:
    NOTE 16, G5, $44
    NOTE 4, G5, $44
    NOTE 4, F5, $44
    NOTE 8, G5, $44
    NOTE 8, C6, $44
    NOTE 8, D6, $44
    NOTE 8, D6, $44
    NOTE 8, C6, $44
    NOTE 8, D6, $44
    KEYOFF 4
    SFXEND

Ins70:
    INS_TONE $C0, $F3, $C1, Arp_5553, Freq_555C, Comb_71DD ; $46

Arp_5553:
    TB 2, $03 ; +3
    TB 2, $07 ; +7
    TB 2, $00 ; +0
    TLOOP Arp_5553

Freq_555C:
    TW 60, 0
    TLOOP Freq_555C

Sfx3D:
    NOTE 10, C7, $46
    NOTE 10, A7, $46
    NOTE 12, G7, $46
    KEYOFF 8
    SFXEND

Sfx3E:
    NOTE 10, C4, $46
    NOTE 10, A4, $46
    NOTE 12, G4, $46
    SFXEND

Sfx3F:
    NOTE 10, D4, $46
    NOTE 10, D4, $46
    NOTE 10, A4, $46
    NOTE 12, F3, $46
    SFXEND

Sfx40:
    NOTE 10, D7, $46
    KEYOFF 8
    SFXEND

Sfx41:
    NOTE 4, G5, $41
    NOTE 4, D6, $41
    NOTE 4, G5, $41
    KEYOFF 4
    SFXEND

SongTable:
    ; song $00: Music off
    db 1, %1111 ; tempo, channel mask
    dw Song00_Ch1, Song00_Ch2, Song00_Ch3, Song00_Ch4
    dw Morph_7657 - 2, Wave_7647 ; wave morph, wave
    ; song $01: Bumper cars
    db 6, %1111 ; tempo, channel mask
    dw Song01_Ch1, Song01_Ch2, Song01_Ch3, Song01_Ch4
    dw Morph_76F6 - 2, Wave_765D ; wave morph, wave
    ; song $02: Multi ball
    db 6, %1111 ; tempo, channel mask
    dw Song02_Ch1, Song02_Ch2, Song02_Ch3, Song01_Ch4
    dw Morph_76F6 - 2, Wave_765D ; wave morph, wave
    ; song $03: Flying falcon
    db 3, %1111 ; tempo, channel mask
    dw Song03_Ch1, Song03_Ch2, Song03_Ch3, Song03_Ch4
    dw Morph_77D3 - 2, Wave_77C3 ; wave morph, wave
    ; song $04: River rapids
    db 7, %1111 ; tempo, channel mask
    dw Song04_Ch1, Song04_Ch2, Song04_Ch3, Song04_Ch4
    dw Morph_76F6 - 2, Wave_765D ; wave morph, wave
    ; song $05: Lights out
    db 6, %1111 ; tempo, channel mask
    dw Song05_Ch1, Song05_Ch2, Song05_Ch3, Song05_Ch4
    dw Morph_76F6 - 2, Wave_765D ; wave morph, wave
    ; song $06: Nite Time
    db 5, %1111 ; tempo, channel mask
    dw Song06_Ch1, Song00_Ch2, Song06_Ch3, Song06_Ch4
    dw Morph_76F6 - 2, Wave_765D ; wave morph, wave
    ; song $07: Thrill Ride
    db 6, %1111 ; tempo, channel mask
    dw Song07_Ch1, Song07_Ch2, Song07_Ch3, Song07_Ch4
    dw Morph_76F6 - 2, Wave_765D ; wave morph, wave
    ; song $08: Shell
    db 5, %1111 ; tempo, channel mask
    dw Song08_Ch1, Song08_Ch2, Song08_Ch3, Song08_Ch4
    dw Morph_77BD - 2, Wave_77AD ; wave morph, wave
    ; song $09: Daylite
    db 6, %1111 ; tempo, channel mask
    dw Song09_Ch1, Song00_Ch2, Song09_Ch3, Song08_Ch4
    dw Morph_76F6 - 2, Wave_765D ; wave morph, wave
    ; song $0A: Thrillzone
    db 5, %1111 ; tempo, channel mask
    dw Song10_Ch1, Song10_Ch2, Song10_Ch3, Song08_Ch4
    dw Morph_76F6 - 2, Wave_765D ; wave morph, wave

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
    dw Pat174                   ; $AE
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
    dw Pat205                   ; $CD
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
    dw Ins30                    ; $1C
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
    dw Ins68                    ; $44
    dw Ins69                    ; $45
    dw Ins70                    ; $46
    dw Ins71                    ; $47
    dw Ins72                    ; $48
    dw Ins73                    ; $49
    dw Ins74                    ; $4A
    dw Ins75                    ; $4B
    dw Ins76                    ; $4C

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

Song01_Ch1:
    STEP 0, $05
    STEP 0, $06
    STEP 0, $05
    STEP 0, $07
    STEP 0, $05
    STEP 0, $06
    STEP 0, $05
    STEP 0, $07
    STEP 5, $05
    STEP 5, $06
    STEP 5, $05
    STEP 5, $07
    STEP 0, $08
    STEP 0, $09
    STEP 0, $08
    STEP 0, $0A
    STEP 0, $0B
    STEP 0, $0C
    STEP 0, $0B
    STEP 0, $1F

Song01_Ch2:
    STEP 0, $1B
    STEP 0, $1B
    STEP 0, $1B
    STEP 0, $1B
    STEP 12, $1B
    STEP 12, $1B
    STEP 12, $1B
    STEP 12, $1B
    STEP 5, $1B
    STEP 5, $1B
    STEP 5, $1B
    STEP 5, $1B
    STEP 0, $1C
    STEP 0, $1D
    STEP 0, $1C
    STEP 0, $1E
    STEP 5, $1B
    STEP 0, $1B
    STEP 5, $1B
    STEP 5, $20

Song01_Ch3:
    STEP 12, $0D
    STEP 12, $0E
    STEP 12, $0D
    STEP 12, $0F
    STEP 12, $0D
    STEP 12, $0E
    STEP 12, $10
    STEP 12, $11
    STEP 12, $12
    STEP 12, $13
    STEP 12, $14
    STEP 12, $15
    STEP 0, $16
    STEP 0, $17
    STEP 0, $16
    STEP 0, $18
    STEP 0, $19
    STEP 0, $1A
    STEP 0, $19
    STEP 0, $21

Song01_Ch4:
    STEP 0, $22

Song02_Ch1:
    STEP 0, $23
    STEP 0, $23
    STEP 0, $23
    STEP 0, $23
    STEP 0, $23
    STEP 0, $23
    STEP 0, $23
    STEP 0, $23
    STEP 0, $24
    STEP 0, $24
    STEP 0, $24
    STEP 0, $24
    STEP 0, $24
    STEP 0, $24
    STEP 0, $24
    STEP 0, $24
    STEP 0, $23
    STEP 0, $23
    STEP 0, $23
    STEP 0, $23
    STEP 0, $23
    STEP 0, $23
    STEP 0, $23
    STEP 0, $23
    STEP 0, $24
    STEP 0, $24
    STEP 0, $24
    STEP 0, $24
    STEP 0, $24
    STEP 0, $24
    STEP 0, $24
    STEP 0, $24
    STEP 0, $25
    STEP 0, $25
    STEP 0, $25
    STEP 0, $25
    STEP 0, $25
    STEP 0, $25
    STEP 0, $25
    STEP 0, $38

Song02_Ch2:
    STEP 0, $36
    STEP 0, $37
    STEP 0, $37
    STEP 0, $36
    STEP 0, $36
    STEP 0, $36
    STEP 0, $36
    STEP 0, $36
    STEP 3, $36
    STEP 3, $37
    STEP 3, $37
    STEP 3, $36
    STEP 3, $36
    STEP 3, $36
    STEP 3, $36
    STEP 3, $36
    STEP 0, $36
    STEP 0, $36
    STEP 0, $36
    STEP 0, $36
    STEP 0, $36
    STEP 0, $36
    STEP 0, $36
    STEP 0, $36
    STEP 3, $36
    STEP 3, $36
    STEP 3, $36
    STEP 3, $36
    STEP 3, $36
    STEP 3, $36
    STEP 3, $36
    STEP 3, $36
    STEP 3, $36
    STEP 3, $36
    STEP 3, $36
    STEP 3, $36
    STEP 3, $36
    STEP 3, $36
    STEP 3, $36
    STEP 3, $39

Song02_Ch3:
    STEP 12, $26
    STEP 12, $27
    STEP 12, $28
    STEP 9, $27
    STEP 12, $29
    STEP 12, $2A
    STEP 12, $2B
    STEP 12, $27
    STEP 3, $26
    STEP 3, $27
    STEP 3, $28
    STEP 0, $27
    STEP 3, $29
    STEP 3, $2C
    STEP 0, $2D
    STEP 12, $27
    STEP 0, $2E
    STEP 0, $2F
    STEP 0, $30
    STEP 0, $31
    STEP 0, $2E
    STEP 0, $2F
    STEP 0, $30
    STEP 0, $31
    STEP 3, $2E
    STEP 3, $2F
    STEP 3, $30
    STEP 3, $31
    STEP 0, $32
    STEP 0, $33
    STEP 0, $34
    STEP 0, $00
    STEP 0, $35
    STEP 0, $35
    STEP 0, $35
    STEP 0, $35
    STEP 12, $35
    STEP 12, $35
    STEP 12, $35
    STEP 12, $3A

Song03_Ch1:
    STEP 0, $3D
    STEP 0, $3E
    STEP 0, $3D
    STEP 0, $3E
    STEP 0, $3F
    STEP 0, $40
    STEP 0, $3F
    STEP 0, $40
    STEP 0, $3D
    STEP 0, $3E
    STEP 0, $3D
    STEP 0, $3E
    STEP 0, $3F
    STEP 0, $40
    STEP 0, $3F
    STEP 0, $40
    STEP 5, $3D
    STEP 5, $3E
    STEP 5, $3D
    STEP 5, $3E
    STEP 5, $3F
    STEP 5, $40
    STEP 5, $3F
    STEP 5, $40
    STEP 5, $3D
    STEP 5, $3E
    STEP 5, $3D
    STEP 5, $3E
    STEP 5, $3F
    STEP 5, $40
    STEP 5, $3F
    STEP 5, $40
    STEP 1, $3D
    STEP 1, $3E
    STEP 1, $3D
    STEP 1, $3E
    STEP 1, $3D
    STEP 1, $3E
    STEP 1, $3D
    STEP 1, $43

Song03_Ch2:
    STEP 0, $41
    STEP 0, $41
    STEP 0, $41
    STEP 0, $42
    STEP 0, $41
    STEP 0, $41
    STEP 0, $41
    STEP 0, $44

Song03_Ch3:
    STEP 0, $3B
    STEP 0, $3C
    STEP 0, $3B
    STEP 0, $3C
    STEP -2, $3B
    STEP -2, $3C
    STEP -2, $3B
    STEP -2, $3C
    STEP 0, $3B
    STEP 0, $3C
    STEP 0, $3B
    STEP 0, $3C
    STEP -2, $3B
    STEP -2, $3C
    STEP -2, $3B
    STEP -2, $3C
    STEP 5, $3B
    STEP 5, $3C
    STEP 5, $3B
    STEP 5, $3C
    STEP 3, $3B
    STEP 3, $3C
    STEP 3, $3B
    STEP 3, $3C
    STEP 5, $3B
    STEP 5, $3C
    STEP 5, $3B
    STEP 5, $3C
    STEP 3, $3B
    STEP 3, $3C
    STEP 3, $3B
    STEP 3, $3C
    STEP 1, $3B
    STEP 1, $3C
    STEP 1, $3B
    STEP 1, $3C
    STEP 1, $3B
    STEP 1, $3C
    STEP 1, $3B
    STEP 1, $45

Song03_Ch4:
    STEP 0, $46

Song04_Ch1:
    STEP 0, $47
    STEP 0, $48
    STEP 0, $47
    STEP 0, $48
    STEP 0, $47
    STEP 0, $48
    STEP 0, $47
    STEP 0, $49
    STEP 0, $47
    STEP 0, $48
    STEP 0, $47
    STEP 0, $48
    STEP 0, $47
    STEP 0, $48
    STEP 0, $4A
    STEP 0, $4B
    STEP 0, $53
    STEP 0, $53
    STEP 2, $53
    STEP 2, $53
    STEP 0, $53
    STEP 0, $53
    STEP 0, $54
    STEP 0, $55
    STEP 0, $53
    STEP 0, $53
    STEP 0, $55
    STEP 0, $55
    STEP 0, $53
    STEP 0, $53
    STEP 0, $54
    STEP 0, $5B

Song04_Ch2:
    STEP 0, $5A
    STEP 0, $5A
    STEP 0, $5A
    STEP 0, $5A
    STEP 0, $5A
    STEP 0, $5A
    STEP 0, $5A
    STEP 0, $5A
    STEP 0, $5A
    STEP 0, $5A
    STEP 0, $5A
    STEP 0, $5A
    STEP 0, $5A
    STEP 0, $5A
    STEP 0, $5A
    STEP 0, $5A
    STEP 0, $57
    STEP 0, $57
    STEP 2, $57
    STEP 2, $57
    STEP 0, $57
    STEP 0, $57
    STEP 7, $57
    STEP 2, $57
    STEP 0, $57
    STEP 0, $57
    STEP 2, $57
    STEP 2, $57
    STEP 0, $57
    STEP 0, $57
    STEP 7, $57
    STEP 2, $5C

Song04_Ch3:
    STEP 0, $4C
    STEP 0, $4D
    STEP 0, $4C
    STEP 0, $4E
    STEP 0, $4C
    STEP 0, $4D
    STEP 0, $4C
    STEP 0, $4F
    STEP 0, $4C
    STEP 0, $4D
    STEP 0, $4C
    STEP 0, $50
    STEP 0, $4C
    STEP 0, $4D
    STEP 0, $51
    STEP 0, $52
    STEP 0, $56
    STEP 0, $56
    STEP 0, $56
    STEP 0, $56
    STEP 0, $56
    STEP 0, $56
    STEP 0, $58
    STEP 0, $59
    STEP 0, $56
    STEP 0, $56
    STEP 0, $56
    STEP 0, $56
    STEP 0, $56
    STEP 0, $56
    STEP 0, $58
    STEP 0, $5D

Song04_Ch4:
    STEP 0, $5E

Song05_Ch1:
    STEP 0, $5F
    STEP 0, $60
    STEP 0, $5F
    STEP 0, $61
    STEP 0, $5F
    STEP 0, $60
    STEP 0, $5F
    STEP 0, $61
    STEP 0, $62
    STEP 0, $63
    STEP 0, $62
    STEP 0, $63
    STEP 0, $62
    STEP 0, $63
    STEP 0, $64
    STEP 2, $64
    STEP 3, $64
    STEP -4, $64
    STEP 0, $64
    STEP -2, $64
    STEP -4, $64
    STEP -4, $76

Song05_Ch2:
    STEP 0, $73
    STEP 0, $74
    STEP 0, $73
    STEP 0, $74
    STEP 0, $73
    STEP 0, $74
    STEP 0, $73
    STEP 0, $74
    STEP 7, $74
    STEP 0, $75
    STEP 7, $74
    STEP 0, $75
    STEP -5, $74
    STEP -12, $75
    STEP 0, $73
    STEP 2, $74
    STEP 7, $74
    STEP 0, $74
    STEP 0, $73
    STEP 2, $74
    STEP 0, $74
    STEP 12, $77

Song05_Ch3:
    STEP 0, $65
    STEP 0, $66
    STEP 0, $65
    STEP 0, $67
    STEP 0, $65
    STEP 0, $66
    STEP 0, $65
    STEP 0, $68
    STEP 0, $69
    STEP 0, $6A
    STEP 0, $69
    STEP 0, $6B
    STEP 0, $6C
    STEP 0, $6D
    STEP 0, $6E
    STEP 0, $00
    STEP 0, $6F
    STEP 0, $70
    STEP 0, $71
    STEP 0, $72
    STEP 0, $00
    STEP 0, $78
    STEP 0, $00 ; (dead: after the song jump)
    STEP 0, $00 ; (dead: after the song jump)
    STEP 0, $00 ; (dead: after the song jump)

Song05_Ch4:
    STEP 0, $8D

Song06_Ch1:
    STEP 0, $79
    STEP 0, $79
    STEP 0, $79
    STEP 0, $79
    STEP 0, $79
    STEP 0, $79
    STEP 0, $79
    STEP 0, $79
    STEP 0, $7B
    STEP 0, $7B
    STEP 0, $7B
    STEP 0, $7B
    STEP 0, $7B
    STEP 0, $7B
    STEP 0, $7B
    STEP 0, $7B
    STEP 0, $7B
    STEP 0, $7B
    STEP 0, $7B
    STEP 0, $7B
    STEP 3, $7B
    STEP 3, $7B
    STEP 3, $7B
    STEP 3, $7B
    STEP 3, $7B
    STEP 3, $7B
    STEP 3, $7B
    STEP 3, $7B
    STEP 7, $7B
    STEP 7, $7B
    STEP 7, $7B
    STEP 7, $7B
    STEP 5, $7B
    STEP 5, $7B
    STEP 5, $7B
    STEP 5, $7B
    STEP 0, $7B
    STEP 0, $7B
    STEP 0, $7B
    STEP 0, $7B
    STEP 0, $7B
    STEP 0, $7B
    STEP 0, $7B
    STEP 0, $7B
    STEP 0, $7B
    STEP 0, $7B
    STEP 0, $7B
    STEP 0, $8B

Song06_Ch3:
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 0, $7A
    STEP 0, $7A
    STEP 12, $7A
    STEP 12, $7A
    STEP 0, $7C
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 0, $7D
    STEP 0, $7E
    STEP 0, $7D
    STEP 0, $7F
    STEP 0, $80
    STEP 0, $81
    STEP 0, $80
    STEP 0, $82
    STEP 3, $7D
    STEP 3, $7E
    STEP 3, $7D
    STEP 3, $7F
    STEP 3, $80
    STEP 3, $81
    STEP 3, $80
    STEP 3, $82
    STEP 0, $83
    STEP 0, $84
    STEP 0, $83
    STEP 0, $85
    STEP 0, $86
    STEP 0, $87
    STEP 0, $88
    STEP 0, $89
    STEP 0, $8A
    STEP 0, $00
    STEP 0, $00
    STEP 0, $00
    STEP 0, $7A
    STEP 0, $7A
    STEP 0, $7A
    STEP 0, $7A
    STEP 12, $7A
    STEP 12, $7A
    STEP 12, $7A
    STEP 12, $8C

Song06_Ch4:
    STEP 0, $8E

Song07_Ch1:
    STEP 0, $8F
    STEP 0, $8F
    STEP 0, $8F
    STEP 0, $8F
    STEP 0, $90
    STEP 0, $90
    STEP 0, $90
    STEP 0, $90
    STEP 0, $91
    STEP 0, $91
    STEP 0, $91
    STEP 0, $91
    STEP 7, $91
    STEP 7, $91
    STEP 7, $91
    STEP 7, $98

Song07_Ch2:
    STEP 0, $94
    STEP 0, $95
    STEP 0, $94
    STEP 0, $95
    STEP 0, $94
    STEP 0, $96
    STEP 0, $94
    STEP 0, $96
    STEP 0, $94
    STEP 0, $97
    STEP 0, $94
    STEP 0, $97
    STEP 0, $94
    STEP 0, $97
    STEP 0, $94
    STEP 0, $99

Song07_Ch3:
    STEP 0, $92
    STEP 0, $92
    STEP 0, $92
    STEP 0, $92
    STEP 0, $93
    STEP 0, $93
    STEP 0, $93
    STEP 0, $93
    STEP -2, $92
    STEP -2, $92
    STEP -2, $92
    STEP -2, $92
    STEP 5, $92
    STEP 5, $92
    STEP 5, $92
    STEP 5, $9A

Song07_Ch4:
    STEP 0, $9B

Song08_Ch1:
    STEP 0, $9C
    STEP 0, $9C
    STEP 0, $9C
    STEP 0, $9C
    STEP 0, $9D
    STEP -4, $9D
    STEP 0, $9C
    STEP 0, $A8

Song08_Ch2:
    STEP 0, $A5
    STEP 0, $A5
    STEP 0, $A5
    STEP 0, $A5
    STEP 0, $A6
    STEP 0, $A7
    STEP 0, $A5
    STEP 0, $A9

Song08_Ch3:
    STEP 0, $9E
    STEP 0, $9F
    STEP 0, $A0
    STEP 0, $A1
    STEP 0, $A2
    STEP 0, $A3
    STEP 0, $A4
    STEP 0, $AA

Song08_Ch4:
    STEP 0, $AB

Song09_Ch1:
    STEP 0, $AC
    STEP 0, $AC
    STEP 0, $AD
    STEP 0, $AE
    STEP 0, $AC
    STEP 0, $AC
    STEP 0, $AD
    STEP 0, $AE
    STEP 0, $AC
    STEP 0, $AC
    STEP 0, $AD
    STEP 0, $AE
    STEP 0, $AC
    STEP 0, $AC
    STEP 0, $AD
    STEP 0, $AE
    STEP 0, $BD
    STEP 0, $AC
    STEP 0, $AD
    STEP 0, $BD
    STEP 0, $AC
    STEP 0, $C1

Song09_Ch3:
    STEP 0, $AF
    STEP 0, $B0
    STEP 0, $B1
    STEP 0, $B2
    STEP 0, $AF
    STEP 0, $B3
    STEP 0, $B4
    STEP 0, $B5
    STEP 0, $B6
    STEP 0, $B7
    STEP 0, $B8
    STEP 0, $B9
    STEP 0, $B6
    STEP 0, $BA
    STEP 0, $BB
    STEP 0, $BC
    STEP 0, $BE
    STEP 0, $BF
    STEP 0, $C0
    STEP 0, $BE
    STEP 0, $BF
    STEP 0, $C2

Song10_Ch1:
    STEP 0, $C3
    STEP 0, $C4
    STEP 0, $C5
    STEP 0, $C6
    STEP 0, $C3
    STEP 0, $C4
    STEP 0, $C5
    STEP 0, $C6
    STEP 0, $C7
    STEP 0, $C8
    STEP 0, $C7
    STEP 0, $C9
    STEP 0, $C7
    STEP 0, $C8
    STEP 0, $C7
    STEP 0, $C9
    STEP 0, $CA
    STEP 0, $CB
    STEP 0, $CC
    STEP 0, $CD
    STEP 3, $CA
    STEP 3, $CB
    STEP 3, $CC
    STEP 3, $DC

Song10_Ch2:
    STEP 0, $D9
    STEP 0, $D9
    STEP -2, $D9
    STEP 5, $D9
    STEP 0, $D9
    STEP 0, $D9
    STEP -2, $D9
    STEP -7, $D9
    STEP -5, $DA
    STEP -2, $D9
    STEP -5, $DA
    STEP 0, $DB
    STEP -5, $DA
    STEP -2, $D9
    STEP -5, $DA
    STEP 0, $DB
    STEP 2, $DB
    STEP 2, $DB
    STEP 2, $DB
    STEP 0, $00
    STEP 5, $DB
    STEP 5, $DB
    STEP 5, $DB
    STEP 5, $DD

Song10_Ch3:
    STEP 0, $CE
    STEP 0, $CF
    STEP 0, $D0
    STEP 0, $D1
    STEP 0, $CE
    STEP 0, $CF
    STEP 0, $D0
    STEP 0, $D2
    STEP 0, $D3
    STEP 0, $D4
    STEP 0, $D3
    STEP 0, $D5
    STEP 0, $D3
    STEP 0, $D4
    STEP 0, $D3
    STEP 0, $D5
    STEP 0, $D6
    STEP 0, $D7
    STEP 0, $D6
    STEP 0, $D8
    STEP 3, $D6
    STEP 3, $D7
    STEP 3, $D6
    STEP 3, $DE

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
    NOTE 2, E2, $03
    NOTE 2, B4, $09
    NOTE 2, E2, $03
    NOTE 2, B4, $09
    NOTE 2, E2, $03
    NOTE 2, Cs5, $0F
    NOTE 1, E2, $03
    NOTE 1, Cs5, $0F
    NOTE 2, Cs5, $0F
    PATEND

Pat006:
    NOTE 2, E2, $03
    NOTE 2, B4, $09
    NOTE 2, E2, $03
    NOTE 2, A4, $09
    NOTE 1, Cs3, $03
    NOTE 1, D3, $03
    NOTE 1, A4, $09
    NOTE 1, E2, $03
    NOTE 2, D3, $03
    NOTE 2, E3, $03
    PATEND

Pat007:
    NOTE 2, E2, $03
    NOTE 2, D5, $06
    NOTE 2, E2, $03
    NOTE 2, D5, $06
    NOTE 1, Cs3, $03
    NOTE 1, Cs2, $03
    NOTE 1, D3, $03
    NOTE 1, D2, $03
    NOTE 1, Cs3, $03
    NOTE 1, Cs2, $03
    NOTE 1, A2, $03
    NOTE 1, G2, $03
    PATEND

Pat008:
    NOTE 2, G2, $03
    NOTE 2, G3, $03
    NOTE 2, G2, $03
    NOTE 2, G3, $03
    NOTE 2, G2, $03
    NOTE 2, G3, $03
    NOTE 2, G2, $03
    NOTE 2, A2, $03
    PATEND

Pat009:
    NOTE 2, A2, $03
    NOTE 2, A3, $03
    NOTE 2, A2, $03
    NOTE 2, A3, $03
    NOTE 2, F2, $03
    NOTE 2, F3, $03
    NOTE 2, Fs2, $03
    NOTE 2, Fs3, $03
    PATEND

Pat010:
    NOTE 2, A2, $03
    NOTE 2, A3, $03
    NOTE 2, A2, $03
    NOTE 2, F2, $03
    NOTE 2, F3, $03
    NOTE 2, F2, $03
    NOTE 2, G2, $03
    NOTE 2, G3, $03
    PATEND

Pat011:
    NOTE 1, G2, $03
    NOTE 2, A2, $03
    NOTE 1, G2, $03
    NOTE 2, A2, $03
    NOTE 1, G2, $03
    NOTE 2, C3, $03
    NOTE 1, G2, $03
    NOTE 6, A2, $03
    PATEND

Pat012:
    NOTE 1, G2, $03
    NOTE 2, A2, $03
    NOTE 1, G2, $03
    NOTE 2, A2, $03
    NOTE 1, G2, $03
    NOTE 2, C3, $03
    NOTE 1, A2, $03
    NOTE 2, E3, $03
    NOTE 2, Ds3, $03
    NOTE 2, C3, $03
    PATEND

Pat013:
    NOTE 2, D4, $26
    NOTE 2, E4, $26
    NOTE 2, Gs4, $26
    NOTE 1, A4, $26
    NOTE 3, Gs4, $26
    NOTE 2, E4, $27
    NOTE 2, D4, $26
    NOTE 2, E4, $26
    PATEND

Pat014:
    NOTE 2, Gs4, $27
    NOTE 1, A4, $26
    NOTE 2, Gs4, $26
    KEYOFF 1
    NOTE 8, D4, $26
    KEYOFF 2
    PATEND

Pat015:
    NOTE 2, Gs4, $27
    NOTE 1, A4, $26
    NOTE 3, Gs4, $26
    NOTE 8, E4, $26
    KEYOFF 2
    PATEND

Pat016:
    NOTE 1, D4, $26
    NOTE 2, E4, $26
    NOTE 1, D4, $26
    NOTE 2, E4, $26
    NOTE 1, D4, $26
    NOTE 2, E4, $26
    NOTE 1, D4, $26
    NOTE 2, E4, $26
    NOTE 1, D4, $26
    NOTE 2, E4, $26
    KEYOFF 1
    PATEND

Pat017:
    NOTE 2, E4, $26
    NOTE 1, D4, $26
    NOTE 2, E4, $26
    NOTE 1, D4, $26
    NOTE 2, E4, $26
    NOTE 2, Cs4, $26
    NOTE 2, D4, $26
    NOTE 2, Cs4, $26
    NOTE 2, A4, $26
    PATEND

Pat018:
    NOTE 3, A4, $26
    NOTE 1, G4, $26
    NOTE 2, A4, $26
    NOTE 1, G4, $26
    NOTE 2, A4, $26
    NOTE 1, G4, $26
    NOTE 2, A4, $26
    NOTE 1, G4, $26
    NOTE 2, A4, $26
    NOTE 1, G4, $26
    PATEND

Pat019:
    NOTE 2, A4, $26
    NOTE 1, G4, $26
    NOTE 2, B4, $26
    NOTE 1, G4, $26
    NOTE 8, A4, $26
    KEYOFF 2
    PATEND

Pat020:
    NOTE 1, G4, $26
    NOTE 2, A4, $26
    NOTE 1, G4, $26
    NOTE 2, Cs5, $26
    NOTE 1, A4, $26
    NOTE 2, D5, $26
    NOTE 1, A4, $26
    NOTE 2, E5, $26
    NOTE 2, D5, $26
    NOTE 2, Cs5, $26
    PATEND

Pat021:
    NOTE 2, D5, $26
    NOTE 1, Cs5, $26
    NOTE 2, D5, $26
    NOTE 1, Cs5, $26
    NOTE 6, A4, $26
    KEYOFF 4
    PATEND

Pat022:
    HOLD 2
    NOTE 2, G5, $2A
    NOTE 2, B5, $2A
    NOTE 4, D6, $2B
    NOTE 4, A5, $2A
    NOTE 2, C6, $2B
    PATEND

Pat023:
    HOLD 2
    NOTE 2, B5, $2A
    NOTE 2, A5, $2A
    NOTE 4, F5, $2A
    NOTE 2, G5, $2A
    NOTE 2, A5, $2A
    NOTE 2, G5, $2A
    PATEND

Pat024:
    HOLD 2
    NOTE 2, B5, $2A
    NOTE 2, A5, $2A
    NOTE 6, F5, $2A
    NOTE 3, G5, $2A
    KEYOFF 1
    PATEND

Pat025:
    NOTE 1, G5, $2A
    NOTE 2, A5, $2A
    NOTE 1, G5, $2A
    NOTE 2, A5, $2A
    NOTE 1, G5, $2A
    NOTE 2, C6, $2A
    NOTE 1, G5, $2A
    NOTE 2, A5, $2A
    KEYOFF 4
    PATEND

Pat026:
    NOTE 1, G5, $2A
    NOTE 2, A5, $2A
    NOTE 1, G5, $2A
    NOTE 2, A5, $2A
    NOTE 1, G5, $2A
    NOTE 2, C6, $2A
    NOTE 1, A5, $2A
    NOTE 2, E6, $2A
    NOTE 2, Ds6, $2A
    NOTE 2, C6, $2A
    PATEND

Pat027:
    NOTE 1, E4, $21
    NOTE 2, E4, $21
    NOTE 1, E4, $21
    NOTE 2, F4, $1D
    NOTE 4, E4, $21
    NOTE 2, E4, $21
    NOTE 3, F4, $1D
    NOTE 1, F4, $1D
    PATEND

Pat028:
    NOTE 2, B3, $0F
    NOTE 2, B3, $0F
    NOTE 2, B3, $0F
    NOTE 2, B3, $0F
    NOTE 2, B3, $0F
    NOTE 2, B3, $0F
    NOTE 2, B3, $0F
    NOTE 2, C4, $0B
    PATEND

Pat029:
    NOTE 2, C4, $0B
    NOTE 2, C4, $0B
    NOTE 2, C4, $0B
    NOTE 2, A4, $0F
    NOTE 2, A4, $0F
    NOTE 2, A4, $0F
    NOTE 2, A4, $0F
    NOTE 2, A4, $0F
    PATEND

Pat030:
    NOTE 2, C4, $0B
    NOTE 2, C4, $0B
    NOTE 2, C4, $0B
    NOTE 2, A4, $0F
    NOTE 2, A4, $0F
    NOTE 2, A4, $0F
    NOTE 2, B4, $0F
    NOTE 2, B4, $0F
    PATEND

Pat031:
    NOTE 1, G2, $03
    NOTE 2, A2, $03
    NOTE 1, G2, $03
    NOTE 2, A2, $03
    NOTE 1, G2, $03
    NOTE 2, C3, $03
    NOTE 1, A2, $03
    NOTE 2, E3, $03
    NOTE 2, Ds3, $03
    NOTE 2, C3, $03
    SONGJUMP Song01_Ch1

Pat032:
    NOTE 1, E4, $21
    NOTE 2, E4, $21
    NOTE 1, E4, $21
    NOTE 2, F4, $1D
    NOTE 4, E4, $21
    NOTE 2, E4, $21
    NOTE 3, F4, $1D
    NOTE 1, F4, $1D
    SONGJUMP Song01_Ch2

Pat033:
    NOTE 1, G5, $2A
    NOTE 2, A5, $2A
    NOTE 1, G5, $2A
    NOTE 2, A5, $2A
    NOTE 1, G5, $2A
    NOTE 2, C6, $2A
    NOTE 1, A5, $2A
    NOTE 2, E6, $2A
    NOTE 2, Ds6, $2A
    NOTE 2, C6, $2A
    SONGJUMP Song01_Ch3

Pat034:
    NOTE 2, $24, $02
    NOTE 2, $24, $03
    NOTE 2, $24, $05
    NOTE 2, $24, $03
    NOTE 2, $24, $02
    NOTE 2, $24, $03
    NOTE 3, $24, $05
    NOTE 1, $24, $05
    SONGJUMP Song01_Ch4

Pat035:
    NOTE 2, B2, $03
    NOTE 1, B4, $21
    NOTE 1, Fs2, $03
    NOTE 2, B3, $1D
    NOTE 2, A2, $03
    NOTE 1, Fs2, $03
    NOTE 1, Fs3, $03
    NOTE 1, Fs2, $03
    NOTE 1, B4, $21
    NOTE 1, B3, $1D
    NOTE 1, A3, $03
    NOTE 2, As2, $03
    PATEND

Pat036:
    NOTE 2, D3, $03
    NOTE 1, D4, $21
    NOTE 1, A2, $03
    NOTE 2, B3, $1D
    NOTE 2, D3, $03
    NOTE 1, A2, $03
    NOTE 1, A3, $03
    NOTE 1, C3, $03
    NOTE 1, D4, $21
    NOTE 1, B3, $1D
    NOTE 1, D3, $03
    NOTE 2, C3, $03
    PATEND

Pat037:
    NOTE 1, D3, $03
    NOTE 1, D3, $03
    KEYOFF 1
    NOTE 1, D3, $03
    NOTE 1, C4, $1D
    KEYOFF 3
    NOTE 4, C3, $1E
    NOTE 2, C4, $1D
    NOTE 1, C4, $1D
    NOTE 1, C4, $1D
    PATEND

Pat038:
    NOTE 12, Ds5, $2C
    NOTE 4, B4, $26
    PATEND

Pat039:
    NOTE 14, A4, $26
    KEYOFF 2
    PATEND

Pat040:
    NOTE 12, Cs5, $2C
    NOTE 4, Gs4, $26
    PATEND

Pat041:
    HOLD 2
    NOTE 3, Fs4, $27
    NOTE 3, Gs4, $26
    NOTE 3, A4, $26
    NOTE 3, B4, $26
    NOTE 2, Cs5, $26
    PATEND

Pat042:
    NOTE 3, Ds5, $26
    NOTE 3, E5, $26
    NOTE 2, Fs5, $26
    NOTE 3, Gs5, $26
    NOTE 3, A5, $27
    NOTE 2, Gs5, $26
    PATEND

Pat043:
    NOTE 12, Fs5, $26
    NOTE 4, Ds5, $26
    PATEND

Pat044:
    NOTE 3, Ds5, $26
    NOTE 3, E5, $26
    NOTE 2, Fs5, $26
    NOTE 3, Gs5, $26
    NOTE 3, A5, $27
    NOTE 2, B5, $26
    PATEND

Pat045:
    NOTE 12, E6, $2C
    NOTE 4, C6, $26
    PATEND

Pat046:
    NOTE 3, B5, $13
    NOTE 3, B5, $13
    NOTE 2, A5, $13
    NOTE 3, B5, $13
    NOTE 3, Fs5, $12
    NOTE 2, A5, $13
    PATEND

Pat047:
    NOTE 3, B5, $13
    NOTE 3, B5, $13
    NOTE 2, A5, $13
    NOTE 3, Cs6, $12
    NOTE 3, A5, $13
    NOTE 2, B5, $13
    PATEND

Pat048:
    NOTE 3, B5, $13
    NOTE 3, B5, $13
    NOTE 2, A5, $13
    NOTE 3, B5, $13
    NOTE 3, A5, $13
    NOTE 2, Fs5, $12
    PATEND

Pat049:
    NOTE 16, Ds5, $12
    PATEND

Pat050:
    NOTE 3, Fs6, $12
    NOTE 3, E6, $12
    NOTE 2, D6, $13
    NOTE 3, C6, $13
    NOTE 3, B5, $12
    NOTE 2, A5, $12
    PATEND

Pat051:
    NOTE 3, G5, $13
    NOTE 3, Fs5, $12
    NOTE 2, E5, $12
    NOTE 4, C5, $13
    NOTE 2, C5, $13
    NOTE 2, B4, $12
    PATEND

Pat052:
    NOTE 4, C5, $13
    NOTE 2, C5, $13
    NOTE 2, B4, $12
    NOTE 2, C5, $13
    NOTE 2, B4, $12
    NOTE 2, A4, $12
    NOTE 2, Fs4, $12
    PATEND

Pat053:
    NOTE 1, D5, $1B
    NOTE 2, D5, $1B
    NOTE 3, D5, $1B
    NOTE 1, D5, $18
    NOTE 2, D5, $18
    NOTE 1, D5, $18
    NOTE 2, D5, $18
    NOTE 4, D5, $16
    PATEND

Pat054:
    NOTE 3, Fs4, $09
    NOTE 3, Fs4, $09
    NOTE 3, Fs4, $09
    NOTE 3, Fs4, $09
    NOTE 2, Fs4, $09
    NOTE 2, Fs4, $09
    PATEND

Pat055:
    NOTE 3, Fs4, $07
    NOTE 3, Fs4, $07
    NOTE 3, Fs4, $07
    NOTE 3, Fs4, $07
    NOTE 2, Fs4, $07
    NOTE 2, Fs4, $07
    PATEND

Pat056:
    NOTE 1, D3, $03
    NOTE 1, D3, $03
    KEYOFF 1
    NOTE 1, D3, $03
    NOTE 1, C4, $1D
    KEYOFF 3
    NOTE 4, C3, $1E
    NOTE 2, C4, $1D
    NOTE 1, C4, $1D
    NOTE 1, C4, $1D
    SONGJUMP Song02_Ch1

Pat057:
    NOTE 3, Fs4, $09
    NOTE 3, Fs4, $09
    NOTE 3, Fs4, $09
    NOTE 3, Fs4, $09
    NOTE 2, Fs4, $09
    NOTE 2, Fs4, $09
    SONGJUMP Song02_Ch2

Pat058:
    NOTE 1, D5, $1B
    NOTE 2, D5, $1B
    NOTE 3, D5, $1B
    NOTE 1, D5, $18
    NOTE 2, D5, $18
    NOTE 1, D5, $18
    NOTE 2, D5, $18
    NOTE 4, D5, $16
    SONGJUMP Song02_Ch3

Pat059:
    NOTE 1, G5, $28
    NOTE 1, G6, $29
    NOTE 1, C6, $28
    NOTE 1, G5, $29
    NOTE 1, E6, $28
    NOTE 1, C6, $29
    NOTE 1, G6, $28
    NOTE 1, E6, $29
    NOTE 1, E6, $28
    NOTE 1, G6, $29
    NOTE 1, C6, $28
    NOTE 1, E6, $29
    NOTE 1, G5, $28
    NOTE 1, C6, $29
    NOTE 1, C6, $28
    NOTE 1, G5, $29
    PATEND

Pat060:
    NOTE 1, E6, $28
    NOTE 1, C6, $29
    NOTE 1, G6, $28
    NOTE 1, E6, $29
    NOTE 1, E6, $28
    NOTE 1, G6, $29
    NOTE 1, C6, $28
    NOTE 1, E6, $29
    NOTE 1, G5, $28
    NOTE 1, C6, $29
    NOTE 1, C6, $28
    NOTE 1, G5, $29
    NOTE 1, E6, $28
    NOTE 1, C6, $29
    NOTE 1, G6, $28
    NOTE 1, E6, $29
    PATEND

Pat061:
    NOTE 4, C2, $03
    NOTE 2, C2, $03
    NOTE 2, C3, $03
    NOTE 4, C5, $06
    NOTE 2, C2, $03
    NOTE 2, C3, $03
    PATEND

Pat062:
    NOTE 4, C2, $03
    NOTE 4, C5, $06
    NOTE 2, C2, $03
    NOTE 2, C2, $03
    NOTE 2, C3, $03
    NOTE 2, C2, $03
    PATEND

Pat063:
    NOTE 4, C2, $03
    NOTE 2, C2, $03
    NOTE 2, C3, $03
    NOTE 4, As4, $06
    NOTE 2, C2, $03
    NOTE 2, C3, $03
    PATEND

Pat064:
    NOTE 4, C2, $03
    NOTE 4, As4, $06
    NOTE 2, C2, $03
    NOTE 2, C2, $03
    NOTE 2, C3, $03
    NOTE 2, C2, $03
    PATEND

Pat065:
    NOTE 4, C3, $1E
    NOTE 4, C7, $1F
    NOTE 4, C5, $1D
    NOTE 4, C3, $1E
    PATEND

Pat066:
    NOTE 4, C3, $1E
    NOTE 2, C7, $1F
    NOTE 2, C7, $1F
    NOTE 2, C5, $1D
    NOTE 2, C7, $1F
    NOTE 2, C5, $1D
    NOTE 2, C5, $1D
    PATEND

Pat067:
    NOTE 4, C2, $03
    NOTE 4, C5, $06
    NOTE 2, C2, $03
    NOTE 2, C2, $03
    NOTE 2, C3, $03
    NOTE 2, C2, $03
    SONGJUMP Song03_Ch1

Pat068:
    NOTE 4, C3, $1E
    NOTE 2, C7, $1F
    NOTE 2, C7, $1F
    NOTE 2, C5, $1D
    NOTE 2, C7, $1F
    NOTE 2, C5, $1D
    NOTE 2, C5, $1D
    SONGJUMP Song03_Ch2

Pat069:
    NOTE 1, E6, $28
    NOTE 1, C6, $29
    NOTE 1, G6, $28
    NOTE 1, E6, $29
    NOTE 1, E6, $28
    NOTE 1, G6, $29
    NOTE 1, C6, $28
    NOTE 1, E6, $29
    NOTE 1, G5, $28
    NOTE 1, C6, $29
    NOTE 1, C6, $28
    NOTE 1, G5, $29
    NOTE 1, E6, $28
    NOTE 1, C6, $29
    NOTE 1, G6, $28
    NOTE 1, E6, $29
    SONGJUMP Song03_Ch3

Pat070:
    NOTE 4, $24, $02
    NOTE 4, $24, $03
    NOTE 4, $24, $05
    NOTE 4, $24, $02
    NOTE 4, $24, $02
    NOTE 4, $24, $03
    NOTE 4, $24, $05
    NOTE 4, $24, $02
    NOTE 4, $24, $02
    NOTE 4, $24, $03
    NOTE 4, $24, $05
    NOTE 4, $24, $02
    NOTE 4, $24, $02
    NOTE 4, $24, $03
    NOTE 4, $24, $05
    NOTE 2, $24, $05
    NOTE 2, $24, $05
    SONGJUMP Song03_Ch4

Pat071:
    NOTE 2, Ds3, $05
    NOTE 1, As4, $09
    NOTE 2, Ds3, $05
    NOTE 1, As4, $09
    NOTE 2, Cs3, $05
    NOTE 1, Gs4, $09
    NOTE 2, Cs3, $05
    NOTE 1, Gs4, $09
    NOTE 1, Cs3, $05
    NOTE 1, Gs4, $09
    NOTE 2, Cs3, $05
    PATEND

Pat072:
    NOTE 2, Gs2, $05
    NOTE 1, Gs4, $06
    NOTE 2, Gs2, $05
    NOTE 1, Gs4, $06
    NOTE 2, Fs2, $05
    NOTE 1, As4, $0F
    NOTE 2, Fs2, $05
    NOTE 1, As4, $0F
    NOTE 2, Fs2, $05
    NOTE 1, Fs2, $05
    NOTE 1, As4, $0F
    PATEND

Pat073:
    NOTE 2, As2, $05
    NOTE 1, Ds5, $02
    NOTE 2, As2, $05
    NOTE 1, Ds5, $02
    NOTE 2, As2, $05
    NOTE 1, D5, $0F
    NOTE 2, As2, $05
    NOTE 1, D5, $0F
    NOTE 1, As2, $05
    NOTE 2, D3, $05
    NOTE 1, D5, $0F
    PATEND

Pat074:
    NOTE 2, As2, $05
    NOTE 1, Ds5, $02
    NOTE 2, As2, $05
    NOTE 1, Ds5, $02
    NOTE 2, As2, $05
    NOTE 1, Ds5, $02
    NOTE 2, As2, $05
    NOTE 1, Ds5, $02
    NOTE 2, As2, $05
    NOTE 1, As2, $05
    NOTE 1, Ds5, $02
    PATEND

Pat075:
    NOTE 2, As3, $05
    NOTE 1, D5, $0F
    NOTE 2, As3, $05
    NOTE 1, D5, $0F
    NOTE 2, As3, $05
    NOTE 1, D5, $0F
    NOTE 2, As3, $05
    NOTE 1, D5, $0F
    NOTE 2, As3, $05
    NOTE 2, As3, $05
    PATEND

Pat076:
    NOTE 1, As4, $26
    NOTE 2, C5, $26
    NOTE 1, Ds5, $26
    KEYOFF 1
    NOTE 1, C5, $26
    NOTE 8, Ds5, $27
    KEYOFF 2
    PATEND

Pat077:
    NOTE 1, Fs5, $26
    NOTE 2, Ds5, $26
    NOTE 1, Ds5, $26
    KEYOFF 1
    NOTE 1, C5, $26
    NOTE 8, Ds5, $27
    KEYOFF 2
    PATEND

Pat078:
    NOTE 1, Fs5, $26
    NOTE 2, Ds5, $26
    NOTE 1, Fs5, $26
    KEYOFF 1
    NOTE 2, Fs5, $27
    NOTE 1, Ds5, $26
    NOTE 1, Fs5, $26
    KEYOFF 1
    NOTE 2, Fs5, $26
    NOTE 1, Ds5, $26
    NOTE 2, Fs5, $26
    KEYOFF 1
    PATEND

Pat079:
    NOTE 1, As4, $26
    NOTE 2, As4, $27
    NOTE 2, As4, $26
    NOTE 1, As4, $26
    NOTE 2, As4, $27
    NOTE 1, As4, $26
    NOTE 2, As4, $27
    NOTE 2, As4, $26
    NOTE 1, As4, $26
    NOTE 2, As4, $27
    PATEND

Pat080:
    NOTE 1, Fs5, $27
    NOTE 1, Ds5, $26
    KEYOFF 1
    NOTE 1, Fs5, $27
    NOTE 1, Ds5, $26
    KEYOFF 1
    NOTE 1, Fs5, $27
    NOTE 1, Ds5, $26
    KEYOFF 1
    NOTE 1, Fs5, $27
    NOTE 1, Ds5, $26
    KEYOFF 1
    NOTE 1, Fs5, $27
    NOTE 3, Ds5, $26
    PATEND

Pat081:
    NOTE 3, As5, $27
    NOTE 3, As5, $27
    NOTE 2, As5, $27
    NOTE 3, As5, $27
    NOTE 3, As5, $27
    NOTE 2, As5, $27
    PATEND

Pat082:
    NOTE 3, As5, $27
    NOTE 3, As5, $27
    NOTE 2, As5, $27
    NOTE 3, As5, $27
    NOTE 2, As5, $27
    NOTE 1, As5, $26
    NOTE 1, Gs5, $26
    NOTE 1, Fs5, $26
    PATEND

Pat083:
    NOTE 2, Gs2, $03
    NOTE 2, Gs2, $03
    NOTE 2, Gs3, $03
    NOTE 1, Gs3, $03
    NOTE 2, Fs3, $03
    NOTE 1, Fs3, $03
    NOTE 2, F3, $03
    NOTE 2, Ds3, $03
    NOTE 2, C3, $03
    PATEND

Pat084:
    NOTE 2, Ds3, $03
    NOTE 2, Ds3, $03
    NOTE 2, G2, $03
    NOTE 1, G2, $03
    NOTE 2, Gs2, $03
    NOTE 1, Gs2, $03
    NOTE 2, Gs2, $03
    NOTE 2, As2, $03
    NOTE 2, As2, $03
    PATEND

Pat085:
    NOTE 2, As2, $03
    NOTE 2, As2, $03
    NOTE 2, As3, $03
    NOTE 1, As3, $03
    NOTE 2, Gs3, $03
    NOTE 1, Gs3, $03
    NOTE 2, G3, $03
    NOTE 2, F3, $03
    NOTE 2, As2, $03
    PATEND

Pat086:
    NOTE 1, As5, $28
    NOTE 1, Gs5, $28
    NOTE 1, Fs5, $28
    NOTE 2, Ds5, $28
    NOTE 1, Fs5, $29
    NOTE 1, As5, $28
    NOTE 1, Gs5, $28
    NOTE 1, Fs5, $28
    NOTE 2, Ds5, $28
    NOTE 1, Fs5, $29
    NOTE 1, As5, $28
    NOTE 1, Gs5, $28
    NOTE 1, Fs5, $28
    NOTE 1, Ds5, $28
    PATEND

Pat087:
    NOTE 2, Cs5, $02
    NOTE 2, Cs5, $02
    NOTE 2, Cs5, $02
    NOTE 2, C5, $0F
    NOTE 2, C5, $0F
    NOTE 2, C5, $0F
    NOTE 2, C5, $0F
    NOTE 2, C5, $0F
    PATEND

Pat088:
    NOTE 2, As5, $28
    NOTE 2, Ds6, $29
    NOTE 2, Gs5, $28
    NOTE 2, Ds6, $29
    NOTE 2, G5, $28
    NOTE 2, Ds6, $29
    NOTE 2, F5, $28
    NOTE 2, Ds6, $29
    PATEND

Pat089:
    NOTE 2, Ds5, $28
    NOTE 2, D6, $29
    NOTE 2, D5, $28
    NOTE 2, D6, $29
    NOTE 2, C5, $28
    NOTE 2, D6, $29
    NOTE 2, As4, $28
    NOTE 2, D6, $29
    PATEND

Pat090:
    NOTE 4, C4, $1E
    NOTE 2, G4, $1D
    NOTE 4, C4, $1E
    NOTE 2, C4, $1E
    NOTE 4, G4, $1D
    PATEND

Pat091:
    NOTE 2, As2, $03
    NOTE 2, As2, $03
    NOTE 2, As3, $03
    NOTE 1, As3, $03
    NOTE 2, Gs3, $03
    NOTE 1, Gs3, $03
    NOTE 2, G3, $03
    NOTE 2, F3, $03
    NOTE 2, As2, $03
    SONGJUMP Song04_Ch1

Pat092:
    NOTE 2, Cs5, $02
    NOTE 2, Cs5, $02
    NOTE 2, Cs5, $02
    NOTE 2, C5, $0F
    NOTE 2, C5, $0F
    NOTE 2, C5, $0F
    NOTE 2, C5, $0F
    NOTE 2, C5, $0F
    SONGJUMP Song04_Ch2

Pat093:
    NOTE 2, Ds5, $28
    NOTE 2, D6, $29
    NOTE 2, D5, $28
    NOTE 2, D6, $29
    NOTE 2, C5, $28
    NOTE 2, D6, $29
    NOTE 2, As4, $28
    db $02, $32 ; part of note
NoiseCtl_6746:
    db $29 ; part of note
    SONGJUMP Song04_Ch3

Pat094:
    NOTE 4, $18, $02
    NOTE 2, $1F, $05
    NOTE 4, $18, $02
    NOTE 2, $18, $02
    NOTE 4, $1F, $05
    SONGJUMP Song04_Ch4

Pat095:
    NOTE 2, A2, $03
    NOTE 2, A2, $03
    NOTE 2, C5, $1D
    NOTE 2, A2, $03
    NOTE 2, A2, $03
    NOTE 2, A2, $03
    NOTE 2, C5, $1D
    NOTE 2, F2, $03
    PATEND

Pat096:
    HOLD 2
    NOTE 2, F2, $03
    NOTE 2, C5, $1D
    NOTE 2, F2, $03
    NOTE 2, F2, $03
    NOTE 2, F2, $03
    NOTE 2, C5, $1D
    NOTE 2, F2, $03
    PATEND

Pat097:
    HOLD 2
    NOTE 2, F2, $03
    NOTE 2, C5, $1D
    NOTE 2, F2, $03
    NOTE 2, F2, $03
    NOTE 2, F2, $03
    NOTE 2, C5, $1D
    NOTE 2, G2, $03
    PATEND

Pat098:
    NOTE 2, C3, $03
    NOTE 2, C3, $03
    NOTE 2, C5, $1D
    NOTE 2, C3, $03
    NOTE 2, C3, $03
    NOTE 2, C3, $03
    NOTE 2, C5, $1D
    NOTE 2, F2, $03
    PATEND

Pat099:
    HOLD 2
    NOTE 2, F2, $03
    NOTE 2, C5, $1D
    NOTE 4, G2, $03
    NOTE 2, G2, $03
    NOTE 2, C5, $1D
    NOTE 2, G2, $03
    PATEND

Pat100:
    NOTE 2, A2, $03
    NOTE 2, A2, $03
    NOTE 2, C5, $1D
    NOTE 2, A2, $03
    NOTE 2, A2, $03
    NOTE 2, A2, $03
    NOTE 2, C5, $1D
    NOTE 2, A2, $03
    PATEND

Pat101:
    NOTE 2, E5, $27
    NOTE 2, E5, $26
    NOTE 2, B5, $26
    NOTE 4, C6, $26
    NOTE 2, E5, $26
    NOTE 2, C6, $26
    NOTE 2, B5, $26
    PATEND

Pat102:
    HOLD 6
    NOTE 8, C6, $27
    KEYOFF 2
    PATEND

Pat103:
    HOLD 4
    NOTE 10, A5, $27
    KEYOFF 2
    PATEND

Pat104:
    HOLD 6
    NOTE 4, C6, $26
    NOTE 4, D6, $26
    NOTE 2, E6, $27
    PATEND

Pat105:
    HOLD 10
    NOTE 2, D6, $26
    NOTE 2, E6, $26
    NOTE 2, F6, $27
    PATEND

Pat106:
    HOLD 2
    NOTE 2, E6, $26
    NOTE 2, D6, $26
    NOTE 4, C6, $26
    NOTE 4, D6, $26
    NOTE 2, E6, $27
    PATEND

Pat107:
    HOLD 2
    NOTE 2, E6, $26
    NOTE 2, D6, $26
    NOTE 4, E6, $26
    NOTE 4, F6, $26
    NOTE 2, G6, $26
    PATEND

Pat108:
    HOLD 10
    NOTE 2, F6, $26
    NOTE 2, G6, $26
    NOTE 2, A6, $26
    PATEND

Pat109:
    HOLD 2
    NOTE 2, G6, $26
    NOTE 2, F6, $26
    NOTE 4, E6, $26
    NOTE 4, F6, $26
    NOTE 2, E6, $26
    PATEND

Pat110:
    HOLD 10
    NOTE 2, D6, $26
    NOTE 2, E6, $26
    NOTE 2, D6, $26
    PATEND

Pat111:
    NOTE 10, E6, $26
    NOTE 2, F6, $26
    NOTE 2, G6, $26
    NOTE 2, A6, $26
    PATEND

Pat112:
    HOLD 2
    NOTE 2, G6, $26
    NOTE 2, F6, $26
    NOTE 4, E6, $26
    NOTE 4, F6, $26
    NOTE 2, E6, $26
    PATEND

Pat113:
    NOTE 10, E6, $26
    NOTE 2, D6, $26
    NOTE 2, E6, $26
    NOTE 2, D6, $26
    PATEND

Pat114:
    HOLD 10
    NOTE 2, C6, $26
    NOTE 2, B5, $26
    NOTE 2, C6, $26
    PATEND

Pat115:
    NOTE 2, C5, $0B
    NOTE 2, C5, $0B
    NOTE 2, C5, $0B
    NOTE 2, C5, $0B
    NOTE 2, C5, $0B
    NOTE 2, C5, $0B
    NOTE 2, C5, $0B
    NOTE 2, C5, $0B
    PATEND

Pat116:
    NOTE 2, C5, $09
    NOTE 2, C5, $09
    NOTE 2, C5, $09
    NOTE 2, C5, $09
    NOTE 2, C5, $09
    NOTE 2, C5, $09
    NOTE 2, C5, $09
    NOTE 2, C5, $09
    PATEND

Pat117:
    NOTE 2, F5, $06
    NOTE 2, F5, $06
    NOTE 2, F5, $06
    NOTE 2, F5, $06
    NOTE 2, G5, $06
    NOTE 2, G5, $06
    NOTE 2, G5, $06
    NOTE 2, G5, $06
    PATEND

Pat118:
    NOTE 2, A2, $03
    NOTE 2, A2, $03
    NOTE 2, C5, $1D
    NOTE 2, A2, $03
    NOTE 2, A2, $03
    NOTE 2, A2, $03
    NOTE 2, C5, $1D
    NOTE 2, A2, $03
    SONGJUMP Song05_Ch1

Pat119:
    NOTE 2, C5, $09
    NOTE 2, C5, $09
    NOTE 2, C5, $09
    NOTE 2, C5, $09
    NOTE 2, C5, $09
    NOTE 2, C5, $09
    NOTE 2, C5, $09
    NOTE 2, C5, $09
    SONGJUMP Song05_Ch2

Pat120:
    HOLD 14
    KEYOFF 2
    SONGJUMP Song05_Ch3

Pat121:
    NOTE 2, B2, $05
    NOTE 2, Fs2, $05
    NOTE 2, B2, $05
    NOTE 2, Fs2, $05
    NOTE 2, G2, $05
    NOTE 2, Fs2, $05
    NOTE 2, A2, $05
    NOTE 2, Fs2, $05
    PATEND

Pat122:
    NOTE 2, B4, $1B
    NOTE 2, Fs4, $1B
    NOTE 2, B4, $1B
    NOTE 2, Fs4, $1B
    NOTE 2, G4, $1B
    NOTE 2, Fs4, $1B
    NOTE 2, A4, $1B
    NOTE 2, Fs4, $1B
    PATEND

Pat123:
    NOTE 1, E2, $05
    NOTE 1, G5, $0B
    NOTE 1, E3, $05
    NOTE 1, G5, $0B
    NOTE 1, C4, $1D
    NOTE 1, G5, $0B
    NOTE 1, E3, $05
    NOTE 1, G5, $0B
    NOTE 1, E2, $05
    NOTE 1, G5, $0B
    NOTE 1, E3, $05
    NOTE 1, G5, $0B
    NOTE 1, C4, $1D
    NOTE 1, G5, $0B
    NOTE 1, E3, $05
    NOTE 1, G5, $0B
    PATEND

Pat124:
    NOTE 16, E4, $2C
    PATEND

Pat125:
    NOTE 2, E5, $1B
    NOTE 2, Fs5, $1B
    NOTE 2, G5, $1B
    NOTE 4, A5, $1B
    NOTE 4, B5, $1B
    NOTE 2, Fs5, $1B
    PATEND

Pat126:
    HOLD 2
    NOTE 4, G5, $1B
    NOTE 2, E5, $1B
    NOTE 4, Fs5, $1B
    NOTE 4, B4, $1B
    PATEND

Pat127:
    HOLD 2
    NOTE 4, G5, $1B
    NOTE 2, E5, $1B
    NOTE 4, Fs5, $1B
    NOTE 4, A4, $1B
    PATEND

Pat128:
    NOTE 2, B5, $14
    NOTE 2, Cs6, $14
    NOTE 2, D6, $14
    NOTE 4, E6, $14
    NOTE 4, Fs6, $14
    NOTE 2, Cs6, $14
    PATEND

Pat129:
    HOLD 2
    NOTE 4, D6, $14
    NOTE 2, B5, $14
    NOTE 4, Cs6, $14
    NOTE 4, Fs5, $14
    PATEND

Pat130:
    HOLD 2
    NOTE 4, D6, $14
    NOTE 2, E6, $14
    NOTE 4, Cs6, $14
    NOTE 4, Fs5, $14
    PATEND

Pat131:
    NOTE 2, D6, $26
    NOTE 2, Cs6, $26
    NOTE 2, D6, $26
    NOTE 2, Cs6, $26
    NOTE 2, B5, $26
    NOTE 2, As5, $26
    NOTE 2, B5, $26
    NOTE 2, Cs6, $26
    PATEND

Pat132:
    NOTE 1, D6, $26
    NOTE 1, Fs5, $26
    NOTE 1, Cs6, $26
    NOTE 1, E5, $26
    NOTE 1, D6, $26
    NOTE 1, Fs5, $26
    NOTE 1, Cs6, $26
    NOTE 1, E5, $26
    NOTE 1, B5, $26
    NOTE 1, D5, $26
    NOTE 1, As5, $26
    NOTE 1, Cs5, $26
    NOTE 1, B5, $26
    NOTE 1, D5, $26
    NOTE 1, Cs6, $26
    NOTE 1, E5, $26
    PATEND

Pat133:
    NOTE 1, D6, $26
    NOTE 1, Fs6, $26
    NOTE 1, Cs6, $26
    NOTE 1, E6, $26
    NOTE 1, D6, $26
    NOTE 1, Fs6, $26
    NOTE 1, Cs6, $26
    NOTE 1, E6, $26
    NOTE 1, B5, $26
    NOTE 1, D6, $26
    NOTE 1, As5, $26
    NOTE 1, Cs6, $26
    NOTE 1, B5, $26
    NOTE 1, D6, $26
    NOTE 1, Cs6, $26
    NOTE 1, E6, $26
    PATEND

Pat134:
    NOTE 8, C6, $26
    NOTE 8, B5, $26
    PATEND

Pat135:
    NOTE 8, A5, $26
    NOTE 8, G5, $26
    PATEND

Pat136:
    NOTE 8, C6, $26
    NOTE 8, D6, $26
    PATEND

Pat137:
    NOTE 8, G5, $26
    NOTE 8, A5, $26
    PATEND

Pat138:
    NOTE 16, E5, $26
    PATEND

Pat139:
    NOTE 1, E2, $05
    NOTE 1, G5, $0B
    NOTE 1, E3, $05
    NOTE 1, G5, $0B
    NOTE 1, C4, $1D
    NOTE 1, G5, $0B
    NOTE 1, E3, $05
    NOTE 1, G5, $0B
    NOTE 1, E2, $05
    NOTE 1, G5, $0B
    NOTE 1, E3, $05
    NOTE 1, G5, $0B
    NOTE 1, C4, $1D
    NOTE 1, G5, $0B
    NOTE 1, E3, $05
    NOTE 1, G5, $0B
    SONGJUMP Song06_Ch1

Pat140:
    NOTE 2, B4, $1B
    NOTE 2, Fs4, $1B
    NOTE 2, B4, $1B
    NOTE 2, Fs4, $1B
    NOTE 2, G4, $1B
    NOTE 2, Fs4, $1B
    NOTE 2, A4, $1B
    NOTE 2, Fs4, $1B
    SONGJUMP Song06_Ch3

Pat141:
    NOTE 4, $24, $02
    NOTE 4, $24, $01
    NOTE 4, $24, $02
    NOTE 4, $24, $01
    SONGJUMP Song05_Ch4

Pat142:
    NOTE 2, $24, $02
    NOTE 2, $24, $03
    NOTE 2, $24, $01
    NOTE 2, $24, $03
    NOTE 2, $24, $02
    NOTE 2, $24, $03
    NOTE 2, $24, $01
    NOTE 2, $24, $03
    SONGJUMP Song06_Ch4

Pat143:
    NOTE 1, G2, $05
    NOTE 1, G3, $05
    NOTE 1, G2, $05
    NOTE 1, F5, $0C
    NOTE 2, G3, $1D
    NOTE 1, F5, $0C
    NOTE 1, G3, $05
    NOTE 1, G4, $20
    NOTE 1, G2, $05
    NOTE 1, G3, $05
    NOTE 1, F5, $0C
    NOTE 1, G3, $1D
    NOTE 1, G3, $05
    NOTE 1, G2, $05
    NOTE 1, F5, $0C
    PATEND

Pat144:
    NOTE 1, As2, $05
    NOTE 1, As3, $05
    NOTE 1, As2, $05
    NOTE 1, F5, $0C
    NOTE 2, As3, $1D
    NOTE 1, F5, $0C
    NOTE 1, As3, $05
    NOTE 1, As5, $20
    NOTE 1, As2, $05
    NOTE 1, As3, $05
    NOTE 1, F5, $0C
    NOTE 1, As3, $1D
    NOTE 1, As3, $05
    NOTE 1, As2, $05
    NOTE 1, F5, $0C
    PATEND

Pat145:
    NOTE 1, F2, $05
    NOTE 1, F3, $05
    NOTE 1, F2, $05
    NOTE 1, F5, $06
    NOTE 2, F3, $1D
    NOTE 1, F5, $06
    NOTE 1, F3, $05
    NOTE 1, F5, $20
    NOTE 1, F2, $05
    NOTE 1, F3, $05
    NOTE 1, F5, $06
    NOTE 1, F3, $1D
    NOTE 1, F3, $05
    NOTE 1, F2, $05
    NOTE 1, F5, $06
    PATEND

Pat146:
    NOTE 1, C6, $28
    NOTE 1, B5, $28
    NOTE 1, G5, $28
    NOTE 1, C6, $28
    NOTE 1, B5, $28
    NOTE 1, G5, $28
    NOTE 1, C6, $28
    NOTE 1, B5, $28
    NOTE 1, G5, $28
    NOTE 1, C6, $28
    NOTE 1, B5, $28
    NOTE 1, G5, $28
    NOTE 1, C6, $28
    NOTE 1, B5, $28
    NOTE 1, G5, $28
    NOTE 1, B5, $28
    PATEND

Pat147:
    NOTE 1, C6, $28
    NOTE 1, As5, $28
    NOTE 1, F5, $28
    NOTE 1, C6, $28
    NOTE 1, As5, $28
    NOTE 1, F5, $28
    NOTE 1, C6, $28
    NOTE 1, As5, $28
    NOTE 1, F5, $28
    NOTE 1, C6, $28
    NOTE 1, As5, $28
    NOTE 1, F5, $28
    NOTE 1, C6, $28
    NOTE 1, As5, $28
    NOTE 1, F5, $28
    NOTE 1, As5, $28
    PATEND

Pat148:
    NOTE 16, C5, $24
    PATEND

Pat149:
    HOLD 6
    NOTE 6, B4, $25
    NOTE 4, A4, $24
    PATEND

Pat150:
    HOLD 6
    NOTE 10, As4, $24
    PATEND

Pat151:
    HOLD 6
    NOTE 6, As4, $25
    NOTE 4, A4, $24
    PATEND

Pat152:
    NOTE 1, F2, $05
    NOTE 1, F3, $05
    NOTE 1, F2, $05
    NOTE 1, F5, $06
    NOTE 2, F3, $1D
    NOTE 1, F5, $06
    NOTE 1, F3, $05
    NOTE 1, F5, $20
    NOTE 1, F2, $05
    NOTE 1, F3, $05
    NOTE 1, F5, $06
    NOTE 1, F3, $1D
    NOTE 1, F3, $05
    NOTE 1, F2, $05
    NOTE 1, F5, $06
    SONGJUMP Song07_Ch1

Pat153:
    HOLD 6
    NOTE 6, As4, $25
    NOTE 4, A4, $24
    SONGJUMP Song07_Ch2

Pat154:
    NOTE 1, C6, $28
    NOTE 1, B5, $28
    NOTE 1, G5, $28
    NOTE 1, C6, $28
    NOTE 1, B5, $28
    NOTE 1, G5, $28
    NOTE 1, C6, $28
    NOTE 1, B5, $28
    NOTE 1, G5, $28
    NOTE 1, C6, $28
    NOTE 1, B5, $28
    NOTE 1, G5, $28
    NOTE 1, C6, $28
    NOTE 1, B5, $28
    NOTE 1, G5, $28
    NOTE 1, B5, $28
    SONGJUMP Song07_Ch3

Pat155:
    NOTE 2, $24, $03
    NOTE 2, $24, $03
    NOTE 2, $24, $01
    NOTE 2, $24, $03
    NOTE 2, $24, $03
    NOTE 2, $24, $03
    NOTE 2, $24, $01
    NOTE 2, $24, $04
    SONGJUMP Song07_Ch4

Pat156:
    NOTE 2, G2, $03
    NOTE 2, G2, $03
    NOTE 2, G3, $03
    NOTE 2, G2, $03
    NOTE 2, G3, $1D
    NOTE 2, G2, $03
    NOTE 2, F3, $03
    NOTE 2, G3, $03
    PATEND

Pat157:
    NOTE 2, A2, $03
    NOTE 2, A2, $03
    NOTE 2, A3, $03
    NOTE 2, A2, $03
    NOTE 2, G3, $1D
    NOTE 2, A2, $03
    NOTE 2, A3, $03
    NOTE 2, A2, $03
    PATEND

Pat158:
    NOTE 2, F5, $26
    NOTE 2, E5, $26
    NOTE 2, F5, $26
    NOTE 4, G5, $26
    NOTE 6, D6, $18
    PATEND

Pat159:
    NOTE 6, D6, $19
    NOTE 6, D6, $18
    NOTE 2, D5, $26
    NOTE 2, D5, $26
    PATEND

Pat160:
    NOTE 2, F5, $26
    NOTE 2, E5, $26
    NOTE 2, F5, $26
    NOTE 4, B4, $26
    NOTE 6, D6, $18
    PATEND

Pat161:
    NOTE 2, D6, $18
    NOTE 4, D6, $19
    NOTE 4, D6, $18
    NOTE 2, D5, $26
    NOTE 2, F5, $26
    NOTE 2, G5, $26
    PATEND

Pat162:
    NOTE 15, A5, $2C
    KEYOFF 1
    PATEND

Pat163:
    NOTE 6, A5, $27
    NOTE 2, As5, $26
    NOTE 2, A5, $27
    NOTE 2, G5, $26
    NOTE 2, F5, $26
    NOTE 2, G5, $26
    PATEND

Pat164:
    HOLD 4
    NOTE 6, D6, $18
    NOTE 6, D6, $18
    PATEND

Pat165:
    NOTE 2, G4, $20
    NOTE 2, D5, $09
    NOTE 2, G5, $20
    NOTE 2, G4, $20
    NOTE 2, D5, $09
    NOTE 2, D5, $09
    NOTE 2, G5, $20
    NOTE 2, D5, $09
    PATEND

Pat166:
    NOTE 2, A4, $20
    NOTE 2, G5, $02
    NOTE 2, A4, $20
    NOTE 2, A5, $20
    NOTE 2, G5, $02
    NOTE 2, G5, $02
    NOTE 2, A4, $20
    NOTE 2, G5, $02
    PATEND

Pat167:
    NOTE 2, F4, $20
    NOTE 2, F5, $06
    NOTE 2, F4, $20
    NOTE 2, F5, $20
    NOTE 2, F5, $06
    NOTE 2, F5, $06
    NOTE 2, F4, $20
    NOTE 2, F5, $06
    PATEND

Pat168:
    NOTE 2, G2, $03
    NOTE 2, G2, $03
    NOTE 2, G3, $03
    NOTE 2, G2, $03
    NOTE 2, G3, $1D
    NOTE 2, G2, $03
    NOTE 2, F3, $03
    NOTE 2, G3, $03
    SONGJUMP Song08_Ch1

Pat169:
    NOTE 2, G4, $20
    NOTE 2, D5, $09
    NOTE 2, G5, $20
    NOTE 2, G4, $20
    NOTE 2, D5, $09
    NOTE 2, D5, $09
    NOTE 2, G5, $20
    NOTE 2, D5, $09
    SONGJUMP Song08_Ch2

Pat170:
    NOTE 6, D6, $19
    NOTE 6, D6, $18
    NOTE 2, D5, $26
    NOTE 2, D5, $26
    SONGJUMP Song08_Ch3

Pat171:
    NOTE 2, $24, $02
    NOTE 2, $24, $03
    NOTE 2, $24, $05
    NOTE 2, $24, $03
    NOTE 2, $24, $02
    NOTE 2, $24, $03
    NOTE 2, $24, $05
    NOTE 2, $24, $02
    SONGJUMP Song08_Ch4

Pat172:
    NOTE 2, A2, $05
    NOTE 1, A4, $0D
    NOTE 1, A2, $05
    NOTE 1, G3, $1D
    NOTE 1, A2, $05
    NOTE 2, G2, $05
    NOTE 2, A2, $05
    NOTE 2, A4, $0D
    NOTE 2, G3, $1D
    NOTE 2, A4, $0D
    PATEND

Pat173:
    NOTE 2, A2, $05
    NOTE 1, A4, $0D
    NOTE 1, A2, $05
    NOTE 1, G3, $1D
    NOTE 1, A2, $05
    NOTE 2, G2, $05
    NOTE 2, A2, $05
    NOTE 2, C3, $05
    NOTE 2, Cs3, $05
    NOTE 1, A4, $0D
    NOTE 1, G2, $05
    PATEND

Pat174:
    NOTE 2, A2, $05
    NOTE 1, A4, $0D
    NOTE 1, A2, $05
    NOTE 1, G3, $1D
    NOTE 1, A2, $05
    NOTE 2, G2, $05
    NOTE 2, A2, $05
    NOTE 2, A4, $0D
    NOTE 2, Ds3, $05
    NOTE 2, Ds5, $0D
    PATEND

Pat175:
    NOTE 4, Cs6, $2C
    NOTE 8, Cs6, $27
    NOTE 2, B5, $26
    NOTE 2, A5, $26
    PATEND

Pat176:
    NOTE 3, Cs6, $27
    NOTE 1, B5, $26
    NOTE 10, A5, $26
    NOTE 2, E5, $26
    PATEND

Pat177:
    NOTE 4, Cs6, $2C
    NOTE 2, D6, $26
    NOTE 2, E6, $26
    NOTE 4, Cs6, $2C
    NOTE 2, B5, $26
    NOTE 2, A5, $26
    PATEND

Pat178:
    NOTE 12, G5, $26
    NOTE 4, C6, $26
    PATEND

Pat179:
    NOTE 2, G6, $2C
    NOTE 2, Fs6, $26
    NOTE 2, E6, $26
    NOTE 2, Fs6, $26
    NOTE 2, C6, $27
    NOTE 2, B5, $26
    NOTE 2, A5, $26
    KEYOFF 1
    NOTE 1, A5, $26
    PATEND

Pat180:
    NOTE 2, D6, $26
    NOTE 2, Cs6, $26
    NOTE 2, D6, $26
    NOTE 2, E6, $26
    NOTE 2, Cs6, $27
    NOTE 4, Cs6, $2C
    NOTE 2, B5, $26
    PATEND

Pat181:
    NOTE 16, A5, $26
    PATEND

Pat182:
    NOTE 16, E6, $12
    PATEND

Pat183:
    NOTE 12, E6, $12
    NOTE 4, D6, $13
    PATEND

Pat184:
    NOTE 2, Cs6, $12
    NOTE 2, E5, $1B
    NOTE 2, G5, $1B
    NOTE 2, A5, $1B
    NOTE 3, Cs6, $1B
    NOTE 3, A5, $1B
    NOTE 2, E5, $1B
    PATEND

Pat185:
    HOLD 2
    NOTE 2, Fs5, $1B
    NOTE 2, A5, $1B
    NOTE 1, B5, $1B
    NOTE 1, A5, $1B
    KEYOFF 8
    PATEND

Pat186:
    NOTE 12, E6, $12
    NOTE 4, E6, $13
    PATEND

Pat187:
    NOTE 2, E6, $14
    NOTE 2, Fs5, $1B
    NOTE 2, A5, $1B
    NOTE 2, B5, $1B
    NOTE 3, Cs6, $1B
    NOTE 3, A5, $1B
    NOTE 2, E6, $1B
    PATEND

Pat188:
    HOLD 2
    NOTE 2, D6, $1B
    NOTE 2, Cs6, $1B
    NOTE 1, B5, $1B
    NOTE 2, A5, $1B
    KEYOFF 7
    PATEND

Pat189:
    NOTE 2, Fs2, $05
    NOTE 2, Cs3, $05
    NOTE 2, Fs3, $05
    NOTE 4, G2, $05
    NOTE 2, D3, $05
    NOTE 2, A2, $05
    NOTE 2, Ds3, $05
    PATEND

Pat190:
    NOTE 1, Cs6, $26
    NOTE 1, B5, $26
    NOTE 1, A5, $26
    NOTE 1, Cs6, $26
    NOTE 1, B5, $26
    NOTE 1, A5, $26
    NOTE 1, B5, $26
    NOTE 1, A5, $26
    NOTE 1, G5, $26
    NOTE 1, B5, $26
    NOTE 1, A5, $26
    NOTE 1, G5, $26
    NOTE 1, B5, $26
    NOTE 1, A5, $26
    NOTE 1, G5, $26
    NOTE 1, A5, $26
    PATEND

Pat191:
    HOLD 2
    NOTE 1, A5, $1B
    NOTE 2, A5, $1B
    NOTE 1, A5, $1B
    NOTE 2, Fs5, $1B
    NOTE 7, A5, $1B
    NOTE 1, A5, $1B
    PATEND

Pat192:
    NOTE 2, A5, $1B
    NOTE 1, A5, $1B
    NOTE 2, Fs5, $1B
    NOTE 1, E5, $1B
    NOTE 1, F5, $1B
    NOTE 1, Fs5, $1B
    NOTE 8, A5, $1B
    PATEND

Pat193:
    NOTE 2, A2, $05
    NOTE 1, A4, $0D
    NOTE 1, A2, $05
    NOTE 1, G3, $1D
    NOTE 1, A2, $05
    NOTE 2, G2, $05
    NOTE 2, A2, $05
    NOTE 2, C3, $05
    NOTE 2, Cs3, $05
    NOTE 1, A4, $0D
    NOTE 1, G2, $05
    SONGJUMP Song09_Ch1

Pat194:
    NOTE 2, A5, $1B
    NOTE 1, A5, $1B
    NOTE 2, Fs5, $1B
    NOTE 1, E5, $1B
    NOTE 1, F5, $1B
    NOTE 1, Fs5, $1B
    NOTE 8, A5, $1B
    SONGJUMP Song09_Ch3

Pat195:
    NOTE 2, C3, $03
    NOTE 2, C3, $03
    NOTE 2, A3, $1D
    NOTE 2, G2, $03
    NOTE 2, C3, $03
    NOTE 2, C3, $03
    NOTE 2, A3, $1D
    NOTE 2, C3, $03
    PATEND

Pat196:
    HOLD 2
    NOTE 2, C3, $03
    NOTE 2, A3, $1D
    NOTE 2, G2, $03
    NOTE 2, C3, $03
    NOTE 2, C3, $03
    NOTE 2, A3, $1D
    NOTE 2, As2, $03
    PATEND

Pat197:
    HOLD 2
    NOTE 2, As2, $03
    NOTE 2, A3, $1D
    NOTE 2, As2, $03
    NOTE 2, As2, $03
    NOTE 2, As2, $03
    NOTE 2, A3, $1D
    NOTE 2, F2, $03
    PATEND

Pat198:
    HOLD 2
    NOTE 2, F2, $03
    NOTE 2, A3, $1D
    NOTE 2, F2, $03
    NOTE 2, F2, $03
    NOTE 2, F2, $03
    NOTE 2, A3, $1D
    NOTE 2, F2, $03
    PATEND

Pat199:
    NOTE 2, G2, $03
    NOTE 2, G2, $03
    NOTE 2, A3, $1D
    NOTE 2, G2, $03
    NOTE 2, G2, $03
    NOTE 2, G2, $03
    NOTE 2, A3, $1D
    NOTE 2, As2, $03
    PATEND

Pat200:
    HOLD 2
    NOTE 2, F2, $03
    NOTE 2, A3, $1D
    NOTE 4, As2, $03
    NOTE 2, F2, $03
    NOTE 2, A3, $1D
    NOTE 2, F2, $03
    PATEND

Pat201:
    HOLD 2
    NOTE 2, C3, $03
    NOTE 2, A3, $1D
    NOTE 4, As2, $03
    NOTE 2, C3, $03
    NOTE 2, A3, $1D
    NOTE 2, As2, $03
    PATEND

Pat202:
    NOTE 2, A2, $03
    NOTE 2, A2, $03
    NOTE 2, A3, $1D
    NOTE 2, E2, $03
    NOTE 2, G2, $03
    NOTE 2, G2, $03
    NOTE 2, A3, $1D
    NOTE 2, A2, $03
    PATEND

Pat203:
    HOLD 2
    NOTE 2, A2, $03
    NOTE 2, A3, $1D
    NOTE 2, E2, $03
    NOTE 2, G2, $03
    NOTE 2, G2, $03
    NOTE 2, A3, $1D
    NOTE 2, A2, $03
    PATEND

Pat204:
    HOLD 2
    NOTE 2, A2, $03
    NOTE 2, A3, $1D
    NOTE 2, E2, $03
    NOTE 2, G2, $03
    NOTE 2, G2, $03
    NOTE 2, A3, $1D
    NOTE 2, A2, $03
    PATEND

Pat205:
    HOLD 2
    NOTE 2, A2, $03
    NOTE 2, A3, $1D
    NOTE 4, As2, $03
    NOTE 2, B2, $03
    NOTE 4, A3, $1D
    PATEND

Pat206:
    HOLD 4
    NOTE 2, C5, $26
    NOTE 2, C5, $26
    NOTE 2, E5, $26
    NOTE 4, F5, $26
    NOTE 2, G5, $26
    PATEND

Pat207:
    HOLD 2
    NOTE 4, C5, $26
    NOTE 4, As4, $26
    NOTE 4, C5, $26
    NOTE 2, Ds5, $26
    PATEND

Pat208:
    HOLD 2
    NOTE 4, C5, $26
    NOTE 4, As4, $26
    NOTE 4, C5, $26
    NOTE 2, Ds5, $26
    PATEND

Pat209:
    HOLD 2
    NOTE 4, C5, $26
    NOTE 4, Ds5, $26
    NOTE 4, F5, $26
    NOTE 2, C5, $26
    PATEND

Pat210:
    HOLD 2
    NOTE 4, C5, $26
    NOTE 4, Ds5, $26
    NOTE 4, F5, $26
    NOTE 2, G5, $1B
    PATEND

Pat211:
    HOLD 10
    NOTE 2, As4, $1B
    NOTE 2, G4, $1B
    NOTE 2, As4, $1B
    PATEND

Pat212:
    HOLD 2
    NOTE 4, C5, $1B
    NOTE 4, As4, $1B
    NOTE 4, C5, $1B
    NOTE 2, As4, $1B
    PATEND

Pat213:
    HOLD 2
    NOTE 4, C5, $1B
    NOTE 4, Ds5, $1B
    NOTE 4, C5, $1B
    NOTE 2, As4, $1B
    PATEND

Pat214:
    NOTE 2, A4, $1B
    NOTE 2, A4, $1B
    NOTE 2, A5, $1B
    NOTE 2, E4, $1B
    NOTE 2, G4, $1B
    NOTE 2, G4, $1B
    NOTE 2, G5, $1B
    NOTE 2, A4, $1B
    PATEND

Pat215:
    HOLD 2
    NOTE 2, A4, $1B
    NOTE 2, A5, $1B
    NOTE 2, E4, $1B
    NOTE 2, G4, $1B
    NOTE 2, G4, $1B
    NOTE 2, G5, $1B
    NOTE 2, A5, $1B
    PATEND

Pat216:
    HOLD 2
    NOTE 4, A4, $1B
    NOTE 4, As4, $1B
    NOTE 6, B4, $1B
    PATEND

Pat217:
    NOTE 4, C5, $06
    NOTE 4, C5, $06
    NOTE 4, C5, $06
    NOTE 4, C5, $06
    PATEND

Pat218:
    NOTE 4, C5, $07
    NOTE 4, C5, $07
    NOTE 4, C5, $07
    NOTE 4, C5, $07
    PATEND

Pat219:
    NOTE 4, As4, $06
    NOTE 4, As4, $06
    NOTE 4, F5, $06
    NOTE 4, F5, $06
    PATEND

Pat220:
    HOLD 2
    NOTE 2, A2, $03
    NOTE 2, A3, $1D
    NOTE 4, As2, $03
    NOTE 2, B2, $03
    NOTE 4, A3, $1D
    SONGJUMP Song10_Ch1

Pat221:
    NOTE 4, As4, $06
    NOTE 4, As4, $06
    NOTE 4, F5, $06
    NOTE 4, F5, $06
    SONGJUMP Song10_Ch2

Pat222:
    HOLD 2
    NOTE 4, A4, $1B
    NOTE 4, As4, $1B
    NOTE 6, B4, $1B
    SONGJUMP Song10_Ch3

Sfx00:
    HOLD 1
    SFXEND

OrphanTab_71CC:
    TB 1, $01
    TB 1, $00
    TLOOP OrphanTab_71CC

Comb_71D3:
    TB 255, $00 ; freq table only
    TLOOP Comb_71D3

Comb_71D8:
    TB 255, $01 ; note only
    TLOOP Comb_71D8

Comb_71DD:
    TB 255, $02 ; note + freq table
    TLOOP Comb_71DD

Arp_71E2:
    TB 255, $00 ; +0
    TLOOP Arp_71E2

Freq_71E7:
    TW 255, 0
    TLOOP Freq_71E7

OrphanTab_71ED:
    TB 255, $00
    TLOOP OrphanTab_71ED

OrphanTab_71F2:
    TW 20, 0

OrphanTab_71F2_Loop:
    TW 2, 1
    TW 2, -1
    TW 2, -1
    TW 2, 1
    TLOOP OrphanTab_71F2_Loop

OrphanTab_7204:
    TW 3, 10
    TW 3, -10
    TW 3, -10
    TW 3, 10
    TLOOP OrphanTab_7204

Freq_744D_L0:
    TW 3, 5
    TW 3, -5
    TW 3, -5
    TW 3, 5
    TLOOP Freq_744D_L0

Freq_7222:
    TW 20, 0

Freq_7225:
    TW 3, 2
    TW 3, -2
    TW 3, -2
    TW 3, 2
    TLOOP Freq_7225

OrphanTab_7234:
    TW 3, 1
    TW 3, -1
    TW 3, -1
    TW 3, 1
    TLOOP OrphanTab_7234

Freq_7243:
    TW 1, 1
    TW 2, 0
    TW 1, -1
    TW 2, 0
    TW 1, -1
    TW 2, 0
    TW 1, 1
    TW 2, 0
    TLOOP Freq_7243

Freq_725E:
    TW 1, -12
    TW 6, 2

Freq_7264:
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

Freq_7264_L0:
    TW 2, 16
    TW 2, -16
    TW 2, -16
    TW 2, 16
    TLOOP Freq_7264_L0

OrphanTab_72DF:
    TB 2, $60
    TB 2, $40

OrphanTab_72DF_Loop:
    TB 255, $20
    TLOOP OrphanTab_72DF_Loop

OrphanTab_72E8:
    TB 255, $20
    TLOOP OrphanTab_72E8

Vol_72ED:
    TB 255, $40 ; 50%
    TLOOP Vol_72ED

Vol_72F2:
    TB 255, $60 ; 25%
    TLOOP Vol_72F2

Ins00:
    INS_TONE $80, $01, $01, Arp_71E2, Freq_71E7, Comb_71D8 ; $00

NoiseIns00:
    INS_NOISE $00, $01, $01, Arp_71E2, Arp_71E2 ; $00

Ins01:
    INS_WAVE BlankVol, BlankVol, Arp_71E2, Freq_71E7, Comb_71DD ; $01

Ins03:
    INS_TONE $80, $D3, $11, Arp_731A, Freq_7225, Comb_71DD ; $03

Arp_731A:
    TB 1, $00 ; +0
    TB 1, $0C ; +12
    TB 255, $00 ; +0
    TLOOP Arp_731A

Ins04:
    INS_TONE $60, $C3, $11, Arp_71E2, Freq_7225, Comb_71DD ; $04 (unused)

Ins05:
    INS_TONE $60, $C6, $11, Arp_71E2, Freq_7225, Comb_71DD ; $05

Ins02:
    INS_TONE $60, $55, $11, Arp_7398, Freq_71E7, Comb_71D8 ; $02

Ins06:
    INS_TONE $60, $55, $11, Arp_73A1, Freq_71E7, Comb_71D8 ; $06

Ins07:
    INS_TONE $60, $55, $11, Arp_73AA, Freq_71E7, Comb_71D8 ; $07

Ins08:
    INS_TONE $60, $55, $11, Arp_73B3, Freq_71E7, Comb_71D8 ; $08 (unused)

Ins09:
    INS_TONE $60, $55, $11, Arp_73BC, Freq_71E7, Comb_71D8 ; $09

Ins10:
    INS_TONE $60, $55, $11, Arp_73C5, Freq_71E7, Comb_71D8 ; $0A (unused)

Ins11:
    INS_TONE $60, $55, $11, Arp_73CE, Freq_71E7, Comb_71D8 ; $0B

Ins12:
    INS_TONE $60, $55, $11, Arp_73D7, Freq_71E7, Comb_71D8 ; $0C

Ins13:
    INS_TONE $60, $55, $11, Arp_73E0, Freq_71E7, Comb_71D8 ; $0D

Ins14:
    INS_TONE $60, $55, $11, Arp_73E9, Freq_71E7, Comb_71D8 ; $0E (unused)

Ins15:
    INS_TONE $60, $55, $11, Arp_73F4, Freq_71E7, Comb_71D8 ; $0F

Arp_7398:
    TB 2, $00 ; +0
    TB 2, $02 ; +2
    TB 2, $07 ; +7
    TLOOP Arp_7398

Arp_73A1:
    TB 2, $00 ; +0
    TB 2, $04 ; +4
    TB 2, $07 ; +7
    TLOOP Arp_73A1

Arp_73AA:
    TB 2, $00 ; +0
    TB 2, $03 ; +3
    TB 2, $07 ; +7
    TLOOP Arp_73AA

Arp_73B3:
    TB 2, $00 ; +0
    TB 2, $05 ; +5
    TB 2, $08 ; +8
    TLOOP Arp_73B3

Arp_73BC:
    TB 2, $00 ; +0
    TB 2, $05 ; +5
    TB 2, $09 ; +9
    TLOOP Arp_73BC

Arp_73C5:
    TB 2, $00 ; +0
    TB 2, $03 ; +3
    TB 2, $09 ; +9
    TLOOP Arp_73C5

Arp_73CE:
    TB 2, $00 ; +0
    TB 2, $04 ; +4
    TB 2, $09 ; +9
    TLOOP Arp_73CE

Arp_73D7:
    TB 1, $00 ; +0
    TB 1, $02 ; +2
    TB 1, $09 ; +9
    TLOOP Arp_73D7

Arp_73E0:
    TB 1, $00 ; +0
    TB 1, $07 ; +7
    TB 1, $0A ; +10
    TLOOP Arp_73E0

Arp_73E9:
    TB 2, $00 ; +0
    TB 2, $04 ; +4
    TB 2, $07 ; +7
    TB 2, $0B ; +11
    TLOOP Arp_73E9

Arp_73F4:
    TB 2, $00 ; +0
    TB 2, $03 ; +3
    TB 2, $08 ; +8
    TLOOP Arp_73F4

Ins32:
    INS_TONE $80, $75, $11, Arp_740F, Freq_7243, Comb_71DD ; $20

Ins33:
    INS_TONE $80, $53, $11, Arp_740F, Freq_7243, Comb_71DD ; $21

Arp_740F:
    TB 1, $00 ; +0
    TB 1, $0C ; +12
    TLOOP Arp_740F

Ins34:
    INS_TONE $40, $58, $83, Arp_71E2, Freq_7264, Comb_71DD ; $22 (unused)

Ins35:
    INS_TONE $40, $58, $83, Arp_71E2, Freq_725E, Comb_71DD ; $23 (unused)

Ins36:
    INS_TONE $80, $48, $44, Arp_71E2, Freq_7222, Comb_71DD ; $24

Ins37:
    INS_TONE $80, $48, $44, Arp_71E2, Freq_743A, Comb_71DD ; $25

Freq_743A:
    TW 1, -20
    TW 5, 4
    TLOOP Freq_7222

Ins44:
    INS_WAVE Vol_754C, Vol_72ED, Arp_71E2, Freq_744D, Comb_71DD ; $2C

Freq_744D:
    TW 1, -15
    TW 15, 1
    TLOOP Freq_744D_L0

Ins16:
    INS_WAVE Vol_7545, Vol_72F2, Arp_74D7, Freq_71E7, Comb_71D8 ; $10 (unused)

Ins17:
    INS_WAVE Vol_7545, Vol_72F2, Arp_74DE, Freq_71E7, Comb_71D8 ; $11 (unused)

Ins18:
    INS_WAVE Vol_7545, Vol_72F2, Arp_74E5, Freq_7474, Comb_71DD ; $12

Freq_7474:
    TW 50, 0
    TW 255, 1
    TLOOP Freq_7474

Ins19:
    INS_WAVE Vol_7545, Vol_72F2, Arp_74EE, Freq_7474, Comb_71DD ; $13

Ins20:
    INS_WAVE Vol_7545, Vol_72F2, Arp_74F7, Freq_71E7, Comb_71D8 ; $14

Ins21:
    INS_WAVE Vol_7545, Vol_72F2, Arp_74FE, Freq_71E7, Comb_71D8 ; $15 (unused)

Ins22:
    INS_WAVE Vol_7545, Vol_72F2, Arp_7505, Freq_71E7, Comb_71D8 ; $16

Ins23:
    INS_WAVE Vol_7545, Vol_72F2, Arp_750E, Freq_71E7, Comb_71D8 ; $17 (unused)

Ins24:
    INS_WAVE Vol_7545, Vol_72F2, Arp_7517, Freq_71E7, Comb_71D8 ; $18

Ins25:
    INS_WAVE Vol_7545, Vol_72F2, Arp_7526, Freq_71E7, Comb_71DD ; $19

Ins26:
    INS_WAVE Vol_7545, Vol_72F2, Arp_7535, Freq_71E7, Comb_71DD ; $1A (unused)

Ins27:
    INS_WAVE Vol_7545, Vol_72F2, Arp_753E, Freq_71E7, Comb_71DD ; $1B

Arp_74D7:
    TB 2, $00 ; +0
    TB 2, $01 ; +1

Noise_74DB:
    TLOOP Arp_74D7

Arp_74DE:
    TB 2, $00 ; +0
    TB 2, $02 ; +2
    TLOOP Arp_74DE

Arp_74E5:
    TB 2, $00 ; +0
    TB 2, $03 ; +3
    TB 2, $FB ; -5
    TLOOP Arp_74E5

Arp_74EE:
    TB 2, $00 ; +0
    TB 2, $04 ; +4
    TB 2, $FB ; -5
    TLOOP Arp_74EE

Arp_74F7:
    TB 2, $00 ; +0
    TB 2, $05 ; +5
    TLOOP Arp_74F7

Arp_74FE:
    TB 2, $00 ; +0
    TB 2, $06 ; +6
    TLOOP Arp_74FE

Arp_7505:
    TB 2, $00 ; +0
    TB 2, $07 ; +7
    TB 2, $FB ; -5
    TLOOP Arp_7505

Arp_750E:
    TB 2, $00 ; +0
    TB 2, $08 ; +8
    TB 2, $FB ; -5
    TLOOP Arp_750E

Arp_7517:
    TB 1, $0C ; +12
    TB 1, $09 ; +9
    TB 1, $03 ; +3
    TB 1, $00 ; +0
    TB 1, $03 ; +3
    TB 1, $09 ; +9
    TLOOP Arp_7517

Arp_7526:
    TB 1, $0C ; +12
    TB 1, $0A ; +10
    TB 1, $00 ; +0
    TB 1, $FD ; -3
    TB 1, $00 ; +0
    TB 1, $0A ; +10
    TLOOP Arp_7526

Arp_7535:
    TB 2, $00 ; +0
    TB 2, $0B ; +11
    TB 2, $FD ; -3
    TLOOP Arp_7535

Arp_753E:
    TB 2, $00 ; +0
    TB 2, $0C ; +12
    TLOOP Arp_753E

Vol_7545:
    TB 6, $20 ; 100%
    TB 255, $40 ; 50%
    TLOOP BlankVol

Vol_754C:
    TB 6, $20 ; 100%
    TB 255, $40 ; 50%
    TLOOP Vol_754C

Ins38:
    INS_WAVE Vol_754C, Vol_72F2, Arp_71E2, Freq_75F9, Comb_71DD ; $26

Ins39:
    INS_WAVE Vol_754C, Vol_72F2, Arp_71E2, Freq_75F3, Comb_71DD ; $27

Ins42:
    INS_WAVE Vol_757B, Vol_72F2, Arp_71E2, Freq_75F9, Comb_71DD ; $2A

Ins43:
    INS_WAVE Vol_757B, Vol_72F2, Arp_71E2, Freq_75F3, Comb_71DD ; $2B

Vol_757B:
    TB 2, $20 ; 100%

Vol_757B_L0:
    TB 255, $40 ; 50%
    TLOOP Vol_757B_L0

Ins30:
    INS_TONE $80, $C1, $21, Arp_75A0, Freq_758B, Comb_71D3 ; $1E, $1C

Freq_758B:
    TW 1, 1200
    TW 1, 100
    TW 255, -80
    TLOOP Freq_758B

Ins29:
    INS_TONE $80, $D1, $21, Arp_75A0, Freq_75A7, Comb_71D3 ; $1D

Arp_75A0:
    TB 1, $00 ; +0
    TB 1, $02 ; +2
    TLOOP Arp_75A0

Freq_75A7:
    TW 1, 1700
    TW 2, -60

Freq_75A7_L0:
    TW 1, 100
    TW 255, -60
    TLOOP Freq_75A7_L0

Ins31:
    INS_TONE $80, $31, $11, Arp_75CE, Freq_75BF, Comb_71D3 ; $1F

Freq_75BF:
    TW 1, 4060
    TW 1, -1
    TW 1, -4060

Freq_75BF_L0:
    TW 255, 0
    TLOOP Freq_75BF_L0

Arp_75CE:
    TB 1, $00 ; +0
    TB 1, $FF ; -1
    TB 1, $FE ; -2
    TB 1, $FD ; -3
    TLOOP Arp_75CE

Ins40:
    INS_WAVE Vol_72ED, Vol_72F2, Arp_71E2, Freq_7243, Comb_71DD ; $28

Ins41:
    INS_WAVE Vol_72F2, Vol_72F2, Arp_71E2, Freq_7243, Comb_71DD ; $29

    ; $75ED-$75F2: 6 unreferenced bytes
    db $32, $00, $00, $00, $F9, $75

Freq_75F3:
    TW 1, -8
    TW 4, 2

Freq_75F9:
    TW 20, 0
    TLOOP Freq_7225

    ; $75FF-$7604: 6 unreferenced bytes
    db $14, $00, $00, $00, $13, $72

OrphanIns_7605:
    INS_TONE $80, $01, $00, Arp_71E2, Freq_71E7, Comb_71DD ; not in the instrument table

NoiseIns02:
    INS_NOISE $00, $51, $91, Noise_7615, Arp_71E2 ; $02

Noise_7615:
    TB 255, $44
    TLOOP Noise_7615

NoiseIns04:
    INS_NOISE $00, $37, $01, Noise_7628, Arp_71E2 ; $04

NoiseIns03:
    INS_NOISE $20, $31, $01, Noise_7628, Noise_7628 ; $03

Noise_7628:
    TB 255, $13
    TLOOP Noise_7628

NoiseIns01:
    INS_NOISE $80, $44, $01, Noise_7634, Arp_71E2 ; $01

Noise_7634:
    TB 255, $32
    TLOOP Noise_7634

NoiseIns05:
    INS_NOISE $80, $51, $01, Noise_7640, Arp_71E2 ; $05

Noise_7640:
    TB 2, $45
    TB 255, $32
    TLOOP Noise_7640

Wave_7647:
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

Morph_7657:
    MORPH 255, $30, $00
    TLOOP Morph_7657

Wave_765D:
    db $90, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

    ; $766D-$767F: 19 unreferenced bytes
    db $AE, $FF, $EE, $FF, $ED, $DD, $DD, $B7, $31, $01, $34, $32, $33, $31, $00, $05
    db $88, $88, $9B

OrphanIns_7680:
    INS_NOISE $CE, $FF, $FF, Noise_74DB, $6746 ; not in the instrument table

    ; $7687-$768C: 6 unreferenced bytes
    db $76, $54, $21, $11, $24, $67

OrphanMorph_768D:
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
    TLOOP OrphanMorph_768D

OrphanMorph_76F0:
    MORPH 220, $30, $AE
    TLOOP OrphanMorph_76F0

Morph_76F6:
    MORPH 7, $30, $90
    MORPH 7, $30, $99
    MORPH 7, $31, $90
    MORPH 7, $31, $99
    MORPH 7, $32, $90
    MORPH 7, $32, $99
    MORPH 7, $33, $90
    MORPH 7, $33, $99
    MORPH 7, $34, $90
    MORPH 7, $34, $99
    MORPH 7, $35, $90
    MORPH 7, $35, $99
    MORPH 7, $36, $90
    MORPH 7, $36, $99
    MORPH 7, $37, $90
    MORPH 7, $37, $99
    MORPH 7, $38, $90
    MORPH 7, $38, $99
    MORPH 7, $39, $90
    MORPH 7, $39, $99
    MORPH 7, $3A, $90
    MORPH 7, $3A, $99
    MORPH 7, $3B, $90
    MORPH 7, $3B, $99
    MORPH 7, $3C, $90
    MORPH 7, $3C, $99
    MORPH 7, $3D, $90
    MORPH 7, $3D, $99
    MORPH 7, $3E, $90
    MORPH 7, $3E, $99
    MORPH 7, $3F, $90
    MORPH 7, $3F, $00
    MORPH 7, $3E, $90
    MORPH 7, $3E, $00
    MORPH 7, $3D, $90
    MORPH 7, $3D, $00
    MORPH 7, $3C, $90
    MORPH 7, $3C, $00
    MORPH 7, $3B, $90
    MORPH 7, $3B, $00
    MORPH 7, $3A, $90
    MORPH 7, $3A, $00
    MORPH 7, $39, $90
    MORPH 7, $39, $00
    MORPH 7, $38, $90
    MORPH 7, $38, $00
    MORPH 7, $37, $90
    MORPH 7, $37, $00
    MORPH 7, $36, $90
    MORPH 7, $36, $00
    MORPH 7, $35, $90
    MORPH 7, $35, $00
    MORPH 7, $34, $90
    MORPH 7, $34, $00
    MORPH 7, $33, $90
    MORPH 7, $33, $00
    MORPH 7, $32, $90
    MORPH 7, $32, $00
    MORPH 7, $31, $90
    MORPH 7, $31, $00
    TLOOP Morph_76F6

Wave_77AD:
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF

Morph_77BD:
    MORPH 255, $30, $00
    TLOOP Morph_77BD

Wave_77C3:
    db $78, $88, $76, $53, $21, $00, $01, $24, $68, $AC, $DF, $FF, $FE, $DC, $B9, $88

Morph_77D3:
    MORPH 96, $3F, $88
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
    MORPH 81, $3F, $88
    TLOOP Morph_77D3

TheEnd:
    db "-- THE END --" ; end-of-data marker left by the converter
