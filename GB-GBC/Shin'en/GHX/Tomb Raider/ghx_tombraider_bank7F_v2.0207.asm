; ============================================================================
; Tomb Raider (UE) (M5) [C][!].gbc  -  bank $7F (file offset $1FC000-$1FFFFF)
; "GHX Sound Engine    v2.0207     (c)2000 SHIN'EN  Code: M. Wodok Music: M.Linzner www.shinen.com"
; 
; Version string "v2.0207" = v2.0 of 7 Feb 2000; the older of the two Tomb Raider
; builds (bank $7E holds v00218 = 18 Feb 2000). Both are used by the game: every
; sound call in bank 0 ($061A-$0662 -> $066B) maps the bank kept in $C1E5 and
; calls the jump table. $C1E5 = $7F is set at boot ($0150) and by the title /
; menu code ($0EFD: subsong 0 = title music; $18FF), so this copy plays the
; front-end music. Subsongs 3-8 are jingles whose loop entry continues into
; the title positions. In-game ($05A0) the game switches to bank $7E.
; 
; Differences to the 1999 engine: channel blocks of $2C bytes, positions hold
; track POINTERS (11 bytes) instead of track numbers, playlist speed byte
; bit 7 = vibrato, playlist command $00-$3F = new speed, save/restore song,
; effect $8x, no PCM playback (ch3 instrument flag bits 6-7 only mute ch3).
;
; Complete disassembly of the bank: sound driver code plus all music and
; sound-effect data as labelled source. Assemble with RGBDS 0.9:
;   rgbasm -o x.o ghx_tombraider_bank7F_v2.0207.asm ; rgblink -o x.gb x.o
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

SECTION "GHX Sound Engine", ROMX[$4000], BANK[$7F]

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

;; Version / copyright string (never executed)
    db "     GHX Sound Engine    v2.0207     (c)2000 SHIN'EN  Code: "; 401B
    db "M. Wodok Music: M.Linzner www.shinen.com "               ; 4057
    db $20                                     ; 4080

;; GHX_SaveSong: remember the playing song (song, subsong, order state,
;; position, transpose + track pointer of each channel) in wSave_* so that
;; a jingle can be played and the music resumed later. Only one level.
SaveSong:
    ld a, [wSaved]              ; 4081
    or a                        ; 4084
    ret nz                      ; 4085
    cpl                         ; 4086
    ld [wSaved], a              ; 4087
    ld a, [wSong]               ; 408A
    ld [wSave_Song], a          ; 408D
    ld a, [wSubsong]            ; 4090
    ld [wSave_Subsong], a       ; 4093
    ld a, [wOrderSel]           ; 4096
    ld [wSave_OrderSel], a      ; 4099
    ld a, [wSpeed]              ; 409C
    ld [wSave_Speed], a         ; 409F
    ld a, [wRowsLeft]           ; 40A2
    ld [wSave_RowsLeft], a      ; 40A5
    ld a, [wPosLeft]            ; 40A8
    ld [wSave_PosLeft], a       ; 40AB
    ld a, [wPosPtrLo]           ; 40AE
    ld [wSave_PosPtrLo], a      ; 40B1
    ld a, [wPosPtrHi]           ; 40B4
    ld [wSave_PosPtrHi], a      ; 40B7
    ld a, [wCh1_Transpose]      ; 40BA
    ld [wSave_Channels], a      ; 40BD
    ld a, [wCh1_TrackPtrLo]     ; 40C0
    ld [wSave_Channels+1], a    ; 40C3
    ld a, [wCh1_TrackPtrHi]     ; 40C6
    ld [wSave_Channels+2], a    ; 40C9
    ld a, [wCh2_Transpose]      ; 40CC
    ld [wSave_Channels+3], a    ; 40CF
    ld a, [wCh2_TrackPtrLo]     ; 40D2
    ld [wSave_Channels+4], a    ; 40D5
    ld a, [wCh2_TrackPtrHi]     ; 40D8
    ld [wSave_Channels+5], a    ; 40DB
    ld a, [wCh3_Transpose]      ; 40DE
    ld [wSave_Channels+6], a    ; 40E1
    ld a, [wCh3_TrackPtrLo]     ; 40E4
    ld [wSave_Channels+7], a    ; 40E7
    ld a, [wCh3_TrackPtrHi]     ; 40EA
    ld [wSave_Channels+8], a    ; 40ED
    ld a, [wCh4_Transpose]      ; 40F0
    ld [wSave_Channels+9], a    ; 40F3
    ld a, [wCh4_TrackPtrLo]     ; 40F6
    ld [wSave_Channels+10], a   ; 40F9
    ld a, [wCh4_TrackPtrHi]     ; 40FC
    ld [wSave_Channels+11], a   ; 40FF
    ret                         ; 4102

;; GHX_Init: A = subsong, C = song (index into SongTable).
;; Copies the 12-byte song header to wHdr_*, clears the channel RAM and
;; switches the APU on.
InitSong:
    ld [wSubsong], a            ; 4103
    ld a, $06                   ; 4106
    ld [wSpeed], a              ; 4108
    xor a                       ; 410B
    ld [wTickCount], a          ; 410C
    ld [wReturnFlag], a         ; 410F
    ld [wRowsLeft], a           ; 4112
    ld [wPosLeft], a            ; 4115
    ld [wOrderSel], a           ; 4118
    ld b, $00                   ; 411B
    ld hl, SongTable            ; 411D
    add hl, bc                  ; 4120
    add hl, bc                  ; 4121
    ld a, c                     ; 4122
    ld [wSong], a               ; 4123
    ld a, [hl+]                 ; 4126
    ld c, a                     ; 4127
    ld a, [hl+]                 ; 4128
    ld h, a                     ; 4129
    ld l, c                     ; 412A
    ld de, wHdr_Magic           ; 412B
    ld c, $0C                   ; 412E
InitSong_CopyHeader:
    ld a, [hl+]                 ; 4130
    ld [de], a                  ; 4131
    inc de                      ; 4132
    dec c                       ; 4133
    jr nz, InitSong_CopyHeader  ; 4134
    ld hl, wCh1_Transpose       ; 4136
    ld c, $B0                   ; 4139
    xor a                       ; 413B
.L413C:
    ld [hl+], a                 ; 413C
    dec c                       ; 413D
    jr nz, .L413C               ; 413E

;; APU on: NR52 = $80, NR50 = $77, NR51 = $FF, envelopes off, player enabled.
InitAPU:
    ld a, $80                   ; 4140
    ldh [rNR52], a              ; 4142
    ld a, $77                   ; 4144
    ldh [rNR50], a              ; 4146
    ld a, $FF                   ; 4148
    ldh [rNR51], a              ; 414A
    xor a                       ; 414C
    ldh [rNR10], a              ; 414D
    ldh [rNR12], a              ; 414F
    ldh [rNR22], a              ; 4151
    ldh [rNR32], a              ; 4153
    ldh [rNR42], a              ; 4155
    ld a, $FF                   ; 4157
    ld [wEnabled], a            ; 4159
    ret                         ; 415C

;; GHX_RestoreSong: resume the song saved by GHX_SaveSong (at the start of
;; the row it was interrupted in).
RestoreSong:
    ld a, [wSaved]              ; 415D
    or a                        ; 4160
    ret z                       ; 4161
    xor a                       ; 4162
    ld [wSaved], a              ; 4163
    ld a, [wSave_Song]          ; 4166
    ld [wSong], a               ; 4169
    ld c, a                     ; 416C
    ld a, [wSave_Subsong]       ; 416D
    ld [wSubsong], a            ; 4170
    ld a, [wSave_Speed]         ; 4173
    ld [wSpeed], a              ; 4176
    xor a                       ; 4179
    ld [wTickCount], a          ; 417A
    ld [wReturnFlag], a         ; 417D
    ld a, [wSave_RowsLeft]      ; 4180
    ld [wRowsLeft], a           ; 4183
    ld a, [wSave_PosLeft]       ; 4186
    ld [wPosLeft], a            ; 4189
    ld a, [wSave_PosPtrLo]      ; 418C
    ld [wPosPtrLo], a           ; 418F
    ld a, [wSave_PosPtrHi]      ; 4192
    ld [wPosPtrHi], a           ; 4195
    ld a, [wSave_OrderSel]      ; 4198
    ld [wOrderSel], a           ; 419B
    ld b, $00                   ; 419E
    ld hl, SongTable            ; 41A0
    add hl, bc                  ; 41A3
    add hl, bc                  ; 41A4
    ld a, [hl+]                 ; 41A5
    ld c, a                     ; 41A6
    ld a, [hl+]                 ; 41A7
    ld h, a                     ; 41A8
    ld l, c                     ; 41A9
    ld de, wHdr_Magic           ; 41AA
    ld c, $0C                   ; 41AD
.L41AF:
    ld a, [hl+]                 ; 41AF
    ld [de], a                  ; 41B0
    inc de                      ; 41B1
    dec c                       ; 41B2
    jr nz, .L41AF               ; 41B3
    ld hl, wCh1_Transpose       ; 41B5
    ld de, wSave_Channels       ; 41B8
    ld b, $04                   ; 41BB
RestoreSong_Channels:
    ld a, [de]                  ; 41BD
    ld [hl+], a                 ; 41BE
    inc de                      ; 41BF
    ld a, [de]                  ; 41C0
    ld [hl+], a                 ; 41C1
    inc de                      ; 41C2
    ld a, [de]                  ; 41C3
    ld [hl+], a                 ; 41C4
    inc de                      ; 41C5
    ld c, $29                   ; 41C6
    xor a                       ; 41C8
.L41C9:
    ld [hl+], a                 ; 41C9
    dec c                       ; 41CA
    jr nz, .L41C9               ; 41CB
    dec b                       ; 41CD
    jr nz, RestoreSong_Channels ; 41CE
    jp InitAPU                  ; 41D0

;; GHX_SoundOn: re-enable the APU, keep the song position.
SoundOnImpl:
    ld a, $80                   ; 41D3
    ldh [rNR52], a              ; 41D5
    ld a, $77                   ; 41D7
    ldh [rNR50], a              ; 41D9
    ld a, $FF                   ; 41DB
    ldh [rNR51], a              ; 41DD
    xor a                       ; 41DF
    ldh [rNR10], a              ; 41E0
    ldh [rNR12], a              ; 41E2
    ldh [rNR22], a              ; 41E4
    ldh [rNR32], a              ; 41E6
    ldh [rNR42], a              ; 41E8
    ld a, $FF                   ; 41EA
    ld [wEnabled], a            ; 41EC
    ret                         ; 41EF

;; GHX_Stop: stop the player, NR52 = 0, forget the saved song and the speed adjust.
StopImpl:
    xor a                       ; 41F0
    ld [wEnabled], a            ; 41F1
    ldh [rNR52], a              ; 41F4
    ld [wSaved], a              ; 41F6
    ld [wSpeedAdjust], a        ; 41F9
    ret                         ; 41FC

;; GHX_Pause: stop the player and the APU (song state is kept).
PauseImpl:
    xor a                       ; 41FD
    ld [wEnabled], a            ; 41FE
    ldh [rNR52], a              ; 4201
    ret                         ; 4203

;; GHX_Play - call once per frame.
;; wTickCount counts the ticks of a row down; bit 7 set = paused.
;; On a new row: when the pattern is finished (wRowsLeft = 0) the next
;; position is read. When the current order entry has no positions left the
;; order entry 2*subsong+wOrderSel is (re)started; wOrderSel is 0 for the
;; first pass (intro) and 1 afterwards (loop).
PlayFrame:
    ld a, [wEnabled]            ; 4204
    or a                        ; 4207
    ret z                       ; 4208
    ld b, $00                   ; 4209
    ld a, [wTickCount]          ; 420B
    bit 7, a                    ; 420E
    jp nz, Tick                 ; 4210
    or a                        ; 4213
    jp nz, Tick_Count           ; 4214
    ld a, [wRowsLeft]           ; 4217
    or a                        ; 421A
    jp nz, Row_Ch1              ; 421B
    ld a, [wHdr_PatLen]         ; 421E
    ld [wRowsLeft], a           ; 4221
    ld a, [wPosLeft]            ; 4224
    or a                        ; 4227
    jp nz, NextPosition         ; 4228
    ld a, [wHdr_OrdersLo]       ; 422B
    ld l, a                     ; 422E
    ld a, [wHdr_OrdersHi]       ; 422F
    ld h, a                     ; 4232
    ld a, [wOrderSel]           ; 4233
    ld c, a                     ; 4236
    or $01                      ; 4237
    ld [wOrderSel], a           ; 4239
    ld a, [wSubsong]            ; 423C
    add a,a                     ; 423F
    add a,c                     ; 4240
    ld c, a                     ; 4241
    add hl, bc                  ; 4242
    add hl, bc                  ; 4243
    add hl, bc                  ; 4244
    ld a, [hl+]                 ; 4245
    ld [wPosLeft], a            ; 4246
    ld a, [hl+]                 ; 4249
    ld c, a                     ; 424A
    ld a, [hl+]                 ; 424B
    ld h, a                     ; 424C
    ld l, c                     ; 424D
    jr ReadPosition             ; 424E
NextPosition:
    ld a, [wPosPtrLo]           ; 4250
    ld l, a                     ; 4253
    ld a, [wPosPtrHi]           ; 4254
    ld h, a                     ; 4257
    ld a, [wPosLeft]            ; 4258
    dec a                       ; 425B
    ld [wPosLeft], a            ; 425C

;; Position = 11 bytes: for ch1..ch3 [dw track pointer] [transpose],
;; then [dw track pointer] for ch4 (no transpose).
ReadPosition:
    ld a, [hl+]                 ; 425F
    ld [wCh1_TrackPtrLo], a     ; 4260
    ld a, [hl+]                 ; 4263
    ld [wCh1_TrackPtrHi], a     ; 4264
    ld a, [hl+]                 ; 4267
    ld [wCh1_Transpose], a      ; 4268
    ld a, [hl+]                 ; 426B
    ld [wCh2_TrackPtrLo], a     ; 426C
    ld a, [hl+]                 ; 426F
    ld [wCh2_TrackPtrHi], a     ; 4270
    ld a, [hl+]                 ; 4273
    ld [wCh2_Transpose], a      ; 4274
    ld a, [hl+]                 ; 4277
    ld [wCh3_TrackPtrLo], a     ; 4278
    ld a, [hl+]                 ; 427B
    ld [wCh3_TrackPtrHi], a     ; 427C
    ld a, [hl+]                 ; 427F
    ld [wCh3_Transpose], a      ; 4280
    ld a, [hl+]                 ; 4283
    ld [wCh4_TrackPtrLo], a     ; 4284
    ld a, [hl+]                 ; 4287
    ld [wCh4_TrackPtrHi], a     ; 4288
    ld a, l                     ; 428B
    ld [wPosPtrLo], a           ; 428C
    ld a, h                     ; 428F
    ld [wPosPtrHi], a           ; 4290

;; New row on channel 1. Row = [note|$40: ins byte follows|$80: fx byte follows]
;; [ins] [fx]. The fx byte is decoded on all channels, even while an SFX owns
;; the channel: $8x sets wReturnFlag, $Fx sets the speed (ticks per row).
Row_Ch1:
    ld hl, wRowsLeft            ; 4293
    dec [hl]                    ; 4296
    ld a, [wCh1_TrackPtrLo]     ; 4297
    ld l, a                     ; 429A
    ld a, [wCh1_TrackPtrHi]     ; 429B
    ld h, a                     ; 429E
    ld a, [hl+]                 ; 429F
    ld [wCh1_RowNote], a        ; 42A0
    ld e, a                     ; 42A3
    bit 6, e                    ; 42A4
    jr z, .L42AC                ; 42A6
    ld a, [hl+]                 ; 42A8
    ld [wCh1_RowIns], a         ; 42A9
.L42AC:
    bit 7, e                    ; 42AC
    jr z, .L42B4                ; 42AE
    ld a, [hl+]                 ; 42B0
    ld [wCh1_RowFx], a          ; 42B1
.L42B4:
    ld a, l                     ; 42B4
    ld [wCh1_TrackPtrLo], a     ; 42B5
    ld a, h                     ; 42B8
    ld [wCh1_TrackPtrHi], a     ; 42B9
    bit 7, e                    ; 42BC
    jr z, Row_Ch1_Decode        ; 42BE
    ld a, [wCh1_RowFx]          ; 42C0
    ld c, a                     ; 42C3
    swap c                      ; 42C4
    and $0F                     ; 42C6
    sub $08                     ; 42C8
    jr nz, .L42D2               ; 42CA
    ld a, c                     ; 42CC
    and $0F                     ; 42CD
    ld [wReturnFlag], a         ; 42CF
.L42D2:
    sub $07                     ; 42D2
    jr nz, Row_Ch1_Decode       ; 42D4
    ld a, c                     ; 42D6
    and $0F                     ; 42D7
    ld [wSpeed], a              ; 42D9

;; The music is muted on a channel while its SFXTimer <> 0.
Row_Ch1_Decode:
    ld a, [wCh1_SFXTimer]       ; 42DC
    or a                        ; 42DF
    jp nz, Row_Ch2              ; 42E0
    ld a, e                     ; 42E3
    and $3F                     ; 42E4
    jr z, .L42EB                ; 42E6
    ld [wCh1_Note], a           ; 42E8

;; Instrument byte: bits 0-5 = instrument+1 (0 = change the volume only),
;; bits 6-7 = volume shift (envelope volume >> 0/1/2/4: full, 1/2, 1/4, off).
.L42EB:
    bit 6, e                    ; 42EB
    jp z, Row_Ch2               ; 42ED
    ld a, [wCh1_RowIns]         ; 42F0
    and $3F                     ; 42F3
    jp nz, Row_Ch1_LoadIns      ; 42F5
    ld a, [wCh1_RowIns]         ; 42F8
    and $C0                     ; 42FB
    jr z, .L4325                ; 42FD
    rlc a                       ; 42FF
    rlc a                       ; 4301
    ld [wCh1_VolShift], a       ; 4303
    ld c, a                     ; 4306
    ldh a, [rNR12]              ; 4307
    and $0F                     ; 4309
    ld d, a                     ; 430B
    ldh a, [rNR12]              ; 430C
    inc c                       ; 430E
    dec c                       ; 430F
    jr z, .L4320                ; 4310
    dec c                       ; 4312
    jr z, .L431E                ; 4313
    dec c                       ; 4315
    jr z, .L431C                ; 4316
    srl a                       ; 4318
    srl a                       ; 431A
.L431C:
    srl a                       ; 431C
.L431E:
    srl a                       ; 431E
.L4320:
    and $F0                     ; 4320
    or d                        ; 4322
    ldh [rNR12], a              ; 4323
.L4325:
    jp Row_Ch1_Trigger          ; 4325

;; Square instrument: [flags: bits 0-5 = playlist steps] [playlist speed,
;; bit 7 = vibrato bytes follow] [NRx2 envelope] ([vibrato delay]
;; [depth<<4 | speed]) followed by the 3-byte playlist steps.
Row_Ch1_LoadIns:
    dec a                       ; 4328
    ld c, a                     ; 4329
    ld a, [wCh1_RowIns]         ; 432A
    and $C0                     ; 432D
    rlc a                       ; 432F
    rlc a                       ; 4331
    ld [wCh1_VolShift], a       ; 4333
    ld a, [wHdr_InstsLo]        ; 4336
    ld l, a                     ; 4339
    ld a, [wHdr_InstsHi]        ; 433A
    ld h, a                     ; 433D
    add hl, bc                  ; 433E
    add hl, bc                  ; 433F
    ld a, [hl+]                 ; 4340
    ld c, a                     ; 4341
    ld a, [hl+]                 ; 4342
    ld h, a                     ; 4343
    ld l, c                     ; 4344
    ld a, [hl+]                 ; 4345
    ld [wCh1_InsFlags], a       ; 4346
    ld d, a                     ; 4349
    ld a, [hl+]                 ; 434A
    ld [wCh1_PLSpeed], a        ; 434B
    xor a                       ; 434E
    ld [wCh1_PLTimer], a        ; 434F
    ld a, $80                   ; 4352
    ldh [rNR11], a              ; 4354
    ld a, [wCh1_VolShift]       ; 4356
    ld c, a                     ; 4359
    ld a, [hl]                  ; 435A
    and $0F                     ; 435B
    ld e, a                     ; 435D
    ld a, [hl+]                 ; 435E
    inc c                       ; 435F
    dec c                       ; 4360
    jr z, .L4371                ; 4361
    dec c                       ; 4363
    jr z, .L436F                ; 4364
    dec c                       ; 4366
    jr z, .L436D                ; 4367
    srl a                       ; 4369
    srl a                       ; 436B
.L436D:
    srl a                       ; 436D
.L436F:
    srl a                       ; 436F
.L4371:
    and $F0                     ; 4371
    or e                        ; 4373
    ldh [rNR12], a              ; 4374
    ld a, [wCh1_PLSpeed]        ; 4376
    bit 7, a                    ; 4379
    jr z, .L4391                ; 437B
    ld a, [hl+]                 ; 437D
    ld [wCh1_VibDelay], a       ; 437E
    ld a, [hl+]                 ; 4381
    ld c, a                     ; 4382
    and $0F                     ; 4383
    ld [wCh1_VibSpeed], a       ; 4385
    ld a, c                     ; 4388
    and $F0                     ; 4389
    ld [wCh1_VibDepth], a       ; 438B
    xor a                       ; 438E
    jr .L439B                   ; 438F
.L4391:
    xor a                       ; 4391
    ld [wCh1_VibDelay], a       ; 4392
    ld [wCh1_VibDepth], a       ; 4395
    ld [wCh1_VibSpeed], a       ; 4398
.L439B:
    ld [wCh1_VibPhase], a       ; 439B
    ld a, d                     ; 439E
    and $3F                     ; 439F
    ld [wCh1_PLSteps], a        ; 43A1
    ld a, l                     ; 43A4
    ld [wCh1_PLPtrLo], a        ; 43A5
    ld a, h                     ; 43A8
    ld [wCh1_PLPtrHi], a        ; 43A9

;; Retrigger the channel (NRx4 bit 7).
Row_Ch1_Trigger:
    ld hl, rNR14                ; 43AC
    set 7, [hl]                 ; 43AF
Row_Ch2:
    ld a, [wCh2_TrackPtrLo]     ; 43B1
    ld l, a                     ; 43B4
    ld a, [wCh2_TrackPtrHi]     ; 43B5
    ld h, a                     ; 43B8
    ld a, [hl+]                 ; 43B9
    ld [wCh2_RowNote], a        ; 43BA
    ld e, a                     ; 43BD
    bit 6, e                    ; 43BE
    jr z, .L43C6                ; 43C0
    ld a, [hl+]                 ; 43C2
    ld [wCh2_RowIns], a         ; 43C3
.L43C6:
    bit 7, e                    ; 43C6
    jr z, .L43CE                ; 43C8
    ld a, [hl+]                 ; 43CA
    ld [wCh2_RowFx], a          ; 43CB
.L43CE:
    ld a, l                     ; 43CE
    ld [wCh2_TrackPtrLo], a     ; 43CF
    ld a, h                     ; 43D2
    ld [wCh2_TrackPtrHi], a     ; 43D3
    bit 7, e                    ; 43D6
    jr z, Row_Ch2_Decode        ; 43D8
    ld a, [wCh2_RowFx]          ; 43DA
    ld c, a                     ; 43DD
    swap c                      ; 43DE
    and $0F                     ; 43E0
    sub $08                     ; 43E2
    jr nz, .L43EC               ; 43E4
    ld a, c                     ; 43E6
    and $0F                     ; 43E7
    ld [wReturnFlag], a         ; 43E9
.L43EC:
    sub $07                     ; 43EC
    jr nz, Row_Ch2_Decode       ; 43EE
    ld a, c                     ; 43F0
    and $0F                     ; 43F1
    ld [wSpeed], a              ; 43F3
Row_Ch2_Decode:
    ld a, [wCh2_SFXTimer]       ; 43F6
    or a                        ; 43F9
    jp nz, Row_Ch3              ; 43FA
    ld a, e                     ; 43FD
    and $3F                     ; 43FE
    jr z, .L4405                ; 4400
    ld [wCh2_Note], a           ; 4402
.L4405:
    bit 6, e                    ; 4405
    jp z, Row_Ch3               ; 4407
    ld a, [wCh2_RowIns]         ; 440A
    and $3F                     ; 440D
    jp nz, Row_Ch2_LoadIns      ; 440F
    ld a, [wCh2_RowIns]         ; 4412
    and $C0                     ; 4415
    jr z, .L443F                ; 4417
    rlc a                       ; 4419
    rlc a                       ; 441B
    ld [wCh2_VolShift], a       ; 441D
    ld c, a                     ; 4420
    ldh a, [rNR22]              ; 4421
    and $0F                     ; 4423
    ld d, a                     ; 4425
    ldh a, [rNR22]              ; 4426
    inc c                       ; 4428
    dec c                       ; 4429
    jr z, .L443A                ; 442A
    dec c                       ; 442C
    jr z, .L4438                ; 442D
    dec c                       ; 442F
    jr z, .L4436                ; 4430
    srl a                       ; 4432
    srl a                       ; 4434
.L4436:
    srl a                       ; 4436
.L4438:
    srl a                       ; 4438
.L443A:
    and $F0                     ; 443A
    or d                        ; 443C
    ldh [rNR22], a              ; 443D
.L443F:
    jp Row_Ch2_Trigger          ; 443F
Row_Ch2_LoadIns:
    dec a                       ; 4442
    ld c, a                     ; 4443
    ld a, [wCh2_RowIns]         ; 4444
    and $C0                     ; 4447
    rlc a                       ; 4449
    rlc a                       ; 444B
    ld [wCh2_VolShift], a       ; 444D
    ld a, [wHdr_InstsLo]        ; 4450
    ld l, a                     ; 4453
    ld a, [wHdr_InstsHi]        ; 4454
    ld h, a                     ; 4457
    add hl, bc                  ; 4458
    add hl, bc                  ; 4459
    ld a, [hl+]                 ; 445A
    ld c, a                     ; 445B
    ld a, [hl+]                 ; 445C
    ld h, a                     ; 445D
    ld l, c                     ; 445E
    ld a, [hl+]                 ; 445F
    ld [wCh2_InsFlags], a       ; 4460
    ld d, a                     ; 4463
    ld a, [hl+]                 ; 4464
    ld [wCh2_PLSpeed], a        ; 4465
    xor a                       ; 4468
    ld [wCh2_PLTimer], a        ; 4469
    ld a, $80                   ; 446C
    ldh [rNR21], a              ; 446E
    ld a, [wCh2_VolShift]       ; 4470
    ld c, a                     ; 4473
    ld a, [hl]                  ; 4474
    and $0F                     ; 4475
    ld e, a                     ; 4477
    ld a, [hl+]                 ; 4478
    inc c                       ; 4479
    dec c                       ; 447A
    jr z, .L448B                ; 447B
    dec c                       ; 447D
    jr z, .L4489                ; 447E
    dec c                       ; 4480
    jr z, .L4487                ; 4481
    srl a                       ; 4483
    srl a                       ; 4485
.L4487:
    srl a                       ; 4487
.L4489:
    srl a                       ; 4489
.L448B:
    and $F0                     ; 448B
    or e                        ; 448D
    ldh [rNR22], a              ; 448E
    ld a, [wCh2_PLSpeed]        ; 4490
    bit 7, a                    ; 4493
    jr z, .L44AB                ; 4495
    ld a, [hl+]                 ; 4497
    ld [wCh2_VibDelay], a       ; 4498
    ld a, [hl+]                 ; 449B
    ld c, a                     ; 449C
    and $0F                     ; 449D
    ld [wCh2_VibSpeed], a       ; 449F
    ld a, c                     ; 44A2
    and $F0                     ; 44A3
    ld [wCh2_VibDepth], a       ; 44A5
    xor a                       ; 44A8
    jr .L44B5                   ; 44A9
.L44AB:
    xor a                       ; 44AB
    ld [wCh2_VibDelay], a       ; 44AC
    ld [wCh2_VibDepth], a       ; 44AF
    ld [wCh2_VibSpeed], a       ; 44B2
.L44B5:
    ld [wCh2_VibPhase], a       ; 44B5
    ld a, d                     ; 44B8
    and $3F                     ; 44B9
    ld [wCh2_PLSteps], a        ; 44BB
    ld a, l                     ; 44BE
    ld [wCh2_PLPtrLo], a        ; 44BF
    ld a, h                     ; 44C2
    ld [wCh2_PLPtrHi], a        ; 44C3
Row_Ch2_Trigger:
    ld hl, rNR24                ; 44C6
    set 7, [hl]                 ; 44C9

;; New row on channel 3 (wave).
Row_Ch3:
    ld a, [wCh3_TrackPtrLo]     ; 44CB
    ld l, a                     ; 44CE
    ld a, [wCh3_TrackPtrHi]     ; 44CF
    ld h, a                     ; 44D2
    ld a, [hl+]                 ; 44D3
    ld [wCh3_RowNote], a        ; 44D4
    ld e, a                     ; 44D7
    bit 6, e                    ; 44D8
    jr z, .L44E0                ; 44DA
    ld a, [hl+]                 ; 44DC
    ld [wCh3_RowIns], a         ; 44DD
.L44E0:
    bit 7, e                    ; 44E0
    jr z, .L44E8                ; 44E2
    ld a, [hl+]                 ; 44E4
    ld [wCh3_RowFx], a          ; 44E5
.L44E8:
    ld a, l                     ; 44E8
    ld [wCh3_TrackPtrLo], a     ; 44E9
    ld a, h                     ; 44EC
    ld [wCh3_TrackPtrHi], a     ; 44ED
    bit 7, e                    ; 44F0
    jr z, Row_Ch3_Decode        ; 44F2
    ld a, [wCh3_RowFx]          ; 44F4
    ld c, a                     ; 44F7
    swap c                      ; 44F8
    and $0F                     ; 44FA
    sub $08                     ; 44FC
    jr nz, .L4506               ; 44FE
    ld a, c                     ; 4500
    and $0F                     ; 4501
    ld [wReturnFlag], a         ; 4503
.L4506:
    sub $07                     ; 4506
    jr nz, Row_Ch3_Decode       ; 4508
    ld a, c                     ; 450A
    and $0F                     ; 450B
    ld [wSpeed], a              ; 450D
Row_Ch3_Decode:
    ld a, [wCh3_SFXTimer]       ; 4510
    or a                        ; 4513
    jp nz, Row_Ch4              ; 4514
    ld a, e                     ; 4517
    and $3F                     ; 4518
    jr z, .L451F                ; 451A
    ld [wCh3_Note], a           ; 451C
.L451F:
    bit 6, e                    ; 451F
    jp z, Row_Ch4               ; 4521

;; Ch3: the two volume bits select the NR32 level directly (1 = 25%, 2 = 50%,
;; 3 = 100%); 0 keeps the instrument's level, or mutes on a volume-only row.
    ld a, [wCh3_RowIns]         ; 4524
    and $3F                     ; 4527
    jp nz, Row_Ch3_LoadIns      ; 4529
    ld a, [wCh3_RowIns]         ; 452C
    rrc a                       ; 452F
    jr z, .L4539                ; 4531
    cp $40                      ; 4533
    jr z, .L4539                ; 4535
    xor $40                     ; 4537
.L4539:
    ldh [rNR32], a              ; 4539
    jp Row_Ch4                  ; 453B

;; Wave instrument: [flags: bits 0-5 steps, bits 6-7 <> 0 = "PCM" (ch3 is left
;; to the game: wWave_PCMFlag mutes the ch3 tick)] [speed] [NR32] (vibrato)
;; [sweep step] [flag byte] [dw position] [dw lower] [dw upper] [sweep speed]
;; [base lo] [base hi] + steps. 16 bytes at base+position are copied to wave
;; RAM; with the sweep on (playlist command $C0 toggles it) the position moves
;; by "step" every "sweep speed" ticks and bounces between lower and upper.
Row_Ch3_LoadIns:
    dec a                       ; 453E
    ld c, a                     ; 453F
    ld a, [wCh3_RowIns]         ; 4540
    and $C0                     ; 4543
    jr z, .L454F                ; 4545
    rrc a                       ; 4547
    cp $40                      ; 4549
    jr z, .L454F                ; 454B
    xor $40                     ; 454D
.L454F:
    ld [wCh3_VolShift], a       ; 454F
    ld a, [wHdr_InstsLo]        ; 4552
    ld l, a                     ; 4555
    ld a, [wHdr_InstsHi]        ; 4556
    ld h, a                     ; 4559
    add hl, bc                  ; 455A
    add hl, bc                  ; 455B
    ld a, [hl+]                 ; 455C
    ld c, a                     ; 455D
    ld a, [hl+]                 ; 455E
    ld h, a                     ; 455F
    ld l, c                     ; 4560
    ld a, [hl+]                 ; 4561
    ld [wCh3_InsFlags], a       ; 4562
    ld d, a                     ; 4565
    and $C0                     ; 4566
    ld [wWave_PCMFlag], a       ; 4568
    ldh a, [rIE]                ; 456B
    and $FB                     ; 456D
    ldh [rIE], a                ; 456F
    ld a, [hl+]                 ; 4571
    ld [wCh3_PLSpeed], a        ; 4572
    xor a                       ; 4575
    ld [wCh3_PLTimer], a        ; 4576
    ld a, [wCh3_VolShift]       ; 4579
    or a                        ; 457C
    jr z, .L4582                ; 457D
    inc hl                      ; 457F
    jr .L4588                   ; 4580
.L4582:
    ld a, [hl+]                 ; 4582
    ld [wCh3_Level], a          ; 4583
    and $FE                     ; 4586
.L4588:
    ldh [rNR32], a              ; 4588
    xor a                       ; 458A
    ld [wCh3_VolShift], a       ; 458B
    ld a, [wCh3_PLSpeed]        ; 458E
    bit 7, a                    ; 4591
    jr z, .L45A9                ; 4593
    ld a, [hl+]                 ; 4595
    ld [wCh3_VibDelay], a       ; 4596
    ld a, [hl+]                 ; 4599
    ld c, a                     ; 459A
    and $0F                     ; 459B
    ld [wCh3_VibSpeed], a       ; 459D
    ld a, c                     ; 45A0
    and $F0                     ; 45A1
    ld [wCh3_VibDepth], a       ; 45A3
    xor a                       ; 45A6
    jr .L45B3                   ; 45A7
.L45A9:
    xor a                       ; 45A9
    ld [wCh3_VibDelay], a       ; 45AA
    ld [wCh3_VibDepth], a       ; 45AD
    ld [wCh3_VibSpeed], a       ; 45B0
.L45B3:
    ld [wCh3_VibPhase], a       ; 45B3
    ld a, [hl+]                 ; 45B6
    ld [wWave_Step], a          ; 45B7
    xor a                       ; 45BA
    ld [wWave_SweepOn], a       ; 45BB
    ld [wWave_FlagHi], a        ; 45BE
    ld a, [hl+]                 ; 45C1
    bit 7, a                    ; 45C2
    jr z, .L45C9                ; 45C4
    ld [wWave_FlagHi], a        ; 45C6
.L45C9:
    and $7F                     ; 45C9
    ld [wWave_FlagLo], a        ; 45CB
    ld a, [hl+]                 ; 45CE
    ld [wWave_PosLo], a         ; 45CF
    ld a, [hl+]                 ; 45D2
    ld [wWave_PosHi], a         ; 45D3
    ld a, [hl+]                 ; 45D6
    ld [wWave_LowerLo], a       ; 45D7
    ld a, [hl+]                 ; 45DA
    ld [wWave_LowerHi], a       ; 45DB
    ld a, [hl+]                 ; 45DE
    ld [wWave_UpperLo], a       ; 45DF
    ld a, [hl+]                 ; 45E2
    ld [wWave_UpperHi], a       ; 45E3
    ld a, [hl+]                 ; 45E6
    ld [wWave_SweepSpeed], a    ; 45E7
    ld [wWave_SweepTimer], a    ; 45EA
    ld a, [hl+]                 ; 45ED
    ld [wWave_BaseLo], a        ; 45EE
    ld a, [hl+]                 ; 45F1
    ld [wWave_BaseHi], a        ; 45F2
    ld a, d                     ; 45F5
    and $3F                     ; 45F6
    ld [wCh3_PLSteps], a        ; 45F8
    ld a, l                     ; 45FB
    ld [wCh3_PLPtrLo], a        ; 45FC
    ld a, h                     ; 45FF
    ld [wCh3_PLPtrHi], a        ; 4600
    ld a, $FF                   ; 4603
    ld [wWave_WaveUpdate], a    ; 4605

;; New row on channel 4 (noise). Instrument: [flags] [speed] [NR42] + steps.
Row_Ch4:
    ld a, [wCh4_TrackPtrLo]     ; 4608
    ld l, a                     ; 460B
    ld a, [wCh4_TrackPtrHi]     ; 460C
    ld h, a                     ; 460F
    ld a, [hl+]                 ; 4610
    ld [wCh4_RowNote], a        ; 4611
    ld e, a                     ; 4614
    bit 6, e                    ; 4615
    jr z, .L461D                ; 4617
    ld a, [hl+]                 ; 4619
    ld [wCh4_RowIns], a         ; 461A
.L461D:
    bit 7, e                    ; 461D
    jr z, .L4625                ; 461F
    ld a, [hl+]                 ; 4621
    ld [wCh4_RowFx], a          ; 4622
.L4625:
    ld a, l                     ; 4625
    ld [wCh4_TrackPtrLo], a     ; 4626
    ld a, h                     ; 4629
    ld [wCh4_TrackPtrHi], a     ; 462A
    bit 7, e                    ; 462D
    jr z, Row_Ch4_Decode        ; 462F
    ld a, [wCh4_RowFx]          ; 4631
    ld c, a                     ; 4634
    swap c                      ; 4635
    and $0F                     ; 4637
    sub $08                     ; 4639
    jr nz, .L4643               ; 463B
    ld a, c                     ; 463D
    and $0F                     ; 463E
    ld [wReturnFlag], a         ; 4640
.L4643:
    sub $07                     ; 4643
    jr nz, Row_Ch4_Decode       ; 4645
    ld a, c                     ; 4647
    and $0F                     ; 4648
    ld [wSpeed], a              ; 464A
Row_Ch4_Decode:
    ld a, [wCh4_SFXTimer]       ; 464D
    or a                        ; 4650
    jp nz, Row_Done             ; 4651
    ld a, e                     ; 4654
    and $3F                     ; 4655
    jr z, .L465C                ; 4657
    ld [wCh4_Note], a           ; 4659
.L465C:
    bit 6, e                    ; 465C
    jp z, Row_Done              ; 465E
    ld a, [wCh4_RowIns]         ; 4661
    and $3F                     ; 4664
    jp nz, Row_Ch4_LoadIns      ; 4666
    ld a, [wCh4_RowIns]         ; 4669
    and $C0                     ; 466C
    jr z, .L4696                ; 466E
    rlc a                       ; 4670
    rlc a                       ; 4672
    ld [wCh4_VolShift], a       ; 4674
    ld c, a                     ; 4677
    ldh a, [rNR42]              ; 4678
    and $0F                     ; 467A
    ld d, a                     ; 467C
    ldh a, [rNR42]              ; 467D
    inc c                       ; 467F
    dec c                       ; 4680
    jr z, .L4691                ; 4681
    dec c                       ; 4683
    jr z, .L468F                ; 4684
    dec c                       ; 4686
    jr z, .L468D                ; 4687
    srl a                       ; 4689
    srl a                       ; 468B
.L468D:
    srl a                       ; 468D
.L468F:
    srl a                       ; 468F
.L4691:
    and $F0                     ; 4691
    or d                        ; 4693
    ldh [rNR42], a              ; 4694
.L4696:
    jp Row_Ch4_Trigger          ; 4696
Row_Ch4_LoadIns:
    dec a                       ; 4699
    ld c, a                     ; 469A
    ld a, [wCh4_RowIns]         ; 469B
    and $C0                     ; 469E
    rlc a                       ; 46A0
    rlc a                       ; 46A2
    ld [wCh4_VolShift], a       ; 46A4
    ld a, [wHdr_InstsLo]        ; 46A7
    ld l, a                     ; 46AA
    ld a, [wHdr_InstsHi]        ; 46AB
    ld h, a                     ; 46AE
    add hl, bc                  ; 46AF
    add hl, bc                  ; 46B0
    ld a, [hl+]                 ; 46B1
    ld c, a                     ; 46B2
    ld a, [hl+]                 ; 46B3
    ld h, a                     ; 46B4
    ld l, c                     ; 46B5
    ld a, [hl+]                 ; 46B6
    ld [wCh4_InsFlags], a       ; 46B7
    ld d, a                     ; 46BA
    ld a, [hl+]                 ; 46BB
    ld [wCh4_PLSpeed], a        ; 46BC
    xor a                       ; 46BF
    ld [wCh4_PLTimer], a        ; 46C0
    ld a, $00                   ; 46C3
    ldh [rNR41], a              ; 46C5
    ld a, [wCh4_VolShift]       ; 46C7
    ld c, a                     ; 46CA
    ld a, [hl]                  ; 46CB
    and $0F                     ; 46CC
    ld e, a                     ; 46CE
    ld a, [hl+]                 ; 46CF
    inc c                       ; 46D0
    dec c                       ; 46D1
    jr z, .L46E2                ; 46D2
    dec c                       ; 46D4
    jr z, .L46E0                ; 46D5
    dec c                       ; 46D7
    jr z, .L46DE                ; 46D8
    srl a                       ; 46DA
    srl a                       ; 46DC
.L46DE:
    srl a                       ; 46DE
.L46E0:
    srl a                       ; 46E0
.L46E2:
    and $F0                     ; 46E2
    or e                        ; 46E4
    ldh [rNR42], a              ; 46E5
    ld a, d                     ; 46E7
    and $3F                     ; 46E8
    ld [wCh4_PLSteps], a        ; 46EA
    ld a, l                     ; 46ED
    ld [wCh4_PLPtrLo], a        ; 46EE
    ld a, h                     ; 46F1
    ld [wCh4_PLPtrHi], a        ; 46F2
Row_Ch4_Trigger:
    ld hl, rNR44                ; 46F5
    set 7, [hl]                 ; 46F8

;; Row done: wTickCount = speed - wSpeedAdjust.
Row_Done:
    ld a, [wSpeedAdjust]        ; 46FA
    ld c, a                     ; 46FD
    ld a, [wSpeed]              ; 46FE
    sub c                       ; 4701
    ld [wTickCount], a          ; 4702
Tick_Count:
    ld hl, wTickCount           ; 4705
    dec [hl]                    ; 4708

;; Per-tick processing of all four channels: instrument playlist, vibrato,
;; frequency. Playlist step = [note] [cmd] [cmd].
;; Note byte: bits 0-5 note (0 = keep), bit 6 = absolute note, otherwise
;; relative to the row note (+transpose; 1 = unison).
;; Command: $00 none, $01-$3F new playlist speed, $40|v volume v (NRx2
;; high nibble, retrigger; ch3: NR32 level), $80|n jump back n steps,
;; $C0|d duty d (ch1/2) / toggle the wave sweep (ch3).
Tick:
    ld a, [wCh1_SFXTimer]       ; 4709
    or a                        ; 470C
    jr z, Tick_Ch1              ; 470D
    dec a                       ; 470F
    ld [wCh1_SFXTimer], a       ; 4710

;; Channel 1 playlist.
Tick_Ch1:
    ld a, [wCh1_PLTimer]        ; 4713
    or a                        ; 4716
    jp nz, Tick_Ch1_Pitch       ; 4717
    ld a, [wCh1_PLSteps]        ; 471A
    or a                        ; 471D
    jp z, Tick_Ch1_PLWait       ; 471E
    dec a                       ; 4721
    ld [wCh1_PLSteps], a        ; 4722
    ld a, [wCh1_PLPtrLo]        ; 4725
    ld l, a                     ; 4728
    ld a, [wCh1_PLPtrHi]        ; 4729
    ld h, a                     ; 472C
    ld a, [hl+]                 ; 472D
    ld [wCh1_PLNoteRaw], a      ; 472E
    and $3F                     ; 4731
    jr z, .L4738                ; 4733
    ld [wCh1_PLNote], a         ; 4735
.L4738:
    ld a, [hl+]                 ; 4738
    bit 7, a                    ; 4739
    jr nz, .L4779               ; 473B
    bit 6, a                    ; 473D
    jr nz, .L474B               ; 473F
    and $3F                     ; 4741
    jr z, .L4748                ; 4743
    ld [wCh1_PLSpeed], a        ; 4745
.L4748:
    jp .L479A                   ; 4748
.L474B:
    swap a                      ; 474B
    ld d, a                     ; 474D
    ld a, [wCh1_VolShift]       ; 474E
    ld c, a                     ; 4751
    ld a, d                     ; 4752
    inc c                       ; 4753
    dec c                       ; 4754
    jr z, .L4765                ; 4755
    dec c                       ; 4757
    jr z, .L4763                ; 4758
    dec c                       ; 475A
    jr z, .L4761                ; 475B
    srl a                       ; 475D
    srl a                       ; 475F
.L4761:
    srl a                       ; 4761
.L4763:
    srl a                       ; 4763
.L4765:
    and $F0                     ; 4765
    ld c, a                     ; 4767
    ldh a, [rNR12]              ; 4768
    and $0F                     ; 476A
    or c                        ; 476C
    ldh [rNR12], a              ; 476D
    push hl                     ; 476F
    ld hl, rNR14                ; 4770
    set 7, [hl]                 ; 4773
    pop hl                      ; 4775
    jp .L479A                   ; 4776
.L4779:
    bit 6, a                    ; 4779
    jr nz, .L4792               ; 477B
    and $3F                     ; 477D
    ld d, a                     ; 477F
    cpl                         ; 4780
    inc a                       ; 4781
    ld c, a                     ; 4782
    dec b                       ; 4783
    add hl, bc                  ; 4784
    add hl, bc                  ; 4785
    add hl, bc                  ; 4786
    inc b                       ; 4787
    ld a, [wCh1_PLSteps]        ; 4788
    ld c, d                     ; 478B
    add a,c                     ; 478C
    ld [wCh1_PLSteps], a        ; 478D
    jr .L479A                   ; 4790
.L4792:
    and $3F                     ; 4792
    rrc a                       ; 4794
    rrc a                       ; 4796
    ldh [rNR11], a              ; 4798
.L479A:
    ld a, [hl+]                 ; 479A
    bit 7, a                    ; 479B
    jr nz, .L47DB               ; 479D
    bit 6, a                    ; 479F
    jr nz, .L47AD               ; 47A1
    and $3F                     ; 47A3
    jr z, .L47AA                ; 47A5
    ld [wCh1_PLSpeed], a        ; 47A7
.L47AA:
    jp .L47FC                   ; 47AA
.L47AD:
    swap a                      ; 47AD
    ld d, a                     ; 47AF
    ld a, [wCh1_VolShift]       ; 47B0
    ld c, a                     ; 47B3
    ld a, d                     ; 47B4
    inc c                       ; 47B5
    dec c                       ; 47B6
    jr z, .L47C7                ; 47B7
    dec c                       ; 47B9
    jr z, .L47C5                ; 47BA
    dec c                       ; 47BC
    jr z, .L47C3                ; 47BD
    srl a                       ; 47BF
    srl a                       ; 47C1
.L47C3:
    srl a                       ; 47C3
.L47C5:
    srl a                       ; 47C5
.L47C7:
    and $F0                     ; 47C7
    ld c, a                     ; 47C9
    ldh a, [rNR12]              ; 47CA
    and $0F                     ; 47CC
    or c                        ; 47CE
    ldh [rNR12], a              ; 47CF
    push hl                     ; 47D1
    ld hl, rNR14                ; 47D2
    set 7, [hl]                 ; 47D5
    pop hl                      ; 47D7
    jp .L47FC                   ; 47D8
.L47DB:
    bit 6, a                    ; 47DB
    jr nz, .L47F4               ; 47DD
    and $3F                     ; 47DF
    ld d, a                     ; 47E1
    cpl                         ; 47E2
    inc a                       ; 47E3
    ld c, a                     ; 47E4
    dec b                       ; 47E5
    add hl, bc                  ; 47E6
    add hl, bc                  ; 47E7
    add hl, bc                  ; 47E8
    inc b                       ; 47E9
    ld a, [wCh1_PLSteps]        ; 47EA
    ld c, d                     ; 47ED
    add a,c                     ; 47EE
    ld [wCh1_PLSteps], a        ; 47EF
    jr .L47FC                   ; 47F2
.L47F4:
    and $3F                     ; 47F4
    rrc a                       ; 47F6
    rrc a                       ; 47F8
    ldh [rNR11], a              ; 47FA
.L47FC:
    ld a, l                     ; 47FC
    ld [wCh1_PLPtrLo], a        ; 47FD
    ld a, h                     ; 4800
    ld [wCh1_PLPtrHi], a        ; 4801
Tick_Ch1_PLWait:
    ld a, [wCh1_PLSpeed]        ; 4804
    res 7, a                    ; 4807
    ld [wCh1_PLTimer], a        ; 4809

;; Frequency = FreqTable[transpose + row note + playlist note - 1] (or the
;; absolute playlist note) + vibrato. Vibrato: after VibDelay ticks the phase
;; advances by VibSpeed (6 bits) and VibratoTable[depth | phase>>2] is added.
Tick_Ch1_Pitch:
    ld hl, wCh1_PLTimer         ; 480C
    dec [hl]                    ; 480F
    ld a, [wCh1_PLNote]         ; 4810
    ld c, a                     ; 4813
    ld a, [wCh1_PLNoteRaw]      ; 4814
    bit 6, a                    ; 4817
    jr nz, .L4826               ; 4819
    ld a, [wCh1_Transpose]      ; 481B
    add a,c                     ; 481E
    ld c, a                     ; 481F
    ld a, [wCh1_Note]           ; 4820
    add a,c                     ; 4823
    dec a                       ; 4824
    ld c, a                     ; 4825
.L4826:
    ld hl, FreqTable            ; 4826
    add hl, bc                  ; 4829
    add hl, bc                  ; 482A
    ld c, $00                   ; 482B
    ld a, [wCh1_VibDepth]       ; 482D
    or a                        ; 4830
    jr z, .L4864                ; 4831
    ld a, [wCh1_VibDelay]       ; 4833
    dec a                       ; 4836
    cp $FF                      ; 4837
    jr z, .L4840                ; 4839
    ld [wCh1_VibDelay], a       ; 483B
    jr .L4864                   ; 483E
.L4840:
    ld a, [wCh1_VibSpeed]       ; 4840
    ld c, a                     ; 4843
    ld a, [wCh1_VibPhase]       ; 4844
    add a,c                     ; 4847
    and $3F                     ; 4848
    ld [wCh1_VibPhase], a       ; 484A
    srl a                       ; 484D
    srl a                       ; 484F
    ld c, a                     ; 4851
    ld a, [wCh1_VibDepth]       ; 4852
    or c                        ; 4855
    ld c, a                     ; 4856
    push hl                     ; 4857
    ld hl, VibratoTable         ; 4858
    add hl, bc                  ; 485B
    ld a, [hl]                  ; 485C
    pop hl                      ; 485D
    ld c, a                     ; 485E
    bit 7, a                    ; 485F
    jr z, .L4864                ; 4861
    dec b                       ; 4863
.L4864:
    ld a, [hl+]                 ; 4864
    ld e, a                     ; 4865
    ld a, [hl]                  ; 4866
    ld h, a                     ; 4867
    ld l, e                     ; 4868
    add hl, bc                  ; 4869
    ld b, $00                   ; 486A
    ld a, l                     ; 486C
    ldh [rNR13], a              ; 486D
    ld a, h                     ; 486F
    ldh [rNR14], a              ; 4870

;; Channel 2 tick.
Tick_Ch2:
    ld a, [wCh2_SFXTimer]       ; 4872
    or a                        ; 4875
    jr z, .L487C                ; 4876
    dec a                       ; 4878
    ld [wCh2_SFXTimer], a       ; 4879
.L487C:
    ld a, [wCh2_PLTimer]        ; 487C
    or a                        ; 487F
    jp nz, Tick_Ch2_Pitch       ; 4880
    ld a, [wCh2_PLSteps]        ; 4883
    or a                        ; 4886
    jp z, Tick_Ch2_PLWait       ; 4887
    dec a                       ; 488A
    ld [wCh2_PLSteps], a        ; 488B
    ld a, [wCh2_PLPtrLo]        ; 488E
    ld l, a                     ; 4891
    ld a, [wCh2_PLPtrHi]        ; 4892
    ld h, a                     ; 4895
    ld a, [hl+]                 ; 4896
    ld [wCh2_PLNoteRaw], a      ; 4897
    and $3F                     ; 489A
    jr z, .L48A1                ; 489C
    ld [wCh2_PLNote], a         ; 489E
.L48A1:
    ld a, [hl+]                 ; 48A1
    bit 7, a                    ; 48A2
    jr nz, .L48E2               ; 48A4
    bit 6, a                    ; 48A6
    jr nz, .L48B4               ; 48A8
    and $3F                     ; 48AA
    jr z, .L48B1                ; 48AC
    ld [wCh2_PLSpeed], a        ; 48AE
.L48B1:
    jp .L4903                   ; 48B1
.L48B4:
    swap a                      ; 48B4
    ld d, a                     ; 48B6
    ld a, [wCh2_VolShift]       ; 48B7
    ld c, a                     ; 48BA
    ld a, d                     ; 48BB
    inc c                       ; 48BC
    dec c                       ; 48BD
    jr z, .L48CE                ; 48BE
    dec c                       ; 48C0
    jr z, .L48CC                ; 48C1
    dec c                       ; 48C3
    jr z, .L48CA                ; 48C4
    srl a                       ; 48C6
    srl a                       ; 48C8
.L48CA:
    srl a                       ; 48CA
.L48CC:
    srl a                       ; 48CC
.L48CE:
    and $F0                     ; 48CE
    ld c, a                     ; 48D0
    ldh a, [rNR22]              ; 48D1
    and $0F                     ; 48D3
    or c                        ; 48D5
    ldh [rNR22], a              ; 48D6
    push hl                     ; 48D8
    ld hl, rNR24                ; 48D9
    set 7, [hl]                 ; 48DC
    pop hl                      ; 48DE
    jp .L4903                   ; 48DF
.L48E2:
    bit 6, a                    ; 48E2
    jr nz, .L48FB               ; 48E4
    and $3F                     ; 48E6
    ld d, a                     ; 48E8
    cpl                         ; 48E9
    inc a                       ; 48EA
    ld c, a                     ; 48EB
    dec b                       ; 48EC
    add hl, bc                  ; 48ED
    add hl, bc                  ; 48EE
    add hl, bc                  ; 48EF
    inc b                       ; 48F0
    ld a, [wCh2_PLSteps]        ; 48F1
    ld c, d                     ; 48F4
    add a,c                     ; 48F5
    ld [wCh2_PLSteps], a        ; 48F6
    jr .L4903                   ; 48F9
.L48FB:
    and $3F                     ; 48FB
    rrc a                       ; 48FD
    rrc a                       ; 48FF
    ldh [rNR21], a              ; 4901
.L4903:
    ld a, [hl+]                 ; 4903
    bit 7, a                    ; 4904
    jr nz, .L4944               ; 4906
    bit 6, a                    ; 4908
    jr nz, .L4916               ; 490A
    and $3F                     ; 490C
    jr z, .L4913                ; 490E
    ld [wCh2_PLSpeed], a        ; 4910
.L4913:
    jp .L4965                   ; 4913
.L4916:
    swap a                      ; 4916
    ld d, a                     ; 4918
    ld a, [wCh2_VolShift]       ; 4919
    ld c, a                     ; 491C
    ld a, d                     ; 491D
    inc c                       ; 491E
    dec c                       ; 491F
    jr z, .L4930                ; 4920
    dec c                       ; 4922
    jr z, .L492E                ; 4923
    dec c                       ; 4925
    jr z, .L492C                ; 4926
    srl a                       ; 4928
    srl a                       ; 492A
.L492C:
    srl a                       ; 492C
.L492E:
    srl a                       ; 492E
.L4930:
    and $F0                     ; 4930
    ld c, a                     ; 4932
    ldh a, [rNR22]              ; 4933
    and $0F                     ; 4935
    or c                        ; 4937
    ldh [rNR22], a              ; 4938
    push hl                     ; 493A
    ld hl, rNR24                ; 493B
    set 7, [hl]                 ; 493E
    pop hl                      ; 4940
    jp .L4965                   ; 4941
.L4944:
    bit 6, a                    ; 4944
    jr nz, .L495D               ; 4946
    and $3F                     ; 4948
    ld d, a                     ; 494A
    cpl                         ; 494B
    inc a                       ; 494C
    ld c, a                     ; 494D
    dec b                       ; 494E
    add hl, bc                  ; 494F
    add hl, bc                  ; 4950
    add hl, bc                  ; 4951
    inc b                       ; 4952
    ld a, [wCh2_PLSteps]        ; 4953
    ld c, d                     ; 4956
    add a,c                     ; 4957
    ld [wCh2_PLSteps], a        ; 4958
    jr .L4965                   ; 495B
.L495D:
    and $3F                     ; 495D
    rrc a                       ; 495F
    rrc a                       ; 4961
    ldh [rNR21], a              ; 4963
.L4965:
    ld a, l                     ; 4965
    ld [wCh2_PLPtrLo], a        ; 4966
    ld a, h                     ; 4969
    ld [wCh2_PLPtrHi], a        ; 496A
Tick_Ch2_PLWait:
    ld a, [wCh2_PLSpeed]        ; 496D
    res 7, a                    ; 4970
    ld [wCh2_PLTimer], a        ; 4972
Tick_Ch2_Pitch:
    ld hl, wCh2_PLTimer         ; 4975
    dec [hl]                    ; 4978
    ld a, [wCh2_PLNote]         ; 4979
    ld c, a                     ; 497C
    ld a, [wCh2_PLNoteRaw]      ; 497D
    bit 6, a                    ; 4980
    jr nz, .L498F               ; 4982
    ld a, [wCh2_Transpose]      ; 4984
    add a,c                     ; 4987
    ld c, a                     ; 4988
    ld a, [wCh2_Note]           ; 4989
    add a,c                     ; 498C
    dec a                       ; 498D
    ld c, a                     ; 498E
.L498F:
    ld hl, FreqTable            ; 498F
    add hl, bc                  ; 4992
    add hl, bc                  ; 4993
    ld c, $00                   ; 4994
    ld a, [wCh2_VibDepth]       ; 4996
    or a                        ; 4999
    jr z, .L49CD                ; 499A
    ld a, [wCh2_VibDelay]       ; 499C
    dec a                       ; 499F
    cp $FF                      ; 49A0
    jr z, .L49A9                ; 49A2
    ld [wCh2_VibDelay], a       ; 49A4
    jr .L49CD                   ; 49A7
.L49A9:
    ld a, [wCh2_VibSpeed]       ; 49A9
    ld c, a                     ; 49AC
    ld a, [wCh2_VibPhase]       ; 49AD
    add a,c                     ; 49B0
    and $3F                     ; 49B1
    ld [wCh2_VibPhase], a       ; 49B3
    srl a                       ; 49B6
    srl a                       ; 49B8
    ld c, a                     ; 49BA
    ld a, [wCh2_VibDepth]       ; 49BB
    or c                        ; 49BE
    ld c, a                     ; 49BF
    push hl                     ; 49C0
    ld hl, VibratoTable         ; 49C1
    add hl, bc                  ; 49C4
    ld a, [hl]                  ; 49C5
    pop hl                      ; 49C6
    ld c, a                     ; 49C7
    bit 7, a                    ; 49C8
    jr z, .L49CD                ; 49CA
    dec b                       ; 49CC
.L49CD:
    ld a, [hl+]                 ; 49CD
    ld e, a                     ; 49CE
    ld a, [hl]                  ; 49CF
    ld h, a                     ; 49D0
    ld l, e                     ; 49D1
    add hl, bc                  ; 49D2
    ld b, $00                   ; 49D3
    ld a, l                     ; 49D5
    ldh [rNR23], a              ; 49D6
    ld a, h                     ; 49D8
    ldh [rNR24], a              ; 49D9

;; Channel 3 tick (skipped completely while wWave_PCMFlag is set).
Tick_Ch3:
    ld a, [wWave_PCMFlag]       ; 49DB
    or a                        ; 49DE
    jp nz, Tick_Ch4             ; 49DF
    ld a, [wCh3_SFXTimer]       ; 49E2
    or a                        ; 49E5
    jr z, .L49EC                ; 49E6
    dec a                       ; 49E8
    ld [wCh3_SFXTimer], a       ; 49E9
.L49EC:
    ld a, [wCh3_PLTimer]        ; 49EC
    or a                        ; 49EF
    jp nz, Tick_Ch3_Sweep       ; 49F0
    ld a, [wCh3_PLSteps]        ; 49F3
    or a                        ; 49F6
    jp z, Tick_Ch3_PLWait       ; 49F7
    dec a                       ; 49FA
    ld [wCh3_PLSteps], a        ; 49FB
    ld a, [wCh3_PLPtrLo]        ; 49FE
    ld l, a                     ; 4A01
    ld a, [wCh3_PLPtrHi]        ; 4A02
    ld h, a                     ; 4A05
    ld a, [hl+]                 ; 4A06
    ld [wCh3_PLNoteRaw], a      ; 4A07
    and $3F                     ; 4A0A
    jr z, .L4A11                ; 4A0C
    ld [wCh3_PLNote], a         ; 4A0E
.L4A11:
    ld a, [hl+]                 ; 4A11
    bit 7, a                    ; 4A12
    jr nz, .L4A36               ; 4A14
    bit 6, a                    ; 4A16
    jr nz, .L4A24               ; 4A18
    and $3F                     ; 4A1A
    jr z, .L4A21                ; 4A1C
    ld [wCh3_PLSpeed], a        ; 4A1E
.L4A21:
    jp .L4A56                   ; 4A21
.L4A24:
    and $3F                     ; 4A24
    jr z, .L4A31                ; 4A26
    add a,a                     ; 4A28
    swap a                      ; 4A29
    cp $40                      ; 4A2B
    jr z, .L4A31                ; 4A2D
    xor $40                     ; 4A2F
.L4A31:
    ldh [rNR32], a              ; 4A31
    jp .L4A56                   ; 4A33
.L4A36:
    bit 6, a                    ; 4A36
    jr nz, .L4A4F               ; 4A38
    and $3F                     ; 4A3A
    ld d, a                     ; 4A3C
    cpl                         ; 4A3D
    inc a                       ; 4A3E
    ld c, a                     ; 4A3F
    dec b                       ; 4A40
    add hl, bc                  ; 4A41
    add hl, bc                  ; 4A42
    add hl, bc                  ; 4A43
    inc b                       ; 4A44
    ld a, [wCh3_PLSteps]        ; 4A45
    ld c, d                     ; 4A48
    add a,c                     ; 4A49
    ld [wCh3_PLSteps], a        ; 4A4A
    jr .L4A56                   ; 4A4D
.L4A4F:
    ld a, [wWave_SweepOn]       ; 4A4F
    cpl                         ; 4A52
    ld [wWave_SweepOn], a       ; 4A53
.L4A56:
    ld a, [hl+]                 ; 4A56
    bit 7, a                    ; 4A57
    jr nz, .L4A7B               ; 4A59
    bit 6, a                    ; 4A5B
    jr nz, .L4A69               ; 4A5D
    and $3F                     ; 4A5F
    jr z, .L4A66                ; 4A61
    ld [wCh3_PLSpeed], a        ; 4A63
.L4A66:
    jp .L4A9B                   ; 4A66
.L4A69:
    and $3F                     ; 4A69
    jr z, .L4A76                ; 4A6B
    add a,a                     ; 4A6D
    swap a                      ; 4A6E
    cp $40                      ; 4A70
    jr z, .L4A76                ; 4A72
    xor $40                     ; 4A74
.L4A76:
    ldh [rNR32], a              ; 4A76
    jp .L4A9B                   ; 4A78
.L4A7B:
    bit 6, a                    ; 4A7B
    jr nz, .L4A94               ; 4A7D
    and $3F                     ; 4A7F
    ld d, a                     ; 4A81
    cpl                         ; 4A82
    inc a                       ; 4A83
    ld c, a                     ; 4A84
    dec b                       ; 4A85
    add hl, bc                  ; 4A86
    add hl, bc                  ; 4A87
    add hl, bc                  ; 4A88
    inc b                       ; 4A89
    ld a, [wCh3_PLSteps]        ; 4A8A
    ld c, d                     ; 4A8D
    add a,c                     ; 4A8E
    ld [wCh3_PLSteps], a        ; 4A8F
    jr .L4A9B                   ; 4A92
.L4A94:
    ld a, [wWave_SweepOn]       ; 4A94
    cpl                         ; 4A97
    ld [wWave_SweepOn], a       ; 4A98
.L4A9B:
    ld a, l                     ; 4A9B
    ld [wCh3_PLPtrLo], a        ; 4A9C
    ld a, h                     ; 4A9F
    ld [wCh3_PLPtrHi], a        ; 4AA0
Tick_Ch3_PLWait:
    ld a, [wCh3_PLSpeed]        ; 4AA3
    res 7, a                    ; 4AA6
    ld [wCh3_PLTimer], a        ; 4AA8

;; Wave sweep: move the window position between the bounds.
Tick_Ch3_Sweep:
    ld hl, wCh3_PLTimer         ; 4AAB
    dec [hl]                    ; 4AAE
    ld a, [wWave_SweepOn]       ; 4AAF
    or a                        ; 4AB2
    jp z, Tick_Ch3_WaveRAM      ; 4AB3
    ld a, [wWave_SweepTimer]    ; 4AB6
    or a                        ; 4AB9
    jp nz, .L4B11               ; 4ABA
    ld a, [wWave_PosHi]         ; 4ABD
    ld h, a                     ; 4AC0
    ld a, [wWave_PosLo]         ; 4AC1
    ld l, a                     ; 4AC4
    ld a, [wWave_Step]          ; 4AC5
    ld c, a                     ; 4AC8
    bit 7, c                    ; 4AC9
    jr z, .L4AEC                ; 4ACB
    dec b                       ; 4ACD
    add hl, bc                  ; 4ACE
    inc b                       ; 4ACF
    ld a, h                     ; 4AD0
    ld [wWave_PosHi], a         ; 4AD1
    ld a, l                     ; 4AD4
    ld [wWave_PosLo], a         ; 4AD5
    ld a, [wWave_LowerLo]       ; 4AD8
    cp l                        ; 4ADB
    jr nz, .L4AEA               ; 4ADC
    ld a, [wWave_LowerHi]       ; 4ADE
    cp h                        ; 4AE1
    jr nz, .L4AEA               ; 4AE2
    ld a, c                     ; 4AE4
    cpl                         ; 4AE5
    inc a                       ; 4AE6
    ld [wWave_Step], a          ; 4AE7
.L4AEA:
    jr .L4B07                   ; 4AEA
.L4AEC:
    add hl, bc                  ; 4AEC
    ld a, h                     ; 4AED
    ld [wWave_PosHi], a         ; 4AEE
    ld a, l                     ; 4AF1
    ld [wWave_PosLo], a         ; 4AF2
    ld a, [wWave_UpperLo]       ; 4AF5
    cp l                        ; 4AF8
    jr nz, .L4B07               ; 4AF9
    ld a, [wWave_UpperHi]       ; 4AFB
    cp h                        ; 4AFE
    jr nz, .L4B07               ; 4AFF
    ld a, c                     ; 4B01
    cpl                         ; 4B02
    inc a                       ; 4B03
    ld [wWave_Step], a          ; 4B04
.L4B07:
    ld hl, wWave_WaveUpdate     ; 4B07
    dec [hl]                    ; 4B0A
    ld a, [wWave_SweepSpeed]    ; 4B0B
    ld [wWave_SweepTimer], a    ; 4B0E
.L4B11:
    ld hl, wWave_SweepTimer     ; 4B11
    dec [hl]                    ; 4B14

;; wWave_Update = $FF: copy 16 bytes from base+position into wave RAM.
Tick_Ch3_WaveRAM:
    ld a, [wWave_WaveUpdate]    ; 4B15
    inc a                       ; 4B18
    jp nz, Tick_Ch3_Pitch       ; 4B19
    ld [wWave_WaveUpdate], a    ; 4B1C
    ld a, [wWave_BaseLo]        ; 4B1F
    ld c, a                     ; 4B22
    ld a, [wWave_PosLo]         ; 4B23
    add a,c                     ; 4B26
    ld e, a                     ; 4B27
    ld a, [wWave_BaseHi]        ; 4B28
    ld c, a                     ; 4B2B
    ld a, [wWave_PosHi]         ; 4B2C
    adc a,c                     ; 4B2F
    ld d, a                     ; 4B30
    ld hl, _AUD3WAVERAM         ; 4B31
    xor a                       ; 4B34
    ldh [rNR30], a              ; 4B35
    ld a, [de]                  ; 4B37
    inc de                      ; 4B38
    ld [hl+], a                 ; 4B39
    ld a, [de]                  ; 4B3A
    inc de                      ; 4B3B
    ld [hl+], a                 ; 4B3C
    ld a, [de]                  ; 4B3D
    inc de                      ; 4B3E
    ld [hl+], a                 ; 4B3F
    ld a, [de]                  ; 4B40
    inc de                      ; 4B41
    ld [hl+], a                 ; 4B42
    ld a, [de]                  ; 4B43
    inc de                      ; 4B44
    ld [hl+], a                 ; 4B45
    ld a, [de]                  ; 4B46
    inc de                      ; 4B47
    ld [hl+], a                 ; 4B48
    ld a, [de]                  ; 4B49
    inc de                      ; 4B4A
    ld [hl+], a                 ; 4B4B
    ld a, [de]                  ; 4B4C
    inc de                      ; 4B4D
    ld [hl+], a                 ; 4B4E
    ld a, [de]                  ; 4B4F
    inc de                      ; 4B50
    ld [hl+], a                 ; 4B51
    ld a, [de]                  ; 4B52
    inc de                      ; 4B53
    ld [hl+], a                 ; 4B54
    ld a, [de]                  ; 4B55
    inc de                      ; 4B56
    ld [hl+], a                 ; 4B57
    ld a, [de]                  ; 4B58
    inc de                      ; 4B59
    ld [hl+], a                 ; 4B5A
    ld a, [de]                  ; 4B5B
    inc de                      ; 4B5C
    ld [hl+], a                 ; 4B5D
    ld a, [de]                  ; 4B5E
    inc de                      ; 4B5F
    ld [hl+], a                 ; 4B60
    ld a, [de]                  ; 4B61
    inc de                      ; 4B62
    ld [hl+], a                 ; 4B63
    ld a, [de]                  ; 4B64
    inc de                      ; 4B65
    ld [hl+], a                 ; 4B66
    ld a, $80                   ; 4B67
    ldh [rNR30], a              ; 4B69
    ld hl, rNR34                ; 4B6B
    set 7, [hl]                 ; 4B6E
    xor a                       ; 4B70
    ldh [rNR31], a              ; 4B71
Tick_Ch3_Pitch:
    xor a                       ; 4B73
    ldh [rNR31], a              ; 4B74
    ld a, [wCh3_PLNote]         ; 4B76
    ld c, a                     ; 4B79
    ld a, [wCh3_PLNoteRaw]      ; 4B7A
    bit 6, a                    ; 4B7D
    jr nz, .L4B8C               ; 4B7F
    ld a, [wCh3_Transpose]      ; 4B81
    add a,c                     ; 4B84
    ld c, a                     ; 4B85
    ld a, [wCh3_Note]           ; 4B86
    add a,c                     ; 4B89
    dec a                       ; 4B8A
    ld c, a                     ; 4B8B
.L4B8C:
    ld hl, FreqTable            ; 4B8C
    add hl, bc                  ; 4B8F
    add hl, bc                  ; 4B90
    ld c, $00                   ; 4B91
    ld a, [wCh3_VibDepth]       ; 4B93
    or a                        ; 4B96
    jr z, .L4BCA                ; 4B97
    ld a, [wCh3_VibDelay]       ; 4B99
    dec a                       ; 4B9C
    cp $FF                      ; 4B9D
    jr z, .L4BA6                ; 4B9F
    ld [wCh3_VibDelay], a       ; 4BA1
    jr .L4BCA                   ; 4BA4
.L4BA6:
    ld a, [wCh3_VibSpeed]       ; 4BA6
    ld c, a                     ; 4BA9
    ld a, [wCh3_VibPhase]       ; 4BAA
    add a,c                     ; 4BAD
    and $3F                     ; 4BAE
    ld [wCh3_VibPhase], a       ; 4BB0
    srl a                       ; 4BB3
    srl a                       ; 4BB5
    ld c, a                     ; 4BB7
    ld a, [wCh3_VibDepth]       ; 4BB8
    or c                        ; 4BBB
    ld c, a                     ; 4BBC
    push hl                     ; 4BBD
    ld hl, VibratoTable         ; 4BBE
    add hl, bc                  ; 4BC1
    ld a, [hl]                  ; 4BC2
    pop hl                      ; 4BC3
    ld c, a                     ; 4BC4
    bit 7, a                    ; 4BC5
    jr z, .L4BCA                ; 4BC7
    dec b                       ; 4BC9
.L4BCA:
    ld a, [hl+]                 ; 4BCA
    ld e, a                     ; 4BCB
    ld a, [hl]                  ; 4BCC
    ld h, a                     ; 4BCD
    ld l, e                     ; 4BCE
    add hl, bc                  ; 4BCF
    ld b, $00                   ; 4BD0
    ld a, l                     ; 4BD2
    ldh [rNR33], a              ; 4BD3
    ld a, h                     ; 4BD5
    ldh [rNR34], a              ; 4BD6
    xor a                       ; 4BD8
    ldh [rNR31], a              ; 4BD9

;; Channel 4 tick: NR43 = NoiseTable[(note + PLnote - 2) / 2].
Tick_Ch4:
    ld a, [wCh4_SFXTimer]       ; 4BDB
    or a                        ; 4BDE
    jr z, .L4BE5                ; 4BDF
    dec a                       ; 4BE1
    ld [wCh4_SFXTimer], a       ; 4BE2
.L4BE5:
    ld a, [wCh4_PLTimer]        ; 4BE5
    or a                        ; 4BE8
    jp nz, Tick_Ch4_Noise       ; 4BE9
    ld a, [wCh4_PLSteps]        ; 4BEC
    or a                        ; 4BEF
    jp z, Tick_Ch4_PLWait       ; 4BF0
    dec a                       ; 4BF3
    ld [wCh4_PLSteps], a        ; 4BF4
    ld a, [wCh4_PLPtrLo]        ; 4BF7
    ld l, a                     ; 4BFA
    ld a, [wCh4_PLPtrHi]        ; 4BFB
    ld h, a                     ; 4BFE
    ld a, [hl+]                 ; 4BFF
    ld [wCh4_PLNoteRaw], a      ; 4C00
    and $3F                     ; 4C03
    jr z, .L4C0A                ; 4C05
    ld [wCh4_PLNote], a         ; 4C07
.L4C0A:
    ld a, [hl+]                 ; 4C0A
    bit 7, a                    ; 4C0B
    jr nz, .L4C4B               ; 4C0D
    bit 6, a                    ; 4C0F
    jr nz, .L4C1D               ; 4C11
    and $3F                     ; 4C13
    jr z, .L4C1A                ; 4C15
    ld [wCh4_PLSpeed], a        ; 4C17
.L4C1A:
    jp .L4C64                   ; 4C1A
.L4C1D:
    swap a                      ; 4C1D
    ld d, a                     ; 4C1F
    ld a, [wCh4_VolShift]       ; 4C20
    ld c, a                     ; 4C23
    ld a, d                     ; 4C24
    inc c                       ; 4C25
    dec c                       ; 4C26
    jr z, .L4C37                ; 4C27
    dec c                       ; 4C29
    jr z, .L4C35                ; 4C2A
    dec c                       ; 4C2C
    jr z, .L4C33                ; 4C2D
    srl a                       ; 4C2F
    srl a                       ; 4C31
.L4C33:
    srl a                       ; 4C33
.L4C35:
    srl a                       ; 4C35
.L4C37:
    and $F0                     ; 4C37
    ld c, a                     ; 4C39
    ldh a, [rNR42]              ; 4C3A
    and $0F                     ; 4C3C
    or c                        ; 4C3E
    ldh [rNR42], a              ; 4C3F
    push hl                     ; 4C41
    ld hl, rNR44                ; 4C42
    set 7, [hl]                 ; 4C45
    pop hl                      ; 4C47
    jp .L4C64                   ; 4C48
.L4C4B:
    bit 6, a                    ; 4C4B
    jr nz, .L4C64               ; 4C4D
    and $3F                     ; 4C4F
    ld d, a                     ; 4C51
    cpl                         ; 4C52
    inc a                       ; 4C53
    ld c, a                     ; 4C54
    dec b                       ; 4C55
    add hl, bc                  ; 4C56
    add hl, bc                  ; 4C57
    add hl, bc                  ; 4C58
    inc b                       ; 4C59
    ld a, [wCh4_PLSteps]        ; 4C5A
    ld c, d                     ; 4C5D
    add a,c                     ; 4C5E
    ld [wCh4_PLSteps], a        ; 4C5F
    jr .L4C64                   ; 4C62
.L4C64:
    ld a, [hl+]                 ; 4C64
    bit 7, a                    ; 4C65
    jr nz, .L4CA5               ; 4C67
    bit 6, a                    ; 4C69
    jr nz, .L4C77               ; 4C6B
    and $3F                     ; 4C6D
    jr z, .L4C74                ; 4C6F
    ld [wCh4_PLSpeed], a        ; 4C71
.L4C74:
    jp .L4CBE                   ; 4C74
.L4C77:
    swap a                      ; 4C77
    ld d, a                     ; 4C79
    ld a, [wCh4_VolShift]       ; 4C7A
    ld c, a                     ; 4C7D
    ld a, d                     ; 4C7E
    inc c                       ; 4C7F
    dec c                       ; 4C80
    jr z, .L4C91                ; 4C81
    dec c                       ; 4C83
    jr z, .L4C8F                ; 4C84
    dec c                       ; 4C86
    jr z, .L4C8D                ; 4C87
    srl a                       ; 4C89
    srl a                       ; 4C8B
.L4C8D:
    srl a                       ; 4C8D
.L4C8F:
    srl a                       ; 4C8F
.L4C91:
    and $F0                     ; 4C91
    ld c, a                     ; 4C93
    ldh a, [rNR42]              ; 4C94
    and $0F                     ; 4C96
    or c                        ; 4C98
    ldh [rNR42], a              ; 4C99
    push hl                     ; 4C9B
    ld hl, rNR44                ; 4C9C
    set 7, [hl]                 ; 4C9F
    pop hl                      ; 4CA1
    jp .L4CBE                   ; 4CA2
.L4CA5:
    bit 6, a                    ; 4CA5
    jr nz, .L4CBE               ; 4CA7
    and $3F                     ; 4CA9
    ld d, a                     ; 4CAB
    cpl                         ; 4CAC
    inc a                       ; 4CAD
    ld c, a                     ; 4CAE
    dec b                       ; 4CAF
    add hl, bc                  ; 4CB0
    add hl, bc                  ; 4CB1
    add hl, bc                  ; 4CB2
    inc b                       ; 4CB3
    ld a, [wCh4_PLSteps]        ; 4CB4
    ld c, d                     ; 4CB7
    add a,c                     ; 4CB8
    ld [wCh4_PLSteps], a        ; 4CB9
    jr .L4CBE                   ; 4CBC
.L4CBE:
    ld a, l                     ; 4CBE
    ld [wCh4_PLPtrLo], a        ; 4CBF
    ld a, h                     ; 4CC2
    ld [wCh4_PLPtrHi], a        ; 4CC3
Tick_Ch4_PLWait:
    ld a, [wCh4_PLSpeed]        ; 4CC6
    res 7, a                    ; 4CC9
    ld [wCh4_PLTimer], a        ; 4CCB
Tick_Ch4_Noise:
    ld hl, wCh4_PLTimer         ; 4CCE
    dec [hl]                    ; 4CD1
    ld a, [wCh4_PLNoteRaw]      ; 4CD2
    ld e, a                     ; 4CD5
    ld a, [wCh4_PLNote]         ; 4CD6
    bit 6, e                    ; 4CD9
    jr nz, .L4CE3               ; 4CDB
    ld c, a                     ; 4CDD
    ld a, [wCh4_Note]           ; 4CDE
    add a,c                     ; 4CE1
    dec a                       ; 4CE2
.L4CE3:
    dec a                       ; 4CE3
    srl a                       ; 4CE4
    ld c, a                     ; 4CE6
    ld hl, NoiseTable           ; 4CE7
    add hl, bc                  ; 4CEA
    ld a, [hl]                  ; 4CEB
    ldh [rNR43], a              ; 4CEC
    ret                         ; 4CEE

;; GHX_PlaySFX: A = effect. SFXTable entry (5 bytes) = [ins ch1 | bit 7: record
;; this SFX in wSFX_Ch3Owner] [ins ch2] [ins ch3] [ins ch4] [time]. Instruments are 1-based
;; indices into SFXInstTable (0 = channel unused); the music on a used channel
;; is muted for "time" ticks.
PlaySFX:
    ld c, a                     ; 4CEF
    ld e, a                     ; 4CF0
    add a,a                     ; 4CF1
    add a,a                     ; 4CF2
    add a,c                     ; 4CF3
    ld c, a                     ; 4CF4
    ld a, $00                   ; 4CF5
    adc a,$00                   ; 4CF7
    ld b, a                     ; 4CF9
    ld hl, SFXTable             ; 4CFA
    add hl, bc                  ; 4CFD
    ld b, $00                   ; 4CFE
    ld a, [hl+]                 ; 4D00
    bit 7, a                    ; 4D01
    res 7, a                    ; 4D03
    push af                     ; 4D05
    ld [wSFX_Ch1], a            ; 4D06
    ld a, [hl+]                 ; 4D09
    ld [wSFX_Ch2], a            ; 4D0A
    ld a, [hl+]                 ; 4D0D
    or a                        ; 4D0E
    jr z, .L4D1C                ; 4D0F
    push af                     ; 4D11
    ld a, [wSFX_Ch3Owner]       ; 4D12
    or a                        ; 4D15
    jr z, .L4D1B                ; 4D16
    ld [wSFX_Ch3Prev], a        ; 4D18
.L4D1B:
    pop af                      ; 4D1B
.L4D1C:
    ld [wSFX_Ch3], a            ; 4D1C
    ld a, [hl+]                 ; 4D1F
    ld [wSFX_Ch4], a            ; 4D20
    ld a, [hl+]                 ; 4D23
    ld [wSFX_Time], a           ; 4D24
    pop af                      ; 4D27
    jr nz, .L4D2C               ; 4D28
    ld e, $00                   ; 4D2A
.L4D2C:
    ld a, [wSFX_Ch3]            ; 4D2C
    or a                        ; 4D2F
    jr z, PlaySFX_Ch1           ; 4D30
    ld a, e                     ; 4D32
    ld [wSFX_Ch3Owner], a       ; 4D33
PlaySFX_Ch1:
    ld a, [wSFX_Ch1]            ; 4D36
    or a                        ; 4D39
    jp z, PlaySFX_Ch2           ; 4D3A
    dec a                       ; 4D3D
    ld hl, SFXInstTable         ; 4D3E
    ld c, a                     ; 4D41
    add hl, bc                  ; 4D42
    add hl, bc                  ; 4D43
    ld a, [hl+]                 ; 4D44
    ld c, a                     ; 4D45
    ld a, [hl+]                 ; 4D46
    ld h, a                     ; 4D47
    ld l, c                     ; 4D48
    xor a                       ; 4D49
    ld [wCh1_VolShift], a       ; 4D4A
    ld a, [hl+]                 ; 4D4D
    ld [wCh1_InsFlags], a       ; 4D4E
    ld d, a                     ; 4D51
    ld a, [hl+]                 ; 4D52
    ld [wCh1_PLSpeed], a        ; 4D53
    xor a                       ; 4D56
    ld [wCh1_PLTimer], a        ; 4D57
    ld a, $80                   ; 4D5A
    ldh [rNR11], a              ; 4D5C
    ld a, [wCh1_VolShift]       ; 4D5E
    ld c, a                     ; 4D61
    ld a, [hl]                  ; 4D62
    and $0F                     ; 4D63
    ld e, a                     ; 4D65
    ld a, [hl+]                 ; 4D66
    inc c                       ; 4D67
    dec c                       ; 4D68
    jr z, .L4D79                ; 4D69
    dec c                       ; 4D6B
    jr z, .L4D77                ; 4D6C
    dec c                       ; 4D6E
    jr z, .L4D75                ; 4D6F
    srl a                       ; 4D71
    srl a                       ; 4D73
.L4D75:
    srl a                       ; 4D75
.L4D77:
    srl a                       ; 4D77
.L4D79:
    and $F0                     ; 4D79
    or e                        ; 4D7B
    ldh [rNR12], a              ; 4D7C
    ld a, [wCh1_PLSpeed]        ; 4D7E
    bit 7, a                    ; 4D81
    jr z, .L4D99                ; 4D83
    ld a, [hl+]                 ; 4D85
    ld [wCh1_VibDelay], a       ; 4D86
    ld a, [hl+]                 ; 4D89
    ld c, a                     ; 4D8A
    and $0F                     ; 4D8B
    ld [wCh1_VibSpeed], a       ; 4D8D
    ld a, c                     ; 4D90
    and $F0                     ; 4D91
    ld [wCh1_VibDepth], a       ; 4D93
    xor a                       ; 4D96
    jr .L4DA3                   ; 4D97
.L4D99:
    xor a                       ; 4D99
    ld [wCh1_VibDelay], a       ; 4D9A
    ld [wCh1_VibDepth], a       ; 4D9D
    ld [wCh1_VibSpeed], a       ; 4DA0
.L4DA3:
    ld [wCh1_VibPhase], a       ; 4DA3
    ld a, d                     ; 4DA6
    and $3F                     ; 4DA7
    ld [wCh1_PLSteps], a        ; 4DA9
    ld a, l                     ; 4DAC
    ld [wCh1_PLPtrLo], a        ; 4DAD
    ld a, h                     ; 4DB0
    ld [wCh1_PLPtrHi], a        ; 4DB1
    ld hl, rNR14                ; 4DB4
    set 7, [hl]                 ; 4DB7
    ld a, [wSFX_Time]           ; 4DB9
    ld [wCh1_SFXTimer], a       ; 4DBC
PlaySFX_Ch2:
    ld a, [wSFX_Ch2]            ; 4DBF
    or a                        ; 4DC2
    jp z, PlaySFX_Ch3           ; 4DC3
    dec a                       ; 4DC6
    ld hl, SFXInstTable         ; 4DC7
    ld c, a                     ; 4DCA
    add hl, bc                  ; 4DCB
    add hl, bc                  ; 4DCC
    ld a, [hl+]                 ; 4DCD
    ld c, a                     ; 4DCE
    ld a, [hl+]                 ; 4DCF
    ld h, a                     ; 4DD0
    ld l, c                     ; 4DD1
    xor a                       ; 4DD2
    ld [wCh2_VolShift], a       ; 4DD3
    ld a, [hl+]                 ; 4DD6
    ld [wCh2_InsFlags], a       ; 4DD7
    ld d, a                     ; 4DDA
    ld a, [hl+]                 ; 4DDB
    ld [wCh2_PLSpeed], a        ; 4DDC
    xor a                       ; 4DDF
    ld [wCh2_PLTimer], a        ; 4DE0
    ld a, $80                   ; 4DE3
    ldh [rNR21], a              ; 4DE5
    ld a, [wCh2_VolShift]       ; 4DE7
    ld c, a                     ; 4DEA
    ld a, [hl]                  ; 4DEB
    and $0F                     ; 4DEC
    ld e, a                     ; 4DEE
    ld a, [hl+]                 ; 4DEF
    inc c                       ; 4DF0
    dec c                       ; 4DF1
    jr z, .L4E02                ; 4DF2
    dec c                       ; 4DF4
    jr z, .L4E00                ; 4DF5
    dec c                       ; 4DF7
    jr z, .L4DFE                ; 4DF8
    srl a                       ; 4DFA
    srl a                       ; 4DFC
.L4DFE:
    srl a                       ; 4DFE
.L4E00:
    srl a                       ; 4E00
.L4E02:
    and $F0                     ; 4E02
    or e                        ; 4E04
    ldh [rNR22], a              ; 4E05
    ld a, [wCh2_PLSpeed]        ; 4E07
    bit 7, a                    ; 4E0A
    jr z, .L4E22                ; 4E0C
    ld a, [hl+]                 ; 4E0E
    ld [wCh2_VibDelay], a       ; 4E0F
    ld a, [hl+]                 ; 4E12
    ld c, a                     ; 4E13
    and $0F                     ; 4E14
    ld [wCh2_VibSpeed], a       ; 4E16
    ld a, c                     ; 4E19
    and $F0                     ; 4E1A
    ld [wCh2_VibDepth], a       ; 4E1C
    xor a                       ; 4E1F
    jr .L4E2C                   ; 4E20
.L4E22:
    xor a                       ; 4E22
    ld [wCh2_VibDelay], a       ; 4E23
    ld [wCh2_VibDepth], a       ; 4E26
    ld [wCh2_VibSpeed], a       ; 4E29
.L4E2C:
    ld [wCh2_VibPhase], a       ; 4E2C
    ld a, d                     ; 4E2F
    and $3F                     ; 4E30
    ld [wCh2_PLSteps], a        ; 4E32
    ld a, l                     ; 4E35
    ld [wCh2_PLPtrLo], a        ; 4E36
    ld a, h                     ; 4E39
    ld [wCh2_PLPtrHi], a        ; 4E3A
    ld hl, rNR24                ; 4E3D
    set 7, [hl]                 ; 4E40
    ld a, [wSFX_Time]           ; 4E42
    ld [wCh2_SFXTimer], a       ; 4E45
PlaySFX_Ch3:
    ld a, [wSFX_Ch3]            ; 4E48
    or a                        ; 4E4B
    jp z, PlaySFX_Ch4           ; 4E4C
    dec a                       ; 4E4F
    ld hl, SFXInstTable         ; 4E50
    ld c, a                     ; 4E53
    add hl, bc                  ; 4E54
    add hl, bc                  ; 4E55
    ld a, [hl+]                 ; 4E56
    ld c, a                     ; 4E57
    ld a, [hl+]                 ; 4E58
    ld h, a                     ; 4E59
    ld l, c                     ; 4E5A
    ld a, [hl+]                 ; 4E5B
    ld [wCh3_InsFlags], a       ; 4E5C
    ld d, a                     ; 4E5F
    and $C0                     ; 4E60
    ld [wWave_PCMFlag], a       ; 4E62
    ldh a, [rIE]                ; 4E65
    and $FB                     ; 4E67
    ldh [rIE], a                ; 4E69
    ld a, [hl+]                 ; 4E6B
    ld [wCh3_PLSpeed], a        ; 4E6C
    xor a                       ; 4E6F
    ld [wCh3_PLTimer], a        ; 4E70
    ld a, [wCh3_VolShift]       ; 4E73
    or a                        ; 4E76
    jr z, .L4E7C                ; 4E77
    inc hl                      ; 4E79
    jr .L4E82                   ; 4E7A
.L4E7C:
    ld a, [hl+]                 ; 4E7C
    ld [wCh3_Level], a          ; 4E7D
    and $FE                     ; 4E80
.L4E82:
    ldh [rNR32], a              ; 4E82
    xor a                       ; 4E84
    ld [wCh3_VolShift], a       ; 4E85
    ld a, [wCh3_PLSpeed]        ; 4E88
    bit 7, a                    ; 4E8B
    jr z, .L4EA3                ; 4E8D
    ld a, [hl+]                 ; 4E8F
    ld [wCh3_VibDelay], a       ; 4E90
    ld a, [hl+]                 ; 4E93
    ld c, a                     ; 4E94
    and $0F                     ; 4E95
    ld [wCh3_VibSpeed], a       ; 4E97
    ld a, c                     ; 4E9A
    and $F0                     ; 4E9B
    ld [wCh3_VibDepth], a       ; 4E9D
    xor a                       ; 4EA0
    jr .L4EAD                   ; 4EA1
.L4EA3:
    xor a                       ; 4EA3
    ld [wCh3_VibDelay], a       ; 4EA4
    ld [wCh3_VibDepth], a       ; 4EA7
    ld [wCh3_VibSpeed], a       ; 4EAA
.L4EAD:
    ld [wCh3_VibPhase], a       ; 4EAD
    ld a, [hl+]                 ; 4EB0
    ld [wWave_Step], a          ; 4EB1
    xor a                       ; 4EB4
    ld [wWave_SweepOn], a       ; 4EB5
    ld [wWave_FlagHi], a        ; 4EB8
    ld a, [hl+]                 ; 4EBB
    bit 7, a                    ; 4EBC
    jr z, .L4EC3                ; 4EBE
    ld [wWave_FlagHi], a        ; 4EC0
.L4EC3:
    and $7F                     ; 4EC3
    ld [wWave_FlagLo], a        ; 4EC5
    ld a, [hl+]                 ; 4EC8
    ld [wWave_PosLo], a         ; 4EC9
    ld a, [hl+]                 ; 4ECC
    ld [wWave_PosHi], a         ; 4ECD
    ld a, [hl+]                 ; 4ED0
    ld [wWave_LowerLo], a       ; 4ED1
    ld a, [hl+]                 ; 4ED4
    ld [wWave_LowerHi], a       ; 4ED5
    ld a, [hl+]                 ; 4ED8
    ld [wWave_UpperLo], a       ; 4ED9
    ld a, [hl+]                 ; 4EDC
    ld [wWave_UpperHi], a       ; 4EDD
    ld a, [hl+]                 ; 4EE0
    ld [wWave_SweepSpeed], a    ; 4EE1
    ld [wWave_SweepTimer], a    ; 4EE4
    ld a, [hl+]                 ; 4EE7
    ld [wWave_BaseLo], a        ; 4EE8
    ld a, [hl+]                 ; 4EEB
    ld [wWave_BaseHi], a        ; 4EEC
    ld a, d                     ; 4EEF
    and $3F                     ; 4EF0
    ld [wCh3_PLSteps], a        ; 4EF2
    ld a, l                     ; 4EF5
    ld [wCh3_PLPtrLo], a        ; 4EF6
    ld a, h                     ; 4EF9
    ld [wCh3_PLPtrHi], a        ; 4EFA
    ld a, $FF                   ; 4EFD
    ld [wWave_WaveUpdate], a    ; 4EFF
    ld a, [wSFX_Time]           ; 4F02
    ld [wCh3_SFXTimer], a       ; 4F05
PlaySFX_Ch4:
    ld a, [wSFX_Ch4]            ; 4F08
    or a                        ; 4F0B
    jr z, .L4F68                ; 4F0C
    dec a                       ; 4F0E
    ld hl, SFXInstTable         ; 4F0F
    ld c, a                     ; 4F12
    add hl, bc                  ; 4F13
    add hl, bc                  ; 4F14
    ld a, [hl+]                 ; 4F15
    ld c, a                     ; 4F16
    ld a, [hl+]                 ; 4F17
    ld h, a                     ; 4F18
    ld l, c                     ; 4F19
    xor a                       ; 4F1A
    ld [wCh4_VolShift], a       ; 4F1B
    ld a, [hl+]                 ; 4F1E
    ld [wCh4_InsFlags], a       ; 4F1F
    ld d, a                     ; 4F22
    ld a, [hl+]                 ; 4F23
    ld [wCh4_PLSpeed], a        ; 4F24
    xor a                       ; 4F27
    ld [wCh4_PLTimer], a        ; 4F28
    ld a, $00                   ; 4F2B
    ldh [rNR41], a              ; 4F2D
    ld a, [wCh4_VolShift]       ; 4F2F
    ld c, a                     ; 4F32
    ld a, [hl]                  ; 4F33
    and $0F                     ; 4F34
    ld e, a                     ; 4F36
    ld a, [hl+]                 ; 4F37
    inc c                       ; 4F38
    dec c                       ; 4F39
    jr z, .L4F4A                ; 4F3A
    dec c                       ; 4F3C
    jr z, .L4F48                ; 4F3D
    dec c                       ; 4F3F
    jr z, .L4F46                ; 4F40
    srl a                       ; 4F42
    srl a                       ; 4F44
.L4F46:
    srl a                       ; 4F46
.L4F48:
    srl a                       ; 4F48
.L4F4A:
    and $F0                     ; 4F4A
    or e                        ; 4F4C
    ldh [rNR42], a              ; 4F4D
    ld a, d                     ; 4F4F
    and $3F                     ; 4F50
    ld [wCh4_PLSteps], a        ; 4F52
    ld a, l                     ; 4F55
    ld [wCh4_PLPtrLo], a        ; 4F56
    ld a, h                     ; 4F59
    ld [wCh4_PLPtrHi], a        ; 4F5A
    ld hl, rNR44                ; 4F5D
    set 7, [hl]                 ; 4F60
    ld a, [wSFX_Time]           ; 4F62
    ld [wCh4_SFXTimer], a       ; 4F65
.L4F68:
    ret                         ; 4F68

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
    db $90, $57, $63, $63, $55, $55, $80, $47, $53, $53; 4FFB 
    db $45, $45, $70, $37, $43, $43, $35, $35, $60, $27; 5005 
    db $33, $33, $25, $25, $50, $17, $23, $23, $15, $15; 500F 

;; 16 depths x 16 phases, signed frequency offsets.
VibratoTable:
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00; 5019 
    db $00, $00, $00, $00, $01, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF; 5029 
    db $00, $00, $01, $01, $02, $01, $01, $00, $00, $FF, $FE, $FE, $FE, $FE, $FE, $FF; 5039 
    db $00, $01, $02, $02, $03, $02, $02, $01, $00, $FE, $FD, $FD, $FD, $FD, $FD, $FE; 5049 
    db $00, $01, $02, $03, $04, $03, $02, $01, $00, $FE, $FD, $FC, $FC, $FC, $FD, $FE; 5059 
    db $00, $01, $03, $04, $05, $04, $03, $01, $00, $FE, $FC, $FB, $FB, $FB, $FC, $FE; 5069 
    db $00, $02, $04, $05, $06, $05, $04, $02, $00, $FD, $FB, $FA, $FA, $FA, $FB, $FD; 5079 
    db $00, $02, $04, $06, $07, $06, $04, $02, $00, $FD, $FB, $F9, $F9, $F9, $FB, $FD; 5089 
    db $00, $03, $05, $07, $08, $07, $05, $03, $00, $FC, $FA, $F8, $F8, $F8, $FA, $FC; 5099 
    db $00, $03, $06, $08, $09, $08, $06, $03, $00, $FC, $F9, $F7, $F7, $F7, $F9, $FC; 50A9 
    db $00, $03, $07, $09, $0A, $09, $07, $03, $00, $FC, $F8, $F6, $F6, $F6, $F8, $FC; 50B9 
    db $00, $04, $07, $0A, $0B, $0A, $07, $04, $00, $FB, $F8, $F5, $F5, $F5, $F8, $FB; 50C9 
    db $00, $04, $08, $0B, $0C, $0B, $08, $04, $00, $FB, $F7, $F4, $F4, $F4, $F7, $FB; 50D9 
    db $00, $04, $09, $0C, $0D, $0C, $09, $04, $00, $FB, $F6, $F3, $F3, $F3, $F6, $FB; 50E9 
    db $00, $05, $09, $0C, $0E, $0C, $09, $05, $00, $FA, $F6, $F3, $F2, $F3, $F6, $FA; 50F9 
    db $00, $05, $0A, $0D, $0F, $0D, $0A, $05, $00, $FA, $F5, $F2, $F1, $F2, $F5, $FA; 5109 
SongTable:
    dw Song0_Header                              ; 5119  song 0

;; Song header (12 bytes, copied to wHdr_* by GHX_Init).
Song0_Header:
    db "GHX"                                     ; 511B magic
    db 10                                        ; subsongs
    db 32                                        ; rows per pattern
    db $00                                       ; (unused)
    dw Song0_Tracks                              ; track pointer table (not used by this build)
    dw Song0_Instruments                         ; instrument pointer table
    dw Song0_Orders                              ; order table

;; Order table: two entries per subsong (intro, loop) = [count] [dw positions];
;; count+1 positions are played. After the intro the loop entry repeats forever.
Song0_Orders:
    db 20 
    dw Song0_Pos000                          ; 5127 subsong 0 intro (21 positions)
    db 20 
    dw Song0_Pos000                          ; 512A subsong 0 loop  (21 positions)
    db 9  
    dw Song0_Pos021                          ; 512D subsong 1 intro (10 positions)
    db 9  
    dw Song0_Pos021                          ; 5130 subsong 1 loop  (10 positions)
    db 10 
    dw Song0_Pos031                          ; 5133 subsong 2 intro (11 positions)
    db 10 
    dw Song0_Pos031                          ; 5136 subsong 2 loop  (11 positions)
    db 0  
    dw Song0_Pos042                          ; 5139 subsong 3 intro (1 positions)
    db 42 
    dw Song0_Pos000                          ; 513C subsong 3 loop  (43 positions)
    db 1  
    dw Song0_Pos043                          ; 513F subsong 4 intro (2 positions)
    db 44 
    dw Song0_Pos000                          ; 5142 subsong 4 loop  (45 positions)
    db 1  
    dw Song0_Pos045                          ; 5145 subsong 5 intro (2 positions)
    db 46 
    dw Song0_Pos000                          ; 5148 subsong 5 loop  (47 positions)
    db 2  
    dw Song0_Pos047                          ; 514B subsong 6 intro (3 positions)
    db 49 
    dw Song0_Pos000                          ; 514E subsong 6 loop  (50 positions)
    db 1  
    dw Song0_Pos050                          ; 5151 subsong 7 intro (2 positions)
    db 51 
    dw Song0_Pos000                          ; 5154 subsong 7 loop  (52 positions)
    db 3  
    dw Song0_Pos052                          ; 5157 subsong 8 intro (4 positions)
    db 55 
    dw Song0_Pos000                          ; 515A subsong 8 loop  (56 positions)
    db 0  
    dw Song0_Pos056                          ; 515D subsong 9 intro (1 positions)
    db 0  
    dw Song0_Pos056                          ; 5160 subsong 9 loop  (1 positions)

;; Positions (11 bytes): for ch1-ch3 [dw track] [transpose], then [dw track] for ch4.
Song0_Pos000:
    POS Track001, 0, Track002, 0, Track003, 0, Track000  ; 5163 pos 0
    POS Track001, 0, Track002, 0, Track003, 0, Track000  ; 516E pos 1
    POS Track004, 0, Track005, 0, Track003, 0, Track000  ; 5179 pos 2
    POS Track004, 0, Track005, 0, Track003, 0, Track000  ; 5184 pos 3
    POS Track024, 0, Track006, 0, Track008, 0, Track000  ; 518F pos 4
    POS Track009, 0, Track010, 0, Track014, 0, Track000  ; 519A pos 5
    POS Track024, 0, Track011, 0, Track008, 0, Track000  ; 51A5 pos 6
    POS Track009, 0, Track012, 0, Track014, 0, Track000  ; 51B0 pos 7
    POS Track024, 0, Track013, 0, Track008, 0, Track000  ; 51BB pos 8
    POS Track009, 0, Track010, 0, Track014, 0, Track000  ; 51C6 pos 9
    POS Track024, 0, Track011, 0, Track008, 0, Track000  ; 51D1 pos 10
    POS Track009, 0, Track012, 0, Track014, 0, Track000  ; 51DC pos 11
    POS Track007, 0, Track016, 0, Track018, 0, Track023  ; 51E7 pos 12
    POS Track020, 0, Track015, 0, Track018, 0, Track019  ; 51F2 pos 13
    POS Track022, 0, Track021, 0, Track018, 0, Track019  ; 51FD pos 14
    POS Track028, 0, Track027, 0, Track018, 0, Track029  ; 5208 pos 15
    POS Track025, 0, Track026, 0, Track018, 0, Track023  ; 5213 pos 16
    POS Track031, 0, Track030, 0, Track033, 0, Track032  ; 521E pos 17
    POS Track025, 0, Track037, 0, Track018, 0, Track023  ; 5229 pos 18
    POS Track031, 0, Track030, 0, Track033, 0, Track032  ; 5234 pos 19
    POS Track036, 0, Track035, 0, Track003, 0, Track034  ; 523F pos 20
Song0_Pos021:
    POS Track038, 0, Track040, 0, Track039, 0, Track044  ; 524A pos 21
    POS Track038, 0, Track040, 0, Track039, 0, Track044  ; 5255 pos 22
    POS Track043, 0, Track042, 0, Track041, 0, Track044  ; 5260 pos 23
    POS Track045, 0, Track040, 0, Track039, 0, Track044  ; 526B pos 24
    POS Track047, 0, Track040, 0, Track039, 0, Track044  ; 5276 pos 25
    POS Track046, 0, Track042, 0, Track041, 0, Track044  ; 5281 pos 26
    POS Track048, 0, Track040, 0, Track039, 0, Track044  ; 528C pos 27
    POS Track048, 0, Track040, 0, Track039, 0, Track044  ; 5297 pos 28
    POS Track048, 0, Track040, 12, Track039, 0, Track044  ; 52A2 pos 29
    POS Track048, 0, Track040, 12, Track039, 0, Track044  ; 52AD pos 30
Song0_Pos031:
    POS Track051, 0, Track049, 0, Track050, 0, Track052  ; 52B8 pos 31
    POS Track051, 0, Track049, 0, Track050, 0, Track052  ; 52C3 pos 32
    POS Track053, 0, Track049, 0, Track050, 0, Track052  ; 52CE pos 33
    POS Track053, 0, Track049, 0, Track050, 0, Track052  ; 52D9 pos 34
    POS Track053, 0, Track049, 0, Track054, 0, Track055  ; 52E4 pos 35
    POS Track053, 0, Track049, 0, Track056, 0, Track057  ; 52EF pos 36
    POS Track058, 0, Track060, 0, Track059, 0, Track055  ; 52FA pos 37
    POS Track061, 0, Track062, 0, Track059, 0, Track057  ; 5305 pos 38
    POS Track058, 0, Track060, 12, Track059, 0, Track055  ; 5310 pos 39
    POS Track063, 0, Track068, 12, Track066, 0, Track067  ; 531B pos 40
    POS Track064, 0, Track065, 0, Track008, -7, Track052  ; 5326 pos 41
Song0_Pos042:
    POS Track069, 0, Track070, 0, Track071, 0, Track072  ; 5331 pos 42
Song0_Pos043:
    POS Track073, 0, Track074, 0, Track075, 0, Track076  ; 533C pos 43
    POS Track077, 0, Track078, 0, Track079, 0, Track076  ; 5347 pos 44
Song0_Pos045:
    POS Track080, 0, Track081, 0, Track082, 0, Track083  ; 5352 pos 45
    POS Track084, 0, Track085, 0, Track086, 0, Track087  ; 535D pos 46
Song0_Pos047:
    POS Track088, 0, Track089, 0, Track093, 0, Track090  ; 5368 pos 47
    POS Track088, 0, Track089, 0, Track093, 0, Track090  ; 5373 pos 48
    POS Track091, 0, Track092, 0, Track094, 0, Track095  ; 537E pos 49
Song0_Pos050:
    POS Track096, 0, Track097, 0, Track098, 0, Track000  ; 5389 pos 50
    POS Track099, 0, Track100, 0, Track101, 0, Track000  ; 5394 pos 51
Song0_Pos052:
    POS Track105, 0, Track104, 0, Track102, 0, Track103  ; 539F pos 52
    POS Track105, 0, Track104, 0, Track102, 0, Track103  ; 53AA pos 53
    POS Track105, 0, Track104, 12, Track102, 0, Track103  ; 53B5 pos 54
    POS Track109, 12, Track106, 12, Track107, 0, Track108  ; 53C0 pos 55
Song0_Pos056:
    POS Track000, 0, Track000, 0, Track000, 0, Track000  ; 53CB pos 56
    POS Track000, 0, Track000, 0, Track000, 0, Track000  ; 53D6 pos 57

;; Track pointer table (left over from the converter: this build reads the track pointers straight from the positions)
Song0_Tracks:
    dw Track000                                  ; 53E1  track 0
    dw Track001                                  ; 53E3  track 1
    dw Track002                                  ; 53E5  track 2
    dw Track003                                  ; 53E7  track 3
    dw Track004                                  ; 53E9  track 4
    dw Track005                                  ; 53EB  track 5
    dw Track006                                  ; 53ED  track 6
    dw Track007                                  ; 53EF  track 7
    dw Track008                                  ; 53F1  track 8
    dw Track009                                  ; 53F3  track 9
    dw Track010                                  ; 53F5  track 10
    dw Track011                                  ; 53F7  track 11
    dw Track012                                  ; 53F9  track 12
    dw Track013                                  ; 53FB  track 13
    dw Track014                                  ; 53FD  track 14
    dw Track015                                  ; 53FF  track 15
    dw Track016                                  ; 5401  track 16
    dw Track017                                  ; 5403  track 17
    dw Track018                                  ; 5405  track 18
    dw Track019                                  ; 5407  track 19
    dw Track020                                  ; 5409  track 20
    dw Track021                                  ; 540B  track 21
    dw Track022                                  ; 540D  track 22
    dw Track023                                  ; 540F  track 23
    dw Track024                                  ; 5411  track 24
    dw Track025                                  ; 5413  track 25
    dw Track026                                  ; 5415  track 26
    dw Track027                                  ; 5417  track 27
    dw Track028                                  ; 5419  track 28
    dw Track029                                  ; 541B  track 29
    dw Track030                                  ; 541D  track 30
    dw Track031                                  ; 541F  track 31
    dw Track032                                  ; 5421  track 32
    dw Track033                                  ; 5423  track 33
    dw Track034                                  ; 5425  track 34
    dw Track035                                  ; 5427  track 35
    dw Track036                                  ; 5429  track 36
    dw Track037                                  ; 542B  track 37
    dw Track038                                  ; 542D  track 38
    dw Track039                                  ; 542F  track 39
    dw Track040                                  ; 5431  track 40
    dw Track041                                  ; 5433  track 41
    dw Track042                                  ; 5435  track 42
    dw Track043                                  ; 5437  track 43
    dw Track044                                  ; 5439  track 44
    dw Track045                                  ; 543B  track 45
    dw Track046                                  ; 543D  track 46
    dw Track047                                  ; 543F  track 47
    dw Track048                                  ; 5441  track 48
    dw Track049                                  ; 5443  track 49
    dw Track050                                  ; 5445  track 50
    dw Track051                                  ; 5447  track 51
    dw Track052                                  ; 5449  track 52
    dw Track053                                  ; 544B  track 53
    dw Track054                                  ; 544D  track 54
    dw Track055                                  ; 544F  track 55
    dw Track056                                  ; 5451  track 56
    dw Track057                                  ; 5453  track 57
    dw Track058                                  ; 5455  track 58
    dw Track059                                  ; 5457  track 59
    dw Track060                                  ; 5459  track 60
    dw Track061                                  ; 545B  track 61
    dw Track062                                  ; 545D  track 62
    dw Track063                                  ; 545F  track 63
    dw Track064                                  ; 5461  track 64
    dw Track065                                  ; 5463  track 65
    dw Track066                                  ; 5465  track 66
    dw Track067                                  ; 5467  track 67
    dw Track068                                  ; 5469  track 68
    dw Track069                                  ; 546B  track 69
    dw Track070                                  ; 546D  track 70
    dw Track071                                  ; 546F  track 71
    dw Track072                                  ; 5471  track 72
    dw Track073                                  ; 5473  track 73
    dw Track074                                  ; 5475  track 74
    dw Track075                                  ; 5477  track 75
    dw Track076                                  ; 5479  track 76
    dw Track077                                  ; 547B  track 77
    dw Track078                                  ; 547D  track 78
    dw Track079                                  ; 547F  track 79
    dw Track080                                  ; 5481  track 80
    dw Track081                                  ; 5483  track 81
    dw Track082                                  ; 5485  track 82
    dw Track083                                  ; 5487  track 83
    dw Track084                                  ; 5489  track 84
    dw Track085                                  ; 548B  track 85
    dw Track086                                  ; 548D  track 86
    dw Track087                                  ; 548F  track 87
    dw Track088                                  ; 5491  track 88
    dw Track089                                  ; 5493  track 89
    dw Track090                                  ; 5495  track 90
    dw Track091                                  ; 5497  track 91
    dw Track092                                  ; 5499  track 92
    dw Track093                                  ; 549B  track 93
    dw Track094                                  ; 549D  track 94
    dw Track095                                  ; 549F  track 95
    dw Track096                                  ; 54A1  track 96
    dw Track097                                  ; 54A3  track 97
    dw Track098                                  ; 54A5  track 98
    dw Track099                                  ; 54A7  track 99
    dw Track100                                  ; 54A9  track 100
    dw Track101                                  ; 54AB  track 101
    dw Track102                                  ; 54AD  track 102
    dw Track103                                  ; 54AF  track 103
    dw Track104                                  ; 54B1  track 104
    dw Track105                                  ; 54B3  track 105
    dw Track106                                  ; 54B5  track 106
    dw Track107                                  ; 54B7  track 107
    dw Track108                                  ; 54B9  track 108
    dw Track109                                  ; 54BB  track 109
Song0_Instruments:
    dw Inst00                                    ; 54BD  instrument 0 (ch1,ch2)
    dw Inst01                                    ; 54BF  instrument 1 (ch3)
    dw Inst02                                    ; 54C1  instrument 2 (ch1,ch2)
    dw Inst03                                    ; 54C3  instrument 3 (ch1,ch2)
    dw Inst04                                    ; 54C5  instrument 4 (ch2)
    dw Inst05                                    ; 54C7  instrument 5 (ch2)
    dw Inst06                                    ; 54C9  instrument 6 (ch2)
    dw Inst07                                    ; 54CB  instrument 7 (ch3)
    dw Inst08                                    ; 54CD  instrument 8 (ch4)
    dw Inst09                                    ; 54CF  instrument 9 (ch3)
    dw Inst10                                    ; 54D1  instrument 10 (ch4)
    dw Inst11                                    ; 54D3  instrument 11 (ch4)
    dw Inst12                                    ; 54D5  instrument 12 (unused)
    dw Inst13                                    ; 54D7  instrument 13 (ch1,ch2)
    dw Inst14                                    ; 54D9  instrument 14 (ch1,ch2)
    dw Inst15                                    ; 54DB  instrument 15 (ch1,ch2)
    dw Inst16                                    ; 54DD  instrument 16 (ch2)
    dw Inst17                                    ; 54DF  instrument 17 (ch2)
    dw Inst18                                    ; 54E1  instrument 18 (ch1)
    dw Inst19                                    ; 54E3  instrument 19 (ch2)
    dw Inst20                                    ; 54E5  instrument 20 (ch4)
    dw Inst21                                    ; 54E7  instrument 21 (ch4)
    dw Inst22                                    ; 54E9  instrument 22 (ch4)
    dw Inst23                                    ; 54EB  instrument 23 (ch2)
    dw Inst24                                    ; 54ED  instrument 24 (ch3)
    dw Inst25                                    ; 54EF  instrument 25 (ch2)
    dw Inst26                                    ; 54F1  instrument 26 (ch2)
    dw Inst27                                    ; 54F3  instrument 27 (ch2)
    dw Inst28                                    ; 54F5  instrument 28 (ch1)
    dw Inst29                                    ; 54F7  instrument 29 (ch2)
    dw Inst30                                    ; 54F9  instrument 30 (ch1,ch2)
    dw Inst31                                    ; 54FB  instrument 31 (unused)
Inst00:
    db $05                                       ; 54FD square, 5 steps
    db $05                                       ; playlist speed
    db $D3                                       ; NRx2 envelope
    db $01, $4F, $C0                             ; step 0: +0  vol 15, duty 0
    db $0D, $4F, $00                             ; step 1: +12  vol 15
    db $01, $00, $00                             ; step 2: +0
    db $0D, $00, $00                             ; step 3: +12
    db $01, $00, $82                             ; step 4: +0  jump -2
Inst01:
    db $03                                       ; 550F wave, 3 steps
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
    db $02                                       ; 5528 square, 2 steps
    db $81                                       ; playlist speed | $80 = vibrato
    db $09                                       ; NRx2 envelope
    db $20, $47                                  ; vibrato delay, depth<<4|speed
    db $01, $00, $C2                             ; step 0: +0  duty 2
    db $00, $C2, $81                             ; step 1: -  duty 2, jump -1
Inst03:
    db $0A                                       ; 5533 square, 10 steps
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
    db $04                                       ; 5556 square, 4 steps
    db $03                                       ; playlist speed
    db $C7                                       ; NRx2 envelope
    db $0D, $00, $C1                             ; step 0: +12  duty 1
    db $12, $00, $00                             ; step 1: +17
    db $14, $00, $83                             ; step 2: +19  jump -3
    db $00, $00, $00                             ; step 3: -
Inst05:
    db $04                                       ; 5565 square, 4 steps
    db $03                                       ; playlist speed
    db $C7                                       ; NRx2 envelope
    db $0D, $00, $C1                             ; step 0: +12  duty 1
    db $11, $00, $00                             ; step 1: +16
    db $14, $00, $83                             ; step 2: +19  jump -3
    db $00, $00, $00                             ; step 3: -
Inst06:
    db $04                                       ; 5574 square, 4 steps
    db $03                                       ; playlist speed
    db $C7                                       ; NRx2 envelope
    db $0C, $00, $C1                             ; step 0: +11  duty 1
    db $0F, $00, $00                             ; step 1: +14
    db $14, $00, $83                             ; step 2: +19  jump -3
    db $00, $00, $00                             ; step 3: -
Inst07:
    db $11                                       ; 5583 wave, 17 steps
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
    db $02                                       ; 55C4 noise, 2 steps
    db $02                                       ; playlist speed
    db $C2                                       ; NR42 envelope
    db $7A, $00, $00                             ; step 0: A-6
    db $59, $00, $82                             ; step 1: C-4  jump -2
Inst09:
    db $03                                       ; 55CD wave, 3 steps
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
    db $03                                       ; 55E6 noise, 3 steps
    db $01                                       ; playlist speed
    db $A1                                       ; NR42 envelope
    db $7A, $00, $00                             ; step 0: A-6
    db $59, $00, $00                             ; step 1: C-4
    db $00, $00, $40                             ; step 2: -  vol 0
Inst11:
    db $03                                       ; 55F2 noise, 3 steps
    db $01                                       ; playlist speed
    db $C5                                       ; NR42 envelope
    db $7A, $00, $00                             ; step 0: A-6
    db $59, $00, $00                             ; step 1: C-4
    db $00, $00, $83                             ; step 2: -  jump -3
Inst12:
    db $02                                       ; 55FE square, 2 steps
    db $81                                       ; playlist speed | $80 = vibrato
    db $D7                                       ; NRx2 envelope
    db $00, $47                                  ; vibrato delay, depth<<4|speed
    db $01, $00, $C2                             ; step 0: +0  duty 2
    db $00, $C2, $81                             ; step 1: -  duty 2, jump -1
Inst13:
    db $06                                       ; 5609 square, 6 steps
    db $03                                       ; playlist speed
    db $0F                                       ; NRx2 envelope
    db $0F, $00, $C1                             ; step 0: +14  duty 1
    db $14, $00, $00                             ; step 1: +19
    db $18, $00, $00                             ; step 2: +23
    db $1B, $00, $00                             ; step 3: +26
    db $18, $00, $00                             ; step 4: +23
    db $14, $00, $86                             ; step 5: +19  jump -6
Inst14:
    db $06                                       ; 561E square, 6 steps
    db $03                                       ; playlist speed
    db $F7                                       ; NRx2 envelope
    db $0F, $00, $C1                             ; step 0: +14  duty 1
    db $12, $00, $00                             ; step 1: +17
    db $16, $00, $00                             ; step 2: +21
    db $19, $00, $00                             ; step 3: +24
    db $16, $00, $00                             ; step 4: +21
    db $12, $00, $86                             ; step 5: +17  jump -6
Inst15:
    db $03                                       ; 5633 square, 3 steps
    db $85                                       ; playlist speed | $80 = vibrato
    db $F2                                       ; NRx2 envelope
    db $0B, $17                                  ; vibrato delay, depth<<4|speed
    db $01, $00, $C0                             ; step 0: +0  duty 0
    db $0D, $C2, $82                             ; step 1: +12  duty 2, jump -2
    db $00, $00, $00                             ; step 2: -
Inst16:
    db $06                                       ; 5641 square, 6 steps
    db $02                                       ; playlist speed
    db $D7                                       ; NRx2 envelope
    db $0D, $00, $C2                             ; step 0: +12  duty 2
    db $0F, $00, $00                             ; step 1: +14
    db $10, $00, $00                             ; step 2: +15
    db $14, $00, $84                             ; step 3: +19  jump -4
    db $00, $00, $00                             ; step 4: -
    db $00, $00, $00                             ; step 5: -
Inst17:
    db $06                                       ; 5656 square, 6 steps
    db $02                                       ; playlist speed
    db $D7                                       ; NRx2 envelope
    db $0D, $00, $C2                             ; step 0: +12  duty 2
    db $10, $00, $00                             ; step 1: +15
    db $15, $00, $00                             ; step 2: +20
    db $09, $00, $84                             ; step 3: +8  jump -4
    db $00, $00, $00                             ; step 4: -
    db $00, $00, $00                             ; step 5: -
Inst18:
    db $02                                       ; 566B square, 2 steps
    db $81                                       ; playlist speed | $80 = vibrato
    db $D0                                       ; NRx2 envelope
    db $20, $47                                  ; vibrato delay, depth<<4|speed
    db $01, $00, $C2                             ; step 0: +0  duty 2
    db $00, $C2, $81                             ; step 1: -  duty 2, jump -1
Inst19:
    db $06                                       ; 5676 square, 6 steps
    db $02                                       ; playlist speed
    db $D7                                       ; NRx2 envelope
    db $09, $00, $C2                             ; step 0: +8  duty 2
    db $0D, $00, $00                             ; step 1: +12
    db $10, $00, $00                             ; step 2: +15
    db $15, $00, $84                             ; step 3: +20  jump -4
    db $00, $00, $00                             ; step 4: -
    db $00, $00, $00                             ; step 5: -
Inst20:
    db $02                                       ; 568B noise, 2 steps
    db $05                                       ; playlist speed
    db $87                                       ; NR42 envelope
    db $01, $00, $00                             ; step 0: +0
    db $0D, $00, $82                             ; step 1: +12  jump -2
Inst21:
    db $02                                       ; 5694 noise, 2 steps
    db $0B                                       ; playlist speed
    db $80                                       ; NR42 envelope
    db $01, $00, $00                             ; step 0: +0
    db $00, $00, $44                             ; step 1: -  vol 4
Inst22:
    db $02                                       ; 569D noise, 2 steps
    db $05                                       ; playlist speed
    db $C7                                       ; NR42 envelope
    db $01, $00, $00                             ; step 0: +0
    db $0D, $00, $82                             ; step 1: +12  jump -2
Inst23:
    db $06                                       ; 56A6 square, 6 steps
    db $02                                       ; playlist speed
    db $D7                                       ; NRx2 envelope
    db $18, $00, $C2                             ; step 0: +23  duty 2
    db $1B, $00, $00                             ; step 1: +26
    db $1E, $00, $00                             ; step 2: +29
    db $24, $00, $84                             ; step 3: +35  jump -4
    db $00, $00, $00                             ; step 4: -
    db $00, $00, $00                             ; step 5: -
Inst24:
    db $01                                       ; 56BB wave, 1 steps
    db $81                                       ; playlist speed | $80 = vibrato
    db $00                                       ; NR32 level
    db $00, $48                                  ; vibrato delay, depth<<4|speed
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $000E, $0002, $0010                       ; position, lower bound, upper bound
    db $0A                                       ; sweep speed
    db LOW(WaveData00), HIGH(WaveData00)         ; wave data base
    db $01, $00, $00                             ; step 0: +0
Inst25:
    db $04                                       ; 56CE square, 4 steps
    db $02                                       ; playlist speed
    db $D7                                       ; NRx2 envelope
    db $0D, $00, $C1                             ; step 0: +12  duty 1
    db $10, $00, $C2                             ; step 1: +15  duty 2
    db $14, $C1, $83                             ; step 2: +19  duty 1, jump -3
    db $00, $00, $00                             ; step 3: -
Inst26:
    db $04                                       ; 56DD square, 4 steps
    db $02                                       ; playlist speed
    db $D7                                       ; NRx2 envelope
    db $0D, $00, $C1                             ; step 0: +12  duty 1
    db $0F, $00, $C2                             ; step 1: +14  duty 2
    db $14, $C1, $83                             ; step 2: +19  duty 1, jump -3
    db $00, $00, $00                             ; step 3: -
Inst27:
    db $04                                       ; 56EC square, 4 steps
    db $02                                       ; playlist speed
    db $D7                                       ; NRx2 envelope
    db $0D, $00, $C1                             ; step 0: +12  duty 1
    db $0F, $00, $C2                             ; step 1: +14  duty 2
    db $13, $C1, $83                             ; step 2: +18  duty 1, jump -3
    db $00, $00, $00                             ; step 3: -
Inst28:
    db $05                                       ; 56FB square, 5 steps
    db $88                                       ; playlist speed | $80 = vibrato
    db $4A                                       ; NRx2 envelope
    db $20, $47                                  ; vibrato delay, depth<<4|speed
    db $01, $00, $C2                             ; step 0: +0  duty 2
    db $00, $00, $C0                             ; step 1: -  duty 0
    db $00, $00, $C1                             ; step 2: -  duty 1
    db $00, $00, $C2                             ; step 3: -  duty 2
    db $00, $C1, $84                             ; step 4: -  duty 1, jump -4
Inst29:
    db $04                                       ; 570F square, 4 steps
    db $02                                       ; playlist speed
    db $D7                                       ; NRx2 envelope
    db $0C, $00, $C1                             ; step 0: +11  duty 1
    db $0F, $00, $C2                             ; step 1: +14  duty 2
    db $14, $C1, $83                             ; step 2: +19  duty 1, jump -3
    db $00, $00, $00                             ; step 3: -
Inst30:
    db $05                                       ; 571E square, 5 steps
    db $88                                       ; playlist speed | $80 = vibrato
    db $F7                                       ; NRx2 envelope
    db $00, $47                                  ; vibrato delay, depth<<4|speed
    db $01, $00, $C1                             ; step 0: +0  duty 1
    db $00, $00, $C2                             ; step 1: -  duty 2
    db $00, $00, $C1                             ; step 2: -  duty 1
    db $00, $00, $C0                             ; step 3: -  duty 0
    db $00, $C1, $84                             ; step 4: -  duty 1, jump -4
Inst31:
    db $05                                       ; 5732 square, 5 steps
    db $83                                       ; playlist speed | $80 = vibrato
    db $91                                       ; NRx2 envelope
    db $20, $47                                  ; vibrato delay, depth<<4|speed
    db $01, $00, $C2                             ; step 0: +0  duty 2
    db $00, $00, $C0                             ; step 1: -  duty 0
    db $00, $00, $4A                             ; step 2: -  vol 10
    db $00, $00, $C2                             ; step 3: -  duty 2
    db $00, $00, $C0                             ; step 4: -  duty 0
Track000:
    R   ___                                     ; 5746 row 00
    R   ___                                     ; 5747 row 01
    R   ___                                     ; 5748 row 02
    R   ___                                     ; 5749 row 03
    R   ___                                     ; 574A row 04
    R   ___                                     ; 574B row 05
    R   ___                                     ; 574C row 06
    R   ___                                     ; 574D row 07
    R   ___                                     ; 574E row 08
    R   ___                                     ; 574F row 09
    R   ___                                     ; 5750 row 10
    R   ___                                     ; 5751 row 11
    R   ___                                     ; 5752 row 12
    R   ___                                     ; 5753 row 13
    R   ___                                     ; 5754 row 14
    R   ___                                     ; 5755 row 15
    R   ___                                     ; 5756 row 16
    R   ___                                     ; 5757 row 17
    R   ___                                     ; 5758 row 18
    R   ___                                     ; 5759 row 19
    R   ___                                     ; 575A row 20
    R   ___                                     ; 575B row 21
    R   ___                                     ; 575C row 22
    R   ___                                     ; 575D row 23
    R   ___                                     ; 575E row 24
    R   ___                                     ; 575F row 25
    R   ___                                     ; 5760 row 26
    R   ___                                     ; 5761 row 27
    R   ___                                     ; 5762 row 28
    R   ___                                     ; 5763 row 29
    R   ___                                     ; 5764 row 30
    R   ___                                     ; 5765 row 31
Track001:
    RIF D_3, 1, 0, $F, $A                       ; 5766 row 00  Inst00  speed 10
    R   ___                                     ; 5769 row 01
    R   ___                                     ; 576A row 02
    R   ___                                     ; 576B row 03
    RI  D_4, 1, 0                               ; 576C row 04  Inst00
    R   ___                                     ; 576E row 05
    R   ___                                     ; 576F row 06
    R   ___                                     ; 5770 row 07
    RI  D_5, 1, 0                               ; 5771 row 08  Inst00
    R   ___                                     ; 5773 row 09
    R   ___                                     ; 5774 row 10
    R   ___                                     ; 5775 row 11
    RI  D_4, 1, 0                               ; 5776 row 12  Inst00
    R   ___                                     ; 5778 row 13
    R   ___                                     ; 5779 row 14
    R   ___                                     ; 577A row 15
    RI  D_3, 1, 0                               ; 577B row 16  Inst00
    R   ___                                     ; 577D row 17
    R   ___                                     ; 577E row 18
    R   ___                                     ; 577F row 19
    RI  C_4, 1, 0                               ; 5780 row 20  Inst00
    R   ___                                     ; 5782 row 21
    R   ___                                     ; 5783 row 22
    R   ___                                     ; 5784 row 23
    RI  C_5, 1, 0                               ; 5785 row 24  Inst00
    R   ___                                     ; 5787 row 25
    R   ___                                     ; 5788 row 26
    R   ___                                     ; 5789 row 27
    RI  C_4, 1, 0                               ; 578A row 28  Inst00
    R   ___                                     ; 578C row 29
    R   ___                                     ; 578D row 30
    R   ___                                     ; 578E row 31
Track002:
    R   ___                                     ; 578F row 00
    R   ___                                     ; 5790 row 01
    RI  G_3, 1, 0                               ; 5791 row 02  Inst00
    R   ___                                     ; 5793 row 03
    R   ___                                     ; 5794 row 04
    R   ___                                     ; 5795 row 05
    RI  G_4, 1, 0                               ; 5796 row 06  Inst00
    R   ___                                     ; 5798 row 07
    R   ___                                     ; 5799 row 08
    R   ___                                     ; 579A row 09
    RI  G_4, 1, 0                               ; 579B row 10  Inst00
    R   ___                                     ; 579D row 11
    R   ___                                     ; 579E row 12
    R   ___                                     ; 579F row 13
    RI  G_3, 1, 0                               ; 57A0 row 14  Inst00
    R   ___                                     ; 57A2 row 15
    R   ___                                     ; 57A3 row 16
    R   ___                                     ; 57A4 row 17
    RI  G_3, 1, 0                               ; 57A5 row 18  Inst00
    R   ___                                     ; 57A7 row 19
    R   ___                                     ; 57A8 row 20
    R   ___                                     ; 57A9 row 21
    RI  G_4, 1, 0                               ; 57AA row 22  Inst00
    R   ___                                     ; 57AC row 23
    R   ___                                     ; 57AD row 24
    R   ___                                     ; 57AE row 25
    RI  G_4, 1, 0                               ; 57AF row 26  Inst00
    R   ___                                     ; 57B1 row 27
    R   ___                                     ; 57B2 row 28
    R   ___                                     ; 57B3 row 29
    RI  G_3, 1, 0                               ; 57B4 row 30  Inst00
    R   ___                                     ; 57B6 row 31
Track003:
    RI  G_3, 2, 0                               ; 57B7 row 00  Inst01
    R   ___                                     ; 57B9 row 01
    R   ___                                     ; 57BA row 02
    R   ___                                     ; 57BB row 03
    R   ___                                     ; 57BC row 04
    R   ___                                     ; 57BD row 05
    R   ___                                     ; 57BE row 06
    R   ___                                     ; 57BF row 07
    R   ___                                     ; 57C0 row 08
    R   ___                                     ; 57C1 row 09
    R   ___                                     ; 57C2 row 10
    R   ___                                     ; 57C3 row 11
    R   ___                                     ; 57C4 row 12
    R   ___                                     ; 57C5 row 13
    R   ___                                     ; 57C6 row 14
    R   ___                                     ; 57C7 row 15
    R   ___                                     ; 57C8 row 16
    R   ___                                     ; 57C9 row 17
    R   ___                                     ; 57CA row 18
    R   ___                                     ; 57CB row 19
    R   ___                                     ; 57CC row 20
    R   ___                                     ; 57CD row 21
    R   ___                                     ; 57CE row 22
    R   ___                                     ; 57CF row 23
    R   ___                                     ; 57D0 row 24
    R   ___                                     ; 57D1 row 25
    R   ___                                     ; 57D2 row 26
    R   ___                                     ; 57D3 row 27
    RI  F_3, 2, 0                               ; 57D4 row 28  Inst01
    R   ___                                     ; 57D6 row 29
    R   ___                                     ; 57D7 row 30
    R   ___                                     ; 57D8 row 31
Track004:
    RIF D_3, 1, 0, $F, $A                       ; 57D9 row 00  Inst00  speed 10
    R   ___                                     ; 57DC row 01
    RI  G_3, 1, 0                               ; 57DD row 02  Inst00
    R   ___                                     ; 57DF row 03
    RI  D_4, 1, 0                               ; 57E0 row 04  Inst00
    R   ___                                     ; 57E2 row 05
    RI  G_4, 1, 0                               ; 57E3 row 06  Inst00
    R   ___                                     ; 57E5 row 07
    RI  D_5, 1, 0                               ; 57E6 row 08  Inst00
    R   ___                                     ; 57E8 row 09
    RI  G_4, 1, 0                               ; 57E9 row 10  Inst00
    R   ___                                     ; 57EB row 11
    RI  D_4, 1, 0                               ; 57EC row 12  Inst00
    R   ___                                     ; 57EE row 13
    RI  G_3, 1, 0                               ; 57EF row 14  Inst00
    R   ___                                     ; 57F1 row 15
    RI  D_3, 1, 0                               ; 57F2 row 16  Inst00
    R   ___                                     ; 57F4 row 17
    RI  G_3, 1, 0                               ; 57F5 row 18  Inst00
    R   ___                                     ; 57F7 row 19
    RI  C_4, 1, 0                               ; 57F8 row 20  Inst00
    R   ___                                     ; 57FA row 21
    RI  G_4, 1, 0                               ; 57FB row 22  Inst00
    R   ___                                     ; 57FD row 23
    RI  C_5, 1, 0                               ; 57FE row 24  Inst00
    R   ___                                     ; 5800 row 25
    RI  G_4, 1, 0                               ; 5801 row 26  Inst00
    R   ___                                     ; 5803 row 27
    RI  C_4, 1, 0                               ; 5804 row 28  Inst00
    R   ___                                     ; 5806 row 29
    RI  G_3, 1, 0                               ; 5807 row 30  Inst00
    R   ___                                     ; 5809 row 31
Track005:
    RI  G_4, 3, 0                               ; 580A row 00  Inst02
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
    RI  A_4, 3, 0                               ; 5823 row 24  Inst02
    R   ___                                     ; 5825 row 25
    R   ___                                     ; 5826 row 26
    R   ___                                     ; 5827 row 27
    RI  F_4, 3, 0                               ; 5828 row 28  Inst02
    R   ___                                     ; 582A row 29
    R   ___                                     ; 582B row 30
    R   ___                                     ; 582C row 31
Track006:
    RI  G_4, 3, 0                               ; 582D row 00  Inst02
    R   ___                                     ; 582F row 01
    R   ___                                     ; 5830 row 02
    R   ___                                     ; 5831 row 03
    R   ___                                     ; 5832 row 04
    R   ___                                     ; 5833 row 05
    R   ___                                     ; 5834 row 06
    R   ___                                     ; 5835 row 07
    RI  G_3, 4, 0                               ; 5836 row 08  Inst03
    R   ___                                     ; 5838 row 09
    RI  F_3, 4, 0                               ; 5839 row 10  Inst03
    R   ___                                     ; 583B row 11
    RI  E_3, 4, 0                               ; 583C row 12  Inst03
    R   ___                                     ; 583E row 13
    RI  D_3, 4, 0                               ; 583F row 14  Inst03
    R   ___                                     ; 5841 row 15
    R   ___                                     ; 5842 row 16
    R   ___                                     ; 5843 row 17
    R   ___                                     ; 5844 row 18
    R   ___                                     ; 5845 row 19
    R   ___                                     ; 5846 row 20
    R   ___                                     ; 5847 row 21
    R   ___                                     ; 5848 row 22
    R   ___                                     ; 5849 row 23
    R   ___                                     ; 584A row 24
    R   ___                                     ; 584B row 25
    R   ___                                     ; 584C row 26
    R   ___                                     ; 584D row 27
    RI  E_3, 4, 0                               ; 584E row 28  Inst03
    R   ___                                     ; 5850 row 29
    RI  F_3, 4, 0                               ; 5851 row 30  Inst03
    R   ___                                     ; 5853 row 31
Track007:
    RIF D_3, 1, 0, $F, $5                       ; 5854 row 00  Inst00  speed 5
    R   ___                                     ; 5857 row 01
    R   ___                                     ; 5858 row 02
    R   ___                                     ; 5859 row 03
    RI  G_3, 1, 0                               ; 585A row 04  Inst00
    R   ___                                     ; 585C row 05
    R   ___                                     ; 585D row 06
    R   ___                                     ; 585E row 07
    R   ___                                     ; 585F row 08
    R   ___                                     ; 5860 row 09
    R   ___                                     ; 5861 row 10
    R   ___                                     ; 5862 row 11
    RI  G_4, 1, 0                               ; 5863 row 12  Inst00
    R   ___                                     ; 5865 row 13
    R   ___                                     ; 5866 row 14
    R   ___                                     ; 5867 row 15
    R   ___                                     ; 5868 row 16
    R   ___                                     ; 5869 row 17
    R   ___                                     ; 586A row 18
    R   ___                                     ; 586B row 19
    RI  G_4, 1, 0                               ; 586C row 20  Inst00
    R   ___                                     ; 586E row 21
    R   ___                                     ; 586F row 22
    R   ___                                     ; 5870 row 23
    R   ___                                     ; 5871 row 24
    R   ___                                     ; 5872 row 25
    R   ___                                     ; 5873 row 26
    R   ___                                     ; 5874 row 27
    RI  G_3, 1, 0                               ; 5875 row 28  Inst00
    R   ___                                     ; 5877 row 29
    R   ___                                     ; 5878 row 30
    R   ___                                     ; 5879 row 31
Track008:
    RI  G_3, 2, 0                               ; 587A row 00  Inst01
    R   ___                                     ; 587C row 01
    R   ___                                     ; 587D row 02
    R   ___                                     ; 587E row 03
    R   ___                                     ; 587F row 04
    R   ___                                     ; 5880 row 05
    R   ___                                     ; 5881 row 06
    R   ___                                     ; 5882 row 07
    R   ___                                     ; 5883 row 08
    R   ___                                     ; 5884 row 09
    R   ___                                     ; 5885 row 10
    R   ___                                     ; 5886 row 11
    R   ___                                     ; 5887 row 12
    R   ___                                     ; 5888 row 13
    R   ___                                     ; 5889 row 14
    R   ___                                     ; 588A row 15
    R   ___                                     ; 588B row 16
    R   ___                                     ; 588C row 17
    R   ___                                     ; 588D row 18
    R   ___                                     ; 588E row 19
    R   ___                                     ; 588F row 20
    R   ___                                     ; 5890 row 21
    R   ___                                     ; 5891 row 22
    R   ___                                     ; 5892 row 23
    R   ___                                     ; 5893 row 24
    R   ___                                     ; 5894 row 25
    R   ___                                     ; 5895 row 26
    R   ___                                     ; 5896 row 27
    R   ___                                     ; 5897 row 28
    R   ___                                     ; 5898 row 29
    R   ___                                     ; 5899 row 30
    R   ___                                     ; 589A row 31
Track009:
    RI  D_3, 1, 0                               ; 589B row 00  Inst00
    R   ___                                     ; 589D row 01
    R   ___                                     ; 589E row 02
    R   ___                                     ; 589F row 03
    RI  G_3, 1, 0                               ; 58A0 row 04  Inst00
    R   ___                                     ; 58A2 row 05
    R   ___                                     ; 58A3 row 06
    R   ___                                     ; 58A4 row 07
    RI  C_4, 1, 0                               ; 58A5 row 08  Inst00
    R   ___                                     ; 58A7 row 09
    R   ___                                     ; 58A8 row 10
    R   ___                                     ; 58A9 row 11
    RI  G_4, 1, 0                               ; 58AA row 12  Inst00
    R   ___                                     ; 58AC row 13
    R   ___                                     ; 58AD row 14
    R   ___                                     ; 58AE row 15
    RI  C_5, 1, 0                               ; 58AF row 16  Inst00
    R   ___                                     ; 58B1 row 17
    R   ___                                     ; 58B2 row 18
    R   ___                                     ; 58B3 row 19
    RI  G_4, 1, 0                               ; 58B4 row 20  Inst00
    R   ___                                     ; 58B6 row 21
    R   ___                                     ; 58B7 row 22
    R   ___                                     ; 58B8 row 23
    RI  C_4, 1, 0                               ; 58B9 row 24  Inst00
    R   ___                                     ; 58BB row 25
    R   ___                                     ; 58BC row 26
    R   ___                                     ; 58BD row 27
    RI  G_3, 1, 0                               ; 58BE row 28  Inst00
    R   ___                                     ; 58C0 row 29
    R   ___                                     ; 58C1 row 30
    R   ___                                     ; 58C2 row 31
Track010:
    RI  E_3, 4, 0                               ; 58C3 row 00  Inst03
    R   ___                                     ; 58C5 row 01
    R   ___                                     ; 58C6 row 02
    R   ___                                     ; 58C7 row 03
    R   ___                                     ; 58C8 row 04
    R   ___                                     ; 58C9 row 05
    R   ___                                     ; 58CA row 06
    R   ___                                     ; 58CB row 07
    RI  C_3, 4, 0                               ; 58CC row 08  Inst03
    R   ___                                     ; 58CE row 09
    R   ___                                     ; 58CF row 10
    R   ___                                     ; 58D0 row 11
    R   ___                                     ; 58D1 row 12
    R   ___                                     ; 58D2 row 13
    R   ___                                     ; 58D3 row 14
    R   ___                                     ; 58D4 row 15
    R   ___                                     ; 58D5 row 16
    R   ___                                     ; 58D6 row 17
    R   ___                                     ; 58D7 row 18
    R   ___                                     ; 58D8 row 19
    R   ___                                     ; 58D9 row 20
    R   ___                                     ; 58DA row 21
    R   ___                                     ; 58DB row 22
    R   ___                                     ; 58DC row 23
    RI  As2, 4, 0                               ; 58DD row 24  Inst03
    R   ___                                     ; 58DF row 25
    R   ___                                     ; 58E0 row 26
    RI  C_3, 4, 0                               ; 58E1 row 27  Inst03
    R   ___                                     ; 58E3 row 28
    R   ___                                     ; 58E4 row 29
    RI  E_2, 4, 0                               ; 58E5 row 30  Inst03
    R   ___                                     ; 58E7 row 31
Track011:
    RI  D_2, 4, 0                               ; 58E8 row 00  Inst03
    R   ___                                     ; 58EA row 01
    R   ___                                     ; 58EB row 02
    R   ___                                     ; 58EC row 03
    R   ___                                     ; 58ED row 04
    R   ___                                     ; 58EE row 05
    R   ___                                     ; 58EF row 06
    R   ___                                     ; 58F0 row 07
    R   ___                                     ; 58F1 row 08
    R   ___                                     ; 58F2 row 09
    R   ___                                     ; 58F3 row 10
    R   ___                                     ; 58F4 row 11
    R   ___                                     ; 58F5 row 12
    R   ___                                     ; 58F6 row 13
    R   ___                                     ; 58F7 row 14
    R   ___                                     ; 58F8 row 15
    R   ___                                     ; 58F9 row 16
    R   ___                                     ; 58FA row 17
    R   ___                                     ; 58FB row 18
    R   ___                                     ; 58FC row 19
    R   ___                                     ; 58FD row 20
    R   ___                                     ; 58FE row 21
    R   ___                                     ; 58FF row 22
    R   ___                                     ; 5900 row 23
    RI  C_4, 5, 0                               ; 5901 row 24  Inst04
    R   ___                                     ; 5903 row 25
    R   ___                                     ; 5904 row 26
    R   ___                                     ; 5905 row 27
    R   ___                                     ; 5906 row 28
    R   ___                                     ; 5907 row 29
    R   ___                                     ; 5908 row 30
    R   ___                                     ; 5909 row 31
Track012:
    RI  C_4, 6, 0                               ; 590A row 00  Inst05
    R   ___                                     ; 590C row 01
    R   ___                                     ; 590D row 02
    R   ___                                     ; 590E row 03
    R   ___                                     ; 590F row 04
    R   ___                                     ; 5910 row 05
    R   ___                                     ; 5911 row 06
    R   ___                                     ; 5912 row 07
    R   ___                                     ; 5913 row 08
    R   ___                                     ; 5914 row 09
    R   ___                                     ; 5915 row 10
    R   ___                                     ; 5916 row 11
    RI  C_4, 5, 0                               ; 5917 row 12  Inst04
    R   ___                                     ; 5919 row 13
    R   ___                                     ; 591A row 14
    R   ___                                     ; 591B row 15
    R   ___                                     ; 591C row 16
    R   ___                                     ; 591D row 17
    R   ___                                     ; 591E row 18
    R   ___                                     ; 591F row 19
    R   ___                                     ; 5920 row 20
    R   ___                                     ; 5921 row 21
    R   ___                                     ; 5922 row 22
    R   ___                                     ; 5923 row 23
    RI  C_4, 6, 0                               ; 5924 row 24  Inst05
    R   ___                                     ; 5926 row 25
    R   ___                                     ; 5927 row 26
    R   ___                                     ; 5928 row 27
    R   ___                                     ; 5929 row 28
    R   ___                                     ; 592A row 29
    R   ___                                     ; 592B row 30
    R   ___                                     ; 592C row 31
Track013:
    RI  C_4, 7, 0                               ; 592D row 00  Inst06
    R   ___                                     ; 592F row 01
    R   ___                                     ; 5930 row 02
    R   ___                                     ; 5931 row 03
    R   ___                                     ; 5932 row 04
    R   ___                                     ; 5933 row 05
    R   ___                                     ; 5934 row 06
    R   ___                                     ; 5935 row 07
    RI  G_3, 4, 0                               ; 5936 row 08  Inst03
    R   ___                                     ; 5938 row 09
    RI  F_3, 4, 0                               ; 5939 row 10  Inst03
    R   ___                                     ; 593B row 11
    RI  E_3, 4, 0                               ; 593C row 12  Inst03
    R   ___                                     ; 593E row 13
    RI  D_3, 4, 0                               ; 593F row 14  Inst03
    R   ___                                     ; 5941 row 15
    R   ___                                     ; 5942 row 16
    R   ___                                     ; 5943 row 17
    R   ___                                     ; 5944 row 18
    R   ___                                     ; 5945 row 19
    R   ___                                     ; 5946 row 20
    R   ___                                     ; 5947 row 21
    R   ___                                     ; 5948 row 22
    R   ___                                     ; 5949 row 23
    R   ___                                     ; 594A row 24
    R   ___                                     ; 594B row 25
    R   ___                                     ; 594C row 26
    R   ___                                     ; 594D row 27
    RI  E_3, 4, 0                               ; 594E row 28  Inst03
    R   ___                                     ; 5950 row 29
    RI  F_3, 4, 0                               ; 5951 row 30  Inst03
    R   ___                                     ; 5953 row 31
Track014:
    R   ___                                     ; 5954 row 00
    R   ___                                     ; 5955 row 01
    R   ___                                     ; 5956 row 02
    R   ___                                     ; 5957 row 03
    R   ___                                     ; 5958 row 04
    R   ___                                     ; 5959 row 05
    R   ___                                     ; 595A row 06
    R   ___                                     ; 595B row 07
    R   ___                                     ; 595C row 08
    R   ___                                     ; 595D row 09
    R   ___                                     ; 595E row 10
    R   ___                                     ; 595F row 11
    R   ___                                     ; 5960 row 12
    R   ___                                     ; 5961 row 13
    R   ___                                     ; 5962 row 14
    R   ___                                     ; 5963 row 15
    R   ___                                     ; 5964 row 16
    R   ___                                     ; 5965 row 17
    R   ___                                     ; 5966 row 18
    R   ___                                     ; 5967 row 19
    R   ___                                     ; 5968 row 20
    R   ___                                     ; 5969 row 21
    R   ___                                     ; 596A row 22
    R   ___                                     ; 596B row 23
    RI  F_3, 2, 0                               ; 596C row 24  Inst01
    R   ___                                     ; 596E row 25
    R   ___                                     ; 596F row 26
    R   ___                                     ; 5970 row 27
    R   ___                                     ; 5971 row 28
    R   ___                                     ; 5972 row 29
    R   ___                                     ; 5973 row 30
    R   ___                                     ; 5974 row 31
Track015:
    R   ___                                     ; 5975 row 00
    R   ___                                     ; 5976 row 01
    R   ___                                     ; 5977 row 02
    R   ___                                     ; 5978 row 03
    RI  G_3, 1, 0                               ; 5979 row 04  Inst00
    R   ___                                     ; 597B row 05
    R   ___                                     ; 597C row 06
    R   ___                                     ; 597D row 07
    R   ___                                     ; 597E row 08
    R   ___                                     ; 597F row 09
    R   ___                                     ; 5980 row 10
    R   ___                                     ; 5981 row 11
    RI  G_4, 1, 0                               ; 5982 row 12  Inst00
    R   ___                                     ; 5984 row 13
    R   ___                                     ; 5985 row 14
    R   ___                                     ; 5986 row 15
    R   ___                                     ; 5987 row 16
    R   ___                                     ; 5988 row 17
    R   ___                                     ; 5989 row 18
    R   ___                                     ; 598A row 19
    RI  G_4, 1, 0                               ; 598B row 20  Inst00
    R   ___                                     ; 598D row 21
    R   ___                                     ; 598E row 22
    R   ___                                     ; 598F row 23
    R   ___                                     ; 5990 row 24
    R   ___                                     ; 5991 row 25
    R   ___                                     ; 5992 row 26
    R   ___                                     ; 5993 row 27
    RI  G_3, 1, 0                               ; 5994 row 28  Inst00
    R   ___                                     ; 5996 row 29
    R   ___                                     ; 5997 row 30
    R   ___                                     ; 5998 row 31
Track016:
    RI  C_4, 7, 0                               ; 5999 row 00  Inst06
    R   ___                                     ; 599B row 01
    R   ___                                     ; 599C row 02
    R   ___                                     ; 599D row 03
    R   ___                                     ; 599E row 04
    R   ___                                     ; 599F row 05
    R   ___                                     ; 59A0 row 06
    R   ___                                     ; 59A1 row 07
    RI  D_4, 1, 0                               ; 59A2 row 08  Inst00
    R   ___                                     ; 59A4 row 09
    R   ___                                     ; 59A5 row 10
    R   ___                                     ; 59A6 row 11
    R   ___                                     ; 59A7 row 12
    R   ___                                     ; 59A8 row 13
    R   ___                                     ; 59A9 row 14
    R   ___                                     ; 59AA row 15
    RI  D_5, 1, 0                               ; 59AB row 16  Inst00
    R   ___                                     ; 59AD row 17
    R   ___                                     ; 59AE row 18
    R   ___                                     ; 59AF row 19
    R   ___                                     ; 59B0 row 20
    R   ___                                     ; 59B1 row 21
    R   ___                                     ; 59B2 row 22
    R   ___                                     ; 59B3 row 23
    RI  D_4, 1, 0                               ; 59B4 row 24  Inst00
    R   ___                                     ; 59B6 row 25
    R   ___                                     ; 59B7 row 26
    R   ___                                     ; 59B8 row 27
    R   ___                                     ; 59B9 row 28
    R   ___                                     ; 59BA row 29
    R   ___                                     ; 59BB row 30
    R   ___                                     ; 59BC row 31
Track017:
    RI  G_4, 4, 0                               ; 59BD row 00  Inst03
    R   ___                                     ; 59BF row 01
    R   ___                                     ; 59C0 row 02
    R   ___                                     ; 59C1 row 03
    R   ___                                     ; 59C2 row 04
    R   ___                                     ; 59C3 row 05
    R   ___                                     ; 59C4 row 06
    R   ___                                     ; 59C5 row 07
    R   ___                                     ; 59C6 row 08
    R   ___                                     ; 59C7 row 09
    R   ___                                     ; 59C8 row 10
    R   ___                                     ; 59C9 row 11
    R   ___                                     ; 59CA row 12
    R   ___                                     ; 59CB row 13
    R   ___                                     ; 59CC row 14
    R   ___                                     ; 59CD row 15
    R   ___                                     ; 59CE row 16
    R   ___                                     ; 59CF row 17
    R   ___                                     ; 59D0 row 18
    R   ___                                     ; 59D1 row 19
    R   ___                                     ; 59D2 row 20
    R   ___                                     ; 59D3 row 21
    R   ___                                     ; 59D4 row 22
    R   ___                                     ; 59D5 row 23
    R   ___                                     ; 59D6 row 24
    R   ___                                     ; 59D7 row 25
    R   ___                                     ; 59D8 row 26
    R   ___                                     ; 59D9 row 27
    R   ___                                     ; 59DA row 28
    R   ___                                     ; 59DB row 29
    R   ___                                     ; 59DC row 30
    R   ___                                     ; 59DD row 31
Track018:
    RI  G_2, 10, 0                              ; 59DE row 00  Inst09
    R   ___                                     ; 59E0 row 01
    R   ___                                     ; 59E1 row 02
    RI  ___, 0, 0                               ; 59E2 row 03
    RI  G_3, 10, 0                              ; 59E4 row 04  Inst09
    RI  ___, 0, 0                               ; 59E6 row 05
    RI  G_2, 10, 0                              ; 59E8 row 06  Inst09
    RI  ___, 0, 0                               ; 59EA row 07
    RI  C_4, 8, 0                               ; 59EC row 08  Inst07
    R   ___                                     ; 59EE row 09
    R   ___                                     ; 59EF row 10
    R   ___                                     ; 59F0 row 11
    RI  G_3, 10, 0                              ; 59F1 row 12  Inst09
    RI  ___, 0, 0                               ; 59F3 row 13
    RI  G_2, 10, 0                              ; 59F5 row 14  Inst09
    RI  ___, 0, 0                               ; 59F7 row 15
    RI  F_2, 10, 0                              ; 59F9 row 16  Inst09
    RI  ___, 0, 0                               ; 59FB row 17
    RI  G_2, 10, 0                              ; 59FD row 18  Inst09
    R   ___                                     ; 59FF row 19
    R   ___                                     ; 5A00 row 20
    RI  ___, 0, 0                               ; 5A01 row 21
    RI  G_2, 10, 0                              ; 5A03 row 22  Inst09
    RI  ___, 0, 0                               ; 5A05 row 23
    RI  C_4, 8, 0                               ; 5A07 row 24  Inst07
    R   ___                                     ; 5A09 row 25
    RI  C_3, 8, 0                               ; 5A0A row 26  Inst07
    R   ___                                     ; 5A0C row 27
    RI  G_3, 10, 0                              ; 5A0D row 28  Inst09
    RI  ___, 0, 0                               ; 5A0F row 29
    RI  C_3, 8, 0                               ; 5A11 row 30  Inst07
    RI  ___, 0, 0                               ; 5A13 row 31
Track019:
    RI  C_3, 11, 0                              ; 5A15 row 00  Inst10
    R   ___                                     ; 5A17 row 01
    R   ___                                     ; 5A18 row 02
    R   ___                                     ; 5A19 row 03
    RI  C_3, 11, 0                              ; 5A1A row 04  Inst10
    R   ___                                     ; 5A1C row 05
    RI  C_3, 11, 0                              ; 5A1D row 06  Inst10
    R   ___                                     ; 5A1F row 07
    RI  C_6, 9, 0                               ; 5A20 row 08  Inst08
    R   ___                                     ; 5A22 row 09
    R   ___                                     ; 5A23 row 10
    R   ___                                     ; 5A24 row 11
    RI  C_3, 11, 0                              ; 5A25 row 12  Inst10
    R   ___                                     ; 5A27 row 13
    RI  C_3, 11, 0                              ; 5A28 row 14  Inst10
    R   ___                                     ; 5A2A row 15
    RI  C_3, 11, 0                              ; 5A2B row 16  Inst10
    R   ___                                     ; 5A2D row 17
    RI  C_3, 11, 0                              ; 5A2E row 18  Inst10
    R   ___                                     ; 5A30 row 19
    R   ___                                     ; 5A31 row 20
    R   ___                                     ; 5A32 row 21
    RI  C_3, 11, 0                              ; 5A33 row 22  Inst10
    R   ___                                     ; 5A35 row 23
    RI  C_3, 9, 0                               ; 5A36 row 24  Inst08
    R   ___                                     ; 5A38 row 25
    R   ___                                     ; 5A39 row 26
    R   ___                                     ; 5A3A row 27
    RI  C_3, 11, 0                              ; 5A3B row 28  Inst10
    R   ___                                     ; 5A3D row 29
    RI  C_3, 11, 0                              ; 5A3E row 30  Inst10
    R   ___                                     ; 5A40 row 31
Track020:
    RI  D_3, 1, 0                               ; 5A41 row 00  Inst00
    R   ___                                     ; 5A43 row 01
    R   ___                                     ; 5A44 row 02
    R   ___                                     ; 5A45 row 03
    R   ___                                     ; 5A46 row 04
    R   ___                                     ; 5A47 row 05
    R   ___                                     ; 5A48 row 06
    R   ___                                     ; 5A49 row 07
    RI  C_4, 1, 0                               ; 5A4A row 08  Inst00
    R   ___                                     ; 5A4C row 09
    R   ___                                     ; 5A4D row 10
    R   ___                                     ; 5A4E row 11
    R   ___                                     ; 5A4F row 12
    R   ___                                     ; 5A50 row 13
    R   ___                                     ; 5A51 row 14
    R   ___                                     ; 5A52 row 15
    RI  C_5, 1, 0                               ; 5A53 row 16  Inst00
    R   ___                                     ; 5A55 row 17
    R   ___                                     ; 5A56 row 18
    R   ___                                     ; 5A57 row 19
    R   ___                                     ; 5A58 row 20
    R   ___                                     ; 5A59 row 21
    R   ___                                     ; 5A5A row 22
    R   ___                                     ; 5A5B row 23
    RI  C_4, 1, 0                               ; 5A5C row 24  Inst00
    R   ___                                     ; 5A5E row 25
    R   ___                                     ; 5A5F row 26
    R   ___                                     ; 5A60 row 27
    R   ___                                     ; 5A61 row 28
    R   ___                                     ; 5A62 row 29
    R   ___                                     ; 5A63 row 30
    R   ___                                     ; 5A64 row 31
Track021:
    R   ___                                     ; 5A65 row 00
    R   ___                                     ; 5A66 row 01
    R   ___                                     ; 5A67 row 02
    R   ___                                     ; 5A68 row 03
    RI  G_3, 1, 0                               ; 5A69 row 04  Inst00
    R   ___                                     ; 5A6B row 05
    R   ___                                     ; 5A6C row 06
    R   ___                                     ; 5A6D row 07
    R   ___                                     ; 5A6E row 08
    R   ___                                     ; 5A6F row 09
    R   ___                                     ; 5A70 row 10
    R   ___                                     ; 5A71 row 11
    RI  G_4, 1, 0                               ; 5A72 row 12  Inst00
    R   ___                                     ; 5A74 row 13
    R   ___                                     ; 5A75 row 14
    R   ___                                     ; 5A76 row 15
    R   ___                                     ; 5A77 row 16
    R   ___                                     ; 5A78 row 17
    R   ___                                     ; 5A79 row 18
    R   ___                                     ; 5A7A row 19
    RI  G_4, 1, 0                               ; 5A7B row 20  Inst00
    R   ___                                     ; 5A7D row 21
    R   ___                                     ; 5A7E row 22
    R   ___                                     ; 5A7F row 23
    R   ___                                     ; 5A80 row 24
    R   ___                                     ; 5A81 row 25
    R   ___                                     ; 5A82 row 26
    R   ___                                     ; 5A83 row 27
    RI  G_3, 1, 0                               ; 5A84 row 28  Inst00
    R   ___                                     ; 5A86 row 29
    R   ___                                     ; 5A87 row 30
    R   ___                                     ; 5A88 row 31
Track022:
    RI  D_3, 1, 0                               ; 5A89 row 00  Inst00
    R   ___                                     ; 5A8B row 01
    R   ___                                     ; 5A8C row 02
    R   ___                                     ; 5A8D row 03
    R   ___                                     ; 5A8E row 04
    R   ___                                     ; 5A8F row 05
    R   ___                                     ; 5A90 row 06
    R   ___                                     ; 5A91 row 07
    RI  D_4, 1, 0                               ; 5A92 row 08  Inst00
    R   ___                                     ; 5A94 row 09
    R   ___                                     ; 5A95 row 10
    R   ___                                     ; 5A96 row 11
    R   ___                                     ; 5A97 row 12
    R   ___                                     ; 5A98 row 13
    R   ___                                     ; 5A99 row 14
    R   ___                                     ; 5A9A row 15
    RI  D_5, 1, 0                               ; 5A9B row 16  Inst00
    R   ___                                     ; 5A9D row 17
    R   ___                                     ; 5A9E row 18
    R   ___                                     ; 5A9F row 19
    R   ___                                     ; 5AA0 row 20
    R   ___                                     ; 5AA1 row 21
    R   ___                                     ; 5AA2 row 22
    R   ___                                     ; 5AA3 row 23
    RI  D_4, 1, 0                               ; 5AA4 row 24  Inst00
    R   ___                                     ; 5AA6 row 25
    R   ___                                     ; 5AA7 row 26
    R   ___                                     ; 5AA8 row 27
    R   ___                                     ; 5AA9 row 28
    R   ___                                     ; 5AAA row 29
    R   ___                                     ; 5AAB row 30
    R   ___                                     ; 5AAC row 31
Track023:
    RI  C_4, 12, 0                              ; 5AAD row 00  Inst11
    R   ___                                     ; 5AAF row 01
    R   ___                                     ; 5AB0 row 02
    R   ___                                     ; 5AB1 row 03
    R   ___                                     ; 5AB2 row 04
    R   ___                                     ; 5AB3 row 05
    R   ___                                     ; 5AB4 row 06
    R   ___                                     ; 5AB5 row 07
    RI  C_4, 9, 0                               ; 5AB6 row 08  Inst08
    R   ___                                     ; 5AB8 row 09
    R   ___                                     ; 5AB9 row 10
    R   ___                                     ; 5ABA row 11
    RI  C_3, 11, 0                              ; 5ABB row 12  Inst10
    R   ___                                     ; 5ABD row 13
    RI  C_3, 11, 0                              ; 5ABE row 14  Inst10
    R   ___                                     ; 5AC0 row 15
    RI  C_3, 11, 0                              ; 5AC1 row 16  Inst10
    R   ___                                     ; 5AC3 row 17
    RI  C_3, 11, 0                              ; 5AC4 row 18  Inst10
    R   ___                                     ; 5AC6 row 19
    R   ___                                     ; 5AC7 row 20
    R   ___                                     ; 5AC8 row 21
    RI  C_3, 11, 0                              ; 5AC9 row 22  Inst10
    R   ___                                     ; 5ACB row 23
    RI  C_3, 9, 0                               ; 5ACC row 24  Inst08
    R   ___                                     ; 5ACE row 25
    R   ___                                     ; 5ACF row 26
    R   ___                                     ; 5AD0 row 27
    RI  C_3, 11, 0                              ; 5AD1 row 28  Inst10
    R   ___                                     ; 5AD3 row 29
    RI  C_3, 11, 0                              ; 5AD4 row 30  Inst10
    R   ___                                     ; 5AD6 row 31
Track024:
    RIF D_3, 1, 0, $F, $5                       ; 5AD7 row 00  Inst00  speed 5
    R   ___                                     ; 5ADA row 01
    R   ___                                     ; 5ADB row 02
    R   ___                                     ; 5ADC row 03
    RI  G_3, 1, 0                               ; 5ADD row 04  Inst00
    R   ___                                     ; 5ADF row 05
    R   ___                                     ; 5AE0 row 06
    R   ___                                     ; 5AE1 row 07
    RI  D_4, 1, 0                               ; 5AE2 row 08  Inst00
    R   ___                                     ; 5AE4 row 09
    R   ___                                     ; 5AE5 row 10
    R   ___                                     ; 5AE6 row 11
    RI  G_4, 1, 0                               ; 5AE7 row 12  Inst00
    R   ___                                     ; 5AE9 row 13
    R   ___                                     ; 5AEA row 14
    R   ___                                     ; 5AEB row 15
    RI  D_5, 1, 0                               ; 5AEC row 16  Inst00
    R   ___                                     ; 5AEE row 17
    R   ___                                     ; 5AEF row 18
    R   ___                                     ; 5AF0 row 19
    RI  G_4, 1, 0                               ; 5AF1 row 20  Inst00
    R   ___                                     ; 5AF3 row 21
    R   ___                                     ; 5AF4 row 22
    R   ___                                     ; 5AF5 row 23
    RI  D_4, 1, 0                               ; 5AF6 row 24  Inst00
    R   ___                                     ; 5AF8 row 25
    R   ___                                     ; 5AF9 row 26
    R   ___                                     ; 5AFA row 27
    RI  G_3, 1, 0                               ; 5AFB row 28  Inst00
    R   ___                                     ; 5AFD row 29
    R   ___                                     ; 5AFE row 30
    R   ___                                     ; 5AFF row 31
Track025:
    RI  G_3, 1, 0                               ; 5B00 row 00  Inst00
    R   ___                                     ; 5B02 row 01
    R   ___                                     ; 5B03 row 02
    R   ___                                     ; 5B04 row 03
    R   ___                                     ; 5B05 row 04
    R   ___                                     ; 5B06 row 05
    RI  G_3, 1, 1                               ; 5B07 row 06  Inst00
    R   ___                                     ; 5B09 row 07
    RI  C_3, 14, 0                              ; 5B0A row 08  Inst13
    R   ___                                     ; 5B0C row 09
    R   ___                                     ; 5B0D row 10
    R   ___                                     ; 5B0E row 11
    R   ___                                     ; 5B0F row 12
    R   ___                                     ; 5B10 row 13
    R   ___                                     ; 5B11 row 14
    R   ___                                     ; 5B12 row 15
    R   ___                                     ; 5B13 row 16
    R   ___                                     ; 5B14 row 17
    R   ___                                     ; 5B15 row 18
    R   ___                                     ; 5B16 row 19
    R   ___                                     ; 5B17 row 20
    R   ___                                     ; 5B18 row 21
    R   ___                                     ; 5B19 row 22
    R   ___                                     ; 5B1A row 23
    R   ___                                     ; 5B1B row 24
    R   ___                                     ; 5B1C row 25
    R   ___                                     ; 5B1D row 26
    R   ___                                     ; 5B1E row 27
    R   ___                                     ; 5B1F row 28
    R   ___                                     ; 5B20 row 29
    R   ___                                     ; 5B21 row 30
    R   ___                                     ; 5B22 row 31
Track026:
    RI  G_2, 4, 0                               ; 5B23 row 00  Inst03
    R   ___                                     ; 5B25 row 01
    R   ___                                     ; 5B26 row 02
    R   ___                                     ; 5B27 row 03
    R   ___                                     ; 5B28 row 04
    R   ___                                     ; 5B29 row 05
    R   ___                                     ; 5B2A row 06
    R   ___                                     ; 5B2B row 07
    R   ___                                     ; 5B2C row 08
    R   ___                                     ; 5B2D row 09
    R   ___                                     ; 5B2E row 10
    R   ___                                     ; 5B2F row 11
    R   ___                                     ; 5B30 row 12
    R   ___                                     ; 5B31 row 13
    RI  C_3, 14, 0                              ; 5B32 row 14  Inst13
    R   ___                                     ; 5B34 row 15
    R   ___                                     ; 5B35 row 16
    R   ___                                     ; 5B36 row 17
    R   ___                                     ; 5B37 row 18
    R   ___                                     ; 5B38 row 19
    R   ___                                     ; 5B39 row 20
    R   ___                                     ; 5B3A row 21
    R   ___                                     ; 5B3B row 22
    R   ___                                     ; 5B3C row 23
    R   ___                                     ; 5B3D row 24
    R   ___                                     ; 5B3E row 25
    R   ___                                     ; 5B3F row 26
    R   ___                                     ; 5B40 row 27
    R   ___                                     ; 5B41 row 28
    R   ___                                     ; 5B42 row 29
    R   ___                                     ; 5B43 row 30
    R   ___                                     ; 5B44 row 31
Track027:
    R   ___                                     ; 5B45 row 00
    R   ___                                     ; 5B46 row 01
    R   ___                                     ; 5B47 row 02
    R   ___                                     ; 5B48 row 03
    RI  G_3, 1, 0                               ; 5B49 row 04  Inst00
    R   ___                                     ; 5B4B row 05
    R   ___                                     ; 5B4C row 06
    R   ___                                     ; 5B4D row 07
    R   ___                                     ; 5B4E row 08
    R   ___                                     ; 5B4F row 09
    R   ___                                     ; 5B50 row 10
    R   ___                                     ; 5B51 row 11
    RI  G_4, 1, 0                               ; 5B52 row 12  Inst00
    R   ___                                     ; 5B54 row 13
    R   ___                                     ; 5B55 row 14
    R   ___                                     ; 5B56 row 15
    R   ___                                     ; 5B57 row 16
    R   ___                                     ; 5B58 row 17
    R   ___                                     ; 5B59 row 18
    R   ___                                     ; 5B5A row 19
    RI  G_4, 1, 0                               ; 5B5B row 20  Inst00
    R   ___                                     ; 5B5D row 21
    R   ___                                     ; 5B5E row 22
    R   ___                                     ; 5B5F row 23
    RI  F_2, 4, 0                               ; 5B60 row 24  Inst03
    R   ___                                     ; 5B62 row 25
    RI  F_2, 4, 0                               ; 5B63 row 26  Inst03
    R   ___                                     ; 5B65 row 27
    R   ___                                     ; 5B66 row 28
    R   ___                                     ; 5B67 row 29
    RI  F_2, 4, 0                               ; 5B68 row 30  Inst03
    R   ___                                     ; 5B6A row 31
Track028:
    RI  D_3, 1, 0                               ; 5B6B row 00  Inst00
    R   ___                                     ; 5B6D row 01
    R   ___                                     ; 5B6E row 02
    R   ___                                     ; 5B6F row 03
    R   ___                                     ; 5B70 row 04
    R   ___                                     ; 5B71 row 05
    R   ___                                     ; 5B72 row 06
    R   ___                                     ; 5B73 row 07
    RI  C_4, 1, 0                               ; 5B74 row 08  Inst00
    R   ___                                     ; 5B76 row 09
    R   ___                                     ; 5B77 row 10
    R   ___                                     ; 5B78 row 11
    R   ___                                     ; 5B79 row 12
    R   ___                                     ; 5B7A row 13
    R   ___                                     ; 5B7B row 14
    R   ___                                     ; 5B7C row 15
    RI  C_5, 1, 0                               ; 5B7D row 16  Inst00
    R   ___                                     ; 5B7F row 17
    R   ___                                     ; 5B80 row 18
    R   ___                                     ; 5B81 row 19
    R   ___                                     ; 5B82 row 20
    R   ___                                     ; 5B83 row 21
    R   ___                                     ; 5B84 row 22
    R   ___                                     ; 5B85 row 23
    RI  F_2, 1, 0                               ; 5B86 row 24  Inst00
    R   ___                                     ; 5B88 row 25
    RI  F_2, 1, 0                               ; 5B89 row 26  Inst00
    R   ___                                     ; 5B8B row 27
    R   ___                                     ; 5B8C row 28
    R   ___                                     ; 5B8D row 29
    RI  F_2, 1, 0                               ; 5B8E row 30  Inst00
    R   ___                                     ; 5B90 row 31
Track029:
    RI  C_3, 11, 0                              ; 5B91 row 00  Inst10
    R   ___                                     ; 5B93 row 01
    R   ___                                     ; 5B94 row 02
    R   ___                                     ; 5B95 row 03
    RI  C_3, 11, 0                              ; 5B96 row 04  Inst10
    R   ___                                     ; 5B98 row 05
    RI  C_3, 11, 0                              ; 5B99 row 06  Inst10
    R   ___                                     ; 5B9B row 07
    RI  C_6, 9, 0                               ; 5B9C row 08  Inst08
    R   ___                                     ; 5B9E row 09
    R   ___                                     ; 5B9F row 10
    R   ___                                     ; 5BA0 row 11
    RI  C_3, 11, 0                              ; 5BA1 row 12  Inst10
    R   ___                                     ; 5BA3 row 13
    RI  C_3, 11, 0                              ; 5BA4 row 14  Inst10
    R   ___                                     ; 5BA6 row 15
    RI  C_3, 11, 0                              ; 5BA7 row 16  Inst10
    R   ___                                     ; 5BA9 row 17
    RI  C_3, 11, 0                              ; 5BAA row 18  Inst10
    R   ___                                     ; 5BAC row 19
    R   ___                                     ; 5BAD row 20
    R   ___                                     ; 5BAE row 21
    RI  C_3, 11, 0                              ; 5BAF row 22  Inst10
    R   ___                                     ; 5BB1 row 23
    RI  C_3, 9, 0                               ; 5BB2 row 24  Inst08
    R   ___                                     ; 5BB4 row 25
    RI  C_3, 9, 0                               ; 5BB5 row 26  Inst08
    R   ___                                     ; 5BB7 row 27
    R   ___                                     ; 5BB8 row 28
    R   ___                                     ; 5BB9 row 29
    RI  C_3, 9, 0                               ; 5BBA row 30  Inst08
    R   ___                                     ; 5BBC row 31
Track030:
    R   ___                                     ; 5BBD row 00
    RI  C_3, 15, 1                              ; 5BBE row 01  Inst14
    R   ___                                     ; 5BC0 row 02
    R   ___                                     ; 5BC1 row 03
    R   ___                                     ; 5BC2 row 04
    R   ___                                     ; 5BC3 row 05
    RI  C_3, 15, 1                              ; 5BC4 row 06  Inst14
    R   ___                                     ; 5BC6 row 07
    R   ___                                     ; 5BC7 row 08
    R   ___                                     ; 5BC8 row 09
    R   ___                                     ; 5BC9 row 10
    R   ___                                     ; 5BCA row 11
    R   ___                                     ; 5BCB row 12
    R   ___                                     ; 5BCC row 13
    R   ___                                     ; 5BCD row 14
    R   ___                                     ; 5BCE row 15
    R   ___                                     ; 5BCF row 16
    R   ___                                     ; 5BD0 row 17
    RI  F_3, 6, 0                               ; 5BD1 row 18  Inst05
    R   ___                                     ; 5BD3 row 19
    RI  F_3, 6, 1                               ; 5BD4 row 20  Inst05
    R   ___                                     ; 5BD6 row 21
    R   ___                                     ; 5BD7 row 22
    R   ___                                     ; 5BD8 row 23
    RI  F_3, 6, 0                               ; 5BD9 row 24  Inst05
    R   ___                                     ; 5BDB row 25
    RI  F_3, 6, 1                               ; 5BDC row 26  Inst05
    R   ___                                     ; 5BDE row 27
    RI  F_3, 6, 0                               ; 5BDF row 28  Inst05
    R   ___                                     ; 5BE1 row 29
    RI  F_3, 6, 1                               ; 5BE2 row 30  Inst05
    R   ___                                     ; 5BE4 row 31
Track031:
    RIF C_3, 15, 0, $F, $5                      ; 5BE5 row 00  Inst14  speed 5
    R   ___                                     ; 5BE8 row 01
    R   ___                                     ; 5BE9 row 02
    R   ___                                     ; 5BEA row 03
    R   ___                                     ; 5BEB row 04
    R   ___                                     ; 5BEC row 05
    R   ___                                     ; 5BED row 06
    R   ___                                     ; 5BEE row 07
    R   ___                                     ; 5BEF row 08
    R   ___                                     ; 5BF0 row 09
    R   ___                                     ; 5BF1 row 10
    R   ___                                     ; 5BF2 row 11
    R   ___                                     ; 5BF3 row 12
    R   ___                                     ; 5BF4 row 13
    R   ___                                     ; 5BF5 row 14
    R   ___                                     ; 5BF6 row 15
    R   ___                                     ; 5BF7 row 16
    R   ___                                     ; 5BF8 row 17
    RI  F_2, 1, 0                               ; 5BF9 row 18  Inst00
    R   ___                                     ; 5BFB row 19
    R   ___                                     ; 5BFC row 20
    R   ___                                     ; 5BFD row 21
    R   ___                                     ; 5BFE row 22
    R   ___                                     ; 5BFF row 23
    RI  F_2, 1, 0                               ; 5C00 row 24  Inst00
    R   ___                                     ; 5C02 row 25
    R   ___                                     ; 5C03 row 26
    R   ___                                     ; 5C04 row 27
    RI  F_2, 1, 0                               ; 5C05 row 28  Inst00
    R   ___                                     ; 5C07 row 29
    R   ___                                     ; 5C08 row 30
    R   ___                                     ; 5C09 row 31
Track032:
    RI  C_3, 11, 0                              ; 5C0A row 00  Inst10
    R   ___                                     ; 5C0C row 01
    R   ___                                     ; 5C0D row 02
    R   ___                                     ; 5C0E row 03
    RI  C_3, 11, 0                              ; 5C0F row 04  Inst10
    R   ___                                     ; 5C11 row 05
    RI  C_3, 11, 0                              ; 5C12 row 06  Inst10
    R   ___                                     ; 5C14 row 07
    RI  C_6, 9, 0                               ; 5C15 row 08  Inst08
    R   ___                                     ; 5C17 row 09
    R   ___                                     ; 5C18 row 10
    R   ___                                     ; 5C19 row 11
    RI  C_3, 11, 0                              ; 5C1A row 12  Inst10
    R   ___                                     ; 5C1C row 13
    RI  C_3, 11, 0                              ; 5C1D row 14  Inst10
    R   ___                                     ; 5C1F row 15
    RI  C_3, 11, 0                              ; 5C20 row 16  Inst10
    R   ___                                     ; 5C22 row 17
    RI  C_3, 11, 0                              ; 5C23 row 18  Inst10
    R   ___                                     ; 5C25 row 19
    R   ___                                     ; 5C26 row 20
    R   ___                                     ; 5C27 row 21
    RI  C_3, 11, 0                              ; 5C28 row 22  Inst10
    R   ___                                     ; 5C2A row 23
    RI  C_3, 9, 0                               ; 5C2B row 24  Inst08
    R   ___                                     ; 5C2D row 25
    R   ___                                     ; 5C2E row 26
    R   ___                                     ; 5C2F row 27
    RI  C_3, 9, 0                               ; 5C30 row 28  Inst08
    R   ___                                     ; 5C32 row 29
    R   ___                                     ; 5C33 row 30
    R   ___                                     ; 5C34 row 31
Track033:
    RI  G_2, 10, 0                              ; 5C35 row 00  Inst09
    R   ___                                     ; 5C37 row 01
    R   ___                                     ; 5C38 row 02
    RI  ___, 0, 0                               ; 5C39 row 03
    RI  G_3, 10, 0                              ; 5C3B row 04  Inst09
    RI  ___, 0, 0                               ; 5C3D row 05
    RI  G_2, 10, 0                              ; 5C3F row 06  Inst09
    RI  ___, 0, 0                               ; 5C41 row 07
    RI  C_4, 8, 0                               ; 5C43 row 08  Inst07
    R   ___                                     ; 5C45 row 09
    R   ___                                     ; 5C46 row 10
    R   ___                                     ; 5C47 row 11
    RI  G_3, 10, 0                              ; 5C48 row 12  Inst09
    RI  ___, 0, 0                               ; 5C4A row 13
    RI  G_2, 10, 0                              ; 5C4C row 14  Inst09
    RI  ___, 0, 0                               ; 5C4E row 15
    RI  F_2, 10, 0                              ; 5C50 row 16  Inst09
    RI  ___, 0, 0                               ; 5C52 row 17
    RI  G_2, 10, 0                              ; 5C54 row 18  Inst09
    R   ___                                     ; 5C56 row 19
    R   ___                                     ; 5C57 row 20
    RI  ___, 0, 0                               ; 5C58 row 21
    RI  G_2, 10, 0                              ; 5C5A row 22  Inst09
    RI  ___, 0, 0                               ; 5C5C row 23
    RI  C_4, 8, 0                               ; 5C5E row 24  Inst07
    R   ___                                     ; 5C60 row 25
    R   ___                                     ; 5C61 row 26
    R   ___                                     ; 5C62 row 27
    RI  C_3, 8, 0                               ; 5C63 row 28  Inst07
    R   ___                                     ; 5C65 row 29
    RI  G_2, 10, 0                              ; 5C66 row 30  Inst09
    R   ___                                     ; 5C68 row 31
Track034:
    RI  C_4, 12, 0                              ; 5C69 row 00  Inst11
    R   ___                                     ; 5C6B row 01
    R   ___                                     ; 5C6C row 02
    R   ___                                     ; 5C6D row 03
    R   ___                                     ; 5C6E row 04
    R   ___                                     ; 5C6F row 05
    R   ___                                     ; 5C70 row 06
    R   ___                                     ; 5C71 row 07
    R   ___                                     ; 5C72 row 08
    R   ___                                     ; 5C73 row 09
    R   ___                                     ; 5C74 row 10
    R   ___                                     ; 5C75 row 11
    R   ___                                     ; 5C76 row 12
    R   ___                                     ; 5C77 row 13
    R   ___                                     ; 5C78 row 14
    R   ___                                     ; 5C79 row 15
    R   ___                                     ; 5C7A row 16
    R   ___                                     ; 5C7B row 17
    R   ___                                     ; 5C7C row 18
    R   ___                                     ; 5C7D row 19
    R   ___                                     ; 5C7E row 20
    R   ___                                     ; 5C7F row 21
    R   ___                                     ; 5C80 row 22
    R   ___                                     ; 5C81 row 23
    R   ___                                     ; 5C82 row 24
    R   ___                                     ; 5C83 row 25
    R   ___                                     ; 5C84 row 26
    R   ___                                     ; 5C85 row 27
    R   ___                                     ; 5C86 row 28
    R   ___                                     ; 5C87 row 29
    R   ___                                     ; 5C88 row 30
    R   ___                                     ; 5C89 row 31
Track035:
    RI  D_2, 15, 0                              ; 5C8A row 00  Inst14
    R   ___                                     ; 5C8C row 01
    R   ___                                     ; 5C8D row 02
    R   ___                                     ; 5C8E row 03
    R   ___                                     ; 5C8F row 04
    R   ___                                     ; 5C90 row 05
    R   ___                                     ; 5C91 row 06
    R   ___                                     ; 5C92 row 07
    R   ___                                     ; 5C93 row 08
    R   ___                                     ; 5C94 row 09
    RI  G_4, 1, 0                               ; 5C95 row 10  Inst00
    R   ___                                     ; 5C97 row 11
    R   ___                                     ; 5C98 row 12
    R   ___                                     ; 5C99 row 13
    RI  G_3, 1, 0                               ; 5C9A row 14  Inst00
    R   ___                                     ; 5C9C row 15
    R   ___                                     ; 5C9D row 16
    R   ___                                     ; 5C9E row 17
    RI  G_3, 1, 0                               ; 5C9F row 18  Inst00
    R   ___                                     ; 5CA1 row 19
    R   ___                                     ; 5CA2 row 20
    R   ___                                     ; 5CA3 row 21
    RI  G_4, 1, 0                               ; 5CA4 row 22  Inst00
    R   ___                                     ; 5CA6 row 23
    R   ___                                     ; 5CA7 row 24
    R   ___                                     ; 5CA8 row 25
    RI  G_4, 1, 0                               ; 5CA9 row 26  Inst00
    R   ___                                     ; 5CAB row 27
    R   ___                                     ; 5CAC row 28
    R   ___                                     ; 5CAD row 29
    RI  G_3, 1, 0                               ; 5CAE row 30  Inst00
    R   ___                                     ; 5CB0 row 31
Track036:
    RIF D_3, 1, 0, $F, $A                       ; 5CB1 row 00  Inst00  speed 10
    R   ___                                     ; 5CB4 row 01
    RI  G_3, 1, 0                               ; 5CB5 row 02  Inst00
    R   ___                                     ; 5CB7 row 03
    RI  D_4, 1, 0                               ; 5CB8 row 04  Inst00
    R   ___                                     ; 5CBA row 05
    RI  G_4, 1, 0                               ; 5CBB row 06  Inst00
    R   ___                                     ; 5CBD row 07
    RI  D_5, 1, 0                               ; 5CBE row 08  Inst00
    R   ___                                     ; 5CC0 row 09
    R   ___                                     ; 5CC1 row 10
    R   ___                                     ; 5CC2 row 11
    RI  D_4, 1, 0                               ; 5CC3 row 12  Inst00
    R   ___                                     ; 5CC5 row 13
    R   ___                                     ; 5CC6 row 14
    R   ___                                     ; 5CC7 row 15
    RI  D_3, 1, 0                               ; 5CC8 row 16  Inst00
    R   ___                                     ; 5CCA row 17
    R   ___                                     ; 5CCB row 18
    R   ___                                     ; 5CCC row 19
    RI  C_4, 1, 0                               ; 5CCD row 20  Inst00
    R   ___                                     ; 5CCF row 21
    R   ___                                     ; 5CD0 row 22
    R   ___                                     ; 5CD1 row 23
    RI  C_5, 1, 0                               ; 5CD2 row 24  Inst00
    R   ___                                     ; 5CD4 row 25
    R   ___                                     ; 5CD5 row 26
    R   ___                                     ; 5CD6 row 27
    RI  C_4, 1, 0                               ; 5CD7 row 28  Inst00
    R   ___                                     ; 5CD9 row 29
    R   ___                                     ; 5CDA row 30
    R   ___                                     ; 5CDB row 31
Track037:
    RI  G_2, 6, 0                               ; 5CDC row 00  Inst05
    R   ___                                     ; 5CDE row 01
    R   ___                                     ; 5CDF row 02
    R   ___                                     ; 5CE0 row 03
    R   ___                                     ; 5CE1 row 04
    R   ___                                     ; 5CE2 row 05
    RI  G_2, 6, 1                               ; 5CE3 row 06  Inst05
    R   ___                                     ; 5CE5 row 07
    R   ___                                     ; 5CE6 row 08
    R   ___                                     ; 5CE7 row 09
    R   ___                                     ; 5CE8 row 10
    R   ___                                     ; 5CE9 row 11
    R   ___                                     ; 5CEA row 12
    R   ___                                     ; 5CEB row 13
    RI  C_3, 14, 0                              ; 5CEC row 14  Inst13
    R   ___                                     ; 5CEE row 15
    R   ___                                     ; 5CEF row 16
    R   ___                                     ; 5CF0 row 17
    R   ___                                     ; 5CF1 row 18
    R   ___                                     ; 5CF2 row 19
    R   ___                                     ; 5CF3 row 20
    R   ___                                     ; 5CF4 row 21
    R   ___                                     ; 5CF5 row 22
    R   ___                                     ; 5CF6 row 23
    R   ___                                     ; 5CF7 row 24
    R   ___                                     ; 5CF8 row 25
    R   ___                                     ; 5CF9 row 26
    R   ___                                     ; 5CFA row 27
    R   ___                                     ; 5CFB row 28
    R   ___                                     ; 5CFC row 29
    R   ___                                     ; 5CFD row 30
    R   ___                                     ; 5CFE row 31
Track038:
    RIF Ds4, 16, 0, $F, $A                      ; 5CFF row 00  Inst15  speed 10
    R   ___                                     ; 5D02 row 01
    RI  D_4, 16, 0                              ; 5D03 row 02  Inst15
    R   ___                                     ; 5D05 row 03
    RI  As3, 16, 0                              ; 5D06 row 04  Inst15
    R   ___                                     ; 5D08 row 05
    RI  G_3, 16, 0                              ; 5D09 row 06  Inst15
    R   ___                                     ; 5D0B row 07
    RI  Ds3, 16, 0                              ; 5D0C row 08  Inst15
    R   ___                                     ; 5D0E row 09
    RI  D_3, 16, 0                              ; 5D0F row 10  Inst15
    R   ___                                     ; 5D11 row 11
    RI  As2, 16, 0                              ; 5D12 row 12  Inst15
    R   ___                                     ; 5D14 row 13
    RI  G_2, 16, 0                              ; 5D15 row 14  Inst15
    R   ___                                     ; 5D17 row 15
    RI  Gs3, 16, 0                              ; 5D18 row 16  Inst15
    R   ___                                     ; 5D1A row 17
    RI  G_3, 16, 0                              ; 5D1B row 18  Inst15
    R   ___                                     ; 5D1D row 19
    RI  Ds3, 16, 0                              ; 5D1E row 20  Inst15
    R   ___                                     ; 5D20 row 21
    RI  C_3, 16, 0                              ; 5D21 row 22  Inst15
    R   ___                                     ; 5D23 row 23
    RI  Gs2, 16, 0                              ; 5D24 row 24  Inst15
    R   ___                                     ; 5D26 row 25
    RI  G_2, 16, 0                              ; 5D27 row 26  Inst15
    R   ___                                     ; 5D29 row 27
    RI  Ds2, 16, 0                              ; 5D2A row 28  Inst15
    R   ___                                     ; 5D2C row 29
    RI  C_2, 16, 0                              ; 5D2D row 30  Inst15
    R   ___                                     ; 5D2F row 31
Track039:
    RI  C_3, 2, 0                               ; 5D30 row 00  Inst01
    R   ___                                     ; 5D32 row 01
    R   ___                                     ; 5D33 row 02
    R   ___                                     ; 5D34 row 03
    R   ___                                     ; 5D35 row 04
    R   ___                                     ; 5D36 row 05
    R   ___                                     ; 5D37 row 06
    R   ___                                     ; 5D38 row 07
    R   ___                                     ; 5D39 row 08
    R   ___                                     ; 5D3A row 09
    R   ___                                     ; 5D3B row 10
    R   ___                                     ; 5D3C row 11
    R   ___                                     ; 5D3D row 12
    R   ___                                     ; 5D3E row 13
    R   ___                                     ; 5D3F row 14
    R   ___                                     ; 5D40 row 15
    RI  Gs2, 2, 0                               ; 5D41 row 16  Inst01
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
Track040:
    RI  C_3, 17, 0                              ; 5D52 row 00  Inst16
    R   ___                                     ; 5D54 row 01
    R   ___                                     ; 5D55 row 02
    R   ___                                     ; 5D56 row 03
    R   ___                                     ; 5D57 row 04
    R   ___                                     ; 5D58 row 05
    R   ___                                     ; 5D59 row 06
    R   ___                                     ; 5D5A row 07
    RI  C_3, 17, 0                              ; 5D5B row 08  Inst16
    R   ___                                     ; 5D5D row 09
    R   ___                                     ; 5D5E row 10
    R   ___                                     ; 5D5F row 11
    R   ___                                     ; 5D60 row 12
    R   ___                                     ; 5D61 row 13
    R   ___                                     ; 5D62 row 14
    R   ___                                     ; 5D63 row 15
    RI  C_3, 18, 0                              ; 5D64 row 16  Inst17
    R   ___                                     ; 5D66 row 17
    R   ___                                     ; 5D67 row 18
    R   ___                                     ; 5D68 row 19
    R   ___                                     ; 5D69 row 20
    R   ___                                     ; 5D6A row 21
    R   ___                                     ; 5D6B row 22
    R   ___                                     ; 5D6C row 23
    RI  C_3, 18, 0                              ; 5D6D row 24  Inst17
    R   ___                                     ; 5D6F row 25
    R   ___                                     ; 5D70 row 26
    R   ___                                     ; 5D71 row 27
    R   ___                                     ; 5D72 row 28
    R   ___                                     ; 5D73 row 29
    R   ___                                     ; 5D74 row 30
    R   ___                                     ; 5D75 row 31
Track041:
    RI  F_3, 2, 0                               ; 5D76 row 00  Inst01
    R   ___                                     ; 5D78 row 01
    R   ___                                     ; 5D79 row 02
    R   ___                                     ; 5D7A row 03
    R   ___                                     ; 5D7B row 04
    R   ___                                     ; 5D7C row 05
    R   ___                                     ; 5D7D row 06
    R   ___                                     ; 5D7E row 07
    R   ___                                     ; 5D7F row 08
    R   ___                                     ; 5D80 row 09
    R   ___                                     ; 5D81 row 10
    R   ___                                     ; 5D82 row 11
    R   ___                                     ; 5D83 row 12
    R   ___                                     ; 5D84 row 13
    R   ___                                     ; 5D85 row 14
    R   ___                                     ; 5D86 row 15
    RI  As2, 2, 0                               ; 5D87 row 16  Inst01
    R   ___                                     ; 5D89 row 17
    R   ___                                     ; 5D8A row 18
    R   ___                                     ; 5D8B row 19
    R   ___                                     ; 5D8C row 20
    R   ___                                     ; 5D8D row 21
    R   ___                                     ; 5D8E row 22
    R   ___                                     ; 5D8F row 23
    RI  B_2, 2, 0                               ; 5D90 row 24  Inst01
    R   ___                                     ; 5D92 row 25
    R   ___                                     ; 5D93 row 26
    R   ___                                     ; 5D94 row 27
    R   ___                                     ; 5D95 row 28
    R   ___                                     ; 5D96 row 29
    R   ___                                     ; 5D97 row 30
    R   ___                                     ; 5D98 row 31
Track042:
    RI  C_3, 20, 0                              ; 5D99 row 00  Inst19
    R   ___                                     ; 5D9B row 01
    R   ___                                     ; 5D9C row 02
    R   ___                                     ; 5D9D row 03
    R   ___                                     ; 5D9E row 04
    R   ___                                     ; 5D9F row 05
    R   ___                                     ; 5DA0 row 06
    R   ___                                     ; 5DA1 row 07
    RI  C_3, 20, 0                              ; 5DA2 row 08  Inst19
    R   ___                                     ; 5DA4 row 09
    R   ___                                     ; 5DA5 row 10
    R   ___                                     ; 5DA6 row 11
    R   ___                                     ; 5DA7 row 12
    R   ___                                     ; 5DA8 row 13
    R   ___                                     ; 5DA9 row 14
    R   ___                                     ; 5DAA row 15
    RI  D_3, 20, 0                              ; 5DAB row 16  Inst19
    R   ___                                     ; 5DAD row 17
    R   ___                                     ; 5DAE row 18
    R   ___                                     ; 5DAF row 19
    R   ___                                     ; 5DB0 row 20
    R   ___                                     ; 5DB1 row 21
    R   ___                                     ; 5DB2 row 22
    R   ___                                     ; 5DB3 row 23
    RI  C_2, 24, 0                              ; 5DB4 row 24  Inst23
    R   ___                                     ; 5DB6 row 25
    R   ___                                     ; 5DB7 row 26
    R   ___                                     ; 5DB8 row 27
    R   ___                                     ; 5DB9 row 28
    R   ___                                     ; 5DBA row 29
    R   ___                                     ; 5DBB row 30
    R   ___                                     ; 5DBC row 31
Track043:
    RI  Gs3, 16, 0                              ; 5DBD row 00  Inst15
    R   ___                                     ; 5DBF row 01
    RI  As3, 16, 0                              ; 5DC0 row 02  Inst15
    R   ___                                     ; 5DC2 row 03
    RI  C_4, 16, 0                              ; 5DC3 row 04  Inst15
    R   ___                                     ; 5DC5 row 05
    RI  Ds4, 16, 0                              ; 5DC6 row 06  Inst15
    R   ___                                     ; 5DC8 row 07
    RI  Gs2, 16, 0                              ; 5DC9 row 08  Inst15
    R   ___                                     ; 5DCB row 09
    RI  As2, 16, 0                              ; 5DCC row 10  Inst15
    R   ___                                     ; 5DCE row 11
    RI  C_3, 16, 0                              ; 5DCF row 12  Inst15
    R   ___                                     ; 5DD1 row 13
    RI  Ds3, 16, 0                              ; 5DD2 row 14  Inst15
    R   ___                                     ; 5DD4 row 15
    RI  As3, 16, 0                              ; 5DD5 row 16  Inst15
    R   ___                                     ; 5DD7 row 17
    RI  D_4, 16, 0                              ; 5DD8 row 18  Inst15
    R   ___                                     ; 5DDA row 19
    RI  F_4, 16, 0                              ; 5DDB row 20  Inst15
    R   ___                                     ; 5DDD row 21
    RI  As4, 16, 0                              ; 5DDE row 22  Inst15
    R   ___                                     ; 5DE0 row 23
    RI  B_2, 16, 0                              ; 5DE1 row 24  Inst15
    R   ___                                     ; 5DE3 row 25
    RI  D_3, 16, 0                              ; 5DE4 row 26  Inst15
    R   ___                                     ; 5DE6 row 27
    RI  F_3, 16, 0                              ; 5DE7 row 28  Inst15
    R   ___                                     ; 5DE9 row 29
    RI  B_3, 16, 0                              ; 5DEA row 30  Inst15
    R   ___                                     ; 5DEC row 31
Track044:
    RI  C_3, 21, 0                              ; 5DED row 00  Inst20
    R   ___                                     ; 5DEF row 01
    R   ___                                     ; 5DF0 row 02
    R   ___                                     ; 5DF1 row 03
    R   ___                                     ; 5DF2 row 04
    R   ___                                     ; 5DF3 row 05
    R   ___                                     ; 5DF4 row 06
    R   ___                                     ; 5DF5 row 07
    RI  C_3, 21, 0                              ; 5DF6 row 08  Inst20
    R   ___                                     ; 5DF8 row 09
    R   ___                                     ; 5DF9 row 10
    R   ___                                     ; 5DFA row 11
    R   ___                                     ; 5DFB row 12
    R   ___                                     ; 5DFC row 13
    R   ___                                     ; 5DFD row 14
    R   ___                                     ; 5DFE row 15
    RI  C_3, 21, 0                              ; 5DFF row 16  Inst20
    R   ___                                     ; 5E01 row 17
    R   ___                                     ; 5E02 row 18
    R   ___                                     ; 5E03 row 19
    R   ___                                     ; 5E04 row 20
    R   ___                                     ; 5E05 row 21
    R   ___                                     ; 5E06 row 22
    R   ___                                     ; 5E07 row 23
    RI  C_3, 21, 0                              ; 5E08 row 24  Inst20
    R   ___                                     ; 5E0A row 25
    R   ___                                     ; 5E0B row 26
    R   ___                                     ; 5E0C row 27
    RI  C_5, 22, 0                              ; 5E0D row 28  Inst21
    R   ___                                     ; 5E0F row 29
    RI  G_3, 22, 0                              ; 5E10 row 30  Inst21
    R   ___                                     ; 5E12 row 31
Track045:
    RI  G_4, 3, 0                               ; 5E13 row 00  Inst02
    R   ___                                     ; 5E15 row 01
    R   ___                                     ; 5E16 row 02
    R   ___                                     ; 5E17 row 03
    R   ___                                     ; 5E18 row 04
    R   ___                                     ; 5E19 row 05
    R   ___                                     ; 5E1A row 06
    R   ___                                     ; 5E1B row 07
    R   ___                                     ; 5E1C row 08
    R   ___                                     ; 5E1D row 09
    R   ___                                     ; 5E1E row 10
    R   ___                                     ; 5E1F row 11
    R   ___                                     ; 5E20 row 12
    R   ___                                     ; 5E21 row 13
    R   ___                                     ; 5E22 row 14
    R   ___                                     ; 5E23 row 15
    RI  Gs4, 19, 0                              ; 5E24 row 16  Inst18
    R   ___                                     ; 5E26 row 17
    R   ___                                     ; 5E27 row 18
    R   ___                                     ; 5E28 row 19
    R   ___                                     ; 5E29 row 20
    R   ___                                     ; 5E2A row 21
    R   ___                                     ; 5E2B row 22
    R   ___                                     ; 5E2C row 23
    RI  Ds4, 19, 0                              ; 5E2D row 24  Inst18
    R   ___                                     ; 5E2F row 25
    R   ___                                     ; 5E30 row 26
    R   ___                                     ; 5E31 row 27
    R   ___                                     ; 5E32 row 28
    R   ___                                     ; 5E33 row 29
    RI  F_4, 19, 0                              ; 5E34 row 30  Inst18
    R   ___                                     ; 5E36 row 31
Track046:
    RI  Ds4, 19, 0                              ; 5E37 row 00  Inst18
    R   ___                                     ; 5E39 row 01
    R   ___                                     ; 5E3A row 02
    R   ___                                     ; 5E3B row 03
    R   ___                                     ; 5E3C row 04
    R   ___                                     ; 5E3D row 05
    RI  C_4, 19, 0                              ; 5E3E row 06  Inst18
    RI  Ds4, 19, 0                              ; 5E40 row 07  Inst18
    RI  Gs4, 19, 0                              ; 5E42 row 08  Inst18
    R   ___                                     ; 5E44 row 09
    R   ___                                     ; 5E45 row 10
    RI  G_4, 19, 0                              ; 5E46 row 11  Inst18
    R   ___                                     ; 5E48 row 12
    R   ___                                     ; 5E49 row 13
    RI  Ds4, 19, 0                              ; 5E4A row 14  Inst18
    R   ___                                     ; 5E4C row 15
    RI  F_4, 19, 0                              ; 5E4D row 16  Inst18
    R   ___                                     ; 5E4F row 17
    R   ___                                     ; 5E50 row 18
    R   ___                                     ; 5E51 row 19
    R   ___                                     ; 5E52 row 20
    R   ___                                     ; 5E53 row 21
    R   ___                                     ; 5E54 row 22
    R   ___                                     ; 5E55 row 23
    RI  B_3, 19, 0                              ; 5E56 row 24  Inst18
    R   ___                                     ; 5E58 row 25
    R   ___                                     ; 5E59 row 26
    R   ___                                     ; 5E5A row 27
    RI  G_3, 19, 0                              ; 5E5B row 28  Inst18
    R   ___                                     ; 5E5D row 29
    R   ___                                     ; 5E5E row 30
    R   ___                                     ; 5E5F row 31
Track047:
    RI  G_4, 19, 0                              ; 5E60 row 00  Inst18
    R   F_4                                     ; 5E62 row 01
    R   G_4                                     ; 5E63 row 02
    R   ___                                     ; 5E64 row 03
    R   ___                                     ; 5E65 row 04
    R   ___                                     ; 5E66 row 05
    R   ___                                     ; 5E67 row 06
    R   ___                                     ; 5E68 row 07
    R   ___                                     ; 5E69 row 08
    R   ___                                     ; 5E6A row 09
    R   ___                                     ; 5E6B row 10
    R   ___                                     ; 5E6C row 11
    R   ___                                     ; 5E6D row 12
    R   ___                                     ; 5E6E row 13
    R   ___                                     ; 5E6F row 14
    R   ___                                     ; 5E70 row 15
    RI  C_5, 19, 0                              ; 5E71 row 16  Inst18
    R   ___                                     ; 5E73 row 17
    R   ___                                     ; 5E74 row 18
    R   ___                                     ; 5E75 row 19
    R   ___                                     ; 5E76 row 20
    R   ___                                     ; 5E77 row 21
    R   ___                                     ; 5E78 row 22
    R   ___                                     ; 5E79 row 23
    RI  Gs4, 19, 0                              ; 5E7A row 24  Inst18
    R   ___                                     ; 5E7C row 25
    R   ___                                     ; 5E7D row 26
    R   ___                                     ; 5E7E row 27
    R   ___                                     ; 5E7F row 28
    R   ___                                     ; 5E80 row 29
    RI  C_4, 19, 0                              ; 5E81 row 30  Inst18
    RI  D_4, 19, 0                              ; 5E83 row 31  Inst18
Track048:
    RI  C_3, 19, 0                              ; 5E85 row 00  Inst18
    R   ___                                     ; 5E87 row 01
    R   ___                                     ; 5E88 row 02
    R   ___                                     ; 5E89 row 03
    R   ___                                     ; 5E8A row 04
    R   ___                                     ; 5E8B row 05
    R   ___                                     ; 5E8C row 06
    R   ___                                     ; 5E8D row 07
    R   ___                                     ; 5E8E row 08
    R   ___                                     ; 5E8F row 09
    R   ___                                     ; 5E90 row 10
    R   ___                                     ; 5E91 row 11
    R   ___                                     ; 5E92 row 12
    R   ___                                     ; 5E93 row 13
    R   ___                                     ; 5E94 row 14
    R   ___                                     ; 5E95 row 15
    RI  Gs2, 3, 0                               ; 5E96 row 16  Inst02
    R   ___                                     ; 5E98 row 17
    R   ___                                     ; 5E99 row 18
    R   ___                                     ; 5E9A row 19
    R   ___                                     ; 5E9B row 20
    R   ___                                     ; 5E9C row 21
    R   ___                                     ; 5E9D row 22
    R   ___                                     ; 5E9E row 23
    R   ___                                     ; 5E9F row 24
    R   ___                                     ; 5EA0 row 25
    R   ___                                     ; 5EA1 row 26
    R   ___                                     ; 5EA2 row 27
    R   ___                                     ; 5EA3 row 28
    R   ___                                     ; 5EA4 row 29
    R   ___                                     ; 5EA5 row 30
    R   ___                                     ; 5EA6 row 31
Track049:
    RIF C_3, 26, 0, $F, $A                      ; 5EA7 row 00  Inst25  speed 10
    R   ___                                     ; 5EAA row 01
    R   ___                                     ; 5EAB row 02
    R   ___                                     ; 5EAC row 03
    R   ___                                     ; 5EAD row 04
    R   ___                                     ; 5EAE row 05
    R   ___                                     ; 5EAF row 06
    R   ___                                     ; 5EB0 row 07
    RI  C_3, 27, 0                              ; 5EB1 row 08  Inst26
    R   ___                                     ; 5EB3 row 09
    R   ___                                     ; 5EB4 row 10
    R   ___                                     ; 5EB5 row 11
    R   ___                                     ; 5EB6 row 12
    R   ___                                     ; 5EB7 row 13
    R   ___                                     ; 5EB8 row 14
    R   ___                                     ; 5EB9 row 15
    RI  C_3, 26, 0                              ; 5EBA row 16  Inst25
    R   ___                                     ; 5EBC row 17
    R   ___                                     ; 5EBD row 18
    R   ___                                     ; 5EBE row 19
    R   ___                                     ; 5EBF row 20
    R   ___                                     ; 5EC0 row 21
    R   ___                                     ; 5EC1 row 22
    R   ___                                     ; 5EC2 row 23
    RI  C_3, 28, 0                              ; 5EC3 row 24  Inst27
    R   ___                                     ; 5EC5 row 25
    R   ___                                     ; 5EC6 row 26
    R   ___                                     ; 5EC7 row 27
    R   ___                                     ; 5EC8 row 28
    R   ___                                     ; 5EC9 row 29
    R   ___                                     ; 5ECA row 30
    R   ___                                     ; 5ECB row 31
Track050:
    RI  C_3, 2, 0                               ; 5ECC row 00  Inst01
    R   ___                                     ; 5ECE row 01
    R   ___                                     ; 5ECF row 02
    R   ___                                     ; 5ED0 row 03
    R   ___                                     ; 5ED1 row 04
    R   ___                                     ; 5ED2 row 05
    R   ___                                     ; 5ED3 row 06
    R   ___                                     ; 5ED4 row 07
    RI  D_3, 2, 0                               ; 5ED5 row 08  Inst01
    R   ___                                     ; 5ED7 row 09
    R   ___                                     ; 5ED8 row 10
    R   ___                                     ; 5ED9 row 11
    R   ___                                     ; 5EDA row 12
    R   ___                                     ; 5EDB row 13
    R   ___                                     ; 5EDC row 14
    R   ___                                     ; 5EDD row 15
    RI  Ds3, 2, 0                               ; 5EDE row 16  Inst01
    R   ___                                     ; 5EE0 row 17
    R   ___                                     ; 5EE1 row 18
    R   ___                                     ; 5EE2 row 19
    R   ___                                     ; 5EE3 row 20
    R   ___                                     ; 5EE4 row 21
    R   ___                                     ; 5EE5 row 22
    R   ___                                     ; 5EE6 row 23
    RI  D_3, 2, 0                               ; 5EE7 row 24  Inst01
    R   ___                                     ; 5EE9 row 25
    R   ___                                     ; 5EEA row 26
    R   ___                                     ; 5EEB row 27
    R   ___                                     ; 5EEC row 28
    R   ___                                     ; 5EED row 29
    R   ___                                     ; 5EEE row 30
    R   ___                                     ; 5EEF row 31
Track051:
    RI  C_3, 16, 0                              ; 5EF0 row 00  Inst15
    R   ___                                     ; 5EF2 row 01
    R   ___                                     ; 5EF3 row 02
    R   ___                                     ; 5EF4 row 03
    RI  G_3, 16, 0                              ; 5EF5 row 04  Inst15
    R   ___                                     ; 5EF7 row 05
    R   ___                                     ; 5EF8 row 06
    R   ___                                     ; 5EF9 row 07
    RI  D_3, 16, 0                              ; 5EFA row 08  Inst15
    R   ___                                     ; 5EFC row 09
    R   ___                                     ; 5EFD row 10
    R   ___                                     ; 5EFE row 11
    RI  Fs3, 16, 0                              ; 5EFF row 12  Inst15
    R   ___                                     ; 5F01 row 13
    R   ___                                     ; 5F02 row 14
    R   ___                                     ; 5F03 row 15
    RI  Ds3, 16, 0                              ; 5F04 row 16  Inst15
    R   ___                                     ; 5F06 row 17
    R   ___                                     ; 5F07 row 18
    R   ___                                     ; 5F08 row 19
    RI  G_3, 16, 0                              ; 5F09 row 20  Inst15
    R   ___                                     ; 5F0B row 21
    R   ___                                     ; 5F0C row 22
    R   ___                                     ; 5F0D row 23
    RI  D_3, 16, 0                              ; 5F0E row 24  Inst15
    R   ___                                     ; 5F10 row 25
    R   ___                                     ; 5F11 row 26
    R   ___                                     ; 5F12 row 27
    RI  Fs3, 16, 0                              ; 5F13 row 28  Inst15
    R   ___                                     ; 5F15 row 29
    R   ___                                     ; 5F16 row 30
    R   ___                                     ; 5F17 row 31
Track052:
    RI  C_3, 11, 0                              ; 5F18 row 00  Inst10
    R   ___                                     ; 5F1A row 01
    RI  C_3, 11, 1                              ; 5F1B row 02  Inst10
    R   ___                                     ; 5F1D row 03
    RI  C_3, 11, 0                              ; 5F1E row 04  Inst10
    R   ___                                     ; 5F20 row 05
    RI  C_3, 11, 1                              ; 5F21 row 06  Inst10
    R   ___                                     ; 5F23 row 07
    RI  C_3, 11, 0                              ; 5F24 row 08  Inst10
    R   ___                                     ; 5F26 row 09
    RI  C_3, 11, 1                              ; 5F27 row 10  Inst10
    R   ___                                     ; 5F29 row 11
    RI  C_3, 11, 0                              ; 5F2A row 12  Inst10
    R   ___                                     ; 5F2C row 13
    RI  C_3, 11, 1                              ; 5F2D row 14  Inst10
    R   ___                                     ; 5F2F row 15
    RI  C_3, 11, 0                              ; 5F30 row 16  Inst10
    R   ___                                     ; 5F32 row 17
    RI  C_3, 11, 1                              ; 5F33 row 18  Inst10
    R   ___                                     ; 5F35 row 19
    RI  C_3, 11, 0                              ; 5F36 row 20  Inst10
    R   ___                                     ; 5F38 row 21
    RI  C_3, 11, 1                              ; 5F39 row 22  Inst10
    R   ___                                     ; 5F3B row 23
    RI  C_3, 11, 0                              ; 5F3C row 24  Inst10
    R   ___                                     ; 5F3E row 25
    RI  C_3, 11, 1                              ; 5F3F row 26  Inst10
    R   ___                                     ; 5F41 row 27
    RI  C_3, 11, 0                              ; 5F42 row 28  Inst10
    R   ___                                     ; 5F44 row 29
    RI  C_3, 11, 1                              ; 5F45 row 30  Inst10
    R   ___                                     ; 5F47 row 31
Track053:
    RI  C_4, 1, 0                               ; 5F48 row 00  Inst00
    RI  C_5, 1, 1                               ; 5F4A row 01  Inst00
    RI  C_4, 1, 1                               ; 5F4C row 02  Inst00
    R   ___                                     ; 5F4E row 03
    RI  G_4, 1, 0                               ; 5F4F row 04  Inst00
    RI  C_4, 1, 1                               ; 5F51 row 05  Inst00
    RI  G_4, 1, 1                               ; 5F53 row 06  Inst00
    R   ___                                     ; 5F55 row 07
    RI  D_4, 1, 0                               ; 5F56 row 08  Inst00
    RI  D_5, 1, 1                               ; 5F58 row 09  Inst00
    RI  D_4, 1, 1                               ; 5F5A row 10  Inst00
    R   ___                                     ; 5F5C row 11
    RI  Fs4, 1, 0                               ; 5F5D row 12  Inst00
    RI  Fs5, 1, 1                               ; 5F5F row 13  Inst00
    RI  Fs4, 1, 1                               ; 5F61 row 14  Inst00
    R   ___                                     ; 5F63 row 15
    RI  Ds4, 1, 0                               ; 5F64 row 16  Inst00
    RI  Ds5, 1, 1                               ; 5F66 row 17  Inst00
    RI  Ds4, 1, 1                               ; 5F68 row 18  Inst00
    R   ___                                     ; 5F6A row 19
    RI  G_4, 1, 0                               ; 5F6B row 20  Inst00
    RI  G_5, 1, 1                               ; 5F6D row 21  Inst00
    RI  G_4, 1, 1                               ; 5F6F row 22  Inst00
    R   ___                                     ; 5F71 row 23
    RI  D_4, 1, 0                               ; 5F72 row 24  Inst00
    RI  D_5, 1, 1                               ; 5F74 row 25  Inst00
    RI  D_4, 1, 1                               ; 5F76 row 26  Inst00
    R   ___                                     ; 5F78 row 27
    RI  Fs4, 1, 0                               ; 5F79 row 28  Inst00
    RI  Fs5, 1, 1                               ; 5F7B row 29  Inst00
    RI  Fs4, 1, 1                               ; 5F7D row 30  Inst00
    R   ___                                     ; 5F7F row 31
Track054:
    RI  C_3, 10, 0                              ; 5F80 row 00  Inst09
    R   ___                                     ; 5F82 row 01
    RI  C_3, 10, 0                              ; 5F83 row 02  Inst09
    R   ___                                     ; 5F85 row 03
    RI  C_3, 8, 0                               ; 5F86 row 04  Inst07
    R   ___                                     ; 5F88 row 05
    RI  C_4, 10, 0                              ; 5F89 row 06  Inst09
    R   ___                                     ; 5F8B row 07
    RI  D_3, 10, 0                              ; 5F8C row 08  Inst09
    R   ___                                     ; 5F8E row 09
    RI  D_3, 10, 0                              ; 5F8F row 10  Inst09
    R   ___                                     ; 5F91 row 11
    RI  C_4, 8, 0                               ; 5F92 row 12  Inst07
    R   ___                                     ; 5F94 row 13
    RI  D_3, 10, 0                              ; 5F95 row 14  Inst09
    R   ___                                     ; 5F97 row 15
    RI  Ds3, 10, 0                              ; 5F98 row 16  Inst09
    R   ___                                     ; 5F9A row 17
    RI  Ds3, 10, 0                              ; 5F9B row 18  Inst09
    R   ___                                     ; 5F9D row 19
    RI  C_3, 8, 0                               ; 5F9E row 20  Inst07
    R   ___                                     ; 5FA0 row 21
    RI  Ds4, 10, 0                              ; 5FA1 row 22  Inst09
    R   ___                                     ; 5FA3 row 23
    RI  D_3, 10, 0                              ; 5FA4 row 24  Inst09
    R   ___                                     ; 5FA6 row 25
    RI  D_3, 10, 0                              ; 5FA7 row 26  Inst09
    R   ___                                     ; 5FA9 row 27
    RI  C_3, 8, 0                               ; 5FAA row 28  Inst07
    R   ___                                     ; 5FAC row 29
    RI  D_3, 10, 0                              ; 5FAD row 30  Inst09
    R   ___                                     ; 5FAF row 31
Track055:
    RI  C_3, 11, 0                              ; 5FB0 row 00  Inst10
    R   ___                                     ; 5FB2 row 01
    RI  C_3, 11, 0                              ; 5FB3 row 02  Inst10
    R   ___                                     ; 5FB5 row 03
    RI  C_4, 9, 0                               ; 5FB6 row 04  Inst08
    R   ___                                     ; 5FB8 row 05
    RI  C_3, 11, 0                              ; 5FB9 row 06  Inst10
    R   ___                                     ; 5FBB row 07
    RI  C_3, 11, 0                              ; 5FBC row 08  Inst10
    R   ___                                     ; 5FBE row 09
    RI  C_3, 11, 0                              ; 5FBF row 10  Inst10
    R   ___                                     ; 5FC1 row 11
    RI  C_4, 9, 0                               ; 5FC2 row 12  Inst08
    R   ___                                     ; 5FC4 row 13
    RI  C_3, 11, 0                              ; 5FC5 row 14  Inst10
    R   ___                                     ; 5FC7 row 15
    RI  C_3, 11, 0                              ; 5FC8 row 16  Inst10
    R   ___                                     ; 5FCA row 17
    RI  C_3, 11, 0                              ; 5FCB row 18  Inst10
    R   ___                                     ; 5FCD row 19
    RI  C_4, 9, 0                               ; 5FCE row 20  Inst08
    R   ___                                     ; 5FD0 row 21
    RI  C_3, 11, 0                              ; 5FD1 row 22  Inst10
    R   ___                                     ; 5FD3 row 23
    RI  C_3, 11, 0                              ; 5FD4 row 24  Inst10
    R   ___                                     ; 5FD6 row 25
    RI  C_3, 11, 0                              ; 5FD7 row 26  Inst10
    R   ___                                     ; 5FD9 row 27
    RI  C_4, 9, 0                               ; 5FDA row 28  Inst08
    R   ___                                     ; 5FDC row 29
    RI  C_3, 11, 0                              ; 5FDD row 30  Inst10
    R   ___                                     ; 5FDF row 31
Track056:
    RI  C_3, 10, 0                              ; 5FE0 row 00  Inst09
    R   ___                                     ; 5FE2 row 01
    RI  C_3, 10, 0                              ; 5FE3 row 02  Inst09
    R   ___                                     ; 5FE5 row 03
    RI  C_3, 8, 0                               ; 5FE6 row 04  Inst07
    R   ___                                     ; 5FE8 row 05
    RI  C_4, 10, 0                              ; 5FE9 row 06  Inst09
    R   ___                                     ; 5FEB row 07
    RI  D_3, 10, 0                              ; 5FEC row 08  Inst09
    R   ___                                     ; 5FEE row 09
    RI  D_3, 10, 0                              ; 5FEF row 10  Inst09
    R   ___                                     ; 5FF1 row 11
    RI  C_4, 8, 0                               ; 5FF2 row 12  Inst07
    R   ___                                     ; 5FF4 row 13
    RI  D_3, 10, 0                              ; 5FF5 row 14  Inst09
    R   ___                                     ; 5FF7 row 15
    RI  Ds3, 10, 0                              ; 5FF8 row 16  Inst09
    R   ___                                     ; 5FFA row 17
    RI  Ds3, 10, 0                              ; 5FFB row 18  Inst09
    R   ___                                     ; 5FFD row 19
    RI  C_3, 8, 0                               ; 5FFE row 20  Inst07
    R   ___                                     ; 6000 row 21
    RI  Ds4, 10, 0                              ; 6001 row 22  Inst09
    R   ___                                     ; 6003 row 23
    RI  D_3, 10, 0                              ; 6004 row 24  Inst09
    R   ___                                     ; 6006 row 25
    RI  D_3, 10, 0                              ; 6007 row 26  Inst09
    R   ___                                     ; 6009 row 27
    RI  C_3, 8, 0                               ; 600A row 28  Inst07
    R   ___                                     ; 600C row 29
    RI  C_3, 8, 0                               ; 600D row 30  Inst07
    R   ___                                     ; 600F row 31
Track057:
    RI  C_3, 11, 0                              ; 6010 row 00  Inst10
    R   ___                                     ; 6012 row 01
    RI  C_3, 11, 0                              ; 6013 row 02  Inst10
    R   ___                                     ; 6015 row 03
    RI  C_4, 9, 0                               ; 6016 row 04  Inst08
    R   ___                                     ; 6018 row 05
    RI  C_3, 11, 0                              ; 6019 row 06  Inst10
    R   ___                                     ; 601B row 07
    RI  C_3, 11, 0                              ; 601C row 08  Inst10
    R   ___                                     ; 601E row 09
    RI  C_3, 11, 0                              ; 601F row 10  Inst10
    R   ___                                     ; 6021 row 11
    RI  C_4, 9, 0                               ; 6022 row 12  Inst08
    R   ___                                     ; 6024 row 13
    RI  C_3, 11, 0                              ; 6025 row 14  Inst10
    R   ___                                     ; 6027 row 15
    RI  C_3, 11, 0                              ; 6028 row 16  Inst10
    R   ___                                     ; 602A row 17
    RI  C_3, 11, 0                              ; 602B row 18  Inst10
    R   ___                                     ; 602D row 19
    RI  C_4, 9, 0                               ; 602E row 20  Inst08
    R   ___                                     ; 6030 row 21
    RI  C_3, 11, 0                              ; 6031 row 22  Inst10
    R   ___                                     ; 6033 row 23
    RI  C_3, 11, 0                              ; 6034 row 24  Inst10
    R   ___                                     ; 6036 row 25
    RI  C_3, 11, 0                              ; 6037 row 26  Inst10
    R   ___                                     ; 6039 row 27
    RI  C_3, 9, 0                               ; 603A row 28  Inst08
    R   ___                                     ; 603C row 29
    RI  C_3, 9, 0                               ; 603D row 30  Inst08
    R   ___                                     ; 603F row 31
Track058:
    RI  C_4, 29, 0                              ; 6040 row 00  Inst28
    R   ___                                     ; 6042 row 01
    R   ___                                     ; 6043 row 02
    R   ___                                     ; 6044 row 03
    R   ___                                     ; 6045 row 04
    R   ___                                     ; 6046 row 05
    R   ___                                     ; 6047 row 06
    R   ___                                     ; 6048 row 07
    RI  G_4, 29, 0                              ; 6049 row 08  Inst28
    R   ___                                     ; 604B row 09
    R   ___                                     ; 604C row 10
    R   ___                                     ; 604D row 11
    R   ___                                     ; 604E row 12
    R   ___                                     ; 604F row 13
    R   ___                                     ; 6050 row 14
    R   ___                                     ; 6051 row 15
    RI  Ds4, 29, 0                              ; 6052 row 16  Inst28
    R   ___                                     ; 6054 row 17
    R   ___                                     ; 6055 row 18
    R   ___                                     ; 6056 row 19
    R   ___                                     ; 6057 row 20
    R   ___                                     ; 6058 row 21
    R   ___                                     ; 6059 row 22
    R   ___                                     ; 605A row 23
    RI  D_4, 29, 0                              ; 605B row 24  Inst28
    R   ___                                     ; 605D row 25
    R   ___                                     ; 605E row 26
    R   ___                                     ; 605F row 27
    R   B_3                                     ; 6060 row 28
    R   ___                                     ; 6061 row 29
    R   ___                                     ; 6062 row 30
    R   ___                                     ; 6063 row 31
Track059:
    RI  C_3, 10, 0                              ; 6064 row 00  Inst09
    R   ___                                     ; 6066 row 01
    RI  C_3, 10, 0                              ; 6067 row 02  Inst09
    R   ___                                     ; 6069 row 03
    RI  C_3, 8, 0                               ; 606A row 04  Inst07
    R   ___                                     ; 606C row 05
    RI  C_4, 10, 0                              ; 606D row 06  Inst09
    R   ___                                     ; 606F row 07
    RI  D_3, 10, 0                              ; 6070 row 08  Inst09
    R   ___                                     ; 6072 row 09
    RI  D_3, 10, 0                              ; 6073 row 10  Inst09
    R   ___                                     ; 6075 row 11
    RI  C_4, 8, 0                               ; 6076 row 12  Inst07
    R   ___                                     ; 6078 row 13
    RI  D_3, 10, 0                              ; 6079 row 14  Inst09
    R   ___                                     ; 607B row 15
    RI  Gs2, 10, 0                              ; 607C row 16  Inst09
    R   ___                                     ; 607E row 17
    RI  Gs2, 10, 0                              ; 607F row 18  Inst09
    R   ___                                     ; 6081 row 19
    RI  C_3, 8, 0                               ; 6082 row 20  Inst07
    R   ___                                     ; 6084 row 21
    RI  Gs3, 10, 0                              ; 6085 row 22  Inst09
    R   ___                                     ; 6087 row 23
    RI  G_2, 10, 0                              ; 6088 row 24  Inst09
    R   ___                                     ; 608A row 25
    RI  G_2, 10, 0                              ; 608B row 26  Inst09
    R   ___                                     ; 608D row 27
    RI  C_3, 8, 0                               ; 608E row 28  Inst07
    R   ___                                     ; 6090 row 29
    RI  G_3, 10, 0                              ; 6091 row 30  Inst09
    R   ___                                     ; 6093 row 31
Track060:
    RIF C_3, 26, 0, $F, $A                      ; 6094 row 00  Inst25  speed 10
    R   ___                                     ; 6097 row 01
    R   ___                                     ; 6098 row 02
    R   ___                                     ; 6099 row 03
    R   ___                                     ; 609A row 04
    R   ___                                     ; 609B row 05
    R   ___                                     ; 609C row 06
    R   ___                                     ; 609D row 07
    RI  C_3, 27, 0                              ; 609E row 08  Inst26
    R   ___                                     ; 60A0 row 09
    R   ___                                     ; 60A1 row 10
    R   ___                                     ; 60A2 row 11
    R   ___                                     ; 60A3 row 12
    R   ___                                     ; 60A4 row 13
    R   ___                                     ; 60A5 row 14
    R   ___                                     ; 60A6 row 15
    RI  C_3, 26, 0                              ; 60A7 row 16  Inst25
    R   ___                                     ; 60A9 row 17
    R   ___                                     ; 60AA row 18
    R   ___                                     ; 60AB row 19
    R   ___                                     ; 60AC row 20
    R   ___                                     ; 60AD row 21
    R   ___                                     ; 60AE row 22
    R   ___                                     ; 60AF row 23
    RI  C_3, 30, 0                              ; 60B0 row 24  Inst29
    R   ___                                     ; 60B2 row 25
    R   ___                                     ; 60B3 row 26
    R   ___                                     ; 60B4 row 27
    R   ___                                     ; 60B5 row 28
    R   ___                                     ; 60B6 row 29
    R   ___                                     ; 60B7 row 30
    R   ___                                     ; 60B8 row 31
Track061:
    RI  C_4, 29, 0                              ; 60B9 row 00  Inst28
    R   ___                                     ; 60BB row 01
    R   ___                                     ; 60BC row 02
    R   ___                                     ; 60BD row 03
    R   ___                                     ; 60BE row 04
    R   ___                                     ; 60BF row 05
    R   ___                                     ; 60C0 row 06
    R   ___                                     ; 60C1 row 07
    RI  G_4, 29, 0                              ; 60C2 row 08  Inst28
    R   ___                                     ; 60C4 row 09
    R   ___                                     ; 60C5 row 10
    R   ___                                     ; 60C6 row 11
    R   ___                                     ; 60C7 row 12
    R   ___                                     ; 60C8 row 13
    R   ___                                     ; 60C9 row 14
    R   ___                                     ; 60CA row 15
    RI  Gs4, 29, 0                              ; 60CB row 16  Inst28
    R   ___                                     ; 60CD row 17
    R   ___                                     ; 60CE row 18
    R   ___                                     ; 60CF row 19
    R   ___                                     ; 60D0 row 20
    R   ___                                     ; 60D1 row 21
    R   ___                                     ; 60D2 row 22
    R   ___                                     ; 60D3 row 23
    RI  As4, 29, 0                              ; 60D4 row 24  Inst28
    R   ___                                     ; 60D6 row 25
    R   ___                                     ; 60D7 row 26
    R   ___                                     ; 60D8 row 27
    R   G_4                                     ; 60D9 row 28
    R   ___                                     ; 60DA row 29
    R   ___                                     ; 60DB row 30
    R   ___                                     ; 60DC row 31
Track062:
    RIF C_3, 26, 0, $F, $A                      ; 60DD row 00  Inst25  speed 10
    R   ___                                     ; 60E0 row 01
    R   ___                                     ; 60E1 row 02
    R   ___                                     ; 60E2 row 03
    R   ___                                     ; 60E3 row 04
    R   ___                                     ; 60E4 row 05
    R   ___                                     ; 60E5 row 06
    R   ___                                     ; 60E6 row 07
    RI  C_3, 27, 0                              ; 60E7 row 08  Inst26
    R   ___                                     ; 60E9 row 09
    R   ___                                     ; 60EA row 10
    R   ___                                     ; 60EB row 11
    R   ___                                     ; 60EC row 12
    R   ___                                     ; 60ED row 13
    R   ___                                     ; 60EE row 14
    R   ___                                     ; 60EF row 15
    RI  Cs3, 30, 0                              ; 60F0 row 16  Inst29
    R   ___                                     ; 60F2 row 17
    R   ___                                     ; 60F3 row 18
    R   ___                                     ; 60F4 row 19
    R   ___                                     ; 60F5 row 20
    R   ___                                     ; 60F6 row 21
    R   ___                                     ; 60F7 row 22
    R   ___                                     ; 60F8 row 23
    RI  Ds3, 30, 0                              ; 60F9 row 24  Inst29
    R   ___                                     ; 60FB row 25
    R   ___                                     ; 60FC row 26
    R   ___                                     ; 60FD row 27
    R   ___                                     ; 60FE row 28
    R   ___                                     ; 60FF row 29
    R   ___                                     ; 6100 row 30
    R   ___                                     ; 6101 row 31
Track063:
    RI  C_4, 29, 0                              ; 6102 row 00  Inst28
    R   ___                                     ; 6104 row 01
    R   ___                                     ; 6105 row 02
    R   ___                                     ; 6106 row 03
    R   ___                                     ; 6107 row 04
    R   ___                                     ; 6108 row 05
    R   ___                                     ; 6109 row 06
    R   ___                                     ; 610A row 07
    RI  G_4, 29, 0                              ; 610B row 08  Inst28
    R   ___                                     ; 610D row 09
    R   ___                                     ; 610E row 10
    R   ___                                     ; 610F row 11
    R   ___                                     ; 6110 row 12
    R   ___                                     ; 6111 row 13
    R   ___                                     ; 6112 row 14
    R   ___                                     ; 6113 row 15
    RI  Gs4, 29, 0                              ; 6114 row 16  Inst28
    R   ___                                     ; 6116 row 17
    R   ___                                     ; 6117 row 18
    R   ___                                     ; 6118 row 19
    R   ___                                     ; 6119 row 20
    R   ___                                     ; 611A row 21
    R   ___                                     ; 611B row 22
    R   ___                                     ; 611C row 23
    RI  Ds5, 29, 0                              ; 611D row 24  Inst28
    R   ___                                     ; 611F row 25
    R   ___                                     ; 6120 row 26
    R   ___                                     ; 6121 row 27
    RI  D_5, 29, 0                              ; 6122 row 28  Inst28
    R   ___                                     ; 6124 row 29
    R   ___                                     ; 6125 row 30
    R   ___                                     ; 6126 row 31
Track064:
    RI  C_5, 29, 0                              ; 6127 row 00  Inst28
    R   ___                                     ; 6129 row 01
    R   ___                                     ; 612A row 02
    R   ___                                     ; 612B row 03
    R   ___                                     ; 612C row 04
    R   ___                                     ; 612D row 05
    R   ___                                     ; 612E row 06
    R   ___                                     ; 612F row 07
    RI  C_5, 31, 0                              ; 6130 row 08  Inst30
    R   ___                                     ; 6132 row 09
    R   ___                                     ; 6133 row 10
    R   ___                                     ; 6134 row 11
    R   ___                                     ; 6135 row 12
    R   ___                                     ; 6136 row 13
    R   ___                                     ; 6137 row 14
    R   ___                                     ; 6138 row 15
    R   ___                                     ; 6139 row 16
    R   ___                                     ; 613A row 17
    R   ___                                     ; 613B row 18
    R   ___                                     ; 613C row 19
    R   ___                                     ; 613D row 20
    R   ___                                     ; 613E row 21
    R   ___                                     ; 613F row 22
    R   ___                                     ; 6140 row 23
    R   ___                                     ; 6141 row 24
    R   ___                                     ; 6142 row 25
    R   ___                                     ; 6143 row 26
    R   ___                                     ; 6144 row 27
    R   ___                                     ; 6145 row 28
    R   ___                                     ; 6146 row 29
    R   ___                                     ; 6147 row 30
    R   ___                                     ; 6148 row 31
Track065:
    RI  C_2, 26, 0                              ; 6149 row 00  Inst25
    R   ___                                     ; 614B row 01
    R   ___                                     ; 614C row 02
    R   ___                                     ; 614D row 03
    R   ___                                     ; 614E row 04
    R   ___                                     ; 614F row 05
    R   ___                                     ; 6150 row 06
    R   ___                                     ; 6151 row 07
    RI  C_2, 26, 0                              ; 6152 row 08  Inst25
    R   ___                                     ; 6154 row 09
    R   ___                                     ; 6155 row 10
    R   ___                                     ; 6156 row 11
    R   ___                                     ; 6157 row 12
    R   ___                                     ; 6158 row 13
    R   ___                                     ; 6159 row 14
    R   ___                                     ; 615A row 15
    RI  C_2, 26, 0                              ; 615B row 16  Inst25
    R   ___                                     ; 615D row 17
    R   ___                                     ; 615E row 18
    R   ___                                     ; 615F row 19
    R   ___                                     ; 6160 row 20
    R   ___                                     ; 6161 row 21
    R   ___                                     ; 6162 row 22
    R   ___                                     ; 6163 row 23
    RI  C_2, 26, 0                              ; 6164 row 24  Inst25
    R   ___                                     ; 6166 row 25
    R   ___                                     ; 6167 row 26
    R   ___                                     ; 6168 row 27
    R   ___                                     ; 6169 row 28
    R   ___                                     ; 616A row 29
    R   ___                                     ; 616B row 30
    R   ___                                     ; 616C row 31
Track066:
    RI  C_3, 10, 0                              ; 616D row 00  Inst09
    R   ___                                     ; 616F row 01
    RI  C_3, 10, 0                              ; 6170 row 02  Inst09
    R   ___                                     ; 6172 row 03
    RI  C_3, 8, 0                               ; 6173 row 04  Inst07
    R   ___                                     ; 6175 row 05
    RI  C_4, 10, 0                              ; 6176 row 06  Inst09
    R   ___                                     ; 6178 row 07
    RI  D_3, 10, 0                              ; 6179 row 08  Inst09
    R   ___                                     ; 617B row 09
    RI  D_3, 10, 0                              ; 617C row 10  Inst09
    R   ___                                     ; 617E row 11
    RI  C_4, 8, 0                               ; 617F row 12  Inst07
    R   ___                                     ; 6181 row 13
    RI  D_3, 10, 0                              ; 6182 row 14  Inst09
    R   ___                                     ; 6184 row 15
    RI  Gs2, 10, 0                              ; 6185 row 16  Inst09
    R   ___                                     ; 6187 row 17
    RI  Gs2, 10, 0                              ; 6188 row 18  Inst09
    R   ___                                     ; 618A row 19
    RI  C_3, 8, 0                               ; 618B row 20  Inst07
    R   ___                                     ; 618D row 21
    RI  Gs3, 10, 0                              ; 618E row 22  Inst09
    R   ___                                     ; 6190 row 23
    RI  Ds2, 10, 0                              ; 6191 row 24  Inst09
    R   ___                                     ; 6193 row 25
    R   ___                                     ; 6194 row 26
    R   ___                                     ; 6195 row 27
    RI  D_2, 10, 0                              ; 6196 row 28  Inst09
    R   ___                                     ; 6198 row 29
    R   ___                                     ; 6199 row 30
    R   ___                                     ; 619A row 31
Track067:
    RI  C_3, 11, 0                              ; 619B row 00  Inst10
    R   ___                                     ; 619D row 01
    RI  C_3, 11, 0                              ; 619E row 02  Inst10
    R   ___                                     ; 61A0 row 03
    RI  C_4, 9, 0                               ; 61A1 row 04  Inst08
    R   ___                                     ; 61A3 row 05
    RI  C_3, 11, 0                              ; 61A4 row 06  Inst10
    R   ___                                     ; 61A6 row 07
    RI  C_3, 11, 0                              ; 61A7 row 08  Inst10
    R   ___                                     ; 61A9 row 09
    RI  C_3, 11, 0                              ; 61AA row 10  Inst10
    R   ___                                     ; 61AC row 11
    RI  C_4, 9, 0                               ; 61AD row 12  Inst08
    R   ___                                     ; 61AF row 13
    RI  C_3, 11, 0                              ; 61B0 row 14  Inst10
    R   ___                                     ; 61B2 row 15
    RI  C_3, 11, 0                              ; 61B3 row 16  Inst10
    R   ___                                     ; 61B5 row 17
    RI  C_3, 11, 0                              ; 61B6 row 18  Inst10
    R   ___                                     ; 61B8 row 19
    RI  C_4, 9, 0                               ; 61B9 row 20  Inst08
    R   ___                                     ; 61BB row 21
    RI  C_3, 11, 0                              ; 61BC row 22  Inst10
    R   ___                                     ; 61BE row 23
    RI  C_3, 12, 0                              ; 61BF row 24  Inst11
    R   ___                                     ; 61C1 row 25
    R   ___                                     ; 61C2 row 26
    R   ___                                     ; 61C3 row 27
    RI  C_3, 12, 0                              ; 61C4 row 28  Inst11
    R   ___                                     ; 61C6 row 29
    R   ___                                     ; 61C7 row 30
    R   ___                                     ; 61C8 row 31
Track068:
    RIF C_3, 26, 0, $F, $A                      ; 61C9 row 00  Inst25  speed 10
    R   ___                                     ; 61CC row 01
    R   ___                                     ; 61CD row 02
    R   ___                                     ; 61CE row 03
    R   ___                                     ; 61CF row 04
    R   ___                                     ; 61D0 row 05
    R   ___                                     ; 61D1 row 06
    R   ___                                     ; 61D2 row 07
    RI  C_3, 27, 0                              ; 61D3 row 08  Inst26
    R   ___                                     ; 61D5 row 09
    R   ___                                     ; 61D6 row 10
    R   ___                                     ; 61D7 row 11
    R   ___                                     ; 61D8 row 12
    R   ___                                     ; 61D9 row 13
    R   ___                                     ; 61DA row 14
    R   ___                                     ; 61DB row 15
    RI  Cs3, 30, 0                              ; 61DC row 16  Inst29
    R   ___                                     ; 61DE row 17
    R   ___                                     ; 61DF row 18
    R   ___                                     ; 61E0 row 19
    R   ___                                     ; 61E1 row 20
    R   ___                                     ; 61E2 row 21
    R   ___                                     ; 61E3 row 22
    R   ___                                     ; 61E4 row 23
    RI  Ds2, 27, 0                              ; 61E5 row 24  Inst26
    R   ___                                     ; 61E7 row 25
    R   ___                                     ; 61E8 row 26
    R   ___                                     ; 61E9 row 27
    RI  Ds2, 30, 0                              ; 61EA row 28  Inst29
    R   ___                                     ; 61EC row 29
    R   ___                                     ; 61ED row 30
    R   ___                                     ; 61EE row 31
Track069:
    RIF G_4, 1, 0, $F, $C                       ; 61EF row 00  Inst00  speed 12
    R   ___                                     ; 61F2 row 01
    RI  Ds4, 1, 0                               ; 61F3 row 02  Inst00
    R   ___                                     ; 61F5 row 03
    RI  D_4, 1, 0                               ; 61F6 row 04  Inst00
    R   ___                                     ; 61F8 row 05
    RI  As3, 1, 0                               ; 61F9 row 06  Inst00
    R   ___                                     ; 61FB row 07
    RI  G_3, 1, 0                               ; 61FC row 08  Inst00
    R   ___                                     ; 61FE row 09
    RI  Ds3, 1, 0                               ; 61FF row 10  Inst00
    R   ___                                     ; 6201 row 11
    RI  D_3, 1, 0                               ; 6202 row 12  Inst00
    R   ___                                     ; 6204 row 13
    RI  As2, 1, 0                               ; 6205 row 14  Inst00
    R   ___                                     ; 6207 row 15
    RI  C_4, 31, 0                              ; 6208 row 16  Inst30
    R   ___                                     ; 620A row 17
    R   ___                                     ; 620B row 18
    R   ___                                     ; 620C row 19
    R   ___                                     ; 620D row 20
    R   ___                                     ; 620E row 21
    R   ___                                     ; 620F row 22
    R   ___                                     ; 6210 row 23
    R   ___                                     ; 6211 row 24
    R   ___                                     ; 6212 row 25
    R   ___                                     ; 6213 row 26
    R   ___                                     ; 6214 row 27
    R   ___                                     ; 6215 row 28
    R   ___                                     ; 6216 row 29
    R   ___                                     ; 6217 row 30
    R   ___                                     ; 6218 row 31
Track070:
    R   ___                                     ; 6219 row 00
    RI  G_4, 1, 0                               ; 621A row 01  Inst00
    R   ___                                     ; 621C row 02
    RI  Ds4, 1, 0                               ; 621D row 03  Inst00
    R   ___                                     ; 621F row 04
    RI  D_4, 1, 0                               ; 6220 row 05  Inst00
    R   ___                                     ; 6222 row 06
    RI  As3, 1, 0                               ; 6223 row 07  Inst00
    R   ___                                     ; 6225 row 08
    RI  G_3, 1, 0                               ; 6226 row 09  Inst00
    R   ___                                     ; 6228 row 10
    RI  Ds3, 1, 0                               ; 6229 row 11  Inst00
    R   ___                                     ; 622B row 12
    RI  D_3, 1, 0                               ; 622C row 13  Inst00
    R   ___                                     ; 622E row 14
    RI  As2, 1, 0                               ; 622F row 15  Inst00
    R   ___                                     ; 6231 row 16
    RI  C_4, 31, 0                              ; 6232 row 17  Inst30
    R   ___                                     ; 6234 row 18
    R   ___                                     ; 6235 row 19
    R   ___                                     ; 6236 row 20
    R   ___                                     ; 6237 row 21
    R   ___                                     ; 6238 row 22
    R   ___                                     ; 6239 row 23
    R   ___                                     ; 623A row 24
    R   ___                                     ; 623B row 25
    R   ___                                     ; 623C row 26
    R   ___                                     ; 623D row 27
    RF  ___, $F, $0                             ; 623E row 28  speed 0
    R   ___                                     ; 6240 row 29
    R   ___                                     ; 6241 row 30
    R   ___                                     ; 6242 row 31
Track071:
    RI  C_4, 2, 0                               ; 6243 row 00  Inst01
    R   ___                                     ; 6245 row 01
    R   ___                                     ; 6246 row 02
    R   ___                                     ; 6247 row 03
    RI  As3, 2, 0                               ; 6248 row 04  Inst01
    R   ___                                     ; 624A row 05
    R   ___                                     ; 624B row 06
    R   ___                                     ; 624C row 07
    RI  Gs3, 2, 0                               ; 624D row 08  Inst01
    R   ___                                     ; 624F row 09
    R   ___                                     ; 6250 row 10
    R   ___                                     ; 6251 row 11
    RI  G_3, 2, 0                               ; 6252 row 12  Inst01
    R   ___                                     ; 6254 row 13
    RI  As2, 2, 0                               ; 6255 row 14  Inst01
    R   ___                                     ; 6257 row 15
    RI  C_3, 2, 0                               ; 6258 row 16  Inst01
    R   ___                                     ; 625A row 17
    R   ___                                     ; 625B row 18
    RI  ___, 0, 2                               ; 625C row 19
    R   ___                                     ; 625E row 20
    R   ___                                     ; 625F row 21
    RI  ___, 0, 1                               ; 6260 row 22
    R   ___                                     ; 6262 row 23
    RI  C_5, 25, 0                              ; 6263 row 24  Inst24
    R   ___                                     ; 6265 row 25
    R   ___                                     ; 6266 row 26
    R   ___                                     ; 6267 row 27
    R   ___                                     ; 6268 row 28
    R   ___                                     ; 6269 row 29
    R   ___                                     ; 626A row 30
    R   ___                                     ; 626B row 31
Track072:
    RI  C_6, 21, 0                              ; 626C row 00  Inst20
    R   ___                                     ; 626E row 01
    R   ___                                     ; 626F row 02
    R   ___                                     ; 6270 row 03
    RI  C_5, 21, 0                              ; 6271 row 04  Inst20
    R   ___                                     ; 6273 row 05
    R   ___                                     ; 6274 row 06
    R   ___                                     ; 6275 row 07
    RI  C_4, 21, 0                              ; 6276 row 08  Inst20
    R   ___                                     ; 6278 row 09
    R   ___                                     ; 6279 row 10
    R   ___                                     ; 627A row 11
    RI  C_4, 21, 0                              ; 627B row 12  Inst20
    R   ___                                     ; 627D row 13
    RI  C_3, 21, 0                              ; 627E row 14  Inst20
    R   ___                                     ; 6280 row 15
    RI  C_2, 21, 0                              ; 6281 row 16  Inst20
    R   ___                                     ; 6283 row 17
    R   ___                                     ; 6284 row 18
    R   ___                                     ; 6285 row 19
    R   ___                                     ; 6286 row 20
    R   ___                                     ; 6287 row 21
    R   ___                                     ; 6288 row 22
    R   ___                                     ; 6289 row 23
    R   ___                                     ; 628A row 24
    R   ___                                     ; 628B row 25
    R   ___                                     ; 628C row 26
    R   ___                                     ; 628D row 27
    R   ___                                     ; 628E row 28
    R   ___                                     ; 628F row 29
    R   ___                                     ; 6290 row 30
    R   ___                                     ; 6291 row 31
Track073:
    RIF C_3, 4, 0, $F, $B                       ; 6292 row 00  Inst03  speed 11
    RI  C_3, 4, 1                               ; 6295 row 01  Inst03
    R   ___                                     ; 6297 row 02
    R   ___                                     ; 6298 row 03
    RI  Fs3, 4, 0                               ; 6299 row 04  Inst03
    RI  Fs3, 4, 1                               ; 629B row 05  Inst03
    R   ___                                     ; 629D row 06
    R   ___                                     ; 629E row 07
    RI  Gs3, 4, 0                               ; 629F row 08  Inst03
    RI  Gs3, 4, 1                               ; 62A1 row 09  Inst03
    R   ___                                     ; 62A3 row 10
    R   ___                                     ; 62A4 row 11
    RI  Fs3, 4, 0                               ; 62A5 row 12  Inst03
    RI  Fs3, 4, 1                               ; 62A7 row 13  Inst03
    R   ___                                     ; 62A9 row 14
    R   ___                                     ; 62AA row 15
    RI  C_3, 4, 0                               ; 62AB row 16  Inst03
    RI  C_3, 4, 1                               ; 62AD row 17  Inst03
    R   ___                                     ; 62AF row 18
    R   ___                                     ; 62B0 row 19
    RI  Fs3, 4, 0                               ; 62B1 row 20  Inst03
    RI  Fs3, 4, 1                               ; 62B3 row 21  Inst03
    R   ___                                     ; 62B5 row 22
    R   ___                                     ; 62B6 row 23
    RI  Gs3, 4, 0                               ; 62B7 row 24  Inst03
    RI  Gs3, 4, 1                               ; 62B9 row 25  Inst03
    R   ___                                     ; 62BB row 26
    R   ___                                     ; 62BC row 27
    RI  Fs3, 4, 0                               ; 62BD row 28  Inst03
    RI  Fs3, 4, 1                               ; 62BF row 29  Inst03
    R   ___                                     ; 62C1 row 30
    R   ___                                     ; 62C2 row 31
Track074:
    R   ___                                     ; 62C3 row 00
    R   ___                                     ; 62C4 row 01
    RI  Ds3, 4, 0                               ; 62C5 row 02  Inst03
    RI  Ds3, 4, 1                               ; 62C7 row 03  Inst03
    R   ___                                     ; 62C9 row 04
    R   ___                                     ; 62CA row 05
    RI  G_3, 4, 0                               ; 62CB row 06  Inst03
    RI  G_3, 4, 1                               ; 62CD row 07  Inst03
    R   ___                                     ; 62CF row 08
    R   ___                                     ; 62D0 row 09
    RI  G_3, 4, 0                               ; 62D1 row 10  Inst03
    RI  G_3, 4, 1                               ; 62D3 row 11  Inst03
    R   ___                                     ; 62D5 row 12
    R   ___                                     ; 62D6 row 13
    RI  G_3, 4, 0                               ; 62D7 row 14  Inst03
    RI  G_3, 4, 1                               ; 62D9 row 15  Inst03
    R   ___                                     ; 62DB row 16
    R   ___                                     ; 62DC row 17
    RI  Ds3, 4, 0                               ; 62DD row 18  Inst03
    RI  Ds3, 4, 1                               ; 62DF row 19  Inst03
    R   ___                                     ; 62E1 row 20
    R   ___                                     ; 62E2 row 21
    RI  G_3, 4, 0                               ; 62E3 row 22  Inst03
    RI  G_3, 4, 1                               ; 62E5 row 23  Inst03
    R   ___                                     ; 62E7 row 24
    R   ___                                     ; 62E8 row 25
    RI  G_3, 4, 0                               ; 62E9 row 26  Inst03
    RI  G_3, 4, 1                               ; 62EB row 27  Inst03
    R   ___                                     ; 62ED row 28
    R   ___                                     ; 62EE row 29
    RI  Ds3, 4, 0                               ; 62EF row 30  Inst03
    RI  Ds3, 4, 1                               ; 62F1 row 31  Inst03
Track075:
    RI  C_3, 2, 0                               ; 62F3 row 00  Inst01
    R   ___                                     ; 62F5 row 01
    R   ___                                     ; 62F6 row 02
    R   ___                                     ; 62F7 row 03
    R   ___                                     ; 62F8 row 04
    R   ___                                     ; 62F9 row 05
    R   ___                                     ; 62FA row 06
    R   ___                                     ; 62FB row 07
    R   ___                                     ; 62FC row 08
    R   ___                                     ; 62FD row 09
    R   ___                                     ; 62FE row 10
    R   ___                                     ; 62FF row 11
    R   ___                                     ; 6300 row 12
    R   ___                                     ; 6301 row 13
    R   ___                                     ; 6302 row 14
    R   ___                                     ; 6303 row 15
    RI  Fs2, 2, 0                               ; 6304 row 16  Inst01
    R   ___                                     ; 6306 row 17
    R   ___                                     ; 6307 row 18
    R   ___                                     ; 6308 row 19
    R   ___                                     ; 6309 row 20
    R   ___                                     ; 630A row 21
    R   ___                                     ; 630B row 22
    R   ___                                     ; 630C row 23
    R   ___                                     ; 630D row 24
    R   ___                                     ; 630E row 25
    R   ___                                     ; 630F row 26
    R   ___                                     ; 6310 row 27
    R   ___                                     ; 6311 row 28
    R   ___                                     ; 6312 row 29
    R   ___                                     ; 6313 row 30
    R   ___                                     ; 6314 row 31
Track076:
    RI  C_5, 21, 0                              ; 6315 row 00  Inst20
    R   ___                                     ; 6317 row 01
    R   ___                                     ; 6318 row 02
    R   ___                                     ; 6319 row 03
    R   ___                                     ; 631A row 04
    R   ___                                     ; 631B row 05
    R   ___                                     ; 631C row 06
    R   ___                                     ; 631D row 07
    RI  C_5, 21, 0                              ; 631E row 08  Inst20
    R   ___                                     ; 6320 row 09
    R   ___                                     ; 6321 row 10
    R   ___                                     ; 6322 row 11
    R   ___                                     ; 6323 row 12
    R   ___                                     ; 6324 row 13
    R   ___                                     ; 6325 row 14
    R   ___                                     ; 6326 row 15
    RI  C_5, 21, 0                              ; 6327 row 16  Inst20
    R   ___                                     ; 6329 row 17
    R   ___                                     ; 632A row 18
    R   ___                                     ; 632B row 19
    R   ___                                     ; 632C row 20
    R   ___                                     ; 632D row 21
    R   ___                                     ; 632E row 22
    R   ___                                     ; 632F row 23
    RI  C_5, 21, 0                              ; 6330 row 24  Inst20
    R   ___                                     ; 6332 row 25
    R   ___                                     ; 6333 row 26
    R   ___                                     ; 6334 row 27
    R   ___                                     ; 6335 row 28
    R   ___                                     ; 6336 row 29
    R   ___                                     ; 6337 row 30
    R   ___                                     ; 6338 row 31
Track077:
    RI  C_3, 4, 0                               ; 6339 row 00  Inst03
    RI  C_3, 4, 1                               ; 633B row 01  Inst03
    R   ___                                     ; 633D row 02
    R   ___                                     ; 633E row 03
    RI  Fs3, 4, 0                               ; 633F row 04  Inst03
    RI  Fs3, 4, 1                               ; 6341 row 05  Inst03
    R   ___                                     ; 6343 row 06
    R   ___                                     ; 6344 row 07
    RI  Gs3, 4, 0                               ; 6345 row 08  Inst03
    RI  Gs3, 4, 1                               ; 6347 row 09  Inst03
    R   ___                                     ; 6349 row 10
    R   ___                                     ; 634A row 11
    RI  Fs3, 4, 0                               ; 634B row 12  Inst03
    RI  Fs3, 4, 1                               ; 634D row 13  Inst03
    R   ___                                     ; 634F row 14
    R   ___                                     ; 6350 row 15
    RI  C_3, 4, 0                               ; 6351 row 16  Inst03
    RI  C_3, 4, 1                               ; 6353 row 17  Inst03
    R   ___                                     ; 6355 row 18
    R   ___                                     ; 6356 row 19
    RI  Fs3, 4, 0                               ; 6357 row 20  Inst03
    RI  Fs3, 4, 1                               ; 6359 row 21  Inst03
    R   ___                                     ; 635B row 22
    R   ___                                     ; 635C row 23
    RI  C_3, 4, 0                               ; 635D row 24  Inst03
    RI  C_3, 4, 1                               ; 635F row 25  Inst03
    R   ___                                     ; 6361 row 26
    R   ___                                     ; 6362 row 27
    R   ___                                     ; 6363 row 28
    R   ___                                     ; 6364 row 29
    R   ___                                     ; 6365 row 30
    R   ___                                     ; 6366 row 31
Track078:
    R   ___                                     ; 6367 row 00
    R   ___                                     ; 6368 row 01
    RI  Ds3, 4, 0                               ; 6369 row 02  Inst03
    RI  Ds3, 4, 1                               ; 636B row 03  Inst03
    R   ___                                     ; 636D row 04
    R   ___                                     ; 636E row 05
    RI  G_3, 4, 0                               ; 636F row 06  Inst03
    RI  G_3, 4, 1                               ; 6371 row 07  Inst03
    R   ___                                     ; 6373 row 08
    R   ___                                     ; 6374 row 09
    RI  G_3, 4, 0                               ; 6375 row 10  Inst03
    RI  G_3, 4, 1                               ; 6377 row 11  Inst03
    R   ___                                     ; 6379 row 12
    R   ___                                     ; 637A row 13
    RI  G_3, 4, 0                               ; 637B row 14  Inst03
    RI  G_3, 4, 1                               ; 637D row 15  Inst03
    R   ___                                     ; 637F row 16
    R   ___                                     ; 6380 row 17
    RI  Ds3, 4, 0                               ; 6381 row 18  Inst03
    RI  Ds3, 4, 1                               ; 6383 row 19  Inst03
    R   ___                                     ; 6385 row 20
    R   ___                                     ; 6386 row 21
    RI  G_3, 4, 0                               ; 6387 row 22  Inst03
    RI  G_3, 4, 1                               ; 6389 row 23  Inst03
    R   ___                                     ; 638B row 24
    R   ___                                     ; 638C row 25
    R   ___                                     ; 638D row 26
    R   ___                                     ; 638E row 27
    R   ___                                     ; 638F row 28
    R   ___                                     ; 6390 row 29
    R   ___                                     ; 6391 row 30
    R   ___                                     ; 6392 row 31
Track079:
    RI  C_3, 2, 0                               ; 6393 row 00  Inst01
    R   ___                                     ; 6395 row 01
    R   ___                                     ; 6396 row 02
    R   ___                                     ; 6397 row 03
    R   ___                                     ; 6398 row 04
    R   ___                                     ; 6399 row 05
    R   ___                                     ; 639A row 06
    R   ___                                     ; 639B row 07
    R   ___                                     ; 639C row 08
    R   ___                                     ; 639D row 09
    R   ___                                     ; 639E row 10
    R   ___                                     ; 639F row 11
    R   ___                                     ; 63A0 row 12
    R   ___                                     ; 63A1 row 13
    R   ___                                     ; 63A2 row 14
    R   ___                                     ; 63A3 row 15
    RI  Fs2, 2, 0                               ; 63A4 row 16  Inst01
    R   ___                                     ; 63A6 row 17
    R   ___                                     ; 63A7 row 18
    R   ___                                     ; 63A8 row 19
    R   ___                                     ; 63A9 row 20
    R   ___                                     ; 63AA row 21
    R   ___                                     ; 63AB row 22
    R   ___                                     ; 63AC row 23
    RI  C_3, 2, 0                               ; 63AD row 24  Inst01
    R   ___                                     ; 63AF row 25
    RI  ___, 0, 2                               ; 63B0 row 26
    R   ___                                     ; 63B2 row 27
    RI  ___, 0, 1                               ; 63B3 row 28
    R   ___                                     ; 63B5 row 29
    RI  C_3, 25, 0                              ; 63B6 row 30  Inst24
    RF  ___, $F, $0                             ; 63B8 row 31  speed 0
Track080:
    RIF Cs5, 16, 0, $F, $F                      ; 63BA row 00  Inst15  speed 15
    R   ___                                     ; 63BD row 01
    RI  Cs5, 16, 0                              ; 63BE row 02  Inst15
    R   ___                                     ; 63C0 row 03
    RI  Gs4, 16, 0                              ; 63C1 row 04  Inst15
    R   ___                                     ; 63C3 row 05
    RI  Gs4, 16, 0                              ; 63C4 row 06  Inst15
    R   ___                                     ; 63C6 row 07
    RI  Cs5, 16, 0                              ; 63C7 row 08  Inst15
    R   ___                                     ; 63C9 row 09
    RI  Cs5, 16, 0                              ; 63CA row 10  Inst15
    R   ___                                     ; 63CC row 11
    RI  Gs4, 16, 0                              ; 63CD row 12  Inst15
    R   ___                                     ; 63CF row 13
    RI  Gs4, 16, 0                              ; 63D0 row 14  Inst15
    R   ___                                     ; 63D2 row 15
    RI  G_4, 16, 0                              ; 63D3 row 16  Inst15
    R   ___                                     ; 63D5 row 17
    RI  G_4, 16, 0                              ; 63D6 row 18  Inst15
    R   ___                                     ; 63D8 row 19
    RI  D_4, 16, 0                              ; 63D9 row 20  Inst15
    R   ___                                     ; 63DB row 21
    RI  D_4, 16, 0                              ; 63DC row 22  Inst15
    R   ___                                     ; 63DE row 23
    RI  G_4, 16, 0                              ; 63DF row 24  Inst15
    R   ___                                     ; 63E1 row 25
    RI  G_4, 16, 0                              ; 63E2 row 26  Inst15
    R   ___                                     ; 63E4 row 27
    RI  D_4, 16, 0                              ; 63E5 row 28  Inst15
    R   ___                                     ; 63E7 row 29
    RI  D_4, 16, 0                              ; 63E8 row 30  Inst15
    R   ___                                     ; 63EA row 31
Track081:
    R   ___                                     ; 63EB row 00
    RI  A_4, 16, 0                              ; 63EC row 01  Inst15
    R   ___                                     ; 63EE row 02
    RI  A_4, 16, 0                              ; 63EF row 03  Inst15
    R   ___                                     ; 63F1 row 04
    RI  E_4, 16, 0                              ; 63F2 row 05  Inst15
    R   ___                                     ; 63F4 row 06
    RI  E_4, 16, 0                              ; 63F5 row 07  Inst15
    R   ___                                     ; 63F7 row 08
    RI  A_4, 16, 0                              ; 63F8 row 09  Inst15
    R   ___                                     ; 63FA row 10
    RI  A_4, 16, 0                              ; 63FB row 11  Inst15
    R   ___                                     ; 63FD row 12
    RI  E_4, 16, 0                              ; 63FE row 13  Inst15
    R   ___                                     ; 6400 row 14
    RI  E_4, 16, 0                              ; 6401 row 15  Inst15
    R   ___                                     ; 6403 row 16
    RI  Ds4, 16, 0                              ; 6404 row 17  Inst15
    R   ___                                     ; 6406 row 18
    RI  Ds4, 16, 0                              ; 6407 row 19  Inst15
    R   ___                                     ; 6409 row 20
    RI  As3, 16, 0                              ; 640A row 21  Inst15
    R   ___                                     ; 640C row 22
    RI  As3, 16, 0                              ; 640D row 23  Inst15
    R   ___                                     ; 640F row 24
    RI  Ds4, 16, 0                              ; 6410 row 25  Inst15
    R   ___                                     ; 6412 row 26
    RI  Ds4, 16, 0                              ; 6413 row 27  Inst15
    R   ___                                     ; 6415 row 28
    RI  As3, 16, 0                              ; 6416 row 29  Inst15
    R   ___                                     ; 6418 row 30
    RI  As3, 16, 0                              ; 6419 row 31  Inst15
Track082:
    RI  Fs2, 10, 0                              ; 641B row 00  Inst09
    R   ___                                     ; 641D row 01
    R   ___                                     ; 641E row 02
    R   ___                                     ; 641F row 03
    RI  Cs2, 10, 0                              ; 6420 row 04  Inst09
    R   ___                                     ; 6422 row 05
    R   ___                                     ; 6423 row 06
    R   ___                                     ; 6424 row 07
    RI  Fs2, 10, 0                              ; 6425 row 08  Inst09
    R   ___                                     ; 6427 row 09
    R   ___                                     ; 6428 row 10
    R   ___                                     ; 6429 row 11
    RI  Cs2, 10, 0                              ; 642A row 12  Inst09
    R   ___                                     ; 642C row 13
    R   ___                                     ; 642D row 14
    R   ___                                     ; 642E row 15
    RI  C_3, 10, 0                              ; 642F row 16  Inst09
    R   ___                                     ; 6431 row 17
    R   ___                                     ; 6432 row 18
    R   ___                                     ; 6433 row 19
    RI  G_2, 10, 0                              ; 6434 row 20  Inst09
    R   ___                                     ; 6436 row 21
    R   ___                                     ; 6437 row 22
    R   ___                                     ; 6438 row 23
    RI  C_3, 10, 0                              ; 6439 row 24  Inst09
    R   ___                                     ; 643B row 25
    R   ___                                     ; 643C row 26
    R   ___                                     ; 643D row 27
    RI  G_2, 10, 0                              ; 643E row 28  Inst09
    R   ___                                     ; 6440 row 29
    R   ___                                     ; 6441 row 30
    R   ___                                     ; 6442 row 31
Track083:
    RI  C_3, 11, 0                              ; 6443 row 00  Inst10
    RI  C_3, 11, 1                              ; 6445 row 01  Inst10
    RI  C_3, 11, 0                              ; 6447 row 02  Inst10
    RI  C_3, 11, 1                              ; 6449 row 03  Inst10
    RI  C_3, 11, 0                              ; 644B row 04  Inst10
    RI  C_3, 11, 1                              ; 644D row 05  Inst10
    RI  C_3, 11, 0                              ; 644F row 06  Inst10
    RI  C_3, 11, 1                              ; 6451 row 07  Inst10
    RI  C_3, 11, 0                              ; 6453 row 08  Inst10
    RI  C_3, 11, 1                              ; 6455 row 09  Inst10
    RI  C_3, 11, 0                              ; 6457 row 10  Inst10
    RI  C_3, 11, 1                              ; 6459 row 11  Inst10
    RI  C_3, 11, 0                              ; 645B row 12  Inst10
    RI  C_3, 11, 1                              ; 645D row 13  Inst10
    RI  C_3, 11, 0                              ; 645F row 14  Inst10
    RI  C_3, 11, 1                              ; 6461 row 15  Inst10
    RI  C_3, 11, 0                              ; 6463 row 16  Inst10
    RI  C_3, 11, 1                              ; 6465 row 17  Inst10
    RI  C_3, 11, 0                              ; 6467 row 18  Inst10
    RI  C_3, 11, 1                              ; 6469 row 19  Inst10
    RI  C_3, 11, 0                              ; 646B row 20  Inst10
    RI  C_3, 11, 1                              ; 646D row 21  Inst10
    RI  C_3, 11, 0                              ; 646F row 22  Inst10
    RI  C_3, 11, 1                              ; 6471 row 23  Inst10
    RI  C_3, 11, 0                              ; 6473 row 24  Inst10
    RI  C_3, 11, 1                              ; 6475 row 25  Inst10
    RI  C_3, 11, 0                              ; 6477 row 26  Inst10
    RI  C_3, 11, 1                              ; 6479 row 27  Inst10
    RI  C_3, 11, 0                              ; 647B row 28  Inst10
    RI  C_3, 11, 1                              ; 647D row 29  Inst10
    RI  C_3, 11, 0                              ; 647F row 30  Inst10
    RI  C_3, 11, 1                              ; 6481 row 31  Inst10
Track084:
    RI  Cs4, 16, 0                              ; 6483 row 00  Inst15
    R   ___                                     ; 6485 row 01
    RI  Cs4, 16, 0                              ; 6486 row 02  Inst15
    R   ___                                     ; 6488 row 03
    RI  Gs3, 16, 0                              ; 6489 row 04  Inst15
    R   ___                                     ; 648B row 05
    RI  Gs3, 16, 0                              ; 648C row 06  Inst15
    R   ___                                     ; 648E row 07
    RI  Cs4, 16, 0                              ; 648F row 08  Inst15
    R   ___                                     ; 6491 row 09
    RI  Cs4, 16, 0                              ; 6492 row 10  Inst15
    R   ___                                     ; 6494 row 11
    RI  Gs3, 16, 0                              ; 6495 row 12  Inst15
    R   ___                                     ; 6497 row 13
    RI  Gs3, 16, 0                              ; 6498 row 14  Inst15
    R   ___                                     ; 649A row 15
    RI  Gs3, 16, 0                              ; 649B row 16  Inst15
    R   ___                                     ; 649D row 17
    RI  Gs3, 16, 1                              ; 649E row 18  Inst15
    R   ___                                     ; 64A0 row 19
    RI  Gs3, 16, 2                              ; 64A1 row 20  Inst15
    R   ___                                     ; 64A3 row 21
    R   ___                                     ; 64A4 row 22
    R   ___                                     ; 64A5 row 23
    R   ___                                     ; 64A6 row 24
    R   ___                                     ; 64A7 row 25
    R   ___                                     ; 64A8 row 26
    R   ___                                     ; 64A9 row 27
    R   ___                                     ; 64AA row 28
    R   ___                                     ; 64AB row 29
    R   ___                                     ; 64AC row 30
    R   ___                                     ; 64AD row 31
Track085:
    R   ___                                     ; 64AE row 00
    RI  A_3, 16, 0                              ; 64AF row 01  Inst15
    R   ___                                     ; 64B1 row 02
    RI  A_3, 16, 0                              ; 64B2 row 03  Inst15
    R   ___                                     ; 64B4 row 04
    RI  E_3, 16, 0                              ; 64B5 row 05  Inst15
    R   ___                                     ; 64B7 row 06
    RI  E_3, 16, 0                              ; 64B8 row 07  Inst15
    R   ___                                     ; 64BA row 08
    RI  A_3, 16, 0                              ; 64BB row 09  Inst15
    R   ___                                     ; 64BD row 10
    RI  A_3, 16, 0                              ; 64BE row 11  Inst15
    R   ___                                     ; 64C0 row 12
    RI  E_3, 16, 0                              ; 64C1 row 13  Inst15
    R   ___                                     ; 64C3 row 14
    RI  E_3, 16, 0                              ; 64C4 row 15  Inst15
    R   ___                                     ; 64C6 row 16
    RI  E_3, 16, 0                              ; 64C7 row 17  Inst15
    R   ___                                     ; 64C9 row 18
    RI  E_3, 16, 1                              ; 64CA row 19  Inst15
    R   ___                                     ; 64CC row 20
    RI  E_3, 16, 2                              ; 64CD row 21  Inst15
    R   ___                                     ; 64CF row 22
    R   ___                                     ; 64D0 row 23
    R   ___                                     ; 64D1 row 24
    R   ___                                     ; 64D2 row 25
    R   ___                                     ; 64D3 row 26
    R   ___                                     ; 64D4 row 27
    R   ___                                     ; 64D5 row 28
    R   ___                                     ; 64D6 row 29
    R   ___                                     ; 64D7 row 30
    R   ___                                     ; 64D8 row 31
Track086:
    RI  Fs2, 10, 0                              ; 64D9 row 00  Inst09
    R   ___                                     ; 64DB row 01
    R   ___                                     ; 64DC row 02
    R   ___                                     ; 64DD row 03
    RI  Cs2, 10, 0                              ; 64DE row 04  Inst09
    R   ___                                     ; 64E0 row 05
    R   ___                                     ; 64E1 row 06
    R   ___                                     ; 64E2 row 07
    RI  Fs2, 10, 0                              ; 64E3 row 08  Inst09
    R   ___                                     ; 64E5 row 09
    R   ___                                     ; 64E6 row 10
    R   ___                                     ; 64E7 row 11
    RI  Cs2, 10, 0                              ; 64E8 row 12  Inst09
    R   ___                                     ; 64EA row 13
    R   ___                                     ; 64EB row 14
    R   ___                                     ; 64EC row 15
    RI  Cs3, 2, 0                               ; 64ED row 16  Inst01
    R   ___                                     ; 64EF row 17
    RI  ___, 0, 2                               ; 64F0 row 18
    R   ___                                     ; 64F2 row 19
    RI  ___, 0, 1                               ; 64F3 row 20
    RI  C_3, 25, 0                              ; 64F5 row 21  Inst24
    R   ___                                     ; 64F7 row 22
    R   ___                                     ; 64F8 row 23
    RF  ___, $F, $0                             ; 64F9 row 24  speed 0
    R   ___                                     ; 64FB row 25
    R   ___                                     ; 64FC row 26
    R   ___                                     ; 64FD row 27
    R   ___                                     ; 64FE row 28
    R   ___                                     ; 64FF row 29
    R   ___                                     ; 6500 row 30
    R   ___                                     ; 6501 row 31
Track087:
    RI  C_3, 11, 0                              ; 6502 row 00  Inst10
    RI  C_3, 11, 1                              ; 6504 row 01  Inst10
    RI  C_3, 11, 0                              ; 6506 row 02  Inst10
    RI  C_3, 11, 1                              ; 6508 row 03  Inst10
    RI  C_3, 11, 0                              ; 650A row 04  Inst10
    RI  C_3, 11, 1                              ; 650C row 05  Inst10
    RI  C_3, 11, 0                              ; 650E row 06  Inst10
    RI  C_3, 11, 1                              ; 6510 row 07  Inst10
    RI  C_3, 11, 0                              ; 6512 row 08  Inst10
    RI  C_3, 11, 1                              ; 6514 row 09  Inst10
    RI  C_3, 11, 0                              ; 6516 row 10  Inst10
    RI  C_3, 11, 1                              ; 6518 row 11  Inst10
    RI  C_3, 11, 0                              ; 651A row 12  Inst10
    RI  C_3, 11, 1                              ; 651C row 13  Inst10
    RI  C_3, 11, 0                              ; 651E row 14  Inst10
    RI  C_3, 11, 1                              ; 6520 row 15  Inst10
    RI  C_3, 23, 0                              ; 6522 row 16  Inst22
    R   ___                                     ; 6524 row 17
    R   ___                                     ; 6525 row 18
    R   ___                                     ; 6526 row 19
    R   ___                                     ; 6527 row 20
    R   ___                                     ; 6528 row 21
    R   ___                                     ; 6529 row 22
    R   ___                                     ; 652A row 23
    R   ___                                     ; 652B row 24
    R   ___                                     ; 652C row 25
    R   ___                                     ; 652D row 26
    R   ___                                     ; 652E row 27
    R   ___                                     ; 652F row 28
    R   ___                                     ; 6530 row 29
    R   ___                                     ; 6531 row 30
    R   ___                                     ; 6532 row 31
Track088:
    RI  F_4, 16, 0                              ; 6533 row 00  Inst15
    R   ___                                     ; 6535 row 01
    R   ___                                     ; 6536 row 02
    R   ___                                     ; 6537 row 03
    RI  C_4, 16, 0                              ; 6538 row 04  Inst15
    R   ___                                     ; 653A row 05
    RI  F_3, 16, 0                              ; 653B row 06  Inst15
    R   ___                                     ; 653D row 07
    RI  F_4, 16, 0                              ; 653E row 08  Inst15
    R   ___                                     ; 6540 row 09
    R   ___                                     ; 6541 row 10
    R   ___                                     ; 6542 row 11
    RI  C_4, 16, 0                              ; 6543 row 12  Inst15
    R   ___                                     ; 6545 row 13
    RI  F_3, 16, 0                              ; 6546 row 14  Inst15
    R   ___                                     ; 6548 row 15
    RI  Ds4, 16, 0                              ; 6549 row 16  Inst15
    R   ___                                     ; 654B row 17
    R   ___                                     ; 654C row 18
    R   ___                                     ; 654D row 19
    RI  D_4, 16, 0                              ; 654E row 20  Inst15
    R   ___                                     ; 6550 row 21
    RI  C_4, 16, 0                              ; 6551 row 22  Inst15
    R   ___                                     ; 6553 row 23
    RI  Ds4, 16, 0                              ; 6554 row 24  Inst15
    R   ___                                     ; 6556 row 25
    R   ___                                     ; 6557 row 26
    R   ___                                     ; 6558 row 27
    RI  D_4, 16, 0                              ; 6559 row 28  Inst15
    R   ___                                     ; 655B row 29
    RI  Ds4, 16, 0                              ; 655C row 30  Inst15
    R   ___                                     ; 655E row 31
Track089:
    RI  A_3, 18, 0                              ; 655F row 00  Inst17
    R   ___                                     ; 6561 row 01
    R   ___                                     ; 6562 row 02
    R   ___                                     ; 6563 row 03
    R   ___                                     ; 6564 row 04
    R   ___                                     ; 6565 row 05
    R   ___                                     ; 6566 row 06
    R   ___                                     ; 6567 row 07
    RI  A_3, 18, 0                              ; 6568 row 08  Inst17
    R   ___                                     ; 656A row 09
    R   ___                                     ; 656B row 10
    R   ___                                     ; 656C row 11
    R   ___                                     ; 656D row 12
    R   ___                                     ; 656E row 13
    R   ___                                     ; 656F row 14
    R   ___                                     ; 6570 row 15
    RI  G_3, 18, 0                              ; 6571 row 16  Inst17
    R   ___                                     ; 6573 row 17
    R   ___                                     ; 6574 row 18
    R   ___                                     ; 6575 row 19
    R   ___                                     ; 6576 row 20
    R   ___                                     ; 6577 row 21
    R   ___                                     ; 6578 row 22
    R   ___                                     ; 6579 row 23
    RI  G_3, 18, 0                              ; 657A row 24  Inst17
    R   ___                                     ; 657C row 25
    R   ___                                     ; 657D row 26
    R   ___                                     ; 657E row 27
    R   ___                                     ; 657F row 28
    R   ___                                     ; 6580 row 29
    R   ___                                     ; 6581 row 30
    R   ___                                     ; 6582 row 31
Track090:
    RIF C_3, 11, 0, $F, $5                      ; 6583 row 00  Inst10  speed 5
    R   ___                                     ; 6586 row 01
    R   ___                                     ; 6587 row 02
    R   ___                                     ; 6588 row 03
    RF  ___, $F, $A                             ; 6589 row 04  speed 10
    R   ___                                     ; 658B row 05
    RI  C_3, 11, 0                              ; 658C row 06  Inst10
    R   ___                                     ; 658E row 07
    RIF C_4, 9, 0, $F, $5                       ; 658F row 08  Inst08  speed 5
    R   ___                                     ; 6592 row 09
    R   ___                                     ; 6593 row 10
    R   ___                                     ; 6594 row 11
    RF  ___, $F, $A                             ; 6595 row 12  speed 10
    R   ___                                     ; 6597 row 13
    RI  C_3, 11, 0                              ; 6598 row 14  Inst10
    R   ___                                     ; 659A row 15
    RIF C_3, 11, 0, $F, $5                      ; 659B row 16  Inst10  speed 5
    R   ___                                     ; 659E row 17
    R   ___                                     ; 659F row 18
    R   ___                                     ; 65A0 row 19
    RF  ___, $F, $A                             ; 65A1 row 20  speed 10
    R   ___                                     ; 65A3 row 21
    RI  C_3, 11, 0                              ; 65A4 row 22  Inst10
    R   ___                                     ; 65A6 row 23
    RIF C_3, 9, 0, $F, $5                       ; 65A7 row 24  Inst08  speed 5
    R   ___                                     ; 65AA row 25
    R   ___                                     ; 65AB row 26
    R   ___                                     ; 65AC row 27
    RIF C_4, 11, 0, $F, $A                      ; 65AD row 28  Inst10  speed 10
    R   ___                                     ; 65B0 row 29
    RI  C_4, 11, 0                              ; 65B1 row 30  Inst10
    R   ___                                     ; 65B3 row 31
Track091:
    RI  F_3, 4, 0                               ; 65B4 row 00  Inst03
    R   ___                                     ; 65B6 row 01
    R   ___                                     ; 65B7 row 02
    R   ___                                     ; 65B8 row 03
    R   ___                                     ; 65B9 row 04
    R   ___                                     ; 65BA row 05
    R   ___                                     ; 65BB row 06
    R   ___                                     ; 65BC row 07
    R   ___                                     ; 65BD row 08
    R   ___                                     ; 65BE row 09
    R   ___                                     ; 65BF row 10
    R   ___                                     ; 65C0 row 11
    R   ___                                     ; 65C1 row 12
    R   ___                                     ; 65C2 row 13
    R   ___                                     ; 65C3 row 14
    R   ___                                     ; 65C4 row 15
    R   ___                                     ; 65C5 row 16
    R   ___                                     ; 65C6 row 17
    R   ___                                     ; 65C7 row 18
    R   ___                                     ; 65C8 row 19
    R   ___                                     ; 65C9 row 20
    R   ___                                     ; 65CA row 21
    R   ___                                     ; 65CB row 22
    R   ___                                     ; 65CC row 23
    R   ___                                     ; 65CD row 24
    R   ___                                     ; 65CE row 25
    R   ___                                     ; 65CF row 26
    R   ___                                     ; 65D0 row 27
    R   ___                                     ; 65D1 row 28
    R   ___                                     ; 65D2 row 29
    R   ___                                     ; 65D3 row 30
    R   ___                                     ; 65D4 row 31
Track092:
    RI  A_3, 18, 0                              ; 65D5 row 00  Inst17
    R   ___                                     ; 65D7 row 01
    R   ___                                     ; 65D8 row 02
    R   ___                                     ; 65D9 row 03
    R   ___                                     ; 65DA row 04
    R   ___                                     ; 65DB row 05
    R   ___                                     ; 65DC row 06
    R   ___                                     ; 65DD row 07
    R   ___                                     ; 65DE row 08
    R   ___                                     ; 65DF row 09
    R   ___                                     ; 65E0 row 10
    R   ___                                     ; 65E1 row 11
    R   ___                                     ; 65E2 row 12
    R   ___                                     ; 65E3 row 13
    R   ___                                     ; 65E4 row 14
    R   ___                                     ; 65E5 row 15
    R   ___                                     ; 65E6 row 16
    R   ___                                     ; 65E7 row 17
    R   ___                                     ; 65E8 row 18
    R   ___                                     ; 65E9 row 19
    R   ___                                     ; 65EA row 20
    R   ___                                     ; 65EB row 21
    R   ___                                     ; 65EC row 22
    R   ___                                     ; 65ED row 23
    R   ___                                     ; 65EE row 24
    R   ___                                     ; 65EF row 25
    R   ___                                     ; 65F0 row 26
    R   ___                                     ; 65F1 row 27
    R   ___                                     ; 65F2 row 28
    R   ___                                     ; 65F3 row 29
    R   ___                                     ; 65F4 row 30
    R   ___                                     ; 65F5 row 31
Track093:
    RI  F_2, 10, 0                              ; 65F6 row 00  Inst09
    R   ___                                     ; 65F8 row 01
    R   ___                                     ; 65F9 row 02
    R   ___                                     ; 65FA row 03
    R   ___                                     ; 65FB row 04
    R   ___                                     ; 65FC row 05
    RI  F_2, 10, 0                              ; 65FD row 06  Inst09
    R   ___                                     ; 65FF row 07
    RI  F_2, 10, 0                              ; 6600 row 08  Inst09
    R   ___                                     ; 6602 row 09
    R   ___                                     ; 6603 row 10
    R   ___                                     ; 6604 row 11
    R   ___                                     ; 6605 row 12
    R   ___                                     ; 6606 row 13
    RI  F_2, 10, 0                              ; 6607 row 14  Inst09
    R   ___                                     ; 6609 row 15
    RI  C_3, 10, 0                              ; 660A row 16  Inst09
    R   ___                                     ; 660C row 17
    R   ___                                     ; 660D row 18
    R   ___                                     ; 660E row 19
    R   ___                                     ; 660F row 20
    R   ___                                     ; 6610 row 21
    RI  C_3, 10, 0                              ; 6611 row 22  Inst09
    R   ___                                     ; 6613 row 23
    RI  C_3, 10, 0                              ; 6614 row 24  Inst09
    R   ___                                     ; 6616 row 25
    R   ___                                     ; 6617 row 26
    R   ___                                     ; 6618 row 27
    RI  D_2, 10, 0                              ; 6619 row 28  Inst09
    R   ___                                     ; 661B row 29
    RI  Ds2, 10, 0                              ; 661C row 30  Inst09
    R   ___                                     ; 661E row 31
Track094:
    RI  F_2, 10, 0                              ; 661F row 00  Inst09
    R   ___                                     ; 6621 row 01
    RI  ___, 0, 2                               ; 6622 row 02
    R   ___                                     ; 6624 row 03
    RI  ___, 0, 1                               ; 6625 row 04
    R   ___                                     ; 6627 row 05
    RI  C_4, 25, 0                              ; 6628 row 06  Inst24
    RF  ___, $F, $0                             ; 662A row 07  speed 0
    R   ___                                     ; 662C row 08
    R   ___                                     ; 662D row 09
    R   ___                                     ; 662E row 10
    R   ___                                     ; 662F row 11
    R   ___                                     ; 6630 row 12
    R   ___                                     ; 6631 row 13
    R   ___                                     ; 6632 row 14
    R   ___                                     ; 6633 row 15
    R   ___                                     ; 6634 row 16
    R   ___                                     ; 6635 row 17
    R   ___                                     ; 6636 row 18
    R   ___                                     ; 6637 row 19
    R   ___                                     ; 6638 row 20
    R   ___                                     ; 6639 row 21
    R   ___                                     ; 663A row 22
    R   ___                                     ; 663B row 23
    R   ___                                     ; 663C row 24
    R   ___                                     ; 663D row 25
    R   ___                                     ; 663E row 26
    R   ___                                     ; 663F row 27
    R   ___                                     ; 6640 row 28
    R   ___                                     ; 6641 row 29
    R   ___                                     ; 6642 row 30
    R   ___                                     ; 6643 row 31
Track095:
    RI  C_3, 12, 0                              ; 6644 row 00  Inst11
    R   ___                                     ; 6646 row 01
    R   ___                                     ; 6647 row 02
    R   ___                                     ; 6648 row 03
    R   ___                                     ; 6649 row 04
    R   ___                                     ; 664A row 05
    R   ___                                     ; 664B row 06
    R   ___                                     ; 664C row 07
    R   ___                                     ; 664D row 08
    R   ___                                     ; 664E row 09
    R   ___                                     ; 664F row 10
    R   ___                                     ; 6650 row 11
    R   ___                                     ; 6651 row 12
    R   ___                                     ; 6652 row 13
    R   ___                                     ; 6653 row 14
    R   ___                                     ; 6654 row 15
    R   ___                                     ; 6655 row 16
    R   ___                                     ; 6656 row 17
    R   ___                                     ; 6657 row 18
    R   ___                                     ; 6658 row 19
    R   ___                                     ; 6659 row 20
    R   ___                                     ; 665A row 21
    R   ___                                     ; 665B row 22
    R   ___                                     ; 665C row 23
    R   ___                                     ; 665D row 24
    R   ___                                     ; 665E row 25
    R   ___                                     ; 665F row 26
    R   ___                                     ; 6660 row 27
    R   ___                                     ; 6661 row 28
    R   ___                                     ; 6662 row 29
    R   ___                                     ; 6663 row 30
    R   ___                                     ; 6664 row 31
Track096:
    RI  C_2, 29, 0                              ; 6665 row 00  Inst28
    R   ___                                     ; 6667 row 01
    R   ___                                     ; 6668 row 02
    R   ___                                     ; 6669 row 03
    R   ___                                     ; 666A row 04
    R   ___                                     ; 666B row 05
    R   ___                                     ; 666C row 06
    R   ___                                     ; 666D row 07
    R   ___                                     ; 666E row 08
    R   ___                                     ; 666F row 09
    R   ___                                     ; 6670 row 10
    R   ___                                     ; 6671 row 11
    R   ___                                     ; 6672 row 12
    R   ___                                     ; 6673 row 13
    R   ___                                     ; 6674 row 14
    R   ___                                     ; 6675 row 15
    RI  Fs2, 29, 0                              ; 6676 row 16  Inst28
    R   ___                                     ; 6678 row 17
    R   ___                                     ; 6679 row 18
    R   ___                                     ; 667A row 19
    R   ___                                     ; 667B row 20
    R   ___                                     ; 667C row 21
    R   ___                                     ; 667D row 22
    R   ___                                     ; 667E row 23
    R   ___                                     ; 667F row 24
    R   ___                                     ; 6680 row 25
    R   ___                                     ; 6681 row 26
    R   ___                                     ; 6682 row 27
    R   ___                                     ; 6683 row 28
    R   ___                                     ; 6684 row 29
    R   ___                                     ; 6685 row 30
    R   ___                                     ; 6686 row 31
Track097:
    RIF C_3, 27, 0, $F, $E                      ; 6687 row 00  Inst26  speed 14
    R   ___                                     ; 668A row 01
    R   ___                                     ; 668B row 02
    R   ___                                     ; 668C row 03
    RI  C_3, 27, 0                              ; 668D row 04  Inst26
    R   ___                                     ; 668F row 05
    R   ___                                     ; 6690 row 06
    R   ___                                     ; 6691 row 07
    RI  C_3, 27, 0                              ; 6692 row 08  Inst26
    R   ___                                     ; 6694 row 09
    R   ___                                     ; 6695 row 10
    R   ___                                     ; 6696 row 11
    RI  C_3, 27, 0                              ; 6697 row 12  Inst26
    R   ___                                     ; 6699 row 13
    R   ___                                     ; 669A row 14
    R   ___                                     ; 669B row 15
    RI  C_3, 28, 0                              ; 669C row 16  Inst27
    R   ___                                     ; 669E row 17
    R   ___                                     ; 669F row 18
    R   ___                                     ; 66A0 row 19
    RI  C_3, 28, 0                              ; 66A1 row 20  Inst27
    R   ___                                     ; 66A3 row 21
    R   ___                                     ; 66A4 row 22
    R   ___                                     ; 66A5 row 23
    RI  C_3, 28, 0                              ; 66A6 row 24  Inst27
    R   ___                                     ; 66A8 row 25
    R   ___                                     ; 66A9 row 26
    R   ___                                     ; 66AA row 27
    RI  C_3, 28, 0                              ; 66AB row 28  Inst27
    R   ___                                     ; 66AD row 29
    R   ___                                     ; 66AE row 30
    R   ___                                     ; 66AF row 31
Track098:
    RI  C_3, 10, 0                              ; 66B0 row 00  Inst09
    R   ___                                     ; 66B2 row 01
    R   ___                                     ; 66B3 row 02
    R   ___                                     ; 66B4 row 03
    R   ___                                     ; 66B5 row 04
    R   ___                                     ; 66B6 row 05
    R   ___                                     ; 66B7 row 06
    R   ___                                     ; 66B8 row 07
    R   ___                                     ; 66B9 row 08
    R   ___                                     ; 66BA row 09
    R   ___                                     ; 66BB row 10
    R   ___                                     ; 66BC row 11
    R   ___                                     ; 66BD row 12
    R   ___                                     ; 66BE row 13
    R   ___                                     ; 66BF row 14
    R   ___                                     ; 66C0 row 15
    RI  Fs3, 10, 0                              ; 66C1 row 16  Inst09
    R   ___                                     ; 66C3 row 17
    R   ___                                     ; 66C4 row 18
    R   ___                                     ; 66C5 row 19
    R   ___                                     ; 66C6 row 20
    R   ___                                     ; 66C7 row 21
    R   ___                                     ; 66C8 row 22
    R   ___                                     ; 66C9 row 23
    R   ___                                     ; 66CA row 24
    R   ___                                     ; 66CB row 25
    R   ___                                     ; 66CC row 26
    R   ___                                     ; 66CD row 27
    R   ___                                     ; 66CE row 28
    R   ___                                     ; 66CF row 29
    R   ___                                     ; 66D0 row 30
    R   ___                                     ; 66D1 row 31
Track099:
    RI  C_2, 29, 0                              ; 66D2 row 00  Inst28
    R   ___                                     ; 66D4 row 01
    R   ___                                     ; 66D5 row 02
    R   ___                                     ; 66D6 row 03
    R   ___                                     ; 66D7 row 04
    R   ___                                     ; 66D8 row 05
    R   ___                                     ; 66D9 row 06
    R   ___                                     ; 66DA row 07
    R   ___                                     ; 66DB row 08
    R   ___                                     ; 66DC row 09
    R   ___                                     ; 66DD row 10
    R   ___                                     ; 66DE row 11
    RI  C_2, 31, 0                              ; 66DF row 12  Inst30
    R   ___                                     ; 66E1 row 13
    R   ___                                     ; 66E2 row 14
    R   ___                                     ; 66E3 row 15
    R   ___                                     ; 66E4 row 16
    R   ___                                     ; 66E5 row 17
    R   ___                                     ; 66E6 row 18
    R   ___                                     ; 66E7 row 19
    R   ___                                     ; 66E8 row 20
    R   ___                                     ; 66E9 row 21
    R   ___                                     ; 66EA row 22
    R   ___                                     ; 66EB row 23
    R   ___                                     ; 66EC row 24
    R   ___                                     ; 66ED row 25
    R   ___                                     ; 66EE row 26
    R   ___                                     ; 66EF row 27
    R   ___                                     ; 66F0 row 28
    R   ___                                     ; 66F1 row 29
    R   ___                                     ; 66F2 row 30
    R   ___                                     ; 66F3 row 31
Track100:
    RIF C_3, 27, 0, $F, $F                      ; 66F4 row 00  Inst26  speed 15
    R   ___                                     ; 66F7 row 01
    R   ___                                     ; 66F8 row 02
    R   ___                                     ; 66F9 row 03
    RI  C_3, 27, 0                              ; 66FA row 04  Inst26
    R   ___                                     ; 66FC row 05
    R   ___                                     ; 66FD row 06
    R   ___                                     ; 66FE row 07
    RI  C_3, 27, 0                              ; 66FF row 08  Inst26
    R   ___                                     ; 6701 row 09
    R   ___                                     ; 6702 row 10
    R   ___                                     ; 6703 row 11
    RI  C_3, 27, 0                              ; 6704 row 12  Inst26
    R   ___                                     ; 6706 row 13
    R   ___                                     ; 6707 row 14
    R   ___                                     ; 6708 row 15
    R   ___                                     ; 6709 row 16
    R   ___                                     ; 670A row 17
    R   ___                                     ; 670B row 18
    R   ___                                     ; 670C row 19
    R   ___                                     ; 670D row 20
    R   ___                                     ; 670E row 21
    R   ___                                     ; 670F row 22
    R   ___                                     ; 6710 row 23
    R   ___                                     ; 6711 row 24
    R   ___                                     ; 6712 row 25
    R   ___                                     ; 6713 row 26
    R   ___                                     ; 6714 row 27
    R   ___                                     ; 6715 row 28
    R   ___                                     ; 6716 row 29
    R   ___                                     ; 6717 row 30
    R   ___                                     ; 6718 row 31
Track101:
    RI  C_3, 10, 0                              ; 6719 row 00  Inst09
    R   ___                                     ; 671B row 01
    R   ___                                     ; 671C row 02
    R   ___                                     ; 671D row 03
    R   ___                                     ; 671E row 04
    R   ___                                     ; 671F row 05
    R   ___                                     ; 6720 row 06
    R   ___                                     ; 6721 row 07
    R   ___                                     ; 6722 row 08
    R   ___                                     ; 6723 row 09
    R   ___                                     ; 6724 row 10
    R   ___                                     ; 6725 row 11
    R   ___                                     ; 6726 row 12
    RI  ___, 0, 2                               ; 6727 row 13
    R   ___                                     ; 6729 row 14
    RI  ___, 0, 1                               ; 672A row 15
    R   ___                                     ; 672C row 16
    RI  C_3, 25, 0                              ; 672D row 17  Inst24
    R   ___                                     ; 672F row 18
    R   ___                                     ; 6730 row 19
    RF  ___, $F, $0                             ; 6731 row 20  speed 0
    R   ___                                     ; 6733 row 21
    R   ___                                     ; 6734 row 22
    R   ___                                     ; 6735 row 23
    R   ___                                     ; 6736 row 24
    R   ___                                     ; 6737 row 25
    R   ___                                     ; 6738 row 26
    R   ___                                     ; 6739 row 27
    R   ___                                     ; 673A row 28
    R   ___                                     ; 673B row 29
    R   ___                                     ; 673C row 30
    R   ___                                     ; 673D row 31
Track102:
    RIF G_2, 10, 0, $F, $6                      ; 673E row 00  Inst09  speed 6
    R   ___                                     ; 6741 row 01
    RI  G_2, 10, 0                              ; 6742 row 02  Inst09
    R   ___                                     ; 6744 row 03
    RI  G_2, 10, 0                              ; 6745 row 04  Inst09
    R   ___                                     ; 6747 row 05
    R   ___                                     ; 6748 row 06
    RI  ___, 0, 0                               ; 6749 row 07
    RI  C_3, 8, 0                               ; 674B row 08  Inst07
    R   ___                                     ; 674D row 09
    R   ___                                     ; 674E row 10
    R   ___                                     ; 674F row 11
    RI  F_2, 10, 0                              ; 6750 row 12  Inst09
    R   ___                                     ; 6752 row 13
    RI  G_2, 10, 0                              ; 6753 row 14  Inst09
    R   ___                                     ; 6755 row 15
    R   ___                                     ; 6756 row 16
    RI  ___, 0, 0                               ; 6757 row 17
    RI  G_2, 10, 0                              ; 6759 row 18  Inst09
    R   ___                                     ; 675B row 19
    RI  G_3, 10, 0                              ; 675C row 20  Inst09
    RI  ___, 0, 0                               ; 675E row 21
    RI  G_2, 10, 0                              ; 6760 row 22  Inst09
    RI  ___, 0, 0                               ; 6762 row 23
    RI  C_3, 8, 0                               ; 6764 row 24  Inst07
    R   ___                                     ; 6766 row 25
    R   ___                                     ; 6767 row 26
    R   ___                                     ; 6768 row 27
    RI  G_3, 10, 0                              ; 6769 row 28  Inst09
    R   ___                                     ; 676B row 29
    RI  C_3, 8, 0                               ; 676C row 30  Inst07
    R   ___                                     ; 676E row 31
Track103:
    RI  C_3, 11, 0                              ; 676F row 00  Inst10
    R   ___                                     ; 6771 row 01
    RI  C_3, 11, 0                              ; 6772 row 02  Inst10
    R   ___                                     ; 6774 row 03
    RI  C_3, 11, 0                              ; 6775 row 04  Inst10
    R   ___                                     ; 6777 row 05
    R   ___                                     ; 6778 row 06
    R   ___                                     ; 6779 row 07
    RI  C_3, 9, 0                               ; 677A row 08  Inst08
    R   ___                                     ; 677C row 09
    R   ___                                     ; 677D row 10
    R   ___                                     ; 677E row 11
    RI  C_3, 11, 0                              ; 677F row 12  Inst10
    R   ___                                     ; 6781 row 13
    RI  C_3, 11, 0                              ; 6782 row 14  Inst10
    R   ___                                     ; 6784 row 15
    R   ___                                     ; 6785 row 16
    R   ___                                     ; 6786 row 17
    RI  C_3, 11, 0                              ; 6787 row 18  Inst10
    R   ___                                     ; 6789 row 19
    RI  C_3, 11, 0                              ; 678A row 20  Inst10
    R   ___                                     ; 678C row 21
    RI  C_3, 11, 0                              ; 678D row 22  Inst10
    R   ___                                     ; 678F row 23
    RI  C_3, 9, 0                               ; 6790 row 24  Inst08
    R   ___                                     ; 6792 row 25
    R   ___                                     ; 6793 row 26
    R   ___                                     ; 6794 row 27
    RI  C_3, 11, 0                              ; 6795 row 28  Inst10
    R   ___                                     ; 6797 row 29
    RI  C_3, 9, 0                               ; 6798 row 30  Inst08
    R   ___                                     ; 679A row 31
Track104:
    RI  C_3, 27, 0                              ; 679B row 00  Inst26
    RI  ___, 0, 1                               ; 679D row 01
    RI  C_3, 27, 0                              ; 679F row 02  Inst26
    RI  ___, 0, 1                               ; 67A1 row 03
    RI  C_3, 27, 0                              ; 67A3 row 04  Inst26
    RI  ___, 0, 1                               ; 67A5 row 05
    R   ___                                     ; 67A7 row 06
    RI  ___, 0, 2                               ; 67A8 row 07
    RI  C_3, 27, 0                              ; 67AA row 08  Inst26
    RI  ___, 0, 1                               ; 67AC row 09
    R   ___                                     ; 67AE row 10
    R   ___                                     ; 67AF row 11
    RI  C_3, 27, 0                              ; 67B0 row 12  Inst26
    RI  ___, 0, 1                               ; 67B2 row 13
    RI  C_3, 27, 0                              ; 67B4 row 14  Inst26
    RI  ___, 0, 1                               ; 67B6 row 15
    R   ___                                     ; 67B8 row 16
    R   ___                                     ; 67B9 row 17
    RI  C_3, 27, 0                              ; 67BA row 18  Inst26
    RI  ___, 0, 1                               ; 67BC row 19
    RI  C_3, 27, 0                              ; 67BE row 20  Inst26
    RI  ___, 0, 1                               ; 67C0 row 21
    RI  C_3, 27, 0                              ; 67C2 row 22  Inst26
    RI  ___, 0, 1                               ; 67C4 row 23
    RI  C_3, 27, 0                              ; 67C6 row 24  Inst26
    RI  ___, 0, 1                               ; 67C8 row 25
    R   ___                                     ; 67CA row 26
    R   ___                                     ; 67CB row 27
    RI  C_3, 27, 0                              ; 67CC row 28  Inst26
    RI  ___, 0, 1                               ; 67CE row 29
    RI  C_3, 27, 0                              ; 67D0 row 30  Inst26
    RI  ___, 0, 1                               ; 67D2 row 31
Track105:
    RI  G_2, 16, 0                              ; 67D4 row 00  Inst15
    R   ___                                     ; 67D6 row 01
    R   ___                                     ; 67D7 row 02
    R   ___                                     ; 67D8 row 03
    RI  G_3, 16, 0                              ; 67D9 row 04  Inst15
    R   ___                                     ; 67DB row 05
    R   ___                                     ; 67DC row 06
    R   ___                                     ; 67DD row 07
    RI  D_3, 16, 0                              ; 67DE row 08  Inst15
    R   ___                                     ; 67E0 row 09
    R   ___                                     ; 67E1 row 10
    R   ___                                     ; 67E2 row 11
    RI  G_2, 16, 0                              ; 67E3 row 12  Inst15
    R   ___                                     ; 67E5 row 13
    RI  G_2, 16, 0                              ; 67E6 row 14  Inst15
    R   ___                                     ; 67E8 row 15
    R   ___                                     ; 67E9 row 16
    R   ___                                     ; 67EA row 17
    RI  G_2, 16, 0                              ; 67EB row 18  Inst15
    R   ___                                     ; 67ED row 19
    RI  G_3, 16, 0                              ; 67EE row 20  Inst15
    R   ___                                     ; 67F0 row 21
    RI  G_2, 16, 0                              ; 67F1 row 22  Inst15
    R   ___                                     ; 67F3 row 23
    RI  D_3, 16, 0                              ; 67F4 row 24  Inst15
    R   ___                                     ; 67F6 row 25
    R   ___                                     ; 67F7 row 26
    R   ___                                     ; 67F8 row 27
    RI  G_2, 16, 0                              ; 67F9 row 28  Inst15
    R   ___                                     ; 67FB row 29
    R   ___                                     ; 67FC row 30
    R   ___                                     ; 67FD row 31
Track106:
    RI  C_3, 27, 0                              ; 67FE row 00  Inst26
    RI  ___, 0, 1                               ; 6800 row 01
    RI  C_3, 27, 0                              ; 6802 row 02  Inst26
    RI  ___, 0, 1                               ; 6804 row 03
    RI  C_3, 27, 0                              ; 6806 row 04  Inst26
    RI  ___, 0, 1                               ; 6808 row 05
    R   ___                                     ; 680A row 06
    RI  ___, 0, 2                               ; 680B row 07
    RI  C_3, 27, 0                              ; 680D row 08  Inst26
    RI  ___, 0, 1                               ; 680F row 09
    R   ___                                     ; 6811 row 10
    R   ___                                     ; 6812 row 11
    RI  C_3, 27, 0                              ; 6813 row 12  Inst26
    RI  ___, 0, 1                               ; 6815 row 13
    RI  C_3, 27, 0                              ; 6817 row 14  Inst26
    R   ___                                     ; 6819 row 15
    R   ___                                     ; 681A row 16
    R   ___                                     ; 681B row 17
    R   ___                                     ; 681C row 18
    R   ___                                     ; 681D row 19
    R   ___                                     ; 681E row 20
    R   ___                                     ; 681F row 21
    R   ___                                     ; 6820 row 22
    R   ___                                     ; 6821 row 23
    R   ___                                     ; 6822 row 24
    R   ___                                     ; 6823 row 25
    R   ___                                     ; 6824 row 26
    R   ___                                     ; 6825 row 27
    R   ___                                     ; 6826 row 28
    R   ___                                     ; 6827 row 29
    R   ___                                     ; 6828 row 30
    R   ___                                     ; 6829 row 31
Track107:
    RIF G_2, 10, 0, $F, $6                      ; 682A row 00  Inst09  speed 6
    R   ___                                     ; 682D row 01
    RI  G_2, 10, 0                              ; 682E row 02  Inst09
    R   ___                                     ; 6830 row 03
    RI  G_2, 10, 0                              ; 6831 row 04  Inst09
    R   ___                                     ; 6833 row 05
    R   ___                                     ; 6834 row 06
    RI  ___, 0, 0                               ; 6835 row 07
    RI  C_3, 8, 0                               ; 6837 row 08  Inst07
    R   ___                                     ; 6839 row 09
    R   ___                                     ; 683A row 10
    R   ___                                     ; 683B row 11
    RI  F_2, 10, 0                              ; 683C row 12  Inst09
    R   ___                                     ; 683E row 13
    RI  G_2, 10, 0                              ; 683F row 14  Inst09
    R   ___                                     ; 6841 row 15
    R   ___                                     ; 6842 row 16
    RI  ___, 0, 2                               ; 6843 row 17
    R   ___                                     ; 6845 row 18
    R   ___                                     ; 6846 row 19
    RI  ___, 0, 1                               ; 6847 row 20
    R   ___                                     ; 6849 row 21
    R   ___                                     ; 684A row 22
    RI  C_3, 25, 0                              ; 684B row 23  Inst24
    R   ___                                     ; 684D row 24
    R   ___                                     ; 684E row 25
    RF  ___, $F, $0                             ; 684F row 26  speed 0
    R   ___                                     ; 6851 row 27
    R   ___                                     ; 6852 row 28
    R   ___                                     ; 6853 row 29
    R   ___                                     ; 6854 row 30
    R   ___                                     ; 6855 row 31
Track108:
    RI  C_3, 11, 0                              ; 6856 row 00  Inst10
    R   ___                                     ; 6858 row 01
    RI  C_3, 11, 0                              ; 6859 row 02  Inst10
    R   ___                                     ; 685B row 03
    RI  C_3, 11, 0                              ; 685C row 04  Inst10
    R   ___                                     ; 685E row 05
    R   ___                                     ; 685F row 06
    R   ___                                     ; 6860 row 07
    RI  C_3, 9, 0                               ; 6861 row 08  Inst08
    R   ___                                     ; 6863 row 09
    R   ___                                     ; 6864 row 10
    R   ___                                     ; 6865 row 11
    RI  C_3, 9, 0                               ; 6866 row 12  Inst08
    R   ___                                     ; 6868 row 13
    RI  C_3, 12, 0                              ; 6869 row 14  Inst11
    R   ___                                     ; 686B row 15
    R   ___                                     ; 686C row 16
    R   ___                                     ; 686D row 17
    R   ___                                     ; 686E row 18
    R   ___                                     ; 686F row 19
    R   ___                                     ; 6870 row 20
    R   ___                                     ; 6871 row 21
    R   ___                                     ; 6872 row 22
    R   ___                                     ; 6873 row 23
    R   ___                                     ; 6874 row 24
    R   ___                                     ; 6875 row 25
    R   ___                                     ; 6876 row 26
    R   ___                                     ; 6877 row 27
    R   ___                                     ; 6878 row 28
    R   ___                                     ; 6879 row 29
    R   ___                                     ; 687A row 30
    R   ___                                     ; 687B row 31
Track109:
    RI  G_2, 16, 0                              ; 687C row 00  Inst15
    R   ___                                     ; 687E row 01
    R   ___                                     ; 687F row 02
    R   ___                                     ; 6880 row 03
    RI  G_3, 16, 0                              ; 6881 row 04  Inst15
    R   ___                                     ; 6883 row 05
    R   ___                                     ; 6884 row 06
    R   ___                                     ; 6885 row 07
    RI  D_3, 16, 0                              ; 6886 row 08  Inst15
    R   ___                                     ; 6888 row 09
    R   ___                                     ; 6889 row 10
    R   ___                                     ; 688A row 11
    RI  G_2, 16, 0                              ; 688B row 12  Inst15
    R   ___                                     ; 688D row 13
    RI  G_2, 4, 0                               ; 688E row 14  Inst03
    R   ___                                     ; 6890 row 15
    R   ___                                     ; 6891 row 16
    R   ___                                     ; 6892 row 17
    R   ___                                     ; 6893 row 18
    R   ___                                     ; 6894 row 19
    R   ___                                     ; 6895 row 20
    R   ___                                     ; 6896 row 21
    R   ___                                     ; 6897 row 22
    R   ___                                     ; 6898 row 23
    R   ___                                     ; 6899 row 24
    R   ___                                     ; 689A row 25
    R   ___                                     ; 689B row 26
    R   ___                                     ; 689C row 27
    R   ___                                     ; 689D row 28
    R   ___                                     ; 689E row 29
    R   ___                                     ; 689F row 30
    R   ___                                     ; 68A0 row 31

;; Wave-RAM source data for Inst01, Inst09, Inst24. 16 bytes at base+position are copied
;; to $FF30-$FF3F (4-bit samples, high nibble first); positions used: $02-$10.
WaveData00:
    db $88, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00; 68A1 
    db $06, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF; 68B1 
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $F8, $00, $00, $00, $00, $00, $00; 68C1 
    db $00, $06, $FF, $FF, $FF, $FF, $FF, $FF   ; 68D1 

;; Wave-RAM source data for Inst07. 16 bytes at base+position are copied
;; to $FF30-$FF3F (4-bit samples, high nibble first); positions used: $02-$10.
WaveData01:
    db $88, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00; 68D9 
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF; 68E9 
SFXInstTable:
    dw SFXInst00                                 ; 68F9  SFX instrument 1 (ch4)
    dw SFXInst01                                 ; 68FB  SFX instrument 2 (ch1)
    dw SFXInst02                                 ; 68FD  SFX instrument 3 (ch1)
    dw SFXInst03                                 ; 68FF  SFX instrument 4 (ch4)
    dw SFXInst04                                 ; 6901  SFX instrument 5 (ch1)
    dw SFXInst05                                 ; 6903  SFX instrument 6 (ch4)
    dw SFXInst06                                 ; 6905  SFX instrument 7 (ch1)
    dw SFXInst07                                 ; 6907  SFX instrument 8 (ch4)
    dw SFXInst08                                 ; 6909  SFX instrument 9 (ch4)
    dw SFXInst09                                 ; 690B  SFX instrument 10 (ch1)
    dw SFXInst10                                 ; 690D  SFX instrument 11 (ch4)
    dw SFXInst11                                 ; 690F  SFX instrument 12 (ch4)
    dw SFXInst12                                 ; 6911  SFX instrument 13 (ch1)
    dw SFXInst13                                 ; 6913  SFX instrument 14 (ch4)
    dw SFXInst14                                 ; 6915  SFX instrument 15 (ch4)
    dw SFXInst15                                 ; 6917  SFX instrument 16 (ch1)
    dw SFXInst16                                 ; 6919  SFX instrument 17 (ch1)
    dw SFXInst17                                 ; 691B  SFX instrument 18 (ch4)
    dw SFXInst18                                 ; 691D  SFX instrument 19 (ch4)
    dw SFXInst19                                 ; 691F  SFX instrument 20 (ch1)
    dw SFXInst20                                 ; 6921  SFX instrument 21 (unused)
    dw SFXInst21                                 ; 6923  SFX instrument 22 (ch4)
    dw SFXInst22                                 ; 6925  SFX instrument 23 (ch4)
    dw SFXInst23                                 ; 6927  SFX instrument 24 (ch1)
    dw SFXInst24                                 ; 6929  SFX instrument 25 (ch4)
    dw SFXInst25                                 ; 692B  SFX instrument 26 (ch4)
    dw SFXInst26                                 ; 692D  SFX instrument 27 (ch1)
    dw SFXInst27                                 ; 692F  SFX instrument 28 (ch1)
    dw SFXInst28                                 ; 6931  SFX instrument 29 (ch1)
    dw SFXInst29                                 ; 6933  SFX instrument 30 (ch4)
    dw SFXInst30                                 ; 6935  SFX instrument 31 (ch4)
    dw SFXInst31                                 ; 6937  SFX instrument 32 (ch4)
    dw SFXInst32                                 ; 6939  SFX instrument 33 (ch4)
    dw SFXInst33                                 ; 693B  SFX instrument 34 (ch4)
    dw SFXInst34                                 ; 693D  SFX instrument 35 (ch1)
    dw SFXInst35                                 ; 693F  SFX instrument 36 (ch1)
    dw SFXInst36                                 ; 6941  SFX instrument 37 (ch1)
    dw SFXInst37                                 ; 6943  SFX instrument 38 (ch4)
    dw SFXInst38                                 ; 6945  SFX instrument 39 (ch4)
    dw SFXInst39                                 ; 6947  SFX instrument 40 (ch1)
    dw SFXInst40                                 ; 6949  SFX instrument 41 (ch4)
    dw SFXInst41                                 ; 694B  SFX instrument 42 (ch1)
    dw SFXInst42                                 ; 694D  SFX instrument 43 (ch4)
    dw SFXInst43                                 ; 694F  SFX instrument 44 (ch1)
    dw SFXInst44                                 ; 6951  SFX instrument 45 (ch1)
SFXInst00:
    db $02                                       ; 6953 noise, 2 steps
    db $01                                       ; playlist speed
    db $82                                       ; NR42 envelope
    db $7A, $00, $00                             ; step 0: A-6
    db $65, $00, $00                             ; step 1: C-5
SFXInst01:
    db $06                                       ; 695C square, 6 steps
    db $01                                       ; playlist speed
    db $F1                                       ; NRx2 envelope
    db $5D, $00, $C2                             ; step 0: E-4  duty 2
    db $59, $00, $00                             ; step 1: C-4
    db $56, $00, $00                             ; step 2: A-3
    db $52, $00, $00                             ; step 3: F-3
    db $4F, $00, $00                             ; step 4: D-3
    db $40, $00, $40                             ; step 5: -  vol 0
SFXInst02:
    db $05                                       ; 6971 square, 5 steps
    db $01                                       ; playlist speed
    db $F1                                       ; NRx2 envelope
    db $59, $00, $C2                             ; step 0: C-4  duty 2
    db $58, $00, $00                             ; step 1: B-3
    db $56, $00, $00                             ; step 2: A-3
    db $54, $00, $00                             ; step 3: G-3
    db $52, $00, $85                             ; step 4: F-3  jump -5
SFXInst03:
    db $03                                       ; 6983 noise, 3 steps
    db $02                                       ; playlist speed
    db $A2                                       ; NR42 envelope
    db $7A, $00, $00                             ; step 0: A-6
    db $59, $00, $00                             ; step 1: C-4
    db $4D, $00, $82                             ; step 2: C-3  jump -2
SFXInst04:
    db $06                                       ; 698F square, 6 steps
    db $01                                       ; playlist speed
    db $F0                                       ; NRx2 envelope
    db $59, $00, $C2                             ; step 0: C-4  duty 2
    db $56, $00, $00                             ; step 1: A-3
    db $52, $00, $00                             ; step 2: F-3
    db $4F, $00, $00                             ; step 3: D-3
    db $4D, $00, $00                             ; step 4: C-3
    db $4A, $00, $86                             ; step 5: A-2  jump -6
SFXInst05:
    db $06                                       ; 69A4 noise, 6 steps
    db $01                                       ; playlist speed
    db $71                                       ; NR42 envelope
    db $7A, $00, $4B                             ; step 0: A-6  vol 11
    db $65, $00, $00                             ; step 1: C-5
    db $40, $00, $00                             ; step 2: -
    db $40, $00, $44                             ; step 3: -  vol 4
    db $40, $00, $00                             ; step 4: -
    db $40, $00, $86                             ; step 5: -  jump -6
SFXInst06:
    db $01                                       ; 69B9 square, 1 steps
    db $01                                       ; playlist speed
    db $00                                       ; NRx2 envelope
    db $41, $00, $40                             ; step 0: C-2  vol 0
SFXInst07:
    db $01                                       ; 69BF noise, 1 steps
    db $01                                       ; playlist speed
    db $00                                       ; NR42 envelope
    db $41, $00, $40                             ; step 0: C-2  vol 0
SFXInst08:
    db $04                                       ; 69C5 noise, 4 steps
    db $01                                       ; playlist speed
    db $F5                                       ; NR42 envelope
    db $59, $00, $4F                             ; step 0: C-4  vol 15
    db $54, $00, $4F                             ; step 1: G-3  vol 15
    db $4D, $00, $4F                             ; step 2: C-3  vol 15
    db $46, $00, $4F                             ; step 3: F-2  vol 15
SFXInst09:
    db $05                                       ; 69D4 square, 5 steps
    db $01                                       ; playlist speed
    db $F4                                       ; NRx2 envelope
    db $52, $00, $C2                             ; step 0: F-3  duty 2
    db $51, $00, $00                             ; step 1: E-3
    db $50, $00, $00                             ; step 2: D#3
    db $4F, $00, $00                             ; step 3: D-3
    db $4E, $00, $85                             ; step 4: C#3  jump -5
SFXInst10:
    db $05                                       ; 69E6 noise, 5 steps
    db $01                                       ; playlist speed
    db $F3                                       ; NR42 envelope
    db $7C, $00, $00                             ; step 0: B-6
    db $7A, $00, $00                             ; step 1: A-6
    db $7C, $00, $00                             ; step 2: B-6
    db $7A, $00, $00                             ; step 3: A-6
    db $71, $00, $85                             ; step 4: C-6  jump -5
SFXInst11:
    db $04                                       ; 69F8 noise, 4 steps
    db $02                                       ; playlist speed
    db $C2                                       ; NR42 envelope
    db $71, $00, $4F                             ; step 0: C-6  vol 15
    db $70, $00, $4F                             ; step 1: B-5  vol 15
    db $6F, $00, $4F                             ; step 2: A#5  vol 15
    db $6E, $00, $4F                             ; step 3: A-5  vol 15
SFXInst12:
    db $06                                       ; 6A07 square, 6 steps
    db $01                                       ; playlist speed
    db $F1                                       ; NRx2 envelope
    db $52, $00, $C2                             ; step 0: F-3  duty 2
    db $53, $00, $00                             ; step 1: F#3
    db $54, $00, $00                             ; step 2: G-3
    db $55, $00, $00                             ; step 3: G#3
    db $56, $00, $85                             ; step 4: A-3  jump -5
    db $40, $00, $40                             ; step 5: -  vol 0
SFXInst13:
    db $05                                       ; 6A1C noise, 5 steps
    db $01                                       ; playlist speed
    db $A2                                       ; NR42 envelope
    db $41, $00, $00                             ; step 0: C-2
    db $48, $00, $00                             ; step 1: G-2
    db $59, $00, $00                             ; step 2: C-4
    db $40, $00, $00                             ; step 3: -
    db $40, $00, $00                             ; step 4: -
SFXInst14:
    db $0E                                       ; 6A2E noise, 14 steps
    db $01                                       ; playlist speed
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
    db $09                                       ; 6A5B square, 9 steps
    db $01                                       ; playlist speed
    db $F0                                       ; NRx2 envelope
    db $51, $00, $C2                             ; step 0: E-3  duty 2
    db $52, $00, $00                             ; step 1: F-3
    db $53, $00, $00                             ; step 2: F#3
    db $54, $00, $00                             ; step 3: G-3
    db $55, $00, $00                             ; step 4: G#3
    db $56, $00, $00                             ; step 5: A-3
    db $57, $00, $00                             ; step 6: A#3
    db $58, $00, $00                             ; step 7: B-3
    db $40, $00, $40                             ; step 8: -  vol 0
SFXInst16:
    db $08                                       ; 6A79 square, 8 steps
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
    db $06                                       ; 6A94 noise, 6 steps
    db $01                                       ; playlist speed
    db $E0                                       ; NR42 envelope
    db $41, $00, $00                             ; step 0: C-2
    db $4D, $00, $00                             ; step 1: C-3
    db $59, $00, $00                             ; step 2: C-4
    db $71, $00, $00                             ; step 3: C-6
    db $4D, $00, $00                             ; step 4: C-3
    db $40, $00, $40                             ; step 5: -  vol 0
SFXInst18:
    db $06                                       ; 6AA9 noise, 6 steps
    db $01                                       ; playlist speed
    db $C0                                       ; NR42 envelope
    db $60, $00, $4F                             ; step 0: G-4  vol 15
    db $40, $00, $4F                             ; step 1: -  vol 15
    db $40, $00, $40                             ; step 2: -  vol 0
    db $4D, $00, $4F                             ; step 3: C-3  vol 15
    db $40, $00, $4A                             ; step 4: -  vol 10
    db $40, $00, $40                             ; step 5: -  vol 0
SFXInst19:
    db $06                                       ; 6ABE square, 6 steps
    db $01                                       ; playlist speed
    db $C0                                       ; NRx2 envelope
    db $60, $C2, $4F                             ; step 0: G-4  duty 2, vol 15
    db $40, $00, $4F                             ; step 1: -  vol 15
    db $40, $00, $40                             ; step 2: -  vol 0
    db $4D, $00, $4F                             ; step 3: C-3  vol 15
    db $40, $00, $4A                             ; step 4: -  vol 10
    db $40, $00, $40                             ; step 5: -  vol 0
SFXInst20:
    db $00                                       ; 6AD3 square, 0 steps
    db $01                                       ; playlist speed
    db $00                                       ; NRx2 envelope
SFXInst21:
    db $07                                       ; 6AD6 noise, 7 steps
    db $01                                       ; playlist speed
    db $E0                                       ; NR42 envelope
    db $41, $00, $00                             ; step 0: C-2
    db $43, $00, $00                             ; step 1: D-2
    db $45, $00, $00                             ; step 2: E-2
    db $46, $00, $00                             ; step 3: F-2
    db $48, $00, $00                             ; step 4: G-2
    db $4A, $00, $00                             ; step 5: A-2
    db $40, $00, $40                             ; step 6: -  vol 0
SFXInst22:
    db $07                                       ; 6AEE noise, 7 steps
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
    db $05                                       ; 6B06 square, 5 steps
    db $01                                       ; playlist speed
    db $B1                                       ; NRx2 envelope
    db $59, $00, $C2                             ; step 0: C-4  duty 2
    db $5A, $00, $00                             ; step 1: C#4
    db $59, $00, $00                             ; step 2: C-4
    db $5A, $00, $00                             ; step 3: C#4
    db $59, $00, $85                             ; step 4: C-4  jump -5
SFXInst24:
    db $05                                       ; 6B18 noise, 5 steps
    db $05                                       ; playlist speed
    db $F3                                       ; NR42 envelope
    db $41, $00, $00                             ; step 0: C-2
    db $42, $00, $00                             ; step 1: C#2
    db $43, $00, $00                             ; step 2: D-2
    db $44, $00, $00                             ; step 3: D#2
    db $45, $00, $00                             ; step 4: E-2
SFXInst25:
    db $03                                       ; 6B2A noise, 3 steps
    db $01                                       ; playlist speed
    db $F1                                       ; NR42 envelope
    db $41, $00, $00                             ; step 0: C-2
    db $54, $00, $00                             ; step 1: G-3
    db $59, $00, $83                             ; step 2: C-4  jump -3
SFXInst26:
    db $05                                       ; 6B36 square, 5 steps
    db $01                                       ; playlist speed
    db $C2                                       ; NRx2 envelope
    db $6E, $00, $C2                             ; step 0: A-5  duty 2
    db $6D, $00, $00                             ; step 1: G#5
    db $6C, $00, $00                             ; step 2: G-5
    db $6B, $00, $00                             ; step 3: F#5
    db $6A, $00, $85                             ; step 4: F-5  jump -5
SFXInst27:
    db $05                                       ; 6B48 square, 5 steps
    db $01                                       ; playlist speed
    db $E1                                       ; NRx2 envelope
    db $6B, $00, $C2                             ; step 0: F#5  duty 2
    db $6A, $00, $00                             ; step 1: F-5
    db $69, $00, $00                             ; step 2: E-5
    db $68, $00, $00                             ; step 3: D#5
    db $67, $00, $85                             ; step 4: D-5  jump -5
SFXInst28:
    db $0B                                       ; 6B5A square, 11 steps
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
    db $02                                       ; 6B7E noise, 2 steps
    db $01                                       ; playlist speed
    db $F1                                       ; NR42 envelope
    db $71, $00, $00                             ; step 0: C-6
    db $41, $00, $82                             ; step 1: C-2  jump -2
SFXInst30:
    db $07                                       ; 6B87 noise, 7 steps
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
    db $07                                       ; 6B9F noise, 7 steps
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
    db $03                                       ; 6BB7 noise, 3 steps
    db $01                                       ; playlist speed
    db $71                                       ; NR42 envelope
    db $7A, $00, $4F                             ; step 0: A-6  vol 15
    db $41, $00, $00                             ; step 1: C-2
    db $40, $00, $40                             ; step 2: -  vol 0
SFXInst33:
    db $07                                       ; 6BC3 noise, 7 steps
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
    db $03                                       ; 6BDB square, 3 steps
    db $01                                       ; playlist speed
    db $F3                                       ; NRx2 envelope
    db $59, $00, $C2                             ; step 0: C-4  duty 2
    db $52, $00, $00                             ; step 1: F-3
    db $40, $00, $40                             ; step 2: -  vol 0
SFXInst35:
    db $06                                       ; 6BE7 square, 6 steps
    db $02                                       ; playlist speed
    db $F5                                       ; NRx2 envelope
    db $5D, $00, $C2                             ; step 0: E-4  duty 2
    db $59, $00, $00                             ; step 1: C-4
    db $56, $00, $00                             ; step 2: A-3
    db $52, $00, $00                             ; step 3: F-3
    db $4F, $00, $85                             ; step 4: D-3  jump -5
    db $40, $00, $00                             ; step 5: -
SFXInst36:
    db $06                                       ; 6BFC square, 6 steps
    db $02                                       ; playlist speed
    db $F5                                       ; NRx2 envelope
    db $65, $00, $C2                             ; step 0: C-5  duty 2
    db $66, $00, $00                             ; step 1: C#5
    db $6C, $00, $C0                             ; step 2: G-5  duty 0
    db $6F, $00, $00                             ; step 3: A#5
    db $74, $00, $85                             ; step 4: D#6  jump -5
    db $40, $00, $00                             ; step 5: -
SFXInst37:
    db $07                                       ; 6C11 noise, 7 steps
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
    db $07                                       ; 6C29 noise, 7 steps
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
    db $06                                       ; 6C41 square, 6 steps
    db $02                                       ; playlist speed
    db $F5                                       ; NRx2 envelope
    db $59, $00, $C0                             ; step 0: C-4  duty 0
    db $5A, $00, $00                             ; step 1: C#4
    db $5B, $00, $00                             ; step 2: D-4
    db $5A, $00, $84                             ; step 3: C#4  jump -4
    db $40, $00, $00                             ; step 4: -
    db $40, $00, $00                             ; step 5: -
SFXInst40:
    db $0E                                       ; 6C56 noise, 14 steps
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
    db $09                                       ; 6C83 square, 9 steps
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
    db $05                                       ; 6CA1 noise, 5 steps
    db $02                                       ; playlist speed
    db $F3                                       ; NR42 envelope
    db $7A, $00, $4F                             ; step 0: A-6  vol 15
    db $40, $00, $40                             ; step 1: -  vol 0
    db $65, $00, $4F                             ; step 2: C-5  vol 15
    db $40, $00, $40                             ; step 3: -  vol 0
    db $40, $00, $00                             ; step 4: -
SFXInst43:
    db $06                                       ; 6CB3 square, 6 steps
    db $01                                       ; playlist speed
    db $F0                                       ; NRx2 envelope
    db $59, $00, $C2                             ; step 0: C-4  duty 2
    db $5D, $00, $00                             ; step 1: E-4
    db $60, $00, $00                             ; step 2: G-4
    db $40, $00, $40                             ; step 3: -  vol 0
    db $40, $00, $00                             ; step 4: -
    db $40, $00, $00                             ; step 5: -
SFXInst44:
    db $06                                       ; 6CC8 square, 6 steps
    db $02                                       ; playlist speed
    db $F1                                       ; NRx2 envelope
    db $65, $00, $C2                             ; step 0: C-5  duty 2
    db $71, $00, $82                             ; step 1: C-6  jump -2
    db $40, $00, $00                             ; step 2: -
    db $40, $00, $00                             ; step 3: -
    db $40, $00, $00                             ; step 4: -
    db $40, $00, $00                             ; step 5: -

;; Sound effects, 5 bytes: [ins ch1] [ins ch2] [ins ch3] [ins ch4] [mute time in ticks].
;; Instrument numbers are 1-based indices into SFXInstTable (0 = channel not used);
;; the music on the used channels is muted for "time" ticks.
SFXTable:
    db 2, 0, 0, 1, $00                           ; 6CDD SFX 0
    db 3, 0, 0, 4, $00                           ; 6CE2 SFX 1
    db 5, 0, 0, 6, $00                           ; 6CE7 SFX 2
    db 7, 0, 0, 8, $00                           ; 6CEC SFX 3
    db 10, 0, 0, 9, $00                          ; 6CF1 SFX 4
    db 0, 0, 0, 11, $00                          ; 6CF6 SFX 5
    db 0, 0, 0, 12, $00                          ; 6CFB SFX 6
    db 13, 0, 0, 14, $00                         ; 6D00 SFX 7
    db 16, 0, 0, 15, $00                         ; 6D05 SFX 8
    db 17, 0, 0, 18, $00                         ; 6D0A SFX 9
    db 20, 0, 0, 19, $00                         ; 6D0F SFX 10
    db 0, 0, 0, 22, $00                          ; 6D14 SFX 11
    db 24, 0, 0, 23, $00                         ; 6D19 SFX 12
    db 0, 0, 0, 25, $00                          ; 6D1E SFX 13
    db 28, 0, 0, 26, $00                         ; 6D23 SFX 14
    db 27, 0, 0, 0, $00                          ; 6D28 SFX 15
    db 29, 0, 0, 26, $00                         ; 6D2D SFX 16
    db 0, 0, 0, 30, $00                          ; 6D32 SFX 17
    db 0, 0, 0, 31, $00                          ; 6D37 SFX 18
    db 0, 0, 0, 32, $00                          ; 6D3C SFX 19
    db 35, 0, 0, 33, $00                         ; 6D41 SFX 20
    db 36, 0, 0, 34, $00                         ; 6D46 SFX 21
    db 37, 0, 0, 38, $00                         ; 6D4B SFX 22
    db 40, 0, 0, 39, $00                         ; 6D50 SFX 23
    db 42, 0, 0, 41, $00                         ; 6D55 SFX 24
    db 16, 0, 0, 26, $00                         ; 6D5A SFX 25
    db 0, 0, 0, 43, $00                          ; 6D5F SFX 26
    db 44, 0, 0, 0, $04                          ; 6D64 SFX 27
    db 45, 0, 0, 0, $08                          ; 6D69 SFX 28
    ds 4754, $DA                ; 6D6E  (fill)
