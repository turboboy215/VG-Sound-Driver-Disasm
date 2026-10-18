; bank 0: track start, update, interpreter, tables ($2B97-$30DF)


; Sound_StartTrack: c = track, de -> header entry - 1. Reads pointer + channel byte,
; resets the per-track state (base note $24, volume, instrument, length set, tuning, stacks).
Sound_StartTrack:
	ld hl, wTrkBaseNote         ; 2B97
	add hl, bc                  ; 2B9A
	ld [hl], $24                ; 2B9B
	xor a                       ; 2B9D
	ld hl, wTrkGate             ; 2B9E
	add hl, bc                  ; 2BA1
	ld [hl], a                  ; 2BA2
	ld hl, wTrkVolume           ; 2BA3
	add hl, bc                  ; 2BA6
	ld [hl], a                  ; 2BA7
	ld hl, wTrkInstrument       ; 2BA8
	add hl, bc                  ; 2BAB
	ld [hl], a                  ; 2BAC
	ld hl, wTrkLengthSet        ; 2BAD
	add hl, bc                  ; 2BB0
	ld [hl], a                  ; 2BB1
	ld hl, wTrkTuning           ; 2BB2
	add hl, bc                  ; 2BB5
	ld [hl], a                  ; 2BB6
	ld hl, TrackStackTable      ; 2BB7
	add hl, bc                  ; 2BBA
	ld a, [hl]                  ; 2BBB
	ld hl, wTrkStack            ; 2BBC
	add hl, bc                  ; 2BBF
	ld [hl], a                  ; 2BC0
	inc de                      ; 2BC1
	ld a, [de]                  ; 2BC2
	ld hl, wTrkPtrLo            ; 2BC3
	add hl, bc                  ; 2BC6
	ld [hl], a                  ; 2BC7
	inc de                      ; 2BC8
	ld a, [de]                  ; 2BC9
	ld hl, wTrkPtrHi            ; 2BCA
	add hl, bc                  ; 2BCD
	ld [hl], a                  ; 2BCE
	inc de                      ; 2BCF
	ld a, [de]                  ; 2BD0
	sra a                       ; 2BD1
	sra a                       ; 2BD3
	add a, LOW(HwOffsetTable)   ; 2BD5
	ld l, a                     ; 2BD7
	ld h, HIGH(HwOffsetTable)   ; 2BD8
	jr nc, .l_2BDD              ; 2BDA
	inc h                       ; 2BDC
.l_2BDD:
	ld a, [hl]                  ; 2BDD
	ld hl, wTrkHwOffset         ; 2BDE
	add hl, bc                  ; 2BE1
	ld [hl], a                  ; 2BE2
	ld hl, wTrkWait             ; 2BE3
	add hl, bc                  ; 2BE6
	ld [hl], $01                ; 2BE7
	ld hl, wTrkRelease          ; 2BE9
	add hl, bc                  ; 2BEC
	ld [hl], $01                ; 2BED
	ret                         ; 2BEF

HwOffsetTable:
	db $00, $05, $FF, $0F, $0A
TrackStackTable:
	db $10, $20, $30, $40, $50, $60, $70, $80

; Sound_Update (bank 0, once per frame): map bank $1F and run music tracks 7-4, map bank $1E
; and run SFX tracks 3-0, then jump to Sound_UpdateSfxAndOutput in bank $1E. Streams,
; instruments and envelopes are read from whichever bank is mapped; the two banks hold
; identical instrument tables and envelopes at $4000.
Sound_Update:
	ld a, BANK(SongTable)       ; 2BFD
	call SwitchBank             ; 2BFF
	ld b, $07                   ; 2C02
.l_2C04:
	ld h, HIGH(wSoundRAM)       ; 2C04
	ld a, LOW(wTrkWait)         ; 2C06
	add a, b                    ; 2C08
	ld l, a                     ; 2C09
	ld a, [hl]                  ; 2C0A
	and a                       ; 2C0B
	jr z, .l_2C48               ; 2C0C
	ld a, b                     ; 2C0E
	cp $04                      ; 2C0F
	ld a, $1A                   ; 2C11
	jr c, .l_2C17               ; 2C13
	ld a, $2E                   ; 2C15
.l_2C17:
	ldh [hRegImage], a          ; 2C17
	ld h, HIGH(wSoundRAM)       ; 2C19
	ld a, LOW(wTrkPtrLo)        ; 2C1B
	add a, b                    ; 2C1D
	ld l, a                     ; 2C1E
	push hl                     ; 2C1F
	ld e, [hl]                  ; 2C20
	add a, LOW(wTrkPtrHi - wTrkPtrLo); 2C21
	ld l, a                     ; 2C23
	push hl                     ; 2C24
	ld d, [hl]                  ; 2C25
	push bc                     ; 2C26
	call Track_Main             ; 2C27
	pop bc                      ; 2C2A
	pop hl                      ; 2C2B
	ld [hl], d                  ; 2C2C
	pop hl                      ; 2C2D
	ld [hl], e                  ; 2C2E
	call Track_Release          ; 2C2F
	ld h, HIGH(wSoundRAM)       ; 2C32
	ld a, LOW(wTrkEnvPtrLo)     ; 2C34
	add a, b                    ; 2C36
	ld l, a                     ; 2C37
	push hl                     ; 2C38
	ld e, [hl]                  ; 2C39
	add a, LOW(wTrkEnvPtrHi - wTrkEnvPtrLo); 2C3A
	ld l, a                     ; 2C3C
	push hl                     ; 2C3D
	ld d, [hl]                  ; 2C3E
	push bc                     ; 2C3F
	call Track_Env              ; 2C40
	pop bc                      ; 2C43
	pop hl                      ; 2C44
	ld [hl], d                  ; 2C45
	pop hl                      ; 2C46
	ld [hl], e                  ; 2C47
.l_2C48:
	ld a, $04                   ; 2C48
	cp b                        ; 2C4A
	jr nz, .l_2C52              ; 2C4B
	ld a, BANK(SfxTable)        ; 2C4D
	call SwitchBank             ; 2C4F
.l_2C52:
	dec b                       ; 2C52
	bit 7, b                    ; 2C53
	jr z, .l_2C04               ; 2C55
	jp Sound_UpdateSfxAndOutput ; 2C57


; Track_Main: b = track, de = stream pointer. Counts wTrkWait down; at 0 reads bytes until
; a note, rest or hold sets a new wait.
Track_Main:
	ld h, HIGH(wSoundRAM)       ; 2C5A
	ld a, LOW(wTrkWait)         ; 2C5C
	add a, b                    ; 2C5E
	ld l, a                     ; 2C5F
	dec [hl]                    ; 2C60
	jr z, Track_MainRead        ; 2C61
	ret                         ; 2C63

Track_MainNextByte:
	inc de                      ; 2C64
Track_MainRead:
	ld h, HIGH(wSoundRAM)       ; 2C65
	ld a, [de]                  ; 2C67
	ld c, a                     ; 2C68
	and $E0                     ; 2C69
	cp $E0                      ; 2C6B
	jp z, Track_Command         ; 2C6D
	ld a, LOW(wTrkHwOffset)     ; 2C70
	add a, b                    ; 2C72
	ld l, a                     ; 2C73
	ld a, [hl]                  ; 2C74
	cp $0F                      ; 2C75
	jr nz, .l_2C97              ; 2C77
	bit 4, c                    ; 2C79
	jp nz, Track_NoteOn         ; 2C7B
	ld a, c                     ; 2C7E
	and $0F                     ; 2C7F
	cp $0F                      ; 2C81
	jr z, Track_Rest            ; 2C83
	add a, LOW(NoiseTable)      ; 2C85
	ld l, a                     ; 2C87
	ld h, HIGH(NoiseTable)      ; 2C88
	jr nc, .l_2C8D              ; 2C8A
	inc h                       ; 2C8C
.l_2C8D:
	ld c, [hl]                  ; 2C8D
	ld a, $12                   ; 2C8E
	call Track_RegAddrAbs       ; 2C90
	ld [hl], c                  ; 2C93
	jp Track_NoteOn             ; 2C94

.l_2C97:
	ld a, c                     ; 2C97
	and $1F                     ; 2C98
	cp $10                      ; 2C9A
	jr z, Track_Rest            ; 2C9C
	bit 4, a                    ; 2C9E
	jr z, .l_2CA4               ; 2CA0
	or $E0                      ; 2CA2
.l_2CA4:
	ld c, a                     ; 2CA4
	ld a, LOW(wTrkBaseNote)     ; 2CA5
	add a, b                    ; 2CA7
	ld l, a                     ; 2CA8
	ld a, [hl]                  ; 2CA9
	add a, c                    ; 2CAA
	push de                     ; 2CAB
	call Track_SetNote          ; 2CAC
	pop de                      ; 2CAF
	jp Track_NoteOn             ; 2CB0

Track_Rest:
	call Track_ReadLength       ; 2CB3
	ld c, a                     ; 2CB6
	ld h, HIGH(wSoundRAM)       ; 2CB7
	ld a, LOW(wTrkRelease)      ; 2CB9
	add a, b                    ; 2CBB
	ld l, a                     ; 2CBC
	ld a, [hl]                  ; 2CBD
	and a                       ; 2CBE
	jr z, Track_NoteDone        ; 2CBF
	ld [hl], $01                ; 2CC1
Track_NoteDone:
	ld a, c                     ; 2CC3
	and a                       ; 2CC4
	jp z, Track_MainNextByte    ; 2CC5
	inc de                      ; 2CC8
	ret                         ; 2CC9


; note: wait = length; release counter = $FF or length*gate/256; start the instrument envelope.
Track_NoteOn:
	call Track_ReadLength       ; 2CCA
	ld c, a                     ; 2CCD
	ld h, HIGH(wSoundRAM)       ; 2CCE
	ld a, LOW(wTrkRelease)      ; 2CD0
	add a, b                    ; 2CD2
	ld l, a                     ; 2CD3
	ld [hl], $FF                ; 2CD4
	add a, LOW(wTrkGate - wTrkRelease); 2CD6
	ld l, a                     ; 2CD8
	ld a, [hl]                  ; 2CD9
	and a                       ; 2CDA
	jr z, .l_2CEF               ; 2CDB
	push bc                     ; 2CDD
	push de                     ; 2CDE
	ld e, a                     ; 2CDF
	ld h, HIGH(wSoundRAM)       ; 2CE0
	ld a, LOW(wTrkRelease)      ; 2CE2
	add a, b                    ; 2CE4
	ld l, a                     ; 2CE5
	push hl                     ; 2CE6
	ld b, e                     ; 2CE7
	call Multiply_BxC           ; 2CE8
	pop hl                      ; 2CEB
	ld [hl], b                  ; 2CEC
	pop de                      ; 2CED
	pop bc                      ; 2CEE
.l_2CEF:
	push bc                     ; 2CEF
	call Track_StartEnvelope    ; 2CF0
	pop bc                      ; 2CF3
	jp Track_NoteDone           ; 2CF4


; point the envelope stream at the instrument's attack envelope (unless STATIC).
Track_StartEnvelope:
	ld h, HIGH(wSoundRAM)       ; 2CF7
	ld a, LOW(wTrkInstrument)   ; 2CF9
	add a, b                    ; 2CFB
	ld l, a                     ; 2CFC
	ld a, [hl]                  ; 2CFD
	bit 7, a                    ; 2CFE
	jr nz, Track_LoadEnvelopeA.l_2D33; 2D00
Track_LoadEnvelope:
	add a, a                    ; 2D02
	add a, a                    ; 2D03
Track_LoadEnvelopeA:
	push de                     ; 2D04
	add a, LOW(InstrumentTable) ; 2D05
	ld e, a                     ; 2D07
	ld d, HIGH(InstrumentTable) ; the same address in both sound banks; 2D08
	jr nc, .l_2D0D              ; 2D0A
	inc d                       ; 2D0C
.l_2D0D:
	ld h, HIGH(wSoundRAM)       ; 2D0D
	ld a, LOW(wTrkEnvPtrLo)     ; 2D0F
	add a, b                    ; 2D11
	ld l, a                     ; 2D12
	ld a, [de]                  ; 2D13
	ld [hl], a                  ; 2D14
	ld a, LOW(wTrkEnvPtrHi)     ; 2D15
	add a, b                    ; 2D17
	ld l, a                     ; 2D18
	inc de                      ; 2D19
	ld a, [de]                  ; 2D1A
	ld [hl], a                  ; 2D1B
	ld h, HIGH(EnvStackTable)   ; 2D1C
	ld a, LOW(EnvStackTable)    ; 2D1E
	add a, b                    ; 2D20
	ld l, a                     ; 2D21
	jr nc, .l_2D25              ; 2D22
	inc h                       ; 2D24
.l_2D25:
	ld c, [hl]                  ; 2D25
	ld h, HIGH(wSoundRAM)       ; 2D26
	ld a, LOW(wTrkEnvStack)     ; 2D28
	add a, b                    ; 2D2A
	ld l, a                     ; 2D2B
	ld [hl], c                  ; 2D2C
	add a, LOW(wTrkEnvWait - wTrkEnvStack); 2D2D
	ld l, a                     ; 2D2F
	ld [hl], $01                ; 2D30
	pop de                      ; 2D32
.l_2D33:
	ret                         ; 2D33


; length: LLL = 6 -> next byte, else LengthSets[wTrkLengthSet + LLL].
Track_ReadLength:
	ld a, [de]                  ; 2D34
	and $E0                     ; 2D35
	cp $C0                      ; 2D37
	jr nz, .l_2D3F              ; 2D39
	inc de                      ; 2D3B
	ld a, [de]                  ; 2D3C
	jr .l_2D56                  ; 2D3D

.l_2D3F:
	ld h, HIGH(wSoundRAM)       ; 2D3F
	ld a, LOW(wTrkLengthSet)    ; 2D41
	add a, b                    ; 2D43
	ld l, a                     ; 2D44
	ld a, [de]                  ; 2D45
	and $E0                     ; 2D46
	swap a                      ; 2D48
	srl a                       ; 2D4A
	add a, [hl]                 ; 2D4C
	add a, LOW(wLengthSets)     ; 2D4D
	ld l, a                     ; 2D4F
	ld a, $00                   ; 2D50
	adc a, HIGH(wLengthSets)    ; 2D52
	ld h, a                     ; 2D54
	ld a, [hl]                  ; 2D55
.l_2D56:
	ld c, a                     ; 2D56
	ld h, HIGH(wSoundRAM)       ; 2D57
	ld a, LOW(wTrkWait)         ; 2D59
	add a, b                    ; 2D5B
	ld l, a                     ; 2D5C
	ld a, c                     ; 2D5D
	ld [hl], a                  ; 2D5E
	ret                         ; 2D5F


; $E0-$FF commands. Unlisted values fall through to the flow-control handler, which ignores
; them: the same byte is then read again forever.
Track_Command:
	ld a, c                     ; 2D60
	cp $F0                      ; 2D61
	jr nz, .l_2D7D              ; 2D63
	inc de                      ; 2D65
	ld h, HIGH(wSoundRAM)       ; 2D66
	ld a, LOW(wTrkVolume)       ; 2D68
	add a, b                    ; 2D6A
	ld l, a                     ; 2D6B
	ld a, [de]                  ; 2D6C
.l_2D6D:
	swap a                      ; 2D6D
	and $F0                     ; 2D6F
	ld c, a                     ; 2D71
	ld a, [hl]                  ; 2D72
	and $0F                     ; 2D73
	or c                        ; 2D75
	ld [hl], a                  ; 2D76
	call Track_ApplyVolume      ; 2D77
	jp Track_MainNextByte       ; 2D7A

.l_2D7D:
	cp $F1                      ; 2D7D
	jr nz, .l_2DA1              ; 2D7F
	inc de                      ; 2D81
	ld a, [de]                  ; 2D82
	ld c, a                     ; 2D83
	ld h, HIGH(wSoundRAM)       ; 2D84
	ld a, LOW(wTrkVolume)       ; 2D86
	add a, b                    ; 2D88
	ld l, a                     ; 2D89
	ld a, [hl]                  ; 2D8A
	swap a                      ; 2D8B
	and $0F                     ; 2D8D
	add a, c                    ; 2D8F
	bit 7, c                    ; 2D90
	jr nz, .l_2D9C              ; 2D92
	cp $10                      ; 2D94
	jr c, .l_2D9F               ; 2D96
	ld a, $0F                   ; 2D98
	jr .l_2D9F                  ; 2D9A

.l_2D9C:
	jr c, .l_2D9F               ; 2D9C
	xor a                       ; 2D9E
.l_2D9F:
	jr .l_2D6D                  ; 2D9F

.l_2DA1:
	cp $F2                      ; 2DA1
	jr nz, .l_2DB6              ; 2DA3
	inc de                      ; 2DA5
	ld a, [de]                  ; 2DA6
	add a, a                    ; 2DA7
	ld c, a                     ; 2DA8
	add a, a                    ; 2DA9
	add a, c                    ; 2DAA
	ld hl, wTrkLengthSet        ; 2DAB
.l_2DAE:
	ld c, a                     ; 2DAE
	ld a, l                     ; 2DAF
	add a, b                    ; 2DB0
	ld l, a                     ; 2DB1
	ld [hl], c                  ; 2DB2
	jp Track_MainNextByte       ; 2DB3

.l_2DB6:
	cp $F3                      ; 2DB6
	jr nz, .l_2DCB              ; 2DB8
	inc de                      ; 2DBA
	ld h, HIGH(wSoundRAM)       ; 2DBB
	ld a, LOW(wTrkWait)         ; 2DBD
	add a, b                    ; 2DBF
	ld l, a                     ; 2DC0
	ld a, [de]                  ; 2DC1
	ld [hl], a                  ; 2DC2
	ld a, LOW(wTrkRelease)      ; 2DC3
	add a, b                    ; 2DC5
	ld l, a                     ; 2DC6
	ld [hl], $FF                ; 2DC7
	inc de                      ; 2DC9
	ret                         ; 2DCA

.l_2DCB:
	cp $F4                      ; 2DCB
	jr nz, .l_2DD7              ; 2DCD
	inc de                      ; 2DCF
	ld a, [de]                  ; 2DD0
	ld hl, wTrkGate             ; 2DD1
	jp .l_2DAE                  ; 2DD4

.l_2DD7:
	cp $F5                      ; 2DD7
	jr nz, .l_2DE3              ; 2DD9
	inc de                      ; 2DDB
	ld a, [de]                  ; 2DDC
	ld hl, wTrkBaseNote         ; 2DDD
	jp .l_2DAE                  ; 2DE0

.l_2DE3:
	cp $F6                      ; 2DE3
	jr nz, .l_2DF8              ; 2DE5
	inc de                      ; 2DE7
	ld h, HIGH(wSoundRAM)       ; 2DE8
	ld a, LOW(wTrkInstrument)   ; 2DEA
	add a, b                    ; 2DEC
	ld l, a                     ; 2DED
	ld a, [de]                  ; 2DEE
	ld [hl], a                  ; 2DEF
	bit 7, a                    ; 2DF0
	call nz, Track_LoadEnvelope ; 2DF2
	jp Track_MainNextByte       ; 2DF5

.l_2DF8:
	cp $F7                      ; 2DF8
	jr nz, .l_2E04              ; 2DFA
	inc de                      ; 2DFC
	ld a, [de]                  ; 2DFD
	ld hl, wTrkTuning           ; 2DFE
	jp .l_2DAE                  ; 2E01

.l_2E04:
	cp $E2                      ; 2E04
	jr nz, .l_2E1A              ; 2E06
	inc de                      ; 2E08
	ld a, [de]                  ; 2E09
	ld c, a                     ; 2E0A
	inc de                      ; 2E0B
	ld a, [de]                  ; 2E0C
	push de                     ; 2E0D
	ld d, a                     ; 2E0E
	ld e, c                     ; 2E0F
	call Track_SetPeriod        ; 2E10
	call Track_StartEnvelope    ; 2E13
	pop de                      ; 2E16
	jp Track_MainNextByte       ; 2E17

.l_2E1A:
	cp $E3                      ; 2E1A
	jr nz, .l_2E31              ; 2E1C
	inc de                      ; 2E1E
	ld a, [de]                  ; 2E1F
	push de                     ; 2E20
	cpl                         ; 2E21
	inc a                       ; 2E22
	ld e, a                     ; 2E23
	ld d, $00                   ; 2E24
	rla                         ; 2E26
	jr nc, .l_2E2A              ; 2E27
	dec d                       ; 2E29
.l_2E2A:
	call Track_AddPeriod        ; 2E2A
	pop de                      ; 2E2D
	jp Track_MainNextByte       ; 2E2E

.l_2E31:
	cp $FE                      ; 2E31
	jr nz, .l_2E6B              ; 2E33
	inc de                      ; 2E35
	ld a, [de]                  ; 2E36
	ld c, a                     ; 2E37
	push de                     ; 2E38
	ld h, HIGH(wSoundRAM)       ; 2E39
	ld a, LOW(wTrkHwOffset)     ; 2E3B
	add a, b                    ; 2E3D
	ld l, a                     ; 2E3E
	ld e, [hl]                  ; 2E3F
	srl e                       ; 2E40
	srl e                       ; 2E42
	ld d, $00                   ; 2E44
	ld hl, wTrkPan              ; 2E46
	add hl, de                  ; 2E49
	ld a, c                     ; 2E4A
	rra                         ; 2E4B
	jr nc, .l_2E50              ; 2E4C
	set 4, d                    ; 2E4E
.l_2E50:
	rra                         ; 2E50
	jr nc, .l_2E54              ; 2E51
	inc d                       ; 2E53
.l_2E54:
	inc e                       ; 2E54
	dec e                       ; 2E55
	jr z, .l_2E5D               ; 2E56
.l_2E58:
	rlc d                       ; 2E58
	dec e                       ; 2E5A
	jr nz, .l_2E58              ; 2E5B
.l_2E5D:
	ld a, b                     ; 2E5D
	cp $04                      ; 2E5E
	jr c, .l_2E66               ; 2E60
	inc l                       ; 2E62
	inc l                       ; 2E63
	inc l                       ; 2E64
	inc l                       ; 2E65
.l_2E66:
	ld [hl], d                  ; 2E66
	pop de                      ; 2E67
	jp Track_MainNextByte       ; 2E68

.l_2E6B:
	cp $E1                      ; 2E6B
	jr nz, .l_2E77              ; 2E6D
	inc de                      ; 2E6F
	ld a, [de]                  ; 2E70
	ld [wSoundSync], a          ; 2E71
	jp Track_MainNextByte       ; 2E74

.l_2E77:
	cp $FF                      ; 2E77
	jr nz, .l_2E8B              ; 2E79
	ld h, HIGH(wSoundRAM)       ; 2E7B
	ld a, LOW(wTrkWait)         ; 2E7D
	add a, b                    ; 2E7F
	ld l, a                     ; 2E80
	ld [hl], $00                ; 2E81
	add a, LOW(wTrkEnvWait - wTrkWait); 2E83
	ld l, a                     ; 2E85
	xor a                       ; 2E86
	ld [hl], a                  ; 2E87
	jp Track_SetVolume          ; 2E88

.l_2E8B:
	ld hl, wTrkStack            ; 2E8B
	call Track_Flow             ; 2E8E
	jp Track_MainRead           ; 2E91


; flow control for the main stream: stack pointer = wSoundStacks + wTrkStack[b].
Track_Flow:
	ld a, l                     ; 2E94
	add a, b                    ; 2E95
	ld l, a                     ; 2E96
	push hl                     ; 2E97
	ld a, LOW(wSoundStacks)     ; 2E98
	add a, [hl]                 ; 2E9A
	ld l, a                     ; 2E9B
	ld a, HIGH(wSoundStacks)    ; 2E9C
	adc a, $00                  ; 2E9E
	ld h, a                     ; 2EA0
	call Stream_Flow            ; 2EA1
	ld a, l                     ; 2EA4
	sub LOW(wSoundStacks)       ; 2EA5
	pop hl                      ; 2EA7
	ld [hl], a                  ; 2EA8
	ret                         ; 2EA9


; $F8 jump, $FA call (push return), $FB return, $FC loop start (push count+address),
; $FD loop end (count down, jump back or pop). hl = stack pointer, de = stream.
Stream_Flow:
	ld a, [de]                  ; 2EAA
	cp $F8                      ; 2EAB
	jr nz, .l_2EB7              ; 2EAD
	inc de                      ; 2EAF
	ld a, [de]                  ; 2EB0
	ld c, a                     ; 2EB1
	inc de                      ; 2EB2
	ld a, [de]                  ; 2EB3
	ld d, a                     ; 2EB4
	ld e, c                     ; 2EB5
	ret                         ; 2EB6

.l_2EB7:
	cp $FA                      ; 2EB7
	jr nz, .l_2ECA              ; 2EB9
	inc de                      ; 2EBB
	inc de                      ; 2EBC
	inc de                      ; 2EBD
	dec hl                      ; 2EBE
	ld [hl], d                  ; 2EBF
	dec hl                      ; 2EC0
	ld [hl], e                  ; 2EC1
	dec de                      ; 2EC2
	ld a, [de]                  ; 2EC3
	ld c, a                     ; 2EC4
	dec de                      ; 2EC5
	ld a, [de]                  ; 2EC6
	ld e, a                     ; 2EC7
	ld d, c                     ; 2EC8
	ret                         ; 2EC9

.l_2ECA:
	cp $FB                      ; 2ECA
	jr nz, .l_2ED3              ; 2ECC
	ld e, [hl]                  ; 2ECE
	inc hl                      ; 2ECF
	ld d, [hl]                  ; 2ED0
	inc hl                      ; 2ED1
	ret                         ; 2ED2

.l_2ED3:
	cp $FC                      ; 2ED3
	jr nz, .l_2EE2              ; 2ED5
	inc de                      ; 2ED7
	ld a, [de]                  ; 2ED8
	ld c, a                     ; 2ED9
	inc de                      ; 2EDA
	dec hl                      ; 2EDB
	ld [hl], d                  ; 2EDC
	dec hl                      ; 2EDD
	ld [hl], e                  ; 2EDE
	dec hl                      ; 2EDF
	ld [hl], c                  ; 2EE0
	ret                         ; 2EE1

.l_2EE2:
	cp $FD                      ; 2EE2
	jr nz, .l_2EF4              ; 2EE4
	dec [hl]                    ; 2EE6
	jr z, .l_2EF0               ; 2EE7
	inc hl                      ; 2EE9
	ld e, [hl]                  ; 2EEA
	inc hl                      ; 2EEB
	ld d, [hl]                  ; 2EEC
	dec hl                      ; 2EED
	dec hl                      ; 2EEE
	ret                         ; 2EEF

.l_2EF0:
	inc hl                      ; 2EF0
	inc hl                      ; 2EF1
	inc hl                      ; 2EF2
	inc de                      ; 2EF3
.l_2EF4:
	ret                         ; 2EF4


; a = note index -> period from the tuning table (big-endian words; index*2 via rlc).
Track_SetNote:
	ld e, a                     ; 2EF5
	ld a, LOW(wTrkTuning)       ; 2EF6
	add a, b                    ; 2EF8
	ld l, a                     ; 2EF9
	ld a, [hl]                  ; 2EFA
	add a, a                    ; 2EFB
	add a, LOW(TuningTable)     ; 2EFC
	ld l, a                     ; 2EFE
	ld a, $00                   ; 2EFF
	adc a, HIGH(TuningTable)    ; 2F01
	ld h, a                     ; 2F03
	ld a, [hli]                 ; 2F04
	rlc e                       ; 2F05
	add a, e                    ; 2F07
	ld e, a                     ; 2F08
	ld a, [hl]                  ; 2F09
	adc a, $00                  ; 2F0A
	ld h, a                     ; 2F0C
	ld l, e                     ; 2F0D
	ld a, [hli]                 ; 2F0E
	ld d, a                     ; 2F0F
	ld e, [hl]                  ; 2F10

; de = period -> image NRx3/NRx4 (ch3: also NR30 = $80).
Track_SetPeriod:
	ld h, HIGH(wSoundRAM)       ; 2F11
	ld a, LOW(wTrkHwOffset)     ; 2F13
	add a, b                    ; 2F15
	ld l, a                     ; 2F16
	ld a, [hl]                  ; 2F17
	cp $0A                      ; 2F18
	jr z, .l_2F23               ; 2F1A
	ld a, $03                   ; 2F1C
	call Track_RegAddrA         ; 2F1E
	jr .l_2F2D                  ; 2F21

.l_2F23:
	ld a, $00                   ; 2F23
	call Track_RegAddrA         ; 2F25
	ld [hl], $80                ; 2F28
	inc l                       ; 2F2A
	inc l                       ; 2F2B
	inc l                       ; 2F2C
.l_2F2D:
	ld a, e                     ; 2F2D
	ld [hli], a                 ; 2F2E
	ld [hl], d                  ; 2F2F
	ret                         ; 2F30


; release counter: when it reaches 0, switch the envelope to the instrument's release envelope.
Track_Release:
	ld h, HIGH(wSoundRAM)       ; 2F31
	ld a, LOW(wTrkRelease)      ; 2F33
	add a, b                    ; 2F35
	ld l, a                     ; 2F36
	ld a, [hl]                  ; 2F37
	and a                       ; 2F38
	ret z                       ; 2F39
	cp $FF                      ; 2F3A
	ret z                       ; 2F3C
	dec [hl]                    ; 2F3D
	ret nz                      ; 2F3E
	ld a, LOW(wTrkInstrument)   ; 2F3F
	add a, b                    ; 2F41
	ld l, a                     ; 2F42
	ld a, [hl]                  ; 2F43
	add a, a                    ; 2F44
	add a, a                    ; 2F45
	add a, $02                  ; 2F46
	jp Track_LoadEnvelopeA      ; 2F48


; Track_Env: envelope (instrument macro) stream, own wait counter and stack.
Track_Env:
	ld h, HIGH(wSoundRAM)       ; 2F4B
	ld a, LOW(wTrkEnvWait)      ; 2F4D
	add a, b                    ; 2F4F
	ld l, a                     ; 2F50
	dec [hl]                    ; 2F51
	jr z, Track_EnvRead         ; 2F52
	ret                         ; 2F54

Track_EnvNextByte:
	inc de                      ; 2F55
Track_EnvRead:
	ld h, HIGH(wSoundRAM)       ; 2F56
	ld a, [de]                  ; 2F58
	ld c, a                     ; 2F59
	and $E0                     ; 2F5A
	jr nz, .l_2F69              ; 2F5C
	ld a, c                     ; 2F5E
	and $1F                     ; 2F5F
	ld c, a                     ; 2F61
	ld a, LOW(wTrkEnvWait)      ; 2F62
	add a, b                    ; 2F64
	ld l, a                     ; 2F65
	ld [hl], c                  ; 2F66
	inc de                      ; 2F67
	ret                         ; 2F68

.l_2F69:
	cp $20                      ; 2F69
	jr nz, Track_EnvWaitFlag.l_2F86; 2F6B
	push bc                     ; 2F6D
	push de                     ; 2F6E
	call SignExtendNibble       ; 2F6F
	call Track_AddPeriod        ; 2F72
	pop de                      ; 2F75
	pop bc                      ; 2F76
Track_EnvWaitFlag:
	ld a, [de]                  ; 2F77
	and $10                     ; 2F78
	jr z, Track_EnvNextByte     ; 2F7A
	ld h, HIGH(wSoundRAM)       ; 2F7C
	ld a, LOW(wTrkEnvWait)      ; 2F7E
	add a, b                    ; 2F80
	ld l, a                     ; 2F81
	ld [hl], $01                ; 2F82
	inc de                      ; 2F84
	ret                         ; 2F85

.l_2F86:
	cp $40                      ; 2F86
	jr nz, .l_2F90              ; 2F88
	ld a, c                     ; 2F8A
	and $0F                     ; 2F8B
	jp .l_2FAE                  ; 2F8D

.l_2F90:
	cp $60                      ; 2F90
	jr nz, .l_2FB6              ; 2F92
	push de                     ; 2F94
	call SignExtendNibble       ; 2F95
	ld h, HIGH(wSoundRAM)       ; 2F98
	ld a, LOW(wTrkVolume)       ; 2F9A
	add a, b                    ; 2F9C
	ld l, a                     ; 2F9D
	ld a, [hl]                  ; 2F9E
	and $0F                     ; 2F9F
	add a, e                    ; 2FA1
	bit 7, a                    ; 2FA2
	jr z, .l_2FA7               ; 2FA4
	xor a                       ; 2FA6
.l_2FA7:
	cp $10                      ; 2FA7
	jr c, .l_2FAD               ; 2FA9
	ld a, $0F                   ; 2FAB
.l_2FAD:
	pop de                      ; 2FAD
.l_2FAE:
	push de                     ; 2FAE
	call Track_SetVolume        ; 2FAF
	pop de                      ; 2FB2
	jp Track_EnvWaitFlag        ; 2FB3

.l_2FB6:
	cp $80                      ; 2FB6
	jr nz, LoadWave.l_300D      ; 2FB8
	ld h, HIGH(wSoundRAM)       ; 2FBA
	ld a, LOW(wTrkHwOffset)     ; 2FBC
	add a, b                    ; 2FBE
	ld l, a                     ; 2FBF
	ld a, [hl]                  ; 2FC0
	cp $0A                      ; 2FC1
	jr z, .l_2FD8               ; 2FC3
	ld a, $01                   ; 2FC5
	call Track_RegAddrA         ; 2FC7
	ld a, c                     ; 2FCA
	rrca                        ; 2FCB
	rrca                        ; 2FCC
	and $C0                     ; 2FCD
	ld c, a                     ; 2FCF
	ld a, [hl]                  ; 2FD0
	and $3F                     ; 2FD1
	or c                        ; 2FD3
	ld [hl], a                  ; 2FD4
	jp Track_EnvWaitFlag        ; 2FD5

.l_2FD8:
	ld a, c                     ; 2FD8
	and $0F                     ; 2FD9
	ld hl, wCurWave             ; 2FDB
	cp [hl]                     ; 2FDE
	jr z, .l_2FFE               ; 2FDF
	push de                     ; 2FE1
	ld [hl], a                  ; 2FE2
	swap a                      ; 2FE3
	ld e, a                     ; 2FE5
	ld d, $00                   ; 2FE6
	ld hl, wWaves               ; 2FE8
	add hl, de                  ; 2FEB
	xor a                       ; 2FEC
	ldh [rNR30], a              ; 2FED
	call LoadWave               ; 2FEF
	ld a, $80                   ; 2FF2
	ldh [rNR30], a              ; 2FF4
	ld a, [$CE14]               ; 2FF6
	set 7, a                    ; 2FF9
	ldh [rNR34], a              ; 2FFB
	pop de                      ; 2FFD
.l_2FFE:
	jp Track_EnvWaitFlag        ; 2FFE


; copy 16 bytes from hl to wave RAM.
LoadWave:
	ld de, _AUD3WAVERAM         ; 3001
	ld c, $10                   ; 3004
.l_3006:
	ld a, [hli]                 ; 3006
	ld [de], a                  ; 3007
	inc de                      ; 3008
	dec c                       ; 3009
	jr nz, .l_3006              ; 300A
	ret                         ; 300C

.l_300D:
	cp $E0                      ; 300D
	jr nz, .l_3036              ; 300F
	ld a, c                     ; 3011
	cp $F0                      ; 3012
	jr nz, .l_3022              ; 3014
	inc de                      ; 3016
	ld a, [de]                  ; 3017
	ld c, a                     ; 3018
	ld a, $00                   ; 3019
	call Track_RegAddr          ; 301B
	ld [hl], c                  ; 301E
	jp Track_EnvNextByte        ; 301F

.l_3022:
	cp $FF                      ; 3022
	jr nz, .l_302D              ; 3024
	ld a, LOW(wTrkEnvWait)      ; 3026
	add a, b                    ; 3028
	ld l, a                     ; 3029
	ld [hl], $00                ; 302A
	ret                         ; 302C

.l_302D:
	ld hl, wTrkEnvStack         ; 302D
	call Track_Flow             ; 3030
	jp Track_EnvRead            ; 3033

.l_3036:
	ret                         ; 3036


; a = envelope volume (low nibble of wTrkVolume); falls into Track_ApplyVolume.
Track_SetVolume:
	ld c, a                     ; 3037
	ld h, HIGH(wSoundRAM)       ; 3038
	ld a, LOW(wTrkVolume)       ; 303A
	add a, b                    ; 303C
	ld l, a                     ; 303D
	ld a, [hl]                  ; 303E
	and $F0                     ; 303F
	or c                        ; 3041
	ld [hl], a                  ; 3042

; output volume = env volume - (15 - channel volume) - (15 - master), clamped at 0;
; NRx2 high nibble, or NR32 through Ch3VolumeTable.
Track_ApplyVolume:
	push de                     ; 3043
	ld a, $FF                   ; 3044
	sub [hl]                    ; 3046
	swap a                      ; 3047
	and $0F                     ; 3049
	ld e, a                     ; 304B
	ld a, [hl]                  ; 304C
	and $0F                     ; 304D
	sub e                       ; 304F
	ld e, a                     ; 3050
	jr nc, .l_3055              ; 3051
	ld e, $00                   ; 3053
.l_3055:
	push hl                     ; 3055
	ld hl, wSfxAttenuation      ; 3056
	ld a, b                     ; 3059
	cp $04                      ; 305A
	jr c, .l_305F               ; 305C
	inc l                       ; 305E
.l_305F:
	ld a, $FF                   ; 305F
	sub [hl]                    ; 3061
	swap a                      ; 3062
	and $0F                     ; 3064
	ld d, a                     ; 3066
	pop hl                      ; 3067
	ld a, e                     ; 3068
	sub d                       ; 3069
	jr nc, .l_306D              ; 306A
	xor a                       ; 306C
.l_306D:
	ld e, a                     ; 306D
	ld a, LOW(wTrkHwOffset)     ; 306E
	add a, b                    ; 3070
	ld l, a                     ; 3071
	ld a, [hl]                  ; 3072
	cp $0A                      ; 3073
	jr z, .l_3085               ; 3075
	ld a, $02                   ; 3077
	call Track_RegAddrA         ; 3079
	swap e                      ; 307C
	ld a, [hl]                  ; 307E
	and $0F                     ; 307F
	or e                        ; 3081
	ld [hl], a                  ; 3082
	pop de                      ; 3083
	ret                         ; 3084

.l_3085:
	srl e                       ; 3085
	srl e                       ; 3087
	ld d, $00                   ; 3089
	ld hl, Ch3VolumeTable       ; 308B
	add hl, de                  ; 308E
	ld e, [hl]                  ; 308F
	ld a, $02                   ; 3090
	call Track_RegAddr          ; 3092
	ld [hl], e                  ; 3095
	pop de                      ; 3096
	ret                         ; 3097

Ch3VolumeTable:
	db $00, $60, $40, $20
SignExtendNibble:
	ld a, c                     ; 309C
	and $0F                     ; 309D
	ld d, $00                   ; 309F
	bit 3, a                    ; 30A1
	jr z, .l_30A8               ; 30A3
	or $F0                      ; 30A5
	dec d                       ; 30A7
.l_30A8:
	ld e, a                     ; 30A8
	ret                         ; 30A9

Track_AddPeriod:
	ld a, $03                   ; 30AA
	call Track_RegAddr          ; 30AC
	ld a, e                     ; 30AF
	add a, [hl]                 ; 30B0
	ld [hli], a                 ; 30B1
	ld a, d                     ; 30B2
	adc a, [hl]                 ; 30B3
	ld [hl], a                  ; 30B4
	ret                         ; 30B5

Track_RegAddr:
	push af                     ; 30B6
	ld h, HIGH(wSoundRAM)       ; 30B7
	ld a, LOW(wTrkHwOffset)     ; 30B9
	add a, b                    ; 30BB
	ld l, a                     ; 30BC
	pop af                      ; 30BD
Track_RegAddrA:
	add a, [hl]                 ; 30BE
Track_RegAddrAbs:
	ld hl, hRegImage            ; 30BF
	add a, [hl]                 ; 30C2
	ld l, a                     ; 30C3
	ld h, HIGH(wSoundRAM)       ; 30C4
	ret                         ; 30C6

EnvStackTable:
	db $06, $16, $26, $36, $46, $56, $66, $76
TuningTable:
	dw PeriodTable - 6  ; tuning 0: entry 3 of this table is PeriodTable
NoiseTable:
	db $00, $10, $20, $30, $07, $23, $50, $33, $60, $43, $70, $45, $47, $55, $65
