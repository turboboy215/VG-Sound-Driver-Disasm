;Bionic Commando audio disassembly
;Disassembly by Will Trowbridge

include "HARDWARE.INC"

def AudioROM equ $4000
def AudioRAM equ $C302
def WaveRAM equ $FF30
def TrackRAMSize equ $2C

def MusC1RAM equ $C30D
def MusC2RAM equ $C339
def MusC3RAM equ $C365
def MusC4RAM equ $C391
def SFXC1RAM equ $C3BD
def SFXC2RAM equ $C3E9
def SFXC3RAM equ $C415
def SFXC4RAM equ $C441

def CurStage equ $DF5D

SECTION "ROM Bank $001", ROMX[$4000], BANK[$1]

	jp PlayAudio


	jp LoadSong


	jp InitSound


	;Game-specific function
	jp SetStageMus


	;Additional game-specific functions (unknown)
	jp $77E7


	jp $7834


	jp $77E6


	jp $77D3


	;These functions do nothing
	jp $7B56


	jp $7B56


	jp $7B56


SetStageMus:
	;If stage number is over $12, then reset to 0
	ld a, [CurStage]
	cp $12
	jr c, .SetStageMus2

	xor a

.SetStageMus2
	add LOW(StageMusIDs)
	ld l, a
	ld a, 0
	adc HIGH(StageMusIDs)
	ld h, a
	ld a, [hl]
	jp StageMacro


StageMusIDs:
	db $2E
	db $2F
	db $2D
	db $30
	db $2E
	db $2D
	db $2E
	db $31
	db $2E
	db $2D
	db $2F
	db $2D
	db $31
	db $30
	db $2D
	db $2D
	db $31
	db $2E

FreqTab:
	dw $002C
	dw $009D
	dw $0107
	dw $016B
	dw $01C9
	dw $0223
	dw $0277
	dw $02C7
	dw $0312
	dw $0358
	dw $039B
	dw $03DA
	dw $0416
	dw $044E
	dw $0483
	dw $04B5
	dw $04E5
	dw $0511
	dw $053B
	dw $0563
	dw $0589
	dw $05AC
	dw $05CE
	dw $05ED
	dw $060B
	dw $0627
	dw $0642
	dw $065B
	dw $0672
	dw $0689
	dw $069E
	dw $06B2
	dw $06C4
	dw $06D6
	dw $06E7
	dw $06F7
	dw $0706
	dw $0714
	dw $0721
	dw $072D
	dw $0739
	dw $0744
	dw $074F
	dw $0759
	dw $0762
	dw $076B
	dw $0773
	dw $077B
	dw $0783
	dw $078A
	dw $0790
	dw $0797
	dw $079D
	dw $07A2
	dw $07A7
	dw $07AC
	dw $07B1
	dw $07B6
	dw $07BA
	dw $07BE
	dw $07C1
	dw $07C5
	dw $07C8
	dw $07CB
	dw $07CE
	dw $07D1
	dw $07D4
	dw $07D6
	dw $07D9
	dw $07DB
	dw $07DD
	dw $07DF
	dw $07E1
	dw $07E2
	dw $07E4
	dw $07E6
	dw $07E7
	dw $07E9
	dw $07EA
	dw $07EB
	dw $07EC
	dw $07ED
	dw $07EE
	dw $07EF
	dw $07F0
	dw $07F1
	dw $07F2
	dw $07F3
	dw $07F4
	dw $01DF
	dw $01E3
	dw $0243
	dw $0247
	dw $0243
	dw $0257

EmptySeq:
	db $FF

Song01D:
	db $D7, $00, $70, $87, $11, $81
	db $E0
	db $12
	db $FF

Song02D:
	db $D7, $00, $80, $88, $31, $F4
	db $E0
	db $13
	db $FF

Song03D:
	db $D7, $00, $80, $88, $11, $B1
	db $E1
	db $B2
	db $FF

Song04C:
	db $D1, $00, $40, $0E
	db $E3
	db $51
	db $21
	db $E2
	db $B1
	db $81
	db $51
	db $21
	db $E1
	db $B1
	db $FF
Song04D:
	db $D8, $00, $80, $88, $11, $B1
	db $E1
	db $B1
	db $FF

Song05C:
	db $D1, $00, $40, $0E
	db $E3
	db $51
	db $21
	db $E2
	db $B1
	db $81
	db $51
	db $21
	db $E1
	db $B1
	db $FF
Song05D:
	db $D8, $00, $A0, $8A, $11, $B1
	db $E1
	db $B1
	db $FF

Song06C:	
	db $D1, $00, $40, $0E
	db $E4
	db $41
	db $01
	db $E3
	db $81
	db $41
	db $01
	db $E2
	db $81
	db $41
	db $01
	db $FF

Song07C:
	db $D1, $00, $40, $0E
	db $E4
	db $01
	db $E3
	db $81
	db $41
	db $01
	db $E2
	db $81
	db $41
	db $01
	db $E1
	db $81
	db $FF
	
Song08C:
	db $D1, $00, $40, $0E
	db $E3
	db $81
	db $41
	db $01
	db $E2
	db $81
	db $41
	db $01
	db $E1
	db $81
	db $41
	db $FF

Song09C:
	db $D1, $00, $40, $0E
	db $E3
	db $41
	db $01
	db $E2
	db $81
	db $41
	db $01
	db $E1
	db $81
	db $41
	db $01
	db $FF

	;Unused/unreferenced data - supposed to be song 0A?
	db $D7, $00, $90, $0A
	db $E5
	db $04
	db $14
	db $24
	db $34
	db $44
	db $54
	db $64
	db $74
	db $FF
	
	db $FF

Song0BA:
	db $D1, $11, $00, $00, $0E
	db $EA, $15
	db $E1
	db $15
	db $EE, $0C
	db $E2
	db $15
	db $EE
	db $08
	db $E1
	db $15
	db $EE, $05
	db $E2
	db $15
	db $EE, $03
	db $E1
	db $15
	db $EE, $02
	db $E2
	db $15
	db $FF

Song0CD:	
	db $D1, $11, $00, $0E
	db $E0, $01
	db $E8, $00
	db $E3
	db $B1
	db $E8, $11
	db $E0
	db $11
	db $E8, $00
	db $E2
	db $B1
	db $C1
	db $E8, $11
	db $E0
	db $01
	db $EE, $0A
	db $E8, $00
	db $E1
	db $01
	db $EE, $08
	db $E8, $11
	db $E0
	db $02
	db $EE, $06
	db $E8, $00
	db $E1
	db $02
	db $EE, $04
	db $E8, $11
	db $E0
	db $02
	db $FF

Song0DA:
	db $D1, $00, $00, $00, $0E
	db $EA, $1C
	db $E5
	db $87
	db $EE, $08
	db $E5
	db $87
	db $EE, $04
	db $E5
	db $87
	db $FF

Song0EA:
	db $D1, $11, $00, $00, $0E
	db $EA, $15
	db $E2
	db $85
	db $EE, $08
	db $E2
	db $85
	db $EE, $04
	db $E2
	db $85
	db $FF

Song0FA:
	db $D1, $01, $00, $00, $0E
	db $EA, $13
	db $E1
	db $03
	db $EE, $0A
	db $E8, $00
	db $EA, $1D
	db $E5
	db $18
	db $EE, $06
	db $E5
	db $18
	db $FF

Song10A:
	db $D1, $31, $00, $00, $0C
	db $EA, $1C
	db $E4
	db $19
	db $EE, $06
	db $E4
	db $49
	db $EE, $05
	db $E4
	db $29
	db $EE, $02
	db $E4
	db $19
	db $FF
Song10D:	
	db $D1, $11, $00, $09
	db $E7
	db $01
	db $11
	db $01
	db $11
	db $C1
	db $EE, $07
	db $01
	db $11
	db $01
	db $11
	db $D3, $00, $60, $86
	db $22
	db $A3
	db $E5
	db $49
	db $FF

Song11C:	
	db $D1, $31, $00, $00, $0F
	db $EA, $1C
	db $E5
	db $35
	db $C1
	db $E3
	db $35
	db $C1
	db $E3
	db $59
	db $EE, $09
	db $E3
	db $89
	db $EE, $05
	db $E3
	db $49
	db $EE, $03
	db $E3
	db $59
	db $FF
Song11D:
	db $D1, $11, $00, $0E
	db $E7
	db $11
	db $EE, $0C
	db $21
	db $EE, $0A
	db $11
	db $C3
	db $EE, $0E
	db $E7
	db $11
	db $EE, $0C
	db $21
	db $EE, $0A
	db $11
	db $C2
	db $EE, $0E
	db $11
	db $21
	db $11
	db $01
	db $11
	db $C1
	db $EE, $0C
	db $21
	db $11
	db $01
	db $11
	db $D3, $00, $A0, $8A
	db $22
	db $A3
	db $E5
	db $4A
	db $FF

Song12A:	
	db $D1, $31, $00, $00, $0F
	db $EA, $1C
	db $E3
	db $35
	db $E8, $00
	db $EA, $17
	db $EE, $08
	db $E5
	db $13
	db $EE, $0F
	db $E8, $31
	db $EA, $1C
	db $E3
	db $32
	db $C1
	db $E5
	db $55
	db $C1
	db $E3
	db $59
	db $EE, $0C
	db $E3
	db $89
	db $EE, $09
	db $E3
	db $49
	db $EE, $07
	db $E3
	db $49
	db $EE, $05
	db $E3
	db $49
	db $EE, $03
	db $E3
	db $59
	db $EE, $01
	db $E3
	db $59
	db $FF
Song12D:
	db $D1, $11, $00, $0E
	db $E7
	db $11
	db $EE, $0C
	db $21
	db $EE, $0A
	db $11
	db $C3
	db $EE, $0E
	db $E7
	db $11
	db $EE, $0C
	db $21
	db $EE, $0A
	db $11
	db $C2
	db $EE, $0E
	db $E7
	db $11
	db $EE, $0C
	db $21
	db $EE, $0A
	db $11
	db $C2
	db $EE, $0E
	db $11
	db $21
	db $11
	db $01
	db $11
	db $C1
	db $EE, $0C
	db $21
	db $11
	db $01
	db $11
	db $21
	db $D6, $00, $A0, $8A, $52, $A5
	db $E5
	db $4A
	db $FF

Song13D:	
	db $D1, $00, $00, $01
	db $E2
	db $14
	db $EE, $02
	db $13
	db $EE, $03
	db $23
	db $EE, $04
	db $23
	db $EE, $05
	db $33
	db $EE, $06
	db $33
	db $EE, $07
	db $43
	db $EE, $08
	db $43
	db $EE, $07
	db $53
	db $EE, $06
	db $53
	db $EE, $05
	db $63
	db $EE, $04
	db $63
	db $EE, $03
	db $73
	db $EE, $02
	db $73
	db $EE, $01
	db $73
	db $FF

Song14A:
	db $D2, $22, $00, $00, $0E
	db $F3, $00
	db $F7
	dw Song14A_1
	db $EE, $06
	db $F7
	dw Song14A_1
	db $EE, $04
	db $F7
	dw Song14A_1
	db $EE, $03
	db $F7
	dw Song14A_1
	db $F3, $03
	db $EE, $02
	db $F7
	dw Song14A_1
	db $FF
Song14A_1:
	db $E4
	db $81
	db $51
	db $E5
	db $11
	db $E4
	db $81
	db $E5
	db $51
	db $F9

Song15D:
	db $D1, $00, $00, $0E
	db $E3
	db $71
	db $E8, $11
	db $EE, $08
	db $E0
	db $01
	db $E8, $00
	db $EE, $04
	db $E3
	db $73
	db $EE, $02
	db $73
	db $FF

Song16A:
	db $D1, $10, $00, $00, $0E
	db $EA, $1C
	db $E7
	db $13
	db $EA, $13
	db $E0
	db $76
	db $EE, $08
	db $76
	db $EE, $04
	db $76
	db $EE, $02
	db $76
	db $FF

Song17D:
	db $D1, $00, $00, $0E
	db $E3
	db $71
	db $61
	db $C2
	db $51
	db $EE, $08
	db $61
	db $EE, $04
	db $51
	db $61
	db $EE, $02
	db $51
	db $FF

Song18A:	
	db $D1, $03, $00, $00, $0E
	db $EA, $1C
	db $E3
	db $83
	db $EA, $1E
	db $E2
	db $E8, $11
	db $14
	db $E8, $00
	db $54
	db $EE, $04
	db $E8, $11
	db $14
	db $E8, $00
	db $54
	db $EE, $02
	db $E8, $11
	db $14
	db $E8, $00
	db $54
	db $EE, $01
	db $E8, $11
	db $14
	db $E8, $00
	db $54
	db $FF

Song19A:
	db $D2, $03, $00, $00, $0E
	db $EA, $1E
	db $E3
	db $59
	db $59
	db $EA, $1C
	db $83
	db $83
	db $EE, $05
	db $83
	db $83
	db $EE, $03
	db $83
	db $83
	db $FF

Song1AA:
	db $D8, $22, $00, $00, $08
	db $EA, $1F
	db $E5
	db $92
	db $EA, $17
	db $E2
	db $B2
	db $FF

Song1BA:
	db $D2, $22, $00, $00, $0E
	db $EA, $16
	db $E3
	db $91
	db $EE, $04
	db $91
	db $EE, $02
	db $91
	db $FF

Song1CA:
	db $D1, $11, $00, $00, $0E
	db $C1
	db $F6, $04
	db $EA, $16
	db $E3
	db $B1
	db $B1
	db $EE, $04
	db $B1
	db $EE, $03
	db $B1
	db $EE, $02
	db $B1
	db $FF

Song1DA:
	db $D5, $33, $00, $00, $08
	db $EA, $17
	db $E1
	db $72
	db $EE, $0C
	db $72
	db $EE, $0E
	db $72
	db $EE, $0A
	db $72
	db $EE, $08
	db $72
	db $EE, $06
	db $72
	db $EE, $04
	db $72
	db $EE, $02
	db $72
	db $FF

Song1EA:
	db $D1, $22, $00, $00, $0A
	db $EA, $1B
	db $E2
	db $A4
	db $C1
	db $A4
	db $C1
	db $FF

Song1FD:
	db $D2, $11, $00, $09
	db $E2
	db $31
	db $EE, $06
	db $41
	db $31
	db $41
	db $31
	db $41
	db $EE, $04
	db $31
	db $41
	db $31
	db $41
	db $EE, $02
	db $31
	db $41
	db $FF

Song20D:
	db $D1, $11, $00, $09
	db $FB
	db $EE, $08
	db $E5
	db $A2
	db $EE, $05
	db $31
	db $EE, $02
	db $32
	db $FD, $01
	db $FF

Song21A:
	db $D1, $31, $00, $00, $09
	db $EA, $1C
	db $E4
	db $19
	db $FF
Song21D:
	db $D1, $11, $00, $0F
	db $E7
	db $12
	db $32
	db $01
	db $21
	db $C1
	db $E6
	db $EE, $0A
	db $23
	db $13
	db $EE, $07
	db $23
	db $33
	db $EE, $06
	db $43
	db $53
	db $EE, $03
	db $62
	db $52
	db $FF

Song23D:
	db $D1, $11, $00, $0A
	db $E0
	db $22
	db $D3, $11, $80, $88, $20, $80
	db $E0
	db $15
	db $FF

Song22A:
	db $D1, $22, $00, $00, $0E
	db $E3
	db $01
	db $21
	db $41
	db $61
	db $81
	db $A1
	db $E4
	db $01
	db $21
	db $41
	db $61
	db $81
	db $A1
	db $EE, $04
	db $02
	db $22
	db $42
	db $62
	db $82
	db $A2
	db $EE, $02
	db $02
	db $22
	db $42
	db $62
	db $82
	db $A2
	db $FF

Song24A:
	db $D2, $22, $00, $00, $0E
	db $E2
	db $91
	db $E3
	db $41
	db $21
	db $91
	db $71
	db $E4
	db $21
	db $EE, $05
	db $E2
	db $91
	db $E3
	db $41
	db $21
	db $91
	db $71
	db $E4
	db $21
	db $EE, $03
	db $E2
	db $91
	db $E3
	db $41
	db $21
	db $91
	db $71
	db $E4
	db $21
	db $FF

Song25A:
	db $D1, $22, $00, $00, $0A
	db $E1
	db $01
	db $11
	db $21
	db $31
	db $41
	db $51
	db $FF

Song26B:
	db $D2, $00, $B1, $00, $0A
Song26A_1:
	db $E2
	db $FB
	db $41
	db $51
	db $61
	db $71
	db $81
	db $91
	db $A1
	db $B5
	db $C1
	db $FD, $02
	db $41
	db $51
	db $61
	db $71
	db $81
	db $91
	db $A1
	db $B5
	db $FF
Song26A:
	db $D2, $00, $B1, $00, $04
	db $C5
	db $EF, $03
	db $F7
	dw Song26A_1
	
Song27B:
	db $D2, $00, $B1, $00, $08
Song27A_1:
	db $E2
	db $FB
	db $41
	db $51
	db $61
	db $71
	db $81
	db $91
	db $A1
	db $B5
	db $C1
	db $FD, $00
Song27A:
	db $D2, $00, $B1, $00, $03
	db $C5
	db $EF, $03
	db $F7
	dw Song27A_1
	
Song28A:
	db $D1, $31, $00, $00, $0F
	db $EA, $1C
	db $E5
	db $35
	db $C1
	db $E3
	db $35
	db $D2, $00, $B1, $00, $06
	db $EA, $1E
	db $E2
	db $61
	db $81
	db $A1
	db $E3
	db $01
	db $21
	db $41
	db $61
	db $81
	db $A1
	db $E4
	db $01
	db $21
	db $41
	db $61
	db $81
	db $A1
	db $EE, $03
	db $41
	db $61
	db $81
	db $A1
	db $EE, $02
	db $41
	db $61
	db $81
	db $A1
	db $EE, $01
	db $41
	db $61
	db $81
	db $A1
	db $FF
Song28D:
	db $D1, $11, $00, $0E
	db $E7
	db $11
	db $EE, $0C
	db $21
	db $EE, $0A
	db $11
	db $C3
	db $D5, $00, $A0, $8A, $41, $F1
	db $E5
	db $4A
	db $FF

Song29A:
	db $D1, $31, $00, $00, $0F
	db $EA, $1B
	db $E4
	db $25
	db $C1
	db $E4
	db $98
	db $EE, $0C
	db $58
	db $EE, $0A
	db $58
	db $EE, $08
	db $58
	db $EE, $06
	db $58
	db $EE, $04
	db $58
	db $FF

Song2AD:
	db $D1, $00, $00, $04
	db $E5
	db $32
	db $EE, $08
	db $32
	db $EE, $0C
	db $32
	db $EE, $0F
	db $4F
	db $EE, $0C
	db $45
	db $EE, $0A
	db $55
	db $EE, $08
	db $55
	db $EE, $06
	db $65
	db $EE, $03
	db $65
	db $EE, $02
	db $73
	db $FF

EnvSeqTab:
	dw EnvSeq00
	dw EnvSeq01
	dw EnvSeq02
	dw EnvSeq03
	dw EnvSeq04
	dw EnvSeq05
	dw EnvSeq06
	dw EnvSeq07
	dw EnvSeq08
	dw EnvSeq09
	dw EnvSeq0A
	dw EnvSeq0B
	dw EnvSeq0C
	dw EnvSeq0D
	dw EnvSeq0E
	dw EnvSeq0F
	dw EnvSeq10
EnvSeq00:
	db $8F
	db $FF
EnvSeq01:
	db $1F
	db $FF
EnvSeq02:
	db $2F
	db $FF
EnvSeq03:
	db $3F
	db $FF
EnvSeq04:
	db $4F
	db $FF
EnvSeq05:
	db $5F
	db $FF
EnvSeq06:
	db $6F
	db $FF
EnvSeq07:
	db $7F
	db $FF
EnvSeq08:
	db $8F
	db $FF
EnvSeq09:
	db $9F
	db $FF
EnvSeq0A:
	db $AF
	db $FF
EnvSeq0B:
	db $BF
	db $FF
EnvSeq0C:
	db $CF
	db $FF
EnvSeq0D:
	db $DF
	db $FF
EnvSeq0E:
	db $EF
	db $FF
EnvSeq0F:
	db $FE
	db $FF
EnvSeq10:
	db $84, $51, $21, $11
	db $FF

VibTab:
	dw Vibrato0
	dw Vibrato1
	dw Vibrato2
	dw Vibrato3
	dw Vibrato4
	dw Vibrato5
	dw Vibrato6
	dw Vibrato7
	dw Vibrato8
	dw Vibrato9
	dw VibratoA
	dw VibratoB
	dw VibratoC
	dw VibratoD
	dw VibratoE
	dw VibratoF
	
Vibrato0:
	db $0F
	db $FF
Vibrato1:
	db $14, $03, $F4, $03
	db $FF
Vibrato2:
	db $11, $22, $11, $02
	db $F1, $E2, $F1, $02
	db $FF
Vibrato3:
	db $21, $32, $21, $02
	db $E1, $D2, $E1, $02
	db $FF
Vibrato4:
	db $21, $42, $21, $02
	db $E1, $C2, $E1, $02
	db $FF
Vibrato5:
	db $31, $52, $31, $02
	db $D1, $B2, $D1, $02
	db $FF
Vibrato6:
	db $31, $62, $31, $02
	db $D1, $A2, $D1, $02
	db $FF
Vibrato7:
Vibrato8:
Vibrato9:
VibratoA:
VibratoB:
VibratoC:
VibratoD:
VibratoE:
VibratoF:
	db $03, $13, $23, $13
	db $FF

WaveTab:
	dw Waveform0
	dw Waveform1
	dw Waveform2
	dw Waveform3
	dw Waveform4
	dw Waveform5
	dw Waveform6
	dw Waveform7
	dw Waveform8
	dw Waveform9
	dw WaveformA
	dw WaveformB
	dw WaveformC
	dw WaveformD
	dw WaveformE
	dw WaveformF
Waveform0:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $ED, $CB, $A9, $87, $65, $43, $21, $00
Waveform1:
	db $02, $46, $8A, $CE, $FF, $FF, $FF, $FF, $EC, $A8, $64, $20, $00, $00, $00, $00
Waveform2:
	db $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
Waveform3:
	db $35, $22, $4A, $00, $0A, $34, $05, $00, $FA, $FF, $0F, $FA, $FC, $F0, $00, $F0
Waveform4:
	db $FE, $DC, $BA, $98, $76, $54, $32, $10, $76, $54, $32, $10, $44, $00, $22, $00
Waveform5:
	db $79, $8F, $FC, $CF, $FD, $B9, $75, $31, $76, $54, $32, $10, $44, $00, $22, $00
Waveform6:
	db $03, $69, $CF, $FC, $96, $30, $03, $56, $77, $65, $44, $33, $20, $00, $52, $00
Waveform7:
	db $01, $21, $45, $67, $01, $21, $45, $67, $FE, $DC, $BA, $98, $76, $54, $32, $10
Waveform8:
	db $01, $11, $12, $23, $34, $45, $56, $67, $78, $89, $9A, $AB, $BC, $CD, $DD, $D0
Waveform9:
WaveformA:
WaveformB:
WaveformC:
WaveformD:
WaveformE:
WaveformF:
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $ED, $CB, $A9, $87, $65, $43, $21, $00

Song2CB:
	db $D7, $11, $51, $40, $95, $13, $87
	db $C0
	db $C0
	db $EF, $01
	db $FB
	db $E1
	db $11
	db $C1
	db $11
	db $11
	db $FD, $07
	db $EF, $00
	db $FB
	db $D7, $00, $C1, $44, $9C, $23, $A7
	db $E2
	db $18
	db $80
	db $66
	db $82
	db $41
	db $31
	db $F6, $0E
	db $1D
	db $F6, $07
	db $34
	db $41
	db $61
	db $8A
	db $B4
	db $9C
	db $E3
	db $12
	db $E2
	db $B1
	db $91
	db $B1
	db $91
	db $6A
	db $94
	db $94
	db $84
	db $64
	db $84
	db $D7, $00, $C1, $43, $9C, $25, $A7
	db $98
	db $46
	db $92
	db $D7, $00, $C5, $43, $9C, $25, $00
	db $72
	db $D7, $22, $91, $00, $99, $14, $84
	db $F3, $01
	db $E1
	db $71
	db $71
	db $F3, $02
	db $A1
	db $A1
	db $F3, $01
	db $E2
	db $21
	db $21
	db $F3, $02
	db $71
	db $71
	db $F3, $01
	db $91
	db $91
	db $F3, $02
	db $A1
	db $A1
	db $F3, $01
	db $E3
	db $21
	db $21
	db $F3, $03
	db $D7, $00, $C1, $43, $9C, $25, $A7
	db $E2
	db $98
	db $46
	db $91
	db $B1
	db $D7, $00, $C1, $43, $9C, $25, $A7
	db $E3
	db $01
	db $21
	db $D7, $00, $C5, $43, $9C, $25, $00
	db $42
	db $D7, $22, $91, $00, $99, $14, $84
	db $F3, $01
	db $E2
	db $01
	db $01
	db $F3, $02
	db $21
	db $21
	db $D7, $00, $C1, $43, $9C, $25, $A7
	db $F3, $03
	db $E3
	db $01
	db $21
	db $44
	db $21
	db $01
	db $D7, $00, $C1, $43, $9C, $25, $A7
	db $21
	db $01
	db $E2
	db $A2
	db $58
	db $E3
	db $22
	db $E2
	db $A2
	db $88
	db $98
	db $D7, $00, $C5, $43, $9C, $25, $00
	db $B4
	db $D7, $22, $91, $00, $99, $14, $84
	db $E1
	db $71
	db $61
	db $71
	db $91
	db $B1
	db $A1
	db $B1
	db $E2
	db $01
	db $21
	db $11
	db $21
	db $41
	db $51
	db $41
	db $21
	db $11
	db $21
	db $41
	db $51
	db $71
	db $51
	db $41
	db $51
	db $71
	db $91
	db $B1
	db $E3
	db $01
	db $21
	db $38
	db $D7, $01, $C1, $43, $9C, $25, $A7
	db $E2
	db $70
	db $56
	db $72
	db $31
	db $21
	db $06
	db $D7, $22, $61, $43, $94, $54, $F5
	db $56
	db $72
	db $31
	db $21
	db $06
	db $D7, $01, $C1, $43, $9C, $24, $A7
	db $06
	db $22
	db $38
	db $A0
	db $86
	db $A2
	db $61
	db $51
	db $3E
	db $E1
	db $B8
	db $88
	db $E2
	db $64
	db $12
	db $62
	db $92
	db $B2
	db $E3
	db $12
	db $E2
	db $92
	db $B8
	db $94
	db $74
	db $64
	db $12
	db $62
	db $92
	db $B2
	db $E3
	db $12
	db $42
	db $38
	db $14
	db $E2
	db $B4
	db $E3
	db $14
	db $E2
	db $42
	db $92
	db $E3
	db $12
	db $32
	db $42
	db $12
	db $E2
	db $B4
	db $64
	db $E3
	db $32
	db $42
	db $62
	db $32
	db $D7, $01, $C1, $42, $AC, $25, $E7
	db $40
	db $60
	db $F6, $0E
	db $80
	db $F6, $07
	db $FD, $00
	db $FF
Song2CA:
	db $D7, $11, $61, $44, $A3, $23, $A7
	db $C2
	db $C0
	db $C0
	db $C0
	db $C0
	db $FB
	db $EF, $FF
	db $E2
	db $18
	db $80
	db $66
	db $82
	db $41
	db $31
	db $F6, $0E
	db $1D
	db $F6, $07
	db $34
	db $41
	db $61
	db $8A
	db $B4
	db $9C
	db $E3
	db $12
	db $E2
	db $B1
	db $91
	db $B1
	db $91
	db $6A
	db $94
	db $94
	db $84
	db $64
	db $82
	db $EF, $00
	db $D7, $00, $A1, $43, $9A, $23, $A7
	db $48
	db $06
	db $42
	db $22
	db $D7, $00, $51, $23, $95, $25, $F7
	db $72
	db $D7, $00, $C1, $43, $9C, $25, $A7
	db $28
	db $72
	db $B2
	db $D7, $00, $A1, $43, $9A, $23, $A7
	db $E2
	db $48
	db $06
	db $41
	db $71
	db $91
	db $B1
	db $D7, $22, $91, $00, $99, $14, $84
	db $F3, $02
	db $E1
	db $71
	db $71
	db $F3, $03
	db $D7, $00, $51, $13, $95, $25, $F7
	db $E3
	db $44
	db $D7, $22, $91, $00, $99, $14, $84
	db $F3, $01
	db $E2
	db $41
	db $41
	db $F3, $02
	db $71
	db $71
	db $F3, $01
	db $E3
	db $01
	db $01
	db $F3, $02
	db $21
	db $21
	db $F3, $03
	db $D7, $00, $A1, $43, $9A, $23, $A7
	db $E2
	db $A4
	db $58
	db $54
	db $08
	db $08
	db $24
	db $DE, $00, $51, $13, $95, $25, $F7
	db $BA
	db $D7, $22, $61, $43, $96, $43, $84
	db $E2
	db $21
	db $11
	db $21
	db $41
	db $51
	db $71
	db $91
	db $B1
	db $D7, $22, $91, $00, $99, $14, $A7
	db $E3
	db $08
	db $D7, $11, $61, $43, $A3, $23, $A7
	db $EF, $FF
	db $E2
	db $C2
	db $76
	db $EF, $00
	db $D7, $11, $A1, $44, $9A, $24, $A7
	db $E1
	db $A0
	db $98
	db $96
	db $92
	db $91
	db $91
	db $96
	db $58
	db $38
	db $E2
	db $38
	db $10
	db $D7, $11, $91, $42, $99, $24, $A7
	db $A8
	db $86
	db $A2
	db $61
	db $51
	db $3E
	db $14
	db $E1
	db $92
	db $E2
	db $12
	db $62
	db $82
	db $92
	db $62
	db $28
	db $04
	db $04
	db $14
	db $E1
	db $92
	db $E2
	db $12
	db $62
	db $82
	db $92
	db $E3
	db $12
	db $E2
	db $68
	db $44
	db $34
	db $44
	db $E1
	db $92
	db $E2
	db $12
	db $42
	db $62
	db $82
	db $42
	db $64
	db $34
	db $62
	db $82
	db $92
	db $62
	db $04
	db $42
	db $02
	db $E1
	db $72
	db $42
	db $02
	db $E0
	db $72
	db $E2
	db $24
	db $62
	db $22
	db $E1
	db $92
	db $62
	db $22
	db $E0
	db $92
	db $DE, $11, $A1, $44, $9A, $24, $E7
	db $E2
	db $40
	db $D7, $11, $61, $44, $A3, $23, $A7
	db $C2
	db $FD, $00
	db $FF
Song2CC:
	db $D7, $04, $00, $10
	db $C0
	db $C0
	db $FB
	db $E2
	db $11
	db $C1
	db $11
	db $11
	db $FD, $07
	db $FC
	db $FB
	db $E2
	db $11
	db $C1
	db $11
	db $11
	db $FD, $03
	db $FB
	db $E1
	db $B1
	db $C1
	db $B1
	db $B1
	db $FD, $03
	db $FB
	db $E1
	db $91
	db $C1
	db $91
	db $91
	db $FD, $03
	db $FB
	db $E1
	db $61
	db $C1
	db $61
	db $61
	db $FD, $03
	db $FB
	db $E2
	db $11
	db $C1
	db $11
	db $11
	db $FD, $03
	db $FB
	db $E2
	db $21
	db $C1
	db $21
	db $21
	db $FD, $03
	db $FB
	db $E2
	db $31
	db $C1
	db $31
	db $31
	db $FD, $03
	db $FB
	db $E2
	db $41
	db $C1
	db $41
	db $41
	db $FD, $03
	db $FB
	db $E1
	db $91
	db $91
	db $91
	db $C3
	db $91
	db $91
	db $91
	db $91
	db $92
	db $92
	db $92
	db $FD, $02
	db $E2
	db $01
	db $01
	db $01
	db $C3
	db $01
	db $01
	db $01
	db $01
	db $02
	db $02
	db $E1
	db $72
	db $A1
	db $A1
	db $A1
	db $C3
	db $A1
	db $A1
	db $A1
	db $A1
	db $A2
	db $A2
	db $E1
	db $52
	db $81
	db $81
	db $81
	db $81
	db $C4
	db $51
	db $51
	db $51
	db $51
	db $C4
	db $72
	db $72
	db $72
	db $72
	db $72
	db $72
	db $72
	db $72
	db $72
	db $72
	db $72
	db $72
	db $72
	db $72
	db $72
	db $72
	db $FB
	db $E2
	db $01
	db $C1
	db $01
	db $01
	db $FD, $0F
	db $FB
	db $E2
	db $31
	db $C1
	db $31
	db $31
	db $FD, $0F
	db $FB
	db $E1
	db $61
	db $C1
	db $61
	db $61
	db $FD, $03
	db $FB
	db $E1
	db $71
	db $C1
	db $71
	db $71
	db $FD, $03
	db $FB
	db $E1
	db $61
	db $C1
	db $61
	db $61
	db $FD, $03
	db $FB
	db $E1
	db $B1
	db $C1
	db $B1
	db $B1
	db $FD, $03
	db $FB
	db $E1
	db $91
	db $C1
	db $91
	db $91
	db $FD, $03
	db $FB
	db $E1
	db $B1
	db $C1
	db $B1
	db $B1
	db $FD, $03
	db $FB
	db $E2
	db $01
	db $C1
	db $01
	db $01
	db $FD, $03
	db $FB
	db $E2
	db $21
	db $C1
	db $21
	db $21
	db $FD, $03
	db $FB
	db $E2
	db $41
	db $C1
	db $E1
	db $B1
	db $ED, $03
	db $C1
	db $ED, $04
	db $FD, $07
	db $FE, $00
	db $FF
Song2CD:
	db $D1, $11, $F1, $40, $00
	db $53
	db $44
	db $47
	db $47
	db $47
	db $53
	db $44
	db $47
	db $47
	db $47
	db $47
	db $53
	db $44
	db $47
	db $47
	db $53
	db $44
	db $47
	db $47
	db $47
	db $53
	db $44
	db $47
	db $47
	db $47
	db $47
	db $53
	db $44
	db $47
	db $47
	db $4E
	db $4E
	db $44
	db $45
	db $45
	db $44
	db $45
	db $32
	db $C3
	db $FB
	db $1E
	db $17
	db $17
	db $3E
	db $17
	db $17
	db $1E
	db $17
	db $17
	db $3E
	db $17
	db $17
	db $1E
	db $17
	db $17
	db $3E
	db $17
	db $17
	db $14
	db $15
	db $15
	db $17
	db $17
	db $3E
	db $17
	db $17
	db $FD, $00
	db $FF

Song2DB:
	db $D7, $12, $A1, $44, $9C, $23, $A7
	db $FB
	db $F7
	dw Song2DB_1
	db $1C
	db $23
	db $E2
	db $B1
	db $B2
	db $B2
	db $E3
	db $18
	db $F7
	dw Song2DB_1
	db $94
	db $A1
	db $C2
	db $51
	db $54
	db $91
	db $C1
	db $71
	db $A1
	db $71
	db $C1
	db $41
	db $11
	db $91
	db $C3
	db $22
	db $12
	db $E2
	db $B3
	db $B1
	db $B2
	db $E3
	db $12
	db $24
	db $12
	db $E2
	db $B2
	db $B1
	db $C2
	db $E3
	db $11
	db $E2
	db $B8
	db $E3
	db $72
	db $52
	db $43
	db $41
	db $42
	db $52
	db $74
	db $52
	db $42
	db $41
	db $C2
	db $51
	db $44
	db $F6, $01
	db $E2
	db $AA
	db $B9
	db $E3
	db $09
	db $F6, $07
	db $14
	db $F6, $01
	db $2E
	db $25
	db $25
	db $24
	db $2A
	db $E2
	db $A9
	db $E3
	db $29
	db $F6, $07
	db $28
	db $F6, $01
	db $4E
	db $45
	db $45
	db $44
	db $4A
	db $09
	db $49
	db $F6, $07
	db $48
	db $52
	db $41
	db $51
	db $72
	db $51
	db $71
	db $92
	db $71
	db $91
	db $A2
	db $91
	db $A1
	db $E4
	db $01
	db $C1
	db $E3
	db $01
	db $01
	db $E4
	db $01
	db $C1
	db $E3
	db $01
	db $01
	db $E4
	db $08
	db $FD, $00
Song2DB_1:
	db $E3
	db $91
	db $C2
	db $41
	db $46
	db $E4
	db $11
	db $21
	db $41
	db $C1
	db $11
	db $C1
	db $E3
	db $B6
	db $21
	db $41
	db $51
	db $C1
	db $51
	db $41
	db $52
	db $22
	db $41
	db $C2
	db $11
	db $F9
Song2DA:
	db $D7, $00, $81, $43, $9A, $23, $A7
	db $FB
	db $F7
	dw Song2DA_1
	db $96
	db $F6, $01
	db $E3
	db $15
	db $45
	db $94
	db $E4
	db $1E
	db $15
	db $E3
	db $95
	db $44
	db $F6, $07
	db $E2
	db $B3
	db $71
	db $72
	db $72
	db $92
	db $F6, $01
	db $E3
	db $95
	db $95
	db $94
	db $F6, $07
	db $92
	db $92
	db $F7
	dw Song2DA_1
	db $E3
	db $44
	db $51
	db $C2
	db $21
	db $24
	db $41
	db $C1
	db $21
	db $51
	db $41
	db $C1
	db $11
	db $E2
	db $91
	db $E3
	db $41
	db $C3
	db $E2
	db $B2
	db $92
	db $73
	db $71
	db $72
	db $92
	db $B4
	db $92
	db $72
	db $71
	db $C2
	db $91
	db $F6, $01
	db $25
	db $75
	db $B4
	db $E3
	db $25
	db $75
	db $B4
	db $E4
	db $25
	db $E3
	db $B5
	db $74
	db $45
	db $15
	db $E2
	db $94
	db $F6, $07
	db $E3
	db $42
	db $22
	db $13
	db $11
	db $12
	db $22
	db $24
	db $22
	db $12
	db $E1
	db $91
	db $E2
	db $11
	db $41
	db $C1
	db $11
	db $41
	db $91
	db $C1
	db $F6, $01
	db $E3
	db $7A
	db $89
	db $99
	db $F6, $07
	db $E2
	db $74
	db $F6, $01
	db $9E
	db $95
	db $95
	db $94
	db $9A
	db $79
	db $99
	db $F6, $07
	db $98
	db $E3
	db $02
	db $F6, $01
	db $05
	db $05
	db $04
	db $0A
	db $E2
	db $99
	db $E3
	db $09
	db $F6, $07
	db $08
	db $04
	db $04
	db $04
	db $E2
	db $74
	db $E3
	db $41
	db $C1
	db $E2
	db $71
	db $71
	db $E3
	db $41
	db $C1
	db $E2
	db $71
	db $71
	db $E3
	db $41
	db $C1
	db $E1
	db $01
	db $01
	db $01
	db $C1
	db $01
	db $C1
	db $FD, $00
Song2DA_1:
	db $E3
	db $41
	db $C2
	db $11
	db $16
	db $E3
	db $91
	db $B1
	db $E4
	db $11
	db $E3
	db $C1
	db $91
	db $C1
	db $76
	db $E2
	db $B1
	db $E3
	db $11
	db $21
	db $C1
	db $21
	db $11
	db $22
	db $E2
	db $B2
	db $E3
	db $11
	db $E2
	db $C2
	db $91
	db $F9
Song2DC:
	db $D7, $05, $83, $64
	db $FC
	db $E1
	db $F7
	dw Song2DC_1
	db $91
	db $C1
	db $91
	db $91
	db $91
	db $C1
	db $71
	db $C1
	db $71
	db $C1
	db $71
	db $71
	db $71
	db $C1
	db $51
	db $C1
	db $91
	db $C1
	db $91
	db $91
	db $91
	db $C1
	db $71
	db $C1
	db $F7
	dw Song2DC_1
	db $A1
	db $C1
	db $A1
	db $A1
	db $A1
	db $C1
	db $A1
	db $C1
	db $91
	db $C1
	db $E0
	db $91
	db $91
	db $E1
	db $91
	db $C1
	db $E0
	db $91
	db $91
	db $E1
	db $91
	db $C7
	db $E0
	db $91
	db $C1
	db $E1
	db $91
	db $91
	db $91
	db $C1
	db $91
	db $C1
	db $E0
	db $91
	db $C1
	db $E1
	db $91
	db $C1
	db $E0
	db $91
	db $C1
	db $E1
	db $91
	db $C1
	db $E0
	db $91
	db $C1
	db $E1
	db $91
	db $91
	db $91
	db $C1
	db $91
	db $C1
	db $E0
	db $91
	db $C1
	db $E1
	db $91
	db $C1
	db $E0
	db $71
	db $C1
	db $E1
	db $71
	db $C1
	db $FB
	db $E0
	db $91
	db $C1
	db $E1
	db $91
	db $91
	db $91
	db $C1
	db $91
	db $C1
	db $E0
	db $91
	db $C1
	db $E1
	db $91
	db $C1
	db $E0
	db $91
	db $C1
	db $E1
	db $91
	db $C1
	db $FD, $01
	db $A1
	db $C1
	db $E0
	db $A1
	db $A1
	db $E1
	db $51
	db $C1
	db $51
	db $C1
	db $A1
	db $C1
	db $E0
	db $A1
	db $A1
	db $A1
	db $C1
	db $A1
	db $C1
	db $E2
	db $01
	db $C1
	db $E1
	db $01
	db $01
	db $71
	db $C1
	db $71
	db $C1
	db $E2
	db $01
	db $C1
	db $E1
	db $01
	db $01
	db $01
	db $C1
	db $01
	db $C1
	db $D7, $05, $83, $C4
	db $E2
	db $54
	db $34
	db $24
	db $14
	db $D7, $05, $83, $64
	db $01
	db $C1
	db $01
	db $01
	db $01
	db $C1
	db $01
	db $01
	db $01
	db $C1
	db $E1
	db $01
	db $01
	db $01
	db $C1
	db $01
	db $C1
	db $FE, $00
Song2DC_1:
	db $FB
	db $91
	db $C1
	db $91
	db $91
	db $91
	db $C1
	db $71
	db $C1
	db $FD, $01
	db $FB
	db $71
	db $C1
	db $71
	db $71
	db $71
	db $C1
	db $51
	db $C1
	db $FD, $01
	db $91
	db $C1
	db $91
	db $91
	db $91
	db $C1
	db $71
	db $C1
	db $F9
Song2DD:
	db $D7, $11, $F1, $40, $00
	db $FB
	db $FC
	db $12
	db $11
	db $11
	db $12
	db $12
	db $C2
	db $12
	db $F6, $01
	db $13
	db $13
	db $12
	db $12
	db $12
	db $12
	db $F6, $07
	db $11
	db $11
	db $FE, $05
	db $12
	db $11
	db $11
	db $12
	db $12
	db $11
	db $11
	db $12
	db $12
	db $11
	db $11
	db $11
	db $11
	db $12
	db $11
	db $11
	db $12
	db $12
	db $11
	db $11
	db $12
	db $12
	db $FC
	db $C2
	db $12
	db $C2
	db $12
	db $C2
	db $11
	db $11
	db $12
	db $12
	db $FE, $02
	db $12
	db $12
	db $F6, $01
	db $13
	db $13
	db $12
	db $12
	db $12
	db $12
	db $F6, $07
	db $11
	db $11
	db $12
	db $11
	db $11
	db $12
	db $11
	db $11
	db $12
	db $11
	db $11
	db $12
	db $11
	db $11
	db $11
	db $11
	db $12
	db $12
	db $12
	db $12
	db $11
	db $11
	db $12
	db $11
	db $11
	db $11
	db $11
	db $12
	db $12
	db $12
	db $12
	db $12
	db $F6, $01
	db $13
	db $13
	db $12
	db $12
	db $12
	db $12
	db $F6, $07
	db $11
	db $11
	db $12
	db $12
	db $F6, $01
	db $13
	db $13
	db $12
	db $12
	db $12
	db $12
	db $F6, $07
	db $11
	db $11
	db $12
	db $11
	db $11
	db $12
	db $11
	db $11
	db $12
	db $11
	db $11
	db $12
	db $12
	db $FD, $00

Song2EB:
	db $D6, $01, $B1, $26, $9B, $15, $C7
	db $EC, $01
	db $FB
	db $E1
	db $42
	db $42
	db $C2
	db $74
	db $72
	db $54
	db $FD, $02
	db $42
	db $42
	db $C8
	db $F6, $01
	db $45
	db $55
	db $65
	db $75
	db $84
	db $F6, $06
	db $FB
	db $FC
	db $E1
	db $96
	db $F6, $01
	db $E2
	db $02
	db $12
	db $21
	db $31
	db $F6, $06
	db $4D
	db $24
	db $72
	db $54
	db $40
	db $C2
	db $C0
	db $E1
	db $96
	db $F6, $01
	db $E2
	db $02
	db $12
	db $21
	db $31
	db $F6, $06
	db $4D
	db $24
	db $72
	db $54
	db $48
	db $F6, $01
	db $92
	db $A2
	db $B2
	db $F6, $06
	db $E3
	db $0B
	db $F6, $01
	db $22
	db $31
	db $49
	db $F6, $06
	db $22
	db $02
	db $E2
	db $B2
	db $92
	db $72
	db $9A
	db $E3
	db $04
	db $E2
	db $92
	db $E3
	db $2A
	db $F6, $01
	db $E2
	db $92
	db $A1
	db $B9
	db $F6, $06
	db $92
	db $72
	db $E3
	db $40
	db $C4
	db $F6, $01
	db $22
	db $31
	db $49
	db $F6, $06
	db $22
	db $02
	db $E2
	db $B2
	db $92
	db $72
	db $9A
	db $E3
	db $04
	db $E2
	db $92
	db $E3
	db $28
	db $F6, $02
	db $E2
	db $91
	db $A1
	db $BA
	db $F6, $06
	db $E3
	db $02
	db $22
	db $40
	db $C0
	db $C2
	db $FE, $01
	db $F6, $02
	db $E1
	db $71
	db $81
	db $91
	db $AF
	db $F6, $06
	db $E2
	db $56
	db $24
	db $46
	db $E3
	db $06
	db $E2
	db $94
	db $A6
	db $E3
	db $50
	db $C2
	db $42
	db $56
	db $43
	db $33
	db $23
	db $13
	db $02
	db $E2
	db $B2
	db $A3
	db $93
	db $82
	db $78
	db $FD, $00
Song2EA:
	db $D6, $10, $A1, $46, $9A, $14, $A7
	db $EC, $01
	db $FB
	db $E0
	db $B2
	db $B2
	db $C2
	db $E1
	db $24
	db $22
	db $04
	db $F6, $06
	db $FD, $02
	db $E0
	db $B2
	db $B2
	db $CC
	db $FB
	db $F7
	dw Song2EA_1
	db $F7
	dw Song2EA_1
	db $D6, $10, $91, $45, $98, $14, $A7
	db $E1
	db $52
	db $52
	db $52
	db $A4
	db $52
	db $E2
	db $54
	db $E1
	db $92
	db $92
	db $92
	db $E2
	db $44
	db $E1
	db $92
	db $E2
	db $94
	db $D6, $01, $81, $25, $98, $16, $B7
	db $FC
	db $E1
	db $A1
	db $51
	db $A1
	db $E2
	db $21
	db $FE, $04
	db $51
	db $21
	db $51
	db $A1
	db $E3
	db $21
	db $E2
	db $A1
	db $E3
	db $21
	db $51
	db $A1
	db $51
	db $A1
	db $E4
	db $21
	db $F3, $00
	db $D6, $10, $B1, $25, $9B, $15, $B7
	db $E2
	db $B3
	db $A3
	db $93
	db $83
	db $72
	db $62
	db $53
	db $43
	db $32
	db $28
	db $F3, $03
	db $FD, $00
Song2EA_1:
	db $D6, $10, $A1, $44, $9A, $14, $A7
	db $FC
	db $E1
	db $41
	db $41
	db $41
	db $41
	db $42
	db $94
	db $41
	db $41
	db $E2
	db $44
	db $FE, $06
	db $D6, $10, $A1, $25, $9A, $14, $B7
	db $C2
	db $F6, $01
	db $E2
	db $A2
	db $B1
	db $E3
	db $09
	db $F6, $06
	db $E2
	db $B2
	db $92
	db $72
	db $52
	db $42
	db $5A
	db $94
	db $52
	db $BA
	db $F6, $01
	db $52
	db $61
	db $79
	db $F6, $06
	db $52
	db $42
	db $E8, $03
	db $96
	db $42
	db $B4
	db $42
	db $E3
	db $04
	db $E2
	db $42
	db $E8, $10
	db $F6, $01
	db $A2
	db $B1
	db $E3
	db $09
	db $F6, $06
	db $E2
	db $B2
	db $92
	db $72
	db $52
	db $42
	db $5A
	db $94
	db $52
	db $B8
	db $F6, $02
	db $51
	db $61
	db $7A
	db $F6, $06
	db $92
	db $B2
	db $E3
	db $04
	db $D6, $10, $81, $44, $98, $13, $A7
	db $E1
	db $41
	db $41
	db $42
	db $41
	db $41
	db $42
	db $41
	db $41
	db $42
	db $44
	db $41
	db $41
	db $42
	db $41
	db $41
	db $42
	db $41
	db $41
	db $42
	db $41
	db $41
	db $F9
Song2EC:
	db $D6, $05, $83, $C4
	db $EC, $01
	db $FB
	db $E1
	db $42
	db $42
	db $C8
	db $54
	db $FD, $02
	db $E1
	db $42
	db $42
	db $C8
	db $44
	db $FB
	db $F7
	dw Song2EC_1
	db $F7
	dw Song2EC_1
	db $F2, $A1
	db $E1
	db $A2
	db $A1
	db $A1
	db $A2
	db $A1
	db $A1
	db $E1
	db $A2
	db $A1
	db $A1
	db $A2
	db $A1
	db $A1
	db $E1
	db $92
	db $91
	db $91
	db $92
	db $91
	db $91
	db $E1
	db $92
	db $91
	db $91
	db $92
	db $91
	db $91
	db $FC
	db $E1
	db $A2
	db $A1
	db $A1
	db $A2
	db $A1
	db $A1
	db $FE, $03
	db $F2, $C4
	db $E2
	db $43
	db $33
	db $23
	db $13
	db $02
	db $E1
	db $B2
	db $A3
	db $93
	db $82
	db $78
	db $FD, $00
Song2EC_1:
	db $F2, $A1
	db $FC
	db $E1
	db $91
	db $91
	db $91
	db $91
	db $92
	db $91
	db $91
	db $E1
	db $92
	db $91
	db $91
	db $92
	db $91
	db $91
	db $FE, $06
	db $F2, $C4
	db $E1
	db $92
	db $E2
	db $02
	db $E1
	db $B2
	db $92
	db $72
	db $52
	db $42
	db $E1
	db $54
	db $F2, $A1
	db $51
	db $51
	db $52
	db $51
	db $51
	db $E1
	db $52
	db $51
	db $51
	db $52
	db $F2, $C4
	db $E1
	db $74
	db $F2, $A1
	db $71
	db $71
	db $72
	db $71
	db $71
	db $E1
	db $72
	db $71
	db $71
	db $72
	db $F2, $C4
	db $E1
	db $94
	db $F2, $B4
	db $91
	db $91
	db $E2
	db $02
	db $E1
	db $91
	db $91
	db $E2
	db $22
	db $E1
	db $91
	db $91
	db $E2
	db $42
	db $E1
	db $41
	db $41
	db $F2, $C4
	db $E1
	db $92
	db $E2
	db $02
	db $E1
	db $B2
	db $92
	db $72
	db $52
	db $42
	db $E1
	db $54
	db $F2, $A1
	db $51
	db $51
	db $52
	db $51
	db $51
	db $E1
	db $52
	db $51
	db $51
	db $52
	db $F2, $C4
	db $E1
	db $74
	db $F2, $A1
	db $71
	db $71
	db $72
	db $71
	db $71
	db $E1
	db $72
	db $71
	db $71
	db $72
	db $F2, $C4
	db $E1
	db $94
	db $F2, $B4
	db $91
	db $91
	db $E2
	db $02
	db $E1
	db $91
	db $91
	db $E2
	db $22
	db $E1
	db $91
	db $91
	db $E2
	db $42
	db $E1
	db $94
	db $91
	db $91
	db $E2
	db $02
	db $E1
	db $91
	db $91
	db $E2
	db $22
	db $E1
	db $91
	db $91
	db $E2
	db $42
	db $E1
	db $41
	db $41
	db $F9
Song2ED:
	db $D6, $11, $F1, $40, $00
	db $FB
	db $22
	db $11
	db $11
	db $12
	db $11
	db $11
	db $12
	db $11
	db $11
	db $12
	db $11
	db $11
	db $FD, $02
	db $32
	db $32
	db $C8
	db $31
	db $31
	db $31
	db $31
	db $FB
	db $F7
	dw Song2ED_1
	db $F7
	dw Song2ED_1
	db $FC
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FE, $03
	db $32
	db $11
	db $32
	db $11
	db $32
	db $11
	db $32
	db $11
	db $32
	db $32
	db $32
	db $11
	db $32
	db $11
	db $32
	db $34
	db $31
	db $31
	db $31
	db $31
	db $FD, $00
Song2ED_1:
	db $FC
	db $11
	db $11
	db $11
	db $11
	db $32
	db $11
	db $11
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FE, $06
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $32
	db $11
	db $11
	db $32
	db $FC
	db $24
	db $11
	db $11
	db $32
	db $11
	db $11
	db $12
	db $11
	db $11
	db $32
	db $FE, $02
	db $11
	db $11
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $32
	db $11
	db $11
	db $32
	db $FC
	db $24
	db $11
	db $11
	db $32
	db $11
	db $11
	db $12
	db $11
	db $11
	db $32
	db $FE, $02
	db $11
	db $11
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $F9

Song2FB:
	db $F6, $07
	db $CA
	db $EC, $02
	db $FB
	db $D7, $10, $B1, $35, $9B, $15, $77
	db $F7
	dw Song2FB_1
	db $D7, $13, $A1, $35, $9A, $15, $A6
	db $C6
	db $E2
	db $03
	db $E1
	db $93
	db $E2
	db $02
	db $23
	db $E1
	db $73
	db $E2
	db $22
	db $73
	db $52
	db $42
	db $51
	db $43
	db $23
	db $02
	db $E1
	db $96
	db $E2
	db $02
	db $E1
	db $B3
	db $B1
	db $E2
	db $01
	db $22
	db $E1
	db $70
	db $C1
	db $E2
	db $03
	db $E1
	db $93
	db $E2
	db $02
	db $23
	db $43
	db $52
	db $73
	db $52
	db $42
	db $51
	db $44
	db $21
	db $03
	db $E1
	db $96
	db $E2
	db $02
	db $E1
	db $B3
	db $B1
	db $E2
	db $01
	db $22
	db $4B
	db $FD, $00
	db $FF
Song2FB_1:
	db $FC
	db $E1
	db $92
	db $E2
	db $01
	db $22
	db $F2, $C7
	db $4B
	db $F2, $76
	db $E1
	db $92
	db $E2
	db $01
	db $42
	db $F2, $C7
	db $2B
	db $F2, $76
	db $02
	db $E1
	db $B1
	db $92
	db $F2, $C7
	db $7B
	db $F2, $76
	db $93
	db $B2
	db $F2, $C7
	db $9B
	db $F2, $76
	db $42
	db $71
	db $E2
	db $02
	db $F2, $C7
	db $E1
	db $9B
	db $F2, $76
	db $92
	db $B1
	db $E2
	db $02
	db $F2, $C7
	db $2B
	db $54
	db $72
	db $93
	db $53
	db $E3
	db $02
	db $E2
	db $B3
	db $E3
	db $23
	db $E2
	db $72
	db $9A
	db $FE, $01
	db $F9
Song2FA:
	db $F6, $07
	db $CA
	db $EC, $02
	db $FB
	db $D7, $00, $61, $35, $96, $14, $77
	db $C2
	db $EF, $01
	db $F7
	dw Song2FB_1
	db $EF, $00
	db $D7, $10, $81, $35, $98, $14, $A6
	db $C4
	db $E1
	db $93
	db $53
	db $92
	db $B3
	db $23
	db $B2
	db $E2
	db $43
	db $22
	db $02
	db $21
	db $03
	db $E1
	db $B3
	db $92
	db $E1
	db $56
	db $92
	db $73
	db $71
	db $91
	db $B2
	db $49
	db $28
	db $E1
	db $93
	db $53
	db $92
	db $B3
	db $E2
	db $03
	db $22
	db $43
	db $22
	db $02
	db $21
	db $04
	db $E1
	db $B1
	db $93
	db $56
	db $92
	db $73
	db $71
	db $91
	db $B2
	db $BB
	db $FD, $00
Song2FC:
	db $F6, $07
	db $CA
	db $EC, $02
	db $FB
	db $FC
	db $D7, $06, $83, $84
	db $E1
	db $42
	db $41
	db $42
	db $F2, $C4
	db $E1
	db $93
	db $F2, $84
	db $92
	db $E2
	db $02
	db $E1
	db $91
	db $E2
	db $22
	db $E1
	db $91
	db $E2
	db $42
	db $F2, $C4
	db $31
	db $42
	db $E1
	db $73
	db $F2, $84
	db $72
	db $B2
	db $71
	db $E2
	db $22
	db $E1
	db $71
	db $E2
	db $42
	db $F2, $C4
	db $31
	db $22
	db $E1
	db $73
	db $F2, $84
	db $72
	db $B2
	db $71
	db $E2
	db $22
	db $E1
	db $71
	db $E2
	db $42
	db $F2, $C4
	db $31
	db $42
	db $E1
	db $93
	db $F2, $84
	db $92
	db $E2
	db $02
	db $E1
	db $91
	db $E2
	db $22
	db $E1
	db $91
	db $42
	db $41
	db $42
	db $F2, $C4
	db $E1
	db $93
	db $F2, $84
	db $92
	db $E2
	db $02
	db $E1
	db $91
	db $E2
	db $22
	db $E1
	db $91
	db $E2
	db $42
	db $F2, $C4
	db $31
	db $42
	db $E1
	db $73
	db $F2, $84
	db $72
	db $B2
	db $71
	db $E2
	db $22
	db $E1
	db $71
	db $E2
	db $42
	db $F2, $C4
	db $31
	db $23
	db $E1
	db $53
	db $E2
	db $03
	db $E1
	db $52
	db $73
	db $E2
	db $23
	db $E1
	db $72
	db $F2, $A4
	db $91
	db $E2
	db $01
	db $41
	db $F2, $C4
	db $22
	db $72
	db $E1
	db $71
	db $F2, $84
	db $92
	db $FE, $01
	db $F2, $B4
	db $C6
	db $E1
	db $52
	db $51
	db $E2
	db $02
	db $01
	db $E1
	db $52
	db $E1
	db $72
	db $71
	db $E2
	db $22
	db $21
	db $E1
	db $72
	db $E2
	db $02
	db $01
	db $72
	db $71
	db $02
	db $E1
	db $92
	db $91
	db $E2
	db $42
	db $41
	db $E1
	db $92
	db $E1
	db $52
	db $51
	db $E2
	db $02
	db $01
	db $E1
	db $52
	db $E1
	db $72
	db $71
	db $E2
	db $22
	db $21
	db $E1
	db $72
	db $E2
	db $02
	db $01
	db $72
	db $71
	db $02
	db $E1
	db $A2
	db $A1
	db $E2
	db $72
	db $71
	db $E1
	db $A2
	db $E1
	db $52
	db $51
	db $E2
	db $02
	db $01
	db $E1
	db $52
	db $E1
	db $72
	db $71
	db $E2
	db $22
	db $21
	db $E1
	db $72
	db $E2
	db $02
	db $01
	db $72
	db $71
	db $02
	db $E1
	db $92
	db $91
	db $E2
	db $02
	db $01
	db $E1
	db $92
	db $E1
	db $52
	db $51
	db $E2
	db $02
	db $01
	db $E1
	db $52
	db $E1
	db $72
	db $71
	db $E2
	db $22
	db $21
	db $E1
	db $72
	db $41
	db $B1
	db $E2
	db $41
	db $22
	db $72
	db $51
	db $41
	db $C1
	db $FD, $00
Song2FD:
	db $D1, $11, $F1, $40, $00
	db $63
	db $64
	db $67
	db $67
	db $73
	db $74
	db $77
	db $77
	db $87
	db $87
	db $5E
	db $D7, $11, $F1, $40, $00
	db $FB
	db $FC
	db $32
	db $31
	db $32
	db $23
	db $12
	db $32
	db $11
	db $12
	db $11
	db $12
	db $31
	db $12
	db $23
	db $12
	db $32
	db $11
	db $12
	db $11
	db $12
	db $31
	db $12
	db $23
	db $12
	db $32
	db $11
	db $12
	db $11
	db $12
	db $31
	db $12
	db $23
	db $12
	db $32
	db $11
	db $12
	db $11
	db $32
	db $31
	db $32
	db $23
	db $12
	db $32
	db $11
	db $12
	db $11
	db $12
	db $31
	db $12
	db $23
	db $12
	db $32
	db $11
	db $12
	db $11
	db $12
	db $32
	db $12
	db $12
	db $12
	db $32
	db $12
	db $12
	db $12
	db $32
	db $12
	db $31
	db $11
	db $11
	db $32
	db $32
	db $31
	db $32
	db $FE, $01
	db $C1
	db $81
	db $94
	db $FC
	db $22
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FE, $0D
	db $31
	db $11
	db $11
	db $32
	db $32
	db $31
	db $32
	db $FD, $00

Song30B:
	db $EC, $08
	db $D6, $10, $B1, $35, $9B, $15, $77
	db $E0
	db $83
	db $83
	db $82
	db $93
	db $92
	db $91
	db $91
	db $91
	db $A3
	db $A3
	db $A2
	db $B2
	db $B1
	db $B2
	db $B1
	db $B1
	db $B1
	db $FB
	db $D6, $01, $B1, $35, $9B, $15, $C7
	db $E1
	db $0C
	db $74
	db $8A
	db $72
	db $82
	db $A2
	db $F6, $0C
	db $50
	db $F6, $06
	db $E1
	db $0C
	db $74
	db $89
	db $71
	db $81
	db $A1
	db $E2
	db $01
	db $31
	db $E1
	db $A1
	db $81
	db $F6, $0C
	db $A0
	db $F6, $06
	db $E2
	db $5A
	db $34
	db $82
	db $5A
	db $34
	db $12
	db $F6, $0C
	db $0C
	db $F6, $06
	db $C1
	db $E1
	db $71
	db $A1
	db $E2
	db $01
	db $11
	db $01
	db $11
	db $31
	db $5A
	db $34
	db $82
	db $5A
	db $34
	db $12
	db $09
	db $11
	db $31
	db $51
	db $01
	db $31
	db $71
	db $A1
	db $E3
	db $01
	db $C3
	db $08
	db $C4
	db $D6, $12, $B1, $35, $9B, $15, $E7
	db $E1
	db $0C
	db $74
	db $8A
	db $72
	db $82
	db $A2
	db $F6, $0C
	db $50
	db $F6, $06
	db $E1
	db $0C
	db $74
	db $89
	db $71
	db $81
	db $A1
	db $E2
	db $01
	db $31
	db $E1
	db $A1
	db $81
	db $F6, $0C
	db $A0
	db $F6, $06
	db $E2
	db $5A
	db $34
	db $82
	db $5A
	db $34
	db $12
	db $F6, $0C
	db $0C
	db $F6, $06
	db $C1
	db $E1
	db $71
	db $A1
	db $E2
	db $01
	db $11
	db $01
	db $11
	db $31
	db $5A
	db $34
	db $82
	db $3A
	db $14
	db $52
	db $F2, $C7
	db $E3
	db $06
	db $E2
	db $A6
	db $54
	db $A6
	db $86
	db $34
	db $E3
	db $06
	db $E2
	db $A6
	db $54
	db $E3
	db $16
	db $06
	db $E2
	db $54
	db $F6, $0C
	db $E3
	db $3A
	db $F6, $06
	db $F2, $E7
	db $C5
	db $51
	db $E8, $22
	db $31
	db $11
	db $31
	db $11
	db $01
	db $E2
	db $81
	db $E8, $12
	db $A0
	db $C4
	db $E3
	db $18
	db $04
	db $FD, $00
Song30A:
	db $EC, $08
	db $D6, $01, $81, $35, $9B, $14, $77
	db $E0
	db $33
	db $33
	db $32
	db $43
	db $42
	db $41
	db $41
	db $41
	db $53
	db $53
	db $52
	db $62
	db $61
	db $62
	db $61
	db $61
	db $61
	db $EF, $01
	db $FB
	db $D6, $11, $61, $35, $98, $14, $E7
	db $C2
	db $E1
	db $0C
	db $74
	db $8A
	db $72
	db $82
	db $A2
	db $F6, $0C
	db $50
	db $F6, $06
	db $E1
	db $0C
	db $74
	db $89
	db $71
	db $81
	db $A1
	db $E2
	db $01
	db $31
	db $E1
	db $A1
	db $81
	db $F6, $0C
	db $A0
	db $F6, $06
	db $E2
	db $5A
	db $34
	db $82
	db $5A
	db $34
	db $12
	db $F6, $0C
	db $0C
	db $F6, $06
	db $C1
	db $E1
	db $71
	db $A1
	db $E2
	db $01
	db $11
	db $01
	db $11
	db $31
	db $E2
	db $52
	db $E1
	db $71
	db $A1
	db $E2
	db $01
	db $31
	db $54
	db $34
	db $82
	db $E2
	db $52
	db $E1
	db $71
	db $A1
	db $E2
	db $01
	db $31
	db $54
	db $34
	db $12
	db $09
	db $11
	db $31
	db $51
	db $01
	db $31
	db $71
	db $A1
	db $E3
	db $01
	db $C3
	db $0A
	db $D6, $33, $91, $35, $99, $14, $77
	db $E1
	db $FC
	db $72
	db $71
	db $71
	db $FE, $03
	db $FC
	db $82
	db $81
	db $81
	db $FE, $03
	db $FC
	db $A2
	db $A1
	db $A1
	db $FE, $03
	db $FC
	db $82
	db $81
	db $81
	db $FE, $03
	db $FC
	db $72
	db $71
	db $71
	db $FE, $03
	db $FC
	db $82
	db $81
	db $81
	db $FE, $03
	db $FC
	db $A2
	db $A1
	db $A1
	db $FE, $07
	db $FC
	db $52
	db $51
	db $51
	db $FE, $07
	db $FC
	db $72
	db $71
	db $71
	db $FE, $07
	db $E1
	db $52
	db $51
	db $51
	db $E1
	db $71
	db $A1
	db $E2
	db $01
	db $31
	db $54
	db $E1
	db $52
	db $51
	db $51
	db $E1
	db $32
	db $31
	db $31
	db $E1
	db $51
	db $81
	db $A1
	db $E2
	db $11
	db $34
	db $E1
	db $32
	db $31
	db $31
	db $D6, $22, $81, $35, $9B, $14, $E7
	db $E3
	db $C2
	db $06
	db $E2
	db $A6
	db $54
	db $A6
	db $86
	db $34
	db $E3
	db $06
	db $E2
	db $A6
	db $54
	db $E3
	db $16
	db $06
	db $E2
	db $54
	db $F6, $0C
	db $E3
	db $3A
	db $F6, $06
	db $C3
	db $D6, $33, $91, $35, $99, $14, $77
	db $E2
	db $A1
	db $81
	db $61
	db $81
	db $61
	db $51
	db $31
	db $D6, $33, $A1, $35, $9A, $14, $77
	db $E1
	db $FC
	db $52
	db $51
	db $51
	db $FE, $07
	db $FD, $00
Song30C:
	db $EC, $FC
	db $D6, $06, $83, $81
	db $E1
	db $83
	db $83
	db $82
	db $E1
	db $93
	db $92
	db $91
	db $91
	db $91
	db $E1
	db $A3
	db $A3
	db $A2
	db $E1
	db $B2
	db $B1
	db $B2
	db $B1
	db $B1
	db $B1
	db $FB
	db $E2
	db $FC
	db $02
	db $01
	db $01
	db $FE, $03
	db $FC
	db $12
	db $11
	db $11
	db $FE, $03
	db $FC
	db $22
	db $21
	db $21
	db $FE, $03
	db $FC
	db $12
	db $11
	db $11
	db $FE, $03
	db $FC
	db $02
	db $01
	db $01
	db $FE, $03
	db $FC
	db $12
	db $11
	db $11
	db $FE, $03
	db $FC
	db $32
	db $31
	db $31
	db $FE, $07
	db $E1
	db $FC
	db $A2
	db $A1
	db $A1
	db $FE, $07
	db $E2
	db $FC
	db $02
	db $01
	db $01
	db $FE, $07
	db $E1
	db $FC
	db $A2
	db $A1
	db $A1
	db $FE, $07
	db $E2
	db $FC
	db $02
	db $01
	db $01
	db $FE, $0B
	db $FC
	db $12
	db $11
	db $11
	db $FE, $03
	db $FC
	db $22
	db $21
	db $21
	db $FE, $03
	db $FC
	db $12
	db $11
	db $11
	db $FE, $03
	db $FC
	db $02
	db $01
	db $01
	db $FE, $03
	db $FC
	db $12
	db $11
	db $11
	db $FE, $03
	db $FC
	db $32
	db $31
	db $31
	db $FE, $07
	db $E1
	db $FC
	db $A2
	db $A1
	db $A1
	db $FE, $07
	db $E2
	db $FC
	db $02
	db $01
	db $01
	db $FE, $07
	db $E1
	db $FC
	db $A2
	db $A1
	db $A1
	db $FE, $03
	db $FC
	db $82
	db $81
	db $81
	db $FE, $03
	db $FC
	db $A2
	db $A1
	db $A1
	db $FE, $03
	db $FC
	db $82
	db $81
	db $81
	db $FE, $03
	db $FC
	db $A2
	db $A1
	db $A1
	db $FE, $03
	db $E2
	db $FC
	db $12
	db $11
	db $11
	db $FE, $03
	db $FC
	db $32
	db $31
	db $31
	db $FE, $03
	db $32
	db $C6
	db $C1
	db $51
	db $31
	db $11
	db $31
	db $11
	db $01
	db $E1
	db $81
	db $E1
	db $FC
	db $A2
	db $A1
	db $A1
	db $FE, $03
	db $E2
	db $FC
	db $02
	db $01
	db $01
	db $FE, $03
	db $FD, $00
Song30D:
	db $D6, $11, $F1, $40, $00
	db $22
	db $11
	db $22
	db $11
	db $11
	db $11
	db $22
	db $11
	db $22
	db $11
	db $11
	db $11
	db $22
	db $11
	db $22
	db $11
	db $11
	db $11
	db $31
	db $11
	db $11
	db $32
	db $31
	db $31
	db $31
	db $FB
	db $FC
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FE, $0E
	db $12
	db $11
	db $11
	db $32
	db $22
	db $FC
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FE, $0F
	db $FC
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FE, $0E
	db $12
	db $11
	db $11
	db $32
	db $22
	db $FC
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FE, $1B
	db $FD, $00

Song32B:
	db $EC, $01
	db $D6, $01, $B1, $35, $9B, $15, $77
	db $CC
	db $FB
	db $F2, $77
	db $E1
	db $71
	db $A1
	db $E2
	db $01
	db $21
	db $52
	db $52
	db $E1
	db $C2
	db $21
	db $21
	db $22
	db $22
	db $E2
	db $42
	db $52
	db $41
	db $01
	db $22
	db $C2
	db $E1
	db $21
	db $21
	db $22
	db $22
	db $71
	db $A1
	db $E2
	db $01
	db $21
	db $52
	db $52
	db $E1
	db $C2
	db $71
	db $71
	db $72
	db $72
	db $E2
	db $42
	db $52
	db $41
	db $01
	db $22
	db $C2
	db $E1
	db $71
	db $71
	db $72
	db $72
	db $E2
	db $21
	db $51
	db $71
	db $91
	db $A2
	db $A2
	db $E1
	db $C2
	db $71
	db $71
	db $72
	db $72
	db $E2
	db $92
	db $A2
	db $91
	db $51
	db $22
	db $C2
	db $E1
	db $51
	db $51
	db $52
	db $52
	db $E2
	db $72
	db $92
	db $71
	db $31
	db $02
	db $C2
	db $E1
	db $31
	db $31
	db $32
	db $E2
	db $22
	db $03
	db $21
	db $24
	db $C2
	db $E1
	db $91
	db $91
	db $92
	db $92
	db $F2, $E7
	db $E1
	db $71
	db $A1
	db $E2
	db $01
	db $21
	db $52
	db $C1
	db $51
	db $58
	db $42
	db $52
	db $42
	db $C1
	db $01
	db $28
	db $E1
	db $71
	db $A1
	db $E2
	db $01
	db $21
	db $52
	db $C1
	db $51
	db $58
	db $42
	db $52
	db $42
	db $C1
	db $01
	db $28
	db $21
	db $51
	db $71
	db $91
	db $A2
	db $C1
	db $A1
	db $A8
	db $51
	db $71
	db $91
	db $A1
	db $E3
	db $02
	db $C1
	db $01
	db $08
	db $E2
	db $A2
	db $92
	db $F6, $0C
	db $7E
	db $F6, $06
	db $71
	db $A1
	db $E3
	db $01
	db $21
	db $33
	db $31
	db $37
	db $C1
	db $22
	db $32
	db $21
	db $01
	db $E2
	db $A2
	db $E3
	db $0B
	db $C1
	db $33
	db $31
	db $37
	db $C1
	db $22
	db $32
	db $21
	db $01
	db $E2
	db $A2
	db $E3
	db $0B
	db $C1
	db $23
	db $21
	db $28
	db $02
	db $22
	db $01
	db $E2
	db $A1
	db $92
	db $A2
	db $74
	db $72
	db $A2
	db $E3
	db $22
	db $76
	db $72
	db $A3
	db $93
	db $72
	db $78
	db $68
	db $F6, $0C
	db $7E
	db $F6, $06
	db $FD, $00
Song32A:
	db $EC, $01
	db $D6, $01, $81, $35, $99, $14, $57
	db $CC
	db $FB
	db $EF, $01
	db $E1
	db $21
	db $71
	db $91
	db $A1
	db $22
	db $22
	db $C2
	db $21
	db $21
	db $22
	db $22
	db $E2
	db $02
	db $02
	db $E1
	db $21
	db $21
	db $22
	db $C2
	db $21
	db $21
	db $22
	db $22
	db $E1
	db $21
	db $71
	db $91
	db $A1
	db $E1
	db $72
	db $72
	db $C2
	db $71
	db $71
	db $72
	db $72
	db $E2
	db $02
	db $02
	db $E1
	db $71
	db $71
	db $72
	db $C2
	db $71
	db $71
	db $72
	db $72
	db $E1
	db $A1
	db $E2
	db $21
	db $31
	db $51
	db $E1
	db $72
	db $72
	db $C2
	db $71
	db $71
	db $72
	db $72
	db $E2
	db $52
	db $52
	db $E1
	db $51
	db $51
	db $52
	db $C2
	db $51
	db $51
	db $52
	db $52
	db $E2
	db $32
	db $22
	db $E1
	db $31
	db $31
	db $32
	db $C2
	db $31
	db $31
	db $32
	db $32
	db $E1
	db $83
	db $81
	db $E1
	db $92
	db $92
	db $C2
	db $91
	db $91
	db $92
	db $92
	db $EF, $01
	db $D6, $11, $71, $35, $97, $24, $E7
	db $C1
	db $71
	db $A1
	db $E2
	db $01
	db $21
	db $53
	db $51
	db $58
	db $42
	db $52
	db $43
	db $01
	db $28
	db $E1
	db $71
	db $A1
	db $E2
	db $01
	db $21
	db $53
	db $51
	db $58
	db $42
	db $52
	db $43
	db $01
	db $28
	db $21
	db $51
	db $71
	db $91
	db $A3
	db $A1
	db $A8
	db $51
	db $71
	db $91
	db $A1
	db $E3
	db $03
	db $01
	db $08
	db $E2
	db $A2
	db $92
	db $7F
	db $EF, $00
	db $D6, $01, $91, $35, $99, $14, $E7
	db $E1
	db $A8
	db $E2
	db $28
	db $E2
	db $A3
	db $A1
	db $A7
	db $C1
	db $A2
	db $A2
	db $91
	db $71
	db $52
	db $5B
	db $C1
	db $A3
	db $A1
	db $A7
	db $C1
	db $A2
	db $A2
	db $91
	db $71
	db $52
	db $5B
	db $C1
	db $90
	db $76
	db $24
	db $22
	db $72
	db $A2
	db $A8
	db $E3
	db $73
	db $73
	db $22
	db $E3
	db $28
	db $E3
	db $28
	db $F6, $0C
	db $2E
	db $F6, $06
	db $FD, $00
Song32C:
	db $EC, $01
	db $D6, $06, $83, $72
	db $C0
	db $FB
	db $E1
	db $72
	db $72
	db $C2
	db $71
	db $71
	db $72
	db $72
	db $C4
	db $E1
	db $71
	db $71
	db $72
	db $C2
	db $71
	db $71
	db $72
	db $72
	db $C4
	db $E2
	db $02
	db $02
	db $C2
	db $01
	db $01
	db $02
	db $02
	db $C4
	db $E2
	db $01
	db $01
	db $02
	db $C2
	db $01
	db $01
	db $02
	db $02
	db $C4
	db $E2
	db $32
	db $32
	db $C2
	db $31
	db $31
	db $32
	db $32
	db $C4
	db $E1
	db $A1
	db $A1
	db $A2
	db $C2
	db $A1
	db $A1
	db $A2
	db $A2
	db $C4
	db $E1
	db $81
	db $81
	db $82
	db $C2
	db $81
	db $81
	db $82
	db $82
	db $C4
	db $E2
	db $22
	db $22
	db $C2
	db $21
	db $21
	db $22
	db $22
	db $E1
	db $21
	db $21
	db $21
	db $21
	db $E1
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $E1
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $E2
	db $02
	db $01
	db $01
	db $02
	db $01
	db $01
	db $02
	db $01
	db $01
	db $02
	db $01
	db $01
	db $E2
	db $02
	db $01
	db $01
	db $02
	db $01
	db $01
	db $02
	db $01
	db $01
	db $02
	db $01
	db $01
	db $E2
	db $32
	db $31
	db $31
	db $32
	db $31
	db $31
	db $32
	db $31
	db $31
	db $32
	db $31
	db $31
	db $E2
	db $52
	db $51
	db $51
	db $52
	db $51
	db $51
	db $52
	db $51
	db $51
	db $52
	db $51
	db $51
	db $E1
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $E1
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $F2, $92
	db $E2
	db $33
	db $F2, $72
	db $31
	db $32
	db $E1
	db $A2
	db $E2
	db $32
	db $E1
	db $A2
	db $C4
	db $F2, $92
	db $E2
	db $53
	db $F2, $72
	db $51
	db $02
	db $E1
	db $92
	db $E2
	db $02
	db $E1
	db $92
	db $E2
	db $02
	db $22
	db $F2, $92
	db $E2
	db $33
	db $F2, $72
	db $31
	db $32
	db $E1
	db $A2
	db $E2
	db $32
	db $E1
	db $A2
	db $C4
	db $F2, $92
	db $E2
	db $53
	db $F2, $72
	db $51
	db $02
	db $E1
	db $92
	db $E2
	db $02
	db $E1
	db $92
	db $E2
	db $02
	db $E1
	db $92
	db $E2
	db $22
	db $21
	db $21
	db $22
	db $21
	db $21
	db $02
	db $01
	db $01
	db $02
	db $01
	db $01
	db $E1
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $A2
	db $A1
	db $A1
	db $A2
	db $A1
	db $A1
	db $E2
	db $32
	db $31
	db $31
	db $32
	db $31
	db $31
	db $22
	db $21
	db $21
	db $22
	db $21
	db $21
	db $E1
	db $62
	db $61
	db $61
	db $62
	db $61
	db $61
	db $92
	db $91
	db $91
	db $92
	db $91
	db $91
	db $E1
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $E1
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $72
	db $72
	db $C4
	db $FD, $00
Song32D:
	db $D1, $11, $F1, $40, $00
	db $32
	db $34
	db $36
	db $36
	db $36
	db $32
	db $34
	db $36
	db $36
	db $36
	db $F6, $06
	db $32
	db $32
	db $C4
	db $FC
	db $FB
	db $32
	db $32
	db $12
	db $31
	db $31
	db $32
	db $32
	db $14
	db $31
	db $31
	db $32
	db $12
	db $31
	db $31
	db $32
	db $32
	db $14
	db $FD, $02
	db $31
	db $31
	db $32
	db $12
	db $31
	db $31
	db $32
	db $32
	db $14
	db $32
	db $32
	db $12
	db $31
	db $31
	db $32
	db $32
	db $31
	db $31
	db $31
	db $31
	db $FB
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FD, $0F
	db $22
	db $11
	db $11
	db $32
	db $11
	db $11
	db $32
	db $32
	db $C4
	db $22
	db $11
	db $11
	db $32
	db $11
	db $11
	db $32
	db $11
	db $11
	db $32
	db $11
	db $11
	db $22
	db $11
	db $11
	db $32
	db $11
	db $11
	db $32
	db $32
	db $C4
	db $22
	db $11
	db $11
	db $32
	db $11
	db $11
	db $32
	db $11
	db $11
	db $32
	db $32
	db $FB
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FD, $0A
	db $32
	db $36
	db $FE, $00
	db $D6, $01, $B1, $44, $9B, $15, $A7
	db $C0
	db $EC, $01
	db $FB
	db $E8, $01
	db $E2
	db $96
	db $44
	db $E1
	db $91
	db $91
	db $E2
	db $41
	db $41
	db $91
	db $91
	db $76
	db $BA
	db $96
	db $44
	db $E1
	db $91
	db $91
	db $E2
	db $41
	db $41
	db $91
	db $91
	db $76
	db $2A
	db $96
	db $44
	db $E1
	db $91
	db $91
	db $E2
	db $41
	db $41
	db $91
	db $91
	db $B6
	db $74
	db $E1
	db $B1
	db $B1
	db $E2
	db $71
	db $71
	db $B1
	db $B1
	db $E3
	db $06
	db $E2
	db $94
	db $E3
	db $01
	db $01
	db $E2
	db $91
	db $91
	db $E3
	db $01
	db $01
	db $E2
	db $B6
	db $E3
	db $46
	db $E8, $22
	db $E2
	db $22
	db $F6, $01
	db $42
	db $52
	db $72
	db $92
	db $B2
	db $E3
	db $02
	db $F6, $06
	db $E3
	db $26
	db $21
	db $41
	db $53
	db $43
	db $22
	db $21
	db $11
	db $2A
	db $E2
	db $42
	db $F6, $01
	db $52
	db $72
	db $92
	db $B2
	db $E3
	db $02
	db $22
	db $F6, $06
	db $E3
	db $46
	db $41
	db $51
	db $73
	db $53
	db $42
	db $41
	db $31
	db $4E
	db $E8, $11
	db $56
	db $41
	db $51
	db $76
	db $51
	db $71
	db $96
	db $71
	db $91
	db $E4
	db $03
	db $E3
	db $B3
	db $92
	db $BC
	db $42
	db $F6, $01
	db $52
	db $72
	db $92
	db $B2
	db $E4
	db $02
	db $22
	db $F6, $06
	db $E4
	db $40
	db $FD, $00
	db $D6, $11, $71, $44, $98, $14, $A7
	db $C0
	db $EC, $01
	db $FB
	db $E8, $10
	db $F2, $A7
	db $E2
	db $46
	db $E1
	db $94
	db $41
	db $41
	db $91
	db $91
	db $E2
	db $41
	db $41
	db $26
	db $7A
	db $46
	db $E1
	db $94
	db $41
	db $41
	db $91
	db $91
	db $E2
	db $41
	db $41
	db $26
	db $E1
	db $BA
	db $E2
	db $46
	db $E1
	db $94
	db $41
	db $41
	db $91
	db $91
	db $E2
	db $41
	db $41
	db $76
	db $24
	db $E1
	db $71
	db $71
	db $E2
	db $21
	db $21
	db $71
	db $71
	db $96
	db $54
	db $91
	db $91
	db $51
	db $51
	db $91
	db $91
	db $86
	db $B6
	db $E8, $22
	db $F2, $E7
	db $EF, $01
	db $E2
	db $24
	db $F6, $01
	db $42
	db $52
	db $72
	db $92
	db $B2
	db $E3
	db $02
	db $F6, $06
	db $E3
	db $26
	db $21
	db $41
	db $53
	db $43
	db $22
	db $21
	db $11
	db $2A
	db $E2
	db $42
	db $F6, $01
	db $52
	db $72
	db $92
	db $B2
	db $E3
	db $02
	db $22
	db $F6, $06
	db $E3
	db $46
	db $41
	db $51
	db $73
	db $53
	db $42
	db $41
	db $31
	db $4E
	db $E8, $11
	db $56
	db $41
	db $51
	db $76
	db $51
	db $71
	db $96
	db $71
	db $91
	db $E4
	db $03
	db $E3
	db $B3
	db $92
	db $BC
	db $42
	db $F6, $01
	db $52
	db $72
	db $92
	db $B2
	db $E4
	db $02
	db $22
	db $F6, $06
	db $E4
	db $4E
	db $FD, $00
	db $D6, $06, $83, $92, $EC, $01, $E1
	db $41
	db $41
	db $41
	db $41
	db $E2
	db $41
	db $E1
	db $41
	db $41
	db $41
	db $E2
	db $21
	db $E1
	db $41
	db $41
	db $E2
	db $01
	db $E1
	db $41
	db $41
	db $B1
	db $41
	db $FB
	db $E1
	db $FC
	db $92
	db $91
	db $91
	db $92
	db $91
	db $91
	db $92
	db $91
	db $91
	db $92
	db $91
	db $91
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $72
	db $71
	db $71
	db $FE, $02
	db $52
	db $51
	db $51
	db $52
	db $51
	db $51
	db $52
	db $51
	db $51
	db $52
	db $51
	db $51
	db $42
	db $41
	db $41
	db $42
	db $41
	db $41
	db $42
	db $41
	db $41
	db $42
	db $41
	db $41
	db $A2
	db $A1
	db $A1
	db $A2
	db $A1
	db $A1
	db $A2
	db $A1
	db $A1
	db $A2
	db $A1
	db $A1
	db $A2
	db $A1
	db $A1
	db $A2
	db $A1
	db $A1
	db $A2
	db $A1
	db $A1
	db $A2
	db $A1
	db $A1
	db $E2
	db $02
	db $01
	db $01
	db $02
	db $01
	db $01
	db $02
	db $01
	db $01
	db $02
	db $01
	db $01
	db $02
	db $01
	db $01
	db $02
	db $01
	db $01
	db $02
	db $01
	db $01
	db $02
	db $01
	db $01
	db $22
	db $21
	db $21
	db $22
	db $21
	db $21
	db $42
	db $41
	db $41
	db $42
	db $41
	db $41
	db $52
	db $51
	db $51
	db $52
	db $51
	db $51
	db $22
	db $21
	db $21
	db $22
	db $21
	db $21
	db $42
	db $41
	db $41
	db $42
	db $41
	db $41
	db $42
	db $41
	db $41
	db $42
	db $41
	db $41
	db $42
	db $41
	db $41
	db $22
	db $21
	db $21
	db $E1
	db $B2
	db $B1
	db $B1
	db $42
	db $41
	db $41
	db $FD, $00
	db $FF

	;Unused?
	db $D6, $11, $F1, $40, $00
	db $31
	db $11
	db $11
	db $11
	db $31
	db $11
	db $11
	db $11
	db $31
	db $11
	db $11
	db $31
	db $11
	db $11
	db $31
	db $31
	db $FB
	db $12
	db $11
	db $11
	db $32
	db $11
	db $11
	db $FD, $00
	db $FF

Song33B:
	db $EC, $02
	db $DC, $11, $71, $24, $95, $74, $E4
	db $E1
	db $C2
	db $42
	db $92
	db $E2
	db $42
	db $24
	db $72
	db $52
	db $41
	db $21
	db $40
	db $E1
	db $42
	db $92
	db $E2
	db $42
	db $74
	db $72
	db $92
	db $B1
	db $E3
	db $01
	db $E2
	db $4E
	db $E3
	db $06
	db $E2
	db $B1
	db $91
	db $B4
	db $72
	db $42
	db $54
	db $94
	db $34
	db $94
	db $40
	db $FF
Song33A:
	db $EC, $02
	db $DC, $33, $61, $24, $94, $73, $E4
	db $EF, $01
	db $E0
	db $C2
	db $92
	db $E1
	db $42
	db $92
	db $74
	db $E2
	db $22
	db $02
	db $E1
	db $91
	db $71
	db $90
	db $E0
	db $92
	db $E1
	db $42
	db $92
	db $E2
	db $24
	db $22
	db $42
	db $71
	db $91
	db $E2
	db $0E
	db $E2
	db $96
	db $71
	db $51
	db $74
	db $22
	db $02
	db $24
	db $54
	db $04
	db $54
	db $E1
	db $B0
	db $FF
Song33C:
	db $EC, $02
	db $DC, $07, $83, $F4
	db $E1
	db $98
	db $78
	db $F2, $C4
	db $94
	db $94
	db $94
	db $92
	db $F2, $F4
	db $42
	db $98
	db $B8
	db $F2, $C4
	db $E2
	db $04
	db $04
	db $04
	db $04
	db $E1
	db $54
	db $54
	db $74
	db $74
	db $24
	db $24
	db $34
	db $34
	db $F2, $F4
	db $40
	db $FF
Song33D:
	db $FF

Song34B:
	db $D7, $01, $B1, $26, $9B, $15, $C7
	db $EC, $FE
	db $FB
	db $E1
	db $A3
	db $A1
	db $C6
	db $A4
	db $A2
	db $93
	db $91
	db $C6
	db $94
	db $92
	db $A3
	db $A1
	db $C6
	db $A4
	db $A2
	db $B3
	db $B3
	db $E2
	db $03
	db $13
	db $22
	db $32
	db $FD, $01
	db $E2
	db $4C
	db $E1
	db $B4
	db $98
	db $E2
	db $24
	db $04
	db $E1
	db $B1
	db $91
	db $4E
	db $D7, $22, $41, $23, $93, $42, $C7
	db $E3
	db $B1
	db $91
	db $4E
	db $D7, $01, $B1, $26, $9B, $15, $C7
	db $E2
	db $4C
	db $E1
	db $B4
	db $98
	db $E2
	db $24
	db $04
	db $E1
	db $B1
	db $E2
	db $01
	db $E1
	db $BE
	db $D7, $22, $41, $23, $93, $42, $C7
	db $E3
	db $B1
	db $E4
	db $01
	db $E3
	db $BE
	db $D7, $01, $B1, $26, $9B, $15, $C7
	db $E2
	db $C2
	db $04
	db $02
	db $03
	db $E1
	db $73
	db $E2
	db $02
	db $E1
	db $C2
	db $A4
	db $A2
	db $A3
	db $53
	db $A2
	db $E2
	db $C2
	db $04
	db $02
	db $03
	db $E1
	db $73
	db $E2
	db $02
	db $33
	db $23
	db $02
	db $E1
	db $B4
	db $E8, $12
	db $E2
	db $74
	db $FB
	db $E3
	db $0A
	db $E2
	db $74
	db $E3
	db $02
	db $E2
	db $A8
	db $23
	db $53
	db $A2
	db $E3
	db $06
	db $02
	db $33
	db $23
	db $02
	db $08
	db $E2
	db $23
	db $73
	db $B2
	db $E3
	db $0A
	db $E2
	db $74
	db $E3
	db $02
	db $E2
	db $A8
	db $23
	db $53
	db $A2
	db $E3
	db $06
	db $02
	db $33
	db $23
	db $02
	db $08
	db $EC, $0A
	db $EB, $23
	db $E2
	db $23
	db $73
	db $B2
	db $FD, $01
	db $E3
	db $00
	db $FF
Song34A:
	db $D7, $10, $A1, $26, $9A, $14, $C7
	db $EC, $FE
	db $FB
	db $E1
	db $53
	db $51
	db $C6
	db $54
	db $52
	db $43
	db $41
	db $C6
	db $44
	db $42
	db $53
	db $51
	db $C6
	db $54
	db $52
	db $63
	db $63
	db $73
	db $83
	db $92
	db $A2
	db $FD, $01
	db $E8, $00
	db $E1
	db $BC
	db $74
	db $68
	db $94
	db $94
	db $71
	db $41
	db $0E
	db $EF, $01
	db $D7, $22, $31, $26, $92, $42, $C7
	db $C2
	db $E3
	db $B1
	db $91
	db $4C
	db $EF, $00
	db $D7, $00, $A1, $26, $9A, $14, $C7
	db $E1
	db $BC
	db $74
	db $68
	db $94
	db $94
	db $71
	db $91
	db $7E
	db $EF, $01
	db $D7, $22, $31, $26, $92, $42, $C7
	db $C2
	db $E3
	db $B1
	db $E4
	db $01
	db $E3
	db $BC
	db $EF, $00
	db $D7, $00, $A1, $26, $9A, $14, $C7
	db $E1
	db $C2
	db $74
	db $72
	db $73
	db $43
	db $72
	db $C2
	db $54
	db $52
	db $53
	db $23
	db $52
	db $C2
	db $84
	db $82
	db $83
	db $33
	db $82
	db $E2
	db $03
	db $E1
	db $B3
	db $92
	db $74
	db $E2
	db $24
	db $D7, $11, $B1, $26, $9B, $15, $C7
	db $FB
	db $E2
	db $7A
	db $44
	db $72
	db $E2
	db $58
	db $E1
	db $A3
	db $E2
	db $23
	db $52
	db $E2
	db $86
	db $82
	db $E3
	db $03
	db $E2
	db $A3
	db $82
	db $78
	db $E1
	db $B3
	db $E2
	db $23
	db $72
	db $E2
	db $7A
	db $44
	db $72
	db $E2
	db $58
	db $E1
	db $A3
	db $E2
	db $23
	db $52
	db $E2
	db $86
	db $82
	db $E3
	db $03
	db $E2
	db $A3
	db $82
	db $78
	db $EC, $0A
	db $EB, $23
	db $E1
	db $B3
	db $E2
	db $23
	db $72
	db $FD, $01
	db $E2
	db $40
	db $FF
Song34C:
	db $D7, $06, $83, $A2
	db $EC, $FE
	db $FB
	db $E1
	db $F2, $A2
	db $A1
	db $A1
	db $A1
	db $A1
	db $A1
	db $E2
	db $A1
	db $E1
	db $A1
	db $A1
	db $A1
	db $A1
	db $F2, $D2
	db $A4
	db $F2, $A2
	db $A1
	db $A1
	db $91
	db $91
	db $91
	db $91
	db $91
	db $E2
	db $91
	db $E1
	db $91
	db $91
	db $91
	db $91
	db $F2, $D2
	db $94
	db $F2, $A2
	db $91
	db $91
	db $A1
	db $A1
	db $A1
	db $A1
	db $A1
	db $E2
	db $A1
	db $E1
	db $A1
	db $A1
	db $A1
	db $A1
	db $F2, $D2
	db $A4
	db $F2, $A2
	db $A1
	db $A1
	db $F2, $D2
	db $B3
	db $B3
	db $E2
	db $03
	db $13
	db $22
	db $32
	db $FD, $01
	db $F2, $A2
	db $FB
	db $FC
	db $E2
	db $41
	db $41
	db $41
	db $41
	db $B1
	db $41
	db $41
	db $41
	db $FE, $01
	db $FC
	db $E2
	db $21
	db $21
	db $21
	db $21
	db $91
	db $21
	db $21
	db $21
	db $FE, $01
	db $FC
	db $E2
	db $01
	db $01
	db $01
	db $01
	db $71
	db $01
	db $01
	db $01
	db $FE, $01
	db $FC
	db $E2
	db $21
	db $21
	db $21
	db $21
	db $91
	db $21
	db $21
	db $21
	db $FE, $01
	db $FD, $01
	db $FB
	db $E2
	db $02
	db $01
	db $02
	db $01
	db $01
	db $01
	db $FD, $01
	db $FB
	db $E1
	db $A2
	db $A1
	db $A2
	db $A1
	db $A1
	db $A1
	db $FD, $01
	db $FB
	db $E1
	db $82
	db $81
	db $82
	db $81
	db $81
	db $81
	db $FD, $01
	db $FB
	db $E1
	db $72
	db $71
	db $72
	db $71
	db $71
	db $71
	db $FD, $01
	db $FB
	db $E2
	db $FC
	db $02
	db $01
	db $02
	db $01
	db $01
	db $01
	db $FE, $01
	db $E1
	db $FC
	db $A2
	db $A1
	db $A2
	db $A1
	db $A1
	db $A1
	db $FE, $01
	db $FC
	db $82
	db $81
	db $82
	db $81
	db $81
	db $81
	db $FE, $01
	db $FC
	db $72
	db $71
	db $72
	db $71
	db $71
	db $71
	db $FE, $01
	db $FD, $03
	db $F2, $D2
	db $E2
	db $00
	db $FF
Song34D:
	db $D7, $11, $F1, $40, $00
	db $FC
	db $FB
	db $11
	db $11
	db $11
	db $11
	db $31
	db $11
	db $11
	db $11
	db $11
	db $11
	db $11
	db $11
	db $31
	db $31
	db $11
	db $11
	db $FD, $02
	db $32
	db $11
	db $32
	db $11
	db $32
	db $11
	db $32
	db $11
	db $31
	db $31
	db $31
	db $31
	db $FE, $01
	db $FB
	db $11
	db $11
	db $11
	db $11
	db $31
	db $11
	db $11
	db $11
	db $FD, $0F
	db $FB
	db $12
	db $32
	db $11
	db $11
	db $32
	db $FD, $06
	db $12
	db $32
	db $11
	db $31
	db $31
	db $31
	db $FB
	db $12
	db $32
	db $11
	db $11
	db $32
	db $FD, $1F
	db $34
	db $FF

Song35B:
	db $EC, $04
	db $D8, $01, $B1, $23, $9B, $25, $A7
	db $F7
	dw Song35B_1
	db $B1
	db $E3
	db $01
	db $E2
	db $B1
	db $71
	db $F7
	dw Song35B_1
	db $E3
	db $01
	db $E2
	db $B1
	db $91
	db $71
	db $F7
	dw Song35B_1
	db $B1
	db $E3
	db $01
	db $E2
	db $B1
	db $71
	db $91
	db $91
	db $C4
	db $91
	db $91
	db $C4
	db $72
	db $82
	db $91
	db $91
	db $91
	db $91
	db $C1
	db $91
	db $91
	db $99
	db $FF
Song35B_1:
	db $E1
	db $91
	db $E2
	db $41
	db $91
	db $41
	db $72
	db $41
	db $92
	db $41
	db $72
	db $F9
Song35A:
	db $EC, $04
	db $D8, $01, $B1, $23, $9B, $24, $A7
	db $F7
	dw Song35A_1
	db $71
	db $91
	db $71
	db $21
	db $F7
	dw Song35A_1
	db $91
	db $71
	db $51
	db $41
	db $F7
	dw Song35A_1
	db $F6, $08
	db $71
	db $91
	db $71
	db $21
	db $41
	db $41
	db $C4
	db $41
	db $41
	db $C4
	db $22
	db $32
	db $11
	db $11
	db $11
	db $11
	db $C1
	db $11
	db $11
	db $19
	db $FF
Song35A_1:
	db $EF, $01
	db $F6, $04
	db $C1
	db $F6, $08
	db $E1
	db $91
	db $E2
	db $41
	db $91
	db $41
	db $72
	db $41
	db $92
	db $41
	db $F6, $04
	db $73
	db $F6, $08
	db $EF, $00
	db $F9
Song35C:
	db $EC, $04
	db $D8, $06, $83, $A0
	db $E1
	db $91
	db $91
	db $91
	db $91
	db $92
	db $91
	db $92
	db $91
	db $92
	db $71
	db $71
	db $71
	db $71
	db $E1
	db $51
	db $51
	db $51
	db $51
	db $52
	db $51
	db $52
	db $51
	db $52
	db $41
	db $41
	db $41
	db $41
	db $E1
	db $21
	db $21
	db $21
	db $21
	db $22
	db $21
	db $22
	db $21
	db $22
	db $71
	db $71
	db $71
	db $71
	db $91
	db $91
	db $C4
	db $91
	db $91
	db $C4
	db $72
	db $82
	db $91
	db $91
	db $91
	db $91
	db $C1
	db $91
	db $91
	db $99
	db $FF
Song35D:
	db $D8, $11, $F1, $40, $00
	db $FB
	db $11
	db $11
	db $31
	db $11
	db $11
	db $11
	db $31
	db $22
	db $11
	db $31
	db $11
	db $11
	db $11
	db $31
	db $11
	db $FD, $02
	db $31
	db $31
	db $F6, $01
	db $63
	db $65
	db $F6, $08
	db $71
	db $81
	db $91
	db $31
	db $32
	db $81
	db $61
	db $81
	db $32
	db $32
	db $31
	db $31
	db $31
	db $32
	db $31
	db $31
	db $31
	db $FF

Song36A:
	db $D3, $01, $91, $C3, $99, $35, $C7
	db $EC, $F4
	db $E3
	db $EF, $01
	db $39
	db $33
	db $EF, $00
	db $F6, $06
	db $89
	db $F6, $03
	db $83
	db $83
	db $7C
	db $74
	db $34
	db $14
	db $F6, $0C
	db $39
	db $F6, $03
	db $EF, $01
	db $39
	db $33
	db $EF, $00
	db $F6, $06
	db $89
	db $F6, $03
	db $83
	db $83
	db $7C
	db $74
	db $34
	db $14
	db $0C
	db $0C
	db $0C
	db $0C
	db $E4
	db $F6, $06
	db $19
	db $F6, $03
	db $16
	db $1C
	db $E3
	db $A4
	db $B4
	db $E4
	db $14
	db $E3
	db $F6, $06
	db $BC
	db $F6, $03
	db $8C
	db $83
	db $A3
	db $B3
	db $E4
	db $13
	db $F6, $06
	db $39
	db $F6, $03
	db $33
	db $33
	db $5C
	db $54
	db $34
	db $14
	db $E3
	db $89
	db $83
	db $83
	db $73
	db $56
	db $7C
	db $F7
	dw Song36A_1
	db $0C
	db $2C
	db $F6, $06
	db $3C
	db $2C
	db $E3
	db $7C
	db $AC
	db $F6, $03
	db $8C
	db $7C
	db $5C
	db $3C
	db $F6, $06
	db $3C
	db $F6, $03
	db $2C
	db $F7
	dw Song36A_1
	db $0C
	db $2C
	db $3C
	db $2C
	db $0C
	db $E3
	db $AC
	db $E4
	db $5C
	db $3C
	db $2C
	db $0C
	db $76
	db $56
	db $36
	db $76
	db $8C
	db $7C
	db $3F
	db $23
	db $33
	db $23
	db $E3
	db $AF
	db $83
	db $A3
	db $83
	db $E4
	db $0C
	db $E3
	db $86
	db $E4
	db $06
	db $E3
	db $86
	db $86
	db $56
	db $26
	db $F6, $0C
	db $3C
	db $E4
	db $1C
	db $0C
	db $E3
	db $AC
	db $F6, $0F
	db $AF
	db $FF
Song36A_1:
	db $E2
	db $A3
	db $E3
	db $33
	db $73
	db $A3
	db $F6, $06
	db $89
	db $F6, $03
	db $86
	db $8C
	db $76
	db $56
	db $79
	db $E2
	db $A3
	db $F6, $06
	db $AC
	db $F6, $03
	db $A3
	db $E3
	db $33
	db $73
	db $A3
	db $F6, $06
	db $89
	db $F6, $03
	db $86
	db $8C
	db $76
	db $56
	db $79
	db $E4
	db $03
	db $0C
	db $F9
Song36B:
	db $D3, $12, $B3, $C4, $9B, $35, $C7
	db $EC, $F4
	db $E3
	db $39
	db $33
	db $F6, $06
	db $E4
	db $09
	db $F6, $03
	db $06
	db $E3
	db $AC
	db $34
	db $A4
	db $E4
	db $14
	db $F6, $0C
	db $09
	db $F6, $03
	db $E3
	db $39
	db $33
	db $F6, $06
	db $E4
	db $09
	db $F6, $03
	db $06
	db $E3
	db $AC
	db $34
	db $A4
	db $E4
	db $14
	db $F6, $06
	db $09
	db $F6, $03
	db $E3
	db $A6
	db $8C
	db $89
	db $83
	db $E4
	db $F6, $06
	db $49
	db $F6, $03
	db $43
	db $43
	db $4C
	db $14
	db $34
	db $44
	db $F6, $06
	db $39
	db $F6, $03
	db $16
	db $E3
	db $BC
	db $B3
	db $E4
	db $13
	db $33
	db $53
	db $F6, $06
	db $79
	db $F6, $03
	db $73
	db $73
	db $8C
	db $84
	db $74
	db $54
	db $F6, $0C
	db $39
	db $F7
	dw Song36B_1
	db $E8, $12
	db $3C
	db $5C
	db $F6, $06
	db $79
	db $F6, $03
	db $76
	db $76
	db $86
	db $76
	db $56
	db $F6, $06
	db $39
	db $F6, $03
	db $36
	db $36
	db $56
	db $36
	db $16
	db $0C
	db $E3
	db $AC
	db $8C
	db $7C
	db $F6, $06
	db $7C
	db $F6, $03
	db $5C
	db $F7
	dw Song36B_1
	db $E8, $12
	db $3C
	db $5C
	db $F6, $06
	db $7F
	db $F6, $03
	db $36
	db $56
	db $76
	db $F6, $06
	db $8F
	db $F6, $03
	db $56
	db $76
	db $86
	db $AF
	db $73
	db $83
	db $A3
	db $E5
	db $0C
	db $2C
	db $3F
	db $23
	db $33
	db $23
	db $F6, $06
	db $E4
	db $AC
	db $F6, $03
	db $8C
	db $33
	db $53
	db $73
	db $83
	db $5C
	db $23
	db $33
	db $53
	db $73
	db $F6, $0C
	db $3C
	db $3C
	db $3C
	db $5C
	db $F6, $0F
	db $7F
	db $FF
Song36B_1:
	db $E8, $10
	db $F6, $03
	db $E3
	db $33
	db $73
	db $A3
	db $E4
	db $33
	db $09
	db $03
	db $F6, $06
	db $0C
	db $F6, $03
	db $E3
	db $A6
	db $86
	db $A9
	db $33
	db $F6, $06
	db $3C
	db $F6, $03
	db $33
	db $73
	db $A3
	db $E4
	db $33
	db $09
	db $03
	db $F6, $06
	db $0C
	db $F6, $03
	db $E3
	db $A6
	db $86
	db $A9
	db $E4
	db $33
	db $3C
	db $F9
Song36C:
	db $D3, $07, $86, $A2
	db $E2
	db $3C
	db $8C
	db $8C
	db $8C
	db $8C
	db $8C
	db $8C
	db $8C
	db $3C
	db $8C
	db $8C
	db $8C
	db $8C
	db $8C
	db $4C
	db $5C
	db $3C
	db $1C
	db $1C
	db $4C
	db $4C
	db $F6, $06
	db $89
	db $F6, $03
	db $36
	db $86
	db $76
	db $76
	db $56
	db $7C
	db $7C
	db $8C
	db $8C
	db $3C
	db $3C
	db $36
	db $36
	db $CC
	db $3C
	db $C6
	db $33
	db $33
	db $36
	db $36
	db $CC
	db $3C
	db $C6
	db $33
	db $33
	db $36
	db $36
	db $CC
	db $3C
	db $C6
	db $33
	db $33
	db $36
	db $36
	db $CC
	db $3C
	db $C6
	db $33
	db $33
	db $36
	db $36
	db $26
	db $26
	db $0C
	db $0C
	db $E1
	db $AC
	db $AC
	db $E2
	db $0C
	db $0C
	db $7C
	db $7C
	db $8C
	db $C6
	db $36
	db $36
	db $56
	db $76
	db $86
	db $AC
	db $AC
	db $AC
	db $CC
	db $3C
	db $C6
	db $33
	db $33
	db $36
	db $36
	db $CC
	db $3C
	db $C6
	db $33
	db $33
	db $36
	db $36
	db $CC
	db $3C
	db $C6
	db $33
	db $33
	db $36
	db $36
	db $CC
	db $3C
	db $C6
	db $33
	db $33
	db $36
	db $26
	db $06
	db $E1
	db $A6
	db $E2
	db $AC
	db $AC
	db $AC
	db $CC
	db $AC
	db $AC
	db $AC
	db $AC
	db $AC
	db $AC
	db $AC
	db $AC
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $3C
	db $FF
Song36D:
	db $D3, $11, $F1, $40, $00
	db $CC
	db $36
	db $36
	db $33
	db $C3
	db $33
	db $33
	db $36
	db $36
	db $34
	db $32
	db $32
	db $32
	db $32
	db $36
	db $36
	db $33
	db $C3
	db $33
	db $33
	db $36
	db $32
	db $32
	db $32
	db $36
	db $33
	db $33
	db $36
	db $36
	db $33
	db $C3
	db $33
	db $33
	db $36
	db $36
	db $34
	db $32
	db $32
	db $32
	db $32
	db $36
	db $32
	db $32
	db $32
	db $36
	db $32
	db $32
	db $32
	db $36
	db $32
	db $32
	db $32
	db $36
	db $33
	db $33
	db $36
	db $36
	db $32
	db $32
	db $32
	db $33
	db $33
	db $33
	db $33
	db $36
	db $34
	db $34
	db $34
	db $32
	db $32
	db $32
	db $CC
	db $33
	db $33
	db $36
	db $33
	db $33
	db $33
	db $33
	db $33
	db $33
	db $36
	db $36
	db $C6
	db $33
	db $33
	db $36
	db $36
	db $34
	db $32
	db $32
	db $32
	db $32
	db $36
	db $36
	db $33
	db $C3
	db $33
	db $33
	db $36
	db $36
	db $CC
	db $3C
	db $C6
	db $33
	db $33
	db $36
	db $36
	db $CC
	db $3C
	db $C6
	db $33
	db $33
	db $36
	db $36
	db $C6
	db $36
	db $3C
	db $C6
	db $33
	db $33
	db $36
	db $36
	db $CC
	db $3C
	db $C6
	db $33
	db $33
	db $36
	db $32
	db $32
	db $32
	db $36
	db $32
	db $32
	db $32
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $33
	db $33
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $33
	db $33
	db $33
	db $33
	db $36
	db $CC
	db $33
	db $33
	db $33
	db $C3
	db $33
	db $33
	db $33
	db $C3
	db $33
	db $33
	db $32
	db $32
	db $32
	db $CC
	db $33
	db $33
	db $36
	db $36
	db $CC
	db $3C
	db $C6
	db $33
	db $33
	db $36
	db $36
	db $CC
	db $3C
	db $C6
	db $33
	db $33
	db $36
	db $32
	db $32
	db $32
	db $36
	db $32
	db $32
	db $32
	db $3C
	db $C6
	db $33
	db $33
	db $36
	db $36
	db $CC
	db $36
	db $CC
	db $33
	db $33
	db $36
	db $33
	db $33
	db $36
	db $33
	db $33
	db $3C
	db $3C
	db $36
	db $16
	db $36
	db $16
	db $3C
	db $3C
	db $36
	db $12
	db $12
	db $12
	db $36
	db $16
	db $3C
	db $3C
	db $36
	db $32
	db $32
	db $32
	db $33
	db $33
	db $33
	db $33
	db $E9, $20
	db $16
	db $13
	db $13
	db $16
	db $13
	db $13
	db $16
	db $13
	db $13
	db $E9, $F1
	db $36
	db $E9, $E0
	db $13
	db $13
	db $16
	db $13
	db $13
	db $16
	db $13
	db $13
	db $16
	db $13
	db $13
	db $E9, $F1
	db $36
	db $33
	db $33
	db $E9, $E0
	db $16
	db $13
	db $13
	db $16
	db $13
	db $13
	db $16
	db $13
	db $13
	db $E9, $F1
	db $36
	db $32
	db $32
	db $32
	db $E9, $E0
	db $16
	db $13
	db $13
	db $16
	db $13
	db $13
	db $16
	db $13
	db $13
	db $E9, $F1
	db $36
	db $36
	db $E9, $E0
	db $16
	db $13
	db $13
	db $16
	db $13
	db $13
	db $16
	db $13
	db $13
	db $E9, $F1
	db $36
	db $32
	db $32
	db $32
	db $E9, $E0
	db $16
	db $13
	db $13
	db $16
	db $13
	db $13
	db $16
	db $13
	db $13
	db $E9, $F1
	db $36
	db $36
	db $E9, $E0
	db $16
	db $13
	db $13
	db $16
	db $13
	db $13
	db $16
	db $13
	db $13
	db $E9, $F1
	db $36
	db $32
	db $32
	db $32
	db $E9, $E0
	db $16
	db $13
	db $13
	db $16
	db $13
	db $13
	db $16
	db $13
	db $13
	db $E9, $F1
	db $36
	db $36
	db $3C
	db $FF

Song37B:
	db $D5, $10, $91, $26, $99, $14, $C7
Song37A_1:
	db $C0
	db $C0
	db $FB
	db $FC
	db $E1
	db $42
	db $E2
	db $42
	db $32
	db $F6, $0A
	db $2D
	db $F6, $05
	db $E1
	db $42
	db $E2
	db $22
	db $12
	db $F6, $0A
	db $0D
	db $F6, $05
	db $E1
	db $42
	db $E2
	db $42
	db $32
	db $2A
	db $E1
	db $42
	db $E2
	db $22
	db $12
	db $0A
	db $E1
	db $42
	db $E2
	db $02
	db $E1
	db $B2
	db $AC
	db $91
	db $91
	db $61
	db $61
	db $31
	db $31
	db $01
	db $31
	db $61
	db $91
	db $E2
	db $01
	db $31
	db $61
	db $91
	db $EC, $05
	db $FE, $01
	db $EC, $00
	db $FD, $00
Song37A:
	db $D5, $00, $71, $26, $97, $13, $C7
	db $EF, $01
	db $C1
	db $F7
	dw Song37A_1
Song37C:
	db $D5, $06, $83, $91
	db $E1
	db $FB
	db $42
	db $42
	db $42
	db $41
	db $41
	db $FD, $03
	db $FC
	db $FB
	db $F7
	dw Song37C_1
	db $F7
	dw Song37C_1
	db $F7
	dw Song37C_1
	db $F7
	dw Song37C_1
	db $F7
	dw Song37C_1
	db $F7
	dw Song37C_1
	db $F7
	dw Song37C_1
	db $F7
	dw Song37C_1
	db $F7
	dw Song37C_2
	db $F7
	dw Song37C_2
	db $F7
	dw Song37C_2
	db $32
	db $32
	db $32
	db $32
	db $31
	db $31
	db $31
	db $31
	db $32
	db $31
	db $31
	db $EC, $05
	db $FD, $01
	db $EC, $00
	db $FE, $00
Song37C_1:
	db $42
	db $42
	db $42
	db $41
	db $41
	db $F9
Song37C_2:
	db $42
	db $42
	db $42
	db $42
	db $42
	db $42
	db $42
	db $41
	db $41
	db $F9
Song37D:
	db $D5, $11, $F1, $40, $00
	db $FB
	db $12
	db $12
	db $32
	db $11
	db $11
	db $FD, $03
	db $FC
	db $F7
	dw Song37D_1
	db $F7
	dw Song37D_1
	db $FE, $00
Song37D_1:
	db $FB
	db $12
	db $12
	db $32
	db $11
	db $11
	db $FD, $07
	db $FB
	db $12
	db $12
	db $32
	db $12
	db $12
	db $12
	db $32
	db $11
	db $11
	db $FD, $02
	db $12
	db $12
	db $32
	db $12
	db $11
	db $11
	db $11
	db $11
	db $32
	db $11
	db $11
	db $F9

Song3AB:
	db $D2, $00, $B1, $00, $08
	db $E2
	db $FB
	db $41
	db $51
	db $61
	db $71
	db $81
	db $91
	db $A1
	db $B5
	db $C1
	db $FD, $03
Song38B:
	db $D5, $01, $B1, $26, $9B, $15, $C7
	db $E0
	db $81
	db $71
	db $81
	db $91
	db $A1
	db $91
	db $A1
	db $B1
	db $E1
	db $01
	db $E0
	db $B1
	db $E1
	db $01
	db $11
	db $21
	db $11
	db $21
	db $31
	db $FB
	db $E1
	db $48
	db $94
	db $E2
	db $42
	db $E1
	db $BC
	db $72
	db $62
	db $52
	db $46
	db $94
	db $E2
	db $42
	db $32
	db $20
	db $C2
	db $E1
	db $48
	db $94
	db $E2
	db $42
	db $E1
	db $BE
	db $92
	db $B2
	db $E2
	db $02
	db $E1
	db $B2
	db $92
	db $E2
	db $24
	db $04
	db $E1
	db $B2
	db $E2
	db $42
	db $22
	db $02
	db $54
	db $44
	db $22
	db $E8, $10
	db $4C
	db $92
	db $2C
	db $E1
	db $B2
	db $E2
	db $02
	db $22
	db $4A
	db $92
	db $82
	db $7E
	db $92
	db $B2
	db $E3
	db $06
	db $E2
	db $76
	db $E3
	db $04
	db $E2
	db $A6
	db $56
	db $A4
	db $F6, $0A
	db $90
	db $F6, $05
	db $E8, $02
	db $F7
	dw Song38B_1
	db $E8, $01
	db $C2
	db $E2
	db $B2
	db $A2
	db $92
	db $82
	db $76
	db $FD, $00
Song38B_1:
	db $E3
	db $02
	db $E2
	db $92
	db $52
	db $04
	db $52
	db $92
	db $E3
	db $02
	db $E2
	db $A2
	db $72
	db $32
	db $E1
	db $A4
	db $E2
	db $32
	db $72
	db $A2
	db $82
	db $52
	db $12
	db $E1
	db $84
	db $E2
	db $12
	db $52
	db $82
	db $72
	db $32
	db $02
	db $E1
	db $74
	db $E2
	db $02
	db $32
	db $72
	db $8A
	db $52
	db $82
	db $E3
	db $12
	db $16
	db $36
	db $14
	db $00
	db $F9
Song3AA:
	db $D2, $00, $B1, $00, $03
	db $C5
	db $EF, $03
	db $E2
	db $FB
	db $41
	db $51
	db $61
	db $71
	db $81
	db $91
	db $A1
	db $B5
	db $C1
	db $FD, $02
	db $41
	db $51
	db $61
	db $71
	db $81
	db $91
	db $A1
	db $B1
Song38A:
	db $D5, $11, $A1, $26, $9A, $14, $C7
	db $EF, $03
	db $E0
	db $81
	db $71
	db $81
	db $91
	db $A1
	db $91
	db $A1
	db $B1
	db $E1
	db $01
	db $E0
	db $B1
	db $E1
	db $01
	db $11
	db $21
	db $11
	db $21
	db $31
	db $EF, $01
	db $FB
	db $E0
	db $98
	db $E1
	db $44
	db $92
	db $70
	db $C2
	db $E0
	db $96
	db $E1
	db $44
	db $92
	db $82
	db $70
	db $C2
	db $E0
	db $98
	db $E1
	db $44
	db $92
	db $7E
	db $72
	db $72
	db $92
	db $72
	db $52
	db $B4
	db $94
	db $72
	db $E2
	db $02
	db $E1
	db $B2
	db $92
	db $E2
	db $24
	db $04
	db $E1
	db $B2
	db $E8, $10
	db $9C
	db $E2
	db $42
	db $E1
	db $70
	db $C2
	db $9A
	db $E2
	db $42
	db $32
	db $2E
	db $52
	db $72
	db $76
	db $46
	db $74
	db $56
	db $26
	db $54
	db $F6, $0A
	db $10
	db $F6, $05
	db $D5, $22, $61, $26, $96, $14, $C7
	db $C2
	db $F7
	dw Song38B_1
	db $D5, $11, $A1, $26, $9A, $14, $C7
	db $E2
	db $62
	db $52
	db $42
	db $32
	db $26
	db $FD, $00
Song3AC:
	db $D2, $06, $83, $E2
	db $CD
	db $CD
	db $CD
	db $CD
Song38C:
	db $D5, $06, $83, $E2
	db $E1
	db $14
	db $34
	db $54
	db $74
	db $F2, $91
	db $FB
	db $E1
	db $F7
	dw Song38C_1
	db $F7
	dw Song38C_1
	db $F7
	dw Song38C_1
	db $22
	db $22
	db $22
	db $F2, $C1
	db $44
	db $F2, $91
	db $42
	db $42
	db $42
	db $52
	db $52
	db $52
	db $F2, $C1
	db $74
	db $F2, $91
	db $72
	db $72
	db $72
	db $F7
	dw Song38C_1
	db $F7
	dw Song38C_1
	db $E2
	db $02
	db $02
	db $02
	db $F2, $C1
	db $04
	db $F2, $91
	db $02
	db $02
	db $02
	db $E1
	db $A2
	db $A2
	db $A2
	db $F2, $C1
	db $A4
	db $F2, $91
	db $A2
	db $A2
	db $A2
	db $FC
	db $92
	db $FE, $0F
	db $E2
	db $52
	db $52
	db $52
	db $F2, $C1
	db $54
	db $F2, $91
	db $52
	db $52
	db $52
	db $32
	db $32
	db $32
	db $F2, $C1
	db $34
	db $F2, $91
	db $32
	db $32
	db $32
	db $12
	db $12
	db $12
	db $F2, $C1
	db $14
	db $F2, $91
	db $12
	db $12
	db $12
	db $02
	db $02
	db $02
	db $F2, $C1
	db $04
	db $F2, $91
	db $02
	db $02
	db $02
	db $FC
	db $12
	db $FE, $0F
	db $FC
	db $02
	db $FE, $08
	db $E1
	db $B2
	db $A2
	db $92
	db $82
	db $F2, $C1
	db $76
	db $F2, $91
	db $FD, $00
Song38C_1:
	db $FC
	db $92
	db $FE, $07
	db $FC
	db $72
	db $FE, $07
	db $F9
Song3AD:
	db $D2, $11, $F1, $40, $00
	db $CD
	db $CD
	db $CD
	db $CD
Song38D:
	db $D5, $11, $F1, $40, $00
	db $FB
	db $11
	db $FD, $0F
	db $FB
	db $FC
	db $12
	db $12
	db $32
	db $12
	db $FE, $0B
	db $FC
	db $12
	db $12
	db $32
	db $24
	db $12
	db $32
	db $12
	db $FE, $01
	db $FC
	db $12
	db $12
	db $32
	db $12
	db $FE, $07
	db $FC
	db $12
	db $12
	db $32
	db $24
	db $12
	db $32
	db $12
	db $FE, $01
	db $FC
	db $12
	db $12
	db $32
	db $12
	db $FE, $03
	db $FC
	db $12
	db $12
	db $32
	db $24
	db $12
	db $32
	db $12
	db $FE, $03
	db $FC
	db $12
	db $12
	db $32
	db $12
	db $FE, $06
	db $32
	db $32
	db $31
	db $31
	db $31
	db $31
	db $FD, $00

Song39B:
	db $EC, $02
	db $D7, $22, $B1, $24, $9B, $43, $87
	db $E2
	db $92
	db $B2
	db $E3
	db $02
	db $E2
	db $7A
	db $52
	db $72
	db $92
	db $4A
	db $22
	db $42
	db $52
	db $24
	db $14
	db $20
	db $FF
Song39A:
	db $EC, $02
	db $D2, $22, $91, $22, $96, $42, $87
	db $EF, $03
	db $F3, $00
	db $C5
	db $F6, $07
	db $E2
	db $92
	db $B2
	db $E3
	db $02
	db $E2
	db $7A
	db $52
	db $72
	db $92
	db $4A
	db $22
	db $42
	db $52
	db $24
	db $14
	db $F3, $03
	db $2E
	db $FF
Song39C:
	db $EC, $02
	db $D7, $06, $8C, $90
	db $E1
	db $56
	db $44
	db $72
	db $E2
	db $02
	db $72
	db $E1
	db $26
	db $04
	db $92
	db $E2
	db $02
	db $42
	db $E0
	db $A6
	db $94
	db $94
	db $E1
	db $20
	db $FF

Song3BB:
	db $EC, $FD
	db $D7, $01, $91, $23, $99, $53, $87
	db $FB
	db $F6, $01
	db $E2
	db $79
	db $C1
	db $78
	db $C1
	db $78
	db $C1
	db $F6, $07
	db $E3
	db $06
	db $01
	db $01
	db $E2
	db $A4
	db $F6, $01
	db $AA
	db $E3
	db $29
	db $59
	db $F6, $07
	db $4C
	db $E2
	db $F6, $01
	db $E2
	db $79
	db $C1
	db $78
	db $C1
	db $78
	db $C1
	db $F6, $07
	db $E3
	db $06
	db $01
	db $01
	db $E2
	db $A4
	db $F6, $01
	db $AA
	db $E3
	db $29
	db $59
	db $F6, $07
	db $7C
	db $73
	db $71
	db $5C
	db $03
	db $51
	db $3C
	db $E2
	db $A3
	db $E3
	db $31
	db $24
	db $24
	db $24
	db $F6, $01
	db $0A
	db $E2
	db $B9
	db $E3
	db $09
	db $F6, $07
	db $7C
	db $FD, $00
Song3BA:
	db $EC, $FD
	db $D7, $10, $81, $24, $98, $53, $87
	db $FB
	db $F6, $01
	db $E2
	db $59
	db $C1
	db $58
	db $C1
	db $58
	db $C1
	db $F6, $07
	db $76
	db $71
	db $71
	db $54
	db $F6, $01
	db $5A
	db $A9
	db $E3
	db $29
	db $F6, $07
	db $E2
	db $7C
	db $F6, $01
	db $59
	db $C1
	db $58
	db $C1
	db $58
	db $C1
	db $F6, $07
	db $76
	db $71
	db $71
	db $54
	db $F6, $01
	db $5A
	db $A9
	db $E3
	db $29
	db $F6, $07
	db $2C
	db $23
	db $21
	db $0C
	db $E2
	db $93
	db $E3
	db $01
	db $E2
	db $AC
	db $73
	db $A1
	db $94
	db $94
	db $94
	db $F6, $01
	db $6A
	db $69
	db $69
	db $F6, $07
	db $E3
	db $2C
	db $FD, $00
Song3BC:
	db $EC, $FD
	db $D7, $06, $8C, $90
	db $FB
	db $C4
	db $E2
	db $04
	db $04
	db $E1
	db $A4
	db $F6, $01
	db $AA
	db $A9
	db $A9
	db $F6, $07
	db $E2
	db $04
	db $04
	db $02
	db $02
	db $C4
	db $E2
	db $04
	db $04
	db $E1
	db $A4
	db $F6, $01
	db $AA
	db $A9
	db $A9
	db $F6, $07
	db $74
	db $74
	db $74
	db $E2
	db $73
	db $71
	db $54
	db $54
	db $54
	db $53
	db $51
	db $34
	db $34
	db $34
	db $33
	db $31
	db $24
	db $24
	db $24
	db $F6, $01
	db $2A
	db $29
	db $29
	db $F6, $07
	db $E1
	db $74
	db $74
	db $72
	db $72
	db $FD, $00
Song3BD:
	db $D7, $11, $F1, $40, $00
	db $FB
	db $C4
	db $32
	db $32
	db $F6, $01
	db $34
	db $35
	db $35
	db $F6, $07
	db $31
	db $31
	db $32
	db $32
	db $F6, $01
	db $3A
	db $39
	db $39
	db $F6, $07
	db $32
	db $32
	db $F6, $01
	db $34
	db $35
	db $35
	db $F6, $07
	db $31
	db $31
	db $32
	db $32
	db $C4
	db $32
	db $32
	db $F6, $01
	db $34
	db $35
	db $35
	db $F6, $07
	db $31
	db $31
	db $32
	db $32
	db $F6, $01
	db $3A
	db $39
	db $39
	db $F6, $07
	db $32
	db $32
	db $F6, $01
	db $34
	db $35
	db $35
	db $F6, $07
	db $31
	db $31
	db $32
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $FC
	db $32
	db $31
	db $31
	db $32
	db $31
	db $31
	db $32
	db $31
	db $31
	db $31
	db $31
	db $31
	db $31
	db $FE, $01
	db $32
	db $31
	db $31
	db $32
	db $31
	db $31
	db $32
	db $31
	db $31
	db $F6, $01
	db $3A
	db $39
	db $39
	db $F6, $07
	db $32
	db $31
	db $31
	db $F6, $01
	db $34
	db $35
	db $35
	db $F6, $07
	db $31
	db $31
	db $32
	db $32
	db $FD, $00

Song3CA:
	db $D3, $01, $B2, $C5, $9B, $15, $87
	db $EC, $F0
	db $CC
	db $CC
	db $CC
	db $CC
	db $FB
	db $E8, $01
	db $E3
	db $F6, $06
	db $5C
	db $5C
	db $F6, $09
	db $4C
	db $F6, $03
	db $06
	db $26
	db $F6, $06
	db $5C
	db $5C
	db $F6, $0C
	db $4C
	db $76
	db $56
	db $56
	db $56
	db $76
	db $56
	db $46
	db $26
	db $E8, $23
	db $F6, $03
	db $9A
	db $E4
	db $06
	db $E3
	db $52
	db $94
	db $E4
	db $02
	db $E3
	db $7A
	db $E4
	db $06
	db $E3
	db $42
	db $74
	db $E4
	db $02
	db $E3
	db $5A
	db $E4
	db $06
	db $E3
	db $02
	db $54
	db $E4
	db $02
	db $E3
	db $46
	db $EF, $01
	db $E4
	db $06
	db $EF, $00
	db $E3
	db $76
	db $E4
	db $06
	db $E3
	db $9A
	db $E4
	db $06
	db $E3
	db $52
	db $94
	db $E4
	db $02
	db $E3
	db $7A
	db $E4
	db $06
	db $E3
	db $42
	db $74
	db $E4
	db $02
	db $E3
	db $5A
	db $E4
	db $06
	db $E3
	db $02
	db $54
	db $E4
	db $02
	db $E3
	db $06
	db $46
	db $76
	db $E4
	db $06
	db $E3
	db $9A
	db $E4
	db $06
	db $E3
	db $52
	db $94
	db $E4
	db $02
	db $E3
	db $7A
	db $E4
	db $06
	db $E3
	db $42
	db $74
	db $E4
	db $02
	db $E3
	db $5A
	db $E4
	db $06
	db $E3
	db $22
	db $54
	db $92
	db $E3
	db $46
	db $06
	db $46
	db $76
	db $5A
	db $A6
	db $22
	db $53
	db $A3
	db $5A
	db $E4
	db $06
	db $E3
	db $52
	db $94
	db $E4
	db $02
	db $22
	db $E3
	db $B2
	db $72
	db $B2
	db $72
	db $22
	db $72
	db $52
	db $22
	db $22
	db $72
	db $B2
	db $E4
	db $06
	db $E3
	db $56
	db $76
	db $96
	db $FD, $00
	db $FF
Song3CB:
	db $D3, $01, $B2, $C5, $9B, $15, $87
	db $EC, $F0
	db $CC
	db $CC
	db $CC
	db $CC
	db $FB
	db $E3
	db $F6, $06
	db $AC
	db $9C
	db $F6, $09
	db $7C
	db $F6, $03
	db $76
	db $96
	db $F6, $06
	db $AC
	db $9C
	db $F6, $0C
	db $7C
	db $E4
	db $06
	db $E3
	db $A6
	db $96
	db $A6
	db $E4
	db $06
	db $E3
	db $A6
	db $96
	db $76
	db $F6, $06
	db $E5
	db $0F
	db $F6, $03
	db $E4
	db $A6
	db $96
	db $76
	db $9A
	db $F6, $06
	db $5A
	db $03
	db $23
	db $53
	db $5C
	db $F6, $03
	db $0C
	db $76
	db $94
	db $F6, $09
	db $50
	db $F6, $03
	db $C2
	db $F6, $06
	db $E5
	db $0F
	db $E4
	db $A3
	db $93
	db $73
	db $F6, $03
	db $99
	db $E5
	db $09
	db $E4
	db $96
	db $79
	db $99
	db $76
	db $5A
	db $28
	db $56
	db $5A
	db $78
	db $96
	db $9A
	db $78
	db $56
	db $E5
	db $06
	db $E4
	db $56
	db $76
	db $96
	db $FD, $00
	db $FF
Song3CC:
	db $D3, $04, $86, $65
	db $EC, $FC
	db $E2
	db $CC
	db $CC
	db $CC
	db $CC
	db $FB
	db $FC
	db $04
	db $02
	db $04
	db $02
	db $04
	db $02
	db $04
	db $02
	db $FE, $06
	db $06
	db $E1
	db $56
	db $76
	db $96
	db $E2
	db $FC
	db $04
	db $02
	db $04
	db $02
	db $04
	db $02
	db $04
	db $02
	db $FE, $07
	db $FC
	db $54
	db $52
	db $54
	db $52
	db $54
	db $52
	db $54
	db $52
	db $44
	db $42
	db $44
	db $42
	db $44
	db $42
	db $44
	db $42
	db $24
	db $22
	db $24
	db $22
	db $24
	db $22
	db $24
	db $22
	db $04
	db $02
	db $04
	db $02
	db $04
	db $02
	db $04
	db $02
	db $FE, $02
	db $A4
	db $A2
	db $A4
	db $A2
	db $A4
	db $A2
	db $A4
	db $A2
	db $94
	db $92
	db $94
	db $92
	db $94
	db $92
	db $94
	db $92
	db $74
	db $72
	db $74
	db $72
	db $74
	db $72
	db $74
	db $72
	db $04
	db $02
	db $04
	db $02
	db $04
	db $02
	db $04
	db $02
	db $FD, $00
	db $FF
Song3CD:
	db $D3, $11, $F1, $40, $00
	db $32
	db $32
	db $32
	db $32
	db $32
	db $32
	db $42
	db $42
	db $42
	db $42
	db $42
	db $42
	db $52
	db $52
	db $52
	db $52
	db $52
	db $52
	db $56
	db $C6
	db $FB
	db $FC
	db $14
	db $12
	db $34
	db $12
	db $14
	db $12
	db $34
	db $12
	db $FE, $02
	db $14
	db $12
	db $34
	db $12
	db $14
	db $12
	db $32
	db $32
	db $32
	db $FC
	db $14
	db $12
	db $34
	db $12
	db $14
	db $12
	db $34
	db $12
	db $FE, $02
	db $14
	db $12
	db $34
	db $12
	db $14
	db $12
	db $32
	db $32
	db $32
	db $FC
	db $14
	db $12
	db $34
	db $12
	db $14
	db $12
	db $34
	db $12
	db $FE, $02
	db $14
	db $12
	db $34
	db $12
	db $14
	db $12
	db $32
	db $32
	db $32
	db $FC
	db $14
	db $12
	db $34
	db $12
	db $14
	db $12
	db $34
	db $12
	db $FE, $02
	db $32
	db $32
	db $32
	db $32
	db $32
	db $32
	db $32
	db $32
	db $32
	db $32
	db $32
	db $32
	db $FD, $00
	db $FF

SongTab:
	dw Song00
	dw Song01
	dw Song02
	dw Song03
	dw Song04
	dw Song05
	dw Song06
	dw Song07
	dw Song08
	dw Song09
	dw Song0A
	dw Song0B
	dw Song0C
	dw Song0D
	dw Song0E
	dw Song0F
	dw Song10
	dw Song11
	dw Song12
	dw Song13
	dw Song14
	dw Song15
	dw Song16
	dw Song17
	dw Song18
	dw Song19
	dw Song1A
	dw Song1B
	dw Song1C
	dw Song1D
	dw Song1E
	dw Song1F
	dw Song20
	dw Song21
	dw Song22
	dw Song23
	dw Song24
	dw Song25
	dw Song26
	dw Song27
	dw Song28
	dw Song29
	dw Song2A
	dw Song2B
	dw Song2C
	dw Song2D
	dw Song2E
	dw Song2F
	dw Song30
	dw Song31
	dw Song32
	dw Song33
	dw Song34
	dw Song35
	dw Song36
	dw Song37
	dw Song38
	dw Song39
	dw Song3A
	dw Song3B
	dw Song3C

Song00:

Song0A:
	db %00000000
	db 0
	dw EmptySeq

Song01:
	db %10000000
	db 0
	dw Song01D

Song02:
	db %10000000
	db 0
	dw Song02D

Song03:	
	db %10000000
	db 0
	dw Song03D

Song04:
	db %11000000
	db 0
	dw Song04C
	dw Song04D

Song05:
	db %11000000
	db 0
	dw Song05C
	dw Song05D

Song06:
	db %11000000
	db 0
	dw Song06C
	dw Song01D

Song07:
	db %11000000
	db 0
	dw Song07C
	dw Song01D

Song08:
	db %11000000
	db 0
	dw Song08C
	dw Song01D

Song09:
	db %11000000
	db 0
	dw Song09C
	dw Song01D

Song0B:
	db %00010000
	db 3
	dw Song0BA

Song0C:
	db %10000000
	db 3
	dw Song0CD

Song0D:
	db %00010000
	db 4
	dw Song0DA

Song0E:
	db %00010000
	db 8
	dw Song0EA

Song0F:
	db %00010000
	db 6
	dw Song0FA
	
Song10:
	db %10010000
	db 7
	dw Song10A
	dw Song10D

Song11:
	db %10010000
	db 9
	dw Song11C
	dw Song11D

Song12:
	db %10010000
	db 9
	dw Song12A
	dw Song12D

Song13:
	db %10000000
	db 7
	dw Song13D

Song14:
	db %00010000
	db 10
	dw Song14A

Song15:
	db %10000000
	db 3
	dw Song15D

Song16:
	db %00010000
	db 5
	dw Song16A

Song17:
	db %10000000
	db 3
	dw Song17D

Song18:
	db %00010000
	db 11
	dw Song18A

Song1A:
	db %00010000
	db 3
	dw Song1AA

Song19:
	db %00010000
	db 12
	dw Song19A

Song1B:
	db %00010000
	db 3
	dw Song1BA

Song1C:
	db %00010000
	db 3
	dw Song1CA

Song1D:
	db %00010000
	db 3
	dw Song1DA

Song1E:
	db %00010000
	db 1
	dw Song1EA

Song1F:
	db %10000000
	db 2
	dw Song1FD

Song20:
	db %10000000
	db 1
	dw Song20D

Song21:
	db %10010000
	db 2
	dw Song21A
	dw Song21D

Song22:
	db %00010000
	db 10
	dw Song22A

Song23:
	db %10000000
	db 3
	dw Song23D

Song24:
	db %00010000
	db 11
	dw Song24A

Song25:
	db %00010000
	db 1
	dw Song25A

Song26:
	db %00110000
	db 10
	dw Song26A
	dw Song26B

Song27:
	db %00001111
	db 0
	dw Song27A
	dw Song27B
	dw EmptySeq
	dw EmptySeq
	
Song28:
	db %10010000
	db 4
	dw Song28A
	dw Song28D

Song29:
	db %00010000
	db 7
	dw Song29A

Song2A:
	db %10000000
	db 7
	dw Song2AD

Song2B:
	db %00001111
	db 2
	dw EmptySeq
	dw EmptySeq
	dw EmptySeq
	dw EmptySeq

Song2C:
	db %00001111
	db 0
	dw Song2CA
	dw Song2CB
	dw Song2CC
	dw Song2CD

Song2D:
	db %00001111
	db 0
	dw Song2DA
	dw Song2DB
	dw Song2DC
	dw Song2DD

Song2E:
	db %00001111
	db 0
	dw Song2EA
	dw Song2EB
	dw Song2EC
	dw Song2ED

Song2F:
	db %00001111
	db 0
	dw Song2FA
	dw Song2FB
	dw Song2FC
	dw Song2FD

Song30:
	db %00001111
	db 0
	dw Song30A
	dw Song30B
	dw Song30C
	dw Song30D

Song31:

Song32:
	db %00001111
	db 0
	dw Song32A
	dw Song32B
	dw Song32C
	dw Song32D

Song33:
	db %00001111
	db 0
	dw Song33A
	dw Song33B
	dw Song33C
	dw Song33D

Song34:
	db %00001111
	db 0
	dw Song34A
	dw Song34B
	dw Song34C
	dw Song34D

Song35:
	db %00001111
	db 0
	dw Song35A
	dw Song35B
	dw Song35C
	dw Song35D

Song36:
	db %00001111
	db 0
	dw Song36A
	dw Song36B
	dw Song36C
	dw Song36D

Song37:
	db %00001111
	db 0
	dw Song37A
	dw $64B5
	dw Song37C
	dw Song37D

Song38:
	db %00001111
	db 0
	dw Song38A
	dw Song38B
	dw Song38C
	dw Song38D

Song39:
	db %00001111
	db 0
	dw Song39A
	dw Song39B
	dw Song39C
	dw EmptySeq

Song3A:
	db %00001111
	db 0
	dw Song3AA
	dw Song3AB
	dw Song3AC
	dw Song3AD

Song3B:
	db %00001111
	db 0
	dw Song3BA
	dw Song3BB
	dw Song3BC
	dw Song3BD

Song3C:
	db %00001111
	db 0
	dw Song3CA
	dw Song3CB
	dw Song3CC
	dw Song3CD

;Load song/sound effect
LoadSong:
	;If song is 0
	or a
	jp z, NoAudio

	;If song is $0A, then fade out current music
	cp $0A
	jp z, FadeOutMus

	push bc
	push de
	;Load number to SFX number RAM variable
	ld [SFXNum], a
	;Get pointer from song table
	add a
	add LOW(SongTab)
	ld l, a
	ld a, HIGH(SongTab)
	adc 0
	ld h, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	
	;Load header values into RAM
	ld a, [hl+]
	ld [Temp1], a		;Byte 1 = Channel mask
	ld a, [hl+]
	ld [Temp2], a		;Byte 2 = priority
	ld b, h
	ld c, l
	;Set channel number to 0
	xor a
	ld [CurTrack], a
	ld de, MusC1MusNum

GetTracks:
	;Check if each track (SFX 4-1, then music 4-1) is present
	ld hl, Temp1
	srl [hl]
	;If track present
	jr c, .InitTrackRAM

	jr z, .LoadSongRet

.NextTrack
	;Advance channel
	ld hl, CurTrack
	inc [hl]
	;Skip to next channel area in RAM
	ld hl, TrackRAMSize
	add hl, de
	ld d, h
	ld e, l
	jr GetTracks

.LoadSongRet
;Return from routine
	pop de
	pop bc
	ret


.InitTrackRAM
;Get song number
	ld hl, $00
	add hl, de
	ld a, [hl+]
	or a
	jr z, .InitTrackRAM2

	;If not below priority, then don't play channel
	ld a, [Temp2]
	cp [hl]
	jr nc, .InitTrackRAM2

	inc bc
	inc bc
	jr .NextTrack

.InitTrackRAM2
	;Get pointer from current song
	ld h, b
	ld l, c
	ld a, [hl+]
	ld b, [hl]
	inc hl
	push hl
	ld hl, $20
	add hl, de
	ld [hl+], a
	ld [hl], b
	inc hl
	ld [hl+], a
	ld [hl], b
	inc hl
	ld [hl+], a
	ld [hl], b
	;Set vibrato to first sequence
	ld hl, $0F
	add hl, de
	ld a, LOW(Vibrato0)
	ld [hl+], a
	ld a, HIGH(Vibrato0)
	ld [hl], a
	pop bc
	;Add current channel mask to output value
	ld a, [CurTrack]
	add LOW(TrackMaskVals)
	ld l, a
	ld a, HIGH(TrackMaskVals)
	adc 0
	ld h, a
	ld a, [Output]
	or [hl]
	ld [Output], a
	;Copy SFX number value to channel music number
	ld h, d
	ld l, e
	ld a, [SFXNum]
	ld [hl+], a
	;Get priority value and copy to channel location
	ld a, [Temp2]
	ld [hl+], a
	;Set sweep value
	ld a, %00001000
	ld [hl+], a
	;Set transpose and tuning to 0
	xor a
	ld [hl+], a
	ld [hl+], a
	;Set volume to maximum
	ld a, %00000011
	ld [hl+], a
	ld [hl+], a
	;Set delay to 1
	ld a, 1
	ld [hl], a
	jr .NextTrack

;Call sound effect with music
CallSFX:
	;Get sound effect number called
	push bc
	push de
	ld [SFXNum], a
	;Get sound effect pointer from RAM
	add a
	add LOW(SongTab)
	ld l, a
	ld a, HIGH(SongTab)
	adc 0
	ld h, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	ld a, [hl+]
	;Get mask and priority values
	and %11110000
	swap a
	ld [Temp1], a
	ld a, [hl+]
	ld [Temp2], a
	ld b, h
	ld c, l
	;Set current track to 4 (SFX track 1)
	ld a, 4
	ld [CurTrack], a
	ld de, SFXC1MusNum
	jp GetTracks


FadeOutMus:
	ld a, 48
	ld [Fade], a
	ld [FadeTime], a
	ret


PlayAudio:
	;Check if fade out is enabled
	ld a, [Fade]
	or a
	;If not, then play audio
	jr z, .PlayAudio2

	;Otherwise, decrement fade and check again
	ld hl, FadeTime
	dec [hl]
	;If not done, then continue playing audio
	jr nz, .PlayAudio2

	;Otherwise, check NR50 value
	ld [hl], a
	ld hl, NR50Val
	ld a, [hl]
	;If not 0, then subtract volume
	or a
	;Otherwise, disable audio
	jp z, InitSound

	sub %00010001
	ld [hl], a

.PlayAudio2:
	call CheckAllTracks
	call OutputRegs
	ret


CheckAllTracks:
	;Check all tracks to see if they are playing
	xor a
	ld [CurTrackCheck], a
	ld de, MusC1MusNum

CheckTrack:
	;Check if track is on (with song number)
	ld hl, $00
	add hl, de
	ld a, [hl]
	cp 0
	;If 0, then skip to next track
	jr z, NextTrack

	;Process the track
	call ProcTrack
	;Copy values to register RAM values
	call ProcTrackRegVals

NextTrack:
;Skip to next track
	ld hl, $2C
	add hl, de
	ld d, h
	ld e, l
	ld hl, CurTrackCheck
	inc [hl]
	;If not done checking all 8 tracks, then check this track
	ld a, 8
	cp [hl]
	jr nz, CheckTrack

ProcTrackRet:
	ret


ProcTrack:
	;Process note length
	ld hl, $08
	add hl, de								;Increase time
	inc [hl]
	ld hl, $07								;Decrease delay
	add hl, de
	dec [hl]
	;If delay is complete, then get next command
	call z, NextCommand
	
	;Check if envelope is on
	ld hl, $09
	add hl, de
	ld a, [hl]
	or a
	;If not, then return
	jr z, ProcTrackRet

	;Otherwise, get envelope value
	ld hl, $11
	add hl, de
	ld a, [hl]
	bit 7, a
	jp z, ProcVibrato

ProcEnvState:
	;Otherwise, this is a decaying (CH1/CH2) envelope.
	;Wait out the current envelope stage.
	ld hl, $1A
	add hl, de
	dec [hl]
	;If not 0, then skip
	jp nz, EnvSustain

	;Check if wave channel
	ld a, [CurTrackCheck]
	and %00000011
	cp 2
	;If so, then perform special envelope handler
	jp z, ProcEnvStateCh3
	
	;Stage expired: pick the handler for the current envelope state.
	;State # is kept in +$18.
	ld hl, $18
	add hl, de
	ld a, [hl]
	cp 1
	jr c, EnvState1

	cp 2
	jr c, EnvState2

	cp 3
	jp c, EnvState3

	cp 4
	jp c, EnvState4

	cp 5
	jp c, EnvState5

	jp EnvSustain


EnvState1:
	;Get envelope value
	push bc
	ld hl, $11
	add hl, de
	ld a, [hl]
	
	;Get volume from envelope
	and %00001111
	ld b, a
	ld a, [hl]
	swap a
	;Also get envelope direction
	or %00001000
	
	;Load the value into current hardware volume register (NRx2)
	ld hl, $1F
	add hl, de
	ld [hl], a
	
	;Then load upper 3 bits
	and %00000111
	ld c, a
	
	;Get decay
	ld hl, $0D
	add hl, de
	ld a, [hl]
	swap a
	and %00001111
	
	;Subtract volume
	sub b
	;If not 0 or below, then go to next stage
	jr c, EnvState1_2

	;Otherwise, multiply the volume by decay
	ld b, c
	call Multiply
	;If result is 0, then skip to next state
	or a
	jr z, EnvState1_2

	pop bc
	;Otherwise, increase envelope state
	ld hl, $18
	add hl, de
	inc [hl]
	;Then save stage duration into RAM
	jp SaveStageDur


EnvState1_2:
	;Increase envelope state
	pop bc
	ld hl, $18
	add hl, de
	inc [hl]

EnvState2:
	push bc
	
	;Get decay
	ld hl, $0D
	add hl, de
	ld a, [hl]
	and %11110000
	ld b, a
	
	;Also get secondary decay parameter
	ld hl, $12
	add hl, de
	ld a, [hl]
	swap a
	and %00000111
	
	;Combine these values and save as current NRx1 volume
	ld c, a
	or b
	ld hl, $001f
	add hl, de
	ld [hl], a
	
	;Compute next stage's duration as (high nibble of +$0D - low nibble of +$12) x 7-bit count of +$12.
	ld hl, $12
	add hl, de
	ld a, [hl]
	and %00001111
	swap b
	ld l, a
	ld a, b
	sub l
	;If not 0 or below, then go to next stage
	jr c, EnvState2_2

	ld b, c
	call Multiply
	or a
	;If result is 0, then skip to next state
	jr z, EnvState2_2

	pop bc
	;Otherwise, increase envelope state
	ld hl, $18
	add hl, de
	inc [hl]
	;Then save stage duration into RAM
	jp SaveStageDur


EnvState2_2:
	;Increase envelope state
	pop bc
	ld hl, $18
	add hl, de
	inc [hl]

EnvState3:
	;Get secondary decay parameter
	ld hl, $12
	add hl, de
	ld a, [hl]
	swap a
	and %11110000
	
	;Save as current NRx1 volume
	ld hl, $1F
	add hl, de
	ld [hl], a
	;Get envelope time-base/speed
	push bc
	ld hl, $0A
	add hl, de
	ld a, [hl]
	;And get note time
	ld hl, $08
	add hl, de
	ld b, [hl]
	
	;Subtract note time from envelope time
	sub b
	;If not negative, then go to next state
	jr c, EnvState3_2

	jr z, EnvState3_2

	;Otherwise, increase envelope state
	pop bc
	ld hl, $18
	add hl, de
	inc [hl]
	;Then save stage duration into RAM
	jp SaveStageDur


EnvState3_2:
	;Increase envelope state
	pop bc
	ld hl, $18
	add hl, de
	inc [hl]

EnvState4:
	;Get secondary decay parameter
	push bc
	ld hl, $12
	add hl, de
	ld a, [hl]
	and %00001111
	swap a
	ld b, a

	;Get tertiary decay parameter
	ld hl, $13
	add hl, de
	ld a, [hl]
	and %00000111
	ld c, a

	;Combine these values and save as current NRx1 volume
	or b
	ld hl, $1F
	add hl, de
	ld [hl], a

	;Get secondary decay and revert swap
	ld a, b
	swap a
	push af

	;Get primary decay value
	ld hl, $0D
	add hl, de
	ld a, [hl]
	and %00001111
	ld b, a

	;Subtract secondary decay value
	pop af
	sub b

	;If decay is more than 0, then go to next stage
	jr c, EnvState4_2

	;Multiply values otherwise
	ld b, c
	call Multiply
	or a
	;If result is 0, then skip to next state
	jr z, EnvState4_2


	pop bc
	;Otherwise, increase envelope state
	ld hl, $18
	add hl, de
	inc [hl]
	;Then save stage duration into RAM
	jp SaveStageDur


EnvState4_2:
	;Increase envelope state
	pop bc
	ld hl, $18
	add hl, de
	inc [hl]

EnvState5:
	;Get primary decay value
	ld hl, $0D
	add hl, de
	ld a, [hl]
	and %00001111
	swap a
	
	;Set secondary decay value to it
	ld hl, $1F
	add hl, de
	ld [hl], a

	;Increase envelope state
	ld a, $FF
	ld hl, $18
	add hl, de
	inc [hl]
	;Set stage duration to 255 into RAM
	jp SaveStageDur


ProcEnvStateCh3:
	;Check state
	ld hl, $18
	add hl, de
	ld a, [hl]
	
	;Jump to the handler of the correct state
	cp 1
	jr c, EnvState1Ch3

	cp 2
	jr c, EnvState2Ch3

	cp 3
	jr c, EnvState3Ch3

	cp 4
	jr c, EnvState4Ch3

	;If none of the above, then return
	jp EnvSustain


EnvState1Ch3:
	;Set NR31 volume to maximum
	ld a, %11110000
	ld hl, $1F
	add hl, de
	ld [hl], a

	;Increase envelope state
	ld hl, $18
	add hl, de
	inc [hl]

	;Get envelope time + 1
	ld hl, $0A
	add hl, de
	ld a, [hl]
	inc a
	
	;Save stage duration
	jp SaveStageDur


EnvState2Ch3:
	;Get new volume
	ld a, %01010000

EnvState2Ch3_2:
	;Set NR31 volume
	ld hl, $1F
	add hl, de
	ld [hl], a

	;Increase envelope state
	ld hl, $18
	add hl, de
	inc [hl]

	;Get envelope value (lower 7 bits)
	ld hl, $11
	add hl, de
	ld a, [hl]
	and %01111111

	;Save stage duration
	jp SaveStageDur


EnvState3Ch3:
	;Get new volume
	ld a, %00010000
	;Rest of state is same as 2
	jr EnvState2Ch3_2

EnvState4Ch3:
	;Set NR31 volume to 0
	ld a, 0
	ld hl, $1F
	add hl, de
	ld [hl], a

	;Increase envelope state
	ld hl, $18
	add hl, de
	inc [hl]

	;Go to sustain
	jp EnvSustain

;Decrease envelope stage duration counter
ProcVibrato:
	ld hl, $1A
	add hl, de
	dec [hl]
	;If not done, then sustain
	jr nz, EnvSustain

	;Otherwise, get next envelope value from sequence
	ld hl, $17
	add hl, de
	inc [hl]
	;Advance the envelope sequence pointer
	ld a, [hl]
	ld hl, $14
	add hl, de
	push bc
	add [hl]
	ld c, a
	inc hl
	ld a, [hl]
	adc 0
	ld b, a
	;Check current envelope value
	ld a, [bc]
	pop bc
	;If FF, then end of sequence
	cp $FF
	;Otherwise, get volume
	jr nz, GetVol

	;Decrement sequence position
	ld hl, $17
	add hl, de
	dec [hl]
	;Restart envelope duration
	ld hl, $1A
	add hl, de
	ld [hl], a
	jr EnvSustain

GetVol:
	;Get volume from upper 4 bits of envelope
	ld hl, $1F
	add hl, de
	push af
	and %11110000
	ld [hl], a
	;Then get duration from lower 4 bits of envelope
	pop af
	and %00001111

SaveStageDur:
	;Load stage duration into RAM value
	ld hl, $1A
	add hl, de
	ld [hl], a

;After envelope is finished...
EnvSustain:
	;If channel is 7 (music 4), then return
	ld a, [CurTrackCheck]
	cp 7
	jr z, ProcNextVibratoRet

	ld hl, $19
	add hl, de
	dec [hl]
	;If not done, then return
	jp nz, ProcNextVibratoRet

	;Increase vibrato sequence
	ld hl, $16
	add hl, de
	inc [hl]
	ld a, [hl]

ProcNextVibrato:
	;Get next byte from vibrato sequence
	ld hl, $0F
	add hl, de
	push bc
	add [hl]
	ld c, a
	inc hl
	ld a, [hl]
	adc 0
	ld b, a
	ld a, [bc]
	pop bc
	;If FF, then end of sequence
	cp $FF
	;Otherwise, process value
	jr nz, .ProcNextVibrato2

	;Reset vibrato sequence step - back to start
	ld hl, $16
	add hl, de
	xor a
	ld [hl], a
	jr ProcNextVibrato

.ProcNextVibrato2
	;Check if value is positive or negative from upper 4 bits
	push af
	swap a
	and %00001111
	cp 8
	jr c, .ProcNextVibrato3

	;If negative
	or %11110000

.ProcNextVibrato3
	;Set vibrato value
	ld hl, $1C
	add hl, de
	ld [hl], a

	;Set delay from lower 4 bits
	pop af
	and %00001111
	ld hl, $19
	add hl, de
	ld [hl], a

ProcNextVibratoRet:
	ret


NextCommand:
	;Get channel pointer
	call GetChPtr

.NextCommand2
	;Get next byte from channel pointer
	ld a, [bc]
	cp $D0
	;If less than D0, is a note or rest
	jr c, .NoteOrRest

	;Otherwise, is parameters or VCMD
	call ParamsOrVCMD
	;Repeat
	jr .NextCommand2

.NoteOrRest
	;Check if track is 3 (music 4)
	ld a, [CurTrackCheck]
	cp 3
	;If so, then use special handler
	jp z, ProcNoteMusC4

	;Otherwise, load envelope on/off address value into HL
	ld hl, $09
	add hl, de
	;Check current command
	ld a, [bc]
	cp $C0
	;If less than C0, then is a note
	jr c, ProcNote

	;Otherwise, is a rest
	ld [hl], 0
	jp ProcNoteC4_2


;It is a note
ProcNote:
	;Set envelope on/off value to on
	ld [hl], $FF
	push bc
	push af
	;Check if track is SFX 4
	ld a, [CurTrackCheck]
	cp 7
	;If so, then perform special handler
	jr z, ProcNoteSFXCh4

	;Get octave
	ld hl, $1B
	add hl, de
	ld a, [hl]

	;Multiply to get proper octave offset
	add a
	add a
	ld b, a
	add a
	add b
	ld b, a

	;Now get note number
	pop af
	swap a
	and %00001111
	
	;Add to octave
	add b

	;And add transpose
	ld hl, $03
	add hl, de
	ld b, [hl]
	add b

	;Get frequency from table
	add a
	add LOW(FreqTab)
	ld c, a
	ld a, HIGH(FreqTab)
	adc 0
	ld b, a

	;Load frequency into RAM
	ld hl, $1D
	add hl, de
	ld a, [bc]
	ld [hl+], a
	inc bc
	ld a, [bc]
	ld [hl], a
	pop bc
	jr ProcNote2

ProcNoteSFXCh4:
	pop af
	pop bc

	;Get note from octave
	and %01110000
	ld hl, $1B
	add hl, de
	or [hl]
	swap a

	;OR with volume/duty value
	ld hl, $0C
	add hl, de
	or [hl]

	;Load frequency into RAM
	ld hl, $1D
	add hl, de
	ld [hl+], a
	xor a
	ld [hl], a

ProcNote2:
	;Reset note time
	ld hl, $08
	add hl, de
	xor a
	ld [hl], a

	;Get note length value
	ld a, [bc]
	and %00001111
	;Convert to actual note length with speed
	call ProcNoteLen

	;Set delay to result
	ld hl, $07
	add hl, de
	ld [hl], a

	;Get lower 4 bits
	push bc
	push af
	and %00001111
	ld b, a
	;Multiply with tertiary decay value
	ld hl, $13
	add hl, de
	ld a, [hl]
	swap a
	and %00001111
	push af
	call Multiply
	swap a
	and %00001111

	;Set envelope time to it
	ld hl, $0A
	add hl, de
	ld [hl], a
	pop af

	;Load original value and multiply more to get final decay value
	ld b, a
	pop af
	swap a
	and %00001111
	call Multiply
	add [hl]
	ld [hl], a
	pop bc
	
	;Reset vibrato step and envelope sequence position to FF
	ld hl, $16
	add hl, de

	ld a, $FF
	ld [hl+], a
	ld [hl+], a
	
	;Set envelope state to 0
	inc a
	ld [hl+], a

	;Reset vibrato to 0
	push hl
	ld hl, $1C
	add hl, de
	ld [hl], a

	;Also reset envelope length to 0
	ld hl, $0E
	add hl, de
	ld a, [hl]

	;Reset vibrato sequence delay to 0
	pop hl
	inc a
	ld [hl+], a

	;Set envelope duration to 1
	ld a, 1
	ld [hl], a

	;Check final volume
	ld hl, $05
	add hl, de
	ld a, [hl+]
	or a
	;If not 0, then don't change volume or delay
	jr nz, .ProcDelay3

	;Check if output volume is 3 (max)
	ld a, [hl]
	cp 3
	;If not, then don't change
	jr nz, .ProcDelay2

	;If so, then set to 1
	ld a, 1

;XOR and AND value to lowest 2 bits (for envelope)
.ProcDelay2
	xor %00000011

.ProcDelay3
	and %00000011
	ld [hl], a
	;Reset vibrato step and envelope sequence position to FF
	jr AdvChanPos

ProcNoteMusC4:
	;Get current note value from upper 4 bits of sequence byte
	ld a, [bc]
	swap a
	;If less than $0C, then use the value to play SFX as "percussion"
	and %00001111
	cp $0C
	call nz, CallSFX

ProcNoteC4_2:
	;Get length as lower 4 bits and process the note length
	ld a, [bc]
	and %00001111
	call ProcNoteLen

	;Set actual length as delay
	ld hl, $07
	add hl, de
	ld [hl], a

	;Also clear note time
	ld hl, $08
	add hl, de
	xor a
	ld [hl], a
	pop hl

;Advance channel position
AdvChanPos:
	ld hl, $20
	add hl, de
	inc bc
	ld [hl], c
	inc hl
	ld [hl], b
	ret


ProcNoteLen:
	;Check if note length is 0
	ld hl, $0B
	add hl, de
	or a
	;If so, then set to maximum speed value
	jr z, ProNoteLenMax

	push bc
	;Otherwise, check if less than speed
	cp [hl]
	;If not, then multiply
	jr nc, ProNoteLenMult3

	;Otherwise, multiply value
	ld c, a
	ld b, [hl]

ProNoteLenMult:
	xor a

ProNoteLenMult2:
	add b
	dec c
	jr nz, ProNoteLenMult2

	pop bc
	ret


ProNoteLenMult3:
	ld b, a
	ld c, [hl]
	jr ProNoteLenMult

ProNoteLenMax:
	;Set note length to max length of speed
	ld a, [hl]
	swap a
	and %11110000
	ret


; Unsigned 8-bit multiply: A = A(in) * C(in).
Multiply:
	;If operand A is 0, then return
	or a
	jr z, .MultiplyRet2

	push bc
	ld c, a
	ld a, b
	or a
	jr z, .MultiplyRet1

	cp c
	jr nc, .Multiply2

	ld b, c
	ld c, a
	jr ProNoteLenMult

.Multiply2
	ld b, a
	jr ProNoteLenMult

.MultiplyRet1
	pop bc

.MultiplyRet2
	ret


GetChPtr:
	;Get channel pointer
	ld hl, $20
	add hl, de
	ld c, [hl]
	inc hl
	ld b, [hl]
	ret


ParamsOrVCMD:
	;If Dx, is parameters
	cp $E0
	jr c, GetParams

	;Otherwise, is a VCMD - get pointer to jump to from table
	sub $E0
	add a
	add LOW(VCMDTab)
	ld l, a
	ld a, HIGH(VCMDTab)
	adc 0
	ld h, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	jp hl


GetParams:
	;Upper 4 bits of command is speed control
	ld hl, $0B
	add hl, de
	and %00001111
	ld [hl+], a
	
	;If current track is 2 or 6 (music/SFX 3, then perform special handler)
	ld a, [CurTrackCheck]
	and %00000011
	cp 2
	jr z, GetParams3

	;If current track is 7 (SFX 4, then perform special handler)
	inc bc
	ld a, [CurTrackCheck]
	cp 7
	jr z, GetParamsSFX4

	;Otherwise, next byte is duty/volume
	ld a, [bc]
	and %00110011
	add a
	add a
	ld [hl+], a

	;Next byte is decay
	inc bc
	ld a, [bc]
	ld [hl], a

	;Next byte is vibrato
	call EventVibrato
	;Final bytes are envelope and decay (if envelope is signed)
	jp GetEnvVal


GetParamsSFX4:
	;Check next byte - duty/volume
	ld a, [bc]
	;If 0, then 0, otherwise, 8
	or a
	jr z, .GetParamsSFX4_2

	ld a, 8

.GetParamsSFX4_2
	;Load parameter into RAM variable
	ld [hl+], a
	;Next byte is decay
	inc bc
	ld a, [bc]
	ld [hl], a
	;Final bytes are envelope (and decay if envelope is signed)
	jp EventEnvDecay


GetParams3:
	;Current byte is waveform
	call EventWaveform
	;Next byte is envelope value
	ld a, [bc]
	ld hl, $11
	add hl, de
	ld [hl+], a
	inc bc
	;Check if envelope is at max
	add a
	;If not, then set envelope sequence
	jp nc, GetEnvSeq

	;Otherwise, next byte is secondary decay
	inc hl
	ld a, [bc]
	ld [hl], a
	inc bc
	ret


VCMDTab:
	dw EventOctave			;E0
	dw EventOctave			;E1
	dw EventOctave			;E2
	dw EventOctave			;E3
	dw EventOctave			;E4
	dw EventOctave			;E5
	dw EventOctave			;E6
	dw EventOctave			;E7
	dw EventDutyVol			;E8
	dw EventDecay			;E9
	dw EventSweep			;EA
	dw EventVibrato			;EB
	dw EventTranspose		;EC
	dw EventWaveform		;ED
	dw EventEnvDecay		;EE
	dw EventTuning			;EF
	dw EventEnvVal			;F0
	dw EventDecay2			;F1
	dw EventDecay3			;F2
	dw EventFinalVol		;F3
	dw EventNop				;F4
	dw EventNop				;F5
	dw EventSpeed			;F6
	dw EventMacro1			;F7
	dw EventMacro2			;F8
	dw EventMacro1Ret		;F9
	dw EventMacro2Ret		;FA
	dw EventRepeat1Start	;FB
	dw EventRepeat2Start	;FC
	dw EventRepeat1End		;FD
	dw EventRepeat2End		;FE
	dw EventEnd				;FF

EventOctave:
;Set the current octave (0-7)
	;Get lower 3 bits of command byte
	ld a, [bc]
	and %00000111
	;Store as octave in RAM
	ld hl, $1B
	add hl, de
	jr StoreVal

EventDutyVol:
;Set duty/volume
;Parameters: xxxxxxxx (x = value)
	inc bc
	;If track is SFX 4, then perform separate handler
	ld a, [CurTrackCheck]
	cp 7
	jr z, .EventDutyVol_SFX4

	ld a, [bc]
	;Mask out bits and multiply to get final value
	and %00110011
	add a
	add a
	ld hl, $0C
	add hl, de
	jr StoreVal

.EventDutyVol_SFX4
	ld a, [bc]
	or a
	jr z, .EventDutyVol2

	ld a, 8

.EventDutyVol2
	;Store final value in RAM
	ld hl, $0C
	add hl, de
	jr StoreVal

EventDecay:
;Set decay
;Parameters: xxxxxxxx (x = value)
	ld hl, $0D
	add hl, de
	inc bc
	ld a, [bc]

StoreVal:
	ld [hl], a

EventNop:
;Do nothing but skip a byte
;Parameters: -------- (- = unused)
NextByte:
	inc bc
	ret


EventSweep:
;Set sweep
;Parameters: xxxxxxxx (x = value)
	;Load parameter in RAM
	ld hl, $02
	add hl, de
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret


EventVibrato:
;Set vibrato
;Parameters: xxxxxxxx (x = value)
	;First, get note envelope length from upper 4 bits
	inc bc
	ld a, [bc]
	swap a
	and %00001111
	call ProcNoteLen
	;Then, get vibrato
	ld hl, $0E
	add hl, de
	ld [hl+], a
	ld a, [bc]
	and %00001111
	push bc
	add a
	add LOW(VibTab)
	ld c, a
	ld a, HIGH(VibTab)
	adc 0
	ld b, a

StorePtr:
	;Store pointer into RAM
	ld a, [bc]
	ld [hl+], a
	inc bc
	ld a, [bc]
	ld [hl], a
	pop bc
	inc bc
	ret


EventTranspose:
;Set transpose (per-channel)
;Parameters: xxxxxxxx (x = value, signed)
	;Load parameter in RAM
	ld hl, $03
	add hl, de
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret


EventWaveform:
;Set waveform
;Parameters: xxxxxxxx (x = value)
	;Check current track and set its respective waveform
	ld a, [CurTrackCheck]
	cp 2
	jr z, .EventWaveform2

	cp 6
	;If neither channel 3 tracks, then do nothing
	jr nz, EventNop

	inc bc
	ld a, [bc]
	ld [WaveformSFX], a
	inc bc
	ret


.EventWaveform2
	inc bc
	ld a, [bc]
	ld [WaveformMus], a
	inc bc
	ret


EventEnvDecay:
;Set duty/volume and decay 2/3
;Parameters: xyyyyyyy (zzzzzzzz aaaaaaaa)  (x = if set, z and a are used, z = decay 2, a = decay 3)
	inc bc

GetEnvVal:
	;Get envelope value from byte
	ld a, [bc]
	ld hl, $11
	add hl, de
	ld [hl+], a
	;If signed, then get decay parameters from next 2 bytes
	add a
	jr c, GetDecay

GetEnvSeq:
	;Get envelope sequence number from parameter
	ld a, [bc]
	push bc
	;Get envelope sequence pointer from table
	add a
	add LOW(EnvSeqTab)
	ld c, a
	ld a, HIGH(EnvSeqTab)
	adc 0
	;Load pointer into RAM
	ld b, a
	ld hl, $14
	add hl, de
	jr StorePtr

;Get decay parameters
GetDecay:
	inc bc
	ld a, [bc]
	ld [hl+], a
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret


EventTuning:
;Set tuning
;Parameters: xxxxxxxx (x = relative pitch, signed)
	;Load parameter in RAM
	ld hl, $04
	add hl, de
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret


EventEnvVal:
;Set envelope value
;Parameters: xxxxxxxx (x = value)
	;Load parameter in RAM
	ld hl, $11
	add hl, de
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret


EventDecay2:
;Set secondary decay
;Parameters: xxxxxxxx (x = value)
	;Load parameter in RAM
	ld hl, $12
	add hl, de
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret


EventDecay3:
;Set tertiary decay
;Parameters: xxxxxxxx (x = value)
	;Load parameter in RAM
	ld hl, $13
	add hl, de
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret


EventFinalVol:
;Set final channel volume step
;Parameters: xxxxxxxx (x = value)
	;Load parameter in RAM
	ld hl, $05
	add hl, de
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret


EventSpeed:
;Set channel speed
;Parameters: xxxxxxxx (x = value)
	;Load parameter in RAM
	ld hl, $0B
	add hl, de
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	ret


EventMacro1:
;Go to macro (subroutine) (1)
;Parameters: xxxxxxxx xxxxxxxx (X = position, absolute)
;(NOTE: 1 level only)
	;Get pointer from 2 parameters
	inc bc
	ld a, [bc]
	ld l, a
	inc bc
	ld a, [bc]
	ld h, a
	inc bc
	
	;Load pointer into RAM
	push hl
	ld hl, $26
	add hl, de
	ld [hl], c
	inc hl
	ld [hl], b
	pop bc
	ret


EventMacro2:
;Go to macro (subroutine) (2)
;Parameters: xxxxxxxx xxxxxxxx (X = position, absolute)
;(NOTE: 1 level only)
	;Get pointer from 2 parameters
	inc bc
	ld a, [bc]
	ld l, a
	inc bc
	ld a, [bc]
	ld h, a
	inc bc
	
	;Load pointer into RAM
	push hl
	ld hl, $28
	add hl, de
	ld [hl], c
	inc hl
	ld [hl], b
	pop bc
	ret


EventMacro1Ret:
;Return from macro (subroutine) (1)
	;Go to position in RAM
	ld hl, $26
	add hl, de
	ld a, [hl+]
	ld b, [hl]
	ld c, a
	ret


EventMacro2Ret:
;Return from macro (subroutine) (2)
	;Go to position in RAM
	ld hl, $28
	add hl, de
	ld a, [hl+]
	ld b, [hl]
	ld c, a
	ret


EventRepeat1Start:
;Start repeat (1) after command
;(NOTE: 1 level only)
	;Load pointer in RAM
	inc bc
	ld hl, $22
	add hl, de
	ld a, c
	ld [hl+], a
	ld [hl], b

	;Set loop times to 0
	ld hl, $2A
	add hl, de
	ld [hl], 0
	ret


EventRepeat2Start:
;Start repeat (2) after command
;(NOTE: 1 level only)
	;Load pointer in RAM
	inc bc
	ld hl, $24
	add hl, de
	ld a, c
	ld [hl+], a
	ld [hl], b
	
	;Set loop times to 0
	ld hl, $2B
	add hl, de
	ld [hl], 0
	ret


EventRepeat1End:
;End of repeat (1) - jump to start
;Parameters: xxxxxxxx (x = times to repeat, 0 = infinite)
	;Check if times parameter is 0
	inc bc
	ld a, [bc]
	or a
	jr z, .EventRepeat1End_GoBack

	;Otherwise, get times currently repeated
	ld hl, $2A
	add hl, de
	push hl
	ld h, [hl]
	cp h
	pop hl
	;If done repeating, then continue ahead
	jr z, EventRepeatEnd_Ret

	;Otherwise, increase value and go to repeat start
	inc [hl]

;Go to repeat start
.EventRepeat1End_GoBack
	ld hl, $22
	add hl, de
	ld a, [hl+]
	ld c, a
	ld b, [hl]
	ret


;Reset repeat count and continue ahead
EventRepeatEnd_Ret:
	ld [hl], 0
	jp EventNop


EventRepeat2End:
;End of repeat (2) - jump to start
;Parameters: xxxxxxxx (x = times to repeat, 0 = infinite)
	;Check if times parameter is 0
	inc bc
	ld a, [bc]
	or a
	jr z, .EventRepeat2End_GoBack

	;Otherwise, get times currently repeated
	ld hl, $2B
	add hl, de
	push hl
	ld h, [hl]
	cp h
	pop hl
	;If done repeating, then continue ahead
	jr z, EventRepeatEnd_Ret

	;Otherwise, increase value and go to repeat start
	inc [hl]

;Go to repeat start
.EventRepeat2End_GoBack
	ld hl, $24
	add hl, de
	ld a, [hl+]
	ld c, a
	ld b, [hl]
	ret


EventEnd:
;End of track
	;Get channel mask and add to output
	ld a, [CurTrackCheck]
	add LOW(ChanMaskVals)
	ld c, a
	ld a, HIGH(ChanMaskVals)
	adc 0
	ld b, a
	ld a, [bc]
	ld h, a
	ld a, [Output]
	and h
	ld [Output], a
	xor a
	ld hl, $1D
	add hl, de
	ld [hl+], a
	ld [hl], a

	;If music 1, then set volume to 8
	ld a, [CurTrackCheck]
	jr z, .EventEnd_DecayVol8

	;Otherwise, if SFX channel 1, then reset sweep 
	cp 4
	jr z, .EventEnd_ResetSweep

	;If channel 4, then set decay and volume to 0
	and %00000011
	cp 3
	jr nz, .EventEnd_DecayVol0

.EventEnd_ResetSweep
	;Reset sweep
	ld a, %00001000
	ldh [rNR10], a
	ld [NR10Val], a

.EventEnd_DecayVol8
	ld a, $08
	jr .EventEnd_2

.EventEnd_DecayVol0
	xor a

.EventEnd_2
	;Set decay
	ld hl, $0D
	add hl, de
	ld [hl], a

	;Set current volume
	ld hl, $1F
	add hl, de
	ld [hl], a

	;Also clear music number and priority
	ld h, d
	ld l, e
	xor a
	ld [hl+], a
	ld [hl+], a
	
	;Reset sweep
	ld a, %00001000
	ld [hl], a

	;Set envelope on/off to off
	ld hl, $09
	add hl, de
	xor a
	ld [hl], a

	;Set note time to 8
	ld hl, $08
	add hl, de
	inc a
	ld [hl], a
	pop hl
	ret


ChanMaskVals:
	db $FE, $FD, $FB, $F7, $EF, $DF, $BF, $7F

TrackMaskVals:
	db $01, $02, $04, $08, $10, $20, $40, $80

ProcTrackRegVals:
	;Get pointer for track routine
	ld a, [CurTrackCheck]
	add a
	add $71
	ld l, a
	ld a, $74
	adc $00
	ld h, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	jp hl


PrepStates:
	dw MusC1Prep
	dw MusC2Prep
	dw MusC3Prep
	dw MusC4Prep
	dw SFXC1Prep
	dw SFXC2Prep
	dw SFXC3Prep
	dw SFXC4Prep

MusC1Prep:
	;Check if SFX is playing in channel 1
	ld hl, SFXC1MusNum
	ld a, [hl]
	or a
	;Return if so
	jr nz, MusPrepRet

;Otherwise, get duty/pan value from table
SFXC1Prep:
	ld hl, $06
	add hl, de
	ld a, [hl]
	and %00000011
	add LOW(Duty1PanTab)
	ld l, a
	ld a, HIGH(Duty1PanTab)
	adc 0
	ld h, a

	;Load into NR51 RAM value
	ld bc, NR51Val
	ld a, [bc]
	and %11101110
	or [hl]
	ld [bc], a

	;Load sweep into NR10 RAM value
	ld bc, NR10Val
	ld hl, $02
	add hl, de
	ld a, [hl]
	ld [bc], a

	;Get note time
	inc bc
	ld hl, $08
	add hl, de
	ld a, [hl]
	;If note time is 0, then skip
	or a
	jr z, MusC1Prep_2

	;Otherwise, set "gate off" value to 0
	ld hl, Gate1Off
	xor a
	ld [hl], a

	;Get duty/volume value
	ld hl, $0C
	add hl, de
	ld a, [hl]
	swap a
	jr MusC1Prep_3

MusC1Prep_2:
	;Set trigger bit on
	ld hl, NR14Val
	set 7, [hl]
	
	;Set "gate off" value
	ld hl, Gate1Off
	ld a, $FF
	ld [hl], a
	
	;Get duty/volume value
	ld hl, $0C
	add hl, de
	ld a, [hl]

MusC1Prep_3:
	;Set NR11 wave duty
	and %11000000
	ld [bc], a
	
	;Then check if envelope is on
	inc bc
	ld hl, $09
	add hl, de
	xor a
	or [hl]
	;If so, then get hardware volume
	jr nz, MusicC1Prep_4

	;If not, then use empty value
	ld a, %00001000
	jr MusC1Prep_5

MusicC1Prep_4:
	;Get hardware volume
	ld hl, $1F
	add hl, de
	ld a, [hl]

MusC1Prep_5:
	;Set NR12 value to it
	ld [bc], a
	inc bc

MusC1Prep_6:
	;Get tuning
	ld hl, $04
	add hl, de
	ld a, [hl]
	
	;And add to vibrato
	ld hl, $1C
	add hl, de
	add [hl]
	inc hl

	;Check if positive or negative
	bit 7, a
	jr nz, MusC1Prep_Neg

	;If positive, then add to frequency
	add [hl]
	inc hl
	;And set NR13 value to it
	ld [bc], a
	ld a, [hl]
	adc 0

MusC1Prep_7:
	;Set NR14 value
	inc bc
	and %00000111
	ld [bc], a

MusC4Prep:
	;Do nothing
MusPrepRet:
	ret


MusC1Prep_Neg:
	;If negative, then add negative to frequency
	add [hl]
	push af
	inc hl
	ld [bc], a
	pop af
	ld a, [hl]
	adc -1
	jr MusC1Prep_7

MusC2Prep:
	;Check if SFX is playing in channel 2
	ld hl, SFXC2MusNum
	ld a, [hl]
	or a
	jr nz, MusPrepRet

;Otherwise, get duty/pan value from table
SFXC2Prep:
	ld hl, $06
	add hl, de
	ld a, [hl]
	and %00000011
	add LOW(Duty2PanTab)
	ld l, a
	ld a, HIGH(Duty2PanTab)
	adc 0
	ld h, a

	;Load into NR51 RAM value
	ld bc, NR51Val
	ld a, [bc]
	and %11011101
	or [hl]
	ld [bc], a
	
	;Get note time
	ld bc, NR21Val
	ld hl, $08
	add hl, de
	ld a, [hl]
	;If note time is 0, then skip
	or a
	jr z, MusC2Prep_2

	;Otherwise, set "gate off" value to 0
	ld hl, Gate2Off
	xor a
	ld [hl], a
	
	;Get duty/volume value
	ld hl, $0C
	add hl, de
	ld a, [hl]
	swap a
	jr MusC1Prep_3

MusC2Prep_2:
	;Set trigger bit on
	ld hl, NR24Val
	set 7, [hl]
	
	;Set "gate off" val
	ld hl, Gate2Off
	ld a, $FF
	ld [hl], a
	
	;Get duty/volume value	
	ld hl, $0C
	add hl, de
	ld a, [hl]
	jp MusC1Prep_3

MusC3Prep:
	;Check if music is playing in SFX channel 3
	ld hl, SFXC3MusNum
	ld a, [hl]
	or a
	;Return if so
	jr nz, MusPrepRet

;Otherwise, get duty/pan value from table
SFXC3Prep:
	ld hl, $06
	add hl, de
	ld a, [hl]
	and %00000011
	add LOW(Duty3PanTab)
	ld l, a
	ld a, HIGH(Duty3PanTab)
	adc 0
	ld h, a
	
	;Load into NR51 RAM value
	ld bc, NR51Val
	ld a, [bc]
	and %10111011
	or [hl]
	ld [bc], a
	
	;Load "on" value into NR30 RAM value
	ld bc, NR30Val
	ld a, %10000000
	ld [bc], a
	inc bc
	inc bc
	
	;Then check if envelope is on
	ld hl, $09
	add hl, de
	xor a
	or [hl]
	;If not, then set NR33 to 0
	jr z, SFXC3Prep_2

	;Otherwise, get hardware volume
	ld hl, $1F
	add hl, de
	ld a, [hl]

	;Get volume from look-up table
	swap a
	and %00001111
	push bc
	add LOW(Vol3LUT)
	ld c, a
	ld a, HIGH(Vol3LUT)
	adc 0
	ld b, a
	ld a, [bc]
	pop bc

;Set NR33
SFXC3Prep_2:
	ld [bc], a
	inc bc
	jp MusC1Prep_6


SFXC4Prep:
	;Get duty/pan value from table
	ld hl, $06
	add hl, de
	ld a, [hl]
	and %00000011
	add LOW(Duty4PanTab)
	ld l, a
	ld a, HIGH(Duty4PanTab)
	adc 0
	ld h, a
	
	;Load into NR51 RAM value
	ld bc, NR51Val
	ld a, [bc]
	and %01110111
	or [hl]
	ld [bc], a

	;Get note time
	ld bc, NR42Val
	ld hl, $08
	add hl, de
	ld a, [hl]
	;If note time is 0, then skip
	or a
	jr z, SFXC4Prep_2

	;Otherwise, set "gate off" value to 0
	ld hl, Gate4Off
	xor a
	jr SFXC4Prep_3

SFXC4Prep_2:
	;Set trigger bit on
	ld hl, NR44Val
	set 7, [hl]
	ld hl, Gate4Off
	ld a, $FF

SFXC4Prep_3:
	;Check if envelope is on
	ld [hl], a
	ld hl, $09
	add hl, de
	xor a
	or [hl]
	;If so, then get hardware volume
	jr nz, SFXC4Prep_4

	;If not, then use empty value
	ld a, %00001000
	jr SFXC4Prep_5

SFXC4Prep_4:
	;Get hardware volume
	ld hl, $1F
	add hl, de
	ld a, [hl]

SFXC4Prep_5:
	;Set NR42 value to it
	ld [bc], a
	inc bc

	;Finally, load frequency into NR43-NR44
	ld hl, $1D
	add hl, de
	ld a, [hl+]
	ld [bc], a
	inc bc
	ld a, [hl]
	and %00000111
	ld [bc], a
	ret


Vol3LUT:
	db $00, $60, $40, $40
	db $40, $40, $40, $20
	db $20, $20, $20, $20
	db $20, $20, $20, $20
	
Duty1PanTab:
	db $11, $01, $10, $11
Duty2PanTab:
	db $22, $02, $20, $22
Duty3PanTab:
	db $44, $04, $40, $44
Duty4PanTab:
	db $88, $08, $80, $88

OutputRegs:
	;Copy all register values in RAM to actual values and set appropriately
	ld hl, NR10Val
	ld bc, NR10ValCopy
	ld de, rNR10
	call OutputReg_CheckCopySame
	call OutputReg_CheckCopyDiff
	push hl
	;Also use "gate off" values
	ld hl, Gate1Off
	ld a, [hl]
	pop hl
	push af
	call OutputRegCheck
	pop af
	call OutputReg_CheckOff
	call OutputRegWithTrig
	inc de
	call OutputReg_CheckCopyDiff
	push hl
	ld hl, Gate2Off
	ld a, [hl]
	pop hl
	call OutputRegCheck
	call OutputReg_CheckCopyDiff
	call OutputRegWithTrig
	call OutputReg_CheckCopyDiff
	call OutputReg_Ret
	call OutputReg_CheckCopyDiff
	call OutputReg_CheckCopyDiff
	call OutputRegWithTrig
	inc de
	call OutputReg_Ret
	push hl
	ld hl, Gate4Off
	ld a, [hl]
	pop hl
	call OutputRegCheck
	call OutputReg_CheckCopyDiff
	call OutputRegWithTrig
	
	;Compare NR50 value
	ld hl, rNR50
	ld a, [NR50Val]
	cp [hl]
	;If different, than copy RAM value into actual register
	jr z, OutputNR51

	ld [hl], a

OutputNR51:
	;Now compare NR51 value
	inc hl
	ld a, [NR51Val]
	cp [hl]
	;If different, than copy RAM value into actual register
	jr z, CheckC3Wave

	ld [hl], a

CheckC3Wave:
	;Check if SFX on channel 3 is playing
	inc hl
	ld a, [SFXC3MusNum]
	or a
	;If so, set SFX waveform
	jr nz, SetSFXWaveform

;Otherwise, set music waveform
SetMusWaveform:
	ld a, [WaveformMus]
	jr LoadWaveform

SetSFXWaveform:
	ld a, [WaveformSFX]

LoadWaveform:
	;If waveform is same, then skip
	ld hl, NewWave
	cp [hl]
	jr z, .LoadWaveform3

	;Otherwise, load new waveform - get pointer to waveform from table
	ld [hl], a
	add a
	add LOW(WaveTab)
	ld l, a
	ld a, HIGH(WaveTab)
	adc 0
	ld h, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	
	;Load all bytes of the waveform into wave RAM
	ld bc, WaveRAM
	xor a
	ldh [rNR30], a
	;4*4 = 16 bytes
	ld d, 4

.LoadWaveform2
	ld a, [hl+]
	ld [bc], a
	inc bc
	ld a, [hl+]
	ld [bc], a
	inc bc
	ld a, [hl+]
	ld [bc], a
	inc bc
	ld a, [hl+]
	ld [bc], a
	inc bc
	dec d
	jr nz, .LoadWaveform2

	;Turn on CH3 DAC
	ld a, %10000000
	ldh [rNR30], a

	;Set CH3 trigger bit on and clear other bits
	ld a, [NR34Val]
	or %10000000
	and %10000111
	ldh [rNR34], a

.LoadWaveform3
	ld hl, Gate1Off
	xor a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ret


OutputRegCheck:
	;Check "gate off" value
	or a
	;If gate off, get new value
	jr nz, OutputReg2

	;Otherwise, get copy value and compare to main register value
	ld a, [bc]
	cp [hl]
	;If same, then return
	jr z, OutputReg_Ret

;Otherwise, load to main register value and actual register 
OutputReg2:
	ld a, [hl+]
	ld [bc], a
	ld [de], a
	inc hl
	;Also set "trigger bit" of next value
	set 7, [hl]
	dec hl
	dec hl

OutputReg_Ret:
	inc hl
	inc bc
	inc de
	ret


OutputReg_CheckCopySame:
	;Check if copy and actual values are same
	ld a, [bc]
	cp [hl]
	;If not, then get new value
	jr nz, OutputReg_Call

	;Otherwise, check gate off value
	ld a, [Gate1Off]
	or a
	;If off, then return
	jr z, OutputReg_Ret

OutputReg_Call:
	jr OutputReg_NewVal

OutputReg_CheckOff:
	;Check if gate is off
	or a
	;If not, then new vlaue
	jr nz, OutputReg_NewVal

OutputReg_CheckCopyDiff:
	;Check if copy and actual values are same
	ld a, [bc]
	cp [hl]
	;If so, then return
	jr z, OutputReg_Ret

OutputReg_NewVal:
	ld a, [hl]
	ld [bc], a
	ld [de], a
	jr OutputReg_Ret

OutputRegWithTrig:
	;Check "trigger" bit of copy value
	ld a, [bc]
	bit 7, a
	;If set, then output new value
	jr nz, .OutputRegWithTrig2

	;Otherwise, check if main value is the same
	cp [hl]
	;If so, then return
	jr z, OutputReg_Ret

;Otherwise, output new value
.OutputRegWithTrig2
	ld a, [hl]
	ld [de], a
	and %01111111
	ld [bc], a
	jr OutputReg_Ret

;Initialize audio with no music/SFX
NoAudio:
	push bc
	push de
	call ClearCh1
	ld a, %01110111
	ld [NR50Val], a
	jr InitSoundRAM

;Initialize audio
InitSound:
	push bc
	push de
	call AudioOff
	ld a, %01110111
	ldh [rNR50], a
	ld [NR50Val], a

;Initialize RAM variables
InitSoundRAM:
	ld hl, MusC1MusNum
	ld de, TrackRAMSize
	ld a, 0
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	ld hl, MusC1NoteTime	;Set note time flag to 1
	ld a, 1
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	add hl, de
	ld [hl], a
	ld a, 0
	ld [Output], a			;Set output flag to 0
	ld [Fade], a			;Disable fade out routine
	ld [FadeTime], a
	ld a, $FF
	ld [NewWave], a			;Set (new) waveform value
	pop de
	pop bc
	ret


AudioOff:
	;Turn off audio
	xor a
	ldh [rNR50], a
	ld a, %10000000
	ldh [rNR52], a

ClearCh1:
	;Reset NR10 (sweep)
	ld a, %00001000
	ldh [rNR10], a
	ld [NR10Val], a
	;Check if channel is on
	ldh a, [rNR52]
	bit 0, a
	;If not, then skip
	jr z, ClearCh2

	xor a
	;Clear NR11-NR14
	ldh [rNR11], a
	ld [NR11Val], a
	ld a, $08
	ldh [rNR12], a
	ld [NR12Val], a
	xor a
	ldh [rNR13], a
	ld [NR13Val], a
	ld [NR14Val], a
	;Set trigger bit
	ld a, %10000000
	ldh [rNR14], a
	xor a

ClearCh2:
	;Check if channel is on
	ldh a, [rNR52]
	bit 1, a
	;If not, then skip
	jr z, ClearCh3

	xor a
	;Clear NR21-NR24
	ldh [rNR21], a
	ld [NR21Val], a
	ldh [rNR22], a
	ld [NR22Val], a
	ldh [rNR23], a
	ld [NR23Val], a
	ld [NR24Val], a
	;Set trigger bit
	ld a, %10000000
	ldh [rNR24], a

ClearCh3:
	;Check if channel is on
	ldh a, [rNR52]
	bit 2, a
	;If not, then skip
	jr z, ClearCh4

	xor a
	;Clear NR32 and NR34
	ldh [rNR32], a
	ld [NR32Val], a
	ld [NR34Val], a
	;Set trigger bit
	ld a, %10000000
	ldh [rNR34], a

ClearCh4:
	;Check if channel is on
	ldh a, [rNR52]
	bit 3, a
	;If not, then return
	jr z, AudioOffRet

	xor a
	;Clear NR41-NR14
	ldh [rNR41], a
	ld [NR41Val], a
	ld a, %00001000
	ldh [rNR42], a
	ld [NR42Val], a
	xor a
	ldh [rNR43], a
	ld [NR43Val], a
	ld [NR44Val], a
	;Set trigger bit
	ld a, %10000000
	ldh [rNR44], a

AudioOffRet:
	ret

SECTION "Audio RAM", WRAM0[AudioRAM]

CurTrack: ds 1			;$C302
CurTrackCheck: ds 1		;$C303
SFXNum: ds 1			;$C304
Temp1: ds 1				;$C305
Temp2: ds 1				;$C306
Output: ds 1			;$C307
WaveformMus: ds 1		;$C308
WaveformSFX: ds 1		;$C309
NewWave: ds 1			;$C30A
Fade: ds 1				;$C30B
FadeTime: ds 1			;$C30C

;Music channel 1 RAM
MusC1MusNum: ds 1		;$C30D = $00
MusC1Priority: ds 1		;$C30E = $01
MusC1Sweep: ds 1		;$C30F = $02
MusC1Transpose: ds 1	;$C310 = $03
MusC1Tuning: ds 1		;$C311 = $04
MusC1VolFinal: ds 1		;$C312 = $05
MusC1VolOutput: ds 1	;$C313 = $06
MusC1NoteDelay: ds 1	;$C314 = $07
MusC1NoteTime: ds 1		;$C315 = $08
MusC1EnvOn: ds 1		;$C316 = $09
MusC1EnvTime: ds 1		;$C317 = $0A
MusC1Speed: ds 1		;$C318 = $0B
MusC1DutyVol: ds 1		;$C319 = $0C
MusC1Decay: ds 1		;$C31A = $0D
MusC1EnvLen: ds 1		;$C31B = $0E
MusC1Vibrato: ds 2		;$C31C = $0F
MusC1EnvVal: ds 1		;$C31E = $11
MusC1Decay2: ds 1		;$C31F = $12
MusC1Decay3: ds 1		;$C320 = $13
MusC1EnvSeqPtr: ds 2	;$C321 = $14
MusC1VibStep: ds 1		;$C322 = $16
MusC1EnvSeqPos: ds 1	;$C323 = $17
MusC1EnvStep: ds 1		;$C325 = $18
MusC1VibSeqDelay: ds 1	;$C326 = $19
MusC1EnvDur: ds 1		;$C327 = $1A
MusC1Octave: ds 1		;$C328 = $1B
MusC1VibVal: ds 1		;$C329 = $1C
MusC1Freq: ds 2			;$C32A = $1D
MusC1VolCur: ds 1		;$C32C = $1F
MusC1SongPos: ds 2		;$C32D = $20
MusC1Repeat1Start: ds 2	;$C32F = $22
MusC1Repeat2Start: ds 2	;$C331 = $24
MusC1Macro1Pos: ds 2	;$C333 = $26
MusC1Macro2Pos: ds 2	;$C335 = $28
MusC1Repeat1Times: ds 1	;$C337 = $2A
MusC1Repeat2Times: ds 1	;$C338 = $2B

;Music channel 2 RAM
MusC2MusNum: ds 1		;$C339 = $00
MusC2Priority: ds 1		;$C33A = $01
MusC2Sweep: ds 1		;$C33B = $02
MusC2Transpose: ds 1	;$C33C = $03
MusC2Tuning: ds 1		;$C33D = $04
MusC2VolFinal: ds 1		;$C33E = $05
MusC2VolOutput: ds 1	;$C33F = $06
MusC2NoteDelay: ds 1	;$C340 = $07
MusC2NoteTime: ds 1		;$C341 = $08
MusC2EnvOn: ds 1		;$C342 = $09
MusC2EnvTime: ds 1		;$C343 = $0A
MusC2Speed: ds 1		;$C344 = $0B
MusC2DutyVol: ds 1		;$C345 = $0C
MusC2Decay: ds 1		;$C346 = $0D
MusC2EnvLen: ds 1		;$C347 = $0E
MusC2Vibrato: ds 2		;$C348 = $0F
MusC2EnvVal: ds 1		;$C34A = $11
MusC2Decay2: ds 1		;$C34B = $12
MusC2Decay3: ds 1		;$C34C = $13
MusC2EnvSeqPtr: ds 2	;$C34D = $14
MusC2VibStep: ds 1		;$C34F = $16
MusC2EnvSeqPos: ds 1	;$C350 = $17
MusC2EnvStep: ds 1		;$C351 = $18
MusC2VibSeqDelay: ds 1	;$C352 = $19
MusC2EnvDur: ds 1		;$C353 = $1A
MusC2Octave: ds 1		;$C354 = $1B
MusC2VibVal: ds 1		;$C355 = $1C
MusC2Freq: ds 2			;$C356 = $1D
MusC2VolCur: ds 1		;$C358 = $1F
MusC2SongPos: ds 2		;$C359 = $20
MusC2Repeat1Start: ds 2	;$C35B = $22
MusC2Repeat2Start: ds 2	;$C35D = $24
MusC2Macro1Pos: ds 2	;$C35F = $26
MusC2Macro2Pos: ds 2	;$C361 = $28
MusC2Repeat1Times: ds 1	;$C363 = $2A
MusC2Repeat2Times: ds 1	;$C364 = $2B

;Music channel 3 RAM
MusC3MusNum: ds 1		;$C365 = $00
MusC3Priority: ds 1		;$C366 = $01
MusC3Sweep: ds 1		;$C367 = $02
MusC3Transpose: ds 1	;$C368 = $03
MusC3Tuning: ds 1		;$C369 = $04
MusC3VolFinal: ds 1		;$C36A = $05
MusC3VolOutput: ds 1	;$C36B = $06
MusC3NoteDelay: ds 1	;$C36C = $07
MusC3NoteTime: ds 1		;$C36D = $08
MusC3EnvOn: ds 1		;$C36E = $09
MusC3EnvTime: ds 1		;$C36F = $0A
MusC3Speed: ds 1		;$C370 = $0B
MusC3DutyVol: ds 1		;$C371 = $0C
MusC3Decay: ds 1		;$C372 = $0D
MusC3EnvLen: ds 1		;$C373 = $0E
MusC3Vibrato: ds 2		;$C374 = $0F
MusC3EnvVal: ds 1		;$C376 = $11
MusC3Decay2: ds 1		;$C377 = $12
MusC3Decay3: ds 1		;$C378 = $13
MusC3EnvSeqPtr: ds 2	;$C379 = $14
MusC3VibStep: ds 1		;$C37B = $16
MusC3EnvSeqPos: ds 1	;$C37C = $17
MusC3EnvStep: ds 1		;$C37D = $18
MusC3VibSeqDelay: ds 1	;$C37E = $19
MusC3EnvDur: ds 1		;$C37F = $1A
MusC3Octave: ds 1		;$C380 = $1B
MusC3VibVal: ds 1		;$C381 = $1C
MusC3Freq: ds 2			;$C382 = $1D
MusC3VolCur: ds 1		;$C384 = $1F
MusC3SongPos: ds 2		;$C385 = $20
MusC3Repeat1Start: ds 2	;$C387 = $22
MusC3Repeat2Start: ds 2	;$C389 = $24
MusC3Macro1Pos: ds 2	;$C38B = $26
MusC3Macro2Pos: ds 2	;$C38D = $28
MusC3Repeat1Times: ds 1	;$C38F = $2A
MusC3Repeat2Times: ds 1	;$C390 = $2B

;Music channel 4 RAM
MusC4MusNum: ds 1		;$C391 = $00
MusC4Priority: ds 1		;$C392 = $01
MusC4Sweep: ds 1		;$C393 = $02
MusC4Transpose: ds 1	;$C394 = $03
MusC4Tuning: ds 1		;$C395 = $04
MusC4VolFinal: ds 1		;$C396 = $05
MusC4VolOutput: ds 1	;$C397 = $06
MusC4NoteDelay: ds 1	;$C398 = $07
MusC4NoteTime: ds 1		;$C399 = $08
MusC4EnvOn: ds 1		;$C39A = $09
MusC4EnvTime: ds 1		;$C39B = $0A
MusC4Speed: ds 1		;$C39C = $0B
MusC4DutyVol: ds 1		;$C39D = $0C
MusC4Decay: ds 1		;$C39E = $0D
MusC4EnvLen: ds 1		;$C39F = $0E
MusC4Vibrato: ds 2		;$C3A0 = $0F
MusC4EnvVal: ds 1		;$C3A2 = $11
MusC4Decay2: ds 1		;$C3A3 = $12
MusC4Decay3: ds 1		;$C3A4 = $13
MusC4EnvSeqPtr: ds 2	;$C3A5 = $14
MusC4VibStep: ds 1		;$C3A7 = $16
MusC4EnvSeqPos: ds 1	;$C3A8 = $17
MusC4EnvStep: ds 1		;$C3A9 = $18
MusC4VibSeqDelay: ds 1	;$C3AA = $19
MusC4EnvDur: ds 1		;$C3AB = $1A
MusC4Octave: ds 1		;$C3AC = $1B
MusC4VibVal: ds 1		;$C3AD = $1C
MusC4Freq: ds 2			;$C3AE = $1D
MusC4VolCur: ds 1		;$C3B0 = $1F
MusC4SongPos: ds 2		;$C3B1 = $20
MusC4Repeat1Start: ds 2	;$C3B3 = $22
MusC4Repeat2Start: ds 2	;$C3B5 = $24
MusC4Macro1Pos: ds 2	;$C3B7 = $26
MusC4Macro2Pos: ds 2	;$C3B9 = $28
MusC4Repeat1Times: ds 1	;$C3BB = $2A
MusC4Repeat2Times: ds 1	;$C3BC = $2B

;SFX channel 1 RAM
SFXC1MusNum: ds 1		;$C3BD = $00
SFXC1Priority: ds 1		;$C3BE = $01
SFXC1Sweep: ds 1		;$C3BF = $02
SFXC1Transpose: ds 1	;$C3C0 = $03
SFXC1Tuning: ds 1		;$C3C1 = $04
SFXC1VolFinal: ds 1		;$C3C2 = $05
SFXC1VolOutput: ds 1	;$C3C3 = $06
SFXC1NoteDelay: ds 1	;$C3C4 = $07
SFXC1NoteTime: ds 1		;$C3C5 = $08
SFXC1EnvOn: ds 1		;$C3C6 = $09
SFXC1EnvTime: ds 1		;$C3C7 = $0A
SFXC1Speed: ds 1		;$C3C8 = $0B
SFXC1DutyVol: ds 1		;$C3C9 = $0C
SFXC1Decay: ds 1		;$C3CA = $0D
SFXC1EnvLen: ds 1		;$C3CB = $0E
SFXC1Vibrato: ds 2		;$C3CC = $0F
SFXC1EnvVal: ds 1		;$C3CE = $11
SFXC1Decay2: ds 1		;$C3CF = $12
SFXC1Decay3: ds 1		;$C3D0 = $13
SFXC1EnvSeqPtr: ds 2	;$C3D1 = $14
SFXC1VibStep: ds 1		;$C3D2 = $16
SFXC1EnvSeqPos: ds 1	;$C3D3 = $17
SFXC1EnvStep: ds 1		;$C3D5 = $18
SFXC1VibSeqDelay: ds 1	;$C3D6 = $19
SFXC1EnvDur: ds 1		;$C3D7 = $1A
SFXC1Octave: ds 1		;$C3D8 = $1B
SFXC1VibVal: ds 1		;$C3D9 = $1C
SFXC1Freq: ds 2			;$C3DA = $1D
SFXC1VolCur: ds 1		;$C3DC = $1F
SFXC1SongPos: ds 2		;$C3DD = $20
SFXC1Repeat1Start: ds 2	;$C3DF = $22
SFXC1Repeat2Start: ds 2	;$C3E1 = $24
SFXC1Macro1Pos: ds 2	;$C3E3 = $26
SFXC1Macro2Pos: ds 2	;$C3E5 = $28
SFXC1Repeat1Times: ds 1	;$C3E7 = $2A
SFXC1Repeat2Times: ds 1	;$C3E8 = $2B

;SFX channel 2 RAM
SFXC2MusNum: ds 1		;$C3E9 = $00
SFXC2Priority: ds 1		;$C3EA = $01
SFXC2Sweep: ds 1		;$C3EB = $02
SFXC2Transpose: ds 1	;$C3EC = $03
SFXC2Tuning: ds 1		;$C3ED = $04
SFXC2VolFinal: ds 1		;$C3EE = $05
SFXC2VolOutput: ds 1	;$C3EF = $06
SFXC2NoteDelay: ds 1	;$C3F0 = $07
SFXC2NoteTime: ds 1		;$C3F1 = $08
SFXC2EnvOn: ds 1		;$C3F2 = $09
SFXC2EnvTime: ds 1		;$C3F3 = $0A
SFXC2Speed: ds 1		;$C3F4 = $0B
SFXC2DutyVol: ds 1		;$C3F5 = $0C
SFXC2Decay: ds 1		;$C3F6 = $0D
SFXC2EnvLen: ds 1		;$C3F7 = $0E
SFXC2Vibrato: ds 2		;$C3F8 = $0F
SFXC2EnvVal: ds 1		;$C3FA = $11
SFXC2Decay2: ds 1		;$C3FB = $12
SFXC2Decay3: ds 1		;$C3FC = $13
SFXC2EnvSeqPtr: ds 2	;$C3FD = $14
SFXC2VibStep: ds 1		;$C3FF = $16
SFXC2EnvSeqPos: ds 1	;%DC00 = $17
SFXC2EnvStep: ds 1		;$C401 = $18
SFXC2VibSeqDelay: ds 1	;$C402 = $19
SFXC2EnvDur: ds 1		;$C403 = $1A
SFXC2Octave: ds 1		;$C404 = $1B
SFXC2VibVal: ds 1		;$C405 = $1C
SFXC2Freq: ds 2			;$C406 = $1D
SFXC2VolCur: ds 1		;$C408 = $1F
SFXC2SongPos: ds 2		;$C409 = $20
SFXC2Repeat1Start: ds 2	;$C40B = $22
SFXC2Repeat2Start: ds 2	;$C40D = $24
SFXC2Macro1Pos: ds 2	;$C40F = $26
SFXC2Macro2Pos: ds 2	;$C411 = $28
SFXC2Repeat1Times: ds 1	;$C413 = $2A
SFXC2Repeat2Times: ds 1	;$C414 = $2B

;SFX channel 3 RAM
SFXC3MusNum: ds 1		;$C415 = $00
SFXC3Priority: ds 1		;$C416 = $01
SFXC3Sweep: ds 1		;$C417 = $02
SFXC3Transpose: ds 1	;$C418 = $03
SFXC3Tuning: ds 1		;$C419 = $04
SFXC3VolFinal: ds 1		;$C41A = $05
SFXC3VolOutput: ds 1	;$C41B = $06
SFXC3NoteDelay: ds 1	;$C41C = $07
SFXC3NoteTime: ds 1		;$C41D = $08
SFXC3EnvOn: ds 1		;$C41E = $09
SFXC3EnvTime: ds 1		;$C41F = $0A
SFXC3Speed: ds 1		;$C420 = $0B
SFXC3DutyVol: ds 1		;$C421 = $0C
SFXC3Decay: ds 1		;$C422 = $0D
SFXC3EnvLen: ds 1		;$C423 = $0E
SFXC3Vibrato: ds 2		;$C424 = $0F
SFXC3EnvVal: ds 1		;$C426 = $11
SFXC3Decay2: ds 1		;$C427 = $12
SFXC3Decay3: ds 1		;$C428 = $13
SFXC3EnvSeqPtr: ds 2	;$C429 = $14
SFXC3VibStep: ds 1		;$C42B = $16
SFXC3EnvSeqPos: ds 1	;$C42C = $17
SFXC3EnvStep: ds 1		;$C42D = $18
SFXC3VibSeqDelay: ds 1	;$C42E = $19
SFXC3EnvDur: ds 1		;$C42F = $1A
SFXC3Octave: ds 1		;$C430 = $1B
SFXC3VibVal: ds 1		;$C431 = $1C
SFXC3Freq: ds 2			;$C432 = $1D
SFXC3VolCur: ds 1		;$C434 = $1F
SFXC3SongPos: ds 2		;$C435 = $20
SFXC3Repeat1Start: ds 2	;$C437 = $22
SFXC3Repeat2Start: ds 2	;$C439 = $24
SFXC3Macro1Pos: ds 2	;$C43B = $26
SFXC3Macro2Pos: ds 2	;$C43D = $28
SFXC3Repeat1Times: ds 1	;$C43F = $2A
SFXC3Repeat2Times: ds 1	;$C440 = $2B

;SFX channel 4 RAM
SFXC4MusNum: ds 1		;$C441 = $00
SFXC4Priority: ds 1		;$C442 = $01
SFXC4Sweep: ds 1		;$C443 = $02
SFXC4Transpose: ds 1	;$C444 = $03
SFXC4Tuning: ds 1		;$C445 = $04
SFXC4VolFinal: ds 1		;$C446 = $05
SFXC4VolOutput: ds 1	;$C447 = $06
SFXC4NoteDelay: ds 1	;$C448 = $07
SFXC4NoteTime: ds 1		;$C449 = $08
SFXC4EnvOn: ds 1		;$C44A = $09
SFXC4EnvTime: ds 1		;$C44B = $0A
SFXC4Speed: ds 1		;$C44C = $0B
SFXC4DutyVol: ds 1		;$C44D = $0C
SFXC4Decay: ds 1		;$C44E = $0D
SFXC4EnvLen: ds 1		;$C44F = $0E
SFXC4Vibrato: ds 2		;$C450 = $0F
SFXC4EnvVal: ds 1		;$C452 = $11
SFXC4Decay2: ds 1		;$C453 = $12
SFXC4Decay3: ds 1		;$C454 = $13
SFXC4EnvSeqPtr: ds 2	;$C455 = $14
SFXC4VibStep: ds 1		;$C457 = $16
SFXC4EnvSeqPos: ds 1	;$C458 = $17
SFXC4EnvStep: ds 1		;$C459 = $18
SFXC4VibSeqDelay: ds 1	;$C45A = $19
SFXC4EnvDur: ds 1		;$C45B = $1A
SFXC4Octave: ds 1		;$C45C = $1B
SFXC4VibVal: ds 1		;$C45D = $1C
SFXC4Freq: ds 2			;$C45E = $1D
SFXC4VolCur: ds 1		;$C460 = $1F
SFXC4SongPos: ds 2		;$C461 = $20
SFXC4Repeat1Start: ds 2	;$C463 = $22
SFXC4Repeat2Start: ds 2	;$C465 = $24
SFXC4Macro1Pos: ds 2	;$C467 = $26
SFXC4Macro2Pos: ds 2	;$C469 = $28
SFXC4Repeat1Times: ds 1	;$C46B = $2A
SFXC4Repeat2Times: ds 1	;$C46C = $2B

NR10Val: ds 1			;$C46D
NR11Val: ds 1			;$C46E
NR12Val: ds 1			;$C46F
NR13Val: ds 1			;$C470
NR14Val: ds 1			;$C471
NR21Val: ds 1			;$C472
NR22Val: ds 1			;$C473
NR23Val: ds 1			;$C474
NR24Val: ds 1			;$C475
NR30Val: ds 1			;$C476
NR31Val: ds 1			;$C477
NR32Val: ds 1			;$C478
NR33Val: ds 1			;$C479
NR34Val: ds 1			;$C47A
NR41Val: ds 1			;$C47B
NR42Val: ds 1			;$C47C
NR43Val: ds 1			;$C47D
NR44Val: ds 1			;$C47E
NR50Val: ds 1			;$C47F
NR51Val: ds 1			;$C480
NR52Val: ds 1			;$C481

NR10ValCopy: ds 1		;$C482
NR11ValCopy: ds 1		;$C483
NR12ValCopy: ds 1		;$C484
NR13ValCopy: ds 1		;$C485
NR14ValCopy: ds 1		;$C486
NR21ValCopy: ds 1		;$C487
NR22ValCopy: ds 1		;$C488
NR23ValCopy: ds 1		;$C489
NR24ValCopy: ds 1		;$C48A
NR30ValCopy: ds 1		;$C48B
NR31ValCopy: ds 1		;$C48C
NR32ValCopy: ds 1		;$C48D
NR33ValCopy: ds 1		;$C48E
NR34ValCopy: ds 1		;$C48F
NR41ValCopy: ds 1		;$C490
NR42ValCopy: ds 1		;$C491
NR43ValCopy: ds 1		;$C492
NR44ValCopy: ds 1		;$C493
NR50ValCopy: ds 1		;$C494
NR51ValCopy: ds 1		;$C495
NR52ValCopy: ds 1		;$C496

Gate1Off: ds 1			;$C497
Gate2Off: ds 1			;$C498
Gate3Off: ds 1			;$C499
Gate4Off: ds 1			;$C49A