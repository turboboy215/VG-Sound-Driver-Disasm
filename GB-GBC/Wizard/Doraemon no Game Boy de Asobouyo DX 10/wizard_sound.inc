; Wizard Game Boy sound driver (Doraemon DX 10, Doraemon no Quiz Boy) - shared definitions
; EQUs for the code, macros for the sound data only.

IF !DEF(WIZARD_SOUND_INC)
DEF WIZARD_SOUND_INC EQU 1

; ---- sound registers ----
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
DEF _AUD3WAVERAM EQU $FF30

; ---- track struct ($22 bytes, 8 of them at wSndTracks) ----
DEF TRK_PTR       EQU $00 ; 2: next row
DEF TRK_LENGTH    EQU $02 ; 2: frames left in the row (high byte always 0)
DEF TRK_GATE      EQU $04 ; 2: frames until release (length, or length+1 before a tie)
DEF TRK_VOLUME    EQU $06 ; high nibble: channel volume ($81)
DEF TRK_UNUSED7   EQU $07 ; cleared, never used
DEF TRK_UNUSED8   EQU $08 ; cleared, never used
DEF TRK_DUTY      EQU $09 ; NRx1 value ($90-$93)
DEF TRK_FLAGS     EQU $0A
DEF TRK_PERIOD    EQU $0B ; 2: period (music ch4: NR43 value, high byte 0)
DEF TRK_SP        EQU $0D ; 2: loop stack pointer
DEF TRK_STACK     EQU $0F ; 12: 4 loop entries (count, pointer)
DEF TRK_RETURN    EQU $18 ; 2: $86/$87 return pointer (shares the 4th loop entry)
DEF TRK_VOLENVPOS EQU $1B
DEF TRK_VOLENV    EQU $1C ; 2: volume envelope, 0 = none
DEF TRK_PITCHPOS  EQU $1E
DEF TRK_PITCHENV  EQU $1F ; 2: pitch envelope, 0 = none
DEF TRK_VOLOFS    EQU $21 ; added to the volume (Sound_SetVolOffset); not cleared by a new sound
DEF TRK_SIZE      EQU $22

; TRK_FLAGS bits
DEF TRKF_ON      EQU 0 ; note sounding: output pass writes the channel
DEF TRKF_BIT1    EQU 1 ; set at start, never read
DEF TRKF_KEYON   EQU 2 ; set at each key-on, never read
DEF TRKF_RELEASE EQU 3 ; take the channel out of NR51 at the next output pass

; envelope terminators
DEF ENV_HOLD EQU $80
DEF ENV_LOOP EQU $81

; ---- note values (MIDI number = value + 12; periods below C_2 are 0) ----

DEF C_0 EQU $00
DEF Cs0 EQU $01
DEF D_0 EQU $02
DEF Ds0 EQU $03
DEF E_0 EQU $04
DEF F_0 EQU $05
DEF Fs0 EQU $06
DEF G_0 EQU $07
DEF Gs0 EQU $08
DEF A_0 EQU $09
DEF As0 EQU $0A
DEF B_0 EQU $0B
DEF C_1 EQU $0C
DEF Cs1 EQU $0D
DEF D_1 EQU $0E
DEF Ds1 EQU $0F
DEF E_1 EQU $10
DEF F_1 EQU $11
DEF Fs1 EQU $12
DEF G_1 EQU $13
DEF Gs1 EQU $14
DEF A_1 EQU $15
DEF As1 EQU $16
DEF B_1 EQU $17
DEF C_2 EQU $18
DEF Cs2 EQU $19
DEF D_2 EQU $1A
DEF Ds2 EQU $1B
DEF E_2 EQU $1C
DEF F_2 EQU $1D
DEF Fs2 EQU $1E
DEF G_2 EQU $1F
DEF Gs2 EQU $20
DEF A_2 EQU $21
DEF As2 EQU $22
DEF B_2 EQU $23
DEF C_3 EQU $24
DEF Cs3 EQU $25
DEF D_3 EQU $26
DEF Ds3 EQU $27
DEF E_3 EQU $28
DEF F_3 EQU $29
DEF Fs3 EQU $2A
DEF G_3 EQU $2B
DEF Gs3 EQU $2C
DEF A_3 EQU $2D
DEF As3 EQU $2E
DEF B_3 EQU $2F
DEF C_4 EQU $30
DEF Cs4 EQU $31
DEF D_4 EQU $32
DEF Ds4 EQU $33
DEF E_4 EQU $34
DEF F_4 EQU $35
DEF Fs4 EQU $36
DEF G_4 EQU $37
DEF Gs4 EQU $38
DEF A_4 EQU $39
DEF As4 EQU $3A
DEF B_4 EQU $3B
DEF C_5 EQU $3C
DEF Cs5 EQU $3D
DEF D_5 EQU $3E
DEF Ds5 EQU $3F
DEF E_5 EQU $40
DEF F_5 EQU $41
DEF Fs5 EQU $42
DEF G_5 EQU $43
DEF Gs5 EQU $44
DEF A_5 EQU $45
DEF As5 EQU $46
DEF B_5 EQU $47
DEF C_6 EQU $48
DEF Cs6 EQU $49
DEF D_6 EQU $4A
DEF Ds6 EQU $4B
DEF E_6 EQU $4C
DEF F_6 EQU $4D
DEF Fs6 EQU $4E
DEF G_6 EQU $4F
DEF Gs6 EQU $50
DEF A_6 EQU $51
DEF As6 EQU $52
DEF B_6 EQU $53
DEF C_7 EQU $54
DEF Cs7 EQU $55
DEF D_7 EQU $56
DEF Ds7 EQU $57
DEF E_7 EQU $58
DEF F_7 EQU $59
DEF Fs7 EQU $5A
DEF G_7 EQU $5B
DEF Gs7 EQU $5C
DEF A_7 EQU $5D
DEF As7 EQU $5E
DEF B_7 EQU $5F
DEF C_8 EQU $60
DEF Cs8 EQU $61
DEF D_8 EQU $62
DEF Ds8 EQU $63
DEF E_8 EQU $64
DEF F_8 EQU $65
DEF Fs8 EQU $66
DEF G_8 EQU $67
DEF Gs8 EQU $68
DEF A_8 EQU $69
DEF As8 EQU $6A
DEF B_8 EQU $6B
DEF C_9 EQU $6C
DEF Cs9 EQU $6D
DEF D_9 EQU $6E
DEF Ds9 EQU $6F
DEF E_9 EQU $70
DEF F_9 EQU $71
DEF Fs9 EQU $72
DEF G_9 EQU $73
DEF Gs9 EQU $74
DEF A_9 EQU $75
DEF As9 EQU $76
DEF B_9 EQU $77
DEF C_10 EQU $78
DEF Cs10 EQU $79
DEF D_10 EQU $7A
DEF Ds10 EQU $7B
DEF E_10 EQU $7C

; ---- sound data macros ----
; note NAME, frames
MACRO note
    db \1, \2
ENDM
; noise NR43, frames  (music ch4 only: the byte goes to NR43 as is)
MACRO noise
    db \1, \2
ENDM
; tie frames: keep the current note sounding
MACRO tie
    db $7E, \1
ENDM
; rest frames
MACRO rest
    db $7F, \1
ENDM
; rawnote byte, frames: $7D prefix (not used by the data)
MACRO rawnote
    db $7D, \1, \2
ENDM
MACRO snd_end
    db $80
ENDM
; snd_volume 0-15
MACRO snd_volume
    db $81, \1
ENDM
; snd_loop count ... snd_endloop: the body plays count times; 4 levels
MACRO snd_loop
    db $82, \1
ENDM
MACRO snd_endloop
    db $83
ENDM
MACRO snd_wave
    db $84, \1
ENDM
MACRO snd_jump
    db $85
    dw \1
ENDM
MACRO snd_call
    db $86
    dw \1
ENDM
MACRO snd_ret
    db $87
ENDM
MACRO snd_volenv
    db $88, \1
ENDM
MACRO snd_pitchenv
    db $89, \1
ENDM
MACRO snd_panleft
    db $8A
ENDM
MACRO snd_panright
    db $8B
ENDM
MACRO snd_pancentre
    db $8C
ENDM
; snd_nop $8D-$8F
MACRO snd_nop
    db \1
ENDM
; snd_duty 0-3
MACRO snd_duty
    db $90 + (\1)
ENDM

ENDC
