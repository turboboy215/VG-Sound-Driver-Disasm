; ==============================================================================
; Tamtex/Irem sound driver - Shisenshou - Match-Mania (J)
; Disassembly of the sound driver code, tables and all music/SFX data.
; 32 KB ROM-only cartridge: addresses == file offsets (assembled as ROMX bank 1).
; Builds byte-exact with RGBDS:  rgbasm -o ss.o Shisensho_sound.asm ; rgblink -p 0xFF -o ss.gb ss.o
; This is the version closest to the common ancestor of the Lenar driver
; (Mercenary Force, Knight Quest) and Irem's Kid Niki / Hammerin' Harry drivers.
; ==============================================================================

DEF SHISENSHO_NOTES EQU 1   ; note constants: $00 = C3 (48-entry SndFreqTable)
INCLUDE "hardware.inc"
INCLUDE "lenar_sound.inc"

; ---- RAM ----------------------------------------------------------------------
; Two sets of 4 tracks, $10 bytes each (one track per hardware channel):
;   wSndSfxTracks   $DF00-$DF3F  (priority set)
;   wSndMusicTracks $DF40-$DF7F
; Track layout: +0 row length (0 = idle)  +1 frame counter  +2/+3 data pointer
;   +4/+5 return pointer  +6 call flag  +7 NR10 sweep  +8 duty/length (NRx1)
;   +9 envelope/volume (NRx2)  +A current note  +B transpose (added)  +C..+F unused
DEF wSndSfxTracks   EQU $DF00
DEF wSndMusicTracks EQU $DF40
DEF wSndReqSfx      EQU $DF0E  ; SndTable id to start in the SFX set ($FF = none)
DEF wSndReqMusic    EQU $DF1E  ; SndTable id to start in the music set ($FF = none)
DEF wSndChanOfs     EQU $DF90  ; offset ($00-$70) of the track being updated
DEF wSndSetFlag     EQU $DF91  ; 0 while updating SFX set, 1 while updating music set

SECTION "Shisensho Sound Data", ROMX[$7460], BANK[1]
; ---- music / SFX data (part 1) ------------------------------------------------

Snd05_Ch1:
    snd_duty $00
    snd_env $8C
    snd_transpose $00
    snd_len 15
    db G_3, A_3, B_3, D_4, E_4, G_4, A_4, B_4, D_5
    snd_env $10
    db D_5
    snd_env $8C
    db B_4, A_4, B_4
    snd_env $10
    db B_4
    snd_env $8C
    db D_5
    snd_env $10
    db D_5
    snd_env $8C
    db E_5, G_5, E_5, D_5, B_4, D_5, B_4, A_4, G_4, A_4, G_4, E_4
    snd_len 30
    db G_4
    snd_env $16
    db G_4
    snd_endsong

Snd05_Ch2:
    snd_pan $FE
    snd_duty $00
    snd_env $8C
    snd_transpose $05 ; notes below sound 5 semitone(s) higher
    snd_len 15
    db G_3, A_3, B_3, D_4, E_4, G_4, A_4, B_4, D_5
    snd_env $10
    db D_5
    snd_env $8C
    snd_len 5
    db B_4, D_5, B_4
    snd_len 15
    db A_4, B_4
    snd_env $10
    db B_4
    snd_env $8C
    db D_5
    snd_env $10
    db D_5
    snd_env $8C
    db E_5, G_5
    snd_len 5
    db E_5, G_5, E_5
    snd_len 15
    db D_5, B_4, D_5
    snd_len 5
    db B_4, D_5, B_4
    snd_len 15
    db A_4, G_4, A_4
    snd_len 5
    db G_4, A_4, G_4
    snd_len 15
    db E_4
    snd_len 30
    db G_4
    snd_env $16
    db G_4
    snd_endsong

Snd05_Ch3:
    snd_transpose $0C ; notes below sound 12 semitone(s) higher
    snd_wave $00
    snd_env $20
    snd_duty $00
    snd_len 30
    db C_3, C_3, E_3, G_3, E_3, E_3, G_3, B_3
    snd_len 60
    db A_3, G_3
    snd_len 15
    db E_3, G_3, E_3, D_3
    snd_len 60
    snd_duty $70
    db C_3
    snd_endsong

Snd07_Ch1:
    snd_transpose $0C ; notes below sound 12 semitone(s) higher

SndLoop_74FC:
    snd_duty $00
    snd_env $F1
    snd_call SndSub_751C
    db G_4, G_4, E_4, G_4, E_4, D_4, E_4, D_4
    snd_len 14
    db B_3, A_3
    snd_hold
    snd_call SndSub_751C
    db D_4, D_4
    snd_len 14
    db Ds4, D_4
    snd_hold
    db Fs4, G_4
    snd_hold
    snd_endsong

SndSub_751C:
    snd_len 7
    db D_4
    snd_hold
    db D_4, D_4
    snd_len 14
    db B_3, D_4, E_4
    snd_duty $80
    db E_4, E_4
    snd_duty $00
    snd_len 7
    db D_4, E_4, G_4
    snd_hold
    db G_4, G_4
    snd_len 14
    db E_4, G_4, A_4
    snd_duty $80
    db A_4, A_4
    snd_duty $00
    snd_len 7
    db G_4, A_4, B_4
    snd_hold
    db B_4, B_4
    snd_len 14
    db A_4, G_4, A_4
    snd_len 7
    db A_4, A_4
    snd_len 14
    db G_4, E_4, G_4
    snd_len 7
    snd_ret

Snd07_Ch2:
    snd_transpose $11 ; notes below sound 17 semitone(s) higher
    snd_jump SndLoop_74FC

Snd07_Ch3:
    snd_env $20
    snd_wave $00
    snd_transpose $0C ; notes below sound 12 semitone(s) higher
    snd_duty $A0
    snd_call SndSub_7574
    snd_len 56
    db E_3
    snd_len 42
    snd_hold
    snd_len 7
    db D_3, E_3
    snd_call SndSub_7574
    snd_len 56
    db E_3
    snd_duty $D0
    snd_len 14
    snd_hold
    db D_3, C_3
    snd_hold
    snd_endsong

SndSub_7574:
    snd_len 56
    db G_3
    snd_len 7
    db A_3, C_4, A_3, G_3, A_3, G_3, E_3, D_3
    snd_len 56
    db C_3
    snd_len 7
    db D_3, E_3, D_3, C_3, D_3, E_3, G_3, A_3
    snd_len 42
    db G_3
    snd_len 7
    db E_3, G_3
    snd_len 42
    db F_3
    snd_len 7
    db A_3, G_3
    snd_ret

Snd07_Ch4:
    snd_call SndSub_75A8
    db $03
    snd_pan $FE
    db $03, $03
    snd_hold
    snd_call SndSub_75A8
    snd_hold
    snd_pan $FE
    db $03, $03
    snd_hold
    snd_endsong

SndSub_75A8:
    snd_pan $7E
    snd_env $D1
    snd_len 7
    db $03
    snd_hold
    db $01, $01
    snd_len 14
    db $03, $01, $03
    snd_pan $CF
    db $03, $03
    snd_pan $7E
    snd_len 7
    db $02, $02, $03
    snd_hold
    db $01, $01
    snd_len 14
    db $03, $01, $03
    snd_pan $CF
    db $03, $03
    snd_pan $7E
    snd_len 7
    db $02, $02
    snd_len 14
    snd_env $D2
    db $03
    snd_hold
    snd_hold
    snd_env $D1
    db $03
    snd_env $D2
    db $03
    snd_hold
    snd_hold
    snd_env $D1
    db $03, $03
    snd_len 7
    db $01, $01
    snd_len 14
    db $03, $01
    snd_ret

Snd06_Ch1:
    snd_transpose $07 ; notes below sound 7 semitone(s) higher
    snd_duty $00
    snd_env $8C
    snd_pan $FF
    snd_len 60
    db A_3, G_3
    snd_pan $FE
    snd_len 15
    db G_4, A_4, E_4, G_4, D_4, E_4, B_3, D_4
    snd_pan $FF
    snd_env $C1
    db A_3, G_3, A_3, B_3, B_3, A_3, B_3, D_4, E_4
    snd_hold
    snd_pan $FE
    snd_env $8C

SndLoop_7610:
    snd_len 3
    db Ds4, D_4, Cs4, C_4, B_3, As3, A_3, Gs3, G_3, Fs3, F_3
    snd_len 12
    db E_3
    snd_len 15
    snd_hold
    snd_env $10
    db E_3
    snd_env $00
    db E_3
    snd_endsong

Snd06_Ch2:
    snd_transpose $07 ; notes below sound 7 semitone(s) higher
    snd_duty $00
    snd_env $8C
    snd_len 15
    db A_5, C_6, G_5, A_5, E_5, G_5, D_5, E_5
    snd_transpose $0C ; notes below sound 12 semitone(s) higher
    db G_4, A_4, E_4, G_4, D_4, E_4, B_3, D_4, A_3
    snd_hold
    snd_hold
    db B_3, D_4
    snd_hold
    db B_3, D_4, E_4
    snd_hold
    snd_jump SndLoop_7610

Snd06_Ch3:
    snd_transpose $07 ; notes below sound 7 semitone(s) higher
    snd_wave $00
    snd_env $20
    snd_duty $00
    snd_len 60
    db E_4, D_4, C_4, D_4, F_4, G_4
    snd_duty $C0
    snd_len 15
    db A_4
    snd_hold
    snd_duty $D0
    db A_3, G_3
    snd_duty $40
    snd_len 60
    db A_3
    snd_endsong

Snd02_Ch1:
    snd_transpose $07 ; notes below sound 7 semitone(s) higher

SndLoop_766C:
    snd_duty $00
    snd_env $F4
    snd_len 16
    db E_4, D_4, E_4, G_4
    snd_len 32
    db A_4, G_4, E_4
    snd_len 16
    db D_4, E_4
    snd_len 32
    db B_3
    snd_hold
    db A_3
    snd_len 16
    db G_3, A_3, B_3, D_4, B_3
    snd_len 8
    snd_hold
    db G_3
    snd_len 32
    db A_3, G_3, E_3
    snd_hold
    db D_3
    snd_len 16
    db E_3, G_3
    snd_len 32
    db A_3
    snd_hold
    db G_3
    snd_len 16
    db A_3, B_3
    snd_len 64
    db D_4
    snd_len 16
    db B_3, D_4, A_3, B_3, G_3, A_3, E_3
    snd_len 8
    snd_hold
    db G_3
    snd_len 64
    db D_3, E_3
    snd_jump SndLoop_766C

Snd02_Ch2:
    snd_transpose $0C ; notes below sound 12 semitone(s) higher
    snd_jump SndLoop_766C

Snd02_Ch3:
    snd_transpose $00
    snd_wave $00
    snd_env $20

SndLoop_76B7:
    snd_duty $00
    snd_len 64
    db E_3, D_3, E_3, D_3, C_3, D_3
    snd_len 32
    db E_3, E_3, E_3
    snd_len 16
    db G_3, B_3
    snd_len 32
    db Fs3, G_3, C_3
    snd_hold
    db B_3, C_4, D_3
    snd_hold
    db D_4, C_4, B_3
    snd_len 16
    db A_3, G_3
    snd_len 32
    db Fs3, D_3, E_3
    snd_hold
    snd_jump SndLoop_76B7

Snd02_Ch4:
    snd_pan $FE
    snd_env $D4
    snd_len 64
    db $33
    snd_hold
    db $33
    snd_hold
    db $33
    snd_hold
    db $33
    snd_hold
    snd_pan $7E
    snd_len 16
    snd_env $A1
    db $02
    snd_hold
    db $02, $01, $02
    snd_hold
    snd_pan $F6
    snd_env $D1
    db $04, $04
    snd_pan $7E
    snd_env $A1
    db $02
    snd_hold
    db $02, $01, $02
    snd_pan $F6
    snd_env $D1
    db $03, $03, $03
    snd_env $D4
    snd_len 64
    snd_hold
    snd_hold
    snd_pan $FE
    db $33, $33
    snd_jump Snd02_Ch4

Snd04_Ch1:
    snd_transpose $13 ; notes below sound 19 semitone(s) higher
    snd_pan $FE

SndLoop_771C:
    snd_env $6E
    snd_duty $00
    snd_len 24
    snd_call SndSub_7768
    db D_4, C_4, A_3
    snd_hold
    db G_3
    snd_hold
    db A_3, C_4, G_3
    snd_hold
    db A_3
    snd_hold
    snd_hold
    snd_env $10
    db A_3
    snd_env $6E
    snd_duty $80
    snd_call SndSub_7768
    db G_4, E_4
    snd_len 48
    db D_4, A_3, C_4
    snd_hold
    snd_hold
    snd_env $10
    db C_4
    snd_env $6E
    snd_len 24
    snd_duty $00
    snd_call SndSub_777B
    db G_3, A_3, C_4, D_4, E_4, G_4, D_4, C_4
    snd_duty $80
    snd_call SndSub_777B
    db G_4
    snd_hold
    db E_4, A_4, G_4
    snd_hold
    snd_hold
    snd_env $10
    db G_4
    snd_jump SndLoop_771C

SndSub_7768:
    db E_3
    snd_hold
    db G_3
    snd_hold
    db A_3, C_4, G_3
    snd_hold
    db E_3
    snd_hold
    db G_3, A_3, C_4, D_4, E_4
    snd_hold
    db D_4, E_4
    snd_ret

SndSub_777B:
    db D_4
    snd_hold
    db C_4, E_4, D_4, C_4, A_3
    snd_hold
    db C_4
    snd_hold
    db A_3, G_3, A_3, C_4, D_4, E_4, D_4
    snd_hold
    db C_4, E_4, D_4, C_4, A_3
    snd_hold
    snd_ret

Snd04_Ch2:
    snd_transpose $18 ; notes below sound 24 semitone(s) higher
    snd_jump SndLoop_771C

Snd04_Ch3:
    snd_transpose $0C ; notes below sound 12 semitone(s) higher
    snd_wave $00
    snd_env $20

SndLoop_779F:
    snd_len 48
    snd_call SndSub_77DE
    db B_3, C_4
    snd_duty $83
    db C_4
    snd_call SndSub_77DE
    db C_4, C_3
    snd_duty $83
    db C_3
    snd_duty $00
    db F_3, F_3, G_3, G_3, A_3, A_3, G_3, G_3, F_3, F_3, G_3, G_3, E_3, A_3, C_4, E_4
    db F_4, F_4, G_4, G_4, A_4, A_4, G_4, G_4, F_4
    snd_len 24
    db E_4, G_4, F_4, E_4, C_4, C_4, G_3, G_3, E_3, A_3
    snd_len 48
    db G_3
    snd_duty $83
    db G_3
    snd_jump SndLoop_779F

SndSub_77DE:
    snd_duty $00
    db C_4, B_3, A_3, B_3, C_4, B_3, A_3, G_3, F_3, F_3, G_3, B_3, C_4
    snd_ret

Snd03_Ch1:
    snd_transpose $00
    snd_duty $00
    snd_env $D1
    snd_len 32
    snd_hold
    snd_call SndSub_7850
    snd_call SndSub_786B
    snd_call SndSub_784B
    snd_call SndSub_786B
    snd_len 64
    db C_4
    snd_call SndSub_7850
    snd_call SndSub_786B
    snd_call SndSub_784B
    snd_len 16
    snd_env $D4
    db F_3
    snd_hold
    snd_hold
    snd_env $D1
    db F_3
    snd_env $D4
    db G_3
    snd_len 32
    snd_hold
    snd_env $D1
    db G_3
    snd_len 8
    db G_3, G_3
    snd_len 16
    snd_hold
    db G_3
    snd_len 32
    db G_3
    snd_duty $00
    snd_env $E1
    snd_call SndSub_7932
    snd_duty $80
    snd_env $6C
    snd_call SndSub_78BE
    snd_len 32
    snd_call SndSub_7882
    snd_call SndSub_7882
    snd_call SndSub_7882
    snd_call SndSub_7882
    snd_duty $00
    snd_env $E1
    snd_len 16
    db G_4, G_4
    snd_jump Snd03_Ch1

SndSub_784B:
    snd_len 16
    snd_hold
    db G_3
    snd_hold
    db G_3

SndSub_7850:
    snd_len 8
    snd_hold
    snd_hold
    db F_3, F_3
    snd_len 16
    snd_hold
    db F_3
    snd_hold
    snd_len 8
    db G_3, G_3
    snd_len 16
    snd_hold
    db G_3
    snd_hold
    snd_len 8
    db A_3, A_3
    snd_len 16
    snd_hold
    db A_3
    snd_hold
    db A_3
    snd_hold
    db G_3
    snd_ret

SndSub_786B:
    snd_len 8
    snd_hold
    snd_hold
    db F_3, F_3
    snd_len 16
    snd_hold
    db F_3
    snd_hold
    snd_len 8
    db G_3, G_3
    snd_len 16
    snd_hold
    db G_3
    snd_hold
    snd_len 8
    db C_4, C_4
    snd_len 16
    snd_hold
    db C_4
    snd_ret

SndSub_7882:
    snd_env $6C
    snd_hold
    snd_len 32
    db G_4, A_4, B_4
    snd_env $E4
    db B_4
    snd_len 64
    snd_hold
    snd_ret

Snd03_Ch2:
    snd_transpose $05 ; notes below sound 5 semitone(s) higher
    snd_pan $FE
    snd_call SndSub_78BE
    snd_call SndSub_78BE
    snd_pan $DE
    snd_duty $00
    snd_env $F1
    snd_call SndSub_7932
    snd_pan $FE
    snd_duty $80
    snd_env $8C
    snd_call SndSub_78BE
    snd_len 32
    snd_hold
    snd_call SndSub_796D
    db G_4
    snd_len 8
    db E_4, D_4
    snd_len 32
    db E_4
    snd_call SndSub_796D
    db G_4, G_4
    snd_jump Snd03_Ch2

SndSub_78BE:
    snd_duty $80
    snd_env $8C
    snd_len 16
    db E_4, G_4, A_4
    snd_hold
    snd_hold
    db B_4, A_4
    snd_len 8
    snd_hold
    db B_4, A_4, G_4, E_4
    snd_hold
    snd_len 32
    db G_4
    snd_hold
    snd_env $10
    db G_4
    snd_env $8C
    snd_len 16
    db E_4, G_4, A_4
    snd_hold
    db B_4, D_5
    snd_len 8
    db E_5
    snd_env $10
    db E_5
    snd_env $8C
    db D_5
    snd_env $10
    db D_5
    snd_env $8C
    db A_4, B_4, D_5
    snd_hold
    snd_len 64
    db B_4
    snd_len 16
    db A_4
    snd_env $10
    db A_4
    snd_env $8C
    db E_4, G_4, A_4
    snd_hold
    snd_hold
    db B_4, A_4
    snd_len 8
    snd_hold
    db B_4, A_4, G_4, E_4
    snd_hold
    snd_len 32
    db G_4
    snd_hold
    snd_env $10
    db G_4
    snd_env $8C
    snd_len 16
    db E_4, G_4, A_4
    snd_len 8
    db G_4, A_4, D_5
    snd_env $10
    db D_5
    snd_env $8C
    db B_4
    snd_env $10
    db B_4
    snd_env $8C
    db A_4, B_4, A_4, G_4, E_4, D_4, E_4
    snd_hold
    snd_len 32
    db G_4
    snd_hold
    snd_env $10
    db G_4
    snd_ret

SndSub_7932:
    snd_len 16
    db G_5, G_5
    snd_len 8
    db E_5, E_5, D_5, D_5, B_4, A_4, B_4
    snd_hold
    db D_5
    snd_hold
    db B_4, E_5, D_5
    snd_hold
    db D_5
    snd_hold
    db E_5, E_5, D_5, D_5, B_4, A_4, B_4, E_5
    snd_len 32
    db D_5, D_5
    snd_len 8
    db E_5, E_5, D_5, D_5, B_4, A_4, B_4
    snd_hold
    db D_5
    snd_hold
    db B_4, E_5, D_5
    snd_hold
    db D_5
    snd_hold
    db B_4, A_4, B_4, D_5, E_5, D_5, B_4
    snd_hold
    snd_len 32
    db A_4
    snd_ret

SndSub_796D:
    snd_duty $80
    snd_env $8C
    snd_len 32
    db G_4, A_4, B_4
    snd_env $E4
    db B_4
    snd_duty $00
    snd_env $F1
    snd_len 8
    snd_hold
    snd_hold
    db A_4, B_4, A_4, G_4, E_4
    snd_hold
    db A_4, B_4, A_4, G_4, E_4
    snd_hold
    db D_4, E_4
    snd_duty $80
    snd_env $8C
    snd_len 32
    db G_4, A_4, B_4
    snd_env $E4
    db B_4
    snd_duty $00
    snd_env $F1
    snd_len 8
    snd_hold
    snd_hold
    db A_4, B_4, A_4, G_4
    snd_len 16
    db E_4
    snd_ret

Snd03_Ch3:
    snd_transpose $00
    snd_wave $00
    snd_env $20

SndLoop_79AC:
    snd_len 32
    snd_hold
    snd_call SndSub_7A2F
    snd_call SndSub_7A4B
    snd_call SndSub_7A2F
    snd_call SndSub_7A6B
    snd_call SndSub_7A4B
    snd_call SndSub_7A2F
    snd_call SndSub_7A8D
    snd_call SndSub_7A4B
    snd_call SndSub_7A2F
    snd_call SndSub_7A6B
    snd_call SndSub_7A4B
    snd_call SndSub_7AA8
    snd_len 32
    snd_duty $01
    snd_len 64
    db A_3, G_3, E_3
    snd_len 8
    db E_5, D_5, E_5, G_5, E_5, D_5, E_5, G_5
    snd_len 64
    db A_3, G_3, C_3
    snd_duty $A9
    snd_len 16
    db D_3
    snd_hold
    db A_3, G_3
    snd_call SndSub_7A2F
    snd_call SndSub_7A4B
    snd_call SndSub_7A2F
    snd_call SndSub_7A6B
    snd_call SndSub_7A4B
    snd_call SndSub_7AA8
    snd_call SndSub_7AC5
    db G_3
    snd_duty $E1
    db D_4
    snd_duty $90
    db G_3
    snd_duty $E1
    db D_4
    snd_call SndSub_7AC5
    db A_3
    snd_duty $E1
    db E_4
    snd_duty $90
    db A_3, B_3
    snd_call SndSub_7AC5
    db G_3
    snd_duty $E1
    db D_4
    snd_duty $90
    db G_3
    snd_duty $E1
    db D_4
    snd_call SndSub_7AC5
    snd_duty $D0
    snd_len 16
    db C_3, C_3
    snd_jump SndLoop_79AC

SndSub_7A2F:
    snd_len 8
    snd_duty $90
    db F_3
    snd_hold
    snd_duty $F1
    db C_5, C_5
    snd_len 16
    snd_duty $90
    db C_3
    snd_duty $F1
    db C_5
    snd_duty $90
    db G_3
    snd_len 8
    snd_duty $F1
    db D_5, D_5
    snd_len 16
    snd_duty $90
    snd_ret

SndSub_7A4B:
    db D_3
    snd_duty $F1
    db D_5
    snd_duty $90
    db A_3
    snd_len 8
    snd_duty $F1
    db E_5, E_5
    snd_len 16
    snd_duty $90
    db E_3
    snd_duty $F1
    db E_5
    snd_duty $90
    db A_3
    snd_duty $F1
    db E_5
    snd_duty $90
    db G_3
    snd_duty $F1
    db D_5
    snd_ret

SndSub_7A6B:
    db D_3
    snd_duty $F1
    db D_5
    snd_duty $90
    db C_3
    snd_len 8
    snd_duty $F1
    db G_5, G_5
    snd_len 16
    snd_duty $90
    db C_4
    snd_duty $F1
    db G_5
    snd_duty $90
    db G_3
    snd_duty $F1
    db D_5
    snd_duty $90
    db G_3
    snd_duty $F1
    db D_5
    snd_jump SndSub_7A2F

SndSub_7A8D:
    db G_3
    snd_duty $F1
    db D_5
    snd_duty $90
    db C_3
    snd_len 8
    snd_duty $F1
    db G_5, G_5
    snd_duty $90
    db C_4
    snd_duty $F1
    db G_5, G_5
    snd_hold
    snd_duty $90
    snd_len 64
    db C_3
    snd_jump SndSub_7A2F

SndSub_7AA8:
    snd_len 16
    snd_duty $90
    db F_3
    snd_hold
    snd_hold
    db F_3, G_3
    snd_hold
    snd_hold
    db G_3, C_3
    snd_len 8
    snd_duty $F1
    db G_5, G_5
    snd_len 16
    snd_duty $90
    db C_4
    snd_duty $F1
    db G_5
    snd_len 64
    snd_duty $90
    db C_3
    snd_ret

SndSub_7AC5:
    snd_len 32
    snd_duty $01
    db C_4, D_4, E_4
    snd_hold
    snd_len 8
    snd_duty $90
    db F_3
    snd_hold
    snd_duty $F1
    db C_4, C_4
    snd_duty $D0
    snd_len 16
    db F_3
    snd_duty $E1
    db C_4
    snd_duty $90
    snd_ret


SECTION "Shisensho Sound Driver", ROMX[$7AF0], BANK[1]

; Pick which track drives hardware channel b (b = $00/$10/$20/$30).
; The SFX set ($DF00+b) has priority; if its length byte is 0 (idle) the
; music set ($DF40+b) is used. Returns h=$DF, b=offset of chosen track.
; Pops the caller (no register writes this frame) if: both tracks idle,
; the chosen track's frame counter is not 0 (no new row this frame),
; or the current row is $89 (hold: let the previous note ring on).
SndOut_SelectSource:
    ld l, b                           ; 7AF0: 68
    ld a, [hl+]                       ; 7AF1: 2A  length byte (0 = idle)
    cp $00                            ; 7AF2: FE 00
    jp z, SndOut_TryMusic             ; 7AF4: CA 08 7B
    ld a, [hl]                        ; 7AF7: 7E  frame counter
    cp $00                            ; 7AF8: FE 00
    jp nz, SndOut_Skip                ; 7AFA: C2 24 7B
    ld a, $0a                         ; 7AFD: 3E 0A
    add b                             ; 7AFF: 80
    ld l, a                           ; 7B00: 6F
    ld a, [hl]                        ; 7B01: 7E  current note
    cp $89                            ; 7B02: FE 89
    jp z, SndOut_Skip                 ; 7B04: CA 24 7B
    ret                               ; 7B07: C9
SndOut_TryMusic:
    ld a, b                           ; 7B08: 78
    add $40                           ; 7B09: C6 40  switch to music set
    ld b, a                           ; 7B0B: 47
    ld l, a                           ; 7B0C: 6F
    ld a, [hl+]                       ; 7B0D: 2A
    cp $00                            ; 7B0E: FE 00
    jp z, SndOut_Skip                 ; 7B10: CA 24 7B
    ld a, [hl]                        ; 7B13: 7E
    cp $00                            ; 7B14: FE 00
    jp nz, SndOut_Skip                ; 7B16: C2 24 7B
    ld a, $0a                         ; 7B19: 3E 0A
    add b                             ; 7B1B: 80
    ld l, a                           ; 7B1C: 6F
    ld a, [hl]                        ; 7B1D: 7E
    cp $89                            ; 7B1E: FE 89
    jp z, SndOut_Skip                 ; 7B20: CA 24 7B
    ret                               ; 7B23: C9
SndOut_Skip:
    pop de                            ; 7B24: D1
    ret                               ; 7B25: C9

; Hardware ch1: +7 -> NR10, +8 -> NR11, +9 -> NR12, note -> NR13/NR14 (trigger)
SndOut_Ch1:
    ld h, HIGH(wSndSfxTracks)         ; 7B26: 26 DF
    call SndOut_SelectSource          ; 7B28: CD F0 7A
    ld a, b                           ; 7B2B: 78
    add $07                           ; 7B2C: C6 07
    ld l, a                           ; 7B2E: 6F
    ld a, [hl+]                       ; 7B2F: 2A  +7 sweep
    ld c, $10                         ; 7B30: 0E 10
    ldh [c], a                        ; 7B32: E2
    inc c                             ; 7B33: 0C
    jp SndOut_WriteRegsFreq           ; 7B34: C3 7A 7B

; Hardware ch2: +8 -> NR21, +9 -> NR22, note -> NR23/NR24 (trigger)
SndOut_Ch2:
    call SndOut_SelectSource          ; 7B37: CD F0 7A
    ld a, b                           ; 7B3A: 78
    add $08                           ; 7B3B: C6 08
    ld l, a                           ; 7B3D: 6F
    ld c, $16                         ; 7B3E: 0E 16
    jp SndOut_WriteRegsFreq           ; 7B40: C3 7A 7B

; Hardware ch3: NR30 = $80 every frame (re-enables DAC after a wave load),
; +8 -> NR31, +9 -> NR32, note -> NR33/NR34 (trigger + length enable)
SndOut_Ch3:
    ld a, $80                         ; 7B43: 3E 80
    ldh [rNR30], a                    ; 7B45: E0 1A
    call SndOut_SelectSource          ; 7B47: CD F0 7A
    ld a, b                           ; 7B4A: 78
    add $08                           ; 7B4B: C6 08
    ld l, a                           ; 7B4D: 6F
    ld c, $1c                         ; 7B4E: 0E 1C
    ld a, [hl+]                       ; 7B50: 2A
    ldh [rNR31], a                    ; 7B51: E0 1B
    ld a, [hl+]                       ; 7B53: 2A
    ldh [rNR32], a                    ; 7B54: E0 1C
    ld a, [hl+]                       ; 7B56: 2A
    add [hl]                          ; 7B57: 86  + transpose
    sla a                             ; 7B58: CB 27
    ld e, a                           ; 7B5A: 5F
    ld d, HIGH(SndFreqTable)          ; 7B5B: 16 7F
    ld a, [de]                        ; 7B5D: 1A
    inc e                             ; 7B5E: 1C
    ldh [rNR33], a                    ; 7B5F: E0 1D
    ld a, [de]                        ; 7B61: 1A
    or $c0                            ; 7B62: F6 C0
    ldh [rNR34], a                    ; 7B64: E0 1E
    ret                               ; 7B66: C9

; Hardware ch4: +9 -> NR42, +A (raw 'note' byte) -> NR43, NR44 = $80
SndOut_Ch4:
    call SndOut_SelectSource          ; 7B67: CD F0 7A
    ld a, b                           ; 7B6A: 78
    add $09                           ; 7B6B: C6 09
    ld l, a                           ; 7B6D: 6F
    ld c, $21                         ; 7B6E: 0E 21
    ld a, [hl+]                       ; 7B70: 2A
    ldh [c], a                        ; 7B71: E2
    inc c                             ; 7B72: 0C
    ld a, [hl+]                       ; 7B73: 2A
    ldh [c], a                        ; 7B74: E2
    inc c                             ; 7B75: 0C
    ld a, $80                         ; 7B76: 3E 80
    ldh [c], a                        ; 7B78: E2
    ret                               ; 7B79: C9

; Write [hl+] -> [c], [hl+] -> [c+1], then frequency from
; SndFreqTable[(note + transpose)] -> [c+2], [c+3] | $80
SndOut_WriteRegsFreq:
    ld a, [hl+]                       ; 7B7A: 2A
    ldh [c], a                        ; 7B7B: E2
    inc c                             ; 7B7C: 0C
    ld a, [hl+]                       ; 7B7D: 2A
    ldh [c], a                        ; 7B7E: E2
    inc c                             ; 7B7F: 0C
    ld a, [hl+]                       ; 7B80: 2A  note
    add [hl]                          ; 7B81: 86
    sla a                             ; 7B82: CB 27
    ld e, a                           ; 7B84: 5F
    ld d, HIGH(SndFreqTable)          ; 7B85: 16 7F
    ld a, [de]                        ; 7B87: 1A
    inc e                             ; 7B88: 1C
    ldh [c], a                        ; 7B89: E2
    inc c                             ; 7B8A: 0C
    ld a, [de]                        ; 7B8B: 1A
    or $80                            ; 7B8C: F6 80
    ldh [c], a                        ; 7B8E: E2
    ret                               ; 7B8F: C9

; hl = request byte, bc = channel set base ($DF00 SFX / $DF40 music).
; $FF = nothing pending (0 is a valid id!). Otherwise store $FF, then
; initialise the 4 tracks of the set from SndTable[id] (4 pointers):
; length=1, counter=0, ptr, call flag=0.
Snd_StartRequest:
    ld a, [hl]                        ; 7B90: 7E
    cp $ff                            ; 7B91: FE FF
    jp z, Snd_StartRequest_Done       ; 7B93: CA BD 7B
    ld d, $ff                         ; 7B96: 16 FF
    ld [hl], d                        ; 7B98: 72  mark request taken ($FF)
    sla a                             ; 7B99: CB 27
    sla a                             ; 7B9B: CB 27
    sla a                             ; 7B9D: CB 27
    ld l, a                           ; 7B9F: 6F
    ld h, HIGH(SndTable)              ; 7BA0: 26 7D
    ld e, $04                         ; 7BA2: 1E 04
Snd_StartRequest_Loop:
    ld a, $01                         ; 7BA4: 3E 01
    ld [bc], a                        ; 7BA6: 02  +0 length = 1
    inc c                             ; 7BA7: 0C
    dec a                             ; 7BA8: 3D
    ld [bc], a                        ; 7BA9: 02  +1 counter = 0
    inc c                             ; 7BAA: 0C
    ld a, [hl+]                       ; 7BAB: 2A
    ld [bc], a                        ; 7BAC: 02  +2 ptr lo
    inc c                             ; 7BAD: 0C
    ld a, [hl+]                       ; 7BAE: 2A
    ld [bc], a                        ; 7BAF: 02  +3 ptr hi
    inc c                             ; 7BB0: 0C
    inc c                             ; 7BB1: 0C
    inc c                             ; 7BB2: 0C
    xor a                             ; 7BB3: AF
    ld [bc], a                        ; 7BB4: 02  +6 call flag = 0
    ld a, c                           ; 7BB5: 79
    add $0a                           ; 7BB6: C6 0A
    ld c, a                           ; 7BB8: 4F
    dec e                             ; 7BB9: 1D
    jp nz, Snd_StartRequest_Loop      ; 7BBA: C2 A4 7B
Snd_StartRequest_Done:
    ret                               ; 7BBD: C9

; Advance to next track (wSndChanOfs += $10) and fall into Snd_UpdateChannel
Snd_UpdateNextChannel:
    ld a, [wSndChanOfs]               ; 7BBE: FA 90 DF
    add $10                           ; 7BC1: C6 10

; a = track offset in $DFxx. If track active, bump its frame counter;
; when counter == length, reset it and read events up to the next row.
Snd_UpdateChannel:
    ld [wSndChanOfs], a               ; 7BC3: EA 90 DF
    ld l, a                           ; 7BC6: 6F
    ld h, HIGH(wSndSfxTracks)         ; 7BC7: 26 DF
    ld a, [hl+]                       ; 7BC9: 2A
    cp $00                            ; 7BCA: FE 00
    jp z, Snd_Return                  ; 7BCC: CA F2 7C
    inc [hl]                          ; 7BCF: 34
    ld d, [hl]                        ; 7BD0: 56
    cp d                              ; 7BD1: BA  counter == length?
    jp nz, Snd_Return                 ; 7BD2: C2 F2 7C
    xor a                             ; 7BD5: AF
    ld [hl+], a                       ; 7BD6: 22
    ld c, [hl]                        ; 7BD7: 4E
    inc l                             ; 7BD8: 2C
    ld b, [hl]                        ; 7BD9: 46

; Event loop: $00-$7F note, $80-$8E command (via SndCmdTable),
; $90-$FF set row length (byte - $90) and continue.
Snd_ReadEvent:
    ld a, [bc]                        ; 7BDA: 0A
    inc bc                            ; 7BDB: 03
    cp $80                            ; 7BDC: FE 80
    jp c, Snd_StoreNote               ; 7BDE: DA F7 7B
    cp $90                            ; 7BE1: FE 90
    jp nc, Snd_SetLength              ; 7BE3: D2 0D 7C
    and $0f                           ; 7BE6: E6 0F
    sla a                             ; 7BE8: CB 27
    ld e, a                           ; 7BEA: 5F
    ld d, $00                         ; 7BEB: 16 00
    ld hl, SndCmdTable                ; 7BED: 21 1A 7C
    add hl, de                        ; 7BF0: 19
    ld a, [hl+]                       ; 7BF1: 2A
    ld h, [hl]                        ; 7BF2: 66
    ld l, a                           ; 7BF3: 6F
    jp hl                             ; 7BF4: E9

; $89: 'hold' row - stored as the note; output skips it so nothing is retriggered
SndCmd_89_Hold:
    ld a, $89                         ; 7BF5: 3E 89
Snd_StoreNote:
    ld e, a                           ; 7BF7: 5F
    ld a, [wSndChanOfs]               ; 7BF8: FA 90 DF
    add $0a                           ; 7BFB: C6 0A
    ld l, a                           ; 7BFD: 6F
    ld h, HIGH(wSndSfxTracks)         ; 7BFE: 26 DF
    ld [hl], e                        ; 7C00: 73
    ld a, [wSndChanOfs]               ; 7C01: FA 90 DF
    add $02                           ; 7C04: C6 02
    ld l, a                           ; 7C06: 6F
    ld h, HIGH(wSndSfxTracks)         ; 7C07: 26 DF
    ld [hl], c                        ; 7C09: 71
    inc l                             ; 7C0A: 2C
    ld [hl], b                        ; 7C0B: 70
    ret                               ; 7C0C: C9
Snd_SetLength:
    sub $90                           ; 7C0D: D6 90
    ld e, a                           ; 7C0F: 5F
    ld a, [wSndChanOfs]               ; 7C10: FA 90 DF
    ld l, a                           ; 7C13: 6F
    ld h, HIGH(wSndSfxTracks)         ; 7C14: 26 DF
    ld [hl], e                        ; 7C16: 73
    jp Snd_ReadEvent                  ; 7C17: C3 DA 7B

; Command jump table for $80-$8E. There is no 16th entry: a $8F byte
; would fetch its pointer from the first two code bytes of SndCmd_8A_Pan
; ($030A, the bytes of SndCmd_8A_Pan) and crash.
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

; $8A xx: NR51 = xx (no shadow copy in this version)
SndCmd_8A_Pan:
    ld a, [bc]                        ; 7C38: 0A
    inc bc                            ; 7C39: 03
    ldh [rNR51], a                    ; 7C3A: E0 25
    jp Snd_ReadEvent                  ; 7C3C: C3 DA 7B

; $8E xx: NR50 = xx
SndCmd_8E_MasterVol:
    ld a, [bc]                        ; 7C3F: 0A
    inc bc                            ; 7C40: 03
    ldh [rNR50], a                    ; 7C41: E0 24
    jp Snd_ReadEvent                  ; 7C43: C3 DA 7B

; $8C xx: NR30 = 0, copy 16 bytes from SndWaveTable+xx to wave RAM
SndCmd_8C_LoadWave:
    xor a                             ; 7C46: AF
    ldh [rNR30], a                    ; 7C47: E0 1A
    ld h, HIGH(SndWaveTable)          ; 7C49: 26 7E
    ld a, [bc]                        ; 7C4B: 0A
    inc bc                            ; 7C4C: 03
    ld l, a                           ; 7C4D: 6F
    ld de, _AUD3WAVERAM               ; 7C4E: 11 30 FF
    call Snd_Copy8                    ; 7C51: CD 5A 7C
    call Snd_Copy8                    ; 7C54: CD 5A 7C
    jp Snd_ReadEvent                  ; 7C57: C3 DA 7B

; copy 8 bytes: call Snd_Copy4, then fall into it again
Snd_Copy8:
    call Snd_Copy4                    ; 7C5A: CD 5D 7C
Snd_Copy4:
    ld a, [hl+]                       ; 7C5D: 2A
    ld [de], a                        ; 7C5E: 12
    inc e                             ; 7C5F: 1C
    ld a, [hl+]                       ; 7C60: 2A
    ld [de], a                        ; 7C61: 12
    inc e                             ; 7C62: 1C
    ld a, [hl+]                       ; 7C63: 2A
    ld [de], a                        ; 7C64: 12
    inc e                             ; 7C65: 1C
    ld a, [hl+]                       ; 7C66: 2A
    ld [de], a                        ; 7C67: 12
    inc e                             ; 7C68: 1C
    ret                               ; 7C69: C9

; $80 xx: track +8 = xx (NR11/NR21 duty+length, NR31 length)
SndCmd_80_Duty:
    ld a, [wSndChanOfs]               ; 7C6A: FA 90 DF
    add $08                           ; 7C6D: C6 08
    jp Snd_StoreParam                 ; 7C6F: C3 87 7C

; $81 xx: track +7 = xx (NR10 sweep; only used by ch1 output)
SndCmd_81_Sweep:
    ld a, [wSndChanOfs]               ; 7C72: FA 90 DF
    add $07                           ; 7C75: C6 07
    jp Snd_StoreParam                 ; 7C77: C3 87 7C

; $82 xx: track +B = xx (ADDED to the note before table lookup)
SndCmd_82_Transpose:
    ld a, [wSndChanOfs]               ; 7C7A: FA 90 DF
    add $0b                           ; 7C7D: C6 0B
    jp Snd_StoreParam                 ; 7C7F: C3 87 7C

; $83 xx: track +9 = xx (NR12/NR22/NR42 envelope, NR32 volume)
SndCmd_83_Envelope:
    ld a, [wSndChanOfs]               ; 7C82: FA 90 DF
    add $09                           ; 7C85: C6 09
Snd_StoreParam:
    ld l, a                           ; 7C87: 6F
    ld h, HIGH(wSndSfxTracks)         ; 7C88: 26 DF
    ld a, [bc]                        ; 7C8A: 0A
    inc bc                            ; 7C8B: 03
    ld [hl], a                        ; 7C8C: 77
    jp Snd_ReadEvent                  ; 7C8D: C3 DA 7B

; $84 xx / $88 xx / $8D xx: unused, parameter skipped
SndCmd_SkipParam:
    ld a, [bc]                        ; 7C90: 0A
    inc bc                            ; 7C91: 03
    jp Snd_ReadEvent                  ; 7C92: C3 DA 7B

; $85 lo hi: one-level call - save return ptr at +4/+5, set +6 = 1, jump
SndCmd_85_Call:
    ld a, [wSndChanOfs]               ; 7C95: FA 90 DF
    add $04                           ; 7C98: C6 04
    ld l, a                           ; 7C9A: 6F
    ld h, HIGH(wSndSfxTracks)         ; 7C9B: 26 DF
    ld a, [bc]                        ; 7C9D: 0A
    inc bc                            ; 7C9E: 03
    ld e, a                           ; 7C9F: 5F
    ld a, [bc]                        ; 7CA0: 0A
    inc bc                            ; 7CA1: 03
    ld [hl], c                        ; 7CA2: 71
    inc l                             ; 7CA3: 2C
    ld [hl], b                        ; 7CA4: 70
    inc l                             ; 7CA5: 2C
    ld b, a                           ; 7CA6: 47
    ld c, e                           ; 7CA7: 4B
    ld a, $01                         ; 7CA8: 3E 01
    ld [hl], a                        ; 7CAA: 77
    jp Snd_ReadEvent                  ; 7CAB: C3 DA 7B

; $86: if call flag (+6) set -> clear it and return to +4/+5.
; Otherwise end of song: zero the length byte of all 4 tracks in the
; set being processed (wSndSetFlag: 0 = SFX set $DF00, 1 = music $DF40).
SndCmd_86_Return:
    ld a, [wSndChanOfs]               ; 7CAE: FA 90 DF
    add $06                           ; 7CB1: C6 06
    ld l, a                           ; 7CB3: 6F
    ld h, HIGH(wSndSfxTracks)         ; 7CB4: 26 DF
    ld a, [hl]                        ; 7CB6: 7E
    cp $00                            ; 7CB7: FE 00
    jp z, Snd_EndSong                 ; 7CB9: CA C4 7C
    xor a                             ; 7CBC: AF
    ld [hl-], a                       ; 7CBD: 32
    ld b, [hl]                        ; 7CBE: 46  return address
    dec l                             ; 7CBF: 2D
    ld c, [hl]                        ; 7CC0: 4E
    jp Snd_ReadEvent                  ; 7CC1: C3 DA 7B
Snd_EndSong:
    ld b, $00                         ; 7CC4: 06 00
    ld a, [wSndSetFlag]               ; 7CC6: FA 91 DF
    cp $01                            ; 7CC9: FE 01
    jp z, Snd_EndSong_Music           ; 7CCB: CA DC 7C
    ld hl, wSndSfxTracks              ; 7CCE: 21 00 DF
    ld [hl], b                        ; 7CD1: 70
    ld l, LOW(wSndSfxTracks + $10)    ; 7CD2: 2E 10
    ld [hl], b                        ; 7CD4: 70
    ld l, LOW(wSndSfxTracks + $20)    ; 7CD5: 2E 20
    ld [hl], b                        ; 7CD7: 70
    ld l, LOW(wSndSfxTracks + $30)    ; 7CD8: 2E 30
    ld [hl], b                        ; 7CDA: 70
    ret                               ; 7CDB: C9
Snd_EndSong_Music:
    ld hl, wSndMusicTracks            ; 7CDC: 21 40 DF
    ld [hl], b                        ; 7CDF: 70
    ld l, LOW(wSndSfxTracks + $50)    ; 7CE0: 2E 50
    ld [hl], b                        ; 7CE2: 70
    ld l, LOW(wSndSfxTracks + $60)    ; 7CE3: 2E 60
    ld [hl], b                        ; 7CE5: 70
    ld l, LOW(wSndSfxTracks + $70)    ; 7CE6: 2E 70
    ld [hl], b                        ; 7CE8: 70
    ret                               ; 7CE9: C9

; $87: end this track only (length = 0)
SndCmd_87_EndTrack:
    ld a, [wSndChanOfs]               ; 7CEA: FA 90 DF
    ld l, a                           ; 7CED: 6F
    ld h, HIGH(wSndSfxTracks)         ; 7CEE: 26 DF
    xor a                             ; 7CF0: AF
    ld [hl], a                        ; 7CF1: 77
Snd_Return:
    ret                               ; 7CF2: C9

; $8B lo hi: jump (used for loops)
SndCmd_8B_Jump:
    ld a, [bc]                        ; 7CF3: 0A
    inc bc                            ; 7CF4: 03
    ld l, a                           ; 7CF5: 6F
    ld a, [bc]                        ; 7CF6: 0A
    inc bc                            ; 7CF7: 03
    ld b, a                           ; 7CF8: 47
    ld c, l                           ; 7CF9: 4D
    jp Snd_ReadEvent                  ; 7CFA: C3 DA 7B
    ds $03, $FF

; ---- SndTable: 4 track pointers (ch1, ch2, ch3, ch4) per sound id -------------
; Requests use $FF for "nothing pending", so id 0 can be started: it points all
; four tracks at a $86, which ends the set at once.
SndTable:
    dw Snd00_Ch1, Snd00_Ch1, Snd00_Ch1, Snd00_Ch1 ; $00
    dw Snd01_Ch1, Snd01_Ch1, Snd01_Ch3, Snd00_Ch1 ; $01
    dw Snd02_Ch1, Snd02_Ch2, Snd02_Ch3, Snd02_Ch4 ; $02
    dw Snd03_Ch1, Snd03_Ch2, Snd03_Ch3, Snd03_Ch4 ; $03
    dw Snd04_Ch1, Snd04_Ch2, Snd04_Ch3, Snd03_Ch4 ; $04
    dw Snd05_Ch1, Snd05_Ch2, Snd05_Ch3, Snd03_Ch4 ; $05
    dw Snd06_Ch1, Snd06_Ch2, Snd06_Ch3, Snd03_Ch4 ; $06
    dw Snd07_Ch1, Snd07_Ch2, Snd07_Ch3, Snd07_Ch4 ; $07
    dw Snd08_Ch1, Snd03_Ch4, Snd03_Ch4, Snd03_Ch4 ; $08
    dw Snd09_Ch1, Snd03_Ch4, Snd03_Ch4, Snd03_Ch4 ; $09
    dw Snd0A_Ch1, Snd03_Ch4, Snd03_Ch4, Snd03_Ch4 ; $0A
    dw Snd03_Ch4, Snd03_Ch4, Snd03_Ch4, Snd0B_Ch4 ; $0B
    dw Snd0C_Ch1, Snd03_Ch4, Snd03_Ch4, Snd03_Ch4 ; $0C
    dw Snd0D_Ch1, Snd03_Ch4, Snd03_Ch4, Snd03_Ch4 ; $0D
    dw Snd03_Ch4, Snd03_Ch4, Snd03_Ch4, Snd0E_Ch4 ; $0E
    dw Snd03_Ch4, Snd03_Ch4, Snd03_Ch4, Snd0F_Ch4 ; $0F
    dw Snd10_Ch1, Snd10_Ch2, Snd03_Ch4, Snd03_Ch4 ; $10
    dw Snd03_Ch4, Snd03_Ch4, Snd11_Ch3, Snd03_Ch4 ; $11
    dw Snd03_Ch4, Snd03_Ch4, Snd03_Ch4, Snd12_Ch4 ; $12
    dw Snd13_Ch1, Snd03_Ch4, Snd03_Ch4, Snd03_Ch4 ; $13
    dw Snd14_Ch1, Snd03_Ch4, Snd03_Ch4, Snd03_Ch4 ; $14
    dw Snd15_Ch1, Snd03_Ch4, Snd03_Ch4, Snd15_Ch4 ; $15
    dw Snd16_Ch1, Snd03_Ch4, Snd03_Ch4, Snd03_Ch4 ; $16
    dw Snd17_Ch1, Snd03_Ch4, Snd03_Ch4, Snd03_Ch4 ; $17

Snd00_Ch1:
Snd00_Ch2:
Snd00_Ch3:
Snd00_Ch4:
Snd01_Ch4:
    snd_endsong ; $7DC0: id $00 - ends the set
Snd03_Ch4:
Snd04_Ch4:
Snd05_Ch4:
Snd06_Ch4:
Snd08_Ch2:
Snd08_Ch3:
Snd08_Ch4:
Snd09_Ch2:
Snd09_Ch3:
Snd09_Ch4:
Snd0A_Ch2:
Snd0A_Ch3:
Snd0A_Ch4:
Snd0B_Ch1:
Snd0B_Ch2:
Snd0B_Ch3:
Snd0C_Ch2:
Snd0C_Ch3:
Snd0C_Ch4:
Snd0D_Ch2:
Snd0D_Ch3:
Snd0D_Ch4:
Snd0E_Ch1:
Snd0E_Ch2:
Snd0E_Ch3:
Snd0F_Ch1:
Snd0F_Ch2:
Snd0F_Ch3:
Snd10_Ch3:
Snd10_Ch4:
Snd11_Ch1:
Snd11_Ch2:
Snd11_Ch4:
Snd12_Ch1:
Snd12_Ch2:
Snd12_Ch3:
Snd13_Ch2:
Snd13_Ch3:
Snd13_Ch4:
Snd14_Ch2:
Snd14_Ch3:
Snd14_Ch4:
Snd15_Ch2:
Snd15_Ch3:
Snd16_Ch2:
Snd16_Ch3:
Snd16_Ch4:
Snd17_Ch2:
Snd17_Ch3:
Snd17_Ch4:
    snd_end     ; $7DC1: shared "silent" track for unused channel slots
    ds $3E, $FF

; ---- SndWaveTable: a single 16-byte wave (saw); sound data follows directly ----
SndWaveTable:
    db $00, $11, $22, $33, $44, $55, $66, $77, $88, $99, $AA, $BB, $CC, $DD, $EE, $FF ; $00

; ---- music / SFX data (part 2) ------------------------------------------------

Snd01_Ch1:
Snd01_Ch2:
    snd_len 1
    snd_duty $00
    snd_env $00
    db $47
    snd_endsong

Snd01_Ch3:
    snd_env $00
    snd_pan $00
    snd_len 1
    snd_duty $FE
    db C_3
    snd_endsong

Snd08_Ch1:
    snd_duty $80
    snd_env $F1
    snd_len 15
    db As6, Fs6
    snd_hold
    snd_hold
    snd_jump Snd08_Ch1

Snd09_Ch1:
    snd_duty $80
    snd_env $F1
    snd_len 3
    db E_5, G_5, A_5, G_5, A_5, C_6
    snd_hold
    snd_endsong

Snd0A_Ch1:
    snd_duty $00
    snd_env $F1
    snd_len 2
    db G_5, A_5, C_6, C_6, E_6
    snd_hold
    snd_endsong

Snd0B_Ch4:
    snd_len 60
    snd_env $F4
    db $42
    snd_hold
    snd_endsong

Snd0C_Ch1:
    snd_duty $80
    snd_env $F0
    snd_len 2
    db F_6, D_6, C_6
    snd_env $13
    db C_6
    snd_endsong

Snd0D_Ch1:
    snd_duty $80
    snd_sweep $25
    snd_env $E3
    snd_len 40
    db E_4
    snd_endsong

Snd17_Ch1:
    snd_duty $80
    snd_sweep $00
    snd_env $F0
    snd_len 2
    db A_5, C_6, D_6, F_6, G_6, A_6
    snd_env $13
    db A_6
    snd_endsong

Snd0E_Ch4:
    snd_env $F1
    snd_len 2
    db $26, $02
    snd_env $00
    db $01
    snd_endsong

Snd0F_Ch4:
    snd_env $F0
    snd_len 8
    db $2F
    snd_hold
    snd_env $11
    db $2F
    snd_endsong

Snd10_Ch1:
    snd_duty $80
    snd_env $F2
    snd_len 3
    db A_5, C_6, D_6, E_6, G_6, A_6
    snd_hold
    snd_endsong

Snd10_Ch2:
    snd_duty $80
    snd_env $F2
    snd_len 3
    db E_5, G_5, A_5, B_5, D_6, E_6
    snd_hold
    snd_endsong

Snd11_Ch3:
    snd_wave $00
    snd_env $20
    snd_duty $F6
    snd_len 3
    db A_6
    snd_endsong

Snd12_Ch4:
    snd_env $F1
    snd_len 1
    db $0A, $08, $09
    snd_endsong

Snd13_Ch1:
    snd_env $F3
    snd_sweep $6D
    snd_duty $80
    snd_len 7
    db F_6
    snd_env $F1
    snd_duty $00
    snd_sweep $1F
    db C_6
    snd_hold
    snd_sweep $00
    snd_endsong

Snd14_Ch1:
    snd_duty $80
    snd_env $F2
    snd_len 10
    snd_sweep $15
    db C_3
    snd_sweep $00
    snd_endsong

Snd15_Ch1:
    snd_duty $80
    snd_env $F2
    snd_sweep $1C
    snd_len 12
    db A_4
    snd_sweep $00
    snd_endsong

Snd15_Ch4:
    snd_env $F1
    snd_len 4
    db $44, $43
    snd_hold
    snd_endsong

Snd16_Ch1:
    snd_sweep $16
    snd_duty $80
    snd_env $F6
    snd_len 60
    db C_3
    snd_sweep $00
    snd_endsong
    ds $18, $FF

; ---- SndFreqTable: 48 GB frequency values, note $00 = C3 (130.8 Hz on ch1/2) ---
; (= entries 12-59 of the 72-entry table in Lenar's and Kid Niki's drivers)
SndFreqTable:
    dw $0416, $044E, $047F, $04B5, $04E5, $0511, $053B, $0563, $0589, $05AC, $05CE, $05ED ; C_3-B_3
    dw $060B, $0627, $0642, $065B, $0672, $0689, $069E, $06B2, $06C4, $06D6, $06E7, $06F7 ; C_4-B_4
    dw $0706, $0714, $0721, $072D, $0739, $0744, $074F, $0759, $0762, $076B, $0773, $077B ; C_5-B_5
    dw $0783, $078A, $0790, $0797, $079D, $07A2, $07A7, $07AC, $07B1, $07B6, $07BA, $07BE ; C_6-B_6
    ds $20, $FF

; Called from the VBlank handler ($0040 -> $0200 -> call $7F80), once per frame.
; 1. Start pending requests (SFX request -> $DF00 set, music request -> $DF40 set)
; 2. Advance all 8 tracks (SFX set with wSndSetFlag=0, then music set with 1)
; 3. Write the 4 hardware channels (SFX track has priority over music track)
SoundUpdate:
    ld hl, wSndReqSfx                 ; 7F80: 21 0E DF
    ld bc, wSndSfxTracks              ; 7F83: 01 00 DF
    call Snd_StartRequest             ; 7F86: CD 90 7B
    ld hl, wSndReqMusic               ; 7F89: 21 1E DF
    ld bc, wSndMusicTracks            ; 7F8C: 01 40 DF
    call Snd_StartRequest             ; 7F8F: CD 90 7B
    ld a, $00                         ; 7F92: 3E 00
    ld [wSndSetFlag], a               ; 7F94: EA 91 DF
    call Snd_UpdateChannel            ; 7F97: CD C3 7B
    call Snd_UpdateNextChannel        ; 7F9A: CD BE 7B
    call Snd_UpdateNextChannel        ; 7F9D: CD BE 7B
    call Snd_UpdateNextChannel        ; 7FA0: CD BE 7B
    ld a, $01                         ; 7FA3: 3E 01
    ld [wSndSetFlag], a               ; 7FA5: EA 91 DF
    call Snd_UpdateNextChannel        ; 7FA8: CD BE 7B
    call Snd_UpdateNextChannel        ; 7FAB: CD BE 7B
    call Snd_UpdateNextChannel        ; 7FAE: CD BE 7B
    call Snd_UpdateNextChannel        ; 7FB1: CD BE 7B
    ld b, $00                         ; 7FB4: 06 00
    call SndOut_Ch1                   ; 7FB6: CD 26 7B
    ld b, $10                         ; 7FB9: 06 10
    call SndOut_Ch2                   ; 7FBB: CD 37 7B
    ld b, $20                         ; 7FBE: 06 20
    call SndOut_Ch3                   ; 7FC0: CD 43 7B
    ld b, $30                         ; 7FC3: 06 30
    jp SndOut_Ch4                     ; 7FC5: C3 67 7B
