; =============================================================================
; QT_Macros.inc - data macros for the AudioArts "QuickThunder" Game Boy sound
; driver family (Michael Delaney / AudioArts, 1999-2001).
;
; Before INCLUDE-ing this file, a game source sets
;     DEF QT_STEP_SIZE EQU 2 | 4    ; bytes per step-list entry
; =============================================================================

; ---------------------------------------------------------------- hardware
DEF rNR10 EQU $FF10
DEF rNR11 EQU $FF11
DEF rNR12 EQU $FF12
DEF rNR13 EQU $FF13
DEF rNR14 EQU $FF14
DEF rNR21 EQU $FF16
DEF rNR22 EQU $FF17
DEF rNR23 EQU $FF18
DEF rNR24 EQU $FF19
DEF rNR30 EQU $FF1A
DEF rNR31 EQU $FF1B
DEF rNR32 EQU $FF1C
DEF rNR33 EQU $FF1D
DEF rNR34 EQU $FF1E
DEF rNR41 EQU $FF20
DEF rNR42 EQU $FF21
DEF rNR43 EQU $FF22
DEF rNR44 EQU $FF23
DEF rNR50 EQU $FF24
DEF rNR51 EQU $FF25
DEF rNR52 EQU $FF26
DEF rTIMA EQU $FF05
DEF rTMA  EQU $FF06
DEF rTAC  EQU $FF07
DEF rIF   EQU $FF0F
DEF rIE   EQU $FFFF
DEF _AUD3WAVERAM EQU $FF30

; ---------------------------------------------------------------- note names
; note 0 = C2 (FreqTable[0] = $002C, 65.4 Hz). The GBA source calls this "c1".
DEF NOTE_NUM = 0
FOR OCT, 2, 8
    DEF C{d:OCT}  EQU NOTE_NUM + 0
    DEF Cs{d:OCT} EQU NOTE_NUM + 1
    DEF D{d:OCT}  EQU NOTE_NUM + 2
    DEF Ds{d:OCT} EQU NOTE_NUM + 3
    DEF E{d:OCT}  EQU NOTE_NUM + 4
    DEF F{d:OCT}  EQU NOTE_NUM + 5
    DEF Fs{d:OCT} EQU NOTE_NUM + 6
    DEF G{d:OCT}  EQU NOTE_NUM + 7
    DEF Gs{d:OCT} EQU NOTE_NUM + 8
    DEF A{d:OCT}  EQU NOTE_NUM + 9
    DEF As{d:OCT} EQU NOTE_NUM + 10
    DEF B{d:OCT}  EQU NOTE_NUM + 11
    REDEF NOTE_NUM = NOTE_NUM + 12
ENDR

; ---------------------------------------------------------------- step lists
; STEP transpose, pattern [, unused]
MACRO STEP
    IF QT_STEP_SIZE == 2
        db \1, \2
    ELSE
        IF _NARG > 2
            db \1, \3
        ELSE
            db \1, 0
        ENDC
        dw \2
    ENDC
ENDM

; ---------------------------------------------------------------- patterns
; Every event starts with a length in ticks (1-254).
MACRO NOTE      ; length, note, instrument
    db \1, \2, \3
ENDM
MACRO HOLD      ; length            - nothing happens, the current note goes on
    db \1, $FF
ENDM
MACRO KEYOFF    ; length            - release: envelope register <- release value
    db \1, $FE
ENDM
MACRO KEYON     ; length            - retrigger with the attack value
    db \1, $FD
ENDM
MACRO PATEND    ; end of pattern: next step
    db 0
ENDM
MACRO SONGJUMP  ; step-list address: end of the song, continue (loop) there
    db $FF
    dw \1
ENDM
MACRO SFXEND    ; [ignored low byte] - end of a sound effect (high byte 0)
    IF _NARG > 0
        db 0, \1, 0
    ELSE
        db 0, 0, 0
    ENDC
ENDM
MACRO SFXLOOP   ; pattern address   - sound effect loops there
    db 0
    dw \1
ENDM

; ---------------------------------------------------------------- tables
; Walker tables: entries start with a length in ticks; length 0 ends the table
; and the next word is the address to continue from (usually a loop).
MACRO TB        ; length, value               (arp / combine / volume / noise tables)
    db \1, \2
ENDM
MACRO TW        ; length, signed 16-bit delta  (frequency tables)
    db \1
    dw \2
ENDM
MACRO MORPH     ; length, wave RAM register, value
    db \1, \2, \3
ENDM
MACRO TLOOP     ; continue at
    db 0
    dw \1
ENDM

; ---------------------------------------------------------------- instruments
; The driver loads a table pointer and steps once before reading, so the
; stored pointer is (first entry - entry size + 1): -1 for 2-byte tables,
; -2 for 3-byte tables.
MACRO INS_TONE  ; NRx1, envelope on, envelope off, arp, freq, combine
    db \1, \2, \3
    dw (\4) - 1, (\5) - 2, (\6) - 1
ENDM
MACRO INS_WAVE  ; volume on, volume off, arp, freq, combine
    dw (\1) - 1, (\2) - 1, (\3) - 1, (\4) - 2, (\5) - 1
ENDM
MACRO INS_NOISE ; NR41, envelope on, envelope off, NR43 table, NR44 table
    db \1, \2, \3
    dw (\4) - 1, (\5) - 1
ENDM
