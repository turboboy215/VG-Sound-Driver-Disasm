; driver code and tables ($4C4A-$54DE)


; Sound_Init: master on, NR50=$77, NR51=$FF, full volume, shadow registers invalidated ($AA),
; load the initial wave, stop music and SFX, write the registers and retrigger all channels.
Sound_Init:
	ld a, $80                   ; 4C4A
	ldh [rNR52], a              ; 4C4C
	ld a, $77                   ; 4C4E
	ldh [rNR50], a              ; 4C50
	ld a, $FF                   ; 4C52
	ldh [rNR51], a              ; 4C54
	ld a, $FF                   ; 4C56
	ld [wSfxAttenuation], a     ; 4C58
	ld [wMusicAttenuation], a   ; 4C5B
	ld [wCurWave], a            ; 4C5E
	ld hl, wHwRegs              ; 4C61
	ld b, $14                   ; 4C64
	ld a, $AA                   ; 4C66
.l_4C68:
	ld [hli], a                 ; 4C68
	dec b                       ; 4C69
	jr nz, .l_4C68              ; 4C6A
	ld hl, InitialWave          ; 4C6C
	call LoadWave               ; 4C6F
	ld a, $FF                   ; 4C72
	call Sound_PlaySong         ; 4C74
	ld a, $FF                   ; 4C77
	call Sound_PlaySfx          ; 4C79
	call Sound_WriteRegs        ; 4C7C
	ld hl, rNR14                ; 4C7F
	set 7, [hl]                 ; 4C82
	ld hl, rNR24                ; 4C84
	set 7, [hl]                 ; 4C87
	ld hl, rNR34                ; 4C89
	set 7, [hl]                 ; 4C8C
	ld hl, rNR44                ; 4C8E
	set 7, [hl]                 ; 4C91
	ld a, $13                   ; 4C93
	ld [wSoundUnusedD3], a      ; 4C95
	ld a, $24                   ; 4C98
	ld [wSoundUnusedD4], a      ; 4C9A
	ret                         ; 4C9D


; Sound_PlaySfx: a = SFX number ($FF = stop all SFX).
; If an SFX already owns one of the new SFX's channels, the new one is refused when its
; priority number is higher than the playing one's (lower number = more important);
; otherwise the old SFX track is stopped. Tracks are then taken from track 3 downward.
Sound_PlaySfx:
	ld e, a                     ; 4C9E
	cp $FF                      ; 4C9F
	jp z, Sound_StopSfx         ; 4CA1
	ld d, $00                   ; 4CA4
	ld a, [wSfxChannels]        ; 4CA6
	and a                       ; 4CA9
	jr z, .l_4CD8               ; 4CAA
	ld hl, SfxChannelMasks      ; 4CAC
	add hl, de                  ; 4CAF
	and [hl]                    ; 4CB0
	jr z, .l_4CD8               ; 4CB1
	ld bc, $0003                ; 4CB3
.l_4CB6:
	ld hl, SfxChannelMasks      ; 4CB6
	add hl, de                  ; 4CB9
	ld a, [hl]                  ; 4CBA
	ld hl, wSfxMask             ; 4CBB
	add hl, bc                  ; 4CBE
	and [hl]                    ; 4CBF
	jr z, .l_4CD3               ; 4CC0
	ld hl, wSfxPriority         ; 4CC2
	add hl, bc                  ; 4CC5
	ld a, [hl]                  ; 4CC6
	ld hl, SfxPriorities        ; 4CC7
	add hl, de                  ; 4CCA
	cp [hl]                     ; 4CCB
	ret c                       ; 4CCC
	ld hl, wTrkWait             ; 4CCD
	add hl, bc                  ; 4CD0
	ld [hl], $00                ; 4CD1
.l_4CD3:
	dec c                       ; 4CD3
	bit 7, c                    ; 4CD4
	jr z, .l_4CB6               ; 4CD6
.l_4CD8:
	ld hl, SfxChannelMasks      ; 4CD8
	add hl, de                  ; 4CDB
	ld a, [hl]                  ; 4CDC
	ld [wSfxNewMask], a         ; 4CDD
	ld hl, SfxPriorities        ; 4CE0
	add hl, de                  ; 4CE3
	ld a, [hl]                  ; 4CE4
	ld c, a                     ; 4CE5
	ld hl, SfxTable             ; 4CE6
	add hl, de                  ; 4CE9
	add hl, de                  ; 4CEA
	ld a, [hli]                 ; 4CEB
	ld e, a                     ; 4CEC
	ld d, [hl]                  ; 4CED
	ld a, [de]                  ; 4CEE
	ld h, a                     ; 4CEF
	ld l, c                     ; 4CF0
	push hl                     ; 4CF1
	ld bc, $0003                ; 4CF2
.l_4CF5:
	ld hl, wTrkWait             ; 4CF5
	add hl, bc                  ; 4CF8
	ld a, [hl]                  ; 4CF9
	and a                       ; 4CFA
	jr nz, .l_4D15              ; 4CFB
	call Sound_StartTrack       ; 4CFD
	ld hl, sp+0                 ; 4D00
	ld a, [hl]                  ; 4D02
	ld hl, wSfxPriority         ; 4D03
	add hl, bc                  ; 4D06
	ld [hl], a                  ; 4D07
	ld a, [wSfxNewMask]         ; 4D08
	ld hl, wSfxMask             ; 4D0B
	add hl, bc                  ; 4D0E
	ld [hl], a                  ; 4D0F
	pop hl                      ; 4D10
	dec h                       ; 4D11
	push hl                     ; 4D12
	jr z, .l_4D1A               ; 4D13
.l_4D15:
	dec c                       ; 4D15
	bit 7, c                    ; 4D16
	jr z, .l_4CF5               ; 4D18
.l_4D1A:
	pop hl                      ; 4D1A

; wSfxChannels = OR of the channel masks of the SFX tracks still running.
Sound_UpdateSfxChannels:
	ld a, [wSfxMask]            ; 4D1B
	ld hl, wSfxMask + 1         ; 4D1E
	ld c, $03                   ; 4D21
.l_4D23:
	or [hl]                     ; 4D23
	inc hl                      ; 4D24
	dec c                       ; 4D25
	jr nz, .l_4D23              ; 4D26
	ld [wSfxChannels], a        ; 4D28
	ret                         ; 4D2B


; stop SFX tracks 0-3 and reset the SFX register image.
Sound_StopSfx:
	ld bc, $0003                ; 4D2C
.l_4D2F:
	ld hl, wTrkWait             ; 4D2F
	add hl, bc                  ; 4D32
	ld [hl], b                  ; 4D33
	ld hl, wSfxMask             ; 4D34
	add hl, bc                  ; 4D37
	ld [hl], b                  ; 4D38
	ld hl, wSfxPriority         ; 4D39
	add hl, bc                  ; 4D3C
	ld [hl], $FF                ; 4D3D
	dec c                       ; 4D3F
	bit 7, c                    ; 4D40
	jr z, .l_4D2F               ; 4D42
	ld hl, DefaultRegImage      ; 4D44
	ld de, wSfxRegs             ; 4D47
	ld c, $14                   ; 4D4A
.l_4D4C:
	ld a, [hli]                 ; 4D4C
	ld [de], a                  ; 4D4D
	inc de                      ; 4D4E
	dec c                       ; 4D4F
	jr nz, .l_4D4C              ; 4D50
	ret                         ; 4D52

DefaultRegImage:
	db $08, $00, $08, $00, $80, $00, $00, $08, $00, $80, $80, $00, $00, $00, $80, $00
	db $00, $08, $00, $80

; Sound_StartTrack: c = track, de -> header entry - 1. Reads pointer + channel byte,
; resets the per-track state (base note $24, volume, instrument, length set, tuning, stacks).
Sound_StartTrack:
	ld hl, wTrkBaseNote         ; 4D67
	add hl, bc                  ; 4D6A
	ld [hl], $24                ; 4D6B
	xor a                       ; 4D6D
	ld hl, wTrkGate             ; 4D6E
	add hl, bc                  ; 4D71
	ld [hl], a                  ; 4D72
	ld hl, wTrkVolume           ; 4D73
	add hl, bc                  ; 4D76
	ld [hl], a                  ; 4D77
	ld hl, wTrkInstrument       ; 4D78
	add hl, bc                  ; 4D7B
	ld [hl], a                  ; 4D7C
	ld hl, wTrkLengthSet        ; 4D7D
	add hl, bc                  ; 4D80
	ld [hl], a                  ; 4D81
	ld hl, wTrkTuning           ; 4D82
	add hl, bc                  ; 4D85
	ld [hl], a                  ; 4D86
	ld hl, TrackStackTable      ; 4D87
	add hl, bc                  ; 4D8A
	ld a, [hl]                  ; 4D8B
	ld hl, wTrkStack            ; 4D8C
	add hl, bc                  ; 4D8F
	ld [hl], a                  ; 4D90
	inc de                      ; 4D91
	ld a, [de]                  ; 4D92
	ld hl, wTrkPtrLo            ; 4D93
	add hl, bc                  ; 4D96
	ld [hl], a                  ; 4D97
	inc de                      ; 4D98
	ld a, [de]                  ; 4D99
	ld hl, wTrkPtrHi            ; 4D9A
	add hl, bc                  ; 4D9D
	ld [hl], a                  ; 4D9E
	inc de                      ; 4D9F
	ld a, [de]                  ; 4DA0
	sra a                       ; 4DA1
	sra a                       ; 4DA3
	add a, LOW(HwOffsetTable)   ; 4DA5
	ld l, a                     ; 4DA7
	ld h, HIGH(HwOffsetTable)   ; 4DA8
	jr nc, .l_4DAD              ; 4DAA
	inc h                       ; 4DAC
.l_4DAD:
	ld a, [hl]                  ; 4DAD
	ld hl, wTrkHwOffset         ; 4DAE
	add hl, bc                  ; 4DB1
	ld [hl], a                  ; 4DB2
	ld hl, wTrkWait             ; 4DB3
	add hl, bc                  ; 4DB6
	ld [hl], $01                ; 4DB7
	ld hl, wTrkRelease          ; 4DB9
	add hl, bc                  ; 4DBC
	ld [hl], $01                ; 4DBD
	ret                         ; 4DBF

HwOffsetTable:
	db $00, $05, $FF, $0F, $0A

; Sound_PlaySong: a = song number ($FF = stop). Stops tracks 4-7, resets the music register
; image, then starts the header's tracks from track 7 downward.
Sound_PlaySong:
	ld b, a                     ; 4DC5
	ld hl, wTrkWait + 4         ; 4DC6
	ld c, $04                   ; 4DC9
	xor a                       ; 4DCB
.l_4DCC:
	ld [hli], a                 ; 4DCC
	dec c                       ; 4DCD
	jr nz, .l_4DCC              ; 4DCE
	ld hl, DefaultRegImage      ; 4DD0
	ld de, wMusicRegs           ; 4DD3
	ld c, $14                   ; 4DD6
.l_4DD8:
	ld a, [hli]                 ; 4DD8
	ld [de], a                  ; 4DD9
	inc de                      ; 4DDA
	dec c                       ; 4DDB
	jr nz, .l_4DD8              ; 4DDC
	ld a, $FF                   ; 4DDE
	cp b                        ; 4DE0
	ret z                       ; 4DE1
	ld e, b                     ; 4DE2
	ld d, $00                   ; 4DE3
	ld hl, SongTable            ; 4DE5
	add hl, de                  ; 4DE8
	add hl, de                  ; 4DE9
	ld a, [hli]                 ; 4DEA
	ld e, a                     ; 4DEB
	ld d, [hl]                  ; 4DEC
	ld a, [de]                  ; 4DED
	ld h, a                     ; 4DEE
	push hl                     ; 4DEF
	ld bc, $0007                ; 4DF0
.l_4DF3:
	ld hl, wTrkWait             ; 4DF3
	add hl, bc                  ; 4DF6
	ld a, [hl]                  ; 4DF7
	and a                       ; 4DF8
	jr nz, .l_4E03              ; 4DF9
	call Sound_StartTrack       ; 4DFB
	pop hl                      ; 4DFE
	dec h                       ; 4DFF
	push hl                     ; 4E00
	jr z, .l_4E09               ; 4E01
.l_4E03:
	dec c                       ; 4E03
	ld a, $03                   ; 4E04
	cp c                        ; 4E06
	jr nz, .l_4DF3              ; 4E07
.l_4E09:
	pop hl                      ; 4E09
	ret                         ; 4E0A


; Sound_Update: once per tick. For each active track (7 down to 0): main stream, release
; check, envelope stream. Then the SFX channel masks, and the register images are written:
; for each channel the SFX image if an SFX owns it, else the music image. Only changed bytes
; are written; a changed NRx2 retriggers the channel. NR51 is built from the pan bytes.
Sound_Update:
	ld b, $07                   ; 4E0B
.l_4E0D:
	ld h, HIGH(wSoundRAM)       ; 4E0D
	ld a, LOW(wTrkWait)         ; 4E0F
	add a, b                    ; 4E11
	ld l, a                     ; 4E12
	ld a, [hl]                  ; 4E13
	and a                       ; 4E14
	jr z, .l_4E52               ; 4E15
	ld a, b                     ; 4E17
	cp $04                      ; 4E18
	ld a, $1A                   ; 4E1A
	jr c, .l_4E20               ; 4E1C
	ld a, $2E                   ; 4E1E
.l_4E20:
	ld [wRegImage], a           ; 4E20
	ld h, HIGH(wSoundRAM)       ; 4E23
	ld a, LOW(wTrkPtrLo)        ; 4E25
	add a, b                    ; 4E27
	ld l, a                     ; 4E28
	push hl                     ; 4E29
	ld e, [hl]                  ; 4E2A
	add a, LOW(wTrkPtrHi - wTrkPtrLo); 4E2B
	ld l, a                     ; 4E2D
	push hl                     ; 4E2E
	ld d, [hl]                  ; 4E2F
	push bc                     ; 4E30
	call Track_Main             ; 4E31
	pop bc                      ; 4E34
	pop hl                      ; 4E35
	ld [hl], d                  ; 4E36
	pop hl                      ; 4E37
	ld [hl], e                  ; 4E38
	call Track_Release          ; 4E39
	ld h, HIGH(wSoundRAM)       ; 4E3C
	ld a, LOW(wTrkEnvPtrLo)     ; 4E3E
	add a, b                    ; 4E40
	ld l, a                     ; 4E41
	push hl                     ; 4E42
	ld e, [hl]                  ; 4E43
	add a, LOW(wTrkEnvPtrHi - wTrkEnvPtrLo); 4E44
	ld l, a                     ; 4E46
	push hl                     ; 4E47
	ld d, [hl]                  ; 4E48
	push bc                     ; 4E49
	call Track_Env              ; 4E4A
	pop bc                      ; 4E4D
	pop hl                      ; 4E4E
	ld [hl], d                  ; 4E4F
	pop hl                      ; 4E50
	ld [hl], e                  ; 4E51
.l_4E52:
	dec b                       ; 4E52
	bit 7, b                    ; 4E53
	jr z, .l_4E0D               ; 4E55
	ld b, $03                   ; 4E57
.l_4E59:
	ld h, HIGH(wSoundRAM)       ; 4E59
	ld a, LOW(wTrkWait)         ; 4E5B
	add a, b                    ; 4E5D
	ld l, a                     ; 4E5E
	ld a, [hl]                  ; 4E5F
	and a                       ; 4E60
	jr nz, .l_4E6E              ; 4E61
	ld a, LOW(wSfxPriority)     ; 4E63
	add a, b                    ; 4E65
	ld l, a                     ; 4E66
	ld [hl], $FF                ; 4E67
	add a, LOW(wSfxMask - wSfxPriority); 4E69
	ld l, a                     ; 4E6B
	ld [hl], $00                ; 4E6C
.l_4E6E:
	dec b                       ; 4E6E
	bit 7, b                    ; 4E6F
	jr z, .l_4E59               ; 4E71
	call Sound_UpdateSfxChannels; 4E73

; compare the chosen image with wHwRegs and write the changed registers.
Sound_WriteRegs:
	ld de, wMusicRegs           ; 4E76
	ld a, [wSfxChannels]        ; 4E79
	bit 0, a                    ; 4E7C
	jr z, .l_4E82               ; 4E7E
	ld e, $1A                   ; 4E80
.l_4E82:
	ld b, $00                   ; 4E82
	ld hl, wHwRegs              ; 4E84
	ld c, $10                   ; 4E87
.l_4E89:
	ld a, [de]                  ; 4E89
	cp [hl]                     ; 4E8A
	jr z, .l_4E95               ; 4E8B
	ld [hl], a                  ; 4E8D
	ldh [c], a                  ; 4E8E
	ld a, c                     ; 4E8F
	cp $12                      ; 4E90
	jr nz, .l_4E95              ; 4E92
	inc b                       ; 4E94
.l_4E95:
	inc l                       ; 4E95
	inc e                       ; 4E96
	inc c                       ; 4E97
	ld a, c                     ; 4E98
	cp $15                      ; 4E99
	jr nz, .l_4E89              ; 4E9B
	dec b                       ; 4E9D
	jr nz, .l_4EA7              ; 4E9E
	ld a, [wHwRegs + 4]         ; 4EA0
	set 7, a                    ; 4EA3
	ldh [rNR14], a              ; 4EA5
.l_4EA7:
	ld de, wMusicRegs + 6       ; 4EA7
	ld a, [wSfxChannels]        ; 4EAA
	bit 1, a                    ; 4EAD
	jr z, .l_4EB3               ; 4EAF
	ld e, $20                   ; 4EB1
.l_4EB3:
	ld b, $00                   ; 4EB3
	ld hl, wHwRegs + 6          ; 4EB5
	ld c, $16                   ; 4EB8
.l_4EBA:
	ld a, [de]                  ; 4EBA
	cp [hl]                     ; 4EBB
	jr z, .l_4EC6               ; 4EBC
	ld [hl], a                  ; 4EBE
	ldh [c], a                  ; 4EBF
	ld a, c                     ; 4EC0
	cp $17                      ; 4EC1
	jr nz, .l_4EC6              ; 4EC3
	inc b                       ; 4EC5
.l_4EC6:
	inc l                       ; 4EC6
	inc e                       ; 4EC7
	inc c                       ; 4EC8
	ld a, c                     ; 4EC9
	cp $1A                      ; 4ECA
	jr nz, .l_4EBA              ; 4ECC
	dec b                       ; 4ECE
	jr nz, .l_4ED8              ; 4ECF
	ld a, [$DE0F]               ; 4ED1
	set 7, a                    ; 4ED4
	ldh [rNR24], a              ; 4ED6
.l_4ED8:
	ld de, $DE38                ; 4ED8
	ld a, [wSfxChannels]        ; 4EDB
	bit 4, a                    ; 4EDE
	jr z, .l_4EE4               ; 4EE0
	ld e, $24                   ; 4EE2
.l_4EE4:
	ld hl, $DE10                ; 4EE4
	ld c, $1A                   ; 4EE7
.l_4EE9:
	ld a, [de]                  ; 4EE9
	cp [hl]                     ; 4EEA
	jr z, .l_4EEF               ; 4EEB
	ld [hl], a                  ; 4EED
	ldh [c], a                  ; 4EEE
.l_4EEF:
	inc l                       ; 4EEF
	inc e                       ; 4EF0
	inc c                       ; 4EF1
	ld a, c                     ; 4EF2
	cp $1F                      ; 4EF3
	jr nz, .l_4EE9              ; 4EF5
	ld de, $DE3E                ; 4EF7
	ld a, [wSfxChannels]        ; 4EFA
	bit 3, a                    ; 4EFD
	jr z, .l_4F03               ; 4EFF
	ld e, $2A                   ; 4F01
.l_4F03:
	ld b, $00                   ; 4F03
	ld hl, $DE16                ; 4F05
	ld c, $20                   ; 4F08
.l_4F0A:
	ld a, [de]                  ; 4F0A
	cp [hl]                     ; 4F0B
	jr z, .l_4F16               ; 4F0C
	ld [hl], a                  ; 4F0E
	ldh [c], a                  ; 4F0F
	ld a, c                     ; 4F10
	cp $21                      ; 4F11
	jr nz, .l_4F16              ; 4F13
	inc b                       ; 4F15
.l_4F16:
	inc l                       ; 4F16
	inc e                       ; 4F17
	inc c                       ; 4F18
	ld a, c                     ; 4F19
	cp $24                      ; 4F1A
	jr nz, .l_4F0A              ; 4F1C
	dec b                       ; 4F1E
	jr nz, .l_4F28              ; 4F1F
	ld a, [$DE19]               ; 4F21
	set 7, a                    ; 4F24
	ldh [rNR44], a              ; 4F26
.l_4F28:
	ld a, [wSfxChannels]        ; 4F28
	ld c, a                     ; 4F2B
	ld a, [wTrkPan + 4]         ; 4F2C
	bit 0, c                    ; 4F2F
	jr z, .l_4F36               ; 4F31
	ld a, [wTrkPan]             ; 4F33
.l_4F36:
	ld b, a                     ; 4F36
	ld a, [wTrkPan + 5]         ; 4F37
	bit 1, c                    ; 4F3A
	jr z, .l_4F41               ; 4F3C
	ld a, [wTrkPan + 1]         ; 4F3E
.l_4F41:
	or b                        ; 4F41
	ld b, a                     ; 4F42
	ld a, [wTrkPan + 6]         ; 4F43
	bit 4, c                    ; 4F46
	jr z, .l_4F4D               ; 4F48
	ld a, [wTrkPan + 2]         ; 4F4A
.l_4F4D:
	or b                        ; 4F4D
	ld b, a                     ; 4F4E
	ld a, [wTrkPan + 7]         ; 4F4F
	bit 3, c                    ; 4F52
	jr z, .l_4F59               ; 4F54
	ld a, [wTrkPan + 3]         ; 4F56
.l_4F59:
	or b                        ; 4F59
	ldh [rNR51], a              ; 4F5A
	ret                         ; 4F5C


; Track_Main: b = track, de = stream pointer. Counts wTrkWait down; at 0 reads bytes until
; a note, rest or hold sets a new wait.
Track_Main:
	ld h, HIGH(wSoundRAM)       ; 4F5D
	ld a, LOW(wTrkWait)         ; 4F5F
	add a, b                    ; 4F61
	ld l, a                     ; 4F62
	dec [hl]                    ; 4F63
	jr z, Track_MainRead        ; 4F64
	ret                         ; 4F66

Track_MainNextByte:
	inc de                      ; 4F67
Track_MainRead:
	ld h, HIGH(wSoundRAM)       ; 4F68
	ld a, [de]                  ; 4F6A
	ld c, a                     ; 4F6B
	and $E0                     ; 4F6C
	cp $E0                      ; 4F6E
	jp z, Track_Command         ; 4F70
	ld a, LOW(wTrkHwOffset)     ; 4F73
	add a, b                    ; 4F75
	ld l, a                     ; 4F76
	ld a, [hl]                  ; 4F77
	cp $0F                      ; 4F78
	jr nz, .l_4F9A              ; 4F7A
	bit 4, c                    ; 4F7C
	jp nz, Track_NoteOn         ; 4F7E
	ld a, c                     ; 4F81
	and $0F                     ; 4F82
	cp $0F                      ; 4F84
	jr z, Track_Rest            ; 4F86
	add a, LOW(NoiseTable)      ; 4F88
	ld l, a                     ; 4F8A
	ld h, HIGH(NoiseTable)      ; 4F8B
	jr nc, .l_4F90              ; 4F8D
	inc h                       ; 4F8F
.l_4F90:
	ld c, [hl]                  ; 4F90
	ld a, $12                   ; 4F91
	call Track_RegAddrAbs       ; 4F93
	ld [hl], c                  ; 4F96
	jp Track_NoteOn             ; 4F97

.l_4F9A:
	ld a, c                     ; 4F9A
	and $1F                     ; 4F9B
	cp $10                      ; 4F9D
	jr z, Track_Rest            ; 4F9F
	bit 4, a                    ; 4FA1
	jr z, .l_4FA7               ; 4FA3
	or $E0                      ; 4FA5
.l_4FA7:
	ld c, a                     ; 4FA7
	ld a, LOW(wTrkBaseNote)     ; 4FA8
	add a, b                    ; 4FAA
	ld l, a                     ; 4FAB
	ld a, [hl]                  ; 4FAC
	add a, c                    ; 4FAD
	push de                     ; 4FAE
	call Track_SetNote          ; 4FAF
	pop de                      ; 4FB2
	jp Track_NoteOn             ; 4FB3

Track_Rest:
	call Track_ReadLength       ; 4FB6
	ld c, a                     ; 4FB9
	ld h, HIGH(wSoundRAM)       ; 4FBA
	ld a, LOW(wTrkRelease)      ; 4FBC
	add a, b                    ; 4FBE
	ld l, a                     ; 4FBF
	ld a, [hl]                  ; 4FC0
	and a                       ; 4FC1
	jr z, Track_NoteDone        ; 4FC2
	ld [hl], $01                ; 4FC4
Track_NoteDone:
	ld a, c                     ; 4FC6
	and a                       ; 4FC7
	jp z, Track_MainNextByte    ; 4FC8
	inc de                      ; 4FCB
	ret                         ; 4FCC


; note: wait = length; release counter = $FF or length*gate/256; start the instrument envelope.
Track_NoteOn:
	call Track_ReadLength       ; 4FCD
	ld c, a                     ; 4FD0
	ld h, HIGH(wSoundRAM)       ; 4FD1
	ld a, LOW(wTrkRelease)      ; 4FD3
	add a, b                    ; 4FD5
	ld l, a                     ; 4FD6
	ld [hl], $FF                ; 4FD7
	add a, LOW(wTrkGate - wTrkRelease); 4FD9
	ld l, a                     ; 4FDB
	ld a, [hl]                  ; 4FDC
	and a                       ; 4FDD
	jr z, .l_4FF3               ; 4FDE
	push bc                     ; 4FE0
	push de                     ; 4FE1
	ld e, a                     ; 4FE2
	ld h, HIGH(wSoundRAM)       ; 4FE3
	ld a, LOW(wTrkRelease)      ; 4FE5
	add a, b                    ; 4FE7
	ld l, a                     ; 4FE8
	push hl                     ; 4FE9
	ld a, c                     ; 4FEA
	call Multiply_AxE           ; 4FEB
	ld b, h                     ; 4FEE
	pop hl                      ; 4FEF
	ld [hl], b                  ; 4FF0
	pop de                      ; 4FF1
	pop bc                      ; 4FF2
.l_4FF3:
	push bc                     ; 4FF3
	call Track_StartEnvelope    ; 4FF4
	pop bc                      ; 4FF7
	jp Track_NoteDone           ; 4FF8


; point the envelope stream at the instrument's attack envelope (unless STATIC).
Track_StartEnvelope:
	ld h, HIGH(wSoundRAM)       ; 4FFB
	ld a, LOW(wTrkInstrument)   ; 4FFD
	add a, b                    ; 4FFF
	ld l, a                     ; 5000
	ld a, [hl]                  ; 5001
	bit 7, a                    ; 5002
	jr nz, Track_LoadEnvelopeA.l_5037; 5004
Track_LoadEnvelope:
	add a, a                    ; 5006
	add a, a                    ; 5007
Track_LoadEnvelopeA:
	push de                     ; 5008
	add a, LOW(InstrumentTable) ; 5009
	ld e, a                     ; 500B
	ld d, HIGH(InstrumentTable) ; 500C
	jr nc, .l_5011              ; 500E
	inc d                       ; 5010
.l_5011:
	ld h, HIGH(wSoundRAM)       ; 5011
	ld a, LOW(wTrkEnvPtrLo)     ; 5013
	add a, b                    ; 5015
	ld l, a                     ; 5016
	ld a, [de]                  ; 5017
	ld [hl], a                  ; 5018
	ld a, LOW(wTrkEnvPtrHi)     ; 5019
	add a, b                    ; 501B
	ld l, a                     ; 501C
	inc de                      ; 501D
	ld a, [de]                  ; 501E
	ld [hl], a                  ; 501F
	ld h, HIGH(EnvStackTable)   ; 5020
	ld a, LOW(EnvStackTable)    ; 5022
	add a, b                    ; 5024
	ld l, a                     ; 5025
	jr nc, .l_5029              ; 5026
	inc h                       ; 5028
.l_5029:
	ld c, [hl]                  ; 5029
	ld h, HIGH(wSoundRAM)       ; 502A
	ld a, LOW(wTrkEnvStack)     ; 502C
	add a, b                    ; 502E
	ld l, a                     ; 502F
	ld [hl], c                  ; 5030
	add a, LOW(wTrkEnvWait - wTrkEnvStack); 5031
	ld l, a                     ; 5033
	ld [hl], $01                ; 5034
	pop de                      ; 5036
.l_5037:
	ret                         ; 5037


; length: LLL = 6 -> next byte, else LengthSets[wTrkLengthSet + LLL].
Track_ReadLength:
	ld a, [de]                  ; 5038
	and $E0                     ; 5039
	cp $C0                      ; 503B
	jr nz, .l_5043              ; 503D
	inc de                      ; 503F
	ld a, [de]                  ; 5040
	jr .l_505A                  ; 5041

.l_5043:
	ld h, HIGH(wSoundRAM)       ; 5043
	ld a, LOW(wTrkLengthSet)    ; 5045
	add a, b                    ; 5047
	ld l, a                     ; 5048
	ld a, [de]                  ; 5049
	and $E0                     ; 504A
	swap a                      ; 504C
	srl a                       ; 504E
	add a, [hl]                 ; 5050
	add a, LOW(LengthSets)      ; 5051
	ld l, a                     ; 5053
	ld a, $00                   ; 5054
	adc a, HIGH(LengthSets)     ; 5056
	ld h, a                     ; 5058
	ld a, [hl]                  ; 5059
.l_505A:
	ld c, a                     ; 505A
	ld h, HIGH(wSoundRAM)       ; 505B
	ld a, LOW(wTrkWait)         ; 505D
	add a, b                    ; 505F
	ld l, a                     ; 5060
	ld a, c                     ; 5061
	ld [hl], a                  ; 5062
	ret                         ; 5063


; $E0-$FF commands. Unlisted values fall through to the flow-control handler, which ignores
; them: the same byte is then read again forever.
Track_Command:
	ld a, c                     ; 5064
	cp $F0                      ; 5065
	jr nz, .l_5081              ; 5067
	inc de                      ; 5069
	ld h, HIGH(wSoundRAM)       ; 506A
	ld a, LOW(wTrkVolume)       ; 506C
	add a, b                    ; 506E
	ld l, a                     ; 506F
	ld a, [de]                  ; 5070
.l_5071:
	swap a                      ; 5071
	and $F0                     ; 5073
	ld c, a                     ; 5075
	ld a, [hl]                  ; 5076
	and $0F                     ; 5077
	or c                        ; 5079
	ld [hl], a                  ; 507A
	call Track_ApplyVolume      ; 507B
	jp Track_MainNextByte       ; 507E

.l_5081:
	cp $F1                      ; 5081
	jr nz, .l_50A5              ; 5083
	inc de                      ; 5085
	ld a, [de]                  ; 5086
	ld c, a                     ; 5087
	ld h, HIGH(wSoundRAM)       ; 5088
	ld a, LOW(wTrkVolume)       ; 508A
	add a, b                    ; 508C
	ld l, a                     ; 508D
	ld a, [hl]                  ; 508E
	swap a                      ; 508F
	and $0F                     ; 5091
	add a, c                    ; 5093
	bit 7, c                    ; 5094
	jr nz, .l_50A0              ; 5096
	cp $10                      ; 5098
	jr c, .l_50A3               ; 509A
	ld a, $0F                   ; 509C
	jr .l_50A3                  ; 509E

.l_50A0:
	jr c, .l_50A3               ; 50A0
	xor a                       ; 50A2
.l_50A3:
	jr .l_5071                  ; 50A3

.l_50A5:
	cp $F2                      ; 50A5
	jr nz, .l_50BA              ; 50A7
	inc de                      ; 50A9
	ld a, [de]                  ; 50AA
	add a, a                    ; 50AB
	ld c, a                     ; 50AC
	add a, a                    ; 50AD
	add a, c                    ; 50AE
	ld hl, wTrkLengthSet        ; 50AF
.l_50B2:
	ld c, a                     ; 50B2
	ld a, l                     ; 50B3
	add a, b                    ; 50B4
	ld l, a                     ; 50B5
	ld [hl], c                  ; 50B6
	jp Track_MainNextByte       ; 50B7

.l_50BA:
	cp $F3                      ; 50BA
	jr nz, .l_50CF              ; 50BC
	inc de                      ; 50BE
	ld h, HIGH(wSoundRAM)       ; 50BF
	ld a, LOW(wTrkWait)         ; 50C1
	add a, b                    ; 50C3
	ld l, a                     ; 50C4
	ld a, [de]                  ; 50C5
	ld [hl], a                  ; 50C6
	ld a, LOW(wTrkRelease)      ; 50C7
	add a, b                    ; 50C9
	ld l, a                     ; 50CA
	ld [hl], $FF                ; 50CB
	inc de                      ; 50CD
	ret                         ; 50CE

.l_50CF:
	cp $F4                      ; 50CF
	jr nz, .l_50DB              ; 50D1
	inc de                      ; 50D3
	ld a, [de]                  ; 50D4
	ld hl, wTrkGate             ; 50D5
	jp .l_50B2                  ; 50D8

.l_50DB:
	cp $F5                      ; 50DB
	jr nz, .l_50E7              ; 50DD
	inc de                      ; 50DF
	ld a, [de]                  ; 50E0
	ld hl, wTrkBaseNote         ; 50E1
	jp .l_50B2                  ; 50E4

.l_50E7:
	cp $F6                      ; 50E7
	jr nz, .l_50FC              ; 50E9
	inc de                      ; 50EB
	ld h, HIGH(wSoundRAM)       ; 50EC
	ld a, LOW(wTrkInstrument)   ; 50EE
	add a, b                    ; 50F0
	ld l, a                     ; 50F1
	ld a, [de]                  ; 50F2
	ld [hl], a                  ; 50F3
	bit 7, a                    ; 50F4
	call nz, Track_LoadEnvelope ; 50F6
	jp Track_MainNextByte       ; 50F9

.l_50FC:
	cp $F7                      ; 50FC
	jr nz, .l_5108              ; 50FE
	inc de                      ; 5100
	ld a, [de]                  ; 5101
	ld hl, wTrkTuning           ; 5102
	jp .l_50B2                  ; 5105

.l_5108:
	cp $E2                      ; 5108
	jr nz, .l_511E              ; 510A
	inc de                      ; 510C
	ld a, [de]                  ; 510D
	ld c, a                     ; 510E
	inc de                      ; 510F
	ld a, [de]                  ; 5110
	push de                     ; 5111
	ld d, a                     ; 5112
	ld e, c                     ; 5113
	call Track_SetPeriod        ; 5114
	call Track_StartEnvelope    ; 5117
	pop de                      ; 511A
	jp Track_MainNextByte       ; 511B

.l_511E:
	cp $E3                      ; 511E
	jr nz, .l_5135              ; 5120
	inc de                      ; 5122
	ld a, [de]                  ; 5123
	push de                     ; 5124
	cpl                         ; 5125
	inc a                       ; 5126
	ld e, a                     ; 5127
	ld d, $00                   ; 5128
	rla                         ; 512A
	jr nc, .l_512E              ; 512B
	dec d                       ; 512D
.l_512E:
	call Track_AddPeriod        ; 512E
	pop de                      ; 5131
	jp Track_MainNextByte       ; 5132

.l_5135:
	cp $FE                      ; 5135
	jr nz, .l_516F              ; 5137
	inc de                      ; 5139
	ld a, [de]                  ; 513A
	ld c, a                     ; 513B
	push de                     ; 513C
	ld h, HIGH(wSoundRAM)       ; 513D
	ld a, LOW(wTrkHwOffset)     ; 513F
	add a, b                    ; 5141
	ld l, a                     ; 5142
	ld e, [hl]                  ; 5143
	srl e                       ; 5144
	srl e                       ; 5146
	ld d, $00                   ; 5148
	ld hl, wTrkPan              ; 514A
	add hl, de                  ; 514D
	ld a, c                     ; 514E
	rra                         ; 514F
	jr nc, .l_5154              ; 5150
	set 4, d                    ; 5152
.l_5154:
	rra                         ; 5154
	jr nc, .l_5158              ; 5155
	inc d                       ; 5157
.l_5158:
	inc e                       ; 5158
	dec e                       ; 5159
	jr z, .l_5161               ; 515A
.l_515C:
	rlc d                       ; 515C
	dec e                       ; 515E
	jr nz, .l_515C              ; 515F
.l_5161:
	ld a, b                     ; 5161
	cp $04                      ; 5162
	jr c, .l_516A               ; 5164
	inc l                       ; 5166
	inc l                       ; 5167
	inc l                       ; 5168
	inc l                       ; 5169
.l_516A:
	ld [hl], d                  ; 516A
	pop de                      ; 516B
	jp Track_MainNextByte       ; 516C

.l_516F:
	cp $E1                      ; 516F
	jr nz, .l_517B              ; 5171
	inc de                      ; 5173
	ld a, [de]                  ; 5174
	ld [wSoundSync], a          ; 5175
	jp Track_MainNextByte       ; 5178

.l_517B:
	cp $FF                      ; 517B
	jr nz, .l_518F              ; 517D
	ld h, HIGH(wSoundRAM)       ; 517F
	ld a, LOW(wTrkWait)         ; 5181
	add a, b                    ; 5183
	ld l, a                     ; 5184
	ld [hl], $00                ; 5185
	add a, LOW(wTrkEnvWait - wTrkWait); 5187
	ld l, a                     ; 5189
	xor a                       ; 518A
	ld [hl], a                  ; 518B
	jp Track_SetVolume          ; 518C

.l_518F:
	ld hl, wTrkStack            ; 518F
	call Track_Flow             ; 5192
	jp Track_MainRead           ; 5195


; flow control for the main stream: stack pointer = wSoundStacks + wTrkStack[b].
Track_Flow:
	ld a, l                     ; 5198
	add a, b                    ; 5199
	ld l, a                     ; 519A
	push hl                     ; 519B
	ld a, LOW(wSoundSync)       ; 519C
	add a, [hl]                 ; 519E
	ld l, a                     ; 519F
	ld a, $DF                   ; 51A0
	adc a, $00                  ; 51A2
	ld h, a                     ; 51A4
	call Stream_Flow            ; 51A5
	ld a, l                     ; 51A8
	sub $00                     ; 51A9
	pop hl                      ; 51AB
	ld [hl], a                  ; 51AC
	ret                         ; 51AD


; $F8 jump, $FA call (push return), $FB return, $FC loop start (push count+address),
; $FD loop end (count down, jump back or pop). hl = stack pointer, de = stream.
Stream_Flow:
	ld a, [de]                  ; 51AE
	cp $F8                      ; 51AF
	jr nz, .l_51BB              ; 51B1
	inc de                      ; 51B3
	ld a, [de]                  ; 51B4
	ld c, a                     ; 51B5
	inc de                      ; 51B6
	ld a, [de]                  ; 51B7
	ld d, a                     ; 51B8
	ld e, c                     ; 51B9
	ret                         ; 51BA

.l_51BB:
	cp $FA                      ; 51BB
	jr nz, .l_51CE              ; 51BD
	inc de                      ; 51BF
	inc de                      ; 51C0
	inc de                      ; 51C1
	dec hl                      ; 51C2
	ld [hl], d                  ; 51C3
	dec hl                      ; 51C4
	ld [hl], e                  ; 51C5
	dec de                      ; 51C6
	ld a, [de]                  ; 51C7
	ld c, a                     ; 51C8
	dec de                      ; 51C9
	ld a, [de]                  ; 51CA
	ld e, a                     ; 51CB
	ld d, c                     ; 51CC
	ret                         ; 51CD

.l_51CE:
	cp $FB                      ; 51CE
	jr nz, .l_51D7              ; 51D0
	ld e, [hl]                  ; 51D2
	inc hl                      ; 51D3
	ld d, [hl]                  ; 51D4
	inc hl                      ; 51D5
	ret                         ; 51D6

.l_51D7:
	cp $FC                      ; 51D7
	jr nz, .l_51E6              ; 51D9
	inc de                      ; 51DB
	ld a, [de]                  ; 51DC
	ld c, a                     ; 51DD
	inc de                      ; 51DE
	dec hl                      ; 51DF
	ld [hl], d                  ; 51E0
	dec hl                      ; 51E1
	ld [hl], e                  ; 51E2
	dec hl                      ; 51E3
	ld [hl], c                  ; 51E4
	ret                         ; 51E5

.l_51E6:
	cp $FD                      ; 51E6
	jr nz, .l_51F8              ; 51E8
	dec [hl]                    ; 51EA
	jr z, .l_51F4               ; 51EB
	inc hl                      ; 51ED
	ld e, [hl]                  ; 51EE
	inc hl                      ; 51EF
	ld d, [hl]                  ; 51F0
	dec hl                      ; 51F1
	dec hl                      ; 51F2
	ret                         ; 51F3

.l_51F4:
	inc hl                      ; 51F4
	inc hl                      ; 51F5
	inc hl                      ; 51F6
	inc de                      ; 51F7
.l_51F8:
	ret                         ; 51F8


; a = note index -> period from the tuning table (big-endian words; index*2 via rlc).
Track_SetNote:
	ld e, a                     ; 51F9
	ld a, LOW(wTrkTuning)       ; 51FA
	add a, b                    ; 51FC
	ld l, a                     ; 51FD
	ld a, [hl]                  ; 51FE
	add a, a                    ; 51FF
	add a, LOW(TuningTable)     ; 5200
	ld l, a                     ; 5202
	ld a, $00                   ; 5203
	adc a, HIGH(TuningTable)    ; 5205
	ld h, a                     ; 5207
	ld a, [hli]                 ; 5208
	rlc e                       ; 5209
	add a, e                    ; 520B
	ld e, a                     ; 520C
	ld a, [hl]                  ; 520D
	adc a, $00                  ; 520E
	ld h, a                     ; 5210
	ld l, e                     ; 5211
	ld a, [hli]                 ; 5212
	ld d, a                     ; 5213
	ld e, [hl]                  ; 5214

; de = period -> image NRx3/NRx4 (ch3: also NR30 = $80).
Track_SetPeriod:
	ld h, HIGH(wSoundRAM)       ; 5215
	ld a, LOW(wTrkHwOffset)     ; 5217
	add a, b                    ; 5219
	ld l, a                     ; 521A
	ld a, [hl]                  ; 521B
	cp $0A                      ; 521C
	jr z, .l_5227               ; 521E
	ld a, $03                   ; 5220
	call Track_RegAddrA         ; 5222
	jr .l_5231                  ; 5225

.l_5227:
	ld a, $00                   ; 5227
	call Track_RegAddrA         ; 5229
	ld [hl], $80                ; 522C
	inc l                       ; 522E
	inc l                       ; 522F
	inc l                       ; 5230
.l_5231:
	ld a, e                     ; 5231
	ld [hli], a                 ; 5232
	ld [hl], d                  ; 5233
	ret                         ; 5234


; release counter: when it reaches 0, switch the envelope to the instrument's release envelope.
Track_Release:
	ld h, HIGH(wSoundRAM)       ; 5235
	ld a, LOW(wTrkRelease)      ; 5237
	add a, b                    ; 5239
	ld l, a                     ; 523A
	ld a, [hl]                  ; 523B
	and a                       ; 523C
	ret z                       ; 523D
	cp $FF                      ; 523E
	ret z                       ; 5240
	dec [hl]                    ; 5241
	ret nz                      ; 5242
	ld a, LOW(wTrkInstrument)   ; 5243
	add a, b                    ; 5245
	ld l, a                     ; 5246
	ld a, [hl]                  ; 5247
	add a, a                    ; 5248
	add a, a                    ; 5249
	add a, $02                  ; 524A
	jp Track_LoadEnvelopeA      ; 524C


; Track_Env: envelope (instrument macro) stream, own wait counter and stack.
Track_Env:
	ld h, HIGH(wSoundRAM)       ; 524F
	ld a, LOW(wTrkEnvWait)      ; 5251
	add a, b                    ; 5253
	ld l, a                     ; 5254
	dec [hl]                    ; 5255
	jr z, Track_EnvRead         ; 5256
	ret                         ; 5258

Track_EnvNextByte:
	inc de                      ; 5259
Track_EnvRead:
	ld h, HIGH(wSoundRAM)       ; 525A
	ld a, [de]                  ; 525C
	ld c, a                     ; 525D
	and $E0                     ; 525E
	jr nz, .l_526D              ; 5260
	ld a, c                     ; 5262
	and $1F                     ; 5263
	ld c, a                     ; 5265
	ld a, LOW(wTrkEnvWait)      ; 5266
	add a, b                    ; 5268
	ld l, a                     ; 5269
	ld [hl], c                  ; 526A
	inc de                      ; 526B
	ret                         ; 526C

.l_526D:
	cp $20                      ; 526D
	jr nz, Track_EnvWaitFlag.l_528A; 526F
	push bc                     ; 5271
	push de                     ; 5272
	call SignExtendNibble       ; 5273
	call Track_AddPeriod        ; 5276
	pop de                      ; 5279
	pop bc                      ; 527A
Track_EnvWaitFlag:
	ld a, [de]                  ; 527B
	and $10                     ; 527C
	jr z, Track_EnvNextByte     ; 527E
	ld h, HIGH(wSoundRAM)       ; 5280
	ld a, LOW(wTrkEnvWait)      ; 5282
	add a, b                    ; 5284
	ld l, a                     ; 5285
	ld [hl], $01                ; 5286
	inc de                      ; 5288
	ret                         ; 5289

.l_528A:
	cp $40                      ; 528A
	jr nz, .l_5294              ; 528C
	ld a, c                     ; 528E
	and $0F                     ; 528F
	jp .l_52B2                  ; 5291

.l_5294:
	cp $60                      ; 5294
	jr nz, .l_52BA              ; 5296
	push de                     ; 5298
	call SignExtendNibble       ; 5299
	ld h, HIGH(wSoundRAM)       ; 529C
	ld a, LOW(wTrkVolume)       ; 529E
	add a, b                    ; 52A0
	ld l, a                     ; 52A1
	ld a, [hl]                  ; 52A2
	and $0F                     ; 52A3
	add a, e                    ; 52A5
	bit 7, a                    ; 52A6
	jr z, .l_52AB               ; 52A8
	xor a                       ; 52AA
.l_52AB:
	cp $10                      ; 52AB
	jr c, .l_52B1               ; 52AD
	ld a, $0F                   ; 52AF
.l_52B1:
	pop de                      ; 52B1
.l_52B2:
	push de                     ; 52B2
	call Track_SetVolume        ; 52B3
	pop de                      ; 52B6
	jp Track_EnvWaitFlag        ; 52B7

.l_52BA:
	cp $80                      ; 52BA
	jr nz, LoadWave.l_5311      ; 52BC
	ld h, HIGH(wSoundRAM)       ; 52BE
	ld a, LOW(wTrkHwOffset)     ; 52C0
	add a, b                    ; 52C2
	ld l, a                     ; 52C3
	ld a, [hl]                  ; 52C4
	cp $0A                      ; 52C5
	jr z, .l_52DC               ; 52C7
	ld a, $01                   ; 52C9
	call Track_RegAddrA         ; 52CB
	ld a, c                     ; 52CE
	rrca                        ; 52CF
	rrca                        ; 52D0
	and $C0                     ; 52D1
	ld c, a                     ; 52D3
	ld a, [hl]                  ; 52D4
	and $3F                     ; 52D5
	or c                        ; 52D7
	ld [hl], a                  ; 52D8
	jp Track_EnvWaitFlag        ; 52D9

.l_52DC:
	ld a, c                     ; 52DC
	and $0F                     ; 52DD
	ld hl, wCurWave             ; 52DF
	cp [hl]                     ; 52E2
	jr z, .l_5302               ; 52E3
	push de                     ; 52E5
	ld [hl], a                  ; 52E6
	swap a                      ; 52E7
	ld e, a                     ; 52E9
	ld d, $00                   ; 52EA
	ld hl, Wave0                ; 52EC
	add hl, de                  ; 52EF
	xor a                       ; 52F0
	ldh [rNR30], a              ; 52F1
	call LoadWave               ; 52F3
	ld a, $80                   ; 52F6
	ldh [rNR30], a              ; 52F8
	ld a, [$DE14]               ; 52FA
	set 7, a                    ; 52FD
	ldh [rNR34], a              ; 52FF
	pop de                      ; 5301
.l_5302:
	jp Track_EnvWaitFlag        ; 5302


; copy 16 bytes from hl to wave RAM.
LoadWave:
	ld de, _AUD3WAVERAM         ; 5305
	ld c, $10                   ; 5308
.l_530A:
	ld a, [hli]                 ; 530A
	ld [de], a                  ; 530B
	inc de                      ; 530C
	dec c                       ; 530D
	jr nz, .l_530A              ; 530E
	ret                         ; 5310

.l_5311:
	cp $E0                      ; 5311
	jr nz, .l_533A              ; 5313
	ld a, c                     ; 5315
	cp $F0                      ; 5316
	jr nz, .l_5326              ; 5318
	inc de                      ; 531A
	ld a, [de]                  ; 531B
	ld c, a                     ; 531C
	ld a, $00                   ; 531D
	call Track_RegAddr          ; 531F
	ld [hl], c                  ; 5322
	jp Track_EnvNextByte        ; 5323

.l_5326:
	cp $FF                      ; 5326
	jr nz, .l_5331              ; 5328
	ld a, LOW(wTrkEnvWait)      ; 532A
	add a, b                    ; 532C
	ld l, a                     ; 532D
	ld [hl], $00                ; 532E
	ret                         ; 5330

.l_5331:
	ld hl, wTrkEnvStack         ; 5331
	call Track_Flow             ; 5334
	jp Track_EnvRead            ; 5337

.l_533A:
	ret                         ; 533A


; a = envelope volume (low nibble of wTrkVolume); falls into Track_ApplyVolume.
Track_SetVolume:
	ld c, a                     ; 533B
	ld h, HIGH(wSoundRAM)       ; 533C
	ld a, LOW(wTrkVolume)       ; 533E
	add a, b                    ; 5340
	ld l, a                     ; 5341
	ld a, [hl]                  ; 5342
	and $F0                     ; 5343
	or c                        ; 5345
	ld [hl], a                  ; 5346

; output volume = env volume - (15 - channel volume) - (15 - master), clamped at 0;
; NRx2 high nibble, or NR32 through Ch3VolumeTable.
Track_ApplyVolume:
	push de                     ; 5347
	ld a, $FF                   ; 5348
	sub [hl]                    ; 534A
	swap a                      ; 534B
	and $0F                     ; 534D
	ld e, a                     ; 534F
	ld a, [hl]                  ; 5350
	and $0F                     ; 5351
	sub e                       ; 5353
	ld e, a                     ; 5354
	jr nc, .l_5359              ; 5355
	ld e, $00                   ; 5357
.l_5359:
	push hl                     ; 5359
	ld hl, wSfxAttenuation      ; 535A
	ld a, b                     ; 535D
	cp $04                      ; 535E
	jr c, .l_5363               ; 5360
	inc l                       ; 5362
.l_5363:
	ld a, $FF                   ; 5363
	sub [hl]                    ; 5365
	swap a                      ; 5366
	and $0F                     ; 5368
	ld d, a                     ; 536A
	pop hl                      ; 536B
	ld a, e                     ; 536C
	sub d                       ; 536D
	jr nc, .l_5371              ; 536E
	xor a                       ; 5370
.l_5371:
	ld e, a                     ; 5371
	ld a, LOW(wTrkHwOffset)     ; 5372
	add a, b                    ; 5374
	ld l, a                     ; 5375
	ld a, [hl]                  ; 5376
	cp $0A                      ; 5377
	jr z, .l_5389               ; 5379
	ld a, $02                   ; 537B
	call Track_RegAddrA         ; 537D
	swap e                      ; 5380
	ld a, [hl]                  ; 5382
	and $0F                     ; 5383
	or e                        ; 5385
	ld [hl], a                  ; 5386
	pop de                      ; 5387
	ret                         ; 5388

.l_5389:
	ld d, $00                   ; 5389
	ld hl, Ch3VolumeTable       ; 538B
	add hl, de                  ; 538E
	ld e, [hl]                  ; 538F
	ld a, $02                   ; 5390
	call Track_RegAddr          ; 5392
	ld [hl], e                  ; 5395
	pop de                      ; 5396
	ret                         ; 5397

Ch3VolumeTable:
	db $00, $60, $60, $60, $40, $40, $40, $40, $20, $20, $20, $20, $20, $20, $20, $20
SignExtendNibble:
	ld a, c                     ; 53A8
	and $0F                     ; 53A9
	ld d, $00                   ; 53AB
	bit 3, a                    ; 53AD
	jr z, .l_53B4               ; 53AF
	or $F0                      ; 53B1
	dec d                       ; 53B3
.l_53B4:
	ld e, a                     ; 53B4
	ret                         ; 53B5

Track_AddPeriod:
	ld a, $03                   ; 53B6
	call Track_RegAddr          ; 53B8
	ld a, e                     ; 53BB
	add a, [hl]                 ; 53BC
	ld [hli], a                 ; 53BD
	ld a, d                     ; 53BE
	adc a, [hl]                 ; 53BF
	ld [hl], a                  ; 53C0
	ret                         ; 53C1

Track_RegAddr:
	push af                     ; 53C2
	ld h, HIGH(wSoundRAM)       ; 53C3
	ld a, LOW(wTrkHwOffset)     ; 53C5
	add a, b                    ; 53C7
	ld l, a                     ; 53C8
	pop af                      ; 53C9
Track_RegAddrA:
	add a, [hl]                 ; 53CA
Track_RegAddrAbs:
	ld hl, wRegImage            ; 53CB
	add a, [hl]                 ; 53CE
	ld l, a                     ; 53CF
	ld h, HIGH(wSoundRAM)       ; 53D0
	ret                         ; 53D2


; h = a*e/256 via the game's floor(i*i/2) table at $DC00 (lo) / $DD00 (hi).
Multiply_AxE:
	push bc                     ; 53D3
	push de                     ; 53D4
	ld d, $DC                   ; 53D5
	ld l, a                     ; 53D7
	ld h, d                     ; 53D8
	and e                       ; 53D9
	rra                         ; 53DA
	ld a, [de]                  ; 53DB
	adc a, [hl]                 ; 53DC
	ld c, a                     ; 53DD
	inc d                       ; 53DE
	ld h, d                     ; 53DF
	ld a, [de]                  ; 53E0
	adc a, [hl]                 ; 53E1
	ld b, a                     ; 53E2
	ld a, l                     ; 53E3
	sub e                       ; 53E4
	jr nc, .l_53E9              ; 53E5
	cpl                         ; 53E7
	inc a                       ; 53E8
.l_53E9:
	ld l, a                     ; 53E9
	dec h                       ; 53EA
	ld a, c                     ; 53EB
	sub [hl]                    ; 53EC
	ld e, a                     ; 53ED
	inc h                       ; 53EE
	ld a, b                     ; 53EF
	sbc a, [hl]                 ; 53F0
	ld h, a                     ; 53F1
	ld l, e                     ; 53F2
	pop de                      ; 53F3
	pop bc                      ; 53F4
	ret                         ; 53F5

PeriodTable:
	dwbe $003B  ; C2
	dwbe $00AA
	dwbe $0112
	dwbe $0175
	dwbe $01D3
	dwbe $022B
	dwbe $027E
	dwbe $02CD
	dwbe $0317
	dwbe $035D
	dwbe $03A0
	dwbe $03DE
	dwbe $0419  ; C3
	dwbe $0451
	dwbe $0486
	dwbe $04B8
	dwbe $04E7
	dwbe $0513
	dwbe $053D
	dwbe $0564
	dwbe $058A
	dwbe $05AD
	dwbe $05CE
	dwbe $05EE
	dwbe $060B  ; C4
	dwbe $0627
	dwbe $0642
	dwbe $065B
	dwbe $0672
	dwbe $0689
	dwbe $069E
	dwbe $06B2
	dwbe $06C4
	dwbe $06D6
	dwbe $06E7
	dwbe $06F6
	dwbe $0705  ; C5
	dwbe $0713
	dwbe $0721
	dwbe $072D
	dwbe $0739
	dwbe $0744
	dwbe $074E
	dwbe $0758
	dwbe $0762
	dwbe $076B
	dwbe $0773
	dwbe $077B
	dwbe $0782  ; C6
	dwbe $0789
	dwbe $0790
	dwbe $0796
	dwbe $079C
	dwbe $07A2
	dwbe $07A7
	dwbe $07AC
	dwbe $07B1
	dwbe $07B5
	dwbe $07B9
	dwbe $07BD
	dwbe $07C1  ; C7
	dwbe $07C4
	dwbe $07C8
	dwbe $07CB
	dwbe $07CE
	dwbe $07D1
	dwbe $07D3
	dwbe $07D6
	dwbe $07D8
	dwbe $07DA
	dwbe $07DC
	dwbe $07DE
UnusedImageBaseTable:
	db $1A, $1A, $1A, $1A, $2E, $2E, $2E, $2E
TrackStackTable:
	db $10, $20, $30, $40, $50, $60, $70, $80
EnvStackTable:
	db $06, $16, $26, $36, $46, $56, $66, $76
TuningTable:
	dw PeriodTable - 6  ; tuning 0: entry 3 of this table is PeriodTable
NoiseTable:
	db $00, $10, $20, $30, $07, $23, $50, $33, $60, $43, $70, $45, $47, $55, $65
Wave0:
	db $22, $66, $AA, $EE, $FF, $FF, $FE, $EA, $A6, $66, $8A, $CF, $FE, $EC, $A6, $33
Wave1:
	db $FF, $FF, $FF, $FF, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $00, $00, $00, $00
Wave2:
	db $13, $57, $9B, $DF, $DB, $97, $53, $10, $13, $57, $9B, $DF, $DB, $97, $53, $10
