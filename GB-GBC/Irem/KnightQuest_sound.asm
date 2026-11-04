; ==============================================================================
; Lenar sound driver - Knight Quest (U)
; Disassembly of the sound driver code, tables and all music/SFX data (bank 3).
; Builds byte-exact with RGBDS:  rgbasm -o snd.o KnightQuest_sound.asm ; rgblink -p 0xFF -o snd.gb snd.o
; ==============================================================================

INCLUDE "hardware.inc"
INCLUDE "lenar_sound.inc"

; ---- RAM ----------------------------------------------------------------------
; Two sets of 4 tracks, $10 bytes each (one track per hardware channel):
;   wSndSfxTracks   $DF00-$DF3F  (priority set)
;   wSndMusicTracks $DF40-$DF7F
; Track layout: +0 row length (0 = idle)  +1 frame counter  +2/+3 data pointer
;   +4/+5 return pointer  +6 call flag  +7 NR10 sweep  +8 duty/length (NRx1)
;   +9 envelope/volume (NRx2)  +A current note  +B transpose  +C..+F unused
;   (+E of track 0 and track 1 of the SFX set double as the two request bytes)
DEF wSndSfxTracks   EQU $DF00
DEF wSndMusicTracks EQU $DF40
DEF wSndReqSfx      EQU $DF1E  ; write a SndTable id here to start it in the SFX set
DEF wSndReqMusic    EQU $DF0E  ; write a SndTable id here to start it in the music set
DEF wSndChanOfs     EQU $C005  ; offset ($00-$70) of the track being updated
DEF wSndSetFlag     EQU $C006  ; 0 while updating SFX set, 1 while updating music set
DEF wSndNR51        EQU $C400  ; shadow copy of the last NR51 value written by $8A

SECTION "Lenar Sound Data", ROMX[$402C], BANK[3]

; ---- music / SFX data ---------------------------------------------------------

SndUnused_402C:  ; not referenced by SndTable
    snd_endsong

Snd10_Ch3:
Snd10_Ch4:
Snd11_Ch3:
Snd11_Ch4:
Snd12_Ch1:
Snd12_Ch3:
Snd12_Ch4:
Snd13_Ch2:
Snd13_Ch3:
Snd13_Ch4:
Snd14_Ch3:
Snd14_Ch4:
Snd15_Ch1:
Snd15_Ch2:
Snd15_Ch3:
Snd16_Ch1:
Snd16_Ch2:
Snd16_Ch3:
Snd17_Ch1:
Snd17_Ch2:
Snd17_Ch3:
Snd18_Ch3:
Snd18_Ch4:
Snd19_Ch1:
Snd19_Ch2:
Snd19_Ch3:
    snd_end

Snd00_Ch1:
Snd01_Ch1:
    snd_sweep $00

Snd00_Ch2:
Snd01_Ch2:
    snd_len 1
    snd_duty $00
    snd_env $00
    db $53
    snd_endsong

Snd00_Ch3:
Snd01_Ch3:
    snd_len 1
    snd_env $00
    snd_pan $00
    db C_3
    snd_endsong

Snd00_Ch4:
Snd01_Ch4:
    snd_len 1
    snd_duty $00
    snd_env $00
    db $0C
    snd_end

SndUnused_4045:  ; not referenced by SndTable
    snd_transpose $00
    snd_duty $20
    snd_env $81
    snd_len 32
    db $00, $01, $02, $03, $04, $05, $06, $07, $78, $69, $6A, $6B, $6C, $6D, $6E, $6F
    db $5E, $5F
    snd_endsong

SndUnused_405F:  ; not referenced by SndTable
    snd_pan $33
    snd_transpose $00
    snd_duty $40
    snd_env $C3
    snd_len 9
    db $24
    snd_hold
    snd_hold
    snd_endsong

SndUnused_406C:  ; not referenced by SndTable
    snd_transpose $00
    snd_duty $40
    snd_env $C3
    snd_len 9
    db $18
    snd_hold
    snd_hold
    snd_endsong

SndUnused_4077:  ; not referenced by SndTable
    snd_pan $33
    snd_transpose $00
    snd_duty $40
    snd_env $F4
    snd_len 12
    db $30
    snd_hold
    snd_hold
    snd_hold
    snd_endsong

SndUnused_4085:  ; not referenced by SndTable
    snd_transpose $00
    snd_duty $40
    snd_env $F4
    snd_len 12
    db $24
    snd_hold
    snd_hold
    snd_hold
    snd_endsong

SndUnused_4091:  ; not referenced by SndTable
    snd_transpose $00
    snd_duty $40
    snd_env $C3
    snd_len 2
    db $0F, $1B, $10, $1C, $11, $1D, $12, $1E, $13, $1F, $14, $20, $15, $21, $16, $22
    db $17, $23, $18, $24, $19, $25, $1A, $26
    snd_endsong

SndUnused_40B1:  ; not referenced by SndTable
    snd_transpose $00
    snd_duty $40
    snd_env $C3
    snd_len 2
    db $0C, $18, $0D, $19, $0E, $1A, $0F, $1B, $10, $1C, $11, $1D, $12, $1E, $13, $1F
    db $14, $20, $15, $21, $16, $22, $17, $23
    snd_endsong

SndUnused_40D1:  ; not referenced by SndTable
    snd_transpose $00
    snd_duty $40
    snd_env $C3
    snd_len 2
    db $21, $21, $1F, $1E, $1F
    snd_len 16
    db $21
    snd_hold
    snd_endsong

SndUnused_40E1:  ; not referenced by SndTable
    snd_transpose $00
    snd_duty $40
    snd_env $C3
    snd_len 2
    db $1A, $1A, $1A, $1A, $1A
    snd_len 16
    db $1A
    snd_hold
    snd_endsong

Snd10_Ch1:
Snd10_Ch2:
    snd_transpose $00
    snd_duty $7C
    snd_env $E1
    snd_len 2
    db G_5
    snd_hold
    snd_endsong

Snd11_Ch1:
Snd11_Ch2:
    snd_transpose $00
    snd_duty $7C
    snd_env $E1
    snd_len 2
    db E_5
    snd_hold
    snd_endsong

Snd12_Ch2:
    snd_transpose $00
    snd_duty $3E
    snd_env $C1
    snd_len 2
    db C_5
    snd_hold
    snd_endsong

Snd19_Ch4:
    snd_transpose $00
    snd_duty $3C
    snd_env $F1
    snd_len 2
    db $6A, $6C, $6E, $6F
    snd_endsong

Snd15_Ch4:
    snd_transpose $00
    snd_duty $3C
    snd_env $F2
    snd_len 2
    db $6F
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_endsong

Snd16_Ch4:
    snd_transpose $00
    snd_duty $3C
    snd_env $F2
    snd_len 4
    db $00, $01, $02, $03, $04, $05, $06
    snd_endsong

Snd17_Ch4:
    snd_transpose $00
    snd_duty $3C
    snd_env $F1
    snd_len 2
    db $02, $02, $02
    snd_hold
    snd_hold
    snd_endsong

SndUnused_4144:  ; not referenced by SndTable
    snd_transpose $00
    snd_duty $40
    snd_env $C1
    snd_len 4
    db $39, $39
    snd_len 16
    db $39
    snd_hold
    snd_endsong

SndUnused_4151:  ; not referenced by SndTable
    snd_transpose $00
    snd_duty $40
    snd_env $C1
    snd_len 4
    db $36, $36
    snd_len 16
    db $36
    snd_hold
    snd_endsong

SndUnused_415E:  ; not referenced by SndTable
    snd_transpose $00
    snd_duty $40
    snd_env $F1
    snd_len 4
    db $0C, $10
    snd_len 16
    db $13
    snd_hold
    snd_endsong

Snd13_Ch1:
    snd_transpose $00
    snd_duty $40
    snd_env $C3
    snd_len 2
    db Fs5, Fs4, Fs3, Fs2, F_5, F_4, F_3, F_2, E_5, E_4, E_3, E_2, Ds5, Ds4, Ds3, Ds2
    snd_len 16
    snd_hold
    snd_hold
    snd_endsong

Snd14_Ch1:
    snd_transpose $00
    snd_duty $40
    snd_env $C3
    snd_len 4
    db Cs3, F_3, Cs4, F_4, E_4, Gs4, F_3, G_3
    snd_len 16
    snd_hold
    snd_hold
    snd_endsong

Snd14_Ch2:
    snd_transpose $00
    snd_duty $40
    snd_env $C3
    snd_len 4
    db C_4, E_4, Ds4, G_4, E_3, A_3, F_4, A_4
    snd_len 16
    snd_hold
    snd_hold
    snd_endsong

Snd18_Ch1:
    snd_transpose $00
    snd_duty $40
    snd_env $C3
    snd_len 4
    db D_5, Ds5, E_5, F_5
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_endsong

Snd18_Ch2:
    snd_transpose $00
    snd_duty $40
    snd_env $C3
    snd_len 4
    db F_4, Fs4, G_4, Gs4
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_endsong

Snd02_Ch1:
    snd_transpose $00
    snd_duty $40
    snd_env $C2
    snd_pan $BD
    snd_len 10
    db Fs4
    snd_hold
    snd_hold
    db B_4
    snd_hold
    snd_hold
    db Fs4
    snd_hold
    snd_len 20
    snd_pan $DB
    db F_4, E_4, F_4, Cs4
    snd_pan $BD
    db E_4, E_5, D_5, Cs5
    snd_len 10
    snd_pan $DB
    db D_5
    snd_hold
    db Cs5, B_4
    snd_hold
    db Cs5, D_5
    snd_hold
    snd_pan $BD
    snd_len 10
    db Fs5
    snd_hold
    snd_hold
    db D_5
    snd_hold
    snd_hold
    db B_4
    snd_hold
    snd_pan $DB
    snd_len 20
    db Cs5, D_5, E_5, Cs5
    snd_pan $BD
    snd_len 10
    db E_5, D_5, E_5, Fs5, G_5, Fs5, E_5, D_5
    snd_pan $DB
    db Cs5
    snd_hold
    db B_4, Cs5
    snd_hold
    db D_5, Fs5
    snd_hold
    snd_len 80
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_jump Snd02_Ch1

Snd02_Ch2:
    snd_transpose $00
    snd_duty $20
    snd_env $C1
    snd_len 10
    db D_4, Fs4, D_4, Fs4, D_4, Fs4, D_4, Fs4, Cs4, F_4, Cs4, F_4, Cs4, F_4, Cs4, F_4
    db C_4, E_4, C_4, E_4, C_4, E_4, C_4, E_4, B_3, D_4, B_3, D_4, B_3, D_4, B_3, D_4
    snd_jump Snd02_Ch2

Snd02_Ch3:
    snd_transpose $00
    snd_wave $10
    snd_duty $E0
    snd_env $20
    snd_len 20
    db Fs5
    snd_hold
    snd_hold
    db Fs5, F_5
    snd_hold
    snd_hold
    db Cs5, E_5
    snd_hold
    snd_hold
    db E_5
    snd_len 40
    db D_5
    snd_hold
    snd_jump Snd02_Ch3

Snd02_Ch4:
    snd_transpose $00
    snd_duty $20
    snd_env $81
    snd_len 10
    db $01, $01, $04, $01, $01, $01, $04, $01, $01, $01, $04, $01, $01, $01, $04, $01
    snd_jump Snd02_Ch4

Snd03_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $40
    snd_env $C2
    snd_pan $BD
    snd_len 8
    db Cs3, Cs3, Cs3, Cs3, Cs3, Cs3, Cs3, Cs3, E_3, E_3, E_3, E_3, E_3, E_3, E_3, E_3
    db Ds3, Ds3, Ds3, Ds3, Fs3, Fs3, Fs3, Fs3, A_3, Gs3, Fs3, E_3, Ds3, Cs3, C_3, Gs2
    snd_len 16
    db Cs4, Cs4, C_4, Gs3, Cs4, Cs4, Ds4, Ds4, E_4, E_4, Ds4, Ds4, E_4, E_4, Gs4, Gs4
    snd_jump Snd03_Ch1

Snd03_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $20
    snd_env $C1
    snd_len 8
    db Cs4, E_4, Gs4, E_4, Cs4, E_4, Gs4, E_4, Cs4, E_4, Gs4, E_4, Cs4, E_4, Gs4, E_4
    db Fs4, A_4, Cs5, A_4, Fs4, A_4, Cs5, A_4, Fs4, E_4, Ds4, C_4, Ds4, Cs4, C_4, Gs3
    db Gs4, G_4, Gs4, A_4, As4, C_5, Cs5, Ds5, E_5, Ds5, E_5, Ds5, Cs5, C_5, A_4, Gs4
    db Gs4, G_4, Gs4, A_4, C_5, Cs5, Ds5, E_5, Gs5, G_5, Gs5, G_5, Gs5, Gs5, Gs5, Gs5
    snd_jump Snd03_Ch2

Snd03_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_wave $10
    snd_duty $E0
    snd_env $20
    snd_len 16
    db Cs4, E_4, Cs4, E_4, Cs4, E_4, Cs4, E_4, Ds4, Fs4, Ds4, Fs4, Ds4, D_4, Cs4, C_4
    snd_len 8
    db Cs4, E_4, Gs4, E_4, Cs4, E_4, Gs4, E_4, Ds4, Fs4, A_4, Fs4, Ds4, Fs4, A_4, Fs4
    db C_4, Ds4, Fs4, Ds4, C_4, Ds4, Fs4, Ds4, Cs4, E_4, Gs4, E_4, Cs4, E_4, Gs4, E_4
    snd_jump Snd03_Ch3

Snd03_Ch4:
    snd_transpose $00
    snd_duty $20
    snd_env $81
    snd_len 8
    db $00, $00, $03, $00, $00, $00, $03, $00, $00, $00, $03, $00, $00, $00, $03, $00
    db $00, $00, $03, $00, $00, $00, $03, $00, $00, $00, $03, $00, $04, $04, $04, $04
    snd_jump Snd03_Ch4

Snd04_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $40
    snd_env $C2
    snd_pan $BD
    snd_len 32
    db E_4, E_4
    snd_len 16
    db Fs4
    snd_hold
    db A_3, D_4
    snd_len 32
    db G_4, G_4
    snd_len 16
    db Fs4, E_4, Fs4, D_4
    snd_len 32
    db G_4, G_4, C_5, G_4, Fs4
    snd_hold
    snd_hold
    snd_hold
    snd_call SndSub_439B
    snd_call SndSub_439B
    snd_jump Snd04_Ch1

SndSub_439B:
    snd_transpose $03 ; notes below sound 3 semitone(s) lower
    snd_len 16
    db Cs3, Ds3, F_3, Gs3, Cs3, Ds3, F_3, Cs3, Cs3, Ds3, F_3, Gs3, Cs3, Ds3, F_3, Cs3
    snd_len 8
    db C_3, C_3, C_3, C_3, C_3, C_3, C_3, C_3, C_3, C_3, C_3, C_3, C_3, C_3, C_3, C_3
    db C_3, C_3, C_3, C_3, C_3, C_3, C_3, C_3, C_3, C_3, C_3, C_3, C_3, C_3, C_3, C_3
    snd_ret

Snd04_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $20
    snd_env $C1
    snd_len 16
    db E_3, C_3, E_3, C_3, Fs3, D_3, Fs3, D_3
    snd_len 8
    db E_4, G_4, C_5, G_4, E_4, G_4, C_5, G_4
    snd_len 16
    db D_5, A_4, D_5, A_4
    snd_len 8
    db E_3, E_3, E_3, E_3, E_3, E_3, E_3, E_3, G_3, G_3, G_3, G_3, C_4, C_4, C_4, C_4
    db A_3, A_3, G_3, G_3, Fs3, Fs3, D_3, D_3, Fs3, Fs3, A_3, A_3, D_4, D_4, Fs4, Fs4
    snd_call SndSub_4417
    snd_call SndSub_4417
    snd_jump Snd04_Ch2

SndSub_4417:
    snd_transpose $03 ; notes below sound 3 semitone(s) lower
    snd_len 32
    db F_4, F_4, G_4, Gs4, Gs4, Gs4, G_4, F_4
    snd_len 16
    db G_4, Ds4, C_4, Ds4
    snd_len 32
    snd_hold
    snd_hold
    snd_len 8
    db G_5, Ds5, C_5
    snd_hold
    db G_4, Ds4, C_4
    snd_hold
    db G_3, Ds3, C_3
    snd_hold
    db C_4, Ds4, G_4, C_5
    snd_ret

Snd04_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_wave $10
    snd_duty $E4
    snd_env $20
    snd_len 8
    db C_4, E_4, G_4, E_4, C_4, E_4, G_4, E_4, D_4, Fs4, A_4, Fs4, D_4, Fs4, A_4, Fs4
    db C_4, E_4, G_4, E_4, C_4, E_4, G_4, E_4, D_4, Fs4, A_4, Fs4, D_4, Fs4, A_4, Fs4
    db C_4, E_4, G_4, E_4, C_4, E_4, G_4, E_4, C_4, E_4, G_4, E_4, C_4, E_4, G_4, E_4
    db D_4, Fs4, A_4, Fs4, D_4, Fs4, A_4, Fs4, D_4, Fs4, A_4, Fs4, D_4, Fs4, A_4, Fs4
    snd_call SndSub_448E
    snd_call SndSub_448E
    snd_jump Snd04_Ch3

SndSub_448E:
    snd_transpose $03 ; notes below sound 3 semitone(s) lower
    db Cs4, F_4, Gs4, F_4, Cs4, F_4, Gs4, F_4, Cs4, F_4, Gs4, F_4, Cs4, F_4, Gs4, F_4
    db Cs4, F_4, Gs4, F_4, Cs4, F_4, Gs4, F_4, Ds4, F_4, Gs4, F_4, Ds4, F_4, Gs4, F_4
    db C_4, Ds4, G_4, Ds4, C_4, Ds4, G_4, Ds4, C_4, Ds4, G_4, Ds4, C_4, Ds4, G_4, Ds4
    db G_5, C_5, G_5, C_5, G_5, C_5, G_5, C_5, G_4, C_4, G_4, C_4, G_4, C_4, G_4, C_4
    snd_ret

Snd04_Ch4:
    snd_transpose $00
    snd_duty $20
    snd_env $81
    snd_len 8
    db $01, $01, $03, $01, $01, $01, $03, $01, $01, $01, $03, $01, $03, $03, $03, $03
    snd_jump Snd04_Ch4

Snd05_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $20
    snd_env $C1
    snd_pan $BD
    snd_len 24
    snd_hold
    db Cs5
    snd_hold
    db Cs5
    snd_len 12
    snd_hold
    snd_hold
    db B_4
    snd_hold
    db B_4, As4, B_4, Gs4
    snd_len 24
    snd_hold
    db Cs5
    snd_hold
    db Cs5
    snd_len 12
    snd_hold
    snd_hold
    db B_4
    snd_hold
    db B_4, As4, B_4, Gs4
    snd_len 24
    snd_hold
    db Cs5
    snd_hold
    db Cs5
    snd_len 12
    snd_hold
    snd_hold
    db B_4
    snd_hold
    db B_4, As4, B_4, Gs4
    snd_jump Snd05_Ch1

Snd05_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $20
    snd_env $C1
    snd_len 12
    db A_3, E_4, A_4, E_4, Cs4, E_4, A_4, E_4, B_3, E_4, Gs4, E_4, Gs4, E_4, Gs4, E_4
    db A_3, E_4, A_4, E_4, Cs4, E_4, A_4, E_4, B_3, E_4, Gs4, E_4, Gs3, E_4, Gs4, E_4
    db A_3, E_4, A_4, E_4, Cs4, E_4, A_4, E_4, B_3, E_4, Gs4, E_4, B_3, E_4, Gs4, E_4
    snd_jump Snd05_Ch2

Snd05_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_wave $10
    snd_duty $E0
    snd_env $20
    snd_len 48
    db A_3, A_3, B_3, B_3
    snd_len 12
    db Cs6
    snd_hold
    snd_hold
    snd_hold
    db Cs7, B_6, A_6, Gs6
    snd_hold
    db Fs6
    snd_hold
    db F_6
    snd_hold
    db E_6
    snd_hold
    db Ds6, Cs6, Cs6, Cs7, Cs6, A_6, Cs6, E_6, Cs6
    snd_len 48
    db B_6, Gs6
    snd_jump Snd05_Ch3

Snd05_Ch4:
    snd_transpose $00
    snd_duty $20
    snd_env $81
    snd_len 24
    db $02, $05, $02, $05, $02, $05, $02, $05
    snd_jump Snd05_Ch4

Snd06_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $20
    snd_env $C1
    snd_pan $BD
    snd_call SndSub_45B5
    snd_call SndSub_45B5
    snd_call SndSub_45CF
    snd_call SndSub_45CF
    snd_call SndSub_4601
    snd_call SndSub_4601
    snd_jump Snd06_Ch1

SndSub_45B5:
    snd_len 10
    db G_5, Fs5, F_5, E_5, Ds5, F_5, Fs5, G_5
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db Gs5, G_5, F_5, E_5, Ds5, F_5, G_5, Gs5
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_ret

SndSub_45CF:
    snd_len 5
    db G_4, F_4, Ds4, G_4, F_4, Ds4, G_4, F_4, Ds4, G_4, F_4, Ds4, G_4, F_4, Ds4, G_4
    db F_4, Ds4, G_4, F_4, Ds4, G_4, F_4, Ds4, Gs4, F_4, Ds4, Gs4, F_4, Ds4, Gs4, F_4
    db Ds4, Gs4, F_4, Ds4, Gs4, F_4, Ds4, Gs4, F_4, Ds4, Gs4, F_4, Ds4, Gs4, F_4, Ds4
    snd_ret

SndSub_4601:
    snd_len 10
    db G_4, C_5, G_5, C_6, G_4, C_5, G_5, C_6, G_4, C_5, G_5, C_6, Gs4, Cs5, Gs5, Cs6
    db Gs4, Cs5, Gs5, Cs6, Gs4, Cs5, Gs5, Cs6
    snd_ret

Snd06_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $20
    snd_env $C1
    snd_len 10
    db C_3, D_3, C_4, D_4, C_5, D_5, C_3, D_3, C_4, D_4, C_5, D_5, Cs3, Ds3, Cs4, Ds4
    db Cs5, Ds5, Cs3, Ds3, Cs4, Ds4, Cs5, Ds5
    snd_jump Snd06_Ch2

Snd06_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_wave $10
    snd_duty $E0
    snd_env $20
    snd_len 10
    db C_4, D_4, C_4, D_4, C_4, D_4, C_4, D_4, C_4, D_4, C_4, D_4, Cs4, Ds4, Cs4, Ds4
    db Cs4, Ds4, Cs4, Ds4, Cs4, Ds4, Cs4, Ds4
    snd_jump Snd06_Ch3

Snd06_Ch4:
    snd_transpose $00
    snd_duty $20
    snd_env $81
    snd_len 10
    db $00, $00, $03, $00, $00, $00, $03, $00
    snd_jump Snd06_Ch4

Snd07_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $20
    snd_env $C3
    snd_pan $ED
    snd_len 24
    db D_5, Ds5, E_5
    snd_hold
    db Ds5, D_5, Ds5, As4
    snd_len 48
    db Cs5
    snd_hold
    snd_len 24
    snd_hold
    snd_hold
    db E_4, Ds4, Cs4
    snd_hold
    db Ds4, Ds3
    snd_len 48
    db Gs3
    snd_hold
    snd_hold
    snd_hold
    snd_jump Snd07_Ch1

Snd07_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $20
    snd_env $C3
    snd_len 24
    db D_4, Ds4, E_4
    snd_hold
    db Ds4, D_4, Ds4, As3
    snd_len 48
    db Cs4
    snd_hold
    snd_len 24
    snd_hold
    snd_hold
    db E_3, Ds3, Cs3
    snd_hold
    db Ds3, Ds3
    snd_len 48
    db Gs2
    snd_hold
    snd_hold
    snd_hold
    snd_jump Snd07_Ch2

Snd07_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_wave $10
    snd_duty $E0
    snd_env $40
    snd_len 6
    db Gs5, Ds6, Gs6, Ds7, Gs5, Ds6, Gs6, Ds7, Gs5, Ds6, Gs6, Ds7, Gs5, Ds6, Gs6, Ds7
    db Gs5, Ds6, Gs6, Ds7, Gs5, Ds6, Gs6, Ds7, Gs5, Ds6, Gs6, Ds7, Gs5, Ds6, Gs6, Ds7
    db Gs5, Ds6, Gs6, Ds7, As5, E_6, As6, Cs7, As5, E_6, As6, Cs7, As5, E_6, As6, Cs7
    db As5, E_6, As6, Cs7, As5, E_6, As6, Cs7, Cs6, E_6, Gs6, E_7, Cs6, E_6, Gs6, E_7
    db Cs6, E_6, Gs6, E_7, Cs6, E_6, Gs6, E_7, Cs6, E_6, Gs6, E_7, Cs6, E_6, Gs6, E_7
    db Gs5, Ds6, Gs6, Ds7, Gs5, Ds6, Gs6, Ds7, Gs5, Ds6, Gs6, Ds7, Gs5, Ds6, Gs6, Ds7
    db Gs5, Ds6, Gs6, Ds7, Gs5, Ds6, Gs6, Ds7, Gs5, Ds6, Gs6, Ds7, Gs5, Ds6, Gs6, Ds7
    snd_jump Snd07_Ch3

Snd07_Ch4:
    snd_end

Snd08_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $20
    snd_env $C1

SndLoop_473E:
    snd_pan $BD
    snd_call SndSub_4767
    snd_pan $BD
    snd_call SndSub_4767
    snd_pan $BD
    snd_len 16
    db G_4, G_4, Gs4
    snd_hold
    db G_4, G_4, F_4
    snd_hold
    snd_len 8
    db G_4, G_4, G_4, G_4, Gs4
    snd_hold
    snd_hold
    snd_hold
    db G_4, G_4, G_4, G_4, F_4, G_5, F_5, Ds5
    snd_jump SndLoop_473E

SndSub_4767:
    snd_len 4
    db G_4, Fs4, F_4, E_4, Ds4
    snd_hold
    snd_hold
    snd_hold
    db G_5
    snd_hold
    snd_hold
    snd_hold
    db Ds5
    snd_hold
    snd_hold
    snd_hold
    snd_len 8
    db C_5
    snd_hold
    db G_5, Ds5
    snd_hold
    db G_5, Ds5
    snd_hold
    snd_len 4
    db C_5, B_4, As4, A_4, Gs4
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_len 32
    snd_hold
    snd_hold
    snd_ret

Snd08_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $20
    snd_env $C1
    snd_len 16

SndLoop_479D:
    snd_call SndSub_47B6
    snd_call SndSub_47B6
    db C_4, C_4, C_4, C_4, C_4, C_4, C_4, C_4, C_4, C_4, C_4, C_4, C_4, C_4, C_4, C_4
    snd_jump SndLoop_479D

SndSub_47B6:
    db C_4, C_4, C_4, C_4, C_4, C_4, C_4, C_4, Gs4, Gs4, Gs4, Gs4, Gs4, Gs4, Gs4, Gs4
    snd_ret

Snd08_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_wave $10
    snd_duty $E0
    snd_env $20
    snd_len 8

SndLoop_47D0:
    snd_call SndSub_47F9
    snd_call SndSub_47F9
    db C_4, Ds4, G_4, Ds4, C_4, Ds4, G_4, Ds4, C_4, Ds4, G_4, Ds4, C_4, Ds4, G_4, Ds4
    db C_4, Ds4, G_4, Ds4, C_4, Ds4, G_4, Ds4, C_4, Ds4, G_4, Ds4, C_4, Ds4, G_4, Ds4
    snd_jump SndLoop_47D0

SndSub_47F9:
    db C_4, Ds4, G_4, Ds4, C_4, Ds4, G_4, Ds4, C_4, Ds4, G_4, Ds4, C_4, Ds4, G_4, Ds4
    db F_4, Gs4, C_5, Gs4, F_4, Gs4, C_5, Gs4, F_4, Gs4, C_5, Gs4, F_4, Gs4, C_5, Gs4
    snd_ret

Snd08_Ch4:
    snd_transpose $00
    snd_duty $20
    snd_env $81
    snd_len 8
    db $00, $00, $02, $00, $00, $00, $02, $00, $00, $00, $02, $00, $02, $02, $02, $02
    snd_jump Snd08_Ch4

Snd09_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $20
    snd_env $C1
    snd_pan $EB
    snd_len 6
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db C_5, B_4, As4, A_4, Gs4, G_4, Fs4, F_4, D_4, Ds4, E_4, F_4, Fs4, G_4, Gs4, A_4
    db As4, A_4, Gs4, G_4, F_4, E_4, Ds4, D_4, Cs4, C_4, A_3, G_3, F_3, Ds3, D_3, Ds3
    db D_3, Ds3, D_3, Ds3, E_3, F_3, Fs3, G_3, Gs3, A_3, As3, A_3, Gs3, G_3, Fs3, F_3
    db E_3, F_3, Fs3, G_3, Gs3, A_3, As3, B_3, C_4, Cs4
    snd_jump Snd09_Ch1

Snd09_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $20
    snd_env $C3
    snd_len 12
    db G_4, F_4, G_4
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db G_4, Gs4, F_4
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db F_4, Ds4
    snd_hold
    db Ds4, Ds4, F_4, Ds4
    snd_hold
    snd_hold
    snd_len 48
    db G_4
    snd_hold
    snd_len 12
    db G_3, F_3, G_3
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db G_3, Gs3, F_3
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db F_3, Ds3
    snd_hold
    db Ds3, Ds3, F_3, Ds3
    snd_hold
    snd_hold
    snd_len 48
    db G_3
    snd_hold
    snd_jump Snd09_Ch2

Snd09_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_wave $10
    snd_duty $E0
    snd_env $20
    snd_len 12
    db G_4, G_4, G_4, G_4, G_4, G_4, G_4, G_4, F_4, F_4, F_4, F_4, F_4, F_4, F_4, F_4
    db Ds4, Ds4, Ds4, Ds4, Ds4, Ds4, Ds4, Ds4, D_4, D_4, D_4, D_4, D_4, D_4, D_4, D_4
    snd_jump Snd09_Ch3

Snd09_Ch4:
Snd0A_Ch4:
    snd_end

Snd0A_Ch1:
    snd_transpose $00
    snd_duty $20
    snd_env $C3
    snd_pan $FF
    snd_len 12
    db C_3
    snd_hold
    db G_3
    snd_hold
    db G_3
    snd_hold
    db D_3, Ds3, F_3
    snd_hold
    db Gs3
    snd_hold
    db G_3, F_3, Ds3, D_3, G_3, F_3, Ds3, D_3, G_3
    snd_hold
    db D_3
    snd_hold
    snd_len 24
    db D_3, D_3, C_4, G_4, G_4, D_4, As4, Gs4
    snd_len 12
    db G_4
    snd_hold
    snd_hold
    db Ds4, F_4
    snd_hold
    db G_4
    snd_hold
    snd_len 24
    db G_4, G_4
    snd_jump Snd0A_Ch1

Snd0A_Ch2:
    snd_transpose $00
    snd_duty $20
    snd_env $C3

SndLoop_492D:
    snd_len 12
    db C_4, D_4, Ds4
    snd_hold
    db G_4
    snd_hold
    db F_4, Ds4, D_4, Ds4, F_4
    snd_hold
    db D_4
    snd_hold
    db Ds4
    snd_hold
    snd_len 6
    db C_4
    snd_hold
    snd_hold
    snd_hold
    db G_4
    snd_hold
    snd_hold
    snd_hold
    db Ds4
    snd_hold
    snd_hold
    snd_hold
    db D_4, Ds4, D_4, Ds4, D_4, Ds4, D_4, Ds4, D_4
    snd_hold
    snd_hold
    snd_hold
    db C_4
    snd_hold
    db D_4
    snd_hold
    db Ds4
    snd_hold
    snd_hold
    snd_hold
    snd_len 12
    db G_3
    snd_hold
    db F_4, Ds4, D_4, Ds4, F_4
    snd_hold
    snd_len 24
    db D_4, Ds4, C_4, B_3, D_4, C_4
    snd_jump SndLoop_492D

Snd0A_Ch3:
    snd_end

Snd0B_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $20
    snd_env $C2
    snd_pan $FF
    snd_len 12
    db A_3
    snd_hold
    snd_hold
    snd_hold
    db A_3
    snd_hold
    snd_hold
    db C_3
    snd_hold
    db F_3
    snd_hold
    db A_3
    snd_hold
    db F_3
    snd_hold
    snd_hold
    snd_len 24
    db G_3
    snd_hold
    db D_3, G_3
    snd_hold
    db D_3, G_3, D_3
    snd_jump Snd0B_Ch1

Snd0B_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $20
    snd_env $C2
    snd_len 12
    db C_4, F_4, A_4, F_4, A_4, F_4, A_4, F_4, C_4, F_4, A_4, F_4, A_4, F_4, A_4, F_4
    db As3, D_4, G_4, D_4, G_4, D_4, G_4, D_4, As3, D_4, G_4, As4, D_5, As4, G_4, E_4
    snd_jump Snd0B_Ch2

Snd0B_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_wave $10
    snd_duty $E0
    snd_env $40
    snd_len 12
    db A_6, A_6
    snd_hold
    db A_6, A_6, A_6
    snd_hold
    db A_6, A_6, A_6
    snd_hold
    db A_6, A_6, A_6
    snd_hold
    db A_6, G_6, G_6
    snd_hold
    db G_6, G_6, G_6
    snd_hold
    db G_6, G_6, G_6
    snd_hold
    db G_6, G_6, G_6
    snd_hold
    db G_6
    snd_jump Snd0B_Ch3

Snd0B_Ch4:
    snd_transpose $00
    snd_duty $20
    snd_env $81
    snd_len 12
    db $00
    snd_hold
    db $03
    snd_hold
    db $00, $00, $03
    snd_hold
    db $00, $00, $03
    snd_hold
    db $00, $00, $03
    snd_hold
    snd_jump Snd0B_Ch4

Snd0C_Ch1:
    snd_endsong

Snd0C_Ch2:
    snd_endsong

Snd0C_Ch3:
    snd_endsong

SndSub_4A0B:
    snd_len 6
    db C_4
    snd_hold
    snd_hold
    db C_4
    snd_hold
    snd_hold
    db C_4
    snd_hold
    snd_hold
    db C_4
    snd_hold
    snd_hold
    db C_4
    snd_hold
    snd_hold
    db C_4
    snd_hold
    snd_hold
    db C_4
    snd_hold
    snd_hold
    db C_4
    snd_hold
    snd_hold
    db C_4
    snd_hold
    snd_hold
    db C_4
    snd_hold
    snd_hold
    db C_4
    snd_hold
    snd_hold
    db C_4
    snd_hold
    snd_hold
    db C_4
    snd_hold
    snd_hold
    db C_4
    snd_hold
    snd_hold
    db Cs4
    snd_hold
    snd_hold
    db Cs4
    snd_hold
    snd_hold
    db Cs4
    snd_hold
    snd_hold
    db Cs4
    snd_hold
    snd_hold
    db Cs4
    snd_hold
    snd_hold
    db Cs4
    snd_hold
    snd_hold
    db Cs4
    snd_hold
    snd_hold
    db Cs4
    snd_hold
    snd_hold
    db C_4
    snd_hold
    snd_hold
    db C_4
    snd_hold
    snd_hold
    db C_4
    snd_hold
    snd_hold
    db C_4
    snd_hold
    snd_hold
    db C_4
    snd_hold
    snd_hold
    db C_4
    snd_hold
    snd_hold
    db C_4
    snd_hold
    snd_hold
    db C_4
    snd_hold
    snd_hold
    snd_ret

SndSub_4A67:
    snd_len 6
    db E_4
    snd_hold
    snd_hold
    db D_4
    snd_hold
    snd_hold
    db E_4
    snd_hold
    snd_hold
    db F_4
    snd_hold
    snd_hold
    db G_4
    snd_hold
    snd_hold
    db F_4
    snd_hold
    snd_hold
    db G_4
    snd_hold
    snd_hold
    db Gs4
    snd_hold
    snd_hold
    db As4
    snd_hold
    snd_hold
    db Gs4
    snd_hold
    snd_hold
    db G_4
    snd_hold
    snd_hold
    db F_4
    snd_hold
    snd_hold
    db G_4
    snd_hold
    snd_hold
    db E_4
    snd_hold
    snd_hold
    db Gs4
    snd_hold
    snd_hold
    db C_5
    snd_hold
    snd_hold
    db As4
    snd_hold
    snd_hold
    db Gs4
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db Gs4
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db Cs5
    snd_len 12
    snd_hold
    db C_5
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_ret

Snd0D_Ch1:
    snd_transpose $08 ; notes below sound 8 semitone(s) lower
    snd_duty $20
    snd_env $C2
    snd_pan $ED
    snd_len 6
    db C_5
    snd_hold
    snd_hold
    db C_5
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db C_5
    snd_hold
    snd_hold
    db C_5
    snd_hold
    snd_hold
    db C_5
    snd_len 12
    snd_hold
    db C_5
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_len 6
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db Cs5
    snd_hold
    snd_hold
    db Cs5
    snd_hold
    snd_hold
    db Cs5
    snd_hold
    snd_hold
    db Cs5
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db Cs5
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db Cs5
    snd_len 12
    snd_hold
    db C_5
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_call SndSub_4A0B
    snd_jump Snd0D_Ch1

Snd0D_Ch2:
    snd_transpose $08 ; notes below sound 8 semitone(s) lower
    snd_duty $20
    snd_env $C2
    snd_len 6
    db E_4
    snd_hold
    snd_hold
    db F_4
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db E_4
    snd_hold
    snd_hold
    db D_4
    snd_hold
    snd_hold
    db E_4
    snd_len 12
    snd_hold
    db G_4
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_len 6
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db F_4
    snd_hold
    snd_hold
    db Gs4
    snd_hold
    snd_hold
    db G_4
    snd_hold
    snd_hold
    db F_4
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db F_4
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db G_4
    snd_len 12
    snd_hold
    db E_4
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_call SndSub_4A67
    snd_jump Snd0D_Ch2

Snd0D_Ch3:
    snd_transpose $08 ; notes below sound 8 semitone(s) lower
    snd_wave $10
    snd_duty $E0
    snd_env $40
    snd_len 6
    db G_5
    snd_hold
    snd_hold
    db G_5, G_5, G_5, G_5
    snd_hold
    snd_hold
    db G_5, G_5, G_5, G_5
    snd_hold
    snd_hold
    db G_5, G_5, G_5, G_5
    snd_hold
    snd_hold
    db G_5, G_5, G_5, G_5
    snd_hold
    snd_hold
    db G_5, G_5, G_5, G_5
    snd_hold
    snd_hold
    db G_5, G_5, G_5, G_5
    snd_hold
    snd_hold
    db G_5, G_5, G_5, Gs5
    snd_hold
    snd_hold
    db Gs5, Gs5, Gs5, Gs5
    snd_hold
    snd_hold
    db Gs5, Gs5, Gs5, Gs5
    snd_hold
    snd_hold
    db Gs5, Gs5, Gs5, Gs5
    snd_hold
    snd_hold
    db Gs5, Gs5, Gs5, G_5
    snd_hold
    snd_hold
    db G_5, G_5, G_5, G_5
    snd_hold
    snd_hold
    db G_5, G_5, G_5, G_5
    snd_hold
    snd_hold
    db G_5, G_5, G_5, G_5
    snd_hold
    snd_hold
    db G_5, G_5, G_5
    snd_jump Snd0D_Ch3

Snd0D_Ch4:
    snd_transpose $00
    snd_duty $20
    snd_env $71
    snd_len 6
    db $03
    snd_hold
    snd_hold
    db $03, $03, $03, $03
    snd_hold
    snd_hold
    db $03, $03, $03, $03
    snd_hold
    snd_hold
    db $03, $03, $03, $03
    snd_hold
    snd_hold
    db $03, $03, $03, $03
    snd_hold
    snd_hold
    db $03, $03, $03, $03
    snd_hold
    snd_hold
    db $03, $03, $03, $03
    snd_hold
    snd_hold
    db $03, $03, $03, $03
    snd_hold
    snd_hold
    db $03, $03, $03, $03
    snd_hold
    snd_hold
    db $03, $03, $03, $03
    snd_hold
    snd_hold
    db $03, $03, $03, $03
    snd_hold
    snd_hold
    db $03, $03, $03, $03
    snd_hold
    snd_hold
    db $03, $03, $03, $03
    snd_hold
    snd_hold
    db $6A
    snd_hold
    snd_hold
    db $03
    snd_hold
    snd_hold
    db $6A
    snd_hold
    snd_hold
    db $6A, $6A, $6A, $6A
    snd_hold
    snd_hold
    snd_jump Snd0D_Ch4

Snd0E_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $40
    snd_env $C2
    snd_pan $ED
    snd_len 12
    db C_4, C_4, G_4
    snd_hold
    db Ds4
    snd_hold
    db F_4, Ds4
    snd_len 6
    db F_4
    snd_hold
    snd_hold
    snd_hold
    db D_4
    snd_hold
    snd_hold
    snd_hold
    db G_4, Gs4, G_4, F_4, G_4
    snd_hold
    db F_4
    snd_hold
    snd_len 12
    db Ds4, D_4, F_4, Ds4, F_4
    snd_hold
    db D_4
    snd_hold
    db C_4, C_4, G_4
    snd_hold
    db Ds4
    snd_hold
    db F_4, Ds4, F_4
    snd_hold
    db D_4
    snd_hold
    db G_4, Gs4, G_4, F_4, Ds4, D_4, C_4
    snd_hold
    db C_3, B_2, C_3, D_3
    snd_env $C3
    snd_duty $20
    db G_4
    snd_hold
    db G_4
    snd_hold
    db G_4
    snd_hold
    db F_4, E_4, F_4, G_4, A_4, C_5, G_4
    snd_hold
    db Fs4
    snd_hold
    db F_4
    snd_hold
    snd_hold
    db D_4, F_4, D_4, F_4, G_4, A_4, C_5, G_4
    snd_hold
    db G_4
    snd_hold
    db G_4
    snd_hold
    snd_len 24
    db E_4, Ds4, E_4
    snd_hold
    snd_len 48
    snd_hold
    snd_hold
    snd_jump Snd0E_Ch1

Snd0E_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $40
    snd_env $C2
    snd_len 12
    db G_4, G_4, C_5
    snd_hold
    db G_4
    snd_hold
    db Gs4, G_4, Gs4
    snd_hold
    db F_4
    snd_hold
    db G_4, F_4, Ds4, F_4, G_4
    snd_hold
    db F_4, Ds4, F_4
    snd_hold
    db D_4
    snd_hold
    db G_4, G_4, C_5
    snd_hold
    db G_4
    snd_hold
    db Gs4, G_4, Gs4
    snd_hold
    db F_4
    snd_hold
    db G_4, F_4, Ds4, F_4, G_4, F_4, Ds4, D_4, C_4
    snd_hold
    db C_4
    snd_hold
    db E_3, G_3, C_4, E_4, G_4, E_4, C_4, G_3, E_3, G_3, C_4, E_4, G_4, E_4, C_4, G_3
    db D_3, F_3, A_3, D_4, F_4, D_4, A_3, F_3, D_3, F_3, A_3, D_4, F_4, D_4, A_3, F_3
    db E_3, G_3, C_4, E_4, G_4, E_4, C_4, G_3, C_3, E_3, G_3, C_4, E_4, C_4, G_3, E_3
    snd_jump Snd0E_Ch2

Snd0E_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_wave $10
    snd_duty $E0
    snd_env $40
    snd_len 12
    db C_4, Ds4, G_4, Ds4, G_4, Ds4, F_4, Gs4, Ds5, Gs4, D_5, Gs4, Ds4
    snd_hold
    db G_4
    snd_hold
    db Ds5
    snd_hold
    db D_5, C_5, D_5
    snd_hold
    db G_4
    snd_hold
    db C_4, Ds4, G_4, Ds4, G_4, Ds4, F_4, Gs4, Ds5, Gs4, D_5, Gs4, Ds4
    snd_hold
    db G_4
    snd_hold
    snd_len 24
    db B_4, C_5
    snd_hold
    snd_hold
    snd_len 12
    db E_4, G_4, C_5, E_5, G_5, E_5, C_5, G_4, E_4, G_4, C_5, E_5, G_5, E_5, C_5, G_4
    db D_4, F_4, A_4, D_5, F_5, D_5, A_4, F_4, D_4, F_4, A_4, D_5, F_5, D_5, A_4, F_4
    db E_4, G_4, C_5, E_5, G_5, E_5, C_5, G_4, C_4, E_4, G_4, C_5, E_5, C_5, G_4, E_4
    snd_jump Snd0E_Ch3

Snd0F_Ch1:
    snd_transpose $06 ; notes below sound 6 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_pan $ED
    snd_len 12
    db G_4, F_4, Ds4
    snd_hold
    db C_5
    snd_hold
    db Ds5
    snd_hold
    db D_5, C_5, B_4, C_5, D_5
    snd_hold
    db B_4
    snd_hold
    db C_5, D_5, C_5, B_4, C_5, Gs4, B_4, G_4, F_4, G_4, F_4, G_4, Ds4
    snd_hold
    db D_4
    snd_hold
    snd_jump Snd0F_Ch1

Snd0F_Ch2:
    snd_transpose $06 ; notes below sound 6 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_len 12
    db C_4
    snd_hold
    db G_4, F_4, G_4
    snd_hold
    db Ds4
    snd_hold
    db D_4
    snd_hold
    db G_4, F_4, F_4
    snd_hold
    db D_4
    snd_hold
    db C_4, C_4, C_4, C_4, C_4, C_4, C_4, C_4
    snd_len 24
    db C_4, C_4, Gs3, G_3
    snd_jump Snd0F_Ch2

Snd0F_Ch3:
    snd_transpose $06 ; notes below sound 6 semitone(s) lower
    snd_wave $10
    snd_duty $E0
    snd_env $40
    snd_len 12
    db C_5, C_5, C_5, C_5, G_5, G_5, G_5, G_5, D_5, D_5, D_5, D_5, D_5, D_5, D_5, D_5
    db C_5, C_5, C_5, C_5, C_5, C_5, C_5, C_5, C_5, C_5, C_5, C_5, Gs4, Gs4, G_4, G_4
    snd_jump Snd0F_Ch3

Snd0F_Ch4:
    snd_transpose $00
    snd_duty $20
    snd_env $81
    snd_len 24
    db $02, $05, $02, $05, $02, $05, $02, $05, $02, $05, $02, $05
    snd_len 12
    db $02
    snd_hold
    db $05
    snd_hold
    db $02, $02, $05
    snd_hold
    snd_jump Snd0F_Ch4

Snd0C_Ch4:
Snd0E_Ch4:
    snd_end

Snd1D_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $20
    snd_env $C4
    snd_pan $ED
    snd_call SndSub_4E31
    snd_pan $DE
    snd_call SndSub_4E31
    snd_duty $00
    snd_pan $ED
    snd_call SndSub_4E31
    snd_pan $DE
    snd_call SndSub_4E31
    snd_jump Snd1D_Ch1

SndSub_4E31:
    snd_len 48
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_len 12
    db Fs4, D_4, Fs4, A_4, Gs4
    snd_hold
    snd_hold
    snd_hold
    db Gs4, A_4, Gs4
    snd_hold
    db E_4
    snd_hold
    snd_hold
    snd_hold
    snd_len 48
    db Fs4
    snd_hold
    snd_hold
    snd_hold
    snd_ret

Snd1D_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $20
    snd_env $C6
    snd_len 48
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db A_4
    snd_hold
    db Gs4
    snd_hold
    db Fs4
    snd_hold
    snd_hold
    snd_hold
    snd_jump Snd1D_Ch2

Snd1D_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_wave $10
    snd_duty $D0
    snd_env $20
    snd_len 12
    db B_3, Fs4, B_4, D_5, Fs5, D_5, B_4, Fs4, B_3, Fs4, B_4, D_5, Fs5, D_5, B_4, Fs4
    db B_3, Fs4, A_4, D_5, A_5, D_5, A_4, Fs4, B_3, Fs4, B_4, D_5, Gs5, D_5, B_4, Fs4
    db B_3, Fs4, B_4, D_5, Fs5, D_5, B_4, Fs4, B_3, Fs4, B_4, D_5, Fs5, D_5, B_4, Fs4
    snd_jump Snd1D_Ch3

Snd1E_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $20
    snd_env $C3
    snd_pan $ED
    snd_len 7
    db A_4
    snd_hold
    db A_4, E_5
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db G_5, Fs5, G_5, A_5
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_endsong

Snd1E_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $20
    snd_env $C3
    snd_len 1
    snd_hold
    snd_len 7
    db A_2
    snd_hold
    db A_2, E_3
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db G_3, Fs3, G_3, A_3
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_endsong

Snd1E_Ch4:
    snd_transpose $00
    snd_duty $20
    snd_env $81
    snd_len 7
    db $01, $01, $03, $01
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db $03, $03, $03, $03
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_endsong

Snd1F_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $80
    snd_env $C1
    snd_pan $ED
    snd_len 12
    snd_call SndSub_4F08
    snd_env $C3
    snd_pan $ED
    snd_call SndSub_4F08
    snd_env $A5
    snd_pan $DE
    snd_call SndSub_4F08
    snd_jump Snd1F_Ch1

SndSub_4F08:
    db A_3, A_3, A_3, A_3, A_3
    snd_hold
    db B_3, B_3, B_3, B_3, B_3
    snd_hold
    db C_4, C_4, C_4, C_4, C_4
    snd_hold
    db D_4, D_4, D_4, D_4, D_4
    snd_hold
    db C_3, C_3, C_3, C_3, C_3
    snd_hold
    db D_3, D_3, D_3, D_3, D_3
    snd_hold
    db C_3, C_3, C_3, C_3, C_3
    snd_hold
    db D_3, D_3, D_3, D_3, E_3
    snd_hold
    snd_ret

Snd1F_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $80
    snd_env $A3
    snd_len 12
    db A_3, E_4, A_4, C_5, E_5
    snd_hold
    db B_3, E_4, Gs4, B_4, E_5
    snd_hold
    db C_4, E_4, G_4, C_5, E_5
    snd_hold
    db D_4, F_4, Gs4, D_5, F_5
    snd_hold
    db C_4, E_4, A_4, C_5, E_5
    snd_hold
    db D_4, F_4, A_4, D_5, F_5
    snd_hold
    db C_4, E_4, A_4, C_5, E_5
    snd_hold
    db D_4, F_4, Gs4, B_4, E_5
    snd_hold
    snd_jump Snd1F_Ch2

Snd1F_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_wave $10
    snd_duty $D0
    snd_env $40
    snd_len 12
    db A_5
    snd_hold
    snd_hold
    db Gs5, A_5, B_5
    snd_hold
    db Gs5
    snd_hold
    db E_5
    snd_hold
    snd_hold
    db C_6
    snd_hold
    snd_hold
    db B_5, C_6, D_6
    snd_hold
    db B_5
    snd_hold
    db Gs5
    snd_hold
    snd_hold
    snd_len 24
    db E_6
    snd_hold
    db C_6, D_6
    snd_len 12
    snd_hold
    db C_6, B_5
    snd_hold
    db C_6
    snd_hold
    snd_hold
    snd_hold
    db A_5
    snd_hold
    db B_5
    snd_hold
    snd_hold
    db Gs5, E_5
    snd_hold
    snd_jump Snd1F_Ch3

Snd1D_Ch4:
Snd1E_Ch3:
Snd1F_Ch4:
    snd_end

Snd1B_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $20
    snd_env $C3
    snd_pan $ED
    snd_len 10
    db C_4
    snd_hold
    db G_4
    snd_hold
    db Ds4, F_4, G_4, Gs4
    snd_len 20
    snd_hold
    db Gs4
    snd_hold
    snd_hold
    snd_len 10
    db C_5, Ds5, D_5, G_5, As5
    snd_hold
    db Gs5, As4
    snd_hold
    db Gs4, As4, Gs4, As4
    snd_hold
    db Gs4
    snd_hold
    snd_jump Snd1B_Ch1

Snd1B_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $20
    snd_env $C5
    snd_len 10
    db G_3
    snd_hold
    snd_hold
    snd_hold
    db G_3
    snd_hold
    snd_hold
    db Gs3
    snd_len 20
    snd_hold
    db Gs3
    snd_hold
    snd_hold
    snd_len 10
    db G_3
    snd_hold
    snd_hold
    snd_hold
    db G_3
    snd_hold
    snd_hold
    db Gs3
    snd_len 20
    snd_hold
    db Gs3
    snd_hold
    snd_hold
    snd_jump Snd1B_Ch2

Snd1B_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_wave $10
    snd_duty $E0
    snd_env $40
    snd_len 10
    db C_4, Ds4, C_5, Ds5, C_4, Ds4, C_5, Ds5, Cs4, E_4, Cs5, E_5, Cs4, E_4, Cs5, E_5
    snd_jump Snd1B_Ch3

Snd1B_Ch4:
    snd_transpose $00
    snd_duty $20
    snd_env $81
    snd_len 20
    db $01, $05, $01, $05
    snd_len 10
    db $01
    snd_hold
    db $05
    snd_hold
    db $01, $01, $05, $01
    snd_len 20
    db $01, $05, $01, $05
    snd_len 10
    db $01
    snd_hold
    db $05
    snd_hold
    db $01, $01, $05, $01
    snd_jump Snd1B_Ch4

Snd1C_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $20
    snd_env $C1
    snd_pan $ED
    snd_len 6
    db C_4
    snd_hold
    db C_4, C_4
    snd_hold
    snd_hold
    db F_4, E_4, F_4, G_4
    snd_hold
    snd_hold
    db G_4
    snd_hold
    snd_hold
    db G_4
    snd_len 12
    snd_hold
    db C_5
    snd_hold
    snd_hold
    snd_endsong

Snd1C_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $20
    snd_env $C1
    snd_len 6
    db G_3
    snd_hold
    db G_3, G_3
    snd_hold
    snd_hold
    db F_3, G_3, A_3, C_4
    snd_hold
    snd_hold
    db E_4
    snd_hold
    snd_hold
    db E_4
    snd_len 12
    snd_hold
    db E_4
    snd_hold
    snd_hold
    snd_endsong

Snd1C_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_wave $10
    snd_duty $F0
    snd_env $60
    snd_len 6
    db E_4
    snd_hold
    db E_4, E_4
    snd_hold
    snd_hold
    db A_4
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db C_5
    snd_hold
    snd_hold
    db C_5
    snd_len 12
    snd_hold
    db C_5
    snd_hold
    snd_hold
    snd_endsong

Snd1C_Ch4:
    snd_transpose $00
    snd_duty $20
    snd_env $81
    snd_len 6
    db $03
    snd_hold
    db $03, $03
    snd_hold
    snd_hold
    db $03
    snd_hold
    db $03, $03
    snd_hold
    snd_hold
    db $04
    snd_hold
    snd_hold
    db $04
    snd_hold
    snd_hold
    db $04, $03, $03, $03
    snd_hold
    snd_hold
    snd_endsong

Snd1A_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $20
    snd_env $A6
    snd_pan $ED
    snd_len 24
    snd_hold
    db E_4
    snd_hold
    db E_4
    snd_hold
    db E_4
    snd_hold
    db E_4
    snd_hold
    db E_4
    snd_hold
    db E_4
    snd_len 12
    snd_hold
    snd_hold
    db E_4, E_4
    snd_hold
    snd_hold
    db E_4, E_4
    snd_len 48
    snd_hold
    snd_hold
    snd_len 12
    db G_5, E_5, B_4, G_4, E_4, B_3, E_4, G_3
    snd_len 48
    snd_hold
    snd_hold
    snd_len 12
    db G_5, E_5, G_5, B_5, C_6, D_6, E_6, G_6
    snd_hold
    snd_hold
    snd_hold
    db E_4
    snd_hold
    snd_hold
    snd_hold
    db E_4
    snd_hold
    snd_hold
    snd_hold
    db E_4
    snd_hold
    snd_hold
    snd_hold
    db E_4
    snd_hold
    snd_hold
    snd_hold
    db F_4
    snd_hold
    snd_hold
    snd_hold
    db F_4
    snd_hold
    snd_hold
    snd_hold
    db G_4
    snd_hold
    snd_hold
    snd_hold
    db G_4
    snd_hold
    snd_hold
    db E_4, E_4
    snd_hold
    snd_hold
    db E_4, E_4
    snd_hold
    snd_hold
    db E_4, E_4
    snd_hold
    snd_hold
    db E_4, E_4
    snd_hold
    snd_hold
    db F_4, F_4
    snd_hold
    snd_hold
    db F_4, F_4
    snd_len 24
    db G_4, G_4, F_4, D_4
    snd_jump Snd1A_Ch1

Snd1A_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $20
    snd_env $C2
    snd_len 12
    db C_3, G_3, C_4, G_3, C_3, G_3, C_4, G_3, F_3, A_3, C_4, A_3, F_3, A_3, C_4, A_3
    db C_3, E_3, G_3, B_3, C_3, E_3, G_3, B_3, B_2, E_3, Gs3, B_3, B_2, E_3, Gs3, B_3
    db D_3, F_3, A_3, D_4, D_3, F_3, A_3, D_4, E_3, G_3, B_3, E_4, E_3, G_3, B_3, E_4
    db D_3, F_3, A_3, D_4, D_3, F_3, A_3, D_4, E_3, G_3, B_3, E_4, E_3, G_3, B_3, E_4
    db C_3, E_3, G_3, C_4, C_3, E_3, G_3, C_4, A_2, C_3, E_3, A_3, A_2, C_3, E_3, A_3
    db F_2, A_2, C_3, F_3, F_2, A_2, C_3, F_3, G_2, D_3, G_3, B_3, G_2, D_3, G_3, B_3
    db C_4, E_4, G_4, C_5, B_3, E_4, G_4, C_5, A_3, E_4, A_4, E_5, A_3, E_4, A_4, E_5
    db D_3, F_3, D_4, F_4, F_3, A_3, D_4, F_4, G_3, Fs3, G_3, A_3, B_3, G_3, F_3, D_3
    snd_jump Snd1A_Ch2

Snd1A_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_wave $10
    snd_duty $D0
    snd_env $40
    snd_len 12
    db E_5, E_5, E_5, E_5, E_5, E_5, E_5, D_5, C_5, C_5, C_5, D_5, E_5, F_5, A_5, C_6
    db E_6, E_6, G_6, G_6, B_6, B_6, C_7, C_7
    snd_len 6
    db E_7
    snd_hold
    db D_7, C_7, B_6
    snd_hold
    db Gs6
    snd_hold
    db E_6
    snd_hold
    db D_6
    snd_hold
    db B_5
    snd_hold
    db Gs5
    snd_hold
    snd_len 12
    db A_4, A_4, A_4, B_4, C_5, F_5, E_5, D_5, E_5, E_5, E_5, E_5, E_5, E_5, E_5, E_5
    db A_4, A_4, A_4, B_4, C_5, F_5, E_5, D_5, E_5, E_5, E_5, E_5, G_5, G_5, B_5, B_5
    db E_6
    snd_hold
    db E_6
    snd_hold
    db E_6, F_6, E_6, E_6, E_6, E_6, D_6, C_6
    snd_hold
    db D_6, C_6, D_6, E_6, F_6, A_6, C_7, A_6
    snd_hold
    db F_6
    snd_hold
    db F_6, E_6, F_6, G_6, B_6, C_7, D_7, G_7
    snd_len 48
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_jump Snd1A_Ch3

Snd1A_Ch4:
    snd_end


SECTION "Lenar Sound Driver", ROMX[$7AE0], BANK[3]

; Pick which track drives hardware channel b (b = $00/$10/$20/$30).
; The SFX set ($DF00+b) has priority; if its length byte is 0 (idle) the
; music set ($DF40+b) is used. Returns h=$DF, b=offset of chosen track.
; Pops the caller (no register writes this frame) if: both tracks idle,
; the chosen track's frame counter is not 0 (no new row this frame),
; or the current row is $89 (hold: let the previous note ring on).
SndOut_SelectSource:
    ld l, b                           ; 7AE0: 68
    ld a, [hl+]                       ; 7AE1: 2A  length byte (0 = idle)
    cp $00                            ; 7AE2: FE 00
    jp z, SndOut_TryMusic             ; 7AE4: CA F8 7A
    ld a, [hl]                        ; 7AE7: 7E  frame counter
    cp $00                            ; 7AE8: FE 00
    jp nz, SndOut_Skip                ; 7AEA: C2 14 7B
    ld a, $0a                         ; 7AED: 3E 0A
    add b                             ; 7AEF: 80
    ld l, a                           ; 7AF0: 6F
    ld a, [hl]                        ; 7AF1: 7E  current note
    cp $89                            ; 7AF2: FE 89
    jp z, SndOut_Skip                 ; 7AF4: CA 14 7B
    ret                               ; 7AF7: C9
SndOut_TryMusic:
    ld a, b                           ; 7AF8: 78
    add $40                           ; 7AF9: C6 40  switch to music set
    ld b, a                           ; 7AFB: 47
    ld l, a                           ; 7AFC: 6F
    ld a, [hl+]                       ; 7AFD: 2A
    cp $00                            ; 7AFE: FE 00
    jp z, SndOut_Skip                 ; 7B00: CA 14 7B
    ld a, [hl]                        ; 7B03: 7E
    cp $00                            ; 7B04: FE 00
    jp nz, SndOut_Skip                ; 7B06: C2 14 7B
    ld a, $0a                         ; 7B09: 3E 0A
    add b                             ; 7B0B: 80
    ld l, a                           ; 7B0C: 6F
    ld a, [hl]                        ; 7B0D: 7E
    cp $89                            ; 7B0E: FE 89
    jp z, SndOut_Skip                 ; 7B10: CA 14 7B
    ret                               ; 7B13: C9
SndOut_Skip:
    pop de                            ; 7B14: D1
    ret                               ; 7B15: C9

; Hardware ch1: +7 -> NR10, +8 -> NR11, +9 -> NR12, note -> NR13/NR14 (trigger)
SndOut_Ch1:
    ld h, HIGH(wSndSfxTracks)         ; 7B16: 26 DF
    call SndOut_SelectSource          ; 7B18: CD E0 7A
    ld a, b                           ; 7B1B: 78
    add $07                           ; 7B1C: C6 07
    ld l, a                           ; 7B1E: 6F
    ld a, [hl+]                       ; 7B1F: 2A  +7 sweep
    ld c, $10                         ; 7B20: 0E 10
    ldh [c], a                        ; 7B22: E2
    inc c                             ; 7B23: 0C
    jp SndOut_WriteRegsFreq           ; 7B24: C3 6A 7B

; Hardware ch2: +8 -> NR21, +9 -> NR22, note -> NR23/NR24 (trigger)
SndOut_Ch2:
    call SndOut_SelectSource          ; 7B27: CD E0 7A
    ld a, b                           ; 7B2A: 78
    add $08                           ; 7B2B: C6 08
    ld l, a                           ; 7B2D: 6F
    ld c, $16                         ; 7B2E: 0E 16
    jp SndOut_WriteRegsFreq           ; 7B30: C3 6A 7B

; Hardware ch3: NR30 = $80 every frame (re-enables DAC after a wave load),
; +8 -> NR31, +9 -> NR32, note -> NR33/NR34 (trigger + length enable)
SndOut_Ch3:
    ld a, $80                         ; 7B33: 3E 80
    ldh [rNR30], a                    ; 7B35: E0 1A
    call SndOut_SelectSource          ; 7B37: CD E0 7A
    ld a, b                           ; 7B3A: 78
    add $08                           ; 7B3B: C6 08
    ld l, a                           ; 7B3D: 6F
    ld c, $1c                         ; 7B3E: 0E 1C
    ld a, [hl+]                       ; 7B40: 2A
    ldh [rNR31], a                    ; 7B41: E0 1B
    ld a, [hl+]                       ; 7B43: 2A
    ldh [rNR32], a                    ; 7B44: E0 1C
    ld a, [hl+]                       ; 7B46: 2A
    sub [hl]                          ; 7B47: 96
    sla a                             ; 7B48: CB 27
    ld e, a                           ; 7B4A: 5F
    ld d, HIGH(SndFreqTable)          ; 7B4B: 16 7F
    ld a, [de]                        ; 7B4D: 1A
    inc e                             ; 7B4E: 1C
    ldh [rNR33], a                    ; 7B4F: E0 1D
    ld a, [de]                        ; 7B51: 1A
    or $c0                            ; 7B52: F6 C0
    ldh [rNR34], a                    ; 7B54: E0 1E
    ret                               ; 7B56: C9

; Hardware ch4: +9 -> NR42, +A (raw 'note' byte) -> NR43, NR44 = $80
SndOut_Ch4:
    call SndOut_SelectSource          ; 7B57: CD E0 7A
    ld a, b                           ; 7B5A: 78
    add $09                           ; 7B5B: C6 09
    ld l, a                           ; 7B5D: 6F
    ld c, $21                         ; 7B5E: 0E 21
    ld a, [hl+]                       ; 7B60: 2A
    ldh [c], a                        ; 7B61: E2
    inc c                             ; 7B62: 0C
    ld a, [hl+]                       ; 7B63: 2A
    ldh [c], a                        ; 7B64: E2
    inc c                             ; 7B65: 0C
    ld a, $80                         ; 7B66: 3E 80
    ldh [c], a                        ; 7B68: E2
    ret                               ; 7B69: C9

; Write [hl+] -> [c], [hl+] -> [c+1], then frequency from
; SndFreqTable[(note - transpose)] -> [c+2], [c+3] | $80
SndOut_WriteRegsFreq:
    ld a, [hl+]                       ; 7B6A: 2A
    ldh [c], a                        ; 7B6B: E2
    inc c                             ; 7B6C: 0C
    ld a, [hl+]                       ; 7B6D: 2A
    ldh [c], a                        ; 7B6E: E2
    inc c                             ; 7B6F: 0C
    ld a, [hl+]                       ; 7B70: 2A  note
    sub [hl]                          ; 7B71: 96  - transpose
    sla a                             ; 7B72: CB 27
    ld e, a                           ; 7B74: 5F
    ld d, HIGH(SndFreqTable)          ; 7B75: 16 7F
    ld a, [de]                        ; 7B77: 1A
    inc e                             ; 7B78: 1C
    ldh [c], a                        ; 7B79: E2
    inc c                             ; 7B7A: 0C
    ld a, [de]                        ; 7B7B: 1A
    or $80                            ; 7B7C: F6 80
    ldh [c], a                        ; 7B7E: E2
    ret                               ; 7B7F: C9

; hl = request byte, bc = channel set base ($DF00 SFX / $DF40 music).
; If [hl] != 0: clear it, then initialise the 4 tracks of the set from
; SndTable[id] (4 pointers): length=1, counter=0, ptr, call flag=0.
Snd_StartRequest:
    ld a, [hl]                        ; 7B80: 7E
    cp $00                            ; 7B81: FE 00
    jp z, Snd_StartRequest_Done       ; 7B83: CA AD 7B
    ld d, $00                         ; 7B86: 16 00
    ld [hl], d                        ; 7B88: 72  clear request
    sla a                             ; 7B89: CB 27
    sla a                             ; 7B8B: CB 27
    sla a                             ; 7B8D: CB 27
    ld l, a                           ; 7B8F: 6F
    ld h, HIGH(SndTable)              ; 7B90: 26 7D
    ld e, $04                         ; 7B92: 1E 04
Snd_StartRequest_Loop:
    ld a, $01                         ; 7B94: 3E 01
    ld [bc], a                        ; 7B96: 02  +0 length = 1
    inc c                             ; 7B97: 0C
    dec a                             ; 7B98: 3D
    ld [bc], a                        ; 7B99: 02  +1 counter = 0
    inc c                             ; 7B9A: 0C
    ld a, [hl+]                       ; 7B9B: 2A
    ld [bc], a                        ; 7B9C: 02  +2 ptr lo
    inc c                             ; 7B9D: 0C
    ld a, [hl+]                       ; 7B9E: 2A
    ld [bc], a                        ; 7B9F: 02  +3 ptr hi
    inc c                             ; 7BA0: 0C
    inc c                             ; 7BA1: 0C
    inc c                             ; 7BA2: 0C
    xor a                             ; 7BA3: AF
    ld [bc], a                        ; 7BA4: 02  +6 call flag = 0
    ld a, c                           ; 7BA5: 79
    add $0a                           ; 7BA6: C6 0A
    ld c, a                           ; 7BA8: 4F
    dec e                             ; 7BA9: 1D
    jp nz, Snd_StartRequest_Loop      ; 7BAA: C2 94 7B
Snd_StartRequest_Done:
    ret                               ; 7BAD: C9

; Advance to next track (wSndChanOfs += $10) and fall into Snd_UpdateChannel
Snd_UpdateNextChannel:
    ld a, [wSndChanOfs]               ; 7BAE: FA 05 C0
    add $10                           ; 7BB1: C6 10

; a = track offset in $DFxx. If track active, bump its frame counter;
; when counter == length, reset it and read events up to the next row.
Snd_UpdateChannel:
    ld [wSndChanOfs], a               ; 7BB3: EA 05 C0
    ld l, a                           ; 7BB6: 6F
    ld h, HIGH(wSndSfxTracks)         ; 7BB7: 26 DF
    ld a, [hl+]                       ; 7BB9: 2A
    cp $00                            ; 7BBA: FE 00
    jp z, Snd_Return                  ; 7BBC: CA EC 7C
    inc [hl]                          ; 7BBF: 34
    ld d, [hl]                        ; 7BC0: 56
    cp d                              ; 7BC1: BA  counter == length?
    jp nz, Snd_Return                 ; 7BC2: C2 EC 7C
    ld a, $00                         ; 7BC5: 3E 00
    ld [hl+], a                       ; 7BC7: 22
    ld c, [hl]                        ; 7BC8: 4E
    inc l                             ; 7BC9: 2C
    ld b, [hl]                        ; 7BCA: 46

; Event loop: $00-$7F note, $80-$8E command (via SndCmdTable),
; $90-$FF set row length (byte - $90) and continue.
Snd_ReadEvent:
    ld a, [bc]                        ; 7BCB: 0A
    inc bc                            ; 7BCC: 03
    cp $80                            ; 7BCD: FE 80
    jp c, Snd_StoreNote               ; 7BCF: DA E8 7B
    cp $90                            ; 7BD2: FE 90
    jp nc, Snd_SetLength              ; 7BD4: D2 FE 7B
    and $0f                           ; 7BD7: E6 0F
    sla a                             ; 7BD9: CB 27
    ld e, a                           ; 7BDB: 5F
    ld d, $00                         ; 7BDC: 16 00
    ld hl, SndCmdTable                ; 7BDE: 21 0B 7C
    add hl, de                        ; 7BE1: 19
    ld a, [hl+]                       ; 7BE2: 2A
    ld h, [hl]                        ; 7BE3: 66
    ld l, a                           ; 7BE4: 6F
    jp hl                             ; 7BE5: E9

; $89: 'hold' row - stored as the note; output skips it so nothing is retriggered
SndCmd_89_Hold:
    ld a, $89                         ; 7BE6: 3E 89
Snd_StoreNote:
    ld e, a                           ; 7BE8: 5F
    ld a, [wSndChanOfs]               ; 7BE9: FA 05 C0
    add $0a                           ; 7BEC: C6 0A
    ld l, a                           ; 7BEE: 6F
    ld h, HIGH(wSndSfxTracks)         ; 7BEF: 26 DF
    ld [hl], e                        ; 7BF1: 73
    ld a, [wSndChanOfs]               ; 7BF2: FA 05 C0
    add $02                           ; 7BF5: C6 02
    ld l, a                           ; 7BF7: 6F
    ld h, HIGH(wSndSfxTracks)         ; 7BF8: 26 DF
    ld [hl], c                        ; 7BFA: 71
    inc l                             ; 7BFB: 2C
    ld [hl], b                        ; 7BFC: 70
    ret                               ; 7BFD: C9
Snd_SetLength:
    sub $90                           ; 7BFE: D6 90
    ld e, a                           ; 7C00: 5F
    ld a, [wSndChanOfs]               ; 7C01: FA 05 C0
    ld l, a                           ; 7C04: 6F
    ld h, HIGH(wSndSfxTracks)         ; 7C05: 26 DF
    ld [hl], e                        ; 7C07: 73
    jp Snd_ReadEvent                  ; 7C08: C3 CB 7B

; Command jump table for $80-$8E. There is no 16th entry: a $8F byte
; would fetch its pointer from the first two code bytes of SndCmd_8A_Pan
; ($030A) and crash.
SndCmdTable:
    dw SndCmd_80_Duty         ; $80
    dw SndCmd_81_Sweep        ; $81
    dw SndCmd_82_Transpose    ; $82
    dw SndCmd_83_Envelope     ; $83
    dw SndCmd_SkipParam       ; $84
    dw SndCmd_85_Call         ; $85
    dw SndCmd_86_Return       ; $86
    dw SndCmd_87_EndTrack     ; $87
    dw SndCmd_SkipParam       ; $88
    dw SndCmd_89_Hold         ; $89
    dw SndCmd_8A_Pan          ; $8A
    dw SndCmd_8B_Jump         ; $8B
    dw SndCmd_8C_LoadWave     ; $8C
    dw SndCmd_SkipParam       ; $8D
    dw SndCmd_8E_MasterVol    ; $8E

; $8A xx: NR51 = xx (also copied to wSndNR51)
SndCmd_8A_Pan:
    ld a, [bc]                        ; 7C29: 0A
    inc bc                            ; 7C2A: 03
    ld [wSndNR51], a                  ; 7C2B: EA 00 C4  shadow copy
    ldh [rNR51], a                    ; 7C2E: E0 25
    jp Snd_ReadEvent                  ; 7C30: C3 CB 7B

; $8E xx: NR50 = xx
SndCmd_8E_MasterVol:
    ld a, [bc]                        ; 7C33: 0A
    inc bc                            ; 7C34: 03
    ldh [rNR50], a                    ; 7C35: E0 24
    jp Snd_ReadEvent                  ; 7C37: C3 CB 7B

; $8C xx: NR30 = 0, copy 16 bytes from SndWaveTable+xx to wave RAM
SndCmd_8C_LoadWave:
    ld a, $00                         ; 7C3A: 3E 00
    ldh [rNR30], a                    ; 7C3C: E0 1A
    ld h, HIGH(SndWaveTable)          ; 7C3E: 26 7E
    ld a, [bc]                        ; 7C40: 0A
    inc bc                            ; 7C41: 03
    ld l, a                           ; 7C42: 6F
    ld de, _AUD3WAVERAM               ; 7C43: 11 30 FF
    call Snd_Copy4                    ; 7C46: CD 55 7C
    call Snd_Copy4                    ; 7C49: CD 55 7C
    call Snd_Copy4                    ; 7C4C: CD 55 7C
    call Snd_Copy4                    ; 7C4F: CD 55 7C
    jp Snd_ReadEvent                  ; 7C52: C3 CB 7B
Snd_Copy4:
    ld a, [hl+]                       ; 7C55: 2A
    ld [de], a                        ; 7C56: 12
    inc e                             ; 7C57: 1C
    ld a, [hl+]                       ; 7C58: 2A
    ld [de], a                        ; 7C59: 12
    inc e                             ; 7C5A: 1C
    ld a, [hl+]                       ; 7C5B: 2A
    ld [de], a                        ; 7C5C: 12
    inc e                             ; 7C5D: 1C
    ld a, [hl+]                       ; 7C5E: 2A
    ld [de], a                        ; 7C5F: 12
    inc e                             ; 7C60: 1C
    ret                               ; 7C61: C9

; $80 xx: track +8 = xx (NR11/NR21 duty+length, NR31 length)
SndCmd_80_Duty:
    ld a, [wSndChanOfs]               ; 7C62: FA 05 C0
    add $08                           ; 7C65: C6 08
    jp Snd_StoreParam                 ; 7C67: C3 7F 7C

; $81 xx: track +7 = xx (NR10 sweep; only used by ch1 output)
SndCmd_81_Sweep:
    ld a, [wSndChanOfs]               ; 7C6A: FA 05 C0
    add $07                           ; 7C6D: C6 07
    jp Snd_StoreParam                 ; 7C6F: C3 7F 7C

; $82 xx: track +B = xx (subtracted from note before table lookup)
SndCmd_82_Transpose:
    ld a, [wSndChanOfs]               ; 7C72: FA 05 C0
    add $0b                           ; 7C75: C6 0B
    jp Snd_StoreParam                 ; 7C77: C3 7F 7C

; $83 xx: track +9 = xx (NR12/NR22/NR42 envelope, NR32 volume)
SndCmd_83_Envelope:
    ld a, [wSndChanOfs]               ; 7C7A: FA 05 C0
    add $09                           ; 7C7D: C6 09
Snd_StoreParam:
    ld l, a                           ; 7C7F: 6F
    ld h, HIGH(wSndSfxTracks)         ; 7C80: 26 DF
    ld a, [bc]                        ; 7C82: 0A
    inc bc                            ; 7C83: 03
    ld [hl], a                        ; 7C84: 77
    jp Snd_ReadEvent                  ; 7C85: C3 CB 7B

; $84 xx / $88 xx / $8D xx: unused, parameter skipped
SndCmd_SkipParam:
    ld a, [bc]                        ; 7C88: 0A
    inc bc                            ; 7C89: 03
    jp Snd_ReadEvent                  ; 7C8A: C3 CB 7B

; $85 lo hi: one-level call - save return ptr at +4/+5, set +6 = 1, jump
SndCmd_85_Call:
    ld a, [wSndChanOfs]               ; 7C8D: FA 05 C0
    add $04                           ; 7C90: C6 04
    ld l, a                           ; 7C92: 6F
    ld h, HIGH(wSndSfxTracks)         ; 7C93: 26 DF
    ld a, [bc]                        ; 7C95: 0A
    inc bc                            ; 7C96: 03
    ld e, a                           ; 7C97: 5F
    ld a, [bc]                        ; 7C98: 0A
    inc bc                            ; 7C99: 03
    ld [hl], c                        ; 7C9A: 71
    inc l                             ; 7C9B: 2C
    ld [hl], b                        ; 7C9C: 70
    inc l                             ; 7C9D: 2C
    ld b, a                           ; 7C9E: 47
    ld c, e                           ; 7C9F: 4B
    ld a, $01                         ; 7CA0: 3E 01
    ld [hl], a                        ; 7CA2: 77
    jp Snd_ReadEvent                  ; 7CA3: C3 CB 7B

; $86: if call flag (+6) set -> clear it and return to +4/+5.
; Otherwise end of song: zero the length byte of all 4 tracks in the
; set being processed (wSndSetFlag: 0 = SFX set $DF00, 1 = music $DF40).
SndCmd_86_Return:
    ld a, [wSndChanOfs]               ; 7CA6: FA 05 C0
    add $06                           ; 7CA9: C6 06
    ld l, a                           ; 7CAB: 6F
    ld h, HIGH(wSndSfxTracks)         ; 7CAC: 26 DF
    ld a, [hl]                        ; 7CAE: 7E
    cp $00                            ; 7CAF: FE 00
    jp z, Snd_EndSong                 ; 7CB1: CA BD 7C
    ld a, $00                         ; 7CB4: 3E 00
    ld [hl-], a                       ; 7CB6: 32
    ld b, [hl]                        ; 7CB7: 46  return address
    dec l                             ; 7CB8: 2D
    ld c, [hl]                        ; 7CB9: 4E
    jp Snd_ReadEvent                  ; 7CBA: C3 CB 7B
Snd_EndSong:
    ld b, $00                         ; 7CBD: 06 00
    ld a, [wSndSetFlag]               ; 7CBF: FA 06 C0
    cp $01                            ; 7CC2: FE 01
    jp z, Snd_EndSong_Music           ; 7CC4: CA D5 7C
    ld hl, wSndSfxTracks              ; 7CC7: 21 00 DF
    ld [hl], b                        ; 7CCA: 70
    ld l, LOW(wSndSfxTracks + $10)    ; 7CCB: 2E 10
    ld [hl], b                        ; 7CCD: 70
    ld l, LOW(wSndSfxTracks + $20)    ; 7CCE: 2E 20
    ld [hl], b                        ; 7CD0: 70
    ld l, LOW(wSndSfxTracks + $30)    ; 7CD1: 2E 30
    ld [hl], b                        ; 7CD3: 70
    ret                               ; 7CD4: C9
Snd_EndSong_Music:
    ld hl, wSndMusicTracks            ; 7CD5: 21 40 DF
    ld [hl], b                        ; 7CD8: 70
    ld l, LOW(wSndSfxTracks + $50)    ; 7CD9: 2E 50
    ld [hl], b                        ; 7CDB: 70
    ld l, LOW(wSndSfxTracks + $60)    ; 7CDC: 2E 60
    ld [hl], b                        ; 7CDE: 70
    ld l, LOW(wSndSfxTracks + $70)    ; 7CDF: 2E 70
    ld [hl], b                        ; 7CE1: 70
    ret                               ; 7CE2: C9

; $87: end this track only (length = 0)
SndCmd_87_EndTrack:
    ld a, [wSndChanOfs]               ; 7CE3: FA 05 C0
    ld l, a                           ; 7CE6: 6F
    ld h, HIGH(wSndSfxTracks)         ; 7CE7: 26 DF
    ld a, $00                         ; 7CE9: 3E 00
    ld [hl], a                        ; 7CEB: 77
Snd_Return:
    ret                               ; 7CEC: C9

; $8B lo hi: jump (used for loops)
SndCmd_8B_Jump:
    ld a, [bc]                        ; 7CED: 0A
    inc bc                            ; 7CEE: 03
    ld l, a                           ; 7CEF: 6F
    ld a, [bc]                        ; 7CF0: 0A
    inc bc                            ; 7CF1: 03
    ld b, a                           ; 7CF2: 47
    ld c, l                           ; 7CF3: 4D
    jp Snd_ReadEvent                  ; 7CF4: C3 CB 7B

; leftover bytes, not referenced
    db $10, $00, $00, $00, $F0, $32, $39, $33, $30

; ---- SndTable: 4 track pointers (ch1, ch2, ch3, ch4) per sound id -------------
; id 0 is never started (a request of 0 means "nothing pending").
SndTable:
    dw Snd00_Ch1, Snd00_Ch2, Snd00_Ch3, Snd00_Ch4 ; $00
    dw Snd00_Ch1, Snd00_Ch2, Snd00_Ch3, Snd00_Ch4 ; $01
    dw Snd02_Ch1, Snd02_Ch2, Snd02_Ch3, Snd02_Ch4 ; $02
    dw Snd03_Ch1, Snd03_Ch2, Snd03_Ch3, Snd03_Ch4 ; $03
    dw Snd04_Ch1, Snd04_Ch2, Snd04_Ch3, Snd04_Ch4 ; $04
    dw Snd05_Ch1, Snd05_Ch2, Snd05_Ch3, Snd05_Ch4 ; $05
    dw Snd06_Ch1, Snd06_Ch2, Snd06_Ch3, Snd06_Ch4 ; $06
    dw Snd07_Ch1, Snd07_Ch2, Snd07_Ch3, Snd07_Ch4 ; $07
    dw Snd08_Ch1, Snd08_Ch2, Snd08_Ch3, Snd08_Ch4 ; $08
    dw Snd09_Ch1, Snd09_Ch2, Snd09_Ch3, Snd09_Ch4 ; $09
    dw Snd0A_Ch1, Snd0A_Ch2, Snd0A_Ch3, Snd09_Ch4 ; $0A
    dw Snd0B_Ch1, Snd0B_Ch2, Snd0B_Ch3, Snd0B_Ch4 ; $0B
    dw Snd0C_Ch1, Snd0C_Ch2, Snd0C_Ch3, Snd0C_Ch4 ; $0C
    dw Snd0D_Ch1, Snd0D_Ch2, Snd0D_Ch3, Snd0D_Ch4 ; $0D
    dw Snd0E_Ch1, Snd0E_Ch2, Snd0E_Ch3, Snd0C_Ch4 ; $0E
    dw Snd0F_Ch1, Snd0F_Ch2, Snd0F_Ch3, Snd0F_Ch4 ; $0F
    dw Snd10_Ch1, Snd10_Ch1, Snd10_Ch3, Snd10_Ch3 ; $10
    dw Snd11_Ch1, Snd11_Ch1, Snd10_Ch3, Snd10_Ch3 ; $11
    dw Snd10_Ch3, Snd12_Ch2, Snd10_Ch3, Snd10_Ch3 ; $12
    dw Snd13_Ch1, Snd10_Ch3, Snd10_Ch3, Snd10_Ch3 ; $13
    dw Snd14_Ch1, Snd14_Ch2, Snd10_Ch3, Snd10_Ch3 ; $14
    dw Snd10_Ch3, Snd10_Ch3, Snd10_Ch3, Snd15_Ch4 ; $15
    dw Snd10_Ch3, Snd10_Ch3, Snd10_Ch3, Snd16_Ch4 ; $16
    dw Snd10_Ch3, Snd10_Ch3, Snd10_Ch3, Snd17_Ch4 ; $17
    dw Snd18_Ch1, Snd18_Ch2, Snd10_Ch3, Snd10_Ch3 ; $18
    dw Snd10_Ch3, Snd10_Ch3, Snd10_Ch3, Snd19_Ch4 ; $19
    dw Snd1A_Ch1, Snd1A_Ch2, Snd1A_Ch3, Snd1A_Ch4 ; $1A
    dw Snd1B_Ch1, Snd1B_Ch2, Snd1B_Ch3, Snd1B_Ch4 ; $1B
    dw Snd1C_Ch1, Snd1C_Ch2, Snd1C_Ch3, Snd1C_Ch4 ; $1C
    dw Snd1D_Ch1, Snd1D_Ch2, Snd1D_Ch3, Snd1D_Ch4 ; $1D
    dw Snd1E_Ch1, Snd1E_Ch2, Snd1D_Ch4, Snd1E_Ch4 ; $1E
    dw Snd1F_Ch1, Snd1F_Ch2, Snd1F_Ch3, Snd1D_Ch4 ; $1F

; ---- SndWaveTable: 5 x 16-byte ch3 wave patterns ($8C $00/$10/$20/$30/$40) --
SndWaveTable:
    db $01, $23, $45, $67, $89, $AB, $CD, $EF, $FE, $DC, $BA, $98, $76, $54, $32, $10 ; $00
    db $00, $11, $22, $33, $44, $55, $66, $77, $88, $99, $AA, $BB, $CC, $DD, $EE, $FF ; $10
    db $00, $21, $42, $63, $84, $A5, $C6, $E7, $08, $29, $4A, $6B, $8C, $AD, $CE, $EF ; $20
    db $04, $08, $0C, $0F, $0C, $08, $04, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $30
    db $02, $46, $8A, $CE, $FF, $FF, $FF, $FF, $ED, $CB, $A9, $87, $65, $43, $21, $00 ; $40


SECTION "Lenar Sound Freq Table", ROMX[$7F00], BANK[3]
; ---- SndFreqTable: 72 GB frequency values, note $00 = C2 (65.4 Hz on ch1/2) ---
SndFreqTable:
    dw $002C, $009D, $0107, $016B, $01C9, $0223, $0277, $02C7, $0312, $0358, $039B, $03DA ; C_2-B_2
    dw $0416, $044E, $047F, $04B5, $04E5, $0511, $053B, $0563, $0589, $05AC, $05CE, $05ED ; C_3-B_3
    dw $060B, $0627, $0642, $065B, $0672, $0689, $069E, $06B2, $06C4, $06D6, $06E7, $06F7 ; C_4-B_4
    dw $0706, $0714, $0721, $072D, $0739, $0744, $074F, $0759, $0762, $076B, $0773, $077B ; C_5-B_5
    dw $0783, $078A, $0790, $0797, $079D, $07A2, $07A7, $07AC, $07B1, $07B6, $07BA, $07BE ; C_6-B_6
    dw $07C1, $07C5, $07C8, $07CB, $07CE, $07D1, $07D4, $07D6, $07D9, $07DB, $07DD, $07DF ; C_7-B_7

; Called once per frame with bank 3 paged in.
; 1. Start pending requests (SFX request -> $DF00 set, music request -> $DF40 set)
; 2. Advance all 8 tracks (SFX set with wSndSetFlag=0, then music set with 1)
; 3. Write the 4 hardware channels (SFX track has priority over music track)
SoundUpdate:
    ld hl, wSndReqSfx                 ; 7F90: 21 1E DF
    ld bc, wSndSfxTracks              ; 7F93: 01 00 DF
    call Snd_StartRequest             ; 7F96: CD 80 7B
    ld hl, wSndReqMusic               ; 7F99: 21 0E DF
    ld bc, wSndMusicTracks            ; 7F9C: 01 40 DF
    call Snd_StartRequest             ; 7F9F: CD 80 7B
    ld a, $00                         ; 7FA2: 3E 00
    ld [wSndSetFlag], a               ; 7FA4: EA 06 C0
    call Snd_UpdateChannel            ; 7FA7: CD B3 7B
    call Snd_UpdateNextChannel        ; 7FAA: CD AE 7B
    call Snd_UpdateNextChannel        ; 7FAD: CD AE 7B
    call Snd_UpdateNextChannel        ; 7FB0: CD AE 7B
    ld a, $01                         ; 7FB3: 3E 01
    ld [wSndSetFlag], a               ; 7FB5: EA 06 C0
    call Snd_UpdateNextChannel        ; 7FB8: CD AE 7B
    call Snd_UpdateNextChannel        ; 7FBB: CD AE 7B
    call Snd_UpdateNextChannel        ; 7FBE: CD AE 7B
    call Snd_UpdateNextChannel        ; 7FC1: CD AE 7B
    ld b, $00                         ; 7FC4: 06 00
    call SndOut_Ch1                   ; 7FC6: CD 16 7B
    ld b, $10                         ; 7FC9: 06 10
    call SndOut_Ch2                   ; 7FCB: CD 27 7B
    ld b, $20                         ; 7FCE: 06 20
    call SndOut_Ch3                   ; 7FD0: CD 33 7B
    ld b, $30                         ; 7FD3: 06 30
    jp SndOut_Ch4                     ; 7FD5: C3 57 7B
