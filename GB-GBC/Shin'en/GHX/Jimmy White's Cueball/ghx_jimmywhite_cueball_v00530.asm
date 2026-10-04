; ============================================================================
; Jimmy White's Cueball (E) [C][!].gbc  -  bank $10 (file offset $40000-$43FFF)
; "GHX Sound Engine   Ver.00530    (c) 2000 SHIN'EN Code: M. Wodok Music: M.Linzner"
; 
; Version string "Ver.00530" = 30 May 2000. The game calls GHX_SetPCMBank with
; A = $10, C = $11 ($3D73), GHX_Play from the VBlank handler ($021A) and
; GHX_TimerISR from the timer handler ($0264). The commentary samples (PCM
; sound effects) live in banks $11-$16 and are included below as data.
; 
; Changes against the Tomb Raider builds: positions are 7 bytes with track
; NUMBERS again, rows are prefetched at the end of the previous frame, PCM
; sample instruments (ch3 flag bits 5-7, banked, 16 bytes per timer IRQ through
; a WRAM copy stub, looping), finite playlist loops (loop count in the $C0
; command - broken on ch1/ch2 here), GHX_MuteMusic.
;
; Complete disassembly of the bank: sound driver code plus all music and
; sound-effect data as labelled source. Assemble with RGBDS 0.9:
;   rgbasm -o x.o ghx_jimmywhite_cueball_v00530.asm ; rgblink -o x.gb x.o
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
DEF wWave_SweepOn_PCMBank        EQU $DE76
DEF wWave_WaveUpdate_PCMRate     EQU $DE77
DEF wWave_BaseHi_PCMPtrHi        EQU $DE78
DEF wWave_BaseLo_PCMPtrLo        EQU $DE79
DEF wWave_SweepSpeed_LoopPtrLo   EQU $DE7A
DEF wWave_UpperLo_LoopPtrHi      EQU $DE7B
DEF wWave_UpperHi_LoopLenHi      EQU $DE7C
DEF wWave_LowerLo_LoopLenLo      EQU $DE7D
DEF wWave_LowerHi_LoopBank       EQU $DE7E
DEF wWave_PosLo_PCMLenLo         EQU $DE7F
DEF wWave_PosHi_PCMLenHi         EQU $DE80
DEF wWave_FlagLo                 EQU $DE81
DEF wWave_FlagHi_PCMNR34         EQU $DE82
DEF wWave_Step_PCMNR33           EQU $DE83
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
DEF wPCM_IRQToggle               EQU $DEEB
DEF wPCM_Done                    EQU $DEEC
DEF wPCM_CopyStub                EQU $DEED
DEF wPCM_BankBase                EQU $DEFC

SECTION "GHX Sound Engine", ROMX[$4000], BANK[$10]

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
GHX_TimerISR:
    jp TimerISR                 ; 4012  timer interrupt: PCM streaming
GHX_PlaySFX:
    jp PlaySFX                  ; 4015  A = sound effect
GHX_Pause:
    jp PauseImpl                ; 4018  stop, APU off, keep everything
GHX_SetPCMBank:
    jp SetPCMBank               ; 401B  A = this bank, C = first PCM bank + 1
GHX_MuteMusic:
    jp MuteMusic                ; 401E  silence the music, SFX keep playing
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00; 4021

;; Version / copyright string (never executed)
    db "GHX Sound Engine   Ver.00530    (c) 2000 SHIN", $B4, "EN Code: M. Wodok Music: M.Linzner"; 4030

;; GHX_SetPCMBank: A = bank of the sound engine, C = first PCM bank + 1.
;; Copies PCMCopyStub to WRAM (wPCM_CopyStub = $DEED) and patches the bank it
;; switches back to (wPCM_CopyStub+10); wPCM_BankBase = C-1 is added to the
;; bank byte of every PCM instrument. The game calls it with A = $10, C = $11.
SetPCMBank:
    push af                     ; 4080
    ld a, c                     ; 4081
    dec a                       ; 4082
    ld [wPCM_BankBase], a       ; 4083
    ld de, wPCM_CopyStub        ; 4086
    ld hl, PCMCopyStub          ; 4089
    ld c, $0F                   ; 408C
.L408E:
    ld a, [hl+]                 ; 408E
    ld [de], a                  ; 408F
    inc de                      ; 4090
    dec c                       ; 4091
    jr nz, .L408E               ; 4092
    pop af                      ; 4094
    ld [wPCM_CopyStub+10], a    ; 4095
    ret                         ; 4098

;; GHX_SaveSong: remember the playing song (song, subsong, order state,
;; position, transpose + track pointer of each channel) in wSave_* so that
;; a jingle can be played and the music resumed later. Only one level.
SaveSong:
    ld a, [wSaved]              ; 4099
    or a                        ; 409C
    ret nz                      ; 409D
    cpl                         ; 409E
    ld [wSaved], a              ; 409F
    ld a, [wSong]               ; 40A2
    ld [wSave_Song], a          ; 40A5
    ld a, [wSubsong]            ; 40A8
    ld [wSave_Subsong], a       ; 40AB
    ld a, [wOrderSel]           ; 40AE
    ld [wSave_OrderSel], a      ; 40B1
    ld a, [wSpeed]              ; 40B4
    ld [wSave_Speed], a         ; 40B7
    ld a, [wRowsLeft]           ; 40BA
    ld [wSave_RowsLeft], a      ; 40BD
    ld a, [wPosLeft]            ; 40C0
    ld [wSave_PosLeft], a       ; 40C3
    ld a, [wPosPtrLo]           ; 40C6
    ld [wSave_PosPtrLo], a      ; 40C9
    ld a, [wPosPtrHi]           ; 40CC
    ld [wSave_PosPtrHi], a      ; 40CF
    ld a, [wCh1_Transpose]      ; 40D2
    ld [wSave_Channels], a      ; 40D5
    ld a, [wCh1_TrackPtrLo]     ; 40D8
    ld [wSave_Channels+1], a    ; 40DB
    ld a, [wCh1_TrackPtrHi]     ; 40DE
    ld [wSave_Channels+2], a    ; 40E1
    ld a, [wCh2_Transpose]      ; 40E4
    ld [wSave_Channels+3], a    ; 40E7
    ld a, [wCh2_TrackPtrLo]     ; 40EA
    ld [wSave_Channels+4], a    ; 40ED
    ld a, [wCh2_TrackPtrHi]     ; 40F0
    ld [wSave_Channels+5], a    ; 40F3
    ld a, [wCh3_Transpose]      ; 40F6
    ld [wSave_Channels+6], a    ; 40F9
    ld a, [wCh3_TrackPtrLo]     ; 40FC
    ld [wSave_Channels+7], a    ; 40FF
    ld a, [wCh3_TrackPtrHi]     ; 4102
    ld [wSave_Channels+8], a    ; 4105
    ld a, [wCh4_Transpose]      ; 4108
    ld [wSave_Channels+9], a    ; 410B
    ld a, [wCh4_TrackPtrLo]     ; 410E
    ld [wSave_Channels+10], a   ; 4111
    ld a, [wCh4_TrackPtrHi]     ; 4114
    ld [wSave_Channels+11], a   ; 4117
    ret                         ; 411A

;; GHX_Init: A = subsong, C = song (index into SongTable).
;; Copies the 12-byte song header to wHdr_*, clears the channel RAM and
;; switches the APU on.
InitSong:
    push af                     ; 411B
    xor a                       ; 411C
    ld [wEnabled], a            ; 411D
    pop af                      ; 4120
    ld [wSubsong], a            ; 4121
    ld a, $06                   ; 4124
    ld [wSpeed], a              ; 4126
    xor a                       ; 4129
    ld [wTickCount], a          ; 412A
    ld [wReturnFlag], a         ; 412D
    ld [wRowsLeft], a           ; 4130
    ld [wPosLeft], a            ; 4133
    ld [wOrderSel], a           ; 4136
    ld b, $00                   ; 4139
    ld hl, SongTable            ; 413B
    add hl, bc                  ; 413E
    add hl, bc                  ; 413F
    ld a, c                     ; 4140
    ld [wSong], a               ; 4141
    ld a, [hl+]                 ; 4144
    ld c, a                     ; 4145
    ld a, [hl+]                 ; 4146
    ld h, a                     ; 4147
    ld l, c                     ; 4148
    ld de, wHdr_Magic           ; 4149
    ld c, $0C                   ; 414C
InitSong_CopyHeader:
    ld a, [hl+]                 ; 414E
    ld [de], a                  ; 414F
    inc de                      ; 4150
    dec c                       ; 4151
    jr nz, InitSong_CopyHeader  ; 4152
    ld hl, wCh1_Transpose       ; 4154
    ld c, $2C                   ; 4157
    xor a                       ; 4159
.L415A:
    ld [hl+], a                 ; 415A
    ld [hl+], a                 ; 415B
    ld [hl+], a                 ; 415C
    ld [hl+], a                 ; 415D
    dec c                       ; 415E
    jr nz, .L415A               ; 415F

;; APU on: NR52 = $80, NR50 = $77, NR51 = $FF, envelopes off, player enabled.
InitAPU:
    ld a, $80                   ; 4161
    ldh [rNR52], a              ; 4163
    ld a, $77                   ; 4165
    ldh [rNR50], a              ; 4167
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
    xor a                       ; 41FA
    ld [wEnabled], a            ; 41FB
    ld a, $80                   ; 41FE
    ldh [rNR52], a              ; 4200
    ld a, $77                   ; 4202
    ldh [rNR50], a              ; 4204
    ld a, $FF                   ; 4206
    ldh [rNR51], a              ; 4208
    xor a                       ; 420A
    ldh [rNR10], a              ; 420B
    ldh [rNR12], a              ; 420D
    ldh [rNR22], a              ; 420F
    ldh [rNR32], a              ; 4211
    ldh [rNR42], a              ; 4213
    ld a, $FF                   ; 4215
    ld [wEnabled], a            ; 4217
    ret                         ; 421A

;; GHX_Stop: stop the player, NR52 = 0, forget the saved song and the speed adjust.
StopImpl:
    xor a                       ; 421B
    ld [wEnabled], a            ; 421C
    ldh [rNR52], a              ; 421F
    ld [wSaved], a              ; 4221
    ld [wSpeedAdjust], a        ; 4224
    ret                         ; 4227

;; GHX_Pause: stop the player and the APU (song state is kept).
PauseImpl:
    xor a                       ; 4228
    ld [wEnabled], a            ; 4229
    ldh [rNR52], a              ; 422C
    ret                         ; 422E

;; GHX_MuteMusic: wEnabled = $0F (bit 7 clear: the rows stop, SFX continue) and
;; all envelopes set to $0F (silent).
MuteMusic:
    ld a, $0F                   ; 422F
    ld [wEnabled], a            ; 4231
    ldh [rNR12], a              ; 4234
    ldh [rNR22], a              ; 4236
    ldh [rNR32], a              ; 4238
    ldh [rNR42], a              ; 423A
    ret                         ; 423C

;; GHX_Play - call once per frame.
;; A pending wReturnFlag (effect $8x) first resumes the song saved by GHX_SaveSong.
;; wEnabled bit 7 clear (GHX_MuteMusic) = only the instrument/SFX ticks run.
;; When wTickCount reaches 0 the row that PrefetchRow read at the end of the
;; previous frame is decoded (instruments, volume, retrigger) on every channel.
PlayFrame:
    ld a, [wEnabled]            ; 423D
    or a                        ; 4240
    ret z                       ; 4241
    ld a, [wReturnFlag]         ; 4242
    or a                        ; 4245
    jr z, .L424F                ; 4246
    xor a                       ; 4248
    ld [wReturnFlag], a         ; 4249
    jp RestoreSong              ; 424C
.L424F:
    ld b, $00                   ; 424F
    ld a, [wEnabled]            ; 4251
    bit 7, a                    ; 4254
    jp z, Tick                  ; 4256
    ld a, [wTickCount]          ; 4259
    bit 7, a                    ; 425C
    jp nz, Tick                 ; 425E
    or a                        ; 4261
    jp nz, Tick_Count           ; 4262

;; Row on channel 1 (bytes already fetched to wCh1_RowNote/RowIns/RowFx by
;; PrefetchRow, which also handled the $8x and $Fx effects).
Row_Ch1:
    ld hl, wRowsLeft            ; 4265
    dec [hl]                    ; 4268

;; The music is muted on a channel while its SFXTimer <> 0.
Row_Ch1_Decode:
    ld a, [wCh1_SFXTimer]       ; 4269
    or a                        ; 426C
    jp nz, Row_Ch2_Decode       ; 426D
    ld a, [wCh1_RowNote]        ; 4270
    ld e, a                     ; 4273
    ld a, e                     ; 4274
    and $3F                     ; 4275
    jr z, .L427C                ; 4277
    ld [wCh1_Note], a           ; 4279

;; Instrument byte: bits 0-5 = instrument+1 (0 = change the volume only),
;; bits 6-7 = volume shift (envelope volume >> 0/1/2/4: full, 1/2, 1/4, off).
.L427C:
    bit 6, e                    ; 427C
    jp z, Row_Ch2_Decode        ; 427E
    ld a, [wCh1_RowIns]         ; 4281
    and $3F                     ; 4284
    jp nz, Row_Ch1_LoadIns      ; 4286
    ld a, [wCh1_RowIns]         ; 4289
    and $C0                     ; 428C
    jr z, .L42B6                ; 428E
    rlc a                       ; 4290
    rlc a                       ; 4292
    ld [wCh1_VolShift], a       ; 4294
    ld c, a                     ; 4297
    ldh a, [rNR12]              ; 4298
    and $0F                     ; 429A
    ld d, a                     ; 429C
    ldh a, [rNR12]              ; 429D
    inc c                       ; 429F
    dec c                       ; 42A0
    jr z, .L42B1                ; 42A1
    dec c                       ; 42A3
    jr z, .L42AF                ; 42A4
    dec c                       ; 42A6
    jr z, .L42AD                ; 42A7
    srl a                       ; 42A9
    srl a                       ; 42AB
.L42AD:
    srl a                       ; 42AD
.L42AF:
    srl a                       ; 42AF
.L42B1:
    and $F0                     ; 42B1
    or d                        ; 42B3
    ldh [rNR12], a              ; 42B4
.L42B6:
    jp Row_Ch1_Trigger          ; 42B6

;; Square instrument: [flags: bits 0-5 = playlist steps] [playlist speed,
;; bit 7 = vibrato bytes follow] [NRx2 envelope] ([vibrato delay]
;; [depth<<4 | speed]) followed by the 3-byte playlist steps.
Row_Ch1_LoadIns:
    dec a                       ; 42B9
    ld c, a                     ; 42BA
    ld a, [wCh1_RowIns]         ; 42BB
    and $C0                     ; 42BE
    rlc a                       ; 42C0
    rlc a                       ; 42C2
    ld [wCh1_VolShift], a       ; 42C4
    ld a, [wHdr_InstsLo]        ; 42C7
    ld l, a                     ; 42CA
    ld a, [wHdr_InstsHi]        ; 42CB
    ld h, a                     ; 42CE
    add hl, bc                  ; 42CF
    add hl, bc                  ; 42D0
    ld a, [hl+]                 ; 42D1
    ld c, a                     ; 42D2
    ld a, [hl+]                 ; 42D3
    ld h, a                     ; 42D4
    ld l, c                     ; 42D5
    ld a, [hl+]                 ; 42D6
    ld [wCh1_InsFlags], a       ; 42D7
    ld d, a                     ; 42DA
    ld a, [hl+]                 ; 42DB
    ld [wCh1_PLSpeed], a        ; 42DC
    xor a                       ; 42DF
    ld [wCh1_PLTimer], a        ; 42E0
    ld a, $80                   ; 42E3
    ldh [rNR11], a              ; 42E5
    ld a, [wCh1_VolShift]       ; 42E7
    ld c, a                     ; 42EA
    ld a, [hl]                  ; 42EB
    and $0F                     ; 42EC
    ld e, a                     ; 42EE
    ld a, [hl+]                 ; 42EF
    inc c                       ; 42F0
    dec c                       ; 42F1
    jr z, .L4302                ; 42F2
    dec c                       ; 42F4
    jr z, .L4300                ; 42F5
    dec c                       ; 42F7
    jr z, .L42FE                ; 42F8
    srl a                       ; 42FA
    srl a                       ; 42FC
.L42FE:
    srl a                       ; 42FE
.L4300:
    srl a                       ; 4300
.L4302:
    and $F0                     ; 4302
    or e                        ; 4304
    ldh [rNR12], a              ; 4305
    ld a, [wCh1_PLSpeed]        ; 4307
    bit 7, a                    ; 430A
    jr z, .L4322                ; 430C
    ld a, [hl+]                 ; 430E
    ld [wCh1_VibDelay], a       ; 430F
    ld a, [hl+]                 ; 4312
    ld c, a                     ; 4313
    and $0F                     ; 4314
    ld [wCh1_VibSpeed], a       ; 4316
    ld a, c                     ; 4319
    and $F0                     ; 431A
    ld [wCh1_VibDepth], a       ; 431C
    xor a                       ; 431F
    jr .L432C                   ; 4320
.L4322:
    xor a                       ; 4322
    ld [wCh1_VibDelay], a       ; 4323
    ld [wCh1_VibDepth], a       ; 4326
    ld [wCh1_VibSpeed], a       ; 4329
.L432C:
    ld [wCh1_VibPhase], a       ; 432C
    ld a, d                     ; 432F
    and $3F                     ; 4330
    ld [wCh1_PLSteps], a        ; 4332
    ld a, l                     ; 4335
    ld [wCh1_PLPtrLo], a        ; 4336
    ld a, h                     ; 4339
    ld [wCh1_PLPtrHi], a        ; 433A
    xor a                       ; 433D
    cpl                         ; 433E
    ld [wCh1_PLLoops], a        ; 433F

;; Retrigger the channel (NRx4 bit 7).
Row_Ch1_Trigger:
    ld hl, rNR14                ; 4342
    set 7, [hl]                 ; 4345
Row_Ch2_Decode:
    ld a, [wCh2_SFXTimer]       ; 4347
    or a                        ; 434A
    jp nz, Row_Ch3_Decode       ; 434B
    ld a, [wCh2_RowNote]        ; 434E
    ld e, a                     ; 4351
    ld a, e                     ; 4352
    and $3F                     ; 4353
    jr z, .L435A                ; 4355
    ld [wCh2_Note], a           ; 4357
.L435A:
    bit 6, e                    ; 435A
    jp z, Row_Ch3_Decode        ; 435C
    ld a, [wCh2_RowIns]         ; 435F
    and $3F                     ; 4362
    jp nz, Row_Ch2_LoadIns      ; 4364
    ld a, [wCh2_RowIns]         ; 4367
    and $C0                     ; 436A
    jr z, .L4394                ; 436C
    rlc a                       ; 436E
    rlc a                       ; 4370
    ld [wCh2_VolShift], a       ; 4372
    ld c, a                     ; 4375
    ldh a, [rNR22]              ; 4376
    and $0F                     ; 4378
    ld d, a                     ; 437A
    ldh a, [rNR22]              ; 437B
    inc c                       ; 437D
    dec c                       ; 437E
    jr z, .L438F                ; 437F
    dec c                       ; 4381
    jr z, .L438D                ; 4382
    dec c                       ; 4384
    jr z, .L438B                ; 4385
    srl a                       ; 4387
    srl a                       ; 4389
.L438B:
    srl a                       ; 438B
.L438D:
    srl a                       ; 438D
.L438F:
    and $F0                     ; 438F
    or d                        ; 4391
    ldh [rNR22], a              ; 4392
.L4394:
    jp Row_Ch2_Trigger          ; 4394
Row_Ch2_LoadIns:
    dec a                       ; 4397
    ld c, a                     ; 4398
    ld a, [wCh2_RowIns]         ; 4399
    and $C0                     ; 439C
    rlc a                       ; 439E
    rlc a                       ; 43A0
    ld [wCh2_VolShift], a       ; 43A2
    ld a, [wHdr_InstsLo]        ; 43A5
    ld l, a                     ; 43A8
    ld a, [wHdr_InstsHi]        ; 43A9
    ld h, a                     ; 43AC
    add hl, bc                  ; 43AD
    add hl, bc                  ; 43AE
    ld a, [hl+]                 ; 43AF
    ld c, a                     ; 43B0
    ld a, [hl+]                 ; 43B1
    ld h, a                     ; 43B2
    ld l, c                     ; 43B3
    ld a, [hl+]                 ; 43B4
    ld [wCh2_InsFlags], a       ; 43B5
    ld d, a                     ; 43B8
    ld a, [hl+]                 ; 43B9
    ld [wCh2_PLSpeed], a        ; 43BA
    xor a                       ; 43BD
    ld [wCh2_PLTimer], a        ; 43BE
    ld a, $80                   ; 43C1
    ldh [rNR21], a              ; 43C3
    ld a, [wCh2_VolShift]       ; 43C5
    ld c, a                     ; 43C8
    ld a, [hl]                  ; 43C9
    and $0F                     ; 43CA
    ld e, a                     ; 43CC
    ld a, [hl+]                 ; 43CD
    inc c                       ; 43CE
    dec c                       ; 43CF
    jr z, .L43E0                ; 43D0
    dec c                       ; 43D2
    jr z, .L43DE                ; 43D3
    dec c                       ; 43D5
    jr z, .L43DC                ; 43D6
    srl a                       ; 43D8
    srl a                       ; 43DA
.L43DC:
    srl a                       ; 43DC
.L43DE:
    srl a                       ; 43DE
.L43E0:
    and $F0                     ; 43E0
    or e                        ; 43E2
    ldh [rNR22], a              ; 43E3
    ld a, [wCh2_PLSpeed]        ; 43E5
    bit 7, a                    ; 43E8
    jr z, .L4400                ; 43EA
    ld a, [hl+]                 ; 43EC
    ld [wCh2_VibDelay], a       ; 43ED
    ld a, [hl+]                 ; 43F0
    ld c, a                     ; 43F1
    and $0F                     ; 43F2
    ld [wCh2_VibSpeed], a       ; 43F4
    ld a, c                     ; 43F7
    and $F0                     ; 43F8
    ld [wCh2_VibDepth], a       ; 43FA
    xor a                       ; 43FD
    jr .L440A                   ; 43FE
.L4400:
    xor a                       ; 4400
    ld [wCh2_VibDelay], a       ; 4401
    ld [wCh2_VibDepth], a       ; 4404
    ld [wCh2_VibSpeed], a       ; 4407
.L440A:
    ld [wCh2_VibPhase], a       ; 440A
    ld a, d                     ; 440D
    and $3F                     ; 440E
    ld [wCh2_PLSteps], a        ; 4410
    ld a, l                     ; 4413
    ld [wCh2_PLPtrLo], a        ; 4414
    ld a, h                     ; 4417
    ld [wCh2_PLPtrHi], a        ; 4418
    xor a                       ; 441B
    cpl                         ; 441C
    ld [wCh2_PLLoops], a        ; 441D
Row_Ch2_Trigger:
    ld hl, rNR24                ; 4420
    set 7, [hl]                 ; 4423
Row_Ch3_Decode:
    ld a, [wCh3_SFXTimer]       ; 4425
    or a                        ; 4428
    jp nz, Row_Ch4_Decode       ; 4429
    ld a, [wCh3_RowNote]        ; 442C
    ld e, a                     ; 442F
    ld a, e                     ; 4430
    and $3F                     ; 4431
    jr z, .L4438                ; 4433
    ld [wCh3_Note], a           ; 4435
.L4438:
    bit 6, e                    ; 4438
    jp z, Row_Ch4_Decode        ; 443A

;; Ch3: the two volume bits select the NR32 level directly (1 = 25%, 2 = 50%,
;; 3 = 100%); 0 keeps the instrument's level, or mutes on a volume-only row.
    ld a, [wCh3_RowIns]         ; 443D
    and $3F                     ; 4440
    jp nz, Row_Ch3_LoadIns      ; 4442
    ld a, [wCh3_RowIns]         ; 4445
    rrc a                       ; 4448
    jr z, .L4452                ; 444A
    cp $40                      ; 444C
    jr z, .L4452                ; 444E
    xor $40                     ; 4450
.L4452:
    ldh [rNR32], a              ; 4452
    jp Row_Ch4_Decode           ; 4454

;; Channel-3 instrument. Flag bits 5-7 = 0: wave instrument
;; [flags: bits 0-4 steps] [speed] [NR32] (vibrato) [sweep step] [flag byte]
;; [dw position] [dw lower] [dw upper] [sweep speed] [base lo] [base hi] + steps.
;; Flag bits 5-7 <> 0: PCM sample instrument [flags] [bank] [dw sample]
;; [dw blocks]: bits 6-7 = rate index (PCMRateTable), bit 5 = loop. The rate
;; programs TMA/TAC and NR33/NR34 and the timer IRQ is enabled; GHX_TimerISR
;; then streams the sample.
Row_Ch3_LoadIns:
    dec a                       ; 4457
    ld c, a                     ; 4458
    ld a, [wCh3_RowIns]         ; 4459
    and $C0                     ; 445C
    jr z, .L4468                ; 445E
    rrc a                       ; 4460
    cp $40                      ; 4462
    jr z, .L4468                ; 4464
    xor $40                     ; 4466
.L4468:
    ld [wCh3_VolShift], a       ; 4468
    ld a, [wHdr_InstsLo]        ; 446B
    ld l, a                     ; 446E
    ld a, [wHdr_InstsHi]        ; 446F
    ld h, a                     ; 4472
    add hl, bc                  ; 4473
    add hl, bc                  ; 4474
    ld a, [hl+]                 ; 4475
    ld c, a                     ; 4476
    ld a, [hl+]                 ; 4477
    ld h, a                     ; 4478
    ld l, c                     ; 4479
    ld a, [hl+]                 ; 447A
    ld [wCh3_InsFlags], a       ; 447B
    ld d, a                     ; 447E
    and $E0                     ; 447F
    jr z, .L44F1                ; 4481
    rlc a                       ; 4483
    rlc a                       ; 4485
    bit 7, a                    ; 4487
    res 7, a                    ; 4489
    ld [wWave_WaveUpdate_PCMRate], a; 448B
    ld a, $01                   ; 448E
    jr z, .L4494                ; 4490
    or $80                      ; 4492
.L4494:
    push af                     ; 4494
    ld a, [hl+]                 ; 4495
    ld [wWave_SweepOn_PCMBank], a; 4496
    ld [wWave_LowerHi_LoopBank], a; 4499
    ld a, [hl+]                 ; 449C
    ld [wWave_BaseLo_PCMPtrLo], a; 449D
    ld [wWave_SweepSpeed_LoopPtrLo], a; 44A0
    ld a, [hl+]                 ; 44A3
    ld [wWave_BaseHi_PCMPtrHi], a; 44A4
    ld [wWave_UpperLo_LoopPtrHi], a; 44A7
    ld a, [hl+]                 ; 44AA
    ld [wWave_PosLo_PCMLenLo], a; 44AB
    ld [wWave_LowerLo_LoopLenLo], a; 44AE
    ld a, [hl+]                 ; 44B1
    ld [wWave_PosHi_PCMLenHi], a; 44B2
    ld [wWave_UpperHi_LoopLenHi], a; 44B5
    ld hl, PCMRateTable-4       ; 44B8
    ld a, [wWave_WaveUpdate_PCMRate]; 44BB
    add a,a                     ; 44BE
    add a,a                     ; 44BF
    ld c, a                     ; 44C0
    add hl, bc                  ; 44C1
    ld a, [hl+]                 ; 44C2
    ldh [rTMA], a               ; 44C3
    ld a, [hl+]                 ; 44C5
    ldh [rTAC], a               ; 44C6
    ldh a, [rIF]                ; 44C8
    or $04                      ; 44CA
    ldh [rIF], a                ; 44CC
    ld a, [hl+]                 ; 44CE
    ld [wWave_Step_PCMNR33], a  ; 44CF
    ld a, [hl+]                 ; 44D2
    ld [wWave_FlagHi_PCMNR34], a; 44D3
    xor a                       ; 44D6
    ld [wPCM_IRQToggle], a      ; 44D7
    ldh [rNR30], a              ; 44DA
    ld a, $FF                   ; 44DC
    ldh [rNR31], a              ; 44DE
    ld a, $20                   ; 44E0
    ldh [rNR32], a              ; 44E2
    pop af                      ; 44E4
    ld [wWave_PCMFlag], a       ; 44E5
    ldh a, [rIE]                ; 44E8
    or $04                      ; 44EA
    ldh [rIE], a                ; 44EC
    jp Row_Ch4_Decode           ; 44EE
.L44F1:
    ld [wWave_PCMFlag], a       ; 44F1
    ldh a, [rIE]                ; 44F4
    and $FB                     ; 44F6
    ldh [rIE], a                ; 44F8
    ld a, [hl+]                 ; 44FA
    ld [wCh3_PLSpeed], a        ; 44FB
    xor a                       ; 44FE
    ld [wCh3_PLTimer], a        ; 44FF
    ld a, [wCh3_VolShift]       ; 4502
    or a                        ; 4505
    jr z, .L450B                ; 4506
    inc hl                      ; 4508
    jr .L450C                   ; 4509
.L450B:
    ld a, [hl+]                 ; 450B
.L450C:
    ldh [rNR32], a              ; 450C
    xor a                       ; 450E
    ld [wCh3_VolShift], a       ; 450F
    ld a, [wCh3_PLSpeed]        ; 4512
    bit 7, a                    ; 4515
    jr z, .L452D                ; 4517
    ld a, [hl+]                 ; 4519
    ld [wCh3_VibDelay], a       ; 451A
    ld a, [hl+]                 ; 451D
    ld c, a                     ; 451E
    and $0F                     ; 451F
    ld [wCh3_VibSpeed], a       ; 4521
    ld a, c                     ; 4524
    and $F0                     ; 4525
    ld [wCh3_VibDepth], a       ; 4527
    xor a                       ; 452A
    jr .L4537                   ; 452B
.L452D:
    xor a                       ; 452D
    ld [wCh3_VibDelay], a       ; 452E
    ld [wCh3_VibDepth], a       ; 4531
    ld [wCh3_VibSpeed], a       ; 4534
.L4537:
    ld [wCh3_VibPhase], a       ; 4537
    ld a, [hl+]                 ; 453A
    ld [wWave_Step_PCMNR33], a  ; 453B
    xor a                       ; 453E
    ld [wWave_SweepOn_PCMBank], a; 453F
    ld [wWave_FlagHi_PCMNR34], a; 4542
    ld a, [hl+]                 ; 4545
    bit 7, a                    ; 4546
    jr z, .L454D                ; 4548
    ld [wWave_FlagHi_PCMNR34], a; 454A
.L454D:
    and $7F                     ; 454D
    ld [wWave_FlagLo], a        ; 454F
    ld a, [hl+]                 ; 4552
    ld [wWave_PosLo_PCMLenLo], a; 4553
    ld a, [hl+]                 ; 4556
    ld [wWave_PosHi_PCMLenHi], a; 4557
    ld a, [hl+]                 ; 455A
    ld [wWave_LowerLo_LoopLenLo], a; 455B
    ld a, [hl+]                 ; 455E
    ld [wWave_LowerHi_LoopBank], a; 455F
    ld a, [hl+]                 ; 4562
    ld [wWave_UpperLo_LoopPtrHi], a; 4563
    ld a, [hl+]                 ; 4566
    ld [wWave_UpperHi_LoopLenHi], a; 4567
    ld a, [hl+]                 ; 456A
    ld [wWave_SweepSpeed_LoopPtrLo], a; 456B
    ld [wWave_SweepTimer], a    ; 456E
    ld a, [hl+]                 ; 4571
    ld [wWave_BaseLo_PCMPtrLo], a; 4572
    ld a, [hl+]                 ; 4575
    ld [wWave_BaseHi_PCMPtrHi], a; 4576
    ld a, d                     ; 4579
    and $3F                     ; 457A
    ld [wCh3_PLSteps], a        ; 457C
    ld a, l                     ; 457F
    ld [wCh3_PLPtrLo], a        ; 4580
    ld a, h                     ; 4583
    ld [wCh3_PLPtrHi], a        ; 4584
    xor a                       ; 4587
    cpl                         ; 4588
    ld [wCh3_PLLoops], a        ; 4589
    ld a, $FF                   ; 458C
    ld [wWave_WaveUpdate_PCMRate], a; 458E
Row_Ch4_Decode:
    ld a, [wCh4_SFXTimer]       ; 4591
    or a                        ; 4594
    jp nz, Row_Done             ; 4595
    ld a, [wCh4_RowNote]        ; 4598
    ld e, a                     ; 459B
    ld a, e                     ; 459C
    and $3F                     ; 459D
    jr z, .L45A4                ; 459F
    ld [wCh4_Note], a           ; 45A1
.L45A4:
    bit 6, e                    ; 45A4
    jp z, Row_Done              ; 45A6
    ld a, [wCh4_RowIns]         ; 45A9
    and $3F                     ; 45AC
    jp nz, Row_Ch4_LoadIns      ; 45AE
    ld a, [wCh4_RowIns]         ; 45B1
    and $C0                     ; 45B4
    jr z, .L45DE                ; 45B6
    rlc a                       ; 45B8
    rlc a                       ; 45BA
    ld [wCh4_VolShift], a       ; 45BC
    ld c, a                     ; 45BF
    ldh a, [rNR42]              ; 45C0
    and $0F                     ; 45C2
    ld d, a                     ; 45C4
    ldh a, [rNR42]              ; 45C5
    inc c                       ; 45C7
    dec c                       ; 45C8
    jr z, .L45D9                ; 45C9
    dec c                       ; 45CB
    jr z, .L45D7                ; 45CC
    dec c                       ; 45CE
    jr z, .L45D5                ; 45CF
    srl a                       ; 45D1
    srl a                       ; 45D3
.L45D5:
    srl a                       ; 45D5
.L45D7:
    srl a                       ; 45D7
.L45D9:
    and $F0                     ; 45D9
    or d                        ; 45DB
    ldh [rNR42], a              ; 45DC
.L45DE:
    jp Row_Ch4_Trigger          ; 45DE
Row_Ch4_LoadIns:
    dec a                       ; 45E1
    ld c, a                     ; 45E2
    ld a, [wCh4_RowIns]         ; 45E3
    and $C0                     ; 45E6
    rlc a                       ; 45E8
    rlc a                       ; 45EA
    ld [wCh4_VolShift], a       ; 45EC
    ld a, [wHdr_InstsLo]        ; 45EF
    ld l, a                     ; 45F2
    ld a, [wHdr_InstsHi]        ; 45F3
    ld h, a                     ; 45F6
    add hl, bc                  ; 45F7
    add hl, bc                  ; 45F8
    ld a, [hl+]                 ; 45F9
    ld c, a                     ; 45FA
    ld a, [hl+]                 ; 45FB
    ld h, a                     ; 45FC
    ld l, c                     ; 45FD
    ld a, [hl+]                 ; 45FE
    ld [wCh4_InsFlags], a       ; 45FF
    ld d, a                     ; 4602
    ld a, [hl+]                 ; 4603
    ld [wCh4_PLSpeed], a        ; 4604
    xor a                       ; 4607
    ld [wCh4_PLTimer], a        ; 4608
    ld a, $00                   ; 460B
    ldh [rNR41], a              ; 460D
    ld a, [wCh4_VolShift]       ; 460F
    ld c, a                     ; 4612
    ld a, [hl]                  ; 4613
    and $0F                     ; 4614
    ld e, a                     ; 4616
    ld a, [hl+]                 ; 4617
    inc c                       ; 4618
    dec c                       ; 4619
    jr z, .L462A                ; 461A
    dec c                       ; 461C
    jr z, .L4628                ; 461D
    dec c                       ; 461F
    jr z, .L4626                ; 4620
    srl a                       ; 4622
    srl a                       ; 4624
.L4626:
    srl a                       ; 4626
.L4628:
    srl a                       ; 4628
.L462A:
    and $F0                     ; 462A
    or e                        ; 462C
    ldh [rNR42], a              ; 462D
    ld a, d                     ; 462F
    and $3F                     ; 4630
    ld [wCh4_PLSteps], a        ; 4632
    ld a, l                     ; 4635
    ld [wCh4_PLPtrLo], a        ; 4636
    ld a, h                     ; 4639
    ld [wCh4_PLPtrHi], a        ; 463A
    xor a                       ; 463D
    cpl                         ; 463E
    ld [wCh4_PLLoops], a        ; 463F
Row_Ch4_Trigger:
    ld hl, rNR44                ; 4642
    set 7, [hl]                 ; 4645

;; Row done: wTickCount = speed - wSpeedAdjust.
Row_Done:
    ld a, [wSpeedAdjust]        ; 4647
    ld c, a                     ; 464A
    ld a, [wSpeed]              ; 464B
    sub c                       ; 464E
    ld [wTickCount], a          ; 464F
Tick_Count:
    ld hl, wTickCount           ; 4652
    dec [hl]                    ; 4655

;; Per-tick processing of all four channels: instrument playlist, vibrato,
;; frequency. Playlist step = [note] [cmd] [cmd].
;; Note byte: bits 0-5 note (0 = keep), bit 6 = absolute note, otherwise
;; relative to the row note (+transpose; 1 = unison).
;; Command: $00 none, $01-$3F new playlist speed, $40|v volume v (NRx2
;; high nibble, retrigger; ch3: NR32 level), $80|n jump back n steps,
;; $C0|x: bits 2-5 = loop count for the next jump (0 = keep; the default $FF
;; loops forever), bits 0-1 = duty on ch1/2 (3 = keep the duty); on ch3 the
;; command toggles the wave sweep (unless only a loop count is given).
;; BUG in this build: the loop count of ch1/ch2 is written to $001E / $0023
;; (ROM, i.e. the MBC RAM-enable register) instead of wCh1/2_PLLoops, so on
;; the square channels every playlist loop is infinite.
Tick:
    ld a, [wCh1_SFXTimer]       ; 4656
    or a                        ; 4659
    jr z, Tick_Ch1              ; 465A
    dec a                       ; 465C
    ld [wCh1_SFXTimer], a       ; 465D

;; Channel 1 playlist.
Tick_Ch1:
    ld a, [wCh1_PLTimer]        ; 4660
    or a                        ; 4663
    jp nz, Tick_Ch1_Pitch       ; 4664
    ld a, [wCh1_PLSteps]        ; 4667
    or a                        ; 466A
    jp z, Tick_Ch1_PLWait       ; 466B
    dec a                       ; 466E
    ld [wCh1_PLSteps], a        ; 466F
    ld a, [wCh1_PLPtrLo]        ; 4672
    ld l, a                     ; 4675
    ld a, [wCh1_PLPtrHi]        ; 4676
    ld h, a                     ; 4679
    ld a, [hl+]                 ; 467A
    ld [wCh1_PLNoteRaw], a      ; 467B
    and $3F                     ; 467E
    jr z, .L4685                ; 4680
    ld [wCh1_PLNote], a         ; 4682
.L4685:
    ld a, [hl+]                 ; 4685
    bit 7, a                    ; 4686
    jr nz, .L46C6               ; 4688
    bit 6, a                    ; 468A
    jr nz, .L4698               ; 468C
    and $3F                     ; 468E
    jr z, .L4695                ; 4690
    ld [wCh1_PLSpeed], a        ; 4692
.L4695:
    jp .L4708                   ; 4695
.L4698:
    swap a                      ; 4698
    ld d, a                     ; 469A
    ld a, [wCh1_VolShift]       ; 469B
    ld c, a                     ; 469E
    ld a, d                     ; 469F
    inc c                       ; 46A0
    dec c                       ; 46A1
    jr z, .L46B2                ; 46A2
    dec c                       ; 46A4
    jr z, .L46B0                ; 46A5
    dec c                       ; 46A7
    jr z, .L46AE                ; 46A8
    srl a                       ; 46AA
    srl a                       ; 46AC
.L46AE:
    srl a                       ; 46AE
.L46B0:
    srl a                       ; 46B0
.L46B2:
    and $F0                     ; 46B2
    ld c, a                     ; 46B4
    ldh a, [rNR12]              ; 46B5
    and $0F                     ; 46B7
    or c                        ; 46B9
    ldh [rNR12], a              ; 46BA
    push hl                     ; 46BC
    ld hl, rNR14                ; 46BD
    set 7, [hl]                 ; 46C0
    pop hl                      ; 46C2
    jp .L4708                   ; 46C3
.L46C6:
    bit 6, a                    ; 46C6
    jr nz, .L46F3               ; 46C8
    and $3F                     ; 46CA
    ld d, a                     ; 46CC
    cpl                         ; 46CD
    inc a                       ; 46CE
    ld c, a                     ; 46CF
    ld a, [wCh1_PLLoops]        ; 46D0
    or a                        ; 46D3
    jr nz, .L46DC               ; 46D4
    dec a                       ; 46D6
    ld [wCh1_PLLoops], a        ; 46D7
    jr .L46F1                   ; 46DA
.L46DC:
    bit 7, a                    ; 46DC
    jr nz, .L46E4               ; 46DE
    dec a                       ; 46E0
    ld [wCh1_PLLoops], a        ; 46E1
.L46E4:
    dec b                       ; 46E4
    add hl, bc                  ; 46E5
    add hl, bc                  ; 46E6
    add hl, bc                  ; 46E7
    inc b                       ; 46E8
    ld a, [wCh1_PLSteps]        ; 46E9
    ld c, d                     ; 46EC
    add a,c                     ; 46ED
    ld [wCh1_PLSteps], a        ; 46EE
.L46F1:
    jr .L4708                   ; 46F1
.L46F3:
    rrc a                       ; 46F3
    rrc a                       ; 46F5
    ld d, a                     ; 46F7
    and $C0                     ; 46F8
    cp $C0                      ; 46FA
    jr z, .L4700                ; 46FC
    ldh [rNR11], a              ; 46FE
.L4700:
    ld a, d                     ; 4700
    and $0F                     ; 4701
    jr z, .L4708                ; 4703
    ld [$001E], a               ; 4705
.L4708:
    ld a, [hl+]                 ; 4708
    bit 7, a                    ; 4709
    jr nz, .L4749               ; 470B
    bit 6, a                    ; 470D
    jr nz, .L471B               ; 470F
    and $3F                     ; 4711
    jr z, .L4718                ; 4713
    ld [wCh1_PLSpeed], a        ; 4715
.L4718:
    jp .L478B                   ; 4718
.L471B:
    swap a                      ; 471B
    ld d, a                     ; 471D
    ld a, [wCh1_VolShift]       ; 471E
    ld c, a                     ; 4721
    ld a, d                     ; 4722
    inc c                       ; 4723
    dec c                       ; 4724
    jr z, .L4735                ; 4725
    dec c                       ; 4727
    jr z, .L4733                ; 4728
    dec c                       ; 472A
    jr z, .L4731                ; 472B
    srl a                       ; 472D
    srl a                       ; 472F
.L4731:
    srl a                       ; 4731
.L4733:
    srl a                       ; 4733
.L4735:
    and $F0                     ; 4735
    ld c, a                     ; 4737
    ldh a, [rNR12]              ; 4738
    and $0F                     ; 473A
    or c                        ; 473C
    ldh [rNR12], a              ; 473D
    push hl                     ; 473F
    ld hl, rNR14                ; 4740
    set 7, [hl]                 ; 4743
    pop hl                      ; 4745
    jp .L478B                   ; 4746
.L4749:
    bit 6, a                    ; 4749
    jr nz, .L4776               ; 474B
    and $3F                     ; 474D
    ld d, a                     ; 474F
    cpl                         ; 4750
    inc a                       ; 4751
    ld c, a                     ; 4752
    ld a, [wCh1_PLLoops]        ; 4753
    or a                        ; 4756
    jr nz, .L475F               ; 4757
    dec a                       ; 4759
    ld [wCh1_PLLoops], a        ; 475A
    jr .L4774                   ; 475D
.L475F:
    bit 7, a                    ; 475F
    jr nz, .L4767               ; 4761
    dec a                       ; 4763
    ld [wCh1_PLLoops], a        ; 4764
.L4767:
    dec b                       ; 4767
    add hl, bc                  ; 4768
    add hl, bc                  ; 4769
    add hl, bc                  ; 476A
    inc b                       ; 476B
    ld a, [wCh1_PLSteps]        ; 476C
    ld c, d                     ; 476F
    add a,c                     ; 4770
    ld [wCh1_PLSteps], a        ; 4771
.L4774:
    jr .L478B                   ; 4774
.L4776:
    rrc a                       ; 4776
    rrc a                       ; 4778
    ld d, a                     ; 477A
    and $C0                     ; 477B
    cp $C0                      ; 477D
    jr z, .L4783                ; 477F
    ldh [rNR11], a              ; 4781
.L4783:
    ld a, d                     ; 4783
    and $0F                     ; 4784
    jr z, .L478B                ; 4786
    ld [$001E], a               ; 4788
.L478B:
    ld a, l                     ; 478B
    ld [wCh1_PLPtrLo], a        ; 478C
    ld a, h                     ; 478F
    ld [wCh1_PLPtrHi], a        ; 4790
Tick_Ch1_PLWait:
    ld a, [wCh1_PLSpeed]        ; 4793
    res 7, a                    ; 4796
    ld [wCh1_PLTimer], a        ; 4798

;; Frequency = FreqTable[transpose + row note + playlist note - 1] (or the
;; absolute playlist note) + vibrato. Vibrato: after VibDelay ticks the phase
;; advances by VibSpeed (6 bits) and VibratoTable[depth | phase>>2] is added.
Tick_Ch1_Pitch:
    ld hl, wCh1_PLTimer         ; 479B
    dec [hl]                    ; 479E
    ld a, [wCh1_PLNote]         ; 479F
    ld c, a                     ; 47A2
    ld a, [wCh1_PLNoteRaw]      ; 47A3
    bit 6, a                    ; 47A6
    jr nz, .L47B5               ; 47A8
    ld a, [wCh1_Transpose]      ; 47AA
    add a,c                     ; 47AD
    ld c, a                     ; 47AE
    ld a, [wCh1_Note]           ; 47AF
    add a,c                     ; 47B2
    dec a                       ; 47B3
    ld c, a                     ; 47B4
.L47B5:
    ld hl, FreqTable            ; 47B5
    add hl, bc                  ; 47B8
    add hl, bc                  ; 47B9
    ld c, $00                   ; 47BA
    ld a, [wCh1_VibDepth]       ; 47BC
    or a                        ; 47BF
    jr z, .L47F3                ; 47C0
    ld a, [wCh1_VibDelay]       ; 47C2
    dec a                       ; 47C5
    cp $FF                      ; 47C6
    jr z, .L47CF                ; 47C8
    ld [wCh1_VibDelay], a       ; 47CA
    jr .L47F3                   ; 47CD
.L47CF:
    ld a, [wCh1_VibSpeed]       ; 47CF
    ld c, a                     ; 47D2
    ld a, [wCh1_VibPhase]       ; 47D3
    add a,c                     ; 47D6
    and $3F                     ; 47D7
    ld [wCh1_VibPhase], a       ; 47D9
    srl a                       ; 47DC
    srl a                       ; 47DE
    ld c, a                     ; 47E0
    ld a, [wCh1_VibDepth]       ; 47E1
    or c                        ; 47E4
    ld c, a                     ; 47E5
    push hl                     ; 47E6
    ld hl, VibratoTable         ; 47E7
    add hl, bc                  ; 47EA
    ld a, [hl]                  ; 47EB
    pop hl                      ; 47EC
    ld c, a                     ; 47ED
    bit 7, a                    ; 47EE
    jr z, .L47F3                ; 47F0
    dec b                       ; 47F2
.L47F3:
    ld a, [hl+]                 ; 47F3
    ld e, a                     ; 47F4
    ld a, [hl]                  ; 47F5
    ld h, a                     ; 47F6
    ld l, e                     ; 47F7
    add hl, bc                  ; 47F8
    ld b, $00                   ; 47F9
    ld a, l                     ; 47FB
    ldh [rNR13], a              ; 47FC
    ld a, h                     ; 47FE
    ldh [rNR14], a              ; 47FF

;; Channel 2 tick.
Tick_Ch2:
    ld a, [wCh2_SFXTimer]       ; 4801
    or a                        ; 4804
    jr z, .L480B                ; 4805
    dec a                       ; 4807
    ld [wCh2_SFXTimer], a       ; 4808
.L480B:
    ld a, [wCh2_PLTimer]        ; 480B
    or a                        ; 480E
    jp nz, Tick_Ch2_Pitch       ; 480F
    ld a, [wCh2_PLSteps]        ; 4812
    or a                        ; 4815
    jp z, Tick_Ch2_PLWait       ; 4816
    dec a                       ; 4819
    ld [wCh2_PLSteps], a        ; 481A
    ld a, [wCh2_PLPtrLo]        ; 481D
    ld l, a                     ; 4820
    ld a, [wCh2_PLPtrHi]        ; 4821
    ld h, a                     ; 4824
    ld a, [hl+]                 ; 4825
    ld [wCh2_PLNoteRaw], a      ; 4826
    and $3F                     ; 4829
    jr z, .L4830                ; 482B
    ld [wCh2_PLNote], a         ; 482D
.L4830:
    ld a, [hl+]                 ; 4830
    bit 7, a                    ; 4831
    jr nz, .L4871               ; 4833
    bit 6, a                    ; 4835
    jr nz, .L4843               ; 4837
    and $3F                     ; 4839
    jr z, .L4840                ; 483B
    ld [wCh2_PLSpeed], a        ; 483D
.L4840:
    jp .L48B3                   ; 4840
.L4843:
    swap a                      ; 4843
    ld d, a                     ; 4845
    ld a, [wCh2_VolShift]       ; 4846
    ld c, a                     ; 4849
    ld a, d                     ; 484A
    inc c                       ; 484B
    dec c                       ; 484C
    jr z, .L485D                ; 484D
    dec c                       ; 484F
    jr z, .L485B                ; 4850
    dec c                       ; 4852
    jr z, .L4859                ; 4853
    srl a                       ; 4855
    srl a                       ; 4857
.L4859:
    srl a                       ; 4859
.L485B:
    srl a                       ; 485B
.L485D:
    and $F0                     ; 485D
    ld c, a                     ; 485F
    ldh a, [rNR22]              ; 4860
    and $0F                     ; 4862
    or c                        ; 4864
    ldh [rNR22], a              ; 4865
    push hl                     ; 4867
    ld hl, rNR24                ; 4868
    set 7, [hl]                 ; 486B
    pop hl                      ; 486D
    jp .L48B3                   ; 486E
.L4871:
    bit 6, a                    ; 4871
    jr nz, .L489E               ; 4873
    and $3F                     ; 4875
    ld d, a                     ; 4877
    cpl                         ; 4878
    inc a                       ; 4879
    ld c, a                     ; 487A
    ld a, [wCh2_PLLoops]        ; 487B
    or a                        ; 487E
    jr nz, .L4887               ; 487F
    dec a                       ; 4881
    ld [wCh2_PLLoops], a        ; 4882
    jr .L489C                   ; 4885
.L4887:
    bit 7, a                    ; 4887
    jr nz, .L488F               ; 4889
    dec a                       ; 488B
    ld [wCh2_PLLoops], a        ; 488C
.L488F:
    dec b                       ; 488F
    add hl, bc                  ; 4890
    add hl, bc                  ; 4891
    add hl, bc                  ; 4892
    inc b                       ; 4893
    ld a, [wCh2_PLSteps]        ; 4894
    ld c, d                     ; 4897
    add a,c                     ; 4898
    ld [wCh2_PLSteps], a        ; 4899
.L489C:
    jr .L48B3                   ; 489C
.L489E:
    rrc a                       ; 489E
    rrc a                       ; 48A0
    ld d, a                     ; 48A2
    and $C0                     ; 48A3
    cp $C0                      ; 48A5
    jr z, .L48AB                ; 48A7
    ldh [rNR21], a              ; 48A9
.L48AB:
    ld a, d                     ; 48AB
    and $0F                     ; 48AC
    jr z, .L48B3                ; 48AE
    ld [$0023], a               ; 48B0
.L48B3:
    ld a, [hl+]                 ; 48B3
    bit 7, a                    ; 48B4
    jr nz, .L48F4               ; 48B6
    bit 6, a                    ; 48B8
    jr nz, .L48C6               ; 48BA
    and $3F                     ; 48BC
    jr z, .L48C3                ; 48BE
    ld [wCh2_PLSpeed], a        ; 48C0
.L48C3:
    jp .L4936                   ; 48C3
.L48C6:
    swap a                      ; 48C6
    ld d, a                     ; 48C8
    ld a, [wCh2_VolShift]       ; 48C9
    ld c, a                     ; 48CC
    ld a, d                     ; 48CD
    inc c                       ; 48CE
    dec c                       ; 48CF
    jr z, .L48E0                ; 48D0
    dec c                       ; 48D2
    jr z, .L48DE                ; 48D3
    dec c                       ; 48D5
    jr z, .L48DC                ; 48D6
    srl a                       ; 48D8
    srl a                       ; 48DA
.L48DC:
    srl a                       ; 48DC
.L48DE:
    srl a                       ; 48DE
.L48E0:
    and $F0                     ; 48E0
    ld c, a                     ; 48E2
    ldh a, [rNR22]              ; 48E3
    and $0F                     ; 48E5
    or c                        ; 48E7
    ldh [rNR22], a              ; 48E8
    push hl                     ; 48EA
    ld hl, rNR24                ; 48EB
    set 7, [hl]                 ; 48EE
    pop hl                      ; 48F0
    jp .L4936                   ; 48F1
.L48F4:
    bit 6, a                    ; 48F4
    jr nz, .L4921               ; 48F6
    and $3F                     ; 48F8
    ld d, a                     ; 48FA
    cpl                         ; 48FB
    inc a                       ; 48FC
    ld c, a                     ; 48FD
    ld a, [wCh2_PLLoops]        ; 48FE
    or a                        ; 4901
    jr nz, .L490A               ; 4902
    dec a                       ; 4904
    ld [wCh2_PLLoops], a        ; 4905
    jr .L491F                   ; 4908
.L490A:
    bit 7, a                    ; 490A
    jr nz, .L4912               ; 490C
    dec a                       ; 490E
    ld [wCh2_PLLoops], a        ; 490F
.L4912:
    dec b                       ; 4912
    add hl, bc                  ; 4913
    add hl, bc                  ; 4914
    add hl, bc                  ; 4915
    inc b                       ; 4916
    ld a, [wCh2_PLSteps]        ; 4917
    ld c, d                     ; 491A
    add a,c                     ; 491B
    ld [wCh2_PLSteps], a        ; 491C
.L491F:
    jr .L4936                   ; 491F
.L4921:
    rrc a                       ; 4921
    rrc a                       ; 4923
    ld d, a                     ; 4925
    and $C0                     ; 4926
    cp $C0                      ; 4928
    jr z, .L492E                ; 492A
    ldh [rNR21], a              ; 492C
.L492E:
    ld a, d                     ; 492E
    and $0F                     ; 492F
    jr z, .L4936                ; 4931
    ld [$0023], a               ; 4933
.L4936:
    ld a, l                     ; 4936
    ld [wCh2_PLPtrLo], a        ; 4937
    ld a, h                     ; 493A
    ld [wCh2_PLPtrHi], a        ; 493B
Tick_Ch2_PLWait:
    ld a, [wCh2_PLSpeed]        ; 493E
    res 7, a                    ; 4941
    ld [wCh2_PLTimer], a        ; 4943
Tick_Ch2_Pitch:
    ld hl, wCh2_PLTimer         ; 4946
    dec [hl]                    ; 4949
    ld a, [wCh2_PLNote]         ; 494A
    ld c, a                     ; 494D
    ld a, [wCh2_PLNoteRaw]      ; 494E
    bit 6, a                    ; 4951
    jr nz, .L4960               ; 4953
    ld a, [wCh2_Transpose]      ; 4955
    add a,c                     ; 4958
    ld c, a                     ; 4959
    ld a, [wCh2_Note]           ; 495A
    add a,c                     ; 495D
    dec a                       ; 495E
    ld c, a                     ; 495F
.L4960:
    ld hl, FreqTable            ; 4960
    add hl, bc                  ; 4963
    add hl, bc                  ; 4964
    ld c, $00                   ; 4965
    ld a, [wCh2_VibDepth]       ; 4967
    or a                        ; 496A
    jr z, .L499E                ; 496B
    ld a, [wCh2_VibDelay]       ; 496D
    dec a                       ; 4970
    cp $FF                      ; 4971
    jr z, .L497A                ; 4973
    ld [wCh2_VibDelay], a       ; 4975
    jr .L499E                   ; 4978
.L497A:
    ld a, [wCh2_VibSpeed]       ; 497A
    ld c, a                     ; 497D
    ld a, [wCh2_VibPhase]       ; 497E
    add a,c                     ; 4981
    and $3F                     ; 4982
    ld [wCh2_VibPhase], a       ; 4984
    srl a                       ; 4987
    srl a                       ; 4989
    ld c, a                     ; 498B
    ld a, [wCh2_VibDepth]       ; 498C
    or c                        ; 498F
    ld c, a                     ; 4990
    push hl                     ; 4991
    ld hl, VibratoTable         ; 4992
    add hl, bc                  ; 4995
    ld a, [hl]                  ; 4996
    pop hl                      ; 4997
    ld c, a                     ; 4998
    bit 7, a                    ; 4999
    jr z, .L499E                ; 499B
    dec b                       ; 499D
.L499E:
    ld a, [hl+]                 ; 499E
    ld e, a                     ; 499F
    ld a, [hl]                  ; 49A0
    ld h, a                     ; 49A1
    ld l, e                     ; 49A2
    add hl, bc                  ; 49A3
    ld b, $00                   ; 49A4
    ld a, l                     ; 49A6
    ldh [rNR23], a              ; 49A7
    ld a, h                     ; 49A9
    ldh [rNR24], a              ; 49AA

;; Channel 3 tick (skipped completely while wWave_PCMFlag is set).
Tick_Ch3:
    ld a, [wWave_PCMFlag]       ; 49AC
    or a                        ; 49AF
    jp nz, Tick_Ch4             ; 49B0
    ld a, [wCh3_SFXTimer]       ; 49B3
    or a                        ; 49B6
    jr z, .L49C2                ; 49B7
    cp $FF                      ; 49B9
    jp z, Tick_Ch4              ; 49BB
    dec a                       ; 49BE
    ld [wCh3_SFXTimer], a       ; 49BF
.L49C2:
    ld a, [wCh3_PLTimer]        ; 49C2
    or a                        ; 49C5
    jp nz, Tick_Ch3_Sweep       ; 49C6
    ld a, [wCh3_PLSteps]        ; 49C9
    or a                        ; 49CC
    jp z, Tick_Ch3_PLWait       ; 49CD
    dec a                       ; 49D0
    ld [wCh3_PLSteps], a        ; 49D1
    ld a, [wCh3_PLPtrLo]        ; 49D4
    ld l, a                     ; 49D7
    ld a, [wCh3_PLPtrHi]        ; 49D8
    ld h, a                     ; 49DB
    ld a, [hl+]                 ; 49DC
    ld [wCh3_PLNoteRaw], a      ; 49DD
    and $3F                     ; 49E0
    jr z, .L49E7                ; 49E2
    ld [wCh3_PLNote], a         ; 49E4
.L49E7:
    ld a, [hl+]                 ; 49E7
    bit 7, a                    ; 49E8
    jr nz, .L4A0C               ; 49EA
    bit 6, a                    ; 49EC
    jr nz, .L49FA               ; 49EE
    and $3F                     ; 49F0
    jr z, .L49F7                ; 49F2
    ld [wCh3_PLSpeed], a        ; 49F4
.L49F7:
    jp .L4A51                   ; 49F7
.L49FA:
    and $3F                     ; 49FA
    jr z, .L4A07                ; 49FC
    add a,a                     ; 49FE
    swap a                      ; 49FF
    cp $40                      ; 4A01
    jr z, .L4A07                ; 4A03
    xor $40                     ; 4A05
.L4A07:
    ldh [rNR32], a              ; 4A07
    jp .L4A51                   ; 4A09
.L4A0C:
    bit 6, a                    ; 4A0C
    jr nz, .L4A39               ; 4A0E
    and $3F                     ; 4A10
    ld d, a                     ; 4A12
    cpl                         ; 4A13
    inc a                       ; 4A14
    ld c, a                     ; 4A15
    ld a, [wCh3_PLLoops]        ; 4A16
    or a                        ; 4A19
    jr nz, .L4A22               ; 4A1A
    dec a                       ; 4A1C
    ld [wCh3_PLLoops], a        ; 4A1D
    jr .L4A37                   ; 4A20
.L4A22:
    bit 7, a                    ; 4A22
    jr nz, .L4A2A               ; 4A24
    dec a                       ; 4A26
    ld [wCh3_PLLoops], a        ; 4A27
.L4A2A:
    dec b                       ; 4A2A
    add hl, bc                  ; 4A2B
    add hl, bc                  ; 4A2C
    add hl, bc                  ; 4A2D
    inc b                       ; 4A2E
    ld a, [wCh3_PLSteps]        ; 4A2F
    ld c, d                     ; 4A32
    add a,c                     ; 4A33
    ld [wCh3_PLSteps], a        ; 4A34
.L4A37:
    jr .L4A51                   ; 4A37
.L4A39:
    ld d, a                     ; 4A39
    rrc a                       ; 4A3A
    rrc a                       ; 4A3C
    and $0F                     ; 4A3E
    jr z, .L4A4A                ; 4A40
    ld [wCh3_PLLoops], a        ; 4A42
    ld a, d                     ; 4A45
    and $03                     ; 4A46
    jr z, .L4A51                ; 4A48
.L4A4A:
    ld a, [wWave_SweepOn_PCMBank]; 4A4A
    cpl                         ; 4A4D
    ld [wWave_SweepOn_PCMBank], a; 4A4E
.L4A51:
    ld a, [hl+]                 ; 4A51
    bit 7, a                    ; 4A52
    jr nz, .L4A76               ; 4A54
    bit 6, a                    ; 4A56
    jr nz, .L4A64               ; 4A58
    and $3F                     ; 4A5A
    jr z, .L4A61                ; 4A5C
    ld [wCh3_PLSpeed], a        ; 4A5E
.L4A61:
    jp .L4ABB                   ; 4A61
.L4A64:
    and $3F                     ; 4A64
    jr z, .L4A71                ; 4A66
    add a,a                     ; 4A68
    swap a                      ; 4A69
    cp $40                      ; 4A6B
    jr z, .L4A71                ; 4A6D
    xor $40                     ; 4A6F
.L4A71:
    ldh [rNR32], a              ; 4A71
    jp .L4ABB                   ; 4A73
.L4A76:
    bit 6, a                    ; 4A76
    jr nz, .L4AA3               ; 4A78
    and $3F                     ; 4A7A
    ld d, a                     ; 4A7C
    cpl                         ; 4A7D
    inc a                       ; 4A7E
    ld c, a                     ; 4A7F
    ld a, [wCh3_PLLoops]        ; 4A80
    or a                        ; 4A83
    jr nz, .L4A8C               ; 4A84
    dec a                       ; 4A86
    ld [wCh3_PLLoops], a        ; 4A87
    jr .L4AA1                   ; 4A8A
.L4A8C:
    bit 7, a                    ; 4A8C
    jr nz, .L4A94               ; 4A8E
    dec a                       ; 4A90
    ld [wCh3_PLLoops], a        ; 4A91
.L4A94:
    dec b                       ; 4A94
    add hl, bc                  ; 4A95
    add hl, bc                  ; 4A96
    add hl, bc                  ; 4A97
    inc b                       ; 4A98
    ld a, [wCh3_PLSteps]        ; 4A99
    ld c, d                     ; 4A9C
    add a,c                     ; 4A9D
    ld [wCh3_PLSteps], a        ; 4A9E
.L4AA1:
    jr .L4ABB                   ; 4AA1
.L4AA3:
    ld d, a                     ; 4AA3
    rrc a                       ; 4AA4
    rrc a                       ; 4AA6
    and $0F                     ; 4AA8
    jr z, .L4AB4                ; 4AAA
    ld [wCh3_PLLoops], a        ; 4AAC
    ld a, d                     ; 4AAF
    and $03                     ; 4AB0
    jr z, .L4ABB                ; 4AB2
.L4AB4:
    ld a, [wWave_SweepOn_PCMBank]; 4AB4
    cpl                         ; 4AB7
    ld [wWave_SweepOn_PCMBank], a; 4AB8
.L4ABB:
    ld a, l                     ; 4ABB
    ld [wCh3_PLPtrLo], a        ; 4ABC
    ld a, h                     ; 4ABF
    ld [wCh3_PLPtrHi], a        ; 4AC0
Tick_Ch3_PLWait:
    ld a, [wCh3_PLSpeed]        ; 4AC3
    res 7, a                    ; 4AC6
    ld [wCh3_PLTimer], a        ; 4AC8

;; Wave sweep: move the window position between the bounds.
Tick_Ch3_Sweep:
    ld hl, wCh3_PLTimer         ; 4ACB
    dec [hl]                    ; 4ACE
    ld a, [wWave_SweepOn_PCMBank]; 4ACF
    or a                        ; 4AD2
    jp z, Tick_Ch3_WaveRAM      ; 4AD3
    ld a, [wWave_SweepTimer]    ; 4AD6
    or a                        ; 4AD9
    jp nz, .L4B31               ; 4ADA
    ld a, [wWave_PosHi_PCMLenHi]; 4ADD
    ld h, a                     ; 4AE0
    ld a, [wWave_PosLo_PCMLenLo]; 4AE1
    ld l, a                     ; 4AE4
    ld a, [wWave_Step_PCMNR33]  ; 4AE5
    ld c, a                     ; 4AE8
    bit 7, c                    ; 4AE9
    jr z, .L4B0C                ; 4AEB
    dec b                       ; 4AED
    add hl, bc                  ; 4AEE
    inc b                       ; 4AEF
    ld a, h                     ; 4AF0
    ld [wWave_PosHi_PCMLenHi], a; 4AF1
    ld a, l                     ; 4AF4
    ld [wWave_PosLo_PCMLenLo], a; 4AF5
    ld a, [wWave_LowerLo_LoopLenLo]; 4AF8
    cp l                        ; 4AFB
    jr nz, .L4B0A               ; 4AFC
    ld a, [wWave_LowerHi_LoopBank]; 4AFE
    cp h                        ; 4B01
    jr nz, .L4B0A               ; 4B02
    ld a, c                     ; 4B04
    cpl                         ; 4B05
    inc a                       ; 4B06
    ld [wWave_Step_PCMNR33], a  ; 4B07
.L4B0A:
    jr .L4B27                   ; 4B0A
.L4B0C:
    add hl, bc                  ; 4B0C
    ld a, h                     ; 4B0D
    ld [wWave_PosHi_PCMLenHi], a; 4B0E
    ld a, l                     ; 4B11
    ld [wWave_PosLo_PCMLenLo], a; 4B12
    ld a, [wWave_UpperLo_LoopPtrHi]; 4B15
    cp l                        ; 4B18
    jr nz, .L4B27               ; 4B19
    ld a, [wWave_UpperHi_LoopLenHi]; 4B1B
    cp h                        ; 4B1E
    jr nz, .L4B27               ; 4B1F
    ld a, c                     ; 4B21
    cpl                         ; 4B22
    inc a                       ; 4B23
    ld [wWave_Step_PCMNR33], a  ; 4B24
.L4B27:
    ld hl, wWave_WaveUpdate_PCMRate; 4B27
    dec [hl]                    ; 4B2A
    ld a, [wWave_SweepSpeed_LoopPtrLo]; 4B2B
    ld [wWave_SweepTimer], a    ; 4B2E
.L4B31:
    ld hl, wWave_SweepTimer     ; 4B31
    dec [hl]                    ; 4B34

;; wWave_Update = $FF: copy 16 bytes from base+position into wave RAM.
Tick_Ch3_WaveRAM:
    ld a, [wWave_WaveUpdate_PCMRate]; 4B35
    inc a                       ; 4B38
    jp nz, Tick_Ch3_Pitch       ; 4B39
    ld [wWave_WaveUpdate_PCMRate], a; 4B3C
    ld a, [wWave_BaseLo_PCMPtrLo]; 4B3F
    ld c, a                     ; 4B42
    ld a, [wWave_PosLo_PCMLenLo]; 4B43
    add a,c                     ; 4B46
    ld e, a                     ; 4B47
    ld a, [wWave_BaseHi_PCMPtrHi]; 4B48
    ld c, a                     ; 4B4B
    ld a, [wWave_PosHi_PCMLenHi]; 4B4C
    adc a,c                     ; 4B4F
    ld d, a                     ; 4B50
    ld hl, _AUD3WAVERAM         ; 4B51
    xor a                       ; 4B54
    ldh [rNR30], a              ; 4B55
    ld a, [de]                  ; 4B57
    inc de                      ; 4B58
    ld [hl+], a                 ; 4B59
    ld a, [de]                  ; 4B5A
    inc de                      ; 4B5B
    ld [hl+], a                 ; 4B5C
    ld a, [de]                  ; 4B5D
    inc de                      ; 4B5E
    ld [hl+], a                 ; 4B5F
    ld a, [de]                  ; 4B60
    inc de                      ; 4B61
    ld [hl+], a                 ; 4B62
    ld a, [de]                  ; 4B63
    inc de                      ; 4B64
    ld [hl+], a                 ; 4B65
    ld a, [de]                  ; 4B66
    inc de                      ; 4B67
    ld [hl+], a                 ; 4B68
    ld a, [de]                  ; 4B69
    inc de                      ; 4B6A
    ld [hl+], a                 ; 4B6B
    ld a, [de]                  ; 4B6C
    inc de                      ; 4B6D
    ld [hl+], a                 ; 4B6E
    ld a, [de]                  ; 4B6F
    inc de                      ; 4B70
    ld [hl+], a                 ; 4B71
    ld a, [de]                  ; 4B72
    inc de                      ; 4B73
    ld [hl+], a                 ; 4B74
    ld a, [de]                  ; 4B75
    inc de                      ; 4B76
    ld [hl+], a                 ; 4B77
    ld a, [de]                  ; 4B78
    inc de                      ; 4B79
    ld [hl+], a                 ; 4B7A
    ld a, [de]                  ; 4B7B
    inc de                      ; 4B7C
    ld [hl+], a                 ; 4B7D
    ld a, [de]                  ; 4B7E
    inc de                      ; 4B7F
    ld [hl+], a                 ; 4B80
    ld a, [de]                  ; 4B81
    inc de                      ; 4B82
    ld [hl+], a                 ; 4B83
    ld a, [de]                  ; 4B84
    inc de                      ; 4B85
    ld [hl+], a                 ; 4B86
    ld a, $80                   ; 4B87
    ldh [rNR30], a              ; 4B89
    ld hl, rNR34                ; 4B8B
    set 7, [hl]                 ; 4B8E
    xor a                       ; 4B90
    ldh [rNR31], a              ; 4B91
Tick_Ch3_Pitch:
    xor a                       ; 4B93
    ldh [rNR31], a              ; 4B94
    ld a, [wCh3_PLNote]         ; 4B96
    ld c, a                     ; 4B99
    ld a, [wCh3_PLNoteRaw]      ; 4B9A
    bit 6, a                    ; 4B9D
    jr nz, .L4BAC               ; 4B9F
    ld a, [wCh3_Transpose]      ; 4BA1
    add a,c                     ; 4BA4
    ld c, a                     ; 4BA5
    ld a, [wCh3_Note]           ; 4BA6
    add a,c                     ; 4BA9
    dec a                       ; 4BAA
    ld c, a                     ; 4BAB
.L4BAC:
    ld hl, FreqTable            ; 4BAC
    add hl, bc                  ; 4BAF
    add hl, bc                  ; 4BB0
    ld c, $00                   ; 4BB1
    ld a, [wCh3_VibDepth]       ; 4BB3
    or a                        ; 4BB6
    jr z, .L4BEA                ; 4BB7
    ld a, [wCh3_VibDelay]       ; 4BB9
    dec a                       ; 4BBC
    cp $FF                      ; 4BBD
    jr z, .L4BC6                ; 4BBF
    ld [wCh3_VibDelay], a       ; 4BC1
    jr .L4BEA                   ; 4BC4
.L4BC6:
    ld a, [wCh3_VibSpeed]       ; 4BC6
    ld c, a                     ; 4BC9
    ld a, [wCh3_VibPhase]       ; 4BCA
    add a,c                     ; 4BCD
    and $3F                     ; 4BCE
    ld [wCh3_VibPhase], a       ; 4BD0
    srl a                       ; 4BD3
    srl a                       ; 4BD5
    ld c, a                     ; 4BD7
    ld a, [wCh3_VibDepth]       ; 4BD8
    or c                        ; 4BDB
    ld c, a                     ; 4BDC
    push hl                     ; 4BDD
    ld hl, VibratoTable         ; 4BDE
    add hl, bc                  ; 4BE1
    ld a, [hl]                  ; 4BE2
    pop hl                      ; 4BE3
    ld c, a                     ; 4BE4
    bit 7, a                    ; 4BE5
    jr z, .L4BEA                ; 4BE7
    dec b                       ; 4BE9
.L4BEA:
    ld a, [hl+]                 ; 4BEA
    ld e, a                     ; 4BEB
    ld a, [hl]                  ; 4BEC
    ld h, a                     ; 4BED
    ld l, e                     ; 4BEE
    add hl, bc                  ; 4BEF
    ld b, $00                   ; 4BF0
    ld a, l                     ; 4BF2
    ldh [rNR33], a              ; 4BF3
    ld a, h                     ; 4BF5
    ldh [rNR34], a              ; 4BF6
    xor a                       ; 4BF8
    ldh [rNR31], a              ; 4BF9

;; Channel 4 tick: NR43 = NoiseTable[(note + PLnote - 2) / 2].
Tick_Ch4:
    ld a, [wCh4_SFXTimer]       ; 4BFB
    or a                        ; 4BFE
    jr z, .L4C05                ; 4BFF
    dec a                       ; 4C01
    ld [wCh4_SFXTimer], a       ; 4C02
.L4C05:
    ld a, [wCh4_PLTimer]        ; 4C05
    or a                        ; 4C08
    jp nz, Tick_Ch4_Noise       ; 4C09
    ld a, [wCh4_PLSteps]        ; 4C0C
    or a                        ; 4C0F
    jp z, Tick_Ch4_PLWait       ; 4C10
    dec a                       ; 4C13
    ld [wCh4_PLSteps], a        ; 4C14
    ld a, [wCh4_PLPtrLo]        ; 4C17
    ld l, a                     ; 4C1A
    ld a, [wCh4_PLPtrHi]        ; 4C1B
    ld h, a                     ; 4C1E
    ld a, [hl+]                 ; 4C1F
    ld [wCh4_PLNoteRaw], a      ; 4C20
    and $3F                     ; 4C23
    jr z, .L4C2A                ; 4C25
    ld [wCh4_PLNote], a         ; 4C27
.L4C2A:
    ld a, [hl+]                 ; 4C2A
    bit 7, a                    ; 4C2B
    jr nz, .L4C6B               ; 4C2D
    bit 6, a                    ; 4C2F
    jr nz, .L4C3D               ; 4C31
    and $3F                     ; 4C33
    jr z, .L4C3A                ; 4C35
    ld [wCh4_PLSpeed], a        ; 4C37
.L4C3A:
    jp .L4C98                   ; 4C3A
.L4C3D:
    swap a                      ; 4C3D
    ld d, a                     ; 4C3F
    ld a, [wCh4_VolShift]       ; 4C40
    ld c, a                     ; 4C43
    ld a, d                     ; 4C44
    inc c                       ; 4C45
    dec c                       ; 4C46
    jr z, .L4C57                ; 4C47
    dec c                       ; 4C49
    jr z, .L4C55                ; 4C4A
    dec c                       ; 4C4C
    jr z, .L4C53                ; 4C4D
    srl a                       ; 4C4F
    srl a                       ; 4C51
.L4C53:
    srl a                       ; 4C53
.L4C55:
    srl a                       ; 4C55
.L4C57:
    and $F0                     ; 4C57
    ld c, a                     ; 4C59
    ldh a, [rNR42]              ; 4C5A
    and $0F                     ; 4C5C
    or c                        ; 4C5E
    ldh [rNR42], a              ; 4C5F
    push hl                     ; 4C61
    ld hl, rNR44                ; 4C62
    set 7, [hl]                 ; 4C65
    pop hl                      ; 4C67
    jp .L4C98                   ; 4C68
.L4C6B:
    bit 6, a                    ; 4C6B
    jr nz, .L4C98               ; 4C6D
    and $3F                     ; 4C6F
    ld d, a                     ; 4C71
    cpl                         ; 4C72
    inc a                       ; 4C73
    ld c, a                     ; 4C74
    ld a, [wCh4_PLLoops]        ; 4C75
    or a                        ; 4C78
    jr nz, .L4C81               ; 4C79
    dec a                       ; 4C7B
    ld [wCh4_PLLoops], a        ; 4C7C
    jr .L4C96                   ; 4C7F
.L4C81:
    bit 7, a                    ; 4C81
    jr nz, .L4C89               ; 4C83
    dec a                       ; 4C85
    ld [wCh4_PLLoops], a        ; 4C86
.L4C89:
    dec b                       ; 4C89
    add hl, bc                  ; 4C8A
    add hl, bc                  ; 4C8B
    add hl, bc                  ; 4C8C
    inc b                       ; 4C8D
    ld a, [wCh4_PLSteps]        ; 4C8E
    ld c, d                     ; 4C91
    add a,c                     ; 4C92
    ld [wCh4_PLSteps], a        ; 4C93
.L4C96:
    jr .L4C98                   ; 4C96
.L4C98:
    ld a, [hl+]                 ; 4C98
    bit 7, a                    ; 4C99
    jr nz, .L4CD9               ; 4C9B
    bit 6, a                    ; 4C9D
    jr nz, .L4CAB               ; 4C9F
    and $3F                     ; 4CA1
    jr z, .L4CA8                ; 4CA3
    ld [wCh4_PLSpeed], a        ; 4CA5
.L4CA8:
    jp .L4D06                   ; 4CA8
.L4CAB:
    swap a                      ; 4CAB
    ld d, a                     ; 4CAD
    ld a, [wCh4_VolShift]       ; 4CAE
    ld c, a                     ; 4CB1
    ld a, d                     ; 4CB2
    inc c                       ; 4CB3
    dec c                       ; 4CB4
    jr z, .L4CC5                ; 4CB5
    dec c                       ; 4CB7
    jr z, .L4CC3                ; 4CB8
    dec c                       ; 4CBA
    jr z, .L4CC1                ; 4CBB
    srl a                       ; 4CBD
    srl a                       ; 4CBF
.L4CC1:
    srl a                       ; 4CC1
.L4CC3:
    srl a                       ; 4CC3
.L4CC5:
    and $F0                     ; 4CC5
    ld c, a                     ; 4CC7
    ldh a, [rNR42]              ; 4CC8
    and $0F                     ; 4CCA
    or c                        ; 4CCC
    ldh [rNR42], a              ; 4CCD
    push hl                     ; 4CCF
    ld hl, rNR44                ; 4CD0
    set 7, [hl]                 ; 4CD3
    pop hl                      ; 4CD5
    jp .L4D06                   ; 4CD6
.L4CD9:
    bit 6, a                    ; 4CD9
    jr nz, .L4D06               ; 4CDB
    and $3F                     ; 4CDD
    ld d, a                     ; 4CDF
    cpl                         ; 4CE0
    inc a                       ; 4CE1
    ld c, a                     ; 4CE2
    ld a, [wCh4_PLLoops]        ; 4CE3
    or a                        ; 4CE6
    jr nz, .L4CEF               ; 4CE7
    dec a                       ; 4CE9
    ld [wCh4_PLLoops], a        ; 4CEA
    jr .L4D04                   ; 4CED
.L4CEF:
    bit 7, a                    ; 4CEF
    jr nz, .L4CF7               ; 4CF1
    dec a                       ; 4CF3
    ld [wCh4_PLLoops], a        ; 4CF4
.L4CF7:
    dec b                       ; 4CF7
    add hl, bc                  ; 4CF8
    add hl, bc                  ; 4CF9
    add hl, bc                  ; 4CFA
    inc b                       ; 4CFB
    ld a, [wCh4_PLSteps]        ; 4CFC
    ld c, d                     ; 4CFF
    add a,c                     ; 4D00
    ld [wCh4_PLSteps], a        ; 4D01
.L4D04:
    jr .L4D06                   ; 4D04
.L4D06:
    ld a, l                     ; 4D06
    ld [wCh4_PLPtrLo], a        ; 4D07
    ld a, h                     ; 4D0A
    ld [wCh4_PLPtrHi], a        ; 4D0B
Tick_Ch4_PLWait:
    ld a, [wCh4_PLSpeed]        ; 4D0E
    res 7, a                    ; 4D11
    ld [wCh4_PLTimer], a        ; 4D13
Tick_Ch4_Noise:
    ld hl, wCh4_PLTimer         ; 4D16
    dec [hl]                    ; 4D19
    ld a, [wCh4_PLNoteRaw]      ; 4D1A
    ld e, a                     ; 4D1D
    ld a, [wCh4_PLNote]         ; 4D1E
    bit 6, e                    ; 4D21
    jr nz, .L4D2B               ; 4D23
    ld c, a                     ; 4D25
    ld a, [wCh4_Note]           ; 4D26
    add a,c                     ; 4D29
    dec a                       ; 4D2A
.L4D2B:
    dec a                       ; 4D2B
    srl a                       ; 4D2C
    ld c, a                     ; 4D2E
    ld hl, NoiseTable           ; 4D2F
    add hl, bc                  ; 4D32
    ld a, [hl]                  ; 4D33
    ldh [rNR43], a              ; 4D34

;; Row prefetch (new in this build): at the end of the frame in which the row
;; counter reached 0, the next row of every channel is read (and the next
;; position if the pattern is finished) so the new row starts on time next frame.
PrefetchRow:
    ld a, [wTickCount]          ; 4D36
    or a                        ; 4D39
    ret nz                      ; 4D3A
    ld a, [wRowsLeft]           ; 4D3B
    or a                        ; 4D3E
    jp nz, PrefetchRow_Read     ; 4D3F
PrefetchRow_NewPattern:
    ld a, [wHdr_PatLen]         ; 4D42
    ld [wRowsLeft], a           ; 4D45
    ld a, [wPosLeft]            ; 4D48
    or a                        ; 4D4B
    jp nz, NextPosition         ; 4D4C
    ld a, [wHdr_OrdersLo]       ; 4D4F
    ld l, a                     ; 4D52
    ld a, [wHdr_OrdersHi]       ; 4D53
    ld h, a                     ; 4D56
    ld a, [wOrderSel]           ; 4D57
    ld c, a                     ; 4D5A
    or $01                      ; 4D5B
    ld [wOrderSel], a           ; 4D5D
    ld a, [wSubsong]            ; 4D60
    add a,a                     ; 4D63
    add a,c                     ; 4D64
    ld c, a                     ; 4D65
    add hl, bc                  ; 4D66
    add hl, bc                  ; 4D67
    add hl, bc                  ; 4D68
    ld a, [hl+]                 ; 4D69
    ld [wPosLeft], a            ; 4D6A
    ld a, [hl+]                 ; 4D6D
    ld c, a                     ; 4D6E
    ld a, [hl+]                 ; 4D6F
    ld h, a                     ; 4D70
    ld l, c                     ; 4D71
    jr ReadPosition             ; 4D72
NextPosition:
    ld a, [wPosPtrLo]           ; 4D74
    ld l, a                     ; 4D77
    ld a, [wPosPtrHi]           ; 4D78
    ld h, a                     ; 4D7B
    ld a, [wPosLeft]            ; 4D7C
    dec a                       ; 4D7F
    ld [wPosLeft], a            ; 4D80

;; Position = 7 bytes again (as in the 1999 engine): track ch1, transpose ch1,
;; track ch2, transpose ch2, track ch3, transpose ch3, track ch4; track numbers
;; index the song's track pointer table (wHdr_Tracks).
ReadPosition:
    ld a, [hl+]                 ; 4D83
    ld [wCh1_TrackNum], a       ; 4D84
    ld a, [hl+]                 ; 4D87
    ld [wCh1_Transpose], a      ; 4D88
    ld a, [hl+]                 ; 4D8B
    ld [wCh2_TrackNum], a       ; 4D8C
    ld a, [hl+]                 ; 4D8F
    ld [wCh2_Transpose], a      ; 4D90
    ld a, [hl+]                 ; 4D93
    ld [wCh3_TrackNum], a       ; 4D94
    ld a, [hl+]                 ; 4D97
    ld [wCh3_Transpose], a      ; 4D98
    ld a, [hl+]                 ; 4D9B
    ld [wCh4_TrackNum], a       ; 4D9C
    ld a, l                     ; 4D9F
    ld [wPosPtrLo], a           ; 4DA0
    ld a, h                     ; 4DA3
    ld [wPosPtrHi], a           ; 4DA4
    ld a, [wHdr_TracksLo]       ; 4DA7
    ld l, a                     ; 4DAA
    ld a, [wHdr_TracksHi]       ; 4DAB
    ld h, a                     ; 4DAE
    push hl                     ; 4DAF
    ld a, [wCh1_TrackNum]       ; 4DB0
    ld c, a                     ; 4DB3
    add hl, bc                  ; 4DB4
    add hl, bc                  ; 4DB5
    ld a, [hl+]                 ; 4DB6
    ld [wCh1_TrackPtrLo], a     ; 4DB7
    ld a, [hl+]                 ; 4DBA
    ld [wCh1_TrackPtrHi], a     ; 4DBB
    pop hl                      ; 4DBE
    push hl                     ; 4DBF
    ld a, [wCh2_TrackNum]       ; 4DC0
    ld c, a                     ; 4DC3
    add hl, bc                  ; 4DC4
    add hl, bc                  ; 4DC5
    ld a, [hl+]                 ; 4DC6
    ld [wCh2_TrackPtrLo], a     ; 4DC7
    ld a, [hl+]                 ; 4DCA
    ld [wCh2_TrackPtrHi], a     ; 4DCB
    pop hl                      ; 4DCE
    push hl                     ; 4DCF
    ld a, [wCh3_TrackNum]       ; 4DD0
    ld c, a                     ; 4DD3
    add hl, bc                  ; 4DD4
    add hl, bc                  ; 4DD5
    ld a, [hl+]                 ; 4DD6
    ld [wCh3_TrackPtrLo], a     ; 4DD7
    ld a, [hl+]                 ; 4DDA
    ld [wCh3_TrackPtrHi], a     ; 4DDB
    pop hl                      ; 4DDE
    ld a, [wCh4_TrackNum]       ; 4DDF
    ld c, a                     ; 4DE2
    add hl, bc                  ; 4DE3
    add hl, bc                  ; 4DE4
    ld a, [hl+]                 ; 4DE5
    ld [wCh4_TrackPtrLo], a     ; 4DE6
    ld a, [hl+]                 ; 4DE9
    ld [wCh4_TrackPtrHi], a     ; 4DEA
PrefetchRow_Read:
    ld a, [wCh1_TrackPtrLo]     ; 4DED
    ld l, a                     ; 4DF0
    ld a, [wCh1_TrackPtrHi]     ; 4DF1
    ld h, a                     ; 4DF4
    ld a, [hl+]                 ; 4DF5
    ld [wCh1_RowNote], a        ; 4DF6
    ld e, a                     ; 4DF9
    bit 6, e                    ; 4DFA
    jr z, .L4E02                ; 4DFC
    ld a, [hl+]                 ; 4DFE
    ld [wCh1_RowIns], a         ; 4DFF
.L4E02:
    bit 7, e                    ; 4E02
    jr z, .L4E0A                ; 4E04
    ld a, [hl+]                 ; 4E06
    ld [wCh1_RowFx], a          ; 4E07
.L4E0A:
    ld a, l                     ; 4E0A
    ld [wCh1_TrackPtrLo], a     ; 4E0B
    ld a, h                     ; 4E0E
    ld [wCh1_TrackPtrHi], a     ; 4E0F
    bit 7, e                    ; 4E12
    jr z, .L4E32                ; 4E14
    ld a, [wCh1_RowFx]          ; 4E16
    ld c, a                     ; 4E19
    swap c                      ; 4E1A
    and $0F                     ; 4E1C
    sub $08                     ; 4E1E
    jr nz, .L4E28               ; 4E20
    ld a, c                     ; 4E22
    and $0F                     ; 4E23
    ld [wReturnFlag], a         ; 4E25
.L4E28:
    sub $07                     ; 4E28
    jr nz, .L4E32               ; 4E2A
    ld a, c                     ; 4E2C
    and $0F                     ; 4E2D
    ld [wSpeed], a              ; 4E2F
.L4E32:
    ld a, [wCh2_TrackPtrLo]     ; 4E32
    ld l, a                     ; 4E35
    ld a, [wCh2_TrackPtrHi]     ; 4E36
    ld h, a                     ; 4E39
    ld a, [hl+]                 ; 4E3A
    ld [wCh2_RowNote], a        ; 4E3B
    ld e, a                     ; 4E3E
    bit 6, e                    ; 4E3F
    jr z, .L4E47                ; 4E41
    ld a, [hl+]                 ; 4E43
    ld [wCh2_RowIns], a         ; 4E44
.L4E47:
    bit 7, e                    ; 4E47
    jr z, .L4E4F                ; 4E49
    ld a, [hl+]                 ; 4E4B
    ld [wCh2_RowFx], a          ; 4E4C
.L4E4F:
    ld a, l                     ; 4E4F
    ld [wCh2_TrackPtrLo], a     ; 4E50
    ld a, h                     ; 4E53
    ld [wCh2_TrackPtrHi], a     ; 4E54
    bit 7, e                    ; 4E57
    jr z, .L4E77                ; 4E59
    ld a, [wCh2_RowFx]          ; 4E5B
    ld c, a                     ; 4E5E
    swap c                      ; 4E5F
    and $0F                     ; 4E61
    sub $08                     ; 4E63
    jr nz, .L4E6D               ; 4E65
    ld a, c                     ; 4E67
    and $0F                     ; 4E68
    ld [wReturnFlag], a         ; 4E6A
.L4E6D:
    sub $07                     ; 4E6D
    jr nz, .L4E77               ; 4E6F
    ld a, c                     ; 4E71
    and $0F                     ; 4E72
    ld [wSpeed], a              ; 4E74
.L4E77:
    ld a, [wCh3_TrackPtrLo]     ; 4E77
    ld l, a                     ; 4E7A
    ld a, [wCh3_TrackPtrHi]     ; 4E7B
    ld h, a                     ; 4E7E
    ld a, [hl+]                 ; 4E7F
    ld [wCh3_RowNote], a        ; 4E80
    ld e, a                     ; 4E83
    bit 6, e                    ; 4E84
    jr z, .L4E8C                ; 4E86
    ld a, [hl+]                 ; 4E88
    ld [wCh3_RowIns], a         ; 4E89
.L4E8C:
    bit 7, e                    ; 4E8C
    jr z, .L4E94                ; 4E8E
    ld a, [hl+]                 ; 4E90
    ld [wCh3_RowFx], a          ; 4E91
.L4E94:
    ld a, l                     ; 4E94
    ld [wCh3_TrackPtrLo], a     ; 4E95
    ld a, h                     ; 4E98
    ld [wCh3_TrackPtrHi], a     ; 4E99
    bit 7, e                    ; 4E9C
    jr z, .L4EBC                ; 4E9E
    ld a, [wCh3_RowFx]          ; 4EA0
    ld c, a                     ; 4EA3
    swap c                      ; 4EA4
    and $0F                     ; 4EA6
    sub $08                     ; 4EA8
    jr nz, .L4EB2               ; 4EAA
    ld a, c                     ; 4EAC
    and $0F                     ; 4EAD
    ld [wReturnFlag], a         ; 4EAF
.L4EB2:
    sub $07                     ; 4EB2
    jr nz, .L4EBC               ; 4EB4
    ld a, c                     ; 4EB6
    and $0F                     ; 4EB7
    ld [wSpeed], a              ; 4EB9
.L4EBC:
    ld a, [wCh4_TrackPtrLo]     ; 4EBC
    ld l, a                     ; 4EBF
    ld a, [wCh4_TrackPtrHi]     ; 4EC0
    ld h, a                     ; 4EC3
    ld a, [hl+]                 ; 4EC4
    ld [wCh4_RowNote], a        ; 4EC5
    ld e, a                     ; 4EC8
    bit 6, e                    ; 4EC9
    jr z, .L4ED1                ; 4ECB
    ld a, [hl+]                 ; 4ECD
    ld [wCh4_RowIns], a         ; 4ECE
.L4ED1:
    bit 7, e                    ; 4ED1
    jr z, .L4ED9                ; 4ED3
    ld a, [hl+]                 ; 4ED5
    ld [wCh4_RowFx], a          ; 4ED6
.L4ED9:
    ld a, l                     ; 4ED9
    ld [wCh4_TrackPtrLo], a     ; 4EDA
    ld a, h                     ; 4EDD
    ld [wCh4_TrackPtrHi], a     ; 4EDE
    bit 7, e                    ; 4EE1
    jr z, .L4F01                ; 4EE3
    ld a, [wCh4_RowFx]          ; 4EE5
    ld c, a                     ; 4EE8
    swap c                      ; 4EE9
    and $0F                     ; 4EEB
    sub $08                     ; 4EED
    jr nz, .L4EF7               ; 4EEF
    ld a, c                     ; 4EF1
    and $0F                     ; 4EF2
    ld [wReturnFlag], a         ; 4EF4
.L4EF7:
    sub $07                     ; 4EF7
    jr nz, .L4F01               ; 4EF9
    ld a, c                     ; 4EFB
    and $0F                     ; 4EFC
    ld [wSpeed], a              ; 4EFE
.L4F01:
    ret                         ; 4F01

;; GHX_TimerISR: one timer IRQ = one 16-byte block (32 4-bit samples) of PCM.
;; In double-speed mode only every second IRQ is used. The block is copied by
;; PCMCopyStub in WRAM, which maps the sample bank (wPCM_BankBase + bank byte),
;; copies 16 bytes to wave RAM and maps the engine bank back. Samples may cross
;; bank boundaries. Looped samples (flag bit 5) restart, others stop the timer IRQ.
TimerISR:
    ld a, [wWave_PCMFlag]       ; 4F02
    or a                        ; 4F05
    jp z, TimerISR_Done         ; 4F06
    ldh a, [rKEY1]              ; 4F09
    bit 7, a                    ; 4F0B
    jr z, TimerISR_Next         ; 4F0D
    ld a, [wPCM_IRQToggle]      ; 4F0F
    inc a                       ; 4F12
    ld [wPCM_IRQToggle], a      ; 4F13
    bit 0, a                    ; 4F16
    jr nz, TimerISR_Next        ; 4F18
    reti                        ; 4F1A
TimerISR_Next:
    ld a, [wWave_PosLo_PCMLenLo]; 4F1B
    ld l, a                     ; 4F1E
    ld a, [wWave_PosHi_PCMLenHi]; 4F1F
    ld h, a                     ; 4F22
    or l                        ; 4F23
    jr z, TimerISR_SampleEnd    ; 4F24
TimerISR_Block:
    dec hl                      ; 4F26
    ld a, l                     ; 4F27
    ld [wWave_PosLo_PCMLenLo], a; 4F28
    ld a, h                     ; 4F2B
    ld [wWave_PosHi_PCMLenHi], a; 4F2C
    ld a, [wWave_BaseLo_PCMPtrLo]; 4F2F
    ld l, a                     ; 4F32
    ld a, [wWave_BaseHi_PCMPtrHi]; 4F33
    ld h, a                     ; 4F36
    ld de, _AUD3WAVERAM         ; 4F37
    ld b, $10                   ; 4F3A
    di                          ; 4F3C
    ld a, [wWave_SweepOn_PCMBank]; 4F3D
    ld c, a                     ; 4F40
    xor a                       ; 4F41
    ldh [rNR30], a              ; 4F42
    ld a, [wPCM_BankBase]       ; 4F44
    add a,c                     ; 4F47
    call wPCM_CopyStub          ; 4F48
    ld a, $80                   ; 4F4B
    ldh [rNR30], a              ; 4F4D
    ld a, [wWave_Step_PCMNR33]  ; 4F4F
    ldh [rNR33], a              ; 4F52
    ld a, [wWave_FlagHi_PCMNR34]; 4F54
    ldh [rNR34], a              ; 4F57
    ld a, h                     ; 4F59
    cp $80                      ; 4F5A
    jr nz, .L4F67               ; 4F5C
    ld a, [wWave_SweepOn_PCMBank]; 4F5E
    inc a                       ; 4F61
    ld [wWave_SweepOn_PCMBank], a; 4F62
    ld h, $40                   ; 4F65
.L4F67:
    ld a, l                     ; 4F67
    ld [wWave_BaseLo_PCMPtrLo], a; 4F68
    ld a, h                     ; 4F6B
    ld [wWave_BaseHi_PCMPtrHi], a; 4F6C
    ret                         ; 4F6F

;; PCMCopyStub - 15 bytes copied to wPCM_CopyStub ($DEED) by GHX_SetPCMBank and
;; executed there: A = bank, HL = source, DE = $FF30, B = 16.
;; The "ld a, $00" operand (wPCM_CopyStub+10) is patched with the engine bank.
PCMCopyStub:
    ld [$2000], a               ; 4F70
.L4F73:
    ld a, [hl+]                 ; 4F73
    ld [de], a                  ; 4F74
    inc de                      ; 4F75
    dec b                       ; 4F76
    jr nz, .L4F73               ; 4F77
    ld a, $00                   ; 4F79
    ld [$2000], a               ; 4F7B
    ret                         ; 4F7E
TimerISR_SampleEnd:
    ld a, [wWave_PCMFlag]       ; 4F7F
    bit 7, a                    ; 4F82
    jr z, TimerISR_Stop         ; 4F84
    ld a, [wWave_LowerHi_LoopBank]; 4F86
    ld [wWave_SweepOn_PCMBank], a; 4F89
    ld a, [wWave_SweepSpeed_LoopPtrLo]; 4F8C
    ld [wWave_BaseLo_PCMPtrLo], a; 4F8F
    ld a, [wWave_UpperLo_LoopPtrHi]; 4F92
    ld [wWave_BaseHi_PCMPtrHi], a; 4F95
    ld a, [wWave_LowerLo_LoopLenLo]; 4F98
    ld l, a                     ; 4F9B
    ld a, [wWave_UpperHi_LoopLenHi]; 4F9C
    ld h, a                     ; 4F9F
    jp TimerISR_Block           ; 4FA0
TimerISR_Stop:
    xor a                       ; 4FA3
    ldh [rNR30], a              ; 4FA4
    ld [wCh3_SFXTimer], a       ; 4FA6
    cpl                         ; 4FA9
    ld [wPCM_Done], a           ; 4FAA
    ldh a, [rIE]                ; 4FAD
    and $FB                     ; 4FAF
    ldh [rIE], a                ; 4FB1
TimerISR_Done:
    ld a, [wSFX_Ch3Prev]        ; 4FB3
    ld [wSFX_Last], a           ; 4FB6
    ret                         ; 4FB9

;; GHX_PlaySFX: A = effect. SFXTable entry (5 bytes) = [ins ch1] [ins ch2]
;; [ins ch3] [ins ch4] [time]; instruments are 1-based indices into SFXInstTable.
;; Ch3 instruments with flag bits 5-7 set are PCM samples: [flags] [bank]
;; [dw sample] [dw blocks]; bits 6-7 = rate (PCMRateTable), bit 5 = loop.
PlaySFX:
    ld c, a                     ; 4FBA
    ld a, [wEnabled]            ; 4FBB
    push af                     ; 4FBE
    xor a                       ; 4FBF
    ld [wEnabled], a            ; 4FC0
    ld a, c                     ; 4FC3
    ld e, a                     ; 4FC4
    add a,a                     ; 4FC5
    add a,a                     ; 4FC6
    add a,c                     ; 4FC7
    ld c, a                     ; 4FC8
    ld a, $00                   ; 4FC9
    adc a,$00                   ; 4FCB
    ld b, a                     ; 4FCD
    ld hl, SFXTable             ; 4FCE
    add hl, bc                  ; 4FD1
    ld b, $00                   ; 4FD2
    ld a, [hl+]                 ; 4FD4
    ld [wSFX_Ch1], a            ; 4FD5
    ld a, [hl+]                 ; 4FD8
    ld [wSFX_Ch2], a            ; 4FD9
    ld a, [hl+]                 ; 4FDC
    ld [wSFX_Ch3], a            ; 4FDD
    ld a, [hl+]                 ; 4FE0
    ld [wSFX_Ch4], a            ; 4FE1
    ld a, [hl+]                 ; 4FE4
    ld [wSFX_Time], a           ; 4FE5
PlaySFX_Ch1:
    ld a, [wSFX_Ch1]            ; 4FE8
    or a                        ; 4FEB
    jp z, PlaySFX_Ch2           ; 4FEC
    dec a                       ; 4FEF
    ld hl, SFXInstTable         ; 4FF0
    ld c, a                     ; 4FF3
    add hl, bc                  ; 4FF4
    add hl, bc                  ; 4FF5
    ld a, [hl+]                 ; 4FF6
    ld c, a                     ; 4FF7
    ld a, [hl+]                 ; 4FF8
    ld h, a                     ; 4FF9
    ld l, c                     ; 4FFA
    xor a                       ; 4FFB
    ld [wCh1_VolShift], a       ; 4FFC
    ld a, [hl+]                 ; 4FFF
    ld [wCh1_InsFlags], a       ; 5000
    ld d, a                     ; 5003
    ld a, [hl+]                 ; 5004
    ld [wCh1_PLSpeed], a        ; 5005
    xor a                       ; 5008
    ld [wCh1_PLTimer], a        ; 5009
    ld a, $80                   ; 500C
    ldh [rNR11], a              ; 500E
    ld a, [wCh1_VolShift]       ; 5010
    ld c, a                     ; 5013
    ld a, [hl]                  ; 5014
    and $0F                     ; 5015
    ld e, a                     ; 5017
    ld a, [hl+]                 ; 5018
    inc c                       ; 5019
    dec c                       ; 501A
    jr z, .L502B                ; 501B
    dec c                       ; 501D
    jr z, .L5029                ; 501E
    dec c                       ; 5020
    jr z, .L5027                ; 5021
    srl a                       ; 5023
    srl a                       ; 5025
.L5027:
    srl a                       ; 5027
.L5029:
    srl a                       ; 5029
.L502B:
    and $F0                     ; 502B
    or e                        ; 502D
    ldh [rNR12], a              ; 502E
    ld a, [wCh1_PLSpeed]        ; 5030
    bit 7, a                    ; 5033
    jr z, .L504B                ; 5035
    ld a, [hl+]                 ; 5037
    ld [wCh1_VibDelay], a       ; 5038
    ld a, [hl+]                 ; 503B
    ld c, a                     ; 503C
    and $0F                     ; 503D
    ld [wCh1_VibSpeed], a       ; 503F
    ld a, c                     ; 5042
    and $F0                     ; 5043
    ld [wCh1_VibDepth], a       ; 5045
    xor a                       ; 5048
    jr .L5055                   ; 5049
.L504B:
    xor a                       ; 504B
    ld [wCh1_VibDelay], a       ; 504C
    ld [wCh1_VibDepth], a       ; 504F
    ld [wCh1_VibSpeed], a       ; 5052
.L5055:
    ld [wCh1_VibPhase], a       ; 5055
    ld a, d                     ; 5058
    and $3F                     ; 5059
    ld [wCh1_PLSteps], a        ; 505B
    ld a, l                     ; 505E
    ld [wCh1_PLPtrLo], a        ; 505F
    ld a, h                     ; 5062
    ld [wCh1_PLPtrHi], a        ; 5063
    xor a                       ; 5066
    cpl                         ; 5067
    ld [wCh1_PLLoops], a        ; 5068
    ld hl, rNR14                ; 506B
    set 7, [hl]                 ; 506E
    ld a, [wSFX_Time]           ; 5070
    ld [wCh1_SFXTimer], a       ; 5073
PlaySFX_Ch2:
    ld a, [wSFX_Ch2]            ; 5076
    or a                        ; 5079
    jp z, PlaySFX_Ch3           ; 507A
    dec a                       ; 507D
    ld hl, SFXInstTable         ; 507E
    ld c, a                     ; 5081
    add hl, bc                  ; 5082
    add hl, bc                  ; 5083
    ld a, [hl+]                 ; 5084
    ld c, a                     ; 5085
    ld a, [hl+]                 ; 5086
    ld h, a                     ; 5087
    ld l, c                     ; 5088
    xor a                       ; 5089
    ld [wCh2_VolShift], a       ; 508A
    ld a, [hl+]                 ; 508D
    ld [wCh2_InsFlags], a       ; 508E
    ld d, a                     ; 5091
    ld a, [hl+]                 ; 5092
    ld [wCh2_PLSpeed], a        ; 5093
    xor a                       ; 5096
    ld [wCh2_PLTimer], a        ; 5097
    ld a, $80                   ; 509A
    ldh [rNR21], a              ; 509C
    ld a, [wCh2_VolShift]       ; 509E
    ld c, a                     ; 50A1
    ld a, [hl]                  ; 50A2
    and $0F                     ; 50A3
    ld e, a                     ; 50A5
    ld a, [hl+]                 ; 50A6
    inc c                       ; 50A7
    dec c                       ; 50A8
    jr z, .L50B9                ; 50A9
    dec c                       ; 50AB
    jr z, .L50B7                ; 50AC
    dec c                       ; 50AE
    jr z, .L50B5                ; 50AF
    srl a                       ; 50B1
    srl a                       ; 50B3
.L50B5:
    srl a                       ; 50B5
.L50B7:
    srl a                       ; 50B7
.L50B9:
    and $F0                     ; 50B9
    or e                        ; 50BB
    ldh [rNR22], a              ; 50BC
    ld a, [wCh2_PLSpeed]        ; 50BE
    bit 7, a                    ; 50C1
    jr z, .L50D9                ; 50C3
    ld a, [hl+]                 ; 50C5
    ld [wCh2_VibDelay], a       ; 50C6
    ld a, [hl+]                 ; 50C9
    ld c, a                     ; 50CA
    and $0F                     ; 50CB
    ld [wCh2_VibSpeed], a       ; 50CD
    ld a, c                     ; 50D0
    and $F0                     ; 50D1
    ld [wCh2_VibDepth], a       ; 50D3
    xor a                       ; 50D6
    jr .L50E3                   ; 50D7
.L50D9:
    xor a                       ; 50D9
    ld [wCh2_VibDelay], a       ; 50DA
    ld [wCh2_VibDepth], a       ; 50DD
    ld [wCh2_VibSpeed], a       ; 50E0
.L50E3:
    ld [wCh2_VibPhase], a       ; 50E3
    ld a, d                     ; 50E6
    and $3F                     ; 50E7
    ld [wCh2_PLSteps], a        ; 50E9
    ld a, l                     ; 50EC
    ld [wCh2_PLPtrLo], a        ; 50ED
    ld a, h                     ; 50F0
    ld [wCh2_PLPtrHi], a        ; 50F1
    xor a                       ; 50F4
    cpl                         ; 50F5
    ld [wCh2_PLLoops], a        ; 50F6
    ld hl, rNR24                ; 50F9
    set 7, [hl]                 ; 50FC
    ld a, [wSFX_Time]           ; 50FE
    ld [wCh2_SFXTimer], a       ; 5101
PlaySFX_Ch3:
    ld a, [wSFX_Ch3]            ; 5104
    or a                        ; 5107
    jp z, PlaySFX_Ch4           ; 5108
    dec a                       ; 510B
    ld hl, SFXInstTable         ; 510C
    ld c, a                     ; 510F
    add hl, bc                  ; 5110
    add hl, bc                  ; 5111
    ld a, [hl+]                 ; 5112
    ld c, a                     ; 5113
    ld a, [hl+]                 ; 5114
    ld h, a                     ; 5115
    ld l, c                     ; 5116
    ld a, [hl+]                 ; 5117
    ld [wCh3_InsFlags], a       ; 5118
    ld d, a                     ; 511B
    and $E0                     ; 511C
    jr z, .L518E                ; 511E
    rlc a                       ; 5120
    rlc a                       ; 5122
    bit 7, a                    ; 5124
    res 7, a                    ; 5126
    ld [wWave_WaveUpdate_PCMRate], a; 5128
    ld a, $01                   ; 512B
    jr z, .L5131                ; 512D
    or $80                      ; 512F
.L5131:
    push af                     ; 5131
    ld a, [hl+]                 ; 5132
    ld [wWave_SweepOn_PCMBank], a; 5133
    ld [wWave_LowerHi_LoopBank], a; 5136
    ld a, [hl+]                 ; 5139
    ld [wWave_BaseLo_PCMPtrLo], a; 513A
    ld [wWave_SweepSpeed_LoopPtrLo], a; 513D
    ld a, [hl+]                 ; 5140
    ld [wWave_BaseHi_PCMPtrHi], a; 5141
    ld [wWave_UpperLo_LoopPtrHi], a; 5144
    ld a, [hl+]                 ; 5147
    ld [wWave_PosLo_PCMLenLo], a; 5148
    ld [wWave_LowerLo_LoopLenLo], a; 514B
    ld a, [hl+]                 ; 514E
    ld [wWave_PosHi_PCMLenHi], a; 514F
    ld [wWave_UpperHi_LoopLenHi], a; 5152
    ld hl, PCMRateTable-4       ; 5155
    ld a, [wWave_WaveUpdate_PCMRate]; 5158
    add a,a                     ; 515B
    add a,a                     ; 515C
    ld c, a                     ; 515D
    add hl, bc                  ; 515E
    ld a, [hl+]                 ; 515F
    ldh [rTMA], a               ; 5160
    ld a, [hl+]                 ; 5162
    ldh [rTAC], a               ; 5163
    ldh a, [rIF]                ; 5165
    or $04                      ; 5167
    ldh [rIF], a                ; 5169
    ld a, [hl+]                 ; 516B
    ld [wWave_Step_PCMNR33], a  ; 516C
    ld a, [hl+]                 ; 516F
    ld [wWave_FlagHi_PCMNR34], a; 5170
    xor a                       ; 5173
    ld [wPCM_IRQToggle], a      ; 5174
    ldh [rNR30], a              ; 5177
    ld a, $FF                   ; 5179
    ldh [rNR31], a              ; 517B
    ld a, $20                   ; 517D
    ldh [rNR32], a              ; 517F
    pop af                      ; 5181
    ld [wWave_PCMFlag], a       ; 5182
    ldh a, [rIE]                ; 5185
    or $04                      ; 5187
    ldh [rIE], a                ; 5189
    jp .L522E                   ; 518B
.L518E:
    ld [wWave_PCMFlag], a       ; 518E
    ldh a, [rIE]                ; 5191
    and $FB                     ; 5193
    ldh [rIE], a                ; 5195
    ld a, [hl+]                 ; 5197
    ld [wCh3_PLSpeed], a        ; 5198
    xor a                       ; 519B
    ld [wCh3_PLTimer], a        ; 519C
    ld a, [wCh3_VolShift]       ; 519F
    or a                        ; 51A2
    jr z, .L51A8                ; 51A3
    inc hl                      ; 51A5
    jr .L51A9                   ; 51A6
.L51A8:
    ld a, [hl+]                 ; 51A8
.L51A9:
    ldh [rNR32], a              ; 51A9
    xor a                       ; 51AB
    ld [wCh3_VolShift], a       ; 51AC
    ld a, [wCh3_PLSpeed]        ; 51AF
    bit 7, a                    ; 51B2
    jr z, .L51CA                ; 51B4
    ld a, [hl+]                 ; 51B6
    ld [wCh3_VibDelay], a       ; 51B7
    ld a, [hl+]                 ; 51BA
    ld c, a                     ; 51BB
    and $0F                     ; 51BC
    ld [wCh3_VibSpeed], a       ; 51BE
    ld a, c                     ; 51C1
    and $F0                     ; 51C2
    ld [wCh3_VibDepth], a       ; 51C4
    xor a                       ; 51C7
    jr .L51D4                   ; 51C8
.L51CA:
    xor a                       ; 51CA
    ld [wCh3_VibDelay], a       ; 51CB
    ld [wCh3_VibDepth], a       ; 51CE
    ld [wCh3_VibSpeed], a       ; 51D1
.L51D4:
    ld [wCh3_VibPhase], a       ; 51D4
    ld a, [hl+]                 ; 51D7
    ld [wWave_Step_PCMNR33], a  ; 51D8
    xor a                       ; 51DB
    ld [wWave_SweepOn_PCMBank], a; 51DC
    ld [wWave_FlagHi_PCMNR34], a; 51DF
    ld a, [hl+]                 ; 51E2
    bit 7, a                    ; 51E3
    jr z, .L51EA                ; 51E5
    ld [wWave_FlagHi_PCMNR34], a; 51E7
.L51EA:
    and $7F                     ; 51EA
    ld [wWave_FlagLo], a        ; 51EC
    ld a, [hl+]                 ; 51EF
    ld [wWave_PosLo_PCMLenLo], a; 51F0
    ld a, [hl+]                 ; 51F3
    ld [wWave_PosHi_PCMLenHi], a; 51F4
    ld a, [hl+]                 ; 51F7
    ld [wWave_LowerLo_LoopLenLo], a; 51F8
    ld a, [hl+]                 ; 51FB
    ld [wWave_LowerHi_LoopBank], a; 51FC
    ld a, [hl+]                 ; 51FF
    ld [wWave_UpperLo_LoopPtrHi], a; 5200
    ld a, [hl+]                 ; 5203
    ld [wWave_UpperHi_LoopLenHi], a; 5204
    ld a, [hl+]                 ; 5207
    ld [wWave_SweepSpeed_LoopPtrLo], a; 5208
    ld [wWave_SweepTimer], a    ; 520B
    ld a, [hl+]                 ; 520E
    ld [wWave_BaseLo_PCMPtrLo], a; 520F
    ld a, [hl+]                 ; 5212
    ld [wWave_BaseHi_PCMPtrHi], a; 5213
    ld a, d                     ; 5216
    and $3F                     ; 5217
    ld [wCh3_PLSteps], a        ; 5219
    ld a, l                     ; 521C
    ld [wCh3_PLPtrLo], a        ; 521D
    ld a, h                     ; 5220
    ld [wCh3_PLPtrHi], a        ; 5221
    xor a                       ; 5224
    cpl                         ; 5225
    ld [wCh3_PLLoops], a        ; 5226
    ld a, $FF                   ; 5229
    ld [wWave_WaveUpdate_PCMRate], a; 522B
.L522E:
    ld a, [wSFX_Time]           ; 522E
    ld [wCh3_SFXTimer], a       ; 5231
PlaySFX_Ch4:
    ld a, [wSFX_Ch4]            ; 5234
    or a                        ; 5237
    jr z, .L5299                ; 5238
    dec a                       ; 523A
    ld hl, SFXInstTable         ; 523B
    ld c, a                     ; 523E
    add hl, bc                  ; 523F
    add hl, bc                  ; 5240
    ld a, [hl+]                 ; 5241
    ld c, a                     ; 5242
    ld a, [hl+]                 ; 5243
    ld h, a                     ; 5244
    ld l, c                     ; 5245
    xor a                       ; 5246
    ld [wCh4_VolShift], a       ; 5247
    ld a, [hl+]                 ; 524A
    ld [wCh4_InsFlags], a       ; 524B
    ld d, a                     ; 524E
    ld a, [hl+]                 ; 524F
    ld [wCh4_PLSpeed], a        ; 5250
    xor a                       ; 5253
    ld [wCh4_PLTimer], a        ; 5254
    ld a, $00                   ; 5257
    ldh [rNR41], a              ; 5259
    ld a, [wCh4_VolShift]       ; 525B
    ld c, a                     ; 525E
    ld a, [hl]                  ; 525F
    and $0F                     ; 5260
    ld e, a                     ; 5262
    ld a, [hl+]                 ; 5263
    inc c                       ; 5264
    dec c                       ; 5265
    jr z, .L5276                ; 5266
    dec c                       ; 5268
    jr z, .L5274                ; 5269
    dec c                       ; 526B
    jr z, .L5272                ; 526C
    srl a                       ; 526E
    srl a                       ; 5270
.L5272:
    srl a                       ; 5272
.L5274:
    srl a                       ; 5274
.L5276:
    and $F0                     ; 5276
    or e                        ; 5278
    ldh [rNR42], a              ; 5279
    ld a, d                     ; 527B
    and $3F                     ; 527C
    ld [wCh4_PLSteps], a        ; 527E
    ld a, l                     ; 5281
    ld [wCh4_PLPtrLo], a        ; 5282
    ld a, h                     ; 5285
    ld [wCh4_PLPtrHi], a        ; 5286
    xor a                       ; 5289
    cpl                         ; 528A
    ld [wCh4_PLLoops], a        ; 528B
    ld hl, rNR44                ; 528E
    set 7, [hl]                 ; 5291
    ld a, [wSFX_Time]           ; 5293
    ld [wCh4_SFXTimer], a       ; 5296
.L5299:
    pop af                      ; 5299
    ld [wEnabled], a            ; 529A
    ret                         ; 529D

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
    db $90, $57, $63, $63, $55, $55, $80, $47, $53, $53; 5330 
    db $45, $45, $70, $37, $43, $43, $35, $35, $60, $27; 533A 
    db $33, $33, $25, $25, $50, $17, $23, $23, $15, $15; 5344 

;; 16 depths x 16 phases, signed frequency offsets.
VibratoTable:
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00; 534E 
    db $00, $00, $00, $00, $01, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF; 535E 
    db $00, $00, $01, $01, $02, $01, $01, $00, $00, $FF, $FE, $FE, $FE, $FE, $FE, $FF; 536E 
    db $00, $01, $02, $02, $03, $02, $02, $01, $00, $FE, $FD, $FD, $FD, $FD, $FD, $FE; 537E 
    db $00, $01, $02, $03, $04, $03, $02, $01, $00, $FE, $FD, $FC, $FC, $FC, $FD, $FE; 538E 
    db $00, $01, $03, $04, $05, $04, $03, $01, $00, $FE, $FC, $FB, $FB, $FB, $FC, $FE; 539E 
    db $00, $02, $04, $05, $06, $05, $04, $02, $00, $FD, $FB, $FA, $FA, $FA, $FB, $FD; 53AE 
    db $00, $02, $04, $06, $07, $06, $04, $02, $00, $FD, $FB, $F9, $F9, $F9, $FB, $FD; 53BE 
    db $00, $03, $05, $07, $08, $07, $05, $03, $00, $FC, $FA, $F8, $F8, $F8, $FA, $FC; 53CE 
    db $00, $03, $06, $08, $09, $08, $06, $03, $00, $FC, $F9, $F7, $F7, $F7, $F9, $FC; 53DE 
    db $00, $03, $07, $09, $0A, $09, $07, $03, $00, $FC, $F8, $F6, $F6, $F6, $F8, $FC; 53EE 
    db $00, $04, $07, $0A, $0B, $0A, $07, $04, $00, $FB, $F8, $F5, $F5, $F5, $F8, $FB; 53FE 
    db $00, $04, $08, $0B, $0C, $0B, $08, $04, $00, $FB, $F7, $F4, $F4, $F4, $F7, $FB; 540E 
    db $00, $04, $09, $0C, $0D, $0C, $09, $04, $00, $FB, $F6, $F3, $F3, $F3, $F6, $FB; 541E 
    db $00, $05, $09, $0C, $0E, $0C, $09, $05, $00, $FA, $F6, $F3, $F2, $F3, $F6, $FA; 542E 
    db $00, $05, $0A, $0D, $0F, $0D, $0A, $05, $00, $FA, $F5, $F2, $F1, $F2, $F5, $FA; 543E 

;; PCM rates, 4 bytes each: TMA, TAC, NR33, NR34. Indexed 1-3 (code uses PCMRateTable-4).
PCMRateTable:
    db $F0, $04, $00, $87                       ; 544E 
    db $F0, $04, $00, $87                       ; 5452 
    db $E0, $07, $80, $87                       ; 5456 
SongTable:
    dw Song0_Header                              ; 545A  song 0

;; Song header (12 bytes, copied to wHdr_* by GHX_Init).
Song0_Header:
    db "GHX"                                     ; 545C magic
    db 7                                         ; subsongs
    db 32                                        ; rows per pattern
    db $00                                       ; (unused)
    dw Song0_Tracks                              ; track pointer table
    dw Song0_Instruments                         ; instrument pointer table
    dw Song0_Orders                              ; order table

;; Order table: two entries per subsong (intro, loop) = [count] [dw positions];
;; count+1 positions are played. After the intro the loop entry repeats forever.
Song0_Orders:
    db 11 
    dw Song0_Pos000                          ; 5468 subsong 0 intro (12 positions)
    db 11 
    dw Song0_Pos000                          ; 546B subsong 0 loop  (12 positions)
    db 21 
    dw Song0_Pos012                          ; 546E subsong 1 intro (22 positions)
    db 21 
    dw Song0_Pos012                          ; 5471 subsong 1 loop  (22 positions)
    db 27 
    dw Song0_Pos034                          ; 5474 subsong 2 intro (28 positions)
    db 27 
    dw Song0_Pos034                          ; 5477 subsong 2 loop  (28 positions)
    db 19 
    dw Song0_Pos062                          ; 547A subsong 3 intro (20 positions)
    db 19 
    dw Song0_Pos062                          ; 547D subsong 3 loop  (20 positions)
    db 2  
    dw Song0_Pos082                          ; 5480 subsong 4 intro (3 positions)
    db 84 
    dw Song0_Pos000                          ; 5483 subsong 4 loop  (85 positions)
    db 1  
    dw Song0_Pos085                          ; 5486 subsong 5 intro (2 positions)
    db 86 
    dw Song0_Pos000                          ; 5489 subsong 5 loop  (87 positions)
    db 0  
    dw Song0_Pos087                          ; 548C subsong 6 intro (1 positions)
    db 0  
    dw Song0_Pos087                          ; 548F subsong 6 loop  (1 positions)

;; Positions (7 bytes): track ch1, transpose ch1, track ch2, transpose ch2,
;; track ch3, transpose ch3, track ch4 (track = index into the track table).
Song0_Pos000:
    db   1,   0,    0,   0,    0,   0,    2          ; 5492 pos 0
    db   1,   0,    0,   0,    0,   0,    2          ; 5499 pos 1
    db   1,   0,    3,   0,   12,   0,    2          ; 54A0 pos 2
    db   1,   0,    4,   0,   13,   0,    2          ; 54A7 pos 3
    db   1,   0,    5,   0,   14,   0,    2          ; 54AE pos 4
    db   7,   0,    6,   0,   15,   0,    8          ; 54B5 pos 5
    db   1,   0,    3,   0,   12,   0,    2          ; 54BC pos 6
    db   1,   0,    4,   0,   13,   0,    2          ; 54C3 pos 7
    db   1,   0,    9,   0,   16,   0,    2          ; 54CA pos 8
    db  11,   0,   10,   0,   17,   0,    8          ; 54D1 pos 9
    db   1,   0,    0,   0,    0,   0,    2          ; 54D8 pos 10
    db   1,   0,    0,   0,    0,   0,    2          ; 54DF pos 11
Song0_Pos012:
    db  20,   0,    0,   0,   18,   0,   19          ; 54E6 pos 12
    db  20,   0,    0,   0,   21,   0,   19          ; 54ED pos 13
    db  20,   0,   22,   0,   18,   0,   19          ; 54F4 pos 14
    db  20,   0,   23,   0,   21,   0,   19          ; 54FB pos 15
    db  20,   0,   22,   0,   18,   0,   19          ; 5502 pos 16
    db  20,   0,   24,   0,   21,   0,   19          ; 5509 pos 17
    db  20,   0,   27,   0,   18,   0,   19          ; 5510 pos 18
    db  20,   0,   27,   0,   21,   0,   19          ; 5517 pos 19
    db  20,   0,   27,  12,   18,   0,   19          ; 551E pos 20
    db  20,   0,   27,  12,   21,   0,   19          ; 5525 pos 21
    db  20,   0,   22,   0,   18,   0,   19          ; 552C pos 22
    db  20,   0,   23,   0,   21,   0,   19          ; 5533 pos 23
    db  20,   0,   22,   0,   18,   0,   19          ; 553A pos 24
    db  20,   0,   30,   0,   21,   0,   19          ; 5541 pos 25
    db  26,   0,   29,   0,   28,   0,    0          ; 5548 pos 26
    db  26,   0,   31,   0,   28,   0,    0          ; 554F pos 27
    db  26,   0,   29,   0,   28,   0,    0          ; 5556 pos 28
    db  26,   0,   32,   0,   28,   0,    0          ; 555D pos 29
    db  20,   0,   27,   0,   18,   0,   19          ; 5564 pos 30
    db  20,   0,   33,   0,   21,   0,   19          ; 556B pos 31
    db  20,   0,   27,   0,   18,   0,   19          ; 5572 pos 32
    db  20,   0,   33,   0,   21,   0,   19          ; 5579 pos 33
Song0_Pos034:
    db  34,   0,    0,   0,   35,   0,   36          ; 5580 pos 34
    db  34,   0,    0,   0,   35,   0,   36          ; 5587 pos 35
    db  34,   0,   37,   0,   35,   0,   36          ; 558E pos 36
    db  34,   0,   38,   0,   35,   0,   36          ; 5595 pos 37
    db  34,   0,   37,   0,   35,   0,   36          ; 559C pos 38
    db  34,   0,   39,   0,   35,   0,   36          ; 55A3 pos 39
    db  34,   2,   40,   0,   35,   2,   36          ; 55AA pos 40
    db  34,   2,   41,   0,   35,   2,   36          ; 55B1 pos 41
    db  34,   2,   40,   0,   35,   2,   36          ; 55B8 pos 42
    db  34,   2,   42,   0,   35,   2,   36          ; 55BF pos 43
    db  34,   2,    0,   0,   35,   2,   36          ; 55C6 pos 44
    db  34,   2,    0,   0,   35,   2,   36          ; 55CD pos 45
    db  34,   0,   44,   0,   35,   0,   36          ; 55D4 pos 46
    db  34,   0,   44,   0,   35,   0,   36          ; 55DB pos 47
    db  34,   0,   45,   0,   35,   0,   36          ; 55E2 pos 48
    db  34,   0,   45,   0,   35,   0,   36          ; 55E9 pos 49
    db  34,   0,   37,   0,   35,   0,   36          ; 55F0 pos 50
    db  34,   0,   38,   0,   35,   0,   36          ; 55F7 pos 51
    db  34,   0,   37,   0,   35,   0,   36          ; 55FE pos 52
    db  34,   0,   39,   0,   35,   0,   36          ; 5605 pos 53
    db  34,   2,   40,   0,   35,   2,   36          ; 560C pos 54
    db  34,   2,   41,   0,   35,   2,   36          ; 5613 pos 55
    db  34,   2,   40,   0,   35,   2,   36          ; 561A pos 56
    db  34,   2,   42,   0,   35,   2,   36          ; 5621 pos 57
    db  47,   0,   48,   0,   46,   0,   36          ; 5628 pos 58
    db  47,   0,   48,   0,   46,   0,   36          ; 562F pos 59
    db  49,   0,   48,   0,   46,   0,   36          ; 5636 pos 60
    db  49,   0,   48,   0,   46,   0,   36          ; 563D pos 61
Song0_Pos062:
    db  50,   0,    0,   0,   51,   0,   52          ; 5644 pos 62
    db  54,   0,    0,   0,   51,   0,   56          ; 564B pos 63
    db  50,   0,   55,   0,   51,   0,   52          ; 5652 pos 64
    db  54,   0,   57,   0,   51,   0,   56          ; 5659 pos 65
    db  50,   0,   55,   0,   51,   0,   52          ; 5660 pos 66
    db  54,   0,   58,   0,   51,   0,   52          ; 5667 pos 67
    db  61,   0,   63,   0,   59,   0,   52          ; 566E pos 68
    db  62,   0,   64,   0,   60,   0,   52          ; 5675 pos 69
    db  61,  12,   63,   0,   59,   0,   52          ; 567C pos 70
    db  62,  12,   64,   0,   60,   0,   52          ; 5683 pos 71
    db  50,   0,   55,   0,   51,   0,   52          ; 568A pos 72
    db  54,   0,   57,   0,   51,   0,   56          ; 5691 pos 73
    db  50,   0,   55,   0,   51,   0,   52          ; 5698 pos 74
    db  54,   0,   58,   0,   51,   0,   52          ; 569F pos 75
    db  67,   0,   68,   0,   65,   0,   66          ; 56A6 pos 76
    db  50,   0,   69,   0,   51,   0,   52          ; 56AD pos 77
    db  54,   0,   70,   0,   51,   0,   56          ; 56B4 pos 78
    db  50,   0,   69,   0,   51,   0,   52          ; 56BB pos 79
    db  54,   0,   70,   0,   51,   0,   56          ; 56C2 pos 80
    db  67,  12,   68,  12,   65,   0,   66          ; 56C9 pos 81
Song0_Pos082:
    db  73,   0,   77,  12,    0,   0,   72          ; 56D0 pos 82
    db  71,   0,   78,  12,    0,   0,   72          ; 56D7 pos 83
    db  75,   0,   79,   0,    0,   0,   76          ; 56DE pos 84
Song0_Pos085:
    db  80,   0,   80,  12,    0,   0,   81          ; 56E5 pos 85
    db  82,   0,   82,  12,    0,   0,   83          ; 56EC pos 86
Song0_Pos087:
    db   0,   0,    0,   0,    0,   0,    0          ; 56F3 pos 87

;; Track pointer table
Song0_Tracks:
    dw Track000                                  ; 56FA  track 0
    dw Track001                                  ; 56FC  track 1
    dw Track002                                  ; 56FE  track 2
    dw Track003                                  ; 5700  track 3
    dw Track004                                  ; 5702  track 4
    dw Track005                                  ; 5704  track 5
    dw Track006                                  ; 5706  track 6
    dw Track007                                  ; 5708  track 7
    dw Track008                                  ; 570A  track 8
    dw Track009                                  ; 570C  track 9
    dw Track010                                  ; 570E  track 10
    dw Track011                                  ; 5710  track 11
    dw Track012                                  ; 5712  track 12
    dw Track013                                  ; 5714  track 13
    dw Track014                                  ; 5716  track 14
    dw Track015                                  ; 5718  track 15
    dw Track016                                  ; 571A  track 16
    dw Track017                                  ; 571C  track 17
    dw Track018                                  ; 571E  track 18
    dw Track019                                  ; 5720  track 19
    dw Track020                                  ; 5722  track 20
    dw Track021                                  ; 5724  track 21
    dw Track022                                  ; 5726  track 22
    dw Track023                                  ; 5728  track 23
    dw Track024                                  ; 572A  track 24
    dw Track025                                  ; 572C  track 25
    dw Track026                                  ; 572E  track 26
    dw Track027                                  ; 5730  track 27
    dw Track028                                  ; 5732  track 28
    dw Track029                                  ; 5734  track 29
    dw Track030                                  ; 5736  track 30
    dw Track031                                  ; 5738  track 31
    dw Track032                                  ; 573A  track 32
    dw Track033                                  ; 573C  track 33
    dw Track034                                  ; 573E  track 34
    dw Track035                                  ; 5740  track 35
    dw Track036                                  ; 5742  track 36
    dw Track037                                  ; 5744  track 37
    dw Track038                                  ; 5746  track 38
    dw Track039                                  ; 5748  track 39
    dw Track040                                  ; 574A  track 40
    dw Track041                                  ; 574C  track 41
    dw Track042                                  ; 574E  track 42
    dw Track043                                  ; 5750  track 43
    dw Track044                                  ; 5752  track 44
    dw Track045                                  ; 5754  track 45
    dw Track046                                  ; 5756  track 46
    dw Track047                                  ; 5758  track 47
    dw Track048                                  ; 575A  track 48
    dw Track049                                  ; 575C  track 49
    dw Track050                                  ; 575E  track 50
    dw Track051                                  ; 5760  track 51
    dw Track052                                  ; 5762  track 52
    dw Track053                                  ; 5764  track 53
    dw Track054                                  ; 5766  track 54
    dw Track055                                  ; 5768  track 55
    dw Track056                                  ; 576A  track 56
    dw Track057                                  ; 576C  track 57
    dw Track058                                  ; 576E  track 58
    dw Track059                                  ; 5770  track 59
    dw Track060                                  ; 5772  track 60
    dw Track061                                  ; 5774  track 61
    dw Track062                                  ; 5776  track 62
    dw Track063                                  ; 5778  track 63
    dw Track064                                  ; 577A  track 64
    dw Track065                                  ; 577C  track 65
    dw Track066                                  ; 577E  track 66
    dw Track067                                  ; 5780  track 67
    dw Track068                                  ; 5782  track 68
    dw Track069                                  ; 5784  track 69
    dw Track070                                  ; 5786  track 70
    dw Track071                                  ; 5788  track 71
    dw Track072                                  ; 578A  track 72
    dw Track073                                  ; 578C  track 73
    dw Track074                                  ; 578E  track 74
    dw Track075                                  ; 5790  track 75
    dw Track076                                  ; 5792  track 76
    dw Track077                                  ; 5794  track 77
    dw Track078                                  ; 5796  track 78
    dw Track079                                  ; 5798  track 79
    dw Track080                                  ; 579A  track 80
    dw Track081                                  ; 579C  track 81
    dw Track082                                  ; 579E  track 82
    dw Track083                                  ; 57A0  track 83
Song0_Instruments:
    dw Inst00                                    ; 57A2  instrument 0 (ch1,ch2)
    dw Inst01                                    ; 57A4  instrument 1 (ch4)
    dw Inst02                                    ; 57A6  instrument 2 (ch4)
    dw Inst03                                    ; 57A8  instrument 3 (ch4)
    dw Inst04                                    ; 57AA  instrument 4 (ch2)
    dw Inst05                                    ; 57AC  instrument 5 (ch3)
    dw Inst06                                    ; 57AE  instrument 6 (ch1)
    dw Inst07                                    ; 57B0  instrument 7 (ch3)
    dw Inst08                                    ; 57B2  instrument 8 (unused)
    dw Inst09                                    ; 57B4  instrument 9 (ch2)
    dw Inst10                                    ; 57B6  instrument 10 (ch2)
    dw Inst11                                    ; 57B8  instrument 11 (ch1)
    dw Inst12                                    ; 57BA  instrument 12 (ch1,ch2)
    dw Inst13                                    ; 57BC  instrument 13 (unused)
    dw Inst14                                    ; 57BE  instrument 14 (ch2)
    dw Inst15                                    ; 57C0  instrument 15 (ch1)
    dw Inst16                                    ; 57C2  instrument 16 (ch2)
    dw Inst17                                    ; 57C4  instrument 17 (ch1,ch2)
    dw Inst18                                    ; 57C6  instrument 18 (ch1,ch2)
    dw Inst19                                    ; 57C8  instrument 19 (ch2)
    dw Inst20                                    ; 57CA  instrument 20 (ch2)
    dw Inst21                                    ; 57CC  instrument 21 (unused)
    dw Inst22                                    ; 57CE  instrument 22 (ch1)
    dw Inst23                                    ; 57D0  instrument 23 (ch1)
    dw Inst24                                    ; 57D2  instrument 24 (ch1)
Inst00:
    db $06                                       ; 57D4 square, 6 steps
    db $03                                       ; playlist speed
    db $F0                                       ; NRx2 envelope
    db $01, $C2, $4F                             ; step 0: +0  duty 2, vol 15
    db $00, $00, $4A                             ; step 1: -  vol 10
    db $00, $00, $C1                             ; step 2: -  duty 1
    db $00, $00, $C0                             ; step 3: -  duty 0
    db $00, $00, $C1                             ; step 4: -  duty 1
    db $00, $C2, $84                             ; step 5: -  duty 2, jump -4
Inst01:
    db $04                                       ; 57E9 noise, 4 steps
    db $01                                       ; playlist speed
    db $90                                       ; NR42 envelope
    db $65, $00, $00                             ; step 0: C-5
    db $59, $00, $00                             ; step 1: C-4
    db $40, $00, $40                             ; step 2: -  vol 0
    db $00, $00, $00                             ; step 3: -
Inst02:
    db $03                                       ; 57F8 noise, 3 steps
    db $01                                       ; playlist speed
    db $95                                       ; NR42 envelope
    db $7A, $00, $49                             ; step 0: A-6  vol 9
    db $40, $00, $42                             ; step 1: -  vol 2
    db $00, $00, $00                             ; step 2: -
Inst03:
    db $06                                       ; 5804 noise, 6 steps
    db $01                                       ; playlist speed
    db $D3                                       ; NR42 envelope
    db $7A, $00, $00                             ; step 0: A-6
    db $71, $00, $00                             ; step 1: C-6
    db $59, $00, $46                             ; step 2: C-4  vol 6
    db $7A, $00, $00                             ; step 3: A-6
    db $71, $00, $00                             ; step 4: C-6
    db $59, $00, $83                             ; step 5: C-4  jump -3
Inst04:
    db $03                                       ; 5819 square, 3 steps
    db $81                                       ; playlist speed | $80 = vibrato
    db $B0                                       ; NRx2 envelope
    db $0A, $49                                  ; vibrato delay, depth<<4|speed
    db $01, $4F, $C2                             ; step 0: +0  vol 15, duty 2
    db $00, $00, $48                             ; step 1: -  vol 8
    db $00, $C1, $00                             ; step 2: -  duty 1
Inst05:
    db $01                                       ; 5827 wave, 1 steps
    db $81                                       ; playlist speed | $80 = vibrato
    db $40                                       ; NR32 level
    db $0A, $48                                  ; vibrato delay, depth<<4|speed
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0000, $001E                       ; position, lower bound, upper bound
    db $01                                       ; sweep speed
    db LOW(WaveData00), HIGH(WaveData00)         ; wave data base
    db $0D, $00, $00                             ; step 0: +12
Inst06:
    db $04                                       ; 583A square, 4 steps
    db $02                                       ; playlist speed
    db $B7                                       ; NRx2 envelope
    db $0D, $00, $C1                             ; step 0: +12  duty 1
    db $10, $00, $00                             ; step 1: +15
    db $14, $00, $C2                             ; step 2: +19  duty 2
    db $17, $00, $84                             ; step 3: +22  jump -4
Inst07:
    db $03                                       ; 5849 wave, 3 steps
    db $05                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0002, $000E                       ; position, lower bound, upper bound
    db $08                                       ; sweep speed
    db LOW(WaveData00), HIGH(WaveData00)         ; wave data base
    db $0D, $00, $C0                             ; step 0: +12  sweep on/off
    db $01, $00, $00                             ; step 1: +0
    db $00, $00, $00                             ; step 2: -
Inst08:
    db $04                                       ; 5860 wave, 4 steps
    db $84                                       ; playlist speed | $80 = vibrato
    db $20                                       ; NR32 level
    db $0A, $48                                  ; vibrato delay, depth<<4|speed
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $000E, $0002, $000E                       ; position, lower bound, upper bound
    db $10                                       ; sweep speed
    db LOW(WaveData00), HIGH(WaveData00)         ; wave data base
    db $0D, $00, $00                             ; step 0: +12
    db $01, $00, $00                             ; step 1: +0
    db $00, $00, $00                             ; step 2: -
    db $00, $00, $42                             ; step 3: -  level 2
Inst09:
    db $03                                       ; 587C square, 3 steps
    db $81                                       ; playlist speed | $80 = vibrato
    db $B0                                       ; NRx2 envelope
    db $0F, $38                                  ; vibrato delay, depth<<4|speed
    db $0D, $4F, $C2                             ; step 0: +12  vol 15, duty 2
    db $01, $00, $4B                             ; step 1: +0  vol 11
    db $00, $00, $C1                             ; step 2: -  duty 1
Inst10:
    db $02                                       ; 588A square, 2 steps
    db $82                                       ; playlist speed | $80 = vibrato
    db $B1                                       ; NRx2 envelope
    db $0F, $38                                  ; vibrato delay, depth<<4|speed
    db $0D, $00, $C2                             ; step 0: +12  duty 2
    db $01, $00, $82                             ; step 1: +0  jump -2
Inst11:
    db $04                                       ; 5895 square, 4 steps
    db $02                                       ; playlist speed
    db $B7                                       ; NRx2 envelope
    db $08, $00, $C1                             ; step 0: +7  duty 1
    db $0B, $00, $00                             ; step 1: +10
    db $0F, $00, $C2                             ; step 2: +14  duty 2
    db $12, $00, $84                             ; step 3: +17  jump -4
Inst12:
    db $05                                       ; 58A4 square, 5 steps
    db $02                                       ; playlist speed
    db $D7                                       ; NRx2 envelope
    db $0D, $00, $C2                             ; step 0: +12  duty 2
    db $01, $00, $44                             ; step 1: +0  vol 4
    db $0D, $00, $00                             ; step 2: +12
    db $01, $00, $00                             ; step 3: +0
    db $00, $00, $40                             ; step 4: -  vol 0
Inst13:
    db $00                                       ; 58B6 square, 0 steps
    db $01                                       ; playlist speed
    db $00                                       ; NRx2 envelope
Inst14:
    db $03                                       ; 58B9 square, 3 steps
    db $81                                       ; playlist speed | $80 = vibrato
    db $B7                                       ; NRx2 envelope
    db $0F, $38                                  ; vibrato delay, depth<<4|speed
    db $01, $00, $C2                             ; step 0: +0  duty 2
    db $00, $00, $00                             ; step 1: -
    db $00, $00, $00                             ; step 2: -
Inst15:
    db $04                                       ; 58C7 square, 4 steps
    db $01                                       ; playlist speed
    db $E1                                       ; NRx2 envelope
    db $11, $00, $C0                             ; step 0: +16  duty 0
    db $14, $00, $00                             ; step 1: +19
    db $18, $00, $00                             ; step 2: +23
    db $1B, $00, $84                             ; step 3: +26  jump -4
Inst16:
    db $04                                       ; 58D6 square, 4 steps
    db $86                                       ; playlist speed | $80 = vibrato
    db $90                                       ; NRx2 envelope
    db $0F, $28                                  ; vibrato delay, depth<<4|speed
    db $01, $00, $C2                             ; step 0: +0  duty 2
    db $00, $00, $C1                             ; step 1: -  duty 1
    db $00, $00, $C0                             ; step 2: -  duty 0
    db $00, $C1, $84                             ; step 3: -  duty 1, jump -4
Inst17:
    db $02                                       ; 58E7 square, 2 steps
    db $04                                       ; playlist speed
    db $87                                       ; NRx2 envelope
    db $01, $00, $C2                             ; step 0: +0  duty 2
    db $0D, $C1, $82                             ; step 1: +12  duty 1, jump -2
Inst18:
    db $03                                       ; 58F0 square, 3 steps
    db $03                                       ; playlist speed
    db $87                                       ; NRx2 envelope
    db $01, $00, $C1                             ; step 0: +0  duty 1
    db $0D, $00, $00                             ; step 1: +12
    db $19, $00, $83                             ; step 2: +24  jump -3
Inst19:
    db $04                                       ; 58FC square, 4 steps
    db $01                                       ; playlist speed
    db $E1                                       ; NRx2 envelope
    db $0F, $00, $C0                             ; step 0: +14  duty 0
    db $11, $00, $00                             ; step 1: +16
    db $13, $00, $00                             ; step 2: +18
    db $16, $00, $84                             ; step 3: +21  jump -4
Inst20:
    db $04                                       ; 590B square, 4 steps
    db $01                                       ; playlist speed
    db $E1                                       ; NRx2 envelope
    db $0D, $00, $C0                             ; step 0: +12  duty 0
    db $12, $00, $00                             ; step 1: +17
    db $16, $00, $00                             ; step 2: +21
    db $19, $00, $84                             ; step 3: +24  jump -4
Inst21:
    db $00                                       ; 591A square, 0 steps
    db $01                                       ; playlist speed
    db $00                                       ; NRx2 envelope
Inst22:
    db $02                                       ; 591D square, 2 steps
    db $03                                       ; playlist speed
    db $C3                                       ; NRx2 envelope
    db $0D, $00, $C1                             ; step 0: +12  duty 1
    db $11, $00, $82                             ; step 1: +16  jump -2
Inst23:
    db $02                                       ; 5926 square, 2 steps
    db $03                                       ; playlist speed
    db $C3                                       ; NRx2 envelope
    db $0D, $00, $C1                             ; step 0: +12  duty 1
    db $10, $00, $82                             ; step 1: +15  jump -2
Inst24:
    db $02                                       ; 592F square, 2 steps
    db $03                                       ; playlist speed
    db $C3                                       ; NRx2 envelope
    db $0D, $00, $C1                             ; step 0: +12  duty 1
    db $12, $00, $82                             ; step 1: +17  jump -2
Track000:
    R   ___                                     ; 5938 row 00
    R   ___                                     ; 5939 row 01
    R   ___                                     ; 593A row 02
    R   ___                                     ; 593B row 03
    R   ___                                     ; 593C row 04
    R   ___                                     ; 593D row 05
    R   ___                                     ; 593E row 06
    R   ___                                     ; 593F row 07
    R   ___                                     ; 5940 row 08
    R   ___                                     ; 5941 row 09
    R   ___                                     ; 5942 row 10
    R   ___                                     ; 5943 row 11
    R   ___                                     ; 5944 row 12
    R   ___                                     ; 5945 row 13
    R   ___                                     ; 5946 row 14
    R   ___                                     ; 5947 row 15
    R   ___                                     ; 5948 row 16
    R   ___                                     ; 5949 row 17
    R   ___                                     ; 594A row 18
    R   ___                                     ; 594B row 19
    R   ___                                     ; 594C row 20
    R   ___                                     ; 594D row 21
    R   ___                                     ; 594E row 22
    R   ___                                     ; 594F row 23
    R   ___                                     ; 5950 row 24
    R   ___                                     ; 5951 row 25
    R   ___                                     ; 5952 row 26
    R   ___                                     ; 5953 row 27
    R   ___                                     ; 5954 row 28
    R   ___                                     ; 5955 row 29
    R   ___                                     ; 5956 row 30
    R   ___                                     ; 5957 row 31
Track001:
    RI  Ds3, 1, 0                               ; 5958 row 00  Inst00
    R   ___                                     ; 595A row 01
    R   ___                                     ; 595B row 02
    RI  ___, 0, 3                               ; 595C row 03
    RI  C_3, 1, 0                               ; 595E row 04  Inst00
    R   ___                                     ; 5960 row 05
    RI  ___, 0, 3                               ; 5961 row 06
    R   ___                                     ; 5963 row 07
    RI  As2, 1, 0                               ; 5964 row 08  Inst00
    R   ___                                     ; 5966 row 09
    RI  ___, 0, 3                               ; 5967 row 10
    R   ___                                     ; 5969 row 11
    RI  G_2, 1, 0                               ; 596A row 12  Inst00
    RI  ___, 0, 3                               ; 596C row 13
    RI  F_2, 1, 0                               ; 596E row 14  Inst00
    R   ___                                     ; 5970 row 15
    R   ___                                     ; 5971 row 16
    RI  ___, 0, 3                               ; 5972 row 17
    RI  F_2, 1, 0                               ; 5974 row 18  Inst00
    R   ___                                     ; 5976 row 19
    RI  B_2, 1, 0                               ; 5977 row 20  Inst00
    R   ___                                     ; 5979 row 21
    RI  ___, 0, 3                               ; 597A row 22
    R   ___                                     ; 597C row 23
    RI  As2, 1, 0                               ; 597D row 24  Inst00
    R   ___                                     ; 597F row 25
    R   ___                                     ; 5980 row 26
    RI  ___, 0, 3                               ; 5981 row 27
    RI  D_3, 1, 0                               ; 5983 row 28  Inst00
    R   ___                                     ; 5985 row 29
    RI  ___, 0, 3                               ; 5986 row 30
    R   ___                                     ; 5988 row 31
Track002:
    RIF C_6, 2, 0, $F, $6                       ; 5989 row 00  Inst01  speed 6
    R   ___                                     ; 598C row 01
    RIF C_6, 3, 0, $F, $3                       ; 598D row 02  Inst02  speed 3
    R   ___                                     ; 5990 row 03
    RIF C_6, 3, 0, $F, $6                       ; 5991 row 04  Inst02  speed 6
    R   ___                                     ; 5994 row 05
    RIF C_6, 3, 0, $F, $3                       ; 5995 row 06  Inst02  speed 3
    R   ___                                     ; 5998 row 07
    RIF C_6, 4, 0, $F, $6                       ; 5999 row 08  Inst03  speed 6
    R   ___                                     ; 599C row 09
    RIF C_6, 3, 0, $F, $3                       ; 599D row 10  Inst02  speed 3
    R   ___                                     ; 59A0 row 11
    RIF C_6, 3, 0, $F, $6                       ; 59A1 row 12  Inst02  speed 6
    R   ___                                     ; 59A4 row 13
    RIF C_6, 3, 0, $F, $3                       ; 59A5 row 14  Inst02  speed 3
    R   ___                                     ; 59A8 row 15
    RIF C_6, 2, 0, $F, $6                       ; 59A9 row 16  Inst01  speed 6
    R   ___                                     ; 59AC row 17
    RIF C_6, 3, 0, $F, $3                       ; 59AD row 18  Inst02  speed 3
    R   ___                                     ; 59B0 row 19
    RIF C_6, 3, 0, $F, $6                       ; 59B1 row 20  Inst02  speed 6
    R   ___                                     ; 59B4 row 21
    RIF C_6, 3, 0, $F, $3                       ; 59B5 row 22  Inst02  speed 3
    R   ___                                     ; 59B8 row 23
    RIF C_6, 4, 0, $F, $6                       ; 59B9 row 24  Inst03  speed 6
    R   ___                                     ; 59BC row 25
    RIF C_6, 3, 0, $F, $3                       ; 59BD row 26  Inst02  speed 3
    R   ___                                     ; 59C0 row 27
    RIF C_6, 3, 0, $F, $6                       ; 59C1 row 28  Inst02  speed 6
    R   ___                                     ; 59C4 row 29
    RIF C_6, 3, 0, $F, $3                       ; 59C5 row 30  Inst02  speed 3
    R   ___                                     ; 59C8 row 31
Track003:
    RI  As3, 5, 0                               ; 59C9 row 00  Inst04
    R   ___                                     ; 59CB row 01
    RI  C_4, 5, 0                               ; 59CC row 02  Inst04
    RI  ___, 0, 3                               ; 59CE row 03
    RI  Ds4, 5, 0                               ; 59D0 row 04  Inst04
    R   ___                                     ; 59D2 row 05
    R   ___                                     ; 59D3 row 06
    RI  Ds4, 5, 0                               ; 59D4 row 07  Inst04
    R   Fs4                                     ; 59D6 row 08
    R   ___                                     ; 59D7 row 09
    RI  F_4, 5, 0                               ; 59D8 row 10  Inst04
    R   ___                                     ; 59DA row 11
    RI  ___, 0, 3                               ; 59DB row 12
    R   ___                                     ; 59DD row 13
    R   ___                                     ; 59DE row 14
    R   ___                                     ; 59DF row 15
    RI  Ds4, 5, 0                               ; 59E0 row 16  Inst04
    R   ___                                     ; 59E2 row 17
    RI  ___, 0, 3                               ; 59E3 row 18
    R   ___                                     ; 59E5 row 19
    RI  C_4, 5, 0                               ; 59E6 row 20  Inst04
    R   ___                                     ; 59E8 row 21
    RI  Ds4, 5, 0                               ; 59E9 row 22  Inst04
    R   ___                                     ; 59EB row 23
    RI  ___, 0, 3                               ; 59EC row 24
    R   ___                                     ; 59EE row 25
    RI  F_4, 5, 0                               ; 59EF row 26  Inst04
    R   ___                                     ; 59F1 row 27
    R   ___                                     ; 59F2 row 28
    R   ___                                     ; 59F3 row 29
    RI  ___, 0, 3                               ; 59F4 row 30
    R   ___                                     ; 59F6 row 31
Track004:
    RI  As3, 5, 0                               ; 59F7 row 00  Inst04
    R   ___                                     ; 59F9 row 01
    RI  C_4, 5, 0                               ; 59FA row 02  Inst04
    RI  ___, 0, 3                               ; 59FC row 03
    RI  Ds4, 5, 0                               ; 59FE row 04  Inst04
    R   ___                                     ; 5A00 row 05
    R   ___                                     ; 5A01 row 06
    RI  Ds4, 5, 0                               ; 5A02 row 07  Inst04
    R   Fs4                                     ; 5A04 row 08
    R   ___                                     ; 5A05 row 09
    RI  F_4, 5, 0                               ; 5A06 row 10  Inst04
    R   ___                                     ; 5A08 row 11
    RI  ___, 0, 3                               ; 5A09 row 12
    R   ___                                     ; 5A0B row 13
    R   ___                                     ; 5A0C row 14
    R   ___                                     ; 5A0D row 15
    RI  B_3, 5, 0                               ; 5A0E row 16  Inst04
    R   ___                                     ; 5A10 row 17
    RI  Gs3, 5, 0                               ; 5A11 row 18  Inst04
    RI  ___, 0, 3                               ; 5A13 row 19
    RI  B_3, 5, 0                               ; 5A15 row 20  Inst04
    RI  ___, 0, 3                               ; 5A17 row 21
    RI  As3, 5, 0                               ; 5A19 row 22  Inst04
    R   ___                                     ; 5A1B row 23
    R   ___                                     ; 5A1C row 24
    R   ___                                     ; 5A1D row 25
    RI  Ds3, 5, 0                               ; 5A1E row 26  Inst04
    RI  ___, 0, 3                               ; 5A20 row 27
    RI  G_3, 5, 0                               ; 5A22 row 28  Inst04
    RI  ___, 0, 3                               ; 5A24 row 29
    RI  Gs3, 5, 0                               ; 5A26 row 30  Inst04
    RI  ___, 0, 3                               ; 5A28 row 31
Track005:
    RI  As3, 5, 0                               ; 5A2A row 00  Inst04
    R   ___                                     ; 5A2C row 01
    R   ___                                     ; 5A2D row 02
    R   ___                                     ; 5A2E row 03
    RI  G_3, 5, 0                               ; 5A2F row 04  Inst04
    R   ___                                     ; 5A31 row 05
    RI  ___, 0, 3                               ; 5A32 row 06
    R   ___                                     ; 5A34 row 07
    RI  Ds3, 5, 0                               ; 5A35 row 08  Inst04
    R   ___                                     ; 5A37 row 09
    R   ___                                     ; 5A38 row 10
    RI  ___, 0, 3                               ; 5A39 row 11
    RI  Ds3, 5, 0                               ; 5A3B row 12  Inst04
    R   ___                                     ; 5A3D row 13
    RI  F_3, 5, 0                               ; 5A3E row 14  Inst04
    R   ___                                     ; 5A40 row 15
    RI  Fs3, 5, 0                               ; 5A41 row 16  Inst04
    RI  ___, 0, 3                               ; 5A43 row 17
    RI  Fs3, 5, 0                               ; 5A45 row 18  Inst04
    R   ___                                     ; 5A47 row 19
    RI  ___, 0, 3                               ; 5A48 row 20
    R   ___                                     ; 5A4A row 21
    RI  F_3, 5, 0                               ; 5A4B row 22  Inst04
    R   ___                                     ; 5A4D row 23
    RI  ___, 0, 3                               ; 5A4E row 24
    R   ___                                     ; 5A50 row 25
    RI  D_3, 5, 0                               ; 5A51 row 26  Inst04
    R   ___                                     ; 5A53 row 27
    R   ___                                     ; 5A54 row 28
    R   ___                                     ; 5A55 row 29
    R   ___                                     ; 5A56 row 30
    R   ___                                     ; 5A57 row 31
Track006:
    RI  Ds3, 5, 0                               ; 5A58 row 00  Inst04
    R   ___                                     ; 5A5A row 01
    R   ___                                     ; 5A5B row 02
    RI  ___, 0, 2                               ; 5A5C row 03
    R   ___                                     ; 5A5E row 04
    R   ___                                     ; 5A5F row 05
    R   ___                                     ; 5A60 row 06
    R   ___                                     ; 5A61 row 07
    RI  As3, 5, 0                               ; 5A62 row 08  Inst04
    R   ___                                     ; 5A64 row 09
    RI  As3, 5, 0                               ; 5A65 row 10  Inst04
    RI  ___, 0, 3                               ; 5A67 row 11
    RI  As3, 5, 0                               ; 5A69 row 12  Inst04
    RI  ___, 0, 3                               ; 5A6B row 13
    RI  As3, 5, 0                               ; 5A6D row 14  Inst04
    R   ___                                     ; 5A6F row 15
    RI  ___, 0, 2                               ; 5A70 row 16
    R   ___                                     ; 5A72 row 17
    RI  ___, 0, 3                               ; 5A73 row 18
    R   ___                                     ; 5A75 row 19
    RI  ___, 0, 3                               ; 5A76 row 20
    R   ___                                     ; 5A78 row 21
    R   ___                                     ; 5A79 row 22
    R   ___                                     ; 5A7A row 23
    R   ___                                     ; 5A7B row 24
    R   ___                                     ; 5A7C row 25
    R   ___                                     ; 5A7D row 26
    R   ___                                     ; 5A7E row 27
    R   ___                                     ; 5A7F row 28
    R   ___                                     ; 5A80 row 29
    R   ___                                     ; 5A81 row 30
    R   ___                                     ; 5A82 row 31
Track007:
    RI  Ds2, 1, 0                               ; 5A83 row 00  Inst00
    R   ___                                     ; 5A85 row 01
    R   ___                                     ; 5A86 row 02
    RI  ___, 0, 2                               ; 5A87 row 03
    R   ___                                     ; 5A89 row 04
    R   ___                                     ; 5A8A row 05
    R   ___                                     ; 5A8B row 06
    R   ___                                     ; 5A8C row 07
    RI  As2, 1, 0                               ; 5A8D row 08  Inst00
    R   ___                                     ; 5A8F row 09
    RI  G_2, 1, 0                               ; 5A90 row 10  Inst00
    R   ___                                     ; 5A92 row 11
    RI  Gs2, 1, 0                               ; 5A93 row 12  Inst00
    R   ___                                     ; 5A95 row 13
    RI  As2, 1, 0                               ; 5A96 row 14  Inst00
    R   ___                                     ; 5A98 row 15
    RI  ___, 0, 3                               ; 5A99 row 16
    R   ___                                     ; 5A9B row 17
    RI  As2, 1, 0                               ; 5A9C row 18  Inst00
    R   ___                                     ; 5A9E row 19
    RI  Gs2, 1, 0                               ; 5A9F row 20  Inst00
    R   ___                                     ; 5AA1 row 21
    RI  ___, 0, 3                               ; 5AA2 row 22
    R   ___                                     ; 5AA4 row 23
    RI  G_2, 1, 0                               ; 5AA5 row 24  Inst00
    R   ___                                     ; 5AA7 row 25
    RI  ___, 0, 3                               ; 5AA8 row 26
    R   ___                                     ; 5AAA row 27
    RI  F_2, 1, 0                               ; 5AAB row 28  Inst00
    R   ___                                     ; 5AAD row 29
    RI  ___, 0, 3                               ; 5AAE row 30
    R   ___                                     ; 5AB0 row 31
Track008:
    RIF C_3, 2, 0, $F, $6                       ; 5AB1 row 00  Inst01  speed 6
    R   ___                                     ; 5AB4 row 01
    RF  ___, $F, $3                             ; 5AB5 row 02  speed 3
    R   ___                                     ; 5AB7 row 03
    RIF C_3, 3, 0, $F, $6                       ; 5AB8 row 04  Inst02  speed 6
    R   ___                                     ; 5ABB row 05
    RF  ___, $F, $3                             ; 5ABC row 06  speed 3
    R   ___                                     ; 5ABE row 07
    RIF C_3, 2, 0, $F, $6                       ; 5ABF row 08  Inst01  speed 6
    R   ___                                     ; 5AC2 row 09
    RF  ___, $F, $3                             ; 5AC3 row 10  speed 3
    R   ___                                     ; 5AC5 row 11
    RIF C_3, 3, 0, $F, $6                       ; 5AC6 row 12  Inst02  speed 6
    R   ___                                     ; 5AC9 row 13
    RF  ___, $F, $3                             ; 5ACA row 14  speed 3
    R   ___                                     ; 5ACC row 15
    RIF C_3, 2, 0, $F, $6                       ; 5ACD row 16  Inst01  speed 6
    R   ___                                     ; 5AD0 row 17
    RIF C_3, 3, 0, $F, $3                       ; 5AD1 row 18  Inst02  speed 3
    R   ___                                     ; 5AD4 row 19
    RIF C_3, 3, 0, $F, $6                       ; 5AD5 row 20  Inst02  speed 6
    R   ___                                     ; 5AD8 row 21
    RIF C_3, 3, 0, $F, $3                       ; 5AD9 row 22  Inst02  speed 3
    R   ___                                     ; 5ADC row 23
    RIF C_3, 2, 0, $F, $6                       ; 5ADD row 24  Inst01  speed 6
    R   ___                                     ; 5AE0 row 25
    RIF C_3, 3, 0, $F, $3                       ; 5AE1 row 26  Inst02  speed 3
    R   ___                                     ; 5AE4 row 27
    RIF C_3, 3, 0, $F, $6                       ; 5AE5 row 28  Inst02  speed 6
    R   ___                                     ; 5AE8 row 29
    RIF C_3, 3, 0, $F, $3                       ; 5AE9 row 30  Inst02  speed 3
    R   ___                                     ; 5AEC row 31
Track009:
    RI  As3, 5, 0                               ; 5AED row 00  Inst04
    R   ___                                     ; 5AEF row 01
    R   ___                                     ; 5AF0 row 02
    R   ___                                     ; 5AF1 row 03
    RI  C_4, 5, 0                               ; 5AF2 row 04  Inst04
    R   ___                                     ; 5AF4 row 05
    RI  ___, 0, 3                               ; 5AF5 row 06
    R   ___                                     ; 5AF7 row 07
    RI  Ds4, 5, 0                               ; 5AF8 row 08  Inst04
    R   ___                                     ; 5AFA row 09
    R   ___                                     ; 5AFB row 10
    RI  ___, 0, 3                               ; 5AFC row 11
    RI  F_4, 5, 0                               ; 5AFE row 12  Inst04
    R   ___                                     ; 5B00 row 13
    RI  Ds4, 5, 0                               ; 5B01 row 14  Inst04
    R   ___                                     ; 5B03 row 15
    RI  F_4, 5, 0                               ; 5B04 row 16  Inst04
    RI  Fs4, 5, 0                               ; 5B06 row 17  Inst04
    RI  F_4, 5, 0                               ; 5B08 row 18  Inst04
    R   ___                                     ; 5B0A row 19
    R   ___                                     ; 5B0B row 20
    RI  ___, 0, 3                               ; 5B0C row 21
    RI  Fs4, 5, 0                               ; 5B0E row 22  Inst04
    RI  G_4, 5, 0                               ; 5B10 row 23  Inst04
    R   ___                                     ; 5B12 row 24
    RI  ___, 0, 3                               ; 5B13 row 25
    RI  As4, 5, 0                               ; 5B15 row 26  Inst04
    R   ___                                     ; 5B17 row 27
    RI  ___, 0, 3                               ; 5B18 row 28
    R   ___                                     ; 5B1A row 29
    RI  Ds4, 5, 0                               ; 5B1B row 30  Inst04
    R   ___                                     ; 5B1D row 31
Track010:
    R   ___                                     ; 5B1E row 00
    R   ___                                     ; 5B1F row 01
    R   ___                                     ; 5B20 row 02
    RI  ___, 0, 2                               ; 5B21 row 03
    R   ___                                     ; 5B23 row 04
    R   ___                                     ; 5B24 row 05
    R   ___                                     ; 5B25 row 06
    RI  D_5, 5, 0                               ; 5B26 row 07  Inst04
    RI  Ds5, 5, 0                               ; 5B28 row 08  Inst04
    R   ___                                     ; 5B2A row 09
    RI  C_5, 5, 0                               ; 5B2B row 10  Inst04
    RI  ___, 0, 3                               ; 5B2D row 11
    RI  As4, 5, 0                               ; 5B2F row 12  Inst04
    RI  ___, 0, 3                               ; 5B31 row 13
    RI  Ds4, 5, 0                               ; 5B33 row 14  Inst04
    R   ___                                     ; 5B35 row 15
    RI  ___, 0, 2                               ; 5B36 row 16
    R   ___                                     ; 5B38 row 17
    RI  As2, 5, 0                               ; 5B39 row 18  Inst04
    RI  ___, 0, 3                               ; 5B3B row 19
    RI  As3, 5, 0                               ; 5B3D row 20  Inst04
    RI  ___, 0, 3                               ; 5B3F row 21
    R   ___                                     ; 5B41 row 22
    R   ___                                     ; 5B42 row 23
    RI  As3, 5, 0                               ; 5B43 row 24  Inst04
    R   ___                                     ; 5B45 row 25
    RI  ___, 0, 3                               ; 5B46 row 26
    R   ___                                     ; 5B48 row 27
    RI  As2, 5, 0                               ; 5B49 row 28  Inst04
    R   ___                                     ; 5B4B row 29
    RI  ___, 0, 3                               ; 5B4C row 30
    R   ___                                     ; 5B4E row 31
Track011:
    RI  Ds2, 1, 0                               ; 5B4F row 00  Inst00
    R   ___                                     ; 5B51 row 01
    R   ___                                     ; 5B52 row 02
    RI  ___, 0, 2                               ; 5B53 row 03
    R   ___                                     ; 5B55 row 04
    R   ___                                     ; 5B56 row 05
    R   ___                                     ; 5B57 row 06
    R   ___                                     ; 5B58 row 07
    RI  C_2, 1, 0                               ; 5B59 row 08  Inst00
    R   ___                                     ; 5B5B row 09
    RI  Ds2, 1, 0                               ; 5B5C row 10  Inst00
    R   ___                                     ; 5B5E row 11
    RI  As2, 1, 0                               ; 5B5F row 12  Inst00
    R   ___                                     ; 5B61 row 13
    RI  Ds2, 1, 0                               ; 5B62 row 14  Inst00
    R   ___                                     ; 5B64 row 15
    RI  ___, 0, 3                               ; 5B65 row 16
    R   ___                                     ; 5B67 row 17
    RI  As2, 1, 0                               ; 5B68 row 18  Inst00
    R   ___                                     ; 5B6A row 19
    RI  As2, 1, 0                               ; 5B6B row 20  Inst00
    R   ___                                     ; 5B6D row 21
    RI  ___, 0, 3                               ; 5B6E row 22
    R   ___                                     ; 5B70 row 23
    RI  As2, 1, 0                               ; 5B71 row 24  Inst00
    R   ___                                     ; 5B73 row 25
    RI  ___, 0, 3                               ; 5B74 row 26
    R   ___                                     ; 5B76 row 27
    RI  As2, 1, 0                               ; 5B77 row 28  Inst00
    R   ___                                     ; 5B79 row 29
    RI  ___, 0, 3                               ; 5B7A row 30
    R   ___                                     ; 5B7C row 31
Track012:
    R   ___                                     ; 5B7D row 00
    RI  As3, 6, 0                               ; 5B7E row 01  Inst05
    R   ___                                     ; 5B80 row 02
    RI  C_4, 6, 0                               ; 5B81 row 03  Inst05
    RI  ___, 0, 0                               ; 5B83 row 04
    RI  Ds4, 6, 0                               ; 5B85 row 05  Inst05
    R   ___                                     ; 5B87 row 06
    R   ___                                     ; 5B88 row 07
    RI  Ds4, 6, 0                               ; 5B89 row 08  Inst05
    R   Fs4                                     ; 5B8B row 09
    R   ___                                     ; 5B8C row 10
    RI  F_4, 6, 0                               ; 5B8D row 11  Inst05
    R   ___                                     ; 5B8F row 12
    RI  ___, 0, 0                               ; 5B90 row 13
    R   ___                                     ; 5B92 row 14
    R   ___                                     ; 5B93 row 15
    R   ___                                     ; 5B94 row 16
    RI  Ds4, 6, 0                               ; 5B95 row 17  Inst05
    R   ___                                     ; 5B97 row 18
    RI  ___, 0, 0                               ; 5B98 row 19
    R   ___                                     ; 5B9A row 20
    RI  C_4, 6, 0                               ; 5B9B row 21  Inst05
    R   ___                                     ; 5B9D row 22
    RI  Ds4, 6, 0                               ; 5B9E row 23  Inst05
    R   ___                                     ; 5BA0 row 24
    RI  ___, 0, 0                               ; 5BA1 row 25
    R   ___                                     ; 5BA3 row 26
    RI  F_4, 6, 0                               ; 5BA4 row 27  Inst05
    R   ___                                     ; 5BA6 row 28
    R   ___                                     ; 5BA7 row 29
    R   ___                                     ; 5BA8 row 30
    RI  ___, 0, 0                               ; 5BA9 row 31
Track013:
    R   ___                                     ; 5BAB row 00
    RI  As3, 6, 0                               ; 5BAC row 01  Inst05
    R   ___                                     ; 5BAE row 02
    RI  C_4, 6, 0                               ; 5BAF row 03  Inst05
    RI  ___, 0, 0                               ; 5BB1 row 04
    RI  Ds4, 6, 0                               ; 5BB3 row 05  Inst05
    R   ___                                     ; 5BB5 row 06
    R   ___                                     ; 5BB6 row 07
    RI  Ds4, 6, 0                               ; 5BB7 row 08  Inst05
    R   Fs4                                     ; 5BB9 row 09
    R   ___                                     ; 5BBA row 10
    RI  F_4, 6, 0                               ; 5BBB row 11  Inst05
    R   ___                                     ; 5BBD row 12
    RI  ___, 0, 0                               ; 5BBE row 13
    R   ___                                     ; 5BC0 row 14
    R   ___                                     ; 5BC1 row 15
    R   ___                                     ; 5BC2 row 16
    RI  B_3, 6, 0                               ; 5BC3 row 17  Inst05
    R   ___                                     ; 5BC5 row 18
    RI  Gs3, 6, 0                               ; 5BC6 row 19  Inst05
    RI  ___, 0, 0                               ; 5BC8 row 20
    RI  B_3, 6, 0                               ; 5BCA row 21  Inst05
    RI  ___, 0, 0                               ; 5BCC row 22
    RI  As3, 6, 0                               ; 5BCE row 23  Inst05
    R   ___                                     ; 5BD0 row 24
    R   ___                                     ; 5BD1 row 25
    R   ___                                     ; 5BD2 row 26
    RI  Ds3, 6, 0                               ; 5BD3 row 27  Inst05
    RI  ___, 0, 0                               ; 5BD5 row 28
    RI  G_3, 6, 0                               ; 5BD7 row 29  Inst05
    RI  ___, 0, 0                               ; 5BD9 row 30
    RI  Gs3, 6, 0                               ; 5BDB row 31  Inst05
Track014:
    R   ___                                     ; 5BDD row 00
    RI  As3, 6, 0                               ; 5BDE row 01  Inst05
    R   ___                                     ; 5BE0 row 02
    R   ___                                     ; 5BE1 row 03
    R   ___                                     ; 5BE2 row 04
    RI  G_3, 6, 0                               ; 5BE3 row 05  Inst05
    R   ___                                     ; 5BE5 row 06
    RI  ___, 0, 0                               ; 5BE6 row 07
    R   ___                                     ; 5BE8 row 08
    RI  Ds3, 6, 0                               ; 5BE9 row 09  Inst05
    R   ___                                     ; 5BEB row 10
    R   ___                                     ; 5BEC row 11
    RI  ___, 0, 0                               ; 5BED row 12
    RI  Ds3, 6, 0                               ; 5BEF row 13  Inst05
    R   ___                                     ; 5BF1 row 14
    RI  F_3, 6, 0                               ; 5BF2 row 15  Inst05
    R   ___                                     ; 5BF4 row 16
    RI  Fs3, 6, 0                               ; 5BF5 row 17  Inst05
    RI  ___, 0, 0                               ; 5BF7 row 18
    RI  Fs3, 6, 0                               ; 5BF9 row 19  Inst05
    R   ___                                     ; 5BFB row 20
    RI  ___, 0, 0                               ; 5BFC row 21
    R   ___                                     ; 5BFE row 22
    RI  F_3, 6, 0                               ; 5BFF row 23  Inst05
    R   ___                                     ; 5C01 row 24
    RI  ___, 0, 0                               ; 5C02 row 25
    R   ___                                     ; 5C04 row 26
    RI  D_3, 6, 0                               ; 5C05 row 27  Inst05
    R   ___                                     ; 5C07 row 28
    R   ___                                     ; 5C08 row 29
    R   ___                                     ; 5C09 row 30
    R   ___                                     ; 5C0A row 31
Track015:
    R   ___                                     ; 5C0B row 00
    RI  Ds3, 6, 0                               ; 5C0C row 01  Inst05
    R   ___                                     ; 5C0E row 02
    R   ___                                     ; 5C0F row 03
    RI  ___, 0, 0                               ; 5C10 row 04
    R   ___                                     ; 5C12 row 05
    R   ___                                     ; 5C13 row 06
    R   ___                                     ; 5C14 row 07
    R   ___                                     ; 5C15 row 08
    R   ___                                     ; 5C16 row 09
    RI  As3, 6, 0                               ; 5C17 row 10  Inst05
    R   ___                                     ; 5C19 row 11
    RI  As3, 6, 0                               ; 5C1A row 12  Inst05
    RI  ___, 0, 0                               ; 5C1C row 13
    RI  As3, 6, 0                               ; 5C1E row 14  Inst05
    RI  ___, 0, 0                               ; 5C20 row 15
    RI  As3, 6, 0                               ; 5C22 row 16  Inst05
    R   ___                                     ; 5C24 row 17
    RI  ___, 0, 1                               ; 5C25 row 18
    R   ___                                     ; 5C27 row 19
    R   ___                                     ; 5C28 row 20
    R   ___                                     ; 5C29 row 21
    RI  ___, 0, 0                               ; 5C2A row 22
    R   ___                                     ; 5C2C row 23
    R   ___                                     ; 5C2D row 24
    R   ___                                     ; 5C2E row 25
    R   ___                                     ; 5C2F row 26
    R   ___                                     ; 5C30 row 27
    R   ___                                     ; 5C31 row 28
    R   ___                                     ; 5C32 row 29
    R   ___                                     ; 5C33 row 30
    R   ___                                     ; 5C34 row 31
Track016:
    R   ___                                     ; 5C35 row 00
    RI  As3, 6, 0                               ; 5C36 row 01  Inst05
    R   ___                                     ; 5C38 row 02
    R   ___                                     ; 5C39 row 03
    R   ___                                     ; 5C3A row 04
    RI  C_4, 6, 0                               ; 5C3B row 05  Inst05
    R   ___                                     ; 5C3D row 06
    RI  ___, 0, 0                               ; 5C3E row 07
    R   ___                                     ; 5C40 row 08
    RI  Ds4, 6, 0                               ; 5C41 row 09  Inst05
    R   ___                                     ; 5C43 row 10
    R   ___                                     ; 5C44 row 11
    RI  ___, 0, 0                               ; 5C45 row 12
    RI  F_4, 6, 0                               ; 5C47 row 13  Inst05
    R   ___                                     ; 5C49 row 14
    RI  Ds4, 6, 0                               ; 5C4A row 15  Inst05
    R   ___                                     ; 5C4C row 16
    RI  F_4, 6, 0                               ; 5C4D row 17  Inst05
    RI  Fs4, 6, 0                               ; 5C4F row 18  Inst05
    RI  F_4, 6, 0                               ; 5C51 row 19  Inst05
    R   ___                                     ; 5C53 row 20
    R   ___                                     ; 5C54 row 21
    RI  ___, 0, 0                               ; 5C55 row 22
    RI  Fs4, 6, 0                               ; 5C57 row 23  Inst05
    RI  G_4, 6, 0                               ; 5C59 row 24  Inst05
    R   ___                                     ; 5C5B row 25
    RI  ___, 0, 0                               ; 5C5C row 26
    RI  As4, 6, 0                               ; 5C5E row 27  Inst05
    R   ___                                     ; 5C60 row 28
    RI  ___, 0, 0                               ; 5C61 row 29
    R   ___                                     ; 5C63 row 30
    RI  Ds4, 6, 0                               ; 5C64 row 31  Inst05
Track017:
    R   ___                                     ; 5C66 row 00
    R   ___                                     ; 5C67 row 01
    R   ___                                     ; 5C68 row 02
    R   ___                                     ; 5C69 row 03
    RI  ___, 0, 1                               ; 5C6A row 04
    R   ___                                     ; 5C6C row 05
    R   ___                                     ; 5C6D row 06
    R   ___                                     ; 5C6E row 07
    RI  D_5, 6, 0                               ; 5C6F row 08  Inst05
    RI  Ds5, 6, 0                               ; 5C71 row 09  Inst05
    R   ___                                     ; 5C73 row 10
    RI  C_5, 6, 0                               ; 5C74 row 11  Inst05
    RI  ___, 0, 0                               ; 5C76 row 12
    RI  As4, 6, 0                               ; 5C78 row 13  Inst05
    RI  ___, 0, 0                               ; 5C7A row 14
    RI  Ds4, 6, 0                               ; 5C7C row 15  Inst05
    R   ___                                     ; 5C7E row 16
    RI  ___, 0, 0                               ; 5C7F row 17
    R   ___                                     ; 5C81 row 18
    RI  As2, 6, 0                               ; 5C82 row 19  Inst05
    RI  ___, 0, 0                               ; 5C84 row 20
    RI  As3, 6, 0                               ; 5C86 row 21  Inst05
    RI  ___, 0, 0                               ; 5C88 row 22
    R   ___                                     ; 5C8A row 23
    R   ___                                     ; 5C8B row 24
    RI  As3, 6, 0                               ; 5C8C row 25  Inst05
    R   ___                                     ; 5C8E row 26
    RI  ___, 0, 0                               ; 5C8F row 27
    R   ___                                     ; 5C91 row 28
    RI  As2, 6, 0                               ; 5C92 row 29  Inst05
    R   ___                                     ; 5C94 row 30
    RI  ___, 0, 0                               ; 5C95 row 31
Track018:
    RIF C_3, 8, 0, $F, $7                       ; 5C97 row 00  Inst07  speed 7
    R   ___                                     ; 5C9A row 01
    RI  ___, 0, 0                               ; 5C9B row 02
    R   ___                                     ; 5C9D row 03
    RI  C_3, 8, 0                               ; 5C9E row 04  Inst07
    R   ___                                     ; 5CA0 row 05
    RI  ___, 0, 0                               ; 5CA1 row 06
    R   ___                                     ; 5CA3 row 07
    R   ___                                     ; 5CA4 row 08
    R   ___                                     ; 5CA5 row 09
    RI  G_2, 8, 0                               ; 5CA6 row 10  Inst07
    R   ___                                     ; 5CA8 row 11
    RI  ___, 0, 0                               ; 5CA9 row 12
    R   ___                                     ; 5CAB row 13
    RI  F_2, 8, 0                               ; 5CAC row 14  Inst07
    R   ___                                     ; 5CAE row 15
    R   ___                                     ; 5CAF row 16
    R   ___                                     ; 5CB0 row 17
    R   ___                                     ; 5CB1 row 18
    R   ___                                     ; 5CB2 row 19
    RI  F_2, 8, 0                               ; 5CB3 row 20  Inst07
    R   ___                                     ; 5CB5 row 21
    RI  ___, 0, 0                               ; 5CB6 row 22
    R   ___                                     ; 5CB8 row 23
    R   ___                                     ; 5CB9 row 24
    R   ___                                     ; 5CBA row 25
    RI  As2, 8, 0                               ; 5CBB row 26  Inst07
    R   ___                                     ; 5CBD row 27
    RI  ___, 0, 0                               ; 5CBE row 28
    R   ___                                     ; 5CC0 row 29
    RI  B_2, 8, 0                               ; 5CC1 row 30  Inst07
    R   ___                                     ; 5CC3 row 31
Track019:
    RI  C_3, 2, 0                               ; 5CC4 row 00  Inst01
    R   ___                                     ; 5CC6 row 01
    R   ___                                     ; 5CC7 row 02
    R   ___                                     ; 5CC8 row 03
    RI  C_3, 4, 0                               ; 5CC9 row 04  Inst03
    R   ___                                     ; 5CCB row 05
    R   ___                                     ; 5CCC row 06
    R   ___                                     ; 5CCD row 07
    RI  C_3, 2, 0                               ; 5CCE row 08  Inst01
    R   ___                                     ; 5CD0 row 09
    R   ___                                     ; 5CD1 row 10
    R   ___                                     ; 5CD2 row 11
    RI  C_3, 4, 0                               ; 5CD3 row 12  Inst03
    R   ___                                     ; 5CD5 row 13
    R   ___                                     ; 5CD6 row 14
    R   ___                                     ; 5CD7 row 15
    RI  C_3, 2, 0                               ; 5CD8 row 16  Inst01
    R   ___                                     ; 5CDA row 17
    R   ___                                     ; 5CDB row 18
    R   ___                                     ; 5CDC row 19
    RI  C_3, 4, 0                               ; 5CDD row 20  Inst03
    R   ___                                     ; 5CDF row 21
    R   ___                                     ; 5CE0 row 22
    R   ___                                     ; 5CE1 row 23
    RI  C_3, 2, 0                               ; 5CE2 row 24  Inst01
    R   ___                                     ; 5CE4 row 25
    R   ___                                     ; 5CE5 row 26
    R   ___                                     ; 5CE6 row 27
    RI  C_3, 4, 0                               ; 5CE7 row 28  Inst03
    R   ___                                     ; 5CE9 row 29
    R   ___                                     ; 5CEA row 30
    R   ___                                     ; 5CEB row 31
Track020:
    RI  C_3, 7, 0                               ; 5CEC row 00  Inst06
    R   ___                                     ; 5CEE row 01
    R   ___                                     ; 5CEF row 02
    R   ___                                     ; 5CF0 row 03
    R   ___                                     ; 5CF1 row 04
    R   ___                                     ; 5CF2 row 05
    R   ___                                     ; 5CF3 row 06
    R   ___                                     ; 5CF4 row 07
    R   ___                                     ; 5CF5 row 08
    R   ___                                     ; 5CF6 row 09
    RI  G_2, 7, 0                               ; 5CF7 row 10  Inst06
    R   ___                                     ; 5CF9 row 11
    R   ___                                     ; 5CFA row 12
    R   ___                                     ; 5CFB row 13
    RI  F_2, 7, 0                               ; 5CFC row 14  Inst06
    R   ___                                     ; 5CFE row 15
    R   ___                                     ; 5CFF row 16
    R   ___                                     ; 5D00 row 17
    R   ___                                     ; 5D01 row 18
    R   ___                                     ; 5D02 row 19
    R   ___                                     ; 5D03 row 20
    R   ___                                     ; 5D04 row 21
    R   ___                                     ; 5D05 row 22
    R   ___                                     ; 5D06 row 23
    R   ___                                     ; 5D07 row 24
    R   ___                                     ; 5D08 row 25
    RI  G_2, 7, 0                               ; 5D09 row 26  Inst06
    R   ___                                     ; 5D0B row 27
    R   ___                                     ; 5D0C row 28
    R   ___                                     ; 5D0D row 29
    R   ___                                     ; 5D0E row 30
    R   ___                                     ; 5D0F row 31
Track021:
    RIF C_3, 8, 0, $F, $7                       ; 5D10 row 00  Inst07  speed 7
    R   ___                                     ; 5D13 row 01
    RI  ___, 0, 0                               ; 5D14 row 02
    R   ___                                     ; 5D16 row 03
    RI  C_3, 8, 0                               ; 5D17 row 04  Inst07
    R   ___                                     ; 5D19 row 05
    RI  ___, 0, 0                               ; 5D1A row 06
    R   ___                                     ; 5D1C row 07
    R   ___                                     ; 5D1D row 08
    R   ___                                     ; 5D1E row 09
    RI  G_2, 8, 0                               ; 5D1F row 10  Inst07
    R   ___                                     ; 5D21 row 11
    RI  ___, 0, 0                               ; 5D22 row 12
    R   ___                                     ; 5D24 row 13
    RI  F_2, 8, 0                               ; 5D25 row 14  Inst07
    R   ___                                     ; 5D27 row 15
    R   ___                                     ; 5D28 row 16
    R   ___                                     ; 5D29 row 17
    R   ___                                     ; 5D2A row 18
    R   ___                                     ; 5D2B row 19
    RI  F_2, 8, 0                               ; 5D2C row 20  Inst07
    R   ___                                     ; 5D2E row 21
    RI  ___, 0, 0                               ; 5D2F row 22
    R   ___                                     ; 5D31 row 23
    RI  As2, 8, 0                               ; 5D32 row 24  Inst07
    R   ___                                     ; 5D34 row 25
    RI  G_2, 8, 0                               ; 5D35 row 26  Inst07
    RI  ___, 0, 0                               ; 5D37 row 27
    RI  As2, 8, 0                               ; 5D39 row 28  Inst07
    RI  ___, 0, 0                               ; 5D3B row 29
    RI  B_2, 8, 0                               ; 5D3D row 30  Inst07
    RI  ___, 0, 0                               ; 5D3F row 31
Track022:
    RI  Ds4, 10, 0                              ; 5D41 row 00  Inst09
    R   ___                                     ; 5D43 row 01
    R   ___                                     ; 5D44 row 02
    R   ___                                     ; 5D45 row 03
    RI  C_4, 10, 0                              ; 5D46 row 04  Inst09
    R   ___                                     ; 5D48 row 05
    RI  Ds4, 10, 2                              ; 5D49 row 06  Inst09
    R   ___                                     ; 5D4B row 07
    RI  Ds4, 10, 0                              ; 5D4C row 08  Inst09
    R   F_4                                     ; 5D4E row 09
    RI  Ds4, 10, 0                              ; 5D4F row 10  Inst09
    R   ___                                     ; 5D51 row 11
    RI  As3, 10, 0                              ; 5D52 row 12  Inst09
    R   ___                                     ; 5D54 row 13
    RI  C_4, 10, 0                              ; 5D55 row 14  Inst09
    R   ___                                     ; 5D57 row 15
    R   ___                                     ; 5D58 row 16
    R   ___                                     ; 5D59 row 17
    RI  Ds4, 10, 0                              ; 5D5A row 18  Inst09
    RI  C_4, 10, 1                              ; 5D5C row 19  Inst09
    RI  Ds4, 10, 1                              ; 5D5E row 20  Inst09
    RI  ___, 0, 3                               ; 5D60 row 21
    RI  G_3, 11, 0                              ; 5D62 row 22  Inst10
    RI  G_3, 11, 0                              ; 5D64 row 23  Inst10
    RI  As3, 11, 0                              ; 5D66 row 24  Inst10
    R   ___                                     ; 5D68 row 25
    RI  G_3, 11, 0                              ; 5D69 row 26  Inst10
    R   ___                                     ; 5D6B row 27
    RI  As3, 11, 0                              ; 5D6C row 28  Inst10
    R   ___                                     ; 5D6E row 29
    RI  B_3, 11, 0                              ; 5D6F row 30  Inst10
    R   ___                                     ; 5D71 row 31
Track023:
    RI  Ds4, 10, 0                              ; 5D72 row 00  Inst09
    R   ___                                     ; 5D74 row 01
    R   ___                                     ; 5D75 row 02
    R   ___                                     ; 5D76 row 03
    RI  C_4, 10, 0                              ; 5D77 row 04  Inst09
    R   ___                                     ; 5D79 row 05
    RI  Ds4, 10, 2                              ; 5D7A row 06  Inst09
    R   ___                                     ; 5D7C row 07
    RI  F_4, 10, 0                              ; 5D7D row 08  Inst09
    R   G_4                                     ; 5D7F row 09
    RI  Ds4, 10, 0                              ; 5D80 row 10  Inst09
    R   ___                                     ; 5D82 row 11
    RI  C_4, 10, 0                              ; 5D83 row 12  Inst09
    R   ___                                     ; 5D85 row 13
    RI  Ds4, 10, 0                              ; 5D86 row 14  Inst09
    R   F_4                                     ; 5D88 row 15
    R   ___                                     ; 5D89 row 16
    R   ___                                     ; 5D8A row 17
    R   ___                                     ; 5D8B row 18
    R   ___                                     ; 5D8C row 19
    R   ___                                     ; 5D8D row 20
    RI  ___, 0, 3                               ; 5D8E row 21
    R   ___                                     ; 5D90 row 22
    R   ___                                     ; 5D91 row 23
    RI  As3, 11, 0                              ; 5D92 row 24  Inst10
    RI  G_3, 11, 0                              ; 5D94 row 25  Inst10
    RI  F_3, 11, 0                              ; 5D96 row 26  Inst10
    RI  G_3, 11, 0                              ; 5D98 row 27  Inst10
    RI  As3, 11, 0                              ; 5D9A row 28  Inst10
    R   ___                                     ; 5D9C row 29
    RI  B_3, 11, 0                              ; 5D9D row 30  Inst10
    R   ___                                     ; 5D9F row 31
Track024:
    RI  Ds4, 10, 0                              ; 5DA0 row 00  Inst09
    R   ___                                     ; 5DA2 row 01
    R   ___                                     ; 5DA3 row 02
    R   ___                                     ; 5DA4 row 03
    RI  C_4, 10, 0                              ; 5DA5 row 04  Inst09
    R   ___                                     ; 5DA7 row 05
    RI  Ds4, 10, 2                              ; 5DA8 row 06  Inst09
    R   ___                                     ; 5DAA row 07
    RI  F_4, 10, 0                              ; 5DAB row 08  Inst09
    R   G_4                                     ; 5DAD row 09
    RI  As4, 10, 0                              ; 5DAE row 10  Inst09
    R   ___                                     ; 5DB0 row 11
    RI  Ds4, 10, 0                              ; 5DB1 row 12  Inst09
    R   ___                                     ; 5DB3 row 13
    RI  E_4, 10, 0                              ; 5DB4 row 14  Inst09
    R   F_4                                     ; 5DB6 row 15
    R   ___                                     ; 5DB7 row 16
    R   ___                                     ; 5DB8 row 17
    R   ___                                     ; 5DB9 row 18
    R   ___                                     ; 5DBA row 19
    R   ___                                     ; 5DBB row 20
    RI  ___, 0, 3                               ; 5DBC row 21
    R   ___                                     ; 5DBE row 22
    R   ___                                     ; 5DBF row 23
    RI  As4, 11, 0                              ; 5DC0 row 24  Inst10
    RI  G_4, 11, 0                              ; 5DC2 row 25  Inst10
    RI  F_4, 11, 0                              ; 5DC4 row 26  Inst10
    RI  G_4, 11, 0                              ; 5DC6 row 27  Inst10
    RI  As4, 11, 0                              ; 5DC8 row 28  Inst10
    R   ___                                     ; 5DCA row 29
    RI  B_4, 11, 0                              ; 5DCB row 30  Inst10
    R   ___                                     ; 5DCD row 31
Track025:
    RI  Gs2, 8, 0                               ; 5DCE row 00  Inst07
    R   ___                                     ; 5DD0 row 01
    RI  ___, 0, 0                               ; 5DD1 row 02
    R   ___                                     ; 5DD3 row 03
    RI  Gs2, 8, 0                               ; 5DD4 row 04  Inst07
    R   ___                                     ; 5DD6 row 05
    RI  ___, 0, 0                               ; 5DD7 row 06
    R   ___                                     ; 5DD9 row 07
    R   ___                                     ; 5DDA row 08
    R   ___                                     ; 5DDB row 09
    RI  Gs2, 8, 0                               ; 5DDC row 10  Inst07
    R   ___                                     ; 5DDE row 11
    RI  ___, 0, 0                               ; 5DDF row 12
    R   ___                                     ; 5DE1 row 13
    RI  As2, 8, 0                               ; 5DE2 row 14  Inst07
    R   ___                                     ; 5DE4 row 15
    R   ___                                     ; 5DE5 row 16
    R   ___                                     ; 5DE6 row 17
    R   ___                                     ; 5DE7 row 18
    R   ___                                     ; 5DE8 row 19
    RI  As2, 8, 0                               ; 5DE9 row 20  Inst07
    R   ___                                     ; 5DEB row 21
    RI  ___, 0, 0                               ; 5DEC row 22
    R   ___                                     ; 5DEE row 23
    RI  As2, 8, 0                               ; 5DEF row 24  Inst07
    R   ___                                     ; 5DF1 row 25
    RI  Gs2, 8, 0                               ; 5DF2 row 26  Inst07
    RI  ___, 0, 0                               ; 5DF4 row 27
    RI  G_2, 8, 0                               ; 5DF6 row 28  Inst07
    RI  ___, 0, 0                               ; 5DF8 row 29
    RI  B_2, 8, 0                               ; 5DFA row 30  Inst07
    RI  ___, 0, 0                               ; 5DFC row 31
Track026:
    RI  C_3, 12, 0                              ; 5DFE row 00  Inst11
    R   ___                                     ; 5E00 row 01
    R   ___                                     ; 5E01 row 02
    R   ___                                     ; 5E02 row 03
    R   ___                                     ; 5E03 row 04
    R   ___                                     ; 5E04 row 05
    R   ___                                     ; 5E05 row 06
    R   ___                                     ; 5E06 row 07
    R   ___                                     ; 5E07 row 08
    R   ___                                     ; 5E08 row 09
    RI  C_3, 12, 0                              ; 5E09 row 10  Inst11
    R   ___                                     ; 5E0B row 11
    R   ___                                     ; 5E0C row 12
    R   ___                                     ; 5E0D row 13
    RI  As2, 12, 0                              ; 5E0E row 14  Inst11
    R   ___                                     ; 5E10 row 15
    R   ___                                     ; 5E11 row 16
    R   ___                                     ; 5E12 row 17
    R   ___                                     ; 5E13 row 18
    R   ___                                     ; 5E14 row 19
    R   ___                                     ; 5E15 row 20
    R   ___                                     ; 5E16 row 21
    RI  As2, 12, 0                              ; 5E17 row 22  Inst11
    R   ___                                     ; 5E19 row 23
    R   ___                                     ; 5E1A row 24
    R   ___                                     ; 5E1B row 25
    RI  C_3, 12, 0                              ; 5E1C row 26  Inst11
    R   ___                                     ; 5E1E row 27
    R   ___                                     ; 5E1F row 28
    R   ___                                     ; 5E20 row 29
    R   ___                                     ; 5E21 row 30
    R   ___                                     ; 5E22 row 31
Track027:
    RI  C_4, 13, 0                              ; 5E23 row 00  Inst12
    R   ___                                     ; 5E25 row 01
    R   ___                                     ; 5E26 row 02
    R   ___                                     ; 5E27 row 03
    RI  C_4, 13, 0                              ; 5E28 row 04  Inst12
    R   ___                                     ; 5E2A row 05
    R   ___                                     ; 5E2B row 06
    R   ___                                     ; 5E2C row 07
    RI  C_4, 13, 0                              ; 5E2D row 08  Inst12
    R   ___                                     ; 5E2F row 09
    R   ___                                     ; 5E30 row 10
    R   ___                                     ; 5E31 row 11
    RI  C_4, 13, 0                              ; 5E32 row 12  Inst12
    R   ___                                     ; 5E34 row 13
    R   ___                                     ; 5E35 row 14
    R   ___                                     ; 5E36 row 15
    RI  C_4, 13, 0                              ; 5E37 row 16  Inst12
    R   ___                                     ; 5E39 row 17
    R   ___                                     ; 5E3A row 18
    R   ___                                     ; 5E3B row 19
    RI  C_4, 13, 0                              ; 5E3C row 20  Inst12
    R   ___                                     ; 5E3E row 21
    R   ___                                     ; 5E3F row 22
    R   ___                                     ; 5E40 row 23
    RI  C_4, 13, 0                              ; 5E41 row 24  Inst12
    R   ___                                     ; 5E43 row 25
    RI  G_3, 13, 0                              ; 5E44 row 26  Inst12
    R   ___                                     ; 5E46 row 27
    RI  F_3, 13, 0                              ; 5E47 row 28  Inst12
    R   ___                                     ; 5E49 row 29
    RI  As3, 13, 0                              ; 5E4A row 30  Inst12
    R   ___                                     ; 5E4C row 31
Track028:
    RIF Ds2, 8, 0, $F, $7                       ; 5E4D row 00  Inst07  speed 7
    R   ___                                     ; 5E50 row 01
    RI  ___, 0, 0                               ; 5E51 row 02
    R   ___                                     ; 5E53 row 03
    RI  Ds2, 8, 0                               ; 5E54 row 04  Inst07
    R   ___                                     ; 5E56 row 05
    RI  ___, 0, 0                               ; 5E57 row 06
    R   ___                                     ; 5E59 row 07
    R   ___                                     ; 5E5A row 08
    R   ___                                     ; 5E5B row 09
    RI  G_2, 8, 0                               ; 5E5C row 10  Inst07
    R   ___                                     ; 5E5E row 11
    RI  ___, 0, 0                               ; 5E5F row 12
    R   ___                                     ; 5E61 row 13
    RI  F_2, 8, 0                               ; 5E62 row 14  Inst07
    R   ___                                     ; 5E64 row 15
    R   ___                                     ; 5E65 row 16
    R   ___                                     ; 5E66 row 17
    R   ___                                     ; 5E67 row 18
    R   ___                                     ; 5E68 row 19
    RI  F_2, 8, 0                               ; 5E69 row 20  Inst07
    R   ___                                     ; 5E6B row 21
    RI  ___, 0, 0                               ; 5E6C row 22
    R   ___                                     ; 5E6E row 23
    RI  As2, 8, 0                               ; 5E6F row 24  Inst07
    R   ___                                     ; 5E71 row 25
    RI  G_2, 8, 0                               ; 5E72 row 26  Inst07
    RI  ___, 0, 0                               ; 5E74 row 27
    RI  F_2, 8, 0                               ; 5E76 row 28  Inst07
    RI  ___, 0, 0                               ; 5E78 row 29
    RI  As2, 8, 0                               ; 5E7A row 30  Inst07
    RI  ___, 0, 0                               ; 5E7C row 31
Track029:
    RI  D_4, 15, 0                              ; 5E7E row 00  Inst14
    R   Ds4                                     ; 5E80 row 01
    RI  D_4, 15, 0                              ; 5E81 row 02  Inst14
    R   ___                                     ; 5E83 row 03
    R   ___                                     ; 5E84 row 04
    R   ___                                     ; 5E85 row 05
    RI  As3, 15, 0                              ; 5E86 row 06  Inst14
    R   ___                                     ; 5E88 row 07
    R   ___                                     ; 5E89 row 08
    R   ___                                     ; 5E8A row 09
    RI  G_3, 15, 0                              ; 5E8B row 10  Inst14
    R   ___                                     ; 5E8D row 11
    R   ___                                     ; 5E8E row 12
    R   ___                                     ; 5E8F row 13
    RI  F_3, 15, 0                              ; 5E90 row 14  Inst14
    R   ___                                     ; 5E92 row 15
    R   ___                                     ; 5E93 row 16
    R   ___                                     ; 5E94 row 17
    R   ___                                     ; 5E95 row 18
    R   ___                                     ; 5E96 row 19
    RI  Ds3, 15, 0                              ; 5E97 row 20  Inst14
    R   ___                                     ; 5E99 row 21
    RI  F_3, 15, 0                              ; 5E9A row 22  Inst14
    R   ___                                     ; 5E9C row 23
    R   ___                                     ; 5E9D row 24
    R   ___                                     ; 5E9E row 25
    RI  G_3, 15, 0                              ; 5E9F row 26  Inst14
    R   ___                                     ; 5EA1 row 27
    R   ___                                     ; 5EA2 row 28
    R   ___                                     ; 5EA3 row 29
    R   ___                                     ; 5EA4 row 30
    R   ___                                     ; 5EA5 row 31
Track030:
    RI  Ds4, 10, 0                              ; 5EA6 row 00  Inst09
    R   ___                                     ; 5EA8 row 01
    R   ___                                     ; 5EA9 row 02
    R   ___                                     ; 5EAA row 03
    RI  C_4, 10, 0                              ; 5EAB row 04  Inst09
    R   ___                                     ; 5EAD row 05
    RI  Ds4, 10, 2                              ; 5EAE row 06  Inst09
    R   ___                                     ; 5EB0 row 07
    RI  F_4, 10, 0                              ; 5EB1 row 08  Inst09
    R   G_4                                     ; 5EB3 row 09
    RI  As4, 10, 0                              ; 5EB4 row 10  Inst09
    R   ___                                     ; 5EB6 row 11
    RI  Ds4, 10, 0                              ; 5EB7 row 12  Inst09
    R   ___                                     ; 5EB9 row 13
    RI  E_4, 10, 0                              ; 5EBA row 14  Inst09
    R   F_4                                     ; 5EBC row 15
    R   ___                                     ; 5EBD row 16
    R   ___                                     ; 5EBE row 17
    R   ___                                     ; 5EBF row 18
    R   ___                                     ; 5EC0 row 19
    R   ___                                     ; 5EC1 row 20
    RI  ___, 0, 3                               ; 5EC2 row 21
    R   ___                                     ; 5EC4 row 22
    R   ___                                     ; 5EC5 row 23
    RI  As3, 15, 0                              ; 5EC6 row 24  Inst14
    R   ___                                     ; 5EC8 row 25
    R   ___                                     ; 5EC9 row 26
    RI  C_4, 15, 0                              ; 5ECA row 27  Inst14
    R   ___                                     ; 5ECC row 28
    R   ___                                     ; 5ECD row 29
    RI  D_4, 15, 0                              ; 5ECE row 30  Inst14
    R   ___                                     ; 5ED0 row 31
Track031:
    RI  D_4, 15, 0                              ; 5ED1 row 00  Inst14
    R   Ds4                                     ; 5ED3 row 01
    RI  D_4, 15, 0                              ; 5ED4 row 02  Inst14
    R   ___                                     ; 5ED6 row 03
    R   ___                                     ; 5ED7 row 04
    R   ___                                     ; 5ED8 row 05
    RI  As3, 15, 0                              ; 5ED9 row 06  Inst14
    R   ___                                     ; 5EDB row 07
    R   ___                                     ; 5EDC row 08
    R   ___                                     ; 5EDD row 09
    RI  G_4, 15, 0                              ; 5EDE row 10  Inst14
    R   ___                                     ; 5EE0 row 11
    R   ___                                     ; 5EE1 row 12
    R   ___                                     ; 5EE2 row 13
    RI  F_4, 15, 0                              ; 5EE3 row 14  Inst14
    R   ___                                     ; 5EE5 row 15
    R   ___                                     ; 5EE6 row 16
    R   ___                                     ; 5EE7 row 17
    R   ___                                     ; 5EE8 row 18
    R   ___                                     ; 5EE9 row 19
    R   ___                                     ; 5EEA row 20
    R   ___                                     ; 5EEB row 21
    R   ___                                     ; 5EEC row 22
    R   ___                                     ; 5EED row 23
    R   ___                                     ; 5EEE row 24
    R   ___                                     ; 5EEF row 25
    R   ___                                     ; 5EF0 row 26
    R   ___                                     ; 5EF1 row 27
    RI  G_3, 15, 0                              ; 5EF2 row 28  Inst14
    R   ___                                     ; 5EF4 row 29
    RI  As3, 15, 0                              ; 5EF5 row 30  Inst14
    R   ___                                     ; 5EF7 row 31
Track032:
    RI  D_4, 15, 0                              ; 5EF8 row 00  Inst14
    R   Ds4                                     ; 5EFA row 01
    RI  D_4, 15, 0                              ; 5EFB row 02  Inst14
    R   ___                                     ; 5EFD row 03
    R   ___                                     ; 5EFE row 04
    R   ___                                     ; 5EFF row 05
    RI  As3, 15, 0                              ; 5F00 row 06  Inst14
    R   ___                                     ; 5F02 row 07
    R   ___                                     ; 5F03 row 08
    R   ___                                     ; 5F04 row 09
    RI  G_4, 15, 0                              ; 5F05 row 10  Inst14
    R   ___                                     ; 5F07 row 11
    R   ___                                     ; 5F08 row 12
    R   ___                                     ; 5F09 row 13
    RI  F_4, 15, 0                              ; 5F0A row 14  Inst14
    R   ___                                     ; 5F0C row 15
    R   ___                                     ; 5F0D row 16
    R   ___                                     ; 5F0E row 17
    R   ___                                     ; 5F0F row 18
    R   ___                                     ; 5F10 row 19
    R   ___                                     ; 5F11 row 20
    R   ___                                     ; 5F12 row 21
    RI  As4, 15, 0                              ; 5F13 row 22  Inst14
    R   ___                                     ; 5F15 row 23
    R   ___                                     ; 5F16 row 24
    R   ___                                     ; 5F17 row 25
    R   ___                                     ; 5F18 row 26
    R   ___                                     ; 5F19 row 27
    R   ___                                     ; 5F1A row 28
    R   ___                                     ; 5F1B row 29
    R   ___                                     ; 5F1C row 30
    R   ___                                     ; 5F1D row 31
Track033:
    RI  C_4, 13, 0                              ; 5F1E row 00  Inst12
    R   ___                                     ; 5F20 row 01
    R   ___                                     ; 5F21 row 02
    R   ___                                     ; 5F22 row 03
    RI  C_4, 13, 0                              ; 5F23 row 04  Inst12
    R   ___                                     ; 5F25 row 05
    R   ___                                     ; 5F26 row 06
    R   ___                                     ; 5F27 row 07
    RI  C_4, 13, 0                              ; 5F28 row 08  Inst12
    R   ___                                     ; 5F2A row 09
    R   ___                                     ; 5F2B row 10
    R   ___                                     ; 5F2C row 11
    RI  C_4, 13, 0                              ; 5F2D row 12  Inst12
    R   ___                                     ; 5F2F row 13
    R   ___                                     ; 5F30 row 14
    R   ___                                     ; 5F31 row 15
    RI  C_4, 13, 0                              ; 5F32 row 16  Inst12
    R   ___                                     ; 5F34 row 17
    R   ___                                     ; 5F35 row 18
    R   ___                                     ; 5F36 row 19
    RI  C_4, 13, 0                              ; 5F37 row 20  Inst12
    R   ___                                     ; 5F39 row 21
    R   ___                                     ; 5F3A row 22
    R   ___                                     ; 5F3B row 23
    RI  Ds4, 13, 0                              ; 5F3C row 24  Inst12
    R   ___                                     ; 5F3E row 25
    RI  D_4, 13, 0                              ; 5F3F row 26  Inst12
    R   ___                                     ; 5F41 row 27
    RI  As3, 13, 0                              ; 5F42 row 28  Inst12
    R   ___                                     ; 5F44 row 29
    RI  G_3, 13, 0                              ; 5F45 row 30  Inst12
    R   ___                                     ; 5F47 row 31
Track034:
    RIF C_4, 13, 0, $F, $7                      ; 5F48 row 00  Inst12  speed 7
    R   ___                                     ; 5F4B row 01
    R   ___                                     ; 5F4C row 02
    R   ___                                     ; 5F4D row 03
    RI  C_3, 16, 0                              ; 5F4E row 04  Inst15
    R   ___                                     ; 5F50 row 05
    R   ___                                     ; 5F51 row 06
    R   ___                                     ; 5F52 row 07
    RI  C_4, 13, 0                              ; 5F53 row 08  Inst12
    R   ___                                     ; 5F55 row 09
    RI  C_3, 16, 0                              ; 5F56 row 10  Inst15
    R   ___                                     ; 5F58 row 11
    R   ___                                     ; 5F59 row 12
    R   ___                                     ; 5F5A row 13
    RI  As3, 13, 0                              ; 5F5B row 14  Inst12
    R   ___                                     ; 5F5D row 15
    R   ___                                     ; 5F5E row 16
    R   ___                                     ; 5F5F row 17
    RI  As2, 16, 0                              ; 5F60 row 18  Inst15
    R   ___                                     ; 5F62 row 19
    R   ___                                     ; 5F63 row 20
    R   ___                                     ; 5F64 row 21
    RI  As3, 13, 0                              ; 5F65 row 22  Inst12
    R   ___                                     ; 5F67 row 23
    RI  As3, 13, 0                              ; 5F68 row 24  Inst12
    R   ___                                     ; 5F6A row 25
    R   ___                                     ; 5F6B row 26
    R   ___                                     ; 5F6C row 27
    RI  As2, 16, 0                              ; 5F6D row 28  Inst15
    R   ___                                     ; 5F6F row 29
    R   ___                                     ; 5F70 row 30
    R   ___                                     ; 5F71 row 31
Track035:
    RI  C_2, 8, 0                               ; 5F72 row 00  Inst07
    R   ___                                     ; 5F74 row 01
    R   ___                                     ; 5F75 row 02
    RI  ___, 0, 0                               ; 5F76 row 03
    R   ___                                     ; 5F78 row 04
    R   ___                                     ; 5F79 row 05
    RI  C_2, 8, 0                               ; 5F7A row 06  Inst07
    RI  ___, 0, 0                               ; 5F7C row 07
    RI  C_2, 8, 0                               ; 5F7E row 08  Inst07
    R   ___                                     ; 5F80 row 09
    RI  ___, 0, 0                               ; 5F81 row 10
    R   ___                                     ; 5F83 row 11
    R   ___                                     ; 5F84 row 12
    R   ___                                     ; 5F85 row 13
    RI  As2, 8, 0                               ; 5F86 row 14  Inst07
    R   ___                                     ; 5F88 row 15
    R   ___                                     ; 5F89 row 16
    RI  ___, 0, 0                               ; 5F8A row 17
    RI  As2, 8, 0                               ; 5F8C row 18  Inst07
    RI  ___, 0, 0                               ; 5F8E row 19
    R   ___                                     ; 5F90 row 20
    R   ___                                     ; 5F91 row 21
    RI  As2, 8, 0                               ; 5F92 row 22  Inst07
    RI  ___, 0, 0                               ; 5F94 row 23
    RI  As2, 8, 0                               ; 5F96 row 24  Inst07
    R   ___                                     ; 5F98 row 25
    RI  ___, 0, 0                               ; 5F99 row 26
    R   ___                                     ; 5F9B row 27
    RI  B_2, 8, 0                               ; 5F9C row 28  Inst07
    R   ___                                     ; 5F9E row 29
    RI  ___, 0, 0                               ; 5F9F row 30
    R   ___                                     ; 5FA1 row 31
Track036:
    RI  C_3, 2, 0                               ; 5FA2 row 00  Inst01
    R   ___                                     ; 5FA4 row 01
    R   ___                                     ; 5FA5 row 02
    R   ___                                     ; 5FA6 row 03
    RI  C_3, 4, 0                               ; 5FA7 row 04  Inst03
    R   ___                                     ; 5FA9 row 05
    RI  C_3, 2, 0                               ; 5FAA row 06  Inst01
    R   ___                                     ; 5FAC row 07
    RI  C_3, 2, 0                               ; 5FAD row 08  Inst01
    R   ___                                     ; 5FAF row 09
    RI  C_3, 4, 0                               ; 5FB0 row 10  Inst03
    R   ___                                     ; 5FB2 row 11
    R   ___                                     ; 5FB3 row 12
    R   ___                                     ; 5FB4 row 13
    RI  C_3, 2, 0                               ; 5FB5 row 14  Inst01
    R   ___                                     ; 5FB7 row 15
    R   ___                                     ; 5FB8 row 16
    R   ___                                     ; 5FB9 row 17
    RI  C_3, 4, 0                               ; 5FBA row 18  Inst03
    R   ___                                     ; 5FBC row 19
    R   ___                                     ; 5FBD row 20
    R   ___                                     ; 5FBE row 21
    RI  C_3, 2, 0                               ; 5FBF row 22  Inst01
    R   ___                                     ; 5FC1 row 23
    RI  C_3, 2, 0                               ; 5FC2 row 24  Inst01
    R   ___                                     ; 5FC4 row 25
    R   ___                                     ; 5FC5 row 26
    R   ___                                     ; 5FC6 row 27
    RI  C_3, 4, 0                               ; 5FC7 row 28  Inst03
    R   ___                                     ; 5FC9 row 29
    R   ___                                     ; 5FCA row 30
    R   ___                                     ; 5FCB row 31
Track037:
    RI  G_4, 17, 0                              ; 5FCC row 00  Inst16
    R   ___                                     ; 5FCE row 01
    R   ___                                     ; 5FCF row 02
    R   ___                                     ; 5FD0 row 03
    RI  E_4, 17, 0                              ; 5FD1 row 04  Inst16
    RI  ___, 0, 2                               ; 5FD3 row 05
    RI  D_4, 17, 0                              ; 5FD5 row 06  Inst16
    R   ___                                     ; 5FD7 row 07
    R   ___                                     ; 5FD8 row 08
    R   ___                                     ; 5FD9 row 09
    RI  E_4, 17, 0                              ; 5FDA row 10  Inst16
    R   ___                                     ; 5FDC row 11
    RI  ___, 0, 2                               ; 5FDD row 12
    R   ___                                     ; 5FDF row 13
    RI  Ds4, 17, 0                              ; 5FE0 row 14  Inst16
    R   F_4                                     ; 5FE2 row 15
    R   ___                                     ; 5FE3 row 16
    R   ___                                     ; 5FE4 row 17
    RI  E_4, 17, 0                              ; 5FE5 row 18  Inst16
    R   ___                                     ; 5FE7 row 19
    R   ___                                     ; 5FE8 row 20
    RI  ___, 0, 2                               ; 5FE9 row 21
    RI  C_4, 17, 0                              ; 5FEB row 22  Inst16
    R   ___                                     ; 5FED row 23
    RI  As3, 17, 0                              ; 5FEE row 24  Inst16
    R   ___                                     ; 5FF0 row 25
    R   ___                                     ; 5FF1 row 26
    R   ___                                     ; 5FF2 row 27
    RI  B_3, 17, 0                              ; 5FF3 row 28  Inst16
    R   ___                                     ; 5FF5 row 29
    R   ___                                     ; 5FF6 row 30
    RI  ___, 0, 2                               ; 5FF7 row 31
Track038:
    RI  G_4, 17, 0                              ; 5FF9 row 00  Inst16
    R   ___                                     ; 5FFB row 01
    R   ___                                     ; 5FFC row 02
    R   ___                                     ; 5FFD row 03
    RI  E_4, 17, 0                              ; 5FFE row 04  Inst16
    RI  ___, 0, 2                               ; 6000 row 05
    RI  D_4, 17, 0                              ; 6002 row 06  Inst16
    R   ___                                     ; 6004 row 07
    R   ___                                     ; 6005 row 08
    R   ___                                     ; 6006 row 09
    RI  C_5, 17, 0                              ; 6007 row 10  Inst16
    R   ___                                     ; 6009 row 11
    R   ___                                     ; 600A row 12
    RI  ___, 0, 2                               ; 600B row 13
    RI  A_4, 17, 0                              ; 600D row 14  Inst16
    R   As4                                     ; 600F row 15
    R   ___                                     ; 6010 row 16
    R   ___                                     ; 6011 row 17
    R   ___                                     ; 6012 row 18
    R   ___                                     ; 6013 row 19
    R   ___                                     ; 6014 row 20
    R   ___                                     ; 6015 row 21
    R   ___                                     ; 6016 row 22
    RI  ___, 0, 3                               ; 6017 row 23
    R   ___                                     ; 6019 row 24
    R   ___                                     ; 601A row 25
    RI  As3, 17, 0                              ; 601B row 26  Inst16
    RI  ___, 0, 3                               ; 601D row 27
    RI  G_3, 17, 0                              ; 601F row 28  Inst16
    R   ___                                     ; 6021 row 29
    RI  As3, 17, 0                              ; 6022 row 30  Inst16
    RI  ___, 0, 3                               ; 6024 row 31
Track039:
    RI  G_4, 17, 0                              ; 6026 row 00  Inst16
    R   ___                                     ; 6028 row 01
    R   ___                                     ; 6029 row 02
    R   ___                                     ; 602A row 03
    RI  E_4, 17, 0                              ; 602B row 04  Inst16
    RI  ___, 0, 2                               ; 602D row 05
    RI  D_4, 17, 0                              ; 602F row 06  Inst16
    R   ___                                     ; 6031 row 07
    R   ___                                     ; 6032 row 08
    R   ___                                     ; 6033 row 09
    RI  C_5, 17, 0                              ; 6034 row 10  Inst16
    R   ___                                     ; 6036 row 11
    R   ___                                     ; 6037 row 12
    RI  ___, 0, 2                               ; 6038 row 13
    RI  C_5, 17, 0                              ; 603A row 14  Inst16
    R   D_5                                     ; 603C row 15
    R   ___                                     ; 603D row 16
    R   ___                                     ; 603E row 17
    R   ___                                     ; 603F row 18
    R   ___                                     ; 6040 row 19
    R   ___                                     ; 6041 row 20
    R   ___                                     ; 6042 row 21
    R   ___                                     ; 6043 row 22
    RI  ___, 0, 3                               ; 6044 row 23
    R   ___                                     ; 6046 row 24
    R   ___                                     ; 6047 row 25
    RI  As3, 17, 0                              ; 6048 row 26  Inst16
    RI  ___, 0, 3                               ; 604A row 27
    RI  G_3, 17, 0                              ; 604C row 28  Inst16
    R   ___                                     ; 604E row 29
    RI  As3, 17, 0                              ; 604F row 30  Inst16
    RI  ___, 0, 3                               ; 6051 row 31
Track040:
    RI  Fs3, 15, 0                              ; 6053 row 00  Inst14
    R   ___                                     ; 6055 row 01
    R   ___                                     ; 6056 row 02
    R   ___                                     ; 6057 row 03
    RI  E_3, 15, 0                              ; 6058 row 04  Inst14
    R   ___                                     ; 605A row 05
    RI  Fs3, 15, 0                              ; 605B row 06  Inst14
    R   ___                                     ; 605D row 07
    R   ___                                     ; 605E row 08
    R   ___                                     ; 605F row 09
    RI  A_3, 15, 0                              ; 6060 row 10  Inst14
    R   ___                                     ; 6062 row 11
    R   ___                                     ; 6063 row 12
    R   ___                                     ; 6064 row 13
    RI  C_4, 15, 0                              ; 6065 row 14  Inst14
    R   ___                                     ; 6067 row 15
    R   ___                                     ; 6068 row 16
    R   ___                                     ; 6069 row 17
    RI  B_3, 15, 0                              ; 606A row 18  Inst14
    R   ___                                     ; 606C row 19
    R   ___                                     ; 606D row 20
    R   ___                                     ; 606E row 21
    RI  A_3, 15, 0                              ; 606F row 22  Inst14
    R   ___                                     ; 6071 row 23
    RI  G_3, 15, 0                              ; 6072 row 24  Inst14
    R   ___                                     ; 6074 row 25
    R   ___                                     ; 6075 row 26
    R   ___                                     ; 6076 row 27
    RI  E_3, 15, 0                              ; 6077 row 28  Inst14
    R   ___                                     ; 6079 row 29
    R   ___                                     ; 607A row 30
    R   ___                                     ; 607B row 31
Track041:
    RI  Fs3, 15, 0                              ; 607C row 00  Inst14
    R   ___                                     ; 607E row 01
    R   ___                                     ; 607F row 02
    R   ___                                     ; 6080 row 03
    RI  E_3, 15, 0                              ; 6081 row 04  Inst14
    R   ___                                     ; 6083 row 05
    RI  Fs3, 15, 0                              ; 6084 row 06  Inst14
    R   ___                                     ; 6086 row 07
    R   ___                                     ; 6087 row 08
    R   ___                                     ; 6088 row 09
    RI  D_4, 15, 0                              ; 6089 row 10  Inst14
    R   ___                                     ; 608B row 11
    R   ___                                     ; 608C row 12
    R   ___                                     ; 608D row 13
    RI  C_4, 15, 0                              ; 608E row 14  Inst14
    R   ___                                     ; 6090 row 15
    R   ___                                     ; 6091 row 16
    R   ___                                     ; 6092 row 17
    R   ___                                     ; 6093 row 18
    R   ___                                     ; 6094 row 19
    R   ___                                     ; 6095 row 20
    R   ___                                     ; 6096 row 21
    R   ___                                     ; 6097 row 22
    R   ___                                     ; 6098 row 23
    R   ___                                     ; 6099 row 24
    R   ___                                     ; 609A row 25
    R   ___                                     ; 609B row 26
    R   ___                                     ; 609C row 27
    R   ___                                     ; 609D row 28
    R   ___                                     ; 609E row 29
    R   ___                                     ; 609F row 30
    R   ___                                     ; 60A0 row 31
Track042:
    RI  Fs3, 15, 0                              ; 60A1 row 00  Inst14
    R   ___                                     ; 60A3 row 01
    R   ___                                     ; 60A4 row 02
    R   ___                                     ; 60A5 row 03
    RI  E_3, 15, 0                              ; 60A6 row 04  Inst14
    R   ___                                     ; 60A8 row 05
    RI  Fs3, 15, 0                              ; 60A9 row 06  Inst14
    R   ___                                     ; 60AB row 07
    R   ___                                     ; 60AC row 08
    R   ___                                     ; 60AD row 09
    RI  Cs4, 15, 0                              ; 60AE row 10  Inst14
    R   D_4                                     ; 60B0 row 11
    R   ___                                     ; 60B1 row 12
    R   ___                                     ; 60B2 row 13
    RI  E_4, 15, 0                              ; 60B3 row 14  Inst14
    R   ___                                     ; 60B5 row 15
    RI  ___, 0, 1                               ; 60B6 row 16
    R   ___                                     ; 60B8 row 17
    RI  C_4, 15, 0                              ; 60B9 row 18  Inst14
    R   ___                                     ; 60BB row 19
    RI  ___, 0, 1                               ; 60BC row 20
    R   ___                                     ; 60BE row 21
    RI  G_4, 15, 0                              ; 60BF row 22  Inst14
    R   ___                                     ; 60C1 row 23
    R   ___                                     ; 60C2 row 24
    RI  ___, 0, 1                               ; 60C3 row 25
    RI  Fs4, 15, 0                              ; 60C5 row 26  Inst14
    R   ___                                     ; 60C7 row 27
    RI  ___, 0, 1                               ; 60C8 row 28
    R   ___                                     ; 60CA row 29
    RI  D_4, 15, 0                              ; 60CB row 30  Inst14
    R   ___                                     ; 60CD row 31
Track043:
    R   ___                                     ; 60CE row 00
    R   ___                                     ; 60CF row 01
    R   ___                                     ; 60D0 row 02
    R   ___                                     ; 60D1 row 03
    R   ___                                     ; 60D2 row 04
    R   ___                                     ; 60D3 row 05
    R   ___                                     ; 60D4 row 06
    R   ___                                     ; 60D5 row 07
    R   ___                                     ; 60D6 row 08
    R   ___                                     ; 60D7 row 09
    R   ___                                     ; 60D8 row 10
    R   ___                                     ; 60D9 row 11
    R   ___                                     ; 60DA row 12
    R   ___                                     ; 60DB row 13
    R   ___                                     ; 60DC row 14
    R   ___                                     ; 60DD row 15
    R   ___                                     ; 60DE row 16
    R   ___                                     ; 60DF row 17
    R   ___                                     ; 60E0 row 18
    R   ___                                     ; 60E1 row 19
    R   ___                                     ; 60E2 row 20
    R   ___                                     ; 60E3 row 21
    R   ___                                     ; 60E4 row 22
    R   ___                                     ; 60E5 row 23
    R   ___                                     ; 60E6 row 24
    R   ___                                     ; 60E7 row 25
    R   ___                                     ; 60E8 row 26
    R   ___                                     ; 60E9 row 27
    R   ___                                     ; 60EA row 28
    R   ___                                     ; 60EB row 29
    R   ___                                     ; 60EC row 30
    R   ___                                     ; 60ED row 31
Track044:
    RI  C_4, 18, 0                              ; 60EE row 00  Inst17
    R   ___                                     ; 60F0 row 01
    R   ___                                     ; 60F1 row 02
    R   ___                                     ; 60F2 row 03
    R   ___                                     ; 60F3 row 04
    R   ___                                     ; 60F4 row 05
    RI  G_4, 18, 0                              ; 60F5 row 06  Inst17
    R   ___                                     ; 60F7 row 07
    R   ___                                     ; 60F8 row 08
    R   ___                                     ; 60F9 row 09
    R   ___                                     ; 60FA row 10
    R   ___                                     ; 60FB row 11
    R   ___                                     ; 60FC row 12
    R   ___                                     ; 60FD row 13
    RI  C_4, 18, 0                              ; 60FE row 14  Inst17
    R   ___                                     ; 6100 row 15
    R   ___                                     ; 6101 row 16
    R   ___                                     ; 6102 row 17
    R   ___                                     ; 6103 row 18
    R   ___                                     ; 6104 row 19
    R   ___                                     ; 6105 row 20
    R   ___                                     ; 6106 row 21
    RI  G_3, 18, 0                              ; 6107 row 22  Inst17
    R   ___                                     ; 6109 row 23
    RI  G_4, 18, 0                              ; 610A row 24  Inst17
    R   ___                                     ; 610C row 25
    R   ___                                     ; 610D row 26
    R   ___                                     ; 610E row 27
    RI  C_4, 18, 0                              ; 610F row 28  Inst17
    R   ___                                     ; 6111 row 29
    R   ___                                     ; 6112 row 30
    R   ___                                     ; 6113 row 31
Track045:
    RI  C_4, 19, 0                              ; 6114 row 00  Inst18
    R   ___                                     ; 6116 row 01
    R   ___                                     ; 6117 row 02
    R   ___                                     ; 6118 row 03
    R   ___                                     ; 6119 row 04
    R   ___                                     ; 611A row 05
    RI  G_4, 19, 0                              ; 611B row 06  Inst18
    R   ___                                     ; 611D row 07
    R   ___                                     ; 611E row 08
    R   ___                                     ; 611F row 09
    R   ___                                     ; 6120 row 10
    R   ___                                     ; 6121 row 11
    R   ___                                     ; 6122 row 12
    R   ___                                     ; 6123 row 13
    RI  C_4, 19, 0                              ; 6124 row 14  Inst18
    R   ___                                     ; 6126 row 15
    R   ___                                     ; 6127 row 16
    R   ___                                     ; 6128 row 17
    R   ___                                     ; 6129 row 18
    R   ___                                     ; 612A row 19
    R   ___                                     ; 612B row 20
    R   ___                                     ; 612C row 21
    RI  G_3, 19, 0                              ; 612D row 22  Inst18
    R   ___                                     ; 612F row 23
    RI  G_4, 19, 0                              ; 6130 row 24  Inst18
    R   ___                                     ; 6132 row 25
    R   ___                                     ; 6133 row 26
    R   ___                                     ; 6134 row 27
    RI  C_4, 19, 0                              ; 6135 row 28  Inst18
    R   ___                                     ; 6137 row 29
    R   ___                                     ; 6138 row 30
    R   ___                                     ; 6139 row 31
Track046:
    RI  D_2, 8, 0                               ; 613A row 00  Inst07
    R   ___                                     ; 613C row 01
    R   ___                                     ; 613D row 02
    RI  ___, 0, 0                               ; 613E row 03
    R   ___                                     ; 6140 row 04
    R   ___                                     ; 6141 row 05
    RI  D_2, 8, 0                               ; 6142 row 06  Inst07
    RI  ___, 0, 0                               ; 6144 row 07
    RI  D_3, 8, 0                               ; 6146 row 08  Inst07
    R   ___                                     ; 6148 row 09
    RI  ___, 0, 0                               ; 6149 row 10
    R   ___                                     ; 614B row 11
    R   ___                                     ; 614C row 12
    R   ___                                     ; 614D row 13
    RI  As2, 8, 0                               ; 614E row 14  Inst07
    R   ___                                     ; 6150 row 15
    R   ___                                     ; 6151 row 16
    RI  ___, 0, 0                               ; 6152 row 17
    RI  As2, 8, 0                               ; 6154 row 18  Inst07
    RI  ___, 0, 0                               ; 6156 row 19
    R   ___                                     ; 6158 row 20
    R   ___                                     ; 6159 row 21
    RI  As2, 8, 0                               ; 615A row 22  Inst07
    RI  ___, 0, 0                               ; 615C row 23
    RI  As2, 8, 0                               ; 615E row 24  Inst07
    R   ___                                     ; 6160 row 25
    RI  ___, 0, 0                               ; 6161 row 26
    R   ___                                     ; 6163 row 27
    RI  C_3, 8, 0                               ; 6164 row 28  Inst07
    R   ___                                     ; 6166 row 29
    RI  ___, 0, 0                               ; 6167 row 30
    R   ___                                     ; 6169 row 31
Track047:
    RI  D_4, 18, 0                              ; 616A row 00  Inst17
    R   ___                                     ; 616C row 01
    R   ___                                     ; 616D row 02
    R   ___                                     ; 616E row 03
    R   ___                                     ; 616F row 04
    R   ___                                     ; 6170 row 05
    RI  A_4, 18, 0                              ; 6171 row 06  Inst17
    R   ___                                     ; 6173 row 07
    R   ___                                     ; 6174 row 08
    R   ___                                     ; 6175 row 09
    R   ___                                     ; 6176 row 10
    R   ___                                     ; 6177 row 11
    R   ___                                     ; 6178 row 12
    R   ___                                     ; 6179 row 13
    RI  F_4, 18, 0                              ; 617A row 14  Inst17
    R   ___                                     ; 617C row 15
    R   ___                                     ; 617D row 16
    R   ___                                     ; 617E row 17
    R   ___                                     ; 617F row 18
    R   ___                                     ; 6180 row 19
    R   ___                                     ; 6181 row 20
    R   ___                                     ; 6182 row 21
    RI  F_4, 18, 0                              ; 6183 row 22  Inst17
    R   ___                                     ; 6185 row 23
    RI  E_4, 18, 0                              ; 6186 row 24  Inst17
    R   ___                                     ; 6188 row 25
    R   ___                                     ; 6189 row 26
    R   ___                                     ; 618A row 27
    RI  C_4, 18, 0                              ; 618B row 28  Inst17
    R   ___                                     ; 618D row 29
    R   ___                                     ; 618E row 30
    R   ___                                     ; 618F row 31
Track048:
    R   ___                                     ; 6190 row 00
    R   ___                                     ; 6191 row 01
    R   ___                                     ; 6192 row 02
    R   ___                                     ; 6193 row 03
    RI  C_4, 20, 0                              ; 6194 row 04  Inst19
    R   ___                                     ; 6196 row 05
    R   ___                                     ; 6197 row 06
    R   ___                                     ; 6198 row 07
    RI  D_4, 13, 0                              ; 6199 row 08  Inst12
    R   ___                                     ; 619B row 09
    RI  C_4, 20, 0                              ; 619C row 10  Inst19
    R   ___                                     ; 619E row 11
    R   ___                                     ; 619F row 12
    R   ___                                     ; 61A0 row 13
    RI  As3, 13, 0                              ; 61A1 row 14  Inst12
    R   ___                                     ; 61A3 row 15
    R   ___                                     ; 61A4 row 16
    R   ___                                     ; 61A5 row 17
    RI  F_3, 21, 0                              ; 61A6 row 18  Inst20
    R   ___                                     ; 61A8 row 19
    R   ___                                     ; 61A9 row 20
    R   ___                                     ; 61AA row 21
    RI  As3, 13, 0                              ; 61AB row 22  Inst12
    R   ___                                     ; 61AD row 23
    RI  As3, 13, 0                              ; 61AE row 24  Inst12
    R   ___                                     ; 61B0 row 25
    R   ___                                     ; 61B1 row 26
    R   ___                                     ; 61B2 row 27
    RI  G_3, 21, 0                              ; 61B3 row 28  Inst20
    R   ___                                     ; 61B5 row 29
    R   ___                                     ; 61B6 row 30
    R   ___                                     ; 61B7 row 31
Track049:
    RI  D_4, 19, 0                              ; 61B8 row 00  Inst18
    R   ___                                     ; 61BA row 01
    R   ___                                     ; 61BB row 02
    R   ___                                     ; 61BC row 03
    R   ___                                     ; 61BD row 04
    R   ___                                     ; 61BE row 05
    RI  A_4, 19, 0                              ; 61BF row 06  Inst18
    R   ___                                     ; 61C1 row 07
    R   ___                                     ; 61C2 row 08
    R   ___                                     ; 61C3 row 09
    R   ___                                     ; 61C4 row 10
    R   ___                                     ; 61C5 row 11
    R   ___                                     ; 61C6 row 12
    R   ___                                     ; 61C7 row 13
    RI  F_4, 19, 0                              ; 61C8 row 14  Inst18
    R   ___                                     ; 61CA row 15
    R   ___                                     ; 61CB row 16
    R   ___                                     ; 61CC row 17
    R   ___                                     ; 61CD row 18
    R   ___                                     ; 61CE row 19
    R   ___                                     ; 61CF row 20
    R   ___                                     ; 61D0 row 21
    RI  F_4, 19, 0                              ; 61D1 row 22  Inst18
    R   ___                                     ; 61D3 row 23
    RI  E_4, 19, 0                              ; 61D4 row 24  Inst18
    R   ___                                     ; 61D6 row 25
    R   ___                                     ; 61D7 row 26
    R   ___                                     ; 61D8 row 27
    RI  C_4, 19, 0                              ; 61D9 row 28  Inst18
    R   ___                                     ; 61DB row 29
    R   ___                                     ; 61DC row 30
    R   ___                                     ; 61DD row 31
Track050:
    RIF F_2, 23, 0, $F, $7                      ; 61DE row 00  Inst22  speed 7
    R   ___                                     ; 61E1 row 01
    R   ___                                     ; 61E2 row 02
    R   ___                                     ; 61E3 row 03
    RI  F_3, 23, 0                              ; 61E4 row 04  Inst22
    R   ___                                     ; 61E6 row 05
    R   ___                                     ; 61E7 row 06
    R   ___                                     ; 61E8 row 07
    RI  E_3, 24, 0                              ; 61E9 row 08  Inst23
    R   ___                                     ; 61EB row 09
    R   ___                                     ; 61EC row 10
    R   ___                                     ; 61ED row 11
    RI  F_3, 23, 0                              ; 61EE row 12  Inst22
    R   ___                                     ; 61F0 row 13
    RI  F_3, 25, 0                              ; 61F1 row 14  Inst24
    R   ___                                     ; 61F3 row 15
    R   ___                                     ; 61F4 row 16
    R   ___                                     ; 61F5 row 17
    RI  F_3, 25, 0                              ; 61F6 row 18  Inst24
    R   ___                                     ; 61F8 row 19
    R   ___                                     ; 61F9 row 20
    R   ___                                     ; 61FA row 21
    RI  F_3, 25, 0                              ; 61FB row 22  Inst24
    R   ___                                     ; 61FD row 23
    RI  F_3, 23, 0                              ; 61FE row 24  Inst22
    R   ___                                     ; 6200 row 25
    R   ___                                     ; 6201 row 26
    R   ___                                     ; 6202 row 27
    RI  E_3, 24, 0                              ; 6203 row 28  Inst23
    R   ___                                     ; 6205 row 29
    R   ___                                     ; 6206 row 30
    R   ___                                     ; 6207 row 31
Track051:
    RI  F_2, 8, 0                               ; 6208 row 00  Inst07
    R   ___                                     ; 620A row 01
    R   ___                                     ; 620B row 02
    RI  ___, 0, 0                               ; 620C row 03
    R   ___                                     ; 620E row 04
    R   ___                                     ; 620F row 05
    RI  F_2, 8, 0                               ; 6210 row 06  Inst07
    R   ___                                     ; 6212 row 07
    R   ___                                     ; 6213 row 08
    RI  ___, 0, 0                               ; 6214 row 09
    R   ___                                     ; 6216 row 10
    R   ___                                     ; 6217 row 11
    RI  F_2, 8, 0                               ; 6218 row 12  Inst07
    RI  ___, 0, 0                               ; 621A row 13
    RI  D_2, 8, 0                               ; 621C row 14  Inst07
    RI  ___, 0, 0                               ; 621E row 15
    RI  D_3, 8, 0                               ; 6220 row 16  Inst07
    R   ___                                     ; 6222 row 17
    R   ___                                     ; 6223 row 18
    RI  ___, 0, 0                               ; 6224 row 19
    R   ___                                     ; 6226 row 20
    R   ___                                     ; 6227 row 21
    RI  D_3, 8, 0                               ; 6228 row 22  Inst07
    RI  ___, 0, 0                               ; 622A row 23
    RI  C_3, 8, 0                               ; 622C row 24  Inst07
    R   ___                                     ; 622E row 25
    RI  ___, 0, 0                               ; 622F row 26
    R   ___                                     ; 6231 row 27
    RI  E_2, 8, 0                               ; 6232 row 28  Inst07
    R   ___                                     ; 6234 row 29
    RI  ___, 0, 0                               ; 6235 row 30
    R   ___                                     ; 6237 row 31
Track052:
    RI  C_3, 2, 0                               ; 6238 row 00  Inst01
    R   ___                                     ; 623A row 01
    RI  C_3, 3, 0                               ; 623B row 02  Inst02
    R   ___                                     ; 623D row 03
    RI  C_3, 4, 0                               ; 623E row 04  Inst03
    R   ___                                     ; 6240 row 05
    RI  C_3, 2, 0                               ; 6241 row 06  Inst01
    R   ___                                     ; 6243 row 07
    R   ___                                     ; 6244 row 08
    R   ___                                     ; 6245 row 09
    RI  C_3, 4, 0                               ; 6246 row 10  Inst03
    R   ___                                     ; 6248 row 11
    RI  C_3, 3, 0                               ; 6249 row 12  Inst02
    R   ___                                     ; 624B row 13
    RI  C_3, 2, 0                               ; 624C row 14  Inst01
    R   ___                                     ; 624E row 15
    RI  C_3, 2, 0                               ; 624F row 16  Inst01
    R   ___                                     ; 6251 row 17
    RI  C_3, 3, 0                               ; 6252 row 18  Inst02
    R   ___                                     ; 6254 row 19
    RI  C_3, 4, 0                               ; 6255 row 20  Inst03
    R   ___                                     ; 6257 row 21
    RI  C_3, 2, 0                               ; 6258 row 22  Inst01
    R   ___                                     ; 625A row 23
    R   ___                                     ; 625B row 24
    R   ___                                     ; 625C row 25
    RI  C_3, 4, 0                               ; 625D row 26  Inst03
    R   ___                                     ; 625F row 27
    RI  C_3, 3, 0                               ; 6260 row 28  Inst02
    R   ___                                     ; 6262 row 29
    RI  C_3, 2, 0                               ; 6263 row 30  Inst01
    R   ___                                     ; 6265 row 31
Track053:
    R   ___                                     ; 6266 row 00
    R   ___                                     ; 6267 row 01
    R   ___                                     ; 6268 row 02
    R   ___                                     ; 6269 row 03
    R   ___                                     ; 626A row 04
    R   ___                                     ; 626B row 05
    R   ___                                     ; 626C row 06
    R   ___                                     ; 626D row 07
    R   ___                                     ; 626E row 08
    R   ___                                     ; 626F row 09
    R   ___                                     ; 6270 row 10
    R   ___                                     ; 6271 row 11
    R   ___                                     ; 6272 row 12
    R   ___                                     ; 6273 row 13
    R   ___                                     ; 6274 row 14
    R   ___                                     ; 6275 row 15
    R   ___                                     ; 6276 row 16
    R   ___                                     ; 6277 row 17
    R   ___                                     ; 6278 row 18
    R   ___                                     ; 6279 row 19
    R   ___                                     ; 627A row 20
    R   ___                                     ; 627B row 21
    R   ___                                     ; 627C row 22
    R   ___                                     ; 627D row 23
    R   ___                                     ; 627E row 24
    R   ___                                     ; 627F row 25
    R   ___                                     ; 6280 row 26
    R   ___                                     ; 6281 row 27
    R   ___                                     ; 6282 row 28
    R   ___                                     ; 6283 row 29
    R   ___                                     ; 6284 row 30
    R   ___                                     ; 6285 row 31
Track054:
    RI  F_2, 23, 0                              ; 6286 row 00  Inst22
    R   ___                                     ; 6288 row 01
    R   ___                                     ; 6289 row 02
    R   ___                                     ; 628A row 03
    RI  F_3, 23, 0                              ; 628B row 04  Inst22
    R   ___                                     ; 628D row 05
    R   ___                                     ; 628E row 06
    R   ___                                     ; 628F row 07
    RI  E_3, 24, 0                              ; 6290 row 08  Inst23
    R   ___                                     ; 6292 row 09
    R   ___                                     ; 6293 row 10
    R   ___                                     ; 6294 row 11
    RI  F_3, 23, 0                              ; 6295 row 12  Inst22
    R   ___                                     ; 6297 row 13
    RI  As2, 23, 0                              ; 6298 row 14  Inst22
    R   ___                                     ; 629A row 15
    R   ___                                     ; 629B row 16
    R   ___                                     ; 629C row 17
    RI  As2, 23, 0                              ; 629D row 18  Inst22
    R   ___                                     ; 629F row 19
    R   ___                                     ; 62A0 row 20
    R   ___                                     ; 62A1 row 21
    RI  As2, 23, 0                              ; 62A2 row 22  Inst22
    R   ___                                     ; 62A4 row 23
    RI  C_3, 23, 0                              ; 62A5 row 24  Inst22
    R   ___                                     ; 62A7 row 25
    R   ___                                     ; 62A8 row 26
    R   ___                                     ; 62A9 row 27
    RI  C_3, 23, 0                              ; 62AA row 28  Inst22
    R   ___                                     ; 62AC row 29
    R   ___                                     ; 62AD row 30
    R   ___                                     ; 62AE row 31
Track055:
    RI  F_4, 15, 0                              ; 62AF row 00  Inst14
    R   ___                                     ; 62B1 row 01
    RI  G_4, 15, 0                              ; 62B2 row 02  Inst14
    R   ___                                     ; 62B4 row 03
    R   ___                                     ; 62B5 row 04
    R   ___                                     ; 62B6 row 05
    RI  C_5, 15, 0                              ; 62B7 row 06  Inst14
    R   ___                                     ; 62B9 row 07
    R   ___                                     ; 62BA row 08
    R   ___                                     ; 62BB row 09
    R   ___                                     ; 62BC row 10
    R   ___                                     ; 62BD row 11
    RI  As4, 15, 0                              ; 62BE row 12  Inst14
    R   ___                                     ; 62C0 row 13
    RI  A_4, 15, 0                              ; 62C1 row 14  Inst14
    R   ___                                     ; 62C3 row 15
    RI  As4, 15, 0                              ; 62C4 row 16  Inst14
    R   ___                                     ; 62C6 row 17
    R   ___                                     ; 62C7 row 18
    R   ___                                     ; 62C8 row 19
    RI  A_4, 15, 0                              ; 62C9 row 20  Inst14
    R   ___                                     ; 62CB row 21
    RI  F_4, 15, 0                              ; 62CC row 22  Inst14
    R   ___                                     ; 62CE row 23
    R   ___                                     ; 62CF row 24
    R   ___                                     ; 62D0 row 25
    RI  G_4, 15, 0                              ; 62D1 row 26  Inst14
    R   ___                                     ; 62D3 row 27
    R   ___                                     ; 62D4 row 28
    R   ___                                     ; 62D5 row 29
    R   ___                                     ; 62D6 row 30
    R   ___                                     ; 62D7 row 31
Track056:
    RI  C_3, 2, 0                               ; 62D8 row 00  Inst01
    R   ___                                     ; 62DA row 01
    RI  C_3, 3, 0                               ; 62DB row 02  Inst02
    R   ___                                     ; 62DD row 03
    RI  C_3, 4, 0                               ; 62DE row 04  Inst03
    R   ___                                     ; 62E0 row 05
    RI  C_3, 2, 0                               ; 62E1 row 06  Inst01
    R   ___                                     ; 62E3 row 07
    R   ___                                     ; 62E4 row 08
    R   ___                                     ; 62E5 row 09
    RI  C_3, 4, 0                               ; 62E6 row 10  Inst03
    R   ___                                     ; 62E8 row 11
    RI  C_3, 3, 0                               ; 62E9 row 12  Inst02
    R   ___                                     ; 62EB row 13
    RI  C_3, 2, 0                               ; 62EC row 14  Inst01
    R   ___                                     ; 62EE row 15
    RI  C_3, 2, 0                               ; 62EF row 16  Inst01
    R   ___                                     ; 62F1 row 17
    RI  C_3, 3, 0                               ; 62F2 row 18  Inst02
    R   ___                                     ; 62F4 row 19
    RI  C_3, 4, 0                               ; 62F5 row 20  Inst03
    R   ___                                     ; 62F7 row 21
    RI  C_3, 2, 0                               ; 62F8 row 22  Inst01
    R   ___                                     ; 62FA row 23
    RI  C_4, 4, 1                               ; 62FB row 24  Inst03
    R   ___                                     ; 62FD row 25
    RI  C_3, 4, 0                               ; 62FE row 26  Inst03
    R   ___                                     ; 6300 row 27
    RI  C_3, 3, 0                               ; 6301 row 28  Inst02
    R   ___                                     ; 6303 row 29
    RI  C_4, 4, 0                               ; 6304 row 30  Inst03
    R   ___                                     ; 6306 row 31
Track057:
    RI  F_4, 15, 0                              ; 6307 row 00  Inst14
    R   ___                                     ; 6309 row 01
    RI  G_4, 15, 0                              ; 630A row 02  Inst14
    R   ___                                     ; 630C row 03
    R   ___                                     ; 630D row 04
    R   ___                                     ; 630E row 05
    RI  C_5, 15, 0                              ; 630F row 06  Inst14
    R   ___                                     ; 6311 row 07
    R   ___                                     ; 6312 row 08
    R   ___                                     ; 6313 row 09
    R   ___                                     ; 6314 row 10
    R   ___                                     ; 6315 row 11
    RI  As4, 15, 0                              ; 6316 row 12  Inst14
    R   ___                                     ; 6318 row 13
    RI  A_4, 15, 0                              ; 6319 row 14  Inst14
    R   ___                                     ; 631B row 15
    RI  D_5, 15, 0                              ; 631C row 16  Inst14
    R   ___                                     ; 631E row 17
    R   ___                                     ; 631F row 18
    R   ___                                     ; 6320 row 19
    RI  F_5, 15, 0                              ; 6321 row 20  Inst14
    R   ___                                     ; 6323 row 21
    RI  C_5, 15, 0                              ; 6324 row 22  Inst14
    R   ___                                     ; 6326 row 23
    R   ___                                     ; 6327 row 24
    R   ___                                     ; 6328 row 25
    R   ___                                     ; 6329 row 26
    R   ___                                     ; 632A row 27
    R   ___                                     ; 632B row 28
    R   ___                                     ; 632C row 29
    R   ___                                     ; 632D row 30
    R   ___                                     ; 632E row 31
Track058:
    RI  F_4, 15, 0                              ; 632F row 00  Inst14
    R   ___                                     ; 6331 row 01
    RI  G_4, 15, 0                              ; 6332 row 02  Inst14
    R   ___                                     ; 6334 row 03
    R   ___                                     ; 6335 row 04
    R   ___                                     ; 6336 row 05
    RI  C_5, 15, 0                              ; 6337 row 06  Inst14
    R   ___                                     ; 6339 row 07
    R   ___                                     ; 633A row 08
    R   ___                                     ; 633B row 09
    R   ___                                     ; 633C row 10
    R   ___                                     ; 633D row 11
    RI  As4, 15, 0                              ; 633E row 12  Inst14
    R   ___                                     ; 6340 row 13
    RI  A_4, 15, 0                              ; 6341 row 14  Inst14
    R   ___                                     ; 6343 row 15
    RI  D_5, 15, 0                              ; 6344 row 16  Inst14
    R   ___                                     ; 6346 row 17
    R   ___                                     ; 6347 row 18
    R   ___                                     ; 6348 row 19
    RI  F_5, 15, 0                              ; 6349 row 20  Inst14
    R   ___                                     ; 634B row 21
    RI  G_5, 15, 0                              ; 634C row 22  Inst14
    R   ___                                     ; 634E row 23
    R   ___                                     ; 634F row 24
    R   ___                                     ; 6350 row 25
    R   ___                                     ; 6351 row 26
    R   ___                                     ; 6352 row 27
    R   ___                                     ; 6353 row 28
    R   ___                                     ; 6354 row 29
    R   ___                                     ; 6355 row 30
    R   ___                                     ; 6356 row 31
Track059:
    RI  As2, 8, 0                               ; 6357 row 00  Inst07
    R   ___                                     ; 6359 row 01
    R   ___                                     ; 635A row 02
    RI  ___, 0, 0                               ; 635B row 03
    R   ___                                     ; 635D row 04
    R   ___                                     ; 635E row 05
    RI  As2, 8, 0                               ; 635F row 06  Inst07
    R   ___                                     ; 6361 row 07
    R   ___                                     ; 6362 row 08
    RI  ___, 0, 0                               ; 6363 row 09
    R   ___                                     ; 6365 row 10
    R   ___                                     ; 6366 row 11
    RI  As2, 8, 0                               ; 6367 row 12  Inst07
    RI  ___, 0, 0                               ; 6369 row 13
    RI  A_2, 8, 0                               ; 636B row 14  Inst07
    RI  ___, 0, 0                               ; 636D row 15
    RI  A_2, 8, 0                               ; 636F row 16  Inst07
    R   ___                                     ; 6371 row 17
    R   ___                                     ; 6372 row 18
    RI  ___, 0, 0                               ; 6373 row 19
    R   ___                                     ; 6375 row 20
    R   ___                                     ; 6376 row 21
    RI  A_2, 8, 0                               ; 6377 row 22  Inst07
    RI  ___, 0, 0                               ; 6379 row 23
    RI  A_2, 8, 0                               ; 637B row 24  Inst07
    R   ___                                     ; 637D row 25
    RI  ___, 0, 0                               ; 637E row 26
    R   ___                                     ; 6380 row 27
    RI  A_2, 8, 0                               ; 6381 row 28  Inst07
    R   ___                                     ; 6383 row 29
    RI  ___, 0, 0                               ; 6384 row 30
    R   ___                                     ; 6386 row 31
Track060:
    RI  G_2, 8, 0                               ; 6387 row 00  Inst07
    R   ___                                     ; 6389 row 01
    R   ___                                     ; 638A row 02
    RI  ___, 0, 0                               ; 638B row 03
    R   ___                                     ; 638D row 04
    R   ___                                     ; 638E row 05
    RI  G_2, 8, 0                               ; 638F row 06  Inst07
    R   ___                                     ; 6391 row 07
    R   ___                                     ; 6392 row 08
    RI  ___, 0, 0                               ; 6393 row 09
    R   ___                                     ; 6395 row 10
    R   ___                                     ; 6396 row 11
    RI  G_2, 8, 0                               ; 6397 row 12  Inst07
    RI  ___, 0, 0                               ; 6399 row 13
    RI  G_2, 8, 0                               ; 639B row 14  Inst07
    RI  ___, 0, 0                               ; 639D row 15
    RI  C_3, 8, 0                               ; 639F row 16  Inst07
    R   ___                                     ; 63A1 row 17
    R   ___                                     ; 63A2 row 18
    RI  ___, 0, 0                               ; 63A3 row 19
    R   ___                                     ; 63A5 row 20
    R   ___                                     ; 63A6 row 21
    RI  C_3, 8, 0                               ; 63A7 row 22  Inst07
    RI  ___, 0, 0                               ; 63A9 row 23
    RI  C_3, 8, 0                               ; 63AB row 24  Inst07
    R   ___                                     ; 63AD row 25
    RI  ___, 0, 0                               ; 63AE row 26
    R   ___                                     ; 63B0 row 27
    RI  C_3, 8, 0                               ; 63B1 row 28  Inst07
    R   ___                                     ; 63B3 row 29
    RI  ___, 0, 0                               ; 63B4 row 30
    R   ___                                     ; 63B6 row 31
Track061:
    RI  D_2, 24, 0                              ; 63B7 row 00  Inst23
    R   ___                                     ; 63B9 row 01
    R   ___                                     ; 63BA row 02
    R   ___                                     ; 63BB row 03
    RI  D_3, 24, 0                              ; 63BC row 04  Inst23
    R   ___                                     ; 63BE row 05
    R   ___                                     ; 63BF row 06
    R   ___                                     ; 63C0 row 07
    RI  C_3, 23, 0                              ; 63C1 row 08  Inst22
    R   ___                                     ; 63C3 row 09
    R   ___                                     ; 63C4 row 10
    R   ___                                     ; 63C5 row 11
    RI  D_3, 24, 0                              ; 63C6 row 12  Inst23
    R   ___                                     ; 63C8 row 13
    RI  A_2, 24, 0                              ; 63C9 row 14  Inst23
    R   ___                                     ; 63CB row 15
    R   ___                                     ; 63CC row 16
    R   ___                                     ; 63CD row 17
    RI  A_2, 24, 0                              ; 63CE row 18  Inst23
    R   ___                                     ; 63D0 row 19
    R   ___                                     ; 63D1 row 20
    R   ___                                     ; 63D2 row 21
    RI  A_2, 24, 0                              ; 63D3 row 22  Inst23
    R   ___                                     ; 63D5 row 23
    RI  C_3, 23, 0                              ; 63D6 row 24  Inst22
    R   ___                                     ; 63D8 row 25
    R   ___                                     ; 63D9 row 26
    R   ___                                     ; 63DA row 27
    RI  D_3, 24, 0                              ; 63DB row 28  Inst23
    R   ___                                     ; 63DD row 29
    R   ___                                     ; 63DE row 30
    R   ___                                     ; 63DF row 31
Track062:
    RI  D_2, 24, 0                              ; 63E0 row 00  Inst23
    R   ___                                     ; 63E2 row 01
    R   ___                                     ; 63E3 row 02
    R   ___                                     ; 63E4 row 03
    RI  D_3, 24, 0                              ; 63E5 row 04  Inst23
    R   ___                                     ; 63E7 row 05
    R   ___                                     ; 63E8 row 06
    R   ___                                     ; 63E9 row 07
    RI  C_3, 23, 0                              ; 63EA row 08  Inst22
    R   ___                                     ; 63EC row 09
    R   ___                                     ; 63ED row 10
    R   ___                                     ; 63EE row 11
    RI  D_3, 24, 0                              ; 63EF row 12  Inst23
    R   ___                                     ; 63F1 row 13
    RI  G_2, 25, 0                              ; 63F2 row 14  Inst24
    R   ___                                     ; 63F4 row 15
    R   ___                                     ; 63F5 row 16
    R   ___                                     ; 63F6 row 17
    RI  G_2, 25, 0                              ; 63F7 row 18  Inst24
    R   ___                                     ; 63F9 row 19
    R   ___                                     ; 63FA row 20
    R   ___                                     ; 63FB row 21
    RI  G_2, 25, 0                              ; 63FC row 22  Inst24
    R   ___                                     ; 63FE row 23
    RI  As2, 23, 0                              ; 63FF row 24  Inst22
    R   ___                                     ; 6401 row 25
    R   ___                                     ; 6402 row 26
    R   ___                                     ; 6403 row 27
    RI  G_2, 25, 0                              ; 6404 row 28  Inst24
    R   ___                                     ; 6406 row 29
    R   ___                                     ; 6407 row 30
    R   ___                                     ; 6408 row 31
Track063:
    R   ___                                     ; 6409 row 00
    R   ___                                     ; 640A row 01
    R   ___                                     ; 640B row 02
    R   ___                                     ; 640C row 03
    RI  F_5, 17, 0                              ; 640D row 04  Inst16
    R   ___                                     ; 640F row 05
    RI  ___, 0, 1                               ; 6410 row 06
    R   ___                                     ; 6412 row 07
    RI  E_5, 17, 0                              ; 6413 row 08  Inst16
    R   ___                                     ; 6415 row 09
    RI  ___, 0, 1                               ; 6416 row 10
    R   ___                                     ; 6418 row 11
    RI  F_5, 17, 0                              ; 6419 row 12  Inst16
    R   ___                                     ; 641B row 13
    RI  C_5, 17, 0                              ; 641C row 14  Inst16
    R   ___                                     ; 641E row 15
    RI  ___, 0, 1                               ; 641F row 16
    R   ___                                     ; 6421 row 17
    RI  C_5, 17, 0                              ; 6422 row 18  Inst16
    R   ___                                     ; 6424 row 19
    RI  ___, 0, 1                               ; 6425 row 20
    R   ___                                     ; 6427 row 21
    RI  C_5, 17, 0                              ; 6428 row 22  Inst16
    R   ___                                     ; 642A row 23
    RI  E_5, 17, 0                              ; 642B row 24  Inst16
    R   ___                                     ; 642D row 25
    RI  ___, 0, 1                               ; 642E row 26
    R   ___                                     ; 6430 row 27
    RI  F_5, 17, 0                              ; 6431 row 28  Inst16
    R   ___                                     ; 6433 row 29
    RI  ___, 0, 1                               ; 6434 row 30
    R   ___                                     ; 6436 row 31
Track064:
    RI  G_3, 17, 0                              ; 6437 row 00  Inst16
    R   ___                                     ; 6439 row 01
    RI  ___, 0, 1                               ; 643A row 02
    R   ___                                     ; 643C row 03
    RI  F_5, 17, 0                              ; 643D row 04  Inst16
    R   ___                                     ; 643F row 05
    RI  ___, 0, 1                               ; 6440 row 06
    R   ___                                     ; 6442 row 07
    RI  E_5, 17, 0                              ; 6443 row 08  Inst16
    R   ___                                     ; 6445 row 09
    RI  ___, 0, 1                               ; 6446 row 10
    R   ___                                     ; 6448 row 11
    RI  F_5, 17, 0                              ; 6449 row 12  Inst16
    R   ___                                     ; 644B row 13
    RI  G_5, 17, 0                              ; 644C row 14  Inst16
    R   ___                                     ; 644E row 15
    RI  ___, 0, 1                               ; 644F row 16
    R   ___                                     ; 6451 row 17
    RI  G_5, 17, 0                              ; 6452 row 18  Inst16
    R   ___                                     ; 6454 row 19
    RI  ___, 0, 1                               ; 6455 row 20
    R   ___                                     ; 6457 row 21
    RI  G_5, 17, 0                              ; 6458 row 22  Inst16
    R   ___                                     ; 645A row 23
    RI  D_5, 17, 0                              ; 645B row 24  Inst16
    R   ___                                     ; 645D row 25
    RI  ___, 0, 1                               ; 645E row 26
    R   ___                                     ; 6460 row 27
    RI  C_5, 17, 0                              ; 6461 row 28  Inst16
    R   ___                                     ; 6463 row 29
    RI  ___, 0, 1                               ; 6464 row 30
    R   ___                                     ; 6466 row 31
Track065:
    RI  F_2, 8, 0                               ; 6467 row 00  Inst07
    R   ___                                     ; 6469 row 01
    R   ___                                     ; 646A row 02
    RI  ___, 0, 0                               ; 646B row 03
    R   ___                                     ; 646D row 04
    R   ___                                     ; 646E row 05
    RI  F_2, 8, 0                               ; 646F row 06  Inst07
    R   ___                                     ; 6471 row 07
    R   ___                                     ; 6472 row 08
    RI  ___, 0, 0                               ; 6473 row 09
    RI  F_2, 8, 0                               ; 6475 row 10  Inst07
    R   ___                                     ; 6477 row 11
    R   ___                                     ; 6478 row 12
    RI  ___, 0, 0                               ; 6479 row 13
    RI  F_2, 8, 0                               ; 647B row 14  Inst07
    R   ___                                     ; 647D row 15
    R   ___                                     ; 647E row 16
    R   ___                                     ; 647F row 17
    RI  ___, 0, 0                               ; 6480 row 18
    R   ___                                     ; 6482 row 19
    R   ___                                     ; 6483 row 20
    R   ___                                     ; 6484 row 21
    RI  C_3, 8, 0                               ; 6485 row 22  Inst07
    R   ___                                     ; 6487 row 23
    RI  D_3, 8, 0                               ; 6488 row 24  Inst07
    R   ___                                     ; 648A row 25
    RI  ___, 0, 0                               ; 648B row 26
    R   ___                                     ; 648D row 27
    RI  E_3, 8, 0                               ; 648E row 28  Inst07
    R   ___                                     ; 6490 row 29
    RI  ___, 0, 0                               ; 6491 row 30
    R   ___                                     ; 6493 row 31
Track066:
    RI  C_3, 2, 0                               ; 6494 row 00  Inst01
    R   ___                                     ; 6496 row 01
    R   ___                                     ; 6497 row 02
    R   ___                                     ; 6498 row 03
    R   ___                                     ; 6499 row 04
    R   ___                                     ; 649A row 05
    RI  C_3, 2, 0                               ; 649B row 06  Inst01
    R   ___                                     ; 649D row 07
    R   ___                                     ; 649E row 08
    R   ___                                     ; 649F row 09
    RI  C_3, 2, 0                               ; 64A0 row 10  Inst01
    R   ___                                     ; 64A2 row 11
    R   ___                                     ; 64A3 row 12
    R   ___                                     ; 64A4 row 13
    RI  C_3, 2, 0                               ; 64A5 row 14  Inst01
    R   ___                                     ; 64A7 row 15
    R   ___                                     ; 64A8 row 16
    R   ___                                     ; 64A9 row 17
    R   ___                                     ; 64AA row 18
    R   ___                                     ; 64AB row 19
    R   ___                                     ; 64AC row 20
    R   ___                                     ; 64AD row 21
    RI  C_3, 2, 0                               ; 64AE row 22  Inst01
    R   ___                                     ; 64B0 row 23
    RI  C_3, 4, 0                               ; 64B1 row 24  Inst03
    R   ___                                     ; 64B3 row 25
    R   ___                                     ; 64B4 row 26
    R   ___                                     ; 64B5 row 27
    RI  C_3, 4, 0                               ; 64B6 row 28  Inst03
    R   ___                                     ; 64B8 row 29
    R   ___                                     ; 64B9 row 30
    R   ___                                     ; 64BA row 31
Track067:
    RI  C_3, 25, 0                              ; 64BB row 00  Inst24
    R   ___                                     ; 64BD row 01
    R   ___                                     ; 64BE row 02
    R   ___                                     ; 64BF row 03
    R   ___                                     ; 64C0 row 04
    R   ___                                     ; 64C1 row 05
    RI  C_3, 25, 0                              ; 64C2 row 06  Inst24
    R   ___                                     ; 64C4 row 07
    R   ___                                     ; 64C5 row 08
    R   ___                                     ; 64C6 row 09
    RI  C_3, 25, 0                              ; 64C7 row 10  Inst24
    R   ___                                     ; 64C9 row 11
    R   ___                                     ; 64CA row 12
    R   ___                                     ; 64CB row 13
    RI  C_3, 25, 0                              ; 64CC row 14  Inst24
    R   ___                                     ; 64CE row 15
    R   ___                                     ; 64CF row 16
    R   ___                                     ; 64D0 row 17
    R   ___                                     ; 64D1 row 18
    R   ___                                     ; 64D2 row 19
    R   ___                                     ; 64D3 row 20
    R   ___                                     ; 64D4 row 21
    RI  F_2, 25, 0                              ; 64D5 row 22  Inst24
    R   ___                                     ; 64D7 row 23
    RI  G_2, 25, 0                              ; 64D8 row 24  Inst24
    R   ___                                     ; 64DA row 25
    R   ___                                     ; 64DB row 26
    R   ___                                     ; 64DC row 27
    RI  C_3, 23, 0                              ; 64DD row 28  Inst22
    R   ___                                     ; 64DF row 29
    R   ___                                     ; 64E0 row 30
    R   ___                                     ; 64E1 row 31
Track068:
    RI  F_4, 13, 0                              ; 64E2 row 00  Inst12
    R   ___                                     ; 64E4 row 01
    R   ___                                     ; 64E5 row 02
    R   ___                                     ; 64E6 row 03
    R   ___                                     ; 64E7 row 04
    R   ___                                     ; 64E8 row 05
    RI  F_4, 13, 0                              ; 64E9 row 06  Inst12
    R   ___                                     ; 64EB row 07
    R   ___                                     ; 64EC row 08
    R   ___                                     ; 64ED row 09
    RI  F_4, 13, 0                              ; 64EE row 10  Inst12
    R   ___                                     ; 64F0 row 11
    R   ___                                     ; 64F1 row 12
    R   ___                                     ; 64F2 row 13
    RI  F_4, 13, 0                              ; 64F3 row 14  Inst12
    R   ___                                     ; 64F5 row 15
    R   ___                                     ; 64F6 row 16
    R   ___                                     ; 64F7 row 17
    R   ___                                     ; 64F8 row 18
    R   ___                                     ; 64F9 row 19
    R   ___                                     ; 64FA row 20
    R   ___                                     ; 64FB row 21
    RI  C_3, 13, 0                              ; 64FC row 22  Inst12
    R   ___                                     ; 64FE row 23
    RI  C_4, 13, 0                              ; 64FF row 24  Inst12
    R   ___                                     ; 6501 row 25
    R   ___                                     ; 6502 row 26
    R   ___                                     ; 6503 row 27
    RI  C_4, 13, 0                              ; 6504 row 28  Inst12
    R   ___                                     ; 6506 row 29
    R   ___                                     ; 6507 row 30
    R   ___                                     ; 6508 row 31
Track069:
    RI  C_4, 19, 0                              ; 6509 row 00  Inst18
    R   ___                                     ; 650B row 01
    R   ___                                     ; 650C row 02
    R   ___                                     ; 650D row 03
    R   ___                                     ; 650E row 04
    R   ___                                     ; 650F row 05
    RI  F_4, 19, 0                              ; 6510 row 06  Inst18
    R   ___                                     ; 6512 row 07
    R   ___                                     ; 6513 row 08
    R   ___                                     ; 6514 row 09
    R   ___                                     ; 6515 row 10
    R   ___                                     ; 6516 row 11
    R   ___                                     ; 6517 row 12
    R   ___                                     ; 6518 row 13
    R   ___                                     ; 6519 row 14
    R   ___                                     ; 651A row 15
    RI  C_4, 19, 0                              ; 651B row 16  Inst18
    R   ___                                     ; 651D row 17
    R   ___                                     ; 651E row 18
    R   ___                                     ; 651F row 19
    R   ___                                     ; 6520 row 20
    R   ___                                     ; 6521 row 21
    RI  G_4, 19, 0                              ; 6522 row 22  Inst18
    R   ___                                     ; 6524 row 23
    R   ___                                     ; 6525 row 24
    R   ___                                     ; 6526 row 25
    R   ___                                     ; 6527 row 26
    R   ___                                     ; 6528 row 27
    RI  E_4, 19, 0                              ; 6529 row 28  Inst18
    R   ___                                     ; 652B row 29
    R   ___                                     ; 652C row 30
    R   ___                                     ; 652D row 31
Track070:
    RI  C_4, 19, 0                              ; 652E row 00  Inst18
    R   ___                                     ; 6530 row 01
    R   ___                                     ; 6531 row 02
    R   ___                                     ; 6532 row 03
    R   ___                                     ; 6533 row 04
    R   ___                                     ; 6534 row 05
    RI  F_4, 19, 0                              ; 6535 row 06  Inst18
    R   ___                                     ; 6537 row 07
    R   ___                                     ; 6538 row 08
    R   ___                                     ; 6539 row 09
    R   ___                                     ; 653A row 10
    R   ___                                     ; 653B row 11
    R   ___                                     ; 653C row 12
    R   ___                                     ; 653D row 13
    R   ___                                     ; 653E row 14
    R   ___                                     ; 653F row 15
    RI  As4, 19, 0                              ; 6540 row 16  Inst18
    R   ___                                     ; 6542 row 17
    R   ___                                     ; 6543 row 18
    R   ___                                     ; 6544 row 19
    R   ___                                     ; 6545 row 20
    R   ___                                     ; 6546 row 21
    RI  A_4, 19, 0                              ; 6547 row 22  Inst18
    R   ___                                     ; 6549 row 23
    R   ___                                     ; 654A row 24
    R   ___                                     ; 654B row 25
    R   ___                                     ; 654C row 26
    R   ___                                     ; 654D row 27
    RI  G_4, 19, 0                              ; 654E row 28  Inst18
    R   ___                                     ; 6550 row 29
    R   ___                                     ; 6551 row 30
    R   ___                                     ; 6552 row 31
Track071:
    RI  F_2, 1, 0                               ; 6553 row 00  Inst00
    R   ___                                     ; 6555 row 01
    RI  ___, 0, 3                               ; 6556 row 02
    R   ___                                     ; 6558 row 03
    R   ___                                     ; 6559 row 04
    R   ___                                     ; 655A row 05
    RI  F_2, 1, 0                               ; 655B row 06  Inst00
    R   ___                                     ; 655D row 07
    RI  A_2, 1, 0                               ; 655E row 08  Inst00
    R   ___                                     ; 6560 row 09
    RI  ___, 0, 3                               ; 6561 row 10
    R   ___                                     ; 6563 row 11
    R   ___                                     ; 6564 row 12
    R   ___                                     ; 6565 row 13
    RI  As2, 1, 0                               ; 6566 row 14  Inst00
    R   ___                                     ; 6568 row 15
    R   ___                                     ; 6569 row 16
    RI  ___, 0, 3                               ; 656A row 17
    RI  As2, 1, 0                               ; 656C row 18  Inst00
    R   ___                                     ; 656E row 19
    R   ___                                     ; 656F row 20
    RI  ___, 0, 3                               ; 6570 row 21
    RI  As2, 1, 0                               ; 6572 row 22  Inst00
    R   ___                                     ; 6574 row 23
    RI  C_3, 1, 0                               ; 6575 row 24  Inst00
    R   ___                                     ; 6577 row 25
    RI  ___, 0, 3                               ; 6578 row 26
    R   ___                                     ; 657A row 27
    RI  E_3, 1, 0                               ; 657B row 28  Inst00
    R   ___                                     ; 657D row 29
    R   ___                                     ; 657E row 30
    RI  ___, 0, 3                               ; 657F row 31
Track072:
    RIF C_6, 2, 0, $F, $5                       ; 6581 row 00  Inst01  speed 5
    R   ___                                     ; 6584 row 01
    RF  ___, $F, $2                             ; 6585 row 02  speed 2
    R   ___                                     ; 6587 row 03
    RIF C_6, 3, 0, $F, $5                       ; 6588 row 04  Inst02  speed 5
    R   ___                                     ; 658B row 05
    RF  ___, $F, $2                             ; 658C row 06  speed 2
    R   ___                                     ; 658E row 07
    RIF C_6, 4, 0, $F, $5                       ; 658F row 08  Inst03  speed 5
    R   ___                                     ; 6592 row 09
    RF  ___, $F, $2                             ; 6593 row 10  speed 2
    R   ___                                     ; 6595 row 11
    RIF C_6, 3, 0, $F, $5                       ; 6596 row 12  Inst02  speed 5
    R   ___                                     ; 6599 row 13
    RIF C_3, 3, 0, $F, $2                       ; 659A row 14  Inst02  speed 2
    R   ___                                     ; 659D row 15
    RIF C_3, 2, 0, $F, $5                       ; 659E row 16  Inst01  speed 5
    R   ___                                     ; 65A1 row 17
    RIF C_6, 2, 0, $F, $2                       ; 65A2 row 18  Inst01  speed 2
    R   ___                                     ; 65A5 row 19
    RIF C_6, 3, 0, $F, $5                       ; 65A6 row 20  Inst02  speed 5
    R   ___                                     ; 65A9 row 21
    RF  ___, $F, $2                             ; 65AA row 22  speed 2
    R   ___                                     ; 65AC row 23
    RIF C_6, 4, 0, $F, $5                       ; 65AD row 24  Inst03  speed 5
    R   ___                                     ; 65B0 row 25
    RF  ___, $F, $2                             ; 65B1 row 26  speed 2
    R   ___                                     ; 65B3 row 27
    RIF C_6, 3, 0, $F, $5                       ; 65B4 row 28  Inst02  speed 5
    R   ___                                     ; 65B7 row 29
    RF  ___, $F, $2                             ; 65B8 row 30  speed 2
    R   ___                                     ; 65BA row 31
Track073:
    RI  F_2, 1, 0                               ; 65BB row 00  Inst00
    R   ___                                     ; 65BD row 01
    RI  ___, 0, 3                               ; 65BE row 02
    R   ___                                     ; 65C0 row 03
    R   ___                                     ; 65C1 row 04
    R   ___                                     ; 65C2 row 05
    RI  F_2, 1, 0                               ; 65C3 row 06  Inst00
    R   ___                                     ; 65C5 row 07
    RI  A_2, 1, 0                               ; 65C6 row 08  Inst00
    R   ___                                     ; 65C8 row 09
    RI  ___, 0, 3                               ; 65C9 row 10
    R   ___                                     ; 65CB row 11
    R   ___                                     ; 65CC row 12
    R   ___                                     ; 65CD row 13
    RI  As2, 1, 0                               ; 65CE row 14  Inst00
    R   ___                                     ; 65D0 row 15
    R   ___                                     ; 65D1 row 16
    RI  ___, 0, 3                               ; 65D2 row 17
    RI  As2, 1, 0                               ; 65D4 row 18  Inst00
    R   ___                                     ; 65D6 row 19
    R   ___                                     ; 65D7 row 20
    RI  ___, 0, 3                               ; 65D8 row 21
    RI  As2, 1, 0                               ; 65DA row 22  Inst00
    R   ___                                     ; 65DC row 23
    RI  Ds2, 1, 0                               ; 65DD row 24  Inst00
    R   ___                                     ; 65DF row 25
    RI  ___, 0, 3                               ; 65E0 row 26
    R   ___                                     ; 65E2 row 27
    RI  E_2, 1, 0                               ; 65E3 row 28  Inst00
    R   ___                                     ; 65E5 row 29
    R   ___                                     ; 65E6 row 30
    RI  ___, 0, 3                               ; 65E7 row 31
Track074:
    RIF C_6, 2, 0, $F, $5                       ; 65E9 row 00  Inst01  speed 5
    R   ___                                     ; 65EC row 01
    RF  ___, $F, $2                             ; 65ED row 02  speed 2
    R   ___                                     ; 65EF row 03
    RIF C_6, 3, 0, $F, $5                       ; 65F0 row 04  Inst02  speed 5
    R   ___                                     ; 65F3 row 05
    RF  ___, $F, $2                             ; 65F4 row 06  speed 2
    R   ___                                     ; 65F6 row 07
    RIF C_6, 4, 0, $F, $5                       ; 65F7 row 08  Inst03  speed 5
    R   ___                                     ; 65FA row 09
    RF  ___, $F, $2                             ; 65FB row 10  speed 2
    R   ___                                     ; 65FD row 11
    RIF C_6, 3, 0, $F, $5                       ; 65FE row 12  Inst02  speed 5
    R   ___                                     ; 6601 row 13
    RIF C_3, 3, 0, $F, $2                       ; 6602 row 14  Inst02  speed 2
    R   ___                                     ; 6605 row 15
    RIF C_3, 2, 0, $F, $5                       ; 6606 row 16  Inst01  speed 5
    R   ___                                     ; 6609 row 17
    RIF C_6, 2, 0, $F, $2                       ; 660A row 18  Inst01  speed 2
    R   ___                                     ; 660D row 19
    RIF C_6, 3, 0, $F, $5                       ; 660E row 20  Inst02  speed 5
    R   ___                                     ; 6611 row 21
    RF  ___, $F, $2                             ; 6612 row 22  speed 2
    R   ___                                     ; 6614 row 23
    RIF C_6, 4, 0, $F, $5                       ; 6615 row 24  Inst03  speed 5
    R   ___                                     ; 6618 row 25
    RF  ___, $F, $2                             ; 6619 row 26  speed 2
    R   ___                                     ; 661B row 27
    RI  C_6, 3, 0                               ; 661C row 28  Inst02
    R   ___                                     ; 661E row 29
    R   ___                                     ; 661F row 30
    R   ___                                     ; 6620 row 31
Track075:
    RI  F_3, 1, 0                               ; 6621 row 00  Inst00
    R   ___                                     ; 6623 row 01
    R   ___                                     ; 6624 row 02
    R   ___                                     ; 6625 row 03
    RI  D_3, 1, 0                               ; 6626 row 04  Inst00
    R   ___                                     ; 6628 row 05
    R   ___                                     ; 6629 row 06
    R   ___                                     ; 662A row 07
    RI  C_3, 1, 0                               ; 662B row 08  Inst00
    R   ___                                     ; 662D row 09
    RI  A_2, 1, 0                               ; 662E row 10  Inst00
    R   ___                                     ; 6630 row 11
    RI  C_3, 1, 0                               ; 6631 row 12  Inst00
    R   ___                                     ; 6633 row 13
    RI  F_2, 1, 0                               ; 6634 row 14  Inst00
    R   ___                                     ; 6636 row 15
    RI  ___, 0, 3                               ; 6637 row 16
    R   ___                                     ; 6639 row 17
    R   ___                                     ; 663A row 18
    R   ___                                     ; 663B row 19
    R   ___                                     ; 663C row 20
    R   ___                                     ; 663D row 21
    R   ___                                     ; 663E row 22
    R   ___                                     ; 663F row 23
    R   ___                                     ; 6640 row 24
    R   ___                                     ; 6641 row 25
    R   ___                                     ; 6642 row 26
    R   ___                                     ; 6643 row 27
    R   ___                                     ; 6644 row 28
    R   ___                                     ; 6645 row 29
    R   ___                                     ; 6646 row 30
    R   ___                                     ; 6647 row 31
Track076:
    RIF C_6, 2, 0, $F, $5                       ; 6648 row 00  Inst01  speed 5
    R   ___                                     ; 664B row 01
    RF  ___, $F, $2                             ; 664C row 02  speed 2
    R   ___                                     ; 664E row 03
    RIF C_6, 3, 0, $F, $5                       ; 664F row 04  Inst02  speed 5
    R   ___                                     ; 6652 row 05
    RF  ___, $F, $2                             ; 6653 row 06  speed 2
    R   ___                                     ; 6655 row 07
    RIF C_6, 4, 0, $F, $5                       ; 6656 row 08  Inst03  speed 5
    R   ___                                     ; 6659 row 09
    RF  ___, $F, $2                             ; 665A row 10  speed 2
    R   ___                                     ; 665C row 11
    RIF C_6, 3, 0, $F, $4                       ; 665D row 12  Inst02  speed 4
    R   ___                                     ; 6660 row 13
    RIF C_3, 4, 0, $F, $6                       ; 6661 row 14  Inst03  speed 6
    R   ___                                     ; 6664 row 15
    R   ___                                     ; 6665 row 16
    R   ___                                     ; 6666 row 17
    R   ___                                     ; 6667 row 18
    R   ___                                     ; 6668 row 19
    R   ___                                     ; 6669 row 20
    RF  ___, $F, $0                             ; 666A row 21  speed 0
    R   ___                                     ; 666C row 22
    R   ___                                     ; 666D row 23
    R   ___                                     ; 666E row 24
    R   ___                                     ; 666F row 25
    R   ___                                     ; 6670 row 26
    R   ___                                     ; 6671 row 27
    R   ___                                     ; 6672 row 28
    R   ___                                     ; 6673 row 29
    R   ___                                     ; 6674 row 30
    R   ___                                     ; 6675 row 31
Track077:
    RI  F_2, 11, 0                              ; 6676 row 00  Inst10
    R   ___                                     ; 6678 row 01
    R   ___                                     ; 6679 row 02
    R   ___                                     ; 667A row 03
    R   ___                                     ; 667B row 04
    R   ___                                     ; 667C row 05
    RI  F_2, 11, 0                              ; 667D row 06  Inst10
    R   ___                                     ; 667F row 07
    RI  A_2, 11, 0                              ; 6680 row 08  Inst10
    R   ___                                     ; 6682 row 09
    R   ___                                     ; 6683 row 10
    R   ___                                     ; 6684 row 11
    R   ___                                     ; 6685 row 12
    R   ___                                     ; 6686 row 13
    RI  As2, 11, 0                              ; 6687 row 14  Inst10
    R   ___                                     ; 6689 row 15
    R   ___                                     ; 668A row 16
    R   ___                                     ; 668B row 17
    RI  As2, 11, 0                              ; 668C row 18  Inst10
    R   ___                                     ; 668E row 19
    R   ___                                     ; 668F row 20
    R   ___                                     ; 6690 row 21
    RI  As2, 11, 0                              ; 6691 row 22  Inst10
    R   ___                                     ; 6693 row 23
    RI  Ds2, 11, 0                              ; 6694 row 24  Inst10
    R   ___                                     ; 6696 row 25
    R   ___                                     ; 6697 row 26
    R   ___                                     ; 6698 row 27
    RI  E_2, 11, 0                              ; 6699 row 28  Inst10
    R   ___                                     ; 669B row 29
    R   ___                                     ; 669C row 30
    R   ___                                     ; 669D row 31
Track078:
    RI  F_2, 11, 0                              ; 669E row 00  Inst10
    R   ___                                     ; 66A0 row 01
    R   ___                                     ; 66A1 row 02
    R   ___                                     ; 66A2 row 03
    R   ___                                     ; 66A3 row 04
    R   ___                                     ; 66A4 row 05
    RI  F_2, 11, 0                              ; 66A5 row 06  Inst10
    R   ___                                     ; 66A7 row 07
    RI  A_2, 11, 0                              ; 66A8 row 08  Inst10
    R   ___                                     ; 66AA row 09
    R   ___                                     ; 66AB row 10
    R   ___                                     ; 66AC row 11
    R   ___                                     ; 66AD row 12
    R   ___                                     ; 66AE row 13
    RI  As2, 11, 0                              ; 66AF row 14  Inst10
    R   ___                                     ; 66B1 row 15
    R   ___                                     ; 66B2 row 16
    R   ___                                     ; 66B3 row 17
    RI  As2, 11, 0                              ; 66B4 row 18  Inst10
    R   ___                                     ; 66B6 row 19
    R   ___                                     ; 66B7 row 20
    R   ___                                     ; 66B8 row 21
    RI  As2, 11, 0                              ; 66B9 row 22  Inst10
    R   ___                                     ; 66BB row 23
    RI  C_3, 11, 0                              ; 66BC row 24  Inst10
    R   ___                                     ; 66BE row 25
    R   ___                                     ; 66BF row 26
    R   ___                                     ; 66C0 row 27
    RI  E_3, 11, 0                              ; 66C1 row 28  Inst10
    R   ___                                     ; 66C3 row 29
    R   ___                                     ; 66C4 row 30
    R   ___                                     ; 66C5 row 31
Track079:
    RI  F_4, 11, 0                              ; 66C6 row 00  Inst10
    R   ___                                     ; 66C8 row 01
    R   ___                                     ; 66C9 row 02
    R   ___                                     ; 66CA row 03
    RI  D_4, 11, 0                              ; 66CB row 04  Inst10
    R   ___                                     ; 66CD row 05
    R   ___                                     ; 66CE row 06
    R   ___                                     ; 66CF row 07
    RI  C_4, 11, 0                              ; 66D0 row 08  Inst10
    R   ___                                     ; 66D2 row 09
    RI  A_3, 11, 0                              ; 66D3 row 10  Inst10
    R   ___                                     ; 66D5 row 11
    RI  C_4, 11, 0                              ; 66D6 row 12  Inst10
    R   ___                                     ; 66D8 row 13
    RI  F_3, 11, 0                              ; 66D9 row 14  Inst10
    R   ___                                     ; 66DB row 15
    R   ___                                     ; 66DC row 16
    R   ___                                     ; 66DD row 17
    R   ___                                     ; 66DE row 18
    R   ___                                     ; 66DF row 19
    R   ___                                     ; 66E0 row 20
    R   ___                                     ; 66E1 row 21
    R   ___                                     ; 66E2 row 22
    R   ___                                     ; 66E3 row 23
    R   ___                                     ; 66E4 row 24
    R   ___                                     ; 66E5 row 25
    R   ___                                     ; 66E6 row 26
    R   ___                                     ; 66E7 row 27
    R   ___                                     ; 66E8 row 28
    R   ___                                     ; 66E9 row 29
    R   ___                                     ; 66EA row 30
    R   ___                                     ; 66EB row 31
Track080:
    RI  F_2, 1, 0                               ; 66EC row 00  Inst00
    R   ___                                     ; 66EE row 01
    R   ___                                     ; 66EF row 02
    R   ___                                     ; 66F0 row 03
    RI  ___, 0, 3                               ; 66F1 row 04
    R   ___                                     ; 66F3 row 05
    RI  F_2, 1, 0                               ; 66F4 row 06  Inst00
    R   ___                                     ; 66F6 row 07
    RI  Ds2, 1, 0                               ; 66F7 row 08  Inst00
    R   ___                                     ; 66F9 row 09
    R   ___                                     ; 66FA row 10
    R   ___                                     ; 66FB row 11
    RI  ___, 0, 3                               ; 66FC row 12
    R   ___                                     ; 66FE row 13
    RI  D_2, 1, 0                               ; 66FF row 14  Inst00
    R   ___                                     ; 6701 row 15
    R   ___                                     ; 6702 row 16
    RI  ___, 0, 3                               ; 6703 row 17
    RI  D_2, 1, 0                               ; 6705 row 18  Inst00
    R   ___                                     ; 6707 row 19
    R   ___                                     ; 6708 row 20
    RI  ___, 0, 3                               ; 6709 row 21
    RI  D_2, 1, 0                               ; 670B row 22  Inst00
    RI  ___, 0, 3                               ; 670D row 23
    RI  Cs2, 1, 0                               ; 670F row 24  Inst00
    R   ___                                     ; 6711 row 25
    RI  ___, 0, 3                               ; 6712 row 26
    R   ___                                     ; 6714 row 27
    RI  Cs2, 1, 0                               ; 6715 row 28  Inst00
    R   ___                                     ; 6717 row 29
    RI  ___, 0, 3                               ; 6718 row 30
    R   ___                                     ; 671A row 31
Track081:
    RIF C_6, 2, 0, $F, $6                       ; 671B row 00  Inst01  speed 6
    R   ___                                     ; 671E row 01
    RF  ___, $F, $3                             ; 671F row 02  speed 3
    R   ___                                     ; 6721 row 03
    RIF C_6, 3, 0, $F, $6                       ; 6722 row 04  Inst02  speed 6
    R   ___                                     ; 6725 row 05
    RF  ___, $F, $3                             ; 6726 row 06  speed 3
    R   ___                                     ; 6728 row 07
    RIF C_6, 4, 0, $F, $6                       ; 6729 row 08  Inst03  speed 6
    R   ___                                     ; 672C row 09
    RF  ___, $F, $3                             ; 672D row 10  speed 3
    R   ___                                     ; 672F row 11
    RIF C_6, 3, 0, $F, $6                       ; 6730 row 12  Inst02  speed 6
    R   ___                                     ; 6733 row 13
    RIF C_3, 2, 0, $F, $3                       ; 6734 row 14  Inst01  speed 3
    R   ___                                     ; 6737 row 15
    RIF C_3, 3, 0, $F, $6                       ; 6738 row 16  Inst02  speed 6
    R   ___                                     ; 673B row 17
    RIF C_6, 2, 0, $F, $3                       ; 673C row 18  Inst01  speed 3
    R   ___                                     ; 673F row 19
    RIF C_6, 3, 0, $F, $6                       ; 6740 row 20  Inst02  speed 6
    R   ___                                     ; 6743 row 21
    RF  ___, $F, $3                             ; 6744 row 22  speed 3
    R   ___                                     ; 6746 row 23
    RIF C_6, 4, 0, $F, $6                       ; 6747 row 24  Inst03  speed 6
    R   ___                                     ; 674A row 25
    RF  ___, $F, $3                             ; 674B row 26  speed 3
    R   ___                                     ; 674D row 27
    RIF C_6, 3, 0, $F, $6                       ; 674E row 28  Inst02  speed 6
    R   ___                                     ; 6751 row 29
    RF  ___, $F, $3                             ; 6752 row 30  speed 3
    R   ___                                     ; 6754 row 31
Track082:
    RI  C_2, 1, 0                               ; 6755 row 00  Inst00
    R   ___                                     ; 6757 row 01
    RI  ___, 0, 1                               ; 6758 row 02
    R   ___                                     ; 675A row 03
    RI  ___, 0, 2                               ; 675B row 04
    R   ___                                     ; 675D row 05
    RI  ___, 0, 3                               ; 675E row 06
    R   ___                                     ; 6760 row 07
    RI  ___, 0, 3                               ; 6761 row 08
    R   ___                                     ; 6763 row 09
    R   ___                                     ; 6764 row 10
    R   ___                                     ; 6765 row 11
    R   ___                                     ; 6766 row 12
    R   ___                                     ; 6767 row 13
    R   ___                                     ; 6768 row 14
    R   ___                                     ; 6769 row 15
    R   ___                                     ; 676A row 16
    R   ___                                     ; 676B row 17
    R   ___                                     ; 676C row 18
    R   ___                                     ; 676D row 19
    R   ___                                     ; 676E row 20
    R   ___                                     ; 676F row 21
    R   ___                                     ; 6770 row 22
    R   ___                                     ; 6771 row 23
    R   ___                                     ; 6772 row 24
    R   ___                                     ; 6773 row 25
    R   ___                                     ; 6774 row 26
    R   ___                                     ; 6775 row 27
    R   ___                                     ; 6776 row 28
    R   ___                                     ; 6777 row 29
    R   ___                                     ; 6778 row 30
    R   ___                                     ; 6779 row 31
Track083:
    RIF C_3, 4, 0, $F, $6                       ; 677A row 00  Inst03  speed 6
    R   ___                                     ; 677D row 01
    R   ___                                     ; 677E row 02
    R   ___                                     ; 677F row 03
    R   ___                                     ; 6780 row 04
    R   ___                                     ; 6781 row 05
    R   ___                                     ; 6782 row 06
    R   ___                                     ; 6783 row 07
    R   ___                                     ; 6784 row 08
    R   ___                                     ; 6785 row 09
    RF  ___, $F, $0                             ; 6786 row 10  speed 0
    R   ___                                     ; 6788 row 11
    R   ___                                     ; 6789 row 12
    R   ___                                     ; 678A row 13
    R   ___                                     ; 678B row 14
    R   ___                                     ; 678C row 15
    R   ___                                     ; 678D row 16
    R   ___                                     ; 678E row 17
    R   ___                                     ; 678F row 18
    R   ___                                     ; 6790 row 19
    R   ___                                     ; 6791 row 20
    R   ___                                     ; 6792 row 21
    R   ___                                     ; 6793 row 22
    R   ___                                     ; 6794 row 23
    R   ___                                     ; 6795 row 24
    R   ___                                     ; 6796 row 25
    R   ___                                     ; 6797 row 26
    R   ___                                     ; 6798 row 27
    R   ___                                     ; 6799 row 28
    R   ___                                     ; 679A row 29
    R   ___                                     ; 679B row 30
    R   ___                                     ; 679C row 31

;; Wave-RAM source data for Inst05, Inst07, Inst08. 16 bytes at base+position are copied
;; to $FF30-$FF3F (4-bit samples, high nibble first); positions used: $00-$1E. The window can reach 14 bytes past this block (into SFXInstTable).
WaveData00:
    db $88, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00; 679D 
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF; 67AD 
SFXInstTable:
    dw SFXInst00                                 ; 67BD  SFX instrument 1 (ch3)
    dw SFXInst01                                 ; 67BF  SFX instrument 2 (ch3)
    dw SFXInst02                                 ; 67C1  SFX instrument 3 (ch3)
    dw SFXInst03                                 ; 67C3  SFX instrument 4 (ch3)
    dw SFXInst04                                 ; 67C5  SFX instrument 5 (ch4)
    dw SFXInst05                                 ; 67C7  SFX instrument 6 (ch4)
    dw SFXInst06                                 ; 67C9  SFX instrument 7 (ch4)
    dw SFXInst07                                 ; 67CB  SFX instrument 8 (ch3)
    dw SFXInst08                                 ; 67CD  SFX instrument 9 (ch3)
    dw SFXInst09                                 ; 67CF  SFX instrument 10 (unused)
    dw SFXInst10                                 ; 67D1  SFX instrument 11 (ch3)
    dw SFXInst11                                 ; 67D3  SFX instrument 12 (ch3)
    dw SFXInst12                                 ; 67D5  SFX instrument 13 (ch3)
    dw SFXInst13                                 ; 67D7  SFX instrument 14 (ch3)
    dw SFXInst14                                 ; 67D9  SFX instrument 15 (ch3)
    dw SFXInst15                                 ; 67DB  SFX instrument 16 (ch3)
    dw SFXInst16                                 ; 67DD  SFX instrument 17 (ch3)
    dw SFXInst17                                 ; 67DF  SFX instrument 18 (ch3)
    dw SFXInst18                                 ; 67E1  SFX instrument 19 (ch3)
    dw SFXInst19                                 ; 67E3  SFX instrument 20 (unused)
    dw SFXInst19                                 ; 67E5  SFX instrument 21 (ch3)
    dw SFXInst21                                 ; 67E7  SFX instrument 22 (ch3)
    dw SFXInst22                                 ; 67E9  SFX instrument 23 (ch3)
    dw SFXInst23                                 ; 67EB  SFX instrument 24 (ch3)
    dw SFXInst24                                 ; 67ED  SFX instrument 25 (ch3)
    dw SFXInst25                                 ; 67EF  SFX instrument 26 (ch3)
    dw SFXInst26                                 ; 67F1  SFX instrument 27 (ch3)
    dw SFXInst27                                 ; 67F3  SFX instrument 28 (ch3)
    dw SFXInst28                                 ; 67F5  SFX instrument 29 (ch3)
    dw SFXInst29                                 ; 67F7  SFX instrument 30 (ch3)
    dw SFXInst30                                 ; 67F9  SFX instrument 31 (ch3)
    dw SFXInst31                                 ; 67FB  SFX instrument 32 (ch3)
    dw SFXInst32                                 ; 67FD  SFX instrument 33 (ch3)
    dw SFXInst33                                 ; 67FF  SFX instrument 34 (ch3)
    dw SFXInst34                                 ; 6801  SFX instrument 35 (ch3)
    dw SFXInst35                                 ; 6803  SFX instrument 36 (ch3)
    dw SFXInst36                                 ; 6805  SFX instrument 37 (ch3)
    dw SFXInst37                                 ; 6807  SFX instrument 38 (ch3)
    dw SFXInst38                                 ; 6809  SFX instrument 39 (ch3)
    dw SFXInst39                                 ; 680B  SFX instrument 40 (ch3)
    dw SFXInst40                                 ; 680D  SFX instrument 41 (ch3)
    dw SFXInst41                                 ; 680F  SFX instrument 42 (ch3)
    dw SFXInst42                                 ; 6811  SFX instrument 43 (ch3)
    dw SFXInst43                                 ; 6813  SFX instrument 44 (ch3)
    dw SFXInst44                                 ; 6815  SFX instrument 45 (ch3)
    dw SFXInst45                                 ; 6817  SFX instrument 46 (ch3)
SFXInst00:
    db $05                                       ; 6819 wave, 5 steps
    db $01                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0000, $001E                       ; position, lower bound, upper bound
    db $01                                       ; sweep speed
    db LOW(WaveData01), HIGH(WaveData01)         ; wave data base
    db $71, $00, $42                             ; step 0: C-6  level 2
    db $65, $00, $00                             ; step 1: C-5
    db $40, $00, $42                             ; step 2: -  level 2
    db $40, $00, $41                             ; step 3: -  level 1
    db $40, $00, $40                             ; step 4: -  level 0
SFXInst01:
    db $05                                       ; 6836 wave, 5 steps
    db $01                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0000, $001E                       ; position, lower bound, upper bound
    db $01                                       ; sweep speed
    db LOW(WaveData01), HIGH(WaveData01)         ; wave data base
    db $71, $00, $42                             ; step 0: C-6  level 2
    db $65, $00, $00                             ; step 1: C-5
    db $40, $00, $42                             ; step 2: -  level 2
    db $40, $00, $41                             ; step 3: -  level 1
    db $40, $00, $40                             ; step 4: -  level 0
SFXInst02:
    db $05                                       ; 6853 wave, 5 steps
    db $01                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0000, $001E                       ; position, lower bound, upper bound
    db $01                                       ; sweep speed
    db LOW(WaveData01), HIGH(WaveData01)         ; wave data base
    db $71, $00, $43                             ; step 0: C-6  level 3
    db $65, $00, $42                             ; step 1: C-5  level 2
    db $40, $00, $42                             ; step 2: -  level 2
    db $40, $00, $41                             ; step 3: -  level 1
    db $40, $00, $40                             ; step 4: -  level 0
SFXInst03:
    db $05                                       ; 6870 wave, 5 steps
    db $01                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0000, $001E                       ; position, lower bound, upper bound
    db $01                                       ; sweep speed
    db LOW(WaveData01), HIGH(WaveData01)         ; wave data base
    db $71, $00, $00                             ; step 0: C-6
    db $65, $00, $00                             ; step 1: C-5
    db $40, $00, $42                             ; step 2: -  level 2
    db $40, $00, $41                             ; step 3: -  level 1
    db $40, $00, $40                             ; step 4: -  level 0
SFXInst04:
    db $03                                       ; 688D noise, 3 steps
    db $01                                       ; playlist speed
    db $C0                                       ; NR42 envelope
    db $71, $00, $00                             ; step 0: C-6
    db $40, $00, $40                             ; step 1: -  vol 0
    db $40, $00, $00                             ; step 2: -
SFXInst05:
    db $02                                       ; 6899 noise, 2 steps
    db $01                                       ; playlist speed
    db $41                                       ; NR42 envelope
    db $65, $00, $00                             ; step 0: C-5
    db $40, $00, $00                             ; step 1: -
SFXInst06:
    db $02                                       ; 68A2 noise, 2 steps
    db $02                                       ; playlist speed
    db $71                                       ; NR42 envelope
    db $6A, $00, $00                             ; step 0: F-5
    db $40, $00, $40                             ; step 1: -  vol 0
SFXInst07:
    db $05                                       ; 68AB wave, 5 steps
    db $01                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0000, $001E                       ; position, lower bound, upper bound
    db $01                                       ; sweep speed
    db LOW(WaveData01), HIGH(WaveData01)         ; wave data base
    db $69, $00, $43                             ; step 0: E-5  level 3
    db $5D, $00, $42                             ; step 1: E-4  level 2
    db $40, $00, $42                             ; step 2: -  level 2
    db $40, $00, $41                             ; step 3: -  level 1
    db $40, $00, $40                             ; step 4: -  level 0
SFXInst08:
    db $05                                       ; 68C8 wave, 5 steps
    db $01                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0000, $001E                       ; position, lower bound, upper bound
    db $01                                       ; sweep speed
    db LOW(WaveData01), HIGH(WaveData01)         ; wave data base
    db $69, $00, $43                             ; step 0: E-5  level 3
    db $5D, $00, $00                             ; step 1: E-4
    db $40, $00, $42                             ; step 2: -  level 2
    db $40, $00, $41                             ; step 3: -  level 1
    db $40, $00, $40                             ; step 4: -  level 0
SFXInst09:
    db $05                                       ; 68E5 wave, 5 steps
    db $01                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0000, $001E                       ; position, lower bound, upper bound
    db $01                                       ; sweep speed
    db LOW(WaveData01), HIGH(WaveData01)         ; wave data base
    db $69, $00, $43                             ; step 0: E-5  level 3
    db $5D, $00, $00                             ; step 1: E-4
    db $40, $00, $43                             ; step 2: -  level 3
    db $40, $00, $40                             ; step 3: -  level 0
    db $40, $00, $00                             ; step 4: -
SFXInst10:
    db $06                                       ; 6902 wave, 6 steps
    db $01                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0000, $001E                       ; position, lower bound, upper bound
    db $01                                       ; sweep speed
    db LOW(WaveData01), HIGH(WaveData01)         ; wave data base
    db $69, $00, $00                             ; step 0: E-5
    db $5D, $00, $00                             ; step 1: E-4
    db $69, $00, $00                             ; step 2: E-5
    db $40, $00, $42                             ; step 3: -  level 2
    db $40, $00, $41                             ; step 4: -  level 1
    db $40, $00, $40                             ; step 5: -  level 0
SFXInst11:
    db $05                                       ; 6922 wave, 5 steps
    db $01                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0000, $001E                       ; position, lower bound, upper bound
    db $01                                       ; sweep speed
    db LOW(WaveData01), HIGH(WaveData01)         ; wave data base
    db $65, $00, $00                             ; step 0: C-5
    db $6A, $00, $00                             ; step 1: F-5
    db $6E, $00, $00                             ; step 2: A-5
    db $71, $00, $00                             ; step 3: C-6
    db $40, $00, $40                             ; step 4: -  level 0
SFXInst12:
    db $09                                       ; 693F wave, 9 steps
    db $01                                       ; playlist speed
    db $20                                       ; NR32 level
    db $01, $00                                  ; sweep step, flag byte (stored, not used)
    dw $0008, $0000, $001E                       ; position, lower bound, upper bound
    db $01                                       ; sweep speed
    db LOW(WaveData01), HIGH(WaveData01)         ; wave data base
    db $65, $00, $00                             ; step 0: C-5
    db $71, $00, $00                             ; step 1: C-6
    db $6C, $00, $00                             ; step 2: G-5
    db $78, $00, $00                             ; step 3: G-6
    db $65, $00, $00                             ; step 4: C-5
    db $71, $00, $42                             ; step 5: C-6  level 2
    db $6C, $00, $00                             ; step 6: G-5
    db $78, $00, $00                             ; step 7: G-6
    db $40, $00, $40                             ; step 8: -  level 0
SFXInst13:
    db $C0                                       ; 6968 PCM sample, rate 3
    db BANK(PCM00)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM00                                     ; sample
    dw 768                                       ; length in 16-byte blocks
SFXInst14:
    db $80                                       ; 696E PCM sample, rate 2
    db BANK(PCM01)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM01                                     ; sample
    dw 173                                       ; length in 16-byte blocks
SFXInst15:
    db $80                                       ; 6974 PCM sample, rate 2
    db BANK(PCM02)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM02                                     ; sample
    dw 132                                       ; length in 16-byte blocks
SFXInst16:
    db $80                                       ; 697A PCM sample, rate 2
    db BANK(PCM03)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM03                                     ; sample
    dw 141                                       ; length in 16-byte blocks
SFXInst17:
    db $80                                       ; 6980 PCM sample, rate 2
    db BANK(PCM04)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM04                                     ; sample
    dw 170                                       ; length in 16-byte blocks
SFXInst18:
    db $80                                       ; 6986 PCM sample, rate 2
    db BANK(PCM05)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM05                                     ; sample
    dw 142                                       ; length in 16-byte blocks
SFXInst19:
SFXInst20:
    db $80                                       ; 698C PCM sample, rate 2
    db BANK(PCM06)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM06                                     ; sample
    dw 106                                       ; length in 16-byte blocks
SFXInst21:
    db $80                                       ; 6992 PCM sample, rate 2
    db BANK(PCM07)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM07                                     ; sample
    dw 123                                       ; length in 16-byte blocks
SFXInst22:
    db $80                                       ; 6998 PCM sample, rate 2
    db BANK(PCM08)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM08                                     ; sample
    dw 103                                       ; length in 16-byte blocks
SFXInst23:
    db $80                                       ; 699E PCM sample, rate 2
    db BANK(PCM09)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM09                                     ; sample
    dw 110                                       ; length in 16-byte blocks
SFXInst24:
    db $80                                       ; 69A4 PCM sample, rate 2
    db BANK(PCM10)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM10                                     ; sample
    dw 144                                       ; length in 16-byte blocks
SFXInst25:
    db $80                                       ; 69AA PCM sample, rate 2
    db BANK(PCM11)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM11                                     ; sample
    dw 108                                       ; length in 16-byte blocks
SFXInst26:
    db $80                                       ; 69B0 PCM sample, rate 2
    db BANK(PCM12)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM12                                     ; sample
    dw 131                                       ; length in 16-byte blocks
SFXInst27:
    db $80                                       ; 69B6 PCM sample, rate 2
    db BANK(PCM13)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM13                                     ; sample
    dw 157                                       ; length in 16-byte blocks
SFXInst28:
    db $80                                       ; 69BC PCM sample, rate 2
    db BANK(PCM14)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM14                                     ; sample
    dw 222                                       ; length in 16-byte blocks
SFXInst29:
    db $80                                       ; 69C2 PCM sample, rate 2
    db BANK(PCM15)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM15                                     ; sample
    dw 212                                       ; length in 16-byte blocks
SFXInst30:
    db $80                                       ; 69C8 PCM sample, rate 2
    db BANK(PCM16)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM16                                     ; sample
    dw 168                                       ; length in 16-byte blocks
SFXInst31:
    db $80                                       ; 69CE PCM sample, rate 2
    db BANK(PCM17)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM17                                     ; sample
    dw 124                                       ; length in 16-byte blocks
SFXInst32:
    db $80                                       ; 69D4 PCM sample, rate 2
    db BANK(PCM18)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM18                                     ; sample
    dw 234                                       ; length in 16-byte blocks
SFXInst33:
    db $80                                       ; 69DA PCM sample, rate 2
    db BANK(PCM19)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM19                                     ; sample
    dw 299                                       ; length in 16-byte blocks
SFXInst34:
    db $80                                       ; 69E0 PCM sample, rate 2
    db BANK(PCM20)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM20                                     ; sample
    dw 189                                       ; length in 16-byte blocks
SFXInst35:
    db $80                                       ; 69E6 PCM sample, rate 2
    db BANK(PCM21)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM21                                     ; sample
    dw 164                                       ; length in 16-byte blocks
SFXInst36:
    db $80                                       ; 69EC PCM sample, rate 2
    db BANK(PCM22)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM22                                     ; sample
    dw 126                                       ; length in 16-byte blocks
SFXInst37:
    db $80                                       ; 69F2 PCM sample, rate 2
    db BANK(PCM23)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM23                                     ; sample
    dw 131                                       ; length in 16-byte blocks
SFXInst38:
    db $80                                       ; 69F8 PCM sample, rate 2
    db BANK(PCM24)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM24                                     ; sample
    dw 226                                       ; length in 16-byte blocks
SFXInst39:
    db $80                                       ; 69FE PCM sample, rate 2
    db BANK(PCM25)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM25                                     ; sample
    dw 215                                       ; length in 16-byte blocks
SFXInst40:
    db $80                                       ; 6A04 PCM sample, rate 2
    db BANK(PCM26)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM26                                     ; sample
    dw 178                                       ; length in 16-byte blocks
SFXInst41:
    db $80                                       ; 6A0A PCM sample, rate 2
    db BANK(PCM27)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM27                                     ; sample
    dw 89                                        ; length in 16-byte blocks
SFXInst42:
    db $80                                       ; 6A10 PCM sample, rate 2
    db BANK(PCM28)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM28                                     ; sample
    dw 117                                       ; length in 16-byte blocks
SFXInst43:
    db $80                                       ; 6A16 PCM sample, rate 2
    db BANK(PCM29)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM29                                     ; sample
    dw 134                                       ; length in 16-byte blocks
SFXInst44:
    db $80                                       ; 6A1C PCM sample, rate 2
    db BANK(PCM30)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM30                                     ; sample
    dw 106                                       ; length in 16-byte blocks
SFXInst45:
    db $80                                       ; 6A22 PCM sample, rate 2
    db BANK(PCM31)-$10                           ; bank (relative to the PCM base bank $10)
    dw PCM31                                     ; sample
    dw 189                                       ; length in 16-byte blocks

;; Wave-RAM source data for SFXInst00, SFXInst01, SFXInst02, SFXInst03, SFXInst07, SFXInst08, SFXInst09, SFXInst10, SFXInst11, SFXInst12. 16 bytes at base+position are copied
;; to $FF30-$FF3F (4-bit samples, high nibble first); positions used: $00-$1E. The window can reach 14 bytes past this block (into SFXTable).
WaveData01:
    db $88, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00; 6A28 
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF; 6A38 

;; Sound effects, 5 bytes: [ins ch1] [ins ch2] [ins ch3] [ins ch4] [mute time in ticks].
;; Instrument numbers are 1-based indices into SFXInstTable (0 = channel not used);
;; the music on the used channels is muted for "time" ticks ($FF on ch3 = until the next song).
SFXTable:
    db 0, 0, 1, 6, $04                           ; 6A48 SFX 0
    db 0, 0, 2, 7, $04                           ; 6A4D SFX 1
    db 0, 0, 3, 7, $04                           ; 6A52 SFX 2
    db 0, 0, 4, 5, $04                           ; 6A57 SFX 3
    db 0, 0, 8, 6, $04                           ; 6A5C SFX 4
    db 0, 0, 8, 7, $04                           ; 6A61 SFX 5
    db 0, 0, 9, 7, $04                           ; 6A66 SFX 6
    db 0, 0, 11, 7, $04                          ; 6A6B SFX 7
    db 0, 0, 12, 0, $06                          ; 6A70 SFX 8
    db 0, 0, 13, 0, $08                          ; 6A75 SFX 9
    db 0, 0, 14, 0, $01                          ; 6A7A SFX 10
    db 0, 0, 15, 0, $01                          ; 6A7F SFX 11
    db 0, 0, 16, 0, $01                          ; 6A84 SFX 12
    db 0, 0, 17, 0, $01                          ; 6A89 SFX 13
    db 0, 0, 18, 0, $01                          ; 6A8E SFX 14
    db 0, 0, 19, 0, $01                          ; 6A93 SFX 15
    db 0, 0, 21, 0, $01                          ; 6A98 SFX 16
    db 0, 0, 22, 0, $01                          ; 6A9D SFX 17
    db 0, 0, 23, 0, $01                          ; 6AA2 SFX 18
    db 0, 0, 24, 0, $01                          ; 6AA7 SFX 19
    db 0, 0, 25, 0, $01                          ; 6AAC SFX 20
    db 0, 0, 26, 0, $01                          ; 6AB1 SFX 21
    db 0, 0, 27, 0, $01                          ; 6AB6 SFX 22
    db 0, 0, 28, 0, $01                          ; 6ABB SFX 23
    db 0, 0, 29, 0, $01                          ; 6AC0 SFX 24
    db 0, 0, 30, 0, $01                          ; 6AC5 SFX 25
    db 0, 0, 31, 0, $01                          ; 6ACA SFX 26
    db 0, 0, 32, 0, $01                          ; 6ACF SFX 27
    db 0, 0, 33, 0, $01                          ; 6AD4 SFX 28
    db 0, 0, 34, 0, $01                          ; 6AD9 SFX 29
    db 0, 0, 35, 0, $01                          ; 6ADE SFX 30
    db 0, 0, 36, 0, $01                          ; 6AE3 SFX 31
    db 0, 0, 37, 0, $01                          ; 6AE8 SFX 32
    db 0, 0, 38, 0, $01                          ; 6AED SFX 33
    db 0, 0, 39, 0, $01                          ; 6AF2 SFX 34
    db 0, 0, 40, 0, $01                          ; 6AF7 SFX 35
    db 0, 0, 41, 0, $01                          ; 6AFC SFX 36
    db 0, 0, 42, 0, $01                          ; 6B01 SFX 37
    db 0, 0, 43, 0, $01                          ; 6B06 SFX 38
    db 0, 0, 44, 0, $01                          ; 6B0B SFX 39
    db 0, 0, 45, 0, $01                          ; 6B10 SFX 40
    db 0, 0, 46, 0, $01                          ; 6B15 SFX 41
    ds 5350, $DA                ; 6B1A  (fill)

; ============================================================================
SECTION "GHX PCM samples bank $11", ROMX[$4000], BANK[$11]
; ============================================================================

;; PCM00: 12288 bytes = 24576 4-bit samples (rate 3) for SFXInst13
PCM00:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:4000
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:4010
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:4020
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:4030
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:4040
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:4050
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:4060
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:4070
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:4080
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:4090
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $99, $99; 11:40A0
    db $98, $88, $87, $76, $66, $55, $54, $44, $55, $55, $55, $66, $66, $66, $77, $77; 11:40B0
    db $88, $88, $99, $9A, $AA, $AA, $AA, $99, $98, $88, $87, $77, $76, $66, $66, $66; 11:40C0
    db $77, $77, $78, $88, $88, $99, $99, $9A, $AA, $A9, $99, $99, $99, $88, $88, $88; 11:40D0
    db $88, $88, $89, $99, $99, $99, $99, $AA, $AA, $AB, $BB, $BB, $BB, $A9, $77, $65; 11:40E0
    db $31, $00, $00, $00, $00, $12, $23, $44, $44, $55, $66, $67, $78, $9A, $BC, $CD; 11:40F0
    db $DE, $DD, $CB, $B9, $87, $76, $65, $55, $56, $66, $66, $66, $66, $66, $66, $67; 11:4100
    db $78, $89, $9A, $BB, $BB, $BA, $AA, $98, $87, $77, $77, $77, $78, $88, $88, $88; 11:4110
    db $88, $88, $89, $9A, $AB, $BC, $CC, $CC, $CB, $BA, $A9, $99, $99, $9A, $AB, $BB; 11:4120
    db $CD, $CA, $75, $43, $20, $00, $00, $00, $01, $23, $45, $56, $65, $43, $46, $88; 11:4130
    db $9A, $BD, $FF, $FF, $EC, $B9, $75, $43, $20, $12, $45, $55, $56, $77, $76, $55; 11:4140
    db $56, $67, $9B, $CC, $EF, $FF, $ED, $B9, $88, $75, $44, $45, $66, $67, $76, $66; 11:4150
    db $66, $66, $67, $8A, $CD, $DE, $FF, $FE, $DC, $BA, $AA, $99, $AA, $AA, $BB, $CB; 11:4160
    db $BB, $CD, $EE, $A4, $12, $42, $00, $00, $00, $02, $32, $33, $33, $46, $64, $35; 11:4170
    db $BF, $FE, $EE, $FF, $EC, $96, $33, $21, $13, $54, $21, $57, $75, $32, $23, $68; 11:4180
    db $88, $AD, $FF, $FF, $FF, $CA, $99, $87, $64, $34, $68, $63, $22, $32, $12, $34; 11:4190
    db $56, $9B, $EF, $FF, $DD, $EE, $C9, $89, $BB, $CC, $CC, $BB, $B9, $98, $97, $78; 11:41A0
    db $BF, $FF, $FF, $E5, $00, $10, $00, $00, $02, $58, $75, $23, $21, $03, $44, $5B; 11:41B0
    db $FF, $FF, $FF, $DA, $74, $00, $00, $34, $57, $95, $10, $12, $10, $01, $5A, $FF; 11:41C0
    db $FF, $FF, $FD, $98, $75, $34, $8A, $99, $75, $20, $10, $00, $02, $79, $BE, $FF; 11:41D0
    db $FE, $EC, $A9, $99, $9B, $FF, $EB, $AA, $97, $55, $55, $8B, $DD, $EF, $FF, $FF; 11:41E0
    db $FF, $A0, $00, $22, $00, $00, $05, $43, $00, $00, $03, $6C, $DD, $BF, $FF, $FC; 11:41F0
    db $76, $67, $65, $00, $15, $52, $01, $00, $00, $48, $88, $BD, $FF, $FF, $C8, $AE; 11:4200
    db $EA, $99, $86, $66, $62, $00, $00, $01, $53, $25, $CF, $FF, $DC, $BD, $FF, $ED; 11:4210
    db $DD, $CB, $BB, $84, $23, $69, $A9, $99, $BE, $FD, $CB, $EF, $FF, $FF, $80, $01; 11:4220
    db $10, $00, $00, $14, $54, $10, $34, $66, $AB, $BD, $FF, $FF, $DA, $98, $73, $00; 11:4230
    db $00, $45, $10, $10, $00, $36, $55, $9E, $FF, $FF, $FC, $EF, $E8, $43, $34, $67; 11:4240
    db $41, $00, $00, $00, $00, $28, $FF, $FE, $DD, $EF, $FB, $99, $BD, $ED, $B8, $54; 11:4250
    db $57, $77, $66, $9C, $FF, $FD, $EF, $FF, $FF, $70, $02, $30, $00, $00, $14, $31; 11:4260
    db $00, $47, $78, $8C, $BF, $FF, $FF, $BB, $BA, $83, $00, $03, $42, $00, $01, $24; 11:4270
    db $55, $58, $CF, $FF, $FF, $FF, $FF, $B6, $45, $56, $41, $00, $11, $00, $00, $13; 11:4280
    db $6A, $BC, $DE, $FF, $FD, $A9, $AC, $B9, $88, $AB, $B9, $77, $89, $A9, $AB, $BD; 11:4290
    db $EF, $FF, $FF, $D9, $32, $20, $00, $00, $02, $12, $35, $67, $55, $68, $AB, $DF; 11:42A0
    db $FF, $FE, $EC, $85, $10, $00, $10, $01, $46, $55, $55, $68, $89, $AD, $FF, $FF; 11:42B0
    db $FF, $DB, $97, $52, $00, $03, $33, $02, $35, $54, $44, $59, $AB, $DD, $EF, $EE; 11:42C0
    db $DC, $A8, $77, $89, $88, $8B, $CB, $A9, $AA, $AB, $AB, $DF, $FF, $C9, $66, $40; 11:42D0
    db $00, $00, $00, $13, $69, $BA, $88, $78, $88, $AA, $AB, $DE, $EC, $A7, $54, $30; 11:42E0
    db $00, $00, $24, $45, $8B, $DD, $BA, $AB, $BB, $BB, $CC, $DE, $DC, $A7, $54, $20; 11:42F0
    db $00, $00, $02, $25, $79, $BB, $AB, $BC, $CB, $BB, $BD, $DC, $CB, $BB, $BA, $98; 11:4300
    db $88, $89, $99, $AB, $DD, $EE, $A8, $66, $52, $00, $00, $11, $02, $59, $BA, $88; 11:4310
    db $9A, $98, $78, $8A, $BC, $CB, $BA, $98, $63, $10, $00, $01, $13, $69, $AA, $AB; 11:4320
    db $DD, $CA, $9A, $AB, $AA, $9A, $BB, $A9, $76, $43, $10, $00, $01, $24, $57, $8B; 11:4330
    db $CD, $CB, $CC, $CB, $A9, $AB, $BB, $BC, $CD, $CB, $BB, $A9, $99, $8A, $AC, $AA; 11:4340
    db $77, $75, $20, $00, $00, $00, $25, $79, $9A, $BB, $BB, $A9, $88, $88, $88, $89; 11:4350
    db $99, $97, $54, $43, $21, $00, $24, $56, $79, $BC, $DD, $DC, $CB, $A9, $98, $88; 11:4360
    db $88, $87, $76, $55, $42, $11, $12, $12, $35, $8A, $AC, $DE, $EE, $CB, $BB, $A9; 11:4370
    db $99, $9A, $BB, $BC, $CC, $CC, $BB, $BA, $BA, $88, $56, $64, $20, $01, $11, $11; 11:4380
    db $35, $67, $78, $9A, $AA, $AA, $AB, $AA, $A9, $99, $88, $86, $54, $44, $32, $22; 11:4390
    db $45, $55, $68, $9A, $AA, $BC, $CC, $BB, $BA, $A9, $88, $76, $65, $53, $32, $22; 11:43A0
    db $22, $22, $56, $78, $9B, $CD, $ED, $DD, $CB, $BA, $A9, $99, $AA, $AB, $BB, $BB; 11:43B0
    db $BA, $AB, $AB, $A8, $86, $76, $42, $00, $10, $00, $13, $55, $77, $89, $AA, $AA; 11:43C0
    db $99, $99, $AA, $99, $9A, $A8, $76, $55, $43, $22, $23, $44, $56, $89, $AA, $BB; 11:43D0
    db $CC, $CB, $BB, $AA, $98, $87, $67, $55, $42, $32, $22, $22, $35, $77, $8A, $BD; 11:43E0
    db $EE, $DD, $CC, $BB, $A9, $99, $AA, $AA, $BB, $BB, $AA, $A9, $A9, $AA, $98, $77; 11:43F0
    db $76, $31, $11, $10, $00, $13, $46, $67, $89, $9A, $AA, $99, $AA, $99, $99, $9A; 11:4400
    db $98, $76, $65, $42, $22, $22, $34, $46, $78, $AB, $BB, $BC, $CC, $BA, $A9, $98; 11:4410
    db $76, $66, $54, $43, $43, $32, $34, $55, $78, $9B, $BC, $DD, $DC, $CB, $BA, $99; 11:4420
    db $9A, $AA, $AA, $BB, $BA, $A9, $98, $99, $AA, $DA, $B8, $99, $73, $10, $10, $00; 11:4430
    db $00, $13, $56, $78, $89, $9A, $98, $79, $AA, $9A, $BC, $BC, $BA, $87, $54, $22; 11:4440
    db $10, $02, $34, $47, $99, $AA, $AA, $AA, $A8, $89, $99, $9A, $A9, $99, $98, $65; 11:4450
    db $54, $44, $33, $46, $78, $9A, $BB, $BC, $CB, $AA, $AA, $AA, $AA, $AB, $BA, $AA; 11:4460
    db $98, $87, $76, $76, $88, $AB, $DE, $FE, $C9, $B9, $50, $00, $00, $00, $12, $24; 11:4470
    db $67, $54, $34, $45, $45, $59, $BC, $CF, $FE, $CC, $BA, $64, $33, $44, $24, $57; 11:4480
    db $77, $78, $76, $56, $65, $56, $8A, $AB, $CC, $DD, $BA, $98, $76, $56, $66, $68; 11:4490
    db $9A, $99, $AA, $99, $88, $89, $9A, $AB, $BB, $AA, $A9, $87, $77, $77, $67, $78; 11:44A0
    db $88, $88, $88, $89, $88, $89, $9A, $BA, $A8, $88, $64, $21, $12, $13, $45, $66; 11:44B0
    db $78, $77, $54, $34, $34, $46, $78, $AB, $BB, $A9, $87, $65, $54, $56, $78, $9A; 11:44C0
    db $BA, $A9, $87, $76, $66, $77, $89, $9A, $AA, $99, $88, $77, $77, $78, $89, $9A; 11:44D0
    db $A9, $99, $88, $77, $77, $78, $88, $88, $88, $87, $77, $77, $78, $88, $99, $99; 11:44E0
    db $99, $98, $88, $77, $88, $88, $88, $88, $77, $77, $67, $77, $78, $88, $99, $98; 11:44F0
    db $88, $88, $78, $78, $88, $77, $76, $65, $55, $55, $55, $66, $77, $77, $76, $66; 11:4500
    db $66, $66, $67, $77, $77, $77, $77, $77, $77, $78, $88, $99, $99, $99, $88, $88; 11:4510
    db $88, $89, $99, $99, $99, $98, $88, $88, $88, $88, $99, $98, $88, $88, $88, $88; 11:4520
    db $88, $88, $88, $88, $88, $87, $77, $77, $78, $88, $88, $88, $88, $88, $88, $77; 11:4530
    db $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77; 11:4540
    db $78, $88, $88, $88, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $78; 11:4550
    db $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $78, $78, $87, $78, $78, $88; 11:4560
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:4570
    db $88, $88, $88, $78, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88; 11:4580
    db $88, $88, $78, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77; 11:4590
    db $77, $78, $88, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $87, $77, $77; 11:45A0
    db $77, $77, $77, $88, $87, $88, $88, $77, $77, $78, $87, $88, $87, $87, $77, $77; 11:45B0
    db $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:45C0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $88; 11:45D0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $87, $77, $77; 11:45E0
    db $77, $77, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88; 11:45F0
    db $88, $88, $87, $77, $77, $77, $77, $77, $77, $77, $77, $78, $88, $88, $88, $88; 11:4600
    db $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $77, $77, $88; 11:4610
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $85, $67, $A9, $5A, $58; 11:4620
    db $59, $68, $88, $77, $88, $78, $88, $88, $88, $8A, $65, $56, $89, $B9, $97, $67; 11:4630
    db $68, $88, $88, $88, $88, $88, $85, $77, $99, $86, $77, $88, $98, $97, $78, $8A; 11:4640
    db $A6, $76, $76, $89, $78, $78, $68, $87, $77, $77, $78, $77, $65, $66, $88, $88; 11:4650
    db $88, $88, $88, $87, $87, $77, $87, $88, $88, $88, $68, $88, $88, $75, $67, $78; 11:4660
    db $88, $77, $89, $9A, $A8, $98, $85, $47, $58, $89, $88, $78, $89, $88, $76, $78; 11:4670
    db $88, $87, $89, $88, $98, $87, $77, $88, $77, $87, $68, $77, $88, $77, $88, $87; 11:4680
    db $67, $68, $78, $56, $77, $88, $87, $67, $79, $89, $87, $78, $99, $88, $78, $88; 11:4690
    db $44, $67, $88, $66, $56, $79, $98, $65, $79, $A9, $97, $88, $AA, $A9, $88, $88; 11:46A0
    db $88, $86, $68, $88, $77, $78, $88, $88, $87, $87, $88, $88, $88, $98, $88, $88; 11:46B0
    db $88, $88, $88, $87, $88, $87, $77, $78, $77, $67, $76, $87, $77, $77, $87, $87; 11:46C0
    db $87, $78, $78, $87, $79, $88, $88, $88, $88, $88, $88, $88, $88, $77, $87, $77; 11:46D0
    db $77, $76, $77, $76, $66, $66, $56, $66, $66, $65, $67, $66, $77, $77, $78, $77; 11:46E0
    db $88, $88, $88, $88, $89, $89, $88, $88, $99, $99, $99, $99, $99, $89, $89, $99; 11:46F0
    db $99, $98, $88, $88, $88, $88, $88, $88, $88, $78, $78, $88, $98, $98, $88, $99; 11:4700
    db $99, $99, $99, $AA, $BA, $BB, $B8, $85, $56, $67, $55, $33, $11, $12, $21, $11; 11:4710
    db $11, $00, $12, $34, $55, $55, $56, $78, $A9, $99, $AB, $BB, $BB, $BC, $CB, $BB; 11:4720
    db $AA, $AA, $AA, $98, $88, $88, $87, $88, $88, $88, $88, $89, $99, $99, $89, $99; 11:4730
    db $9A, $AA, $BA, $AB, $AA, $AB, $BB, $BB, $BB, $BB, $BB, $BB, $BA, $AA, $AA, $AA; 11:4740
    db $AA, $AA, $9A, $99, $AB, $DA, $95, $22, $01, $21, $10, $00, $00, $00, $00, $00; 11:4750
    db $01, $00, $12, $35, $77, $99, $9A, $AA, $AA, $AB, $CB, $BB, $A8, $88, $89, $98; 11:4760
    db $98, $98, $88, $99, $9A, $99, $99, $99, $88, $88, $88, $77, $76, $66, $67, $77; 11:4770
    db $88, $88, $99, $9A, $AB, $BB, $BB, $BB, $BB, $BB, $BB, $BB, $AA, $AA, $9A, $AA; 11:4780
    db $AA, $AA, $AA, $BB, $BB, $BB, $AA, $AB, $BC, $BB, $DE, $FD, $70, $00, $00, $10; 11:4790
    db $00, $00, $00, $00, $00, $25, $75, $33, $34, $56, $89, $AA, $99, $97, $55, $56; 11:47A0
    db $88, $88, $88, $77, $78, $89, $BC, $CD, $CA, $A9, $99, $99, $AA, $A9, $87, $65; 11:47B0
    db $56, $78, $89, $88, $88, $77, $78, $99, $AA, $AA, $98, $88, $88, $88, $99, $99; 11:47C0
    db $88, $88, $89, $9A, $AB, $BB, $BB, $AA, $BB, $BC, $CD, $DD, $DC, $CC, $BB, $BB; 11:47D0
    db $BC, $CD, $DE, $FE, $C7, $10, $00, $00, $00, $00, $00, $00, $00, $00, $25, $65; 11:47E0
    db $56, $67, $65, $55, $57, $9A, $BA, $87, $67, $77, $77, $8A, $BC, $CC, $BA, $99; 11:47F0
    db $9A, $AA, $AA, $AA, $98, $76, $65, $56, $78, $88, $88, $88, $87, $77, $88, $99; 11:4800
    db $99, $98, $88, $87, $77, $88, $89, $99, $88, $88, $88, $89, $99, $AA, $AA, $AA; 11:4810
    db $AA, $AB, $BB, $CC, $CC, $CC, $CC, $CC, $CC, $CB, $BB, $CD, $FF, $EA, $51, $00; 11:4820
    db $00, $00, $00, $01, $10, $00, $00, $00, $01, $13, $68, $88, $76, $66, $66, $78; 11:4830
    db $89, $AB, $CC, $BA, $A9, $99, $9A, $AB, $BB, $BB, $BA, $97, $66, $77, $77, $78; 11:4840
    db $88, $88, $76, $66, $77, $88, $88, $99, $99, $88, $77, $77, $78, $88, $89, $99; 11:4850
    db $98, $88, $88, $88, $89, $99, $9A, $AA, $99, $99, $9A, $AA, $BB, $BB, $BB, $BB; 11:4860
    db $BB, $BB, $BB, $BB, $BB, $CC, $CD, $DD, $B7, $42, $34, $31, $00, $01, $22, $20; 11:4870
    db $00, $00, $10, $00, $12, $45, $54, $44, $56, $66, $66, $77, $78, $89, $99, $99; 11:4880
    db $99, $AA, $A9, $99, $AA, $BB, $BA, $AA, $BB, $AA, $99, $99, $99, $99, $99, $99; 11:4890
    db $88, $88, $77, $87, $77, $77, $76, $66, $66, $66, $66, $66, $66, $66, $77, $88; 11:48A0
    db $89, $99, $AA, $AB, $BB, $BB, $BC, $CC, $CC, $CB, $BB, $BB, $BB, $BB, $BB, $BB; 11:48B0
    db $AA, $AB, $BB, $BB, $BA, $86, $66, $76, $42, $11, $12, $10, $00, $00, $00, $00; 11:48C0
    db $00, $00, $12, $22, $23, $34, $55, $55, $67, $78, $9A, $AA, $AA, $BB, $BB, $BB; 11:48D0
    db $BC, $CC, $CC, $CC, $CC, $CC, $BB, $BB, $BB, $BA, $AA, $99, $88, $88, $77, $66; 11:48E0
    db $66, $55, $55, $55, $55, $55, $55, $55, $56, $66, $77, $88, $99, $9A, $AA, $BB; 11:48F0
    db $BB, $CC, $CC, $CC, $CC, $CC, $BB, $BB, $BB, $BB, $BB, $BA, $AA, $AA, $AA, $AA; 11:4900
    db $A9, $87, $65, $56, $54, $21, $11, $11, $00, $00, $00, $00, $00, $00, $12, $22; 11:4910
    db $22, $34, $55, $66, $66, $78, $89, $9A, $AA, $AA, $BB, $BB, $BB, $CC, $CD, $CC; 11:4920
    db $CC, $CC, $CC, $BB, $BB, $BB, $AA, $99, $88, $88, $77, $66, $55, $55, $55, $55; 11:4930
    db $55, $55, $55, $55, $66, $77, $77, $88, $99, $9A, $AA, $BB, $BB, $BB, $CC, $CC; 11:4940
    db $CC, $BB, $BB, $BB, $BB, $BB, $BA, $AA, $AA, $AA, $99, $AA, $AA, $AA, $97, $65; 11:4950
    db $56, $55, $32, $11, $22, $10, $00, $00, $00, $00, $00, $12, $22, $22, $33, $45; 11:4960
    db $56, $66, $77, $89, $9A, $AA, $AA, $BB, $BB, $BC, $CC, $CC, $DC, $CC, $CC, $CC; 11:4970
    db $CB, $BA, $AA, $AA, $98, $88, $88, $77, $66, $55, $55, $55, $55, $55, $56, $66; 11:4980
    db $66, $67, $77, $88, $89, $9A, $AA, $BB, $BB, $BB, $BB, $BB, $BB, $BB, $BB, $BB; 11:4990
    db $AA, $AA, $AA, $AA, $AA, $A9, $99, $99, $99, $99, $99, $98, $87, $65, $55, $54; 11:49A0
    db $32, $22, $22, $10, $00, $00, $00, $00, $00, $11, $22, $23, $34, $55, $67, $78; 11:49B0
    db $88, $99, $AA, $BB, $BB, $BB, $BC, $CC, $CB, $BB, $CC, $CC, $CC, $BB, $BB, $AA; 11:49C0
    db $99, $99, $88, $88, $77, $76, $66, $66, $55, $55, $66, $66, $66, $67, $77, $78; 11:49D0
    db $88, $89, $99, $AA, $AA, $AB, $BB, $BB, $BB, $BB, $BB, $BB, $AA, $AA, $AA, $AA; 11:49E0
    db $99, $99, $99, $99, $88, $88, $88, $88, $88, $88, $87, $66, $55, $54, $33, $33; 11:49F0
    db $22, $10, $00, $00, $00, $00, $01, $11, $12, $23, $45, $55, $56, $67, $88, $88; 11:4A00
    db $9A, $BB, $BB, $BB, $BB, $BB, $BB, $BB, $CC, $CC, $CC, $BB, $BB, $AA, $AA, $A9; 11:4A10
    db $99, $98, $88, $77, $77, $66, $66, $66, $66, $66, $66, $77, $77, $88, $88, $89; 11:4A20
    db $99, $AA, $AA, $BB, $BB, $BB, $BB, $BB, $AA, $AA, $AA, $A9, $99, $99, $99, $99; 11:4A30
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $76, $65, $55, $54, $43, $33, $22; 11:4A40
    db $11, $01, $10, $00, $00, $01, $22, $23, $34, $55, $55, $67, $78, $88, $99, $AA; 11:4A50
    db $BB, $BB, $BB, $BB, $BB, $BB, $CC, $CC, $BB, $BB, $BB, $BA, $AA, $A9, $99, $88; 11:4A60
    db $88, $88, $77, $77, $66, $66, $66, $66, $66, $67, $77, $78, $88, $88, $99, $99; 11:4A70
    db $AA, $AA, $AB, $BB, $BB, $BB, $BA, $AA, $AA, $AA, $AA, $99, $98, $88, $88, $88; 11:4A80
    db $87, $77, $78, $87, $77, $77, $66, $66, $66, $55, $55, $55, $44, $44, $33, $22; 11:4A90
    db $22, $22, $22, $22, $22, $22, $33, $44, $44, $55, $66, $77, $78, $88, $99, $AA; 11:4AA0
    db $AB, $BB, $BB, $BB, $BC, $CC, $CB, $BB, $BB, $BB, $BA, $AA, $AA, $99, $98, $88; 11:4AB0
    db $88, $87, $77, $77, $77, $77, $77, $77, $77, $78, $88, $88, $89, $99, $99, $98; 11:4AC0
    db $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $77; 11:4AD0
    db $77, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87; 11:4AE0
    db $77, $77, $76, $66, $66, $66, $55, $55, $55, $55, $55, $55, $55, $55, $66, $66; 11:4AF0
    db $66, $77, $77, $78, $88, $88, $88, $88, $99, $99, $99, $99, $99, $99, $99, $99; 11:4B00
    db $99, $99, $99, $99, $99, $99, $99, $99, $88, $88, $88, $88, $88, $88, $88, $88; 11:4B10
    db $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77; 11:4B20
    db $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $78, $77, $88, $88, $88, $88; 11:4B30
    db $88, $77, $88, $76, $78, $87, $78, $88, $77, $87, $67, $77, $76, $76, $67, $65; 11:4B40
    db $66, $65, $56, $66, $66, $67, $77, $77, $77, $78, $87, $88, $78, $88, $88, $99; 11:4B50
    db $89, $98, $88, $89, $99, $98, $88, $99, $88, $99, $88, $99, $88, $99, $88, $88; 11:4B60
    db $88, $88, $88, $88, $77, $77, $77, $88, $87, $77, $88, $88, $88, $88, $88, $88; 11:4B70
    db $88, $99, $88, $88, $98, $98, $89, $98, $88, $89, $9A, $99, $89, $99, $A9, $99; 11:4B80
    db $AA, $A9, $AA, $AA, $98, $65, $45, $76, $53, $22, $21, $10, $11, $11, $21, $00; 11:4B90
    db $02, $45, $54, $56, $67, $78, $9A, $BB, $BB, $A9, $AB, $CC, $BA, $AA, $A9, $98; 11:4BA0
    db $88, $89, $88, $66, $67, $88, $87, $88, $87, $78, $89, $99, $98, $88, $89, $99; 11:4BB0
    db $98, $88, $88, $77, $88, $88, $87, $77, $78, $88, $98, $99, $99, $99, $AA, $BA; 11:4BC0
    db $AA, $AA, $AB, $BB, $BB, $BB, $BA, $AA, $AB, $BB, $BB, $CD, $CB, $93, $11, $47; 11:4BD0
    db $63, $00, $00, $00, $00, $00, $12, $10, $00, $26, $88, $78, $9A, $AA, $9B, $CE; 11:4BE0
    db $EE, $DB, $87, $89, $A9, $87, $66, $53, $22, $45, $66, $76, $54, $57, $9A, $BB; 11:4BF0
    db $BC, $CC, $BB, $CD, $EE, $ED, $B9, $88, $98, $87, $66, $54, $33, $34, $56, $76; 11:4C00
    db $65, $67, $8A, $AB, $BB, $CC, $BB, $BB, $CD, $DC, $BA, $99, $AA, $AA, $AA, $AA; 11:4C10
    db $A9, $99, $AA, $AC, $BD, $CE, $FF, $C2, $00, $58, $92, $00, $00, $00, $00, $00; 11:4C20
    db $03, $50, $00, $05, $BA, $99, $BC, $CB, $AB, $CC, $EF, $FF, $A5, $35, $99, $85; 11:4C30
    db $55, $54, $21, $12, $35, $8A, $96, $34, $8B, $CC, $CD, $EE, $DC, $BB, $BC, $DE; 11:4C40
    db $EB, $75, $45, $76, $55, $55, $43, $22, $35, $68, $AA, $87, $79, $BC, $DC, $DD; 11:4C50
    db $DC, $BB, $BB, $CC, $CC, $B8, $77, $99, $A9, $9A, $AA, $99, $99, $AB, $DE, $EF; 11:4C60
    db $FE, $B3, $00, $58, $83, $00, $00, $00, $00, $00, $02, $20, $00, $06, $AB, $AA; 11:4C70
    db $AB, $BA, $BD, $EE, $FF, $FE, $A5, $47, $9B, $97, $54, $32, $11, $23, $45, $77; 11:4C80
    db $64, $24, $7B, $CC, $CC, $CC, $BB, $CD, $EE, $EE, $DA, $76, $68, $98, $75, $44; 11:4C90
    db $32, $34, $55, $66, $66, $55, $69, $BD, $CC, $BB, $BB, $CD, $EE, $ED, $CB, $A9; 11:4CA0
    db $9A, $BC, $BA, $98, $88, $8A, $AA, $A9, $99, $9A, $BD, $FE, $B3, $00, $58, $82; 11:4CB0
    db $20, $10, $00, $00, $00, $02, $20, $00, $05, $89, $77, $89, $99, $9B, $DD, $EF; 11:4CC0
    db $FD, $97, $8B, $DC, $A8, $76, $54, $44, $55, $56, $65, $32, $25, $8A, $98, $88; 11:4CD0
    db $9A, $AB, $CD, $DD, $CC, $BA, $9A, $BC, $B9, $76, $66, $66, $66, $65, $44, $44; 11:4CE0
    db $46, $89, $98, $77, $8A, $BC, $DD, $DD, $CC, $CC, $CD, $EE, $DC, $A9, $9A, $AB; 11:4CF0
    db $AA, $A9, $77, $78, $9A, $BC, $BA, $61, $01, $59, $84, $20, $10, $00, $01, $20; 11:4D00
    db $11, $00, $00, $26, $76, $44, $56, $67, $8A, $CD, $CB, $A9, $9A, $BE, $ED, $A8; 11:4D10
    db $88, $88, $89, $99, $86, $54, $45, $68, $98, $65, $56, $88, $99, $AA, $98, $88; 11:4D20
    db $9A, $BC, $CA, $97, $78, $99, $99, $88, $76, $55, $68, $88, $87, $66, $78, $AA; 11:4D30
    db $BA, $AA, $AA, $AB, $BC, $DD, $BA, $9A, $AA, $BA, $A9, $88, $77, $78, $78, $89; 11:4D40
    db $88, $77, $65, $55, $78, $75, $33, $45, $42, $23, $44, $22, $11, $22, $34, $43; 11:4D50
    db $33, $45, $55, $56, $78, $87, $77, $89, $AA, $99, $99, $AA, $99, $9A, $AA, $AA; 11:4D60
    db $99, $9A, $AA, $A9, $AA, $AA, $AA, $AA, $AA, $A9, $99, $99, $98, $88, $87, $77; 11:4D70
    db $77, $66, $66, $55, $55, $56, $66, $66, $66, $77, $88, $89, $99, $9A, $AA, $AA; 11:4D80
    db $AA, $AA, $AA, $99, $99, $98, $88, $88, $88, $87, $77, $77, $77, $78, $88, $88; 11:4D90
    db $88, $88, $88, $88, $88, $88, $77, $77, $77, $66, $66, $66, $55, $55, $55, $55; 11:4DA0
    db $55, $55, $55, $55, $55, $55, $55, $55, $56, $66, $66, $66, $77, $77, $88, $88; 11:4DB0
    db $89, $99, $AA, $AA, $BB, $BB, $BB, $BB, $BB, $AA, $AA, $99, $99, $98, $88, $88; 11:4DC0
    db $87, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:4DD0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:4DE0
    db $87, $77, $77, $76, $66, $66, $66, $55, $55, $55, $55, $55, $55, $55, $55, $55; 11:4DF0
    db $55, $55, $55, $66, $66, $66, $66, $77, $77, $88, $88, $88, $89, $99, $9A, $AA; 11:4E00
    db $AA, $AA, $AA, $AA, $AA, $AA, $99, $A9, $99, $99, $99, $98, $88, $88, $88, $88; 11:4E10
    db $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88; 11:4E20
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77; 11:4E30
    db $77, $66, $66, $66, $66, $55, $55, $55, $55, $55, $55, $55, $55, $55, $66, $66; 11:4E40
    db $66, $66, $67, $77, $77, $77, $88, $88, $88, $99, $99, $99, $99, $9A, $AA, $A9; 11:4E50
    db $99, $AA, $AA, $A9, $99, $99, $99, $99, $99, $99, $98, $88, $98, $88, $88, $88; 11:4E60
    db $88, $88, $77, $77, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88; 11:4E70
    db $88, $88, $88, $88, $88, $88, $88, $87, $78, $77, $77, $77, $77, $77, $77, $77; 11:4E80
    db $66, $66, $66, $66, $55, $55, $55, $55, $56, $65, $66, $66, $66, $66, $66, $67; 11:4E90
    db $77, $77, $77, $77, $77, $78, $88, $88, $88, $88, $99, $99, $99, $99, $99, $99; 11:4EA0
    db $99, $99, $9A, $AA, $AA, $99, $9A, $A9, $98, $79, $AA, $98, $88, $88, $87, $78; 11:4EB0
    db $88, $88, $88, $87, $78, $88, $77, $77, $88, $88, $77, $88, $87, $77, $88, $87; 11:4EC0
    db $77, $88, $87, $78, $77, $77, $77, $87, $77, $77, $77, $77, $77, $77, $76, $67; 11:4ED0
    db $76, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66, $66; 11:4EE0
    db $67, $77, $77, $77, $78, $78, $88, $88, $88, $88, $99, $99, $99, $99, $99, $99; 11:4EF0
    db $99, $A9, $99, $99, $99, $99, $99, $99, $99, $88, $89, $98, $88, $89, $98, $88; 11:4F00
    db $99, $88, $88, $98, $88, $88, $88, $88, $77, $88, $87, $77, $88, $78, $77, $87; 11:4F10
    db $66, $66, $88, $78, $77, $87, $78, $78, $76, $78, $88, $76, $78, $77, $77, $76; 11:4F20
    db $77, $77, $66, $77, $76, $66, $77, $65, $66, $76, $65, $56, $66, $66, $66, $67; 11:4F30
    db $76, $67, $77, $77, $77, $78, $78, $87, $88, $88, $78, $98, $89, $89, $98, $8A; 11:4F40
    db $A9, $98, $89, $A9, $89, $99, $99, $9A, $99, $A8, $8A, $99, $98, $89, $A9, $87; 11:4F50
    db $8A, $89, $88, $88, $97, $77, $88, $87, $78, $88, $78, $68, $87, $88, $77, $76; 11:4F60
    db $88, $78, $78, $96, $79, $78, $76, $88, $77, $67, $88, $77, $77, $88, $77, $76; 11:4F70
    db $87, $88, $67, $87, $77, $77, $77, $77, $68, $65, $76, $76, $56, $76, $65, $56; 11:4F80
    db $86, $55, $58, $86, $54, $77, $87, $57, $86, $86, $79, $67, $88, $88, $88, $8C; 11:4F90
    db $86, $A9, $9B, $89, $97, $AB, $88, $A8, $9B, $88, $99, $89, $9A, $98, $88, $A9; 11:4FA0
    db $B9, $58, $AB, $88, $87, $9B, $78, $78, $99, $76, $88, $89, $67, $98, $96, $78; 11:4FB0
    db $7A, $66, $97, $87, $69, $78, $86, $67, $89, $77, $56, $88, $77, $78, $66, $86; 11:4FC0
    db $98, $85, $87, $77, $78, $67, $77, $77, $76, $66, $77, $66, $66, $76, $55, $56; 11:4FD0
    db $65, $76, $56, $56, $67, $77, $67, $75, $78, $77, $86, $68, $79, $87, $88, $A9; 11:4FE0
    db $98, $88, $99, $98, $9A, $78, $AA, $88, $99, $8C, $97, $A8, $BA, $99, $7A, $A9; 11:4FF0
    db $96, $9A, $89, $78, $A9, $66, $B9, $8A, $39, $B7, $89, $78, $86, $A7, $78, $97; 11:5000
    db $96, $76, $9A, $75, $68, $89, $84, $77, $89, $76, $85, $89, $77, $97, $89, $48; 11:5010
    db $A5, $87, $6B, $75, $65, $79, $65, $65, $67, $55, $55, $65, $55, $66, $55, $56; 11:5020
    db $77, $65, $65, $77, $77, $67, $67, $99, $65, $79, $A7, $88, $79, $88, $97, $B9; 11:5030
    db $5C, $B4, $B8, $8B, $B8, $B6, $8B, $A9, $C8, $99, $9A, $B8, $97, $9E, $88, $77; 11:5040
    db $A9, $7B, $98, $78, $6B, $A8, $65, $99, $7B, $67, $88, $88, $5B, $87, $85, $79; 11:5050
    db $9A, $85, $88, $8A, $74, $89, $8A, $76, $87, $67, $69, $76, $65, $66, $54, $45; 11:5060
    db $76, $44, $33, $56, $44, $44, $66, $33, $56, $77, $55, $55, $88, $86, $67, $89; 11:5070
    db $88, $77, $8A, $99, $87, $98, $AC, $88, $78, $BB, $89, $88, $AB, $9A, $79, $99; 11:5080
    db $AA, $78, $A8, $B7, $89, $8A, $9B, $77, $89, $A8, $AA, $7A, $99, $A7, $8B, $9B; 11:5090
    db $95, $8C, $A9, $77, $8B, $B8, $78, $E9, $78, $BB, $C9, $64, $6A, $A8, $64, $55; 11:50A0
    db $55, $33, $32, $33, $42, $00, $02, $44, $10, $03, $44, $33, $35, $67, $65, $57; 11:50B0
    db $89, $A8, $89, $89, $BB, $BA, $9A, $BB, $B8, $89, $BB, $B8, $88, $99, $BA, $97; 11:50C0
    db $78, $9A, $97, $86, $8B, $B8, $55, $9A, $BB, $95, $69, $BE, $B9, $78, $BD, $B9; 11:50D0
    db $A7, $BA, $CD, $A8, $9B, $DE, $C9, $AB, $DF, $C8, $53, $5B, $DA, $50, $23, $53; 11:50E0
    db $10, $22, $10, $00, $00, $00, $22, $10, $00, $35, $65, $56, $78, $88, $8B, $DD; 11:50F0
    db $CB, $BA, $BB, $CC, $DC, $BA, $99, $9A, $99, $87, $76, $56, $66, $66, $55, $66; 11:5100
    db $66, $78, $88, $88, $99, $AB, $BC, $CB, $BA, $CD, $ED, $CC, $BD, $DE, $EC, $CD; 11:5110
    db $DE, $EE, $EF, $FF, $C5, $01, $9F, $E5, $00, $02, $00, $00, $10, $00, $00, $00; 11:5120
    db $02, $42, $00, $03, $8B, $A8, $8A, $AA, $AB, $FF, $FF, $EC, $CC, $CD, $FF, $FB; 11:5130
    db $75, $68, $87, $65, $43, $10, $13, $45, $54, $44, $45, $79, $BC, $BA, $9A, $CD; 11:5140
    db $EF, $FF, $ED, $CD, $FF, $FF, $FE, $ED, $DE, $FF, $FF, $FF, $40, $02, $FF, $A0; 11:5150
    db $00, $00, $00, $27, $00, $00, $00, $01, $68, $50, $00, $49, $EE, $DE, $FB, $86; 11:5160
    db $8F, $FF, $FE, $B8, $66, $9D, $FC, $93, $11, $00, $25, $77, $20, $00, $25, $99; 11:5170
    db $A9, $65, $68, $CF, $FF, $ED, $BB, $BD, $FF, $FF, $EC, $CD, $FF, $FF, $FF, $FF; 11:5180
    db $F4, $00, $5F, $F9, $00, $00, $00, $03, $60, $00, $00, $00, $5D, $E9, $00, $06; 11:5190
    db $EF, $FD, $FF, $D8, $57, $DF, $FF, $EB, $40, $03, $AB, $95, $00, $10, $00, $38; 11:51A0
    db $96, $33, $33, $6A, $FF, $FB, $88, $AC, $EF, $FF, $FD, $A8, $AD, $FF, $FF, $FD; 11:51B0
    db $DF, $FF, $FC, $10, $0C, $FB, $00, $03, $00, $00, $20, $00, $10, $00, $08, $DD; 11:51C0
    db $85, $58, $BE, $DB, $DF, $FE, $A8, $98, $68, $CC, $82, $01, $33, $12, $24, $54; 11:51D0
    db $10, $14, $79, $AC, $B8, $79, $CF, $FE, $EE, $ED, $CB, $CD, $EF, $ED, $CB, $BD; 11:51E0
    db $FF, $FF, $FF, $D1, $00, $6F, $F5, $00, $00, $00, $04, $20, $00, $00, $00, $7E; 11:51F0
    db $FE, $A6, $68, $CE, $EF, $FF, $D9, $67, $64, $6B, $DA, $30, $00, $01, $45, $44; 11:5200
    db $20, $00, $46, $8B, $DC, $A7, $79, $EF, $FF, $FE, $CB, $CD, $EF, $FF, $FE, $EE; 11:5210
    db $FF, $FF, $FB, $00, $06, $D9, $20, $00, $00, $00, $00, $02, $43, $00, $05, $BE; 11:5220
    db $FD, $BA, $BB, $DD, $FF, $FE, $CB, $A6, $24, $89, $85, $31, $00, $01, $33, $34; 11:5230
    db $44, $34, $35, $8B, $CC, $BA, $AB, $BB, $EF, $FF, $EF, $EE, $EF, $FF, $FF, $FF; 11:5240
    db $FF, $82, $00, $AF, $A4, $00, $00, $00, $00, $00, $14, $30, $00, $19, $DE, $CA; 11:5250
    db $98, $89, $BE, $FE, $DB, $BB, $85, $45, $78, $87, $54, $10, $11, $36, $65, $44; 11:5260
    db $54, $55, $69, $AB, $BB, $CA, $9A, $BD, $FF, $FF, $FF, $FF, $FF, $FF, $FC, $73; 11:5270
    db $47, $97, $54, $42, $00, $00, $00, $00, $35, $42, $00, $25, $78, $AB, $BA, $AA; 11:5280
    db $BB, $A9, $89, $CD, $CA, $76, $56, $66, $76, $55, $44, $55, $54, $34, $67, $88; 11:5290
    db $89, $99, $AA, $99, $98, $8A, $BC, $BB, $AA, $BC, $DE, $FF, $EA, $88, $9B, $A9; 11:52A0
    db $99, $99, $87, $54, $32, $34, $55, $43, $22, $34, $43, $34, $45, $57, $77, $66; 11:52B0
    db $66, $78, $88, $88, $89, $99, $99, $99, $99, $99, $99, $99, $88, $77, $66, $66; 11:52C0
    db $66, $66, $55, $55, $67, $88, $99, $99, $AB, $BC, $DC, $CD, $DD, $DD, $CB, $BB; 11:52D0
    db $BB, $BA, $87, $76, $66, $65, $44, $32, $22, $22, $21, $22, $33, $23, $33, $45; 11:52E0
    db $56, $66, $66, $78, $89, $AA, $AA, $AA, $AB, $BA, $AA, $AA, $AA, $99, $98, $88; 11:52F0
    db $88, $88, $78, $88, $99, $9A, $AB, $BB, $BA, $AB, $CC, $CC, $BA, $A9, $A9, $98; 11:5300
    db $77, $65, $55, $43, $32, $22, $22, $21, $11, $23, $34, $44, $44, $45, $67, $77; 11:5310
    db $78, $89, $AA, $99, $9A, $AA, $BB, $AA, $9A, $AA, $AA, $99, $99, $98, $88, $88; 11:5320
    db $99, $99, $99, $9A, $BB, $AA, $AA, $BA, $BB, $AA, $99, $99, $87, $66, $56, $66; 11:5330
    db $54, $22, $23, $33, $43, $22, $33, $34, $44, $45, $55, $56, $66, $77, $89, $99; 11:5340
    db $88, $88, $99, $9A, $99, $99, $AA, $AA, $99, $9A, $99, $99, $99, $99, $AA, $BB; 11:5350
    db $BC, $CB, $BB, $BB, $BB, $BA, $A9, $88, $88, $76, $65, $55, $54, $33, $22, $33; 11:5360
    db $33, $32, $34, $55, $55, $44, $55, $66, $76, $77, $78, $88, $88, $88, $88, $88; 11:5370
    db $88, $88, $99, $99, $99, $99, $AA, $BB, $BB, $BC, $CD, $EE, $DC, $CC, $CD, $CB; 11:5380
    db $A9, $88, $88, $86, $54, $33, $43, $22, $11, $12, $22, $22, $22, $45, $65, $55; 11:5390
    db $55, $67, $88, $88, $88, $99, $99, $98, $88, $89, $88, $88, $88, $99, $98, $88; 11:53A0
    db $9A, $BB, $BB, $BC, $DE, $EE, $ED, $CC, $DE, $ED, $B9, $99, $9A, $97, $54, $43; 11:53B0
    db $44, $31, $00, $00, $21, $11, $01, $23, $44, $44, $44, $56, $77, $77, $78, $9A; 11:53C0
    db $AA, $98, $99, $AA, $A9, $98, $99, $AA, $99, $99, $9A, $BB, $BB, $BC, $DE, $ED; 11:53D0
    db $CC, $CD, $ED, $DB, $98, $89, $98, $75, $43, $34, $43, $21, $00, $12, $22, $11; 11:53E0
    db $12, $34, $55, $44, $45, $67, $77, $77, $78, $9A, $99, $88, $89, $99, $98, $88; 11:53F0
    db $9A, $BB, $AA, $AA, $BC, $CC, $CD, $EE, $FE, $DD, $CD, $DD, $CB, $A8, $88, $87; 11:5400
    db $65, $43, $33, $22, $21, $00, $11, $22, $21, $12, $34, $55, $55, $55, $66, $77; 11:5410
    db $77, $78, $99, $98, $88, $88, $99, $99, $89, $9A, $AB, $BB, $BC, $DE, $FF, $FF; 11:5420
    db $FF, $EC, $BC, $EE, $EC, $97, $54, $46, $54, $21, $12, $21, $00, $00, $23, $44; 11:5430
    db $32, $23, $58, $88, $76, $78, $99, $99, $98, $88, $98, $76, $67, $89, $76, $55; 11:5440
    db $67, $89, $98, $89, $AC, $DD, $DD, $FF, $FF, $FC, $AA, $DF, $FE, $95, $22, $58; 11:5450
    db $96, $10, $00, $22, $10, $00, $23, $32, $22, $46, $89, $74, $35, $9C, $CA, $87; 11:5460
    db $68, $9A, $98, $65, $78, $88, $76, $78, $88, $78, $89, $AB, $BB, $BB, $DF, $FF; 11:5470
    db $FF, $FB, $BC, $FF, $FC, $74, $35, $67, $74, $00, $00, $22, $00, $00, $01, $12; 11:5480
    db $45, $66, $55, $55, $8B, $BB, $87, $79, $AB, $A8, $77, $66, $78, $87, $66, $66; 11:5490
    db $67, $89, $99, $89, $AC, $EE, $FF, $FF, $FF, $CC, $DF, $FF, $B7, $55, $78, $86; 11:54A0
    db $20, $00, $23, $00, $00, $00, $00, $24, $44, $44, $56, $7A, $B9, $77, $8B, $CB; 11:54B0
    db $A8, $77, $99, $88, $77, $77, $77, $77, $78, $98, $79, $AB, $CD, $DD, $EF, $FF; 11:54C0
    db $FB, $BD, $FF, $FB, $86, $78, $87, $52, $01, $22, $20, $00, $10, $00, $02, $54; 11:54D0
    db $43, $24, $58, $AA, $76, $79, $BB, $A9, $87, $99, $88, $87, $88, $76, $67, $88; 11:54E0
    db $88, $77, $9B, $CC, $CC, $DE, $FF, $FF, $AB, $DF, $FF, $B8, $88, $88, $75, $31; 11:54F0
    db $22, $22, $10, $11, $00, $00, $35, $43, $22, $46, $8A, $96, $57, $9B, $BA, $99; 11:5500
    db $88, $98, $89, $88, $77, $67, $88, $87, $77, $79, $BA, $AB, $BB, $DF, $FF, $FD; 11:5510
    db $AC, $EF, $FE, $B8, $88, $88, $87, $31, $32, $33, $21, $20, $00, $01, $34, $21; 11:5520
    db $12, $46, $89, $75, $57, $9A, $B9, $98, $88, $AA, $AA, $88, $88, $88, $99, $87; 11:5530
    db $87, $9A, $BA, $AA, $BB, $DE, $FF, $FB, $8A, $DF, $FE, $A7, $78, $9A, $A7, $41; 11:5540
    db $33, $45, $31, $20, $00, $02, $34, $21, $12, $45, $79, $74, $45, $8A, $B9, $87; 11:5550
    db $68, $AB, $BA, $87, $88, $99, $A9, $87, $88, $8B, $BA, $AA, $AA, $CD, $EF, $ED; 11:5560
    db $88, $BE, $FF, $B7, $67, $9B, $CA, $62, $24, $57, $64, $12, $00, $13, $34, $20; 11:5570
    db $01, $24, $57, $75, $24, $68, $AB, $87, $56, $8B, $CC, $97, $78, $AB, $BA, $87; 11:5580
    db $78, $9A, $BB, $99, $9A, $BC, $DE, $DE, $C7, $8B, $EF, $FB, $65, $68, $CE, $B7; 11:5590
    db $11, $35, $98, $41, $00, $03, $54, $31, $00, $24, $55, $66, $33, $46, $8A, $A8; 11:55A0
    db $86, $68, $AC, $CB, $86, $79, $BC, $BA, $75, $68, $BC, $B9, $88, $9B, $CE, $DD; 11:55B0
    db $CC, $88, $AB, $EF, $C9, $76, $68, $CD, $B6, $11, $16, $98, $53, $00, $04, $66; 11:55C0
    db $51, $00, $14, $67, $74, $23, $57, $89, $88, $76, $78, $9B, $BA, $99, $88, $9A; 11:55D0
    db $BB, $99, $77, $8A, $AB, $BA, $99, $AB, $DE, $EE, $B8, $98, $CE, $EC, $A7, $55; 11:55E0
    db $8A, $CA, $64, $11, $45, $66, $51, $00, $13, $54, $32, $23, $33, $55, $56, $77; 11:55F0
    db $77, $67, $89, $AA, $99, $88, $9A, $AA, $A8, $88, $88, $98, $99, $98, $99, $AA; 11:5600
    db $AB, $CC, $CC, $DD, $A9, $9A, $CD, $EC, $A8, $66, $89, $A8, $64, $23, $33, $33; 11:5610
    db $32, $12, $33, $21, $12, $45, $55, $54, $35, $78, $99, $88, $88, $99, $AA, $A9; 11:5620
    db $9A, $AA, $88, $88, $99, $99, $88, $78, $99, $AA, $AA, $AB, $BC, $DE, $DA, $BA; 11:5630
    db $BB, $CC, $BB, $98, $88, $87, $55, $54, $55, $43, $21, $11, $22, $32, $22, $22; 11:5640
    db $33, $45, $55, $67, $78, $88, $89, $99, $9A, $AA, $AA, $BA, $A9, $99, $99, $98; 11:5650
    db $88, $88, $89, $98, $88, $9A, $BB, $BB, $CC, $ED, $CB, $AA, $AB, $BB, $BA, $98; 11:5660
    db $87, $75, $53, $33, $33, $33, $22, $11, $22, $11, $22, $34, $45, $55, $56, $67; 11:5670
    db $78, $89, $9A, $AA, $BA, $AA, $AA, $A9, $99, $99, $99, $88, $88, $88, $88, $88; 11:5680
    db $88, $9A, $AB, $BB, $BC, $DD, $DC, $BB, $BA, $AA, $A9, $98, $88, $76, $54, $33; 11:5690
    db $22, $22, $11, $12, $22, $22, $22, $33, $44, $55, $67, $78, $99, $9A, $AA, $AA; 11:56A0
    db $BA, $AA, $AA, $AA, $A9, $99, $99, $88, $87, $77, $78, $88, $88, $89, $9A, $AA; 11:56B0
    db $BB, $BB, $BC, $CC, $CC, $CB, $BA, $98, $87, $76, $65, $44, $33, $44, $33, $22; 11:56C0
    db $22, $22, $22, $23, $34, $55, $66, $77, $88, $99, $99, $99, $AA, $AA, $AA, $AA; 11:56D0
    db $AA, $AA, $99, $98, $87, $77, $77, $77, $77, $78, $89, $99, $99, $99, $98, $89; 11:56E0
    db $9A, $BC, $CC, $CB, $BB, $AA, $98, $76, $55, $55, $44, $44, $55, $55, $55, $55; 11:56F0
    db $54, $44, $44, $44, $55, $66, $78, $89, $99, $A9, $99, $99, $98, $89, $99, $A9; 11:5700
    db $99, $99, $99, $88, $76, $66, $66, $55, $67, $88, $99, $88, $88, $88, $88, $89; 11:5710
    db $9A, $AA, $BB, $BB, $BB, $AA, $99, $88, $77, $76, $66, $56, $66, $66, $66, $66; 11:5720
    db $65, $55, $55, $55, $55, $55, $66, $77, $88, $89, $99, $98, $88, $88, $88, $88; 11:5730
    db $88, $88, $88, $88, $77, $77, $76, $66, $67, $78, $88, $88, $88, $88, $89, $99; 11:5740
    db $99, $99, $9A, $AA, $BA, $AB, $BB, $BA, $A9, $99, $88, $87, $77, $67, $77, $76; 11:5750
    db $66, $66, $65, $55, $44, $44, $44, $44, $45, $55, $67, $77, $88, $88, $88, $88; 11:5760
    db $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $78, $88, $88, $88, $88; 11:5770
    db $88, $88, $99, $99, $AA, $AB, $BB, $BC, $BB, $BB, $BB, $AA, $99, $87, $76, $65; 11:5780
    db $55, $55, $55, $44, $55, $44, $44, $44, $44, $44, $44, $55, $66, $77, $89, $9A; 11:5790
    db $99, $99, $99, $98, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $78, $88; 11:57A0
    db $89, $99, $99, $99, $99, $99, $99, $99, $99, $AA, $AB, $BA, $AA, $AA, $99, $88; 11:57B0
    db $76, $65, $55, $44, $45, $55, $55, $56, $66, $55, $55, $55, $55, $55, $56, $67; 11:57C0
    db $78, $89, $9A, $AA, $AA, $A9, $99, $88, $88, $88, $77, $77, $77, $77, $77, $76; 11:57D0
    db $66, $67, $77, $88, $88, $88, $88, $88, $89, $89, $99, $9A, $AA, $AB, $BC, $BB; 11:57E0
    db $BB, $BB, $A9, $87, $76, $54, $43, $34, $44, $44, $55, $66, $66, $66, $66, $65; 11:57F0
    db $66, $66, $77, $88, $99, $AB, $BB, $BB, $BA, $99, $87, $76, $65, $55, $54, $55; 11:5800
    db $44, $55, $55, $55, $56, $67, $78, $9A, $BB, $BB, $BB, $AA, $AA, $AA, $AA, $BC; 11:5810
    db $CD, $EE, $ED, $DD, $CB, $A8, $76, $53, $21, $11, $01, $12, $33, $45, $67, $77; 11:5820
    db $78, $88, $77, $77, $88, $89, $9A, $AB, $BB, $BB, $AA, $98, $76, $54, $33, $22; 11:5830
    db $22, $22, $34, $45, $56, $77, $88, $89, $AB, $BC, $CD, $DD, $DD, $CC, $BB, $AA; 11:5840
    db $BB, $BB, $CE, $EF, $EE, $EC, $CA, $75, $31, $00, $00, $00, $00, $01, $34, $68; 11:5850
    db $9A, $AA, $BB, $BA, $99, $88, $88, $89, $99, $AA, $AA, $98, $87, $64, $32, $11; 11:5860
    db $00, $01, $23, $56, $78, $9A, $BC, $CC, $CC, $CC, $CB, $BB, $AA, $AA, $AA, $AA; 11:5870
    db $AB, $BC, $DE, $FF, $FF, $ED, $CB, $96, $20, $00, $00, $00, $00, $01, $35, $68; 11:5880
    db $AB, $CC, $BB, $CC, $BA, $99, $9A, $99, $99, $99, $98, $76, $43, $22, $10, $00; 11:5890
    db $12, $34, $57, $9A, $BC, $CD, $CC, $CB, $B9, $98, $88, $88, $88, $99, $9A, $AB; 11:58A0
    db $BD, $EE, $FF, $FF, $FF, $EC, $A7, $30, $00, $00, $00, $00, $01, $36, $89, $BD; 11:58B0
    db $DD, $DD, $CC, $CB, $BA, $AA, $AA, $A9, $87, $65, $42, $00, $00, $00, $12, $56; 11:58C0
    db $8A, $CD, $EE, $EE, $DC, $A8, $87, $55, $55, $55, $66, $78, $9A, $BB, $CD, $EF; 11:58D0
    db $FF, $FF, $FF, $FE, $C9, $40, $00, $00, $00, $00, $01, $47, $AB, $DF, $FF, $FE; 11:58E0
    db $DC, $CB, $A9, $89, $98, $87, $64, $32, $10, $00, $00, $02, $46, $9D, $FF, $FF; 11:58F0
    db $FF, $EC, $A8, $64, $23, $33, $34, $56, $78, $88, $9A, $AB, $CD, $EF, $FF, $FF; 11:5900
    db $FF, $FE, $B5, $00, $00, $00, $00, $00, $49, $DF, $FF, $FF, $FF, $C9, $99, $88; 11:5910
    db $88, $88, $87, $64, $10, $00, $00, $00, $04, $9D, $FF, $FF, $FF, $FD, $A7, $42; 11:5920
    db $22, $22, $57, $89, $98, $88, $75, $44, $57, $9B, $FF, $FF, $FF, $FF, $FC, $72; 11:5930
    db $00, $00, $00, $00, $16, $AE, $FF, $FF, $DB, $AA, $98, $8A, $DF, $FE, $DA, $73; 11:5940
    db $00, $00, $00, $00, $26, $BF, $FF, $FF, $FF, $B7, $53, $12, $35, $8B, $CC, $BA; 11:5950
    db $96, $41, $00, $12, $58, $CE, $FF, $FF, $FF, $FF, $FF, $A6, $32, $00, $00, $00; 11:5960
    db $00, $03, $57, $AD, $FF, $FF, $FF, $FF, $EC, $BB, $96, $41, $00, $00, $00, $00; 11:5970
    db $14, $8B, $BD, $FF, $FF, $FE, $CA, $87, $75, $44, $33, $56, $45, $66, $77, $88; 11:5980
    db $8A, $A9, $AC, $BB, $DE, $FF, $FF, $FF, $FF, $83, $00, $00, $00, $00, $05, $BE; 11:5990
    db $EF, $FF, $EB, $98, $BE, $FF, $FF, $EB, $83, $00, $00, $00, $00, $27, $CF, $FF; 11:59A0
    db $FE, $DC, $BA, $AA, $AA, $98, $75, $31, $00, $01, $25, $9B, $DE, $ED, $CA, $86; 11:59B0
    db $78, $9B, $FF, $FF, $FF, $FF, $C3, $00, $00, $00, $00, $37, $AC, $B9, $78, $9A; 11:59C0
    db $BC, $EF, $FF, $FF, $C7, $20, $00, $00, $00, $37, $88, $89, $99, $88, $AD, $FF; 11:59D0
    db $FF, $FE, $A4, $00, $00, $00, $16, $AB, $DE, $CA, $98, $67, $88, $AD, $FF, $FF; 11:59E0
    db $FF, $FF, $FF, $FA, $30, $00, $00, $00, $01, $57, $AA, $99, $BD, $EE, $EE, $FF; 11:59F0
    db $FF, $C8, $52, $00, $00, $00, $02, $55, $56, $79, $CD, $EF, $FF, $FF, $EB, $83; 11:5A00
    db $00, $00, $01, $25, $87, $88, $87, $89, $9B, $CB, $BC, $DD, $DE, $FF, $FF, $FF; 11:5A10
    db $FE, $50, $00, $00, $00, $04, $67, $88, $53, $58, $CF, $FF, $FF, $FF, $B5, $10; 11:5A20
    db $00, $01, $21, $01, $21, $00, $26, $BF, $FF, $FF, $FE, $C8, $63, $12, $45, $54; 11:5A30
    db $21, $22, $35, $68, $9B, $DE, $DC, $98, $AC, $DF, $FF, $FF, $FF, $FB, $20, $00; 11:5A40
    db $00, $00, $12, $33, $22, $12, $6C, $FF, $FF, $FF, $EB, $85, $44, $56, $64, $00; 11:5A50
    db $00, $00, $03, $6A, $EF, $FF, $EC, $CD, $EF, $EA, $86, $54, $20, $00, $14, $67; 11:5A60
    db $87, $67, $8A, $CC, $BC, $EF, $FF, $FF, $FF, $FF, $F8, $00, $00, $00, $00, $00; 11:5A70
    db $12, $22, $24, $AF, $FF, $FF, $ED, $DD, $BA, $98, $76, $51, $00, $00, $01, $34; 11:5A80
    db $56, $8B, $CD, $EE, $FF, $FF, $EB, $86, $65, $54, $33, $33, $34, $44, $57, $9B; 11:5A90
    db $CC, $BC, $EF, $FF, $FF, $FF, $F9, $20, $00, $11, $21, $00, $00, $00, $15, $9E; 11:5AA0
    db $FF, $EC, $BB, $EF, $FF, $FD, $96, $42, $00, $00, $00, $00, $00, $02, $7B, $DE; 11:5AB0
    db $EC, $CD, $DE, $EE, $EE, $C9, $75, $32, $45, $67, $75, $55, $78, $BD, $FF, $FF; 11:5AC0
    db $FF, $A5, $36, $AC, $B8, $30, $00, $00, $12, $24, $57, $65, $46, $AE, $FF, $FD; 11:5AD0
    db $A9, $9B, $CC, $A7, $54, $32, $00, $00, $23, $32, $00, $26, $AD, $ED, $CB, $CD; 11:5AE0
    db $DE, $ED, $CC, $B9, $87, $78, $BC, $DC, $CB, $B8, $42, $36, $AB, $96, $30, $01; 11:5AF0
    db $48, $97, $53, $35, $56, $89, $AB, $CA, $97, $67, $AC, $DB, $85, $33, $56, $77; 11:5B00
    db $64, $44, $45, $54, $45, $66, $77, $67, $89, $AB, $BA, $AB, $BD, $DD, $CB, $BB; 11:5B10
    db $BC, $DD, $DD, $DA, $52, $24, $9C, $A6, $30, $00, $48, $97, $42, $24, $56, $78; 11:5B20
    db $99, $98, $88, $79, $BD, $DB, $86, $57, $89, $97, $52, $23, $56, $64, $22, $35; 11:5B30
    db $67, $87, $66, $77, $89, $9A, $BB, $CC, $CC, $DF, $FF, $FF, $FE, $EA, $55, $58; 11:5B40
    db $BA, $63, $00, $02, $57, $41, $00, $26, $78, $76, $67, $89, $BA, $9A, $BB, $B9; 11:5B50
    db $9A, $BB, $BA, $86, $55, $77, $76, $31, $02, $35, $65, $53, $24, $78, $89, $88; 11:5B60
    db $88, $AB, $CC, $CC, $CD, $EF, $FF, $FF, $D9, $88, $AD, $DA, $62, $01, $46, $64; 11:5B70
    db $00, $00, $45, $54, $21, $25, $8A, $98, $77, $79, $BB, $CC, $CB, $AA, $AB, $BB; 11:5B80
    db $B9, $87, $65, $55, $54, $32, $22, $24, $55, $55, $56, $89, $99, $99, $AB, $CD; 11:5B90
    db $DD, $DE, $FF, $FF, $DB, $AB, $DC, $B8, $65, $56, $76, $41, $00, $12, $32, $11; 11:5BA0
    db $12, $34, $55, $55, $56, $78, $89, $99, $9A, $BC, $CC, $BB, $AA, $BB, $BA, $87; 11:5BB0
    db $66, $76, $55, $44, $45, $55, $55, $67, $88, $88, $99, $AB, $CC, $DE, $DB, $BB; 11:5BC0
    db $CE, $EC, $A9, $89, $AA, $97, $54, $45, $54, $32, $11, $22, $23, $32, $33, $35; 11:5BD0
    db $56, $66, $66, $89, $A9, $98, $88, $AA, $AB, $A9, $99, $89, $A9, $98, $77, $78; 11:5BE0
    db $88, $88, $78, $99, $9A, $AA, $BA, $89, $BC, $CB, $98, $89, $AA, $A8, $65, $77; 11:5BF0
    db $76, $54, $44, $44, $54, $44, $32, $34, $56, $65, $45, $68, $89, $88, $88, $89; 11:5C00
    db $A9, $88, $88, $89, $98, $87, $78, $89, $99, $87, $89, $9A, $AA, $99, $AB, $BC; 11:5C10
    db $B9, $8A, $CD, $CA, $98, $88, $9A, $87, $66, $65, $55, $54, $43, $33, $44, $44; 11:5C20
    db $32, $34, $56, $55, $55, $67, $88, $88, $88, $89, $A9, $99, $88, $9A, $99, $98; 11:5C30
    db $88, $99, $99, $88, $99, $AA, $BA, $9A, $BB, $CB, $A9, $8A, $BB, $A9, $88, $89; 11:5C40
    db $99, $86, $66, $66, $65, $54, $44, $33, $44, $43, $33, $34, $55, $55, $56, $67; 11:5C50
    db $77, $78, $88, $99, $99, $99, $99, $AA, $A9, $A9, $99, $99, $99, $99, $99, $99; 11:5C60
    db $99, $99, $99, $A9, $A9, $98, $79, $99, $99, $88, $88, $88, $87, $77, $77, $66; 11:5C70
    db $66, $55, $54, $44, $44, $44, $43, $44, $55, $55, $56, $66, $77, $78, $88, $88; 11:5C80
    db $99, $99, $99, $99, $99, $99, $99, $99, $99, $99, $99, $99, $89, $98, $99, $99; 11:5C90
    db $99, $99, $99, $98, $89, $89, $99, $88, $88, $88, $88, $87, $77, $66, $66, $55; 11:5CA0
    db $55, $55, $55, $55, $55, $55, $56, $66, $66, $76, $77, $77, $77, $77, $88, $88; 11:5CB0
    db $88, $88, $88, $88, $99, $99, $99, $99, $99, $99, $99, $99, $99, $99, $99, $99; 11:5CC0
    db $99, $99, $99, $99, $99, $88, $88, $88, $88, $88, $87, $77, $66, $66, $66, $66; 11:5CD0
    db $66, $66, $66, $66, $66, $66, $66, $66, $67, $77, $77, $77, $77, $77, $77, $77; 11:5CE0
    db $78, $88, $88, $88, $88, $88, $88, $88, $98, $99, $99, $99, $99, $99, $99, $98; 11:5CF0
    db $88, $88, $88, $88, $88, $88, $88, $87, $77, $88, $87, $78, $88, $88, $88, $88; 11:5D00
    db $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $76, $66, $66, $66, $66, $66; 11:5D10
    db $66, $66, $66, $66, $67, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:5D20
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:5D30
    db $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $77, $77; 11:5D40
    db $77, $77, $77, $87, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $77, $77; 11:5D50
    db $77, $87, $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:5D60
    db $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $77, $77, $88, $88, $88; 11:5D70
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87; 11:5D80
    db $77, $77, $77, $77, $77, $77, $77, $77, $87, $87, $88, $88, $88, $88, $87, $77; 11:5D90
    db $87, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $87, $88; 11:5DA0
    db $88, $87, $88, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $87; 11:5DB0
    db $88, $87, $87, $87, $87, $77, $88, $87, $77, $77, $77, $87, $77, $77, $77, $77; 11:5DC0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $88, $78, $87, $87, $87, $88; 11:5DD0
    db $87, $78, $88, $88, $88, $88, $88, $88, $88, $87, $87, $77, $87, $87, $87, $78; 11:5DE0
    db $77, $77, $77, $77, $77, $77, $78, $87, $66, $87, $87, $87, $88, $87, $88, $88; 11:5DF0
    db $88, $88, $88, $88, $87, $87, $87, $87, $78, $87, $88, $88, $87, $88, $88, $88; 11:5E00
    db $88, $88, $88, $87, $87, $87, $87, $78, $77, $77, $87, $86, $87, $78, $78, $77; 11:5E10
    db $87, $87, $87, $87, $87, $88, $87, $88, $88, $88, $88, $88, $88, $78, $88, $88; 11:5E20
    db $97, $87, $88, $88, $78, $88, $78, $87, $87, $88, $87, $98, $78, $78, $87, $86; 11:5E30
    db $86, $86, $87, $87, $78, $77, $77, $86, $87, $86, $76, $77, $87, $87, $78, $77; 11:5E40
    db $88, $78, $79, $78, $86, $96, $88, $77, $97, $87, $88, $78, $A5, $A6, $A6, $87; 11:5E50
    db $97, $87, $88, $78, $88, $69, $88, $78, $96, $97, $96, $97, $86, $97, $87, $87; 11:5E60
    db $87, $87, $77, $68, $87, $78, $78, $69, $68, $87, $96, $89, $3B, $6A, $4B, $59; 11:5E70
    db $5B, $68, $5B, $85, $88, $76, $A7, $67, $B5, $7A, $77, $78, $86, $89, $68, $5A; 11:5E80
    db $75, $A6, $A3, $C4, $B5, $A7, $78, $88, $78, $79, $78, $5A, $57, $96, $A5, $97; 11:5E90
    db $88, $6A, $76, $A5, $B5, $A6, $88, $87, $7A, $6A, $4C, $4A, $5B, $5A, $68, $79; 11:5EA0
    db $59, $69, $87, $95, $A6, $87, $A4, $95, $A3, $D1, $D4, $95, $B4, $B5, $A4, $B4; 11:5EB0
    db $C4, $A8, $86, $A5, $B2, $D5, $95, $B6, $88, $79, $69, $68, $5B, $2B, $3D, $56; 11:5EC0
    db $C2, $C4, $B5, $B6, $96, $86, $B3, $B5, $A6, $87, $85, $A5, $96, $A5, $B4, $A6; 11:5ED0
    db $96, $98, $78, $88, $78, $78, $6A, $4B, $3C, $2D, $4B, $3B, $77, $97, $A3, $B8; 11:5EE0
    db $86, $8B, $49, $6A, $67, $88, $78, $68, $96, $77, $A3, $D1, $E1, $D2, $E2, $B5; 11:5EF0
    db $B3, $D3, $C3, $C3, $B3, $97, $85, $87, $7B, $3B, $5B, $58, $6B, $49, $4B, $68; 11:5F00
    db $59, $96, $87, $88, $87, $88, $59, $5A, $79, $69, $68, $88, $97, $96, $B6, $97; 11:5F10
    db $89, $4C, $3E, $2D, $3A, $68, $94, $C2, $D3, $B3, $C5, $97, $8A, $58, $99, $67; 11:5F20
    db $97, $77, $A4, $B5, $A4, $A8, $67, $79, $67, $7A, $4A, $67, $86, $97, $96, $A5; 11:5F30
    db $89, $68, $88, $67, $97, $77, $A7, $86, $A7, $58, $87, $94, $E3, $96, $98, $66; 11:5F40
    db $9A, $58, $77, $78, $6A, $67, $97, $68, $89, $67, $98, $78, $87, $88, $7A, $4B; 11:5F50
    db $59, $59, $85, $88, $77, $78, $86, $89, $86, $78, $88, $98, $87, $77, $96, $97; 11:5F60
    db $85, $96, $89, $79, $58, $88, $77, $96, $96, $A6, $89, $76, $A7, $88, $77, $87; 11:5F70
    db $87, $99, $77, $78, $69, $98, $77, $87, $88, $98, $67, $87, $86, $88, $67, $77; 11:5F80
    db $88, $77, $78, $78, $88, $87, $88, $88, $88, $88, $88, $78, $88, $77, $77, $68; 11:5F90
    db $88, $77, $67, $78, $77, $77, $77, $78, $77, $77, $87, $87, $77, $77, $78, $88; 11:5FA0
    db $77, $88, $88, $88, $88, $88, $78, $87, $88, $88, $78, $88, $87, $77, $88, $88; 11:5FB0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $88, $88, $88, $87; 11:5FC0
    db $88, $88, $88, $78, $88, $87, $87, $88, $88, $77, $87, $88, $87, $88, $88, $88; 11:5FD0
    db $88, $88, $87, $88, $78, $78, $77, $77, $77, $87, $77, $88, $78, $88, $88, $88; 11:5FE0
    db $88, $88, $88, $88, $77, $87, $87, $87, $77, $77, $77, $77, $78, $78, $78, $88; 11:5FF0
    db $88, $87, $88, $87, $88, $87, $88, $77, $78, $77, $78, $77, $87, $78, $87, $87; 11:6000
    db $87, $88, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:6010
    db $88, $78, $77, $77, $77, $87, $87, $77, $78, $78, $78, $88, $88, $88, $88, $88; 11:6020
    db $88, $88, $88, $88, $88, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:6030
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $87, $77, $77, $77, $77, $77; 11:6040
    db $77, $77, $77, $77, $77, $77, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:6050
    db $88, $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:6060
    db $88, $88, $88, $88, $88, $88, $88, $87, $87, $77, $77, $77, $77, $77, $77, $77; 11:6070
    db $77, $77, $77, $87, $87, $87, $88, $88, $88, $88, $88, $87, $88, $77, $88, $88; 11:6080
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78; 11:6090
    db $88, $87, $88, $88, $87, $78, $78, $88, $77, $87, $88, $77, $78, $88, $88, $88; 11:60A0
    db $88, $88, $88, $88, $88, $88, $87, $88, $88, $88, $78, $78, $88, $87, $77, $88; 11:60B0
    db $88, $88, $87, $78, $88, $87, $68, $88, $78, $77, $88, $87, $78, $78, $88, $77; 11:60C0
    db $88, $88, $77, $77, $87, $78, $78, $88, $78, $78, $78, $88, $87, $88, $88, $88; 11:60D0
    db $88, $88, $88, $88, $88, $78, $88, $87, $77, $88, $87, $88, $87, $87, $88, $88; 11:60E0
    db $87, $87, $88, $88, $87, $88, $88, $88, $77, $88, $88, $87, $88, $88, $88, $88; 11:60F0
    db $78, $88, $88, $87, $87, $87, $87, $88, $77, $78, $78, $78, $78, $78, $78, $78; 11:6100
    db $88, $77, $87, $77, $87, $88, $87, $78, $87, $77, $87, $87, $87, $88, $77, $78; 11:6110
    db $88, $87, $78, $78, $78, $77, $78, $78, $87, $88, $88, $77, $88, $78, $87, $88; 11:6120
    db $78, $87, $78, $88, $78, $88, $87, $86, $89, $77, $88, $87, $87, $88, $87, $88; 11:6130
    db $87, $77, $77, $88, $77, $88, $78, $77, $77, $78, $78, $87, $78, $87, $78, $87; 11:6140
    db $88, $78, $88, $78, $88, $77, $78, $76, $77, $88, $87, $87, $97, $87, $97, $87; 11:6150
    db $86, $88, $88, $87, $88, $78, $78, $78, $78, $87, $88, $88, $87, $87, $87, $87; 11:6160
    db $87, $86, $96, $87, $87, $87, $88, $87, $77, $88, $77, $78, $78, $68, $78, $77; 11:6170
    db $88, $88, $77, $88, $98, $85, $88, $A7, $76, $88, $98, $77, $79, $78, $78, $77; 11:6180
    db $89, $77, $78, $79, $88, $68, $87, $78, $87, $77, $89, $86, $87, $98, $77, $88; 11:6190
    db $87, $78, $68, $98, $76, $69, $79, $75, $78, $98, $66, $88, $97, $77, $88, $77; 11:61A0
    db $77, $77, $99, $75, $69, $98, $67, $78, $88, $77, $89, $68, $77, $88, $87, $78; 11:61B0
    db $88, $67, $88, $88, $77, $68, $98, $76, $78, $88, $66, $7A, $86, $67, $89, $86; 11:61C0
    db $67, $99, $87, $57, $99, $97, $56, $8A, $96, $57, $89, $97, $57, $89, $97, $77; 11:61D0
    db $78, $98, $86, $79, $96, $78, $98, $67, $88, $87, $68, $78, $77, $79, $77, $88; 11:61E0
    db $87, $68, $78, $89, $77, $88, $88, $87, $78, $89, $86, $79, $89, $76, $79, $97; 11:61F0
    db $66, $78, $98, $77, $68, $98, $76, $78, $98, $76, $78, $88, $77, $78, $88, $88; 11:6200
    db $77, $88, $87, $88, $87, $78, $88, $77, $77, $87, $77, $88, $77, $88, $87, $88; 11:6210
    db $87, $77, $88, $87, $68, $98, $78, $77, $87, $88, $78, $77, $88, $87, $87, $88; 11:6220
    db $88, $87, $77, $88, $87, $77, $89, $87, $78, $88, $77, $78, $88, $77, $77, $88; 11:6230
    db $87, $68, $88, $86, $78, $98, $77, $78, $87, $78, $77, $78, $87, $78, $88, $77; 11:6240
    db $88, $87, $77, $88, $77, $67, $78, $77, $77, $77, $77, $78, $78, $77, $77, $88; 11:6250
    db $88, $78, $99, $88, $89, $99, $99, $A9, $99, $AA, $AA, $AA, $AB, $BA, $AA, $AA; 11:6260
    db $98, $78, $99, $96, $55, $66, $55, $54, $43, $22, $23, $22, $22, $11, $22, $45; 11:6270
    db $43, $34, $56, $66, $77, $77, $89, $AA, $AA, $BA, $AA, $BC, $CC, $BB, $BC, $CC; 11:6280
    db $CC, $CC, $BC, $CC, $DC, $DD, $DD, $DE, $D7, $8A, $BF, $D7, $35, $78, $67, $55; 11:6290
    db $31, $01, $34, $10, $12, $00, $00, $35, $30, $02, $34, $56, $87, $55, $59, $BA; 11:62A0
    db $89, $AB, $99, $9B, $DC, $A9, $AA, $AA, $BB, $B9, $88, $9B, $BA, $99, $99, $9A; 11:62B0
    db $BC, $CB, $BC, $DE, $EB, $6A, $AE, $FC, $76, $79, $89, $97, $63, $12, $45, $40; 11:62C0
    db $02, $21, $00, $14, $42, $01, $22, $34, $77, $64, $45, $9A, $97, $99, $99, $9B; 11:62D0
    db $CC, $A9, $AB, $BB, $AB, $BA, $A8, $9A, $BB, $99, $99, $99, $AB, $BB, $AA, $BD; 11:62E0
    db $EE, $D6, $88, $BF, $EB, $65, $67, $8A, $97, $40, $12, $56, $30, $11, $10, $01; 11:62F0
    db $23, $22, $23, $23, $36, $88, $65, $57, $AA, $AA, $A8, $89, $BD, $DB, $98, $9B; 11:6300
    db $BB, $BA, $99, $89, $8A, $A8, $88, $98, $88, $9B, $BA, $AA, $BC, $DE, $E8, $88; 11:6310
    db $AE, $FD, $96, $66, $7B, $A9, $62, $01, $47, $52, $10, $00, $12, $23, $20, $12; 11:6320
    db $33, $35, $57, $66, $56, $79, $AA, $B9, $88, $9B, $CD, $CA, $99, $AB, $BC, $BA; 11:6330
    db $88, $79, $AA, $98, $87, $88, $9A, $BA, $99, $9B, $CD, $DE, $B7, $88, $CF, $FC; 11:6340
    db $86, $56, $8B, $BA, $51, $01, $47, $64, $20, $00, $02, $55, $31, $01, $24, $46; 11:6350
    db $66, $65, $56, $8A, $9A, $A9, $99, $89, $CD, $DB, $A9, $9A, $AB, $CB, $97, $67; 11:6360
    db $8A, $A9, $76, $66, $68, $AA, $98, $78, $9B, $CD, $DD, $DA, $69, $9E, $FF, $B8; 11:6370
    db $65, $58, $CC, $B5, $10, $04, $77, $64, $00, $00, $26, $64, $00, $01, $35, $77; 11:6380
    db $64, $44, $68, $99, $AA, $99, $99, $BC, $CC, $BB, $BA, $99, $BB, $CB, $97, $77; 11:6390
    db $78, $99, $86, $55, $67, $89, $88, $87, $78, $AC, $DC, $CC, $CA, $8A, $AE, $FE; 11:63A0
    db $B9, $76, $68, $AC, $B6, $30, $13, $66, $64, $10, $00, $15, $54, $20, $01, $23; 11:63B0
    db $56, $65, $44, $68, $88, $AA, $BB, $AA, $BB, $BB, $CD, $DC, $A9, $9A, $BB, $AA; 11:63C0
    db $97, $65, $68, $88, $65, $55, $66, $78, $87, $77, $89, $9A, $AB, $CD, $DE, $EC; 11:63D0
    db $AA, $AD, $FF, $EB, $87, $67, $9B, $B8, $51, $01, $34, $54, $20, $00, $01, $33; 11:63E0
    db $21, $11, $12, $44, $56, $67, $88, $88, $89, $BC, $DC, $CB, $BB, $BC, $ED, $CB; 11:63F0
    db $A9, $9A, $AA, $98, $76, $66, $66, $55, $55, $55, $56, $65, $67, $78, $98, $89; 11:6400
    db $9A, $BC, $DD, $DD, $EE, $FE, $CB, $AB, $DD, $DB, $A8, $65, $67, $86, $42, $11; 11:6410
    db $11, $22, $10, $00, $02, $21, $00, $12, $34, $55, $55, $57, $8A, $AA, $AA, $BB; 11:6420
    db $CC, $CC, $CC, $CD, $DD, $CB, $AA, $AA, $BA, $98, $76, $66, $66, $55, $55, $55; 11:6430
    db $54, $44, $45, $67, $77, $77, $88, $9A, $BB, $BB, $CC, $DE, $EE, $EF, $FD, $CB; 11:6440
    db $BB, $CC, $BB, $A8, $66, $55, $54, $22, $22, $20, $00, $00, $00, $01, $10, $01; 11:6450
    db $12, $34, $56, $77, $88, $9A, $AA, $BC, $CD, $DE, $EE, $DD, $DD, $ED, $CC, $BB; 11:6460
    db $AA, $99, $88, $76, $66, $54, $44, $33, $44, $44, $44, $44, $56, $67, $78, $99; 11:6470
    db $AA, $AB, $BB, $CD, $EE, $EE, $EF, $FF, $FF, $ED, $BB, $AB, $BA, $98, $86, $54; 11:6480
    db $43, $20, $00, $00, $00, $00, $00, $00, $00, $01, $12, $44, $55, $67, $79, $AB; 11:6490
    db $CC, $CC, $DE, $EE, $FF, $FF, $EE, $EE, $ED, $CB, $AA, $A9, $87, $66, $54, $44; 11:64A0
    db $32, $22, $22, $22, $22, $33, $45, $66, $67, $88, $AA, $BB, $BC, $DD, $EE, $EE; 11:64B0
    db $EE, $EE, $EE, $EE, $EE, $EE, $EE, $CB, $87, $66, $65, $54, $42, $21, $20, $00; 11:64C0
    db $00, $00, $00, $00, $01, $12, $23, $33, $46, $89, $AA, $BB, $BB, $CC, $DD, $DD; 11:64D0
    db $DE, $EE, $ED, $CB, $BB, $AA, $A9, $88, $88, $87, $65, $43, $32, $22, $22, $23; 11:64E0
    db $34, $44, $45, $55, $67, $78, $89, $AA, $BC, $CC, $CD, $DD, $DD, $DD, $DD, $DD; 11:64F0
    db $DD, $CC, $BB, $BB, $BB, $BB, $BB, $A9, $88, $66, $45, $34, $22, $23, $32, $21; 11:6500
    db $10, $00, $00, $01, $12, $24, $45, $56, $67, $77, $88, $88, $9A, $BB, $BB, $BB; 11:6510
    db $BC, $CB, $BB, $AA, $AA, $AA, $A9, $88, $88, $77, $76, $65, $55, $55, $55, $55; 11:6520
    db $55, $66, $66, $78, $88, $99, $99, $99, $9A, $AA, $AA, $BB, $BB, $BA, $AA, $99; 11:6530
    db $99, $99, $99, $99, $99, $99, $99, $99, $9A, $A9, $99, $98, $88, $76, $55, $55; 11:6540
    db $56, $55, $55, $55, $54, $44, $43, $44, $44, $44, $44, $55, $55, $66, $66, $77; 11:6550
    db $77, $77, $77, $88, $88, $88, $88, $99, $99, $99, $99, $99, $99, $99, $99, $99; 11:6560
    db $99, $99, $99, $99, $98, $88, $88, $88, $88, $88, $88, $88, $88, $87, $78, $88; 11:6570
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $89, $99, $99, $99, $99, $99; 11:6580
    db $99, $99, $98, $88, $88, $87, $77, $77, $66, $66, $65, $55, $55, $55, $54, $44; 11:6590
    db $44, $44, $45, $55, $55, $55, $55, $56, $66, $66, $67, $77, $88, $88, $89, $99; 11:65A0
    db $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $99, $99, $99, $98, $88; 11:65B0
    db $88, $88, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $88, $88, $88; 11:65C0
    db $88, $99, $99, $99, $99, $99, $99, $99, $88, $88, $88, $88, $77, $77, $76, $66; 11:65D0
    db $66, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $66, $66, $77; 11:65E0
    db $77, $88, $88, $89, $99, $99, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $A9, $99; 11:65F0
    db $99, $99, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77; 11:6600
    db $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $99, $89, $99; 11:6610
    db $99, $88, $88, $88, $88, $88, $87, $77, $77, $76, $66, $66, $65, $55, $55, $55; 11:6620
    db $55, $55, $55, $55, $66, $66, $66, $66, $66, $67, $77, $77, $88, $88, $88, $99; 11:6630
    db $99, $99, $99, $99, $AA, $A9, $AA, $AA, $99, $99, $99, $99, $98, $88, $88, $88; 11:6640
    db $88, $88, $88, $88, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77; 11:6650
    db $78, $88, $88, $88, $88, $88, $88, $88, $88, $98, $88, $88, $88, $88, $88, $88; 11:6660
    db $88, $88, $77, $77, $77, $77, $66, $66, $66, $66, $65, $55, $55, $55, $56, $66; 11:6670
    db $66, $66, $66, $66, $66, $66, $77, $77, $77, $78, $88, $88, $88, $88, $99, $99; 11:6680
    db $99, $99, $99, $99, $99, $99, $99, $99, $99, $99, $99, $98, $88, $88, $88, $88; 11:6690
    db $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77; 11:66A0
    db $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:66B0
    db $88, $88, $88, $77, $77, $77, $77, $66, $66, $66, $66, $66, $66, $66, $66, $66; 11:66C0
    db $66, $66, $66, $66, $66, $77, $77, $77, $77, $88, $86, $88, $88, $88, $98, $99; 11:66D0
    db $99, $88, $99, $99, $A9, $A9, $99, $99, $99, $88, $88, $99, $99, $99, $88, $88; 11:66E0
    db $88, $87, $87, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $78, $88, $88; 11:66F0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $99, $99, $AA, $AA, $AA, $AA, $98; 11:6700
    db $88, $76, $55, $54, $44, $55, $45, $55, $55, $55, $44, $55, $55, $56, $78, $88; 11:6710
    db $88, $88, $88, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:6720
    db $99, $99, $99, $98, $98, $88, $88, $88, $88, $88, $88, $88, $88, $78, $88, $88; 11:6730
    db $88, $88, $99, $88, $88, $99, $98, $99, $99, $AA, $AA, $AA, $AA, $AA, $AA, $BB; 11:6740
    db $CC, $DE, $EE, $DA, $96, $53, $10, $00, $00, $00, $02, $24, $45, $44, $44, $44; 11:6750
    db $56, $78, $AB, $DE, $ED, $DC, $B9, $86, $43, $23, $23, $34, $56, $67, $87, $77; 11:6760
    db $77, $77, $78, $9B, $CD, $EE, $EE, $ED, $CA, $98, $75, $55, $54, $45, $56, $66; 11:6770
    db $66, $66, $66, $77, $89, $9A, $BB, $BB, $BB, $AA, $98, $87, $77, $77, $88, $89; 11:6780
    db $99, $99, $99, $AA, $AB, $BB, $CD, $EE, $EF, $FF, $FF, $EA, $85, $30, $00, $00; 11:6790
    db $00, $00, $00, $15, $66, $67, $77, $88, $99, $9B, $DE, $FF, $FF, $EC, $B9, $52; 11:67A0
    db $00, $00, $00, $00, $25, $79, $AA, $BB, $CC, $BB, $BB, $CE, $FF, $FF, $FF, $EC; 11:67B0
    db $A8, $54, $21, $00, $00, $23, $45, $68, $99, $AB, $AA, $AA, $BB, $BB, $BB, $BB; 11:67C0
    db $B9, $87, $65, $54, $34, $45, $67, $99, $AB, $CC, $CC, $BB, $CC, $CC, $DD, $DE; 11:67D0
    db $EF, $EF, $FF, $ED, $84, $20, $00, $00, $00, $00, $00, $15, $9B, $BB, $CC, $BA; 11:67E0
    db $BC, $BA, $AD, $DE, $DD, $B9, $76, $40, $00, $00, $00, $00, $37, $AD, $FF, $FF; 11:67F0
    db $FF, $FE, $DC, $BB, $CC, $BA, $AB, $A8, $65, $21, $00, $00, $00, $36, $8A, $CE; 11:6800
    db $FF, $FF, $ED, $BA, $98, $77, $77, $77, $76, $55, $55, $43, $33, $56, $78, $AB; 11:6810
    db $DE, $EF, $ED, $CC, $BA, $A9, $99, $AA, $BB, $BB, $BB, $CB, $CC, $B8, $44, $21; 11:6820
    db $00, $00, $00, $00, $02, $6A, $AA, $AB, $BA, $AA, $B9, $99, $BB, $BA, $A9, $76; 11:6830
    db $53, $00, $00, $00, $02, $58, $AD, $EF, $FF, $FF, $EC, $BA, $99, $99, $98, $88; 11:6840
    db $87, $64, $32, $21, $22, $34, $79, $BC, $DE, $FF, $ED, $CA, $88, $76, $55, $55; 11:6850
    db $66, $66, $55, $55, $55, $45, $78, $9A, $BC, $DD, $DD, $CB, $AA, $98, $88, $88; 11:6860
    db $99, $9A, $99, $AA, $99, $9A, $AC, $DF, $FF, $C9, $85, $40, $00, $00, $00, $00; 11:6870
    db $06, $AC, $CC, $DE, $CB, $BB, $98, $9B, $BC, $AA, $98, $75, $20, $00, $00, $00; 11:6880
    db $15, $8B, $EF, $FF, $FF, $FE, $BA, $98, $88, $87, $67, $88, $64, $22, $22, $12; 11:6890
    db $24, $69, $CD, $EF, $FF, $FE, $C9, $86, $65, $54, $45, $56, $66, $55, $66, $65; 11:68A0
    db $66, $89, $AB, $CC, $DD, $CC, $A9, $87, $77, $77, $78, $9A, $A9, $98, $88, $88; 11:68B0
    db $88, $9A, $BD, $EF, $FF, $FF, $F9, $52, $00, $00, $00, $00, $01, $37, $BE, $FE; 11:68C0
    db $DD, $BA, $AA, $A9, $8A, $CC, $C9, $86, $42, $00, $00, $00, $01, $48, $CF, $FF; 11:68D0
    db $FF, $FF, $FC, $A8, $65, $66, $76, $66, $67, $64, $22, $22, $35, $68, $BD, $FF; 11:68E0
    db $FF, $FF, $DB, $85, $31, $12, $12, $23, $56, $78, $77, $88, $9A, $AA, $BC, $DD; 11:68F0
    db $DC, $BA, $A9, $76, $55, $56, $67, $78, $9A, $AA, $98, $88, $88, $99, $AB, $CE; 11:6900
    db $ED, $DC, $CB, $A9, $99, $97, $41, $00, $00, $00, $00, $00, $14, $8B, $EF, $FF; 11:6910
    db $FE, $DC, $CA, $76, $56, $54, $32, $22, $10, $00, $00, $23, $58, $BD, $FF, $FF; 11:6920
    db $FF, $FE, $DA, $86, $55, $54, $44, $45, $55, $55, $55, $67, $89, $AB, $CE, $EE; 11:6930
    db $DC, $BA, $97, $53, $32, $22, $34, $56, $89, $AA, $AA, $BB, $BA, $A9, $99, $98; 11:6940
    db $87, $77, $76, $65, $66, $77, $89, $9A, $BB, $BB, $AA, $AA, $99, $88, $99, $99; 11:6950
    db $99, $99, $88, $77, $66, $77, $9B, $CB, $97, $65, $30, $00, $00, $00, $14, $7B; 11:6960
    db $DE, $ED, $BA, $87, $65, $32, $46, $87, $77, $78, $75, $31, $12, $34, $68, $BD; 11:6970
    db $FF, $FF, $FE, $CB, $86, $32, $23, $45, $56, $78, $98, $88, $77, $78, $89, $9B; 11:6980
    db $CE, $ED, $CB, $A9, $75, $32, $22, $34, $56, $78, $AA, $BA, $99, $99, $98, $88; 11:6990
    db $99, $99, $88, $87, $76, $65, $66, $78, $99, $AA, $BB, $A9, $88, $87, $77, $78; 11:69A0
    db $89, $AA, $AA, $A9, $98, $88, $77, $78, $89, $9B, $CE, $EA, $73, $31, $00, $00; 11:69B0
    db $00, $03, $59, $CE, $FF, $EC, $98, $77, $65, $45, $7A, $A8, $76, $65, $31, $00; 11:69C0
    db $01, $47, $9B, $DF, $FF, $FF, $CA, $98, $64, $33, $56, $77, $88, $88, $87, $65; 11:69D0
    db $55, $78, $AA, $BD, $EE, $EC, $A8, $75, $43, $22, $34, $68, $89, $AA, $BB, $A8; 11:69E0
    db $87, $88, $88, $88, $99, $98, $87, $66, $66, $66, $78, $9A, $BB, $AA, $AA, $88; 11:69F0
    db $76, $67, $88, $89, $AA, $BA, $99, $88, $77, $77, $78, $99, $99, $99, $88, $87; 11:6A00
    db $88, $AC, $A8, $54, $53, $10, $00, $00, $01, $48, $AC, $EE, $FD, $BA, $99, $75; 11:6A10
    db $44, $68, $76, $56, $66, $53, $22, $24, $57, $9A, $CE, $FF, $FE, $DB, $A8, $64; 11:6A20
    db $32, $34, $55, $67, $88, $99, $98, $78, $89, $99, $9A, $BC, $BB, $A9, $87, $65; 11:6A30
    db $44, $45, $67, $77, $89, $99, $98, $88, $88, $87, $88, $88, $88, $87, $78, $88; 11:6A40
    db $77, $89, $99, $99, $99, $98, $87, $77, $78, $88, $99, $AA, $AA, $A9, $98, $88; 11:6A50
    db $77, $77, $77, $77, $77, $77, $77, $66, $78, $89, $AB, $CB, $97, $54, $20, $00; 11:6A60
    db $00, $01, $36, $9B, $CD, $DD, $BA, $98, $77, $65, $67, $88, $77, $66, $54, $32; 11:6A70
    db $33, $46, $8A, $CD, $FF, $FF, $DB, $A8, $75, $43, $44, $56, $78, $88, $99, $88; 11:6A80
    db $87, $88, $99, $AA, $BB, $BB, $A9, $87, $65, $44, $44, $56, $78, $99, $99, $98; 11:6A90
    db $87, $77, $77, $88, $99, $99, $99, $88, $77, $66, $67, $78, $89, $99, $99, $98; 11:6AA0
    db $87, $78, $88, $89, $AA, $AA, $A9, $98, $76, $65, $55, $56, $67, $77, $88, $77; 11:6AB0
    db $77, $77, $77, $78, $99, $AB, $CC, $B9, $75, $31, $00, $00, $01, $35, $7A, $CE; 11:6AC0
    db $EE, $DC, $A9, $87, $66, $66, $78, $88, $77, $65, $43, $23, $45, $78, $AC, $EF; 11:6AD0
    db $FF, $EC, $B9, $76, $43, $33, $45, $67, $78, $99, $98, $88, $88, $99, $AA, $BB; 11:6AE0
    db $BB, $A9, $87, $65, $43, $34, $56, $67, $89, $AA, $AA, $98, $88, $88, $87, $88; 11:6AF0
    db $99, $88, $88, $77, $66, $66, $78, $88, $89, $99, $98, $88, $77, $88, $88, $99; 11:6B00
    db $AA, $A9, $98, $87, $66, $66, $66, $67, $77, $88, $88, $77, $77, $88, $88, $88; 11:6B10
    db $98, $88, $88, $88, $9A, $98, $65, $54, $30, $00, $02, $34, $68, $BD, $EE, $DC; 11:6B20
    db $CA, $98, $65, $44, $56, $66, $55, $66, $65, $44, $56, $78, $9A, $CD, $EE, $EC; 11:6B30
    db $BA, $97, $64, $33, $34, $55, $67, $89, $A9, $99, $99, $99, $99, $9A, $AA, $A9; 11:6B40
    db $88, $76, $55, $44, $56, $67, $88, $9A, $AA, $99, $88, $77, $76, $67, $78, $88; 11:6B50
    db $88, $88, $87, $77, $88, $88, $99, $9A, $99, $88, $88, $87, $78, $88, $89, $99; 11:6B60
    db $99, $88, $87, $66, $66, $67, $78, $89, $99, $99, $88, $77, $66, $56, $66, $77; 11:6B70
    db $88, $89, $9A, $AB, $B9, $75, $44, $31, $00, $03, $55, $67, $9C, $DC, $BA, $99; 11:6B80
    db $88, $77, $67, $78, $88, $76, $66, $65, $43, $46, $78, $8A, $BD, $EE, $DB, $A9; 11:6B90
    db $97, $65, $44, $55, $67, $77, $89, $99, $88, $89, $99, $99, $9A, $AA, $98, $87; 11:6BA0
    db $76, $55, $45, $56, $77, $88, $9A, $AA, $99, $98, $88, $76, $67, $77, $76, $77; 11:6BB0
    db $77, $77, $78, $88, $99, $99, $99, $99, $88, $88, $88, $88, $88, $99, $98, $88; 11:6BC0
    db $88, $76, $66, $66, $66, $67, $88, $88, $88, $88, $87, $77, $77, $77, $77, $78; 11:6BD0
    db $88, $88, $88, $9A, $A9, $75, $55, $42, $00, $03, $55, $56, $9C, $DD, $BB, $AA; 11:6BE0
    db $A8, $76, $66, $77, $87, $76, $66, $65, $43, $46, $78, $89, $BC, $EE, $DC, $BA; 11:6BF0
    db $A8, $65, $44, $45, $55, $67, $89, $99, $88, $89, $99, $98, $9A, $BA, $A9, $98; 11:6C00
    db $87, $55, $44, $55, $56, $78, $9A, $AB, $AA, $A9, $98, $77, $77, $77, $77, $77; 11:6C10
    db $77, $77, $77, $88, $88, $99, $9A, $A9, $99, $88, $87, $77, $77, $88, $88, $88; 11:6C20
    db $88, $77, $76, $66, $77, $77, $88, $88, $98, $88, $87, $76, $66, $66, $67, $78; 11:6C30
    db $88, $88, $99, $9A, $BA, $98, $65, $54, $20, $00, $23, $45, $68, $BC, $CB, $BB; 11:6C40
    db $BA, $98, $77, $77, $77, $77, $66, $65, $54, $44, $56, $78, $9A, $CD, $DD, $DC; 11:6C50
    db $CB, $97, $65, $55, $55, $55, $77, $88, $88, $99, $99, $99, $99, $AA, $AA, $A9; 11:6C60
    db $98, $86, $55, $55, $55, $56, $78, $99, $AA, $AA, $A9, $88, $77, $66, $66, $66; 11:6C70
    db $77, $77, $77, $77, $88, $88, $99, $99, $9A, $99, $88, $87, $77, $77, $78, $88; 11:6C80
    db $88, $88, $87, $77, $67, $77, $78, $88, $88, $88, $87, $76, $66, $66, $67, $77; 11:6C90
    db $78, $88, $88, $87, $77, $88, $9A, $A9, $88, $76, $53, $10, $12, $23, $46, $8A; 11:6CA0
    db $CC, $CB, $CC, $B9, $87, $77, $76, $66, $77, $87, $76, $65, $55, $56, $78, $9B; 11:6CB0
    db $CC, $DD, $DD, $CA, $87, $65, $54, $34, $45, $67, $78, $99, $A9, $99, $99, $99; 11:6CC0
    db $99, $99, $99, $88, $77, $76, $65, $55, $66, $77, $88, $9A, $AA, $99, $88, $87; 11:6CD0
    db $76, $66, $67, $77, $78, $88, $88, $88, $88, $88, $88, $89, $88, $88, $88, $77; 11:6CE0
    db $77, $77, $78, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $78, $88, $77; 11:6CF0
    db $77, $77, $77, $77, $88, $88, $88, $88, $99, $A9, $98, $87, $65, $42, $22, $23; 11:6D00
    db $34, $57, $9A, $AA, $BB, $BB, $A8, $88, $87, $76, $77, $77, $77, $66, $66, $55; 11:6D10
    db $56, $78, $89, $AB, $BC, $CB, $BA, $98, $76, $65, $55, $56, $67, $78, $99, $99; 11:6D20
    db $99, $99, $88, $88, $89, $88, $88, $88, $87, $77, $66, $66, $66, $77, $88, $88; 11:6D30
    db $99, $98, $88, $77, $77, $66, $67, $77, $88, $88, $88, $88, $88, $88, $88, $88; 11:6D40
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77; 11:6D50
    db $77, $77, $88, $88, $88, $88, $77, $77, $76, $77, $78, $88, $89, $AA, $99, $88; 11:6D60
    db $76, $54, $33, $33, $33, $45, $78, $99, $9A, $BB, $A9, $98, $98, $87, $77, $88; 11:6D70
    db $77, $67, $76, $65, $56, $67, $78, $89, $AB, $BB, $BB, $BA, $A9, $87, $76, $66; 11:6D80
    db $66, $66, $77, $88, $88, $88, $88, $88, $89, $99, $99, $99, $98, $88, $77, $76; 11:6D90
    db $66, $66, $66, $67, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:6DA0
    db $88, $87, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:6DB0
    db $88, $77, $77, $77, $77, $77, $78, $88, $88, $88, $88, $77, $77, $77, $77, $77; 11:6DC0
    db $78, $88, $99, $88, $88, $76, $54, $44, $44, $44, $56, $77, $88, $99, $AA, $99; 11:6DD0
    db $98, $88, $88, $88, $88, $88, $77, $77, $76, $66, $66, $77, $78, $89, $AA, $AB; 11:6DE0
    db $BB, $AA, $98, $88, $77, $76, $67, $77, $77, $88, $88, $88, $88, $88, $88, $88; 11:6DF0
    db $99, $99, $99, $88, $87, $77, $66, $66, $66, $66, $77, $78, $88, $88, $88, $88; 11:6E00
    db $88, $88, $88, $77, $77, $77, $77, $77, $77, $77, $77, $78, $88, $88, $88, $88; 11:6E10
    db $88, $88, $88, $87, $77, $77, $77, $78, $88, $88, $88, $88, $88, $77, $77, $77; 11:6E20
    db $77, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $65, $55, $55, $54, $55; 11:6E30
    db $66, $77, $88, $99, $99, $99, $99, $88, $88, $88, $77, $77, $77, $77, $77, $77; 11:6E40
    db $77, $77, $88, $89, $99, $9A, $AA, $A9, $99, $88, $87, $77, $66, $66, $77, $77; 11:6E50
    db $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $66, $66, $66, $66; 11:6E60
    db $67, $78, $88, $89, $99, $88, $88, $88, $77, $77, $77, $78, $88, $88, $88, $88; 11:6E70
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:6E80
    db $88, $88, $77, $77, $77, $77, $77, $77, $77, $88, $77, $77, $77, $77, $77, $88; 11:6E90
    db $88, $88, $88, $77, $66, $55, $55, $55, $55, $67, $78, $88, $99, $99, $88, $88; 11:6EA0
    db $87, $77, $77, $77, $78, $88, $87, $77, $77, $77, $78, $88, $89, $99, $99, $99; 11:6EB0
    db $98, $88, $87, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:6EC0
    db $88, $88, $88, $88, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $87; 11:6ED0
    db $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $88, $88, $88, $88, $88; 11:6EE0
    db $88, $88, $88, $87, $77, $87, $77, $77, $77, $77, $77, $77, $77, $77, $78, $88; 11:6EF0
    db $87, $77, $77, $77, $77, $78, $88, $88, $88, $88, $77, $77, $77, $76, $66, $67; 11:6F00
    db $77, $77, $78, $88, $88, $87, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88; 11:6F10
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:6F20
    db $87, $87, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77; 11:6F30
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77; 11:6F40
    db $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77; 11:6F50
    db $77, $77, $77, $77, $77, $77, $88, $78, $87, $77, $77, $77, $77, $77, $77, $77; 11:6F60
    db $77, $78, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:6F70
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:6F80
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:6F90
    db $88, $88, $88, $88, $87, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $87; 11:6FA0
    db $87, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77; 11:6FB0
    db $77, $77, $77, $77, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $78; 11:6FC0
    db $88, $88, $87, $87, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $88; 11:6FD0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $88, $88, $88, $88, $88, $88; 11:6FE0
    db $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $77, $77, $78, $88; 11:6FF0

;; PCM01: 2768 bytes = 5536 4-bit samples (rate 2) for SFXInst14
PCM01:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $87; 11:7000
    db $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:7010
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $88, $88, $88, $88; 11:7020
    db $88, $88, $88, $88, $87, $88, $88, $88, $78, $78, $87, $78, $78, $77, $88, $78; 11:7030
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:7040
    db $88, $88, $88, $88, $88, $88, $88, $87, $78, $88, $88, $77, $77, $88, $77, $88; 11:7050
    db $88, $88, $88, $88, $88, $88, $88, $88, $78, $88, $87, $88, $87, $88, $87, $77; 11:7060
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $88, $78, $78, $78, $77; 11:7070
    db $77, $77, $78, $88, $88, $78, $78, $88, $88, $88, $88, $78, $78, $88, $88, $88; 11:7080
    db $88, $88, $88, $88, $88, $88, $88, $88, $87, $87, $88, $78, $87, $78, $78, $88; 11:7090
    db $78, $87, $87, $88, $87, $88, $87, $87, $88, $88, $77, $87, $78, $87, $88, $88; 11:70A0
    db $87, $88, $78, $78, $78, $87, $88, $88, $78, $88, $87, $88, $88, $78, $78, $78; 11:70B0
    db $87, $88, $77, $78, $77, $87, $88, $77, $88, $78, $77, $88, $77, $88, $78, $77; 11:70C0
    db $88, $87, $87, $88, $77, $87, $88, $87, $88, $77, $88, $88, $88, $88, $88, $87; 11:70D0
    db $78, $88, $88, $88, $88, $88, $88, $77, $78, $87, $88, $88, $88, $88, $88, $98; 11:70E0
    db $87, $77, $66, $55, $55, $55, $55, $67, $78, $88, $99, $88, $89, $89, $99, $99; 11:70F0
    db $99, $AA, $AA, $99, $99, $99, $88, $88, $87, $88, $88, $87, $77, $77, $8A, $CB; 11:7100
    db $10, $20, $52, $00, $17, $8A, $A7, $BD, $CC, $86, $46, $85, $65, $59, $CD, $BB; 11:7110
    db $BB, $CB, $85, $33, $56, $66, $79, $BC, $CA, $A9, $99, $98, $78, $99, $AA, $99; 11:7120
    db $99, $98, $77, $66, $67, $79, $DD, $30, $10, $16, $01, $02, $7A, $FC, $89, $78; 11:7130
    db $A7, $42, $24, $7B, $CB, $BB, $DE, $DB, $85, $55, $77, $76, $67, $9A, $A9, $87; 11:7140
    db $88, $88, $87, $89, $AB, $BA, $AA, $AA, $A9, $87, $66, $77, $77, $77, $9B, $FB; 11:7150
    db $02, $00, $53, $18, $11, $8B, $FF, $E9, $26, $43, $95, $25, $47, $EF, $FD, $B8; 11:7160
    db $7A, $87, $72, $35, $59, $BA, $A8, $77, $89, $88, $76, $88, $9B, $AA, $A9, $AB; 11:7170
    db $BB, $A8, $66, $76, $88, $77, $88, $DF, $74, $40, $03, $07, $81, $65, $6C, $EF; 11:7180
    db $B9, $70, $45, $3A, $74, $86, $8D, $EF, $DB, $75, $75, $79, $56, $64, $89, $9B; 11:7190
    db $98, $78, $88, $A9, $89, $78, $AA, $BC, $AA, $99, $99, $98, $77, $67, $9C, $D6; 11:71A0
    db $53, $00, $10, $95, $27, $25, $8A, $DB, $D9, $48, $34, $A6, $89, $46, $88, $BC; 11:71B0
    db $EB, $A9, $58, $76, $97, $57, $45, $78, $9A, $A9, $9A, $9B, $B9, $A8, $79, $89; 11:71C0
    db $A9, $99, $88, $89, $9C, $E9, $55, $00, $20, $28, $14, $63, $8B, $EE, $DC, $45; 11:71D0
    db $51, $88, $5A, $54, $88, $BE, $EC, $AA, $57, $95, $87, $34, $33, $78, $AA, $B8; 11:71E0
    db $8A, $9B, $C8, $98, $69, $AA, $CB, $99, $89, $AD, $EC, $63, $00, $00, $08, $32; 11:71F0
    db $52, $7C, $EF, $DB, $52, $52, $79, $36, $32, $7A, $EF, $FC, $89, $77, $B7, $55; 11:7200
    db $01, $35, $9B, $BA, $A9, $8C, $BA, $B7, $68, $8B, $DC, $BA, $A9, $CE, $FD, $30; 11:7210
    db $00, $10, $2A, $13, $66, $FF, $FD, $56, $01, $72, $74, $05, $7D, $FF, $F8, $86; 11:7220
    db $4A, $64, $40, $25, $8B, $BB, $78, $A8, $CA, $67, $47, $BB, $DC, $BB, $BE, $DE; 11:7230
    db $EC, $F6, $00, $00, $50, $78, $2A, $9F, $FC, $E0, $02, $06, $41, $66, $CF, $FF; 11:7240
    db $AC, $51, $82, $23, $05, $8C, $CB, $B5, $8A, $58, $53, $78, $BC, $BA, $8C, $BC; 11:7250
    db $EA, $AC, $CF, $F8, $00, $00, $E0, $35, $2E, $FF, $B2, $60, $38, $00, $04, $CF; 11:7260
    db $FB, $BB, $4D, $90, $00, $3A, $FE, $6A, $87, $D5, $13, $49, $CC, $86, $BA, $CD; 11:7270
    db $78, $BB, $DC, $BD, $FE, $00, $00, $A3, $05, $8F, $EF, $B0, $72, $02, $00, $1E; 11:7280
    db $FD, $FB, $9F, $B4, $00, $04, $B8, $6B, $BD, $E8, $42, $78, $8A, $68, $DB, $B9; 11:7290
    db $8A, $CE, $CB, $CD, $FF, $80, $00, $05, $00, $3F, $FB, $D9, $4A, $80, $00, $45; 11:72A0
    db $BC, $7E, $FF, $96, $33, $45, $01, $AB, $BB, $9A, $CB, $53, $68, $AA, $78, $BD; 11:72B0
    db $BA, $BC, $DE, $BC, $FF, $00, $31, $00, $01, $7F, $E5, $DF, $A6, $20, $03, $40; 11:72C0
    db $2E, $FC, $EC, $BB, $B3, $03, $42, $57, $9B, $DB, $9A, $B8, $68, $99, $99, $9B; 11:72D0
    db $CC, $BB, $ED, $DF, $F0, $0A, $A0, $00, $B3, $37, $9F, $FC, $18, $F6, $00, $55; 11:72E0
    db $13, $7C, $EB, $8C, $FA, $66, $86, $34, $69, $A7, $8C, $DA, $8A, $BB, $98, $9A; 11:72F0
    db $98, $9A, $A9, $9B, $EB, $04, $D4, $00, $A6, $00, $AA, $13, $BD, $96, $9B, $86; 11:7300
    db $57, $75, $56, $98, $69, $BA, $89, $A9, $88, $98, $88, $98, $89, $98, $88, $98; 11:7310
    db $88, $88, $77, $67, $76, $78, $98, $88, $98, $77, $66, $65, $67, $77, $77, $77; 11:7320
    db $87, $56, $76, $56, $88, $78, $99, $99, $99, $99, $88, $88, $88, $88, $88, $98; 11:7330
    db $88, $88, $87, $77, $77, $77, $88, $88, $88, $88, $76, $78, $76, $78, $88, $78; 11:7340
    db $88, $77, $77, $77, $77, $77, $77, $88, $88, $98, $77, $88, $77, $77, $88, $88; 11:7350
    db $88, $88, $88, $77, $77, $77, $88, $88, $88, $87, $77, $78, $77, $78, $98, $88; 11:7360
    db $88, $88, $87, $77, $77, $77, $77, $77, $77, $88, $87, $88, $88, $88, $88, $77; 11:7370
    db $88, $77, $78, $77, $77, $77, $77, $88, $88, $88, $88, $77, $77, $87, $88, $88; 11:7380
    db $88, $88, $87, $78, $87, $77, $88, $77, $88, $88, $88, $88, $87, $77, $77, $77; 11:7390
    db $87, $78, $88, $88, $87, $77, $77, $88, $88, $88, $88, $88, $77, $77, $88, $88; 11:73A0
    db $88, $88, $88, $88, $77, $88, $87, $78, $87, $88, $88, $88, $88, $87, $77, $77; 11:73B0
    db $77, $78, $88, $88, $88, $88, $87, $77, $88, $78, $88, $88, $88, $88, $87, $88; 11:73C0
    db $87, $88, $88, $88, $88, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $87; 11:73D0
    db $77, $77, $78, $88, $88, $88, $88, $77, $77, $77, $88, $88, $88, $88, $87, $77; 11:73E0
    db $77, $77, $78, $88, $87, $88, $88, $78, $88, $88, $88, $77, $78, $88, $88, $87; 11:73F0
    db $88, $87, $77, $77, $88, $88, $88, $87, $77, $77, $78, $88, $88, $88, $88, $77; 11:7400
    db $77, $77, $88, $88, $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $88; 11:7410
    db $88, $87, $77, $77, $88, $88, $88, $88, $77, $77, $77, $77, $88, $88, $88, $87; 11:7420
    db $77, $77, $77, $88, $88, $88, $88, $88, $88, $78, $88, $88, $88, $88, $77, $78; 11:7430
    db $78, $77, $77, $77, $77, $88, $88, $88, $88, $77, $77, $77, $88, $88, $88, $88; 11:7440
    db $87, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:7450
    db $88, $87, $77, $77, $77, $78, $78, $66, $77, $86, $88, $77, $87, $88, $78, $98; 11:7460
    db $88, $88, $87, $66, $77, $77, $87, $88, $88, $88, $88, $87, $77, $87, $77, $77; 11:7470
    db $78, $77, $87, $88, $87, $99, $89, $99, $8A, $99, $BA, $9A, $C8, $48, $75, $22; 11:7480
    db $21, $40, $03, $55, $48, $7A, $A9, $9B, $C9, $88, $98, $77, $68, $87, $89, $BA; 11:7490
    db $BB, $CD, $CB, $DF, $FF, $C5, $9B, $61, $02, $01, $00, $04, $30, $7A, $AB, $AB; 11:74A0
    db $CE, $97, $9A, $73, $55, $65, $36, $9A, $78, $BC, $BA, $BC, $ED, $BF, $FF, $C2; 11:74B0
    db $CD, $50, $03, $00, $00, $35, $20, $AD, $B9, $9E, $DD, $66, $B9, $40, $67, $43; 11:74C0
    db $49, $98, $69, $EB, $9A, $ED, $BC, $DF, $FF, $B1, $FC, $20, $26, $00, $00, $33; 11:74D0
    db $10, $EB, $6A, $EF, $9B, $99, $A5, $34, $94, $06, $87, $49, $B9, $A9, $BC, $BA; 11:74E0
    db $BF, $DC, $FF, $F2, $BF, $60, $09, $00, $00, $30, $20, $9B, $58, $CF, $89, $DA; 11:74F0
    db $97, $87, $67, $36, $76, $48, $A6, $7A, $B8, $9C, $BB, $BB, $CE, $FF, $E5, $DE; 11:7500
    db $52, $3B, $00, $12, $00, $32, $54, $48, $9B, $6B, $EB, $AB, $D9, $8A, $97, $58; 11:7510
    db $64, $56, $75, $78, $98, $8A, $AB, $AB, $CB, $CD, $C7, $AD, $75, $6A, $30, $34; 11:7520
    db $20, $23, $22, $37, $67, $7A, $BA, $BB, $DB, $AB, $A9, $9A, $87, $77, $65, $66; 11:7530
    db $66, $67, $77, $89, $99, $AB, $BB, $BA, $AB, $98, $88, $65, $54, $43, $33, $34; 11:7540
    db $44, $55, $66, $78, $88, $99, $99, $A9, $99, $99, $98, $88, $88, $88, $88, $88; 11:7550
    db $88, $88, $99, $99, $9A, $98, $88, $87, $76, $55, $54, $44, $44, $55, $56, $67; 11:7560
    db $78, $88, $99, $99, $9A, $99, $99, $99, $88, $88, $87, $77, $77, $77, $78, $88; 11:7570
    db $89, $99, $99, $A9, $99, $87, $76, $65, $54, $44, $45, $55, $56, $66, $77, $78; 11:7580
    db $88, $99, $9A, $AA, $AA, $A9, $99, $88, $88, $77, $77, $77, $77, $88, $89, $99; 11:7590
    db $99, $99, $99, $88, $77, $66, $55, $55, $55, $55, $55, $55, $66, $77, $88, $99; 11:75A0
    db $9A, $AA, $99, $99, $98, $88, $88, $88, $77, $78, $88, $88, $88, $88, $89, $99; 11:75B0
    db $99, $99, $98, $88, $76, $65, $55, $55, $55, $55, $55, $66, $67, $78, $88, $89; 11:75C0
    db $99, $89, $A9, $99, $98, $98, $88, $87, $77, $87, $78, $78, $98, $98, $99, $99; 11:75D0
    db $AA, $99, $88, $86, $66, $64, $45, $45, $45, $55, $66, $77, $88, $99, $99, $AA; 11:75E0
    db $99, $98, $88, $88, $78, $77, $77, $77, $88, $88, $89, $99, $9A, $AA, $BB, $BA; 11:75F0
    db $9A, $87, $75, $64, $33, $33, $13, $23, $34, $66, $77, $9A, $9B, $BB, $BA, $BA; 11:7600
    db $A8, $88, $77, $67, $55, $66, $76, $79, $89, $AB, $AB, $BB, $BA, $BB, $BC, $B7; 11:7610
    db $9B, $46, $43, $40, $10, $20, $04, $25, $38, $A8, $AA, $DB, $BC, $CC, $99, $A8; 11:7620
    db $65, $85, $45, $56, $57, $88, $88, $BA, $AA, $BC, $BB, $CC, $CC, $EF, $F6, $6F; 11:7630
    db $13, $31, $50, $00, $30, $07, $37, $2A, $EA, $BB, $FD, $9C, $BC, $56, $86, $32; 11:7640
    db $74, $34, $79, $68, $AB, $A9, $DC, $AA, $CD, $BB, $CE, $DE, $FF, $0F, $E0, $60; 11:7650
    db $60, $00, $05, $04, $49, $66, $FD, $DB, $EF, $9A, $8A, $71, $54, $50, $48, $56; 11:7660
    db $6B, $A9, $AB, $D8, $9B, $A9, $9B, $BA, $BD, $FE, $FF, $90, $F2, $00, $04, $00; 11:7670
    db $03, $00, $89, $E4, $EF, $ED, $BF, $D5, $64, $91, $03, $55, $08, $98, $8A, $DB; 11:7680
    db $99, $BA, $67, $98, $67, $BA, $AB, $EE, $EF, $FF, $F0, $BF, $00, $06, $00, $00; 11:7690
    db $80, $6B, $FB, $9F, $FC, $99, $C4, $20, $54, $02, $58, $47, $DD, $BA, $FE, $98; 11:76A0
    db $99, $53, $67, $75, $8B, $BA, $CF, $EC, $EF, $FF, $F0, $3F, $00, $06, $00, $20; 11:76B0
    db $A1, $8C, $FD, $7F, $F8, $56, $92, $01, $36, $05, $8C, $89, $FE, $CA, $DB, $86; 11:76C0
    db $68, $53, $57, $76, $AC, $BB, $CE, $CB, $BC, $CB, $DF, $B0, $9D, $00, $08, $00; 11:76D0
    db $04, $A2, $8B, $F9, $5E, $E7, $36, $82, $11, $76, $46, $BD, $9A, $EE, $A8, $BA; 11:76E0
    db $75, $57, $54, $69, $98, $9C, $CB, $BC, $CA, $9B, $BA, $AD, $FA, $0B, $D0, $00; 11:76F0
    db $90, $00, $59, $26, $AF, $85, $EE, $63, $78, $22, $37, $75, $6B, $E8, $AE, $E9; 11:7700
    db $7B, $96, $45, $75, $46, $A9, $7A, $DC, $AB, $CB, $88, $9A, $A9, $BE, $FE, $09; 11:7710
    db $F0, $00, $B0, $01, $38, $07, $8F, $A5, $EF, $72, $6A, $31, $27, $84, $6A, $F9; 11:7720
    db $9E, $EA, $79, $96, $35, $75, $46, $99, $8A, $CC, $99, $BA, $87, $9A, $88, $BD; 11:7730
    db $DE, $FB, $0F, $80, $00, $60, $10, $55, $49, $AF, $78, $ED, $52, $87, $13, $38; 11:7740
    db $67, $7C, $F9, $BE, $E8, $78, $75, $34, $66, $57, $AA, $9A, $CB, $99, $A9, $87; 11:7750
    db $88, $98, $AB, $CC, $FF, $F3, $0F, $10, $06, $00, $20, $91, $68, $EE, $4A, $EA; 11:7760
    db $34, $A6, $24, $7A, $68, $9E, $C8, $BD, $B5, $78, $63, $37, $65, $69, $B9, $9B; 11:7770
    db $C9, $88, $97, $67, $98, $8A, $CC, $CC, $EF, $FF, $90, $E7, $00, $05, $00, $15; 11:7780
    db $54, $BB, $F8, $8F, $D5, $29, $80, $35, $86, $78, $CE, $9A, $DD, $76, $A7, $44; 11:7790
    db $56, $56, $8A, $A9, $AB, $A8, $89, $86, $78, $88, $9A, $AA, $BB, $BB, $CD, $FE; 11:77A0
    db $02, $F0, $00, $80, $05, $39, $29, $AF, $D5, $CE, $92, $6B, $42, $58, $86, $9A; 11:77B0
    db $EA, $8B, $DA, $58, $96, $35, $86, $57, $9A, $88, $AB, $87, $99, $75, $89, $88; 11:77C0
    db $9B, $AA, $AC, $BA, $AB, $BB, $CE, $20, $E0, $00, $52, $04, $28, $56, $AC, $F5; 11:77D0
    db $AF, $A5, $4C, $73, $58, $96, $89, $CB, $7A, $BB, $67, $97, $55, $87, $66, $79; 11:77E0
    db $87, $8A, $87, $99, $87, $88, $88, $89, $99, $9A, $B9, $AB, $AA, $A9, $9A, $CA; 11:77F0
    db $04, $D0, $00, $80, $07, $49, $47, $AC, $B3, $BC, $74, $7C, $56, $8A, $A8, $AA; 11:7800
    db $C9, $79, $97, $57, $85, $56, $88, $78, $9A, $88, $99, $87, $88, $66, $78, $88; 11:7810
    db $9A, $AA, $AB, $B9, $9A, $98, $88, $87, $78, $BC, $30, $F5, $00, $55, $02, $54; 11:7820
    db $74, $8B, $D8, $7F, $B6, $6B, $93, $78, $87, $68, $AA, $68, $CA, $78, $B8, $67; 11:7830
    db $89, $77, $89, $87, $99, $87, $89, $86, $78, $87, $89, $99, $9A, $B9, $9A, $A9; 11:7840
    db $88, $87, $67, $76, $67, $89, $80, $5C, $00, $46, $10, $75, $66, $6A, $AA, $6A; 11:7850
    db $D7, $69, $B7, $6A, $98, $78, $99, $86, $9A, $76, $89, $77, $9A, $98, $99, $96; 11:7860
    db $68, $75, $58, $76, $78, $98, $89, $AA, $89, $BA, $89, $A9, $88, $88, $76, $66; 11:7870
    db $65, $66, $55, $78, $98, $17, $B0, $27, $72, $38, $66, $76, $8A, $85, $AB, $76; 11:7880
    db $AB, $88, $BA, $A9, $99, $A8, $58, $96, $58, $97, $78, $99, $78, $98, $77, $88; 11:7890
    db $77, $88, $87, $88, $87, $89, $98, $89, $98, $89, $A8, $88, $87, $66, $66, $55; 11:78A0
    db $66, $56, $67, $88, $AB, $45, $D5, $16, $85, $27, $65, $76, $69, $95, $6B, $96; 11:78B0
    db $8B, $A9, $AA, $AA, $88, $99, $66, $88, $67, $88, $88, $89, $88, $89, $87, $78; 11:78C0
    db $77, $77, $77, $66, $77, $77, $89, $99, $AA, $AA, $AA, $98, $88, $76, $76, $66; 11:78D0
    db $65, $66, $66, $77, $68, $9A, $84, $89, $43, $67, $44, $66, $67, $67, $88, $77; 11:78E0
    db $99, $89, $BB, $AA, $AA, $A9, $88, $87, $67, $77, $67, $88, $77, $88, $87, $89; 11:78F0
    db $88, $88, $87, $77, $87, $77, $88, $78, $99, $99, $AA, $99, $99, $88, $77, $76; 11:7900
    db $55, $66, $55, $66, $66, $78, $89, $BB, $65, $B7, $35, $76, $34, $75, $67, $67; 11:7910
    db $89, $77, $AA, $89, $BB, $99, $99, $98, $77, $87, $66, $78, $77, $88, $88, $88; 11:7920
    db $99, $88, $88, $87, $77, $77, $66, $77, $77, $88, $89, $99, $A9, $99, $98, $88; 11:7930
    db $87, $77, $66, $66, $66, $66, $67, $77, $88, $89, $AA, $66, $87, $54, $55, $44; 11:7940
    db $65, $56, $87, $78, $99, $99, $AA, $AA, $AA, $99, $A9, $88, $87, $77, $87, $77; 11:7950
    db $88, $78, $88, $88, $87, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88; 11:7960
    db $88, $88, $88, $88, $77, $77, $76, $66, $66, $66, $66, $67, $77, $78, $98, $77; 11:7970
    db $88, $66, $86, $56, $66, $56, $77, $67, $87, $78, $89, $88, $9A, $99, $AA, $99; 11:7980
    db $A9, $88, $98, $88, $87, $77, $77, $77, $77, $67, $77, $77, $88, $88, $88, $88; 11:7990
    db $98, $88, $88, $88, $88, $88, $88, $87, $77, $77, $76, $66, $66, $66, $76, $67; 11:79A0
    db $77, $78, $88, $88, $78, $87, $77, $76, $66, $66, $67, $77, $78, $88, $89, $99; 11:79B0
    db $99, $A9, $9A, $A9, $99, $98, $88, $87, $77, $77, $66, $77, $67, $77, $77, $77; 11:79C0
    db $78, $88, $88, $89, $99, $99, $88, $88, $88, $88, $78, $77, $77, $76, $77, $66; 11:79D0
    db $66, $76, $67, $77, $77, $77, $88, $88, $98, $88, $88, $77, $76, $66, $66, $67; 11:79E0
    db $77, $77, $88, $88, $99, $99, $99, $99, $A9, $99, $98, $88, $88, $77, $77, $66; 11:79F0
    db $66, $66, $77, $77, $77, $88, $88, $88, $88, $89, $98, $89, $88, $88, $88, $77; 11:7A00
    db $77, $77, $76, $77, $77, $77, $77, $77, $77, $77, $77, $78, $88, $88, $88, $88; 11:7A10
    db $88, $77, $76, $66, $66, $66, $66, $77, $77, $88, $88, $99, $99, $99, $99, $99; 11:7A20
    db $99, $88, $88, $77, $77, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88; 11:7A30
    db $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $67, $77, $77, $77, $77, $77; 11:7A40
    db $87, $78, $88, $88, $88, $88, $88, $88, $77, $77, $77, $66, $66, $66, $77, $77; 11:7A50
    db $88, $88, $89, $99, $99, $99, $99, $98, $88, $88, $77, $77, $77, $77, $77, $77; 11:7A60
    db $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77; 11:7A70
    db $77, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:7A80
    db $88, $87, $77, $77, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88; 11:7A90
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:7AA0
    db $88, $88, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77; 11:7AB0
    db $77, $77, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $88; 11:7AC0

;; PCM02: 2112 bytes = 4224 4-bit samples (rate 2) for SFXInst15
PCM02:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:7AD0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:7AE0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:7AF0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:7B00
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $88, $88, $88, $88, $88, $87; 11:7B10
    db $78, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $99, $98, $88, $88; 11:7B20
    db $88, $87, $65, $66, $44, $56, $56, $68, $88, $89, $98, $78, $87, $66, $77, $77; 11:7B30
    db $89, $99, $89, $86, $67, $65, $78, $88, $9A, $AA, $AA, $B9, $99, $98, $87, $88; 11:7B40
    db $87, $8A, $9A, $D8, $0A, $C0, $33, $42, $0A, $4B, $84, $FA, $B7, $AD, $25, $46; 11:7B50
    db $61, $78, $99, $7D, $CB, $98, $A7, $44, $65, $25, $89, $89, $CC, $BB, $CC, $98; 11:7B60
    db $89, $86, $78, $87, $8A, $AB, $DF, $20, $F0, $08, $03, $01, $A2, $B4, $9F, $6B; 11:7B70
    db $AE, $90, $B5, $52, $39, $57, $7A, $E7, $AC, $B8, $59, $75, $46, $76, $68, $BA; 11:7B80
    db $9C, $CB, $AB, $B9, $88, $87, $67, $88, $89, $BD, $B0, $BF, $02, $A0, $20, $77; 11:7B90
    db $18, $2F, $B2, $EC, $E3, $7F, $46, $2A, $81, $78, $B5, $6D, $B9, $6B, $B6, $68; 11:7BA0
    db $94, $58, $88, $6B, $B9, $AB, $D9, $9B, $A8, $79, $97, $89, $AB, $90, $BF, $04; 11:7BB0
    db $A0, $20, $86, $16, $5F, $72, $FB, $A5, $AE, $37, $5B, $61, $A8, $74, $9C, $68; 11:7BC0
    db $8B, $86, $98, $75, $89, $58, $9A, $89, $CA, $AA, $BB, $89, $99, $78, $AA, $BB; 11:7BD0
    db $07, $F0, $0F, $00, $07, $60, $84, $C8, $1F, $B8, $8B, $F1, $A9, $86, $1C, $63; 11:7BE0
    db $69, $A2, $9B, $87, $7D, $76, $89, $84, $99, $87, $9C, $8A, $CB, $A9, $C9, $89; 11:7BF0
    db $9A, $8C, $C0, $9F, $05, $C0, $40, $64, $07, $3C, $35, $F6, $B9, $DD, $4E, $8A; 11:7C00
    db $64, $D3, $46, $86, $2B, $77, $89, $B6, $9A, $98, $7B, $68, $99, $97, $BA, $99; 11:7C10
    db $AB, $8A, $A9, $99, $CB, $14, $F0, $0F, $04, $03, $70, $52, $A3, $2F, $59, $9C; 11:7C20
    db $E5, $EA, $C8, $5F, $55, $78, $62, $95, $56, $7A, $59, $99, $88, $C8, $99, $AA; 11:7C30
    db $7B, $A9, $9A, $B8, $AA, $98, $9B, $AB, $19, $F0, $8B, $06, $06, $20, $42, $90; 11:7C40
    db $6D, $3A, $8D, $A8, $EA, $E6, $BE, $58, $8A, $45, $85, $63, $87, $48, $89, $6A; 11:7C50
    db $B8, $99, $B8, $9B, $AA, $8B, $98, $A9, $98, $99, $89, $9A, $1B, $C0, $96, $34; 11:7C60
    db $17, $04, $22, $80, $67, $76, $6D, $79, $BA, $C8, $BA, $A9, $8B, $78, $88, $76; 11:7C70
    db $86, $77, $57, $67, $87, $87, $88, $89, $99, $99, $A9, $99, $99, $98, $88, $88; 11:7C80
    db $87, $78, $77, $87, $77, $77, $77, $66, $65, $65, $66, $66, $66, $67, $77, $77; 11:7C90
    db $88, $88, $89, $89, $99, $99, $99, $99, $89, $88, $88, $87, $87, $77, $77, $77; 11:7CA0
    db $88, $77, $88, $88, $99, $89, $88, $88, $88, $77, $77, $67, $76, $77, $77, $77; 11:7CB0
    db $77, $78, $78, $77, $77, $77, $67, $66, $77, $77, $77, $78, $88, $89, $99, $99; 11:7CC0
    db $99, $99, $88, $88, $88, $77, $77, $87, $78, $77, $88, $87, $88, $88, $88, $87; 11:7CD0
    db $88, $87, $88, $77, $77, $77, $78, $77, $87, $78, $87, $78, $78, $77, $87, $78; 11:7CE0
    db $88, $88, $88, $88, $88, $88, $77, $77, $77, $88, $78, $88, $88, $88, $88, $88; 11:7CF0
    db $88, $88, $88, $88, $88, $88, $88, $88, $87, $88, $88, $88, $88, $88, $87, $88; 11:7D00
    db $78, $77, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $77, $88; 11:7D10
    db $88, $88, $88, $88, $88, $78, $88, $77, $87, $77, $78, $77, $77, $88, $88, $88; 11:7D20
    db $88, $88, $88, $88, $88, $87, $88, $88, $88, $88, $88, $87, $78, $77, $78, $77; 11:7D30
    db $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78; 11:7D40
    db $87, $88, $88, $88, $78, $88, $87, $88, $78, $88, $88, $88, $87, $87, $88, $88; 11:7D50
    db $87, $88, $87, $88, $77, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88; 11:7D60
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $78; 11:7D70
    db $87, $88, $88, $88, $88, $88, $88, $88, $88, $87, $88, $77, $87, $77, $77, $77; 11:7D80
    db $77, $78, $77, $77, $77, $77, $78, $78, $88, $88, $88, $88, $88, $88, $88, $88; 11:7D90
    db $88, $88, $88, $77, $87, $77, $78, $87, $78, $88, $88, $88, $88, $88, $88, $77; 11:7DA0
    db $87, $87, $88, $88, $88, $77, $88, $78, $77, $77, $77, $77, $77, $88, $88, $88; 11:7DB0
    db $88, $88, $88, $88, $88, $88, $78, $77, $78, $78, $88, $88, $88, $88, $88, $87; 11:7DC0
    db $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $77; 11:7DD0
    db $77, $77, $77, $88, $78, $88, $88, $88, $77, $87, $78, $87, $78, $88, $88, $88; 11:7DE0
    db $88, $88, $88, $87, $88, $88, $78, $78, $88, $88, $88, $88, $88, $88, $88, $87; 11:7DF0
    db $77, $77, $77, $78, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 11:7E00
    db $88, $78, $77, $66, $66, $67, $77, $77, $77, $88, $88, $88, $88, $88, $98, $89; 11:7E10
    db $99, $99, $88, $88, $88, $88, $99, $9A, $BC, $95, $40, $00, $24, $45, $54, $6A; 11:7E20
    db $BD, $CB, $85, $54, $57, $76, $77, $88, $CD, $CC, $B8, $76, $65, $66, $56, $78; 11:7E30
    db $9B, $BA, $99, $77, $88, $99, $98, $8A, $AB, $CB, $AA, $AA, $BD, $B5, $20, $00; 11:7E40
    db $02, $58, $97, $69, $9B, $FC, $95, $10, $02, $68, $BC, $AA, $BC, $DE, $EA, $75; 11:7E50
    db $11, $46, $79, $A9, $9A, $AA, $BA, $86, $54, $58, $9A, $BB, $9A, $BB, $BB, $A8; 11:7E60
    db $77, $78, $BD, $D6, $30, $00, $02, $7A, $A8, $68, $89, $EB, $85, $10, $02, $89; 11:7E70
    db $EE, $BB, $A9, $AB, $B9, $65, $12, $57, $AD, $CB, $98, $77, $88, $66, $55, $79; 11:7E80
    db $BB, $BB, $99, $99, $AA, $A9, $87, $88, $BC, $EB, $21, $00, $00, $6A, $CB, $78; 11:7E90
    db $A8, $CD, $85, $10, $00, $7A, $EF, $DB, $B9, $9A, $A8, $54, $11, $58, $BE, $DB; 11:7EA0
    db $97, $66, $77, $66, $66, $8A, $CC, $CA, $88, $88, $AA, $98, $77, $89, $BB, $BC; 11:7EB0
    db $C8, $11, $00, $00, $59, $BB, $AA, $B8, $BA, $44, $00, $03, $7B, $EF, $DD, $B8; 11:7EC0
    db $88, $76, $44, $24, $89, $CE, $BA, $96, $56, $65, $67, $78, $AA, $BB, $A8, $77; 11:7ED0
    db $78, $99, $99, $89, $9A, $AA, $98, $89, $A9, $32, $00, $01, $6C, $ED, $A8, $75; 11:7EE0
    db $78, $55, $20, $14, $9D, $FF, $EC, $95, $66, $66, $65, $46, $9A, $DE, $BA, $74; 11:7EF0
    db $45, $67, $88, $78, $99, $BA, $98, $66, $68, $AA, $BA, $88, $88, $99, $98, $76; 11:7F00
    db $68, $CB, $55, $00, $00, $5C, $DC, $87, $54, $89, $88, $41, $14, $8C, $FF, $DB; 11:7F10
    db $63, $56, $79, $97, $56, $79, $DD, $B9, $53, $35, $79, $B9, $88, $78, $AA, $98; 11:7F20
    db $76, $68, $9A, $BA, $87, $78, $9A, $A9, $86, $57, $9C, $E7, $40, $00, $04, $CE; 11:7F30
    db $E9, $66, $47, $B8, $85, $00, $27, $BF, $FE, $A8, $44, $78, $99, $75, $58, $9C; 11:7F40
    db $EB, $96, $43, $58, $9A, $A8, $77, $78, $A9, $87, $66, $8A, $BA, $A8, $67, $78; 11:7F50
    db $AA, $98, $76, $68, $9A, $DB, $33, $00, $02, $6C, $DB, $88, $75, $99, $56, $30; 11:7F60
    db $26, $9D, $FF, $BA, $74, $57, $78, $87, $68, $AA, $DC, $97, $54, $57, $99, $A8; 11:7F70
    db $67, $77, $99, $87, $76, $79, $AA, $A8, $67, $78, $9A, $98, $87, $78, $88, $99; 11:7F80
    db $B7, $23, $00, $22, $8C, $CB, $88, $65, $87, $56, $32, $57, $BE, $FE, $B9, $54; 11:7F90
    db $66, $78, $88, $89, $AA, $CA, $87, $54, $57, $89, $98, $78, $77, $88, $88, $78; 11:7FA0
    db $9A, $A9, $87, $67, $89, $AA, $98, $87, $77, $77, $78, $9B, $63, $30, $02, $49; 11:7FB0
    db $CD, $A8, $85, $69, $76, $63, $26, $9C, $EF, $C9, $74, $46, $78, $88, $77, $9A; 11:7FC0
    db $BB, $97, $64, $46, $89, $A9, $77, $76, $79, $98, $88, $88, $98, $88, $77, $88; 11:7FD0
    db $9A, $98, $87, $66, $77, $67, $78, $9D, $C5, $50, $00, $15, $DE, $DA, $87, $59; 11:7FE0
    db $96, $64, $03, $7B, $EF, $FB, $85, $24, $67, $88, $77, $8A, $BC, $B8, $64, $34; 11:7FF0

; ============================================================================
SECTION "GHX PCM samples bank $12", ROMX[$4000], BANK[$12]
; ============================================================================
;; (continuation of the previous sample from bank $11)
    db $79, $AA, $86, $67, $79, $A9, $87, $77, $89, $88, $76, $78, $9A, $A9, $76, $56; 12:4000
    db $78, $87, $66, $68, $AC, $E8, $32, $00, $35, $CF, $EB, $77, $56, $B8, $55, $11; 12:4010
    db $5A, $EF, $FC, $75, $33, $78, $89, $76, $7A, $BC, $C9, $64, $34, $79, $AA, $97; 12:4020
    db $67, $88, $98, $77, $77, $89, $88, $87, $79, $AA, $A9, $76, $66, $78, $88, $77; 12:4030
    db $67, $89, $AA, $BA, $42, $10, $15, $7C, $DC, $98, $86, $89, $54, $42, $48, $BE; 12:4040
    db $FE, $A7, $64, $57, $77, $87, $89, $BB, $BA, $75, $54, $58, $89, $98, $87, $88; 12:4050
    db $78, $76, $77, $88, $98, $78, $78, $99, $99, $87, $77, $77, $87, $77, $78, $88; 12:4060
    db $87, $77, $8B, $B6, $52, $00, $57, $DE, $C9, $76, $47, $97, $76, $34, $8A, $DE; 12:4070
    db $D9, $65, $34, $78, $89, $87, $9A, $AB, $A7, $54, $45, $89, $9A, $98, $88, $77; 12:4080
    db $77, $67, $78, $9A, $98, $87, $78, $99, $98, $77, $77, $78, $87, $77, $78, $88; 12:4090
    db $88, $77, $78, $BB, $75, $30, $05, $7B, $DB, $97, $66, $79, $86, $53, $37, $AC; 12:40A0
    db $ED, $A7, $54, $58, $98, $98, $78, $9B, $BB, $86, $44, $57, $9A, $A9, $87, $77; 12:40B0
    db $88, $76, $66, $79, $AA, $98, $77, $78, $99, $87, $76, $67, $88, $88, $76, $66; 12:40C0
    db $78, $87, $77, $89, $BB, $75, $20, $04, $6B, $EC, $A8, $66, $78, $86, $63, $37; 12:40D0
    db $9C, $FE, $B8, $54, $46, $88, $98, $78, $9A, $BB, $87, $54, $46, $99, $A9, $87; 12:40E0
    db $77, $88, $77, $66, $78, $AA, $A8, $76, $67, $89, $98, $87, $77, $88, $88, $76; 12:40F0
    db $77, $88, $87, $76, $78, $9A, $BA, $64, $10, $36, $8B, $CA, $98, $77, $88, $76; 12:4100
    db $53, $47, $9C, $EC, $A8, $55, $56, $88, $88, $88, $99, $AA, $87, $65, $67, $88; 12:4110
    db $98, $87, $77, $78, $77, $77, $88, $99, $98, $77, $67, $89, $99, $88, $77, $77; 12:4120
    db $77, $77, $78, $89, $88, $76, $67, $89, $BB, $96, $41, $04, $58, $BB, $A9, $87; 12:4130
    db $88, $88, $75, $45, $68, $BD, $CB, $96, $65, $67, $88, $88, $78, $9A, $AA, $97; 12:4140
    db $65, $56, $78, $88, $87, $77, $88, $88, $87, $77, $88, $89, $88, $78, $89, $99; 12:4150
    db $88, $77, $77, $78, $88, $77, $77, $77, $77, $78, $89, $A8, $75, $22, $34, $6A; 12:4160
    db $AB, $B9, $88, $77, $87, $65, $56, $79, $BB, $BB, $87, $65, $67, $78, $88, $88; 12:4170
    db $89, $99, $88, $76, $56, $67, $88, $88, $77, $88, $88, $88, $77, $78, $88, $88; 12:4180
    db $88, $88, $88, $88, $87, $77, $78, $88, $88, $77, $77, $77, $78, $78, $89, $98; 12:4190
    db $76, $43, $33, $68, $9B, $BA, $98, $77, $77, $76, $66, $68, $9B, $CC, $A9, $76; 12:41A0
    db $66, $68, $88, $88, $89, $99, $99, $86, $55, $56, $78, $89, $88, $88, $88, $77; 12:41B0
    db $77, $77, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $88, $77, $77, $77; 12:41C0
    db $77, $78, $89, $A9, $87, $53, $34, $58, $9A, $BA, $88, $87, $88, $77, $66, $67; 12:41D0
    db $89, $BB, $BA, $97, $66, $66, $77, $78, $78, $89, $99, $98, $76, $55, $66, $78; 12:41E0
    db $88, $98, $88, $87, $77, $77, $77, $88, $88, $88, $88, $88, $87, $77, $77, $78; 12:41F0
    db $88, $88, $87, $77, $77, $77, $77, $78, $88, $99, $87, $64, $44, $46, $89, $AA; 12:4200
    db $99, $88, $77, $77, $76, $66, $78, $9A, $BA, $98, $77, $67, $78, $88, $88, $88; 12:4210
    db $88, $88, $77, $77, $78, $88, $88, $88, $88, $88, $88, $78, $88, $88, $88, $88; 12:4220
    db $87, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88, $89; 12:4230
    db $98, $76, $55, $56, $78, $99, $98, $88, $88, $88, $87, $77, $78, $89, $99, $98; 12:4240
    db $87, $77, $77, $88, $77, $77, $88, $88, $88, $77, $77, $78, $88, $88, $88, $88; 12:4250
    db $88, $88, $77, $78, $88, $88, $88, $88, $88, $88, $77, $77, $77, $88, $88, $77; 12:4260
    db $77, $78, $88, $88, $77, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $87; 12:4270
    db $77, $77, $78, $88, $88, $88, $87, $78, $88, $88, $88, $88, $88, $88, $88, $88; 12:4280
    db $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $88, $87, $77, $77, $77; 12:4290
    db $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $88, $77, $78, $88, $88, $88; 12:42A0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:42B0
    db $88, $87, $88, $88, $88, $87, $77, $77, $88, $88, $88, $88, $77, $87, $77, $77; 12:42C0
    db $77, $77, $87, $88, $88, $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88; 12:42D0
    db $88, $88, $87, $77, $88, $88, $88, $88, $88, $87, $87, $88, $88, $88, $87, $78; 12:42E0
    db $87, $88, $77, $77, $88, $88, $87, $77, $88, $88, $87, $78, $88, $88, $87, $88; 12:42F0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:4300

;; PCM03: 2256 bytes = 4512 4-bit samples (rate 2) for SFXInst16
PCM03:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:4310
    db $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:4320
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:4330
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77; 12:4340
    db $77, $66, $67, $77, $78, $88, $88, $99, $99, $A9, $9A, $99, $99, $98, $88, $87; 12:4350
    db $77, $77, $77, $77, $77, $77, $77, $88, $89, $A8, $77, $66, $66, $54, $55, $45; 12:4360
    db $55, $57, $77, $88, $89, $AA, $AA, $99, $99, $98, $88, $77, $77, $67, $77, $77; 12:4370
    db $88, $89, $99, $99, $99, $AA, $AA, $99, $98, $88, $77, $76, $66, $66, $66, $67; 12:4380
    db $89, $CB, $13, $60, $77, $43, $49, $59, $73, $46, $88, $87, $7A, $CD, $C9, $88; 12:4390
    db $88, $86, $58, $99, $98, $67, $88, $77, $77, $9A, $99, $88, $89, $88, $88, $9A; 12:43A0
    db $AA, $A9, $88, $86, $77, $78, $98, $76, $55, $67, $9D, $F2, $04, $02, $E8, $65; 12:43B0
    db $88, $8B, $21, $34, $BC, $B9, $A9, $BD, $84, $65, $6B, $C9, $99, $78, $96, $56; 12:43C0
    db $79, $BA, $87, $66, $77, $78, $99, $BA, $88, $88, $AB, $A9, $87, $77, $88, $77; 12:43D0
    db $66, $65, $67, $AF, $F0, $00, $04, $FB, $B8, $34, $78, $22, $12, $CF, $EE, $83; 12:43E0
    db $78, $79, $95, $8D, $BC, $B6, $35, $68, $AB, $99, $87, $76, $57, $89, $BB, $98; 12:43F0
    db $87, $8A, $AB, $BA, $98, $77, $78, $98, $77, $66, $7A, $FF, $00, $00, $5F, $DF; 12:4400
    db $A0, $24, $54, $43, $4D, $FE, $F7, $03, $56, $DC, $88, $A9, $AA, $63, $55, $9C; 12:4410
    db $CB, $96, $55, $66, $99, $9B, $A8, $87, $79, $BC, $BB, $97, $77, $89, $99, $88; 12:4420
    db $AD, $FB, $00, $00, $EF, $DF, $40, $22, $65, $45, $5F, $FC, $D2, $04, $59, $FC; 12:4430
    db $88, $88, $99, $43, $78, $CE, $B9, $63, $57, $89, $99, $8A, $97, $77, $8B, $DD; 12:4440
    db $C9, $76, $78, $8A, $AA, $CF, $F3, $00, $00, $FF, $EC, $00, $13, $74, $66, $AF; 12:4450
    db $EB, $70, $05, $7D, $D9, $88, $98, $86, $35, $8B, $EC, $86, $45, $79, $99, $A8; 12:4460
    db $88, $67, $8A, $CD, $DB, $87, $68, $AB, $CD, $EE, $40, $00, $0F, $FC, $80, $01; 12:4470
    db $45, $27, $9D, $FD, $74, $02, $8A, $BA, $97, $89, $65, $54, $8B, $BB, $97, $66; 12:4480
    db $66, $9A, $AB, $98, $77, $89, $AB, $CC, $B9, $99, $AC, $EF, $D0, $00, $08, $FE; 12:4490
    db $81, $12, $25, $12, $8C, $FF, $83, $13, $79, $A8, $9B, $98, $62, $36, $9A, $BA; 12:44A0
    db $98, $85, $57, $8B, $CA, $87, $78, $99, $9B, $BB, $A9, $9B, $DE, $F9, $00, $03; 12:44B0
    db $DF, $A3, $16, $32, $20, $5D, $FE, $84, $35, $87, $77, $9B, $C8, $53, $47, $89; 12:44C0
    db $9A, $B9, $76, $57, $AC, $B9, $88, $99, $88, $AD, $DB, $98, $AD, $DD, $60, $02; 12:44D0
    db $8C, $A8, $23, $83, $00, $4A, $DE, $A5, $78, $86, $55, $8B, $A8, $66, $68, $65; 12:44E0
    db $79, $BB, $86, $68, $99, $9A, $BB, $A7, $78, $BC, $CC, $BB, $DE, $CB, $00, $06; 12:44F0
    db $86, $69, $58, $60, $00, $89, $9B, $BB, $B8, $52, $58, $87, $89, $A9, $74, $25; 12:4500
    db $99, $99, $AA, $98, $67, $9B, $AA, $BB, $AA, $99, $BC, $DD, $ED, $C0, $00, $66; 12:4510
    db $05, $B8, $95, $00, $48, $43, $AD, $E9, $87, $78, $64, $48, $99, $78, $77, $56; 12:4520
    db $67, $9A, $99, $AA, $89, $99, $AB, $AA, $BB, $BB, $CD, $EF, $D8, $00, $65, $00; 12:4530
    db $9B, $64, $43, $45, $22, $7E, $A8, $9D, $B8, $67, $66, $55, $78, $86, $79, $86; 12:4540
    db $58, $A8, $89, $BB, $A8, $9B, $B9, $AC, $CB, $BB, $DF, $FF, $10, $75, $00, $6D; 12:4550
    db $22, $8A, $44, $13, $59, $46, $CF, $88, $CC, $73, $66, $64, $57, $87, $77, $98; 12:4560
    db $77, $99, $88, $AA, $9A, $CB, $BB, $BB, $BB, $BC, $EF, $F2, $0A, $30, $06, $70; 12:4570
    db $28, $A4, $44, $77, $52, $9B, $97, $CF, $A8, $89, $65, $46, $56, $48, $87, $79; 12:4580
    db $A8, $78, $98, $88, $BB, $AB, $CC, $BB, $CC, $BC, $EF, $D0, $6C, $00, $08, $00; 12:4590
    db $46, $55, $35, $96, $45, $E7, $6A, $FA, $8A, $B9, $77, $58, $54, $38, $75, $6A; 12:45A0
    db $98, $9A, $A7, $99, $BA, $AB, $CB, $BB, $CC, $BC, $DF, $F7, $0D, $80, $02, $50; 12:45B0
    db $02, $23, $62, $3A, $85, $5C, $98, $9B, $9A, $B7, $8A, $A7, $88, $86, $77, $56; 12:45C0
    db $77, $68, $87, $89, $88, $AB, $AA, $BB, $AB, $BB, $BC, $CC, $EE, $B8, $C8, $33; 12:45D0
    db $40, $00, $00, $02, $00, $46, $46, $A8, $8B, $C9, $AD, $BA, $CD, $AA, $B9, $78; 12:45E0
    db $86, $67, $54, $66, $56, $88, $79, $99, $AB, $BB, $CC, $BB, $CC, $DE, $ED, $8B; 12:45F0
    db $94, $33, $20, $00, $00, $10, $03, $54, $5A, $87, $BD, $AA, $DC, $AC, $DA, $AD; 12:4600
    db $A7, $89, $76, $85, $45, $64, $57, $76, $89, $8A, $BB, $AC, $DB, $BC, $CB, $CC; 12:4610
    db $CD, $C8, $99, $53, $42, $00, $00, $00, $00, $25, $24, $98, $7B, $CA, $AD, $CA; 12:4620
    db $CD, $BB, $DB, $9A, $A8, $78, $65, $55, $44, $66, $67, $88, $9A, $AB, $CC, $BC; 12:4630
    db $CB, $BB, $BB, $BB, $BB, $98, $96, $44, $30, $00, $00, $00, $00, $33, $37, $87; 12:4640
    db $9C, $BB, $DD, $BC, $EC, $CD, $C9, $9A, $77, $87, $55, $54, $56, $65, $78, $88; 12:4650
    db $9A, $AB, $BB, $BC, $BB, $BB, $AA, $A9, $98, $89, $87, $76, $55, $42, $22, $10; 12:4660
    db $00, $00, $33, $35, $77, $8B, $BB, $DD, $CC, $DC, $BC, $CA, $9A, $87, $87, $66; 12:4670
    db $76, $56, $66, $78, $88, $99, $9A, $AA, $AA, $99, $99, $99, $88, $77, $77, $78; 12:4680
    db $88, $87, $77, $65, $55, $43, $22, $11, $22, $23, $56, $67, $9A, $AB, $CD, $CD; 12:4690
    db $DC, $BB, $BA, $AA, $98, $77, $77, $66, $66, $67, $77, $88, $88, $99, $99, $98; 12:46A0
    db $89, $98, $88, $77, $87, $78, $77, $88, $88, $87, $77, $66, $65, $44, $33, $22; 12:46B0
    db $33, $35, $56, $78, $89, $AB, $BB, $BC, $BB, $BB, $AA, $AA, $99, $87, $77, $77; 12:46C0
    db $77, $66, $66, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77; 12:46D0
    db $77, $77, $77, $77, $76, $66, $55, $55, $44, $44, $55, $55, $66, $78, $89, $AA; 12:46E0
    db $AB, $BB, $BB, $BB, $AA, $99, $88, $77, $76, $66, $66, $66, $77, $77, $78, $88; 12:46F0
    db $99, $99, $9A, $99, $A9, $99, $88, $88, $77, $76, $66, $66, $66, $66, $55, $66; 12:4700
    db $66, $66, $66, $66, $66, $67, $77, $77, $88, $88, $88, $89, $9A, $AA, $AA, $AA; 12:4710
    db $99, $99, $88, $87, $88, $77, $77, $77, $77, $88, $88, $88, $88, $99, $99, $99; 12:4720
    db $99, $99, $99, $99, $AB, $B8, $52, $00, $01, $23, $33, $35, $8A, $CD, $A8, $65; 12:4730
    db $56, $77, $66, $56, $9B, $CD, $CA, $88, $88, $98, $76, $55, $79, $AB, $A9, $88; 12:4740
    db $99, $99, $87, $78, $8A, $BB, $AA, $AA, $BB, $CD, $FA, $31, $00, $00, $05, $76; 12:4750
    db $57, $AA, $FF, $B8, $50, $00, $24, $8B, $99, $CC, $DF, $FE, $B7, $31, $34, $58; 12:4760
    db $98, $AA, $AC, $CB, $97, $54, $56, $7A, $BA, $AB, $AB, $CC, $A9, $87, $89, $AB; 12:4770
    db $CC, $DD, $52, $00, $00, $04, $9A, $A9, $B9, $AE, $B7, $60, $00, $03, $9E, $FF; 12:4780
    db $FD, $AC, $BA, $A7, $31, $12, $5A, $DE, $FD, $98, $85, $66, $55, $67, $8B, $DC; 12:4790
    db $CB, $87, $87, $89, $98, $99, $9A, $BB, $CF, $D2, $10, $00, $00, $9E, $DD, $BA; 12:47A0
    db $7A, $C7, $53, $00, $00, $7F, $FF, $FF, $A8, $97, $78, $42, $32, $5A, $EF, $FE; 12:47B0
    db $97, $64, $46, $66, $88, $8B, $CB, $BA, $76, $66, $8A, $AA, $A9, $8A, $BB, $BB; 12:47C0
    db $AD, $90, $00, $00, $03, $EF, $ED, $A7, $57, $74, $31, $00, $25, $EF, $FF, $FA; 12:47D0
    db $64, $44, $66, $55, $66, $AE, $EF, $D9, $65, $34, $57, $78, $99, $AB, $BA, $97; 12:47E0
    db $66, $78, $AA, $A9, $98, $89, $9A, $98, $88, $AD, $63, $00, $00, $09, $FE, $DB; 12:47F0
    db $63, $56, $65, $61, $04, $5A, $FF, $FF, $94, $22, $36, $99, $88, $88, $CD, $CC; 12:4800
    db $95, $42, $36, $89, $AA, $99, $AA, $99, $75, $67, $8A, $BA, $A9, $88, $89, $9A; 12:4810
    db $87, $77, $8D, $F6, $40, $00, $01, $CF, $EC, $93, $25, $78, $76, $00, $35, $CF; 12:4820
    db $FF, $E6, $22, $36, $AA, $87, $77, $9D, $DC, $B6, $23, $36, $9B, $A9, $87, $79; 12:4830
    db $99, $86, $56, $79, $BB, $A9, $87, $89, $9A, $98, $66, $68, $AB, $DE, $51, $00; 12:4840
    db $01, $2A, $FC, $BA, $65, $88, $65, $20, $05, $8D, $FF, $EC, $63, $45, $68, $87; 12:4850
    db $89, $AC, $EC, $98, $53, $57, $8B, $A7, $76, $68, $99, $88, $65, $89, $AB, $A8; 12:4860
    db $87, $79, $AA, $A9, $76, $77, $89, $87, $78, $B9, $43, $00, $00, $5F, $FE, $D8; 12:4870
    db $34, $56, $76, $42, $47, $9F, $FF, $E9, $32, $34, $8A, $AA, $98, $9B, $CA, $97; 12:4880
    db $43, $56, $9B, $A8, $76, $57, $88, $99, $88, $88, $99, $87, $88, $8A, $AA, $98; 12:4890
    db $66, $66, $77, $77, $76, $8B, $EA, $52, $00, $01, $8F, $FE, $D7, $26, $77, $86; 12:48A0
    db $30, $47, $BF, $FF, $D7, $11, $35, $9B, $99, $88, $9B, $CB, $96, $33, $57, $AB; 12:48B0
    db $98, $65, $68, $9A, $A8, $66, $78, $99, $88, $77, $9A, $A9, $86, $55, $57, $89; 12:48C0
    db $87, $76, $79, $AD, $E6, $10, $00, $36, $DF, $FB, $A4, $38, $87, $64, $11, $6A; 12:48D0
    db $EF, $FC, $93, $03, $57, $BA, $88, $89, $BC, $B9, $63, $24, $79, $BB, $87, $65; 12:48E0
    db $79, $99, $87, $67, $88, $99, $77, $88, $AB, $A9, $75, $55, $67, $98, $88, $77; 12:48F0
    db $78, $89, $AD, $A3, $20, $01, $57, $FF, $BA, $83, $57, $66, $54, $25, $AC, $FF; 12:4900
    db $DA, $61, $25, $69, $B9, $99, $9A, $BB, $97, $52, $36, $8A, $CA, $87, $55, $78; 12:4910
    db $98, $86, $78, $89, $99, $88, $88, $AA, $98, $75, $55, $78, $99, $98, $76, $56; 12:4920
    db $67, $8A, $CD, $72, $10, $04, $6A, $FD, $9A, $64, $88, $77, $53, $38, $BD, $FF; 12:4930
    db $A8, $41, $46, $7A, $B9, $9A, $9A, $A9, $75, $43, $58, $9B, $B9, $87, $56, $77; 12:4940
    db $78, $88, $99, $99, $87, $78, $8A, $BA, $88, $65, $67, $78, $86, $67, $78, $88; 12:4950
    db $76, $67, $8B, $E9, $31, $00, $27, $AF, $FA, $96, $36, $87, $65, $32, $7B, $EF; 12:4960
    db $FA, $64, $02, $78, $AB, $98, $99, $AB, $A7, $53, $24, $8B, $CD, $A7, $65, $57; 12:4970
    db $87, $78, $78, $AA, $A9, $76, $78, $9A, $A8, $76, $56, $78, $99, $86, $66, $68; 12:4980
    db $88, $87, $78, $AD, $B5, $20, $00, $69, $FF, $B9, $72, $48, $76, $64, $36, $AD; 12:4990
    db $FF, $C7, $41, $05, $8A, $CB, $89, $99, $BA, $75, $32, $47, $BC, $DB, $86, $55; 12:49A0
    db $57, $77, $87, $8A, $AA, $A8, $67, $78, $99, $87, $65, $68, $99, $97, $55, $56; 12:49B0
    db $88, $87, $76, $79, $AD, $D7, $20, $00, $59, $CF, $E8, $86, $37, $86, $65, $25; 12:49C0
    db $9D, $FF, $E8, $42, $03, $89, $BB, $98, $AA, $AB, $85, $42, $37, $AC, $DB, $86; 12:49D0
    db $55, $57, $77, $77, $79, $BB, $A9, $65, $67, $8B, $A9, $86, $56, $88, $99, $76; 12:49E0
    db $66, $79, $98, $76, $57, $89, $BC, $C8, $21, $00, $38, $AF, $FA, $98, $45, $85; 12:49F0
    db $56, $34, $8A, $DF, $EB, $84, $22, $57, $9B, $BA, $AA, $89, $87, $66, $55, $88; 12:4A00
    db $AB, $A8, $75, $55, $67, $89, $99, $98, $88, $77, $77, $89, $99, $98, $76, $66; 12:4A10
    db $78, $88, $87, $77, $77, $77, $67, $77, $89, $9B, $C9, $43, $00, $25, $7E, $FC; 12:4A20
    db $B9, $45, $76, $68, $54, $77, $9E, $ED, $C8, $43, $34, $7A, $AA, $A9, $88, $88; 12:4A30
    db $88, $65, $55, $69, $9A, $A8, $66, $56, $88, $99, $87, $88, $88, $98, $88, $88; 12:4A40
    db $98, $87, $66, $66, $78, $98, $87, $66, $67, $78, $77, $77, $79, $AC, $B7, $50; 12:4A50
    db $01, $36, $DE, $CC, $95, $56, $67, $87, $56, $56, $AC, $DE, $C8, $63, $24, $68; 12:4A60
    db $AB, $A9, $88, $88, $98, $86, $54, $57, $8A, $BA, $86, $55, $67, $89, $88, $77; 12:4A70
    db $78, $89, $98, $88, $88, $88, $87, $76, $77, $88, $88, $87, $66, $66, $77, $78; 12:4A80
    db $88, $89, $AB, $A6, $52, $01, $35, $BD, $CD, $B7, $65, $55, $77, $66, $66, $9A; 12:4A90
    db $CE, $DA, $85, $33, $46, $8A, $BA, $A9, $88, $88, $87, $65, $55, $67, $9A, $A9; 12:4AA0
    db $88, $76, $77, $78, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77; 12:4AB0
    db $88, $87, $76, $66, $77, $88, $88, $89, $AB, $98, $63, $12, $25, $AB, $CE, $B8; 12:4AC0
    db $86, $56, $76, $66, $66, $89, $BC, $CB, $96, $54, $45, $78, $9A, $98, $88, $88; 12:4AD0
    db $88, $76, $55, $66, $89, $AA, $98, $76, $66, $78, $88, $88, $88, $89, $99, $87; 12:4AE0
    db $76, $77, $88, $88, $87, $77, $78, $88, $77, $67, $77, $88, $88, $77, $78, $89; 12:4AF0
    db $99, $97, $64, $33, $46, $89, $AA, $98, $87, $77, $77, $76, $67, $88, $9A, $AA; 12:4B00
    db $98, $77, $67, $78, $88, $88, $88, $88, $88, $77, $77, $77, $88, $88, $88, $87; 12:4B10
    db $77, $78, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $77; 12:4B20
    db $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $87, $77, $66, $67, $77, $78; 12:4B30
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77; 12:4B40
    db $77, $78, $88, $88, $88, $88, $88, $88, $77, $78, $88, $88, $88, $77, $77, $78; 12:4B50
    db $88, $87, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $88; 12:4B60
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $87, $88; 12:4B70
    db $88, $88, $88, $88, $88, $88, $88, $77, $77, $88, $88, $88, $88, $88, $87, $77; 12:4B80
    db $88, $77, $77, $77, $77, $78, $88, $87, $77, $77, $77, $77, $77, $78, $88, $88; 12:4B90
    db $88, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:4BA0
    db $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $77, $88, $77, $77, $78, $88; 12:4BB0
    db $87, $77, $77, $88, $88, $88, $88, $88, $88, $87, $77, $88, $88, $88, $88, $88; 12:4BC0
    db $88, $88, $88, $88, $88, $88, $88, $88, $87, $88, $88, $88, $88, $87, $77, $78; 12:4BD0

;; PCM04: 2720 bytes = 5440 4-bit samples (rate 2) for SFXInst17
PCM04:
    db $88, $88, $88, $88, $88, $88, $87, $87, $88, $77, $87, $88, $87, $88, $88, $88; 12:4BE0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $88, $88, $78, $77; 12:4BF0
    db $87, $88, $78, $78, $77, $87, $87, $78, $78, $78, $78, $88, $78, $78, $88, $87; 12:4C00
    db $88, $88, $78, $77, $87, $87, $78, $78, $87, $87, $87, $87, $88, $87, $87, $88; 12:4C10
    db $88, $88, $88, $88, $88, $88, $88, $87, $88, $78, $78, $78, $77, $87, $87, $88; 12:4C20
    db $78, $88, $78, $87, $88, $87, $87, $88, $88, $78, $78, $78, $78, $78, $88, $87; 12:4C30
    db $87, $87, $87, $87, $87, $88, $78, $78, $78, $87, $88, $88, $88, $88, $88, $88; 12:4C40
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $88, $78, $87, $78, $77, $87; 12:4C50
    db $87, $87, $88, $88, $88, $88, $88, $88, $87, $78, $88, $78, $78, $87, $77, $88; 12:4C60
    db $87, $78, $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:4C70
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:4C80
    db $88, $88, $78, $88, $77, $78, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77; 12:4C90
    db $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:4CA0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $78, $78, $88; 12:4CB0
    db $87, $77, $77, $78, $87, $78, $88, $88, $87, $87, $87, $88, $87, $88, $77, $88; 12:4CC0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:4CD0
    db $88, $88, $87, $88, $88, $88, $88, $88, $88, $88, $88, $87, $88, $87, $87, $87; 12:4CE0
    db $87, $87, $77, $77, $88, $78, $76, $87, $88, $87, $88, $88, $78, $78, $88, $88; 12:4CF0
    db $78, $78, $78, $77, $88, $78, $88, $68, $78, $88, $88, $98, $88, $77, $88, $88; 12:4D00
    db $88, $87, $88, $78, $78, $88, $88, $88, $88, $78, $87, $77, $86, $77, $67, $77; 12:4D10
    db $66, $76, $77, $77, $78, $78, $88, $88, $88, $88, $88, $88, $98, $88, $88, $88; 12:4D20
    db $88, $87, $87, $88, $99, $AB, $A3, $7A, $44, $22, $34, $40, $59, $78, $9B, $BD; 12:4D30
    db $C8, $AB, $97, $77, $67, $74, $68, $87, $89, $9A, $A8, $9A, $97, $88, $89, $88; 12:4D40
    db $AB, $A9, $AA, $A9, $87, $87, $55, $66, $67, $9D, $80, $AD, $03, $20, $46, $40; 12:4D50
    db $8E, $69, $BA, $BE, $A3, $8C, $53, $55, $69, $85, $AF, $B9, $BB, $BA, $74, $68; 12:4D60
    db $42, $57, $89, $89, $CD, $A9, $BB, $98, $77, $88, $66, $99, $87, $89, $88, $67; 12:4D70
    db $88, $8D, $80, $6F, $00, $60, $5A, $60, $BF, $86, $DB, $8B, $60, $7B, $31, $8A; 12:4D80
    db $9C, $B8, $DF, $85, $AA, $65, $53, $69, $44, $AB, $88, $99, $A9, $67, $A9, $78; 12:4D90
    db $AB, $AA, $89, $A9, $66, $78, $65, $57, $77, $8B, $FB, $07, $F0, $06, $05, $B4; 12:4DA0
    db $0D, $F8, $5E, $C7, $B3, $08, $A1, $09, $C9, $BB, $9E, $F6, $4A, $93, $34, $57; 12:4DB0
    db $85, $6C, $B8, $8A, $A9, $76, $8B, $97, $8B, $BA, $98, $9A, $85, $78, $75, $67; 12:4DC0
    db $88, $9C, $F1, $0F, $D0, $37, $09, $A2, $3F, $F4, $3F, $93, $A0, $1A, $82, $0F; 12:4DD0
    db $E8, $CB, $BE, $B3, $1A, $80, $26, $99, $96, $9F, $B5, $68, $96, $46, $9C, $A8; 12:4DE0
    db $BE, $CA, $99, $97, $55, $77, $65, $79, $99, $CF, $60, $BF, $00, $90, $69, $56; 12:4DF0
    db $DF, $90, $DD, $25, $23, $77, $81, $EF, $99, $BC, $A7, $51, $69, $33, $6C, $A9; 12:4E00
    db $A9, $BB, $44, $67, $54, $8A, $AB, $AC, $DB, $A8, $98, $65, $57, $76, $78, $9A; 12:4E10
    db $AC, $F1, $0E, $C0, $08, $38, $78, $9D, $F6, $0F, $A1, $32, $75, $88, $4F, $F8; 12:4E20
    db $8C, $C6, $56, $38, $84, $69, $D8, $7A, $97, $54, $56, $86, $7C, $C9, $AB, $CA; 12:4E30
    db $88, $98, $77, $89, $98, $88, $87, $8A, $B3, $08, $E0, $0B, $68, $87, $88, $D3; 12:4E40
    db $0C, $92, $56, $C9, $9B, $7E, $A5, $58, $95, $48, $89, $86, $AA, $95, $68, $85; 12:4E50
    db $47, $A8, $68, $AB, $98, $8B, $CA, $8A, $CA, $79, $B9, $87, $78, $99, $AC, $30; 12:4E60
    db $9A, $03, $73, $76, $85, $7E, $22, $D6, $56, $7A, $8C, $A7, $D8, $57, $77, $66; 12:4E70
    db $88, $98, $8A, $98, $87, $77, $76, $79, $87, $99, $A9, $99, $AB, $99, $BB, $AA; 12:4E80
    db $99, $98, $78, $AB, $C7, $02, $D0, $05, $16, $34, $65, $E7, $0B, $97, $85, $BA; 12:4E90
    db $BB, $7B, $C7, $67, $78, $56, $77, $97, $88, $99, $78, $98, $78, $88, $88, $89; 12:4EA0
    db $AA, $99, $BA, $9A, $BA, $AA, $99, $9A, $9A, $E9, $04, $B0, $06, $00, $42, $02; 12:4EB0
    db $85, $48, $97, $8A, $87, $BA, $8A, $A9, $8A, $A8, $99, $87, $88, $76, $76, $67; 12:4EC0
    db $67, $68, $87, $89, $88, $9A, $AA, $BB, $BB, $CB, $AB, $BA, $AA, $BB, $C8, $58; 12:4ED0
    db $42, $41, $00, $00, $01, $20, $46, $54, $9A, $8A, $DB, $BD, $B9, $CD, $BA, $BA; 12:4EE0
    db $89, $97, $78, $64, $55, $55, $66, $78, $88, $9A, $BB, $BC, $CC, $CB, $BC, $BA; 12:4EF0
    db $AA, $AB, $B8, $68, $53, $42, $00, $00, $00, $00, $23, $45, $99, $8B, $CC, $CD; 12:4F00
    db $BB, $DC, $BB, $BA, $99, $87, $87, $66, $65, $56, $56, $78, $88, $9A, $AB, $AB; 12:4F10
    db $BB, $AA, $AA, $A9, $99, $99, $99, $77, $75, $65, $43, $32, $00, $10, $12, $33; 12:4F20
    db $57, $68, $AA, $CC, $CC, $DD, $CB, $BB, $B9, $88, $87, $66, $66, $66, $66, $77; 12:4F30
    db $88, $89, $99, $99, $99, $99, $89, $99, $99, $AA, $AA, $99, $98, $76, $53, $32; 12:4F40
    db $00, $00, $02, $23, $56, $68, $AA, $BC, $CC, $DD, $CB, $BB, $BA, $88, $87, $66; 12:4F50
    db $66, $66, $67, $88, $89, $99, $99, $99, $99, $89, $98, $88, $88, $88, $87, $77; 12:4F60
    db $77, $77, $66, $65, $55, $54, $44, $25, $64, $58, $77, $88, $9B, $BA, $AC, $BB; 12:4F70
    db $BA, $99, $A7, $78, $76, $77, $68, $77, $88, $98, $89, $98, $89, $98, $8A, $9B; 12:4F80
    db $BC, $CA, $78, $A4, $44, $23, $20, $01, $22, $14, $67, $88, $8B, $CA, $AB, $CB; 12:4F90
    db $99, $88, $88, $67, $77, $66, $77, $87, $88, $A9, $9A, $AB, $AA, $BC, $BA, $BC; 12:4FA0
    db $CC, $ED, $24, $E2, $00, $01, $00, $00, $38, $04, $9B, $BA, $AD, $DD, $B6, $BB; 12:4FB0
    db $85, $56, $75, $35, $69, $76, $8B, $B9, $8B, $CA, $A8, $AB, $A8, $9B, $CB, $BD; 12:4FC0
    db $EF, $F7, $0D, $A2, $00, $20, $00, $00, $95, $24, $BF, $D8, $BF, $EE, $66, $88; 12:4FD0
    db $73, $05, $84, $33, $AB, $98, $AB, $EA, $89, $AC, $86, $9B, $BA, $9C, $FF, $FF; 12:4FE0
    db $F5, $2D, $90, $00, $10, $00, $00, $86, $76, $CF, $F9, $BE, $EB, $56, $65, $52; 12:4FF0
    db $03, $56, $54, $9B, $AA, $AB, $DA, $A9, $9A, $98, $99, $CC, $BD, $FF, $FF, $51; 12:5000
    db $CA, $30, $01, $00, $00, $18, $78, $6C, $FF, $AA, $CF, $D5, $55, $65, $20, $24; 12:5010
    db $85, $37, $BC, $98, $AE, $AA, $79, $BA, $89, $AC, $DB, $DF, $FF, $C0, $8C, $70; 12:5020
    db $00, $10, $00, $06, $77, $67, $FF, $E9, $BE, $F8, $56, $67, $52, $03, $68, $33; 12:5030
    db $9C, $B7, $8C, $DA, $98, $AB, $A9, $8B, $DC, $BD, $FF, $E1, $6D, $81, $00, $30; 12:5040
    db $00, $02, $75, $65, $BF, $E9, $BE, $FD, $78, $88, $85, $23, $66, $41, $5A, $97; 12:5050
    db $7A, $CB, $9A, $AB, $B9, $9A, $BB, $9A, $DE, $EB, $37, $C8, $20, $15, $20, $01; 12:5060
    db $35, $43, $58, $BA, $88, $CD, $B9, $8B, $B9, $87, $78, $86, $67, $89, $76, $89; 12:5070
    db $97, $89, $98, $78, $99, $88, $99, $98, $9A, $99, $88, $98, $76, $77, $65, $55; 12:5080
    db $55, $44, $55, $45, $56, $66, $67, $88, $88, $89, $99, $99, $AA, $AA, $AA, $AA; 12:5090
    db $99, $99, $88, $78, $88, $77, $89, $88, $89, $99, $87, $77, $75, $55, $55, $44; 12:50A0
    db $44, $55, $56, $66, $77, $88, $88, $99, $A9, $99, $9A, $A9, $99, $99, $98, $88; 12:50B0
    db $88, $77, $87, $77, $88, $88, $99, $99, $99, $98, $87, $66, $65, $44, $45, $44; 12:50C0
    db $55, $55, $66, $77, $88, $88, $99, $99, $9A, $A9, $99, $99, $98, $89, $88, $88; 12:50D0
    db $88, $77, $78, $88, $88, $99, $89, $99, $98, $88, $87, $66, $65, $55, $55, $55; 12:50E0
    db $55, $56, $66, $77, $77, $88, $88, $99, $99, $9A, $AA, $99, $99, $98, $88, $87; 12:50F0
    db $78, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $76, $66, $55; 12:5100
    db $55, $55, $56, $66, $66, $67, $77, $88, $89, $99, $99, $A9, $99, $99, $98, $88; 12:5110
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $78, $77, $88, $87, $88, $87; 12:5120
    db $77, $77, $66, $66, $66, $66, $66, $77, $77, $88, $88, $88, $88, $88, $88, $88; 12:5130
    db $89, $99, $99, $99, $88, $88, $88, $87, $77, $77, $77, $77, $88, $88, $88, $88; 12:5140
    db $88, $87, $88, $88, $88, $88, $77, $77, $77, $77, $76, $66, $66, $67, $77, $77; 12:5150
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:5160
    db $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $77, $77, $77; 12:5170
    db $77, $77, $77, $78, $77, $88, $88, $88, $88, $88, $77, $77, $77, $77, $88, $88; 12:5180
    db $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $88; 12:5190
    db $78, $88, $88, $88, $88, $87, $78, $77, $77, $77, $77, $77, $87, $88, $88, $88; 12:51A0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:51B0
    db $88, $88, $88, $88, $88, $78, $77, $77, $77, $77, $77, $77, $78, $88, $88, $88; 12:51C0
    db $88, $88, $88, $77, $77, $88, $78, $88, $87, $78, $88, $78, $88, $88, $88, $88; 12:51D0
    db $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $78, $88, $88, $88, $98, $88; 12:51E0
    db $88, $87, $78, $87, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:51F0
    db $88, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $78, $87, $88, $88, $77; 12:5200
    db $77, $77, $77, $77, $88, $78, $88, $88, $88, $88, $78, $88, $87, $77, $88, $88; 12:5210
    db $88, $88, $88, $88, $88, $88, $88, $88, $78, $88, $87, $87, $87, $77, $77, $77; 12:5220
    db $77, $77, $78, $87, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:5230
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $88, $88, $88, $77, $78; 12:5240
    db $88, $87, $77, $66, $66, $55, $55, $55, $56, $66, $77, $88, $88, $99, $99, $99; 12:5250
    db $99, $99, $99, $9A, $A9, $99, $99, $99, $99, $99, $99, $99, $99, $AA, $87, $41; 12:5260
    db $00, $00, $12, $22, $34, $58, $AB, $CC, $CA, $99, $89, $98, $76, $55, $67, $9A; 12:5270
    db $BB, $AA, $99, $99, $A9, $98, $77, $78, $9A, $BB, $AA, $AA, $BC, $DD, $B8, $50; 12:5280
    db $00, $00, $00, $10, $12, $36, $9C, $EE, $DB, $99, $88, $88, $87, $54, $44, $67; 12:5290
    db $9B, $BB, $A9, $99, $9A, $AA, $98, $87, $89, $AB, $BC, $BB, $BB, $CD, $EC, $A7; 12:52A0
    db $20, $00, $00, $02, $12, $33, $58, $BE, $FF, $DB, $A8, $67, $77, $76, $54, $44; 12:52B0
    db $57, $AB, $CD, $BA, $99, $99, $AA, $99, $87, $78, $9B, $CD, $DC, $CB, $BD, $DB; 12:52C0
    db $96, $10, $00, $00, $01, $24, $44, $79, $AD, $EF, $EC, $A7, $65, $55, $65, $55; 12:52D0
    db $55, $56, $8A, $CD, $CB, $A8, $87, $88, $89, $88, $88, $89, $AB, $CC, $CB, $BB; 12:52E0
    db $CD, $A9, $71, $00, $00, $00, $13, $45, $57, $89, $DE, $EE, $DB, $86, $65, $46; 12:52F0
    db $55, $66, $56, $78, $9B, $CC, $CB, $98, $87, $77, $77, $78, $88, $99, $AB, $BB; 12:5300
    db $BB, $BB, $BD, $CA, $96, $10, $00, $00, $12, $45, $55, $88, $9C, $DE, $DC, $B8; 12:5310
    db $76, $45, $66, $77, $77, $77, $89, $BB, $BC, $A9, $87, $66, $77, $78, $88, $88; 12:5320
    db $89, $AB, $BB, $BA, $A9, $AA, $BC, $A9, $71, $00, $00, $02, $34, $55, $46, $77; 12:5330
    db $BC, $DD, $DB, $97, $65, $57, $67, $87, $67, $77, $89, $AA, $BB, $98, $76, $67; 12:5340
    db $68, $88, $88, $88, $8A, $AA, $BA, $AA, $99, $9A, $AB, $BD, $C9, $95, $11, $00; 12:5350
    db $00, $12, $34, $45, $77, $AD, $DE, $EC, $A9, $76, $56, $65, $77, $56, $66, $79; 12:5360
    db $AB, $BC, $BA, $98, $77, $77, $77, $76, $67, $78, $9A, $BB, $BB, $99, $88, $89; 12:5370
    db $99, $9A, $BB, $98, $83, $21, $00, $01, $23, $55, $57, $88, $BC, $BC, $CA, $98; 12:5380
    db $76, $56, $66, $77, $78, $78, $99, $BB, $BB, $A9, $87, $66, $56, $66, $77, $78; 12:5390
    db $89, $9A, $BA, $AA, $98, $87, $77, $88, $89, $99, $AB, $CB, $A9, $52, $10, $00; 12:53A0
    db $01, $34, $56, $78, $8A, $BB, $DD, $BB, $98, $65, $65, $67, $77, $88, $89, $99; 12:53B0
    db $AB, $BA, $98, $76, $65, $66, $68, $88, $99, $99, $9A, $AA, $99, $88, $66, $66; 12:53C0
    db $78, $99, $9A, $AA, $BB, $BA, $97, $32, $00, $00, $01, $35, $56, $88, $9B, $BD; 12:53D0
    db $ED, $CC, $A8, $65, $55, $56, $67, $87, $88, $89, $AB, $BB, $A9, $87, $65, $55; 12:53E0
    db $67, $77, $88, $88, $89, $99, $99, $88, $77, $77, $88, $99, $AA, $AA, $AA, $AA; 12:53F0
    db $BA, $88, $31, $00, $00, $02, $56, $88, $99, $9B, $CC, $DD, $BB, $96, $54, $44; 12:5400
    db $57, $78, $99, $99, $99, $AA, $AB, $A9, $87, $65, $55, $56, $77, $88, $89, $88; 12:5410
    db $98, $98, $88, $77, $77, $78, $89, $AA, $BA, $A9, $98, $88, $89, $97, $65, $10; 12:5420
    db $00, $01, $35, $78, $99, $A9, $AB, $BB, $CB, $99, $75, $54, $45, $68, $89, $A9; 12:5430
    db $9A, $9A, $AA, $AA, $99, $86, $65, $55, $56, $77, $88, $89, $88, $98, $88, $88; 12:5440
    db $77, $77, $88, $89, $99, $99, $98, $88, $87, $78, $88, $98, $86, $53, $21, $12; 12:5450
    db $34, $67, $89, $99, $9A, $AA, $BB, $A9, $87, $65, $55, $67, $88, $99, $99, $99; 12:5460
    db $99, $9A, $99, $87, $76, $65, $66, $77, $88, $88, $88, $88, $88, $88, $87, $77; 12:5470
    db $77, $88, $99, $99, $99, $88, $88, $88, $87, $88, $88, $88, $76, $53, $22, $23; 12:5480
    db $35, $67, $88, $88, $89, $9A, $AA, $A9, $87, $76, $66, $77, $89, $99, $99, $99; 12:5490
    db $99, $AA, $99, $88, $76, $65, $66, $67, $78, $88, $88, $88, $88, $88, $88, $88; 12:54A0
    db $88, $89, $99, $99, $88, $88, $87, $77, $77, $77, $88, $88, $76, $43, $21, $23; 12:54B0
    db $35, $77, $89, $99, $AA, $AA, $BA, $99, $87, $65, $56, $67, $89, $9A, $AA, $99; 12:54C0
    db $99, $99, $88, $76, $65, $55, $66, $78, $88, $99, $98, $88, $88, $88, $87, $88; 12:54D0
    db $88, $89, $99, $88, $88, $87, $77, $77, $67, $77, $88, $9A, $98, $74, $32, $02; 12:54E0
    db $33, $57, $79, $99, $99, $AA, $AB, $AA, $97, $66, $55, $66, $79, $9A, $AA, $99; 12:54F0
    db $99, $99, $98, $87, $66, $55, $66, $78, $88, $88, $87, $78, $88, $88, $87, $77; 12:5500
    db $78, $89, $99, $99, $88, $87, $77, $77, $77, $77, $77, $78, $88, $9A, $98, $75; 12:5510
    db $33, $11, $33, $47, $78, $99, $99, $AA, $AB, $A9, $98, $66, $54, $66, $79, $9A; 12:5520
    db $BA, $AA, $99, $99, $88, $87, $66, $65, $66, $68, $88, $88, $88, $88, $88, $88; 12:5530
    db $88, $88, $78, $88, $89, $89, $88, $88, $77, $77, $88, $88, $77, $77, $77, $78; 12:5540
    db $89, $98, $87, $44, $32, $34, $46, $78, $99, $99, $99, $9A, $A9, $98, $76, $65; 12:5550
    db $66, $78, $9A, $BA, $AA, $99, $88, $88, $88, $77, $65, $66, $67, $78, $98, $99; 12:5560
    db $88, $88, $88, $87, $77, $77, $77, $88, $89, $99, $98, $88, $87, $77, $77, $77; 12:5570
    db $77, $77, $77, $78, $88, $99, $88, $75, $53, $24, $34, $67, $89, $99, $99, $AA; 12:5580
    db $AA, $99, $98, $77, $66, $67, $88, $9A, $99, $99, $88, $88, $88, $87, $76, $66; 12:5590
    db $67, $77, $88, $99, $88, $88, $77, $77, $77, $77, $77, $78, $88, $89, $99, $88; 12:55A0
    db $77, $77, $77, $77, $77, $77, $77, $77, $88, $88, $89, $98, $88, $66, $54, $44; 12:55B0
    db $56, $77, $89, $99, $99, $99, $99, $98, $88, $76, $77, $78, $88, $99, $99, $88; 12:55C0
    db $88, $88, $87, $77, $77, $76, $77, $78, $88, $88, $88, $88, $77, $87, $77, $78; 12:55D0
    db $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77; 12:55E0
    db $77, $88, $88, $88, $76, $65, $55, $56, $77, $88, $88, $88, $99, $99, $99, $98; 12:55F0
    db $88, $77, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $78, $88, $88, $88; 12:5600
    db $88, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $78, $77, $77; 12:5610
    db $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $77; 12:5620
    db $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:5630
    db $88, $78, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77; 12:5640
    db $78, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88; 12:5650
    db $88, $87, $77, $77, $78, $88, $78, $88, $88, $88, $77, $77, $88, $88, $88, $88; 12:5660
    db $88, $88, $88, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:5670

;; PCM05: 2272 bytes = 4544 4-bit samples (rate 2) for SFXInst18
PCM05:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:5680
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:5690
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $89, $AB, $B7; 12:56A0
    db $31, $26, $75, $00, $04, $78, $88, $89, $AB, $CD, $B9, $66, $8A, $96, $44, $68; 12:56B0
    db $99, $88, $89, $AA, $A9, $76, $67, $88, $76, $68, $AA, $AA, $9A, $AA, $AA, $98; 12:56C0
    db $88, $88, $87, $67, $88, $88, $78, $9B, $C9, $30, $01, $55, $10, $01, $59, $AA; 12:56D0
    db $A9, $9B, $DE, $C8, $43, $68, $96, $44, $69, $BC, $CB, $A9, $AB, $B8, $52, $24; 12:56E0
    db $66, $66, $79, $BD, $ED, $BA, $9A, $AA, $87, $67, $78, $88, $77, $78, $99, $75; 12:56F0
    db $56, $8A, $BD, $A0, $00, $28, $60, $00, $38, $BE, $FB, $77, $BF, $F8, $20, $27; 12:5700
    db $88, $98, $66, $9F, $FE, $96, $79, $97, $53, $11, $27, $A8, $65, $9D, $ED, $B9; 12:5710
    db $87, $8A, $CA, $76, $8B, $BB, $A9, $97, $78, $97, $53, $57, $89, $CE, $C0, $00; 12:5720
    db $24, $20, $00, $03, $BF, $FB, $68, $CB, $B8, $63, $00, $6B, $C9, $79, $CD, $FF; 12:5730
    db $EA, $42, $57, $64, $23, $46, $AD, $B8, $57, $AB, $BA, $97, $67, $CE, $DA, $9A; 12:5740
    db $AA, $BB, $85, $34, $67, $77, $77, $79, $DF, $F2, $00, $00, $12, $31, $00, $CF; 12:5750
    db $FF, $DA, $75, $9D, $83, $00, $26, $AF, $FC, $9A, $EF, $FD, $93, $00, $38, $74; 12:5760
    db $45, $68, $BD, $C8, $57, $89, $99, $97, $69, $DE, $EC, $BA, $88, $AA, $86, $45; 12:5770
    db $56, $89, $99, $BE, $B0, $00, $00, $02, $40, $03, $BE, $FF, $FD, $75, $AB, $85; 12:5780
    db $22, $22, $7D, $DB, $AA, $CC, $DF, $D8, $42, $34, $45, $64, $23, $59, $BB, $BA; 12:5790
    db $88, $9B, $CA, $99, $99, $BC, $CB, $99, $98, $89, $98, $66, $88, $AD, $F6, $00; 12:57A0
    db $00, $00, $32, $00, $28, $DF, $FF, $C7, $8B, $CB, $85, $30, $16, $AB, $B9, $99; 12:57B0
    db $AC, $FF, $C7, $54, $45, $77, $52, $03, $79, $DD, $CA, $89, $BC, $CB, $A8, $67; 12:57C0
    db $AB, $BA, $98, $78, $BC, $B9, $98, $AD, $C4, $00, $00, $00, $10, $00, $05, $AD; 12:57D0
    db $FF, $CB, $BC, $ED, $A9, $62, $25, $79, $77, $87, $8B, $DF, $D9, $98, $77, $87; 12:57E0
    db $63, $35, $79, $AB, $BA, $9A, $BC, $CB, $A9, $78, $9A, $98, $77, $78, $9A, $A9; 12:57F0
    db $89, $BD, $C5, $10, $00, $00, $00, $00, $04, $89, $BB, $AB, $DF, $FF, $CA, $98; 12:5800
    db $89, $98, $43, $36, $89, $99, $87, $89, $BA, $88, $88, $8A, $AA, $88, $9A, $AA; 12:5810
    db $AA, $98, $9A, $A9, $88, $88, $88, $88, $77, $78, $77, $77, $77, $53, $22, $34; 12:5820
    db $32, $10, $12, $46, $66, $67, $88, $9A, $BA, $AA, $AB, $BB, $AA, $AA, $A9, $AA; 12:5830
    db $98, $87, $78, $88, $88, $78, $89, $99, $98, $88, $88, $88, $88, $88, $88, $88; 12:5840
    db $77, $77, $77, $76, $66, $66, $77, $77, $67, $77, $77, $77, $77, $77, $77, $67; 12:5850
    db $77, $88, $88, $77, $77, $77, $77, $67, $77, $77, $77, $78, $88, $99, $99, $9A; 12:5860
    db $A9, $99, $99, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77; 12:5870
    db $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $78, $88, $88; 12:5880
    db $88, $88, $88, $77, $77, $77, $78, $88, $88, $88, $99, $88, $88, $88, $87, $77; 12:5890
    db $77, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $77, $88; 12:58A0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77; 12:58B0
    db $77, $77, $78, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $88, $87; 12:58C0
    db $87, $77, $77, $77, $77, $77, $87, $87, $77, $88, $88, $88, $88, $88, $88, $88; 12:58D0
    db $88, $87, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $88, $88, $88; 12:58E0
    db $88, $88, $87, $87, $77, $77, $77, $87, $87, $87, $77, $64, $75, $A8, $3C, $69; 12:58F0
    db $88, $87, $95, $79, $77, $7C, $69, $A6, $99, $87, $9B, $5A, $98, $98, $88, $9A; 12:5900
    db $5A, $88, $86, $97, $87, $77, $85, $85, $95, $86, $87, $76, $86, $85, $85, $76; 12:5910
    db $58, $77, $67, $85, $88, $69, $86, $78, $86, $89, $69, $88, $99, $87, $7A, $78; 12:5920
    db $88, $87, $97, $7A, $58, $86, $88, $77, $99, $6A, $86, $98, $78, $96, $79, $67; 12:5930
    db $A6, $69, $66, $99, $68, $96, $89, $68, $86, $77, $77, $87, $89, $77, $97, $88; 12:5940
    db $78, $88, $78, $88, $88, $78, $88, $78, $78, $78, $88, $88, $77, $78, $78, $86; 12:5950
    db $78, $77, $77, $76, $87, $89, $88, $88, $88, $88, $88, $87, $87, $88, $78, $88; 12:5960
    db $88, $88, $88, $88, $78, $87, $88, $88, $89, $89, $87, $77, $65, $55, $33, $22; 12:5970
    db $23, $34, $56, $78, $99, $AB, $AB, $BB, $AB, $BA, $BB, $BB, $BB, $BB, $BB, $BB; 12:5980
    db $AA, $AB, $A9, $99, $AC, $E1, $28, $00, $00, $00, $00, $06, $23, $8B, $A9, $BB; 12:5990
    db $CC, $88, $AA, $66, $87, $99, $8A, $CA, $9B, $B9, $89, $8A, $98, $9B, $BA, $CE; 12:59A0
    db $EE, $EE, $FE, $DB, $DF, $FF, $40, $74, $00, $00, $00, $00, $CB, $4B, $FF, $BB; 12:59B0
    db $B7, $93, $01, $53, $04, $AB, $CD, $EF, $FB, $AB, $82, $23, $34, $46, $BD, $CD; 12:59C0
    db $FF, $FE, $FE, $DB, $BC, $DD, $FF, $C0, $7F, $00, $02, $00, $20, $EF, $08, $FF; 12:59D0
    db $73, $C8, $53, $01, $74, $01, $FD, $8D, $FF, $FB, $AA, $C1, $05, $40, $05, $A8; 12:59E0
    db $AB, $EF, $EC, $FF, $D9, $CE, $DE, $FF, $90, $FA, $00, $05, $00, $30, $F7, $3D; 12:59F0
    db $FF, $3A, $F6, $52, $05, $20, $06, $E4, $9E, $FF, $CD, $EC, $91, $18, $00, $07; 12:5A00
    db $63, $9E, $FF, $DF, $FF, $BC, $FE, $9E, $FB, $08, $F0, $00, $50, $07, $0F, $93; 12:5A10
    db $DF, $F4, $9F, $73, $31, $62, $01, $6C, $28, $EF, $CB, $EF, $B7, $56, $60, $03; 12:5A20
    db $52, $39, $DC, $CE, $FF, $EE, $FF, $DE, $F9, $07, $B0, $00, $40, $06, $0C, $66; 12:5A30
    db $FF, $E6, $DF, $64, $64, $50, $12, $56, $19, $DB, $9D, $FE, $9A, $A8, $41, $33; 12:5A40
    db $11, $59, $89, $EF, $EF, $FF, $FF, $FF, $D0, $5B, $00, $03, $00, $40, $95, $8E; 12:5A50
    db $FF, $BF, $F8, $79, $64, $03, $21, $22, $78, $79, $DE, $BB, $DB, $96, $77, $53; 12:5A60
    db $58, $77, $AD, $ED, $FF, $FF, $FB, $5F, $30, $00, $00, $00, $02, $1A, $AB, $CF; 12:5A70
    db $FE, $BF, $C9, $57, $70, $21, $32, $14, $68, $67, $CB, $89, $CB, $8A, $BA, $AA; 12:5A80
    db $DC, $EF, $FF, $79, $F3, $24, $70, $04, $00, $00, $63, $76, $DF, $9C, $FE, $B8; 12:5A90
    db $F9, $57, $68, $14, $54, $32, $66, $55, $8A, $68, $CB, $AB, $FE, $EF, $FF, $FB; 12:5AA0
    db $8F, $90, $45, $10, $02, $00, $06, $33, $7C, $EA, $BF, $FB, $AF, $D5, $88, $82; 12:5AB0
    db $36, $33, $15, $63, $58, $A6, $9D, $AA, $CE, $DC, $FF, $FF, $F9, $CF, $22, $74; 12:5AC0
    db $00, $30, $00, $12, $05, $7A, $BA, $FF, $DD, $EF, $98, $B8, $53, $63, $10, $33; 12:5AD0
    db $03, $67, $68, $DB, $BD, $FF, $EF, $FF, $FF, $FC, $6E, $B0, $15, $30, $02, $00; 12:5AE0
    db $04, $11, $68, $A8, $BF, $EC, $CF, $F8, $AB, $94, $47, $20, $03, $20, $56, $56; 12:5AF0
    db $9C, $AC, $EF, $EF, $FF, $EF, $FF, $ED, $4A, $D0, $23, $30, $06, $00, $04, $30; 12:5B00
    db $88, $9A, $AE, $DB, $CC, $E7, $9C, $84, $69, $31, $56, $24, $78, $58, $BA, $BB; 12:5B10
    db $DD, $DC, $ED, $BB, $BA, $9A, $A9, $74, $85, $33, $34, $02, $31, $22, $44, $45; 12:5B20
    db $67, $77, $99, $89, $A9, $88, $98, $88, $78, $77, $88, $88, $A9, $9B, $AA, $BA; 12:5B30
    db $AA, $9B, $99, $A8, $98, $88, $79, $76, $87, $77, $77, $66, $65, $65, $45, $43; 12:5B40
    db $44, $44, $55, $56, $77, $78, $88, $89, $98, $99, $9A, $98, $B9, $89, $A9, $89; 12:5B50
    db $A8, $9A, $8A, $89, $88, $97, $89, $77, $76, $86, $68, $77, $87, $68, $76, $77; 12:5B60
    db $57, $76, $77, $66, $87, $67, $76, $86, $67, $75, $87, $68, $87, $88, $88, $98; 12:5B70
    db $8A, $79, $98, $A9, $88, $98, $78, $86, $88, $68, $88, $78, $98, $89, $79, $97; 12:5B80
    db $89, $77, $78, $67, $87, $79, $67, $96, $78, $76, $78, $76, $A6, $88, $78, $79; 12:5B90
    db $87, $88, $77, $86, $87, $77, $77, $85, $97, $78, $78, $79, $87, $98, $88, $78; 12:5BA0
    db $87, $87, $96, $87, $88, $87, $89, $78, $89, $68, $87, $97, $88, $79, $76, $87; 12:5BB0
    db $76, $88, $58, $86, $88, $77, $88, $68, $87, $69, $67, $87, $77, $87, $88, $78; 12:5BC0
    db $88, $88, $79, $87, $88, $88, $97, $88, $88, $98, $88, $78, $87, $78, $85, $87; 12:5BD0
    db $59, $67, $87, $87, $88, $78, $87, $86, $87, $68, $58, $84, $88, $77, $88, $79; 12:5BE0
    db $87, $88, $87, $88, $78, $87, $8A, $58, $87, $87, $87, $87, $78, $86, $78, $78; 12:5BF0
    db $87, $88, $76, $87, $79, $69, $68, $87, $98, $78, $78, $77, $86, $88, $76, $A7; 12:5C00
    db $69, $78, $7A, $86, $A7, $69, $76, $88, $77, $88, $87, $78, $78, $78, $87, $88; 12:5C10
    db $78, $69, $86, $98, $69, $86, $87, $87, $97, $7A, $85, $98, $77, $86, $78, $86; 12:5C20
    db $8A, $79, $79, $86, $98, $78, $87, $77, $78, $77, $86, $87, $78, $79, $76, $97; 12:5C30
    db $78, $67, $78, $67, $87, $69, $76, $88, $76, $98, $68, $96, $78, $76, $A8, $79; 12:5C40
    db $88, $78, $87, $98, $59, $86, $87, $77, $77, $77, $A6, $79, $78, $87, $88, $87; 12:5C50
    db $7A, $86, $A8, $79, $86, $89, $75, $98, $68, $96, $89, $78, $88, $87, $87, $78; 12:5C60
    db $78, $77, $78, $68, $87, $78, $88, $88, $87, $87, $67, $66, $65, $65, $66, $67; 12:5C70
    db $77, $87, $88, $88, $88, $98, $99, $9A, $99, $9A, $AA, $9A, $9A, $99, $99, $98; 12:5C80
    db $8A, $98, $A8, $99, $99, $9A, $B9, $04, $A0, $00, $01, $00, $01, $55, $27, $AA; 12:5C90
    db $CB, $AC, $EC, $99, $CA, $78, $78, $88, $68, $99, $77, $98, $77, $78, $98, $78; 12:5CA0
    db $AA, $99, $BB, $BA, $AA, $BA, $99, $A9, $88, $9A, $BC, $DF, $50, $F7, $03, $00; 12:5CB0
    db $00, $00, $39, $10, $CB, $AE, $99, $EE, $A5, $8D, $75, $75, $8B, $75, $9C, $C7; 12:5CC0
    db $9B, $AB, $86, $79, $72, $48, $76, $67, $9B, $A8, $AC, $C9, $8A, $AA, $98, $9B; 12:5CD0
    db $B9, $AC, $ED, $DF, $F8, $0E, $C0, $40, $00, $02, $01, $F3, $3B, $FC, $FC, $8D; 12:5CE0
    db $EF, $13, $C5, $55, $45, $BB, $77, $BF, $9A, $A8, $B9, $65, $69, $63, $68, $78; 12:5CF0
    db $78, $AB, $A7, $8A, $97, $78, $99, $88, $9B, $CA, $BC, $DC, $BB, $BB, $DF, $90; 12:5D00
    db $2F, $00, $00, $40, $10, $0F, $84, $8D, $FE, $E8, $8C, $F6, $0A, $87, $75, $68; 12:5D10
    db $DA, $59, $DB, $88, $69, $98, $64, $AA, $77, $89, $A8, $77, $7A, $64, $78, $86; 12:5D20
    db $77, $9A, $A9, $AD, $CB, $BB, $BB, $B9, $9A, $98, $78, $AC, $50, $49, $00, $00; 12:5D30
    db $30, $60, $0F, $78, $AB, $EC, $E9, $7C, $C6, $58, $78, $87, $58, $C9, $69, $A9; 12:5D40
    db $99, $77, $AA, $77, $A9, $88, $77, $89, $65, $78, $66, $76, $89, $87, $9A, $AA; 12:5D50
    db $AB, $BB, $B9, $AA, $98, $88, $88, $77, $78, $AB, $80, $2B, $01, $00, $50, $60; 12:5D60
    db $0D, $68, $98, $DA, $EA, $5B, $DA, $88, $99, $AA, $66, $B9, $76, $78, $89, $76; 12:5D70
    db $9A, $A8, $89, $AA, $97, $78, $86, $56, $77, $76, $67, $88, $78, $99, $99, $9A; 12:5D80
    db $AA, $9A, $9A, $98, $88, $87, $66, $77, $67, $78, $AA, $42, $A4, $25, $13, $13; 12:5D90
    db $50, $46, $47, $79, $89, $D9, $9C, $DB, $AC, $A9, $BA, $88, $98, $78, $87, $78; 12:5DA0
    db $87, $88, $77, $88, $78, $88, $77, $77, $77, $77, $77, $77, $78, $88, $88, $99; 12:5DB0
    db $99, $99, $A9, $99, $99, $88, $88, $88, $77, $77, $77, $76, $67, $77, $76, $66; 12:5DC0
    db $45, $54, $33, $42, $34, $55, $68, $77, $9A, $9B, $BB, $AB, $CA, $BB, $AA, $A9; 12:5DD0
    db $87, $88, $67, $76, $67, $76, $78, $87, $88, $88, $88, $88, $88, $88, $89, $99; 12:5DE0
    db $99, $88, $88, $88, $87, $78, $87, $88, $88, $88, $88, $87, $77, $77, $66, $66; 12:5DF0
    db $76, $77, $86, $57, $65, $55, $42, $44, $24, $55, $57, $97, $8A, $AA, $BB, $AB; 12:5E00
    db $CB, $AB, $BB, $AB, $A9, $99, $88, $87, $77, $76, $66, $66, $66, $66, $77, $77; 12:5E10
    db $88, $88, $89, $99, $99, $89, $98, $88, $88, $88, $88, $88, $88, $87, $77, $77; 12:5E20
    db $76, $66, $66, $66, $66, $66, $78, $88, $77, $76, $66, $54, $45, $44, $56, $67; 12:5E30
    db $88, $89, $9A, $AB, $BA, $BB, $BB, $BB, $AA, $A9, $99, $88, $77, $77, $66, $66; 12:5E40
    db $66, $67, $77, $78, $88, $88, $88, $89, $89, $88, $88, $88, $88, $87, $77, $77; 12:5E50
    db $77, $77, $77, $77, $77, $77, $77, $76, $66, $66, $66, $67, $77, $88, $88, $88; 12:5E60
    db $88, $77, $76, $66, $66, $66, $77, $78, $88, $99, $9A, $AA, $AB, $BA, $AA, $A9; 12:5E70
    db $99, $88, $87, $76, $76, $66, $66, $66, $77, $78, $88, $88, $89, $99, $99, $88; 12:5E80
    db $88, $88, $88, $88, $77, $77, $77, $77, $77, $76, $67, $77, $67, $77, $77, $77; 12:5E90
    db $77, $77, $78, $88, $88, $88, $88, $88, $87, $77, $66, $66, $66, $66, $77, $78; 12:5EA0
    db $88, $99, $99, $9A, $AA, $A9, $99, $98, $88, $88, $77, $77, $77, $77, $77, $78; 12:5EB0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $76, $67; 12:5EC0
    db $66, $66, $77, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88; 12:5ED0
    db $88, $88, $87, $77, $77, $77, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88; 12:5EE0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:5EF0
    db $87, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $77, $77, $77, $77; 12:5F00
    db $77, $77, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88; 12:5F10
    db $88, $87, $78, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:5F20
    db $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $77, $77, $77; 12:5F30
    db $77, $78, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:5F40
    db $88, $88, $88, $88, $88, $88, $77, $87, $77, $78, $88, $88, $88, $88, $88, $88; 12:5F50

;; PCM06: 1696 bytes = 3392 4-bit samples (rate 2) for SFXInst19, SFXInst20
PCM06:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:5F60
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $87; 12:5F70
    db $88, $88, $88, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:5F80
    db $88, $88, $88, $88, $88, $88, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:5F90
    db $88, $88, $88, $88, $78, $78, $88, $87, $88, $87, $88, $87, $88, $88, $87, $88; 12:5FA0
    db $88, $88, $87, $87, $87, $88, $88, $88, $88, $88, $88, $78, $78, $78, $87, $87; 12:5FB0
    db $87, $78, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $78, $78, $78, $78; 12:5FC0
    db $88, $87, $87, $87, $87, $87, $87, $87, $87, $87, $87, $87, $88, $88, $88, $78; 12:5FD0
    db $88, $88, $78, $78, $87, $87, $88, $87, $87, $87, $87, $87, $87, $87, $87, $77; 12:5FE0
    db $78, $78, $88, $87, $88, $87, $87, $87, $87, $88, $88, $88, $88, $88, $78, $78; 12:5FF0
    db $78, $78, $78, $78, $78, $68, $78, $78, $78, $78, $77, $77, $87, $87, $87, $87; 12:6000
    db $88, $87, $87, $87, $87, $87, $87, $87, $86, $87, $87, $87, $87, $87, $87, $77; 12:6010
    db $87, $87, $78, $78, $78, $78, $78, $78, $78, $78, $78, $78, $78, $78, $78, $78; 12:6020
    db $78, $78, $78, $78, $78, $88, $88, $88, $87, $87, $87, $87, $87, $88, $77, $88; 12:6030
    db $87, $78, $78, $87, $87, $87, $87, $87, $86, $86, $97, $87, $96, $97, $87, $88; 12:6040
    db $87, $87, $87, $88, $88, $78, $88, $78, $78, $78, $78, $87, $87, $87, $87, $87; 12:6050
    db $87, $86, $86, $96, $87, $87, $87, $87, $88, $78, $78, $78, $78, $78, $78, $78; 12:6060
    db $78, $78, $78, $78, $77, $77, $77, $78, $87, $87, $88, $88, $79, $78, $78, $88; 12:6070
    db $88, $78, $78, $88, $87, $87, $88, $78, $78, $78, $87, $87, $88, $78, $77, $87; 12:6080
    db $87, $78, $78, $78, $78, $78, $78, $78, $78, $78, $87, $78, $78, $78, $87, $87; 12:6090
    db $88, $78, $88, $87, $88, $87, $87, $88, $88, $87, $88, $78, $78, $78, $78, $78; 12:60A0
    db $88, $78, $88, $88, $88, $88, $78, $88, $87, $87, $78, $78, $78, $78, $78, $77; 12:60B0
    db $87, $87, $88, $87, $88, $88, $88, $78, $78, $88, $88, $78, $78, $78, $87, $88; 12:60C0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $78, $88, $78, $78, $78, $88; 12:60D0
    db $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:60E0
    db $88, $87, $87, $77, $77, $77, $77, $88, $78, $88, $87, $88, $88, $88, $88, $88; 12:60F0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $87, $88, $88, $88, $88; 12:6100
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77; 12:6110
    db $77, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:6120
    db $88, $88, $88, $88, $88, $88, $88, $88, $78, $77, $88, $77, $77, $88, $77, $88; 12:6130
    db $77, $87, $77, $77, $77, $77, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88; 12:6140
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $99, $99, $98, $88, $76; 12:6150
    db $55, $43, $32, $22, $33, $45, $66, $78, $89, $AA, $AA, $AA, $AA, $AA, $AA, $AA; 12:6160
    db $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $99, $99, $99, $98, $66, $42, $32; 12:6170
    db $00, $00, $00, $00, $13, $45, $78, $8B, $CC, $DD, $CC, $DD, $CC, $CA, $AA, $97; 12:6180
    db $76, $65, $55, $55, $67, $88, $99, $AB, $CC, $CC, $CC, $CC, $BB, $BB, $AA, $AB; 12:6190
    db $B8, $76, $22, $20, $00, $00, $00, $00, $13, $46, $77, $8B, $CC, $DD, $CC, $EE; 12:61A0
    db $DD, $CB, $AA, $98, $77, $65, $55, $45, $66, $78, $88, $9B, $BC, $CC, $CC, $CC; 12:61B0
    db $CC, $CB, $CC, $CD, $B7, $96, $14, $20, $00, $00, $00, $00, $22, $46, $86, $8C; 12:61C0
    db $DD, $DD, $CD, $FE, $DD, $A9, $9A, $75, $64, $45, $55, $57, $88, $88, $AA, $BD; 12:61D0
    db $CD, $DD, $DE, $DD, $ED, $DE, $FF, $00, $A0, $04, $00, $07, $21, $B3, $29, $F5; 12:61E0
    db $69, $38, $9F, $87, $DA, $AB, $B5, $67, $75, $48, $57, $CA, $99, $A9, $89, $96; 12:61F0
    db $9B, $9A, $BB, $AC, $ED, $CE, $ED, $FF, $F6, $05, $00, $50, $00, $1B, $6A, $B0; 12:6200
    db $1B, $6A, $32, $44, $EF, $AC, $98, $EA, $95, $13, $68, $86, $7A, $9E, $C9, $86; 12:6210
    db $77, $89, $78, $BB, $CC, $BB, $BD, $FD, $EE, $FF, $F5, $00, $00, $20, $00, $0C; 12:6220
    db $BB, $F2, $04, $6A, $20, $20, $8F, $FE, $A9, $DB, $CB, $20, $24, $77, $88, $7B; 12:6230
    db $FD, $B8, $56, $6A, $A7, $8A, $AD, $DC, $BB, $EF, $EF, $FF, $FB, $00, $00, $00; 12:6240
    db $20, $09, $EB, $FD, $54, $4B, $60, $10, $09, $DF, $C9, $DE, $DF, $D5, $30, $24; 12:6250
    db $47, $54, $BC, $ED, $99, $87, $BA, $78, $68, $AB, $DC, $BE, $EF, $FF, $FF, $50; 12:6260
    db $00, $00, $00, $00, $CF, $EF, $CC, $67, $C4, $00, $00, $47, $E9, $AF, $FF, $FF; 12:6270
    db $B5, $27, $42, $22, $37, $AF, $CA, $CA, $BB, $99, $65, $98, $9A, $AA, $BD, $FE; 12:6280
    db $EF, $EF, $F0, $00, $00, $00, $00, $29, $AE, $AB, $B7, $DB, $63, $01, $43, $88; 12:6290
    db $69, $AE, $ED, $DA, $89, $99, $74, $65, $79, $AA, $89, $BB, $CB, $99, $79, $98; 12:62A0
    db $88, $79, $AB, $B9, $A9, $99, $A9, $53, $33, $33, $21, $00, $23, $44, $56, $78; 12:62B0
    db $99, $99, $9A, $99, $88, $77, $88, $88, $89, $9A, $A9, $98, $89, $88, $88, $89; 12:62C0
    db $99, $88, $88, $88, $88, $99, $99, $88, $87, $77, $77, $77, $77, $77, $77, $77; 12:62D0
    db $77, $77, $77, $77, $77, $77, $77, $76, $66, $66, $67, $77, $78, $78, $88, $88; 12:62E0
    db $88, $89, $99, $99, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77; 12:62F0
    db $77, $77, $78, $88, $88, $88, $88, $87, $77, $77, $77, $77, $88, $88, $88, $77; 12:6300
    db $77, $66, $66, $67, $77, $88, $88, $88, $88, $88, $77, $77, $77, $77, $88, $88; 12:6310
    db $88, $88, $88, $77, $77, $78, $88, $88, $88, $88, $88, $88, $87, $77, $77, $88; 12:6320
    db $88, $88, $88, $88, $77, $77, $77, $77, $77, $88, $88, $99, $88, $88, $77, $76; 12:6330
    db $66, $77, $78, $88, $88, $88, $87, $77, $77, $77, $77, $78, $88, $88, $88, $87; 12:6340
    db $77, $77, $77, $77, $88, $88, $88, $88, $88, $78, $88, $77, $88, $88, $88, $88; 12:6350
    db $88, $77, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $87, $78, $77, $77; 12:6360
    db $88, $88, $88, $66, $89, $87, $56, $89, $86, $57, $AA, $86, $78, $98, $76, $88; 12:6370
    db $87, $78, $88, $77, $89, $87, $78, $88, $76, $78, $88, $77, $88, $87, $77, $87; 12:6380
    db $67, $77, $78, $88, $78, $88, $88, $88, $87, $77, $87, $77, $78, $88, $78, $88; 12:6390
    db $77, $78, $88, $78, $88, $87, $77, $87, $88, $88, $88, $88, $88, $77, $77, $77; 12:63A0
    db $78, $78, $88, $87, $87, $77, $88, $77, $78, $88, $78, $88, $87, $78, $88, $88; 12:63B0
    db $98, $98, $88, $88, $88, $88, $88, $88, $76, $55, $54, $44, $55, $56, $77, $88; 12:63C0
    db $98, $89, $88, $78, $88, $88, $88, $99, $AA, $AA, $AA, $99, $88, $88, $88, $89; 12:63D0
    db $99, $99, $AA, $BB, $CC, $40, $56, $20, $03, $40, $03, $8A, $8B, $CB, $CB, $B8; 12:63E0
    db $68, $95, $45, $78, $68, $AA, $BB, $BB, $A9, $A7, $54, $55, $45, $78, $9A, $AB; 12:63F0
    db $AA, $BA, $98, $88, $88, $98, $89, $AA, $BB, $BB, $CE, $FB, $00, $64, $00, $03; 12:6400
    db $32, $45, $9D, $EF, $B6, $AC, $83, $01, $53, $56, $6A, $DF, $FC, $CE, $DA, $75; 12:6410
    db $54, $45, $43, $68, $AA, $9B, $BB, $A8, $77, $77, $76, $79, $AA, $AA, $BB, $AA; 12:6420
    db $99, $99, $87, $78, $9E, $F0, $02, $75, $00, $05, $68, $95, $9C, $FF, $61, $58; 12:6430
    db $75, $03, $79, $DC, $AB, $DF, $FA, $67, $78, $62, $34, $6A, $B9, $9A, $CD, $95; 12:6440
    db $56, $76, $55, $68, $AB, $99, $9A, $B9, $88, $89, $98, $88, $8A, $98, $87, $78; 12:6450
    db $9A, $BB, $00, $23, $20, $01, $66, $AC, $9A, $BE, $F8, $24, $65, $53, $57, $8C; 12:6460
    db $FC, $AB, $CE, $A6, $55, $56, $66, $67, $AD, $BA, $98, $87, $55, $44, $78, $88; 12:6470
    db $8A, $BA, $99, $88, $87, $88, $89, $99, $99, $99, $88, $75, $56, $66, $67, $9B; 12:6480
    db $E9, $00, $54, $40, $03, $58, $DC, $89, $AE, $D6, $44, $45, $77, $76, $8D, $FC; 12:6490
    db $A9, $9A, $87, $64, $47, $99, $88, $AB, $BA, $86, $77, $76, $55, $78, $99, $89; 12:64A0
    db $99, $88, $77, $78, $99, $88, $99, $88, $77, $66, $66, $66, $77, $77, $77, $88; 12:64B0
    db $9A, $C8, $00, $35, $52, $14, $68, $CD, $A9, $9B, $C8, $54, $35, $78, $88, $8B; 12:64C0
    db $ED, $B9, $99, $88, $76, $56, $89, $A8, $8A, $AA, $97, $76, $66, $66, $66, $89; 12:64D0
    db $98, $88, $88, $88, $87, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $77; 12:64E0
    db $77, $76, $78, $89, $AB, $70, $15, $66, $23, $67, $9C, $CA, $88, $BB, $75, $55; 12:64F0
    db $67, $89, $88, $BD, $CA, $88, $87, $66, $55, $57, $99, $88, $9A, $A8, $76, $56; 12:6500
    db $77, $66, $79, $AA, $99, $99, $98, $87, $67, $88, $88, $88, $88, $88, $77, $77; 12:6510
    db $66, $67, $77, $77, $88, $87, $77, $88, $89, $A7, $43, $56, $54, $56, $78, $9A; 12:6520
    db $98, $89, $98, $65, $66, $78, $89, $9A, $BB, $A9, $98, $87, $77, $67, $78, $88; 12:6530
    db $89, $98, $87, $77, $66, $77, $78, $89, $99, $88, $88, $87, $77, $78, $88, $88; 12:6540
    db $88, $77, $77, $77, $77, $77, $77, $76, $66, $67, $77, $78, $88, $88, $88, $88; 12:6550
    db $77, $67, $76, $66, $77, $88, $88, $88, $88, $87, $88, $88, $88, $89, $99, $98; 12:6560
    db $88, $88, $87, $77, $88, $88, $88, $88, $88, $77, $88, $88, $88, $88, $88, $88; 12:6570
    db $88, $87, $77, $77, $77, $78, $88, $77, $77, $77, $77, $77, $77, $77, $78, $87; 12:6580
    db $77, $77, $78, $77, $78, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $88; 12:6590
    db $77, $88, $87, $78, $87, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:65A0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77; 12:65B0
    db $77, $77, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88, $87, $77, $77, $77; 12:65C0
    db $88, $88, $88, $88, $88, $87, $77, $77, $78, $88, $88, $88, $88, $88, $87, $88; 12:65D0
    db $87, $88, $88, $88, $88, $88, $77, $77, $77, $77, $88, $88, $88, $88, $87, $77; 12:65E0
    db $78, $77, $88, $88, $88, $88, $88, $87, $77, $87, $78, $87, $77, $77, $77, $88; 12:65F0

;; PCM07: 1968 bytes = 3936 4-bit samples (rate 2) for SFXInst21
PCM07:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $88, $88, $88, $88; 12:6600
    db $88, $88, $88, $88, $88, $88, $88, $87, $88, $88, $88, $88, $88, $88, $88, $88; 12:6610
    db $88, $88, $88, $88, $88, $88, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:6620
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:6630
    db $87, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $87, $88, $88, $88; 12:6640
    db $88, $88, $88, $88, $78, $77, $87, $77, $77, $77, $87, $87, $87, $88, $88, $88; 12:6650
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $78, $88, $88, $88, $88, $78; 12:6660
    db $78, $78, $78, $78, $78, $78, $78, $78, $78, $87, $87, $87, $87, $87, $87, $88; 12:6670
    db $78, $87, $87, $87, $87, $87, $88, $88, $88, $88, $88, $87, $87, $87, $87, $87; 12:6680
    db $78, $78, $78, $77, $77, $77, $77, $77, $77, $87, $87, $87, $87, $87, $87, $97; 12:6690
    db $87, $87, $88, $88, $88, $87, $87, $88, $88, $78, $78, $78, $77, $87, $88, $78; 12:66A0
    db $78, $78, $78, $78, $78, $88, $78, $78, $78, $78, $87, $87, $87, $87, $87, $87; 12:66B0
    db $87, $87, $87, $87, $87, $87, $78, $87, $77, $77, $88, $78, $78, $78, $78, $88; 12:66C0
    db $88, $88, $88, $88, $88, $88, $78, $78, $88, $78, $78, $78, $68, $78, $78, $78; 12:66D0
    db $78, $78, $78, $78, $78, $78, $87, $88, $88, $78, $78, $87, $87, $88, $88, $78; 12:66E0
    db $78, $88, $87, $77, $87, $88, $88, $78, $87, $87, $87, $87, $88, $88, $78, $78; 12:66F0
    db $78, $88, $87, $88, $87, $88, $78, $87, $87, $77, $87, $87, $87, $88, $78, $78; 12:6700
    db $87, $87, $87, $87, $87, $87, $87, $97, $87, $87, $87, $87, $87, $87, $88, $88; 12:6710
    db $78, $78, $78, $78, $87, $78, $88, $78, $78, $78, $87, $88, $79, $78, $78, $78; 12:6720
    db $88, $87, $88, $78, $78, $87, $87, $87, $97, $88, $88, $78, $77, $87, $88, $88; 12:6730
    db $78, $77, $87, $88, $78, $78, $68, $77, $77, $87, $87, $77, $87, $77, $77, $87; 12:6740
    db $87, $87, $87, $86, $87, $88, $78, $88, $87, $97, $88, $88, $88, $78, $78, $78; 12:6750
    db $78, $87, $78, $78, $78, $78, $78, $78, $68, $78, $78, $78, $78, $77, $87, $88; 12:6760
    db $77, $78, $87, $87, $87, $87, $77, $77, $87, $87, $78, $88, $78, $88, $88, $88; 12:6770
    db $88, $88, $87, $87, $87, $88, $88, $88, $88, $88, $88, $79, $79, $78, $88, $87; 12:6780
    db $87, $88, $78, $77, $87, $87, $77, $77, $77, $87, $87, $87, $87, $78, $78, $78; 12:6790
    db $78, $78, $78, $78, $88, $88, $88, $88, $88, $78, $88, $87, $87, $88, $88, $87; 12:67A0
    db $88, $78, $78, $88, $87, $87, $87, $87, $77, $87, $88, $88, $87, $88, $78, $78; 12:67B0
    db $88, $87, $87, $88, $78, $87, $87, $88, $78, $88, $88, $88, $88, $88, $88, $88; 12:67C0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $88, $78, $77, $88; 12:67D0
    db $87, $88, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:67E0
    db $88, $88, $88, $88, $88, $88, $88, $78, $88, $88, $78, $88, $77, $77, $87, $77; 12:67F0
    db $77, $77, $77, $77, $77, $76, $66, $66, $67, $77, $88, $89, $9A, $AA, $AA, $99; 12:6800
    db $99, $88, $88, $88, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77; 12:6810
    db $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77; 12:6820
    db $77, $76, $66, $66, $65, $55, $55, $66, $67, $88, $99, $AB, $BB, $CC, $CD, $DD; 12:6830
    db $DD, $DD, $DD, $CB, $98, $65, $31, $00, $00, $00, $00, $00, $24, $56, $8A, $CD; 12:6840
    db $EE, $EF, $FF, $FF, $FF, $FF, $FF, $FF, $EC, $95, $42, $00, $00, $00, $00, $00; 12:6850
    db $13, $56, $79, $AB, $CC, $BB, $BC, $CD, $DC, $DD, $EE, $FF, $FF, $FF, $D9, $65; 12:6860
    db $41, $00, $00, $00, $00, $01, $35, $67, $88, $9B, $BA, $AA, $BB, $CC, $CC, $DE; 12:6870
    db $EF, $FF, $FF, $FE, $B7, $55, $20, $00, $00, $00, $00, $12, $45, $67, $88, $AA; 12:6880
    db $AA, $AB, $BC, $CC, $CC, $DE, $FF, $FF, $FF, $EC, $86, $63, $10, $00, $00, $00; 12:6890
    db $00, $24, $55, $78, $89, $AA, $AA, $AB, $CC, $CC, $CD, $EF, $FF, $FF, $FE, $C7; 12:68A0
    db $76, $31, $00, $00, $00, $00, $02, $45, $57, $88, $AB, $AA, $AA, $BC, $CB, $CC; 12:68B0
    db $DE, $FF, $FF, $FE, $E9, $77, $52, $00, $00, $00, $01, $12, $45, $56, $98, $9B; 12:68C0
    db $A9, $9A, $AA, $CB, $BB, $CD, $EF, $FF, $FE, $DB, $77, $63, $10, $00, $00, $00; 12:68D0
    db $22, $35, $65, $89, $8A, $BA, $9A, $AA, $AB, $BB, $CE, $FF, $FF, $FA, $CA, $46; 12:68E0
    db $50, $00, $00, $12, $01, $56, $57, $86, $9B, $A9, $89, $88, $A9, $89, $AA, $CE; 12:68F0
    db $FF, $FF, $E9, $B8, $35, $30, $00, $10, $13, $22, $6A, $78, $97, $9A, $98, $77; 12:6900
    db $87, $99, $89, $AB, $CF, $FF, $FF, $C7, $94, $33, $00, $00, $20, $45, $45, $8B; 12:6910
    db $98, $88, $78, $87, $66, $78, $89, $AA, $BC, $EF, $FF, $FD, $68, $53, $30, $00; 12:6920
    db $03, $15, $76, $67, $BA, $88, $76, $77, $66, $57, $78, $A9, $AB, $BE, $FF, $FF; 12:6930
    db $F7, $65, $22, $10, $00, $12, $38, $77, $6A, $D9, $98, $66, $66, $65, $77, $79; 12:6940
    db $AB, $BB, $CE, $FF, $FF, $F5, $54, $22, $01, $00, $21, $58, $89, $6B, $DA, $B9; 12:6950
    db $75, $45, $54, $66, $68, $9B, $BC, $DD, $FF, $FF, $F9, $33, $00, $01, $00, $00; 12:6960
    db $28, $BD, $AA, $DB, $CD, $B8, $21, $01, $46, $66, $69, $CD, $FF, $FF, $FF, $FF; 12:6970
    db $F4, $20, $00, $02, $00, $00, $6B, $FF, $BC, $CB, $ED, $B6, $00, $00, $47, $88; 12:6980
    db $7A, $BE, $FF, $FE, $DD, $EF, $FA, $20, $00, $02, $30, $00, $16, $BF, $EC, $CA; 12:6990
    db $AC, $DB, $51, $00, $05, $9A, $99, $8A, $EF, $FE, $DB, $9B, $DF, $FB, $52, $00; 12:69A0
    db $04, $50, $00, $03, $7E, $CC, $A9, $9A, $DD, $85, $10, $24, $99, $98, $78, $9C; 12:69B0
    db $ED, $CA, $88, $9C, $DE, $EA, $74, $45, $55, $52, $00, $13, $59, $88, $78, $99; 12:69C0
    db $BB, $A8, $66, $67, $89, $98, $87, $78, $89, $89, $88, $88, $99, $A9, $99, $99; 12:69D0
    db $99, $98, $87, $76, $66, $65, $55, $55, $66, $66, $66, $67, $88, $88, $88, $88; 12:69E0
    db $99, $A9, $99, $99, $99, $98, $88, $88, $88, $88, $87, $77, $77, $78, $77, $77; 12:69F0
    db $77, $88, $77, $76, $66, $66, $65, $56, $67, $88, $89, $9A, $AA, $AA, $99, $88; 12:6A00
    db $77, $76, $66, $66, $67, $77, $78, $88, $89, $99, $99, $88, $77, $77, $76, $77; 12:6A10
    db $77, $78, $88, $88, $88, $88, $87, $77, $77, $77, $77, $88, $88, $88, $88, $88; 12:6A20
    db $88, $77, $77, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $77, $77; 12:6A30
    db $78, $88, $88, $88, $88, $88, $87, $77, $77, $77, $88, $88, $88, $88, $88, $77; 12:6A40
    db $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $78; 12:6A50
    db $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88; 12:6A60
    db $88, $88, $87, $77, $77, $77, $87, $78, $78, $88, $88, $88, $88, $87, $77, $77; 12:6A70
    db $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $77, $77, $88, $77, $77, $77; 12:6A80
    db $88, $88, $88, $88, $88, $88, $77, $77, $78, $77, $78, $88, $88, $88, $88, $88; 12:6A90
    db $88, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77; 12:6AA0
    db $77, $77, $77, $77, $88, $88, $88, $88, $87, $77, $78, $88, $88, $88, $88, $88; 12:6AB0
    db $87, $88, $99, $77, $78, $78, $86, $86, $88, $98, $67, $69, $99, $65, $78, $A9; 12:6AC0
    db $97, $58, $9A, $87, $55, $78, $A9, $86, $68, $89, $87, $76, $79, $85, $57, $99; 12:6AD0
    db $76, $46, $9B, $96, $35, $9A, $B8, $77, $9B, $A9, $77, $89, $97, $56, $88, $97; 12:6AE0
    db $76, $77, $77, $68, $88, $76, $78, $98, $77, $77, $78, $87, $78, $88, $77, $88; 12:6AF0
    db $86, $66, $78, $89, $88, $89, $98, $88, $88, $77, $77, $78, $88, $88, $88, $87; 12:6B00
    db $77, $87, $77, $77, $78, $78, $78, $87, $77, $77, $76, $76, $77, $77, $67, $88; 12:6B10
    db $88, $88, $89, $98, $99, $99, $99, $99, $98, $89, $99, $99, $99, $99, $AA, $A8; 12:6B20
    db $54, $32, $10, $00, $01, $24, $57, $9A, $BC, $CC, $CB, $98, $65, $45, $55, $57; 12:6B30
    db $9A, $BB, $BB, $BB, $BA, $99, $99, $99, $9A, $BC, $DE, $FF, $FF, $30, $22, $40; 12:6B40
    db $00, $00, $12, $74, $9F, $FE, $B9, $EE, $66, $00, $12, $65, $36, $BE, $FA, $BC; 12:6B50
    db $AB, $97, $53, $58, $77, $79, $CB, $DD, $CB, $BC, $C9, $89, $9B, $BD, $EF, $F0; 12:6B60
    db $01, $03, $00, $00, $16, $A9, $79, $FF, $BB, $57, $72, $52, $00, $59, $C8, $AE; 12:6B70
    db $EF, $FD, $A7, $79, $63, $32, $66, $8B, $99, $AC, $CA, $78, $78, $98, $88, $9C; 12:6B80
    db $ED, $EE, $FF, $FF, $F0, $00, $00, $00, $00, $3C, $FB, $AA, $FF, $AB, $20, $01; 12:6B90
    db $52, $00, $9B, $FF, $FF, $CF, $FD, $62, $02, $23, $53, $58, $DF, $D9, $AA, $9A; 12:6BA0
    db $75, $33, $8A, $99, $AB, $DD, $ED, $AB, $BC, $BC, $EF, $C0, $00, $00, $00, $00; 12:6BB0
    db $4E, $FB, $BA, $FF, $8A, $30, $02, $55, $23, $CB, $FF, $FF, $BB, $DB, $43, $11; 12:6BC0
    db $34, $77, $69, $CC, $CB, $98, $67, $86, $55, $78, $9A, $BA, $9B, $BA, $88, $88; 12:6BD0
    db $89, $AA, $9A, $CD, $FF, $F0, $00, $00, $00, $00, $1A, $FB, $99, $BF, $A9, $60; 12:6BE0
    db $02, $66, $53, $AD, $EF, $FE, $A9, $AB, $62, $20, $25, $89, $88, $CF, $ED, $B9; 12:6BF0
    db $76, $65, $32, $46, $99, $AB, $BB, $BB, $98, $77, $77, $78, $88, $AC, $CB, $BC; 12:6C00
    db $CE, $E5, $00, $00, $00, $00, $08, $FF, $DD, $BD, $D8, $72, $00, $35, $76, $6C; 12:6C10
    db $DF, $FF, $DA, $98, $83, $22, $14, $7A, $BB, $AD, $EC, $B8, $64, $45, $54, $46; 12:6C20
    db $7A, $BB, $A9, $99, $97, $76, $67, $89, $99, $9A, $AB, $A9, $98, $88, $88, $9A; 12:6C30
    db $80, $00, $02, $20, $22, $5A, $EC, $BA, $AC, $A8, $63, $03, $77, $87, $9C, $DE; 12:6C40
    db $EC, $99, $88, $74, $44, $57, $99, $99, $9B, $B9, $97, $55, $56, $65, $67, $89; 12:6C50
    db $AA, $99, $89, $87, $77, $78, $88, $88, $88, $99, $88, $88, $88, $87, $67, $88; 12:6C60
    db $88, $8A, $82, $02, $33, $33, $34, $69, $CB, $A9, $AA, $98, $75, $45, $67, $87; 12:6C70
    db $8A, $BC, $CB, $A9, $99, $87, $66, $67, $88, $98, $8A, $A9, $87, $66, $66, $66; 12:6C80
    db $67, $88, $98, $88, $89, $88, $77, $78, $88, $88, $89, $99, $88, $88, $77, $77; 12:6C90
    db $66, $77, $77, $78, $9A, $81, $03, $45, $43, $44, $7B, $C9, $98, $9A, $98, $75; 12:6CA0
    db $57, $89, $98, $AB, $BC, $B9, $88, $88, $76, $55, $67, $89, $99, $99, $98, $76; 12:6CB0
    db $67, $77, $78, $89, $9A, $A9, $98, $88, $77, $66, $77, $88, $88, $89, $88, $87; 12:6CC0
    db $77, $76, $66, $66, $78, $88, $78, $88, $88, $88, $53, $34, $55, $55, $56, $89; 12:6CD0
    db $98, $88, $98, $87, $66, $78, $99, $99, $AB, $BA, $98, $88, $87, $77, $78, $89; 12:6CE0
    db $99, $88, $88, $87, $77, $77, $78, $88, $88, $88, $88, $88, $77, $77, $77, $88; 12:6CF0
    db $88, $88, $87, $76, $66, $66, $66, $67, $77, $77, $77, $77, $87, $77, $78, $88; 12:6D00
    db $76, $67, $77, $77, $78, $89, $88, $88, $88, $88, $77, $88, $88, $88, $99, $88; 12:6D10
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:6D20
    db $87, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $87, $77, $77; 12:6D30
    db $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:6D40
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:6D50
    db $88, $88, $88, $88, $77, $77, $78, $88, $88, $87, $77, $77, $66, $77, $67, $77; 12:6D60
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77; 12:6D70
    db $77, $77, $88, $88, $88, $88, $87, $77, $77, $77, $78, $88, $88, $88, $88, $77; 12:6D80
    db $78, $78, $88, $88, $88, $88, $88, $77, $77, $77, $78, $88, $88, $88, $88, $87; 12:6D90
    db $78, $88, $88, $78, $88, $88, $88, $88, $88, $77, $88, $88, $88, $88, $88, $88; 12:6DA0

;; PCM08: 1648 bytes = 3296 4-bit samples (rate 2) for SFXInst22
PCM08:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $88, $88, $78, $88; 12:6DB0
    db $88, $87, $77, $77, $78, $77, $88, $88, $88, $88, $87, $88, $77, $88, $88, $88; 12:6DC0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $87, $88, $78, $88, $77, $77; 12:6DD0
    db $78, $88, $87, $87, $77, $88, $88, $88, $88, $88, $77, $88, $88, $78, $88, $78; 12:6DE0
    db $87, $87, $78, $88, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:6DF0
    db $88, $78, $88, $88, $88, $87, $88, $88, $88, $77, $88, $88, $88, $78, $88, $88; 12:6E00
    db $77, $88, $78, $88, $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $77, $88; 12:6E10
    db $87, $88, $88, $88, $88, $88, $78, $88, $87, $78, $88, $88, $88, $88, $87, $88; 12:6E20
    db $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $77, $66, $55, $56, $67, $77; 12:6E30
    db $77, $78, $88, $88, $88, $89, $99, $99, $99, $99, $99, $99, $88, $88, $88, $88; 12:6E40
    db $88, $99, $AB, $CC, $64, $10, $00, $45, $68, $55, $89, $BC, $B8, $44, $33, $78; 12:6E50
    db $98, $88, $8A, $BA, $A9, $76, $67, $78, $98, $89, $9A, $AA, $98, $98, $99, $A9; 12:6E60
    db $99, $A9, $BB, $BB, $CF, $B4, $20, $00, $04, $69, $A6, $8A, $9C, $C9, $40, $00; 12:6E70
    db $17, $9B, $CB, $A9, $CC, $AA, $73, $23, $46, $9B, $99, $98, $9A, $A8, $77, $68; 12:6E80
    db $AA, $BA, $98, $9A, $BB, $CB, $BE, $F5, $00, $00, $04, $AB, $FA, $6B, $88, $C8; 12:6E90
    db $30, $00, $09, $FE, $FF, $A8, $7A, $76, $72, $15, $7A, $DE, $B7, $85, $58, $88; 12:6EA0
    db $88, $98, $CC, $9A, $87, $9B, $CC, $CE, $FC, $02, $00, $00, $AD, $FF, $6A, $95; 12:6EB0
    db $98, $10, $00, $19, $FF, $FF, $85, $46, $64, $74, $28, $9D, $FE, $B5, $42, $17; 12:6EC0
    db $8A, $BA, $B9, $BB, $78, $77, $9B, $CC, $BD, $FF, $40, $00, $00, $AF, $FF, $75; 12:6ED0
    db $72, $58, $20, $01, $5A, $FF, $FB, $20, $04, $87, $B8, $6A, $BE, $DB, $70, $12; 12:6EE0
    db $4B, $DD, $C9, $96, $89, $79, $A9, $BB, $CA, $CF, $F3, $00, $00, $4D, $FF, $F4; 12:6EF0
    db $25, $05, $72, $10, $69, $EF, $FB, $50, $00, $6B, $9F, $98, $CB, $B9, $62, $03; 12:6F00
    db $59, $FE, $B8, $66, $59, $99, $BB, $BB, $BA, $AF, $F5, $00, $00, $7F, $FF, $F2; 12:6F10
    db $05, $05, $63, $10, $AE, $FF, $C4, $00, $02, $DE, $AE, $88, $BA, $94, $41, $19; 12:6F20
    db $BD, $D9, $64, $78, $8C, $A9, $AA, $AA, $BB, $CF, $C0, $00, $08, $FF, $FF, $50; 12:6F30
    db $41, $57, $33, $0B, $FF, $F9, $00, $02, $6E, $F9, $B8, $8A, $97, $22, $36, $DE; 12:6F40
    db $C8, $54, $59, $BB, $B8, $88, $AB, $AD, $EF, $B0, $00, $09, $FF, $FF, $30, $42; 12:6F50
    db $54, $22, $2E, $FF, $F5, $00, $06, $AF, $D7, $87, $89, $95, $14, $6A, $EC, $85; 12:6F60
    db $46, $8C, $BA, $98, $89, $AB, $BE, $FF, $00, $00, $6F, $FF, $F7, $03, $35, $42; 12:6F70
    db $23, $CF, $FF, $60, $00, $8B, $FD, $77, $67, $77, $63, $69, $BC, $A6, $35, $8A; 12:6F80
    db $DC, $98, $88, $9B, $CD, $FF, $10, $00, $3D, $FF, $DA, $02, $56, $42, $44, $AF; 12:6F90
    db $FC, $50, $00, $BB, $DE, $87, $68, $65, $52, $6B, $DC, $96, $23, $8B, $DD, $A8; 12:6FA0
    db $89, $9A, $DD, $FF, $00, $00, $8F, $FC, $D3, $03, $67, $22, $56, $FF, $E8, $00; 12:6FB0
    db $06, $CC, $DA, $76, $79, $66, $44, $8B, $DB, $75, $36, $AB, $CA, $88, $9B, $AC; 12:6FC0
    db $CF, $F1, $00, $06, $DF, $FC, $70, $24, $74, $26, $6D, $FE, $91, $00, $4C, $DD; 12:6FD0
    db $B7, $56, $86, $55, $47, $BC, $A8, $53, $69, $BB, $B9, $78, $AA, $BD, $FF, $50; 12:6FE0
    db $00, $3C, $FF, $B9, $01, $36, $42, $57, $CF, $FA, $10, $02, $BE, $DC, $86, $57; 12:6FF0
    db $65, $55, $7A, $CB, $85, $35, $8B, $BB, $A8, $89, $AA, $CE, $FA, $00, $00, $AF; 12:7000
    db $FC, $B1, $13, $54, $24, $6A, $FF, $C4, $00, $08, $DD, $DA, $76, $76, $55, $56; 12:7010
    db $9C, $B9, $75, $58, $AB, $BA, $88, $99, $AB, $CF, $F5, $00, $03, $BF, $FD, $80; 12:7020
    db $24, $63, $25, $6C, $FF, $A2, $00, $2B, $DE, $C8, $65, $87, $66, $46, $9B, $B8; 12:7030
    db $64, $58, $BB, $B9, $78, $99, $AB, $CE, $F6, $00, $01, $AF, $FE, $90, $13, $65; 12:7040
    db $35, $5B, $FF, $C4, $00, $19, $DE, $C8, $55, $87, $87, $55, $8B, $A9, $74, $58; 12:7050
    db $AB, $B9, $78, $99, $AA, $BC, $FF, $20, $00, $3E, $FF, $E5, $01, $56, $54, $55; 12:7060
    db $CF, $FB, $40, $03, $AD, $EB, $75, $68, $88, $65, $69, $BA, $96, $45, $8A, $BB; 12:7070
    db $87, $89, $9A, $AA, $CE, $F8, $00, $00, $8F, $FF, $B1, $03, $66, $44, $37, $EF; 12:7080
    db $FA, $40, $05, $9C, $DA, $76, $77, $88, $65, $78, $AA, $86, $56, $8A, $CA, $87; 12:7090
    db $77, $9A, $AB, $BD, $FB, $10, $00, $5E, $FF, $E6, $12, $45, $54, $44, $BF, $FE; 12:70A0
    db $81, $00, $49, $ED, $A8, $66, $78, $76, $66, $89, $A8, $66, $68, $BB, $A8, $76; 12:70B0
    db $89, $AA, $BB, $BE, $E4, $00, $00, $AF, $FF, $A2, $02, $35, $55, $48, $EF, $FC; 12:70C0
    db $40, $01, $6C, $FC, $A8, $66, $88, $76, $66, $8A, $A8, $76, $68, $AA, $98, $77; 12:70D0
    db $89, $AA, $AA, $AB, $DA, $20, $00, $5D, $FF, $E7, $11, $24, $76, $65, $8B, $EE; 12:70E0
    db $B5, $00, $15, $BE, $DB, $86, $56, $87, $87, $68, $9A, $98, $65, $78, $AB, $A8; 12:70F0
    db $77, $89, $AA, $99, $AC, $EA, $30, $00, $3D, $FF, $F7, $21, $24, $77, $55, $8B; 12:7100
    db $EF, $C6, $00, $04, $BF, $FD, $85, $45, $78, $98, $77, $89, $98, $76, $78, $9A; 12:7110
    db $A8, $76, $68, $9A, $A9, $99, $AD, $C6, $10, $00, $7E, $FF, $B4, $22, $36, $77; 12:7120
    db $55, $7A, $EF, $C7, $20, $05, $AD, $EC, $86, $56, $78, $86, $67, $89, $A9, $75; 12:7130
    db $56, $8A, $AA, $87, $67, $89, $AA, $A9, $AB, $DB, $51, $00, $07, $FF, $FC, $51; 12:7140
    db $12, $57, $86, $67, $9D, $EC, $83, $00, $49, $DE, $D9, $65, $57, $89, $87, $66; 12:7150
    db $89, $98, $76, $68, $9A, $A8, $76, $68, $9A, $BA, $98, $8A, $CC, $72, $00, $05; 12:7160
    db $CF, $FE, $72, $11, $47, $86, $56, $7A, $EE, $B7, $20, $15, $9D, $EC, $86, $55; 12:7170
    db $78, $87, $77, $78, $99, $87, $66, $89, $AA, $97, $66, $78, $AA, $AA, $99, $9A; 12:7180
    db $CB, $62, $00, $06, $BF, $FD, $73, $22, $47, $87, $66, $79, $CD, $B9, $52, $14; 12:7190
    db $7B, $DC, $A8, $76, $78, $88, $77, $77, $89, $98, $87, $77, $89, $98, $87, $78; 12:71A0
    db $9A, $A9, $98, $78, $9A, $CB, $73, $00, $04, $9D, $ED, $96, $44, $56, $76, $55; 12:71B0
    db $68, $CE, $DB, $73, $12, $58, $BC, $BA, $86, $67, $88, $87, $77, $78, $99, $87; 12:71C0
    db $66, $79, $AA, $A8, $76, $67, $89, $A9, $99, $89, $AB, $B8, $41, $00, $27, $BD; 12:71D0
    db $DB, $86, $54, $56, $65, $56, $79, $BD, $CB, $85, $32, $46, $9B, $BB, $98, $88; 12:71E0
    db $87, $66, $56, $78, $9A, $98, $76, $78, $89, $98, $88, $88, $88, $88, $88, $89; 12:71F0
    db $99, $99, $98, $53, $10, $15, $8C, $ED, $A7, $53, $45, $67, $77, $77, $9B, $BB; 12:7200
    db $A7, $54, $35, $79, $BB, $A9, $88, $78, $87, $66, $67, $79, $99, $98, $77, $78; 12:7210
    db $88, $88, $77, $88, $99, $99, $88, $88, $88, $88, $89, $97, $53, $22, $46, $9B; 12:7220
    db $BA, $86, $54, $56, $77, $77, $78, $9B, $BB, $97, $54, $46, $89, $AA, $98, $87; 12:7230
    db $78, $87, $66, $67, $89, $AA, $98, $66, $67, $88, $88, $88, $88, $88, $88, $78; 12:7240
    db $88, $88, $87, $78, $89, $A8, $63, $21, $25, $8A, $BB, $97, $65, $66, $77, $76; 12:7250
    db $77, $9A, $BB, $A8, $65, $55, $78, $9A, $99, $88, $87, $87, $77, $77, $78, $99; 12:7260
    db $98, $87, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $88; 12:7270
    db $99, $87, $54, $32, $46, $8A, $BA, $97, $66, $66, $77, $77, $77, $8A, $BB, $A8; 12:7280
    db $65, $55, $78, $9A, $A9, $87, $77, $88, $88, $76, $77, $88, $98, $87, $77, $78; 12:7290
    db $89, $98, $87, $77, $78, $99, $99, $88, $88, $77, $77, $77, $88, $99, $98, $75; 12:72A0
    db $43, $34, $68, $9B, $A9, $87, $66, $66, $66, $77, $89, $AA, $A9, $87, $66, $66; 12:72B0
    db $78, $99, $99, $88, $87, $78, $87, $77, $77, $88, $99, $98, $87, $77, $78, $88; 12:72C0
    db $88, $88, $88, $88, $88, $87, $77, $78, $88, $87, $77, $78, $89, $98, $65, $33; 12:72D0
    db $45, $79, $AB, $A9, $76, $66, $67, $77, $77, $88, $9A, $AA, $98, $76, $55, $67; 12:72E0
    db $89, $A9, $88, $87, $88, $87, $77, $77, $88, $89, $88, $87, $77, $77, $88, $88; 12:72F0
    db $88, $88, $88, $88, $87, $77, $77, $78, $88, $88, $88, $89, $98, $65, $32, $34; 12:7300
    db $68, $AB, $BA, $97, $66, $67, $87, $77, $77, $89, $AB, $BA, $87, $55, $56, $78; 12:7310
    db $9A, $A9, $88, $77, $77, $77, $77, $77, $88, $88, $88, $77, $77, $88, $88, $88; 12:7320
    db $88, $88, $88, $88, $87, $77, $77, $78, $88, $87, $87, $88, $99, $87, $64, $33; 12:7330
    db $45, $89, $AB, $A9, $87, $77, $78, $77, $76, $67, $89, $AB, $A9, $87, $66, $66; 12:7340
    db $78, $88, $88, $88, $88, $88, $87, $77, $77, $88, $88, $88, $88, $88, $88, $88; 12:7350
    db $88, $77, $77, $88, $88, $77, $77, $77, $77, $77, $77, $78, $88, $99, $88, $76; 12:7360
    db $54, $45, $67, $89, $99, $98, $88, $87, $77, $77, $77, $78, $89, $99, $99, $88; 12:7370
    db $77, $77, $88, $88, $88, $88, $88, $88, $88, $87, $77, $78, $88, $88, $88, $88; 12:7380
    db $88, $88, $77, $77, $77, $78, $88, $87, $77, $77, $77, $77, $77, $87, $78, $88; 12:7390
    db $88, $77, $66, $66, $77, $88, $88, $88, $77, $88, $88, $88, $88, $87, $88, $88; 12:73A0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:73B0
    db $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $77, $77, $77, $78, $77, $77; 12:73C0
    db $77, $77, $78, $88, $78, $88, $88, $87, $77, $78, $78, $88, $88, $88, $88, $88; 12:73D0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:73E0
    db $87, $78, $77, $88, $88, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77; 12:73F0
    db $77, $78, $88, $88, $88, $88, $88, $87, $88, $88, $88, $88, $88, $77, $88, $88; 12:7400
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $78, $78, $77, $77; 12:7410

;; PCM09: 1760 bytes = 3520 4-bit samples (rate 2) for SFXInst23
PCM09:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:7420
    db $88, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:7430
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:7440
    db $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $78, $78, $77, $78, $77, $87; 12:7450
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:7460
    db $88, $88, $88, $88, $87, $87, $77, $87, $77, $88, $78, $78, $88, $78, $78, $88; 12:7470
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87; 12:7480
    db $78, $87, $88, $88, $78, $78, $78, $78, $78, $78, $78, $88, $87, $88, $88, $88; 12:7490
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $78, $88, $88; 12:74A0
    db $88, $88, $78, $78, $88, $77, $77, $77, $78, $77, $77, $77, $77, $77, $87, $87; 12:74B0
    db $87, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87; 12:74C0
    db $88, $88, $88, $78, $78, $78, $88, $87, $87, $87, $87, $87, $87, $87, $88, $88; 12:74D0
    db $78, $78, $78, $78, $87, $87, $87, $87, $87, $88, $78, $78, $78, $78, $78, $87; 12:74E0
    db $87, $87, $88, $78, $78, $88, $88, $78, $78, $78, $88, $88, $88, $88, $87, $87; 12:74F0
    db $87, $87, $87, $87, $87, $87, $87, $78, $78, $78, $78, $78, $77, $78, $78, $78; 12:7500
    db $78, $88, $87, $87, $87, $88, $78, $78, $88, $78, $88, $88, $88, $88, $87, $87; 12:7510
    db $88, $78, $78, $78, $78, $78, $88, $87, $78, $88, $87, $78, $88, $78, $78, $78; 12:7520
    db $87, $87, $87, $78, $88, $77, $88, $87, $87, $88, $87, $77, $88, $87, $78, $88; 12:7530
    db $78, $78, $87, $88, $88, $78, $78, $87, $87, $88, $87, $78, $88, $77, $88, $88; 12:7540
    db $77, $78, $78, $78, $78, $78, $87, $87, $87, $88, $88, $87, $88, $88, $78, $78; 12:7550
    db $88, $77, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $77, $77, $77; 12:7560
    db $88, $87, $88, $88, $88, $88, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:7570
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:7580
    db $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $78, $77, $78, $88, $88; 12:7590
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $87, $88; 12:75A0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:75B0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $87, $77, $88, $88, $78; 12:75C0
    db $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $88, $88; 12:75D0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:75E0
    db $88, $88, $87, $77, $78, $77, $77, $78, $77, $77, $77, $78, $76, $78, $98, $77; 12:75F0
    db $78, $99, $76, $78, $88, $77, $88, $98, $87, $88, $88, $76, $78, $88, $87, $77; 12:7600
    db $88, $88, $88, $87, $78, $76, $67, $87, $87, $88, $88, $88, $88, $88, $77, $77; 12:7610
    db $77, $77, $77, $78, $88, $88, $88, $88, $87, $88, $88, $87, $78, $88, $88, $77; 12:7620
    db $88, $88, $87, $77, $88, $77, $77, $77, $77, $77, $88, $78, $78, $88, $87, $78; 12:7630
    db $88, $77, $78, $78, $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $88; 12:7640
    db $88, $99, $AA, $AA, $A7, $55, $66, $42, $23, $44, $45, $66, $89, $AA, $9A, $BB; 12:7650
    db $A8, $87, $77, $66, $66, $78, $89, $99, $AA, $9A, $A9, $88, $99, $99, $9A, $AA; 12:7660
    db $BB, $CD, $EE, $A3, $02, $42, $00, $00, $22, $47, $89, $CE, $FC, $99, $A9, $73; 12:7670
    db $24, $44, $57, $88, $9C, $DC, $A9, $AA, $75, $55, $66, $79, $99, $AC, $DC, $BA; 12:7680
    db $AA, $98, $89, $9A, $BC, $DE, $FC, $00, $03, $50, $00, $05, $88, $BB, $AB, $EF; 12:7690
    db $C4, $01, $56, $20, $27, $AC, $EE, $EC, $BD, $D8, $31, $35, $54, $57, $AB, $BD; 12:76A0
    db $CA, $88, $A9, $75, $79, $AA, $BC, $DC, $CD, $FF, $FB, $00, $02, $60, $00, $3B; 12:76B0
    db $FE, $ED, $89, $CC, $80, $00, $68, $63, $7E, $FF, $FF, $C7, $47, $83, $00, $19; 12:76C0
    db $BA, $AB, $CC, $BB, $94, $24, $79, $75, $8C, $EE, $CC, $CB, $BB, $A8, $78, $FF; 12:76D0
    db $10, $00, $C7, $00, $3A, $DE, $DD, $51, $7B, $A0, $00, $AE, $B8, $9E, $ED, $EC; 12:76E0
    db $61, $05, $96, $23, $8D, $DA, $A9, $88, $87, $52, $38, $BA, $88, $BD, $CA, $AA; 12:76F0
    db $98, $9A, $97, $79, $BB, $CF, $F0, $00, $5B, $00, $09, $FF, $ED, $92, $4C, $90; 12:7700
    db $00, $9F, $B8, $AD, $FE, $DB, $30, $17, $A6, $25, $CF, $EA, $76, $56, $75, $23; 12:7710
    db $8D, $D9, $8A, $BB, $A9, $98, $8B, $B8, $67, $9A, $88, $9B, $DF, $E0, $00, $69; 12:7720
    db $10, $2C, $EF, $F9, $41, $7C, $30, $04, $EF, $BB, $CB, $EE, $82, $01, $9A, $76; 12:7730
    db $8E, $FD, $B7, $33, $45, $42, $5B, $DC, $B9, $9A, $99, $76, $7A, $BA, $89, $A9; 12:7740
    db $88, $89, $98, $87, $8C, $F9, $00, $48, $72, $0B, $CC, $FB, $20, $28, $70, $07; 12:7750
    db $BF, $FC, $CA, $BE, $80, $02, $8A, $78, $BB, $DD, $85, $33, $55, $58, $8B, $CB; 12:7760
    db $98, $67, $86, $77, $9B, $BA, $A9, $98, $77, $77, $86, $68, $9A, $BE, $F5, $00; 12:7770
    db $86, $32, $2A, $DD, $F8, $04, $88, $40, $3B, $CF, $E8, $89, $98, $20, $47, $AC; 12:7780
    db $AA, $BB, $C9, $32, $45, $66, $79, $AB, $A8, $67, $88, $87, $8A, $AA, $98, $99; 12:7790
    db $98, $66, $78, $87, $78, $88, $88, $AD, $E4, $00, $A7, $55, $4A, $DE, $E4, $05; 12:77A0
    db $86, $30, $5C, $DF, $B5, $7A, $A7, $11, $7A, $CB, $79, $BB, $A5, $24, $79, $96; 12:77B0
    db $7A, $BB, $74, $57, $88, $78, $9B, $B9, $88, $AB, $97, $57, $88, $77, $8A, $97; 12:77C0
    db $67, $8A, $BC, $A0, $01, $95, $35, $7D, $ED, $91, $28, $62, $24, $AD, $DD, $86; 12:77D0
    db $AA, $72, $26, $AB, $B9, $9B, $B8, $53, $47, $89, $98, $9A, $96, $55, $67, $88; 12:77E0
    db $89, $BA, $98, $89, $A9, $76, $77, $88, $88, $99, $87, $65, $67, $79, $CD, $60; 12:77F0
    db $04, $74, $46, $8C, $EB, $52, $57, $53, $57, $BE, $DA, $78, $A8, $54, $68, $BC; 12:7800
    db $B9, $99, $86, $34, $79, $AA, $99, $87, $65, $46, $89, $9A, $AA, $98, $77, $88; 12:7810
    db $88, $88, $87, $88, $87, $87, $76, $66, $67, $89, $9B, $B7, $00, $12, $67, $69; 12:7820
    db $BD, $C7, $54, $45, $54, $7A, $DE, $B9, $87, $65, $45, $7A, $CB, $A9, $88, $75; 12:7830
    db $56, $8A, $98, $99, $76, $55, $78, $99, $89, $98, $77, $78, $99, $88, $88, $76; 12:7840
    db $67, $77, $87, $77, $87, $66, $78, $8A, $BB, $83, $14, $33, $78, $8B, $CB, $86; 12:7850
    db $65, $45, $67, $9B, $CB, $88, $86, $55, $68, $AB, $B9, $99, $87, $65, $77, $89; 12:7860
    db $A9, $86, $66, $77, $88, $89, $88, $77, $88, $88, $99, $98, $76, $78, $87, $78; 12:7870
    db $87, $77, $77, $77, $78, $89, $9A, $B8, $31, $23, $35, $78, $AC, $B8, $66, $54; 12:7880
    db $45, $78, $BC, $BA, $98, $75, $56, $78, $9A, $AA, $97, $66, $77, $78, $88, $88; 12:7890
    db $87, $77, $77, $88, $89, $98, $88, $88, $89, $99, $88, $77, $77, $88, $88, $77; 12:78A0
    db $77, $77, $77, $77, $78, $88, $BC, $70, $14, $45, $56, $8A, $C9, $67, $87, $54; 12:78B0
    db $57, $9A, $98, $9A, $A8, $76, $77, $77, $89, $A9, $88, $88, $65, $78, $88, $88; 12:78C0
    db $89, $87, $78, $88, $88, $99, $98, $88, $98, $87, $77, $77, $77, $88, $87, $66; 12:78D0
    db $66, $66, $77, $78, $88, $88, $88, $86, $66, $55, $56, $77, $88, $89, $88, $76; 12:78E0
    db $67, $88, $88, $89, $AA, $87, $77, $88, $88, $9B, $A8, $88, $88, $77, $78, $88; 12:78F0
    db $88, $98, $88, $88, $87, $78, $88, $87, $88, $77, $77, $87, $77, $77, $77, $77; 12:7900
    db $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $88, $78, $87, $77, $77, $78; 12:7910
    db $88, $88, $88, $88, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $78, $88; 12:7920
    db $88, $87, $88, $77, $77, $77, $77, $88, $88, $88, $88, $77, $77, $78, $88, $88; 12:7930
    db $88, $77, $77, $78, $88, $88, $88, $88, $77, $77, $77, $77, $78, $77, $88, $88; 12:7940
    db $88, $88, $88, $88, $88, $88, $88, $88, $77, $78, $88, $88, $88, $88, $77, $78; 12:7950
    db $88, $88, $88, $87, $77, $77, $77, $77, $88, $88, $77, $77, $77, $77, $78, $88; 12:7960
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $88, $88, $88, $88; 12:7970
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $88, $88, $88, $88, $88, $88; 12:7980
    db $88, $88, $88, $88, $88, $87, $77, $77, $88, $88, $87, $77, $77, $78, $88, $87; 12:7990
    db $78, $77, $77, $78, $88, $88, $88, $87, $77, $77, $78, $88, $88, $88, $87, $78; 12:79A0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:79B0
    db $88, $88, $88, $77, $78, $77, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88; 12:79C0
    db $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:79D0
    db $88, $88, $88, $88, $88, $88, $88, $88, $78, $88, $88, $88, $88, $87, $77, $88; 12:79E0
    db $88, $88, $87, $77, $77, $87, $88, $87, $88, $78, $77, $88, $88, $78, $88, $87; 12:79F0
    db $78, $87, $88, $78, $78, $87, $87, $88, $78, $88, $87, $78, $78, $87, $87, $88; 12:7A00
    db $78, $87, $87, $78, $78, $87, $88, $88, $88, $88, $88, $88, $88, $78, $87, $78; 12:7A10
    db $78, $77, $78, $78, $88, $87, $87, $88, $88, $78, $78, $88, $87, $88, $78, $87; 12:7A20
    db $87, $88, $78, $88, $77, $87, $88, $88, $78, $87, $87, $87, $78, $77, $88, $78; 12:7A30
    db $77, $87, $88, $88, $87, $87, $88, $78, $78, $87, $88, $78, $87, $87, $78, $78; 12:7A40
    db $77, $87, $87, $78, $77, $87, $78, $87, $78, $77, $87, $88, $87, $88, $78, $87; 12:7A50
    db $88, $68, $87, $87, $78, $78, $78, $87, $88, $78, $87, $88, $78, $88, $88, $87; 12:7A60
    db $88, $88, $78, $77, $87, $77, $87, $88, $77, $88, $78, $87, $88, $77, $88, $78; 12:7A70
    db $86, $88, $77, $78, $86, $88, $78, $88, $78, $87, $88, $78, $87, $88, $88, $88; 12:7A80
    db $78, $87, $87, $87, $87, $88, $88, $87, $78, $87, $88, $78, $88, $78, $87, $78; 12:7A90
    db $87, $88, $78, $87, $78, $77, $87, $78, $77, $87, $77, $87, $78, $77, $87, $88; 12:7AA0
    db $88, $88, $88, $88, $88, $78, $87, $88, $78, $88, $88, $88, $78, $78, $87, $78; 12:7AB0
    db $78, $87, $88, $78, $88, $88, $87, $88, $78, $78, $87, $87, $87, $78, $78, $88; 12:7AC0
    db $77, $88, $77, $87, $78, $77, $88, $77, $88, $77, $87, $88, $78, $88, $78, $88; 12:7AD0
    db $78, $78, $87, $88, $88, $88, $78, $77, $87, $87, $88, $78, $87, $87, $88, $88; 12:7AE0
    db $88, $88, $88, $88, $88, $87, $88, $78, $87, $88, $77, $87, $78, $87, $88, $78; 12:7AF0

;; PCM10: 2304 bytes = 4608 4-bit samples (rate 2) for SFXInst24
PCM10:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:7B00
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:7B10
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 12:7B20
    db $88, $89, $99, $99, $84, $67, $44, $33, $55, $54, $6A, $88, $9A, $AA, $98, $88; 12:7B30
    db $75, $66, $66, $77, $79, $99, $9A, $A9, $98, $88, $76, $56, $66, $67, $78, $89; 12:7B40
    db $9A, $A9, $99, $88, $88, $88, $88, $89, $9A, $AA, $AA, $AA, $9A, $BB, $10, $A2; 12:7B50
    db $10, $02, $34, $11, $BC, $7A, $AC, $CB, $86, $8A, $33, $55, $66, $66, $9C, $B9; 12:7B60
    db $CC, $B9, $76, $77, $53, $57, $77, $89, $AB, $BA, $AB, $A8, $87, $88, $77, $8A; 12:7B70
    db $99, $AA, $BB, $A9, $99, $99, $A8, $20, $63, $00, $01, $33, $22, $9E, $9A, $BC; 12:7B80
    db $CB, $86, $68, $53, $55, $78, $88, $AD, $DA, $AA, $A9, $75, $56, $65, $57, $8A; 12:7B90
    db $AA, $BC, $CB, $99, $99, $87, $78, $98, $89, $BB, $A9, $AA, $AA, $AE, $90, $28; 12:7BA0
    db $00, $00, $13, $60, $3F, $BB, $DA, $CD, $C6, $27, $72, $53, $48, $BB, $8C, $FC; 12:7BB0
    db $DC, $98, $76, $32, $43, $46, $68, $AC, $CB, $CC, $BB, $98, $88, $88, $88, $9B; 12:7BC0
    db $AA, $BB, $AB, $BA, $BF, $E0, $05, $02, $00, $01, $81, $3B, $8F, $FB, $9A, $C9; 12:7BD0
    db $55, $01, $85, $45, $8C, $EF, $DB, $FD, $CB, $52, $25, $32, $33, $7C, $BB, $BC; 12:7BE0
    db $ED, $C8, $79, $98, $77, $8A, $CB, $AB, $BC, $BA, $AC, $FF, $00, $00, $30, $00; 12:7BF0
    db $09, $59, $96, $FF, $FD, $67, $46, $70, $00, $49, $9C, $BC, $FF, $FE, $B9, $77; 12:7C00
    db $31, $10, $46, $89, $9C, $DE, $EB, $BA, $A9, $88, $78, $99, $AB, $BC, $CC, $CE; 12:7C10
    db $FF, $60, $00, $01, $00, $00, $46, $DF, $7C, $FD, $FD, $50, $04, $10, $40, $19; 12:7C20
    db $CE, $FF, $ED, $FF, $BA, $30, $12, $34, $55, $7C, $EE, $FD, $BB, $BB, $AA, $86; 12:7C30
    db $9A, $AC, $CB, $CD, $FF, $FB, $02, $00, $20, $00, $00, $0C, $EB, $FC, $9F, $FD; 12:7C40
    db $96, $20, $24, $26, $52, $6A, $EF, $FF, $BC, $B8, $96, $22, $23, $57, $99, $BA; 12:7C50
    db $AE, $ED, $DB, $9A, $BA, $AB, $A9, $BB, $DF, $F8, $43, $00, $10, $00, $00, $05; 12:7C60
    db $6C, $F8, $BB, $9D, $EC, $86, $40, $47, $47, $74, $68, $AC, $ED, $9A, $86, $98; 12:7C70
    db $77, $54, $47, $9A, $CA, $9B, $AD, $ED, $CB, $BB, $BD, $CD, $FE, $55, $20, $00; 12:7C80
    db $00, $00, $01, $45, $DC, $9D, $98, $BC, $B8, $84, $26, $56, $A6, $67, $79, $BC; 12:7C90
    db $A9, $86, $89, $8A, $86, $66, $89, $BA, $99, $89, $BA, $CC, $BB, $CE, $FF, $FA; 12:7CA0
    db $64, $00, $00, $00, $00, $04, $5E, $E9, $DA, $9D, $DC, $76, $20, $54, $5B, $66; 12:7CB0
    db $88, $BD, $FB, $98, $47, $87, $96, $55, $8A, $BF, $DB, $C9, $BC, $BB, $99, $9B; 12:7CC0
    db $FF, $F7, $50, $02, $01, $00, $00, $25, $9E, $A8, $BA, $DD, $E8, $44, $14, $76; 12:7CD0
    db $65, $46, $9E, $DE, $B7, $88, $99, $75, $34, $58, $BA, $BB, $BE, $EF, $DC, $BA; 12:7CE0
    db $CE, $FF, $F2, $30, $03, $00, $00, $00, $AB, $AC, $99, $EF, $F9, $82, $14, $54; 12:7CF0
    db $42, $27, $AD, $ED, $AA, $BB, $B9, $63, $35, $56, $65, $7A, $CE, $ED, $DD, $EE; 12:7D00
    db $EE, $EF, $FC, $04, $00, $00, $00, $00, $5B, $6B, $BD, $FF, $F7, $87, $17, $10; 12:7D10
    db $01, $33, $B8, $7E, $DF, $EE, $98, $B5, $65, $23, $58, $7B, $CB, $FF, $FF, $FF; 12:7D20
    db $FF, $FF, $D0, $40, $00, $00, $02, $03, $84, $AE, $FF, $BF, $79, $B3, $20, $30; 12:7D30
    db $25, $05, $9D, $DB, $D9, $FE, $97, $46, $57, $52, $89, $CD, $DD, $FF, $FF, $FF; 12:7D40
    db $FF, $D0, $21, $00, $00, $06, $00, $38, $EF, $FC, $AF, $F9, $71, $00, $70, $02; 12:7D50
    db $36, $89, $6E, $FB, $CB, $AA, $96, $17, $74, $78, $BD, $FD, $DF, $FF, $FF, $FB; 12:7D60
    db $09, $00, $00, $00, $20, $03, $BB, $CF, $FF, $FC, $BB, $B4, $04, $02, $10, $06; 12:7D70
    db $A4, $9C, $BD, $CB, $8C, $94, $88, $88, $AA, $CF, $DE, $FF, $FF, $B0, $F8, $00; 12:7D80
    db $00, $00, $00, $25, $05, $FF, $CF, $FF, $FE, $76, $E1, $00, $50, $03, $26, $85; 12:7D90
    db $8C, $E8, $AD, $BA, $9B, $AB, $BB, $FF, $FF, $FF, $1F, $F0, $00, $90, $00, $00; 12:7DA0
    db $00, $0C, $81, $EF, $DD, $FF, $9F, $B8, $97, $30, $72, $03, $51, $17, $85, $A9; 12:7DB0
    db $BC, $DB, $CF, $CB, $EF, $DE, $FF, $95, $F9, $02, $83, $01, $00, $00, $20, $43; 12:7DC0
    db $7E, $AB, $EF, $E8, $FE, $B6, $DA, $34, $54, $00, $32, $22, $68, $68, $BD, $BD; 12:7DD0
    db $FF, $EE, $FE, $DF, $FA, $4F, $A0, $27, $50, $22, $00, $06, $00, $68, $55, $DB; 12:7DE0
    db $AA, $CF, $AC, $BD, $A8, $A8, $74, $65, $13, $35, $25, $87, $9A, $DC, $CD, $DD; 12:7DF0
    db $CC, $DC, $B9, $9A, $86, $57, $52, $45, $40, $36, $32, $47, $43, $68, $65, $9B; 12:7E00
    db $88, $BC, $99, $CA, $88, $A8, $67, $76, $57, $77, $78, $A9, $AB, $BB, $AB, $BA; 12:7E10
    db $9B, $A8, $88, $86, $66, $64, $35, $53, $34, $53, $35, $55, $56, $77, $79, $9A; 12:7E20
    db $AA, $BA, $BB, $A9, $98, $87, $77, $77, $77, $78, $89, $9A, $AA, $BB, $AB, $A9; 12:7E30
    db $89, $96, $66, $64, $34, $43, $34, $44, $45, $55, $56, $77, $89, $99, $AB, $BA; 12:7E40
    db $BB, $A9, $99, $77, $87, $66, $76, $67, $87, $89, $99, $BB, $BB, $AC, $CB, $98; 12:7E50
    db $97, $55, $44, $33, $32, $33, $44, $56, $67, $67, $88, $99, $AA, $AB, $AA, $9A; 12:7E60
    db $A8, $88, $77, $67, $65, $67, $77, $88, $88, $9A, $AB, $CC, $CC, $B9, $AA, $96; 12:7E70
    db $55, $43, $22, $11, $22, $33, $46, $78, $9A, $AA, $BB, $AA, $AB, $98, $98, $76; 12:7E80
    db $65, $55, $66, $67, $77, $89, $9A, $AB, $BB, $BB, $BB, $BB, $BC, $D9, $67, $87; 12:7E90
    db $43, $20, $01, $20, $02, $55, $78, $99, $BE, $CB, $AB, $A8, $98, $55, $66, $53; 12:7EA0
    db $55, $67, $88, $89, $BA, $BB, $AA, $BC, $BB, $BB, $BC, $EF, $FF, $A4, $53, $30; 12:7EB0
    db $00, $00, $00, $12, $55, $8F, $FE, $ED, $CA, $CB, $64, $32, $22, $53, $35, $69; 12:7EC0
    db $BC, $CA, $BB, $AB, $AA, $88, $AA, $CE, $DE, $FF, $FF, $FA, $41, $00, $00, $00; 12:7ED0
    db $00, $06, $AC, $CD, $FD, $FF, $EB, $73, $01, $42, $02, $02, $8B, $CD, $EC, $AC; 12:7EE0
    db $A9, $A8, $64, $78, $8D, $ED, $EF, $FF, $FF, $FF, $B4, $00, $00, $00, $00, $00; 12:7EF0
    db $5A, $FF, $FF, $ED, $A9, $A8, $32, $00, $01, $47, $BB, $AC, $CC, $EE, $CB, $75; 12:7F00
    db $34, $67, $BC, $CD, $DE, $FF, $FF, $FF, $FB, $61, $00, $00, $00, $00, $03, $5C; 12:7F10
    db $FF, $FF, $EB, $75, $43, $31, $11, $01, $46, $AD, $EF, $EC, $AA, $98, $88, $66; 12:7F20
    db $67, $9B, $EF, $FF, $FF, $FF, $FF, $DB, $30, $00, $00, $00, $01, $22, $9D, $FF; 12:7F30
    db $FF, $FA, $53, $22, $24, $32, $32, $35, $8B, $DE, $ED, $C9, $77, $67, $99, $9A; 12:7F40
    db $AB, $CD, $EF, $FF, $FF, $FC, $B4, $00, $00, $00, $00, $02, $38, $AD, $FF, $FF; 12:7F50
    db $DA, $75, $32, $43, $34, $33, $45, $7A, $BD, $DC, $B9, $97, $88, $89, $AB, $BB; 12:7F60
    db $CC, $DE, $EF, $FF, $FC, $B3, $00, $00, $00, $00, $12, $36, $8A, $DF, $FF, $EB; 12:7F70
    db $98, $65, $55, $56, $54, $44, $46, $89, $AB, $BA, $99, $89, $AA, $CC, $CC, $BB; 12:7F80
    db $BB, $DE, $FF, $FE, $B9, $20, $00, $00, $00, $00, $22, $55, $79, $9C, $DB, $DB; 12:7F90
    db $99, $88, $89, $98, $87, $56, $55, $77, $88, $88, $99, $9A, $BB, $BB, $AB, $AB; 12:7FA0
    db $CC, $DE, $EF, $FF, $AA, $72, $32, $00, $00, $00, $00, $01, $14, $46, $A8, $BC; 12:7FB0
    db $BB, $BB, $AB, $CB, $BB, $9A, $98, $97, $77, $66, $56, $56, $87, $8A, $9B, $CD; 12:7FC0
    db $EF, $FF, $FF, $FF, $DB, $D7, $25, $00, $00, $00, $00, $00, $00, $33, $79, $9C; 12:7FD0
    db $DD, $DD, $EC, $EF, $DE, $CB, $B8, $87, $55, $54, $33, $53, $57, $79, $AB, $CD; 12:7FE0
    db $EF, $FF, $FF, $FF, $FD, $BD, $62, $40, $00, $00, $00, $00, $00, $13, $37, $9A; 12:7FF0

; ============================================================================
SECTION "GHX PCM samples bank $13", ROMX[$4000], BANK[$13]
; ============================================================================
;; (continuation of the previous sample from bank $12)
    db $CD, $ED, $EF, $EF, $FE, $ED, $BA, $88, $76, $54, $43, $34, $46, $78, $9A, $BC; 13:4000
    db $DE, $EF, $EE, $EE, $FF, $FB, $BC, $52, $40, $00, $00, $00, $00, $00, $13, $38; 13:4010
    db $9A, $CD, $ED, $FF, $EF, $FD, $DB, $A9, $88, $76, $55, $54, $55, $57, $88, $99; 13:4020
    db $AB, $CD, $EE, $EE, $EE, $FF, $FD, $AC, $62, $41, $00, $00, $00, $00, $00, $14; 13:4030
    db $47, $AA, $DD, $DD, $DE, $CE, $ED, $DC, $AA, $98, $88, $65, $54, $45, $55, $77; 13:4040
    db $78, $9A, $BD, $DE, $EE, $EF, $EF, $FF, $E9, $C8, $13, $20, $00, $00, $00, $00; 13:4050
    db $01, $44, $69, $9B, $CC, $CC, $ED, $EF, $EE, $EB, $BB, $98, $87, $55, $43, $44; 13:4060
    db $45, $66, $88, $9B, $CC, $DE, $ED, $EE, $EF, $FF, $FD, $CA, $10, $10, $00, $00; 13:4070
    db $00, $00, $00, $25, $6A, $BA, $BC, $BA, $CD, $CE, $ED, $CB, $98, $87, $66, $75; 13:4080
    db $65, $56, $67, $89, $AA, $AB, $BB, $BC, $CC, $DE, $EF, $FF, $FF, $88, $50, $00; 13:4090
    db $00, $00, $00, $10, $03, $35, $78, $BA, $9B, $BA, $AC, $CB, $DC, $99, $86, $77; 13:40A0
    db $76, $67, $67, $77, $88, $89, $9A, $AA, $AB, $BB, $BC, $CC, $CC, $DD, $EF, $FF; 13:40B0
    db $B7, $70, $00, $00, $00, $00, $00, $03, $67, $BB, $BA, $89, $9A, $BD, $ED, $CB; 13:40C0
    db $75, $76, $78, $87, $56, $55, $79, $AB, $A9, $87, $88, $9A, $BB, $AA, $99, $BC; 13:40D0
    db $DE, $FF, $EE, $FF, $D7, $81, $00, $00, $00, $00, $02, $02, $88, $BC, $CB, $99; 13:40E0
    db $9B, $CD, $ED, $A9, $74, $67, $78, $86, $45, $55, $8B, $BB, $B9, $87, $88, $9B; 13:40F0
    db $AA, $98, $89, $BD, $EE, $DD, $CC, $EF, $FF, $86, $10, $00, $00, $00, $00, $11; 13:4100
    db $2A, $DD, $ED, $A7, $89, $AD, $FD, $B8, $65, $58, $99, $97, $53, $35, $8A, $DD; 13:4110
    db $BA, $87, $78, $99, $98, $76, $78, $BC, $ED, $CC, $BB, $CE, $FF, $FF, $73, $10; 13:4120
    db $00, $00, $00, $00, $14, $4C, $FD, $DC, $A6, $9B, $AB, $E9, $77, $67, $8B, $A8; 13:4130
    db $86, $35, $67, $AB, $CB, $AA, $99, $BA, $98, $66, $56, $89, $AB, $BB, $BB, $CD; 13:4140
    db $EE, $DD, $DE, $FB, $54, $00, $00, $00, $00, $00, $54, $9F, $EE, $ED, $97, $A9; 13:4150
    db $7A, $A5, $66, $66, $9B, $99, $A7, $58, $78, $8A, $98, $9A, $89, $B9, $88, $76; 13:4160
    db $68, $88, $AA, $AB, $BC, $CD, $ED, $DD, $DD, $FF, $83, $10, $00, $00, $00, $00; 13:4170
    db $25, $6D, $FF, $FF, $C7, $69, $86, $97, $33, $34, $5A, $CC, $CD, $A8, $AA, $AA; 13:4180
    db $B8, $55, $54, $68, $89, $98, $78, $AB, $BC, $B9, $98, $89, $BC, $CC, $CC, $CE; 13:4190
    db $FD, $75, $00, $00, $00, $00, $00, $35, $9F, $FF, $FE, $A7, $78, $77, $84, $22; 13:41A0
    db $34, $7B, $DD, $DD, $AA, $BB, $BA, $96, $22, $11, $46, $89, $AA, $AB, $DD, $DE; 13:41B0
    db $CA, $87, $77, $8A, $A9, $AA, $BD, $FF, $B8, $40, $00, $00, $01, $00, $03, $4B; 13:41C0
    db $FF, $FF, $C9, $88, $98, $A8, $53, $33, $48, $BC, $BD, $B9, $AA, $BB, $B9, $53; 13:41D0
    db $31, $26, $78, $99, $99, $BD, $DE, $EB, $98, $76, $78, $98, $99, $8A, $CE, $FC; 13:41E0
    db $95, $00, $00, $00, $00, $00, $23, $9D, $FF, $FD, $A8, $89, $8A, $96, $53, $23; 13:41F0
    db $69, $BB, $DB, $9A, $AA, $BB, $98, $54, $22, $56, $89, $AA, $AA, $BB, $CD, $BA; 13:4200
    db $97, $67, $89, $9A, $AA, $AC, $DF, $D9, $70, $00, $00, $00, $00, $02, $37, $CE; 13:4210
    db $FF, $EB, $98, $98, $89, $75, $43, $34, $7A, $BC, $DA, $AA, $9A, $BA, $97, $54; 13:4220
    db $24, $56, $8A, $AA, $AA, $AB, $CC, $BA, $87, $77, $89, $AA, $AA, $AB, $CE, $D9; 13:4230
    db $72, $00, $00, $00, $10, $02, $35, $AD, $EF, $EC, $A8, $98, $89, $86, $54, $34; 13:4240
    db $69, $AC, $DB, $AA, $AA, $BB, $A8, $75, $33, $46, $8A, $AA, $AA, $AA, $CB, $BB; 13:4250
    db $97, $66, $77, $9A, $AA, $AA, $AC, $EE, $B8, $50, $00, $00, $00, $00, $02, $37; 13:4260
    db $BD, $FF, $EB, $A9, $88, $98, $65, $43, $34, $79, $BD, $CB, $BA, $9B, $BB, $A9; 13:4270
    db $74, $44, $56, $9A, $AA, $99, $8A, $BA, $AA, $86, $66, $78, $AA, $AB, $A9, $AB; 13:4280
    db $DE, $C9, $60, $00, $00, $00, $00, $01, $26, $AD, $FF, $EC, $A9, $98, $99, $76; 13:4290
    db $53, $34, $68, $9B, $BB, $BA, $AA, $BB, $A8, $75, $45, $57, $9A, $A9, $99, $99; 13:42A0
    db $BA, $AA, $87, $77, $78, $9A, $AA, $AA, $AB, $CD, $DA, $75, $00, $00, $00, $00; 13:42B0
    db $00, $23, $7A, $CD, $DD, $BA, $AA, $99, $98, $76, $55, $57, $89, $AA, $AA, $A9; 13:42C0
    db $9A, $99, $88, $76, $77, $89, $99, $98, $88, $89, $88, $87, $77, $88, $89, $99; 13:42D0
    db $9A, $9A, $AA, $AA, $B9, $75, $30, $00, $00, $00, $11, $24, $58, $AB, $CC, $CB; 13:42E0
    db $BB, $AA, $A9, $88, $77, $77, $88, $99, $99, $99, $88, $88, $88, $87, $88, $88; 13:42F0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $89, $99, $98, $88, $89, $9A; 13:4300
    db $86, $52, $10, $01, $12, $22, $24, $56, $9B, $BB, $BB, $AA, $AA, $AA, $98, $88; 13:4310
    db $88, $89, $99, $98, $87, $77, $77, $77, $78, $78, $88, $99, $98, $88, $88, $88; 13:4320
    db $88, $87, $87, $88, $88, $88, $88, $88, $88, $77, $77, $78, $77, $65, $43, $33; 13:4330
    db $44, $54, $45, $56, $88, $99, $99, $99, $AA, $AA, $A9, $99, $99, $98, $88, $87; 13:4340
    db $77, $77, $88, $88, $89, $99, $88, $88, $88, $88, $77, $78, $88, $88, $88, $88; 13:4350
    db $88, $77, $77, $77, $77, $77, $77, $77, $88, $88, $87, $77, $66, $66, $76, $66; 13:4360
    db $67, $77, $88, $88, $88, $88, $87, $77, $77, $88, $88, $88, $88, $99, $99, $98; 13:4370
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $66, $67, $77; 13:4380
    db $77, $77, $88, $88, $88, $88, $77, $77, $77, $87, $88, $88, $77, $77, $88, $77; 13:4390
    db $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $88; 13:43A0
    db $88, $88, $88, $88, $87, $77, $77, $77, $78, $78, $88, $88, $88, $88, $88, $88; 13:43B0
    db $88, $88, $88, $88, $78, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77; 13:43C0
    db $88, $88, $88, $88, $88, $88, $88, $88, $87, $87, $77, $88, $88, $87, $78, $88; 13:43D0
    db $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87; 13:43E0
    db $77, $77, $77, $77, $77, $77, $87, $88, $78, $88, $88, $88, $88, $88, $88, $88; 13:43F0

;; PCM11: 1728 bytes = 3456 4-bit samples (rate 2) for SFXInst25
PCM11:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:4400
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:4410
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $78, $88, $88; 13:4420
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $88; 13:4430
    db $88, $99, $87, $65, $55, $55, $55, $55, $56, $78, $99, $99, $88, $88, $98, $88; 13:4440
    db $77, $67, $78, $88, $88, $88, $88, $88, $87, $77, $77, $88, $88, $88, $99, $99; 13:4450
    db $99, $88, $88, $88, $88, $77, $77, $78, $9A, $A9, $74, $23, $45, $55, $44, $45; 13:4460
    db $68, $AB, $BA, $87, $89, $99, $87, $66, $56, $79, $A9, $88, $88, $9A, $98, $76; 13:4470
    db $55, $56, $78, $77, $78, $AB, $BA, $A9, $99, $99, $98, $76, $66, $78, $88, $88; 13:4480
    db $9B, $B8, $41, $02, $45, $53, $34, $57, $9C, $DC, $A7, $68, $9A, $85, $44, $57; 13:4490
    db $8A, $AA, $A9, $9A, $BB, $96, $44, $56, $66, $67, $89, $AC, $CC, $A9, $9A, $A9; 13:44A0
    db $75, $55, $68, $88, $77, $8A, $EF, $92, $00, $38, $73, $00, $49, $CE, $ED, $A6; 13:44B0
    db $57, $AB, $71, $02, $7C, $CA, $99, $BC, $CC, $A8, $52, $35, $77, $54, $6A, $DD; 13:44C0
    db $CA, $99, $9A, $A9, $75, $56, $8A, $97, $66, $8A, $BC, $E8, $00, $06, $C9, $00; 13:44D0
    db $1A, $FF, $B9, $77, $66, $99, $50, $05, $DF, $B6, $5A, $FE, $95, $34, $55, $78; 13:44E0
    db $75, $59, $EE, $A5, $58, $CB, $86, $7A, $A9, $99, $87, $68, $98, $54, $5B, $FF; 13:44F0
    db $40, $05, $ED, $10, $2A, $EE, $A8, $74, $59, $A7, $00, $5F, $FC, $55, $CE, $B7; 13:4500
    db $34, $53, $6A, $A7, $56, $CE, $84, $59, $CA, $78, $AB, $A9, $99, $64, $69, $A7; 13:4510
    db $58, $BC, $EF, $B0, $00, $BD, $30, $2F, $FF, $C7, $63, $3A, $80, $00, $CF, $F7; 13:4520
    db $7A, $EC, $53, $20, $3A, $DB, $55, $CD, $84, $36, $A9, $AB, $AA, $BB, $B6, $25; 13:4530
    db $88, $65, $8C, $CD, $FF, $20, $0A, $B4, $01, $FF, $EF, $B3, $03, $98, $00, $8F; 13:4540
    db $FE, $89, $86, $98, $10, $2B, $FB, $79, $AA, $84, $23, $5C, $EA, $9B, $DE, $A7; 13:4550
    db $75, $45, $79, $AB, $EF, $A0, $05, $95, $42, $8D, $EF, $C0, $04, $77, $01, $9D; 13:4560
    db $FF, $A3, $46, $85, $14, $9C, $FD, $75, $56, $63, $49, $CE, $DB, $AA, $9A, $96; 13:4570
    db $56, $8B, $BC, $FF, $20, $08, $56, $67, $CD, $FC, $00, $45, $56, $5A, $DF, $F8; 13:4580
    db $02, $55, $53, $7B, $EF, $C5, $23, $56, $68, $CD, $DB, $66, $8B, $CB, $87, $8A; 13:4590
    db $AA, $DE, $00, $08, $7B, $99, $AC, $F7, $00, $56, $A9, $89, $DE, $A1, $03, $7A; 13:45A0
    db $88, $AC, $CA, $40, $15, $99, $AC, $DB, $96, $69, $DE, $A7, $78, $88, $AD, $C0; 13:45B0
    db $02, $AA, $B8, $77, $BA, $20, $38, $BD, $97, $8B, $A4, $02, $6B, $D9, $79, $B8; 13:45C0
    db $40, $15, $AB, $AA, $BB, $96, $69, $CD, $B8, $78, $99, $AC, $D1, $00, $8B, $CA; 13:45D0
    db $76, $BA, $30, $37, $BC, $A7, $7A, $94, $03, $7A, $BC, $A8, $76, $21, $59, $BB; 13:45E0
    db $BA, $87, $77, $9C, $CB, $98, $78, $9B, $EC, $00, $29, $C9, $A7, $9B, $70, $05; 13:45F0
    db $AB, $B9, $89, $96, $12, $69, $BC, $98, $87, $31, $49, $CC, $B8, $88, $87, $9C; 13:4600
    db $DA, $88, $89, $AC, $B3, $00, $7B, $99, $99, $B8, $20, $39, $BA, $88, $89, $73; 13:4610
    db $15, $BC, $97, $76, $65, $57, $AB, $97, $88, $88, $AB, $B9, $87, $89, $BC, $C2; 13:4620
    db $01, $9A, $77, $8A, $A8, $30, $5A, $96, $68, $AA, $75, $58, $98, $77, $65, $68; 13:4630
    db $99, $99, $99, $87, $7A, $A9, $88, $99, $8A, $CB, $00, $19, $B8, $89, $A9, $71; 13:4640
    db $05, $AA, $78, $AA, $97, $54, $69, $98, $78, $98, $66, $8A, $A9, $88, $A9, $87; 13:4650
    db $8A, $A8, $78, $BE, $C0, $01, $BA, $46, $CE, $B6, $20, $48, $63, $6D, $EA, $77; 13:4660
    db $76, $53, $48, $CA, $78, $AA, $76, $79, $9A, $98, $89, $A8, $78, $9A, $BD, $A0; 13:4670
    db $05, $A5, $07, $DD, $88, $77, $65, $31, $59, $A9, $AB, $B9, $75, $56, $76, $69; 13:4680
    db $BA, $88, $99, $87, $78, $99, $98, $89, $87, $79, $CE, $E2, $06, $B6, $00, $CE; 13:4690
    db $63, $8D, $C6, $65, $88, $65, $48, $BA, $68, $AA, $76, $79, $98, $87, $78, $77; 13:46A0
    db $89, $A9, $88, $98, $77, $88, $88, $88, $88, $9A, $65, $79, $74, $47, $86, $56; 13:46B0
    db $77, $66, $78, $88, $88, $88, $88, $99, $98, $88, $87, $77, $78, $77, $78, $88; 13:46C0
    db $78, $88, $87, $88, $88, $88, $98, $78, $88, $77, $77, $87, $78, $88, $87, $78; 13:46D0
    db $77, $66, $66, $66, $67, $77, $88, $88, $78, $87, $78, $89, $98, $99, $88, $77; 13:46E0
    db $88, $88, $88, $88, $88, $77, $88, $88, $88, $88, $77, $88, $77, $78, $87, $77; 13:46F0
    db $78, $77, $78, $88, $77, $78, $77, $77, $88, $77, $77, $76, $77, $88, $77, $87; 13:4700
    db $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:4710
    db $88, $87, $77, $88, $88, $88, $87, $77, $77, $88, $87, $77, $77, $77, $77, $88; 13:4720
    db $88, $88, $87, $77, $77, $88, $87, $88, $88, $77, $78, $77, $78, $88, $88, $88; 13:4730
    db $88, $88, $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:4740
    db $87, $77, $88, $87, $77, $87, $77, $78, $77, $77, $88, $88, $88, $88, $77, $78; 13:4750
    db $87, $77, $87, $77, $88, $88, $88, $88, $88, $88, $87, $78, $88, $88, $88, $87; 13:4760
    db $78, $88, $88, $88, $88, $88, $78, $87, $77, $88, $88, $77, $78, $87, $78, $88; 13:4770
    db $88, $78, $88, $78, $86, $89, $96, $79, $96, $79, $95, $69, $96, $59, $B7, $36; 13:4780
    db $B9, $65, $A9, $75, $89, $87, $88, $85, $69, $87, $79, $74, $79, $87, $89, $77; 13:4790
    db $88, $87, $88, $87, $78, $87, $77, $88, $77, $88, $87, $78, $78, $88, $77, $88; 13:47A0
    db $77, $78, $77, $77, $77, $77, $66, $76, $66, $88, $78, $88, $88, $98, $89, $98; 13:47B0
    db $89, $89, $88, $89, $89, $89, $89, $88, $98, $89, $99, $BC, $40, $78, $30, $08; 13:47C0
    db $60, $05, $B9, $68, $BC, $A8, $88, $88, $54, $78, $85, $7B, $B9, $89, $B9, $77; 13:47D0
    db $88, $77, $89, $AA, $9A, $BB, $BA, $AB, $A8, $89, $AA, $AF, $A0, $08, $70, $00; 13:47E0
    db $A4, $01, $9F, $BA, $A8, $A9, $73, $05, $85, $35, $BD, $AA, $BC, $BA, $87, $66; 13:47F0
    db $64, $46, $9A, $89, $BC, $BA, $99, $99, $98, $88, $99, $89, $99, $9A, $CF, $F1; 13:4800
    db $04, $84, $00, $46, $79, $68, $AD, $F8, $13, $77, $20, $35, $9D, $BA, $AD, $FC; 13:4810
    db $87, $67, $66, $53, $59, $98, $89, $AA, $98, $77, $78, $87, $89, $AB, $BB, $A9; 13:4820
    db $99, $87, $67, $9B, $F8, $00, $45, $40, $11, $2A, $C9, $76, $BB, $87, $42, $36; 13:4830
    db $97, $58, $AC, $DC, $B8, $8A, $86, $55, $67, $8A, $97, $89, $A9, $76, $57, $88; 13:4840
    db $77, $89, $AB, $BA, $AA, $98, $77, $77, $88, $78, $9A, $BE, $D2, $01, $01, $24; 13:4850
    db $30, $5B, $CC, $CB, $86, $89, $52, $23, $58, $BB, $AA, $CB, $BB, $A6, $44, $66; 13:4860
    db $67, $78, $9A, $A8, $88, $66, $78, $87, $88, $8A, $BA, $98, $88, $88, $87, $78; 13:4870
    db $88, $89, $87, $77, $89, $BB, $40, $20, $14, $66, $34, $77, $9C, $C9, $77, $76; 13:4880
    db $79, $76, $68, $99, $BC, $A8, $88, $88, $88, $66, $76, $79, $99, $88, $88, $89; 13:4890
    db $87, $77, $77, $89, $88, $99, $9A, $A9, $88, $87, $77, $77, $77, $77, $88, $87; 13:48A0
    db $89, $A6, $45, $21, $35, $65, $67, $66, $9A, $A9, $A8, $66, $88, $88, $98, $78; 13:48B0
    db $98, $9A, $A8, $88, $87, $78, $87, $78, $88, $99, $88, $88, $77, $88, $77, $77; 13:48C0
    db $88, $99, $99, $88, $88, $88, $88, $77, $88, $77, $87, $76, $66, $77, $88, $75; 13:48D0
    db $77, $56, $87, $55, $65, $46, $76, $68, $87, $89, $99, $AA, $99, $99, $99, $99; 13:48E0
    db $98, $88, $87, $88, $77, $77, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88; 13:48F0
    db $99, $98, $88, $88, $88, $77, $77, $76, $66, $66, $66, $66, $77, $78, $86, $88; 13:4900
    db $66, $87, $56, $75, $56, $76, $78, $77, $88, $99, $99, $99, $99, $A9, $AA, $98; 13:4910
    db $88, $88, $88, $77, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $89; 13:4920
    db $88, $88, $88, $88, $87, $77, $77, $77, $77, $66, $66, $77, $77, $77, $89, $97; 13:4930
    db $89, $76, $87, $65, $65, $56, $67, $77, $78, $78, $99, $99, $99, $89, $99, $9A; 13:4940
    db $98, $88, $88, $88, $77, $66, $66, $77, $77, $77, $78, $88, $88, $88, $88, $89; 13:4950
    db $99, $98, $88, $88, $88, $88, $77, $77, $77, $76, $66, $66, $67, $77, $77, $77; 13:4960
    db $88, $88, $88, $78, $87, $77, $76, $66, $66, $67, $77, $77, $88, $89, $99, $99; 13:4970
    db $99, $99, $99, $98, $88, $88, $88, $77, $77, $77, $77, $77, $77, $77, $88, $88; 13:4980
    db $88, $88, $88, $98, $88, $88, $88, $88, $77, $77, $77, $77, $77, $77, $77, $77; 13:4990
    db $77, $77, $77, $88, $88, $88, $88, $88, $88, $77, $77, $76, $66, $67, $77, $77; 13:49A0
    db $77, $88, $88, $88, $89, $99, $99, $99, $98, $88, $88, $77, $77, $77, $77, $77; 13:49B0
    db $77, $77, $78, $88, $88, $88, $89, $99, $88, $88, $88, $88, $77, $77, $77, $77; 13:49C0
    db $77, $77, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $87, $77; 13:49D0
    db $77, $76, $66, $66, $77, $77, $78, $88, $88, $88, $89, $99, $99, $98, $88, $88; 13:49E0
    db $88, $87, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:49F0
    db $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88; 13:4A00
    db $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88; 13:4A10
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $78, $88, $88, $88, $88; 13:4A20
    db $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $77, $77, $77, $88; 13:4A30
    db $88, $88, $87, $87, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:4A40
    db $88, $88, $88, $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:4A50
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77; 13:4A60
    db $77, $77, $77, $77, $77, $77, $77, $78, $78, $78, $88, $88, $88, $88, $88, $88; 13:4A70
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:4A80
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $78, $77, $77; 13:4A90
    db $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $78, $88, $88, $88, $88; 13:4AA0
    db $88, $88, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:4AB0

;; PCM12: 2096 bytes = 4192 4-bit samples (rate 2) for SFXInst26
PCM12:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:4AC0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:4AD0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:4AE0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:4AF0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $87, $87, $87, $87, $88; 13:4B00
    db $78, $78, $78, $78, $78, $78, $78, $78, $88, $87, $87, $77, $88, $88, $88, $88; 13:4B10
    db $78, $88, $88, $88, $87, $87, $87, $87, $87, $87, $87, $88, $78, $78, $78, $78; 13:4B20
    db $78, $78, $88, $88, $78, $78, $78, $78, $87, $87, $77, $88, $77, $87, $87, $87; 13:4B30
    db $88, $78, $78, $78, $88, $88, $78, $88, $78, $78, $87, $87, $87, $88, $88, $78; 13:4B40
    db $78, $87, $77, $88, $79, $78, $87, $88, $88, $88, $88, $78, $78, $87, $87, $87; 13:4B50
    db $78, $78, $77, $87, $87, $87, $78, $77, $87, $87, $87, $78, $78, $88, $78, $78; 13:4B60
    db $78, $88, $78, $78, $87, $87, $88, $78, $88, $87, $88, $78, $78, $78, $87, $88; 13:4B70
    db $88, $78, $77, $87, $77, $87, $79, $78, $88, $87, $88, $78, $87, $87, $78, $77; 13:4B80
    db $87, $78, $78, $78, $87, $88, $78, $87, $78, $77, $97, $77, $88, $68, $86, $88; 13:4B90
    db $78, $88, $78, $97, $79, $77, $98, $78, $87, $78, $88, $88, $78, $87, $88, $78; 13:4BA0
    db $87, $88, $77, $88, $77, $87, $78, $76, $77, $67, $77, $67, $77, $78, $77, $88; 13:4BB0
    db $78, $98, $8A, $88, $AA, $88, $A8, $89, $97, $89, $88, $99, $88, $98, $88, $98; 13:4BC0
    db $88, $86, $57, $53, $44, $43, $34, $44, $55, $68, $88, $8A, $BA, $AB, $BA, $AA; 13:4BD0
    db $99, $98, $77, $76, $56, $66, $67, $78, $88, $9A, $AA, $AB, $AA, $AA, $AA, $AA; 13:4BE0
    db $9A, $BA, $AB, $84, $79, $40, $14, $20, $01, $22, $23, $67, $89, $8B, $DD, $BA; 13:4BF0
    db $CD, $B8, $89, $97, $56, $76, $54, $57, $76, $68, $A9, $89, $BB, $A9, $AB, $BA; 13:4C00
    db $9A, $BA, $9A, $BC, $CC, $CD, $84, $98, $30, $03, $10, $00, $33, $14, $99, $BB; 13:4C10
    db $BC, $DE, $CA, $8B, $96, $44, $66, $33, $57, $86, $79, $9A, $A8, $AA, $A9, $88; 13:4C20
    db $98, $88, $9B, $AA, $BD, $EE, $EF, $FF, $72, $68, $20, $00, $10, $00, $48, $67; 13:4C30
    db $BC, $FF, $EC, $BB, $C8, $32, $45, $30, $26, $78, $89, $CD, $DC, $A9, $98, $74; 13:4C40
    db $35, $65, $56, $9B, $BC, $DE, $FE, $ED, $DE, $FF, $A0, $04, $50, $00, $15, $10; 13:4C50
    db $2A, $DC, $DC, $BC, $DC, $81, $16, $52, $00, $79, $89, $AE, $FF, $ED, $A9, $85; 13:4C60
    db $20, $02, $34, $58, $BC, $DE, $EE, $ED, $DB, $AA, $BB, $CE, $B0, $03, $85, $00; 13:4C70
    db $17, $52, $28, $BB, $DC, $97, $7B, $A3, $02, $68, $42, $6A, $CD, $CD, $BB, $CD; 13:4C80
    db $82, $03, $53, $12, $6A, $BB, $CC, $DE, $ED, $A9, $BC, $CA, $BF, $F4, $00, $68; 13:4C90
    db $00, $03, $65, $48, $A9, $DF, $D8, $46, $A7, $00, $17, $75, $69, $BC, $DF, $EA; 13:4CA0
    db $89, $95, $00, $24, $44, $7A, $BC, $EE, $DB, $CE, $DA, $9A, $CD, $EF, $60, $03; 13:4CB0
    db $92, $00, $17, $96, $69, $AC, $EE, $94, $27, $95, $00, $38, $98, $9A, $CD, $FF; 13:4CC0
    db $C7, $56, $73, $00, $25, $78, $AB, $BD, $EF, $DA, $AC, $DC, $AB, $FF, $90, $01; 13:4CD0
    db $73, $00, $04, $78, $AB, $99, $CF, $D6, $13, $67, $30, $04, $68, $BB, $BA, $BF; 13:4CE0
    db $FB, $62, $45, $42, $23, $58, $BC, $CB, $BE, $FE, $BB, $CE, $DD, $FE, $40, $03; 13:4CF0
    db $71, $00, $06, $89, $BB, $A9, $CF, $E7, $12, $58, $41, $13, $57, $AD, $C9, $8B; 13:4D00
    db $FE, $83, $34, $54, $45, $56, $8C, $ED, $AB, $DF, $ED, $CD, $DE, $E8, $10, $02; 13:4D10
    db $21, $00, $03, $6A, $CB, $98, $AE, $EB, $74, $45, $55, $55, $43, $59, $BB, $99; 13:4D20
    db $99, $99, $98, $65, $57, $89, $99, $A9, $AB, $CC, $BA, $AB, $DD, $B6, $32, $44; 13:4D30
    db $44, $32, $11, $47, $88, $66, $78, $9A, $AA, $98, $77, $88, $88, $77, $77, $78; 13:4D40
    db $88, $77, $78, $99, $98, $88, $88, $88, $77, $88, $89, $99, $99, $AA, $A9, $88; 13:4D50
    db $88, $88, $76, $65, $55, $55, $55, $55, $55, $56, $67, $77, $88, $88, $99, $99; 13:4D60
    db $9A, $AA, $AA, $A9, $98, $88, $77, $66, $66, $66, $78, $88, $89, $99, $9A, $AA; 13:4D70
    db $99, $99, $88, $87, $66, $55, $55, $55, $55, $55, $55, $66, $77, $78, $88, $89; 13:4D80
    db $99, $9A, $AA, $AA, $99, $99, $88, $77, $76, $66, $66, $77, $78, $88, $89, $99; 13:4D90
    db $99, $99, $99, $88, $88, $87, $77, $66, $65, $55, $55, $55, $55, $66, $66, $77; 13:4DA0
    db $88, $88, $99, $AA, $AA, $AA, $A9, $99, $88, $87, $77, $77, $77, $77, $77, $77; 13:4DB0
    db $77, $88, $88, $88, $89, $99, $99, $99, $98, $88, $87, $66, $55, $55, $55, $55; 13:4DC0
    db $55, $66, $67, $77, $88, $88, $89, $99, $99, $99, $99, $99, $98, $88, $88, $87; 13:4DD0
    db $77, $66, $66, $66, $67, $77, $88, $88, $99, $99, $99, $99, $88, $88, $88, $77; 13:4DE0
    db $77, $77, $66, $55, $66, $66, $66, $66, $67, $77, $78, $88, $89, $99, $99, $99; 13:4DF0
    db $99, $99, $88, $88, $87, $77, $76, $67, $77, $77, $77, $77, $88, $88, $85, $8A; 13:4E00
    db $99, $99, $99, $9A, $AA, $97, $66, $66, $66, $55, $55, $56, $66, $67, $77, $78; 13:4E10
    db $89, $98, $88, $88, $88, $88, $88, $88, $88, $87, $88, $88, $88, $88, $89, $99; 13:4E20
    db $99, $9A, $AA, $AB, $CC, $A6, $33, $45, $53, $22, $22, $46, $88, $55, $79, $98; 13:4E30
    db $88, $87, $78, $9A, $87, $78, $98, $77, $77, $77, $78, $87, $78, $99, $99, $AB; 13:4E40
    db $BB, $BC, $CC, $CD, $FF, $D7, $10, $13, $21, $00, $00, $27, $BC, $97, $8B, $DC; 13:4E50
    db $A8, $64, $33, $68, $75, $35, $9B, $BA, $98, $77, $78, $86, $56, $8A, $BB, $BB; 13:4E60
    db $CC, $DF, $FF, $FF, $FB, $20, $00, $10, $00, $00, $37, $CF, $EB, $9B, $FF, $B5; 13:4E70
    db $22, $23, $35, $65, $46, $BF, $FC, $88, $98, $75, $43, $35, $8B, $DB, $BC, $EF; 13:4E80
    db $FF, $FF, $FF, $F7, $00, $00, $00, $00, $03, $9E, $FF, $DA, $BE, $FC, $40, $00; 13:4E90
    db $34, $44, $56, $9D, $FF, $C8, $79, $A7, $30, $03, $6A, $CC, $BB, $EF, $FF, $DC; 13:4EA0
    db $DF, $FF, $80, $00, $15, $00, $00, $6C, $FF, $DB, $AC, $FF, $90, $00, $46, $41; 13:4EB0
    db $25, $AE, $FF, $D9, $79, $BA, $30, $02, $79, $99, $AD, $EF, $FF, $CB, $CF, $FF; 13:4EC0
    db $F7, $00, $04, $50, $00, $1B, $DB, $AB, $DE, $EE, $A4, $00, $37, $40, $05, $DF; 13:4ED0
    db $EB, $BC, $BA, $97, $50, $02, $77, $66, $BF, $FE, $DD, $ED, $CD, $DD, $DF, $E3; 13:4EE0
    db $00, $27, $10, $00, $AC, $AA, $CD, $DC, $EB, $40, $05, $72, $00, $8E, $EB, $BC; 13:4EF0
    db $CB, $88, $52, $02, $55, $45, $AD, $EC, $CD, $EC, $BB, $CC, $CE, $FF, $40, $05; 13:4F00
    db $A0, $00, $1B, $A7, $8B, $DE, $FE, $80, $05, $94, $00, $6D, $EA, $AC, $DD, $CA; 13:4F10
    db $50, $05, $74, $03, $BF, $C9, $AE, $EC, $AA, $98, $BE, $FE, $FE, $30, $06, $40; 13:4F20
    db $00, $5A, $66, $BE, $FF, $DA, $31, $56, $20, $06, $CB, $9A, $EF, $EC, $95, $22; 13:4F30
    db $55, $10, $5C, $CA, $AC, $ED, $BA, $97, $8B, $CB, $BF, $FF, $30, $08, $60, $00; 13:4F40
    db $59, $77, $BD, $FF, $E6, $13, $94, $00, $19, $B9, $AB, $EF, $FB, $52, $66, $20; 13:4F50
    db $06, $99, $9A, $DE, $CB, $98, $99, $87, $8C, $EE, $FF, $F3, $02, $60, $00, $05; 13:4F60
    db $68, $9D, $FF, $FA, $24, $75, $00, $06, $88, $9C, $FF, $FB, $67, $86, $00, $26; 13:4F70
    db $77, $7B, $EE, $D8, $8A, $A7, $56, $AB, $BB, $EF, $FF, $F0, $05, $50, $00, $57; 13:4F80
    db $78, $9F, $FF, $C3, $58, $40, $00, $57, $78, $9F, $FF, $B8, $AB, $50, $00, $56; 13:4F90
    db $55, $BF, $FA, $9A, $B9, $55, $68, $A8, $9C, $FF, $EF, $FF, $00, $42, $00, $02; 13:4FA0
    db $59, $B8, $EF, $FB, $47, $61, $00, $04, $55, $8C, $FF, $EC, $CB, $82, $00, $23; 13:4FB0
    db $25, $9C, $CB, $BD, $C9, $65, $88, $65, $7A, $BB, $BC, $FF, $FF, $F0, $08, $00; 13:4FC0
    db $00, $54, $78, $9F, $FA, $87, $B5, $00, $03, $53, $4B, $FF, $BD, $ED, $A5, $23; 13:4FD0
    db $32, $11, $7A, $AA, $CE, $DA, $88, $75, $45, $78, $78, $AD, $CC, $CF, $FE, $EF; 13:4FE0
    db $60, $53, $00, $04, $36, $79, $FF, $B9, $BB, $70, $00, $22, $13, $AD, $DC, $EF; 13:4FF0
    db $EB, $75, $54, $10, $36, $68, $AC, $DC, $BA, $A8, $54, $55, $55, $8A, $AB, $BD; 13:5000
    db $EC, $CB, $BC, $BD, $60, $66, $00, $07, $46, $67, $EE, $77, $9A, $50, $42, $53; 13:5010
    db $26, $BB, $AA, $FE, $B9, $89, $64, $23, $66, $47, $AC, $AA, $BB, $A7, $57, $65; 13:5020
    db $45, $78, $89, $BC, $CC, $CC, $BA, $AA, $AA, $D8, $07, $70, $00, $50, $33, $4C; 13:5030
    db $A8, $9D, $C7, $58, $56, $22, $57, $65, $9D, $BB, $BC, $C9, $86, $75, $23, $66; 13:5040
    db $67, $AB, $A9, $AA, $97, $67, $86, $68, $99, $9A, $BB, $A9, $AA, $98, $9A, $BC; 13:5050
    db $C2, $3C, $10, $03, $30, $52, $AA, $89, $BE, $86, $97, $53, $26, $46, $48, $B9; 13:5060
    db $AB, $DC, $AA, $98, $65, $55, $54, $58, $88, $9A, $A9, $99, $88, $77, $87, $78; 13:5070
    db $98, $89, $AA, $AA, $BB, $AA, $AA, $AB, $80, $88, $00, $15, $01, $54, $B6, $9B; 13:5080
    db $CB, $6B, $A6, $55, $75, $45, $6A, $78, $AC, $B9, $BC, $98, $78, $65, $45, $65; 13:5090
    db $57, $88, $8A, $AA, $99, $98, $77, $87, $67, $88, $89, $AA, $9A, $AA, $99, $9A; 13:50A0
    db $9A, $A1, $6B, $12, $16, $10, $61, $72, $69, $8B, $6D, $C9, $99, $B7, $58, $57; 13:50B0
    db $46, $76, $77, $BA, $9A, $BB, $89, $98, $75, $76, $55, $78, $78, $9A, $99, $A9; 13:50C0
    db $88, $88, $77, $78, $87, $88, $88, $99, $99, $99, $98, $9A, $72, $97, $13, $46; 13:50D0
    db $02, $53, $52, $78, $78, $9D, $A9, $BB, $A7, $9A, $76, $69, $76, $78, $86, $88; 13:50E0
    db $87, $89, $88, $89, $98, $99, $98, $88, $87, $78, $77, $88, $88, $99, $88, $88; 13:50F0
    db $87, $88, $77, $88, $78, $88, $88, $87, $76, $76, $66, $67, $76, $77, $77, $77; 13:5100
    db $76, $66, $66, $77, $77, $88, $88, $89, $99, $99, $88, $88, $88, $88, $98, $88; 13:5110
    db $88, $88, $77, $77, $77, $77, $88, $78, $88, $88, $88, $88, $87, $77, $77, $77; 13:5120
    db $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88; 13:5130
    db $88, $88, $88, $77, $77, $77, $78, $88, $88, $88, $88, $77, $77, $77, $77, $88; 13:5140
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $78; 13:5150
    db $88, $88, $88, $88, $77, $77, $87, $78, $88, $88, $88, $88, $87, $77, $77, $77; 13:5160
    db $78, $78, $88, $88, $88, $87, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88; 13:5170
    db $88, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $87, $77, $77, $78, $88; 13:5180
    db $88, $88, $88, $88, $77, $88, $78, $87, $88, $87, $77, $77, $77, $88, $88, $88; 13:5190
    db $88, $88, $87, $77, $77, $87, $88, $88, $88, $88, $77, $77, $77, $77, $77, $87; 13:51A0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77; 13:51B0
    db $77, $77, $88, $88, $88, $88, $87, $77, $77, $77, $78, $88, $88, $77, $88, $88; 13:51C0
    db $88, $78, $87, $78, $87, $88, $87, $78, $77, $88, $77, $88, $78, $88, $88, $77; 13:51D0
    db $77, $67, $87, $88, $88, $89, $88, $88, $77, $77, $77, $77, $88, $88, $88, $78; 13:51E0
    db $77, $77, $77, $78, $78, $88, $88, $88, $87, $87, $77, $77, $77, $88, $88, $88; 13:51F0
    db $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $88, $77; 13:5200
    db $88, $77, $87, $77, $77, $77, $87, $88, $78, $87, $78, $87, $78, $87, $88, $88; 13:5210
    db $88, $87, $87, $77, $77, $77, $77, $88, $88, $88, $88, $87, $78, $77, $88, $78; 13:5220
    db $88, $88, $88, $88, $77, $87, $88, $88, $88, $88, $88, $77, $77, $77, $77, $78; 13:5230
    db $88, $88, $88, $88, $77, $77, $77, $77, $88, $88, $88, $87, $88, $77, $77, $77; 13:5240
    db $77, $77, $88, $88, $88, $88, $87, $88, $87, $88, $88, $88, $88, $88, $88, $88; 13:5250
    db $88, $88, $88, $88, $88, $87, $88, $88, $87, $88, $77, $78, $88, $88, $88, $87; 13:5260
    db $88, $77, $77, $77, $88, $77, $88, $87, $88, $77, $77, $77, $77, $78, $88, $88; 13:5270
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87; 13:5280
    db $78, $77, $88, $88, $88, $88, $88, $88, $77, $77, $77, $78, $87, $88, $88, $88; 13:5290
    db $88, $77, $88, $88, $88, $88, $88, $87, $88, $77, $77, $88, $88, $88, $88, $87; 13:52A0
    db $77, $77, $88, $88, $78, $88, $88, $87, $88, $88, $88, $88, $88, $88, $88, $88; 13:52B0
    db $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $78, $87, $77, $77, $77, $77; 13:52C0
    db $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $87, $78, $87, $88; 13:52D0
    db $88, $88, $88, $88, $88, $78, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88; 13:52E0

;; PCM13: 2512 bytes = 5024 4-bit samples (rate 2) for SFXInst27
PCM13:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:52F0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:5300
    db $88, $88, $88, $87, $76, $66, $55, $55, $55, $56, $67, $78, $88, $89, $99, $99; 13:5310
    db $99, $99, $98, $88, $88, $87, $77, $77, $78, $88, $88, $99, $99, $9A, $AA, $AA; 13:5320
    db $98, $97, $67, $65, $44, $23, $44, $45, $56, $77, $88, $99, $9A, $AA, $99, $A9; 13:5330
    db $99, $88, $87, $77, $76, $67, $77, $88, $88, $99, $9A, $AA, $AB, $BB, $B9, $98; 13:5340
    db $76, $64, $33, $22, $33, $34, $55, $67, $88, $89, $9A, $AA, $A9, $99, $99, $87; 13:5350
    db $66, $67, $77, $66, $88, $9A, $AA, $BC, $CD, $EE, $FA, $54, $02, $33, $21, $34; 13:5360
    db $87, $86, $56, $78, $99, $88, $BB, $CA, $76, $55, $55, $45, $77, $99, $88, $88; 13:5370
    db $9A, $9A, $BB, $CC, $DE, $FF, $D3, $00, $04, $57, $46, $7A, $A8, $60, $24, $7A; 13:5380
    db $A8, $8A, $CB, $95, $32, $57, $78, $78, $9A, $97, $76, $79, $AB, $AB, $BB, $CD; 13:5390
    db $EF, $F6, $00, $03, $79, $85, $87, $A8, $51, $03, $7B, $BA, $98, $BA, $86, $33; 13:53A0
    db $47, $88, $97, $88, $87, $67, $7A, $AB, $BA, $BC, $DE, $FF, $70, $00, $39, $99; 13:53B0
    db $68, $6A, $73, $10, $38, $BB, $A9, $8B, $A7, $63, $46, $98, $77, $68, $88, $65; 13:53C0
    db $78, $BA, $AA, $AC, $DF, $FF, $A0, $00, $09, $9A, $68, $79, $82, $10, $38, $CC; 13:53D0
    db $A9, $8A, $A6, $53, $47, $99, $78, $78, $87, $66, $89, $BB, $AB, $CE, $FF, $EB; 13:53E0
    db $00, $00, $88, $96, $99, $88, $20, $14, $8B, $B9, $9A, $99, $53, $35, $88, $86; 13:53F0
    db $78, $98, $66, $69, $AA, $AA, $BD, $EF, $FE, $A0, $00, $19, $88, $6A, $A9, $71; 13:5400
    db $02, $69, $A9, $9B, $BA, $84, $45, $67, $56, $79, $A8, $76, $89, $A9, $9A, $CD; 13:5410
    db $DD, $FF, $E3, $00, $06, $86, $68, $C9, $82, $02, $68, $88, $9B, $DA, $74, $47; 13:5420
    db $66, $35, $89, $A7, $67, $89, $89, $9B, $DD, $DE, $FF, $E2, $00, $15, $64, $5A; 13:5430
    db $E9, $62, $15, $65, $58, $BD, $E9, $78, $76, $44, $37, $87, $88, $98, $76, $79; 13:5440
    db $AB, $BC, $EE, $FF, $EA, $00, $21, $42, $57, $DB, $67, $65, $43, $25, $BA, $AB; 13:5450
    db $BB, $97, $34, $53, $45, $89, $A9, $89, $87, $88, $BC, $DD, $EF, $FF, $70, $34; 13:5460
    db $10, $15, $7D, $77, $BC, $73, $44, $57, $46, $BD, $A9, $B9, $A6, $21, $55, $35; 13:5470
    db $8B, $B9, $8A, $B9, $9B, $CC, $CD, $EF, $70, $65, $10, $03, $48, $58, $DE, $86; 13:5480
    db $A8, $44, $24, $67, $58, $DB, $AA, $B8, $64, $35, $54, $68, $A9, $AB, $CB, $AA; 13:5490
    db $BB, $CD, $EE, $33, $A3, $00, $62, $34, $5B, $CB, $8C, $E7, $46, $54, $14, $38; 13:54A0
    db $87, $AD, $C9, $AA, $76, $55, $55, $66, $88, $8A, $BA, $AC, $DD, $DD, $ED, $25; 13:54B0
    db $93, $00, $60, $02, $79, $98, $9D, $D6, $8B, $84, $47, $44, $46, $88, $89, $CB; 13:54C0
    db $89, $B8, $46, $75, $45, $88, $79, $AC, $BC, $DE, $EE, $FF, $35, $C2, $00, $60; 13:54D0
    db $00, $26, $47, $8D, $D8, $DF, $A8, $8B, $54, $45, $53, $56, $86, $7B, $99, $8B; 13:54E0
    db $97, $88, $76, $68, $88, $8B, $BB, $CD, $DC, $CD, $D8, $5C, $61, $05, $20, $02; 13:54F0
    db $31, $48, $99, $9D, $EB, $AB, $D7, $68, $74, $35, $64, $46, $86, $68, $98, $8A; 13:5500
    db $A9, $9A, $A8, $89, $98, $89, $99, $9A, $BA, $AC, $DC, $59, $C3, $23, $70, $03; 13:5510
    db $21, $05, $55, $67, $BA, $9B, $DC, $8B, $B8, $77, $84, $45, $65, $58, $87, $8A; 13:5520
    db $A9, $9A, $A9, $89, $98, $89, $98, $9A, $A9, $AA, $99, $AA, $99, $77, $85, $44; 13:5530
    db $43, $34, $33, $44, $55, $66, $78, $79, $99, $9A, $A9, $99, $88, $88, $87, $77; 13:5540
    db $87, $78, $88, $89, $88, $99, $99, $99, $99, $88, $88, $88, $88, $78, $87, $78; 13:5550
    db $77, $77, $88, $77, $87, $67, $75, $55, $54, $45, $55, $56, $66, $77, $89, $89; 13:5560
    db $AA, $9A, $A9, $99, $88, $98, $88, $88, $88, $78, $88, $89, $88, $98, $88, $87; 13:5570
    db $88, $78, $87, $77, $77, $77, $67, $66, $67, $67, $76, $77, $77, $87, $78, $77; 13:5580
    db $88, $78, $87, $88, $87, $77, $67, $77, $67, $77, $78, $78, $87, $98, $89, $99; 13:5590
    db $89, $88, $98, $89, $79, $88, $88, $97, $98, $88, $88, $79, $77, $97, $67, $85; 13:55A0
    db $87, $67, $76, $68, $85, $97, $78, $78, $77, $68, $77, $86, $87, $78, $88, $78; 13:55B0
    db $87, $87, $88, $88, $88, $88, $87, $89, $79, $89, $78, $97, $87, $68, $78, $78; 13:55C0
    db $77, $97, $88, $88, $88, $88, $88, $78, $69, $66, $86, $77, $87, $88, $88, $78; 13:55D0
    db $78, $87, $87, $87, $78, $78, $78, $78, $88, $78, $87, $88, $78, $78, $68, $77; 13:55E0
    db $87, $88, $88, $79, $78, $88, $88, $78, $77, $87, $87, $88, $79, $68, $86, $97; 13:55F0
    db $87, $78, $78, $88, $87, $78, $78, $77, $86, $87, $79, $88, $88, $77, $87, $78; 13:5600
    db $86, $97, $78, $78, $68, $86, $96, $89, $79, $78, $87, $78, $78, $78, $77, $87; 13:5610
    db $88, $77, $87, $87, $97, $89, $87, $88, $68, $87, $79, $68, $88, $79, $87, $88; 13:5620
    db $78, $87, $79, $68, $87, $78, $77, $88, $78, $87, $87, $87, $87, $78, $77, $97; 13:5630
    db $88, $88, $87, $88, $68, $78, $78, $87, $88, $88, $79, $77, $87, $87, $87, $78; 13:5640
    db $69, $77, $97, $98, $88, $79, $68, $96, $88, $78, $77, $88, $87, $87, $78, $88; 13:5650
    db $78, $87, $88, $78, $78, $77, $86, $88, $69, $68, $77, $87, $78, $77, $97, $88; 13:5660
    db $89, $69, $87, $87, $88, $78, $77, $88, $78, $87, $88, $88, $88, $78, $87, $87; 13:5670
    db $78, $77, $87, $77, $88, $68, $87, $87, $78, $68, $87, $69, $77, $87, $87, $88; 13:5680
    db $79, $78, $78, $78, $87, $88, $87, $88, $87, $88, $78, $77, $88, $87, $88, $88; 13:5690
    db $79, $78, $78, $78, $87, $88, $78, $88, $78, $87, $88, $78, $87, $79, $77, $88; 13:56A0
    db $78, $86, $88, $77, $87, $78, $77, $98, $77, $88, $78, $78, $77, $87, $88, $6A; 13:56B0
    db $77, $87, $87, $88, $78, $86, $87, $87, $87, $78, $86, $88, $78, $88, $78, $87; 13:56C0
    db $87, $79, $77, $87, $86, $88, $78, $88, $87, $88, $78, $87, $79, $68, $69, $77; 13:56D0
    db $96, $79, $68, $78, $68, $78, $78, $86, $88, $68, $86, $88, $87, $88, $77, $96; 13:56E0
    db $88, $69, $77, $78, $86, $97, $78, $88, $78, $86, $A6, $69, $77, $87, $87, $97; 13:56F0
    db $78, $86, $79, $66, $98, $69, $86, $88, $88, $88, $79, $67, $A6, $79, $76, $98; 13:5700
    db $69, $86, $88, $87, $87, $78, $88, $96, $97, $78, $87, $78, $77, $88, $78, $88; 13:5710
    db $77, $88, $79, $86, $97, $79, $78, $78, $86, $97, $78, $95, $88, $78, $88, $6A; 13:5720
    db $77, $88, $77, $88, $68, $95, $98, $78, $87, $87, $87, $88, $78, $87, $88, $68; 13:5730
    db $88, $68, $96, $88, $87, $88, $68, $78, $87, $89, $69, $78, $78, $86, $89, $58; 13:5740
    db $86, $88, $77, $88, $67, $97, $6A, $68, $87, $87, $88, $78, $87, $97, $88, $79; 13:5750
    db $87, $97, $87, $88, $78, $78, $88, $79, $68, $96, $88, $87, $79, $68, $87, $78; 13:5760
    db $78, $78, $76, $97, $79, $77, $88, $77, $88, $78, $69, $68, $87, $88, $78, $86; 13:5770
    db $99, $69, $87, $88, $87, $89, $68, $88, $78, $88, $79, $87, $87, $88, $69, $86; 13:5780
    db $96, $87, $78, $78, $87, $78, $95, $98, $68, $97, $69, $94, $98, $5A, $75, $98; 13:5790
    db $67, $A6, $7A, $75, $A7, $68, $87, $79, $77, $87, $88, $87, $87, $79, $78, $87; 13:57A0
    db $87, $88, $88, $69, $86, $98, $77, $87, $69, $76, $98, $67, $97, $78, $95, $98; 13:57B0
    db $77, $87, $88, $87, $77, $A5, $89, $59, $86, $88, $77, $88, $68, $87, $86, $87; 13:57C0
    db $78, $68, $77, $95, $97, $6A, $68, $95, $98, $59, $87, $78, $86, $79, $68, $97; 13:57D0
    db $88, $78, $88, $87, $88, $78, $97, $88, $88, $78, $88, $87, $88, $87, $88, $78; 13:57E0
    db $87, $88, $68, $77, $88, $68, $88, $68, $86, $88, $77, $97, $78, $86, $88, $77; 13:57F0
    db $97, $78, $97, $79, $78, $87, $87, $87, $79, $77, $97, $7A, $85, $9B, $67, $B8; 13:5800
    db $69, $A6, $8A, $87, $A8, $57, $85, $46, $53, $55, $44, $77, $57, $88, $89, $99; 13:5810
    db $99, $88, $99, $88, $99, $89, $99, $AA, $9A, $BA, $AB, $BA, $BD, $D6, $2C, $80; 13:5820
    db $30, $23, $00, $04, $73, $39, $AA, $B8, $BD, $CA, $79, $B7, $55, $47, $63, $47; 13:5830
    db $98, $69, $BB, $A9, $AC, $B9, $9A, $CB, $9B, $DF, $F6, $0D, $C1, $00, $43, $00; 13:5840
    db $03, $B6, $18, $DF, $C6, $BD, $CB, $44, $88, $51, $28, $85, $56, $BC, $87, $9B; 13:5850
    db $B7, $79, $BA, $78, $CD, $CC, $DF, $FE, $05, $E3, $00, $02, $00, $00, $9E, $98; 13:5860
    db $CF, $F9, $99, $89, $40, $03, $65, $15, $BC, $B9, $AD, $B9, $74, $76, $54, $59; 13:5870
    db $B9, $AD, $EF, $DD, $EF, $FF, $20, $65, $00, $03, $45, $54, $BF, $FE, $B8, $FC; 13:5880
    db $40, $03, $42, $12, $7F, $EC, $BD, $FC, $75, $44, $40, $23, $8B, $AB, $CE, $FD; 13:5890
    db $AA, $9B, $97, $8B, $EF, $80, $27, $83, $00, $59, $A5, $7A, $EF, $C3, $46, $86; 13:58A0
    db $00, $28, $A9, $8A, $CF, $E8, $75, $85, $21, $35, $98, $9A, $BD, $BA, $88, $99; 13:58B0
    db $88, $8B, $BD, $EF, $FC, $00, $15, $30, $21, $8D, $DF, $9A, $FD, $50, $02, $13; 13:58C0
    db $64, $8C, $FF, $D9, $98, $72, $00, $05, $8B, $9B, $EE, $CA, $66, $56, $75, $78; 13:58D0
    db $BC, $BC, $ED, $EE, $FF, $00, $00, $50, $06, $2F, $FF, $A2, $78, $52, $00, $06; 13:58E0
    db $FE, $AA, $DF, $C8, $20, $04, $78, $4A, $DF, $FC, $A5, $34, $44, $46, $AA, $ED; 13:58F0
    db $A8, $8B, $A9, $98, $89, $DF, $F0, $00, $09, $28, $71, $FF, $F7, $13, $02, $43; 13:5900
    db $20, $AF, $FF, $98, $55, $93, $00, $5B, $EF, $E9, $98, $A5, $12, $28, $BD, $C9; 13:5910
    db $99, $88, $66, $68, $BC, $BA, $AB, $EF, $F0, $00, $0A, $3F, $80, $FF, $F7, $00; 13:5920
    db $02, $6B, $70, $BF, $FF, $97, $00, $86, $84, $9A, $DF, $F8, $20, $42, $78, $99; 13:5930
    db $BE, $B6, $54, $67, $BB, $89, $9A, $99, $A9, $BC, $EF, $D0, $00, $08, $8F, $57; 13:5940
    db $CF, $F4, $20, $03, $8E, $78, $BB, $FD, $92, $03, $5A, $BB, $B8, $CD, $A6, $12; 13:5950
    db $26, $BB, $A8, $A8, $76, $55, $7A, $BA, $A8, $87, $89, $9A, $BB, $BA, $BF, $C0; 13:5960
    db $00, $29, $CF, $66, $9A, $B1, $30, $04, $BF, $BC, $A6, $98, $81, $05, $7E, $EF; 13:5970
    db $A5, $77, $85, $55, $48, $CD, $A7, $65, $79, $98, $79, $99, $86, $67, $AC, $CB; 13:5980
    db $A9, $88, $99, $CF, $40, $00, $69, $FD, $37, $6A, $75, $40, $38, $EE, $AA, $46; 13:5990
    db $88, $72, $56, $AE, $EC, $55, $56, $87, $85, $79, $AA, $76, $56, $89, $97, $88; 13:59A0
    db $9A, $98, $89, $99, $97, $67, $89, $9B, $BB, $EA, $00, $00, $7C, $FA, $78, $99; 13:59B0
    db $54, $00, $5B, $FD, $C8, $56, $77, $44, $68, $CE, $D8, $44, $57, $88, $87, $9A; 13:59C0
    db $A7, $55, $57, $9A, $98, $88, $88, $88, $89, $AA, $98, $77, $89, $98, $88, $9C; 13:59D0
    db $E8, $00, $02, $9F, $F8, $66, $67, $54, $02, $9D, $FD, $94, $25, $78, $66, $8A; 13:59E0
    db $ED, $A6, $33, $58, $AA, $98, $98, $87, $54, $68, $AA, $98, $67, $99, $99, $88; 13:59F0
    db $88, $87, $78, $89, $98, $77, $78, $9A, $DA, $10, $02, $8D, $E9, $67, $66, $64; 13:5A00
    db $23, $8B, $DC, $95, $36, $78, $88, $89, $BB, $96, $55, $68, $A9, $88, $88, $76; 13:5A10
    db $56, $89, $A9, $87, $77, $89, $88, $88, $99, $87, $77, $88, $89, $88, $87, $77; 13:5A20
    db $89, $BB, $71, $00, $4A, $DC, $85, $67, $87, $43, $5A, $CC, $A7, $55, $78, $87; 13:5A30
    db $78, $AB, $A7, $55, $58, $99, $88, $89, $87, $55, $67, $9A, $98, $77, $88, $88; 13:5A40
    db $88, $99, $87, $77, $88, $98, $87, $77, $88, $77, $78, $8A, $B9, $42, $12, $7B; 13:5A50
    db $B9, $88, $77, $74, $35, $8A, $BB, $86, $67, $77, $77, $8A, $A9, $76, $66, $89; 13:5A60
    db $88, $88, $88, $76, $67, $89, $98, $77, $77, $88, $99, $99, $87, $77, $78, $88; 13:5A70
    db $88, $88, $87, $77, $78, $88, $87, $89, $B9, $32, $24, $8B, $A8, $78, $87, $74; 13:5A80
    db $36, $9B, $AA, $87, $78, $75, $78, $9B, $B9, $66, $66, $78, $89, $AA, $98, $65; 13:5A90
    db $67, $88, $89, $98, $76, $56, $79, $99, $98, $88, $87, $77, $88, $87, $77, $88; 13:5AA0
    db $77, $77, $77, $77, $88, $9A, $A6, $22, $45, $9A, $88, $9A, $87, $54, $58, $AA; 13:5AB0
    db $99, $88, $87, $55, $89, $AA, $98, $77, $65, $67, $89, $A9, $87, $77, $77, $77; 13:5AC0
    db $89, $98, $76, $67, $88, $89, $98, $88, $76, $77, $88, $88, $88, $77, $67, $78; 13:5AD0
    db $88, $88, $88, $77, $78, $AA, $53, $45, $89, $88, $8A, $A8, $65, $46, $88, $88; 13:5AE0
    db $99, $98, $65, $68, $88, $88, $89, $87, $66, $78, $88, $88, $88, $76, $67, $88; 13:5AF0
    db $88, $87, $77, $77, $88, $88, $88, $77, $77, $78, $88, $88, $87, $77, $77, $78; 13:5B00
    db $88, $88, $77, $77, $88, $9A, $96, $45, $66, $77, $78, $AA, $87, $66, $77, $77; 13:5B10
    db $8A, $A9, $87, $77, $76, $68, $9A, $98, $87, $77, $77, $78, $89, $88, $88, $77; 13:5B20
    db $77, $78, $88, $88, $88, $77, $78, $88, $88, $88, $77, $77, $77, $77, $78, $87; 13:5B30
    db $77, $78, $87, $77, $78, $88, $88, $89, $87, $66, $67, $77, $88, $88, $88, $77; 13:5B40
    db $77, $78, $88, $88, $88, $77, $77, $78, $88, $88, $88, $77, $77, $77, $88, $88; 13:5B50
    db $88, $88, $87, $78, $88, $88, $88, $87, $77, $88, $88, $88, $87, $77, $78, $77; 13:5B60
    db $88, $88, $88, $88, $77, $78, $88, $87, $88, $88, $88, $87, $77, $77, $88, $88; 13:5B70
    db $88, $88, $78, $88, $87, $77, $88, $78, $88, $88, $88, $88, $77, $77, $88, $88; 13:5B80
    db $88, $88, $77, $77, $88, $88, $87, $78, $88, $87, $88, $87, $78, $88, $77, $88; 13:5B90
    db $88, $77, $77, $77, $78, $88, $87, $77, $78, $77, $78, $88, $87, $88, $87, $88; 13:5BA0
    db $88, $88, $88, $77, $88, $88, $88, $88, $88, $88, $77, $88, $88, $78, $88, $88; 13:5BB0
    db $88, $88, $88, $88, $88, $88, $88, $78, $88, $88, $87, $88, $88, $77, $78, $77; 13:5BC0
    db $77, $67, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:5BD0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $78; 13:5BE0
    db $88, $88, $88, $78, $78, $88, $88, $87, $77, $77, $77, $77, $77, $77, $77, $77; 13:5BF0
    db $78, $88, $88, $88, $88, $88, $77, $88, $88, $77, $88, $88, $88, $77, $78, $88; 13:5C00
    db $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $78, $88, $88, $88, $88; 13:5C10
    db $88, $88, $88, $88, $88, $88, $88, $87, $77, $87, $88, $88, $88, $88, $88, $88; 13:5C20
    db $88, $77, $77, $77, $77, $78, $77, $87, $77, $77, $78, $78, $88, $88, $88, $77; 13:5C30
    db $87, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $87; 13:5C40
    db $77, $77, $78, $78, $88, $77, $77, $78, $78, $78, $77, $88, $78, $77, $77, $78; 13:5C50
    db $78, $78, $88, $88, $88, $88, $88, $88, $88, $88, $78, $88, $87, $88, $88, $88; 13:5C60
    db $88, $78, $88, $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $78, $78, $77; 13:5C70
    db $78, $88, $88, $88, $87, $77, $77, $87, $78, $88, $88, $88, $88, $88, $88, $88; 13:5C80
    db $88, $88, $88, $88, $88, $88, $88, $78, $88, $88, $88, $87, $88, $78, $88, $88; 13:5C90
    db $88, $88, $78, $88, $77, $78, $87, $88, $88, $88, $88, $88, $88, $78, $88, $88; 13:5CA0
    db $88, $87, $77, $77, $88, $88, $88, $88, $88, $78, $78, $87, $88, $88, $88, $88; 13:5CB0

;; PCM14: 3552 bytes = 7104 4-bit samples (rate 2) for SFXInst28
PCM14:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:5CC0
    db $88, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:5CD0
    db $88, $88, $88, $88, $88, $99, $98, $86, $56, $55, $44, $56, $77, $88, $99, $99; 13:5CE0
    db $88, $87, $76, $66, $77, $78, $89, $99, $99, $98, $87, $77, $88, $88, $99, $AA; 13:5CF0
    db $AA, $AA, $99, $99, $AB, $81, $23, $23, $11, $17, $97, $99, $BB, $B8, $46, $64; 13:5D00
    db $43, $46, $AA, $9B, $BC, $CA, $86, $86, $54, $35, $79, $89, $BB, $CA, $88, $88; 13:5D10
    db $66, $68, $99, $9A, $BC, $BA, $9A, $AA, $AB, $20, $41, $32, $23, $5F, $89, $A9; 13:5D20
    db $A9, $70, $26, $35, $55, $9C, $E9, $BB, $AA, $75, $36, $64, $66, $9B, $BA, $8A; 13:5D30
    db $98, $65, $67, $87, $89, $AB, $A9, $AB, $B9, $88, $9B, $DD, $00, $61, $51, $21; 13:5D40
    db $AF, $69, $8A, $A8, $50, $37, $55, $48, $BF, $E7, $9A, $A7, $42, $28, $86, $79; 13:5D50
    db $CC, $B8, $79, $86, $55, $79, $98, $8A, $BA, $99, $9A, $A9, $99, $BE, $F0, $05; 13:5D60
    db $14, $12, $2A, $F8, $88, $A8, $73, $01, $86, $56, $BD, $FF, $67, $88, $43, $24; 13:5D70
    db $AA, $88, $BC, $A8, $55, $88, $65, $8A, $AA, $88, $AA, $87, $8A, $A9, $9A, $BE; 13:5D80
    db $F5, $02, $23, $30, $46, $FE, $77, $99, $53, $00, $7A, $78, $BD, $FF, $72, $57; 13:5D90
    db $53, $35, $BD, $B8, $9B, $96, $44, $79, $87, $8A, $B9, $87, $9A, $98, $8A, $B9; 13:5DA0
    db $99, $CF, $F0, $05, $16, $13, $4C, $FA, $55, $96, $40, $00, $CD, $89, $CE, $EB; 13:5DB0
    db $20, $48, $54, $6A, $EE, $A5, $79, $74, $46, $AB, $97, $8A, $97, $67, $AB, $A8; 13:5DC0
    db $9B, $B9, $9A, $EF, $60, $04, $55, $16, $7F, $F5, $26, $84, $20, $09, $FB, $7A; 13:5DD0
    db $DC, $A4, $02, $99, $67, $BD, $DA, $54, $77, $54, $7B, $CA, $87, $89, $76, $8A; 13:5DE0
    db $BA, $88, $AA, $AA, $CF, $F0, $04, $26, $35, $7B, $FB, $33, $75, $20, $03, $EF; 13:5DF0
    db $98, $BC, $95, $10, $5A, $98, $AC, $CA, $84, $46, $66, $7B, $BB, $97, $78, $87; 13:5E00
    db $8A, $BA, $98, $89, $9A, $CE, $F4, $01, $45, $42, $99, $FF, $32, $66, $20, $03; 13:5E10
    db $CF, $A8, $9B, $84, $20, $5B, $A8, $AC, $C8, $74, $36, $67, $8B, $CA, $97, $67; 13:5E20
    db $87, $8B, $BA, $87, $89, $AA, $CF, $F0, $05, $26, $25, $AC, $FB, $12, $64, $10; 13:5E30
    db $25, $FF, $97, $9A, $52, $01, $7D, $CA, $BD, $B6, $43, $37, $88, $9B, $B9, $76; 13:5E40
    db $68, $99, $9A, $A9, $77, $89, $BB, $BD, $FC, $00, $33, $74, $9A, $FF, $70, $14; 13:5E50
    db $31, $14, $AF, $F8, $67, $73, $11, $4B, $FC, $AA, $B8, $42, $26, $99, $89, $BA; 13:5E60
    db $85, $57, $9A, $9A, $AA, $86, $68, $AB, $AA, $BD, $FB, $00, $45, $85, $9C, $FF; 13:5E70
    db $60, $04, $42, $37, $BF, $F7, $55, $63, $23, $6C, $FC, $99, $97, $32, $37, $BB; 13:5E80
    db $99, $A9, $64, $58, $BB, $99, $99, $76, $79, $AB, $A9, $9A, $AC, $E3, $00, $56; 13:5E90
    db $87, $AA, $ED, $20, $35, $44, $68, $CF, $B5, $56, $64, $56, $8D, $D9, $88, $86; 13:5EA0
    db $54, $57, $AA, $98, $88, $76, $78, $AA, $98, $88, $77, $89, $AA, $AA, $98, $88; 13:5EB0
    db $BE, $80, $05, $68, $66, $9B, $E6, $12, $56, $65, $69, $EC, $76, $77, $75, $56; 13:5EC0
    db $AC, $A8, $88, $87, $54, $69, $A9, $78, $98, $75, $58, $99, $88, $99, $87, $78; 13:5ED0
    db $AB, $A9, $99, $87, $67, $9C, $B6, $03, $55, $55, $78, $BA, $65, $67, $54, $45; 13:5EE0
    db $9B, $A9, $99, $97, $54, $58, $99, $9A, $A9, $86, $55, $67, $89, $AA, $88, $66; 13:5EF0
    db $66, $78, $9A, $AA, $98, $77, $78, $89, $99, $99, $88, $79, $99, $50, $47, $66; 13:5F00
    db $56, $8B, $A6, $67, $86, $54, $58, $A9, $88, $AA, $87, $55, $78, $77, $9B, $BA; 13:5F10
    db $86, $77, $65, $67, $99, $98, $89, $86, $66, $78, $88, $9A, $A9, $87, $88, $88; 13:5F20
    db $78, $88, $87, $88, $98, $44, $66, $75, $56, $8A, $87, $88, $97, $54, $58, $77; 13:5F30
    db $89, $AA, $A8, $78, $76, $56, $78, $99, $89, $99, $76, $67, $77, $77, $78, $88; 13:5F40
    db $88, $88, $87, $78, $88, $88, $89, $88, $89, $98, $88, $88, $77, $88, $76, $77; 13:5F50
    db $76, $66, $67, $77, $78, $88, $88, $78, $88, $88, $88, $88, $77, $88, $88, $88; 13:5F60
    db $88, $77, $77, $77, $78, $88, $88, $88, $87, $77, $88, $88, $88, $87, $77, $77; 13:5F70
    db $87, $78, $88, $77, $88, $88, $88, $88, $88, $88, $88, $77, $88, $77, $77, $77; 13:5F80
    db $66, $67, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:5F90
    db $77, $77, $78, $88, $88, $77, $77, $77, $77, $88, $88, $78, $88, $87, $88, $88; 13:5FA0
    db $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $66, $77, $77, $77; 13:5FB0
    db $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77; 13:5FC0
    db $88, $88, $88, $88, $77, $78, $88, $88, $88, $77, $77, $88, $88, $88, $88, $88; 13:5FD0
    db $88, $88, $88, $88, $87, $77, $88, $77, $87, $77, $77, $77, $77, $77, $77, $77; 13:5FE0
    db $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77; 13:5FF0
    db $88, $77, $88, $87, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:6000
    db $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $77, $77, $77, $88, $88; 13:6010
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77; 13:6020
    db $78, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:6030
    db $88, $87, $77, $67, $67, $76, $66, $67, $77, $77, $78, $88, $88, $88, $88, $88; 13:6040
    db $88, $88, $88, $88, $88, $88, $87, $88, $77, $77, $88, $88, $88, $88, $88, $88; 13:6050
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $78, $89, $87, $77; 13:6060
    db $56, $66, $55, $65, $67, $88, $88, $88, $89, $98, $88, $88, $88, $87, $77, $88; 13:6070
    db $88, $88, $88, $88, $88, $88, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:6080
    db $88, $88, $88, $78, $88, $88, $87, $77, $78, $88, $88, $66, $65, $66, $65, $45; 13:6090
    db $56, $88, $88, $89, $99, $A9, $88, $77, $88, $87, $77, $78, $88, $88, $88, $88; 13:60A0
    db $88, $87, $77, $78, $77, $88, $88, $88, $88, $88, $88, $88, $78, $88, $88, $78; 13:60B0
    db $77, $88, $87, $77, $77, $77, $88, $98, $56, $55, $76, $65, $46, $67, $98, $88; 13:60C0
    db $99, $9A, $A8, $88, $78, $87, $76, $88, $88, $88, $88, $98, $88, $88, $88, $87; 13:60D0
    db $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $78, $87, $88, $88, $88, $77; 13:60E0
    db $87, $77, $77, $88, $89, $75, $76, $67, $55, $45, $76, $78, $78, $89, $A9, $98; 13:60F0
    db $89, $98, $87, $77, $78, $77, $88, $88, $98, $88, $88, $88, $87, $78, $77, $87; 13:6100
    db $88, $88, $88, $88, $88, $88, $88, $88, $87, $88, $88, $88, $78, $87, $87, $77; 13:6110
    db $77, $77, $88, $86, $67, $56, $65, $54, $66, $68, $67, $88, $98, $99, $89, $99; 13:6120
    db $88, $88, $88, $77, $78, $88, $87, $88, $88, $88, $88, $88, $78, $88, $88, $88; 13:6130
    db $88, $88, $88, $88, $88, $88, $88, $88, $77, $87, $77, $77, $77, $77, $77, $77; 13:6140
    db $77, $88, $86, $77, $67, $66, $55, $76, $66, $67, $78, $88, $99, $99, $99, $89; 13:6150
    db $88, $88, $77, $78, $78, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:6160
    db $88, $88, $88, $88, $88, $88, $87, $77, $87, $77, $77, $77, $77, $77, $77, $77; 13:6170
    db $78, $88, $77, $77, $77, $76, $66, $66, $66, $77, $88, $88, $88, $99, $98, $88; 13:6180
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $88, $88; 13:6190
    db $88, $88, $88, $78, $87, $87, $87, $87, $87, $77, $87, $87, $77, $77, $77, $77; 13:61A0
    db $77, $88, $88, $87, $77, $77, $77, $66, $77, $77, $77, $78, $88, $88, $88, $88; 13:61B0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $88, $78, $88; 13:61C0
    db $88, $87, $87, $87, $87, $87, $87, $87, $87, $78, $77, $77, $77, $77, $77, $77; 13:61D0
    db $77, $77, $87, $87, $88, $87, $87, $87, $77, $77, $77, $77, $77, $88, $78, $88; 13:61E0
    db $88, $88, $88, $88, $88, $88, $88, $88, $87, $88, $88, $88, $88, $88, $88, $78; 13:61F0
    db $78, $77, $87, $87, $87, $87, $87, $88, $78, $78, $77, $77, $87, $77, $77, $77; 13:6200
    db $87, $87, $88, $78, $87, $88, $87, $78, $77, $77, $77, $77, $77, $78, $78, $78; 13:6210
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $87; 13:6220
    db $88, $88, $88, $88, $88, $88, $88, $87, $88, $78, $88, $87, $88, $77, $77, $77; 13:6230
    db $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $87, $78; 13:6240
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:6250
    db $87, $87, $87, $77, $77, $77, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77; 13:6260
    db $77, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88, $87, $77, $77, $77, $77; 13:6270
    db $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:6280
    db $88, $77, $77, $77, $77, $77, $77, $77, $78, $88, $88, $87, $88, $77, $87, $77; 13:6290
    db $77, $77, $77, $77, $77, $88, $88, $78, $88, $88, $88, $88, $88, $87, $77, $77; 13:62A0
    db $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:62B0
    db $88, $88, $88, $77, $77, $77, $77, $77, $78, $78, $88, $88, $88, $88, $88, $88; 13:62C0
    db $88, $88, $88, $88, $88, $88, $88, $77, $87, $77, $87, $77, $87, $87, $78, $77; 13:62D0
    db $77, $77, $77, $77, $77, $78, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:62E0
    db $88, $88, $88, $88, $87, $88, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88; 13:62F0
    db $88, $88, $88, $88, $88, $77, $77, $78, $78, $87, $77, $77, $77, $87, $87, $88; 13:6300
    db $78, $87, $77, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88; 13:6310
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $88, $88, $88, $88, $88; 13:6320
    db $88, $88, $78, $77, $77, $87, $77, $87, $77, $77, $77, $77, $77, $77, $77, $77; 13:6330
    db $88, $78, $87, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88; 13:6340
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $77; 13:6350
    db $78, $87, $78, $88, $88, $88, $88, $88, $88, $78, $88, $88, $88, $88, $88, $88; 13:6360
    db $87, $77, $77, $67, $76, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $88; 13:6370
    db $88, $88, $88, $78, $87, $88, $87, $88, $78, $88, $88, $88, $88, $88, $88, $87; 13:6380
    db $88, $88, $88, $78, $87, $88, $86, $78, $76, $76, $66, $56, $56, $65, $67, $67; 13:6390
    db $88, $88, $99, $99, $99, $A9, $99, $99, $88, $88, $87, $77, $77, $77, $77, $78; 13:63A0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $88, $88, $87, $78; 13:63B0
    db $75, $66, $65, $55, $55, $54, $66, $56, $77, $88, $89, $99, $9A, $AA, $AA, $A9; 13:63C0
    db $98, $88, $87, $77, $77, $67, $76, $77, $77, $78, $88, $89, $99, $99, $99, $88; 13:63D0
    db $88, $88, $88, $87, $88, $86, $79, $56, $75, $65, $45, $55, $34, $65, $56, $78; 13:63E0
    db $88, $89, $A9, $9B, $AA, $AA, $A9, $99, $89, $77, $87, $76, $67, $66, $77, $87; 13:63F0
    db $78, $89, $99, $A9, $99, $99, $88, $98, $88, $88, $88, $85, $7A, $45, $74, $63; 13:6400
    db $44, $35, $34, $75, $57, $88, $78, $99, $B9, $AB, $A9, $9A, $A8, $88, $88, $76; 13:6410
    db $76, $66, $67, $66, $78, $88, $89, $99, $9A, $A9, $9A, $99, $89, $99, $88, $9A; 13:6420
    db $75, $B7, $36, $56, $32, $42, $54, $15, $75, $57, $A8, $7A, $AB, $B9, $AB, $A9; 13:6430
    db $8A, $97, $77, $76, $56, $66, $65, $78, $77, $89, $98, $9A, $A9, $9A, $A9, $99; 13:6440
    db $99, $89, $AA, $A8, $5B, $93, $55, $72, $05, $33, $32, $56, $55, $6A, $A7, $9B; 13:6450
    db $BA, $9B, $B9, $98, $99, $76, $67, $75, $57, $76, $68, $88, $89, $9A, $99, $AA; 13:6460
    db $A9, $9A, $99, $9A, $A9, $AB, $94, $AA, $43, $48, $30, $34, $32, $25, $56, $76; 13:6470
    db $8B, $A9, $9C, $C9, $9B, $A9, $78, $87, $65, $56, $65, $56, $87, $78, $99, $89; 13:6480
    db $AA, $99, $9A, $99, $99, $99, $9A, $BC, $A4, $9B, $63, $28, $50, $23, $43, $24; 13:6490
    db $56, $97, $79, $BB, $89, $CB, $98, $9A, $87, $76, $66, $55, $57, $76, $78, $98; 13:64A0
    db $8A, $A9, $99, $A9, $99, $89, $99, $99, $AB, $BB, $57, $B8, $51, $56, $21, $13; 13:64B0
    db $43, $45, $59, $98, $89, $DB, $99, $BB, $98, $87, $77, $65, $56, $75, $57, $88; 13:64C0
    db $78, $98, $AA, $99, $9A, $98, $99, $99, $99, $9A, $BB, $B6, $7A, $86, $24, $52; 13:64D0
    db $22, $23, $46, $55, $79, $A9, $9B, $BA, $BA, $99, $99, $76, $77, $75, $56, $67; 13:64E0
    db $77, $78, $99, $88, $99, $98, $98, $89, $88, $89, $A9, $AA, $BC, $86, $98, $74; 13:64F0
    db $34, $23, $32, $23, $56, $56, $89, $A9, $AA, $9B, $BA, $87, $98, $77, $66, $66; 13:6500
    db $76, $68, $88, $89, $98, $99, $98, $89, $88, $88, $88, $99, $99, $AB, $BB, $76; 13:6510
    db $88, $73, $33, $23, $32, $23, $67, $67, $89, $AA, $BA, $9A, $A9, $88, $87, $77; 13:6520
    db $66, $67, $87, $78, $88, $99, $88, $99, $98, $88, $88, $98, $88, $99, $9A, $AA; 13:6530
    db $BC, $A6, $77, $75, $23, $22, $43, $32, $57, $77, $89, $9A, $BB, $99, $A9, $87; 13:6540
    db $77, $67, $76, $66, $87, $88, $88, $99, $98, $88, $88, $88, $88, $99, $88, $99; 13:6550
    db $A9, $AA, $AB, $BB, $75, $76, $64, $33, $13, $43, $34, $67, $88, $98, $AB, $BA; 13:6560
    db $89, $98, $88, $66, $78, $75, $67, $78, $88, $88, $A9, $88, $88, $88, $87, $78; 13:6570
    db $88, $89, $99, $9A, $99, $AA, $AB, $A7, $56, $75, $42, $32, $24, $42, $36, $87; 13:6580
    db $88, $9A, $BB, $A8, $9A, $98, $87, $77, $77, $56, $78, $77, $88, $89, $99, $88; 13:6590
    db $99, $88, $88, $88, $98, $89, $98, $88, $98, $88, $88, $88, $86, $56, $76, $55; 13:65A0
    db $66, $55, $56, $66, $67, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:65B0
    db $88, $88, $88, $88, $88, $78, $87, $77, $77, $78, $88, $88, $88, $88, $88, $88; 13:65C0
    db $88, $78, $77, $77, $77, $77, $77, $77, $77, $77, $76, $66, $66, $66, $66, $67; 13:65D0
    db $77, $77, $88, $88, $99, $99, $99, $99, $99, $98, $88, $88, $88, $77, $77, $77; 13:65E0
    db $77, $87, $78, $88, $77, $88, $88, $88, $88, $88, $88, $98, $77, $88, $76, $65; 13:65F0
    db $55, $65, $55, $77, $77, $78, $99, $88, $88, $99, $88, $88, $88, $88, $88, $88; 13:6600
    db $87, $78, $87, $77, $78, $87, $78, $88, $88, $88, $88, $88, $99, $98, $88, $89; 13:6610
    db $88, $89, $98, $55, $76, $54, $33, $45, $54, $47, $88, $98, $89, $AA, $98, $89; 13:6620
    db $88, $87, $77, $88, $77, $88, $88, $88, $88, $88, $77, $77, $78, $77, $88, $98; 13:6630
    db $89, $99, $98, $88, $88, $88, $88, $88, $89, $9A, $A7, $46, $64, $43, $32, $36; 13:6640
    db $55, $68, $9A, $AA, $A8, $AA, $87, $77, $77, $77, $57, $88, $88, $99, $99, $98; 13:6650
    db $88, $87, $77, $76, $78, $88, $88, $99, $99, $88, $88, $88, $88, $88, $88, $88; 13:6660
    db $88, $89, $99, $96, $45, $55, $53, $32, $46, $66, $67, $89, $9A, $98, $88, $88; 13:6670
    db $77, $67, $88, $88, $89, $99, $99, $88, $87, $77, $76, $78, $88, $88, $99, $99; 13:6680
    db $88, $88, $88, $87, $78, $88, $88, $88, $88, $88, $88, $88, $89, $98, $65, $55; 13:6690
    db $55, $44, $34, $56, $77, $78, $8A, $A9, $98, $88, $88, $87, $77, $88, $88, $88; 13:66A0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $78, $88; 13:66B0
    db $77, $88, $88, $88, $88, $88, $88, $88, $77, $88, $88, $76, $55, $55, $56, $55; 13:66C0
    db $66, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:66D0
    db $88, $88, $88, $88, $88, $87, $78, $77, $78, $88, $88, $88, $88, $87, $78, $77; 13:66E0
    db $88, $87, $87, $77, $77, $77, $77, $77, $77, $77, $78, $88, $87, $77, $77, $77; 13:66F0
    db $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:6700
    db $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $77, $78, $88; 13:6710
    db $87, $78, $88, $77, $77, $78, $87, $88, $88, $88, $88, $88, $88, $88, $88, $77; 13:6720
    db $87, $87, $78, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:6730
    db $88, $88, $88, $87, $77, $77, $78, $88, $88, $88, $88, $87, $78, $88, $88, $88; 13:6740
    db $88, $88, $88, $88, $88, $88, $78, $87, $88, $87, $77, $77, $77, $88, $88, $88; 13:6750
    db $88, $88, $88, $88, $87, $77, $77, $78, $88, $88, $88, $88, $78, $77, $77, $77; 13:6760
    db $77, $77, $88, $88, $88, $88, $88, $88, $88, $87, $78, $88, $88, $88, $88, $88; 13:6770
    db $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $88; 13:6780
    db $88, $77, $88, $77, $88, $77, $78, $77, $77, $88, $78, $87, $77, $77, $77, $77; 13:6790
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $77, $78, $87, $88, $88; 13:67A0
    db $88, $88, $88, $88, $88, $88, $77, $88, $78, $88, $87, $78, $88, $88, $77, $88; 13:67B0
    db $87, $78, $77, $77, $77, $77, $78, $88, $88, $78, $88, $88, $88, $88, $88, $88; 13:67C0
    db $88, $88, $88, $88, $88, $87, $78, $88, $88, $88, $87, $88, $88, $88, $88, $88; 13:67D0
    db $88, $88, $88, $88, $88, $87, $77, $77, $87, $87, $77, $88, $87, $78, $88, $88; 13:67E0
    db $78, $78, $88, $78, $88, $88, $88, $88, $88, $88, $77, $87, $77, $78, $88, $77; 13:67F0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $88, $78; 13:6800
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:6810
    db $88, $88, $88, $87, $88, $77, $87, $78, $77, $77, $78, $88, $88, $78, $88, $88; 13:6820
    db $87, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:6830
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:6840
    db $88, $87, $77, $77, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88; 13:6850
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:6860
    db $88, $88, $87, $77, $77, $77, $78, $88, $88, $76, $65, $55, $67, $77, $77, $78; 13:6870
    db $88, $88, $88, $77, $77, $88, $88, $88, $88, $88, $88, $88, $87, $77, $88, $88; 13:6880
    db $87, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:6890
    db $88, $88, $88, $88, $88, $88, $88, $88, $76, $55, $55, $66, $78, $88, $88, $88; 13:68A0
    db $99, $98, $87, $76, $77, $88, $88, $88, $88, $88, $88, $88, $77, $77, $88, $88; 13:68B0
    db $88, $88, $88, $88, $88, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:68C0
    db $87, $77, $88, $78, $77, $78, $88, $89, $87, $75, $55, $55, $67, $88, $88, $88; 13:68D0
    db $88, $99, $88, $76, $67, $78, $89, $88, $88, $88, $88, $88, $87, $77, $77, $88; 13:68E0
    db $88, $88, $88, $88, $88, $87, $77, $77, $88, $88, $88, $88, $88, $88, $88, $87; 13:68F0
    db $77, $77, $88, $88, $77, $77, $78, $88, $88, $77, $55, $55, $67, $78, $88, $88; 13:6900
    db $88, $89, $98, $87, $66, $67, $78, $89, $98, $88, $88, $88, $88, $87, $77, $77; 13:6910
    db $88, $88, $88, $88, $77, $87, $77, $77, $78, $88, $88, $88, $88, $88, $88, $87; 13:6920
    db $77, $77, $77, $88, $88, $87, $77, $88, $88, $87, $65, $55, $56, $77, $88, $88; 13:6930
    db $88, $89, $99, $88, $77, $66, $77, $88, $99, $98, $88, $88, $88, $88, $77, $77; 13:6940
    db $77, $88, $88, $88, $77, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88; 13:6950
    db $88, $77, $77, $78, $88, $88, $77, $77, $78, $88, $88, $87, $76, $55, $55, $67; 13:6960
    db $88, $88, $88, $88, $99, $88, $87, $76, $67, $78, $89, $99, $98, $88, $88, $88; 13:6970
    db $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:6980
    db $77, $77, $78, $77, $77, $77, $88, $88, $77, $77, $77, $77, $88, $88, $87, $65; 13:6990
    db $55, $66, $77, $88, $88, $88, $99, $99, $88, $77, $76, $77, $88, $99, $99, $88; 13:69A0
    db $88, $88, $87, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:69B0
    db $88, $88, $88, $87, $77, $77, $78, $88, $88, $88, $77, $77, $77, $77, $78, $88; 13:69C0
    db $88, $88, $76, $66, $56, $67, $78, $88, $88, $88, $99, $88, $87, $77, $77, $88; 13:69D0
    db $89, $99, $98, $88, $88, $87, $77, $77, $77, $78, $88, $88, $88, $88, $87, $88; 13:69E0
    db $77, $77, $88, $88, $88, $88, $77, $77, $88, $88, $87, $87, $88, $87, $77, $77; 13:69F0
    db $77, $77, $78, $88, $88, $88, $87, $76, $66, $66, $77, $88, $88, $88, $88, $88; 13:6A00
    db $88, $87, $77, $78, $88, $88, $88, $88, $88, $88, $77, $77, $77, $88, $88, $88; 13:6A10
    db $88, $88, $88, $88, $77, $77, $88, $88, $88, $88, $87, $88, $88, $87, $77, $77; 13:6A20
    db $78, $78, $87, $77, $77, $77, $88, $77, $88, $88, $88, $88, $77, $77, $77, $77; 13:6A30
    db $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87; 13:6A40
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $77, $88; 13:6A50
    db $88, $88, $87, $77, $77, $77, $77, $77, $77, $78, $78, $88, $88, $88, $88, $88; 13:6A60
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:6A70
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $77, $77, $77, $77; 13:6A80
    db $77, $77, $78, $88, $88, $88, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88; 13:6A90

;; PCM15: 3392 bytes = 6784 4-bit samples (rate 2) for SFXInst29
PCM15:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:6AA0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:6AB0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:6AC0
    db $88, $88, $88, $88, $87, $88, $87, $87, $88, $88, $88, $78, $88, $87, $78, $88; 13:6AD0
    db $78, $78, $87, $78, $77, $78, $88, $88, $88, $87, $88, $87, $78, $77, $87, $78; 13:6AE0
    db $77, $78, $77, $77, $87, $77, $78, $77, $88, $88, $87, $88, $88, $88, $87, $87; 13:6AF0
    db $87, $87, $88, $78, $78, $77, $88, $77, $87, $78, $77, $78, $77, $88, $78, $88; 13:6B00
    db $88, $88, $88, $88, $98, $88, $88, $88, $88, $88, $77, $87, $66, $66, $55, $55; 13:6B10
    db $66, $66, $77, $78, $89, $99, $AA, $AA, $AA, $AA, $BB, $A9, $89, $86, $67, $64; 13:6B20
    db $44, $44, $44, $46, $66, $78, $98, $89, $99, $89, $98, $88, $88, $88, $89, $AA; 13:6B30
    db $AB, $A9, $AA, $87, $77, $65, $55, $44, $44, $45, $55, $67, $87, $89, $88, $89; 13:6B40
    db $98, $98, $99, $99, $AA, $BB, $B9, $AB, $97, $78, $75, $44, $43, $33, $44, $55; 13:6B50
    db $57, $88, $88, $A9, $89, $99, $88, $99, $99, $9A, $BB, $B9, $AB, $B8, $78, $86; 13:6B60
    db $45, $54, $33, $44, $55, $56, $88, $77, $99, $88, $99, $98, $98, $99, $9A, $BC; 13:6B70
    db $B9, $9B, $B8, $68, $86, $44, $43, $33, $34, $56, $55, $88, $88, $9A, $99, $89; 13:6B80
    db $89, $98, $89, $AA, $AC, $B9, $AB, $B8, $78, $75, $44, $43, $44, $33, $56, $55; 13:6B90
    db $78, $88, $99, $99, $98, $89, $98, $89, $AA, $AC, $B9, $AB, $A7, $78, $75, $44; 13:6BA0
    db $43, $44, $33, $56, $56, $89, $88, $A9, $9A, $98, $89, $98, $89, $AA, $BC, $A9; 13:6BB0
    db $AB, $A7, $78, $75, $54, $33, $43, $23, $56, $56, $88, $89, $98, $9A, $98, $89; 13:6BC0
    db $98, $99, $AA, $BC, $A9, $AB, $A7, $77, $65, $53, $23, $53, $23, $55, $67, $78; 13:6BD0
    db $9A, $98, $9A, $98, $89, $89, $99, $9A, $CC, $B9, $AB, $B9, $77, $66, $54, $33; 13:6BE0
    db $44, $33, $45, $67, $77, $89, $98, $89, $99, $88, $88, $99, $99, $BB, $B9, $9A; 13:6BF0
    db $A9, $77, $66, $65, $32, $45, $44, $45, $67, $87, $89, $99, $89, $99, $99, $88; 13:6C00
    db $99, $99, $AB, $BB, $98, $9A, $97, $76, $66, $54, $34, $54, $44, $55, $78, $77; 13:6C10
    db $89, $98, $98, $89, $98, $89, $99, $99, $99, $A9, $88, $89, $88, $76, $77, $65; 13:6C20
    db $56, $66, $66, $66, $77, $77, $78, $78, $88, $88, $88, $88, $88, $88, $88, $88; 13:6C30
    db $88, $99, $99, $99, $88, $88, $77, $77, $66, $66, $66, $66, $66, $66, $77, $77; 13:6C40
    db $78, $88, $88, $88, $88, $88, $89, $99, $9A, $99, $99, $99, $98, $88, $77, $76; 13:6C50
    db $66, $66, $66, $66, $66, $66, $66, $77, $77, $78, $88, $88, $88, $88, $99, $99; 13:6C60
    db $99, $99, $99, $99, $99, $98, $88, $87, $76, $66, $66, $66, $66, $66, $66, $66; 13:6C70
    db $77, $77, $88, $88, $88, $88, $88, $88, $88, $89, $99, $99, $99, $99, $99, $88; 13:6C80
    db $87, $76, $66, $66, $65, $56, $66, $66, $66, $77, $77, $78, $88, $88, $88, $88; 13:6C90
    db $89, $88, $88, $89, $99, $98, $89, $99, $88, $77, $87, $65, $66, $67, $66, $67; 13:6CA0
    db $76, $76, $67, $87, $78, $88, $88, $88, $98, $78, $88, $89, $9A, $AB, $BC, $B7; 13:6CB0
    db $89, $97, $66, $45, $64, $33, $65, $67, $67, $8A, $88, $98, $88, $87, $67, $55; 13:6CC0
    db $57, $67, $98, $99, $A9, $AC, $CE, $FF, $C7, $A9, $84, $31, $04, $20, $04, $76; 13:6CD0
    db $A8, $9B, $EC, $7A, $98, $75, $30, $43, $23, $58, $8C, $BA, $DE, $ED, $FF, $FF; 13:6CE0
    db $D3, $48, $50, $00, $04, $51, $18, $EA, $DB, $BC, $FB, $25, $65, $32, $00, $67; 13:6CF0
    db $46, $BD, $CF, $BA, $EF, $DA, $FF, $FB, $14, $47, $00, $00, $75, $42, $9F, $CD; 13:6D00
    db $8A, $AC, $80, $32, $62, $21, $2B, $99, $7C, $EC, $C7, $AB, $DB, $9F, $FF, $72; 13:6D10
    db $66, $80, $00, $19, $44, $2E, $DE, $C6, $AA, $D2, $03, $47, $24, $09, $EA, $88; 13:6D20
    db $EB, $B8, $48, $BC, $7B, $FF, $F9, $16, $88, $00, $00, $A5, $31, $FF, $EB, $69; 13:6D30
    db $9D, $00, $15, $63, $53, $BF, $C8, $8E, $A9, $52, $69, $A6, $AF, $FF, $F7, $0A; 13:6D40
    db $82, $00, $02, $B4, $38, $FF, $CB, $78, $87, $00, $36, $55, $88, $FF, $B7, $9B; 13:6D50
    db $64, $22, $59, $87, $DF, $FF, $FF, $70, $50, $00, $00, $2E, $9B, $CF, $FD, $B3; 13:6D60
    db $11, $20, $04, $7A, $CF, $DE, $FB, $65, $41, $13, $36, $AC, $CE, $FF, $FF, $FF; 13:6D70
    db $F0, $00, $00, $01, $0D, $FE, $AB, $FC, $50, $00, $23, $00, $DF, $FD, $EC, $B8; 13:6D80
    db $10, $14, $45, $8B, $FE, $CA, $BC, $BA, $AC, $EF, $F0, $05, $42, $03, $0C, $FA; 13:6D90
    db $79, $FB, $41, $00, $55, $01, $EF, $EB, $B9, $BA, $00, $38, $76, $9A, $ED, $85; 13:6DA0
    db $8B, $99, $BD, $FF, $FF, $50, $20, $00, $02, $8F, $EC, $BF, $D3, $00, $02, $20; 13:6DB0
    db $2F, $FF, $EC, $B9, $90, $02, $66, $5A, $BE, $F9, $57, $B8, $68, $9B, $DC, $CF; 13:6DC0
    db $F7, $00, $13, $00, $28, $FF, $96, $FA, $00, $00, $58, $44, $FF, $FF, $95, $58; 13:6DD0
    db $00, $18, $BB, $CB, $DE, $83, $37, $77, $88, $CD, $CB, $EF, $FF, $F0, $02, $10; 13:6DE0
    db $06, $3F, $FB, $58, $F4, $00, $02, $9A, $7B, $FF, $D8, $43, $44, $00, $8C, $CB; 13:6DF0
    db $C9, $A8, $32, $58, $89, $BB, $BA, $88, $BC, $CC, $DF, $F1, $00, $05, $03, $3C; 13:6E00
    db $FF, $85, $D9, $10, $00, $8A, $85, $FF, $EA, $53, $47, $20, $5C, $CA, $A9, $9A; 13:6E10
    db $62, $48, $98, $8A, $AB, $97, $9B, $BA, $BB, $CE, $FF, $00, $20, $20, $84, $FF; 13:6E20
    db $C8, $9E, $50, $00, $18, $87, $9F, $FD, $95, $44, $20, $08, $BC, $CD, $DC, $95; 13:6E30
    db $24, $56, $68, $BB, $B9, $8A, $B9, $89, $AB, $A9, $BF, $F4, $02, $26, $02, $48; 13:6E40
    db $FC, $64, $CB, $00, $00, $99, $85, $FF, $C9, $54, $66, $30, $6C, $CB, $BC, $BB; 13:6E50
    db $62, $46, $65, $7A, $AB, $A8, $9A, $97, $8A, $99, $78, $9B, $BD, $FC, $01, $42; 13:6E60
    db $00, $62, $FE, $79, $CE, $42, $20, $55, $23, $AF, $AC, $BA, $B8, $50, $47, $56; 13:6E70
    db $8B, $CD, $B7, $99, $64, $46, $78, $88, $AB, $A8, $89, $89, $88, $9A, $A9, $AA; 13:6E80
    db $BE, $F4, $05, $42, $00, $45, $F7, $5A, $DC, $55, $22, $72, $04, $AB, $9C, $BC; 13:6E90
    db $EB, $65, $85, $34, $57, $9A, $9A, $BA, $88, $87, $66, $67, $88, $79, $AA, $99; 13:6EA0
    db $9A, $A8, $78, $87, $77, $79, $AB, $D7, $28, $54, $10, $22, $74, $59, $BC, $9A; 13:6EB0
    db $88, $96, $44, $66, $57, $79, $BA, $AA, $B9, $88, $77, $77, $88, $88, $88, $76; 13:6EC0
    db $66, $67, $77, $89, $9A, $99, $99, $87, $77, $88, $88, $88, $88, $87, $66, $66; 13:6ED0
    db $67, $78, $89, $88, $88, $76, $66, $66, $66, $67, $77, $77, $67, $77, $78, $88; 13:6EE0
    db $88, $89, $99, $88, $99, $99, $99, $98, $77, $77, $77, $78, $88, $87, $88, $77; 13:6EF0
    db $77, $88, $88, $99, $88, $77, $77, $66, $67, $77, $88, $88, $88, $87, $77, $77; 13:6F00
    db $77, $77, $78, $88, $88, $88, $87, $77, $77, $77, $78, $88, $88, $88, $88, $88; 13:6F10
    db $88, $88, $88, $77, $77, $78, $88, $88, $88, $88, $78, $77, $78, $88, $88, $88; 13:6F20
    db $88, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $87, $88, $87, $77, $77; 13:6F30
    db $77, $88, $77, $78, $88, $88, $88, $87, $78, $77, $77, $88, $88, $88, $77, $77; 13:6F40
    db $88, $88, $88, $88, $88, $88, $77, $77, $88, $88, $78, $87, $78, $88, $88, $88; 13:6F50
    db $87, $77, $88, $88, $88, $88, $77, $77, $77, $78, $88, $88, $88, $78, $88, $88; 13:6F60
    db $88, $88, $88, $88, $78, $88, $88, $88, $87, $77, $77, $78, $78, $88, $88, $88; 13:6F70
    db $78, $87, $88, $88, $88, $88, $88, $77, $77, $77, $78, $88, $88, $88, $88, $77; 13:6F80
    db $78, $77, $88, $88, $88, $78, $87, $78, $78, $88, $88, $88, $87, $77, $77, $78; 13:6F90
    db $78, $88, $88, $88, $87, $77, $88, $88, $88, $88, $77, $77, $77, $88, $88, $88; 13:6FA0
    db $88, $77, $78, $88, $78, $88, $77, $78, $88, $78, $88, $87, $78, $88, $88, $88; 13:6FB0
    db $88, $88, $88, $88, $78, $88, $88, $88, $78, $77, $78, $88, $88, $88, $77, $77; 13:6FC0
    db $77, $78, $88, $88, $88, $77, $77, $78, $88, $88, $88, $77, $77, $77, $78, $88; 13:6FD0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $78, $77, $88, $88; 13:6FE0
    db $88, $87, $77, $77, $77, $88, $88, $78, $77, $77, $88, $88, $88, $88, $87, $77; 13:6FF0
    db $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $78; 13:7000
    db $77, $77, $67, $88, $88, $88, $87, $87, $77, $76, $88, $88, $88, $88, $78, $88; 13:7010
    db $78, $77, $78, $78, $87, $88, $88, $88, $78, $88, $88, $77, $87, $87, $87, $77; 13:7020
    db $77, $78, $78, $78, $88, $88, $88, $78, $68, $78, $77, $87, $88, $78, $78, $78; 13:7030
    db $78, $78, $88, $86, $87, $88, $78, $78, $87, $88, $87, $79, $69, $78, $97, $97; 13:7040
    db $8A, $69, $78, $86, $97, $79, $68, $78, $85, $97, $78, $87, $78, $86, $88, $77; 13:7050
    db $87, $88, $87, $79, $88, $78, $77, $88, $78, $88, $78, $88, $87, $88, $87, $78; 13:7060
    db $87, $78, $87, $87, $77, $88, $77, $87, $78, $87, $78, $88, $78, $87, $78, $87; 13:7070
    db $77, $88, $88, $87, $88, $77, $78, $87, $77, $88, $78, $77, $88, $87, $88, $88; 13:7080
    db $78, $88, $87, $78, $88, $78, $88, $88, $87, $88, $88, $88, $87, $88, $88, $87; 13:7090
    db $78, $88, $77, $78, $88, $77, $77, $78, $88, $77, $88, $77, $78, $88, $78, $78; 13:70A0
    db $87, $87, $77, $88, $77, $78, $87, $77, $78, $87, $77, $88, $77, $77, $78, $88; 13:70B0
    db $77, $88, $87, $77, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:70C0
    db $87, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $88, $88, $77; 13:70D0
    db $88, $88, $77, $77, $78, $88, $77, $87, $88, $88, $78, $88, $87, $77, $78, $78; 13:70E0
    db $88, $87, $77, $88, $88, $88, $77, $77, $88, $77, $77, $78, $88, $77, $77, $78; 13:70F0
    db $87, $77, $78, $88, $77, $77, $77, $77, $77, $77, $77, $88, $77, $77, $88, $88; 13:7100
    db $77, $78, $88, $87, $77, $78, $88, $87, $77, $88, $88, $88, $88, $88, $88, $88; 13:7110
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $88, $88, $88, $88; 13:7120
    db $88, $88, $88, $88, $78, $88, $87, $77, $88, $77, $87, $78, $88, $77, $78, $88; 13:7130
    db $87, $77, $77, $87, $77, $77, $88, $88, $87, $77, $77, $87, $77, $87, $77, $77; 13:7140
    db $78, $77, $88, $87, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:7150
    db $88, $88, $88, $88, $88, $87, $76, $65, $55, $56, $67, $77, $77, $77, $77, $77; 13:7160
    db $77, $88, $89, $99, $88, $99, $99, $99, $99, $98, $99, $89, $99, $99, $99, $AA; 13:7170
    db $B9, $87, $53, $21, $12, $34, $67, $88, $88, $88, $99, $9A, $98, $77, $65, $67; 13:7180
    db $79, $9A, $A9, $87, $77, $78, $88, $88, $88, $89, $99, $99, $99, $99, $AA, $BC; 13:7190
    db $CA, $97, $42, $00, $00, $24, $68, $89, $98, $89, $99, $AA, $98, $76, $54, $45; 13:71A0
    db $68, $9A, $BB, $A9, $87, $67, $77, $88, $88, $99, $99, $AA, $AA, $AA, $AA, $BC; 13:71B0
    db $CA, $96, $21, $00, $01, $35, $7A, $AA, $A8, $89, $98, $99, $87, $65, $34, $44; 13:71C0
    db $79, $AB, $CC, $A9, $87, $77, $66, $77, $88, $99, $AB, $AA, $AA, $9A, $BB, $CD; 13:71D0
    db $B9, $82, $00, $00, $02, $58, $AB, $AB, $A8, $99, $88, $97, $75, $53, $34, $57; 13:71E0
    db $AC, $CE, $CB, $98, $65, $56, $57, $77, $89, $9A, $BB, $BA, $A9, $99, $9A, $CD; 13:71F0
    db $B9, $82, $00, $00, $04, $7B, $CD, $BB, $97, $77, $77, $86, $64, $32, $35, $8A; 13:7200
    db $EE, $DD, $A8, $65, $34, $56, $78, $98, $9A, $AB, $BA, $A9, $98, $89, $AB, $DE; 13:7210
    db $C9, $80, $00, $00, $26, $9D, $DD, $9A, $86, $88, $77, $73, $31, $33, $7A, $DE; 13:7220
    db $FD, $B9, $54, $34, $46, $78, $79, $99, $AB, $AA, $A8, $87, $87, $9B, $BC, $EE; 13:7230
    db $E8, $71, $00, $00, $27, $9D, $DE, $AA, $A6, $77, $63, $50, $21, $57, $BF, $FE; 13:7240
    db $DB, $56, $33, $35, $56, $78, $8A, $CB, $CB, $96, $75, $77, $AA, $BB, $AB, $CD; 13:7250
    db $FE, $77, $00, $00, $06, $CF, $FE, $E7, $77, $56, $73, $12, $03, $5D, $FF, $FF; 13:7260
    db $97, $20, $33, $66, $86, $78, $BA, $DD, $A8, $54, $36, $8B, $BC, $99, $99, $AD; 13:7270
    db $EE, $FA, $21, $00, $01, $8C, $FD, $B9, $A5, $89, $54, $10, $03, $6D, $FF, $FC; 13:7280
    db $95, $24, $55, $65, $64, $8B, $DE, $FA, $74, $23, $59, $AB, $B9, $78, $89, $BB; 13:7290
    db $A9, $99, $BE, $F5, $30, $00, $06, $BF, $EA, $68, $75, $C7, $31, $00, $39, $FF; 13:72A0
    db $FE, $54, $54, $59, $76, $47, $7A, $EE, $B9, $51, $35, $89, $BA, $78, $98, $AB; 13:72B0
    db $98, $89, $9B, $DD, $CF, $E2, $00, $00, $49, $DE, $E9, $7B, $A5, $92, $00, $04; 13:72C0
    db $9F, $FC, $AA, $36, $87, $55, $44, $7D, $EC, $C8, $34, $66, $88, $86, $79, $9A; 13:72D0
    db $A8, $67, $89, $AC, $A8, $99, $AE, $FD, $00, $00, $3B, $FD, $CA, $68, $FA, $32; 13:72E0
    db $00, $09, $EF, $FD, $58, $B9, $96, $20, $29, $EE, $FA, $53, $57, $89, $74, $5A; 13:72F0
    db $AB, $B7, $45, $8A, $BB, $96, $78, $AB, $CB, $AC, $FA, $00, $00, $5B, $FB, $BB; 13:7300
    db $68, $E5, $00, $00, $5F, $FC, $DC, $6A, $B6, $20, $24, $9F, $EA, $A7, $67, $97; 13:7310
    db $44, $78, $BC, $96, $56, $89, $A9, $78, $99, $99, $88, $9B, $CC, $DE, $B0, $00; 13:7320
    db $07, $BD, $97, $CB, $9B, $40, $00, $68, $DD, $9A, $EB, $97, $20, $17, $AA, $BB; 13:7330
    db $9A, $BA, $64, $44, $6A, $A9, $88, $88, $87, $67, $99, $A9, $87, $8A, $AB, $BA; 13:7340
    db $98, $9B, $EA, $00, $01, $89, $A5, $6E, $D9, $71, $01, $7A, $67, $99, $CF, $B5; 13:7350
    db $24, $56, $98, $68, $DE, $B8, $64, $58, $86, $68, $9A, $A9, $65, $77, $78, $99; 13:7360
    db $9B, $A8, $88, $99, $98, $89, $AB, $EF, $20, $00, $55, $67, $4E, $FB, $74, $12; 13:7370
    db $46, $31, $8D, $EE, $B8, $67, $94, $24, $6A, $CC, $A8, $AB, $85, $44, $69, $A8; 13:7380
    db $78, $99, $87, $67, $9A, $88, $88, $88, $88, $8A, $A9, $99, $99, $AD, $50, $03; 13:7390
    db $55, $37, $6C, $FB, $54, $56, $33, $21, $9E, $DA, $9B, $B8, $83, $25, $88, $68; 13:73A0
    db $CC, $CA, $76, $67, $64, $68, $99, $98, $89, $97, $68, $89, $98, $88, $88, $77; 13:73B0
    db $8A, $A9, $98, $89, $9B, $80, $05, $65, $15, $99, $EA, $67, $99, $51, $35, $78; 13:73C0
    db $77, $9D, $D9, $88, $88, $55, $57, $A9, $89, $BB, $97, $76, $66, $56, $79, $98; 13:73D0
    db $9A, $A9, $77, $78, $88, $88, $99, $89, $99, $98, $87, $78, $79, $B5, $05, $85; 13:73E0
    db $22, $88, $89, $68, $BA, $73, $79, $65, $57, $99, $A8, $9C, $B8, $78, $86, $56; 13:73F0
    db $68, $88, $89, $A9, $78, $88, $76, $67, $78, $78, $99, $88, $99, $88, $88, $88; 13:7400
    db $88, $88, $88, $88, $88, $99, $9A, $50, $78, $20, $38, $75, $88, $BB, $87, $8A; 13:7410
    db $74, $57, $75, $68, $99, $99, $AB, $A8, $78, $75, $56, $77, $77, $9A, $98, $9A; 13:7420
    db $97, $67, $87, $67, $78, $88, $89, $98, $89, $88, $88, $77, $77, $88, $78, $88; 13:7430
    db $9A, $A4, $2A, $60, $25, $73, $47, $7B, $97, $AB, $A6, $7A, $65, $57, $86, $87; 13:7440
    db $9B, $88, $AB, $97, $99, $87, $67, $76, $67, $88, $78, $99, $88, $88, $76, $68; 13:7450
    db $77, $79, $98, $89, $99, $88, $88, $87, $88, $77, $87, $78, $97, $36, $93, $35; 13:7460
    db $55, $35, $67, $85, $8B, $98, $8B, $97, $87, $98, $66, $89, $77, $99, $98, $99; 13:7470
    db $99, $88, $87, $77, $77, $67, $87, $77, $88, $77, $88, $88, $99, $88, $89, $87; 13:7480
    db $88, $88, $88, $88, $88, $77, $77, $78, $98, $46, $A3, $37, $55, $45, $67, $85; 13:7490
    db $8B, $88, $9B, $98, $98, $98, $68, $87, $67, $87, $87, $89, $88, $89, $87, $89; 13:74A0
    db $87, $78, $76, $67, $77, $78, $88, $89, $99, $88, $99, $88, $88, $87, $88, $77; 13:74B0
    db $78, $77, $88, $77, $88, $88, $56, $A5, $37, $65, $55, $57, $75, $89, $87, $9B; 13:74C0
    db $99, $99, $A8, $78, $87, $67, $87, $77, $88, $88, $89, $88, $99, $88, $88, $77; 13:74D0
    db $78, $87, $88, $88, $88, $88, $88, $88, $88, $88, $78, $87, $77, $87, $77, $87; 13:74E0
    db $77, $77, $78, $89, $66, $87, $55, $66, $55, $56, $65, $68, $87, $8A, $99, $9A; 13:74F0
    db $A9, $88, $98, $77, $88, $77, $88, $77, $88, $88, $89, $88, $89, $88, $88, $88; 13:7500
    db $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $77, $77, $77; 13:7510
    db $77, $77, $77, $77, $77, $78, $87, $77, $87, $77, $77, $77, $78, $77, $88, $88; 13:7520
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:7530
    db $87, $88, $88, $88, $88, $88, $88, $78, $88, $77, $77, $77, $77, $77, $77, $77; 13:7540
    db $77, $77, $77, $78, $77, $88, $78, $88, $78, $87, $88, $88, $88, $87, $88, $88; 13:7550
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $88, $87, $88, $88, $88; 13:7560
    db $88, $88, $88, $88, $88, $78, $77, $77, $77, $88, $78, $78, $88, $77, $77, $78; 13:7570
    db $77, $77, $77, $77, $77, $77, $78, $77, $88, $88, $77, $87, $77, $88, $88, $88; 13:7580
    db $88, $88, $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:7590
    db $88, $88, $77, $87, $78, $77, $77, $77, $88, $78, $88, $78, $87, $87, $78, $77; 13:75A0
    db $77, $87, $77, $77, $88, $88, $88, $88, $88, $88, $87, $88, $78, $88, $88, $88; 13:75B0
    db $88, $88, $88, $88, $88, $78, $78, $78, $77, $88, $77, $78, $88, $88, $88, $88; 13:75C0
    db $88, $88, $78, $77, $77, $88, $88, $88, $87, $88, $87, $78, $77, $77, $87, $87; 13:75D0
    db $88, $88, $88, $87, $78, $78, $88, $88, $88, $88, $88, $87, $78, $88, $88, $88; 13:75E0
    db $88, $87, $87, $78, $78, $77, $77, $87, $87, $88, $78, $88, $88, $88, $88, $77; 13:75F0
    db $78, $78, $87, $88, $88, $88, $88, $87, $87, $88, $78, $88, $88, $88, $88, $88; 13:7600
    db $88, $77, $78, $88, $78, $88, $88, $88, $78, $78, $78, $78, $88, $88, $88, $88; 13:7610
    db $88, $78, $77, $87, $88, $88, $88, $88, $88, $87, $78, $88, $88, $88, $88, $88; 13:7620
    db $88, $88, $88, $88, $88, $88, $78, $78, $78, $88, $87, $87, $88, $77, $78, $77; 13:7630
    db $87, $87, $77, $78, $78, $88, $88, $87, $88, $87, $87, $88, $88, $88, $88, $88; 13:7640
    db $88, $88, $87, $88, $88, $78, $88, $87, $88, $87, $88, $88, $88, $88, $87, $87; 13:7650
    db $88, $88, $88, $88, $88, $88, $87, $88, $88, $88, $78, $78, $77, $78, $87, $87; 13:7660
    db $88, $88, $78, $88, $78, $88, $88, $88, $88, $88, $88, $78, $78, $77, $78, $77; 13:7670
    db $88, $78, $88, $88, $78, $77, $88, $87, $88, $87, $88, $78, $87, $88, $78, $88; 13:7680
    db $88, $88, $88, $88, $78, $78, $87, $88, $87, $88, $88, $88, $78, $88, $88, $88; 13:7690
    db $88, $78, $78, $78, $88, $88, $88, $88, $87, $88, $78, $78, $88, $87, $88, $87; 13:76A0
    db $87, $87, $87, $88, $78, $87, $88, $87, $87, $88, $88, $88, $88, $88, $87, $88; 13:76B0
    db $88, $88, $88, $88, $88, $88, $78, $88, $88, $78, $88, $78, $88, $88, $88, $87; 13:76C0
    db $87, $88, $88, $88, $88, $88, $88, $87, $87, $87, $88, $78, $87, $78, $88, $78; 13:76D0
    db $87, $87, $88, $78, $88, $88, $88, $88, $87, $88, $88, $88, $88, $88, $88, $88; 13:76E0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $88, $78, $88, $88, $88; 13:76F0
    db $77, $88, $88, $78, $88, $88, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:7700
    db $88, $88, $88, $88, $88, $88, $88, $78, $88, $87, $88, $78, $88, $87, $88, $88; 13:7710
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $88, $88, $78, $87; 13:7720
    db $87, $88, $78, $88, $78, $88, $88, $88, $88, $88, $87, $87, $88, $78, $88, $88; 13:7730
    db $88, $88, $88, $88, $88, $78, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88; 13:7740
    db $88, $88, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78; 13:7750
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $88, $78; 13:7760
    db $77, $87, $87, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:7770
    db $88, $88, $88, $78, $88, $87, $77, $87, $77, $87, $88, $78, $77, $77, $78, $78; 13:7780
    db $88, $88, $88, $88, $78, $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88; 13:7790
    db $87, $87, $78, $88, $78, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:77A0
    db $88, $77, $87, $87, $87, $87, $88, $88, $78, $87, $88, $87, $88, $88, $87, $88; 13:77B0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $88, $88, $88, $88, $78, $88; 13:77C0
    db $88, $88, $88, $88, $88, $78, $88, $88, $88, $88, $87, $88, $88, $77, $87, $87; 13:77D0

;; PCM16: 2688 bytes = 5376 4-bit samples (rate 2) for SFXInst30
PCM16:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:77E0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:77F0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:7800
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:7810
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $66; 13:7820
    db $55, $55, $55, $55, $67, $78, $89, $99, $99, $99, $99, $98, $88, $77, $77, $77; 13:7830
    db $67, $77, $88, $88, $88, $99, $99, $99, $99, $99, $99, $99, $AA, $AB, $A9, $85; 13:7840
    db $44, $33, $43, $33, $33, $56, $79, $AA, $A9, $99, $A9, $99, $87, $66, $66, $67; 13:7850
    db $77, $77, $77, $89, $99, $98, $88, $88, $99, $98, $89, $99, $AA, $9A, $99, $9A; 13:7860
    db $AA, $97, $65, $33, $33, $44, $34, $45, $67, $89, $A9, $98, $88, $88, $87, $76; 13:7870
    db $66, $78, $89, $99, $99, $99, $99, $98, $88, $88, $89, $99, $9A, $AA, $AB, $BB; 13:7880
    db $BC, $DE, $B7, $30, $00, $01, $34, $55, $68, $CE, $FF, $A8, $40, $12, $36, $77; 13:7890
    db $78, $AC, $FF, $FD, $85, $21, $34, $68, $88, $9B, $BD, $CA, $97, $57, $89, $BB; 13:78A0
    db $BB, $BD, $FF, $FF, $40, $00, $00, $5A, $9B, $99, $DF, $FE, $A0, $00, $00, $7B; 13:78B0
    db $FE, $CD, $DF, $FE, $92, $00, $02, $8E, $FE, $CA, $AB, $BA, $74, $12, $69, $EE; 13:78C0
    db $DB, $99, $BD, $EE, $DB, $9A, $50, $00, $00, $09, $BC, $DB, $A9, $97, $32, $00; 13:78D0
    db $02, $AE, $FF, $EB, $A9, $86, $52, $12, $49, $CD, $DB, $87, $77, $88, $76, $77; 13:78E0
    db $AC, $CB, $98, $89, $BD, $DC, $BB, $CD, $D2, $00, $00, $08, $FE, $CB, $8A, $AA; 13:78F0
    db $40, $00, $04, $BF, $FF, $DA, $AB, $A6, $20, $02, $8C, $FF, $B8, $66, $8A, $97; 13:7900
    db $65, $7A, $BB, $A7, $89, $BD, $EC, $A9, $8B, $EF, $FD, $00, $00, $18, $9E, $A6; 13:7910
    db $AC, $FB, $70, $00, $03, $DE, $DE, $BE, $FF, $B5, $00, $05, $9E, $FA, $89, $9B; 13:7920
    db $B7, $44, $57, $BB, $98, $77, $AC, $CB, $A8, $9B, $BB, $BA, $BD, $FF, $C0, $00; 13:7930
    db $06, $A9, $96, $5B, $FF, $72, $00, $06, $7A, $A8, $BF, $FF, $B5, $00, $45, $78; 13:7940
    db $67, $BF, $EB, $94, $37, $88, $86, $58, $BC, $BA, $89, $BC, $B9, $88, $AD, $DB; 13:7950
    db $BA, $CF, $F0, $00, $01, $74, $02, $BE, $FF, $60, $24, $33, $10, $0B, $FF, $FD; 13:7960
    db $7A, $EB, $42, $10, $7B, $87, $9A, $BC, $B6, $58, $87, $87, $69, $BB, $9A, $AB; 13:7970
    db $CB, $99, $99, $98, $87, $9B, $EF, $F3, $00, $00, $00, $00, $AF, $9A, $CE, $DA; 13:7980
    db $50, $04, $63, $36, $AE, $FF, $A9, $CC, $84, $11, $5A, $86, $8B, $DC, $B8, $8A; 13:7990
    db $96, $46, $89, $AA, $9A, $CB, $A8, $87, $77, $77, $89, $88, $98, $88, $AA, $51; 13:79A0
    db $35, $30, $03, $45, $43, $47, $97, $57, $99, $88, $88, $99, $88, $99, $98, $9A; 13:79B0
    db $A9, $99, $9A, $98, $89, $98, $78, $89, $99, $99, $99, $98, $88, $87, $66, $56; 13:79C0
    db $77, $77, $88, $86, $56, $66, $55, $66, $78, $78, $88, $88, $87, $76, $76, $67; 13:79D0
    db $78, $87, $78, $99, $88, $88, $88, $88, $77, $78, $88, $88, $88, $88, $88, $88; 13:79E0
    db $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $78, $87, $77, $78; 13:79F0
    db $88, $77, $77, $77, $77, $77, $77, $77, $88, $88, $87, $88, $87, $77, $77, $77; 13:7A00
    db $78, $87, $77, $78, $88, $88, $88, $77, $77, $77, $78, $88, $88, $88, $88, $77; 13:7A10
    db $77, $77, $77, $88, $88, $88, $88, $77, $77, $78, $78, $88, $88, $88, $87, $77; 13:7A20
    db $77, $77, $88, $88, $77, $77, $78, $88, $88, $88, $88, $77, $77, $78, $88, $88; 13:7A30
    db $88, $88, $77, $77, $77, $77, $88, $88, $88, $88, $77, $77, $77, $88, $88, $88; 13:7A40
    db $88, $88, $77, $78, $88, $87, $77, $88, $77, $77, $78, $88, $87, $78, $88, $88; 13:7A50
    db $77, $88, $88, $88, $88, $88, $88, $87, $77, $88, $88, $88, $88, $77, $77, $77; 13:7A60
    db $77, $88, $88, $88, $87, $77, $77, $88, $88, $88, $88, $88, $77, $78, $88, $88; 13:7A70
    db $88, $77, $77, $77, $78, $88, $88, $88, $88, $77, $77, $87, $88, $88, $88, $88; 13:7A80
    db $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $78, $88, $88, $88, $87, $77; 13:7A90
    db $77, $77, $88, $88, $78, $87, $69, $78, $87, $58, $87, $77, $87, $87, $97, $88; 13:7AA0
    db $78, $87, $88, $88, $88, $87, $89, $68, $87, $88, $88, $87, $77, $76, $77, $77; 13:7AB0
    db $88, $88, $88, $78, $78, $87, $87, $78, $78, $77, $87, $77, $87, $87, $88, $78; 13:7AC0
    db $88, $88, $88, $77, $77, $88, $78, $88, $88, $87, $88, $88, $87, $87, $88, $88; 13:7AD0
    db $88, $88, $88, $88, $88, $78, $77, $77, $78, $78, $88, $88, $88, $88, $87, $88; 13:7AE0
    db $78, $88, $88, $88, $88, $88, $87, $77, $87, $88, $88, $77, $77, $87, $88, $78; 13:7AF0
    db $78, $77, $77, $77, $77, $88, $87, $88, $88, $88, $88, $88, $88, $77, $78, $78; 13:7B00
    db $87, $88, $78, $78, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87; 13:7B10
    db $88, $78, $78, $87, $77, $77, $77, $77, $77, $77, $77, $77, $78, $78, $78, $88; 13:7B20
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:7B30
    db $88, $88, $88, $97, $79, $67, $74, $83, $45, $35, $24, $54, $55, $76, $88, $9A; 13:7B40
    db $9B, $BB, $BA, $BB, $AA, $99, $88, $88, $77, $87, $88, $88, $89, $99, $99, $99; 13:7B50
    db $99, $99, $88, $88, $88, $98, $67, $83, $64, $36, $03, $30, $30, $33, $24, $57; 13:7B60
    db $68, $8A, $B9, $DC, $BD, $CD, $CB, $BB, $A9, $98, $76, $66, $55, $55, $65, $67; 13:7B70
    db $88, $9A, $AA, $BB, $BB, $BB, $A9, $99, $98, $88, $87, $88, $89, $85, $88, $37; 13:7B80
    db $44, $50, $32, $02, $03, $22, $35, $65, $89, $9B, $AD, $CC, $DD, $ED, $CD, $BB; 13:7B90
    db $99, $97, $66, $54, $44, $55, $56, $67, $89, $9A, $AB, $BB, $BC, $BB, $BA, $A9; 13:7BA0
    db $88, $87, $78, $77, $77, $88, $65, $A5, $47, $25, $30, $41, $11, $23, $23, $46; 13:7BB0
    db $65, $98, $9A, $AD, $BC, $DD, $DC, $CC, $BA, $99, $87, $66, $54, $55, $55, $56; 13:7BC0
    db $67, $89, $AA, $BB, $BB, $CC, $BA, $AA, $99, $88, $77, $77, $66, $67, $67, $78; 13:7BD0
    db $88, $59, $84, $75, $45, $23, $31, $12, $22, $34, $56, $68, $99, $AB, $CC, $DD; 13:7BE0
    db $DD, $DC, $CB, $AA, $98, $76, $65, $55, $55, $56, $67, $78, $99, $AA, $BB, $BB; 13:7BF0
    db $BA, $A9, $88, $87, $77, $66, $76, $67, $66, $77, $78, $78, $87, $88, $76, $86; 13:7C00
    db $56, $44, $43, $34, $33, $44, $45, $67, $88, $9A, $AB, $BB, $BB, $BB, $BB, $AA; 13:7C10
    db $99, $88, $87, $77, $77, $77, $78, $88, $89, $99, $99, $99, $89, $98, $88, $87; 13:7C20
    db $77, $67, $76, $76, $77, $77, $77, $77, $77, $76, $77, $67, $66, $76, $67, $76; 13:7C30
    db $77, $77, $77, $88, $78, $87, $77, $77, $77, $77, $77, $88, $88, $88, $88, $99; 13:7C40
    db $99, $99, $99, $98, $98, $89, $88, $88, $88, $87, $88, $78, $78, $78, $77, $77; 13:7C50
    db $86, $78, $67, $76, $77, $76, $78, $67, $77, $77, $87, $77, $78, $78, $87, $78; 13:7C60
    db $78, $87, $78, $67, $77, $77, $77, $87, $78, $88, $88, $88, $88, $88, $88, $88; 13:7C70
    db $88, $88, $88, $87, $78, $77, $87, $78, $78, $78, $78, $87, $88, $78, $78, $87; 13:7C80
    db $88, $78, $78, $88, $87, $98, $88, $88, $88, $88, $87, $88, $77, $77, $67, $76; 13:7C90
    db $78, $67, $87, $78, $87, $88, $78, $87, $88, $88, $87, $88, $78, $78, $77, $87; 13:7CA0
    db $88, $78, $77, $88, $78, $87, $78, $87, $88, $79, $78, $98, $88, $88, $89, $78; 13:7CB0
    db $87, $88, $88, $88, $78, $77, $87, $78, $77, $87, $78, $86, $88, $78, $87, $88; 13:7CC0
    db $88, $88, $78, $77, $87, $78, $78, $77, $87, $87, $78, $78, $87, $78, $87, $78; 13:7CD0
    db $78, $88, $79, $77, $88, $88, $87, $88, $87, $97, $88, $87, $97, $79, $86, $88; 13:7CE0
    db $77, $86, $78, $67, $86, $87, $78, $78, $87, $96, $88, $78, $79, $78, $87, $87; 13:7CF0
    db $79, $68, $87, $77, $96, $89, $68, $87, $78, $86, $98, $68, $87, $78, $86, $97; 13:7D00
    db $78, $87, $88, $78, $87, $88, $78, $68, $87, $88, $78, $78, $78, $87, $87, $78; 13:7D10
    db $77, $87, $87, $78, $78, $78, $78, $87, $78, $87, $87, $78, $78, $77, $87, $88; 13:7D20
    db $78, $87, $87, $96, $89, $77, $97, $88, $88, $78, $77, $86, $88, $68, $87, $77; 13:7D30
    db $88, $78, $87, $88, $78, $87, $87, $87, $88, $88, $88, $88, $87, $88, $79, $79; 13:7D40
    db $87, $87, $78, $79, $78, $85, $97, $78, $87, $78, $77, $87, $78, $96, $87, $78; 13:7D50
    db $87, $87, $87, $78, $77, $86, $89, $59, $78, $78, $87, $87, $87, $78, $78, $78; 13:7D60
    db $78, $96, $89, $78, $98, $88, $87, $88, $88, $77, $78, $68, $86, $88, $77, $87; 13:7D70
    db $78, $86, $88, $78, $67, $96, $87, $77, $88, $78, $95, $88, $78, $77, $88, $78; 13:7D80
    db $87, $78, $78, $88, $78, $87, $88, $78, $88, $87, $88, $78, $78, $87, $87, $87; 13:7D90
    db $88, $79, $68, $86, $87, $78, $78, $77, $86, $88, $78, $78, $87, $88, $78, $77; 13:7DA0
    db $88, $78, $77, $87, $87, $88, $77, $87, $87, $87, $87, $88, $79, $78, $78, $87; 13:7DB0
    db $79, $77, $87, $87, $88, $79, $78, $87, $88, $78, $86, $87, $79, $77, $87, $77; 13:7DC0
    db $87, $69, $76, $88, $69, $86, $97, $78, $87, $88, $88, $87, $78, $87, $87, $88; 13:7DD0
    db $77, $97, $87, $87, $78, $77, $87, $88, $87, $79, $68, $97, $88, $87, $79, $77; 13:7DE0
    db $98, $79, $77, $88, $77, $88, $77, $77, $87, $78, $77, $87, $78, $77, $88, $87; 13:7DF0
    db $88, $78, $87, $87, $78, $68, $78, $87, $88, $87, $87, $69, $78, $78, $87, $88; 13:7E00
    db $78, $78, $87, $88, $77, $87, $88, $88, $78, $86, $88, $78, $87, $78, $77, $88; 13:7E10
    db $78, $87, $78, $77, $87, $78, $77, $88, $78, $87, $78, $77, $88, $77, $88, $68; 13:7E20
    db $86, $88, $78, $78, $88, $88, $88, $78, $97, $79, $78, $88, $87, $88, $78, $87; 13:7E30
    db $88, $88, $88, $87, $87, $78, $78, $77, $87, $78, $78, $87, $78, $78, $77, $77; 13:7E40
    db $87, $78, $77, $87, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 13:7E50
    db $78, $88, $78, $88, $8A, $97, $88, $65, $54, $44, $43, $46, $55, $78, $89, $AA; 13:7E60
    db $AA, $B9, $9A, $97, $77, $76, $67, $77, $88, $89, $99, $99, $99, $98, $88, $88; 13:7E70
    db $89, $98, $99, $99, $99, $88, $87, $77, $77, $88, $96, $15, $92, $02, $34, $22; 13:7E80
    db $44, $89, $68, $BB, $B9, $9B, $99, $86, $78, $76, $78, $98, $8A, $AB, $A9, $99; 13:7E90
    db $87, $66, $76, $66, $78, $88, $99, $AA, $99, $99, $98, $89, $88, $88, $99, $88; 13:7EA0
    db $88, $87, $77, $67, $78, $A9, $20, $77, $10, $14, $32, $44, $6B, $B8, $9B, $DA; 13:7EB0
    db $78, $87, $75, $56, $89, $88, $AC, $BB, $AA, $A9, $86, $66, $55, $66, $78, $9A; 13:7EC0
    db $AA, $AA, $99, $88, $77, $78, $88, $99, $AA, $A9, $98, $87, $66, $66, $55, $67; 13:7ED0
    db $89, $AC, $A2, $25, $52, $00, $14, $55, $59, $CD, $DB, $AB, $A8, $54, $45, $67; 13:7EE0
    db $68, $AC, $DC, $BB, $BA, $86, $55, $66, $65, $68, $AA, $98, $9A, $97, $66, $77; 13:7EF0
    db $77, $89, $AB, $AA, $AA, $98, $76, $77, $66, $67, $78, $76, $67, $88, $88, $BC; 13:7F00
    db $20, $14, $52, $02, $69, $BA, $A9, $AE, $B6, $34, $67, $55, $69, $CD, $DB, $AC; 13:7F10
    db $CA, $75, $56, $67, $77, $9A, $CB, $87, $88, $75, $55, $78, $99, $89, $AA, $98; 13:7F20
    db $88, $88, $87, $67, $88, $87, $88, $88, $76, $66, $65, $56, $78, $AD, $E5, $01; 13:7F30
    db $55, $21, $34, $8E, $EA, $88, $B9, $64, $22, $59, $B9, $8B, $EE, $C9, $75, $57; 13:7F40
    db $75, $57, $AB, $BB, $98, $99, $64, $35, $78, $99, $99, $AB, $86, $67, $88, $89; 13:7F50
    db $99, $A9, $86, $68, $88, $86, $66, $77, $66, $78, $88, $89, $9B, $D8, $00, $04; 13:7F60
    db $55, $66, $6C, $FD, $85, $55, $56, $63, $59, $EE, $CC, $B8, $88, $63, $35, $89; 13:7F70
    db $BB, $BA, $AA, $96, $55, $55, $68, $88, $9A, $98, $77, $77, $88, $88, $9A, $99; 13:7F80
    db $98, $87, $77, $77, $87, $77, $87, $76, $66, $77, $77, $89, $CD, $A0, $00, $35; 13:7F90
    db $78, $76, $BF, $EA, $63, $24, $78, $66, $9D, $ED, $B8, $44, $66, $66, $79, $BD; 13:7FA0
    db $DA, $76, $66, $56, $65, $68, $AA, $98, $87, $88, $77, $78, $99, $99, $88, $99; 13:7FB0
    db $87, $66, $78, $87, $65, $67, $88, $76, $67, $78, $88, $9B, $DB, $30, $01, $47; 13:7FC0
    db $98, $79, $DD, $B7, $31, $26, $88, $89, $BC, $DB, $85, $45, $67, $89, $9A, $CB; 13:7FD0
    db $97, $55, $57, $88, $88, $88, $88, $76, $78, $88, $88, $78, $99, $88, $88, $99; 13:7FE0
    db $86, $67, $88, $87, $77, $88, $76, $57, $89, $88, $78, $9C, $D8, $00, $03, $8A; 13:7FF0

; ============================================================================
SECTION "GHX PCM samples bank $14", ROMX[$4000], BANK[$14]
; ============================================================================
;; (continuation of the previous sample from bank $13)
    db $A7, $7B, $DB, $83, $01, $59, $98, $9A, $CC, $B8, $43, $57, $89, $99, $AB, $B9; 14:4000
    db $75, $56, $89, $88, $99, $88, $76, $67, $89, $98, $87, $88, $88, $89, $99, $98; 14:4010
    db $66, $67, $88, $77, $77, $76, $66, $68, $88, $77, $77, $8A, $CB, $40, $02, $58; 14:4020
    db $A8, $79, $BB, $96, $32, $48, $99, $9A, $AB, $B9, $64, $56, $89, $A9, $9A, $A9; 14:4030
    db $86, $55, $78, $99, $99, $98, $75, $56, $89, $98, $88, $88, $88, $88, $99, $98; 14:4040
    db $87, $67, $77, $77, $88, $88, $65, $67, $88, $88, $77, $88, $9B, $B7, $10, $13; 14:4050
    db $7A, $A8, $8A, $A9, $84, $23, $69, $AA, $A9, $AA, $97, $54, $57, $9A, $99, $9A; 14:4060
    db $98, $75, $56, $88, $99, $88, $88, $65, $56, $89, $98, $77, $88, $88, $88, $99; 14:4070
    db $98, $76, $78, $88, $88, $88, $87, $66, $78, $88, $87, $78, $88, $9B, $B7, $21; 14:4080
    db $13, $79, $98, $9A, $AA, $85, $23, $58, $9A, $A9, $AB, $97, $54, $57, $9A, $9A; 14:4090
    db $A9, $98, $65, $56, $89, $99, $99, $87, $65, $45, $79, $AA, $98, $88, $88, $88; 14:40A0
    db $89, $98, $77, $78, $88, $87, $77, $87, $76, $67, $88, $87, $66, $78, $99, $BA; 14:40B0
    db $52, $22, $47, $98, $8A, $A9, $96, $43, $57, $89, $AA, $AB, $A7, $65, $56, $89; 14:40C0
    db $9A, $AA, $98, $65, $56, $78, $9A, $A9, $98, $65, $55, $78, $99, $99, $88, $87; 14:40D0
    db $78, $99, $99, $87, $77, $77, $77, $88, $87, $76, $77, $78, $88, $87, $77, $77; 14:40E0
    db $89, $BC, $82, $22, $36, $77, $79, $BB, $A8, $54, $56, $77, $8A, $BB, $B9, $76; 14:40F0
    db $66, $77, $89, $AB, $A9, $76, $66, $77, $78, $99, $87, $66, $67, $77, $78, $99; 14:4100
    db $98, $78, $89, $98, $89, $88, $76, $67, $88, $87, $77, $77, $66, $78, $87, $77; 14:4110
    db $77, $77, $78, $89, $BB, $61, $24, $56, $77, $8B, $DB, $87, $65, $66, $55, $8B; 14:4120
    db $BB, $A8, $88, $86, $56, $89, $AA, $98, $99, $86, $66, $78, $88, $88, $88, $77; 14:4130
    db $77, $88, $88, $89, $98, $88, $88, $87, $77, $88, $87, $77, $77, $77, $78, $87; 14:4140
    db $77, $77, $76, $77, $88, $88, $78, $89, $A8, $64, $43, $57, $67, $8A, $A9, $88; 14:4150
    db $77, $76, $67, $88, $99, $99, $A9, $87, $77, $78, $78, $88, $88, $88, $88, $87; 14:4160
    db $78, $87, $88, $89, $88, $88, $88, $87, $77, $77, $78, $88, $87, $77, $77, $76; 14:4170
    db $77, $77, $77, $77, $77, $77, $77, $77, $77, $78, $87, $78, $88, $88, $88, $88; 14:4180
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77; 14:4190
    db $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $78, $87; 14:41A0
    db $77, $77, $88, $88, $88, $88, $87, $77, $78, $88, $88, $88, $77, $77, $78, $88; 14:41B0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $78, $88, $88, $88; 14:41C0
    db $77, $77, $77, $88, $88, $87, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88; 14:41D0
    db $88, $88, $88, $88, $78, $78, $88, $88, $87, $77, $77, $88, $88, $88, $88, $88; 14:41E0
    db $77, $77, $78, $87, $78, $88, $88, $88, $88, $88, $88, $87, $78, $88, $88, $88; 14:41F0
    db $77, $88, $88, $88, $88, $88, $88, $77, $88, $88, $88, $88, $77, $78, $77, $77; 14:4200
    db $88, $87, $87, $77, $77, $77, $77, $78, $78, $78, $78, $78, $78, $88, $88, $88; 14:4210
    db $88, $88, $88, $88, $78, $88, $88, $88, $88, $78, $88, $88, $88, $88, $88, $88; 14:4220
    db $88, $87, $88, $88, $88, $88, $87, $88, $77, $88, $88, $77, $88, $77, $87, $77; 14:4230
    db $77, $78, $77, $88, $88, $78, $88, $78, $88, $88, $88, $88, $78, $88, $88, $88; 14:4240
    db $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77; 14:4250

;; PCM17: 1984 bytes = 3968 4-bit samples (rate 2) for SFXInst31
PCM17:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:4260
    db $88, $88, $88, $88, $88, $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $77; 14:4270
    db $88, $88, $77, $88, $88, $77, $88, $88, $88, $88, $87, $88, $88, $88, $88, $88; 14:4280
    db $88, $88, $88, $88, $78, $77, $77, $77, $77, $77, $87, $88, $77, $87, $77, $77; 14:4290
    db $77, $77, $77, $77, $78, $78, $88, $87, $88, $77, $77, $78, $87, $78, $87, $88; 14:42A0
    db $78, $77, $78, $87, $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $88; 14:42B0
    db $88, $88, $88, $88, $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $87; 14:42C0
    db $88, $75, $54, $44, $43, $45, $66, $78, $89, $99, $99, $99, $98, $89, $AA, $AB; 14:42D0
    db $BB, $BB, $BB, $BB, $BB, $BB, $DF, $A0, $00, $03, $00, $04, $A7, $D8, $AF, $FC; 14:42E0
    db $44, $22, $60, $02, $6C, $DD, $AB, $FC, $B7, $34, $67, $55, $79, $DD, $CC, $CD; 14:42F0
    db $DC, $A9, $BD, $EF, $E0, $00, $07, $00, $03, $FC, $FB, $4E, $BA, $50, $00, $67; 14:4300
    db $58, $7D, $FF, $E7, $54, $67, $10, $36, $CD, $B9, $9D, $CC, $A8, $9A, $CC, $CE; 14:4310
    db $FF, $B0, $00, $06, $02, $06, $FF, $F9, $85, $4A, $40, $00, $5B, $FE, $8D, $EF; 14:4320
    db $F5, $00, $05, $77, $58, $CE, $FA, $68, $8B, $CA, $9A, $CE, $FF, $FB, $00, $00; 14:4330
    db $50, $50, $8F, $FF, $C6, $12, $52, $00, $06, $EF, $FE, $C7, $BB, $50, $00, $2A; 14:4340
    db $FC, $A9, $8C, $A7, $55, $9C, $ED, $BC, $EF, $FF, $00, $00, $66, $A0, $4F, $FF; 14:4350
    db $F8, $00, $02, $42, $03, $BF, $FF, $D3, $13, $45, $00, $28, $FF, $F9, $45, $59; 14:4360
    db $97, $79, $DF, $FF, $FF, $FF, $00, $00, $37, $C4, $9D, $FF, $F9, $00, $00, $57; 14:4370
    db $47, $BF, $FF, $F3, $00, $00, $35, $5A, $FF, $EA, $52, $26, $8A, $BB, $BD, $FF; 14:4380
    db $FF, $F3, $00, $00, $68, $74, $DD, $FF, $E2, $00, $02, $77, $59, $DF, $FF, $B1; 14:4390
    db $00, $00, $45, $7D, $FE, $D9, $52, $47, $8B, $CB, $AD, $FF, $FF, $F0, $00, $00; 14:43A0
    db $6A, $65, $CD, $FF, $E1, $00, $01, $87, $59, $BF, $FF, $C3, $00, $02, $67, $8B; 14:43B0
    db $DD, $DB, $52, $46, $9C, $DB, $AB, $DF, $FF, $F7, $00, $00, $48, $93, $8A, $DF; 14:43C0
    db $F9, $30, $00, $38, $76, $8A, $DF, $FD, $62, $00, $58, $88, $89, $AB, $A7, $55; 14:43D0
    db $7A, $CD, $B9, $89, $BE, $FF, $F8, $00, $00, $25, $75, $68, $8C, $FD, $B6, $31; 14:43E0
    db $25, $66, $76, $79, $AB, $A9, $87, $78, $98, $76, $66, $78, $9A, $BB, $BB, $A9; 14:43F0
    db $88, $88, $89, $9B, $CA, $84, $31, $25, $55, $55, $67, $8A, $99, $87, $66, $56; 14:4400
    db $56, $67, $99, $AA, $98, $88, $76, $65, $67, $99, $AA, $A9, $99, $87, $77, $77; 14:4410
    db $88, $89, $99, $88, $87, $77, $78, $88, $77, $77, $77, $66, $66, $55, $66, $77; 14:4420
    db $88, $87, $77, $66, $67, $78, $89, $99, $99, $98, $88, $77, $88, $88, $88, $88; 14:4430
    db $88, $88, $88, $88, $88, $88, $77, $88, $88, $87, $77, $77, $77, $77, $77, $77; 14:4440
    db $66, $77, $77, $87, $88, $87, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88; 14:4450
    db $88, $88, $88, $88, $88, $87, $88, $87, $77, $88, $88, $88, $77, $77, $77, $88; 14:4460
    db $88, $88, $88, $77, $77, $77, $88, $88, $88, $88, $88, $77, $88, $88, $88, $88; 14:4470
    db $88, $77, $77, $78, $77, $88, $88, $88, $77, $77, $77, $78, $88, $88, $87, $77; 14:4480
    db $77, $77, $88, $88, $88, $88, $87, $77, $78, $89, $98, $88, $88, $87, $77, $77; 14:4490
    db $78, $88, $88, $87, $77, $77, $77, $78, $88, $88, $88, $77, $77, $77, $78, $88; 14:44A0
    db $88, $88, $88, $77, $77, $88, $88, $88, $88, $77, $77, $78, $88, $88, $88, $88; 14:44B0
    db $77, $77, $77, $87, $78, $88, $88, $77, $77, $77, $88, $88, $88, $88, $87, $77; 14:44C0
    db $77, $88, $88, $88, $88, $87, $77, $77, $78, $88, $88, $88, $87, $77, $77, $78; 14:44D0
    db $88, $88, $88, $87, $77, $77, $78, $88, $88, $88, $77, $77, $77, $78, $88, $88; 14:44E0
    db $88, $87, $77, $77, $88, $88, $88, $88, $87, $77, $77, $77, $88, $88, $88, $88; 14:44F0
    db $77, $77, $77, $88, $88, $88, $88, $77, $77, $88, $88, $88, $88, $88, $87, $77; 14:4500
    db $88, $88, $88, $88, $87, $88, $77, $77, $88, $88, $88, $88, $77, $77, $77, $78; 14:4510
    db $88, $88, $88, $77, $77, $77, $88, $88, $88, $88, $77, $78, $88, $88, $88, $88; 14:4520
    db $88, $88, $87, $77, $78, $88, $88, $88, $88, $77, $77, $88, $88, $88, $88, $88; 14:4530
    db $77, $87, $77, $78, $88, $87, $77, $77, $77, $78, $88, $88, $88, $87, $77, $77; 14:4540
    db $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:4550
    db $88, $88, $87, $77, $78, $88, $88, $88, $88, $88, $77, $77, $77, $77, $88, $78; 14:4560
    db $88, $87, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:4570
    db $78, $88, $88, $88, $88, $88, $88, $88, $77, $78, $88, $88, $88, $88, $87, $77; 14:4580
    db $88, $88, $87, $77, $77, $77, $78, $88, $88, $88, $87, $77, $78, $88, $88, $88; 14:4590
    db $88, $88, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:45A0
    db $88, $88, $88, $88, $88, $88, $88, $87, $77, $87, $88, $88, $88, $87, $88, $77; 14:45B0
    db $87, $87, $78, $88, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87; 14:45C0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77; 14:45D0
    db $87, $78, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:45E0
    db $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $77, $77, $77, $77, $87, $78; 14:45F0
    db $88, $88, $88, $88, $88, $88, $88, $88, $89, $88, $89, $99, $99, $99, $86, $54; 14:4600
    db $55, $55, $55, $55, $67, $88, $88, $88, $88, $88, $88, $77, $78, $88, $88, $89; 14:4610
    db $88, $99, $99, $99, $9A, $AA, $BB, $CC, $A7, $43, $33, $44, $55, $44, $46, $8A; 14:4620
    db $A9, $87, $77, $88, $88, $77, $66, $78, $88, $88, $88, $88, $88, $88, $88, $9A; 14:4630
    db $AB, $BC, $CE, $ED, $A5, $10, $12, $33, $33, $22, $47, $BD, $CA, $87, $77, $78; 14:4640
    db $87, $54, $45, $79, $99, $99, $98, $89, $99, $87, $78, $9A, $BB, $CC, $DF, $FF; 14:4650
    db $B4, $00, $02, $22, $11, $12, $59, $DF, $EB, $87, $88, $88, $75, $42, $35, $8A; 14:4660
    db $A9, $88, $9A, $AA, $98, $65, $68, $AB, $BB, $BC, $EF, $FF, $F8, $00, $00, $22; 14:4670
    db $00, $01, $48, $DF, $FD, $87, $8A, $A8, $53, $11, $25, $9B, $B8, $78, $AC, $BA; 14:4680
    db $86, $54, $57, $AA, $98, $9B, $EE, $EF, $FF, $F9, $30, $00, $01, $00, $12, $59; 14:4690
    db $DF, $FE, $A8, $99, $86, $31, $01, $36, $9B, $B9, $9A, $BB, $B8, $75, $44, $57; 14:46A0
    db $88, $88, $AC, $CC, $CB, $BA, $AB, $CE, $FA, $20, $00, $34, $10, $04, $8C, $FF; 14:46B0
    db $FA, $77, $AA, $71, $00, $25, $8A, $BA, $89, $CF, $E9, $41, $35, $76, $65, $68; 14:46C0
    db $AD, $EC, $98, $9A, $BA, $88, $8A, $CF, $FC, $20, $04, $85, $00, $05, $9D, $EE; 14:46D0
    db $94, $5A, $DA, $20, $03, $89, $99, $88, $9D, $FF, $93, $25, $76, $44, $67, $8B; 14:46E0
    db $DD, $96, $7A, $B8, $66, $89, $AB, $CD, $CE, $FF, $90, $00, $54, $00, $04, $9C; 14:46F0
    db $FF, $D8, $7B, $D8, $00, $04, $55, $58, $AB, $EF, $FB, $55, $89, $50, $02, $58; 14:4700
    db $BC, $B9, $9C, $EB, $64, $68, $98, $77, $89, $CE, $EC, $CF, $FB, $00, $05, $40; 14:4710
    db $00, $5A, $DF, $F9, $79, $EB, $10, $02, $65, $58, $9C, $FF, $FA, $57, $98, $20; 14:4720
    db $04, $79, $AB, $BB, $DD, $B6, $46, $76, $55, $69, $AB, $BA, $AC, $DC, $AA, $BD; 14:4730
    db $E7, $00, $07, $50, $02, $8D, $EB, $95, $AD, $92, $00, $57, $66, $6B, $EF, $FB; 14:4740
    db $79, $A9, $40, $14, $78, $88, $8A, $ED, $96, $68, $85, $34, $68, $9A, $99, $BC; 14:4750
    db $B9, $8A, $A9, $99, $AD, $FB, $00, $57, $30, $03, $78, $B8, $99, $EE, $51, $37; 14:4760
    db $63, $16, $6B, $DC, $9A, $CE, $A4, $44, $65, $54, $68, $DB, $98, $AB, $85, $55; 14:4770
    db $57, $67, $79, $BB, $AA, $AB, $A8, $88, $99, $99, $AB, $EE, $10, $45, $20, $04; 14:4780
    db $68, $A9, $9F, $ED, $42, $66, $20, $04, $8A, $DA, $CF, $FB, $75, $76, $32, $25; 14:4790
    db $8A, $9A, $BE, $B9, $66, $66, $44, $58, $A9, $9A, $BB, $A8, $88, $87, $78, $99; 14:47A0
    db $AB, $CC, $CD, $50, $35, $10, $05, $67, $89, $AF, $EA, $65, $95, $00, $25, $86; 14:47B0
    db $8A, $EF, $DA, $AB, $96, $24, $55, $55, $7A, $BB, $98, $A9, $64, $57, $76, $78; 14:47C0
    db $9A, $A9, $9A, $98, $89, $98, $89, $AA, $AA, $AA, $AB, $B2, $07, $41, $01, $85; 14:47D0
    db $78, $8B, $DA, $77, $88, $22, $46, $65, $6A, $CC, $BA, $CC, $A6, $56, $64, $44; 14:47E0
    db $68, $88, $AC, $BA, $89, $87, $55, $66, $67, $89, $AA, $AA, $A9, $88, $88, $87; 14:47F0
    db $88, $99, $9A, $AB, $BB, $30, $76, $00, $17, $33, $68, $CB, $99, $BC, $84, $57; 14:4800
    db $53, $36, $89, $89, $CD, $B9, $99, $86, $55, $65, $55, $89, $99, $AB, $A9, $88; 14:4810
    db $76, $55, $67, $67, $9A, $A9, $9A, $A9, $88, $88, $87, $88, $88, $99, $9A, $B9; 14:4820
    db $64, $46, $10, $13, $42, $68, $9B, $9B, $BB, $96, $77, $54, $47, $76, $79, $BA; 14:4830
    db $AA, $BB, $98, $88, $75, $57, $77, $78, $99, $99, $99, $77, $77, $65, $67, $77; 14:4840
    db $89, $99, $9A, $99, $89, $98, $88, $88, $88, $88, $88, $89, $74, $57, $42, $35; 14:4850
    db $52, $56, $88, $79, $AA, $98, $A9, $86, $78, $65, $67, $87, $89, $AA, $9A, $AA; 14:4860
    db $88, $88, $76, $67, $76, $78, $87, $78, $88, $88, $88, $77, $88, $88, $88, $88; 14:4870
    db $99, $88, $88, $88, $88, $87, $77, $77, $78, $86, $56, $75, $34, $55, $44, $67; 14:4880
    db $67, $8A, $99, $9A, $A8, $89, $88, $77, $87, $77, $88, $78, $88, $88, $99, $88; 14:4890
    db $88, $87, $77, $76, $77, $77, $88, $88, $89, $88, $88, $88, $88, $88, $88, $88; 14:48A0
    db $88, $88, $88, $88, $77, $77, $77, $78, $87, $58, $85, $57, $74, $47, $65, $57; 14:48B0
    db $77, $77, $98, $89, $AA, $89, $A9, $88, $88, $87, $78, $77, $88, $87, $89, $88; 14:48C0
    db $89, $88, $88, $87, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88; 14:48D0
    db $88, $88, $88, $88, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77; 14:48E0
    db $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $99, $99, $99, $98, $88; 14:48F0
    db $88, $88, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:4900
    db $77, $77, $77, $77, $77, $77, $77, $77, $88, $88, $78, $88, $77, $77, $77, $77; 14:4910
    db $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $88, $77, $77; 14:4920
    db $77, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $88, $88, $88, $88, $88; 14:4930
    db $88, $77, $78, $88, $88, $88, $88, $88, $87, $87, $77, $77, $78, $88, $88, $88; 14:4940
    db $88, $77, $77, $77, $77, $78, $88, $88, $88, $77, $77, $77, $78, $88, $88, $88; 14:4950
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:4960
    db $88, $77, $77, $77, $77, $78, $88, $88, $88, $88, $78, $87, $77, $78, $88, $88; 14:4970
    db $88, $88, $88, $88, $87, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $88; 14:4980
    db $88, $88, $88, $87, $88, $87, $88, $88, $88, $88, $78, $88, $77, $87, $78, $77; 14:4990
    db $88, $77, $87, $67, $87, $78, $87, $88, $88, $88, $78, $88, $88, $88, $77, $87; 14:49A0
    db $88, $88, $88, $88, $88, $88, $87, $78, $77, $88, $78, $88, $78, $88, $88, $88; 14:49B0
    db $88, $78, $77, $78, $77, $87, $77, $87, $78, $87, $88, $88, $88, $88, $87, $88; 14:49C0
    db $77, $88, $78, $88, $88, $88, $88, $88, $88, $88, $88, $78, $78, $87, $88, $77; 14:49D0
    db $87, $77, $77, $77, $77, $87, $88, $88, $88, $88, $88, $88, $78, $88, $78, $88; 14:49E0
    db $88, $88, $88, $88, $88, $88, $88, $88, $87, $88, $78, $88, $88, $88, $88, $78; 14:49F0
    db $87, $78, $87, $88, $77, $88, $87, $87, $78, $87, $88, $88, $88, $88, $87, $88; 14:4A00
    db $77, $77, $78, $88, $88, $88, $88, $88, $88, $78, $87, $88, $88, $87, $78, $77; 14:4A10

;; PCM18: 3744 bytes = 7488 4-bit samples (rate 2) for SFXInst32
PCM18:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:4A20
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:4A30
    db $88, $88, $88, $88, $87, $88, $87, $78, $88, $87, $88, $87, $88, $88, $87, $88; 14:4A40
    db $88, $88, $88, $88, $88, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:4A50
    db $88, $88, $88, $78, $77, $78, $78, $77, $88, $77, $88, $87, $77, $88, $77, $78; 14:4A60
    db $87, $78, $88, $78, $88, $87, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:4A70
    db $88, $88, $88, $88, $88, $77, $88, $77, $88, $87, $77, $78, $77, $78, $87, $88; 14:4A80
    db $78, $87, $88, $88, $77, $88, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:4A90
    db $87, $88, $78, $87, $77, $88, $78, $88, $88, $88, $88, $88, $88, $88, $87, $88; 14:4AA0
    db $88, $87, $88, $88, $88, $88, $88, $88, $88, $87, $88, $77, $77, $78, $87, $88; 14:4AB0
    db $88, $88, $88, $88, $78, $87, $88, $88, $87, $77, $78, $88, $88, $88, $88, $88; 14:4AC0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:4AD0
    db $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88; 14:4AE0
    db $88, $78, $77, $88, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87; 14:4AF0
    db $88, $87, $77, $88, $87, $78, $77, $77, $78, $87, $78, $88, $88, $87, $88, $88; 14:4B00
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $87, $77, $88, $77; 14:4B10
    db $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77; 14:4B20
    db $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:4B30
    db $88, $88, $88, $77, $77, $77, $77, $77, $77, $77, $77, $78, $88, $88, $88, $88; 14:4B40
    db $88, $88, $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77; 14:4B50
    db $77, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $87, $87, $77, $78; 14:4B60
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77; 14:4B70
    db $87, $88, $88, $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:4B80
    db $88, $88, $88, $88, $88, $88, $88, $88, $78, $87, $87, $88, $88, $88, $88, $88; 14:4B90
    db $88, $88, $88, $77, $77, $77, $77, $77, $77, $77, $77, $88, $78, $88, $88, $88; 14:4BA0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:4BB0
    db $88, $88, $88, $77, $88, $88, $88, $88, $88, $88, $87, $78, $87, $78, $77, $77; 14:4BC0
    db $77, $77, $77, $87, $88, $88, $88, $77, $88, $88, $88, $88, $78, $88, $78, $88; 14:4BD0
    db $78, $78, $88, $78, $88, $88, $88, $88, $88, $88, $88, $87, $88, $87, $88, $78; 14:4BE0
    db $78, $78, $78, $78, $87, $88, $78, $78, $78, $78, $78, $77, $87, $87, $88, $87; 14:4BF0
    db $87, $87, $87, $88, $87, $87, $88, $87, $88, $77, $88, $78, $87, $88, $87, $88; 14:4C00
    db $78, $87, $78, $77, $88, $78, $88, $78, $88, $88, $78, $88, $78, $87, $88, $78; 14:4C10
    db $87, $78, $88, $77, $87, $87, $87, $87, $87, $87, $87, $87, $87, $78, $87, $78; 14:4C20
    db $78, $78, $88, $88, $88, $88, $88, $88, $88, $88, $78, $88, $88, $88, $78, $78; 14:4C30
    db $87, $78, $87, $88, $87, $88, $78, $87, $88, $88, $78, $78, $87, $88, $88, $78; 14:4C40
    db $78, $78, $78, $88, $78, $88, $88, $78, $88, $78, $87, $78, $87, $87, $87, $87; 14:4C50
    db $88, $87, $88, $78, $88, $78, $88, $88, $87, $87, $87, $87, $88, $87, $88, $88; 14:4C60
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $88, $88, $88, $78, $87; 14:4C70
    db $87, $88, $88, $88, $88, $78, $87, $87, $77, $88, $78, $78, $78, $78, $88, $88; 14:4C80
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:4C90
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:4CA0
    db $88, $88, $88, $88, $87, $87, $77, $88, $87, $87, $88, $88, $88, $88, $88, $88; 14:4CB0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $78, $88, $88, $88; 14:4CC0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77; 14:4CD0
    db $77, $77, $77, $77, $77, $77, $77, $87, $77, $88, $88, $88, $88, $88, $88, $88; 14:4CE0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $78; 14:4CF0
    db $88, $88, $88, $77, $77, $77, $77, $77, $77, $77, $77, $77, $78, $88, $88, $88; 14:4D00
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:4D10
    db $88, $77, $76, $65, $55, $54, $45, $56, $67, $78, $89, $9A, $AA, $AA, $A9, $99; 14:4D20
    db $98, $88, $77, $77, $77, $77, $77, $88, $88, $99, $99, $99, $99, $99, $98, $88; 14:4D30
    db $88, $89, $98, $77, $66, $55, $43, $32, $12, $23, $45, $66, $88, $9A, $BB, $BB; 14:4D40
    db $AA, $AB, $A9, $A9, $88, $87, $77, $66, $66, $65, $57, $78, $99, $AA, $AA, $AA; 14:4D50
    db $A9, $99, $99, $89, $99, $99, $AA, $BB, $63, $72, $43, $01, $06, $14, $53, $66; 14:4D60
    db $A6, $78, $89, $AB, $9A, $BA, $AA, $88, $88, $76, $66, $78, $77, $78, $99, $98; 14:4D70
    db $89, $99, $88, $99, $99, $99, $9A, $9A, $AA, $AB, $BB, $BD, $F6, $03, $00, $30; 14:4D80
    db $00, $86, $57, $44, $79, $75, $68, $8D, $BA, $9A, $A8, $75, $56, $78, $77, $89; 14:4D90
    db $99, $77, $78, $88, $89, $9A, $98, $78, $88, $99, $9A, $BB, $BB, $BB, $BB, $AB; 14:4DA0
    db $EF, $20, $10, $43, $21, $09, $79, $71, $26, $89, $68, $7B, $FC, $A7, $67, $77; 14:4DB0
    db $55, $68, $BA, $88, $78, $87, $67, $8A, $BA, $88, $88, $87, $78, $9A, $AA, $AA; 14:4DC0
    db $AB, $BB, $BB, $BC, $FF, $00, $00, $62, $90, $1A, $A9, $32, $02, $AC, $88, $8C; 14:4DD0
    db $CC, $A4, $24, $78, $88, $88, $AB, $96, $55, $68, $99, $9A, $AA, $87, $66, $89; 14:4DE0
    db $99, $9A, $AA, $AA, $AB, $CC, $BB, $CF, $F0, $00, $05, $6B, $21, $89, $85, $40; 14:4DF0
    db $17, $DC, $B9, $88, $BA, $63, $25, $8B, $BA, $78, $89, $76, $55, $8B, $BB, $98; 14:4E00
    db $78, $88, $78, $9A, $AA, $98, $9A, $BB, $CB, $BB, $CE, $F1, $00, $03, $BB, $81; 14:4E10
    db $68, $76, $40, $05, $DF, $DB, $76, $79, $74, $25, $8C, $EC, $86, $67, $78, $65; 14:4E20
    db $8B, $CB, $96, $56, $88, $9A, $99, $99, $98, $99, $BC, $BB, $A9, $BE, $F1, $00; 14:4E30
    db $03, $ED, $A1, $55, $58, $50, $15, $CF, $FC, $64, $68, $86, $36, $8C, $FC, $85; 14:4E40
    db $45, $79, $85, $8A, $BB, $96, $56, $8A, $BA, $99, $98, $99, $9A, $BB, $BB, $BA; 14:4E50
    db $BF, $C0, $00, $0C, $FE, $53, $63, $57, $00, $48, $FF, $E8, $34, $67, $85, $58; 14:4E60
    db $9E, $D9, $54, $56, $89, $78, $AA, $A9, $75, $68, $AB, $B9, $88, $88, $9A, $AB; 14:4E70
    db $BB, $BB, $AB, $FF, $00, $00, $8F, $E8, $26, $34, $70, $03, $8F, $FE, $82, $45; 14:4E80
    db $78, $55, $8A, $ED, $95, $45, $68, $A8, $9B, $A9, $86, $56, $AA, $AB, $99, $88; 14:4E90
    db $88, $AB, $BB, $AA, $BB, $CF, $D0, $00, $0B, $FD, $63, $84, $45, $00, $5B, $FF; 14:4EA0
    db $D6, $25, $67, $74, $7A, $CE, $B7, $44, $66, $89, $8A, $B9, $86, $66, $8B, $AA; 14:4EB0
    db $A9, $99, $88, $8B, $BB, $BA, $AB, $DF, $F0, $00, $09, $FE, $63, $86, $44, $00; 14:4EC0
    db $3B, $FF, $C7, $36, $75, $53, $6B, $DE, $A6, $55, $77, $78, $8A, $CB, $86, $67; 14:4ED0
    db $8A, $98, $9A, $A9, $88, $8A, $BB, $BA, $AB, $FF, $80, $00, $1E, $EA, $26, $B6; 14:4EE0
    db $50, $00, $8F, $FC, $A5, $7A, $63, $13, $9D, $FB, $76, $67, $85, $56, $9C, $C9; 14:4EF0
    db $66, $88, $98, $89, $BB, $A8, $89, $AB, $BB, $AC, $FF, $D0, $00, $0D, $CA, $26; 14:4F00
    db $F9, $31, $00, $7F, $E8, $BA, $AC, $71, $04, $AB, $CA, $79, $A9, $52, $47, $AB; 14:4F10
    db $98, $89, $A8, $67, $8B, $BB, $98, $AB, $BA, $AB, $CF, $F0, $00, $09, $9A, $34; 14:4F20
    db $FE, $21, $00, $5B, $B4, $8E, $DC, $83, $04, $A8, $68, $9C, $C9, $53, $78, $77; 14:4F30
    db $79, $AA, $96, $7A, $A9, $88, $AB, $BA, $9B, $CE, $F5, $00, $28, $56, $66, $FF; 14:4F40
    db $51, $03, $44, $51, $6F, $FC, $87, $87, $61, $04, $AC, $B9, $99, $A9, $52, $58; 14:4F50
    db $99, $9A, $BB, $A8, $79, $A9, $9A, $BC, $EF, $20, $24, $41, $45, $8E, $D5, $67; 14:4F60
    db $94, $33, $37, $B8, $89, $DB, $97, $65, $75, $33, $69, $A9, $99, $BA, $86, $68; 14:4F70
    db $87, $79, $BB, $AA, $BB, $B9, $89, $83, $35, $43, $45, $58, $A8, $8A, $A8, $66; 14:4F80
    db $55, $65, $57, $AA, $AA, $A9, $88, $65, $56, $66, $77, $88, $88, $99, $88, $99; 14:4F90
    db $98, $88, $88, $99, $AA, $A9, $98, $55, $55, $44, $55, $78, $78, $99, $98, $88; 14:4FA0
    db $77, $66, $76, $66, $78, $88, $88, $99, $88, $88, $87, $66, $76, $67, $88, $89; 14:4FB0
    db $88, $99, $89, $99, $88, $88, $88, $88, $88, $77, $77, $66, $66, $66, $66, $77; 14:4FC0
    db $88, $88, $88, $88, $87, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $87; 14:4FD0
    db $78, $87, $78, $88, $87, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77; 14:4FE0
    db $66, $66, $66, $77, $77, $78, $88, $88, $88, $88, $88, $88, $87, $87, $77, $77; 14:4FF0
    db $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $78, $88, $88, $88, $88; 14:5000
    db $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $67, $77, $77, $77, $77, $77; 14:5010
    db $88, $88, $88, $88, $88, $77, $88, $88, $88, $88, $77, $77, $78, $88, $87, $78; 14:5020
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77; 14:5030
    db $77, $67, $66, $66, $76, $77, $77, $88, $88, $88, $88, $88, $88, $87, $78, $88; 14:5040
    db $87, $78, $77, $78, $88, $78, $88, $88, $88, $89, $99, $98, $99, $88, $88, $88; 14:5050
    db $77, $76, $66, $66, $66, $67, $67, $78, $88, $88, $89, $88, $88, $88, $87, $77; 14:5060
    db $77, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $99, $99, $99, $99, $99; 14:5070
    db $99, $76, $87, $65, $55, $54, $45, $65, $66, $78, $88, $89, $98, $99, $98, $88; 14:5080
    db $87, $66, $77, $66, $77, $77, $78, $88, $88, $98, $89, $A9, $99, $AA, $99, $99; 14:5090
    db $99, $AA, $67, $A5, $64, $54, $43, $35, $63, $67, $88, $89, $AA, $98, $AA, $88; 14:50A0
    db $88, $76, $66, $76, $56, $77, $66, $88, $88, $8A, $99, $9A, $A9, $9A, $A9, $99; 14:50B0
    db $A9, $99, $BB, $84, $B8, $44, $46, $33, $13, $55, $17, $89, $69, $AB, $A9, $8B; 14:50C0
    db $A7, $78, $86, $56, $76, $54, $68, $75, $8A, $97, $9A, $A9, $89, $A9, $89, $AA; 14:50D0
    db $89, $AA, $99, $AB, $BA, $28, $D2, $31, $63, $01, $33, $62, $3A, $99, $5C, $DB; 14:50E0
    db $8B, $9C, $86, $68, $85, $36, $86, $55, $99, $87, $9A, $A7, $9A, $A8, $78, $A9; 14:50F0
    db $88, $AB, $89, $AB, $AA, $AC, $C9, $19, $A2, $00, $62, $00, $33, $83, $59, $CC; 14:5100
    db $7A, $DD, $79, $7B, $65, $35, $67, $35, $89, $85, $AC, $A8, $9A, $B7, $77, $88; 14:5110
    db $76, $8A, $98, $8B, $BA, $9B, $BB, $AB, $CC, $22, $A5, $10, $25, $10, $34, $78; 14:5120
    db $69, $9E, $CA, $7C, $A8, $45, $85, $43, $56, $96, $88, $BB, $A8, $BA, $98, $67; 14:5130
    db $76, $66, $79, $89, $9B, $BB, $AB, $BB, $A9, $AA, $BC, $60, $79, $40, $05, $61; 14:5140
    db $04, $6B, $89, $8A, $DE, $75, $8A, $92, $35, $86, $65, $9A, $BB, $89, $BC, $97; 14:5150
    db $69, $86, $45, $68, $78, $8A, $CB, $AA, $BB, $B8, $99, $A9, $AC, $C1, $08, $73; 14:5160
    db $00, $55, $03, $47, $99, $B8, $8B, $E8, $54, $99, $43, $56, $88, $89, $8B, $DB; 14:5170
    db $88, $AB, $75, $56, $66, $67, $89, $BB, $AA, $BC, $B8, $9A, $99, $89, $AC, $FA; 14:5180
    db $02, $79, $20, $04, $53, $43, $78, $DD, $95, $9D, $B6, $15, $77, $55, $47, $8C; 14:5190
    db $B9, $8C, $DB, $75, $87, $65, $55, $67, $A9, $9A, $CD, $B9, $AA, $A9, $89, $9A; 14:51A0
    db $BD, $EC, $12, $68, $40, $02, $43, $54, $77, $BE, $C7, $79, $B9, $22, $45, $57; 14:51B0
    db $57, $7B, $DC, $99, $AB, $96, $65, $55, $66, $66, $9B, $CA, $AB, $CA, $99, $99; 14:51C0
    db $89, $AA, $BF, $E4, $04, $87, $00, $05, $46, $58, $79, $DF, $95, $7A, $B4, $22; 14:51D0
    db $55, $66, $87, $9B, $EC, $98, $AA, $86, $44, $56, $78, $67, $AD, $CA, $9B, $BA; 14:51E0
    db $98, $89, $9B, $BC, $E8, $13, $68, $30, $03, $45, $56, $87, $BE, $C7, $67, $C8; 14:51F0
    db $41, $35, $75, $77, $7A, $DD, $B8, $8B, $A8, $44, $56, $57, $67, $8B, $CB, $9A; 14:5200
    db $BC, $A8, $99, $9A, $BC, $E6, $03, $78, $20, $04, $55, $46, $88, $BD, $B7, $78; 14:5210
    db $C7, $32, $56, $64, $67, $8A, $CC, $A8, $AC, $A7, $45, $76, $56, $68, $8B, $BA; 14:5220
    db $9B, $CB, $98, $AA, $AA, $BC, $C3, $05, $86, $00, $26, $55, $47, $8A, $DC, $87; 14:5230
    db $8B, $B4, $24, $76, $43, $67, $9B, $B9, $9A, $DB, $76, $78, $64, $56, $68, $89; 14:5240
    db $9A, $CC, $AA, $AB, $B9, $AA, $BD, $70, $36, $81, $00, $55, $54, $59, $9D, $C8; 14:5250
    db $6B, $BB, $43, $57, $64, $35, $78, $A8, $8A, $CC, $B8, $99, $87, $55, $66, $77; 14:5260
    db $69, $AB, $AA, $BD, $BA, $AB, $CB, $C5, $04, $75, $00, $16, $43, $44, $9B, $CA; 14:5270
    db $89, $EB, $86, $58, $65, $33, $48, $76, $68, $CB, $99, $BB, $A7, $87, $78, $65; 14:5280
    db $68, $99, $8A, $BB, $BB, $BC, $CB, $CB, $43, $85, $20, $03, $22, $33, $49, $98; 14:5290
    db $8A, $CC, $99, $A8, $88, $55, $56, $65, $47, $88, $88, $9A, $A9, $99, $A9, $88; 14:52A0
    db $88, $88, $89, $A9, $99, $AA, $99, $AA, $A6, $59, $74, $55, $45, $64, $46, $66; 14:52B0
    db $66, $67, $87, $77, $78, $88, $78, $89, $88, $89, $99, $99, $89, $88, $77, $77; 14:52C0
    db $77, $77, $77, $88, $88, $99, $88, $99, $98, $89, $99, $88, $88, $87, $66, $76; 14:52D0
    db $65, $55, $55, $55, $56, $66, $66, $77, $77, $89, $9A, $AA, $AB, $AA, $99, $98; 14:52E0
    db $88, $87, $77, $77, $77, $77, $88, $88, $88, $88, $89, $88, $88, $88, $88, $77; 14:52F0
    db $76, $66, $66, $65, $56, $56, $66, $66, $66, $77, $88, $99, $9A, $AA, $AA, $A9; 14:5300
    db $99, $88, $88, $87, $77, $77, $77, $77, $78, $77, $78, $88, $88, $88, $88, $88; 14:5310
    db $88, $88, $88, $87, $77, $66, $66, $55, $55, $55, $56, $66, $67, $88, $88, $99; 14:5320
    db $99, $99, $99, $99, $99, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $88; 14:5330
    db $88, $88, $88, $99, $88, $88, $88, $88, $87, $76, $66, $55, $55, $55, $66, $66; 14:5340
    db $77, $77, $77, $88, $88, $89, $99, $99, $99, $99, $99, $88, $88, $87, $77, $77; 14:5350
    db $77, $77, $77, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77; 14:5360
    db $77, $66, $66, $66, $66, $66, $66, $67, $77, $78, $88, $89, $99, $99, $99, $99; 14:5370
    db $99, $98, $88, $88, $87, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $77; 14:5380
    db $88, $88, $88, $88, $88, $88, $87, $77, $77, $66, $55, $56, $66, $66, $67, $77; 14:5390
    db $88, $88, $98, $99, $98, $99, $88, $88, $88, $88, $87, $88, $87, $77, $77, $88; 14:53A0
    db $88, $88, $89, $88, $88, $88, $88, $88, $89, $99, $A8, $67, $86, $54, $44, $43; 14:53B0
    db $24, $45, $56, $68, $A8, $9A, $AA, $A9, $9A, $98, $88, $88, $87, $78, $87, $78; 14:53C0
    db $88, $88, $88, $88, $88, $88, $78, $88, $88, $99, $99, $99, $99, $89, $99, $AA; 14:53D0
    db $A4, $68, $44, $12, $13, $20, $33, $54, $67, $9C, $9A, $BC, $BA, $A8, $99, $66; 14:53E0
    db $77, $67, $67, $99, $89, $AA, $99, $89, $98, $77, $87, $77, $89, $98, $8A, $AA; 14:53F0
    db $A9, $AA, $99, $9A, $AA, $B8, $37, $62, $20, $10, $30, $05, $56, $68, $9C, $D9; 14:5400
    db $BC, $B9, $87, $68, $64, $57, $77, $77, $9B, $99, $AB, $A9, $98, $88, $65, $77; 14:5410
    db $67, $78, $A9, $9A, $BA, $AA, $AA, $A9, $9A, $AA, $BB, $54, $94, $20, $01, $12; 14:5420
    db $02, $66, $67, $AB, $DB, $9B, $B9, $76, $66, $74, $46, $87, $79, $AB, $B9, $AB; 14:5430
    db $B8, $87, $77, $55, $67, $66, $88, $AA, $9A, $BB, $99, $A9, $99, $9A, $A9, $AC; 14:5440
    db $D8, $29, $62, $10, $00, $30, $06, $78, $7B, $BE, $D8, $AB, $96, $45, $46, $43; 14:5450
    db $69, $98, $AB, $CD, $AA, $BB, $86, $66, $65, $45, $77, $78, $9B, $A9, $AA, $A9; 14:5460
    db $89, $99, $88, $9B, $A9, $BD, $E7, $09, $52, $00, $10, $40, $18, $A9, $8D, $DE; 14:5470
    db $D6, $8B, $83, $25, $46, $33, $8C, $B9, $CE, $EC, $99, $A9, $53, $55, $54, $47; 14:5480
    db $99, $89, $CB, $A9, $9A, $97, $68, $98, $88, $AB, $BA, $BD, $ED, $21, $A1, $00; 14:5490
    db $00, $24, $07, $CC, $9A, $FD, $D9, $48, $84, $02, $54, $65, $8D, $EC, $BE, $EB; 14:54A0
    db $97, $77, $52, $26, $65, $68, $AB, $A9, $BC, $A7, $78, $87, $67, $99, $89, $BC; 14:54B0
    db $BA, $AB, $CC, $C5, $08, $40, $00, $30, $71, $5E, $DA, $8E, $C9, $93, $36, $40; 14:54C0
    db $07, $68, $99, $DF, $EA, $BD, $97, $54, $45, $32, $68, $88, $AB, $BB, $99, $A9; 14:54D0
    db $66, $77, $77, $79, $AA, $9A, $BB, $A9, $AA, $98, $AD, $30, $83, $00, $03, $3A; 14:54E0
    db $15, $DC, $A7, $C9, $88, $13, $76, $23, $88, $AB, $AC, $ED, $98, $A8, $64, $34; 14:54F0
    db $66, $47, $AA, $AA, $BB, $A8, $78, $86, $56, $88, $88, $9A, $B9, $9A, $A9, $99; 14:5500
    db $89, $98, $9C, $70, $75, $00, $04, $2A, $43, $CC, $B7, $A9, $79, $32, $67, $53; 14:5510
    db $99, $BC, $AA, $DD, $86, $87, $65, $34, $78, $68, $BB, $BA, $99, $98, $55, $77; 14:5520
    db $66, $89, $AA, $9A, $BA, $88, $98, $87, $78, $99, $9B, $DC, $01, $92, $20, $12; 14:5530
    db $58, $08, $DD, $98, $B8, $97, $14, $76, $35, $AA, $CB, $AB, $DB, $76, $76, $54; 14:5540
    db $46, $88, $8A, $BB, $A9, $98, $86, $56, $77, $78, $9A, $A9, $99, $98, $78, $88; 14:5550
    db $78, $89, $AA, $AB, $BC, $D4, $07, $40, $00, $43, $A5, $5D, $EC, $7A, $86, $72; 14:5560
    db $05, $75, $49, $BC, $EB, $AC, $C8, $45, $55, $54, $58, $BA, $9B, $CB, $98, $77; 14:5570
    db $75, $45, $78, $78, $9A, $A9, $88, $98, $77, $88, $88, $89, $AA, $99, $A9, $9B; 14:5580
    db $A0, $07, $00, $02, $46, $C4, $8E, $EA, $79, $56, $61, $16, $86, $6B, $CD, $DB; 14:5590
    db $9A, $B7, $45, $55, $66, $79, $BA, $AB, $BA, $87, $66, $65, $46, $88, $89, $9A; 14:55A0
    db $A8, $88, $87, $67, $88, $88, $9A, $A9, $99, $99, $78, $AA, $00, $72, $10, $25; 14:55B0
    db $6C, $56, $DD, $A5, $86, $68, $32, $6A, $97, $BB, $CD, $A8, $9A, $74, $46, $67; 14:55C0
    db $77, $9B, $B9, $AA, $98, $65, $56, $65, $68, $99, $9A, $AA, $97, $78, $76, $78; 14:55D0
    db $88, $99, $9A, $98, $88, $86, $66, $8A, $A0, $0A, $43, $13, $66, $B4, $5D, $C9; 14:55E0
    db $58, $87, $83, $37, $A8, $5A, $BB, $B9, $8A, $B7, $35, $76, $66, $89, $BA, $8A; 14:55F0
    db $B9, $76, $66, $65, $57, $99, $89, $AA, $98, $78, $87, $67, $88, $88, $99, $98; 14:5600
    db $88, $87, $66, $67, $77, $9B, $80, $59, $33, $24, $66, $94, $9D, $A9, $7A, $87; 14:5610
    db $63, $57, $76, $7B, $BB, $BA, $BA, $96, $57, $65, $67, $89, $99, $9A, $98, $77; 14:5620
    db $76, $66, $78, $88, $89, $98, $87, $87, $76, $78, $88, $89, $99, $88, $88, $76; 14:5630
    db $78, $77, $77, $89, $9A, $92, $59, $22, $24, $65, $86, $8D, $A9, $8A, $96, $74; 14:5640
    db $57, $76, $7B, $BA, $AA, $BA, $86, $57, $75, $67, $99, $99, $9A, $97, $77, $75; 14:5650
    db $56, $68, $87, $89, $98, $88, $88, $77, $78, $88, $89, $99, $99, $98, $87, $67; 14:5660
    db $76, $67, $77, $78, $9B, $A2, $3A, $42, $23, $75, $76, $7E, $B8, $9B, $B7, $75; 14:5670
    db $58, $65, $69, $B8, $9A, $BB, $98, $78, $85, $56, $77, $68, $8A, $98, $89, $97; 14:5680
    db $67, $77, $66, $79, $98, $99, $99, $88, $88, $77, $78, $87, $88, $88, $88, $88; 14:5690
    db $77, $77, $77, $67, $88, $A9, $43, $A5, $23, $47, $56, $67, $CB, $89, $AA, $77; 14:56A0
    db $66, $76, $56, $89, $89, $BB, $A9, $98, $88, $56, $77, $66, $88, $89, $99, $A9; 14:56B0
    db $88, $87, $66, $77, $77, $89, $99, $89, $99, $87, $88, $77, $78, $88, $78, $88; 14:56C0
    db $88, $88, $77, $77, $66, $78, $9A, $72, $79, $43, $46, $65, $66, $9B, $88, $AB; 14:56D0
    db $97, $88, $87, $66, $79, $77, $9A, $A9, $9A, $99, $77, $77, $65, $77, $77, $88; 14:56E0
    db $99, $88, $88, $77, $77, $67, $78, $88, $89, $99, $88, $88, $77, $77, $77, $77; 14:56F0
    db $88, $88, $88, $88, $77, $77, $77, $89, $95, $49, $73, $46, $75, $67, $7A, $A7; 14:5700
    db $9B, $A8, $89, $88, $76, $78, $76, $89, $98, $9A, $A9, $98, $88, $76, $67, $66; 14:5710
    db $77, $88, $88, $98, $88, $87, $77, $77, $77, $89, $98, $89, $98, $88, $88, $77; 14:5720
    db $77, $77, $78, $87, $78, $87, $77, $77, $77, $89, $94, $4B, $62, $56, $65, $56; 14:5730
    db $7A, $86, $AB, $97, $9A, $88, $67, $88, $66, $99, $88, $9B, $99, $99, $98, $77; 14:5740
    db $77, $66, $77, $77, $88, $88, $88, $88, $88, $87, $77, $88, $88, $88, $88, $88; 14:5750
    db $88, $88, $87, $77, $77, $77, $77, $77, $77, $77, $88, $99, $64, $98, $24, $56; 14:5760
    db $44, $66, $98, $79, $BA, $8A, $B9, $87, $88, $76, $68, $87, $79, $A9, $9A, $AA; 14:5770
    db $88, $88, $76, $77, $66, $78, $88, $88, $98, $88, $98, $78, $88, $77, $88, $87; 14:5780
    db $88, $88, $88, $88, $88, $77, $77, $77, $66, $77, $77, $88, $88, $99, $66, $A6; 14:5790
    db $35, $65, $35, $56, $86, $7A, $B9, $9B, $BA, $99, $98, $76, $78, $66, $78, $88; 14:57A0
    db $99, $98, $89, $98, $78, $87, $67, $77, $77, $88, $88, $88, $88, $88, $88, $88; 14:57B0
    db $87, $78, $87, $88, $88, $88, $88, $88, $87, $77, $77, $66, $67, $77, $77, $88; 14:57C0
    db $87, $68, $85, $56, $75, $56, $66, $67, $89, $88, $AA, $99, $99, $88, $88, $88; 14:57D0
    db $78, $87, $78, $88, $78, $88, $88, $88, $87, $88, $77, $88, $88, $88, $88, $88; 14:57E0
    db $88, $88, $88, $88, $87, $78, $87, $77, $77, $77, $77, $77, $77, $77, $77, $77; 14:57F0
    db $77, $77, $77, $88, $77, $77, $77, $77, $77, $77, $77, $78, $88, $88, $88, $88; 14:5800
    db $88, $99, $88, $88, $88, $88, $77, $78, $87, $88, $88, $88, $88, $88, $88, $88; 14:5810
    db $88, $88, $88, $78, $87, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77; 14:5820
    db $77, $77, $77, $77, $77, $77, $77, $87, $78, $88, $88, $88, $88, $88, $88, $88; 14:5830
    db $88, $88, $88, $88, $87, $87, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:5840
    db $88, $88, $87, $88, $78, $88, $77, $87, $78, $88, $88, $77, $77, $77, $77, $77; 14:5850
    db $77, $77, $77, $77, $77, $78, $77, $88, $77, $78, $88, $88, $87, $78, $87, $88; 14:5860
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $78, $88, $88, $87, $88, $88; 14:5870
    db $88, $88, $88, $87, $78, $87, $77, $77, $77, $88, $88, $88, $88, $77, $77, $77; 14:5880
    db $77, $78, $77, $88, $88, $88, $88, $88, $87, $88, $77, $88, $78, $88, $88, $88; 14:5890
    db $88, $77, $87, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $88, $87; 14:58A0
    db $78, $77, $78, $87, $77, $87, $77, $87, $77, $77, $88, $88, $88, $88, $88, $88; 14:58B0

;; PCM19: 4784 bytes = 9568 4-bit samples (rate 2) for SFXInst33
PCM19:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:58C0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:58D0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:58E0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77; 14:58F0
    db $77, $78, $88, $88, $88, $88, $99, $98, $88, $88, $88, $77, $77, $77, $77, $77; 14:5900
    db $78, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:5910
    db $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $66, $66, $66, $66, $77; 14:5920
    db $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $78, $88; 14:5930
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $88; 14:5940
    db $88, $87, $76, $66, $66, $66, $66, $56, $67, $78, $88, $88, $99, $99, $99, $98; 14:5950
    db $88, $88, $88, $87, $77, $77, $77, $78, $78, $88, $88, $88, $88, $88, $88, $88; 14:5960
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:5970
    db $87, $76, $66, $65, $56, $55, $56, $66, $77, $88, $88, $99, $99, $99, $98, $88; 14:5980
    db $88, $88, $88, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:5990
    db $88, $88, $88, $88, $88, $77, $77, $77, $77, $88, $87, $76, $66, $65, $55, $55; 14:59A0
    db $55, $56, $77, $88, $88, $99, $99, $99, $99, $88, $88, $88, $88, $77, $77, $77; 14:59B0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:59C0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $65, $55, $55, $55, $55, $56; 14:59D0
    db $78, $88, $88, $99, $AA, $AA, $99, $98, $88, $88, $77, $77, $77, $78, $88, $88; 14:59E0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:59F0
    db $77, $77, $77, $77, $88, $88, $76, $55, $55, $55, $44, $44, $56, $78, $88, $89; 14:5A00
    db $AB, $BB, $A9, $99, $99, $98, $87, $66, $77, $77, $77, $78, $88, $88, $88, $88; 14:5A10
    db $88, $88, $88, $88, $99, $88, $88, $99, $88, $88, $88, $88, $88, $77, $77, $78; 14:5A20
    db $88, $98, $75, $44, $55, $53, $22, $45, $66, $77, $88, $9B, $BB, $AA, $9A, $BA; 14:5A30
    db $98, $77, $77, $77, $76, $66, $78, $88, $88, $88, $88, $88, $77, $88, $88, $88; 14:5A40
    db $89, $99, $99, $99, $99, $98, $88, $88, $88, $77, $78, $99, $98, $54, $45, $64; 14:5A50
    db $20, $13, $55, $55, $67, $9A, $BB, $BA, $AB, $CB, $98, $78, $88, $75, $56, $77; 14:5A60
    db $77, $77, $89, $99, $87, $88, $98, $76, $78, $88, $88, $89, $99, $A9, $99, $99; 14:5A70
    db $98, $88, $99, $87, $78, $AB, $A7, $32, $47, $61, $00, $25, $52, $24, $8A, $AA; 14:5A80
    db $AB, $BC, $DD, $B8, $89, $A9, $64, $57, $86, $55, $79, $98, $89, $99, $89, $98; 14:5A90
    db $77, $88, $86, $78, $99, $88, $AA, $A9, $9A, $99, $99, $98, $89, $AB, $B9, $42; 14:5AA0
    db $46, $61, $00, $15, $20, $05, $9A, $87, $AD, $DD, $CB, $BA, $BB, $96, $56, $98; 14:5AB0
    db $43, $59, $97, $57, $AB, $87, $89, $98, $77, $78, $88, $88, $89, $BA, $99, $AB; 14:5AC0
    db $B9, $9A, $BA, $99, $BD, $D5, $04, $88, $00, $04, $40, $00, $89, $65, $7D, $EC; 14:5AD0
    db $BC, $BB, $BB, $A6, $58, $97, $33, $89, $75, $6A, $C8, $78, $AA, $86, $77, $87; 14:5AE0
    db $67, $78, $A9, $9A, $BC, $B9, $AB, $CB, $99, $BC, $DB, $32, $78, $40, $02, $50; 14:5AF0
    db $00, $7A, $32, $8D, $FA, $9D, $EC, $B8, $98, $88, $63, $57, $86, $36, $BA, $76; 14:5B00
    db $9C, $A7, $79, $A8, $67, $88, $87, $8A, $AB, $AA, $CD, $CB, $BD, $EE, $D4, $2A; 14:5B10
    db $92, $00, $43, $00, $06, $50, $3B, $DB, $9B, $FF, $CC, $AB, $B8, $55, $48, $42; 14:5B20
    db $36, $75, $37, $B9, $88, $BC, $A8, $9A, $B8, $78, $AA, $87, $AC, $CB, $BE, $FF; 14:5B30
    db $D5, $8E, $80, $02, $50, $00, $22, $00, $6A, $86, $9E, $FC, $BC, $FF, $B7, $9A; 14:5B40
    db $85, $15, $64, $12, $57, $35, $7A, $97, $9C, $BA, $9A, $DB, $99, $BC, $B9, $BD; 14:5B50
    db $FE, $84, $FC, $21, $28, $10, $03, $10, $03, $85, $56, $BD, $C8, $ED, $FA, $9B; 14:5B60
    db $C8, $66, $88, $24, $56, $33, $48, $66, $69, $A9, $8B, $BB, $AA, $CB, $BB, $DD; 14:5B70
    db $EE, $E5, $7F, $41, $35, $30, $01, $10, $10, $96, $56, $CD, $B8, $DF, $BC, $7D; 14:5B80
    db $A9, $48, $68, $24, $65, $33, $57, $65, $88, $B8, $AB, $CA, $BB, $DB, $BC, $DD; 14:5B90
    db $EE, $85, $F8, $05, $44, $00, $01, $01, $07, $64, $5A, $DA, $AD, $FB, $E9, $DA; 14:5BA0
    db $A5, $96, $72, $54, $33, $36, $55, $5A, $8A, $8D, $BC, $AD, $DD, $BD, $EE, $ED; 14:5BB0
    db $86, $F4, $14, $52, $00, $10, $01, $08, $45, $7D, $B9, $AF, $EA, $CA, $D8, $86; 14:5BC0
    db $96, $51, $53, $31, $45, $55, $79, $99, $BD, $CD, $DF, $ED, $DF, $FE, $C5, $BF; 14:5BD0
    db $03, $35, $00, $00, $00, $03, $81, $69, $F9, $BE, $FB, $EB, $FC, $87, $89, $42; 14:5BE0
    db $35, $01, $05, $23, $59, $89, $AE, $DD, $EF, $FE, $EF, $FF, $B5, $FB, $04, $34; 14:5BF0
    db $00, $00, $00, $07, $53, $7C, $E8, $CF, $FB, $DC, $F9, $97, $A6, $41, $63, $00; 14:5C00
    db $45, $24, $89, $89, $CE, $CE, $EF, $EE, $FF, $F8, $7F, $60, $35, $20, $00, $00; 14:5C10
    db $00, $72, $47, $FC, $AD, $FF, $DD, $EE, $98, $89, $52, $25, $00, $05, $32, $59; 14:5C20
    db $98, $AE, $ED, $EF, $FF, $FF, $F7, $BF, $33, $34, $00, $00, $00, $02, $53, $68; 14:5C30
    db $EA, $CE, $FD, $EC, $EB, $A7, $88, $41, $43, $00, $34, $35, $79, $AA, $CF, $EF; 14:5C40
    db $FF, $FF, $FD, $7F, $A1, $44, $30, $00, $00, $00, $52, $56, $CC, $9E, $FE, $CE; 14:5C50
    db $ED, $89, $78, $42, $25, $00, $15, $34, $79, $A9, $BE, $FE, $FF, $FF, $FB, $BF; 14:5C60
    db $62, $55, $00, $00, $00, $01, $52, $58, $EA, $BF, $FD, $DE, $EB, $88, $76, $21; 14:5C70
    db $22, $00, $35, $35, $8A, $9B, $DF, $EF, $FF, $FF, $AC, $F5, $25, $60, $00, $00; 14:5C80
    db $00, $25, $25, $AF, $9B, $FF, $DD, $EF, $A8, $78, $52, $13, $20, $04, $53, $59; 14:5C90
    db $BA, $BE, $FE, $FF, $FF, $AB, $F8, $23, $71, $00, $00, $00, $16, $34, $8F, $BA; 14:5CA0
    db $EF, $EC, $CE, $B8, $78, $72, $12, $40, $04, $64, $58, $BB, $BD, $FF, $FF, $FF; 14:5CB0
    db $8E, $F5, $44, $50, $00, $00, $00, $45, $55, $BE, $AB, $FF, $DC, $DD, $A8, $67; 14:5CC0
    db $53, $13, $31, $15, $55, $7A, $BB, $CE, $FF, $FF, $FA, $DF, $64, $56, $00, $00; 14:5CD0
    db $00, $02, $54, $59, $EA, $BE, $FC, $CC, $C9, $97, $75, $32, $44, $22, $56, $57; 14:5CE0
    db $9B, $AC, $DF, $FF, $FF, $9C, $F6, $45, $70, $00, $00, $00, $35, $55, $8E, $AA; 14:5CF0
    db $DE, $BB, $BC, $88, $66, $54, $24, $53, $37, $86, $8A, $BB, $CD, $EF, $FF, $E8; 14:5D00
    db $DE, $34, $56, $00, $10, $00, $05, $56, $6A, $E9, $AD, $EA, $AB, $B7, $75, $55; 14:5D10
    db $32, $55, $45, $89, $89, $BC, $CC, $DE, $FF, $FB, $7F, $81, $36, $30, $01, $00; 14:5D20
    db $02, $76, $77, $ED, $AB, $EC, $A9, $B9, $76, $45, $42, $26, $55, $6A, $99, $AC; 14:5D30
    db $CC, $CD, $EF, $FD, $6D, $F1, $24, $70, $01, $10, $00, $67, $76, $BF, $AA, $CE; 14:5D40
    db $A8, $8A, $67, $34, $54, $15, $76, $58, $B9, $AB, $DC, $DC, $EF, $FF, $78, $F5; 14:5D50
    db $02, $71, $00, $11, $10, $39, $87, $6F, $C9, $9E, $B9, $79, $77, $42, $56, $32; 14:5D60
    db $78, $76, $BA, $BA, $CC, $DC, $CE, $FF, $85, $F9, $01, $65, $00, $02, $21, $1A; 14:5D70
    db $A9, $5E, $FA, $8C, $C9, $76, $77, $61, $46, $51, $68, $86, $9A, $BB, $BC, $DE; 14:5D80
    db $CE, $FF, $93, $FC, $00, $46, $00, $01, $33, $08, $BB, $4C, $FC, $9A, $BA, $85; 14:5D90
    db $56, $81, $25, $72, $57, $98, $99, $BC, $BB, $CE, $DD, $FF, $93, $FB, $10, $45; 14:5DA0
    db $00, $00, $44, $07, $CC, $5B, $FC, $99, $99, $95, $45, $82, $25, $84, $57, $99; 14:5DB0
    db $A9, $9C, $BA, $BE, $DD, $FF, $B2, $FC, $11, $35, $00, $00, $46, $06, $BD, $6A; 14:5DC0
    db $FC, $A9, $88, $96, $34, $94, $24, $85, $77, $89, $BA, $8B, $CA, $9C, $DD, $EF; 14:5DD0
    db $D3, $BF, $21, $16, $00, $00, $37, $24, $AE, $97, $EC, $B9, $86, $97, $31, $86; 14:5DE0
    db $23, $77, $78, $88, $BC, $79, $CB, $9B, $CD, $EF, $F8, $5F, $71, $14, $30, $00; 14:5DF0
    db $06, $61, $8C, $D6, $BD, $C9, $96, $88, $52, $48, $43, $58, $68, $88, $9C, $97; 14:5E00
    db $AB, $99, $BC, $DF, $FE, $5A, $F3, $20, $50, $00, $02, $83, $2A, $EB, $7D, $CB; 14:5E10
    db $98, $58, $85, $15, $74, $47, $68, $98, $8A, $D8, $8A, $B9, $AB, $CD, $FF, $D4; 14:5E20
    db $BF, $31, $04, $00, $00, $28, $33, $9E, $B8, $CB, $BA, $84, $77, $51, $57, $55; 14:5E30
    db $76, $9A, $98, $AC, $98, $9A, $AB, $AB, $DF, $FF, $78, $F5, $20, $21, $00, $00; 14:5E40
    db $76, $38, $BE, $9C, $BB, $BA, $56, $76, $23, $65, $67, $67, $A9, $98, $BA, $99; 14:5E50
    db $89, $BB, $BC, $FF, $FE, $5C, $E4, $10, $20, $00, $00, $95, $58, $DD, $BD, $AB; 14:5E60
    db $BA, $46, $66, $24, $45, $78, $58, $BB, $98, $A8, $88, $77, $AB, $BC, $FF, $FF; 14:5E70
    db $78, $F7, $20, $00, $00, $00, $67, $57, $BF, $DE, $AB, $BC, $65, $46, $44, $34; 14:5E80
    db $78, $87, $9A, $B9, $87, $88, $76, $79, $BC, $DF, $FF, $F9, $6E, $83, $00, $00; 14:5E90
    db $00, $03, $87, $8A, $FE, $FC, $BA, $B8, $52, $43, $44, $36, $8A, $99, $AB, $A9; 14:5EA0
    db $77, $67, $76, $7A, $CE, $FF, $FF, $F9, $6C, $62, $00, $00, $00, $01, $8B, $BB; 14:5EB0
    db $FF, $FF, $B8, $97, $61, $10, $45, $55, $7B, $CB, $AA, $AA, $75, $45, $66, $68; 14:5EC0
    db $BE, $FF, $FF, $FF, $F3, $77, $20, $00, $00, $00, $08, $CF, $EF, $FF, $FE, $75; 14:5ED0
    db $55, $10, $00, $46, $77, $AD, $EC, $CA, $97, $74, $33, $56, $89, $BE, $FF, $FF; 14:5EE0
    db $FF, $F9, $05, $00, $00, $00, $02, $05, $BF, $FF, $FE, $FE, $C4, $10, $00, $00; 14:5EF0
    db $14, $9C, $DD, $EF, $FC, $96, $33, $22, $13, $69, $BD, $EF, $FF, $FF, $FF, $F9; 14:5F00
    db $00, $00, $00, $00, $27, $78, $DF, $FF, $FB, $B9, $72, $00, $00, $22, $58, $BF; 14:5F10
    db $FF, $FE, $CA, $74, $00, $01, $25, $7A, $DF, $FF, $FF, $FF, $EC, $BD, $F4, $00; 14:5F20
    db $00, $00, $00, $5A, $AB, $BC, $FF, $E7, $52, $43, $10, $02, $79, $BA, $BE, $FF; 14:5F30
    db $D9, $74, $42, $00, $03, $79, $BC, $DF, $FF, $CB, $9A, $AA, $AB, $EF, $A0, $52; 14:5F40
    db $22, $00, $00, $57, $99, $8C, $EF, $B9, $45, $55, $22, $03, $6A, $BA, $BC, $DE; 14:5F50
    db $CA, $64, $43, $42, $24, $69, $BC, $BB, $BD, $CB, $AA, $BC, $EE, $FF, $F6, $13; 14:5F60
    db $00, $00, $00, $06, $8D, $CC, $CF, $FB, $83, $21, $32, $10, $37, $BD, $ED, $DE; 14:5F70
    db $EC, $A6, $30, $11, $23, $56, $9C, $EE, $DC, $BB, $BA, $98, $89, $BC, $EF, $FB; 14:5F80
    db $14, $00, $00, $00, $02, $7B, $EB, $BD, $FB, $C7, $20, $11, $12, $54, $7D, $FF; 14:5F90
    db $FE, $CB, $B9, $63, $10, $03, $67, $AA, $BD, $FD, $BA, $87, $88, $88, $9A, $CF; 14:5FA0
    db $FF, $F8, $22, $00, $00, $00, $03, $8F, $FD, $DD, $BD, $B4, $00, $00, $36, $66; 14:5FB0
    db $AB, $FF, $FF, $DA, $75, $53, $00, $01, $6A, $CD, $DC, $CC, $C9, $86, $45, $79; 14:5FC0
    db $AC, $DE, $FF, $FF, $A2, $00, $00, $00, $00, $19, $FF, $FF, $B7, $99, $43, $00; 14:5FD0
    db $00, $59, $DE, $DF, $FF, $FF, $94, $10, $01, $32, $36, $7B, $FF, $EC, $87, $66; 14:5FE0
    db $65, $55, $7A, $CF, $FF, $FF, $FF, $F8, $10, $00, $00, $13, $13, $9E, $FF, $FA; 14:5FF0
    db $55, $10, $30, $00, $14, $AF, $FF, $FE, $BD, $B8, $72, $00, $02, $69, $AB, $CB; 14:6000
    db $BD, $C9, $84, $23, $56, $99, $AB, $CE, $FF, $FE, $CB, $DC, $52, $00, $00, $05; 14:6010
    db $53, $67, $AE, $FF, $B8, $40, $24, $25, $41, $68, $BF, $FF, $DB, $97, $87, $45; 14:6020
    db $20, $35, $7B, $CB, $A9, $87, $87, $66, $55, $89, $BE, $DD, $DC, $CC, $BA, $9A; 14:6030
    db $AB, $93, $20, $00, $02, $63, $57, $7B, $EF, $EA, $83, $13, $24, $63, $57, $7B; 14:6040
    db $EF, $FE, $B9, $66, $55, $53, $34, $48, $BC, $EC, $98, $55, $56, $66, $77, $8A; 14:6050
    db $CD, $EC, $CB, $9A, $A9, $99, $AC, $B6, $60, $00, $00, $53, $47, $68, $CD, $DC; 14:6060
    db $A6, $33, $23, $55, $68, $79, $CC, $FF, $CB, $96, $55, $44, $55, $57, $89, $CB; 14:6070
    db $BA, $75, $54, $67, $89, $99, $AB, $CC, $DB, $A9, $88, $98, $9A, $AC, $B6, $60; 14:6080
    db $00, $00, $52, $57, $59, $CB, $FE, $B8, $42, $11, $44, $78, $7A, $BB, $FF, $EE; 14:6090
    db $A7, $63, $34, $45, $56, $68, $AA, $CC, $98, $65, $66, $79, $99, $98, $9A, $BB; 14:60A0
    db $BB, $A9, $98, $9A, $AB, $BB, $75, $20, $00, $05, $44, $86, $6A, $9B, $DA, $86; 14:60B0
    db $32, $24, $68, $AA, $BB, $AC, $DB, $DA, $76, $42, $44, $57, $78, $89, $AA, $BA; 14:60C0
    db $98, $55, $44, $78, $9A, $A9, $AA, $BC, $BB, $A8, $77, $78, $99, $AB, $B8, $73; 14:60D0
    db $00, $00, $53, $48, $46, $98, $CD, $BB, $96, $54, $55, $78, $89, $98, $AA, $AD; 14:60E0
    db $BA, $96, $55, $46, $78, $88, $87, $89, $99, $87, $76, $68, $89, $99, $98, $8A; 14:60F0
    db $AA, $BA, $A9, $98, $89, $99, $AB, $A7, $61, $00, $00, $52, $56, $36, $77, $BB; 14:6100
    db $BB, $97, $66, $78, $A9, $99, $77, $87, $99, $88, $65, $66, $89, $AA, $AA, $88; 14:6110
    db $87, $77, $56, $55, $77, $9A, $9A, $99, $AA, $BB, $BA, $AA, $99, $99, $88, $8A; 14:6120
    db $B8, $54, $00, $00, $24, $25, $43, $67, $9C, $BA, $98, $67, $88, $AB, $88, $86; 14:6130
    db $88, $89, $76, $66, $78, $9A, $BA, $99, $98, $99, $88, $65, $55, $68, $88, $88; 14:6140
    db $89, $9A, $AA, $BB, $AA, $AA, $A9, $99, $88, $9A, $95, $51, $00, $00, $31, $13; 14:6150
    db $25, $78, $AA, $A9, $88, $7A, $A9, $B9, $89, $89, $A9, $97, $76, $78, $89, $87; 14:6160
    db $98, $8A, $9A, $A9, $87, $76, $66, $67, $66, $77, $89, $9B, $BB, $BB, $BA, $AA; 14:6170
    db $99, $99, $98, $89, $98, $55, $10, $20, $02, $00, $11, $55, $89, $9A, $8B, $A9; 14:6180
    db $DB, $BC, $9A, $AA, $A9, $97, $77, $68, $76, $86, $68, $88, $99, $99, $98, $88; 14:6190
    db $78, $77, $76, $67, $78, $99, $AA, $AA, $BB, $BB, $AA, $A9, $99, $89, $99, $54; 14:61A0
    db $40, $02, $00, $10, $00, $24, $58, $79, $89, $CA, $DD, $BC, $BB, $BB, $BA, $A8; 14:61B0
    db $78, $77, $75, $66, $56, $77, $78, $88, $98, $89, $88, $88, $88, $88, $88, $99; 14:61C0
    db $99, $9A, $AB, $BB, $AA, $A9, $99, $99, $99, $64, $50, $04, $00, $10, $00, $23; 14:61D0
    db $46, $68, $88, $CA, $CE, $BC, $CB, $CC, $CA, $A9, $88, $76, $75, $66, $56, $66; 14:61E0
    db $77, $88, $88, $88, $89, $98, $88, $78, $89, $99, $99, $AA, $BB, $AB, $AA, $A9; 14:61F0
    db $99, $89, $AA, $64, $60, $04, $00, $00, $00, $23, $46, $58, $79, $CA, $DD, $BC; 14:6200
    db $DC, $CC, $BA, $A9, $88, $77, $65, $76, $56, $66, $77, $77, $87, $88, $89, $98; 14:6210
    db $88, $89, $99, $99, $9A, $AA, $BA, $AA, $AA, $A9, $99, $99, $A9, $45, $40, $23; 14:6220
    db $00, $00, $01, $33, $55, $68, $7B, $BA, $DC, $BD, $DC, $BC, $A9, $A9, $88, $67; 14:6230
    db $66, $76, $56, $66, $78, $78, $87, $89, $99, $98, $98, $99, $88, $89, $9A, $AA; 14:6240
    db $AA, $AB, $AA, $A9, $99, $9A, $A7, $45, $20, $41, $01, $00, $02, $33, $55, $78; 14:6250
    db $8C, $AB, $DB, $CE, $DC, $CC, $AB, $A8, $87, $66, $66, $65, $56, $66, $88, $78; 14:6260
    db $78, $99, $99, $89, $99, $99, $98, $99, $9A, $A9, $AA, $AA, $AA, $99, $99, $9B; 14:6270
    db $95, $54, $03, $30, $00, $00, $23, $35, $46, $89, $CC, $AC, $CC, $EE, $BA, $A9; 14:6280
    db $9A, $75, $54, $78, $77, $65, $78, $99, $97, $89, $9A, $98, $88, $88, $76, $77; 14:6290
    db $89, $99, $AB, $BC, $BA, $A9, $99, $88, $9A, $C6, $00, $00, $50, $02, $25, $A9; 14:62A0
    db $77, $57, $B9, $89, $8A, $EC, $A9, $66, $77, $56, $78, $BB, $AB, $9A, $A8, $76; 14:62B0
    db $78, $99, $78, $76, $76, $67, $89, $99, $9A, $BB, $BA, $AB, $BB, $A8, $88, $88; 14:62C0
    db $76, $7A, $DA, $00, $00, $65, $15, $38, $B8, $62, $44, $89, $69, $AB, $FD, $98; 14:62D0
    db $75, $77, $67, $9A, $CB, $99, $88, $86, $56, $79, $AA, $87, $76, $66, $68, $9A; 14:62E0
    db $A9, $89, $AA, $AA, $AB, $BB, $A8, $88, $89, $89, $8A, $DD, $30, $00, $08, $15; 14:62F0
    db $55, $B8, $62, $13, $5A, $88, $CB, $EF, $A7, $65, $57, $77, $AB, $BB, $97, $76; 14:6300
    db $78, $77, $9A, $AA, $86, $65, $56, $67, $99, $A9, $88, $89, $AB, $BB, $CB, $A9; 14:6310
    db $87, $89, $99, $89, $DD, $00, $00, $18, $26, $56, $A9, $61, $23, $6B, $89, $CB; 14:6320
    db $ED, $85, $54, $58, $88, $BB, $BB, $86, $66, $88, $88, $9A, $A9, $75, $55, $68; 14:6330
    db $88, $9A, $98, $87, $9A, $BC, $BB, $CB, $A8, $77, $8A, $AA, $CE, $90, $00, $06; 14:6340
    db $54, $75, $98, $73, $02, $38, $B9, $BB, $BD, $A6, $34, $56, $AA, $AC, $BA, $96; 14:6350
    db $56, $78, $9A, $9A, $A8, $75, $45, $68, $99, $99, $98, $77, $8A, $BC, $CC, $BB; 14:6360
    db $A9, $77, $89, $AC, $ED, $10, $00, $08, $36, $78, $98, $50, $02, $5B, $AA, $CC; 14:6370
    db $CB, $73, $35, $59, $A9, $CC, $B9, $75, $57, $89, $AA, $BB, $86, $43, $46, $89; 14:6380
    db $AA, $99, $87, $78, $9B, $CD, $CC, $BA, $98, $88, $9C, $ED, $10, $00, $28, $46; 14:6390
    db $58, $A8, $50, $02, $6B, $AA, $BC, $CA, $72, $25, $69, $A9, $BD, $CA, $75, $57; 14:63A0
    db $89, $AA, $AB, $96, $43, $46, $88, $99, $99, $98, $88, $9B, $CC, $BB, $BB, $A9; 14:63B0
    db $AA, $BF, $D0, $00, $03, $A6, $55, $88, $84, $00, $28, $CB, $99, $AB, $A7, $23; 14:63C0
    db $67, $AB, $AA, $CB, $98, $65, $8B, $BB, $A9, $88, $64, $46, $8A, $A8, $77, $88; 14:63D0
    db $88, $9B, $CD, $CA, $AA, $AB, $BB, $EF, $60, $00, $09, $86, $57, $87, $70, $01; 14:63E0
    db $5B, $DB, $AA, $B9, $82, $14, $69, $BB, $AB, $B9, $76, $47, $BC, $CB, $A8, $86; 14:63F0
    db $44, $57, $AB, $99, $88, $99, $89, $AC, $DD, $BA, $AB, $CD, $FD, $00, $00, $39; 14:6400
    db $65, $59, $77, $30, $05, $AD, $BA, $9B, $A8, $51, $36, $89, $A9, $9A, $A7, $66; 14:6410
    db $69, $BB, $AA, $98, $86, $55, $78, $98, $78, $89, $AA, $AB, $DD, $CB, $AB, $DD; 14:6420
    db $FF, $90, $00, $08, $85, $28, $97, $60, $01, $8D, $DB, $9B, $DA, $82, $04, $89; 14:6430
    db $9A, $89, $B8, $54, $48, $BC, $A9, $99, $97, $44, $79, $A9, $77, $8A, $AA, $9B; 14:6440
    db $DF, $EC, $BC, $DF, $FF, $00, $00, $7A, $50, $3A, $66, $00, $07, $EE, $B8, $8D; 14:6450
    db $B8, $40, $49, $B9, $97, $8B, $95, $44, $7B, $DB, $89, $89, $85, $46, $9A, $96; 14:6460
    db $57, $8A, $99, $AD, $EE, $DD, $DF, $FF, $00, $00, $8C, $81, $3B, $76, $00, $06; 14:6470
    db $EF, $C9, $8C, $A7, $20, $4A, $DB, $A7, $7A, $94, $35, $8B, $EA, $89, $99, $75; 14:6480
    db $57, $BB, $A7, $67, $78, $89, $AD, $EE, $DD, $DF, $F3, $00, $04, $EC, $41, $B7; 14:6490
    db $62, $00, $4C, $FD, $B8, $DB, $73, $02, $8D, $BA, $98, $A9, $41, $37, $AD, $B7; 14:64A0
    db $99, $98, $65, $7B, $BB, $98, $88, $99, $AB, $CE, $ED, $FF, $F4, $00, $03, $BB; 14:64B0
    db $63, $C8, $50, $00, $3B, $EC, $C9, $DB, $72, $03, $8D, $BA, $A9, $BA, $42, $47; 14:64C0
    db $AC, $A8, $99, $86, $55, $8B, $BA, $98, $99, $99, $AC, $EF, $EE, $FF, $C0, $00; 14:64D0
    db $0A, $A6, $1D, $C8, $30, $00, $8C, $9B, $AE, $F8, $30, $16, $AA, $9A, $BC, $C5; 14:64E0
    db $12, $79, $BB, $8A, $CA, $64, $46, $AB, $A9, $9A, $AA, $99, $BD, $FF, $FF, $F0; 14:64F0
    db $00, $06, $87, $0B, $E8, $50, $00, $6A, $7A, $BD, $FA, $50, $15, $88, $6A, $CD; 14:6500
    db $D7, $22, $78, $89, $8A, $CB, $86, $66, $8A, $99, $AA, $BA, $AA, $BC, $DE, $FF; 14:6510
    db $F0, $00, $05, $77, $08, $F9, $50, $00, $69, $58, $CD, $FB, $50, $25, $77, $58; 14:6520
    db $CD, $D8, $33, $78, $78, $89, $CB, $86, $78, $89, $99, $AB, $A9, $AA, $CE, $EF; 14:6530
    db $FF, $F0, $00, $06, $66, $0D, $F8, $20, $00, $79, $39, $DF, $F9, $40, $45, $55; 14:6540
    db $5B, $ED, $B6, $54, $76, $57, $AB, $CA, $76, $87, $78, $9B, $CB, $98, $AA, $BC; 14:6550
    db $DF, $FF, $F0, $00, $03, $35, $19, $FB, $30, $00, $56, $26, $FF, $FA, $63, $56; 14:6560
    db $32, $5A, $ED, $B8, $77, $75, $24, $9B, $BA, $87, $87, $55, $8A, $BB, $A9, $BB; 14:6570
    db $AB, $CF, $FF, $FA, $00, $00, $11, $35, $FF, $50, $11, $22, $23, $EF, $FB, $98; 14:6580
    db $66, $20, $38, $CC, $BB, $BA, $75, $34, $79, $9A, $BB, $98, $55, $78, $99, $AB; 14:6590
    db $BB, $9A, $BD, $FF, $FF, $50, $00, $00, $12, $7F, $C3, $24, $21, $11, $4E, $ED; 14:65A0
    db $BC, $B7, $51, $15, $89, $9B, $CC, $B8, $65, $66, $67, $AB, $B9, $87, $77, $77; 14:65B0
    db $9B, $AA, $AA, $BC, $CD, $FF, $FF, $00, $11, $00, $33, $CF, $61, $67, $20, $12; 14:65C0
    db $8E, $A9, $CF, $B7, $43, $36, $55, $8C, $CB, $A9, $88, $64, $47, $A9, $99, $A9; 14:65D0
    db $87, $68, $99, $9A, $BB, $BC, $CD, $EF, $FF, $A0, $04, $00, $04, $5D, $B3, $5B; 14:65E0
    db $70, $03, $37, $87, $BF, $FA, $79, $84, $33, $48, $A9, $9D, $DA, $76, $55, $66; 14:65F0
    db $68, $BA, $99, $88, $77, $78, $AA, $AB, $CC, $CD, $FF, $FF, $00, $53, $00, $14; 14:6600
    db $7C, $74, $BE, $20, $26, $24, $58, $DF, $D9, $CE, $72, $34, $56, $66, $BE, $B8; 14:6610
    db $9A, $85, $55, $68, $77, $9B, $A8, $99, $98, $88, $9A, $AB, $CE, $FF, $FF, $B0; 14:6620
    db $05, $00, $04, $38, $75, $8F, $91, $38, $52, $35, $8B, $B8, $CF, $D7, $8A, $74; 14:6630
    db $33, $58, $76, $9D, $C9, $8A, $97, $55, $78, $87, $9B, $A8, $89, $A9, $9A, $CC; 14:6640
    db $CC, $CC, $EF, $B0, $2A, $10, $03, $02, $12, $8F, $C5, $AF, $B2, $25, $54, $33; 14:6650
    db $9E, $C8, $CF, $E8, $77, $86, $21, $58, $75, $9D, $CA, $9A, $B8, $54, $77, $55; 14:6660
    db $8B, $BB, $CD, $DB, $AA, $BB, $9B, $FF, $30, $B6, $00, $02, $02, $06, $CF, $88; 14:6670
    db $FF, $63, $56, $20, $03, $98, $79, $FF, $CB, $DC, $85, $34, $53, $24, $89, $8A; 14:6680
    db $CC, $A9, $99, $75, $57, $87, $79, $BB, $AB, $CC, $BB, $BC, $BA, $DF, $10, $A3; 14:6690
    db $00, $02, $02, $17, $BC, $9A, $FD, $66, $87, $10, $23, $64, $6A, $FD, $AD, $FD; 14:66A0
    db $98, $77, $53, $25, $65, $69, $A9, $AB, $BA, $88, $88, $65, $79, $88, $9B, $BA; 14:66B0
    db $AB, $BB, $AA, $BB, $AC, $D1, $09, $20, $01, $20, $13, $6B, $8A, $BF, $C7, $AA; 14:66C0
    db $72, $24, $45, $36, $BC, $AA, $FF, $BA, $BB, $86, $56, $64, $35, $87, $58, $BA; 14:66D0
    db $89, $AA, $97, $78, $86, $68, $98, $8A, $BB, $BB, $BB, $A9, $89, $88, $9B, $20; 14:66E0
    db $C5, $00, $25, $00, $33, $94, $6A, $EC, $5D, $DA, $76, $A7, $64, $5A, $86, $7C; 14:66F0
    db $C8, $9B, $C9, $78, $88, $55, $77, $75, $78, $87, $8A, $98, $88, $98, $88, $88; 14:6700
    db $78, $99, $89, $BA, $AA, $AA, $99, $98, $78, $89, $A0, $1D, $20, $14, $40, $15; 14:6710
    db $59, $47, $ED, $A7, $ED, $77, $6A, $64, $55, $A5, $58, $BB, $7A, $CB, $98, $A9; 14:6720
    db $86, $79, $76, $68, $75, $67, $87, $79, $98, $89, $A9, $88, $AA, $88, $9A, $98; 14:6730
    db $99, $97, $88, $87, $67, $77, $8A, $60, $8A, $00, $43, $10, $45, $66, $4A, $D9; 14:6740
    db $8B, $EA, $8A, $9A, $76, $78, $83, $79, $87, $8B, $B9, $AA, $B9, $88, $99, $66; 14:6750
    db $66, $54, $67, $77, $89, $88, $9A, $A9, $9A, $A9, $89, $98, $78, $87, $77, $87; 14:6760
    db $77, $77, $66, $67, $77, $9A, $24, $C4, $05, $53, $13, $45, $75, $7B, $B8, $AD; 14:6770
    db $B9, $AB, $A9, $87, $88, $65, $88, $67, $89, $88, $99, $A8, $99, $98, $78, $76; 14:6780
    db $56, $76, $67, $88, $89, $9A, $99, $99, $88, $88, $87, $78, $77, $77, $77, $77; 14:6790
    db $77, $77, $77, $77, $89, $89, $94, $8A, $42, $66, $32, $44, $55, $47, $99, $7A; 14:67A0
    db $DB, $AB, $CB, $98, $89, $85, $67, $75, $68, $88, $8A, $AA, $99, $A9, $87, $77; 14:67B0
    db $66, $66, $76, $78, $88, $9A, $A9, $99, $98, $88, $77, $77, $77, $77, $77, $77; 14:67C0
    db $77, $76, $77, $76, $67, $77, $78, $89, $75, $89, $54, $67, $54, $56, $77, $67; 14:67D0
    db $AA, $89, $BB, $AA, $AA, $A8, $88, $87, $67, $87, $78, $88, $77, $88, $87, $88; 14:67E0
    db $87, $78, $88, $88, $88, $89, $99, $98, $99, $88, $88, $77, $76, $66, $66, $66; 14:67F0
    db $66, $77, $67, $77, $77, $77, $77, $77, $77, $77, $78, $78, $88, $88, $88, $88; 14:6800
    db $66, $77, $66, $66, $67, $77, $88, $88, $99, $99, $99, $99, $99, $98, $88, $88; 14:6810
    db $88, $88, $88, $88, $88, $88, $88, $78, $88, $88, $88, $88, $88, $77, $77, $76; 14:6820
    db $66, $66, $67, $77, $77, $77, $77, $78, $87, $78, $87, $77, $77, $77, $67, $77; 14:6830
    db $78, $88, $88, $88, $89, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:6840
    db $88, $88, $88, $87, $78, $77, $77, $77, $77, $87, $77, $77, $77, $87, $77, $77; 14:6850
    db $77, $77, $88, $78, $78, $88, $78, $87, $77, $77, $77, $77, $87, $87, $88, $78; 14:6860
    db $88, $88, $88, $88, $77, $88, $77, $78, $77, $77, $78, $88, $88, $88, $88, $88; 14:6870
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77; 14:6880
    db $77, $77, $88, $88, $88, $88, $88, $88, $88, $78, $88, $87, $78, $88, $77, $88; 14:6890
    db $77, $78, $87, $87, $88, $87, $78, $88, $88, $88, $88, $88, $88, $88, $87, $87; 14:68A0
    db $88, $78, $78, $78, $88, $87, $88, $78, $77, $87, $87, $88, $88, $88, $88, $87; 14:68B0
    db $88, $78, $78, $78, $87, $78, $77, $88, $77, $88, $88, $87, $77, $77, $77, $78; 14:68C0
    db $88, $88, $88, $88, $88, $88, $87, $87, $78, $77, $88, $88, $88, $88, $88, $88; 14:68D0
    db $87, $88, $78, $87, $87, $88, $78, $88, $88, $88, $88, $88, $78, $78, $87, $77; 14:68E0
    db $88, $78, $78, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $78, $88, $88; 14:68F0
    db $88, $88, $88, $88, $88, $87, $88, $87, $87, $88, $88, $87, $87, $88, $78, $88; 14:6900
    db $78, $88, $88, $88, $87, $87, $87, $87, $87, $87, $87, $78, $88, $87, $88, $88; 14:6910
    db $88, $78, $77, $87, $87, $87, $78, $78, $87, $87, $87, $87, $88, $77, $87, $87; 14:6920
    db $78, $78, $78, $78, $88, $88, $88, $88, $88, $88, $88, $78, $78, $88, $88, $88; 14:6930
    db $88, $78, $77, $77, $77, $77, $77, $77, $77, $77, $87, $88, $88, $88, $88, $88; 14:6940
    db $78, $88, $88, $88, $88, $87, $87, $87, $87, $87, $87, $78, $78, $78, $88, $78; 14:6950
    db $88, $88, $88, $88, $88, $87, $88, $88, $88, $88, $78, $88, $88, $88, $78, $88; 14:6960
    db $78, $78, $78, $78, $77, $78, $77, $77, $87, $77, $88, $88, $78, $88, $88, $78; 14:6970
    db $78, $88, $78, $78, $77, $87, $87, $88, $88, $88, $88, $88, $78, $88, $78, $88; 14:6980
    db $88, $88, $88, $88, $88, $88, $88, $87, $77, $87, $87, $77, $87, $87, $87, $87; 14:6990
    db $78, $78, $77, $87, $87, $87, $77, $77, $78, $87, $87, $88, $87, $88, $88, $88; 14:69A0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $88, $87, $88, $78; 14:69B0
    db $78, $87, $87, $87, $87, $87, $78, $78, $87, $87, $78, $78, $77, $78, $88, $78; 14:69C0
    db $88, $87, $87, $87, $77, $78, $78, $78, $78, $87, $87, $87, $88, $88, $78, $88; 14:69D0
    db $88, $88, $88, $88, $88, $78, $88, $88, $88, $78, $78, $78, $78, $78, $88, $87; 14:69E0
    db $87, $88, $78, $78, $88, $87, $88, $88, $78, $78, $87, $87, $87, $77, $87, $77; 14:69F0
    db $78, $88, $88, $87, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $87, $88; 14:6A00
    db $87, $88, $88, $88, $88, $87, $87, $88, $78, $87, $87, $78, $78, $78, $78, $88; 14:6A10
    db $78, $78, $88, $88, $88, $88, $87, $78, $77, $78, $78, $77, $77, $87, $78, $88; 14:6A20
    db $78, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $87, $88; 14:6A30
    db $87, $88, $88, $88, $78, $87, $87, $88, $78, $78, $88, $77, $77, $87, $87, $87; 14:6A40
    db $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $78, $88, $78, $78, $88, $88; 14:6A50
    db $88, $88, $88, $88, $78, $87, $77, $87, $88, $88, $88, $88, $88, $78, $78, $78; 14:6A60
    db $87, $88, $78, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78; 14:6A70
    db $87, $88, $88, $78, $87, $88, $78, $78, $78, $87, $88, $88, $87, $87, $88, $88; 14:6A80
    db $88, $87, $88, $88, $88, $88, $88, $88, $88, $78, $77, $88, $77, $88, $87, $78; 14:6A90
    db $88, $88, $88, $77, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:6AA0
    db $88, $78, $88, $88, $88, $88, $88, $88, $78, $78, $77, $77, $77, $88, $78, $88; 14:6AB0
    db $88, $78, $78, $78, $77, $87, $88, $87, $88, $88, $88, $88, $88, $88, $88, $88; 14:6AC0
    db $88, $88, $88, $88, $88, $88, $88, $87, $87, $87, $87, $77, $87, $78, $77, $78; 14:6AD0
    db $78, $77, $77, $77, $77, $77, $87, $88, $78, $88, $88, $88, $88, $78, $78, $78; 14:6AE0
    db $88, $78, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:6AF0
    db $88, $88, $87, $88, $87, $87, $87, $77, $87, $77, $77, $77, $77, $77, $78, $78; 14:6B00
    db $78, $78, $88, $78, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:6B10
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $87, $78, $77, $77, $77, $77; 14:6B20
    db $78, $77, $77, $77, $88, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:6B30
    db $88, $88, $78, $88, $78, $88, $88, $88, $88, $88, $88, $88, $87, $88, $88, $87; 14:6B40
    db $88, $88, $88, $88, $88, $88, $87, $87, $88, $77, $77, $87, $87, $77, $77, $78; 14:6B50
    db $77, $78, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:6B60

;; PCM20: 3024 bytes = 6048 4-bit samples (rate 2) for SFXInst34
PCM20:
    db $88, $87, $87, $88, $78, $78, $88, $87, $77, $77, $88, $88, $88, $88, $88, $88; 14:6B70
    db $88, $88, $88, $88, $88, $88, $87, $87, $88, $88, $88, $88, $88, $88, $88, $88; 14:6B80
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $88; 14:6B90
    db $88, $77, $77, $77, $76, $66, $66, $66, $66, $77, $77, $78, $88, $89, $99, $99; 14:6BA0
    db $99, $99, $99, $99, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:6BB0
    db $87, $76, $65, $55, $44, $44, $44, $45, $67, $78, $89, $AA, $AB, $BB, $BA, $A9; 14:6BC0
    db $98, $87, $77, $66, $67, $77, $78, $88, $99, $9A, $99, $99, $99, $88, $88, $88; 14:6BD0
    db $88, $88, $88, $88, $87, $78, $89, $AB, $73, $43, $22, $21, $15, $54, $56, $78; 14:6BE0
    db $A8, $79, $99, $AA, $9A, $BA, $98, $88, $77, $66, $67, $88, $89, $9A, $A9, $88; 14:6BF0
    db $88, $88, $88, $89, $88, $88, $88, $88, $99, $9A, $A9, $99, $98, $88, $88, $89; 14:6C00
    db $C8, $00, $00, $22, $20, $69, $88, $56, $78, $97, $67, $9C, $BB, $99, $99, $85; 14:6C10
    db $56, $79, $88, $8A, $BA, $98, $88, $89, $88, $89, $99, $88, $88, $89, $88, $9A; 14:6C20
    db $AA, $AA, $AA, $A9, $98, $88, $88, $BF, $20, $00, $02, $62, $0A, $A8, $84, $22; 14:6C30
    db $89, $68, $8A, $DE, $C7, $66, $77, $67, $79, $CC, $A8, $98, $89, $87, $89, $99; 14:6C40
    db $98, $78, $98, $88, $99, $AA, $99, $9A, $AB, $BA, $A9, $99, $99, $AF, $90, $00; 14:6C50
    db $04, $95, $16, $A8, $97, $00, $49, $9B, $A8, $BC, $CA, $53, $46, $8A, $A8, $9B; 14:6C60
    db $A9, $97, $69, $A9, $9A, $88, $98, $67, $88, $99, $99, $9A, $AA, $AA, $BB, $BB; 14:6C70
    db $AA, $AB, $CF, $40, $00, $08, $95, $26, $86, $85, $00, $48, $DD, $BA, $89, $A8; 14:6C80
    db $52, $45, $8D, $B9, $99, $88, $97, $7A, $AB, $BA, $87, $87, $88, $88, $99, $99; 14:6C90
    db $9A, $AB, $BC, $CB, $BB, $BC, $FE, $00, $00, $6A, $93, $26, $56, $80, $02, $7E; 14:6CA0
    db $FD, $B6, $89, $97, $24, $56, $DC, $98, $76, $68, $76, $9B, $BC, $A8, $76, $78; 14:6CB0
    db $99, $99, $98, $98, $9A, $BC, $EE, $EC, $EF, $F0, $00, $04, $CC, $53, $66, $48; 14:6CC0
    db $00, $05, $EF, $FB, $77, $88, $72, $35, $8D, $EA, $76, $65, $76, $57, $AB, $CB; 14:6CD0
    db $86, $67, $78, $99, $AA, $98, $89, $AB, $CD, $EF, $FF, $00, $00, $5B, $B5, $59; 14:6CE0
    db $85, $60, $00, $7C, $EC, $A9, $BA, $84, $12, $79, $CC, $A8, $98, $75, $33, $8B; 14:6CF0
    db $CB, $A8, $88, $86, $78, $AB, $BA, $98, $AA, $CC, $DF, $F0, $00, $03, $9A, $44; 14:6D00
    db $99, $76, $00, $18, $AA, $AA, $9C, $B8, $42, $26, $8A, $98, $9A, $98, $54, $58; 14:6D10
    db $AB, $99, $9A, $98, $66, $8A, $BB, $BA, $BC, $CC, $DF, $A0, $00, $26, $98, $47; 14:6D20
    db $A6, $62, $00, $59, $99, $AA, $BC, $B6, $23, $46, $88, $88, $AB, $97, $54, $68; 14:6D30
    db $99, $9A, $AA, $98, $88, $9A, $99, $AB, $CC, $DD, $B1, $00, $13, $66, $58, $B9; 14:6D40
    db $86, $31, $36, $55, $89, $BD, $CA, $87, $54, $43, $47, $9A, $AA, $98, $77, $66; 14:6D50
    db $68, $9A, $AA, $AA, $A9, $88, $9A, $BB, $BB, $A7, $33, $23, $45, $55, $89, $77; 14:6D60
    db $65, $56, $65, $68, $89, $AA, $99, $98, $76, $55, $66, $66, $78, $89, $A9, $99; 14:6D70
    db $88, $77, $78, $AA, $BB, $BB, $BB, $A9, $98, $55, $54, $45, $55, $57, $77, $77; 14:6D80
    db $67, $76, $66, $77, $89, $98, $99, $87, $76, $77, $77, $67, $66, $77, $78, $99; 14:6D90
    db $9A, $99, $99, $98, $88, $99, $99, $88, $88, $77, $77, $77, $76, $66, $66, $66; 14:6DA0
    db $67, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77; 14:6DB0
    db $77, $78, $88, $88, $88, $88, $88, $88, $99, $99, $88, $88, $87, $77, $76, $66; 14:6DC0
    db $55, $66, $66, $77, $77, $77, $78, $88, $88, $99, $99, $99, $88, $88, $88, $88; 14:6DD0
    db $87, $77, $77, $77, $77, $88, $88, $88, $88, $88, $98, $88, $99, $88, $77, $66; 14:6DE0
    db $65, $56, $66, $66, $66, $67, $77, $77, $88, $88, $88, $99, $99, $88, $88, $88; 14:6DF0
    db $88, $88, $88, $87, $77, $77, $88, $88, $88, $88, $89, $99, $98, $89, $88, $87; 14:6E00
    db $66, $66, $66, $56, $66, $66, $66, $67, $77, $78, $88, $89, $99, $99, $98, $88; 14:6E10
    db $88, $88, $87, $77, $77, $77, $77, $88, $88, $88, $89, $99, $99, $98, $88, $88; 14:6E20
    db $87, $66, $66, $66, $56, $66, $66, $66, $67, $77, $88, $88, $89, $99, $99, $99; 14:6E30
    db $99, $98, $88, $88, $87, $77, $77, $77, $88, $88, $88, $88, $99, $99, $98, $88; 14:6E40
    db $88, $77, $65, $66, $66, $55, $56, $66, $66, $67, $77, $78, $88, $88, $99, $99; 14:6E50
    db $99, $99, $98, $88, $88, $88, $77, $77, $78, $78, $88, $88, $99, $99, $AA, $A9; 14:6E60
    db $78, $89, $87, $65, $56, $55, $55, $55, $56, $66, $66, $77, $78, $88, $88, $99; 14:6E70
    db $99, $99, $99, $88, $88, $88, $77, $77, $78, $88, $88, $88, $89, $99, $AA, $BB; 14:6E80
    db $97, $88, $87, $65, $44, $65, $54, $56, $66, $66, $67, $88, $77, $88, $89, $89; 14:6E90
    db $88, $88, $88, $88, $88, $78, $78, $88, $88, $88, $99, $99, $AA, $AA, $BB, $DC; 14:6EA0
    db $86, $78, $85, $33, $22, $54, $32, $67, $86, $76, $78, $89, $87, $89, $88, $89; 14:6EB0
    db $88, $88, $88, $78, $78, $78, $78, $88, $88, $99, $99, $AA, $BB, $BC, $DE, $E7; 14:6EC0
    db $46, $87, $20, $11, $05, $33, $26, $9A, $68, $89, $98, $87, $77, $97, $76, $88; 14:6ED0
    db $86, $87, $88, $77, $77, $87, $88, $88, $9B, $AB, $BC, $CE, $EF, $FF, $A0, $36; 14:6EE0
    db $70, $00, $10, $44, $34, $9E, $D9, $7B, $BB, $65, $45, $58, $44, $59, $B8, $59; 14:6EF0
    db $BB, $97, $76, $77, $65, $89, $BA, $AC, $EE, $EE, $FF, $FE, $00, $58, $00, $00; 14:6F00
    db $12, $42, $5A, $FF, $C6, $BE, $D5, $12, $54, $53, $24, $AD, $A6, $9E, $DA, $67; 14:6F10
    db $77, $55, $47, $9C, $BB, $CF, $FF, $FF, $FD, $00, $46, $00, $01, $13, $35, $8B; 14:6F20
    db $FF, $C7, $BE, $C3, $01, $52, $31, $46, $9B, $B9, $BD, $DA, $66, $75, $44, $58; 14:6F30
    db $AC, $CD, $FF, $FF, $FF, $40, $27, $00, $00, $32, $02, $9E, $FF, $FA, $BD, $E6; 14:6F40
    db $00, $45, $20, $27, $BA, $BA, $CD, $EB, $85, $66, $52, $37, $AB, $BD, $FF, $FF; 14:6F50
    db $FF, $30, $26, $00, $00, $23, $03, $BF, $FF, $FC, $AB, $C6, $00, $25, $30, $27; 14:6F60
    db $CC, $CB, $DD, $DB, $85, $44, $53, $46, $AC, $DD, $FF, $FF, $FF, $20, $16, $00; 14:6F70
    db $00, $55, $13, $BF, $FF, $EB, $89, $A5, $00, $06, $51, $29, $EE, $BB, $CC, $B8; 14:6F80
    db $64, $23, $55, $57, $BE, $EE, $FF, $FF, $FF, $10, $06, $20, $00, $7A, $34, $CF; 14:6F90
    db $FF, $CB, $76, $85, $00, $07, $95, $48, $FF, $B8, $9B, $A7, $33, $23, $56, $77; 14:6FA0
    db $AF, $FE, $DF, $FF, $FF, $50, $03, $50, $00, $5D, $93, $7F, $FF, $C9, $85, $66; 14:6FB0
    db $20, $04, $B9, $56, $CF, $F8, $68, $B8, $32, $34, $66, $88, $9D, $FE, $DC, $FF; 14:6FC0
    db $FF, $F2, $00, $45, $00, $07, $D6, $29, $FF, $F8, $98, $76, $41, $00, $6A, $85; 14:6FD0
    db $7C, $FD, $64, $8C, $92, $24, $77, $56, $8A, $DD, $DC, $CF, $FF, $FF, $70, $02; 14:6FE0
    db $60, $00, $4C, $81, $6F, $FF, $A9, $A8, $64, $20, $03, $87, $56, $BF, $E7, $6A; 14:6FF0
    db $DA, $32, $46, $53, $57, $9C, $DD, $DD, $FF, $FF, $FF, $50, $04, $60, $00, $7C; 14:7000
    db $61, $8F, $FE, $AA, $B8, $64, $10, $03, $75, $47, $EF, $C7, $9D, $D7, $23, $55; 14:7010
    db $32, $48, $AC, $CC, $EF, $FF, $EF, $FF, $A0, $02, $80, $00, $5C, $80, $5F, $FF; 14:7020
    db $A8, $CA, $84, $10, $03, $63, $37, $EF, $C7, $BE, $E7, $34, $75, $20, $48, $AA; 14:7030
    db $BB, $FF, $FD, $DE, $FF, $F3, $00, $66, $00, $09, $A1, $0A, $FF, $A7, $CF, $A5; 14:7040
    db $21, $33, $32, $16, $BD, $A7, $BF, $E8, $56, $97, $21, $37, $87, $8A, $EF, $EC; 14:7050
    db $DE, $FE, $DF, $D0, $03, $90, $00, $78, $10, $6F, $F8, $9E, $FB, $76, $65, $42; 14:7060
    db $21, $59, $75, $7C, $F9, $7A, $DB, $53, $67, $54, $58, $AA, $BB, $DE, $EE, $DD; 14:7070
    db $FF, $E0, $09, $A0, $00, $94, $00, $6F, $B6, $9F, $FD, $89, $89, $62, $02, $57; 14:7080
    db $12, $7C, $A6, $8F, $D9, $6A, $B7, $35, $79, $66, $9C, $CC, $BD, $FF, $FF, $F6; 14:7090
    db $29, $71, $00, $42, $00, $2D, $64, $8F, $FF, $9D, $CD, $95, $25, $65, $00, $68; 14:70A0
    db $44, $8D, $A7, $9C, $C8, $69, $A8, $77, $AA, $AA, $BC, $DD, $FF, $FB, $39, $C7; 14:70B0
    db $00, $34, $00, $05, $60, $4A, $FD, $BB, $FF, $E8, $89, $A5, $20, $66, $20, $39; 14:70C0
    db $84, $6B, $DA, $8A, $DB, $98, $9B, $98, $8A, $BB, $BD, $FF, $F6, $6D, $B4, $00; 14:70D0
    db $52, $00, $07, $10, $3B, $E9, $8D, $FE, $C9, $BA, $B7, $53, $65, $50, $26, $85; 14:70E0
    db $47, $CB, $88, $BD, $B9, $9B, $BB, $99, $AC, $BB, $AD, $EF, $C5, $69, $95, $00; 14:70F0
    db $34, $00, $04, $43, $35, $88, $AB, $BA, $AC, $DA, $88, $99, $85, $55, $66, $55; 14:7100
    db $68, $88, $8A, $AA, $9A, $AA, $99, $99, $88, $99, $88, $89, $98, $89, $A9, $86; 14:7110
    db $77, $76, $65, $54, $44, $55, $45, $56, $55, $66, $77, $77, $88, $88, $9A, $AA; 14:7120
    db $AA, $AA, $99, $99, $88, $88, $78, $88, $87, $88, $87, $78, $88, $78, $88, $88; 14:7130
    db $88, $98, $88, $88, $77, $76, $66, $55, $55, $45, $55, $56, $67, $77, $88, $89; 14:7140
    db $99, $99, $99, $99, $99, $99, $88, $98, $88, $88, $88, $87, $77, $77, $77, $88; 14:7150
    db $78, $88, $88, $88, $88, $77, $77, $77, $76, $77, $78, $78, $88, $88, $77, $77; 14:7160
    db $77, $77, $66, $77, $77, $78, $88, $88, $88, $88, $77, $77, $77, $78, $88, $88; 14:7170
    db $99, $99, $98, $88, $87, $77, $77, $77, $78, $88, $88, $98, $88, $88, $87, $77; 14:7180
    db $76, $66, $66, $77, $77, $88, $88, $88, $88, $77, $77, $77, $77, $77, $88, $88; 14:7190
    db $88, $88, $88, $77, $77, $77, $78, $88, $88, $88, $89, $98, $88, $88, $77, $77; 14:71A0
    db $77, $77, $88, $88, $88, $88, $88, $87, $88, $77, $77, $77, $77, $78, $87, $78; 14:71B0
    db $88, $87, $78, $88, $77, $88, $88, $88, $88, $88, $88, $88, $87, $78, $87, $77; 14:71C0
    db $87, $77, $78, $87, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77; 14:71D0
    db $88, $87, $88, $88, $77, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $78; 14:71E0
    db $87, $88, $88, $88, $88, $88, $77, $78, $77, $78, $88, $88, $88, $88, $88, $87; 14:71F0
    db $87, $77, $77, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $77, $88; 14:7200
    db $88, $88, $88, $78, $88, $87, $78, $88, $88, $88, $77, $88, $77, $77, $88, $88; 14:7210
    db $78, $88, $88, $88, $88, $88, $77, $77, $88, $87, $77, $88, $77, $77, $77, $77; 14:7220
    db $67, $88, $88, $88, $89, $98, $88, $88, $88, $88, $87, $88, $88, $88, $88, $88; 14:7230
    db $88, $88, $88, $87, $77, $77, $77, $77, $77, $88, $77, $88, $77, $77, $88, $77; 14:7240
    db $78, $88, $88, $87, $78, $87, $76, $78, $87, $77, $77, $88, $88, $87, $78, $98; 14:7250
    db $88, $88, $88, $88, $87, $78, $77, $77, $77, $78, $87, $77, $77, $78, $77, $88; 14:7260
    db $88, $88, $77, $88, $88, $77, $77, $88, $87, $77, $88, $87, $78, $88, $87, $77; 14:7270
    db $88, $87, $77, $88, $88, $78, $88, $78, $88, $87, $77, $88, $88, $87, $77, $88; 14:7280
    db $88, $77, $78, $88, $77, $78, $77, $88, $88, $88, $88, $88, $87, $77, $88, $77; 14:7290
    db $88, $77, $78, $88, $87, $77, $78, $87, $76, $78, $98, $77, $78, $88, $87, $66; 14:72A0
    db $78, $87, $77, $88, $88, $77, $88, $88, $76, $78, $88, $88, $77, $89, $98, $77; 14:72B0
    db $77, $88, $87, $77, $88, $87, $77, $88, $88, $87, $78, $88, $77, $77, $88, $88; 14:72C0
    db $78, $88, $87, $77, $78, $88, $77, $78, $88, $88, $77, $89, $88, $77, $78, $88; 14:72D0
    db $87, $77, $88, $88, $77, $88, $88, $77, $78, $88, $77, $78, $88, $87, $87, $88; 14:72E0
    db $88, $77, $78, $88, $87, $77, $77, $88, $77, $77, $77, $66, $66, $67, $76, $77; 14:72F0
    db $78, $88, $88, $99, $9A, $99, $99, $9A, $AA, $AA, $AA, $BB, $BB, $CD, $B6, $10; 14:7300
    db $03, $20, $00, $03, $56, $79, $AB, $DE, $EB, $87, $89, $85, $23, $57, $89, $99; 14:7310
    db $AB, $CC, $B9, $88, $99, $88, $8A, $BC, $DE, $FF, $FF, $E4, $00, $34, $00, $00; 14:7320
    db $14, $55, $8A, $CE, $FF, $D8, $57, $97, $20, $04, $77, $67, $9B, $CC, $CB, $97; 14:7330
    db $78, $87, $57, $9B, $CD, $EF, $FF, $FF, $F3, $00, $46, $00, $00, $45, $56, $8C; 14:7340
    db $EF, $FF, $C6, $48, $A5, $00, $06, $86, $57, $BC, $EE, $C9, $66, $88, $63, $37; 14:7350
    db $AB, $BB, $EF, $FF, $FF, $FC, $10, $03, $20, $00, $05, $66, $9B, $EF, $FF, $E8; 14:7360
    db $56, $85, $00, $04, $86, $68, $BE, $EE, $DA, $87, $88, $52, $25, $9A, $9B, $DF; 14:7370
    db $FF, $FF, $FF, $F8, $00, $04, $00, $00, $5A, $88, $AE, $FF, $FE, $94, $45, $50; 14:7380
    db $00, $39, $86, $8C, $FF, $DC, $A8, $66, $64, $12, $59, $A9, $BE, $FF, $FE, $EE; 14:7390
    db $FF, $D0, $00, $45, $00, $05, $B9, $6A, $DF, $FF, $D8, $23, $65, $00, $06, $A8; 14:73A0
    db $68, $EF, $FD, $A8, $67, $74, $00, $38, $98, $9B, $FF, $FE, $DD, $DD, $FF, $C0; 14:73B0
    db $00, $55, $00, $07, $A8, $5A, $DE, $FE, $B6, $46, $83, $00, $39, $86, $7B, $EF; 14:73C0
    db $ED, $97, $55, $53, $01, $49, $A8, $AC, $EF, $EC, $BB, $BC, $BB, $CE, $B0, $03; 14:73D0
    db $73, $00, $26, $66, $6B, $BC, $EC, $85, $59, $60, $03, $77, $67, $BB, $DD, $CA; 14:73E0
    db $78, $84, $22, $36, $56, $9A, $BC, $CD, $BB, $BB, $BA, $BC, $DF, $F5, $02, $67; 14:73F0
    db $00, $05, $55, $47, $CC, $FD, $86, $99, $70, $04, $56, $45, $8B, $BE, $B9, $AB; 14:7400
    db $B6, $12, $65, $42, $7A, $BA, $AB, $CC, $BB, $9A, $BB, $BB, $DF, $F2, $04, $74; 14:7410
    db $00, $15, $55, $57, $CD, $FA, $69, $C8, $30, $26, $45, $45, $8C, $DB, $9A, $FC; 14:7420
    db $95, $56, $65, $33, $59, $99, $8B, $DD, $BA, $AA, $BA, $99, $AC, $DE, $B0, $1A; 14:7430
    db $60, $00, $45, $23, $46, $DC, $A8, $9D, $C6, $46, $56, $42, $45, $8A, $88, $CD; 14:7440
    db $CB, $89, $97, $65, $45, $55, $67, $8A, $AA, $BB, $BB, $A9, $A9, $9A, $AC, $DE; 14:7450
    db $70, $8B, $20, $01, $23, $11, $37, $C9, $6A, $DC, $A8, $68, $86, $53, $47, $75; 14:7460
    db $68, $AB, $A8, $9B, $B9, $76, $88, $65, $57, $88, $88, $BB, $A9, $89, $A8, $88; 14:7470
    db $9A, $A9, $AC, $D8, $49, $94, $44, $22, $63, $04, $65, $67, $67, $A9, $78, $88; 14:7480
    db $99, $87, $99, $99, $88, $99, $87, $77, $77, $66, $78, $77, $88, $88, $88, $88; 14:7490
    db $88, $88, $99, $88, $89, $99, $99, $AB, $A5, $7A, $55, $74, $45, $52, $25, $34; 14:74A0
    db $55, $57, $A7, $8A, $AA, $AA, $89, $B8, $77, $87, $68, $67, $88, $77, $97, $88; 14:74B0
    db $78, $88, $67, $86, $77, $88, $9A, $9B, $BB, $BB, $BB, $BB, $BD, $70, $B7, $03; 14:74C0
    db $02, $02, $00, $98, $65, $CB, $CE, $9A, $BD, $55, $96, $55, $54, $89, $57, $BC; 14:74D0
    db $8A, $AA, $BA, $77, $A8, $44, $66, $66, $68, $A9, $79, $BA, $89, $99, $98, $89; 14:74E0
    db $A8, $9B, $BB, $CD, $EA, $29, $80, $20, $10, $00, $07, $54, $6C, $BC, $BD, $BE; 14:74F0
    db $B5, $88, $62, $45, $65, $65, $AB, $99, $BD, $BA, $AA, $98, $55, $75, $34, $77; 14:7500
    db $67, $8A, $B9, $9B, $B9, $89, $98, $77, $89, $88, $9B, $BB, $DA, $2A, $90, $30; 14:7510
    db $20, $00, $07, $22, $7B, $A9, $BE, $BD, $A8, $C8, $65, $86, $55, $67, $87, $8A; 14:7520
    db $AA, $8B, $B9, $88, $87, $66, $77, $66, $78, $98, $8A, $A9, $99, $98, $88, $88; 14:7530
    db $78, $88, $99, $AA, $BB, $D8, $3C, $70, $41, $30, $00, $05, $02, $6A, $88, $CC; 14:7540
    db $DC, $BC, $D9, $88, $96, $55, $66, $55, $78, $78, $9A, $A9, $AA, $A8, $89, $87; 14:7550
    db $77, $76, $67, $87, $78, $99, $89, $99, $88, $98, $88, $89, $88, $9A, $AA, $BC; 14:7560
    db $56, $D3, $34, $24, $01, $03, $30, $67, $87, $AD, $CC, $BB, $EA, $89, $98, $56; 14:7570
    db $76, $54, $67, $66, $89, $88, $9A, $A9, $9A, $98, $78, $86, $67, $76, $67, $88; 14:7580
    db $78, $A9, $89, $A9, $88, $99, $88, $99, $98, $9A, $AA, $56, $B1, $34, $24, $02; 14:7590
    db $14, $30, $87, $77, $9C, $AB, $BC, $C9, $AB, $98, $78, $76, $56, $75, $57, $88; 14:75A0
    db $78, $99, $99, $AA, $89, $99, $77, $88, $76, $78, $77, $88, $88, $99, $98, $99; 14:75B0
    db $98, $99, $98, $89, $88, $89, $85, $4A, $32, $52, $51, $23, $44, $27, $76, $88; 14:75C0
    db $BA, $9B, $BC, $AB, $BA, $A8, $99, $76, $67, $65, $66, $66, $78, $88, $89, $98; 14:75D0
    db $99, $98, $88, $87, $78, $87, $78, $88, $89, $88, $89, $98, $99, $98, $88, $87; 14:75E0
    db $78, $87, $75, $68, $25, $53, $42, $44, $44, $37, $66, $89, $A9, $BB, $BB, $AC; 14:75F0
    db $BA, $99, $98, $77, $76, $56, $66, $67, $88, $88, $99, $99, $99, $98, $88, $78; 14:7600
    db $88, $78, $88, $88, $88, $88, $88, $88, $88, $87, $88, $88, $88, $89, $85, $97; 14:7610
    db $27, $44, $32, $43, $42, $57, $57, $7A, $A9, $BB, $CB, $BC, $AA, $99, $97, $87; 14:7620
    db $76, $67, $66, $67, $87, $88, $88, $89, $99, $89, $98, $88, $88, $78, $87, $78; 14:7630
    db $87, $88, $88, $78, $88, $88, $88, $88, $88, $88, $98, $66, $94, $55, $45, $34; 14:7640
    db $44, $43, $75, $67, $89, $8A, $AB, $AA, $BB, $AA, $AA, $88, $88, $76, $77, $66; 14:7650
    db $77, $78, $88, $88, $99, $99, $99, $88, $88, $88, $88, $78, $77, $77, $87, $77; 14:7660
    db $88, $88, $88, $88, $88, $87, $88, $77, $76, $76, $55, $55, $55, $55, $55, $66; 14:7670
    db $67, $88, $89, $99, $99, $99, $99, $99, $99, $88, $88, $88, $88, $88, $88, $88; 14:7680
    db $88, $88, $88, $88, $88, $88, $88, $88, $87, $78, $88, $87, $88, $88, $88, $88; 14:7690
    db $88, $88, $87, $77, $77, $66, $66, $66, $66, $77, $77, $78, $88, $87, $77, $77; 14:76A0
    db $77, $67, $67, $77, $77, $88, $88, $88, $88, $89, $98, $88, $88, $88, $88, $88; 14:76B0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77; 14:76C0
    db $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $78, $78; 14:76D0
    db $88, $88, $88, $87, $78, $77, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88; 14:76E0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77; 14:76F0
    db $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $87, $87; 14:7700
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:7710
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77; 14:7720
    db $77, $77, $77, $77, $77, $87, $77, $88, $77, $77, $77, $77, $77, $77, $77, $77; 14:7730

;; PCM21: 2624 bytes = 5248 4-bit samples (rate 2) for SFXInst35
PCM21:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:7740
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 14:7750
    db $88, $88, $88, $88, $88, $88, $78, $87, $77, $77, $87, $77, $88, $88, $88, $88; 14:7760
    db $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $78, $88, $88, $88; 14:7770
    db $88, $87, $78, $77, $77, $77, $88, $88, $88, $88, $88, $78, $88, $87, $88, $88; 14:7780
    db $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $78, $88, $88; 14:7790
    db $88, $88, $77, $88, $77, $77, $78, $77, $88, $88, $88, $88, $88, $88, $88, $88; 14:77A0
    db $88, $88, $88, $78, $88, $88, $88, $88, $87, $88, $88, $87, $77, $88, $88, $78; 14:77B0
    db $77, $77, $78, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78; 14:77C0
    db $88, $87, $77, $78, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88; 14:77D0
    db $88, $88, $88, $88, $88, $88, $88, $88, $87, $55, $44, $54, $44, $57, $77, $78; 14:77E0
    db $88, $88, $78, $88, $88, $99, $AA, $BB, $BB, $CC, $CD, $EE, $92, $22, $33, $01; 14:77F0
    db $03, $79, $A9, $9A, $BC, $97, $53, $45, $54, $45, $89, $AA, $AA, $AA, $A9, $99; 14:7800
    db $AB, $CD, $FE, $84, $43, $44, $32, $02, $48, $AA, $AA, $99, $99, $86, $54, $34; 14:7810
    db $57, $78, $89, $AB, $BB, $A9, $99, $AB, $CD, $EC, $75, $43, $33, $43, $23, $45; 14:7820
    db $89, $BB, $98, $87, $88, $86, $54, $44, $57, $88, $99, $99, $AA, $AA, $BC, $CD; 14:7830
    db $DA, $86, $44, $45, $55, $44, $45, $67, $88, $88, $77, $78, $88, $88, $77, $77; 14:7840
    db $78, $98, $87, $77, $89, $9A, $BC, $BA, $99, $88, $88, $77, $65, $44, $55, $55; 14:7850
    db $65, $66, $67, $78, $88, $99, $99, $88, $88, $88, $78, $88, $9A, $BB, $AA, $A9; 14:7860
    db $99, $98, $77, $65, $54, $44, $55, $55, $66, $67, $88, $89, $99, $99, $99, $99; 14:7870
    db $88, $88, $88, $99, $AA, $AA, $A9, $99, $88, $87, $54, $43, $34, $45, $56, $66; 14:7880
    db $67, $88, $9A, $99, $98, $88, $98, $88, $77, $88, $9A, $BB, $AA, $99, $99, $88; 14:7890
    db $76, $54, $43, $34, $55, $66, $66, $78, $89, $99, $98, $88, $88, $88, $88, $88; 14:78A0
    db $9A, $CC, $BB, $98, $88, $87, $77, $54, $43, $34, $56, $67, $76, $67, $88, $99; 14:78B0
    db $98, $87, $78, $88, $88, $89, $AB, $DE, $CB, $A7, $66, $66, $67, $54, $43, $34; 14:78C0
    db $67, $78, $76, $67, $78, $99, $88, $87, $78, $89, $9A, $AA, $CF, $FE, $CA, $42; 14:78D0
    db $23, $46, $87, $55, $43, $57, $88, $87, $55, $67, $9B, $B9, $76, $55, $67, $89; 14:78E0
    db $AA, $BD, $FF, $FC, $92, $00, $14, $7A, $97, $65, $35, $67, $87, $54, $57, $9B; 14:78F0
    db $CB, $96, $44, $57, $9A, $AB, $BD, $FF, $FC, $92, $00, $03, $7B, $C9, $75, $23; 14:7900
    db $67, $87, $55, $57, $AB, $CA, $84, $24, $58, $BC, $BB, $BC, $FF, $FC, $81, $00; 14:7910
    db $04, $AE, $EB, $53, $12, $57, $87, $55, $57, $CC, $B9, $52, $14, $6A, $DD, $AA; 14:7920
    db $AB, $FF, $FF, $72, $00, $05, $BF, $FB, $40, $00, $58, $98, $55, $68, $DF, $B8; 14:7930
    db $40, $03, $8B, $DD, $97, $79, $EF, $FF, $C4, $00, $02, $9E, $FD, $70, $00, $38; 14:7940
    db $98, $63, $58, $BF, $EA, $50, $01, $6B, $ED, $B6, $56, $9E, $FF, $FF, $63, $00; 14:7950
    db $06, $8D, $C8, $51, $23, $57, $76, $56, $AA, $DE, $95, $20, $15, $9C, $CB, $85; 14:7960
    db $57, $AD, $FF, $FF, $B5, $20, $01, $49, $DB, $93, $22, $36, $88, $77, $9A, $AD; 14:7970
    db $A7, $41, $13, $7B, $DB, $95, $45, $8C, $FF, $FF, $FA, $40, $00, $05, $BE, $A9; 14:7980
    db $22, $25, $58, $77, $69, $BB, $E9, $62, $01, $59, $CD, $A6, $33, $5A, $EF, $FF; 14:7990
    db $FF, $F6, $40, $00, $28, $FE, $D6, $00, $14, $69, $88, $9B, $AD, $B6, $30, $04; 14:79A0
    db $8B, $DA, $74, $35, $9D, $EF, $EF, $FF, $F7, $20, $00, $3C, $FF, $B3, $00, $16; 14:79B0
    db $9C, $97, $7B, $BD, $B6, $20, $05, $AC, $D9, $53, $36, $AC, $DD, $DD, $FF, $FF; 14:79C0
    db $40, $00, $09, $FF, $E7, $00, $05, $98, $85, $58, $ED, $D8, $20, $14, $BD, $C9; 14:79D0
    db $42, $47, $9C, $CB, $AB, $CF, $FF, $FF, $00, $00, $1C, $FF, $95, $00, $15, $76; 14:79E0
    db $76, $8B, $EB, $94, $02, $69, $DA, $84, $33, $78, $A9, $99, $AB, $CD, $EF, $FF; 14:79F0
    db $F4, $00, $00, $BF, $FA, $30, $00, $69, $99, $77, $AD, $BA, $62, $37, $9C, $85; 14:7A00
    db $22, $49, $AB, $A9, $89, $AB, $CC, $EF, $FF, $F4, $00, $00, $AF, $FB, $20, $02; 14:7A10
    db $7A, $76, $68, $CF, $D9, $41, $16, $9C, $96, $23, $49, $AB, $88, $78, $9B, $BC; 14:7A20
    db $DF, $FF, $FF, $40, $00, $0A, $FF, $B2, $00, $36, $97, $78, $BC, $FB, $51, $02; 14:7A30
    db $8C, $DA, $63, $34, $79, $A8, $98, $88, $89, $9C, $EF, $FE, $EF, $B2, $00, $02; 14:7A40
    db $DF, $F8, $30, $13, $77, $77, $9B, $DC, $73, $22, $69, $BA, $85, $56, $78, $87; 14:7A50
    db $88, $9A, $98, $8A, $BE, $ED, $CC, $FF, $50, $00, $0B, $FF, $94, $00, $37, $87; 14:7A60
    db $78, $AB, $B7, $31, $37, $AD, $B8, $55, $57, $87, $78, $AB, $B8, $64, $6A, $DE; 14:7A70
    db $DB, $AB, $EF, $D3, $00, $06, $FF, $E3, $00, $25, $86, $55, $9C, $DB, $51, $15; 14:7A80
    db $AE, $D9, $54, $68, $A7, $53, $69, $BA, $85, $58, $BC, $CB, $AA, $CF, $FF, $90; 14:7A90
    db $00, $08, $FE, $A1, $00, $44, $64, $79, $EE, $C7, $22, $49, $CD, $97, $56, $88; 14:7AA0
    db $74, $45, $9A, $B8, $76, $79, $BA, $AA, $BC, $DC, $CD, $F8, $10, $00, $8E, $D9; 14:7AB0
    db $20, $05, $68, $68, $9D, $CB, $73, $36, $AB, $B8, $66, $88, $86, $55, $78, $98; 14:7AC0
    db $76, $79, $AA, $98, $9B, $CD, $DC, $CD, $E8, $00, $02, $AF, $C7, $10, $04, $56; 14:7AD0
    db $69, $CE, $C8, $42, $58, $BA, $97, $67, $76, $55, $68, $A9, $76, $57, $89, $A9; 14:7AE0
    db $9A, $AA, $AB, $BB, $BC, $DF, $B0, $00, $19, $EA, $51, $14, $77, $55, $7B, $EB; 14:7AF0
    db $75, $46, $99, $77, $89, $98, $44, $57, $9A, $87, $77, $88, $88, $9A, $99, $9A; 14:7B00
    db $BC, $CB, $9A, $BD, $E6, $00, $05, $BA, $64, $47, $65, $23, $8B, $DB, $64, $67; 14:7B10
    db $87, $67, $AA, $86, $44, $7A, $97, $77, $99, $65, $68, $BB, $98, $89, $AA, $AA; 14:7B20
    db $BB, $BB, $BC, $D3, $00, $16, $A8, $54, $76, $53, $24, $9B, $B9, $78, $98, $66; 14:7B30
    db $68, $98, $67, $78, $98, $55, $89, $97, $57, $AB, $98, $88, $A9, $89, $BC, $DB; 14:7B40
    db $AA, $CD, $D8, $00, $34, $75, $53, $89, $33, $25, $7A, $87, $9B, $BA, $65, $67; 14:7B50
    db $87, $77, $98, $87, $76, $78, $77, $88, $88, $98, $9A, $99, $9A, $AA, $BB, $AB; 14:7B60
    db $BC, $DC, $A2, $03, $14, $43, $46, $A5, $53, $46, $77, $59, $AB, $A9, $88, $87; 14:7B70
    db $65, $68, $88, $88, $88, $87, $67, $78, $88, $99, $A9, $99, $9A, $AB, $AA, $AA; 14:7B80
    db $AB, $BA, $A6, $57, $55, $43, $21, $43, $45, $55, $68, $77, $77, $78, $98, $89; 14:7B90
    db $98, $99, $99, $99, $88, $87, $76, $66, $77, $77, $77, $88, $AA, $BB, $BB, $BB; 14:7BA0
    db $BB, $CD, $DB, $89, $74, $53, $10, $11, $01, $11, $36, $55, $78, $89, $A9, $AB; 14:7BB0
    db $BA, $BB, $AA, $A9, $88, $87, $66, $55, $55, $55, $78, $89, $AA, $BC, $CC, $CC; 14:7BC0
    db $CC, $CD, $DC, $99, $74, $44, $10, $00, $01, $21, $25, $55, $79, $89, $BA, $AB; 14:7BD0
    db $BA, $BC, $AA, $A9, $88, $87, $66, $54, $45, $56, $78, $89, $9A, $BB, $CC, $DC; 14:7BE0
    db $CC, $CC, $DD, $A9, $95, $45, $30, $01, $00, $11, $14, $65, $68, $88, $BA, $9B; 14:7BF0
    db $BA, $AC, $BA, $AA, $88, $97, $76, $64, $55, $55, $67, $78, $89, $AB, $CC, $CC; 14:7C00
    db $CC, $CD, $DE, $C9, $97, $45, $41, $01, $00, $01, $01, $65, $57, $98, $AB, $9A; 14:7C10
    db $BB, $AB, $BA, $AA, $97, $88, $76, $65, $55, $55, $67, $78, $89, $9A, $BC, $CC; 14:7C20
    db $DC, $CC, $CD, $EB, $8A, $64, $43, $00, $20, $01, $10, $37, $45, $89, $8B, $B9; 14:7C30
    db $AB, $B9, $BA, $AA, $A8, $78, $76, $66, $55, $55, $66, $78, $89, $AB, $BC, $CC; 14:7C40
    db $CC, $CC, $CC, $ED, $89, $84, $44, $20, $11, $00, $21, $16, $54, $79, $88, $B9; 14:7C50
    db $9B, $B9, $AB, $AA, $A9, $78, $86, $66, $65, $66, $56, $78, $78, $9A, $AB, $CC; 14:7C60
    db $DD, $DC, $CD, $EF, $73, $93, $41, $00, $07, $01, $16, $39, $73, $9B, $C5, $B8; 14:7C70
    db $BC, $A7, $6B, $88, $54, $67, $75, $56, $97, $68, $AB, $AA, $8B, $CB, $9B, $DC; 14:7C80
    db $CA, $AB, $CC, $FB, $02, $50, $10, $00, $C6, $27, $89, $59, $28, $B8, $68, $CA; 14:7C90
    db $C7, $67, $86, $45, $58, $86, $89, $98, $85, $79, $87, $AB, $AB, $98, $9B, $9A; 14:7CA0
    db $BB, $BC, $BD, $FF, $30, $30, $10, $01, $8D, $35, $68, $75, $33, $B9, $88, $BC; 14:7CB0
    db $B8, $56, $75, $54, $68, $99, $8A, $88, $75, $68, $98, $BB, $BA, $88, $89, $9A; 14:7CC0
    db $CC, $BB, $BC, $FF, $A0, $02, $13, $02, $6D, $92, $44, $65, $42, $8C, $BA, $AA; 14:7CD0
    db $B9, $63, $56, $78, $79, $AA, $88, $76, $65, $68, $AA, $AA, $99, $88, $89, $AB; 14:7CE0
    db $CD, $CB, $BB, $DF, $D0, $02, $24, $21, $5B, $D3, $22, $46, $64, $6D, $DA, $98; 14:7CF0
    db $88, $74, $36, $8A, $98, $89, $87, $75, $78, $88, $9A, $AA, $87, $88, $89, $AB; 14:7D00
    db $CD, $B9, $AB, $CF, $F2, $00, $35, $52, $57, $E6, $10, $27, $86, $69, $DC, $A7; 14:7D10
    db $47, $76, $46, $7A, $B8, $66, $88, $76, $68, $99, $99, $99, $97, $78, $9A, $BB; 14:7D20
    db $CC, $B9, $9B, $DF, $F2, $00, $36, $64, $56, $D8, $10, $16, $89, $78, $CD, $B6; 14:7D30
    db $35, $78, $65, $7A, $B9, $65, $69, $87, $67, $9B, $98, $89, $98, $78, $9B, $BB; 14:7D40
    db $BB, $AA, $9B, $DF, $F0, $00, $38, $86, $46, $D7, $10, $15, $AB, $87, $BC, $A6; 14:7D50
    db $34, $7A, $86, $69, $B9, $64, $68, $98, $67, $9B, $A8, $88, $99, $88, $9B, $BB; 14:7D60
    db $BA, $99, $BC, $EF, $70, $00, $59, $87, $3B, $B4, $00, $27, $DB, $89, $AB, $85; 14:7D70
    db $34, $9A, $97, $78, $A8, $65, $68, $98, $78, $AB, $A8, $78, $99, $88, $AB, $CB; 14:7D80
    db $A9, $8B, $DE, $F8, $00, $05, $A9, $82, $AB, $40, $00, $7D, $C8, $8A, $98, $52; 14:7D90
    db $38, $AA, $77, $79, $97, $66, $68, $88, $89, $AA, $A8, $78, $AA, $9A, $BC, $CA; 14:7DA0
    db $89, $CE, $FF, $00, $01, $AB, $94, $5D, $81, $00, $2B, $EB, $79, $99, $73, $26; 14:7DB0
    db $AC, $97, $67, $88, $76, $57, $88, $88, $99, $AA, $88, $99, $AB, $BB, $CC, $AA; 14:7DC0
    db $CF, $FD, $00, $04, $EC, $A0, $7B, $60, $00, $5E, $FA, $67, $8A, $73, $26, $CD; 14:7DD0
    db $A6, $46, $88, $87, $68, $98, $67, $89, $BA, $88, $99, $AA, $BB, $DC, $AC, $EF; 14:7DE0
    db $B0, $00, $3F, $EB, $05, $96, $20, $05, $EF, $C7, $45, $98, $52, $5B, $EC, $72; 14:7DF0
    db $46, $99, $76, $8A, $97, $66, $8B, $B9, $99, $AB, $BB, $AC, $DE, $FF, $90, $00; 14:7E00
    db $5F, $F9, $06, $85, $10, $06, $FF, $C7, $34, $88, $64, $6B, $DC, $73, $25, $8A; 14:7E10
    db $86, $79, $98, $75, $7B, $BA, $98, $9B, $CB, $AA, $CF, $F8, $00, $08, $FF, $70; 14:7E20
    db $59, $63, $00, $5F, $FD, $60, $28, $A7, $45, $BE, $D7, $21, $49, $B9, $67, $99; 14:7E30
    db $86, $57, $CD, $BA, $89, $BC, $CB, $DF, $F3, $00, $09, $FF, $70, $46, $55, $00; 14:7E40
    db $5F, $FE, $70, $06, $98, $55, $AE, $E8, $20, $28, $CA, $88, $89, $97, $57, $BC; 14:7E50
    db $CB, $99, $BC, $CD, $FF, $00, $00, $BF, $F5, $26, $43, $30, $08, $FF, $E8, $12; 14:7E60
    db $57, $76, $69, $CC, $85, $23, $79, $A9, $87, $89, $77, $8A, $BC, $B9, $BD, $DE; 14:7E70
    db $FF, $00, $00, $DF, $F4, $26, $43, $20, $0A, $FF, $D6, $02, $67, $76, $7A, $CB; 14:7E80
    db $64, $24, $9A, $99, $88, $88, $76, $AB, $CC, $BA, $BD, $FF, $F0, $00, $0C, $FF; 14:7E90
    db $42, $65, $64, $00, $7F, $FF, $91, $16, $88, $75, $8A, $B9, $62, $49, $A9, $97; 14:7EA0
    db $69, $A8, $8A, $BC, $DD, $BB, $FF, $80, $00, $4F, $FC, $22, $44, $83, $00, $8F; 14:7EB0
    db $FF, $70, $15, $8A, $87, $88, $98, $54, $58, $AB, $A7, $78, $89, $BB, $BC, $ED; 14:7EC0
    db $EF, $D0, $00, $0A, $FF, $83, $42, $56, $00, $5C, $FF, $B3, $02, $6A, $A7, $77; 14:7ED0
    db $8A, $85, $46, $8A, $B9, $68, $89, $BC, $CC, $DE, $FF, $20, $00, $5F, $FB, $43; 14:7EE0
    db $34, $94, $02, $6B, $FF, $92, $12, $6A, $A8, $76, $9A, $86, $56, $8B, $B9, $77; 14:7EF0
    db $79, $DE, $EF, $FF, $40, $00, $1E, $FE, $84, $33, $84, $01, $5A, $FF, $D6, $21; 14:7F00
    db $38, $98, $75, $7A, $A9, $75, $69, $CC, $B9, $7A, $EF, $FF, $F2, $00, $01, $DF; 14:7F10
    db $C8, $53, $37, $51, $24, $8F, $FE, $72, $12, $79, $87, $67, $98, $86, $56, $AC; 14:7F20
    db $EC, $A8, $9D, $FF, $F4, $00, $02, $FF, $C7, $32, $4A, $50, $01, $7F, $FF, $92; 14:7F30
    db $02, $79, $97, $45, $9A, $A8, $54, $7B, $DE, $C9, $AF, $FF, $80, $00, $0D, $FF; 14:7F40
    db $A3, $02, $88, $41, $03, $DF, $FE, $60, $03, $8B, $A7, $45, $68, $97, $67, $9D; 14:7F50
    db $FF, $DC, $FF, $82, $00, $08, $DD, $D8, $31, $45, $54, $32, $8B, $FF, $B6, $21; 14:7F60
    db $37, $AA, $97, $56, $87, $78, $8A, $DE, $FF, $FC, $10, $00, $4C, $DD, $B6, $45; 14:7F70
    db $53, $21, $15, $CF, $FE, $84, $11, $48, $9A, $A8, $77, $65, $78, $9D, $EF, $FF; 14:7F80
    db $F4, $10, $00, $8B, $CD, $95, $55, $53, $21, $27, $AF, $FD, $94, $22, $47, $8A; 14:7F90
    db $98, $98, $77, $77, $AD, $EF, $FF, $B2, $00, $03, $9B, $DB, $86, $66, $53, $21; 14:7FA0
    db $47, $BF, $EC, $84, $12, $47, $9B, $98, $76, $68, $89, $BC, $EF, $FF, $83, $00; 14:7FB0
    db $05, $AB, $DA, $65, $66, $65, $31, $36, $BF, $FD, $83, $12, $58, $AA, $88, $76; 14:7FC0
    db $78, $89, $BC, $EF, $FF, $73, $00, $05, $AC, $EA, $65, $55, $66, $32, $35, $BE; 14:7FD0
    db $FE, $83, $11, $48, $BA, $87, $66, $88, $9A, $AB, $DE, $FF, $D5, $20, $00, $6A; 14:7FE0
    db $DC, $86, $55, $56, $53, $34, $7C, $EF, $C7, $32, $36, $AB, $98, $65, $68, $9B; 14:7FF0

; ============================================================================
SECTION "GHX PCM samples bank $15", ROMX[$4000], BANK[$15]
; ============================================================================
;; (continuation of the previous sample from bank $14)
    db $BA, $BC, $EF, $FC, $50, $00, $27, $BD, $B6, $43, $46, $76, $53, $47, $BD, $EB; 15:4000
    db $64, $34, $8A, $A9, $75, $57, $9A, $BB, $BB, $CE, $FF, $B4, $00, $02, $7B, $C9; 15:4010
    db $53, $24, $68, $87, $54, $69, $BC, $B8, $65, $68, $AA, $87, $55, $79, $BC, $CB; 15:4020
    db $BB, $CD, $EE, $B5, $20, $02, $58, $87, $53, $35, $79, $98, $65, $57, $9B, $B9; 15:4030
    db $86, $67, $78, $77, $66, $79, $BC, $CB, $AA, $AA, $BC, $CA, $86, $33, $23, $45; 15:4040
    db $54, $44, $56, $78, $87, $78, $89, $AA, $A9, $87, $66, $67, $78, $88, $99, $99; 15:4050
    db $99, $99, $9A, $BB, $BB, $A9, $87, $65, $55, $55, $55, $55, $55, $56, $77, $77; 15:4060
    db $77, $77, $77, $88, $88, $88, $87, $78, $88, $99, $99, $99, $9A, $A9, $99, $99; 15:4070
    db $99, $88, $76, $66, $66, $66, $66, $65, $55, $55, $56, $77, $88, $87, $77, $88; 15:4080
    db $99, $99, $88, $88, $88, $99, $99, $99, $98, $88, $88, $88, $99, $98, $88, $88; 15:4090
    db $77, $77, $66, $66, $66, $55, $55, $66, $77, $77, $77, $77, $88, $98, $88, $88; 15:40A0
    db $88, $87, $88, $89, $99, $88, $88, $99, $99, $98, $88, $88, $87, $77, $77, $78; 15:40B0
    db $87, $77, $77, $78, $88, $87, $77, $77, $77, $76, $67, $77, $77, $77, $78, $88; 15:40C0
    db $88, $88, $88, $88, $88, $88, $88, $88, $77, $88, $88, $88, $88, $88, $88, $88; 15:40D0
    db $88, $88, $88, $77, $77, $78, $88, $87, $77, $77, $77, $77, $77, $77, $77, $77; 15:40E0
    db $77, $78, $88, $88, $88, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:40F0
    db $88, $77, $77, $77, $77, $78, $77, $77, $77, $78, $88, $88, $88, $87, $77, $87; 15:4100
    db $88, $88, $87, $77, $78, $88, $88, $87, $78, $88, $87, $77, $88, $88, $87, $77; 15:4110
    db $88, $88, $88, $87, $88, $88, $77, $78, $88, $88, $87, $77, $88, $88, $88, $77; 15:4120
    db $77, $87, $77, $88, $88, $88, $77, $78, $88, $88, $87, $77, $88, $88, $87, $77; 15:4130
    db $88, $88, $77, $78, $88, $88, $87, $77, $78, $88, $78, $88, $88, $88, $88, $88; 15:4140
    db $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $78, $88, $87, $77, $77; 15:4150
    db $78, $87, $77, $88, $88, $87, $88, $88, $88, $77, $78, $88, $88, $88, $88, $88; 15:4160
    db $87, $88, $88, $88, $88, $87, $77, $78, $88, $88, $77, $77, $88, $88, $88, $88; 15:4170

;; PCM22: 2016 bytes = 4032 4-bit samples (rate 2) for SFXInst36
PCM22:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:4180
    db $88, $88, $77, $77, $66, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $89; 15:4190
    db $99, $99, $99, $88, $88, $88, $88, $88, $88, $88, $88, $88, $9A, $B9, $76, $10; 15:41A0
    db $00, $13, $36, $66, $78, $9B, $DC, $CB, $86, $54, $56, $68, $88, $89, $9A, $BC; 15:41B0
    db $BB, $87, $65, $56, $77, $88, $89, $9A, $BB, $AA, $87, $77, $78, $88, $89, $89; 15:41C0
    db $AA, $AA, $99, $88, $9B, $A5, $60, $00, $00, $44, $67, $67, $8B, $BE, $E9, $75; 15:41D0
    db $02, $45, $8A, $A9, $AA, $BE, $EE, $D9, $75, $34, $56, $67, $77, $9A, $BC, $B9; 15:41E0
    db $97, $67, $88, $88, $78, $9A, $BC, $A9, $87, $78, $99, $98, $89, $DD, $55, $00; 15:41F0
    db $00, $08, $66, $67, $9C, $FE, $A8, $00, $12, $69, $97, $9C, $CF, $FD, $B7, $23; 15:4200
    db $46, $66, $54, $8A, $CF, $D9, $76, $57, $98, $67, $68, $BC, $CB, $97, $8A, $9A; 15:4210
    db $86, $68, $9B, $CB, $9A, $CF, $90, $00, $02, $17, $65, $58, $FF, $FD, $10, $00; 15:4220
    db $36, $63, $5C, $FF, $FE, $96, $45, $65, $10, $35, $CF, $EB, $98, $89, $94, $32; 15:4230
    db $38, $BC, $A9, $A9, $CC, $88, $67, $9A, $A8, $89, $AC, $CA, $98, $AE, $E0, $00; 15:4240
    db $03, $65, $22, $99, $FF, $63, $30, $46, $40, $08, $BF, $FD, $9A, $BB, $85, $00; 15:4250
    db $58, $AB, $A9, $CF, $D8, $62, $26, $76, $57, $9B, $EC, $98, $88, $88, $76, $8A; 15:4260
    db $AA, $A9, $AB, $CA, $99, $AF, $C0, $00, $05, $42, $04, $FE, $DD, $42, $98, $20; 15:4270
    db $02, $5E, $D7, $BF, $FF, $B7, $14, $85, $33, $49, $DF, $C8, $9A, $98, $52, $36; 15:4280
    db $88, $89, $BC, $CA, $77, $99, $88, $88, $AB, $A9, $AB, $BB, $AA, $ED, $00, $20; 15:4290
    db $10, $00, $4F, $F7, $8B, $BA, $61, $00, $86, $35, $9E, $FF, $D9, $BC, $95, $22; 15:42A0
    db $47, $76, $6A, $DD, $A8, $99, $85, $44, $68, $88, $9B, $BB, $99, $9A, $98, $89; 15:42B0
    db $AA, $99, $BB, $CC, $FC, $00, $60, $00, $02, $6B, $A5, $BF, $DA, $43, $63, $31; 15:42C0
    db $05, $AA, $BA, $EF, $FB, $97, $88, $52, $15, $88, $78, $AD, $CA, $88, $98, $55; 15:42D0
    db $68, $98, $89, $BC, $B9, $9A, $BA, $89, $AB, $BC, $EC, $00, $73, $00, $03, $56; 15:42E0
    db $85, $AF, $EB, $56, $97, $10, $04, $76, $88, $BF, $FC, $BA, $B8, $54, $34, $66; 15:42F0
    db $56, $8C, $B9, $8A, $BA, $76, $79, $98, $79, $BC, $BA, $AB, $BA, $AA, $BC, $DF; 15:4300
    db $50, $05, $40, $00, $76, $35, $8E, $EE, $C6, $6A, $82, $00, $66, $44, $8C, $FE; 15:4310
    db $EC, $CC, $B7, $31, $35, $31, $38, $CB, $9A, $CD, $B8, $77, $89, $77, $8B, $CC; 15:4320
    db $BB, $DE, $DC, $BD, $FA, $00, $06, $10, $01, $77, $55, $CE, $FF, $B6, $56, $84; 15:4330
    db $00, $28, $96, $7C, $FF, $EC, $BA, $88, $52, $01, $46, $56, $8C, $DC, $BA, $99; 15:4340
    db $97, $67, $8A, $AA, $BC, $EE, $DD, $EF, $FA, $00, $05, $20, $00, $7B, $87, $BE; 15:4350
    db $FF, $D9, $40, $45, $40, $03, $AC, $BB, $CF, $EE, $C9, $53, $25, $41, $03, $9D; 15:4360
    db $A9, $9C, $DA, $87, $66, $78, $99, $9C, $EF, $EE, $FF, $FF, $50, $00, $30, $00; 15:4370
    db $05, $BC, $ED, $BB, $BD, $C5, $00, $16, $53, $47, $BE, $FF, $FC, $A9, $98, $41; 15:4380
    db $00, $36, $8A, $BB, $CC, $DC, $96, $56, $77, $78, $8A, $CF, $FF, $FF, $FF, $60; 15:4390
    db $00, $00, $00, $02, $8C, $FF, $FB, $8A, $C9, $40, $00, $14, $79, $AB, $BE, $FF; 15:43A0
    db $E9, $55, $43, $21, $12, $59, $CE, $EC, $AB, $BA, $87, $66, $56, $8C, $DD, $CE; 15:43B0
    db $FF, $FB, $10, $00, $00, $00, $00, $4C, $FF, $FA, $79, $99, $74, $10, $00, $5B; 15:43C0
    db $DB, $BB, $CD, $DD, $C8, $30, $02, $56, $78, $89, $AB, $EF, $EA, $87, $78, $99; 15:43D0
    db $99, $9B, $EF, $FF, $A1, $00, $00, $01, $00, $00, $7D, $FF, $EB, $86, $67, $98; 15:43E0
    db $51, $01, $47, $AD, $ED, $A9, $AA, $A9, $87, $52, $24, $78, $9A, $AA, $AB, $CD; 15:43F0
    db $CB, $98, $88, $9B, $EF, $FC, $71, $00, $00, $23, $21, $02, $59, $CE, $ED, $96; 15:4400
    db $55, $67, $77, $65, $44, $69, $BC, $CC, $B8, $77, $88, $88, $87, $55, $68, $AB; 15:4410
    db $CC, $CA, $99, $AB, $CC, $DE, $EB, $73, $00, $00, $01, $22, $24, $68, $AC, $EE; 15:4420
    db $CA, $97, $54, $45, $66, $66, $77, $78, $AB, $BB, $B9, $87, $67, $77, $78, $88; 15:4430
    db $89, $AB, $BC, $CB, $BB, $BC, $DE, $DA, $51, $00, $00, $01, $34, $56, $68, $AB; 15:4440
    db $DD, $DC, $A8, $54, $33, $45, $66, $77, $88, $89, $AA, $BB, $A9, $87, $66, $67; 15:4450
    db $9A, $BB, $BC, $CB, $CC, $CE, $EB, $96, $20, $00, $00, $13, $56, $67, $78, $8A; 15:4460
    db $BC, $CC, $B9, $76, $54, $44, $55, $66, $77, $88, $89, $AA, $AA, $A9, $88, $88; 15:4470
    db $89, $AB, $CC, $CD, $EF, $EC, $A7, $30, $00, $00, $02, $35, $68, $99, $AB, $BB; 15:4480
    db $BB, $BA, $98, $65, $44, $44, $56, $67, $77, $88, $9A, $AA, $A9, $99, $99, $9A; 15:4490
    db $AA, $BB, $CD, $EE, $DB, $95, $10, $00, $00, $23, $55, $77, $88, $99, $AB, $BC; 15:44A0
    db $CB, $A8, $66, $44, $45, $55, $56, $67, $88, $99, $AA, $AA, $AA, $AA, $AA, $AB; 15:44B0
    db $BC, $DE, $ED, $B9, $51, $00, $00, $01, $25, $67, $89, $99, $9A, $BA, $BB, $BA; 15:44C0
    db $97, $65, $55, $45, $56, $67, $78, $88, $89, $99, $AA, $BB, $BB, $BB, $CC, $DE; 15:44D0
    db $FE, $CB, $73, $00, $00, $00, $03, $67, $99, $AA, $AA, $BA, $BC, $AA, $97, $54; 15:44E0
    db $33, $35, $55, $77, $88, $99, $A9, $A9, $99, $89, $AA, $AB, $CD, $DF, $FF, $ED; 15:44F0
    db $84, $10, $00, $00, $02, $67, $9B, $BB, $CC, $BC, $CB, $A9, $85, $43, $22, $34; 15:4500
    db $57, $88, $9A, $AA, $A9, $99, $88, $89, $99, $BC, $CE, $FF, $FF, $EB, $51, $00; 15:4510
    db $00, $00, $25, $89, $CC, $CC, $CB, $CB, $A9, $76, $32, $22, $25, $57, $99, $AA; 15:4520
    db $A9, $99, $87, $88, $78, $8A, $BC, $DE, $FF, $FF, $FC, $91, $00, $00, $00, $04; 15:4530
    db $8B, $BE, $DD, $ED, $BB, $A8, $63, $20, $01, $25, $8A, $CD, $CC, $B9, $87, $76; 15:4540
    db $66, $67, $89, $BD, $EF, $FF, $FF, $FD, $A4, $00, $00, $00, $05, $9E, $EF, $FE; 15:4550
    db $DD, $B9, $85, $30, $00, $01, $48, $DF, $FF, $EB, $86, $43, $44, $45, $67, $9B; 15:4560
    db $DF, $FF, $FF, $FF, $FD, $85, $00, $00, $00, $16, $CF, $FF, $FE, $AA, $86, $53; 15:4570
    db $10, $00, $03, $8C, $FF, $FF, $C7, $31, $11, $46, $68, $88, $AC, $EF, $FF, $FE; 15:4580
    db $DC, $DF, $B8, $50, $00, $00, $07, $BF, $FF, $DD, $97, $87, $64, $20, $00, $03; 15:4590
    db $AF, $FF, $FF, $84, $00, $02, $58, $98, $99, $9B, $DF, $FF, $EC, $BB, $CF, $FB; 15:45A0
    db $92, $00, $00, $06, $DF, $FF, $B9, $97, $89, $85, $10, $00, $15, $CF, $FF, $FC; 15:45B0
    db $60, $00, $03, $57, $78, $89, $BD, $DE, $EB, $BA, $AA, $CE, $FF, $E7, $30, $00; 15:45C0
    db $00, $6E, $DC, $DA, $8B, $BB, $A6, $20, $00, $07, $DF, $FF, $FB, $74, $12, $22; 15:45D0
    db $22, $35, $8B, $DF, $EC, $A9, $9A, $BC, $CC, $CD, $FF, $F9, $60, $00, $00, $5F; 15:45E0
    db $DD, $D8, $78, $AA, $85, $10, $00, $5D, $FF, $FE, $93, $21, $25, $55, $54, $68; 15:45F0
    db $BD, $CD, $98, $88, $AB, $CB, $99, $9C, $FF, $FF, $61, $00, $00, $7A, $FB, $75; 15:4600
    db $24, $8A, $96, $10, $05, $BF, $FF, $F7, $10, $02, $58, $A7, $66, $7A, $BC, $B8; 15:4610
    db $75, $79, $AB, $A8, $77, $9C, $FF, $FF, $FF, $51, $00, $00, $36, $AE, $88, $54; 15:4620
    db $55, $54, $32, $59, $DF, $FE, $97, $21, $14, $58, $99, $99, $89, $99, $88, $77; 15:4630
    db $88, $99, $99, $AA, $BB, $CC, $CD, $DF, $FF, $70, $00, $00, $8B, $DD, $54, $13; 15:4640
    db $65, $54, $23, $8E, $FF, $E8, $20, $04, $7A, $99, $88, $AB, $A8, $52, $35, $AD; 15:4650
    db $EC, $96, $56, $AC, $DB, $98, $8A, $CD, $EE, $FF, $90, $00, $00, $6A, $99, $32; 15:4660
    db $03, $67, $56, $56, $AE, $EE, $B5, $22, $47, $99, $98, $88, $98, $86, $54, $68; 15:4670
    db $BD, $DB, $86, $56, $78, $89, $99, $AA, $AA, $AB, $DF, $FF, $F9, $00, $00, $16; 15:4680
    db $96, $52, $34, $67, $53, $35, $9D, $FD, $96, $45, $68, $76, $56, $9C, $CC, $85; 15:4690
    db $45, $8A, $A9, $88, $89, $98, $65, $67, $99, $98, $78, $AB, $DD, $CB, $BC, $DE; 15:46A0
    db $FE, $60, $00, $03, $77, $43, $24, $56, $54, $47, $AC, $DC, $97, $78, $87, $64; 15:46B0
    db $57, $AC, $B8, $65, $68, $AA, $98, $87, $88, $77, $77, $88, $88, $77, $89, $AA; 15:46C0
    db $AA, $AB, $CC, $BA, $AB, $BC, $CE, $C2, $00, $00, $36, $32, $34, $86, $63, $35; 15:46D0
    db $AD, $CB, $A8, $99, $86, $34, $48, $9A, $97, $78, $99, $88, $89, $BB, $A7, $54; 15:46E0
    db $56, $67, $67, $99, $A9, $88, $9A, $AB, $BB, $BB, $B9, $98, $88, $99, $AB, $B3; 15:46F0
    db $00, $02, $46, $41, $65, $95, $53, $58, $AC, $99, $AA, $AA, $65, $37, $79, $98; 15:4700
    db $99, $A9, $87, $78, $99, $A9, $88, $87, $56, $67, $78, $88, $99, $87, $78, $9A; 15:4710
    db $AA, $AA, $A9, $88, $89, $AA, $98, $88, $89, $B7, $00, $01, $53, $50, $56, $57; 15:4720
    db $25, $58, $98, $98, $BC, $CA, $98, $78, $87, $77, $88, $88, $78, $88, $87, $89; 15:4730
    db $AA, $99, $88, $88, $76, $67, $77, $77, $88, $99, $99, $AA, $A9, $99, $AA, $A9; 15:4740
    db $98, $88, $87, $76, $8A, $93, $02, $03, $32, $32, $86, $66, $57, $79, $88, $89; 15:4750
    db $CB, $BA, $99, $88, $77, $78, $88, $87, $88, $88, $88, $89, $98, $88, $88, $88; 15:4760
    db $77, $77, $88, $77, $77, $88, $88, $89, $99, $99, $99, $99, $99, $99, $98, $87; 15:4770
    db $77, $88, $89, $65, $53, $34, $43, $23, $32, $44, $45, $67, $78, $9A, $BB, $BB; 15:4780
    db $AA, $BB, $BB, $AA, $99, $87, $77, $66, $76, $67, $77, $66, $66, $78, $88, $89; 15:4790
    db $99, $99, $99, $99, $99, $98, $98, $88, $88, $88, $99, $98, $87, $77, $77, $77; 15:47A0
    db $78, $86, $55, $44, $44, $22, $33, $45, $55, $67, $88, $89, $AB, $BB, $AA, $BB; 15:47B0
    db $BB, $AA, $99, $98, $87, $77, $77, $66, $77, $77, $77, $88, $88, $88, $88, $88; 15:47C0
    db $99, $98, $88, $88, $88, $88, $88, $88, $99, $99, $88, $88, $77, $77, $76, $77; 15:47D0
    db $78, $86, $56, $55, $65, $33, $43, $35, $45, $78, $88, $89, $9B, $BB, $AA, $BB; 15:47E0
    db $BB, $AA, $99, $88, $88, $77, $77, $67, $77, $77, $77, $77, $77, $88, $88, $89; 15:47F0
    db $99, $99, $99, $98, $88, $88, $89, $88, $88, $88, $77, $77, $77, $77, $66, $66; 15:4800
    db $67, $77, $88, $67, $75, $66, $54, $55, $45, $55, $67, $87, $88, $89, $AA, $AA; 15:4810
    db $AA, $AA, $AA, $99, $98, $88, $87, $77, $66, $77, $77, $77, $77, $88, $88, $88; 15:4820
    db $89, $99, $99, $99, $98, $88, $88, $88, $88, $88, $87, $77, $76, $66, $67, $76; 15:4830
    db $66, $66, $66, $77, $78, $88, $88, $77, $76, $55, $55, $55, $55, $66, $77, $78; 15:4840
    db $89, $99, $9A, $AA, $AA, $AA, $AA, $99, $99, $88, $87, $77, $77, $77, $77, $77; 15:4850
    db $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77; 15:4860
    db $77, $77, $76, $66, $66, $66, $66, $77, $77, $78, $88, $88, $87, $77, $77, $77; 15:4870
    db $77, $77, $77, $77, $77, $88, $88, $99, $99, $99, $99, $99, $99, $98, $88, $88; 15:4880
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77; 15:4890
    db $77, $77, $77, $66, $66, $67, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77; 15:48A0
    db $77, $77, $78, $88, $88, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:48B0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:48C0
    db $88, $87, $77, $77, $77, $77, $77, $77, $76, $66, $67, $77, $77, $77, $77, $77; 15:48D0
    db $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:48E0
    db $88, $78, $87, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77; 15:48F0
    db $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77; 15:4900
    db $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:4910
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77; 15:4920
    db $77, $77, $77, $78, $87, $87, $88, $77, $77, $77, $77, $77, $77, $77, $77, $88; 15:4930
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:4940
    db $88, $88, $87, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $87, $77; 15:4950

;; PCM23: 2096 bytes = 4192 4-bit samples (rate 2) for SFXInst37
PCM23:
    db $88, $88, $88, $88, $87, $87, $77, $88, $88, $88, $88, $88, $87, $88, $88, $88; 15:4960
    db $88, $87, $88, $87, $77, $77, $77, $77, $77, $78, $88, $88, $77, $77, $77, $77; 15:4970
    db $77, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $78, $88, $88; 15:4980
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:4990
    db $88, $88, $88, $88, $88, $88, $77, $65, $54, $44, $55, $66, $78, $88, $89, $99; 15:49A0
    db $98, $88, $88, $89, $99, $9A, $AA, $A9, $99, $99, $88, $88, $88, $88, $88, $88; 15:49B0
    db $88, $88, $89, $9B, $B7, $62, $00, $00, $23, $45, $56, $7A, $BD, $EC, $A9, $55; 15:49C0
    db $65, $78, $88, $88, $8A, $BB, $CA, $87, $65, $67, $78, $87, $89, $AB, $CB, $A9; 15:49D0
    db $88, $88, $99, $88, $88, $9A, $AA, $AA, $AC, $EB, $65, $00, $00, $03, $24, $45; 15:49E0
    db $7B, $FF, $FF, $74, $30, $25, $56, $66, $6A, $EF, $FF, $DB, $85, $65, $44, $32; 15:49F0
    db $37, $9C, $ED, $BA, $88, $99, $88, $86, $8A, $BD, $DC, $BA, $AA, $BB, $BE, $F2; 15:4A00
    db $00, $00, $00, $42, $22, $7E, $DF, $F8, $84, $03, $54, $22, $32, $BF, $FF, $FB; 15:4A10
    db $B9, $98, $85, $01, $12, $9B, $BB, $BA, $AC, $A7, $84, $47, $9B, $BB, $AB, $EE; 15:4A20
    db $DD, $98, $89, $BD, $FB, $00, $00, $41, $10, $02, $3F, $FC, $E8, $06, $87, $00; 15:4A30
    db $00, $7E, $BE, $DB, $BF, $F9, $74, $02, $76, $54, $55, $CF, $DB, $85, $68, $A6; 15:4A40
    db $57, $6B, $FD, $CB, $DD, $DE, $96, $89, $BF, $F1, $02, $01, $50, $00, $79, $BF; 15:4A50
    db $A4, $AE, $C5, $20, $05, $85, $56, $9E, $FF, $A8, $A8, $97, $40, $07, $88, $97; 15:4A60
    db $AC, $FC, $67, $66, $86, $55, $AD, $CD, $DC, $EE, $C9, $8A, $AC, $FF, $00, $60; 15:4A70
    db $20, $00, $0E, $93, $8C, $EF, $C7, $04, $A2, $10, $26, $CD, $99, $FF, $FC, $86; 15:4A80
    db $67, $30, $34, $57, $89, $BD, $C9, $99, $77, $66, $68, $AA, $BE, $FF, $EE, $CC; 15:4A90
    db $CC, $FA, $00, $50, $00, $00, $5B, $05, $FF, $D9, $9A, $59, $10, $26, $41, $5C; 15:4AA0
    db $BE, $EB, $EE, $F7, $56, $53, $30, $25, $87, $8D, $EB, $B9, $A8, $87, $58, $98; 15:4AB0
    db $AC, $FF, $FF, $FF, $F8, $05, $70, $00, $00, $32, $09, $FF, $9C, $FF, $87, $22; 15:4AC0
    db $52, $00, $69, $67, $DE, $FE, $CC, $EB, $61, $53, $20, $15, $88, $8A, $EE, $B9; 15:4AD0
    db $BB, $97, $67, $AA, $AB, $FF, $FF, $90, $FA, $00, $03, $00, $00, $7F, $68, $FF; 15:4AE0
    db $F6, $BB, $83, $30, $64, $20, $6D, $A8, $AF, $EE, $8A, $8A, $41, $16, $43, $38; 15:4AF0
    db $BA, $AC, $ED, $B9, $BB, $B8, $9B, $DD, $FF, $A0, $EA, $00, $05, $00, $03, $3A; 15:4B00
    db $48, $EF, $E8, $AE, $C4, $52, $93, $22, $68, $95, $9D, $EC, $8A, $B9, $34, $57; 15:4B10
    db $22, $48, $89, $8D, $ED, $BC, $DE, $AA, $CD, $ED, $B0, $6D, $10, $05, $20, $04; 15:4B20
    db $58, $55, $DD, $D9, $AC, $F6, $63, $97, $30, $77, $85, $7B, $CB, $99, $CC, $76; 15:4B30
    db $68, $63, $37, $88, $59, $CD, $BC, $DF, $EE, $EF, $F7, $08, $80, $00, $31, $00; 15:4B40
    db $47, $A5, $BE, $FE, $C9, $EB, $73, $26, $50, $03, $78, $58, $CD, $CA, $AC, $97; 15:4B50
    db $55, $65, $46, $79, $9A, $BD, $EE, $DF, $FF, $FE, $52, $86, $00, $03, $00, $04; 15:4B60
    db $A7, $4A, $FF, $DB, $BE, $B9, $44, $56, $10, $16, $74, $59, $CC, $9A, $CC, $97; 15:4B70
    db $78, $75, $57, $99, $9B, $DF, $FF, $FF, $F9, $27, $81, $00, $01, $00, $08, $B7; 15:4B80
    db $9E, $FF, $FB, $DB, $A5, $21, $32, $10, $37, $87, $8B, $EC, $99, $AA, $75, $67; 15:4B90
    db $77, $7A, $CC, $CD, $FF, $FF, $FD, $44, $74, $00, $01, $00, $04, $B8, $8B, $FF; 15:4BA0
    db $FC, $DB, $A8, $53, $33, $42, $14, $78, $77, $9B, $A8, $89, $87, $67, $89, $9A; 15:4BB0
    db $BC, $DE, $EF, $FF, $FA, $36, $84, $00, $02, $00, $05, $B7, $6B, $FF, $FB, $EC; 15:4BC0
    db $B8, $54, $43, $42, $24, $77, $66, $AB, $98, $8A, $97, $78, $99, $8A, $BC, $DD; 15:4BD0
    db $EF, $FF, $F6, $4A, $82, $00, $10, $00, $08, $62, $6D, $FF, $DD, $FE, $E8, $66; 15:4BE0
    db $75, $30, $36, $51, $38, $B7, $6A, $DC, $88, $BC, $A8, $9C, $BB, $BC, $DF, $FF; 15:4BF0
    db $F9, $2C, $A4, $00, $31, $00, $03, $50, $58, $DC, $CA, $EF, $FB, $6B, $B8, $33; 15:4C00
    db $47, $22, $35, $75, $68, $BA, $B9, $DC, $CB, $BC, $CA, $9A, $AA, $9A, $BB, $BD; 15:4C10
    db $B4, $5C, $71, $13, $31, $00, $12, $43, $26, $88, $88, $AC, $A9, $9A, $A9, $88; 15:4C20
    db $88, $87, $78, $87, $89, $88, $99, $99, $99, $89, $88, $88, $88, $99, $88, $88; 15:4C30
    db $88, $88, $88, $77, $77, $77, $66, $77, $65, $66, $65, $56, $66, $56, $66, $66; 15:4C40
    db $77, $88, $89, $99, $AA, $AA, $99, $99, $98, $88, $88, $88, $88, $88, $88, $88; 15:4C50
    db $88, $77, $78, $87, $77, $87, $77, $78, $87, $78, $88, $77, $77, $76, $66, $66; 15:4C60
    db $67, $77, $78, $88, $88, $88, $88, $87, $77, $78, $88, $88, $99, $88, $99, $88; 15:4C70
    db $88, $87, $77, $87, $78, $88, $88, $88, $88, $87, $88, $77, $77, $88, $87, $78; 15:4C80
    db $88, $77, $87, $77, $77, $77, $77, $77, $87, $78, $87, $77, $88, $88, $88, $87; 15:4C90
    db $77, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $87, $88, $88, $88; 15:4CA0
    db $88, $88, $88, $88, $77, $77, $77, $77, $77, $78, $88, $88, $88, $87, $77, $77; 15:4CB0
    db $77, $77, $77, $78, $88, $88, $88, $87, $78, $77, $77, $88, $88, $88, $88, $88; 15:4CC0
    db $88, $88, $87, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $77, $77, $77; 15:4CD0
    db $77, $77, $88, $88, $88, $87, $88, $77, $77, $77, $78, $88, $88, $88, $88, $88; 15:4CE0
    db $87, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $87, $88; 15:4CF0
    db $87, $88, $88, $88, $88, $87, $87, $87, $87, $88, $88, $88, $88, $88, $88, $88; 15:4D00
    db $87, $77, $59, $75, $97, $88, $88, $98, $88, $97, $87, $77, $77, $77, $87, $87; 15:4D10
    db $88, $87, $88, $78, $67, $78, $87, $85, $85, $99, $88, $78, $89, $89, $89, $78; 15:4D20
    db $78, $78, $78, $87, $87, $97, $97, $97, $97, $87, $97, $87, $87, $87, $77, $77; 15:4D30
    db $67, $77, $67, $77, $87, $78, $78, $78, $77, $86, $87, $87, $78, $6A, $6A, $5A; 15:4D40
    db $78, $78, $78, $88, $79, $79, $88, $98, $89, $79, $78, $88, $88, $78, $76, $95; 15:4D50
    db $A5, $95, $96, $87, $87, $86, $86, $96, $87, $6A, $59, $68, $86, $96, $88, $78; 15:4D60
    db $68, $86, $96, $96, $87, $79, $87, $A6, $96, $87, $6A, $59, $88, $78, $88, $7A; 15:4D70
    db $5A, $69, $68, $96, $98, $78, $88, $78, $86, $87, $87, $87, $69, $69, $59, $78; 15:4D80
    db $87, $77, $87, $78, $78, $87, $77, $95, $96, $97, $78, $78, $87, $86, $97, $88; 15:4D90
    db $69, $78, $77, $96, $97, $79, $88, $69, $87, $87, $87, $78, $69, $68, $87, $97; 15:4DA0
    db $87, $89, $68, $78, $87, $86, $87, $77, $78, $78, $87, $88, $78, $88, $78, $78; 15:4DB0
    db $68, $88, $78, $88, $89, $88, $88, $77, $87, $78, $77, $87, $77, $87, $77, $77; 15:4DC0
    db $77, $77, $77, $66, $66, $66, $66, $77, $78, $89, $9A, $AA, $BB, $AC, $CB, $CC; 15:4DD0
    db $CC, $EE, $EB, $45, $93, $00, $00, $00, $00, $22, $22, $9B, $BE, $BD, $FE, $B8; 15:4DE0
    db $BA, $66, $57, $78, $88, $CD, $CD, $FF, $FF, $FF, $F9, $1F, $81, $00, $10, $00; 15:4DF0
    db $02, $04, $03, $F8, $FC, $CF, $FF, $68, $D7, $50, $23, $26, $15, $BB, $B9, $FF; 15:4E00
    db $FF, $FF, $FF, $FF, $45, $F4, $00, $01, $00, $00, $61, $50, $BF, $9F, $CF, $FE; 15:4E10
    db $F4, $8A, $31, $02, $10, $42, $6A, $BB, $BF, $FE, $FF, $FF, $FF, $FC, $0C, $C0; 15:4E20
    db $00, $10, $00, $00, $35, $41, $FE, $DE, $DF, $DF, $A5, $89, $20, $03, $11, $35; 15:4E30
    db $6B, $B9, $BF, $FC, $EF, $FE, $FF, $FF, $62, $E7, $10, $03, $00, $00, $44, $81; 15:4E40
    db $6F, $DD, $AD, $FD, $B8, $58, $92, $00, $64, $13, $59, $B8, $9A, $FF, $AB, $DF; 15:4E50
    db $EB, $FF, $FF, $16, $F7, $20, $03, $01, $00, $45, $70, $7F, $DB, $9C, $FD, $B9; 15:4E60
    db $5A, $A5, $20, $87, $13, $49, $98, $86, $CE, $A9, $AF, $EB, $EF, $FF, $F4, $5F; 15:4E70
    db $B2, $00, $50, $00, $01, $37, $03, $EF, $B8, $DF, $FD, $C8, $AD, $83, $05, $82; 15:4E80
    db $01, $68, $66, $59, $EB, $98, $DF, $CC, $EF, $FF, $FF, $1B, $F5, $00, $20, $00; 15:4E90
    db $00, $02, $50, $6F, $FB, $CF, $FF, $DE, $8A, $B7, $30, $55, $00, $14, $56, $86; 15:4EA0
    db $9E, $CB, $AE, $FC, $CE, $EF, $FF, $FF, $F2, $7C, $40, $00, $00, $00, $00, $37; 15:4EB0
    db $37, $EF, $EE, $FF, $FB, $D8, $78, $64, $01, $42, $02, $45, $69, $88, $BD, $CA; 15:4EC0
    db $BE, $CB, $CB, $CC, $CD, $DF, $FF, $B1, $AC, $40, $00, $00, $00, $01, $78, $37; 15:4ED0
    db $FF, $ED, $DF, $EC, $C5, $57, $63, $01, $54, $22, $48, $8A, $98, $CE, $C9, $8B; 15:4EE0
    db $C9, $87, $8A, $AA, $8A, $EF, $DD, $FF, $94, $A8, $50, $01, $00, $00, $00, $67; 15:4EF0
    db $36, $DF, $ED, $EF, $DE, $D8, $76, $85, $02, $43, $34, $57, $7B, $BA, $AB, $DB; 15:4F00
    db $89, $98, $87, $76, $89, $99, $AC, $DD, $DE, $EE, $FF, $C2, $48, $50, $00, $00; 15:4F10
    db $00, $00, $29, $86, $9F, $FE, $DE, $DA, $DB, $75, $57, $52, $34, $46, $78, $77; 15:4F20
    db $BC, $BA, $AB, $B9, $A8, $66, $77, $55, $78, $9A, $AB, $BC, $EC, $BC, $DD, $CD; 15:4F30
    db $E9, $15, $63, $00, $00, $00, $00, $02, $98, $79, $DD, $FE, $FC, $AD, $CA, $65; 15:4F40
    db $76, $55, $54, $57, $98, $7A, $BB, $AA, $A8, $78, $86, $55, $75, $78, $88, $9B; 15:4F50
    db $CB, $BC, $BB, $BB, $A9, $AB, $AB, $CB, $43, $54, $30, $00, $00, $02, $01, $69; 15:4F60
    db $9A, $CC, $CC, $EE, $AA, $A9, $86, $66, $45, $66, $66, $89, $8A, $BB, $A9, $AA; 15:4F70
    db $87, $65, $55, $66, $57, $89, $AA, $BB, $BC, $CB, $AA, $A9, $88, $88, $88, $AB; 15:4F80
    db $C9, $55, $55, $40, $10, $00, $02, $11, $35, $79, $BA, $BB, $DE, $CD, $BA, $98; 15:4F90
    db $A8, $76, $66, $66, $87, $68, $8A, $9A, $AA, $99, $88, $76, $66, $66, $67, $78; 15:4FA0
    db $99, $9A, $AA, $AA, $A9, $88, $88, $88, $99, $9A, $BC, $C9, $66, $44, $21, $10; 15:4FB0
    db $00, $01, $23, $56, $8B, $DE, $EE, $EE, $DE, $CB, $86, $65, $45, $44, $44, $67; 15:4FC0
    db $8A, $AA, $BB, $CC, $BB, $A8, $65, $65, $44, $44, $56, $88, $9A, $AB, $AB, $BA; 15:4FD0
    db $A9, $98, $88, $98, $89, $99, $AB, $BB, $86, $43, $22, $11, $00, $00, $23, $57; 15:4FE0
    db $78, $AC, $DE, $EE, $DB, $BA, $A9, $76, $54, $45, $55, $66, $78, $9A, $BB, $BB; 15:4FF0
    db $BB, $BA, $98, $54, $33, $44, $55, $56, $78, $9A, $BB, $BB, $BA, $AA, $98, $88; 15:5000
    db $87, $88, $88, $88, $89, $A9, $75, $32, $21, $22, $00, $01, $35, $89, $AA, $BC; 15:5010
    db $DD, $ED, $CA, $98, $77, $76, $54, $45, $56, $89, $99, $9A, $BB, $CC, $BA, $98; 15:5020
    db $76, $55, $44, $45, $66, $88, $89, $9A, $AA, $AA, $98, $88, $88, $88, $88, $88; 15:5030
    db $99, $99, $98, $99, $98, $75, $32, $12, $22, $22, $22, $46, $8A, $BB, $BB, $BB; 15:5040
    db $CC, $BA, $98, $66, $66, $66, $66, $67, $88, $9A, $AA, $AA, $AA, $A9, $87, $65; 15:5050
    db $44, $55, $66, $77, $78, $89, $AA, $A9, $88, $88, $88, $88, $88, $88, $99, $99; 15:5060
    db $98, $88, $88, $99, $86, $53, $22, $22, $22, $22, $34, $58, $9B, $BC, $BB, $BC; 15:5070
    db $CC, $BA, $97, $66, $55, $66, $66, $67, $78, $9A, $AA, $AA, $98, $88, $77, $65; 15:5080
    db $55, $56, $78, $88, $89, $9A, $AA, $AA, $99, $88, $88, $88, $87, $77, $78, $88; 15:5090
    db $88, $77, $77, $77, $88, $87, $55, $43, $34, $44, $45, $45, $57, $89, $AB, $AA; 15:50A0
    db $AA, $AA, $AA, $98, $77, $66, $77, $88, $88, $88, $88, $99, $99, $88, $87, $77; 15:50B0
    db $87, $77, $77, $88, $89, $99, $99, $98, $88, $88, $88, $77, $77, $77, $78, $88; 15:50C0
    db $78, $88, $88, $87, $76, $66, $66, $77, $77, $77, $66, $66, $55, $55, $55, $55; 15:50D0
    db $67, $78, $89, $99, $99, $AA, $AA, $AA, $99, $99, $99, $88, $88, $87, $77, $88; 15:50E0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77; 15:50F0
    db $77, $77, $77, $77, $77, $77, $77, $77, $77, $76, $66, $77, $77, $77, $77, $78; 15:5100
    db $88, $88, $87, $77, $77, $77, $77, $77, $78, $88, $88, $99, $99, $99, $99, $99; 15:5110
    db $88, $88, $88, $88, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $77, $77; 15:5120
    db $77, $77, $77, $77, $77, $77, $88, $87, $77, $77, $77, $77, $77, $77, $77, $77; 15:5130
    db $77, $77, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88; 15:5140
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:5150
    db $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77; 15:5160
    db $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:5170
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:5180

;; PCM24: 3616 bytes = 7232 4-bit samples (rate 2) for SFXInst38
PCM24:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:5190
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:51A0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:51B0
    db $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $77, $77, $77; 15:51C0
    db $77, $78, $88, $77, $77, $77, $77, $77, $77, $87, $77, $88, $88, $78, $88, $88; 15:51D0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $88; 15:51E0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $78, $88, $88, $88, $88; 15:51F0
    db $88, $88, $87, $77, $77, $66, $66, $66, $77, $77, $77, $88, $88, $88, $88, $88; 15:5200
    db $88, $89, $99, $99, $99, $98, $88, $88, $88, $88, $88, $88, $88, $89, $9A, $B9; 15:5210
    db $86, $21, $00, $00, $26, $68, $98, $9A, $AB, $BB, $A9, $75, $54, $46, $78, $99; 15:5220
    db $99, $89, $9A, $A9, $87, $76, $68, $89, $AA, $AA, $99, $9A, $A9, $99, $88, $88; 15:5230
    db $9A, $CD, $B9, $70, $00, $00, $01, $66, $67, $78, $AC, $DD, $D9, $65, $11, $44; 15:5240
    db $79, $9A, $A9, $AB, $BC, $CA, $87, $43, $55, $79, $9A, $A9, $AA, $AB, $BA, $88; 15:5250
    db $77, $88, $AB, $BB, $BC, $DF, $C8, $70, $00, $00, $11, $65, $56, $9B, $CF, $FA; 15:5260
    db $A5, $02, $13, $77, $88, $88, $AD, $DF, $FA, $96, $23, $44, $67, $67, $9A, $BE; 15:5270
    db $CB, $B7, $77, $78, $99, $9A, $BB, $EF, $FF, $C2, $50, $00, $03, $42, $22, $9A; 15:5280
    db $FF, $EC, $90, $13, $25, $54, $14, $9A, $FF, $EE, $95, $67, $74, $30, $05, $7B; 15:5290
    db $FE, $B9, $89, $AC, $86, $63, $6B, $BD, $DC, $CE, $FF, $F7, $00, $00, $11, $40; 15:52A0
    db $20, $AF, $FF, $F2, $03, $25, $21, $00, $8B, $FF, $EB, $AB, $CB, $A1, $00, $04; 15:52B0
    db $AA, $99, $CD, $EF, $95, $53, $8A, $97, $79, $BF, $FF, $DE, $FF, $60, $00, $02; 15:52C0
    db $01, $06, $8F, $FF, $99, $43, $63, $00, $02, $5F, $FB, $EF, $FF, $E8, $00, $31; 15:52D0
    db $24, $35, $BF, $FE, $C8, $8A, $85, $45, $59, $DB, $AC, $DF, $FF, $FF, $90, $00; 15:52E0
    db $02, $00, $08, $FE, $FF, $8B, $F9, $30, $00, $07, $52, $AF, $FF, $FD, $6A, $A4; 15:52F0
    db $00, $00, $6A, $79, $DE, $EF, $A6, $68, $66, $77, $8B, $DC, $DF, $FF, $FB, $00; 15:5300
    db $20, $00, $00, $8F, $C8, $CF, $FF, $92, $01, $31, $00, $4A, $EF, $DC, $FF, $E7; 15:5310
    db $42, $22, $10, $27, $BB, $CC, $DE, $C9, $77, $88, $88, $9B, $DF, $FF, $E0, $48; 15:5320
    db $00, $00, $04, $A7, $5F, $FF, $D8, $94, $72, $00, $14, $75, $8B, $FF, $FC, $AB; 15:5330
    db $96, $00, $04, $45, $6B, $DE, $CB, $BC, $B9, $88, $AA, $BB, $EF, $F2, $0B, $52; 15:5340
    db $00, $02, $77, $46, $FF, $E7, $AA, $A5, $20, $16, $55, $29, $CE, $AC, $AD, $A8; 15:5350
    db $32, $45, $42, $58, $B9, $BA, $DC, $C9, $AA, $CB, $BC, $FF, $C0, $0A, $40, $00; 15:5360
    db $26, $57, $3C, $FF, $96, $AC, $91, $20, $65, $62, $69, $EB, $9A, $BC, $85, $35; 15:5370
    db $55, $24, $6B, $AA, $9C, $CD, $AA, $BC, $CB, $CE, $FB, $01, $85, $00, $04, $52; 15:5380
    db $65, $DF, $FB, $89, $D9, $10, $25, $43, $37, $9F, $BB, $AD, $BA, $44, $44, $32; 15:5390
    db $37, $AA, $BB, $DE, $EC, $BB, $CC, $CD, $FA, $01, $75, $00, $04, $41, $57, $DE; 15:53A0
    db $FD, $A8, $CA, $50, $04, $52, $25, $8D, $DC, $BB, $BB, $74, $24, $43, $25, $8B; 15:53B0
    db $BB, $CF, $FF, $DC, $CE, $FF, $A0, $05, $71, $00, $38, $53, $4C, $FF, $DB, $79; 15:53C0
    db $A8, $30, $05, $75, $35, $CE, $EB, $99, $B9, $72, $13, $65, $56, $AD, $EC, $CD; 15:53D0
    db $FF, $ED, $EF, $F3, $00, $46, $00, $05, $88, $48, $DF, $FF, $86, $67, $81, $00; 15:53E0
    db $48, $85, $8C, $FF, $C8, $77, $75, $10, $25, $89, $9B, $DF, $FE, $EE, $FF, $FF; 15:53F0
    db $70, $02, $71, $00, $29, $B6, $6B, $FF, $FB, $75, $47, $61, $00, $5C, $96, $8D; 15:5400
    db $FE, $97, $67, $65, $22, $26, $AB, $AA, $DF, $FF, $DE, $FF, $F7, $00, $06, $20; 15:5410
    db $00, $8C, $96, $9E, $FF, $D8, $64, $66, $30, $01, $8A, $97, $9D, $FE, $A7, $67; 15:5420
    db $54, $22, $36, $AB, $BB, $EF, $FF, $FF, $FD, $10, $02, $10, $00, $3A, $98, $AE; 15:5430
    db $FF, $FC, $95, $45, $51, $00, $48, $A8, $8B, $EE, $C9, $87, $65, $44, $45, $8B; 15:5440
    db $DD, $DE, $FF, $FF, $B2, $01, $52, $00, $01, $98, $77, $BF, $FF, $EA, $66, $78; 15:5450
    db $50, $00, $69, $86, $6A, $EE, $B9, $87, $76, $65, $55, $8B, $EE, $EF, $FF, $F7; 15:5460
    db $11, $54, $00, $00, $24, $68, $AB, $CF, $FF, $B6, $56, $75, $10, $14, $67, $89; 15:5470
    db $99, $AC, $DA, $75, $68, $87, $79, $BD, $EF, $FF, $E6, $34, $76, $00, $00, $13; 15:5480
    db $57, $88, $AC, $FF, $D9, $67, $88, $54, $23, $35, $78, $87, $68, $AB, $A8, $77; 15:5490
    db $89, $AB, $BB, $BE, $FF, $F8, $32, $56, $30, $00, $00, $48, $B9, $77, $BE, $FE; 15:54A0
    db $C9, $75, $57, $87, $42, $35, $78, $99, $86, $78, $AA, $98, $99, $BC, $EF, $FF; 15:54B0
    db $D9, $53, $44, $31, $00, $00, $26, $9A, $98, $9A, $BC, $DC, $A7, $55, $67, $77; 15:54C0
    db $65, $45, $78, $98, $87, $77, $89, $AB, $CC, $DD, $EF, $FE, $95, $21, $00, $11; 15:54D0
    db $10, $01, $47, $AC, $CC, $A8, $9B, $BB, $A9, $75, $44, $66, $66, $66, $65, $68; 15:54E0
    db $9A, $A9, $88, $9B, $DF, $FF, $FF, $B8, $54, $20, $01, $10, $00, $23, $58, $BC; 15:54F0
    db $CB, $BB, $AA, $AB, $A8, $76, $54, $34, $56, $66, $66, $78, $9A, $AA, $BB, $BB; 15:5500
    db $DE, $FF, $FE, $B7, $41, $00, $01, $11, $12, $23, $58, $AB, $CD, $DC, $AA, $99; 15:5510
    db $99, $97, $65, $32, $23, $56, $78, $99, $99, $AA, $BC, $DD, $EE, $EF, $EB, $96; 15:5520
    db $30, $00, $00, $12, $22, $35, $67, $8B, $CD, $DD, $CB, $99, $98, $87, $65, $43; 15:5530
    db $22, $35, $68, $9B, $BB, $BB, $BB, $CD, $EE, $FF, $EB, $A6, $20, $00, $00, $22; 15:5540
    db $23, $45, $56, $8A, $BD, $ED, $DB, $A9, $88, $76, $55, $44, $33, $34, $57, $9A; 15:5550
    db $BC, $CB, $BB, $BC, $CD, $EF, $FD, $C8, $41, $00, $00, $02, $24, $55, $56, $78; 15:5560
    db $AC, $EE, $EE, $CB, $97, $54, $44, $34, $44, $55, $56, $89, $AB, $CC, $CC, $BB; 15:5570
    db $BC, $CD, $EE, $DB, $84, $10, $00, $00, $13, $55, $67, $78, $9A, $BC, $DE, $DD; 15:5580
    db $B8, $65, $33, $33, $34, $56, $67, $88, $AA, $AB, $BB, $BB, $BB, $BC, $DE, $DD; 15:5590
    db $B7, $52, $00, $00, $00, $25, $58, $89, $AB, $AC, $CC, $DC, $BA, $86, $43, $22; 15:55A0
    db $24, $45, $78, $89, $9A, $AA, $BA, $BB, $BB, $BC, $DE, $ED, $CB, $75, $20, $00; 15:55B0
    db $00, $02, $56, $99, $AB, $BB, $CD, $CC, $BA, $97, $53, $22, $23, $45, $78, $89; 15:55C0
    db $AA, $A9, $99, $9A, $AB, $CC, $CD, $EE, $DD, $A5, $30, $00, $00, $01, $46, $8A; 15:55D0
    db $AB, $CB, $BC, $BB, $BA, $97, $53, $22, $22, $45, $79, $9A, $BA, $A9, $88, $89; 15:55E0
    db $AA, $CC, $DE, $FF, $FD, $C7, $41, $00, $00, $01, $37, $8B, $CC, $DC, $BC, $BA; 15:55F0
    db $B9, $86, $43, $11, $22, $57, $8A, $BA, $B9, $88, $77, $78, $9A, $CE, $EF, $FF; 15:5600
    db $FD, $C6, $20, $00, $00, $02, $48, $AC, $DD, $EC, $CC, $B9, $97, $54, $22, $13; 15:5610
    db $45, $8A, $BC, $BA, $97, $65, $56, $68, $AC, $EF, $FF, $FF, $EC, $92, $00, $00; 15:5620
    db $00, $15, $9B, $DE, $DD, $DA, $BA, $87, $64, $22, $22, $47, $8B, $DC, $CA, $87; 15:5630
    db $55, $45, $67, $9B, $BE, $FF, $FF, $FF, $C9, $00, $00, $00, $05, $9D, $ED, $EB; 15:5640
    db $AB, $99, $87, $52, $20, $14, $7A, $EE, $EC, $A7, $44, $33, $56, $68, $8A, $BD; 15:5650
    db $FF, $FF, $FF, $E8, $50, $00, $00, $05, $9B, $FE, $CD, $BA, $98, $74, $21, $02; 15:5660
    db $47, $CE, $FF, $DA, $64, $32, $45, $56, $67, $8A, $DE, $FF, $FE, $EE, $FB, $86; 15:5670
    db $00, $00, $01, $8B, $CE, $A8, $75, $66, $67, $65, $56, $9A, $EF, $EC, $83, $00; 15:5680
    db $02, $58, $9B, $A9, $99, $BC, $CD, $DD, $CD, $FF, $C9, $50, $00, $00, $4A, $AB; 15:5690
    db $96, $65, $67, $76, $65, $68, $CE, $FF, $D9, $51, $00, $24, $78, $98, $88, $99; 15:56A0
    db $AB, $BB, $CC, $DE, $FF, $FC, $72, $00, $00, $37, $CA, $96, $45, $57, $76, $44; 15:56B0
    db $58, $CF, $FF, $D7, $31, $01, $46, $88, $87, $78, $89, $9A, $BB, $CD, $EE, $FF; 15:56C0
    db $FF, $A5, $00, $00, $26, $BD, $97, $43, $55, $76, $42, $58, $BF, $FF, $C7, $31; 15:56D0
    db $13, $58, $88, $76, $77, $78, $88, $AC, $DE, $ED, $DE, $FF, $F8, $30, $00, $06; 15:56E0
    db $AE, $B7, $30, $36, $67, $52, $27, $BF, $FF, $B7, $22, $35, $78, $75, $66, $79; 15:56F0
    db $87, $67, $9C, $EE, $EC, $BC, $EF, $FF, $60, $00, $02, $BC, $B5, $21, $28, $96; 15:5700
    db $41, $14, $CF, $FF, $A5, $34, $68, $85, $43, $49, $99, $85, $46, $9C, $EE, $BA; 15:5710
    db $AB, $FF, $FF, $E0, $00, $01, $7A, $75, $24, $57, $96, $11, $26, $BF, $FD, $96; 15:5720
    db $78, $88, $53, $25, $7A, $B7, $53, $48, $BD, $CB, $AA, $CE, $FF, $FF, $F2, $00; 15:5730
    db $00, $48, $66, $24, $45, $76, $32, $47, $9E, $DB, $A8, $89, $87, $44, $37, $89; 15:5740
    db $96, $45, $68, $AB, $AA, $BB, $DE, $FF, $FF, $F5, $00, $00, $49, $65, $13, $56; 15:5750
    db $87, $32, $58, $AD, $B9, $88, $AA, $96, $33, $48, $98, $74, $46, $89, $A9, $9B; 15:5760
    db $CD, $EE, $EF, $FF, $F2, $00, $01, $78, $32, $05, $78, $74, $13, $8B, $BB, $87; 15:5770
    db $9B, $DA, $63, $35, $79, $75, $55, $78, $88, $78, $AD, $ED, $DD, $EF, $FF, $B0; 15:5780
    db $00, $14, $64, $02, $49, $85, $42, $38, $BA, $77, $79, $DD, $B6, $55, $77, $76; 15:5790
    db $55, $78, $77, $67, $8B, $CC, $CC, $EF, $FF, $FF, $70, $20, $12, $20, $03, $57; 15:57A0
    db $54, $35, $6B, $A7, $78, $9B, $CB, $87, $87, $75, $55, $57, $87, $67, $78, $9A; 15:57B0
    db $BB, $CE, $FF, $FF, $FF, $34, $40, $33, $00, $02, $55, $34, $55, $9B, $87, $89; 15:57C0
    db $9B, $B9, $9A, $98, $87, $65, $66, $55, $56, $67, $88, $AB, $BC, $DE, $FF, $FF; 15:57D0
    db $BC, $96, $76, $30, $10, $01, $10, $13, $44, $56, $67, $8A, $BB, $CC, $BC, $DC; 15:57E0
    db $A9, $87, $76, $65, $56, $68, $8A, $AB, $DF, $FF, $BC, $A7, $88, $52, $32, $02; 15:57F0
    db $20, $12, $44, $45, $55, $79, $A9, $AB, $BB, $DC, $AA, $A8, $88, $76, $66, $67; 15:5800
    db $88, $9A, $CD, $FF, $DB, $C8, $78, $74, $23, $11, $21, $01, $34, $45, $56, $68; 15:5810
    db $99, $89, $AA, $BC, $BA, $AA, $99, $86, $67, $77, $88, $8A, $BD, $EF, $FC, $BC; 15:5820
    db $76, $76, $21, $30, $12, $21, $24, $45, $56, $67, $89, $99, $99, $AB, $CB, $AA; 15:5830
    db $99, $98, $77, $77, $78, $88, $9B, $CE, $FF, $CB, $B7, $67, $63, $12, $00, $22; 15:5840
    db $22, $43, $46, $66, $78, $99, $9A, $AA, $BB, $BA, $AA, $99, $87, $77, $77, $88; 15:5850
    db $89, $AB, $CE, $FF, $BC, $B6, $67, $62, $23, $00, $22, $12, $54, $46, $66, $79; 15:5860
    db $A9, $AA, $9A, $BB, $AA, $A9, $88, $87, $77, $77, $88, $9B, $BB, $DF, $FF, $B9; 15:5870
    db $95, $54, $42, $00, $02, $12, $55, $44, $66, $78, $AA, $99, $AA, $9A, $AA, $98; 15:5880
    db $88, $88, $87, $67, $78, $89, $99, $AB, $CD, $EF, $FD, $9A, $75, $46, $40, $00; 15:5890
    db $00, $23, $34, $55, $56, $8A, $9A, $BA, $A9, $BA, $9A, $A8, $88, $77, $78, $77; 15:58A0
    db $78, $88, $9A, $BB, $CE, $EF, $FC, $AA, $65, $56, $20, $10, $00, $21, $23, $55; 15:58B0
    db $57, $89, $9B, $BB, $AB, $BA, $AA, $98, $88, $66, $76, $67, $77, $78, $9A, $BC; 15:58C0
    db $CD, $EF, $FD, $CB, $84, $45, $21, $21, $00, $10, $13, $55, $58, $98, $AB, $BB; 15:58D0
    db $BB, $BA, $BA, $98, $76, $56, $66, $67, $77, $79, $9A, $BC, $CC, $DE, $EF, $DB; 15:58E0
    db $B8, $43, $31, $02, $10, $02, $01, $45, $57, $A9, $AC, $CB, $BB, $AA, $AA, $88; 15:58F0
    db $86, $56, $55, $56, $67, $88, $89, $AB, $BC, $CC, $DE, $DE, $DA, $B8, $43, $20; 15:5900
    db $00, $00, $02, $12, $65, $68, $AA, $BE, $DB, $CB, $88, $98, $78, $75, $56, $55; 15:5910
    db $56, $67, $88, $9A, $BB, $BC, $CC, $CD, $CD, $ED, $AA, $83, $32, $00, $00, $01; 15:5920
    db $32, $37, $76, $AB, $AB, $EC, $BC, $B8, $89, $66, $76, $55, $65, $56, $66, $78; 15:5930
    db $89, $BB, $CC, $CC, $CC, $CC, $CD, $DB, $9A, $52, $20, $00, $00, $03, $44, $7A; 15:5940
    db $79, $BB, $BC, $EA, $BB, $87, $77, $46, $65, $57, $65, $76, $67, $88, $9B, $BC; 15:5950
    db $CC, $CC, $CC, $CC, $CC, $DB, $89, $40, $00, $00, $00, $04, $55, $7A, $7A, $CC; 15:5960
    db $BC, $D8, $88, $65, $67, $57, $76, $67, $64, $77, $78, $AA, $AB, $BB, $BC, $CC; 15:5970
    db $DC, $CB, $BB, $CD, $98, $70, $00, $00, $03, $14, $66, $59, $A9, $DE, $EA, $B9; 15:5980
    db $46, $65, $59, $76, $66, $44, $77, $8A, $A8, $78, $78, $AC, $CD, $DB, $BA, $BB; 15:5990
    db $DE, $EF, $B5, $50, $00, $01, $04, $10, $35, $6A, $FE, $EC, $B6, $59, $68, $98; 15:59A0
    db $44, $44, $58, $B8, $98, $66, $79, $9A, $B9, $89, $9B, $DD, $CB, $BB, $BD, $FF; 15:59B0
    db $F5, $40, $00, $03, $00, $10, $06, $BC, $FF, $B6, $79, $7C, $B7, $22, $23, $8B; 15:59C0
    db $B7, $74, $58, $CC, $A8, $54, $6A, $CD, $BA, $78, $BE, $EE, $DA, $BD, $FE, $44; 15:59D0
    db $00, $00, $50, $00, $04, $CF, $ED, $8A, $7D, $E9, $70, $11, $58, $95, $55, $7B; 15:59E0
    db $CF, $97, $67, $79, $97, $45, $9A, $DC, $B9, $BD, $EE, $EC, $BE, $FA, $01, $00; 15:59F0
    db $00, $20, $02, $8A, $ED, $BB, $CF, $A9, $43, $33, $64, $01, $68, $CB, $B8, $8C; 15:5A00
    db $DB, $86, $56, $69, $56, $8A, $CC, $CB, $AC, $ED, $CA, $BD, $EF, $90, $13, $31; 15:5A10
    db $00, $01, $99, $65, $BF, $F9, $D5, $89, $86, $01, $67, $56, $69, $9E, $D8, $8B; 15:5A20
    db $C8, $66, $55, $98, $66, $AC, $BA, $AB, $BC, $BA, $9C, $CC, $CE, $F5, $08, $42; 15:5A30
    db $00, $30, $45, $33, $9F, $D8, $9F, $9A, $67, $54, $84, $25, $99, $78, $CA, $A8; 15:5A40
    db $98, $89, $75, $68, $87, $8A, $9A, $99, $9A, $BA, $9A, $BA, $AB, $DE, $FF, $40; 15:5A50
    db $B6, $00, $07, $02, $00, $7B, $C5, $8E, $E7, $87, $98, $66, $39, $87, $68, $B9; 15:5A60
    db $79, $9A, $88, $87, $97, $68, $99, $88, $A8, $98, $89, $98, $88, $BA, $AA, $CE; 15:5A70
    db $EF, $FF, $02, $D0, $00, $20, $04, $06, $98, $76, $FC, $78, $A9, $76, $77, $AA; 15:5A80
    db $59, $BB, $77, $98, $77, $57, $78, $67, $AA, $88, $99, $88, $78, $87, $78, $98; 15:5A90
    db $8A, $BC, $BB, $CD, $DC, $DF, $E0, $1C, $00, $02, $00, $50, $7B, $85, $5F, $85; 15:5AA0
    db $89, $A7, $97, $9E, $96, $9C, $95, $78, $76, $56, $88, $67, $BB, $98, $9A, $87; 15:5AB0
    db $67, $87, $66, $99, $88, $9B, $BA, $AB, $CB, $BC, $DD, $CE, $F5, $0A, $20, $00; 15:5AC0
    db $10, $20, $0B, $89, $5F, $E5, $A8, $B7, $88, $6C, $A6, $8A, $B5, $68, $78, $67; 15:5AD0
    db $7A, $A6, $AB, $B8, $79, $77, $55, $77, $86, $8A, $99, $8B, $A9, $98, $BA, $9A; 15:5AE0
    db $BC, $BA, $BB, $DE, $70, $67, $00, $04, $01, $41, $B9, $84, $AF, $57, $7A, $88; 15:5AF0
    db $B6, $CC, $87, $8C, $65, $76, $87, $87, $AC, $9A, $AA, $86, $86, $86, $57, $79; 15:5B00
    db $67, $99, $97, $89, $99, $89, $AA, $A9, $BB, $AA, $AA, $9A, $AB, $A0, $08, $00; 15:5B10
    db $03, $20, $61, $6A, $86, $3D, $86, $87, $A8, $C9, $9E, $A9, $8A, $95, $76, $77; 15:5B20
    db $78, $7A, $98, $9A, $97, $88, $78, $88, $78, $97, $88, $77, $78, $78, $98, $9A; 15:5B30
    db $A9, $9A, $9A, $AA, $AA, $A8, $AB, $C7, $04, $50, $00, $30, $36, $07, $AA, $66; 15:5B40
    db $D8, $88, $79, $AC, $88, $CA, $96, $87, $67, $56, $79, $87, $AA, $A9, $99, $89; 15:5B50
    db $77, $88, $86, $78, $77, $68, $77, $87, $89, $A9, $9B, $A9, $9A, $A9, $98, $89; 15:5B60
    db $87, $78, $89, $B6, $04, $50, $00, $41, $57, $26, $AA, $56, $A8, $88, $87, $BD; 15:5B70
    db $98, $BB, $98, $86, $78, $65, $79, $98, $AA, $AA, $A8, $78, $77, $76, $77, $77; 15:5B80
    db $78, $78, $78, $88, $88, $99, $9A, $AA, $AA, $A9, $98, $77, $76, $66, $67, $78; 15:5B90
    db $AA, $12, $63, $11, $22, $48, $44, $8B, $87, $98, $89, $86, $8C, $A9, $AA, $A9; 15:5BA0
    db $A8, $68, $87, $68, $88, $99, $99, $A9, $77, $77, $77, $77, $88, $77, $88, $77; 15:5BB0
    db $77, $88, $88, $99, $99, $99, $99, $87, $77, $77, $77, $67, $77, $78, $89, $83; 15:5BC0
    db $46, $53, $34, $36, $75, $58, $98, $88, $88, $99, $79, $AA, $9A, $98, $9A, $87; 15:5BD0
    db $88, $77, $87, $88, $88, $89, $88, $88, $88, $87, $78, $88, $87, $77, $77, $77; 15:5BE0
    db $88, $88, $88, $88, $99, $99, $98, $88, $87, $87, $77, $77, $77, $77, $88, $76; 15:5BF0
    db $77, $55, $55, $34, $43, $35, $55, $68, $88, $99, $AB, $BA, $AB, $AA, $AA, $A9; 15:5C00
    db $99, $88, $88, $87, $77, $66, $66, $67, $77, $77, $78, $88, $88, $88, $88, $88; 15:5C10
    db $88, $99, $99, $99, $99, $88, $88, $88, $77, $77, $76, $76, $66, $67, $78, $88; 15:5C20
    db $77, $75, $66, $54, $45, $44, $65, $57, $88, $89, $99, $AB, $AA, $AA, $AA, $A9; 15:5C30
    db $99, $98, $88, $88, $87, $76, $66, $66, $77, $77, $77, $88, $88, $88, $88, $88; 15:5C40
    db $88, $98, $88, $88, $88, $88, $88, $88, $87, $77, $77, $66, $66, $66, $66, $77; 15:5C50
    db $88, $77, $76, $66, $64, $45, $43, $55, $56, $88, $78, $99, $AB, $AA, $AB, $AA; 15:5C60
    db $AA, $A9, $99, $88, $88, $88, $77, $77, $77, $77, $77, $78, $78, $88, $88, $88; 15:5C70
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $66, $77, $66, $66, $77; 15:5C80
    db $78, $88, $87, $77, $56, $65, $44, $54, $55, $56, $78, $88, $99, $9A, $BA, $AA; 15:5C90
    db $AA, $AA, $A9, $99, $88, $87, $77, $76, $66, $77, $77, $77, $88, $88, $88, $88; 15:5CA0
    db $88, $88, $88, $88, $88, $98, $88, $88, $88, $87, $77, $77, $76, $66, $66, $66; 15:5CB0
    db $77, $77, $88, $88, $77, $76, $66, $54, $55, $45, $66, $67, $88, $89, $99, $AA; 15:5CC0
    db $A9, $AA, $AA, $A9, $99, $88, $88, $87, $77, $77, $77, $77, $88, $78, $88, $88; 15:5CD0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77; 15:5CE0
    db $77, $66, $77, $77, $77, $88, $77, $76, $66, $65, $55, $45, $55, $67, $87, $89; 15:5CF0
    db $99, $AA, $AA, $AA, $AA, $A9, $99, $98, $88, $88, $77, $77, $77, $77, $78, $88; 15:5D00
    db $88, $88, $88, $88, $88, $88, $88, $98, $88, $88, $88, $88, $77, $77, $77, $77; 15:5D10
    db $76, $66, $66, $66, $66, $66, $77, $78, $88, $77, $77, $77, $66, $66, $66, $67; 15:5D20
    db $78, $88, $89, $99, $A9, $99, $99, $99, $99, $99, $88, $88, $88, $77, $77, $77; 15:5D30
    db $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77; 15:5D40
    db $77, $77, $76, $66, $66, $66, $66, $77, $77, $77, $88, $88, $88, $88, $88, $77; 15:5D50
    db $77, $77, $77, $77, $77, $78, $88, $88, $88, $99, $99, $99, $99, $99, $98, $88; 15:5D60
    db $88, $88, $78, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:5D70
    db $77, $77, $77, $77, $66, $66, $66, $66, $66, $77, $77, $77, $77, $77, $78, $88; 15:5D80
    db $88, $88, $88, $88, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88; 15:5D90
    db $88, $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $98, $89, $88, $88, $88; 15:5DA0
    db $87, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77; 15:5DB0
    db $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:5DC0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:5DD0
    db $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $77, $77, $77; 15:5DE0
    db $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:5DF0
    db $88, $88, $87, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:5E00
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $77; 15:5E10
    db $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:5E20
    db $88, $88, $88, $87, $77, $87, $77, $78, $77, $78, $87, $87, $87, $87, $88, $78; 15:5E30
    db $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $87, $78; 15:5E40
    db $77, $78, $78, $87, $78, $77, $88, $78, $88, $78, $77, $78, $78, $88, $88, $87; 15:5E50
    db $88, $77, $87, $87, $87, $77, $77, $88, $88, $87, $88, $88, $88, $88, $88, $88; 15:5E60
    db $88, $88, $88, $88, $87, $77, $77, $77, $77, $87, $78, $88, $88, $88, $78, $78; 15:5E70
    db $87, $87, $77, $87, $77, $87, $88, $87, $88, $88, $88, $78, $88, $88, $88, $88; 15:5E80
    db $88, $88, $88, $88, $88, $88, $88, $78, $78, $87, $77, $77, $77, $77, $77, $78; 15:5E90
    db $88, $88, $88, $88, $88, $88, $88, $78, $88, $78, $78, $78, $78, $88, $88, $88; 15:5EA0
    db $88, $88, $77, $87, $77, $87, $88, $87, $88, $88, $88, $78, $88, $88, $88, $87; 15:5EB0
    db $87, $87, $88, $78, $77, $77, $87, $87, $88, $78, $88, $87, $88, $88, $88, $88; 15:5EC0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $87; 15:5ED0
    db $88, $77, $77, $77, $77, $77, $77, $77, $77, $78, $78, $78, $78, $78, $78, $78; 15:5EE0
    db $88, $78, $78, $78, $88, $78, $78, $88, $88, $88, $88, $87, $88, $87, $87, $88; 15:5EF0
    db $88, $78, $88, $88, $88, $88, $88, $78, $78, $78, $78, $78, $78, $78, $78, $88; 15:5F00
    db $88, $88, $88, $87, $88, $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88; 15:5F10
    db $88, $88, $88, $88, $88, $88, $88, $77, $78, $88, $88, $78, $77, $87, $87, $87; 15:5F20
    db $77, $77, $77, $77, $77, $77, $78, $77, $77, $87, $87, $88, $88, $88, $88, $88; 15:5F30
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $88, $78, $88, $78, $78, $78; 15:5F40
    db $78, $77, $78, $78, $87, $88, $87, $88, $88, $88, $88, $87, $87, $77, $77, $77; 15:5F50
    db $77, $87, $87, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:5F60
    db $88, $88, $88, $88, $88, $88, $87, $87, $87, $87, $77, $87, $77, $87, $88, $87; 15:5F70
    db $88, $78, $87, $77, $77, $78, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:5F80
    db $88, $88, $88, $78, $88, $88, $88, $88, $78, $78, $78, $78, $88, $78, $78, $78; 15:5F90
    db $78, $78, $87, $77, $77, $78, $78, $88, $87, $88, $88, $78, $88, $88, $88, $88; 15:5FA0

;; PCM25: 3440 bytes = 6880 4-bit samples (rate 2) for SFXInst39
PCM25:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $88, $88, $77; 15:5FB0
    db $88, $87, $87, $77, $78, $88, $88, $77, $78, $88, $88, $88, $77, $78, $88, $88; 15:5FC0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $78, $88; 15:5FD0
    db $88, $88, $88, $78, $88, $88, $77, $65, $44, $44, $55, $67, $78, $88, $99, $99; 15:5FE0
    db $99, $99, $99, $99, $99, $99, $AA, $AA, $A9, $99, $88, $88, $99, $99, $AC, $D8; 15:5FF0
    db $74, $00, $00, $02, $34, $45, $59, $BC, $FE, $CA, $65, $45, $67, $87, $67, $79; 15:6000
    db $BB, $DC, $A8, $77, $68, $87, $87, $79, $AB, $CC, $BA, $A9, $9A, $99, $98, $99; 15:6010
    db $AC, $EF, $95, $20, $00, $01, $22, $01, $45, $CF, $FF, $C6, $44, $56, $77, $23; 15:6020
    db $44, $AE, $EF, $DB, $89, $98, $86, $33, $35, $9C, $CB, $A9, $9C, $BB, $A7, $66; 15:6030
    db $8A, $BD, $CC, $EF, $FF, $A0, $00, $00, $01, $00, $06, $FF, $FF, $73, $47, $60; 15:6040
    db $20, $04, $9E, $FF, $CB, $FF, $DE, $40, $00, $24, $76, $6D, $EF, $FC, $87, $89; 15:6050
    db $88, $54, $8A, $DF, $ED, $EF, $FF, $D0, $00, $01, $00, $01, $BD, $FF, $9A, $AC; 15:6060
    db $83, $00, $03, $47, $89, $BF, $FF, $DB, $56, $65, $00, $02, $6D, $BA, $BE, $FD; 15:6070
    db $B7, $36, $88, $66, $99, $DF, $EF, $FF, $FF, $00, $00, $00, $00, $0E, $EC, $EE; 15:6080
    db $EF, $F9, $00, $00, $00, $02, $BF, $FE, $FF, $FF, $B4, $01, $00, $00, $59, $EF; 15:6090
    db $DE, $DC, $C9, $75, $67, $68, $9A, $DF, $FF, $FF, $10, $80, $00, $00, $0A, $55; 15:60A0
    db $FF, $FF, $CB, $59, $50, $00, $02, $57, $9D, $FF, $FF, $FC, $85, $00, $00, $02; 15:60B0
    db $7C, $DF, $ED, $FE, $A8, $78, $77, $87, $BD, $FF, $FA, $0D, $80, $00, $00, $41; 15:60C0
    db $06, $FE, $DB, $FD, $AB, $00, $34, $00, $29, $6C, $CC, $FF, $EA, $B9, $51, $10; 15:60D0
    db $13, $55, $9D, $DC, $EE, $DC, $B9, $9A, $98, $AE, $FD, $05, $F2, $00, $22, $23; 15:60E0
    db $02, $EC, $7A, $BF, $88, $56, $66, $01, $47, $53, $9B, $EC, $CB, $D9, $84, $55; 15:60F0
    db $42, $35, $88, $8A, $CE, $DC, $DD, $DC, $BB, $CD, $D0, $0D, $20, $02, $50, $24; 15:6100
    db $5C, $F6, $AB, $F8, $56, $95, $50, $15, $75, $28, $CC, $8B, $AE, $A8, $57, $76; 15:6110
    db $25, $78, $77, $AC, $CB, $CD, $FD, $DE, $FF, $C0, $1B, $10, $01, $40, $04, $6E; 15:6120
    db $D7, $BE, $FB, $66, $C5, $40, $25, $52, $35, $CB, $8A, $BD, $A7, $78, $76, $36; 15:6130
    db $88, $77, $AE, $CB, $CF, $FE, $EF, $F8, $08, $60, $00, $20, $00, $47, $C9, $CC; 15:6140
    db $FF, $D6, $B9, $71, $14, $51, $34, $7A, $98, $8B, $C9, $78, $98, $54, $78, $78; 15:6150
    db $8C, $DD, $DE, $FF, $FF, $63, $A6, $00, $02, $00, $04, $99, $8C, $FF, $FC, $9C; 15:6160
    db $A7, $10, $35, $11, $29, $A7, $8B, $CC, $98, $99, $74, $47, $77, $7A, $DE, $EF; 15:6170
    db $FF, $FC, $27, $95, $00, $02, $00, $05, $B8, $AC, $FF, $FB, $BA, $B7, $21, $33; 15:6180
    db $41, $27, $98, $89, $CB, $A9, $88, $86, $66, $89, $9A, $CE, $FF, $FF, $E4, $79; 15:6190
    db $50, $00, $20, $00, $5B, $8A, $DF, $FF, $CB, $88, $73, $00, $25, $23, $6A, $BA; 15:61A0
    db $9C, $BA, $87, $66, $56, $57, $9B, $DE, $EF, $FF, $F9, $26, $73, $00, $03, $00; 15:61B0
    db $09, $EC, $CD, $FF, $EB, $85, $65, $20, $02, $75, $56, $AD, $CA, $AA, $A8, $65; 15:61C0
    db $56, $77, $8A, $DF, $FF, $FF, $F9, $25, $73, $00, $02, $00, $07, $DD, $DE, $EF; 15:61D0
    db $FD, $95, $56, $40, $01, $66, $55, $8C, $CA, $99, $B9, $76, $56, $88, $99, $CF; 15:61E0
    db $FF, $FF, $B5, $79, $60, $00, $20, $00, $6A, $BB, $DF, $FE, $EB, $76, $65, $30; 15:61F0
    db $15, $65, $47, $BC, $A9, $9B, $97, $65, $78, $89, $AC, $FF, $FF, $F7, $58, $A3; 15:6200
    db $00, $02, $00, $09, $BA, $9C, $EF, $DD, $97, $77, $62, $03, $66, $44, $8B, $A9; 15:6210
    db $8A, $B9, $87, $78, $9A, $AA, $DF, $FF, $F9, $59, $B7, $00, $04, $00, $06, $98; 15:6220
    db $79, $DE, $ED, $B8, $AA, $94, $24, $75, $22, $69, $86, $69, $B9, $98, $9A, $BA; 15:6230
    db $AB, $DF, $FF, $F6, $6A, $B4, $00, $33, $00, $08, $77, $69, $BD, $DC, $89, $BB; 15:6240
    db $83, $48, $84, $23, $88, $65, $79, $98, $78, $AB, $AA, $BD, $FE, $FF, $FB, $38; 15:6250
    db $B9, $00, $04, $00, $04, $75, $77, $AB, $DC, $A8, $CC, $95, $59, $84, $24, $67; 15:6260
    db $45, $68, $88, $88, $9B, $A9, $BD, $EC, $DF, $FF, $73, $CC, $50, $05, $30, $00; 15:6270
    db $46, $25, $5B, $DC, $9A, $DF, $C6, $8A, $C5, $23, $76, $43, $58, $88, $79, $BB; 15:6280
    db $9A, $BD, $CA, $CD, $ED, $EF, $93, $BB, $40, $05, $20, $00, $02, $22, $57, $99; 15:6290
    db $8A, $ED, $AB, $CD, $A8, $88, $76, $65, $77, $65, $68, $87, $8A, $99, $AA, $AA; 15:62A0
    db $AA, $99, $99, $88, $88, $77, $77, $66, $54, $44, $33, $34, $55, $66, $78, $99; 15:62B0
    db $89, $99, $88, $88, $77, $88, $88, $89, $99, $99, $99, $88, $88, $77, $88, $88; 15:62C0
    db $89, $98, $98, $98, $77, $66, $65, $56, $66, $67, $77, $77, $77, $66, $56, $66; 15:62D0
    db $67, $88, $89, $9A, $A9, $99, $99, $88, $78, $87, $77, $88, $88, $88, $99, $88; 15:62E0
    db $88, $77, $77, $78, $88, $88, $98, $87, $77, $76, $66, $66, $66, $77, $77, $88; 15:62F0
    db $88, $88, $88, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:6300
    db $88, $88, $88, $88, $87, $77, $77, $77, $77, $88, $78, $88, $88, $78, $87, $77; 15:6310
    db $77, $77, $77, $77, $77, $88, $77, $77, $77, $77, $77, $78, $88, $88, $88, $88; 15:6320
    db $88, $77, $77, $77, $78, $88, $88, $88, $88, $88, $77, $77, $77, $88, $88, $88; 15:6330
    db $88, $88, $88, $77, $77, $88, $88, $88, $88, $88, $88, $87, $88, $88, $87, $88; 15:6340
    db $88, $88, $88, $77, $77, $77, $77, $77, $77, $88, $88, $88, $87, $77, $77, $77; 15:6350
    db $78, $88, $88, $88, $88, $88, $87, $77, $77, $77, $88, $88, $88, $88, $88, $88; 15:6360
    db $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $76, $78; 15:6370
    db $88, $97, $97, $88, $87, $87, $87, $77, $78, $77, $68, $77, $66, $58, $78, $89; 15:6380
    db $98, $87, $98, $98, $88, $86, $78, $87, $88, $99, $89, $89, $88, $98, $88, $78; 15:6390
    db $77, $77, $87, $77, $78, $68, $67, $67, $66, $76, $77, $77, $87, $86, $97, $87; 15:63A0
    db $77, $77, $86, $86, $87, $79, $79, $88, $98, $88, $98, $88, $79, $79, $79, $88; 15:63B0
    db $89, $89, $79, $69, $68, $78, $87, $87, $88, $78, $78, $78, $76, $86, $77, $68; 15:63C0
    db $59, $68, $88, $77, $88, $78, $77, $86, $87, $87, $87, $87, $88, $87, $88, $78; 15:63D0
    db $79, $69, $78, $87, $87, $87, $88, $78, $78, $77, $86, $87, $78, $78, $68, $87; 15:63E0
    db $97, $88, $87, $87, $86, $78, $68, $78, $87, $96, $88, $78, $79, $77, $97, $87; 15:63F0
    db $87, $88, $78, $87, $88, $78, $88, $68, $88, $87, $88, $78, $78, $87, $87, $87; 15:6400
    db $87, $78, $86, $78, $76, $97, $77, $96, $78, $86, $96, $86, $97, $87, $87, $96; 15:6410
    db $77, $86, $87, $87, $87, $79, $78, $78, $87, $89, $78, $78, $78, $88, $89, $88; 15:6420
    db $78, $77, $87, $78, $87, $78, $77, $86, $88, $76, $88, $78, $87, $89, $86, $88; 15:6430
    db $67, $88, $78, $87, $89, $88, $89, $77, $87, $78, $77, $88, $87, $98, $77, $88; 15:6440
    db $78, $87, $88, $76, $89, $77, $88, $78, $87, $88, $67, $88, $77, $87, $78, $77; 15:6450
    db $87, $67, $88, $77, $78, $88, $77, $88, $77, $88, $88, $78, $88, $77, $89, $88; 15:6460
    db $89, $99, $99, $99, $99, $99, $99, $89, $99, $99, $75, $56, $42, $12, $20, $01; 15:6470
    db $23, $35, $57, $99, $AB, $CC, $BB, $CB, $BA, $AB, $BA, $AB, $BC, $CC, $CE, $EF; 15:6480
    db $FF, $E1, $8E, $50, $02, $20, $00, $00, $01, $05, $D8, $8B, $FF, $BC, $FE, $D8; 15:6490
    db $87, $67, $31, $46, $64, $5A, $AA, $AC, $ED, $DE, $DF, $FE, $FF, $F3, $3E, $71; 15:64A0
    db $00, $60, $00, $02, $03, $22, $CB, $A9, $DF, $FA, $CE, $E8, $68, $55, $42, $33; 15:64B0
    db $66, $37, $AB, $9A, $EF, $DE, $EF, $FF, $FF, $A4, $DB, $40, $06, $00, $00, $00; 15:64C0
    db $03, $07, $AB, $AA, $FF, $DC, $EF, $D8, $78, $65, $32, $22, $54, $36, $8A, $89; 15:64D0
    db $DE, $EE, $EF, $FF, $FE, $5B, $F8, $00, $43, $00, $00, $00, $20, $38, $BB, $8D; 15:64E0
    db $FF, $ED, $FF, $B8, $87, $54, $22, $02, $52, $34, $9A, $8B, $DE, $FF, $FF, $FF; 15:64F0
    db $F6, $AD, $B3, $02, $20, $00, $00, $03, $02, $6B, $E9, $BF, $FF, $EE, $FB, $99; 15:6500
    db $64, $33, $40, $03, $45, $47, $9A, $CE, $DE, $FF, $FF, $FB, $AD, $A7, $00, $30; 15:6510
    db $00, $00, $00, $11, $58, $BB, $AE, $FF, $FE, $FE, $AA, $86, $42, $32, $12, $24; 15:6520
    db $56, $88, $BE, $EF, $FF, $FF, $FA, $CD, $A5, $01, $00, $00, $00, $02, $11, $49; 15:6530
    db $BB, $BD, $EF, $FE, $DB, $BB, $85, $44, $42, $33, $24, $68, $88, $BD, $EF, $FF; 15:6540
    db $FF, $BC, $CA, $62, $30, $00, $00, $00, $32, $24, $8A, $BC, $ED, $EF, $FE, $9A; 15:6550
    db $B8, $64, $44, $34, $43, $46, $88, $9C, $DE, $FF, $FE, $AD, $DB, $62, $41, $00; 15:6560
    db $00, $00, $31, $24, $7A, $AB, $DC, $DE, $ED, $9A, $A7, $65, $44, $36, $64, $57; 15:6570
    db $9A, $AC, $DD, $FF, $FB, $9D, $C9, $43, $30, $01, $00, $02, $32, $36, $89, $BD; 15:6580
    db $DB, $CE, $DB, $99, $86, $65, $43, $46, $66, $78, $9A, $CD, $DE, $FF, $D9, $AA; 15:6590
    db $96, $43, $00, $11, $00, $03, $34, $68, $8A, $CE, $CC, $CD, $B9, $A8, $65, $55; 15:65A0
    db $44, $66, $68, $9A, $AC, $EE, $FF, $FC, $AA, $A8, $54, $30, $00, $00, $01, $23; 15:65B0
    db $47, $88, $9B, $CC, $CC, $CA, $99, $86, $55, $54, $46, $66, $89, $AB, $CD, $EF; 15:65C0
    db $FF, $CA, $A9, $85, $52, $00, $00, $00, $22, $35, $78, $9A, $CB, $BC, $CB, $A9; 15:65D0
    db $87, $66, $65, $45, $56, $78, $9A, $BC, $DE, $FF, $EB, $A9, $87, $65, $10, $00; 15:65E0
    db $00, $22, $23, $57, $8A, $CC, $BB, $CC, $BA, $A8, $76, $65, $55, $55, $67, $89; 15:65F0
    db $AC, $CD, $EF, $FD, $BA, $86, $66, $42, $00, $00, $13, $34, $55, $68, $AB, $CC; 15:6600
    db $CB, $AA, $A9, $88, $75, $55, $66, $78, $88, $9B, $CC, $EF, $FD, $CA, $87, $66; 15:6610
    db $53, $20, $00, $02, $34, $55, $67, $8A, $BC, $CC, $BA, $98, $88, $87, $66, $55; 15:6620
    db $57, $88, $AA, $BB, $CD, $EE, $EC, $A8, $65, $54, $33, $10, $00, $12, $46, $77; 15:6630
    db $88, $9A, $BC, $CC, $BA, $98, $77, $77, $77, $66, $66, $79, $AB, $CD, $DD, $EC; 15:6640
    db $CA, $97, $55, $32, $21, $10, $11, $23, $45, $78, $89, $9B, $BB, $BB, $BA, $98; 15:6650
    db $87, $77, $77, $77, $78, $89, $AB, $CD, $DE, $DC, $BA, $86, $54, $33, $22, $11; 15:6660
    db $12, $23, $56, $78, $99, $AB, $BB, $BB, $AA, $99, $87, $76, $66, $67, $78, $89; 15:6670
    db $9A, $BB, $CD, $DC, $CA, $97, $54, $33, $32, $22, $22, $23, $44, $67, $89, $AB; 15:6680
    db $BB, $BB, $AA, $A9, $98, $87, $77, $66, $67, $88, $9A, $AB, $BC, $CC, $CB, $B9; 15:6690
    db $86, $53, $22, $22, $22, $22, $33, $45, $67, $8A, $BB, $BC, $BB, $AA, $99, $88; 15:66A0
    db $87, $76, $66, $66, $78, $8A, $BB, $BB, $CC, $CC, $BA, $87, $53, $22, $22, $22; 15:66B0
    db $23, $33, $35, $57, $89, $AB, $CD, $CC, $BA, $99, $88, $77, $76, $66, $66, $67; 15:66C0
    db $89, $AA, $BB, $CC, $DD, $DB, $A8, $65, $32, $21, $22, $22, $23, $34, $55, $78; 15:66D0
    db $AB, $CD, $DD, $CB, $A9, $88, $77, $66, $66, $55, $66, $78, $99, $AB, $BC, $DD; 15:66E0
    db $DD, $DB, $98, $64, $22, $11, $12, $22, $33, $34, $56, $89, $BC, $DD, $DD, $CB; 15:66F0
    db $98, $87, $66, $65, $55, $55, $66, $79, $9A, $AB, $BC, $DE, $EE, $DB, $97, $53; 15:6700
    db $21, $00, $11, $22, $33, $34, $67, $8A, $BD, $EE, $DC, $BA, $98, $76, $65, $55; 15:6710
    db $55, $55, $67, $89, $AB, $BB, $BC, $DE, $EE, $EC, $A8, $53, $10, $00, $01, $12; 15:6720
    db $22, $34, $57, $8A, $CE, $EE, $ED, $BA, $87, $76, $55, $54, $44, $45, $57, $8A; 15:6730
    db $BB, $BB, $BC, $CE, $EF, $FE, $C9, $63, $10, $00, $00, $11, $11, $23, $46, $9B; 15:6740
    db $DF, $FE, $DC, $A9, $88, $77, $65, $43, $32, $35, $68, $AB, $CB, $BB, $BB, $CE; 15:6750
    db $FF, $FF, $CA, $63, $10, $00, $01, $00, $00, $02, $58, $BE, $FE, $ED, $CB, $BB; 15:6760
    db $A9, $86, $32, $10, $14, $67, $99, $99, $9A, $BD, $EE, $EE, $DD, $DE, $FC, $C8; 15:6770
    db $30, $00, $00, $10, $00, $11, $37, $BD, $FF, $FE, $CB, $A8, $A9, $76, $31, $00; 15:6780
    db $34, $79, $99, $88, $99, $CD, $DD, $CB, $AB, $EF, $FF, $D9, $50, $00, $11, $00; 15:6790
    db $00, $00, $59, $DF, $EB, $BB, $DE, $FF, $96, $20, $12, $66, $54, $34, $69, $DD; 15:67A0
    db $CB, $77, $8B, $DD, $DC, $AB, $EF, $FF, $B7, $00, $00, $40, $00, $00, $0B, $DD; 15:67B0
    db $CB, $9D, $FF, $FA, $81, $12, $58, $31, $00, $39, $DE, $A9, $87, $BC, $D9, $66; 15:67C0
    db $7A, $EF, $FE, $EF, $FD, $95, $00, $01, $00, $00, $00, $7D, $AA, $DF, $FF, $EF; 15:67D0
    db $65, $75, $50, $00, $03, $98, $87, $AC, $BE, $B9, $57, $A9, $89, $98, $CE, $FF; 15:67E0
    db $FF, $F7, $35, $21, $00, $00, $00, $50, $6C, $FF, $FF, $FC, $BF, $84, $01, $00; 15:67F0
    db $24, $23, $9B, $C9, $ED, $CC, $B9, $46, $88, $58, $9C, $CF, $FF, $FF, $F5, $06; 15:6800
    db $42, $00, $00, $00, $30, $6F, $FE, $FF, $FF, $AC, $30, $02, $10, $05, $67, $9A; 15:6810
    db $DC, $FE, $A9, $99, $65, $66, $69, $9C, $CF, $FF, $FF, $F9, $07, $61, $00, $00; 15:6820
    db $00, $03, $8F, $FC, $EF, $FE, $79, $63, $30, $00, $45, $44, $BB, $DA, $BB, $AB; 15:6830
    db $86, $77, $76, $6A, $AC, $BD, $EF, $FF, $FF, $D0, $58, $10, $04, $00, $10, $78; 15:6840
    db $FB, $9F, $FA, $97, $A7, $34, $26, $66, $56, $9A, $79, $89, $87, $76, $98, $78; 15:6850
    db $9A, $A9, $CB, $CC, $CC, $CD, $EF, $F4, $0C, $40, $00, $80, $40, $28, $BC, $2A; 15:6860
    db $FA, $56, $79, $58, $57, $C9, $77, $BB, $56, $87, $64, $66, $88, $69, $CB, $99; 15:6870
    db $BC, $BB, $9A, $BB, $AB, $EF, $FE, $07, $C0, $00, $80, $01, $08, $8B, $16, $FA; 15:6880
    db $56, $99, $79, $77, $EA, $65, $CA, $45, $56, $54, $56, $AA, $7A, $DD, $98, $AB; 15:6890
    db $A7, $7A, $BA, $9B, $EF, $FF, $FF, $05, $A0, $00, $50, $02, $08, $8E, $27, $E9; 15:68A0
    db $75, $88, $8A, $68, $D8, $76, $B7, $56, $47, $78, $68, $B9, $9A, $BA, $88, $88; 15:68B0
    db $98, $89, $AB, $9B, $CC, $CB, $DE, $FF, $80, $A7, $00, $07, $05, $00, $99, $90; 15:68C0
    db $AC, $66, $69, $89, $A5, $BD, $87, $7C, $56, $56, $87, $76, $AB, $88, $9B, $97; 15:68D0
    db $88, $A8, $78, $9B, $87, $8A, $A8, $9B, $CC, $BE, $FF, $B0, $97, $00, $05, $05; 15:68E0
    db $00, $89, $B0, $9C, $87, $58, $8C, $B5, $BE, $A7, $6B, $77, $55, $78, $95, $8B; 15:68F0
    db $B9, $8A, $A8, $76, $88, $86, $68, $87, $68, $98, $89, $BB, $BB, $CE, $EE, $FF; 15:6900
    db $B0, $55, $00, $03, $04, $10, $68, $B0, $8B, $78, $69, $8C, $E8, $AC, $B8, $59; 15:6910
    db $56, $54, $67, $A7, $8B, $BB, $89, $98, $96, $78, $88, $68, $88, $77, $88, $99; 15:6920
    db $9A, $AB, $AB, $DC, $CC, $DD, $EE, $E0, $06, $00, $00, $10, $70, $58, $B8, $1B; 15:6930
    db $99, $77, $98, $EB, $8A, $A9, $55, $64, $76, $66, $AC, $9B, $BB, $B9, $86, $78; 15:6940
    db $66, $69, $88, $88, $88, $88, $89, $99, $9A, $BA, $BA, $AA, $AA, $9A, $99, $AB; 15:6950
    db $EB, $00, $60, $00, $10, $37, $04, $7C, $54, $97, $97, $87, $9E, $A9, $9A, $A7; 15:6960
    db $85, $69, $88, $7A, $AA, $A9, $99, $98, $57, $88, $77, $88, $88, $77, $88, $77; 15:6970
    db $88, $89, $99, $AB, $99, $A9, $99, $A9, $AA, $AA, $AB, $C5, $03, $20, $00, $10; 15:6980
    db $64, $25, $8A, $58, $88, $A9, $97, $CD, $AA, $9A, $88, $84, $67, $77, $79, $8A; 15:6990
    db $AA, $AA, $A9, $88, $89, $88, $77, $77, $65, $66, $67, $78, $9A, $AA, $BB, $BA; 15:69A0
    db $AA, $AA, $99, $99, $88, $88, $AC, $50, $34, $10, $01, $05, $42, $38, $A5, $99; 15:69B0
    db $8A, $BA, $6B, $CA, $A9, $98, $A9, $56, $78, $67, $87, $99, $98, $9B, $99, $88; 15:69C0
    db $88, $86, $77, $77, $67, $67, $77, $77, $99, $99, $AA, $AB, $AA, $AA, $98, $88; 15:69D0
    db $87, $77, $88, $96, $24, $52, $22, $20, $24, $23, $66, $68, $98, $8A, $A9, $AB; 15:69E0
    db $A9, $BA, $9A, $A9, $99, $88, $88, $77, $77, $77, $78, $88, $88, $87, $88, $88; 15:69F0
    db $88, $88, $88, $88, $88, $88, $88, $88, $89, $99, $99, $99, $99, $98, $88, $88; 15:6A00
    db $88, $65, $63, $33, $31, $02, $10, $34, $45, $88, $79, $BA, $BC, $BA, $BC, $BB; 15:6A10
    db $BB, $AA, $98, $88, $87, $66, $66, $66, $77, $77, $87, $88, $88, $88, $88, $88; 15:6A20
    db $88, $88, $88, $88, $88, $88, $88, $88, $89, $99, $99, $99, $98, $99, $86, $56; 15:6A30
    db $43, $43, $11, $22, $13, $44, $57, $77, $9A, $9B, $CB, $BC, $CB, $BC, $BA, $AA; 15:6A40
    db $88, $87, $76, $66, $56, $66, $77, $77, $78, $88, $88, $88, $88, $89, $98, $89; 15:6A50
    db $88, $88, $88, $88, $88, $99, $99, $99, $88, $88, $88, $88, $88, $65, $54, $44; 15:6A60
    db $32, $12, $22, $23, $45, $67, $78, $9A, $BB, $BB, $BC, $BB, $BB, $AA, $99, $88; 15:6A70
    db $87, $76, $66, $66, $66, $77, $77, $88, $88, $88, $99, $99, $99, $99, $99, $88; 15:6A80
    db $98, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $87, $55, $54, $45; 15:6A90
    db $32, $33, $23, $44, $57, $87, $89, $AA, $BB, $BB, $BB, $BB, $BA, $A9, $98, $88; 15:6AA0
    db $77, $66, $66, $66, $77, $77, $88, $88, $99, $99, $99, $99, $99, $88, $88, $88; 15:6AB0
    db $88, $88, $88, $88, $88, $88, $87, $77, $77, $76, $66, $77, $77, $76, $66, $55; 15:6AC0
    db $54, $33, $33, $45, $56, $78, $88, $AA, $AB, $BB, $BB, $BA, $AA, $AA, $99, $88; 15:6AD0
    db $88, $77, $77, $77, $77, $77, $77, $88, $88, $88, $99, $88, $88, $88, $88, $88; 15:6AE0
    db $88, $88, $88, $88, $77, $77, $77, $77, $77, $66, $66, $66, $66, $77, $78, $77; 15:6AF0
    db $76, $66, $65, $55, $55, $55, $66, $78, $88, $99, $AA, $AA, $AA, $AA, $AA, $AA; 15:6B00
    db $99, $98, $88, $87, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88; 15:6B10
    db $88, $88, $88, $88, $77, $77, $77, $77, $77, $77, $77, $67, $76, $66, $77, $77; 15:6B20
    db $78, $88, $77, $77, $66, $65, $55, $55, $56, $67, $88, $89, $99, $AA, $AA, $AA; 15:6B30
    db $AA, $99, $99, $99, $99, $88, $88, $88, $77, $77, $77, $78, $88, $88, $88, $88; 15:6B40
    db $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $77, $67, $77; 15:6B50
    db $77, $77, $77, $77, $77, $77, $77, $77, $76, $66, $66, $67, $77, $88, $88, $99; 15:6B60
    db $99, $9A, $AA, $A9, $99, $99, $98, $88, $88, $88, $87, $77, $77, $77, $78, $88; 15:6B70
    db $88, $88, $88, $88, $88, $87, $78, $77, $77, $77, $77, $77, $77, $77, $77, $77; 15:6B80
    db $77, $77, $66, $77, $77, $77, $77, $88, $88, $88, $88, $88, $87, $77, $77, $77; 15:6B90
    db $77, $77, $78, $88, $88, $88, $99, $99, $99, $99, $99, $88, $88, $88, $87, $77; 15:6BA0
    db $77, $78, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77; 15:6BB0
    db $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $78, $87, $88, $88; 15:6BC0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:6BD0
    db $88, $88, $88, $88, $87, $87, $77, $77, $77, $87, $88, $88, $88, $88, $88, $88; 15:6BE0
    db $88, $88, $88, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $78; 15:6BF0
    db $78, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:6C00
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $77, $77; 15:6C10
    db $77, $88, $88, $88, $88, $88, $88, $87, $87, $77, $78, $77, $78, $78, $88, $88; 15:6C20
    db $88, $88, $88, $88, $87, $77, $77, $77, $87, $87, $78, $88, $88, $88, $88, $88; 15:6C30
    db $88, $88, $88, $78, $78, $78, $78, $78, $88, $88, $78, $78, $78, $78, $77, $87; 15:6C40
    db $77, $77, $77, $87, $78, $78, $88, $88, $98, $88, $88, $88, $88, $88, $88, $88; 15:6C50
    db $88, $88, $88, $88, $88, $88, $87, $87, $77, $77, $77, $77, $77, $77, $77, $77; 15:6C60
    db $77, $77, $77, $77, $77, $78, $78, $87, $87, $87, $87, $88, $88, $88, $87, $88; 15:6C70
    db $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $88, $78; 15:6C80
    db $88, $88, $88, $78, $78, $88, $88, $78, $78, $78, $78, $88, $78, $78, $78, $78; 15:6C90
    db $78, $78, $87, $87, $87, $87, $87, $87, $88, $87, $87, $88, $78, $77, $77, $77; 15:6CA0
    db $78, $78, $78, $78, $77, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $88; 15:6CB0
    db $88, $88, $78, $78, $88, $88, $88, $78, $78, $77, $77, $87, $87, $77, $87, $78; 15:6CC0
    db $78, $78, $78, $78, $78, $78, $78, $88, $88, $78, $78, $88, $88, $88, $88, $88; 15:6CD0
    db $88, $88, $88, $88, $88, $87, $88, $87, $88, $78, $78, $78, $78, $78, $78, $88; 15:6CE0
    db $78, $87, $88, $88, $88, $77, $87, $77, $77, $88, $78, $78, $78, $78, $88, $78; 15:6CF0
    db $88, $78, $88, $78, $78, $77, $88, $88, $77, $78, $78, $88, $87, $88, $88, $88; 15:6D00
    db $87, $88, $87, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:6D10

;; PCM26: 2848 bytes = 5696 4-bit samples (rate 2) for SFXInst40
PCM26:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:6D20
    db $87, $88, $77, $88, $77, $87, $77, $78, $88, $88, $78, $88, $78, $87, $78, $87; 15:6D30
    db $88, $78, $88, $78, $88, $88, $88, $87, $88, $88, $88, $88, $88, $87, $88, $77; 15:6D40
    db $88, $78, $78, $87, $78, $77, $88, $78, $88, $88, $88, $87, $88, $77, $87, $78; 15:6D50
    db $87, $88, $78, $87, $88, $88, $88, $88, $88, $88, $88, $88, $78, $87, $88, $78; 15:6D60
    db $77, $87, $78, $77, $87, $77, $87, $77, $77, $78, $77, $87, $88, $88, $88, $88; 15:6D70
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $99, $98, $88, $78; 15:6D80
    db $76, $65, $55, $55, $45, $55, $67, $78, $89, $99, $99, $99, $98, $88, $88, $78; 15:6D90
    db $88, $88, $89, $99, $9A, $AA, $AA, $AA, $A9, $AB, $BA, $37, $C0, $25, $13, $00; 15:6DA0
    db $23, $30, $89, $68, $AE, $BB, $CB, $D9, $7A, $87, $46, $75, $45, $77, $57, $99; 15:6DB0
    db $88, $BA, $99, $AB, $98, $AB, $A9, $BC, $BB, $BE, $FF, $06, $F0, $04, $05, $01; 15:6DC0
    db $04, $90, $FE, $8A, $9F, $AA, $A6, $F4, $06, $67, $04, $95, $64, $CC, $89, $9E; 15:6DD0
    db $85, $A8, $84, $6A, $88, $8D, $EA, $CE, $FD, $EF, $30, $F0, $04, $04, $00, $31; 15:6DE0
    db $F0, $BF, $DD, $7F, $B6, $91, $83, $01, $28, $05, $BA, $C8, $DF, $B8, $7A, $61; 15:6DF0
    db $45, $64, $6A, $CC, $AF, $FD, $DE, $FF, $C0, $7F, $00, $04, $10, $90, $F8, $2F; 15:6E00
    db $FF, $2D, $F3, $40, $37, $00, $1D, $72, $DF, $F9, $BE, $A6, $24, $61, $04, $A8; 15:6E10
    db $7D, $FF, $EE, $FF, $EE, $F0, $0F, $00, $01, $20, $B0, $FD, $6F, $FF, $5A, $F2; 15:6E20
    db $30, $14, $03, $1B, $A6, $EF, $FA, $BB, $75, $02, $40, $15, $BA, $BF, $FF, $FF; 15:6E30
    db $FF, $F1, $0F, $00, $00, $60, $63, $FF, $5F, $FF, $56, $F6, $00, $16, $02, $1C; 15:6E40
    db $C7, $CF, $F9, $7C, $91, $03, $41, $27, $DB, $BF, $FF, $FF, $F2, $4E, $00, $02; 15:6E50
    db $00, $50, $FA, $DE, $FF, $7C, $D3, $30, $20, $12, $2C, $8A, $CF, $D9, $B9, $74; 15:6E60
    db $35, $55, $5A, $DC, $EF, $FF, $2C, $F0, $00, $70, $00, $4C, $58, $CF, $D7, $DE; 15:6E70
    db $72, $16, $21, $06, $A7, $7B, $FA, $8A, $B7, $46, $78, $77, $EF, $FF, $B5, $F5; 15:6E80
    db $00, $62, $05, $08, $49, $AF, $F8, $BF, $84, $36, $20, $33, $85, $88, $DB, $8B; 15:6E90
    db $BA, $79, $98, $88, $CE, $ED, $0E, $E0, $22, $B0, $33, $77, $49, $BF, $87, $EB; 15:6EA0
    db $44, $77, $04, $38, $55, $6A, $B5, $9C, $A7, $AE, $BB, $EF, $F9, $0F, $90, $06; 15:6EB0
    db $70, $33, $B5, $8A, $FE, $78, $F8, $12, $84, $03, $69, $46, $9D, $76, $BC, $87; 15:6EC0
    db $BD, $BC, $FF, $37, $F2, $10, $A0, $23, $79, $79, $AF, $96, $AA, $33, $46, $15; 15:6ED0
    db $48, $67, $9B, $A7, $AA, $87, $AC, $BE, $F7, $5F, $51, $2A, $00, $64, $85, $8A; 15:6EE0
    db $FB, $8C, $E5, $56, $70, $24, $55, $38, $9A, $8D, $EB, $BE, $ED, $FA, $0E, $70; 15:6EF0
    db $07, $40, $65, $A5, $AB, $FC, $8B, $D6, $36, $60, $14, $44, $29, $99, $8D, $EB; 15:6F00
    db $DF, $FE, $F3, $6F, $00, $2B, $00, $78, $56, $DC, $E8, $BE, $B3, $69, $50, $54; 15:6F10
    db $41, $59, $87, $AF, $BB, $FF, $FF, $76, $F2, $01, $90, $05, $74, $4C, $CD, $9C; 15:6F20
    db $EC, $47, $85, $03, $42, $04, $86, $7B, $FB, $CF, $FF, $F6, $9F, $00, $27, $00; 15:6F30
    db $47, $36, $DE, $D9, $FE, $A4, $98, $20, $42, $10, $58, $67, $DF, $BD, $FF, $FE; 15:6F40
    db $5E, $A0, $06, $20, $24, $51, $9B, $DB, $BF, $E8, $7B, $71, $25, $10, $16, $55; 15:6F50
    db $9D, $CC, $FF, $FF, $9A, $F3, $03, $60, $03, $41, $4B, $BC, $AF, $FB, $7B, $A4; 15:6F60
    db $25, $30, $04, $53, $7B, $CA, $EF, $FF, $D8, $F9, $12, $70, $02, $32, $18, $9B; 15:6F70
    db $AD, $FD, $9A, $B7, $45, $41, $02, $53, $59, $BA, $DF, $FF, $F9, $EE, $52, $53; 15:6F80
    db $00, $11, $04, $79, $9B, $EE, $BC, $D9, $66, $51, $10, $32, $46, $9A, $CF, $FF; 15:6F90
    db $FB, $EF, $74, $64, $00, $01, $02, $58, $7A, $DD, $BC, $EB, $88, $73, $21, $22; 15:6FA0
    db $35, $89, $BE, $FF, $FC, $FE, $86, $93, $01, $20, $02, $55, $5A, $CB, $AD, $DA; 15:6FB0
    db $99, $74, $42, $22, $45, $78, $BE, $FF, $CF, $FA, $89, $72, $22, $20, $14, $54; 15:6FC0
    db $6A, $A9, $BD, $BA, $A9, $65, $54, $33, $57, $79, $CE, $EB, $FF, $A8, $A9, $34; 15:6FD0
    db $43, $12, $34, $35, $88, $8A, $CA, $AA, $97, $75, $54, $45, $67, $8B, $DC, $AF; 15:6FE0
    db $D9, $9B, $74, $54, $31, $34, $43, $68, $88, $BB, $9A, $A9, $66, $65, $45, $67; 15:6FF0
    db $8A, $CD, $BB, $FB, $89, $A4, $45, $52, $25, $54, $58, $87, $8B, $A8, $9A, $85; 15:7000
    db $76, $55, $77, $89, $BD, $D9, $DE, $87, $A8, $25, $53, $14, $55, $57, $98, $89; 15:7010
    db $B9, $88, $85, $56, $55, $68, $89, $BD, $EA, $CE, $86, $99, $24, $54, $14, $66; 15:7020
    db $57, $A9, $89, $B8, $78, $85, $47, $64, $69, $89, $BE, $FB, $BF, $A5, $8A, $22; 15:7030
    db $55, $02, $66, $46, $99, $88, $BA, $78, $96, $46, $64, $58, $88, $AD, $FD, $9E; 15:7040
    db $D7, $5B, $60, $46, $20, $66, $45, $99, $88, $AB, $87, $99, $55, $86, $46, $98; 15:7050
    db $9C, $FE, $9C, $F9, $48, $A2, $15, $50, $26, $64, $79, $98, $8A, $A7, $69, $84; 15:7060
    db $58, $75, $8A, $AA, $EF, $A9, $EB, $55, $A4, $14, $62, $25, $66, $68, $89, $87; 15:7070
    db $9A, $66, $97, $56, $87, $79, $AB, $DF, $C9, $DC, $64, $96, $13, $64, $15, $66; 15:7080
    db $78, $78, $98, $69, $95, $68, $75, $78, $89, $AB, $DF, $E8, $BE, $82, $58, $32; 15:7090
    db $34, $36, $64, $7A, $85, $8B, $87, $76, $68, $75, $69, $98, $AC, $DF, $FA, $8B; 15:70A0
    db $B6, $35, $32, $54, $22, $67, $58, $87, $7A, $97, $88, $66, $87, $68, $88, $9B; 15:70B0
    db $BB, $EE, $BA, $B9, $78, $85, $45, $43, $45, $44, $67, $67, $88, $78, $86, $78; 15:70C0
    db $77, $88, $88, $AA, $BC, $DC, $BC, $CA, $A9, $75, $65, $22, $33, $24, $54, $57; 15:70D0
    db $76, $78, $77, $88, $78, $98, $9B, $BB, $CE, $DC, $DD, $B9, $A8, $55, $52, $12; 15:70E0
    db $32, $35, $44, $67, $67, $98, $78, $97, $8A, $98, $AB, $AB, $DD, $DC, $DC, $A9; 15:70F0
    db $97, $55, $52, $12, $22, $35, $44, $56, $67, $88, $79, $87, $9A, $89, $BA, $9B; 15:7100
    db $DD, $DD, $DC, $BA, $98, $65, $53, $12, $21, $24, $43, $56, $56, $88, $79, $A8; 15:7110
    db $89, $99, $AA, $9A, $BC, $DE, $DC, $DB, $99, $96, $55, $30, $22, $12, $44, $35; 15:7120
    db $65, $69, $88, $99, $88, $98, $8A, $A9, $AB, $BC, $EE, $BD, $D9, $89, $85, $55; 15:7130
    db $11, $21, $13, $43, $46, $66, $88, $89, $A9, $88, $99, $9A, $99, $AA, $BC, $ED; 15:7140
    db $CD, $C9, $9A, $85, $55, $10, $21, $03, $43, $45, $55, $88, $88, $A9, $88, $98; 15:7150
    db $89, $99, $9A, $BC, $EE, $CC, $EA, $8A, $96, $56, $20, $21, $02, $43, $45, $65; 15:7160
    db $79, $89, $A9, $98, $98, $89, $99, $9A, $BC, $EF, $EB, $CC, $87, $87, $56, $62; 15:7170
    db $11, $00, $13, $46, $77, $78, $88, $89, $A9, $88, $87, $78, $89, $BB, $CE, $FF; 15:7180
    db $FC, $B6, $22, $33, $35, $53, $44, $34, $56, $78, $87, $67, $89, $9A, $A8, $76; 15:7190
    db $55, $68, $89, $AA, $BD, $FF, $FF, $DA, $10, $00, $14, $76, $55, $33, $57, $9A; 15:71A0
    db $97, $54, $58, $BC, $DA, $65, $33, $58, $9A, $A9, $9B, $DF, $FF, $FC, $40, $00; 15:71B0
    db $03, $78, $65, $43, $57, $BC, $A7, $42, $37, $BD, $EC, $85, $22, $47, $9B, $A8; 15:71C0
    db $88, $BF, $FF, $FE, $90, $00, $00, $58, $96, $55, $58, $AC, $B7, $41, $04, $9D; 15:71D0
    db $FE, $B6, $32, $25, $8A, $A8, $76, $8B, $FF, $FF, $D8, $00, $00, $16, $9A, $87; 15:71E0
    db $67, $9A, $CA, $63, $00, $49, $DF, $FB, $74, $22, $57, $9A, $87, $68, $BF, $FF; 15:71F0
    db $FF, $92, $00, $00, $48, $AA, $88, $79, $AB, $B7, $32, $02, $7A, $EF, $D9, $52; 15:7200
    db $13, $57, $98, $87, $7A, $DF, $FF, $FD, $80, $00, $00, $58, $AB, $99, $89, $AB; 15:7210
    db $A5, $30, $02, $6A, $FF, $DA, $52, $23, $57, $98, $88, $7A, $DF, $FF, $FE, $91; 15:7220
    db $00, $00, $58, $AB, $99, $89, $AA, $95, $20, $01, $59, $EF, $EB, $73, $22, $46; 15:7230
    db $88, $88, $8A, $CF, $FF, $FF, $B7, $00, $00, $05, $8B, $AA, $A8, $99, $97, $42; 15:7240
    db $00, $36, $BE, $FE, $B8, $53, $34, $57, $78, $89, $BD, $FF, $FF, $FB, $70, $00; 15:7250
    db $00, $57, $BA, $A9, $88, $88, $85, $42, $04, $59, $DE, $ED, $96, $33, $34, $67; 15:7260
    db $88, $8A, $BD, $FF, $FF, $E9, $30, $00, $02, $69, $A9, $87, $88, $AA, $96, $41; 15:7270
    db $14, $6B, $EF, $EB, $84, $22, $36, $78, $88, $8A, $BE, $FF, $FF, $D8, $20, $00; 15:7280
    db $02, $67, $98, $88, $9A, $CB, $A6, $40, $13, $5A, $DE, $EC, $85, $32, $35, $67; 15:7290
    db $88, $8A, $BD, $FF, $FF, $FC, $84, $00, $00, $14, $69, $89, $AB, $BC, $B9, $64; 15:72A0
    db $11, $34, $8B, $CD, $C9, $74, $33, $45, $67, $88, $AA, $BD, $EF, $FF, $FF, $A7; 15:72B0
    db $00, $00, $03, $58, $9A, $AA, $BB, $BB, $86, $30, $22, $59, $BC, $DB, $97, $54; 15:72C0
    db $45, $56, $77, $89, $AB, $CD, $FF, $FF, $FB, $83, $00, $00, $03, $59, $AB, $BC; 15:72D0
    db $BC, $BA, $75, $10, $12, $59, $BD, $EC, $B8, $65, $44, $45, $55, $78, $9C, $DE; 15:72E0
    db $EE, $EE, $EF, $C8, $50, $00, $00, $36, $BC, $DC, $BA, $AA, $A8, $64, $11, $12; 15:72F0
    db $69, $BE, $DD, $B8, $65, $44, $35, $45, $88, $BD, $DD, $CB, $BB, $BD, $FE, $A8; 15:7300
    db $10, $00, $03, $59, $BB, $AA, $99, $99, $97, $63, $11, $14, $8A, $DE, $DC, $B8; 15:7310
    db $76, $65, $54, $33, $55, $9B, $DE, $DB, $BA, $BD, $EF, $FC, $A2, $00, $00, $04; 15:7320
    db $8A, $AA, $98, $9A, $BC, $BA, $52, $00, $16, $8C, $EE, $DC, $97, $66, $66, $53; 15:7330
    db $22, $25, $8C, $FF, $FE, $B9, $89, $BE, $FF, $D8, $30, $00, $00, $67, $AA, $98; 15:7340
    db $9A, $CD, $FC, $96, $00, $00, $27, $AE, $ED, $CA, $98, $89, $86, $41, $00, $05; 15:7350
    db $9D, $FF, $FD, $A8, $88, $AC, $DE, $ED, $87, $30, $00, $01, $34, $78, $9B, $DD; 15:7360
    db $ED, $C8, $62, $00, $00, $58, $9C, $DC, $CB, $AA, $98, $64, $20, $01, $37, $AD; 15:7370
    db $FF, $EC, $98, $77, $8A, $BC, $CD, $EC, $A9, $20, $00, $01, $15, $8A, $AC, $BB; 15:7380
    db $AB, $98, $84, $32, $21, $54, $8A, $BC, $DB, $BA, $98, $76, $43, $32, $35, $7A; 15:7390
    db $CC, $DB, $A8, $88, $9A, $BC, $CD, $CD, $EA, $95, $00, $00, $00, $28, $9B, $BD; 15:73A0
    db $BC, $BB, $88, $63, $22, $02, $55, $9B, $CD, $DB, $BA, $98, $76, $43, $22, $36; 15:73B0
    db $8B, $DD, $DC, $B9, $98, $89, $99, $9A, $AB, $DF, $ED, $A3, $00, $00, $00, $47; 15:73C0
    db $99, $BA, $AB, $CC, $AB, $65, $21, $02, $25, $9B, $CC, $CA, $BA, $BA, $A8, $65; 15:73D0
    db $21, $24, $6B, $CD, $CB, $98, $88, $89, $98, $88, $89, $BC, $EF, $EC, $92, $00; 15:73E0
    db $00, $01, $47, $87, $89, $9B, $CE, $BC, $85, $32, $02, $56, $AB, $CB, $BA, $99; 15:73F0
    db $A9, $99, $65, $44, $46, $89, $BB, $A8, $87, $88, $88, $98, $89, $99, $AA, $AA; 15:7400
    db $BB, $BB, $97, $52, $11, $12, $34, $55, $55, $67, $88, $99, $99, $88, $88, $78; 15:7410
    db $89, $89, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $77, $77, $78, $88; 15:7420
    db $99, $99, $AA, $99, $98, $89, $99, $9A, $A9, $87, $42, $22, $23, $45, $56, $66; 15:7430
    db $67, $78, $98, $88, $77, $77, $88, $99, $99, $A9, $99, $99, $88, $77, $77, $77; 15:7440
    db $77, $77, $88, $89, $99, $99, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:7450
    db $99, $98, $86, $44, $43, $45, $65, $55, $55, $77, $78, $87, $77, $77, $88, $99; 15:7460
    db $AA, $9A, $99, $99, $98, $88, $87, $77, $77, $77, $78, $88, $88, $89, $98, $88; 15:7470
    db $87, $77, $88, $88, $88, $88, $88, $88, $88, $88, $89, $87, $76, $45, $55, $56; 15:7480
    db $65, $55, $56, $77, $77, $77, $88, $99, $9A, $98, $88, $88, $88, $88, $88, $88; 15:7490
    db $88, $88, $88, $87, $77, $77, $78, $87, $88, $88, $88, $88, $88, $88, $88, $88; 15:74A0
    db $88, $88, $88, $89, $AA, $87, $64, $34, $55, $56, $54, $56, $68, $88, $77, $77; 15:74B0
    db $78, $99, $99, $88, $99, $99, $89, $88, $88, $77, $77, $77, $88, $88, $88, $88; 15:74C0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $99, $99, $9A, $AB, $A7, $54; 15:74D0
    db $12, $34, $54, $44, $35, $99, $99, $87, $67, $88, $89, $87, $88, $99, $9A, $88; 15:74E0
    db $88, $89, $98, $76, $77, $78, $88, $77, $77, $88, $88, $88, $88, $89, $98, $98; 15:74F0
    db $88, $99, $98, $99, $AA, $AA, $AB, $B7, $32, $00, $13, $43, $23, $45, $AC, $BA; 15:7500
    db $87, $65, $79, $76, $66, $79, $BD, $BA, $A9, $89, $A9, $76, $65, $68, $98, $88; 15:7510
    db $88, $89, $87, $78, $88, $88, $87, $89, $99, $99, $98, $99, $99, $9A, $AA, $AA; 15:7520
    db $CC, $62, $10, $00, $23, $10, $37, $8C, $EC, $96, $77, $67, $75, $34, $6A, $BC; 15:7530
    db $EB, $AA, $BB, $A8, $75, $34, $67, $88, $88, $8A, $BA, $97, $65, $57, $88, $77; 15:7540
    db $89, $AB, $A9, $88, $99, $99, $98, $89, $AB, $A9, $9B, $B5, $10, $00, $02, $42; 15:7550
    db $15, $9B, $DE, $DA, $67, $87, $65, $43, $47, $CD, $CC, $BB, $BB, $BA, $64, $33; 15:7560
    db $56, $78, $78, $AB, $CB, $A8, $64, $45, $66, $67, $89, $BC, $BA, $98, $98, $88; 15:7570
    db $87, $78, $99, $99, $99, $99, $AB, $60, $00, $02, $24, $42, $5A, $EE, $DB, $97; 15:7580
    db $68, $86, $32, $47, $9B, $DC, $BA, $BC, $B9, $64, $33, $47, $87, $78, $AB, $CC; 15:7590
    db $B8, $65, $55, $44, $56, $89, $BC, $BA, $9A, $98, $87, $77, $89, $98, $88, $89; 15:75A0
    db $88, $87, $78, $A9, $30, $02, $44, $56, $54, $8C, $EC, $98, $86, $78, $76, $33; 15:75B0
    db $7A, $BB, $BA, $A9, $BB, $96, $44, $56, $68, $87, $89, $CC, $B8, $77, $66, $65; 15:75C0
    db $54, $68, $BB, $AA, $A9, $99, $87, $66, $78, $99, $88, $88, $99, $87, $66, $67; 15:75D0
    db $89, $B8, $21, $35, $65, $44, $35, $8C, $DA, $77, $98, $87, $64, $24, $8B, $B9; 15:75E0
    db $9A, $BA, $BA, $86, $45, $78, $77, $78, $9A, $BB, $87, $77, $86, $55, $56, $89; 15:75F0
    db $A9, $88, $99, $98, $77, $67, $89, $99, $88, $99, $98, $76, $66, $88, $87, $8A; 15:7600
    db $C9, $42, $23, $54, $45, $45, $8C, $DB, $88, $88, $87, $65, $45, $8B, $CA, $AA; 15:7610
    db $BB, $A9, $75, $45, $78, $77, $89, $AA, $AA, $87, $66, $65, $44, $56, $89, $AA; 15:7620
    db $99, $99, $98, $66, $78, $89, $99, $99, $9A, $97, $66, $77, $77, $76, $78, $AB; 15:7630
    db $B6, $21, $35, $64, $33, $58, $BD, $C9, $78, $AA, $85, $44, $57, $9A, $98, $8B; 15:7640
    db $CB, $A8, $66, $67, $87, $55, $79, $BA, $98, $88, $88, $75, $45, $78, $88, $88; 15:7650
    db $99, $99, $87, $78, $89, $88, $88, $99, $87, $76, $77, $77, $77, $88, $88, $88; 15:7660
    db $9A, $95, $11, $46, $54, $45, $79, $BC, $B8, $78, $98, $64, $45, $68, $AA, $99; 15:7670
    db $AC, $CB, $86, $66, $77, $76, $67, $9B, $BA, $88, $99, $87, $65, $55, $78, $87; 15:7680
    db $89, $AA, $98, $88, $88, $88, $77, $89, $98, $88, $88, $87, $77, $77, $77, $76; 15:7690
    db $67, $89, $AA, $84, $23, $56, $43, $35, $89, $BB, $A8, $8A, $A8, $54, $56, $88; 15:76A0
    db $89, $99, $BC, $CA, $77, $77, $76, $55, $68, $9A, $A9, $88, $99, $76, $55, $56; 15:76B0
    db $77, $88, $9A, $AA, $88, $88, $77, $77, $78, $88, $88, $88, $88, $77, $67, $77; 15:76C0
    db $77, $77, $78, $88, $88, $9A, $96, $32, $46, $54, $45, $79, $BB, $B9, $89, $99; 15:76D0
    db $74, $45, $67, $88, $99, $AB, $CB, $97, $77, $76, $55, $67, $89, $99, $89, $98; 15:76E0
    db $76, $56, $67, $78, $88, $89, $A9, $87, $77, $77, $77, $77, $88, $88, $88, $88; 15:76F0
    db $76, $66, $77, $77, $77, $88, $88, $77, $89, $9A, $85, $33, $57, $64, $46, $89; 15:7700
    db $AA, $99, $99, $A9, $75, $57, $88, $88, $89, $AA, $A9, $87, $78, $76, $56, $78; 15:7710
    db $88, $88, $88, $88, $76, $67, $88, $88, $88, $99, $98, $88, $88, $77, $77, $88; 15:7720
    db $88, $87, $88, $77, $76, $77, $77, $77, $77, $87, $77, $77, $88, $88, $88, $89; 15:7730
    db $85, $44, $78, $65, $57, $89, $88, $88, $88, $98, $77, $88, $88, $89, $99, $99; 15:7740
    db $98, $78, $88, $77, $78, $88, $88, $88, $88, $87, $77, $88, $88, $88, $88, $88; 15:7750
    db $87, $77, $77, $77, $77, $77, $88, $77, $77, $77, $77, $77, $77, $77, $77, $77; 15:7760
    db $77, $88, $77, $78, $88, $88, $87, $78, $88, $88, $88, $88, $88, $88, $88, $88; 15:7770
    db $88, $88, $88, $88, $88, $88, $87, $88, $88, $88, $88, $88, $88, $88, $87, $77; 15:7780
    db $88, $88, $88, $88, $88, $77, $77, $77, $77, $78, $87, $77, $77, $77, $77, $77; 15:7790
    db $88, $88, $88, $87, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77; 15:77A0
    db $88, $87, $88, $88, $88, $88, $78, $77, $87, $78, $88, $88, $88, $88, $88, $88; 15:77B0
    db $88, $88, $87, $87, $77, $77, $87, $88, $88, $88, $88, $88, $88, $88, $78, $87; 15:77C0
    db $77, $77, $88, $88, $88, $88, $88, $88, $87, $87, $77, $77, $77, $78, $88, $88; 15:77D0
    db $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:77E0
    db $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $78, $87, $77, $77, $77; 15:77F0
    db $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:7800
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $78, $87, $88, $88, $88; 15:7810
    db $87, $77, $77, $77, $77, $88, $88, $88, $87, $88, $87, $78, $88, $88, $88, $88; 15:7820
    db $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $87, $88, $88, $88, $88, $88; 15:7830

;; PCM27: 1424 bytes = 2848 4-bit samples (rate 2) for SFXInst41
PCM27:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:7840
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:7850
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:7860
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $77; 15:7870
    db $77, $66, $66, $66, $66, $77, $78, $88, $99, $99, $A9, $99, $99, $99, $98, $88; 15:7880
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $89, $A9, $3A, $C0, $A6, $1A; 15:7890
    db $11, $74, $42, $67, $48, $67, $C8, $8C, $AB, $AA, $BB, $A8, $9B, $77, $76, $75; 15:78A0
    db $46, $55, $56, $76, $78, $9A, $99, $BB, $BA, $BB, $A9, $99, $98, $78, $87, $77; 15:78B0
    db $87, $67, $89, $94, $3F, $50, $B2, $48, $03, $62, $31, $77, $27, $87, $C7, $8E; 15:78C0
    db $BB, $AB, $EA, $AA, $9B, $85, $88, $65, $57, $64, $55, $76, $48, $98, $88, $AB; 15:78D0
    db $99, $AB, $A8, $AB, $A9, $89, $98, $88, $88, $77, $88, $89, $A6, $2C, $80, $75; 15:78E0
    db $15, $01, $32, $40, $39, $44, $A9, $BB, $9D, $DC, $C9, $EE, $89, $A9, $95, $58; 15:78F0
    db $65, $44, $85, $46, $78, $77, $AA, $99, $9B, $B9, $AA, $BA, $89, $A9, $88, $9A; 15:7900
    db $88, $89, $98, $9C, $91, $6C, $20, $23, $30, $02, $03, $20, $59, $77, $8C, $F9; 15:7910
    db $BE, $DD, $A9, $CB, $88, $58, $85, $45, $77, $45, $98, $77, $8A, $98, $89, $B9; 15:7920
    db $89, $AA, $98, $AB, $A9, $9B, $CA, $9A, $BB, $AB, $D7, $08, $90, $00, $33, $00; 15:7930
    db $13, $41, $3A, $BA, $CA, $DF, $DC, $9A, $E9, $46, $78, $51, $58, $76, $68, $C9; 15:7940
    db $99, $AC, $A7, $78, $97, $45, $88, $87, $8C, $CC, $BB, $DD, $CC, $BC, $DD, $E8; 15:7950
    db $03, $A5, $00, $07, $00, $03, $B8, $39, $EE, $FD, $CB, $AC, $B4, $13, $78, $00; 15:7960
    db $59, $97, $5C, $EC, $CA, $AA, $99, $72, $46, $75, $36, $BB, $B9, $CF, $ED, $DB; 15:7970
    db $CC, $CC, $BC, $FB, $00, $48, $30, $00, $42, $00, $7B, $AD, $DB, $BB, $FE, $51; 15:7980
    db $48, $92, $03, $79, $97, $9B, $BE, $EB, $75, $69, $62, $03, $89, $88, $9C, $EE; 15:7990
    db $EB, $BC, $DD, $C9, $BD, $FF, $E1, $00, $58, $00, $00, $55, $34, $68, $EF, $FC; 15:79A0
    db $56, $BC, $81, $03, $67, $76, $79, $AE, $FD, $A7, $8A, $72, $00, $24, $57, $99; 15:79B0
    db $BD, $FF, $CA, $AC, $CA, $9A, $BE, $FF, $E3, $00, $67, $00, $00, $26, $8A, $A7; 15:79C0
    db $8C, $FF, $81, $25, $85, $22, $34, $7B, $FE, $A9, $BF, $FA, $41, $02, $23, $44; 15:79D0
    db $58, $DF, $FD, $BC, $ED, $BA, $AA, $BC, $FF, $70, $00, $75, $00, $00, $59, $EF; 15:79E0
    db $B8, $7C, $FE, $60, $01, $44, $55, $55, $7C, $FF, $E9, $8A, $B7, $20, $00, $25; 15:79F0
    db $AB, $B9, $BF, $FF, $DA, $BC, $CD, $EF, $FA, $00, $03, $50, $00, $04, $8B, $FE; 15:7A00
    db $B8, $8D, $F9, $20, $02, $44, $66, $77, $9F, $FF, $C8, $78, $63, $00, $12, $49; 15:7A10
    db $DE, $CB, $DF, $FD, $BA, $CD, $EF, $FA, $00, $02, $72, $00, $07, $CF, $FF, $B7; 15:7A20
    db $5B, $E9, $00, $00, $68, $98, $98, $BF, $FF, $B3, $01, $34, $11, $26, $9F, $FF; 15:7A30
    db $EB, $BE, $FE, $BA, $CF, $FE, $30, $00, $23, $00, $02, $8F, $FF, $D8, $69, $D9; 15:7A40
    db $30, $00, $47, $BB, $A9, $BF, $FF, $92, $00, $03, $22, $27, $DF, $FF, $EC, $DE; 15:7A50
    db $FE, $CB, $DF, $B0, $00, $16, $20, $00, $7A, $FF, $FA, $66, $AC, $40, $00, $38; 15:7A60
    db $8B, $CC, $CF, $FF, $B1, $00, $11, $11, $37, $CF, $FF, $EB, $DF, $FF, $DD, $FE; 15:7A70
    db $20, $00, $42, $00, $18, $BE, $FF, $A4, $79, $C2, $00, $15, $89, $BE, $CD, $FF; 15:7A80
    db $F6, $00, $02, $21, $47, $BE, $FF, $FA, $9D, $FF, $DC, $FF, $90, $00, $34, $00; 15:7A90
    db $35, $BD, $FF, $C3, $37, $83, $00, $05, $7C, $DF, $CC, $FF, $D3, $00, $00, $35; 15:7AA0
    db $68, $BF, $FF, $B9, $BE, $FF, $FF, $FD, $00, $00, $10, $01, $4A, $FF, $FC, $54; 15:7AB0
    db $95, $10, $00, $48, $EF, $EB, $CF, $F9, $00, $00, $25, $89, $9D, $FF, $C8, $7A; 15:7AC0
    db $CE, $FF, $FF, $F1, $00, $01, $00, $14, $9F, $FF, $93, $38, $30, $00, $16, $DF; 15:7AD0
    db $FD, $CD, $EA, $30, $00, $07, $AB, $BD, $FF, $B8, $77, $8C, $FF, $FF, $FB, $00; 15:7AE0
    db $01, $00, $05, $5E, $FF, $C4, $24, $30, $00, $04, $EF, $FF, $DE, $B7, $30, $00; 15:7AF0
    db $08, $DC, $EF, $FD, $B8, $54, $7C, $EF, $FF, $FF, $10, $00, $02, $13, $5C, $FF; 15:7B00
    db $F7, $20, $00, $00, $05, $FF, $FF, $EA, $75, $30, $00, $08, $FF, $FE, $BC, $B6; 15:7B10
    db $44, $7B, $EF, $FF, $FF, $80, $00, $02, $67, $69, $FF, $F7, $00, $00, $01, $17; 15:7B20
    db $FF, $FF, $F7, $21, $10, $00, $18, $FF, $FA, $88, $87, $66, $7A, $FF, $FF, $FF; 15:7B30
    db $F4, $00, $00, $7B, $A9, $BF, $FF, $40, $00, $04, $67, $CF, $FF, $FA, $10, $00; 15:7B40
    db $12, $26, $CF, $FC, $74, $35, $88, $89, $BD, $EE, $FF, $FF, $F0, $00, $00, $AC; 15:7B50
    db $98, $BF, $FC, $20, $00, $28, $9B, $DF, $FF, $F5, $00, $02, $78, $79, $CE, $DA; 15:7B60
    db $52, $25, $8A, $B9, $9B, $DD, $DE, $FF, $FF, $20, $00, $07, $C7, $9B, $FF, $D5; 15:7B70
    db $00, $03, $6A, $BB, $DF, $FE, $50, $00, $38, $99, $AB, $CC, $96, $21, $47, $9B; 15:7B80
    db $A9, $AB, $CC, $CD, $EF, $FF, $E5, $00, $00, $3A, $99, $BE, $ED, $82, $00, $24; 15:7B90
    db $9C, $CB, $ED, $B7, $20, $03, $8A, $BD, $CA, $86, $31, $24, $7B, $DD, $BA, $88; 15:7BA0
    db $8A, $AC, $DD, $EE, $FF, $70, $00, $01, $AB, $CF, $FF, $EA, $20, $00, $06, $BB; 15:7BB0
    db $CF, $FE, $B7, $10, $04, $79, $BA, $BB, $96, $43, $46, $AC, $B9, $86, $79, $AB; 15:7BC0
    db $CC, $CD, $CB, $BE, $F5, $00, $00, $8F, $DB, $CB, $BB, $70, $00, $05, $DF, $EE; 15:7BD0
    db $ED, $A7, $10, $01, $7B, $FF, $DC, $C8, $30, $00, $4B, $EE, $CA, $77, $86, $79; 15:7BE0
    db $BD, $EE, $DD, $DE, $E9, $00, $00, $3D, $EB, $AB, $BB, $82, $00, $04, $AE, $DA; 15:7BF0
    db $CD, $DA, $60, $00, $59, $CE, $CB, $CB, $95, $00, $06, $BE, $EB, $98, $98, $87; 15:7C00
    db $78, $BC, $DC, $BB, $DE, $FA, $00, $00, $3A, $A9, $8A, $BD, $B6, $00, $02, $7A; 15:7C10
    db $B9, $BC, $DB, $94, $00, $47, $9B, $BA, $CC, $B9, $61, $03, $6A, $CD, $A9, $A9; 15:7C20
    db $88, $86, $8A, $BB, $BB, $CE, $FF, $B3, $00, $00, $59, $99, $AC, $DC, $93, $00; 15:7C30
    db $02, $7B, $BB, $BC, $DD, $A6, $10, $14, $8B, $BB, $BB, $BA, $84, $22, $47, $9A; 15:7C40
    db $99, $99, $AA, $98, $78, $9B, $BC, $BB, $BC, $C9, $52, $00, $03, $68, $88, $88; 15:7C50
    db $AA, $97, $53, $23, $57, $99, $88, $78, $9A, $A9, $87, $78, $88, $88, $88, $88; 15:7C60
    db $88, $87, $77, $77, $77, $77, $88, $88, $88, $99, $99, $98, $88, $88, $88, $88; 15:7C70
    db $98, $87, $77, $66, $55, $55, $56, $67, $77, $78, $88, $88, $88, $88, $99, $99; 15:7C80
    db $99, $99, $87, $77, $77, $88, $88, $87, $77, $66, $66, $67, $78, $89, $99, $98; 15:7C90
    db $87, $76, $78, $88, $88, $88, $88, $76, $66, $77, $88, $99, $88, $87, $76, $66; 15:7CA0
    db $67, $78, $88, $88, $87, $77, $77, $88, $88, $88, $88, $77, $77, $67, $78, $88; 15:7CB0
    db $88, $88, $87, $77, $77, $78, $88, $88, $88, $87, $77, $77, $88, $88, $88, $88; 15:7CC0
    db $88, $77, $77, $77, $88, $88, $88, $87, $77, $77, $77, $88, $89, $88, $88, $77; 15:7CD0
    db $77, $78, $88, $88, $88, $77, $77, $77, $78, $88, $88, $87, $77, $78, $88, $88; 15:7CE0
    db $88, $87, $77, $77, $77, $88, $88, $88, $88, $87, $88, $88, $88, $88, $77, $78; 15:7CF0
    db $88, $88, $88, $88, $88, $77, $77, $88, $77, $88, $88, $88, $88, $88, $87, $77; 15:7D00
    db $78, $88, $88, $77, $77, $77, $77, $88, $88, $88, $88, $88, $78, $88, $88, $88; 15:7D10
    db $77, $77, $77, $78, $88, $88, $88, $77, $77, $77, $77, $88, $88, $88, $87, $77; 15:7D20
    db $77, $77, $88, $88, $88, $87, $77, $77, $88, $88, $88, $88, $88, $78, $88, $88; 15:7D30
    db $88, $88, $87, $77, $77, $78, $88, $88, $88, $88, $87, $77, $77, $78, $88, $88; 15:7D40
    db $88, $77, $77, $77, $78, $88, $88, $87, $77, $77, $78, $88, $88, $88, $88, $77; 15:7D50
    db $77, $78, $88, $88, $88, $77, $77, $77, $88, $88, $88, $87, $77, $78, $88, $88; 15:7D60
    db $88, $77, $77, $77, $88, $88, $88, $88, $87, $77, $77, $87, $77, $77, $78, $88; 15:7D70
    db $78, $88, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88, $78, $88, $88, $88; 15:7D80
    db $88, $87, $77, $77, $88, $88, $88, $88, $88, $88, $87, $77, $77, $88, $88, $77; 15:7D90
    db $78, $77, $88, $88, $88, $88, $87, $77, $77, $88, $88, $88, $88, $87, $77, $88; 15:7DA0
    db $88, $88, $88, $77, $77, $77, $88, $88, $88, $88, $77, $77, $77, $88, $88, $88; 15:7DB0
    db $88, $77, $77, $78, $88, $88, $88, $87, $77, $77, $77, $88, $88, $88, $88, $88; 15:7DC0

;; PCM28: 1872 bytes = 3744 4-bit samples (rate 2) for SFXInst42
PCM28:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:7DD0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:7DE0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:7DF0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:7E00
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $66, $77, $77; 15:7E10
    db $88, $89, $99, $99, $99, $99, $99, $88, $88, $88, $88, $88, $88, $88, $88, $88; 15:7E20
    db $89, $A9, $38, $B3, $34, $64, $02, $32, $53, $37, $87, $78, $CB, $9B, $BC, $B9; 15:7E30
    db $AB, $A9, $67, $86, $44, $66, $44, $67, $76, $8A, $99, $9A, $BA, $99, $AA, $98; 15:7E40
    db $99, $98, $89, $98, $89, $9A, $9A, $C9, $27, $C2, $00, $54, $00, $22, $32, $37; 15:7E50
    db $8A, $A8, $DF, $CB, $AD, $E8, $79, $88, $44, $66, $65, $48, $87, $78, $AB, $88; 15:7E60
    db $9A, $A7, $89, $88, $78, $A9, $99, $AB, $BA, $AA, $BA, $89, $A9, $99, $BC, $20; 15:7E70
    db $97, $10, $06, $10, $02, $76, $38, $BA, $FD, $AC, $CF, $A4, $8B, $75, $26, $86; 15:7E80
    db $56, $7B, $99, $A9, $CB, $88, $88, $84, $57, $77, $68, $BA, $BB, $BD, $DB, $BA; 15:7E90
    db $BB, $99, $9B, $DE, $80, $2A, $60, $00, $51, $00, $39, $A8, $CA, $CF, $FB, $67; 15:7EA0
    db $CA, $21, $27, $73, $47, $9B, $CB, $BA, $EC, $97, $77, $63, $34, $56, $78, $9A; 15:7EB0
    db $CD, $BB, $BC, $CA, $99, $AB, $AB, $DF, $FA, $01, $76, $00, $00, $10, $02, $8B; 15:7EC0
    db $DF, $BB, $DF, $F6, $14, $65, $30, $35, $8B, $BA, $CD, $FF, $98, $66, $63, $22; 15:7ED0
    db $27, $88, $89, $CE, $CB, $BA, $B9, $99, $9A, $BC, $EF, $FF, $80, $24, $50, $00; 15:7EE0
    db $00, $23, $58, $AF, $FE, $A8, $BB, $51, $10, $34, $57, $69, $DF, $FD, $AC, $B8; 15:7EF0
    db $51, $11, $25, $55, $8A, $EE, $DB, $BB, $B8, $86, $69, $BC, $DE, $FF, $F7, $01; 15:7F00
    db $45, $00, $00, $04, $77, $79, $FF, $F8, $58, $95, $10, $02, $48, $99, $AE, $FF; 15:7F10
    db $EA, $98, $83, $00, $02, $66, $89, $CF, $FE, $CA, $A9, $87, $67, $9B, $EF, $FF; 15:7F20
    db $E3, $24, $71, $00, $01, $33, $59, $9E, $FF, $C6, $7A, $82, $00, $45, $57, $89; 15:7F30
    db $CE, $FE, $AB, $98, $51, $12, $24, $57, $9A, $DE, $DC, $CC, $C8, $88, $AB, $BC; 15:7F40
    db $FF, $B1, $26, $80, $00, $04, $22, $39, $AD, $ED, $A9, $AB, $71, $13, $74, $23; 15:7F50
    db $9A, $CA, $CD, $CB, $A8, $55, $45, $33, $58, $88, $9D, $DD, $CC, $DC, $BA, $BC; 15:7F60
    db $DF, $F5, $04, $87, $00, $04, $20, $05, $B9, $BB, $BB, $DD, $B5, $47, $75, $02; 15:7F70
    db $68, $56, $8B, $CA, $AA, $A9, $87, $65, $67, $67, $8A, $BB, $BC, $DD, $CB, $CC; 15:7F80
    db $CD, $B4, $27, $84, $00, $34, $10, $14, $76, $78, $8B, $BA, $9A, $BB, $97, $77; 15:7F90
    db $76, $55, $56, $66, $78, $99, $88, $99, $98, $89, $88, $89, $99, $99, $AA, $98; 15:7FA0
    db $88, $98, $87, $78, $98, $77, $87, $76, $55, $55, $44, $44, $45, $55, $56, $78; 15:7FB0
    db $88, $9A, $99, $AB, $BB, $AA, $AA, $98, $88, $77, $66, $67, $77, $78, $88, $88; 15:7FC0
    db $89, $99, $88, $99, $98, $88, $88, $76, $67, $65, $55, $55, $45, $55, $55, $56; 15:7FD0
    db $67, $88, $89, $9A, $AA, $AB, $BA, $AA, $99, $88, $88, $77, $77, $77, $78, $88; 15:7FE0
    db $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $77, $77, $77, $66, $66; 15:7FF0

; ============================================================================
SECTION "GHX PCM samples bank $16", ROMX[$4000], BANK[$16]
; ============================================================================
;; (continuation of the previous sample from bank $15)
    db $66, $66, $66, $67, $78, $88, $88, $99, $99, $99, $99, $98, $88, $88, $88, $88; 16:4000
    db $87, $78, $88, $77, $78, $88, $88, $88, $77, $77, $87, $77, $88, $87, $78, $87; 16:4010
    db $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $78; 16:4020
    db $88, $88, $88, $88, $88, $88, $77, $87, $77, $77, $88, $88, $88, $88, $88, $88; 16:4030
    db $88, $87, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $77, $78, $87, $78; 16:4040
    db $88, $88, $77, $88, $87, $78, $87, $77, $87, $77, $77, $77, $78, $88, $88, $88; 16:4050
    db $88, $88, $88, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88; 16:4060
    db $88, $88, $88, $87, $77, $77, $77, $88, $88, $88, $88, $88, $77, $77, $77, $77; 16:4070
    db $88, $88, $88, $88, $86, $97, $88, $76, $95, $7A, $5A, $68, $78, $78, $87, $87; 16:4080
    db $86, $87, $79, $78, $79, $69, $78, $57, $79, $78, $88, $A7, $A8, $89, $78, $68; 16:4090
    db $67, $87, $78, $88, $88, $88, $79, $78, $77, $87, $77, $77, $77, $77, $87, $77; 16:40A0
    db $77, $78, $78, $78, $69, $78, $86, $87, $68, $78, $88, $88, $89, $68, $96, $97; 16:40B0
    db $78, $68, $77, $A4, $C4, $97, $97, $96, $A5, $A5, $88, $6A, $4A, $68, $77, $79; 16:40C0
    db $69, $78, $77, $96, $87, $87, $88, $78, $78, $87, $88, $78, $77, $77, $88, $69; 16:40D0
    db $88, $88, $77, $87, $79, $77, $88, $68, $95, $88, $85, $96, $87, $88, $68, $77; 16:40E0
    db $87, $97, $79, $79, $6A, $68, $78, $78, $95, $98, $78, $88, $78, $96, $89, $68; 16:40F0
    db $78, $68, $86, $88, $78, $87, $78, $86, $78, $87, $97, $88, $87, $78, $77, $87; 16:4100
    db $68, $77, $78, $78, $88, $69, $87, $87, $78, $87, $68, $97, $88, $87, $88, $78; 16:4110
    db $97, $79, $87, $88, $67, $86, $57, $64, $55, $45, $66, $67, $87, $89, $99, $A9; 16:4120
    db $9A, $A9, $99, $99, $AA, $AA, $AA, $AA, $AA, $AA, $99, $AA, $BF, $A0, $59, $01; 16:4130
    db $00, $00, $30, $09, $B8, $C9, $BE, $FE, $86, $C8, $66, $25, $78, $75, $7C, $BA; 16:4140
    db $99, $B9, $97, $58, $87, $77, $AC, $AB, $BC, $ED, $CC, $DE, $EF, $F5, $08, $60; 16:4150
    db $00, $00, $07, $00, $BF, $EF, $6E, $DA, $F2, $04, $66, $20, $68, $AF, $89, $EF; 16:4160
    db $FB, $58, $67, $60, $24, $8A, $67, $CD, $EC, $AC, $BB, $96, $79, $AA, $9B, $FF; 16:4170
    db $FB, $05, $94, $10, $00, $07, $20, $4E, $FF, $4A, $CC, $E3, $10, $28, $80, $27; 16:4180
    db $DF, $BD, $BD, $FF, $73, $25, $70, $20, $69, $AA, $9B, $EE, $A9, $7A, $87, $76; 16:4190
    db $9B, $BB, $CE, $FF, $F1, $07, $44, $00, $00, $55, $42, $BF, $FE, $6B, $8E, $60; 16:41A0
    db $00, $38, $62, $69, $FF, $EC, $AE, $DA, $41, $04, $34, $33, $9C, $EC, $BA, $CB; 16:41B0
    db $96, $46, $68, $78, $AC, $EE, $EE, $FF, $FA, $00, $06, $00, $00, $58, $65, $8D; 16:41C0
    db $FF, $97, $29, $B3, $00, $18, $A8, $88, $FF, $FF, $88, $A9, $61, $01, $46, $75; 16:41D0
    db $8B, $EE, $B9, $89, $86, $44, $58, $99, $BB, $EE, $ED, $CD, $DE, $F7, $00, $04; 16:41E0
    db $10, $00, $69, $78, $AB, $FF, $B6, $15, $84, $10, $28, $AB, $AA, $DF, $FE, $86; 16:41F0
    db $67, $73, $02, $58, $98, $9A, $CD, $A8, $77, $87, $55, $69, $BA, $BB, $CD, $CB; 16:4200
    db $AA, $AA, $AB, $D6, $00, $27, $10, $00, $78, $78, $89, $CE, $A6, $15, $87, $40; 16:4210
    db $49, $BC, $A9, $BC, $DC, $75, $46, $75, $34, $7A, $AA, $A9, $AA, $98, $65, $67; 16:4220
    db $77, $79, $BB, $BB, $AB, $BA, $98, $99, $AB, $CF, $A0, $01, $63, $00, $05, $86; 16:4230
    db $78, $9B, $EB, $93, $48, $85, $23, $8A, $BA, $9A, $BB, $C9, $65, $58, $75, $45; 16:4240
    db $9A, $87, $67, $99, $86, $68, $AA, $98, $9A, $AA, $88, $89, $99, $9A, $AB, $CC; 16:4250
    db $DE, $C1, $00, $33, $00, $04, $88, $89, $99, $BB, $83, $27, $98, $65, $9C, $CB; 16:4260
    db $99, $99, $97, $44, $58, $87, $67, $AB, $97, $66, $88, $87, $68, $A9, $86, $78; 16:4270
    db $98, $88, $9B, $BB, $BA, $BC, $BA, $99, $BC, $80, $00, $34, $00, $25, $97, $76; 16:4280
    db $67, $98, $54, $5B, $BA, $AA, $DD, $B9, $66, $66, $65, $47, $9B, $A8, $9A, $BA; 16:4290
    db $86, $66, $88, $76, $79, $A8, $76, $89, $99, $99, $BB, $BA, $9A, $BA, $99, $99; 16:42A0
    db $9A, $CC, $50, $03, $40, $00, $36, $55, $66, $78, $97, $56, $AC, $A8, $9B, $C9; 16:42B0
    db $76, $77, $76, $66, $79, $A9, $88, $99, $87, $77, $78, $88, $88, $89, $87, $67; 16:42C0
    db $78, $89, $99, $AB, $BA, $AA, $AA, $99, $99, $9A, $AC, $B4, $00, $34, $00, $03; 16:42D0
    db $65, $45, $67, $88, $65, $7A, $B9, $9A, $CC, $98, $77, $77, $66, $57, $99, $98; 16:42E0
    db $8A, $98, $88, $88, $89, $98, $88, $88, $66, $67, $78, $99, $9A, $AB, $A9, $AA; 16:42F0
    db $AA, $AA, $A9, $AA, $AC, $B2, $00, $23, $00, $13, $55, $47, $68, $98, $66, $8B; 16:4300
    db $B8, $AB, $CB, $77, $77, $76, $66, $78, $A9, $99, $9A, $88, $88, $88, $88, $88; 16:4310
    db $87, $76, $67, $66, $78, $98, $9A, $BA, $AA, $AB, $AA, $A9, $A9, $99, $89, $BB; 16:4320
    db $20, $24, $30, $03, $44, $43, $66, $78, $85, $7A, $BB, $8B, $DB, $A8, $88, $77; 16:4330
    db $76, $68, $8A, $87, $AA, $98, $89, $88, $88, $88, $88, $86, $77, $66, $68, $88; 16:4340
    db $89, $9A, $99, $AA, $AA, $AB, $AA, $AA, $98, $89, $A9, $00, $33, $20, $04, $43; 16:4350
    db $44, $67, $88, $87, $9B, $AB, $AB, $DA, $98, $88, $87, $66, $68, $88, $78, $99; 16:4360
    db $88, $88, $89, $88, $88, $97, $77, $77, $76, $78, $88, $88, $99, $99, $AA, $AA; 16:4370
    db $AA, $A9, $99, $88, $88, $9B, $40, $24, $10, $02, $42, $34, $66, $88, $89, $8B; 16:4380
    db $B9, $AB, $CB, $B9, $99, $88, $76, $67, $77, $77, $88, $88, $89, $99, $98, $99; 16:4390
    db $98, $88, $88, $77, $78, $88, $88, $99, $99, $99, $99, $99, $98, $88, $88, $88; 16:43A0
    db $9A, $92, $05, $31, $00, $22, $32, $45, $58, $87, $99, $A9, $AA, $BB, $AA, $A9; 16:43B0
    db $AA, $88, $88, $88, $77, $77, $78, $77, $88, $88, $88, $88, $88, $98, $88, $88; 16:43C0
    db $88, $88, $88, $88, $88, $88, $89, $98, $99, $88, $88, $99, $97, $56, $34, $41; 16:43D0
    db $01, $21, $23, $25, $66, $78, $99, $AB, $BB, $BB, $BB, $CC, $BA, $A9, $88, $87; 16:43E0
    db $77, $66, $66, $67, $77, $77, $88, $89, $99, $9A, $99, $99, $99, $98, $88, $88; 16:43F0
    db $88, $88, $87, $88, $88, $88, $99, $A8, $66, $54, $53, $11, $21, $23, $23, $55; 16:4400
    db $67, $88, $9A, $BB, $BB, $BB, $CC, $BA, $A9, $98, $88, $77, $66, $66, $66, $77; 16:4410
    db $77, $88, $89, $99, $99, $99, $99, $98, $88, $88, $87, $77, $77, $88, $88, $88; 16:4420
    db $88, $88, $88, $88, $76, $65, $55, $44, $43, $33, $44, $55, $56, $67, $89, $9A; 16:4430
    db $AA, $AB, $BA, $AA, $AA, $99, $98, $88, $88, $77, $78, $88, $88, $88, $88, $89; 16:4440
    db $99, $98, $88, $88, $88, $87, $77, $77, $77, $77, $77, $78, $87, $77, $77, $77; 16:4450
    db $77, $77, $76, $66, $66, $65, $55, $55, $55, $66, $67, $78, $88, $88, $99, $99; 16:4460
    db $99, $99, $99, $99, $98, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 16:4470
    db $88, $88, $87, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77; 16:4480
    db $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88; 16:4490
    db $88, $88, $99, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $77; 16:44A0
    db $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $78, $87, $78; 16:44B0
    db $87, $77, $77, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88; 16:44C0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $78, $77, $77; 16:44D0
    db $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77; 16:44E0
    db $77, $77, $78, $87, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 16:44F0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77; 16:4500
    db $77, $77, $88, $88, $88, $88, $87, $77, $77, $77, $77, $77, $78, $88, $78, $88; 16:4510

;; PCM29: 2144 bytes = 4288 4-bit samples (rate 2) for SFXInst43
PCM29:
    db $88, $88, $88, $88, $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88, $88; 16:4520
    db $88, $88, $78, $88, $88, $88, $88, $88, $77, $77, $87, $87, $87, $88, $87, $68; 16:4530
    db $77, $88, $88, $87, $88, $88, $87, $78, $77, $87, $77, $77, $78, $88, $88, $88; 16:4540
    db $88, $88, $78, $77, $77, $77, $87, $78, $77, $77, $77, $77, $77, $78, $78, $78; 16:4550
    db $88, $87, $77, $77, $77, $77, $77, $77, $77, $88, $88, $88, $88, $88, $88, $88; 16:4560
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $89, $AB, $C7, $36, $43, $20, $02; 16:4570
    db $42, $36, $8B, $CB, $AC, $DB, $A8, $67, $76, $45, $67, $88, $9A, $CB, $AA, $99; 16:4580
    db $87, $67, $87, $89, $9B, $BB, $BB, $BB, $A9, $9A, $9A, $CF, $00, $90, $10, $00; 16:4590
    db $1A, $04, $C9, $FF, $A5, $CE, $35, $20, $57, $41, $AD, $BF, $CB, $EF, $A5, $86; 16:45A0
    db $44, $12, $68, $78, $CC, $ED, $AA, $BA, $66, $77, $98, $8A, $CD, $CD, $DE, $FF; 16:45B0
    db $F0, $0D, $00, $00, $01, $C0, $6F, $DF, $CB, $7E, $D0, $03, $13, $22, $3F, $F9; 16:45C0
    db $EF, $FF, $C7, $49, $60, $01, $46, $66, $AF, $EB, $BC, $C9, $64, $69, $65, $8C; 16:45D0
    db $DC, $CD, $FF, $EF, $F0, $0A, $00, $00, $00, $80, $9F, $DE, $CF, $AD, $90, $35; 16:45E0
    db $10, $06, $5A, $B9, $FF, $FB, $DD, $86, $41, $22, $11, $78, $8A, $CE, $CB, $A9; 16:45F0
    db $A8, $56, $88, $8A, $BC, $EE, $EE, $FF, $80, $88, $00, $00, $00, $00, $ED, $99; 16:4600
    db $FF, $BA, $87, $93, $00, $56, $03, $AC, $BA, $DE, $FC, $8A, $B7, $12, $63, $23; 16:4610
    db $79, $99, $AE, $D9, $9B, $B8, $79, $A9, $89, $CD, $CC, $FF, $03, $F0, $00, $21; 16:4620
    db $01, $05, $82, $6B, $F9, $8F, $DA, $78, $A5, $53, $58, $44, $5B, $85, $BC, $B9; 16:4630
    db $AC, $88, $77, $75, $55, $87, $58, $AA, $7A, $CB, $AA, $CB, $AA, $AB, $AA, $CC; 16:4640
    db $32, $F3, $01, $75, $03, $42, $11, $86, $85, $8D, $98, $9C, $B6, $AB, $97, $7B; 16:4650
    db $76, $68, $84, $68, $86, $6B, $A8, $8B, $B8, $99, $97, $68, $77, $78, $88, $99; 16:4660
    db $89, $A9, $88, $88, $77, $77, $65, $78, $66, $88, $66, $76, $55, $65, $55, $55; 16:4670
    db $66, $67, $88, $99, $99, $9A, $98, $99, $88, $99, $99, $99, $98, $88, $76, $66; 16:4680
    db $55, $56, $67, $88, $9A, $A9, $AA, $99, $98, $77, $76, $76, $66, $78, $78, $88; 16:4690
    db $88, $88, $77, $77, $77, $77, $77, $77, $76, $66, $66, $66, $66, $78, $89, $99; 16:46A0
    db $AA, $AA, $99, $88, $77, $77, $66, $77, $78, $88, $88, $88, $88, $77, $77, $77; 16:46B0
    db $77, $88, $88, $98, $88, $88, $77, $77, $77, $77, $78, $88, $88, $88, $77, $87; 16:46C0
    db $77, $77, $77, $77, $88, $88, $88, $88, $77, $77, $77, $77, $78, $88, $88, $88; 16:46D0
    db $88, $88, $77, $77, $77, $78, $88, $88, $88, $88, $88, $87, $87, $77, $88, $78; 16:46E0
    db $88, $88, $88, $88, $78, $87, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77; 16:46F0
    db $77, $88, $88, $88, $88, $88, $87, $77, $77, $77, $88, $88, $88, $88, $88, $88; 16:4700
    db $88, $88, $88, $88, $87, $77, $77, $87, $78, $87, $88, $87, $88, $88, $88, $87; 16:4710
    db $88, $77, $77, $77, $77, $77, $68, $96, $79, $87, $88, $77, $98, $66, $89, $77; 16:4720
    db $99, $87, $88, $87, $78, $88, $78, $89, $88, $77, $77, $87, $68, $87, $79, $87; 16:4730
    db $89, $77, $88, $67, $78, $67, $77, $77, $77, $77, $87, $88, $88, $88, $88, $87; 16:4740
    db $87, $88, $88, $88, $88, $98, $98, $98, $88, $88, $88, $88, $89, $99, $77, $87; 16:4750
    db $55, $55, $33, $34, $34, $56, $66, $89, $99, $9B, $A9, $99, $98, $88, $98, $89; 16:4760
    db $99, $9A, $AA, $AA, $A9, $99, $99, $B9, $BC, $B7, $6B, $62, $23, $30, $00, $11; 16:4770
    db $02, $47, $66, $BB, $BA, $CD, $BB, $AA, $98, $76, $77, $67, $88, $78, $99, $9A; 16:4780
    db $AA, $AA, $AA, $BA, $AA, $BA, $AA, $BC, $B9, $66, $A3, $12, $21, $00, $00, $01; 16:4790
    db $35, $66, $7B, $BA, $BC, $DB, $BA, $99, $87, $67, $76, $79, $88, $9A, $AA, $AA; 16:47A0
    db $BB, $9A, $A9, $99, $99, $89, $98, $A8, $A9, $87, $76, $64, $44, $33, $22, $22; 16:47B0
    db $23, $45, $66, $78, $88, $99, $9A, $98, $99, $89, $99, $99, $A9, $AA, $99, $A9; 16:47C0
    db $8A, $89, $88, $97, $98, $88, $88, $88, $87, $87, $88, $68, $86, $87, $76, $67; 16:47D0
    db $66, $66, $66, $65, $66, $56, $66, $66, $77, $78, $78, $88, $98, $99, $8A, $89; 16:47E0
    db $98, $9A, $8A, $88, $A7, $88, $89, $69, $87, $87, $78, $78, $77, $77, $87, $78; 16:47F0
    db $86, $97, $78, $77, $77, $77, $77, $77, $87, $78, $68, $77, $77, $77, $86, $87; 16:4800
    db $87, $88, $87, $78, $68, $87, $78, $78, $78, $77, $97, $98, $89, $78, $87, $88; 16:4810
    db $79, $78, $87, $97, $88, $79, $88, $88, $78, $78, $87, $88, $78, $77, $95, $A7; 16:4820
    db $69, $68, $78, $88, $88, $78, $77, $96, $87, $68, $75, $86, $96, $88, $69, $78; 16:4830
    db $78, $77, $95, $88, $69, $78, $88, $87, $97, $88, $88, $78, $77, $87, $78, $78; 16:4840
    db $87, $88, $88, $88, $88, $78, $77, $87, $87, $78, $78, $88, $88, $78, $77, $87; 16:4850
    db $69, $76, $96, $88, $78, $88, $87, $89, $69, $77, $97, $79, $77, $88, $87, $88; 16:4860
    db $78, $87, $78, $78, $87, $88, $78, $78, $87, $77, $77, $78, $78, $87, $87, $97; 16:4870
    db $79, $78, $88, $77, $87, $78, $87, $88, $87, $89, $68, $86, $87, $87, $68, $77; 16:4880
    db $96, $88, $78, $87, $97, $78, $78, $87, $87, $88, $7A, $78, $96, $88, $79, $6A; 16:4890
    db $67, $A4, $98, $68, $87, $78, $77, $88, $78, $76, $96, $78, $87, $78, $77, $87; 16:48A0
    db $87, $78, $78, $78, $86, $88, $78, $78, $87, $87, $78, $87, $88, $87, $88, $77; 16:48B0
    db $96, $89, $68, $87, $87, $88, $68, $77, $86, $88, $69, $67, $86, $98, $69, $86; 16:48C0
    db $97, $77, $88, $68, $86, $88, $78, $88, $68, $88, $79, $77, $79, $59, $86, $97; 16:48D0
    db $86, $A7, $5B, $75, $98, $76, $A7, $68, $77, $78, $77, $87, $87, $97, $7A, $76; 16:48E0
    db $97, $87, $87, $79, $67, $96, $88, $67, $87, $78, $86, $97, $69, $67, $97, $87; 16:48F0
    db $79, $68, $86, $86, $89, $58, $96, $88, $77, $89, $57, $97, $6A, $85, $98, $78; 16:4900
    db $79, $67, $87, $88, $87, $79, $76, $88, $78, $86, $88, $78, $78, $77, $87, $88; 16:4910
    db $78, $68, $86, $87, $87, $87, $88, $77, $98, $78, $97, $6A, $77, $88, $87, $87; 16:4920
    db $79, $68, $87, $88, $97, $78, $87, $88, $77, $98, $59, $86, $88, $78, $87, $88; 16:4930
    db $68, $87, $79, $77, $97, $69, $86, $88, $77, $88, $68, $95, $88, $77, $87, $77; 16:4940
    db $87, $78, $87, $79, $86, $97, $78, $87, $78, $79, $85, $98, $68, $96, $69, $76; 16:4950
    db $89, $58, $96, $79, $76, $88, $77, $97, $69, $76, $87, $87, $88, $79, $77, $87; 16:4960
    db $88, $87, $88, $78, $88, $87, $87, $88, $78, $87, $88, $87, $88, $78, $77, $78; 16:4970
    db $67, $86, $78, $76, $88, $67, $87, $78, $86, $88, $68, $87, $78, $88, $88, $97; 16:4980
    db $A9, $79, $98, $8A, $98, $A9, $8A, $A9, $9A, $AA, $83, $67, $34, $00, $22, $21; 16:4990
    db $26, $66, $88, $AC, $BA, $AB, $C9, $77, $77, $74, $57, $88, $88, $AB, $B9, $9B; 16:49A0
    db $B9, $AA, $AB, $BA, $CE, $FF, $81, $A9, $21, $00, $00, $00, $08, $75, $78, $CF; 16:49B0
    db $DB, $8B, $E9, $55, $57, $62, $35, $88, $67, $BB, $B8, $8B, $BA, $88, $AB, $BA; 16:49C0
    db $AE, $FF, $FF, $F3, $1F, $20, $00, $00, $00, $03, $D8, $AB, $CF, $FE, $A5, $AA; 16:49D0
    db $31, $03, $53, $43, $7D, $C8, $AB, $DB, $77, $68, $85, $69, $BC, $AC, $FF, $FF; 16:49E0
    db $FF, $F1, $0A, $00, $00, $00, $43, $05, $FF, $FC, $DF, $CE, $50, $04, $10, $02; 16:49F0
    db $99, $B9, $BF, $FD, $A6, $A8, $52, $25, $77, $88, $BF, $ED, $CD, $EC, $AB, $BD; 16:4A00
    db $FE, $00, $B2, $20, $02, $2D, $92, $7F, $FF, $36, $96, $70, $00, $78, $70, $AE; 16:4A10
    db $FF, $B9, $AC, $95, $04, $57, $44, $8C, $DD, $A9, $DB, $B7, $89, $A9, $AB, $FF; 16:4A20
    db $F8, $05, $64, $00, $00, $9E, $82, $DF, $FB, $25, $06, $40, $00, $7F, $BA, $BE; 16:4A30
    db $FF, $B3, $24, $72, $10, $6B, $CC, $AC, $EE, $97, $48, $88, $78, $AE, $FF, $FF; 16:4A40
    db $FE, $00, $00, $00, $00, $9F, $FC, $BD, $FF, $20, $00, $05, $22, $5F, $FF, $E9; 16:4A50
    db $B8, $A2, $00, $06, $A8, $AB, $FF, $C9, $56, $66, $55, $7B, $BD, $CE, $EE, $ED; 16:4A60
    db $FF, $F0, $00, $06, $00, $46, $FF, $FA, $65, $A2, $00, $00, $6E, $DD, $DF, $FF; 16:4A70
    db $84, $00, $13, $43, $7D, $FF, $EA, $86, $86, $53, $48, $CC, $B9, $AB, $CB, $88; 16:4A80
    db $8B, $CC, $EF, $B0, $00, $45, $07, $0A, $FF, $F6, $03, $33, $10, $00, $EF, $FB; 16:4A90
    db $BA, $B8, $71, $00, $7D, $DC, $AB, $BC, $95, $13, $69, $99, $99, $AB, $A8, $67; 16:4AA0
    db $9A, $BA, $AA, $CE, $FF, $F3, $00, $05, $17, $82, $CF, $FD, $50, $00, $24, $20; 16:4AB0
    db $6F, $FF, $D9, $24, $57, $20, $39, $EF, $FB, $65, $77, $54, $46, $AD, $C8, $66; 16:4AC0
    db $78, $98, $88, $AC, $BA, $89, $BD, $EE, $FF, $00, $00, $54, $D9, $6C, $FF, $92; 16:4AD0
    db $00, $04, $57, $5B, $FF, $FC, $60, $03, $56, $89, $BE, $FE, $95, $33, $35, $77; 16:4AE0
    db $9B, $B9, $87, $67, $8A, $AA, $A9, $88, $99, $9B, $CC, $CC, $CF, $E0, $00, $04; 16:4AF0
    db $7E, $85, $AD, $D7, $20, $00, $8A, $AA, $DD, $EE, $93, $00, $47, $BC, $BB, $DE; 16:4B00
    db $B7, $42, $25, $88, $8A, $AA, $98, $65, $68, $99, $99, $99, $BB, $BA, $A9, $88; 16:4B10
    db $89, $AE, $F9, $00, $00, $5A, $B6, $6C, $EC, $71, $00, $38, $9A, $AB, $CE, $D7; 16:4B20
    db $20, $26, $AC, $A9, $AB, $CA, $74, $25, $9B, $A8, $77, $88, $76, $68, $AB, $B8; 16:4B30
    db $77, $89, $99, $89, $AB, $AA, $AA, $AA, $CB, $40, $00, $17, $BA, $89, $DB, $84; 16:4B40
    db $00, $05, $9A, $BB, $BC, $DA, $41, $13, $7B, $CB, $BC, $CB, $84, $23, $69, $AA; 16:4B50
    db $87, $78, $87, $67, $9A, $A9, $87, $88, $9A, $99, $9A, $99, $98, $9A, $A9, $9A; 16:4B60
    db $94, $00, $01, $6A, $A8, $8B, $B8, $50, $00, $59, $9B, $BB, $BB, $84, $23, $58; 16:4B70
    db $BC, $BB, $BA, $97, $53, $57, $9A, $A8, $77, $88, $88, $89, $A9, $86, $66, $89; 16:4B80
    db $AB, $BB, $A9, $87, $78, $89, $A9, $99, $BB, $60, $00, $07, $BA, $87, $A9, $85; 16:4B90
    db $00, $16, $AB, $CB, $BB, $B9, $53, $35, $8B, $BB, $AA, $A9, $75, $34, $78, $9A; 16:4BA0
    db $99, $87, $65, $68, $99, $98, $87, $78, $89, $AB, $A9, $98, $78, $89, $AA, $A9; 16:4BB0
    db $88, $9B, $A5, $00, $02, $79, $87, $8B, $A8, $40, $03, $89, $9A, $AB, $CB, $73; 16:4BC0
    db $34, $69, $A9, $AB, $CB, $97, $55, $67, $78, $9A, $A9, $86, $67, $88, $88, $78; 16:4BD0
    db $88, $88, $9A, $AA, $98, $88, $88, $89, $AA, $98, $88, $AA, $81, $00, $05, $86; 16:4BE0
    db $66, $AC, $A7, $21, $25, $76, $78, $BD, $DB, $76, $66, $65, $67, $BD, $DB, $98; 16:4BF0
    db $87, $64, $46, $9B, $A9, $88, $87, $65, $67, $89, $88, $99, $99, $88, $99, $98; 16:4C00
    db $88, $9A, $A9, $88, $9B, $C6, $00, $02, $65, $54, $AE, $C9, $43, $35, $52, $37; 16:4C10
    db $BE, $EC, $88, $98, $53, $36, $9C, $BB, $BC, $B9, $74, $45, $78, $78, $AB, $B9; 16:4C20
    db $76, $67, $66, $67, $99, $99, $99, $99, $88, $89, $99, $99, $AA, $CB, $40, $01; 16:4C30
    db $33, $34, $6C, $DA, $76, $65, $52, $03, $7A, $BB, $BC, $DB, $85, $45, $67, $77; 16:4C40
    db $9B, $CB, $A9, $88, $75, $45, $78, $88, $9A, $A9, $86, $77, $76, $67, $8A, $A9; 16:4C50
    db $99, $A9, $88, $78, $89, $88, $77, $64, $44, $55, $56, $67, $88, $87, $66, $66; 16:4C60
    db $56, $78, $99, $99, $99, $98, $88, $77, $88, $88, $89, $99, $88, $88, $87, $77; 16:4C70
    db $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $89, $98, $76; 16:4C80
    db $65, $55, $55, $67, $77, $88, $88, $87, $77, $66, $77, $78, $88, $99, $99, $98; 16:4C90
    db $88, $87, $77, $77, $78, $88, $88, $88, $89, $9A, $AA, $A9, $98, $87, $66, $66; 16:4CA0
    db $66, $56, $66, $66, $66, $77, $88, $88, $88, $88, $88, $88, $88, $88, $78, $77; 16:4CB0
    db $77, $77, $77, $78, $88, $88, $88, $89, $98, $88, $88, $88, $88, $87, $77, $77; 16:4CC0
    db $77, $77, $88, $77, $77, $77, $77, $78, $88, $88, $88, $87, $88, $87, $87, $88; 16:4CD0
    db $87, $78, $88, $77, $77, $77, $77, $78, $88, $88, $88, $87, $78, $88, $88, $88; 16:4CE0
    db $88, $88, $88, $88, $88, $88, $88, $77, $77, $77, $77, $77, $77, $77, $78, $88; 16:4CF0
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $78, $77, $77; 16:4D00
    db $77, $77, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $87, $88, $88, $87; 16:4D10
    db $77, $77, $77, $77, $78, $88, $88, $88, $87, $77, $78, $88, $88, $88, $87, $77; 16:4D20
    db $78, $88, $88, $88, $88, $77, $77, $77, $88, $88, $88, $88, $87, $77, $77, $78; 16:4D30
    db $88, $88, $88, $88, $87, $77, $87, $77, $88, $87, $77, $77, $77, $77, $88, $88; 16:4D40
    db $88, $78, $88, $88, $88, $88, $88, $88, $77, $77, $88, $88, $88, $87, $77, $77; 16:4D50
    db $77, $88, $88, $88, $88, $88, $88, $87, $77, $88, $88, $88, $88, $88, $78, $88; 16:4D60
    db $87, $88, $88, $88, $77, $77, $77, $77, $78, $88, $88, $88, $88, $88, $87, $77; 16:4D70

;; PCM30: 1696 bytes = 3392 4-bit samples (rate 2) for SFXInst44
PCM30:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 16:4D80
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 16:4D90
    db $88, $89, $99, $98, $75, $34, $55, $55, $67, $89, $AA, $98, $88, $87, $66, $66; 16:4DA0
    db $78, $88, $99, $A9, $98, $88, $78, $88, $88, $89, $99, $99, $99, $99, $99, $99; 16:4DB0
    db $AA, $AA, $A7, $00, $03, $32, $24, $58, $BD, $C9, $78, $98, $53, $33, $47, $9A; 16:4DC0
    db $A9, $BC, $CB, $97, $54, $55, $66, $67, $AB, $BA, $A9, $88, $88, $76, $78, $99; 16:4DD0
    db $9A, $AB, $BB, $BB, $BB, $CB, $20, $00, $43, $22, $46, $AC, $FD, $86, $68, $74; 16:4DE0
    db $11, $25, $7A, $CB, $AB, $DE, $C8, $64, $44, $56, $55, $79, $CC, $A9, $88, $98; 16:4DF0
    db $87, $66, $89, $AA, $AB, $CD, $DE, $EE, $A0, $00, $14, $10, $14, $8B, $EF, $D9; 16:4E00
    db $56, $98, $30, $01, $57, $AB, $BA, $BD, $FD, $94, $23, $45, $55, $67, $AC, $DB; 16:4E10
    db $98, $89, $98, $66, $67, $9A, $BB, $BD, $FF, $FA, $00, $02, $41, $00, $28, $CF; 16:4E20
    db $FD, $96, $8B, $94, $00, $04, $79, $9A, $AB, $EF, $FB, $53, $35, $53, $34, $69; 16:4E30
    db $BD, $CA, $99, $AA, $87, $67, $89, $AA, $BC, $EF, $F7, $00, $05, $40, $00, $48; 16:4E40
    db $BE, $ED, $98, $AB, $94, $00, $25, $76, $78, $AC, $DE, $EA, $74, $56, $53, $23; 16:4E50
    db $79, $BB, $BB, $AA, $BB, $98, $78, $AA, $BB, $DF, $C5, $00, $46, $30, $01, $69; 16:4E60
    db $AB, $BB, $89, $BB, $93, $01, $57, $64, $58, $AC, $CC, $B9, $76, $77, $53, $35; 16:4E70
    db $89, $99, $9A, $BB, $BB, $A9, $9B, $BC, $CD, $C5, $00, $26, $51, $01, $7A, $BB; 16:4E80
    db $AB, $A9, $AA, $84, $11, $57, $85, $57, $AC, $CB, $A8, $76, $66, $64, $45, $8A; 16:4E90
    db $A9, $9B, $BB, $BA, $AA, $AB, $DF, $E6, $00, $27, $50, $00, $5A, $BB, $AB, $BB; 16:4EA0
    db $CB, $84, $12, $67, $52, $48, $BC, $BA, $A9, $87, $66, $43, $36, $89, $89, $BD; 16:4EB0
    db $DB, $BC, $CC, $CD, $E9, $10, $07, $71, $00, $5B, $B9, $8A, $CC, $CB, $95, $22; 16:4EC0
    db $66, $41, $28, $CC, $A9, $BB, $A8, $65, $43, $45, $76, $79, $CE, $DC, $DF, $FF; 16:4ED0
    db $FC, $40, $03, $61, $00, $2A, $B8, $7A, $EE, $DB, $97, $54, $55, $20, $27, $AA; 16:4EE0
    db $88, $BD, $B9, $77, $75, $55, $56, $79, $BB, $CD, $FF, $FF, $93, $24, $61, $00; 16:4EF0
    db $06, $86, $69, $EF, $EC, $A8, $77, $64, $10, $26, $86, $68, $BD, $B9, $89, $87; 16:4F00
    db $55, $56, $89, $BB, $CF, $FF, $E6, $47, $94, $00, $04, $41, $27, $BE, $DC, $CB; 16:4F10
    db $BB, $96, $22, $55, $42, $48, $AA, $98, $BB, $98, $77, $77, $88, $AC, $DE, $FD; 16:4F20
    db $66, $8A, $40, $03, $64, $03, $9B, $C9, $AB, $BB, $A6, $44, $67, $42, $48, $A8; 16:4F30
    db $78, $AB, $97, $77, $87, $67, $9B, $DD, $FF, $95, $8A, $80, $02, $53, $00, $8A; 16:4F40
    db $AA, $AC, $CB, $B8, $66, $66, $32, $46, $76, $69, $BA, $99, $AA, $88, $78, $AA; 16:4F50
    db $BC, $EE, $57, $AA, $40, $16, $41, $04, $98, $99, $9C, $CB, $96, $88, $53, $25; 16:4F60
    db $74, $45, $8A, $88, $AB, $C9, $89, $BB, $BB, $DF, $B3, $7B, $81, $04, $63, $12; 16:4F70
    db $69, $89, $8A, $DC, $88, $8A, $74, $35, $65, $34, $68, $86, $8B, $BA, $8A, $CB; 16:4F80
    db $BC, $EF, $D3, $8B, $81, $04, $61, $01, $59, $77, $8B, $FC, $8A, $BB, $74, $56; 16:4F90
    db $53, $14, $67, $55, $9C, $A9, $AD, $DB, $BD, $FF, $83, $BA, $50, $27, $40, $12; 16:4FA0
    db $88, $56, $9E, $C7, $9C, $B9, $46, $87, $42, $37, $54, $38, $A8, $8B, $CD, $BD; 16:4FB0
    db $FF, $F9, $4D, $A3, $01, $62, $01, $27, $83, $7A, $FA, $7B, $DA, $95, $88, $74; 16:4FC0
    db $25, $63, $35, $88, $69, $BB, $BB, $EF, $FF, $87, $F8, $31, $45, $00, $03, $74; 16:4FD0
    db $38, $BD, $8A, $EC, $A8, $89, $75, $24, $63, $14, $78, $68, $BC, $BA, $DF, $FF; 16:4FE0
    db $C6, $DC, $42, $36, $10, $12, $65, $27, $AC, $88, $DC, $B8, $8A, $96, $35, $63; 16:4FF0
    db $23, $77, $56, $AB, $A9, $CE, $FF, $F8, $AE, $63, $25, $20, $10, $56, $25, $AC; 16:5000
    db $99, $DD, $B9, $89, $96, $24, $63, $22, $67, $67, $AB, $BA, $CE, $FF, $F8, $8F; 16:5010
    db $63, $15, $20, $11, $56, $46, $AD, $A9, $CD, $B8, $78, $86, $23, $64, $33, $78; 16:5020
    db $87, $AB, $BA, $BD, $EE, $F6, $9E, $53, $17, $21, $11, $67, $46, $BE, $99, $CD; 16:5030
    db $B7, $67, $84, $13, $54, $24, $88, $98, $BC, $BA, $CE, $EE, $D4, $AC, $41, $17; 16:5040
    db $12, $14, $87, $68, $DE, $99, $BC, $86, $66, $63, $14, $65, $46, $A9, $99, $CB; 16:5050
    db $BA, $DE, $EE, $A3, $D9, $20, $46, $02, $16, $88, $6A, $EC, $8A, $BB, $55, $56; 16:5060
    db $42, $25, $75, $59, $BA, $9A, $CA, $AA, $DD, $DE, $65, $E6, $20, $74, $02, $38; 16:5070
    db $88, $7B, $FB, $79, $B9, $34, $46, $32, $37, $86, $6B, $BA, $8B, $BA, $9A, $CD; 16:5080
    db $EE, $37, $E5, $10, $92, $21, $48, $98, $7C, $FA, $79, $C7, $24, $45, $32, $38; 16:5090
    db $97, $7C, $BA, $8A, $A9, $8A, $CE, $FD, $28, $D5, $00, $A1, $11, $59, $A9, $7C; 16:50A0
    db $F9, $57, $B6, $12, $46, $54, $49, $B8, $6B, $C9, $68, $99, $79, $BE, $FF, $46; 16:50B0
    db $F8, $00, $83, $00, $39, $BB, $7A, $FD, $54, $A8, $11, $25, $66, $58, $DC, $79; 16:50C0
    db $BB, $55, $78, $88, $AD, $FF, $E1, $BE, $50, $07, $11, $05, $BE, $C6, $CF, $B3; 16:50D0
    db $28, $51, $02, $69, $97, $9F, $D7, $69, $94, $45, $8A, $AB, $EF, $FF, $07, $D5; 16:50E0
    db $00, $42, $32, $5C, $FF, $98, $FD, $40, $13, $22, $15, $DF, $C8, $DF, $93, $25; 16:50F0
    db $44, $35, $BE, $DD, $FF, $FF, $00, $84, $00, $25, $97, $8E, $FF, $C2, $9A, $30; 16:5100
    db $01, $48, $68, $FF, $F8, $6A, $61, $00, $38, $87, $BF, $FE, $DF, $FF, $B0, $04; 16:5110
    db $30, $07, $AF, $DB, $DF, $F8, $00, $32, $00, $38, $FF, $CD, $FF, $50, $01, $21; 16:5120
    db $46, $DF, $DA, $BF, $EB, $BD, $EF, $00, $26, $50, $29, $DF, $C9, $7E, $E2, $00; 16:5130
    db $35, $35, $5C, $FF, $A8, $A8, $10, $02, $69, $A9, $EF, $B7, $89, $AB, $DD, $FF; 16:5140
    db $10, $36, $40, $45, $9F, $D8, $6D, $D2, $01, $23, $58, $6A, $FF, $A8, $85, $01; 16:5150
    db $12, $6C, $CA, $CC, $86, $68, $9C, $FE, $FF, $F0, $03, $40, $04, $3D, $FF, $89; 16:5160
    db $EA, $00, $00, $4A, $A7, $EF, $FB, $74, $00, $21, $49, $EE, $CB, $85, $67, $8A; 16:5170
    db $DF, $EF, $FF, $00, $00, $00, $44, $AF, $FC, $78, $81, $00, $02, $BF, $CC, $FE; 16:5180
    db $B8, $00, $02, $67, $BE, $FE, $A6, $35, $89, $BC, $EE, $EF, $FF, $00, $00, $31; 16:5190
    db $76, $FF, $FB, $33, $40, $00, $05, $FF, $EC, $CA, $86, $00, $05, $BD, $EE, $BB; 16:51A0
    db $86, $23, $8A, $CC, $CC, $DE, $FF, $B0, $00, $36, $6A, $8F, $FF, $60, $00, $03; 16:51B0
    db $00, $8F, $FF, $B8, $45, $62, $00, $8D, $FE, $A6, $78, $63, $58, $AC, $DB, $99; 16:51C0
    db $CE, $FF, $E0, $00, $35, $5A, $6A, $FF, $81, $01, $04, $50, $4E, $FF, $CA, $52; 16:51D0
    db $75, $10, $5B, $DE, $C6, $68, $86, $56, $8B, $DA, $77, $AC, $DF, $FF, $F0, $00; 16:51E0
    db $04, $5A, $79, $FF, $B5, $00, $02, $63, $5B, $FF, $FD, $71, $34, $33, $48, $AE; 16:51F0
    db $FA, $65, $55, $67, $77, $BB, $A8, $89, $AD, $ED, $EF, $E0, $00, $04, $8B, $68; 16:5200
    db $FF, $B7, $20, $03, $75, $6B, $DF, $FE, $71, $23, $35, $67, $8C, $FB, $86, $44; 16:5210
    db $67, $67, $AB, $BA, $87, $8A, $BB, $CD, $CE, $F4, $00, $02, $6B, $95, $AF, $EC; 16:5220
    db $72, $00, $65, $57, $8A, $DF, $E7, $54, $23, $66, $56, $BB, $BB, $96, $56, $76; 16:5230
    db $79, $89, $AA, $88, $99, $9B, $BB, $BD, $FC, $00, $00, $27, $A8, $7C, $DD, $EA; 16:5240
    db $50, $02, $24, $76, $9B, $FF, $DB, $72, $23, $55, $57, $89, $CC, $B9, $76, $56; 16:5250
    db $77, $78, $9A, $9A, $97, $89, $AA, $BB, $BC, $84, $32, $24, $68, $75, $88, $99; 16:5260
    db $A8, $66, $66, $77, $77, $67, $78, $89, $88, $88, $78, $88, $87, $77, $78, $88; 16:5270
    db $87, $78, $88, $88, $87, $78, $88, $77, $78, $99, $88, $89, $98, $87, $78, $77; 16:5280
    db $76, $66, $77, $77, $77, $66, $66, $66, $78, $89, $98, $88, $88, $88, $88, $99; 16:5290
    db $99, $88, $88, $77, $77, $77, $87, $77, $77, $77, $88, $88, $88, $87, $88, $88; 16:52A0
    db $88, $88, $88, $88, $77, $88, $77, $87, $77, $77, $67, $77, $77, $77, $77, $77; 16:52B0
    db $77, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $88, $88, $77; 16:52C0
    db $77, $77, $78, $88, $88, $88, $88, $77, $77, $78, $88, $88, $88, $88, $77, $88; 16:52D0
    db $77, $78, $88, $88, $88, $88, $77, $78, $77, $77, $88, $88, $77, $77, $77, $77; 16:52E0
    db $77, $77, $77, $78, $88, $88, $88, $88, $88, $87, $88, $88, $88, $88, $88, $87; 16:52F0
    db $77, $88, $88, $87, $87, $77, $77, $88, $87, $77, $88, $88, $88, $88, $87, $77; 16:5300
    db $77, $88, $88, $88, $88, $88, $87, $77, $77, $78, $88, $88, $88, $88, $78, $78; 16:5310
    db $88, $88, $88, $88, $77, $78, $88, $88, $88, $88, $88, $87, $77, $88, $88, $88; 16:5320
    db $88, $88, $88, $88, $88, $88, $77, $88, $87, $78, $88, $87, $77, $78, $88, $88; 16:5330
    db $88, $87, $77, $77, $77, $88, $88, $88, $77, $77, $78, $88, $88, $88, $87, $77; 16:5340
    db $77, $78, $88, $88, $88, $77, $77, $88, $88, $88, $88, $87, $77, $77, $78, $88; 16:5350
    db $88, $88, $87, $77, $77, $77, $88, $88, $88, $88, $77, $77, $78, $88, $88, $88; 16:5360
    db $88, $87, $77, $77, $77, $88, $88, $88, $87, $77, $77, $77, $88, $88, $88, $88; 16:5370
    db $88, $88, $88, $88, $87, $77, $88, $88, $88, $88, $77, $77, $78, $88, $88, $88; 16:5380
    db $87, $78, $88, $88, $88, $88, $77, $77, $78, $88, $88, $88, $87, $77, $77, $87; 16:5390
    db $88, $88, $88, $88, $87, $77, $87, $88, $88, $88, $88, $87, $88, $88, $88, $87; 16:53A0
    db $77, $77, $88, $88, $88, $88, $87, $77, $78, $88, $88, $88, $88, $77, $77, $78; 16:53B0
    db $88, $88, $88, $88, $78, $88, $88, $87, $77, $77, $88, $88, $88, $88, $87, $77; 16:53C0
    db $78, $88, $88, $88, $88, $77, $77, $77, $78, $88, $88, $88, $88, $88, $78, $88; 16:53D0
    db $88, $88, $88, $88, $87, $88, $88, $88, $88, $87, $78, $88, $88, $88, $88, $88; 16:53E0
    db $77, $77, $78, $88, $88, $88, $88, $77, $88, $87, $88, $88, $88, $87, $78, $88; 16:53F0
    db $88, $88, $87, $77, $77, $88, $88, $88, $88, $88, $77, $87, $78, $88, $88, $88; 16:5400
    db $88, $87, $77, $78, $88, $88, $77, $88, $88, $88, $88, $88, $88, $88, $88, $88; 16:5410

;; PCM31: 3024 bytes = 6048 4-bit samples (rate 2) for SFXInst45
PCM31:
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77; 16:5420
    db $88, $88, $88, $88, $88, $88, $89, $99, $AA, $AA, $AA, $AB, $BB, $BB, $71, $00; 16:5430
    db $02, $45, $57, $89, $EE, $B9, $53, $24, $43, $44, $5A, $DE, $ED, $B8, $88, $65; 16:5440
    db $32, $36, $89, $BA, $9A, $AA, $98, $65, $68, $89, $99, $AB, $CC, $BB, $AB, $CC; 16:5450
    db $B7, $00, $00, $46, $65, $7A, $CF, $E8, $52, $22, $44, $13, $68, $DE, $DA, $77; 16:5460
    db $67, $74, $34, $79, $BB, $99, $AA, $CC, $CB, $CD, $FF, $FF, $10, $00, $03, $31; 16:5470
    db $4B, $EF, $FD, $63, $21, $11, $00, $49, $FF, $FD, $BB, $96, $30, $00, $38, $BD; 16:5480
    db $BB, $DC, $BA, $88, $AE, $EE, $FF, $FC, $10, $00, $02, $22, $6C, $FF, $FB, $52; 16:5490
    db $20, $00, $00, $7D, $FF, $FD, $DC, $83, $00, $01, $79, $BB, $CD, $CB, $88, $AC; 16:54A0
    db $EF, $FF, $FF, $B0, $00, $00, $20, $07, $EF, $FF, $94, $55, $00, $00, $1A, $FE; 16:54B0
    db $FF, $EF, $E7, $00, $00, $46, $68, $DF, $EC, $A9, $BE, $FF, $FF, $FF, $90, $00; 16:54C0
    db $00, $00, $07, $FF, $FE, $97, $98, $00, $00, $29, $B9, $BF, $FF, $D7, $11, $43; 16:54D0
    db $11, $38, $CE, $CB, $CE, $EF, $ED, $FF, $FF, $20, $00, $00, $00, $09, $FE, $BB; 16:54E0
    db $AD, $FB, $10, $01, $44, $32, $7F, $FD, $A9, $9A, $A6, $22, $58, $89, $9B, $EF; 16:54F0
    db $ED, $DE, $FF, $F9, $00, $35, $10, $00, $16, $84, $56, $9C, $BB, $66, $79, $96; 16:5500
    db $65, $77, $87, $67, $8A, $98, $77, $99, $98, $8A, $AB, $A9, $99, $AA, $BC, $B8; 16:5510
    db $89, $98, $64, $12, $22, $11, $22, $56, $76, $78, $8A, $BB, $AA, $AA, $99, $98; 16:5520
    db $87, $77, $77, $78, $88, $99, $98, $88, $89, $89, $9A, $BB, $CB, $99, $98, $75; 16:5530
    db $43, $33, $33, $34, $45, $66, $78, $88, $99, $88, $99, $88, $88, $88, $88, $89; 16:5540
    db $98, $88, $88, $88, $77, $78, $89, $99, $9A, $A9, $98, $77, $87, $66, $55, $55; 16:5550
    db $55, $56, $67, $77, $77, $87, $77, $77, $78, $88, $99, $AA, $A9, $98, $88, $77; 16:5560
    db $77, $77, $77, $88, $88, $88, $88, $88, $88, $77, $77, $66, $77, $78, $88, $88; 16:5570
    db $87, $76, $66, $66, $67, $78, $88, $88, $88, $87, $77, $77, $77, $77, $88, $88; 16:5580
    db $88, $88, $88, $88, $88, $87, $77, $77, $78, $88, $89, $98, $87, $77, $66, $67; 16:5590
    db $78, $88, $88, $88, $88, $77, $77, $77, $77, $77, $77, $77, $78, $88, $88, $87; 16:55A0
    db $87, $77, $77, $78, $88, $99, $98, $88, $88, $77, $77, $77, $88, $88, $88, $88; 16:55B0
    db $87, $77, $77, $77, $78, $88, $88, $88, $88, $87, $87, $77, $77, $77, $77, $88; 16:55C0
    db $88, $88, $88, $87, $77, $77, $67, $78, $88, $88, $88, $88, $77, $77, $77, $78; 16:55D0
    db $88, $88, $88, $78, $78, $88, $78, $87, $77, $77, $87, $78, $88, $88, $87, $88; 16:55E0
    db $87, $87, $87, $88, $88, $88, $88, $77, $77, $77, $77, $87, $87, $88, $88, $87; 16:55F0
    db $87, $77, $77, $77, $77, $88, $88, $89, $89, $79, $78, $68, $88, $78, $88, $88; 16:5600
    db $88, $88, $78, $87, $77, $77, $78, $77, $88, $87, $89, $78, $77, $77, $77, $87; 16:5610
    db $78, $88, $77, $88, $86, $89, $77, $6A, $78, $68, $88, $97, $87, $A6, $87, $87; 16:5620
    db $77, $86, $68, $78, $78, $98, $78, $98, $76, $78, $77, $78, $78, $78, $78, $77; 16:5630
    db $78, $87, $79, $87, $76, $67, $77, $76, $88, $87, $88, $88, $77, $98, $87, $88; 16:5640
    db $98, $78, $88, $77, $88, $78, $88, $77, $99, $88, $88, $88, $88, $88, $88, $87; 16:5650
    db $88, $87, $88, $77, $88, $87, $88, $87, $88, $87, $88, $87, $78, $87, $77, $77; 16:5660
    db $78, $87, $78, $87, $78, $88, $77, $88, $77, $78, $88, $88, $87, $78, $87, $77; 16:5670
    db $77, $78, $87, $78, $88, $88, $88, $87, $77, $77, $77, $77, $77, $77, $87, $77; 16:5680
    db $88, $77, $77, $77, $77, $88, $88, $88, $88, $88, $87, $77, $88, $88, $88, $86; 16:5690
    db $98, $78, $98, $78, $88, $88, $87, $88, $77, $88, $77, $88, $78, $88, $78, $88; 16:56A0
    db $88, $88, $76, $78, $77, $88, $87, $88, $77, $88, $67, $87, $88, $56, $98, $77; 16:56B0
    db $89, $86, $99, $77, $98, $78, $98, $76, $68, $86, $88, $88, $88, $A7, $87, $88; 16:56C0
    db $87, $88, $78, $98, $88, $88, $88, $78, $86, $67, $76, $88, $88, $88, $78, $77; 16:56D0
    db $77, $66, $87, $77, $87, $77, $88, $77, $87, $67, $86, $78, $87, $99, $88, $88; 16:56E0
    db $78, $88, $78, $87, $78, $87, $88, $87, $88, $87, $88, $87, $77, $88, $88, $88; 16:56F0
    db $88, $88, $88, $88, $88, $88, $88, $87, $88, $77, $77, $66, $66, $55, $55, $66; 16:5700
    db $66, $88, $89, $9A, $BA, $BB, $BC, $DD, $98, $B9, $63, $54, $21, $03, $33, $24; 16:5710
    db $78, $77, $9A, $A8, $8A, $98, $7A, $9A, $AC, $EF, $FD, $BD, $F9, $45, $74, $00; 16:5720
    db $01, $10, $14, $87, $58, $CB, $77, $AA, $75, $89, $99, $BF, $FF, $F9, $EF, $E1; 16:5730
    db $18, $40, $00, $01, $00, $49, $C6, $8D, $FB, $47, $99, $33, $59, $98, $CF, $FF; 16:5740
    db $EA, $FF, $A0, $25, $20, $00, $04, $00, $6E, $F8, $AE, $F9, $43, $76, $10, $39; 16:5750
    db $9A, $CF, $FF, $EB, $FF, $80, $00, $10, $00, $07, $45, $7F, $FE, $BC, $F9, $40; 16:5760
    db $12, $20, $07, $CE, $EF, $FF, $FB, $CF, $B0, $00, $00, $00, $06, $BA, $8E, $FF; 16:5770
    db $EA, $98, $40, $00, $02, $35, $AF, $FF, $FF, $FF, $AB, $B3, $00, $00, $00, $01; 16:5780
    db $BF, $ED, $FF, $FD, $95, $20, $00, $00, $47, $8B, $FF, $FF, $FF, $A9, $A8, $00; 16:5790
    db $00, $00, $00, $3C, $FE, $EF, $FF, $C9, $41, $00, $00, $15, $9C, $DD, $FF, $FF; 16:57A0
    db $D6, $8A, $85, $10, $12, $45, $23, $69, $A9, $98, $89, $A8, $55, $66, $77, $67; 16:57B0
    db $89, $99, $BB, $BB, $AA, $A9, $88, $75, $55, $65, $45, $56, $78, $77, $88, $76; 16:57C0
    db $66, $56, $77, $78, $AA, $BD, $DD, $EB, $8A, $A9, $86, $44, $45, $53, $45, $78; 16:57D0
    db $88, $77, $99, $76, $55, $56, $65, $68, $BB, $BB, $EE, $FF, $75, $88, $74, $21; 16:57E0
    db $25, $85, $37, $9A, $BA, $77, $8B, $83, $33, $43, $55, $58, $CD, $CE, $FF, $FF; 16:57F0
    db $71, $58, $40, $00, $06, $95, $5B, $FF, $EB, $77, $87, $00, $00, $36, $76, $BF; 16:5800
    db $FF, $FF, $FF, $60, $01, $00, $00, $08, $DA, $CF, $FF, $FB, $32, $21, $00, $00; 16:5810
    db $8D, $CC, $FF, $FF, $FF, $F0, $00, $00, $00, $04, $EF, $DF, $FF, $FE, $50, $00; 16:5820
    db $00, $00, $5E, $FF, $DF, $FF, $FF, $F1, $00, $10, $00, $04, $FF, $FE, $FF, $FE; 16:5830
    db $50, $00, $00, $00, $4E, $FF, $DB, $FF, $FF, $F3, $00, $25, $00, $02, $EF, $FC; 16:5840
    db $8B, $FD, $50, $00, $05, $40, $2C, $FF, $E9, $AD, $FF, $F6, $00, $18, $20, $00; 16:5850
    db $CF, $FC, $45, $BB, $80, $00, $3C, $C6, $26, $DF, $D8, $6A, $FF, $FA, $00, $1A; 16:5860
    db $87, $10, $8F, $F9, $00, $03, $84, $00, $6E, $FB, $64, $8B, $DA, $9A, $FF, $F8; 16:5870
    db $00, $05, $8D, $63, $8F, $FB, $20, $00, $67, $31, $5B, $DC, $95, $58, $EE, $DE; 16:5880
    db $FF, $D0, $00, $02, $CB, $88, $EF, $B8, $20, $01, $56, $56, $87, $8A, $86, $7B; 16:5890
    db $DE, $FF, $FE, $00, $00, $2A, $A6, $9E, $FB, $82, $00, $38, $78, $77, $56, $75; 16:58A0
    db $56, $BD, $FF, $FF, $F0, $00, $02, $BB, $67, $BE, $A9, $10, $04, $AB, $B8, $63; 16:58B0
    db $35, $45, $7B, $DF, $FF, $FF, $00, $00, $4D, $C7, $79, $BA, $80, $00, $5D, $FE; 16:58C0
    db $95, $22, $55, $68, $AD, $FF, $FF, $C0, $00, $07, $FC, $87, $89, $86, $00, $06; 16:58D0
    db $EF, $F9, $20, $16, $79, $9A, $CF, $FF, $F6, $00, $02, $BF, $B9, $57, $77, $50; 16:58E0
    db $00, $8F, $FF, $70, $00, $89, $CA, $AB, $FF, $FF, $20, $00, $5F, $FB, $83, $65; 16:58F0
    db $72, $00, $0B, $FF, $F4, $00, $18, $BE, $BA, $9E, $FF, $F1, $00, $06, $FF, $B7; 16:5900
    db $04, $57, $20, $00, $CF, $FE, $20, $02, $9D, $FB, $98, $DF, $FF, $10, $00, $7F; 16:5910
    db $FD, $70, $24, $83, $00, $0C, $FF, $E1, $00, $2B, $FF, $B9, $6C, $FF, $F0, $00; 16:5920
    db $07, $FF, $E8, $02, $48, $50, $00, $CF, $FE, $00, $01, $BF, $FC, $95, $AF, $FF; 16:5930
    db $30, $00, $6F, $FF, $90, $14, $77, $00, $0B, $FF, $F1, $00, $0B, $FF, $DB, $67; 16:5940
    db $FF, $FB, $00, $03, $EF, $FB, $00, $45, $92, $00, $6F, $FF, $50, $00, $8E, $FF; 16:5950
    db $A8, $5C, $FF, $F2, $00, $07, $FF, $C6, $02, $47, $60, $02, $DF, $FC, $00, $02; 16:5960
    db $BE, $FC, $A6, $7D, $FF, $F1, $00, $18, $FF, $B4, $03, $37, $51, $25, $FF, $E9; 16:5970
    db $00, $06, $BF, $FB, $95, $8D, $FF, $F2, $00, $19, $FF, $B3, $04, $37, $42, $36; 16:5980
    db $FE, $D8, $00, $06, $AF, $FA, $95, $9D, $FF, $E1, $00, $1A, $FF, $B2, $03, $27; 16:5990
    db $42, $36, $FD, $E8, $00, $06, $AF, $EA, $85, $AE, $FF, $D0, $00, $1B, $FF, $B3; 16:59A0
    db $03, $36, $42, $47, $FE, $D8, $00, $06, $9E, $DA, $86, $9E, $FF, $F1, $00, $09; 16:59B0
    db $FF, $D4, $02, $25, $52, $46, $FE, $D8, $00, $05, $AE, $EA, $86, $9E, $FF, $F3; 16:59C0
    db $00, $06, $FF, $F7, $01, $23, $53, $56, $EF, $B9, $10, $04, $9C, $EB, $96, $8B; 16:59D0
    db $EF, $FA, $00, $02, $FF, $FA, $10, $12, $55, $55, $AF, $BA, $40, $01, $9B, $FB; 16:59E0
    db $96, $6A, $DF, $FF, $30, $00, $8F, $FD, $50, $02, $46, $55, $6E, $DA, $70, $00; 16:59F0
    db $6A, $CD, $88, $58, $BF, $FF, $F0, $00, $2D, $FF, $A1, $02, $36, $54, $48, $FC; 16:5A00
    db $A5, $00, $2A, $AC, $96, $76, $BC, $FF, $FE, $00, $03, $DF, $F9, $10, $34, $63; 16:5A10
    db $23, $9F, $DA, $40, $03, $A8, $B7, $78, $8B, $AF, $FF, $F0, $00, $5C, $FF, $71; 16:5A20
    db $05, $46, $01, $3A, $FE, $93, $01, $4B, $69, $69, $AA, $B8, $FF, $FF, $00, $05; 16:5A30
    db $CF, $F6, $10, $75, $60, $03, $AF, $F9, $21, $24, $A3, $66, $CC, $B9, $6D, $FF; 16:5A40
    db $F1, $00, $2B, $FF, $42, $0B, $76, $00, $1A, $FF, $93, $25, $58, $33, $7D, $EB; 16:5A50
    db $85, $BF, $FF, $80, $00, $AF, $F5, $23, $C9, $50, $00, $8F, $FA, $35, $77, $51; 16:5A60
    db $04, $DF, $A8, $5A, $FF, $FF, $00, $06, $BF, $A2, $6A, $E4, $00, $03, $EE, $B6; 16:5A70
    db $79, $95, $10, $19, $EC, $87, $9F, $FF, $FB, $00, $08, $AC, $54, $8D, $B5, $00; 16:5A80
    db $05, $DC, $A5, $9A, $A4, $20, $39, $BA, $98, $AF, $FF, $FF, $00, $12, $79, $43; 16:5A90
    db $7A, $C7, $10, $03, $99, $A6, $69, $A9, $65, $27, $89, $8A, $8A, $DF, $FF, $D3; 16:5AA0
    db $68, $78, $84, $44, $32, $76, $21, $46, $79, $77, $55, $57, $76, $65, $79, $AA; 16:5AB0
    db $CE, $FF, $FD, $CB, $88, $B7, $12, $10, $14, $00, $14, $58, $86, $55, $67, $87; 16:5AC0
    db $76, $89, $CB, $BC, $DF, $FF, $EE, $C8, $7A, $70, $00, $01, $51, $01, $45, $88; 16:5AD0
    db $54, $57, $89, $78, $67, $9B, $AA, $AB, $DF, $FF, $FE, $B5, $59, $93, $10, $00; 16:5AE0
    db $65, $32, $00, $4A, $A8, $65, $48, $AB, $96, $67, $9B, $DC, $DD, $FF, $FF, $FD; 16:5AF0
    db $75, $76, $23, $10, $02, $11, $44, $24, $67, $89, $97, $88, $88, $89, $99, $A9; 16:5B00
    db $9A, $CF, $FF, $FF, $FB, $56, $85, $12, $00, $02, $01, $44, $46, $75, $79, $98; 16:5B10
    db $A9, $88, $87, $78, $99, $AB, $CD, $FF, $FF, $FE, $85, $67, $21, $10, $01, $20; 16:5B20
    db $13, $34, $87, $7A, $B9, $88, $77, $88, $77, $88, $89, $AB, $CE, $FF, $FD, $DD; 16:5B30
    db $B8, $86, $33, $00, $00, $00, $23, $45, $55, $78, $9B, $B9, $98, $88, $88, $88; 16:5B40
    db $79, $9B, $DE, $FF, $FF, $CE, $C9, $78, $74, $20, $00, $00, $11, $44, $55, $58; 16:5B50
    db $99, $AB, $88, $79, $89, $9A, $88, $99, $9A, $CD, $FF, $FF, $BE, $C8, $79, $73; 16:5B60
    db $12, $00, $00, $00, $44, $44, $77, $8A, $CB, $AA, $88, $8A, $A9, $88, $76, $89; 16:5B70
    db $AB, $DD, $FF, $FE, $CB, $86, $58, $51, $01, $00, $00, $13, $65, $56, $87, $BC; 16:5B80
    db $CB, $B9, $87, $99, $88, $76, $56, $78, $8B, $BB, $DE, $FF, $FE, $D9, $64, $56; 16:5B90
    db $32, $10, $00, $02, $37, $76, $68, $79, $DD, $DB, $B8, $77, $86, $76, $55, $56; 16:5BA0
    db $67, $9A, $9B, $BD, $FF, $FF, $FD, $B6, $32, $44, $10, $00, $00, $15, $7A, $76; 16:5BB0
    db $89, $9D, $EC, $B9, $85, $67, $76, $74, $44, $57, $8A, $A9, $AB, $DF, $FF, $FF; 16:5BC0
    db $FF, $DA, $60, $00, $00, $00, $00, $04, $7A, $DD, $9A, $A9, $AC, $A8, $66, $45; 16:5BD0
    db $88, $77, $65, $67, $98, $A8, $89, $AB, $EF, $FF, $FF, $FF, $F8, $50, $00, $00; 16:5BE0
    db $00, $00, $08, $BE, $FE, $97, $AA, $9C, $73, $23, $57, $BB, $66, $53, $79, $A8; 16:5BF0
    db $66, $48, $BC, $DD, $CD, $EF, $FF, $FF, $E4, $30, $00, $00, $00, $00, $8D, $CE; 16:5C00
    db $CA, $79, $A6, $55, $02, $58, $9B, $C8, $89, $98, $A7, $43, $55, $7A, $99, $AC; 16:5C10
    db $DF, $FF, $FF, $FF, $FF, $20, $00, $00, $00, $00, $09, $FE, $EB, $A6, $CE, $87; 16:5C20
    db $40, $28, $B9, $BA, $59, $AB, $87, $40, $36, $68, $87, $8B, $FE, $FF, $EF, $FF; 16:5C30
    db $FF, $FC, $00, $00, $00, $00, $00, $3E, $FF, $EF, $DB, $FA, $43, $10, $15, $42; 16:5C40
    db $87, $9D, $DB, $79, $65, $85, $43, $56, $8D, $CC, $ED, $FF, $FF, $FF, $FF, $F1; 16:5C50
    db $00, $00, $00, $00, $01, $BE, $FC, $EF, $CF, $D6, $31, $10, $22, $05, $8A, $CD; 16:5C60
    db $DB, $EB, $98, $53, $24, $45, $88, $AD, $EF, $EF, $EE, $EC, $DD, $FF, $62, $00; 16:5C70
    db $00, $00, $00, $07, $9B, $AC, $FC, $DC, $86, $45, $23, $42, $46, $78, $AB, $9A; 16:5C80
    db $A9, $98, $87, $88, $89, $AA, $AA, $A9, $98, $87, $78, $88, $99, $BB, $CB, $99; 16:5C90
    db $77, $76, $64, $53, $33, $33, $22, $33, $55, $56, $77, $78, $99, $99, $AA, $AA; 16:5CA0
    db $AA, $AA, $BA, $A9, $98, $77, $66, $66, $67, $88, $89, $9A, $AA, $AA, $A9, $A9; 16:5CB0
    db $88, $88, $88, $87, $76, $54, $43, $22, $22, $34, $45, $56, $67, $88, $99, $AA; 16:5CC0
    db $AB, $AA, $AA, $AA, $A9, $99, $88, $88, $88, $87, $77, $88, $88, $77, $78, $88; 16:5CD0
    db $89, $99, $9A, $99, $88, $88, $77, $66, $55, $54, $44, $44, $44, $44, $55, $66; 16:5CE0
    db $77, $89, $9A, $AB, $BB, $BB, $BA, $AA, $A9, $98, $87, $77, $77, $77, $77, $77; 16:5CF0
    db $78, $88, $88, $88, $88, $99, $99, $99, $98, $88, $88, $77, $65, $55, $54, $44; 16:5D00
    db $45, $55, $56, $67, $78, $88, $99, $99, $99, $AA, $AA, $A9, $99, $98, $88, $77; 16:5D10
    db $77, $77, $77, $76, $77, $77, $88, $88, $9A, $AA, $9A, $AA, $AA, $AB, $CB, $77; 16:5D20
    db $77, $64, $30, $13, $12, $13, $57, $96, $89, $AA, $AA, $89, $A9, $88, $88, $99; 16:5D30
    db $77, $88, $78, $87, $87, $77, $77, $67, $77, $99, $99, $BA, $AB, $BB, $BB, $BB; 16:5D40
    db $BB, $CE, $FF, $C0, $24, $10, $00, $00, $20, $13, $BB, $FD, $8E, $EC, $76, $42; 16:5D50
    db $73, $02, $69, $8C, $AC, $FF, $DA, $BA, $88, $32, $46, $43, $66, $AC, $A9, $BE; 16:5D60
    db $A9, $87, $99, $87, $9C, $BD, $DE, $FF, $FF, $F5, $03, $00, $00, $00, $40, $28; 16:5D70
    db $EF, $FF, $BD, $F8, $30, $10, $03, $04, $AD, $DF, $FF, $FF, $C9, $77, $21, $00; 16:5D80
    db $35, $56, $AE, $CF, $DB, $CA, $85, $66, $58, $89, $BD, $EE, $FF, $FF, $EC, $CF; 16:5D90
    db $90, $00, $00, $00, $05, $92, $CE, $FF, $FC, $5B, $60, $00, $00, $45, $5F, $FF; 16:5DA0
    db $FF, $FF, $F9, $44, $21, $02, $25, $A9, $BD, $ED, $BB, $77, $74, $45, $77, $8A; 16:5DB0
    db $AC, $DC, $CB, $CB, $AA, $AA, $9A, $A9, $DF, $20, $40, $00, $00, $0A, $23, $AD; 16:5DC0
    db $EB, $D6, $7B, $40, $14, $34, $96, $AF, $FE, $FF, $CB, $B5, $35, $30, $26, $58; 16:5DD0
    db $BB, $CE, $EA, $AA, $75, $54, $46, $76, $8B, $BB, $CC, $BC, $C9, $99, $98, $89; 16:5DE0
    db $89, $BE, $F3, $06, $00, $00, $00, $80, $29, $BE, $BC, $99, $D6, $23, $55, $47; 16:5DF0
    db $68, $ED, $BC, $ED, $AA, $65, $65, $43, $68, $8B, $AB, $CC, $A8, $97, $55, $44; 16:5E00
    db $57, $78, $AA, $BB, $AA, $AA, $88, $88, $89, $99, $BB, $AC, $FF, $20, $50, $00; 16:5E10
    db $00, $0B, $34, $CF, $FD, $D8, $7C, $30, $03, $32, $76, $AF, $FD, $EF, $EA, $95; 16:5E20
    db $35, $31, $26, $78, $BB, $DE, $EB, $AA, $75, $42, $23, $55, $7A, $AB, $CC, $BB; 16:5E30
    db $A8, $78, $77, $78, $89, $BA, $BC, $BA, $DE, $40, $31, $00, $00, $0A, $54, $CF; 16:5E40
    db $FC, $C9, $7B, $50, $14, $43, $66, $9F, $EC, $DF, $DA, $95, $56, $52, $36, $78; 16:5E50
    db $AA, $BD, $DA, $89, $75, $54, $35, $65, $7A, $AA, $BB, $AA, $98, $77, $76, $68; 16:5E60
    db $88, $99, $9A, $A8, $89, $9B, $50, $42, $20, $01, $39, $55, $AC, $DA, $A9, $AB; 16:5E70
    db $64, $47, $64, $55, $9B, $A9, $BE, $CA, $98, $88, $63, $57, $77, $78, $AB, $A9; 16:5E80
    db $AA, $98, $76, $66, $55, $67, $78, $88, $9A, $98, $88, $87, $77, $77, $77, $88; 16:5E90
    db $88, $89, $99, $99, $88, $76, $55, $54, $44, $56, $77, $89, $99, $99, $98, $87; 16:5EA0
    db $66, $66, $66, $78, $88, $9A, $AA, $99, $99, $87, $77, $77, $77, $78, $88, $88; 16:5EB0
    db $88, $88, $87, $77, $66, $67, $77, $77, $88, $88, $88, $88, $87, $78, $87, $88; 16:5EC0
    db $88, $98, $88, $88, $88, $77, $77, $67, $77, $77, $77, $88, $78, $88, $88, $88; 16:5ED0
    db $88, $78, $88, $77, $77, $77, $77, $77, $87, $77, $77, $77, $77, $77, $88, $88; 16:5EE0
    db $88, $98, $98, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $76, $66; 16:5EF0
    db $77, $77, $88, $88, $88, $88, $87, $77, $77, $77, $88, $88, $88, $88, $88, $87; 16:5F00
    db $77, $77, $77, $77, $88, $88, $88, $88, $77, $77, $77, $77, $88, $88, $88, $88; 16:5F10
    db $88, $88, $88, $77, $77, $77, $77, $78, $88, $88, $88, $88, $77, $77, $77, $77; 16:5F20
    db $77, $88, $88, $88, $88, $88, $88, $77, $77, $77, $88, $88, $88, $88, $87, $77; 16:5F30
    db $77, $77, $78, $88, $88, $88, $88, $77, $77, $77, $78, $88, $88, $88, $88, $88; 16:5F40
    db $87, $77, $77, $77, $77, $78, $88, $88, $88, $77, $77, $78, $88, $88, $88, $88; 16:5F50
    db $88, $88, $88, $87, $77, $78, $88, $88, $87, $77, $77, $77, $77, $78, $88, $88; 16:5F60
    db $88, $88, $88, $88, $77, $78, $77, $77, $78, $77, $78, $88, $87, $88, $88, $88; 16:5F70
    db $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $77, $77; 16:5F80
    db $77, $77, $88, $78, $88, $88, $87, $77, $77, $77, $78, $88, $88, $88, $88, $88; 16:5F90
    db $88, $78, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 16:5FA0
    db $88, $88, $88, $87, $77, $77, $77, $77, $88, $88, $88, $88, $87, $77, $77, $77; 16:5FB0
    db $88, $88, $88, $88, $88, $88, $88, $87, $77, $77, $78, $88, $88, $88, $77, $77; 16:5FC0
    db $77, $77, $77, $77, $78, $88, $88, $88, $88, $77, $77, $77, $88, $88, $88, $88; 16:5FD0
    db $88, $88, $77, $77, $77, $78, $88, $88, $88, $88, $88, $88, $88, $78, $88, $88; 16:5FE0
