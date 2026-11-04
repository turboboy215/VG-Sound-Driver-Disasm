; =============================================================================
; lenar_sound.inc - macros and constants for the Lenar GB sound driver data
; (Knight Quest, Mercenary Force, Shisensho: Match-Mania)
; =============================================================================
IF !DEF(LENAR_SOUND_INC)
DEF LENAR_SOUND_INC EQU 1

; ---- note values (index into SndFreqTable) ----------------------------------
; Lenar (MF, KQ): $00 = C2 (65.4 Hz on ch1/ch2), 72 notes C2-B7.
; Shisensho (DEF SHISENSHO_NOTES before INCLUDE): $00 = C3, 48 notes C3-B6.
; On ch3 the same value sounds one octave lower.
; On ch4 the byte is written raw to NR43 (noise), so ch4 data uses hex values.
IF DEF(SHISENSHO_NOTES)
DEF C_3 EQU $00
DEF Cs3 EQU $01
DEF D_3 EQU $02
DEF Ds3 EQU $03
DEF E_3 EQU $04
DEF F_3 EQU $05
DEF Fs3 EQU $06
DEF G_3 EQU $07
DEF Gs3 EQU $08
DEF A_3 EQU $09
DEF As3 EQU $0A
DEF B_3 EQU $0B
DEF C_4 EQU $0C
DEF Cs4 EQU $0D
DEF D_4 EQU $0E
DEF Ds4 EQU $0F
DEF E_4 EQU $10
DEF F_4 EQU $11
DEF Fs4 EQU $12
DEF G_4 EQU $13
DEF Gs4 EQU $14
DEF A_4 EQU $15
DEF As4 EQU $16
DEF B_4 EQU $17
DEF C_5 EQU $18
DEF Cs5 EQU $19
DEF D_5 EQU $1A
DEF Ds5 EQU $1B
DEF E_5 EQU $1C
DEF F_5 EQU $1D
DEF Fs5 EQU $1E
DEF G_5 EQU $1F
DEF Gs5 EQU $20
DEF A_5 EQU $21
DEF As5 EQU $22
DEF B_5 EQU $23
DEF C_6 EQU $24
DEF Cs6 EQU $25
DEF D_6 EQU $26
DEF Ds6 EQU $27
DEF E_6 EQU $28
DEF F_6 EQU $29
DEF Fs6 EQU $2A
DEF G_6 EQU $2B
DEF Gs6 EQU $2C
DEF A_6 EQU $2D
DEF As6 EQU $2E
DEF B_6 EQU $2F
ELSE
DEF C_2 EQU $00
DEF Cs2 EQU $01
DEF D_2 EQU $02
DEF Ds2 EQU $03
DEF E_2 EQU $04
DEF F_2 EQU $05
DEF Fs2 EQU $06
DEF G_2 EQU $07
DEF Gs2 EQU $08
DEF A_2 EQU $09
DEF As2 EQU $0A
DEF B_2 EQU $0B
DEF C_3 EQU $0C
DEF Cs3 EQU $0D
DEF D_3 EQU $0E
DEF Ds3 EQU $0F
DEF E_3 EQU $10
DEF F_3 EQU $11
DEF Fs3 EQU $12
DEF G_3 EQU $13
DEF Gs3 EQU $14
DEF A_3 EQU $15
DEF As3 EQU $16
DEF B_3 EQU $17
DEF C_4 EQU $18
DEF Cs4 EQU $19
DEF D_4 EQU $1A
DEF Ds4 EQU $1B
DEF E_4 EQU $1C
DEF F_4 EQU $1D
DEF Fs4 EQU $1E
DEF G_4 EQU $1F
DEF Gs4 EQU $20
DEF A_4 EQU $21
DEF As4 EQU $22
DEF B_4 EQU $23
DEF C_5 EQU $24
DEF Cs5 EQU $25
DEF D_5 EQU $26
DEF Ds5 EQU $27
DEF E_5 EQU $28
DEF F_5 EQU $29
DEF Fs5 EQU $2A
DEF G_5 EQU $2B
DEF Gs5 EQU $2C
DEF A_5 EQU $2D
DEF As5 EQU $2E
DEF B_5 EQU $2F
DEF C_6 EQU $30
DEF Cs6 EQU $31
DEF D_6 EQU $32
DEF Ds6 EQU $33
DEF E_6 EQU $34
DEF F_6 EQU $35
DEF Fs6 EQU $36
DEF G_6 EQU $37
DEF Gs6 EQU $38
DEF A_6 EQU $39
DEF As6 EQU $3A
DEF B_6 EQU $3B
DEF C_7 EQU $3C
DEF Cs7 EQU $3D
DEF D_7 EQU $3E
DEF Ds7 EQU $3F
DEF E_7 EQU $40
DEF F_7 EQU $41
DEF Fs7 EQU $42
DEF G_7 EQU $43
DEF Gs7 EQU $44
DEF A_7 EQU $45
DEF As7 EQU $46
DEF B_7 EQU $47
ENDC

; ---- events -----------------------------------------------------------------
; $00-$7F  note: start a new row with this note (retriggers the channel)
; $90-$FF  set row length to (byte - $90) frames, keep reading
MACRO snd_len        ; frames per row (0-111); 0 would silence the track
    ASSERT (\1) < $70
    db $90 + (\1)
ENDM
MACRO snd_duty       ; $80 xx: +8  NRx1 (duty|length) / NR31 (length)
    db $80, \1
ENDM
MACRO snd_sweep      ; $81 xx: +7  NR10 (ch1 only)
    db $81, \1
ENDM
MACRO snd_transpose  ; $82 xx: +B  subtracted from notes (Lenar) / added (Shisensho)
    db $82, \1
ENDM
MACRO snd_env        ; $83 xx: +9  NRx2 envelope / NR32 output level
    db $83, \1
ENDM
MACRO snd_unused84   ; $84 xx: no effect
    db $84, \1
ENDM
MACRO snd_call       ; $85 addr: one-level subroutine call
    db $85
    dw \1
ENDM
MACRO snd_ret        ; $86: return from snd_call
    db $86
ENDM
MACRO snd_endsong    ; $86 outside a call: stop all 4 tracks of this set
    db $86
ENDM
MACRO snd_end        ; $87: stop this track only
    db $87
ENDM
MACRO snd_unused88   ; $88 xx: no effect
    db $88, \1
ENDM
MACRO snd_hold       ; $89: a row with no retrigger (previous note rings on)
    db $89
ENDM
MACRO snd_pan        ; $8A xx: NR51 = xx (global!)
    db $8A, \1
ENDM
MACRO snd_jump       ; $8B addr: jump (loops)
    db $8B
    dw \1
ENDM
MACRO snd_wave       ; $8C xx: load SndWaveTable+xx into wave RAM
    db $8C, \1
ENDM
MACRO snd_unused8d   ; $8D xx: no effect
    db $8D, \1
ENDM
MACRO snd_mastervol  ; $8E xx: NR50 = xx (global!)
    db $8E, \1
ENDM

ENDC
