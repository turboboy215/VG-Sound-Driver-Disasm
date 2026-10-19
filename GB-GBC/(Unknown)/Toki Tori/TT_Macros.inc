; Toki Tori sound data macros

IF !DEF(TT_MACROS_INC)
DEF TT_MACROS_INC EQU 1

DEF SND_BANK EQU $2D ; data banks are stored relative to this

; ---- notes (index into a 72-entry period table, C2 = 0)
DEF C_2 EQU 0
DEF Cs2 EQU 1
DEF D_2 EQU 2
DEF Ds2 EQU 3
DEF E_2 EQU 4
DEF F_2 EQU 5
DEF Fs2 EQU 6
DEF G_2 EQU 7
DEF Gs2 EQU 8
DEF A_2 EQU 9
DEF As2 EQU 10
DEF B_2 EQU 11
DEF C_3 EQU 12
DEF Cs3 EQU 13
DEF D_3 EQU 14
DEF Ds3 EQU 15
DEF E_3 EQU 16
DEF F_3 EQU 17
DEF Fs3 EQU 18
DEF G_3 EQU 19
DEF Gs3 EQU 20
DEF A_3 EQU 21
DEF As3 EQU 22
DEF B_3 EQU 23
DEF C_4 EQU 24
DEF Cs4 EQU 25
DEF D_4 EQU 26
DEF Ds4 EQU 27
DEF E_4 EQU 28
DEF F_4 EQU 29
DEF Fs4 EQU 30
DEF G_4 EQU 31
DEF Gs4 EQU 32
DEF A_4 EQU 33
DEF As4 EQU 34
DEF B_4 EQU 35
DEF C_5 EQU 36
DEF Cs5 EQU 37
DEF D_5 EQU 38
DEF Ds5 EQU 39
DEF E_5 EQU 40
DEF F_5 EQU 41
DEF Fs5 EQU 42
DEF G_5 EQU 43
DEF Gs5 EQU 44
DEF A_5 EQU 45
DEF As5 EQU 46
DEF B_5 EQU 47
DEF C_6 EQU 48
DEF Cs6 EQU 49
DEF D_6 EQU 50
DEF Ds6 EQU 51
DEF E_6 EQU 52
DEF F_6 EQU 53
DEF Fs6 EQU 54
DEF G_6 EQU 55
DEF Gs6 EQU 56
DEF A_6 EQU 57
DEF As6 EQU 58
DEF B_6 EQU 59
DEF C_7 EQU 60
DEF Cs7 EQU 61
DEF D_7 EQU 62
DEF Ds7 EQU 63
DEF E_7 EQU 64
DEF F_7 EQU 65
DEF Fs7 EQU 66
DEF G_7 EQU 67
DEF Gs7 EQU 68
DEF A_7 EQU 69
DEF As7 EQU 70
DEF B_7 EQU 71

; ---- row effects (effect byte)
DEF FX_ARPEGGIO         EQU $00
DEF FX_SLIDE_UP         EQU $01
DEF FX_SLIDE_DOWN       EQU $02
DEF FX_PORTA            EQU $03
DEF FX_VIBRATO          EQU $04
DEF FX_PORTA_VOLSLIDE   EQU $05
DEF FX_VIB_VOLSLIDE     EQU $06
DEF FX_TREMOLO          EQU $07
DEF FX_08               EQU $08
DEF FX_09               EQU $09
DEF FX_VOLSLIDE         EQU $0A
DEF FX_POS_JUMP         EQU $0B
DEF FX_SET_VOL          EQU $0C
DEF FX_PAT_BREAK        EQU $0D
DEF FX_0E               EQU $0E
DEF FX_SPEED            EQU $0F
DEF FX_E0               EQU $10
DEF FX_FINE_UP          EQU $11
DEF FX_FINE_DOWN        EQU $12
DEF FX_E3               EQU $13
DEF FX_E4               EQU $14
DEF FX_E5               EQU $15
DEF FX_E6               EQU $16
DEF FX_E7               EQU $17
DEF FX_E8               EQU $18
DEF FX_E9               EQU $19
DEF FX_FINE_VOL         EQU $1A
DEF FX_FINE_VOL_B       EQU $1B
DEF FX_EC               EQU $1C
DEF FX_ED               EQU $1D
DEF FX_EE               EQU $1E
DEF FX_EF               EQU $1F

; ---- tick effects (offsets into ChN_TickFxTable)
DEF TFX_NONE         EQU $00
DEF TFX_ARPEGGIO     EQU $02
DEF TFX_SLIDE_UP     EQU $04
DEF TFX_SLIDE_DOWN   EQU $06
DEF TFX_FINE_UP      EQU $08
DEF TFX_FINE_DOWN    EQU $0A
DEF TFX_PORTA_UP     EQU $0C
DEF TFX_PORTA_DOWN   EQU $0E
DEF TFX_VIBRATO      EQU $10
DEF TFX_TREMOLO      EQU $12
DEF TFX_VOLSLIDE     EQU $14
DEF TFX_FINE_VOL     EQU $16

; ---- pattern rows
; ROW note, instrument, volume, effect, param: a full row (5 bytes, note < $80)
MACRO ROW
	ASSERT (\1) < $80
	db \1, \2, \3, \4, \5
ENDM

; masked rows: one byte $80 | bits, then one byte per bit:
;   N note (bit 0), I instrument (1), V volume (2), X effect (3), P param (4)
; X without P: param 0.  P without X: effect 0 (FX_ARPEGGIO) with that param.
; A note without V sets the volume to $3F. ___ is an empty row ($80).
MACRO ___
	db $80
ENDM
MACRO R_N
	ASSERT _NARG == 1
	db $81, \#
ENDM
MACRO R_I
	ASSERT _NARG == 1
	db $82, \#
ENDM
MACRO R_NI
	ASSERT _NARG == 2
	db $83, \#
ENDM
MACRO R_V
	ASSERT _NARG == 1
	db $84, \#
ENDM
MACRO R_NV
	ASSERT _NARG == 2
	db $85, \#
ENDM
MACRO R_IV
	ASSERT _NARG == 2
	db $86, \#
ENDM
MACRO R_NIV
	ASSERT _NARG == 3
	db $87, \#
ENDM
MACRO R_X
	ASSERT _NARG == 1
	db $88, \#
ENDM
MACRO R_NX
	ASSERT _NARG == 2
	db $89, \#
ENDM
MACRO R_IX
	ASSERT _NARG == 2
	db $8A, \#
ENDM
MACRO R_NIX
	ASSERT _NARG == 3
	db $8B, \#
ENDM
MACRO R_VX
	ASSERT _NARG == 2
	db $8C, \#
ENDM
MACRO R_NVX
	ASSERT _NARG == 3
	db $8D, \#
ENDM
MACRO R_IVX
	ASSERT _NARG == 3
	db $8E, \#
ENDM
MACRO R_NIVX
	ASSERT _NARG == 4
	db $8F, \#
ENDM
MACRO R_P
	ASSERT _NARG == 1
	db $90, \#
ENDM
MACRO R_NP
	ASSERT _NARG == 2
	db $91, \#
ENDM
MACRO R_IP
	ASSERT _NARG == 2
	db $92, \#
ENDM
MACRO R_NIP
	ASSERT _NARG == 3
	db $93, \#
ENDM
MACRO R_VP
	ASSERT _NARG == 2
	db $94, \#
ENDM
MACRO R_NVP
	ASSERT _NARG == 3
	db $95, \#
ENDM
MACRO R_IVP
	ASSERT _NARG == 3
	db $96, \#
ENDM
MACRO R_NIVP
	ASSERT _NARG == 4
	db $97, \#
ENDM
MACRO R_XP
	ASSERT _NARG == 2
	db $98, \#
ENDM
MACRO R_NXP
	ASSERT _NARG == 3
	db $99, \#
ENDM
MACRO R_IXP
	ASSERT _NARG == 3
	db $9A, \#
ENDM
MACRO R_NIXP
	ASSERT _NARG == 4
	db $9B, \#
ENDM
MACRO R_VXP
	ASSERT _NARG == 3
	db $9C, \#
ENDM
MACRO R_NVXP
	ASSERT _NARG == 4
	db $9D, \#
ENDM
MACRO R_IVXP
	ASSERT _NARG == 4
	db $9E, \#
ENDM
; $9F: 5 bytes would follow, but Seq_FetchRow copies only 4
MACRO R_NIVXP_TRUNC
	db $9F, \#
ENDM

; ---- order list
; ORDER ch1, ch2, ch3, ch4, rows: four pattern streams played together for "rows" rows
MACRO ORDER
	REPT 4
		db BANK(\1) - SND_BANK, LOW(\1), HIGH(\1)
		SHIFT
	ENDR
	db \1, 0, 0, 0
ENDM
MACRO ORDER_END
	db $FF
	ds 15, 0
ENDM

; ---- song table entry: SONG orders, speed, loop entry (same bank)
MACRO SONG
	db BANK(\1) - SND_BANK, LOW(\1), HIGH(\1), \2, LOW(\3), HIGH(\3), 0, 0
ENDM

; ---- sound effects
MACRO SFX_ENTRY
	db BANK(\1) - SND_BANK, LOW(\1), HIGH(\1), 0
ENDM
; SFX_STEP frames, channel (0-3), register values. ch1 writes NR10-NR14 from the
; 1st-5th values, ch2 NR21-NR24 from the 2nd-5th, ch4 NR41-NR44 from the 1st-4th;
; ch3 has no SFX output. The next step (or SFX_END) is read after "frames" frames.
MACRO SFX_STEP
	db \1, ((_NARG - 2) << 4) | (\2)
	SHIFT 2
	db \#
ENDM
MACRO SFX_END
	db 0
ENDM

ENDC
