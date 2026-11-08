; Macros for the Source sound driver.
;   SRC_VER 1 = Workboy, SRC_VER 2 = Double Dragon 3. Define SRC_VER before INCLUDE.
	IF !DEF(SOURCE_SOUND_INC)
	DEF SOURCE_SOUND_INC EQU 1

; ---- note indexes into the 48-entry frequency table (C_2 = 0 ... B_5 = 47) ----
	DEF _o = 2
	REPT 5
	DEF C_{d:_o} EQU (_o-2)*12 + 0
	DEF Cs{d:_o} EQU (_o-2)*12 + 1
	DEF D_{d:_o} EQU (_o-2)*12 + 2
	DEF Ds{d:_o} EQU (_o-2)*12 + 3
	DEF E_{d:_o} EQU (_o-2)*12 + 4
	DEF F_{d:_o} EQU (_o-2)*12 + 5
	DEF Fs{d:_o} EQU (_o-2)*12 + 6
	DEF G_{d:_o} EQU (_o-2)*12 + 7
	DEF Gs{d:_o} EQU (_o-2)*12 + 8
	DEF A_{d:_o} EQU (_o-2)*12 + 9
	DEF As{d:_o} EQU (_o-2)*12 + 10
	DEF B_{d:_o} EQU (_o-2)*12 + 11
	DEF _o += 1
	ENDR
	PURGE _o

	IF SRC_VER == 1
	DEF SRC_NOTE_BASE EQU $30	; sequence byte = $30 + index
	ELSE
	DEF SRC_NOTE_BASE EQU $24	; ch1/ch2 byte = $24 + index (ch4 subtracts $48)
	ENDC

; ---- sequences ----
; note NOTE, len   (v1: len in frames; v2: length code 1-6, see DdDurTable)
MACRO note
	db SRC_NOTE_BASE + (\1), \2
ENDM
; rest len  (note byte 0)
MACRO rest
	db 0, \1
ENDM
; drum byte, len  (v2 ch4: any nonzero byte below $78 hits the single drum instrument)
MACRO drum
	db \1, \2
ENDM
	IF SRC_VER == 1
; snd_inst n - $F0-$FE; the driver skips the byte and discards n
MACRO snd_inst
	db $F0 | (\1)
ENDM
; snd_end - $FF stops all music; the $01 after it is never read
MACRO snd_end
	db $FF, $01
ENDM
	ELSE
; snd_loop - $FE restarts the current song (all channels)
MACRO snd_loop
	db $FE
ENDM
; snd_end - $FF stops all music
MACRO snd_end
	db $FF
ENDM
	ENDC

; ---- pitch envelopes ----
; env_step delta, steps, frames_per_step
MACRO env_step
	db LOW(\1), \2, \3
ENDM
MACRO env_end
	db $63
ENDM

; ---- instruments (first byte = channel) ----
; inst_pulse1 NR11, NR12, envelope   (v2: only the NR12 low nibble is used)
MACRO inst_pulse1
	db 1, \1, \2
	dw \3
ENDM
; inst_pulse2 NR21, NR22, envelope
MACRO inst_pulse2
	db 2, \1, \2
	dw \3
ENDM
; inst_wave NR32, envelope, wave (v1 only)
MACRO inst_wave
	db 3, \1
	dw \2, \3
ENDM
; inst_noise NR42, NR43
MACRO inst_noise
	db 4, \1, \2
ENDM

; ---- DD3 sound effects (5 bytes) ----
MACRO sfx_noise
	db \1, \2, \3, \4, \5
ENDM
MACRO sfx_pulse
	db \1, \2, \3, \4, \5
ENDM
	ENDC
