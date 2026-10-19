; Kirby Tilt 'n' Tumble sound driver: song data macros and constants
IF !DEF(KTT_MACROS_INC)
DEF KTT_MACROS_INC EQU 1

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
MACRO LIST_LOOP          ; continue the list at \1 (a loop, or a jump to another list fragment)
	dw $ffff, \1
ENDM
; list commands: a word between two patterns (only the low byte of the operand is used)
MACRO LIST_TRANSPOSE     ; set this channel's transpose (bytes: 2 per semitone)
	dw $ff96, \1
ENDM
MACRO LIST_TRANSPOSE_ADD ; add to this channel's transpose
	dw $ff95, \1
ENDM
MACRO LIST_ENV_SET       ; set the instrument's NRx2 byte
	dw $ff94, \1
ENDM
MACRO LIST_ENV_ADD       ; add to it (signed; an add that would wrap is ignored)
	dw $ff93, \1
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
; ch4: offsets into the current drum kit (default NoiseTable: 1 + 5n, 25 entries)
FOR N, 1, 126, 5
	DEF NOISE_{02X:N} EQU N
ENDR
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
; INSTR env, $00, duty        ch1/ch2/ch4: NRx2 and NRx1 (low nibble of duty: pitch effect)
; INSTR_ENV table, duty       per-frame NRx2 table (first 48 frames of a note, 0 = no write)
MACRO INSTR
	db $9d, \1, \2, \3
ENDM
MACRO INSTR_ENV
	db $9d
	dw \1
	db \2
ENDM
; INSTR_WAVE wave, level   ch3: wave pointer, NR32
MACRO INSTR_WAVE
	db $9d
	dw \1
	db \2
ENDM
MACRO REPEAT             ; play the following up to REPEAT_END \1 times
	db $9b, \1
ENDM
MACRO REPEAT_END
	db $9c
ENDM
MACRO DROP_ON            ; period falls 32 per frame
	db $97
ENDM
MACRO DROP_OFF
	db $98
ENDM
MACRO VOLUME             ; NR50 = \1 & $77
	db $9a, \1
ENDM
MACRO REST_ENV           ; NRx2 written for rests (ch1/ch2)
	db $99, \1
ENDM
MACRO TEMPO              ; select length table
	db $9e
	dw \1
ENDM
MACRO TRANSPOSE          ; set this channel's transpose (ch1-ch3, bytes: 2 per semitone)
	db $96, \1
ENDM
MACRO TRANSPOSE_ADD      ; add to this channel's transpose
	db $95, \1
ENDM
MACRO ENV_SET            ; set the instrument's NRx2 byte (ch1/ch2, not with an envelope table)
	db $94, \1
ENDM
MACRO ENV_ADD            ; add to it (signed; an add that would wrap is ignored)
	db $93, \1
ENDM
MACRO DRUMKIT            ; ch4 notes index this table from now on
	db $92
	dw \1
ENDM
ENDC
