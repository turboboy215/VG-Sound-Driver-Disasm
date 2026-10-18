; HAL Laboratory GB sound engine - data macros (KDL command set)

; ---- track header ----
DEF CH1 EQU $00   ; register offset / 4 selects NR1x
DEF CH2 EQU $04
DEF CH4 EQU $0C
DEF CH3 EQU $10

MACRO track ; pointer, channel
	dw \1
	db \2
ENDM

; ---- main stream ----
; note offset, len    offset -15..15 from the base note, len = index 0-5 into the length set
MACRO note
	ASSERT (\2) >= 0 && (\2) < 6
	ASSERT (\1) >= -15 && (\1) <= 15
	db ((\2) << 5) | ((\1) & $1F)
ENDM
MACRO note_x ; offset, frames
	db $C0 | ((\1) & $1F), \2
ENDM
MACRO rest ; len index
	db ((\1) << 5) | $10
ENDM
MACRO rest_x ; frames
	db $D0, \1
ENDM
; noise track: drum n (0-14 = NoiseTable entry; +16 = trigger without a new NR43), $0F = rest
MACRO drum
	ASSERT (\2) >= 0 && (\2) < 6
	db ((\2) << 5) | (\1)
ENDM
MACRO drum_x
	db $C0 | (\1), \2
ENDM
MACRO drest
	db ((\1) << 5) | $0F
ENDM
MACRO drest_x
	db $CF, \1
ENDM

MACRO sync          ; game-visible marker (wSoundSync)
	db $E1, \1
ENDM
MACRO frequency     ; set the period directly and restart the envelope
	db $E2
	dw \1
ENDM
MACRO detune        ; period -= n (signed): positive lowers the pitch
	db $E3, \1
ENDM
MACRO volume        ; channel volume 0-15
	db $F0, \1
ENDM
MACRO volume_add    ; channel volume += n (clamped)
	db $F1, \1
ENDM
MACRO length_set    ; select length set n (6 entries each)
	db $F2, \1
ENDM
MACRO hold          ; wait n frames, no new note
	db $F3, \1
ENDM
MACRO gate          ; release after len*n/256 frames (0 = never)
	db $F4, \1
ENDM
MACRO base_note
	db $F5, \1
ENDM
DEF STATIC EQU $80
MACRO instrument    ; n [, STATIC]: STATIC runs the envelope once now instead of per note
	IF _NARG == 2
		db $F6, (\1) | (\2)
	ELSE
		db $F6, \1
	ENDC
ENDM
MACRO tuning
	db $F7, \1
ENDM
MACRO snd_jump
	db $F8
	dw \1
ENDM
MACRO snd_call
	db $FA
	dw \1
ENDM
MACRO snd_ret
	db $FB
ENDM
MACRO snd_loop      ; count
	db $FC, \1
ENDM
MACRO snd_endloop
	db $FD
ENDM
DEF PAN_OFF EQU 0
DEF PAN_L   EQU 1   ; bit 0: left output (NR51 bits 4-7)
DEF PAN_R   EQU 2   ; bit 1: right output (NR51 bits 0-3)
DEF PAN_LR  EQU 3
MACRO pan
	db $FE, \1
ENDM
MACRO snd_end
	db $FF
ENDM

; ---- envelope (instrument macro) stream ----
DEF WAIT EQU $10    ; optional 2nd argument: wait 1 frame after this step
MACRO env_wait
	ASSERT (\1) < 32
	db \1
ENDM
MACRO env_pitch
	IF _NARG == 2
		db $20 | ((\1) & $0F) | (\2)
	ELSE
		db $20 | ((\1) & $0F)
	ENDC
ENDM
MACRO env_vol
	IF _NARG == 2
		db $40 | (\1) | (\2)
	ELSE
		db $40 | (\1)
	ENDC
ENDM
MACRO env_vol_add
	IF _NARG == 2
		db $60 | ((\1) & $0F) | (\2)
	ELSE
		db $60 | ((\1) & $0F)
	ENDC
ENDM
MACRO env_timbre    ; duty 0-3 (ch1/2/4) or wave number (ch3)
	IF _NARG == 2
		db $80 | (\1) | (\2)
	ELSE
		db $80 | (\1)
	ENDC
ENDM
MACRO env_reg0      ; NR10 (sweep) / NR30
	db $F0, \1
ENDM
MACRO env_jump
	db $F8
	dw \1
ENDM
MACRO env_call
	db $FA
	dw \1
ENDM
MACRO env_ret
	db $FB
ENDM
MACRO env_loop
	db $FC, \1
ENDM
MACRO env_endloop
	db $FD
ENDM
MACRO env_end
	db $FF
ENDM

; ---- tables ----
MACRO dwbe          ; big-endian word (period table)
	db HIGH(\1), LOW(\1)
ENDM
MACRO instr         ; attack envelope, release envelope
	dw \1, \2
ENDM
