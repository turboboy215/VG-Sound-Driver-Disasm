; Biox sound driver "B" (Burger Burger Pocket = version 1, Daiku no Gensan = version 2)
; Track-data macros and note constants.
; Set BIOXB_VER to 1 or 2 before including this file.
;
;              v1 (BBP)     v2 (Daiku)
;  length      $00-$31      $00-$7F    set row length in ticks, keep reading
;  note        $32-$8F      $80-$D3    note index (+ transpose) into SndFreqTable
;  drum preset $90-$EC      $D4-$E3    NRx2 / NRx3 pair from the preset tables
;  commands    $ED-$FC      $E4-$FA

IF !DEF(BIOXB_SOUND_INC)
DEF BIOXB_SOUND_INC EQU 1

IF BIOXB_VER == 1
	DEF SNDB_NOTE  EQU $32
	DEF SNDB_DRUM  EQU $90
	DEF SNDB_CMD   EQU $ED      ; first command byte
ELSE
	DEF SNDB_NOTE  EQU $80
	DEF SNDB_DRUM  EQU $D4
	DEF SNDB_CMD   EQU $E4
ENDC

; ---- note constants: index 0 = C_2 (SndFreqTable[0] = $002C, 65.4 Hz on ch1/2)
DEF NOTE_IDX = 0
FOR OCT, 2, 11
	DEF C_{d:OCT}  EQU NOTE_IDX + 0
	DEF Cs_{d:OCT} EQU NOTE_IDX + 1
	DEF D_{d:OCT}  EQU NOTE_IDX + 2
	DEF Ds_{d:OCT} EQU NOTE_IDX + 3
	DEF E_{d:OCT}  EQU NOTE_IDX + 4
	DEF F_{d:OCT}  EQU NOTE_IDX + 5
	DEF Fs_{d:OCT} EQU NOTE_IDX + 6
	DEF G_{d:OCT}  EQU NOTE_IDX + 7
	DEF Gs_{d:OCT} EQU NOTE_IDX + 8
	DEF A_{d:OCT}  EQU NOTE_IDX + 9
	DEF As_{d:OCT} EQU NOTE_IDX + 10
	DEF B_{d:OCT}  EQU NOTE_IDX + 11
	REDEF NOTE_IDX = NOTE_IDX + 12
ENDR

MACRO snd_len            ; set row length (ticks)
	db \1
ENDM
MACRO snd_note           ; snd_note n [, len]  (len first, as stored)
	IF _NARG > 1
		db \2
	ENDC
	db SNDB_NOTE + (\1)
ENDM
MACRO snd_drum           ; drum preset n
	db SNDB_DRUM + (\1)
ENDM
MACRO snd_noise          ; len, NR42, NR43: direct ch4 note (any track)
	db SNDB_CMD + 0, \1, \2, \3
ENDM
MACRO snd_hold           ; wait one row, previous note keeps sounding (arg byte skipped)
	db SNDB_CMD + 1, \1
ENDM
MACRO snd_off            ; key off (envelope 0 + trigger) and rest
	db SNDB_CMD + 2
ENDM
MACRO snd_end            ; end of track
	db SNDB_CMD + 3
ENDM
MACRO snd_jump
	db SNDB_CMD + 4
	dw \1
ENDM
MACRO snd_call           ; one level only
	db SNDB_CMD + 5
	dw \1
ENDM
MACRO snd_ret
	db SNDB_CMD + 6
ENDM
MACRO snd_loop           ; loop start, count
	db SNDB_CMD + 7, \1
ENDM
MACRO snd_endloop        ; back to loop start until count runs out
	db SNDB_CMD + 8
ENDM
MACRO snd_tempo          ; ticks per frame = t/150 (v2), t/300 (v1)
	db SNDB_CMD + 9, \1
ENDM
MACRO snd_env            ; NRx2 (ch3: NR32)
	db SNDB_CMD + 10, \1
ENDM
MACRO snd_pitchenv       ; additive pitch envelope (0 = off)
	db SNDB_CMD + 11
	dw \1
ENDM
MACRO snd_nop
	db SNDB_CMD + 12
ENDM
MACRO snd_duty           ; NRx1 (written immediately)
	db SNDB_CMD + 13, \1
ENDM
MACRO snd_pan            ; NR51 (global)
	db SNDB_CMD + 14, \1
ENDM
MACRO snd_transpose      ; added to every note index
	db SNDB_CMD + 15, \1
ENDM
IF BIOXB_VER == 2
MACRO snd_vol            ; NRx2 high nibble (arg is $x0)
	db $F4, \1
ENDM
MACRO snd_envlo          ; NRx2 low nibble (arg is $0x)
	db $F5, \1
ENDM
MACRO snd_octenv         ; octave-shift envelope (0 = off)
	db $F6
	dw \1
ENDM
MACRO snd_wave           ; load wave RAM, remember previous wave
	db $F7
	dw \1
ENDM
MACRO snd_wave_restore   ; reload the previous wave
	db $F8
ENDM
MACRO snd_env2           ; NRx2 (same as snd_env)
	db $F9, \1
ENDM
MACRO snd_ch3len         ; nonzero = NR34 length-enable bit on ch3 notes
	db $FA, \1
ENDM
ENDC

; envelope streams (snd_pitchenv / snd_octenv)
MACRO env_stop
	db $80
ENDM
MACRO env_jump
	db $81
	dw \1
ENDM

ENDC
