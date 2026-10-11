; Sanrio Carnival 2 sound driver: data macros and constants
IF !DEF(S2_MACROS_INC)
DEF S2_MACROS_INC EQU 1

; ---------------------------------------------------------------- music streams
; A note byte (< $80) is followed by a packed length byte only when the channel's repeat counter has
; run out: the length byte applies to that note and the next count-1 notes.
;   note PITCH                 ; same length as the note before
;   note PITCH, index, count   ; length = wLengthTable[index] frames, for this note and count-1 more
; Pitch 0 = rest; 1 = C2 ... (NoteFreqTable entry pitch-1). On ch4 the pitch is a drum number.
MACRO note
	IF _NARG == 1
		db \1
	ELSE
		db \1, (\2) << 4 | ((\3) - 1)
	ENDC
ENDM

DEF REST EQU 0
FOR OCT, 2, 10
	DEF C_{d:OCT}  EQU (OCT-2)*12 + 1
	DEF Cs{d:OCT}  EQU (OCT-2)*12 + 2
	DEF D_{d:OCT}  EQU (OCT-2)*12 + 3
	DEF Ds{d:OCT}  EQU (OCT-2)*12 + 4
	DEF E_{d:OCT}  EQU (OCT-2)*12 + 5
	DEF F_{d:OCT}  EQU (OCT-2)*12 + 6
	DEF Fs{d:OCT}  EQU (OCT-2)*12 + 7
	DEF G_{d:OCT}  EQU (OCT-2)*12 + 8
	DEF Gs{d:OCT}  EQU (OCT-2)*12 + 9
	DEF A_{d:OCT}  EQU (OCT-2)*12 + 10
	DEF As{d:OCT}  EQU (OCT-2)*12 + 11
	DEF B_{d:OCT}  EQU (OCT-2)*12 + 12
ENDR

; commands $80-$9F
MACRO wave          ; $80: load the 16-byte wave at \1 (next frame)
	db $80
	dw \1
ENDM
MACRO master_vol    ; $81: NR50
	db $81, \1
ENDM
MACRO music_pan     ; $82: NR51 bits of the music (the SFX channels are ORed in)
	db $82, \1
ENDM
MACRO sweep1        ; $83: ch1 NR10
	db $83, \1
ENDM
MACRO duty1         ; $84: ch1 NR11
	db $84, \1
ENDM
MACRO duty2         ; $85: ch2 NR21
	db $85, \1
ENDM
MACRO len3          ; $86: ch3 NR31
	db $86, \1
ENDM
MACRO len4          ; $87: ch4 NR41
	db $87, \1
ENDM
MACRO env           ; $88-$8B: envelope macro of channel \1 (macro in the $6Dxx page)
	db $87 + (\1), LOW(\2)
ENDM
MACRO pitch         ; $8C-$8E: pitch macro of channel \1 (1-3)
	db $8b + (\1), LOW(\2)
ENDM
MACRO lengths       ; $8F: length table
	db $8f
	dw \1
ENDM
MACRO jump          ; $93
	db $93
	dw \1
ENDM
MACRO gosub         ; $94-$97: call, using the return stack of channel \1
	db $93 + (\1)
	dw \2
ENDM
MACRO endsub        ; $98-$9B: return, stack of channel \1
	db $97 + (\1)
ENDM
MACRO endch         ; $9C-$9F: channel \1 stops (silenced)
	db $9b + (\1)
ENDM

; envelope / pitch macro rows: frames, value (frames 0 = jump to LOW(\2) in the same page)
MACRO mrow
	db \1, \2
ENDM
MACRO mloop
	db 0, LOW(\1)
ENDM

; ---------------------------------------------------------------- SFX streams
MACRO sfx_channels  ; first byte: channels the effect takes (bit 0-3 = ch1-ch4)
	db \1
ENDM
; $00-$3F: register writes for channel \1 (1-4); \2 = which: 1 NRx0, 2 NRx1, 4 NRx2, 8 NRx3+NRx4,
; then the values. Any of NRx0-NRx2 = full write and trigger, NRx3/4 alone = frequency only.
MACRO sfx_regs
	db ((\1) - 1) << 4 | (\2)
	SHIFT 2
	REPT _NARG
		db \1
		SHIFT
	ENDR
ENDM
MACRO sfx_music     ; $40-$5F: bit 0 = 1 holds the music (no music updates), 0 resumes it
	db $40 | (\1)
ENDM
MACRO sfx_end       ; $60-$6F: end; silence the channels in \1 (bit 0-3) not owned by a higher slot
	db $60 | (\1)
ENDM
MACRO sfx_take      ; $70-$7F: change the channel set
	db $70 | (\1)
ENDM
MACRO sfx_wait      ; $80-$FF: wait \1 frames (1-128)
	db $80 | ((\1) & $7f)
ENDM

ENDC
