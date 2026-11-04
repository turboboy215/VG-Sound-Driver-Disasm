; ==============================================================================
; Lenar sound driver - Mercenary Force (UE) [!]
; Disassembly of the sound driver code, tables and all music/SFX data (bank 3).
; Builds byte-exact with RGBDS:  rgbasm -o snd.o MercenaryForce_sound.asm ; rgblink -p 0xFF -o snd.gb snd.o
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
DEF wSndReqSfx      EQU $DF0E  ; write a SndTable id here to start it in the SFX set
DEF wSndReqMusic    EQU $DF1E  ; write a SndTable id here to start it in the music set
DEF wSndChanOfs     EQU $C116  ; offset ($00-$70) of the track being updated
DEF wSndSetFlag     EQU $C117  ; 0 while updating SFX set, 1 while updating music set
DEF wSndNR51        EQU $C141  ; shadow copy of the last NR51 value written by $8A

SECTION "Lenar Sound Update + Data", ROMX[$4000], BANK[3]

; Called once per frame with bank 3 paged in.
; 1. Start pending requests (SFX request -> $DF00 set, music request -> $DF40 set)
; 2. Advance all 8 tracks (SFX set with wSndSetFlag=0, then music set with 1)
; 3. Write the 4 hardware channels (SFX track has priority over music track)
SoundUpdate:
    ld hl, wSndReqSfx                 ; 4000: 21 0E DF
    ld bc, wSndSfxTracks              ; 4003: 01 00 DF
    call Snd_StartRequest             ; 4006: CD 80 7B
    ld hl, wSndReqMusic               ; 4009: 21 1E DF
    ld bc, wSndMusicTracks            ; 400C: 01 40 DF
    call Snd_StartRequest             ; 400F: CD 80 7B
    xor a                             ; 4012: AF
    ld [wSndSetFlag], a               ; 4013: EA 17 C1
    call Snd_UpdateChannel            ; 4016: CD B3 7B
    call Snd_UpdateNextChannel        ; 4019: CD AE 7B
    call Snd_UpdateNextChannel        ; 401C: CD AE 7B
    call Snd_UpdateNextChannel        ; 401F: CD AE 7B
    ld a, $01                         ; 4022: 3E 01
    ld [wSndSetFlag], a               ; 4024: EA 17 C1
    call Snd_UpdateNextChannel        ; 4027: CD AE 7B
    call Snd_UpdateNextChannel        ; 402A: CD AE 7B
    call Snd_UpdateNextChannel        ; 402D: CD AE 7B
    call Snd_UpdateNextChannel        ; 4030: CD AE 7B
    ld b, $00                         ; 4033: 06 00
    call SndOut_Ch1                   ; 4035: CD 16 7B
    ld b, $10                         ; 4038: 06 10
    call SndOut_Ch2                   ; 403A: CD 27 7B
    ld b, $20                         ; 403D: 06 20
    call SndOut_Ch3                   ; 403F: CD 33 7B
    ld b, $30                         ; 4042: 06 30
    jp SndOut_Ch4                     ; 4044: C3 57 7B

; ---- music / SFX data ---------------------------------------------------------

Snd01_Ch1:
    snd_sweep $00

Snd01_Ch2:
    snd_len 1
    snd_duty $00
    snd_env $00
    db $53
    snd_endsong

Snd01_Ch3:
    snd_len 1
    snd_env $00
    snd_pan $00
    db C_3
    snd_endsong

Snd01_Ch4:
Snd02_Ch4:
Snd03_Ch4:
Snd04_Ch4:
Snd05_Ch4:
Snd06_Ch4:
Snd07_Ch4:
Snd08_Ch4:
Snd09_Ch4:
Snd0A_Ch4:
Snd12_Ch4:
Snd13_Ch4:
Snd14_Ch4:
Snd15_Ch4:
Snd16_Ch4:
Snd17_Ch4:
Snd18_Ch4:
Snd19_Ch4:
    snd_len 1
    snd_duty $00
    snd_env $00
    db $0C
    snd_end

Snd05_Ch1:
    snd_transpose $00
    snd_duty $40
    snd_env $C1
    snd_call SndSub_4081
    snd_env $C1
    snd_duty $20
    snd_call SndSub_40A3
    snd_call SndSub_40A3
    snd_duty $40
    snd_call SndSub_40E5
    snd_duty $00
    snd_call SndSub_4107
    snd_call SndSub_4107
    snd_jump Snd05_Ch1

SndSub_4081:
    snd_len 10
    db G_4
    snd_hold
    snd_hold
    db Ds4, D_4
    snd_hold
    db C_4
    snd_hold
    db G_4
    snd_hold
    db D_4, Ds4, Gs4
    snd_hold
    db C_4
    snd_hold
    db D_5, C_5, Gs4, G_4, C_5
    snd_hold
    db Ds5
    snd_hold
    db D_4, Ds4, D_4, C_4, Gs3
    snd_hold
    db G_3
    snd_hold
    snd_ret

SndSub_40A3:
    snd_len 5
    db D_4
    snd_hold
    db D_4
    snd_hold
    db D_4
    snd_hold
    db D_4
    snd_hold
    db D_4
    snd_hold
    db Ds4, D_4, C_4
    snd_hold
    db Gs3
    snd_hold
    db C_4
    snd_hold
    db D_4, C_4, Gs3
    snd_hold
    db G_3
    snd_hold
    db C_4
    snd_hold
    db D_4, C_4, Gs3
    snd_hold
    db G_3
    snd_hold
    db D_4
    snd_hold
    db D_4
    snd_hold
    db D_4
    snd_hold
    db D_4
    snd_hold
    db D_4
    snd_hold
    db Ds4, D_4, C_4
    snd_hold
    db Gs3
    snd_hold
    db C_4
    snd_hold
    db D_4, C_4, Gs3
    snd_hold
    db G_3
    snd_hold
    db C_4
    snd_hold
    db D_4
    snd_hold
    db Ds4
    snd_hold
    db G_4
    snd_hold
    snd_ret

SndSub_40E5:
    snd_len 10
    db Gs4
    snd_hold
    db G_4, G_4, Gs4
    snd_hold
    db G_4, G_4, Gs4
    snd_hold
    db C_5, C_5, Gs4
    snd_hold
    db G_4, G_4, Ds4
    snd_hold
    db D_4, C_4, Ds4
    snd_hold
    db D_4, C_4, Gs3
    snd_hold
    db G_3, G_3, Ds3
    snd_hold
    db D_3, D_3
    snd_ret

SndSub_4107:
    db A_4, G_4, D_4, D_4, A_4, G_4, D_4, D_4, G_4, F_4, C_4, C_4, G_4, F_4, C_4, C_4
    db A_4, G_4, D_4, D_4, A_4, G_4, D_4, D_4, G_4, F_4, C_4, C_4, G_4, F_4, C_4, C_4
    snd_ret

Snd05_Ch2:
    snd_transpose $00
    snd_env $D1
    snd_call SndSub_4141
    snd_call SndSub_4163
    snd_call SndSub_4163
    snd_call SndSub_41A5
    snd_call SndSub_41C7
    snd_call SndSub_41C7
    snd_jump Snd05_Ch2

SndSub_4141:
    snd_len 10
    db C_3, D_3, Ds3, G_3, Gs3, C_4, C_3, D_3, Ds3, G_3, Gs3, C_4, C_3, D_3, Ds3, G_3
    db Gs3, C_4, C_3, D_3, Ds3, G_3, Gs3, C_4, C_3, D_3, Ds3, G_3, Gs3, C_4, Gs3, G_3
    snd_ret

SndSub_4163:
    snd_len 5
    db G_3
    snd_hold
    db G_3
    snd_hold
    db G_3
    snd_hold
    db G_3
    snd_hold
    db G_3
    snd_hold
    db Gs3, G_3, Ds3
    snd_hold
    db D_3
    snd_hold
    db F_3
    snd_hold
    db F_3, F_3, F_3
    snd_hold
    db D_3
    snd_hold
    db Ds3
    snd_hold
    db Ds3, Ds3, Ds3
    snd_hold
    db D_3
    snd_hold
    db G_3
    snd_hold
    db G_3
    snd_hold
    db G_3
    snd_hold
    db G_3
    snd_hold
    db G_3
    snd_hold
    db Gs3, G_3, Ds3
    snd_hold
    db D_3
    snd_hold
    db F_3
    snd_hold
    db F_3, F_3, F_3
    snd_hold
    db D_3
    snd_hold
    db Ds3
    snd_hold
    db Ds3, Ds3, Ds3
    snd_hold
    db D_3
    snd_hold
    snd_ret

SndSub_41A5:
    snd_len 10
    db D_3, D_3, C_3, C_3, D_3, D_3, C_3, C_3, D_3, D_3, C_3, C_3, D_3, D_3, C_3, C_3
    db Ds3, Ds3, D_3, D_3, Ds3, Ds3, D_3, D_3, Ds3, Ds3, D_3, D_3, Ds3, Ds3, D_3, D_3
    snd_ret

SndSub_41C7:
    snd_len 10
    db D_4, G_4, D_4, G_4, D_4, G_4, D_4, G_4, C_4, F_4, C_4, F_4, C_4, F_4, C_4, F_4
    db D_3, D_3, D_3, D_3, D_3, D_3, D_3, D_3, C_3, C_3, C_3, C_3, C_3, C_3, C_3, C_3
    snd_ret

Snd05_Ch3:
    snd_transpose $00
    snd_wave $10
    snd_env $20
    snd_duty $E0
    snd_pan $FB
    snd_call SndSub_420F
    snd_call SndSub_4227
    snd_call SndSub_4227
    snd_call SndSub_4249
    snd_call SndSub_426B
    snd_pan $AF
    snd_call SndSub_4270
    snd_pan $FF
    snd_call SndSub_4270
    snd_jump Snd05_Ch3

SndSub_420F:
    snd_len 20
    db G_4, Ds4, D_4, C_4
    snd_len 10
    db G_4, G_4, Ds4, Ds4, D_4, D_4, C_4, C_4
    snd_len 20
    db D_4, Ds4, D_4, Ds4, D_4, C_4, Gs3, G_3
    snd_ret

SndSub_4227:
    snd_len 10
    db D_4, D_5, D_4, D_5, D_4, D_5, D_4, D_5, C_4, C_5, C_4, C_5, C_4, C_5, C_4, C_5
    db D_4, D_5, D_4, D_5, D_4, D_5, D_4, D_5, C_4, C_5, C_4, C_5, C_4, C_5, C_4, C_5
    snd_ret

SndSub_4249:
    snd_len 10
    db Gs4, G_4, Ds4, D_4, Gs4, G_4, Ds4, D_4, Gs4, G_4, Ds4, D_4, Gs4, G_4, Ds4, D_4
    db Ds4, D_4, C_4, G_3, Ds4, D_4, C_4, G_3, Ds4, D_4, C_4, G_3, Ds4, D_4, C_4, G_3
    snd_ret

SndSub_426B:
    snd_len 40
    snd_hold
    snd_hold
    snd_hold
    snd_hold

SndSub_4270:
    snd_len 10
    db A_4, A_4, A_4, D_5, G_4, D_4, D_4, D_4, G_4, G_4, G_4, C_5, F_4, C_4, C_4, C_4
    snd_ret

Snd04_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_pan $DB
    snd_len 10
    db G_4, G_4, G_4, G_4, A_4, A_4, A_4, A_4, C_4, C_4, C_4, C_4, D_4, D_4, D_4, D_4
    db A_5, G_5, D_5, C_5, A_5, G_5, D_5, C_5, A_5, G_5, D_5, C_5, A_5, G_5, D_5, C_5
    snd_jump Snd04_Ch1

Snd04_Ch2:
    snd_len 5
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $80
    snd_env $C1
    db C_4, C_4, C_4, C_4, C_4, C_4, C_4, C_4, D_4, D_4, D_4, D_4, D_4, D_4, D_4, D_4
    db F_3, F_3, F_3, F_3, F_3, F_3, F_3, F_3, G_3, G_3, G_3, G_3, G_3, G_3, G_3, G_3
    db C_3, D_3, G_3, A_3, C_4, D_4, G_4, A_4, C_5, D_5, G_5, A_5, G_5, D_5, C_5, A_4
    db C_3, D_3, G_3, A_3, C_4, D_4, G_4, A_4, C_5, D_5, G_5, A_5, G_5, D_5, C_5, A_4
    snd_jump Snd04_Ch2

Snd04_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_wave $10
    snd_env $20
    snd_duty $E0
    snd_len 20
    db C_4, C_4, D_4, D_4, G_3, G_3, A_3, A_3
    snd_len 10
    db A_5, G_5, A_5, G_5, A_5, G_5, A_5, G_5, D_5, C_5, D_5, C_5, D_5, C_5, D_5, C_5
    snd_jump Snd04_Ch3

Snd06_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_pan $DB
    snd_len 10
    db C_2, C_5, G_4, D_5, G_4, C_5, G_4, D_5, Gs4, C_5, Gs4, G_4, Gs4, C_5, Gs4, G_4
    db Ds5, Ds5, Ds5, Ds5, D_5, C_5, Gs4, C_5, G_4, G_4, G_4, G_4, G_4, Ds4, D_4
    snd_hold
    snd_len 5
    snd_pan $BB
    snd_hold
    db C_3
    snd_hold
    db D_3
    snd_hold
    db Ds3
    snd_hold
    db G_3
    snd_hold
    db Gs3
    snd_hold
    db C_4
    snd_hold
    db D_4
    snd_hold
    db G_4
    snd_hold
    db Gs4
    snd_hold
    db G_4
    snd_hold
    db Ds4
    snd_hold
    db D_4
    snd_hold
    db Ds4
    snd_hold
    db D_4
    snd_hold
    db C_4
    snd_hold
    db Gs3
    snd_hold
    db C_3
    snd_hold
    db D_3
    snd_hold
    db Ds3
    snd_hold
    db G_3
    snd_hold
    db Gs3
    snd_hold
    db C_4
    snd_hold
    db D_4
    snd_hold
    db Ds4
    snd_hold
    db G_4
    snd_hold
    db Gs4
    snd_hold
    db C_5
    snd_hold
    db Gs4
    snd_hold
    db G_4
    snd_hold
    db Ds4
    snd_hold
    db D_4
    snd_hold
    db C_4
    snd_jump Snd06_Ch1

Snd06_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_len 10
    db C_4
    snd_hold
    db D_4, Ds4, C_4
    snd_hold
    db D_4, Ds4, Gs3
    snd_hold
    db C_4, D_4, Gs3
    snd_hold
    db Gs3, Gs3, G_3
    snd_hold
    db D_4, Ds4, G_3
    snd_hold
    db D_4, Ds4, G_3, Gs3, D_4, Ds4, D_4, C_4, Gs3
    snd_hold
    db C_4, D_4, Ds4, G_4, Gs4, C_5, D_5, G_5, Gs5, G_5, Ds5, D_5, Ds5, D_5, C_5, Gs4
    db C_4, D_4, Ds4, G_4, Gs4, C_5, D_5, Ds5, G_5, Gs5, C_6, Gs5, G_5, Ds5, D_5, C_5
    snd_jump Snd06_Ch2

Snd06_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_wave $10
    snd_env $20
    snd_duty $E0
    snd_len 20
    db G_4, G_4, G_4, G_4, Gs4, Gs4, Gs4, Gs4, Ds4, Ds4, D_4, D_4, C_4, C_4, D_4, D_4
    snd_len 40
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_jump Snd06_Ch3

Snd07_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_pan $DB
    snd_len 12
    db C_3, G_3, C_3, G_3, C_3, G_3, C_3, G_3, C_3, A_3, C_3, A_3, C_3, A_3, C_3, A_3
    db Ds3, Gs3, Ds3, Gs3, D_3, G_3, D_3, G_3, C_3, G_3, C_3, G_3, C_3, G_3, C_3, G_3
    snd_len 6
    db D_4, D_4, D_4
    snd_hold
    db C_4, C_4, C_4
    snd_hold
    db D_4, D_4, D_4
    snd_hold
    db C_4, C_4, C_4
    snd_hold
    db D_5
    snd_hold
    db Ds5
    snd_hold
    db D_5
    snd_hold
    db C_5
    snd_hold
    db Gs4, G_4, Ds4
    snd_hold
    db Ds4
    snd_hold
    db G_4
    snd_hold
    snd_len 12
    db Gs4
    snd_hold
    db C_5, C_5, Gs4
    snd_hold
    db C_5, C_5, G_4, Gs4, G_4, Ds4, D_4, C_4, Gs3, G_3
    snd_jump Snd07_Ch1

Snd07_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_len 12
    db G_4
    snd_hold
    db G_4, G_4, A_4, C_5, A_4, G_4
    snd_len 24
    db A_4, A_4, A_4
    snd_hold
    snd_len 6
    db D_5
    snd_hold
    db Ds5
    snd_hold
    db G_5
    snd_hold
    db Gs5
    snd_hold
    db G_5
    snd_hold
    db Ds5, D_5, C_5
    snd_hold
    db A_4
    snd_hold
    db C_5
    snd_hold
    db C_4, D_4, C_4
    snd_hold
    db C_5
    snd_hold
    db C_4, D_4, C_4
    snd_hold
    db C_4
    snd_hold
    snd_hold
    snd_hold
    snd_len 24
    db D_5, C_5, D_5, C_5
    snd_len 6
    snd_hold
    db D_5
    snd_hold
    db Ds5
    snd_hold
    db D_5
    snd_hold
    db C_5
    snd_hold
    db Gs4, G_4, Ds4
    snd_hold
    db Ds4
    snd_hold
    db G_4
    snd_hold
    db Gs4
    snd_hold
    snd_hold
    snd_hold
    db C_5
    snd_hold
    db C_5
    snd_hold
    db Gs4
    snd_hold
    snd_hold
    snd_hold
    db C_5
    snd_hold
    db C_5
    snd_hold
    db G_4
    snd_hold
    db Gs4
    snd_hold
    db G_4
    snd_hold
    db Ds4
    snd_hold
    db D_4
    snd_hold
    db C_4
    snd_hold
    db Gs3
    snd_hold
    db G_3
    snd_jump Snd07_Ch2

Snd07_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_wave $10
    snd_env $20
    snd_duty $E0
    snd_len 24
    db C_5, C_5, C_5, C_5
    snd_len 12
    db A_5, A_5, A_5, A_5, A_5, C_5, D_5, E_5
    snd_len 24
    db Ds5, Ds5, D_5, D_5
    snd_len 12
    db C_5
    snd_hold
    db C_5, C_5, G_4, A_4, B_4, C_5
    snd_len 24
    db D_5, C_5, D_5, C_5
    snd_len 12
    db D_5, Ds5, D_5, C_5, C_5, C_5, C_5, C_5, Gs4, C_5, C_5, C_5, Gs4, C_5, C_5, C_5
    db G_4, C_5, C_5, C_5, D_5, C_5, Gs4, G_4
    snd_jump Snd07_Ch3

Snd08_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_pan $DB
    snd_len 40
    db G_5, F_5
    snd_len 10
    db G_5, Gs5, G_5, Ds5, C_5
    snd_hold
    snd_hold
    snd_hold
    snd_len 20
    db C_5, D_5, Ds5, G_5
    snd_len 10
    db D_5, Ds5, D_5, C_5, Gs4
    snd_hold
    db C_5
    snd_hold
    snd_len 40
    db Gs4, Fs5
    snd_len 5
    db F_5
    snd_hold
    db Fs5
    snd_hold
    db F_5
    snd_hold
    db E_5
    snd_hold
    db F_5
    snd_hold
    snd_hold
    snd_hold
    db Ds5
    snd_hold
    snd_hold
    snd_hold
    snd_len 10
    db D_5, Ds5, D_5, C_5, D_5
    snd_hold
    db F_5
    snd_hold
    snd_len 20
    db Ds5, D_5, C_5
    snd_hold
    snd_jump Snd08_Ch1

Snd08_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_len 10
    db C_4
    snd_hold
    db G_4, G_4, C_5
    snd_hold
    db G_4, G_4, C_4
    snd_hold
    db G_4, G_4, C_5
    snd_hold
    db G_4, G_4, C_4
    snd_hold
    db G_4, G_4, C_5
    snd_hold
    db G_4, G_4, C_4
    snd_hold
    db G_4, G_4, C_5
    snd_hold
    db G_4, G_4, Cs4
    snd_hold
    db Gs4, Gs4, Cs5
    snd_hold
    db Gs4, Gs4, Cs4
    snd_hold
    db Gs4, Gs4, Cs5
    snd_hold
    db Gs4, Gs4, C_4
    snd_hold
    db G_4, G_4, C_5
    snd_hold
    db G_4, G_4, C_4
    snd_hold
    db G_4, G_4, C_5
    snd_hold
    db G_4, G_4
    snd_jump Snd08_Ch2

Snd08_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_wave $10
    snd_env $20
    snd_duty $E0
    snd_len 20
    db C_5, G_4, C_5, G_4
    snd_len 10
    db C_5
    snd_hold
    db G_4
    snd_hold
    db C_5, C_5, C_5, C_5
    snd_len 20
    db C_5, G_4, C_5, G_4, C_5, G_4, C_5, G_4, Cs5, Gs4, Cs5, Gs4
    snd_len 10
    db Cs5
    snd_hold
    db Gs4
    snd_hold
    db Cs5, Cs5, Cs5, Cs5, C_5, C_5, C_5, C_5, C_5
    snd_hold
    db G_5
    snd_hold
    snd_len 20
    db C_5, G_5, C_5, G_5
    snd_jump Snd08_Ch3

Snd0B_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $80
    snd_env $C1
    snd_len 5
    db C_6
    snd_hold
    snd_endsong

Snd0C_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $80
    snd_env $C1
    snd_len 5
    db C_5
    snd_hold
    snd_endsong

Snd0D_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $80
    snd_env $C2
    snd_len 5
    db C_3
    snd_hold
    snd_endsong

Snd0E_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $80
    snd_env $C1
    snd_len 2
    db C_6, D_6, Ds6, G_6, Gs6
    snd_hold
    snd_hold
    snd_endsong

Snd0F_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $80
    snd_env $C1
    snd_len 2
    db C_6, E_6, G_6, C_7
    snd_hold
    snd_endsong

Snd10_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $80
    snd_env $C1
    snd_len 2
    db C_4, C_5, C_6, D_4, D_5, D_6
    snd_hold
    snd_endsong

Snd11_Ch2:
    snd_transpose $01 ; notes below sound 1 semitone(s) lower

SndLoop_4624:
    snd_duty $80
    snd_env $C1
    snd_len 2
    db C_5, B_4, A_4, G_4, F_4, Ds4, D_4, C_4, B_3, A_3, G_3, F_3, Ds3, D_3, C_3
    snd_endsong

Snd11_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_jump SndLoop_4624

SndUnused_463E:  ; not referenced by SndTable
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $80
    snd_env $C1
    snd_len 2
    db $0C, $18, $0E, $1A, $10, $1C
    snd_hold
    snd_endsong

Snd12_Ch1:
    snd_duty $00
    snd_env $C1
    snd_pan $DB
    snd_len 8
    snd_transpose $08 ; notes below sound 8 semitone(s) lower
    snd_call SndSub_4676
    snd_jump Snd12_Ch1

Snd12_Ch2:
    snd_duty $00
    snd_env $C1
    snd_len 8
    snd_transpose $08 ; notes below sound 8 semitone(s) lower
    snd_call SndSub_4697
    snd_jump Snd12_Ch2

Snd12_Ch3:
    snd_env $20
    snd_duty $E0
    snd_len 8
    snd_transpose $08 ; notes below sound 8 semitone(s) lower
    snd_call SndSub_4697
    snd_jump Snd12_Ch3

SndSub_4676:
    db C_3, C_4, D_3, D_4, Cs3, Cs4, Ds3, Ds4, C_3, C_4, D_3, D_4, Cs3, Cs4, Ds3, Ds4
    db As3, As4, A_3, A_4, Gs3, Gs4, G_3, G_4, As3, As4, A_3, A_4, Gs3, Gs4, G_3, G_4
    snd_ret

SndSub_4697:
    db F_3, F_4, G_3, G_4, Fs3, Fs4, Gs3, Gs4, F_3, F_4, G_3, G_4, Fs3, Fs4, Gs3, Gs4
    db F_3, F_4, E_3, E_4, Ds3, Ds4, D_3, D_4, F_3, F_4, E_3, E_4, Ds3, Ds4, D_3, D_4
    snd_ret

Snd13_Ch1:
    snd_duty $00
    snd_env $C1
    snd_pan $DB
    snd_len 8
    snd_transpose $08 ; notes below sound 8 semitone(s) lower
    snd_jump SndLoop_46D8

Snd13_Ch2:
    snd_duty $00
    snd_env $C1
    snd_len 8
    snd_transpose $08 ; notes below sound 8 semitone(s) lower
    snd_jump SndLoop_46E9

Snd13_Ch3:
    snd_env $20
    snd_duty $E0
    snd_len 8
    snd_transpose $08 ; notes below sound 8 semitone(s) lower
    snd_jump SndLoop_46E9

SndLoop_46D8:
    db G_3, G_4, F_3, F_4, D_3, D_4, C_3, C_4, G_4, G_4, G_4
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_endsong

SndLoop_46E9:
    db C_4, C_5, As3, As4, A_3, A_4, F_3, F_4, D_4, D_4, D_4
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_endsong

Snd14_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $30
    snd_env $C1
    snd_pan $DB
    snd_len 10
    db C_4, D_4, Ds4, G_4, Gs4, G_4, Ds4, D_4
    snd_len 40
    snd_env $C3
    db C_4, C_4
    snd_env $C1
    snd_len 10
    db C_4
    snd_hold
    db C_5, Gs4, G_4, Ds4, D_4, C_4
    snd_len 40
    snd_env $C3
    db D_4, D_4
    snd_env $C1
    snd_len 5
    db F_4
    snd_hold
    db F_4
    snd_hold
    db F_4
    snd_hold
    db F_4
    snd_hold
    db F_4
    snd_hold
    db G_4, F_4, D_4
    snd_hold
    db F_4
    snd_hold
    snd_len 10
    db G_4, F_4, D_4, Ds4, D_4, C_4, Gs3, C_4
    snd_len 5
    db F_4
    snd_hold
    db F_4
    snd_hold
    db F_4
    snd_hold
    db F_4
    snd_hold
    db F_4
    snd_hold
    db G_4, F_4, D_4
    snd_hold
    db C_4
    snd_hold
    snd_len 20
    db G_4, Gs4, G_4, F_4
    snd_pan $C3
    snd_len 10
    db G_3
    snd_hold
    db C_4
    snd_hold
    db G_3, G_3, C_4
    snd_hold
    snd_pan $D2
    db G_3, G_3, C_4, G_3, C_4, G_3, C_4, G_3
    snd_duty $40
    snd_pan $C3
    db G_3
    snd_hold
    db C_4
    snd_hold
    db G_3, G_3, C_4
    snd_hold
    snd_pan $D2
    db G_3, G_3, C_4, G_3, C_4, G_3, C_4, G_3
    snd_env $C1
    snd_duty $78
    snd_pan $CB
    db F_3, G_3, Gs3, C_4, D_4, C_4, Gs3, G_3
    snd_pan $DB
    db F_4, G_4, Gs4, C_5, D_5, C_5, Gs4, G_4
    snd_pan $DA
    db F_5, G_5, Gs5, C_6, D_6, C_6, Gs5, G_5
    snd_len 40
    snd_pan $DB
    db C_7
    snd_hold
    snd_jump Snd14_Ch1

Snd14_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $78
    snd_env $E1
    snd_len 10
    db C_3, C_3, G_3, G_3, D_3, D_3, C_3, C_3, C_3, D_3, Ds3, G_3, Gs3, G_3, Ds3, D_3
    db C_3, D_3, Ds3, G_3, Gs3, C_4, Gs3, G_3, D_3, F_3, G_3, F_3, D_3, F_3, G_3, F_3
    db C_3, C_3, G_3, G_3, F_3, G_3, Gs3, G_3, F_3, G_3, Gs3, G_3, F_3, G_3, Gs3, G_3
    db F_3, G_3, F_3, G_3, F_3, G_3, F_3, G_3, G_3, G_3, F_3, F_3, Ds3, Ds3, D_3, D_3
    db C_3, D_3, Ds3, G_3, Gs3, G_3, Ds3, D_3, C_3, D_3, Ds3, D_3, C_3, D_3, Ds3, D_3
    db C_4, D_4, Ds4, G_4, Gs4, G_4, Ds4, D_4, C_4, D_4, Ds4, D_4, C_4, D_4, Ds4, D_4
    db C_3, D_3, Ds3, G_3, Gs3, G_3, C_4, D_4, C_4, D_4, Ds4, G_4, Gs4, G_4, C_5, D_5
    db C_5, D_5, Ds5, G_5, Gs5, G_5, C_6, D_6, G_6, D_3, Ds3, G_3, Gs3, G_3, Ds3, D_3
    snd_jump Snd14_Ch2

Snd14_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_env $20
    snd_duty $E0
    snd_len 10
    db G_4, G_4, G_4, G_4, G_4
    snd_hold
    snd_hold
    snd_hold
    db G_4, G_4, G_4, G_4, G_4
    snd_hold
    snd_hold
    snd_hold
    db G_4, G_4, G_4, G_4, G_4
    snd_hold
    snd_hold
    snd_hold
    db D_4, D_4, D_4, D_4, D_4
    snd_hold
    snd_hold
    snd_hold
    db F_4, F_4, F_4, F_4, F_4
    snd_hold
    snd_hold
    snd_hold
    db F_4, F_4, F_4, F_4, F_4
    snd_hold
    snd_hold
    snd_hold
    db F_4, F_4, F_4, F_4, F_4
    snd_hold
    snd_hold
    snd_hold
    db G_4, G_4, F_4, F_4, Ds4, Ds4, D_4, D_4
    snd_len 20
    db C_4, C_4, C_4, C_4, C_4, C_4, C_4, C_4, C_4, C_4, C_4, C_4, C_4, C_4, C_4, C_4
    snd_len 10
    db C_4, D_4, Ds4, G_4, Gs4, G_4, Ds4, D_4, C_4, D_4, Ds4, G_4, Gs4, G_4, Ds4, D_4
    db C_4, D_4, Ds4, G_4, Gs4, G_4, Ds4, D_4
    snd_len 40
    db C_4
    snd_hold
    snd_jump Snd14_Ch3

Snd15_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_pan $DB
    snd_len 10
    db C_5, D_5, Ds5, G_5, Gs5, G_5, Ds5, D_5
    snd_len 20
    db C_5, G_4, C_5
    snd_hold
    snd_endsong

Snd15_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_len 10
    db G_3, Gs3, C_4, D_4, Ds4, D_4, C_4, Gs3, G_3
    snd_hold
    db C_4, G_3, G_3
    snd_hold
    snd_hold
    snd_hold
    snd_endsong

Snd15_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_env $20
    snd_duty $E0
    snd_len 10
    db C_4, D_4, Ds4, G_4, Gs4, G_4, Ds4, D_4
    snd_len 20
    db C_4, G_3, C_4
    snd_hold
    snd_endsong

Snd0A_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_len 10
    db C_4, G_4, Gs4, G_4, Gs4
    snd_hold
    db C_5, Gs4, G_4, Gs4, G_4, Ds4
    snd_len 5
    db D_4
    snd_hold
    db Ds4, D_4, C_4
    snd_hold
    db D_4
    snd_hold
    db C_4
    snd_hold
    db G_4
    snd_hold
    db Gs4
    snd_hold
    db G_4
    snd_hold
    snd_len 10
    db Gs4
    snd_hold
    db C_5, C_5, D_5, C_5, Gs4, G_4, Gs4, C_5, D_5
    snd_hold
    db Ds5, C_4, Ds5, C_4, D_5, C_4, D_5, C_4, C_5, C_4, C_5, C_4
    snd_len 5
    db D_5
    snd_hold
    db Ds5, D_5, C_5
    snd_hold
    db Gs4
    snd_hold
    db Gs5
    snd_hold
    db G_5
    snd_hold
    db Ds5
    snd_hold
    db D_5
    snd_hold
    db C_5
    snd_hold
    db D_5
    snd_hold
    db Ds5
    snd_hold
    db G_5
    snd_hold
    db D_5
    snd_hold
    db Ds5, D_5, C_5
    snd_hold
    db G_4
    snd_hold
    snd_len 10
    db C_5, C_5, C_5, C_5, D_5, D_5, D_5, D_5
    snd_len 5
    db Ds5
    snd_hold
    db Ds5
    snd_hold
    db Ds5
    snd_hold
    db Ds5
    snd_hold
    db D_5
    snd_hold
    db Ds5, D_5, C_5
    snd_hold
    db Gs4
    snd_hold
    snd_len 10
    db G_4, G_4, G_4, G_4, Gs4
    snd_hold
    db C_5, C_5, Gs4
    snd_hold
    db C_5, C_5, G_4
    snd_hold
    db Gs4, Gs4
    snd_len 5
    db G_4
    snd_hold
    db G_4
    snd_hold
    db Ds4, D_4, C_4
    snd_hold
    db D_4
    snd_hold
    db D_4
    snd_hold
    db D_4
    snd_hold
    db D_4
    snd_hold
    db Ds4
    snd_hold
    db Ds4
    snd_hold
    db Ds4
    snd_hold
    db Ds4
    snd_hold
    db D_4
    snd_hold
    db Ds4, D_4, C_4
    snd_hold
    db Gs3
    snd_hold
    snd_len 10
    db G_3, G_3, G_3, G_3, D_4, C_4, D_4
    snd_hold
    db G_4, F_4, G_4
    snd_hold
    db G_4, Gs4, G_4, Ds4, D_4, D_4, D_4, D_4
    snd_jump Snd0A_Ch1

Snd0A_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_len 10
    db C_3, G_3, C_3, G_3, C_3, G_3, C_3, G_3, C_3, G_3, C_3, G_3, D_3, G_3, D_3, G_3
    db C_3, G_3, C_3, G_3, C_3, Gs3, C_3, G_3, C_3, F_3, C_3, Ds3, C_3, D_3, C_3, C_3
    db G_3, Gs3, G_3, Ds3
    snd_len 5
    db D_3
    snd_hold
    db Ds3, D_3, C_3
    snd_hold
    db D_3
    snd_hold
    db G_3
    snd_hold
    db Gs3
    snd_hold
    db G_3
    snd_hold
    db Ds3
    snd_hold
    db D_3
    snd_hold
    db Ds3, D_3, C_3
    snd_hold
    db D_3
    snd_hold
    db G_3
    snd_hold
    db G_3
    snd_hold
    db G_3
    snd_hold
    db G_3
    snd_hold
    snd_len 10
    db Gs3, Gs3, Gs3, Gs3, D_4, D_4, D_4, D_4, G_3, Ds3, Gs3, C_4, G_4, G_4, G_4, G_4
    snd_len 5
    db Gs4
    snd_hold
    db Gs4
    snd_hold
    db Gs4
    snd_hold
    db Gs4
    snd_hold
    db G_4
    snd_hold
    db Gs4, G_4, Ds4
    snd_hold
    db D_4
    snd_hold
    snd_len 10
    db C_4, C_4, C_4, C_4, C_4, C_4, Gs4, Gs4, C_4, C_4, Gs4, Gs4, C_4, C_4, C_4, C_4
    db C_4, C_4, C_4, C_4, G_3, G_3, G_3, G_3
    snd_len 5
    db Gs3
    snd_hold
    db Gs3
    snd_hold
    db Gs3
    snd_hold
    db Gs3
    snd_hold
    db G_3
    snd_hold
    db Gs3, G_3, Ds3
    snd_hold
    db D_3
    snd_hold
    snd_len 10
    db Ds3, Ds3, Ds3, Ds3, D_3, C_3, D_3, D_3, G_3, F_3, G_3, G_3, G_3, Gs3, G_3, Ds3
    db D_3, D_3, D_3, D_3
    snd_jump Snd0A_Ch2

Snd0A_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_wave $10
    snd_env $20
    snd_duty $E0
    snd_pan $FB
    snd_len 20
    db C_5, C_5, C_5, C_5, C_5, C_5, D_5, D_5, C_5, C_5, C_5, C_5, C_5, C_5
    snd_len 10
    db D_5
    snd_hold
    db D_5
    snd_hold
    db G_5, G_5, G_5
    snd_hold
    db G_5, G_5, G_5
    snd_hold
    db G_5, G_5, G_5
    snd_hold
    db G_5, G_5, G_5
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_len 40
    snd_hold
    snd_hold
    snd_pan $BF
    snd_len 20
    snd_hold
    snd_hold
    db D_5, D_5
    snd_len 10
    db Ds5, Ds5, Ds5, Ds5, D_5
    snd_hold
    db D_5
    snd_hold
    db C_5, C_5, C_5, C_5, C_5
    snd_hold
    db Gs4, Gs4, C_5
    snd_hold
    db Gs4, Gs4, G_4
    snd_hold
    db Ds4, Ds4, G_4
    snd_hold
    db Ds4, Ds4, D_5
    snd_hold
    db G_5, G_5, Ds5
    snd_hold
    db Gs5, Gs5, D_5
    snd_hold
    db C_5, C_5, Gs5, G_5, Ds5, D_5
    snd_pan $FB
    db D_5, C_5, D_5
    snd_hold
    snd_pan $BF
    db G_5, F_5, G_5
    snd_hold
    snd_pan $FF
    db G_5, Gs5, G_5, Ds5, D_5, D_5, D_5, D_5
    snd_jump Snd0A_Ch3

Snd09_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_pan $DB
    snd_jump SndSub_4B13

Snd09_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_jump SndSub_4B6B

Snd09_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_wave $10
    snd_env $20
    snd_duty $E0
    snd_jump SndSub_4BC6

Snd03_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_pan $DB
    snd_call SndSub_4B13
    snd_call SndSub_4B35
    snd_call SndSub_4B35
    snd_jump Snd03_Ch1

SndSub_4B13:
    snd_len 10
    db C_3
    snd_hold
    db C_3, C_3
    snd_hold
    db C_3, C_3, C_3, D_3, D_3, D_3, D_3, C_3, C_3, C_3, C_3, F_3, F_3, F_3, F_3, G_3
    db G_3, G_3, G_3, D_3, D_3, D_3, D_3, D_3, C_3, D_3, F_3
    snd_ret

SndSub_4B35:
    snd_len 5
    db C_5, D_5
    snd_hold
    snd_hold
    db C_3, D_3, C_3
    snd_hold
    db C_5, D_5
    snd_hold
    snd_hold
    db C_3, D_3, C_3
    snd_hold
    db C_5, D_5
    snd_hold
    snd_hold
    db C_3, D_3, C_3
    snd_hold
    db C_5, D_5
    snd_hold
    snd_hold
    db C_3, D_3, C_3
    snd_hold
    snd_ret

Snd03_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_call SndSub_4B6B
    snd_call SndSub_4BA0
    snd_duty $80
    snd_call SndSub_4BA0
    snd_jump Snd03_Ch2

SndSub_4B6B:
    snd_len 5
    db C_4
    snd_hold
    snd_hold
    snd_hold
    db A_4
    snd_hold
    db A_4
    snd_hold
    db C_5
    snd_hold
    snd_hold
    snd_hold
    db D_5, Cs5, C_5
    snd_hold
    snd_len 10
    db A_4, A_4, A_4, A_4, G_4, F_4, D_4, C_4
    snd_len 5
    db D_4
    snd_hold
    snd_hold
    snd_hold
    db F_4
    snd_hold
    db D_4
    snd_hold
    db D_4
    snd_hold
    db D_4
    snd_hold
    db G_4, Fs4, F_4
    snd_hold
    snd_len 10
    db D_4
    snd_hold
    db D_4, C_4, D_4
    snd_hold
    snd_hold
    snd_hold
    snd_ret

SndSub_4BA0:
    snd_len 10
    db C_5, A_4, G_4, F_4, C_5, A_4, G_4, F_4, A_4, G_4, F_4, D_4, A_4, G_4, F_4, D_4
    snd_ret

Snd03_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_wave $10
    snd_env $20
    snd_duty $E0
    snd_call SndSub_4BC6
    snd_call SndSub_4BE8
    snd_call SndSub_4BE8
    snd_jump Snd03_Ch3

SndSub_4BC6:
    snd_len 10
    db C_5, C_5, C_5, C_5, C_5, C_5, C_5, C_5, D_4, A_4, G_4, F_4, C_5, G_4, F_4, C_4
    db F_5, F_4, F_5, F_4, G_5, G_4, G_5, G_4, D_5, D_4, D_5, D_4, D_5, D_4, D_5, D_4
    snd_ret

SndSub_4BE8:
    snd_len 20
    db A_5, G_5, A_5, D_6, A_5, G_5, F_5, D_5
    snd_ret

Snd02_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_len 10
    snd_pan $DB
    snd_call SndSub_4C23
    snd_duty $80
    snd_pan $BD
    snd_call SndSub_4C23
    snd_duty $00
    snd_pan $DB
    snd_call SndSub_4C44
    snd_pan $BD
    snd_call SndSub_4C44
    snd_duty $20
    snd_call SndSub_4C65
    snd_duty $40
    snd_call SndSub_4C90
    snd_duty $00
    snd_call SndSub_4C90
    snd_jump Snd02_Ch1

SndSub_4C23:
    db G_3, G_4, D_3, D_4, G_3, G_4, D_3, D_4, G_3, G_4, D_3, D_4, G_3, G_4, D_3, D_4
    db F_3, F_4, C_3, C_4, F_3, F_4, C_3, C_4, F_3, F_4, C_3, C_4, F_3, F_4, C_3, C_4
    snd_ret

SndSub_4C44:
    db D_3, D_3, D_3, D_4, D_3, D_3, D_3, D_4, D_3, D_3, D_3, D_4, D_3, D_3, D_3, D_4
    db F_3
    snd_hold
    snd_hold
    db C_4, F_3
    snd_hold
    snd_hold
    db C_4, F_3
    snd_hold
    snd_hold
    db C_4, F_3
    snd_hold
    snd_hold
    db C_4
    snd_ret

SndSub_4C65:
    snd_pan $F9
    db D_4, C_5, D_5, C_5
    snd_pan $F9
    db D_4, D_5, D_5, D_5
    snd_pan $F9
    db D_4, C_5, D_5, C_5
    snd_pan $F9
    db D_4, D_5, D_5, D_5
    snd_pan $FF
    db C_4, D_4, D_5, D_4, C_4, D_4, D_5, D_4, D_4, D_5, D_5, D_5, D_5, D_5, D_5, D_5
    snd_ret

SndSub_4C90:
    snd_pan $FF
    db F_2, F_3, F_2, F_3, F_2, F_3, F_2, F_3, F_2, F_3, F_2, F_3, F_2, F_3, F_2, F_3
    db D_3, D_4, D_3, D_4, D_3, D_4, D_3, D_4, D_3, D_4, D_3, D_4, D_3, D_4, D_3, D_4
    snd_ret

Snd02_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_env $D1
    snd_call SndSub_4CCF
    snd_call SndSub_4CCF
    snd_call SndSub_4D04
    snd_call SndSub_4D04
    snd_call SndSub_4D37
    snd_call SndSub_4D57
    snd_call SndSub_4D57
    snd_jump Snd02_Ch2

SndSub_4CCF:
    snd_duty $00
    snd_len 10
    db G_3
    snd_hold
    db G_3
    snd_hold
    db F_4, G_4, C_4, D_4, F_4, G_4, C_4, D_4, G_4, G_4, G_4, G_4
    snd_len 5
    db C_5, C_5, C_5
    snd_hold
    db As4, As4, As4
    snd_hold
    db C_5, C_5, C_5
    snd_hold
    db G_5, G_5, G_5
    snd_hold
    db C_6, C_6, C_6
    snd_hold
    db As5, As5, As5
    snd_hold
    db G_5, G_5, G_5
    snd_hold
    db C_5, C_5, C_5
    snd_hold
    snd_ret

SndSub_4D04:
    snd_len 5
    db D_5
    snd_hold
    db As4
    snd_hold
    db A_4
    snd_hold
    db G_4
    snd_hold
    db A_4
    snd_hold
    db G_4, As4, A_4
    snd_hold
    snd_hold
    snd_hold
    db D_5
    snd_hold
    db As4
    snd_hold
    db A_4
    snd_hold
    db G_4
    snd_hold
    db A_4
    snd_hold
    db G_4, As4, A_4
    snd_hold
    snd_hold
    snd_hold
    snd_len 10
    db C_4, As3, C_4, Cs4, F_4, Gs4, G_4, F_4, C_4, As3, C_4, Cs4, F_4, Gs4, G_4, F_4
    snd_ret

SndSub_4D37:
    snd_len 10
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db A_4, A_4, A_4
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db A_4, A_4, A_4
    snd_len 20
    snd_hold
    db A_4
    snd_hold
    db A_4
    snd_len 10
    snd_hold
    db A_4, A_4, A_4, A_4, A_4, A_4, A_4
    snd_ret

SndSub_4D57:
    snd_len 5
    db F_4
    snd_hold
    db F_4
    snd_hold
    db F_4
    snd_hold
    db F_4
    snd_hold
    db G_4
    snd_hold
    db F_4, G_4, F_4
    snd_hold
    db G_4
    snd_hold
    db Gs4
    snd_hold
    db Gs4
    snd_hold
    db Gs4
    snd_hold
    db Gs4
    snd_hold
    db G_4
    snd_hold
    db F_4, G_4, F_4
    snd_hold
    db G_4
    snd_hold
    snd_duty $40
    db D_4
    snd_hold
    db G_4
    snd_hold
    db Gs4
    snd_hold
    db C_5
    snd_hold
    db G_4
    snd_hold
    db Ds4, D_4
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db D_4
    snd_hold
    db G_4
    snd_hold
    db Gs4
    snd_hold
    db C_5
    snd_hold
    db G_4
    snd_hold
    db Ds4, D_4, C_4
    snd_hold
    snd_hold
    snd_hold
    snd_ret

Snd02_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_wave $10
    snd_env $20
    snd_call SndSub_4DB9
    snd_call SndSub_4DB9
    snd_call SndSub_4DCC
    snd_call SndSub_4DCC
    snd_call SndSub_4DE7
    snd_call SndSub_4E0D
    snd_call SndSub_4E0D
    snd_jump Snd02_Ch3

SndSub_4DB9:
    snd_duty $B0
    snd_len 20
    db G_3, As3, G_3, As3, G_4, As3, G_4, As3
    snd_len 40
    snd_duty $80
    db C_5
    snd_hold
    db C_5
    snd_hold
    snd_ret

SndSub_4DCC:
    snd_len 40
    snd_duty $60
    db D_5
    snd_hold
    db D_5
    snd_hold
    snd_duty $E0
    snd_len 10
    db C_4, As3, C_4, Cs4, F_4, Gs4, G_4, F_4, C_4, As3, C_4, Cs4, F_4, Gs4, G_4, F_4
    snd_ret

SndSub_4DE7:
    snd_len 10
    snd_duty $E0
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db D_4, G_5, G_5, G_5
    snd_hold
    snd_hold
    snd_hold
    snd_hold
    db D_4, G_5, G_5, G_5
    snd_duty $C0
    snd_len 20
    snd_hold
    db G_5
    snd_hold
    db G_5
    snd_len 10
    snd_duty $E0
    snd_hold
    db G_5, G_5, G_5, G_5, G_5, G_5, G_5
    snd_ret

SndSub_4E0D:
    snd_len 20
    snd_duty $B0
    db F_4, F_4, G_4, G_4, Gs4, Gs4, G_4, F_4
    snd_len 40
    db D_4
    snd_hold
    db D_4
    snd_hold
    snd_ret

Snd16_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_len 7
    db A_4
    snd_hold
    snd_hold
    snd_hold
    db A_4, A_4, A_4
    snd_hold
    db A_4
    snd_hold
    db C_5
    snd_hold
    db A_4, G_4, D_4
    snd_hold
    snd_len 56
    db F_4
    snd_hold
    snd_len 7
    db D_4
    snd_hold
    db D_4, D_4, D_4
    snd_hold
    db D_4
    snd_hold
    db G_4
    snd_hold
    db E_4
    snd_hold
    db D_4, G_4, D_4, Cs4
    snd_len 56
    db C_4
    snd_hold
    snd_endsong

Snd16_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_len 14
    db C_3, F_3, C_3, F_3, C_3, F_3, C_3, F_3, C_3, F_3, C_3, F_3, C_3, F_3, C_3, F_3
    db D_3, G_3, D_3, G_3, D_3, G_3, D_3, G_3, C_3, C_4, D_3, D_4, E_3, E_4, F_3, F_4
    snd_endsong

Snd16_Ch3:
    snd_wave $10
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_env $20
    snd_duty $E0
    snd_pan $FB
    snd_len 14
    db C_4, C_4, A_4, A_4, C_4, C_4, A_4, A_4, C_4, C_4, A_4, A_4, C_4, C_4, A_4, A_4
    db D_4, D_4, G_4, G_4, D_4, D_4, G_4, G_4
    snd_len 28
    db C_4, D_4, E_4, F_4
    snd_endsong

Snd17_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_len 7
    db C_5
    snd_hold
    db C_5, D_5, C_5
    snd_hold
    db A_4, G_4, A_4
    snd_hold
    db E_4
    snd_hold
    db A_4
    snd_hold
    db C_5
    snd_hold
    db D_5
    snd_hold
    db D_5, C_5, D_5
    snd_hold
    db C_5, D_5, E_5
    snd_hold
    snd_hold
    snd_hold
    db D_5
    snd_hold
    snd_hold
    snd_hold
    db E_5
    snd_hold
    db E_5
    snd_hold
    db E_5
    snd_hold
    db E_5
    snd_hold
    db G_5, Gs5, G_5, Ds5, D_5
    snd_hold
    db Ds5, D_5
    snd_len 14
    db E_5, E_5, E_5, A_4, C_5
    snd_hold
    snd_hold
    snd_hold
    snd_jump Snd17_Ch1

Snd17_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_len 14
    db C_3, E_3, G_3, A_3, C_4, A_3, G_3, C_4, D_3, F_3, A_3, C_4, D_4, C_4, A_3, G_3
    db C_5, C_5, C_5, A_4, D_5, D_5, D_5, A_4, C_5, C_5, C_5, F_4, G_4, C_4, D_4, E_4
    snd_jump Snd17_Ch2

Snd17_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_env $20
    snd_duty $E0
    snd_pan $FB
    snd_len 14
    db C_4, C_4, C_4, C_4, D_4
    snd_hold
    db C_4
    snd_hold
    db D_4, D_4, D_4, D_4, E_4
    snd_hold
    db D_4
    snd_hold
    db C_4, C_4, C_4, C_4, G_4
    snd_hold
    db D_4
    snd_hold
    db E_4, E_4, E_4, E_4, C_4
    snd_hold
    snd_hold
    snd_hold
    snd_jump Snd17_Ch3

Snd18_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_len 14
    db C_4, B_3, As3, A_3, Gs3, G_3, Fs3, F_3
    snd_len 7
    db G_4, F_4, Ds4
    snd_hold
    db E_4, Ds4, D_4
    snd_hold
    db Cs4
    snd_hold
    db As3
    snd_hold
    snd_hold
    snd_hold
    db G_3
    snd_hold
    snd_len 14
    snd_hold
    db F_3
    snd_hold
    db E_3, Ds3, D_3, Cs3, C_3, B_2, As2, A_2, G_2, Fs2, F_2, E_2, Ds2
    snd_jump Snd18_Ch1

Snd18_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_len 14
    db C_3, G_3, C_3, G_3, C_3, G_3, C_3, G_3, C_3, G_3, C_3, G_3, C_3, G_3, C_3, G_3
    db C_3, G_3, C_3, G_3, C_3, G_3, C_3, G_3, C_3, G_3, C_3, Fs3, C_3, Fs3, C_3, Fs3
    snd_jump Snd18_Ch2

Snd18_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_env $20
    snd_duty $E0
    snd_pan $FB
    snd_len 14
    db C_4, C_4, G_4, G_4, C_4, C_4, G_4, G_4, C_4, C_4, G_4, G_4, C_4, C_4, G_4, G_4
    db C_4, C_4, C_4, C_4, C_4, C_4, C_4, C_4
    snd_hold
    db G_4
    snd_hold
    db F_4
    snd_hold
    db E_4
    snd_hold
    db D_4
    snd_jump Snd18_Ch3

Snd19_Ch1:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_len 7
    db G_4
    snd_hold
    db F_4
    snd_hold
    db D_4
    snd_hold
    db C_4
    snd_hold
    db D_4, F_4, G_4, C_5, D_5
    snd_hold
    db F_5
    snd_hold
    db G_5, G_5, G_5, G_5, G_5
    snd_hold
    db G_5
    snd_hold
    db A_5
    snd_hold
    db C_6
    snd_hold
    db D_6
    snd_hold
    snd_hold
    snd_hold
    db C_4
    snd_hold
    db D_4
    snd_hold
    db F_4
    snd_hold
    db G_4
    snd_hold
    db A_4
    snd_hold
    db C_5, D_5, C_5
    snd_hold
    db A_4
    snd_hold
    db G_4
    snd_hold
    db A_4, G_4, F_4
    snd_hold
    db D_4
    snd_hold
    db F_4
    snd_hold
    db F_4
    snd_hold
    db F_4
    snd_hold
    db F_4
    snd_hold
    snd_jump Snd19_Ch1

Snd19_Ch2:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_duty $00
    snd_env $C1
    snd_len 7
    db D_4
    snd_hold
    db C_4
    snd_hold
    db A_3
    snd_hold
    db G_3
    snd_hold
    db A_3, C_4, D_4, F_4, G_4
    snd_hold
    db C_5
    snd_hold
    db D_5, C_5, D_5, C_5, D_5, C_5, D_5, C_5, F_5
    snd_hold
    db G_5
    snd_hold
    db A_5
    snd_hold
    db D_3
    snd_hold
    snd_len 14
    db F_3, G_3, A_3, C_4, D_4, F_4, C_4, A_3, G_3, F_3, D_3, F_3, C_4, C_4, C_4, C_4
    snd_jump Snd19_Ch2

Snd19_Ch3:
    snd_transpose $04 ; notes below sound 4 semitone(s) lower
    snd_env $20
    snd_duty $E0
    snd_pan $FB
    snd_len 14
    db D_5, C_5, D_5, C_5, D_5, C_5, D_5
    snd_hold
    db D_5, C_5, D_5, C_5, D_5, C_5, D_5
    snd_hold
    db D_5, C_5, D_5, C_5, D_5, C_5, D_5, C_5, D_5, C_5, D_5, C_5, D_5, C_5, D_5, C_5
    snd_jump Snd19_Ch3


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
    ld a, [wSndChanOfs]               ; 7BAE: FA 16 C1
    add $10                           ; 7BB1: C6 10

; a = track offset in $DFxx. If track active, bump its frame counter;
; when counter == length, reset it and read events up to the next row.
Snd_UpdateChannel:
    ld [wSndChanOfs], a               ; 7BB3: EA 16 C1
    ld l, a                           ; 7BB6: 6F
    ld h, HIGH(wSndSfxTracks)         ; 7BB7: 26 DF
    ld a, [hl+]                       ; 7BB9: 2A
    cp $00                            ; 7BBA: FE 00
    jp z, Snd_Return                  ; 7BBC: CA E8 7C
    inc [hl]                          ; 7BBF: 34
    ld d, [hl]                        ; 7BC0: 56
    cp d                              ; 7BC1: BA  counter == length?
    jp nz, Snd_Return                 ; 7BC2: C2 E8 7C
    xor a                             ; 7BC5: AF
    ld [hl+], a                       ; 7BC6: 22
    ld c, [hl]                        ; 7BC7: 4E
    inc l                             ; 7BC8: 2C
    ld b, [hl]                        ; 7BC9: 46

; Event loop: $00-$7F note, $80-$8E command (via SndCmdTable),
; $90-$FF set row length (byte - $90) and continue.
Snd_ReadEvent:
    ld a, [bc]                        ; 7BCA: 0A
    inc bc                            ; 7BCB: 03
    cp $80                            ; 7BCC: FE 80
    jp c, Snd_StoreNote               ; 7BCE: DA E7 7B
    cp $90                            ; 7BD1: FE 90
    jp nc, Snd_SetLength              ; 7BD3: D2 FD 7B
    and $0f                           ; 7BD6: E6 0F
    sla a                             ; 7BD8: CB 27
    ld e, a                           ; 7BDA: 5F
    ld d, $00                         ; 7BDB: 16 00
    ld hl, SndCmdTable                ; 7BDD: 21 0A 7C
    add hl, de                        ; 7BE0: 19
    ld a, [hl+]                       ; 7BE1: 2A
    ld h, [hl]                        ; 7BE2: 66
    ld l, a                           ; 7BE3: 6F
    jp hl                             ; 7BE4: E9

; $89: 'hold' row - stored as the note; output skips it so nothing is retriggered
SndCmd_89_Hold:
    ld a, $89                         ; 7BE5: 3E 89
Snd_StoreNote:
    ld e, a                           ; 7BE7: 5F
    ld a, [wSndChanOfs]               ; 7BE8: FA 16 C1
    add $0a                           ; 7BEB: C6 0A
    ld l, a                           ; 7BED: 6F
    ld h, HIGH(wSndSfxTracks)         ; 7BEE: 26 DF
    ld [hl], e                        ; 7BF0: 73
    ld a, [wSndChanOfs]               ; 7BF1: FA 16 C1
    add $02                           ; 7BF4: C6 02
    ld l, a                           ; 7BF6: 6F
    ld h, HIGH(wSndSfxTracks)         ; 7BF7: 26 DF
    ld [hl], c                        ; 7BF9: 71
    inc l                             ; 7BFA: 2C
    ld [hl], b                        ; 7BFB: 70
    ret                               ; 7BFC: C9
Snd_SetLength:
    sub $90                           ; 7BFD: D6 90
    ld e, a                           ; 7BFF: 5F
    ld a, [wSndChanOfs]               ; 7C00: FA 16 C1
    ld l, a                           ; 7C03: 6F
    ld h, HIGH(wSndSfxTracks)         ; 7C04: 26 DF
    ld [hl], e                        ; 7C06: 73
    jp Snd_ReadEvent                  ; 7C07: C3 CA 7B

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
    ld a, [bc]                        ; 7C28: 0A
    inc bc                            ; 7C29: 03
    ld [wSndNR51], a                  ; 7C2A: EA 41 C1  shadow copy
    ldh [rNR51], a                    ; 7C2D: E0 25
    jp Snd_ReadEvent                  ; 7C2F: C3 CA 7B

; $8E xx: NR50 = xx
SndCmd_8E_MasterVol:
    ld a, [bc]                        ; 7C32: 0A
    inc bc                            ; 7C33: 03
    ldh [rNR50], a                    ; 7C34: E0 24
    jp Snd_ReadEvent                  ; 7C36: C3 CA 7B

; $8C xx: NR30 = 0, copy 16 bytes from SndWaveTable+xx to wave RAM
SndCmd_8C_LoadWave:
    xor a                             ; 7C39: AF
    ldh [rNR30], a                    ; 7C3A: E0 1A
    ld h, HIGH(SndWaveTable)          ; 7C3C: 26 7E
    ld a, [bc]                        ; 7C3E: 0A
    inc bc                            ; 7C3F: 03
    ld l, a                           ; 7C40: 6F
    ld de, _AUD3WAVERAM               ; 7C41: 11 30 FF
    call Snd_Copy4                    ; 7C44: CD 53 7C
    call Snd_Copy4                    ; 7C47: CD 53 7C
    call Snd_Copy4                    ; 7C4A: CD 53 7C
    call Snd_Copy4                    ; 7C4D: CD 53 7C
    jp Snd_ReadEvent                  ; 7C50: C3 CA 7B
Snd_Copy4:
    ld a, [hl+]                       ; 7C53: 2A
    ld [de], a                        ; 7C54: 12
    inc e                             ; 7C55: 1C
    ld a, [hl+]                       ; 7C56: 2A
    ld [de], a                        ; 7C57: 12
    inc e                             ; 7C58: 1C
    ld a, [hl+]                       ; 7C59: 2A
    ld [de], a                        ; 7C5A: 12
    inc e                             ; 7C5B: 1C
    ld a, [hl+]                       ; 7C5C: 2A
    ld [de], a                        ; 7C5D: 12
    inc e                             ; 7C5E: 1C
    ret                               ; 7C5F: C9

; $80 xx: track +8 = xx (NR11/NR21 duty+length, NR31 length)
SndCmd_80_Duty:
    ld a, [wSndChanOfs]               ; 7C60: FA 16 C1
    add $08                           ; 7C63: C6 08
    jp Snd_StoreParam                 ; 7C65: C3 7D 7C

; $81 xx: track +7 = xx (NR10 sweep; only used by ch1 output)
SndCmd_81_Sweep:
    ld a, [wSndChanOfs]               ; 7C68: FA 16 C1
    add $07                           ; 7C6B: C6 07
    jp Snd_StoreParam                 ; 7C6D: C3 7D 7C

; $82 xx: track +B = xx (subtracted from note before table lookup)
SndCmd_82_Transpose:
    ld a, [wSndChanOfs]               ; 7C70: FA 16 C1
    add $0b                           ; 7C73: C6 0B
    jp Snd_StoreParam                 ; 7C75: C3 7D 7C

; $83 xx: track +9 = xx (NR12/NR22/NR42 envelope, NR32 volume)
SndCmd_83_Envelope:
    ld a, [wSndChanOfs]               ; 7C78: FA 16 C1
    add $09                           ; 7C7B: C6 09
Snd_StoreParam:
    ld l, a                           ; 7C7D: 6F
    ld h, HIGH(wSndSfxTracks)         ; 7C7E: 26 DF
    ld a, [bc]                        ; 7C80: 0A
    inc bc                            ; 7C81: 03
    ld [hl], a                        ; 7C82: 77
    jp Snd_ReadEvent                  ; 7C83: C3 CA 7B

; $84 xx / $88 xx / $8D xx: unused, parameter skipped
SndCmd_SkipParam:
    ld a, [bc]                        ; 7C86: 0A
    inc bc                            ; 7C87: 03
    jp Snd_ReadEvent                  ; 7C88: C3 CA 7B

; $85 lo hi: one-level call - save return ptr at +4/+5, set +6 = 1, jump
SndCmd_85_Call:
    ld a, [wSndChanOfs]               ; 7C8B: FA 16 C1
    add $04                           ; 7C8E: C6 04
    ld l, a                           ; 7C90: 6F
    ld h, HIGH(wSndSfxTracks)         ; 7C91: 26 DF
    ld a, [bc]                        ; 7C93: 0A
    inc bc                            ; 7C94: 03
    ld e, a                           ; 7C95: 5F
    ld a, [bc]                        ; 7C96: 0A
    inc bc                            ; 7C97: 03
    ld [hl], c                        ; 7C98: 71
    inc l                             ; 7C99: 2C
    ld [hl], b                        ; 7C9A: 70
    inc l                             ; 7C9B: 2C
    ld b, a                           ; 7C9C: 47
    ld c, e                           ; 7C9D: 4B
    ld a, $01                         ; 7C9E: 3E 01
    ld [hl], a                        ; 7CA0: 77
    jp Snd_ReadEvent                  ; 7CA1: C3 CA 7B

; $86: if call flag (+6) set -> clear it and return to +4/+5.
; Otherwise end of song: zero the length byte of all 4 tracks in the
; set being processed (wSndSetFlag: 0 = SFX set $DF00, 1 = music $DF40).
SndCmd_86_Return:
    ld a, [wSndChanOfs]               ; 7CA4: FA 16 C1
    add $06                           ; 7CA7: C6 06
    ld l, a                           ; 7CA9: 6F
    ld h, HIGH(wSndSfxTracks)         ; 7CAA: 26 DF
    ld a, [hl]                        ; 7CAC: 7E
    cp $00                            ; 7CAD: FE 00
    jp z, Snd_EndSong                 ; 7CAF: CA BA 7C
    xor a                             ; 7CB2: AF
    ld [hl-], a                       ; 7CB3: 32
    ld b, [hl]                        ; 7CB4: 46  return address
    dec l                             ; 7CB5: 2D
    ld c, [hl]                        ; 7CB6: 4E
    jp Snd_ReadEvent                  ; 7CB7: C3 CA 7B
Snd_EndSong:
    ld b, $00                         ; 7CBA: 06 00
    ld a, [wSndSetFlag]               ; 7CBC: FA 17 C1
    cp $01                            ; 7CBF: FE 01
    jp z, Snd_EndSong_Music           ; 7CC1: CA D2 7C
    ld hl, wSndSfxTracks              ; 7CC4: 21 00 DF
    ld [hl], b                        ; 7CC7: 70
    ld l, LOW(wSndSfxTracks + $10)    ; 7CC8: 2E 10
    ld [hl], b                        ; 7CCA: 70
    ld l, LOW(wSndSfxTracks + $20)    ; 7CCB: 2E 20
    ld [hl], b                        ; 7CCD: 70
    ld l, LOW(wSndSfxTracks + $30)    ; 7CCE: 2E 30
    ld [hl], b                        ; 7CD0: 70
    ret                               ; 7CD1: C9
Snd_EndSong_Music:
    ld hl, wSndMusicTracks            ; 7CD2: 21 40 DF
    ld [hl], b                        ; 7CD5: 70
    ld l, LOW(wSndSfxTracks + $50)    ; 7CD6: 2E 50
    ld [hl], b                        ; 7CD8: 70
    ld l, LOW(wSndSfxTracks + $60)    ; 7CD9: 2E 60
    ld [hl], b                        ; 7CDB: 70
    ld l, LOW(wSndSfxTracks + $70)    ; 7CDC: 2E 70
    ld [hl], b                        ; 7CDE: 70
    ret                               ; 7CDF: C9

; $87: end this track only (length = 0)
SndCmd_87_EndTrack:
    ld a, [wSndChanOfs]               ; 7CE0: FA 16 C1
    ld l, a                           ; 7CE3: 6F
    ld h, HIGH(wSndSfxTracks)         ; 7CE4: 26 DF
    xor a                             ; 7CE6: AF
    ld [hl], a                        ; 7CE7: 77
Snd_Return:
    ret                               ; 7CE8: C9

; $8B lo hi: jump (used for loops)
SndCmd_8B_Jump:
    ld a, [bc]                        ; 7CE9: 0A
    inc bc                            ; 7CEA: 03
    ld l, a                           ; 7CEB: 6F
    ld a, [bc]                        ; 7CEC: 0A
    inc bc                            ; 7CED: 03
    ld b, a                           ; 7CEE: 47
    ld c, l                           ; 7CEF: 4D
    jp Snd_ReadEvent                  ; 7CF0: C3 CA 7B

    ds $0D, $FF

; ---- SndTable: 4 track pointers (ch1, ch2, ch3, ch4) per sound id -------------
; id 0 is never started (a request of 0 means "nothing pending").
SndTable:
    dw Snd00_Ch1, Snd00_Ch1, Snd00_Ch1, Snd00_Ch1 ; $00
    dw Snd01_Ch1, Snd01_Ch2, Snd01_Ch3, Snd01_Ch4 ; $01
    dw Snd02_Ch1, Snd02_Ch2, Snd02_Ch3, Snd01_Ch4 ; $02
    dw Snd03_Ch1, Snd03_Ch2, Snd03_Ch3, Snd01_Ch4 ; $03
    dw Snd04_Ch1, Snd04_Ch2, Snd04_Ch3, Snd01_Ch4 ; $04
    dw Snd05_Ch1, Snd05_Ch2, Snd05_Ch3, Snd01_Ch4 ; $05
    dw Snd06_Ch1, Snd06_Ch2, Snd06_Ch3, Snd01_Ch4 ; $06
    dw Snd07_Ch1, Snd07_Ch2, Snd07_Ch3, Snd01_Ch4 ; $07
    dw Snd08_Ch1, Snd08_Ch2, Snd08_Ch3, Snd01_Ch4 ; $08
    dw Snd09_Ch1, Snd09_Ch2, Snd09_Ch3, Snd01_Ch4 ; $09
    dw Snd0A_Ch1, Snd0A_Ch2, Snd0A_Ch3, Snd01_Ch4 ; $0A
    dw Snd0B_Ch1, Snd0B_Ch2, Snd0B_Ch1, Snd0B_Ch1 ; $0B
    dw Snd0B_Ch1, Snd0C_Ch2, Snd0B_Ch1, Snd0B_Ch1 ; $0C
    dw Snd0B_Ch1, Snd0D_Ch2, Snd0B_Ch1, Snd0B_Ch1 ; $0D
    dw Snd0B_Ch1, Snd0E_Ch2, Snd0B_Ch1, Snd0B_Ch1 ; $0E
    dw Snd0B_Ch1, Snd0F_Ch2, Snd0B_Ch1, Snd0B_Ch1 ; $0F
    dw Snd0B_Ch1, Snd10_Ch2, Snd0B_Ch1, Snd0B_Ch1 ; $10
    dw Snd11_Ch1, Snd11_Ch2, Snd0B_Ch1, Snd0B_Ch1 ; $11
    dw Snd12_Ch1, Snd12_Ch2, Snd12_Ch3, Snd01_Ch4 ; $12
    dw Snd13_Ch1, Snd13_Ch2, Snd13_Ch3, Snd01_Ch4 ; $13
    dw Snd14_Ch1, Snd14_Ch2, Snd14_Ch3, Snd01_Ch4 ; $14
    dw Snd15_Ch1, Snd15_Ch2, Snd15_Ch3, Snd01_Ch4 ; $15
    dw Snd16_Ch1, Snd16_Ch2, Snd16_Ch3, Snd01_Ch4 ; $16
    dw Snd17_Ch1, Snd17_Ch2, Snd17_Ch3, Snd01_Ch4 ; $17
    dw Snd18_Ch1, Snd18_Ch2, Snd18_Ch3, Snd01_Ch4 ; $18
    dw Snd19_Ch1, Snd19_Ch2, Snd19_Ch3, Snd01_Ch4 ; $19

Snd00_Ch1:
Snd00_Ch2:
Snd00_Ch3:
Snd00_Ch4:
    snd_endsong ; $7DD0 (only reached via id $00, never started)
Snd0B_Ch1:
Snd0B_Ch3:
Snd0B_Ch4:
Snd0C_Ch1:
Snd0C_Ch3:
Snd0C_Ch4:
Snd0D_Ch1:
Snd0D_Ch3:
Snd0D_Ch4:
Snd0E_Ch1:
Snd0E_Ch3:
Snd0E_Ch4:
Snd0F_Ch1:
Snd0F_Ch3:
Snd0F_Ch4:
Snd10_Ch1:
Snd10_Ch3:
Snd10_Ch4:
Snd11_Ch3:
Snd11_Ch4:
    snd_end     ; $7DD1: shared "silent" track for unused channel slots
    ds $2E, $FF

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
