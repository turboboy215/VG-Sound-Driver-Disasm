; =============================================================================
; Mega Man Xtreme 2 (GBC) - sound bank 2
; Driver: the same source as Mega Man Xtreme (MMX_SoundDriver.inc, from
; ../MegaManXtreme, assemble with -I ../MegaManXtreme). Only the data header
; at $4B40 differs (id count $7D, instruments $4C3F, waves $4E17).
; Byte-exact for 2:$4000-$7EF7 (the rest of the bank is $00).
; =============================================================================

DEF NUM_SOUND_IDS EQU $7D
INCLUDE "MMX_Sound.inc"

SECTION "MMX2 Sound bank 2", ROMX[$4000], BANK[2]

INCLUDE "MMX_SoundDriver.inc"

SndPointerTable:
	db $00, $00                             ; $00
	BEPTR Music01                           ; $01
	BEPTR Music02                           ; $02
	BEPTR Music03                           ; $03
	BEPTR Music04                           ; $04
	BEPTR Music05                           ; $05
	BEPTR Music06                           ; $06
	BEPTR Music07                           ; $07
	db $00, $00                             ; $08
	db $00, $00                             ; $09
	db $00, $00                             ; $0A
	db $00, $00                             ; $0B
	db $00, $00                             ; $0C
	db $00, $00                             ; $0D
	db $00, $00                             ; $0E
	db $00, $00                             ; $0F
	db $00, $00                             ; $10
	db $00, $00                             ; $11
	db $00, $00                             ; $12
	db $00, $00                             ; $13
	db $00, $00                             ; $14
	db $00, $00                             ; $15
	db $00, $00                             ; $16
	db $00, $00                             ; $17
	db $00, $00                             ; $18
	db $00, $00                             ; $19
	db $00, $00                             ; $1A
	db $00, $00                             ; $1B
	db $00, $00                             ; $1C
	db $00, $00                             ; $1D
	db $00, $00                             ; $1E
	db $00, $00                             ; $1F
	BEPTR Sfx20                             ; $20
	BEPTR Sfx21                             ; $21
	BEPTR Sfx22                             ; $22
	BEPTR Sfx23                             ; $23
	BEPTR Sfx24                             ; $24
	BEPTR Sfx25                             ; $25
	BEPTR Sfx26                             ; $26
	BEPTR Sfx27                             ; $27
	BEPTR Sfx28                             ; $28
	BEPTR Sfx29                             ; $29
	BEPTR Sfx2A                             ; $2A
	BEPTR Sfx2B                             ; $2B
	BEPTR Sfx2C                             ; $2C
	BEPTR Sfx2D                             ; $2D
	BEPTR Sfx2E                             ; $2E
	BEPTR Sfx2F                             ; $2F
	BEPTR Sfx30                             ; $30
	BEPTR Sfx31                             ; $31
	BEPTR Sfx32                             ; $32
	BEPTR Sfx33                             ; $33
	BEPTR Sfx34                             ; $34
	BEPTR Sfx35                             ; $35
	BEPTR Sfx36                             ; $36
	BEPTR Sfx37                             ; $37
	BEPTR Sfx38                             ; $38
	BEPTR Sfx39                             ; $39
	BEPTR Sfx3A                             ; $3A
	BEPTR Sfx3B                             ; $3B
	BEPTR Sfx3C                             ; $3C
	BEPTR Sfx3D                             ; $3D
	BEPTR Sfx3E                             ; $3E
	BEPTR Sfx3F                             ; $3F
	BEPTR Sfx40                             ; $40
	BEPTR Sfx41                             ; $41
	BEPTR Sfx42                             ; $42
	BEPTR Sfx43                             ; $43
	BEPTR Sfx44                             ; $44
	BEPTR Sfx45                             ; $45
	BEPTR Sfx46                             ; $46
	BEPTR Sfx47                             ; $47
	BEPTR Sfx48                             ; $48
	BEPTR Sfx49                             ; $49
	BEPTR Sfx4A                             ; $4A
	BEPTR Sfx4B                             ; $4B
	BEPTR Sfx4C                             ; $4C
	BEPTR Sfx4D                             ; $4D
	BEPTR Sfx4E                             ; $4E
	BEPTR Sfx4F                             ; $4F
	BEPTR Sfx50                             ; $50
	BEPTR Sfx51                             ; $51
	BEPTR Sfx52                             ; $52
	BEPTR Sfx53                             ; $53
	BEPTR Sfx54                             ; $54
	BEPTR Sfx55                             ; $55
	BEPTR Sfx56                             ; $56
	BEPTR Sfx57                             ; $57
	BEPTR Sfx58                             ; $58
	BEPTR Sfx59                             ; $59
	BEPTR Sfx5A                             ; $5A
	BEPTR Sfx5B                             ; $5B
	BEPTR Sfx5C                             ; $5C
	BEPTR Sfx5D                             ; $5D
	BEPTR Sfx5E                             ; $5E
	BEPTR Sfx5F                             ; $5F
	BEPTR Sfx60                             ; $60
	BEPTR Sfx61                             ; $61
	BEPTR Sfx62                             ; $62
	BEPTR Sfx63                             ; $63
	BEPTR Sfx64                             ; $64
	BEPTR Sfx65                             ; $65
	BEPTR Sfx66                             ; $66
	BEPTR Sfx67                             ; $67
	BEPTR Sfx68                             ; $68
	BEPTR Sfx69                             ; $69
	BEPTR Sfx6A                             ; $6A
	BEPTR Sfx6B                             ; $6B
	BEPTR Sfx6C                             ; $6C
	BEPTR Sfx6D                             ; $6D
	BEPTR Sfx6E                             ; $6E
	BEPTR Sfx6F                             ; $6F
	BEPTR Sfx70                             ; $70
	BEPTR Sfx71                             ; $71
	BEPTR Sfx72                             ; $72
	BEPTR Sfx73                             ; $73
	BEPTR Sfx74                             ; $74
	BEPTR Sfx75                             ; $75
	BEPTR Sfx76                             ; $76
	BEPTR Sfx77                             ; $77
	BEPTR Sfx78                             ; $78
	BEPTR Sfx79                             ; $79
	BEPTR Sfx7A                             ; $7A
	BEPTR Sfx7B                             ; $7B
	BEPTR Sfx7C                             ; $7C

;; Instruments (8 bytes): attack, decay, sustain, release, vibrato speed,
;; vibrato depth, duty/noise bits, wave (CH3, 1-based)
SoundInstruments:
	INSTRUMENT $1F, $08, $C0, $07, $80, $00, $00, 0  ; 0
	INSTRUMENT $00, $04, $90, $07, $00, $00, $00, 1  ; 1
	INSTRUMENT $1F, $08, $C0, $07, $50, $06, $00, 0  ; 2
	INSTRUMENT $1F, $00, $E0, $07, $E4, $04, $00, 0  ; 3
	INSTRUMENT $1F, $08, $40, $07, $00, $00, $00, 0  ; 4
	INSTRUMENT $1F, $08, $70, $07, $00, $00, $08, 0  ; 5
	INSTRUMENT $1F, $00, $90, $07, $00, $00, $00, 0  ; 6
	INSTRUMENT $1F, $08, $C0, $01, $64, $07, $00, 0  ; 7
	INSTRUMENT $1F, $00, $70, $03, $00, $00, $00, 0  ; 8
	INSTRUMENT $03, $08, $F0, $06, $64, $06, $00, 2  ; 9
	INSTRUMENT $1D, $08, $C0, $07, $00, $00, $00, 0  ; 10
	INSTRUMENT $1F, $08, $D0, $07, $00, $00, $00, 0  ; 11
	INSTRUMENT $1F, $05, $D0, $05, $00, $00, $00, 3  ; 12
	INSTRUMENT $1F, $00, $E0, $04, $64, $04, $08, 0  ; 13
	INSTRUMENT $1F, $00, $C0, $05, $00, $00, $00, 0  ; 14
	INSTRUMENT $00, $00, $00, $00, $00, $00, $00, 0  ; 15
	INSTRUMENT $00, $00, $00, $00, $00, $00, $00, 0  ; 16
	INSTRUMENT $00, $00, $00, $00, $00, $00, $00, 0  ; 17
	INSTRUMENT $00, $00, $00, $00, $00, $00, $00, 0  ; 18
	INSTRUMENT $00, $00, $00, $00, $00, $00, $00, 0  ; 19
	INSTRUMENT $00, $00, $00, $00, $00, $00, $00, 0  ; 20
	INSTRUMENT $00, $00, $00, $00, $80, $00, $00, 0  ; 21
	INSTRUMENT $00, $00, $00, $00, $80, $00, $00, 0  ; 22
	INSTRUMENT $00, $00, $00, $00, $00, $00, $00, 0  ; 23
	INSTRUMENT $00, $00, $00, $00, $80, $00, $00, 0  ; 24
	INSTRUMENT $00, $00, $00, $00, $00, $00, $00, 0  ; 25
	INSTRUMENT $00, $00, $00, $00, $00, $00, $00, 0  ; 26
	INSTRUMENT $00, $00, $00, $00, $00, $00, $00, 0  ; 27
	INSTRUMENT $00, $00, $00, $00, $00, $00, $00, 0  ; 28
	INSTRUMENT $00, $00, $00, $00, $00, $00, $00, 0  ; 29
	INSTRUMENT $00, $00, $00, $00, $00, $00, $00, 0  ; 30
	INSTRUMENT $00, $00, $00, $00, $00, $00, $00, 0  ; 31
	INSTRUMENT $1F, $08, $F0, $08, $D4, $56, $00, 4  ; 32
	INSTRUMENT $1F, $08, $90, $05, $00, $00, $00, 0  ; 33
	INSTRUMENT $19, $00, $E0, $07, $FF, $04, $00, 0  ; 34
	INSTRUMENT $00, $00, $00, $00, $00, $00, $00, 0  ; 35
	INSTRUMENT $00, $00, $00, $00, $00, $00, $00, 0  ; 36
	INSTRUMENT $1F, $08, $F0, $04, $00, $00, $00, 0  ; 37
	INSTRUMENT $1D, $00, $A0, $05, $00, $00, $00, 0  ; 38
	INSTRUMENT $1F, $00, $C0, $05, $00, $00, $00, 0  ; 39
	INSTRUMENT $1D, $08, $F0, $06, $FF, $07, $00, 0  ; 40
	INSTRUMENT $1D, $08, $F0, $06, $FF, $7F, $08, 0  ; 41
	INSTRUMENT $1F, $05, $D0, $04, $7F, $7F, $00, 5  ; 42
	INSTRUMENT $1F, $08, $F0, $08, $86, $28, $00, 6  ; 43
	INSTRUMENT $16, $08, $F0, $01, $00, $00, $00, 0  ; 44
	INSTRUMENT $1F, $07, $80, $02, $00, $00, $00, 0  ; 45
	INSTRUMENT $1F, $07, $80, $07, $A8, $7F, $00, 7  ; 46
	INSTRUMENT $1F, $07, $50, $07, $B8, $14, $00, 0  ; 47
	INSTRUMENT $1F, $00, $F0, $00, $01, $0A, $00, 8  ; 48
	INSTRUMENT $1F, $05, $D0, $04, $88, $51, $08, 0  ; 49
	INSTRUMENT $1F, $08, $F0, $05, $46, $43, $00, 9  ; 50
	INSTRUMENT $1F, $08, $F0, $08, $00, $00, $00, 10  ; 51
	INSTRUMENT $1F, $07, $60, $05, $00, $00, $00, 0  ; 52
	INSTRUMENT $1F, $07, $50, $07, $00, $00, $00, 0  ; 53
	INSTRUMENT $1F, $07, $A0, $07, $00, $00, $00, 0  ; 54
	INSTRUMENT $1C, $08, $F0, $08, $BF, $3C, $00, 0  ; 55
	INSTRUMENT $1F, $07, $A0, $05, $00, $00, $00, 0  ; 56
	INSTRUMENT $1F, $07, $80, $07, $A8, $7F, $00, 0  ; 57
	INSTRUMENT $1F, $05, $A0, $04, $80, $00, $00, 0  ; 58

;; CH3 waves (16 bytes each)
SoundWaves:
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00 ; wave 1
	db $8A, $CD, $EE, $DB, $85, $21, $01, $25, $8A, $CD, $ED, $CA, $74, $11, $01, $25 ; wave 2
	db $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; wave 3
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00 ; wave 4
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; wave 5
	db $FF, $EE, $DD, $CC, $BB, $AA, $99, $88, $77, $66, $55, $44, $33, $22, $11, $00 ; wave 6
	db $AC, $EF, $FF, $FD, $A7, $43, $23, $47, $AC, $EF, $FF, $EC, $96, $33, $23, $47 ; wave 7
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; wave 8
	db $9D, $D9, $99, $55, $8C, $C8, $88, $44, $7B, $B7, $77, $33, $6A, $A6, $66, $22 ; wave 9
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00 ; wave 10

;; Music $01
Music01:
	db $00
	BEPTR Music01_Ch1
	BEPTR Music01_Ch2
	BEPTR Music01_Ch3
	BEPTR Music01_Ch4
Music01_Ch1:
	FLAGS $48
	TEMPO $0266
	OCTAVE 0
	HOLD 255
	DUTY $40
.l4ECB:
	FLAGS $48
	INSTR 0
	VOLUME $0D
	DOTTED
	NOTE N2, 10       ; A_4
	INSTR 2
	DOTTED
	CONNECT
	NOTE N8, 10       ; A_4
	VOLUME $07
	NOTE N16, 10      ; A_4
	INSTR 0
	VOLUME $0D
	DOTTED
	CONNECT
	NOTE N2, 12       ; B_4
	INSTR 2
	DOTTED
	CONNECT
	NOTE N8, 12       ; B_4
	VOLUME $07
	NOTE N16, 12      ; B_4
	INSTR 0
	VOLUME $0D
	DOTTED
	CONNECT
	NOTE N2, 13       ; C_5
	INSTR 2
	DOTTED
	CONNECT
	NOTE N8, 13       ; C_5
	VOLUME $07
	NOTE N16, 13      ; C_5
	INSTR 0
	VOLUME $0D
	DOTTED
	CONNECT
	NOTE N2, 15       ; D_5
	INSTR 2
	DOTTED
	CONNECT
	NOTE N8, 15       ; D_5
	VOLUME $07
	NOTE N16, 15      ; D_5
	LOOP1 1, .l4ECB
	INSTR 0
.l4F0E:
	FLAGS $08
	VOLUME $0D
	NOTE N8, 17       ; E_5
	VOLUME $06
	NOTE N8, 17       ; E_5
	VOLUME $03
	NOTE N8, 17       ; E_5
	VOLUME $0D
	NOTE N8, 17       ; E_5
	VOLUME $06
	NOTE N8, 17       ; E_5
	VOLUME $03
	NOTE N8, 17       ; E_5
	VOLUME $0D
	NOTE N8, 17       ; E_5
	VOLUME $06
	NOTE N8, 17       ; E_5
	LOOP1 1, .l4F0E
	SLIDE 127
	DUTY $80
	VOLUME $0F
	NOTE N8, 18       ; F_5
	SLIDE 0
	NOTE N8, 17       ; E_5
	NOTE N8, 13       ; C_5
	DOTTED
	NOTE N4, 8        ; G_4
	NOTE N8, 13       ; C_5
	CONNECT
	NOTE N8, 10       ; A_4
	CONNECT
	NOTE N8, 10       ; A_4
	NOTE N8, 8        ; G_4
	NOTE N8, 6        ; F_4
	NOTE N4, 5        ; E_4
	NOTE N8, 8        ; G_4
	NOTE N8, 6        ; F_4
	NOTE N8, 1        ; C_4
	NOTE N8, 11       ; A#4
	OCTUP
	NOTE N8, 23       ; A#3
	NOTE N8, 30       ; F_4
	NOTE N8, 23       ; A#3
	NOTE N8, 23       ; A#3
	NOTE N8, 30       ; F_4
	NOTE N8, 23       ; A#3
	NOTE N8, 18       ; F_3
	OCTUP
	NOTE N8, 8        ; G_4
	NOTE N8, 1        ; C_4
	NOTE N8, 5        ; E_4
	NOTE N8, 1        ; C_4
	NOTE N8, 13       ; C_5
	NOTE N8, 8        ; G_4
	NOTE N8, 5        ; E_4
	NOTE N8, 1        ; C_4
	DOTTED
	CONNECT
	NOTE N4, 6        ; F_4
	INSTR 2
	CONNECT
	NOTE N8, 6        ; F_4
	INSTR 0
	VOLUME $07
	NOTE N8, 6        ; F_4
	VOLUME $0F
	NOTE N8, 5        ; E_4
	NOTE N8, 6        ; F_4
	NOTE N8, 8        ; G_4
	DOTTED
	CONNECT
	NOTE N4, 10       ; A_4
	INSTR 2
	CONNECT
	NOTE N8, 10       ; A_4
	INSTR 0
	VOLUME $07
	NOTE N8, 10       ; A_4
	VOLUME $0F
	NOTE N8, 8        ; G_4
	NOTE N8, 10       ; A_4
	NOTE N8, 11       ; A#4
	DOTTED
	CONNECT
	NOTE N2, 13       ; C_5
	INSTR 2
	CONNECT
	NOTE N4, 13       ; C_5
	INSTR 0
	VOLUME $07
	NOTE N8, 13       ; C_5
	VOLUME $0F
	SLIDE 127
	DOTTED
	NOTE N4, 17       ; E_5
	SLIDE 0
	NOTE N8, 13       ; C_5
	VOLUME $07
	NOTE N8, 13       ; C_5
	VOLUME $0F
	NOTE N8, 5        ; E_4
	VOLUME $07
	NOTE N8, 5        ; E_4
	TRANSP 12
	DUTY $00
	VOLUME $0B
	NOTE N8, 5        ; E_4
	VOLUME $06
	NOTE N8, 5        ; E_4
	VOLUME $03
	NOTE N8, 5        ; E_4
	VOLUME $0B
	NOTE N8, 5        ; E_4
	VOLUME $06
	NOTE N8, 5        ; E_4
	VOLUME $03
	NOTE N8, 5        ; E_4
	VOLUME $0B
	NOTE N8, 5        ; E_4
	VOLUME $06
	NOTE N8, 5        ; E_4
	VOLUME $0B
	NOTE N8, 5        ; E_4
	VOLUME $06
	NOTE N8, 5        ; E_4
	VOLUME $03
	NOTE N8, 5        ; E_4
	VOLUME $0B
	NOTE N8, 5        ; E_4
	VOLUME $06
	NOTE N8, 5        ; E_4
	TRANSP 0
	VOLUME $00
	NOTE N8, 1        ; C_4
	DUTY $80
	VOLUME $0F
	SLIDE 127
	NOTE N8, 3        ; D_4
	SLIDE 0
	NOTE N8, 5        ; E_4
	DOTTED
	CONNECT
	NOTE N4, 6        ; F_4
	INSTR 2
	CONNECT
	NOTE N8, 6        ; F_4
	INSTR 0
	VOLUME $07
	NOTE N8, 6        ; F_4
	VOLUME $0F
	SLIDE 127
	NOTE N4, 8        ; G_4
	SLIDE 0
	NOTE N8, 6        ; F_4
	NOTE N4, 5        ; E_4
	NOTE N8, 3        ; D_4
	DOTTED
	CONNECT
	NOTE N4, 1        ; C_4
	INSTR 2
	CONNECT
	NOTE N8, 1        ; C_4
	INSTR 0
	VOLUME $07
	NOTE N8, 1        ; C_4
	TRANSP 12
	DUTY $00
	VOLUME $0B
	NOTE N8, 5        ; E_4
	VOLUME $06
	NOTE N8, 5        ; E_4
	VOLUME $03
	NOTE N8, 5        ; E_4
	VOLUME $0B
	NOTE N8, 5        ; E_4
	VOLUME $06
	NOTE N8, 5        ; E_4
	VOLUME $03
	NOTE N8, 5        ; E_4
	VOLUME $0B
	NOTE N8, 5        ; E_4
	VOLUME $06
	NOTE N8, 5        ; E_4
	VOLUME $0B
	NOTE N8, 5        ; E_4
	VOLUME $06
	NOTE N8, 5        ; E_4
	VOLUME $03
	NOTE N8, 5        ; E_4
	VOLUME $0B
	NOTE N8, 5        ; E_4
	VOLUME $06
	NOTE N8, 5        ; E_4
	TRANSP 0
	VOLUME $00
	NOTE N8, 1        ; C_4
	DUTY $80
	SLIDE 127
	VOLUME $0F
	NOTE N8, 3        ; D_4
	SLIDE 0
	NOTE N8, 5        ; E_4
	DOTTED
	CONNECT
	NOTE N4, 6        ; F_4
	INSTR 2
	CONNECT
	NOTE N8, 6        ; F_4
	INSTR 0
	VOLUME $07
	NOTE N8, 6        ; F_4
	SLIDE 127
	VOLUME $0F
	NOTE N4, 8        ; G_4
	SLIDE 0
	NOTE N8, 10       ; A_4
	NOTE N4, 8        ; G_4
	NOTE N8, 6        ; F_4
	NOTE N4, 5        ; E_4
	SLIDE 127
	NOTE N8, 6        ; F_4
	SLIDE 0
	NOTE N8, 5        ; E_4
	NOTE N8, 1        ; C_4
	DOTTED
	CONNECT
	NOTE N2, 10       ; A_4
	INSTR 2
	NOTE N4, 10       ; A_4
	DOTTED
	CONNECT
	NOTE N4, 10       ; A_4
	INSTR 0
	VOLUME $07
	NOTE N8, 10       ; A_4
	DUTY $00
	VOLUME $0D
	NOTE N8, 6        ; F_4
	VOLUME $06
	NOTE N8, 6        ; F_4
	VOLUME $0D
	NOTE N8, 8        ; G_4
	VOLUME $06
	NOTE N8, 8        ; G_4
	JUMP Music01_Ch1
	END                ; unreachable
Music01_Ch2:
	FLAGS $48
	TEMPO $0266
	OCTAVE 0
	HOLD 255
	DUTY $40
	TRANSP -12
.l5077:
	FLAGS $48
	INSTR 0
	VOLUME $0D
	DOTTED
	NOTE N2, 15       ; D_5
	INSTR 2
	DOTTED
	CONNECT
	NOTE N8, 15       ; D_5
	VOLUME $07
	NOTE N16, 15      ; D_5
	INSTR 0
	VOLUME $0D
	DOTTED
	CONNECT
	NOTE N2, 17       ; E_5
	INSTR 2
	DOTTED
	CONNECT
	NOTE N8, 17       ; E_5
	VOLUME $07
	NOTE N16, 17      ; E_5
	INSTR 0
	VOLUME $0D
	DOTTED
	CONNECT
	NOTE N2, 18       ; F_5
	INSTR 2
	DOTTED
	CONNECT
	NOTE N8, 18       ; F_5
	VOLUME $07
	NOTE N16, 18      ; F_5
	INSTR 0
	VOLUME $0D
	DOTTED
	CONNECT
	NOTE N2, 20       ; G_5
	INSTR 2
	DOTTED
	CONNECT
	NOTE N8, 20       ; G_5
	VOLUME $07
	NOTE N16, 20      ; G_5
	LOOP1 1, .l5077
	INSTR 0
.l50BA:
	FLAGS $08
	VOLUME $0D
	NOTE N8, 22       ; A_5
	VOLUME $06
	NOTE N8, 22       ; A_5
	VOLUME $03
	NOTE N8, 22       ; A_5
	VOLUME $0D
	NOTE N8, 22       ; A_5
	VOLUME $06
	NOTE N8, 22       ; A_5
	VOLUME $03
	NOTE N8, 22       ; A_5
	VOLUME $0D
	NOTE N8, 22       ; A_5
	VOLUME $06
	NOTE N8, 22       ; A_5
	LOOP1 1, .l50BA
	TRANSP 0
	VOLUME $00
	DOTTED
	NOTE N8, 17       ; E_5
	SLIDE 127
	DETUNE 1
	DUTY $80
	PAN $10
	VOLUME $0A
	NOTE N8, 18       ; F_5
	SLIDE 0
	NOTE N8, 17       ; E_5
	NOTE N8, 13       ; C_5
	DOTTED
	NOTE N4, 8        ; G_4
	NOTE N8, 13       ; C_5
	CONNECT
	NOTE N8, 10       ; A_4
	CONNECT
	NOTE N8, 10       ; A_4
	NOTE N8, 8        ; G_4
	NOTE N8, 6        ; F_4
	NOTE N4, 5        ; E_4
	NOTE N8, 8        ; G_4
	NOTE N8, 6        ; F_4
	NOTE N8, 1        ; C_4
	NOTE N8, 11       ; A#4
	OCTUP
	NOTE N8, 23       ; A#3
	NOTE N8, 30       ; F_4
	NOTE N8, 23       ; A#3
	NOTE N8, 23       ; A#3
	NOTE N8, 30       ; F_4
	NOTE N8, 23       ; A#3
	NOTE N8, 18       ; F_3
	OCTUP
	NOTE N8, 8        ; G_4
	NOTE N8, 1        ; C_4
	NOTE N8, 5        ; E_4
	NOTE N8, 1        ; C_4
	NOTE N8, 13       ; C_5
	NOTE N8, 8        ; G_4
	NOTE N16, 5       ; E_4
	HOLD 100
	DUTY $40
	DETUNE 0
	PAN $11
	VOLUME $0C
	NOTE N8, 3        ; D_4
	NOTE N8, 6        ; F_4
	NOTE N8, 13       ; C_5
	NOTE N8, 3        ; D_4
	NOTE N8, 6        ; F_4
	NOTE N8, 13       ; C_5
	NOTE N8, 3        ; D_4
	NOTE N8, 13       ; C_5
	NOTE N8, 5        ; E_4
	NOTE N8, 6        ; F_4
	NOTE N8, 13       ; C_5
	NOTE N8, 5        ; E_4
	NOTE N8, 6        ; F_4
	NOTE N8, 13       ; C_5
	NOTE N8, 5        ; E_4
	NOTE N8, 13       ; C_5
	NOTE N8, 3        ; D_4
	NOTE N8, 6        ; F_4
	NOTE N8, 11       ; A#4
	NOTE N8, 3        ; D_4
	NOTE N8, 6        ; F_4
	NOTE N8, 11       ; A#4
	NOTE N8, 3        ; D_4
	NOTE N8, 11       ; A#4
	NOTE N8, 5        ; E_4
	NOTE N8, 6        ; F_4
	NOTE N8, 10       ; A_4
	NOTE N8, 5        ; E_4
	NOTE N8, 6        ; F_4
	NOTE N8, 13       ; C_5
	NOTE N8, 5        ; E_4
	NOTE N8, 6        ; F_4
	HOLD 255
	TRANSP -12
	TRANSP 0
	DUTY $00
	NOTE N8, 10       ; A_4
	VOLUME $06
	NOTE N8, 10       ; A_4
	VOLUME $03
	NOTE N8, 10       ; A_4
	VOLUME $0C
	NOTE N8, 10       ; A_4
	VOLUME $06
	NOTE N8, 10       ; A_4
	VOLUME $03
	NOTE N8, 10       ; A_4
	VOLUME $0C
	NOTE N8, 10       ; A_4
	VOLUME $06
	NOTE N8, 10       ; A_4
	VOLUME $0C
	NOTE N8, 10       ; A_4
	VOLUME $06
	NOTE N8, 10       ; A_4
	VOLUME $03
	NOTE N8, 10       ; A_4
	VOLUME $0C
	NOTE N8, 10       ; A_4
	VOLUME $06
	NOTE N8, 10       ; A_4
	VOLUME $00
	NOTE N8, 4        ; D#4
	DUTY $80
	SLIDE 127
	VOLUME $0C
	NOTE N8, 6        ; F_4
	SLIDE 0
	NOTE N8, 8        ; G_4
	DOTTED
	CONNECT
	NOTE N4, 11       ; A#4
	INSTR 2
	CONNECT
	NOTE N8, 11       ; A#4
	INSTR 0
	VOLUME $06
	NOTE N8, 11       ; A#4
	VOLUME $0C
	NOTE N8, 13       ; C_5
	VOLUME $06
	NOTE N8, 13       ; C_5
	VOLUME $0C
	NOTE N8, 11       ; A#4
	NOTE N4, 13       ; C_5
	NOTE N8, 11       ; A#4
	NOTE N8, 8        ; G_4
	VOLUME $06
	NOTE N8, 8        ; G_4
	VOLUME $0C
	NOTE N8, 8        ; G_4
	VOLUME $06
	NOTE N8, 8        ; G_4
	VOLUME $0C
	NOTE N8, 8        ; G_4
	DUTY $00
	NOTE N8, 10       ; A_4
	VOLUME $06
	NOTE N8, 10       ; A_4
	VOLUME $03
	NOTE N8, 10       ; A_4
	VOLUME $0C
	NOTE N8, 10       ; A_4
	VOLUME $06
	NOTE N8, 10       ; A_4
	VOLUME $03
	NOTE N8, 10       ; A_4
	VOLUME $0C
	NOTE N8, 10       ; A_4
	VOLUME $06
	NOTE N8, 10       ; A_4
	VOLUME $0C
	NOTE N8, 10       ; A_4
	VOLUME $06
	NOTE N8, 10       ; A_4
	VOLUME $03
	NOTE N8, 10       ; A_4
	VOLUME $0C
	NOTE N8, 10       ; A_4
	VOLUME $06
	NOTE N8, 10       ; A_4
	VOLUME $00
	NOTE N8, 4        ; D#4
	DUTY $40
	DUTY $80
	VOLUME $0C
	SLIDE 127
	NOTE N8, 6        ; F_4
	SLIDE 0
	NOTE N8, 8        ; G_4
	DOTTED
	CONNECT
	NOTE N4, 11       ; A#4
	INSTR 2
	CONNECT
	NOTE N8, 11       ; A#4
	INSTR 0
	VOLUME $06
	NOTE N8, 11       ; A#4
	VOLUME $0C
	NOTE N8, 13       ; C_5
	VOLUME $06
	NOTE N8, 13       ; C_5
	VOLUME $0C
	NOTE N8, 15       ; D_5
	DOTTED
	CONNECT
	NOTE N4, 13       ; C_5
	INSTR 2
	CONNECT
	NOTE N8, 13       ; C_5
	VOLUME $06
	INSTR 0
	NOTE N8, 13       ; C_5
	VOLUME $0C
	NOTE N8, 13       ; C_5
	VOLUME $06
	NOTE N8, 13       ; C_5
	VOLUME $0C
	NOTE N8, 8        ; G_4
	DOTTED
	CONNECT
	NOTE N2, 15       ; D_5
	INSTR 2
	NOTE N4, 15       ; D_5
	DOTTED
	CONNECT
	NOTE N4, 15       ; D_5
	INSTR 0
	VOLUME $06
	NOTE N8, 15       ; D_5
	DUTY $00
	VOLUME $0C
	NOTE N8, 11       ; A#4
	VOLUME $06
	NOTE N8, 11       ; A#4
	VOLUME $0C
	NOTE N8, 13       ; C_5
	VOLUME $06
	NOTE N8, 13       ; C_5
	JUMP Music01_Ch2
	END                ; unreachable
Music01_Ch3:
	FLAGS $00
	TEMPO $0266
	INSTR 1
	OCTAVE 1
	HOLD 230
.l521E:
	FLAGS $00
	VOLUME $03
	NOTE N16, 3       ; D_3
	VOLUME $02
	NOTE N16, 3       ; D_3
	VOLUME $03
	NOTE N16, 3       ; D_3
	VOLUME $02
	NOTE N16, 3       ; D_3
	VOLUME $03
	OCTUP
	NOTE N16, 15      ; D_6
	VOLUME $02
	NOTE N16, 15      ; D_6
	VOLUME $03
	NOTE N16, 3       ; D_5
	VOLUME $02
	NOTE N16, 3       ; D_5
	VOLUME $03
	NOTE N16, 10      ; A_5
	VOLUME $02
	NOTE N16, 10      ; A_5
	VOLUME $03
	OCTUP
	NOTE N8, 3        ; D_3
	NOTE N16, 27      ; D_5
	VOLUME $02
	NOTE N16, 27      ; D_5
	VOLUME $03
	OCTUP
	NOTE N16, 10      ; A_5
	VOLUME $02
	NOTE N16, 10      ; A_5
	LOOP1 7, .l521E
	OCTAVE 2
	HOLD 200
	VOLUME $03
	OCTUP
	NOTE N8, 15       ; D_5
	NOTE N8, 3        ; D_4
	NOTE N8, 3        ; D_4
	NOTE N8, 15       ; D_5
	NOTE N8, 3        ; D_4
	NOTE N8, 3        ; D_4
	NOTE N8, 15       ; D_5
	NOTE N8, 3        ; D_4
	NOTE N8, 15       ; D_5
	NOTE N8, 3        ; D_4
	NOTE N8, 3        ; D_4
	NOTE N8, 15       ; D_5
	NOTE N8, 3        ; D_4
	NOTE N8, 15       ; D_5
	NOTE N8, 10       ; A_4
	NOTE N8, 3        ; D_4
.l5269:
	FLAGS $00
	NOTE N8, 3        ; D_4
	NOTE N32, 3       ; D_4
	REST N32
	NOTE N16, 3       ; D_4
	LOOP1 3, .l5269
.l5273:
	FLAGS $00
	NOTE N8, 1        ; C_4
	NOTE N32, 1       ; C_4
	REST N32
	NOTE N16, 1       ; C_4
	LOOP1 3, .l5273
	OCTAVE 0
.l527F:
	FLAGS $00
	NOTE N8, 23       ; A#3
	NOTE N32, 23      ; A#3
	REST N32
	NOTE N16, 23      ; A#3
	LOOP1 3, .l527F
.l5289:
	FLAGS $00
	NOTE N8, 25       ; C_4
	NOTE N32, 25      ; C_4
	REST N32
	NOTE N16, 25      ; C_4
	LOOP1 2, .l5289
	NOTE N8, 29       ; E_4
	NOTE N32, 29      ; E_4
	REST N32
	NOTE N16, 29      ; E_4
	OCTAVE 2
.l5299:
	FLAGS $00
	NOTE N8, 3        ; D_4
	NOTE N32, 3       ; D_4
	REST N32
	NOTE N16, 3       ; D_4
	LOOP1 3, .l5299
.l52A3:
	FLAGS $00
	NOTE N8, 1        ; C_4
	NOTE N32, 1       ; C_4
	REST N32
	NOTE N16, 1       ; C_4
	LOOP1 3, .l52A3
	OCTAVE 0
.l52AF:
	FLAGS $00
	NOTE N8, 23       ; A#3
	NOTE N32, 23      ; A#3
	REST N32
	NOTE N16, 23      ; A#3
	LOOP1 3, .l52AF
.l52B9:
	FLAGS $00
	NOTE N8, 25       ; C_4
	NOTE N32, 25      ; C_4
	REST N32
	NOTE N16, 25      ; C_4
	LOOP1 3, .l52B9
	TRANSP -12
	OCTUP
	NOTE N8, 15       ; D_5
	NOTE N8, 3        ; D_4
	NOTE N8, 3        ; D_4
	NOTE N8, 15       ; D_5
	NOTE N8, 3        ; D_4
	NOTE N8, 3        ; D_4
	NOTE N8, 15       ; D_5
	NOTE N8, 3        ; D_4
	NOTE N8, 15       ; D_5
	NOTE N8, 3        ; D_4
	NOTE N8, 3        ; D_4
	NOTE N8, 15       ; D_5
	NOTE N8, 3        ; D_4
	NOTE N8, 3        ; D_4
	NOTE N8, 15       ; D_5
	NOTE N8, 13       ; C_5
	TRANSP 0
.l52D8:
	FLAGS $00
	NOTE N8, 23       ; A#3
	NOTE N32, 23      ; A#3
	REST N32
	NOTE N16, 23      ; A#3
	LOOP1 3, .l52D8
.l52E2:
	FLAGS $00
	NOTE N8, 25       ; C_4
	NOTE N32, 25      ; C_4
	REST N32
	NOTE N16, 25      ; C_4
	LOOP1 3, .l52E2
.l52EC:
	FLAGS $00
.l52EE:
	FLAGS $00
	NOTE N8, 27       ; D_4
	NOTE N32, 27      ; D_4
	REST N32
	NOTE N16, 27      ; D_4
	LOOP1 1, .l52EE
	NOTE N16, 27      ; D_4
	REST N16
	NOTE N4, 27       ; D_4
	NOTE N8, 27       ; D_4
	LOOP2 1, .l52EC
.l5300:
	FLAGS $00
	NOTE N8, 23       ; A#3
	NOTE N32, 23      ; A#3
	REST N32
	NOTE N16, 23      ; A#3
	LOOP1 3, .l5300
.l530A:
	FLAGS $00
	NOTE N8, 25       ; C_4
	NOTE N32, 25      ; C_4
	REST N32
	NOTE N16, 25      ; C_4
	LOOP1 3, .l530A
.l5314:
	FLAGS $00
	NOTE N8, 27       ; D_4
	NOTE N32, 27      ; D_4
	REST N32
	NOTE N16, 27      ; D_4
	LOOP1 1, .l5314
	NOTE N16, 27      ; D_4
	REST N16
	NOTE N4, 27       ; D_4
	NOTE N8, 27       ; D_4
	NOTE N8, 27       ; D_4
	NOTE N32, 27      ; D_4
	REST N32
	NOTE N16, 27      ; D_4
	NOTE N8, 27       ; D_4
	NOTE N32, 27      ; D_4
	REST N32
	NOTE N16, 27      ; D_4
	NOTE N8, 23       ; A#3
	NOTE N32, 23      ; A#3
	REST N32
	NOTE N16, 23      ; A#3
	NOTE N8, 25       ; C_4
	NOTE N32, 25      ; C_4
	REST N32
	NOTE N16, 25      ; C_4
	JUMP Music01_Ch3
	END                ; unreachable
Music01_Ch4:
	FLAGS $00
	TEMPO $0266
	OCTAVE 0
	HOLD 100
.l533F:
	FLAGS $00
	VOLUME $0F
	INSTR 8
	NOTE N8, 12
	REST N8
	DOTTED
	REST N2
	LOOP1 3, .l533F
.l534D:
	FLAGS $00
	INSTR 8
	NOTE N8, 12
	REST N8
	REST N2
	INSTR 6
	NOTE N32, 10
	REST N32
	NOTE N32, 10
	REST N32
	REST N8
	LOOP1 2, .l534D
	INSTR 8
	NOTE N8, 12
	DOTTED
	REST N4
	HOLD 255
	INSTR 6
	VOLUME $07
	NOTE N32, 10
	REST N32
	VOLUME $08
	NOTE N32, 10
	REST N32
	VOLUME $09
	NOTE N32, 10
	REST N32
	VOLUME $0A
	NOTE N32, 10
	REST N32
	VOLUME $0B
	NOTE N32, 10
	REST N32
	VOLUME $0C
	NOTE N32, 10
	REST N32
	VOLUME $0D
	NOTE N32, 10
	REST N32
	VOLUME $0E
	NOTE N32, 10
	REST N32
.l5388:
	FLAGS $00
	HOLD 255
	VOLUME $0F
	NOTE N32, 10
	REST N32
	HOLD 100
	VOLUME $0A
	NOTE N32, 10
	REST N32
	VOLUME $0D
	NOTE N32, 10
	REST N32
	VOLUME $0A
	NOTE N32, 10
	REST N32
	VOLUME $0D
	NOTE N32, 10
	REST N32
	VOLUME $0A
	NOTE N32, 10
	REST N32
	HOLD 255
	VOLUME $0F
	NOTE N32, 10
	REST N32
	HOLD 100
	VOLUME $0A
	NOTE N32, 10
	REST N32
	VOLUME $0D
	NOTE N32, 10
	REST N32
	VOLUME $0A
	NOTE N32, 10
	REST N32
	VOLUME $0D
	NOTE N32, 10
	REST N32
	VOLUME $0A
	NOTE N32, 10
	REST N32
	HOLD 255
	VOLUME $0F
	NOTE N32, 10
	REST N32
	HOLD 100
	VOLUME $0A
	NOTE N32, 10
	REST N32
	VOLUME $0D
	NOTE N32, 10
	REST N32
	VOLUME $0A
	NOTE N32, 10
	REST N32
	LOOP1 1, .l5388
.l53DA:
	FLAGS $00
	VOLUME $0F
	INSTR 5
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $08
	NOTE N16, 15
	VOLUME $04
	NOTE N16, 15
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	INSTR 4
	VOLUME $08
	NOTE N16, 15
	REST N16
	VOLUME $04
	NOTE N16, 15
	VOLUME $0F
	INSTR 5
	NOTE N16, 8
	INSTR 4
	VOLUME $08
	NOTE N16, 15
	REST N16
	VOLUME $04
	NOTE N16, 15
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	REST N16
	INSTR 4
	VOLUME $04
	NOTE N16, 15
	VOLUME $08
	NOTE N16, 15
	LOOP1 7, .l53DA
.l5418:
	FLAGS $00
	HOLD 255
	INSTR 6
	VOLUME $0F
	NOTE N32, 10
	REST N32
	HOLD 100
	VOLUME $0A
	NOTE N32, 10
	REST N32
	VOLUME $0D
	NOTE N32, 10
	REST N32
	VOLUME $0A
	NOTE N32, 10
	REST N32
	VOLUME $0D
	NOTE N32, 10
	REST N32
	VOLUME $0A
	NOTE N32, 10
	REST N32
	HOLD 255
	VOLUME $0F
	NOTE N32, 10
	REST N32
	HOLD 100
	VOLUME $0A
	NOTE N32, 10
	REST N32
	VOLUME $0D
	NOTE N32, 10
	REST N32
	VOLUME $0A
	NOTE N32, 10
	REST N32
	VOLUME $0D
	NOTE N32, 10
	REST N32
	VOLUME $0A
	NOTE N32, 10
	REST N32
	HOLD 255
	VOLUME $0F
	NOTE N32, 10
	REST N32
	HOLD 100
	VOLUME $0A
	NOTE N32, 10
	REST N32
	VOLUME $0D
	NOTE N32, 10
	REST N32
	VOLUME $0A
	NOTE N32, 10
	REST N32
	LOOP1 1, .l5418
.l546C:
	FLAGS $00
	VOLUME $0F
	INSTR 5
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	VOLUME $07
	NOTE N16, 15
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	REST N16
	NOTE N16, 15
	VOLUME $0F
	INSTR 5
	NOTE N16, 8
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	REST N16
	VOLUME $07
	NOTE N16, 15
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	REST N16
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	NOTE N16, 15
	LOOP1 1, .l546C
.l54A6:
	FLAGS $00
	HOLD 255
	INSTR 6
	VOLUME $0F
	NOTE N32, 10
	REST N32
	HOLD 100
	VOLUME $0A
	NOTE N32, 10
	REST N32
	VOLUME $0D
	NOTE N32, 10
	REST N32
	VOLUME $0A
	NOTE N32, 10
	REST N32
	VOLUME $0D
	NOTE N32, 10
	REST N32
	VOLUME $0A
	NOTE N32, 10
	REST N32
	HOLD 255
	VOLUME $0F
	NOTE N32, 10
	REST N32
	HOLD 100
	VOLUME $0A
	NOTE N32, 10
	REST N32
	VOLUME $0D
	NOTE N32, 10
	REST N32
	VOLUME $0A
	NOTE N32, 10
	REST N32
	VOLUME $0D
	NOTE N32, 10
	REST N32
	VOLUME $0A
	NOTE N32, 10
	REST N32
	HOLD 255
	VOLUME $0F
	NOTE N32, 10
	REST N32
	HOLD 100
	VOLUME $0A
	NOTE N32, 10
	REST N32
	VOLUME $0D
	NOTE N32, 10
	REST N32
	VOLUME $0A
	NOTE N32, 10
	REST N32
	LOOP1 1, .l54A6
.l54FA:
	FLAGS $00
	VOLUME $0F
	INSTR 5
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	VOLUME $07
	NOTE N16, 15
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	REST N16
	NOTE N16, 15
	VOLUME $0F
	INSTR 5
	NOTE N16, 8
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	REST N16
	VOLUME $07
	NOTE N16, 15
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	REST N16
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	NOTE N16, 15
	LOOP1 2, .l54FA
	VOLUME $0F
	INSTR 5
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	VOLUME $07
	NOTE N16, 15
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	REST N16
	NOTE N16, 15
	VOLUME $0F
	INSTR 8
	NOTE N8, 12
	REST N8
	NOTE N8, 12
	REST N8
	JUMP Music01_Ch4
	END                ; unreachable

;; Music $02
Music02:
	db $00
	BEPTR Music02_Ch1
	BEPTR Music02_Ch2
	BEPTR Music02_Ch3
	BEPTR Music02_Ch4
Music02_Ch1:
	TEMPO $022E
	OCTAVE 1
	HOLD 255
	DUTY $00
	INSTR 0
	REST N8
	VOLUME $0C
	NOTE N4, 13       ; C_4
	NOTE N8, 16       ; D#4
	NOTE N8, 13       ; C_4
	NOTE N8, 18       ; F_4
	NOTE N8, 16       ; D#4
	NOTE N8, 13       ; C_4
	CONNECT
	NOTE N8, 16       ; D#4
	NOTE N4, 16       ; D#4
	INSTR 2
	CONNECT
	NOTE N4, 16       ; D#4
	INSTR 0
	VOLUME $06
	TRIPLET
	NOTE N4, 16       ; D#4
	VOLUME $0C
	NOTE N4, 11       ; A#3
	NOTE N4, 12       ; B_3
	TRIPLET
	NOTE N4, 13       ; C_4
	NOTE N8, 16       ; D#4
	NOTE N8, 13       ; C_4
	NOTE N8, 18       ; F_4
	NOTE N8, 16       ; D#4
	NOTE N8, 13       ; C_4
	CONNECT
	NOTE N8, 11       ; A#3
	DOTTED
	NOTE N4, 11       ; A#3
	INSTR 2
	CONNECT
	NOTE N2, 11       ; A#3
	INSTR 0
	VOLUME $06
	NOTE N8, 11       ; A#3
.l559C:
	FLAGS $00
	TEMPO $022E
	HOLD 255
	INSTR 0
	DUTY $80
	OCTAVE 1
	REST N4
	VOLUME $0A
	OCTUP
	NOTE N4, 9        ; G#5
	VOLUME $05
	NOTE N8, 9        ; G#5
	VOLUME $0A
	NOTE N8, 8        ; G_5
	VOLUME $05
	NOTE N8, 8        ; G_5
	VOLUME $0A
	CONNECT
	NOTE N8, 6        ; F_5
	NOTE N2, 6        ; F_5
	INSTR 2
	CONNECT
	NOTE N2, 6        ; F_5
	INSTR 0
	VOLUME $05
	NOTE N8, 6        ; F_5
	REST N8
	VOLUME $0A
	NOTE N4, 9        ; G#5
	VOLUME $05
	NOTE N8, 9        ; G#5
	VOLUME $0A
	NOTE N8, 8        ; G_5
	VOLUME $05
	NOTE N8, 8        ; G_5
	VOLUME $0A
	CONNECT
	OCTUP
	NOTE N8, 20       ; G_4
	NOTE N2, 20       ; G_4
	INSTR 2
	CONNECT
	NOTE N2, 20       ; G_4
	INSTR 0
	VOLUME $05
	NOTE N8, 20       ; G_4
	REST N8
	VOLUME $0A
	OCTUP
	NOTE N4, 9        ; G#5
	VOLUME $05
	NOTE N8, 9        ; G#5
	VOLUME $0A
	NOTE N8, 8        ; G_5
	VOLUME $05
	NOTE N8, 8        ; G_5
	VOLUME $0A
	CONNECT
	NOTE N8, 6        ; F_5
	NOTE N2, 6        ; F_5
	INSTR 2
	CONNECT
	NOTE N2, 6        ; F_5
	INSTR 0
	VOLUME $05
	NOTE N8, 6        ; F_5
	REST N8
	VOLUME $0A
	NOTE N4, 9        ; G#5
	VOLUME $05
	NOTE N8, 9        ; G#5
	VOLUME $0A
	NOTE N8, 8        ; G_5
	VOLUME $05
	NOTE N8, 8        ; G_5
	VOLUME $0A
	CONNECT
	OCTUP
	NOTE N8, 20       ; G_4
	DOTTED
	NOTE N4, 20       ; G_4
	INSTR 2
	CONNECT
	NOTE N2, 20       ; G_4
	INSTR 0
	VOLUME $05
	NOTE N8, 20       ; G_4
	OCTAVE 1
	DUTY $40
	VOLUME $0C
	CONNECT
	NOTE N32, 28      ; D#5
	SLIDE 127
	DOTTED
	NOTE N2, 30       ; F_5
	INSTR 2
	DOTTED
	NOTE N8, 30       ; F_5
	CONNECT
	NOTE N32, 30      ; F_5
	INSTR 0
	SLIDE 0
	VOLUME $06
	NOTE N8, 30       ; F_5
	VOLUME $0C
	CONNECT
	OCTUP
	NOTE N32, 11      ; A#5
	SLIDE 127
	DOTTED
	NOTE N8, 13       ; C_6
	CONNECT
	NOTE N32, 13      ; C_6
	SLIDE 0
	NOTE N8, 11       ; A#5
	NOTE N8, 9        ; G#5
	VOLUME $06
	TRIPLET
	NOTE N16, 9       ; G#5
	VOLUME $0C
	TRIPLET
	NOTE N8, 11       ; A#5
	VOLUME $06
	TRIPLET
	NOTE N16, 11      ; A#5
	VOLUME $0C
	TRIPLET
	NOTE N8, 9        ; G#5
	VOLUME $06
	TRIPLET
	NOTE N16, 9       ; G#5
	VOLUME $0C
	DOTTED
	TRIPLET
	NOTE N4, 8        ; G_5
	CONNECT
	NOTE N2, 6        ; F_5
	INSTR 2
	CONNECT
	NOTE N8, 6        ; F_5
	INSTR 0
	VOLUME $06
	NOTE N8, 6        ; F_5
	VOLUME $0C
	NOTE N8, 4        ; D#5
	NOTE N8, 5        ; E_5
	NOTE N8, 6        ; F_5
	NOTE N8, 9        ; G#5
	NOTE N8, 6        ; F_5
	NOTE N8, 4        ; D#5
	NOTE N8, 5        ; E_5
	CONNECT
	NOTE N2, 6        ; F_5
	INSTR 2
	CONNECT
	NOTE N2, 6        ; F_5
	INSTR 0
	VOLUME $06
	NOTE N8, 6        ; F_5
	VOLUME $0C
	CONNECT
	NOTE N32, 11      ; A#5
	SLIDE 127
	DOTTED
	NOTE N8, 13       ; C_6
	CONNECT
	NOTE N32, 13      ; C_6
	SLIDE 0
	NOTE N8, 11       ; A#5
	NOTE N8, 9        ; G#5
	VOLUME $06
	TRIPLET
	NOTE N16, 9       ; G#5
	VOLUME $0C
	TRIPLET
	NOTE N8, 11       ; A#5
	VOLUME $06
	TRIPLET
	NOTE N16, 11      ; A#5
	VOLUME $0C
	TRIPLET
	NOTE N8, 9        ; G#5
	VOLUME $06
	TRIPLET
	NOTE N16, 9       ; G#5
	VOLUME $0C
	DOTTED
	TRIPLET
	NOTE N4, 8        ; G_5
	CONNECT
	NOTE N2, 1        ; C_5
	INSTR 2
	NOTE N8, 1        ; C_5
	DOTTED
	CONNECT
	NOTE N2, 1        ; C_5
	INSTR 0
	VOLUME $06
	NOTE N8, 1        ; C_5
	VOLUME $03
	NOTE N8, 1        ; C_5
	DUTY $80
	VOLUME $0A
	CONNECT
	NOTE N32, 12      ; B_5
	SLIDE 127
	DOTTED
	CONNECT
	NOTE N16, 14      ; C#6
	SLIDE 0
	NOTE N8, 9        ; G#5
	NOTE N8, 6        ; F_5
	NOTE N8, 14       ; C#6
	NOTE N8, 9        ; G#5
	NOTE N8, 6        ; F_5
	NOTE N8, 14       ; C#6
	NOTE N8, 9        ; G#5
	NOTE N8, 8        ; G_5
	NOTE N8, 14       ; C#6
	NOTE N8, 11       ; A#5
	NOTE N8, 8        ; G_5
	NOTE N8, 14       ; C#6
	NOTE N8, 11       ; A#5
	NOTE N8, 8        ; G_5
	NOTE N8, 14       ; C#6
	NOTE N8, 13       ; C_6
	NOTE N8, 8        ; G_5
	NOTE N8, 4        ; D#5
	NOTE N8, 13       ; C_6
	NOTE N8, 8        ; G_5
	NOTE N8, 4        ; D#5
	NOTE N8, 13       ; C_6
	NOTE N8, 8        ; G_5
	NOTE N8, 9        ; G#5
	VOLUME $05
	NOTE N16, 9       ; G#5
	VOLUME $0A
	NOTE N8, 8        ; G_5
	VOLUME $05
	NOTE N16, 8       ; G_5
	VOLUME $0A
	CONNECT
	NOTE N4, 6        ; F_5
	INSTR 2
	CONNECT
	NOTE N8, 6        ; F_5
	INSTR 0
	NOTE N16, 9       ; G#5
	NOTE N16, 8       ; G_5
	NOTE N16, 6       ; F_5
	NOTE N16, 4       ; D#5
	NOTE N8, 14       ; C#6
	NOTE N8, 9        ; G#5
	NOTE N8, 6        ; F_5
	NOTE N8, 14       ; C#6
	NOTE N8, 9        ; G#5
	NOTE N8, 6        ; F_5
	NOTE N8, 14       ; C#6
	NOTE N8, 9        ; G#5
	NOTE N8, 8        ; G_5
	NOTE N8, 14       ; C#6
	NOTE N8, 11       ; A#5
	NOTE N8, 8        ; G_5
	NOTE N8, 14       ; C#6
	NOTE N8, 11       ; A#5
	NOTE N8, 8        ; G_5
	NOTE N8, 14       ; C#6
	NOTE N8, 13       ; C_6
	NOTE N8, 8        ; G_5
	NOTE N8, 4        ; D#5
	NOTE N8, 13       ; C_6
	NOTE N8, 8        ; G_5
	NOTE N8, 4        ; D#5
	NOTE N8, 13       ; C_6
	NOTE N8, 16       ; D#6
	NOTE N16, 13      ; C_6
	NOTE N16, 11      ; A#5
	NOTE N16, 9       ; G#5
	NOTE N16, 11      ; A#5
	NOTE N16, 9       ; G#5
	NOTE N16, 4       ; D#5
	CONNECT
	NOTE N4, 6        ; F_5
	INSTR 2
	CONNECT
	NOTE N16, 6       ; F_5
	INSTR 0
	VOLUME $05
	NOTE N16, 6       ; F_5
	VOLUME $0A
	NOTE N8, 4        ; D#5
	NOTE N8, 5        ; E_5
	CONNECT
	NOTE N1, 6        ; F_5
	INSTR 2
	NOTE N1, 6        ; F_5
	INSTR 7
	CONNECT
	NOTE N1, 6        ; F_5
	REST N1
	JUMP .l559C
	END                ; unreachable
Music02_Ch2:
	TEMPO $022E
	REST N8
.l572C:
	FLAGS $00
	TEMPO $022E
	PAN $11
	OCTAVE 0
	HOLD 255
	DUTY $00
	INSTR 0
	TRANSP 0
	DETUNE 0
	VOLUME $0C
	NOTE N4, 30       ; F_4
	OCTUP
	NOTE N8, 9        ; G#4
	NOTE N8, 6        ; F_4
	NOTE N8, 11       ; A#4
	NOTE N8, 9        ; G#4
	NOTE N8, 6        ; F_4
	CONNECT
	NOTE N8, 9        ; G#4
	NOTE N4, 9        ; G#4
	INSTR 2
	CONNECT
	NOTE N4, 9        ; G#4
	INSTR 0
	VOLUME $06
	TRIPLET
	NOTE N4, 9        ; G#4
	VOLUME $0C
	NOTE N4, 4        ; D#4
	NOTE N4, 5        ; E_4
	TRIPLET
	NOTE N4, 6        ; F_4
	NOTE N8, 9        ; G#4
	NOTE N8, 6        ; F_4
	NOTE N8, 11       ; A#4
	NOTE N8, 9        ; G#4
	NOTE N8, 6        ; F_4
	CONNECT
	NOTE N8, 4        ; D#4
	DOTTED
	NOTE N4, 4        ; D#4
	INSTR 2
	CONNECT
	NOTE N2, 4        ; D#4
	INSTR 0
	VOLUME $06
	NOTE N8, 4        ; D#4
	VOLUME $0C
	NOTE N4, 6        ; F_4
	NOTE N8, 9        ; G#4
	NOTE N8, 6        ; F_4
	NOTE N8, 11       ; A#4
	NOTE N8, 9        ; G#4
	NOTE N8, 6        ; F_4
	CONNECT
	NOTE N8, 9        ; G#4
	DOTTED
	CONNECT
	NOTE N2, 9        ; G#4
	VOLUME $06
	NOTE N8, 9        ; G#4
	VOLUME $0C
	NOTE N16, 4       ; D#4
	NOTE N16, 5       ; E_4
	NOTE N4, 6        ; F_4
	NOTE N8, 9        ; G#4
	NOTE N8, 6        ; F_4
	NOTE N8, 11       ; A#4
	NOTE N8, 9        ; G#4
	NOTE N8, 6        ; F_4
	NOTE N8, 4        ; D#4
	VOLUME $06
	NOTE N8, 4        ; D#4
	VOLUME $0C
	DOTTED
	NOTE N2, 1        ; C_4
	VOLUME $06
	NOTE N8, 1        ; C_4
	VOLUME $0C
	NOTE N4, 6        ; F_4
	NOTE N8, 9        ; G#4
	NOTE N8, 6        ; F_4
	NOTE N8, 11       ; A#4
	NOTE N8, 9        ; G#4
	NOTE N8, 6        ; F_4
	CONNECT
	NOTE N8, 9        ; G#4
	DOTTED
	CONNECT
	NOTE N2, 9        ; G#4
	VOLUME $06
	NOTE N8, 9        ; G#4
	VOLUME $0C
	NOTE N16, 4       ; D#4
	NOTE N16, 5       ; E_4
	NOTE N4, 6        ; F_4
	NOTE N8, 9        ; G#4
	NOTE N8, 6        ; F_4
	NOTE N8, 11       ; A#4
	NOTE N8, 9        ; G#4
	NOTE N8, 6        ; F_4
	NOTE N8, 4        ; D#4
	VOLUME $06
	NOTE N8, 4        ; D#4
	VOLUME $0C
	DOTTED
	NOTE N4, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	OCTUP
	NOTE N8, 20       ; G_3
	NOTE N8, 25       ; C_4
	HOLD 120
	VOLUME $0E
	TRANSP -12
	OCTUP
	NOTE N8, 9        ; G#4
	NOTE N8, 13       ; C_5
	NOTE N8, 9        ; G#4
	NOTE N8, 13       ; C_5
	NOTE N8, 18       ; F_5
	NOTE N8, 13       ; C_5
	NOTE N8, 9        ; G#4
	CONNECT
	NOTE N8, 9        ; G#4
	CONNECT
	NOTE N8, 9        ; G#4
	NOTE N8, 13       ; C_5
	NOTE N8, 9        ; G#4
	NOTE N8, 13       ; C_5
	NOTE N8, 18       ; F_5
	NOTE N8, 13       ; C_5
	NOTE N8, 9        ; G#4
	NOTE N8, 6        ; F_4
	NOTE N8, 11       ; A#4
	NOTE N8, 15       ; D_5
	NOTE N8, 11       ; A#4
	NOTE N8, 15       ; D_5
	NOTE N8, 18       ; F_5
	NOTE N8, 15       ; D_5
	NOTE N8, 11       ; A#4
	NOTE N8, 11       ; A#4
	VOLUME $07
	NOTE N8, 11       ; A#4
	TRANSP 0
	VOLUME $0C
	NOTE N8, 4        ; D#4
	NOTE N8, 5        ; E_4
	NOTE N8, 6        ; F_4
	NOTE N8, 9        ; G#4
	NOTE N8, 6        ; F_4
	NOTE N8, 4        ; D#4
	NOTE N8, 5        ; E_4
	TRANSP -12
	VOLUME $0E
	NOTE N8, 9        ; G#4
	NOTE N8, 13       ; C_5
	NOTE N8, 9        ; G#4
	NOTE N8, 13       ; C_5
	NOTE N8, 18       ; F_5
	NOTE N8, 13       ; C_5
	NOTE N8, 9        ; G#4
	CONNECT
	NOTE N8, 9        ; G#4
	CONNECT
	NOTE N8, 9        ; G#4
	NOTE N8, 13       ; C_5
	NOTE N8, 9        ; G#4
	NOTE N8, 13       ; C_5
	NOTE N8, 18       ; F_5
	NOTE N8, 13       ; C_5
	NOTE N8, 9        ; G#4
	NOTE N8, 6        ; F_4
	NOTE N8, 11       ; A#4
	NOTE N8, 17       ; E_5
	NOTE N8, 11       ; A#4
	NOTE N8, 17       ; E_5
	NOTE N8, 20       ; G_5
	NOTE N8, 17       ; E_5
	NOTE N8, 11       ; A#4
	CONNECT
	NOTE N8, 11       ; A#4
	CONNECT
	NOTE N8, 11       ; A#4
	NOTE N8, 17       ; E_5
	NOTE N8, 11       ; A#4
	NOTE N8, 17       ; E_5
	NOTE N8, 20       ; G_5
	NOTE N8, 17       ; E_5
	NOTE N8, 11       ; A#4
	NOTE N8, 8        ; G_4
	DOTTED
	REST N8
	HOLD 255
	TRANSP 12
	DETUNE 1
	PAN $10
	DUTY $80
	VOLUME $07
	TRIPLET
	CONNECT
	NOTE N32, 12      ; B_4
	SLIDE 127
	DOTTED
	TRIPLET
	NOTE N16, 14      ; C#5
	TRIPLET
	CONNECT
	NOTE N64, 14      ; C#5
	SLIDE 0
	TRIPLET
	NOTE N8, 9        ; G#4
	NOTE N8, 6        ; F_4
	NOTE N8, 14       ; C#5
	NOTE N8, 9        ; G#4
	NOTE N8, 6        ; F_4
	NOTE N8, 14       ; C#5
	NOTE N8, 9        ; G#4
	NOTE N8, 8        ; G_4
	NOTE N8, 14       ; C#5
	NOTE N8, 11       ; A#4
	NOTE N8, 8        ; G_4
	NOTE N8, 14       ; C#5
	NOTE N8, 11       ; A#4
	NOTE N8, 8        ; G_4
	NOTE N8, 14       ; C#5
	NOTE N8, 13       ; C_5
	NOTE N8, 8        ; G_4
	NOTE N8, 4        ; D#4
	NOTE N8, 13       ; C_5
	NOTE N8, 8        ; G_4
	NOTE N8, 4        ; D#4
	NOTE N8, 13       ; C_5
	NOTE N8, 8        ; G_4
	NOTE N8, 9        ; G#4
	VOLUME $03
	NOTE N16, 9       ; G#4
	VOLUME $07
	NOTE N8, 8        ; G_4
	VOLUME $03
	NOTE N16, 8       ; G_4
	VOLUME $07
	CONNECT
	NOTE N4, 6        ; F_4
	INSTR 2
	CONNECT
	NOTE N8, 6        ; F_4
	INSTR 0
	NOTE N16, 9       ; G#4
	NOTE N16, 8       ; G_4
	NOTE N16, 6       ; F_4
	NOTE N16, 4       ; D#4
	NOTE N8, 14       ; C#5
	NOTE N8, 9        ; G#4
	NOTE N8, 6        ; F_4
	NOTE N8, 14       ; C#5
	NOTE N8, 9        ; G#4
	NOTE N8, 6        ; F_4
	NOTE N8, 14       ; C#5
	NOTE N8, 9        ; G#4
	NOTE N8, 8        ; G_4
	NOTE N8, 14       ; C#5
	NOTE N8, 11       ; A#4
	NOTE N8, 8        ; G_4
	NOTE N8, 14       ; C#5
	NOTE N8, 11       ; A#4
	NOTE N8, 8        ; G_4
	NOTE N8, 14       ; C#5
	NOTE N8, 13       ; C_5
	NOTE N8, 8        ; G_4
	NOTE N8, 4        ; D#4
	NOTE N8, 13       ; C_5
	NOTE N8, 8        ; G_4
	NOTE N8, 4        ; D#4
	NOTE N8, 13       ; C_5
	NOTE N8, 16       ; D#5
	NOTE N16, 13      ; C_5
	NOTE N16, 11      ; A#4
	NOTE N16, 9       ; G#4
	NOTE N16, 11      ; A#4
	NOTE N16, 9       ; G#4
	NOTE N16, 4       ; D#4
	CONNECT
	NOTE N4, 6        ; F_4
	INSTR 2
	CONNECT
	NOTE N16, 6       ; F_4
	INSTR 0
	VOLUME $03
	NOTE N16, 6       ; F_4
	VOLUME $07
	NOTE N16, 4       ; D#4
	JUMP .l572C
	END                ; unreachable
Music02_Ch3:
	TEMPO $022E
	REST N8
.l588F:
	FLAGS $00
	TEMPO $022E
	HOLD 255
	OCTAVE 0
	INSTR 1
	TRANSP -12
	VOLUME $03
	NOTE N4, 30       ; F_4
	OCTUP
	NOTE N8, 9        ; G#4
	NOTE N8, 6        ; F_4
	NOTE N8, 11       ; A#4
	NOTE N8, 9        ; G#4
	NOTE N8, 6        ; F_4
	CONNECT
	NOTE N8, 9        ; G#4
	CONNECT
	NOTE N2, 9        ; G#4
	VOLUME $02
	TRIPLET
	NOTE N4, 9        ; G#4
	VOLUME $03
	TRIPLET
	NOTE N8, 4        ; D#4
	VOLUME $02
	TRIPLET
	NOTE N16, 4       ; D#4
	VOLUME $03
	TRIPLET
	NOTE N8, 5        ; E_4
	VOLUME $02
	TRIPLET
	NOTE N16, 5       ; E_4
	VOLUME $03
	TRIPLET
	NOTE N4, 6        ; F_4
	NOTE N8, 9        ; G#4
	NOTE N8, 6        ; F_4
	NOTE N8, 11       ; A#4
	NOTE N8, 9        ; G#4
	NOTE N8, 6        ; F_4
	CONNECT
	NOTE N8, 4        ; D#4
	DOTTED
	NOTE N4, 4        ; D#4
	CONNECT
	NOTE N16, 4       ; D#4
	VOLUME $02
	NOTE N16, 4       ; D#4
	VOLUME $03
	NOTE N16, 8       ; G_4
	NOTE N16, 20      ; G_5
	NOTE N16, 13      ; C_5
	NOTE N16, 6       ; F_4
	NOTE N16, 4       ; D#4
	NOTE N16, 11      ; A#4
	NOTE N16, 13      ; C_5
	NOTE N16, 16      ; D#5
	HOLD 200
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N16, 4       ; D#4
	NOTE N16, 5       ; E_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 18       ; F_5
	NOTE N8, 6        ; F_4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 4        ; D#4
	NOTE N8, 4        ; D#4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N16, 4       ; D#4
	NOTE N16, 5       ; E_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 18       ; F_5
	NOTE N8, 6        ; F_4
	HOLD 255
	NOTE N8, 1        ; C_4
	VOLUME $02
	NOTE N8, 1        ; C_4
	VOLUME $03
	NOTE N4, 1        ; C_4
	VOLUME $02
	NOTE N8, 1        ; C_4
	HOLD 200
	VOLUME $03
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 8        ; G_4
	NOTE N8, 1        ; C_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 11       ; A#4
	NOTE N8, 11       ; A#4
	NOTE N8, 11       ; A#4
	NOTE N8, 11       ; A#4
	NOTE N8, 11       ; A#4
	NOTE N8, 11       ; A#4
	NOTE N8, 11       ; A#4
	HOLD 255
	NOTE N8, 11       ; A#4
	VOLUME $02
	NOTE N8, 11       ; A#4
	VOLUME $03
	HOLD 200
	NOTE N8, 4        ; D#4
	NOTE N8, 5        ; E_4
	NOTE N8, 6        ; F_4
	NOTE N8, 9        ; G#4
	NOTE N8, 6        ; F_4
	NOTE N8, 4        ; D#4
	NOTE N8, 5        ; E_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 2        ; C#4
	NOTE N8, 2        ; C#4
	NOTE N8, 2        ; C#4
	NOTE N8, 2        ; C#4
	NOTE N8, 2        ; C#4
	NOTE N8, 2        ; C#4
	NOTE N8, 2        ; C#4
	NOTE N8, 2        ; C#4
	NOTE N8, 4        ; D#4
	NOTE N8, 4        ; D#4
	NOTE N8, 4        ; D#4
	NOTE N8, 4        ; D#4
	NOTE N8, 4        ; D#4
	NOTE N8, 4        ; D#4
	NOTE N8, 4        ; D#4
	NOTE N8, 4        ; D#4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 8        ; G_4
	HOLD 255
	NOTE N8, 9        ; G#4
	VOLUME $02
	NOTE N16, 9       ; G#4
	VOLUME $03
	NOTE N8, 8        ; G_4
	VOLUME $02
	NOTE N16, 8       ; G_4
	VOLUME $03
	CONNECT
	NOTE N2, 6        ; F_4
	CONNECT
	NOTE N16, 6       ; F_4
	VOLUME $02
	NOTE N16, 6       ; F_4
	HOLD 200
	VOLUME $03
	NOTE N8, 2        ; C#4
	NOTE N8, 2        ; C#4
	NOTE N8, 2        ; C#4
	NOTE N8, 2        ; C#4
	NOTE N8, 2        ; C#4
	NOTE N8, 2        ; C#4
	NOTE N8, 2        ; C#4
	NOTE N8, 2        ; C#4
	NOTE N8, 4        ; D#4
	NOTE N8, 4        ; D#4
	NOTE N8, 4        ; D#4
	NOTE N8, 4        ; D#4
	NOTE N8, 4        ; D#4
	NOTE N8, 4        ; D#4
	NOTE N8, 4        ; D#4
	NOTE N8, 4        ; D#4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 1        ; C_4
	NOTE N8, 8        ; G_4
	HOLD 255
	NOTE N8, 6        ; F_4
	VOLUME $02
	NOTE N16, 6       ; F_4
	VOLUME $03
	NOTE N8, 4        ; D#4
	VOLUME $02
	NOTE N16, 4       ; D#4
	VOLUME $03
	NOTE N2, 6        ; F_4
	VOLUME $02
	NOTE N8, 6        ; F_4
	JUMP .l588F
	END                ; unreachable
Music02_Ch4:
	TEMPO $022E
	OCTAVE 0
	HOLD 100
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	NOTE N16, 10
.l59DC:
	FLAGS $00
.l59DE:
	FLAGS $00
	INSTR 5
	VOLUME $0F
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $06
	NOTE N16, 15
	REST N16
	LOOP1 13, .l59DE
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	NOTE N16, 10
	NOTE N16, 10
	REST N16
	NOTE N16, 10
	REST N16
	NOTE N16, 10
	NOTE N16, 10
.l59FC:
	FLAGS $00
.l59FE:
	FLAGS $00
	INSTR 5
	VOLUME $0F
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $06
	NOTE N16, 15
	REST N16
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	REST N16
	INSTR 4
	VOLUME $06
	NOTE N16, 15
	REST N16
	LOOP1 6, .l59FE
	INSTR 5
	VOLUME $0F
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $06
	NOTE N16, 15
	REST N16
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	REST N16
	NOTE N16, 10
	NOTE N16, 10
	LOOP2 1, .l59FC
.l5A34:
	FLAGS $00
	INSTR 5
	VOLUME $0F
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $06
	NOTE N16, 15
	REST N16
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	REST N16
	INSTR 4
	VOLUME $06
	NOTE N16, 15
	REST N16
	LOOP1 4, .l5A34
	INSTR 5
	VOLUME $0F
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $06
	NOTE N16, 15
	REST N16
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	REST N16
	HOLD 255
	INSTR 3
	VOLUME $0A
	NOTE N8, 15
	HOLD 100
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	REST N16
	DOTTED
	REST N4
	REST N8
	INSTR 5
	VOLUME $0F
	NOTE N16, 8
	REST N16
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	REST N16
	REST N8
.l5A83:
	FLAGS $00
	INSTR 5
	VOLUME $0F
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $06
	NOTE N16, 15
	REST N16
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	REST N16
	INSTR 4
	VOLUME $06
	NOTE N16, 15
	REST N16
	LOOP1 6, .l5A83
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	NOTE N16, 10
	HOLD 255
	INSTR 3
	VOLUME $0A
	NOTE N8, 15
	HOLD 100
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	NOTE N16, 10
	HOLD 255
	INSTR 3
	VOLUME $0A
	NOTE N8, 15
	HOLD 100
.l5ABF:
	FLAGS $00
	INSTR 5
	VOLUME $0F
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $06
	NOTE N16, 15
	REST N16
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	REST N16
	INSTR 4
	VOLUME $06
	NOTE N16, 15
	REST N16
	LOOP1 5, .l5ABF
	INSTR 6
	VOLUME $0F
	NOTE N16, 10
	REST N8
	NOTE N16, 10
	REST N8
	NOTE N16, 10
	REST N16
	REST N4
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	NOTE N16, 10
	NOTE N16, 10
	REST N16
.l5AF0:
	FLAGS $00
	INSTR 5
	VOLUME $0F
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $06
	NOTE N16, 15
	REST N16
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	REST N16
	INSTR 4
	VOLUME $06
	NOTE N16, 15
	REST N16
	LOOP1 5, .l5AF0
	INSTR 6
	VOLUME $0F
	NOTE N16, 10
	REST N8
	NOTE N16, 10
	REST N8
	NOTE N16, 10
	REST N16
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	NOTE N16, 10
	NOTE N16, 10
	REST N16
	NOTE N16, 10
	REST N16
	NOTE N16, 10
	NOTE N16, 10
	JUMP .l59DC
	END                ; unreachable

;; Music $03
Music03:
	db $00
	BEPTR Music03_Ch1
	BEPTR Music03_Ch2
	BEPTR Music03_Ch3
	BEPTR Music03_Ch4
Music03_Ch1:
	FLAGS $00
	TEMPO $0216
	HOLD 255
	DUTY $80
	INSTR 0
	OCTAVE 0
	VOLUME $09
	DOTTED
	NOTE N8, 23       ; A#3
	REST N16
	VOLUME $06
	DOTTED
	NOTE N8, 23       ; A#3
	REST N16
	VOLUME $03
	NOTE N8, 23       ; A#3
	VOLUME $09
	CONNECT
	NOTE N32, 22      ; A_3
	SLIDE 127
	DOTTED
	CONNECT
	NOTE N16, 23      ; A#3
	SLIDE 0
	NOTE N8, 21       ; G#3
	NOTE N8, 18       ; F_3
	DOTTED
	NOTE N8, 21       ; G#3
	NOTE N8, 23       ; A#3
	REST N16
	VOLUME $06
	DOTTED
	NOTE N8, 23       ; A#3
	REST N16
	VOLUME $03
	DOTTED
	NOTE N8, 23       ; A#3
	REST N16
	VOLUME $09
	NOTE N16, 23      ; A#3
	NOTE N16, 25      ; C_4
	DOTTED
	NOTE N8, 26       ; C#4
	NOTE N8, 28       ; D#4
	VOLUME $05
	NOTE N16, 28      ; D#4
	VOLUME $09
	NOTE N8, 26       ; C#4
	DOTTED
	NOTE N8, 25       ; C_4
	NOTE N8, 21       ; G#3
	VOLUME $05
	NOTE N16, 21      ; G#3
	VOLUME $09
	NOTE N8, 18       ; F_3
	DOTTED
	NOTE N8, 21       ; G#3
	NOTE N8, 23       ; A#3
	REST N16
	VOLUME $06
	DOTTED
	NOTE N8, 23       ; A#3
	REST N16
	VOLUME $03
	DOTTED
	NOTE N8, 23       ; A#3
	REST N16
	VOLUME $01
	NOTE N8, 23       ; A#3
	HOLD 255
	DUTY $40
	INSTR 0
	OCTAVE 1
	VOLUME $0C
	DOTTED
	NOTE N8, 30       ; F_5
	REST N16
	VOLUME $06
	DOTTED
	NOTE N8, 30       ; F_5
	REST N16
	VOLUME $03
	NOTE N8, 30       ; F_5
	VOLUME $0C
	CONNECT
	NOTE N32, 29      ; E_5
	SLIDE 127
	DOTTED
	CONNECT
	NOTE N16, 30      ; F_5
	SLIDE 0
	NOTE N8, 28       ; D#5
	NOTE N8, 26       ; C#5
	NOTE N8, 25       ; C_5
	NOTE N8, 21       ; G#4
	NOTE N8, 18       ; F_4
	DOTTED
	NOTE N8, 23       ; A#4
	VOLUME $06
	NOTE N16, 23      ; A#4
	VOLUME $03
	NOTE N32, 23      ; A#4
	VOLUME $0C
	NOTE N16, 25      ; C_5
	VOLUME $0A
	CONNECT
	NOTE N16, 25      ; C_5
	CONNECT
	NOTE N32, 25      ; C_5
	VOLUME $0C
	DOTTED
	NOTE N8, 26       ; C#5
	NOTE N8, 28       ; D#5
	NOTE N16, 30      ; F_5
	DOTTED
	NOTE N8, 28       ; D#5
	NOTE N8, 26       ; C#5
	NOTE N8, 25       ; C_5
	NOTE N8, 21       ; G#4
	NOTE N8, 18       ; F_4
	NOTE N8, 13       ; C_4
	NOTE N8, 16       ; D#4
	VOLUME $08
	NOTE N16, 16      ; D#4
	VOLUME $0C
	NOTE N8, 14       ; C#4
	VOLUME $08
	NOTE N16, 14      ; C#4
	VOLUME $0C
	DOTTED
	CONNECT
	NOTE N8, 18       ; F_4
	TRIPLET
	CONNECT
	NOTE N32, 18      ; F_4
	VOLUME $03
	NOTE N16, 18      ; F_4
	VOLUME $06
	DOTTED
	TRIPLET
	CONNECT
	NOTE N8, 18       ; F_4
	TRIPLET
	CONNECT
	NOTE N32, 18      ; F_4
	VOLUME $02
	NOTE N16, 18      ; F_4
	VOLUME $05
	NOTE N32, 24      ; B_4
	VOLUME $06
	NOTE N32, 25      ; C_5
	VOLUME $07
	NOTE N32, 26      ; C#5
	VOLUME $08
	NOTE N32, 27      ; D_5
	VOLUME $09
	NOTE N32, 28      ; D#5
	VOLUME $0A
	NOTE N32, 29      ; E_5
	VOLUME $0C
	DOTTED
	TRIPLET
	NOTE N8, 30       ; F_5
	REST N16
	VOLUME $06
	DOTTED
	NOTE N8, 30       ; F_5
	REST N16
	VOLUME $03
	NOTE N8, 30       ; F_5
	VOLUME $0C
	CONNECT
	NOTE N32, 29      ; E_5
	SLIDE 127
	DOTTED
	CONNECT
	NOTE N16, 30      ; F_5
	SLIDE 0
	NOTE N16, 28      ; D#5
	DOTTED
	NOTE N8, 26       ; C#5
	NOTE N8, 25       ; C_5
	NOTE N8, 21       ; G#4
	NOTE N8, 25       ; C_5
	NOTE N8, 23       ; A#4
	VOLUME $06
	NOTE N8, 23       ; A#4
	VOLUME $0C
	NOTE N16, 23      ; A#4
	NOTE N16, 25      ; C_5
	NOTE N16, 26      ; C#5
	NOTE N16, 28      ; D#5
	NOTE N16, 30      ; F_5
	OCTUP
	NOTE N16, 13      ; C_6
	DOTTED
	NOTE N8, 11       ; A#5
	DOTTED
	NOTE N8, 9        ; G#5
	NOTE N8, 11       ; A#5
	DOTTED
	NOTE N8, 14       ; C#6
	DOTTED
	NOTE N8, 13       ; C_6
	NOTE N8, 9        ; G#5
	NOTE N8, 16       ; D#6
	VOLUME $06
	NOTE N16, 16      ; D#6
	VOLUME $0C
	NOTE N8, 9        ; G#5
	VOLUME $06
	NOTE N16, 9       ; G#5
	VOLUME $0C
	DOTTED
	NOTE N8, 11       ; A#5
	REST N16
	VOLUME $06
	NOTE N8, 11       ; A#5
	DUTY $80
	VOLUME $0D
	CONNECT
	NOTE N32, 1       ; C_5
	SLIDE 50
	CONNECT
	OCTUP
	NOTE N32, 13      ; C_4
	SLIDE 0
	CONNECT
	NOTE N32, 25      ; C_5
	SLIDE 50
	CONNECT
	NOTE N32, 13      ; C_4
	SLIDE 0
	CONNECT
	NOTE N16, 17      ; E_4
	SLIDE 50
	NOTE N16, 11      ; A#3
	SLIDE 50
	CONNECT
	NOTE N16, 1       ; C_3
	DUTY $40
	SLIDE 0
	VOLUME $08
	NOTE N32, 21      ; G#4
	VOLUME $0A
	NOTE N32, 22      ; A_4
	VOLUME $0C
	NOTE N8, 23       ; A#4
	NOTE N8, 26       ; C#5
	NOTE N8, 28       ; D#5
	TRIPLET
	CONNECT
	NOTE N32, 29      ; E_5
	SLIDE 127
	VOLUME $0C
	CONNECT
	NOTE N4, 30       ; F_5
	SLIDE 0
	DOTTED
	TRIPLET
	NOTE N8, 25       ; C_5
	NOTE N8, 26       ; C#5
	NOTE N8, 28       ; D#5
	NOTE N16, 26      ; C#5
	NOTE N8, 25       ; C_5
	DOTTED
	NOTE N8, 21       ; G#4
	CONNECT
	NOTE N4, 23       ; A#4
	INSTR 2
	DOTTED
	CONNECT
	NOTE N8, 23       ; A#4
	INSTR 0
	VOLUME $06
	NOTE N16, 23      ; A#4
	VOLUME $0C
	NOTE N32, 22      ; A_4
	DOTTED
	NOTE N16, 23      ; A#4
	NOTE N32, 22      ; A_4
	DOTTED
	NOTE N16, 23      ; A#4
	NOTE N32, 22      ; A_4
	DOTTED
	NOTE N16, 23      ; A#4
	NOTE N32, 22      ; A_4
	DOTTED
	NOTE N16, 23      ; A#4
	NOTE N8, 25       ; C_5
	NOTE N8, 26       ; C#5
	NOTE N8, 28       ; D#5
	CONNECT
	NOTE N8, 30       ; F_5
	NOTE N2, 30       ; F_5
	INSTR 2
	DOTTED
	NOTE N4, 30       ; F_5
	SLIDE 80
	DOTTED
	CONNECT
	NOTE N16, 25      ; C_5
	VOLUME $00
	NOTE N32, 29      ; E_5
	VOLUME $0C
	SLIDE 127
	INSTR 0
	NOTE N8, 31       ; F#5
	SLIDE 0
	NOTE N16, 30      ; F_5
	DOTTED
	NOTE N8, 31       ; F#5
	OCTUP
	NOTE N8, 9        ; G#5
	NOTE N8, 11       ; A#5
	NOTE N8, 13       ; C_6
	NOTE N8, 14       ; C#6
	NOTE N8, 11       ; A#5
	VOLUME $06
	NOTE N8, 11       ; A#5
	VOLUME $0C
	SLIDE 127
	NOTE N8, 13       ; C_6
	SLIDE 0
	NOTE N8, 9        ; G#5
	NOTE N8, 6        ; F_5
	NOTE N16, 3       ; D_5
	NOTE N16, 11      ; A#5
	NOTE N16, 6       ; F_5
	NOTE N16, 3       ; D_5
	NOTE N16, 11      ; A#5
	NOTE N16, 6       ; F_5
	NOTE N16, 3       ; D_5
	NOTE N16, 11      ; A#5
	DOTTED
	NOTE N4, 2        ; C#5
	OCTUP
	NOTE N4, 23       ; A#4
	VOLUME $06
	DOTTED
	NOTE N16, 23      ; A#4
	VOLUME $0C
	CONNECT
	NOTE N32, 26      ; C#5
	SLIDE 127
	CONNECT
	NOTE N8, 28       ; D#5
	SLIDE 0
	CONNECT
	NOTE N8, 30       ; F_5
	NOTE N2, 30       ; F_5
	INSTR 2
	DOTTED
	CONNECT
	NOTE N4, 30       ; F_5
	INSTR 0
	VOLUME $06
	NOTE N8, 30       ; F_5
	VOLUME $0C
	HOLD 150
	NOTE N16, 30      ; F_5
	NOTE N16, 30      ; F_5
	VOLUME $06
	NOTE N16, 30      ; F_5
	VOLUME $0C
	NOTE N16, 30      ; F_5
	VOLUME $06
	NOTE N16, 30      ; F_5
	VOLUME $0C
	NOTE N16, 30      ; F_5
	VOLUME $06
	NOTE N16, 30      ; F_5
	VOLUME $0C
	NOTE N16, 30      ; F_5
	HOLD 255
	NOTE N16, 30      ; F_5
	VOLUME $06
	NOTE N16, 30      ; F_5
	VOLUME $03
	NOTE N16, 30      ; F_5
	CONNECT
	REST N4
	CONNECT
	REST N16
	JUMP Music03_Ch1
	END                ; unreachable
Music03_Ch2:
	FLAGS $00
	TEMPO $0216
	HOLD 255
	DUTY $80
	INSTR 0
	OCTAVE 1
	VOLUME $07
	DOTTED
	NOTE N8, 23       ; A#4
	REST N16
	VOLUME $04
	DOTTED
	NOTE N8, 23       ; A#4
	REST N16
	VOLUME $02
	NOTE N8, 23       ; A#4
	VOLUME $07
	CONNECT
	NOTE N32, 22      ; A_4
	SLIDE 127
	DOTTED
	CONNECT
	NOTE N16, 23      ; A#4
	SLIDE 0
	NOTE N8, 21       ; G#4
	NOTE N8, 18       ; F_4
	DOTTED
	NOTE N8, 21       ; G#4
	NOTE N8, 23       ; A#4
	REST N16
	VOLUME $04
	DOTTED
	NOTE N8, 23       ; A#4
	REST N16
	VOLUME $02
	DOTTED
	NOTE N8, 23       ; A#4
	REST N16
	VOLUME $07
	NOTE N16, 23      ; A#4
	NOTE N16, 25      ; C_5
	DOTTED
	NOTE N8, 26       ; C#5
	NOTE N8, 28       ; D#5
	VOLUME $04
	NOTE N16, 28      ; D#5
	VOLUME $07
	NOTE N8, 26       ; C#5
	DOTTED
	NOTE N8, 25       ; C_5
	NOTE N8, 21       ; G#4
	VOLUME $04
	NOTE N16, 21      ; G#4
	VOLUME $07
	NOTE N8, 18       ; F_4
	DOTTED
	NOTE N8, 21       ; G#4
	NOTE N8, 23       ; A#4
	REST N16
	VOLUME $04
	DOTTED
	NOTE N8, 23       ; A#4
	REST N16
	VOLUME $02
	DOTTED
	NOTE N8, 23       ; A#4
	REST N16
	VOLUME $01
	NOTE N8, 23       ; A#4
	HOLD 200
	INSTR 0
	OCTAVE 1
	DUTY $00
	PAN $11
	VOLUME $0C
	NOTE N8, 11       ; A#3
	VOLUME $06
	NOTE N8, 11       ; A#3
	HOLD 150
	DUTY $80
	VOLUME $08
	OCTUP
	NOTE N16, 9       ; G#5
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $03
	NOTE N16, 11      ; A#5
	VOLUME $08
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $08
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $08
	NOTE N16, 9       ; G#5
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $08
	NOTE N16, 11      ; A#5
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $08
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $08
	NOTE N16, 9       ; G#5
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $08
	NOTE N16, 11      ; A#5
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	HOLD 200
	DUTY $00
	VOLUME $0C
	DOTTED
	OCTUP
	NOTE N8, 11       ; A#3
	DOTTED
	NOTE N8, 10       ; A_3
	DOTTED
	NOTE N8, 11       ; A#3
	VOLUME $06
	NOTE N16, 11      ; A#3
	HOLD 150
	DUTY $80
	VOLUME $08
	OCTUP
	NOTE N16, 9       ; G#5
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $08
	NOTE N16, 11      ; A#5
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $08
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $08
	NOTE N16, 9       ; G#5
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $08
	NOTE N16, 11      ; A#5
	HOLD 200
	DUTY $00
	VOLUME $0C
	DOTTED
	OCTUP
	NOTE N8, 11       ; A#3
	DOTTED
	NOTE N8, 9        ; G#3
	CONNECT
	NOTE N64, 11      ; A#3
	DOTTED
	CONNECT
	NOTE N16, 11      ; A#3
	DUTY $80
	INSTR 3
	VOLUME $08
	CONNECT
	NOTE N64, 26      ; C#5
	SLIDE 127
	NOTE N16, 28      ; D#5
	INSTR 2
	CONNECT
	NOTE N8, 28       ; D#5
	INSTR 3
	SLIDE 0
	DOTTED
	NOTE N8, 25       ; C_5
	NOTE N8, 21       ; G#4
	HOLD 200
	DUTY $00
	INSTR 0
	VOLUME $0C
	NOTE N8, 11       ; A#3
	VOLUME $06
	NOTE N8, 11       ; A#3
	HOLD 150
	DUTY $80
	VOLUME $08
	OCTUP
	NOTE N16, 9       ; G#5
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $08
	NOTE N16, 11      ; A#5
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $08
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $08
	NOTE N16, 9       ; G#5
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $08
	NOTE N16, 11      ; A#5
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $08
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $08
	NOTE N16, 9       ; G#5
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $08
	NOTE N16, 11      ; A#5
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	HOLD 200
	DUTY $00
	VOLUME $0C
	DOTTED
	OCTUP
	NOTE N8, 11       ; A#3
	DOTTED
	NOTE N8, 10       ; A_3
	DOTTED
	NOTE N8, 7        ; F#3
	VOLUME $06
	NOTE N16, 7       ; F#3
	HOLD 150
	DUTY $80
	VOLUME $08
	OCTUP
	NOTE N16, 9       ; G#5
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $08
	NOTE N16, 11      ; A#5
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $08
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $08
	NOTE N16, 9       ; G#5
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $08
	NOTE N16, 11      ; A#5
	HOLD 200
	DUTY $00
	VOLUME $0C
	DOTTED
	OCTUP
	NOTE N8, 9        ; G#3
	DOTTED
	NOTE N8, 4        ; D#3
	DOTTED
	NOTE N8, 6        ; F_3
	VOLUME $06
	NOTE N16, 6       ; F_3
	HOLD 150
	DUTY $80
	VOLUME $08
	OCTUP
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $08
	NOTE N16, 9       ; G#5
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $08
	NOTE N16, 11      ; A#5
	HOLD 220
	DUTY $80
	INSTR 3
	TRANSP -12
	VOLUME $0A
	DOTTED
	CONNECT
	NOTE N4, 14       ; C#6
	CONNECT
	NOTE N16, 14      ; C#6
	VOLUME $05
	NOTE N16, 14      ; C#6
	VOLUME $0A
	DOTTED
	NOTE N8, 13       ; C_6
	DOTTED
	NOTE N8, 11       ; A#5
	NOTE N16, 9       ; G#5
	VOLUME $05
	NOTE N16, 9       ; G#5
	VOLUME $0A
	DOTTED
	CONNECT
	NOTE N4, 9        ; G#5
	CONNECT
	NOTE N16, 9       ; G#5
	VOLUME $05
	NOTE N16, 9       ; G#5
	VOLUME $0A
	NOTE N8, 14       ; C#6
	NOTE N8, 13       ; C_6
	NOTE N8, 11       ; A#5
	NOTE N8, 9        ; G#5
	DOTTED
	CONNECT
	NOTE N4, 14       ; C#6
	CONNECT
	NOTE N16, 14      ; C#6
	VOLUME $05
	NOTE N16, 14      ; C#6
	VOLUME $0A
	NOTE N4, 16       ; D#6
	NOTE N8, 9        ; G#5
	CONNECT
	NOTE N8, 14       ; C#6
	DOTTED
	CONNECT
	NOTE N4, 14       ; C#6
	VOLUME $05
	NOTE N8, 14       ; C#6
	TRANSP 0
	DUTY $40
	INSTR 0
	VOLUME $08
	TRIPLET
	NOTE N32, 3       ; D_5
	VOLUME $06
	NOTE N32, 3       ; D_5
	VOLUME $08
	NOTE N32, 6       ; F_5
	VOLUME $06
	NOTE N32, 6       ; F_5
	VOLUME $08
	NOTE N32, 9       ; G#5
	VOLUME $06
	NOTE N32, 9       ; G#5
	VOLUME $08
	NOTE N32, 12      ; B_5
	VOLUME $06
	NOTE N32, 12      ; B_5
	VOLUME $08
	NOTE N32, 9       ; G#5
	VOLUME $06
	NOTE N32, 9       ; G#5
	VOLUME $08
	NOTE N32, 12      ; B_5
	VOLUME $06
	NOTE N32, 12      ; B_5
	VOLUME $08
	NOTE N32, 15      ; D_6
	VOLUME $06
	NOTE N32, 15      ; D_6
	VOLUME $08
	NOTE N32, 18      ; F_6
	VOLUME $06
	NOTE N32, 18      ; F_6
	VOLUME $08
	NOTE N32, 15      ; D_6
	VOLUME $06
	NOTE N32, 15      ; D_6
	VOLUME $08
	NOTE N32, 18      ; F_6
	VOLUME $06
	NOTE N32, 18      ; F_6
	VOLUME $08
	NOTE N32, 21      ; G#6
	VOLUME $06
	NOTE N32, 21      ; G#6
	VOLUME $08
	NOTE N32, 24      ; B_6
	VOLUME $06
	NOTE N32, 24      ; B_6
	VOLUME $09
	TRANSP 0
	DUTY $40
	HOLD 180
	TRIPLET
	OCTUP
	NOTE N8, 14       ; C#4
	NOTE N8, 14       ; C#4
	NOTE N8, 14       ; C#4
	NOTE N8, 14       ; C#4
	NOTE N8, 16       ; D#4
	NOTE N8, 16       ; D#4
	NOTE N8, 16       ; D#4
	NOTE N8, 16       ; D#4
	HOLD 220
	NOTE N16, 13      ; C_4
	VOLUME $07
	NOTE N8, 13       ; C_4
	VOLUME $0C
	DOTTED
	NOTE N8, 18       ; F_4
	NOTE N8, 21       ; G#4
	NOTE N8, 18       ; F_4
	NOTE N8, 23       ; A#4
	NOTE N8, 15       ; D_4
	NOTE N8, 6        ; F_3
	NOTE N8, 11       ; A#3
	NOTE N8, 11       ; A#3
	NOTE N8, 11       ; A#3
	NOTE N8, 14       ; C#4
	NOTE N8, 13       ; C_4
	NOTE N8, 16       ; D#4
	NOTE N8, 21       ; G#4
	NOTE N8, 22       ; A_4
	NOTE N16, 22      ; A_4
	NOTE N16, 18      ; F_4
	NOTE N16, 25      ; C_5
	NOTE N16, 22      ; A_4
	NOTE N16, 18      ; F_4
	NOTE N16, 25      ; C_5
	NOTE N16, 22      ; A_4
	NOTE N16, 18      ; F_4
	NOTE N16, 25      ; C_5
	NOTE N16, 22      ; A_4
	NOTE N16, 18      ; F_4
	NOTE N16, 25      ; C_5
	NOTE N16, 22      ; A_4
	NOTE N16, 18      ; F_4
	NOTE N16, 25      ; C_5
	NOTE N16, 22      ; A_4
	HOLD 180
	NOTE N16, 25      ; C_5
	NOTE N16, 25      ; C_5
	VOLUME $07
	NOTE N16, 25      ; C_5
	VOLUME $0C
	NOTE N16, 25      ; C_5
	VOLUME $07
	NOTE N16, 25      ; C_5
	VOLUME $0C
	NOTE N16, 25      ; C_5
	VOLUME $07
	NOTE N16, 25      ; C_5
	VOLUME $0C
	NOTE N16, 25      ; C_5
	NOTE N16, 25      ; C_5
	VOLUME $07
	NOTE N16, 25      ; C_5
	VOLUME $04
	NOTE N16, 25      ; C_5
	CONNECT
	REST N4
	CONNECT
	REST N16
	JUMP Music03_Ch2
	END                ; unreachable
Music03_Ch3:
	FLAGS $00
	TEMPO $0216
	HOLD 240
	INSTR 1
	OCTAVE 0
	VOLUME $03
	DOTTED
	NOTE N8, 23       ; A#3
	REST N16
	VOLUME $02
	DOTTED
	NOTE N8, 23       ; A#3
	REST N16
	VOLUME $01
	NOTE N8, 23       ; A#3
	VOLUME $03
	CONNECT
	NOTE N32, 22      ; A_3
	SLIDE 127
	DOTTED
	CONNECT
	NOTE N16, 23      ; A#3
	SLIDE 0
	NOTE N8, 21       ; G#3
	NOTE N8, 18       ; F_3
	DOTTED
	NOTE N8, 21       ; G#3
	NOTE N8, 23       ; A#3
	REST N16
	VOLUME $02
	DOTTED
	NOTE N8, 23       ; A#3
	REST N16
	VOLUME $01
	DOTTED
	NOTE N8, 23       ; A#3
	REST N16
	VOLUME $03
	NOTE N16, 23      ; A#3
	NOTE N16, 25      ; C_4
	DOTTED
	NOTE N8, 26       ; C#4
	NOTE N8, 28       ; D#4
	VOLUME $02
	NOTE N16, 28      ; D#4
	VOLUME $03
	NOTE N8, 26       ; C#4
	DOTTED
	NOTE N8, 25       ; C_4
	NOTE N8, 21       ; G#3
	VOLUME $02
	NOTE N16, 21      ; G#3
	VOLUME $03
	NOTE N8, 18       ; F_3
	DOTTED
	NOTE N8, 21       ; G#3
	NOTE N8, 23       ; A#3
	REST N16
	VOLUME $02
	DOTTED
	NOTE N8, 23       ; A#3
	REST N16
	VOLUME $01
	DOTTED
	NOTE N8, 23       ; A#3
	DOTTED
	REST N8
.l600C:
	FLAGS $00
	VOLUME $03
	HOLD 230
	NOTE N8, 23       ; A#3
	NOTE N8, 23       ; A#3
	NOTE N16, 23      ; A#3
	OCTUP
	NOTE N16, 11      ; A#4
	VOLUME $02
	NOTE N16, 11      ; A#4
	VOLUME $03
	DOTTED
	OCTUP
	NOTE N8, 23       ; A#3
	NOTE N8, 23       ; A#3
	NOTE N8, 21       ; G#3
	NOTE N8, 18       ; F_3
	NOTE N8, 21       ; G#3
	NOTE N8, 21       ; G#3
	NOTE N8, 21       ; G#3
	NOTE N8, 23       ; A#3
	NOTE N8, 23       ; A#3
	NOTE N8, 23       ; A#3
	NOTE N16, 23      ; A#3
	DOTTED
	NOTE N8, 22       ; A_3
	NOTE N8, 19       ; F#3
	VOLUME $02
	NOTE N16, 19      ; F#3
	VOLUME $03
	NOTE N8, 19       ; F#3
	VOLUME $02
	NOTE N16, 19      ; F#3
	VOLUME $03
	NOTE N8, 19       ; F#3
	NOTE N8, 21       ; G#3
	VOLUME $02
	NOTE N16, 21      ; G#3
	VOLUME $03
	NOTE N8, 21       ; G#3
	VOLUME $02
	NOTE N16, 21      ; G#3
	VOLUME $03
	NOTE N8, 21       ; G#3
	BREAK1 $00, .l6068
	VOLUME $03
	CONNECT
	NOTE N8, 16       ; D#3
	CONNECT
	NOTE N32, 16      ; D#3
	VOLUME $02
	NOTE N32, 16      ; D#3
	VOLUME $03
	CONNECT
	NOTE N8, 14       ; C#3
	CONNECT
	NOTE N32, 14      ; C#3
	VOLUME $02
	NOTE N32, 14      ; C#3
	VOLUME $03
	NOTE N4, 18       ; F_3
	VOLUME $02
	NOTE N4, 18       ; F_3
	VOLUME $01
	NOTE N8, 18       ; F_3
	LOOP1 1, .l600C
.l6068:
	VOLUME $03
	NOTE N8, 28       ; D#4
	VOLUME $02
	NOTE N16, 28      ; D#4
	VOLUME $03
	NOTE N8, 21       ; G#3
	VOLUME $02
	NOTE N16, 21      ; G#3
	VOLUME $03
	DOTTED
	NOTE N8, 23       ; A#3
	REST N16
	VOLUME $02
	NOTE N8, 23       ; A#3
	VOLUME $03
	NOTE N4, 21       ; G#3
	NOTE N8, 19       ; F#3
	NOTE N8, 19       ; F#3
	NOTE N16, 19      ; F#3
	NOTE N16, 31      ; F#4
	VOLUME $02
	NOTE N16, 31      ; F#4
	VOLUME $03
	NOTE N16, 19      ; F#3
	NOTE N8, 21       ; G#3
	NOTE N8, 21       ; G#3
	NOTE N16, 21      ; G#3
	OCTUP
	NOTE N16, 9       ; G#4
	VOLUME $02
	NOTE N16, 9       ; G#4
	VOLUME $03
	OCTUP
	NOTE N16, 21      ; G#3
	NOTE N16, 18      ; F_3
	VOLUME $02
	NOTE N8, 18       ; F_3
	VOLUME $03
	DOTTED
	NOTE N8, 21       ; G#3
	DOTTED
	CONNECT
	NOTE N16, 25      ; C_4
	TRIPLET
	CONNECT
	NOTE N64, 25      ; C_4
	VOLUME $02
	NOTE N32, 25      ; C_4
	VOLUME $03
	TRIPLET
	NOTE N8, 26       ; C#4
	NOTE N16, 25      ; C_4
	DOTTED
	NOTE N8, 23       ; A#3
	NOTE N8, 23       ; A#3
	NOTE N8, 19       ; F#3
	NOTE N8, 19       ; F#3
	NOTE N16, 19      ; F#3
	NOTE N16, 31      ; F#4
	VOLUME $02
	NOTE N16, 31      ; F#4
	VOLUME $03
	NOTE N16, 19      ; F#3
	NOTE N8, 21       ; G#3
	NOTE N8, 19       ; F#3
	NOTE N8, 18       ; F_3
	CONNECT
	NOTE N8, 26       ; C#4
	CONNECT
	NOTE N8, 26       ; C#4
	OCTUP
	NOTE N8, 14       ; C#5
	NOTE N8, 2        ; C#4
	NOTE N4, 3        ; D_4
	NOTE N8, 15       ; D_5
	NOTE N8, 3        ; D_4
	NOTE N8, 3        ; D_4
	OCTUP
	NOTE N8, 19       ; F#3
	NOTE N8, 19       ; F#3
	NOTE N16, 19      ; F#3
	NOTE N16, 31      ; F#4
	VOLUME $02
	NOTE N16, 31      ; F#4
	VOLUME $03
	NOTE N16, 19      ; F#3
	NOTE N8, 21       ; G#3
	NOTE N8, 21       ; G#3
	NOTE N16, 21      ; G#3
	OCTUP
	NOTE N16, 9       ; G#4
	VOLUME $02
	NOTE N16, 9       ; G#4
	VOLUME $03
	OCTUP
	NOTE N16, 21      ; G#3
	NOTE N16, 18      ; F_3
	VOLUME $02
	NOTE N8, 18       ; F_3
	VOLUME $03
	DOTTED
	NOTE N8, 21       ; G#3
	NOTE N8, 25       ; C_4
	NOTE N8, 23       ; A#3
	NOTE N16, 23      ; A#3
	DOTTED
	NOTE N8, 23       ; A#3
	NOTE N8, 23       ; A#3
	NOTE N8, 19       ; F#3
	NOTE N8, 19       ; F#3
	NOTE N16, 19      ; F#3
	NOTE N16, 31      ; F#4
	VOLUME $02
	NOTE N16, 31      ; F#4
	VOLUME $03
	NOTE N16, 19      ; F#3
	NOTE N8, 21       ; G#3
	NOTE N8, 21       ; G#3
	NOTE N8, 21       ; G#3
	CONNECT
	NOTE N8, 18       ; F_3
	CONNECT
	NOTE N8, 18       ; F_3
	NOTE N8, 18       ; F_3
	NOTE N8, 18       ; F_3
	NOTE N8, 18       ; F_3
	NOTE N8, 18       ; F_3
	NOTE N8, 18       ; F_3
	NOTE N8, 18       ; F_3
	NOTE N8, 18       ; F_3
	NOTE N16, 16      ; D#3
	NOTE N16, 16      ; D#3
	VOLUME $02
	NOTE N16, 16      ; D#3
	VOLUME $03
	NOTE N16, 16      ; D#3
	VOLUME $02
	NOTE N16, 16      ; D#3
	VOLUME $03
	NOTE N16, 16      ; D#3
	VOLUME $02
	NOTE N16, 16      ; D#3
	VOLUME $03
	NOTE N16, 16      ; D#3
	NOTE N16, 16      ; D#3
	VOLUME $02
	NOTE N16, 16      ; D#3
	VOLUME $01
	NOTE N16, 16      ; D#3
	CONNECT
	REST N4
	CONNECT
	REST N16
	JUMP Music03_Ch3
	END                ; unreachable
Music03_Ch4:
	FLAGS $00
	TEMPO $0216
	OCTAVE 0
	HOLD 100
.l612F:
	FLAGS $00
	INSTR 5
	VOLUME $0F
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $08
	NOTE N16, 15
	VOLUME $0C
	NOTE N16, 15
	LOOP1 13, .l612F
	INSTR 5
	VOLUME $0F
	NOTE N16, 8
	INSTR 6
	NOTE N16, 10
	NOTE N16, 10
	REST N16
	NOTE N16, 10
	REST N16
	NOTE N16, 10
	NOTE N16, 10
.l6151:
	FLAGS $00
.l6153:
	FLAGS $00
	INSTR 5
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $08
	NOTE N16, 15
	VOLUME $0C
	NOTE N16, 15
	INSTR 6
	VOLUME $0F
	NOTE N16, 10
	REST N16
	INSTR 4
	VOLUME $08
	NOTE N16, 15
	INSTR 5
	VOLUME $0F
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $08
	NOTE N16, 15
	INSTR 5
	VOLUME $0F
	NOTE N16, 8
	INSTR 4
	VOLUME $08
	NOTE N16, 15
	INSTR 6
	VOLUME $0F
	NOTE N16, 10
	REST N16
	INSTR 5
	NOTE N16, 8
	REST N16
	LOOP1 2, .l6153
	BREAK2 $00, .l61AB
	INSTR 6
	NOTE N16, 10
	REST N8
	NOTE N16, 10
	REST N8
	NOTE N16, 10
	REST N16
	INSTR 5
	NOTE N16, 8
	INSTR 6
	NOTE N16, 10
	NOTE N16, 10
	REST N16
	NOTE N16, 10
	REST N16
	NOTE N16, 10
	NOTE N16, 10
	LOOP2 1, .l6151
.l61AB:
	INSTR 6
	NOTE N16, 10
	REST N8
	NOTE N16, 10
	REST N8
	NOTE N16, 10
	REST N16
	REST N4
	NOTE N16, 12
	NOTE N16, 12
	NOTE N16, 12
	REST N16
.l61B8:
	FLAGS $00
	INSTR 5
	VOLUME $0F
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $08
	NOTE N16, 15
	REST N16
	INSTR 6
	VOLUME $0F
	NOTE N16, 10
	REST N16
	INSTR 4
	VOLUME $08
	NOTE N16, 15
	INSTR 5
	VOLUME $0A
	NOTE N16, 8
	VOLUME $0F
	NOTE N16, 8
	INSTR 4
	VOLUME $08
	NOTE N16, 15
	INSTR 5
	VOLUME $0F
	NOTE N16, 8
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	INSTR 6
	VOLUME $0F
	NOTE N16, 10
	REST N16
	INSTR 3
	VOLUME $0A
	NOTE N8, 15
	LOOP1 2, .l61B8
	INSTR 5
	VOLUME $0F
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $08
	NOTE N16, 15
	REST N16
	INSTR 6
	VOLUME $0F
	NOTE N16, 10
	REST N16
	INSTR 4
	VOLUME $08
	NOTE N16, 15
	INSTR 5
	VOLUME $0A
	NOTE N16, 8
	VOLUME $0F
	NOTE N16, 8
	INSTR 4
	VOLUME $08
	NOTE N16, 15
	INSTR 5
	VOLUME $0F
	NOTE N16, 8
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	INSTR 6
	VOLUME $0F
	NOTE N16, 10
	NOTE N16, 10
	NOTE N16, 10
	REST N16
.l622D:
	FLAGS $00
	INSTR 5
	VOLUME $0F
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $08
	NOTE N16, 15
	REST N16
	INSTR 6
	VOLUME $0F
	NOTE N16, 10
	REST N16
	INSTR 4
	VOLUME $08
	NOTE N16, 15
	INSTR 5
	VOLUME $0A
	NOTE N16, 8
	VOLUME $0F
	NOTE N16, 8
	INSTR 4
	VOLUME $08
	NOTE N16, 15
	INSTR 5
	VOLUME $0F
	NOTE N16, 8
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	INSTR 6
	VOLUME $0F
	NOTE N16, 10
	REST N16
	INSTR 3
	VOLUME $0A
	NOTE N8, 15
	LOOP1 3, .l622D
	INSTR 6
	VOLUME $0F
	NOTE N16, 10
	NOTE N16, 10
	REST N16
	NOTE N16, 10
	REST N16
	NOTE N16, 10
	REST N16
	NOTE N16, 10
	NOTE N16, 10
	DOTTED
	REST N8
	REST N4
	JUMP Music03_Ch4
	END                ; unreachable

;; Music $04
Music04:
	db $00
	BEPTR Music04_Ch1
	BEPTR Music04_Ch2
	BEPTR Music04_Ch3
	BEPTR Music04_Ch4
Music04_Ch1:
	FLAGS $00
	TEMPO $0266
	DUTY $40
	HOLD 255
	OCTAVE 1
	INSTR 0
	VOLUME $0E
	NOTE N8, 27       ; D_5
	VOLUME $07
	NOTE N16, 27      ; D_5
	VOLUME $0E
	NOTE N16, 27      ; D_5
	VOLUME $07
	NOTE N8, 27       ; D_5
	VOLUME $0E
	CONNECT
	NOTE N2, 27       ; D_5
	NOTE N8, 27       ; D_5
	INSTR 2
	CONNECT
	NOTE N2, 27       ; D_5
	INSTR 0
	VOLUME $07
	NOTE N8, 27       ; D_5
	VOLUME $0E
	NOTE N4, 27       ; D_5
	NOTE N8, 26       ; C#5
	VOLUME $07
	NOTE N16, 26      ; C#5
	VOLUME $0E
	NOTE N16, 26      ; C#5
	VOLUME $07
	NOTE N8, 26       ; C#5
	VOLUME $0E
	CONNECT
	NOTE N2, 26       ; C#5
	NOTE N8, 26       ; C#5
	INSTR 2
	DOTTED
	CONNECT
	NOTE N2, 26       ; C#5
	INSTR 0
	VOLUME $07
	NOTE N8, 26       ; C#5
	VOLUME $0E
	CONNECT
	OCTUP
	NOTE N2, 9        ; G#5
	NOTE N8, 9        ; G#5
	INSTR 2
	CONNECT
	NOTE N4, 9        ; G#5
	INSTR 0
	VOLUME $07
	NOTE N8, 9        ; G#5
	VOLUME $0E
	CONNECT
	NOTE N2, 8        ; G_5
	INSTR 2
	CONNECT
	NOTE N4, 8        ; G_5
	INSTR 0
	VOLUME $07
	NOTE N8, 8        ; G_5
	VOLUME $0E
	CONNECT
	NOTE N1, 7        ; F#5
	INSTR 2
	DOTTED
	NOTE N2, 7        ; F#5
	CONNECT
	NOTE N16, 7       ; F#5
	INSTR 0
	VOLUME $07
	NOTE N8, 7        ; F#5
	VOLUME $00
	DUTY $00
	NOTE N16, 4       ; D#5
	VOLUME $0E
	SLIDE 127
	NOTE N8, 6        ; F_5
	SLIDE 0
	VOLUME $07
	NOTE N8, 6        ; F_5
	VOLUME $0E
	NOTE N8, 2        ; C#5
	NOTE N8, 4        ; D#5
	VOLUME $07
	NOTE N8, 4        ; D#5
	VOLUME $0E
	NOTE N8, 1        ; C_5
	NOTE N8, 2        ; C#5
	VOLUME $07
	NOTE N8, 2        ; C#5
	VOLUME $0E
	OCTUP
	NOTE N4, 23       ; A#4
	VOLUME $07
	NOTE N8, 23       ; A#4
	VOLUME $0E
	NOTE N8, 25       ; C_5
	VOLUME $07
	NOTE N8, 25       ; C_5
	VOLUME $0E
	NOTE N8, 21       ; G#4
	DOTTED
	CONNECT
	NOTE N8, 23       ; A#4
	CONNECT
	NOTE N32, 23      ; A#4
	VOLUME $08
	NOTE N32, 28      ; D#5
	VOLUME $0E
	NOTE N8, 30       ; F_5
	VOLUME $07
	NOTE N8, 30       ; F_5
	VOLUME $0E
	NOTE N8, 26       ; C#5
	NOTE N8, 28       ; D#5
	VOLUME $07
	NOTE N8, 28       ; D#5
	VOLUME $0E
	NOTE N8, 25       ; C_5
	NOTE N8, 26       ; C#5
	VOLUME $07
	NOTE N8, 26       ; C#5
	VOLUME $0E
	NOTE N4, 23       ; A#4
	VOLUME $07
	DOTTED
	NOTE N16, 23      ; A#4
	VOLUME $0A
	NOTE N32, 23      ; A#4
	VOLUME $0E
	NOTE N8, 25       ; C_5
	VOLUME $07
	NOTE N8, 25       ; C_5
	VOLUME $0E
	NOTE N8, 21       ; G#4
	NOTE N4, 23       ; A#4
	NOTE N16, 26      ; C#5
	VOLUME $07
	NOTE N16, 26      ; C#5
	VOLUME $0E
	NOTE N16, 23      ; A#4
	VOLUME $07
	NOTE N16, 23      ; A#4
	VOLUME $0E
	NOTE N16, 26      ; C#5
	VOLUME $07
	NOTE N16, 26      ; C#5
	VOLUME $0E
	NOTE N4, 30       ; F_5
	NOTE N16, 26      ; C#5
	VOLUME $07
	NOTE N16, 26      ; C#5
	VOLUME $0E
	NOTE N16, 23      ; A#4
	VOLUME $07
	NOTE N16, 23      ; A#4
	VOLUME $0E
	NOTE N16, 26      ; C#5
	VOLUME $07
	NOTE N16, 26      ; C#5
	VOLUME $0E
	NOTE N16, 31      ; F#5
	VOLUME $07
	NOTE N16, 31      ; F#5
	VOLUME $0E
	OCTUP
	NOTE N16, 9       ; G#5
	VOLUME $07
	NOTE N16, 9       ; G#5
	VOLUME $0E
	NOTE N16, 7       ; F#5
	VOLUME $07
	NOTE N16, 7       ; F#5
	VOLUME $0E
	NOTE N4, 6        ; F_5
	VOLUME $07
	NOTE N8, 6        ; F_5
	TRANSP -24
	DUTY $80
	VOLUME $0C
	CONNECT
	NOTE N32, 18      ; F_6
	SLIDE 127
	CONNECT
	NOTE N32, 6       ; F_5
	SLIDE 0
	CONNECT
	NOTE N32, 18      ; F_6
	SLIDE 127
	CONNECT
	NOTE N32, 6       ; F_5
	SLIDE 0
	CONNECT
	NOTE N32, 10      ; A_5
	SLIDE 100
	CONNECT
	OCTUP
	NOTE N16, 22      ; A_4
	TRANSP 0
	SLIDE 0
	VOLUME $00
	DUTY $00
	NOTE N32, 24      ; B_4
	SLIDE 127
	VOLUME $0E
	CONNECT
	NOTE N4, 26       ; C#5
	CONNECT
	NOTE N16, 26      ; C#5
	SLIDE 0
	VOLUME $07
	NOTE N16, 26      ; C#5
	VOLUME $0E
	DOTTED
	CONNECT
	NOTE N4, 23       ; A#4
	INSTR 2
	CONNECT
	NOTE N4, 23       ; A#4
	VOLUME $07
	INSTR 0
	NOTE N8, 23       ; A#4
	VOLUME $0E
	NOTE N32, 25      ; C_5
	NOTE N8, 26       ; C#5
	VOLUME $07
	NOTE N32, 26      ; C#5
	VOLUME $0E
	CONNECT
	NOTE N8, 28       ; D#5
	CONNECT
	NOTE N32, 28      ; D#5
	VOLUME $07
	NOTE N32, 28      ; D#5
	VOLUME $0E
	CONNECT
	NOTE N8, 30       ; F_5
	CONNECT
	NOTE N32, 30      ; F_5
	VOLUME $07
	NOTE N32, 30      ; F_5
	VOLUME $0E
	CONNECT
	NOTE N8, 28       ; D#5
	CONNECT
	NOTE N32, 28      ; D#5
	VOLUME $07
	NOTE N32, 28      ; D#5
	VOLUME $0E
	NOTE N8, 26       ; C#5
	NOTE N8, 25       ; C_5
	CONNECT
	NOTE N2, 21       ; G#4
	INSTR 2
	DOTTED
	CONNECT
	NOTE N4, 21       ; G#4
	VOLUME $07
	INSTR 0
	NOTE N8, 21       ; G#4
	VOLUME $0E
	NOTE N32, 20      ; G_4
	DOTTED
	CONNECT
	NOTE N8, 21       ; G#4
	CONNECT
	NOTE N32, 21      ; G#4
	NOTE N8, 23       ; A#4
	NOTE N8, 25       ; C_5
	NOTE N8, 26       ; C#5
	NOTE N8, 25       ; C_5
	DOTTED
	NOTE N16, 21      ; G#4
	VOLUME $07
	NOTE N32, 21      ; G#4
	VOLUME $0E
	NOTE N8, 21       ; G#4
	NOTE N4, 23       ; A#4
	DOTTED
	CONNECT
	NOTE N8, 19       ; F#4
	CONNECT
	NOTE N32, 19      ; F#4
	VOLUME $07
	NOTE N32, 19      ; F#4
	VOLUME $0E
	NOTE N16, 19      ; F#4
	VOLUME $07
	NOTE N16, 19      ; F#4
	VOLUME $0E
	NOTE N8, 26       ; C#5
	NOTE N8, 23       ; A#4
	NOTE N8, 25       ; C_5
	NOTE N4, 21       ; G#4
	DOTTED
	NOTE N8, 18       ; F_4
	VOLUME $07
	NOTE N16, 18      ; F_4
	VOLUME $0E
	NOTE N16, 13      ; C_4
	VOLUME $07
	NOTE N16, 13      ; C_4
	VOLUME $0E
	NOTE N8, 25       ; C_5
	NOTE N8, 21       ; G#4
	VOLUME $0E
	CONNECT
	NOTE N2, 23       ; A#4
	INSTR 2
	DOTTED
	CONNECT
	NOTE N4, 23       ; A#4
	VOLUME $07
	INSTR 0
	NOTE N8, 23       ; A#4
.l6449:
	FLAGS $40
	DUTY $40
	VOLUME $0C
	NOTE N2, 23       ; A#4
	INSTR 2
	DOTTED
	CONNECT
	NOTE N4, 23       ; A#4
	VOLUME $06
	INSTR 0
	NOTE N8, 23       ; A#4
	LOOP1 2, .l6449
	DUTY $00
	VOLUME $0E
	SLIDE 127
	NOTE N4, 26       ; C#5
	SLIDE 0
	VOLUME $07
	NOTE N8, 26       ; C#5
	VOLUME $0E
	DOTTED
	CONNECT
	NOTE N4, 22       ; A_4
	INSTR 2
	CONNECT
	NOTE N4, 22       ; A_4
	INSTR 0
	VOLUME $07
	NOTE N8, 22       ; A_4
	VOLUME $0E
	DOTTED
	NOTE N8, 26       ; C#5
	DOTTED
	NOTE N8, 27       ; D_5
	DOTTED
	NOTE N8, 29       ; E_5
	DOTTED
	NOTE N8, 30       ; F_5
	OCTUP
	NOTE N8, 8        ; G_5
	SLIDE 127
	NOTE N4, 9        ; G#5
	SLIDE 0
	VOLUME $07
	NOTE N8, 9        ; G#5
	VOLUME $0E
	DOTTED
	CONNECT
	NOTE N4, 4        ; D#5
	INSTR 2
	CONNECT
	NOTE N4, 4        ; D#5
	INSTR 0
	VOLUME $07
	NOTE N8, 4        ; D#5
	VOLUME $0E
	DOTTED
	OCTUP
	NOTE N8, 21       ; G#4
	DOTTED
	NOTE N8, 23       ; A#4
	DOTTED
	NOTE N8, 25       ; C_5
	DOTTED
	NOTE N8, 28       ; D#5
	NOTE N8, 30       ; F_5
	NOTE N8, 30       ; F_5
	OCTUP
	NOTE N16, 8       ; G_5
	NOTE N16, 3       ; D_5
	NOTE N16, 1       ; C_5
	NOTE N8, 8        ; G_5
	NOTE N16, 8       ; G_5
	NOTE N16, 3       ; D_5
	NOTE N16, 1       ; C_5
	NOTE N32, 8       ; G_5
	NOTE N32, 3       ; D_5
	NOTE N32, 1       ; C_5
	NOTE N32, 3       ; D_5
	NOTE N8, 9        ; G#5
	NOTE N16, 9       ; G#5
	NOTE N16, 4       ; D#5
	NOTE N16, 2       ; C#5
	NOTE N8, 9        ; G#5
	NOTE N16, 9       ; G#5
	NOTE N16, 4       ; D#5
	NOTE N16, 2       ; C#5
	NOTE N32, 9       ; G#5
	NOTE N32, 4       ; D#5
	NOTE N32, 2       ; C#5
	NOTE N32, 4       ; D#5
	NOTE N8, 15       ; D_6
	NOTE N16, 15      ; D_6
	NOTE N16, 8       ; G_5
	NOTE N16, 6       ; F_5
	NOTE N16, 8       ; G_5
	NOTE N8, 15       ; D_6
	NOTE N32, 15      ; D_6
	NOTE N32, 8       ; G_5
	NOTE N32, 6       ; F_5
	NOTE N32, 8       ; G_5
	NOTE N32, 6       ; F_5
	NOTE N32, 8       ; G_5
	NOTE N32, 12      ; B_5
	NOTE N32, 15      ; D_6
	NOTE N8, 18       ; F_6
	NOTE N16, 18      ; F_6
	NOTE N16, 13      ; C_6
	NOTE N8, 11       ; A#5
	NOTE N32, 18      ; F_6
	NOTE N32, 13      ; C_6
	NOTE N32, 11      ; A#5
	NOTE N32, 13      ; C_6
	NOTE N16, 9       ; G#5
	NOTE N16, 13      ; C_6
	NOTE N16, 16      ; D#6
	NOTE N16, 18      ; F_6
	CONNECT
	NOTE N2, 20       ; G_6
	INSTR 2
	NOTE N4, 20       ; G_6
	SLIDE 60
	INSTR 0
	NOTE N2, 8        ; G_5
	INSTR 2
	DOTTED
	CONNECT
	NOTE N4, 8        ; G_5
	SLIDE 0
	VOLUME $07
	NOTE N8, 8        ; G_5
	JUMP Music04_Ch1
	END                ; unreachable
Music04_Ch2:
	FLAGS $48
	TEMPO $0266
	DUTY $40
	HOLD 220
	OCTAVE 0
	TRANSP -12
	INSTR 0
	VOLUME $0D
	NOTE N1, 10       ; A_4
	INSTR 2
	CONNECT
	NOTE N2, 10       ; A_4
	VOLUME $06
	INSTR 0
	NOTE N8, 10       ; A_4
	VOLUME $0D
	NOTE N4, 10       ; A_4
	CONNECT
	NOTE N1, 9        ; G#4
	INSTR 2
	CONNECT
	NOTE N2, 9        ; G#4
	VOLUME $06
	INSTR 0
	NOTE N8, 9        ; G#4
	VOLUME $0D
	NOTE N4, 9        ; G#4
	CONNECT
	NOTE N2, 16       ; D#5
	INSTR 2
	DOTTED
	CONNECT
	NOTE N4, 16       ; D#5
	INSTR 0
	VOLUME $06
	NOTE N8, 16       ; D#5
	VOLUME $0D
	CONNECT
	NOTE N2, 15       ; D_5
	INSTR 2
	CONNECT
	NOTE N4, 15       ; D_5
	INSTR 0
	VOLUME $06
	NOTE N8, 15       ; D_5
	VOLUME $0D
	CONNECT
	NOTE N1, 14       ; C#5
	INSTR 2
	CONNECT
	NOTE N1, 14       ; C#5
.l653E:
	FLAGS $08
	VOLUME $0C
	INSTR 0
	DOTTED
	NOTE N4, 9        ; G#4
	DOTTED
	NOTE N4, 9        ; G#4
	NOTE N4, 9        ; G#4
	LOOP1 1, .l653E
.l654D:
	FLAGS $08
	DOTTED
	NOTE N4, 8        ; G_4
	DOTTED
	NOTE N4, 8        ; G_4
	NOTE N4, 8        ; G_4
	LOOP1 1, .l654D
	DOTTED
	NOTE N4, 6        ; F_4
	DOTTED
	NOTE N4, 9        ; G#4
	NOTE N8, 6        ; F_4
	NOTE N8, 9        ; G#4
	NOTE N8, 16       ; D#5
	NOTE N8, 18       ; F_5
	NOTE N8, 16       ; D#5
	NOTE N4, 13       ; C_5
	VOLUME $06
	NOTE N8, 13       ; C_5
	REST N4
	TRANSP 12
	VOLUME $00
	DUTY $00
	DOTTED
	OCTUP
	NOTE N8, 24       ; B_3
	PAN $10
	DETUNE 1
	SLIDE 127
	VOLUME $0A
	CONNECT
	NOTE N4, 26       ; C#4
	CONNECT
	NOTE N16, 26      ; C#4
	SLIDE 0
	REST N16
	DOTTED
	CONNECT
	NOTE N4, 23       ; A#3
	INSTR 2
	CONNECT
	NOTE N4, 23       ; A#3
	INSTR 0
	REST N8
	NOTE N32, 25      ; C_4
	NOTE N8, 26       ; C#4
	REST N32
	CONNECT
	NOTE N8, 28       ; D#4
	CONNECT
	NOTE N32, 28      ; D#4
	REST N32
	CONNECT
	NOTE N8, 30       ; F_4
	CONNECT
	NOTE N32, 30      ; F_4
	REST N32
	CONNECT
	NOTE N8, 28       ; D#4
	CONNECT
	NOTE N32, 28      ; D#4
	REST N32
	NOTE N8, 26       ; C#4
	NOTE N8, 25       ; C_4
	CONNECT
	NOTE N2, 21       ; G#3
	INSTR 2
	DOTTED
	CONNECT
	NOTE N4, 21       ; G#3
	INSTR 0
	REST N8
	NOTE N32, 20      ; G_3
	DOTTED
	CONNECT
	NOTE N8, 21       ; G#3
	CONNECT
	NOTE N32, 21      ; G#3
	NOTE N8, 23       ; A#3
	NOTE N8, 25       ; C_4
	NOTE N8, 26       ; C#4
	NOTE N8, 25       ; C_4
	DOTTED
	NOTE N16, 21      ; G#3
	REST N32
	NOTE N8, 21       ; G#3
	NOTE N4, 23       ; A#3
	DOTTED
	CONNECT
	NOTE N8, 19       ; F#3
	CONNECT
	NOTE N32, 19      ; F#3
	REST N32
	NOTE N16, 19      ; F#3
	REST N16
	NOTE N8, 26       ; C#4
	NOTE N8, 23       ; A#3
	NOTE N8, 25       ; C_4
	NOTE N4, 21       ; G#3
	DOTTED
	NOTE N8, 18       ; F_3
	REST N16
	NOTE N16, 13      ; C_3
	REST N16
	NOTE N16, 25      ; C_4
	TRANSP 0
	DETUNE 0
	PAN $11
	DUTY $40
	VOLUME $0C
	CONNECT
	NOTE N2, 30       ; F_4
	INSTR 2
	DOTTED
	CONNECT
	NOTE N4, 30       ; F_4
	INSTR 0
	REST N8
	CONNECT
	NOTE N2, 31       ; F#4
	INSTR 2
	DOTTED
	CONNECT
	NOTE N4, 31       ; F#4
	INSTR 0
	REST N8
	CONNECT
	OCTUP
	NOTE N2, 8        ; G_4
	INSTR 2
	DOTTED
	CONNECT
	NOTE N4, 8        ; G_4
	INSTR 0
	REST N8
	CONNECT
	NOTE N2, 7        ; F#4
	INSTR 2
	DOTTED
	CONNECT
	NOTE N4, 7        ; F#4
	INSTR 0
	REST N8
	CONNECT
	NOTE N2, 5        ; E_4
	INSTR 2
	CONNECT
	NOTE N2, 5        ; E_4
	INSTR 0
	REST N8
	DOTTED
	NOTE N8, 5        ; E_4
	DOTTED
	NOTE N8, 6        ; F_4
	DOTTED
	NOTE N8, 8        ; G_4
	DOTTED
	NOTE N8, 10       ; A_4
	NOTE N8, 12       ; B_4
	CONNECT
	NOTE N2, 4        ; D#4
	INSTR 2
	CONNECT
	NOTE N2, 4        ; D#4
	INSTR 0
	REST N8
	DOTTED
	NOTE N8, 4        ; D#4
	DOTTED
	NOTE N8, 4        ; D#4
	DOTTED
	NOTE N8, 4        ; D#4
	DOTTED
	NOTE N8, 1        ; C_4
	NOTE N8, 4        ; D#4
.l661E:
	FLAGS $00
	NOTE N2, 27       ; D_4
	REST N8
	NOTE N8, 27       ; D_4
	NOTE N2, 28       ; D#4
	REST N8
	NOTE N8, 28       ; D#4
	LOOP1 1, .l661E
	DOTTED
	CONNECT
	NOTE N2, 27       ; D_4
	INSTR 2
	CONNECT
	NOTE N1, 27       ; D_4
	JUMP Music04_Ch2
	END                ; unreachable
Music04_Ch3:
	FLAGS $08
	TEMPO $0266
	HOLD 255
	OCTAVE 0
	TRANSP -12
	INSTR 1
	VOLUME $03
	NOTE N8, 15       ; D_5
	REST N16
	NOTE N16, 15      ; D_5
	REST N8
	CONNECT
	NOTE N2, 15       ; D_5
	NOTE N8, 15       ; D_5
	DOTTED
	CONNECT
	NOTE N2, 15       ; D_5
	REST N8
	NOTE N8, 14       ; C#5
	REST N16
	NOTE N16, 14      ; C#5
	REST N8
	CONNECT
	NOTE N2, 14       ; C#5
	NOTE N8, 14       ; C#5
	DOTTED
	CONNECT
	NOTE N2, 14       ; C#5
	REST N8
	NOTE N8, 13       ; C_5
	REST N16
	NOTE N16, 13      ; C_5
	REST N8
	NOTE N2, 13       ; C_5
	REST N8
	NOTE N8, 12       ; B_4
	REST N16
	NOTE N16, 12      ; B_4
	REST N8
	DOTTED
	NOTE N4, 12       ; B_4
	REST N8
	NOTE N8, 11       ; A#4
	REST N16
	NOTE N16, 11      ; A#4
	REST N8
	CONNECT
	NOTE N2, 11       ; A#4
	CONNECT
	NOTE N8, 11       ; A#4
	REST N8
	HOLD 230
	NOTE N8, 11       ; A#4
	NOTE N8, 11       ; A#4
	NOTE N8, 11       ; A#4
	NOTE N8, 11       ; A#4
	NOTE N8, 11       ; A#4
	NOTE N8, 11       ; A#4
	NOTE N8, 11       ; A#4
.l6679:
	FLAGS $08
	DOTTED
	NOTE N8, 11       ; A#4
	NOTE N16, 11      ; A#4
	NOTE N16, 11      ; A#4
	REST N16
	NOTE N4, 11       ; A#4
	NOTE N16, 11      ; A#4
	REST N16
	NOTE N8, 11       ; A#4
	NOTE N8, 11       ; A#4
	LOOP1 1, .l6679
.l6689:
	FLAGS $08
	DOTTED
	NOTE N8, 16       ; D#5
	NOTE N16, 16      ; D#5
	NOTE N16, 16      ; D#5
	REST N16
	NOTE N4, 16       ; D#5
	NOTE N16, 16      ; D#5
	REST N16
	NOTE N8, 16       ; D#5
	NOTE N8, 16       ; D#5
	LOOP1 1, .l6689
	DOTTED
	NOTE N8, 14       ; C#5
	NOTE N16, 14      ; C#5
	NOTE N16, 14      ; C#5
	REST N16
	NOTE N4, 14       ; C#5
	NOTE N16, 14      ; C#5
	REST N16
	NOTE N8, 14       ; C#5
	NOTE N8, 14       ; C#5
.l66A3:
	FLAGS $08
	NOTE N16, 13      ; C_5
	REST N16
	LOOP1 2, .l66A3
	DOTTED
	NOTE N8, 18       ; F_5
	REST N8
	REST N16
	SLIDE 127
	NOTE N4, 6        ; F_4
	SLIDE 0
.l66B4:
	FLAGS $08
	DOTTED
	NOTE N8, 11       ; A#4
	NOTE N16, 11      ; A#4
	NOTE N16, 11      ; A#4
	REST N16
	NOTE N4, 11       ; A#4
	NOTE N16, 11      ; A#4
	REST N16
	NOTE N8, 11       ; A#4
	NOTE N8, 11       ; A#4
	LOOP1 1, .l66B4
.l66C4:
	FLAGS $08
	DOTTED
	NOTE N8, 9        ; G#4
	NOTE N16, 9       ; G#4
	NOTE N16, 9       ; G#4
	REST N16
	NOTE N4, 9        ; G#4
	NOTE N16, 9       ; G#4
	REST N16
	NOTE N8, 9        ; G#4
	NOTE N8, 9        ; G#4
	LOOP1 1, .l66C4
	DOTTED
	NOTE N8, 7        ; F#4
	NOTE N16, 7       ; F#4
	NOTE N16, 7       ; F#4
	REST N16
	NOTE N4, 7        ; F#4
	NOTE N16, 7       ; F#4
	REST N16
	NOTE N8, 7        ; F#4
	NOTE N8, 7        ; F#4
	DOTTED
	NOTE N8, 9        ; G#4
	NOTE N16, 9       ; G#4
	NOTE N16, 9       ; G#4
	REST N16
	NOTE N4, 9        ; G#4
	NOTE N16, 9       ; G#4
	REST N16
	NOTE N8, 9        ; G#4
	NOTE N8, 9        ; G#4
.l66E8:
	FLAGS $08
	DOTTED
	NOTE N8, 11       ; A#4
	NOTE N16, 11      ; A#4
	NOTE N16, 11      ; A#4
	REST N16
	NOTE N4, 11       ; A#4
	NOTE N16, 11      ; A#4
	REST N16
	NOTE N8, 11       ; A#4
	NOTE N8, 11       ; A#4
	LOOP1 3, .l66E8
	TRANSP -24
.l66FA:
	FLAGS $08
	NOTE N8, 10       ; A_4
	NOTE N32, 10      ; A_4
	REST N32
	NOTE N32, 10      ; A_4
	REST N32
	NOTE N32, 10      ; A_4
	REST N32
	REST N16
	NOTE N4, 22       ; A_5
	NOTE N16, 22      ; A_5
	REST N16
	NOTE N8, 17       ; E_5
	NOTE N8, 10       ; A_4
	LOOP1 1, .l66FA
.l670D:
	FLAGS $08
	NOTE N8, 9        ; G#4
	NOTE N32, 9       ; G#4
	REST N32
	NOTE N32, 9       ; G#4
	REST N32
	NOTE N32, 9       ; G#4
	REST N32
	REST N16
	NOTE N4, 21       ; G#5
	NOTE N16, 21      ; G#5
	REST N16
	NOTE N8, 16       ; D#5
	NOTE N8, 9        ; G#4
	LOOP1 1, .l670D
.l6720:
	FLAGS $08
	DOTTED
	NOTE N8, 8        ; G_4
	NOTE N16, 8       ; G_4
	NOTE N8, 20       ; G_5
	NOTE N32, 20      ; G_5
	REST N32
	NOTE N16, 20      ; G_5
	NOTE N32, 20      ; G_5
	REST N32
	NOTE N16, 20      ; G_5
	NOTE N8, 8        ; G_4
	DOTTED
	NOTE N8, 9        ; G#4
	NOTE N16, 9       ; G#4
	NOTE N8, 21       ; G#5
	NOTE N32, 21      ; G#5
	REST N32
	NOTE N16, 21      ; G#5
	NOTE N32, 21      ; G#5
	REST N32
	NOTE N16, 21      ; G#5
	NOTE N8, 9        ; G#4
	LOOP1 1, .l6720
	DOTTED
	NOTE N8, 8        ; G_4
	NOTE N16, 8       ; G_4
	NOTE N8, 20       ; G_5
	NOTE N32, 20      ; G_5
	REST N32
	NOTE N16, 20      ; G_5
	NOTE N32, 20      ; G_5
	REST N32
	NOTE N16, 20      ; G_5
	NOTE N8, 8        ; G_4
	DOTTED
	NOTE N8, 8        ; G_4
	NOTE N16, 8       ; G_4
	NOTE N8, 20       ; G_5
	NOTE N32, 20      ; G_5
	REST N32
	NOTE N16, 20      ; G_5
	NOTE N32, 20      ; G_5
	REST N32
	NOTE N16, 20      ; G_5
	NOTE N8, 8        ; G_4
	NOTE N4, 8        ; G_4
	JUMP Music04_Ch3
	END                ; unreachable
Music04_Ch4:
	FLAGS $00
	TEMPO $0266
	OCTAVE 0
	HOLD 100
.l6760:
	FLAGS $00
	VOLUME $0F
	INSTR 8
	NOTE N8, 12
	REST N4
	REST N2
	HOLD 1
	INSTR 4
	VOLUME $0F
	NOTE N16, 15
	VOLUME $0A
	NOTE N16, 15
	VOLUME $0F
	NOTE N16, 15
	REST N16
	VOLUME $0A
	NOTE N16, 15
	VOLUME $0C
	NOTE N16, 15
	VOLUME $0F
	NOTE N16, 15
	VOLUME $0C
	NOTE N16, 15
	REST N16
	VOLUME $0F
	NOTE N16, 15
	VOLUME $0C
	NOTE N16, 15
	REST N16
	VOLUME $0F
	NOTE N16, 15
	REST N16
	VOLUME $0C
	NOTE N16, 15
	REST N16
	LOOP1 1, .l6760
	VOLUME $0F
	INSTR 8
	NOTE N8, 12
	REST N4
	REST N2
	INSTR 4
	VOLUME $0F
	NOTE N16, 15
	VOLUME $0A
	NOTE N16, 15
	VOLUME $0F
	INSTR 8
	NOTE N8, 12
	REST N4
	INSTR 4
	NOTE N16, 15
	REST N16
	VOLUME $0A
	NOTE N16, 15
	VOLUME $0C
	NOTE N16, 15
	VOLUME $0F
	NOTE N16, 15
	VOLUME $0C
	NOTE N16, 15
	REST N16
	VOLUME $0F
	NOTE N16, 15
	VOLUME $0F
	INSTR 8
	NOTE N8, 12
	REST N4
	INSTR 4
	VOLUME $0F
	NOTE N16, 15
	REST N16
	VOLUME $0A
	NOTE N16, 15
	VOLUME $0C
	NOTE N16, 15
	VOLUME $0F
	NOTE N16, 15
	VOLUME $0C
	NOTE N16, 15
	REST N16
	VOLUME $0F
	NOTE N16, 15
	VOLUME $0C
	NOTE N16, 15
	REST N16
	VOLUME $0F
	NOTE N16, 15
	REST N16
	VOLUME $0C
	NOTE N16, 15
	REST N16
	INSTR 6
	VOLUME $0A
	NOTE N16, 10
	NOTE N16, 10
	VOLUME $0B
	NOTE N16, 10
	NOTE N16, 10
	VOLUME $0C
	NOTE N16, 10
	NOTE N16, 10
	VOLUME $0D
	NOTE N16, 10
	NOTE N16, 10
	VOLUME $0E
	NOTE N16, 10
	NOTE N16, 10
	VOLUME $0F
	NOTE N16, 10
	NOTE N16, 10
.l6802:
	FLAGS $00
	VOLUME $0F
	INSTR 5
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	VOLUME $07
	NOTE N16, 15
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	REST N16
	VOLUME $0F
	INSTR 5
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	VOLUME $07
	NOTE N16, 15
	VOLUME $0F
	INSTR 5
	NOTE N16, 8
	REST N16
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	REST N16
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	VOLUME $07
	NOTE N16, 15
	LOOP1 4, .l6802
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	REST N16
	NOTE N16, 10
	REST N16
	NOTE N16, 10
	REST N16
	INSTR 8
	NOTE N8, 12
	REST N4
	NOTE N16, 10
	NOTE N16, 10
	NOTE N16, 10
	REST N16
.l6850:
	FLAGS $00
	VOLUME $0F
	INSTR 5
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	VOLUME $07
	NOTE N16, 15
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	REST N16
	VOLUME $0F
	INSTR 5
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	VOLUME $07
	NOTE N16, 15
	VOLUME $0F
	INSTR 5
	NOTE N16, 8
	REST N16
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	REST N16
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	VOLUME $07
	NOTE N16, 15
	LOOP1 5, .l6850
.l688C:
	FLAGS $00
	VOLUME $0F
	INSTR 8
	NOTE N8, 12
	REST N8
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	REST N16
	VOLUME $0F
	INSTR 5
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	VOLUME $07
	NOTE N16, 15
	VOLUME $0F
	INSTR 5
	NOTE N16, 8
	REST N16
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	REST N16
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	VOLUME $07
	NOTE N16, 15
	LOOP1 4, .l688C
.l68C0:
	FLAGS $00
	VOLUME $0F
	INSTR 5
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	VOLUME $07
	NOTE N16, 15
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	REST N16
	VOLUME $0F
	INSTR 5
	NOTE N16, 8
	REST N16
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	VOLUME $07
	NOTE N16, 15
	VOLUME $0F
	INSTR 5
	NOTE N16, 8
	REST N16
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	REST N16
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	VOLUME $07
	NOTE N16, 15
	LOOP1 2, .l68C0
.l68FC:
	FLAGS $00
	VOLUME $0F
	INSTR 8
	NOTE N8, 12
	REST N8
	INSTR 6
	NOTE N16, 10
	REST N16
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	REST N16
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	REST N16
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	REST N16
	LOOP1 3, .l68FC
	VOLUME $0F
	INSTR 8
	NOTE N8, 12
	REST N8
	INSTR 6
	VOLUME $0C
	TRIPLET
	NOTE N16, 10
	VOLUME $06
	NOTE N16, 10
	VOLUME $0C
	NOTE N16, 10
	VOLUME $0F
	NOTE N16, 10
	REST N8
	VOLUME $0C
	NOTE N16, 8
	VOLUME $06
	NOTE N16, 8
	VOLUME $0C
	NOTE N16, 8
	VOLUME $0F
	NOTE N16, 8
	REST N8
	VOLUME $0F
	INSTR 8
	TRIPLET
	NOTE N8, 12
	REST N8
	INSTR 6
	NOTE N16, 10
	REST N16
	REST N8
	NOTE N16, 10
	REST N16
	NOTE N16, 10
	REST N16
	NOTE N16, 10
	VOLUME $0B
	NOTE N16, 10
	VOLUME $0F
	NOTE N16, 10
	VOLUME $0B
	NOTE N16, 10
	JUMP Music04_Ch4
	END                ; unreachable

;; Music $05
Music05:
	db $00
	BEPTR Music05_Ch1
	BEPTR Music05_Ch2
	BEPTR Music05_Ch3
	BEPTR Music05_Ch4
Music05_Ch1:
	TEMPO $0180
	DUTY $00
	HOLD 255
	OCTAVE 1
	INSTR 10
	VOLUME $0C
	NOTE N32, 24      ; B_4
	VOLUME $0D
	CONNECT
	NOTE N4, 25       ; C_5
	INSTR 2
	CONNECT
	NOTE N4, 25       ; C_5
	VOLUME $06
	INSTR 0
	DOTTED
	NOTE N16, 25      ; C_5
	INSTR 10
	VOLUME $0C
	NOTE N32, 22      ; A_4
	VOLUME $0D
	DOTTED
	CONNECT
	NOTE N16, 24      ; B_4
	NOTE N8, 24       ; B_4
	NOTE N32, 24      ; B_4
	INSTR 2
	CONNECT
	NOTE N4, 24       ; B_4
	VOLUME $06
	INSTR 0
	DOTTED
	NOTE N16, 24      ; B_4
	INSTR 10
	VOLUME $0D
	TRIPLET
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	TRIPLET
	NOTE N16, 24      ; B_4
	VOLUME $0D
	NOTE N32, 18      ; F_4
	CONNECT
	NOTE N8, 20       ; G_4
	NOTE N32, 20      ; G_4
	INSTR 2
	DOTTED
	NOTE N2, 20       ; G_4
	TEMPO $01D8
	INSTR 7
	DOTTED
	CONNECT
	NOTE N2, 20       ; G_4
.l69C5:
	FLAGS $00
	TEMPO $01D8
	SLIDE 0
	INSTR 0
	VOLUME $06
	DOTTED
	NOTE N8, 20       ; G_4
	DUTY $80
	VOLUME $0F
	NOTE N16, 18      ; F_4
	NOTE N16, 20      ; G_4
	NOTE N16, 30      ; F_5
	DOTTED
	NOTE N8, 29       ; E_5
	DOTTED
	NOTE N8, 27       ; D_5
	NOTE N16, 25      ; C_5
	NOTE N16, 27      ; D_5
	NOTE N16, 23      ; A#4
	NOTE N16, 22      ; A_4
	NOTE N16, 23      ; A#4
	NOTE N16, 25      ; C_5
	NOTE N16, 20      ; G_4
	NOTE N16, 18      ; F_4
	NOTE N16, 19      ; F#4
	NOTE N16, 20      ; G_4
	NOTE N16, 23      ; A#4
	NOTE N16, 20      ; G_4
	NOTE N16, 23      ; A#4
	NOTE N16, 15      ; D_4
	NOTE N16, 18      ; F_4
	DOTTED
	NOTE N8, 23       ; A#4
	NOTE N16, 23      ; A#4
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 17      ; E_4
	NOTE N16, 18      ; F_4
	NOTE N16, 19      ; F#4
	NOTE N8, 20       ; G_4
	NOTE N8, 18       ; F_4
	NOTE N16, 20      ; G_4
	NOTE N16, 30      ; F_5
	DOTTED
	NOTE N8, 29       ; E_5
	DOTTED
	NOTE N8, 27       ; D_5
	NOTE N8, 25       ; C_5
	NOTE N8, 27       ; D_5
	NOTE N8, 23       ; A#4
	NOTE N8, 22       ; A_4
	NOTE N8, 23       ; A#4
	NOTE N8, 25       ; C_5
	NOTE N16, 27      ; D_5
	NOTE N16, 20      ; G_4
	NOTE N16, 30      ; F_5
	OCTUP
	NOTE N8, 8        ; G_5
	NOTE N16, 11      ; A#5
	NOTE N16, 10      ; A_5
	NOTE N16, 1       ; C_5
	NOTE N16, 3       ; D_5
	NOTE N16, 8       ; G_5
	NOTE N16, 6       ; F_5
	NOTE N16, 7       ; F#5
	CONNECT
	NOTE N2, 8        ; G_5
	INSTR 2
	CONNECT
	NOTE N4, 8        ; G_5
	INSTR 0
	VOLUME $07
	NOTE N8, 8        ; G_5
	VOLUME $0A
	NOTE N32, 4       ; D#5
	VOLUME $0F
	DOTTED
	CONNECT
	NOTE N8, 6        ; F_5
	CONNECT
	NOTE N32, 6       ; F_5
	NOTE N8, 1        ; C_5
	DOTTED
	NOTE N8, 3        ; D_5
	OCTUP
	NOTE N16, 23      ; A#4
	CONNECT
	NOTE N4, 26       ; C#5
	INSTR 2
	NOTE N4, 26       ; C#5
	CONNECT
	NOTE N16, 26      ; C#5
	INSTR 0
	VOLUME $07
	DOTTED
	NOTE N8, 26       ; C#5
	VOLUME $0F
	NOTE N16, 27      ; D_5
	NOTE N16, 25      ; C_5
	OCTUP
	NOTE N16, 8       ; G_5
	NOTE N16, 6       ; F_5
	NOTE N16, 3       ; D_5
	NOTE N16, 1       ; C_5
	NOTE N16, 3       ; D_5
	OCTUP
	NOTE N16, 23      ; A#4
	NOTE N16, 27      ; D_5
	NOTE N16, 25      ; C_5
	NOTE N16, 27      ; D_5
	NOTE N16, 23      ; A#4
	CONNECT
	OCTUP
	NOTE N2, 10       ; A_5
	INSTR 2
	CONNECT
	NOTE N4, 10       ; A_5
	VOLUME $07
	INSTR 0
	NOTE N8, 10       ; A_5
	VOLUME $0A
	OCTUP
	NOTE N32, 21      ; G#4
	VOLUME $0F
	CONNECT
	NOTE N8, 23       ; A#4
	CONNECT
	NOTE N32, 23      ; A#4
	NOTE N16, 20      ; G_4
	NOTE N8, 18       ; F_4
	NOTE N8, 17       ; E_4
	NOTE N8, 18       ; F_4
	CONNECT
	NOTE N4, 17       ; E_4
	NOTE N16, 17      ; E_4
	INSTR 2
	CONNECT
	NOTE N4, 17       ; E_4
	INSTR 0
	NOTE N16, 15      ; D_4
	NOTE N16, 17      ; E_4
	NOTE N16, 13      ; C_4
	NOTE N16, 20      ; G_4
	NOTE N16, 18      ; F_4
	NOTE N16, 20      ; G_4
	NOTE N16, 23      ; A#4
	NOTE N16, 20      ; G_4
	NOTE N16, 23      ; A#4
	NOTE N16, 25      ; C_5
	NOTE N16, 23      ; A#4
	NOTE N16, 25      ; C_5
	NOTE N16, 27      ; D_5
	NOTE N16, 25      ; C_5
	NOTE N16, 27      ; D_5
	OCTUP
	NOTE N16, 8       ; G_5
	VOLUME $0A
	NOTE N16, 8       ; G_5
	VOLUME $0F
	NOTE N16, 11      ; A#5
	VOLUME $0A
	NOTE N16, 11      ; A#5
	VOLUME $0F
	NOTE N16, 13      ; C_6
	VOLUME $0A
	NOTE N16, 13      ; C_6
	VOLUME $0F
	NOTE N16, 15      ; D_6
	VOLUME $0A
	NOTE N16, 15      ; D_6
	VOLUME $0F
	NOTE N16, 18      ; F_6
	VOLUME $0A
	NOTE N16, 18      ; F_6
	VOLUME $0F
	NOTE N16, 19      ; F#6
	VOLUME $0A
	NOTE N16, 19      ; F#6
	VOLUME $0F
	CONNECT
	NOTE N4, 20       ; G_6
	NOTE N16, 20      ; G_6
	INSTR 2
	CONNECT
	NOTE N4, 20       ; G_6
	INSTR 0
	VOLUME $07
	DOTTED
	NOTE N8, 20       ; G_6
	VOLUME $0F
	NOTE N16, 11      ; A#5
	NOTE N16, 6       ; F_5
	NOTE N16, 3       ; D_5
	NOTE N16, 11      ; A#5
	NOTE N16, 6       ; F_5
	NOTE N16, 3       ; D_5
	NOTE N16, 11      ; A#5
	NOTE N16, 6       ; F_5
	NOTE N16, 3       ; D_5
	NOTE N16, 11      ; A#5
	NOTE N16, 6       ; F_5
	NOTE N16, 3       ; D_5
	NOTE N16, 10      ; A_5
	NOTE N16, 5       ; E_5
	NOTE N16, 2       ; C#5
	NOTE N16, 10      ; A_5
	NOTE N16, 5       ; E_5
	NOTE N16, 2       ; C#5
	NOTE N16, 9       ; G#5
	NOTE N16, 4       ; D#5
	NOTE N16, 1       ; C_5
	NOTE N16, 9       ; G#5
	NOTE N16, 4       ; D#5
	NOTE N16, 1       ; C_5
	DOTTED
	CONNECT
	NOTE N4, 8        ; G_5
	NOTE N16, 8       ; G_5
	INSTR 2
	NOTE N4, 8        ; G_5
	CONNECT
	NOTE N16, 8       ; G_5
	VOLUME $07
	INSTR 0
	NOTE N8, 8        ; G_5
	VOLUME $0F
	OCTUP
	NOTE N8, 18       ; F_4
	NOTE N8, 19       ; F#4
	NOTE N8, 20       ; G_4
	NOTE N8, 23       ; A#4
	NOTE N8, 25       ; C_5
	CONNECT
	NOTE N4, 27       ; D_5
	INSTR 2
	CONNECT
	NOTE N4, 27       ; D_5
	INSTR 0
	VOLUME $07
	NOTE N8, 27       ; D_5
	VOLUME $0F
	NOTE N8, 29       ; E_5
	NOTE N8, 30       ; F_5
	TRIPLET
	NOTE N16, 29      ; E_5
	NOTE N16, 30      ; F_5
	NOTE N16, 29      ; E_5
	TRIPLET
	NOTE N8, 27       ; D_5
	NOTE N8, 29       ; E_5
	NOTE N4, 25       ; C_5
	NOTE N8, 25       ; C_5
	NOTE N32, 25      ; C_5
	CONNECT
	NOTE N4, 27       ; D_5
	INSTR 2
	CONNECT
	NOTE N4, 27       ; D_5
	INSTR 0
	VOLUME $07
	DOTTED
	NOTE N16, 27      ; D_5
	VOLUME $0F
	NOTE N32, 24      ; B_4
	CONNECT
	NOTE N4, 25       ; C_5
	INSTR 2
	CONNECT
	NOTE N4, 25       ; C_5
	INSTR 0
	VOLUME $07
	DOTTED
	NOTE N16, 25      ; C_5
	VOLUME $0F
	NOTE N32, 20      ; G_4
	DOTTED
	CONNECT
	NOTE N16, 24      ; B_4
	NOTE N8, 24       ; B_4
	NOTE N32, 24      ; B_4
	INSTR 2
	CONNECT
	NOTE N4, 24       ; B_4
	INSTR 0
	VOLUME $07
	DOTTED
	NOTE N16, 24      ; B_4
	VOLUME $0F
	TRIPLET
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	TRIPLET
	NOTE N16, 24      ; B_4
	DOTTED
	CONNECT
	NOTE N8, 20       ; G_4
	INSTR 2
	DOTTED
	CONNECT
	NOTE N2, 20       ; G_4
	JUMP .l69C5
	END                ; unreachable
Music05_Ch2:
	TEMPO $0180
	DUTY $00
	PAN $10
	HOLD 255
	OCTAVE 1
	DETUNE 2
	DOTTED
	REST N8
	INSTR 10
	VOLUME $08
	NOTE N32, 24      ; B_4
	VOLUME $09
	CONNECT
	NOTE N4, 25       ; C_5
	INSTR 2
	CONNECT
	NOTE N4, 25       ; C_5
	VOLUME $04
	INSTR 0
	DOTTED
	NOTE N16, 25      ; C_5
	INSTR 10
	VOLUME $08
	NOTE N32, 22      ; A_4
	VOLUME $09
	DOTTED
	CONNECT
	NOTE N16, 24      ; B_4
	NOTE N8, 24       ; B_4
	NOTE N32, 24      ; B_4
	INSTR 2
	CONNECT
	NOTE N4, 24       ; B_4
	VOLUME $04
	INSTR 0
	DOTTED
	NOTE N16, 24      ; B_4
	INSTR 10
	VOLUME $09
	TRIPLET
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	TRIPLET
	NOTE N16, 24      ; B_4
	NOTE N32, 18      ; F_4
	CONNECT
	NOTE N8, 20       ; G_4
	NOTE N32, 20      ; G_4
	INSTR 2
	DOTTED
	NOTE N2, 20       ; G_4
	TEMPO $01D8
	INSTR 7
	DOTTED
	CONNECT
	NOTE N2, 20       ; G_4
.l6BA3:
	FLAGS $00
	TEMPO $01D8
	SLIDE 0
	INSTR 0
	VOLUME $04
	DOTTED
	NOTE N8, 20       ; G_4
	DUTY $80
	VOLUME $09
	NOTE N16, 18      ; F_4
	NOTE N16, 20      ; G_4
	NOTE N16, 30      ; F_5
	DOTTED
	NOTE N8, 29       ; E_5
	DOTTED
	NOTE N8, 27       ; D_5
	NOTE N16, 25      ; C_5
	NOTE N16, 27      ; D_5
	NOTE N16, 23      ; A#4
	NOTE N16, 22      ; A_4
	NOTE N16, 23      ; A#4
	NOTE N16, 25      ; C_5
	NOTE N16, 20      ; G_4
	NOTE N16, 18      ; F_4
	NOTE N16, 19      ; F#4
	NOTE N16, 20      ; G_4
	NOTE N16, 23      ; A#4
	NOTE N16, 20      ; G_4
	NOTE N16, 23      ; A#4
	NOTE N16, 15      ; D_4
	NOTE N16, 18      ; F_4
	DOTTED
	NOTE N8, 23       ; A#4
	NOTE N16, 23      ; A#4
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 17      ; E_4
	NOTE N16, 18      ; F_4
	NOTE N16, 19      ; F#4
	NOTE N8, 20       ; G_4
	NOTE N8, 18       ; F_4
	NOTE N16, 20      ; G_4
	NOTE N16, 30      ; F_5
	DOTTED
	NOTE N8, 29       ; E_5
	DOTTED
	NOTE N8, 27       ; D_5
	NOTE N8, 25       ; C_5
	NOTE N8, 27       ; D_5
	NOTE N8, 23       ; A#4
	NOTE N8, 22       ; A_4
	NOTE N8, 23       ; A#4
	NOTE N8, 25       ; C_5
	NOTE N16, 27      ; D_5
	NOTE N16, 20      ; G_4
	NOTE N16, 30      ; F_5
	OCTUP
	NOTE N8, 8        ; G_5
	NOTE N16, 11      ; A#5
	NOTE N16, 10      ; A_5
	NOTE N16, 1       ; C_5
	NOTE N16, 3       ; D_5
	NOTE N16, 8       ; G_5
	NOTE N16, 6       ; F_5
	NOTE N16, 7       ; F#5
	CONNECT
	NOTE N2, 8        ; G_5
	INSTR 2
	CONNECT
	NOTE N4, 8        ; G_5
	INSTR 0
	VOLUME $04
	NOTE N8, 8        ; G_5
	VOLUME $05
	NOTE N32, 4       ; D#5
	VOLUME $09
	DOTTED
	CONNECT
	NOTE N8, 6        ; F_5
	CONNECT
	NOTE N32, 6       ; F_5
	NOTE N8, 1        ; C_5
	DOTTED
	NOTE N8, 3        ; D_5
	OCTUP
	NOTE N16, 23      ; A#4
	CONNECT
	NOTE N4, 26       ; C#5
	INSTR 2
	NOTE N4, 26       ; C#5
	CONNECT
	NOTE N16, 26      ; C#5
	INSTR 0
	VOLUME $04
	DOTTED
	NOTE N8, 26       ; C#5
	VOLUME $09
	NOTE N16, 27      ; D_5
	NOTE N16, 25      ; C_5
	OCTUP
	NOTE N16, 8       ; G_5
	NOTE N16, 6       ; F_5
	NOTE N16, 3       ; D_5
	NOTE N16, 1       ; C_5
	NOTE N16, 3       ; D_5
	OCTUP
	NOTE N16, 23      ; A#4
	NOTE N16, 27      ; D_5
	NOTE N16, 25      ; C_5
	NOTE N16, 27      ; D_5
	NOTE N16, 23      ; A#4
	CONNECT
	OCTUP
	NOTE N2, 10       ; A_5
	INSTR 2
	CONNECT
	NOTE N4, 10       ; A_5
	VOLUME $04
	INSTR 0
	NOTE N8, 10       ; A_5
	VOLUME $05
	OCTUP
	NOTE N32, 21      ; G#4
	VOLUME $09
	CONNECT
	NOTE N8, 23       ; A#4
	CONNECT
	NOTE N32, 23      ; A#4
	NOTE N16, 20      ; G_4
	NOTE N8, 18       ; F_4
	NOTE N8, 17       ; E_4
	NOTE N8, 18       ; F_4
	CONNECT
	NOTE N4, 17       ; E_4
	NOTE N16, 17      ; E_4
	INSTR 2
	CONNECT
	NOTE N4, 17       ; E_4
	INSTR 0
	NOTE N16, 15      ; D_4
	NOTE N16, 17      ; E_4
	NOTE N16, 13      ; C_4
	NOTE N16, 20      ; G_4
	NOTE N16, 18      ; F_4
	NOTE N16, 20      ; G_4
	NOTE N16, 23      ; A#4
	NOTE N16, 20      ; G_4
	NOTE N16, 23      ; A#4
	NOTE N16, 25      ; C_5
	NOTE N16, 23      ; A#4
	NOTE N16, 25      ; C_5
	NOTE N16, 27      ; D_5
	NOTE N16, 25      ; C_5
	NOTE N16, 27      ; D_5
	OCTUP
	NOTE N16, 8       ; G_5
	VOLUME $05
	NOTE N16, 8       ; G_5
	VOLUME $09
	NOTE N16, 11      ; A#5
	VOLUME $05
	NOTE N16, 11      ; A#5
	VOLUME $09
	NOTE N16, 13      ; C_6
	VOLUME $05
	NOTE N16, 13      ; C_6
	VOLUME $09
	NOTE N16, 15      ; D_6
	VOLUME $05
	NOTE N16, 15      ; D_6
	VOLUME $09
	NOTE N16, 18      ; F_6
	VOLUME $05
	NOTE N16, 18      ; F_6
	VOLUME $09
	NOTE N16, 19      ; F#6
	VOLUME $05
	NOTE N16, 19      ; F#6
	VOLUME $09
	CONNECT
	NOTE N4, 20       ; G_6
	NOTE N16, 20      ; G_6
	INSTR 2
	CONNECT
	NOTE N4, 20       ; G_6
	INSTR 0
	VOLUME $04
	DOTTED
	NOTE N8, 20       ; G_6
	VOLUME $09
	NOTE N16, 11      ; A#5
	NOTE N16, 6       ; F_5
	NOTE N16, 3       ; D_5
	NOTE N16, 11      ; A#5
	NOTE N16, 6       ; F_5
	NOTE N16, 3       ; D_5
	NOTE N16, 11      ; A#5
	NOTE N16, 6       ; F_5
	NOTE N16, 3       ; D_5
	NOTE N16, 11      ; A#5
	NOTE N16, 6       ; F_5
	NOTE N16, 3       ; D_5
	NOTE N16, 10      ; A_5
	NOTE N16, 5       ; E_5
	NOTE N16, 2       ; C#5
	NOTE N16, 10      ; A_5
	NOTE N16, 5       ; E_5
	NOTE N16, 2       ; C#5
	NOTE N16, 9       ; G#5
	NOTE N16, 4       ; D#5
	NOTE N16, 1       ; C_5
	NOTE N16, 9       ; G#5
	NOTE N16, 4       ; D#5
	NOTE N16, 1       ; C_5
	DOTTED
	CONNECT
	NOTE N4, 8        ; G_5
	NOTE N16, 8       ; G_5
	INSTR 2
	NOTE N4, 8        ; G_5
	CONNECT
	NOTE N16, 8       ; G_5
	VOLUME $04
	INSTR 0
	NOTE N8, 8        ; G_5
	VOLUME $09
	OCTUP
	NOTE N8, 18       ; F_4
	NOTE N8, 19       ; F#4
	NOTE N8, 20       ; G_4
	NOTE N8, 23       ; A#4
	NOTE N8, 25       ; C_5
	CONNECT
	NOTE N4, 27       ; D_5
	INSTR 2
	CONNECT
	NOTE N4, 27       ; D_5
	INSTR 0
	VOLUME $04
	NOTE N8, 27       ; D_5
	VOLUME $09
	NOTE N8, 29       ; E_5
	NOTE N8, 30       ; F_5
	TRIPLET
	NOTE N16, 29      ; E_5
	NOTE N16, 30      ; F_5
	NOTE N16, 29      ; E_5
	TRIPLET
	NOTE N8, 27       ; D_5
	NOTE N8, 29       ; E_5
	NOTE N4, 25       ; C_5
	NOTE N8, 25       ; C_5
	NOTE N32, 25      ; C_5
	CONNECT
	NOTE N4, 27       ; D_5
	INSTR 2
	CONNECT
	NOTE N4, 27       ; D_5
	INSTR 0
	VOLUME $04
	DOTTED
	NOTE N16, 27      ; D_5
	VOLUME $09
	NOTE N32, 24      ; B_4
	CONNECT
	NOTE N4, 25       ; C_5
	INSTR 2
	CONNECT
	NOTE N4, 25       ; C_5
	INSTR 0
	VOLUME $04
	DOTTED
	NOTE N16, 25      ; C_5
	VOLUME $09
	NOTE N32, 20      ; G_4
	DOTTED
	CONNECT
	NOTE N16, 24      ; B_4
	NOTE N8, 24       ; B_4
	NOTE N32, 24      ; B_4
	INSTR 2
	CONNECT
	NOTE N4, 24       ; B_4
	INSTR 0
	VOLUME $04
	DOTTED
	NOTE N16, 24      ; B_4
	VOLUME $09
	TRIPLET
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	NOTE N16, 25      ; C_5
	NOTE N16, 24      ; B_4
	TRIPLET
	NOTE N16, 24      ; B_4
	DOTTED
	CONNECT
	NOTE N8, 20       ; G_4
	INSTR 2
	DOTTED
	CONNECT
	NOTE N2, 20       ; G_4
	JUMP .l6BA3
	END                ; unreachable
Music05_Ch3:
	TEMPO $0180
	HOLD 220
	OCTAVE 0
	TRANSP 0
	INSTR 9
	VOLUME $03
	DOTTED
	CONNECT
	OCTUP
	NOTE N2, 8        ; G_4
	DOTTED
	NOTE N2, 8        ; G_4
	DOTTED
	NOTE N2, 8        ; G_4
	DOTTED
	NOTE N2, 8        ; G_4
	TEMPO $01D8
	NOTE N2, 8        ; G_4
	CONNECT
	NOTE N8, 8        ; G_4
	VOLUME $02
	NOTE N8, 8        ; G_4
.l6D40:
	FLAGS $08
	TEMPO $01D8
	INSTR 1
	TRANSP -12
.l6D49:
	FLAGS $08
	VOLUME $03
	NOTE N16, 8       ; G_4
	VOLUME $02
	NOTE N16, 8       ; G_4
	VOLUME $03
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	NOTE N16, 20      ; G_5
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	VOLUME $02
	NOTE N16, 8       ; G_4
	VOLUME $03
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	NOTE N16, 20      ; G_5
	NOTE N16, 8       ; G_4
	LOOP1 1, .l6D49
	NOTE N16, 11      ; A#4
	VOLUME $02
	NOTE N16, 11      ; A#4
	VOLUME $03
	NOTE N16, 11      ; A#4
	NOTE N16, 11      ; A#4
	NOTE N16, 23      ; A#5
	NOTE N16, 11      ; A#4
	NOTE N16, 11      ; A#4
	NOTE N16, 12      ; B_4
	NOTE N16, 13      ; C_5
	NOTE N16, 11      ; A#4
	NOTE N16, 11      ; A#4
	NOTE N16, 11      ; A#4
.l6D75:
	FLAGS $08
	NOTE N16, 8       ; G_4
	VOLUME $02
	NOTE N16, 8       ; G_4
	VOLUME $03
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	NOTE N16, 20      ; G_5
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	VOLUME $02
	NOTE N16, 8       ; G_4
	VOLUME $03
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	NOTE N16, 20      ; G_5
	NOTE N16, 8       ; G_4
	LOOP1 1, .l6D75
	NOTE N16, 11      ; A#4
	VOLUME $02
	NOTE N16, 11      ; A#4
	VOLUME $03
	NOTE N16, 11      ; A#4
	NOTE N16, 11      ; A#4
	NOTE N16, 23      ; A#5
	NOTE N16, 11      ; A#4
	NOTE N16, 13      ; C_5
	NOTE N16, 25      ; C_6
	NOTE N16, 13      ; C_5
	NOTE N16, 11      ; A#4
	NOTE N16, 23      ; A#5
	NOTE N16, 11      ; A#4
.l6D9F:
	FLAGS $08
	NOTE N16, 8       ; G_4
	VOLUME $02
	NOTE N16, 8       ; G_4
	VOLUME $03
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	NOTE N16, 20      ; G_5
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	VOLUME $02
	NOTE N16, 8       ; G_4
	VOLUME $03
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	NOTE N16, 20      ; G_5
	NOTE N16, 8       ; G_4
	LOOP1 9, .l6D9F
	NOTE N16, 11      ; A#4
	VOLUME $02
	NOTE N16, 11      ; A#4
	VOLUME $03
	NOTE N16, 11      ; A#4
	NOTE N16, 11      ; A#4
	NOTE N16, 23      ; A#5
	NOTE N16, 11      ; A#4
	NOTE N16, 11      ; A#4
	VOLUME $02
	NOTE N16, 11      ; A#4
	VOLUME $03
	NOTE N16, 11      ; A#4
	NOTE N16, 11      ; A#4
	NOTE N16, 23      ; A#5
	NOTE N16, 11      ; A#4
	NOTE N16, 10      ; A_4
	VOLUME $02
	NOTE N16, 10      ; A_4
	VOLUME $03
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	NOTE N16, 22      ; A_5
	NOTE N16, 10      ; A_4
	NOTE N16, 9       ; G#4
	VOLUME $02
	NOTE N16, 9       ; G#4
	VOLUME $03
	NOTE N16, 9       ; G#4
	NOTE N16, 9       ; G#4
	NOTE N16, 21      ; G#5
	NOTE N16, 9       ; G#4
.l6DE1:
	FLAGS $08
	NOTE N16, 8       ; G_4
	VOLUME $02
	NOTE N16, 8       ; G_4
	VOLUME $03
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	NOTE N16, 20      ; G_5
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	VOLUME $02
	NOTE N16, 8       ; G_4
	VOLUME $03
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	NOTE N16, 20      ; G_5
	NOTE N16, 8       ; G_4
	LOOP1 8, .l6DE1
	JUMP .l6D40
	END                ; unreachable
Music05_Ch4:
	TEMPO $0180
	HOLD 255
	OCTAVE 0
	INSTR 13
	VOLUME $0A
	NOTE N8, 15
	REST N2
	NOTE N8, 15
	REST N2
	NOTE N8, 15
	REST N8
	DOTTED
	REST N4
	REST N8
	REST N16
	NOTE N8, 15
	REST N16
	DOTTED
	REST N2
	TEMPO $01D8
	DOTTED
	REST N4
	HOLD 100
	VOLUME $09
	INSTR 6
	NOTE N16, 10
	VOLUME $0A
	NOTE N16, 10
	VOLUME $0B
	NOTE N16, 10
	VOLUME $0C
	NOTE N16, 10
	VOLUME $0D
	NOTE N16, 10
	VOLUME $0E
	NOTE N16, 10
.l6E33:
	FLAGS $00
	TEMPO $01D8
.l6E38:
	FLAGS $00
	VOLUME $0F
	INSTR 5
	NOTE N16, 8
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	VOLUME $07
	NOTE N16, 15
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	VOLUME $07
	NOTE N16, 15
	LOOP1 30, .l6E38
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	REST N16
	NOTE N16, 10
	REST N16
	NOTE N16, 10
	NOTE N16, 10
.l6E62:
	FLAGS $00
	VOLUME $0F
	INSTR 5
	NOTE N16, 8
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	VOLUME $07
	NOTE N16, 15
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	INSTR 4
	VOLUME $0A
	NOTE N16, 15
	VOLUME $07
	NOTE N16, 15
	LOOP1 20, .l6E62
	VOLUME $0F
	INSTR 6
	NOTE N16, 10
	REST N16
	NOTE N16, 10
	REST N16
	NOTE N16, 10
	NOTE N16, 10
	JUMP .l6E33
	END                ; unreachable

;; Music $06
Music06:
	db $00
	BEPTR Music06_Ch1
	BEPTR Music06_Ch2
	BEPTR Music06_Ch3
	BEPTR Music06_Ch4
Music06_Ch1:
	TEMPO $0266
	TRANSP -12
	OCTAVE 0
	VOLUME $0D
	INSTR 0
	HOLD 200
	DUTY $40
.l6EA8:
	FLAGS $08
	TEMPO $0266
	NOTE N8, 16       ; D#5
	REST N4
	NOTE N8, 19       ; F#5
	REST N4
	NOTE N8, 18       ; F_5
	REST N8
	NOTE N8, 21       ; G#5
	REST N8
	NOTE N8, 24       ; B_5
	REST N8
	JUMP .l6EA8
	END                ; unreachable
Music06_Ch2:
	TEMPO $0266
	TRANSP -12
	OCTAVE 0
	VOLUME $0D
	INSTR 0
	DUTY $40
	HOLD 200
	DETUNE 1
.l6ECC:
	FLAGS $08
	TEMPO $0266
	NOTE N16, 9       ; G#4
	NOTE N8, 16       ; D#5
	DOTTED
	REST N8
	NOTE N16, 12      ; B_4
	NOTE N8, 19       ; F#5
	DOTTED
	REST N8
	NOTE N16, 11      ; A#4
	NOTE N8, 18       ; F_5
	REST N16
	NOTE N16, 14      ; C#5
	NOTE N8, 21       ; G#5
	REST N16
	NOTE N16, 17      ; E_5
	NOTE N8, 24       ; B_5
	REST N16
	JUMP .l6ECC
	END                ; unreachable
Music06_Ch3:
	TEMPO $0266
	TRANSP -12
	OCTAVE 0
	VOLUME $03
	INSTR 1
	HOLD 230
.l6EF3:
	FLAGS $00
	TEMPO $0266
	NOTE N8, 28       ; D#4
	OCTUP
	NOTE N16, 16      ; D#5
	REST N16
	NOTE N8, 4        ; D#4
	NOTE N4, 7        ; F#4
	NOTE N16, 19      ; F#5
	REST N16
	NOTE N8, 6        ; F_4
	NOTE N8, 18       ; F_5
	NOTE N8, 9        ; G#4
	NOTE N8, 21       ; G#5
	NOTE N8, 12       ; B_4
	NOTE N8, 24       ; B_5
	JUMP .l6EF3
	END                ; unreachable
Music06_Ch4:
	TEMPO $0266
	OCTAVE 0
	HOLD 50
	VOLUME $0F
.l6F13:
	FLAGS $00
	TEMPO $0266
	INSTR 4
	NOTE N16, 15
	NOTE N16, 15
	INSTR 6
	NOTE N8, 10
	NOTE N8, 10
	INSTR 4
	NOTE N8, 15
	INSTR 6
	NOTE N8, 10
	NOTE N8, 10
	INSTR 4
	NOTE N8, 15
	NOTE N8, 15
	INSTR 5
	NOTE N16, 8
	NOTE N16, 8
	INSTR 4
	NOTE N8, 15
	INSTR 6
	NOTE N8, 10
	INSTR 4
	NOTE N8, 15
	JUMP .l6F13
	END                ; unreachable

;; Music $07
Music07:
	db $00
	BEPTR Music07_Ch1
	BEPTR Music07_Ch2
	BEPTR Music07_Ch3
	BEPTR Music07_Ch4
Music07_Ch1:
	TEMPO $0266
	OCTAVE 0
	VOLUME $0D
	INSTR 0
	HOLD 150
	DUTY $80
.l6F52:
	FLAGS $00
	NOTE N8, 26       ; C#4
	REST N8
	OCTUP
	NOTE N16, 14      ; C#5
	NOTE N16, 14      ; C#5
	NOTE N8, 2        ; C#4
	REST N8
	NOTE N8, 14       ; C#5
	REST N8
	CONNECT
	NOTE N8, 1        ; C_4
	INSTR 2
	CONNECT
	NOTE N4, 1        ; C_4
	INSTR 0
	NOTE N16, 13      ; C_5
	NOTE N16, 13      ; C_5
	NOTE N8, 13       ; C_5
	REST N2
	LOOP1 1, .l6F52
.l6F6D:
	FLAGS $00
	VOLUME $0F
	TEMPO $0266
	TRANSP 0
	INSTR 0
	DUTY $40
	NOTE N32, 20      ; G_3
	DOTTED
	NOTE N16, 22      ; A_3
	NOTE N8, 21       ; G#3
	NOTE N8, 22       ; A_3
	NOTE N32, 27      ; D_4
	CONNECT
	NOTE N2, 29       ; E_4
	DOTTED
	CONNECT
	NOTE N16, 29      ; E_4
	NOTE N8, 27       ; D_4
	NOTE N4, 28       ; D#4
	CONNECT
	NOTE N2, 21       ; G#3
	INSTR 2
	CONNECT
	NOTE N8, 21       ; G#3
	INSTR 0
	NOTE N32, 20      ; G_3
	DOTTED
	NOTE N16, 22      ; A_3
	NOTE N8, 21       ; G#3
	NOTE N8, 22       ; A_3
	NOTE N32, 27      ; D_4
	DOTTED
	CONNECT
	NOTE N16, 29      ; E_4
	INSTR 2
	NOTE N2, 29       ; E_4
	CONNECT
	NOTE N8, 29       ; E_4
	INSTR 0
	NOTE N4, 30       ; F_4
	CONNECT
	OCTUP
	NOTE N4, 13       ; C_5
	INSTR 2
	DOTTED
	CONNECT
	NOTE N4, 13       ; C_5
	DUTY $80
	INSTR 0
.l6FAC:
	FLAGS $08
	VOLUME $0C
	NOTE N8, 8        ; G_4
	VOLUME $07
	NOTE N8, 8        ; G_4
	VOLUME $08
	NOTE N8, 8        ; G_4
	VOLUME $09
	NOTE N8, 8        ; G_4
	VOLUME $0A
	NOTE N8, 8        ; G_4
	VOLUME $0B
.l6FBF:
	FLAGS $08
	NOTE N8, 8        ; G_4
	LOOP3 2, .l6FBF
	VOLUME $0C
	NOTE N8, 9        ; G#4
	VOLUME $07
	NOTE N8, 9        ; G#4
	VOLUME $08
	NOTE N8, 9        ; G#4
	VOLUME $09
	NOTE N8, 9        ; G#4
	VOLUME $0A
	NOTE N8, 9        ; G#4
	VOLUME $0B
.l6FD7:
	FLAGS $08
	NOTE N8, 9        ; G#4
	LOOP3 2, .l6FD7
	LOOP2 1, .l6FAC
	DUTY $00
	TRANSP -12
	VOLUME $0C
	DOTTED
	NOTE N4, 17       ; E_5
	NOTE N2, 17       ; E_5
	CONNECT
	NOTE N8, 16       ; D#5
	INSTR 2
	CONNECT
	NOTE N1, 16       ; D#5
	INSTR 0
	DOTTED
	NOTE N4, 17       ; E_5
	NOTE N2, 17       ; E_5
	CONNECT
	NOTE N8, 18       ; F_5
	INSTR 2
	CONNECT
	NOTE N1, 18       ; F_5
	JUMP .l6F6D
	END                ; unreachable
Music07_Ch2:
	TEMPO $0266
	OCTAVE 1
	HOLD 150
	VOLUME $0C
	INSTR 0
	DUTY $80
.l700D:
	FLAGS $00
	NOTE N8, 19       ; F#4
	REST N8
	NOTE N16, 31      ; F#5
	NOTE N16, 31      ; F#5
	NOTE N8, 19       ; F#4
	REST N8
	NOTE N8, 31       ; F#5
	REST N8
	CONNECT
	NOTE N8, 18       ; F_4
	INSTR 2
	CONNECT
	NOTE N4, 18       ; F_4
	INSTR 0
	NOTE N16, 30      ; F_5
	NOTE N16, 30      ; F_5
	NOTE N8, 30       ; F_5
	REST N2
	LOOP1 1, .l700D
.l7027:
	FLAGS $08
	TEMPO $0266
	VOLUME $07
.l702E:
	FLAGS $08
	NOTE N16, 9       ; G#5
	NOTE N16, 10      ; A_5
	NOTE N16, 17      ; E_6
	LOOP2 4, .l702E
	NOTE N16, 9       ; G#5
	NOTE N16, 15      ; D_6
	NOTE N16, 16      ; D#6
.l703A:
	FLAGS $08
	NOTE N16, 8       ; G_5
	NOTE N16, 9       ; G#5
	NOTE N16, 16      ; D#6
	LOOP2 1, .l703A
	NOTE N16, 15      ; D_6
	NOTE N16, 16      ; D#6
	NOTE N16, 8       ; G_5
	NOTE N16, 9       ; G#5
	NOTE N16, 16      ; D#6
	NOTE N16, 9       ; G#5
	NOTE N16, 8       ; G_5
	NOTE N16, 9       ; G#5
.l704B:
	FLAGS $08
	NOTE N16, 9       ; G#5
	NOTE N16, 10      ; A_5
	NOTE N16, 17      ; E_6
	LOOP2 4, .l704B
	NOTE N16, 9       ; G#5
	NOTE N16, 17      ; E_6
	NOTE N16, 18      ; F_6
	NOTE N16, 10      ; A_5
	NOTE N16, 11      ; A#5
	NOTE N16, 18      ; F_6
	NOTE N16, 11      ; A#5
	NOTE N16, 10      ; A_5
	NOTE N16, 11      ; A#5
	NOTE N16, 17      ; E_6
	NOTE N16, 18      ; F_6
	NOTE N16, 10      ; A_5
	NOTE N16, 11      ; A#5
	NOTE N16, 18      ; F_6
	NOTE N16, 10      ; A_5
	NOTE N16, 11      ; A#5
	NOTE N16, 18      ; F_6
	HOLD 100
.l7067:
	FLAGS $00
	VOLUME $0C
	NOTE N8, 27       ; D_5
	VOLUME $07
	NOTE N8, 27       ; D_5
	VOLUME $08
	NOTE N8, 27       ; D_5
	VOLUME $09
	NOTE N8, 27       ; D_5
	VOLUME $0A
	NOTE N8, 27       ; D_5
.l7078:
	FLAGS $00
	NOTE N8, 27       ; D_5
	LOOP3 2, .l7078
	VOLUME $0C
	NOTE N8, 28       ; D#5
	VOLUME $07
	NOTE N8, 28       ; D#5
	VOLUME $08
	NOTE N8, 28       ; D#5
	VOLUME $09
	NOTE N8, 28       ; D#5
	VOLUME $0A
	NOTE N8, 28       ; D#5
.l708E:
	FLAGS $00
	NOTE N8, 28       ; D#5
	LOOP3 2, .l708E
	LOOP2 1, .l7067
	VOLUME $07
.l709B:
	FLAGS $08
	NOTE N16, 19      ; F#6
	NOTE N16, 13      ; C_6
	NOTE N16, 14      ; C#6
	LOOP2 4, .l709B
	NOTE N16, 19      ; F#6
.l70A5:
	FLAGS $08
	NOTE N16, 16      ; D#6
	NOTE N16, 8       ; G_5
	NOTE N16, 9       ; G#5
	LOOP2 4, .l70A5
	NOTE N16, 16      ; D#6
.l70AF:
	FLAGS $08
	NOTE N16, 17      ; E_6
	NOTE N16, 9       ; G#5
	NOTE N16, 10      ; A_5
	LOOP2 4, .l70AF
	NOTE N16, 17      ; E_6
.l70B9:
	FLAGS $08
	NOTE N16, 18      ; F_6
	NOTE N16, 10      ; A_5
	NOTE N16, 11      ; A#5
	LOOP2 4, .l70B9
	NOTE N16, 18      ; F_6
	JUMP .l7027
	END                ; unreachable
Music07_Ch3:
	TEMPO $0266
	OCTAVE 0
	VOLUME $03
	INSTR 1
	HOLD 210
	TRANSP -12
	DUTY $80
.l70D6:
	FLAGS $00
	NOTE N8, 31       ; F#4
	NOTE N8, 31       ; F#4
	OCTUP
	NOTE N8, 14       ; C#5
	NOTE N8, 7        ; F#4
	NOTE N8, 7        ; F#4
	NOTE N4, 16       ; D#5
	CONNECT
	NOTE N8, 7        ; F#4
	CONNECT
	NOTE N8, 7        ; F#4
	NOTE N8, 7        ; F#4
	NOTE N8, 18       ; F_5
	NOTE N4, 18       ; F_5
	NOTE N8, 7        ; F#4
	NOTE N8, 10       ; A_4
	NOTE N8, 7        ; F#4
	LOOP1 1, .l70D6
.l70ED:
	FLAGS $00
	TEMPO $0266
.l70F2:
	FLAGS $00
	NOTE N8, 31       ; F#4
	NOTE N8, 31       ; F#4
	OCTUP
	NOTE N8, 14       ; C#5
	NOTE N4, 7        ; F#4
	NOTE N4, 17       ; E_5
	CONNECT
	NOTE N8, 7        ; F#4
	CONNECT
	NOTE N8, 7        ; F#4
	NOTE N8, 7        ; F#4
	NOTE N8, 17       ; E_5
	NOTE N4, 16       ; D#5
	NOTE N8, 7        ; F#4
	NOTE N8, 10       ; A_4
	NOTE N8, 7        ; F#4
	LOOP2 1, .l70F2
.l7108:
	FLAGS $00
	NOTE N8, 31       ; F#4
	OCTUP
	NOTE N8, 8        ; G_4
	NOTE N8, 20       ; G_5
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	REST N8
	NOTE N8, 8        ; G_4
	NOTE N4, 8        ; G_4
	NOTE N8, 8        ; G_4
	NOTE N8, 9        ; G#4
	NOTE N8, 21       ; G#5
	NOTE N16, 9       ; G#4
	NOTE N16, 9       ; G#4
	REST N8
	NOTE N4, 9        ; G#4
	NOTE N8, 9        ; G#4
	LOOP2 1, .l7108
.l711F:
	FLAGS $00
	NOTE N8, 31       ; F#4
	NOTE N8, 31       ; F#4
	OCTUP
	NOTE N8, 14       ; C#5
	NOTE N8, 7        ; F#4
	NOTE N8, 7        ; F#4
	NOTE N4, 17       ; E_5
	CONNECT
	NOTE N8, 7        ; F#4
	CONNECT
	NOTE N8, 7        ; F#4
	NOTE N8, 7        ; F#4
	NOTE N8, 17       ; E_5
	NOTE N4, 16       ; D#5
	NOTE N8, 7        ; F#4
	NOTE N8, 10       ; A_4
	NOTE N8, 7        ; F#4
	LOOP2 1, .l711F
	JUMP .l70ED
	END                ; unreachable
Music07_Ch4:
	TEMPO $0266
	OCTAVE 0
	HOLD 20
	VOLUME $0F
.l7143:
	FLAGS $00
	INSTR 6
	NOTE N8, 10
	INSTR 5
	NOTE N8, 8
	INSTR 4
	NOTE N16, 15
	NOTE N16, 15
	NOTE N8, 15
	INSTR 6
	REST N8
	NOTE N8, 10
	INSTR 4
	NOTE N8, 15
	INSTR 6
	NOTE N8, 10
	REST N8
	NOTE N16, 10
	NOTE N16, 10
	NOTE N16, 10
	NOTE N16, 10
	NOTE N8, 10
	INSTR 4
	REST N8
	NOTE N16, 15
	NOTE N16, 15
	NOTE N16, 15
	NOTE N16, 15
	NOTE N16, 15
	NOTE N16, 15
	LOOP1 1, .l7143
.l716D:
	FLAGS $00
	TEMPO $0266
.l7172:
	FLAGS $00
	INSTR 6
	NOTE N8, 10
	INSTR 4
	NOTE N16, 15
	NOTE N16, 15
	INSTR 6
	NOTE N8, 10
	INSTR 4
	NOTE N16, 15
	NOTE N16, 15
	INSTR 6
	NOTE N16, 10
	INSTR 4
	NOTE N16, 15
	INSTR 6
	NOTE N16, 10
	INSTR 4
	NOTE N16, 15
	INSTR 6
	NOTE N8, 10
	INSTR 4
	NOTE N16, 15
	NOTE N16, 15
	LOOP1 2, .l7172
	INSTR 6
	NOTE N8, 10
	INSTR 4
	NOTE N16, 15
	NOTE N16, 15
	INSTR 6
	NOTE N8, 10
	INSTR 4
	NOTE N16, 15
	NOTE N16, 15
	INSTR 6
	NOTE N16, 10
	INSTR 4
	NOTE N16, 15
	INSTR 6
	NOTE N16, 10
	INSTR 4
	NOTE N16, 15
	INSTR 6
	NOTE N16, 10
	NOTE N16, 10
	NOTE N16, 10
	NOTE N16, 10
.l71B9:
	FLAGS $00
	NOTE N8, 10
	NOTE N16, 10
	NOTE N16, 10
	LOOP1 14, .l71B9
	NOTE N16, 10
	NOTE N16, 10
	NOTE N16, 10
	NOTE N16, 10
.l71C6:
	FLAGS $00
	INSTR 6
	NOTE N8, 10
	INSTR 4
	NOTE N16, 15
	NOTE N16, 15
	INSTR 6
	NOTE N8, 10
	INSTR 4
	NOTE N16, 15
	NOTE N16, 15
	INSTR 6
	NOTE N16, 10
	INSTR 4
	NOTE N16, 15
	INSTR 6
	NOTE N16, 10
	INSTR 4
	NOTE N16, 15
	INSTR 6
	NOTE N8, 10
	INSTR 4
	NOTE N16, 15
	NOTE N16, 15
	LOOP1 2, .l71C6
	INSTR 6
	NOTE N8, 10
	INSTR 4
	NOTE N16, 15
	NOTE N16, 15
	INSTR 6
	NOTE N8, 10
	INSTR 4
	NOTE N16, 15
	NOTE N16, 15
	INSTR 6
	NOTE N16, 10
	INSTR 4
	NOTE N16, 15
	INSTR 6
	NOTE N16, 10
	INSTR 4
	NOTE N16, 15
	INSTR 6
	NOTE N16, 10
	NOTE N16, 10
	NOTE N16, 10
	NOTE N16, 10
	JUMP .l716D
	END                ; unreachable

;; SFX $20
Sfx20:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $04
	SEG_FRAMES 2, %1010         ; CH2+CH4
	db $0F, $39, $C0, $07, $0F, $2D; CH2: instr 57, duty $C0, vol $07, slide $0F, note 45
	db $0D, $3A, $08, $BE, $50  ; CH4: instr 58, vol $08, slide $BE, noise 80
	SEGMENT $FF, %010
	SEG_HOLD $43
	SEG_FRAMES 10, %1000        ; CH4
	db $0D, $39, $08, $00, $6D  ; CH4: instr 57, vol $08, slide $00, noise 109
	SFX_END

;; SFX $21
Sfx21:
	SFX_PRIORITY 12, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $38, $0D, $E4, $6E  ; CH4: instr 56, vol $0D, slide $E4, noise 110
	SEGMENT $FF, %010
	SEG_HOLD $3C
	SEG_FRAMES 40, %1000        ; CH4
	db $05, $37, $0B, $42       ; CH4: instr 55, vol $0B, noise 66
	SFX_END

;; SFX $22
Sfx22:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $36, $0D, $FF, $1B  ; CH4: instr 54, vol $0D, slide $FF, noise 27
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 6, %1000         ; CH4
	db $0C, $0C, $FF, $1D       ; CH4: vol $0C, slide $FF, noise 29
	SFX_END

;; SFX $23
Sfx23:
	SFX_PRIORITY 12, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $30, $0D, $8B, $1B  ; CH4: instr 48, vol $0D, slide $8B, noise 27
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 20, %1000        ; CH4
	db $0D, $3A, $0C, $B2, $2E  ; CH4: instr 58, vol $0C, slide $B2, noise 46
	SFX_END

;; SFX $24
Sfx24:
	SFX_PRIORITY 15, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $38, $0F, $D0, $6E  ; CH4: instr 56, vol $0F, slide $D0, noise 110
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $35, $0F, $A0, $2E  ; CH4: instr 53, vol $0F, slide $A0, noise 46
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1000         ; CH4
	db $0D, $3A, $0E, $A0, $2D  ; CH4: instr 58, vol $0E, slide $A0, noise 45
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 35, %1000        ; CH4
	db $0C, $0E, $A0, $2D       ; CH4: vol $0E, slide $A0, noise 45
	SFX_END

;; SFX $25
Sfx25:
	SFX_PRIORITY 16, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $31, $0F, $FF, $1C  ; CH4: instr 49, vol $0F, slide $FF, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1000         ; CH4
	db $0D, $36, $0F, $02, $1D  ; CH4: instr 54, vol $0F, slide $02, noise 29
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %1000         ; CH4
	db $0D, $3A, $0F, $FF, $2C  ; CH4: instr 58, vol $0F, slide $FF, noise 44
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 31, %1000        ; CH4
	db $0C, $0E, $00, $2C       ; CH4: vol $0E, slide $00, noise 44
	SFX_END

;; SFX $26
Sfx26:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $39, $0C, $A0, $7E  ; CH4: instr 57, vol $0C, slide $A0, noise 126
	SFX_END

;; SFX $27
Sfx27:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %1000         ; CH4
	db $0D, $36, $0F, $FB, $21  ; CH4: instr 54, vol $0F, slide $FB, noise 33
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1000         ; CH4
	db $0C, $0F, $C3, $21       ; CH4: vol $0F, slide $C3, noise 33
	SFX_END

;; SFX $28
Sfx28:
	SFX_PRIORITY 12, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 110, %0110       ; CH2+CH3
	db $1F, $38, $40, $0B, $9B, $DB, $20; CH2: instr 56, duty $40, vol $0B, slide $9B, detune $DB, note 32
	db $1F, $33, $02, $E8, $9B, $F8, $2E; CH3: instr 51, duty $02, vol $E8, slide $9B, detune $F8, note 46
	SFX_END

;; SFX $29
Sfx29:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 32, %1010        ; CH2+CH4
	db $0D, $38, $0A, $87, $19  ; CH2: instr 56, vol $0A, slide $87, note 25
	db $0D, $39, $0F, $84, $3B  ; CH4: instr 57, vol $0F, slide $84, noise 59
	SFX_END

;; SFX $2A
Sfx2A:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 13, %1010        ; CH2+CH4
	db $0D, $39, $0A, $0F, $2D  ; CH2: instr 57, vol $0A, slide $0F, note 45
	db $0D, $3A, $0D, $BE, $50  ; CH4: instr 58, vol $0D, slide $BE, noise 80
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 10, %1000        ; CH4
	db $0D, $39, $0C, $00, $6D  ; CH4: instr 57, vol $0C, slide $00, noise 109
	SFX_END

;; SFX $2B
Sfx2B:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $04
	SEG_FRAMES 4, %1010         ; CH2+CH4
	db $0D, $39, $0B, $0F, $2D  ; CH2: instr 57, vol $0B, slide $0F, note 45
	db $0D, $3A, $0E, $FF, $6E  ; CH4: instr 58, vol $0E, slide $FF, noise 110
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 41, %1000        ; CH4
	db $0C, $0D, $91, $70       ; CH4: vol $0D, slide $91, noise 112
	SFX_END

;; SFX $2C
Sfx2C:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 4, %1000         ; CH4
	db $1D, $3A, $09, $29, $D4, $7F; CH4: instr 58, vol $09, slide $29, detune $D4, noise 127
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 19, %1000        ; CH4
	db $1D, $36, $07, $16, $D4, $7F; CH4: instr 54, vol $07, slide $16, detune $D4, noise 127
	SFX_END

;; SFX $2D
Sfx2D:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1010         ; CH2+CH4
	db $07, $3A, $80, $08, $40  ; CH2: instr 58, duty $80, vol $08, note 64
	db $05, $39, $0B, $4D       ; CH4: instr 57, vol $0B, noise 77
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1010         ; CH2+CH4
	db $06, $80, $08, $4E       ; CH2: duty $80, vol $08, note 78
	db $04, $0B, $33            ; CH4: vol $0B, noise 51
	SFX_END

;; SFX $2E
Sfx2E:
	SFX_PRIORITY 22, 0
	SEGMENT $FF, %010
	SEG_HOLD $04
	SEG_FRAMES 5, %1011         ; CH1+CH2+CH4
	db $0F, $3A, $80, $0F, $1C, $0B; CH1: instr 58, duty $80, vol $0F, slide $1C, note 11
	db $1F, $3A, $40, $0F, $1C, $FC, $02; CH2: instr 58, duty $40, vol $0F, slide $1C, detune $FC, note 2
	db $0D, $32, $0F, $9A, $2B  ; CH4: instr 50, vol $0F, slide $9A, noise 43
	SEGMENT $FF, %010
	SEG_HOLD $5B
	SEG_FRAMES 26, %0011        ; CH1+CH2
	db $0F, $32, $80, $0F, $FF, $12; CH1: instr 50, duty $80, vol $0F, slide $FF, note 18
	db $1F, $39, $40, $0D, $DC, $FC, $18; CH2: instr 57, duty $40, vol $0D, slide $DC, detune $FC, note 24
	SEGMENT $FF, %010
	SEG_HOLD $04
	SEG_FRAMES 15, %0011        ; CH1+CH2
	db $0E, $80, $0D, $FF, $12  ; CH1: duty $80, vol $0D, slide $FF, note 18
	db $1E, $40, $0B, $16, $FC, $28; CH2: duty $40, vol $0B, slide $16, detune $FC, note 40
	SEGMENT $FF, %010
	SEG_HOLD $04
	SEG_FRAMES 15, %0011        ; CH1+CH2
	db $0E, $80, $0B, $FF, $12  ; CH1: duty $80, vol $0B, slide $FF, note 18
	db $1E, $40, $09, $16, $FC, $28; CH2: duty $40, vol $09, slide $16, detune $FC, note 40
	SEGMENT $FF, %010
	SEG_HOLD $04
	SEG_FRAMES 15, %0011        ; CH1+CH2
	db $0E, $80, $09, $FF, $12  ; CH1: duty $80, vol $09, slide $FF, note 18
	db $1E, $40, $07, $16, $FC, $28; CH2: duty $40, vol $07, slide $16, detune $FC, note 40
	SEGMENT $FF, %010
	SEG_HOLD $04
	SEG_FRAMES 15, %0011        ; CH1+CH2
	db $0E, $80, $07, $FF, $12  ; CH1: duty $80, vol $07, slide $FF, note 18
	db $1E, $40, $05, $16, $FC, $28; CH2: duty $40, vol $05, slide $16, detune $FC, note 40
	SEGMENT $FF, %010
	SEG_HOLD $04
	SEG_FRAMES 15, %0011        ; CH1+CH2
	db $0E, $80, $05, $FF, $12  ; CH1: duty $80, vol $05, slide $FF, note 18
	db $1E, $40, $03, $16, $FC, $28; CH2: duty $40, vol $03, slide $16, detune $FC, note 40
	SFX_END

;; SFX $2F
Sfx2F:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 2, %0011         ; CH1+CH2
	db $07, $3A, $80, $08, $38  ; CH1: instr 58, duty $80, vol $08, note 56
	db $07, $3A, $80, $08, $31  ; CH2: instr 58, duty $80, vol $08, note 49
	SEGMENT $FF, %000
	SEG_FRAMES 0, %0000
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0011         ; CH1+CH2
	db $06, $80, $08, $38       ; CH1: duty $80, vol $08, note 56
	db $06, $80, $08, $31       ; CH2: duty $80, vol $08, note 49
	SFX_END

;; SFX $30
Sfx30:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0011         ; CH1+CH2
	db $07, $38, $C0, $08, $30  ; CH1: instr 56, duty $C0, vol $08, note 48
	db $17, $38, $C0, $08, $FE, $30; CH2: instr 56, duty $C0, vol $08, detune $FE, note 48
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0011         ; CH1+CH2
	db $06, $C0, $08, $2C       ; CH1: duty $C0, vol $08, note 44
	db $16, $C0, $08, $FE, $2C  ; CH2: duty $C0, vol $08, detune $FE, note 44
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0011         ; CH1+CH2
	db $06, $C0, $03, $2C       ; CH1: duty $C0, vol $03, note 44
	db $16, $C0, $03, $FE, $2C  ; CH2: duty $C0, vol $03, detune $FE, note 44
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0011         ; CH1+CH2
	db $06, $C0, $01, $2C       ; CH1: duty $C0, vol $01, note 44
	db $16, $C0, $01, $FE, $2C  ; CH2: duty $C0, vol $01, detune $FE, note 44
	SFX_END

;; SFX $31
Sfx31:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 2, %0010         ; CH2
	db $07, $35, $80, $0B, $2E  ; CH2: instr 53, duty $80, vol $0B, note 46
	SEGMENT $FF, %000
	SEG_FRAMES 0, %0000
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0010         ; CH2
	db $07, $35, $80, $06, $2E  ; CH2: instr 53, duty $80, vol $06, note 46
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0010         ; CH2
	db $07, $35, $80, $03, $2E  ; CH2: instr 53, duty $80, vol $03, note 46
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0010         ; CH2
	db $07, $35, $80, $03, $2E  ; CH2: instr 53, duty $80, vol $03, note 46
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0010         ; CH2
	db $07, $35, $80, $03, $2E  ; CH2: instr 53, duty $80, vol $03, note 46
	SFX_END

;; SFX $32
Sfx32:
	SFX_PRIORITY 13, 0
.l7481:
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 1, %1010         ; CH2+CH4
	db $07, $3A, $C0, $08, $22  ; CH2: instr 58, duty $C0, vol $08, note 34
	db $05, $3A, $09, $2D       ; CH4: instr 58, vol $09, noise 45
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1010         ; CH2+CH4
	db $06, $C0, $08, $3C       ; CH2: duty $C0, vol $08, note 60
	db $04, $09, $41            ; CH4: vol $09, noise 65
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0000
	SEGMENT $FF, %011
	SEG_LOOP 4, .l7481
	SEG_HOLD $0B
	SEG_FRAMES 1, %0000
	SFX_END

;; SFX $33
Sfx33:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $36, $0C, $FF, $1C  ; CH4: instr 54, vol $0C, slide $FF, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 5, %1011         ; CH1+CH2+CH4
	db $07, $3A, $C0, $09, $20  ; CH1: instr 58, duty $C0, vol $09, note 32
	db $07, $3A, $C0, $0B, $40  ; CH2: instr 58, duty $C0, vol $0B, note 64
	db $0C, $0F, $9C, $60       ; CH4: vol $0F, slide $9C, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 6, %1011         ; CH1+CH2+CH4
	db $06, $C0, $07, $2C       ; CH1: duty $C0, vol $07, note 44
	db $06, $C0, $09, $4B       ; CH2: duty $C0, vol $09, note 75
	db $0D, $34, $0F, $03, $2B  ; CH4: instr 52, vol $0F, slide $03, noise 43
	SFX_END

;; SFX $34
Sfx34:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %0011         ; CH1+CH2
	db $07, $3A, $C0, $0B, $38  ; CH1: instr 58, duty $C0, vol $0B, note 56
	db $17, $3A, $C0, $0B, $FF, $38; CH2: instr 58, duty $C0, vol $0B, detune $FF, note 56
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 2, %0000
	SEGMENT $FF, %010
	SEG_HOLD $08
	SEG_FRAMES 1, %0011         ; CH1+CH2
	db $07, $33, $C0, $0A, $3D  ; CH1: instr 51, duty $C0, vol $0A, note 61
	db $17, $33, $C0, $0A, $FF, $3D; CH2: instr 51, duty $C0, vol $0A, detune $FF, note 61
	SEGMENT $FF, %010
	SEG_HOLD $08
	SEG_FRAMES 1, %0011         ; CH1+CH2
	db $06, $C0, $0A, $42       ; CH1: duty $C0, vol $0A, note 66
	db $16, $C0, $0A, $FF, $42  ; CH2: duty $C0, vol $0A, detune $FF, note 66
	SEGMENT $FF, %010
	SEG_HOLD $64
	SEG_FRAMES 41, %0011        ; CH1+CH2
	db $07, $3A, $C0, $0A, $42  ; CH1: instr 58, duty $C0, vol $0A, note 66
	db $17, $3A, $C0, $0A, $FF, $42; CH2: instr 58, duty $C0, vol $0A, detune $FF, note 66
	SFX_END

;; SFX $35
Sfx35:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0010         ; CH2
	db $07, $35, $80, $0E, $25  ; CH2: instr 53, duty $80, vol $0E, note 37
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 3, %0010         ; CH2
	db $06, $80, $0C, $31       ; CH2: duty $80, vol $0C, note 49
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0010         ; CH2
	db $06, $80, $0E, $25       ; CH2: duty $80, vol $0E, note 37
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 5, %0010         ; CH2
	db $06, $80, $0C, $31       ; CH2: duty $80, vol $0C, note 49
	SFX_END

;; SFX $36
Sfx36:
	SFX_PRIORITY 15, 0
	SEGMENT $FF, %010
	SEG_HOLD $05
	SEG_FRAMES 5, %1011         ; CH1+CH2+CH4
	db $0D, $36, $0A, $A0, $14  ; CH1: instr 54, vol $0A, slide $A0, note 20
	db $0D, $31, $08, $E8, $1E  ; CH2: instr 49, vol $08, slide $E8, note 30
	db $0D, $3A, $05, $9D, $20  ; CH4: instr 58, vol $05, slide $9D, noise 32
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 23, %1010        ; CH2+CH4
	db $0C, $0B, $E8, $1E       ; CH2: vol $0B, slide $E8, note 30
	db $0C, $0C, $9D, $20       ; CH4: vol $0C, slide $9D, noise 32
	SFX_END

;; SFX $37
Sfx37:
	SFX_PRIORITY 15, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 6, %1010         ; CH2+CH4
	db $0D, $31, $07, $CE, $2F  ; CH2: instr 49, vol $07, slide $CE, note 47
	db $0D, $3A, $08, $9D, $1F  ; CH4: instr 58, vol $08, slide $9D, noise 31
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 21, %1010        ; CH2+CH4
	db $0C, $0A, $E8, $1E       ; CH2: vol $0A, slide $E8, note 30
	db $0C, $0D, $9D, $1F       ; CH4: vol $0D, slide $9D, noise 31
	SFX_END

;; SFX $38
Sfx38:
	SFX_PRIORITY 12, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %1010         ; CH2+CH4
	db $0F, $3A, $80, $0E, $10, $14; CH2: instr 58, duty $80, vol $0E, slide $10, note 20
	db $0D, $36, $0D, $FF, $1C  ; CH4: instr 54, vol $0D, slide $FF, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1010         ; CH2+CH4
	db $0E, $80, $0E, $16, $14  ; CH2: duty $80, vol $0E, slide $16, note 20
	db $0C, $0D, $FF, $1C       ; CH4: vol $0D, slide $FF, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 61, %1000        ; CH4
	db $0D, $31, $0D, $9E, $6F  ; CH4: instr 49, vol $0D, slide $9E, noise 111
	SFX_END

;; SFX $39
Sfx39:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $03
	SEG_FRAMES 2, %0010         ; CH2
	db $07, $38, $C0, $0D, $2F  ; CH2: instr 56, duty $C0, vol $0D, note 47
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0000
	SEGMENT $FF, %010
	SEG_HOLD $03
	SEG_FRAMES 2, %0010         ; CH2
	db $07, $38, $C0, $08, $2F  ; CH2: instr 56, duty $C0, vol $08, note 47
	SFX_END

;; SFX $3A
Sfx3A:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $32, $0B, $FF, $1C  ; CH4: instr 50, vol $0B, slide $FF, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1011         ; CH1+CH2+CH4
	db $07, $3A, $C0, $0A, $3B  ; CH1: instr 58, duty $C0, vol $0A, note 59
	db $07, $3A, $C0, $0A, $3B  ; CH2: instr 58, duty $C0, vol $0A, note 59
	db $0C, $0B, $FF, $1C       ; CH4: vol $0B, slide $FF, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 36, %0011        ; CH1+CH2
	db $07, $3A, $C0, $0A, $41  ; CH1: instr 58, duty $C0, vol $0A, note 65
	db $07, $3A, $C0, $0A, $41  ; CH2: instr 58, duty $C0, vol $0A, note 65
	SFX_END

;; SFX $3B
Sfx3B:
	SFX_PRIORITY 15, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 18, %0011        ; CH1+CH2
	db $0F, $30, $40, $0E, $01, $19; CH1: instr 48, duty $40, vol $0E, slide $01, note 25
	db $07, $30, $40, $0E, $19  ; CH2: instr 48, duty $40, vol $0E, note 25
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 125, %0111       ; CH1+CH2+CH3
	db $0E, $40, $0E, $81, $19  ; CH1: duty $40, vol $0E, slide $81, note 25
	db $06, $40, $0E, $19       ; CH2: duty $40, vol $0E, note 25
	db $07, $32, $03, $FF, $2B  ; CH3: instr 50, duty $03, vol $FF, note 43
	SFX_END

;; SFX $3C
Sfx3C:
	SFX_PRIORITY 12, 0
	SEGMENT $FF, %010
	SEG_HOLD $FF
	SEG_FRAMES 3, %1010         ; CH2+CH4
	db $0F, $2F, $C0, $0C, $73, $53; CH2: instr 47, duty $C0, vol $0C, slide $73, note 83
	db $0D, $2E, $0C, $84, $2F  ; CH4: instr 46, vol $0C, slide $84, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $FF
	SEG_FRAMES 3, %1010         ; CH2+CH4
	db $0E, $C0, $0C, $73, $53  ; CH2: duty $C0, vol $0C, slide $73, note 83
	db $0C, $08, $84, $2F       ; CH4: vol $08, slide $84, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $FF
	SEG_FRAMES 3, %1010         ; CH2+CH4
	db $0E, $C0, $0C, $73, $53  ; CH2: duty $C0, vol $0C, slide $73, note 83
	db $0C, $07, $84, $2F       ; CH4: vol $07, slide $84, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $6E
	SEG_FRAMES 20, %1010        ; CH2+CH4
	db $0C, $0C, $09, $53       ; CH2: vol $0C, slide $09, note 83
	db $0D, $2D, $04, $86, $3E  ; CH4: instr 45, vol $04, slide $86, noise 62
	SFX_END

;; SFX $3D
Sfx3D:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %1000         ; CH4
	db $0D, $30, $0B, $8B, $1B  ; CH4: instr 48, vol $0B, slide $8B, noise 27
	SEGMENT $FF, %010
	SEG_HOLD $03
	SEG_FRAMES 5, %1000         ; CH4
	db $05, $3A, $0B, $16       ; CH4: instr 58, vol $0B, noise 22
	SEGMENT $FF, %010
	SEG_HOLD $04
	SEG_FRAMES 4, %1000         ; CH4
	db $0C, $0B, $33, $2E       ; CH4: vol $0B, slide $33, noise 46
	SEGMENT $FF, %010
	SEG_HOLD $03
	SEG_FRAMES 3, %1000         ; CH4
	db $0C, $05, $33, $2E       ; CH4: vol $05, slide $33, noise 46
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 2, %1000         ; CH4
	db $0C, $04, $33, $2E       ; CH4: vol $04, slide $33, noise 46
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1000         ; CH4
	db $0C, $03, $33, $2E       ; CH4: vol $03, slide $33, noise 46
	SFX_END

;; SFX $3E
Sfx3E:
	SFX_PRIORITY 12, 0
	SEGMENT $FF, %010
	SEG_HOLD $03
	SEG_FRAMES 3, %0011         ; CH1+CH2
	db $0F, $3A, $C0, $09, $B6, $29; CH1: instr 58, duty $C0, vol $09, slide $B6, note 41
	db $1F, $3A, $C0, $09, $BC, $FD, $29; CH2: instr 58, duty $C0, vol $09, slide $BC, detune $FD, note 41
	SEGMENT $FF, %000
	SEG_FRAMES 0, %0010         ; CH2
	db $07, $3A, $C0, $09, $29  ; CH2: instr 58, duty $C0, vol $09, note 41
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 2, %0010         ; CH2
	db $07, $3A, $C0, $04, $29  ; CH2: instr 58, duty $C0, vol $04, note 41
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0010         ; CH2
	db $07, $3A, $C0, $02, $29  ; CH2: instr 58, duty $C0, vol $02, note 41
	SFX_END

;; SFX $3F
Sfx3F:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $31, $0C, $9D, $1A  ; CH4: instr 49, vol $0C, slide $9D, noise 26
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 17, %1000        ; CH4
	db $0D, $38, $0D, $8F, $1A  ; CH4: instr 56, vol $0D, slide $8F, noise 26
	SFX_END

;; SFX $40
Sfx40:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 45, %1000        ; CH4
	db $0D, $3A, $0D, $7F, $5B  ; CH4: instr 58, vol $0D, slide $7F, noise 91
	SFX_END

;; SFX $41
Sfx41:
	SFX_PRIORITY 12, 0
.l76E8:
	SEGMENT $FF, %010
	SEG_HOLD $41
	SEG_FRAMES 15, %1000        ; CH4
	db $0D, $30, $09, $9D, $2F  ; CH4: instr 48, vol $09, slide $9D, noise 47
	SEGMENT $FF, %011
	SEG_LOOP 10, .l76E8
	SEG_HOLD $3D
	SEG_FRAMES 15, %1000        ; CH4
	db $0C, $09, $9D, $30       ; CH4: vol $09, slide $9D, noise 48
	SFX_END

;; SFX $42
Sfx42:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %110
	SEG_HOLD $01
	SEG_TRANSP -12
	SEG_FRAMES 16, %0110        ; CH2+CH3
	db $0F, $31, $C0, $0D, $BD, $23; CH2: instr 49, duty $C0, vol $0D, slide $BD, note 35
	db $0F, $2B, $03, $FF, $B5, $2F; CH3: instr 43, duty $03, vol $FF, slide $B5, note 47
	SEGMENT $FF, %110
	SEG_HOLD $01
	SEG_TRANSP -12
	SEG_FRAMES 15, %0110        ; CH2+CH3
	db $0F, $31, $C0, $0D, $00, $2C; CH2: instr 49, duty $C0, vol $0D, slide $00, note 44
	db $0F, $2B, $03, $FF, $00, $38; CH3: instr 43, duty $03, vol $FF, slide $00, note 56
	SFX_END

;; SFX $43
Sfx43:
	SFX_PRIORITY 12, 0
	SEGMENT $FF, %010
	SEG_HOLD $5B
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $36, $0E, $FF, $1C  ; CH4: instr 54, vol $0E, slide $FF, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $5B
	SEG_FRAMES 4, %1000         ; CH4
	db $0C, $0E, $FF, $1D       ; CH4: vol $0E, slide $FF, noise 29
	SEGMENT $FF, %010
	SEG_HOLD $09
	SEG_FRAMES 2, %1000         ; CH4
	db $0D, $34, $0E, $00, $2B  ; CH4: instr 52, vol $0E, slide $00, noise 43
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 16, %1000        ; CH4
	db $0C, $0D, $00, $2B       ; CH4: vol $0D, slide $00, noise 43
	SFX_END

;; SFX $44
Sfx44:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 6, %1000         ; CH4
	db $0D, $38, $0E, $00, $6E  ; CH4: instr 56, vol $0E, slide $00, noise 110
	SEGMENT $FF, %010
	SEG_HOLD $40
	SEG_FRAMES 64, %1000        ; CH4
	db $0D, $36, $0E, $84, $1B  ; CH4: instr 54, vol $0E, slide $84, noise 27
	SFX_END

;; SFX $45
Sfx45:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1110         ; CH2+CH3+CH4
	db $0F, $3A, $C0, $0F, $47, $16; CH2: instr 58, duty $C0, vol $0F, slide $47, note 22
	db $0F, $2E, $03, $FF, $7F, $1A; CH3: instr 46, duty $03, vol $FF, slide $7F, note 26
	db $0D, $32, $03, $9D, $6D  ; CH4: instr 50, vol $03, slide $9D, noise 109
	SEGMENT $FF, %000
	SEG_FRAMES 16, %1110        ; CH2+CH3+CH4
	db $0E, $C0, $0F, $2D, $0E  ; CH2: duty $C0, vol $0F, slide $2D, note 14
	db $0E, $03, $FF, $C3, $0F  ; CH3: duty $03, vol $FF, slide $C3, note 15
	db $0D, $32, $08, $0A, $2D  ; CH4: instr 50, vol $08, slide $0A, noise 45
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %0110         ; CH2+CH3
	db $06, $C0, $0C, $14       ; CH2: duty $C0, vol $0C, note 20
	db $06, $03, $FF, $0D       ; CH3: duty $03, vol $FF, note 13
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %0110         ; CH2+CH3
	db $06, $C0, $08, $14       ; CH2: duty $C0, vol $08, note 20
	db $06, $03, $FF, $0D       ; CH3: duty $03, vol $FF, note 13
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 9, %0110         ; CH2+CH3
	db $06, $C0, $04, $14       ; CH2: duty $C0, vol $04, note 20
	db $06, $03, $FF, $0D       ; CH3: duty $03, vol $FF, note 13
	SFX_END

;; SFX $46
Sfx46:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 22, %1110        ; CH2+CH3+CH4
	db $0F, $36, $C0, $0F, $47, $18; CH2: instr 54, duty $C0, vol $0F, slide $47, note 24
	db $0F, $2E, $03, $FC, $7F, $1A; CH3: instr 46, duty $03, vol $FC, slide $7F, note 26
	db $0D, $32, $0A, $07, $2E  ; CH4: instr 50, vol $0A, slide $07, noise 46
	SFX_END

;; SFX $47
Sfx47:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %110
	SEG_HOLD $01
	SEG_TRANSP -4
	SEG_FRAMES 1, %0010         ; CH2
	db $0F, $2E, $80, $0C, $FF, $0C; CH2: instr 46, duty $80, vol $0C, slide $FF, note 12
	SEGMENT $FF, %110
	SEG_HOLD $01
	SEG_TRANSP -4
	SEG_FRAMES 22, %0010        ; CH2
	db $0F, $2E, $80, $0B, $7F, $30; CH2: instr 46, duty $80, vol $0B, slide $7F, note 48
	SFX_END

;; SFX $48
Sfx48:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 6, %1000         ; CH4
	db $0D, $35, $0D, $BA, $1C  ; CH4: instr 53, vol $0D, slide $BA, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 8, %1000         ; CH4
	db $0D, $3A, $09, $84, $1D  ; CH4: instr 58, vol $09, slide $84, noise 29
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $38, $0D, $7F, $4F  ; CH4: instr 56, vol $0D, slide $7F, noise 79
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1000         ; CH4
	db $04, $0A, $4F            ; CH4: vol $0A, noise 79
	SFX_END

;; SFX $49
Sfx49:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $2D
	SEG_FRAMES 51, %0110        ; CH2+CH3
	db $1F, $32, $C0, $0F, $B3, $F5, $07; CH2: instr 50, duty $C0, vol $0F, slide $B3, detune $F5, note 7
	db $0F, $33, $03, $FF, $CE, $03; CH3: instr 51, duty $03, vol $FF, slide $CE, note 3
	SFX_END

;; SFX $4A
Sfx4A:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 9, %1000         ; CH4
	db $0D, $39, $09, $0C, $2D  ; CH4: instr 57, vol $09, slide $0C, noise 45
	SFX_END

;; SFX $4B
Sfx4B:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 5, %1010         ; CH2+CH4
	db $0F, $36, $C0, $0B, $91, $41; CH2: instr 54, duty $C0, vol $0B, slide $91, note 65
	db $0D, $39, $0B, $DE, $1C  ; CH4: instr 57, vol $0B, slide $DE, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 5, %1010         ; CH2+CH4
	db $0E, $C0, $0B, $91, $41  ; CH2: duty $C0, vol $0B, slide $91, note 65
	db $0C, $0B, $DE, $1C       ; CH4: vol $0B, slide $DE, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 5, %1010         ; CH2+CH4
	db $0E, $C0, $0B, $91, $41  ; CH2: duty $C0, vol $0B, slide $91, note 65
	db $0C, $0B, $DE, $1C       ; CH4: vol $0B, slide $DE, noise 28
	SFX_END

;; SFX $4C
Sfx4C:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 8, %0010         ; CH2
	db $0D, $3A, $0D, $D7, $1D  ; CH2: instr 58, vol $0D, slide $D7, note 29
	SEGMENT $FF, %000
	SEG_FRAMES 0, %0000
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %0010         ; CH2
	db $0D, $32, $0D, $B8, $30  ; CH2: instr 50, vol $0D, slide $B8, note 48
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %0010         ; CH2
	db $0D, $32, $0D, $B8, $31  ; CH2: instr 50, vol $0D, slide $B8, note 49
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %0010         ; CH2
	db $0D, $32, $0D, $B8, $30  ; CH2: instr 50, vol $0D, slide $B8, note 48
	SFX_END

;; SFX $4D
Sfx4D:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $3A, $07, $A2, $22  ; CH4: instr 58, vol $07, slide $A2, noise 34
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 51, %1011        ; CH1+CH2+CH4
	db $0F, $31, $C0, $0F, $9F, $09; CH1: instr 49, duty $C0, vol $0F, slide $9F, note 9
	db $1F, $31, $80, $0F, $9E, $F5, $13; CH2: instr 49, duty $80, vol $0F, slide $9E, detune $F5, note 19
	db $0C, $0D, $A2, $22       ; CH4: vol $0D, slide $A2, noise 34
	SFX_END

;; SFX $4E
Sfx4E:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $2F, $0E, $FF, $1C  ; CH4: instr 47, vol $0E, slide $FF, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 20, %1000        ; CH4
	db $0D, $35, $0B, $1D, $1C  ; CH4: instr 53, vol $0B, slide $1D, noise 28
	SFX_END

;; SFX $4F
Sfx4F:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $22
	SEG_FRAMES 29, %1000        ; CH4
	db $0D, $29, $0F, $86, $3D  ; CH4: instr 41, vol $0F, slide $86, noise 61
	SFX_END

;; SFX $50
Sfx50:
	SFX_PRIORITY 11, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $38, $0D, $7F, $4F  ; CH4: instr 56, vol $0D, slide $7F, noise 79
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1000         ; CH4
	db $04, $0C, $4F            ; CH4: vol $0C, noise 79
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1000         ; CH4
	db $04, $08, $4F            ; CH4: vol $08, noise 79
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1000         ; CH4
	db $04, $07, $4F            ; CH4: vol $07, noise 79
	SFX_END

;; SFX $51
Sfx51:
	SFX_PRIORITY 11, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0110         ; CH2+CH3
	db $0F, $36, $80, $0F, $7F, $21; CH2: instr 54, duty $80, vol $0F, slide $7F, note 33
	db $0F, $2E, $02, $FF, $2F, $28; CH3: instr 46, duty $02, vol $FF, slide $2F, note 40
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0110         ; CH2+CH3
	db $06, $80, $0F, $21       ; CH2: duty $80, vol $0F, note 33
	db $06, $02, $F5, $28       ; CH3: duty $02, vol $F5, note 40
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0110         ; CH2+CH3
	db $06, $80, $0C, $21       ; CH2: duty $80, vol $0C, note 33
	db $06, $02, $E6, $28       ; CH3: duty $02, vol $E6, note 40
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0110         ; CH2+CH3
	db $06, $80, $0B, $21       ; CH2: duty $80, vol $0B, note 33
	db $06, $02, $D7, $28       ; CH3: duty $02, vol $D7, note 40
	SFX_END

;; SFX $52
Sfx52:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1010         ; CH2+CH4
	db $0F, $33, $C0, $0D, $B2, $1D; CH2: instr 51, duty $C0, vol $0D, slide $B2, note 29
	db $0D, $29, $0D, $CD, $1A  ; CH4: instr 41, vol $0D, slide $CD, noise 26
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %0010         ; CH2
	db $0F, $39, $C0, $0D, $B2, $2A; CH2: instr 57, duty $C0, vol $0D, slide $B2, note 42
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %0010         ; CH2
	db $0F, $39, $C0, $0B, $B2, $2A; CH2: instr 57, duty $C0, vol $0B, slide $B2, note 42
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %0010         ; CH2
	db $0F, $39, $C0, $09, $B2, $2A; CH2: instr 57, duty $C0, vol $09, slide $B2, note 42
	SFX_END

;; SFX $53
Sfx53:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $31, $0D, $FF, $1B  ; CH4: instr 49, vol $0D, slide $FF, noise 27
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $2F, $0D, $CF, $1B  ; CH4: instr 47, vol $0D, slide $CF, noise 27
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 9, %1000         ; CH4
	db $0D, $38, $0C, $AB, $2D  ; CH4: instr 56, vol $0C, slide $AB, noise 45
	SFX_END

;; SFX $54
Sfx54:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %1010         ; CH2+CH4
	db $0F, $2E, $80, $09, $7F, $2E; CH2: instr 46, duty $80, vol $09, slide $7F, note 46
	db $0D, $38, $08, $FF, $1C  ; CH4: instr 56, vol $08, slide $FF, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 5, %0010         ; CH2
	db $0F, $2E, $C0, $09, $55, $22; CH2: instr 46, duty $C0, vol $09, slide $55, note 34
	SFX_END

;; SFX $55
Sfx55:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 5, %1010         ; CH2+CH4
	db $0F, $36, $C0, $0E, $85, $4A; CH2: instr 54, duty $C0, vol $0E, slide $85, note 74
	db $0D, $39, $0D, $00, $1C  ; CH4: instr 57, vol $0D, slide $00, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 9, %0010         ; CH2
	db $07, $36, $C0, $0E, $4A  ; CH2: instr 54, duty $C0, vol $0E, note 74
	SFX_END

;; SFX $56
Sfx56:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 6, %1000         ; CH4
	db $0D, $38, $0C, $DD, $1F  ; CH4: instr 56, vol $0C, slide $DD, noise 31
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 29, %1000        ; CH4
	db $0D, $2E, $0C, $0C, $3D  ; CH4: instr 46, vol $0C, slide $0C, noise 61
	SFX_END

;; SFX $57
Sfx57:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 14, %1000        ; CH4
	db $0D, $31, $0B, $9F, $2E  ; CH4: instr 49, vol $0B, slide $9F, noise 46
	SFX_END

;; SFX $58
Sfx58:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1010         ; CH2+CH4
	db $0F, $2D, $C0, $0C, $FF, $21; CH2: instr 45, duty $C0, vol $0C, slide $FF, note 33
	db $0D, $3A, $0A, $FF, $6E  ; CH4: instr 58, vol $0A, slide $FF, noise 110
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 11, %1010        ; CH2+CH4
	db $0E, $40, $08, $FF, $28  ; CH2: duty $40, vol $08, slide $FF, note 40
	db $0C, $0A, $91, $70       ; CH4: vol $0A, slide $91, noise 112
	SFX_END

;; SFX $59
Sfx59:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1010         ; CH2+CH4
	db $07, $35, $C0, $0B, $3B  ; CH2: instr 53, duty $C0, vol $0B, note 59
	db $0D, $31, $0A, $21, $1B  ; CH4: instr 49, vol $0A, slide $21, noise 27
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 36, %0010        ; CH2
	db $07, $35, $C0, $0B, $41  ; CH2: instr 53, duty $C0, vol $0B, note 65
	SFX_END

;; SFX $5A
Sfx5A:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1010         ; CH2+CH4
	db $0F, $34, $C0, $08, $FF, $2F; CH2: instr 52, duty $C0, vol $08, slide $FF, note 47
	db $0D, $34, $0D, $FF, $1C  ; CH4: instr 52, vol $0D, slide $FF, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 15, %1010        ; CH2+CH4
	db $0E, $C0, $07, $E6, $39  ; CH2: duty $C0, vol $07, slide $E6, note 57
	db $0D, $34, $0C, $9B, $2F  ; CH4: instr 52, vol $0C, slide $9B, noise 47
	SFX_END

;; SFX $5B
Sfx5B:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $38, $0E, $C5, $1D  ; CH4: instr 56, vol $0E, slide $C5, noise 29
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $3A, $0E, $C5, $1A  ; CH4: instr 58, vol $0E, slide $C5, noise 26
	SFX_END

;; SFX $5C
Sfx5C:
	SFX_PRIORITY 11, 0
	SEGMENT $FF, %010
	SEG_HOLD $44
	SEG_FRAMES 68, %1000        ; CH4
	db $0D, $32, $0B, $9F, $31  ; CH4: instr 50, vol $0B, slide $9F, noise 49
	SFX_END

;; SFX $5D
Sfx5D:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $36
	SEG_FRAMES 49, %1000        ; CH4
	db $0D, $37, $0B, $B6, $30  ; CH4: instr 55, vol $0B, slide $B6, noise 48
	SFX_END

;; SFX $5E
Sfx5E:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $0F
	SEG_FRAMES 31, %1000        ; CH4
	db $05, $30, $0F, $19       ; CH4: instr 48, vol $0F, noise 25
	SEGMENT $FF, %010
	SEG_HOLD $6B
	SEG_FRAMES 101, %1000       ; CH4
	db $05, $3A, $0F, $1A       ; CH4: instr 58, vol $0F, noise 26
	SFX_END

;; SFX $5F
Sfx5F:
	SFX_PRIORITY 12, 0
.l7A7A:
	SEGMENT $FF, %010
	SEG_HOLD $08
	SEG_FRAMES 11, %1000        ; CH4
	db $0D, $30, $0F, $06, $19  ; CH4: instr 48, vol $0F, slide $06, noise 25
	SEGMENT $FF, %011
	SEG_LOOP 0, .l7A7A
	SEG_HOLD $06
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $30, $0F, $08, $19  ; CH4: instr 48, vol $0F, slide $08, noise 25
	SFX_END            ; unreachable (after an endless SEG_LOOP 0)

;; SFX $60
Sfx60:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 10, %1010        ; CH2+CH4
	db $0F, $2F, $C0, $0F, $A1, $15; CH2: instr 47, duty $C0, vol $0F, slide $A1, note 21
	db $0D, $34, $0B, $99, $2D  ; CH4: instr 52, vol $0B, slide $99, noise 45
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 6, %1010         ; CH2+CH4
	db $0F, $30, $C0, $0E, $23, $20; CH2: instr 48, duty $C0, vol $0E, slide $23, note 32
	db $0D, $3A, $0A, $92, $1D  ; CH4: instr 58, vol $0A, slide $92, noise 29
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 55, %1010        ; CH2+CH4
	db $0F, $30, $C0, $0E, $1C, $18; CH2: instr 48, duty $C0, vol $0E, slide $1C, note 24
	db $0D, $30, $0A, $02, $1B  ; CH4: instr 48, vol $0A, slide $02, noise 27
	SFX_END

;; SFX $61
Sfx61:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $03
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $36, $0E, $FF, $1C  ; CH4: instr 54, vol $0E, slide $FF, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 5, %1000         ; CH4
	db $0C, $0C, $9C, $60       ; CH4: vol $0C, slide $9C, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 6, %1000         ; CH4
	db $0D, $34, $0E, $03, $2B  ; CH4: instr 52, vol $0E, slide $03, noise 43
	SFX_END

;; SFX $62
Sfx62:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 5, %1010         ; CH2+CH4
	db $0F, $34, $40, $09, $B3, $32; CH2: instr 52, duty $40, vol $09, slide $B3, note 50
	db $0D, $38, $0E, $CF, $1F  ; CH4: instr 56, vol $0E, slide $CF, noise 31
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 36, %1010        ; CH2+CH4
	db $0D, $3A, $07, $A4, $35  ; CH2: instr 58, vol $07, slide $A4, note 53
	db $0D, $3A, $0B, $A5, $45  ; CH4: instr 58, vol $0B, slide $A5, noise 69
	SFX_END

;; SFX $63
Sfx63:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $3A, $0A, $E4, $1D  ; CH4: instr 58, vol $0A, slide $E4, noise 29
	SEGMENT $FF, %010
	SEG_HOLD $25
	SEG_FRAMES 6, %1000         ; CH4
	db $0D, $38, $0A, $E4, $6E  ; CH4: instr 56, vol $0A, slide $E4, noise 110
	SEGMENT $FF, %010
	SEG_HOLD $29
	SEG_FRAMES 26, %1000        ; CH4
	db $05, $37, $09, $3E       ; CH4: instr 55, vol $09, noise 62
	SFX_END

;; SFX $64
Sfx64:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 10, %1000        ; CH4
	db $0D, $3A, $09, $4A, $59  ; CH4: instr 58, vol $09, slide $4A, noise 89
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %1100         ; CH3+CH4
	db $0F, $20, $02, $C9, $AC, $12; CH3: instr 32, duty $02, vol $C9, slide $AC, note 18
	db $0D, $35, $08, $D9, $2D  ; CH4: instr 53, vol $08, slide $D9, noise 45
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 15, %1000        ; CH4
	db $0C, $09, $FF, $45       ; CH4: vol $09, slide $FF, noise 69
	SFX_END

;; SFX $65
Sfx65:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $7C
	SEG_FRAMES 124, %1000       ; CH4
	db $0D, $32, $0A, $02, $5E  ; CH4: instr 50, vol $0A, slide $02, noise 94
	SFX_END

;; SFX $66
Sfx66:
	SFX_PRIORITY 12, 0
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 4, %1000         ; CH4
	db $1D, $38, $09, $C1, $D4, $3C; CH4: instr 56, vol $09, slide $C1, detune $D4, noise 60
	SEGMENT $FF, %010
	SEG_HOLD $13
	SEG_FRAMES 19, %1000        ; CH4
	db $1D, $3A, $09, $00, $D4, $7F; CH4: instr 58, vol $09, slide $00, detune $D4, noise 127
	SFX_END

;; SFX $67
Sfx67:
	SFX_PRIORITY 12, 0
	SEGMENT $FF, %010
	SEG_HOLD $A6
	SEG_FRAMES 166, %1000       ; CH4
	db $05, $25, $0A, $1A       ; CH4: instr 37, vol $0A, noise 26
	SFX_END

;; SFX $68
Sfx68:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $0D
	SEG_FRAMES 8, %1000         ; CH4
	db $0D, $36, $0F, $9C, $5E  ; CH4: instr 54, vol $0F, slide $9C, noise 94
	SEGMENT $FF, %010
	SEG_HOLD $2E
	SEG_FRAMES 6, %1000         ; CH4
	db $0D, $34, $0F, $00, $2B  ; CH4: instr 52, vol $0F, slide $00, noise 43
	SEGMENT $FF, %010
	SEG_HOLD $41
	SEG_FRAMES 6, %1000         ; CH4
	db $0C, $0F, $00, $2A       ; CH4: vol $0F, slide $00, noise 42
	SEGMENT $FF, %010
	SEG_HOLD $41
	SEG_FRAMES 6, %1000         ; CH4
	db $0C, $0F, $00, $2B       ; CH4: vol $0F, slide $00, noise 43
	SEGMENT $FF, %010
	SEG_HOLD $3C
	SEG_FRAMES 60, %1000        ; CH4
	db $0C, $0F, $00, $2A       ; CH4: vol $0F, slide $00, noise 42
	SFX_END

;; SFX $69
Sfx69:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $FF
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $2D, $0D, $84, $2F  ; CH4: instr 45, vol $0D, slide $84, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $FF
	SEG_FRAMES 3, %1010         ; CH2+CH4
	db $0F, $2F, $C0, $0D, $73, $53; CH2: instr 47, duty $C0, vol $0D, slide $73, note 83
	db $0D, $2D, $0D, $84, $2F  ; CH4: instr 45, vol $0D, slide $84, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $FF
	SEG_FRAMES 3, %1010         ; CH2+CH4
	db $0F, $2F, $C0, $0D, $73, $53; CH2: instr 47, duty $C0, vol $0D, slide $73, note 83
	db $0D, $2D, $0D, $84, $2F  ; CH4: instr 45, vol $0D, slide $84, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $64
	SEG_FRAMES 17, %1010        ; CH2+CH4
	db $0C, $0D, $09, $03       ; CH2: vol $0D, slide $09, note 3
	db $0D, $2D, $09, $86, $3E  ; CH4: instr 45, vol $09, slide $86, noise 62
	SFX_END

;; SFX $6A
Sfx6A:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $FF
	SEG_FRAMES 3, %1010         ; CH2+CH4
	db $0F, $2F, $C0, $0D, $73, $53; CH2: instr 47, duty $C0, vol $0D, slide $73, note 83
	db $0D, $2E, $0D, $84, $2F  ; CH4: instr 46, vol $0D, slide $84, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $FF
	SEG_FRAMES 3, %1010         ; CH2+CH4
	db $0F, $2F, $C0, $0D, $73, $53; CH2: instr 47, duty $C0, vol $0D, slide $73, note 83
	db $0D, $2E, $0D, $84, $2F  ; CH4: instr 46, vol $0D, slide $84, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $6E
	SEG_FRAMES 20, %1010        ; CH2+CH4
	db $0C, $0D, $09, $53       ; CH2: vol $0D, slide $09, note 83
	db $09, $2D, $86, $3E       ; CH4: instr 45, slide $86, noise 62
	SFX_END

;; SFX $6B
Sfx6B:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $FF
	SEG_FRAMES 3, %1010         ; CH2+CH4
	db $0F, $2F, $C0, $0D, $73, $53; CH2: instr 47, duty $C0, vol $0D, slide $73, note 83
	db $0D, $2E, $0D, $84, $2F  ; CH4: instr 46, vol $0D, slide $84, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $FF
	SEG_FRAMES 3, %1010         ; CH2+CH4
	db $0F, $2F, $C0, $0D, $73, $53; CH2: instr 47, duty $C0, vol $0D, slide $73, note 83
	db $0D, $2E, $09, $84, $2F  ; CH4: instr 46, vol $09, slide $84, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $FF
	SEG_FRAMES 3, %1010         ; CH2+CH4
	db $0F, $2F, $C0, $0D, $73, $53; CH2: instr 47, duty $C0, vol $0D, slide $73, note 83
	db $0D, $2E, $08, $84, $2F  ; CH4: instr 46, vol $08, slide $84, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $6E
	SEG_FRAMES 20, %1010        ; CH2+CH4
	db $0C, $0D, $09, $53       ; CH2: vol $0D, slide $09, note 83
	db $0D, $2D, $05, $86, $3E  ; CH4: instr 45, vol $05, slide $86, noise 62
	SFX_END

;; SFX $6C
Sfx6C:
	SFX_PRIORITY 11, 0
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 9, %0011         ; CH1+CH2
	db $0F, $2E, $80, $0F, $FF, $0D; CH1: instr 46, duty $80, vol $0F, slide $FF, note 13
	db $1F, $2E, $80, $0F, $FF, $04, $0D; CH2: instr 46, duty $80, vol $0F, slide $FF, detune $04, note 13
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 9, %0011         ; CH1+CH2
	db $0E, $80, $0D, $FF, $0D  ; CH1: duty $80, vol $0D, slide $FF, note 13
	db $1E, $80, $0D, $FF, $04, $0D; CH2: duty $80, vol $0D, slide $FF, detune $04, note 13
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 9, %0011         ; CH1+CH2
	db $0E, $80, $08, $FF, $0D  ; CH1: duty $80, vol $08, slide $FF, note 13
	db $1E, $80, $08, $FF, $04, $0D; CH2: duty $80, vol $08, slide $FF, detune $04, note 13
	SFX_END

;; SFX $6D
Sfx6D:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $13
	SEG_FRAMES 16, %1000        ; CH4
	db $0D, $3A, $09, $46, $38  ; CH4: instr 58, vol $09, slide $46, noise 56
	SFX_END

;; SFX $6E
Sfx6E:
	SFX_PRIORITY 11, 0
	SEGMENT $FF, %010
	SEG_HOLD $3C
	SEG_FRAMES 60, %1000        ; CH4
	db $0D, $2D, $0F, $97, $30  ; CH4: instr 45, vol $0F, slide $97, noise 48
	SFX_END

;; SFX $6F
Sfx6F:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $38, $0F, $D0, $6E  ; CH4: instr 56, vol $0F, slide $D0, noise 110
	SEGMENT $FF, %010
	SEG_HOLD $73
	SEG_FRAMES 88, %1000        ; CH4
	db $0D, $36, $0F, $84, $1B  ; CH4: instr 54, vol $0F, slide $84, noise 27
	SFX_END

;; SFX $70
Sfx70:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $0D
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $38, $0E, $FF, $6E  ; CH4: instr 56, vol $0E, slide $FF, noise 110
	SEGMENT $FF, %010
	SEG_HOLD $29
	SEG_FRAMES 41, %1000        ; CH4
	db $0D, $38, $0E, $8F, $70  ; CH4: instr 56, vol $0E, slide $8F, noise 112
	SFX_END

;; SFX $71
Sfx71:
	SFX_PRIORITY 11, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %1000         ; CH4
	db $0D, $36, $09, $FF, $1C  ; CH4: instr 54, vol $09, slide $FF, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $0A
	SEG_FRAMES 5, %1011         ; CH1+CH2+CH4
	db $07, $3A, $C0, $03, $1F  ; CH1: instr 58, duty $C0, vol $03, note 31
	db $07, $3A, $C0, $04, $3F  ; CH2: instr 58, duty $C0, vol $04, note 63
	db $0D, $36, $0E, $9C, $60  ; CH4: instr 54, vol $0E, slide $9C, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $04
	SEG_FRAMES 4, %1011         ; CH1+CH2+CH4
	db $06, $C0, $02, $2B       ; CH1: duty $C0, vol $02, note 43
	db $06, $C0, $03, $4A       ; CH2: duty $C0, vol $03, note 74
	db $0D, $34, $0E, $03, $2B  ; CH4: instr 52, vol $0E, slide $03, noise 43
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %1011         ; CH1+CH2+CH4
	db $00, $2C                 ; CH1: note 44
	db $00, $4B                 ; CH2: note 75
	db $05, $34, $0E, $2B       ; CH4: instr 52, vol $0E, noise 43
	SFX_END

;; SFX $72
Sfx72:
	SFX_PRIORITY 11, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $3A, $07, $A2, $22  ; CH4: instr 58, vol $07, slide $A2, noise 34
	SEGMENT $FF, %010
	SEG_HOLD $35
	SEG_FRAMES 51, %1011        ; CH1+CH2+CH4
	db $0F, $31, $C0, $0F, $BB, $07; CH1: instr 49, duty $C0, vol $0F, slide $BB, note 7
	db $1F, $31, $80, $0F, $BB, $F5, $11; CH2: instr 49, duty $80, vol $0F, slide $BB, detune $F5, note 17
	db $0C, $0C, $A2, $22       ; CH4: vol $0C, slide $A2, noise 34
	SFX_END

;; SFX $73
Sfx73:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $0D
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $38, $0E, $FF, $6E  ; CH4: instr 56, vol $0E, slide $FF, noise 110
	SEGMENT $FF, %010
	SEG_HOLD $29
	SEG_FRAMES 41, %1000        ; CH4
	db $0D, $38, $0E, $8F, $70  ; CH4: instr 56, vol $0E, slide $8F, noise 112
	SFX_END

;; SFX $74
Sfx74:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %110
	SEG_HOLD $01
	SEG_TRANSP 3
	SEG_FRAMES 3, %0011         ; CH1+CH2
	db $17, $30, $80, $08, $FF, $2A; CH1: instr 48, duty $80, vol $08, detune $FF, note 42
	db $07, $30, $80, $08, $2A  ; CH2: instr 48, duty $80, vol $08, note 42
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0011         ; CH1+CH2
	db $17, $30, $80, $08, $01, $2A; CH1: instr 48, duty $80, vol $08, detune $01, note 42
	db $07, $30, $80, $08, $2A  ; CH2: instr 48, duty $80, vol $08, note 42
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0011         ; CH1+CH2
	db $17, $30, $80, $08, $FF, $2A; CH1: instr 48, duty $80, vol $08, detune $FF, note 42
	db $07, $30, $80, $08, $2A  ; CH2: instr 48, duty $80, vol $08, note 42
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0011         ; CH1+CH2
	db $17, $30, $80, $08, $FF, $2A; CH1: instr 48, duty $80, vol $08, detune $FF, note 42
	db $17, $30, $80, $08, $FE, $2A; CH2: instr 48, duty $80, vol $08, detune $FE, note 42
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0011         ; CH1+CH2
	db $17, $30, $80, $08, $01, $2A; CH1: instr 48, duty $80, vol $08, detune $01, note 42
	db $07, $30, $80, $08, $2A  ; CH2: instr 48, duty $80, vol $08, note 42
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0011         ; CH1+CH2
	db $17, $30, $80, $08, $01, $2A; CH1: instr 48, duty $80, vol $08, detune $01, note 42
	db $17, $30, $80, $08, $FE, $2A; CH2: instr 48, duty $80, vol $08, detune $FE, note 42
	SFX_END

;; SFX $75
Sfx75:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 6, %1000         ; CH4
	db $0D, $3A, $0B, $06, $5D  ; CH4: instr 58, vol $0B, slide $06, noise 93
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 6, %1000         ; CH4
	db $0D, $3A, $09, $06, $5D  ; CH4: instr 58, vol $09, slide $06, noise 93
	SFX_END

;; SFX $76
Sfx76:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 5, %1011         ; CH1+CH2+CH4
	db $07, $3A, $C0, $06, $20  ; CH1: instr 58, duty $C0, vol $06, note 32
	db $07, $3A, $C0, $08, $40  ; CH2: instr 58, duty $C0, vol $08, note 64
	db $0D, $36, $0B, $9C, $60  ; CH4: instr 54, vol $0B, slide $9C, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 5, %1011         ; CH1+CH2+CH4
	db $07, $3A, $C0, $06, $20  ; CH1: instr 58, duty $C0, vol $06, note 32
	db $07, $3A, $C0, $08, $40  ; CH2: instr 58, duty $C0, vol $08, note 64
	db $0D, $36, $0B, $9C, $60  ; CH4: instr 54, vol $0B, slide $9C, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1011         ; CH1+CH2+CH4
	db $06, $C0, $04, $2C       ; CH1: duty $C0, vol $04, note 44
	db $06, $C0, $06, $4B       ; CH2: duty $C0, vol $06, note 75
	db $0D, $34, $03, $03, $2B  ; CH4: instr 52, vol $03, slide $03, noise 43
	SFX_END

;; SFX $77
Sfx77:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $5B
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $36, $0E, $FF, $1C  ; CH4: instr 54, vol $0E, slide $FF, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $09
	SEG_FRAMES 2, %1000         ; CH4
	db $0D, $34, $0D, $00, $2B  ; CH4: instr 52, vol $0D, slide $00, noise 43
	SEGMENT $FF, %010
	SEG_HOLD $09
	SEG_FRAMES 6, %1000         ; CH4
	db $0C, $0C, $00, $2B       ; CH4: vol $0C, slide $00, noise 43
	SFX_END

;; SFX $78
Sfx78:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 5, %1000         ; CH4
	db $0D, $29, $0E, $C1, $2B  ; CH4: instr 41, vol $0E, slide $C1, noise 43
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1000         ; CH4
	db $0D, $38, $0D, $BC, $10  ; CH4: instr 56, vol $0D, slide $BC, noise 16
	SFX_END

;; SFX $79
Sfx79:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %110
	SEG_HOLD $0E
	SEG_TRANSP -1
	SEG_FRAMES 14, %0010        ; CH2
	db $0D, $3A, $0F, $FF, $02  ; CH2: instr 58, vol $0F, slide $FF, note 2
	SEGMENT $FF, %010
	SEG_HOLD $13
	SEG_FRAMES 19, %0010        ; CH2
	db $0C, $0F, $7F, $02       ; CH2: vol $0F, slide $7F, note 2
	SFX_END

;; SFX $7A
Sfx7A:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %110
	SEG_HOLD $01
	SEG_TRANSP -1
	SEG_FRAMES 4, %0010         ; CH2
	db $0F, $3A, $80, $0F, $FF, $15; CH2: instr 58, duty $80, vol $0F, slide $FF, note 21
	SEGMENT $FF, %000
	SEG_FRAMES 0, %0000
	SEGMENT $FF, %110
	SEG_HOLD $01
	SEG_TRANSP -1
	SEG_FRAMES 2, %0010         ; CH2
	db $0F, $3A, $80, $0E, $FF, $0C; CH2: instr 58, duty $80, vol $0E, slide $FF, note 12
	SEGMENT $FF, %000
	SEG_FRAMES 0, %0000
	SEGMENT $FF, %110
	SEG_HOLD $01
	SEG_TRANSP -1
	SEG_FRAMES 2, %0010         ; CH2
	db $0F, $3A, $80, $0C, $FF, $04; CH2: instr 58, duty $80, vol $0C, slide $FF, note 4
	SFX_END

;; SFX $7B
Sfx7B:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $07
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $30, $0B, $07, $60  ; CH4: instr 48, vol $0B, slide $07, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0000
	SEGMENT $FF, %010
	SEG_HOLD $07
	SEG_FRAMES 4, %1000         ; CH4
	db $0C, $07, $07, $60       ; CH4: vol $07, slide $07, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0000
	SEGMENT $FF, %010
	SEG_HOLD $07
	SEG_FRAMES 4, %1000         ; CH4
	db $0C, $04, $07, $60       ; CH4: vol $04, slide $07, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0000
	SEGMENT $FF, %010
	SEG_HOLD $07
	SEG_FRAMES 4, %1000         ; CH4
	db $0C, $01, $07, $60       ; CH4: vol $01, slide $07, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0000
	SEGMENT $FF, %010
	SEG_HOLD $07
	SEG_FRAMES 4, %1000         ; CH4
	db $0C, $01, $07, $60       ; CH4: vol $01, slide $07, noise 96
	SFX_END

;; SFX $7C
Sfx7C:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $07
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $30, $01, $07, $60  ; CH4: instr 48, vol $01, slide $07, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0000
	SEGMENT $FF, %010
	SEG_HOLD $07
	SEG_FRAMES 4, %1000         ; CH4
	db $0C, $02, $07, $60       ; CH4: vol $02, slide $07, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0000
	SEGMENT $FF, %010
	SEG_HOLD $07
	SEG_FRAMES 4, %1000         ; CH4
	db $0C, $04, $07, $60       ; CH4: vol $04, slide $07, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0000
	SEGMENT $FF, %010
	SEG_HOLD $07
	SEG_FRAMES 4, %1000         ; CH4
	db $0C, $08, $07, $60       ; CH4: vol $08, slide $07, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0000
	SEGMENT $FF, %010
	SEG_HOLD $07
	SEG_FRAMES 4, %1000         ; CH4
	db $0C, $0B, $07, $60       ; CH4: vol $0B, slide $07, noise 96
	SFX_END
