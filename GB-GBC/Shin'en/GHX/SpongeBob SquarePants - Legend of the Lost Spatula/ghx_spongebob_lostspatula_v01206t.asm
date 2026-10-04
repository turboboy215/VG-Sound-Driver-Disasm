; ============================================================================
; SpongeBob SquarePants - Legend of the Lost Spatula (U) [C][!].gbc  -  bank $3D (file offset $F4000-$F7FFF)
; "GHX Sound Engine   Ver.01206t   (c) 2000 SHIN'EN Code: M. Wodok Music: M.Linzner"
; 
; Version string "Ver.01206t" = 6 Dec 2000 - the newest build here. The song
; names that the converter left in the bank are used for the subsongs below.
; 
; Changes against Jimmy White (00530): the PCM player is gone again (a ch3
; instrument with flag bits 5-7 set only releases channel 3 and saves/restores
; the game's timer-IRQ enable), the playlist loop count works on all channels,
; envelope shadow registers (wChX_EnvShadow) instead of reading NRx2 back, NR10
; kept across GHX_Pause, master volume and fades (GHX_SetMasterVolume,
; GHX_FadeIn, GHX_FadeOut), a second GHX_Stop entry.
;
; Complete disassembly of the bank: sound driver code plus all music and
; sound-effect data as labelled source. Assemble with RGBDS 0.9:
;   rgbasm -o x.o ghx_spongebob_lostspatula_v01206t.asm ; rgblink -o x.gb x.o
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
DEF wFade                        EQU $DEED
DEF wMasterVol                   EQU $DEEE
DEF wTimerIESave                 EQU $DEEF

SECTION "GHX Sound Engine", ROMX[$4000], BANK[$3D]

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
GHX_MuteMusic:
    jp MuteMusic                ; 401E  silence the music, SFX keep playing
GHX_FadeIn:
    jp FadeIn                   ; 4021  A = fade speed
GHX_FadeOut:
    jp FadeOut                  ; 4024  A = fade speed
GHX_SetMasterVolume:
    jp SetMasterVolume          ; 4027  A = NR50 volume 0-7
GHX_Stop2:
    jp StopImpl                 ; 402A  same as GHX_Stop
    db $00, $00, $00                           ; 402D

;; Version / copyright string (never executed)
    db "GHX Sound Engine   Ver.01206t   (c) 2000 SHIN", $B4, "EN Code: M. Wodok Music: M.Linzner"; 4030

;; GHX_SetMasterVolume: A = 0-7 -> NR50 (both sides), remembered in wMasterVol.
SetMasterVolume:
    ld b, a                     ; 4080
    swap a                      ; 4081
    ld [wMasterVol], a          ; 4083
    or b                        ; 4086
    ldh [rNR50], a              ; 4087
    ret                         ; 4089

;; GHX_FadeIn: A = step added to the master volume every frame.
FadeIn:
    ld [wFade], a               ; 408A
    ret                         ; 408D

;; GHX_FadeOut: A = step subtracted every frame; the APU is switched off at 0.
FadeOut:
    set 7, a                    ; 408E
    ld [wFade], a               ; 4090
    ret                         ; 4093

;; GHX_SaveSong: remember the playing song (song, subsong, order state,
;; position, transpose + track pointer of each channel) in wSave_* so that
;; a jingle can be played and the music resumed later. Only one level.
SaveSong:
    ld a, [wSaved]              ; 4094
    or a                        ; 4097
    ret nz                      ; 4098
    cpl                         ; 4099
    ld [wSaved], a              ; 409A
    ld a, [wSong]               ; 409D
    ld [wSave_Song], a          ; 40A0
    ld a, [wSubsong]            ; 40A3
    ld [wSave_Subsong], a       ; 40A6
    ld a, [wOrderSel]           ; 40A9
    ld [wSave_OrderSel], a      ; 40AC
    ld a, [wSpeed]              ; 40AF
    ld [wSave_Speed], a         ; 40B2
    ld a, [wRowsLeft]           ; 40B5
    ld [wSave_RowsLeft], a      ; 40B8
    ld a, [wPosLeft]            ; 40BB
    ld [wSave_PosLeft], a       ; 40BE
    ld a, [wPosPtrLo]           ; 40C1
    ld [wSave_PosPtrLo], a      ; 40C4
    ld a, [wPosPtrHi]           ; 40C7
    ld [wSave_PosPtrHi], a      ; 40CA
    ld a, [wCh1_Transpose]      ; 40CD
    ld [wSave_Channels], a      ; 40D0
    ld a, [wCh1_TrackPtrLo]     ; 40D3
    ld [wSave_Channels+1], a    ; 40D6
    ld a, [wCh1_TrackPtrHi]     ; 40D9
    ld [wSave_Channels+2], a    ; 40DC
    ld a, [wCh2_Transpose]      ; 40DF
    ld [wSave_Channels+3], a    ; 40E2
    ld a, [wCh2_TrackPtrLo]     ; 40E5
    ld [wSave_Channels+4], a    ; 40E8
    ld a, [wCh2_TrackPtrHi]     ; 40EB
    ld [wSave_Channels+5], a    ; 40EE
    ld a, [wCh3_Transpose]      ; 40F1
    ld [wSave_Channels+6], a    ; 40F4
    ld a, [wCh3_TrackPtrLo]     ; 40F7
    ld [wSave_Channels+7], a    ; 40FA
    ld a, [wCh3_TrackPtrHi]     ; 40FD
    ld [wSave_Channels+8], a    ; 4100
    ld a, [wCh4_Transpose]      ; 4103
    ld [wSave_Channels+9], a    ; 4106
    ld a, [wCh4_TrackPtrLo]     ; 4109
    ld [wSave_Channels+10], a   ; 410C
    ld a, [wCh4_TrackPtrHi]     ; 410F
    ld [wSave_Channels+11], a   ; 4112
    ret                         ; 4115

;; GHX_Init: A = subsong, C = song (index into SongTable).
;; Copies the 12-byte song header to wHdr_*, clears the channel RAM and
;; switches the APU on.
InitSong:
    push af                     ; 4116
    xor a                       ; 4117
    ld [wEnabled], a            ; 4118
    pop af                      ; 411B
    ld [wSubsong], a            ; 411C
    ld a, $06                   ; 411F
    ld [wSpeed], a              ; 4121
    xor a                       ; 4124
    ld [wTickCount], a          ; 4125
    ld [wReturnFlag], a         ; 4128
    ld [wRowsLeft], a           ; 412B
    ld [wPosLeft], a            ; 412E
    ld [wOrderSel], a           ; 4131
    ld b, $00                   ; 4134
    ld hl, SongTable            ; 4136
    add hl, bc                  ; 4139
    add hl, bc                  ; 413A
    ld a, c                     ; 413B
    ld [wSong], a               ; 413C
    ld a, [hl+]                 ; 413F
    ld c, a                     ; 4140
    ld a, [hl+]                 ; 4141
    ld h, a                     ; 4142
    ld l, c                     ; 4143
    ld de, wHdr_Magic           ; 4144
    ld c, $0C                   ; 4147
InitSong_CopyHeader:
    ld a, [hl+]                 ; 4149
    ld [de], a                  ; 414A
    inc de                      ; 414B
    dec c                       ; 414C
    jr nz, InitSong_CopyHeader  ; 414D
    ld hl, wCh1_Transpose       ; 414F
    ld c, $2C                   ; 4152
    xor a                       ; 4154
.L4155:
    ld [hl+], a                 ; 4155
    ld [hl+], a                 ; 4156
    ld [hl+], a                 ; 4157
    ld [hl+], a                 ; 4158
    dec c                       ; 4159
    jr nz, .L4155               ; 415A

;; APU on: NR52 = $80, NR50 = $77, NR51 = $FF, envelopes off, player enabled.
InitAPU:
    ld a, $80                   ; 415C
    ldh [rNR52], a              ; 415E
    ld a, $77                   ; 4160
    ldh [rNR50], a              ; 4162
    and $F0                     ; 4164
    ld [wMasterVol], a          ; 4166
    ld a, $FF                   ; 4169
    ldh [rNR51], a              ; 416B
    xor a                       ; 416D
    ldh [rNR10], a              ; 416E
    ldh [rNR12], a              ; 4170
    ldh [rNR22], a              ; 4172
    ldh [rNR32], a              ; 4174
    ldh [rNR42], a              ; 4176
    ld a, $FF                   ; 4178
    ld [wEnabled], a            ; 417A
    jp PrefetchRow_NewPattern   ; 417D

;; GHX_RestoreSong: resume the song saved by GHX_SaveSong (at the start of
;; the row it was interrupted in).
RestoreSong:
    ld a, [wSaved]              ; 4180
    or a                        ; 4183
    ret z                       ; 4184
    xor a                       ; 4185
    ld [wSaved], a              ; 4186
    xor a                       ; 4189
    ld [wEnabled], a            ; 418A
    ld a, [wSave_Song]          ; 418D
    ld [wSong], a               ; 4190
    ld c, a                     ; 4193
    ld a, [wSave_Subsong]       ; 4194
    ld [wSubsong], a            ; 4197
    ld a, [wSave_Speed]         ; 419A
    ld [wSpeed], a              ; 419D
    xor a                       ; 41A0
    ld [wTickCount], a          ; 41A1
    ld [wReturnFlag], a         ; 41A4
    ld a, [wSave_RowsLeft]      ; 41A7
    ld [wRowsLeft], a           ; 41AA
    ld a, [wSave_PosLeft]       ; 41AD
    ld [wPosLeft], a            ; 41B0
    ld a, [wSave_PosPtrLo]      ; 41B3
    ld [wPosPtrLo], a           ; 41B6
    ld a, [wSave_PosPtrHi]      ; 41B9
    ld [wPosPtrHi], a           ; 41BC
    ld a, [wSave_OrderSel]      ; 41BF
    ld [wOrderSel], a           ; 41C2
    ld b, $00                   ; 41C5
    ld hl, SongTable            ; 41C7
    add hl, bc                  ; 41CA
    add hl, bc                  ; 41CB
    ld a, [hl+]                 ; 41CC
    ld c, a                     ; 41CD
    ld a, [hl+]                 ; 41CE
    ld h, a                     ; 41CF
    ld l, c                     ; 41D0
    ld de, wHdr_Magic           ; 41D1
    ld c, $0C                   ; 41D4
.L41D6:
    ld a, [hl+]                 ; 41D6
    ld [de], a                  ; 41D7
    inc de                      ; 41D8
    dec c                       ; 41D9
    jr nz, .L41D6               ; 41DA
    ld hl, wCh1_Transpose       ; 41DC
    ld de, wSave_Channels       ; 41DF
    ld b, $04                   ; 41E2
RestoreSong_Channels:
    ld a, [de]                  ; 41E4
    ld [hl+], a                 ; 41E5
    inc de                      ; 41E6
    ld a, [de]                  ; 41E7
    ld [hl+], a                 ; 41E8
    inc de                      ; 41E9
    ld a, [de]                  ; 41EA
    ld [hl+], a                 ; 41EB
    inc de                      ; 41EC
    ld c, $29                   ; 41ED
    xor a                       ; 41EF
.L41F0:
    ld [hl+], a                 ; 41F0
    dec c                       ; 41F1
    jr nz, .L41F0               ; 41F2
    dec b                       ; 41F4
    jr nz, RestoreSong_Channels ; 41F5
    jp InitAPU                  ; 41F7

;; GHX_SoundOn: re-enable the APU, keep the song position.
SoundOnImpl:
    ld a, [wEnabled]            ; 41FA
    push af                     ; 41FD
    xor a                       ; 41FE
    ld [wEnabled], a            ; 41FF
    pop af                      ; 4202
    cp $0F                      ; 4203
    jr nz, $420E                ; 4205
    ld a, $01                   ; 4207
    ld [wTickCount], a          ; 4209
    jr .L422D                   ; 420C
    ld a, $80                   ; 420E
    ldh [rNR52], a              ; 4210
    ld a, $77                   ; 4212
    ldh [rNR50], a              ; 4214
    and $F0                     ; 4216
    ld [wMasterVol], a          ; 4218
    ld a, $FF                   ; 421B
    ldh [rNR51], a              ; 421D
    ld a, [wCh1_SweepShadow]    ; 421F
    ldh [rNR10], a              ; 4222
    xor a                       ; 4224
    ldh [rNR12], a              ; 4225
    ldh [rNR22], a              ; 4227
    ldh [rNR32], a              ; 4229
    ldh [rNR42], a              ; 422B
.L422D:
    ld a, $FF                   ; 422D
    ld [wEnabled], a            ; 422F
    ld a, [wWave_PCMFlag]       ; 4232
    or a                        ; 4235
    jr z, .L4244                ; 4236
    ld a, [wTimerIESave]        ; 4238
    or a                        ; 423B
    jr z, .L4244                ; 423C
    ldh a, [rIE]                ; 423E
    or $04                      ; 4240
    ldh [rIE], a                ; 4242
.L4244:
    ret                         ; 4244

;; GHX_Stop: stop the player, NR52 = 0, forget the saved song and the speed adjust.
StopImpl:
    xor a                       ; 4245
    ld [wEnabled], a            ; 4246
    ldh [rNR52], a              ; 4249
    ld [wSaved], a              ; 424B
    ld [wSpeedAdjust], a        ; 424E
    ret                         ; 4251

;; GHX_Pause: stop the player and the APU (song state is kept).
PauseImpl:
    ld a, [wWave_PCMFlag]       ; 4252
    or a                        ; 4255
    jr z, .L4265                ; 4256
    ldh a, [rIE]                ; 4258
    and $04                     ; 425A
    ld [wTimerIESave], a        ; 425C
    ldh a, [rIE]                ; 425F
    and $FB                     ; 4261
    ldh [rIE], a                ; 4263
.L4265:
    ldh a, [rNR10]              ; 4265
    ld [wCh1_SweepShadow], a    ; 4267
    xor a                       ; 426A
    ld [wEnabled], a            ; 426B
    ldh [rNR52], a              ; 426E
    ret                         ; 4270

;; GHX_MuteMusic: wEnabled = $0F (rows stop, SFX continue), envelopes off,
;; SFX timers cleared, timer IRQ (if the game's PCM was running) disabled.
MuteMusic:
    ld a, $0F                   ; 4271
    ld [wEnabled], a            ; 4273
    xor a                       ; 4276
    ldh [rNR12], a              ; 4277
    ldh [rNR22], a              ; 4279
    ldh [rNR42], a              ; 427B
    ldh [rNR32], a              ; 427D
    ld [wCh3_SFXTimer], a       ; 427F
    ld [wCh3_PLSteps], a        ; 4282
    ld a, [wWave_PCMFlag]       ; 4285
    or a                        ; 4288
    jr z, .L4295                ; 4289
    ldh a, [rIE]                ; 428B
    and $FB                     ; 428D
    ldh [rIE], a                ; 428F
    xor a                       ; 4291
    ld [wTimerIESave], a        ; 4292
.L4295:
    ld [wCh1_SFXTimer], a       ; 4295
    ld [wCh2_SFXTimer], a       ; 4298
    ld [wCh4_SFXTimer], a       ; 429B
    ld [wCh1_PLSteps], a        ; 429E
    ld [wCh2_PLSteps], a        ; 42A1
    ld [wCh4_PLSteps], a        ; 42A4
    ret                         ; 42A7

;; GHX_Play - call once per frame.
;; A pending wReturnFlag (effect $8x) first resumes the song saved by GHX_SaveSong. Then the
;; master-volume fade (wFade: bit 7 = out, bits 0-6 = step per frame) is run.
;; wEnabled bit 7 clear (GHX_MuteMusic) = only the instrument/SFX ticks run.
;; When wTickCount reaches 0 the row that PrefetchRow read at the end of the
;; previous frame is decoded (instruments, volume, retrigger) on every channel.
PlayFrame:
    ld a, [wEnabled]            ; 42A8
    or a                        ; 42AB
    ret z                       ; 42AC
    ld a, [wReturnFlag]         ; 42AD
    or a                        ; 42B0
    jr z, .L42BA                ; 42B1
    xor a                       ; 42B3
    ld [wReturnFlag], a         ; 42B4
    jp RestoreSong              ; 42B7
.L42BA:
    ld a, [wFade]               ; 42BA
    or a                        ; 42BD
    jr z, .L42F6                ; 42BE
    bit 7, a                    ; 42C0
    jr z, .L42DC                ; 42C2
    res 7, a                    ; 42C4
    ld b, a                     ; 42C6
    ld a, [wMasterVol]          ; 42C7
    sub b                       ; 42CA
    bit 7, a                    ; 42CB
    jr z, .L42D7                ; 42CD
    xor a                       ; 42CF
    ld [wFade], a               ; 42D0
    ldh [rNR52], a              ; 42D3
    jr .L42F6                   ; 42D5
.L42D7:
    ld [wMasterVol], a          ; 42D7
    jr .L42EE                   ; 42DA
.L42DC:
    ld b, a                     ; 42DC
    ld a, [wMasterVol]          ; 42DD
    cp $70                      ; 42E0
    jr c, .L42EA                ; 42E2
    xor a                       ; 42E4
    ld [wFade], a               ; 42E5
    jr .L42F6                   ; 42E8
.L42EA:
    add a,b                     ; 42EA
    ld [wMasterVol], a          ; 42EB
.L42EE:
    and $F0                     ; 42EE
    ld b, a                     ; 42F0
    swap a                      ; 42F1
    or b                        ; 42F3
    ldh [rNR50], a              ; 42F4
.L42F6:
    ld b, $00                   ; 42F6
    ld a, [wEnabled]            ; 42F8
    bit 7, a                    ; 42FB
    jp z, Tick                  ; 42FD
    ld a, [wTickCount]          ; 4300
    bit 7, a                    ; 4303
    jp nz, Tick                 ; 4305
    or a                        ; 4308
    jp nz, Tick_Count           ; 4309

;; Row on channel 1 (bytes already fetched to wCh1_RowNote/RowIns/RowFx by
;; PrefetchRow, which also handled the $8x and $Fx effects).
Row_Ch1:
    ld hl, wRowsLeft            ; 430C
    dec [hl]                    ; 430F

;; The music is muted on a channel while its SFXTimer <> 0.
Row_Ch1_Decode:
    ld a, [wCh1_SFXTimer]       ; 4310
    or a                        ; 4313
    jp nz, Row_Ch2_Decode       ; 4314
    ld a, [wCh1_RowNote]        ; 4317
    ld e, a                     ; 431A
    ld a, e                     ; 431B
    and $3F                     ; 431C
    jr z, .L4323                ; 431E
    ld [wCh1_Note], a           ; 4320

;; Instrument byte: bits 0-5 = instrument+1 (0 = change the volume only),
;; bits 6-7 = volume shift (envelope volume >> 0/1/2/4: full, 1/2, 1/4, off).
.L4323:
    bit 6, e                    ; 4323
    jp z, Row_Ch2_Decode        ; 4325
    ld a, [wCh1_RowIns]         ; 4328
    and $3F                     ; 432B
    jp nz, Row_Ch1_LoadIns      ; 432D
    ld a, [wCh1_RowIns]         ; 4330
    and $C0                     ; 4333
    jr z, .L435E                ; 4335
    rlc a                       ; 4337
    rlc a                       ; 4339
    ld [wCh1_VolShift], a       ; 433B
    ld c, a                     ; 433E
    ld a, [wCh1_EnvShadow]      ; 433F
    and $0F                     ; 4342
    ld d, a                     ; 4344
    ldh a, [rNR12]              ; 4345
    inc c                       ; 4347
    dec c                       ; 4348
    jr z, .L4359                ; 4349
    dec c                       ; 434B
    jr z, .L4357                ; 434C
    dec c                       ; 434E
    jr z, .L4355                ; 434F
    srl a                       ; 4351
    srl a                       ; 4353
.L4355:
    srl a                       ; 4355
.L4357:
    srl a                       ; 4357
.L4359:
    and $F0                     ; 4359
    or d                        ; 435B
    ldh [rNR12], a              ; 435C
.L435E:
    jp Row_Ch1_Trigger          ; 435E

;; Square instrument: [flags: bits 0-5 = playlist steps] [playlist speed,
;; bit 7 = vibrato bytes follow] [NRx2 envelope] ([vibrato delay]
;; [depth<<4 | speed]) followed by the 3-byte playlist steps.
Row_Ch1_LoadIns:
    dec a                       ; 4361
    ld c, a                     ; 4362
    ld a, [wCh1_RowIns]         ; 4363
    and $C0                     ; 4366
    rlc a                       ; 4368
    rlc a                       ; 436A
    ld [wCh1_VolShift], a       ; 436C
    ld a, [wHdr_InstsLo]        ; 436F
    ld l, a                     ; 4372
    ld a, [wHdr_InstsHi]        ; 4373
    ld h, a                     ; 4376
    add hl, bc                  ; 4377
    add hl, bc                  ; 4378
    ld a, [hl+]                 ; 4379
    ld c, a                     ; 437A
    ld a, [hl+]                 ; 437B
    ld h, a                     ; 437C
    ld l, c                     ; 437D
    ld a, [hl+]                 ; 437E
    ld [wCh1_InsFlags], a       ; 437F
    ld d, a                     ; 4382
    ld a, [hl+]                 ; 4383
    ld [wCh1_PLSpeed], a        ; 4384
    xor a                       ; 4387
    ld [wCh1_PLTimer], a        ; 4388
    ld a, $80                   ; 438B
    ldh [rNR11], a              ; 438D
    ld a, [wCh1_VolShift]       ; 438F
    ld c, a                     ; 4392
    ld a, [hl]                  ; 4393
    ld [wCh1_EnvShadow], a      ; 4394
    and $0F                     ; 4397
    ld e, a                     ; 4399
    ld a, [hl+]                 ; 439A
    inc c                       ; 439B
    dec c                       ; 439C
    jr z, .L43AD                ; 439D
    dec c                       ; 439F
    jr z, .L43AB                ; 43A0
    dec c                       ; 43A2
    jr z, .L43A9                ; 43A3
    srl a                       ; 43A5
    srl a                       ; 43A7
.L43A9:
    srl a                       ; 43A9
.L43AB:
    srl a                       ; 43AB
.L43AD:
    and $F0                     ; 43AD
    or e                        ; 43AF
    ldh [rNR12], a              ; 43B0
    ld a, [wCh1_PLSpeed]        ; 43B2
    bit 7, a                    ; 43B5
    jr z, .L43CD                ; 43B7
    ld a, [hl+]                 ; 43B9
    ld [wCh1_VibDelay], a       ; 43BA
    ld a, [hl+]                 ; 43BD
    ld c, a                     ; 43BE
    and $0F                     ; 43BF
    ld [wCh1_VibSpeed], a       ; 43C1
    ld a, c                     ; 43C4
    and $F0                     ; 43C5
    ld [wCh1_VibDepth], a       ; 43C7
    xor a                       ; 43CA
    jr .L43D7                   ; 43CB
.L43CD:
    xor a                       ; 43CD
    ld [wCh1_VibDelay], a       ; 43CE
    ld [wCh1_VibDepth], a       ; 43D1
    ld [wCh1_VibSpeed], a       ; 43D4
.L43D7:
    ld [wCh1_VibPhase], a       ; 43D7
    ld a, d                     ; 43DA
    and $3F                     ; 43DB
    ld [wCh1_PLSteps], a        ; 43DD
    ld a, l                     ; 43E0
    ld [wCh1_PLPtrLo], a        ; 43E1
    ld a, h                     ; 43E4
    ld [wCh1_PLPtrHi], a        ; 43E5
    xor a                       ; 43E8
    cpl                         ; 43E9
    ld [wCh1_PLLoops], a        ; 43EA

;; Retrigger the channel (NRx4 bit 7).
Row_Ch1_Trigger:
    ld hl, rNR14                ; 43ED
    set 7, [hl]                 ; 43F0
Row_Ch2_Decode:
    ld a, [wCh2_SFXTimer]       ; 43F2
    or a                        ; 43F5
    jp nz, Row_Ch3_Decode       ; 43F6
    ld a, [wCh2_RowNote]        ; 43F9
    ld e, a                     ; 43FC
    ld a, e                     ; 43FD
    and $3F                     ; 43FE
    jr z, .L4405                ; 4400
    ld [wCh2_Note], a           ; 4402
.L4405:
    bit 6, e                    ; 4405
    jp z, Row_Ch3_Decode        ; 4407
    ld a, [wCh2_RowIns]         ; 440A
    and $3F                     ; 440D
    jp nz, Row_Ch2_LoadIns      ; 440F
    ld a, [wCh2_RowIns]         ; 4412
    and $C0                     ; 4415
    jr z, .L4440                ; 4417
    rlc a                       ; 4419
    rlc a                       ; 441B
    ld [wCh2_VolShift], a       ; 441D
    ld c, a                     ; 4420
    ld a, [wCh2_EnvShadow]      ; 4421
    and $0F                     ; 4424
    ld d, a                     ; 4426
    ldh a, [rNR22]              ; 4427
    inc c                       ; 4429
    dec c                       ; 442A
    jr z, .L443B                ; 442B
    dec c                       ; 442D
    jr z, .L4439                ; 442E
    dec c                       ; 4430
    jr z, .L4437                ; 4431
    srl a                       ; 4433
    srl a                       ; 4435
.L4437:
    srl a                       ; 4437
.L4439:
    srl a                       ; 4439
.L443B:
    and $F0                     ; 443B
    or d                        ; 443D
    ldh [rNR22], a              ; 443E
.L4440:
    jp Row_Ch2_Trigger          ; 4440
Row_Ch2_LoadIns:
    dec a                       ; 4443
    ld c, a                     ; 4444
    ld a, [wCh2_RowIns]         ; 4445
    and $C0                     ; 4448
    rlc a                       ; 444A
    rlc a                       ; 444C
    ld [wCh2_VolShift], a       ; 444E
    ld a, [wHdr_InstsLo]        ; 4451
    ld l, a                     ; 4454
    ld a, [wHdr_InstsHi]        ; 4455
    ld h, a                     ; 4458
    add hl, bc                  ; 4459
    add hl, bc                  ; 445A
    ld a, [hl+]                 ; 445B
    ld c, a                     ; 445C
    ld a, [hl+]                 ; 445D
    ld h, a                     ; 445E
    ld l, c                     ; 445F
    ld a, [hl+]                 ; 4460
    ld [wCh2_InsFlags], a       ; 4461
    ld d, a                     ; 4464
    ld a, [hl+]                 ; 4465
    ld [wCh2_PLSpeed], a        ; 4466
    xor a                       ; 4469
    ld [wCh2_PLTimer], a        ; 446A
    ld a, $80                   ; 446D
    ldh [rNR21], a              ; 446F
    ld a, [wCh2_VolShift]       ; 4471
    ld c, a                     ; 4474
    ld a, [hl]                  ; 4475
    ld [wCh2_EnvShadow], a      ; 4476
    and $0F                     ; 4479
    ld e, a                     ; 447B
    ld a, [hl+]                 ; 447C
    inc c                       ; 447D
    dec c                       ; 447E
    jr z, .L448F                ; 447F
    dec c                       ; 4481
    jr z, .L448D                ; 4482
    dec c                       ; 4484
    jr z, .L448B                ; 4485
    srl a                       ; 4487
    srl a                       ; 4489
.L448B:
    srl a                       ; 448B
.L448D:
    srl a                       ; 448D
.L448F:
    and $F0                     ; 448F
    or e                        ; 4491
    ldh [rNR22], a              ; 4492
    ld a, [wCh2_PLSpeed]        ; 4494
    bit 7, a                    ; 4497
    jr z, .L44AF                ; 4499
    ld a, [hl+]                 ; 449B
    ld [wCh2_VibDelay], a       ; 449C
    ld a, [hl+]                 ; 449F
    ld c, a                     ; 44A0
    and $0F                     ; 44A1
    ld [wCh2_VibSpeed], a       ; 44A3
    ld a, c                     ; 44A6
    and $F0                     ; 44A7
    ld [wCh2_VibDepth], a       ; 44A9
    xor a                       ; 44AC
    jr .L44B9                   ; 44AD
.L44AF:
    xor a                       ; 44AF
    ld [wCh2_VibDelay], a       ; 44B0
    ld [wCh2_VibDepth], a       ; 44B3
    ld [wCh2_VibSpeed], a       ; 44B6
.L44B9:
    ld [wCh2_VibPhase], a       ; 44B9
    ld a, d                     ; 44BC
    and $3F                     ; 44BD
    ld [wCh2_PLSteps], a        ; 44BF
    ld a, l                     ; 44C2
    ld [wCh2_PLPtrLo], a        ; 44C3
    ld a, h                     ; 44C6
    ld [wCh2_PLPtrHi], a        ; 44C7
    xor a                       ; 44CA
    cpl                         ; 44CB
    ld [wCh2_PLLoops], a        ; 44CC
Row_Ch2_Trigger:
    ld hl, rNR24                ; 44CF
    set 7, [hl]                 ; 44D2
Row_Ch3_Decode:
    ld a, [wCh3_SFXTimer]       ; 44D4
    or a                        ; 44D7
    jp nz, Row_Ch4_Decode       ; 44D8
    ld a, [wCh3_RowNote]        ; 44DB
    ld e, a                     ; 44DE
    ld a, e                     ; 44DF
    and $3F                     ; 44E0
    jr z, .L44E7                ; 44E2
    ld [wCh3_Note], a           ; 44E4
.L44E7:
    bit 6, e                    ; 44E7
    jp z, Row_Ch4_Decode        ; 44E9

;; Ch3: the two volume bits select the NR32 level directly (1 = 25%, 2 = 50%,
;; 3 = 100%); 0 keeps the instrument's level, or mutes on a volume-only row.
    ld a, [wCh3_RowIns]         ; 44EC
    and $3F                     ; 44EF
    jp nz, Row_Ch3_LoadIns      ; 44F1
    ld a, [wCh3_RowIns]         ; 44F4
    rrc a                       ; 44F7
    jr z, .L4501                ; 44F9
    cp $40                      ; 44FB
    jr z, .L4501                ; 44FD
    xor $40                     ; 44FF
.L4501:
    ldh [rNR32], a              ; 4501
    jp Row_Ch4_Decode           ; 4503

;; Channel-3 instrument [flags: bits 0-4 steps, bits 5-7 <> 0 = "PCM": ch3 is
;; left to the game (wWave_PCMFlag mutes the ch3 tick; the game's timer IRQ
;; enable state is saved in wTimerIESave)] [speed] [NR32] (vibrato) [sweep step]
;; [flag byte] [dw position] [dw lower] [dw upper] [sweep speed] [base lo]
;; [base hi] + steps. 16 bytes at base+position are copied to wave RAM; with
;; the sweep on the position moves by "step" every "sweep speed" ticks and
;; bounces between lower and upper.
Row_Ch3_LoadIns:
    dec a                       ; 4506
    ld c, a                     ; 4507
    ld a, [wCh3_RowIns]         ; 4508
    and $C0                     ; 450B
    jr z, .L4517                ; 450D
    rrc a                       ; 450F
    cp $40                      ; 4511
    jr z, .L4517                ; 4513
    xor $40                     ; 4515
.L4517:
    ld [wCh3_VolShift], a       ; 4517
    ld a, [wHdr_InstsLo]        ; 451A
    ld l, a                     ; 451D
    ld a, [wHdr_InstsHi]        ; 451E
    ld h, a                     ; 4521
    add hl, bc                  ; 4522
    add hl, bc                  ; 4523
    ld a, [hl+]                 ; 4524
    ld c, a                     ; 4525
    ld a, [hl+]                 ; 4526
    ld h, a                     ; 4527
    ld l, c                     ; 4528
    ld a, [hl+]                 ; 4529
    ld [wCh3_InsFlags], a       ; 452A
    ld d, a                     ; 452D
    and $E0                     ; 452E
    ld [wWave_PCMFlag], a       ; 4530
    ld a, [hl+]                 ; 4533
    ld [wCh3_PLSpeed], a        ; 4534
    xor a                       ; 4537
    ld [wCh3_PLTimer], a        ; 4538
    ld a, [wCh3_VolShift]       ; 453B
    or a                        ; 453E
    jr z, .L4544                ; 453F
    inc hl                      ; 4541
    jr .L4545                   ; 4542
.L4544:
    ld a, [hl+]                 ; 4544
.L4545:
    ldh [rNR32], a              ; 4545
    xor a                       ; 4547
    ld [wCh3_VolShift], a       ; 4548
    ld a, [wCh3_PLSpeed]        ; 454B
    bit 7, a                    ; 454E
    jr z, .L4566                ; 4550
    ld a, [hl+]                 ; 4552
    ld [wCh3_VibDelay], a       ; 4553
    ld a, [hl+]                 ; 4556
    ld c, a                     ; 4557
    and $0F                     ; 4558
    ld [wCh3_VibSpeed], a       ; 455A
    ld a, c                     ; 455D
    and $F0                     ; 455E
    ld [wCh3_VibDepth], a       ; 4560
    xor a                       ; 4563
    jr .L4570                   ; 4564
.L4566:
    xor a                       ; 4566
    ld [wCh3_VibDelay], a       ; 4567
    ld [wCh3_VibDepth], a       ; 456A
    ld [wCh3_VibSpeed], a       ; 456D
.L4570:
    ld [wCh3_VibPhase], a       ; 4570
    ld a, [hl+]                 ; 4573
    ld [wWave_Step], a          ; 4574
    xor a                       ; 4577
    ld [wWave_SweepOn], a       ; 4578
    ld [wWave_FlagHi], a        ; 457B
    ld a, [hl+]                 ; 457E
    bit 7, a                    ; 457F
    jr z, .L4586                ; 4581
    ld [wWave_FlagHi], a        ; 4583
.L4586:
    and $7F                     ; 4586
    ld [wWave_FlagLo], a        ; 4588
    ld a, [hl+]                 ; 458B
    ld [wWave_PosLo], a         ; 458C
    ld a, [hl+]                 ; 458F
    ld [wWave_PosHi], a         ; 4590
    ld a, [hl+]                 ; 4593
    ld [wWave_LowerLo], a       ; 4594
    ld a, [hl+]                 ; 4597
    ld [wWave_LowerHi], a       ; 4598
    ld a, [hl+]                 ; 459B
    ld [wWave_UpperLo], a       ; 459C
    ld a, [hl+]                 ; 459F
    ld [wWave_UpperHi], a       ; 45A0
    ld a, [hl+]                 ; 45A3
    ld [wWave_SweepSpeed], a    ; 45A4
    ld [wWave_SweepTimer], a    ; 45A7
    ld a, [hl+]                 ; 45AA
    ld [wWave_BaseLo], a        ; 45AB
    ld a, [hl+]                 ; 45AE
    ld [wWave_BaseHi], a        ; 45AF
    ld a, d                     ; 45B2
    and $3F                     ; 45B3
    ld [wCh3_PLSteps], a        ; 45B5
    ld a, l                     ; 45B8
    ld [wCh3_PLPtrLo], a        ; 45B9
    ld a, h                     ; 45BC
    ld [wCh3_PLPtrHi], a        ; 45BD
    xor a                       ; 45C0
    cpl                         ; 45C1
    ld [wCh3_PLLoops], a        ; 45C2
    ld a, $FF                   ; 45C5
    ld [wWave_WaveUpdate], a    ; 45C7
Row_Ch4_Decode:
    ld a, [wCh4_SFXTimer]       ; 45CA
    or a                        ; 45CD
    jp nz, Row_Done             ; 45CE
    ld a, [wCh4_RowNote]        ; 45D1
    ld e, a                     ; 45D4
    ld a, e                     ; 45D5
    and $3F                     ; 45D6
    jr z, .L45DD                ; 45D8
    ld [wCh4_Note], a           ; 45DA
.L45DD:
    bit 6, e                    ; 45DD
    jp z, Row_Done              ; 45DF
    ld a, [wCh4_RowIns]         ; 45E2
    and $3F                     ; 45E5
    jp nz, Row_Ch4_LoadIns      ; 45E7
    ld a, [wCh4_RowIns]         ; 45EA
    and $C0                     ; 45ED
    jr z, .L4618                ; 45EF
    rlc a                       ; 45F1
    rlc a                       ; 45F3
    ld [wCh4_VolShift], a       ; 45F5
    ld c, a                     ; 45F8
    ld a, [wCh4_EnvShadow]      ; 45F9
    and $0F                     ; 45FC
    ld d, a                     ; 45FE
    ldh a, [rNR42]              ; 45FF
    inc c                       ; 4601
    dec c                       ; 4602
    jr z, .L4613                ; 4603
    dec c                       ; 4605
    jr z, .L4611                ; 4606
    dec c                       ; 4608
    jr z, .L460F                ; 4609
    srl a                       ; 460B
    srl a                       ; 460D
.L460F:
    srl a                       ; 460F
.L4611:
    srl a                       ; 4611
.L4613:
    and $F0                     ; 4613
    or d                        ; 4615
    ldh [rNR42], a              ; 4616
.L4618:
    jp Row_Ch4_Trigger          ; 4618
Row_Ch4_LoadIns:
    dec a                       ; 461B
    ld c, a                     ; 461C
    ld a, [wCh4_RowIns]         ; 461D
    and $C0                     ; 4620
    rlc a                       ; 4622
    rlc a                       ; 4624
    ld [wCh4_VolShift], a       ; 4626
    ld a, [wHdr_InstsLo]        ; 4629
    ld l, a                     ; 462C
    ld a, [wHdr_InstsHi]        ; 462D
    ld h, a                     ; 4630
    add hl, bc                  ; 4631
    add hl, bc                  ; 4632
    ld a, [hl+]                 ; 4633
    ld c, a                     ; 4634
    ld a, [hl+]                 ; 4635
    ld h, a                     ; 4636
    ld l, c                     ; 4637
    ld a, [hl+]                 ; 4638
    ld [wCh4_InsFlags], a       ; 4639
    ld d, a                     ; 463C
    ld a, [hl+]                 ; 463D
    ld [wCh4_PLSpeed], a        ; 463E
    xor a                       ; 4641
    ld [wCh4_PLTimer], a        ; 4642
    ld a, $00                   ; 4645
    ldh [rNR41], a              ; 4647
    ld a, [wCh4_VolShift]       ; 4649
    ld c, a                     ; 464C
    ld a, [hl]                  ; 464D
    ld [wCh4_EnvShadow], a      ; 464E
    and $0F                     ; 4651
    ld e, a                     ; 4653
    ld a, [hl+]                 ; 4654
    inc c                       ; 4655
    dec c                       ; 4656
    jr z, .L4667                ; 4657
    dec c                       ; 4659
    jr z, .L4665                ; 465A
    dec c                       ; 465C
    jr z, .L4663                ; 465D
    srl a                       ; 465F
    srl a                       ; 4661
.L4663:
    srl a                       ; 4663
.L4665:
    srl a                       ; 4665
.L4667:
    and $F0                     ; 4667
    or e                        ; 4669
    ldh [rNR42], a              ; 466A
    ld a, d                     ; 466C
    and $3F                     ; 466D
    ld [wCh4_PLSteps], a        ; 466F
    ld a, l                     ; 4672
    ld [wCh4_PLPtrLo], a        ; 4673
    ld a, h                     ; 4676
    ld [wCh4_PLPtrHi], a        ; 4677
    xor a                       ; 467A
    cpl                         ; 467B
    ld [wCh4_PLLoops], a        ; 467C
Row_Ch4_Trigger:
    ld hl, rNR44                ; 467F
    set 7, [hl]                 ; 4682

;; Row done: wTickCount = speed - wSpeedAdjust.
Row_Done:
    ld a, [wSpeedAdjust]        ; 4684
    ld c, a                     ; 4687
    ld a, [wSpeed]              ; 4688
    sub c                       ; 468B
    ld [wTickCount], a          ; 468C
Tick_Count:
    ld hl, wTickCount           ; 468F
    dec [hl]                    ; 4692

;; Per-tick processing of all four channels: instrument playlist, vibrato,
;; frequency. Playlist step = [note] [cmd] [cmd].
;; Note byte: bits 0-5 note (0 = keep), bit 6 = absolute note, otherwise
;; relative to the row note (+transpose; 1 = unison).
;; Command: $00 none, $01-$3F new playlist speed, $40|v volume v (NRx2
;; high nibble, retrigger; ch3: NR32 level), $80|n jump back n steps,
;; $C0|x: bits 2-5 = loop count for the next jump (0 = keep; the default $FF
;; loops forever), bits 0-1 = duty on ch1/2 (3 = keep the duty); on ch3 the
;; command toggles the wave sweep (unless only a loop count is given).
Tick:
    ld a, [wCh1_SFXTimer]       ; 4693
    or a                        ; 4696
    jr z, Tick_Ch1              ; 4697
    dec a                       ; 4699
    ld [wCh1_SFXTimer], a       ; 469A

;; Channel 1 playlist.
Tick_Ch1:
    ld a, [wCh1_PLTimer]        ; 469D
    or a                        ; 46A0
    jp nz, Tick_Ch1_Pitch       ; 46A1
    ld a, [wCh1_PLSteps]        ; 46A4
    or a                        ; 46A7
    jp z, Tick_Ch1_PLWait       ; 46A8
    dec a                       ; 46AB
    ld [wCh1_PLSteps], a        ; 46AC
    ld a, [wCh1_PLPtrLo]        ; 46AF
    ld l, a                     ; 46B2
    ld a, [wCh1_PLPtrHi]        ; 46B3
    ld h, a                     ; 46B6
    ld a, [hl+]                 ; 46B7
    ld [wCh1_PLNoteRaw], a      ; 46B8
    and $3F                     ; 46BB
    jr z, .L46C2                ; 46BD
    ld [wCh1_PLNote], a         ; 46BF
.L46C2:
    ld a, [hl+]                 ; 46C2
    bit 7, a                    ; 46C3
    jr nz, .L4704               ; 46C5
    bit 6, a                    ; 46C7
    jr nz, .L46D5               ; 46C9
    and $3F                     ; 46CB
    jr z, .L46D2                ; 46CD
    ld [wCh1_PLSpeed], a        ; 46CF
.L46D2:
    jp .L4732                   ; 46D2
.L46D5:
    swap a                      ; 46D5
    ld d, a                     ; 46D7
    ld a, [wCh1_VolShift]       ; 46D8
    ld c, a                     ; 46DB
    ld a, d                     ; 46DC
    inc c                       ; 46DD
    dec c                       ; 46DE
    jr z, .L46EF                ; 46DF
    dec c                       ; 46E1
    jr z, .L46ED                ; 46E2
    dec c                       ; 46E4
    jr z, .L46EB                ; 46E5
    srl a                       ; 46E7
    srl a                       ; 46E9
.L46EB:
    srl a                       ; 46EB
.L46ED:
    srl a                       ; 46ED
.L46EF:
    and $F0                     ; 46EF
    ld c, a                     ; 46F1
    ld a, [wCh1_EnvShadow]      ; 46F2
    and $0F                     ; 46F5
    or c                        ; 46F7
    ldh [rNR12], a              ; 46F8
    push hl                     ; 46FA
    ld hl, rNR14                ; 46FB
    set 7, [hl]                 ; 46FE
    pop hl                      ; 4700
    jp .L4732                   ; 4701
.L4704:
    bit 6, a                    ; 4704
    jr nz, .L471D               ; 4706
    and $3F                     ; 4708
    ld d, a                     ; 470A
    cpl                         ; 470B
    inc a                       ; 470C
    ld c, a                     ; 470D
    dec b                       ; 470E
    add hl, bc                  ; 470F
    add hl, bc                  ; 4710
    add hl, bc                  ; 4711
    inc b                       ; 4712
    ld a, [wCh1_PLSteps]        ; 4713
    ld c, d                     ; 4716
    add a,c                     ; 4717
    ld [wCh1_PLSteps], a        ; 4718
    jr .L4732                   ; 471B
.L471D:
    rrc a                       ; 471D
    rrc a                       ; 471F
    ld d, a                     ; 4721
    and $C0                     ; 4722
    cp $C0                      ; 4724
    jr z, .L472A                ; 4726
    ldh [rNR11], a              ; 4728
.L472A:
    ld a, d                     ; 472A
    and $0F                     ; 472B
    jr z, .L4732                ; 472D
    ld [wCh1_PLLoops], a        ; 472F
.L4732:
    ld a, [hl+]                 ; 4732
    bit 7, a                    ; 4733
    jr nz, .L4774               ; 4735
    bit 6, a                    ; 4737
    jr nz, .L4745               ; 4739
    and $3F                     ; 473B
    jr z, .L4742                ; 473D
    ld [wCh1_PLSpeed], a        ; 473F
.L4742:
    jp .L47A2                   ; 4742
.L4745:
    swap a                      ; 4745
    ld d, a                     ; 4747
    ld a, [wCh1_VolShift]       ; 4748
    ld c, a                     ; 474B
    ld a, d                     ; 474C
    inc c                       ; 474D
    dec c                       ; 474E
    jr z, .L475F                ; 474F
    dec c                       ; 4751
    jr z, .L475D                ; 4752
    dec c                       ; 4754
    jr z, .L475B                ; 4755
    srl a                       ; 4757
    srl a                       ; 4759
.L475B:
    srl a                       ; 475B
.L475D:
    srl a                       ; 475D
.L475F:
    and $F0                     ; 475F
    ld c, a                     ; 4761
    ld a, [wCh1_EnvShadow]      ; 4762
    and $0F                     ; 4765
    or c                        ; 4767
    ldh [rNR12], a              ; 4768
    push hl                     ; 476A
    ld hl, rNR14                ; 476B
    set 7, [hl]                 ; 476E
    pop hl                      ; 4770
    jp .L47A2                   ; 4771
.L4774:
    bit 6, a                    ; 4774
    jr nz, .L478D               ; 4776
    and $3F                     ; 4778
    ld d, a                     ; 477A
    cpl                         ; 477B
    inc a                       ; 477C
    ld c, a                     ; 477D
    dec b                       ; 477E
    add hl, bc                  ; 477F
    add hl, bc                  ; 4780
    add hl, bc                  ; 4781
    inc b                       ; 4782
    ld a, [wCh1_PLSteps]        ; 4783
    ld c, d                     ; 4786
    add a,c                     ; 4787
    ld [wCh1_PLSteps], a        ; 4788
    jr .L47A2                   ; 478B
.L478D:
    rrc a                       ; 478D
    rrc a                       ; 478F
    ld d, a                     ; 4791
    and $C0                     ; 4792
    cp $C0                      ; 4794
    jr z, .L479A                ; 4796
    ldh [rNR11], a              ; 4798
.L479A:
    ld a, d                     ; 479A
    and $0F                     ; 479B
    jr z, .L47A2                ; 479D
    ld [wCh1_PLLoops], a        ; 479F
.L47A2:
    ld a, l                     ; 47A2
    ld [wCh1_PLPtrLo], a        ; 47A3
    ld a, h                     ; 47A6
    ld [wCh1_PLPtrHi], a        ; 47A7
Tick_Ch1_PLWait:
    ld a, [wCh1_PLSpeed]        ; 47AA
    res 7, a                    ; 47AD
    ld [wCh1_PLTimer], a        ; 47AF

;; Frequency = FreqTable[transpose + row note + playlist note - 1] (or the
;; absolute playlist note) + vibrato. Vibrato: after VibDelay ticks the phase
;; advances by VibSpeed (6 bits) and VibratoTable[depth | phase>>2] is added.
Tick_Ch1_Pitch:
    ld hl, wCh1_PLTimer         ; 47B2
    dec [hl]                    ; 47B5
    ld a, [wCh1_PLNote]         ; 47B6
    ld c, a                     ; 47B9
    ld a, [wCh1_PLNoteRaw]      ; 47BA
    bit 6, a                    ; 47BD
    jr nz, .L47CC               ; 47BF
    ld a, [wCh1_Transpose]      ; 47C1
    add a,c                     ; 47C4
    ld c, a                     ; 47C5
    ld a, [wCh1_Note]           ; 47C6
    add a,c                     ; 47C9
    dec a                       ; 47CA
    ld c, a                     ; 47CB
.L47CC:
    ld hl, FreqTable            ; 47CC
    add hl, bc                  ; 47CF
    add hl, bc                  ; 47D0
    ld c, $00                   ; 47D1
    ld a, [wCh1_VibDepth]       ; 47D3
    or a                        ; 47D6
    jr z, .L480A                ; 47D7
    ld a, [wCh1_VibDelay]       ; 47D9
    dec a                       ; 47DC
    cp $FF                      ; 47DD
    jr z, .L47E6                ; 47DF
    ld [wCh1_VibDelay], a       ; 47E1
    jr .L480A                   ; 47E4
.L47E6:
    ld a, [wCh1_VibSpeed]       ; 47E6
    ld c, a                     ; 47E9
    ld a, [wCh1_VibPhase]       ; 47EA
    add a,c                     ; 47ED
    and $3F                     ; 47EE
    ld [wCh1_VibPhase], a       ; 47F0
    srl a                       ; 47F3
    srl a                       ; 47F5
    ld c, a                     ; 47F7
    ld a, [wCh1_VibDepth]       ; 47F8
    or c                        ; 47FB
    ld c, a                     ; 47FC
    push hl                     ; 47FD
    ld hl, VibratoTable         ; 47FE
    add hl, bc                  ; 4801
    ld a, [hl]                  ; 4802
    pop hl                      ; 4803
    ld c, a                     ; 4804
    bit 7, a                    ; 4805
    jr z, .L480A                ; 4807
    dec b                       ; 4809
.L480A:
    ld a, [hl+]                 ; 480A
    ld e, a                     ; 480B
    ld a, [hl]                  ; 480C
    ld h, a                     ; 480D
    ld l, e                     ; 480E
    add hl, bc                  ; 480F
    ld b, $00                   ; 4810
    ld a, l                     ; 4812
    ldh [rNR13], a              ; 4813
    ld a, h                     ; 4815
    ldh [rNR14], a              ; 4816

;; Channel 2 tick.
Tick_Ch2:
    ld a, [wCh2_SFXTimer]       ; 4818
    or a                        ; 481B
    jr z, .L4822                ; 481C
    dec a                       ; 481E
    ld [wCh2_SFXTimer], a       ; 481F
.L4822:
    ld a, [wCh2_PLTimer]        ; 4822
    or a                        ; 4825
    jp nz, Tick_Ch2_Pitch       ; 4826
    ld a, [wCh2_PLSteps]        ; 4829
    or a                        ; 482C
    jp z, Tick_Ch2_PLWait       ; 482D
    dec a                       ; 4830
    ld [wCh2_PLSteps], a        ; 4831
    ld a, [wCh2_PLPtrLo]        ; 4834
    ld l, a                     ; 4837
    ld a, [wCh2_PLPtrHi]        ; 4838
    ld h, a                     ; 483B
    ld a, [hl+]                 ; 483C
    ld [wCh2_PLNoteRaw], a      ; 483D
    and $3F                     ; 4840
    jr z, .L4847                ; 4842
    ld [wCh2_PLNote], a         ; 4844
.L4847:
    ld a, [hl+]                 ; 4847
    bit 7, a                    ; 4848
    jr nz, .L4889               ; 484A
    bit 6, a                    ; 484C
    jr nz, .L485A               ; 484E
    and $3F                     ; 4850
    jr z, .L4857                ; 4852
    ld [wCh2_PLSpeed], a        ; 4854
.L4857:
    jp .L48B7                   ; 4857
.L485A:
    swap a                      ; 485A
    ld d, a                     ; 485C
    ld a, [wCh2_VolShift]       ; 485D
    ld c, a                     ; 4860
    ld a, d                     ; 4861
    inc c                       ; 4862
    dec c                       ; 4863
    jr z, .L4874                ; 4864
    dec c                       ; 4866
    jr z, .L4872                ; 4867
    dec c                       ; 4869
    jr z, .L4870                ; 486A
    srl a                       ; 486C
    srl a                       ; 486E
.L4870:
    srl a                       ; 4870
.L4872:
    srl a                       ; 4872
.L4874:
    and $F0                     ; 4874
    ld c, a                     ; 4876
    ld a, [wCh2_EnvShadow]      ; 4877
    and $0F                     ; 487A
    or c                        ; 487C
    ldh [rNR22], a              ; 487D
    push hl                     ; 487F
    ld hl, rNR24                ; 4880
    set 7, [hl]                 ; 4883
    pop hl                      ; 4885
    jp .L48B7                   ; 4886
.L4889:
    bit 6, a                    ; 4889
    jr nz, .L48A2               ; 488B
    and $3F                     ; 488D
    ld d, a                     ; 488F
    cpl                         ; 4890
    inc a                       ; 4891
    ld c, a                     ; 4892
    dec b                       ; 4893
    add hl, bc                  ; 4894
    add hl, bc                  ; 4895
    add hl, bc                  ; 4896
    inc b                       ; 4897
    ld a, [wCh2_PLSteps]        ; 4898
    ld c, d                     ; 489B
    add a,c                     ; 489C
    ld [wCh2_PLSteps], a        ; 489D
    jr .L48B7                   ; 48A0
.L48A2:
    rrc a                       ; 48A2
    rrc a                       ; 48A4
    ld d, a                     ; 48A6
    and $C0                     ; 48A7
    cp $C0                      ; 48A9
    jr z, .L48AF                ; 48AB
    ldh [rNR21], a              ; 48AD
.L48AF:
    ld a, d                     ; 48AF
    and $0F                     ; 48B0
    jr z, .L48B7                ; 48B2
    ld [wCh2_PLLoops], a        ; 48B4
.L48B7:
    ld a, [hl+]                 ; 48B7
    bit 7, a                    ; 48B8
    jr nz, .L48F9               ; 48BA
    bit 6, a                    ; 48BC
    jr nz, .L48CA               ; 48BE
    and $3F                     ; 48C0
    jr z, .L48C7                ; 48C2
    ld [wCh2_PLSpeed], a        ; 48C4
.L48C7:
    jp .L4927                   ; 48C7
.L48CA:
    swap a                      ; 48CA
    ld d, a                     ; 48CC
    ld a, [wCh2_VolShift]       ; 48CD
    ld c, a                     ; 48D0
    ld a, d                     ; 48D1
    inc c                       ; 48D2
    dec c                       ; 48D3
    jr z, .L48E4                ; 48D4
    dec c                       ; 48D6
    jr z, .L48E2                ; 48D7
    dec c                       ; 48D9
    jr z, .L48E0                ; 48DA
    srl a                       ; 48DC
    srl a                       ; 48DE
.L48E0:
    srl a                       ; 48E0
.L48E2:
    srl a                       ; 48E2
.L48E4:
    and $F0                     ; 48E4
    ld c, a                     ; 48E6
    ld a, [wCh2_EnvShadow]      ; 48E7
    and $0F                     ; 48EA
    or c                        ; 48EC
    ldh [rNR22], a              ; 48ED
    push hl                     ; 48EF
    ld hl, rNR24                ; 48F0
    set 7, [hl]                 ; 48F3
    pop hl                      ; 48F5
    jp .L4927                   ; 48F6
.L48F9:
    bit 6, a                    ; 48F9
    jr nz, .L4912               ; 48FB
    and $3F                     ; 48FD
    ld d, a                     ; 48FF
    cpl                         ; 4900
    inc a                       ; 4901
    ld c, a                     ; 4902
    dec b                       ; 4903
    add hl, bc                  ; 4904
    add hl, bc                  ; 4905
    add hl, bc                  ; 4906
    inc b                       ; 4907
    ld a, [wCh2_PLSteps]        ; 4908
    ld c, d                     ; 490B
    add a,c                     ; 490C
    ld [wCh2_PLSteps], a        ; 490D
    jr .L4927                   ; 4910
.L4912:
    rrc a                       ; 4912
    rrc a                       ; 4914
    ld d, a                     ; 4916
    and $C0                     ; 4917
    cp $C0                      ; 4919
    jr z, .L491F                ; 491B
    ldh [rNR21], a              ; 491D
.L491F:
    ld a, d                     ; 491F
    and $0F                     ; 4920
    jr z, .L4927                ; 4922
    ld [wCh2_PLLoops], a        ; 4924
.L4927:
    ld a, l                     ; 4927
    ld [wCh2_PLPtrLo], a        ; 4928
    ld a, h                     ; 492B
    ld [wCh2_PLPtrHi], a        ; 492C
Tick_Ch2_PLWait:
    ld a, [wCh2_PLSpeed]        ; 492F
    res 7, a                    ; 4932
    ld [wCh2_PLTimer], a        ; 4934
Tick_Ch2_Pitch:
    ld hl, wCh2_PLTimer         ; 4937
    dec [hl]                    ; 493A
    ld a, [wCh2_PLNote]         ; 493B
    ld c, a                     ; 493E
    ld a, [wCh2_PLNoteRaw]      ; 493F
    bit 6, a                    ; 4942
    jr nz, .L4951               ; 4944
    ld a, [wCh2_Transpose]      ; 4946
    add a,c                     ; 4949
    ld c, a                     ; 494A
    ld a, [wCh2_Note]           ; 494B
    add a,c                     ; 494E
    dec a                       ; 494F
    ld c, a                     ; 4950
.L4951:
    ld hl, FreqTable            ; 4951
    add hl, bc                  ; 4954
    add hl, bc                  ; 4955
    ld c, $00                   ; 4956
    ld a, [wCh2_VibDepth]       ; 4958
    or a                        ; 495B
    jr z, .L498F                ; 495C
    ld a, [wCh2_VibDelay]       ; 495E
    dec a                       ; 4961
    cp $FF                      ; 4962
    jr z, .L496B                ; 4964
    ld [wCh2_VibDelay], a       ; 4966
    jr .L498F                   ; 4969
.L496B:
    ld a, [wCh2_VibSpeed]       ; 496B
    ld c, a                     ; 496E
    ld a, [wCh2_VibPhase]       ; 496F
    add a,c                     ; 4972
    and $3F                     ; 4973
    ld [wCh2_VibPhase], a       ; 4975
    srl a                       ; 4978
    srl a                       ; 497A
    ld c, a                     ; 497C
    ld a, [wCh2_VibDepth]       ; 497D
    or c                        ; 4980
    ld c, a                     ; 4981
    push hl                     ; 4982
    ld hl, VibratoTable         ; 4983
    add hl, bc                  ; 4986
    ld a, [hl]                  ; 4987
    pop hl                      ; 4988
    ld c, a                     ; 4989
    bit 7, a                    ; 498A
    jr z, .L498F                ; 498C
    dec b                       ; 498E
.L498F:
    ld a, [hl+]                 ; 498F
    ld e, a                     ; 4990
    ld a, [hl]                  ; 4991
    ld h, a                     ; 4992
    ld l, e                     ; 4993
    add hl, bc                  ; 4994
    ld b, $00                   ; 4995
    ld a, l                     ; 4997
    ldh [rNR23], a              ; 4998
    ld a, h                     ; 499A
    ldh [rNR24], a              ; 499B

;; Channel 3 tick (skipped completely while wWave_PCMFlag is set).
Tick_Ch3:
    ld a, [wWave_PCMFlag]       ; 499D
    or a                        ; 49A0
    jp nz, Tick_Ch4             ; 49A1
    ld a, [wCh3_SFXTimer]       ; 49A4
    or a                        ; 49A7
    jr z, .L49B3                ; 49A8
    cp $FF                      ; 49AA
    jp z, .L49B3                ; 49AC
    dec a                       ; 49AF
    ld [wCh3_SFXTimer], a       ; 49B0
.L49B3:
    ld a, [wCh3_PLTimer]        ; 49B3
    or a                        ; 49B6
    jp nz, Tick_Ch3_Sweep       ; 49B7
    ld a, [wCh3_PLSteps]        ; 49BA
    or a                        ; 49BD
    jp z, Tick_Ch3_PLWait       ; 49BE
    dec a                       ; 49C1
    ld [wCh3_PLSteps], a        ; 49C2
    ld a, [wCh3_PLPtrLo]        ; 49C5
    ld l, a                     ; 49C8
    ld a, [wCh3_PLPtrHi]        ; 49C9
    ld h, a                     ; 49CC
    ld a, [hl+]                 ; 49CD
    ld [wCh3_PLNoteRaw], a      ; 49CE
    and $3F                     ; 49D1
    jr z, .L49D8                ; 49D3
    ld [wCh3_PLNote], a         ; 49D5
.L49D8:
    ld a, [hl+]                 ; 49D8
    bit 7, a                    ; 49D9
    jr nz, .L49FD               ; 49DB
    bit 6, a                    ; 49DD
    jr nz, .L49EB               ; 49DF
    and $3F                     ; 49E1
    jr z, .L49E8                ; 49E3
    ld [wCh3_PLSpeed], a        ; 49E5
.L49E8:
    jp .L4A2E                   ; 49E8
.L49EB:
    and $3F                     ; 49EB
    jr z, .L49F8                ; 49ED
    add a,a                     ; 49EF
    swap a                      ; 49F0
    cp $40                      ; 49F2
    jr z, .L49F8                ; 49F4
    xor $40                     ; 49F6
.L49F8:
    ldh [rNR32], a              ; 49F8
    jp .L4A2E                   ; 49FA
.L49FD:
    bit 6, a                    ; 49FD
    jr nz, .L4A16               ; 49FF
    and $3F                     ; 4A01
    ld d, a                     ; 4A03
    cpl                         ; 4A04
    inc a                       ; 4A05
    ld c, a                     ; 4A06
    dec b                       ; 4A07
    add hl, bc                  ; 4A08
    add hl, bc                  ; 4A09
    add hl, bc                  ; 4A0A
    inc b                       ; 4A0B
    ld a, [wCh3_PLSteps]        ; 4A0C
    ld c, d                     ; 4A0F
    add a,c                     ; 4A10
    ld [wCh3_PLSteps], a        ; 4A11
    jr .L4A2E                   ; 4A14
.L4A16:
    ld d, a                     ; 4A16
    rrc a                       ; 4A17
    rrc a                       ; 4A19
    and $0F                     ; 4A1B
    jr z, .L4A27                ; 4A1D
    ld [wCh3_PLLoops], a        ; 4A1F
    ld a, d                     ; 4A22
    and $03                     ; 4A23
    jr z, .L4A2E                ; 4A25
.L4A27:
    ld a, [wWave_SweepOn]       ; 4A27
    cpl                         ; 4A2A
    ld [wWave_SweepOn], a       ; 4A2B
.L4A2E:
    ld a, [hl+]                 ; 4A2E
    bit 7, a                    ; 4A2F
    jr nz, .L4A53               ; 4A31
    bit 6, a                    ; 4A33
    jr nz, .L4A41               ; 4A35
    and $3F                     ; 4A37
    jr z, .L4A3E                ; 4A39
    ld [wCh3_PLSpeed], a        ; 4A3B
.L4A3E:
    jp .L4A84                   ; 4A3E
.L4A41:
    and $3F                     ; 4A41
    jr z, .L4A4E                ; 4A43
    add a,a                     ; 4A45
    swap a                      ; 4A46
    cp $40                      ; 4A48
    jr z, .L4A4E                ; 4A4A
    xor $40                     ; 4A4C
.L4A4E:
    ldh [rNR32], a              ; 4A4E
    jp .L4A84                   ; 4A50
.L4A53:
    bit 6, a                    ; 4A53
    jr nz, .L4A6C               ; 4A55
    and $3F                     ; 4A57
    ld d, a                     ; 4A59
    cpl                         ; 4A5A
    inc a                       ; 4A5B
    ld c, a                     ; 4A5C
    dec b                       ; 4A5D
    add hl, bc                  ; 4A5E
    add hl, bc                  ; 4A5F
    add hl, bc                  ; 4A60
    inc b                       ; 4A61
    ld a, [wCh3_PLSteps]        ; 4A62
    ld c, d                     ; 4A65
    add a,c                     ; 4A66
    ld [wCh3_PLSteps], a        ; 4A67
    jr .L4A84                   ; 4A6A
.L4A6C:
    ld d, a                     ; 4A6C
    rrc a                       ; 4A6D
    rrc a                       ; 4A6F
    and $0F                     ; 4A71
    jr z, .L4A7D                ; 4A73
    ld [wCh3_PLLoops], a        ; 4A75
    ld a, d                     ; 4A78
    and $03                     ; 4A79
    jr z, .L4A84                ; 4A7B
.L4A7D:
    ld a, [wWave_SweepOn]       ; 4A7D
    cpl                         ; 4A80
    ld [wWave_SweepOn], a       ; 4A81
.L4A84:
    ld a, l                     ; 4A84
    ld [wCh3_PLPtrLo], a        ; 4A85
    ld a, h                     ; 4A88
    ld [wCh3_PLPtrHi], a        ; 4A89
Tick_Ch3_PLWait:
    ld a, [wCh3_PLSpeed]        ; 4A8C
    res 7, a                    ; 4A8F
    ld [wCh3_PLTimer], a        ; 4A91

;; Wave sweep: move the window position between the bounds.
Tick_Ch3_Sweep:
    ld hl, wCh3_PLTimer         ; 4A94
    dec [hl]                    ; 4A97
    ld a, [wWave_SweepOn]       ; 4A98
    or a                        ; 4A9B
    jp z, Tick_Ch3_WaveRAM      ; 4A9C
    ld a, [wWave_SweepTimer]    ; 4A9F
    or a                        ; 4AA2
    jp nz, .L4AFA               ; 4AA3
    ld a, [wWave_PosHi]         ; 4AA6
    ld h, a                     ; 4AA9
    ld a, [wWave_PosLo]         ; 4AAA
    ld l, a                     ; 4AAD
    ld a, [wWave_Step]          ; 4AAE
    ld c, a                     ; 4AB1
    bit 7, c                    ; 4AB2
    jr z, .L4AD5                ; 4AB4
    dec b                       ; 4AB6
    add hl, bc                  ; 4AB7
    inc b                       ; 4AB8
    ld a, h                     ; 4AB9
    ld [wWave_PosHi], a         ; 4ABA
    ld a, l                     ; 4ABD
    ld [wWave_PosLo], a         ; 4ABE
    ld a, [wWave_LowerLo]       ; 4AC1
    cp l                        ; 4AC4
    jr nz, .L4AD3               ; 4AC5
    ld a, [wWave_LowerHi]       ; 4AC7
    cp h                        ; 4ACA
    jr nz, .L4AD3               ; 4ACB
    ld a, c                     ; 4ACD
    cpl                         ; 4ACE
    inc a                       ; 4ACF
    ld [wWave_Step], a          ; 4AD0
.L4AD3:
    jr .L4AF0                   ; 4AD3
.L4AD5:
    add hl, bc                  ; 4AD5
    ld a, h                     ; 4AD6
    ld [wWave_PosHi], a         ; 4AD7
    ld a, l                     ; 4ADA
    ld [wWave_PosLo], a         ; 4ADB
    ld a, [wWave_UpperLo]       ; 4ADE
    cp l                        ; 4AE1
    jr nz, .L4AF0               ; 4AE2
    ld a, [wWave_UpperHi]       ; 4AE4
    cp h                        ; 4AE7
    jr nz, .L4AF0               ; 4AE8
    ld a, c                     ; 4AEA
    cpl                         ; 4AEB
    inc a                       ; 4AEC
    ld [wWave_Step], a          ; 4AED
.L4AF0:
    ld hl, wWave_WaveUpdate     ; 4AF0
    dec [hl]                    ; 4AF3
    ld a, [wWave_SweepSpeed]    ; 4AF4
    ld [wWave_SweepTimer], a    ; 4AF7
.L4AFA:
    ld hl, wWave_SweepTimer     ; 4AFA
    dec [hl]                    ; 4AFD

;; wWave_Update = $FF: copy 16 bytes from base+position into wave RAM.
Tick_Ch3_WaveRAM:
    ld a, [wWave_WaveUpdate]    ; 4AFE
    inc a                       ; 4B01
    jp nz, Tick_Ch3_Pitch       ; 4B02
    ld [wWave_WaveUpdate], a    ; 4B05
    ld a, [wWave_BaseLo]        ; 4B08
    ld c, a                     ; 4B0B
    ld a, [wWave_PosLo]         ; 4B0C
    add a,c                     ; 4B0F
    ld e, a                     ; 4B10
    ld a, [wWave_BaseHi]        ; 4B11
    ld c, a                     ; 4B14
    ld a, [wWave_PosHi]         ; 4B15
    adc a,c                     ; 4B18
    ld d, a                     ; 4B19
    ld hl, _AUD3WAVERAM         ; 4B1A
    xor a                       ; 4B1D
    ldh [rNR30], a              ; 4B1E
    ld a, [de]                  ; 4B20
    inc de                      ; 4B21
    ld [hl+], a                 ; 4B22
    ld a, [de]                  ; 4B23
    inc de                      ; 4B24
    ld [hl+], a                 ; 4B25
    ld a, [de]                  ; 4B26
    inc de                      ; 4B27
    ld [hl+], a                 ; 4B28
    ld a, [de]                  ; 4B29
    inc de                      ; 4B2A
    ld [hl+], a                 ; 4B2B
    ld a, [de]                  ; 4B2C
    inc de                      ; 4B2D
    ld [hl+], a                 ; 4B2E
    ld a, [de]                  ; 4B2F
    inc de                      ; 4B30
    ld [hl+], a                 ; 4B31
    ld a, [de]                  ; 4B32
    inc de                      ; 4B33
    ld [hl+], a                 ; 4B34
    ld a, [de]                  ; 4B35
    inc de                      ; 4B36
    ld [hl+], a                 ; 4B37
    ld a, [de]                  ; 4B38
    inc de                      ; 4B39
    ld [hl+], a                 ; 4B3A
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
    ld a, $80                   ; 4B50
    ldh [rNR30], a              ; 4B52
    ld hl, rNR34                ; 4B54
    set 7, [hl]                 ; 4B57
    ld a, $FF                   ; 4B59
    ldh [rNR51], a              ; 4B5B
    xor a                       ; 4B5D
    ldh [rNR31], a              ; 4B5E
Tick_Ch3_Pitch:
    xor a                       ; 4B60
    ldh [rNR31], a              ; 4B61
    ld a, [wCh3_PLNote]         ; 4B63
    ld c, a                     ; 4B66
    ld a, [wCh3_PLNoteRaw]      ; 4B67
    bit 6, a                    ; 4B6A
    jr nz, .L4B79               ; 4B6C
    ld a, [wCh3_Transpose]      ; 4B6E
    add a,c                     ; 4B71
    ld c, a                     ; 4B72
    ld a, [wCh3_Note]           ; 4B73
    add a,c                     ; 4B76
    dec a                       ; 4B77
    ld c, a                     ; 4B78
.L4B79:
    ld hl, FreqTable            ; 4B79
    add hl, bc                  ; 4B7C
    add hl, bc                  ; 4B7D
    ld c, $00                   ; 4B7E
    ld a, [wCh3_VibDepth]       ; 4B80
    or a                        ; 4B83
    jr z, .L4BB7                ; 4B84
    ld a, [wCh3_VibDelay]       ; 4B86
    dec a                       ; 4B89
    cp $FF                      ; 4B8A
    jr z, .L4B93                ; 4B8C
    ld [wCh3_VibDelay], a       ; 4B8E
    jr .L4BB7                   ; 4B91
.L4B93:
    ld a, [wCh3_VibSpeed]       ; 4B93
    ld c, a                     ; 4B96
    ld a, [wCh3_VibPhase]       ; 4B97
    add a,c                     ; 4B9A
    and $3F                     ; 4B9B
    ld [wCh3_VibPhase], a       ; 4B9D
    srl a                       ; 4BA0
    srl a                       ; 4BA2
    ld c, a                     ; 4BA4
    ld a, [wCh3_VibDepth]       ; 4BA5
    or c                        ; 4BA8
    ld c, a                     ; 4BA9
    push hl                     ; 4BAA
    ld hl, VibratoTable         ; 4BAB
    add hl, bc                  ; 4BAE
    ld a, [hl]                  ; 4BAF
    pop hl                      ; 4BB0
    ld c, a                     ; 4BB1
    bit 7, a                    ; 4BB2
    jr z, .L4BB7                ; 4BB4
    dec b                       ; 4BB6
.L4BB7:
    ld a, [hl+]                 ; 4BB7
    ld e, a                     ; 4BB8
    ld a, [hl]                  ; 4BB9
    ld h, a                     ; 4BBA
    ld l, e                     ; 4BBB
    add hl, bc                  ; 4BBC
    ld b, $00                   ; 4BBD
    ld a, l                     ; 4BBF
    ldh [rNR33], a              ; 4BC0
    ld a, h                     ; 4BC2
    ldh [rNR34], a              ; 4BC3
    xor a                       ; 4BC5
    ldh [rNR31], a              ; 4BC6

;; Channel 4 tick: NR43 = NoiseTable[(note + PLnote - 2) / 2].
Tick_Ch4:
    ld a, [wCh4_SFXTimer]       ; 4BC8
    or a                        ; 4BCB
    jr z, .L4BD2                ; 4BCC
    dec a                       ; 4BCE
    ld [wCh4_SFXTimer], a       ; 4BCF
.L4BD2:
    ld a, [wCh4_PLTimer]        ; 4BD2
    or a                        ; 4BD5
    jp nz, Tick_Ch4_Noise       ; 4BD6
    ld a, [wCh4_PLSteps]        ; 4BD9
    or a                        ; 4BDC
    jp z, Tick_Ch4_PLWait       ; 4BDD
    dec a                       ; 4BE0
    ld [wCh4_PLSteps], a        ; 4BE1
    ld a, [wCh4_PLPtrLo]        ; 4BE4
    ld l, a                     ; 4BE7
    ld a, [wCh4_PLPtrHi]        ; 4BE8
    ld h, a                     ; 4BEB
    ld a, [hl+]                 ; 4BEC
    ld [wCh4_PLNoteRaw], a      ; 4BED
    and $3F                     ; 4BF0
    jr z, .L4BF7                ; 4BF2
    ld [wCh4_PLNote], a         ; 4BF4
.L4BF7:
    ld a, [hl+]                 ; 4BF7
    bit 7, a                    ; 4BF8
    jr nz, .L4C39               ; 4BFA
    bit 6, a                    ; 4BFC
    jr nz, .L4C0A               ; 4BFE
    and $3F                     ; 4C00
    jr z, .L4C07                ; 4C02
    ld [wCh4_PLSpeed], a        ; 4C04
.L4C07:
    jp .L4C52                   ; 4C07
.L4C0A:
    swap a                      ; 4C0A
    ld d, a                     ; 4C0C
    ld a, [wCh4_VolShift]       ; 4C0D
    ld c, a                     ; 4C10
    ld a, d                     ; 4C11
    inc c                       ; 4C12
    dec c                       ; 4C13
    jr z, .L4C24                ; 4C14
    dec c                       ; 4C16
    jr z, .L4C22                ; 4C17
    dec c                       ; 4C19
    jr z, .L4C20                ; 4C1A
    srl a                       ; 4C1C
    srl a                       ; 4C1E
.L4C20:
    srl a                       ; 4C20
.L4C22:
    srl a                       ; 4C22
.L4C24:
    and $F0                     ; 4C24
    ld c, a                     ; 4C26
    ld a, [wCh4_EnvShadow]      ; 4C27
    and $0F                     ; 4C2A
    or c                        ; 4C2C
    ldh [rNR42], a              ; 4C2D
    push hl                     ; 4C2F
    ld hl, rNR44                ; 4C30
    set 7, [hl]                 ; 4C33
    pop hl                      ; 4C35
    jp .L4C52                   ; 4C36
.L4C39:
    bit 6, a                    ; 4C39
    jr nz, .L4C52               ; 4C3B
    and $3F                     ; 4C3D
    ld d, a                     ; 4C3F
    cpl                         ; 4C40
    inc a                       ; 4C41
    ld c, a                     ; 4C42
    dec b                       ; 4C43
    add hl, bc                  ; 4C44
    add hl, bc                  ; 4C45
    add hl, bc                  ; 4C46
    inc b                       ; 4C47
    ld a, [wCh4_PLSteps]        ; 4C48
    ld c, d                     ; 4C4B
    add a,c                     ; 4C4C
    ld [wCh4_PLSteps], a        ; 4C4D
    jr .L4C52                   ; 4C50
.L4C52:
    ld a, [hl+]                 ; 4C52
    bit 7, a                    ; 4C53
    jr nz, .L4C94               ; 4C55
    bit 6, a                    ; 4C57
    jr nz, .L4C65               ; 4C59
    and $3F                     ; 4C5B
    jr z, .L4C62                ; 4C5D
    ld [wCh4_PLSpeed], a        ; 4C5F
.L4C62:
    jp .L4CAD                   ; 4C62
.L4C65:
    swap a                      ; 4C65
    ld d, a                     ; 4C67
    ld a, [wCh4_VolShift]       ; 4C68
    ld c, a                     ; 4C6B
    ld a, d                     ; 4C6C
    inc c                       ; 4C6D
    dec c                       ; 4C6E
    jr z, .L4C7F                ; 4C6F
    dec c                       ; 4C71
    jr z, .L4C7D                ; 4C72
    dec c                       ; 4C74
    jr z, .L4C7B                ; 4C75
    srl a                       ; 4C77
    srl a                       ; 4C79
.L4C7B:
    srl a                       ; 4C7B
.L4C7D:
    srl a                       ; 4C7D
.L4C7F:
    and $F0                     ; 4C7F
    ld c, a                     ; 4C81
    ld a, [wCh4_EnvShadow]      ; 4C82
    and $0F                     ; 4C85
    or c                        ; 4C87
    ldh [rNR42], a              ; 4C88
    push hl                     ; 4C8A
    ld hl, rNR44                ; 4C8B
    set 7, [hl]                 ; 4C8E
    pop hl                      ; 4C90
    jp .L4CAD                   ; 4C91
.L4C94:
    bit 6, a                    ; 4C94
    jr nz, .L4CAD               ; 4C96
    and $3F                     ; 4C98
    ld d, a                     ; 4C9A
    cpl                         ; 4C9B
    inc a                       ; 4C9C
    ld c, a                     ; 4C9D
    dec b                       ; 4C9E
    add hl, bc                  ; 4C9F
    add hl, bc                  ; 4CA0
    add hl, bc                  ; 4CA1
    inc b                       ; 4CA2
    ld a, [wCh4_PLSteps]        ; 4CA3
    ld c, d                     ; 4CA6
    add a,c                     ; 4CA7
    ld [wCh4_PLSteps], a        ; 4CA8
    jr .L4CAD                   ; 4CAB
.L4CAD:
    ld a, l                     ; 4CAD
    ld [wCh4_PLPtrLo], a        ; 4CAE
    ld a, h                     ; 4CB1
    ld [wCh4_PLPtrHi], a        ; 4CB2
Tick_Ch4_PLWait:
    ld a, [wCh4_PLSpeed]        ; 4CB5
    res 7, a                    ; 4CB8
    ld [wCh4_PLTimer], a        ; 4CBA
Tick_Ch4_Noise:
    ld hl, wCh4_PLTimer         ; 4CBD
    dec [hl]                    ; 4CC0
    ld a, [wCh4_PLNoteRaw]      ; 4CC1
    ld e, a                     ; 4CC4
    ld a, [wCh4_PLNote]         ; 4CC5
    bit 6, e                    ; 4CC8
    jr nz, .L4CD2               ; 4CCA
    ld c, a                     ; 4CCC
    ld a, [wCh4_Note]           ; 4CCD
    add a,c                     ; 4CD0
    dec a                       ; 4CD1
.L4CD2:
    dec a                       ; 4CD2
    srl a                       ; 4CD3
    ld c, a                     ; 4CD5
    ld hl, NoiseTable           ; 4CD6
    add hl, bc                  ; 4CD9
    ld a, [hl]                  ; 4CDA
    ldh [rNR43], a              ; 4CDB

;; Row prefetch (new in this build): at the end of the frame in which the row
;; counter reached 0, the next row of every channel is read (and the next
;; position if the pattern is finished) so the new row starts on time next frame.
PrefetchRow:
    ld a, [wTickCount]          ; 4CDD
    or a                        ; 4CE0
    ret nz                      ; 4CE1
    ld a, [wRowsLeft]           ; 4CE2
    or a                        ; 4CE5
    jp nz, PrefetchRow_Read     ; 4CE6
PrefetchRow_NewPattern:
    ld a, [wHdr_PatLen]         ; 4CE9
    ld [wRowsLeft], a           ; 4CEC
    ld a, [wPosLeft]            ; 4CEF
    or a                        ; 4CF2
    jp nz, NextPosition         ; 4CF3
    ld a, [wHdr_OrdersLo]       ; 4CF6
    ld l, a                     ; 4CF9
    ld a, [wHdr_OrdersHi]       ; 4CFA
    ld h, a                     ; 4CFD
    ld a, [wOrderSel]           ; 4CFE
    ld c, a                     ; 4D01
    or $01                      ; 4D02
    ld [wOrderSel], a           ; 4D04
    ld a, [wSubsong]            ; 4D07
    add a,a                     ; 4D0A
    add a,c                     ; 4D0B
    ld c, a                     ; 4D0C
    add hl, bc                  ; 4D0D
    add hl, bc                  ; 4D0E
    add hl, bc                  ; 4D0F
    ld a, [hl+]                 ; 4D10
    ld [wPosLeft], a            ; 4D11
    ld a, [hl+]                 ; 4D14
    ld c, a                     ; 4D15
    ld a, [hl+]                 ; 4D16
    ld h, a                     ; 4D17
    ld l, c                     ; 4D18
    jr ReadPosition             ; 4D19
NextPosition:
    ld a, [wPosPtrLo]           ; 4D1B
    ld l, a                     ; 4D1E
    ld a, [wPosPtrHi]           ; 4D1F
    ld h, a                     ; 4D22
    ld a, [wPosLeft]            ; 4D23
    dec a                       ; 4D26
    ld [wPosLeft], a            ; 4D27

;; Position = 7 bytes again (as in the 1999 engine): track ch1, transpose ch1,
;; track ch2, transpose ch2, track ch3, transpose ch3, track ch4; track numbers
;; index the song's track pointer table (wHdr_Tracks).
ReadPosition:
    ld a, [hl+]                 ; 4D2A
    ld [wCh1_TrackNum], a       ; 4D2B
    ld a, [hl+]                 ; 4D2E
    ld [wCh1_Transpose], a      ; 4D2F
    ld a, [hl+]                 ; 4D32
    ld [wCh2_TrackNum], a       ; 4D33
    ld a, [hl+]                 ; 4D36
    ld [wCh2_Transpose], a      ; 4D37
    ld a, [hl+]                 ; 4D3A
    ld [wCh3_TrackNum], a       ; 4D3B
    ld a, [hl+]                 ; 4D3E
    ld [wCh3_Transpose], a      ; 4D3F
    ld a, [hl+]                 ; 4D42
    ld [wCh4_TrackNum], a       ; 4D43
    ld a, l                     ; 4D46
    ld [wPosPtrLo], a           ; 4D47
    ld a, h                     ; 4D4A
    ld [wPosPtrHi], a           ; 4D4B
    ld a, [wHdr_TracksLo]       ; 4D4E
    ld l, a                     ; 4D51
    ld a, [wHdr_TracksHi]       ; 4D52
    ld h, a                     ; 4D55
    push hl                     ; 4D56
    ld a, [wCh1_TrackNum]       ; 4D57
    ld c, a                     ; 4D5A
    add hl, bc                  ; 4D5B
    add hl, bc                  ; 4D5C
    ld a, [hl+]                 ; 4D5D
    ld [wCh1_TrackPtrLo], a     ; 4D5E
    ld a, [hl+]                 ; 4D61
    ld [wCh1_TrackPtrHi], a     ; 4D62
    pop hl                      ; 4D65
    push hl                     ; 4D66
    ld a, [wCh2_TrackNum]       ; 4D67
    ld c, a                     ; 4D6A
    add hl, bc                  ; 4D6B
    add hl, bc                  ; 4D6C
    ld a, [hl+]                 ; 4D6D
    ld [wCh2_TrackPtrLo], a     ; 4D6E
    ld a, [hl+]                 ; 4D71
    ld [wCh2_TrackPtrHi], a     ; 4D72
    pop hl                      ; 4D75
    push hl                     ; 4D76
    ld a, [wCh3_TrackNum]       ; 4D77
    ld c, a                     ; 4D7A
    add hl, bc                  ; 4D7B
    add hl, bc                  ; 4D7C
    ld a, [hl+]                 ; 4D7D
    ld [wCh3_TrackPtrLo], a     ; 4D7E
    ld a, [hl+]                 ; 4D81
    ld [wCh3_TrackPtrHi], a     ; 4D82
    pop hl                      ; 4D85
    ld a, [wCh4_TrackNum]       ; 4D86
    ld c, a                     ; 4D89
    add hl, bc                  ; 4D8A
    add hl, bc                  ; 4D8B
    ld a, [hl+]                 ; 4D8C
    ld [wCh4_TrackPtrLo], a     ; 4D8D
    ld a, [hl+]                 ; 4D90
    ld [wCh4_TrackPtrHi], a     ; 4D91
PrefetchRow_Read:
    ld a, [wCh1_TrackPtrLo]     ; 4D94
    ld l, a                     ; 4D97
    ld a, [wCh1_TrackPtrHi]     ; 4D98
    ld h, a                     ; 4D9B
    ld a, [hl+]                 ; 4D9C
    ld [wCh1_RowNote], a        ; 4D9D
    ld e, a                     ; 4DA0
    bit 6, e                    ; 4DA1
    jr z, .L4DA9                ; 4DA3
    ld a, [hl+]                 ; 4DA5
    ld [wCh1_RowIns], a         ; 4DA6
.L4DA9:
    bit 7, e                    ; 4DA9
    jr z, .L4DB1                ; 4DAB
    ld a, [hl+]                 ; 4DAD
    ld [wCh1_RowFx], a          ; 4DAE
.L4DB1:
    ld a, l                     ; 4DB1
    ld [wCh1_TrackPtrLo], a     ; 4DB2
    ld a, h                     ; 4DB5
    ld [wCh1_TrackPtrHi], a     ; 4DB6
    bit 7, e                    ; 4DB9
    jr z, .L4DD9                ; 4DBB
    ld a, [wCh1_RowFx]          ; 4DBD
    ld c, a                     ; 4DC0
    swap c                      ; 4DC1
    and $0F                     ; 4DC3
    sub $08                     ; 4DC5
    jr nz, .L4DCF               ; 4DC7
    ld a, c                     ; 4DC9
    and $0F                     ; 4DCA
    ld [wReturnFlag], a         ; 4DCC
.L4DCF:
    sub $07                     ; 4DCF
    jr nz, .L4DD9               ; 4DD1
    ld a, c                     ; 4DD3
    and $0F                     ; 4DD4
    ld [wSpeed], a              ; 4DD6
.L4DD9:
    ld a, [wCh2_TrackPtrLo]     ; 4DD9
    ld l, a                     ; 4DDC
    ld a, [wCh2_TrackPtrHi]     ; 4DDD
    ld h, a                     ; 4DE0
    ld a, [hl+]                 ; 4DE1
    ld [wCh2_RowNote], a        ; 4DE2
    ld e, a                     ; 4DE5
    bit 6, e                    ; 4DE6
    jr z, .L4DEE                ; 4DE8
    ld a, [hl+]                 ; 4DEA
    ld [wCh2_RowIns], a         ; 4DEB
.L4DEE:
    bit 7, e                    ; 4DEE
    jr z, .L4DF6                ; 4DF0
    ld a, [hl+]                 ; 4DF2
    ld [wCh2_RowFx], a          ; 4DF3
.L4DF6:
    ld a, l                     ; 4DF6
    ld [wCh2_TrackPtrLo], a     ; 4DF7
    ld a, h                     ; 4DFA
    ld [wCh2_TrackPtrHi], a     ; 4DFB
    bit 7, e                    ; 4DFE
    jr z, .L4E1E                ; 4E00
    ld a, [wCh2_RowFx]          ; 4E02
    ld c, a                     ; 4E05
    swap c                      ; 4E06
    and $0F                     ; 4E08
    sub $08                     ; 4E0A
    jr nz, .L4E14               ; 4E0C
    ld a, c                     ; 4E0E
    and $0F                     ; 4E0F
    ld [wReturnFlag], a         ; 4E11
.L4E14:
    sub $07                     ; 4E14
    jr nz, .L4E1E               ; 4E16
    ld a, c                     ; 4E18
    and $0F                     ; 4E19
    ld [wSpeed], a              ; 4E1B
.L4E1E:
    ld a, [wCh3_TrackPtrLo]     ; 4E1E
    ld l, a                     ; 4E21
    ld a, [wCh3_TrackPtrHi]     ; 4E22
    ld h, a                     ; 4E25
    ld a, [hl+]                 ; 4E26
    ld [wCh3_RowNote], a        ; 4E27
    ld e, a                     ; 4E2A
    bit 6, e                    ; 4E2B
    jr z, .L4E33                ; 4E2D
    ld a, [hl+]                 ; 4E2F
    ld [wCh3_RowIns], a         ; 4E30
.L4E33:
    bit 7, e                    ; 4E33
    jr z, .L4E3B                ; 4E35
    ld a, [hl+]                 ; 4E37
    ld [wCh3_RowFx], a          ; 4E38
.L4E3B:
    ld a, l                     ; 4E3B
    ld [wCh3_TrackPtrLo], a     ; 4E3C
    ld a, h                     ; 4E3F
    ld [wCh3_TrackPtrHi], a     ; 4E40
    bit 7, e                    ; 4E43
    jr z, .L4E63                ; 4E45
    ld a, [wCh3_RowFx]          ; 4E47
    ld c, a                     ; 4E4A
    swap c                      ; 4E4B
    and $0F                     ; 4E4D
    sub $08                     ; 4E4F
    jr nz, .L4E59               ; 4E51
    ld a, c                     ; 4E53
    and $0F                     ; 4E54
    ld [wReturnFlag], a         ; 4E56
.L4E59:
    sub $07                     ; 4E59
    jr nz, .L4E63               ; 4E5B
    ld a, c                     ; 4E5D
    and $0F                     ; 4E5E
    ld [wSpeed], a              ; 4E60
.L4E63:
    ld a, [wCh4_TrackPtrLo]     ; 4E63
    ld l, a                     ; 4E66
    ld a, [wCh4_TrackPtrHi]     ; 4E67
    ld h, a                     ; 4E6A
    ld a, [hl+]                 ; 4E6B
    ld [wCh4_RowNote], a        ; 4E6C
    ld e, a                     ; 4E6F
    bit 6, e                    ; 4E70
    jr z, .L4E78                ; 4E72
    ld a, [hl+]                 ; 4E74
    ld [wCh4_RowIns], a         ; 4E75
.L4E78:
    bit 7, e                    ; 4E78
    jr z, .L4E80                ; 4E7A
    ld a, [hl+]                 ; 4E7C
    ld [wCh4_RowFx], a          ; 4E7D
.L4E80:
    ld a, l                     ; 4E80
    ld [wCh4_TrackPtrLo], a     ; 4E81
    ld a, h                     ; 4E84
    ld [wCh4_TrackPtrHi], a     ; 4E85
    bit 7, e                    ; 4E88
    jr z, .L4EA8                ; 4E8A
    ld a, [wCh4_RowFx]          ; 4E8C
    ld c, a                     ; 4E8F
    swap c                      ; 4E90
    and $0F                     ; 4E92
    sub $08                     ; 4E94
    jr nz, .L4E9E               ; 4E96
    ld a, c                     ; 4E98
    and $0F                     ; 4E99
    ld [wReturnFlag], a         ; 4E9B
.L4E9E:
    sub $07                     ; 4E9E
    jr nz, .L4EA8               ; 4EA0
    ld a, c                     ; 4EA2
    and $0F                     ; 4EA3
    ld [wSpeed], a              ; 4EA5
.L4EA8:
    ret                         ; 4EA8

;; GHX_PlaySFX: A = effect. SFXTable entry (5 bytes) = [ins ch1] [ins ch2] [ins ch3]
;; [ins ch4] [time]. Instruments are 1-based indices into SFXInstTable (0 =
;; channel unused); the music on a used channel is muted for "time" ticks
;; ($FF on ch3 = until the next song). The player is held (wEnabled = 0)
;; while the instruments are set up.
PlaySFX:
    ld c, a                     ; 4EA9
    ld a, [wEnabled]            ; 4EAA
    push af                     ; 4EAD
    xor a                       ; 4EAE
    ld [wEnabled], a            ; 4EAF
    ld a, c                     ; 4EB2
    ld e, a                     ; 4EB3
    add a,a                     ; 4EB4
    add a,a                     ; 4EB5
    add a,c                     ; 4EB6
    ld c, a                     ; 4EB7
    ld a, $00                   ; 4EB8
    adc a,$00                   ; 4EBA
    ld b, a                     ; 4EBC
    ld hl, SFXTable             ; 4EBD
    add hl, bc                  ; 4EC0
    ld b, $00                   ; 4EC1
    ld a, [hl+]                 ; 4EC3
    ld [wSFX_Ch1], a            ; 4EC4
    ld a, [hl+]                 ; 4EC7
    ld [wSFX_Ch2], a            ; 4EC8
    ld a, [hl+]                 ; 4ECB
    ld [wSFX_Ch3], a            ; 4ECC
    ld a, [hl+]                 ; 4ECF
    ld [wSFX_Ch4], a            ; 4ED0
    ld a, [hl+]                 ; 4ED3
    ld [wSFX_Time], a           ; 4ED4
PlaySFX_Ch1:
    ld a, [wSFX_Ch1]            ; 4ED7
    or a                        ; 4EDA
    jp z, PlaySFX_Ch2           ; 4EDB
    dec a                       ; 4EDE
    ld hl, SFXInstTable         ; 4EDF
    ld c, a                     ; 4EE2
    add hl, bc                  ; 4EE3
    add hl, bc                  ; 4EE4
    ld a, [hl+]                 ; 4EE5
    ld c, a                     ; 4EE6
    ld a, [hl+]                 ; 4EE7
    ld h, a                     ; 4EE8
    ld l, c                     ; 4EE9
    xor a                       ; 4EEA
    ld [wCh1_VolShift], a       ; 4EEB
    ld a, [hl+]                 ; 4EEE
    ld [wCh1_InsFlags], a       ; 4EEF
    ld d, a                     ; 4EF2
    ld a, [hl+]                 ; 4EF3
    ld [wCh1_PLSpeed], a        ; 4EF4
    xor a                       ; 4EF7
    ld [wCh1_PLTimer], a        ; 4EF8
    ld a, $80                   ; 4EFB
    ldh [rNR11], a              ; 4EFD
    ld a, [wCh1_VolShift]       ; 4EFF
    ld c, a                     ; 4F02
    ld a, [hl]                  ; 4F03
    ld [wCh1_EnvShadow], a      ; 4F04
    and $0F                     ; 4F07
    ld e, a                     ; 4F09
    ld a, [hl+]                 ; 4F0A
    inc c                       ; 4F0B
    dec c                       ; 4F0C
    jr z, .L4F1D                ; 4F0D
    dec c                       ; 4F0F
    jr z, .L4F1B                ; 4F10
    dec c                       ; 4F12
    jr z, .L4F19                ; 4F13
    srl a                       ; 4F15
    srl a                       ; 4F17
.L4F19:
    srl a                       ; 4F19
.L4F1B:
    srl a                       ; 4F1B
.L4F1D:
    and $F0                     ; 4F1D
    or e                        ; 4F1F
    ldh [rNR12], a              ; 4F20
    ld a, [wCh1_PLSpeed]        ; 4F22
    bit 7, a                    ; 4F25
    jr z, .L4F3D                ; 4F27
    ld a, [hl+]                 ; 4F29
    ld [wCh1_VibDelay], a       ; 4F2A
    ld a, [hl+]                 ; 4F2D
    ld c, a                     ; 4F2E
    and $0F                     ; 4F2F
    ld [wCh1_VibSpeed], a       ; 4F31
    ld a, c                     ; 4F34
    and $F0                     ; 4F35
    ld [wCh1_VibDepth], a       ; 4F37
    xor a                       ; 4F3A
    jr .L4F47                   ; 4F3B
.L4F3D:
    xor a                       ; 4F3D
    ld [wCh1_VibDelay], a       ; 4F3E
    ld [wCh1_VibDepth], a       ; 4F41
    ld [wCh1_VibSpeed], a       ; 4F44
.L4F47:
    ld [wCh1_VibPhase], a       ; 4F47
    ld a, d                     ; 4F4A
    and $3F                     ; 4F4B
    ld [wCh1_PLSteps], a        ; 4F4D
    ld a, l                     ; 4F50
    ld [wCh1_PLPtrLo], a        ; 4F51
    ld a, h                     ; 4F54
    ld [wCh1_PLPtrHi], a        ; 4F55
    xor a                       ; 4F58
    cpl                         ; 4F59
    ld [wCh1_PLLoops], a        ; 4F5A
    ld hl, rNR14                ; 4F5D
    set 7, [hl]                 ; 4F60
    ld a, [wSFX_Time]           ; 4F62
    ld [wCh1_SFXTimer], a       ; 4F65
PlaySFX_Ch2:
    ld a, [wSFX_Ch2]            ; 4F68
    or a                        ; 4F6B
    jp z, PlaySFX_Ch3           ; 4F6C
    dec a                       ; 4F6F
    ld hl, SFXInstTable         ; 4F70
    ld c, a                     ; 4F73
    add hl, bc                  ; 4F74
    add hl, bc                  ; 4F75
    ld a, [hl+]                 ; 4F76
    ld c, a                     ; 4F77
    ld a, [hl+]                 ; 4F78
    ld h, a                     ; 4F79
    ld l, c                     ; 4F7A
    xor a                       ; 4F7B
    ld [wCh2_VolShift], a       ; 4F7C
    ld a, [hl+]                 ; 4F7F
    ld [wCh2_InsFlags], a       ; 4F80
    ld d, a                     ; 4F83
    ld a, [hl+]                 ; 4F84
    ld [wCh2_PLSpeed], a        ; 4F85
    xor a                       ; 4F88
    ld [wCh2_PLTimer], a        ; 4F89
    ld a, $80                   ; 4F8C
    ldh [rNR21], a              ; 4F8E
    ld a, [wCh2_VolShift]       ; 4F90
    ld c, a                     ; 4F93
    ld a, [hl]                  ; 4F94
    ld [wCh2_EnvShadow], a      ; 4F95
    and $0F                     ; 4F98
    ld e, a                     ; 4F9A
    ld a, [hl+]                 ; 4F9B
    inc c                       ; 4F9C
    dec c                       ; 4F9D
    jr z, .L4FAE                ; 4F9E
    dec c                       ; 4FA0
    jr z, .L4FAC                ; 4FA1
    dec c                       ; 4FA3
    jr z, .L4FAA                ; 4FA4
    srl a                       ; 4FA6
    srl a                       ; 4FA8
.L4FAA:
    srl a                       ; 4FAA
.L4FAC:
    srl a                       ; 4FAC
.L4FAE:
    and $F0                     ; 4FAE
    or e                        ; 4FB0
    ldh [rNR22], a              ; 4FB1
    ld a, [wCh2_PLSpeed]        ; 4FB3
    bit 7, a                    ; 4FB6
    jr z, .L4FCE                ; 4FB8
    ld a, [hl+]                 ; 4FBA
    ld [wCh2_VibDelay], a       ; 4FBB
    ld a, [hl+]                 ; 4FBE
    ld c, a                     ; 4FBF
    and $0F                     ; 4FC0
    ld [wCh2_VibSpeed], a       ; 4FC2
    ld a, c                     ; 4FC5
    and $F0                     ; 4FC6
    ld [wCh2_VibDepth], a       ; 4FC8
    xor a                       ; 4FCB
    jr .L4FD8                   ; 4FCC
.L4FCE:
    xor a                       ; 4FCE
    ld [wCh2_VibDelay], a       ; 4FCF
    ld [wCh2_VibDepth], a       ; 4FD2
    ld [wCh2_VibSpeed], a       ; 4FD5
.L4FD8:
    ld [wCh2_VibPhase], a       ; 4FD8
    ld a, d                     ; 4FDB
    and $3F                     ; 4FDC
    ld [wCh2_PLSteps], a        ; 4FDE
    ld a, l                     ; 4FE1
    ld [wCh2_PLPtrLo], a        ; 4FE2
    ld a, h                     ; 4FE5
    ld [wCh2_PLPtrHi], a        ; 4FE6
    xor a                       ; 4FE9
    cpl                         ; 4FEA
    ld [wCh2_PLLoops], a        ; 4FEB
    ld hl, rNR24                ; 4FEE
    set 7, [hl]                 ; 4FF1
    ld a, [wSFX_Time]           ; 4FF3
    ld [wCh2_SFXTimer], a       ; 4FF6
PlaySFX_Ch3:
    ld a, [wSFX_Ch3]            ; 4FF9
    or a                        ; 4FFC
    jp z, PlaySFX_Ch4           ; 4FFD
    dec a                       ; 5000
    ld hl, SFXInstTable         ; 5001
    ld c, a                     ; 5004
    add hl, bc                  ; 5005
    add hl, bc                  ; 5006
    ld a, [hl+]                 ; 5007
    ld c, a                     ; 5008
    ld a, [hl+]                 ; 5009
    ld h, a                     ; 500A
    ld l, c                     ; 500B
    ld a, [hl+]                 ; 500C
    ld [wCh3_InsFlags], a       ; 500D
    ld d, a                     ; 5010
    and $E0                     ; 5011
    ld [wWave_PCMFlag], a       ; 5013
    ld a, [hl+]                 ; 5016
    ld [wCh3_PLSpeed], a        ; 5017
    xor a                       ; 501A
    ld [wCh3_PLTimer], a        ; 501B
    ld a, [wCh3_VolShift]       ; 501E
    or a                        ; 5021
    jr z, .L5027                ; 5022
    inc hl                      ; 5024
    jr .L5028                   ; 5025
.L5027:
    ld a, [hl+]                 ; 5027
.L5028:
    ldh [rNR32], a              ; 5028
    xor a                       ; 502A
    ld [wCh3_VolShift], a       ; 502B
    ld a, [wCh3_PLSpeed]        ; 502E
    bit 7, a                    ; 5031
    jr z, .L5049                ; 5033
    ld a, [hl+]                 ; 5035
    ld [wCh3_VibDelay], a       ; 5036
    ld a, [hl+]                 ; 5039
    ld c, a                     ; 503A
    and $0F                     ; 503B
    ld [wCh3_VibSpeed], a       ; 503D
    ld a, c                     ; 5040
    and $F0                     ; 5041
    ld [wCh3_VibDepth], a       ; 5043
    xor a                       ; 5046
    jr .L5053                   ; 5047
.L5049:
    xor a                       ; 5049
    ld [wCh3_VibDelay], a       ; 504A
    ld [wCh3_VibDepth], a       ; 504D
    ld [wCh3_VibSpeed], a       ; 5050
.L5053:
    ld [wCh3_VibPhase], a       ; 5053
    ld a, [hl+]                 ; 5056
    ld [wWave_Step], a          ; 5057
    xor a                       ; 505A
    ld [wWave_SweepOn], a       ; 505B
    ld [wWave_FlagHi], a        ; 505E
    ld a, [hl+]                 ; 5061
    bit 7, a                    ; 5062
    jr z, .L5069                ; 5064
    ld [wWave_FlagHi], a        ; 5066
.L5069:
    and $7F                     ; 5069
    ld [wWave_FlagLo], a        ; 506B
    ld a, [hl+]                 ; 506E
    ld [wWave_PosLo], a         ; 506F
    ld a, [hl+]                 ; 5072
    ld [wWave_PosHi], a         ; 5073
    ld a, [hl+]                 ; 5076
    ld [wWave_LowerLo], a       ; 5077
    ld a, [hl+]                 ; 507A
    ld [wWave_LowerHi], a       ; 507B
    ld a, [hl+]                 ; 507E
    ld [wWave_UpperLo], a       ; 507F
    ld a, [hl+]                 ; 5082
    ld [wWave_UpperHi], a       ; 5083
    ld a, [hl+]                 ; 5086
    ld [wWave_SweepSpeed], a    ; 5087
    ld [wWave_SweepTimer], a    ; 508A
    ld a, [hl+]                 ; 508D
    ld [wWave_BaseLo], a        ; 508E
    ld a, [hl+]                 ; 5091
    ld [wWave_BaseHi], a        ; 5092
    ld a, d                     ; 5095
    and $3F                     ; 5096
    ld [wCh3_PLSteps], a        ; 5098
    ld a, l                     ; 509B
    ld [wCh3_PLPtrLo], a        ; 509C
    ld a, h                     ; 509F
    ld [wCh3_PLPtrHi], a        ; 50A0
    xor a                       ; 50A3
    cpl                         ; 50A4
    ld [wCh3_PLLoops], a        ; 50A5
    ld a, $FF                   ; 50A8
    ld [wWave_WaveUpdate], a    ; 50AA
    ld a, [wSFX_Time]           ; 50AD
    ld [wCh3_SFXTimer], a       ; 50B0
PlaySFX_Ch4:
    ld a, [wSFX_Ch4]            ; 50B3
    or a                        ; 50B6
    jr z, .L511B                ; 50B7
    dec a                       ; 50B9
    ld hl, SFXInstTable         ; 50BA
    ld c, a                     ; 50BD
    add hl, bc                  ; 50BE
    add hl, bc                  ; 50BF
    ld a, [hl+]                 ; 50C0
    ld c, a                     ; 50C1
    ld a, [hl+]                 ; 50C2
    ld h, a                     ; 50C3
    ld l, c                     ; 50C4
    xor a                       ; 50C5
    ld [wCh4_VolShift], a       ; 50C6
    ld a, [hl+]                 ; 50C9
    ld [wCh4_InsFlags], a       ; 50CA
    ld d, a                     ; 50CD
    ld a, [hl+]                 ; 50CE
    ld [wCh4_PLSpeed], a        ; 50CF
    xor a                       ; 50D2
    ld [wCh4_PLTimer], a        ; 50D3
    ld a, $00                   ; 50D6
    ldh [rNR41], a              ; 50D8
    ld a, [wCh4_VolShift]       ; 50DA
    ld c, a                     ; 50DD
    ld a, [hl]                  ; 50DE
    ld [wCh4_EnvShadow], a      ; 50DF
    and $0F                     ; 50E2
    ld e, a                     ; 50E4
    ld a, [hl+]                 ; 50E5
    inc c                       ; 50E6
    dec c                       ; 50E7
    jr z, .L50F8                ; 50E8
    dec c                       ; 50EA
    jr z, .L50F6                ; 50EB
    dec c                       ; 50ED
    jr z, .L50F4                ; 50EE
    srl a                       ; 50F0
    srl a                       ; 50F2
.L50F4:
    srl a                       ; 50F4
.L50F6:
    srl a                       ; 50F6
.L50F8:
    and $F0                     ; 50F8
    or e                        ; 50FA
    ldh [rNR42], a              ; 50FB
    ld a, d                     ; 50FD
    and $3F                     ; 50FE
    ld [wCh4_PLSteps], a        ; 5100
    ld a, l                     ; 5103
    ld [wCh4_PLPtrLo], a        ; 5104
    ld a, h                     ; 5107
    ld [wCh4_PLPtrHi], a        ; 5108
    xor a                       ; 510B
    cpl                         ; 510C
    ld [wCh4_PLLoops], a        ; 510D
    ld hl, rNR44                ; 5110
    set 7, [hl]                 ; 5113
    ld a, [wSFX_Time]           ; 5115
    ld [wCh4_SFXTimer], a       ; 5118
.L511B:
    pop af                      ; 511B
    ld [wEnabled], a            ; 511C
    ret                         ; 511F

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
    db $90, $57, $63, $63, $55, $55, $80, $47, $53, $53; 51B2 
    db $45, $45, $70, $37, $43, $43, $35, $35, $60, $27; 51BC 
    db $33, $33, $25, $25, $50, $17, $23, $23, $15, $15; 51C6 

;; 16 depths x 16 phases, signed frequency offsets.
VibratoTable:
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00; 51D0 
    db $00, $00, $00, $00, $01, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF; 51E0 
    db $00, $00, $01, $01, $02, $01, $01, $00, $00, $FF, $FE, $FE, $FE, $FE, $FE, $FF; 51F0 
    db $00, $01, $02, $02, $03, $02, $02, $01, $00, $FE, $FD, $FD, $FD, $FD, $FD, $FE; 5200 
    db $00, $01, $02, $03, $04, $03, $02, $01, $00, $FE, $FD, $FC, $FC, $FC, $FD, $FE; 5210 
    db $00, $01, $03, $04, $05, $04, $03, $01, $00, $FE, $FC, $FB, $FB, $FB, $FC, $FE; 5220 
    db $00, $02, $04, $05, $06, $05, $04, $02, $00, $FD, $FB, $FA, $FA, $FA, $FB, $FD; 5230 
    db $00, $02, $04, $06, $07, $06, $04, $02, $00, $FD, $FB, $F9, $F9, $F9, $FB, $FD; 5240 
    db $00, $03, $05, $07, $08, $07, $05, $03, $00, $FC, $FA, $F8, $F8, $F8, $FA, $FC; 5250 
    db $00, $03, $06, $08, $09, $08, $06, $03, $00, $FC, $F9, $F7, $F7, $F7, $F9, $FC; 5260 
    db $00, $03, $07, $09, $0A, $09, $07, $03, $00, $FC, $F8, $F6, $F6, $F6, $F8, $FC; 5270 
    db $00, $04, $07, $0A, $0B, $0A, $07, $04, $00, $FB, $F8, $F5, $F5, $F5, $F8, $FB; 5280 
    db $00, $04, $08, $0B, $0C, $0B, $08, $04, $00, $FB, $F7, $F4, $F4, $F4, $F7, $FB; 5290 
    db $00, $04, $09, $0C, $0D, $0C, $09, $04, $00, $FB, $F6, $F3, $F3, $F3, $F6, $FB; 52A0 
    db $00, $05, $09, $0C, $0E, $0C, $09, $05, $00, $FA, $F6, $F3, $F2, $F3, $F6, $FA; 52B0 
    db $00, $05, $0A, $0D, $0F, $0D, $0A, $05, $00, $FA, $F5, $F2, $F1, $F2, $F5, $FA; 52C0 
SongTable:
    dw Song0_Header                              ; 52D0  song 0

;; Song header (12 bytes, copied to wHdr_* by GHX_Init).
Song0_Header:
    db "GHX"                                     ; 52D2 magic
    db 18                                        ; subsongs
    db 16                                        ; rows per pattern
    db $00                                       ; (unused)
    dw Song0_Tracks                              ; track pointer table
    dw Song0_Instruments                         ; instrument pointer table
    dw Song0_Orders                              ; order table

;; Order table: two entries per subsong (intro, loop) = [count] [dw positions];
;; count+1 positions are played. After the intro the loop entry repeats forever.
Song0_Orders:
    db 11 
    dw Song0_Pos000                          ; 52DE subsong 0 intro (12 positions)  MAIN MENU
    db 9  
    dw Song0_Pos002                          ; 52E1 subsong 0 loop  (10 positions)
    db 7  
    dw Song0_Pos012                          ; 52E4 subsong 1 intro (8 positions)  CUTSCENES
    db 7  
    dw Song0_Pos012                          ; 52E7 subsong 1 loop  (8 positions)
    db 9  
    dw Song0_Pos020                          ; 52EA subsong 2 intro (10 positions)  SUBSCREENS
    db 9  
    dw Song0_Pos020                          ; 52ED subsong 2 loop  (10 positions)
    db 23 
    dw Song0_Pos030                          ; 52F0 subsong 3 intro (24 positions)  ACTION 1
    db 15 
    dw Song0_Pos038                          ; 52F3 subsong 3 loop  (16 positions)
    db 17 
    dw Song0_Pos054                          ; 52F6 subsong 4 intro (18 positions)  CREEPY 1
    db 17 
    dw Song0_Pos054                          ; 52F9 subsong 4 loop  (18 positions)
    db 19 
    dw Song0_Pos072                          ; 52FC subsong 5 intro (20 positions)  SAFE 1
    db 19 
    dw Song0_Pos072                          ; 52FF subsong 5 loop  (20 positions)
    db 25 
    dw Song0_Pos092                          ; 5302 subsong 6 intro (26 positions)  SAFE 2
    db 25 
    dw Song0_Pos092                          ; 5305 subsong 6 loop  (26 positions)
    db 15 
    dw Song0_Pos118                          ; 5308 subsong 7 intro (16 positions)  SAFE 3
    db 9  
    dw Song0_Pos124                          ; 530B subsong 7 loop  (10 positions)
    db 17 
    dw Song0_Pos134                          ; 530E subsong 8 intro (18 positions)  CREEPY 2
    db 17 
    dw Song0_Pos134                          ; 5311 subsong 8 loop  (18 positions)
    db 21 
    dw Song0_Pos152                          ; 5314 subsong 9 intro (22 positions)  ACTION 2
    db 21 
    dw Song0_Pos152                          ; 5317 subsong 9 loop  (22 positions)
    db 20 
    dw Song0_Pos174                          ; 531A subsong 10 intro (21 positions)  SAFE 4
    db 20 
    dw Song0_Pos174                          ; 531D subsong 10 loop  (21 positions)
    db 23 
    dw Song0_Pos195                          ; 5320 subsong 11 intro (24 positions)  ACTION 3
    db 23 
    dw Song0_Pos195                          ; 5323 subsong 11 loop  (24 positions)
    db 19 
    dw Song0_Pos219                          ; 5326 subsong 12 intro (20 positions)  ACTION 4
    db 11 
    dw Song0_Pos227                          ; 5329 subsong 12 loop  (12 positions)
    db 21 
    dw Song0_Pos239                          ; 532C subsong 13 intro (22 positions)  ACTION 5
    db 21 
    dw Song0_Pos239                          ; 532F subsong 13 loop  (22 positions)
    db 17 
    dw Song0_Pos261                          ; 5332 subsong 14 intro (18 positions)  BOSS 1
    db 17 
    dw Song0_Pos261                          ; 5335 subsong 14 loop  (18 positions)
    db 20 
    dw Song0_Pos279                          ; 5338 subsong 15 intro (21 positions)  BOSS 2
    db 34 
    dw Song0_Pos265                          ; 533B subsong 15 loop  (35 positions)
    db 0  
    dw Song0_Pos300                          ; 533E subsong 16 intro (1 positions)  EMPTY
    db 0  
    dw Song0_Pos300                          ; 5341 subsong 16 loop  (1 positions)
    db 255
    dw Song0_Pos301                          ; 5344 subsong 17 intro (256 positions)  (count runs past the position list!)
    db 0  
    dw Song0_Pos300                          ; 5347 subsong 17 loop  (1 positions)

;; Positions (7 bytes): track ch1, transpose ch1, track ch2, transpose ch2,
;; track ch3, transpose ch3, track ch4 (track = index into the track table).
Song0_Pos000:
    db   1,   0,    0,   0,    0,   0,    2          ; 534A pos 0
    db   1,   0,    0,   0,    0,   0,    2          ; 5351 pos 1
Song0_Pos002:
    db   1,   0,    3,   0,    0,   0,    2          ; 5358 pos 2
    db   1,   0,    4,   0,    0,   0,    2          ; 535F pos 3
    db   1,   5,    3,   5,    0,   0,    2          ; 5366 pos 4
    db   1,   5,    4,   5,    0,   0,    2          ; 536D pos 5
    db   1,   0,    3,   0,    0,   0,    2          ; 5374 pos 6
    db   1,   0,    4,   0,    0,   0,    2          ; 537B pos 7
    db   1,   5,    3,   5,    0,   0,    2          ; 5382 pos 8
    db   1,   5,    4,   5,    0,   0,    2          ; 5389 pos 9
    db   1,   0,    6,   0,    0,   0,    2          ; 5390 pos 10
    db   1,   0,    6,   0,    0,   0,    2          ; 5397 pos 11
Song0_Pos012:
    db   7,   0,    9,   0,    0,   0,    8          ; 539E pos 12
    db  11,   0,   10,   0,    0,   0,    8          ; 53A5 pos 13
    db  11,   0,   12,   0,    0,   0,    8          ; 53AC pos 14
    db  14,   0,   13,   0,    0,   0,   20          ; 53B3 pos 15
    db  16,   0,   15,   0,    0,   0,    8          ; 53BA pos 16
    db  17,   0,   19,   0,    0,   0,    8          ; 53C1 pos 17
    db  18,   0,   21,   0,    0,   0,    8          ; 53C8 pos 18
    db  23,   0,   22,   0,    0,   0,   24          ; 53CF pos 19
Song0_Pos020:
    db  25,   0,   26,   0,    0,   0,  149          ; 53D6 pos 20
    db  25,   0,   27,   0,    0,   0,  149          ; 53DD pos 21
    db  25,   0,   28,   0,    0,   0,  149          ; 53E4 pos 22
    db  25,   7,   27,   0,    0,   0,  149          ; 53EB pos 23
    db  25,  -2,   26,  -2,    0,   0,  149          ; 53F2 pos 24
    db  25,  -2,   27,  -2,    0,   0,  149          ; 53F9 pos 25
    db  25,  -2,   28,  -2,    0,   0,  149          ; 5400 pos 26
    db  25,   5,   30,   0,    0,   0,  149          ; 5407 pos 27
    db  25,  -2,   29,   0,    0,   0,  149          ; 540E pos 28
    db  25,  -2,    0,   0,    0,   0,  149          ; 5415 pos 29
Song0_Pos030:
    db  31,   0,   33,   0,    0,   0,   32          ; 541C pos 30
    db  31,   0,   34,   0,    0,   0,   32          ; 5423 pos 31
    db  31,   0,   33,   0,    0,   0,   32          ; 542A pos 32
    db  31,   0,   35,   0,    0,   0,   32          ; 5431 pos 33
    db  31,   5,   33,   5,    0,   0,   32          ; 5438 pos 34
    db  31,   5,   34,   5,    0,   0,   32          ; 543F pos 35
    db  31,   5,   33,   5,    0,   0,   32          ; 5446 pos 36
    db  31,   5,   37,   5,    0,   0,   32          ; 544D pos 37
Song0_Pos038:
    db  31,   0,   33,   0,    0,   0,   32          ; 5454 pos 38
    db  31,   0,   34,   0,    0,   0,   32          ; 545B pos 39
    db  31,   0,   33,   0,    0,   0,   32          ; 5462 pos 40
    db  31,   0,   35,   0,    0,   0,   32          ; 5469 pos 41
    db  31,   7,   33,   7,    0,   0,   32          ; 5470 pos 42
    db  31,   5,   34,   5,    0,   0,   32          ; 5477 pos 43
    db  31,   0,   33,   0,    0,   0,   32          ; 547E pos 44
    db  39,   0,   38,   0,    0,   0,   32          ; 5485 pos 45
    db  31,   0,   33,   0,    0,   0,   32          ; 548C pos 46
    db  31,   0,   34,   0,    0,   0,   32          ; 5493 pos 47
    db  31,   0,   33,   0,    0,   0,   32          ; 549A pos 48
    db  31,   0,   35,   0,    0,   0,   32          ; 54A1 pos 49
    db  31,   5,   33,   5,    0,   0,   32          ; 54A8 pos 50
    db  31,   5,   34,   5,    0,   0,   32          ; 54AF pos 51
    db  31,   5,   33,   5,    0,   0,   32          ; 54B6 pos 52
    db  31,   5,   37,   5,    0,   0,   32          ; 54BD pos 53
Song0_Pos054:
    db  42,   0,   51,   0,    0,   0,   43          ; 54C4 pos 54
    db  42,   0,   51,   0,    0,   0,   43          ; 54CB pos 55
    db  42,   0,   44,   0,    0,   0,   43          ; 54D2 pos 56
    db  42,   0,   45,   0,    0,   0,   43          ; 54D9 pos 57
    db  42,   0,   44,   0,    0,   0,   43          ; 54E0 pos 58
    db  46,   0,   47,   0,    0,   0,   48          ; 54E7 pos 59
    db  42,   0,   44,  12,    0,   0,   43          ; 54EE pos 60
    db  42,   0,   45,  12,    0,   0,   43          ; 54F5 pos 61
    db  42,   0,   44,  12,    0,   0,   43          ; 54FC pos 62
    db  46,   0,   47,   0,    0,   0,   48          ; 5503 pos 63
    db  42,   2,   44,   2,    0,   0,   43          ; 550A pos 64
    db  42,   2,   45,   2,    0,   0,   43          ; 5511 pos 65
    db  42,   2,   44,   2,    0,   0,   43          ; 5518 pos 66
    db  50, -12,   49, -12,    0,   0,   48          ; 551F pos 67
    db  42,   0,   44,  12,    0,   0,   43          ; 5526 pos 68
    db  42,   0,   45,  12,    0,   0,   43          ; 552D pos 69
    db  42,   0,   44,  12,    0,   0,   43          ; 5534 pos 70
    db  50,   0,   49,  -5,    0,   0,   48          ; 553B pos 71
Song0_Pos072:
    db  52,   0,   54,   0,    0,   0,   53          ; 5542 pos 72
    db  52,  -2,   55,   0,    0,   0,   53          ; 5549 pos 73
    db  52,   0,   57,   0,    0,   0,   53          ; 5550 pos 74
    db  52,  -2,   56,   0,    0,   0,   53          ; 5557 pos 75
    db  58,   0,   54,  12,    0,   0,   60          ; 555E pos 76
    db  58,  -2,   55,  12,    0,   0,   60          ; 5565 pos 77
    db  58,   0,   57,  12,    0,   0,   60          ; 556C pos 78
    db  58,  -2,   56,  12,    0,   0,   60          ; 5573 pos 79
    db  52,   8,   61, -12,    0,   0,   53          ; 557A pos 80
    db  52,   1,   62, -12,    0,   0,   53          ; 5581 pos 81
    db  52,   8,   61, -12,    0,   0,   53          ; 5588 pos 82
    db  52,   1,   63, -12,    0,   0,   53          ; 558F pos 83
    db  52,   8,   61,   0,    0,   0,   53          ; 5596 pos 84
    db  52,   1,   62,   0,    0,   0,   53          ; 559D pos 85
    db  52,   8,   61,   0,    0,   0,   53          ; 55A4 pos 86
    db  52,   1,   63,   0,    0,   0,   53          ; 55AB pos 87
    db  52,   0,   65,   0,    0,   0,   64          ; 55B2 pos 88
    db  52,   0,   65,   0,    0,   0,   64          ; 55B9 pos 89
    db  52,  12,   65,  12,    0,   0,   53          ; 55C0 pos 90
    db  52,  12,   65,  12,    0,   0,   60          ; 55C7 pos 91
Song0_Pos092:
    db  66,   0,   68,   0,    0,   0,   67          ; 55CE pos 92
    db  66,   0,   68,   0,    0,   0,   67          ; 55D5 pos 93
    db  70,   0,   71, -12,    0,   0,   69          ; 55DC pos 94
    db  70,   0,   72, -12,    0,   0,   69          ; 55E3 pos 95
    db  70,   0,   71,   0,    0,   0,   69          ; 55EA pos 96
    db  70,   0,   72,   0,    0,   0,   69          ; 55F1 pos 97
    db  70,   5,   71, -12,    0,   0,   69          ; 55F8 pos 98
    db  70,   5,   72, -12,    0,   0,   69          ; 55FF pos 99
    db  70,   0,   71, -12,    0,   0,   69          ; 5606 pos 100
    db  70,   0,   72, -12,    0,   0,   69          ; 560D pos 101
    db  70,   7,   71,  -5,    0,   0,   69          ; 5614 pos 102
    db  70,   5,   71,  -7,    0,   0,   69          ; 561B pos 103
    db  70,   0,   71, -12,    0,   0,   69          ; 5622 pos 104
    db  70,   0,   72, -12,    0,   0,   69          ; 5629 pos 105
    db  70,  12,   73,   0,    0,   0,   69          ; 5630 pos 106
    db  70,  12,   73,   0,    0,   0,   69          ; 5637 pos 107
    db  70,   5,   73,   0,    0,   0,   69          ; 563E pos 108
    db  70,   5,   73,   0,    0,   0,   69          ; 5645 pos 109
    db  70,  12,   73,  12,    0,   0,   69          ; 564C pos 110
    db  70,  12,   73,  12,    0,   0,   69          ; 5653 pos 111
    db  70,  10,   73,  10,    0,   0,   69          ; 565A pos 112
    db  70,   9,   73,   9,    0,   0,   69          ; 5661 pos 113
    db  70,   7,   73,   7,    0,   0,   69          ; 5668 pos 114
    db  70,   5,   73,   5,    0,   0,   69          ; 566F pos 115
    db  70,   0,   70,   0,    0,   0,   69          ; 5676 pos 116
    db  70,   0,   70,  12,    0,   0,   69          ; 567D pos 117
Song0_Pos118:
    db  74,   0,   76,   0,    0,   0,   75          ; 5684 pos 118
    db  78,   0,   77,   0,    0,   0,   75          ; 568B pos 119
    db  79,   0,   76,  -5,    0,   0,   75          ; 5692 pos 120
    db  80,   0,   81,  -5,    0,   0,   75          ; 5699 pos 121
    db  74,   0,   76,  12,    0,   0,   75          ; 56A0 pos 122
    db  78,   0,   77,  12,    0,   0,   75          ; 56A7 pos 123
Song0_Pos124:
    db  79,   0,   76,   7,    0,   0,   75          ; 56AE pos 124
    db  80,   0,   81,   7,    0,   0,   75          ; 56B5 pos 125
    db  74,   0,  150,  12,    0,   0,   82          ; 56BC pos 126
    db  78,   0,  151,  12,    0,   0,   82          ; 56C3 pos 127
    db  79,   0,  150,   7,    0,   0,   82          ; 56CA pos 128
    db  80,   0,  152,   0,    0,   0,   82          ; 56D1 pos 129
    db  74,   0,   76,   0,    0,   0,   75          ; 56D8 pos 130
    db  78,   0,   77,   0,    0,   0,   75          ; 56DF pos 131
    db  79,   0,   76,  -5,    0,   0,   75          ; 56E6 pos 132
    db  80,   0,   81,  -5,    0,   0,   75          ; 56ED pos 133
Song0_Pos134:
    db  83,   0,   84,   0,    0,   0,    0          ; 56F4 pos 134
    db  83,   0,   84,   0,    0,   0,    0          ; 56FB pos 135
    db  83,   0,   84,   0,    0,   0,   87          ; 5702 pos 136
    db  83,   0,   84,   0,    0,   0,   88          ; 5709 pos 137
    db  85,   0,   86,   0,    0,   0,   87          ; 5710 pos 138
    db  85,   0,   86,   0,    0,   0,   88          ; 5717 pos 139
    db  85,   3,   86,   3,    0,   0,   87          ; 571E pos 140
    db  85,   3,   86,   3,    0,   0,   88          ; 5725 pos 141
    db  85,   0,   86,  12,    0,   0,   87          ; 572C pos 142
    db  85,   0,   86,  12,    0,   0,   88          ; 5733 pos 143
    db  85,   0,   86,   0,    0,   0,   87          ; 573A pos 144
    db  85,   0,   86,   0,    0,   0,   88          ; 5741 pos 145
    db  85,   3,   86,   3,    0,   0,   87          ; 5748 pos 146
    db  85,   3,   86,   3,    0,   0,   88          ; 574F pos 147
    db  85,   0,   86,  12,    0,   0,   87          ; 5756 pos 148
    db  85,   0,   86,  12,    0,   0,   88          ; 575D pos 149
    db  83,   0,   86,   0,    0,   0,   87          ; 5764 pos 150
    db  83,   0,   86,   0,    0,   0,   88          ; 576B pos 151
Song0_Pos152:
    db  89,   0,   92,   0,    0,   0,   91          ; 5772 pos 152
    db  90,   0,   93,   0,    0,   0,   91          ; 5779 pos 153
    db  89,   0,   92,   0,    0,   0,   91          ; 5780 pos 154
    db  90,   0,   93,   0,    0,   0,   91          ; 5787 pos 155
    db  89,  -2,   94,  -2,    0,   0,   91          ; 578E pos 156
    db  90,  -2,   95,  -2,    0,   0,   91          ; 5795 pos 157
    db  89,  -2,   94,  -2,    0,   0,   91          ; 579C pos 158
    db  90,  -2,   95,  -2,    0,   0,   91          ; 57A3 pos 159
    db  89,   5,   92,  -7,    0,   0,   91          ; 57AA pos 160
    db  90,   5,   93,  -7,    0,   0,   91          ; 57B1 pos 161
    db  89,   5,   92,  -7,    0,   0,   91          ; 57B8 pos 162
    db  90,   5,   93,  -7,    0,   0,   91          ; 57BF pos 163
    db  89,   0,   94,   0,    0,   0,   91          ; 57C6 pos 164
    db  90,   0,   95,   0,    0,   0,   91          ; 57CD pos 165
    db  89,   0,   94,   0,    0,   0,   91          ; 57D4 pos 166
    db  90,   0,   95,   0,    0,   0,   91          ; 57DB pos 167
    db  96,   0,   92,   0,    0,   0,   91          ; 57E2 pos 168
    db  97,   0,   93,   0,    0,   0,   91          ; 57E9 pos 169
    db  96,   0,   92,   0,    0,   0,   91          ; 57F0 pos 170
    db  97,   0,   93,   0,    0,   0,   91          ; 57F7 pos 171
    db  96,   0,   98,   0,    0,   0,   91          ; 57FE pos 172
    db  97,   0,   99,   0,    0,   0,   91          ; 5805 pos 173
Song0_Pos174:
    db 100,   0,  102,   0,    0,   0,  101          ; 580C pos 174
    db 100,   0,  102,   0,    0,   0,  101          ; 5813 pos 175
    db 100,   5,  102,   5,    0,   0,  101          ; 581A pos 176
    db 100,   5,  102,   5,    0,   0,  101          ; 5821 pos 177
    db 100,   0,  102,   0,    0,   0,  101          ; 5828 pos 178
    db 100,   0,  102,   0,    0,   0,  101          ; 582F pos 179
    db 100,   7,  102,   7,    0,   0,  101          ; 5836 pos 180
    db 100,   5,  102,   5,    0,   0,  101          ; 583D pos 181
    db 100,   0,  102,   0,    0,   0,  101          ; 5844 pos 182
    db 100,   0,  102,   0,    0,   0,  101          ; 584B pos 183
    db 100,   0,  103,   0,    0,   0,  101          ; 5852 pos 184
    db 100,   0,  104,   0,    0,   0,  101          ; 5859 pos 185
    db 100,   5,  105,   0,    0,   0,  101          ; 5860 pos 186
    db 100,   5,  106,   0,    0,   0,  101          ; 5867 pos 187
    db 100,   0,  103,   0,    0,   0,  101          ; 586E pos 188
    db 100,   0,  104,   0,    0,   0,  101          ; 5875 pos 189
    db 100,   7,  107,   0,    0,   0,  101          ; 587C pos 190
    db 100,   5,  107,  -2,    0,   0,  101          ; 5883 pos 191
    db 100,   0,  108,   0,    0,   0,  101          ; 588A pos 192
    db 100,   0,    0,   0,    0,   0,  101          ; 5891 pos 193
    db 100,   0,    0,   0,    0,   0,  101          ; 5898 pos 194
Song0_Pos195:
    db 109,   0,  120,   0,    0,   0,    0          ; 589F pos 195
    db 109,   0,  120,   0,    0,   0,    0          ; 58A6 pos 196
    db 109,   0,  111,   0,    0,   0,  110          ; 58AD pos 197
    db 109,   0,  111,   0,    0,   0,  110          ; 58B4 pos 198
    db 112,   0,  113,   0,    0,   0,  110          ; 58BB pos 199
    db 112,   0,  114,   0,    0,   0,  110          ; 58C2 pos 200
    db 112,   0,  113,   0,    0,   0,  110          ; 58C9 pos 201
    db 112,   0,  115,   0,    0,   0,  110          ; 58D0 pos 202
    db 112,   0,  116,   0,    0,   0,  110          ; 58D7 pos 203
    db 112,   0,  117,   0,    0,   0,  110          ; 58DE pos 204
    db 112,   0,  118,   0,    0,   0,  110          ; 58E5 pos 205
    db 112,   0,  119,   0,    0,   0,  110          ; 58EC pos 206
    db 109,   0,  111,   0,    0,   0,  110          ; 58F3 pos 207
    db 109,   0,  111,   0,    0,   0,  110          ; 58FA pos 208
    db 112,  12,  111,   0,    0,   0,  110          ; 5901 pos 209
    db 112,  12,  111,   0,    0,   0,  110          ; 5908 pos 210
    db 112,   2,  113,   2,    0,   0,  110          ; 590F pos 211
    db 112,   2,  114,   2,    0,   0,  110          ; 5916 pos 212
    db 112,   2,  113,   2,    0,   0,  110          ; 591D pos 213
    db 112,   2,  115,   2,    0,   0,  110          ; 5924 pos 214
    db 112,   2,  116,   2,    0,   0,  110          ; 592B pos 215
    db 112,   2,  117,   2,    0,   0,  110          ; 5932 pos 216
    db 112,   2,  118,   2,    0,   0,  110          ; 5939 pos 217
    db 112,   2,  119,   2,    0,   0,  110          ; 5940 pos 218
Song0_Pos219:
    db 121,   0,  123,   0,    0,   0,  153          ; 5947 pos 219
    db 121,   2,  124, -12,    0,   0,  153          ; 594E pos 220
    db 126,   0,  125, -12,    0,   0,  129          ; 5955 pos 221
    db 127,   0,  128, -12,    0,   0,  153          ; 595C pos 222
    db 121,   0,  123,  12,    0,   0,  153          ; 5963 pos 223
    db 121,   2,  124,   0,    0,   0,  153          ; 596A pos 224
    db 126,   0,  125,   0,    0,   0,  129          ; 5971 pos 225
    db 127,   0,  128,   0,    0,   0,  153          ; 5978 pos 226
Song0_Pos227:
    db 121,  -8,  154,   0,    0,   0,  153          ; 597F pos 227
    db 121,  -6,  154,   2,    0,   0,  153          ; 5986 pos 228
    db 121,  -4,  154,   4,    0,   0,  153          ; 598D pos 229
    db 156,  -3,  155,   5,    0,   0,  153          ; 5994 pos 230
    db 121,   0,  123,   0,    0,   0,  153          ; 599B pos 231
    db 121,   2,  124, -12,    0,   0,  153          ; 59A2 pos 232
    db 126,   0,  125, -12,    0,   0,  129          ; 59A9 pos 233
    db 127,   0,  128, -12,    0,   0,  153          ; 59B0 pos 234
    db 121,   0,  123,  12,    0,   0,  153          ; 59B7 pos 235
    db 121,   2,  124,   0,    0,   0,  153          ; 59BE pos 236
    db 126,   0,  125,   0,    0,   0,  129          ; 59C5 pos 237
    db 127,   0,  128,   0,    0,   0,  153          ; 59CC pos 238
Song0_Pos239:
    db 133,   0,    0,   0,    0,   0,  131          ; 59D3 pos 239
    db 133,   0,    0,   0,    0,   0,  131          ; 59DA pos 240
    db 130,   0,  132, -12,    0,   0,  131          ; 59E1 pos 241
    db 130,   0,  134, -12,    0,   0,  131          ; 59E8 pos 242
    db 130,   0,  132, -12,    0,   0,  131          ; 59EF pos 243
    db 130,   0,  134, -12,    0,   0,  131          ; 59F6 pos 244
    db 130,   5,  132,  -7,    0,   0,  131          ; 59FD pos 245
    db 130,   5,  134,  -7,    0,   0,  131          ; 5A04 pos 246
    db 130,   0,  132, -12,    0,   0,  131          ; 5A0B pos 247
    db 130,   0,  134, -12,    0,   0,  131          ; 5A12 pos 248
    db 130,   7,  132,  -5,    0,   0,  131          ; 5A19 pos 249
    db 130,   5,  134,  -7,    0,   0,  131          ; 5A20 pos 250
    db 130,   0,  132,   0,    0,   0,  131          ; 5A27 pos 251
    db 130,   0,  134,   0,    0,   0,  131          ; 5A2E pos 252
    db 130,   0,  132,   0,    0,   0,  131          ; 5A35 pos 253
    db 130,   0,  134,   0,    0,   0,  131          ; 5A3C pos 254
    db 130,   5,  132,   5,    0,   0,  131          ; 5A43 pos 255
    db 130,   5,  134,   5,    0,   0,  131          ; 5A4A pos 256
    db 130,   0,  132,   0,    0,   0,  131          ; 5A51 pos 257
    db 130,   0,  134,   0,    0,   0,  131          ; 5A58 pos 258
    db 130,   7,  132,   7,    0,   0,  131          ; 5A5F pos 259
    db 130,   5,  134,   5,    0,   0,  131          ; 5A66 pos 260
Song0_Pos261:
    db 135,   0,    0,   0,    0,   0,  136          ; 5A6D pos 261
    db 135,   0,    0,   0,    0,   0,  136          ; 5A74 pos 262
    db 135,   0,  137,   0,    0,   0,  136          ; 5A7B pos 263
    db 135,   0,  137,   0,    0,   0,  136          ; 5A82 pos 264
Song0_Pos265:
    db 135,   0,  138,   0,    0,   0,  136          ; 5A89 pos 265
    db 135,   0,  138,   0,    0,   0,  136          ; 5A90 pos 266
    db 135,   0,  139,   0,    0,   0,    0          ; 5A97 pos 267
    db 135,   0,  139,  12,    0,   0,    0          ; 5A9E pos 268
    db 135,   0,    0,   0,    0,   0,    0          ; 5AA5 pos 269
    db 135,   0,    0,   0,    0,   0,    0          ; 5AAC pos 270
    db 135,   0,  138,   0,    0,   0,  136          ; 5AB3 pos 271
    db 135,   0,  138,   0,    0,   0,  136          ; 5ABA pos 272
    db 135,   0,  138,   0,    0,   0,  136          ; 5AC1 pos 273
    db 135,   0,  138,   0,    0,   0,  136          ; 5AC8 pos 274
    db 135,   2,  138,   2,    0,   0,  136          ; 5ACF pos 275
    db 135,   2,  138,   2,    0,   0,  136          ; 5AD6 pos 276
    db 140,   0,  139,   2,    0,   0,  136          ; 5ADD pos 277
    db 140,  14,  139,  14,    0,   0,  136          ; 5AE4 pos 278
Song0_Pos279:
    db 141,   0,  142,   0,    0,   0,    0          ; 5AEB pos 279
    db 143,   0,  145,   0,    0,   0,  144          ; 5AF2 pos 280
    db 143,   0,  145,   0,    0,   0,  144          ; 5AF9 pos 281
    db 146,   0,  147,   0,    0,   0,  144          ; 5B00 pos 282
    db 146,   0,  147,   0,    0,   0,  144          ; 5B07 pos 283
    db 146,   7,  147,   7,    0,   0,  144          ; 5B0E pos 284
    db 146,   7,  147,   7,    0,   0,  144          ; 5B15 pos 285
    db 143,   0,  147,   0,    0,   0,  144          ; 5B1C pos 286
    db 143,   0,  147,   0,    0,   0,  144          ; 5B23 pos 287
    db 143,   0,  145,   0,    0,   0,  144          ; 5B2A pos 288
    db 143,   0,  145,   0,    0,   0,  144          ; 5B31 pos 289
    db 147,   0,  148,   0,    0,   0,  144          ; 5B38 pos 290
    db 147,   0,  148,   0,    0,   0,  144          ; 5B3F pos 291
    db 146,   0,  148,   0,    0,   0,  144          ; 5B46 pos 292
    db 146,   0,  148,   0,    0,   0,  144          ; 5B4D pos 293
    db 146,   0,  148,   0,    0,   0,  144          ; 5B54 pos 294
    db 146,   0,  148,   0,    0,   0,  144          ; 5B5B pos 295
    db 146,  -1,  148,  -1,    0,   0,  144          ; 5B62 pos 296
    db 146,  -1,  148,  -1,    0,   0,  144          ; 5B69 pos 297
    db 146,  -1,  148,  -1,    0,   0,  144          ; 5B70 pos 298
    db 146,  -1,  148,  -1,    0,   0,  144          ; 5B77 pos 299
Song0_Pos300:
    db   0,   0,    0,   0,    0,   0,    0          ; 5B7E pos 300
Song0_Pos301:
    db   0,   0,    0,   0,    0,   0,    0          ; 5B85 pos 301
    db   0,   0,    0,   0,    0,   0,    0          ; 5B8C pos 302

;; Track pointer table
Song0_Tracks:
    dw Track000                                  ; 5B93  track 0
    dw Track001                                  ; 5B95  track 1
    dw Track002                                  ; 5B97  track 2
    dw Track003                                  ; 5B99  track 3
    dw Track004                                  ; 5B9B  track 4
    dw Track005                                  ; 5B9D  track 5
    dw Track006                                  ; 5B9F  track 6
    dw Track007                                  ; 5BA1  track 7
    dw Track008                                  ; 5BA3  track 8
    dw Track009                                  ; 5BA5  track 9
    dw Track010                                  ; 5BA7  track 10
    dw Track011                                  ; 5BA9  track 11
    dw Track012                                  ; 5BAB  track 12
    dw Track013                                  ; 5BAD  track 13
    dw Track014                                  ; 5BAF  track 14
    dw Track015                                  ; 5BB1  track 15
    dw Track016                                  ; 5BB3  track 16
    dw Track017                                  ; 5BB5  track 17
    dw Track018                                  ; 5BB7  track 18
    dw Track019                                  ; 5BB9  track 19
    dw Track020                                  ; 5BBB  track 20
    dw Track021                                  ; 5BBD  track 21
    dw Track022                                  ; 5BBF  track 22
    dw Track023                                  ; 5BC1  track 23
    dw Track024                                  ; 5BC3  track 24
    dw Track025                                  ; 5BC5  track 25
    dw Track026                                  ; 5BC7  track 26
    dw Track027                                  ; 5BC9  track 27
    dw Track028                                  ; 5BCB  track 28
    dw Track029                                  ; 5BCD  track 29
    dw Track030                                  ; 5BCF  track 30
    dw Track031                                  ; 5BD1  track 31
    dw Track032                                  ; 5BD3  track 32
    dw Track033                                  ; 5BD5  track 33
    dw Track034                                  ; 5BD7  track 34
    dw Track035                                  ; 5BD9  track 35
    dw Track036                                  ; 5BDB  track 36
    dw Track037                                  ; 5BDD  track 37
    dw Track038                                  ; 5BDF  track 38
    dw Track039                                  ; 5BE1  track 39
    dw Track040                                  ; 5BE3  track 40
    dw Track041                                  ; 5BE5  track 41
    dw Track042                                  ; 5BE7  track 42
    dw Track043                                  ; 5BE9  track 43
    dw Track044                                  ; 5BEB  track 44
    dw Track045                                  ; 5BED  track 45
    dw Track046                                  ; 5BEF  track 46
    dw Track047                                  ; 5BF1  track 47
    dw Track048                                  ; 5BF3  track 48
    dw Track049                                  ; 5BF5  track 49
    dw Track050                                  ; 5BF7  track 50
    dw Track051                                  ; 5BF9  track 51
    dw Track052                                  ; 5BFB  track 52
    dw Track053                                  ; 5BFD  track 53
    dw Track054                                  ; 5BFF  track 54
    dw Track055                                  ; 5C01  track 55
    dw Track056                                  ; 5C03  track 56
    dw Track057                                  ; 5C05  track 57
    dw Track058                                  ; 5C07  track 58
    dw Track059                                  ; 5C09  track 59
    dw Track060                                  ; 5C0B  track 60
    dw Track061                                  ; 5C0D  track 61
    dw Track062                                  ; 5C0F  track 62
    dw Track063                                  ; 5C11  track 63
    dw Track064                                  ; 5C13  track 64
    dw Track065                                  ; 5C15  track 65
    dw Track066                                  ; 5C17  track 66
    dw Track067                                  ; 5C19  track 67
    dw Track068                                  ; 5C1B  track 68
    dw Track069                                  ; 5C1D  track 69
    dw Track070                                  ; 5C1F  track 70
    dw Track071                                  ; 5C21  track 71
    dw Track072                                  ; 5C23  track 72
    dw Track073                                  ; 5C25  track 73
    dw Track074                                  ; 5C27  track 74
    dw Track075                                  ; 5C29  track 75
    dw Track076                                  ; 5C2B  track 76
    dw Track077                                  ; 5C2D  track 77
    dw Track078                                  ; 5C2F  track 78
    dw Track079                                  ; 5C31  track 79
    dw Track080                                  ; 5C33  track 80
    dw Track081                                  ; 5C35  track 81
    dw Track082                                  ; 5C37  track 82
    dw Track083                                  ; 5C39  track 83
    dw Track084                                  ; 5C3B  track 84
    dw Track085                                  ; 5C3D  track 85
    dw Track086                                  ; 5C3F  track 86
    dw Track087                                  ; 5C41  track 87
    dw Track088                                  ; 5C43  track 88
    dw Track089                                  ; 5C45  track 89
    dw Track090                                  ; 5C47  track 90
    dw Track091                                  ; 5C49  track 91
    dw Track092                                  ; 5C4B  track 92
    dw Track093                                  ; 5C4D  track 93
    dw Track094                                  ; 5C4F  track 94
    dw Track095                                  ; 5C51  track 95
    dw Track096                                  ; 5C53  track 96
    dw Track097                                  ; 5C55  track 97
    dw Track098                                  ; 5C57  track 98
    dw Track099                                  ; 5C59  track 99
    dw Track100                                  ; 5C5B  track 100
    dw Track101                                  ; 5C5D  track 101
    dw Track102                                  ; 5C5F  track 102
    dw Track103                                  ; 5C61  track 103
    dw Track104                                  ; 5C63  track 104
    dw Track105                                  ; 5C65  track 105
    dw Track106                                  ; 5C67  track 106
    dw Track107                                  ; 5C69  track 107
    dw Track108                                  ; 5C6B  track 108
    dw Track109                                  ; 5C6D  track 109
    dw Track110                                  ; 5C6F  track 110
    dw Track111                                  ; 5C71  track 111
    dw Track112                                  ; 5C73  track 112
    dw Track113                                  ; 5C75  track 113
    dw Track114                                  ; 5C77  track 114
    dw Track115                                  ; 5C79  track 115
    dw Track116                                  ; 5C7B  track 116
    dw Track117                                  ; 5C7D  track 117
    dw Track118                                  ; 5C7F  track 118
    dw Track119                                  ; 5C81  track 119
    dw Track120                                  ; 5C83  track 120
    dw Track121                                  ; 5C85  track 121
    dw Track122                                  ; 5C87  track 122
    dw Track123                                  ; 5C89  track 123
    dw Track124                                  ; 5C8B  track 124
    dw Track125                                  ; 5C8D  track 125
    dw Track126                                  ; 5C8F  track 126
    dw Track127                                  ; 5C91  track 127
    dw Track128                                  ; 5C93  track 128
    dw Track129                                  ; 5C95  track 129
    dw Track130                                  ; 5C97  track 130
    dw Track131                                  ; 5C99  track 131
    dw Track132                                  ; 5C9B  track 132
    dw Track133                                  ; 5C9D  track 133
    dw Track134                                  ; 5C9F  track 134
    dw Track135                                  ; 5CA1  track 135
    dw Track136                                  ; 5CA3  track 136
    dw Track137                                  ; 5CA5  track 137
    dw Track138                                  ; 5CA7  track 138
    dw Track139                                  ; 5CA9  track 139
    dw Track140                                  ; 5CAB  track 140
    dw Track141                                  ; 5CAD  track 141
    dw Track142                                  ; 5CAF  track 142
    dw Track143                                  ; 5CB1  track 143
    dw Track144                                  ; 5CB3  track 144
    dw Track145                                  ; 5CB5  track 145
    dw Track146                                  ; 5CB7  track 146
    dw Track147                                  ; 5CB9  track 147
    dw Track148                                  ; 5CBB  track 148
    dw Track149                                  ; 5CBD  track 149
    dw Track150                                  ; 5CBF  track 150
    dw Track151                                  ; 5CC1  track 151
    dw Track152                                  ; 5CC3  track 152
    dw Track153                                  ; 5CC5  track 153
    dw Track154                                  ; 5CC7  track 154
    dw Track155                                  ; 5CC9  track 155
    dw Track156                                  ; 5CCB  track 156
Song0_Instruments:
    dw Inst00                                    ; 5CCD  instrument 0 (ch1,ch2)
    dw Inst01                                    ; 5CCF  instrument 1 (ch1,ch2)
    dw Inst02                                    ; 5CD1  instrument 2 (ch4)
    dw Inst03                                    ; 5CD3  instrument 3 (ch4)
    dw Inst04                                    ; 5CD5  instrument 4 (ch1,ch2)
    dw Inst05                                    ; 5CD7  instrument 5 (ch4)
    dw Inst06                                    ; 5CD9  instrument 6 (ch1,ch2)
    dw Inst07                                    ; 5CDB  instrument 7 (ch1,ch2)
    dw Inst08                                    ; 5CDD  instrument 8 (ch1)
    dw Inst09                                    ; 5CDF  instrument 9 (ch1,ch2)
    dw Inst10                                    ; 5CE1  instrument 10 (ch2)
    dw Inst11                                    ; 5CE3  instrument 11 (ch1,ch2)
    dw Inst12                                    ; 5CE5  instrument 12 (ch1)
    dw Inst13                                    ; 5CE7  instrument 13 (ch4)
    dw Inst14                                    ; 5CE9  instrument 14 (ch1,ch2)
    dw Inst15                                    ; 5CEB  instrument 15 (unused)
    dw Inst16                                    ; 5CED  instrument 16 (ch1)
    dw Inst17                                    ; 5CEF  instrument 17 (ch2)
    dw Inst18                                    ; 5CF1  instrument 18 (ch1,ch2)
    dw Inst19                                    ; 5CF3  instrument 19 (ch1)
Inst00:
    db $04                                       ; 5CF5 square, 4 steps
    db $83                                       ; playlist speed | $80 = vibrato
    db $F2                                       ; NRx2 envelope
    db $03, $26                                  ; vibrato delay, depth<<4|speed
    db $01, $00, $C0                             ; step 0: +0  duty 0
    db $00, $00, $C1                             ; step 1: -  duty 1
    db $00, $00, $C2                             ; step 2: -  duty 2
    db $00, $00, $C1                             ; step 3: -  duty 1
Inst01:
    db $05                                       ; 5D06 square, 5 steps
    db $03                                       ; playlist speed
    db $94                                       ; NRx2 envelope
    db $0D, $00, $C2                             ; step 0: +12  duty 2
    db $01, $00, $C1                             ; step 1: +0  duty 1
    db $0D, $00, $46                             ; step 2: +12  vol 6
    db $01, $00, $00                             ; step 3: +0
    db $0D, $00, $84                             ; step 4: +12  jump -4
Inst02:
    db $02                                       ; 5D18 noise, 2 steps
    db $01                                       ; playlist speed
    db $C1                                       ; NR42 envelope
    db $65, $00, $00                             ; step 0: C-5
    db $59, $00, $82                             ; step 1: C-4  jump -2
Inst03:
    db $03                                       ; 5D21 noise, 3 steps
    db $01                                       ; playlist speed
    db $F1                                       ; NR42 envelope
    db $65, $00, $00                             ; step 0: C-5
    db $59, $00, $00                             ; step 1: C-4
    db $00, $00, $40                             ; step 2: -  vol 0
Inst04:
    db $03                                       ; 5D2D square, 3 steps
    db $83                                       ; playlist speed | $80 = vibrato
    db $87                                       ; NRx2 envelope
    db $03, $26                                  ; vibrato delay, depth<<4|speed
    db $0D, $00, $C2                             ; step 0: +12  duty 2
    db $00, $00, $45                             ; step 1: -  vol 5
    db $00, $00, $00                             ; step 2: -
Inst05:
    db $02                                       ; 5D3B noise, 2 steps
    db $01                                       ; playlist speed
    db $61                                       ; NR42 envelope
    db $71, $00, $00                             ; step 0: C-6
    db $00, $00, $00                             ; step 1: -
Inst06:
    db $04                                       ; 5D44 square, 4 steps
    db $01                                       ; playlist speed
    db $C1                                       ; NRx2 envelope
    db $0E, $00, $C0                             ; step 0: +13  duty 0
    db $11, $00, $00                             ; step 1: +16
    db $16, $00, $00                             ; step 2: +21
    db $0E, $00, $83                             ; step 3: +13  jump -3
Inst07:
    db $03                                       ; 5D53 square, 3 steps
    db $83                                       ; playlist speed | $80 = vibrato
    db $A6                                       ; NRx2 envelope
    db $03, $26                                  ; vibrato delay, depth<<4|speed
    db $0C, $01, $C0                             ; step 0: +11  speed 1, duty 0
    db $0D, $00, $03                             ; step 1: +12  speed 3
    db $00, $C1, $4A                             ; step 2: -  duty 1, vol 10
Inst08:
    db $04                                       ; 5D61 square, 4 steps
    db $01                                       ; playlist speed
    db $C1                                       ; NRx2 envelope
    db $0C, $00, $C0                             ; step 0: +11  duty 0
    db $11, $00, $00                             ; step 1: +16
    db $15, $00, $00                             ; step 2: +20
    db $0C, $00, $83                             ; step 3: +11  jump -3
Inst09:
    db $04                                       ; 5D70 square, 4 steps
    db $01                                       ; playlist speed
    db $C1                                       ; NRx2 envelope
    db $0D, $00, $C0                             ; step 0: +12  duty 0
    db $12, $00, $00                             ; step 1: +17
    db $16, $00, $00                             ; step 2: +21
    db $0D, $00, $83                             ; step 3: +12  jump -3
Inst10:
    db $05                                       ; 5D7F square, 5 steps
    db $02                                       ; playlist speed
    db $91                                       ; NRx2 envelope
    db $0D, $00, $C0                             ; step 0: +12  duty 0
    db $01, $00, $C1                             ; step 1: +0  duty 1
    db $0D, $00, $46                             ; step 2: +12  vol 6
    db $01, $00, $C0                             ; step 3: +0  duty 0
    db $0D, $00, $82                             ; step 4: +12  jump -2
Inst11:
    db $03                                       ; 5D91 square, 3 steps
    db $83                                       ; playlist speed | $80 = vibrato
    db $B0                                       ; NRx2 envelope
    db $03, $26                                  ; vibrato delay, depth<<4|speed
    db $0C, $01, $C0                             ; step 0: +11  speed 1, duty 0
    db $0D, $00, $03                             ; step 1: +12  speed 3
    db $00, $00, $48                             ; step 2: -  vol 8
Inst12:
    db $04                                       ; 5D9F square, 4 steps
    db $8C                                       ; playlist speed | $80 = vibrato
    db $80                                       ; NRx2 envelope
    db $03, $72                                  ; vibrato delay, depth<<4|speed
    db $01, $00, $C2                             ; step 0: +0  duty 2
    db $00, $00, $C1                             ; step 1: -  duty 1
    db $00, $C2, $82                             ; step 2: -  duty 2, jump -2
    db $00, $00, $00                             ; step 3: -
Inst13:
    db $03                                       ; 5DB0 noise, 3 steps
    db $02                                       ; playlist speed
    db $A1                                       ; NR42 envelope
    db $01, $00, $4A                             ; step 0: +0  vol 10
    db $00, $00, $4A                             ; step 1: -  vol 10
    db $00, $00, $00                             ; step 2: -
Inst14:
    db $05                                       ; 5DBC square, 5 steps
    db $02                                       ; playlist speed
    db $91                                       ; NRx2 envelope
    db $0D, $00, $C2                             ; step 0: +12  duty 2
    db $01, $00, $C1                             ; step 1: +0  duty 1
    db $0D, $00, $00                             ; step 2: +12
    db $01, $00, $C0                             ; step 3: +0  duty 0
    db $0D, $00, $82                             ; step 4: +12  jump -2
Inst15:
    db $00                                       ; 5DCE square, 0 steps
    db $01                                       ; playlist speed
    db $00                                       ; NRx2 envelope
Inst16:
    db $04                                       ; 5DD1 square, 4 steps
    db $83                                       ; playlist speed | $80 = vibrato
    db $F1                                       ; NRx2 envelope
    db $03, $26                                  ; vibrato delay, depth<<4|speed
    db $01, $00, $C0                             ; step 0: +0  duty 0
    db $00, $00, $C1                             ; step 1: -  duty 1
    db $00, $00, $C2                             ; step 2: -  duty 2
    db $00, $00, $C1                             ; step 3: -  duty 1
Inst17:
    db $05                                       ; 5DE2 square, 5 steps
    db $02                                       ; playlist speed
    db $94                                       ; NRx2 envelope
    db $0D, $00, $C0                             ; step 0: +12  duty 0
    db $01, $00, $C1                             ; step 1: +0  duty 1
    db $0D, $00, $46                             ; step 2: +12  vol 6
    db $01, $00, $C0                             ; step 3: +0  duty 0
    db $0D, $00, $82                             ; step 4: +12  jump -2
Inst18:
    db $07                                       ; 5DF4 square, 7 steps
    db $81                                       ; playlist speed | $80 = vibrato
    db $F1                                       ; NRx2 envelope
    db $03, $26                                  ; vibrato delay, depth<<4|speed
    db $0D, $00, $C2                             ; step 0: +12  duty 2
    db $0A, $00, $00                             ; step 1: +9
    db $08, $00, $00                             ; step 2: +7
    db $05, $00, $00                             ; step 3: +4
    db $00, $00, $40                             ; step 4: -  vol 0
    db $00, $00, $00                             ; step 5: -
    db $00, $00, $00                             ; step 6: -
Inst19:
    db $08                                       ; 5E0E square, 8 steps
    db $81                                       ; playlist speed | $80 = vibrato
    db $F1                                       ; NRx2 envelope
    db $03, $26                                  ; vibrato delay, depth<<4|speed
    db $0D, $00, $C2                             ; step 0: +12  duty 2
    db $0A, $00, $00                             ; step 1: +9
    db $08, $00, $48                             ; step 2: +7  vol 8
    db $0D, $00, $4F                             ; step 3: +12  vol 15
    db $0A, $00, $00                             ; step 4: +9
    db $08, $00, $00                             ; step 5: +7
    db $00, $00, $40                             ; step 6: -  vol 0
    db $00, $00, $00                             ; step 7: -
Track000:
    R   ___                                     ; 5E2B row 00
    R   ___                                     ; 5E2C row 01
    R   ___                                     ; 5E2D row 02
    R   ___                                     ; 5E2E row 03
    R   ___                                     ; 5E2F row 04
    R   ___                                     ; 5E30 row 05
    R   ___                                     ; 5E31 row 06
    R   ___                                     ; 5E32 row 07
    R   ___                                     ; 5E33 row 08
    R   ___                                     ; 5E34 row 09
    R   ___                                     ; 5E35 row 10
    R   ___                                     ; 5E36 row 11
    R   ___                                     ; 5E37 row 12
    R   ___                                     ; 5E38 row 13
    R   ___                                     ; 5E39 row 14
    R   ___                                     ; 5E3A row 15
Track001:
    RI  F_2, 1, 0                               ; 5E3B row 00  Inst00
    R   ___                                     ; 5E3D row 01
    R   ___                                     ; 5E3E row 02
    RI  C_2, 1, 0                               ; 5E3F row 03  Inst00
    R   ___                                     ; 5E41 row 04
    R   ___                                     ; 5E42 row 05
    RI  F_2, 1, 0                               ; 5E43 row 06  Inst00
    R   ___                                     ; 5E45 row 07
    R   ___                                     ; 5E46 row 08
    RI  C_2, 1, 0                               ; 5E47 row 09  Inst00
    R   ___                                     ; 5E49 row 10
    RI  D_2, 1, 0                               ; 5E4A row 11  Inst00
    R   ___                                     ; 5E4C row 12
    RI  E_2, 1, 0                               ; 5E4D row 13  Inst00
    R   ___                                     ; 5E4F row 14
    R   ___                                     ; 5E50 row 15
Track002:
    RIF C_5, 4, 0, $F, $9                       ; 5E51 row 00  Inst03  speed 9
    R   ___                                     ; 5E54 row 01
    RI  C_6, 6, 0                               ; 5E55 row 02  Inst05
    RI  C_5, 3, 0                               ; 5E57 row 03  Inst02
    R   ___                                     ; 5E59 row 04
    RI  C_6, 6, 0                               ; 5E5A row 05  Inst05
    RI  C_5, 4, 0                               ; 5E5C row 06  Inst03
    R   ___                                     ; 5E5E row 07
    RI  C_6, 6, 0                               ; 5E5F row 08  Inst05
    RIF C_5, 3, 0, $F, $4                       ; 5E61 row 09  Inst02  speed 4
    RF  ___, $F, $5                             ; 5E64 row 10  speed 5
    RF  ___, $F, $4                             ; 5E66 row 11  speed 4
    RF  ___, $F, $5                             ; 5E68 row 12  speed 5
    RIF C_6, 6, 0, $F, $2                       ; 5E6A row 13  Inst05  speed 2
    RF  ___, $F, $4                             ; 5E6D row 14  speed 4
    RF  ___, $F, $3                             ; 5E6F row 15  speed 3
Track003:
    RI  A_3, 2, 0                               ; 5E71 row 00  Inst01
    RI  C_4, 2, 0                               ; 5E73 row 01  Inst01
    RI  D_4, 2, 0                               ; 5E75 row 02  Inst01
    RI  C_4, 2, 0                               ; 5E77 row 03  Inst01
    RI  A_3, 2, 0                               ; 5E79 row 04  Inst01
    RI  G_3, 2, 0                               ; 5E7B row 05  Inst01
    RI  A_3, 2, 0                               ; 5E7D row 06  Inst01
    RI  C_4, 2, 0                               ; 5E7F row 07  Inst01
    RI  D_4, 2, 0                               ; 5E81 row 08  Inst01
    RI  C_4, 2, 0                               ; 5E83 row 09  Inst01
    R   ___                                     ; 5E85 row 10
    R   ___                                     ; 5E86 row 11
    R   ___                                     ; 5E87 row 12
    R   ___                                     ; 5E88 row 13
    R   ___                                     ; 5E89 row 14
    R   ___                                     ; 5E8A row 15
Track004:
    RI  F_4, 5, 0                               ; 5E8B row 00  Inst04
    RI  E_4, 5, 0                               ; 5E8D row 01  Inst04
    RI  C_4, 5, 0                               ; 5E8F row 02  Inst04
    RI  A_3, 5, 0                               ; 5E91 row 03  Inst04
    RI  G_3, 5, 0                               ; 5E93 row 04  Inst04
    RI  F_3, 5, 0                               ; 5E95 row 05  Inst04
    RI  G_3, 5, 0                               ; 5E97 row 06  Inst04
    RI  A_3, 5, 0                               ; 5E99 row 07  Inst04
    RI  G_3, 5, 0                               ; 5E9B row 08  Inst04
    RI  F_3, 5, 0                               ; 5E9D row 09  Inst04
    R   ___                                     ; 5E9F row 10
    R   ___                                     ; 5EA0 row 11
    R   ___                                     ; 5EA1 row 12
    R   ___                                     ; 5EA2 row 13
    R   ___                                     ; 5EA3 row 14
    R   ___                                     ; 5EA4 row 15
Track005:
    R   ___                                     ; 5EA5 row 00
    R   ___                                     ; 5EA6 row 01
    R   ___                                     ; 5EA7 row 02
    R   ___                                     ; 5EA8 row 03
    R   ___                                     ; 5EA9 row 04
    R   ___                                     ; 5EAA row 05
    R   ___                                     ; 5EAB row 06
    R   ___                                     ; 5EAC row 07
    R   ___                                     ; 5EAD row 08
    R   ___                                     ; 5EAE row 09
    R   ___                                     ; 5EAF row 10
    R   ___                                     ; 5EB0 row 11
    R   ___                                     ; 5EB1 row 12
    R   ___                                     ; 5EB2 row 13
    R   ___                                     ; 5EB3 row 14
    R   ___                                     ; 5EB4 row 15
Track006:
    R   ___                                     ; 5EB5 row 00
    RI  F_2, 1, 0                               ; 5EB6 row 01  Inst00
    R   ___                                     ; 5EB8 row 02
    R   ___                                     ; 5EB9 row 03
    RI  C_2, 1, 0                               ; 5EBA row 04  Inst00
    R   ___                                     ; 5EBC row 05
    R   ___                                     ; 5EBD row 06
    RI  F_2, 1, 0                               ; 5EBE row 07  Inst00
    R   ___                                     ; 5EC0 row 08
    R   ___                                     ; 5EC1 row 09
    RI  C_2, 1, 0                               ; 5EC2 row 10  Inst00
    R   ___                                     ; 5EC4 row 11
    RI  D_2, 1, 0                               ; 5EC5 row 12  Inst00
    R   ___                                     ; 5EC7 row 13
    RI  E_2, 1, 0                               ; 5EC8 row 14  Inst00
    R   ___                                     ; 5ECA row 15
Track007:
    RIF A_2, 1, 0, $F, $A                       ; 5ECB row 00  Inst00  speed 10
    RF  ___, $F, $6                             ; 5ECE row 01  speed 6
    RIF C_3, 7, 0, $F, $A                       ; 5ED0 row 02  Inst06  speed 10
    RF  ___, $F, $6                             ; 5ED3 row 03  speed 6
    RIF E_2, 1, 0, $F, $A                       ; 5ED5 row 04  Inst00  speed 10
    RF  ___, $F, $6                             ; 5ED8 row 05  speed 6
    RIF C_3, 7, 0, $F, $A                       ; 5EDA row 06  Inst06  speed 10
    RF  ___, $F, $6                             ; 5EDD row 07  speed 6
    RIF A_2, 1, 0, $F, $A                       ; 5EDF row 08  Inst00  speed 10
    RF  ___, $F, $6                             ; 5EE2 row 09  speed 6
    RIF C_3, 7, 0, $F, $A                       ; 5EE4 row 10  Inst06  speed 10
    RF  ___, $F, $6                             ; 5EE7 row 11  speed 6
    RIF E_2, 1, 0, $F, $A                       ; 5EE9 row 12  Inst00  speed 10
    RF  ___, $F, $6                             ; 5EEC row 13  speed 6
    RIF C_3, 7, 0, $F, $A                       ; 5EEE row 14  Inst06  speed 10
    RF  ___, $F, $6                             ; 5EF1 row 15  speed 6
Track008:
    RI  C_3, 4, 0                               ; 5EF3 row 00  Inst03
    R   ___                                     ; 5EF5 row 01
    RI  C_3, 6, 0                               ; 5EF6 row 02  Inst05
    RI  C_3, 6, 0                               ; 5EF8 row 03  Inst05
    RI  C_3, 3, 0                               ; 5EFA row 04  Inst02
    R   ___                                     ; 5EFC row 05
    RI  C_3, 6, 0                               ; 5EFD row 06  Inst05
    RI  C_3, 6, 0                               ; 5EFF row 07  Inst05
    RI  C_3, 4, 0                               ; 5F01 row 08  Inst03
    R   ___                                     ; 5F03 row 09
    RI  C_3, 6, 0                               ; 5F04 row 10  Inst05
    RI  C_3, 6, 0                               ; 5F06 row 11  Inst05
    RI  C_3, 3, 0                               ; 5F08 row 12  Inst02
    R   ___                                     ; 5F0A row 13
    RI  C_3, 6, 0                               ; 5F0B row 14  Inst05
    RI  C_3, 6, 0                               ; 5F0D row 15  Inst05
Track009:
    RI  Cs3, 8, 0                               ; 5F0F row 00  Inst07
    R   ___                                     ; 5F11 row 01
    R   ___                                     ; 5F12 row 02
    R   ___                                     ; 5F13 row 03
    R   ___                                     ; 5F14 row 04
    R   ___                                     ; 5F15 row 05
    RI  C_3, 8, 0                               ; 5F16 row 06  Inst07
    R   Cs3                                     ; 5F18 row 07
    RI  D_3, 8, 0                               ; 5F19 row 08  Inst07
    R   ___                                     ; 5F1B row 09
    RI  Cs3, 8, 0                               ; 5F1C row 10  Inst07
    RI  ___, 0, 3                               ; 5F1E row 11
    RI  C_3, 8, 0                               ; 5F20 row 12  Inst07
    RI  Cs3, 8, 0                               ; 5F22 row 13  Inst07
    RI  ___, 0, 3                               ; 5F24 row 14
    RI  Gs3, 8, 0                               ; 5F26 row 15  Inst07
Track010:
    R   ___                                     ; 5F28 row 00
    R   ___                                     ; 5F29 row 01
    R   ___                                     ; 5F2A row 02
    R   ___                                     ; 5F2B row 03
    R   ___                                     ; 5F2C row 04
    R   ___                                     ; 5F2D row 05
    RI  Fs3, 8, 0                               ; 5F2E row 06  Inst07
    RI  E_3, 8, 0                               ; 5F30 row 07  Inst07
    R   ___                                     ; 5F32 row 08
    R   ___                                     ; 5F33 row 09
    R   ___                                     ; 5F34 row 10
    R   ___                                     ; 5F35 row 11
    R   ___                                     ; 5F36 row 12
    R   ___                                     ; 5F37 row 13
    RI  Cs3, 8, 0                               ; 5F38 row 14  Inst07
    RI  D_3, 8, 0                               ; 5F3A row 15  Inst07
Track011:
    RIF E_3, 1, 0, $F, $A                       ; 5F3C row 00  Inst00  speed 10
    RF  ___, $F, $6                             ; 5F3F row 01  speed 6
    RIF C_3, 9, 0, $F, $A                       ; 5F41 row 02  Inst08  speed 10
    RF  ___, $F, $6                             ; 5F44 row 03  speed 6
    RIF B_2, 1, 0, $F, $A                       ; 5F46 row 04  Inst00  speed 10
    RF  ___, $F, $6                             ; 5F49 row 05  speed 6
    RIF C_3, 9, 0, $F, $A                       ; 5F4B row 06  Inst08  speed 10
    RF  ___, $F, $6                             ; 5F4E row 07  speed 6
    RIF E_3, 1, 0, $F, $A                       ; 5F50 row 08  Inst00  speed 10
    RF  ___, $F, $6                             ; 5F53 row 09  speed 6
    RIF C_3, 9, 0, $F, $A                       ; 5F55 row 10  Inst08  speed 10
    RF  ___, $F, $6                             ; 5F58 row 11  speed 6
    RIF B_2, 1, 0, $F, $A                       ; 5F5A row 12  Inst00  speed 10
    RF  ___, $F, $6                             ; 5F5D row 13  speed 6
    RIF C_3, 9, 0, $F, $A                       ; 5F5F row 14  Inst08  speed 10
    RF  ___, $F, $6                             ; 5F62 row 15  speed 6
Track012:
    RI  E_3, 8, 0                               ; 5F64 row 00  Inst07
    R   ___                                     ; 5F66 row 01
    R   ___                                     ; 5F67 row 02
    R   ___                                     ; 5F68 row 03
    R   ___                                     ; 5F69 row 04
    R   ___                                     ; 5F6A row 05
    RI  D_3, 8, 0                               ; 5F6B row 06  Inst07
    R   ___                                     ; 5F6D row 07
    RI  Fs3, 8, 0                               ; 5F6E row 08  Inst07
    R   ___                                     ; 5F70 row 09
    RI  E_3, 8, 0                               ; 5F71 row 10  Inst07
    RI  ___, 0, 3                               ; 5F73 row 11
    RI  D_3, 8, 0                               ; 5F75 row 12  Inst07
    RI  ___, 0, 3                               ; 5F77 row 13
    RI  E_3, 8, 0                               ; 5F79 row 14  Inst07
    RI  Cs3, 8, 0                               ; 5F7B row 15  Inst07
Track013:
    R   ___                                     ; 5F7D row 00
    R   ___                                     ; 5F7E row 01
    R   ___                                     ; 5F7F row 02
    R   ___                                     ; 5F80 row 03
    R   ___                                     ; 5F81 row 04
    R   ___                                     ; 5F82 row 05
    R   ___                                     ; 5F83 row 06
    R   ___                                     ; 5F84 row 07
    R   ___                                     ; 5F85 row 08
    R   ___                                     ; 5F86 row 09
    RI  A_2, 8, 0                               ; 5F87 row 10  Inst07
    RI  ___, 0, 3                               ; 5F89 row 11
    RI  B_2, 8, 0                               ; 5F8B row 12  Inst07
    RI  ___, 0, 3                               ; 5F8D row 13
    RI  C_3, 8, 0                               ; 5F8F row 14  Inst07
    RI  ___, 0, 3                               ; 5F91 row 15
Track014:
    RIF A_2, 1, 0, $F, $A                       ; 5F93 row 00  Inst00  speed 10
    RF  ___, $F, $6                             ; 5F96 row 01  speed 6
    RIF C_3, 7, 0, $F, $A                       ; 5F98 row 02  Inst06  speed 10
    RF  ___, $F, $6                             ; 5F9B row 03  speed 6
    RIF E_2, 1, 0, $F, $A                       ; 5F9D row 04  Inst00  speed 10
    RF  ___, $F, $6                             ; 5FA0 row 05  speed 6
    RIF C_3, 7, 0, $F, $A                       ; 5FA2 row 06  Inst06  speed 10
    RF  ___, $F, $6                             ; 5FA5 row 07  speed 6
    RIF A_2, 1, 0, $F, $A                       ; 5FA7 row 08  Inst00  speed 10
    RF  ___, $F, $6                             ; 5FAA row 09  speed 6
    RIF C_3, 7, 0, $F, $A                       ; 5FAC row 10  Inst06  speed 10
    RF  ___, $F, $6                             ; 5FAF row 11  speed 6
    RIF B_2, 1, 0, $F, $A                       ; 5FB1 row 12  Inst00  speed 10
    RF  ___, $F, $6                             ; 5FB4 row 13  speed 6
    RIF C_3, 1, 0, $F, $A                       ; 5FB6 row 14  Inst00  speed 10
    RF  ___, $F, $6                             ; 5FB9 row 15  speed 6
Track015:
    RI  Cs3, 8, 0                               ; 5FBB row 00  Inst07
    R   ___                                     ; 5FBD row 01
    R   ___                                     ; 5FBE row 02
    R   ___                                     ; 5FBF row 03
    R   ___                                     ; 5FC0 row 04
    R   ___                                     ; 5FC1 row 05
    RI  C_3, 8, 0                               ; 5FC2 row 06  Inst07
    R   Cs3                                     ; 5FC4 row 07
    RI  D_3, 8, 0                               ; 5FC5 row 08  Inst07
    R   ___                                     ; 5FC7 row 09
    RI  Cs3, 8, 0                               ; 5FC8 row 10  Inst07
    RI  ___, 0, 3                               ; 5FCA row 11
    RI  B_2, 8, 0                               ; 5FCC row 12  Inst07
    RI  Cs3, 8, 0                               ; 5FCE row 13  Inst07
    RI  ___, 0, 3                               ; 5FD0 row 14
    RI  B_2, 8, 0                               ; 5FD2 row 15  Inst07
Track016:
    RIF Cs3, 1, 0, $F, $A                       ; 5FD4 row 00  Inst00  speed 10
    RF  ___, $F, $6                             ; 5FD7 row 01  speed 6
    RIF E_3, 7, 0, $F, $A                       ; 5FD9 row 02  Inst06  speed 10
    RF  ___, $F, $6                             ; 5FDC row 03  speed 6
    RIF Gs2, 1, 0, $F, $A                       ; 5FDE row 04  Inst00  speed 10
    RF  ___, $F, $6                             ; 5FE1 row 05  speed 6
    RIF E_3, 7, 0, $F, $A                       ; 5FE3 row 06  Inst06  speed 10
    RF  ___, $F, $6                             ; 5FE6 row 07  speed 6
    RIF Cs3, 1, 0, $F, $A                       ; 5FE8 row 08  Inst00  speed 10
    RF  ___, $F, $6                             ; 5FEB row 09  speed 6
    RIF E_3, 7, 0, $F, $A                       ; 5FED row 10  Inst06  speed 10
    RF  ___, $F, $6                             ; 5FF0 row 11  speed 6
    RIF Gs2, 1, 0, $F, $A                       ; 5FF2 row 12  Inst00  speed 10
    RF  ___, $F, $6                             ; 5FF5 row 13  speed 6
    RIF E_3, 7, 0, $F, $A                       ; 5FF7 row 14  Inst06  speed 10
    RF  ___, $F, $6                             ; 5FFA row 15  speed 6
Track017:
    RIF A_2, 1, 0, $F, $A                       ; 5FFC row 00  Inst00  speed 10
    RF  ___, $F, $6                             ; 5FFF row 01  speed 6
    RIF E_3, 10, 0, $F, $A                      ; 6001 row 02  Inst09  speed 10
    RF  ___, $F, $6                             ; 6004 row 03  speed 6
    RIF E_2, 1, 0, $F, $A                       ; 6006 row 04  Inst00  speed 10
    RF  ___, $F, $6                             ; 6009 row 05  speed 6
    RIF E_3, 10, 0, $F, $A                      ; 600B row 06  Inst09  speed 10
    RF  ___, $F, $6                             ; 600E row 07  speed 6
    RIF A_2, 1, 0, $F, $A                       ; 6010 row 08  Inst00  speed 10
    RF  ___, $F, $6                             ; 6013 row 09  speed 6
    RIF E_3, 10, 0, $F, $A                      ; 6015 row 10  Inst09  speed 10
    RF  ___, $F, $6                             ; 6018 row 11  speed 6
    RIF E_2, 1, 0, $F, $A                       ; 601A row 12  Inst00  speed 10
    RF  ___, $F, $6                             ; 601D row 13  speed 6
    RIF E_3, 10, 0, $F, $A                      ; 601F row 14  Inst09  speed 10
    RF  ___, $F, $6                             ; 6022 row 15  speed 6
Track018:
    RIF B_2, 1, 0, $F, $A                       ; 6024 row 00  Inst00  speed 10
    RF  ___, $F, $6                             ; 6027 row 01  speed 6
    RIF D_3, 7, 0, $F, $A                       ; 6029 row 02  Inst06  speed 10
    RF  ___, $F, $6                             ; 602C row 03  speed 6
    RIF Fs2, 1, 0, $F, $A                       ; 602E row 04  Inst00  speed 10
    RF  ___, $F, $6                             ; 6031 row 05  speed 6
    RIF D_3, 7, 0, $F, $A                       ; 6033 row 06  Inst06  speed 10
    RF  ___, $F, $6                             ; 6036 row 07  speed 6
    RIF B_2, 1, 0, $F, $A                       ; 6038 row 08  Inst00  speed 10
    RF  ___, $F, $6                             ; 603B row 09  speed 6
    RIF D_3, 7, 0, $F, $A                       ; 603D row 10  Inst06  speed 10
    RF  ___, $F, $6                             ; 6040 row 11  speed 6
    RIF Fs2, 1, 0, $F, $A                       ; 6042 row 12  Inst00  speed 10
    RF  ___, $F, $6                             ; 6045 row 13  speed 6
    RIF D_3, 7, 0, $F, $A                       ; 6047 row 14  Inst06  speed 10
    RF  ___, $F, $6                             ; 604A row 15  speed 6
Track019:
    R   ___                                     ; 604C row 00
    R   ___                                     ; 604D row 01
    R   ___                                     ; 604E row 02
    R   ___                                     ; 604F row 03
    R   ___                                     ; 6050 row 04
    R   ___                                     ; 6051 row 05
    RI  A_2, 8, 0                               ; 6052 row 06  Inst07
    RI  ___, 0, 3                               ; 6054 row 07
    RI  A_2, 8, 0                               ; 6056 row 08  Inst07
    R   ___                                     ; 6058 row 09
    R   ___                                     ; 6059 row 10
    R   ___                                     ; 605A row 11
    R   ___                                     ; 605B row 12
    R   ___                                     ; 605C row 13
    RI  As2, 8, 0                               ; 605D row 14  Inst07
    R   ___                                     ; 605F row 15
Track020:
    RI  C_3, 4, 0                               ; 6060 row 00  Inst03
    R   ___                                     ; 6062 row 01
    RI  C_3, 6, 0                               ; 6063 row 02  Inst05
    RI  C_3, 6, 0                               ; 6065 row 03  Inst05
    RI  C_3, 3, 0                               ; 6067 row 04  Inst02
    R   ___                                     ; 6069 row 05
    RI  C_3, 6, 0                               ; 606A row 06  Inst05
    RI  C_3, 6, 0                               ; 606C row 07  Inst05
    RI  C_3, 4, 0                               ; 606E row 08  Inst03
    R   ___                                     ; 6070 row 09
    RI  C_3, 6, 0                               ; 6071 row 10  Inst05
    R   ___                                     ; 6073 row 11
    RI  C_3, 3, 0                               ; 6074 row 12  Inst02
    R   ___                                     ; 6076 row 13
    RI  C_3, 6, 0                               ; 6077 row 14  Inst05
    RI  C_3, 3, 0                               ; 6079 row 15  Inst02
Track021:
    RI  B_2, 8, 0                               ; 607B row 00  Inst07
    R   ___                                     ; 607D row 01
    R   ___                                     ; 607E row 02
    R   ___                                     ; 607F row 03
    R   ___                                     ; 6080 row 04
    R   ___                                     ; 6081 row 05
    RI  B_2, 8, 0                               ; 6082 row 06  Inst07
    RI  ___, 0, 3                               ; 6084 row 07
    RI  Cs3, 8, 0                               ; 6086 row 08  Inst07
    RI  ___, 0, 3                               ; 6088 row 09
    RI  B_2, 8, 0                               ; 608A row 10  Inst07
    RI  ___, 0, 3                               ; 608C row 11
    RI  Cs3, 8, 0                               ; 608E row 12  Inst07
    RI  D_3, 8, 0                               ; 6090 row 13  Inst07
    RI  ___, 0, 3                               ; 6092 row 14
    RI  E_3, 8, 0                               ; 6094 row 15  Inst07
Track022:
    R   ___                                     ; 6096 row 00
    R   ___                                     ; 6097 row 01
    R   ___                                     ; 6098 row 02
    R   ___                                     ; 6099 row 03
    R   ___                                     ; 609A row 04
    R   ___                                     ; 609B row 05
    R   ___                                     ; 609C row 06
    R   ___                                     ; 609D row 07
    R   ___                                     ; 609E row 08
    R   ___                                     ; 609F row 09
    RF  ___, $F, $A                             ; 60A0 row 10  speed 10
    RF  ___, $F, $6                             ; 60A2 row 11  speed 6
    RIF B_2, 8, 0, $F, $A                       ; 60A4 row 12  Inst07  speed 10
    RF  ___, $F, $6                             ; 60A7 row 13  speed 6
    RF  ___, $F, $A                             ; 60A9 row 14  speed 10
    RF  ___, $F, $6                             ; 60AB row 15  speed 6
Track023:
    RIF E_3, 1, 0, $F, $A                       ; 60AD row 00  Inst00  speed 10
    RF  ___, $F, $6                             ; 60B0 row 01  speed 6
    RIF C_3, 9, 0, $F, $A                       ; 60B2 row 02  Inst08  speed 10
    RF  ___, $F, $6                             ; 60B5 row 03  speed 6
    RIF B_2, 1, 0, $F, $A                       ; 60B7 row 04  Inst00  speed 10
    RF  ___, $F, $6                             ; 60BA row 05  speed 6
    RIF C_3, 9, 0, $F, $A                       ; 60BC row 06  Inst08  speed 10
    RF  ___, $F, $6                             ; 60BF row 07  speed 6
    RIF E_3, 1, 0, $F, $A                       ; 60C1 row 08  Inst00  speed 10
    RF  ___, $F, $6                             ; 60C4 row 09  speed 6
    RI  A_2, 8, 0                               ; 60C6 row 10  Inst07
    R   ___                                     ; 60C8 row 11
    R   ___                                     ; 60C9 row 12
    R   ___                                     ; 60CA row 13
    RI  C_3, 8, 0                               ; 60CB row 14  Inst07
    R   ___                                     ; 60CD row 15
Track024:
    RI  C_3, 4, 0                               ; 60CE row 00  Inst03
    R   ___                                     ; 60D0 row 01
    RI  C_3, 6, 0                               ; 60D1 row 02  Inst05
    RI  C_3, 6, 0                               ; 60D3 row 03  Inst05
    RI  C_3, 3, 0                               ; 60D5 row 04  Inst02
    R   ___                                     ; 60D7 row 05
    RI  C_3, 6, 0                               ; 60D8 row 06  Inst05
    RI  C_3, 6, 0                               ; 60DA row 07  Inst05
    RI  C_3, 4, 0                               ; 60DC row 08  Inst03
    R   ___                                     ; 60DE row 09
    R   ___                                     ; 60DF row 10
    R   ___                                     ; 60E0 row 11
    R   ___                                     ; 60E1 row 12
    R   ___                                     ; 60E2 row 13
    R   ___                                     ; 60E3 row 14
    R   ___                                     ; 60E4 row 15
Track025:
    RI  A_2, 1, 0                               ; 60E5 row 00  Inst00
    R   ___                                     ; 60E7 row 01
    RI  C_3, 7, 0                               ; 60E8 row 02  Inst06
    R   ___                                     ; 60EA row 03
    RI  E_2, 1, 0                               ; 60EB row 04  Inst00
    R   ___                                     ; 60ED row 05
    RI  C_3, 7, 0                               ; 60EE row 06  Inst06
    R   ___                                     ; 60F0 row 07
    RI  A_2, 1, 0                               ; 60F1 row 08  Inst00
    R   ___                                     ; 60F3 row 09
    RI  C_3, 7, 0                               ; 60F4 row 10  Inst06
    R   ___                                     ; 60F6 row 11
    RI  E_2, 1, 0                               ; 60F7 row 12  Inst00
    R   ___                                     ; 60F9 row 13
    RI  C_3, 7, 0                               ; 60FA row 14  Inst06
    R   ___                                     ; 60FC row 15
Track026:
    RI  Cs4, 5, 0                               ; 60FD row 00  Inst04
    R   ___                                     ; 60FF row 01
    R   ___                                     ; 6100 row 02
    R   ___                                     ; 6101 row 03
    R   ___                                     ; 6102 row 04
    R   ___                                     ; 6103 row 05
    RI  C_4, 5, 0                               ; 6104 row 06  Inst04
    RI  Cs4, 5, 0                               ; 6106 row 07  Inst04
    RI  D_4, 5, 0                               ; 6108 row 08  Inst04
    R   ___                                     ; 610A row 09
    RI  Cs4, 5, 0                               ; 610B row 10  Inst04
    R   ___                                     ; 610D row 11
    RI  C_4, 5, 0                               ; 610E row 12  Inst04
    R   ___                                     ; 6110 row 13
    RI  Cs4, 5, 0                               ; 6111 row 14  Inst04
    RI  A_3, 5, 0                               ; 6113 row 15  Inst04
Track027:
    R   ___                                     ; 6115 row 00
    R   ___                                     ; 6116 row 01
    R   ___                                     ; 6117 row 02
    R   ___                                     ; 6118 row 03
    R   ___                                     ; 6119 row 04
    R   ___                                     ; 611A row 05
    R   ___                                     ; 611B row 06
    R   ___                                     ; 611C row 07
    R   ___                                     ; 611D row 08
    R   ___                                     ; 611E row 09
    RI  A_3, 5, 0                               ; 611F row 10  Inst04
    R   ___                                     ; 6121 row 11
    RI  B_3, 5, 0                               ; 6122 row 12  Inst04
    R   ___                                     ; 6124 row 13
    RI  C_4, 5, 0                               ; 6125 row 14  Inst04
    R   ___                                     ; 6127 row 15
Track028:
    RI  Cs4, 5, 0                               ; 6128 row 00  Inst04
    R   ___                                     ; 612A row 01
    R   ___                                     ; 612B row 02
    R   ___                                     ; 612C row 03
    R   ___                                     ; 612D row 04
    R   ___                                     ; 612E row 05
    RI  C_4, 5, 0                               ; 612F row 06  Inst04
    RI  Cs4, 5, 0                               ; 6131 row 07  Inst04
    RI  D_4, 5, 0                               ; 6133 row 08  Inst04
    R   ___                                     ; 6135 row 09
    RI  Cs4, 5, 0                               ; 6136 row 10  Inst04
    R   ___                                     ; 6138 row 11
    RI  C_4, 5, 0                               ; 6139 row 12  Inst04
    R   ___                                     ; 613B row 13
    RI  Fs4, 5, 0                               ; 613C row 14  Inst04
    RI  E_4, 5, 0                               ; 613E row 15  Inst04
Track029:
    RI  G_3, 5, 0                               ; 6140 row 00  Inst04
    R   ___                                     ; 6142 row 01
    R   ___                                     ; 6143 row 02
    R   ___                                     ; 6144 row 03
    R   ___                                     ; 6145 row 04
    R   ___                                     ; 6146 row 05
    R   ___                                     ; 6147 row 06
    R   ___                                     ; 6148 row 07
    R   ___                                     ; 6149 row 08
    R   ___                                     ; 614A row 09
    R   ___                                     ; 614B row 10
    R   ___                                     ; 614C row 11
    R   ___                                     ; 614D row 12
    R   ___                                     ; 614E row 13
    R   ___                                     ; 614F row 14
    R   ___                                     ; 6150 row 15
Track030:
    R   D_4                                     ; 6151 row 00
    R   ___                                     ; 6152 row 01
    R   ___                                     ; 6153 row 02
    R   ___                                     ; 6154 row 03
    R   ___                                     ; 6155 row 04
    R   ___                                     ; 6156 row 05
    R   ___                                     ; 6157 row 06
    R   ___                                     ; 6158 row 07
    R   ___                                     ; 6159 row 08
    R   ___                                     ; 615A row 09
    RI  B_3, 5, 0                               ; 615B row 10  Inst04
    R   ___                                     ; 615D row 11
    RI  C_4, 5, 0                               ; 615E row 12  Inst04
    R   ___                                     ; 6160 row 13
    RI  B_3, 5, 0                               ; 6161 row 14  Inst04
    R   ___                                     ; 6163 row 15
Track031:
    RI  D_2, 1, 0                               ; 6164 row 00  Inst00
    R   ___                                     ; 6166 row 01
    RI  F_2, 7, 0                               ; 6167 row 02  Inst06
    R   ___                                     ; 6169 row 03
    RI  Fs2, 1, 0                               ; 616A row 04  Inst00
    R   ___                                     ; 616C row 05
    RI  F_2, 7, 0                               ; 616D row 06  Inst06
    R   ___                                     ; 616F row 07
    RI  G_2, 1, 0                               ; 6170 row 08  Inst00
    R   ___                                     ; 6172 row 09
    RI  F_2, 7, 0                               ; 6173 row 10  Inst06
    R   ___                                     ; 6175 row 11
    RI  Fs2, 1, 0                               ; 6176 row 12  Inst00
    R   ___                                     ; 6178 row 13
    RI  F_2, 7, 0                               ; 6179 row 14  Inst06
    R   ___                                     ; 617B row 15
Track032:
    RIF C_3, 4, 0, $F, $7                       ; 617C row 00  Inst03  speed 7
    RF  ___, $F, $6                             ; 617F row 01  speed 6
    RIF C_3, 6, 0, $F, $7                       ; 6181 row 02  Inst05  speed 7
    RF  ___, $F, $6                             ; 6184 row 03  speed 6
    RIF C_3, 4, 0, $F, $7                       ; 6186 row 04  Inst03  speed 7
    RF  ___, $F, $6                             ; 6189 row 05  speed 6
    RIF C_3, 6, 0, $F, $7                       ; 618B row 06  Inst05  speed 7
    RF  ___, $F, $6                             ; 618E row 07  speed 6
    RIF C_3, 4, 0, $F, $7                       ; 6190 row 08  Inst03  speed 7
    RF  ___, $F, $6                             ; 6193 row 09  speed 6
    RIF C_3, 6, 0, $F, $7                       ; 6195 row 10  Inst05  speed 7
    RF  ___, $F, $6                             ; 6198 row 11  speed 6
    RIF C_3, 4, 0, $F, $7                       ; 619A row 12  Inst03  speed 7
    RF  ___, $F, $6                             ; 619D row 13  speed 6
    RIF C_3, 6, 0, $F, $7                       ; 619F row 14  Inst05  speed 7
    RF  ___, $F, $6                             ; 61A2 row 15  speed 6
Track033:
    RI  D_3, 12, 0                              ; 61A4 row 00  Inst11
    RI  ___, 0, 1                               ; 61A6 row 01
    RI  D_3, 8, 0                               ; 61A8 row 02  Inst07
    RI  ___, 0, 1                               ; 61AA row 03
    RI  D_3, 12, 0                              ; 61AC row 04  Inst11
    RI  ___, 0, 1                               ; 61AE row 05
    RI  C_3, 8, 0                               ; 61B0 row 06  Inst07
    RI  ___, 0, 1                               ; 61B2 row 07
    RI  A_2, 12, 0                              ; 61B4 row 08  Inst11
    RI  ___, 0, 1                               ; 61B6 row 09
    RI  A_2, 8, 0                               ; 61B8 row 10  Inst07
    RI  ___, 0, 1                               ; 61BA row 11
    RI  C_3, 12, 0                              ; 61BC row 12  Inst11
    RI  ___, 0, 1                               ; 61BE row 13
    RI  Cs3, 8, 0                               ; 61C0 row 14  Inst07
    RI  ___, 0, 1                               ; 61C2 row 15
Track034:
    RI  D_3, 12, 0                              ; 61C4 row 00  Inst11
    RI  ___, 0, 1                               ; 61C6 row 01
    RI  D_3, 8, 0                               ; 61C8 row 02  Inst07
    RI  ___, 0, 1                               ; 61CA row 03
    RI  D_3, 12, 0                              ; 61CC row 04  Inst11
    RI  ___, 0, 1                               ; 61CE row 05
    RI  C_3, 8, 0                               ; 61D0 row 06  Inst07
    RI  ___, 0, 1                               ; 61D2 row 07
    RI  A_2, 12, 0                              ; 61D4 row 08  Inst11
    RI  ___, 0, 1                               ; 61D6 row 09
    R   ___                                     ; 61D8 row 10
    R   ___                                     ; 61D9 row 11
    RI  C_3, 12, 0                              ; 61DA row 12  Inst11
    RI  ___, 0, 1                               ; 61DC row 13
    RI  Cs3, 8, 0                               ; 61DE row 14  Inst07
    RI  ___, 0, 1                               ; 61E0 row 15
Track035:
    RI  D_3, 12, 0                              ; 61E2 row 00  Inst11
    RI  ___, 0, 1                               ; 61E4 row 01
    RI  D_3, 8, 0                               ; 61E6 row 02  Inst07
    RI  ___, 0, 1                               ; 61E8 row 03
    RI  D_3, 12, 0                              ; 61EA row 04  Inst11
    RI  ___, 0, 1                               ; 61EC row 05
    RI  C_3, 8, 0                               ; 61EE row 06  Inst07
    RI  ___, 0, 1                               ; 61F0 row 07
    RI  A_2, 12, 0                              ; 61F2 row 08  Inst11
    RI  ___, 0, 1                               ; 61F4 row 09
    R   ___                                     ; 61F6 row 10
    RI  ___, 0, 1                               ; 61F7 row 11
    RI  D_3, 12, 0                              ; 61F9 row 12  Inst11
    RI  ___, 0, 1                               ; 61FB row 13
    RI  F_3, 12, 0                              ; 61FD row 14  Inst11
    RI  ___, 0, 1                               ; 61FF row 15
Track036:
    R   ___                                     ; 6201 row 00
    R   ___                                     ; 6202 row 01
    RI  As4, 11, 0                              ; 6203 row 02  Inst10
    R   ___                                     ; 6205 row 03
    RI  G_4, 11, 0                              ; 6206 row 04  Inst10
    RI  F_4, 11, 0                              ; 6208 row 05  Inst10
    R   ___                                     ; 620A row 06
    RI  As5, 11, 0                              ; 620B row 07  Inst10
    R   ___                                     ; 620D row 08
    RI  Gs5, 11, 0                              ; 620E row 09  Inst10
    RI  F_5, 11, 0                              ; 6210 row 10  Inst10
    RI  Ds5, 11, 0                              ; 6212 row 11  Inst10
    RI  D_5, 11, 0                              ; 6214 row 12  Inst10
    RI  Ds5, 11, 0                              ; 6216 row 13  Inst10
    RI  F_5, 11, 0                              ; 6218 row 14  Inst10
    RI  As4, 11, 0                              ; 621A row 15  Inst10
Track037:
    RI  D_3, 12, 0                              ; 621C row 00  Inst11
    RI  ___, 0, 1                               ; 621E row 01
    RI  D_3, 8, 0                               ; 6220 row 02  Inst07
    RI  ___, 0, 1                               ; 6222 row 03
    RI  D_3, 12, 0                              ; 6224 row 04  Inst11
    RI  ___, 0, 1                               ; 6226 row 05
    RI  C_3, 8, 0                               ; 6228 row 06  Inst07
    RI  ___, 0, 1                               ; 622A row 07
    RI  A_2, 12, 0                              ; 622C row 08  Inst11
    RI  ___, 0, 1                               ; 622E row 09
    R   ___                                     ; 6230 row 10
    RI  ___, 0, 1                               ; 6231 row 11
    RI  E_2, 12, 0                              ; 6233 row 12  Inst11
    RI  ___, 0, 1                               ; 6235 row 13
    RI  G_2, 12, 0                              ; 6237 row 14  Inst11
    RI  ___, 0, 1                               ; 6239 row 15
Track038:
    RI  A_2, 12, 0                              ; 623B row 00  Inst11
    R   ___                                     ; 623D row 01
    RI  ___, 0, 1                               ; 623E row 02
    R   ___                                     ; 6240 row 03
    RI  A_2, 8, 0                               ; 6241 row 04  Inst07
    R   ___                                     ; 6243 row 05
    RI  ___, 0, 1                               ; 6244 row 06
    R   ___                                     ; 6246 row 07
    RI  C_3, 12, 0                              ; 6247 row 08  Inst11
    R   ___                                     ; 6249 row 09
    RI  A_2, 12, 0                              ; 624A row 10  Inst11
    R   ___                                     ; 624C row 11
    RI  C_3, 12, 0                              ; 624D row 12  Inst11
    R   ___                                     ; 624F row 13
    RI  Cs3, 12, 0                              ; 6250 row 14  Inst11
    R   ___                                     ; 6252 row 15
Track039:
    RI  A_2, 1, 0                               ; 6253 row 00  Inst00
    R   ___                                     ; 6255 row 01
    RI  C_3, 7, 0                               ; 6256 row 02  Inst06
    R   ___                                     ; 6258 row 03
    RI  E_2, 1, 0                               ; 6259 row 04  Inst00
    R   ___                                     ; 625B row 05
    RI  C_3, 7, 0                               ; 625C row 06  Inst06
    R   ___                                     ; 625E row 07
    RI  A_2, 1, 0                               ; 625F row 08  Inst00
    RI  C_3, 12, 0                              ; 6261 row 09  Inst11
    R   ___                                     ; 6263 row 10
    RI  A_2, 12, 0                              ; 6264 row 11  Inst11
    R   ___                                     ; 6266 row 12
    RI  C_3, 12, 0                              ; 6267 row 13  Inst11
    R   ___                                     ; 6269 row 14
    RI  Cs3, 12, 0                              ; 626A row 15  Inst11
Track040:
    RI  F_2, 1, 0                               ; 626C row 00  Inst00
    RI  ___, 0, 3                               ; 626E row 01
    R   ___                                     ; 6270 row 02
    RI  F_4, 11, 1                              ; 6271 row 03  Inst10
    R   ___                                     ; 6273 row 04
    RI  F_4, 11, 1                              ; 6274 row 05  Inst10
    R   ___                                     ; 6276 row 06
    R   ___                                     ; 6277 row 07
    RI  F_2, 1, 0                               ; 6278 row 08  Inst00
    RI  F_4, 11, 1                              ; 627A row 09  Inst10
    R   ___                                     ; 627C row 10
    RI  F_4, 11, 1                              ; 627D row 11  Inst10
    RI  F_4, 11, 1                              ; 627F row 12  Inst10
    R   ___                                     ; 6281 row 13
    RI  Ds2, 1, 0                               ; 6282 row 14  Inst00
    RI  ___, 0, 3                               ; 6284 row 15
Track041:
    RI  F_3, 1, 0                               ; 6286 row 00  Inst00
    RI  ___, 0, 3                               ; 6288 row 01
    R   ___                                     ; 628A row 02
    RI  F_4, 11, 1                              ; 628B row 03  Inst10
    R   ___                                     ; 628D row 04
    RI  F_4, 11, 1                              ; 628E row 05  Inst10
    R   ___                                     ; 6290 row 06
    R   ___                                     ; 6291 row 07
    RI  F_3, 1, 0                               ; 6292 row 08  Inst00
    RI  F_4, 11, 1                              ; 6294 row 09  Inst10
    R   ___                                     ; 6296 row 10
    RI  F_4, 11, 1                              ; 6297 row 11  Inst10
    RI  F_4, 11, 1                              ; 6299 row 12  Inst10
    R   ___                                     ; 629B row 13
    RI  C_3, 1, 0                               ; 629C row 14  Inst00
    RI  ___, 0, 3                               ; 629E row 15
Track042:
    RIF D_3, 1, 0, $F, $7                       ; 62A0 row 00  Inst00  speed 7
    RI  ___, 0, 3                               ; 62A3 row 01
    RI  D_4, 1, 0                               ; 62A5 row 02  Inst00
    RI  ___, 0, 3                               ; 62A7 row 03
    RI  A_2, 1, 0                               ; 62A9 row 04  Inst00
    RI  ___, 0, 3                               ; 62AB row 05
    RI  A_3, 1, 0                               ; 62AD row 06  Inst00
    RI  ___, 0, 3                               ; 62AF row 07
    RI  D_3, 1, 0                               ; 62B1 row 08  Inst00
    RI  ___, 0, 3                               ; 62B3 row 09
    RI  D_4, 1, 0                               ; 62B5 row 10  Inst00
    RI  ___, 0, 3                               ; 62B7 row 11
    RI  A_2, 1, 0                               ; 62B9 row 12  Inst00
    RI  ___, 0, 3                               ; 62BB row 13
    RI  A_3, 1, 0                               ; 62BD row 14  Inst00
    R   ___                                     ; 62BF row 15
Track043:
    RI  C_3, 4, 0                               ; 62C0 row 00  Inst03
    R   ___                                     ; 62C2 row 01
    RI  C_3, 6, 0                               ; 62C3 row 02  Inst05
    R   ___                                     ; 62C5 row 03
    RI  C_3, 3, 0                               ; 62C6 row 04  Inst02
    R   ___                                     ; 62C8 row 05
    RI  C_3, 6, 0                               ; 62C9 row 06  Inst05
    R   ___                                     ; 62CB row 07
    RI  C_3, 4, 0                               ; 62CC row 08  Inst03
    R   ___                                     ; 62CE row 09
    RI  C_3, 6, 0                               ; 62CF row 10  Inst05
    RI  C_3, 6, 0                               ; 62D1 row 11  Inst05
    RI  C_3, 3, 0                               ; 62D3 row 12  Inst02
    R   ___                                     ; 62D5 row 13
    RI  C_3, 6, 0                               ; 62D6 row 14  Inst05
    R   ___                                     ; 62D8 row 15
Track044:
    RI  D_3, 12, 0                              ; 62D9 row 00  Inst11
    RI  ___, 0, 3                               ; 62DB row 01
    RI  E_3, 12, 0                              ; 62DD row 02  Inst11
    RI  ___, 0, 3                               ; 62DF row 03
    RI  F_3, 12, 0                              ; 62E1 row 04  Inst11
    RI  ___, 0, 3                               ; 62E3 row 05
    RI  A_3, 12, 0                              ; 62E5 row 06  Inst11
    RI  ___, 0, 3                               ; 62E7 row 07
    RI  Gs3, 12, 0                              ; 62E9 row 08  Inst11
    RI  ___, 0, 3                               ; 62EB row 09
    RI  G_3, 12, 0                              ; 62ED row 10  Inst11
    RI  F_3, 12, 0                              ; 62EF row 11  Inst11
    RI  E_3, 12, 0                              ; 62F1 row 12  Inst11
    RI  ___, 0, 3                               ; 62F3 row 13
    RI  F_3, 12, 0                              ; 62F5 row 14  Inst11
    RI  ___, 0, 3                               ; 62F7 row 15
Track045:
    RI  D_3, 12, 0                              ; 62F9 row 00  Inst11
    RI  ___, 0, 3                               ; 62FB row 01
    RI  E_3, 12, 0                              ; 62FD row 02  Inst11
    RI  ___, 0, 3                               ; 62FF row 03
    RI  F_3, 12, 0                              ; 6301 row 04  Inst11
    RI  ___, 0, 3                               ; 6303 row 05
    RI  A_3, 12, 0                              ; 6305 row 06  Inst11
    RI  ___, 0, 3                               ; 6307 row 07
    RI  Gs3, 12, 0                              ; 6309 row 08  Inst11
    R   A_3                                     ; 630B row 09
    R   Gs3                                     ; 630C row 10
    R   A_3                                     ; 630D row 11
    RI  Gs3, 12, 0                              ; 630E row 12  Inst11
    RI  ___, 0, 3                               ; 6310 row 13
    RI  A_3, 12, 0                              ; 6312 row 14  Inst11
    RI  ___, 0, 3                               ; 6314 row 15
Track046:
    RI  D_3, 1, 0                               ; 6316 row 00  Inst00
    R   ___                                     ; 6318 row 01
    R   ___                                     ; 6319 row 02
    R   ___                                     ; 631A row 03
    RI  Cs3, 1, 0                               ; 631B row 04  Inst00
    R   ___                                     ; 631D row 05
    R   ___                                     ; 631E row 06
    R   ___                                     ; 631F row 07
    RI  As2, 1, 0                               ; 6320 row 08  Inst00
    R   ___                                     ; 6322 row 09
    R   ___                                     ; 6323 row 10
    R   ___                                     ; 6324 row 11
    RI  A_2, 1, 0                               ; 6325 row 12  Inst00
    R   ___                                     ; 6327 row 13
    R   ___                                     ; 6328 row 14
    R   ___                                     ; 6329 row 15
Track047:
    R   ___                                     ; 632A row 00
    RI  D_3, 12, 0                              ; 632B row 01  Inst11
    R   ___                                     ; 632D row 02
    R   ___                                     ; 632E row 03
    R   ___                                     ; 632F row 04
    RI  Cs3, 12, 0                              ; 6330 row 05  Inst11
    R   ___                                     ; 6332 row 06
    R   ___                                     ; 6333 row 07
    R   ___                                     ; 6334 row 08
    RI  As2, 12, 0                              ; 6335 row 09  Inst11
    R   ___                                     ; 6337 row 10
    R   ___                                     ; 6338 row 11
    R   ___                                     ; 6339 row 12
    RI  A_2, 12, 0                              ; 633A row 13  Inst11
    R   ___                                     ; 633C row 14
    R   ___                                     ; 633D row 15
Track048:
    RI  C_3, 4, 0                               ; 633E row 00  Inst03
    R   ___                                     ; 6340 row 01
    RI  C_3, 6, 0                               ; 6341 row 02  Inst05
    RI  C_3, 6, 0                               ; 6343 row 03  Inst05
    RI  C_3, 3, 0                               ; 6345 row 04  Inst02
    R   ___                                     ; 6347 row 05
    RI  C_3, 6, 0                               ; 6348 row 06  Inst05
    RI  C_3, 6, 0                               ; 634A row 07  Inst05
    RI  C_3, 4, 0                               ; 634C row 08  Inst03
    R   ___                                     ; 634E row 09
    RI  C_3, 6, 0                               ; 634F row 10  Inst05
    RI  C_3, 6, 0                               ; 6351 row 11  Inst05
    RI  C_3, 3, 0                               ; 6353 row 12  Inst02
    R   ___                                     ; 6355 row 13
    RI  C_3, 3, 0                               ; 6356 row 14  Inst02
    R   ___                                     ; 6358 row 15
Track049:
    R   ___                                     ; 6359 row 00
    R   ___                                     ; 635A row 01
    RI  Fs3, 1, 0                               ; 635B row 02  Inst00
    R   ___                                     ; 635D row 03
    R   ___                                     ; 635E row 04
    R   ___                                     ; 635F row 05
    RI  B_3, 1, 0                               ; 6360 row 06  Inst00
    R   ___                                     ; 6362 row 07
    R   ___                                     ; 6363 row 08
    R   ___                                     ; 6364 row 09
    RI  G_3, 1, 0                               ; 6365 row 10  Inst00
    R   ___                                     ; 6367 row 11
    R   ___                                     ; 6368 row 12
    R   ___                                     ; 6369 row 13
    RI  G_3, 1, 0                               ; 636A row 14  Inst00
    R   ___                                     ; 636C row 15
Track050:
    RI  E_3, 1, 0                               ; 636D row 00  Inst00
    R   ___                                     ; 636F row 01
    R   ___                                     ; 6370 row 02
    R   ___                                     ; 6371 row 03
    RI  G_3, 1, 0                               ; 6372 row 04  Inst00
    R   ___                                     ; 6374 row 05
    R   ___                                     ; 6375 row 06
    R   ___                                     ; 6376 row 07
    RI  As3, 1, 0                               ; 6377 row 08  Inst00
    R   ___                                     ; 6379 row 09
    R   ___                                     ; 637A row 10
    R   ___                                     ; 637B row 11
    RI  Fs3, 1, 0                               ; 637C row 12  Inst00
    R   ___                                     ; 637E row 13
    R   ___                                     ; 637F row 14
    R   ___                                     ; 6380 row 15
Track051:
    R   ___                                     ; 6381 row 00
    RI  D_3, 1, 1                               ; 6382 row 01  Inst00
    R   ___                                     ; 6384 row 02
    RI  D_4, 1, 1                               ; 6385 row 03  Inst00
    R   ___                                     ; 6387 row 04
    RI  A_2, 1, 1                               ; 6388 row 05  Inst00
    R   ___                                     ; 638A row 06
    RI  A_3, 1, 1                               ; 638B row 07  Inst00
    R   ___                                     ; 638D row 08
    RI  D_3, 1, 1                               ; 638E row 09  Inst00
    R   ___                                     ; 6390 row 10
    RI  D_4, 1, 1                               ; 6391 row 11  Inst00
    R   ___                                     ; 6393 row 12
    RI  A_2, 1, 1                               ; 6394 row 13  Inst00
    R   ___                                     ; 6396 row 14
    RI  A_3, 1, 1                               ; 6397 row 15  Inst00
Track052:
    RIF G_2, 1, 0, $F, $7                       ; 6399 row 00  Inst00  speed 7
    RI  ___, 0, 3                               ; 639C row 01
    RI  G_3, 1, 0                               ; 639E row 02  Inst00
    R   ___                                     ; 63A0 row 03
    RI  D_2, 1, 0                               ; 63A1 row 04  Inst00
    RI  ___, 0, 3                               ; 63A3 row 05
    RI  D_3, 1, 0                               ; 63A5 row 06  Inst00
    R   ___                                     ; 63A7 row 07
    RI  G_2, 1, 0                               ; 63A8 row 08  Inst00
    RI  ___, 0, 3                               ; 63AA row 09
    RI  G_3, 1, 0                               ; 63AC row 10  Inst00
    R   ___                                     ; 63AE row 11
    RI  D_2, 1, 0                               ; 63AF row 12  Inst00
    RI  ___, 0, 3                               ; 63B1 row 13
    RI  D_3, 1, 0                               ; 63B3 row 14  Inst00
    R   ___                                     ; 63B5 row 15
Track053:
    RI  C_3, 4, 0                               ; 63B6 row 00  Inst03
    R   ___                                     ; 63B8 row 01
    RI  C_3, 6, 0                               ; 63B9 row 02  Inst05
    R   ___                                     ; 63BB row 03
    RI  C_3, 3, 0                               ; 63BC row 04  Inst02
    R   ___                                     ; 63BE row 05
    RI  C_3, 6, 0                               ; 63BF row 06  Inst05
    RI  C_3, 6, 0                               ; 63C1 row 07  Inst05
    RI  C_3, 4, 0                               ; 63C3 row 08  Inst03
    R   ___                                     ; 63C5 row 09
    RI  C_3, 6, 0                               ; 63C6 row 10  Inst05
    R   ___                                     ; 63C8 row 11
    RI  C_3, 3, 0                               ; 63C9 row 12  Inst02
    R   ___                                     ; 63CB row 13
    RI  C_3, 3, 0                               ; 63CC row 14  Inst02
    R   ___                                     ; 63CE row 15
Track054:
    RI  D_3, 5, 0                               ; 63CF row 00  Inst04
    R   ___                                     ; 63D1 row 01
    R   ___                                     ; 63D2 row 02
    R   ___                                     ; 63D3 row 03
    RI  G_3, 5, 0                               ; 63D4 row 04  Inst04
    R   ___                                     ; 63D6 row 05
    RI  B_3, 5, 0                               ; 63D7 row 06  Inst04
    R   ___                                     ; 63D9 row 07
    R   ___                                     ; 63DA row 08
    R   ___                                     ; 63DB row 09
    RI  G_3, 5, 0                               ; 63DC row 10  Inst04
    R   ___                                     ; 63DE row 11
    R   ___                                     ; 63DF row 12
    R   ___                                     ; 63E0 row 13
    RI  A_3, 5, 0                               ; 63E1 row 14  Inst04
    R   ___                                     ; 63E3 row 15
Track055:
    R   ___                                     ; 63E4 row 00
    R   ___                                     ; 63E5 row 01
    RI  A_3, 5, 0                               ; 63E6 row 02  Inst04
    R   ___                                     ; 63E8 row 03
    RI  A_3, 5, 0                               ; 63E9 row 04  Inst04
    R   ___                                     ; 63EB row 05
    RI  F_3, 5, 0                               ; 63EC row 06  Inst04
    R   ___                                     ; 63EE row 07
    RI  C_3, 5, 0                               ; 63EF row 08  Inst04
    R   ___                                     ; 63F1 row 09
    R   ___                                     ; 63F2 row 10
    R   ___                                     ; 63F3 row 11
    RI  A_2, 5, 0                               ; 63F4 row 12  Inst04
    R   ___                                     ; 63F6 row 13
    R   ___                                     ; 63F7 row 14
    R   ___                                     ; 63F8 row 15
Track056:
    R   ___                                     ; 63F9 row 00
    R   ___                                     ; 63FA row 01
    RI  C_4, 5, 0                               ; 63FB row 02  Inst04
    R   ___                                     ; 63FD row 03
    RI  C_4, 5, 0                               ; 63FE row 04  Inst04
    R   ___                                     ; 6400 row 05
    RI  B_3, 5, 0                               ; 6401 row 06  Inst04
    R   ___                                     ; 6403 row 07
    RI  A_3, 5, 0                               ; 6404 row 08  Inst04
    R   ___                                     ; 6406 row 09
    R   ___                                     ; 6407 row 10
    R   ___                                     ; 6408 row 11
    RI  G_4, 2, 0                               ; 6409 row 12  Inst01
    R   ___                                     ; 640B row 13
    RI  A_4, 2, 0                               ; 640C row 14  Inst01
    R   ___                                     ; 640E row 15
Track057:
    RI  D_3, 5, 0                               ; 640F row 00  Inst04
    R   ___                                     ; 6411 row 01
    R   ___                                     ; 6412 row 02
    R   ___                                     ; 6413 row 03
    RI  G_3, 5, 0                               ; 6414 row 04  Inst04
    R   ___                                     ; 6416 row 05
    RI  B_3, 5, 0                               ; 6417 row 06  Inst04
    R   ___                                     ; 6419 row 07
    R   ___                                     ; 641A row 08
    R   ___                                     ; 641B row 09
    RI  G_3, 5, 0                               ; 641C row 10  Inst04
    R   ___                                     ; 641E row 11
    R   ___                                     ; 641F row 12
    R   ___                                     ; 6420 row 13
    RI  C_4, 5, 0                               ; 6421 row 14  Inst04
    R   ___                                     ; 6423 row 15
Track058:
    RI  G_2, 1, 0                               ; 6424 row 00  Inst00
    R   ___                                     ; 6426 row 01
    RI  D_3, 10, 0                              ; 6427 row 02  Inst09
    RI  G_3, 1, 0                               ; 6429 row 03  Inst00
    RI  D_2, 1, 0                               ; 642B row 04  Inst00
    R   ___                                     ; 642D row 05
    RI  D_3, 10, 0                              ; 642E row 06  Inst09
    RI  D_3, 1, 0                               ; 6430 row 07  Inst00
    RI  G_2, 1, 0                               ; 6432 row 08  Inst00
    R   ___                                     ; 6434 row 09
    RI  D_3, 10, 0                              ; 6435 row 10  Inst09
    RI  G_3, 1, 0                               ; 6437 row 11  Inst00
    RI  D_2, 1, 0                               ; 6439 row 12  Inst00
    R   ___                                     ; 643B row 13
    RI  D_3, 10, 0                              ; 643C row 14  Inst09
    RI  D_3, 1, 0                               ; 643E row 15  Inst00
Track059:
    RI  Ds3, 1, 0                               ; 6440 row 00  Inst00
    R   ___                                     ; 6442 row 01
    RI  Ds4, 1, 0                               ; 6443 row 02  Inst00
    R   ___                                     ; 6445 row 03
    RI  As2, 1, 0                               ; 6446 row 04  Inst00
    R   ___                                     ; 6448 row 05
    RI  As3, 1, 0                               ; 6449 row 06  Inst00
    R   ___                                     ; 644B row 07
    RI  Ds3, 1, 0                               ; 644C row 08  Inst00
    R   ___                                     ; 644E row 09
    RI  Ds4, 1, 0                               ; 644F row 10  Inst00
    R   ___                                     ; 6451 row 11
    RI  As2, 1, 0                               ; 6452 row 12  Inst00
    R   ___                                     ; 6454 row 13
    RI  As3, 1, 0                               ; 6455 row 14  Inst00
    R   ___                                     ; 6457 row 15
Track060:
    RI  C_3, 4, 0                               ; 6458 row 00  Inst03
    R   ___                                     ; 645A row 01
    RI  C_3, 6, 0                               ; 645B row 02  Inst05
    RI  C_3, 6, 0                               ; 645D row 03  Inst05
    RI  C_3, 3, 0                               ; 645F row 04  Inst02
    R   ___                                     ; 6461 row 05
    RI  C_3, 6, 0                               ; 6462 row 06  Inst05
    RI  C_3, 6, 0                               ; 6464 row 07  Inst05
    RI  C_3, 4, 0                               ; 6466 row 08  Inst03
    R   ___                                     ; 6468 row 09
    RI  C_3, 6, 0                               ; 6469 row 10  Inst05
    RI  C_3, 6, 0                               ; 646B row 11  Inst05
    RI  C_3, 3, 0                               ; 646D row 12  Inst02
    R   ___                                     ; 646F row 13
    RI  C_3, 6, 0                               ; 6470 row 14  Inst05
    RI  C_3, 6, 0                               ; 6472 row 15  Inst05
Track061:
    RI  Ds4, 5, 0                               ; 6474 row 00  Inst04
    R   ___                                     ; 6476 row 01
    R   ___                                     ; 6477 row 02
    R   ___                                     ; 6478 row 03
    RI  G_4, 5, 0                               ; 6479 row 04  Inst04
    R   ___                                     ; 647B row 05
    RI  As4, 5, 0                               ; 647C row 06  Inst04
    R   ___                                     ; 647E row 07
    R   ___                                     ; 647F row 08
    R   ___                                     ; 6480 row 09
    RI  G_4, 5, 0                               ; 6481 row 10  Inst04
    R   ___                                     ; 6483 row 11
    R   ___                                     ; 6484 row 12
    R   ___                                     ; 6485 row 13
    RI  C_5, 5, 0                               ; 6486 row 14  Inst04
    R   ___                                     ; 6488 row 15
Track062:
    R   ___                                     ; 6489 row 00
    R   ___                                     ; 648A row 01
    RI  C_5, 5, 0                               ; 648B row 02  Inst04
    R   ___                                     ; 648D row 03
    RI  C_5, 5, 0                               ; 648E row 04  Inst04
    R   ___                                     ; 6490 row 05
    RI  Gs4, 5, 0                               ; 6491 row 06  Inst04
    R   ___                                     ; 6493 row 07
    RI  Ds4, 5, 0                               ; 6494 row 08  Inst04
    R   ___                                     ; 6496 row 09
    R   ___                                     ; 6497 row 10
    R   ___                                     ; 6498 row 11
    RI  C_4, 5, 0                               ; 6499 row 12  Inst04
    R   ___                                     ; 649B row 13
    R   ___                                     ; 649C row 14
    R   ___                                     ; 649D row 15
Track063:
    R   ___                                     ; 649E row 00
    R   ___                                     ; 649F row 01
    RI  C_5, 5, 0                               ; 64A0 row 02  Inst04
    R   ___                                     ; 64A2 row 03
    RI  C_5, 5, 0                               ; 64A3 row 04  Inst04
    R   ___                                     ; 64A5 row 05
    RI  Ds5, 5, 0                               ; 64A6 row 06  Inst04
    R   ___                                     ; 64A8 row 07
    RI  C_5, 5, 0                               ; 64A9 row 08  Inst04
    R   ___                                     ; 64AB row 09
    R   ___                                     ; 64AC row 10
    R   ___                                     ; 64AD row 11
    RI  Ds4, 10, 0                              ; 64AE row 12  Inst09
    R   ___                                     ; 64B0 row 13
    RI  Ds4, 10, 0                              ; 64B1 row 14  Inst09
    R   ___                                     ; 64B3 row 15
Track064:
    RI  C_4, 4, 0                               ; 64B4 row 00  Inst03
    R   ___                                     ; 64B6 row 01
    RI  C_4, 6, 0                               ; 64B7 row 02  Inst05
    R   ___                                     ; 64B9 row 03
    RI  C_4, 4, 0                               ; 64BA row 04  Inst03
    R   ___                                     ; 64BC row 05
    RI  C_4, 6, 0                               ; 64BD row 06  Inst05
    R   ___                                     ; 64BF row 07
    RI  C_4, 4, 0                               ; 64C0 row 08  Inst03
    R   ___                                     ; 64C2 row 09
    RI  C_4, 6, 0                               ; 64C3 row 10  Inst05
    R   ___                                     ; 64C5 row 11
    RI  C_4, 4, 0                               ; 64C6 row 12  Inst03
    R   ___                                     ; 64C8 row 13
    RI  C_4, 6, 0                               ; 64C9 row 14  Inst05
    R   ___                                     ; 64CB row 15
Track065:
    RI  G_2, 1, 0                               ; 64CC row 00  Inst00
    R   ___                                     ; 64CE row 01
    R   ___                                     ; 64CF row 02
    RI  G_2, 1, 0                               ; 64D0 row 03  Inst00
    RI  D_3, 1, 0                               ; 64D2 row 04  Inst00
    R   ___                                     ; 64D4 row 05
    R   ___                                     ; 64D5 row 06
    RI  D_2, 1, 0                               ; 64D6 row 07  Inst00
    RI  G_2, 1, 0                               ; 64D8 row 08  Inst00
    R   ___                                     ; 64DA row 09
    R   ___                                     ; 64DB row 10
    RI  G_2, 1, 0                               ; 64DC row 11  Inst00
    RI  D_3, 1, 0                               ; 64DE row 12  Inst00
    R   ___                                     ; 64E0 row 13
    R   ___                                     ; 64E1 row 14
    RI  D_3, 1, 0                               ; 64E2 row 15  Inst00
Track066:
    RI  C_2, 1, 0                               ; 64E4 row 00  Inst00
    R   ___                                     ; 64E6 row 01
    R   ___                                     ; 64E7 row 02
    RI  G_2, 1, 0                               ; 64E8 row 03  Inst00
    RI  As2, 1, 0                               ; 64EA row 04  Inst00
    RI  C_3, 1, 0                               ; 64EC row 05  Inst00
    R   ___                                     ; 64EE row 06
    RI  C_2, 1, 0                               ; 64EF row 07  Inst00
    R   ___                                     ; 64F1 row 08
    RI  C_2, 1, 0                               ; 64F2 row 09  Inst00
    R   ___                                     ; 64F4 row 10
    RI  G_2, 1, 0                               ; 64F5 row 11  Inst00
    RI  As2, 1, 0                               ; 64F7 row 12  Inst00
    R   ___                                     ; 64F9 row 13
    RI  C_3, 1, 0                               ; 64FA row 14  Inst00
    R   ___                                     ; 64FC row 15
Track067:
    RIF C_3, 4, 0, $F, $A                       ; 64FD row 00  Inst03  speed 10
    RF  ___, $F, $6                             ; 6500 row 01  speed 6
    RIF C_3, 6, 0, $F, $A                       ; 6502 row 02  Inst05  speed 10
    RF  ___, $F, $6                             ; 6505 row 03  speed 6
    RIF C_3, 4, 0, $F, $A                       ; 6507 row 04  Inst03  speed 10
    RF  ___, $F, $6                             ; 650A row 05  speed 6
    RIF C_3, 6, 0, $F, $A                       ; 650C row 06  Inst05  speed 10
    RF  ___, $F, $6                             ; 650F row 07  speed 6
    RIF C_3, 4, 0, $F, $A                       ; 6511 row 08  Inst03  speed 10
    RF  ___, $F, $6                             ; 6514 row 09  speed 6
    RIF C_3, 6, 0, $F, $A                       ; 6516 row 10  Inst05  speed 10
    RF  ___, $F, $6                             ; 6519 row 11  speed 6
    RIF C_3, 4, 0, $F, $A                       ; 651B row 12  Inst03  speed 10
    RF  ___, $F, $6                             ; 651E row 13  speed 6
    RIF C_3, 6, 0, $F, $A                       ; 6520 row 14  Inst05  speed 10
    RF  ___, $F, $6                             ; 6523 row 15  speed 6
Track068:
    RI  C_3, 2, 0                               ; 6525 row 00  Inst01
    R   ___                                     ; 6527 row 01
    R   ___                                     ; 6528 row 02
    R   ___                                     ; 6529 row 03
    R   ___                                     ; 652A row 04
    R   ___                                     ; 652B row 05
    R   ___                                     ; 652C row 06
    R   ___                                     ; 652D row 07
    R   ___                                     ; 652E row 08
    R   ___                                     ; 652F row 09
    R   ___                                     ; 6530 row 10
    R   ___                                     ; 6531 row 11
    R   ___                                     ; 6532 row 12
    R   ___                                     ; 6533 row 13
    R   ___                                     ; 6534 row 14
    R   ___                                     ; 6535 row 15
Track069:
    RIF C_3, 4, 0, $F, $A                       ; 6536 row 00  Inst03  speed 10
    RIF C_3, 6, 0, $F, $6                       ; 6539 row 01  Inst05  speed 6
    RIF A_3, 6, 0, $F, $A                       ; 653C row 02  Inst05  speed 10
    RIF C_3, 4, 0, $F, $6                       ; 653F row 03  Inst03  speed 6
    RIF C_3, 3, 0, $F, $A                       ; 6542 row 04  Inst02  speed 10
    RF  ___, $F, $6                             ; 6545 row 05  speed 6
    RIF C_3, 6, 0, $F, $A                       ; 6547 row 06  Inst05  speed 10
    RIF C_3, 4, 0, $F, $6                       ; 654A row 07  Inst03  speed 6
    RIF C_3, 6, 0, $F, $A                       ; 654D row 08  Inst05  speed 10
    RIF C_3, 4, 0, $F, $6                       ; 6550 row 09  Inst03  speed 6
    RIF C_3, 6, 0, $F, $A                       ; 6553 row 10  Inst05  speed 10
    RIF C_3, 4, 0, $F, $6                       ; 6556 row 11  Inst03  speed 6
    RIF C_3, 3, 0, $F, $A                       ; 6559 row 12  Inst02  speed 10
    RF  ___, $F, $6                             ; 655C row 13  speed 6
    RIF C_3, 6, 0, $F, $A                       ; 655E row 14  Inst05  speed 10
    RIF C_3, 4, 0, $F, $6                       ; 6561 row 15  Inst03  speed 6
Track070:
    RI  C_2, 1, 0                               ; 6564 row 00  Inst00
    R   ___                                     ; 6566 row 01
    RI  G_3, 10, 0                              ; 6567 row 02  Inst09
    RI  G_2, 1, 0                               ; 6569 row 03  Inst00
    RI  As2, 1, 0                               ; 656B row 04  Inst00
    RI  C_3, 1, 0                               ; 656D row 05  Inst00
    RI  G_3, 10, 0                              ; 656F row 06  Inst09
    RI  C_2, 1, 0                               ; 6571 row 07  Inst00
    R   ___                                     ; 6573 row 08
    RI  C_2, 1, 0                               ; 6574 row 09  Inst00
    RI  G_3, 10, 0                              ; 6576 row 10  Inst09
    RI  G_2, 1, 0                               ; 6578 row 11  Inst00
    RI  As2, 1, 0                               ; 657A row 12  Inst00
    R   ___                                     ; 657C row 13
    RI  G_3, 10, 0                              ; 657D row 14  Inst09
    RI  C_3, 1, 0                               ; 657F row 15  Inst00
Track071:
    RI  As4, 2, 0                               ; 6581 row 00  Inst01
    R   ___                                     ; 6583 row 01
    RI  C_5, 2, 0                               ; 6584 row 02  Inst01
    RI  ___, 0, 3                               ; 6586 row 03
    RI  As4, 2, 0                               ; 6588 row 04  Inst01
    RI  G_4, 2, 0                               ; 658A row 05  Inst01
    RI  ___, 0, 3                               ; 658C row 06
    RI  C_5, 2, 0                               ; 658E row 07  Inst01
    RI  ___, 0, 3                               ; 6590 row 08
    RI  C_5, 2, 0                               ; 6592 row 09  Inst01
    RI  ___, 0, 3                               ; 6594 row 10
    RI  G_4, 2, 0                               ; 6596 row 11  Inst01
    RI  As4, 2, 0                               ; 6598 row 12  Inst01
    RI  ___, 0, 3                               ; 659A row 13
    RI  C_5, 2, 0                               ; 659C row 14  Inst01
    RI  ___, 0, 3                               ; 659E row 15
Track072:
    RI  As4, 2, 0                               ; 65A0 row 00  Inst01
    R   ___                                     ; 65A2 row 01
    RI  C_5, 2, 0                               ; 65A3 row 02  Inst01
    RI  ___, 0, 3                               ; 65A5 row 03
    RI  As4, 2, 0                               ; 65A7 row 04  Inst01
    RI  G_4, 2, 0                               ; 65A9 row 05  Inst01
    RI  ___, 0, 3                               ; 65AB row 06
    RI  Fs5, 2, 0                               ; 65AD row 07  Inst01
    RI  ___, 0, 3                               ; 65AF row 08
    RI  F_5, 2, 0                               ; 65B1 row 09  Inst01
    RI  ___, 0, 3                               ; 65B3 row 10
    RI  Ds5, 2, 0                               ; 65B5 row 11  Inst01
    RI  C_5, 2, 0                               ; 65B7 row 12  Inst01
    RI  ___, 0, 3                               ; 65B9 row 13
    RI  G_4, 2, 0                               ; 65BB row 14  Inst01
    RI  ___, 0, 3                               ; 65BD row 15
Track073:
    RI  C_3, 5, 0                               ; 65BF row 00  Inst04
    RI  F_3, 5, 0                               ; 65C1 row 01  Inst04
    RI  G_3, 5, 0                               ; 65C3 row 02  Inst04
    RI  C_4, 5, 0                               ; 65C5 row 03  Inst04
    RI  F_4, 5, 0                               ; 65C7 row 04  Inst04
    RI  G_4, 5, 0                               ; 65C9 row 05  Inst04
    RI  As4, 5, 0                               ; 65CB row 06  Inst04
    RI  G_4, 5, 0                               ; 65CD row 07  Inst04
    RI  C_3, 5, 0                               ; 65CF row 08  Inst04
    RI  F_3, 5, 0                               ; 65D1 row 09  Inst04
    RI  G_3, 5, 0                               ; 65D3 row 10  Inst04
    RI  C_4, 5, 0                               ; 65D5 row 11  Inst04
    RI  F_4, 5, 0                               ; 65D7 row 12  Inst04
    RI  G_4, 5, 0                               ; 65D9 row 13  Inst04
    RI  Ds4, 5, 0                               ; 65DB row 14  Inst04
    RI  F_4, 5, 0                               ; 65DD row 15  Inst04
Track074:
    RI  E_3, 1, 0                               ; 65DF row 00  Inst00
    R   ___                                     ; 65E1 row 01
    RI  G_3, 7, 0                               ; 65E2 row 02  Inst06
    RI  E_2, 1, 0                               ; 65E4 row 03  Inst00
    RI  B_2, 1, 0                               ; 65E6 row 04  Inst00
    R   ___                                     ; 65E8 row 05
    RI  G_3, 7, 0                               ; 65E9 row 06  Inst06
    RI  E_2, 1, 0                               ; 65EB row 07  Inst00
    RI  E_3, 1, 0                               ; 65ED row 08  Inst00
    R   ___                                     ; 65EF row 09
    RI  G_3, 7, 0                               ; 65F0 row 10  Inst06
    RI  E_2, 1, 0                               ; 65F2 row 11  Inst00
    RI  B_2, 1, 0                               ; 65F4 row 12  Inst00
    R   ___                                     ; 65F6 row 13
    RI  G_3, 7, 0                               ; 65F7 row 14  Inst06
    RI  E_2, 1, 0                               ; 65F9 row 15  Inst00
Track075:
    RIF C_3, 4, 0, $F, $B                       ; 65FB row 00  Inst03  speed 11
    RF  ___, $F, $6                             ; 65FE row 01  speed 6
    RIF C_3, 3, 0, $F, $B                       ; 6600 row 02  Inst02  speed 11
    RIF C_3, 6, 0, $F, $6                       ; 6603 row 03  Inst05  speed 6
    RIF C_3, 4, 0, $F, $B                       ; 6606 row 04  Inst03  speed 11
    RF  ___, $F, $6                             ; 6609 row 05  speed 6
    RIF C_3, 3, 0, $F, $B                       ; 660B row 06  Inst02  speed 11
    RF  ___, $F, $6                             ; 660E row 07  speed 6
    RIF C_3, 4, 0, $F, $B                       ; 6610 row 08  Inst03  speed 11
    RF  ___, $F, $6                             ; 6613 row 09  speed 6
    RIF C_3, 3, 0, $F, $B                       ; 6615 row 10  Inst02  speed 11
    RIF C_3, 6, 0, $F, $6                       ; 6618 row 11  Inst05  speed 6
    RIF C_3, 4, 0, $F, $B                       ; 661B row 12  Inst03  speed 11
    RF  ___, $F, $6                             ; 661E row 13  speed 6
    RIF C_3, 3, 0, $F, $B                       ; 6620 row 14  Inst02  speed 11
    RF  ___, $F, $6                             ; 6623 row 15  speed 6
Track076:
    RI  E_4, 15, 0                              ; 6625 row 00  Inst14
    RI  Cs4, 15, 0                              ; 6627 row 01  Inst14
    RI  B_3, 15, 0                              ; 6629 row 02  Inst14
    RI  E_4, 15, 0                              ; 662B row 03  Inst14
    RI  Cs4, 15, 0                              ; 662D row 04  Inst14
    RI  B_3, 15, 0                              ; 662F row 05  Inst14
    RI  E_4, 15, 0                              ; 6631 row 06  Inst14
    RI  Cs4, 15, 0                              ; 6633 row 07  Inst14
    RI  B_3, 15, 0                              ; 6635 row 08  Inst14
    RI  E_4, 15, 0                              ; 6637 row 09  Inst14
    RI  Cs4, 15, 0                              ; 6639 row 10  Inst14
    RI  B_3, 15, 0                              ; 663B row 11  Inst14
    RI  E_4, 15, 0                              ; 663D row 12  Inst14
    RI  Cs4, 15, 0                              ; 663F row 13  Inst14
    RI  B_3, 15, 0                              ; 6641 row 14  Inst14
    R   ___                                     ; 6643 row 15
Track077:
    RI  E_4, 15, 0                              ; 6644 row 00  Inst14
    RI  Cs4, 15, 0                              ; 6646 row 01  Inst14
    RI  B_3, 15, 0                              ; 6648 row 02  Inst14
    RI  E_4, 15, 0                              ; 664A row 03  Inst14
    RI  Cs4, 15, 0                              ; 664C row 04  Inst14
    RI  B_3, 15, 0                              ; 664E row 05  Inst14
    RI  Cs4, 15, 0                              ; 6650 row 06  Inst14
    RI  D_4, 15, 0                              ; 6652 row 07  Inst14
    RI  Ds4, 15, 0                              ; 6654 row 08  Inst14
    R   ___                                     ; 6656 row 09
    R   ___                                     ; 6657 row 10
    R   ___                                     ; 6658 row 11
    R   ___                                     ; 6659 row 12
    R   ___                                     ; 665A row 13
    R   ___                                     ; 665B row 14
    R   ___                                     ; 665C row 15
Track078:
    RI  E_3, 1, 0                               ; 665D row 00  Inst00
    R   ___                                     ; 665F row 01
    RI  G_3, 7, 0                               ; 6660 row 02  Inst06
    RI  E_2, 1, 0                               ; 6662 row 03  Inst00
    RI  B_2, 1, 0                               ; 6664 row 04  Inst00
    R   ___                                     ; 6666 row 05
    RI  Cs3, 1, 0                               ; 6667 row 06  Inst00
    R   ___                                     ; 6669 row 07
    RI  Ds3, 1, 0                               ; 666A row 08  Inst00
    R   ___                                     ; 666C row 09
    RI  G_3, 9, 0                               ; 666D row 10  Inst08
    RI  Ds2, 1, 0                               ; 666F row 11  Inst00
    RI  B_2, 1, 0                               ; 6671 row 12  Inst00
    R   ___                                     ; 6673 row 13
    RI  G_3, 9, 0                               ; 6674 row 14  Inst08
    RI  Ds2, 1, 0                               ; 6676 row 15  Inst00
Track079:
    RI  B_2, 1, 0                               ; 6678 row 00  Inst00
    R   ___                                     ; 667A row 01
    RI  D_3, 7, 0                               ; 667B row 02  Inst06
    RI  B_3, 1, 0                               ; 667D row 03  Inst00
    RI  Fs2, 1, 0                               ; 667F row 04  Inst00
    R   ___                                     ; 6681 row 05
    RI  D_3, 7, 0                               ; 6682 row 06  Inst06
    RI  B_3, 1, 0                               ; 6684 row 07  Inst00
    RI  B_2, 1, 0                               ; 6686 row 08  Inst00
    R   ___                                     ; 6688 row 09
    RI  D_3, 7, 0                               ; 6689 row 10  Inst06
    RI  B_3, 1, 0                               ; 668B row 11  Inst00
    RI  Fs2, 1, 0                               ; 668D row 12  Inst00
    R   ___                                     ; 668F row 13
    RI  D_3, 7, 0                               ; 6690 row 14  Inst06
    RI  B_2, 1, 0                               ; 6692 row 15  Inst00
Track080:
    RI  B_2, 1, 0                               ; 6694 row 00  Inst00
    R   ___                                     ; 6696 row 01
    RI  D_3, 7, 0                               ; 6697 row 02  Inst06
    R   ___                                     ; 6699 row 03
    RI  Ds2, 1, 0                               ; 669A row 04  Inst00
    R   ___                                     ; 669C row 05
    RI  D_3, 7, 0                               ; 669D row 06  Inst06
    R   ___                                     ; 669F row 07
    RI  E_2, 1, 0                               ; 66A0 row 08  Inst00
    R   ___                                     ; 66A2 row 09
    RI  G_3, 7, 0                               ; 66A3 row 10  Inst06
    R   ___                                     ; 66A5 row 11
    RI  G_3, 7, 0                               ; 66A6 row 12  Inst06
    R   ___                                     ; 66A8 row 13
    R   ___                                     ; 66A9 row 14
    R   ___                                     ; 66AA row 15
Track081:
    RI  E_4, 15, 0                              ; 66AB row 00  Inst14
    RI  Cs4, 15, 0                              ; 66AD row 01  Inst14
    RI  B_3, 15, 0                              ; 66AF row 02  Inst14
    RI  E_4, 15, 0                              ; 66B1 row 03  Inst14
    RI  Cs4, 15, 0                              ; 66B3 row 04  Inst14
    RI  B_3, 15, 0                              ; 66B5 row 05  Inst14
    RI  Gs4, 15, 0                              ; 66B7 row 06  Inst14
    RI  B_4, 15, 0                              ; 66B9 row 07  Inst14
    RI  A_4, 15, 0                              ; 66BB row 08  Inst14
    R   ___                                     ; 66BD row 09
    R   ___                                     ; 66BE row 10
    R   ___                                     ; 66BF row 11
    R   ___                                     ; 66C0 row 12
    R   ___                                     ; 66C1 row 13
    R   ___                                     ; 66C2 row 14
    R   ___                                     ; 66C3 row 15
Track082:
    RIF C_3, 4, 0, $F, $B                       ; 66C4 row 00  Inst03  speed 11
    RIF C_3, 6, 0, $F, $6                       ; 66C7 row 01  Inst05  speed 6
    RIF C_3, 3, 0, $F, $B                       ; 66CA row 02  Inst02  speed 11
    RIF C_3, 6, 0, $F, $6                       ; 66CD row 03  Inst05  speed 6
    RIF C_3, 4, 0, $F, $B                       ; 66D0 row 04  Inst03  speed 11
    RIF C_3, 6, 0, $F, $6                       ; 66D3 row 05  Inst05  speed 6
    RIF C_3, 3, 0, $F, $B                       ; 66D6 row 06  Inst02  speed 11
    RIF C_3, 6, 0, $F, $6                       ; 66D9 row 07  Inst05  speed 6
    RIF C_3, 4, 0, $F, $B                       ; 66DC row 08  Inst03  speed 11
    RIF C_3, 6, 0, $F, $6                       ; 66DF row 09  Inst05  speed 6
    RIF C_3, 3, 0, $F, $B                       ; 66E2 row 10  Inst02  speed 11
    RIF C_3, 6, 0, $F, $6                       ; 66E5 row 11  Inst05  speed 6
    RIF C_3, 4, 0, $F, $B                       ; 66E8 row 12  Inst03  speed 11
    RIF C_3, 6, 0, $F, $6                       ; 66EB row 13  Inst05  speed 6
    RIF C_3, 3, 0, $F, $B                       ; 66EE row 14  Inst02  speed 11
    RIF C_3, 6, 0, $F, $6                       ; 66F1 row 15  Inst05  speed 6
Track083:
    RIF G_2, 5, 0, $F, $B                       ; 66F4 row 00  Inst04  speed 11
    R   ___                                     ; 66F7 row 01
    RI  B_2, 5, 0                               ; 66F8 row 02  Inst04
    R   ___                                     ; 66FA row 03
    RI  C_3, 5, 0                               ; 66FB row 04  Inst04
    R   ___                                     ; 66FD row 05
    RI  Cs3, 5, 0                               ; 66FE row 06  Inst04
    R   ___                                     ; 6700 row 07
    RI  D_3, 5, 0                               ; 6701 row 08  Inst04
    R   ___                                     ; 6703 row 09
    RI  Cs3, 5, 0                               ; 6704 row 10  Inst04
    R   ___                                     ; 6706 row 11
    RI  C_3, 5, 0                               ; 6707 row 12  Inst04
    R   ___                                     ; 6709 row 13
    RI  B_2, 5, 0                               ; 670A row 14  Inst04
    R   ___                                     ; 670C row 15
Track084:
    R   ___                                     ; 670D row 00
    RI  B_2, 5, 1                               ; 670E row 01  Inst04
    R   ___                                     ; 6710 row 02
    RI  G_2, 5, 1                               ; 6711 row 03  Inst04
    R   ___                                     ; 6713 row 04
    RI  B_2, 5, 1                               ; 6714 row 05  Inst04
    R   ___                                     ; 6716 row 06
    RI  C_3, 5, 1                               ; 6717 row 07  Inst04
    R   ___                                     ; 6719 row 08
    RI  Cs3, 5, 1                               ; 671A row 09  Inst04
    R   ___                                     ; 671C row 10
    RI  D_3, 5, 1                               ; 671D row 11  Inst04
    R   ___                                     ; 671F row 12
    RI  Cs3, 5, 1                               ; 6720 row 13  Inst04
    R   ___                                     ; 6722 row 14
    RI  C_3, 5, 1                               ; 6723 row 15  Inst04
Track085:
    RI  G_2, 13, 0                              ; 6725 row 00  Inst12
    R   ___                                     ; 6727 row 01
    R   ___                                     ; 6728 row 02
    R   ___                                     ; 6729 row 03
    RI  G_2, 12, 0                              ; 672A row 04  Inst11
    RI  G_2, 13, 0                              ; 672C row 05  Inst12
    RI  G_2, 1, 0                               ; 672E row 06  Inst00
    RI  G_2, 8, 0                               ; 6730 row 07  Inst07
    RI  D_2, 13, 0                              ; 6732 row 08  Inst12
    R   ___                                     ; 6734 row 09
    R   ___                                     ; 6735 row 10
    RI  D_2, 13, 0                              ; 6736 row 11  Inst12
    RI  D_2, 8, 0                               ; 6738 row 12  Inst07
    RI  D_2, 1, 0                               ; 673A row 13  Inst00
    RI  D_2, 2, 0                               ; 673C row 14  Inst01
    RI  D_3, 2, 0                               ; 673E row 15  Inst01
Track086:
    RI  G_2, 5, 0                               ; 6740 row 00  Inst04
    RI  B_2, 5, 1                               ; 6742 row 01  Inst04
    RI  B_2, 5, 0                               ; 6744 row 02  Inst04
    RI  G_2, 5, 1                               ; 6746 row 03  Inst04
    RI  C_3, 5, 0                               ; 6748 row 04  Inst04
    RI  B_2, 5, 1                               ; 674A row 05  Inst04
    RI  Cs3, 5, 0                               ; 674C row 06  Inst04
    RI  C_3, 5, 1                               ; 674E row 07  Inst04
    RI  D_3, 5, 0                               ; 6750 row 08  Inst04
    RI  Cs3, 5, 1                               ; 6752 row 09  Inst04
    RI  Cs3, 5, 0                               ; 6754 row 10  Inst04
    RI  D_3, 5, 1                               ; 6756 row 11  Inst04
    RI  C_3, 5, 0                               ; 6758 row 12  Inst04
    RI  Cs3, 5, 1                               ; 675A row 13  Inst04
    RI  B_2, 5, 0                               ; 675C row 14  Inst04
    RI  C_3, 5, 1                               ; 675E row 15  Inst04
Track087:
    RI  C_2, 14, 0                              ; 6760 row 00  Inst13
    RI  Cs2, 14, 1                              ; 6762 row 01  Inst13
    RI  D_2, 14, 1                              ; 6764 row 02  Inst13
    RI  Ds2, 14, 0                              ; 6766 row 03  Inst13
    RI  E_2, 14, 1                              ; 6768 row 04  Inst13
    RI  F_2, 14, 1                              ; 676A row 05  Inst13
    RI  Fs2, 14, 0                              ; 676C row 06  Inst13
    RI  G_2, 14, 1                              ; 676E row 07  Inst13
    RI  Gs2, 14, 1                              ; 6770 row 08  Inst13
    RI  A_2, 14, 0                              ; 6772 row 09  Inst13
    RI  As2, 14, 1                              ; 6774 row 10  Inst13
    RI  B_2, 14, 1                              ; 6776 row 11  Inst13
    RI  C_3, 14, 0                              ; 6778 row 12  Inst13
    RI  Cs3, 14, 1                              ; 677A row 13  Inst13
    RI  D_3, 14, 1                              ; 677C row 14  Inst13
    RI  Ds3, 14, 0                              ; 677E row 15  Inst13
Track088:
    RI  Ds3, 14, 0                              ; 6780 row 00  Inst13
    RI  E_3, 14, 1                              ; 6782 row 01  Inst13
    RI  F_3, 14, 1                              ; 6784 row 02  Inst13
    RI  Fs3, 14, 0                              ; 6786 row 03  Inst13
    RI  G_3, 14, 1                              ; 6788 row 04  Inst13
    RI  Fs3, 14, 1                              ; 678A row 05  Inst13
    RI  F_3, 14, 0                              ; 678C row 06  Inst13
    RI  D_3, 14, 1                              ; 678E row 07  Inst13
    RI  Cs3, 14, 1                              ; 6790 row 08  Inst13
    RI  C_3, 14, 0                              ; 6792 row 09  Inst13
    RI  B_2, 14, 1                              ; 6794 row 10  Inst13
    RI  As2, 14, 1                              ; 6796 row 11  Inst13
    RI  G_2, 14, 0                              ; 6798 row 12  Inst13
    RI  E_2, 14, 1                              ; 679A row 13  Inst13
    RI  C_2, 14, 1                              ; 679C row 14  Inst13
    RI  Cs2, 14, 0                              ; 679E row 15  Inst13
Track089:
    RI  G_2, 1, 0                               ; 67A0 row 00  Inst00
    RI  ___, 0, 3                               ; 67A2 row 01
    RI  G_3, 1, 0                               ; 67A4 row 02  Inst00
    RI  G_3, 1, 0                               ; 67A6 row 03  Inst00
    RI  G_2, 1, 0                               ; 67A8 row 04  Inst00
    RI  ___, 0, 3                               ; 67AA row 05
    RI  G_3, 1, 0                               ; 67AC row 06  Inst00
    RI  G_3, 1, 0                               ; 67AE row 07  Inst00
    RI  G_2, 1, 0                               ; 67B0 row 08  Inst00
    RI  ___, 0, 3                               ; 67B2 row 09
    RI  G_3, 1, 0                               ; 67B4 row 10  Inst00
    RI  G_3, 1, 0                               ; 67B6 row 11  Inst00
    RI  G_2, 1, 0                               ; 67B8 row 12  Inst00
    RI  ___, 0, 3                               ; 67BA row 13
    RI  G_3, 1, 0                               ; 67BC row 14  Inst00
    RI  G_3, 1, 0                               ; 67BE row 15  Inst00
Track090:
    RI  D_2, 1, 0                               ; 67C0 row 00  Inst00
    RI  ___, 0, 3                               ; 67C2 row 01
    RI  D_3, 1, 0                               ; 67C4 row 02  Inst00
    RI  D_3, 1, 0                               ; 67C6 row 03  Inst00
    RI  D_2, 1, 0                               ; 67C8 row 04  Inst00
    RI  ___, 0, 3                               ; 67CA row 05
    RI  D_3, 1, 0                               ; 67CC row 06  Inst00
    RI  D_3, 1, 0                               ; 67CE row 07  Inst00
    RI  F_2, 1, 0                               ; 67D0 row 08  Inst00
    RI  ___, 0, 3                               ; 67D2 row 09
    RI  F_3, 1, 0                               ; 67D4 row 10  Inst00
    RI  F_3, 1, 0                               ; 67D6 row 11  Inst00
    RI  F_2, 1, 0                               ; 67D8 row 12  Inst00
    RI  ___, 0, 3                               ; 67DA row 13
    RI  F_3, 1, 0                               ; 67DC row 14  Inst00
    RI  F_3, 1, 0                               ; 67DE row 15  Inst00
Track091:
    RIF C_3, 4, 0, $F, $6                       ; 67E0 row 00  Inst03  speed 6
    RF  ___, $F, $6                             ; 67E3 row 01  speed 6
    RIF C_3, 6, 0, $F, $D                       ; 67E5 row 02  Inst05  speed 13
    RIF C_3, 6, 0, $F, $D                       ; 67E8 row 03  Inst05  speed 13
    RIF C_3, 3, 0, $F, $6                       ; 67EB row 04  Inst02  speed 6
    RF  ___, $F, $6                             ; 67EE row 05  speed 6
    RIF C_3, 6, 0, $F, $D                       ; 67F0 row 06  Inst05  speed 13
    RIF C_3, 6, 0, $F, $D                       ; 67F3 row 07  Inst05  speed 13
    RIF C_3, 4, 0, $F, $6                       ; 67F6 row 08  Inst03  speed 6
    RF  ___, $F, $6                             ; 67F9 row 09  speed 6
    RIF C_3, 6, 0, $F, $D                       ; 67FB row 10  Inst05  speed 13
    RIF C_3, 6, 0, $F, $D                       ; 67FE row 11  Inst05  speed 13
    RIF C_3, 3, 0, $F, $6                       ; 6801 row 12  Inst02  speed 6
    RF  ___, $F, $6                             ; 6804 row 13  speed 6
    RIF C_3, 6, 0, $F, $D                       ; 6806 row 14  Inst05  speed 13
    RIF C_3, 6, 0, $F, $D                       ; 6809 row 15  Inst05  speed 13
Track092:
    RI  As2, 7, 0                               ; 680C row 00  Inst06
    R   ___                                     ; 680E row 01
    RI  As3, 7, 0                               ; 680F row 02  Inst06
    RI  As3, 7, 0                               ; 6811 row 03  Inst06
    RI  As2, 7, 0                               ; 6813 row 04  Inst06
    R   ___                                     ; 6815 row 05
    RI  As3, 7, 0                               ; 6816 row 06  Inst06
    RI  As3, 7, 0                               ; 6818 row 07  Inst06
    RI  As2, 7, 0                               ; 681A row 08  Inst06
    R   ___                                     ; 681C row 09
    RI  As3, 7, 0                               ; 681D row 10  Inst06
    RI  As3, 7, 0                               ; 681F row 11  Inst06
    RI  As2, 7, 0                               ; 6821 row 12  Inst06
    R   ___                                     ; 6823 row 13
    RI  As3, 7, 0                               ; 6824 row 14  Inst06
    RI  As3, 7, 0                               ; 6826 row 15  Inst06
Track093:
    RI  F_2, 7, 0                               ; 6828 row 00  Inst06
    R   ___                                     ; 682A row 01
    RI  F_3, 7, 0                               ; 682B row 02  Inst06
    RI  F_3, 7, 0                               ; 682D row 03  Inst06
    RI  F_2, 7, 0                               ; 682F row 04  Inst06
    R   ___                                     ; 6831 row 05
    RI  F_3, 7, 0                               ; 6832 row 06  Inst06
    RI  F_3, 7, 0                               ; 6834 row 07  Inst06
    RI  Gs2, 7, 0                               ; 6836 row 08  Inst06
    R   ___                                     ; 6838 row 09
    RI  Gs3, 7, 0                               ; 6839 row 10  Inst06
    RI  Gs3, 7, 0                               ; 683B row 11  Inst06
    RI  Gs2, 7, 0                               ; 683D row 12  Inst06
    R   ___                                     ; 683F row 13
    RI  Gs3, 7, 0                               ; 6840 row 14  Inst06
    RI  Gs3, 7, 0                               ; 6842 row 15  Inst06
Track094:
    RI  G_3, 8, 0                               ; 6844 row 00  Inst07
    R   ___                                     ; 6846 row 01
    RI  E_3, 8, 0                               ; 6847 row 02  Inst07
    RI  D_3, 8, 0                               ; 6849 row 03  Inst07
    RI  G_3, 8, 0                               ; 684B row 04  Inst07
    R   ___                                     ; 684D row 05
    RI  E_3, 8, 0                               ; 684E row 06  Inst07
    RI  D_3, 8, 0                               ; 6850 row 07  Inst07
    RI  G_3, 8, 0                               ; 6852 row 08  Inst07
    RI  D_3, 8, 0                               ; 6854 row 09  Inst07
    R   ___                                     ; 6856 row 10
    RI  E_3, 8, 0                               ; 6857 row 11  Inst07
    RI  D_3, 8, 0                               ; 6859 row 12  Inst07
    R   ___                                     ; 685B row 13
    R   ___                                     ; 685C row 14
    R   ___                                     ; 685D row 15
Track095:
    RI  D_3, 8, 0                               ; 685E row 00  Inst07
    R   ___                                     ; 6860 row 01
    RI  A_2, 8, 0                               ; 6861 row 02  Inst07
    RI  B_2, 8, 0                               ; 6863 row 03  Inst07
    RI  D_3, 8, 0                               ; 6865 row 04  Inst07
    R   ___                                     ; 6867 row 05
    RI  A_2, 8, 0                               ; 6868 row 06  Inst07
    RI  B_2, 8, 0                               ; 686A row 07  Inst07
    RI  F_3, 8, 0                               ; 686C row 08  Inst07
    RI  C_3, 8, 0                               ; 686E row 09  Inst07
    R   ___                                     ; 6870 row 10
    RI  D_3, 8, 0                               ; 6871 row 11  Inst07
    RI  C_3, 8, 0                               ; 6873 row 12  Inst07
    R   ___                                     ; 6875 row 13
    R   ___                                     ; 6876 row 14
    R   ___                                     ; 6877 row 15
Track096:
    RI  C_4, 5, 0                               ; 6878 row 00  Inst04
    R   ___                                     ; 687A row 01
    R   ___                                     ; 687B row 02
    R   ___                                     ; 687C row 03
    RI  B_3, 5, 0                               ; 687D row 04  Inst04
    R   ___                                     ; 687F row 05
    R   ___                                     ; 6880 row 06
    R   ___                                     ; 6881 row 07
    RI  A_3, 5, 0                               ; 6882 row 08  Inst04
    R   ___                                     ; 6884 row 09
    RI  B_3, 5, 0                               ; 6885 row 10  Inst04
    RI  C_4, 5, 0                               ; 6887 row 11  Inst04
    RI  G_3, 5, 0                               ; 6889 row 12  Inst04
    R   ___                                     ; 688B row 13
    R   ___                                     ; 688C row 14
    R   ___                                     ; 688D row 15
Track097:
    RI  A_3, 5, 0                               ; 688E row 00  Inst04
    R   ___                                     ; 6890 row 01
    R   ___                                     ; 6891 row 02
    R   ___                                     ; 6892 row 03
    RI  G_3, 5, 0                               ; 6893 row 04  Inst04
    R   ___                                     ; 6895 row 05
    R   ___                                     ; 6896 row 06
    R   ___                                     ; 6897 row 07
    RI  F_4, 5, 0                               ; 6898 row 08  Inst04
    RI  C_4, 5, 0                               ; 689A row 09  Inst04
    R   ___                                     ; 689C row 10
    RI  D_4, 5, 0                               ; 689D row 11  Inst04
    RI  C_4, 5, 0                               ; 689F row 12  Inst04
    R   ___                                     ; 68A1 row 13
    R   ___                                     ; 68A2 row 14
    R   ___                                     ; 68A3 row 15
Track098:
    R   ___                                     ; 68A4 row 00
    RI  C_4, 5, 0                               ; 68A5 row 01  Inst04
    R   ___                                     ; 68A7 row 02
    R   ___                                     ; 68A8 row 03
    R   ___                                     ; 68A9 row 04
    RI  B_3, 5, 0                               ; 68AA row 05  Inst04
    R   ___                                     ; 68AC row 06
    R   ___                                     ; 68AD row 07
    R   ___                                     ; 68AE row 08
    RI  A_3, 5, 0                               ; 68AF row 09  Inst04
    R   ___                                     ; 68B1 row 10
    RI  B_3, 5, 0                               ; 68B2 row 11  Inst04
    RI  C_4, 5, 0                               ; 68B4 row 12  Inst04
    RI  G_3, 5, 0                               ; 68B6 row 13  Inst04
    R   ___                                     ; 68B8 row 14
    R   ___                                     ; 68B9 row 15
Track099:
    R   ___                                     ; 68BA row 00
    RI  A_3, 5, 0                               ; 68BB row 01  Inst04
    R   ___                                     ; 68BD row 02
    R   ___                                     ; 68BE row 03
    R   ___                                     ; 68BF row 04
    RI  G_3, 5, 0                               ; 68C0 row 05  Inst04
    R   ___                                     ; 68C2 row 06
    R   ___                                     ; 68C3 row 07
    R   ___                                     ; 68C4 row 08
    RI  F_4, 5, 0                               ; 68C5 row 09  Inst04
    RI  C_4, 5, 0                               ; 68C7 row 10  Inst04
    R   ___                                     ; 68C9 row 11
    RI  D_4, 5, 0                               ; 68CA row 12  Inst04
    RI  C_4, 5, 0                               ; 68CC row 13  Inst04
    R   ___                                     ; 68CE row 14
    R   ___                                     ; 68CF row 15
Track100:
    RI  F_2, 1, 0                               ; 68D0 row 00  Inst00
    RI  ___, 0, 3                               ; 68D2 row 01
    RI  C_3, 1, 0                               ; 68D4 row 02  Inst00
    RI  ___, 0, 3                               ; 68D6 row 03
    RI  D_3, 1, 0                               ; 68D8 row 04  Inst00
    R   ___                                     ; 68DA row 05
    RI  C_3, 1, 0                               ; 68DB row 06  Inst00
    RI  ___, 0, 3                               ; 68DD row 07
    RI  F_2, 1, 0                               ; 68DF row 08  Inst00
    RI  ___, 0, 3                               ; 68E1 row 09
    RI  C_3, 1, 0                               ; 68E3 row 10  Inst00
    RI  ___, 0, 3                               ; 68E5 row 11
    RI  D_3, 1, 0                               ; 68E7 row 12  Inst00
    R   ___                                     ; 68E9 row 13
    RI  C_3, 1, 0                               ; 68EA row 14  Inst00
    RI  ___, 0, 3                               ; 68EC row 15
Track101:
    RIF C_3, 4, 0, $F, $A                       ; 68EE row 00  Inst03  speed 10
    R   ___                                     ; 68F1 row 01
    RIF C_3, 4, 0, $F, $6                       ; 68F2 row 02  Inst03  speed 6
    R   ___                                     ; 68F5 row 03
    RIF C_3, 6, 0, $F, $A                       ; 68F6 row 04  Inst05  speed 10
    R   ___                                     ; 68F9 row 05
    RIF C_3, 6, 0, $F, $6                       ; 68FA row 06  Inst05  speed 6
    R   ___                                     ; 68FD row 07
    RIF C_3, 4, 0, $F, $A                       ; 68FE row 08  Inst03  speed 10
    R   ___                                     ; 6901 row 09
    RIF C_3, 4, 0, $F, $6                       ; 6902 row 10  Inst03  speed 6
    R   ___                                     ; 6905 row 11
    RIF C_3, 6, 0, $F, $A                       ; 6906 row 12  Inst05  speed 10
    R   ___                                     ; 6909 row 13
    RIF C_3, 6, 0, $F, $6                       ; 690A row 14  Inst05  speed 6
    R   ___                                     ; 690D row 15
Track102:
    RI  F_2, 2, 0                               ; 690E row 00  Inst01
    RI  ___, 0, 3                               ; 6910 row 01
    RI  C_4, 2, 0                               ; 6912 row 02  Inst01
    RI  ___, 0, 3                               ; 6914 row 03
    RI  D_4, 2, 0                               ; 6916 row 04  Inst01
    RI  ___, 0, 3                               ; 6918 row 05
    RI  C_4, 2, 0                               ; 691A row 06  Inst01
    RI  ___, 0, 3                               ; 691C row 07
    RI  F_2, 2, 0                               ; 691E row 08  Inst01
    RI  ___, 0, 3                               ; 6920 row 09
    RI  C_4, 2, 0                               ; 6922 row 10  Inst01
    RI  ___, 0, 3                               ; 6924 row 11
    RI  D_4, 2, 0                               ; 6926 row 12  Inst01
    RI  ___, 0, 3                               ; 6928 row 13
    RI  C_4, 2, 0                               ; 692A row 14  Inst01
    RI  ___, 0, 3                               ; 692C row 15
Track103:
    RI  C_3, 5, 0                               ; 692E row 00  Inst04
    R   ___                                     ; 6930 row 01
    R   ___                                     ; 6931 row 02
    R   ___                                     ; 6932 row 03
    RI  D_3, 5, 0                               ; 6933 row 04  Inst04
    R   ___                                     ; 6935 row 05
    R   ___                                     ; 6936 row 06
    R   ___                                     ; 6937 row 07
    RI  F_3, 5, 0                               ; 6938 row 08  Inst04
    R   ___                                     ; 693A row 09
    R   ___                                     ; 693B row 10
    R   ___                                     ; 693C row 11
    RI  C_3, 5, 0                               ; 693D row 12  Inst04
    R   ___                                     ; 693F row 13
    RI  D_3, 5, 0                               ; 6940 row 14  Inst04
    R   ___                                     ; 6942 row 15
Track104:
    R   ___                                     ; 6943 row 00
    R   ___                                     ; 6944 row 01
    RI  F_3, 5, 0                               ; 6945 row 02  Inst04
    R   ___                                     ; 6947 row 03
    R   ___                                     ; 6948 row 04
    R   ___                                     ; 6949 row 05
    R   ___                                     ; 694A row 06
    R   ___                                     ; 694B row 07
    RI  C_3, 5, 0                               ; 694C row 08  Inst04
    R   ___                                     ; 694E row 09
    RI  D_3, 5, 0                               ; 694F row 10  Inst04
    R   ___                                     ; 6951 row 11
    RI  F_3, 5, 0                               ; 6952 row 12  Inst04
    R   ___                                     ; 6954 row 13
    R   ___                                     ; 6955 row 14
    R   ___                                     ; 6956 row 15
Track105:
    RI  G_3, 5, 0                               ; 6957 row 00  Inst04
    R   ___                                     ; 6959 row 01
    R   ___                                     ; 695A row 02
    R   ___                                     ; 695B row 03
    RI  G_3, 5, 0                               ; 695C row 04  Inst04
    R   ___                                     ; 695E row 05
    R   ___                                     ; 695F row 06
    R   ___                                     ; 6960 row 07
    RI  G_3, 5, 0                               ; 6961 row 08  Inst04
    R   ___                                     ; 6963 row 09
    R   ___                                     ; 6964 row 10
    R   ___                                     ; 6965 row 11
    RI  A_3, 5, 0                               ; 6966 row 12  Inst04
    R   ___                                     ; 6968 row 13
    RI  F_3, 5, 0                               ; 6969 row 14  Inst04
    R   ___                                     ; 696B row 15
Track106:
    R   ___                                     ; 696C row 00
    R   ___                                     ; 696D row 01
    R   ___                                     ; 696E row 02
    R   ___                                     ; 696F row 03
    R   ___                                     ; 6970 row 04
    R   ___                                     ; 6971 row 05
    R   ___                                     ; 6972 row 06
    R   ___                                     ; 6973 row 07
    R   ___                                     ; 6974 row 08
    R   ___                                     ; 6975 row 09
    RI  F_3, 5, 0                               ; 6976 row 10  Inst04
    R   ___                                     ; 6978 row 11
    RI  D_3, 5, 0                               ; 6979 row 12  Inst04
    R   ___                                     ; 697B row 13
    RI  C_3, 5, 0                               ; 697C row 14  Inst04
    R   ___                                     ; 697E row 15
Track107:
    RI  C_4, 5, 0                               ; 697F row 00  Inst04
    R   ___                                     ; 6981 row 01
    R   ___                                     ; 6982 row 02
    R   ___                                     ; 6983 row 03
    RI  C_4, 5, 0                               ; 6984 row 04  Inst04
    R   ___                                     ; 6986 row 05
    R   ___                                     ; 6987 row 06
    R   ___                                     ; 6988 row 07
    RI  C_4, 5, 0                               ; 6989 row 08  Inst04
    R   ___                                     ; 698B row 09
    R   ___                                     ; 698C row 10
    R   ___                                     ; 698D row 11
    RI  G_3, 5, 0                               ; 698E row 12  Inst04
    R   ___                                     ; 6990 row 13
    R   ___                                     ; 6991 row 14
    R   ___                                     ; 6992 row 15
Track108:
    RI  A_3, 5, 0                               ; 6993 row 00  Inst04
    R   ___                                     ; 6995 row 01
    R   ___                                     ; 6996 row 02
    R   ___                                     ; 6997 row 03
    RI  G_3, 5, 0                               ; 6998 row 04  Inst04
    R   ___                                     ; 699A row 05
    R   ___                                     ; 699B row 06
    R   ___                                     ; 699C row 07
    RI  F_3, 5, 0                               ; 699D row 08  Inst04
    R   ___                                     ; 699F row 09
    R   ___                                     ; 69A0 row 10
    R   ___                                     ; 69A1 row 11
    RI  G_3, 5, 0                               ; 69A2 row 12  Inst04
    R   ___                                     ; 69A4 row 13
    RI  F_3, 5, 0                               ; 69A5 row 14  Inst04
    R   ___                                     ; 69A7 row 15
Track109:
    RIF Fs2, 1, 0, $F, $7                       ; 69A8 row 00  Inst00  speed 7
    RI  ___, 0, 3                               ; 69AB row 01
    RI  Fs3, 1, 0                               ; 69AD row 02  Inst00
    RI  Fs3, 1, 0                               ; 69AF row 03  Inst00
    RI  As2, 1, 0                               ; 69B1 row 04  Inst00
    RI  ___, 0, 3                               ; 69B3 row 05
    RI  As3, 1, 0                               ; 69B5 row 06  Inst00
    RI  As3, 1, 0                               ; 69B7 row 07  Inst00
    RI  B_2, 1, 0                               ; 69B9 row 08  Inst00
    RI  ___, 0, 3                               ; 69BB row 09
    RI  B_3, 1, 0                               ; 69BD row 10  Inst00
    RI  B_3, 1, 0                               ; 69BF row 11  Inst00
    RI  Cs3, 1, 0                               ; 69C1 row 12  Inst00
    RI  ___, 0, 3                               ; 69C3 row 13
    RI  Cs4, 1, 0                               ; 69C5 row 14  Inst00
    RI  Cs4, 1, 0                               ; 69C7 row 15  Inst00
Track110:
    RI  C_3, 4, 0                               ; 69C9 row 00  Inst03
    R   ___                                     ; 69CB row 01
    RI  C_3, 6, 0                               ; 69CC row 02  Inst05
    RI  C_3, 6, 0                               ; 69CE row 03  Inst05
    RI  C_3, 3, 0                               ; 69D0 row 04  Inst02
    R   ___                                     ; 69D2 row 05
    RI  C_3, 6, 0                               ; 69D3 row 06  Inst05
    RI  C_3, 6, 0                               ; 69D5 row 07  Inst05
    RI  C_3, 4, 0                               ; 69D7 row 08  Inst03
    R   ___                                     ; 69D9 row 09
    RI  C_3, 6, 0                               ; 69DA row 10  Inst05
    RI  C_3, 6, 0                               ; 69DC row 11  Inst05
    RI  C_3, 3, 0                               ; 69DE row 12  Inst02
    R   ___                                     ; 69E0 row 13
    RI  C_3, 6, 0                               ; 69E1 row 14  Inst05
    RI  C_3, 4, 0                               ; 69E3 row 15  Inst03
Track111:
    RI  Fs2, 15, 0                              ; 69E5 row 00  Inst14
    RI  Fs3, 15, 0                              ; 69E7 row 01  Inst14
    RI  Cs4, 15, 0                              ; 69E9 row 02  Inst14
    RI  Fs2, 15, 0                              ; 69EB row 03  Inst14
    RI  Fs3, 15, 0                              ; 69ED row 04  Inst14
    RI  As3, 15, 0                              ; 69EF row 05  Inst14
    RI  Fs2, 15, 0                              ; 69F1 row 06  Inst14
    RI  Fs3, 15, 0                              ; 69F3 row 07  Inst14
    RI  B_3, 15, 0                              ; 69F5 row 08  Inst14
    RI  Fs2, 15, 0                              ; 69F7 row 09  Inst14
    RI  Fs3, 15, 0                              ; 69F9 row 10  Inst14
    RI  B_3, 15, 0                              ; 69FB row 11  Inst14
    RI  Fs2, 15, 0                              ; 69FD row 12  Inst14
    RI  Fs3, 15, 0                              ; 69FF row 13  Inst14
    RI  Cs3, 15, 0                              ; 6A01 row 14  Inst14
    RI  Cs4, 15, 0                              ; 6A03 row 15  Inst14
Track112:
    RI  Fs2, 1, 0                               ; 6A05 row 00  Inst00
    RI  Fs3, 15, 0                              ; 6A07 row 01  Inst14
    RI  Cs4, 15, 0                              ; 6A09 row 02  Inst14
    RI  Fs2, 15, 0                              ; 6A0B row 03  Inst14
    RI  As2, 1, 0                               ; 6A0D row 04  Inst00
    RI  As3, 15, 0                              ; 6A0F row 05  Inst14
    RI  Fs2, 15, 0                              ; 6A11 row 06  Inst14
    RI  Fs3, 15, 0                              ; 6A13 row 07  Inst14
    RI  B_2, 1, 0                               ; 6A15 row 08  Inst00
    RI  Fs2, 15, 0                              ; 6A17 row 09  Inst14
    RI  Fs3, 15, 0                              ; 6A19 row 10  Inst14
    RI  B_3, 15, 0                              ; 6A1B row 11  Inst14
    RI  Cs3, 1, 0                               ; 6A1D row 12  Inst00
    RI  Fs3, 15, 0                              ; 6A1F row 13  Inst14
    RI  Cs3, 15, 0                              ; 6A21 row 14  Inst14
    RI  Cs4, 15, 0                              ; 6A23 row 15  Inst14
Track113:
    RI  Fs3, 5, 0                               ; 6A25 row 00  Inst04
    R   ___                                     ; 6A27 row 01
    RI  Gs3, 5, 0                               ; 6A28 row 02  Inst04
    R   ___                                     ; 6A2A row 03
    RI  As3, 5, 0                               ; 6A2B row 04  Inst04
    R   ___                                     ; 6A2D row 05
    R   ___                                     ; 6A2E row 06
    R   ___                                     ; 6A2F row 07
    RI  Cs4, 5, 0                               ; 6A30 row 08  Inst04
    R   ___                                     ; 6A32 row 09
    R   ___                                     ; 6A33 row 10
    R   ___                                     ; 6A34 row 11
    RI  Fs3, 5, 0                               ; 6A35 row 12  Inst04
    R   ___                                     ; 6A37 row 13
    RI  As3, 5, 0                               ; 6A38 row 14  Inst04
    R   ___                                     ; 6A3A row 15
Track114:
    R   ___                                     ; 6A3B row 00
    R   ___                                     ; 6A3C row 01
    RI  Cs4, 5, 0                               ; 6A3D row 02  Inst04
    R   ___                                     ; 6A3F row 03
    R   ___                                     ; 6A40 row 04
    R   ___                                     ; 6A41 row 05
    RI  As3, 5, 0                               ; 6A42 row 06  Inst04
    R   ___                                     ; 6A44 row 07
    RI  Ds4, 5, 0                               ; 6A45 row 08  Inst04
    RI  ___, 0, 3                               ; 6A47 row 09
    RI  Ds4, 5, 0                               ; 6A49 row 10  Inst04
    RI  ___, 0, 3                               ; 6A4B row 11
    RI  Ds4, 5, 0                               ; 6A4D row 12  Inst04
    RI  Cs4, 5, 0                               ; 6A4F row 13  Inst04
    R   ___                                     ; 6A51 row 14
    R   ___                                     ; 6A52 row 15
Track115:
    R   ___                                     ; 6A53 row 00
    R   ___                                     ; 6A54 row 01
    RI  Cs4, 5, 0                               ; 6A55 row 02  Inst04
    R   ___                                     ; 6A57 row 03
    R   ___                                     ; 6A58 row 04
    R   ___                                     ; 6A59 row 05
    RI  As3, 5, 0                               ; 6A5A row 06  Inst04
    R   ___                                     ; 6A5C row 07
    RI  B_3, 5, 0                               ; 6A5D row 08  Inst04
    RI  ___, 0, 3                               ; 6A5F row 09
    RI  B_3, 5, 0                               ; 6A61 row 10  Inst04
    RI  ___, 0, 3                               ; 6A63 row 11
    RI  B_3, 5, 0                               ; 6A65 row 12  Inst04
    RI  F_3, 5, 0                               ; 6A67 row 13  Inst04
    R   ___                                     ; 6A69 row 14
    R   ___                                     ; 6A6A row 15
Track116:
    RI  Fs3, 2, 0                               ; 6A6B row 00  Inst01
    R   ___                                     ; 6A6D row 01
    RI  Gs3, 2, 0                               ; 6A6E row 02  Inst01
    R   ___                                     ; 6A70 row 03
    RI  As3, 2, 0                               ; 6A71 row 04  Inst01
    R   ___                                     ; 6A73 row 05
    R   ___                                     ; 6A74 row 06
    R   ___                                     ; 6A75 row 07
    RI  Cs4, 2, 0                               ; 6A76 row 08  Inst01
    R   ___                                     ; 6A78 row 09
    R   ___                                     ; 6A79 row 10
    R   ___                                     ; 6A7A row 11
    RI  Fs3, 2, 0                               ; 6A7B row 12  Inst01
    R   ___                                     ; 6A7D row 13
    RI  As3, 2, 0                               ; 6A7E row 14  Inst01
    R   ___                                     ; 6A80 row 15
Track117:
    R   ___                                     ; 6A81 row 00
    R   ___                                     ; 6A82 row 01
    RI  Cs4, 2, 0                               ; 6A83 row 02  Inst01
    R   ___                                     ; 6A85 row 03
    R   ___                                     ; 6A86 row 04
    R   ___                                     ; 6A87 row 05
    RI  As3, 2, 0                               ; 6A88 row 06  Inst01
    R   ___                                     ; 6A8A row 07
    RI  Ds4, 2, 0                               ; 6A8B row 08  Inst01
    RI  ___, 0, 3                               ; 6A8D row 09
    RI  Ds4, 2, 0                               ; 6A8F row 10  Inst01
    RI  ___, 0, 3                               ; 6A91 row 11
    RI  Ds4, 2, 0                               ; 6A93 row 12  Inst01
    RI  Cs4, 2, 0                               ; 6A95 row 13  Inst01
    R   ___                                     ; 6A97 row 14
    R   ___                                     ; 6A98 row 15
Track118:
    RI  Fs3, 2, 0                               ; 6A99 row 00  Inst01
    R   ___                                     ; 6A9B row 01
    RI  Gs3, 2, 0                               ; 6A9C row 02  Inst01
    R   ___                                     ; 6A9E row 03
    RI  As3, 2, 0                               ; 6A9F row 04  Inst01
    R   ___                                     ; 6AA1 row 05
    R   ___                                     ; 6AA2 row 06
    R   ___                                     ; 6AA3 row 07
    RI  Cs4, 2, 0                               ; 6AA4 row 08  Inst01
    R   ___                                     ; 6AA6 row 09
    R   ___                                     ; 6AA7 row 10
    R   ___                                     ; 6AA8 row 11
    RI  Fs3, 2, 0                               ; 6AA9 row 12  Inst01
    R   ___                                     ; 6AAB row 13
    RI  As3, 2, 0                               ; 6AAC row 14  Inst01
    R   ___                                     ; 6AAE row 15
Track119:
    R   ___                                     ; 6AAF row 00
    R   ___                                     ; 6AB0 row 01
    RI  Cs4, 2, 0                               ; 6AB1 row 02  Inst01
    R   ___                                     ; 6AB3 row 03
    R   ___                                     ; 6AB4 row 04
    R   ___                                     ; 6AB5 row 05
    RI  As3, 2, 0                               ; 6AB6 row 06  Inst01
    R   ___                                     ; 6AB8 row 07
    RI  B_3, 2, 0                               ; 6AB9 row 08  Inst01
    RI  ___, 0, 3                               ; 6ABB row 09
    RI  B_3, 2, 0                               ; 6ABD row 10  Inst01
    RI  ___, 0, 3                               ; 6ABF row 11
    RI  B_3, 2, 0                               ; 6AC1 row 12  Inst01
    RI  F_3, 2, 0                               ; 6AC3 row 13  Inst01
    R   ___                                     ; 6AC5 row 14
    R   ___                                     ; 6AC6 row 15
Track120:
    RI  Fs2, 1, 0                               ; 6AC7 row 00  Inst00
    R   ___                                     ; 6AC9 row 01
    RI  Fs2, 5, 0                               ; 6ACA row 02  Inst04
    R   ___                                     ; 6ACC row 03
    RI  As2, 1, 0                               ; 6ACD row 04  Inst00
    R   ___                                     ; 6ACF row 05
    RI  As2, 5, 0                               ; 6AD0 row 06  Inst04
    R   ___                                     ; 6AD2 row 07
    RI  B_2, 1, 0                               ; 6AD3 row 08  Inst00
    R   ___                                     ; 6AD5 row 09
    RI  B_2, 5, 0                               ; 6AD6 row 10  Inst04
    R   ___                                     ; 6AD8 row 11
    RI  Cs3, 1, 0                               ; 6AD9 row 12  Inst00
    R   ___                                     ; 6ADB row 13
    RI  Cs3, 5, 0                               ; 6ADC row 14  Inst04
    R   ___                                     ; 6ADE row 15
Track121:
    RI  Ds3, 17, 0                              ; 6ADF row 00  Inst16
    RI  Fs3, 7, 0                               ; 6AE1 row 01  Inst06
    RI  As2, 17, 0                              ; 6AE3 row 02  Inst16
    RI  Fs3, 7, 0                               ; 6AE5 row 03  Inst06
    RI  Ds3, 17, 0                              ; 6AE7 row 04  Inst16
    RI  Fs3, 7, 0                               ; 6AE9 row 05  Inst06
    RI  As2, 17, 0                              ; 6AEB row 06  Inst16
    RI  Fs3, 7, 0                               ; 6AED row 07  Inst06
    RI  Ds3, 17, 0                              ; 6AEF row 08  Inst16
    RI  Fs3, 7, 0                               ; 6AF1 row 09  Inst06
    RI  As2, 17, 0                              ; 6AF3 row 10  Inst16
    RI  Fs3, 7, 0                               ; 6AF5 row 11  Inst06
    RI  Ds3, 17, 0                              ; 6AF7 row 12  Inst16
    RI  Fs3, 7, 0                               ; 6AF9 row 13  Inst06
    RI  As2, 1, 0                               ; 6AFB row 14  Inst00
    RI  Fs3, 7, 0                               ; 6AFD row 15  Inst06
Track122:
    RI  C_3, 4, 0                               ; 6AFF row 00  Inst03
    R   ___                                     ; 6B01 row 01
    RI  C_3, 6, 0                               ; 6B02 row 02  Inst05
    RI  C_4, 6, 0                               ; 6B04 row 03  Inst05
    RI  C_3, 3, 0                               ; 6B06 row 04  Inst02
    R   ___                                     ; 6B08 row 05
    RI  C_3, 6, 0                               ; 6B09 row 06  Inst05
    RI  C_4, 6, 0                               ; 6B0B row 07  Inst05
    RI  C_3, 4, 0                               ; 6B0D row 08  Inst03
    R   ___                                     ; 6B0F row 09
    RI  C_3, 6, 0                               ; 6B10 row 10  Inst05
    RI  C_4, 6, 0                               ; 6B12 row 11  Inst05
    RI  C_3, 3, 0                               ; 6B14 row 12  Inst02
    R   ___                                     ; 6B16 row 13
    RI  C_3, 6, 0                               ; 6B17 row 14  Inst05
    RI  C_4, 6, 0                               ; 6B19 row 15  Inst05
Track123:
    RI  Ds3, 18, 0                              ; 6B1B row 00  Inst17
    R   ___                                     ; 6B1D row 01
    R   ___                                     ; 6B1E row 02
    RI  Ds3, 18, 0                              ; 6B1F row 03  Inst17
    RI  G_3, 18, 0                              ; 6B21 row 04  Inst17
    R   ___                                     ; 6B23 row 05
    RI  As3, 18, 0                              ; 6B24 row 06  Inst17
    R   ___                                     ; 6B26 row 07
    RI  C_4, 18, 0                              ; 6B27 row 08  Inst17
    RI  As3, 18, 0                              ; 6B29 row 09  Inst17
    R   ___                                     ; 6B2B row 10
    R   ___                                     ; 6B2C row 11
    R   ___                                     ; 6B2D row 12
    R   ___                                     ; 6B2E row 13
    R   ___                                     ; 6B2F row 14
    R   ___                                     ; 6B30 row 15
Track124:
    RI  F_4, 18, 0                              ; 6B31 row 00  Inst17
    R   ___                                     ; 6B33 row 01
    R   ___                                     ; 6B34 row 02
    RI  F_4, 18, 0                              ; 6B35 row 03  Inst17
    RI  A_4, 18, 0                              ; 6B37 row 04  Inst17
    RI  D_5, 18, 0                              ; 6B39 row 05  Inst17
    R   ___                                     ; 6B3B row 06
    RI  C_5, 18, 0                              ; 6B3C row 07  Inst17
    R   ___                                     ; 6B3E row 08
    R   ___                                     ; 6B3F row 09
    R   ___                                     ; 6B40 row 10
    R   ___                                     ; 6B41 row 11
    R   ___                                     ; 6B42 row 12
    R   ___                                     ; 6B43 row 13
    R   ___                                     ; 6B44 row 14
    R   ___                                     ; 6B45 row 15
Track125:
    RI  Ds5, 18, 0                              ; 6B46 row 00  Inst17
    R   ___                                     ; 6B48 row 01
    RI  Ds5, 18, 0                              ; 6B49 row 02  Inst17
    R   ___                                     ; 6B4B row 03
    RI  Ds5, 18, 0                              ; 6B4C row 04  Inst17
    R   ___                                     ; 6B4E row 05
    RI  C_5, 18, 0                              ; 6B4F row 06  Inst17
    R   ___                                     ; 6B51 row 07
    RI  D_5, 18, 0                              ; 6B52 row 08  Inst17
    RI  Cs5, 18, 0                              ; 6B54 row 09  Inst17
    RI  C_5, 18, 0                              ; 6B56 row 10  Inst17
    RI  As4, 18, 0                              ; 6B58 row 11  Inst17
    R   ___                                     ; 6B5A row 12
    R   ___                                     ; 6B5B row 13
    RI  F_4, 18, 0                              ; 6B5C row 14  Inst17
    RI  G_4, 18, 0                              ; 6B5E row 15  Inst17
Track126:
    RI  Gs2, 17, 0                              ; 6B60 row 00  Inst16
    RI  B_3, 7, 0                               ; 6B62 row 01  Inst06
    RI  Ds2, 17, 0                              ; 6B64 row 02  Inst16
    RI  B_3, 7, 0                               ; 6B66 row 03  Inst06
    RI  Gs2, 17, 0                              ; 6B68 row 04  Inst16
    RI  B_3, 7, 0                               ; 6B6A row 05  Inst06
    RI  Ds2, 17, 0                              ; 6B6C row 06  Inst16
    RI  B_3, 7, 0                               ; 6B6E row 07  Inst06
    RI  G_2, 17, 0                              ; 6B70 row 08  Inst16
    RI  Fs2, 17, 0                              ; 6B72 row 09  Inst16
    RI  F_2, 17, 0                              ; 6B74 row 10  Inst16
    RI  F_2, 17, 0                              ; 6B76 row 11  Inst16
    R   ___                                     ; 6B78 row 12
    R   ___                                     ; 6B79 row 13
    RI  F_2, 17, 0                              ; 6B7A row 14  Inst16
    RI  G_2, 17, 0                              ; 6B7C row 15  Inst16
Track127:
    RI  Gs2, 17, 0                              ; 6B7E row 00  Inst16
    RI  B_3, 7, 0                               ; 6B80 row 01  Inst06
    RI  Ds2, 17, 0                              ; 6B82 row 02  Inst16
    RI  B_3, 7, 0                               ; 6B84 row 03  Inst06
    RI  Gs2, 17, 0                              ; 6B86 row 04  Inst16
    RI  B_3, 7, 0                               ; 6B88 row 05  Inst06
    RI  Ds2, 17, 0                              ; 6B8A row 06  Inst16
    RI  B_3, 7, 0                               ; 6B8C row 07  Inst06
    RI  As2, 17, 0                              ; 6B8E row 08  Inst16
    RI  Cs4, 7, 0                               ; 6B90 row 09  Inst06
    RI  F_2, 17, 0                              ; 6B92 row 10  Inst16
    RI  Cs4, 7, 0                               ; 6B94 row 11  Inst06
    RI  As2, 17, 0                              ; 6B96 row 12  Inst16
    RI  Cs4, 7, 0                               ; 6B98 row 13  Inst06
    RI  F_2, 17, 0                              ; 6B9A row 14  Inst16
    RI  Cs4, 7, 0                               ; 6B9C row 15  Inst06
Track128:
    RI  Gs4, 18, 0                              ; 6B9E row 00  Inst17
    R   ___                                     ; 6BA0 row 01
    RI  Gs4, 18, 0                              ; 6BA1 row 02  Inst17
    R   ___                                     ; 6BA3 row 03
    RI  Gs4, 18, 0                              ; 6BA4 row 04  Inst17
    RI  A_4, 18, 0                              ; 6BA6 row 05  Inst17
    R   ___                                     ; 6BA8 row 06
    RI  As4, 18, 0                              ; 6BA9 row 07  Inst17
    R   ___                                     ; 6BAB row 08
    R   ___                                     ; 6BAC row 09
    R   ___                                     ; 6BAD row 10
    R   ___                                     ; 6BAE row 11
    R   ___                                     ; 6BAF row 12
    RI  As4, 18, 0                              ; 6BB0 row 13  Inst17
    RI  Gs4, 18, 0                              ; 6BB2 row 14  Inst17
    RI  F_4, 18, 0                              ; 6BB4 row 15  Inst17
Track129:
    RIF C_3, 4, 0, $F, $E                       ; 6BB6 row 00  Inst03  speed 14
    RIF C_3, 6, 0, $F, $7                       ; 6BB9 row 01  Inst05  speed 7
    RIF C_3, 3, 0, $F, $E                       ; 6BBC row 02  Inst02  speed 14
    RIF C_3, 6, 0, $F, $7                       ; 6BBF row 03  Inst05  speed 7
    RIF C_3, 4, 0, $F, $E                       ; 6BC2 row 04  Inst03  speed 14
    RIF C_3, 6, 0, $F, $7                       ; 6BC5 row 05  Inst05  speed 7
    RIF C_3, 3, 0, $F, $E                       ; 6BC8 row 06  Inst02  speed 14
    RIF C_3, 6, 0, $F, $7                       ; 6BCB row 07  Inst05  speed 7
    RIF C_4, 3, 0, $F, $E                       ; 6BCE row 08  Inst02  speed 14
    RIF C_4, 4, 0, $F, $7                       ; 6BD1 row 09  Inst03  speed 7
    RIF C_4, 3, 0, $F, $E                       ; 6BD4 row 10  Inst02  speed 14
    RIF C_4, 3, 0, $F, $7                       ; 6BD7 row 11  Inst02  speed 7
    RF  ___, $F, $E                             ; 6BDA row 12  speed 14
    RIF C_4, 6, 0, $F, $7                       ; 6BDC row 13  Inst05  speed 7
    RIF C_3, 3, 0, $F, $E                       ; 6BDF row 14  Inst02  speed 14
    RIF C_3, 6, 0, $F, $7                       ; 6BE2 row 15  Inst05  speed 7
Track130:
    RIF G_2, 17, 0, $F, $F                      ; 6BE5 row 00  Inst16  speed 15
    RI  As2, 17, 0                              ; 6BE8 row 01  Inst16
    RI  C_3, 17, 0                              ; 6BEA row 02  Inst16
    RI  Cs3, 17, 0                              ; 6BEC row 03  Inst16
    RI  C_3, 17, 0                              ; 6BEE row 04  Inst16
    RIF As2, 17, 0, $F, $8                      ; 6BF0 row 05  Inst16  speed 8
    RI  C_3, 17, 0                              ; 6BF3 row 06  Inst16
    RI  ___, 0, 3                               ; 6BF5 row 07
    RIF As2, 17, 0, $F, $4                      ; 6BF7 row 08  Inst16  speed 4
    R   ___                                     ; 6BFA row 09
    RI  Cs3, 17, 0                              ; 6BFB row 10  Inst16
    R   ___                                     ; 6BFD row 11
    RIF D_3, 17, 0, $F, $2                      ; 6BFE row 12  Inst16  speed 2
    R   ___                                     ; 6C01 row 13
    R   ___                                     ; 6C02 row 14
    RI  ___, 0, 3                               ; 6C03 row 15
Track131:
    RI  C_3, 4, 0                               ; 6C05 row 00  Inst03
    RI  C_3, 3, 0                               ; 6C07 row 01  Inst02
    RI  C_3, 4, 0                               ; 6C09 row 02  Inst03
    RI  C_3, 3, 0                               ; 6C0B row 03  Inst02
    RI  C_3, 4, 0                               ; 6C0D row 04  Inst03
    RI  C_3, 3, 0                               ; 6C0F row 05  Inst02
    R   ___                                     ; 6C11 row 06
    RI  C_3, 4, 0                               ; 6C12 row 07  Inst03
    R   ___                                     ; 6C14 row 08
    R   ___                                     ; 6C15 row 09
    RI  C_3, 3, 0                               ; 6C16 row 10  Inst02
    R   ___                                     ; 6C18 row 11
    R   ___                                     ; 6C19 row 12
    R   ___                                     ; 6C1A row 13
    R   ___                                     ; 6C1B row 14
    R   ___                                     ; 6C1C row 15
Track132:
    RI  G_4, 11, 0                              ; 6C1D row 00  Inst10
    RI  As4, 11, 0                              ; 6C1F row 01  Inst10
    RI  C_5, 11, 0                              ; 6C21 row 02  Inst10
    RI  Cs5, 11, 0                              ; 6C23 row 03  Inst10
    RI  C_5, 11, 0                              ; 6C25 row 04  Inst10
    RI  G_4, 11, 0                              ; 6C27 row 05  Inst10
    RI  As4, 11, 0                              ; 6C29 row 06  Inst10
    R   ___                                     ; 6C2B row 07
    RI  G_4, 11, 0                              ; 6C2C row 08  Inst10
    R   ___                                     ; 6C2E row 09
    RI  F_4, 11, 0                              ; 6C2F row 10  Inst10
    R   ___                                     ; 6C31 row 11
    RI  D_4, 11, 0                              ; 6C32 row 12  Inst10
    R   ___                                     ; 6C34 row 13
    R   ___                                     ; 6C35 row 14
    R   ___                                     ; 6C36 row 15
Track133:
    RIF G_2, 17, 0, $F, $F                      ; 6C37 row 00  Inst16  speed 15
    RI  D_2, 17, 0                              ; 6C3A row 01  Inst16
    RI  G_2, 17, 0                              ; 6C3C row 02  Inst16
    RI  D_2, 17, 0                              ; 6C3E row 03  Inst16
    RI  G_2, 17, 0                              ; 6C40 row 04  Inst16
    RIF D_2, 17, 0, $F, $8                      ; 6C42 row 05  Inst16  speed 8
    RI  G_2, 17, 0                              ; 6C45 row 06  Inst16
    RI  ___, 0, 3                               ; 6C47 row 07
    RIF D_2, 17, 0, $F, $4                      ; 6C49 row 08  Inst16  speed 4
    R   ___                                     ; 6C4C row 09
    RI  F_2, 17, 0                              ; 6C4D row 10  Inst16
    R   ___                                     ; 6C4F row 11
    RIF Fs2, 17, 0, $F, $2                      ; 6C50 row 12  Inst16  speed 2
    R   ___                                     ; 6C53 row 13
    R   ___                                     ; 6C54 row 14
    RI  ___, 0, 3                               ; 6C55 row 15
Track134:
    RI  G_4, 11, 0                              ; 6C57 row 00  Inst10
    RI  As4, 11, 0                              ; 6C59 row 01  Inst10
    RI  C_5, 11, 0                              ; 6C5B row 02  Inst10
    RI  Cs5, 11, 0                              ; 6C5D row 03  Inst10
    RI  C_5, 18, 0                              ; 6C5F row 04  Inst17
    R   ___                                     ; 6C61 row 05
    RI  D_5, 18, 0                              ; 6C62 row 06  Inst17
    R   ___                                     ; 6C64 row 07
    R   ___                                     ; 6C65 row 08
    R   ___                                     ; 6C66 row 09
    R   ___                                     ; 6C67 row 10
    R   ___                                     ; 6C68 row 11
    R   ___                                     ; 6C69 row 12
    R   ___                                     ; 6C6A row 13
    R   ___                                     ; 6C6B row 14
    R   ___                                     ; 6C6C row 15
Track135:
    RIF C_2, 19, 0, $F, $6                      ; 6C6D row 00  Inst18  speed 6
    R   ___                                     ; 6C70 row 01
    RI  C_3, 19, 1                              ; 6C71 row 02  Inst18
    RI  C_3, 19, 1                              ; 6C73 row 03  Inst18
    RI  C_2, 19, 0                              ; 6C75 row 04  Inst18
    R   ___                                     ; 6C77 row 05
    RI  C_3, 19, 1                              ; 6C78 row 06  Inst18
    RI  C_3, 19, 1                              ; 6C7A row 07  Inst18
    RI  C_2, 19, 0                              ; 6C7C row 08  Inst18
    R   ___                                     ; 6C7E row 09
    RI  C_3, 19, 1                              ; 6C7F row 10  Inst18
    RI  C_3, 19, 1                              ; 6C81 row 11  Inst18
    RI  C_3, 20, 0                              ; 6C83 row 12  Inst19
    RI  C_3, 19, 1                              ; 6C85 row 13  Inst18
    RI  C_3, 19, 1                              ; 6C87 row 14  Inst18
    RI  C_3, 19, 1                              ; 6C89 row 15  Inst18
Track136:
    RI  C_3, 6, 0                               ; 6C8B row 00  Inst05
    R   ___                                     ; 6C8D row 01
    RI  C_3, 6, 0                               ; 6C8E row 02  Inst05
    RI  C_3, 6, 0                               ; 6C90 row 03  Inst05
    RI  C_3, 6, 0                               ; 6C92 row 04  Inst05
    R   ___                                     ; 6C94 row 05
    RI  C_3, 6, 0                               ; 6C95 row 06  Inst05
    RI  C_3, 6, 0                               ; 6C97 row 07  Inst05
    RI  C_3, 6, 0                               ; 6C99 row 08  Inst05
    R   ___                                     ; 6C9B row 09
    RI  C_3, 6, 0                               ; 6C9C row 10  Inst05
    RI  C_3, 6, 0                               ; 6C9E row 11  Inst05
    RI  C_3, 3, 0                               ; 6CA0 row 12  Inst02
    R   ___                                     ; 6CA2 row 13
    RI  C_3, 6, 0                               ; 6CA3 row 14  Inst05
    RI  C_3, 6, 0                               ; 6CA5 row 15  Inst05
Track137:
    R   ___                                     ; 6CA7 row 00
    R   ___                                     ; 6CA8 row 01
    RI  G_2, 19, 0                              ; 6CA9 row 02  Inst18
    R   ___                                     ; 6CAB row 03
    RI  G_2, 19, 0                              ; 6CAC row 04  Inst18
    R   ___                                     ; 6CAE row 05
    R   ___                                     ; 6CAF row 06
    R   ___                                     ; 6CB0 row 07
    RI  G_2, 19, 0                              ; 6CB1 row 08  Inst18
    R   ___                                     ; 6CB3 row 09
    R   ___                                     ; 6CB4 row 10
    RI  G_2, 19, 0                              ; 6CB5 row 11  Inst18
    R   ___                                     ; 6CB7 row 12
    R   ___                                     ; 6CB8 row 13
    R   ___                                     ; 6CB9 row 14
    R   ___                                     ; 6CBA row 15
Track138:
    RI  G_2, 5, 0                               ; 6CBB row 00  Inst04
    RI  Gs2, 5, 0                               ; 6CBD row 01  Inst04
    RI  G_2, 19, 0                              ; 6CBF row 02  Inst18
    R   ___                                     ; 6CC1 row 03
    RI  G_2, 19, 0                              ; 6CC2 row 04  Inst18
    R   ___                                     ; 6CC4 row 05
    RI  Gs2, 5, 0                               ; 6CC5 row 06  Inst04
    RI  A_2, 5, 0                               ; 6CC7 row 07  Inst04
    RI  G_2, 19, 0                              ; 6CC9 row 08  Inst18
    R   ___                                     ; 6CCB row 09
    RI  Gs2, 5, 0                               ; 6CCC row 10  Inst04
    RI  G_2, 19, 0                              ; 6CCE row 11  Inst18
    RI  A_2, 5, 0                               ; 6CD0 row 12  Inst04
    RI  Gs2, 5, 0                               ; 6CD2 row 13  Inst04
    RI  G_2, 5, 0                               ; 6CD4 row 14  Inst04
    RI  ___, 0, 3                               ; 6CD6 row 15
Track139:
    RI  Gs2, 5, 0                               ; 6CD8 row 00  Inst04
    RI  G_2, 5, 0                               ; 6CDA row 01  Inst04
    RI  Fs2, 5, 0                               ; 6CDC row 02  Inst04
    RI  G_2, 5, 0                               ; 6CDE row 03  Inst04
    RI  Gs2, 5, 0                               ; 6CE0 row 04  Inst04
    RI  G_2, 5, 0                               ; 6CE2 row 05  Inst04
    RI  Fs2, 5, 0                               ; 6CE4 row 06  Inst04
    RI  Gs2, 5, 0                               ; 6CE6 row 07  Inst04
    RI  G_2, 8, 0                               ; 6CE8 row 08  Inst07
    RI  ___, 0, 3                               ; 6CEA row 09
    RI  G_2, 8, 0                               ; 6CEC row 10  Inst07
    RI  ___, 0, 3                               ; 6CEE row 11
    RI  G_2, 8, 0                               ; 6CF0 row 12  Inst07
    RI  ___, 0, 3                               ; 6CF2 row 13
    R   ___                                     ; 6CF4 row 14
    R   ___                                     ; 6CF5 row 15
Track140:
    R   ___                                     ; 6CF6 row 00
    R   ___                                     ; 6CF7 row 01
    RI  Gs2, 5, 1                               ; 6CF8 row 02  Inst04
    RI  G_2, 5, 1                               ; 6CFA row 03  Inst04
    RI  Fs2, 5, 1                               ; 6CFC row 04  Inst04
    RI  G_2, 5, 1                               ; 6CFE row 05  Inst04
    RI  Gs2, 5, 1                               ; 6D00 row 06  Inst04
    RI  G_2, 5, 1                               ; 6D02 row 07  Inst04
    RI  Fs2, 5, 1                               ; 6D04 row 08  Inst04
    RI  Gs2, 5, 1                               ; 6D06 row 09  Inst04
    RI  G_2, 8, 1                               ; 6D08 row 10  Inst07
    RI  ___, 0, 3                               ; 6D0A row 11
    RI  G_2, 8, 1                               ; 6D0C row 12  Inst07
    RI  ___, 0, 3                               ; 6D0E row 13
    RI  G_2, 8, 1                               ; 6D10 row 14  Inst07
    RI  ___, 0, 3                               ; 6D12 row 15
Track141:
    RIF Fs3, 5, 0, $F, $4                       ; 6D14 row 00  Inst04  speed 4
    R   ___                                     ; 6D17 row 01
    RI  G_3, 5, 0                               ; 6D18 row 02  Inst04
    R   ___                                     ; 6D1A row 03
    RI  Fs3, 5, 0                               ; 6D1B row 04  Inst04
    R   ___                                     ; 6D1D row 05
    RI  G_3, 5, 0                               ; 6D1E row 06  Inst04
    R   ___                                     ; 6D20 row 07
    RI  Fs3, 5, 0                               ; 6D21 row 08  Inst04
    R   ___                                     ; 6D23 row 09
    RI  G_3, 5, 0                               ; 6D24 row 10  Inst04
    R   ___                                     ; 6D26 row 11
    RI  As3, 5, 0                               ; 6D27 row 12  Inst04
    RF  ___, $F, $F                             ; 6D29 row 13  speed 15
    R   ___                                     ; 6D2B row 14
    R   ___                                     ; 6D2C row 15
Track142:
    R   ___                                     ; 6D2D row 00
    R   ___                                     ; 6D2E row 01
    R   ___                                     ; 6D2F row 02
    RI  Fs3, 5, 1                               ; 6D30 row 03  Inst04
    R   ___                                     ; 6D32 row 04
    RI  G_3, 5, 1                               ; 6D33 row 05  Inst04
    R   ___                                     ; 6D35 row 06
    RI  Fs3, 5, 1                               ; 6D36 row 07  Inst04
    R   ___                                     ; 6D38 row 08
    RI  G_3, 5, 1                               ; 6D39 row 09  Inst04
    R   ___                                     ; 6D3B row 10
    RI  Fs3, 5, 1                               ; 6D3C row 11  Inst04
    R   ___                                     ; 6D3E row 12
    RI  As3, 5, 1                               ; 6D3F row 13  Inst04
    R   ___                                     ; 6D41 row 14
    R   ___                                     ; 6D42 row 15
Track143:
    RIF C_3, 19, 0, $F, $6                      ; 6D43 row 00  Inst18  speed 6
    RI  C_3, 19, 1                              ; 6D46 row 01  Inst18
    RI  C_3, 19, 1                              ; 6D48 row 02  Inst18
    RI  C_3, 19, 1                              ; 6D4A row 03  Inst18
    RI  B_2, 19, 0                              ; 6D4C row 04  Inst18
    RI  B_2, 19, 1                              ; 6D4E row 05  Inst18
    RI  B_2, 19, 1                              ; 6D50 row 06  Inst18
    RI  B_2, 19, 1                              ; 6D52 row 07  Inst18
    RI  As2, 19, 0                              ; 6D54 row 08  Inst18
    RI  As2, 19, 1                              ; 6D56 row 09  Inst18
    RI  As2, 19, 1                              ; 6D58 row 10  Inst18
    RI  As2, 19, 1                              ; 6D5A row 11  Inst18
    RI  A_2, 19, 0                              ; 6D5C row 12  Inst18
    RI  A_2, 19, 1                              ; 6D5E row 13  Inst18
    RI  A_2, 19, 1                              ; 6D60 row 14  Inst18
    RI  A_2, 19, 1                              ; 6D62 row 15  Inst18
Track144:
    RI  C_3, 6, 0                               ; 6D64 row 00  Inst05
    RI  C_3, 6, 1                               ; 6D66 row 01  Inst05
    RI  C_3, 6, 1                               ; 6D68 row 02  Inst05
    RI  C_3, 6, 1                               ; 6D6A row 03  Inst05
    RI  C_3, 6, 0                               ; 6D6C row 04  Inst05
    RI  C_3, 6, 1                               ; 6D6E row 05  Inst05
    RI  C_3, 6, 1                               ; 6D70 row 06  Inst05
    RI  C_3, 6, 1                               ; 6D72 row 07  Inst05
    RI  C_3, 6, 0                               ; 6D74 row 08  Inst05
    RI  C_3, 6, 1                               ; 6D76 row 09  Inst05
    RI  C_3, 6, 1                               ; 6D78 row 10  Inst05
    RI  C_3, 6, 1                               ; 6D7A row 11  Inst05
    RI  C_3, 6, 0                               ; 6D7C row 12  Inst05
    RI  C_3, 6, 1                               ; 6D7E row 13  Inst05
    RI  C_3, 6, 1                               ; 6D80 row 14  Inst05
    RI  C_3, 6, 1                               ; 6D82 row 15  Inst05
Track145:
    RI  Fs2, 2, 0                               ; 6D84 row 00  Inst01
    R   ___                                     ; 6D86 row 01
    R   ___                                     ; 6D87 row 02
    R   ___                                     ; 6D88 row 03
    RI  G_2, 2, 0                               ; 6D89 row 04  Inst01
    R   ___                                     ; 6D8B row 05
    R   ___                                     ; 6D8C row 06
    R   ___                                     ; 6D8D row 07
    RI  Gs2, 2, 0                               ; 6D8E row 08  Inst01
    R   ___                                     ; 6D90 row 09
    R   ___                                     ; 6D91 row 10
    R   ___                                     ; 6D92 row 11
    RI  G_2, 2, 0                               ; 6D93 row 12  Inst01
    R   ___                                     ; 6D95 row 13
    R   ___                                     ; 6D96 row 14
    R   ___                                     ; 6D97 row 15
Track146:
    RI  C_2, 19, 0                              ; 6D98 row 00  Inst18
    RI  G_2, 5, 0                               ; 6D9A row 01  Inst04
    RI  As2, 5, 0                               ; 6D9C row 02  Inst04
    RI  C_2, 19, 0                              ; 6D9E row 03  Inst18
    RI  C_3, 19, 0                              ; 6DA0 row 04  Inst18
    RI  As2, 5, 0                               ; 6DA2 row 05  Inst04
    RI  C_2, 19, 0                              ; 6DA4 row 06  Inst18
    RI  F_2, 5, 0                               ; 6DA6 row 07  Inst04
    RI  C_2, 19, 0                              ; 6DA8 row 08  Inst18
    RI  C_3, 19, 0                              ; 6DAA row 09  Inst18
    RI  As2, 5, 0                               ; 6DAC row 10  Inst04
    RI  C_3, 19, 0                              ; 6DAE row 11  Inst18
    RI  C_2, 19, 0                              ; 6DB0 row 12  Inst18
    RI  Fs2, 5, 0                               ; 6DB2 row 13  Inst04
    RI  C_3, 20, 0                              ; 6DB4 row 14  Inst19
    RI  Fs2, 5, 0                               ; 6DB6 row 15  Inst04
Track147:
    RI  F_2, 5, 0                               ; 6DB8 row 00  Inst04
    RI  Fs2, 5, 0                               ; 6DBA row 01  Inst04
    RI  G_2, 5, 0                               ; 6DBC row 02  Inst04
    RI  As2, 5, 0                               ; 6DBE row 03  Inst04
    RI  G_2, 5, 0                               ; 6DC0 row 04  Inst04
    RI  Fs2, 5, 0                               ; 6DC2 row 05  Inst04
    RI  F_2, 5, 0                               ; 6DC4 row 06  Inst04
    RI  Fs2, 5, 0                               ; 6DC6 row 07  Inst04
    RI  G_2, 5, 0                               ; 6DC8 row 08  Inst04
    RI  As2, 5, 0                               ; 6DCA row 09  Inst04
    RI  G_2, 5, 0                               ; 6DCC row 10  Inst04
    RI  Fs2, 5, 0                               ; 6DCE row 11  Inst04
    RI  F_2, 5, 0                               ; 6DD0 row 12  Inst04
    RI  Fs2, 5, 0                               ; 6DD2 row 13  Inst04
    RI  G_2, 5, 0                               ; 6DD4 row 14  Inst04
    RI  As2, 5, 0                               ; 6DD6 row 15  Inst04
Track148:
    R   ___                                     ; 6DD8 row 00
    RI  ___, 0, 1                               ; 6DD9 row 01
    RI  F_2, 5, 1                               ; 6DDB row 02  Inst04
    RI  Fs2, 5, 1                               ; 6DDD row 03  Inst04
    RI  G_2, 5, 1                               ; 6DDF row 04  Inst04
    RI  As2, 5, 1                               ; 6DE1 row 05  Inst04
    RI  G_2, 5, 1                               ; 6DE3 row 06  Inst04
    RI  Fs2, 5, 1                               ; 6DE5 row 07  Inst04
    RI  F_2, 5, 1                               ; 6DE7 row 08  Inst04
    RI  Fs2, 5, 1                               ; 6DE9 row 09  Inst04
    RI  G_2, 5, 1                               ; 6DEB row 10  Inst04
    RI  As2, 5, 1                               ; 6DED row 11  Inst04
    RI  G_2, 5, 1                               ; 6DEF row 12  Inst04
    RI  Fs2, 5, 1                               ; 6DF1 row 13  Inst04
    RI  F_2, 5, 1                               ; 6DF3 row 14  Inst04
    RI  Fs2, 5, 1                               ; 6DF5 row 15  Inst04
Track149:
    RIF C_3, 4, 0, $F, $C                       ; 6DF7 row 00  Inst03  speed 12
    RF  ___, $F, $5                             ; 6DFA row 01  speed 5
    RIF C_3, 6, 0, $F, $C                       ; 6DFC row 02  Inst05  speed 12
    RF  ___, $F, $5                             ; 6DFF row 03  speed 5
    RIF C_3, 3, 0, $F, $C                       ; 6E01 row 04  Inst02  speed 12
    RF  ___, $F, $5                             ; 6E04 row 05  speed 5
    RIF C_3, 6, 0, $F, $C                       ; 6E06 row 06  Inst05  speed 12
    RF  ___, $F, $5                             ; 6E09 row 07  speed 5
    RIF C_3, 4, 0, $F, $C                       ; 6E0B row 08  Inst03  speed 12
    RF  ___, $F, $5                             ; 6E0E row 09  speed 5
    RIF C_3, 6, 0, $F, $C                       ; 6E10 row 10  Inst05  speed 12
    RF  ___, $F, $5                             ; 6E13 row 11  speed 5
    RIF C_3, 3, 0, $F, $C                       ; 6E15 row 12  Inst02  speed 12
    RF  ___, $F, $5                             ; 6E18 row 13  speed 5
    RIF C_3, 6, 0, $F, $C                       ; 6E1A row 14  Inst05  speed 12
    RF  ___, $F, $5                             ; 6E1D row 15  speed 5
Track150:
    RI  E_2, 11, 0                              ; 6E1F row 00  Inst10
    R   ___                                     ; 6E21 row 01
    RI  E_3, 11, 0                              ; 6E22 row 02  Inst10
    RI  E_3, 11, 0                              ; 6E24 row 03  Inst10
    RI  E_2, 11, 0                              ; 6E26 row 04  Inst10
    R   ___                                     ; 6E28 row 05
    RI  E_3, 11, 0                              ; 6E29 row 06  Inst10
    RI  E_3, 11, 0                              ; 6E2B row 07  Inst10
    RI  E_2, 11, 0                              ; 6E2D row 08  Inst10
    R   ___                                     ; 6E2F row 09
    RI  E_3, 11, 0                              ; 6E30 row 10  Inst10
    RI  E_3, 11, 0                              ; 6E32 row 11  Inst10
    RI  E_2, 11, 0                              ; 6E34 row 12  Inst10
    R   ___                                     ; 6E36 row 13
    RI  E_3, 11, 0                              ; 6E37 row 14  Inst10
    RI  E_3, 11, 0                              ; 6E39 row 15  Inst10
Track151:
    RI  E_2, 11, 0                              ; 6E3B row 00  Inst10
    R   ___                                     ; 6E3D row 01
    RI  E_3, 11, 0                              ; 6E3E row 02  Inst10
    RI  E_3, 11, 0                              ; 6E40 row 03  Inst10
    RI  E_2, 11, 0                              ; 6E42 row 04  Inst10
    R   ___                                     ; 6E44 row 05
    RI  E_3, 11, 0                              ; 6E45 row 06  Inst10
    RI  E_3, 11, 0                              ; 6E47 row 07  Inst10
    RI  B_2, 11, 0                              ; 6E49 row 08  Inst10
    R   ___                                     ; 6E4B row 09
    RI  B_2, 11, 0                              ; 6E4C row 10  Inst10
    RI  B_2, 11, 0                              ; 6E4E row 11  Inst10
    RI  B_2, 11, 0                              ; 6E50 row 12  Inst10
    R   ___                                     ; 6E52 row 13
    RI  B_2, 11, 0                              ; 6E53 row 14  Inst10
    RI  B_2, 11, 0                              ; 6E55 row 15  Inst10
Track152:
    RI  B_2, 11, 0                              ; 6E57 row 00  Inst10
    R   ___                                     ; 6E59 row 01
    RI  B_3, 11, 0                              ; 6E5A row 02  Inst10
    RI  B_3, 11, 0                              ; 6E5C row 03  Inst10
    RI  B_2, 11, 0                              ; 6E5E row 04  Inst10
    R   ___                                     ; 6E60 row 05
    RI  B_3, 11, 0                              ; 6E61 row 06  Inst10
    RI  B_3, 11, 0                              ; 6E63 row 07  Inst10
    RI  E_3, 11, 0                              ; 6E65 row 08  Inst10
    R   ___                                     ; 6E67 row 09
    RI  E_4, 11, 0                              ; 6E68 row 10  Inst10
    R   ___                                     ; 6E6A row 11
    RI  E_4, 11, 0                              ; 6E6B row 12  Inst10
    R   ___                                     ; 6E6D row 13
    R   ___                                     ; 6E6E row 14
    R   ___                                     ; 6E6F row 15
Track153:
    RIF C_3, 4, 0, $F, $E                       ; 6E70 row 00  Inst03  speed 14
    RIF C_3, 6, 0, $F, $7                       ; 6E73 row 01  Inst05  speed 7
    RIF C_3, 3, 0, $F, $E                       ; 6E76 row 02  Inst02  speed 14
    RIF C_3, 6, 0, $F, $7                       ; 6E79 row 03  Inst05  speed 7
    RIF C_3, 4, 0, $F, $E                       ; 6E7C row 04  Inst03  speed 14
    RIF C_3, 6, 0, $F, $7                       ; 6E7F row 05  Inst05  speed 7
    RIF C_3, 3, 0, $F, $E                       ; 6E82 row 06  Inst02  speed 14
    RIF C_3, 6, 0, $F, $7                       ; 6E85 row 07  Inst05  speed 7
    RIF C_3, 4, 0, $F, $E                       ; 6E88 row 08  Inst03  speed 14
    RIF C_3, 6, 0, $F, $7                       ; 6E8B row 09  Inst05  speed 7
    RIF C_3, 3, 0, $F, $E                       ; 6E8E row 10  Inst02  speed 14
    RIF C_3, 6, 0, $F, $7                       ; 6E91 row 11  Inst05  speed 7
    RIF C_3, 4, 0, $F, $E                       ; 6E94 row 12  Inst03  speed 14
    RIF C_3, 6, 0, $F, $7                       ; 6E97 row 13  Inst05  speed 7
    RIF C_3, 3, 0, $F, $E                       ; 6E9A row 14  Inst02  speed 14
    RIF C_3, 6, 0, $F, $7                       ; 6E9D row 15  Inst05  speed 7
Track154:
    RI  G_4, 11, 0                              ; 6EA0 row 00  Inst10
    R   ___                                     ; 6EA2 row 01
    RI  D_4, 11, 0                              ; 6EA3 row 02  Inst10
    R   ___                                     ; 6EA5 row 03
    RI  G_4, 11, 0                              ; 6EA6 row 04  Inst10
    R   ___                                     ; 6EA8 row 05
    RI  D_4, 11, 0                              ; 6EA9 row 06  Inst10
    R   ___                                     ; 6EAB row 07
    RI  G_4, 11, 0                              ; 6EAC row 08  Inst10
    R   ___                                     ; 6EAE row 09
    RI  D_4, 11, 0                              ; 6EAF row 10  Inst10
    R   ___                                     ; 6EB1 row 11
    RI  G_4, 11, 0                              ; 6EB2 row 12  Inst10
    R   ___                                     ; 6EB4 row 13
    RI  D_4, 11, 0                              ; 6EB5 row 14  Inst10
    RI  E_4, 11, 0                              ; 6EB7 row 15  Inst10
Track155:
    RI  G_4, 11, 0                              ; 6EB9 row 00  Inst10
    R   ___                                     ; 6EBB row 01
    RI  D_4, 11, 0                              ; 6EBC row 02  Inst10
    R   ___                                     ; 6EBE row 03
    RI  G_4, 11, 0                              ; 6EBF row 04  Inst10
    R   ___                                     ; 6EC1 row 05
    RI  D_4, 11, 0                              ; 6EC2 row 06  Inst10
    R   ___                                     ; 6EC4 row 07
    RI  A_4, 11, 0                              ; 6EC5 row 08  Inst10
    R   ___                                     ; 6EC7 row 09
    RI  E_4, 11, 0                              ; 6EC8 row 10  Inst10
    R   ___                                     ; 6ECA row 11
    RI  A_4, 11, 0                              ; 6ECB row 12  Inst10
    R   ___                                     ; 6ECD row 13
    RI  E_4, 11, 0                              ; 6ECE row 14  Inst10
    R   ___                                     ; 6ED0 row 15
Track156:
    RI  Ds3, 17, 0                              ; 6ED1 row 00  Inst16
    RI  Fs3, 7, 0                               ; 6ED3 row 01  Inst06
    RI  As2, 17, 0                              ; 6ED5 row 02  Inst16
    RI  Fs3, 7, 0                               ; 6ED7 row 03  Inst06
    RI  Ds3, 17, 0                              ; 6ED9 row 04  Inst16
    RI  Fs3, 7, 0                               ; 6EDB row 05  Inst06
    RI  As2, 17, 0                              ; 6EDD row 06  Inst16
    RI  Fs3, 7, 0                               ; 6EDF row 07  Inst06
    RI  F_3, 17, 0                              ; 6EE1 row 08  Inst16
    RI  Gs3, 7, 0                               ; 6EE3 row 09  Inst06
    RI  C_3, 17, 0                              ; 6EE5 row 10  Inst16
    RI  Gs3, 7, 0                               ; 6EE7 row 11  Inst06
    RI  F_3, 17, 0                              ; 6EE9 row 12  Inst16
    RI  Gs3, 7, 0                               ; 6EEB row 13  Inst06
    RI  C_3, 1, 0                               ; 6EED row 14  Inst00
    RI  Gs3, 7, 0                               ; 6EEF row 15  Inst06

;; Subsong names (text left in by the music converter; not used by the engine)
    db "SONG00: MAIN MENU......."                                ; 6EF1
    db "01: CUTSCENES......."                                    ; 6F09
    db "02: SUBSCREENS......"                                    ; 6F1D
    db "03: ACTION 1........"                                    ; 6F31
    db "04: CREEPY 1........"                                    ; 6F45
    db "05: SAFE 1.........."                                    ; 6F59
    db "06: SAFE 2.........."                                    ; 6F6D
    db "07: SAFE 3.........."                                    ; 6F81
    db "08: CREEPY 2........"                                    ; 6F95
    db "09: ACTION 2........"                                    ; 6FA9
    db "10: SAFE 4.........."                                    ; 6FBD
    db "11: ACTION 3........"                                    ; 6FD1
    db "12: ACTION 4........"                                    ; 6FE5
    db "13: ACTION 5........"                                    ; 6FF9
    db "14: BOSS 1.........."                                    ; 700D
    db "15: BOSS 2.........."                                    ; 7021
    db "16: EMPTY..............................."                ; 7035
SFXInstTable:
    dw SFXInst00                                 ; 705D  SFX instrument 1 (ch3)
    dw SFXInst01                                 ; 705F  SFX instrument 2 (ch3)
    dw SFXInst02                                 ; 7061  SFX instrument 3 (ch3)
    dw SFXInst03                                 ; 7063  SFX instrument 4 (ch1,ch2)
    dw SFXInst04                                 ; 7065  SFX instrument 5 (ch4)
    dw SFXInst05                                 ; 7067  SFX instrument 6 (ch3)
    dw SFXInst06                                 ; 7069  SFX instrument 7 (ch3)
    dw SFXInst07                                 ; 706B  SFX instrument 8 (ch3)
    dw SFXInst08                                 ; 706D  SFX instrument 9 (unused)
    dw SFXInst09                                 ; 706F  SFX instrument 10 (ch4)
    dw SFXInst10                                 ; 7071  SFX instrument 11 (ch3)
    dw SFXInst11                                 ; 7073  SFX instrument 12 (unused)
    dw SFXInst12                                 ; 7075  SFX instrument 13 (ch4)
    dw SFXInst13                                 ; 7077  SFX instrument 14 (ch4)
    dw SFXInst14                                 ; 7079  SFX instrument 15 (ch4)
    dw SFXInst15                                 ; 707B  SFX instrument 16 (ch3)
    dw SFXInst16                                 ; 707D  SFX instrument 17 (ch4)
    dw SFXInst17                                 ; 707F  SFX instrument 18 (ch4)
    dw SFXInst18                                 ; 7081  SFX instrument 19 (ch3)
    dw SFXInst19                                 ; 7083  SFX instrument 20 (ch3)
    dw SFXInst20                                 ; 7085  SFX instrument 21 (ch3)
    dw SFXInst21                                 ; 7087  SFX instrument 22 (ch4)
    dw SFXInst22                                 ; 7089  SFX instrument 23 (ch3)
    dw SFXInst23                                 ; 708B  SFX instrument 24 (ch3)
    dw SFXInst24                                 ; 708D  SFX instrument 25 (ch3)
    dw SFXInst25                                 ; 708F  SFX instrument 26 (ch3)
SFXInst00:
    db $0F                                       ; 7091 wave, 15 steps
    db $02                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0006, $0002, $001E                       ; position, lower bound, upper bound
    db $08                                       ; sweep speed
    db LOW(WaveData00), HIGH(WaveData00)         ; wave data base
    db $65, $43, $C0                             ; step 0: C-5  level 3, sweep on/off
    db $40, $42, $00                             ; step 1: -  level 2
    db $68, $43, $00                             ; step 2: D#5  level 3
    db $40, $42, $00                             ; step 3: -  level 2
    db $6A, $43, $00                             ; step 4: F-5  level 3
    db $40, $42, $00                             ; step 5: -  level 2
    db $6B, $43, $00                             ; step 6: F#5  level 3
    db $40, $42, $00                             ; step 7: -  level 2
    db $6C, $43, $00                             ; step 8: G-5  level 3
    db $40, $42, $00                             ; step 9: -  level 2
    db $6F, $43, $00                             ; step 10: A#5  level 3
    db $40, $42, $00                             ; step 11: -  level 2
    db $71, $43, $00                             ; step 12: C-6  level 3
    db $40, $42, $00                             ; step 13: -  level 2
    db $40, $40, $C0                             ; step 14: -  level 0, sweep on/off
SFXInst01:
    db $11                                       ; 70CC wave, 17 steps
    db $03                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0006, $0000, $001E                       ; position, lower bound, upper bound
    db $04                                       ; sweep speed
    db LOW(WaveData00), HIGH(WaveData00)         ; wave data base
    db $65, $43, $00                             ; step 0: C-5  level 3
    db $69, $00, $00                             ; step 1: E-5
    db $6C, $00, $00                             ; step 2: G-5
    db $70, $00, $00                             ; step 3: B-5
    db $67, $00, $00                             ; step 4: D-5
    db $6A, $00, $00                             ; step 5: F-5
    db $6E, $00, $00                             ; step 6: A-5
    db $71, $00, $00                             ; step 7: C-6
    db $69, $00, $00                             ; step 8: E-5
    db $6C, $00, $00                             ; step 9: G-5
    db $70, $00, $00                             ; step 10: B-5
    db $73, $00, $00                             ; step 11: D-6
    db $6A, $00, $00                             ; step 12: F-5
    db $6E, $00, $00                             ; step 13: A-5
    db $71, $00, $00                             ; step 14: C-6
    db $75, $00, $00                             ; step 15: E-6
    db $40, $00, $40                             ; step 16: -  level 0
SFXInst02:
    db $11                                       ; 710D wave, 17 steps
    db $03                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0006, $0000, $001E                       ; position, lower bound, upper bound
    db $08                                       ; sweep speed
    db LOW(WaveData00), HIGH(WaveData00)         ; wave data base
    db $59, $43, $C0                             ; step 0: C-4  level 3, sweep on/off
    db $65, $00, $00                             ; step 1: C-5
    db $5D, $00, $00                             ; step 2: E-4
    db $69, $00, $00                             ; step 3: E-5
    db $60, $00, $00                             ; step 4: G-4
    db $6C, $00, $00                             ; step 5: G-5
    db $64, $00, $00                             ; step 6: B-4
    db $70, $00, $00                             ; step 7: B-5
    db $67, $00, $00                             ; step 8: D-5
    db $73, $00, $00                             ; step 9: D-6
    db $5D, $00, $00                             ; step 10: E-4
    db $69, $00, $00                             ; step 11: E-5
    db $60, $00, $00                             ; step 12: G-4
    db $6C, $00, $00                             ; step 13: G-5
    db $65, $00, $00                             ; step 14: C-5
    db $71, $00, $00                             ; step 15: C-6
    db $40, $00, $40                             ; step 16: -  level 0
SFXInst03:
    db $07                                       ; 714E square, 7 steps
    db $81                                       ; playlist speed | $80 = vibrato
    db $F7                                       ; NRx2 envelope
    db $00, $3A                                  ; vibrato delay, depth<<4|speed
    db $65, $00, $C2                             ; step 0: C-5  duty 2
    db $68, $00, $00                             ; step 1: D#5
    db $6C, $00, $00                             ; step 2: G-5
    db $6F, $00, $00                             ; step 3: A#5
    db $71, $00, $00                             ; step 4: C-6
    db $65, $00, $85                             ; step 5: C-5  jump -5
    db $40, $00, $00                             ; step 6: -
SFXInst04:
    db $07                                       ; 7168 noise, 7 steps
    db $05                                       ; playlist speed
    db $F7                                       ; NR42 envelope
    db $59, $00, $C2                             ; step 0: C-4  (nop)
    db $5A, $00, $00                             ; step 1: C#4
    db $5B, $00, $00                             ; step 2: D-4
    db $5C, $00, $00                             ; step 3: D#4
    db $5D, $00, $00                             ; step 4: E-4
    db $5E, $00, $85                             ; step 5: F-4  jump -5
    db $40, $00, $00                             ; step 6: -
SFXInst05:
    db $15                                       ; 7180 wave, 21 steps
    db $02                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0006, $0002, $001E                       ; position, lower bound, upper bound
    db $04                                       ; sweep speed
    db LOW(WaveData00), HIGH(WaveData00)         ; wave data base
    db $70, $43, $C0                             ; step 0: B-5  level 3, sweep on/off
    db $6F, $42, $00                             ; step 1: A#5  level 2
    db $6E, $43, $00                             ; step 2: A-5  level 3
    db $6D, $42, $00                             ; step 3: G#5  level 2
    db $6C, $43, $00                             ; step 4: G-5  level 3
    db $6B, $42, $00                             ; step 5: F#5  level 2
    db $6A, $43, $00                             ; step 6: F-5  level 3
    db $68, $42, $00                             ; step 7: D#5  level 2
    db $69, $43, $00                             ; step 8: E-5  level 3
    db $68, $42, $00                             ; step 9: D#5  level 2
    db $67, $43, $00                             ; step 10: D-5  level 3
    db $65, $42, $00                             ; step 11: C-5  level 2
    db $64, $43, $00                             ; step 12: B-4  level 3
    db $65, $00, $00                             ; step 13: C-5
    db $64, $00, $00                             ; step 14: B-4
    db $65, $00, $00                             ; step 15: C-5
    db $64, $00, $00                             ; step 16: B-4
    db $65, $00, $C0                             ; step 17: C-5  sweep on/off
    db $40, $00, $40                             ; step 18: -  level 0
    db $40, $00, $00                             ; step 19: -
    db $40, $00, $00                             ; step 20: -
SFXInst06:
    db $0F                                       ; 71CD wave, 15 steps
    db $01                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0002, $001E                       ; position, lower bound, upper bound
    db $04                                       ; sweep speed
    db LOW(WaveData00), HIGH(WaveData00)         ; wave data base
    db $65, $43, $00                             ; step 0: C-5  level 3
    db $66, $00, $00                             ; step 1: C#5
    db $67, $00, $00                             ; step 2: D-5
    db $68, $00, $00                             ; step 3: D#5
    db $69, $00, $00                             ; step 4: E-5
    db $6A, $00, $00                             ; step 5: F-5
    db $6B, $00, $00                             ; step 6: F#5
    db $6C, $00, $00                             ; step 7: G-5
    db $40, $00, $40                             ; step 8: -  level 0
    db $40, $00, $00                             ; step 9: -
    db $40, $00, $00                             ; step 10: -
    db $40, $00, $00                             ; step 11: -
    db $40, $00, $00                             ; step 12: -
    db $40, $00, $00                             ; step 13: -
    db $40, $00, $00                             ; step 14: -
SFXInst07:
    db $0F                                       ; 7208 wave, 15 steps
    db $01                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0002, $001E                       ; position, lower bound, upper bound
    db $04                                       ; sweep speed
    db LOW(WaveData00), HIGH(WaveData00)         ; wave data base
    db $71, $43, $00                             ; step 0: C-6  level 3
    db $72, $00, $00                             ; step 1: C#6
    db $73, $00, $00                             ; step 2: D-6
    db $74, $00, $00                             ; step 3: D#6
    db $75, $42, $00                             ; step 4: E-6  level 2
    db $74, $00, $00                             ; step 5: D#6
    db $73, $00, $00                             ; step 6: D-6
    db $71, $00, $00                             ; step 7: C-6
    db $40, $00, $40                             ; step 8: -  level 0
    db $40, $00, $00                             ; step 9: -
    db $40, $00, $00                             ; step 10: -
    db $40, $00, $00                             ; step 11: -
    db $40, $00, $00                             ; step 12: -
    db $40, $00, $00                             ; step 13: -
    db $40, $00, $00                             ; step 14: -
SFXInst08:
    db $0F                                       ; 7243 wave, 15 steps
    db $01                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0002, $001E                       ; position, lower bound, upper bound
    db $04                                       ; sweep speed
    db LOW(WaveData00), HIGH(WaveData00)         ; wave data base
    db $65, $43, $00                             ; step 0: C-5  level 3
    db $66, $00, $00                             ; step 1: C#5
    db $67, $00, $00                             ; step 2: D-5
    db $68, $00, $00                             ; step 3: D#5
    db $69, $00, $00                             ; step 4: E-5
    db $6A, $00, $00                             ; step 5: F-5
    db $6B, $00, $00                             ; step 6: F#5
    db $6C, $00, $00                             ; step 7: G-5
    db $40, $00, $40                             ; step 8: -  level 0
    db $40, $00, $00                             ; step 9: -
    db $40, $00, $00                             ; step 10: -
    db $40, $00, $00                             ; step 11: -
    db $40, $00, $00                             ; step 12: -
    db $40, $00, $00                             ; step 13: -
    db $40, $00, $00                             ; step 14: -
SFXInst09:
    db $07                                       ; 727E noise, 7 steps
    db $05                                       ; playlist speed
    db $F2                                       ; NR42 envelope
    db $59, $00, $C2                             ; step 0: C-4  (nop)
    db $5A, $00, $00                             ; step 1: C#4
    db $5B, $00, $00                             ; step 2: D-4
    db $5C, $00, $00                             ; step 3: D#4
    db $5D, $00, $00                             ; step 4: E-4
    db $5E, $00, $85                             ; step 5: F-4  jump -5
    db $40, $00, $00                             ; step 6: -
SFXInst10:
    db $0F                                       ; 7296 wave, 15 steps
    db $01                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0002, $001E                       ; position, lower bound, upper bound
    db $04                                       ; sweep speed
    db LOW(WaveData00), HIGH(WaveData00)         ; wave data base
    db $6A, $43, $00                             ; step 0: F-5  level 3
    db $6B, $00, $00                             ; step 1: F#5
    db $6C, $00, $00                             ; step 2: G-5
    db $6D, $00, $00                             ; step 3: G#5
    db $6E, $42, $00                             ; step 4: A-5  level 2
    db $6F, $00, $00                             ; step 5: A#5
    db $70, $00, $00                             ; step 6: B-5
    db $71, $00, $00                             ; step 7: C-6
    db $40, $00, $40                             ; step 8: -  level 0
    db $40, $00, $00                             ; step 9: -
    db $40, $00, $00                             ; step 10: -
    db $40, $00, $00                             ; step 11: -
    db $40, $00, $00                             ; step 12: -
    db $40, $00, $00                             ; step 13: -
    db $40, $00, $00                             ; step 14: -
SFXInst11:
    db $11                                       ; 72D1 wave, 17 steps
    db $03                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0006, $0000, $001E                       ; position, lower bound, upper bound
    db $01                                       ; sweep speed
    db LOW(WaveData00), HIGH(WaveData00)         ; wave data base
    db $65, $43, $C0                             ; step 0: C-5  level 3, sweep on/off
    db $69, $00, $00                             ; step 1: E-5
    db $6C, $00, $00                             ; step 2: G-5
    db $70, $00, $00                             ; step 3: B-5
    db $67, $00, $00                             ; step 4: D-5
    db $6A, $00, $00                             ; step 5: F-5
    db $6E, $00, $00                             ; step 6: A-5
    db $71, $00, $00                             ; step 7: C-6
    db $69, $00, $00                             ; step 8: E-5
    db $6C, $00, $00                             ; step 9: G-5
    db $70, $00, $00                             ; step 10: B-5
    db $73, $00, $00                             ; step 11: D-6
    db $6A, $00, $00                             ; step 12: F-5
    db $6E, $00, $00                             ; step 13: A-5
    db $71, $00, $00                             ; step 14: C-6
    db $75, $00, $00                             ; step 15: E-6
    db $40, $00, $40                             ; step 16: -  level 0
SFXInst12:
    db $07                                       ; 7312 noise, 7 steps
    db $01                                       ; playlist speed
    db $F1                                       ; NR42 envelope
    db $70, $00, $C2                             ; step 0: B-5  (nop)
    db $6F, $00, $00                             ; step 1: A#5
    db $6E, $00, $00                             ; step 2: A-5
    db $6D, $00, $00                             ; step 3: G#5
    db $69, $00, $00                             ; step 4: E-5
    db $65, $00, $85                             ; step 5: C-5  jump -5
    db $40, $00, $00                             ; step 6: -
SFXInst13:
    db $07                                       ; 732A noise, 7 steps
    db $02                                       ; playlist speed
    db $F1                                       ; NR42 envelope
    db $65, $00, $C2                             ; step 0: C-5  (nop)
    db $59, $00, $00                             ; step 1: C-4
    db $5E, $00, $00                             ; step 2: F-4
    db $6E, $00, $00                             ; step 3: A-5
    db $5D, $00, $00                             ; step 4: E-4
    db $5B, $00, $85                             ; step 5: D-4  jump -5
    db $40, $00, $00                             ; step 6: -
SFXInst14:
    db $07                                       ; 7342 noise, 7 steps
    db $01                                       ; playlist speed
    db $F1                                       ; NR42 envelope
    db $59, $00, $C2                             ; step 0: C-4  (nop)
    db $64, $00, $00                             ; step 1: B-4
    db $69, $00, $00                             ; step 2: E-5
    db $70, $00, $00                             ; step 3: B-5
    db $5B, $00, $00                             ; step 4: D-4
    db $62, $00, $85                             ; step 5: A-4  jump -5
    db $40, $00, $00                             ; step 6: -
SFXInst15:
    db $0F                                       ; 735A wave, 15 steps
    db $01                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0002, $001E                       ; position, lower bound, upper bound
    db $04                                       ; sweep speed
    db LOW(WaveData00), HIGH(WaveData00)         ; wave data base
    db $70, $43, $00                             ; step 0: B-5  level 3
    db $6E, $00, $00                             ; step 1: A-5
    db $6C, $00, $00                             ; step 2: G-5
    db $6A, $00, $00                             ; step 3: F-5
    db $70, $42, $00                             ; step 4: B-5  level 2
    db $6E, $00, $00                             ; step 5: A-5
    db $6C, $00, $00                             ; step 6: G-5
    db $6A, $00, $00                             ; step 7: F-5
    db $40, $00, $40                             ; step 8: -  level 0
    db $40, $00, $00                             ; step 9: -
    db $40, $00, $00                             ; step 10: -
    db $40, $00, $00                             ; step 11: -
    db $40, $00, $00                             ; step 12: -
    db $40, $00, $00                             ; step 13: -
    db $40, $00, $00                             ; step 14: -
SFXInst16:
    db $07                                       ; 7395 noise, 7 steps
    db $01                                       ; playlist speed
    db $F1                                       ; NR42 envelope
    db $65, $00, $00                             ; step 0: C-5
    db $59, $00, $00                             ; step 1: C-4
    db $5D, $00, $00                             ; step 2: E-4
    db $78, $00, $00                             ; step 3: G-6
    db $5E, $00, $00                             ; step 4: F-4
    db $65, $00, $00                             ; step 5: C-5
    db $40, $00, $40                             ; step 6: -  vol 0
SFXInst17:
    db $0D                                       ; 73AD noise, 13 steps
    db $01                                       ; playlist speed
    db $80                                       ; NR42 envelope
    db $42, $00, $00                             ; step 0: C#2
    db $4E, $00, $00                             ; step 1: C#3
    db $42, $00, $00                             ; step 2: C#2
    db $4E, $00, $00                             ; step 3: C#3
    db $42, $00, $00                             ; step 4: C#2
    db $4E, $00, $00                             ; step 5: C#3
    db $42, $00, $00                             ; step 6: C#2
    db $4E, $00, $00                             ; step 7: C#3
    db $42, $00, $00                             ; step 8: C#2
    db $4E, $00, $00                             ; step 9: C#3
    db $42, $00, $00                             ; step 10: C#2
    db $4E, $00, $00                             ; step 11: C#3
    db $40, $00, $40                             ; step 12: -  vol 0
SFXInst18:
    db $12                                       ; 73D7 wave, 18 steps
    db $01                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0002, $001E                       ; position, lower bound, upper bound
    db $04                                       ; sweep speed
    db LOW(WaveData00), HIGH(WaveData00)         ; wave data base
    db $65, $43, $00                             ; step 0: C-5  level 3
    db $66, $00, $00                             ; step 1: C#5
    db $65, $00, $00                             ; step 2: C-5
    db $66, $00, $00                             ; step 3: C#5
    db $65, $42, $00                             ; step 4: C-5  level 2
    db $66, $00, $00                             ; step 5: C#5
    db $65, $00, $00                             ; step 6: C-5
    db $66, $00, $00                             ; step 7: C#5
    db $64, $00, $00                             ; step 8: B-4
    db $65, $00, $00                             ; step 9: C-5
    db $64, $00, $00                             ; step 10: B-4
    db $65, $00, $00                             ; step 11: C-5
    db $63, $00, $00                             ; step 12: A#4
    db $64, $00, $00                             ; step 13: B-4
    db $63, $00, $00                             ; step 14: A#4
    db $64, $00, $00                             ; step 15: B-4
    db $40, $00, $40                             ; step 16: -  level 0
    db $40, $00, $00                             ; step 17: -
SFXInst19:
    db $06                                       ; 741B wave, 6 steps
    db $03                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0000, $001E                       ; position, lower bound, upper bound
    db $01                                       ; sweep speed
    db LOW(WaveData00), HIGH(WaveData00)         ; wave data base
    db $59, $43, $00                             ; step 0: C-4  level 3
    db $65, $00, $00                             ; step 1: C-5
    db $71, $00, $00                             ; step 2: C-6
    db $65, $00, $00                             ; step 3: C-5
    db $40, $00, $40                             ; step 4: -  level 0
    db $40, $00, $00                             ; step 5: -
SFXInst20:
    db $0C                                       ; 743B wave, 12 steps
    db $02                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0000, $001E                       ; position, lower bound, upper bound
    db $01                                       ; sweep speed
    db LOW(WaveData00), HIGH(WaveData00)         ; wave data base
    db $65, $43, $00                             ; step 0: C-5  level 3
    db $66, $00, $00                             ; step 1: C#5
    db $67, $00, $00                             ; step 2: D-5
    db $68, $00, $00                             ; step 3: D#5
    db $6A, $00, $00                             ; step 4: F-5
    db $6D, $00, $00                             ; step 5: G#5
    db $65, $00, $41                             ; step 6: C-5  level 1
    db $67, $00, $00                             ; step 7: D-5
    db $69, $00, $00                             ; step 8: E-5
    db $6A, $00, $00                             ; step 9: F-5
    db $40, $00, $40                             ; step 10: -  level 0
    db $40, $00, $00                             ; step 11: -
SFXInst21:
    db $0D                                       ; 746D noise, 13 steps
    db $02                                       ; playlist speed
    db $F0                                       ; NR42 envelope
    db $4D, $00, $00                             ; step 0: C-3
    db $4F, $00, $00                             ; step 1: D-3
    db $51, $00, $00                             ; step 2: E-3
    db $52, $00, $00                             ; step 3: F-3
    db $54, $00, $00                             ; step 4: G-3
    db $56, $00, $00                             ; step 5: A-3
    db $58, $00, $00                             ; step 6: B-3
    db $59, $00, $00                             ; step 7: C-4
    db $40, $00, $40                             ; step 8: -  vol 0
    db $40, $00, $00                             ; step 9: -
    db $40, $00, $00                             ; step 10: -
    db $40, $00, $00                             ; step 11: -
    db $40, $00, $00                             ; step 12: -
SFXInst22:
    db $07                                       ; 7497 wave, 7 steps
    db $03                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0000, $001E                       ; position, lower bound, upper bound
    db $04                                       ; sweep speed
    db LOW(WaveData00), HIGH(WaveData00)         ; wave data base
    db $65, $43, $C0                             ; step 0: C-5  level 3, sweep on/off
    db $69, $00, $00                             ; step 1: E-5
    db $6C, $00, $00                             ; step 2: G-5
    db $65, $00, $00                             ; step 3: C-5
    db $69, $00, $00                             ; step 4: E-5
    db $6C, $00, $C0                             ; step 5: G-5  sweep on/off
    db $40, $00, $40                             ; step 6: -  level 0
SFXInst23:
    db $07                                       ; 74BA wave, 7 steps
    db $03                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0000, $001E                       ; position, lower bound, upper bound
    db $04                                       ; sweep speed
    db LOW(WaveData00), HIGH(WaveData00)         ; wave data base
    db $59, $43, $C0                             ; step 0: C-4  level 3, sweep on/off
    db $5A, $00, $00                             ; step 1: C#4
    db $59, $00, $00                             ; step 2: C-4
    db $5A, $00, $C0                             ; step 3: C#4  sweep on/off
    db $40, $00, $40                             ; step 4: -  level 0
    db $40, $00, $00                             ; step 5: -
    db $40, $00, $00                             ; step 6: -
SFXInst24:
    db $07                                       ; 74DD wave, 7 steps
    db $03                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0000, $001E                       ; position, lower bound, upper bound
    db $04                                       ; sweep speed
    db LOW(WaveData00), HIGH(WaveData00)         ; wave data base
    db $65, $43, $C0                             ; step 0: C-5  level 3, sweep on/off
    db $6C, $00, $00                             ; step 1: G-5
    db $71, $00, $00                             ; step 2: C-6
    db $78, $00, $00                             ; step 3: G-6
    db $65, $00, $00                             ; step 4: C-5
    db $6C, $00, $C0                             ; step 5: G-5  sweep on/off
    db $40, $00, $40                             ; step 6: -  level 0
SFXInst25:
    db $07                                       ; 7500 wave, 7 steps
    db $03                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0000, $001E                       ; position, lower bound, upper bound
    db $04                                       ; sweep speed
    db LOW(WaveData00), HIGH(WaveData00)         ; wave data base
    db $65, $43, $C0                             ; step 0: C-5  level 3, sweep on/off
    db $66, $00, $00                             ; step 1: C#5
    db $67, $00, $00                             ; step 2: D-5
    db $68, $00, $00                             ; step 3: D#5
    db $67, $00, $00                             ; step 4: D-5
    db $66, $00, $C0                             ; step 5: C#5  sweep on/off
    db $40, $00, $40                             ; step 6: -  level 0

;; Wave-RAM source data for SFXInst00, SFXInst01, SFXInst02, SFXInst05, SFXInst06, SFXInst07, SFXInst08, SFXInst10, SFXInst11, SFXInst15, SFXInst18, SFXInst19, SFXInst20, SFXInst22, SFXInst23, SFXInst24, SFXInst25. 16 bytes at base+position are copied
;; to $FF30-$FF3F (4-bit samples, high nibble first); positions used: $00-$1E. The window can reach 14 bytes past this block (into SFXTable).
WaveData00:
    db $88, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00; 7523 
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF; 7533 

;; Sound effects, 5 bytes: [ins ch1] [ins ch2] [ins ch3] [ins ch4] [mute time in ticks].
;; Instrument numbers are 1-based indices into SFXInstTable (0 = channel not used);
;; the music on the used channels is muted for "time" ticks ($FF on ch3 = until the next song).
SFXTable:
    db 0, 0, 1, 0, $01                           ; 7543 SFX 0
    db 0, 0, 2, 0, $01                           ; 7548 SFX 1
    db 0, 0, 3, 0, $01                           ; 754D SFX 2
    db 4, 4, 0, 5, $F0                           ; 7552 SFX 3
    db 0, 0, 6, 0, $01                           ; 7557 SFX 4
    db 0, 0, 7, 0, $01                           ; 755C SFX 5
    db 0, 0, 8, 0, $01                           ; 7561 SFX 6
    db 0, 0, 0, 10, $14                          ; 7566 SFX 7
    db 0, 0, 11, 0, $01                          ; 756B SFX 8
    db 0, 0, 3, 0, $34                           ; 7570 SFX 9
    db 0, 0, 0, 13, $10                          ; 7575 SFX 10
    db 0, 0, 0, 14, $01                          ; 757A SFX 11
    db 0, 0, 0, 15, $01                          ; 757F SFX 12
    db 0, 0, 16, 17, $01                         ; 7584 SFX 13
    db 0, 0, 19, 18, $10                         ; 7589 SFX 14
    db 0, 0, 20, 0, $01                          ; 758E SFX 15
    db 0, 0, 21, 0, $20                          ; 7593 SFX 16
    db 0, 0, 0, 22, $01                          ; 7598 SFX 17
    db 0, 0, 23, 0, $01                          ; 759D SFX 18
    db 0, 0, 24, 0, $01                          ; 75A2 SFX 19
    db 0, 0, 25, 0, $01                          ; 75A7 SFX 20
    db 0, 0, 26, 0, $01                          ; 75AC SFX 21
    db 0, 0, 0, 0, $01                           ; 75B1 SFX 22
    db 0, 0, 0, 0, $01                           ; 75B6 SFX 23
    ds 2629, $DA                ; 75BB  (fill)
