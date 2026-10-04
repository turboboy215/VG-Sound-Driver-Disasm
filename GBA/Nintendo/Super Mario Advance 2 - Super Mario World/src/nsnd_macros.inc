@ Macros for the sound data of the SMA2/SMA3/SMA4/ALttP driver.
@ Define GEN_A before including this file for the Super Mario Advance 2 data
@ (1-byte tempo command, no song-volume command).

@ ---- key names: c4 = 60 --------------------------------------------------------
	.irp o, 0,1,2,3,4,5,6,7,8,9
	.equ c\o, 12*(\o+1)+0
	.equ cs\o, 12*(\o+1)+1
	.equ d\o, 12*(\o+1)+2
	.equ ds\o, 12*(\o+1)+3
	.equ e\o, 12*(\o+1)+4
	.equ f\o, 12*(\o+1)+5
	.equ fs\o, 12*(\o+1)+6
	.equ g\o, 12*(\o+1)+7
	.equ gs\o, 12*(\o+1)+8
	.equ a\o, 12*(\o+1)+9
	.equ as\o, 12*(\o+1)+10
	.equ b\o, 12*(\o+1)+11
	.endr
	.equ cm1,0
	.equ csm1,1
	.equ dm1,2
	.equ dsm1,3
	.equ em1,4
	.equ fm1,5
	.equ fsm1,6
	.equ gm1,7
	.equ gsm1,8
	.equ am1,9
	.equ asm1,10
	.equ bm1,11

@ ---- instruments -----------------------------------------------------------------
@ type 0 sample, 1 square 1, 2 square 2, 3 wave, 4 noise
	.macro inst type, flags, data, env, release, root
	.byte \type, \flags
	.hword \data, \env
	.byte \release, \root
	.endm
	.macro inst_kit table, base, b5, b6, b7, flags=0	@ type 0x10 drum kit
	.byte 0x10, \flags
	.hword \table
	.byte \base, \b5, \b6, \b7
	.endm
	.macro inst_split table, flags=0		@ type 0x12 key split (4-byte record)
	.byte 0x12, \flags
	.hword \table
	.endm
	.macro inst_skit table, flags=0		@ type 0x11 sample kit (4-byte record)
	.byte 0x11, \flags
	.hword \table
	.endm

@ ---- sequences -------------------------------------------------------------------
	.macro vl v			@ variable length, 1 byte (0-127)
	.byte \v
	.endm
	.macro vl2 v			@ variable length, 2 bytes (the encoder also used it for small values)
	.byte 0x80 | ((\v) >> 8), (\v) & 0xFF
	.endm
	.macro n key			@ note with the previous length and velocity
	.byte \key
	.endm
	.macro nl key, len, vel		@ note, length (ticks), velocity
	.byte 0x60 + \key
	vl \len
	.byte \vel
	.endm
	.macro nl2 key, len, vel
	.byte 0x60 + \key
	vl2 \len
	.byte \vel
	.endm
	.macro rest
	.byte 0xC0
	.endm
	.macro restn t
	.byte 0xC1
	vl \t
	.endm
	.macro restn_2 t
	.byte 0xC1
	vl2 \t
	.endm
	.macro program p
	.byte 0xC2, \p
	.endm
	.macro pan p
	.byte 0xC3, \p
	.endm
	.macro priority p
	.byte 0xC4, \p
	.endm
	.macro tie_on
	.byte 0xC5
	.endm
	.macro tie_off
	.byte 0xC6
	.endm
	.macro bank b
	.byte 0xC7, \b
	.endm
	.macro notes_advance
	.byte 0xC8
	.endm
	.macro notes_chord
	.byte 0xC9
	.endm
	.macro hook v
	.byte 0xCA, \v
	.endm
	.macro porta mode, key, len, delay
	.ifb \delay
	.byte 0xD0 | \mode, \key, \len
	.else
	.byte 0xD0 | \mode, \key, \len, \delay
	.endif
	.endm
	.macro volume v
	.byte 0xE0, \v
	.endm
	.macro bend v
	.byte 0xE1, \v
	.endm
	.macro bend_range v
	.byte 0xE2, \v
	.endm
	.macro echo v
	.byte 0xE3, \v
	.endm
	.ifdef GEN_A
	.macro tempo t
	.byte 0xE4, \t
	.endm
	.else
	.macro tempo t
	.byte 0xE4
	vl \t
	.endm
	.macro tempo_2 t
	.byte 0xE4
	vl2 \t
	.endm
	.endif
	.macro lfo_delay v
	.byte 0xE5, \v
	.endm
	.macro lfo_speed v
	.byte 0xE6, \v
	.endm
	.macro lfo_depth v
	.byte 0xE7, \v
	.endm
	.macro porta_off
	.byte 0xE8
	.endm
	.macro transpose v
	.byte 0xE9, \v
	.endm
	.macro song_volume v
	.byte 0xEA, \v
	.endm
	.macro jump ofs			@ offsets are relative to the song / sound-effect set
	.byte 0xF0
	.hword \ofs
	.endm
	.macro call ofs
	.byte 0xF4
	.hword \ofs
	.endm
	.macro start_track slot, ofs
	.byte 0xF8, \slot
	.hword \ofs
	.endm
	.macro end
	.byte 0xFF
	.endm
