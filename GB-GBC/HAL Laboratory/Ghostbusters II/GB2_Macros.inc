; Ghostbusters II sound data macros

; header: channel 0-3 = music on NR1x-NR4x, 4-7 = SFX on the same hardware (channel & 3)
MACRO channel
	db \1
	dw \2
ENDM
MACRO end_header
	db $FF
ENDM

; notes: semitone constant, octave 0-7 (octave 0 = C2 in PeriodTable)
DEF C_ EQU 0
DEF C# EQU 1
DEF D_ EQU 2
DEF D# EQU 3
DEF E_ EQU 4
DEF F_ EQU 5
DEF F# EQU 6
DEF G_ EQU 7
DEF G# EQU 8
DEF A_ EQU 9
DEF A# EQU 10
DEF B_ EQU 11
MACRO note
	ASSERT (\2) < 8
	db ((\2) << 4) | (\1)
ENDM
MACRO drum          ; CH4: NoiseTable index
	db \1
ENDM
MACRO rest
	db $7C
ENDM
MACRO length        ; LengthTable index 0-63 (applies to the following notes)
	db $80 | (\1)
ENDM

MACRO envelope
	db $F0, \1
ENDM
MACRO duty          ; NRx1 value (OR $3F)
	db $F1, \1
ENDM
MACRO attenuate     ; subtracted from every envelope volume
	db $F2, \1
ENDM
MACRO transpose
	db $F3, \1
ENDM
MACRO loop          ; one level per channel
	db $F4, \1
ENDM
MACRO endloop
	db $F5
ENDM
MACRO snd_call      ; one level per channel
	db $F6
	dw \1
ENDM
MACRO snd_ret
	db $F7
ENDM
MACRO sweep         ; NR10 = n ^ 8 at every note (CH1)
	db $F8, \1
ENDM
MACRO sweep_off     ; NR10 = $08
	db $F9
ENDM
MACRO transpose_up
	db $FA
ENDM
MACRO snd_jump
	db $FB
	dw \1
ENDM
MACRO snd_nop
	db $FC
ENDM
MACRO play_sound    ; queue another sound id
	db $FD, \1
ENDM
MACRO snd_end_count ; end, counting hChannelsEnded
	db $FE
ENDM
MACRO snd_end
	db $FF
ENDM

; envelopes: (frames, volume) pairs; a step of $FF frames ends the envelope (holds 255 frames)
MACRO env_step
	db \1, \2
ENDM
MACRO env_hold
	db $FF, \1
ENDM
