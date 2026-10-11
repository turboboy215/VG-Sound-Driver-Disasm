; Metal Slug 2 (unlicensed) music byte code
IF !DEF(MS2_MACROS_INC)
DEF MS2_MACROS_INC EQU 1

; ---- song header: db channels - 1, then per channel:
MACRO STREAM             ; channel 0-3 (ch1-ch4), stream address
	db \1
	dw \2
ENDM

; ---- notes and rests
; Nsxl: semitone s (0-11, high nibble), length l (1-16, low nibble + 1); a note lasts
; (speed + 1) * l frames. NoteTable index = (5 - octave) * 12 + s + transpose (entry 1 = C2).
FOR S, 0, 12
	FOR LEN, 1, 17
		DEF N{d:S}x{d:LEN} EQU (S << 4) | (LEN - 1)
	ENDR
ENDR
FOR LEN, 1, 17
	DEF R{d:LEN} EQU $c0 | (LEN - 1)   ; rest
ENDR

; ---- commands
MACRO INSTR              ; speed, InstrEnv, InstrRelease, InstrDuty (ch3: wave offset, -, level)
	db $d0 | \1, \2, \3, \4
ENDM
MACRO OCTAVE             ; 0-5
	db $e0 | \1
ENDM
MACRO SPEED
	db $e6, \1
ENDM
MACRO CH3_FADEOUT_ON
	db $e7
ENDM
MACRO CH3_FADES_OFF
	db $e8
ENDM
MACRO CH3_FADEIN_ON
	db $e9
ENDM
MACRO TRANSPOSE          ; semitones, signed
	db $ea, LOW(\1)
ENDM
MACRO DROP_ON
	db $eb
ENDM
MACRO DROP_OFF
	db $ec
ENDM
MACRO CH3_SFX_PAUSE
	db $ed
ENDM
MACRO CH3_SFX_RESUME
	db $ee
ENDM
MACRO POKE               ; value, address in $C800-$C8FF
	db $ef, \1, LOW(\2)
ENDM
MACRO MARK
	db $fb
ENDM
MACRO JUMP
	db $fd
	dw \1
ENDM
MACRO REPEAT_MARK        ; go back to the MARK \1 more times
	db $fe, \1
ENDM
MACRO END_SONG               ; any byte $F0-$FA, $FC, $FF stops the music
	db $ff
ENDM
ENDC
