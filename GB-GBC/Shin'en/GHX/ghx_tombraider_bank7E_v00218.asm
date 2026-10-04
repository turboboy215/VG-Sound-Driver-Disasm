; ============================================================================
; Tomb Raider (UE) (M5) [C][!].gbc  -  bank $7E (file offset $1F8000-$1FBFFF)
; "GHX Sound Engine v00218 (c) 2000 SHIN'EN. Code: M. Wodok   Music: M. Linzner"
; 
; Version string "v00218" = 18 Feb 2000 - the newer Tomb Raider build, used for
; the in-game music: $0596 sets the sound bank $C1E5 = $7E and starts subsong
; 4/5/6/7/8 for $C194 = 0/3/6/9/11 (else 9), then plays SFX 29 (ch3 instrument
; at level 0 with time $FF), which mutes the music on channel 3 for good so the
; game's own PCM player in bank 0 can use it (see ghx_tombraider_bank0_pcm.asm).
; 
; Changes against v2.0207 (bank $7F): GHX_Play honours wReturnFlag (effect $8x
; = resume the song saved by GHX_SaveSong), an SFX time of $FF on ch3 holds the
; channel indefinitely, GHX_Init/GHX_RestoreSong/GHX_PlaySFX disable the player
; while they work, the timer-IRQ code is gone. Song data: different music set.
;
; Complete disassembly of the bank: sound driver code plus all music and
; sound-effect data as labelled source. Assemble with RGBDS 0.9:
;   rgbasm -o x.o ghx_tombraider_bank7E_v00218.asm ; rgblink -o x.gb x.o
; and the bank(s) in x.gb are byte-identical to the original ROM.
; ============================================================================

INCLUDE "ghx_hw.inc"
INCLUDE "ghx_macros.inc"

; ---- RAM: four channel blocks of $2C bytes at $DE00/$DE2C/$DE58/$DE84 ------
DEF wCh1_Transpose               EQU $DE00
DEF wCh1_TrackPtrLo              EQU $DE01
DEF wCh1_TrackPtrHi              EQU $DE02
DEF wCh1_SFXTimer                EQU $DE03
DEF wCh1_TrackNum                EQU $DE04
DEF wCh1_Note                    EQU $DE05
DEF wCh1_VolShift                EQU $DE06
DEF wCh1_InsFlags                EQU $DE07
DEF wCh1_VibDelay                EQU $DE08
DEF wCh1_VibDepth                EQU $DE09
DEF wCh1_VibSpeed                EQU $DE0A
DEF wCh1_VibPhase                EQU $DE0B
DEF wCh1_Level                   EQU $DE0C
DEF wCh1_PLLoops                 EQU $DE0D
DEF wCh1_PLNoteRaw               EQU $DE0E
DEF wCh1_PLNote                  EQU $DE0F
DEF wCh1_PLPtrLo                 EQU $DE10
DEF wCh1_PLPtrHi                 EQU $DE11
DEF wCh1_PLSpeed                 EQU $DE12
DEF wCh1_PLTimer                 EQU $DE13
DEF wCh1_PLSteps                 EQU $DE14
DEF wCh1_RowNote                 EQU $DE15
DEF wCh1_RowIns                  EQU $DE16
DEF wCh1_RowFx                   EQU $DE17
DEF wCh1_EnvShadow               EQU $DE18
DEF wCh1_SweepShadow             EQU $DE19
DEF wCh2_Transpose               EQU $DE2C
DEF wCh2_TrackPtrLo              EQU $DE2D
DEF wCh2_TrackPtrHi              EQU $DE2E
DEF wCh2_SFXTimer                EQU $DE2F
DEF wCh2_TrackNum                EQU $DE30
DEF wCh2_Note                    EQU $DE31
DEF wCh2_VolShift                EQU $DE32
DEF wCh2_InsFlags                EQU $DE33
DEF wCh2_VibDelay                EQU $DE34
DEF wCh2_VibDepth                EQU $DE35
DEF wCh2_VibSpeed                EQU $DE36
DEF wCh2_VibPhase                EQU $DE37
DEF wCh2_Level                   EQU $DE38
DEF wCh2_PLLoops                 EQU $DE39
DEF wCh2_PLNoteRaw               EQU $DE3A
DEF wCh2_PLNote                  EQU $DE3B
DEF wCh2_PLPtrLo                 EQU $DE3C
DEF wCh2_PLPtrHi                 EQU $DE3D
DEF wCh2_PLSpeed                 EQU $DE3E
DEF wCh2_PLTimer                 EQU $DE3F
DEF wCh2_PLSteps                 EQU $DE40
DEF wCh2_RowNote                 EQU $DE41
DEF wCh2_RowIns                  EQU $DE42
DEF wCh2_RowFx                   EQU $DE43
DEF wCh2_EnvShadow               EQU $DE44
DEF wCh2_SweepShadow             EQU $DE45
DEF wCh3_Transpose               EQU $DE58
DEF wCh3_TrackPtrLo              EQU $DE59
DEF wCh3_TrackPtrHi              EQU $DE5A
DEF wCh3_SFXTimer                EQU $DE5B
DEF wCh3_TrackNum                EQU $DE5C
DEF wCh3_Note                    EQU $DE5D
DEF wCh3_VolShift                EQU $DE5E
DEF wCh3_InsFlags                EQU $DE5F
DEF wCh3_VibDelay                EQU $DE60
DEF wCh3_VibDepth                EQU $DE61
DEF wCh3_VibSpeed                EQU $DE62
DEF wCh3_VibPhase                EQU $DE63
DEF wCh3_Level                   EQU $DE64
DEF wCh3_PLLoops                 EQU $DE65
DEF wCh3_PLNoteRaw               EQU $DE66
DEF wCh3_PLNote                  EQU $DE67
DEF wCh3_PLPtrLo                 EQU $DE68
DEF wCh3_PLPtrHi                 EQU $DE69
DEF wCh3_PLSpeed                 EQU $DE6A
DEF wCh3_PLTimer                 EQU $DE6B
DEF wCh3_PLSteps                 EQU $DE6C
DEF wCh3_RowNote                 EQU $DE6D
DEF wCh3_RowIns                  EQU $DE6E
DEF wCh3_RowFx                   EQU $DE6F
DEF wCh3_EnvShadow               EQU $DE70
DEF wCh3_SweepShadow             EQU $DE71
DEF wWave_PCMFlag                EQU $DE74
DEF wWave_SweepTimer             EQU $DE75
DEF wWave_SweepOn                EQU $DE76
DEF wWave_WaveUpdate             EQU $DE77
DEF wWave_BaseHi                 EQU $DE78
DEF wWave_BaseLo                 EQU $DE79
DEF wWave_SweepSpeed             EQU $DE7A
DEF wWave_UpperLo                EQU $DE7B
DEF wWave_UpperHi                EQU $DE7C
DEF wWave_LowerLo                EQU $DE7D
DEF wWave_LowerHi                EQU $DE7E
DEF wWave_PosLo                  EQU $DE7F
DEF wWave_PosHi                  EQU $DE80
DEF wWave_FlagLo                 EQU $DE81
DEF wWave_FlagHi                 EQU $DE82
DEF wWave_Step                   EQU $DE83
DEF wCh4_Transpose               EQU $DE84
DEF wCh4_TrackPtrLo              EQU $DE85
DEF wCh4_TrackPtrHi              EQU $DE86
DEF wCh4_SFXTimer                EQU $DE87
DEF wCh4_TrackNum                EQU $DE88
DEF wCh4_Note                    EQU $DE89
DEF wCh4_VolShift                EQU $DE8A
DEF wCh4_InsFlags                EQU $DE8B
DEF wCh4_VibDelay                EQU $DE8C
DEF wCh4_VibDepth                EQU $DE8D
DEF wCh4_VibSpeed                EQU $DE8E
DEF wCh4_VibPhase                EQU $DE8F
DEF wCh4_Level                   EQU $DE90
DEF wCh4_PLLoops                 EQU $DE91
DEF wCh4_PLNoteRaw               EQU $DE92
DEF wCh4_PLNote                  EQU $DE93
DEF wCh4_PLPtrLo                 EQU $DE94
DEF wCh4_PLPtrHi                 EQU $DE95
DEF wCh4_PLSpeed                 EQU $DE96
DEF wCh4_PLTimer                 EQU $DE97
DEF wCh4_PLSteps                 EQU $DE98
DEF wCh4_RowNote                 EQU $DE99
DEF wCh4_RowIns                  EQU $DE9A
DEF wCh4_RowFx                   EQU $DE9B
DEF wCh4_EnvShadow               EQU $DE9C
DEF wCh4_SweepShadow             EQU $DE9D
DEF wEnabled                     EQU $DEB0
DEF wHdr_Magic                   EQU $DEB1
DEF wHdr_Subsongs                EQU $DEB4
DEF wHdr_PatLen                  EQU $DEB5
DEF wHdr_Unused                  EQU $DEB6
DEF wHdr_TracksLo                EQU $DEB7
DEF wHdr_TracksHi                EQU $DEB8
DEF wHdr_InstsLo                 EQU $DEB9
DEF wHdr_InstsHi                 EQU $DEBA
DEF wHdr_OrdersLo                EQU $DEBB
DEF wHdr_OrdersHi                EQU $DEBC
DEF wTickCount                   EQU $DEBD
DEF wSubsong                     EQU $DEBE
DEF wOrderSel                    EQU $DEBF
DEF wSpeed                       EQU $DEC0
DEF wRowsLeft                    EQU $DEC1
DEF wPosLeft                     EQU $DEC2
DEF wPosPtrLo                    EQU $DEC3
DEF wPosPtrHi                    EQU $DEC4
DEF wSFX_Ch1                     EQU $DEC7
DEF wSFX_Ch2                     EQU $DEC8
DEF wSFX_Ch3                     EQU $DEC9
DEF wSFX_Ch4                     EQU $DECA
DEF wSFX_Time                    EQU $DECB
DEF wSave_Subsong                EQU $DECC
DEF wSave_OrderSel               EQU $DECD
DEF wSave_Speed                  EQU $DECE
DEF wSave_RowsLeft               EQU $DECF
DEF wSave_PosLeft                EQU $DED0
DEF wSave_PosPtrLo               EQU $DED1
DEF wSave_PosPtrHi               EQU $DED2
DEF wSave_Channels               EQU $DED3
DEF wSong                        EQU $DEE1
DEF wSave_Song                   EQU $DEE2
DEF wReturnFlag                  EQU $DEE3
DEF wSpeedAdjust                 EQU $DEE5
DEF wSFX_Last                    EQU $DEE6
DEF wSFX_Ch3Owner                EQU $DEE7
DEF wSFX_Ch3Prev                 EQU $DEE8
DEF wSaved                       EQU $DEE9

SECTION "GHX Sound Engine", ROMX[$4000], BANK[$7E]

;; =====================================================================
;; Public jump table
;; =====================================================================
GHX_Init:
    jp InitSong                 ; 4000  A = subsong, C = song
GHX_Play:
    jp PlayFrame                ; 4003  call once per frame
GHX_Stop:
    jp StopImpl                 ; 4006  stop, APU off, forget saved song
GHX_SoundOn:
    jp SoundOnImpl              ; 4009  APU on again (keeps the song position)
GHX_SaveSong:
    jp SaveSong                 ; 400C  push the current song
GHX_RestoreSong:
    jp RestoreSong              ; 400F  pop it again
GHX_Unused1:
    ret                         ; 4012  (empty slot)
    db $00, $00                                ; 4013
GHX_PlaySFX:
    jp PlaySFX                  ; 4015  A = sound effect
GHX_Pause:
    jp PauseImpl                ; 4018  stop, APU off, keep everything
GHX_Unused2:
    ret                         ; 401B  (empty slot)
    db $00, $00                                ; 401C

;; Version / copyright string (never executed)
    db "GHX Sound Engine v00218 (c) 2000 SHIN", $B4, "EN. Code: M. Wodok   Music: M. Linzner "; 401E

;; GHX_SaveSong: remember the playing song (song, subsong, order state,
;; position, transpose + track pointer of each channel) in wSave_* so that
;; a jingle can be played and the music resumed later. Only one level.
SaveSong:
    ld a, [wSaved]              ; 406B
    or a                        ; 406E
    ret nz                      ; 406F
    cpl                         ; 4070
    ld [wSaved], a              ; 4071
    ld a, [wSong]               ; 4074
    ld [wSave_Song], a          ; 4077
    ld a, [wSubsong]            ; 407A
    ld [wSave_Subsong], a       ; 407D
    ld a, [wOrderSel]           ; 4080
    ld [wSave_OrderSel], a      ; 4083
    ld a, [wSpeed]              ; 4086
    ld [wSave_Speed], a         ; 4089
    ld a, [wRowsLeft]           ; 408C
    ld [wSave_RowsLeft], a      ; 408F
    ld a, [wPosLeft]            ; 4092
    ld [wSave_PosLeft], a       ; 4095
    ld a, [wPosPtrLo]           ; 4098
    ld [wSave_PosPtrLo], a      ; 409B
    ld a, [wPosPtrHi]           ; 409E
    ld [wSave_PosPtrHi], a      ; 40A1
    ld a, [wCh1_Transpose]      ; 40A4
    ld [wSave_Channels], a      ; 40A7
    ld a, [wCh1_TrackPtrLo]     ; 40AA
    ld [wSave_Channels+1], a    ; 40AD
    ld a, [wCh1_TrackPtrHi]     ; 40B0
    ld [wSave_Channels+2], a    ; 40B3
    ld a, [wCh2_Transpose]      ; 40B6
    ld [wSave_Channels+3], a    ; 40B9
    ld a, [wCh2_TrackPtrLo]     ; 40BC
    ld [wSave_Channels+4], a    ; 40BF
    ld a, [wCh2_TrackPtrHi]     ; 40C2
    ld [wSave_Channels+5], a    ; 40C5
    ld a, [wCh3_Transpose]      ; 40C8
    ld [wSave_Channels+6], a    ; 40CB
    ld a, [wCh3_TrackPtrLo]     ; 40CE
    ld [wSave_Channels+7], a    ; 40D1
    ld a, [wCh3_TrackPtrHi]     ; 40D4
    ld [wSave_Channels+8], a    ; 40D7
    ld a, [wCh4_Transpose]      ; 40DA
    ld [wSave_Channels+9], a    ; 40DD
    ld a, [wCh4_TrackPtrLo]     ; 40E0
    ld [wSave_Channels+10], a   ; 40E3
    ld a, [wCh4_TrackPtrHi]     ; 40E6
    ld [wSave_Channels+11], a   ; 40E9
    ret                         ; 40EC

;; GHX_Init: A = subsong, C = song (index into SongTable).
;; Copies the 12-byte song header to wHdr_*, clears the channel RAM and
;; switches the APU on.
InitSong:
    push af                     ; 40ED
    xor a                       ; 40EE
    ld [wEnabled], a            ; 40EF
    pop af                      ; 40F2
    ld [wSubsong], a            ; 40F3
    ld a, $06                   ; 40F6
    ld [wSpeed], a              ; 40F8
    xor a                       ; 40FB
    ld [wTickCount], a          ; 40FC
    ld [wReturnFlag], a         ; 40FF
    ld [wRowsLeft], a           ; 4102
    ld [wPosLeft], a            ; 4105
    ld [wOrderSel], a           ; 4108
    ld b, $00                   ; 410B
    ld hl, SongTable            ; 410D
    add hl, bc                  ; 4110
    add hl, bc                  ; 4111
    ld a, c                     ; 4112
    ld [wSong], a               ; 4113
    ld a, [hl+]                 ; 4116
    ld c, a                     ; 4117
    ld a, [hl+]                 ; 4118
    ld h, a                     ; 4119
    ld l, c                     ; 411A
    ld de, wHdr_Magic           ; 411B
    ld c, $0C                   ; 411E
InitSong_CopyHeader:
    ld a, [hl+]                 ; 4120
    ld [de], a                  ; 4121
    inc de                      ; 4122
    dec c                       ; 4123
    jr nz, InitSong_CopyHeader  ; 4124
    ld hl, wCh1_Transpose       ; 4126
    ld c, $B0                   ; 4129
    xor a                       ; 412B
.L412C:
    ld [hl+], a                 ; 412C
    dec c                       ; 412D
    jr nz, .L412C               ; 412E

;; APU on: NR52 = $80, NR50 = $77, NR51 = $FF, envelopes off, player enabled.
InitAPU:
    ld a, $80                   ; 4130
    ldh [rNR52], a              ; 4132
    ld a, $77                   ; 4134
    ldh [rNR50], a              ; 4136
    ld a, $FF                   ; 4138
    ldh [rNR51], a              ; 413A
    xor a                       ; 413C
    ldh [rNR10], a              ; 413D
    ldh [rNR12], a              ; 413F
    ldh [rNR22], a              ; 4141
    ldh [rNR32], a              ; 4143
    ldh [rNR42], a              ; 4145
    ld a, $FF                   ; 4147
    ld [wEnabled], a            ; 4149
    ret                         ; 414C

;; GHX_RestoreSong: resume the song saved by GHX_SaveSong (at the start of
;; the row it was interrupted in).
RestoreSong:
    ld a, [wSaved]              ; 414D
    or a                        ; 4150
    ret z                       ; 4151
    xor a                       ; 4152
    ld [wSaved], a              ; 4153
    xor a                       ; 4156
    ld [wEnabled], a            ; 4157
    ld a, [wSave_Song]          ; 415A
    ld [wSong], a               ; 415D
    ld c, a                     ; 4160
    ld a, [wSave_Subsong]       ; 4161
    ld [wSubsong], a            ; 4164
    ld a, [wSave_Speed]         ; 4167
    ld [wSpeed], a              ; 416A
    xor a                       ; 416D
    ld [wTickCount], a          ; 416E
    ld [wReturnFlag], a         ; 4171
    ld a, [wSave_RowsLeft]      ; 4174
    ld [wRowsLeft], a           ; 4177
    ld a, [wSave_PosLeft]       ; 417A
    ld [wPosLeft], a            ; 417D
    ld a, [wSave_PosPtrLo]      ; 4180
    ld [wPosPtrLo], a           ; 4183
    ld a, [wSave_PosPtrHi]      ; 4186
    ld [wPosPtrHi], a           ; 4189
    ld a, [wSave_OrderSel]      ; 418C
    ld [wOrderSel], a           ; 418F
    ld b, $00                   ; 4192
    ld hl, SongTable            ; 4194
    add hl, bc                  ; 4197
    add hl, bc                  ; 4198
    ld a, [hl+]                 ; 4199
    ld c, a                     ; 419A
    ld a, [hl+]                 ; 419B
    ld h, a                     ; 419C
    ld l, c                     ; 419D
    ld de, wHdr_Magic           ; 419E
    ld c, $0C                   ; 41A1
.L41A3:
    ld a, [hl+]                 ; 41A3
    ld [de], a                  ; 41A4
    inc de                      ; 41A5
    dec c                       ; 41A6
    jr nz, .L41A3               ; 41A7
    ld hl, wCh1_Transpose       ; 41A9
    ld de, wSave_Channels       ; 41AC
    ld b, $04                   ; 41AF
RestoreSong_Channels:
    ld a, [de]                  ; 41B1
    ld [hl+], a                 ; 41B2
    inc de                      ; 41B3
    ld a, [de]                  ; 41B4
    ld [hl+], a                 ; 41B5
    inc de                      ; 41B6
    ld a, [de]                  ; 41B7
    ld [hl+], a                 ; 41B8
    inc de                      ; 41B9
    ld c, $29                   ; 41BA
    xor a                       ; 41BC
.L41BD:
    ld [hl+], a                 ; 41BD
    dec c                       ; 41BE
    jr nz, .L41BD               ; 41BF
    dec b                       ; 41C1
    jr nz, RestoreSong_Channels ; 41C2
    jp InitAPU                  ; 41C4

;; GHX_SoundOn: re-enable the APU, keep the song position.
SoundOnImpl:
    xor a                       ; 41C7
    ld [wEnabled], a            ; 41C8
    ld a, $80                   ; 41CB
    ldh [rNR52], a              ; 41CD
    ld a, $77                   ; 41CF
    ldh [rNR50], a              ; 41D1
    ld a, $FF                   ; 41D3
    ldh [rNR51], a              ; 41D5
    xor a                       ; 41D7
    ldh [rNR10], a              ; 41D8
    ldh [rNR12], a              ; 41DA
    ldh [rNR22], a              ; 41DC
    ldh [rNR32], a              ; 41DE
    ldh [rNR42], a              ; 41E0
    ld a, $FF                   ; 41E2
    ld [wEnabled], a            ; 41E4
    ret                         ; 41E7

;; GHX_Stop: stop the player, NR52 = 0, forget the saved song and the speed adjust.
StopImpl:
    xor a                       ; 41E8
    ld [wEnabled], a            ; 41E9
    ldh [rNR52], a              ; 41EC
    ld [wSaved], a              ; 41EE
    ld [wSpeedAdjust], a        ; 41F1
    ret                         ; 41F4

;; GHX_Pause: stop the player and the APU (song state is kept).
PauseImpl:
    xor a                       ; 41F5
    ld [wEnabled], a            ; 41F6
    ldh [rNR52], a              ; 41F9
    ret                         ; 41FB

;; GHX_Play - call once per frame.
;; New in this build: a pending wReturnFlag (effect $8x) resumes the song saved
;; by GHX_SaveSong before anything else is done.
;; wTickCount counts the ticks of a row down; bit 7 set = paused.
;; On a new row: when the pattern is finished (wRowsLeft = 0) the next
;; position is read. When the current order entry has no positions left the
;; order entry 2*subsong+wOrderSel is (re)started; wOrderSel is 0 for the
;; first pass (intro) and 1 afterwards (loop).
PlayFrame:
    ld a, [wEnabled]            ; 41FC
    or a                        ; 41FF
    ret z                       ; 4200
    ld a, [wReturnFlag]         ; 4201
    or a                        ; 4204
    jr z, .L420E                ; 4205
    xor a                       ; 4207
    ld [wReturnFlag], a         ; 4208
    jp RestoreSong              ; 420B
.L420E:
    ld b, $00                   ; 420E
    ld a, [wTickCount]          ; 4210
    bit 7, a                    ; 4213
    jp nz, Tick                 ; 4215
    or a                        ; 4218
    jp nz, Tick_Count           ; 4219
    ld a, [wRowsLeft]           ; 421C
    or a                        ; 421F
    jp nz, Row_Ch1              ; 4220
    ld a, [wHdr_PatLen]         ; 4223
    ld [wRowsLeft], a           ; 4226
    ld a, [wPosLeft]            ; 4229
    or a                        ; 422C
    jp nz, NextPosition         ; 422D
    ld a, [wHdr_OrdersLo]       ; 4230
    ld l, a                     ; 4233
    ld a, [wHdr_OrdersHi]       ; 4234
    ld h, a                     ; 4237
    ld a, [wOrderSel]           ; 4238
    ld c, a                     ; 423B
    or $01                      ; 423C
    ld [wOrderSel], a           ; 423E
    ld a, [wSubsong]            ; 4241
    add a,a                     ; 4244
    add a,c                     ; 4245
    ld c, a                     ; 4246
    add hl, bc                  ; 4247
    add hl, bc                  ; 4248
    add hl, bc                  ; 4249
    ld a, [hl+]                 ; 424A
    ld [wPosLeft], a            ; 424B
    ld a, [hl+]                 ; 424E
    ld c, a                     ; 424F
    ld a, [hl+]                 ; 4250
    ld h, a                     ; 4251
    ld l, c                     ; 4252
    jr ReadPosition             ; 4253
NextPosition:
    ld a, [wPosPtrLo]           ; 4255
    ld l, a                     ; 4258
    ld a, [wPosPtrHi]           ; 4259
    ld h, a                     ; 425C
    ld a, [wPosLeft]            ; 425D
    dec a                       ; 4260
    ld [wPosLeft], a            ; 4261

;; Position = 11 bytes: for ch1..ch3 [dw track pointer] [transpose],
;; then [dw track pointer] for ch4 (no transpose).
ReadPosition:
    ld a, [hl+]                 ; 4264
    ld [wCh1_TrackPtrLo], a     ; 4265
    ld a, [hl+]                 ; 4268
    ld [wCh1_TrackPtrHi], a     ; 4269
    ld a, [hl+]                 ; 426C
    ld [wCh1_Transpose], a      ; 426D
    ld a, [hl+]                 ; 4270
    ld [wCh2_TrackPtrLo], a     ; 4271
    ld a, [hl+]                 ; 4274
    ld [wCh2_TrackPtrHi], a     ; 4275
    ld a, [hl+]                 ; 4278
    ld [wCh2_Transpose], a      ; 4279
    ld a, [hl+]                 ; 427C
    ld [wCh3_TrackPtrLo], a     ; 427D
    ld a, [hl+]                 ; 4280
    ld [wCh3_TrackPtrHi], a     ; 4281
    ld a, [hl+]                 ; 4284
    ld [wCh3_Transpose], a      ; 4285
    ld a, [hl+]                 ; 4288
    ld [wCh4_TrackPtrLo], a     ; 4289
    ld a, [hl+]                 ; 428C
    ld [wCh4_TrackPtrHi], a     ; 428D
    ld a, l                     ; 4290
    ld [wPosPtrLo], a           ; 4291
    ld a, h                     ; 4294
    ld [wPosPtrHi], a           ; 4295

;; New row on channel 1. Row = [note|$40: ins byte follows|$80: fx byte follows]
;; [ins] [fx]. The fx byte is decoded on all channels, even while an SFX owns
;; the channel: $8x sets wReturnFlag, $Fx sets the speed (ticks per row).
Row_Ch1:
    ld hl, wRowsLeft            ; 4298
    dec [hl]                    ; 429B
    ld a, [wCh1_TrackPtrLo]     ; 429C
    ld l, a                     ; 429F
    ld a, [wCh1_TrackPtrHi]     ; 42A0
    ld h, a                     ; 42A3
    ld a, [hl+]                 ; 42A4
    ld [wCh1_RowNote], a        ; 42A5
    ld e, a                     ; 42A8
    bit 6, e                    ; 42A9
    jr z, .L42B1                ; 42AB
    ld a, [hl+]                 ; 42AD
    ld [wCh1_RowIns], a         ; 42AE
.L42B1:
    bit 7, e                    ; 42B1
    jr z, .L42B9                ; 42B3
    ld a, [hl+]                 ; 42B5
    ld [wCh1_RowFx], a          ; 42B6
.L42B9:
    ld a, l                     ; 42B9
    ld [wCh1_TrackPtrLo], a     ; 42BA
    ld a, h                     ; 42BD
    ld [wCh1_TrackPtrHi], a     ; 42BE
    bit 7, e                    ; 42C1
    jr z, Row_Ch1_Decode        ; 42C3
    ld a, [wCh1_RowFx]          ; 42C5
    ld c, a                     ; 42C8
    swap c                      ; 42C9
    and $0F                     ; 42CB
    sub $08                     ; 42CD
    jr nz, .L42D7               ; 42CF
    ld a, c                     ; 42D1
    and $0F                     ; 42D2
    ld [wReturnFlag], a         ; 42D4
.L42D7:
    sub $07                     ; 42D7
    jr nz, Row_Ch1_Decode       ; 42D9
    ld a, c                     ; 42DB
    and $0F                     ; 42DC
    ld [wSpeed], a              ; 42DE

;; The music is muted on a channel while its SFXTimer <> 0.
Row_Ch1_Decode:
    ld a, [wCh1_SFXTimer]       ; 42E1
    or a                        ; 42E4
    jp nz, Row_Ch2              ; 42E5
    ld a, e                     ; 42E8
    and $3F                     ; 42E9
    jr z, .L42F0                ; 42EB
    ld [wCh1_Note], a           ; 42ED

;; Instrument byte: bits 0-5 = instrument+1 (0 = change the volume only),
;; bits 6-7 = volume shift (envelope volume >> 0/1/2/4: full, 1/2, 1/4, off).
.L42F0:
    bit 6, e                    ; 42F0
    jp z, Row_Ch2               ; 42F2
    ld a, [wCh1_RowIns]         ; 42F5
    and $3F                     ; 42F8
    jp nz, Row_Ch1_LoadIns      ; 42FA
    ld a, [wCh1_RowIns]         ; 42FD
    and $C0                     ; 4300
    jr z, .L432A                ; 4302
    rlc a                       ; 4304
    rlc a                       ; 4306
    ld [wCh1_VolShift], a       ; 4308
    ld c, a                     ; 430B
    ldh a, [rNR12]              ; 430C
    and $0F                     ; 430E
    ld d, a                     ; 4310
    ldh a, [rNR12]              ; 4311
    inc c                       ; 4313
    dec c                       ; 4314
    jr z, .L4325                ; 4315
    dec c                       ; 4317
    jr z, .L4323                ; 4318
    dec c                       ; 431A
    jr z, .L4321                ; 431B
    srl a                       ; 431D
    srl a                       ; 431F
.L4321:
    srl a                       ; 4321
.L4323:
    srl a                       ; 4323
.L4325:
    and $F0                     ; 4325
    or d                        ; 4327
    ldh [rNR12], a              ; 4328
.L432A:
    jp Row_Ch1_Trigger          ; 432A

;; Square instrument: [flags: bits 0-5 = playlist steps] [playlist speed,
;; bit 7 = vibrato bytes follow] [NRx2 envelope] ([vibrato delay]
;; [depth<<4 | speed]) followed by the 3-byte playlist steps.
Row_Ch1_LoadIns:
    dec a                       ; 432D
    ld c, a                     ; 432E
    ld a, [wCh1_RowIns]         ; 432F
    and $C0                     ; 4332
    rlc a                       ; 4334
    rlc a                       ; 4336
    ld [wCh1_VolShift], a       ; 4338
    ld a, [wHdr_InstsLo]        ; 433B
    ld l, a                     ; 433E
    ld a, [wHdr_InstsHi]        ; 433F
    ld h, a                     ; 4342
    add hl, bc                  ; 4343
    add hl, bc                  ; 4344
    ld a, [hl+]                 ; 4345
    ld c, a                     ; 4346
    ld a, [hl+]                 ; 4347
    ld h, a                     ; 4348
    ld l, c                     ; 4349
    ld a, [hl+]                 ; 434A
    ld [wCh1_InsFlags], a       ; 434B
    ld d, a                     ; 434E
    ld a, [hl+]                 ; 434F
    ld [wCh1_PLSpeed], a        ; 4350
    xor a                       ; 4353
    ld [wCh1_PLTimer], a        ; 4354
    ld a, $80                   ; 4357
    ldh [rNR11], a              ; 4359
    ld a, [wCh1_VolShift]       ; 435B
    ld c, a                     ; 435E
    ld a, [hl]                  ; 435F
    and $0F                     ; 4360
    ld e, a                     ; 4362
    ld a, [hl+]                 ; 4363
    inc c                       ; 4364
    dec c                       ; 4365
    jr z, .L4376                ; 4366
    dec c                       ; 4368
    jr z, .L4374                ; 4369
    dec c                       ; 436B
    jr z, .L4372                ; 436C
    srl a                       ; 436E
    srl a                       ; 4370
.L4372:
    srl a                       ; 4372
.L4374:
    srl a                       ; 4374
.L4376:
    and $F0                     ; 4376
    or e                        ; 4378
    ldh [rNR12], a              ; 4379
    ld a, [wCh1_PLSpeed]        ; 437B
    bit 7, a                    ; 437E
    jr z, .L4396                ; 4380
    ld a, [hl+]                 ; 4382
    ld [wCh1_VibDelay], a       ; 4383
    ld a, [hl+]                 ; 4386
    ld c, a                     ; 4387
    and $0F                     ; 4388
    ld [wCh1_VibSpeed], a       ; 438A
    ld a, c                     ; 438D
    and $F0                     ; 438E
    ld [wCh1_VibDepth], a       ; 4390
    xor a                       ; 4393
    jr .L43A0                   ; 4394
.L4396:
    xor a                       ; 4396
    ld [wCh1_VibDelay], a       ; 4397
    ld [wCh1_VibDepth], a       ; 439A
    ld [wCh1_VibSpeed], a       ; 439D
.L43A0:
    ld [wCh1_VibPhase], a       ; 43A0
    ld a, d                     ; 43A3
    and $3F                     ; 43A4
    ld [wCh1_PLSteps], a        ; 43A6
    ld a, l                     ; 43A9
    ld [wCh1_PLPtrLo], a        ; 43AA
    ld a, h                     ; 43AD
    ld [wCh1_PLPtrHi], a        ; 43AE

;; Retrigger the channel (NRx4 bit 7).
Row_Ch1_Trigger:
    ld hl, rNR14                ; 43B1
    set 7, [hl]                 ; 43B4
Row_Ch2:
    ld a, [wCh2_TrackPtrLo]     ; 43B6
    ld l, a                     ; 43B9
    ld a, [wCh2_TrackPtrHi]     ; 43BA
    ld h, a                     ; 43BD
    ld a, [hl+]                 ; 43BE
    ld [wCh2_RowNote], a        ; 43BF
    ld e, a                     ; 43C2
    bit 6, e                    ; 43C3
    jr z, .L43CB                ; 43C5
    ld a, [hl+]                 ; 43C7
    ld [wCh2_RowIns], a         ; 43C8
.L43CB:
    bit 7, e                    ; 43CB
    jr z, .L43D3                ; 43CD
    ld a, [hl+]                 ; 43CF
    ld [wCh2_RowFx], a          ; 43D0
.L43D3:
    ld a, l                     ; 43D3
    ld [wCh2_TrackPtrLo], a     ; 43D4
    ld a, h                     ; 43D7
    ld [wCh2_TrackPtrHi], a     ; 43D8
    bit 7, e                    ; 43DB
    jr z, Row_Ch2_Decode        ; 43DD
    ld a, [wCh2_RowFx]          ; 43DF
    ld c, a                     ; 43E2
    swap c                      ; 43E3
    and $0F                     ; 43E5
    sub $08                     ; 43E7
    jr nz, .L43F1               ; 43E9
    ld a, c                     ; 43EB
    and $0F                     ; 43EC
    ld [wReturnFlag], a         ; 43EE
.L43F1:
    sub $07                     ; 43F1
    jr nz, Row_Ch2_Decode       ; 43F3
    ld a, c                     ; 43F5
    and $0F                     ; 43F6
    ld [wSpeed], a              ; 43F8
Row_Ch2_Decode:
    ld a, [wCh2_SFXTimer]       ; 43FB
    or a                        ; 43FE
    jp nz, Row_Ch3              ; 43FF
    ld a, e                     ; 4402
    and $3F                     ; 4403
    jr z, .L440A                ; 4405
    ld [wCh2_Note], a           ; 4407
.L440A:
    bit 6, e                    ; 440A
    jp z, Row_Ch3               ; 440C
    ld a, [wCh2_RowIns]         ; 440F
    and $3F                     ; 4412
    jp nz, Row_Ch2_LoadIns      ; 4414
    ld a, [wCh2_RowIns]         ; 4417
    and $C0                     ; 441A
    jr z, .L4444                ; 441C
    rlc a                       ; 441E
    rlc a                       ; 4420
    ld [wCh2_VolShift], a       ; 4422
    ld c, a                     ; 4425
    ldh a, [rNR22]              ; 4426
    and $0F                     ; 4428
    ld d, a                     ; 442A
    ldh a, [rNR22]              ; 442B
    inc c                       ; 442D
    dec c                       ; 442E
    jr z, .L443F                ; 442F
    dec c                       ; 4431
    jr z, .L443D                ; 4432
    dec c                       ; 4434
    jr z, .L443B                ; 4435
    srl a                       ; 4437
    srl a                       ; 4439
.L443B:
    srl a                       ; 443B
.L443D:
    srl a                       ; 443D
.L443F:
    and $F0                     ; 443F
    or d                        ; 4441
    ldh [rNR22], a              ; 4442
.L4444:
    jp Row_Ch2_Trigger          ; 4444
Row_Ch2_LoadIns:
    dec a                       ; 4447
    ld c, a                     ; 4448
    ld a, [wCh2_RowIns]         ; 4449
    and $C0                     ; 444C
    rlc a                       ; 444E
    rlc a                       ; 4450
    ld [wCh2_VolShift], a       ; 4452
    ld a, [wHdr_InstsLo]        ; 4455
    ld l, a                     ; 4458
    ld a, [wHdr_InstsHi]        ; 4459
    ld h, a                     ; 445C
    add hl, bc                  ; 445D
    add hl, bc                  ; 445E
    ld a, [hl+]                 ; 445F
    ld c, a                     ; 4460
    ld a, [hl+]                 ; 4461
    ld h, a                     ; 4462
    ld l, c                     ; 4463
    ld a, [hl+]                 ; 4464
    ld [wCh2_InsFlags], a       ; 4465
    ld d, a                     ; 4468
    ld a, [hl+]                 ; 4469
    ld [wCh2_PLSpeed], a        ; 446A
    xor a                       ; 446D
    ld [wCh2_PLTimer], a        ; 446E
    ld a, $80                   ; 4471
    ldh [rNR21], a              ; 4473
    ld a, [wCh2_VolShift]       ; 4475
    ld c, a                     ; 4478
    ld a, [hl]                  ; 4479
    and $0F                     ; 447A
    ld e, a                     ; 447C
    ld a, [hl+]                 ; 447D
    inc c                       ; 447E
    dec c                       ; 447F
    jr z, .L4490                ; 4480
    dec c                       ; 4482
    jr z, .L448E                ; 4483
    dec c                       ; 4485
    jr z, .L448C                ; 4486
    srl a                       ; 4488
    srl a                       ; 448A
.L448C:
    srl a                       ; 448C
.L448E:
    srl a                       ; 448E
.L4490:
    and $F0                     ; 4490
    or e                        ; 4492
    ldh [rNR22], a              ; 4493
    ld a, [wCh2_PLSpeed]        ; 4495
    bit 7, a                    ; 4498
    jr z, .L44B0                ; 449A
    ld a, [hl+]                 ; 449C
    ld [wCh2_VibDelay], a       ; 449D
    ld a, [hl+]                 ; 44A0
    ld c, a                     ; 44A1
    and $0F                     ; 44A2
    ld [wCh2_VibSpeed], a       ; 44A4
    ld a, c                     ; 44A7
    and $F0                     ; 44A8
    ld [wCh2_VibDepth], a       ; 44AA
    xor a                       ; 44AD
    jr .L44BA                   ; 44AE
.L44B0:
    xor a                       ; 44B0
    ld [wCh2_VibDelay], a       ; 44B1
    ld [wCh2_VibDepth], a       ; 44B4
    ld [wCh2_VibSpeed], a       ; 44B7
.L44BA:
    ld [wCh2_VibPhase], a       ; 44BA
    ld a, d                     ; 44BD
    and $3F                     ; 44BE
    ld [wCh2_PLSteps], a        ; 44C0
    ld a, l                     ; 44C3
    ld [wCh2_PLPtrLo], a        ; 44C4
    ld a, h                     ; 44C7
    ld [wCh2_PLPtrHi], a        ; 44C8
Row_Ch2_Trigger:
    ld hl, rNR24                ; 44CB
    set 7, [hl]                 ; 44CE

;; New row on channel 3 (wave).
Row_Ch3:
    ld a, [wCh3_TrackPtrLo]     ; 44D0
    ld l, a                     ; 44D3
    ld a, [wCh3_TrackPtrHi]     ; 44D4
    ld h, a                     ; 44D7
    ld a, [hl+]                 ; 44D8
    ld [wCh3_RowNote], a        ; 44D9
    ld e, a                     ; 44DC
    bit 6, e                    ; 44DD
    jr z, .L44E5                ; 44DF
    ld a, [hl+]                 ; 44E1
    ld [wCh3_RowIns], a         ; 44E2
.L44E5:
    bit 7, e                    ; 44E5
    jr z, .L44ED                ; 44E7
    ld a, [hl+]                 ; 44E9
    ld [wCh3_RowFx], a          ; 44EA
.L44ED:
    ld a, l                     ; 44ED
    ld [wCh3_TrackPtrLo], a     ; 44EE
    ld a, h                     ; 44F1
    ld [wCh3_TrackPtrHi], a     ; 44F2
    bit 7, e                    ; 44F5
    jr z, Row_Ch3_Decode        ; 44F7
    ld a, [wCh3_RowFx]          ; 44F9
    ld c, a                     ; 44FC
    swap c                      ; 44FD
    and $0F                     ; 44FF
    sub $08                     ; 4501
    jr nz, .L450B               ; 4503
    ld a, c                     ; 4505
    and $0F                     ; 4506
    ld [wReturnFlag], a         ; 4508
.L450B:
    sub $07                     ; 450B
    jr nz, Row_Ch3_Decode       ; 450D
    ld a, c                     ; 450F
    and $0F                     ; 4510
    ld [wSpeed], a              ; 4512
Row_Ch3_Decode:
    ld a, [wCh3_SFXTimer]       ; 4515
    or a                        ; 4518
    jp nz, Row_Ch4              ; 4519
    ld a, e                     ; 451C
    and $3F                     ; 451D
    jr z, .L4524                ; 451F
    ld [wCh3_Note], a           ; 4521
.L4524:
    bit 6, e                    ; 4524
    jp z, Row_Ch4               ; 4526

;; Ch3: the two volume bits select the NR32 level directly (1 = 25%, 2 = 50%,
;; 3 = 100%); 0 keeps the instrument's level, or mutes on a volume-only row.
    ld a, [wCh3_RowIns]         ; 4529
    and $3F                     ; 452C
    jp nz, Row_Ch3_LoadIns      ; 452E
    ld a, [wCh3_RowIns]         ; 4531
    rrc a                       ; 4534
    jr z, .L453E                ; 4536
    cp $40                      ; 4538
    jr z, .L453E                ; 453A
    xor $40                     ; 453C
.L453E:
    ldh [rNR32], a              ; 453E
    jp Row_Ch4                  ; 4540

;; Wave instrument: [flags: bits 0-5 steps, bits 6-7 <> 0 = "PCM" (ch3 is left
;; to the game: wWave_PCMFlag mutes the ch3 tick)] [speed] [NR32] (vibrato)
;; [sweep step] [flag byte] [dw position] [dw lower] [dw upper] [sweep speed]
;; [base lo] [base hi] + steps. 16 bytes at base+position are copied to wave
;; RAM; with the sweep on (playlist command $C0 toggles it) the position moves
;; by "step" every "sweep speed" ticks and bounces between lower and upper.
Row_Ch3_LoadIns:
    dec a                       ; 4543
    ld c, a                     ; 4544
    ld a, [wCh3_RowIns]         ; 4545
    and $C0                     ; 4548
    jr z, .L4554                ; 454A
    rrc a                       ; 454C
    cp $40                      ; 454E
    jr z, .L4554                ; 4550
    xor $40                     ; 4552
.L4554:
    ld [wCh3_VolShift], a       ; 4554
    ld a, [wHdr_InstsLo]        ; 4557
    ld l, a                     ; 455A
    ld a, [wHdr_InstsHi]        ; 455B
    ld h, a                     ; 455E
    add hl, bc                  ; 455F
    add hl, bc                  ; 4560
    ld a, [hl+]                 ; 4561
    ld c, a                     ; 4562
    ld a, [hl+]                 ; 4563
    ld h, a                     ; 4564
    ld l, c                     ; 4565
    ld a, [hl+]                 ; 4566
    ld [wCh3_InsFlags], a       ; 4567
    ld d, a                     ; 456A
    and $C0                     ; 456B
    ld [wWave_PCMFlag], a       ; 456D
    ld a, [hl+]                 ; 4570
    ld [wCh3_PLSpeed], a        ; 4571
    xor a                       ; 4574
    ld [wCh3_PLTimer], a        ; 4575
    ld a, [wCh3_VolShift]       ; 4578
    or a                        ; 457B
    jr z, .L4581                ; 457C
    inc hl                      ; 457E
    jr .L4587                   ; 457F
.L4581:
    ld a, [hl+]                 ; 4581
    ld [wCh3_Level], a          ; 4582
    and $FE                     ; 4585
.L4587:
    ldh [rNR32], a              ; 4587
    xor a                       ; 4589
    ld [wCh3_VolShift], a       ; 458A
    ld a, [wCh3_PLSpeed]        ; 458D
    bit 7, a                    ; 4590
    jr z, .L45A8                ; 4592
    ld a, [hl+]                 ; 4594
    ld [wCh3_VibDelay], a       ; 4595
    ld a, [hl+]                 ; 4598
    ld c, a                     ; 4599
    and $0F                     ; 459A
    ld [wCh3_VibSpeed], a       ; 459C
    ld a, c                     ; 459F
    and $F0                     ; 45A0
    ld [wCh3_VibDepth], a       ; 45A2
    xor a                       ; 45A5
    jr .L45B2                   ; 45A6
.L45A8:
    xor a                       ; 45A8
    ld [wCh3_VibDelay], a       ; 45A9
    ld [wCh3_VibDepth], a       ; 45AC
    ld [wCh3_VibSpeed], a       ; 45AF
.L45B2:
    ld [wCh3_VibPhase], a       ; 45B2
    ld a, [hl+]                 ; 45B5
    ld [wWave_Step], a          ; 45B6
    xor a                       ; 45B9
    ld [wWave_SweepOn], a       ; 45BA
    ld [wWave_FlagHi], a        ; 45BD
    ld a, [hl+]                 ; 45C0
    bit 7, a                    ; 45C1
    jr z, .L45C8                ; 45C3
    ld [wWave_FlagHi], a        ; 45C5
.L45C8:
    and $7F                     ; 45C8
    ld [wWave_FlagLo], a        ; 45CA
    ld a, [hl+]                 ; 45CD
    ld [wWave_PosLo], a         ; 45CE
    ld a, [hl+]                 ; 45D1
    ld [wWave_PosHi], a         ; 45D2
    ld a, [hl+]                 ; 45D5
    ld [wWave_LowerLo], a       ; 45D6
    ld a, [hl+]                 ; 45D9
    ld [wWave_LowerHi], a       ; 45DA
    ld a, [hl+]                 ; 45DD
    ld [wWave_UpperLo], a       ; 45DE
    ld a, [hl+]                 ; 45E1
    ld [wWave_UpperHi], a       ; 45E2
    ld a, [hl+]                 ; 45E5
    ld [wWave_SweepSpeed], a    ; 45E6
    ld [wWave_SweepTimer], a    ; 45E9
    ld a, [hl+]                 ; 45EC
    ld [wWave_BaseLo], a        ; 45ED
    ld a, [hl+]                 ; 45F0
    ld [wWave_BaseHi], a        ; 45F1
    ld a, d                     ; 45F4
    and $3F                     ; 45F5
    ld [wCh3_PLSteps], a        ; 45F7
    ld a, l                     ; 45FA
    ld [wCh3_PLPtrLo], a        ; 45FB
    ld a, h                     ; 45FE
    ld [wCh3_PLPtrHi], a        ; 45FF
    ld a, $FF                   ; 4602
    ld [wWave_WaveUpdate], a    ; 4604

;; New row on channel 4 (noise). Instrument: [flags] [speed] [NR42] + steps.
Row_Ch4:
    ld a, [wCh4_TrackPtrLo]     ; 4607
    ld l, a                     ; 460A
    ld a, [wCh4_TrackPtrHi]     ; 460B
    ld h, a                     ; 460E
    ld a, [hl+]                 ; 460F
    ld [wCh4_RowNote], a        ; 4610
    ld e, a                     ; 4613
    bit 6, e                    ; 4614
    jr z, .L461C                ; 4616
    ld a, [hl+]                 ; 4618
    ld [wCh4_RowIns], a         ; 4619
.L461C:
    bit 7, e                    ; 461C
    jr z, .L4624                ; 461E
    ld a, [hl+]                 ; 4620
    ld [wCh4_RowFx], a          ; 4621
.L4624:
    ld a, l                     ; 4624
    ld [wCh4_TrackPtrLo], a     ; 4625
    ld a, h                     ; 4628
    ld [wCh4_TrackPtrHi], a     ; 4629
    bit 7, e                    ; 462C
    jr z, Row_Ch4_Decode        ; 462E
    ld a, [wCh4_RowFx]          ; 4630
    ld c, a                     ; 4633
    swap c                      ; 4634
    and $0F                     ; 4636
    sub $08                     ; 4638
    jr nz, .L4642               ; 463A
    ld a, c                     ; 463C
    and $0F                     ; 463D
    ld [wReturnFlag], a         ; 463F
.L4642:
    sub $07                     ; 4642
    jr nz, Row_Ch4_Decode       ; 4644
    ld a, c                     ; 4646
    and $0F                     ; 4647
    ld [wSpeed], a              ; 4649
Row_Ch4_Decode:
    ld a, [wCh4_SFXTimer]       ; 464C
    or a                        ; 464F
    jp nz, Row_Done             ; 4650
    ld a, e                     ; 4653
    and $3F                     ; 4654
    jr z, .L465B                ; 4656
    ld [wCh4_Note], a           ; 4658
.L465B:
    bit 6, e                    ; 465B
    jp z, Row_Done              ; 465D
    ld a, [wCh4_RowIns]         ; 4660
    and $3F                     ; 4663
    jp nz, Row_Ch4_LoadIns      ; 4665
    ld a, [wCh4_RowIns]         ; 4668
    and $C0                     ; 466B
    jr z, .L4695                ; 466D
    rlc a                       ; 466F
    rlc a                       ; 4671
    ld [wCh4_VolShift], a       ; 4673
    ld c, a                     ; 4676
    ldh a, [rNR42]              ; 4677
    and $0F                     ; 4679
    ld d, a                     ; 467B
    ldh a, [rNR42]              ; 467C
    inc c                       ; 467E
    dec c                       ; 467F
    jr z, .L4690                ; 4680
    dec c                       ; 4682
    jr z, .L468E                ; 4683
    dec c                       ; 4685
    jr z, .L468C                ; 4686
    srl a                       ; 4688
    srl a                       ; 468A
.L468C:
    srl a                       ; 468C
.L468E:
    srl a                       ; 468E
.L4690:
    and $F0                     ; 4690
    or d                        ; 4692
    ldh [rNR42], a              ; 4693
.L4695:
    jp Row_Ch4_Trigger          ; 4695
Row_Ch4_LoadIns:
    dec a                       ; 4698
    ld c, a                     ; 4699
    ld a, [wCh4_RowIns]         ; 469A
    and $C0                     ; 469D
    rlc a                       ; 469F
    rlc a                       ; 46A1
    ld [wCh4_VolShift], a       ; 46A3
    ld a, [wHdr_InstsLo]        ; 46A6
    ld l, a                     ; 46A9
    ld a, [wHdr_InstsHi]        ; 46AA
    ld h, a                     ; 46AD
    add hl, bc                  ; 46AE
    add hl, bc                  ; 46AF
    ld a, [hl+]                 ; 46B0
    ld c, a                     ; 46B1
    ld a, [hl+]                 ; 46B2
    ld h, a                     ; 46B3
    ld l, c                     ; 46B4
    ld a, [hl+]                 ; 46B5
    ld [wCh4_InsFlags], a       ; 46B6
    ld d, a                     ; 46B9
    ld a, [hl+]                 ; 46BA
    ld [wCh4_PLSpeed], a        ; 46BB
    xor a                       ; 46BE
    ld [wCh4_PLTimer], a        ; 46BF
    ld a, $00                   ; 46C2
    ldh [rNR41], a              ; 46C4
    ld a, [wCh4_VolShift]       ; 46C6
    ld c, a                     ; 46C9
    ld a, [hl]                  ; 46CA
    and $0F                     ; 46CB
    ld e, a                     ; 46CD
    ld a, [hl+]                 ; 46CE
    inc c                       ; 46CF
    dec c                       ; 46D0
    jr z, .L46E1                ; 46D1
    dec c                       ; 46D3
    jr z, .L46DF                ; 46D4
    dec c                       ; 46D6
    jr z, .L46DD                ; 46D7
    srl a                       ; 46D9
    srl a                       ; 46DB
.L46DD:
    srl a                       ; 46DD
.L46DF:
    srl a                       ; 46DF
.L46E1:
    and $F0                     ; 46E1
    or e                        ; 46E3
    ldh [rNR42], a              ; 46E4
    ld a, d                     ; 46E6
    and $3F                     ; 46E7
    ld [wCh4_PLSteps], a        ; 46E9
    ld a, l                     ; 46EC
    ld [wCh4_PLPtrLo], a        ; 46ED
    ld a, h                     ; 46F0
    ld [wCh4_PLPtrHi], a        ; 46F1
Row_Ch4_Trigger:
    ld hl, rNR44                ; 46F4
    set 7, [hl]                 ; 46F7

;; Row done: wTickCount = speed - wSpeedAdjust.
Row_Done:
    ld a, [wSpeedAdjust]        ; 46F9
    ld c, a                     ; 46FC
    ld a, [wSpeed]              ; 46FD
    sub c                       ; 4700
    ld [wTickCount], a          ; 4701
Tick_Count:
    ld hl, wTickCount           ; 4704
    dec [hl]                    ; 4707

;; Per-tick processing of all four channels: instrument playlist, vibrato,
;; frequency. Playlist step = [note] [cmd] [cmd].
;; Note byte: bits 0-5 note (0 = keep), bit 6 = absolute note, otherwise
;; relative to the row note (+transpose; 1 = unison).
;; Command: $00 none, $01-$3F new playlist speed, $40|v volume v (NRx2
;; high nibble, retrigger; ch3: NR32 level), $80|n jump back n steps,
;; $C0|d duty d (ch1/2) / toggle the wave sweep (ch3).
Tick:
    ld a, [wCh1_SFXTimer]       ; 4708
    or a                        ; 470B
    jr z, Tick_Ch1              ; 470C
    dec a                       ; 470E
    ld [wCh1_SFXTimer], a       ; 470F

;; Channel 1 playlist.
Tick_Ch1:
    ld a, [wCh1_PLTimer]        ; 4712
    or a                        ; 4715
    jp nz, Tick_Ch1_Pitch       ; 4716
    ld a, [wCh1_PLSteps]        ; 4719
    or a                        ; 471C
    jp z, Tick_Ch1_PLWait       ; 471D
    dec a                       ; 4720
    ld [wCh1_PLSteps], a        ; 4721
    ld a, [wCh1_PLPtrLo]        ; 4724
    ld l, a                     ; 4727
    ld a, [wCh1_PLPtrHi]        ; 4728
    ld h, a                     ; 472B
    ld a, [hl+]                 ; 472C
    ld [wCh1_PLNoteRaw], a      ; 472D
    and $3F                     ; 4730
    jr z, .L4737                ; 4732
    ld [wCh1_PLNote], a         ; 4734
.L4737:
    ld a, [hl+]                 ; 4737
    bit 7, a                    ; 4738
    jr nz, .L4778               ; 473A
    bit 6, a                    ; 473C
    jr nz, .L474A               ; 473E
    and $3F                     ; 4740
    jr z, .L4747                ; 4742
    ld [wCh1_PLSpeed], a        ; 4744
.L4747:
    jp .L4799                   ; 4747
.L474A:
    swap a                      ; 474A
    ld d, a                     ; 474C
    ld a, [wCh1_VolShift]       ; 474D
    ld c, a                     ; 4750
    ld a, d                     ; 4751
    inc c                       ; 4752
    dec c                       ; 4753
    jr z, .L4764                ; 4754
    dec c                       ; 4756
    jr z, .L4762                ; 4757
    dec c                       ; 4759
    jr z, .L4760                ; 475A
    srl a                       ; 475C
    srl a                       ; 475E
.L4760:
    srl a                       ; 4760
.L4762:
    srl a                       ; 4762
.L4764:
    and $F0                     ; 4764
    ld c, a                     ; 4766
    ldh a, [rNR12]              ; 4767
    and $0F                     ; 4769
    or c                        ; 476B
    ldh [rNR12], a              ; 476C
    push hl                     ; 476E
    ld hl, rNR14                ; 476F
    set 7, [hl]                 ; 4772
    pop hl                      ; 4774
    jp .L4799                   ; 4775
.L4778:
    bit 6, a                    ; 4778
    jr nz, .L4791               ; 477A
    and $3F                     ; 477C
    ld d, a                     ; 477E
    cpl                         ; 477F
    inc a                       ; 4780
    ld c, a                     ; 4781
    dec b                       ; 4782
    add hl, bc                  ; 4783
    add hl, bc                  ; 4784
    add hl, bc                  ; 4785
    inc b                       ; 4786
    ld a, [wCh1_PLSteps]        ; 4787
    ld c, d                     ; 478A
    add a,c                     ; 478B
    ld [wCh1_PLSteps], a        ; 478C
    jr .L4799                   ; 478F
.L4791:
    and $3F                     ; 4791
    rrc a                       ; 4793
    rrc a                       ; 4795
    ldh [rNR11], a              ; 4797
.L4799:
    ld a, [hl+]                 ; 4799
    bit 7, a                    ; 479A
    jr nz, .L47DA               ; 479C
    bit 6, a                    ; 479E
    jr nz, .L47AC               ; 47A0
    and $3F                     ; 47A2
    jr z, .L47A9                ; 47A4
    ld [wCh1_PLSpeed], a        ; 47A6
.L47A9:
    jp .L47FB                   ; 47A9
.L47AC:
    swap a                      ; 47AC
    ld d, a                     ; 47AE
    ld a, [wCh1_VolShift]       ; 47AF
    ld c, a                     ; 47B2
    ld a, d                     ; 47B3
    inc c                       ; 47B4
    dec c                       ; 47B5
    jr z, .L47C6                ; 47B6
    dec c                       ; 47B8
    jr z, .L47C4                ; 47B9
    dec c                       ; 47BB
    jr z, .L47C2                ; 47BC
    srl a                       ; 47BE
    srl a                       ; 47C0
.L47C2:
    srl a                       ; 47C2
.L47C4:
    srl a                       ; 47C4
.L47C6:
    and $F0                     ; 47C6
    ld c, a                     ; 47C8
    ldh a, [rNR12]              ; 47C9
    and $0F                     ; 47CB
    or c                        ; 47CD
    ldh [rNR12], a              ; 47CE
    push hl                     ; 47D0
    ld hl, rNR14                ; 47D1
    set 7, [hl]                 ; 47D4
    pop hl                      ; 47D6
    jp .L47FB                   ; 47D7
.L47DA:
    bit 6, a                    ; 47DA
    jr nz, .L47F3               ; 47DC
    and $3F                     ; 47DE
    ld d, a                     ; 47E0
    cpl                         ; 47E1
    inc a                       ; 47E2
    ld c, a                     ; 47E3
    dec b                       ; 47E4
    add hl, bc                  ; 47E5
    add hl, bc                  ; 47E6
    add hl, bc                  ; 47E7
    inc b                       ; 47E8
    ld a, [wCh1_PLSteps]        ; 47E9
    ld c, d                     ; 47EC
    add a,c                     ; 47ED
    ld [wCh1_PLSteps], a        ; 47EE
    jr .L47FB                   ; 47F1
.L47F3:
    and $3F                     ; 47F3
    rrc a                       ; 47F5
    rrc a                       ; 47F7
    ldh [rNR11], a              ; 47F9
.L47FB:
    ld a, l                     ; 47FB
    ld [wCh1_PLPtrLo], a        ; 47FC
    ld a, h                     ; 47FF
    ld [wCh1_PLPtrHi], a        ; 4800
Tick_Ch1_PLWait:
    ld a, [wCh1_PLSpeed]        ; 4803
    res 7, a                    ; 4806
    ld [wCh1_PLTimer], a        ; 4808

;; Frequency = FreqTable[transpose + row note + playlist note - 1] (or the
;; absolute playlist note) + vibrato. Vibrato: after VibDelay ticks the phase
;; advances by VibSpeed (6 bits) and VibratoTable[depth | phase>>2] is added.
Tick_Ch1_Pitch:
    ld hl, wCh1_PLTimer         ; 480B
    dec [hl]                    ; 480E
    ld a, [wCh1_PLNote]         ; 480F
    ld c, a                     ; 4812
    ld a, [wCh1_PLNoteRaw]      ; 4813
    bit 6, a                    ; 4816
    jr nz, .L4825               ; 4818
    ld a, [wCh1_Transpose]      ; 481A
    add a,c                     ; 481D
    ld c, a                     ; 481E
    ld a, [wCh1_Note]           ; 481F
    add a,c                     ; 4822
    dec a                       ; 4823
    ld c, a                     ; 4824
.L4825:
    ld hl, FreqTable            ; 4825
    add hl, bc                  ; 4828
    add hl, bc                  ; 4829
    ld c, $00                   ; 482A
    ld a, [wCh1_VibDepth]       ; 482C
    or a                        ; 482F
    jr z, .L4863                ; 4830
    ld a, [wCh1_VibDelay]       ; 4832
    dec a                       ; 4835
    cp $FF                      ; 4836
    jr z, .L483F                ; 4838
    ld [wCh1_VibDelay], a       ; 483A
    jr .L4863                   ; 483D
.L483F:
    ld a, [wCh1_VibSpeed]       ; 483F
    ld c, a                     ; 4842
    ld a, [wCh1_VibPhase]       ; 4843
    add a,c                     ; 4846
    and $3F                     ; 4847
    ld [wCh1_VibPhase], a       ; 4849
    srl a                       ; 484C
    srl a                       ; 484E
    ld c, a                     ; 4850
    ld a, [wCh1_VibDepth]       ; 4851
    or c                        ; 4854
    ld c, a                     ; 4855
    push hl                     ; 4856
    ld hl, VibratoTable         ; 4857
    add hl, bc                  ; 485A
    ld a, [hl]                  ; 485B
    pop hl                      ; 485C
    ld c, a                     ; 485D
    bit 7, a                    ; 485E
    jr z, .L4863                ; 4860
    dec b                       ; 4862
.L4863:
    ld a, [hl+]                 ; 4863
    ld e, a                     ; 4864
    ld a, [hl]                  ; 4865
    ld h, a                     ; 4866
    ld l, e                     ; 4867
    add hl, bc                  ; 4868
    ld b, $00                   ; 4869
    ld a, l                     ; 486B
    ldh [rNR13], a              ; 486C
    ld a, h                     ; 486E
    ldh [rNR14], a              ; 486F

;; Channel 2 tick.
Tick_Ch2:
    ld a, [wCh2_SFXTimer]       ; 4871
    or a                        ; 4874
    jr z, .L487B                ; 4875
    dec a                       ; 4877
    ld [wCh2_SFXTimer], a       ; 4878
.L487B:
    ld a, [wCh2_PLTimer]        ; 487B
    or a                        ; 487E
    jp nz, Tick_Ch2_Pitch       ; 487F
    ld a, [wCh2_PLSteps]        ; 4882
    or a                        ; 4885
    jp z, Tick_Ch2_PLWait       ; 4886
    dec a                       ; 4889
    ld [wCh2_PLSteps], a        ; 488A
    ld a, [wCh2_PLPtrLo]        ; 488D
    ld l, a                     ; 4890
    ld a, [wCh2_PLPtrHi]        ; 4891
    ld h, a                     ; 4894
    ld a, [hl+]                 ; 4895
    ld [wCh2_PLNoteRaw], a      ; 4896
    and $3F                     ; 4899
    jr z, .L48A0                ; 489B
    ld [wCh2_PLNote], a         ; 489D
.L48A0:
    ld a, [hl+]                 ; 48A0
    bit 7, a                    ; 48A1
    jr nz, .L48E1               ; 48A3
    bit 6, a                    ; 48A5
    jr nz, .L48B3               ; 48A7
    and $3F                     ; 48A9
    jr z, .L48B0                ; 48AB
    ld [wCh2_PLSpeed], a        ; 48AD
.L48B0:
    jp .L4902                   ; 48B0
.L48B3:
    swap a                      ; 48B3
    ld d, a                     ; 48B5
    ld a, [wCh2_VolShift]       ; 48B6
    ld c, a                     ; 48B9
    ld a, d                     ; 48BA
    inc c                       ; 48BB
    dec c                       ; 48BC
    jr z, .L48CD                ; 48BD
    dec c                       ; 48BF
    jr z, .L48CB                ; 48C0
    dec c                       ; 48C2
    jr z, .L48C9                ; 48C3
    srl a                       ; 48C5
    srl a                       ; 48C7
.L48C9:
    srl a                       ; 48C9
.L48CB:
    srl a                       ; 48CB
.L48CD:
    and $F0                     ; 48CD
    ld c, a                     ; 48CF
    ldh a, [rNR22]              ; 48D0
    and $0F                     ; 48D2
    or c                        ; 48D4
    ldh [rNR22], a              ; 48D5
    push hl                     ; 48D7
    ld hl, rNR24                ; 48D8
    set 7, [hl]                 ; 48DB
    pop hl                      ; 48DD
    jp .L4902                   ; 48DE
.L48E1:
    bit 6, a                    ; 48E1
    jr nz, .L48FA               ; 48E3
    and $3F                     ; 48E5
    ld d, a                     ; 48E7
    cpl                         ; 48E8
    inc a                       ; 48E9
    ld c, a                     ; 48EA
    dec b                       ; 48EB
    add hl, bc                  ; 48EC
    add hl, bc                  ; 48ED
    add hl, bc                  ; 48EE
    inc b                       ; 48EF
    ld a, [wCh2_PLSteps]        ; 48F0
    ld c, d                     ; 48F3
    add a,c                     ; 48F4
    ld [wCh2_PLSteps], a        ; 48F5
    jr .L4902                   ; 48F8
.L48FA:
    and $3F                     ; 48FA
    rrc a                       ; 48FC
    rrc a                       ; 48FE
    ldh [rNR21], a              ; 4900
.L4902:
    ld a, [hl+]                 ; 4902
    bit 7, a                    ; 4903
    jr nz, .L4943               ; 4905
    bit 6, a                    ; 4907
    jr nz, .L4915               ; 4909
    and $3F                     ; 490B
    jr z, .L4912                ; 490D
    ld [wCh2_PLSpeed], a        ; 490F
.L4912:
    jp .L4964                   ; 4912
.L4915:
    swap a                      ; 4915
    ld d, a                     ; 4917
    ld a, [wCh2_VolShift]       ; 4918
    ld c, a                     ; 491B
    ld a, d                     ; 491C
    inc c                       ; 491D
    dec c                       ; 491E
    jr z, .L492F                ; 491F
    dec c                       ; 4921
    jr z, .L492D                ; 4922
    dec c                       ; 4924
    jr z, .L492B                ; 4925
    srl a                       ; 4927
    srl a                       ; 4929
.L492B:
    srl a                       ; 492B
.L492D:
    srl a                       ; 492D
.L492F:
    and $F0                     ; 492F
    ld c, a                     ; 4931
    ldh a, [rNR22]              ; 4932
    and $0F                     ; 4934
    or c                        ; 4936
    ldh [rNR22], a              ; 4937
    push hl                     ; 4939
    ld hl, rNR24                ; 493A
    set 7, [hl]                 ; 493D
    pop hl                      ; 493F
    jp .L4964                   ; 4940
.L4943:
    bit 6, a                    ; 4943
    jr nz, .L495C               ; 4945
    and $3F                     ; 4947
    ld d, a                     ; 4949
    cpl                         ; 494A
    inc a                       ; 494B
    ld c, a                     ; 494C
    dec b                       ; 494D
    add hl, bc                  ; 494E
    add hl, bc                  ; 494F
    add hl, bc                  ; 4950
    inc b                       ; 4951
    ld a, [wCh2_PLSteps]        ; 4952
    ld c, d                     ; 4955
    add a,c                     ; 4956
    ld [wCh2_PLSteps], a        ; 4957
    jr .L4964                   ; 495A
.L495C:
    and $3F                     ; 495C
    rrc a                       ; 495E
    rrc a                       ; 4960
    ldh [rNR21], a              ; 4962
.L4964:
    ld a, l                     ; 4964
    ld [wCh2_PLPtrLo], a        ; 4965
    ld a, h                     ; 4968
    ld [wCh2_PLPtrHi], a        ; 4969
Tick_Ch2_PLWait:
    ld a, [wCh2_PLSpeed]        ; 496C
    res 7, a                    ; 496F
    ld [wCh2_PLTimer], a        ; 4971
Tick_Ch2_Pitch:
    ld hl, wCh2_PLTimer         ; 4974
    dec [hl]                    ; 4977
    ld a, [wCh2_PLNote]         ; 4978
    ld c, a                     ; 497B
    ld a, [wCh2_PLNoteRaw]      ; 497C
    bit 6, a                    ; 497F
    jr nz, .L498E               ; 4981
    ld a, [wCh2_Transpose]      ; 4983
    add a,c                     ; 4986
    ld c, a                     ; 4987
    ld a, [wCh2_Note]           ; 4988
    add a,c                     ; 498B
    dec a                       ; 498C
    ld c, a                     ; 498D
.L498E:
    ld hl, FreqTable            ; 498E
    add hl, bc                  ; 4991
    add hl, bc                  ; 4992
    ld c, $00                   ; 4993
    ld a, [wCh2_VibDepth]       ; 4995
    or a                        ; 4998
    jr z, .L49CC                ; 4999
    ld a, [wCh2_VibDelay]       ; 499B
    dec a                       ; 499E
    cp $FF                      ; 499F
    jr z, .L49A8                ; 49A1
    ld [wCh2_VibDelay], a       ; 49A3
    jr .L49CC                   ; 49A6
.L49A8:
    ld a, [wCh2_VibSpeed]       ; 49A8
    ld c, a                     ; 49AB
    ld a, [wCh2_VibPhase]       ; 49AC
    add a,c                     ; 49AF
    and $3F                     ; 49B0
    ld [wCh2_VibPhase], a       ; 49B2
    srl a                       ; 49B5
    srl a                       ; 49B7
    ld c, a                     ; 49B9
    ld a, [wCh2_VibDepth]       ; 49BA
    or c                        ; 49BD
    ld c, a                     ; 49BE
    push hl                     ; 49BF
    ld hl, VibratoTable         ; 49C0
    add hl, bc                  ; 49C3
    ld a, [hl]                  ; 49C4
    pop hl                      ; 49C5
    ld c, a                     ; 49C6
    bit 7, a                    ; 49C7
    jr z, .L49CC                ; 49C9
    dec b                       ; 49CB
.L49CC:
    ld a, [hl+]                 ; 49CC
    ld e, a                     ; 49CD
    ld a, [hl]                  ; 49CE
    ld h, a                     ; 49CF
    ld l, e                     ; 49D0
    add hl, bc                  ; 49D1
    ld b, $00                   ; 49D2
    ld a, l                     ; 49D4
    ldh [rNR23], a              ; 49D5
    ld a, h                     ; 49D7
    ldh [rNR24], a              ; 49D8

;; Channel 3 tick (skipped completely while wWave_PCMFlag is set).
Tick_Ch3:
    ld a, [wWave_PCMFlag]       ; 49DA
    or a                        ; 49DD
    jp nz, Tick_Ch4             ; 49DE
    ld a, [wCh3_SFXTimer]       ; 49E1
    or a                        ; 49E4
    jr z, .L49F0                ; 49E5
    cp $FF                      ; 49E7
    jp z, Tick_Ch4              ; 49E9
    dec a                       ; 49EC
    ld [wCh3_SFXTimer], a       ; 49ED
.L49F0:
    ld a, [wCh3_PLTimer]        ; 49F0
    or a                        ; 49F3
    jp nz, Tick_Ch3_Sweep       ; 49F4
    ld a, [wCh3_PLSteps]        ; 49F7
    or a                        ; 49FA
    jp z, Tick_Ch3_PLWait       ; 49FB
    dec a                       ; 49FE
    ld [wCh3_PLSteps], a        ; 49FF
    ld a, [wCh3_PLPtrLo]        ; 4A02
    ld l, a                     ; 4A05
    ld a, [wCh3_PLPtrHi]        ; 4A06
    ld h, a                     ; 4A09
    ld a, [hl+]                 ; 4A0A
    ld [wCh3_PLNoteRaw], a      ; 4A0B
    and $3F                     ; 4A0E
    jr z, .L4A15                ; 4A10
    ld [wCh3_PLNote], a         ; 4A12
.L4A15:
    ld a, [hl+]                 ; 4A15
    bit 7, a                    ; 4A16
    jr nz, .L4A3A               ; 4A18
    bit 6, a                    ; 4A1A
    jr nz, .L4A28               ; 4A1C
    and $3F                     ; 4A1E
    jr z, .L4A25                ; 4A20
    ld [wCh3_PLSpeed], a        ; 4A22
.L4A25:
    jp .L4A5A                   ; 4A25
.L4A28:
    and $3F                     ; 4A28
    jr z, .L4A35                ; 4A2A
    add a,a                     ; 4A2C
    swap a                      ; 4A2D
    cp $40                      ; 4A2F
    jr z, .L4A35                ; 4A31
    xor $40                     ; 4A33
.L4A35:
    ldh [rNR32], a              ; 4A35
    jp .L4A5A                   ; 4A37
.L4A3A:
    bit 6, a                    ; 4A3A
    jr nz, .L4A53               ; 4A3C
    and $3F                     ; 4A3E
    ld d, a                     ; 4A40
    cpl                         ; 4A41
    inc a                       ; 4A42
    ld c, a                     ; 4A43
    dec b                       ; 4A44
    add hl, bc                  ; 4A45
    add hl, bc                  ; 4A46
    add hl, bc                  ; 4A47
    inc b                       ; 4A48
    ld a, [wCh3_PLSteps]        ; 4A49
    ld c, d                     ; 4A4C
    add a,c                     ; 4A4D
    ld [wCh3_PLSteps], a        ; 4A4E
    jr .L4A5A                   ; 4A51
.L4A53:
    ld a, [wWave_SweepOn]       ; 4A53
    cpl                         ; 4A56
    ld [wWave_SweepOn], a       ; 4A57
.L4A5A:
    ld a, [hl+]                 ; 4A5A
    bit 7, a                    ; 4A5B
    jr nz, .L4A7F               ; 4A5D
    bit 6, a                    ; 4A5F
    jr nz, .L4A6D               ; 4A61
    and $3F                     ; 4A63
    jr z, .L4A6A                ; 4A65
    ld [wCh3_PLSpeed], a        ; 4A67
.L4A6A:
    jp .L4A9F                   ; 4A6A
.L4A6D:
    and $3F                     ; 4A6D
    jr z, .L4A7A                ; 4A6F
    add a,a                     ; 4A71
    swap a                      ; 4A72
    cp $40                      ; 4A74
    jr z, .L4A7A                ; 4A76
    xor $40                     ; 4A78
.L4A7A:
    ldh [rNR32], a              ; 4A7A
    jp .L4A9F                   ; 4A7C
.L4A7F:
    bit 6, a                    ; 4A7F
    jr nz, .L4A98               ; 4A81
    and $3F                     ; 4A83
    ld d, a                     ; 4A85
    cpl                         ; 4A86
    inc a                       ; 4A87
    ld c, a                     ; 4A88
    dec b                       ; 4A89
    add hl, bc                  ; 4A8A
    add hl, bc                  ; 4A8B
    add hl, bc                  ; 4A8C
    inc b                       ; 4A8D
    ld a, [wCh3_PLSteps]        ; 4A8E
    ld c, d                     ; 4A91
    add a,c                     ; 4A92
    ld [wCh3_PLSteps], a        ; 4A93
    jr .L4A9F                   ; 4A96
.L4A98:
    ld a, [wWave_SweepOn]       ; 4A98
    cpl                         ; 4A9B
    ld [wWave_SweepOn], a       ; 4A9C
.L4A9F:
    ld a, l                     ; 4A9F
    ld [wCh3_PLPtrLo], a        ; 4AA0
    ld a, h                     ; 4AA3
    ld [wCh3_PLPtrHi], a        ; 4AA4
Tick_Ch3_PLWait:
    ld a, [wCh3_PLSpeed]        ; 4AA7
    res 7, a                    ; 4AAA
    ld [wCh3_PLTimer], a        ; 4AAC

;; Wave sweep: move the window position between the bounds.
Tick_Ch3_Sweep:
    ld hl, wCh3_PLTimer         ; 4AAF
    dec [hl]                    ; 4AB2
    ld a, [wWave_SweepOn]       ; 4AB3
    or a                        ; 4AB6
    jp z, Tick_Ch3_WaveRAM      ; 4AB7
    ld a, [wWave_SweepTimer]    ; 4ABA
    or a                        ; 4ABD
    jp nz, .L4B15               ; 4ABE
    ld a, [wWave_PosHi]         ; 4AC1
    ld h, a                     ; 4AC4
    ld a, [wWave_PosLo]         ; 4AC5
    ld l, a                     ; 4AC8
    ld a, [wWave_Step]          ; 4AC9
    ld c, a                     ; 4ACC
    bit 7, c                    ; 4ACD
    jr z, .L4AF0                ; 4ACF
    dec b                       ; 4AD1
    add hl, bc                  ; 4AD2
    inc b                       ; 4AD3
    ld a, h                     ; 4AD4
    ld [wWave_PosHi], a         ; 4AD5
    ld a, l                     ; 4AD8
    ld [wWave_PosLo], a         ; 4AD9
    ld a, [wWave_LowerLo]       ; 4ADC
    cp l                        ; 4ADF
    jr nz, .L4AEE               ; 4AE0
    ld a, [wWave_LowerHi]       ; 4AE2
    cp h                        ; 4AE5
    jr nz, .L4AEE               ; 4AE6
    ld a, c                     ; 4AE8
    cpl                         ; 4AE9
    inc a                       ; 4AEA
    ld [wWave_Step], a          ; 4AEB
.L4AEE:
    jr .L4B0B                   ; 4AEE
.L4AF0:
    add hl, bc                  ; 4AF0
    ld a, h                     ; 4AF1
    ld [wWave_PosHi], a         ; 4AF2
    ld a, l                     ; 4AF5
    ld [wWave_PosLo], a         ; 4AF6
    ld a, [wWave_UpperLo]       ; 4AF9
    cp l                        ; 4AFC
    jr nz, .L4B0B               ; 4AFD
    ld a, [wWave_UpperHi]       ; 4AFF
    cp h                        ; 4B02
    jr nz, .L4B0B               ; 4B03
    ld a, c                     ; 4B05
    cpl                         ; 4B06
    inc a                       ; 4B07
    ld [wWave_Step], a          ; 4B08
.L4B0B:
    ld hl, wWave_WaveUpdate     ; 4B0B
    dec [hl]                    ; 4B0E
    ld a, [wWave_SweepSpeed]    ; 4B0F
    ld [wWave_SweepTimer], a    ; 4B12
.L4B15:
    ld hl, wWave_SweepTimer     ; 4B15
    dec [hl]                    ; 4B18

;; wWave_Update = $FF: copy 16 bytes from base+position into wave RAM.
Tick_Ch3_WaveRAM:
    ld a, [wWave_WaveUpdate]    ; 4B19
    inc a                       ; 4B1C
    jp nz, Tick_Ch3_Pitch       ; 4B1D
    ld [wWave_WaveUpdate], a    ; 4B20
    ld a, [wWave_BaseLo]        ; 4B23
    ld c, a                     ; 4B26
    ld a, [wWave_PosLo]         ; 4B27
    add a,c                     ; 4B2A
    ld e, a                     ; 4B2B
    ld a, [wWave_BaseHi]        ; 4B2C
    ld c, a                     ; 4B2F
    ld a, [wWave_PosHi]         ; 4B30
    adc a,c                     ; 4B33
    ld d, a                     ; 4B34
    ld hl, _AUD3WAVERAM         ; 4B35
    xor a                       ; 4B38
    ldh [rNR30], a              ; 4B39
    ld a, [de]                  ; 4B3B
    inc de                      ; 4B3C
    ld [hl+], a                 ; 4B3D
    ld a, [de]                  ; 4B3E
    inc de                      ; 4B3F
    ld [hl+], a                 ; 4B40
    ld a, [de]                  ; 4B41
    inc de                      ; 4B42
    ld [hl+], a                 ; 4B43
    ld a, [de]                  ; 4B44
    inc de                      ; 4B45
    ld [hl+], a                 ; 4B46
    ld a, [de]                  ; 4B47
    inc de                      ; 4B48
    ld [hl+], a                 ; 4B49
    ld a, [de]                  ; 4B4A
    inc de                      ; 4B4B
    ld [hl+], a                 ; 4B4C
    ld a, [de]                  ; 4B4D
    inc de                      ; 4B4E
    ld [hl+], a                 ; 4B4F
    ld a, [de]                  ; 4B50
    inc de                      ; 4B51
    ld [hl+], a                 ; 4B52
    ld a, [de]                  ; 4B53
    inc de                      ; 4B54
    ld [hl+], a                 ; 4B55
    ld a, [de]                  ; 4B56
    inc de                      ; 4B57
    ld [hl+], a                 ; 4B58
    ld a, [de]                  ; 4B59
    inc de                      ; 4B5A
    ld [hl+], a                 ; 4B5B
    ld a, [de]                  ; 4B5C
    inc de                      ; 4B5D
    ld [hl+], a                 ; 4B5E
    ld a, [de]                  ; 4B5F
    inc de                      ; 4B60
    ld [hl+], a                 ; 4B61
    ld a, [de]                  ; 4B62
    inc de                      ; 4B63
    ld [hl+], a                 ; 4B64
    ld a, [de]                  ; 4B65
    inc de                      ; 4B66
    ld [hl+], a                 ; 4B67
    ld a, [de]                  ; 4B68
    inc de                      ; 4B69
    ld [hl+], a                 ; 4B6A
    ld a, $80                   ; 4B6B
    ldh [rNR30], a              ; 4B6D
    ld hl, rNR34                ; 4B6F
    set 7, [hl]                 ; 4B72
    xor a                       ; 4B74
    ldh [rNR31], a              ; 4B75
Tick_Ch3_Pitch:
    xor a                       ; 4B77
    ldh [rNR31], a              ; 4B78
    ld a, [wCh3_PLNote]         ; 4B7A
    ld c, a                     ; 4B7D
    ld a, [wCh3_PLNoteRaw]      ; 4B7E
    bit 6, a                    ; 4B81
    jr nz, .L4B90               ; 4B83
    ld a, [wCh3_Transpose]      ; 4B85
    add a,c                     ; 4B88
    ld c, a                     ; 4B89
    ld a, [wCh3_Note]           ; 4B8A
    add a,c                     ; 4B8D
    dec a                       ; 4B8E
    ld c, a                     ; 4B8F
.L4B90:
    ld hl, FreqTable            ; 4B90
    add hl, bc                  ; 4B93
    add hl, bc                  ; 4B94
    ld c, $00                   ; 4B95
    ld a, [wCh3_VibDepth]       ; 4B97
    or a                        ; 4B9A
    jr z, .L4BCE                ; 4B9B
    ld a, [wCh3_VibDelay]       ; 4B9D
    dec a                       ; 4BA0
    cp $FF                      ; 4BA1
    jr z, .L4BAA                ; 4BA3
    ld [wCh3_VibDelay], a       ; 4BA5
    jr .L4BCE                   ; 4BA8
.L4BAA:
    ld a, [wCh3_VibSpeed]       ; 4BAA
    ld c, a                     ; 4BAD
    ld a, [wCh3_VibPhase]       ; 4BAE
    add a,c                     ; 4BB1
    and $3F                     ; 4BB2
    ld [wCh3_VibPhase], a       ; 4BB4
    srl a                       ; 4BB7
    srl a                       ; 4BB9
    ld c, a                     ; 4BBB
    ld a, [wCh3_VibDepth]       ; 4BBC
    or c                        ; 4BBF
    ld c, a                     ; 4BC0
    push hl                     ; 4BC1
    ld hl, VibratoTable         ; 4BC2
    add hl, bc                  ; 4BC5
    ld a, [hl]                  ; 4BC6
    pop hl                      ; 4BC7
    ld c, a                     ; 4BC8
    bit 7, a                    ; 4BC9
    jr z, .L4BCE                ; 4BCB
    dec b                       ; 4BCD
.L4BCE:
    ld a, [hl+]                 ; 4BCE
    ld e, a                     ; 4BCF
    ld a, [hl]                  ; 4BD0
    ld h, a                     ; 4BD1
    ld l, e                     ; 4BD2
    add hl, bc                  ; 4BD3
    ld b, $00                   ; 4BD4
    ld a, l                     ; 4BD6
    ldh [rNR33], a              ; 4BD7
    ld a, h                     ; 4BD9
    ldh [rNR34], a              ; 4BDA
    xor a                       ; 4BDC
    ldh [rNR31], a              ; 4BDD

;; Channel 4 tick: NR43 = NoiseTable[(note + PLnote - 2) / 2].
Tick_Ch4:
    ld a, [wCh4_SFXTimer]       ; 4BDF
    or a                        ; 4BE2
    jr z, .L4BE9                ; 4BE3
    dec a                       ; 4BE5
    ld [wCh4_SFXTimer], a       ; 4BE6
.L4BE9:
    ld a, [wCh4_PLTimer]        ; 4BE9
    or a                        ; 4BEC
    jp nz, Tick_Ch4_Noise       ; 4BED
    ld a, [wCh4_PLSteps]        ; 4BF0
    or a                        ; 4BF3
    jp z, Tick_Ch4_PLWait       ; 4BF4
    dec a                       ; 4BF7
    ld [wCh4_PLSteps], a        ; 4BF8
    ld a, [wCh4_PLPtrLo]        ; 4BFB
    ld l, a                     ; 4BFE
    ld a, [wCh4_PLPtrHi]        ; 4BFF
    ld h, a                     ; 4C02
    ld a, [hl+]                 ; 4C03
    ld [wCh4_PLNoteRaw], a      ; 4C04
    and $3F                     ; 4C07
    jr z, .L4C0E                ; 4C09
    ld [wCh4_PLNote], a         ; 4C0B
.L4C0E:
    ld a, [hl+]                 ; 4C0E
    bit 7, a                    ; 4C0F
    jr nz, .L4C4F               ; 4C11
    bit 6, a                    ; 4C13
    jr nz, .L4C21               ; 4C15
    and $3F                     ; 4C17
    jr z, .L4C1E                ; 4C19
    ld [wCh4_PLSpeed], a        ; 4C1B
.L4C1E:
    jp .L4C68                   ; 4C1E
.L4C21:
    swap a                      ; 4C21
    ld d, a                     ; 4C23
    ld a, [wCh4_VolShift]       ; 4C24
    ld c, a                     ; 4C27
    ld a, d                     ; 4C28
    inc c                       ; 4C29
    dec c                       ; 4C2A
    jr z, .L4C3B                ; 4C2B
    dec c                       ; 4C2D
    jr z, .L4C39                ; 4C2E
    dec c                       ; 4C30
    jr z, .L4C37                ; 4C31
    srl a                       ; 4C33
    srl a                       ; 4C35
.L4C37:
    srl a                       ; 4C37
.L4C39:
    srl a                       ; 4C39
.L4C3B:
    and $F0                     ; 4C3B
    ld c, a                     ; 4C3D
    ldh a, [rNR42]              ; 4C3E
    and $0F                     ; 4C40
    or c                        ; 4C42
    ldh [rNR42], a              ; 4C43
    push hl                     ; 4C45
    ld hl, rNR44                ; 4C46
    set 7, [hl]                 ; 4C49
    pop hl                      ; 4C4B
    jp .L4C68                   ; 4C4C
.L4C4F:
    bit 6, a                    ; 4C4F
    jr nz, .L4C68               ; 4C51
    and $3F                     ; 4C53
    ld d, a                     ; 4C55
    cpl                         ; 4C56
    inc a                       ; 4C57
    ld c, a                     ; 4C58
    dec b                       ; 4C59
    add hl, bc                  ; 4C5A
    add hl, bc                  ; 4C5B
    add hl, bc                  ; 4C5C
    inc b                       ; 4C5D
    ld a, [wCh4_PLSteps]        ; 4C5E
    ld c, d                     ; 4C61
    add a,c                     ; 4C62
    ld [wCh4_PLSteps], a        ; 4C63
    jr .L4C68                   ; 4C66
.L4C68:
    ld a, [hl+]                 ; 4C68
    bit 7, a                    ; 4C69
    jr nz, .L4CA9               ; 4C6B
    bit 6, a                    ; 4C6D
    jr nz, .L4C7B               ; 4C6F
    and $3F                     ; 4C71
    jr z, .L4C78                ; 4C73
    ld [wCh4_PLSpeed], a        ; 4C75
.L4C78:
    jp .L4CC2                   ; 4C78
.L4C7B:
    swap a                      ; 4C7B
    ld d, a                     ; 4C7D
    ld a, [wCh4_VolShift]       ; 4C7E
    ld c, a                     ; 4C81
    ld a, d                     ; 4C82
    inc c                       ; 4C83
    dec c                       ; 4C84
    jr z, .L4C95                ; 4C85
    dec c                       ; 4C87
    jr z, .L4C93                ; 4C88
    dec c                       ; 4C8A
    jr z, .L4C91                ; 4C8B
    srl a                       ; 4C8D
    srl a                       ; 4C8F
.L4C91:
    srl a                       ; 4C91
.L4C93:
    srl a                       ; 4C93
.L4C95:
    and $F0                     ; 4C95
    ld c, a                     ; 4C97
    ldh a, [rNR42]              ; 4C98
    and $0F                     ; 4C9A
    or c                        ; 4C9C
    ldh [rNR42], a              ; 4C9D
    push hl                     ; 4C9F
    ld hl, rNR44                ; 4CA0
    set 7, [hl]                 ; 4CA3
    pop hl                      ; 4CA5
    jp .L4CC2                   ; 4CA6
.L4CA9:
    bit 6, a                    ; 4CA9
    jr nz, .L4CC2               ; 4CAB
    and $3F                     ; 4CAD
    ld d, a                     ; 4CAF
    cpl                         ; 4CB0
    inc a                       ; 4CB1
    ld c, a                     ; 4CB2
    dec b                       ; 4CB3
    add hl, bc                  ; 4CB4
    add hl, bc                  ; 4CB5
    add hl, bc                  ; 4CB6
    inc b                       ; 4CB7
    ld a, [wCh4_PLSteps]        ; 4CB8
    ld c, d                     ; 4CBB
    add a,c                     ; 4CBC
    ld [wCh4_PLSteps], a        ; 4CBD
    jr .L4CC2                   ; 4CC0
.L4CC2:
    ld a, l                     ; 4CC2
    ld [wCh4_PLPtrLo], a        ; 4CC3
    ld a, h                     ; 4CC6
    ld [wCh4_PLPtrHi], a        ; 4CC7
Tick_Ch4_PLWait:
    ld a, [wCh4_PLSpeed]        ; 4CCA
    res 7, a                    ; 4CCD
    ld [wCh4_PLTimer], a        ; 4CCF
Tick_Ch4_Noise:
    ld hl, wCh4_PLTimer         ; 4CD2
    dec [hl]                    ; 4CD5
    ld a, [wCh4_PLNoteRaw]      ; 4CD6
    ld e, a                     ; 4CD9
    ld a, [wCh4_PLNote]         ; 4CDA
    bit 6, e                    ; 4CDD
    jr nz, .L4CE7               ; 4CDF
    ld c, a                     ; 4CE1
    ld a, [wCh4_Note]           ; 4CE2
    add a,c                     ; 4CE5
    dec a                       ; 4CE6
.L4CE7:
    dec a                       ; 4CE7
    srl a                       ; 4CE8
    ld c, a                     ; 4CEA
    ld hl, NoiseTable           ; 4CEB
    add hl, bc                  ; 4CEE
    ld a, [hl]                  ; 4CEF
    ldh [rNR43], a              ; 4CF0
    ret                         ; 4CF2

;; GHX_PlaySFX: A = effect. SFXTable entry (5 bytes) = [ins ch1 | bit 7: record
;; this SFX in wSFX_Ch3Owner] [ins ch2] [ins ch3] [ins ch4] [time]. Instruments are 1-based
;; indices into SFXInstTable (0 = channel unused); the music on a used channel
;; is muted for "time" ticks.
PlaySFX:
    ld c, a                     ; 4CF3
    ld a, [wEnabled]            ; 4CF4
    push af                     ; 4CF7
    xor a                       ; 4CF8
    ld [wEnabled], a            ; 4CF9
    ld a, c                     ; 4CFC
    ld e, a                     ; 4CFD
    add a,a                     ; 4CFE
    add a,a                     ; 4CFF
    add a,c                     ; 4D00
    ld c, a                     ; 4D01
    ld a, $00                   ; 4D02
    adc a,$00                   ; 4D04
    ld b, a                     ; 4D06
    ld hl, SFXTable             ; 4D07
    add hl, bc                  ; 4D0A
    ld b, $00                   ; 4D0B
    ld a, [hl+]                 ; 4D0D
    bit 7, a                    ; 4D0E
    res 7, a                    ; 4D10
    push af                     ; 4D12
    ld [wSFX_Ch1], a            ; 4D13
    ld a, [hl+]                 ; 4D16
    ld [wSFX_Ch2], a            ; 4D17
    ld a, [hl+]                 ; 4D1A
    or a                        ; 4D1B
    jr z, .L4D29                ; 4D1C
    push af                     ; 4D1E
    ld a, [wSFX_Ch3Owner]       ; 4D1F
    or a                        ; 4D22
    jr z, .L4D28                ; 4D23
    ld [wSFX_Ch3Prev], a        ; 4D25
.L4D28:
    pop af                      ; 4D28
.L4D29:
    ld [wSFX_Ch3], a            ; 4D29
    ld a, [hl+]                 ; 4D2C
    ld [wSFX_Ch4], a            ; 4D2D
    ld a, [hl+]                 ; 4D30
    ld [wSFX_Time], a           ; 4D31
    pop af                      ; 4D34
    jr nz, .L4D39               ; 4D35
    ld e, $00                   ; 4D37
.L4D39:
    ld a, [wSFX_Ch3]            ; 4D39
    or a                        ; 4D3C
    jr z, PlaySFX_Ch1           ; 4D3D
    ld a, e                     ; 4D3F
    ld [wSFX_Ch3Owner], a       ; 4D40
PlaySFX_Ch1:
    ld a, [wSFX_Ch1]            ; 4D43
    or a                        ; 4D46
    jp z, PlaySFX_Ch2           ; 4D47
    dec a                       ; 4D4A
    ld hl, SFXInstTable         ; 4D4B
    ld c, a                     ; 4D4E
    add hl, bc                  ; 4D4F
    add hl, bc                  ; 4D50
    ld a, [hl+]                 ; 4D51
    ld c, a                     ; 4D52
    ld a, [hl+]                 ; 4D53
    ld h, a                     ; 4D54
    ld l, c                     ; 4D55
    xor a                       ; 4D56
    ld [wCh1_VolShift], a       ; 4D57
    ld a, [hl+]                 ; 4D5A
    ld [wCh1_InsFlags], a       ; 4D5B
    ld d, a                     ; 4D5E
    ld a, [hl+]                 ; 4D5F
    ld [wCh1_PLSpeed], a        ; 4D60
    xor a                       ; 4D63
    ld [wCh1_PLTimer], a        ; 4D64
    ld a, $80                   ; 4D67
    ldh [rNR11], a              ; 4D69
    ld a, [wCh1_VolShift]       ; 4D6B
    ld c, a                     ; 4D6E
    ld a, [hl]                  ; 4D6F
    and $0F                     ; 4D70
    ld e, a                     ; 4D72
    ld a, [hl+]                 ; 4D73
    inc c                       ; 4D74
    dec c                       ; 4D75
    jr z, .L4D86                ; 4D76
    dec c                       ; 4D78
    jr z, .L4D84                ; 4D79
    dec c                       ; 4D7B
    jr z, .L4D82                ; 4D7C
    srl a                       ; 4D7E
    srl a                       ; 4D80
.L4D82:
    srl a                       ; 4D82
.L4D84:
    srl a                       ; 4D84
.L4D86:
    and $F0                     ; 4D86
    or e                        ; 4D88
    ldh [rNR12], a              ; 4D89
    ld a, [wCh1_PLSpeed]        ; 4D8B
    bit 7, a                    ; 4D8E
    jr z, .L4DA6                ; 4D90
    ld a, [hl+]                 ; 4D92
    ld [wCh1_VibDelay], a       ; 4D93
    ld a, [hl+]                 ; 4D96
    ld c, a                     ; 4D97
    and $0F                     ; 4D98
    ld [wCh1_VibSpeed], a       ; 4D9A
    ld a, c                     ; 4D9D
    and $F0                     ; 4D9E
    ld [wCh1_VibDepth], a       ; 4DA0
    xor a                       ; 4DA3
    jr .L4DB0                   ; 4DA4
.L4DA6:
    xor a                       ; 4DA6
    ld [wCh1_VibDelay], a       ; 4DA7
    ld [wCh1_VibDepth], a       ; 4DAA
    ld [wCh1_VibSpeed], a       ; 4DAD
.L4DB0:
    ld [wCh1_VibPhase], a       ; 4DB0
    ld a, d                     ; 4DB3
    and $3F                     ; 4DB4
    ld [wCh1_PLSteps], a        ; 4DB6
    ld a, l                     ; 4DB9
    ld [wCh1_PLPtrLo], a        ; 4DBA
    ld a, h                     ; 4DBD
    ld [wCh1_PLPtrHi], a        ; 4DBE
    ld hl, rNR14                ; 4DC1
    set 7, [hl]                 ; 4DC4
    ld a, [wSFX_Time]           ; 4DC6
    ld [wCh1_SFXTimer], a       ; 4DC9
PlaySFX_Ch2:
    ld a, [wSFX_Ch2]            ; 4DCC
    or a                        ; 4DCF
    jp z, PlaySFX_Ch3           ; 4DD0
    dec a                       ; 4DD3
    ld hl, SFXInstTable         ; 4DD4
    ld c, a                     ; 4DD7
    add hl, bc                  ; 4DD8
    add hl, bc                  ; 4DD9
    ld a, [hl+]                 ; 4DDA
    ld c, a                     ; 4DDB
    ld a, [hl+]                 ; 4DDC
    ld h, a                     ; 4DDD
    ld l, c                     ; 4DDE
    xor a                       ; 4DDF
    ld [wCh2_VolShift], a       ; 4DE0
    ld a, [hl+]                 ; 4DE3
    ld [wCh2_InsFlags], a       ; 4DE4
    ld d, a                     ; 4DE7
    ld a, [hl+]                 ; 4DE8
    ld [wCh2_PLSpeed], a        ; 4DE9
    xor a                       ; 4DEC
    ld [wCh2_PLTimer], a        ; 4DED
    ld a, $80                   ; 4DF0
    ldh [rNR21], a              ; 4DF2
    ld a, [wCh2_VolShift]       ; 4DF4
    ld c, a                     ; 4DF7
    ld a, [hl]                  ; 4DF8
    and $0F                     ; 4DF9
    ld e, a                     ; 4DFB
    ld a, [hl+]                 ; 4DFC
    inc c                       ; 4DFD
    dec c                       ; 4DFE
    jr z, .L4E0F                ; 4DFF
    dec c                       ; 4E01
    jr z, .L4E0D                ; 4E02
    dec c                       ; 4E04
    jr z, .L4E0B                ; 4E05
    srl a                       ; 4E07
    srl a                       ; 4E09
.L4E0B:
    srl a                       ; 4E0B
.L4E0D:
    srl a                       ; 4E0D
.L4E0F:
    and $F0                     ; 4E0F
    or e                        ; 4E11
    ldh [rNR22], a              ; 4E12
    ld a, [wCh2_PLSpeed]        ; 4E14
    bit 7, a                    ; 4E17
    jr z, .L4E2F                ; 4E19
    ld a, [hl+]                 ; 4E1B
    ld [wCh2_VibDelay], a       ; 4E1C
    ld a, [hl+]                 ; 4E1F
    ld c, a                     ; 4E20
    and $0F                     ; 4E21
    ld [wCh2_VibSpeed], a       ; 4E23
    ld a, c                     ; 4E26
    and $F0                     ; 4E27
    ld [wCh2_VibDepth], a       ; 4E29
    xor a                       ; 4E2C
    jr .L4E39                   ; 4E2D
.L4E2F:
    xor a                       ; 4E2F
    ld [wCh2_VibDelay], a       ; 4E30
    ld [wCh2_VibDepth], a       ; 4E33
    ld [wCh2_VibSpeed], a       ; 4E36
.L4E39:
    ld [wCh2_VibPhase], a       ; 4E39
    ld a, d                     ; 4E3C
    and $3F                     ; 4E3D
    ld [wCh2_PLSteps], a        ; 4E3F
    ld a, l                     ; 4E42
    ld [wCh2_PLPtrLo], a        ; 4E43
    ld a, h                     ; 4E46
    ld [wCh2_PLPtrHi], a        ; 4E47
    ld hl, rNR24                ; 4E4A
    set 7, [hl]                 ; 4E4D
    ld a, [wSFX_Time]           ; 4E4F
    ld [wCh2_SFXTimer], a       ; 4E52
PlaySFX_Ch3:
    ld a, [wSFX_Ch3]            ; 4E55
    or a                        ; 4E58
    jp z, PlaySFX_Ch4           ; 4E59
    dec a                       ; 4E5C
    ld hl, SFXInstTable         ; 4E5D
    ld c, a                     ; 4E60
    add hl, bc                  ; 4E61
    add hl, bc                  ; 4E62
    ld a, [hl+]                 ; 4E63
    ld c, a                     ; 4E64
    ld a, [hl+]                 ; 4E65
    ld h, a                     ; 4E66
    ld l, c                     ; 4E67
    ld a, [hl+]                 ; 4E68
    ld [wCh3_InsFlags], a       ; 4E69
    ld d, a                     ; 4E6C
    and $C0                     ; 4E6D
    ld [wWave_PCMFlag], a       ; 4E6F
    ld a, [hl+]                 ; 4E72
    ld [wCh3_PLSpeed], a        ; 4E73
    xor a                       ; 4E76
    ld [wCh3_PLTimer], a        ; 4E77
    ld a, [wCh3_VolShift]       ; 4E7A
    or a                        ; 4E7D
    jr z, .L4E83                ; 4E7E
    inc hl                      ; 4E80
    jr .L4E89                   ; 4E81
.L4E83:
    ld a, [hl+]                 ; 4E83
    ld [wCh3_Level], a          ; 4E84
    and $FE                     ; 4E87
.L4E89:
    ldh [rNR32], a              ; 4E89
    xor a                       ; 4E8B
    ld [wCh3_VolShift], a       ; 4E8C
    ld a, [wCh3_PLSpeed]        ; 4E8F
    bit 7, a                    ; 4E92
    jr z, .L4EAA                ; 4E94
    ld a, [hl+]                 ; 4E96
    ld [wCh3_VibDelay], a       ; 4E97
    ld a, [hl+]                 ; 4E9A
    ld c, a                     ; 4E9B
    and $0F                     ; 4E9C
    ld [wCh3_VibSpeed], a       ; 4E9E
    ld a, c                     ; 4EA1
    and $F0                     ; 4EA2
    ld [wCh3_VibDepth], a       ; 4EA4
    xor a                       ; 4EA7
    jr .L4EB4                   ; 4EA8
.L4EAA:
    xor a                       ; 4EAA
    ld [wCh3_VibDelay], a       ; 4EAB
    ld [wCh3_VibDepth], a       ; 4EAE
    ld [wCh3_VibSpeed], a       ; 4EB1
.L4EB4:
    ld [wCh3_VibPhase], a       ; 4EB4
    ld a, [hl+]                 ; 4EB7
    ld [wWave_Step], a          ; 4EB8
    xor a                       ; 4EBB
    ld [wWave_SweepOn], a       ; 4EBC
    ld [wWave_FlagHi], a        ; 4EBF
    ld a, [hl+]                 ; 4EC2
    bit 7, a                    ; 4EC3
    jr z, .L4ECA                ; 4EC5
    ld [wWave_FlagHi], a        ; 4EC7
.L4ECA:
    and $7F                     ; 4ECA
    ld [wWave_FlagLo], a        ; 4ECC
    ld a, [hl+]                 ; 4ECF
    ld [wWave_PosLo], a         ; 4ED0
    ld a, [hl+]                 ; 4ED3
    ld [wWave_PosHi], a         ; 4ED4
    ld a, [hl+]                 ; 4ED7
    ld [wWave_LowerLo], a       ; 4ED8
    ld a, [hl+]                 ; 4EDB
    ld [wWave_LowerHi], a       ; 4EDC
    ld a, [hl+]                 ; 4EDF
    ld [wWave_UpperLo], a       ; 4EE0
    ld a, [hl+]                 ; 4EE3
    ld [wWave_UpperHi], a       ; 4EE4
    ld a, [hl+]                 ; 4EE7
    ld [wWave_SweepSpeed], a    ; 4EE8
    ld [wWave_SweepTimer], a    ; 4EEB
    ld a, [hl+]                 ; 4EEE
    ld [wWave_BaseLo], a        ; 4EEF
    ld a, [hl+]                 ; 4EF2
    ld [wWave_BaseHi], a        ; 4EF3
    ld a, d                     ; 4EF6
    and $3F                     ; 4EF7
    ld [wCh3_PLSteps], a        ; 4EF9
    ld a, l                     ; 4EFC
    ld [wCh3_PLPtrLo], a        ; 4EFD
    ld a, h                     ; 4F00
    ld [wCh3_PLPtrHi], a        ; 4F01
    ld a, $FF                   ; 4F04
    ld [wWave_WaveUpdate], a    ; 4F06
    ld a, [wSFX_Time]           ; 4F09
    ld [wCh3_SFXTimer], a       ; 4F0C
PlaySFX_Ch4:
    ld a, [wSFX_Ch4]            ; 4F0F
    or a                        ; 4F12
    jr z, .L4F6F                ; 4F13
    dec a                       ; 4F15
    ld hl, SFXInstTable         ; 4F16
    ld c, a                     ; 4F19
    add hl, bc                  ; 4F1A
    add hl, bc                  ; 4F1B
    ld a, [hl+]                 ; 4F1C
    ld c, a                     ; 4F1D
    ld a, [hl+]                 ; 4F1E
    ld h, a                     ; 4F1F
    ld l, c                     ; 4F20
    xor a                       ; 4F21
    ld [wCh4_VolShift], a       ; 4F22
    ld a, [hl+]                 ; 4F25
    ld [wCh4_InsFlags], a       ; 4F26
    ld d, a                     ; 4F29
    ld a, [hl+]                 ; 4F2A
    ld [wCh4_PLSpeed], a        ; 4F2B
    xor a                       ; 4F2E
    ld [wCh4_PLTimer], a        ; 4F2F
    ld a, $00                   ; 4F32
    ldh [rNR41], a              ; 4F34
    ld a, [wCh4_VolShift]       ; 4F36
    ld c, a                     ; 4F39
    ld a, [hl]                  ; 4F3A
    and $0F                     ; 4F3B
    ld e, a                     ; 4F3D
    ld a, [hl+]                 ; 4F3E
    inc c                       ; 4F3F
    dec c                       ; 4F40
    jr z, .L4F51                ; 4F41
    dec c                       ; 4F43
    jr z, .L4F4F                ; 4F44
    dec c                       ; 4F46
    jr z, .L4F4D                ; 4F47
    srl a                       ; 4F49
    srl a                       ; 4F4B
.L4F4D:
    srl a                       ; 4F4D
.L4F4F:
    srl a                       ; 4F4F
.L4F51:
    and $F0                     ; 4F51
    or e                        ; 4F53
    ldh [rNR42], a              ; 4F54
    ld a, d                     ; 4F56
    and $3F                     ; 4F57
    ld [wCh4_PLSteps], a        ; 4F59
    ld a, l                     ; 4F5C
    ld [wCh4_PLPtrLo], a        ; 4F5D
    ld a, h                     ; 4F60
    ld [wCh4_PLPtrHi], a        ; 4F61
    ld hl, rNR44                ; 4F64
    set 7, [hl]                 ; 4F67
    ld a, [wSFX_Time]           ; 4F69
    ld [wCh4_SFXTimer], a       ; 4F6C
.L4F6F:
    pop af                      ; 4F6F
    ld [wEnabled], a            ; 4F70
    ret                         ; 4F73

;; GB frequency values. Index 0 = 0, index 1 = C-2 ... index 72 = B-7.
FreqTable:
    dw $0000, $002C, $009C, $0106, $016B, $01C9  ; (0)-E-2
    dw $0223, $0277, $02C6, $0312, $0359, $039B  ; F-2-A#2
    dw $03DA, $0416, $044E, $0483, $04B5, $04E5  ; B-2-E-3
    dw $0511, $053B, $0563, $0589, $05AC, $05CE  ; F-3-A#3
    dw $05ED, $060A, $0627, $0642, $065B, $0672  ; B-3-E-4
    dw $0689, $069E, $06B2, $06C4, $06D6, $06E7  ; F-4-A#4
    dw $06F7, $0706, $0714, $0721, $072D, $0739  ; B-4-E-5
    dw $0744, $074F, $0759, $0762, $076B, $0773  ; F-5-A#5
    dw $077B, $0783, $078A, $0790, $0797, $079D  ; B-5-E-6
    dw $07A2, $07A7, $07AC, $07B1, $07B6, $07BA  ; F-6-A#6
    dw $07BE, $07C1, $07C4, $07C8, $07CB, $07CE  ; B-6-E-7
    dw $07D1, $07D4, $07D6, $07D9, $07DB, $07DD  ; F-7-A#7
    dw $07DF                                     ; B-7-B-7

;; NR43 values for channel 4 (index = (note+PLnote-2)/2).
NoiseTable:
    db $90, $57, $63, $63, $55, $55, $80, $47, $53, $53; 5006 
    db $45, $45, $70, $37, $43, $43, $35, $35, $60, $27; 5010 
    db $33, $33, $25, $25, $50, $17, $23, $23, $15, $15; 501A 

;; 16 depths x 16 phases, signed frequency offsets.
VibratoTable:
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00; 5024 
    db $00, $00, $00, $00, $01, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF; 5034 
    db $00, $00, $01, $01, $02, $01, $01, $00, $00, $FF, $FE, $FE, $FE, $FE, $FE, $FF; 5044 
    db $00, $01, $02, $02, $03, $02, $02, $01, $00, $FE, $FD, $FD, $FD, $FD, $FD, $FE; 5054 
    db $00, $01, $02, $03, $04, $03, $02, $01, $00, $FE, $FD, $FC, $FC, $FC, $FD, $FE; 5064 
    db $00, $01, $03, $04, $05, $04, $03, $01, $00, $FE, $FC, $FB, $FB, $FB, $FC, $FE; 5074 
    db $00, $02, $04, $05, $06, $05, $04, $02, $00, $FD, $FB, $FA, $FA, $FA, $FB, $FD; 5084 
    db $00, $02, $04, $06, $07, $06, $04, $02, $00, $FD, $FB, $F9, $F9, $F9, $FB, $FD; 5094 
    db $00, $03, $05, $07, $08, $07, $05, $03, $00, $FC, $FA, $F8, $F8, $F8, $FA, $FC; 50A4 
    db $00, $03, $06, $08, $09, $08, $06, $03, $00, $FC, $F9, $F7, $F7, $F7, $F9, $FC; 50B4 
    db $00, $03, $07, $09, $0A, $09, $07, $03, $00, $FC, $F8, $F6, $F6, $F6, $F8, $FC; 50C4 
    db $00, $04, $07, $0A, $0B, $0A, $07, $04, $00, $FB, $F8, $F5, $F5, $F5, $F8, $FB; 50D4 
    db $00, $04, $08, $0B, $0C, $0B, $08, $04, $00, $FB, $F7, $F4, $F4, $F4, $F7, $FB; 50E4 
    db $00, $04, $09, $0C, $0D, $0C, $09, $04, $00, $FB, $F6, $F3, $F3, $F3, $F6, $FB; 50F4 
    db $00, $05, $09, $0C, $0E, $0C, $09, $05, $00, $FA, $F6, $F3, $F2, $F3, $F6, $FA; 5104 
    db $00, $05, $0A, $0D, $0F, $0D, $0A, $05, $00, $FA, $F5, $F2, $F1, $F2, $F5, $FA; 5114 
SongTable:
    dw Song0_Header                              ; 5124  song 0

;; Song header (12 bytes, copied to wHdr_* by GHX_Init).
Song0_Header:
    db "GHX"                                     ; 5126 magic
    db 11                                        ; subsongs
    db 32                                        ; rows per pattern
    db $00                                       ; (unused)
    dw Song0_Tracks                              ; track pointer table (not used by this build)
    dw Song0_Instruments                         ; instrument pointer table
    dw Song0_Orders                              ; order table

;; Order table: two entries per subsong (intro, loop) = [count] [dw positions];
;; count+1 positions are played. After the intro the loop entry repeats forever.
Song0_Orders:
    db 20 
    dw Song0_Pos000                          ; 5132 subsong 0 intro (21 positions)
    db 19 
    dw Song0_Pos001                          ; 5135 subsong 0 loop  (20 positions)
    db 9  
    dw Song0_Pos021                          ; 5138 subsong 1 intro (10 positions)
    db 9  
    dw Song0_Pos021                          ; 513B subsong 1 loop  (10 positions)
    db 10 
    dw Song0_Pos031                          ; 513E subsong 2 intro (11 positions)
    db 10 
    dw Song0_Pos031                          ; 5141 subsong 2 loop  (11 positions)
    db 1  
    dw Song0_Pos042                          ; 5144 subsong 3 intro (2 positions)
    db 0  
    dw Song0_Pos043                          ; 5147 subsong 3 loop  (1 positions)
    db 2  
    dw Song0_Pos044                          ; 514A subsong 4 intro (3 positions)
    db 0  
    dw Song0_Pos046                          ; 514D subsong 4 loop  (1 positions)
    db 2  
    dw Song0_Pos047                          ; 5150 subsong 5 intro (3 positions)
    db 0  
    dw Song0_Pos049                          ; 5153 subsong 5 loop  (1 positions)
    db 3  
    dw Song0_Pos050                          ; 5156 subsong 6 intro (4 positions)
    db 0  
    dw Song0_Pos053                          ; 5159 subsong 6 loop  (1 positions)
    db 2  
    dw Song0_Pos054                          ; 515C subsong 7 intro (3 positions)
    db 0  
    dw Song0_Pos056                          ; 515F subsong 7 loop  (1 positions)
    db 4  
    dw Song0_Pos057                          ; 5162 subsong 8 intro (5 positions)
    db 0  
    dw Song0_Pos061                          ; 5165 subsong 8 loop  (1 positions)
    db 0  
    dw Song0_Pos062                          ; 5168 subsong 9 intro (1 positions)
    db 0  
    dw Song0_Pos062                          ; 516B subsong 9 loop  (1 positions)
    db 192
    dw Song0_Pos063                          ; 516E subsong 10 intro (193 positions)  (count runs past the position list!)
    db 255
    dw Song0_Pos000                          ; 5171 subsong 10 loop  (256 positions)  (count runs past the position list!)

;; Positions (11 bytes): for ch1-ch3 [dw track] [transpose], then [dw track] for ch4.
Song0_Pos000:
    POS Track001, 0, Track002, 0, Track003, 0, Track000  ; 5174 pos 0
Song0_Pos001:
    POS Track001, 0, Track002, 0, Track003, 0, Track000  ; 517F pos 1
    POS Track004, 0, Track005, 0, Track003, 0, Track000  ; 518A pos 2
    POS Track004, 0, Track005, 0, Track003, 0, Track000  ; 5195 pos 3
    POS Track024, 0, Track006, 0, Track008, 0, Track000  ; 51A0 pos 4
    POS Track009, 0, Track010, 0, Track014, 0, Track000  ; 51AB pos 5
    POS Track024, 0, Track011, 0, Track008, 0, Track000  ; 51B6 pos 6
    POS Track009, 0, Track012, 0, Track014, 0, Track000  ; 51C1 pos 7
    POS Track024, 0, Track013, 0, Track008, 0, Track000  ; 51CC pos 8
    POS Track009, 0, Track010, 0, Track014, 0, Track000  ; 51D7 pos 9
    POS Track024, 0, Track011, 0, Track008, 0, Track000  ; 51E2 pos 10
    POS Track009, 0, Track012, 0, Track014, 0, Track000  ; 51ED pos 11
    POS Track007, 0, Track016, 0, Track018, 0, Track023  ; 51F8 pos 12
    POS Track020, 0, Track015, 0, Track018, 0, Track019  ; 5203 pos 13
    POS Track022, 0, Track021, 0, Track018, 0, Track019  ; 520E pos 14
    POS Track028, 0, Track027, 0, Track018, 0, Track029  ; 5219 pos 15
    POS Track025, 0, Track026, 0, Track018, 0, Track023  ; 5224 pos 16
    POS Track031, 0, Track030, 0, Track033, 0, Track032  ; 522F pos 17
    POS Track025, 0, Track037, 0, Track018, 0, Track023  ; 523A pos 18
    POS Track031, 0, Track030, 0, Track033, 0, Track032  ; 5245 pos 19
    POS Track036, 0, Track035, 0, Track003, 0, Track034  ; 5250 pos 20
Song0_Pos021:
    POS Track038, 0, Track040, 0, Track039, 0, Track044  ; 525B pos 21
    POS Track038, 0, Track040, 0, Track039, 0, Track044  ; 5266 pos 22
    POS Track043, 0, Track042, 0, Track041, 0, Track044  ; 5271 pos 23
    POS Track045, 0, Track040, 0, Track039, 0, Track044  ; 527C pos 24
    POS Track047, 0, Track040, 0, Track039, 0, Track044  ; 5287 pos 25
    POS Track046, 0, Track042, 0, Track041, 0, Track044  ; 5292 pos 26
    POS Track048, 0, Track040, 0, Track039, 0, Track044  ; 529D pos 27
    POS Track048, 0, Track040, 0, Track039, 0, Track044  ; 52A8 pos 28
    POS Track048, 0, Track040, 12, Track039, 0, Track044  ; 52B3 pos 29
    POS Track048, 0, Track040, 12, Track039, 0, Track044  ; 52BE pos 30
Song0_Pos031:
    POS Track051, 0, Track049, 0, Track050, 0, Track052  ; 52C9 pos 31
    POS Track051, 0, Track049, 0, Track050, 0, Track052  ; 52D4 pos 32
    POS Track053, 0, Track049, 0, Track050, 0, Track052  ; 52DF pos 33
    POS Track053, 0, Track049, 0, Track050, 0, Track052  ; 52EA pos 34
    POS Track053, 0, Track049, 0, Track054, 0, Track055  ; 52F5 pos 35
    POS Track053, 0, Track049, 0, Track056, 0, Track057  ; 5300 pos 36
    POS Track058, 0, Track060, 0, Track059, 0, Track055  ; 530B pos 37
    POS Track061, 0, Track062, 0, Track059, 0, Track057  ; 5316 pos 38
    POS Track058, 0, Track060, 12, Track059, 0, Track055  ; 5321 pos 39
    POS Track063, 0, Track068, 12, Track066, 0, Track067  ; 532C pos 40
    POS Track064, 0, Track065, 0, Track008, -7, Track052  ; 5337 pos 41
Song0_Pos042:
    POS Track069, 0, Track070, 0, Track071, 0, Track072  ; 5342 pos 42
Song0_Pos043:
    POS Track000, 0, Track000, 0, Track000, 0, Track000  ; 534D pos 43
Song0_Pos044:
    POS Track073, 0, Track074, 0, Track075, 0, Track076  ; 5358 pos 44
    POS Track077, 0, Track078, 0, Track079, 0, Track076  ; 5363 pos 45
Song0_Pos046:
    POS Track000, 0, Track000, 0, Track000, 0, Track000  ; 536E pos 46
Song0_Pos047:
    POS Track080, 0, Track081, 0, Track082, 0, Track083  ; 5379 pos 47
    POS Track084, 0, Track085, 0, Track086, 0, Track087  ; 5384 pos 48
Song0_Pos049:
    POS Track000, 0, Track000, 0, Track000, 0, Track000  ; 538F pos 49
Song0_Pos050:
    POS Track088, 0, Track089, 0, Track093, 0, Track090  ; 539A pos 50
    POS Track088, 0, Track089, 0, Track093, 0, Track090  ; 53A5 pos 51
    POS Track091, 0, Track092, 0, Track094, 0, Track095  ; 53B0 pos 52
Song0_Pos053:
    POS Track000, 0, Track000, 0, Track000, 0, Track000  ; 53BB pos 53
Song0_Pos054:
    POS Track096, 0, Track097, 0, Track098, 0, Track000  ; 53C6 pos 54
    POS Track099, 0, Track100, 0, Track101, 0, Track000  ; 53D1 pos 55
Song0_Pos056:
    POS Track000, 0, Track000, 0, Track000, 0, Track000  ; 53DC pos 56
Song0_Pos057:
    POS Track105, 0, Track104, 0, Track102, 0, Track103  ; 53E7 pos 57
    POS Track105, 0, Track104, 0, Track102, 0, Track103  ; 53F2 pos 58
    POS Track105, 0, Track104, 12, Track102, 0, Track103  ; 53FD pos 59
    POS Track109, 12, Track106, 12, Track107, 0, Track108  ; 5408 pos 60
Song0_Pos061:
    POS Track000, 0, Track000, 0, Track000, 0, Track000  ; 5413 pos 61
Song0_Pos062:
    POS Track000, 0, Track000, 0, Track000, 0, Track000  ; 541E pos 62
Song0_Pos063:
    POS Track000, 0, Track000, 0, Track000, 0, Track000  ; 5429 pos 63

;; Track pointer table (left over from the converter: this build reads the track pointers straight from the positions)
Song0_Tracks:
    dw Track000                                  ; 5434  track 0
    dw Track001                                  ; 5436  track 1
    dw Track002                                  ; 5438  track 2
    dw Track003                                  ; 543A  track 3
    dw Track004                                  ; 543C  track 4
    dw Track005                                  ; 543E  track 5
    dw Track006                                  ; 5440  track 6
    dw Track007                                  ; 5442  track 7
    dw Track008                                  ; 5444  track 8
    dw Track009                                  ; 5446  track 9
    dw Track010                                  ; 5448  track 10
    dw Track011                                  ; 544A  track 11
    dw Track012                                  ; 544C  track 12
    dw Track013                                  ; 544E  track 13
    dw Track014                                  ; 5450  track 14
    dw Track015                                  ; 5452  track 15
    dw Track016                                  ; 5454  track 16
    dw Track017                                  ; 5456  track 17
    dw Track018                                  ; 5458  track 18
    dw Track019                                  ; 545A  track 19
    dw Track020                                  ; 545C  track 20
    dw Track021                                  ; 545E  track 21
    dw Track022                                  ; 5460  track 22
    dw Track023                                  ; 5462  track 23
    dw Track024                                  ; 5464  track 24
    dw Track025                                  ; 5466  track 25
    dw Track026                                  ; 5468  track 26
    dw Track027                                  ; 546A  track 27
    dw Track028                                  ; 546C  track 28
    dw Track029                                  ; 546E  track 29
    dw Track030                                  ; 5470  track 30
    dw Track031                                  ; 5472  track 31
    dw Track032                                  ; 5474  track 32
    dw Track033                                  ; 5476  track 33
    dw Track034                                  ; 5478  track 34
    dw Track035                                  ; 547A  track 35
    dw Track036                                  ; 547C  track 36
    dw Track037                                  ; 547E  track 37
    dw Track038                                  ; 5480  track 38
    dw Track039                                  ; 5482  track 39
    dw Track040                                  ; 5484  track 40
    dw Track041                                  ; 5486  track 41
    dw Track042                                  ; 5488  track 42
    dw Track043                                  ; 548A  track 43
    dw Track044                                  ; 548C  track 44
    dw Track045                                  ; 548E  track 45
    dw Track046                                  ; 5490  track 46
    dw Track047                                  ; 5492  track 47
    dw Track048                                  ; 5494  track 48
    dw Track049                                  ; 5496  track 49
    dw Track050                                  ; 5498  track 50
    dw Track051                                  ; 549A  track 51
    dw Track052                                  ; 549C  track 52
    dw Track053                                  ; 549E  track 53
    dw Track054                                  ; 54A0  track 54
    dw Track055                                  ; 54A2  track 55
    dw Track056                                  ; 54A4  track 56
    dw Track057                                  ; 54A6  track 57
    dw Track058                                  ; 54A8  track 58
    dw Track059                                  ; 54AA  track 59
    dw Track060                                  ; 54AC  track 60
    dw Track061                                  ; 54AE  track 61
    dw Track062                                  ; 54B0  track 62
    dw Track063                                  ; 54B2  track 63
    dw Track064                                  ; 54B4  track 64
    dw Track065                                  ; 54B6  track 65
    dw Track066                                  ; 54B8  track 66
    dw Track067                                  ; 54BA  track 67
    dw Track068                                  ; 54BC  track 68
    dw Track069                                  ; 54BE  track 69
    dw Track070                                  ; 54C0  track 70
    dw Track071                                  ; 54C2  track 71
    dw Track072                                  ; 54C4  track 72
    dw Track073                                  ; 54C6  track 73
    dw Track074                                  ; 54C8  track 74
    dw Track075                                  ; 54CA  track 75
    dw Track076                                  ; 54CC  track 76
    dw Track077                                  ; 54CE  track 77
    dw Track078                                  ; 54D0  track 78
    dw Track079                                  ; 54D2  track 79
    dw Track080                                  ; 54D4  track 80
    dw Track081                                  ; 54D6  track 81
    dw Track082                                  ; 54D8  track 82
    dw Track083                                  ; 54DA  track 83
    dw Track084                                  ; 54DC  track 84
    dw Track085                                  ; 54DE  track 85
    dw Track086                                  ; 54E0  track 86
    dw Track087                                  ; 54E2  track 87
    dw Track088                                  ; 54E4  track 88
    dw Track089                                  ; 54E6  track 89
    dw Track090                                  ; 54E8  track 90
    dw Track091                                  ; 54EA  track 91
    dw Track092                                  ; 54EC  track 92
    dw Track093                                  ; 54EE  track 93
    dw Track094                                  ; 54F0  track 94
    dw Track095                                  ; 54F2  track 95
    dw Track096                                  ; 54F4  track 96
    dw Track097                                  ; 54F6  track 97
    dw Track098                                  ; 54F8  track 98
    dw Track099                                  ; 54FA  track 99
    dw Track100                                  ; 54FC  track 100
    dw Track101                                  ; 54FE  track 101
    dw Track102                                  ; 5500  track 102
    dw Track103                                  ; 5502  track 103
    dw Track104                                  ; 5504  track 104
    dw Track105                                  ; 5506  track 105
    dw Track106                                  ; 5508  track 106
    dw Track107                                  ; 550A  track 107
    dw Track108                                  ; 550C  track 108
    dw Track109                                  ; 550E  track 109
Song0_Instruments:
    dw Inst00                                    ; 5510  instrument 0 (ch1,ch2)
    dw Inst01                                    ; 5512  instrument 1 (ch3)
    dw Inst02                                    ; 5514  instrument 2 (ch1,ch2)
    dw Inst03                                    ; 5516  instrument 3 (ch1,ch2)
    dw Inst04                                    ; 5518  instrument 4 (ch2)
    dw Inst05                                    ; 551A  instrument 5 (ch2)
    dw Inst06                                    ; 551C  instrument 6 (ch2)
    dw Inst07                                    ; 551E  instrument 7 (ch3)
    dw Inst08                                    ; 5520  instrument 8 (ch4)
    dw Inst09                                    ; 5522  instrument 9 (ch3)
    dw Inst10                                    ; 5524  instrument 10 (ch4)
    dw Inst11                                    ; 5526  instrument 11 (ch4)
    dw Inst12                                    ; 5528  instrument 12 (unused)
    dw Inst13                                    ; 552A  instrument 13 (ch1,ch2)
    dw Inst14                                    ; 552C  instrument 14 (ch1,ch2)
    dw Inst15                                    ; 552E  instrument 15 (ch1,ch2)
    dw Inst16                                    ; 5530  instrument 16 (ch2)
    dw Inst17                                    ; 5532  instrument 17 (ch2)
    dw Inst18                                    ; 5534  instrument 18 (ch1)
    dw Inst19                                    ; 5536  instrument 19 (ch2)
    dw Inst20                                    ; 5538  instrument 20 (ch4)
    dw Inst21                                    ; 553A  instrument 21 (ch4)
    dw Inst22                                    ; 553C  instrument 22 (ch4)
    dw Inst23                                    ; 553E  instrument 23 (ch2)
    dw Inst24                                    ; 5540  instrument 24 (ch3)
    dw Inst25                                    ; 5542  instrument 25 (ch2)
    dw Inst26                                    ; 5544  instrument 26 (ch2)
    dw Inst27                                    ; 5546  instrument 27 (ch2)
    dw Inst28                                    ; 5548  instrument 28 (ch1)
    dw Inst29                                    ; 554A  instrument 29 (ch2)
    dw Inst30                                    ; 554C  instrument 30 (ch1,ch2)
    dw Inst31                                    ; 554E  instrument 31 (unused)
Inst00:
    db $05                                       ; 5550 square, 5 steps
    db $05                                       ; playlist speed
    db $D3                                       ; NRx2 envelope
    db $01, $4F, $C0                             ; step 0: +0  vol 15, duty 0
    db $0D, $4F, $00                             ; step 1: +12  vol 15
    db $01, $00, $00                             ; step 2: +0
    db $0D, $00, $00                             ; step 3: +12
    db $01, $00, $82                             ; step 4: +0  jump -2
Inst01:
    db $03                                       ; 5562 wave, 3 steps
    db $85                                       ; playlist speed | $80 = vibrato
    db $20                                       ; NR32 level
    db $00, $48                                  ; vibrato delay, depth<<4|speed
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $000E, $0002, $0010                       ; position, lower bound, upper bound
    db $0A                                       ; sweep speed
    db LOW(WaveData00), HIGH(WaveData00)         ; wave data base
    db $01, $00, $C0                             ; step 0: +0  sweep on/off
    db $00, $00, $00                             ; step 1: -
    db $00, $00, $00                             ; step 2: -
Inst02:
    db $02                                       ; 557B square, 2 steps
    db $81                                       ; playlist speed | $80 = vibrato
    db $09                                       ; NRx2 envelope
    db $20, $47                                  ; vibrato delay, depth<<4|speed
    db $01, $00, $C2                             ; step 0: +0  duty 2
    db $00, $C2, $81                             ; step 1: -  duty 2, jump -1
Inst03:
    db $0A                                       ; 5586 square, 10 steps
    db $82                                       ; playlist speed | $80 = vibrato
    db $E7                                       ; NRx2 envelope
    db $0A, $47                                  ; vibrato delay, depth<<4|speed
    db $19, $00, $C0                             ; step 0: +24  duty 0
    db $00, $00, $00                             ; step 1: -
    db $0D, $00, $C1                             ; step 2: +12  duty 1
    db $00, $00, $00                             ; step 3: -
    db $00, $00, $C2                             ; step 4: -  duty 2
    db $00, $00, $00                             ; step 5: -
    db $00, $00, $C1                             ; step 6: -  duty 1
    db $00, $00, $00                             ; step 7: -
    db $00, $00, $C0                             ; step 8: -  duty 0
    db $00, $00, $88                             ; step 9: -  jump -8
Inst04:
    db $04                                       ; 55A9 square, 4 steps
    db $03                                       ; playlist speed
    db $C7                                       ; NRx2 envelope
    db $0D, $00, $C1                             ; step 0: +12  duty 1
    db $12, $00, $00                             ; step 1: +17
    db $14, $00, $83                             ; step 2: +19  jump -3
    db $00, $00, $00                             ; step 3: -
Inst05:
    db $04                                       ; 55B8 square, 4 steps
    db $03                                       ; playlist speed
    db $C7                                       ; NRx2 envelope
    db $0D, $00, $C1                             ; step 0: +12  duty 1
    db $11, $00, $00                             ; step 1: +16
    db $14, $00, $83                             ; step 2: +19  jump -3
    db $00, $00, $00                             ; step 3: -
Inst06:
    db $04                                       ; 55C7 square, 4 steps
    db $03                                       ; playlist speed
    db $C7                                       ; NRx2 envelope
    db $0C, $00, $C1                             ; step 0: +11  duty 1
    db $0F, $00, $00                             ; step 1: +14
    db $14, $00, $83                             ; step 2: +19  jump -3
    db $00, $00, $00                             ; step 3: -
Inst07:
    db $11                                       ; 55D6 wave, 17 steps
    db $01                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $01                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0002, $0010                       ; position, lower bound, upper bound
    db $0A                                       ; sweep speed
    db LOW(WaveData01), HIGH(WaveData01)         ; wave data base
    db $65, $00, $00                             ; step 0: C-5
    db $64, $00, $00                             ; step 1: B-4
    db $62, $00, $00                             ; step 2: A-4
    db $60, $00, $00                             ; step 3: G-4
    db $5E, $00, $00                             ; step 4: F-4
    db $65, $00, $00                             ; step 5: C-5
    db $64, $00, $00                             ; step 6: B-4
    db $62, $00, $00                             ; step 7: A-4
    db $60, $00, $00                             ; step 8: G-4
    db $5E, $00, $00                             ; step 9: F-4
    db $65, $00, $00                             ; step 10: C-5
    db $64, $00, $00                             ; step 11: B-4
    db $62, $00, $00                             ; step 12: A-4
    db $5E, $00, $00                             ; step 13: F-4
    db $00, $00, $40                             ; step 14: -  level 0
    db $00, $00, $00                             ; step 15: -
    db $00, $00, $00                             ; step 16: -
Inst08:
    db $02                                       ; 5617 noise, 2 steps
    db $02                                       ; playlist speed
    db $C2                                       ; NR42 envelope
    db $7A, $00, $00                             ; step 0: A-6
    db $59, $00, $82                             ; step 1: C-4  jump -2
Inst09:
    db $03                                       ; 5620 wave, 3 steps
    db $85                                       ; playlist speed | $80 = vibrato
    db $20                                       ; NR32 level
    db $00, $48                                  ; vibrato delay, depth<<4|speed
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0006, $0002, $0010                       ; position, lower bound, upper bound
    db $0A                                       ; sweep speed
    db LOW(WaveData00), HIGH(WaveData00)         ; wave data base
    db $0D, $00, $C0                             ; step 0: +12  sweep on/off
    db $01, $00, $00                             ; step 1: +0
    db $00, $00, $00                             ; step 2: -
Inst10:
    db $03                                       ; 5639 noise, 3 steps
    db $01                                       ; playlist speed
    db $A1                                       ; NR42 envelope
    db $7A, $00, $00                             ; step 0: A-6
    db $59, $00, $00                             ; step 1: C-4
    db $00, $00, $40                             ; step 2: -  vol 0
Inst11:
    db $03                                       ; 5645 noise, 3 steps
    db $01                                       ; playlist speed
    db $C5                                       ; NR42 envelope
    db $7A, $00, $00                             ; step 0: A-6
    db $59, $00, $00                             ; step 1: C-4
    db $00, $00, $83                             ; step 2: -  jump -3
Inst12:
    db $02                                       ; 5651 square, 2 steps
    db $81                                       ; playlist speed | $80 = vibrato
    db $D7                                       ; NRx2 envelope
    db $00, $47                                  ; vibrato delay, depth<<4|speed
    db $01, $00, $C2                             ; step 0: +0  duty 2
    db $00, $C2, $81                             ; step 1: -  duty 2, jump -1
Inst13:
    db $06                                       ; 565C square, 6 steps
    db $03                                       ; playlist speed
    db $0F                                       ; NRx2 envelope
    db $0F, $00, $C1                             ; step 0: +14  duty 1
    db $14, $00, $00                             ; step 1: +19
    db $18, $00, $00                             ; step 2: +23
    db $1B, $00, $00                             ; step 3: +26
    db $18, $00, $00                             ; step 4: +23
    db $14, $00, $86                             ; step 5: +19  jump -6
Inst14:
    db $06                                       ; 5671 square, 6 steps
    db $03                                       ; playlist speed
    db $F7                                       ; NRx2 envelope
    db $0F, $00, $C1                             ; step 0: +14  duty 1
    db $12, $00, $00                             ; step 1: +17
    db $16, $00, $00                             ; step 2: +21
    db $19, $00, $00                             ; step 3: +24
    db $16, $00, $00                             ; step 4: +21
    db $12, $00, $86                             ; step 5: +17  jump -6
Inst15:
    db $03                                       ; 5686 square, 3 steps
    db $85                                       ; playlist speed | $80 = vibrato
    db $F2                                       ; NRx2 envelope
    db $0B, $17                                  ; vibrato delay, depth<<4|speed
    db $01, $00, $C0                             ; step 0: +0  duty 0
    db $0D, $C2, $82                             ; step 1: +12  duty 2, jump -2
    db $00, $00, $00                             ; step 2: -
Inst16:
    db $06                                       ; 5694 square, 6 steps
    db $02                                       ; playlist speed
    db $D7                                       ; NRx2 envelope
    db $0D, $00, $C2                             ; step 0: +12  duty 2
    db $0F, $00, $00                             ; step 1: +14
    db $10, $00, $00                             ; step 2: +15
    db $14, $00, $84                             ; step 3: +19  jump -4
    db $00, $00, $00                             ; step 4: -
    db $00, $00, $00                             ; step 5: -
Inst17:
    db $06                                       ; 56A9 square, 6 steps
    db $02                                       ; playlist speed
    db $D7                                       ; NRx2 envelope
    db $0D, $00, $C2                             ; step 0: +12  duty 2
    db $10, $00, $00                             ; step 1: +15
    db $15, $00, $00                             ; step 2: +20
    db $09, $00, $84                             ; step 3: +8  jump -4
    db $00, $00, $00                             ; step 4: -
    db $00, $00, $00                             ; step 5: -
Inst18:
    db $02                                       ; 56BE square, 2 steps
    db $81                                       ; playlist speed | $80 = vibrato
    db $D0                                       ; NRx2 envelope
    db $20, $47                                  ; vibrato delay, depth<<4|speed
    db $01, $00, $C2                             ; step 0: +0  duty 2
    db $00, $C2, $81                             ; step 1: -  duty 2, jump -1
Inst19:
    db $06                                       ; 56C9 square, 6 steps
    db $02                                       ; playlist speed
    db $D7                                       ; NRx2 envelope
    db $09, $00, $C2                             ; step 0: +8  duty 2
    db $0D, $00, $00                             ; step 1: +12
    db $10, $00, $00                             ; step 2: +15
    db $15, $00, $84                             ; step 3: +20  jump -4
    db $00, $00, $00                             ; step 4: -
    db $00, $00, $00                             ; step 5: -
Inst20:
    db $02                                       ; 56DE noise, 2 steps
    db $05                                       ; playlist speed
    db $87                                       ; NR42 envelope
    db $01, $00, $00                             ; step 0: +0
    db $0D, $00, $82                             ; step 1: +12  jump -2
Inst21:
    db $02                                       ; 56E7 noise, 2 steps
    db $0B                                       ; playlist speed
    db $80                                       ; NR42 envelope
    db $01, $00, $00                             ; step 0: +0
    db $00, $00, $44                             ; step 1: -  vol 4
Inst22:
    db $02                                       ; 56F0 noise, 2 steps
    db $05                                       ; playlist speed
    db $C7                                       ; NR42 envelope
    db $01, $00, $00                             ; step 0: +0
    db $0D, $00, $82                             ; step 1: +12  jump -2
Inst23:
    db $06                                       ; 56F9 square, 6 steps
    db $02                                       ; playlist speed
    db $D7                                       ; NRx2 envelope
    db $18, $00, $C2                             ; step 0: +23  duty 2
    db $1B, $00, $00                             ; step 1: +26
    db $1E, $00, $00                             ; step 2: +29
    db $24, $00, $84                             ; step 3: +35  jump -4
    db $00, $00, $00                             ; step 4: -
    db $00, $00, $00                             ; step 5: -
Inst24:
    db $01                                       ; 570E wave, 1 steps
    db $81                                       ; playlist speed | $80 = vibrato
    db $00                                       ; NR32 level
    db $00, $48                                  ; vibrato delay, depth<<4|speed
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $000E, $0002, $0010                       ; position, lower bound, upper bound
    db $0A                                       ; sweep speed
    db LOW(WaveData00), HIGH(WaveData00)         ; wave data base
    db $01, $00, $00                             ; step 0: +0
Inst25:
    db $04                                       ; 5721 square, 4 steps
    db $02                                       ; playlist speed
    db $D7                                       ; NRx2 envelope
    db $0D, $00, $C1                             ; step 0: +12  duty 1
    db $10, $00, $C2                             ; step 1: +15  duty 2
    db $14, $C1, $83                             ; step 2: +19  duty 1, jump -3
    db $00, $00, $00                             ; step 3: -
Inst26:
    db $04                                       ; 5730 square, 4 steps
    db $02                                       ; playlist speed
    db $D7                                       ; NRx2 envelope
    db $0D, $00, $C1                             ; step 0: +12  duty 1
    db $0F, $00, $C2                             ; step 1: +14  duty 2
    db $14, $C1, $83                             ; step 2: +19  duty 1, jump -3
    db $00, $00, $00                             ; step 3: -
Inst27:
    db $04                                       ; 573F square, 4 steps
    db $02                                       ; playlist speed
    db $D7                                       ; NRx2 envelope
    db $0D, $00, $C1                             ; step 0: +12  duty 1
    db $0F, $00, $C2                             ; step 1: +14  duty 2
    db $13, $C1, $83                             ; step 2: +18  duty 1, jump -3
    db $00, $00, $00                             ; step 3: -
Inst28:
    db $05                                       ; 574E square, 5 steps
    db $88                                       ; playlist speed | $80 = vibrato
    db $4A                                       ; NRx2 envelope
    db $20, $47                                  ; vibrato delay, depth<<4|speed
    db $01, $00, $C2                             ; step 0: +0  duty 2
    db $00, $00, $C0                             ; step 1: -  duty 0
    db $00, $00, $C1                             ; step 2: -  duty 1
    db $00, $00, $C2                             ; step 3: -  duty 2
    db $00, $C1, $84                             ; step 4: -  duty 1, jump -4
Inst29:
    db $04                                       ; 5762 square, 4 steps
    db $02                                       ; playlist speed
    db $D7                                       ; NRx2 envelope
    db $0C, $00, $C1                             ; step 0: +11  duty 1
    db $0F, $00, $C2                             ; step 1: +14  duty 2
    db $14, $C1, $83                             ; step 2: +19  duty 1, jump -3
    db $00, $00, $00                             ; step 3: -
Inst30:
    db $05                                       ; 5771 square, 5 steps
    db $88                                       ; playlist speed | $80 = vibrato
    db $F7                                       ; NRx2 envelope
    db $00, $47                                  ; vibrato delay, depth<<4|speed
    db $01, $00, $C1                             ; step 0: +0  duty 1
    db $00, $00, $C2                             ; step 1: -  duty 2
    db $00, $00, $C1                             ; step 2: -  duty 1
    db $00, $00, $C0                             ; step 3: -  duty 0
    db $00, $C1, $84                             ; step 4: -  duty 1, jump -4
Inst31:
    db $05                                       ; 5785 square, 5 steps
    db $83                                       ; playlist speed | $80 = vibrato
    db $91                                       ; NRx2 envelope
    db $20, $47                                  ; vibrato delay, depth<<4|speed
    db $01, $00, $C2                             ; step 0: +0  duty 2
    db $00, $00, $C0                             ; step 1: -  duty 0
    db $00, $00, $4A                             ; step 2: -  vol 10
    db $00, $00, $C2                             ; step 3: -  duty 2
    db $00, $00, $C0                             ; step 4: -  duty 0
Track000:
    R   ___                                     ; 5799 row 00
    R   ___                                     ; 579A row 01
    R   ___                                     ; 579B row 02
    R   ___                                     ; 579C row 03
    R   ___                                     ; 579D row 04
    R   ___                                     ; 579E row 05
    R   ___                                     ; 579F row 06
    R   ___                                     ; 57A0 row 07
    R   ___                                     ; 57A1 row 08
    R   ___                                     ; 57A2 row 09
    R   ___                                     ; 57A3 row 10
    R   ___                                     ; 57A4 row 11
    R   ___                                     ; 57A5 row 12
    R   ___                                     ; 57A6 row 13
    R   ___                                     ; 57A7 row 14
    R   ___                                     ; 57A8 row 15
    R   ___                                     ; 57A9 row 16
    R   ___                                     ; 57AA row 17
    R   ___                                     ; 57AB row 18
    R   ___                                     ; 57AC row 19
    R   ___                                     ; 57AD row 20
    R   ___                                     ; 57AE row 21
    R   ___                                     ; 57AF row 22
    R   ___                                     ; 57B0 row 23
    R   ___                                     ; 57B1 row 24
    R   ___                                     ; 57B2 row 25
    R   ___                                     ; 57B3 row 26
    R   ___                                     ; 57B4 row 27
    R   ___                                     ; 57B5 row 28
    R   ___                                     ; 57B6 row 29
    R   ___                                     ; 57B7 row 30
    R   ___                                     ; 57B8 row 31
Track001:
    RIF D_3, 1, 0, $F, $A                       ; 57B9 row 00  Inst00  speed 10
    R   ___                                     ; 57BC row 01
    R   ___                                     ; 57BD row 02
    R   ___                                     ; 57BE row 03
    RI  D_4, 1, 0                               ; 57BF row 04  Inst00
    R   ___                                     ; 57C1 row 05
    R   ___                                     ; 57C2 row 06
    R   ___                                     ; 57C3 row 07
    RI  D_5, 1, 0                               ; 57C4 row 08  Inst00
    R   ___                                     ; 57C6 row 09
    R   ___                                     ; 57C7 row 10
    R   ___                                     ; 57C8 row 11
    RI  D_4, 1, 0                               ; 57C9 row 12  Inst00
    R   ___                                     ; 57CB row 13
    R   ___                                     ; 57CC row 14
    R   ___                                     ; 57CD row 15
    RI  D_3, 1, 0                               ; 57CE row 16  Inst00
    R   ___                                     ; 57D0 row 17
    R   ___                                     ; 57D1 row 18
    R   ___                                     ; 57D2 row 19
    RI  C_4, 1, 0                               ; 57D3 row 20  Inst00
    R   ___                                     ; 57D5 row 21
    R   ___                                     ; 57D6 row 22
    R   ___                                     ; 57D7 row 23
    RI  C_5, 1, 0                               ; 57D8 row 24  Inst00
    R   ___                                     ; 57DA row 25
    R   ___                                     ; 57DB row 26
    R   ___                                     ; 57DC row 27
    RI  C_4, 1, 0                               ; 57DD row 28  Inst00
    R   ___                                     ; 57DF row 29
    R   ___                                     ; 57E0 row 30
    R   ___                                     ; 57E1 row 31
Track002:
    R   ___                                     ; 57E2 row 00
    R   ___                                     ; 57E3 row 01
    RI  G_3, 1, 0                               ; 57E4 row 02  Inst00
    R   ___                                     ; 57E6 row 03
    R   ___                                     ; 57E7 row 04
    R   ___                                     ; 57E8 row 05
    RI  G_4, 1, 0                               ; 57E9 row 06  Inst00
    R   ___                                     ; 57EB row 07
    R   ___                                     ; 57EC row 08
    R   ___                                     ; 57ED row 09
    RI  G_4, 1, 0                               ; 57EE row 10  Inst00
    R   ___                                     ; 57F0 row 11
    R   ___                                     ; 57F1 row 12
    R   ___                                     ; 57F2 row 13
    RI  G_3, 1, 0                               ; 57F3 row 14  Inst00
    R   ___                                     ; 57F5 row 15
    R   ___                                     ; 57F6 row 16
    R   ___                                     ; 57F7 row 17
    RI  G_3, 1, 0                               ; 57F8 row 18  Inst00
    R   ___                                     ; 57FA row 19
    R   ___                                     ; 57FB row 20
    R   ___                                     ; 57FC row 21
    RI  G_4, 1, 0                               ; 57FD row 22  Inst00
    R   ___                                     ; 57FF row 23
    R   ___                                     ; 5800 row 24
    R   ___                                     ; 5801 row 25
    RI  G_4, 1, 0                               ; 5802 row 26  Inst00
    R   ___                                     ; 5804 row 27
    R   ___                                     ; 5805 row 28
    R   ___                                     ; 5806 row 29
    RI  G_3, 1, 0                               ; 5807 row 30  Inst00
    R   ___                                     ; 5809 row 31
Track003:
    RI  G_3, 2, 0                               ; 580A row 00  Inst01
    R   ___                                     ; 580C row 01
    R   ___                                     ; 580D row 02
    R   ___                                     ; 580E row 03
    R   ___                                     ; 580F row 04
    R   ___                                     ; 5810 row 05
    R   ___                                     ; 5811 row 06
    R   ___                                     ; 5812 row 07
    R   ___                                     ; 5813 row 08
    R   ___                                     ; 5814 row 09
    R   ___                                     ; 5815 row 10
    R   ___                                     ; 5816 row 11
    R   ___                                     ; 5817 row 12
    R   ___                                     ; 5818 row 13
    R   ___                                     ; 5819 row 14
    R   ___                                     ; 581A row 15
    R   ___                                     ; 581B row 16
    R   ___                                     ; 581C row 17
    R   ___                                     ; 581D row 18
    R   ___                                     ; 581E row 19
    R   ___                                     ; 581F row 20
    R   ___                                     ; 5820 row 21
    R   ___                                     ; 5821 row 22
    R   ___                                     ; 5822 row 23
    R   ___                                     ; 5823 row 24
    R   ___                                     ; 5824 row 25
    R   ___                                     ; 5825 row 26
    R   ___                                     ; 5826 row 27
    RI  F_3, 2, 0                               ; 5827 row 28  Inst01
    R   ___                                     ; 5829 row 29
    R   ___                                     ; 582A row 30
    R   ___                                     ; 582B row 31
Track004:
    RIF D_3, 1, 0, $F, $A                       ; 582C row 00  Inst00  speed 10
    R   ___                                     ; 582F row 01
    RI  G_3, 1, 0                               ; 5830 row 02  Inst00
    R   ___                                     ; 5832 row 03
    RI  D_4, 1, 0                               ; 5833 row 04  Inst00
    R   ___                                     ; 5835 row 05
    RI  G_4, 1, 0                               ; 5836 row 06  Inst00
    R   ___                                     ; 5838 row 07
    RI  D_5, 1, 0                               ; 5839 row 08  Inst00
    R   ___                                     ; 583B row 09
    RI  G_4, 1, 0                               ; 583C row 10  Inst00
    R   ___                                     ; 583E row 11
    RI  D_4, 1, 0                               ; 583F row 12  Inst00
    R   ___                                     ; 5841 row 13
    RI  G_3, 1, 0                               ; 5842 row 14  Inst00
    R   ___                                     ; 5844 row 15
    RI  D_3, 1, 0                               ; 5845 row 16  Inst00
    R   ___                                     ; 5847 row 17
    RI  G_3, 1, 0                               ; 5848 row 18  Inst00
    R   ___                                     ; 584A row 19
    RI  C_4, 1, 0                               ; 584B row 20  Inst00
    R   ___                                     ; 584D row 21
    RI  G_4, 1, 0                               ; 584E row 22  Inst00
    R   ___                                     ; 5850 row 23
    RI  C_5, 1, 0                               ; 5851 row 24  Inst00
    R   ___                                     ; 5853 row 25
    RI  G_4, 1, 0                               ; 5854 row 26  Inst00
    R   ___                                     ; 5856 row 27
    RI  C_4, 1, 0                               ; 5857 row 28  Inst00
    R   ___                                     ; 5859 row 29
    RI  G_3, 1, 0                               ; 585A row 30  Inst00
    R   ___                                     ; 585C row 31
Track005:
    RI  G_4, 3, 0                               ; 585D row 00  Inst02
    R   ___                                     ; 585F row 01
    R   ___                                     ; 5860 row 02
    R   ___                                     ; 5861 row 03
    R   ___                                     ; 5862 row 04
    R   ___                                     ; 5863 row 05
    R   ___                                     ; 5864 row 06
    R   ___                                     ; 5865 row 07
    R   ___                                     ; 5866 row 08
    R   ___                                     ; 5867 row 09
    R   ___                                     ; 5868 row 10
    R   ___                                     ; 5869 row 11
    R   ___                                     ; 586A row 12
    R   ___                                     ; 586B row 13
    R   ___                                     ; 586C row 14
    R   ___                                     ; 586D row 15
    R   ___                                     ; 586E row 16
    R   ___                                     ; 586F row 17
    R   ___                                     ; 5870 row 18
    R   ___                                     ; 5871 row 19
    R   ___                                     ; 5872 row 20
    R   ___                                     ; 5873 row 21
    R   ___                                     ; 5874 row 22
    R   ___                                     ; 5875 row 23
    RI  A_4, 3, 0                               ; 5876 row 24  Inst02
    R   ___                                     ; 5878 row 25
    R   ___                                     ; 5879 row 26
    R   ___                                     ; 587A row 27
    RI  F_4, 3, 0                               ; 587B row 28  Inst02
    R   ___                                     ; 587D row 29
    R   ___                                     ; 587E row 30
    R   ___                                     ; 587F row 31
Track006:
    RI  G_4, 3, 0                               ; 5880 row 00  Inst02
    R   ___                                     ; 5882 row 01
    R   ___                                     ; 5883 row 02
    R   ___                                     ; 5884 row 03
    R   ___                                     ; 5885 row 04
    R   ___                                     ; 5886 row 05
    R   ___                                     ; 5887 row 06
    R   ___                                     ; 5888 row 07
    RI  G_3, 4, 0                               ; 5889 row 08  Inst03
    R   ___                                     ; 588B row 09
    RI  F_3, 4, 0                               ; 588C row 10  Inst03
    R   ___                                     ; 588E row 11
    RI  E_3, 4, 0                               ; 588F row 12  Inst03
    R   ___                                     ; 5891 row 13
    RI  D_3, 4, 0                               ; 5892 row 14  Inst03
    R   ___                                     ; 5894 row 15
    R   ___                                     ; 5895 row 16
    R   ___                                     ; 5896 row 17
    R   ___                                     ; 5897 row 18
    R   ___                                     ; 5898 row 19
    R   ___                                     ; 5899 row 20
    R   ___                                     ; 589A row 21
    R   ___                                     ; 589B row 22
    R   ___                                     ; 589C row 23
    R   ___                                     ; 589D row 24
    R   ___                                     ; 589E row 25
    R   ___                                     ; 589F row 26
    R   ___                                     ; 58A0 row 27
    RI  E_3, 4, 0                               ; 58A1 row 28  Inst03
    R   ___                                     ; 58A3 row 29
    RI  F_3, 4, 0                               ; 58A4 row 30  Inst03
    R   ___                                     ; 58A6 row 31
Track007:
    RIF D_3, 1, 0, $F, $5                       ; 58A7 row 00  Inst00  speed 5
    R   ___                                     ; 58AA row 01
    R   ___                                     ; 58AB row 02
    R   ___                                     ; 58AC row 03
    RI  G_3, 1, 0                               ; 58AD row 04  Inst00
    R   ___                                     ; 58AF row 05
    R   ___                                     ; 58B0 row 06
    R   ___                                     ; 58B1 row 07
    R   ___                                     ; 58B2 row 08
    R   ___                                     ; 58B3 row 09
    R   ___                                     ; 58B4 row 10
    R   ___                                     ; 58B5 row 11
    RI  G_4, 1, 0                               ; 58B6 row 12  Inst00
    R   ___                                     ; 58B8 row 13
    R   ___                                     ; 58B9 row 14
    R   ___                                     ; 58BA row 15
    R   ___                                     ; 58BB row 16
    R   ___                                     ; 58BC row 17
    R   ___                                     ; 58BD row 18
    R   ___                                     ; 58BE row 19
    RI  G_4, 1, 0                               ; 58BF row 20  Inst00
    R   ___                                     ; 58C1 row 21
    R   ___                                     ; 58C2 row 22
    R   ___                                     ; 58C3 row 23
    R   ___                                     ; 58C4 row 24
    R   ___                                     ; 58C5 row 25
    R   ___                                     ; 58C6 row 26
    R   ___                                     ; 58C7 row 27
    RI  G_3, 1, 0                               ; 58C8 row 28  Inst00
    R   ___                                     ; 58CA row 29
    R   ___                                     ; 58CB row 30
    R   ___                                     ; 58CC row 31
Track008:
    RI  G_3, 2, 0                               ; 58CD row 00  Inst01
    R   ___                                     ; 58CF row 01
    R   ___                                     ; 58D0 row 02
    R   ___                                     ; 58D1 row 03
    R   ___                                     ; 58D2 row 04
    R   ___                                     ; 58D3 row 05
    R   ___                                     ; 58D4 row 06
    R   ___                                     ; 58D5 row 07
    R   ___                                     ; 58D6 row 08
    R   ___                                     ; 58D7 row 09
    R   ___                                     ; 58D8 row 10
    R   ___                                     ; 58D9 row 11
    R   ___                                     ; 58DA row 12
    R   ___                                     ; 58DB row 13
    R   ___                                     ; 58DC row 14
    R   ___                                     ; 58DD row 15
    R   ___                                     ; 58DE row 16
    R   ___                                     ; 58DF row 17
    R   ___                                     ; 58E0 row 18
    R   ___                                     ; 58E1 row 19
    R   ___                                     ; 58E2 row 20
    R   ___                                     ; 58E3 row 21
    R   ___                                     ; 58E4 row 22
    R   ___                                     ; 58E5 row 23
    R   ___                                     ; 58E6 row 24
    R   ___                                     ; 58E7 row 25
    R   ___                                     ; 58E8 row 26
    R   ___                                     ; 58E9 row 27
    R   ___                                     ; 58EA row 28
    R   ___                                     ; 58EB row 29
    R   ___                                     ; 58EC row 30
    R   ___                                     ; 58ED row 31
Track009:
    RI  D_3, 1, 0                               ; 58EE row 00  Inst00
    R   ___                                     ; 58F0 row 01
    R   ___                                     ; 58F1 row 02
    R   ___                                     ; 58F2 row 03
    RI  G_3, 1, 0                               ; 58F3 row 04  Inst00
    R   ___                                     ; 58F5 row 05
    R   ___                                     ; 58F6 row 06
    R   ___                                     ; 58F7 row 07
    RI  C_4, 1, 0                               ; 58F8 row 08  Inst00
    R   ___                                     ; 58FA row 09
    R   ___                                     ; 58FB row 10
    R   ___                                     ; 58FC row 11
    RI  G_4, 1, 0                               ; 58FD row 12  Inst00
    R   ___                                     ; 58FF row 13
    R   ___                                     ; 5900 row 14
    R   ___                                     ; 5901 row 15
    RI  C_5, 1, 0                               ; 5902 row 16  Inst00
    R   ___                                     ; 5904 row 17
    R   ___                                     ; 5905 row 18
    R   ___                                     ; 5906 row 19
    RI  G_4, 1, 0                               ; 5907 row 20  Inst00
    R   ___                                     ; 5909 row 21
    R   ___                                     ; 590A row 22
    R   ___                                     ; 590B row 23
    RI  C_4, 1, 0                               ; 590C row 24  Inst00
    R   ___                                     ; 590E row 25
    R   ___                                     ; 590F row 26
    R   ___                                     ; 5910 row 27
    RI  G_3, 1, 0                               ; 5911 row 28  Inst00
    R   ___                                     ; 5913 row 29
    R   ___                                     ; 5914 row 30
    R   ___                                     ; 5915 row 31
Track010:
    RI  E_3, 4, 0                               ; 5916 row 00  Inst03
    R   ___                                     ; 5918 row 01
    R   ___                                     ; 5919 row 02
    R   ___                                     ; 591A row 03
    R   ___                                     ; 591B row 04
    R   ___                                     ; 591C row 05
    R   ___                                     ; 591D row 06
    R   ___                                     ; 591E row 07
    RI  C_3, 4, 0                               ; 591F row 08  Inst03
    R   ___                                     ; 5921 row 09
    R   ___                                     ; 5922 row 10
    R   ___                                     ; 5923 row 11
    R   ___                                     ; 5924 row 12
    R   ___                                     ; 5925 row 13
    R   ___                                     ; 5926 row 14
    R   ___                                     ; 5927 row 15
    R   ___                                     ; 5928 row 16
    R   ___                                     ; 5929 row 17
    R   ___                                     ; 592A row 18
    R   ___                                     ; 592B row 19
    R   ___                                     ; 592C row 20
    R   ___                                     ; 592D row 21
    R   ___                                     ; 592E row 22
    R   ___                                     ; 592F row 23
    RI  As2, 4, 0                               ; 5930 row 24  Inst03
    R   ___                                     ; 5932 row 25
    R   ___                                     ; 5933 row 26
    RI  C_3, 4, 0                               ; 5934 row 27  Inst03
    R   ___                                     ; 5936 row 28
    R   ___                                     ; 5937 row 29
    RI  E_2, 4, 0                               ; 5938 row 30  Inst03
    R   ___                                     ; 593A row 31
Track011:
    RI  D_2, 4, 0                               ; 593B row 00  Inst03
    R   ___                                     ; 593D row 01
    R   ___                                     ; 593E row 02
    R   ___                                     ; 593F row 03
    R   ___                                     ; 5940 row 04
    R   ___                                     ; 5941 row 05
    R   ___                                     ; 5942 row 06
    R   ___                                     ; 5943 row 07
    R   ___                                     ; 5944 row 08
    R   ___                                     ; 5945 row 09
    R   ___                                     ; 5946 row 10
    R   ___                                     ; 5947 row 11
    R   ___                                     ; 5948 row 12
    R   ___                                     ; 5949 row 13
    R   ___                                     ; 594A row 14
    R   ___                                     ; 594B row 15
    R   ___                                     ; 594C row 16
    R   ___                                     ; 594D row 17
    R   ___                                     ; 594E row 18
    R   ___                                     ; 594F row 19
    R   ___                                     ; 5950 row 20
    R   ___                                     ; 5951 row 21
    R   ___                                     ; 5952 row 22
    R   ___                                     ; 5953 row 23
    RI  C_4, 5, 0                               ; 5954 row 24  Inst04
    R   ___                                     ; 5956 row 25
    R   ___                                     ; 5957 row 26
    R   ___                                     ; 5958 row 27
    R   ___                                     ; 5959 row 28
    R   ___                                     ; 595A row 29
    R   ___                                     ; 595B row 30
    R   ___                                     ; 595C row 31
Track012:
    RI  C_4, 6, 0                               ; 595D row 00  Inst05
    R   ___                                     ; 595F row 01
    R   ___                                     ; 5960 row 02
    R   ___                                     ; 5961 row 03
    R   ___                                     ; 5962 row 04
    R   ___                                     ; 5963 row 05
    R   ___                                     ; 5964 row 06
    R   ___                                     ; 5965 row 07
    R   ___                                     ; 5966 row 08
    R   ___                                     ; 5967 row 09
    R   ___                                     ; 5968 row 10
    R   ___                                     ; 5969 row 11
    RI  C_4, 5, 0                               ; 596A row 12  Inst04
    R   ___                                     ; 596C row 13
    R   ___                                     ; 596D row 14
    R   ___                                     ; 596E row 15
    R   ___                                     ; 596F row 16
    R   ___                                     ; 5970 row 17
    R   ___                                     ; 5971 row 18
    R   ___                                     ; 5972 row 19
    R   ___                                     ; 5973 row 20
    R   ___                                     ; 5974 row 21
    R   ___                                     ; 5975 row 22
    R   ___                                     ; 5976 row 23
    RI  C_4, 6, 0                               ; 5977 row 24  Inst05
    R   ___                                     ; 5979 row 25
    R   ___                                     ; 597A row 26
    R   ___                                     ; 597B row 27
    R   ___                                     ; 597C row 28
    R   ___                                     ; 597D row 29
    R   ___                                     ; 597E row 30
    R   ___                                     ; 597F row 31
Track013:
    RI  C_4, 7, 0                               ; 5980 row 00  Inst06
    R   ___                                     ; 5982 row 01
    R   ___                                     ; 5983 row 02
    R   ___                                     ; 5984 row 03
    R   ___                                     ; 5985 row 04
    R   ___                                     ; 5986 row 05
    R   ___                                     ; 5987 row 06
    R   ___                                     ; 5988 row 07
    RI  G_3, 4, 0                               ; 5989 row 08  Inst03
    R   ___                                     ; 598B row 09
    RI  F_3, 4, 0                               ; 598C row 10  Inst03
    R   ___                                     ; 598E row 11
    RI  E_3, 4, 0                               ; 598F row 12  Inst03
    R   ___                                     ; 5991 row 13
    RI  D_3, 4, 0                               ; 5992 row 14  Inst03
    R   ___                                     ; 5994 row 15
    R   ___                                     ; 5995 row 16
    R   ___                                     ; 5996 row 17
    R   ___                                     ; 5997 row 18
    R   ___                                     ; 5998 row 19
    R   ___                                     ; 5999 row 20
    R   ___                                     ; 599A row 21
    R   ___                                     ; 599B row 22
    R   ___                                     ; 599C row 23
    R   ___                                     ; 599D row 24
    R   ___                                     ; 599E row 25
    R   ___                                     ; 599F row 26
    R   ___                                     ; 59A0 row 27
    RI  E_3, 4, 0                               ; 59A1 row 28  Inst03
    R   ___                                     ; 59A3 row 29
    RI  F_3, 4, 0                               ; 59A4 row 30  Inst03
    R   ___                                     ; 59A6 row 31
Track014:
    R   ___                                     ; 59A7 row 00
    R   ___                                     ; 59A8 row 01
    R   ___                                     ; 59A9 row 02
    R   ___                                     ; 59AA row 03
    R   ___                                     ; 59AB row 04
    R   ___                                     ; 59AC row 05
    R   ___                                     ; 59AD row 06
    R   ___                                     ; 59AE row 07
    R   ___                                     ; 59AF row 08
    R   ___                                     ; 59B0 row 09
    R   ___                                     ; 59B1 row 10
    R   ___                                     ; 59B2 row 11
    R   ___                                     ; 59B3 row 12
    R   ___                                     ; 59B4 row 13
    R   ___                                     ; 59B5 row 14
    R   ___                                     ; 59B6 row 15
    R   ___                                     ; 59B7 row 16
    R   ___                                     ; 59B8 row 17
    R   ___                                     ; 59B9 row 18
    R   ___                                     ; 59BA row 19
    R   ___                                     ; 59BB row 20
    R   ___                                     ; 59BC row 21
    R   ___                                     ; 59BD row 22
    R   ___                                     ; 59BE row 23
    RI  F_3, 2, 0                               ; 59BF row 24  Inst01
    R   ___                                     ; 59C1 row 25
    R   ___                                     ; 59C2 row 26
    R   ___                                     ; 59C3 row 27
    R   ___                                     ; 59C4 row 28
    R   ___                                     ; 59C5 row 29
    R   ___                                     ; 59C6 row 30
    R   ___                                     ; 59C7 row 31
Track015:
    R   ___                                     ; 59C8 row 00
    R   ___                                     ; 59C9 row 01
    R   ___                                     ; 59CA row 02
    R   ___                                     ; 59CB row 03
    RI  G_3, 1, 0                               ; 59CC row 04  Inst00
    R   ___                                     ; 59CE row 05
    R   ___                                     ; 59CF row 06
    R   ___                                     ; 59D0 row 07
    R   ___                                     ; 59D1 row 08
    R   ___                                     ; 59D2 row 09
    R   ___                                     ; 59D3 row 10
    R   ___                                     ; 59D4 row 11
    RI  G_4, 1, 0                               ; 59D5 row 12  Inst00
    R   ___                                     ; 59D7 row 13
    R   ___                                     ; 59D8 row 14
    R   ___                                     ; 59D9 row 15
    R   ___                                     ; 59DA row 16
    R   ___                                     ; 59DB row 17
    R   ___                                     ; 59DC row 18
    R   ___                                     ; 59DD row 19
    RI  G_4, 1, 0                               ; 59DE row 20  Inst00
    R   ___                                     ; 59E0 row 21
    R   ___                                     ; 59E1 row 22
    R   ___                                     ; 59E2 row 23
    R   ___                                     ; 59E3 row 24
    R   ___                                     ; 59E4 row 25
    R   ___                                     ; 59E5 row 26
    R   ___                                     ; 59E6 row 27
    RI  G_3, 1, 0                               ; 59E7 row 28  Inst00
    R   ___                                     ; 59E9 row 29
    R   ___                                     ; 59EA row 30
    R   ___                                     ; 59EB row 31
Track016:
    RI  C_4, 7, 0                               ; 59EC row 00  Inst06
    R   ___                                     ; 59EE row 01
    R   ___                                     ; 59EF row 02
    R   ___                                     ; 59F0 row 03
    R   ___                                     ; 59F1 row 04
    R   ___                                     ; 59F2 row 05
    R   ___                                     ; 59F3 row 06
    R   ___                                     ; 59F4 row 07
    RI  D_4, 1, 0                               ; 59F5 row 08  Inst00
    R   ___                                     ; 59F7 row 09
    R   ___                                     ; 59F8 row 10
    R   ___                                     ; 59F9 row 11
    R   ___                                     ; 59FA row 12
    R   ___                                     ; 59FB row 13
    R   ___                                     ; 59FC row 14
    R   ___                                     ; 59FD row 15
    RI  D_5, 1, 0                               ; 59FE row 16  Inst00
    R   ___                                     ; 5A00 row 17
    R   ___                                     ; 5A01 row 18
    R   ___                                     ; 5A02 row 19
    R   ___                                     ; 5A03 row 20
    R   ___                                     ; 5A04 row 21
    R   ___                                     ; 5A05 row 22
    R   ___                                     ; 5A06 row 23
    RI  D_4, 1, 0                               ; 5A07 row 24  Inst00
    R   ___                                     ; 5A09 row 25
    R   ___                                     ; 5A0A row 26
    R   ___                                     ; 5A0B row 27
    R   ___                                     ; 5A0C row 28
    R   ___                                     ; 5A0D row 29
    R   ___                                     ; 5A0E row 30
    R   ___                                     ; 5A0F row 31
Track017:
    RI  G_4, 4, 0                               ; 5A10 row 00  Inst03
    R   ___                                     ; 5A12 row 01
    R   ___                                     ; 5A13 row 02
    R   ___                                     ; 5A14 row 03
    R   ___                                     ; 5A15 row 04
    R   ___                                     ; 5A16 row 05
    R   ___                                     ; 5A17 row 06
    R   ___                                     ; 5A18 row 07
    R   ___                                     ; 5A19 row 08
    R   ___                                     ; 5A1A row 09
    R   ___                                     ; 5A1B row 10
    R   ___                                     ; 5A1C row 11
    R   ___                                     ; 5A1D row 12
    R   ___                                     ; 5A1E row 13
    R   ___                                     ; 5A1F row 14
    R   ___                                     ; 5A20 row 15
    R   ___                                     ; 5A21 row 16
    R   ___                                     ; 5A22 row 17
    R   ___                                     ; 5A23 row 18
    R   ___                                     ; 5A24 row 19
    R   ___                                     ; 5A25 row 20
    R   ___                                     ; 5A26 row 21
    R   ___                                     ; 5A27 row 22
    R   ___                                     ; 5A28 row 23
    R   ___                                     ; 5A29 row 24
    R   ___                                     ; 5A2A row 25
    R   ___                                     ; 5A2B row 26
    R   ___                                     ; 5A2C row 27
    R   ___                                     ; 5A2D row 28
    R   ___                                     ; 5A2E row 29
    R   ___                                     ; 5A2F row 30
    R   ___                                     ; 5A30 row 31
Track018:
    RI  G_2, 10, 0                              ; 5A31 row 00  Inst09
    R   ___                                     ; 5A33 row 01
    R   ___                                     ; 5A34 row 02
    RI  ___, 0, 0                               ; 5A35 row 03
    RI  G_3, 10, 0                              ; 5A37 row 04  Inst09
    RI  ___, 0, 0                               ; 5A39 row 05
    RI  G_2, 10, 0                              ; 5A3B row 06  Inst09
    RI  ___, 0, 0                               ; 5A3D row 07
    RI  C_4, 8, 0                               ; 5A3F row 08  Inst07
    R   ___                                     ; 5A41 row 09
    R   ___                                     ; 5A42 row 10
    R   ___                                     ; 5A43 row 11
    RI  G_3, 10, 0                              ; 5A44 row 12  Inst09
    RI  ___, 0, 0                               ; 5A46 row 13
    RI  G_2, 10, 0                              ; 5A48 row 14  Inst09
    RI  ___, 0, 0                               ; 5A4A row 15
    RI  F_2, 10, 0                              ; 5A4C row 16  Inst09
    RI  ___, 0, 0                               ; 5A4E row 17
    RI  G_2, 10, 0                              ; 5A50 row 18  Inst09
    R   ___                                     ; 5A52 row 19
    R   ___                                     ; 5A53 row 20
    RI  ___, 0, 0                               ; 5A54 row 21
    RI  G_2, 10, 0                              ; 5A56 row 22  Inst09
    RI  ___, 0, 0                               ; 5A58 row 23
    RI  C_4, 8, 0                               ; 5A5A row 24  Inst07
    R   ___                                     ; 5A5C row 25
    RI  C_3, 8, 0                               ; 5A5D row 26  Inst07
    R   ___                                     ; 5A5F row 27
    RI  G_3, 10, 0                              ; 5A60 row 28  Inst09
    RI  ___, 0, 0                               ; 5A62 row 29
    RI  C_3, 8, 0                               ; 5A64 row 30  Inst07
    RI  ___, 0, 0                               ; 5A66 row 31
Track019:
    RI  C_3, 11, 0                              ; 5A68 row 00  Inst10
    R   ___                                     ; 5A6A row 01
    R   ___                                     ; 5A6B row 02
    R   ___                                     ; 5A6C row 03
    RI  C_3, 11, 0                              ; 5A6D row 04  Inst10
    R   ___                                     ; 5A6F row 05
    RI  C_3, 11, 0                              ; 5A70 row 06  Inst10
    R   ___                                     ; 5A72 row 07
    RI  C_6, 9, 0                               ; 5A73 row 08  Inst08
    R   ___                                     ; 5A75 row 09
    R   ___                                     ; 5A76 row 10
    R   ___                                     ; 5A77 row 11
    RI  C_3, 11, 0                              ; 5A78 row 12  Inst10
    R   ___                                     ; 5A7A row 13
    RI  C_3, 11, 0                              ; 5A7B row 14  Inst10
    R   ___                                     ; 5A7D row 15
    RI  C_3, 11, 0                              ; 5A7E row 16  Inst10
    R   ___                                     ; 5A80 row 17
    RI  C_3, 11, 0                              ; 5A81 row 18  Inst10
    R   ___                                     ; 5A83 row 19
    R   ___                                     ; 5A84 row 20
    R   ___                                     ; 5A85 row 21
    RI  C_3, 11, 0                              ; 5A86 row 22  Inst10
    R   ___                                     ; 5A88 row 23
    RI  C_3, 9, 0                               ; 5A89 row 24  Inst08
    R   ___                                     ; 5A8B row 25
    R   ___                                     ; 5A8C row 26
    R   ___                                     ; 5A8D row 27
    RI  C_3, 11, 0                              ; 5A8E row 28  Inst10
    R   ___                                     ; 5A90 row 29
    RI  C_3, 11, 0                              ; 5A91 row 30  Inst10
    R   ___                                     ; 5A93 row 31
Track020:
    RI  D_3, 1, 0                               ; 5A94 row 00  Inst00
    R   ___                                     ; 5A96 row 01
    R   ___                                     ; 5A97 row 02
    R   ___                                     ; 5A98 row 03
    R   ___                                     ; 5A99 row 04
    R   ___                                     ; 5A9A row 05
    R   ___                                     ; 5A9B row 06
    R   ___                                     ; 5A9C row 07
    RI  C_4, 1, 0                               ; 5A9D row 08  Inst00
    R   ___                                     ; 5A9F row 09
    R   ___                                     ; 5AA0 row 10
    R   ___                                     ; 5AA1 row 11
    R   ___                                     ; 5AA2 row 12
    R   ___                                     ; 5AA3 row 13
    R   ___                                     ; 5AA4 row 14
    R   ___                                     ; 5AA5 row 15
    RI  C_5, 1, 0                               ; 5AA6 row 16  Inst00
    R   ___                                     ; 5AA8 row 17
    R   ___                                     ; 5AA9 row 18
    R   ___                                     ; 5AAA row 19
    R   ___                                     ; 5AAB row 20
    R   ___                                     ; 5AAC row 21
    R   ___                                     ; 5AAD row 22
    R   ___                                     ; 5AAE row 23
    RI  C_4, 1, 0                               ; 5AAF row 24  Inst00
    R   ___                                     ; 5AB1 row 25
    R   ___                                     ; 5AB2 row 26
    R   ___                                     ; 5AB3 row 27
    R   ___                                     ; 5AB4 row 28
    R   ___                                     ; 5AB5 row 29
    R   ___                                     ; 5AB6 row 30
    R   ___                                     ; 5AB7 row 31
Track021:
    R   ___                                     ; 5AB8 row 00
    R   ___                                     ; 5AB9 row 01
    R   ___                                     ; 5ABA row 02
    R   ___                                     ; 5ABB row 03
    RI  G_3, 1, 0                               ; 5ABC row 04  Inst00
    R   ___                                     ; 5ABE row 05
    R   ___                                     ; 5ABF row 06
    R   ___                                     ; 5AC0 row 07
    R   ___                                     ; 5AC1 row 08
    R   ___                                     ; 5AC2 row 09
    R   ___                                     ; 5AC3 row 10
    R   ___                                     ; 5AC4 row 11
    RI  G_4, 1, 0                               ; 5AC5 row 12  Inst00
    R   ___                                     ; 5AC7 row 13
    R   ___                                     ; 5AC8 row 14
    R   ___                                     ; 5AC9 row 15
    R   ___                                     ; 5ACA row 16
    R   ___                                     ; 5ACB row 17
    R   ___                                     ; 5ACC row 18
    R   ___                                     ; 5ACD row 19
    RI  G_4, 1, 0                               ; 5ACE row 20  Inst00
    R   ___                                     ; 5AD0 row 21
    R   ___                                     ; 5AD1 row 22
    R   ___                                     ; 5AD2 row 23
    R   ___                                     ; 5AD3 row 24
    R   ___                                     ; 5AD4 row 25
    R   ___                                     ; 5AD5 row 26
    R   ___                                     ; 5AD6 row 27
    RI  G_3, 1, 0                               ; 5AD7 row 28  Inst00
    R   ___                                     ; 5AD9 row 29
    R   ___                                     ; 5ADA row 30
    R   ___                                     ; 5ADB row 31
Track022:
    RI  D_3, 1, 0                               ; 5ADC row 00  Inst00
    R   ___                                     ; 5ADE row 01
    R   ___                                     ; 5ADF row 02
    R   ___                                     ; 5AE0 row 03
    R   ___                                     ; 5AE1 row 04
    R   ___                                     ; 5AE2 row 05
    R   ___                                     ; 5AE3 row 06
    R   ___                                     ; 5AE4 row 07
    RI  D_4, 1, 0                               ; 5AE5 row 08  Inst00
    R   ___                                     ; 5AE7 row 09
    R   ___                                     ; 5AE8 row 10
    R   ___                                     ; 5AE9 row 11
    R   ___                                     ; 5AEA row 12
    R   ___                                     ; 5AEB row 13
    R   ___                                     ; 5AEC row 14
    R   ___                                     ; 5AED row 15
    RI  D_5, 1, 0                               ; 5AEE row 16  Inst00
    R   ___                                     ; 5AF0 row 17
    R   ___                                     ; 5AF1 row 18
    R   ___                                     ; 5AF2 row 19
    R   ___                                     ; 5AF3 row 20
    R   ___                                     ; 5AF4 row 21
    R   ___                                     ; 5AF5 row 22
    R   ___                                     ; 5AF6 row 23
    RI  D_4, 1, 0                               ; 5AF7 row 24  Inst00
    R   ___                                     ; 5AF9 row 25
    R   ___                                     ; 5AFA row 26
    R   ___                                     ; 5AFB row 27
    R   ___                                     ; 5AFC row 28
    R   ___                                     ; 5AFD row 29
    R   ___                                     ; 5AFE row 30
    R   ___                                     ; 5AFF row 31
Track023:
    RI  C_4, 12, 0                              ; 5B00 row 00  Inst11
    R   ___                                     ; 5B02 row 01
    R   ___                                     ; 5B03 row 02
    R   ___                                     ; 5B04 row 03
    R   ___                                     ; 5B05 row 04
    R   ___                                     ; 5B06 row 05
    R   ___                                     ; 5B07 row 06
    R   ___                                     ; 5B08 row 07
    RI  C_4, 9, 0                               ; 5B09 row 08  Inst08
    R   ___                                     ; 5B0B row 09
    R   ___                                     ; 5B0C row 10
    R   ___                                     ; 5B0D row 11
    RI  C_3, 11, 0                              ; 5B0E row 12  Inst10
    R   ___                                     ; 5B10 row 13
    RI  C_3, 11, 0                              ; 5B11 row 14  Inst10
    R   ___                                     ; 5B13 row 15
    RI  C_3, 11, 0                              ; 5B14 row 16  Inst10
    R   ___                                     ; 5B16 row 17
    RI  C_3, 11, 0                              ; 5B17 row 18  Inst10
    R   ___                                     ; 5B19 row 19
    R   ___                                     ; 5B1A row 20
    R   ___                                     ; 5B1B row 21
    RI  C_3, 11, 0                              ; 5B1C row 22  Inst10
    R   ___                                     ; 5B1E row 23
    RI  C_3, 9, 0                               ; 5B1F row 24  Inst08
    R   ___                                     ; 5B21 row 25
    R   ___                                     ; 5B22 row 26
    R   ___                                     ; 5B23 row 27
    RI  C_3, 11, 0                              ; 5B24 row 28  Inst10
    R   ___                                     ; 5B26 row 29
    RI  C_3, 11, 0                              ; 5B27 row 30  Inst10
    R   ___                                     ; 5B29 row 31
Track024:
    RIF D_3, 1, 0, $F, $5                       ; 5B2A row 00  Inst00  speed 5
    R   ___                                     ; 5B2D row 01
    R   ___                                     ; 5B2E row 02
    R   ___                                     ; 5B2F row 03
    RI  G_3, 1, 0                               ; 5B30 row 04  Inst00
    R   ___                                     ; 5B32 row 05
    R   ___                                     ; 5B33 row 06
    R   ___                                     ; 5B34 row 07
    RI  D_4, 1, 0                               ; 5B35 row 08  Inst00
    R   ___                                     ; 5B37 row 09
    R   ___                                     ; 5B38 row 10
    R   ___                                     ; 5B39 row 11
    RI  G_4, 1, 0                               ; 5B3A row 12  Inst00
    R   ___                                     ; 5B3C row 13
    R   ___                                     ; 5B3D row 14
    R   ___                                     ; 5B3E row 15
    RI  D_5, 1, 0                               ; 5B3F row 16  Inst00
    R   ___                                     ; 5B41 row 17
    R   ___                                     ; 5B42 row 18
    R   ___                                     ; 5B43 row 19
    RI  G_4, 1, 0                               ; 5B44 row 20  Inst00
    R   ___                                     ; 5B46 row 21
    R   ___                                     ; 5B47 row 22
    R   ___                                     ; 5B48 row 23
    RI  D_4, 1, 0                               ; 5B49 row 24  Inst00
    R   ___                                     ; 5B4B row 25
    R   ___                                     ; 5B4C row 26
    R   ___                                     ; 5B4D row 27
    RI  G_3, 1, 0                               ; 5B4E row 28  Inst00
    R   ___                                     ; 5B50 row 29
    R   ___                                     ; 5B51 row 30
    R   ___                                     ; 5B52 row 31
Track025:
    RI  G_3, 1, 0                               ; 5B53 row 00  Inst00
    R   ___                                     ; 5B55 row 01
    R   ___                                     ; 5B56 row 02
    R   ___                                     ; 5B57 row 03
    R   ___                                     ; 5B58 row 04
    R   ___                                     ; 5B59 row 05
    RI  G_3, 1, 1                               ; 5B5A row 06  Inst00
    R   ___                                     ; 5B5C row 07
    RI  C_3, 14, 0                              ; 5B5D row 08  Inst13
    R   ___                                     ; 5B5F row 09
    R   ___                                     ; 5B60 row 10
    R   ___                                     ; 5B61 row 11
    R   ___                                     ; 5B62 row 12
    R   ___                                     ; 5B63 row 13
    R   ___                                     ; 5B64 row 14
    R   ___                                     ; 5B65 row 15
    R   ___                                     ; 5B66 row 16
    R   ___                                     ; 5B67 row 17
    R   ___                                     ; 5B68 row 18
    R   ___                                     ; 5B69 row 19
    R   ___                                     ; 5B6A row 20
    R   ___                                     ; 5B6B row 21
    R   ___                                     ; 5B6C row 22
    R   ___                                     ; 5B6D row 23
    R   ___                                     ; 5B6E row 24
    R   ___                                     ; 5B6F row 25
    R   ___                                     ; 5B70 row 26
    R   ___                                     ; 5B71 row 27
    R   ___                                     ; 5B72 row 28
    R   ___                                     ; 5B73 row 29
    R   ___                                     ; 5B74 row 30
    R   ___                                     ; 5B75 row 31
Track026:
    RI  G_2, 4, 0                               ; 5B76 row 00  Inst03
    R   ___                                     ; 5B78 row 01
    R   ___                                     ; 5B79 row 02
    R   ___                                     ; 5B7A row 03
    R   ___                                     ; 5B7B row 04
    R   ___                                     ; 5B7C row 05
    R   ___                                     ; 5B7D row 06
    R   ___                                     ; 5B7E row 07
    R   ___                                     ; 5B7F row 08
    R   ___                                     ; 5B80 row 09
    R   ___                                     ; 5B81 row 10
    R   ___                                     ; 5B82 row 11
    R   ___                                     ; 5B83 row 12
    R   ___                                     ; 5B84 row 13
    RI  C_3, 14, 0                              ; 5B85 row 14  Inst13
    R   ___                                     ; 5B87 row 15
    R   ___                                     ; 5B88 row 16
    R   ___                                     ; 5B89 row 17
    R   ___                                     ; 5B8A row 18
    R   ___                                     ; 5B8B row 19
    R   ___                                     ; 5B8C row 20
    R   ___                                     ; 5B8D row 21
    R   ___                                     ; 5B8E row 22
    R   ___                                     ; 5B8F row 23
    R   ___                                     ; 5B90 row 24
    R   ___                                     ; 5B91 row 25
    R   ___                                     ; 5B92 row 26
    R   ___                                     ; 5B93 row 27
    R   ___                                     ; 5B94 row 28
    R   ___                                     ; 5B95 row 29
    R   ___                                     ; 5B96 row 30
    R   ___                                     ; 5B97 row 31
Track027:
    R   ___                                     ; 5B98 row 00
    R   ___                                     ; 5B99 row 01
    R   ___                                     ; 5B9A row 02
    R   ___                                     ; 5B9B row 03
    RI  G_3, 1, 0                               ; 5B9C row 04  Inst00
    R   ___                                     ; 5B9E row 05
    R   ___                                     ; 5B9F row 06
    R   ___                                     ; 5BA0 row 07
    R   ___                                     ; 5BA1 row 08
    R   ___                                     ; 5BA2 row 09
    R   ___                                     ; 5BA3 row 10
    R   ___                                     ; 5BA4 row 11
    RI  G_4, 1, 0                               ; 5BA5 row 12  Inst00
    R   ___                                     ; 5BA7 row 13
    R   ___                                     ; 5BA8 row 14
    R   ___                                     ; 5BA9 row 15
    R   ___                                     ; 5BAA row 16
    R   ___                                     ; 5BAB row 17
    R   ___                                     ; 5BAC row 18
    R   ___                                     ; 5BAD row 19
    RI  G_4, 1, 0                               ; 5BAE row 20  Inst00
    R   ___                                     ; 5BB0 row 21
    R   ___                                     ; 5BB1 row 22
    R   ___                                     ; 5BB2 row 23
    RI  F_2, 4, 0                               ; 5BB3 row 24  Inst03
    R   ___                                     ; 5BB5 row 25
    RI  F_2, 4, 0                               ; 5BB6 row 26  Inst03
    R   ___                                     ; 5BB8 row 27
    R   ___                                     ; 5BB9 row 28
    R   ___                                     ; 5BBA row 29
    RI  F_2, 4, 0                               ; 5BBB row 30  Inst03
    R   ___                                     ; 5BBD row 31
Track028:
    RI  D_3, 1, 0                               ; 5BBE row 00  Inst00
    R   ___                                     ; 5BC0 row 01
    R   ___                                     ; 5BC1 row 02
    R   ___                                     ; 5BC2 row 03
    R   ___                                     ; 5BC3 row 04
    R   ___                                     ; 5BC4 row 05
    R   ___                                     ; 5BC5 row 06
    R   ___                                     ; 5BC6 row 07
    RI  C_4, 1, 0                               ; 5BC7 row 08  Inst00
    R   ___                                     ; 5BC9 row 09
    R   ___                                     ; 5BCA row 10
    R   ___                                     ; 5BCB row 11
    R   ___                                     ; 5BCC row 12
    R   ___                                     ; 5BCD row 13
    R   ___                                     ; 5BCE row 14
    R   ___                                     ; 5BCF row 15
    RI  C_5, 1, 0                               ; 5BD0 row 16  Inst00
    R   ___                                     ; 5BD2 row 17
    R   ___                                     ; 5BD3 row 18
    R   ___                                     ; 5BD4 row 19
    R   ___                                     ; 5BD5 row 20
    R   ___                                     ; 5BD6 row 21
    R   ___                                     ; 5BD7 row 22
    R   ___                                     ; 5BD8 row 23
    RI  F_2, 1, 0                               ; 5BD9 row 24  Inst00
    R   ___                                     ; 5BDB row 25
    RI  F_2, 1, 0                               ; 5BDC row 26  Inst00
    R   ___                                     ; 5BDE row 27
    R   ___                                     ; 5BDF row 28
    R   ___                                     ; 5BE0 row 29
    RI  F_2, 1, 0                               ; 5BE1 row 30  Inst00
    R   ___                                     ; 5BE3 row 31
Track029:
    RI  C_3, 11, 0                              ; 5BE4 row 00  Inst10
    R   ___                                     ; 5BE6 row 01
    R   ___                                     ; 5BE7 row 02
    R   ___                                     ; 5BE8 row 03
    RI  C_3, 11, 0                              ; 5BE9 row 04  Inst10
    R   ___                                     ; 5BEB row 05
    RI  C_3, 11, 0                              ; 5BEC row 06  Inst10
    R   ___                                     ; 5BEE row 07
    RI  C_6, 9, 0                               ; 5BEF row 08  Inst08
    R   ___                                     ; 5BF1 row 09
    R   ___                                     ; 5BF2 row 10
    R   ___                                     ; 5BF3 row 11
    RI  C_3, 11, 0                              ; 5BF4 row 12  Inst10
    R   ___                                     ; 5BF6 row 13
    RI  C_3, 11, 0                              ; 5BF7 row 14  Inst10
    R   ___                                     ; 5BF9 row 15
    RI  C_3, 11, 0                              ; 5BFA row 16  Inst10
    R   ___                                     ; 5BFC row 17
    RI  C_3, 11, 0                              ; 5BFD row 18  Inst10
    R   ___                                     ; 5BFF row 19
    R   ___                                     ; 5C00 row 20
    R   ___                                     ; 5C01 row 21
    RI  C_3, 11, 0                              ; 5C02 row 22  Inst10
    R   ___                                     ; 5C04 row 23
    RI  C_3, 9, 0                               ; 5C05 row 24  Inst08
    R   ___                                     ; 5C07 row 25
    RI  C_3, 9, 0                               ; 5C08 row 26  Inst08
    R   ___                                     ; 5C0A row 27
    R   ___                                     ; 5C0B row 28
    R   ___                                     ; 5C0C row 29
    RI  C_3, 9, 0                               ; 5C0D row 30  Inst08
    R   ___                                     ; 5C0F row 31
Track030:
    R   ___                                     ; 5C10 row 00
    RI  C_3, 15, 1                              ; 5C11 row 01  Inst14
    R   ___                                     ; 5C13 row 02
    R   ___                                     ; 5C14 row 03
    R   ___                                     ; 5C15 row 04
    R   ___                                     ; 5C16 row 05
    RI  C_3, 15, 1                              ; 5C17 row 06  Inst14
    R   ___                                     ; 5C19 row 07
    R   ___                                     ; 5C1A row 08
    R   ___                                     ; 5C1B row 09
    R   ___                                     ; 5C1C row 10
    R   ___                                     ; 5C1D row 11
    R   ___                                     ; 5C1E row 12
    R   ___                                     ; 5C1F row 13
    R   ___                                     ; 5C20 row 14
    R   ___                                     ; 5C21 row 15
    R   ___                                     ; 5C22 row 16
    R   ___                                     ; 5C23 row 17
    RI  F_3, 6, 0                               ; 5C24 row 18  Inst05
    R   ___                                     ; 5C26 row 19
    RI  F_3, 6, 1                               ; 5C27 row 20  Inst05
    R   ___                                     ; 5C29 row 21
    R   ___                                     ; 5C2A row 22
    R   ___                                     ; 5C2B row 23
    RI  F_3, 6, 0                               ; 5C2C row 24  Inst05
    R   ___                                     ; 5C2E row 25
    RI  F_3, 6, 1                               ; 5C2F row 26  Inst05
    R   ___                                     ; 5C31 row 27
    RI  F_3, 6, 0                               ; 5C32 row 28  Inst05
    R   ___                                     ; 5C34 row 29
    RI  F_3, 6, 1                               ; 5C35 row 30  Inst05
    R   ___                                     ; 5C37 row 31
Track031:
    RIF C_3, 15, 0, $F, $5                      ; 5C38 row 00  Inst14  speed 5
    R   ___                                     ; 5C3B row 01
    R   ___                                     ; 5C3C row 02
    R   ___                                     ; 5C3D row 03
    R   ___                                     ; 5C3E row 04
    R   ___                                     ; 5C3F row 05
    R   ___                                     ; 5C40 row 06
    R   ___                                     ; 5C41 row 07
    R   ___                                     ; 5C42 row 08
    R   ___                                     ; 5C43 row 09
    R   ___                                     ; 5C44 row 10
    R   ___                                     ; 5C45 row 11
    R   ___                                     ; 5C46 row 12
    R   ___                                     ; 5C47 row 13
    R   ___                                     ; 5C48 row 14
    R   ___                                     ; 5C49 row 15
    R   ___                                     ; 5C4A row 16
    R   ___                                     ; 5C4B row 17
    RI  F_2, 1, 0                               ; 5C4C row 18  Inst00
    R   ___                                     ; 5C4E row 19
    R   ___                                     ; 5C4F row 20
    R   ___                                     ; 5C50 row 21
    R   ___                                     ; 5C51 row 22
    R   ___                                     ; 5C52 row 23
    RI  F_2, 1, 0                               ; 5C53 row 24  Inst00
    R   ___                                     ; 5C55 row 25
    R   ___                                     ; 5C56 row 26
    R   ___                                     ; 5C57 row 27
    RI  F_2, 1, 0                               ; 5C58 row 28  Inst00
    R   ___                                     ; 5C5A row 29
    R   ___                                     ; 5C5B row 30
    R   ___                                     ; 5C5C row 31
Track032:
    RI  C_3, 11, 0                              ; 5C5D row 00  Inst10
    R   ___                                     ; 5C5F row 01
    R   ___                                     ; 5C60 row 02
    R   ___                                     ; 5C61 row 03
    RI  C_3, 11, 0                              ; 5C62 row 04  Inst10
    R   ___                                     ; 5C64 row 05
    RI  C_3, 11, 0                              ; 5C65 row 06  Inst10
    R   ___                                     ; 5C67 row 07
    RI  C_6, 9, 0                               ; 5C68 row 08  Inst08
    R   ___                                     ; 5C6A row 09
    R   ___                                     ; 5C6B row 10
    R   ___                                     ; 5C6C row 11
    RI  C_3, 11, 0                              ; 5C6D row 12  Inst10
    R   ___                                     ; 5C6F row 13
    RI  C_3, 11, 0                              ; 5C70 row 14  Inst10
    R   ___                                     ; 5C72 row 15
    RI  C_3, 11, 0                              ; 5C73 row 16  Inst10
    R   ___                                     ; 5C75 row 17
    RI  C_3, 11, 0                              ; 5C76 row 18  Inst10
    R   ___                                     ; 5C78 row 19
    R   ___                                     ; 5C79 row 20
    R   ___                                     ; 5C7A row 21
    RI  C_3, 11, 0                              ; 5C7B row 22  Inst10
    R   ___                                     ; 5C7D row 23
    RI  C_3, 9, 0                               ; 5C7E row 24  Inst08
    R   ___                                     ; 5C80 row 25
    R   ___                                     ; 5C81 row 26
    R   ___                                     ; 5C82 row 27
    RI  C_3, 9, 0                               ; 5C83 row 28  Inst08
    R   ___                                     ; 5C85 row 29
    R   ___                                     ; 5C86 row 30
    R   ___                                     ; 5C87 row 31
Track033:
    RI  G_2, 10, 0                              ; 5C88 row 00  Inst09
    R   ___                                     ; 5C8A row 01
    R   ___                                     ; 5C8B row 02
    RI  ___, 0, 0                               ; 5C8C row 03
    RI  G_3, 10, 0                              ; 5C8E row 04  Inst09
    RI  ___, 0, 0                               ; 5C90 row 05
    RI  G_2, 10, 0                              ; 5C92 row 06  Inst09
    RI  ___, 0, 0                               ; 5C94 row 07
    RI  C_4, 8, 0                               ; 5C96 row 08  Inst07
    R   ___                                     ; 5C98 row 09
    R   ___                                     ; 5C99 row 10
    R   ___                                     ; 5C9A row 11
    RI  G_3, 10, 0                              ; 5C9B row 12  Inst09
    RI  ___, 0, 0                               ; 5C9D row 13
    RI  G_2, 10, 0                              ; 5C9F row 14  Inst09
    RI  ___, 0, 0                               ; 5CA1 row 15
    RI  F_2, 10, 0                              ; 5CA3 row 16  Inst09
    RI  ___, 0, 0                               ; 5CA5 row 17
    RI  G_2, 10, 0                              ; 5CA7 row 18  Inst09
    R   ___                                     ; 5CA9 row 19
    R   ___                                     ; 5CAA row 20
    RI  ___, 0, 0                               ; 5CAB row 21
    RI  G_2, 10, 0                              ; 5CAD row 22  Inst09
    RI  ___, 0, 0                               ; 5CAF row 23
    RI  C_4, 8, 0                               ; 5CB1 row 24  Inst07
    R   ___                                     ; 5CB3 row 25
    R   ___                                     ; 5CB4 row 26
    R   ___                                     ; 5CB5 row 27
    RI  C_3, 8, 0                               ; 5CB6 row 28  Inst07
    R   ___                                     ; 5CB8 row 29
    RI  G_2, 10, 0                              ; 5CB9 row 30  Inst09
    R   ___                                     ; 5CBB row 31
Track034:
    RI  C_4, 12, 0                              ; 5CBC row 00  Inst11
    R   ___                                     ; 5CBE row 01
    R   ___                                     ; 5CBF row 02
    R   ___                                     ; 5CC0 row 03
    R   ___                                     ; 5CC1 row 04
    R   ___                                     ; 5CC2 row 05
    R   ___                                     ; 5CC3 row 06
    R   ___                                     ; 5CC4 row 07
    R   ___                                     ; 5CC5 row 08
    R   ___                                     ; 5CC6 row 09
    R   ___                                     ; 5CC7 row 10
    R   ___                                     ; 5CC8 row 11
    R   ___                                     ; 5CC9 row 12
    R   ___                                     ; 5CCA row 13
    R   ___                                     ; 5CCB row 14
    R   ___                                     ; 5CCC row 15
    R   ___                                     ; 5CCD row 16
    R   ___                                     ; 5CCE row 17
    R   ___                                     ; 5CCF row 18
    R   ___                                     ; 5CD0 row 19
    R   ___                                     ; 5CD1 row 20
    R   ___                                     ; 5CD2 row 21
    R   ___                                     ; 5CD3 row 22
    R   ___                                     ; 5CD4 row 23
    R   ___                                     ; 5CD5 row 24
    R   ___                                     ; 5CD6 row 25
    R   ___                                     ; 5CD7 row 26
    R   ___                                     ; 5CD8 row 27
    R   ___                                     ; 5CD9 row 28
    R   ___                                     ; 5CDA row 29
    R   ___                                     ; 5CDB row 30
    R   ___                                     ; 5CDC row 31
Track035:
    RI  D_2, 15, 0                              ; 5CDD row 00  Inst14
    R   ___                                     ; 5CDF row 01
    R   ___                                     ; 5CE0 row 02
    R   ___                                     ; 5CE1 row 03
    R   ___                                     ; 5CE2 row 04
    R   ___                                     ; 5CE3 row 05
    R   ___                                     ; 5CE4 row 06
    R   ___                                     ; 5CE5 row 07
    R   ___                                     ; 5CE6 row 08
    R   ___                                     ; 5CE7 row 09
    RI  G_4, 1, 0                               ; 5CE8 row 10  Inst00
    R   ___                                     ; 5CEA row 11
    R   ___                                     ; 5CEB row 12
    R   ___                                     ; 5CEC row 13
    RI  G_3, 1, 0                               ; 5CED row 14  Inst00
    R   ___                                     ; 5CEF row 15
    R   ___                                     ; 5CF0 row 16
    R   ___                                     ; 5CF1 row 17
    RI  G_3, 1, 0                               ; 5CF2 row 18  Inst00
    R   ___                                     ; 5CF4 row 19
    R   ___                                     ; 5CF5 row 20
    R   ___                                     ; 5CF6 row 21
    RI  G_4, 1, 0                               ; 5CF7 row 22  Inst00
    R   ___                                     ; 5CF9 row 23
    R   ___                                     ; 5CFA row 24
    R   ___                                     ; 5CFB row 25
    RI  G_4, 1, 0                               ; 5CFC row 26  Inst00
    R   ___                                     ; 5CFE row 27
    R   ___                                     ; 5CFF row 28
    R   ___                                     ; 5D00 row 29
    RI  G_3, 1, 0                               ; 5D01 row 30  Inst00
    R   ___                                     ; 5D03 row 31
Track036:
    RIF D_3, 1, 0, $F, $A                       ; 5D04 row 00  Inst00  speed 10
    R   ___                                     ; 5D07 row 01
    RI  G_3, 1, 0                               ; 5D08 row 02  Inst00
    R   ___                                     ; 5D0A row 03
    RI  D_4, 1, 0                               ; 5D0B row 04  Inst00
    R   ___                                     ; 5D0D row 05
    RI  G_4, 1, 0                               ; 5D0E row 06  Inst00
    R   ___                                     ; 5D10 row 07
    RI  D_5, 1, 0                               ; 5D11 row 08  Inst00
    R   ___                                     ; 5D13 row 09
    R   ___                                     ; 5D14 row 10
    R   ___                                     ; 5D15 row 11
    RI  D_4, 1, 0                               ; 5D16 row 12  Inst00
    R   ___                                     ; 5D18 row 13
    R   ___                                     ; 5D19 row 14
    R   ___                                     ; 5D1A row 15
    RI  D_3, 1, 0                               ; 5D1B row 16  Inst00
    R   ___                                     ; 5D1D row 17
    R   ___                                     ; 5D1E row 18
    R   ___                                     ; 5D1F row 19
    RI  C_4, 1, 0                               ; 5D20 row 20  Inst00
    R   ___                                     ; 5D22 row 21
    R   ___                                     ; 5D23 row 22
    R   ___                                     ; 5D24 row 23
    RI  C_5, 1, 0                               ; 5D25 row 24  Inst00
    R   ___                                     ; 5D27 row 25
    R   ___                                     ; 5D28 row 26
    R   ___                                     ; 5D29 row 27
    RI  C_4, 1, 0                               ; 5D2A row 28  Inst00
    R   ___                                     ; 5D2C row 29
    R   ___                                     ; 5D2D row 30
    R   ___                                     ; 5D2E row 31
Track037:
    RI  G_2, 6, 0                               ; 5D2F row 00  Inst05
    R   ___                                     ; 5D31 row 01
    R   ___                                     ; 5D32 row 02
    R   ___                                     ; 5D33 row 03
    R   ___                                     ; 5D34 row 04
    R   ___                                     ; 5D35 row 05
    RI  G_2, 6, 1                               ; 5D36 row 06  Inst05
    R   ___                                     ; 5D38 row 07
    R   ___                                     ; 5D39 row 08
    R   ___                                     ; 5D3A row 09
    R   ___                                     ; 5D3B row 10
    R   ___                                     ; 5D3C row 11
    R   ___                                     ; 5D3D row 12
    R   ___                                     ; 5D3E row 13
    RI  C_3, 14, 0                              ; 5D3F row 14  Inst13
    R   ___                                     ; 5D41 row 15
    R   ___                                     ; 5D42 row 16
    R   ___                                     ; 5D43 row 17
    R   ___                                     ; 5D44 row 18
    R   ___                                     ; 5D45 row 19
    R   ___                                     ; 5D46 row 20
    R   ___                                     ; 5D47 row 21
    R   ___                                     ; 5D48 row 22
    R   ___                                     ; 5D49 row 23
    R   ___                                     ; 5D4A row 24
    R   ___                                     ; 5D4B row 25
    R   ___                                     ; 5D4C row 26
    R   ___                                     ; 5D4D row 27
    R   ___                                     ; 5D4E row 28
    R   ___                                     ; 5D4F row 29
    R   ___                                     ; 5D50 row 30
    R   ___                                     ; 5D51 row 31
Track038:
    RIF Ds4, 16, 0, $F, $A                      ; 5D52 row 00  Inst15  speed 10
    R   ___                                     ; 5D55 row 01
    RI  D_4, 16, 0                              ; 5D56 row 02  Inst15
    R   ___                                     ; 5D58 row 03
    RI  As3, 16, 0                              ; 5D59 row 04  Inst15
    R   ___                                     ; 5D5B row 05
    RI  G_3, 16, 0                              ; 5D5C row 06  Inst15
    R   ___                                     ; 5D5E row 07
    RI  Ds3, 16, 0                              ; 5D5F row 08  Inst15
    R   ___                                     ; 5D61 row 09
    RI  D_3, 16, 0                              ; 5D62 row 10  Inst15
    R   ___                                     ; 5D64 row 11
    RI  As2, 16, 0                              ; 5D65 row 12  Inst15
    R   ___                                     ; 5D67 row 13
    RI  G_2, 16, 0                              ; 5D68 row 14  Inst15
    R   ___                                     ; 5D6A row 15
    RI  Gs3, 16, 0                              ; 5D6B row 16  Inst15
    R   ___                                     ; 5D6D row 17
    RI  G_3, 16, 0                              ; 5D6E row 18  Inst15
    R   ___                                     ; 5D70 row 19
    RI  Ds3, 16, 0                              ; 5D71 row 20  Inst15
    R   ___                                     ; 5D73 row 21
    RI  C_3, 16, 0                              ; 5D74 row 22  Inst15
    R   ___                                     ; 5D76 row 23
    RI  Gs2, 16, 0                              ; 5D77 row 24  Inst15
    R   ___                                     ; 5D79 row 25
    RI  G_2, 16, 0                              ; 5D7A row 26  Inst15
    R   ___                                     ; 5D7C row 27
    RI  Ds2, 16, 0                              ; 5D7D row 28  Inst15
    R   ___                                     ; 5D7F row 29
    RI  C_2, 16, 0                              ; 5D80 row 30  Inst15
    R   ___                                     ; 5D82 row 31
Track039:
    RI  C_3, 2, 0                               ; 5D83 row 00  Inst01
    R   ___                                     ; 5D85 row 01
    R   ___                                     ; 5D86 row 02
    R   ___                                     ; 5D87 row 03
    R   ___                                     ; 5D88 row 04
    R   ___                                     ; 5D89 row 05
    R   ___                                     ; 5D8A row 06
    R   ___                                     ; 5D8B row 07
    R   ___                                     ; 5D8C row 08
    R   ___                                     ; 5D8D row 09
    R   ___                                     ; 5D8E row 10
    R   ___                                     ; 5D8F row 11
    R   ___                                     ; 5D90 row 12
    R   ___                                     ; 5D91 row 13
    R   ___                                     ; 5D92 row 14
    R   ___                                     ; 5D93 row 15
    RI  Gs2, 2, 0                               ; 5D94 row 16  Inst01
    R   ___                                     ; 5D96 row 17
    R   ___                                     ; 5D97 row 18
    R   ___                                     ; 5D98 row 19
    R   ___                                     ; 5D99 row 20
    R   ___                                     ; 5D9A row 21
    R   ___                                     ; 5D9B row 22
    R   ___                                     ; 5D9C row 23
    R   ___                                     ; 5D9D row 24
    R   ___                                     ; 5D9E row 25
    R   ___                                     ; 5D9F row 26
    R   ___                                     ; 5DA0 row 27
    R   ___                                     ; 5DA1 row 28
    R   ___                                     ; 5DA2 row 29
    R   ___                                     ; 5DA3 row 30
    R   ___                                     ; 5DA4 row 31
Track040:
    RI  C_3, 17, 0                              ; 5DA5 row 00  Inst16
    R   ___                                     ; 5DA7 row 01
    R   ___                                     ; 5DA8 row 02
    R   ___                                     ; 5DA9 row 03
    R   ___                                     ; 5DAA row 04
    R   ___                                     ; 5DAB row 05
    R   ___                                     ; 5DAC row 06
    R   ___                                     ; 5DAD row 07
    RI  C_3, 17, 0                              ; 5DAE row 08  Inst16
    R   ___                                     ; 5DB0 row 09
    R   ___                                     ; 5DB1 row 10
    R   ___                                     ; 5DB2 row 11
    R   ___                                     ; 5DB3 row 12
    R   ___                                     ; 5DB4 row 13
    R   ___                                     ; 5DB5 row 14
    R   ___                                     ; 5DB6 row 15
    RI  C_3, 18, 0                              ; 5DB7 row 16  Inst17
    R   ___                                     ; 5DB9 row 17
    R   ___                                     ; 5DBA row 18
    R   ___                                     ; 5DBB row 19
    R   ___                                     ; 5DBC row 20
    R   ___                                     ; 5DBD row 21
    R   ___                                     ; 5DBE row 22
    R   ___                                     ; 5DBF row 23
    RI  C_3, 18, 0                              ; 5DC0 row 24  Inst17
    R   ___                                     ; 5DC2 row 25
    R   ___                                     ; 5DC3 row 26
    R   ___                                     ; 5DC4 row 27
    R   ___                                     ; 5DC5 row 28
    R   ___                                     ; 5DC6 row 29
    R   ___                                     ; 5DC7 row 30
    R   ___                                     ; 5DC8 row 31
Track041:
    RI  F_3, 2, 0                               ; 5DC9 row 00  Inst01
    R   ___                                     ; 5DCB row 01
    R   ___                                     ; 5DCC row 02
    R   ___                                     ; 5DCD row 03
    R   ___                                     ; 5DCE row 04
    R   ___                                     ; 5DCF row 05
    R   ___                                     ; 5DD0 row 06
    R   ___                                     ; 5DD1 row 07
    R   ___                                     ; 5DD2 row 08
    R   ___                                     ; 5DD3 row 09
    R   ___                                     ; 5DD4 row 10
    R   ___                                     ; 5DD5 row 11
    R   ___                                     ; 5DD6 row 12
    R   ___                                     ; 5DD7 row 13
    R   ___                                     ; 5DD8 row 14
    R   ___                                     ; 5DD9 row 15
    RI  As2, 2, 0                               ; 5DDA row 16  Inst01
    R   ___                                     ; 5DDC row 17
    R   ___                                     ; 5DDD row 18
    R   ___                                     ; 5DDE row 19
    R   ___                                     ; 5DDF row 20
    R   ___                                     ; 5DE0 row 21
    R   ___                                     ; 5DE1 row 22
    R   ___                                     ; 5DE2 row 23
    RI  B_2, 2, 0                               ; 5DE3 row 24  Inst01
    R   ___                                     ; 5DE5 row 25
    R   ___                                     ; 5DE6 row 26
    R   ___                                     ; 5DE7 row 27
    R   ___                                     ; 5DE8 row 28
    R   ___                                     ; 5DE9 row 29
    R   ___                                     ; 5DEA row 30
    R   ___                                     ; 5DEB row 31
Track042:
    RI  C_3, 20, 0                              ; 5DEC row 00  Inst19
    R   ___                                     ; 5DEE row 01
    R   ___                                     ; 5DEF row 02
    R   ___                                     ; 5DF0 row 03
    R   ___                                     ; 5DF1 row 04
    R   ___                                     ; 5DF2 row 05
    R   ___                                     ; 5DF3 row 06
    R   ___                                     ; 5DF4 row 07
    RI  C_3, 20, 0                              ; 5DF5 row 08  Inst19
    R   ___                                     ; 5DF7 row 09
    R   ___                                     ; 5DF8 row 10
    R   ___                                     ; 5DF9 row 11
    R   ___                                     ; 5DFA row 12
    R   ___                                     ; 5DFB row 13
    R   ___                                     ; 5DFC row 14
    R   ___                                     ; 5DFD row 15
    RI  D_3, 20, 0                              ; 5DFE row 16  Inst19
    R   ___                                     ; 5E00 row 17
    R   ___                                     ; 5E01 row 18
    R   ___                                     ; 5E02 row 19
    R   ___                                     ; 5E03 row 20
    R   ___                                     ; 5E04 row 21
    R   ___                                     ; 5E05 row 22
    R   ___                                     ; 5E06 row 23
    RI  C_2, 24, 0                              ; 5E07 row 24  Inst23
    R   ___                                     ; 5E09 row 25
    R   ___                                     ; 5E0A row 26
    R   ___                                     ; 5E0B row 27
    R   ___                                     ; 5E0C row 28
    R   ___                                     ; 5E0D row 29
    R   ___                                     ; 5E0E row 30
    R   ___                                     ; 5E0F row 31
Track043:
    RI  Gs3, 16, 0                              ; 5E10 row 00  Inst15
    R   ___                                     ; 5E12 row 01
    RI  As3, 16, 0                              ; 5E13 row 02  Inst15
    R   ___                                     ; 5E15 row 03
    RI  C_4, 16, 0                              ; 5E16 row 04  Inst15
    R   ___                                     ; 5E18 row 05
    RI  Ds4, 16, 0                              ; 5E19 row 06  Inst15
    R   ___                                     ; 5E1B row 07
    RI  Gs2, 16, 0                              ; 5E1C row 08  Inst15
    R   ___                                     ; 5E1E row 09
    RI  As2, 16, 0                              ; 5E1F row 10  Inst15
    R   ___                                     ; 5E21 row 11
    RI  C_3, 16, 0                              ; 5E22 row 12  Inst15
    R   ___                                     ; 5E24 row 13
    RI  Ds3, 16, 0                              ; 5E25 row 14  Inst15
    R   ___                                     ; 5E27 row 15
    RI  As3, 16, 0                              ; 5E28 row 16  Inst15
    R   ___                                     ; 5E2A row 17
    RI  D_4, 16, 0                              ; 5E2B row 18  Inst15
    R   ___                                     ; 5E2D row 19
    RI  F_4, 16, 0                              ; 5E2E row 20  Inst15
    R   ___                                     ; 5E30 row 21
    RI  As4, 16, 0                              ; 5E31 row 22  Inst15
    R   ___                                     ; 5E33 row 23
    RI  B_2, 16, 0                              ; 5E34 row 24  Inst15
    R   ___                                     ; 5E36 row 25
    RI  D_3, 16, 0                              ; 5E37 row 26  Inst15
    R   ___                                     ; 5E39 row 27
    RI  F_3, 16, 0                              ; 5E3A row 28  Inst15
    R   ___                                     ; 5E3C row 29
    RI  B_3, 16, 0                              ; 5E3D row 30  Inst15
    R   ___                                     ; 5E3F row 31
Track044:
    RI  C_3, 21, 0                              ; 5E40 row 00  Inst20
    R   ___                                     ; 5E42 row 01
    R   ___                                     ; 5E43 row 02
    R   ___                                     ; 5E44 row 03
    R   ___                                     ; 5E45 row 04
    R   ___                                     ; 5E46 row 05
    R   ___                                     ; 5E47 row 06
    R   ___                                     ; 5E48 row 07
    RI  C_3, 21, 0                              ; 5E49 row 08  Inst20
    R   ___                                     ; 5E4B row 09
    R   ___                                     ; 5E4C row 10
    R   ___                                     ; 5E4D row 11
    R   ___                                     ; 5E4E row 12
    R   ___                                     ; 5E4F row 13
    R   ___                                     ; 5E50 row 14
    R   ___                                     ; 5E51 row 15
    RI  C_3, 21, 0                              ; 5E52 row 16  Inst20
    R   ___                                     ; 5E54 row 17
    R   ___                                     ; 5E55 row 18
    R   ___                                     ; 5E56 row 19
    R   ___                                     ; 5E57 row 20
    R   ___                                     ; 5E58 row 21
    R   ___                                     ; 5E59 row 22
    R   ___                                     ; 5E5A row 23
    RI  C_3, 21, 0                              ; 5E5B row 24  Inst20
    R   ___                                     ; 5E5D row 25
    R   ___                                     ; 5E5E row 26
    R   ___                                     ; 5E5F row 27
    RI  C_5, 22, 0                              ; 5E60 row 28  Inst21
    R   ___                                     ; 5E62 row 29
    RI  G_3, 22, 0                              ; 5E63 row 30  Inst21
    R   ___                                     ; 5E65 row 31
Track045:
    RI  G_4, 3, 0                               ; 5E66 row 00  Inst02
    R   ___                                     ; 5E68 row 01
    R   ___                                     ; 5E69 row 02
    R   ___                                     ; 5E6A row 03
    R   ___                                     ; 5E6B row 04
    R   ___                                     ; 5E6C row 05
    R   ___                                     ; 5E6D row 06
    R   ___                                     ; 5E6E row 07
    R   ___                                     ; 5E6F row 08
    R   ___                                     ; 5E70 row 09
    R   ___                                     ; 5E71 row 10
    R   ___                                     ; 5E72 row 11
    R   ___                                     ; 5E73 row 12
    R   ___                                     ; 5E74 row 13
    R   ___                                     ; 5E75 row 14
    R   ___                                     ; 5E76 row 15
    RI  Gs4, 19, 0                              ; 5E77 row 16  Inst18
    R   ___                                     ; 5E79 row 17
    R   ___                                     ; 5E7A row 18
    R   ___                                     ; 5E7B row 19
    R   ___                                     ; 5E7C row 20
    R   ___                                     ; 5E7D row 21
    R   ___                                     ; 5E7E row 22
    R   ___                                     ; 5E7F row 23
    RI  Ds4, 19, 0                              ; 5E80 row 24  Inst18
    R   ___                                     ; 5E82 row 25
    R   ___                                     ; 5E83 row 26
    R   ___                                     ; 5E84 row 27
    R   ___                                     ; 5E85 row 28
    R   ___                                     ; 5E86 row 29
    RI  F_4, 19, 0                              ; 5E87 row 30  Inst18
    R   ___                                     ; 5E89 row 31
Track046:
    RI  Ds4, 19, 0                              ; 5E8A row 00  Inst18
    R   ___                                     ; 5E8C row 01
    R   ___                                     ; 5E8D row 02
    R   ___                                     ; 5E8E row 03
    R   ___                                     ; 5E8F row 04
    R   ___                                     ; 5E90 row 05
    RI  C_4, 19, 0                              ; 5E91 row 06  Inst18
    RI  Ds4, 19, 0                              ; 5E93 row 07  Inst18
    RI  Gs4, 19, 0                              ; 5E95 row 08  Inst18
    R   ___                                     ; 5E97 row 09
    R   ___                                     ; 5E98 row 10
    RI  G_4, 19, 0                              ; 5E99 row 11  Inst18
    R   ___                                     ; 5E9B row 12
    R   ___                                     ; 5E9C row 13
    RI  Ds4, 19, 0                              ; 5E9D row 14  Inst18
    R   ___                                     ; 5E9F row 15
    RI  F_4, 19, 0                              ; 5EA0 row 16  Inst18
    R   ___                                     ; 5EA2 row 17
    R   ___                                     ; 5EA3 row 18
    R   ___                                     ; 5EA4 row 19
    R   ___                                     ; 5EA5 row 20
    R   ___                                     ; 5EA6 row 21
    R   ___                                     ; 5EA7 row 22
    R   ___                                     ; 5EA8 row 23
    RI  B_3, 19, 0                              ; 5EA9 row 24  Inst18
    R   ___                                     ; 5EAB row 25
    R   ___                                     ; 5EAC row 26
    R   ___                                     ; 5EAD row 27
    RI  G_3, 19, 0                              ; 5EAE row 28  Inst18
    R   ___                                     ; 5EB0 row 29
    R   ___                                     ; 5EB1 row 30
    R   ___                                     ; 5EB2 row 31
Track047:
    RI  G_4, 19, 0                              ; 5EB3 row 00  Inst18
    R   F_4                                     ; 5EB5 row 01
    R   G_4                                     ; 5EB6 row 02
    R   ___                                     ; 5EB7 row 03
    R   ___                                     ; 5EB8 row 04
    R   ___                                     ; 5EB9 row 05
    R   ___                                     ; 5EBA row 06
    R   ___                                     ; 5EBB row 07
    R   ___                                     ; 5EBC row 08
    R   ___                                     ; 5EBD row 09
    R   ___                                     ; 5EBE row 10
    R   ___                                     ; 5EBF row 11
    R   ___                                     ; 5EC0 row 12
    R   ___                                     ; 5EC1 row 13
    R   ___                                     ; 5EC2 row 14
    R   ___                                     ; 5EC3 row 15
    RI  C_5, 19, 0                              ; 5EC4 row 16  Inst18
    R   ___                                     ; 5EC6 row 17
    R   ___                                     ; 5EC7 row 18
    R   ___                                     ; 5EC8 row 19
    R   ___                                     ; 5EC9 row 20
    R   ___                                     ; 5ECA row 21
    R   ___                                     ; 5ECB row 22
    R   ___                                     ; 5ECC row 23
    RI  Gs4, 19, 0                              ; 5ECD row 24  Inst18
    R   ___                                     ; 5ECF row 25
    R   ___                                     ; 5ED0 row 26
    R   ___                                     ; 5ED1 row 27
    R   ___                                     ; 5ED2 row 28
    R   ___                                     ; 5ED3 row 29
    RI  C_4, 19, 0                              ; 5ED4 row 30  Inst18
    RI  D_4, 19, 0                              ; 5ED6 row 31  Inst18
Track048:
    RI  C_3, 19, 0                              ; 5ED8 row 00  Inst18
    R   ___                                     ; 5EDA row 01
    R   ___                                     ; 5EDB row 02
    R   ___                                     ; 5EDC row 03
    R   ___                                     ; 5EDD row 04
    R   ___                                     ; 5EDE row 05
    R   ___                                     ; 5EDF row 06
    R   ___                                     ; 5EE0 row 07
    R   ___                                     ; 5EE1 row 08
    R   ___                                     ; 5EE2 row 09
    R   ___                                     ; 5EE3 row 10
    R   ___                                     ; 5EE4 row 11
    R   ___                                     ; 5EE5 row 12
    R   ___                                     ; 5EE6 row 13
    R   ___                                     ; 5EE7 row 14
    R   ___                                     ; 5EE8 row 15
    RI  Gs2, 3, 0                               ; 5EE9 row 16  Inst02
    R   ___                                     ; 5EEB row 17
    R   ___                                     ; 5EEC row 18
    R   ___                                     ; 5EED row 19
    R   ___                                     ; 5EEE row 20
    R   ___                                     ; 5EEF row 21
    R   ___                                     ; 5EF0 row 22
    R   ___                                     ; 5EF1 row 23
    R   ___                                     ; 5EF2 row 24
    R   ___                                     ; 5EF3 row 25
    R   ___                                     ; 5EF4 row 26
    R   ___                                     ; 5EF5 row 27
    R   ___                                     ; 5EF6 row 28
    R   ___                                     ; 5EF7 row 29
    R   ___                                     ; 5EF8 row 30
    R   ___                                     ; 5EF9 row 31
Track049:
    RIF C_3, 26, 0, $F, $A                      ; 5EFA row 00  Inst25  speed 10
    R   ___                                     ; 5EFD row 01
    R   ___                                     ; 5EFE row 02
    R   ___                                     ; 5EFF row 03
    R   ___                                     ; 5F00 row 04
    R   ___                                     ; 5F01 row 05
    R   ___                                     ; 5F02 row 06
    R   ___                                     ; 5F03 row 07
    RI  C_3, 27, 0                              ; 5F04 row 08  Inst26
    R   ___                                     ; 5F06 row 09
    R   ___                                     ; 5F07 row 10
    R   ___                                     ; 5F08 row 11
    R   ___                                     ; 5F09 row 12
    R   ___                                     ; 5F0A row 13
    R   ___                                     ; 5F0B row 14
    R   ___                                     ; 5F0C row 15
    RI  C_3, 26, 0                              ; 5F0D row 16  Inst25
    R   ___                                     ; 5F0F row 17
    R   ___                                     ; 5F10 row 18
    R   ___                                     ; 5F11 row 19
    R   ___                                     ; 5F12 row 20
    R   ___                                     ; 5F13 row 21
    R   ___                                     ; 5F14 row 22
    R   ___                                     ; 5F15 row 23
    RI  C_3, 28, 0                              ; 5F16 row 24  Inst27
    R   ___                                     ; 5F18 row 25
    R   ___                                     ; 5F19 row 26
    R   ___                                     ; 5F1A row 27
    R   ___                                     ; 5F1B row 28
    R   ___                                     ; 5F1C row 29
    R   ___                                     ; 5F1D row 30
    R   ___                                     ; 5F1E row 31
Track050:
    RI  C_3, 2, 0                               ; 5F1F row 00  Inst01
    R   ___                                     ; 5F21 row 01
    R   ___                                     ; 5F22 row 02
    R   ___                                     ; 5F23 row 03
    R   ___                                     ; 5F24 row 04
    R   ___                                     ; 5F25 row 05
    R   ___                                     ; 5F26 row 06
    R   ___                                     ; 5F27 row 07
    RI  D_3, 2, 0                               ; 5F28 row 08  Inst01
    R   ___                                     ; 5F2A row 09
    R   ___                                     ; 5F2B row 10
    R   ___                                     ; 5F2C row 11
    R   ___                                     ; 5F2D row 12
    R   ___                                     ; 5F2E row 13
    R   ___                                     ; 5F2F row 14
    R   ___                                     ; 5F30 row 15
    RI  Ds3, 2, 0                               ; 5F31 row 16  Inst01
    R   ___                                     ; 5F33 row 17
    R   ___                                     ; 5F34 row 18
    R   ___                                     ; 5F35 row 19
    R   ___                                     ; 5F36 row 20
    R   ___                                     ; 5F37 row 21
    R   ___                                     ; 5F38 row 22
    R   ___                                     ; 5F39 row 23
    RI  D_3, 2, 0                               ; 5F3A row 24  Inst01
    R   ___                                     ; 5F3C row 25
    R   ___                                     ; 5F3D row 26
    R   ___                                     ; 5F3E row 27
    R   ___                                     ; 5F3F row 28
    R   ___                                     ; 5F40 row 29
    R   ___                                     ; 5F41 row 30
    R   ___                                     ; 5F42 row 31
Track051:
    RI  C_3, 16, 0                              ; 5F43 row 00  Inst15
    R   ___                                     ; 5F45 row 01
    R   ___                                     ; 5F46 row 02
    R   ___                                     ; 5F47 row 03
    RI  G_3, 16, 0                              ; 5F48 row 04  Inst15
    R   ___                                     ; 5F4A row 05
    R   ___                                     ; 5F4B row 06
    R   ___                                     ; 5F4C row 07
    RI  D_3, 16, 0                              ; 5F4D row 08  Inst15
    R   ___                                     ; 5F4F row 09
    R   ___                                     ; 5F50 row 10
    R   ___                                     ; 5F51 row 11
    RI  Fs3, 16, 0                              ; 5F52 row 12  Inst15
    R   ___                                     ; 5F54 row 13
    R   ___                                     ; 5F55 row 14
    R   ___                                     ; 5F56 row 15
    RI  Ds3, 16, 0                              ; 5F57 row 16  Inst15
    R   ___                                     ; 5F59 row 17
    R   ___                                     ; 5F5A row 18
    R   ___                                     ; 5F5B row 19
    RI  G_3, 16, 0                              ; 5F5C row 20  Inst15
    R   ___                                     ; 5F5E row 21
    R   ___                                     ; 5F5F row 22
    R   ___                                     ; 5F60 row 23
    RI  D_3, 16, 0                              ; 5F61 row 24  Inst15
    R   ___                                     ; 5F63 row 25
    R   ___                                     ; 5F64 row 26
    R   ___                                     ; 5F65 row 27
    RI  Fs3, 16, 0                              ; 5F66 row 28  Inst15
    R   ___                                     ; 5F68 row 29
    R   ___                                     ; 5F69 row 30
    R   ___                                     ; 5F6A row 31
Track052:
    RI  C_3, 11, 0                              ; 5F6B row 00  Inst10
    R   ___                                     ; 5F6D row 01
    RI  C_3, 11, 1                              ; 5F6E row 02  Inst10
    R   ___                                     ; 5F70 row 03
    RI  C_3, 11, 0                              ; 5F71 row 04  Inst10
    R   ___                                     ; 5F73 row 05
    RI  C_3, 11, 1                              ; 5F74 row 06  Inst10
    R   ___                                     ; 5F76 row 07
    RI  C_3, 11, 0                              ; 5F77 row 08  Inst10
    R   ___                                     ; 5F79 row 09
    RI  C_3, 11, 1                              ; 5F7A row 10  Inst10
    R   ___                                     ; 5F7C row 11
    RI  C_3, 11, 0                              ; 5F7D row 12  Inst10
    R   ___                                     ; 5F7F row 13
    RI  C_3, 11, 1                              ; 5F80 row 14  Inst10
    R   ___                                     ; 5F82 row 15
    RI  C_3, 11, 0                              ; 5F83 row 16  Inst10
    R   ___                                     ; 5F85 row 17
    RI  C_3, 11, 1                              ; 5F86 row 18  Inst10
    R   ___                                     ; 5F88 row 19
    RI  C_3, 11, 0                              ; 5F89 row 20  Inst10
    R   ___                                     ; 5F8B row 21
    RI  C_3, 11, 1                              ; 5F8C row 22  Inst10
    R   ___                                     ; 5F8E row 23
    RI  C_3, 11, 0                              ; 5F8F row 24  Inst10
    R   ___                                     ; 5F91 row 25
    RI  C_3, 11, 1                              ; 5F92 row 26  Inst10
    R   ___                                     ; 5F94 row 27
    RI  C_3, 11, 0                              ; 5F95 row 28  Inst10
    R   ___                                     ; 5F97 row 29
    RI  C_3, 11, 1                              ; 5F98 row 30  Inst10
    R   ___                                     ; 5F9A row 31
Track053:
    RI  C_4, 1, 0                               ; 5F9B row 00  Inst00
    RI  C_5, 1, 1                               ; 5F9D row 01  Inst00
    RI  C_4, 1, 1                               ; 5F9F row 02  Inst00
    R   ___                                     ; 5FA1 row 03
    RI  G_4, 1, 0                               ; 5FA2 row 04  Inst00
    RI  C_4, 1, 1                               ; 5FA4 row 05  Inst00
    RI  G_4, 1, 1                               ; 5FA6 row 06  Inst00
    R   ___                                     ; 5FA8 row 07
    RI  D_4, 1, 0                               ; 5FA9 row 08  Inst00
    RI  D_5, 1, 1                               ; 5FAB row 09  Inst00
    RI  D_4, 1, 1                               ; 5FAD row 10  Inst00
    R   ___                                     ; 5FAF row 11
    RI  Fs4, 1, 0                               ; 5FB0 row 12  Inst00
    RI  Fs5, 1, 1                               ; 5FB2 row 13  Inst00
    RI  Fs4, 1, 1                               ; 5FB4 row 14  Inst00
    R   ___                                     ; 5FB6 row 15
    RI  Ds4, 1, 0                               ; 5FB7 row 16  Inst00
    RI  Ds5, 1, 1                               ; 5FB9 row 17  Inst00
    RI  Ds4, 1, 1                               ; 5FBB row 18  Inst00
    R   ___                                     ; 5FBD row 19
    RI  G_4, 1, 0                               ; 5FBE row 20  Inst00
    RI  G_5, 1, 1                               ; 5FC0 row 21  Inst00
    RI  G_4, 1, 1                               ; 5FC2 row 22  Inst00
    R   ___                                     ; 5FC4 row 23
    RI  D_4, 1, 0                               ; 5FC5 row 24  Inst00
    RI  D_5, 1, 1                               ; 5FC7 row 25  Inst00
    RI  D_4, 1, 1                               ; 5FC9 row 26  Inst00
    R   ___                                     ; 5FCB row 27
    RI  Fs4, 1, 0                               ; 5FCC row 28  Inst00
    RI  Fs5, 1, 1                               ; 5FCE row 29  Inst00
    RI  Fs4, 1, 1                               ; 5FD0 row 30  Inst00
    R   ___                                     ; 5FD2 row 31
Track054:
    RI  C_3, 10, 0                              ; 5FD3 row 00  Inst09
    R   ___                                     ; 5FD5 row 01
    RI  C_3, 10, 0                              ; 5FD6 row 02  Inst09
    R   ___                                     ; 5FD8 row 03
    RI  C_3, 8, 0                               ; 5FD9 row 04  Inst07
    R   ___                                     ; 5FDB row 05
    RI  C_4, 10, 0                              ; 5FDC row 06  Inst09
    R   ___                                     ; 5FDE row 07
    RI  D_3, 10, 0                              ; 5FDF row 08  Inst09
    R   ___                                     ; 5FE1 row 09
    RI  D_3, 10, 0                              ; 5FE2 row 10  Inst09
    R   ___                                     ; 5FE4 row 11
    RI  C_4, 8, 0                               ; 5FE5 row 12  Inst07
    R   ___                                     ; 5FE7 row 13
    RI  D_3, 10, 0                              ; 5FE8 row 14  Inst09
    R   ___                                     ; 5FEA row 15
    RI  Ds3, 10, 0                              ; 5FEB row 16  Inst09
    R   ___                                     ; 5FED row 17
    RI  Ds3, 10, 0                              ; 5FEE row 18  Inst09
    R   ___                                     ; 5FF0 row 19
    RI  C_3, 8, 0                               ; 5FF1 row 20  Inst07
    R   ___                                     ; 5FF3 row 21
    RI  Ds4, 10, 0                              ; 5FF4 row 22  Inst09
    R   ___                                     ; 5FF6 row 23
    RI  D_3, 10, 0                              ; 5FF7 row 24  Inst09
    R   ___                                     ; 5FF9 row 25
    RI  D_3, 10, 0                              ; 5FFA row 26  Inst09
    R   ___                                     ; 5FFC row 27
    RI  C_3, 8, 0                               ; 5FFD row 28  Inst07
    R   ___                                     ; 5FFF row 29
    RI  D_3, 10, 0                              ; 6000 row 30  Inst09
    R   ___                                     ; 6002 row 31
Track055:
    RI  C_3, 11, 0                              ; 6003 row 00  Inst10
    R   ___                                     ; 6005 row 01
    RI  C_3, 11, 0                              ; 6006 row 02  Inst10
    R   ___                                     ; 6008 row 03
    RI  C_4, 9, 0                               ; 6009 row 04  Inst08
    R   ___                                     ; 600B row 05
    RI  C_3, 11, 0                              ; 600C row 06  Inst10
    R   ___                                     ; 600E row 07
    RI  C_3, 11, 0                              ; 600F row 08  Inst10
    R   ___                                     ; 6011 row 09
    RI  C_3, 11, 0                              ; 6012 row 10  Inst10
    R   ___                                     ; 6014 row 11
    RI  C_4, 9, 0                               ; 6015 row 12  Inst08
    R   ___                                     ; 6017 row 13
    RI  C_3, 11, 0                              ; 6018 row 14  Inst10
    R   ___                                     ; 601A row 15
    RI  C_3, 11, 0                              ; 601B row 16  Inst10
    R   ___                                     ; 601D row 17
    RI  C_3, 11, 0                              ; 601E row 18  Inst10
    R   ___                                     ; 6020 row 19
    RI  C_4, 9, 0                               ; 6021 row 20  Inst08
    R   ___                                     ; 6023 row 21
    RI  C_3, 11, 0                              ; 6024 row 22  Inst10
    R   ___                                     ; 6026 row 23
    RI  C_3, 11, 0                              ; 6027 row 24  Inst10
    R   ___                                     ; 6029 row 25
    RI  C_3, 11, 0                              ; 602A row 26  Inst10
    R   ___                                     ; 602C row 27
    RI  C_4, 9, 0                               ; 602D row 28  Inst08
    R   ___                                     ; 602F row 29
    RI  C_3, 11, 0                              ; 6030 row 30  Inst10
    R   ___                                     ; 6032 row 31
Track056:
    RI  C_3, 10, 0                              ; 6033 row 00  Inst09
    R   ___                                     ; 6035 row 01
    RI  C_3, 10, 0                              ; 6036 row 02  Inst09
    R   ___                                     ; 6038 row 03
    RI  C_3, 8, 0                               ; 6039 row 04  Inst07
    R   ___                                     ; 603B row 05
    RI  C_4, 10, 0                              ; 603C row 06  Inst09
    R   ___                                     ; 603E row 07
    RI  D_3, 10, 0                              ; 603F row 08  Inst09
    R   ___                                     ; 6041 row 09
    RI  D_3, 10, 0                              ; 6042 row 10  Inst09
    R   ___                                     ; 6044 row 11
    RI  C_4, 8, 0                               ; 6045 row 12  Inst07
    R   ___                                     ; 6047 row 13
    RI  D_3, 10, 0                              ; 6048 row 14  Inst09
    R   ___                                     ; 604A row 15
    RI  Ds3, 10, 0                              ; 604B row 16  Inst09
    R   ___                                     ; 604D row 17
    RI  Ds3, 10, 0                              ; 604E row 18  Inst09
    R   ___                                     ; 6050 row 19
    RI  C_3, 8, 0                               ; 6051 row 20  Inst07
    R   ___                                     ; 6053 row 21
    RI  Ds4, 10, 0                              ; 6054 row 22  Inst09
    R   ___                                     ; 6056 row 23
    RI  D_3, 10, 0                              ; 6057 row 24  Inst09
    R   ___                                     ; 6059 row 25
    RI  D_3, 10, 0                              ; 605A row 26  Inst09
    R   ___                                     ; 605C row 27
    RI  C_3, 8, 0                               ; 605D row 28  Inst07
    R   ___                                     ; 605F row 29
    RI  C_3, 8, 0                               ; 6060 row 30  Inst07
    R   ___                                     ; 6062 row 31
Track057:
    RI  C_3, 11, 0                              ; 6063 row 00  Inst10
    R   ___                                     ; 6065 row 01
    RI  C_3, 11, 0                              ; 6066 row 02  Inst10
    R   ___                                     ; 6068 row 03
    RI  C_4, 9, 0                               ; 6069 row 04  Inst08
    R   ___                                     ; 606B row 05
    RI  C_3, 11, 0                              ; 606C row 06  Inst10
    R   ___                                     ; 606E row 07
    RI  C_3, 11, 0                              ; 606F row 08  Inst10
    R   ___                                     ; 6071 row 09
    RI  C_3, 11, 0                              ; 6072 row 10  Inst10
    R   ___                                     ; 6074 row 11
    RI  C_4, 9, 0                               ; 6075 row 12  Inst08
    R   ___                                     ; 6077 row 13
    RI  C_3, 11, 0                              ; 6078 row 14  Inst10
    R   ___                                     ; 607A row 15
    RI  C_3, 11, 0                              ; 607B row 16  Inst10
    R   ___                                     ; 607D row 17
    RI  C_3, 11, 0                              ; 607E row 18  Inst10
    R   ___                                     ; 6080 row 19
    RI  C_4, 9, 0                               ; 6081 row 20  Inst08
    R   ___                                     ; 6083 row 21
    RI  C_3, 11, 0                              ; 6084 row 22  Inst10
    R   ___                                     ; 6086 row 23
    RI  C_3, 11, 0                              ; 6087 row 24  Inst10
    R   ___                                     ; 6089 row 25
    RI  C_3, 11, 0                              ; 608A row 26  Inst10
    R   ___                                     ; 608C row 27
    RI  C_3, 9, 0                               ; 608D row 28  Inst08
    R   ___                                     ; 608F row 29
    RI  C_3, 9, 0                               ; 6090 row 30  Inst08
    R   ___                                     ; 6092 row 31
Track058:
    RI  C_4, 29, 0                              ; 6093 row 00  Inst28
    R   ___                                     ; 6095 row 01
    R   ___                                     ; 6096 row 02
    R   ___                                     ; 6097 row 03
    R   ___                                     ; 6098 row 04
    R   ___                                     ; 6099 row 05
    R   ___                                     ; 609A row 06
    R   ___                                     ; 609B row 07
    RI  G_4, 29, 0                              ; 609C row 08  Inst28
    R   ___                                     ; 609E row 09
    R   ___                                     ; 609F row 10
    R   ___                                     ; 60A0 row 11
    R   ___                                     ; 60A1 row 12
    R   ___                                     ; 60A2 row 13
    R   ___                                     ; 60A3 row 14
    R   ___                                     ; 60A4 row 15
    RI  Ds4, 29, 0                              ; 60A5 row 16  Inst28
    R   ___                                     ; 60A7 row 17
    R   ___                                     ; 60A8 row 18
    R   ___                                     ; 60A9 row 19
    R   ___                                     ; 60AA row 20
    R   ___                                     ; 60AB row 21
    R   ___                                     ; 60AC row 22
    R   ___                                     ; 60AD row 23
    RI  D_4, 29, 0                              ; 60AE row 24  Inst28
    R   ___                                     ; 60B0 row 25
    R   ___                                     ; 60B1 row 26
    R   ___                                     ; 60B2 row 27
    R   B_3                                     ; 60B3 row 28
    R   ___                                     ; 60B4 row 29
    R   ___                                     ; 60B5 row 30
    R   ___                                     ; 60B6 row 31
Track059:
    RI  C_3, 10, 0                              ; 60B7 row 00  Inst09
    R   ___                                     ; 60B9 row 01
    RI  C_3, 10, 0                              ; 60BA row 02  Inst09
    R   ___                                     ; 60BC row 03
    RI  C_3, 8, 0                               ; 60BD row 04  Inst07
    R   ___                                     ; 60BF row 05
    RI  C_4, 10, 0                              ; 60C0 row 06  Inst09
    R   ___                                     ; 60C2 row 07
    RI  D_3, 10, 0                              ; 60C3 row 08  Inst09
    R   ___                                     ; 60C5 row 09
    RI  D_3, 10, 0                              ; 60C6 row 10  Inst09
    R   ___                                     ; 60C8 row 11
    RI  C_4, 8, 0                               ; 60C9 row 12  Inst07
    R   ___                                     ; 60CB row 13
    RI  D_3, 10, 0                              ; 60CC row 14  Inst09
    R   ___                                     ; 60CE row 15
    RI  Gs2, 10, 0                              ; 60CF row 16  Inst09
    R   ___                                     ; 60D1 row 17
    RI  Gs2, 10, 0                              ; 60D2 row 18  Inst09
    R   ___                                     ; 60D4 row 19
    RI  C_3, 8, 0                               ; 60D5 row 20  Inst07
    R   ___                                     ; 60D7 row 21
    RI  Gs3, 10, 0                              ; 60D8 row 22  Inst09
    R   ___                                     ; 60DA row 23
    RI  G_2, 10, 0                              ; 60DB row 24  Inst09
    R   ___                                     ; 60DD row 25
    RI  G_2, 10, 0                              ; 60DE row 26  Inst09
    R   ___                                     ; 60E0 row 27
    RI  C_3, 8, 0                               ; 60E1 row 28  Inst07
    R   ___                                     ; 60E3 row 29
    RI  G_3, 10, 0                              ; 60E4 row 30  Inst09
    R   ___                                     ; 60E6 row 31
Track060:
    RIF C_3, 26, 0, $F, $A                      ; 60E7 row 00  Inst25  speed 10
    R   ___                                     ; 60EA row 01
    R   ___                                     ; 60EB row 02
    R   ___                                     ; 60EC row 03
    R   ___                                     ; 60ED row 04
    R   ___                                     ; 60EE row 05
    R   ___                                     ; 60EF row 06
    R   ___                                     ; 60F0 row 07
    RI  C_3, 27, 0                              ; 60F1 row 08  Inst26
    R   ___                                     ; 60F3 row 09
    R   ___                                     ; 60F4 row 10
    R   ___                                     ; 60F5 row 11
    R   ___                                     ; 60F6 row 12
    R   ___                                     ; 60F7 row 13
    R   ___                                     ; 60F8 row 14
    R   ___                                     ; 60F9 row 15
    RI  C_3, 26, 0                              ; 60FA row 16  Inst25
    R   ___                                     ; 60FC row 17
    R   ___                                     ; 60FD row 18
    R   ___                                     ; 60FE row 19
    R   ___                                     ; 60FF row 20
    R   ___                                     ; 6100 row 21
    R   ___                                     ; 6101 row 22
    R   ___                                     ; 6102 row 23
    RI  C_3, 30, 0                              ; 6103 row 24  Inst29
    R   ___                                     ; 6105 row 25
    R   ___                                     ; 6106 row 26
    R   ___                                     ; 6107 row 27
    R   ___                                     ; 6108 row 28
    R   ___                                     ; 6109 row 29
    R   ___                                     ; 610A row 30
    R   ___                                     ; 610B row 31
Track061:
    RI  C_4, 29, 0                              ; 610C row 00  Inst28
    R   ___                                     ; 610E row 01
    R   ___                                     ; 610F row 02
    R   ___                                     ; 6110 row 03
    R   ___                                     ; 6111 row 04
    R   ___                                     ; 6112 row 05
    R   ___                                     ; 6113 row 06
    R   ___                                     ; 6114 row 07
    RI  G_4, 29, 0                              ; 6115 row 08  Inst28
    R   ___                                     ; 6117 row 09
    R   ___                                     ; 6118 row 10
    R   ___                                     ; 6119 row 11
    R   ___                                     ; 611A row 12
    R   ___                                     ; 611B row 13
    R   ___                                     ; 611C row 14
    R   ___                                     ; 611D row 15
    RI  Gs4, 29, 0                              ; 611E row 16  Inst28
    R   ___                                     ; 6120 row 17
    R   ___                                     ; 6121 row 18
    R   ___                                     ; 6122 row 19
    R   ___                                     ; 6123 row 20
    R   ___                                     ; 6124 row 21
    R   ___                                     ; 6125 row 22
    R   ___                                     ; 6126 row 23
    RI  As4, 29, 0                              ; 6127 row 24  Inst28
    R   ___                                     ; 6129 row 25
    R   ___                                     ; 612A row 26
    R   ___                                     ; 612B row 27
    R   G_4                                     ; 612C row 28
    R   ___                                     ; 612D row 29
    R   ___                                     ; 612E row 30
    R   ___                                     ; 612F row 31
Track062:
    RIF C_3, 26, 0, $F, $A                      ; 6130 row 00  Inst25  speed 10
    R   ___                                     ; 6133 row 01
    R   ___                                     ; 6134 row 02
    R   ___                                     ; 6135 row 03
    R   ___                                     ; 6136 row 04
    R   ___                                     ; 6137 row 05
    R   ___                                     ; 6138 row 06
    R   ___                                     ; 6139 row 07
    RI  C_3, 27, 0                              ; 613A row 08  Inst26
    R   ___                                     ; 613C row 09
    R   ___                                     ; 613D row 10
    R   ___                                     ; 613E row 11
    R   ___                                     ; 613F row 12
    R   ___                                     ; 6140 row 13
    R   ___                                     ; 6141 row 14
    R   ___                                     ; 6142 row 15
    RI  Cs3, 30, 0                              ; 6143 row 16  Inst29
    R   ___                                     ; 6145 row 17
    R   ___                                     ; 6146 row 18
    R   ___                                     ; 6147 row 19
    R   ___                                     ; 6148 row 20
    R   ___                                     ; 6149 row 21
    R   ___                                     ; 614A row 22
    R   ___                                     ; 614B row 23
    RI  Ds3, 30, 0                              ; 614C row 24  Inst29
    R   ___                                     ; 614E row 25
    R   ___                                     ; 614F row 26
    R   ___                                     ; 6150 row 27
    R   ___                                     ; 6151 row 28
    R   ___                                     ; 6152 row 29
    R   ___                                     ; 6153 row 30
    R   ___                                     ; 6154 row 31
Track063:
    RI  C_4, 29, 0                              ; 6155 row 00  Inst28
    R   ___                                     ; 6157 row 01
    R   ___                                     ; 6158 row 02
    R   ___                                     ; 6159 row 03
    R   ___                                     ; 615A row 04
    R   ___                                     ; 615B row 05
    R   ___                                     ; 615C row 06
    R   ___                                     ; 615D row 07
    RI  G_4, 29, 0                              ; 615E row 08  Inst28
    R   ___                                     ; 6160 row 09
    R   ___                                     ; 6161 row 10
    R   ___                                     ; 6162 row 11
    R   ___                                     ; 6163 row 12
    R   ___                                     ; 6164 row 13
    R   ___                                     ; 6165 row 14
    R   ___                                     ; 6166 row 15
    RI  Gs4, 29, 0                              ; 6167 row 16  Inst28
    R   ___                                     ; 6169 row 17
    R   ___                                     ; 616A row 18
    R   ___                                     ; 616B row 19
    R   ___                                     ; 616C row 20
    R   ___                                     ; 616D row 21
    R   ___                                     ; 616E row 22
    R   ___                                     ; 616F row 23
    RI  Ds5, 29, 0                              ; 6170 row 24  Inst28
    R   ___                                     ; 6172 row 25
    R   ___                                     ; 6173 row 26
    R   ___                                     ; 6174 row 27
    RI  D_5, 29, 0                              ; 6175 row 28  Inst28
    R   ___                                     ; 6177 row 29
    R   ___                                     ; 6178 row 30
    R   ___                                     ; 6179 row 31
Track064:
    RI  C_5, 29, 0                              ; 617A row 00  Inst28
    R   ___                                     ; 617C row 01
    R   ___                                     ; 617D row 02
    R   ___                                     ; 617E row 03
    R   ___                                     ; 617F row 04
    R   ___                                     ; 6180 row 05
    R   ___                                     ; 6181 row 06
    R   ___                                     ; 6182 row 07
    RI  C_5, 31, 0                              ; 6183 row 08  Inst30
    R   ___                                     ; 6185 row 09
    R   ___                                     ; 6186 row 10
    R   ___                                     ; 6187 row 11
    R   ___                                     ; 6188 row 12
    R   ___                                     ; 6189 row 13
    R   ___                                     ; 618A row 14
    R   ___                                     ; 618B row 15
    R   ___                                     ; 618C row 16
    R   ___                                     ; 618D row 17
    R   ___                                     ; 618E row 18
    R   ___                                     ; 618F row 19
    R   ___                                     ; 6190 row 20
    R   ___                                     ; 6191 row 21
    R   ___                                     ; 6192 row 22
    R   ___                                     ; 6193 row 23
    R   ___                                     ; 6194 row 24
    R   ___                                     ; 6195 row 25
    R   ___                                     ; 6196 row 26
    R   ___                                     ; 6197 row 27
    R   ___                                     ; 6198 row 28
    R   ___                                     ; 6199 row 29
    R   ___                                     ; 619A row 30
    R   ___                                     ; 619B row 31
Track065:
    RI  C_2, 26, 0                              ; 619C row 00  Inst25
    R   ___                                     ; 619E row 01
    R   ___                                     ; 619F row 02
    R   ___                                     ; 61A0 row 03
    R   ___                                     ; 61A1 row 04
    R   ___                                     ; 61A2 row 05
    R   ___                                     ; 61A3 row 06
    R   ___                                     ; 61A4 row 07
    RI  C_2, 26, 0                              ; 61A5 row 08  Inst25
    R   ___                                     ; 61A7 row 09
    R   ___                                     ; 61A8 row 10
    R   ___                                     ; 61A9 row 11
    R   ___                                     ; 61AA row 12
    R   ___                                     ; 61AB row 13
    R   ___                                     ; 61AC row 14
    R   ___                                     ; 61AD row 15
    RI  C_2, 26, 0                              ; 61AE row 16  Inst25
    R   ___                                     ; 61B0 row 17
    R   ___                                     ; 61B1 row 18
    R   ___                                     ; 61B2 row 19
    R   ___                                     ; 61B3 row 20
    R   ___                                     ; 61B4 row 21
    R   ___                                     ; 61B5 row 22
    R   ___                                     ; 61B6 row 23
    RI  C_2, 26, 0                              ; 61B7 row 24  Inst25
    R   ___                                     ; 61B9 row 25
    R   ___                                     ; 61BA row 26
    R   ___                                     ; 61BB row 27
    R   ___                                     ; 61BC row 28
    R   ___                                     ; 61BD row 29
    R   ___                                     ; 61BE row 30
    R   ___                                     ; 61BF row 31
Track066:
    RI  C_3, 10, 0                              ; 61C0 row 00  Inst09
    R   ___                                     ; 61C2 row 01
    RI  C_3, 10, 0                              ; 61C3 row 02  Inst09
    R   ___                                     ; 61C5 row 03
    RI  C_3, 8, 0                               ; 61C6 row 04  Inst07
    R   ___                                     ; 61C8 row 05
    RI  C_4, 10, 0                              ; 61C9 row 06  Inst09
    R   ___                                     ; 61CB row 07
    RI  D_3, 10, 0                              ; 61CC row 08  Inst09
    R   ___                                     ; 61CE row 09
    RI  D_3, 10, 0                              ; 61CF row 10  Inst09
    R   ___                                     ; 61D1 row 11
    RI  C_4, 8, 0                               ; 61D2 row 12  Inst07
    R   ___                                     ; 61D4 row 13
    RI  D_3, 10, 0                              ; 61D5 row 14  Inst09
    R   ___                                     ; 61D7 row 15
    RI  Gs2, 10, 0                              ; 61D8 row 16  Inst09
    R   ___                                     ; 61DA row 17
    RI  Gs2, 10, 0                              ; 61DB row 18  Inst09
    R   ___                                     ; 61DD row 19
    RI  C_3, 8, 0                               ; 61DE row 20  Inst07
    R   ___                                     ; 61E0 row 21
    RI  Gs3, 10, 0                              ; 61E1 row 22  Inst09
    R   ___                                     ; 61E3 row 23
    RI  Ds2, 10, 0                              ; 61E4 row 24  Inst09
    R   ___                                     ; 61E6 row 25
    R   ___                                     ; 61E7 row 26
    R   ___                                     ; 61E8 row 27
    RI  D_2, 10, 0                              ; 61E9 row 28  Inst09
    R   ___                                     ; 61EB row 29
    R   ___                                     ; 61EC row 30
    R   ___                                     ; 61ED row 31
Track067:
    RI  C_3, 11, 0                              ; 61EE row 00  Inst10
    R   ___                                     ; 61F0 row 01
    RI  C_3, 11, 0                              ; 61F1 row 02  Inst10
    R   ___                                     ; 61F3 row 03
    RI  C_4, 9, 0                               ; 61F4 row 04  Inst08
    R   ___                                     ; 61F6 row 05
    RI  C_3, 11, 0                              ; 61F7 row 06  Inst10
    R   ___                                     ; 61F9 row 07
    RI  C_3, 11, 0                              ; 61FA row 08  Inst10
    R   ___                                     ; 61FC row 09
    RI  C_3, 11, 0                              ; 61FD row 10  Inst10
    R   ___                                     ; 61FF row 11
    RI  C_4, 9, 0                               ; 6200 row 12  Inst08
    R   ___                                     ; 6202 row 13
    RI  C_3, 11, 0                              ; 6203 row 14  Inst10
    R   ___                                     ; 6205 row 15
    RI  C_3, 11, 0                              ; 6206 row 16  Inst10
    R   ___                                     ; 6208 row 17
    RI  C_3, 11, 0                              ; 6209 row 18  Inst10
    R   ___                                     ; 620B row 19
    RI  C_4, 9, 0                               ; 620C row 20  Inst08
    R   ___                                     ; 620E row 21
    RI  C_3, 11, 0                              ; 620F row 22  Inst10
    R   ___                                     ; 6211 row 23
    RI  C_3, 12, 0                              ; 6212 row 24  Inst11
    R   ___                                     ; 6214 row 25
    R   ___                                     ; 6215 row 26
    R   ___                                     ; 6216 row 27
    RI  C_3, 12, 0                              ; 6217 row 28  Inst11
    R   ___                                     ; 6219 row 29
    R   ___                                     ; 621A row 30
    R   ___                                     ; 621B row 31
Track068:
    RIF C_3, 26, 0, $F, $A                      ; 621C row 00  Inst25  speed 10
    R   ___                                     ; 621F row 01
    R   ___                                     ; 6220 row 02
    R   ___                                     ; 6221 row 03
    R   ___                                     ; 6222 row 04
    R   ___                                     ; 6223 row 05
    R   ___                                     ; 6224 row 06
    R   ___                                     ; 6225 row 07
    RI  C_3, 27, 0                              ; 6226 row 08  Inst26
    R   ___                                     ; 6228 row 09
    R   ___                                     ; 6229 row 10
    R   ___                                     ; 622A row 11
    R   ___                                     ; 622B row 12
    R   ___                                     ; 622C row 13
    R   ___                                     ; 622D row 14
    R   ___                                     ; 622E row 15
    RI  Cs3, 30, 0                              ; 622F row 16  Inst29
    R   ___                                     ; 6231 row 17
    R   ___                                     ; 6232 row 18
    R   ___                                     ; 6233 row 19
    R   ___                                     ; 6234 row 20
    R   ___                                     ; 6235 row 21
    R   ___                                     ; 6236 row 22
    R   ___                                     ; 6237 row 23
    RI  Ds2, 27, 0                              ; 6238 row 24  Inst26
    R   ___                                     ; 623A row 25
    R   ___                                     ; 623B row 26
    R   ___                                     ; 623C row 27
    RI  Ds2, 30, 0                              ; 623D row 28  Inst29
    R   ___                                     ; 623F row 29
    R   ___                                     ; 6240 row 30
    R   ___                                     ; 6241 row 31
Track069:
    RIF G_4, 1, 0, $F, $C                       ; 6242 row 00  Inst00  speed 12
    R   ___                                     ; 6245 row 01
    RI  Ds4, 1, 0                               ; 6246 row 02  Inst00
    R   ___                                     ; 6248 row 03
    RI  D_4, 1, 0                               ; 6249 row 04  Inst00
    R   ___                                     ; 624B row 05
    RI  As3, 1, 0                               ; 624C row 06  Inst00
    R   ___                                     ; 624E row 07
    RI  G_3, 1, 0                               ; 624F row 08  Inst00
    R   ___                                     ; 6251 row 09
    RI  Ds3, 1, 0                               ; 6252 row 10  Inst00
    R   ___                                     ; 6254 row 11
    RI  D_3, 1, 0                               ; 6255 row 12  Inst00
    R   ___                                     ; 6257 row 13
    RI  As2, 1, 0                               ; 6258 row 14  Inst00
    R   ___                                     ; 625A row 15
    RI  C_4, 31, 0                              ; 625B row 16  Inst30
    R   ___                                     ; 625D row 17
    R   ___                                     ; 625E row 18
    R   ___                                     ; 625F row 19
    R   ___                                     ; 6260 row 20
    R   ___                                     ; 6261 row 21
    R   ___                                     ; 6262 row 22
    R   ___                                     ; 6263 row 23
    R   ___                                     ; 6264 row 24
    R   ___                                     ; 6265 row 25
    R   ___                                     ; 6266 row 26
    R   ___                                     ; 6267 row 27
    R   ___                                     ; 6268 row 28
    R   ___                                     ; 6269 row 29
    R   ___                                     ; 626A row 30
    R   ___                                     ; 626B row 31
Track070:
    R   ___                                     ; 626C row 00
    RI  G_4, 1, 0                               ; 626D row 01  Inst00
    R   ___                                     ; 626F row 02
    RI  Ds4, 1, 0                               ; 6270 row 03  Inst00
    R   ___                                     ; 6272 row 04
    RI  D_4, 1, 0                               ; 6273 row 05  Inst00
    R   ___                                     ; 6275 row 06
    RI  As3, 1, 0                               ; 6276 row 07  Inst00
    R   ___                                     ; 6278 row 08
    RI  G_3, 1, 0                               ; 6279 row 09  Inst00
    R   ___                                     ; 627B row 10
    RI  Ds3, 1, 0                               ; 627C row 11  Inst00
    R   ___                                     ; 627E row 12
    RI  D_3, 1, 0                               ; 627F row 13  Inst00
    R   ___                                     ; 6281 row 14
    RI  As2, 1, 0                               ; 6282 row 15  Inst00
    R   ___                                     ; 6284 row 16
    RI  C_4, 31, 0                              ; 6285 row 17  Inst30
    R   ___                                     ; 6287 row 18
    R   ___                                     ; 6288 row 19
    R   ___                                     ; 6289 row 20
    R   ___                                     ; 628A row 21
    R   ___                                     ; 628B row 22
    R   ___                                     ; 628C row 23
    R   ___                                     ; 628D row 24
    R   ___                                     ; 628E row 25
    R   ___                                     ; 628F row 26
    R   ___                                     ; 6290 row 27
    R   ___                                     ; 6291 row 28
    R   ___                                     ; 6292 row 29
    R   ___                                     ; 6293 row 30
    R   ___                                     ; 6294 row 31
Track071:
    RI  C_4, 2, 0                               ; 6295 row 00  Inst01
    R   ___                                     ; 6297 row 01
    R   ___                                     ; 6298 row 02
    R   ___                                     ; 6299 row 03
    RI  As3, 2, 0                               ; 629A row 04  Inst01
    R   ___                                     ; 629C row 05
    R   ___                                     ; 629D row 06
    R   ___                                     ; 629E row 07
    RI  Gs3, 2, 0                               ; 629F row 08  Inst01
    R   ___                                     ; 62A1 row 09
    R   ___                                     ; 62A2 row 10
    R   ___                                     ; 62A3 row 11
    RI  G_3, 2, 0                               ; 62A4 row 12  Inst01
    R   ___                                     ; 62A6 row 13
    RI  As2, 2, 0                               ; 62A7 row 14  Inst01
    R   ___                                     ; 62A9 row 15
    RI  C_3, 2, 0                               ; 62AA row 16  Inst01
    R   ___                                     ; 62AC row 17
    R   ___                                     ; 62AD row 18
    RI  ___, 0, 2                               ; 62AE row 19
    R   ___                                     ; 62B0 row 20
    R   ___                                     ; 62B1 row 21
    RI  ___, 0, 1                               ; 62B2 row 22
    R   ___                                     ; 62B4 row 23
    RI  C_5, 25, 0                              ; 62B5 row 24  Inst24
    R   ___                                     ; 62B7 row 25
    R   ___                                     ; 62B8 row 26
    R   ___                                     ; 62B9 row 27
    R   ___                                     ; 62BA row 28
    R   ___                                     ; 62BB row 29
    R   ___                                     ; 62BC row 30
    R   ___                                     ; 62BD row 31
Track072:
    RI  C_6, 21, 0                              ; 62BE row 00  Inst20
    R   ___                                     ; 62C0 row 01
    R   ___                                     ; 62C1 row 02
    R   ___                                     ; 62C2 row 03
    RI  C_5, 21, 0                              ; 62C3 row 04  Inst20
    R   ___                                     ; 62C5 row 05
    R   ___                                     ; 62C6 row 06
    R   ___                                     ; 62C7 row 07
    RI  C_4, 21, 0                              ; 62C8 row 08  Inst20
    R   ___                                     ; 62CA row 09
    R   ___                                     ; 62CB row 10
    R   ___                                     ; 62CC row 11
    RI  C_4, 21, 0                              ; 62CD row 12  Inst20
    R   ___                                     ; 62CF row 13
    RI  C_3, 21, 0                              ; 62D0 row 14  Inst20
    R   ___                                     ; 62D2 row 15
    RI  C_2, 21, 0                              ; 62D3 row 16  Inst20
    R   ___                                     ; 62D5 row 17
    R   ___                                     ; 62D6 row 18
    R   ___                                     ; 62D7 row 19
    R   ___                                     ; 62D8 row 20
    R   ___                                     ; 62D9 row 21
    R   ___                                     ; 62DA row 22
    R   ___                                     ; 62DB row 23
    R   ___                                     ; 62DC row 24
    R   ___                                     ; 62DD row 25
    R   ___                                     ; 62DE row 26
    R   ___                                     ; 62DF row 27
    R   ___                                     ; 62E0 row 28
    R   ___                                     ; 62E1 row 29
    R   ___                                     ; 62E2 row 30
    R   ___                                     ; 62E3 row 31
Track073:
    RIF C_3, 4, 0, $F, $B                       ; 62E4 row 00  Inst03  speed 11
    RI  C_3, 4, 1                               ; 62E7 row 01  Inst03
    R   ___                                     ; 62E9 row 02
    R   ___                                     ; 62EA row 03
    RI  Fs3, 4, 0                               ; 62EB row 04  Inst03
    RI  Fs3, 4, 1                               ; 62ED row 05  Inst03
    R   ___                                     ; 62EF row 06
    R   ___                                     ; 62F0 row 07
    RI  Gs3, 4, 0                               ; 62F1 row 08  Inst03
    RI  Gs3, 4, 1                               ; 62F3 row 09  Inst03
    R   ___                                     ; 62F5 row 10
    R   ___                                     ; 62F6 row 11
    RI  Fs3, 4, 0                               ; 62F7 row 12  Inst03
    RI  Fs3, 4, 1                               ; 62F9 row 13  Inst03
    R   ___                                     ; 62FB row 14
    R   ___                                     ; 62FC row 15
    RI  C_3, 4, 0                               ; 62FD row 16  Inst03
    RI  C_3, 4, 1                               ; 62FF row 17  Inst03
    R   ___                                     ; 6301 row 18
    R   ___                                     ; 6302 row 19
    RI  Fs3, 4, 0                               ; 6303 row 20  Inst03
    RI  Fs3, 4, 1                               ; 6305 row 21  Inst03
    R   ___                                     ; 6307 row 22
    R   ___                                     ; 6308 row 23
    RI  Gs3, 4, 0                               ; 6309 row 24  Inst03
    RI  Gs3, 4, 1                               ; 630B row 25  Inst03
    R   ___                                     ; 630D row 26
    R   ___                                     ; 630E row 27
    RI  Fs3, 4, 0                               ; 630F row 28  Inst03
    RI  Fs3, 4, 1                               ; 6311 row 29  Inst03
    R   ___                                     ; 6313 row 30
    R   ___                                     ; 6314 row 31
Track074:
    R   ___                                     ; 6315 row 00
    R   ___                                     ; 6316 row 01
    RI  Ds3, 4, 0                               ; 6317 row 02  Inst03
    RI  Ds3, 4, 1                               ; 6319 row 03  Inst03
    R   ___                                     ; 631B row 04
    R   ___                                     ; 631C row 05
    RI  G_3, 4, 0                               ; 631D row 06  Inst03
    RI  G_3, 4, 1                               ; 631F row 07  Inst03
    R   ___                                     ; 6321 row 08
    R   ___                                     ; 6322 row 09
    RI  G_3, 4, 0                               ; 6323 row 10  Inst03
    RI  G_3, 4, 1                               ; 6325 row 11  Inst03
    R   ___                                     ; 6327 row 12
    R   ___                                     ; 6328 row 13
    RI  G_3, 4, 0                               ; 6329 row 14  Inst03
    RI  G_3, 4, 1                               ; 632B row 15  Inst03
    R   ___                                     ; 632D row 16
    R   ___                                     ; 632E row 17
    RI  Ds3, 4, 0                               ; 632F row 18  Inst03
    RI  Ds3, 4, 1                               ; 6331 row 19  Inst03
    R   ___                                     ; 6333 row 20
    R   ___                                     ; 6334 row 21
    RI  G_3, 4, 0                               ; 6335 row 22  Inst03
    RI  G_3, 4, 1                               ; 6337 row 23  Inst03
    R   ___                                     ; 6339 row 24
    R   ___                                     ; 633A row 25
    RI  G_3, 4, 0                               ; 633B row 26  Inst03
    RI  G_3, 4, 1                               ; 633D row 27  Inst03
    R   ___                                     ; 633F row 28
    R   ___                                     ; 6340 row 29
    RI  Ds3, 4, 0                               ; 6341 row 30  Inst03
    RI  Ds3, 4, 1                               ; 6343 row 31  Inst03
Track075:
    RI  C_3, 2, 0                               ; 6345 row 00  Inst01
    R   ___                                     ; 6347 row 01
    R   ___                                     ; 6348 row 02
    R   ___                                     ; 6349 row 03
    R   ___                                     ; 634A row 04
    R   ___                                     ; 634B row 05
    R   ___                                     ; 634C row 06
    R   ___                                     ; 634D row 07
    R   ___                                     ; 634E row 08
    R   ___                                     ; 634F row 09
    R   ___                                     ; 6350 row 10
    R   ___                                     ; 6351 row 11
    R   ___                                     ; 6352 row 12
    R   ___                                     ; 6353 row 13
    R   ___                                     ; 6354 row 14
    R   ___                                     ; 6355 row 15
    RI  Fs2, 2, 0                               ; 6356 row 16  Inst01
    R   ___                                     ; 6358 row 17
    R   ___                                     ; 6359 row 18
    R   ___                                     ; 635A row 19
    R   ___                                     ; 635B row 20
    R   ___                                     ; 635C row 21
    R   ___                                     ; 635D row 22
    R   ___                                     ; 635E row 23
    R   ___                                     ; 635F row 24
    R   ___                                     ; 6360 row 25
    R   ___                                     ; 6361 row 26
    R   ___                                     ; 6362 row 27
    R   ___                                     ; 6363 row 28
    R   ___                                     ; 6364 row 29
    R   ___                                     ; 6365 row 30
    R   ___                                     ; 6366 row 31
Track076:
    RI  C_5, 21, 0                              ; 6367 row 00  Inst20
    R   ___                                     ; 6369 row 01
    R   ___                                     ; 636A row 02
    R   ___                                     ; 636B row 03
    R   ___                                     ; 636C row 04
    R   ___                                     ; 636D row 05
    R   ___                                     ; 636E row 06
    R   ___                                     ; 636F row 07
    RI  C_5, 21, 0                              ; 6370 row 08  Inst20
    R   ___                                     ; 6372 row 09
    R   ___                                     ; 6373 row 10
    R   ___                                     ; 6374 row 11
    R   ___                                     ; 6375 row 12
    R   ___                                     ; 6376 row 13
    R   ___                                     ; 6377 row 14
    R   ___                                     ; 6378 row 15
    RI  C_5, 21, 0                              ; 6379 row 16  Inst20
    R   ___                                     ; 637B row 17
    R   ___                                     ; 637C row 18
    R   ___                                     ; 637D row 19
    R   ___                                     ; 637E row 20
    R   ___                                     ; 637F row 21
    R   ___                                     ; 6380 row 22
    R   ___                                     ; 6381 row 23
    RI  C_5, 21, 0                              ; 6382 row 24  Inst20
    R   ___                                     ; 6384 row 25
    R   ___                                     ; 6385 row 26
    R   ___                                     ; 6386 row 27
    R   ___                                     ; 6387 row 28
    R   ___                                     ; 6388 row 29
    R   ___                                     ; 6389 row 30
    R   ___                                     ; 638A row 31
Track077:
    RI  C_3, 4, 0                               ; 638B row 00  Inst03
    RI  C_3, 4, 1                               ; 638D row 01  Inst03
    R   ___                                     ; 638F row 02
    R   ___                                     ; 6390 row 03
    RI  Fs3, 4, 0                               ; 6391 row 04  Inst03
    RI  Fs3, 4, 1                               ; 6393 row 05  Inst03
    R   ___                                     ; 6395 row 06
    R   ___                                     ; 6396 row 07
    RI  Gs3, 4, 0                               ; 6397 row 08  Inst03
    RI  Gs3, 4, 1                               ; 6399 row 09  Inst03
    R   ___                                     ; 639B row 10
    R   ___                                     ; 639C row 11
    RI  Fs3, 4, 0                               ; 639D row 12  Inst03
    RI  Fs3, 4, 1                               ; 639F row 13  Inst03
    R   ___                                     ; 63A1 row 14
    R   ___                                     ; 63A2 row 15
    RI  C_3, 4, 0                               ; 63A3 row 16  Inst03
    RI  C_3, 4, 1                               ; 63A5 row 17  Inst03
    R   ___                                     ; 63A7 row 18
    R   ___                                     ; 63A8 row 19
    RI  Fs3, 4, 0                               ; 63A9 row 20  Inst03
    RI  Fs3, 4, 1                               ; 63AB row 21  Inst03
    R   ___                                     ; 63AD row 22
    R   ___                                     ; 63AE row 23
    RI  C_3, 4, 0                               ; 63AF row 24  Inst03
    RI  C_3, 4, 1                               ; 63B1 row 25  Inst03
    R   ___                                     ; 63B3 row 26
    R   ___                                     ; 63B4 row 27
    R   ___                                     ; 63B5 row 28
    R   ___                                     ; 63B6 row 29
    R   ___                                     ; 63B7 row 30
    R   ___                                     ; 63B8 row 31
Track078:
    R   ___                                     ; 63B9 row 00
    R   ___                                     ; 63BA row 01
    RI  Ds3, 4, 0                               ; 63BB row 02  Inst03
    RI  Ds3, 4, 1                               ; 63BD row 03  Inst03
    R   ___                                     ; 63BF row 04
    R   ___                                     ; 63C0 row 05
    RI  G_3, 4, 0                               ; 63C1 row 06  Inst03
    RI  G_3, 4, 1                               ; 63C3 row 07  Inst03
    R   ___                                     ; 63C5 row 08
    R   ___                                     ; 63C6 row 09
    RI  G_3, 4, 0                               ; 63C7 row 10  Inst03
    RI  G_3, 4, 1                               ; 63C9 row 11  Inst03
    R   ___                                     ; 63CB row 12
    R   ___                                     ; 63CC row 13
    RI  G_3, 4, 0                               ; 63CD row 14  Inst03
    RI  G_3, 4, 1                               ; 63CF row 15  Inst03
    R   ___                                     ; 63D1 row 16
    R   ___                                     ; 63D2 row 17
    RI  Ds3, 4, 0                               ; 63D3 row 18  Inst03
    RI  Ds3, 4, 1                               ; 63D5 row 19  Inst03
    R   ___                                     ; 63D7 row 20
    R   ___                                     ; 63D8 row 21
    RI  G_3, 4, 0                               ; 63D9 row 22  Inst03
    RI  G_3, 4, 1                               ; 63DB row 23  Inst03
    R   ___                                     ; 63DD row 24
    R   ___                                     ; 63DE row 25
    R   ___                                     ; 63DF row 26
    R   ___                                     ; 63E0 row 27
    R   ___                                     ; 63E1 row 28
    R   ___                                     ; 63E2 row 29
    R   ___                                     ; 63E3 row 30
    R   ___                                     ; 63E4 row 31
Track079:
    RI  C_3, 2, 0                               ; 63E5 row 00  Inst01
    R   ___                                     ; 63E7 row 01
    R   ___                                     ; 63E8 row 02
    R   ___                                     ; 63E9 row 03
    R   ___                                     ; 63EA row 04
    R   ___                                     ; 63EB row 05
    R   ___                                     ; 63EC row 06
    R   ___                                     ; 63ED row 07
    R   ___                                     ; 63EE row 08
    R   ___                                     ; 63EF row 09
    R   ___                                     ; 63F0 row 10
    R   ___                                     ; 63F1 row 11
    R   ___                                     ; 63F2 row 12
    R   ___                                     ; 63F3 row 13
    R   ___                                     ; 63F4 row 14
    R   ___                                     ; 63F5 row 15
    RI  Fs2, 2, 0                               ; 63F6 row 16  Inst01
    R   ___                                     ; 63F8 row 17
    R   ___                                     ; 63F9 row 18
    R   ___                                     ; 63FA row 19
    R   ___                                     ; 63FB row 20
    R   ___                                     ; 63FC row 21
    R   ___                                     ; 63FD row 22
    R   ___                                     ; 63FE row 23
    RI  C_3, 2, 0                               ; 63FF row 24  Inst01
    R   ___                                     ; 6401 row 25
    RI  ___, 0, 2                               ; 6402 row 26
    R   ___                                     ; 6404 row 27
    RI  ___, 0, 1                               ; 6405 row 28
    R   ___                                     ; 6407 row 29
    RI  C_3, 25, 0                              ; 6408 row 30  Inst24
    R   ___                                     ; 640A row 31
Track080:
    RIF Cs5, 16, 0, $F, $F                      ; 640B row 00  Inst15  speed 15
    R   ___                                     ; 640E row 01
    RI  Cs5, 16, 0                              ; 640F row 02  Inst15
    R   ___                                     ; 6411 row 03
    RI  Gs4, 16, 0                              ; 6412 row 04  Inst15
    R   ___                                     ; 6414 row 05
    RI  Gs4, 16, 0                              ; 6415 row 06  Inst15
    R   ___                                     ; 6417 row 07
    RI  Cs5, 16, 0                              ; 6418 row 08  Inst15
    R   ___                                     ; 641A row 09
    RI  Cs5, 16, 0                              ; 641B row 10  Inst15
    R   ___                                     ; 641D row 11
    RI  Gs4, 16, 0                              ; 641E row 12  Inst15
    R   ___                                     ; 6420 row 13
    RI  Gs4, 16, 0                              ; 6421 row 14  Inst15
    R   ___                                     ; 6423 row 15
    RI  G_4, 16, 0                              ; 6424 row 16  Inst15
    R   ___                                     ; 6426 row 17
    RI  G_4, 16, 0                              ; 6427 row 18  Inst15
    R   ___                                     ; 6429 row 19
    RI  D_4, 16, 0                              ; 642A row 20  Inst15
    R   ___                                     ; 642C row 21
    RI  D_4, 16, 0                              ; 642D row 22  Inst15
    R   ___                                     ; 642F row 23
    RI  G_4, 16, 0                              ; 6430 row 24  Inst15
    R   ___                                     ; 6432 row 25
    RI  G_4, 16, 0                              ; 6433 row 26  Inst15
    R   ___                                     ; 6435 row 27
    RI  D_4, 16, 0                              ; 6436 row 28  Inst15
    R   ___                                     ; 6438 row 29
    RI  D_4, 16, 0                              ; 6439 row 30  Inst15
    R   ___                                     ; 643B row 31
Track081:
    R   ___                                     ; 643C row 00
    RI  A_4, 16, 0                              ; 643D row 01  Inst15
    R   ___                                     ; 643F row 02
    RI  A_4, 16, 0                              ; 6440 row 03  Inst15
    R   ___                                     ; 6442 row 04
    RI  E_4, 16, 0                              ; 6443 row 05  Inst15
    R   ___                                     ; 6445 row 06
    RI  E_4, 16, 0                              ; 6446 row 07  Inst15
    R   ___                                     ; 6448 row 08
    RI  A_4, 16, 0                              ; 6449 row 09  Inst15
    R   ___                                     ; 644B row 10
    RI  A_4, 16, 0                              ; 644C row 11  Inst15
    R   ___                                     ; 644E row 12
    RI  E_4, 16, 0                              ; 644F row 13  Inst15
    R   ___                                     ; 6451 row 14
    RI  E_4, 16, 0                              ; 6452 row 15  Inst15
    R   ___                                     ; 6454 row 16
    RI  Ds4, 16, 0                              ; 6455 row 17  Inst15
    R   ___                                     ; 6457 row 18
    RI  Ds4, 16, 0                              ; 6458 row 19  Inst15
    R   ___                                     ; 645A row 20
    RI  As3, 16, 0                              ; 645B row 21  Inst15
    R   ___                                     ; 645D row 22
    RI  As3, 16, 0                              ; 645E row 23  Inst15
    R   ___                                     ; 6460 row 24
    RI  Ds4, 16, 0                              ; 6461 row 25  Inst15
    R   ___                                     ; 6463 row 26
    RI  Ds4, 16, 0                              ; 6464 row 27  Inst15
    R   ___                                     ; 6466 row 28
    RI  As3, 16, 0                              ; 6467 row 29  Inst15
    R   ___                                     ; 6469 row 30
    RI  As3, 16, 0                              ; 646A row 31  Inst15
Track082:
    RI  Fs2, 10, 0                              ; 646C row 00  Inst09
    R   ___                                     ; 646E row 01
    R   ___                                     ; 646F row 02
    R   ___                                     ; 6470 row 03
    RI  Cs2, 10, 0                              ; 6471 row 04  Inst09
    R   ___                                     ; 6473 row 05
    R   ___                                     ; 6474 row 06
    R   ___                                     ; 6475 row 07
    RI  Fs2, 10, 0                              ; 6476 row 08  Inst09
    R   ___                                     ; 6478 row 09
    R   ___                                     ; 6479 row 10
    R   ___                                     ; 647A row 11
    RI  Cs2, 10, 0                              ; 647B row 12  Inst09
    R   ___                                     ; 647D row 13
    R   ___                                     ; 647E row 14
    R   ___                                     ; 647F row 15
    RI  C_3, 10, 0                              ; 6480 row 16  Inst09
    R   ___                                     ; 6482 row 17
    R   ___                                     ; 6483 row 18
    R   ___                                     ; 6484 row 19
    RI  G_2, 10, 0                              ; 6485 row 20  Inst09
    R   ___                                     ; 6487 row 21
    R   ___                                     ; 6488 row 22
    R   ___                                     ; 6489 row 23
    RI  C_3, 10, 0                              ; 648A row 24  Inst09
    R   ___                                     ; 648C row 25
    R   ___                                     ; 648D row 26
    R   ___                                     ; 648E row 27
    RI  G_2, 10, 0                              ; 648F row 28  Inst09
    R   ___                                     ; 6491 row 29
    R   ___                                     ; 6492 row 30
    R   ___                                     ; 6493 row 31
Track083:
    RI  C_3, 11, 0                              ; 6494 row 00  Inst10
    RI  C_3, 11, 1                              ; 6496 row 01  Inst10
    RI  C_3, 11, 0                              ; 6498 row 02  Inst10
    RI  C_3, 11, 1                              ; 649A row 03  Inst10
    RI  C_3, 11, 0                              ; 649C row 04  Inst10
    RI  C_3, 11, 1                              ; 649E row 05  Inst10
    RI  C_3, 11, 0                              ; 64A0 row 06  Inst10
    RI  C_3, 11, 1                              ; 64A2 row 07  Inst10
    RI  C_3, 11, 0                              ; 64A4 row 08  Inst10
    RI  C_3, 11, 1                              ; 64A6 row 09  Inst10
    RI  C_3, 11, 0                              ; 64A8 row 10  Inst10
    RI  C_3, 11, 1                              ; 64AA row 11  Inst10
    RI  C_3, 11, 0                              ; 64AC row 12  Inst10
    RI  C_3, 11, 1                              ; 64AE row 13  Inst10
    RI  C_3, 11, 0                              ; 64B0 row 14  Inst10
    RI  C_3, 11, 1                              ; 64B2 row 15  Inst10
    RI  C_3, 11, 0                              ; 64B4 row 16  Inst10
    RI  C_3, 11, 1                              ; 64B6 row 17  Inst10
    RI  C_3, 11, 0                              ; 64B8 row 18  Inst10
    RI  C_3, 11, 1                              ; 64BA row 19  Inst10
    RI  C_3, 11, 0                              ; 64BC row 20  Inst10
    RI  C_3, 11, 1                              ; 64BE row 21  Inst10
    RI  C_3, 11, 0                              ; 64C0 row 22  Inst10
    RI  C_3, 11, 1                              ; 64C2 row 23  Inst10
    RI  C_3, 11, 0                              ; 64C4 row 24  Inst10
    RI  C_3, 11, 1                              ; 64C6 row 25  Inst10
    RI  C_3, 11, 0                              ; 64C8 row 26  Inst10
    RI  C_3, 11, 1                              ; 64CA row 27  Inst10
    RI  C_3, 11, 0                              ; 64CC row 28  Inst10
    RI  C_3, 11, 1                              ; 64CE row 29  Inst10
    RI  C_3, 11, 0                              ; 64D0 row 30  Inst10
    RI  C_3, 11, 1                              ; 64D2 row 31  Inst10
Track084:
    RI  Cs4, 16, 0                              ; 64D4 row 00  Inst15
    R   ___                                     ; 64D6 row 01
    RI  Cs4, 16, 0                              ; 64D7 row 02  Inst15
    R   ___                                     ; 64D9 row 03
    RI  Gs3, 16, 0                              ; 64DA row 04  Inst15
    R   ___                                     ; 64DC row 05
    RI  Gs3, 16, 0                              ; 64DD row 06  Inst15
    R   ___                                     ; 64DF row 07
    RI  Cs4, 16, 0                              ; 64E0 row 08  Inst15
    R   ___                                     ; 64E2 row 09
    RI  Cs4, 16, 0                              ; 64E3 row 10  Inst15
    R   ___                                     ; 64E5 row 11
    RI  Gs3, 16, 0                              ; 64E6 row 12  Inst15
    R   ___                                     ; 64E8 row 13
    RI  Gs3, 16, 0                              ; 64E9 row 14  Inst15
    R   ___                                     ; 64EB row 15
    RI  Gs3, 16, 0                              ; 64EC row 16  Inst15
    R   ___                                     ; 64EE row 17
    RI  Gs3, 16, 1                              ; 64EF row 18  Inst15
    R   ___                                     ; 64F1 row 19
    RI  Gs3, 16, 2                              ; 64F2 row 20  Inst15
    R   ___                                     ; 64F4 row 21
    R   ___                                     ; 64F5 row 22
    R   ___                                     ; 64F6 row 23
    R   ___                                     ; 64F7 row 24
    R   ___                                     ; 64F8 row 25
    R   ___                                     ; 64F9 row 26
    R   ___                                     ; 64FA row 27
    R   ___                                     ; 64FB row 28
    R   ___                                     ; 64FC row 29
    R   ___                                     ; 64FD row 30
    R   ___                                     ; 64FE row 31
Track085:
    R   ___                                     ; 64FF row 00
    RI  A_3, 16, 0                              ; 6500 row 01  Inst15
    R   ___                                     ; 6502 row 02
    RI  A_3, 16, 0                              ; 6503 row 03  Inst15
    R   ___                                     ; 6505 row 04
    RI  E_3, 16, 0                              ; 6506 row 05  Inst15
    R   ___                                     ; 6508 row 06
    RI  E_3, 16, 0                              ; 6509 row 07  Inst15
    R   ___                                     ; 650B row 08
    RI  A_3, 16, 0                              ; 650C row 09  Inst15
    R   ___                                     ; 650E row 10
    RI  A_3, 16, 0                              ; 650F row 11  Inst15
    R   ___                                     ; 6511 row 12
    RI  E_3, 16, 0                              ; 6512 row 13  Inst15
    R   ___                                     ; 6514 row 14
    RI  E_3, 16, 0                              ; 6515 row 15  Inst15
    R   ___                                     ; 6517 row 16
    RI  E_3, 16, 0                              ; 6518 row 17  Inst15
    R   ___                                     ; 651A row 18
    RI  E_3, 16, 1                              ; 651B row 19  Inst15
    R   ___                                     ; 651D row 20
    RI  E_3, 16, 2                              ; 651E row 21  Inst15
    R   ___                                     ; 6520 row 22
    R   ___                                     ; 6521 row 23
    R   ___                                     ; 6522 row 24
    R   ___                                     ; 6523 row 25
    R   ___                                     ; 6524 row 26
    R   ___                                     ; 6525 row 27
    R   ___                                     ; 6526 row 28
    R   ___                                     ; 6527 row 29
    R   ___                                     ; 6528 row 30
    R   ___                                     ; 6529 row 31
Track086:
    RI  Fs2, 10, 0                              ; 652A row 00  Inst09
    R   ___                                     ; 652C row 01
    R   ___                                     ; 652D row 02
    R   ___                                     ; 652E row 03
    RI  Cs2, 10, 0                              ; 652F row 04  Inst09
    R   ___                                     ; 6531 row 05
    R   ___                                     ; 6532 row 06
    R   ___                                     ; 6533 row 07
    RI  Fs2, 10, 0                              ; 6534 row 08  Inst09
    R   ___                                     ; 6536 row 09
    R   ___                                     ; 6537 row 10
    R   ___                                     ; 6538 row 11
    RI  Cs2, 10, 0                              ; 6539 row 12  Inst09
    R   ___                                     ; 653B row 13
    R   ___                                     ; 653C row 14
    R   ___                                     ; 653D row 15
    RI  Cs3, 2, 0                               ; 653E row 16  Inst01
    R   ___                                     ; 6540 row 17
    RI  ___, 0, 2                               ; 6541 row 18
    R   ___                                     ; 6543 row 19
    RI  ___, 0, 1                               ; 6544 row 20
    RI  C_3, 25, 0                              ; 6546 row 21  Inst24
    R   ___                                     ; 6548 row 22
    R   ___                                     ; 6549 row 23
    R   ___                                     ; 654A row 24
    R   ___                                     ; 654B row 25
    R   ___                                     ; 654C row 26
    R   ___                                     ; 654D row 27
    R   ___                                     ; 654E row 28
    R   ___                                     ; 654F row 29
    R   ___                                     ; 6550 row 30
    R   ___                                     ; 6551 row 31
Track087:
    RI  C_3, 11, 0                              ; 6552 row 00  Inst10
    RI  C_3, 11, 1                              ; 6554 row 01  Inst10
    RI  C_3, 11, 0                              ; 6556 row 02  Inst10
    RI  C_3, 11, 1                              ; 6558 row 03  Inst10
    RI  C_3, 11, 0                              ; 655A row 04  Inst10
    RI  C_3, 11, 1                              ; 655C row 05  Inst10
    RI  C_3, 11, 0                              ; 655E row 06  Inst10
    RI  C_3, 11, 1                              ; 6560 row 07  Inst10
    RI  C_3, 11, 0                              ; 6562 row 08  Inst10
    RI  C_3, 11, 1                              ; 6564 row 09  Inst10
    RI  C_3, 11, 0                              ; 6566 row 10  Inst10
    RI  C_3, 11, 1                              ; 6568 row 11  Inst10
    RI  C_3, 11, 0                              ; 656A row 12  Inst10
    RI  C_3, 11, 1                              ; 656C row 13  Inst10
    RI  C_3, 11, 0                              ; 656E row 14  Inst10
    RI  C_3, 11, 1                              ; 6570 row 15  Inst10
    RI  C_3, 23, 0                              ; 6572 row 16  Inst22
    R   ___                                     ; 6574 row 17
    R   ___                                     ; 6575 row 18
    R   ___                                     ; 6576 row 19
    R   ___                                     ; 6577 row 20
    R   ___                                     ; 6578 row 21
    R   ___                                     ; 6579 row 22
    R   ___                                     ; 657A row 23
    R   ___                                     ; 657B row 24
    R   ___                                     ; 657C row 25
    R   ___                                     ; 657D row 26
    R   ___                                     ; 657E row 27
    R   ___                                     ; 657F row 28
    R   ___                                     ; 6580 row 29
    R   ___                                     ; 6581 row 30
    R   ___                                     ; 6582 row 31
Track088:
    RI  F_4, 16, 0                              ; 6583 row 00  Inst15
    R   ___                                     ; 6585 row 01
    R   ___                                     ; 6586 row 02
    R   ___                                     ; 6587 row 03
    RI  C_4, 16, 0                              ; 6588 row 04  Inst15
    R   ___                                     ; 658A row 05
    RI  F_3, 16, 0                              ; 658B row 06  Inst15
    R   ___                                     ; 658D row 07
    RI  F_4, 16, 0                              ; 658E row 08  Inst15
    R   ___                                     ; 6590 row 09
    R   ___                                     ; 6591 row 10
    R   ___                                     ; 6592 row 11
    RI  C_4, 16, 0                              ; 6593 row 12  Inst15
    R   ___                                     ; 6595 row 13
    RI  F_3, 16, 0                              ; 6596 row 14  Inst15
    R   ___                                     ; 6598 row 15
    RI  Ds4, 16, 0                              ; 6599 row 16  Inst15
    R   ___                                     ; 659B row 17
    R   ___                                     ; 659C row 18
    R   ___                                     ; 659D row 19
    RI  D_4, 16, 0                              ; 659E row 20  Inst15
    R   ___                                     ; 65A0 row 21
    RI  C_4, 16, 0                              ; 65A1 row 22  Inst15
    R   ___                                     ; 65A3 row 23
    RI  Ds4, 16, 0                              ; 65A4 row 24  Inst15
    R   ___                                     ; 65A6 row 25
    R   ___                                     ; 65A7 row 26
    R   ___                                     ; 65A8 row 27
    RI  D_4, 16, 0                              ; 65A9 row 28  Inst15
    R   ___                                     ; 65AB row 29
    RI  Ds4, 16, 0                              ; 65AC row 30  Inst15
    R   ___                                     ; 65AE row 31
Track089:
    RI  A_3, 18, 0                              ; 65AF row 00  Inst17
    R   ___                                     ; 65B1 row 01
    R   ___                                     ; 65B2 row 02
    R   ___                                     ; 65B3 row 03
    R   ___                                     ; 65B4 row 04
    R   ___                                     ; 65B5 row 05
    R   ___                                     ; 65B6 row 06
    R   ___                                     ; 65B7 row 07
    RI  A_3, 18, 0                              ; 65B8 row 08  Inst17
    R   ___                                     ; 65BA row 09
    R   ___                                     ; 65BB row 10
    R   ___                                     ; 65BC row 11
    R   ___                                     ; 65BD row 12
    R   ___                                     ; 65BE row 13
    R   ___                                     ; 65BF row 14
    R   ___                                     ; 65C0 row 15
    RI  G_3, 18, 0                              ; 65C1 row 16  Inst17
    R   ___                                     ; 65C3 row 17
    R   ___                                     ; 65C4 row 18
    R   ___                                     ; 65C5 row 19
    R   ___                                     ; 65C6 row 20
    R   ___                                     ; 65C7 row 21
    R   ___                                     ; 65C8 row 22
    R   ___                                     ; 65C9 row 23
    RI  G_3, 18, 0                              ; 65CA row 24  Inst17
    R   ___                                     ; 65CC row 25
    R   ___                                     ; 65CD row 26
    R   ___                                     ; 65CE row 27
    R   ___                                     ; 65CF row 28
    R   ___                                     ; 65D0 row 29
    R   ___                                     ; 65D1 row 30
    R   ___                                     ; 65D2 row 31
Track090:
    RIF C_3, 11, 0, $F, $5                      ; 65D3 row 00  Inst10  speed 5
    R   ___                                     ; 65D6 row 01
    R   ___                                     ; 65D7 row 02
    R   ___                                     ; 65D8 row 03
    RF  ___, $F, $A                             ; 65D9 row 04  speed 10
    R   ___                                     ; 65DB row 05
    RI  C_3, 11, 0                              ; 65DC row 06  Inst10
    R   ___                                     ; 65DE row 07
    RIF C_4, 9, 0, $F, $5                       ; 65DF row 08  Inst08  speed 5
    R   ___                                     ; 65E2 row 09
    R   ___                                     ; 65E3 row 10
    R   ___                                     ; 65E4 row 11
    RF  ___, $F, $A                             ; 65E5 row 12  speed 10
    R   ___                                     ; 65E7 row 13
    RI  C_3, 11, 0                              ; 65E8 row 14  Inst10
    R   ___                                     ; 65EA row 15
    RIF C_3, 11, 0, $F, $5                      ; 65EB row 16  Inst10  speed 5
    R   ___                                     ; 65EE row 17
    R   ___                                     ; 65EF row 18
    R   ___                                     ; 65F0 row 19
    RF  ___, $F, $A                             ; 65F1 row 20  speed 10
    R   ___                                     ; 65F3 row 21
    RI  C_3, 11, 0                              ; 65F4 row 22  Inst10
    R   ___                                     ; 65F6 row 23
    RIF C_3, 9, 0, $F, $5                       ; 65F7 row 24  Inst08  speed 5
    R   ___                                     ; 65FA row 25
    R   ___                                     ; 65FB row 26
    R   ___                                     ; 65FC row 27
    RIF C_4, 11, 0, $F, $A                      ; 65FD row 28  Inst10  speed 10
    R   ___                                     ; 6600 row 29
    RI  C_4, 11, 0                              ; 6601 row 30  Inst10
    R   ___                                     ; 6603 row 31
Track091:
    RI  F_3, 4, 0                               ; 6604 row 00  Inst03
    R   ___                                     ; 6606 row 01
    R   ___                                     ; 6607 row 02
    R   ___                                     ; 6608 row 03
    R   ___                                     ; 6609 row 04
    R   ___                                     ; 660A row 05
    R   ___                                     ; 660B row 06
    R   ___                                     ; 660C row 07
    R   ___                                     ; 660D row 08
    R   ___                                     ; 660E row 09
    R   ___                                     ; 660F row 10
    R   ___                                     ; 6610 row 11
    R   ___                                     ; 6611 row 12
    R   ___                                     ; 6612 row 13
    R   ___                                     ; 6613 row 14
    R   ___                                     ; 6614 row 15
    R   ___                                     ; 6615 row 16
    R   ___                                     ; 6616 row 17
    R   ___                                     ; 6617 row 18
    R   ___                                     ; 6618 row 19
    R   ___                                     ; 6619 row 20
    R   ___                                     ; 661A row 21
    R   ___                                     ; 661B row 22
    R   ___                                     ; 661C row 23
    R   ___                                     ; 661D row 24
    R   ___                                     ; 661E row 25
    R   ___                                     ; 661F row 26
    R   ___                                     ; 6620 row 27
    R   ___                                     ; 6621 row 28
    R   ___                                     ; 6622 row 29
    R   ___                                     ; 6623 row 30
    R   ___                                     ; 6624 row 31
Track092:
    RI  A_3, 18, 0                              ; 6625 row 00  Inst17
    R   ___                                     ; 6627 row 01
    R   ___                                     ; 6628 row 02
    R   ___                                     ; 6629 row 03
    R   ___                                     ; 662A row 04
    R   ___                                     ; 662B row 05
    R   ___                                     ; 662C row 06
    R   ___                                     ; 662D row 07
    R   ___                                     ; 662E row 08
    R   ___                                     ; 662F row 09
    R   ___                                     ; 6630 row 10
    R   ___                                     ; 6631 row 11
    R   ___                                     ; 6632 row 12
    R   ___                                     ; 6633 row 13
    R   ___                                     ; 6634 row 14
    R   ___                                     ; 6635 row 15
    R   ___                                     ; 6636 row 16
    R   ___                                     ; 6637 row 17
    R   ___                                     ; 6638 row 18
    R   ___                                     ; 6639 row 19
    R   ___                                     ; 663A row 20
    R   ___                                     ; 663B row 21
    R   ___                                     ; 663C row 22
    R   ___                                     ; 663D row 23
    R   ___                                     ; 663E row 24
    R   ___                                     ; 663F row 25
    R   ___                                     ; 6640 row 26
    R   ___                                     ; 6641 row 27
    R   ___                                     ; 6642 row 28
    R   ___                                     ; 6643 row 29
    R   ___                                     ; 6644 row 30
    R   ___                                     ; 6645 row 31
Track093:
    RI  F_2, 10, 0                              ; 6646 row 00  Inst09
    R   ___                                     ; 6648 row 01
    R   ___                                     ; 6649 row 02
    R   ___                                     ; 664A row 03
    R   ___                                     ; 664B row 04
    R   ___                                     ; 664C row 05
    RI  F_2, 10, 0                              ; 664D row 06  Inst09
    R   ___                                     ; 664F row 07
    RI  F_2, 10, 0                              ; 6650 row 08  Inst09
    R   ___                                     ; 6652 row 09
    R   ___                                     ; 6653 row 10
    R   ___                                     ; 6654 row 11
    R   ___                                     ; 6655 row 12
    R   ___                                     ; 6656 row 13
    RI  F_2, 10, 0                              ; 6657 row 14  Inst09
    R   ___                                     ; 6659 row 15
    RI  C_3, 10, 0                              ; 665A row 16  Inst09
    R   ___                                     ; 665C row 17
    R   ___                                     ; 665D row 18
    R   ___                                     ; 665E row 19
    R   ___                                     ; 665F row 20
    R   ___                                     ; 6660 row 21
    RI  C_3, 10, 0                              ; 6661 row 22  Inst09
    R   ___                                     ; 6663 row 23
    RI  C_3, 10, 0                              ; 6664 row 24  Inst09
    R   ___                                     ; 6666 row 25
    R   ___                                     ; 6667 row 26
    R   ___                                     ; 6668 row 27
    RI  D_2, 10, 0                              ; 6669 row 28  Inst09
    R   ___                                     ; 666B row 29
    RI  Ds2, 10, 0                              ; 666C row 30  Inst09
    R   ___                                     ; 666E row 31
Track094:
    RI  F_2, 10, 0                              ; 666F row 00  Inst09
    R   ___                                     ; 6671 row 01
    RI  ___, 0, 2                               ; 6672 row 02
    R   ___                                     ; 6674 row 03
    RI  ___, 0, 1                               ; 6675 row 04
    R   ___                                     ; 6677 row 05
    RI  C_4, 25, 0                              ; 6678 row 06  Inst24
    R   ___                                     ; 667A row 07
    R   ___                                     ; 667B row 08
    R   ___                                     ; 667C row 09
    R   ___                                     ; 667D row 10
    R   ___                                     ; 667E row 11
    R   ___                                     ; 667F row 12
    R   ___                                     ; 6680 row 13
    R   ___                                     ; 6681 row 14
    R   ___                                     ; 6682 row 15
    R   ___                                     ; 6683 row 16
    R   ___                                     ; 6684 row 17
    R   ___                                     ; 6685 row 18
    R   ___                                     ; 6686 row 19
    R   ___                                     ; 6687 row 20
    R   ___                                     ; 6688 row 21
    R   ___                                     ; 6689 row 22
    R   ___                                     ; 668A row 23
    R   ___                                     ; 668B row 24
    R   ___                                     ; 668C row 25
    R   ___                                     ; 668D row 26
    R   ___                                     ; 668E row 27
    R   ___                                     ; 668F row 28
    R   ___                                     ; 6690 row 29
    R   ___                                     ; 6691 row 30
    R   ___                                     ; 6692 row 31
Track095:
    RI  C_3, 12, 0                              ; 6693 row 00  Inst11
    R   ___                                     ; 6695 row 01
    R   ___                                     ; 6696 row 02
    R   ___                                     ; 6697 row 03
    R   ___                                     ; 6698 row 04
    R   ___                                     ; 6699 row 05
    R   ___                                     ; 669A row 06
    R   ___                                     ; 669B row 07
    R   ___                                     ; 669C row 08
    R   ___                                     ; 669D row 09
    R   ___                                     ; 669E row 10
    R   ___                                     ; 669F row 11
    R   ___                                     ; 66A0 row 12
    R   ___                                     ; 66A1 row 13
    R   ___                                     ; 66A2 row 14
    R   ___                                     ; 66A3 row 15
    R   ___                                     ; 66A4 row 16
    R   ___                                     ; 66A5 row 17
    R   ___                                     ; 66A6 row 18
    R   ___                                     ; 66A7 row 19
    R   ___                                     ; 66A8 row 20
    R   ___                                     ; 66A9 row 21
    R   ___                                     ; 66AA row 22
    R   ___                                     ; 66AB row 23
    R   ___                                     ; 66AC row 24
    R   ___                                     ; 66AD row 25
    R   ___                                     ; 66AE row 26
    R   ___                                     ; 66AF row 27
    R   ___                                     ; 66B0 row 28
    R   ___                                     ; 66B1 row 29
    R   ___                                     ; 66B2 row 30
    R   ___                                     ; 66B3 row 31
Track096:
    RI  C_2, 29, 0                              ; 66B4 row 00  Inst28
    R   ___                                     ; 66B6 row 01
    R   ___                                     ; 66B7 row 02
    R   ___                                     ; 66B8 row 03
    R   ___                                     ; 66B9 row 04
    R   ___                                     ; 66BA row 05
    R   ___                                     ; 66BB row 06
    R   ___                                     ; 66BC row 07
    R   ___                                     ; 66BD row 08
    R   ___                                     ; 66BE row 09
    R   ___                                     ; 66BF row 10
    R   ___                                     ; 66C0 row 11
    R   ___                                     ; 66C1 row 12
    R   ___                                     ; 66C2 row 13
    R   ___                                     ; 66C3 row 14
    R   ___                                     ; 66C4 row 15
    RI  Fs2, 29, 0                              ; 66C5 row 16  Inst28
    R   ___                                     ; 66C7 row 17
    R   ___                                     ; 66C8 row 18
    R   ___                                     ; 66C9 row 19
    R   ___                                     ; 66CA row 20
    R   ___                                     ; 66CB row 21
    R   ___                                     ; 66CC row 22
    R   ___                                     ; 66CD row 23
    R   ___                                     ; 66CE row 24
    R   ___                                     ; 66CF row 25
    R   ___                                     ; 66D0 row 26
    R   ___                                     ; 66D1 row 27
    R   ___                                     ; 66D2 row 28
    R   ___                                     ; 66D3 row 29
    R   ___                                     ; 66D4 row 30
    R   ___                                     ; 66D5 row 31
Track097:
    RIF C_3, 27, 0, $F, $E                      ; 66D6 row 00  Inst26  speed 14
    R   ___                                     ; 66D9 row 01
    R   ___                                     ; 66DA row 02
    R   ___                                     ; 66DB row 03
    RI  C_3, 27, 0                              ; 66DC row 04  Inst26
    R   ___                                     ; 66DE row 05
    R   ___                                     ; 66DF row 06
    R   ___                                     ; 66E0 row 07
    RI  C_3, 27, 0                              ; 66E1 row 08  Inst26
    R   ___                                     ; 66E3 row 09
    R   ___                                     ; 66E4 row 10
    R   ___                                     ; 66E5 row 11
    RI  C_3, 27, 0                              ; 66E6 row 12  Inst26
    R   ___                                     ; 66E8 row 13
    R   ___                                     ; 66E9 row 14
    R   ___                                     ; 66EA row 15
    RI  C_3, 28, 0                              ; 66EB row 16  Inst27
    R   ___                                     ; 66ED row 17
    R   ___                                     ; 66EE row 18
    R   ___                                     ; 66EF row 19
    RI  C_3, 28, 0                              ; 66F0 row 20  Inst27
    R   ___                                     ; 66F2 row 21
    R   ___                                     ; 66F3 row 22
    R   ___                                     ; 66F4 row 23
    RI  C_3, 28, 0                              ; 66F5 row 24  Inst27
    R   ___                                     ; 66F7 row 25
    R   ___                                     ; 66F8 row 26
    R   ___                                     ; 66F9 row 27
    RI  C_3, 28, 0                              ; 66FA row 28  Inst27
    R   ___                                     ; 66FC row 29
    R   ___                                     ; 66FD row 30
    R   ___                                     ; 66FE row 31
Track098:
    RI  C_3, 10, 0                              ; 66FF row 00  Inst09
    R   ___                                     ; 6701 row 01
    R   ___                                     ; 6702 row 02
    R   ___                                     ; 6703 row 03
    R   ___                                     ; 6704 row 04
    R   ___                                     ; 6705 row 05
    R   ___                                     ; 6706 row 06
    R   ___                                     ; 6707 row 07
    R   ___                                     ; 6708 row 08
    R   ___                                     ; 6709 row 09
    R   ___                                     ; 670A row 10
    R   ___                                     ; 670B row 11
    R   ___                                     ; 670C row 12
    R   ___                                     ; 670D row 13
    R   ___                                     ; 670E row 14
    R   ___                                     ; 670F row 15
    RI  Fs3, 10, 0                              ; 6710 row 16  Inst09
    R   ___                                     ; 6712 row 17
    R   ___                                     ; 6713 row 18
    R   ___                                     ; 6714 row 19
    R   ___                                     ; 6715 row 20
    R   ___                                     ; 6716 row 21
    R   ___                                     ; 6717 row 22
    R   ___                                     ; 6718 row 23
    R   ___                                     ; 6719 row 24
    R   ___                                     ; 671A row 25
    R   ___                                     ; 671B row 26
    R   ___                                     ; 671C row 27
    R   ___                                     ; 671D row 28
    R   ___                                     ; 671E row 29
    R   ___                                     ; 671F row 30
    R   ___                                     ; 6720 row 31
Track099:
    RI  C_2, 29, 0                              ; 6721 row 00  Inst28
    R   ___                                     ; 6723 row 01
    R   ___                                     ; 6724 row 02
    R   ___                                     ; 6725 row 03
    R   ___                                     ; 6726 row 04
    R   ___                                     ; 6727 row 05
    R   ___                                     ; 6728 row 06
    R   ___                                     ; 6729 row 07
    R   ___                                     ; 672A row 08
    R   ___                                     ; 672B row 09
    R   ___                                     ; 672C row 10
    R   ___                                     ; 672D row 11
    RI  C_2, 31, 0                              ; 672E row 12  Inst30
    R   ___                                     ; 6730 row 13
    R   ___                                     ; 6731 row 14
    R   ___                                     ; 6732 row 15
    R   ___                                     ; 6733 row 16
    R   ___                                     ; 6734 row 17
    R   ___                                     ; 6735 row 18
    R   ___                                     ; 6736 row 19
    R   ___                                     ; 6737 row 20
    R   ___                                     ; 6738 row 21
    R   ___                                     ; 6739 row 22
    R   ___                                     ; 673A row 23
    R   ___                                     ; 673B row 24
    R   ___                                     ; 673C row 25
    R   ___                                     ; 673D row 26
    R   ___                                     ; 673E row 27
    R   ___                                     ; 673F row 28
    R   ___                                     ; 6740 row 29
    R   ___                                     ; 6741 row 30
    R   ___                                     ; 6742 row 31
Track100:
    RIF C_3, 27, 0, $F, $F                      ; 6743 row 00  Inst26  speed 15
    R   ___                                     ; 6746 row 01
    R   ___                                     ; 6747 row 02
    R   ___                                     ; 6748 row 03
    RI  C_3, 27, 0                              ; 6749 row 04  Inst26
    R   ___                                     ; 674B row 05
    R   ___                                     ; 674C row 06
    R   ___                                     ; 674D row 07
    RI  C_3, 27, 0                              ; 674E row 08  Inst26
    R   ___                                     ; 6750 row 09
    R   ___                                     ; 6751 row 10
    R   ___                                     ; 6752 row 11
    RI  C_3, 27, 0                              ; 6753 row 12  Inst26
    R   ___                                     ; 6755 row 13
    R   ___                                     ; 6756 row 14
    R   ___                                     ; 6757 row 15
    R   ___                                     ; 6758 row 16
    R   ___                                     ; 6759 row 17
    R   ___                                     ; 675A row 18
    R   ___                                     ; 675B row 19
    R   ___                                     ; 675C row 20
    R   ___                                     ; 675D row 21
    R   ___                                     ; 675E row 22
    R   ___                                     ; 675F row 23
    R   ___                                     ; 6760 row 24
    R   ___                                     ; 6761 row 25
    R   ___                                     ; 6762 row 26
    R   ___                                     ; 6763 row 27
    R   ___                                     ; 6764 row 28
    R   ___                                     ; 6765 row 29
    R   ___                                     ; 6766 row 30
    R   ___                                     ; 6767 row 31
Track101:
    RI  C_3, 10, 0                              ; 6768 row 00  Inst09
    R   ___                                     ; 676A row 01
    R   ___                                     ; 676B row 02
    R   ___                                     ; 676C row 03
    R   ___                                     ; 676D row 04
    R   ___                                     ; 676E row 05
    R   ___                                     ; 676F row 06
    R   ___                                     ; 6770 row 07
    R   ___                                     ; 6771 row 08
    R   ___                                     ; 6772 row 09
    R   ___                                     ; 6773 row 10
    R   ___                                     ; 6774 row 11
    R   ___                                     ; 6775 row 12
    RI  ___, 0, 2                               ; 6776 row 13
    R   ___                                     ; 6778 row 14
    RI  ___, 0, 1                               ; 6779 row 15
    R   ___                                     ; 677B row 16
    RI  C_3, 25, 0                              ; 677C row 17  Inst24
    R   ___                                     ; 677E row 18
    R   ___                                     ; 677F row 19
    R   ___                                     ; 6780 row 20
    R   ___                                     ; 6781 row 21
    R   ___                                     ; 6782 row 22
    R   ___                                     ; 6783 row 23
    R   ___                                     ; 6784 row 24
    R   ___                                     ; 6785 row 25
    R   ___                                     ; 6786 row 26
    R   ___                                     ; 6787 row 27
    R   ___                                     ; 6788 row 28
    R   ___                                     ; 6789 row 29
    R   ___                                     ; 678A row 30
    R   ___                                     ; 678B row 31
Track102:
    RIF G_2, 10, 0, $F, $6                      ; 678C row 00  Inst09  speed 6
    R   ___                                     ; 678F row 01
    RI  G_2, 10, 0                              ; 6790 row 02  Inst09
    R   ___                                     ; 6792 row 03
    RI  G_2, 10, 0                              ; 6793 row 04  Inst09
    R   ___                                     ; 6795 row 05
    R   ___                                     ; 6796 row 06
    RI  ___, 0, 0                               ; 6797 row 07
    RI  C_3, 8, 0                               ; 6799 row 08  Inst07
    R   ___                                     ; 679B row 09
    R   ___                                     ; 679C row 10
    R   ___                                     ; 679D row 11
    RI  F_2, 10, 0                              ; 679E row 12  Inst09
    R   ___                                     ; 67A0 row 13
    RI  G_2, 10, 0                              ; 67A1 row 14  Inst09
    R   ___                                     ; 67A3 row 15
    R   ___                                     ; 67A4 row 16
    RI  ___, 0, 0                               ; 67A5 row 17
    RI  G_2, 10, 0                              ; 67A7 row 18  Inst09
    R   ___                                     ; 67A9 row 19
    RI  G_3, 10, 0                              ; 67AA row 20  Inst09
    RI  ___, 0, 0                               ; 67AC row 21
    RI  G_2, 10, 0                              ; 67AE row 22  Inst09
    RI  ___, 0, 0                               ; 67B0 row 23
    RI  C_3, 8, 0                               ; 67B2 row 24  Inst07
    R   ___                                     ; 67B4 row 25
    R   ___                                     ; 67B5 row 26
    R   ___                                     ; 67B6 row 27
    RI  G_3, 10, 0                              ; 67B7 row 28  Inst09
    R   ___                                     ; 67B9 row 29
    RI  C_3, 8, 0                               ; 67BA row 30  Inst07
    R   ___                                     ; 67BC row 31
Track103:
    RI  C_3, 11, 0                              ; 67BD row 00  Inst10
    R   ___                                     ; 67BF row 01
    RI  C_3, 11, 0                              ; 67C0 row 02  Inst10
    R   ___                                     ; 67C2 row 03
    RI  C_3, 11, 0                              ; 67C3 row 04  Inst10
    R   ___                                     ; 67C5 row 05
    R   ___                                     ; 67C6 row 06
    R   ___                                     ; 67C7 row 07
    RI  C_3, 9, 0                               ; 67C8 row 08  Inst08
    R   ___                                     ; 67CA row 09
    R   ___                                     ; 67CB row 10
    R   ___                                     ; 67CC row 11
    RI  C_3, 11, 0                              ; 67CD row 12  Inst10
    R   ___                                     ; 67CF row 13
    RI  C_3, 11, 0                              ; 67D0 row 14  Inst10
    R   ___                                     ; 67D2 row 15
    R   ___                                     ; 67D3 row 16
    R   ___                                     ; 67D4 row 17
    RI  C_3, 11, 0                              ; 67D5 row 18  Inst10
    R   ___                                     ; 67D7 row 19
    RI  C_3, 11, 0                              ; 67D8 row 20  Inst10
    R   ___                                     ; 67DA row 21
    RI  C_3, 11, 0                              ; 67DB row 22  Inst10
    R   ___                                     ; 67DD row 23
    RI  C_3, 9, 0                               ; 67DE row 24  Inst08
    R   ___                                     ; 67E0 row 25
    R   ___                                     ; 67E1 row 26
    R   ___                                     ; 67E2 row 27
    RI  C_3, 11, 0                              ; 67E3 row 28  Inst10
    R   ___                                     ; 67E5 row 29
    RI  C_3, 9, 0                               ; 67E6 row 30  Inst08
    R   ___                                     ; 67E8 row 31
Track104:
    RI  C_3, 27, 0                              ; 67E9 row 00  Inst26
    RI  ___, 0, 1                               ; 67EB row 01
    RI  C_3, 27, 0                              ; 67ED row 02  Inst26
    RI  ___, 0, 1                               ; 67EF row 03
    RI  C_3, 27, 0                              ; 67F1 row 04  Inst26
    RI  ___, 0, 1                               ; 67F3 row 05
    R   ___                                     ; 67F5 row 06
    RI  ___, 0, 2                               ; 67F6 row 07
    RI  C_3, 27, 0                              ; 67F8 row 08  Inst26
    RI  ___, 0, 1                               ; 67FA row 09
    R   ___                                     ; 67FC row 10
    R   ___                                     ; 67FD row 11
    RI  C_3, 27, 0                              ; 67FE row 12  Inst26
    RI  ___, 0, 1                               ; 6800 row 13
    RI  C_3, 27, 0                              ; 6802 row 14  Inst26
    RI  ___, 0, 1                               ; 6804 row 15
    R   ___                                     ; 6806 row 16
    R   ___                                     ; 6807 row 17
    RI  C_3, 27, 0                              ; 6808 row 18  Inst26
    RI  ___, 0, 1                               ; 680A row 19
    RI  C_3, 27, 0                              ; 680C row 20  Inst26
    RI  ___, 0, 1                               ; 680E row 21
    RI  C_3, 27, 0                              ; 6810 row 22  Inst26
    RI  ___, 0, 1                               ; 6812 row 23
    RI  C_3, 27, 0                              ; 6814 row 24  Inst26
    RI  ___, 0, 1                               ; 6816 row 25
    R   ___                                     ; 6818 row 26
    R   ___                                     ; 6819 row 27
    RI  C_3, 27, 0                              ; 681A row 28  Inst26
    RI  ___, 0, 1                               ; 681C row 29
    RI  C_3, 27, 0                              ; 681E row 30  Inst26
    RI  ___, 0, 1                               ; 6820 row 31
Track105:
    RI  G_2, 16, 0                              ; 6822 row 00  Inst15
    R   ___                                     ; 6824 row 01
    R   ___                                     ; 6825 row 02
    R   ___                                     ; 6826 row 03
    RI  G_3, 16, 0                              ; 6827 row 04  Inst15
    R   ___                                     ; 6829 row 05
    R   ___                                     ; 682A row 06
    R   ___                                     ; 682B row 07
    RI  D_3, 16, 0                              ; 682C row 08  Inst15
    R   ___                                     ; 682E row 09
    R   ___                                     ; 682F row 10
    R   ___                                     ; 6830 row 11
    RI  G_2, 16, 0                              ; 6831 row 12  Inst15
    R   ___                                     ; 6833 row 13
    RI  G_2, 16, 0                              ; 6834 row 14  Inst15
    R   ___                                     ; 6836 row 15
    R   ___                                     ; 6837 row 16
    R   ___                                     ; 6838 row 17
    RI  G_2, 16, 0                              ; 6839 row 18  Inst15
    R   ___                                     ; 683B row 19
    RI  G_3, 16, 0                              ; 683C row 20  Inst15
    R   ___                                     ; 683E row 21
    RI  G_2, 16, 0                              ; 683F row 22  Inst15
    R   ___                                     ; 6841 row 23
    RI  D_3, 16, 0                              ; 6842 row 24  Inst15
    R   ___                                     ; 6844 row 25
    R   ___                                     ; 6845 row 26
    R   ___                                     ; 6846 row 27
    RI  G_2, 16, 0                              ; 6847 row 28  Inst15
    R   ___                                     ; 6849 row 29
    R   ___                                     ; 684A row 30
    R   ___                                     ; 684B row 31
Track106:
    RI  C_3, 27, 0                              ; 684C row 00  Inst26
    RI  ___, 0, 1                               ; 684E row 01
    RI  C_3, 27, 0                              ; 6850 row 02  Inst26
    RI  ___, 0, 1                               ; 6852 row 03
    RI  C_3, 27, 0                              ; 6854 row 04  Inst26
    RI  ___, 0, 1                               ; 6856 row 05
    R   ___                                     ; 6858 row 06
    RI  ___, 0, 2                               ; 6859 row 07
    RI  C_3, 27, 0                              ; 685B row 08  Inst26
    RI  ___, 0, 1                               ; 685D row 09
    R   ___                                     ; 685F row 10
    R   ___                                     ; 6860 row 11
    RI  C_3, 27, 0                              ; 6861 row 12  Inst26
    RI  ___, 0, 1                               ; 6863 row 13
    RI  C_3, 27, 0                              ; 6865 row 14  Inst26
    R   ___                                     ; 6867 row 15
    R   ___                                     ; 6868 row 16
    R   ___                                     ; 6869 row 17
    R   ___                                     ; 686A row 18
    R   ___                                     ; 686B row 19
    R   ___                                     ; 686C row 20
    R   ___                                     ; 686D row 21
    R   ___                                     ; 686E row 22
    R   ___                                     ; 686F row 23
    R   ___                                     ; 6870 row 24
    R   ___                                     ; 6871 row 25
    R   ___                                     ; 6872 row 26
    R   ___                                     ; 6873 row 27
    R   ___                                     ; 6874 row 28
    R   ___                                     ; 6875 row 29
    R   ___                                     ; 6876 row 30
    R   ___                                     ; 6877 row 31
Track107:
    RIF G_2, 10, 0, $F, $6                      ; 6878 row 00  Inst09  speed 6
    R   ___                                     ; 687B row 01
    RI  G_2, 10, 0                              ; 687C row 02  Inst09
    R   ___                                     ; 687E row 03
    RI  G_2, 10, 0                              ; 687F row 04  Inst09
    R   ___                                     ; 6881 row 05
    R   ___                                     ; 6882 row 06
    RI  ___, 0, 0                               ; 6883 row 07
    RI  C_3, 8, 0                               ; 6885 row 08  Inst07
    R   ___                                     ; 6887 row 09
    R   ___                                     ; 6888 row 10
    R   ___                                     ; 6889 row 11
    RI  F_2, 10, 0                              ; 688A row 12  Inst09
    R   ___                                     ; 688C row 13
    RI  G_2, 10, 0                              ; 688D row 14  Inst09
    R   ___                                     ; 688F row 15
    R   ___                                     ; 6890 row 16
    RI  ___, 0, 2                               ; 6891 row 17
    R   ___                                     ; 6893 row 18
    R   ___                                     ; 6894 row 19
    RI  ___, 0, 1                               ; 6895 row 20
    R   ___                                     ; 6897 row 21
    R   ___                                     ; 6898 row 22
    RI  C_3, 25, 0                              ; 6899 row 23  Inst24
    R   ___                                     ; 689B row 24
    R   ___                                     ; 689C row 25
    R   ___                                     ; 689D row 26
    R   ___                                     ; 689E row 27
    R   ___                                     ; 689F row 28
    R   ___                                     ; 68A0 row 29
    R   ___                                     ; 68A1 row 30
    R   ___                                     ; 68A2 row 31
Track108:
    RI  C_3, 11, 0                              ; 68A3 row 00  Inst10
    R   ___                                     ; 68A5 row 01
    RI  C_3, 11, 0                              ; 68A6 row 02  Inst10
    R   ___                                     ; 68A8 row 03
    RI  C_3, 11, 0                              ; 68A9 row 04  Inst10
    R   ___                                     ; 68AB row 05
    R   ___                                     ; 68AC row 06
    R   ___                                     ; 68AD row 07
    RI  C_3, 9, 0                               ; 68AE row 08  Inst08
    R   ___                                     ; 68B0 row 09
    R   ___                                     ; 68B1 row 10
    R   ___                                     ; 68B2 row 11
    RI  C_3, 9, 0                               ; 68B3 row 12  Inst08
    R   ___                                     ; 68B5 row 13
    RI  C_3, 12, 0                              ; 68B6 row 14  Inst11
    R   ___                                     ; 68B8 row 15
    R   ___                                     ; 68B9 row 16
    R   ___                                     ; 68BA row 17
    R   ___                                     ; 68BB row 18
    R   ___                                     ; 68BC row 19
    R   ___                                     ; 68BD row 20
    R   ___                                     ; 68BE row 21
    R   ___                                     ; 68BF row 22
    R   ___                                     ; 68C0 row 23
    R   ___                                     ; 68C1 row 24
    R   ___                                     ; 68C2 row 25
    R   ___                                     ; 68C3 row 26
    R   ___                                     ; 68C4 row 27
    R   ___                                     ; 68C5 row 28
    R   ___                                     ; 68C6 row 29
    R   ___                                     ; 68C7 row 30
    R   ___                                     ; 68C8 row 31
Track109:
    RI  G_2, 16, 0                              ; 68C9 row 00  Inst15
    R   ___                                     ; 68CB row 01
    R   ___                                     ; 68CC row 02
    R   ___                                     ; 68CD row 03
    RI  G_3, 16, 0                              ; 68CE row 04  Inst15
    R   ___                                     ; 68D0 row 05
    R   ___                                     ; 68D1 row 06
    R   ___                                     ; 68D2 row 07
    RI  D_3, 16, 0                              ; 68D3 row 08  Inst15
    R   ___                                     ; 68D5 row 09
    R   ___                                     ; 68D6 row 10
    R   ___                                     ; 68D7 row 11
    RI  G_2, 16, 0                              ; 68D8 row 12  Inst15
    R   ___                                     ; 68DA row 13
    RI  G_2, 4, 0                               ; 68DB row 14  Inst03
    R   ___                                     ; 68DD row 15
    R   ___                                     ; 68DE row 16
    R   ___                                     ; 68DF row 17
    R   ___                                     ; 68E0 row 18
    R   ___                                     ; 68E1 row 19
    R   ___                                     ; 68E2 row 20
    R   ___                                     ; 68E3 row 21
    R   ___                                     ; 68E4 row 22
    R   ___                                     ; 68E5 row 23
    R   ___                                     ; 68E6 row 24
    R   ___                                     ; 68E7 row 25
    R   ___                                     ; 68E8 row 26
    R   ___                                     ; 68E9 row 27
    R   ___                                     ; 68EA row 28
    R   ___                                     ; 68EB row 29
    R   ___                                     ; 68EC row 30
    R   ___                                     ; 68ED row 31

;; Wave-RAM source data for Inst01, Inst09, Inst24. 16 bytes at base+position are copied
;; to $FF30-$FF3F (4-bit samples, high nibble first); positions used: $02-$10.
WaveData00:
    db $88, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00; 68EE 
    db $06, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF; 68FE 
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $F8, $00, $00, $00, $00, $00, $00; 690E 
    db $00, $06, $FF, $FF, $FF, $FF, $FF, $FF   ; 691E 

;; Wave-RAM source data for Inst07. 16 bytes at base+position are copied
;; to $FF30-$FF3F (4-bit samples, high nibble first); positions used: $02-$10.
WaveData01:
    db $88, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00; 6926 
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF; 6936 
SFXInstTable:
    dw SFXInst00                                 ; 6946  SFX instrument 1 (ch4)
    dw SFXInst01                                 ; 6948  SFX instrument 2 (ch1)
    dw SFXInst02                                 ; 694A  SFX instrument 3 (ch1)
    dw SFXInst03                                 ; 694C  SFX instrument 4 (ch4)
    dw SFXInst04                                 ; 694E  SFX instrument 5 (ch1)
    dw SFXInst05                                 ; 6950  SFX instrument 6 (ch4)
    dw SFXInst06                                 ; 6952  SFX instrument 7 (ch1)
    dw SFXInst07                                 ; 6954  SFX instrument 8 (ch4)
    dw SFXInst08                                 ; 6956  SFX instrument 9 (ch4)
    dw SFXInst09                                 ; 6958  SFX instrument 10 (ch1)
    dw SFXInst10                                 ; 695A  SFX instrument 11 (ch4)
    dw SFXInst11                                 ; 695C  SFX instrument 12 (ch4)
    dw SFXInst12                                 ; 695E  SFX instrument 13 (ch1)
    dw SFXInst13                                 ; 6960  SFX instrument 14 (ch4)
    dw SFXInst14                                 ; 6962  SFX instrument 15 (ch4)
    dw SFXInst15                                 ; 6964  SFX instrument 16 (ch1)
    dw SFXInst16                                 ; 6966  SFX instrument 17 (ch1)
    dw SFXInst17                                 ; 6968  SFX instrument 18 (ch4)
    dw SFXInst18                                 ; 696A  SFX instrument 19 (ch4)
    dw SFXInst19                                 ; 696C  SFX instrument 20 (ch1)
    dw SFXInst20                                 ; 696E  SFX instrument 21 (unused)
    dw SFXInst21                                 ; 6970  SFX instrument 22 (ch4)
    dw SFXInst22                                 ; 6972  SFX instrument 23 (ch4)
    dw SFXInst23                                 ; 6974  SFX instrument 24 (ch1)
    dw SFXInst24                                 ; 6976  SFX instrument 25 (ch4)
    dw SFXInst25                                 ; 6978  SFX instrument 26 (ch4)
    dw SFXInst26                                 ; 697A  SFX instrument 27 (ch1)
    dw SFXInst27                                 ; 697C  SFX instrument 28 (ch1)
    dw SFXInst28                                 ; 697E  SFX instrument 29 (ch1)
    dw SFXInst29                                 ; 6980  SFX instrument 30 (ch4)
    dw SFXInst30                                 ; 6982  SFX instrument 31 (ch4)
    dw SFXInst31                                 ; 6984  SFX instrument 32 (ch4)
    dw SFXInst32                                 ; 6986  SFX instrument 33 (ch4)
    dw SFXInst33                                 ; 6988  SFX instrument 34 (ch4)
    dw SFXInst34                                 ; 698A  SFX instrument 35 (ch1)
    dw SFXInst35                                 ; 698C  SFX instrument 36 (ch1)
    dw SFXInst36                                 ; 698E  SFX instrument 37 (ch1)
    dw SFXInst37                                 ; 6990  SFX instrument 38 (ch4)
    dw SFXInst38                                 ; 6992  SFX instrument 39 (ch4)
    dw SFXInst39                                 ; 6994  SFX instrument 40 (ch1)
    dw SFXInst40                                 ; 6996  SFX instrument 41 (ch4)
    dw SFXInst41                                 ; 6998  SFX instrument 42 (ch1)
    dw SFXInst42                                 ; 699A  SFX instrument 43 (ch4)
    dw SFXInst43                                 ; 699C  SFX instrument 44 (ch1)
    dw SFXInst44                                 ; 699E  SFX instrument 45 (ch1)
    dw SFXInst45                                 ; 69A0  SFX instrument 46 (ch1)
    dw SFXInst46                                 ; 69A2  SFX instrument 47 (ch3)
    dw SFXInst47                                 ; 69A4  SFX instrument 48 (ch1)
    dw SFXInst48                                 ; 69A6  SFX instrument 49 (ch1)
SFXInst00:
    db $02                                       ; 69A8 noise, 2 steps
    db $01                                       ; playlist speed
    db $82                                       ; NR42 envelope
    db $7A, $00, $00                             ; step 0: A-6
    db $65, $00, $00                             ; step 1: C-5
SFXInst01:
    db $06                                       ; 69B1 square, 6 steps
    db $01                                       ; playlist speed
    db $F1                                       ; NRx2 envelope
    db $5D, $00, $C2                             ; step 0: E-4  duty 2
    db $59, $00, $00                             ; step 1: C-4
    db $56, $00, $00                             ; step 2: A-3
    db $52, $00, $00                             ; step 3: F-3
    db $4F, $00, $00                             ; step 4: D-3
    db $40, $00, $40                             ; step 5: -  vol 0
SFXInst02:
    db $05                                       ; 69C6 square, 5 steps
    db $01                                       ; playlist speed
    db $F1                                       ; NRx2 envelope
    db $59, $00, $C2                             ; step 0: C-4  duty 2
    db $58, $00, $00                             ; step 1: B-3
    db $56, $00, $00                             ; step 2: A-3
    db $54, $00, $00                             ; step 3: G-3
    db $52, $00, $85                             ; step 4: F-3  jump -5
SFXInst03:
    db $03                                       ; 69D8 noise, 3 steps
    db $02                                       ; playlist speed
    db $A2                                       ; NR42 envelope
    db $7A, $00, $00                             ; step 0: A-6
    db $59, $00, $00                             ; step 1: C-4
    db $4D, $00, $82                             ; step 2: C-3  jump -2
SFXInst04:
    db $06                                       ; 69E4 square, 6 steps
    db $01                                       ; playlist speed
    db $F0                                       ; NRx2 envelope
    db $59, $00, $C2                             ; step 0: C-4  duty 2
    db $56, $00, $00                             ; step 1: A-3
    db $52, $00, $00                             ; step 2: F-3
    db $4F, $00, $00                             ; step 3: D-3
    db $4D, $00, $00                             ; step 4: C-3
    db $4A, $00, $86                             ; step 5: A-2  jump -6
SFXInst05:
    db $06                                       ; 69F9 noise, 6 steps
    db $01                                       ; playlist speed
    db $71                                       ; NR42 envelope
    db $7A, $00, $4B                             ; step 0: A-6  vol 11
    db $65, $00, $00                             ; step 1: C-5
    db $40, $00, $00                             ; step 2: -
    db $40, $00, $44                             ; step 3: -  vol 4
    db $40, $00, $00                             ; step 4: -
    db $40, $00, $86                             ; step 5: -  jump -6
SFXInst06:
    db $01                                       ; 6A0E square, 1 steps
    db $01                                       ; playlist speed
    db $00                                       ; NRx2 envelope
    db $41, $00, $40                             ; step 0: C-2  vol 0
SFXInst07:
    db $01                                       ; 6A14 noise, 1 steps
    db $01                                       ; playlist speed
    db $00                                       ; NR42 envelope
    db $41, $00, $40                             ; step 0: C-2  vol 0
SFXInst08:
    db $04                                       ; 6A1A noise, 4 steps
    db $01                                       ; playlist speed
    db $F5                                       ; NR42 envelope
    db $59, $00, $4F                             ; step 0: C-4  vol 15
    db $54, $00, $4F                             ; step 1: G-3  vol 15
    db $4D, $00, $4F                             ; step 2: C-3  vol 15
    db $46, $00, $4F                             ; step 3: F-2  vol 15
SFXInst09:
    db $05                                       ; 6A29 square, 5 steps
    db $01                                       ; playlist speed
    db $F4                                       ; NRx2 envelope
    db $52, $00, $C2                             ; step 0: F-3  duty 2
    db $51, $00, $00                             ; step 1: E-3
    db $50, $00, $00                             ; step 2: D#3
    db $4F, $00, $00                             ; step 3: D-3
    db $4E, $00, $85                             ; step 4: C#3  jump -5
SFXInst10:
    db $05                                       ; 6A3B noise, 5 steps
    db $01                                       ; playlist speed
    db $F3                                       ; NR42 envelope
    db $7C, $00, $00                             ; step 0: B-6
    db $7A, $00, $00                             ; step 1: A-6
    db $7C, $00, $00                             ; step 2: B-6
    db $7A, $00, $00                             ; step 3: A-6
    db $71, $00, $85                             ; step 4: C-6  jump -5
SFXInst11:
    db $04                                       ; 6A4D noise, 4 steps
    db $02                                       ; playlist speed
    db $C2                                       ; NR42 envelope
    db $71, $00, $4F                             ; step 0: C-6  vol 15
    db $70, $00, $4F                             ; step 1: B-5  vol 15
    db $6F, $00, $4F                             ; step 2: A#5  vol 15
    db $6E, $00, $4F                             ; step 3: A-5  vol 15
SFXInst12:
    db $06                                       ; 6A5C square, 6 steps
    db $01                                       ; playlist speed
    db $F2                                       ; NRx2 envelope
    db $52, $00, $C2                             ; step 0: F-3  duty 2
    db $53, $00, $00                             ; step 1: F#3
    db $54, $00, $00                             ; step 2: G-3
    db $55, $00, $00                             ; step 3: G#3
    db $56, $00, $85                             ; step 4: A-3  jump -5
    db $40, $00, $40                             ; step 5: -  vol 0
SFXInst13:
    db $0D                                       ; 6A71 noise, 13 steps
    db $02                                       ; playlist speed
    db $C4                                       ; NR42 envelope
    db $4D, $00, $00                             ; step 0: C-3
    db $54, $00, $00                             ; step 1: G-3
    db $5B, $00, $00                             ; step 2: D-4
    db $6C, $00, $00                             ; step 3: G-5
    db $40, $00, $00                             ; step 4: -
    db $40, $00, $00                             ; step 5: -
    db $5F, $00, $00                             ; step 6: F#4
    db $40, $00, $00                             ; step 7: -
    db $40, $00, $00                             ; step 8: -
    db $5E, $00, $00                             ; step 9: F-4
    db $40, $00, $00                             ; step 10: -
    db $40, $00, $00                             ; step 11: -
    db $5D, $00, $00                             ; step 12: E-4
SFXInst14:
    db $0E                                       ; 6A9B noise, 14 steps
    db $02                                       ; playlist speed
    db $C0                                       ; NR42 envelope
    db $46, $00, $00                             ; step 0: F-2
    db $47, $00, $00                             ; step 1: F#2
    db $48, $00, $00                             ; step 2: G-2
    db $49, $00, $00                             ; step 3: G#2
    db $4A, $00, $00                             ; step 4: A-2
    db $4B, $00, $00                             ; step 5: A#2
    db $4C, $00, $00                             ; step 6: B-2
    db $4D, $00, $00                             ; step 7: C-3
    db $4E, $00, $00                             ; step 8: C#3
    db $4F, $00, $00                             ; step 9: D-3
    db $40, $00, $40                             ; step 10: -  vol 0
    db $40, $00, $00                             ; step 11: -
    db $40, $00, $00                             ; step 12: -
    db $40, $00, $00                             ; step 13: -
SFXInst15:
    db $11                                       ; 6AC8 square, 17 steps
    db $01                                       ; playlist speed
    db $F0                                       ; NRx2 envelope
    db $46, $00, $C2                             ; step 0: F-2  duty 2
    db $47, $00, $00                             ; step 1: F#2
    db $48, $00, $00                             ; step 2: G-2
    db $49, $00, $00                             ; step 3: G#2
    db $4A, $00, $00                             ; step 4: A-2
    db $4B, $00, $00                             ; step 5: A#2
    db $4C, $00, $00                             ; step 6: B-2
    db $4D, $00, $00                             ; step 7: C-3
    db $4E, $00, $00                             ; step 8: C#3
    db $4F, $00, $00                             ; step 9: D-3
    db $50, $00, $00                             ; step 10: D#3
    db $51, $00, $00                             ; step 11: E-3
    db $52, $00, $00                             ; step 12: F-3
    db $53, $00, $00                             ; step 13: F#3
    db $54, $00, $00                             ; step 14: G-3
    db $55, $00, $00                             ; step 15: G#3
    db $40, $00, $40                             ; step 16: -  vol 0
SFXInst16:
    db $08                                       ; 6AFE square, 8 steps
    db $01                                       ; playlist speed
    db $91                                       ; NRx2 envelope
    db $65, $40, $C2                             ; step 0: C-5  vol 0, duty 2
    db $40, $40, $00                             ; step 1: -  vol 0
    db $40, $40, $00                             ; step 2: -  vol 0
    db $40, $00, $00                             ; step 3: -
    db $7A, $49, $00                             ; step 4: A-6  vol 9
    db $7C, $00, $00                             ; step 5: B-6
    db $7A, $00, $00                             ; step 6: A-6
    db $40, $00, $00                             ; step 7: -
SFXInst17:
    db $06                                       ; 6B19 noise, 6 steps
    db $01                                       ; playlist speed
    db $E0                                       ; NR42 envelope
    db $41, $00, $00                             ; step 0: C-2
    db $4D, $00, $00                             ; step 1: C-3
    db $59, $00, $00                             ; step 2: C-4
    db $71, $00, $00                             ; step 3: C-6
    db $4D, $00, $00                             ; step 4: C-3
    db $40, $00, $40                             ; step 5: -  vol 0
SFXInst18:
    db $06                                       ; 6B2E noise, 6 steps
    db $01                                       ; playlist speed
    db $C0                                       ; NR42 envelope
    db $60, $00, $4F                             ; step 0: G-4  vol 15
    db $40, $00, $4F                             ; step 1: -  vol 15
    db $40, $00, $40                             ; step 2: -  vol 0
    db $4D, $00, $4F                             ; step 3: C-3  vol 15
    db $40, $00, $4A                             ; step 4: -  vol 10
    db $40, $00, $40                             ; step 5: -  vol 0
SFXInst19:
    db $06                                       ; 6B43 square, 6 steps
    db $01                                       ; playlist speed
    db $C0                                       ; NRx2 envelope
    db $60, $C2, $4F                             ; step 0: G-4  duty 2, vol 15
    db $40, $00, $4F                             ; step 1: -  vol 15
    db $40, $00, $40                             ; step 2: -  vol 0
    db $4D, $00, $4F                             ; step 3: C-3  vol 15
    db $40, $00, $4A                             ; step 4: -  vol 10
    db $40, $00, $40                             ; step 5: -  vol 0
SFXInst20:
    db $00                                       ; 6B58 square, 0 steps
    db $01                                       ; playlist speed
    db $00                                       ; NRx2 envelope
SFXInst21:
    db $07                                       ; 6B5B noise, 7 steps
    db $02                                       ; playlist speed
    db $E0                                       ; NR42 envelope
    db $41, $00, $00                             ; step 0: C-2
    db $43, $00, $00                             ; step 1: D-2
    db $45, $00, $00                             ; step 2: E-2
    db $46, $00, $00                             ; step 3: F-2
    db $48, $00, $00                             ; step 4: G-2
    db $4A, $00, $00                             ; step 5: A-2
    db $40, $00, $40                             ; step 6: -  vol 0
SFXInst22:
    db $07                                       ; 6B73 noise, 7 steps
    db $01                                       ; playlist speed
    db $E0                                       ; NR42 envelope
    db $4D, $00, $00                             ; step 0: C-3
    db $54, $00, $00                             ; step 1: G-3
    db $59, $00, $00                             ; step 2: C-4
    db $60, $00, $00                             ; step 3: G-4
    db $65, $00, $00                             ; step 4: C-5
    db $6C, $00, $00                             ; step 5: G-5
    db $40, $00, $40                             ; step 6: -  vol 0
SFXInst23:
    db $05                                       ; 6B8B square, 5 steps
    db $01                                       ; playlist speed
    db $B1                                       ; NRx2 envelope
    db $59, $00, $C2                             ; step 0: C-4  duty 2
    db $5A, $00, $00                             ; step 1: C#4
    db $59, $00, $00                             ; step 2: C-4
    db $5A, $00, $00                             ; step 3: C#4
    db $59, $00, $85                             ; step 4: C-4  jump -5
SFXInst24:
    db $05                                       ; 6B9D noise, 5 steps
    db $05                                       ; playlist speed
    db $F3                                       ; NR42 envelope
    db $41, $00, $00                             ; step 0: C-2
    db $42, $00, $00                             ; step 1: C#2
    db $43, $00, $00                             ; step 2: D-2
    db $44, $00, $00                             ; step 3: D#2
    db $45, $00, $00                             ; step 4: E-2
SFXInst25:
    db $03                                       ; 6BAF noise, 3 steps
    db $01                                       ; playlist speed
    db $F1                                       ; NR42 envelope
    db $41, $00, $00                             ; step 0: C-2
    db $54, $00, $00                             ; step 1: G-3
    db $59, $00, $83                             ; step 2: C-4  jump -3
SFXInst26:
    db $05                                       ; 6BBB square, 5 steps
    db $01                                       ; playlist speed
    db $C2                                       ; NRx2 envelope
    db $6E, $00, $C2                             ; step 0: A-5  duty 2
    db $6D, $00, $00                             ; step 1: G#5
    db $6C, $00, $00                             ; step 2: G-5
    db $6B, $00, $00                             ; step 3: F#5
    db $6A, $00, $85                             ; step 4: F-5  jump -5
SFXInst27:
    db $05                                       ; 6BCD square, 5 steps
    db $01                                       ; playlist speed
    db $E1                                       ; NRx2 envelope
    db $6B, $00, $C2                             ; step 0: F#5  duty 2
    db $6A, $00, $00                             ; step 1: F-5
    db $69, $00, $00                             ; step 2: E-5
    db $68, $00, $00                             ; step 3: D#5
    db $67, $00, $85                             ; step 4: D-5  jump -5
SFXInst28:
    db $0B                                       ; 6BDF square, 11 steps
    db $01                                       ; playlist speed
    db $C2                                       ; NRx2 envelope
    db $6C, $00, $C2                             ; step 0: G-5  duty 2
    db $6B, $00, $00                             ; step 1: F#5
    db $6A, $00, $00                             ; step 2: F-5
    db $69, $00, $00                             ; step 3: E-5
    db $68, $00, $00                             ; step 4: D#5
    db $6A, $00, $00                             ; step 5: F-5
    db $69, $00, $00                             ; step 6: E-5
    db $68, $00, $00                             ; step 7: D#5
    db $67, $00, $00                             ; step 8: D-5
    db $66, $00, $00                             ; step 9: C#5
    db $65, $00, $8B                             ; step 10: C-5  jump -11
SFXInst29:
    db $02                                       ; 6C03 noise, 2 steps
    db $01                                       ; playlist speed
    db $F1                                       ; NR42 envelope
    db $71, $00, $00                             ; step 0: C-6
    db $41, $00, $82                             ; step 1: C-2  jump -2
SFXInst30:
    db $07                                       ; 6C0C noise, 7 steps
    db $01                                       ; playlist speed
    db $F2                                       ; NR42 envelope
    db $78, $00, $00                             ; step 0: G-6
    db $46, $00, $00                             ; step 1: F-2
    db $7C, $00, $83                             ; step 2: B-6  jump -3
    db $40, $00, $00                             ; step 3: -
    db $40, $00, $00                             ; step 4: -
    db $40, $00, $00                             ; step 5: -
    db $40, $00, $00                             ; step 6: -
SFXInst31:
    db $07                                       ; 6C24 noise, 7 steps
    db $06                                       ; playlist speed
    db $F3                                       ; NR42 envelope
    db $59, $00, $00                             ; step 0: C-4
    db $4D, $00, $00                             ; step 1: C-3
    db $41, $00, $00                             ; step 2: C-2
    db $40, $00, $00                             ; step 3: -
    db $40, $00, $00                             ; step 4: -
    db $40, $00, $00                             ; step 5: -
    db $40, $00, $00                             ; step 6: -
SFXInst32:
    db $03                                       ; 6C3C noise, 3 steps
    db $01                                       ; playlist speed
    db $71                                       ; NR42 envelope
    db $7A, $00, $4F                             ; step 0: A-6  vol 15
    db $41, $00, $00                             ; step 1: C-2
    db $40, $00, $40                             ; step 2: -  vol 0
SFXInst33:
    db $07                                       ; 6C48 noise, 7 steps
    db $02                                       ; playlist speed
    db $F5                                       ; NR42 envelope
    db $59, $00, $00                             ; step 0: C-4
    db $57, $00, $00                             ; step 1: A#3
    db $52, $00, $00                             ; step 2: F-3
    db $4F, $00, $00                             ; step 3: D-3
    db $41, $00, $85                             ; step 4: C-2  jump -5
    db $40, $00, $00                             ; step 5: -
    db $40, $00, $00                             ; step 6: -
SFXInst34:
    db $03                                       ; 6C60 square, 3 steps
    db $01                                       ; playlist speed
    db $F3                                       ; NRx2 envelope
    db $59, $00, $C2                             ; step 0: C-4  duty 2
    db $52, $00, $00                             ; step 1: F-3
    db $40, $00, $40                             ; step 2: -  vol 0
SFXInst35:
    db $06                                       ; 6C6C square, 6 steps
    db $02                                       ; playlist speed
    db $F5                                       ; NRx2 envelope
    db $5D, $00, $C2                             ; step 0: E-4  duty 2
    db $59, $00, $00                             ; step 1: C-4
    db $56, $00, $00                             ; step 2: A-3
    db $52, $00, $00                             ; step 3: F-3
    db $4F, $00, $85                             ; step 4: D-3  jump -5
    db $40, $00, $00                             ; step 5: -
SFXInst36:
    db $06                                       ; 6C81 square, 6 steps
    db $02                                       ; playlist speed
    db $F5                                       ; NRx2 envelope
    db $65, $00, $C2                             ; step 0: C-5  duty 2
    db $66, $00, $00                             ; step 1: C#5
    db $6C, $00, $C0                             ; step 2: G-5  duty 0
    db $6F, $00, $00                             ; step 3: A#5
    db $74, $00, $85                             ; step 4: D#6  jump -5
    db $40, $00, $00                             ; step 5: -
SFXInst37:
    db $07                                       ; 6C96 noise, 7 steps
    db $02                                       ; playlist speed
    db $F5                                       ; NR42 envelope
    db $71, $00, $00                             ; step 0: C-6
    db $75, $00, $00                             ; step 1: E-6
    db $41, $00, $83                             ; step 2: C-2  jump -3
    db $40, $00, $00                             ; step 3: -
    db $40, $00, $00                             ; step 4: -
    db $40, $00, $00                             ; step 5: -
    db $40, $00, $00                             ; step 6: -
SFXInst38:
    db $07                                       ; 6CAE noise, 7 steps
    db $02                                       ; playlist speed
    db $F5                                       ; NR42 envelope
    db $7C, $00, $00                             ; step 0: B-6
    db $71, $00, $00                             ; step 1: C-6
    db $70, $00, $00                             ; step 2: B-5
    db $69, $00, $00                             ; step 3: E-5
    db $65, $00, $00                             ; step 4: C-5
    db $40, $00, $00                             ; step 5: -
    db $40, $00, $00                             ; step 6: -
SFXInst39:
    db $06                                       ; 6CC6 square, 6 steps
    db $02                                       ; playlist speed
    db $F5                                       ; NRx2 envelope
    db $59, $00, $C0                             ; step 0: C-4  duty 0
    db $5A, $00, $00                             ; step 1: C#4
    db $5B, $00, $00                             ; step 2: D-4
    db $5A, $00, $84                             ; step 3: C#4  jump -4
    db $40, $00, $00                             ; step 4: -
    db $40, $00, $00                             ; step 5: -
SFXInst40:
    db $0E                                       ; 6CDB noise, 14 steps
    db $01                                       ; playlist speed
    db $C0                                       ; NR42 envelope
    db $4D, $00, $00                             ; step 0: C-3
    db $51, $00, $00                             ; step 1: E-3
    db $54, $00, $00                             ; step 2: G-3
    db $58, $00, $00                             ; step 3: B-3
    db $5B, $00, $00                             ; step 4: D-4
    db $5E, $00, $00                             ; step 5: F-4
    db $5F, $00, $00                             ; step 6: F#4
    db $60, $00, $00                             ; step 7: G-4
    db $40, $00, $40                             ; step 8: -  vol 0
    db $40, $00, $00                             ; step 9: -
    db $40, $00, $00                             ; step 10: -
    db $40, $00, $00                             ; step 11: -
    db $40, $00, $00                             ; step 12: -
    db $40, $00, $00                             ; step 13: -
SFXInst41:
    db $09                                       ; 6D08 square, 9 steps
    db $01                                       ; playlist speed
    db $F0                                       ; NRx2 envelope
    db $60, $00, $C2                             ; step 0: G-4  duty 2
    db $5D, $00, $00                             ; step 1: E-4
    db $56, $00, $00                             ; step 2: A-3
    db $58, $00, $00                             ; step 3: B-3
    db $51, $00, $00                             ; step 4: E-3
    db $4F, $00, $00                             ; step 5: D-3
    db $4C, $00, $00                             ; step 6: B-2
    db $45, $00, $00                             ; step 7: E-2
    db $40, $00, $40                             ; step 8: -  vol 0
SFXInst42:
    db $05                                       ; 6D26 noise, 5 steps
    db $02                                       ; playlist speed
    db $F3                                       ; NR42 envelope
    db $7A, $00, $4F                             ; step 0: A-6  vol 15
    db $40, $00, $40                             ; step 1: -  vol 0
    db $65, $00, $4F                             ; step 2: C-5  vol 15
    db $40, $00, $40                             ; step 3: -  vol 0
    db $40, $00, $00                             ; step 4: -
SFXInst43:
    db $06                                       ; 6D38 square, 6 steps
    db $01                                       ; playlist speed
    db $F0                                       ; NRx2 envelope
    db $59, $00, $C2                             ; step 0: C-4  duty 2
    db $5D, $00, $00                             ; step 1: E-4
    db $60, $00, $00                             ; step 2: G-4
    db $40, $00, $40                             ; step 3: -  vol 0
    db $40, $00, $00                             ; step 4: -
    db $40, $00, $00                             ; step 5: -
SFXInst44:
    db $06                                       ; 6D4D square, 6 steps
    db $02                                       ; playlist speed
    db $F1                                       ; NRx2 envelope
    db $65, $00, $C2                             ; step 0: C-5  duty 2
    db $71, $00, $82                             ; step 1: C-6  jump -2
    db $40, $00, $00                             ; step 2: -
    db $40, $00, $00                             ; step 3: -
    db $40, $00, $00                             ; step 4: -
    db $40, $00, $00                             ; step 5: -
SFXInst45:
    db $08                                       ; 6D62 square, 8 steps
    db $01                                       ; playlist speed
    db $F0                                       ; NRx2 envelope
    db $52, $00, $C2                             ; step 0: F-3  duty 2
    db $53, $00, $00                             ; step 1: F#3
    db $54, $00, $00                             ; step 2: G-3
    db $55, $00, $00                             ; step 3: G#3
    db $56, $00, $00                             ; step 4: A-3
    db $57, $00, $00                             ; step 5: A#3
    db $58, $00, $00                             ; step 6: B-3
    db $40, $00, $40                             ; step 7: -  vol 0
SFXInst46:
    db $01                                       ; 6D7D wave, 1 steps
    db $01                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0000, $0000, $001E                       ; position, lower bound, upper bound
    db $01                                       ; sweep speed
    db LOW(WaveData02), HIGH(WaveData02)         ; wave data base
    db $41, $00, $40                             ; step 0: C-2  level 0
SFXInst47:
    db $07                                       ; 6D8E square, 7 steps
    db $01                                       ; playlist speed
    db $F0                                       ; NRx2 envelope
    db $63, $00, $C0                             ; step 0: A#4  duty 0
    db $64, $00, $00                             ; step 1: B-4
    db $65, $00, $00                             ; step 2: C-5
    db $6F, $00, $00                             ; step 3: A#5
    db $70, $00, $00                             ; step 4: B-5
    db $71, $00, $00                             ; step 5: C-6
    db $40, $00, $40                             ; step 6: -  vol 0
SFXInst48:
    db $0A                                       ; 6DA6 square, 10 steps
    db $01                                       ; playlist speed
    db $F1                                       ; NRx2 envelope
    db $63, $4F, $C0                             ; step 0: A#4  vol 15, duty 0
    db $64, $4F, $00                             ; step 1: B-4  vol 15
    db $65, $4F, $00                             ; step 2: C-5  vol 15
    db $6F, $4F, $00                             ; step 3: A#5  vol 15
    db $70, $00, $00                             ; step 4: B-5
    db $71, $00, $00                             ; step 5: C-6
    db $63, $00, $00                             ; step 6: A#4
    db $64, $00, $00                             ; step 7: B-4
    db $65, $00, $84                             ; step 8: C-5  jump -4
    db $40, $00, $40                             ; step 9: -  vol 0

;; Wave-RAM source data for SFXInst46. 16 bytes at base+position are copied
;; to $FF30-$FF3F (4-bit samples, high nibble first); positions used: $00-$1E. The window can reach 30 bytes past this block (into SFXTable).
WaveData02:
    db $DC, $DC, $C8, $8C, $8C, $89, $88, $88, $88, $88, $8B, $88, $88, $1F, $B8, $F0; 6DC7 

;; Sound effects, 5 bytes: [ins ch1] [ins ch2] [ins ch3] [ins ch4] [mute time in ticks].
;; Instrument numbers are 1-based indices into SFXInstTable (0 = channel not used);
;; the music on the used channels is muted for "time" ticks ($FF on ch3 = until the next song).
SFXTable:
    db 2, 0, 0, 1, $01                           ; 6DD7 SFX 0
    db 3, 0, 0, 4, $01                           ; 6DDC SFX 1
    db 5, 0, 0, 6, $01                           ; 6DE1 SFX 2
    db 7, 0, 0, 8, $01                           ; 6DE6 SFX 3
    db 10, 0, 0, 9, $01                          ; 6DEB SFX 4
    db 0, 0, 0, 11, $01                          ; 6DF0 SFX 5
    db 0, 0, 0, 12, $01                          ; 6DF5 SFX 6
    db 13, 0, 0, 14, $01                         ; 6DFA SFX 7
    db 16, 0, 0, 15, $01                         ; 6DFF SFX 8
    db 17, 0, 0, 18, $01                         ; 6E04 SFX 9
    db 20, 0, 0, 19, $01                         ; 6E09 SFX 10
    db 0, 0, 0, 22, $01                          ; 6E0E SFX 11
    db 24, 0, 0, 23, $01                         ; 6E13 SFX 12
    db 0, 0, 0, 25, $01                          ; 6E18 SFX 13
    db 28, 0, 0, 26, $01                         ; 6E1D SFX 14
    db 27, 0, 0, 0, $01                          ; 6E22 SFX 15
    db 29, 0, 0, 26, $01                         ; 6E27 SFX 16
    db 0, 0, 0, 30, $01                          ; 6E2C SFX 17
    db 0, 0, 0, 31, $01                          ; 6E31 SFX 18
    db 0, 0, 0, 32, $01                          ; 6E36 SFX 19
    db 35, 0, 0, 33, $01                         ; 6E3B SFX 20
    db 36, 0, 0, 34, $01                         ; 6E40 SFX 21
    db 37, 0, 0, 38, $01                         ; 6E45 SFX 22
    db 40, 0, 0, 39, $01                         ; 6E4A SFX 23
    db 42, 0, 0, 41, $01                         ; 6E4F SFX 24
    db 46, 0, 0, 26, $01                         ; 6E54 SFX 25
    db 0, 0, 0, 43, $01                          ; 6E59 SFX 26
    db 44, 0, 0, 0, $04                          ; 6E5E SFX 27
    db 45, 0, 0, 0, $08                          ; 6E63 SFX 28
    db 0, 0, 47, 0, $FF                          ; 6E68 SFX 29
    db 48, 0, 0, 0, $07                          ; 6E6D SFX 30
    db 49, 0, 0, 26, $0F                         ; 6E72 SFX 31
    ds 4489, $DA                ; 6E77  (fill)
