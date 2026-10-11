; Tetris sound driver: song data macros and constants
IF !DEF(TET_MACROS_INC)
DEF TET_MACROS_INC EQU 1

; ---- song header
; SONG transpose, lengthTable, ch1List, ch2List, ch3List, ch4List   (0 = channel unused)
MACRO SONG
	db \1
	dw \2, \3, \4, \5, \6
ENDM

; ---- section lists
DEF LIST_END_WORD EQU $0000
MACRO LIST_END
	dw $0000
ENDM
MACRO LIST_LOOP          ; continue the list at \1
	dw $ffff, \1
ENDM

; ---- pattern bytes
DEF PAT_END EQU $00      ; end of pattern: next list entry
DEF REST    EQU $01
; notes: even bytes $02-$90 = offset into NoteTable (C2-B7)
DEF NOTE_C2 EQU $02
FOR OCT, 2, 8
	DEF C{d:OCT}  EQU NOTE_C2 + ((OCT-2)*12 + 0)*2
	DEF Cs{d:OCT} EQU NOTE_C2 + ((OCT-2)*12 + 1)*2
	DEF D{d:OCT}  EQU NOTE_C2 + ((OCT-2)*12 + 2)*2
	DEF Ds{d:OCT} EQU NOTE_C2 + ((OCT-2)*12 + 3)*2
	DEF E{d:OCT}  EQU NOTE_C2 + ((OCT-2)*12 + 4)*2
	DEF F{d:OCT}  EQU NOTE_C2 + ((OCT-2)*12 + 5)*2
	DEF Fs{d:OCT} EQU NOTE_C2 + ((OCT-2)*12 + 6)*2
	DEF G{d:OCT}  EQU NOTE_C2 + ((OCT-2)*12 + 7)*2
	DEF Gs{d:OCT} EQU NOTE_C2 + ((OCT-2)*12 + 8)*2
	DEF A{d:OCT}  EQU NOTE_C2 + ((OCT-2)*12 + 9)*2
	DEF As{d:OCT} EQU NOTE_C2 + ((OCT-2)*12 + 10)*2
	DEF B{d:OCT}  EQU NOTE_C2 + ((OCT-2)*12 + 11)*2
ENDR
; ch4: offsets into NoiseTable
DEF NOISE0 EQU $01
DEF NOISE1 EQU $06
DEF NOISE2 EQU $0b
DEF NOISE3 EQU $10
; lengths: $A0+n = entry n of the current length table
DEF L32  EQU $a0
DEF L16  EQU $a1
DEF L8   EQU $a2
DEF L4   EQU $a3
DEF L2   EQU $a4
DEF L1   EQU $a5
DEF L8D  EQU $a6
DEF L4D  EQU $a7
DEF L2D  EQU $a8
DEF L8T  EQU $a9
DEF L4T  EQU $aa
DEF LEN11 EQU $ab
DEF LEN12 EQU $ac
DEF LEN13 EQU $ad
DEF LEN14 EQU $ae
DEF LEN15 EQU $af

; ---- commands
; INSTR env, flag, duty   ch1/ch2: NRx2, (0), NRx1 (duty, length; low nibble also = vibrato type)
MACRO INSTR
	db $9d, \1, \2, \3
ENDM
; INSTR_WAVE wave, level   ch3: wave pointer, NR32 (bit 7 = short notes)
MACRO INSTR_WAVE
	db $9d
	dw \1
	db \2
ENDM
; Tetris has no other commands ($9E/$9F/$9B/$9C came with Dr. Mario)
ENDC
