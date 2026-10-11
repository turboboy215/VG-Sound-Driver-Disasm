; Link's Awakening DX sound driver: song data macros and constants
IF !DEF(LA_MACROS_INC)
DEF LA_MACROS_INC EQU 1

; ---- song header
; SONG transpose, lengthTable, ch1List, ch2List, ch3List, ch4List   (0 = unused)
MACRO SONG
	db \1
	dw \2, \3, \4, \5, \6
ENDM

; ---- section lists
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
; ch4: offsets into NoiseTable (1 + 5n); DRUM = the two-step drum on ch4
FOR N, 1, 81, 5
	DEF NOISE_{02X:N} EQU N
ENDR
DEF DRUM EQU $ff
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
DEF LEN9  EQU $a9    ; entries 9-13 differ from table to table (triplets, short values)
DEF LEN10 EQU $aa
DEF LEN11 EQU $ab
DEF LEN12 EQU $ac
DEF LEN13 EQU $ad
DEF L1D  EQU $ae      ; dotted whole note
DEF LEN15 EQU $af

; ---- commands
; INSTR env, release, duty   ch1/ch2: NRx2; release (bit 7: at 1/2, bit 6: at 1/4, else at 3/4 of the length;
;                            low nibble: ReleaseEnvelopes index); NRx1 (low nibble: pitch effect)
MACRO INSTR
	db $9d, \1, \2, \3
ENDM
; INSTR_WAVE wave, level   ch3: wave pointer, NR32 (bit 7: 50% for the last 6 frames)
MACRO INSTR_WAVE
	db $9d
	dw \1
	db \2
ENDM
MACRO TEMPO              ; select length table
	db $9e
	dw \1
ENDM
MACRO TRANSPOSE          ; in bytes: 2 per semitone
	db $9f, \1
ENDM
MACRO REPEAT             ; play the following up to REPEAT_END \1 times
	db $9b, \1
ENDM
MACRO REPEAT_END
	db $9c
ENDM
MACRO CH3_FADEOUT_ON     ; ch3 volume steps down after each note starts
	db $99
ENDM
MACRO CH3_FADEOUT_OFF
	db $9a
ENDM
MACRO CH3_FADEIN_ON      ; ch3 volume steps up after each note starts
	db $94
ENDM
MACRO DROP_ON            ; period falls 100 per frame
	db $97
ENDM
MACRO DROP_OFF
	db $98
ENDM
MACRO CH3_SFX_PAUSE      ; the ch3 SFX stops being updated
	db $96
ENDM
MACRO CH3_SFX_RESUME
	db $95
ENDM
ENDC
