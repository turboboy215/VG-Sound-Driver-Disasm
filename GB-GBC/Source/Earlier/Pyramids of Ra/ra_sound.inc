; Macros for the Pyramids of Ra sound driver (bank 2).
	IF !DEF(RA_SOUND_INC)
	DEF RA_SOUND_INC EQU 1

; song_header ch4, ch2, ch1, ch3, ticks_per_frame, bars, transpose1, transpose2
MACRO song_header
	dw \1, \2, \3, \4
	db \5, \6, \7, \8
ENDM

; ra_inst NR12, NR10, NR11, sfx_note, sfx_frames, vib_pattern, vib_step, vib_mask
MACRO ra_inst
	db \1, \2, \3, \4, \5, \6, \7, \8
ENDM

; Events are 5 bytes: a 12-bit bar number, a 12-bit tick in the bar
; (bar length $2FC ticks), then a MIDI status byte and one data byte.
; event bar, tick, status, data
MACRO event
	db (\1) >> 4, (((\1) & $0F) << 4) | ((\2) >> 8), (\2) & $FF, \3, \4
ENDM
; note_on bar, tick, midi_channel, note   (no note-offs: notes decay by envelope)
MACRO note_on
	event \1, \2, $90 | (\3), \4
ENDM
; prog_chg bar, tick, midi_channel, program   (the driver skips these)
MACRO prog_chg
	event \1, \2, $C0 | (\3), \4
ENDM
; track_end bar - sentinel one bar past the song; never reached because the
; song restarts when the bar counter reaches the header's bar count.
MACRO track_end
	event \1, 0, 0, 0
ENDM

; MIDI note numbers, C_4 = 60
	DEF _o = 0
	REPT 9
	DEF C_{d:_o} EQU 12 + _o*12 + 0
	DEF Cs{d:_o} EQU 12 + _o*12 + 1
	DEF D_{d:_o} EQU 12 + _o*12 + 2
	DEF Ds{d:_o} EQU 12 + _o*12 + 3
	DEF E_{d:_o} EQU 12 + _o*12 + 4
	DEF F_{d:_o} EQU 12 + _o*12 + 5
	DEF Fs{d:_o} EQU 12 + _o*12 + 6
	DEF G_{d:_o} EQU 12 + _o*12 + 7
	DEF Gs{d:_o} EQU 12 + _o*12 + 8
	DEF A_{d:_o} EQU 12 + _o*12 + 9
	DEF As{d:_o} EQU 12 + _o*12 + 10
	DEF B_{d:_o} EQU 12 + _o*12 + 11
	DEF _o += 1
	ENDR
	PURGE _o
	ENDC
