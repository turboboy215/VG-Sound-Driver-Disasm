; Sanrio Carnival 2 sound, bank $01: driver code, $6000-$69EE

; Entry points: init (called from home $018D), update once per frame (home $00D3).
Sound_Init:
	jp Sound_Reset

; Per frame: SFX, then the music unless an effect holds it (wMusicHold), a pending wave load
; (wWavePtr high byte <> 0), then the shadow registers are written out. Each channel has a
; dirty byte: bit 7 = write all registers and trigger, other bits = frequency only.
; wShadowMaster bit 0 = write NR50, bit 1 = NR51 = wMusicNR51 | wSfxNR51.
Sound_Update:
	call Sfx_Update
	ld a, [wMusicHold]
	or a
	call z, Music_Update
	ld e, $00
	ld hl, wWavePtr+1
	ld a, [hl]
	or a
	jr z, .l1
	ld [hl], e
	dec hl
	ld l, [hl]
	ld h, a
	xor a
	ldh [rNR30], a
	ld bc, $1030
.l0:
	ld a, [hl+]
	ldh [c], a
	inc c
	dec b
	jr nz, .l0
.l1:
	ld hl, wShadowCh1
	ld a, [hl]
	ld [hl], e
	inc hl
	add a, a
	jr c, .l2
	inc hl
	inc hl
	inc hl
	jr nz, .l3
	inc hl
	inc hl
	jr .l5

.l2:
	ld a, [hl+]
	ldh [rNR10], a
	ld a, [hl+]
	ldh [rNR11], a
	ld a, [hl+]
	ldh [rNR12], a
.l3:
	ld a, [hl+]
	ldh [rNR13], a
	ld a, [hl+]
	jr nc, .l4
	or $80
.l4:
	ldh [rNR14], a
.l5:
	ld a, [hl]
	ld [hl], e
	inc hl
	inc hl
	add a, a
	jr c, .l6
	inc hl
	inc hl
	jr nz, .l7
	inc hl
	inc hl
	jr .l9

.l6:
	ld a, [hl+]
	ldh [rNR21], a
	ld a, [hl+]
	ldh [rNR22], a
.l7:
	ld a, [hl+]
	ldh [rNR23], a
	ld a, [hl+]
	jr nc, .l8
	or $80
.l8:
	ldh [rNR24], a
.l9:
	ld a, [hl]
	ld [hl], e
	inc hl
	add a, a
	jr c, .l10
	inc hl
	inc hl
	inc hl
	jr nz, .l11
	inc hl
	inc hl
	jr .l13

.l10:
	ld a, [hl+]
	ldh [rNR30], a
	ld a, [hl+]
	ldh [rNR31], a
	ld a, [hl+]
	ldh [rNR32], a
.l11:
	ld a, [hl+]
	ldh [rNR33], a
	ld a, [hl+]
	jr nc, .l12
	or $80
.l12:
	ldh [rNR34], a
.l13:
	ld a, [hl]
	ld [hl], e
	inc hl
	inc hl
	add a, a
	jr c, .l14
	inc hl
	inc hl
	jr nz, .l15
	inc hl
	inc hl
	jr .l17

.l14:
	ld a, [hl+]
	ldh [rNR41], a
	ld a, [hl+]
	ldh [rNR42], a
.l15:
	ld a, [hl+]
	ldh [rNR43], a
	ld a, [hl+]
	jr nc, .l16
	or $80
.l16:
	ldh [rNR44], a
.l17:
	xor a
	ld c, [hl]
	ld [hl+], a
	ld a, [hl+]
	rr c
	jr nc, .l18
	ldh [rNR50], a
.l18:
	rr c
	jr nc, .l19
	ld a, [hl+]
	or [hl]
	ldh [rNR51], a
.l19:
	ret

; Clear $DE00-$DE81, silence the APU, then NR50 = $77 and music NR51 = $FF (written next frame).
Sound_Reset:
	ld hl, wSongRequest
	ld bc, $0082
.l0:
	xor a
	ld [hl+], a
	dec bc
	ld a, c
	or b
	jr nz, .l0
	ldh [rNR50], a
	ldh [rNR51], a
	ldh [rNR30], a
	ld a, $08
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR42], a
	swap a
	ldh [rNR14], a
	ldh [rNR24], a
	ldh [rNR44], a
	ldh [rNR52], a
	ld hl, wShadowMaster
	ld [hl], $03
	inc l
	ld [hl], $77
	inc l
	ld [hl], $ff
	ret

; Four SFX slots, highest priority first. wSfxRequestN is a bit mask of effects (bit 7 = effect 0,
; the most important); requests collect in wSfxPendingN and the highest pending bit plays: a new
; request for it starts it, otherwise the running effect continues. An effect's end clears every
; pending bit of its slot. A slot only writes channels a higher slot has not taken this frame.
Sfx_Update:
	xor a
	ld [wSfxSlotChannels], a
	ld [wSfxChannels], a
	ld bc, $ff00
	ld hl, wSfxRequest1
	ld e, [hl]
	ld [hl], c
	ld a, [wSfxPending1]
	or e
	ld [wSfxPending1], a
	jr z, .l1
	scf
.l0:
	inc b
	rr c
	rla
	jr nc, .l0
	call Sfx_Slot1
	ld hl, wSfxSlotChannels
	ld a, [hl+]
	or [hl]
	ld [hl], a
.l1:
	ld bc, $ff00
	ld hl, wSfxRequest2
	ld e, [hl]
	ld [hl], c
	ld a, [wSfxPending2]
	or e
	ld [wSfxPending2], a
	jr z, .l3
	scf
.l2:
	inc b
	rr c
	rla
	jr nc, .l2
	call Sfx_Slot2
	ld hl, wSfxSlotChannels
	ld a, [hl+]
	or [hl]
	ld [hl], a
.l3:
	ld bc, $ff00
	ld hl, wSfxRequest3
	ld e, [hl]
	ld [hl], c
	ld a, [wSfxPending3]
	or e
	ld [wSfxPending3], a
	jr z, .l5
	scf
.l4:
	inc b
	rr c
	rla
	jr nc, .l4
	call Sfx_Slot3
	ld hl, wSfxSlotChannels
	ld a, [hl+]
	or [hl]
	ld [hl], a
.l5:
	ld bc, $ff00
	ld hl, wSfxRequest4
	ld e, [hl]
	ld [hl], c
	ld a, [wSfxPending4]
	or e
	ld [wSfxPending4], a
	jr z, .l7
	scf
.l6:
	inc b
	rr c
	rla
	jr nc, .l6
	call Sfx_Slot4
	ld hl, wSfxSlotChannels
	ld a, [hl+]
	or [hl]
	ld [hl], a
; wSfxChannels = channels taken by an effect: refresh NR51 when it changed, set the per-channel flags.
.l7:
	ld a, [wSfxNR51]
	ld b, a
	ld a, [wSfxChannels]
	ld c, a
	swap a
	or c
	cp b
	jr z, .l8
	ld [wSfxNR51], a
	ld a, $02
	ld [wShadowMaster], a
.l8:
	ld b, $01
	ld a, c
	and b
	ld [wCh1SfxOwned], a
	ld a, c
	rra
	ld c, a
	and b
	ld [wCh2SfxOwned], a
	ld a, c
	rra
	ld c, a
	and b
	ld [wCh3SfxOwned], a
	ld a, c
	rra
	and b
	ld [wCh4SfxOwned], a
	ret

; Slot 1. Stream bytes: $00-$3F register writes (Sfx_RegsChN), $40-$5F hold / resume the music,
; $60-$6F end, $70-$7F new channel set, $80-$FF wait n frames ($80 = 128).
Sfx_Slot1:
	ld a, c
	and e
	jr z, .l0
	ld a, b
	add a, a
	ld e, a
	ld d, $00
	ld hl, SfxTable1
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld hl, wSfxSlot1Channels
	ld a, [de]
	inc de
	ld [hl+], a
	ld [wSfxSlotChannels], a
	ld [hl], $00
	jr .l1

.l0:
	ld hl, wSfxSlot1Ptr
	ld a, [hl+]
	ld e, a
	ld a, [hl+]
	ld d, a
	ld a, [hl+]
	ld [wSfxSlotChannels], a
	ld a, [hl]
	or a
	jr z, .l1
	dec [hl]
	ret

.l1:
	ld a, [de]
	inc de
	cp $40
	jr nc, .l5
	ld c, a
	swap a
	and $03
	jr nz, .l2
	call Sfx_RegsCh1
	jr .l1

.l2:
	dec a
	jr nz, .l3
	call Sfx_RegsCh2
	jr .l1

.l3:
	dec a
	jr nz, .l4
	call Sfx_RegsCh3
	jr .l1

.l4:
	call Sfx_RegsCh4
	jr .l1

.l5:
	cp $80
	jr nc, .l8
	cp $70
	jr nc, .l6
	cp $60
	jr nc, .l7
	and $01
	ld [wMusicHold], a
	jr .l1

.l6:
	and $0f
	ld [wSfxSlot1Channels], a
	ld [wSfxSlotChannels], a
	jr .l1

.l7:
	call Sfx_Silence
	xor a
	ld [wSfxPending1], a
	ret

.l8:
	ld hl, wSfxSlot1Ptr
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	inc l
	dec a
	and $7f
	ld [hl], a
	ret

Sfx_Slot2:
	ld a, c
	and e
	jr z, .l0
	ld a, b
	add a, a
	ld e, a
	ld d, $00
	ld hl, SfxTable2
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld hl, wSfxSlot2Channels
	ld a, [de]
	inc de
	ld [hl+], a
	ld [wSfxSlotChannels], a
	ld [hl], $00
	jr .l1

.l0:
	ld hl, wSfxSlot2Ptr
	ld a, [hl+]
	ld e, a
	ld a, [hl+]
	ld d, a
	ld a, [hl+]
	ld [wSfxSlotChannels], a
	ld a, [hl]
	or a
	jr z, .l1
	dec [hl]
	ret

.l1:
	ld a, [de]
	inc de
	cp $40
	jr nc, .l5
	ld c, a
	swap a
	and $03
	jr nz, .l2
	call Sfx_RegsCh1
	jr .l1

.l2:
	dec a
	jr nz, .l3
	call Sfx_RegsCh2
	jr .l1

.l3:
	dec a
	jr nz, .l4
	call Sfx_RegsCh3
	jr .l1

.l4:
	call Sfx_RegsCh4
	jr .l1

.l5:
	cp $80
	jr nc, .l8
	cp $70
	jr nc, .l6
	cp $60
	jr nc, .l7
	and $01
	ld [wMusicHold], a
	jr .l1

.l6:
	and $0f
	ld [wSfxSlot2Channels], a
	ld [wSfxSlotChannels], a
	jr .l1

.l7:
	call Sfx_Silence
	xor a
	ld [wSfxPending2], a
	ret

.l8:
	ld hl, wSfxSlot2Ptr
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	inc l
	dec a
	and $7f
	ld [hl], a
	ret

Sfx_Slot3:
	ld a, c
	and e
	jr z, .l0
	ld a, b
	add a, a
	ld e, a
	ld d, $00
	ld hl, SfxTable3
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld hl, wSfxSlot3Channels
	ld a, [de]
	inc de
	ld [hl+], a
	ld [wSfxSlotChannels], a
	ld [hl], $00
	jr .l1

.l0:
	ld hl, wSfxSlot3Ptr
	ld a, [hl+]
	ld e, a
	ld a, [hl+]
	ld d, a
	ld a, [hl+]
	ld [wSfxSlotChannels], a
	ld a, [hl]
	or a
	jr z, .l1
	dec [hl]
	ret

.l1:
	ld a, [de]
	inc de
	cp $40
	jr nc, .l5
	ld c, a
	swap a
	and $03
	jr nz, .l2
	call Sfx_RegsCh1
	jr .l1

.l2:
	dec a
	jr nz, .l3
	call Sfx_RegsCh2
	jr .l1

.l3:
	dec a
	jr nz, .l4
	call Sfx_RegsCh3
	jr .l1

.l4:
	call Sfx_RegsCh4
	jr .l1

.l5:
	cp $80
	jr nc, .l8
	cp $70
	jr nc, .l6
	cp $60
	jr nc, .l7
	and $01
	ld [wMusicHold], a
	jr .l1

.l6:
	and $0f
	ld [wSfxSlot3Channels], a
	ld [wSfxSlotChannels], a
	jr .l1

.l7:
	call Sfx_Silence
	xor a
	ld [wSfxPending3], a
	ret

.l8:
	ld hl, wSfxSlot3Ptr
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	inc l
	dec a
	and $7f
	ld [hl], a
	ret

Sfx_Slot4:
	ld a, c
	and e
	jr z, .l0
	ld a, b
	add a, a
	ld e, a
	ld d, $00
	ld hl, SfxTable4
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld hl, wSfxSlot4Channels
	ld a, [de]
	inc de
	ld [hl+], a
	ld [wSfxSlotChannels], a
	ld [hl], $00
	jr .l1

.l0:
	ld hl, wSfxSlot4Ptr
	ld a, [hl+]
	ld e, a
	ld a, [hl+]
	ld d, a
	ld a, [hl+]
	ld [wSfxSlotChannels], a
	ld a, [hl]
	or a
	jr z, .l1
	dec [hl]
	ret

.l1:
	ld a, [de]
	inc de
	cp $40
	jr nc, .l5
	ld c, a
	swap a
	and $03
	jr nz, .l2
	call Sfx_RegsCh1
	jr .l1

.l2:
	dec a
	jr nz, .l3
	call Sfx_RegsCh2
	jr .l1

.l3:
	dec a
	jr nz, .l4
	call Sfx_RegsCh3
	jr .l1

.l4:
	call Sfx_RegsCh4
	jr .l1

.l5:
	cp $80
	jr nc, .l8
	cp $70
	jr nc, .l6
	cp $60
	jr nc, .l7
	and $01
	ld [wMusicHold], a
	jr .l1

.l6:
	and $0f
	ld [wSfxSlot4Channels], a
	ld [wSfxSlotChannels], a
	jr .l1

.l7:
	call Sfx_Silence
	xor a
	ld [wSfxPending4], a
	ret

.l8:
	ld hl, wSfxSlot4Ptr
	ld [hl], e
	inc l
	ld [hl], d
	inc l
	inc l
	dec a
	and $7f
	ld [hl], a
	ret

; End of an effect: silence the channels in a (bits 0-3) that no higher slot owns.
Sfx_Silence:
	ld c, a
	ld a, [wSfxChannels]
	cpl
	and c
	ld c, a
	rr c
	jr nc, .l0
	ld a, $08
	ld [wShadowNR12], a
	swap a
	ld [wShadowNR14], a
	ld [wShadowCh1], a
.l0:
	rr c
	jr nc, .l1
	ld a, $08
	ld [wShadowNR22], a
	swap a
	ld [wShadowNR24], a
	ld [wShadowCh2], a
.l1:
	rr c
	jr nc, .l2
	xor a
	ld [wShadowNR30], a
	ld a, $80
	ld [wShadowCh3], a
.l2:
	rr c
	jr nc, .l3
	ld a, $08
	ld [wShadowNR42], a
	swap a
	ld [wShadowNR44], a
	ld [wShadowCh4], a
.l3:
	ret

; Register writes for one channel: c bits 0-2 = NRx0-NRx2, bit 3 = NRx3 and NRx4. Skipped (with
; their operands) when a higher slot owns the channel.
Sfx_RegsCh1:
	ld a, [wSfxChannels]
	bit 0, a
	jr nz, Sfx_SkipRegs
	ld hl, wShadowCh1
	jr Sfx_WriteRegs

Sfx_RegsCh2:
	ld a, [wSfxChannels]
	bit 1, a
	jr nz, Sfx_SkipRegs
	ld hl, wShadowCh2
	jr Sfx_WriteRegs

Sfx_RegsCh3:
	ld a, [wSfxChannels]
	bit 2, a
	jr nz, Sfx_SkipRegs
	ld hl, wShadowCh3
	jr Sfx_WriteRegs

Sfx_RegsCh4:
	ld a, [wSfxChannels]
	bit 3, a
	jr nz, Sfx_SkipRegs
	ld hl, wShadowCh4
Sfx_WriteRegs:
	ld a, c
	and $07
	jr z, .l0
	ld a, $80
.l0:
	inc a
	ld [hl+], a
	rr c
	jr nc, .l1
	ld a, [de]
	inc de
	ld [hl], a
.l1:
	inc l
	rr c
	jr nc, .l2
	ld a, [de]
	inc de
	ld [hl], a
.l2:
	inc l
	rr c
	jr nc, .l3
	ld a, [de]
	inc de
	ld [hl], a
.l3:
	inc l
	rr c
	jr nc, .l4
	ld a, [de]
	inc de
	ld [hl+], a
	ld a, [de]
	inc de
	ld [hl], a
.l4:
	ret

Sfx_SkipRegs:
	rr c
	jr nc, .l0
	inc de
.l0:
	rr c
	jr nc, .l1
	inc de
.l1:
	rr c
	jr nc, .l2
	inc de
.l2:
	rr c
	jr nc, .l3
	inc de
	inc de
.l3:
	ret

; wSongRequest bit 7 clear = a new song: load the four stream pointers (8 bytes per song at
; SongTable; a $00xx pointer = channel unused and silenced), clear the call stacks.
Music_Update:
	ld hl, wSongRequest
	ld a, [hl]
	add a, a
	jr c, .play
	set 7, [hl]
	add a, a
	add a, a
	add a, LOW(SongTable)
	ld e, a
	ld a, HIGH(SongTable)
	adc a, $00
	ld d, a
	ld hl, wMusicCh1Ptr
	ld bc, $0400
.l0:
	ld a, [de]
	inc de
	ld [hl+], a
	ld a, [de]
	inc de
	ld [hl+], a
	sub $01
	rl c
	xor a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	inc a
	ld [hl+], a
	dec b
	jr nz, .l0
	swap c
	rl c
	call c, Cmd_End1
	rl c
	call c, Cmd_End2
	rl c
	call c, Cmd_End3
	rl c
	call c, Cmd_End4
	xor a
	ld [wCh1Depth], a
	ld [wCh2Depth], a
	ld [wCh3Depth], a
	ld [wCh4Depth], a
.play:
	ld hl, wMusicCh1Ptr
	ld e, [hl]
	inc hl
	ld a, [hl+]
	or a
	call nz, Music_Ch1
	ld hl, wMusicCh2Ptr
	ld e, [hl]
	inc hl
	ld a, [hl+]
	or a
	call nz, Music_Ch2
	ld hl, wMusicCh3Ptr
	ld e, [hl]
	inc hl
	ld a, [hl+]
	or a
	call nz, Music_Ch3
	ld hl, wMusicCh4Ptr
	ld e, [hl]
	inc hl
	ld a, [hl+]
	or a
	call nz, Music_Ch4
	ret

; Channel players (one copy per channel). A note byte < $80: pitch*2 -> wMusicChNNote; when the
; repeat counter runs out, a packed length byte follows: high nibble = index into the length
; table, low nibble+1 = how many notes use that length. A note restarts the envelope and pitch
; macros (rest: volume 0). Each frame the envelope macro may give a new NRx2 (retrigger) and the
; pitch macro an offset; commands $80-$9F go through Music_Command (carry = channel done for
; this frame).
Music_Ch1:
	ld d, a
	ld a, [hl]
	or a
	jr nz, .l4
.l0:
	ld a, [de]
	inc de
	add a, a
	jr nc, .l1
	call Music_Command
	jr nc, .l0
	ret

.l1:
	ld hl, wMusicCh1Note
	ld [hl+], a
	ld a, [hl+]
	dec [hl]
	jr nz, .l2
	ld a, [de]
	and $0f
	inc a
	ld [hl-], a
	ld a, [de]
	inc de
	swap a
	and $0f
	ld c, a
	ld a, [wLengthTable]
	add a, c
	ld c, a
	ld a, [wLengthTable+1]
	adc a, $00
	ld b, a
	ld a, [bc]
	ld [hl], a
.l2:
	ld hl, wMusicCh1Ptr
	ld [hl], e
	inc hl
	ld [hl], d
	inc hl
	ld [hl+], a
	ld a, [hl]
	or a
	jr nz, .l3
	ld a, [wCh1SfxOwned]
	or a
	jr nz, .l4
	ld a, $08
	ld [wShadowNR12], a
	ld a, $80
	ld [wShadowNR14], a
	ld [wShadowCh1], a
	jr .l4

.l3:
	ld b, $01
	ld hl, wCh1EnvPtr
	ld a, [wCh1EnvMacro]
	ld [hl+], a
	ld [hl], b
	inc hl
	ld a, [wCh1PitchMacro]
	ld [hl+], a
	ld [hl], b
.l4:
	ld a, [wMusicCh1Note]
	or a
	jr z, .l13
	ld hl, wCh1SfxOwned
	ld a, [hl+]
	or a
	jr z, .l5
	xor a
	ld [wMusicCh1Note], a
	jr .l13

.l5:
	ld c, a
	ld b, a
	ld a, [hl+]
	dec [hl]
	jr nz, .l6
	ld e, a
	ld d, HIGH(EnvMacro_00)
	ld a, [de]
	inc e
	or a
	call z, Macro_Jump
	ld [hl-], a
	ld a, [de]
	ld c, a
	inc e
	ld [hl], e
	inc hl
.l6:
	inc hl
	ld a, [hl+]
	dec [hl]
	jr nz, .l11
	ld e, a
	ld d, HIGH(EnvMacro_00)
	ld a, [de]
	inc e
	or a
	jr nz, .l7
	ld a, [de]
	ld e, a
	ld a, [de]
	inc e
; Pitch: base = NoteFreqTable entry pitch-1. The offset is the macro value's bits 6-0 as a binary
; fraction of the low byte of the next entry (up) or minus the high byte of the base entry (bit 7
; set, down). The only pitch macro waits 510 frames before it moves, so this is never heard.
.l7:
	ld [hl-], a
	ld a, [de]
	inc e
	ld [hl], e
	ld b, a
	ld a, [wMusicCh1Note]
	ld e, a
	ld d, $00
	ld hl, NoteFreqTable
	add hl, de
	ld a, [hl-]
	ld e, [hl]
	dec hl
	ld l, [hl]
	ld h, e
	sla b
	jr nc, .l8
	ld a, d
	sub e
	dec d
.l8:
	ld e, a
	xor a
.l9:
	sra e
	sla b
	jr nc, .l10
	add a, e
.l10:
	jr nz, .l9
	inc b
	add a, l
	ld [wShadowNR13], a
	ld a, d
	adc a, h
	ld [wShadowNR14], a
.l11:
	ld hl, wShadowCh1
	ld a, c
	or a
	jr nz, .l12
	or b
	jr z, .l13
	inc [hl]
	jr .l13

.l12:
	dec [hl]
	inc hl
	ld a, [wCh1Reg0]
	ld [hl+], a
	ld a, [wCh1Reg1]
	ld [hl+], a
	ld [hl], c
.l13:
	ld hl, wMusicCh1Timer
	dec [hl]
	ret

Music_Ch2:
	ld d, a
	ld a, [hl]
	or a
	jr nz, .l4
.l0:
	ld a, [de]
	inc de
	add a, a
	jr nc, .l1
	call Music_Command
	jr nc, .l0
	ret

.l1:
	ld hl, wMusicCh2Note
	ld [hl+], a
	ld a, [hl+]
	dec [hl]
	jr nz, .l2
	ld a, [de]
	and $0f
	inc a
	ld [hl-], a
	ld a, [de]
	inc de
	swap a
	and $0f
	ld c, a
	ld a, [wLengthTable]
	add a, c
	ld c, a
	ld a, [wLengthTable+1]
	adc a, $00
	ld b, a
	ld a, [bc]
	ld [hl], a
.l2:
	ld hl, wMusicCh2Ptr
	ld [hl], e
	inc hl
	ld [hl], d
	inc hl
	ld [hl+], a
	ld a, [hl]
	or a
	jr nz, .l3
	ld a, [wCh2SfxOwned]
	or a
	jr nz, .l4
	ld a, $08
	ld [wShadowNR22], a
	ld a, $80
	ld [wShadowNR24], a
	ld [wShadowCh2], a
	jr .l4

.l3:
	ld b, $01
	ld hl, wCh2EnvPtr
	ld a, [wCh2EnvMacro]
	ld [hl+], a
	ld [hl], b
	inc hl
	ld a, [wCh2PitchMacro]
	ld [hl+], a
	ld [hl], b
.l4:
	ld a, [wMusicCh2Note]
	or a
	jr z, .l13
	ld hl, wCh2SfxOwned
	ld a, [hl+]
	or a
	jr z, .l5
	xor a
	ld [wMusicCh2Note], a
	jr .l13

.l5:
	ld c, a
	ld b, a
	ld a, [hl+]
	dec [hl]
	jr nz, .l6
	ld e, a
	ld d, HIGH(EnvMacro_00)
	ld a, [de]
	inc e
	or a
	call z, Macro_Jump
	ld [hl-], a
	ld a, [de]
	ld c, a
	inc e
	ld [hl], e
	inc hl
.l6:
	inc hl
	ld a, [hl+]
	dec [hl]
	jr nz, .l11
	ld e, a
	ld d, HIGH(EnvMacro_00)
	ld a, [de]
	inc e
	or a
	jr nz, .l7
	ld a, [de]
	ld e, a
	ld a, [de]
	inc e
.l7:
	ld [hl-], a
	ld a, [de]
	inc e
	ld [hl], e
	ld b, a
	ld a, [wMusicCh2Note]
	ld e, a
	ld d, $00
	ld hl, NoteFreqTable
	add hl, de
	ld a, [hl-]
	ld e, [hl]
	dec hl
	ld l, [hl]
	ld h, e
	sla b
	jr nc, .l8
	ld a, d
	sub e
	dec d
.l8:
	ld e, a
	xor a
.l9:
	sra e
	sla b
	jr nc, .l10
	add a, e
.l10:
	jr nz, .l9
	inc b
	add a, l
	ld [wShadowNR23], a
	ld a, d
	adc a, h
	ld [wShadowNR24], a
.l11:
	ld hl, wShadowCh2
	ld a, c
	or a
	jr nz, .l12
	or b
	jr z, .l13
	inc [hl]
	jr .l13

.l12:
	dec [hl]
	inc hl
	inc hl
	ld a, [wCh2Reg1]
	ld [hl+], a
	ld [hl], c
.l13:
	ld hl, wMusicCh2Timer
	dec [hl]
	ret

Music_Ch3:
	ld d, a
	ld a, [hl]
	or a
	jr nz, .l4
.l0:
	ld a, [de]
	inc de
	add a, a
	jr nc, .l1
	call Music_Command
	jr nc, .l0
	ret

.l1:
	ld hl, wMusicCh3Note
	ld [hl+], a
	ld a, [hl+]
	dec [hl]
	jr nz, .l2
	ld a, [de]
	and $0f
	inc a
	ld [hl-], a
	ld a, [de]
	inc de
	swap a
	and $0f
	ld c, a
	ld a, [wLengthTable]
	add a, c
	ld c, a
	ld a, [wLengthTable+1]
	adc a, $00
	ld b, a
	ld a, [bc]
	ld [hl], a
.l2:
	ld hl, wMusicCh3Ptr
	ld [hl], e
	inc hl
	ld [hl], d
	inc hl
	ld [hl+], a
	ld a, [hl]
	or a
	jr nz, .l3
	ld a, [wCh3SfxOwned]
	or a
	jr nz, .l4
	ld a, $80
	ld [wShadowCh3], a
	xor a
	ld [wShadowNR30], a
	jr .l4

.l3:
	ld b, $01
	ld hl, wCh3EnvPtr
	ld a, [wCh3EnvMacro]
	ld [hl+], a
	ld [hl], b
	inc hl
	ld a, [wCh3PitchMacro]
	ld [hl+], a
	ld [hl], b
.l4:
	ld a, [wMusicCh3Note]
	or a
	jr z, .l13
	ld hl, wCh3SfxOwned
	ld a, [hl+]
	or a
	jr z, .l5
	xor a
	ld [wMusicCh3Note], a
	jr .l13

.l5:
	ld c, a
	ld b, a
	ld a, [hl+]
	dec [hl]
	jr nz, .l6
	ld e, a
	ld d, HIGH(EnvMacro_00)
	ld a, [de]
	inc e
	or a
	call z, Macro_Jump
	ld [hl-], a
	ld a, [de]
	ld c, a
	inc e
	ld [hl], e
	inc hl
.l6:
	inc hl
	ld a, [hl+]
	dec [hl]
	jr nz, .l11
	ld e, a
	ld d, HIGH(EnvMacro_00)
	ld a, [de]
	inc e
	or a
	jr nz, .l7
	ld a, [de]
	ld e, a
	ld a, [de]
	inc e
.l7:
	ld [hl-], a
	ld a, [de]
	inc e
	ld [hl], e
	ld b, a
	ld a, [wMusicCh3Note]
	ld e, a
	ld d, $00
	ld hl, NoteFreqTable
	add hl, de
	ld a, [hl-]
	ld e, [hl]
	dec hl
	ld l, [hl]
	ld h, e
	sla b
	jr nc, .l8
	ld a, d
	sub e
	dec d
.l8:
	ld e, a
	xor a
.l9:
	sra e
	sla b
	jr nc, .l10
	add a, e
.l10:
	jr nz, .l9
	inc b
	add a, l
	ld [wShadowNR33], a
	ld a, d
	adc a, h
	ld [wShadowNR34], a
.l11:
	ld hl, wShadowCh3
	ld a, c
	or a
	jr nz, .l12
	or b
	jr z, .l13
	inc [hl]
	jr .l13

.l12:
	dec [hl]
	inc hl
	ld a, $80
	ld [hl+], a
	ld a, [wCh3Reg1]
	ld [hl+], a
	ld [hl], c
.l13:
	ld hl, wMusicCh3Timer
	dec [hl]
	ret

Music_Ch4:
	ld d, a
	ld a, [hl]
	or a
	jr nz, .l4
.l0:
	ld a, [de]
	add a, a
	inc de
	jr nc, .l1
	call Music_Command
	jr nc, .l0
	ret

.l1:
	ld hl, wMusicCh4Note
	ld [hl+], a
	ld a, [hl+]
	dec [hl]
	jr nz, .l2
	ld a, [de]
	and $0f
	inc a
	ld [hl-], a
	ld a, [de]
	inc de
	swap a
	and $0f
	ld c, a
	ld a, [wLengthTable]
	add a, c
	ld c, a
	ld a, [wLengthTable+1]
	adc a, $00
	ld b, a
	ld a, [bc]
	ld [hl], a
.l2:
	ld hl, wMusicCh4Ptr
	ld [hl], e
	inc hl
	ld [hl], d
	inc hl
	ld [hl+], a
	ld a, [hl]
	or a
	jr nz, .l3
	ld a, [wCh4SfxOwned]
	or a
	jr nz, .l4
	ld a, $08
	ld [wShadowNR42], a
	ld a, $80
	ld [wShadowNR44], a
	ld [wShadowCh4], a
	jr .l4

; Drum: DrumTable entry (macro low byte, page) gives the NR43 macro; the envelope macro comes from
; Cmd_Env4. Only drums 1 and 2 have entries: drum 3 (used by songs $06 and $07) reads the first
; bytes of DrumMacro1 as its entry and runs a "macro" at $5E01 in game data (NR43 $F4).
.l3:
	add a, LOW(DrumTable - 2)
	ld l, a
	ld a, HIGH(DrumTable - 2)
	adc a, $00
	ld h, a
	ld c, [hl]
	inc hl
	ld a, [hl]
	ld [wCh4DrumPage], a
	ld b, $01
	ld hl, wCh4EnvPtr
	ld a, [wCh4EnvMacro]
	ld [hl+], a
	ld [hl], b
	inc hl
	ld [hl], c
	inc hl
	ld [hl], b
.l4:
	ld a, [wMusicCh4Note]
	or a
	jr z, .l10
	ld hl, wCh4SfxOwned
	ld a, [hl+]
	or a
	jr z, .l5
	xor a
	ld [wMusicCh4Note], a
	jr .l10

.l5:
	ld c, a
	ld b, a
	ld a, [hl+]
	dec [hl]
	jr nz, .l6
	ld e, a
	ld d, HIGH(EnvMacro_00)
	ld a, [de]
	inc e
	or a
	call z, Macro_Jump
	ld [hl-], a
	ld a, [de]
	ld c, a
	inc e
	ld [hl], e
	inc hl
.l6:
	inc hl
	ld a, [hl+]
	dec [hl]
	jr nz, .l8
	ld e, a
	ld a, [wCh4DrumPage]
	ld d, a
	ld a, [de]
	inc e
	or a
	jr nz, .l7
	ld a, [de]
	ld e, a
	ld a, [de]
	inc e
.l7:
	ld [hl-], a
	ld a, [de]
	ld [wShadowNR43], a
	inc e
	ld [hl], e
	inc b
	xor a
	ld [wShadowNR44], a
.l8:
	ld hl, wShadowCh4
	ld a, c
	or a
	jr nz, .l9
	or b
	jr z, .l10
	inc [hl]
	jr .l10

.l9:
	dec [hl]
	inc hl
	inc hl
	ld a, [wCh4Reg1]
	ld [hl+], a
	ld [hl], c
.l10:
	ld hl, wMusicCh4Timer
	dec [hl]
	ret

; Macro row with frames = 0: jump to the low byte that follows, read the new frames.
Macro_Jump:
	dec hl
	ld a, [de]
	ld [hl+], a
	ld e, a
	ld a, [de]
	inc e
	ret

; a = command*2 (low byte): jump through MusicCommandTable.
Music_Command:
	add a, LOW(MusicCommandTable)
	ld l, a
	ld a, HIGH(MusicCommandTable)
	adc a, $00
	ld h, a
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	jp hl

; commands $80-$9F; $90-$92 have no handler
MusicCommandTable:
	dw Cmd_Wave
	dw Cmd_MasterVolume
	dw Cmd_MusicPan
	dw Cmd_Sweep1
	dw Cmd_Duty1
	dw Cmd_Duty2
	dw Cmd_Length3
	dw Cmd_Length4
	dw Cmd_Env1
	dw Cmd_Env2
	dw Cmd_Env3
	dw Cmd_Env4
	dw Cmd_Pitch1
	dw Cmd_Pitch2
	dw Cmd_Pitch3
	dw Cmd_LengthTable
	dw $0000
	dw $0000
	dw $0000
	dw Cmd_Jump
	dw Cmd_Call1
	dw Cmd_Call2
	dw Cmd_Call3
	dw Cmd_Call4
	dw Cmd_Return1
	dw Cmd_Return2
	dw Cmd_Return3
	dw Cmd_Return4
	dw Cmd_End1
	dw Cmd_End2
	dw Cmd_End3
	dw Cmd_End4
Cmd_Wave:
	ld a, [de]
	inc de
	ld [wWavePtr], a
	ld a, [de]
	inc de
	ld [wWavePtr+1], a
	ret

Cmd_MasterVolume:
	ld a, [de]
	inc de
	ld [wShadowNR50], a
	ld a, [wShadowMaster]
	or $01
	ld [wShadowMaster], a
	ret

Cmd_MusicPan:
	ld a, [de]
	inc de
	ld [wMusicNR51], a
	ld a, [wShadowMaster]
	or $02
	ld [wShadowMaster], a
	ret

Cmd_Sweep1:
	ld a, [de]
	inc de
	ld [wCh1Reg0], a
	ret

Cmd_Duty1:
	ld a, [de]
	inc de
	ld [wCh1Reg1], a
	ret

Cmd_Duty2:
	ld a, [de]
	inc de
	ld [wCh2Reg1], a
	ret

Cmd_Length3:
	ld a, [de]
	inc de
	ld [wCh3Reg1], a
	ret

Cmd_Length4:
	ld a, [de]
	inc de
	ld [wCh4Reg1], a
	ret

Cmd_Env1:
	ld a, [de]
	inc de
	ld [wCh1EnvMacro], a
	ret

Cmd_Env2:
	ld a, [de]
	inc de
	ld [wCh2EnvMacro], a
	ret

Cmd_Env3:
	ld a, [de]
	inc de
	ld [wCh3EnvMacro], a
	ret

Cmd_Env4:
	ld a, [de]
	inc de
	ld [wCh4EnvMacro], a
	ret

Cmd_Pitch1:
	ld a, [de]
	inc de
	ld [wCh1PitchMacro], a
	ret

Cmd_Pitch2:
	ld a, [de]
	inc de
	ld [wCh2PitchMacro], a
	ret

Cmd_Pitch3:
	ld a, [de]
	inc de
	ld [wCh3PitchMacro], a
	ret

Cmd_LengthTable:
	ld a, [de]
	inc de
	ld [wLengthTable], a
	ld a, [de]
	inc de
	ld [wLengthTable+1], a
	ret

Cmd_Jump:
	ld l, e
	ld h, d
	ld a, [hl+]
	ld e, a
	ld d, [hl]
	ret

Cmd_Call1:
	ld hl, wCh1Depth
	jr Cmd_Call

Cmd_Call2:
	ld hl, wCh2Depth
	jr Cmd_Call

Cmd_Call3:
	ld hl, wCh3Depth
	jr Cmd_Call

Cmd_Call4:
	ld hl, wCh4Depth
Cmd_Call:
	ld a, [hl]
	inc [hl]
	inc hl
	add a, a
	ld c, a
	ld b, $00
	add hl, bc
	inc de
	inc de
	ld [hl], e
	inc hl
	ld [hl], d
	dec de
	ld l, e
	ld h, d
	ld d, [hl]
	dec hl
	ld e, [hl]
	or a
	ret

Cmd_Return1:
	ld hl, wCh1Depth
	jr Cmd_Return

Cmd_Return2:
	ld hl, wCh2Depth
	jr Cmd_Return

Cmd_Return3:
	ld hl, wCh3Depth
	jr Cmd_Return

Cmd_Return4:
	ld hl, wCh4Depth
Cmd_Return:
	dec [hl]
	ld a, [hl+]
	add a, a
	ld e, a
	ld d, $00
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
	or a
	ret

; Channel end: silence the channel (unless an effect owns it) and stop it (pointer high byte 0).
Cmd_End1:
	ld a, [wCh1SfxOwned]
	or a
	jr nz, .l0
	ld a, $80
	ld [wShadowCh1], a
	ld [wShadowNR14], a
	swap a
	ld [wShadowNR12], a
.l0:
	xor a
	ld [wMusicCh1Ptr+1], a
	scf
	ret

Cmd_End2:
	ld a, [wCh2SfxOwned]
	or a
	jr nz, .l0
	ld a, $80
	ld [wShadowCh2], a
	ld [wShadowNR24], a
	swap a
	ld [wShadowNR22], a
.l0:
	xor a
	ld [wMusicCh2Ptr+1], a
	scf
	ret

Cmd_End3:
	ld a, [wCh3SfxOwned]
	or a
	jr nz, .l0
	ld a, $80
	ld [wShadowCh3], a
	xor a
	ld [wShadowNR30], a
.l0:
	xor a
	ld [wMusicCh3Ptr+1], a
	scf
	ret

Cmd_End4:
	ld a, [wCh4SfxOwned]
	or a
	jr nz, .l0
	ld a, $80
	ld [wShadowCh4], a
	ld [wShadowNR44], a
	swap a
	ld [wShadowNR42], a
.l0:
	xor a
	ld [wMusicCh4Ptr+1], a
	scf
	ret

