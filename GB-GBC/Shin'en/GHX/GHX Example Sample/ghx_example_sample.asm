; ============================================================================
; GHX Example Sample (PD) [C].gbc  -  bank 1 (file offset $4000-$7FFF)
; "GHX Audio Engine (c) 1999 Martin Wodok." / "(C) ML/SHINEN in 1999"
; The oldest known GHX build: one song with the PCM samples stored in the same
; bank and played by the engine itself through the timer interrupt.
;
; Disassembly with all song data as labelled source. Assemble with RGBDS:
;   rgbasm -o ex.o ghx_example_sample.asm ; rgblink -o ex.gb ex.o
; and bank 1 of ex.gb is byte-identical to the original ROM.
; ============================================================================

INCLUDE "ghx_hw.inc"
INCLUDE "ghx_macros.inc"

; ---- RAM (channel blocks of $40 bytes at $DE00/$DE40/$DE80/$DEC0) --------
DEF wCh1_SFXTimer          EQU $DE00
DEF wCh1_Transpose         EQU $DE01
DEF wCh1_TrackPtrLo        EQU $DE02
DEF wCh1_TrackPtrHi        EQU $DE03
DEF wCh1_TrackNum          EQU $DE04
DEF wCh1_Note              EQU $DE05
DEF wCh1_VolShift          EQU $DE06
DEF wCh1_InsFlags          EQU $DE07
DEF wCh1_VibDelay          EQU $DE08
DEF wCh1_VibDepth          EQU $DE09
DEF wCh1_VibSpeed          EQU $DE0A
DEF wCh1_VibPhase          EQU $DE0B
DEF wCh1_PLNoteRaw         EQU $DE0E
DEF wCh1_PLNote            EQU $DE0F
DEF wCh1_PLPtrLo           EQU $DE10
DEF wCh1_PLPtrHi           EQU $DE11
DEF wCh1_PLSpeed           EQU $DE12
DEF wCh1_PLTimer           EQU $DE13
DEF wCh1_PLSteps           EQU $DE14
DEF wCh1_RowNote           EQU $DE15
DEF wCh1_RowIns            EQU $DE16
DEF wCh1_RowFx             EQU $DE17
DEF wCh2_SFXTimer          EQU $DE40
DEF wCh2_Transpose         EQU $DE41
DEF wCh2_TrackPtrLo        EQU $DE42
DEF wCh2_TrackPtrHi        EQU $DE43
DEF wCh2_TrackNum          EQU $DE44
DEF wCh2_Note              EQU $DE45
DEF wCh2_VolShift          EQU $DE46
DEF wCh2_InsFlags          EQU $DE47
DEF wCh2_VibDelay          EQU $DE48
DEF wCh2_VibDepth          EQU $DE49
DEF wCh2_VibSpeed          EQU $DE4A
DEF wCh2_VibPhase          EQU $DE4B
DEF wCh2_PLNoteRaw         EQU $DE4E
DEF wCh2_PLNote            EQU $DE4F
DEF wCh2_PLPtrLo           EQU $DE50
DEF wCh2_PLPtrHi           EQU $DE51
DEF wCh2_PLSpeed           EQU $DE52
DEF wCh2_PLTimer           EQU $DE53
DEF wCh2_PLSteps           EQU $DE54
DEF wCh2_RowNote           EQU $DE55
DEF wCh2_RowIns            EQU $DE56
DEF wCh2_RowFx             EQU $DE57
DEF wCh3_SFXTimer          EQU $DE80
DEF wCh3_Transpose         EQU $DE81
DEF wCh3_TrackPtrLo        EQU $DE82
DEF wCh3_TrackPtrHi        EQU $DE83
DEF wCh3_TrackNum          EQU $DE84
DEF wCh3_Note              EQU $DE85
DEF wCh3_VolShift          EQU $DE86
DEF wCh3_InsFlags          EQU $DE87
DEF wCh3_VibDelay          EQU $DE88
DEF wCh3_VibDepth          EQU $DE89
DEF wCh3_VibSpeed          EQU $DE8A
DEF wCh3_VibPhase          EQU $DE8B
DEF wCh3_PLNoteRaw         EQU $DE8E
DEF wCh3_PLNote            EQU $DE8F
DEF wCh3_PLPtrLo           EQU $DE90
DEF wCh3_PLPtrHi           EQU $DE91
DEF wCh3_PLSpeed           EQU $DE92
DEF wCh3_PLTimer           EQU $DE93
DEF wCh3_PLSteps           EQU $DE94
DEF wCh3_RowNote           EQU $DE95
DEF wCh3_RowIns            EQU $DE96
DEF wCh3_RowFx             EQU $DE97
DEF wPCM_Active            EQU $DEB0
DEF wWave_SweepTimer       EQU $DEB1
DEF wWave_SweepOn          EQU $DEB2
DEF wWave_Update           EQU $DEB3
DEF wWave_BaseHi           EQU $DEB4
DEF wWave_BaseLo           EQU $DEB5
DEF wWave_SweepSpeed       EQU $DEB6
DEF wWave_UpperLo          EQU $DEB7
DEF wWave_UpperHi          EQU $DEB8
DEF wWave_LowerLo          EQU $DEB9
DEF wWave_LowerHi          EQU $DEBA
DEF wWave_PosLo            EQU $DEBB
DEF wWave_PosHi            EQU $DEBC
DEF wWave_Unused           EQU $DEBD
DEF wWave_Flag             EQU $DEBE
DEF wWave_Step             EQU $DEBF
DEF wCh4_SFXTimer          EQU $DEC0
DEF wCh4_Transpose         EQU $DEC1
DEF wCh4_TrackPtrLo        EQU $DEC2
DEF wCh4_TrackPtrHi        EQU $DEC3
DEF wCh4_TrackNum          EQU $DEC4
DEF wCh4_Note              EQU $DEC5
DEF wCh4_VolShift          EQU $DEC6
DEF wCh4_InsFlags          EQU $DEC7
DEF wCh4_VibDelay          EQU $DEC8
DEF wCh4_VibDepth          EQU $DEC9
DEF wCh4_VibSpeed          EQU $DECA
DEF wCh4_VibPhase          EQU $DECB
DEF wCh4_PLNoteRaw         EQU $DECE
DEF wCh4_PLNote            EQU $DECF
DEF wCh4_PLPtrLo           EQU $DED0
DEF wCh4_PLPtrHi           EQU $DED1
DEF wCh4_PLSpeed           EQU $DED2
DEF wCh4_PLTimer           EQU $DED3
DEF wCh4_PLSteps           EQU $DED4
DEF wCh4_RowNote           EQU $DED5
DEF wCh4_RowIns            EQU $DED6
DEF wCh4_RowFx             EQU $DED7
DEF wSubsong               EQU $DF00
DEF wOrderSel              EQU $DF01
DEF wEnabled               EQU $DF02
DEF wSpeed                 EQU $DF03
DEF wTickCount             EQU $DF04
DEF wRowsLeft              EQU $DF05
DEF wPosLeft               EQU $DF06
DEF wPosPtrLo              EQU $DF07
DEF wPosPtrHi              EQU $DF08
DEF wSFX_Ch1               EQU $DF0B
DEF wSFX_Ch2               EQU $DF0C
DEF wSFX_Ch3               EQU $DF0D
DEF wSFX_Ch4               EQU $DF0E
DEF wSFX_Time              EQU $DF0F
DEF wHdr_Magic             EQU $DF11
DEF wHdr_Subsongs          EQU $DF14
DEF wHdr_PatLen            EQU $DF15
DEF wHdr_Unused            EQU $DF16
DEF wHdr_TracksLo          EQU $DF17
DEF wHdr_TracksHi          EQU $DF18
DEF wHdr_InstsLo           EQU $DF19
DEF wHdr_InstsHi           EQU $DF1A
DEF wHdr_OrdersLo          EQU $DF1B
DEF wHdr_OrdersHi          EQU $DF1C

SECTION "GHX Engine + Song Data", ROMX[$4000], BANK[1]

;; =====================================================================
;; GHX Audio Engine (c) 1999 Martin Wodok - "GHX Example Sample" build
;; =====================================================================
;; Public jump table (bank 1). The demo program in bank 0 (GBDK C) calls:
;;   $04FA: xor a / ld c,0 / jp GHX_Init   - start song 0, subsong 0
;;   $0500: jp GHX_Play                    - once per frame (main loop)
;;   $0503: jp GHX_TimerISR                - installed as the timer handler
;;   $0506: ld a,[sp+2] / jp GHX_PlaySFX   - sound effect A
;; Note: no bank switching anywhere - engine and data share this bank.
GHX_Init:
    jp InitSong                 ; 4000  A = subsong, C = song number (index into SongTable)
GHX_Play:
    jp PlayFrame                ; 4003  call once per frame
GHX_Stop:
    jp StopSound                ; 4006  silence + disable (NR52 = 0)
GHX_SoundOn:
    jp SoundOnImpl              ; 4009  re-enable sound hardware, keep song position
GHX_TimerISR:
    jp TimerISR                 ; 400C  timer interrupt: streams PCM into wave RAM
GHX_PlaySFX:
    jp PlaySFX                  ; 400F  A = sound effect number

;; Copyright string (never executed)
    db "GHX Audio Engine (c) 1999 Martin Wodok. All rights reserved."  ; 4012

;; GHX_Init: A = subsong, C = song.
;; Copies the 12-byte song header to wHdr_*, resets the sequencer and the
;; 256 bytes of channel RAM ($DE00-$DEFF) and switches the APU on.
InitSong:
    ld [wSubsong], a            ; 404E
    ld b, $00                   ; 4051
    ld hl, SongTable            ; 4053
    add hl, bc                  ; 4056
    add hl, bc                  ; 4057
    ld a, [hl+]                 ; 4058
    ld e, a                     ; 4059
    ld a, [hl+]                 ; 405A
    ld h, a                     ; 405B
    ld l, e                     ; 405C
    ld de, wHdr_Magic           ; 405D
    ld c, $0C                   ; 4060
.L4062:
    ld a, [hl+]                 ; 4062
    ld [de], a                  ; 4063
    inc de                      ; 4064
    dec c                       ; 4065
    jr nz, .L4062               ; 4066
    ld a, $06                   ; 4068
    ld [wSpeed], a              ; 406A
    xor a                       ; 406D
    ld [wRowsLeft], a           ; 406E
    ld [wPosLeft], a            ; 4071
    ld [wTickCount], a          ; 4074
    ld [wOrderSel], a           ; 4077
    ld hl, wCh1_SFXTimer        ; 407A
    ld c, $00                   ; 407D
    xor a                       ; 407F
.L4080:
    ld [hl+], a                 ; 4080
    dec c                       ; 4081
    jr nz, .L4080               ; 4082
    ld a, $80                   ; 4084
    ldh [rNR52], a              ; 4086
    ld a, $77                   ; 4088
    ldh [rNR50], a              ; 408A
    ld a, $FF                   ; 408C
    ldh [rNR51], a              ; 408E
    ld [wEnabled], a            ; 4090
    xor a                       ; 4093
    ldh [rNR10], a              ; 4094
    ldh [rNR12], a              ; 4096
    ldh [rNR22], a              ; 4098
    ldh [rNR32], a              ; 409A
    ldh [rNR42], a              ; 409C
    ret                         ; 409E

;; GHX_SoundOn: APU on, master volume max, all channels to both outputs.
SoundOnImpl:
    ld a, $80                   ; 409F
    ldh [rNR52], a              ; 40A1
    ld a, $77                   ; 40A3
    ldh [rNR50], a              ; 40A5
    ld a, $FF                   ; 40A7
    ldh [rNR51], a              ; 40A9
    ld [wEnabled], a            ; 40AB
    xor a                       ; 40AE
    ldh [rNR10], a              ; 40AF
    ldh [rNR12], a              ; 40B1
    ldh [rNR22], a              ; 40B3
    ldh [rNR32], a              ; 40B5
    ldh [rNR42], a              ; 40B7
    ret                         ; 40B9

;; GHX_Stop: disable the player and the APU.
StopSound:
    xor a                       ; 40BA
    ld [wEnabled], a            ; 40BB
    ldh [rNR52], a              ; 40BE
    ret                         ; 40C0

;; GHX_Play - called once per frame.
;; wTickCount counts down the ticks of a row (wSpeed ticks per row). On a new
;; row: if the pattern is finished (wRowsLeft = 0) the next position is read;
;; when the position list of the current order entry runs out, order entry
;; 2*subsong+1 (the loop part) is (re)started. wOrderSel is 0 for the first
;; pass (intro, entry 2*subsong) and stays 1 afterwards.
PlayFrame:
    ld a, [wEnabled]            ; 40C1
    or a                        ; 40C4
    jp z, Play_Return           ; 40C5
    ld a, [wTickCount]          ; 40C8
    or a                        ; 40CB
    jp nz, Tick                 ; 40CC
    ld a, [wRowsLeft]           ; 40CF
    or a                        ; 40D2
    jp nz, Row_Ch1              ; 40D3
    ld a, [wHdr_PatLen]         ; 40D6
    ld [wRowsLeft], a           ; 40D9
    ld a, [wPosLeft]            ; 40DC
    or a                        ; 40DF
    jp nz, Play_NextPosition    ; 40E0
    ld a, [wHdr_OrdersLo]       ; 40E3
    ld l, a                     ; 40E6
    ld a, [wHdr_OrdersHi]       ; 40E7
    ld h, a                     ; 40EA
    ld a, [wOrderSel]           ; 40EB
    ld c, a                     ; 40EE
    or $01                      ; 40EF
    ld [wOrderSel], a           ; 40F1
    ld a, [wSubsong]            ; 40F4
    add a,a                     ; 40F7
    add a,c                     ; 40F8
    ld c, a                     ; 40F9
    ld b, $00                   ; 40FA
    add hl, bc                  ; 40FC
    add hl, bc                  ; 40FD
    add hl, bc                  ; 40FE
    ld a, [hl+]                 ; 40FF
    ld [wPosLeft], a            ; 4100
    ld a, [hl+]                 ; 4103
    ld c, a                     ; 4104
    ld a, [hl+]                 ; 4105
    ld h, a                     ; 4106
    ld l, c                     ; 4107
    jr Play_ReadPosition        ; 4108
Play_NextPosition:
    ld a, [wPosPtrLo]           ; 410A
    ld l, a                     ; 410D
    ld a, [wPosPtrHi]           ; 410E
    ld h, a                     ; 4111
    ld a, [wPosLeft]            ; 4112
    dec a                       ; 4115
    ld [wPosLeft], a            ; 4116

;; Position = 7 bytes: track ch1, transpose ch1, track ch2, transpose ch2,
;; track ch3, transpose ch3, track ch4 (ch4 has no transpose). Track numbers
;; index the song's track pointer table.
Play_ReadPosition:
    ld a, [hl+]                 ; 4119
    ld [wCh1_TrackNum], a       ; 411A
    ld a, [hl+]                 ; 411D
    ld [wCh1_Transpose], a      ; 411E
    ld a, [hl+]                 ; 4121
    ld [wCh2_TrackNum], a       ; 4122
    ld a, [hl+]                 ; 4125
    ld [wCh2_Transpose], a      ; 4126
    ld a, [hl+]                 ; 4129
    ld [wCh3_TrackNum], a       ; 412A
    ld a, [hl+]                 ; 412D
    ld [wCh3_Transpose], a      ; 412E
    ld a, [hl+]                 ; 4131
    ld [wCh4_TrackNum], a       ; 4132
    ld a, l                     ; 4135
    ld [wPosPtrLo], a           ; 4136
    ld a, h                     ; 4139
    ld [wPosPtrHi], a           ; 413A
    ld a, [wHdr_TracksLo]       ; 413D
    ld l, a                     ; 4140
    ld a, [wHdr_TracksHi]       ; 4141
    ld h, a                     ; 4144
    push hl                     ; 4145
    ld a, [wCh1_TrackNum]       ; 4146
    ld c, a                     ; 4149
    ld b, $00                   ; 414A
    add hl, bc                  ; 414C
    add hl, bc                  ; 414D
    ld a, [hl+]                 ; 414E
    ld [wCh1_TrackPtrLo], a     ; 414F
    ld a, [hl+]                 ; 4152
    ld [wCh1_TrackPtrHi], a     ; 4153
    pop hl                      ; 4156
    push hl                     ; 4157
    ld a, [wCh2_TrackNum]       ; 4158
    ld c, a                     ; 415B
    ld b, $00                   ; 415C
    add hl, bc                  ; 415E
    add hl, bc                  ; 415F
    ld a, [hl+]                 ; 4160
    ld [wCh2_TrackPtrLo], a     ; 4161
    ld a, [hl+]                 ; 4164
    ld [wCh2_TrackPtrHi], a     ; 4165
    pop hl                      ; 4168
    push hl                     ; 4169
    ld a, [wCh3_TrackNum]       ; 416A
    ld c, a                     ; 416D
    ld b, $00                   ; 416E
    add hl, bc                  ; 4170
    add hl, bc                  ; 4171
    ld a, [hl+]                 ; 4172
    ld [wCh3_TrackPtrLo], a     ; 4173
    ld a, [hl+]                 ; 4176
    ld [wCh3_TrackPtrHi], a     ; 4177
    pop hl                      ; 417A
    ld a, [wCh4_TrackNum]       ; 417B
    ld c, a                     ; 417E
    ld b, $00                   ; 417F
    add hl, bc                  ; 4181
    add hl, bc                  ; 4182
    ld a, [hl+]                 ; 4183
    ld [wCh4_TrackPtrLo], a     ; 4184
    ld a, [hl+]                 ; 4187
    ld [wCh4_TrackPtrHi], a     ; 4188

;; New row, channel 1. Row = [note|$40 ins follows|$80 fx follows] [ins] [fx].
;; Effect $Fx sets the speed (ticks per row) - checked on all channels even while
;; a sound effect owns the channel; nothing else is decoded from the fx byte.
Row_Ch1:
    ld hl, wRowsLeft            ; 418B
    dec [hl]                    ; 418E
    ld a, [wCh1_TrackPtrLo]     ; 418F
    ld l, a                     ; 4192
    ld a, [wCh1_TrackPtrHi]     ; 4193
    ld h, a                     ; 4196
    ld a, [hl+]                 ; 4197
    ld [wCh1_RowNote], a        ; 4198
    ld e, a                     ; 419B
    bit 6, e                    ; 419C
    jr z, .L41A4                ; 419E
    ld a, [hl+]                 ; 41A0
    ld [wCh1_RowIns], a         ; 41A1
.L41A4:
    bit 7, e                    ; 41A4
    jr z, .L41AC                ; 41A6
    ld a, [hl+]                 ; 41A8
    ld [wCh1_RowFx], a          ; 41A9
.L41AC:
    ld a, l                     ; 41AC
    ld [wCh1_TrackPtrLo], a     ; 41AD
    ld a, h                     ; 41B0
    ld [wCh1_TrackPtrHi], a     ; 41B1
    bit 7, e                    ; 41B4
    jr z, Row_Ch1_Decode        ; 41B6
    ld a, [wCh1_RowFx]          ; 41B8
    ld b, a                     ; 41BB
    swap b                      ; 41BC
    and $0F                     ; 41BE
    sub $0F                     ; 41C0
    jr nz, Row_Ch1_Decode       ; 41C2
    ld a, b                     ; 41C4
    and $0F                     ; 41C5
    ld [wSpeed], a              ; 41C7

;; Music is muted on this channel while wCh1_SFXTimer <> 0 (SFX playing).
Row_Ch1_Decode:
    ld a, [wCh1_SFXTimer]       ; 41CA
    or a                        ; 41CD
    jp nz, Row_Ch2              ; 41CE
    ld a, e                     ; 41D1
    and $3F                     ; 41D2
    jr z, .L41D9                ; 41D4
    ld [wCh1_Note], a           ; 41D6
.L41D9:
    ld a, [wCh1_RowNote]        ; 41D9
    bit 6, a                    ; 41DC
    jp z, Row_Ch2               ; 41DE

;; Instrument byte: bits 0-5 = instrument+1 (0 = only change the volume),
;; bits 6-7 = volume shift (envelope volume >> 0/1/2/4: full, 1/2, 1/4, off);
;; on ch3 they select the NR32 level instead (1 = 25%, 2 = 50%, 3 = 100%).
    ld a, [wCh1_RowIns]         ; 41E1
    and $3F                     ; 41E4
    jp nz, Row_Ch1_LoadIns      ; 41E6
    ld a, [wCh1_RowIns]         ; 41E9
    and $C0                     ; 41EC
    jr z, .L4216                ; 41EE
    rlc a                       ; 41F0
    rlc a                       ; 41F2
    ld [wCh1_VolShift], a       ; 41F4
    ld c, a                     ; 41F7
    ldh a, [rNR12]              ; 41F8
    and $0F                     ; 41FA
    ld b, a                     ; 41FC
    ldh a, [rNR12]              ; 41FD
    inc c                       ; 41FF
    dec c                       ; 4200
    jr z, .L4211                ; 4201
    dec c                       ; 4203
    jr z, .L420F                ; 4204
    dec c                       ; 4206
    jr z, .L420D                ; 4207
    srl a                       ; 4209
    srl a                       ; 420B
.L420D:
    srl a                       ; 420D
.L420F:
    srl a                       ; 420F
.L4211:
    and $F0                     ; 4211
    or b                        ; 4213
    ldh [rNR12], a              ; 4214
.L4216:
    jp Row_Ch1_Trigger          ; 4216

;; Load square instrument: [flags: bit5 vibrato, bits0-4 steps] [playlist speed]
;; [NRx2 envelope] ([vibrato delay] [vibrato depth<<4 | speed]) then 3-byte steps.
Row_Ch1_LoadIns:
    dec a                       ; 4219
    ld c, a                     ; 421A
    xor a                       ; 421B
    ld [wCh1_VolShift], a       ; 421C
    ld a, [wCh1_RowIns]         ; 421F
    and $C0                     ; 4222
    jr z, .L422D                ; 4224
    rlc a                       ; 4226
    rlc a                       ; 4228
    ld [wCh1_VolShift], a       ; 422A
.L422D:
    ld a, [wHdr_InstsLo]        ; 422D
    ld l, a                     ; 4230
    ld a, [wHdr_InstsHi]        ; 4231
    ld h, a                     ; 4234
    ld b, $00                   ; 4235
    add hl, bc                  ; 4237
    add hl, bc                  ; 4238
    ld a, [hl+]                 ; 4239
    ld c, a                     ; 423A
    ld a, [hl+]                 ; 423B
    ld h, a                     ; 423C
    ld l, c                     ; 423D
    ld a, [hl+]                 ; 423E
    ld [wCh1_InsFlags], a       ; 423F
    ld d, a                     ; 4242
    ld a, [hl+]                 ; 4243
    ld [wCh1_PLSpeed], a        ; 4244
    xor a                       ; 4247
    ld [wCh1_PLTimer], a        ; 4248
    ld a, $80                   ; 424B
    ldh [rNR11], a              ; 424D
    ld a, [wCh1_VolShift]       ; 424F
    ld c, a                     ; 4252
    ld a, [hl]                  ; 4253
    and $0F                     ; 4254
    ld b, a                     ; 4256
    ld a, [hl+]                 ; 4257
    inc c                       ; 4258
    dec c                       ; 4259
    jr z, .L426A                ; 425A
    dec c                       ; 425C
    jr z, .L4268                ; 425D
    dec c                       ; 425F
    jr z, .L4266                ; 4260
    srl a                       ; 4262
    srl a                       ; 4264
.L4266:
    srl a                       ; 4266
.L4268:
    srl a                       ; 4268
.L426A:
    and $F0                     ; 426A
    or b                        ; 426C
    ldh [rNR12], a              ; 426D
    bit 5, d                    ; 426F
    jr z, .L4287                ; 4271
    ld a, [hl+]                 ; 4273
    ld [wCh1_VibDelay], a       ; 4274
    ld a, [hl+]                 ; 4277
    ld b, a                     ; 4278
    and $0F                     ; 4279
    ld [wCh1_VibSpeed], a       ; 427B
    ld a, b                     ; 427E
    and $F0                     ; 427F
    ld [wCh1_VibDepth], a       ; 4281
    xor a                       ; 4284
    jr .L4291                   ; 4285
.L4287:
    xor a                       ; 4287
    ld [wCh1_VibDelay], a       ; 4288
    ld [wCh1_VibDepth], a       ; 428B
    ld [wCh1_VibSpeed], a       ; 428E
.L4291:
    ld [wCh1_VibPhase], a       ; 4291
    ld a, d                     ; 4294
    and $1F                     ; 4295
    ld [wCh1_PLSteps], a        ; 4297
    ld a, l                     ; 429A
    ld [wCh1_PLPtrLo], a        ; 429B
    ld a, h                     ; 429E
    ld [wCh1_PLPtrHi], a        ; 429F

;; Retrigger the channel (NRx4 bit 7).
Row_Ch1_Trigger:
    ld hl, rNR14                ; 42A2
    set 7, [hl]                 ; 42A5
Row_Ch2:
    ld a, [wCh2_TrackPtrLo]     ; 42A7
    ld l, a                     ; 42AA
    ld a, [wCh2_TrackPtrHi]     ; 42AB
    ld h, a                     ; 42AE
    ld a, [hl+]                 ; 42AF
    ld [wCh2_RowNote], a        ; 42B0
    ld e, a                     ; 42B3
    bit 6, e                    ; 42B4
    jr z, .L42BC                ; 42B6
    ld a, [hl+]                 ; 42B8
    ld [wCh2_RowIns], a         ; 42B9
.L42BC:
    bit 7, e                    ; 42BC
    jr z, .L42C4                ; 42BE
    ld a, [hl+]                 ; 42C0
    ld [wCh2_RowFx], a          ; 42C1
.L42C4:
    ld a, l                     ; 42C4
    ld [wCh2_TrackPtrLo], a     ; 42C5
    ld a, h                     ; 42C8
    ld [wCh2_TrackPtrHi], a     ; 42C9
    bit 7, e                    ; 42CC
    jr z, .L42E2                ; 42CE
    ld a, [wCh2_RowFx]          ; 42D0
    ld b, a                     ; 42D3
    swap b                      ; 42D4
    and $0F                     ; 42D6
    sub $0F                     ; 42D8
    jr nz, .L42E2               ; 42DA
    ld a, b                     ; 42DC
    and $0F                     ; 42DD
    ld [wSpeed], a              ; 42DF
.L42E2:
    ld a, [wCh2_SFXTimer]       ; 42E2
    or a                        ; 42E5
    jp nz, Row_Ch3              ; 42E6
    ld a, e                     ; 42E9
    and $3F                     ; 42EA
    jr z, .L42F1                ; 42EC
    ld [wCh2_Note], a           ; 42EE
.L42F1:
    ld a, [wCh2_RowNote]        ; 42F1
    bit 6, a                    ; 42F4
    jp z, Row_Ch3               ; 42F6
    ld a, [wCh2_RowIns]         ; 42F9
    and $3F                     ; 42FC
    jp nz, Row_Ch2_LoadIns      ; 42FE
    ld a, [wCh2_RowIns]         ; 4301
    and $C0                     ; 4304
    jr z, .L432E                ; 4306
    rlc a                       ; 4308
    rlc a                       ; 430A
    ld [wCh2_VolShift], a       ; 430C
    ld c, a                     ; 430F
    ldh a, [rNR22]              ; 4310
    and $0F                     ; 4312
    ld b, a                     ; 4314
    ldh a, [rNR22]              ; 4315
    inc c                       ; 4317
    dec c                       ; 4318
    jr z, .L4329                ; 4319
    dec c                       ; 431B
    jr z, .L4327                ; 431C
    dec c                       ; 431E
    jr z, .L4325                ; 431F
    srl a                       ; 4321
    srl a                       ; 4323
.L4325:
    srl a                       ; 4325
.L4327:
    srl a                       ; 4327
.L4329:
    and $F0                     ; 4329
    or b                        ; 432B
    ldh [rNR22], a              ; 432C
.L432E:
    jp Row_Ch2_Trigger          ; 432E
Row_Ch2_LoadIns:
    dec a                       ; 4331
    ld c, a                     ; 4332
    xor a                       ; 4333
    ld [wCh2_VolShift], a       ; 4334
    ld a, [wCh2_RowIns]         ; 4337
    and $C0                     ; 433A
    jr z, .L4345                ; 433C
    rlc a                       ; 433E
    rlc a                       ; 4340
    ld [wCh2_VolShift], a       ; 4342
.L4345:
    ld a, [wHdr_InstsLo]        ; 4345
    ld l, a                     ; 4348
    ld a, [wHdr_InstsHi]        ; 4349
    ld h, a                     ; 434C
    ld b, $00                   ; 434D
    add hl, bc                  ; 434F
    add hl, bc                  ; 4350
    ld a, [hl+]                 ; 4351
    ld c, a                     ; 4352
    ld a, [hl+]                 ; 4353
    ld h, a                     ; 4354
    ld l, c                     ; 4355
    ld a, [hl+]                 ; 4356
    ld [wCh2_InsFlags], a       ; 4357
    ld d, a                     ; 435A
    ld a, [hl+]                 ; 435B
    ld [wCh2_PLSpeed], a        ; 435C
    xor a                       ; 435F
    ld [wCh2_PLTimer], a        ; 4360
    ld a, $80                   ; 4363
    ldh [rNR21], a              ; 4365
    ld a, [wCh2_VolShift]       ; 4367
    ld c, a                     ; 436A
    ld a, [hl]                  ; 436B
    and $0F                     ; 436C
    ld b, a                     ; 436E
    ld a, [hl+]                 ; 436F
    inc c                       ; 4370
    dec c                       ; 4371
    jr z, .L4382                ; 4372
    dec c                       ; 4374
    jr z, .L4380                ; 4375
    dec c                       ; 4377
    jr z, .L437E                ; 4378
    srl a                       ; 437A
    srl a                       ; 437C
.L437E:
    srl a                       ; 437E
.L4380:
    srl a                       ; 4380
.L4382:
    and $F0                     ; 4382
    or b                        ; 4384
    ldh [rNR22], a              ; 4385
    bit 5, d                    ; 4387
    jr z, .L439F                ; 4389
    ld a, [hl+]                 ; 438B
    ld [wCh2_VibDelay], a       ; 438C
    ld a, [hl+]                 ; 438F
    ld b, a                     ; 4390
    and $0F                     ; 4391
    ld [wCh2_VibSpeed], a       ; 4393
    ld a, b                     ; 4396
    and $F0                     ; 4397
    ld [wCh2_VibDepth], a       ; 4399
    xor a                       ; 439C
    jr .L43A9                   ; 439D
.L439F:
    xor a                       ; 439F
    ld [wCh2_VibDelay], a       ; 43A0
    ld [wCh2_VibDepth], a       ; 43A3
    ld [wCh2_VibSpeed], a       ; 43A6
.L43A9:
    ld [wCh2_VibPhase], a       ; 43A9
    ld a, d                     ; 43AC
    and $1F                     ; 43AD
    ld [wCh2_PLSteps], a        ; 43AF
    ld a, l                     ; 43B2
    ld [wCh2_PLPtrLo], a        ; 43B3
    ld a, h                     ; 43B6
    ld [wCh2_PLPtrHi], a        ; 43B7
Row_Ch2_Trigger:
    ld hl, rNR24                ; 43BA
    set 7, [hl]                 ; 43BD

;; New row, channel 3 (wave / PCM).
Row_Ch3:
    ld a, [wCh3_TrackPtrLo]     ; 43BF
    ld l, a                     ; 43C2
    ld a, [wCh3_TrackPtrHi]     ; 43C3
    ld h, a                     ; 43C6
    ld a, [hl+]                 ; 43C7
    ld [wCh3_RowNote], a        ; 43C8
    ld e, a                     ; 43CB
    bit 6, e                    ; 43CC
    jr z, .L43D4                ; 43CE
    ld a, [hl+]                 ; 43D0
    ld [wCh3_RowIns], a         ; 43D1
.L43D4:
    bit 7, e                    ; 43D4
    jr z, .L43DC                ; 43D6
    ld a, [hl+]                 ; 43D8
    ld [wCh3_RowFx], a          ; 43D9
.L43DC:
    ld a, l                     ; 43DC
    ld [wCh3_TrackPtrLo], a     ; 43DD
    ld a, h                     ; 43E0
    ld [wCh3_TrackPtrHi], a     ; 43E1
    bit 7, e                    ; 43E4
    jr z, .L43FA                ; 43E6
    ld a, [wCh3_RowFx]          ; 43E8
    ld b, a                     ; 43EB
    swap b                      ; 43EC
    and $0F                     ; 43EE
    sub $0F                     ; 43F0
    jr nz, .L43FA               ; 43F2
    ld a, b                     ; 43F4
    and $0F                     ; 43F5
    ld [wSpeed], a              ; 43F7
.L43FA:
    ld a, [wCh3_SFXTimer]       ; 43FA
    or a                        ; 43FD
    jp nz, Row_Ch4              ; 43FE
    ld a, e                     ; 4401
    and $3F                     ; 4402
    jr z, .L4409                ; 4404
    ld [wCh3_Note], a           ; 4406
.L4409:
    ld a, [wCh3_RowNote]        ; 4409
    bit 6, a                    ; 440C
    jp z, Row_Ch4               ; 440E
    ld a, [wCh3_RowIns]         ; 4411
    and $3F                     ; 4414
    jp nz, Row_Ch3_LoadIns      ; 4416
    ld a, [wCh3_RowIns]         ; 4419
    rrc a                       ; 441C
    cp $20                      ; 441E
    jr nz, .L4426               ; 4420
    ld a, $60                   ; 4422
    jr .L442C                   ; 4424
.L4426:
    cp $60                      ; 4426
    jr nz, .L442C               ; 4428
    ld a, $20                   ; 442A
.L442C:
    ldh [rNR32], a              ; 442C
    jp Row_Ch4                  ; 442E

;; Channel-3 instrument. Flags bits 6-7 <> 0 -> PCM sample instrument:
;;   [flags: rate index<<6] [sample lo] [sample hi] [blocks lo] [blocks hi]
;; The rate index selects a TMA/TAC/NR33/NR34 entry of PCMRateTable and enables
;; the timer interrupt; GHX_TimerISR then copies 16 bytes per IRQ to wave RAM.
Row_Ch3_LoadIns:
    dec a                       ; 4431
    ld c, a                     ; 4432
    xor a                       ; 4433
    ld [wCh3_VolShift], a       ; 4434
    ld a, [wCh3_RowIns]         ; 4437
    and $C0                     ; 443A
    jr z, .L4451                ; 443C
    rrc a                       ; 443E
    cp $20                      ; 4440
    jr nz, .L4448               ; 4442
    ld a, $60                   ; 4444
    jr .L444E                   ; 4446
.L4448:
    cp $60                      ; 4448
    jr nz, .L444E               ; 444A
    ld a, $20                   ; 444C
.L444E:
    ld [wCh3_VolShift], a       ; 444E
.L4451:
    ld a, [wHdr_InstsLo]        ; 4451
    ld l, a                     ; 4454
    ld a, [wHdr_InstsHi]        ; 4455
    ld h, a                     ; 4458
    ld b, $00                   ; 4459
    add hl, bc                  ; 445B
    add hl, bc                  ; 445C
    ld a, [hl+]                 ; 445D
    ld c, a                     ; 445E
    ld a, [hl+]                 ; 445F
    ld h, a                     ; 4460
    ld l, c                     ; 4461
    ld a, [hl+]                 ; 4462
    ld [wCh3_InsFlags], a       ; 4463
    ld d, a                     ; 4466
    and $C0                     ; 4467
    jr z, Row_Ch3_LoadWave      ; 4469
    rlc a                       ; 446B
    rlc a                       ; 446D
    ld [wWave_Update], a        ; 446F
    ld a, [hl+]                 ; 4472
    ld [wWave_BaseLo], a        ; 4473
    ld a, [hl+]                 ; 4476
    ld [wWave_BaseHi], a        ; 4477
    ld a, [hl+]                 ; 447A
    ld [wWave_PosLo], a         ; 447B
    ld a, [hl+]                 ; 447E
    ld [wWave_PosHi], a         ; 447F
    ld hl, PCMRateTable-4       ; 4482
    ld a, [wWave_Update]        ; 4485
    add a,a                     ; 4488
    add a,a                     ; 4489
    ld c, a                     ; 448A
    ld b, $00                   ; 448B
    add hl, bc                  ; 448D
    ld a, [hl+]                 ; 448E
    ldh [rTMA], a               ; 448F
    ld a, [hl+]                 ; 4491
    ldh [rTAC], a               ; 4492
    ld a, [hl+]                 ; 4494
    ld [wWave_Step], a          ; 4495
    ld a, [hl+]                 ; 4498
    ld [wWave_Flag], a          ; 4499
    xor a                       ; 449C
    ldh [rNR30], a              ; 449D
    ld a, $FF                   ; 449F
    ldh [rNR31], a              ; 44A1
    ld a, $20                   ; 44A3
    ldh [rNR32], a              ; 44A5
    ld a, $01                   ; 44A7
    ld [wPCM_Active], a         ; 44A9
    ldh a, [rIE]                ; 44AC
    or $04                      ; 44AE
    ldh [rIE], a                ; 44B0
    jp Row_Ch4                  ; 44B2

;; Wave instrument: [flags] [speed] [NR32] (vibrato) [sweep step] [flag byte]
;; [pos lo] [pos hi] [lower lo] [lower hi] [upper lo] [upper hi] [sweep speed]
;; [base lo] [base hi] then steps. 16 bytes from base+pos are copied to wave RAM;
;; when the sweep is switched on (playlist command $C0) pos moves by "step" every
;; "sweep speed" ticks and bounces between lower and upper (PWM-like effect).
Row_Ch3_LoadWave:
    ld [wPCM_Active], a         ; 44B5
    ldh a, [rIE]                ; 44B8
    and $FB                     ; 44BA
    ldh [rIE], a                ; 44BC
    ld a, [hl+]                 ; 44BE
    ld [wCh3_PLSpeed], a        ; 44BF
    xor a                       ; 44C2
    ld [wCh3_PLTimer], a        ; 44C3
    ld a, [wCh3_VolShift]       ; 44C6
    or a                        ; 44C9
    jr z, .L44CF                ; 44CA
    inc hl                      ; 44CC
    jr .L44D0                   ; 44CD
.L44CF:
    ld a, [hl+]                 ; 44CF
.L44D0:
    ldh [rNR32], a              ; 44D0
    xor a                       ; 44D2
    ld [wCh3_VolShift], a       ; 44D3
    bit 5, d                    ; 44D6
    jr z, .L44EE                ; 44D8
    ld a, [hl+]                 ; 44DA
    ld [wCh3_VibDelay], a       ; 44DB
    ld a, [hl+]                 ; 44DE
    ld b, a                     ; 44DF
    and $0F                     ; 44E0
    ld [wCh3_VibSpeed], a       ; 44E2
    ld a, b                     ; 44E5
    and $F0                     ; 44E6
    ld [wCh3_VibDepth], a       ; 44E8
    xor a                       ; 44EB
    jr .L44F8                   ; 44EC
.L44EE:
    xor a                       ; 44EE
    ld [wCh3_VibDelay], a       ; 44EF
    ld [wCh3_VibDepth], a       ; 44F2
    ld [wCh3_VibSpeed], a       ; 44F5
.L44F8:
    ld [wCh3_VibPhase], a       ; 44F8
    ld a, [hl+]                 ; 44FB
    ld [wWave_Step], a          ; 44FC
    xor a                       ; 44FF
    ld [wWave_SweepOn], a       ; 4500
    ld [wWave_Flag], a          ; 4503
    ld a, [hl+]                 ; 4506
    bit 7, a                    ; 4507
    jr z, .L450E                ; 4509
    ld [wWave_Flag], a          ; 450B
.L450E:
    and $7F                     ; 450E
    ld [wWave_Unused], a        ; 4510
    ld a, [hl+]                 ; 4513
    ld [wWave_PosLo], a         ; 4514
    ld a, [hl+]                 ; 4517
    ld [wWave_PosHi], a         ; 4518
    ld a, [hl+]                 ; 451B
    ld [wWave_LowerLo], a       ; 451C
    ld a, [hl+]                 ; 451F
    ld [wWave_LowerHi], a       ; 4520
    ld a, [hl+]                 ; 4523
    ld [wWave_UpperLo], a       ; 4524
    ld a, [hl+]                 ; 4527
    ld [wWave_UpperHi], a       ; 4528
    ld a, [hl+]                 ; 452B
    ld [wWave_SweepSpeed], a    ; 452C
    ld [wWave_SweepTimer], a    ; 452F
    ld a, [hl+]                 ; 4532
    ld [wWave_BaseLo], a        ; 4533
    ld a, [hl+]                 ; 4536
    ld [wWave_BaseHi], a        ; 4537
    ld a, d                     ; 453A
    and $1F                     ; 453B
    ld [wCh3_PLSteps], a        ; 453D
    ld a, l                     ; 4540
    ld [wCh3_PLPtrLo], a        ; 4541
    ld a, h                     ; 4544
    ld [wCh3_PLPtrHi], a        ; 4545
    ld a, $FF                   ; 4548
    ld [wWave_Update], a        ; 454A

;; New row, channel 4 (noise). Instrument: [flags] [speed] [NR42] then steps.
Row_Ch4:
    ld a, [wCh4_TrackPtrLo]     ; 454D
    ld l, a                     ; 4550
    ld a, [wCh4_TrackPtrHi]     ; 4551
    ld h, a                     ; 4554
    ld a, [hl+]                 ; 4555
    ld [wCh4_RowNote], a        ; 4556
    ld e, a                     ; 4559
    bit 6, e                    ; 455A
    jr z, .L4562                ; 455C
    ld a, [hl+]                 ; 455E
    ld [wCh4_RowIns], a         ; 455F
.L4562:
    bit 7, e                    ; 4562
    jr z, .L456A                ; 4564
    ld a, [hl+]                 ; 4566
    ld [wCh4_RowFx], a          ; 4567
.L456A:
    ld a, l                     ; 456A
    ld [wCh4_TrackPtrLo], a     ; 456B
    ld a, h                     ; 456E
    ld [wCh4_TrackPtrHi], a     ; 456F
    bit 7, e                    ; 4572
    jr z, .L4588                ; 4574
    ld a, [wCh4_RowFx]          ; 4576
    ld b, a                     ; 4579
    swap b                      ; 457A
    and $0F                     ; 457C
    sub $0F                     ; 457E
    jr nz, .L4588               ; 4580
    ld a, b                     ; 4582
    and $0F                     ; 4583
    ld [wSpeed], a              ; 4585
.L4588:
    ld a, [wCh4_SFXTimer]       ; 4588
    or a                        ; 458B
    jp nz, Row_Done             ; 458C
    ld a, e                     ; 458F
    and $3F                     ; 4590
    jr z, .L4597                ; 4592
    ld [wCh4_Note], a           ; 4594
.L4597:
    ld a, [wCh4_RowNote]        ; 4597
    bit 6, a                    ; 459A
    jp z, Row_Done              ; 459C
    ld a, [wCh4_RowIns]         ; 459F
    and $3F                     ; 45A2
    jp nz, Row_Ch4_LoadIns      ; 45A4
    ld a, [wCh4_RowIns]         ; 45A7
    and $C0                     ; 45AA
    jr z, .L45D4                ; 45AC
    rlc a                       ; 45AE
    rlc a                       ; 45B0
    ld [wCh4_VolShift], a       ; 45B2
    ld c, a                     ; 45B5
    ldh a, [rNR42]              ; 45B6
    and $0F                     ; 45B8
    ld b, a                     ; 45BA
    ldh a, [rNR42]              ; 45BB
    inc c                       ; 45BD
    dec c                       ; 45BE
    jr z, .L45CF                ; 45BF
    dec c                       ; 45C1
    jr z, .L45CD                ; 45C2
    dec c                       ; 45C4
    jr z, .L45CB                ; 45C5
    srl a                       ; 45C7
    srl a                       ; 45C9
.L45CB:
    srl a                       ; 45CB
.L45CD:
    srl a                       ; 45CD
.L45CF:
    and $F0                     ; 45CF
    or b                        ; 45D1
    ldh [rNR42], a              ; 45D2
.L45D4:
    jp Row_Ch4_Trigger          ; 45D4
Row_Ch4_LoadIns:
    dec a                       ; 45D7
    ld c, a                     ; 45D8
    xor a                       ; 45D9
    ld [wCh4_VolShift], a       ; 45DA
    ld a, [wCh4_RowIns]         ; 45DD
    and $C0                     ; 45E0
    jr z, .L45EB                ; 45E2
    rlc a                       ; 45E4
    rlc a                       ; 45E6
    ld [wCh4_VolShift], a       ; 45E8
.L45EB:
    ld a, [wHdr_InstsLo]        ; 45EB
    ld l, a                     ; 45EE
    ld a, [wHdr_InstsHi]        ; 45EF
    ld h, a                     ; 45F2
    ld b, $00                   ; 45F3
    add hl, bc                  ; 45F5
    add hl, bc                  ; 45F6
    ld a, [hl+]                 ; 45F7
    ld c, a                     ; 45F8
    ld a, [hl+]                 ; 45F9
    ld h, a                     ; 45FA
    ld l, c                     ; 45FB
    ld a, [hl+]                 ; 45FC
    ld [wCh4_InsFlags], a       ; 45FD
    ld d, a                     ; 4600
    ld a, [hl+]                 ; 4601
    ld [wCh4_PLSpeed], a        ; 4602
    xor a                       ; 4605
    ld [wCh4_PLTimer], a        ; 4606
    ld a, $00                   ; 4609
    ldh [rNR41], a              ; 460B
    ld a, [wCh4_VolShift]       ; 460D
    ld c, a                     ; 4610
    ld a, [hl]                  ; 4611
    and $0F                     ; 4612
    ld b, a                     ; 4614
    ld a, [hl+]                 ; 4615
    inc c                       ; 4616
    dec c                       ; 4617
    jr z, .L4628                ; 4618
    dec c                       ; 461A
    jr z, .L4626                ; 461B
    dec c                       ; 461D
    jr z, .L4624                ; 461E
    srl a                       ; 4620
    srl a                       ; 4622
.L4624:
    srl a                       ; 4624
.L4626:
    srl a                       ; 4626
.L4628:
    and $F0                     ; 4628
    or b                        ; 462A
    ldh [rNR42], a              ; 462B
    ld a, d                     ; 462D
    and $1F                     ; 462E
    ld [wCh4_PLSteps], a        ; 4630
    ld a, l                     ; 4633
    ld [wCh4_PLPtrLo], a        ; 4634
    ld a, h                     ; 4637
    ld [wCh4_PLPtrHi], a        ; 4638
Row_Ch4_Trigger:
    ld hl, rNR44                ; 463B
    set 7, [hl]                 ; 463E

;; Row finished: reload the tick counter with the speed.
Row_Done:
    ld a, [wSpeed]              ; 4640
    ld [wTickCount], a          ; 4643

;; Per-tick processing. For each channel: instrument playlist, vibrato, pitch.
;; Playlist step = [note] [cmd] [cmd]. Note: bits 0-5 note (0 = keep),
;; bit 6 = absolute note (else relative to row note + transpose; 1 = unison).
;; Commands: $00 none, $40|v volume (NRx2 high nibble = v, retrigger),
;; $80|n jump back n steps (loop), $C0|d duty d (ch1/2) / toggle wave sweep (ch3).
Tick:
    ld hl, wTickCount           ; 4646
    dec [hl]                    ; 4649
    ld a, [wCh1_SFXTimer]       ; 464A
    or a                        ; 464D
    jr z, Tick_Ch1              ; 464E
    dec a                       ; 4650
    ld [wCh1_SFXTimer], a       ; 4651
Tick_Ch1:
    ld a, [wCh1_PLTimer]        ; 4654
    or a                        ; 4657
    jp nz, Tick_Ch1_Pitch       ; 4658
    ld a, [wCh1_PLSpeed]        ; 465B
    ld [wCh1_PLTimer], a        ; 465E
    ld a, [wCh1_PLSteps]        ; 4661
    or a                        ; 4664
    jp z, Tick_Ch1_Pitch        ; 4665
    dec a                       ; 4668
    ld [wCh1_PLSteps], a        ; 4669
    ld a, [wCh1_PLPtrLo]        ; 466C
    ld l, a                     ; 466F
    ld a, [wCh1_PLPtrHi]        ; 4670
    ld h, a                     ; 4673
    ld a, [hl+]                 ; 4674
    ld [wCh1_PLNoteRaw], a      ; 4675
    and $3F                     ; 4678
    jr z, .L467F                ; 467A
    ld [wCh1_PLNote], a         ; 467C
.L467F:
    ld a, [hl+]                 ; 467F
    bit 7, a                    ; 4680
    jr nz, .L46B9               ; 4682
    bit 6, a                    ; 4684
    jr nz, .L468B               ; 4686
    jp .L46DB                   ; 4688
.L468B:
    swap a                      ; 468B
    ld b, a                     ; 468D
    ld a, [wCh1_VolShift]       ; 468E
    ld c, a                     ; 4691
    ld a, b                     ; 4692
    inc c                       ; 4693
    dec c                       ; 4694
    jr z, .L46A5                ; 4695
    dec c                       ; 4697
    jr z, .L46A3                ; 4698
    dec c                       ; 469A
    jr z, .L46A1                ; 469B
    srl a                       ; 469D
    srl a                       ; 469F
.L46A1:
    srl a                       ; 46A1
.L46A3:
    srl a                       ; 46A3
.L46A5:
    and $F0                     ; 46A5
    ld c, a                     ; 46A7
    ldh a, [rNR12]              ; 46A8
    and $0F                     ; 46AA
    or c                        ; 46AC
    ldh [rNR12], a              ; 46AD
    push hl                     ; 46AF
    ld hl, rNR14                ; 46B0
    set 7, [hl]                 ; 46B3
    pop hl                      ; 46B5
    jp .L46DB                   ; 46B6
.L46B9:
    bit 6, a                    ; 46B9
    jr nz, .L46D3               ; 46BB
    and $3F                     ; 46BD
    ld d, a                     ; 46BF
    cpl                         ; 46C0
    inc a                       ; 46C1
    ld c, a                     ; 46C2
    xor a                       ; 46C3
    cpl                         ; 46C4
    ld b, a                     ; 46C5
    add hl, bc                  ; 46C6
    add hl, bc                  ; 46C7
    add hl, bc                  ; 46C8
    ld a, [wCh1_PLSteps]        ; 46C9
    ld c, d                     ; 46CC
    add a,c                     ; 46CD
    ld [wCh1_PLSteps], a        ; 46CE
    jr .L46DB                   ; 46D1
.L46D3:
    and $3F                     ; 46D3
    rrc a                       ; 46D5
    rrc a                       ; 46D7
    ldh [rNR11], a              ; 46D9
.L46DB:
    ld a, [hl+]                 ; 46DB
    bit 7, a                    ; 46DC
    jr nz, .L4715               ; 46DE
    bit 6, a                    ; 46E0
    jr nz, .L46E7               ; 46E2
    jp .L4737                   ; 46E4
.L46E7:
    swap a                      ; 46E7
    ld b, a                     ; 46E9
    ld a, [wCh1_VolShift]       ; 46EA
    ld c, a                     ; 46ED
    ld a, b                     ; 46EE
    inc c                       ; 46EF
    dec c                       ; 46F0
    jr z, .L4701                ; 46F1
    dec c                       ; 46F3
    jr z, .L46FF                ; 46F4
    dec c                       ; 46F6
    jr z, .L46FD                ; 46F7
    srl a                       ; 46F9
    srl a                       ; 46FB
.L46FD:
    srl a                       ; 46FD
.L46FF:
    srl a                       ; 46FF
.L4701:
    and $F0                     ; 4701
    ld c, a                     ; 4703
    ldh a, [rNR12]              ; 4704
    and $0F                     ; 4706
    or c                        ; 4708
    ldh [rNR12], a              ; 4709
    push hl                     ; 470B
    ld hl, rNR14                ; 470C
    set 7, [hl]                 ; 470F
    pop hl                      ; 4711
    jp .L4737                   ; 4712
.L4715:
    bit 6, a                    ; 4715
    jr nz, .L472F               ; 4717
    and $3F                     ; 4719
    ld d, a                     ; 471B
    cpl                         ; 471C
    inc a                       ; 471D
    ld c, a                     ; 471E
    xor a                       ; 471F
    cpl                         ; 4720
    ld b, a                     ; 4721
    add hl, bc                  ; 4722
    add hl, bc                  ; 4723
    add hl, bc                  ; 4724
    ld a, [wCh1_PLSteps]        ; 4725
    ld c, d                     ; 4728
    add a,c                     ; 4729
    ld [wCh1_PLSteps], a        ; 472A
    jr .L4737                   ; 472D
.L472F:
    and $3F                     ; 472F
    rrc a                       ; 4731
    rrc a                       ; 4733
    ldh [rNR11], a              ; 4735
.L4737:
    ld a, l                     ; 4737
    ld [wCh1_PLPtrLo], a        ; 4738
    ld a, h                     ; 473B
    ld [wCh1_PLPtrHi], a        ; 473C

;; Frequency = FreqTable[note+transpose+PLnote-1] + vibrato.
;; Vibrato: after VibDelay ticks the phase advances by VibSpeed (0-63) and the
;; offset is VibratoTable[VibDepth | phase>>2] (signed).
Tick_Ch1_Pitch:
    ld hl, wCh1_PLTimer         ; 473F
    dec [hl]                    ; 4742
    ld b, $00                   ; 4743
    ld a, [wCh1_PLNote]         ; 4745
    ld c, a                     ; 4748
    ld a, [wCh1_PLNoteRaw]      ; 4749
    bit 6, a                    ; 474C
    jr nz, .L475B               ; 474E
    ld a, [wCh1_Transpose]      ; 4750
    add a,c                     ; 4753
    ld c, a                     ; 4754
    ld a, [wCh1_Note]           ; 4755
    add a,c                     ; 4758
    dec a                       ; 4759
    ld c, a                     ; 475A
.L475B:
    ld hl, FreqTable            ; 475B
    add hl, bc                  ; 475E
    add hl, bc                  ; 475F
    ld c, $00                   ; 4760
    ld a, [wCh1_VibDepth]       ; 4762
    or a                        ; 4765
    jr z, .L479C                ; 4766
    ld a, [wCh1_VibDelay]       ; 4768
    dec a                       ; 476B
    cp $FF                      ; 476C
    jr z, .L4775                ; 476E
    ld [wCh1_VibDelay], a       ; 4770
    jr .L479C                   ; 4773
.L4775:
    ld a, [wCh1_VibSpeed]       ; 4775
    ld c, a                     ; 4778
    ld a, [wCh1_VibPhase]       ; 4779
    add a,c                     ; 477C
    and $3F                     ; 477D
    ld [wCh1_VibPhase], a       ; 477F
    srl a                       ; 4782
    srl a                       ; 4784
    ld c, a                     ; 4786
    ld a, [wCh1_VibDepth]       ; 4787
    or c                        ; 478A
    ld c, a                     ; 478B
    push hl                     ; 478C
    ld hl, VibratoTable         ; 478D
    add hl, bc                  ; 4790
    ld a, [hl]                  ; 4791
    pop hl                      ; 4792
    ld c, a                     ; 4793
    ld b, $00                   ; 4794
    bit 7, a                    ; 4796
    jr z, .L479C                ; 4798
    ld b, $FF                   ; 479A
.L479C:
    ld a, [hl+]                 ; 479C
    ld e, a                     ; 479D
    ld a, [hl]                  ; 479E
    ld h, a                     ; 479F
    ld l, e                     ; 47A0
    add hl, bc                  ; 47A1
    ld a, l                     ; 47A2
    ldh [rNR13], a              ; 47A3
    ld a, h                     ; 47A5
    ldh [rNR14], a              ; 47A6
Tick_Ch2:
    ld a, [wCh2_SFXTimer]       ; 47A8
    or a                        ; 47AB
    jr z, .L47B2                ; 47AC
    dec a                       ; 47AE
    ld [wCh2_SFXTimer], a       ; 47AF
.L47B2:
    ld a, [wCh2_PLTimer]        ; 47B2
    or a                        ; 47B5
    jp nz, Tick_Ch2_Pitch       ; 47B6
    ld a, [wCh2_PLSpeed]        ; 47B9
    ld [wCh2_PLTimer], a        ; 47BC
    ld a, [wCh2_PLSteps]        ; 47BF
    or a                        ; 47C2
    jp z, Tick_Ch2_Pitch        ; 47C3
    dec a                       ; 47C6
    ld [wCh2_PLSteps], a        ; 47C7
    ld a, [wCh2_PLPtrLo]        ; 47CA
    ld l, a                     ; 47CD
    ld a, [wCh2_PLPtrHi]        ; 47CE
    ld h, a                     ; 47D1
    ld a, [hl+]                 ; 47D2
    ld [wCh2_PLNoteRaw], a      ; 47D3
    and $3F                     ; 47D6
    jr z, .L47DD                ; 47D8
    ld [wCh2_PLNote], a         ; 47DA
.L47DD:
    ld a, [hl+]                 ; 47DD
    bit 7, a                    ; 47DE
    jr nz, .L4817               ; 47E0
    bit 6, a                    ; 47E2
    jr nz, .L47E9               ; 47E4
    jp .L4839                   ; 47E6
.L47E9:
    swap a                      ; 47E9
    ld b, a                     ; 47EB
    ld a, [wCh2_VolShift]       ; 47EC
    ld c, a                     ; 47EF
    ld a, b                     ; 47F0
    inc c                       ; 47F1
    dec c                       ; 47F2
    jr z, .L4803                ; 47F3
    dec c                       ; 47F5
    jr z, .L4801                ; 47F6
    dec c                       ; 47F8
    jr z, .L47FF                ; 47F9
    srl a                       ; 47FB
    srl a                       ; 47FD
.L47FF:
    srl a                       ; 47FF
.L4801:
    srl a                       ; 4801
.L4803:
    and $F0                     ; 4803
    ld c, a                     ; 4805
    ldh a, [rNR22]              ; 4806
    and $0F                     ; 4808
    or c                        ; 480A
    ldh [rNR22], a              ; 480B
    push hl                     ; 480D
    ld hl, rNR24                ; 480E
    set 7, [hl]                 ; 4811
    pop hl                      ; 4813
    jp .L4839                   ; 4814
.L4817:
    bit 6, a                    ; 4817
    jr nz, .L4831               ; 4819
    and $3F                     ; 481B
    ld d, a                     ; 481D
    cpl                         ; 481E
    inc a                       ; 481F
    ld c, a                     ; 4820
    xor a                       ; 4821
    cpl                         ; 4822
    ld b, a                     ; 4823
    add hl, bc                  ; 4824
    add hl, bc                  ; 4825
    add hl, bc                  ; 4826
    ld a, [wCh2_PLSteps]        ; 4827
    ld c, d                     ; 482A
    add a,c                     ; 482B
    ld [wCh2_PLSteps], a        ; 482C
    jr .L4839                   ; 482F
.L4831:
    and $3F                     ; 4831
    rrc a                       ; 4833
    rrc a                       ; 4835
    ldh [rNR21], a              ; 4837
.L4839:
    ld a, [hl+]                 ; 4839
    bit 7, a                    ; 483A
    jr nz, .L4873               ; 483C
    bit 6, a                    ; 483E
    jr nz, .L4845               ; 4840
    jp .L4895                   ; 4842
.L4845:
    swap a                      ; 4845
    ld b, a                     ; 4847
    ld a, [wCh2_VolShift]       ; 4848
    ld c, a                     ; 484B
    ld a, b                     ; 484C
    inc c                       ; 484D
    dec c                       ; 484E
    jr z, .L485F                ; 484F
    dec c                       ; 4851
    jr z, .L485D                ; 4852
    dec c                       ; 4854
    jr z, .L485B                ; 4855
    srl a                       ; 4857
    srl a                       ; 4859
.L485B:
    srl a                       ; 485B
.L485D:
    srl a                       ; 485D
.L485F:
    and $F0                     ; 485F
    ld c, a                     ; 4861
    ldh a, [rNR22]              ; 4862
    and $0F                     ; 4864
    or c                        ; 4866
    ldh [rNR22], a              ; 4867
    push hl                     ; 4869
    ld hl, rNR24                ; 486A
    set 7, [hl]                 ; 486D
    pop hl                      ; 486F
    jp .L4895                   ; 4870
.L4873:
    bit 6, a                    ; 4873
    jr nz, .L488D               ; 4875
    and $3F                     ; 4877
    ld d, a                     ; 4879
    cpl                         ; 487A
    inc a                       ; 487B
    ld c, a                     ; 487C
    xor a                       ; 487D
    cpl                         ; 487E
    ld b, a                     ; 487F
    add hl, bc                  ; 4880
    add hl, bc                  ; 4881
    add hl, bc                  ; 4882
    ld a, [wCh2_PLSteps]        ; 4883
    ld c, d                     ; 4886
    add a,c                     ; 4887
    ld [wCh2_PLSteps], a        ; 4888
    jr .L4895                   ; 488B
.L488D:
    and $3F                     ; 488D
    rrc a                       ; 488F
    rrc a                       ; 4891
    ldh [rNR21], a              ; 4893
.L4895:
    ld a, l                     ; 4895
    ld [wCh2_PLPtrLo], a        ; 4896
    ld a, h                     ; 4899
    ld [wCh2_PLPtrHi], a        ; 489A
Tick_Ch2_Pitch:
    ld hl, wCh2_PLTimer         ; 489D
    dec [hl]                    ; 48A0
    ld b, $00                   ; 48A1
    ld a, [wCh2_PLNote]         ; 48A3
    ld c, a                     ; 48A6
    ld a, [wCh2_PLNoteRaw]      ; 48A7
    bit 6, a                    ; 48AA
    jr nz, .L48B9               ; 48AC
    ld a, [wCh2_Transpose]      ; 48AE
    add a,c                     ; 48B1
    ld c, a                     ; 48B2
    ld a, [wCh2_Note]           ; 48B3
    add a,c                     ; 48B6
    dec a                       ; 48B7
    ld c, a                     ; 48B8
.L48B9:
    ld hl, FreqTable            ; 48B9
    add hl, bc                  ; 48BC
    add hl, bc                  ; 48BD
    ld c, $00                   ; 48BE
    ld a, [wCh2_VibDepth]       ; 48C0
    or a                        ; 48C3
    jr z, .L48FA                ; 48C4
    ld a, [wCh2_VibDelay]       ; 48C6
    dec a                       ; 48C9
    cp $FF                      ; 48CA
    jr z, .L48D3                ; 48CC
    ld [wCh2_VibDelay], a       ; 48CE
    jr .L48FA                   ; 48D1
.L48D3:
    ld a, [wCh2_VibSpeed]       ; 48D3
    ld c, a                     ; 48D6
    ld a, [wCh2_VibPhase]       ; 48D7
    add a,c                     ; 48DA
    and $3F                     ; 48DB
    ld [wCh2_VibPhase], a       ; 48DD
    srl a                       ; 48E0
    srl a                       ; 48E2
    ld c, a                     ; 48E4
    ld a, [wCh2_VibDepth]       ; 48E5
    or c                        ; 48E8
    ld c, a                     ; 48E9
    push hl                     ; 48EA
    ld hl, VibratoTable         ; 48EB
    add hl, bc                  ; 48EE
    ld a, [hl]                  ; 48EF
    pop hl                      ; 48F0
    ld c, a                     ; 48F1
    ld b, $00                   ; 48F2
    bit 7, a                    ; 48F4
    jr z, .L48FA                ; 48F6
    ld b, $FF                   ; 48F8
.L48FA:
    ld a, [hl+]                 ; 48FA
    ld e, a                     ; 48FB
    ld a, [hl]                  ; 48FC
    ld h, a                     ; 48FD
    ld l, e                     ; 48FE
    add hl, bc                  ; 48FF
    ld a, l                     ; 4900
    ldh [rNR23], a              ; 4901
    ld a, h                     ; 4903
    ldh [rNR24], a              ; 4904

;; Channel 3 tick (skipped completely while a PCM sample plays).
Tick_Ch3:
    ld a, [wPCM_Active]         ; 4906
    or a                        ; 4909
    jp nz, Tick_Ch4             ; 490A
    ld a, [wCh3_SFXTimer]       ; 490D
    or a                        ; 4910
    jr z, .L4917                ; 4911
    dec a                       ; 4913
    ld [wCh3_SFXTimer], a       ; 4914
.L4917:
    ld a, [wCh3_PLTimer]        ; 4917
    or a                        ; 491A
    jp nz, Tick_Ch3_Sweep       ; 491B
    ld a, [wCh3_PLSpeed]        ; 491E
    ld [wCh3_PLTimer], a        ; 4921
    ld a, [wCh3_PLSteps]        ; 4924
    or a                        ; 4927
    jp z, Tick_Ch3_Sweep        ; 4928
    dec a                       ; 492B
    ld [wCh3_PLSteps], a        ; 492C
    ld a, [wCh3_PLPtrLo]        ; 492F
    ld l, a                     ; 4932
    ld a, [wCh3_PLPtrHi]        ; 4933
    ld h, a                     ; 4936
    ld a, [hl+]                 ; 4937
    ld [wCh3_PLNoteRaw], a      ; 4938
    and $3F                     ; 493B
    jr z, .L4942                ; 493D
    ld [wCh3_PLNote], a         ; 493F
.L4942:
    ld a, [hl+]                 ; 4942
    bit 7, a                    ; 4943
    jr nz, .L4987               ; 4945
    bit 6, a                    ; 4947
    jr nz, .L494E               ; 4949
    jp .L49A8                   ; 494B
.L494E:
    and $3F                     ; 494E
    ld b, a                     ; 4950
    ld a, [wCh3_VolShift]       ; 4951
    ld c, a                     ; 4954
    ld a, b                     ; 4955
    inc c                       ; 4956
    dec c                       ; 4957
    jr z, .L4968                ; 4958
    dec c                       ; 495A
    jr z, .L4966                ; 495B
    dec c                       ; 495D
    jr z, .L4964                ; 495E
    srl a                       ; 4960
    srl a                       ; 4962
.L4964:
    srl a                       ; 4964
.L4966:
    srl a                       ; 4966
.L4968:
    cp $02                      ; 4968
    jr nz, .L4970               ; 496A
    ld a, $40                   ; 496C
    jr .L4982                   ; 496E
.L4970:
    cp $01                      ; 4970
    jr nz, .L4978               ; 4972
    ld a, $60                   ; 4974
    jr .L4982                   ; 4976
.L4978:
    cp $03                      ; 4978
    jr nz, .L4980               ; 497A
    ld a, $20                   ; 497C
    jr .L4982                   ; 497E
.L4980:
    ld a, $00                   ; 4980
.L4982:
    ldh [rNR32], a              ; 4982
    jp .L49A8                   ; 4984
.L4987:
    bit 6, a                    ; 4987
    jr nz, .L49A1               ; 4989
    and $3F                     ; 498B
    ld d, a                     ; 498D
    cpl                         ; 498E
    inc a                       ; 498F
    ld c, a                     ; 4990
    xor a                       ; 4991
    cpl                         ; 4992
    ld b, a                     ; 4993
    add hl, bc                  ; 4994
    add hl, bc                  ; 4995
    add hl, bc                  ; 4996
    ld a, [wCh3_PLSteps]        ; 4997
    ld c, d                     ; 499A
    add a,c                     ; 499B
    ld [wCh3_PLSteps], a        ; 499C
    jr .L49A8                   ; 499F
.L49A1:
    ld a, [wWave_SweepOn]       ; 49A1
    cpl                         ; 49A4
    ld [wWave_SweepOn], a       ; 49A5
.L49A8:
    ld a, [hl+]                 ; 49A8
    bit 7, a                    ; 49A9
    jr nz, .L49ED               ; 49AB
    bit 6, a                    ; 49AD
    jr nz, .L49B4               ; 49AF
    jp .L4A0E                   ; 49B1
.L49B4:
    and $3F                     ; 49B4
    ld b, a                     ; 49B6
    ld a, [wCh3_VolShift]       ; 49B7
    ld c, a                     ; 49BA
    ld a, b                     ; 49BB
    inc c                       ; 49BC
    dec c                       ; 49BD
    jr z, .L49CE                ; 49BE
    dec c                       ; 49C0
    jr z, .L49CC                ; 49C1
    dec c                       ; 49C3
    jr z, .L49CA                ; 49C4
    srl a                       ; 49C6
    srl a                       ; 49C8
.L49CA:
    srl a                       ; 49CA
.L49CC:
    srl a                       ; 49CC
.L49CE:
    cp $02                      ; 49CE
    jr nz, .L49D6               ; 49D0
    ld a, $40                   ; 49D2
    jr .L49E8                   ; 49D4
.L49D6:
    cp $01                      ; 49D6
    jr nz, .L49DE               ; 49D8
    ld a, $60                   ; 49DA
    jr .L49E8                   ; 49DC
.L49DE:
    cp $03                      ; 49DE
    jr nz, .L49E6               ; 49E0
    ld a, $20                   ; 49E2
    jr .L49E8                   ; 49E4
.L49E6:
    ld a, $00                   ; 49E6
.L49E8:
    ldh [rNR32], a              ; 49E8
    jp .L4A0E                   ; 49EA
.L49ED:
    bit 6, a                    ; 49ED
    jr nz, .L4A07               ; 49EF
    and $3F                     ; 49F1
    ld d, a                     ; 49F3
    cpl                         ; 49F4
    inc a                       ; 49F5
    ld c, a                     ; 49F6
    xor a                       ; 49F7
    cpl                         ; 49F8
    ld b, a                     ; 49F9
    add hl, bc                  ; 49FA
    add hl, bc                  ; 49FB
    add hl, bc                  ; 49FC
    ld a, [wCh3_PLSteps]        ; 49FD
    ld c, d                     ; 4A00
    add a,c                     ; 4A01
    ld [wCh3_PLSteps], a        ; 4A02
    jr .L4A0E                   ; 4A05
.L4A07:
    ld a, [wWave_SweepOn]       ; 4A07
    cpl                         ; 4A0A
    ld [wWave_SweepOn], a       ; 4A0B
.L4A0E:
    ld a, l                     ; 4A0E
    ld [wCh3_PLPtrLo], a        ; 4A0F
    ld a, h                     ; 4A12
    ld [wCh3_PLPtrHi], a        ; 4A13
Tick_Ch3_Sweep:
    ld hl, wCh3_PLTimer         ; 4A16
    dec [hl]                    ; 4A19
    ld a, [wWave_SweepOn]       ; 4A1A
    or a                        ; 4A1D
    jp z, Tick_Ch3_WaveRAM      ; 4A1E
    ld a, [wWave_SweepTimer]    ; 4A21
    or a                        ; 4A24
    jp nz, .L4A7D               ; 4A25
    ld a, [wWave_PosHi]         ; 4A28
    ld h, a                     ; 4A2B
    ld a, [wWave_PosLo]         ; 4A2C
    ld l, a                     ; 4A2F
    ld b, $00                   ; 4A30
    ld a, [wWave_Step]          ; 4A32
    ld c, a                     ; 4A35
    bit 7, c                    ; 4A36
    jr z, .L4A58                ; 4A38
    dec b                       ; 4A3A
    add hl, bc                  ; 4A3B
    ld a, h                     ; 4A3C
    ld [wWave_PosHi], a         ; 4A3D
    ld a, l                     ; 4A40
    ld [wWave_PosLo], a         ; 4A41
    ld a, [wWave_LowerLo]       ; 4A44
    cp l                        ; 4A47
    jr nz, .L4A56               ; 4A48
    ld a, [wWave_LowerHi]       ; 4A4A
    cp h                        ; 4A4D
    jr nz, .L4A56               ; 4A4E
    ld a, c                     ; 4A50
    cpl                         ; 4A51
    inc a                       ; 4A52
    ld [wWave_Step], a          ; 4A53
.L4A56:
    jr .L4A73                   ; 4A56
.L4A58:
    add hl, bc                  ; 4A58
    ld a, h                     ; 4A59
    ld [wWave_PosHi], a         ; 4A5A
    ld a, l                     ; 4A5D
    ld [wWave_PosLo], a         ; 4A5E
    ld a, [wWave_UpperLo]       ; 4A61
    cp l                        ; 4A64
    jr nz, .L4A73               ; 4A65
    ld a, [wWave_UpperHi]       ; 4A67
    cp h                        ; 4A6A
    jr nz, .L4A73               ; 4A6B
    ld a, c                     ; 4A6D
    cpl                         ; 4A6E
    inc a                       ; 4A6F
    ld [wWave_Step], a          ; 4A70
.L4A73:
    ld hl, wWave_Update         ; 4A73
    dec [hl]                    ; 4A76
    ld a, [wWave_SweepSpeed]    ; 4A77
    ld [wWave_SweepTimer], a    ; 4A7A
.L4A7D:
    ld hl, wWave_SweepTimer     ; 4A7D
    dec [hl]                    ; 4A80

;; wWave_Update = $FF -> copy 16 bytes from base+pos into wave RAM.
Tick_Ch3_WaveRAM:
    ld a, [wWave_Update]        ; 4A81
    inc a                       ; 4A84
    jp nz, Tick_Ch3_Pitch       ; 4A85
    ld [wWave_Update], a        ; 4A88
    ld a, [wWave_BaseLo]        ; 4A8B
    ld c, a                     ; 4A8E
    ld a, [wWave_PosLo]         ; 4A8F
    add a,c                     ; 4A92
    ld e, a                     ; 4A93
    ld a, [wWave_BaseHi]        ; 4A94
    ld c, a                     ; 4A97
    ld a, [wWave_PosHi]         ; 4A98
    adc a,c                     ; 4A9B
    ld d, a                     ; 4A9C
    ld hl, _AUD3WAVERAM         ; 4A9D
    xor a                       ; 4AA0
    ldh [rNR30], a              ; 4AA1
    ld a, [de]                  ; 4AA3
    inc de                      ; 4AA4
    ld [hl+], a                 ; 4AA5
    ld a, [de]                  ; 4AA6
    inc de                      ; 4AA7
    ld [hl+], a                 ; 4AA8
    ld a, [de]                  ; 4AA9
    inc de                      ; 4AAA
    ld [hl+], a                 ; 4AAB
    ld a, [de]                  ; 4AAC
    inc de                      ; 4AAD
    ld [hl+], a                 ; 4AAE
    ld a, [de]                  ; 4AAF
    inc de                      ; 4AB0
    ld [hl+], a                 ; 4AB1
    ld a, [de]                  ; 4AB2
    inc de                      ; 4AB3
    ld [hl+], a                 ; 4AB4
    ld a, [de]                  ; 4AB5
    inc de                      ; 4AB6
    ld [hl+], a                 ; 4AB7
    ld a, [de]                  ; 4AB8
    inc de                      ; 4AB9
    ld [hl+], a                 ; 4ABA
    ld a, [de]                  ; 4ABB
    inc de                      ; 4ABC
    ld [hl+], a                 ; 4ABD
    ld a, [de]                  ; 4ABE
    inc de                      ; 4ABF
    ld [hl+], a                 ; 4AC0
    ld a, [de]                  ; 4AC1
    inc de                      ; 4AC2
    ld [hl+], a                 ; 4AC3
    ld a, [de]                  ; 4AC4
    inc de                      ; 4AC5
    ld [hl+], a                 ; 4AC6
    ld a, [de]                  ; 4AC7
    inc de                      ; 4AC8
    ld [hl+], a                 ; 4AC9
    ld a, [de]                  ; 4ACA
    inc de                      ; 4ACB
    ld [hl+], a                 ; 4ACC
    ld a, [de]                  ; 4ACD
    inc de                      ; 4ACE
    ld [hl+], a                 ; 4ACF
    ld a, [de]                  ; 4AD0
    inc de                      ; 4AD1
    ld [hl+], a                 ; 4AD2
    ld a, $80                   ; 4AD3
    ldh [rNR30], a              ; 4AD5
    ld hl, rNR34                ; 4AD7
    set 7, [hl]                 ; 4ADA
    xor a                       ; 4ADC
    ldh [rNR31], a              ; 4ADD
Tick_Ch3_Pitch:
    xor a                       ; 4ADF
    ldh [rNR31], a              ; 4AE0
    ld b, $00                   ; 4AE2
    ld a, [wCh3_PLNote]         ; 4AE4
    ld c, a                     ; 4AE7
    ld a, [wCh3_PLNoteRaw]      ; 4AE8
    bit 6, a                    ; 4AEB
    jr nz, .L4AFA               ; 4AED
    ld a, [wCh3_Transpose]      ; 4AEF
    add a,c                     ; 4AF2
    ld c, a                     ; 4AF3
    ld a, [wCh3_Note]           ; 4AF4
    add a,c                     ; 4AF7
    dec a                       ; 4AF8
    ld c, a                     ; 4AF9
.L4AFA:
    ld hl, FreqTable            ; 4AFA
    add hl, bc                  ; 4AFD
    add hl, bc                  ; 4AFE
    ld c, $00                   ; 4AFF
    ld a, [wCh3_VibDepth]       ; 4B01
    or a                        ; 4B04
    jr z, .L4B3B                ; 4B05
    ld a, [wCh3_VibDelay]       ; 4B07
    dec a                       ; 4B0A
    cp $FF                      ; 4B0B
    jr z, .L4B14                ; 4B0D
    ld [wCh3_VibDelay], a       ; 4B0F
    jr .L4B3B                   ; 4B12
.L4B14:
    ld a, [wCh3_VibSpeed]       ; 4B14
    ld c, a                     ; 4B17
    ld a, [wCh3_VibPhase]       ; 4B18
    add a,c                     ; 4B1B
    and $3F                     ; 4B1C
    ld [wCh3_VibPhase], a       ; 4B1E
    srl a                       ; 4B21
    srl a                       ; 4B23
    ld c, a                     ; 4B25
    ld a, [wCh3_VibDepth]       ; 4B26
    or c                        ; 4B29
    ld c, a                     ; 4B2A
    push hl                     ; 4B2B
    ld hl, VibratoTable         ; 4B2C
    add hl, bc                  ; 4B2F
    ld a, [hl]                  ; 4B30
    pop hl                      ; 4B31
    ld c, a                     ; 4B32
    ld b, $00                   ; 4B33
    bit 7, a                    ; 4B35
    jr z, .L4B3B                ; 4B37
    ld b, $FF                   ; 4B39
.L4B3B:
    ld a, [hl+]                 ; 4B3B
    ld e, a                     ; 4B3C
    ld a, [hl]                  ; 4B3D
    ld h, a                     ; 4B3E
    ld l, e                     ; 4B3F
    add hl, bc                  ; 4B40
    ld a, l                     ; 4B41
    ldh [rNR33], a              ; 4B42
    ld a, h                     ; 4B44
    ldh [rNR34], a              ; 4B45
    xor a                       ; 4B47
    ldh [rNR31], a              ; 4B48

;; Channel 4 tick: NR43 = NoiseTable[(note+PLnote-2)/2].
Tick_Ch4:
    ld a, [wCh4_SFXTimer]       ; 4B4A
    or a                        ; 4B4D
    jr z, .L4B54                ; 4B4E
    dec a                       ; 4B50
    ld [wCh4_SFXTimer], a       ; 4B51
.L4B54:
    ld a, [wCh4_PLTimer]        ; 4B54
    or a                        ; 4B57
    jp nz, Tick_Ch4_Noise       ; 4B58
    ld a, [wCh4_PLSpeed]        ; 4B5B
    ld [wCh4_PLTimer], a        ; 4B5E
    ld a, [wCh4_PLSteps]        ; 4B61
    or a                        ; 4B64
    jp z, Tick_Ch4_Noise        ; 4B65
    dec a                       ; 4B68
    ld [wCh4_PLSteps], a        ; 4B69
    ld a, [wCh4_PLPtrLo]        ; 4B6C
    ld l, a                     ; 4B6F
    ld a, [wCh4_PLPtrHi]        ; 4B70
    ld h, a                     ; 4B73
    ld a, [hl+]                 ; 4B74
    ld [wCh4_PLNoteRaw], a      ; 4B75
    and $3F                     ; 4B78
    jr z, .L4B7F                ; 4B7A
    ld [wCh4_PLNote], a         ; 4B7C
.L4B7F:
    ld a, [hl+]                 ; 4B7F
    bit 7, a                    ; 4B80
    jr nz, .L4BB9               ; 4B82
    bit 6, a                    ; 4B84
    jr nz, .L4B8B               ; 4B86
    jp .L4BD3                   ; 4B88
.L4B8B:
    swap a                      ; 4B8B
    ld b, a                     ; 4B8D
    ld a, [wCh4_VolShift]       ; 4B8E
    ld c, a                     ; 4B91
    ld a, b                     ; 4B92
    inc c                       ; 4B93
    dec c                       ; 4B94
    jr z, .L4BA5                ; 4B95
    dec c                       ; 4B97
    jr z, .L4BA3                ; 4B98
    dec c                       ; 4B9A
    jr z, .L4BA1                ; 4B9B
    srl a                       ; 4B9D
    srl a                       ; 4B9F
.L4BA1:
    srl a                       ; 4BA1
.L4BA3:
    srl a                       ; 4BA3
.L4BA5:
    and $F0                     ; 4BA5
    ld c, a                     ; 4BA7
    ldh a, [rNR42]              ; 4BA8
    and $0F                     ; 4BAA
    or c                        ; 4BAC
    ldh [rNR42], a              ; 4BAD
    push hl                     ; 4BAF
    ld hl, rNR44                ; 4BB0
    set 7, [hl]                 ; 4BB3
    pop hl                      ; 4BB5
    jp .L4BD3                   ; 4BB6
.L4BB9:
    bit 6, a                    ; 4BB9
    jr nz, .L4BD3               ; 4BBB
    and $3F                     ; 4BBD
    ld d, a                     ; 4BBF
    cpl                         ; 4BC0
    inc a                       ; 4BC1
    ld c, a                     ; 4BC2
    xor a                       ; 4BC3
    cpl                         ; 4BC4
    ld b, a                     ; 4BC5
    add hl, bc                  ; 4BC6
    add hl, bc                  ; 4BC7
    add hl, bc                  ; 4BC8
    ld a, [wCh4_PLSteps]        ; 4BC9
    ld c, d                     ; 4BCC
    add a,c                     ; 4BCD
    ld [wCh4_PLSteps], a        ; 4BCE
    jr .L4BD3                   ; 4BD1
.L4BD3:
    ld a, [hl+]                 ; 4BD3
    bit 7, a                    ; 4BD4
    jr nz, .L4C0D               ; 4BD6
    bit 6, a                    ; 4BD8
    jr nz, .L4BDF               ; 4BDA
    jp .L4C27                   ; 4BDC
.L4BDF:
    swap a                      ; 4BDF
    ld b, a                     ; 4BE1
    ld a, [wCh4_VolShift]       ; 4BE2
    ld c, a                     ; 4BE5
    ld a, b                     ; 4BE6
    inc c                       ; 4BE7
    dec c                       ; 4BE8
    jr z, .L4BF9                ; 4BE9
    dec c                       ; 4BEB
    jr z, .L4BF7                ; 4BEC
    dec c                       ; 4BEE
    jr z, .L4BF5                ; 4BEF
    srl a                       ; 4BF1
    srl a                       ; 4BF3
.L4BF5:
    srl a                       ; 4BF5
.L4BF7:
    srl a                       ; 4BF7
.L4BF9:
    and $F0                     ; 4BF9
    ld c, a                     ; 4BFB
    ldh a, [rNR42]              ; 4BFC
    and $0F                     ; 4BFE
    or c                        ; 4C00
    ldh [rNR42], a              ; 4C01
    push hl                     ; 4C03
    ld hl, rNR44                ; 4C04
    set 7, [hl]                 ; 4C07
    pop hl                      ; 4C09
    jp .L4C27                   ; 4C0A
.L4C0D:
    bit 6, a                    ; 4C0D
    jr nz, .L4C27               ; 4C0F
    and $3F                     ; 4C11
    ld d, a                     ; 4C13
    cpl                         ; 4C14
    inc a                       ; 4C15
    ld c, a                     ; 4C16
    xor a                       ; 4C17
    cpl                         ; 4C18
    ld b, a                     ; 4C19
    add hl, bc                  ; 4C1A
    add hl, bc                  ; 4C1B
    add hl, bc                  ; 4C1C
    ld a, [wCh4_PLSteps]        ; 4C1D
    ld c, d                     ; 4C20
    add a,c                     ; 4C21
    ld [wCh4_PLSteps], a        ; 4C22
    jr .L4C27                   ; 4C25
.L4C27:
    ld a, l                     ; 4C27
    ld [wCh4_PLPtrLo], a        ; 4C28
    ld a, h                     ; 4C2B
    ld [wCh4_PLPtrHi], a        ; 4C2C
Tick_Ch4_Noise:
    ld hl, wCh4_PLTimer         ; 4C2F
    dec [hl]                    ; 4C32
    ld b, $00                   ; 4C33
    ld a, [wCh4_PLNote]         ; 4C35
    ld c, a                     ; 4C38
    ld a, [wCh4_PLNoteRaw]      ; 4C39
    bit 6, a                    ; 4C3C
    jr nz, .L4C4D               ; 4C3E
    ld a, $00                   ; 4C40
    add a,c                     ; 4C42
    ld c, a                     ; 4C43
    ld a, [wCh4_Note]           ; 4C44
    add a,c                     ; 4C47
    dec a                       ; 4C48
    dec a                       ; 4C49
    srl a                       ; 4C4A
    ld c, a                     ; 4C4C
.L4C4D:
    ld hl, NoiseTable           ; 4C4D
    add hl, bc                  ; 4C50
    ld a, [hl]                  ; 4C51
    ldh [rNR43], a              ; 4C52
Play_Return:
    ret                         ; 4C54

;; GHX_TimerISR: one timer IRQ = one 16-byte block of 4-bit PCM (32 samples).
;; Rate entry 1/2 = TMA $F0 TAC 4 (256 Hz) and NR33/34 = $700 (8192 Hz);
;; entry 3 = TMA $E0 TAC 7 (512 Hz) and $780 (16384 Hz). Runs with interrupts
;; enabled (ei). When the block count reaches 0 the timer IRQ is disabled.
TimerISR:
    ei                          ; 4C55
    ld a, [wPCM_Active]         ; 4C56
    cp $00                      ; 4C59
    jp z, TimerISR_End.L4CA8    ; 4C5B
    ld a, [wWave_PosLo]         ; 4C5E
    ld l, a                     ; 4C61
    ld a, [wWave_PosHi]         ; 4C62
    ld h, a                     ; 4C65
    or l                        ; 4C66
    jr z, TimerISR_End          ; 4C67
    dec hl                      ; 4C69
    ld a, l                     ; 4C6A
    ld [wWave_PosLo], a         ; 4C6B
    ld a, h                     ; 4C6E
    ld [wWave_PosHi], a         ; 4C6F
    ld a, [wWave_BaseLo]        ; 4C72
    ld l, a                     ; 4C75
    ld a, [wWave_BaseHi]        ; 4C76
    ld h, a                     ; 4C79
    ld de, _AUD3WAVERAM         ; 4C7A
    ld b, $10                   ; 4C7D
    xor a                       ; 4C7F
    ldh [rNR30], a              ; 4C80
.L4C82:
    ld a, [hl+]                 ; 4C82
    ld [de], a                  ; 4C83
    inc de                      ; 4C84
    dec b                       ; 4C85
    jr nz, .L4C82               ; 4C86
    ld a, $80                   ; 4C88
    ldh [rNR30], a              ; 4C8A
    ld a, [wWave_Step]          ; 4C8C
    ldh [rNR33], a              ; 4C8F
    ld a, [wWave_Flag]          ; 4C91
    ldh [rNR34], a              ; 4C94
    ld a, l                     ; 4C96
    ld [wWave_BaseLo], a        ; 4C97
    ld a, h                     ; 4C9A
    ld [wWave_BaseHi], a        ; 4C9B
    ret                         ; 4C9E
TimerISR_End:
    xor a                       ; 4C9F
    ldh [rNR30], a              ; 4CA0
    ldh a, [rIE]                ; 4CA2
    and $FB                     ; 4CA4
    ldh [rIE], a                ; 4CA6
.L4CA8:
    ret                         ; 4CA8

;; GHX_PlaySFX: A = effect. SFXTable entry = [ins ch1] [ins ch2] [ins ch3]
;; [ins ch4] [time]. Instruments (1-based, 0 = channel unused) come from
;; SFXInstTable; the channel's music is muted for "time" ticks.
PlaySFX:
    ld hl, SFXTable             ; 4CA9
    ld b, $00                   ; 4CAC
    ld c, a                     ; 4CAE
    add hl, bc                  ; 4CAF
    add hl, bc                  ; 4CB0
    add hl, bc                  ; 4CB1
    add hl, bc                  ; 4CB2
    add hl, bc                  ; 4CB3
    ld a, [hl+]                 ; 4CB4
    ld [wSFX_Ch1], a            ; 4CB5
    ld a, [hl+]                 ; 4CB8
    ld [wSFX_Ch2], a            ; 4CB9
    ld a, [hl+]                 ; 4CBC
    ld [wSFX_Ch3], a            ; 4CBD
    ld a, [hl+]                 ; 4CC0
    ld [wSFX_Ch4], a            ; 4CC1
    ld a, [hl+]                 ; 4CC4
    ld [wSFX_Time], a           ; 4CC5
    ld a, [wSFX_Ch1]            ; 4CC8
    or a                        ; 4CCB
    jp z, PlaySFX_Ch2           ; 4CCC
    dec a                       ; 4CCF
    ld hl, SFXInstTable         ; 4CD0
    ld b, $00                   ; 4CD3
    ld c, a                     ; 4CD5
    add hl, bc                  ; 4CD6
    add hl, bc                  ; 4CD7
    ld a, [hl+]                 ; 4CD8
    ld c, a                     ; 4CD9
    ld a, [hl+]                 ; 4CDA
    ld h, a                     ; 4CDB
    ld l, c                     ; 4CDC
    ld a, $41                   ; 4CDD
    ld [wCh1_RowNote], a        ; 4CDF
    ld e, a                     ; 4CE2
    ld a, $01                   ; 4CE3
    ld [wCh1_RowIns], a         ; 4CE5
    xor a                       ; 4CE8
    ld [wCh1_VolShift], a       ; 4CE9
    ld a, [hl+]                 ; 4CEC
    ld [wCh1_InsFlags], a       ; 4CED
    ld d, a                     ; 4CF0
    ld a, [hl+]                 ; 4CF1
    ld [wCh1_PLSpeed], a        ; 4CF2
    xor a                       ; 4CF5
    ld [wCh1_PLTimer], a        ; 4CF6
    ld a, $80                   ; 4CF9
    ldh [rNR11], a              ; 4CFB
    ld a, [wCh1_VolShift]       ; 4CFD
    ld c, a                     ; 4D00
    ld a, [hl]                  ; 4D01
    and $0F                     ; 4D02
    ld b, a                     ; 4D04
    ld a, [hl+]                 ; 4D05
    inc c                       ; 4D06
    dec c                       ; 4D07
    jr z, .L4D18                ; 4D08
    dec c                       ; 4D0A
    jr z, .L4D16                ; 4D0B
    dec c                       ; 4D0D
    jr z, .L4D14                ; 4D0E
    srl a                       ; 4D10
    srl a                       ; 4D12
.L4D14:
    srl a                       ; 4D14
.L4D16:
    srl a                       ; 4D16
.L4D18:
    and $F0                     ; 4D18
    or b                        ; 4D1A
    ldh [rNR12], a              ; 4D1B
    bit 5, d                    ; 4D1D
    jr z, .L4D35                ; 4D1F
    ld a, [hl+]                 ; 4D21
    ld [wCh1_VibDelay], a       ; 4D22
    ld a, [hl+]                 ; 4D25
    ld b, a                     ; 4D26
    and $0F                     ; 4D27
    ld [wCh1_VibSpeed], a       ; 4D29
    ld a, b                     ; 4D2C
    and $F0                     ; 4D2D
    ld [wCh1_VibDepth], a       ; 4D2F
    xor a                       ; 4D32
    jr .L4D3F                   ; 4D33
.L4D35:
    xor a                       ; 4D35
    ld [wCh1_VibDelay], a       ; 4D36
    ld [wCh1_VibDepth], a       ; 4D39
    ld [wCh1_VibSpeed], a       ; 4D3C
.L4D3F:
    ld [wCh1_VibPhase], a       ; 4D3F
    ld a, d                     ; 4D42
    and $1F                     ; 4D43
    ld [wCh1_PLSteps], a        ; 4D45
    ld a, l                     ; 4D48
    ld [wCh1_PLPtrLo], a        ; 4D49
    ld a, h                     ; 4D4C
    ld [wCh1_PLPtrHi], a        ; 4D4D
    ld hl, rNR14                ; 4D50
    set 7, [hl]                 ; 4D53
    ld a, [wSFX_Time]           ; 4D55
    ld [wCh1_SFXTimer], a       ; 4D58
PlaySFX_Ch2:
    ld a, [wSFX_Ch2]            ; 4D5B
    or a                        ; 4D5E
    jp z, PlaySFX_Ch3           ; 4D5F
    dec a                       ; 4D62
    ld hl, SFXInstTable         ; 4D63
    ld b, $00                   ; 4D66
    ld c, a                     ; 4D68
    add hl, bc                  ; 4D69
    add hl, bc                  ; 4D6A
    ld a, [hl+]                 ; 4D6B
    ld c, a                     ; 4D6C
    ld a, [hl+]                 ; 4D6D
    ld h, a                     ; 4D6E
    ld l, c                     ; 4D6F
    ld a, $41                   ; 4D70
    ld [wCh2_RowNote], a        ; 4D72
    ld e, a                     ; 4D75
    ld a, $01                   ; 4D76
    ld [wCh2_RowIns], a         ; 4D78
    xor a                       ; 4D7B
    ld [wCh2_VolShift], a       ; 4D7C
    ld a, [hl+]                 ; 4D7F
    ld [wCh2_InsFlags], a       ; 4D80
    ld d, a                     ; 4D83
    ld a, [hl+]                 ; 4D84
    ld [wCh2_PLSpeed], a        ; 4D85
    xor a                       ; 4D88
    ld [wCh2_PLTimer], a        ; 4D89
    ld a, $80                   ; 4D8C
    ldh [rNR21], a              ; 4D8E
    ld a, [wCh2_VolShift]       ; 4D90
    ld c, a                     ; 4D93
    ld a, [hl]                  ; 4D94
    and $0F                     ; 4D95
    ld b, a                     ; 4D97
    ld a, [hl+]                 ; 4D98
    inc c                       ; 4D99
    dec c                       ; 4D9A
    jr z, .L4DAB                ; 4D9B
    dec c                       ; 4D9D
    jr z, .L4DA9                ; 4D9E
    dec c                       ; 4DA0
    jr z, .L4DA7                ; 4DA1
    srl a                       ; 4DA3
    srl a                       ; 4DA5
.L4DA7:
    srl a                       ; 4DA7
.L4DA9:
    srl a                       ; 4DA9
.L4DAB:
    and $F0                     ; 4DAB
    or b                        ; 4DAD
    ldh [rNR22], a              ; 4DAE
    bit 5, d                    ; 4DB0
    jr z, .L4DC8                ; 4DB2
    ld a, [hl+]                 ; 4DB4
    ld [wCh2_VibDelay], a       ; 4DB5
    ld a, [hl+]                 ; 4DB8
    ld b, a                     ; 4DB9
    and $0F                     ; 4DBA
    ld [wCh2_VibSpeed], a       ; 4DBC
    ld a, b                     ; 4DBF
    and $F0                     ; 4DC0
    ld [wCh2_VibDepth], a       ; 4DC2
    xor a                       ; 4DC5
    jr .L4DD2                   ; 4DC6
.L4DC8:
    xor a                       ; 4DC8
    ld [wCh2_VibDelay], a       ; 4DC9
    ld [wCh2_VibDepth], a       ; 4DCC
    ld [wCh2_VibSpeed], a       ; 4DCF
.L4DD2:
    ld [wCh2_VibPhase], a       ; 4DD2
    ld a, d                     ; 4DD5
    and $1F                     ; 4DD6
    ld [wCh2_PLSteps], a        ; 4DD8
    ld a, l                     ; 4DDB
    ld [wCh2_PLPtrLo], a        ; 4DDC
    ld a, h                     ; 4DDF
    ld [wCh2_PLPtrHi], a        ; 4DE0
    ld hl, rNR24                ; 4DE3
    set 7, [hl]                 ; 4DE6
    ld a, [wSFX_Time]           ; 4DE8
    ld [wCh2_SFXTimer], a       ; 4DEB
PlaySFX_Ch3:
    ld a, [wSFX_Ch3]            ; 4DEE
    or a                        ; 4DF1
    jp z, PlaySFX_Ch4           ; 4DF2
    dec a                       ; 4DF5
    ld hl, SFXInstTable         ; 4DF6
    ld b, $00                   ; 4DF9
    ld c, a                     ; 4DFB
    add hl, bc                  ; 4DFC
    add hl, bc                  ; 4DFD
    ld a, [hl+]                 ; 4DFE
    ld c, a                     ; 4DFF
    ld a, [hl+]                 ; 4E00
    ld h, a                     ; 4E01
    ld l, c                     ; 4E02
    ld a, $41                   ; 4E03
    ld [wCh3_RowNote], a        ; 4E05
    ld e, a                     ; 4E08
    ld a, $01                   ; 4E09
    ld [wCh3_RowIns], a         ; 4E0B
    xor a                       ; 4E0E
    ld [wCh2_VolShift], a       ; 4E0F
    ld a, [hl+]                 ; 4E12
    ld [wCh3_InsFlags], a       ; 4E13
    ld d, a                     ; 4E16
    and $C0                     ; 4E17
    jr z, PlaySFX_Ch3_Wave      ; 4E19
    rlc a                       ; 4E1B
    rlc a                       ; 4E1D
    ld [wWave_Update], a        ; 4E1F
    ld a, [hl+]                 ; 4E22
    ld [wWave_BaseLo], a        ; 4E23
    ld a, [hl+]                 ; 4E26
    ld [wWave_BaseHi], a        ; 4E27
    ld a, [hl+]                 ; 4E2A
    ld [wWave_PosLo], a         ; 4E2B
    ld a, [hl+]                 ; 4E2E
    ld [wWave_PosHi], a         ; 4E2F
    ld hl, PCMRateTable-4       ; 4E32
    ld a, [wWave_Update]        ; 4E35
    add a,a                     ; 4E38
    add a,a                     ; 4E39
    ld c, a                     ; 4E3A
    ld b, $00                   ; 4E3B
    add hl, bc                  ; 4E3D
    ld a, [hl+]                 ; 4E3E
    ldh [rTMA], a               ; 4E3F
    ld a, [hl+]                 ; 4E41
    ldh [rTAC], a               ; 4E42
    ld a, [hl+]                 ; 4E44
    ld [wWave_Step], a          ; 4E45
    ld a, [hl+]                 ; 4E48
    ld [wWave_Flag], a          ; 4E49
    xor a                       ; 4E4C
    ldh [rNR30], a              ; 4E4D
    ld a, $FF                   ; 4E4F
    ldh [rNR31], a              ; 4E51
    ld a, $20                   ; 4E53
    ldh [rNR32], a              ; 4E55
    ld a, $01                   ; 4E57
    ld [wPCM_Active], a         ; 4E59
    ldh a, [rIE]                ; 4E5C
    or $04                      ; 4E5E
    ldh [rIE], a                ; 4E60
    jp PlaySFX_Ch3_Wave.L4EFD   ; 4E62
PlaySFX_Ch3_Wave:
    ld [wPCM_Active], a         ; 4E65
    ldh a, [rIE]                ; 4E68
    and $FB                     ; 4E6A
    ldh [rIE], a                ; 4E6C
    ld a, [hl+]                 ; 4E6E
    ld [wCh3_PLSpeed], a        ; 4E6F
    xor a                       ; 4E72
    ld [wCh3_PLTimer], a        ; 4E73
    ld a, [wCh3_VolShift]       ; 4E76
    or a                        ; 4E79
    jr z, .L4E7F                ; 4E7A
    inc hl                      ; 4E7C
    jr .L4E80                   ; 4E7D
.L4E7F:
    ld a, [hl+]                 ; 4E7F
.L4E80:
    ldh [rNR32], a              ; 4E80
    xor a                       ; 4E82
    ld [wCh3_VolShift], a       ; 4E83
    bit 5, d                    ; 4E86
    jr z, .L4E9E                ; 4E88
    ld a, [hl+]                 ; 4E8A
    ld [wCh3_VibDelay], a       ; 4E8B
    ld a, [hl+]                 ; 4E8E
    ld b, a                     ; 4E8F
    and $0F                     ; 4E90
    ld [wCh3_VibSpeed], a       ; 4E92
    ld a, b                     ; 4E95
    and $F0                     ; 4E96
    ld [wCh3_VibDepth], a       ; 4E98
    xor a                       ; 4E9B
    jr .L4EA8                   ; 4E9C
.L4E9E:
    xor a                       ; 4E9E
    ld [wCh3_VibDelay], a       ; 4E9F
    ld [wCh3_VibDepth], a       ; 4EA2
    ld [wCh3_VibSpeed], a       ; 4EA5
.L4EA8:
    ld [wCh3_VibPhase], a       ; 4EA8
    ld a, [hl+]                 ; 4EAB
    ld [wWave_Step], a          ; 4EAC
    xor a                       ; 4EAF
    ld [wWave_SweepOn], a       ; 4EB0
    ld [wWave_Flag], a          ; 4EB3
    ld a, [hl+]                 ; 4EB6
    bit 7, a                    ; 4EB7
    jr z, .L4EBE                ; 4EB9
    ld [wWave_Flag], a          ; 4EBB
.L4EBE:
    and $7F                     ; 4EBE
    ld [wWave_Unused], a        ; 4EC0
    ld a, [hl+]                 ; 4EC3
    ld [wWave_PosLo], a         ; 4EC4
    ld a, [hl+]                 ; 4EC7
    ld [wWave_PosHi], a         ; 4EC8
    ld a, [hl+]                 ; 4ECB
    ld [wWave_LowerLo], a       ; 4ECC
    ld a, [hl+]                 ; 4ECF
    ld [wWave_LowerHi], a       ; 4ED0
    ld a, [hl+]                 ; 4ED3
    ld [wWave_UpperLo], a       ; 4ED4
    ld a, [hl+]                 ; 4ED7
    ld [wWave_UpperHi], a       ; 4ED8
    ld a, [hl+]                 ; 4EDB
    ld [wWave_SweepSpeed], a    ; 4EDC
    ld [wWave_SweepTimer], a    ; 4EDF
    ld a, [hl+]                 ; 4EE2
    ld [wWave_BaseLo], a        ; 4EE3
    ld a, [hl+]                 ; 4EE6
    ld [wWave_BaseHi], a        ; 4EE7
    ld a, d                     ; 4EEA
    and $1F                     ; 4EEB
    ld [wCh3_PLSteps], a        ; 4EED
    ld a, l                     ; 4EF0
    ld [wCh3_PLPtrLo], a        ; 4EF1
    ld a, h                     ; 4EF4
    ld [wCh3_PLPtrHi], a        ; 4EF5
    ld a, $FF                   ; 4EF8
    ld [wWave_Update], a        ; 4EFA
.L4EFD:
    ld a, [wSFX_Time]           ; 4EFD
    ld [wCh3_SFXTimer], a       ; 4F00
PlaySFX_Ch4:
    ld a, [wSFX_Ch4]            ; 4F03
    or a                        ; 4F06
    jr z, .L4F70                ; 4F07
    dec a                       ; 4F09
    ld hl, SFXInstTable         ; 4F0A
    ld b, $00                   ; 4F0D
    ld c, a                     ; 4F0F
    add hl, bc                  ; 4F10
    add hl, bc                  ; 4F11
    ld a, [hl+]                 ; 4F12
    ld c, a                     ; 4F13
    ld a, [hl+]                 ; 4F14
    ld h, a                     ; 4F15
    ld l, c                     ; 4F16
    ld a, $41                   ; 4F17
    ld [wCh4_RowNote], a        ; 4F19
    ld e, a                     ; 4F1C
    ld a, $01                   ; 4F1D
    ld [wCh4_RowIns], a         ; 4F1F
    xor a                       ; 4F22
    ld [wCh4_VolShift], a       ; 4F23
    ld a, [hl+]                 ; 4F26
    ld [wCh4_InsFlags], a       ; 4F27
    ld d, a                     ; 4F2A
    ld a, [hl+]                 ; 4F2B
    ld [wCh4_PLSpeed], a        ; 4F2C
    xor a                       ; 4F2F
    ld [wCh4_PLTimer], a        ; 4F30
    ld a, $00                   ; 4F33
    ldh [rNR41], a              ; 4F35
    ld a, [wCh4_VolShift]       ; 4F37
    ld c, a                     ; 4F3A
    ld a, [hl]                  ; 4F3B
    and $0F                     ; 4F3C
    ld b, a                     ; 4F3E
    ld a, [hl+]                 ; 4F3F
    inc c                       ; 4F40
    dec c                       ; 4F41
    jr z, .L4F52                ; 4F42
    dec c                       ; 4F44
    jr z, .L4F50                ; 4F45
    dec c                       ; 4F47
    jr z, .L4F4E                ; 4F48
    srl a                       ; 4F4A
    srl a                       ; 4F4C
.L4F4E:
    srl a                       ; 4F4E
.L4F50:
    srl a                       ; 4F50
.L4F52:
    and $F0                     ; 4F52
    or b                        ; 4F54
    ldh [rNR42], a              ; 4F55
    ld a, d                     ; 4F57
    and $1F                     ; 4F58
    ld [wCh4_PLSteps], a        ; 4F5A
    ld a, l                     ; 4F5D
    ld [wCh4_PLPtrLo], a        ; 4F5E
    ld a, h                     ; 4F61
    ld [wCh4_PLPtrHi], a        ; 4F62
    ld hl, rNR44                ; 4F65
    set 7, [hl]                 ; 4F68
    ld a, [wSFX_Time]           ; 4F6A
    ld [wCh4_SFXTimer], a       ; 4F6D
.L4F70:
    ret                         ; 4F70

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

;; NR43 values for channel 4, one per two semitones.
NoiseTable:
    db $90, $57, $63, $63, $55, $55, $80, $47, $53, $53; 5003 
    db $45, $45, $70, $37, $43, $43, $35, $35, $60, $27; 500D 
    db $33, $33, $25, $25, $50, $17, $23, $23, $15, $15; 5017 

;; 16 depths x 16 phases, signed frequency offsets.
VibratoTable:
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00; 5021 
    db $00, $00, $00, $00, $01, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF, $FF, $FF; 5031 
    db $00, $00, $01, $01, $02, $01, $01, $00, $00, $FF, $FE, $FE, $FE, $FE, $FE, $FF; 5041 
    db $00, $01, $02, $02, $03, $02, $02, $01, $00, $FE, $FD, $FD, $FD, $FD, $FD, $FE; 5051 
    db $00, $01, $02, $03, $04, $03, $02, $01, $00, $FE, $FD, $FC, $FC, $FC, $FD, $FE; 5061 
    db $00, $01, $03, $04, $05, $04, $03, $01, $00, $FE, $FC, $FB, $FB, $FB, $FC, $FE; 5071 
    db $00, $02, $04, $05, $06, $05, $04, $02, $00, $FD, $FB, $FA, $FA, $FA, $FB, $FD; 5081 
    db $00, $02, $04, $06, $07, $06, $04, $02, $00, $FD, $FB, $F9, $F9, $F9, $FB, $FD; 5091 
    db $00, $03, $05, $07, $08, $07, $05, $03, $00, $FC, $FA, $F8, $F8, $F8, $FA, $FC; 50A1 
    db $00, $03, $06, $08, $09, $08, $06, $03, $00, $FC, $F9, $F7, $F7, $F7, $F9, $FC; 50B1 
    db $00, $03, $07, $09, $0A, $09, $07, $03, $00, $FC, $F8, $F6, $F6, $F6, $F8, $FC; 50C1 
    db $00, $04, $07, $0A, $0B, $0A, $07, $04, $00, $FB, $F8, $F5, $F5, $F5, $F8, $FB; 50D1 
    db $00, $04, $08, $0B, $0C, $0B, $08, $04, $00, $FB, $F7, $F4, $F4, $F4, $F7, $FB; 50E1 
    db $00, $04, $09, $0C, $0D, $0C, $09, $04, $00, $FB, $F6, $F3, $F3, $F3, $F6, $FB; 50F1 
    db $00, $05, $09, $0C, $0E, $0C, $09, $05, $00, $FA, $F6, $F3, $F2, $F3, $F6, $FA; 5101 
    db $00, $05, $0A, $0D, $0F, $0D, $0A, $05, $00, $FA, $F5, $F2, $F1, $F2, $F5, $FA; 5111 

;; PCM rates, 4 bytes each: TMA, TAC, NR33, NR34. Indexed 1-3
;; (the code uses PCMRateTable-4). 1,2: 256 IRQ/s = 8192 Hz; 3: 512 IRQ/s = 16384 Hz
PCMRateTable:
    db $F0, $04, $00, $87                       ; 5121 
    db $F0, $04, $00, $87                       ; 5125 
    db $E0, $07, $80, $87                       ; 5129 
SongTable:
    dw Song0_Header                              ; 512D  song 0

;; Song header (copied to wHdr_* by GHX_Init).
Song0_Header:
    db "GHX"                                    ; 512F magic
    db 1                                       ; subsongs
    db 32                                      ; rows per pattern
    db $00                                      ; (unused)
    dw Song0_Tracks                             ; track pointer table
    dw Song0_Instruments                        ; instrument pointer table
    dw Song0_Orders                            ; order table

;; Order table: two entries per subsong (intro, loop) = [count] [dw positions].
;; count+1 positions are played.
Song0_Orders:
    db 3  
    dw Song0_Pos00                           ; 513B subsong 0 intro (4 positions)
    db 1  
    dw Song0_Pos02                           ; 513E subsong 0 loop (2 positions)

;; Positions: track ch1, transpose ch1, track ch2, transpose ch2,
;; track ch3, transpose ch3, track ch4
Song0_Pos00:
    db  0,   0,  11,   0,   2,   0,  10           ; 5141 pos 0
    db  0,   0,   8,   0,   3,   0,   9           ; 5148 pos 1
Song0_Pos02:
    db  6,   0,   1,   0,   3,   0,   7           ; 514F pos 2
    db  5,   0,   4,   0,   3,   0,   7           ; 5156 pos 3
    db  0,   0,   0,   0,   0,   0,   0           ; 515D pos 4
Song0_Tracks:
    dw Track00                                   ; 5164  track 0
    dw Track01                                   ; 5166  track 1
    dw Track02                                   ; 5168  track 2
    dw Track03                                   ; 516A  track 3
    dw Track04                                   ; 516C  track 4
    dw Track05                                   ; 516E  track 5
    dw Track06                                   ; 5170  track 6
    dw Track07                                   ; 5172  track 7
    dw Track08                                   ; 5174  track 8
    dw Track09                                   ; 5176  track 9
    dw Track10                                   ; 5178  track 10
    dw Track11                                   ; 517A  track 11
Song0_Instruments:
    dw Inst00                                    ; 517C  instrument 0 (ch3)
    dw Inst01                                    ; 517E  instrument 1 (ch3)
    dw Inst02                                    ; 5180  instrument 2 (ch3)
    dw Inst03                                    ; 5182  instrument 3 (ch3)
    dw Inst04                                    ; 5184  instrument 4 (ch3)
    dw Inst05                                    ; 5186  instrument 5 (ch2)
    dw Inst06                                    ; 5188  instrument 6 (ch1)
    dw Inst07                                    ; 518A  instrument 7 (ch1)
    dw Inst08                                    ; 518C  instrument 8 (ch1)
    dw Inst09                                    ; 518E  instrument 9 (ch1)
    dw Inst10                                    ; 5190  instrument 10 (ch1)
    dw Inst11                                    ; 5192  instrument 11 (ch4)
    dw Inst12                                    ; 5194  instrument 12 (unused)
    dw Inst13                                    ; 5196  instrument 13 (ch2)
    dw Inst14                                    ; 5198  instrument 14 (ch2)
    dw Inst15                                    ; 519A  instrument 15 (ch4)
    dw Inst16                                    ; 519C  instrument 16 (ch3)
Inst00:
    db $C0                                     ; 519E PCM, rate 3
    db LOW(Sample00), HIGH(Sample00)      ; sample
    dw 123                                       ; 123 blocks of 16 bytes
Inst01:
    db $80                                     ; 51A3 PCM, rate 2
    db LOW(Sample01), HIGH(Sample01)      ; sample
    dw 7                                         ; 7 blocks of 16 bytes
Inst02:
    db $80                                     ; 51A8 PCM, rate 2
    db LOW(Sample02), HIGH(Sample02)      ; sample
    dw 3                                         ; 3 blocks of 16 bytes
Inst03:
    db $80                                     ; 51AD PCM, rate 2
    db LOW(Sample03), HIGH(Sample03)      ; sample
    dw 52                                        ; 52 blocks of 16 bytes
Inst04:
    db $80                                     ; 51B2 PCM, rate 2
    db LOW(Sample04), HIGH(Sample04)      ; sample
    dw 16                                        ; 16 blocks of 16 bytes
Inst05:
    db $0A                                       ; 51B7 square, 10 steps
    db $01                                       ; playlist speed
    db $C2                                       ; NR12 envelope
    db $00, $00, $40                             ; step 0: -  vol 0
    db $01, $4A, $C2                             ; step 1: +0  vol 10, duty 2
    db $00, $00, $00                             ; step 2: -
    db $00, $00, $00                             ; step 3: -
    db $00, $00, $C1                             ; step 4: -  duty 1
    db $00, $00, $00                             ; step 5: -
    db $00, $00, $00                             ; step 6: -
    db $00, $00, $C0                             ; step 7: -  duty 0
    db $00, $00, $00                             ; step 8: -
    db $00, $00, $C2                             ; step 9: -  duty 2
Inst06:
    db $04                                       ; 51D8 square, 4 steps
    db $02                                       ; playlist speed
    db $A7                                       ; NR12 envelope
    db $0D, $C0, $00                             ; step 0: +12  duty 0
    db $0F, $C1, $00                             ; step 1: +14  duty 1
    db $12, $C2, $00                             ; step 2: +17  duty 2
    db $16, $C1, $84                             ; step 3: +21  duty 1, loop -4
Inst07:
    db $04                                       ; 51E7 square, 4 steps
    db $02                                       ; playlist speed
    db $A7                                       ; NR12 envelope
    db $0F, $C0, $00                             ; step 0: +14  duty 0
    db $11, $C1, $00                             ; step 1: +16  duty 1
    db $14, $C2, $00                             ; step 2: +19  duty 2
    db $18, $C1, $84                             ; step 3: +23  duty 1, loop -4
Inst08:
    db $04                                       ; 51F6 square, 4 steps
    db $02                                       ; playlist speed
    db $A7                                       ; NR12 envelope
    db $0F, $C0, $00                             ; step 0: +14  duty 0
    db $11, $C1, $00                             ; step 1: +16  duty 1
    db $13, $C2, $00                             ; step 2: +18  duty 2
    db $16, $C1, $84                             ; step 3: +21  duty 1, loop -4
Inst09:
    db $04                                       ; 5205 square, 4 steps
    db $02                                       ; playlist speed
    db $A7                                       ; NR12 envelope
    db $11, $C0, $00                             ; step 0: +16  duty 0
    db $13, $C1, $00                             ; step 1: +18  duty 1
    db $16, $C2, $00                             ; step 2: +21  duty 2
    db $1A, $C1, $84                             ; step 3: +25  duty 1, loop -4
Inst10:
    db $04                                       ; 5214 square, 4 steps
    db $02                                       ; playlist speed
    db $A7                                       ; NR12 envelope
    db $11, $C0, $00                             ; step 0: +16  duty 0
    db $13, $C1, $00                             ; step 1: +18  duty 1
    db $15, $C2, $00                             ; step 2: +20  duty 2
    db $1A, $C1, $84                             ; step 3: +25  duty 1, loop -4
Inst11:
    db $02                                       ; 5223 noise, 2 steps
    db $01                                       ; playlist speed
    db $80                                       ; NR42 envelope
    db $71, $00, $00                             ; step 0: C-6
    db $00, $00, $40                             ; step 1: -  vol 0
Inst12:
    db $0A                                       ; 522C square, 10 steps
    db $01                                       ; playlist speed
    db $81                                       ; NR12 envelope
    db $01, $00, $C2                             ; step 0: +0  duty 2
    db $0D, $00, $00                             ; step 1: +12
    db $01, $00, $00                             ; step 2: +0
    db $00, $00, $C1                             ; step 3: -  duty 1
    db $00, $00, $00                             ; step 4: -
    db $00, $00, $00                             ; step 5: -
    db $00, $00, $C0                             ; step 6: -  duty 0
    db $00, $00, $00                             ; step 7: -
    db $00, $00, $88                             ; step 8: -  loop -8
    db $00, $00, $00                             ; step 9: -
Inst13:
    db $09                                       ; 524D square, 9 steps
    db $01                                       ; playlist speed
    db $C1                                       ; NR12 envelope
    db $59, $00, $C2                             ; step 0: C-4  duty 2
    db $58, $00, $00                             ; step 1: B-3
    db $56, $00, $00                             ; step 2: A-3
    db $54, $00, $00                             ; step 3: G-3
    db $52, $00, $00                             ; step 4: F-3
    db $51, $00, $00                             ; step 5: E-3
    db $4F, $00, $00                             ; step 6: D-3
    db $4D, $00, $00                             ; step 7: C-3
    db $00, $00, $40                             ; step 8: -  vol 0
Inst14:
    db $07                                       ; 526B square, 7 steps
    db $01                                       ; playlist speed
    db $91                                       ; NR12 envelope
    db $59, $00, $C2                             ; step 0: C-4  duty 2
    db $52, $00, $00                             ; step 1: F-3
    db $4D, $00, $00                             ; step 2: C-3
    db $46, $00, $00                             ; step 3: F-2
    db $00, $00, $40                             ; step 4: -  vol 0
    db $00, $00, $00                             ; step 5: -
    db $00, $00, $00                             ; step 6: -
Inst15:
    db $03                                       ; 5283 noise, 3 steps
    db $01                                       ; playlist speed
    db $C2                                       ; NR42 envelope
    db $71, $00, $00                             ; step 0: C-6
    db $00, $00, $40                             ; step 1: -  vol 0
    db $00, $00, $45                             ; step 2: -  vol 5
Inst16:
    db $80                                     ; 528F PCM, rate 2
    db LOW(Sample05), HIGH(Sample05)      ; sample
    dw 143                                       ; 143 blocks of 16 bytes
Track00:
    R   ___                                     ; 5294 row 00
    R   ___                                     ; 5295 row 01
    R   ___                                     ; 5296 row 02
    R   ___                                     ; 5297 row 03
    R   ___                                     ; 5298 row 04
    R   ___                                     ; 5299 row 05
    R   ___                                     ; 529A row 06
    R   ___                                     ; 529B row 07
    R   ___                                     ; 529C row 08
    R   ___                                     ; 529D row 09
    R   ___                                     ; 529E row 10
    R   ___                                     ; 529F row 11
    R   ___                                     ; 52A0 row 12
    R   ___                                     ; 52A1 row 13
    R   ___                                     ; 52A2 row 14
    R   ___                                     ; 52A3 row 15
    R   ___                                     ; 52A4 row 16
    R   ___                                     ; 52A5 row 17
    R   ___                                     ; 52A6 row 18
    R   ___                                     ; 52A7 row 19
    R   ___                                     ; 52A8 row 20
    R   ___                                     ; 52A9 row 21
    R   ___                                     ; 52AA row 22
    R   ___                                     ; 52AB row 23
    R   ___                                     ; 52AC row 24
    R   ___                                     ; 52AD row 25
    R   ___                                     ; 52AE row 26
    R   ___                                     ; 52AF row 27
    R   ___                                     ; 52B0 row 28
    R   ___                                     ; 52B1 row 29
    R   ___                                     ; 52B2 row 30
    R   ___                                     ; 52B3 row 31
Track01:
    RI  A_2, 6, 0                               ; 52B4 row 00  Inst05
    R   ___                                     ; 52B6 row 01
    RI  A_2, 6, 0                               ; 52B7 row 02  Inst05
    R   ___                                     ; 52B9 row 03
    R   ___                                     ; 52BA row 04
    RI  A_2, 6, 0                               ; 52BB row 05  Inst05
    R   ___                                     ; 52BD row 06
    R   ___                                     ; 52BE row 07
    RI  A_2, 6, 0                               ; 52BF row 08  Inst05
    R   ___                                     ; 52C1 row 09
    RI  A_3, 6, 0                               ; 52C2 row 10  Inst05
    RI  A_2, 6, 0                               ; 52C4 row 11  Inst05
    R   ___                                     ; 52C6 row 12
    R   ___                                     ; 52C7 row 13
    RI  A_2, 6, 0                               ; 52C8 row 14  Inst05
    RI  E_2, 6, 0                               ; 52CA row 15  Inst05
    RI  Fs2, 6, 0                               ; 52CC row 16  Inst05
    R   ___                                     ; 52CE row 17
    RI  Fs2, 6, 0                               ; 52CF row 18  Inst05
    R   ___                                     ; 52D1 row 19
    R   ___                                     ; 52D2 row 20
    RI  Fs2, 6, 0                               ; 52D3 row 21  Inst05
    R   ___                                     ; 52D5 row 22
    R   ___                                     ; 52D6 row 23
    RI  Fs2, 6, 0                               ; 52D7 row 24  Inst05
    R   ___                                     ; 52D9 row 25
    RI  Fs3, 6, 0                               ; 52DA row 26  Inst05
    RI  Fs2, 6, 0                               ; 52DC row 27  Inst05
    R   ___                                     ; 52DE row 28
    R   ___                                     ; 52DF row 29
    RI  Fs2, 6, 0                               ; 52E0 row 30  Inst05
    RI  E_2, 6, 0                               ; 52E2 row 31  Inst05
Track02:
    RI  C_5, 4, 0                               ; 52E4 row 00  Inst03
    R   ___                                     ; 52E6 row 01
    R   ___                                     ; 52E7 row 02
    R   ___                                     ; 52E8 row 03
    RI  C_5, 1, 0                               ; 52E9 row 04  Inst00
    R   ___                                     ; 52EB row 05
    R   ___                                     ; 52EC row 06
    RI  C_5, 4, 0                               ; 52ED row 07  Inst03
    R   ___                                     ; 52EF row 08
    R   ___                                     ; 52F0 row 09
    RI  C_5, 4, 0                               ; 52F1 row 10  Inst03
    R   ___                                     ; 52F3 row 11
    RI  C_5, 1, 0                               ; 52F4 row 12  Inst00
    R   ___                                     ; 52F6 row 13
    RI  C_3, 1, 0                               ; 52F7 row 14  Inst00
    RI  C_3, 1, 0                               ; 52F9 row 15  Inst00
    RI  C_3, 4, 0                               ; 52FB row 16  Inst03
    R   ___                                     ; 52FD row 17
    R   ___                                     ; 52FE row 18
    R   ___                                     ; 52FF row 19
    RI  C_5, 1, 0                               ; 5300 row 20  Inst00
    R   ___                                     ; 5302 row 21
    R   ___                                     ; 5303 row 22
    R   ___                                     ; 5304 row 23
    RI  C_3, 4, 0                               ; 5305 row 24  Inst03
    R   ___                                     ; 5307 row 25
    RI  C_3, 17, 0                              ; 5308 row 26  Inst16
    R   ___                                     ; 530A row 27
    R   ___                                     ; 530B row 28
    R   ___                                     ; 530C row 29
    R   ___                                     ; 530D row 30
    R   ___                                     ; 530E row 31
Track03:
    RI  C_5, 4, 0                               ; 530F row 00  Inst03
    R   ___                                     ; 5311 row 01
    RI  C_5, 2, 0                               ; 5312 row 02  Inst01
    RI  C_5, 3, 0                               ; 5314 row 03  Inst02
    RI  C_5, 1, 0                               ; 5316 row 04  Inst00
    R   ___                                     ; 5318 row 05
    RI  C_5, 3, 0                               ; 5319 row 06  Inst02
    RI  C_5, 4, 0                               ; 531B row 07  Inst03
    R   ___                                     ; 531D row 08
    RI  C_5, 2, 0                               ; 531E row 09  Inst01
    RI  C_5, 4, 0                               ; 5320 row 10  Inst03
    RI  C_5, 2, 0                               ; 5322 row 11  Inst01
    RI  C_5, 1, 0                               ; 5324 row 12  Inst00
    R   ___                                     ; 5326 row 13
    RI  C_5, 4, 0                               ; 5327 row 14  Inst03
    RI  C_5, 1, 0                               ; 5329 row 15  Inst00
    RI  C_5, 4, 0                               ; 532B row 16  Inst03
    R   ___                                     ; 532D row 17
    RI  C_5, 5, 0                               ; 532E row 18  Inst04
    RI  C_5, 2, 0                               ; 5330 row 19  Inst01
    RI  C_5, 1, 0                               ; 5332 row 20  Inst00
    RI  C_5, 2, 0                               ; 5334 row 21  Inst01
    RI  C_5, 4, 0                               ; 5336 row 22  Inst03
    R   ___                                     ; 5338 row 23
    RI  C_5, 2, 0                               ; 5339 row 24  Inst01
    RI  C_5, 3, 0                               ; 533B row 25  Inst02
    RI  C_5, 4, 0                               ; 533D row 26  Inst03
    R   ___                                     ; 533F row 27
    RI  C_5, 1, 0                               ; 5340 row 28  Inst00
    RI  C_5, 4, 0                               ; 5342 row 29  Inst03
    RI  C_5, 1, 0                               ; 5344 row 30  Inst00
    RI  C_5, 1, 0                               ; 5346 row 31  Inst00
Track04:
    RI  D_2, 6, 0                               ; 5348 row 00  Inst05
    R   ___                                     ; 534A row 01
    RI  D_2, 6, 0                               ; 534B row 02  Inst05
    R   ___                                     ; 534D row 03
    R   ___                                     ; 534E row 04
    RI  D_2, 6, 0                               ; 534F row 05  Inst05
    R   ___                                     ; 5351 row 06
    R   ___                                     ; 5352 row 07
    RI  D_2, 6, 0                               ; 5353 row 08  Inst05
    R   ___                                     ; 5355 row 09
    RI  D_3, 6, 0                               ; 5356 row 10  Inst05
    RI  D_2, 6, 0                               ; 5358 row 11  Inst05
    R   ___                                     ; 535A row 12
    R   ___                                     ; 535B row 13
    RI  D_2, 6, 0                               ; 535C row 14  Inst05
    RI  D_3, 6, 0                               ; 535E row 15  Inst05
    RI  F_2, 6, 0                               ; 5360 row 16  Inst05
    R   ___                                     ; 5362 row 17
    RI  F_2, 6, 0                               ; 5363 row 18  Inst05
    R   ___                                     ; 5365 row 19
    R   ___                                     ; 5366 row 20
    RI  F_2, 6, 0                               ; 5367 row 21  Inst05
    R   ___                                     ; 5369 row 22
    R   ___                                     ; 536A row 23
    RI  E_2, 6, 0                               ; 536B row 24  Inst05
    R   ___                                     ; 536D row 25
    RI  E_3, 6, 0                               ; 536E row 26  Inst05
    RI  E_2, 6, 0                               ; 5370 row 27  Inst05
    R   ___                                     ; 5372 row 28
    R   ___                                     ; 5373 row 29
    RI  E_3, 6, 0                               ; 5374 row 30  Inst05
    RI  E_2, 6, 0                               ; 5376 row 31  Inst05
Track05:
    RI  C_3, 9, 0                               ; 5378 row 00  Inst08
    R   ___                                     ; 537A row 01
    R   ___                                     ; 537B row 02
    R   ___                                     ; 537C row 03
    R   ___                                     ; 537D row 04
    R   ___                                     ; 537E row 05
    R   ___                                     ; 537F row 06
    R   ___                                     ; 5380 row 07
    RI  C_3, 9, 0                               ; 5381 row 08  Inst08
    R   ___                                     ; 5383 row 09
    R   ___                                     ; 5384 row 10
    R   ___                                     ; 5385 row 11
    R   ___                                     ; 5386 row 12
    R   ___                                     ; 5387 row 13
    R   ___                                     ; 5388 row 14
    R   ___                                     ; 5389 row 15
    RI  C_3, 7, 0                               ; 538A row 16  Inst06
    R   ___                                     ; 538C row 17
    R   ___                                     ; 538D row 18
    R   ___                                     ; 538E row 19
    R   ___                                     ; 538F row 20
    R   ___                                     ; 5390 row 21
    R   ___                                     ; 5391 row 22
    R   ___                                     ; 5392 row 23
    RI  C_3, 8, 0                               ; 5393 row 24  Inst07
    R   ___                                     ; 5395 row 25
    R   ___                                     ; 5396 row 26
    R   ___                                     ; 5397 row 27
    R   ___                                     ; 5398 row 28
    R   ___                                     ; 5399 row 29
    R   ___                                     ; 539A row 30
    R   ___                                     ; 539B row 31
Track06:
    RI  C_3, 10, 0                              ; 539C row 00  Inst09
    R   ___                                     ; 539E row 01
    R   ___                                     ; 539F row 02
    R   ___                                     ; 53A0 row 03
    R   ___                                     ; 53A1 row 04
    R   ___                                     ; 53A2 row 05
    R   ___                                     ; 53A3 row 06
    R   ___                                     ; 53A4 row 07
    RI  C_3, 10, 0                              ; 53A5 row 08  Inst09
    R   ___                                     ; 53A7 row 09
    R   ___                                     ; 53A8 row 10
    R   ___                                     ; 53A9 row 11
    R   ___                                     ; 53AA row 12
    R   ___                                     ; 53AB row 13
    R   ___                                     ; 53AC row 14
    R   ___                                     ; 53AD row 15
    RI  C_3, 11, 0                              ; 53AE row 16  Inst10
    R   ___                                     ; 53B0 row 17
    R   ___                                     ; 53B1 row 18
    R   ___                                     ; 53B2 row 19
    R   ___                                     ; 53B3 row 20
    R   ___                                     ; 53B4 row 21
    R   ___                                     ; 53B5 row 22
    R   ___                                     ; 53B6 row 23
    RI  C_3, 11, 0                              ; 53B7 row 24  Inst10
    R   ___                                     ; 53B9 row 25
    R   ___                                     ; 53BA row 26
    R   ___                                     ; 53BB row 27
    R   ___                                     ; 53BC row 28
    R   ___                                     ; 53BD row 29
    R   ___                                     ; 53BE row 30
    R   ___                                     ; 53BF row 31
Track07:
    RI  C_6, 12, 0                              ; 53C0 row 00  Inst11
    R   ___                                     ; 53C2 row 01
    RI  C_6, 12, 0                              ; 53C3 row 02  Inst11
    R   ___                                     ; 53C5 row 03
    R   ___                                     ; 53C6 row 04
    RI  C_6, 12, 0                              ; 53C7 row 05  Inst11
    R   ___                                     ; 53C9 row 06
    R   ___                                     ; 53CA row 07
    RI  C_6, 12, 0                              ; 53CB row 08  Inst11
    R   ___                                     ; 53CD row 09
    RI  C_6, 12, 0                              ; 53CE row 10  Inst11
    RI  C_6, 12, 0                              ; 53D0 row 11  Inst11
    R   ___                                     ; 53D2 row 12
    R   ___                                     ; 53D3 row 13
    RI  C_6, 12, 0                              ; 53D4 row 14  Inst11
    RI  C_6, 12, 0                              ; 53D6 row 15  Inst11
    RI  C_6, 12, 0                              ; 53D8 row 16  Inst11
    R   ___                                     ; 53DA row 17
    RI  C_6, 12, 0                              ; 53DB row 18  Inst11
    R   ___                                     ; 53DD row 19
    R   ___                                     ; 53DE row 20
    RI  C_6, 12, 0                              ; 53DF row 21  Inst11
    R   ___                                     ; 53E1 row 22
    R   ___                                     ; 53E2 row 23
    RI  C_6, 12, 0                              ; 53E3 row 24  Inst11
    R   ___                                     ; 53E5 row 25
    RI  C_6, 12, 0                              ; 53E6 row 26  Inst11
    RI  C_6, 12, 0                              ; 53E8 row 27  Inst11
    R   ___                                     ; 53EA row 28
    R   ___                                     ; 53EB row 29
    RI  C_6, 12, 0                              ; 53EC row 30  Inst11
    RI  C_6, 12, 0                              ; 53EE row 31  Inst11
Track08:
    R   ___                                     ; 53F0 row 00
    R   ___                                     ; 53F1 row 01
    R   ___                                     ; 53F2 row 02
    R   ___                                     ; 53F3 row 03
    R   ___                                     ; 53F4 row 04
    R   ___                                     ; 53F5 row 05
    R   ___                                     ; 53F6 row 06
    R   ___                                     ; 53F7 row 07
    R   ___                                     ; 53F8 row 08
    R   ___                                     ; 53F9 row 09
    R   ___                                     ; 53FA row 10
    R   ___                                     ; 53FB row 11
    R   ___                                     ; 53FC row 12
    R   ___                                     ; 53FD row 13
    R   ___                                     ; 53FE row 14
    R   ___                                     ; 53FF row 15
    R   ___                                     ; 5400 row 16
    R   ___                                     ; 5401 row 17
    R   ___                                     ; 5402 row 18
    R   ___                                     ; 5403 row 19
    R   ___                                     ; 5404 row 20
    R   ___                                     ; 5405 row 21
    R   ___                                     ; 5406 row 22
    R   ___                                     ; 5407 row 23
    RI  A_3, 6, 0                               ; 5408 row 24  Inst05
    RI  A_2, 6, 0                               ; 540A row 25  Inst05
    R   ___                                     ; 540C row 26
    RI  A_2, 6, 0                               ; 540D row 27  Inst05
    R   ___                                     ; 540F row 28
    RI  A_2, 6, 0                               ; 5410 row 29  Inst05
    R   ___                                     ; 5412 row 30
    R   ___                                     ; 5413 row 31
Track09:
    R   ___                                     ; 5414 row 00
    R   ___                                     ; 5415 row 01
    R   ___                                     ; 5416 row 02
    R   ___                                     ; 5417 row 03
    R   ___                                     ; 5418 row 04
    R   ___                                     ; 5419 row 05
    R   ___                                     ; 541A row 06
    R   ___                                     ; 541B row 07
    R   ___                                     ; 541C row 08
    R   ___                                     ; 541D row 09
    R   ___                                     ; 541E row 10
    R   ___                                     ; 541F row 11
    R   ___                                     ; 5420 row 12
    R   ___                                     ; 5421 row 13
    R   ___                                     ; 5422 row 14
    R   ___                                     ; 5423 row 15
    R   ___                                     ; 5424 row 16
    R   ___                                     ; 5425 row 17
    R   ___                                     ; 5426 row 18
    R   ___                                     ; 5427 row 19
    R   ___                                     ; 5428 row 20
    R   ___                                     ; 5429 row 21
    R   ___                                     ; 542A row 22
    R   ___                                     ; 542B row 23
    RI  C_3, 12, 0                              ; 542C row 24  Inst11
    RI  C_3, 12, 0                              ; 542E row 25  Inst11
    R   ___                                     ; 5430 row 26
    RI  C_3, 12, 0                              ; 5431 row 27  Inst11
    R   ___                                     ; 5433 row 28
    RI  C_3, 12, 0                              ; 5434 row 29  Inst11
    R   ___                                     ; 5436 row 30
    R   ___                                     ; 5437 row 31
Track10:
    R   ___                                     ; 5438 row 00
    R   ___                                     ; 5439 row 01
    R   ___                                     ; 543A row 02
    R   ___                                     ; 543B row 03
    R   ___                                     ; 543C row 04
    R   ___                                     ; 543D row 05
    R   ___                                     ; 543E row 06
    R   ___                                     ; 543F row 07
    R   ___                                     ; 5440 row 08
    R   ___                                     ; 5441 row 09
    R   ___                                     ; 5442 row 10
    R   ___                                     ; 5443 row 11
    R   ___                                     ; 5444 row 12
    R   ___                                     ; 5445 row 13
    R   ___                                     ; 5446 row 14
    R   ___                                     ; 5447 row 15
    R   ___                                     ; 5448 row 16
    R   ___                                     ; 5449 row 17
    R   ___                                     ; 544A row 18
    R   ___                                     ; 544B row 19
    R   ___                                     ; 544C row 20
    R   ___                                     ; 544D row 21
    R   ___                                     ; 544E row 22
    R   ___                                     ; 544F row 23
    R   ___                                     ; 5450 row 24
    R   ___                                     ; 5451 row 25
    RI  C_3, 12, 0                              ; 5452 row 26  Inst11
    R   ___                                     ; 5454 row 27
    RI  C_3, 16, 0                              ; 5455 row 28  Inst15
    R   ___                                     ; 5457 row 29
    RI  C_3, 16, 0                              ; 5458 row 30  Inst15
    RI  C_3, 16, 0                              ; 545A row 31  Inst15
Track11:
    RF  ___, $F, $7                             ; 545C row 00  speed 7
    R   ___                                     ; 545E row 01
    R   ___                                     ; 545F row 02
    R   ___                                     ; 5460 row 03
    R   ___                                     ; 5461 row 04
    R   ___                                     ; 5462 row 05
    R   ___                                     ; 5463 row 06
    R   ___                                     ; 5464 row 07
    R   ___                                     ; 5465 row 08
    R   ___                                     ; 5466 row 09
    R   ___                                     ; 5467 row 10
    R   ___                                     ; 5468 row 11
    R   ___                                     ; 5469 row 12
    R   ___                                     ; 546A row 13
    R   ___                                     ; 546B row 14
    R   ___                                     ; 546C row 15
    R   ___                                     ; 546D row 16
    R   ___                                     ; 546E row 17
    R   ___                                     ; 546F row 18
    R   ___                                     ; 5470 row 19
    R   ___                                     ; 5471 row 20
    R   ___                                     ; 5472 row 21
    R   ___                                     ; 5473 row 22
    R   ___                                     ; 5474 row 23
    R   ___                                     ; 5475 row 24
    R   ___                                     ; 5476 row 25
    RI  C_3, 15, 0                              ; 5477 row 26  Inst14
    R   ___                                     ; 5479 row 27
    RI  C_3, 14, 0                              ; 547A row 28  Inst13
    R   ___                                     ; 547C row 29
    RI  C_3, 14, 0                              ; 547D row 30  Inst13
    RI  C_3, 14, 0                              ; 547F row 31  Inst13
    db $88, $00, $F0, $46, $4F, $B1, $FB, $0B, $00, $2F, $52, $F4, $0F, $E0, $F7, $FF; 5481
    db $0F, $82, $8D, $03, $F0, $AD, $5F, $07, $A0, $F8, $0E, $07, $B0, $F0, $BC, $04; 5491
    db $06, $6F, $F6, $F5, $7F, $4F, $B0, $FF, $B0, $1F, $63, $70, $E7, $6D, $90, $1A; 54A1
    db $04, $5F, $0F, $8D, $01, $04, $AC, $FC, $F5, $73, $4F, $EF, $D0, $F3, $2F, $AE; 54B1
    db $B0, $D6, $39, $B1, $84, $F0, $2B, $00, $40, $22, $34, $4B, $3C, $F9, $75, $0A; 54C1
    db $CF, $BF, $29, $3A, $7C, $B4, $D8, $D5, $B4, $0C, $AB, $A8, $AB, $38, $A1, $98; 54D1
    db $49, $7E, $30, $99, $5E, $CB, $D5, $42, $FA, $53, $CF, $7F, $94, $56, $BA, $9F; 54E1
    db $D9, $3D, $9A, $FA, $46, $FA, $F7, $F4, $40, $8C, $46, $81, $31, $55, $60, $41; 54F1
    db $37, $10, $80, $09, $05, $03, $8A, $70, $54, $CF, $28, $E7, $CE, $9F, $DC, $FB; 5501
    db $FF, $FF, $AF, $FF, $FD, $9F, $F5, $64, $BF, $A4, $44, $A4, $49, $E9, $A0, $21; 5511
    db $00, $36, $0A, $00, $04, $60, $03, $10, $03, $83, $40, $87, $87, $A9, $C7, $45; 5521
    db $65, $DD, $6E, $ED, $89, $8E, $7F, $F8, $E8, $89, $CC, $FA, $BA, $AD, $BE, $CA; 5531
    db $FC, $CC, $C5, $68, $F5, $D5, $CB, $56, $79, $68, $18, $AA, $8A, $97, $A0, $8C; 5541
    db $00, $C7, $60, $10, $36, $56, $04, $32, $08, $44, $40, $42, $A8, $35, $52, $BE; 5551
    db $D2, $50, $09, $BD, $A7, $66, $3F, $B9, $7E, $6D, $EF, $DF, $E8, $DE, $DD, $D8; 5561
    db $CB, $EA, $FD, $DA, $F9, $AB, $9D, $8B, $98, $C6, $7A, $75, $36, $20, $A3, $93; 5571
    db $1A, $82, $00, $27, $44, $05, $05, $40, $68, $75, $64, $53, $5A, $21, $84, $A4; 5581
    db $88, $7C, $E6, $8A, $4B, $9F, $F6, $6C, $8E, $DF, $DB, $79, $BB, $EF, $BE, $F7; 5591
    db $89, $47, $CE, $83, $55, $7C, $9A, $62, $03, $88, $48, $97, $55, $43, $64, $67; 55A1
    db $24, $38, $39, $43, $08, $5C, $16, $38, $28, $74, $28, $63, $BC, $A4, $77, $AF; 55B1
    db $7F, $AD, $A7, $9F, $7E, $C8, $86, $F9, $EF, $DF, $D5, $5C, $BF, $FC, $98, $CA; 55C1
    db $CC, $B6, $76, $88, $CA, $99, $6D, $72, $5D, $47, $81, $7B, $45, $23, $44, $77; 55D1
    db $23, $50, $26, $60, $51, $71, $30, $10, $13, $34, $31, $12, $44, $43, $30, $77; 55E1
    db $63, $34, $78, $BC, $C7, $45, $BC, $9A, $7C, $FD, $FA, $9A, $CD, $FD, $FD, $ED; 55F1
    db $BD, $DF, $FF, $DF, $CD, $BF, $EC, $AF, $ED, $89, $DA, $FC, $AA, $8C, $99, $79; 5601
    db $5A, $7B, $91, $65, $5A, $38, $20, $88, $73, $40, $22, $24, $14, $05, $80, $00; 5611
    db $05, $75, $14, $43, $30, $04, $26, $66, $59, $04, $74, $68, $19, $6B, $65, $6A; 5621
    db $47, $98, $97, $D8, $AA, $87, $BE, $DB, $59, $AA, $9D, $C9, $AD, $BB, $CC, $BE; 5631
    db $DD, $BB, $AB, $EE, $AF, $CB, $9B, $BF, $AC, $8B, $99, $F7, $BB, $BB, $97, $D8; 5641
    db $EC, $47, $96, $5A, $67, $96, $67, $48, $93, $44, $60, $67, $57, $48, $22, $63; 5651
    db $56, $10, $27, $43, $43, $23, $41, $32, $37, $53, $33, $45, $56, $27, $98, $28; 5661
    db $76, $5B, $76, $78, $99, $C7, $A9, $A8, $6B, $D8, $DB, $97, $AD, $BA; 5671

;; PCM sample 0: 1968 bytes = 3936 samples, 4-bit unsigned, high nibble first (used by Inst00)
Sample00:
    db $88, $5A, $99, $74, $86, $50, $3A, $08, $A0, $8A, $0C, $58, $D4, $B3, $C7, $87; 567F 
    db $8B, $57, $4F, $0A, $47, $93, $F0, $F0, $7C, $70, $00, $83, $FF, $BF, $83, $F3; 568F 
    db $0F, $87, $F8, $0F, $F0, $02, $00, $D8, $00, $C0, $00, $A0, $03, $F8, $00, $D0; 569F 
    db $00, $FF, $83, $AF, $FC, $07, $FF, $F9, $FF, $FF, $FF, $FF, $FF, $80, $5F, $F3; 56AF 
    db $04, $FF, $FF, $00, $3F, $F8, $27, $B0, $7F, $90, $00, $00, $00, $00, $00, $00; 56BF 
    db $00, $30, $00, $0B, $CF, $A4, $00, $75, $6F, $FF, $A2, $37, $AC, $30, $00, $10; 56CF 
    db $3C, $9B, $EF, $FF, $87, $FF, $FF, $FD, $CE, $FD, $FF, $FF, $FF, $FF, $FF, $FF; 56DF 
    db $FF, $FB, $DE, $FF, $FF, $FF, $FB, $9A, $B0, $0A, $89, $D5, $00, $02, $74, $10; 56EF 
    db $00, $00, $00, $06, $30, $03, $43, $56, $7F, $A8, $6C, $AC, $84, $AA, $00, $31; 56FF 
    db $00, $4C, $FD, $81, $11, $45, $78, $65, $68, $67, $7B, $DC, $50, $00, $13, $55; 570F 
    db $10, $7A, $C8, $00, $00, $03, $97, $40, $15, $9D, $94, $00, $4A, $94, $73, $00; 571F 
    db $07, $95, $00, $10, $69, $61, $23, $06, $DF, $FF, $90, $4C, $EF, $FF, $82, $00; 572F 
    db $07, $FF, $F8, $55, $35, $AD, $C8, $AF, $EE, $CA, $AF, $FF, $DB, $CF, $CF, $FF; 573F 
    db $FE, $A3, $00, $AF, $FB, $89, $A3, $6A, $DE, $68, $CF, $94, $7C, $DC, $56, $DF; 574F 
    db $FA, $DF, $FF, $FF, $B8, $BC, $FF, $CF, $FF, $B3, $7F, $FC, $EE, $BC, $FF, $85; 575F 
    db $7E, $97, $35, $53, $A8, $83, $00, $03, $7A, $83, $00, $00, $78, $00, $00, $00; 576F 
    db $68, $00, $07, $FE, $4B, $50, $00, $14, $99, $63, $86, $63, $15, $44, $86, $7C; 577F 
    db $80, $61, $01, $63, $64, $32, $10, $01, $44, $68, $80, $03, $7C, $93, $00, $17; 578F 
    db $B8, $27, $9E, $B3, $04, $CB, $4B, $9B, $FB, $BA, $A8, $65, $66, $FF, $CC, $99; 579F 
    db $3C, $EF, $FC, $37, $FF, $EF, $FF, $FF, $C9, $FF, $FF, $BC, $FF, $FF, $FF, $FA; 57AF 
    db $99, $8A, $FF, $FF, $F5, $7C, $CF, $D5, $AF, $FC, $9E, $83, $DB, $FA, $CA, $79; 57BF 
    db $31, $78, $6E, $FB, $BA, $84, $59, $CB, $A9, $BC, $A3, $2C, $FA, $9C, $B3, $B8; 57CF 
    db $44, $69, $4A, $80, $13, $00, $02, $40, $03, $00, $00, $05, $61, $39, $00, $03; 57DF 
    db $B4, $04, $00, $00, $10, $02, $00, $50, $00, $63, $00, $01, $00, $65, $00, $00; 57EF 
    db $00, $00, $14, $50, $03, $35, $9C, $40, $03, $63, $63, $02, $47, $FE, $D5, $05; 57FF 
    db $AF, $CA, $A7, $CE, $A7, $FF, $BE, $FC, $6C, $FF, $AF, $FB, $D8, $9F, $CC, $AA; 580F 
    db $A6, $CF, $F9, $47, $FC, $FF, $C7, $AF, $E8, $9A, $CF, $F8, $AD, $AF, $B7, $CF; 581F 
    db $FA, $FF, $CC, $8A, $CF, $DF, $EF, $EA, $8A, $B9, $CF, $AF, $FE, $C6, $BA, $CC; 582F 
    db $67, $D5, $5C, $FC, $FC, $FF, $CD, $FF, $FD, $FF, $FA, $FF, $BC, $FD, $57, $97; 583F 
    db $77, $46, $95, $50, $79, $63, $15, $06, $76, $04, $A5, $26, $66, $00, $3C, $56; 584F 
    db $84, $40, $00, $03, $45, $35, $03, $61, $23, $11, $00, $34, $04, $50, $00, $40; 585F 
    db $04, $53, $00, $34, $00, $03, $30, $51, $21, $00, $17, $80, $06, $10, $48, $33; 586F 
    db $44, $15, $43, $A6, $44, $12, $9E, $40, $65, $74, $66, $57, $49, $95, $77, $46; 587F 
    db $78, $15, $77, $A8, $78, $B8, $79, $35, $7D, $99, $55, $54, $7A, $FC, $7F, $A1; 588F 
    db $25, $CF, $FB, $94, $7F, $BA, $FD, $8F, $FA, $8D, $FD, $EB, $87, $9D, $EE, $CE; 589F 
    db $FF, $FF, $8B, $AF, $FF, $FF, $BD, $CF, $EF, $FF, $BC, $FF, $DC, $CA, $BF, $FC; 58AF 
    db $FF, $87, $FE, $8B, $FF, $A5, $C8, $FF, $8C, $8A, $F8, $47, $BE, $C8, $5B, $C9; 58BF 
    db $97, $79, $7E, $EC, $C8, $56, $DA, $BC, $96, $AC, $6F, $84, $7E, $87, $8C, $86; 58CF 
    db $BC, $76, $B5, $75, $6B, $78, $98, $09, $88, $66, $67, $86, $04, $B5, $02, $50; 58DF 
    db $36, $50, $04, $57, $05, $83, $03, $05, $43, $63, $00, $44, $95, $43, $02, $34; 58EF 
    db $85, $50, $00, $10, $17, $61, $17, $03, $78, $43, $11, $26, $65, $58, $61, $22; 58FF 
    db $64, $78, $68, $66, $60, $47, $76, $64, $10, $14, $45, $04, $30, $03, $65, $76; 590F 
    db $42, $4A, $47, $B3, $5A, $78, $67, $7C, $67, $69, $99, $C5, $33, $6C, $A9, $87; 591F 
    db $64, $97, $EF, $E9, $37, $6A, $B3, $7C, $E8, $6A, $9E, $B3, $9C, $84, $9A, $9B; 592F 
    db $86, $AB, $C8, $7C, $F6, $AF, $C6, $AA, $85, $AE, $96, $CE, $B8, $A9, $79, $CF; 593F 
    db $DF, $C6, $97, $9F, $C9, $A9, $DC, $CF, $FD, $AA, $AB, $AE, $F9, $AC, $A7, $9D; 594F 
    db $AC, $FE, $86, $CF, $8C, $F9, $7C, $FD, $B7, $BC, $BA, $AC, $88, $A8, $69, $CC; 595F 
    db $A6, $8A, $89, $78, $CC, $88, $A9, $9B, $7A, $97, $C8, $77, $98, $7F, $94, $77; 596F 
    db $66, $BC, $86, $67, $A6, $9C, $86, $AB, $BB, $D9, $49, $B7, $77, $56, $65, $44; 597F 
    db $78, $C8, $68, $49, $45, $9B, $84, $38, $44, $89, $95, $32, $07, $58, $33, $16; 598F 
    db $3A, $83, $29, $53, $25, $65, $64, $41, $39, $65, $45, $86, $64, $56, $34, $74; 599F 
    db $33, $13, $68, $24, $51, $48, $63, $22, $7B, $50, $31, $15, $44, $35, $50, $00; 59AF 
    db $14, $B6, $45, $17, $A8, $13, $76, $68, $66, $57, $73, $06, $53, $25, $56, $65; 59BF 
    db $33, $49, $98, $13, $78, $66, $79, $67, $CA, $7B, $AA, $8B, $49, $DD, $B8, $6B; 59CF 
    db $DB, $67, $99, $B9, $BD, $CB, $7C, $96, $37, $F9, $7D, $C8, $54, $64, $56, $77; 59DF 
    db $FD, $89, $99, $57, $9D, $C9, $78, $66, $DB, $8A, $CD, $A6, $68, $A8, $CF, $D8; 59EF 
    db $AD, $C6, $7C, $CB, $D9, $79, $CF, $FF, $E9, $86, $AF, $FF, $A9, $86, $7C, $FF; 59FF 
    db $D8, $85, $67, $DF, $DC, $83, $69, $B9, $DD, $C8, $74, $7B, $CB, $B9, $98, $7A; 5A0F 
    db $CA, $78, $9B, $83, $7B, $84, $57, $A8, $47, $7D, $86, $B6, $57, $6C, $B4, $46; 5A1F 
    db $66, $7B, $86, $96, $77, $57, $D8, $86, $7C, $B5, $24, $88, $64, $A9, $56, $48; 5A2F 
    db $9C, $B9, $87, $30, $38, $6A, $A9, $88, $41, $58, $96, $86, $66, $84, $31, $79; 5A3F 
    db $46, $A7, $64, $66, $83, $21, $49, $CB, $A8, $01, $37, $9B, $53, $26, $9A, $83; 5A4F 
    db $13, $47, $A8, $55, $76, $77, $65, $47, $AB, $63, $46, $79, $B8, $59, $86, $78; 5A5F 
    db $30, $14, $86, $BC, $A9, $32, $46, $AE, $B8, $67, $89, $CC, $66, $44, $69, $AD; 5A6F 
    db $DB, $75, $65, $76, $56, $87, $96, $46, $BD, $DC, $82, $25, $9C, $B8, $73, $39; 5A7F 
    db $CA, $88, $35, $66, $87, $97, $69, $A9, $A8, $93, $4B, $B7, $79, $86, $77, $52; 5A8F 
    db $6A, $BA, $84, $03, $79, $85, $63, $34, $46, $59, $A8, $33, $78, $89, $86, $77; 5A9F 
    db $A9, $55, $58, $77, $88, $7A, $A5, $7A, $65, $6A, $86, $44, $69, $CA, $CD, $84; 5AAF 
    db $78, $CC, $99, $B8, $78, $69, $CB, $98, $63, $47, $68, $BA, $99, $66, $77, $CC; 5ABF 
    db $A8, $69, $87, $96, $56, $7A, $85, $9B, $86, $35, $69, $9A, $B8, $46, $87, $AA; 5ACF 
    db $9B, $85, $7A, $AB, $89, $A8, $67, $CC, $AB, $A9, $6A, $CB, $97, $69, $CB, $DF; 5ADF 
    db $EB, $B8, $6A, $CF, $DC, $CB, $98, $AB, $A6, $BA, $B8, $69, $A9, $89, $94, $79; 5AEF 
    db $9A, $A6, $54, $59, $BB, $89, $64, $46, $8A, $78, $46, $86, $57, $BC, $95, $45; 5AFF 
    db $79, $C8, $68, $88, $69, $B9, $67, $BA, $47, $CB, $B6, $67, $B8, $A9, $89, $CC; 5B0F 
    db $B9, $7C, $B8, $57, $89, $9A, $88, $66, $48, $76, $58, $57, $98, $57, $76, $57; 5B1F 
    db $65, $56, $79, $A8, $44, $45, $67, $98, $42, $34, $55, $79, $65, $66, $88, $86; 5B2F 
    db $89, $85, $43, $78, $77, $87, $56, $84, $46, $84, $56, $67, $67, $87, $67, $89; 5B3F 
    db $B8, $55, $64, $67, $88, $A8, $22, $37, $66, $56, $75, $59, $84, $46, $69, $84; 5B4F 
    db $5A, $B8, $55, $57, $B9, $88, $75, $69, $67, $98, $54, $66, $87, $77, $56, $86; 5B5F 
    db $89, $98, $77, $56, $57, $68, $45, $67, $99, $67, $66, $84, $49, $CA, $94, $43; 5B6F 
    db $45, $79, $A9, $88, $43, $67, $55, $55, $57, $A9, $56, $66, $67, $A8, $78, $86; 5B7F 
    db $69, $BB, $B9, $89, $A9, $89, $B9, $78, $89, $CD, $CA, $96, $77, $67, $CD, $9A; 5B8F 
    db $BA, $89, $BB, $99, $A8, $67, $8C, $CB, $98, $9A, $87, $CA, $96, $67, $A9, $BE; 5B9F 
    db $DA, $86, $AA, $A9, $88, $57, $A9, $89, $C9, $45, $69, $9C, $97, $79, $87, $77; 5BAF 
    db $99, $88, $88, $97, $AC, $99, $B9, $67, $C9, $77, $B9, $9A, $B9, $86, $9B, $A9; 5BBF 
    db $89, $AC, $CC, $B8, $89, $AC, $86, $67, $8A, $98, $98, $56, $9C, $C9, $86, $67; 5BCF 
    db $BA, $79, $86, $7B, $86, $78, $98, $57, $A9, $65, $78, $54, $78, $85, $76, $55; 5BDF 
    db $78, $8A, $96, $57, $67, $66, $99, $84, $47, $78, $86, $44, $48, $77, $79, $56; 5BEF 
    db $45, $67, $78, $76, $43, $69, $88, $78, $84, $45, $47, $77, $77, $77, $75, $54; 5BFF 
    db $54, $78, $99, $A8, $63, $37, $A8, $56, $77, $76, $98, $77, $77, $64, $35, $BB; 5C0F 
    db $98, $78, $56, $66, $79, $96, $68, $76, $46, $87, $56, $76, $46, $87, $76, $77; 5C1F 
    db $78, $69, $65, $78, $65, $78, $95, $44, $89, $85, $67, $89, $87, $79, $88, $99; 5C2F 
    db $89, $9A, $9B, $BA, $77, $88, $CB, $88, $77, $AB, $CB, $A7, $8A, $BA, $A8, $99; 5C3F 
    db $86, $6A, $CB, $88, $57, $77, $A8, $77, $87, $89, $CC, $94, $44, $67, $87, $87; 5C4F 
    db $67, $89, $55, $89, $98, $84, $69, $87, $88, $99, $BA, $47, $AA, $97, $7A, $96; 5C5F 
    db $7A, $B9, $99, $85, $7B, $99, $B9, $87, $9E, $A9, $9B, $A6, $67, $CB, $93, $68; 5C6F 
    db $67, $86, $66, $77, $87, $99, $76, $76, $76, $45, $55, $45, $56, $65, $56, $57; 5C7F 
    db $AA, $88, $88, $86, $67, $87, $87, $76, $6A, $89, $98, $87, $99, $AA, $A9, $89; 5C8F 
    db $9A, $87, $78, $98, $98, $79, $86, $79, $98, $98, $89, $BB, $98, $98, $99, $88; 5C9F 
    db $9B, $99, $86, $67, $98, $86, $78, $99, $97, $87, $87, $78, $76, $66, $66, $78; 5CAF 
    db $77, $66, $89, $87, $79, $68, $86, $8A, $98, $99, $98, $46, $78, $A9, $87, $89; 5CBF 
    db $89, $AA, $87, $AA, $87, $87, $87, $86, $67, $89, $77, $79, $87, $67, $88, $88; 5CCF 
    db $89, $99, $86, $77, $67, $86, $66, $78, $87, $88, $77, $67, $98, $99, $99, $87; 5CDF 
    db $67, $77, $87, $78, $77, $78, $67, $78, $87, $88, $87, $78, $76, $79, $99, $79; 5CEF 
    db $86, $66, $66, $69, $88, $76, $79, $86, $67, $67, $99, $87, $87, $78, $AB, $BA; 5CFF 
    db $AA, $9A, $99, $86, $8A, $98, $88, $88, $76, $79, $B9, $77, $78, $67, $99, $79; 5D0F 
    db $96, $56, $79, $86, $67, $67, $76, $79, $98, $87, $77, $77, $67, $87, $78, $87; 5D1F 
    db $79, $98, $66, $67, $99, $98, $87, $67, $99, $87, $88, $88, $88, $89, $AA, $98; 5D2F 
    db $89, $89, $98, $88, $AB, $99, $AA, $99, $99, $98, $87, $77, $89, $98, $86, $66; 5D3F 
    db $79, $99, $87, $75, $56, $78, $9A, $86, $33, $66, $78, $87, $77, $87, $65, $79; 5D4F 
    db $87, $55, $67, $89, $87, $87, $76, $77, $9A, $99, $87, $66, $68, $A8, $67, $77; 5D5F 
    db $65, $7A, $98, $77, $67, $79, $98, $77, $88, $86, $67, $89, $86, $67, $77, $76; 5D6F 
    db $56, $65, $68, $77, $67, $76, $55, $56, $76, $67, $65, $67, $66, $77, $77, $88; 5D7F 
    db $86, $67, $76, $56, $78, $9A, $A7, $78, $87, $8A, $99, $86, $68, $98, $88, $98; 5D8F 
    db $66, $79, $98, $87, $79, $98, $75, $67, $76, $56, $79, $99, $85, $56, $76, $66; 5D9F 
    db $66, $78, $77, $67, $89, $A9, $98, $77, $77, $99, $87, $89, $88, $98, $88, $77; 5DAF 
    db $66, $9A, $A9, $87, $89, $86, $78, $99, $98, $79, $87, $67, $87, $67, $78, $75; 5DBF 
    db $67, $66, $77, $65, $56, $67, $77, $87, $65, $78, $76, $67, $76, $89, $99, $87; 5DCF 
    db $66, $79, $98, $99, $87, $88, $89, $99, $98, $88, $99, $99, $98, $66, $77, $99; 5DDF 
    db $AA, $96, $56, $78, $AA, $98, $77, $66, $66, $79, $AA, $87, $66, $68, $98, $77; 5DEF 
    db $77, $66, $69, $A9, $76, $66, $89, $87, $88, $65, $56, $89, $99, $87, $78, $99; 5DFF 
    db $99, $99, $98, $88, $88, $89, $99, $99, $87, $78, $9A, $88, $98, $79, $87, $67; 5E0F 
    db $89, $88, $76, $67, $88, $87, $77, $67, $88, $87, $77, $77, $67, $78, $88, $88; 5E1F 
    db $88, $88, $88, $88, $88, $88, $88, $78, $88, $88, $88, $88, $88, $88, $88; 5E2F

;; PCM sample 1: 112 bytes = 224 samples, 4-bit unsigned, high nibble first (used by Inst01)
Sample01:
    db $0B, $DA, $8C, $AF, $16, $00, $7A, $EE, $55, $A8, $9F, $DA, $90, $DC, $74, $85; 5E3E 
    db $81, $47, $88, $88, $94, $8C, $67, $3A, $DD, $A7, $47, $57, $64, $43, $3C, $27; 5E4E 
    db $99, $C9, $5C, $57, $36, $8C, $85, $75, $4B, $CA, $45, $5B, $A9, $9B, $7A, $BA; 5E5E 
    db $88, $67, $6B, $66, $88, $75, $59, $66, $88, $87, $55, $96, $87, $88, $89, $79; 5E6E 
    db $88, $97, $8A, $97, $96, $67, $86, $66, $77, $78, $99, $88, $87, $77, $78, $87; 5E7E 
    db $89, $87, $88, $88, $97, $88, $88, $87, $78, $77, $87, $88, $88, $87, $77, $77; 5E8E 
    db $78, $88, $77, $78, $88, $78, $87, $88, $88, $87, $78, $78, $88, $88, $88, $88; 5E9E 

;; PCM sample 2: 48 bytes = 96 samples, 4-bit unsigned, high nibble first (used by Inst02)
Sample02:
    db $29, $B5, $60, $C8, $B0, $52, $E3, $76, $B6, $B6, $CD, $45, $BD, $B8, $4D, $A7; 5EAE 
    db $57, $8A, $55, $89, $66, $79, $85, $59, $A8, $68, $8A, $76, $9A, $87, $79, $A6; 5EBE 
    db $68, $88, $66, $99, $76, $89, $86, $69, $A7, $68, $88, $87, $99, $87, $88, $97; 5ECE 
    db $89, $97, $77, $99, $78, $88            ; 5EDE

;; PCM sample 3: 832 bytes = 1664 samples, 4-bit unsigned, high nibble first (used by Inst03)
Sample03:
    db $77, $78, $9B, $CC, $A9, $75, $44, $67, $77, $88, $87, $78, $86, $F0, $AF, $2F; 5EE4 
    db $0A, $A5, $38, $F5, $2A, $1F, $0D, $82, $F8, $2F, $0F, $90, $F0, $F7, $0C, $2A; 5EF4 
    db $6B, $82, $9D, $2C, $0F, $64, $8A, $70, $6F, $07, $F0, $8F, $1D, $98, $95, $8C; 5F04 
    db $5F, $58, $AC, $59, $8C, $86, $95, $7A, $35, $78, $67, $60, $A3, $27, $26, $33; 5F14 
    db $56, $38, $37, $A5, $D3, $7C, $58, $C7, $9A, $B9, $CC, $BA, $BB, $FD, $8D, $AD; 5F24 
    db $AF, $7D, $98, $99, $77, $58, $55, $34, $44, $23, $21, $23, $20, $20, $11, $41; 5F34 
    db $06, $22, $65, $47, $67, $8A, $AA, $AD, $CB, $DF, $CD, $EC, $DE, $FD, $DF, $DE; 5F44 
    db $BF, $DC, $EC, $CA, $D8, $9B, $A5, $A6, $65, $55, $24, $32, $23, $01, $21, $10; 5F54 
    db $20, $12, $11, $02, $01, $23, $25, $35, $47, $49, $69, $8A, $AB, $BC, $DD, $ED; 5F64 
    db $EE, $FE, $FF, $FF, $FE, $ED, $EC, $EE, $EC, $CC, $BC, $CA, $8A, $A7, $89, $56; 5F74 
    db $67, $35, $52, $13, $12, $11, $00, $11, $01, $10, $00, $30, $31, $41, $33, $32; 5F84 
    db $55, $36, $66, $67, $88, $A8, $A9, $CB, $BD, $DD, $DF, $EF, $DF, $FF, $FF, $EE; 5F94 
    db $FF, $FD, $ED, $DD, $DB, $CC, $AA, $BB, $99, $98, $96, $76, $76, $64, $45, $42; 5FA4 
    db $43, $21, $20, $12, $11, $01, $00, $01, $10, $03, $12, $24, $14, $54, $36, $65; 5FB4 
    db $67, $69, $97, $AA, $B9, $BC, $CC, $CD, $BD, $EE, $EE, $FD, $DF, $FC, $EF, $ED; 5FC4 
    db $FC, $DE, $CB, $BD, $CC, $A9, $AA, $A8, $A6, $88, $66, $76, $35, $53, $53, $42; 5FD4 
    db $34, $22, $33, $22, $32, $33, $33, $33, $43, $54, $45, $55, $76, $56, $95, $88; 5FE4 
    db $98, $8B, $8A, $AA, $AC, $BC, $AC, $AD, $BB, $BB, $CC, $BB, $BB, $A9, $BA, $9B; 5FF4 
    db $99, $A8, $88, $87, $78, $75, $66, $46, $66, $45, $64, $55, $53, $63, $53, $55; 6004 
    db $44, $47, $35, $55, $47, $65, $66, $56, $77, $67, $96, $88, $97, $99, $98, $9A; 6014 
    db $99, $9B, $9B, $AB, $AB, $AA, $CA, $DA, $BB, $CA, $DB, $BA, $DB, $AC, $AB, $AA; 6024 
    db $BA, $9B, $9A, $A9, $89, $99, $78, $97, $68, $74, $77, $55, $64, $54, $43, $34; 6034 
    db $22, $33, $21, $32, $22, $31, $22, $21, $22, $22, $33, $32, $44, $35, $63, $56; 6044 
    db $66, $67, $86, $99, $78, $AA, $9A, $BB, $AC, $CB, $CD, $DC, $DD, $DE, $EE, $DF; 6054 
    db $DE, $DF, $CE, $DD, $DE, $CD, $CC, $CC, $CA, $DA, $AB, $AA, $AA, $89, $98, $98; 6064 
    db $78, $67, $66, $56, $56, $45, $35, $44, $42, $42, $33, $23, $22, $21, $31, $32; 6074 
    db $23, $22, $33, $23, $43, $35, $33, $55, $45, $55, $57, $56, $67, $77, $79, $78; 6084 
    db $88, $88, $99, $8A, $99, $AA, $B9, $BA, $AB, $AB, $AA, $C9, $BB, $BA, $CB, $BC; 6094 
    db $BC, $BB, $BC, $BC, $CB, $BC, $BA, $CC, $AB, $BA, $AB, $A9, $AA, $99, $99, $98; 60A4 
    db $89, $88, $87, $76, $86, $67, $65, $66, $64, $64, $55, $45, $44, $43, $44, $33; 60B4 
    db $33, $32, $33, $33, $33, $33, $44, $35, $34, $36, $45, $56, $46, $57, $58, $76; 60C4 
    db $68, $88, $89, $88, $A8, $A9, $AA, $9A, $A9, $BB, $AA, $BB, $AB, $BB, $BB, $BC; 60D4 
    db $AC, $CB, $BC, $AB, $CA, $AB, $BA, $AA, $B9, $AA, $A9, $99, $99, $98, $88, $88; 60E4 
    db $88, $77, $77, $76, $66, $66, $65, $65, $55, $54, $54, $55, $54, $54, $44, $54; 60F4 
    db $55, $55, $55, $56, $56, $56, $56, $66, $67, $67, $77, $77, $88, $88, $88, $89; 6104 
    db $89, $89, $99, $89, $99, $99, $99, $99, $98, $99, $89, $89, $99, $99, $88, $89; 6114 
    db $88, $99, $79, $88, $88, $78, $88, $88, $88, $88, $88, $98, $88, $88, $88, $87; 6124 
    db $88, $87, $88, $78, $87, $88, $77, $88, $77, $87, $77, $88, $78, $78, $87, $87; 6134 
    db $78, $77, $87, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $77; 6144 
    db $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $87, $88, $77, $88, $78, $87; 6154 
    db $88, $88, $88, $88, $88, $88, $88, $78, $97, $88, $88, $88, $88, $88, $88, $88; 6164 
    db $88, $88, $88, $88, $87, $88, $87, $88, $78, $87, $78, $77, $78, $77, $87, $77; 6174 
    db $87, $78, $77, $78, $77, $77, $77, $77, $77, $77, $78, $77, $78, $78, $77, $87; 6184 
    db $78, $78, $88, $78, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 6194 
    db $88, $78, $88, $88, $88, $88, $78, $87, $78, $88, $78, $77, $78, $77, $78, $77; 61A4 
    db $77, $78, $77, $78, $77, $77, $77, $77, $77, $77, $78, $77, $87, $77, $87, $88; 61B4 
    db $87, $88, $87, $88, $88, $97, $88, $87, $89, $88, $98, $88, $88, $88, $88, $88; 61C4 
    db $78, $88, $88, $87, $88, $78, $87, $78, $77, $78, $77, $77, $77, $77, $77, $77; 61D4 
    db $77, $77, $77, $77, $77, $77, $77, $77, $77, $77, $87, $87, $78, $87, $88, $88; 61E4 
    db $87, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88, $88; 61F4 
    db $88, $88, $88, $88, $78, $88, $78, $87, $87, $87, $88, $77, $78, $77, $77, $77; 6204 
    db $87, $78, $77, $87, $87, $88, $77, $88, $88, $87, $88, $88, $88, $88, $88, $88; 6214 
    db $88                                     ; 6224

;; PCM sample 4: 256 bytes = 512 samples, 4-bit unsigned, high nibble first (used by Inst04)
Sample04:
    db $79, $1A, $65, $D8, $A1, $27, $AF, $48, $22, $9F, $F3, $93, $3C, $EF, $82, $82; 6225 
    db $EF, $BB, $18, $58, $F9, $C3, $2C, $7E, $97, $61, $DA, $DB, $47, $47, $C8, $D4; 6235 
    db $45, $5A, $AC, $45, $55, $A9, $9A, $44, $57, $B9, $93, $54, $7C, $98, $54, $57; 6245 
    db $AB, $76, $36, $7A, $B7, $64, $77, $AA, $86, $66, $8A, $A8, $76, $6A, $9A, $87; 6255 
    db $66, $8A, $A8, $66, $77, $A9, $97, $77, $89, $A9, $86, $79, $9A, $88, $67, $88; 6265 
    db $A9, $87, $77, $99, $98, $77, $79, $99, $87, $78, $8A, $98, $77, $78, $99, $86; 6275 
    db $77, $99, $98, $76, $78, $99, $77, $67, $89, $98, $77, $78, $99, $87, $77, $98; 6285 
    db $98, $76, $78, $98, $87, $67, $89, $88, $77, $78, $98, $87, $77, $88, $97, $67; 6295 
    db $78, $98, $87, $77, $89, $88, $77, $88, $88, $77, $77, $88, $87, $77, $78, $88; 62A5 
    db $77, $77, $88, $88, $77, $88, $88, $87, $78, $88, $87, $87, $88, $88, $78, $87; 62B5 
    db $88, $88, $78, $78, $88, $87, $87, $88, $88, $87, $77, $88, $88, $77, $78, $88; 62C5 
    db $87, $77, $88, $88, $87, $88, $88, $78, $78, $88, $87, $88, $88, $78, $88, $87; 62D5 
    db $88, $88, $88, $78, $88, $87, $88, $78, $88, $88, $88, $88, $88, $78, $88, $88; 62E5 
    db $87, $88, $88, $88, $87, $88, $88, $78, $78, $88, $87, $88, $88, $88, $77, $88; 62F5 
    db $88, $87, $78, $88, $88, $77, $88, $98, $77, $78, $88, $87, $77, $88, $88, $77; 6305 
    db $78, $88, $87, $77, $88, $88, $77, $87, $88, $87, $78, $78, $88, $87, $78, $88; 6315 
    db $88, $77, $88                           ; 6325

;; PCM sample 5: 2288 bytes = 4576 samples, 4-bit unsigned, high nibble first (used by Inst16)
Sample05:
    db $88, $77, $78, $87, $77, $78, $87, $77, $78, $87, $77, $88, $78, $88, $78, $98; 6328 
    db $78, $98, $88, $88, $78, $88, $76, $78, $77, $76, $77, $87, $78, $88, $88, $88; 6338 
    db $88, $88, $88, $88, $77, $88, $87, $77, $87, $77, $77, $77, $77, $93, $B7, $3C; 6348 
    db $73, $B8, $59, $78, $A6, $89, $88, $88, $98, $89, $88, $88, $87, $77, $78, $57; 6358 
    db $85, $77, $56, $96, $68, $88, $87, $88, $89, $97, $89, $88, $88, $87, $78, $87; 6368 
    db $88, $87, $78, $77, $77, $68, $87, $67, $78, $86, $78, $87, $88, $88, $78, $98; 6378 
    db $88, $88, $78, $88, $88, $88, $78, $87, $87, $78, $77, $76, $77, $77, $77, $77; 6388 
    db $88, $87, $78, $88, $87, $88, $88, $88, $88, $88, $87, $88, $88, $88, $87, $77; 6398 
    db $77, $77, $77, $78, $77, $88, $78, $77, $87, $88, $78, $88, $88, $88, $88, $88; 63A8 
    db $88, $88, $78, $88, $88, $77, $87, $77, $77, $77, $87, $78, $87, $87, $77, $87; 63B8 
    db $88, $78, $88, $88, $88, $88, $88, $88, $87, $88, $87, $88, $88, $88, $78, $88; 63C8 
    db $77, $78, $88, $78, $87, $88, $78, $87, $78, $88, $88, $88, $87, $88, $88, $87; 63D8 
    db $88, $87, $78, $88, $77, $88, $88, $77, $87, $87, $78, $87, $87, $88, $78, $87; 63E8 
    db $73, $F8, $0B, $C2, $9C, $36, $C7, $52, $F8, $0C, $F0, $AE, $45, $B8, $59, $86; 63F8 
    db $79, $87, $84, $8B, $54, $A6, $78, $96, $79, $78, $96, $72, $DD, $26, $E4, $6D; 6408 
    db $81, $9D, $18, $BB, $1A, $B1, $BA, $73, $AB, $66, $B4, $6B, $6B, $49, $76, $85; 6418 
    db $99, $27, $E5, $0E, $D0, $AD, $3A, $A5, $8B, $76, $99, $76, $98, $58, $85, $88; 6428 
    db $76, $88, $57, $C6, $3B, $B4, $7C, $86, $88, $86, $85, $A8, $56, $A6, $79, $94; 6438 
    db $7A, $77, $A5, $7B, $95, $6A, $75, $96, $55, $5F, $00, $FB, $0F, $A5, $E6, $69; 6448 
    db $B9, $27, $E4, $2B, $95, $87, $79, $96, $59, $A9, $44, $F9, $19, $A3, $8E, $32; 6458 
    db $DA, $46, $AA, $57, $B7, $78, $67, $97, $68, $87, $89, $66, $B8, $49, $B4, $6E; 6468 
    db $52, $98, $96, $23, $FF, $00, $F7, $0B, $6D, $A4, $75, $BC, $03, $D9, $45, $7B; 6478 
    db $94, $7B, $A7, $58, $A9, $43, $7E, $80, $6F, $81, $9D, $27, $F7, $0A, $F6, $18; 6488 
    db $A7, $64, $8B, $85, $5B, $B6, $58, $A9, $64, $89, $76, $49, $98, $55, $D7, $04; 6498 
    db $EF, $00, $FC, $09, $5A, $B6, $64, $9D, $32, $BB, $75, $7B, $96, $77, $8A, $75; 64A8 
    db $68, $A5, $3A, $A5, $57, $D9, $0A, $E4, $5C, $93, $78, $98, $37, $8A, $F0, $5F; 64B8 
    db $54, $A7, $B8, $66, $5C, $90, $7C, $75, $89, $87, $94, $8C, $34, $3D, $F0, $0F; 64C8 
    db $76, $83, $CA, $87, $37, $D8, $36, $B9, $68, $97, $89, $78, $88, $85, $89, $68; 64D8 
    db $75, $98, $78, $79, $84, $9C, $36, $95, $B8, $26, $55, $F7, $0F, $F8, $A2, $8D; 64E8 
    db $8A, $43, $B9, $43, $9C, $45, $A8, $98, $77, $69, $92, $BA, $0A, $96, $95, $85; 64F8 
    db $BC, $08, $B9, $85, $98, $9B, $35, $B8, $86, $78, $8A, $63, $9C, $57, $75, $87; 6508 
    db $9A, $47, $A7, $88, $87, $99, $57, $98, $77, $77, $88, $78, $88, $78, $77, $88; 6518 
    db $68, $86, $88, $77, $87, $88, $78, $88, $88, $78, $87, $88, $78, $87, $78, $78; 6528 
    db $88, $77, $88, $78, $87, $77, $88, $88, $78, $88, $87, $78, $87, $78, $87, $88; 6538 
    db $88, $87, $88, $87, $77, $88, $78, $87, $88, $88, $88, $88, $88, $77, $88, $88; 6548 
    db $77, $88, $87, $78, $88, $87, $78, $88, $87, $88, $88, $87, $78, $88, $87, $78; 6558 
    db $88, $87, $78, $87, $78, $87, $78, $88, $87, $78, $78, $87, $88, $88, $87, $88; 6568 
    db $88, $87, $88, $87, $77, $88, $77, $88, $87, $78, $88, $87, $78, $87, $88, $77; 6578 
    db $78, $88, $77, $88, $77, $77, $88, $77, $88, $87, $87, $88, $88, $78, $88, $77; 6588 
    db $88, $88, $78, $78, $87, $88, $77, $87, $88, $77, $77, $88, $77, $88, $88, $77; 6598 
    db $88, $87, $88, $88, $87, $88, $88, $88, $88, $87, $88, $88, $88, $88, $87, $78; 65A8 
    db $88, $77, $78, $88, $77, $88, $78, $88, $77, $88, $88, $77, $88, $88, $78, $87; 65B8 
    db $88, $88, $78, $88, $88, $77, $88, $87, $87, $78, $88, $88, $78, $87, $88, $87; 65C8 
    db $78, $87, $88, $77, $88, $87, $88, $87, $87, $88, $87, $88, $78, $88, $88, $77; 65D8 
    db $99, $76, $68, $98, $66, $89, $87, $77, $88, $77, $78, $88, $87, $78, $88, $67; 65E8 
    db $A9, $76, $69, $98, $67, $89, $87, $88, $87, $78, $87, $88, $88, $77, $89, $76; 65F8 
    db $88, $88, $88, $77, $89, $77, $78, $98, $76, $79, $87, $78, $78, $86, $88, $68; 6608 
    db $87, $78, $88, $67, $89, $86, $68, $98, $77, $79, $87, $78, $88, $77, $88, $78; 6618 
    db $86, $79, $87, $78, $79, $86, $78, $98, $68, $78, $87, $77, $88, $78, $77, $78; 6628 
    db $78, $77, $88, $79, $68, $88, $88, $77, $88, $87, $78, $98, $77, $87, $77, $7A; 6638 
    db $85, $88, $88, $79, $64, $D9, $45, $AA, $68, $84, $B4, $8A, $49, $66, $D4, $4B; 6648 
    db $7C, $15, $EB, $0A, $97, $E1, $92, $9F, $25, $79, $6B, $B5, $0B, $F6, $34, $7A; 6658 
    db $F5, $0A, $7B, $F0, $79, $2E, $84, $42, $8F, $A0, $09, $FF, $43, $5A, $FC, $63; 6668 
    db $6A, $EC, $12, $68, $D7, $30, $58, $8A, $91, $09, $FD, $52, $4D, $FB, $63, $68; 6678 
    db $CD, $53, $48, $8D, $62, $3A, $9B, $67, $65, $9A, $A9, $36, $98, $96, $45, $10; 6688 
    db $9F, $90, $07, $FF, $B3, $4B, $FE, $B5, $39, $DB, $62, $27, $B8, $31, $59, $A8; 6698 
    db $00, $8F, $F2, $05, $EF, $D4, $16, $DF, $B3, $16, $CD, $82, $39, $CB, $73, $5A; 66A8 
    db $B8, $76, $54, $7B, $91, $04, $30, $BF, $40, $4E, $FF, $50, $AF, $FF, $90, $2A; 66B8 
    db $DC, $40, $0B, $C7, $52, $39, $CC, $82, $2B, $E6, $26, $87, $57, $97, $8A, $AB; 66C8 
    db $87, $BE, $97, $88, $89, $97, $33, $9B, $74, $44, $56, $50, $0F, $F0, $05, $FF; 66D8 
    db $E0, $4B, $DF, $F2, $05, $BF, $B0, $08, $CD, $A4, $28, $CF, $C0, $09, $D9, $20; 66E8 
    db $00, $FF, $20, $0F, $FF, $33, $4B, $FF, $00, $2D, $F8, $02, $6B, $FB, $20, $2B; 66F8 
    db $90, $CE, $04, $BB, $F5, $0E, $C3, $AC, $66, $45, $B7, $3A, $84, $AC, $B8, $8B; 6708 
    db $94, $35, $85, $00, $7F, $C0, $37, $FF, $A7, $10, $FF, $50, $03, $FF, $00, $2D; 6718 
    db $FF, $50, $0B, $F5, $03, $66, $BA, $56, $AF, $C5, $7C, $B4, $24, $89, $65, $36; 6728 
    db $DF, $B6, $6A, $A9, $42, $31, $0D, $F0, $09, $CF, $F3, $91, $5F, $B0, $00, $DF; 6738 
    db $40, $6C, $EE, $93, $3B, $F8, $00, $BE, $76, $24, $CF, $D2, $1B, $F9, $53, $48; 6748 
    db $B9, $53, $7E, $C7, $68, $86, $54, $50, $0F, $F0, $1C, $FF, $64, $70, $9F, $50; 6758 
    db $09, $FB, $37, $79, $DA, $A4, $09, $B4, $87, $4B, $B9, $A8, $98, $37, $96, $57; 6768 
    db $86, $8C, $A8, $48, $C6, $76, $96, $06, $35, $2D, $F0, $0F, $FF, $60, $60, $7F; 6778 
    db $50, $1E, $FC, $57, $79, $D8, $00, $38, $EE, $00, $EF, $F7, $06, $75, $B7, $01; 6788 
    db $AF, $B7, $8A, $98, $B8, $24, $75, $39, $50, $A4, $FF, $02, $F7, $D6, $22, $0B; 6798 
    db $F4, $39, $DF, $A9, $83, $7B, $40, $08, $F4, $49, $AF, $D1, $54, $9D, $32, $33; 67A8 
    db $CF, $84, $8C, $D9, $79, $65, $A2, $00, $0F, $83, $F3, $0F, $E8, $30, $63, $8D; 67B8 
    db $10, $9F, $F9, $67, $6B, $C1, $03, $FD, $26, $85, $AF, $20, $E9, $3A, $A9, $96; 67C8 
    db $86, $5C, $A3, $47, $BA, $B6, $00, $2F, $40, $F6, $6F, $8B, $01, $F2, $3C, $76; 67D8 
    db $7E, $E6, $99, $47, $60, $5B, $74, $8F, $A8, $D3, $23, $BA, $08, $C5, $BB, $8A; 67E8 
    db $58, $A5, $57, $68, $95, $00, $FC, $0F, $82, $F8, $B0, $0F, $33, $D5, $6A, $BB; 67F8 
    db $78, $A6, $55, $13, $F7, $0E, $D8, $F8, $56, $7A, $20, $6B, $88, $B9, $7E, $B6; 6808 
    db $83, $5A, $65, $00, $FF, $0F, $C4, $F9, $74, $1C, $40, $98, $6A, $DB, $7D, $B5; 6818 
    db $86, $00, $F6, $0D, $F6, $FD, $78, $BD, $10, $75, $55, $69, $8D, $F6, $AB, $5C; 6828 
    db $90, $00, $EB, $08, $E7, $FE, $67, $AC, $52, $44, $67, $76, $7D, $D6, $C9, $08; 6838 
    db $F1, $0C, $B3, $C8, $2B, $FD, $33, $C9, $76, $15, $98, $76, $89, $9D, $A4, $59; 6848 
    db $A8, $34, $88, $B5, $49, $BA, $86, $6A, $B7, $36, $98, $77, $64, $2A, $F2, $0D; 6858 
    db $C6, $E7, $0C, $F8, $35, $98, $89, $23, $9A, $96, $55, $9D, $A6, $66, $AD, $92; 6868 
    db $49, $B8, $67, $58, $A8, $67, $87, $78, $A6, $87, $77, $A7, $48, $96, $59, $85; 6878 
    db $98, $58, $B8, $67, $89, $99, $65, $9A, $86, $67, $89, $85, $78, $78, $86, $6A; 6888 
    db $97, $68, $78, $97, $57, $98, $87, $67, $89, $76, $88, $88, $76, $89, $76, $69; 6898 
    db $87, $85, $7A, $97, $68, $98, $98, $79, $A8, $66, $88, $68, $66, $A6, $49, $A6; 68A8 
    db $79, $68, $A7, $57, $A7, $77, $87, $8A, $76, $8A, $77, $87, $47, $A5, $34, $7A; 68B8 
    db $78, $43, $DD, $85, $7C, $CA, $75, $7C, $B5, $27, $B8, $65, $55, $B8, $3A, $56; 68C8 
    db $CB, $47, $B5, $8B, $83, $7B, $77, $A7, $49, $C7, $78, $79, $A5, $55, $58, $21; 68D8 
    db $B8, $37, $9B, $AB, $86, $DE, $75, $6A, $96, $65, $69, $85, $6A, $74, $C7, $5D; 68E8 
    db $70, $9F, $12, $D8, $38, $A4, $9D, $53, $DD, $55, $9A, $A6, $5A, $74, $83, $69; 68F8 
    db $21, $AE, $42, $DD, $79, $98, $AB, $64, $AB, $44, $8A, $75, $69, $A9, $64, $9F; 6908 
    db $40, $DC, $09, $B0, $6C, $62, $EB, $18, $F7, $5B, $85, $AA, $56, $9A, $73, $7A; 6918 
    db $82, $48, $78, $94, $6B, $E5, $5E, $85, $B9, $57, $95, $5C, $73, $9A, $78, $96; 6928 
    db $9B, $26, $F3, $0D, $90, $CB, $07, $F5, $3D, $A6, $B9, $5C, $A3, $8B, $55, $B5; 6938 
    db $6B, $43, $C9, $08, $A0, $CD, $08, $F6, $0F, $91, $CA, $39, $94, $7C, $63, $B7; 6948 
    db $78, $88, $89, $78, $B2, $7D, $25, $A4, $0D, $C0, $6F, $34, $F6, $8F, $46, $F8; 6958 
    db $39, $B3, $6B, $36, $C3, $4C, $72, $AB, $37, $BA, $2A, $C4, $A6, $A7, $69, $78; 6968 
    db $86, $88, $87, $79, $86, $7B, $87, $98, $97, $3E, $62, $97, $32, $F6, $0D, $C1; 6978 
    db $CA, $4F, $A3, $DE, $46, $E7, $4A, $56, $85, $66, $68, $66, $96, $78, $9C, $0C; 6988 
    db $F0, $9C, $84, $88, $88, $57, $A4, $79, $77, $78, $88, $96, $9B, $55, $AB, $36; 6998 
    db $84, $35, $E2, $0E, $75, $B5, $9D, $67, $FA, $4A, $C7, $77, $89, $64, $78, $36; 69A8 
    db $84, $78, $59, $77, $B3, $DB, $1E, $C2, $AC, $68, $86, $A7, $2B, $92, $8A, $57; 69B8 
    db $86, $8A, $58, $B5, $6C, $45, $B0, $8F, $06, $F0, $7D, $2B, $C3, $AE, $56, $E9; 69C8 
    db $69, $88, $A5, $7A, $65, $58, $72, $8A, $26, $7D, $51, $F5, $5D, $59, $C3, $8E; 69D8 
    db $55, $C6, $6C, $56, $A6, $79, $68, $86, $87, $67, $87, $47, $46, $D0, $6F, $0A; 69E8 
    db $94, $F7, $5E, $97, $AA, $89, $86, $A9, $59, $85, $86, $68, $65, $77, $56, $7B; 69F8 
    db $07, $F1, $6E, $67, $97, $A9, $59, $D5, $7C, $58, $A6, $89, $59, $A4, $6C, $44; 6A08 
    db $B3, $68, $0F, $40, $F6, $0F, $47, $E3, $8F, $74, $CB, $69, $97, $B7, $5B, $84; 6A18 
    db $88, $76, $68, $76, $74, $9B, $0E, $D0, $DD, $09, $A4, $B8, $5B, $95, $AA, $69; 6A28 
    db $98, $88, $8A, $86, $97, $59, $56, $82, $99, $0A, $93, $C4, $7D, $28, $D7, $69; 6A38 
    db $A8, $88, $7B, $84, $B8, $59, $87, $87, $89, $76, $96, $96, $58, $67, $58, $93; 6A48 
    db $A9, $4A, $88, $97, $98, $98, $8A, $68, $B7, $79, $86, $69, $72, $99, $28, $A4; 6A58 
    db $89, $69, $88, $98, $87, $89, $77, $88, $87, $88, $78, $78, $87, $78, $7A, $74; 6A68 
    db $99, $62, $9C, $08, $A3, $B6, $6D, $76, $AB, $76, $B9, $69, $87, $96, $6A, $73; 6A78 
    db $89, $64, $8A, $48, $86, $98, $88, $99, $6A, $A5, $88, $88, $67, $97, $59, $86; 6A88 
    db $89, $88, $88, $88, $87, $2F, $40, $F2, $0F, $0B, $94, $C7, $B6, $8F, $58, $B6; 6A98 
    db $96, $8B, $28, $92, $B5, $3D, $55, $A5, $D6, $2F, $91, $BB, $66, $98, $77, $78; 6AA8 
    db $77, $78, $96, $89, $69, $85, $9A, $67, $A9, $68, $32, $F0, $0F, $20, $F3, $B8; 6AB8 
    db $6A, $8E, $26, $F5, $5B, $78, $76, $96, $48, $94, $5A, $65, $C5, $5E, $72, $BF; 6AC8 
    db $41, $FA, $1A, $88, $A3, $7B, $63, $8C, $45, $B8, $58, $96, $8A, $66, $A9, $32; 6AD8 
    db $FA, $0C, $F0, $8A, $88, $89, $6B, $A2, $BC, $36, $B9, $46, $B7, $58, $77, $68; 6AE8 
    db $77, $88, $69, $A5, $7B, $86, $88, $97, $5A, $A4, $5B, $A4, $6B, $85, $89, $87; 6AF8 
    db $88, $43, $F4, $0F, $80, $CA, $86, $9A, $6D, $74, $D9, $38, $B8, $37, $B5, $78; 6B08 
    db $59, $96, $78, $76, $B4, $6C, $35, $C6, $69, $88, $6A, $96, $8A, $77, $89, $87; 6B18 
    db $78, $87, $77, $88, $77, $87, $77, $86, $88, $68, $97, $78, $88, $78, $87, $78; 6B28 
    db $87, $78, $88, $77, $88, $86, $89, $87, $89, $87, $87, $78, $77, $78, $87, $88; 6B38 
    db $78, $87, $87, $67, $69, $83, $8B, $66, $89, $87, $98, $88, $78, $88, $77, $98; 6B48 
    db $67, $98, $77, $88, $78, $78, $87, $78, $86, $68, $87, $67, $98, $67, $98, $77; 6B58 
    db $88, $88, $78, $87, $78, $88, $77, $88, $87, $78, $88, $87, $78, $87, $88, $87; 6B68 
    db $78, $87, $88, $88, $77, $88, $87, $88, $78, $77, $88, $77, $88, $87, $77, $88; 6B78 
    db $77, $88, $78, $88, $78, $88, $88, $87, $87, $77, $87, $78, $88, $77, $88, $87; 6B88 
    db $88, $88, $88, $87, $77, $88, $77, $77, $78, $88, $77, $88, $88, $77, $77, $88; 6B98 
    db $76, $89, $86, $88, $88, $78, $88, $77, $88, $77, $78, $78, $78, $77, $89, $77; 6BA8 
    db $88, $88, $77, $87, $88, $88, $87, $88, $88, $77, $87, $78, $87, $87, $78, $77; 6BB8 
    db $78, $87, $77, $78, $87, $87, $77, $89, $77, $88, $87, $88, $87, $88, $77, $87; 6BC8 
    db $88, $78, $89, $76, $89, $87, $78, $88, $87, $78, $88, $77, $87, $77, $87, $77; 6BD8 
    db $87, $78, $88, $77, $88, $87, $88, $87, $78, $88, $76, $88, $88, $77, $88, $77; 6BE8 
    db $88, $87, $68, $87, $87, $78, $87, $77, $88, $77, $78, $88, $87, $88, $87, $78; 6BF8 
    db $87, $77, $88, $77, $77, $87, $88, $77, $88, $87, $78, $88, $77, $88, $88, $77; 6C08 
    db $78, $87, $88, $88, $78, $77, $87, $87, $78, $78, $87, $88, $88; 6C18
SFXInstTable:
    dw SFXInst00                                 ; 6C25  SFX instrument 1 (ch1)
    dw SFXInst01                                 ; 6C27  SFX instrument 2 (ch4)
    dw SFXInst02                                 ; 6C29  SFX instrument 3 (ch1)
    dw SFXInst03                                 ; 6C2B  SFX instrument 4 (unused)
    dw SFXInst04                                 ; 6C2D  SFX instrument 5 (ch4)
    dw SFXInst05                                 ; 6C2F  SFX instrument 6 (ch1)
    dw SFXInst06                                 ; 6C31  SFX instrument 7 (ch4)
    dw SFXInst07                                 ; 6C33  SFX instrument 8 (unused)
SFXInst00:
    db $10                                       ; 6C35 square, 16 steps
    db $01                                       ; playlist speed
    db $A0                                       ; NR12 envelope
    db $6A, $00, $C2                             ; step 0: F-5  duty 2
    db $65, $00, $00                             ; step 1: C-5
    db $60, $00, $46                             ; step 2: G-4  vol 6
    db $54, $00, $45                             ; step 3: G-3  vol 5
    db $52, $00, $44                             ; step 4: F-3  vol 4
    db $51, $00, $43                             ; step 5: E-3  vol 3
    db $4F, $00, $42                             ; step 6: D-3  vol 2
    db $4D, $00, $41                             ; step 7: C-3  vol 1
    db $00, $00, $40                             ; step 8: -  vol 0
    db $00, $00, $00                             ; step 9: -
    db $00, $00, $00                             ; step 10: -
    db $00, $00, $00                             ; step 11: -
    db $00, $00, $00                             ; step 12: -
    db $00, $00, $00                             ; step 13: -
    db $00, $00, $00                             ; step 14: -
    db $00, $00, $00                             ; step 15: -
SFXInst01:
    db $12                                       ; 6C68 noise, 18 steps
    db $01                                       ; playlist speed
    db $C3                                       ; NR42 envelope
    db $59, $00, $00                             ; step 0: C-4
    db $65, $00, $00                             ; step 1: C-5
    db $5D, $00, $00                             ; step 2: E-4
    db $69, $00, $00                             ; step 3: E-5
    db $6C, $00, $00                             ; step 4: G-5
    db $78, $00, $00                             ; step 5: G-6
    db $6E, $00, $00                             ; step 6: A-5
    db $62, $00, $00                             ; step 7: A-4
    db $6A, $00, $00                             ; step 8: F-5
    db $5E, $00, $00                             ; step 9: F-4
    db $67, $00, $00                             ; step 10: D-5
    db $5B, $00, $00                             ; step 11: D-4
    db $58, $00, $00                             ; step 12: B-3
    db $4C, $00, $00                             ; step 13: B-2
    db $52, $00, $00                             ; step 14: F-3
    db $46, $00, $00                             ; step 15: F-2
    db $4F, $00, $00                             ; step 16: D-3
    db $43, $00, $00                             ; step 17: D-2
SFXInst02:
    db $14                                       ; 6CA1 square, 20 steps
    db $01                                       ; playlist speed
    db $F1                                       ; NR12 envelope
    db $59, $44, $C0                             ; step 0: C-4  vol 4, duty 0
    db $5D, $48, $00                             ; step 1: E-4  vol 8
    db $62, $4A, $00                             ; step 2: A-4  vol 10
    db $69, $4B, $00                             ; step 3: E-5  vol 11
    db $6C, $4C, $00                             ; step 4: G-5  vol 12
    db $6E, $4D, $00                             ; step 5: A-5  vol 13
    db $62, $C2, $48                             ; step 6: A-4  duty 2, vol 8
    db $6E, $00, $00                             ; step 7: A-5
    db $7A, $00, $00                             ; step 8: A-6
    db $6E, $00, $00                             ; step 9: A-5
    db $62, $00, $00                             ; step 10: A-4
    db $56, $00, $00                             ; step 11: A-3
    db $7A, $00, $44                             ; step 12: A-6  vol 4
    db $6E, $00, $00                             ; step 13: A-5
    db $6E, $00, $00                             ; step 14: A-5
    db $62, $00, $00                             ; step 15: A-4
    db $62, $00, $00                             ; step 16: A-4
    db $56, $00, $00                             ; step 17: A-3
    db $56, $00, $00                             ; step 18: A-3
    db $4D, $00, $00                             ; step 19: C-3
SFXInst03:
    db $0E                                       ; 6CE0 square, 14 steps
    db $01                                       ; playlist speed
    db $50                                       ; NR12 envelope
    db $00, $40, $C2                             ; step 0: -  vol 0, duty 2
    db $00, $00, $00                             ; step 1: -
    db $70, $00, $C2                             ; step 2: B-5  duty 2
    db $6C, $00, $00                             ; step 3: G-5
    db $69, $00, $00                             ; step 4: E-5
    db $70, $C1, $44                             ; step 5: B-5  duty 1, vol 4
    db $6C, $00, $00                             ; step 6: G-5
    db $69, $00, $00                             ; step 7: E-5
    db $70, $C0, $42                             ; step 8: B-5  duty 0, vol 2
    db $6C, $00, $00                             ; step 9: G-5
    db $69, $00, $00                             ; step 10: E-5
    db $00, $00, $40                             ; step 11: -  vol 0
    db $00, $00, $00                             ; step 12: -
    db $00, $00, $00                             ; step 13: -
SFXInst04:
    db $1F                                       ; 6D0D noise, 31 steps
    db $09                                       ; playlist speed
    db $F0                                       ; NR42 envelope
    db $41, $00, $41                             ; step 0: C-2  vol 1
    db $42, $00, $42                             ; step 1: C#2  vol 2
    db $43, $00, $43                             ; step 2: D-2  vol 3
    db $44, $00, $44                             ; step 3: D#2  vol 4
    db $45, $00, $45                             ; step 4: E-2  vol 5
    db $46, $00, $46                             ; step 5: F-2  vol 6
    db $47, $00, $48                             ; step 6: F#2  vol 8
    db $48, $00, $4A                             ; step 7: G-2  vol 10
    db $49, $00, $4B                             ; step 8: G#2  vol 11
    db $4A, $00, $4C                             ; step 9: A-2  vol 12
    db $4B, $00, $4D                             ; step 10: A#2  vol 13
    db $4C, $00, $4E                             ; step 11: B-2  vol 14
    db $4D, $00, $4F                             ; step 12: C-3  vol 15
    db $4E, $00, $00                             ; step 13: C#3
    db $4F, $00, $00                             ; step 14: D-3
    db $50, $00, $00                             ; step 15: D#3
    db $51, $00, $00                             ; step 16: E-3
    db $52, $00, $00                             ; step 17: F-3
    db $53, $00, $00                             ; step 18: F#3
    db $54, $00, $00                             ; step 19: G-3
    db $55, $00, $00                             ; step 20: G#3
    db $56, $00, $00                             ; step 21: A-3
    db $57, $00, $00                             ; step 22: A#3
    db $58, $00, $00                             ; step 23: B-3
    db $59, $00, $00                             ; step 24: C-4
    db $5A, $00, $00                             ; step 25: C#4
    db $5B, $00, $00                             ; step 26: D-4
    db $5C, $00, $00                             ; step 27: D#4
    db $5D, $00, $00                             ; step 28: E-4
    db $5E, $00, $00                             ; step 29: F-4
    db $5F, $00, $00                             ; step 30: F#4
SFXInst05:
    db $0D                                       ; 6D6D square, 13 steps
    db $01                                       ; playlist speed
    db $0F                                       ; NR12 envelope
    db $41, $00, $C2                             ; step 0: C-2  duty 2
    db $42, $00, $00                             ; step 1: C#2
    db $43, $00, $00                             ; step 2: D-2
    db $44, $00, $00                             ; step 3: D#2
    db $45, $00, $00                             ; step 4: E-2
    db $46, $00, $00                             ; step 5: F-2
    db $47, $00, $00                             ; step 6: F#2
    db $46, $00, $00                             ; step 7: F-2
    db $45, $00, $00                             ; step 8: E-2
    db $44, $00, $00                             ; step 9: D#2
    db $43, $00, $00                             ; step 10: D-2
    db $42, $00, $00                             ; step 11: C#2
    db $41, $00, $8D                             ; step 12: C-2  loop -13
SFXInst06:
    db $04                                       ; 6D97 noise, 4 steps
    db $01                                       ; playlist speed
    db $81                                       ; NR42 envelope
    db $7C, $00, $00                             ; step 0: B-6
    db $71, $00, $00                             ; step 1: C-6
    db $65, $00, $00                             ; step 2: C-5
    db $00, $00, $40                             ; step 3: -  vol 0
SFXInst07:
    db $04                                       ; 6DA6 square, 4 steps
    db $01                                       ; playlist speed
    db $61                                       ; NR12 envelope
    db $7C, $00, $00                             ; step 0: B-6
    db $65, $00, $44                             ; step 1: C-5  vol 4
    db $41, $00, $44                             ; step 2: C-2  vol 4
    db $00, $00, $40                             ; step 3: -  vol 0

;; Unreferenced 32 bytes (look like two wave-RAM patterns)
    db $88, $88, $69, $97, $07, $ED, $88, $99, $22, $88, $69, $97, $07, $ED, $88, $99; 6DB5 
    db $88, $CB, $A9, $98, $77, $76, $54, $32, $28, $CB, $BA, $98, $78, $76, $55, $43; 6DC5 

;; Sound effects: [ins ch1] [ins ch2] [ins ch3] [ins ch4] [mute time in ticks].
;; Instrument numbers are 1-based indices into SFXInstTable, 0 = channel unused.
SFXTable:
    db 1, 0, 0, 7, $18                           ; 6DD5 SFX 0
    db 0, 0, 0, 2, $12                           ; 6DDA SFX 1
    db 6, 0, 0, 5, $FF                           ; 6DDF SFX 2
    db 3, 0, 0, 7, $00                           ; 6DE4 SFX 3
    db 0, 0, 0, 0, $00                           ; 6DE9 SFX 4 (empty)
    db 0, 0, 0, 0, $00                           ; 6DEE SFX 5 (empty)
    db 0, 0, 0, 0, $00                           ; 6DF3 SFX 6 (empty)
    db 0, 0, 0, 0, $00                           ; 6DF8 SFX 7 (empty)
    db 0, 0, 0, 0, $00                           ; 6DFD SFX 8 (empty)
    db 0, 0, 0, 0, $00                           ; 6E02 SFX 9 (empty)
    db 0, 0, 0, 0, $00                           ; 6E07 SFX 10 (empty)
    db 0, 0, 0, 0, $00                           ; 6E0C SFX 11 (empty)
    db 0, 0, 0, 0, $00                           ; 6E11 SFX 12 (empty)
    db 0, 0, 0, 0, $00                           ; 6E16 SFX 13 (empty)

;; Unused space (filled with $DA by the linker)
    ds 4581, $DA                ; 6E1B  (fill)
