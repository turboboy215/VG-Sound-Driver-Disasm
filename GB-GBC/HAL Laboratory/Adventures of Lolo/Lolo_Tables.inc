; bank 0: song, SFX and pattern tables ($3C17-$3FFF)

SongTable:
	dw Song00  ; song 0
	dw Song01  ; song 1
	dw Song02  ; song 2
	dw Song03  ; song 3
	dw Song04  ; song 4
	dw Song05  ; song 5
	dw Song06  ; song 6
	dw Song07  ; song 7
	dw Song08  ; song 8
	dw Song09  ; song 9
	dw Song10  ; song 10
	dw Song11  ; song 11
	dw Song12  ; song 12
	dw Song13  ; song 13
	dw Song14  ; song 14
	dw Song15  ; song 15
	dw Song16  ; song 16
	dw Song17  ; song 17
	dw Song18  ; song 18
	dw Song19  ; song 19
	dw Song20  ; song 20
	dw Song21  ; song 21
	dw Song22  ; song 22
	dw Song23  ; song 23
	dw Song24  ; song 24
	dw Song25  ; song 25
	dw Song26  ; song 26
	dw Song27  ; song 27
	dw Song28  ; song 28
	dw Song29  ; song 29
	dw Song30  ; song 30
	dw Song31  ; song 31
	dw Song32  ; song 32
	dw Song33  ; song 33
	dw Song34  ; song 34
	dw Song35  ; song 35
	dw Song36  ; song 36
	dw Song37  ; song 37
	dw Song38  ; song 38
	dw Song39  ; song 39
	dw Song40  ; song 40
	dw Song41  ; song 41
	dw Song42  ; song 42
	dw Song43  ; song 43
	dw Song44  ; song 44
	dw Song45  ; song 45
	dw Song46  ; song 46
	dw Song47  ; song 47
	dw Song48  ; song 48
	dw Song49  ; song 49
	dw Song50  ; song 50
	dw Song51  ; song 51
	dw Song52  ; song 52
	dw Song53  ; song 53
	dw Song54  ; song 54
	dw Song55  ; song 55
SfxTable:
	dw Sfx00  ; sfx 0
	dw Sfx01  ; sfx 1
	dw Sfx02  ; sfx 2
	dw Sfx03  ; sfx 3
	dw Sfx04  ; sfx 4
	dw Sfx05  ; sfx 5
	dw Sfx06  ; sfx 6
	dw Sfx07  ; sfx 7
	dw Sfx08  ; sfx 8
	dw Sfx09  ; sfx 9
	dw Sfx10  ; sfx 10
	dw Sfx11  ; sfx 11
	dw Sfx12  ; sfx 12
	dw Sfx13  ; sfx 13
	dw Sfx14  ; sfx 14
	dw Sfx15  ; sfx 15
	dw Sfx16  ; sfx 16
	dw Sfx17  ; sfx 17
	dw Sfx18  ; sfx 18
	dw Sfx19  ; sfx 19
	dw Sfx20  ; sfx 20
	dw Sfx21  ; sfx 21
	dw Sfx22  ; sfx 22
	dw Sfx23  ; sfx 23
	dw Sfx24  ; sfx 24
	dw Sfx25  ; sfx 25
	dw Sfx26  ; sfx 26
SfxChannelMasks:
	db %00010  ; sfx 0
	db %00010  ; sfx 1
	db %00010  ; sfx 2
	db %00011  ; sfx 3
	db %00010  ; sfx 4
	db %01010  ; sfx 5
	db %00011  ; sfx 6
	db %01000  ; sfx 7
	db %01010  ; sfx 8
	db %00010  ; sfx 9
	db %00011  ; sfx 10
	db %00011  ; sfx 11
	db %00010  ; sfx 12
	db %00010  ; sfx 13
	db %00011  ; sfx 14
	db %00010  ; sfx 15
	db %00011  ; sfx 16
	db %00011  ; sfx 17
	db %00010  ; sfx 18
	db %01010  ; sfx 19
	db %01000  ; sfx 20
	db %00010  ; sfx 21
	db %00010  ; sfx 22
	db %00010  ; sfx 23
	db %00011  ; sfx 24
	db %00010  ; sfx 25
	db %00010  ; sfx 26
SfxPriorities:
	db 40  ; sfx 0
	db 50  ; sfx 1
	db 40  ; sfx 2
	db 30  ; sfx 3
	db 30  ; sfx 4
	db 30  ; sfx 5
	db 20  ; sfx 6
	db 50  ; sfx 7
	db 40  ; sfx 8
	db 20  ; sfx 9
	db 0  ; sfx 10
	db 0  ; sfx 11
	db 50  ; sfx 12
	db 50  ; sfx 13
	db 20  ; sfx 14
	db 0  ; sfx 15
	db 0  ; sfx 16
	db 0  ; sfx 17
	db 50  ; sfx 18
	db 50  ; sfx 19
	db 50  ; sfx 20
	db 50  ; sfx 21
	db 30  ; sfx 22
	db 30  ; sfx 23
	db 0  ; sfx 24
	db 0  ; sfx 25
	db 0  ; sfx 26
SongPatternGroups:
	db NO_PATTERNS  ; song 0
	db NO_PATTERNS  ; song 1
	db NO_PATTERNS  ; song 2
	db NO_PATTERNS  ; song 3
	db NO_PATTERNS  ; song 4
	db NO_PATTERNS  ; song 5
	db NO_PATTERNS  ; song 6
	db NO_PATTERNS  ; song 7
	db NO_PATTERNS  ; song 8
	db NO_PATTERNS  ; song 9
	db NO_PATTERNS  ; song 10
	db NO_PATTERNS  ; song 11
	db NO_PATTERNS  ; song 12
	db NO_PATTERNS  ; song 13
	db NO_PATTERNS  ; song 14
	db NO_PATTERNS  ; song 15
	db NO_PATTERNS  ; song 16
	db NO_PATTERNS  ; song 17
	db NO_PATTERNS  ; song 18
	db NO_PATTERNS  ; song 19
	db NO_PATTERNS  ; song 20
	db NO_PATTERNS  ; song 21
	db NO_PATTERNS  ; song 22
	db 0  ; song 23
	db 0  ; song 24
	db 0  ; song 25
	db 0  ; song 26
	db 0  ; song 27
	db 1  ; song 28
	db 1  ; song 29
	db 1  ; song 30
	db 1  ; song 31
	db 1  ; song 32
	db NO_PATTERNS  ; song 33
	db NO_PATTERNS  ; song 34
	db NO_PATTERNS  ; song 35
	db NO_PATTERNS  ; song 36
	db NO_PATTERNS  ; song 37
	db NO_PATTERNS  ; song 38
	db NO_PATTERNS  ; song 39
	db NO_PATTERNS  ; song 40
	db NO_PATTERNS  ; song 41
	db NO_PATTERNS  ; song 42
	db NO_PATTERNS  ; song 43
	db NO_PATTERNS  ; song 44
	db NO_PATTERNS  ; song 45
	db NO_PATTERNS  ; song 46
	db NO_PATTERNS  ; song 47
	db NO_PATTERNS  ; song 48
	db NO_PATTERNS  ; song 49
	db NO_PATTERNS  ; song 50
	db NO_PATTERNS  ; song 51
	db NO_PATTERNS  ; song 52
	db NO_PATTERNS  ; song 53
	db NO_PATTERNS  ; song 54
	db NO_PATTERNS  ; song 55
SongPatternPeriods:
	db $FF  ; song 0
	db $FF  ; song 1
	db $FF  ; song 2
	db $FF  ; song 3
	db $FF  ; song 4
	db $FF  ; song 5
	db $FF  ; song 6
	db $FF  ; song 7
	db $FF  ; song 8
	db $FF  ; song 9
	db $FF  ; song 10
	db $FF  ; song 11
	db $FF  ; song 12
	db $FF  ; song 13
	db $FF  ; song 14
	db $FF  ; song 15
	db $FF  ; song 16
	db $FF  ; song 17
	db $FF  ; song 18
	db $FF  ; song 19
	db $FF  ; song 20
	db $FF  ; song 21
	db $FF  ; song 22
	db $30  ; song 23
	db $30  ; song 24
	db $30  ; song 25
	db $30  ; song 26
	db $30  ; song 27
	db $38  ; song 28
	db $38  ; song 29
	db $38  ; song 30
	db $38  ; song 31
	db $38  ; song 32
	db $FF  ; song 33
	db $FF  ; song 34
	db $FF  ; song 35
	db $FF  ; song 36
	db $FF  ; song 37
	db $FF  ; song 38
	db $FF  ; song 39
	db $FF  ; song 40
	db $FF  ; song 41
	db $FF  ; song 42
	db $FF  ; song 43
	db $FF  ; song 44
	db $FF  ; song 45
	db $FF  ; song 46
	db $FF  ; song 47
	db $FF  ; song 48
	db $FF  ; song 49
	db $FF  ; song 50
	db $FF  ; song 51
	db $FF  ; song 52
	db $FF  ; song 53
	db $FF  ; song 54
	db $FF  ; song 55
PatternTables:
	dw Pattern_G0V0  ; group 0, variant 0
	dw Pattern_G0V1  ; group 0, variant 1
	dw Pattern_G0V2  ; group 0, variant 2
	dw Pattern_G0V3  ; group 0, variant 3
	dw Pattern_G0V4  ; group 0, variant 4
	dw Pattern_G1V0  ; group 1, variant 0
	dw Pattern_G1V1  ; group 1, variant 1
	dw Pattern_G1V2  ; group 1, variant 2
	dw Pattern_G1V3  ; group 1, variant 3
	dw Pattern_G1V4  ; group 1, variant 4
Pattern_G0V0:
	dw Song23_CH1, Song23_CH2, Song23_CH3, Song23_CH4  ; row 0
	dw Pat_G0V0R1_CH1, Pat_G0V0R1_CH2, Song23_CH3, Pat_G0V0R1_CH4  ; row 1
	dw Pat_G0V0R2_CH1, Pat_G0V0R2_CH2, Song23_CH3, Song23_CH4  ; row 2
	dw Pat_G0V0R3_CH1, Pat_G0V0R3_CH2, Song23_CH3, Pat_G0V0R1_CH4  ; row 3
	dw Song23_CH1, Song23_CH2, Pat_G0V0R4_CH3, Song23_CH4  ; row 4
	dw Pat_G0V0R1_CH1, Pat_G0V0R1_CH2, Pat_G0V0R5_CH3, Pat_G0V0R1_CH4  ; row 5
	dw Pat_G0V0R6_CH1, Pat_G0V0R6_CH2, Pat_G0V0R6_CH3, Song23_CH4  ; row 6
	dw Pat_G0V0R7_CH1, Pat_G0V0R7_CH2, Pat_G0V0R7_CH3, Pat_G0V0R1_CH4  ; row 7
Pattern_G0V1:
	dw Song24_CH1, Song24_CH2, Song24_CH3, Song23_CH4  ; row 0
	dw Pat_G0V1R1_CH1, Pat_G0V1R1_CH2, Song24_CH3, Pat_G0V0R1_CH4  ; row 1
	dw Pat_G0V1R2_CH1, Pat_G0V1R2_CH2, Song24_CH3, Song23_CH4  ; row 2
	dw Pat_G0V1R3_CH1, Pat_G0V1R3_CH2, Song24_CH3, Pat_G0V0R1_CH4  ; row 3
	dw Song24_CH1, Song24_CH2, Pat_G0V1R4_CH3, Song23_CH4  ; row 4
	dw Pat_G0V1R1_CH1, Pat_G0V1R1_CH2, Pat_G0V1R5_CH3, Pat_G0V0R1_CH4  ; row 5
	dw Pat_G0V1R6_CH1, Pat_G0V1R6_CH2, Pat_G0V1R6_CH3, Song23_CH4  ; row 6
	dw Pat_G0V1R7_CH1, Pat_G0V1R7_CH2, Pat_G0V1R7_CH3, Pat_G0V0R1_CH4  ; row 7
Pattern_G0V2:
	dw Song25_CH1, Song25_CH2, Song25_CH3, Song25_CH4  ; row 0
	dw Pat_G0V2R1_CH1, Pat_G0V2R1_CH2, Pat_G0V2R1_CH3, Pat_G0V2R1_CH4  ; row 1
	dw Song25_CH1, Song25_CH2, Song25_CH3, Song25_CH4  ; row 2
	dw Pat_G0V2R1_CH1, Pat_G0V2R1_CH2, Pat_G0V2R1_CH3, Pat_G0V2R1_CH4  ; row 3
	dw Pat_G0V2R4_CH1, Pat_G0V2R4_CH2, Pat_G0V2R4_CH3, Song25_CH4  ; row 4
	dw Pat_G0V2R5_CH1, Pat_G0V2R5_CH2, Pat_G0V2R5_CH3, Pat_G0V2R1_CH4  ; row 5
	dw Pat_G0V2R6_CH1, Pat_G0V2R6_CH2, Pat_G0V2R6_CH3, Song25_CH4  ; row 6
	dw Pat_G0V2R7_CH1, Pat_G0V2R7_CH2, Pat_G0V2R7_CH3, Pat_G0V2R1_CH4  ; row 7
Pattern_G0V3:
	dw Song26_CH1, Song26_CH2, Song25_CH3, Song25_CH4  ; row 0
	dw Pat_G0V3R1_CH1, Pat_G0V3R1_CH2, Pat_G0V2R1_CH3, Pat_G0V2R1_CH4  ; row 1
	dw Song26_CH1, Song26_CH2, Song25_CH3, Song25_CH4  ; row 2
	dw Pat_G0V3R1_CH1, Pat_G0V3R1_CH2, Pat_G0V2R1_CH3, Pat_G0V2R1_CH4  ; row 3
	dw Song26_CH1, Song26_CH2, Pat_G0V2R4_CH3, Song25_CH4  ; row 4
	dw Pat_G0V3R1_CH1, Pat_G0V3R1_CH2, Pat_G0V2R5_CH3, Pat_G0V2R1_CH4  ; row 5
	dw Pat_G0V3R6_CH1, Pat_G0V3R6_CH2, Pat_G0V2R6_CH3, Song25_CH4  ; row 6
	dw Pat_G0V3R7_CH1, Pat_G0V3R7_CH2, Pat_G0V2R7_CH3, Pat_G0V2R1_CH4  ; row 7
Pattern_G0V4:
	dw Song27_CH1, Song27_CH2, Song27_CH3, Song27_CH4  ; row 0
	dw Pat_G0V4R1_CH1, Pat_G0V4R1_CH2, Song27_CH3, Pat_G0V4R1_CH4  ; row 1
	dw Pat_G0V4R2_CH1, Pat_G0V4R2_CH2, Song27_CH3, Song27_CH4  ; row 2
	dw Pat_G0V4R3_CH1, Pat_G0V4R3_CH2, Song27_CH3, Pat_G0V4R1_CH4  ; row 3
	dw Pat_G0V4R4_CH1, Pat_G0V4R4_CH2, Pat_G0V4R4_CH3, Song27_CH4  ; row 4
	dw Pat_G0V4R5_CH1, Pat_G0V4R5_CH2, Pat_G0V4R5_CH3, Pat_G0V4R1_CH4  ; row 5
	dw Pat_G0V4R6_CH1, Pat_G0V4R6_CH2, Pat_G0V4R6_CH3, Song27_CH4  ; row 6
	dw Pat_G0V4R7_CH1, Pat_G0V4R7_CH2, Pat_G0V4R7_CH3, Pat_G0V4R1_CH4  ; row 7
Pattern_G1V0:
	dw Song28_CH1, Song28_CH2, Song28_CH3, Song28_CH4  ; row 0
	dw Pat_G1V0R1_CH1, Pat_G1V0R1_CH2, Pat_G1V0R1_CH3, Pat_G1V0R1_CH4  ; row 1
	dw Pat_G1V0R2_CH1, Pat_G1V0R2_CH2, Pat_G1V0R2_CH3, Song28_CH4  ; row 2
	dw Pat_G1V0R3_CH1, Pat_G1V0R3_CH2, Pat_G1V0R3_CH3, Pat_G1V0R1_CH4  ; row 3
	dw Pat_G1V0R4_CH1, Pat_G1V0R4_CH2, Pat_G1V0R4_CH3, Song28_CH4  ; row 4
	dw Pat_G1V0R5_CH1, Pat_G1V0R5_CH2, Pat_G1V0R5_CH3, Pat_G1V0R1_CH4  ; row 5
	dw Pat_G1V0R6_CH1, Pat_G1V0R6_CH2, Pat_G1V0R6_CH3, Song28_CH4  ; row 6
	dw Pat_G1V0R7_CH1, Pat_G1V0R7_CH2, Pat_G1V0R7_CH3, Pat_G1V0R1_CH4  ; row 7
Pattern_G1V1:
	dw Song29_CH1, Song29_CH2, Song29_CH3, Song29_CH4  ; row 0
	dw Pat_G1V1R1_CH1, Pat_G1V1R1_CH2, Pat_G1V1R1_CH3, Pat_G1V1R1_CH4  ; row 1
	dw Pat_G1V1R2_CH1, Pat_G1V1R2_CH2, Pat_G1V1R2_CH3, Song29_CH4  ; row 2
	dw Pat_G1V1R3_CH1, Pat_G1V1R3_CH2, Pat_G1V1R3_CH3, Pat_G1V1R1_CH4  ; row 3
	dw Pat_G1V1R4_CH1, Pat_G1V1R4_CH2, Pat_G1V1R4_CH3, Song29_CH4  ; row 4
	dw Pat_G1V1R5_CH1, Pat_G1V1R5_CH2, Pat_G1V1R5_CH3, Pat_G1V1R1_CH4  ; row 5
	dw Pat_G1V1R6_CH1, Pat_G1V1R6_CH2, Pat_G1V1R6_CH3, Song29_CH4  ; row 6
	dw Pat_G1V1R7_CH1, Pat_G1V1R7_CH2, Pat_G1V1R7_CH3, Pat_G1V1R1_CH4  ; row 7
Pattern_G1V2:
	dw Song31_CH1, Song31_CH2, Song31_CH3, Song28_CH4  ; row 0
	dw Pat_G1V2R1_CH1, Pat_G1V2R1_CH2, Pat_G1V2R1_CH3, Pat_G1V0R1_CH4  ; row 1
	dw Pat_G1V2R2_CH1, Pat_G1V2R2_CH2, Pat_G1V2R2_CH3, Song28_CH4  ; row 2
	dw Pat_G1V2R3_CH1, Pat_G1V2R3_CH2, Pat_G1V2R3_CH3, Pat_G1V0R1_CH4  ; row 3
	dw Pat_G1V2R4_CH1, Pat_G1V2R4_CH2, Pat_G1V2R4_CH3, Song28_CH4  ; row 4
	dw Pat_G1V2R5_CH1, Pat_G1V2R5_CH2, Pat_G1V2R5_CH3, Pat_G1V0R1_CH4  ; row 5
	dw Pat_G1V2R6_CH1, Pat_G1V2R6_CH2, Pat_G1V2R6_CH3, Song28_CH4  ; row 6
	dw Pat_G1V2R7_CH1, Pat_G1V2R7_CH2, Pat_G1V2R7_CH3, Pat_G1V0R1_CH4  ; row 7
Pattern_G1V3:
	dw Song30_CH1, Song30_CH2, Song30_CH3, Song28_CH4  ; row 0
	dw Pat_G1V3R1_CH1, Pat_G1V3R1_CH2, Pat_G1V3R1_CH3, Pat_G1V0R1_CH4  ; row 1
	dw Pat_G1V3R2_CH1, Pat_G1V3R2_CH2, Pat_G1V3R2_CH3, Song28_CH4  ; row 2
	dw Pat_G1V3R3_CH1, Pat_G1V3R3_CH2, Pat_G1V3R3_CH3, Pat_G1V0R1_CH4  ; row 3
	dw Pat_G1V3R4_CH1, Pat_G1V3R4_CH2, Pat_G1V3R4_CH3, Song28_CH4  ; row 4
	dw Pat_G1V3R5_CH1, Pat_G1V3R5_CH2, Pat_G1V3R5_CH3, Pat_G1V0R1_CH4  ; row 5
	dw Pat_G1V3R6_CH1, Pat_G1V3R6_CH2, Pat_G1V3R6_CH3, Song28_CH4  ; row 6
	dw Pat_G1V3R7_CH1, Pat_G1V3R7_CH2, Pat_G1V3R7_CH3, Pat_G1V0R1_CH4  ; row 7
Pattern_G1V4:
	dw Song32_CH1, Song32_CH2, Song32_CH3, Song32_CH4  ; row 0
	dw Pat_G1V4R1_CH1, Pat_G1V4R1_CH2, Pat_G1V4R1_CH3, Song32_CH4  ; row 1
	dw Pat_G1V4R2_CH1, Pat_G1V4R2_CH2, Pat_G1V4R2_CH3, Song32_CH4  ; row 2
	dw Pat_G1V4R3_CH1, Pat_G1V4R3_CH2, Pat_G1V4R3_CH3, Song32_CH4  ; row 3
	dw Pat_G1V4R4_CH1, Pat_G1V4R4_CH2, Pat_G1V4R4_CH3, Song32_CH4  ; row 4
	dw Pat_G1V4R5_CH1, Pat_G1V4R5_CH2, Pat_G1V4R5_CH3, Song32_CH4  ; row 5
	dw Pat_G1V4R6_CH1, Pat_G1V4R6_CH2, Pat_G1V4R6_CH3, Song32_CH4  ; row 6
	dw Pat_G1V4R7_CH1, Pat_G1V4R7_CH2, Pat_G1V4R7_CH3, Song32_CH4  ; row 7
	db $01, $41, $01, $05, $02, $00, $03, $09, $00  ; not referenced by the sound code
