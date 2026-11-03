; Biox / Japan System House sound driver "A" (Noobow, Pocket Bowling)
; Track-data macros and note constants.
;
; Track bytes:
;   $00-$9F  note (hi nibble = octave row, lo nibble 0-B = C..B, C = next C,
;            D-F = rest). On the noise channel the byte is swapped into NR43.
;            An optional $Ax byte directly after the note sets the length.
;   $A0-$AF  length index (into SndLengthTable). Alone it re-strikes the last
;            note with the new length (or just extends it after snd_tie).
;   $B0-$DF  end of track (no handler)
;   $E0-$FF  commands (see below)

IF !DEF(BIOXA_SOUND_INC)
DEF BIOXA_SOUND_INC EQU 1

; ---- note constants -------------------------------------------------------
; octave number in the name = hi nibble + 1, so $10 = C_2 (65.4 Hz on ch1/2).
; Lo nibble $C is the C of the next octave, written Bs_n (B sharp).
FOR OCT, 1, 10
	DEF C_{d:OCT}  EQU ((OCT-1) << 4) | $0
	DEF Cs_{d:OCT} EQU ((OCT-1) << 4) | $1
	DEF D_{d:OCT}  EQU ((OCT-1) << 4) | $2
	DEF Ds_{d:OCT} EQU ((OCT-1) << 4) | $3
	DEF E_{d:OCT}  EQU ((OCT-1) << 4) | $4
	DEF F_{d:OCT}  EQU ((OCT-1) << 4) | $5
	DEF Fs_{d:OCT} EQU ((OCT-1) << 4) | $6
	DEF G_{d:OCT}  EQU ((OCT-1) << 4) | $7
	DEF Gs_{d:OCT} EQU ((OCT-1) << 4) | $8
	DEF A_{d:OCT}  EQU ((OCT-1) << 4) | $9
	DEF As_{d:OCT} EQU ((OCT-1) << 4) | $A
	DEF B_{d:OCT}  EQU ((OCT-1) << 4) | $B
	DEF Bs_{d:OCT} EQU ((OCT-1) << 4) | $C
ENDR
DEF REST EQU $0D            ; the only rest value either game uses

; ---- notes / lengths ------------------------------------------------------
; snd_note n [, len]   note byte, optionally followed by a length byte $A0|len
MACRO snd_note
	db \1
	IF _NARG > 1
		db $A0 | (\2)
	ENDC
ENDM
; snd_len len          lone length byte: re-strike last note (or extend after snd_tie)
MACRO snd_len
	db $A0 | (\1)
ENDM

; ---- commands -------------------------------------------------------------
MACRO snd_end_e0       ; $E0 end of track (same handler as $FF)
	db $E0
ENDM
MACRO snd_sweep        ; $E1 xx  NR10 = xx (music ch1 only)
	db $E1, \1
ENDM
MACRO snd_inst         ; $E2 xx  envelope sequence xx (ch1/2/4), wave xx (ch3)
	db $E2, \1
ENDM
MACRO snd_duty         ; $E3 xx  NR11 = xx (music ch1 only)
	db $E3, \1
ENDM
MACRO snd_vibrato      ; $E4 xx  vibrato table entry xx (taken by the next note)
	db $E4, \1
ENDM
MACRO snd_env          ; $E5 xx  NRx2 volume envelope (ch3: NR32 level)
	db $E5, \1
ENDM
MACRO snd_tempo        ; $E6 xx  timer modulo (TMA) = xx; 0 = keep
	db $E6, \1
ENDM
MACRO snd_unused_e7    ; $E7 ww  stores -ww in hSndUnusedCE (never read)
	db $E7
	dw \1
ENDM
MACRO snd_unused_e8    ; $E8 ww  stores ww in hSndUnusedCE (never read)
	db $E8
	dw \1
ENDM
MACRO snd_pan          ; $EB xx  0 = off, 1 = right, 2 = left, 3 = both
	db $EB, \1
ENDM
MACRO snd_call         ; $EE ptr  call (4-level stack per track)
	db $EE
	dw \1
ENDM
MACRO snd_ret          ; $EF     return
	db $EF
ENDM
MACRO snd_loop         ; $F0 count, counter, ptr
	db $F0, \1, \2
	dw \3
ENDM
MACRO snd_jump         ; $F1 ptr
	db $F1
	dw \1
ENDM
MACRO snd_mastervol    ; $F2 xx  NR50 = xx
	db $F2, \1
ENDM
MACRO snd_tie          ; $F3     next lone length byte extends the note
	db $F3
ENDM
MACRO snd_rawnote      ; $F4 nn [, len]  note byte without the $A0 range check
	db $F4, \1
	IF _NARG > 1
		db $A0 | (\2)
	ENDC
ENDM
MACRO snd_slur         ; $F5     next note changes pitch without retrigger
	db $F5
ENDM
MACRO snd_length       ; $FE xx  (Pocket Bowling only) row length = xx ticks for the next note(s)
	db $FE, \1
ENDM
MACRO snd_end          ; $FF     end of track
	db $FF
ENDM

; ---- headers ---------------------------------------------------------------
DEF SND_NONE EQU $FFFF       ; unused channel pointer

ENDC
