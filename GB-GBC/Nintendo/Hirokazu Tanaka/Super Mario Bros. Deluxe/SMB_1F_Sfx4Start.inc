; Super Mario Bros. Deluxe SFX: slot 4 dispatch, start / stop, bank $1F $4737-$4859

; Effects $3E-$48; while a priority effect plays only $45 gets through.
Sfx4_Update:
	ld hl, wSfx4Request
	ld a, [hl]
	and a
	jr z, Sfx4_Update_playing
	cp $3e
	jp c, Sfx4_Refuse
	cp $49
	jp nc, Sfx4_Refuse
	ld a, [wSfx4Priority]
	and a
	jp z, .start
	ld a, [hl]
	cp $45
	jp nz, Sfx4_Refuse
.start:
	ld a, [hl]
	ld hl, Sfx4_InitTable
	jr Sfx4_Update_dispatch

Sfx4_Dummy_Play:
	jp Sfx4_Stop

Sfx4_Dummy_Init:
	ld hl, wSfx4Request
Sfx4_Update_playing:
	inc hl
	ld a, [hl]
	and a
	ret z
	ld hl, Sfx4_PlayTable
Sfx4_Update_dispatch:
	call GetPointer
	ld de, wSfx4Timer
	ld bc, wSfx4Step
	jp hl

; unreferenced
Sfx4_StartPriority_Unused:
	ld a, $01
	ld [wSfx4Priority], a
Sfx4_Start:
	ld a, [wSfx4Request]
	ld [wSfx4Playing], a
	xor a
	ld [wSfx4Timer], a
	ld [wSfx4Step], a
	ld a, [wCh4Flags]
	set 7, a
	ld [wCh4Flags], a
	jp SetRegs_Ch4

Sfx4_StopWithRegs:
	ld hl, Sfx4_StopRegs
	call SetRegs_Ch4
Sfx4_Stop:
	xor a
	ld [wSfx4Playing], a
	ld [wSfx4Timer], a
	ld [wSfx4Step], a
	ld [wSfx4Counter], a
	ld [wSfx4Priority], a
	ld a, [wCh4Flags]
	res 7, a
	ld [wCh4Flags], a
	ret

Sfx4_StopRegs:
	db $00, $08, $00, $80, $01
Sfx4_WritePeriod_Unused:
	ld b, $02
	ld c, $22
	ld de, wSfx4Timer
	jp SetRegs_Copy

Sfx4_Refuse:
	xor a
	ld [wSfx4Request], a
	jp Sfx4_Update

Sfx2_StartPriority2:
	ld a, $02
	jr Sfx2_StartPriority.store

Sfx2_StartPriority3:
	ld a, $03
	jr Sfx2_StartPriority.store

Sfx2_StartPriority4:
	ld a, $04
	jr Sfx2_StartPriority.store

Sfx2_StartPriority:
	ld a, $01
.store:
	ld [wSfx2Priority], a
; Start a ch2 effect: hl = NR21-NR24 + frames. Takes ch2 from the music.
Sfx2_Start:
	ld a, [wSfx2Request]
	ld [wSfx2Playing], a
	ld a, [wCh2Flags]
	set 7, a
	ld [wCh2Flags], a
	xor a
	ld [wSfx2Timer], a
	ld [wSfx2Step], a
	ld a, [wChannelsPlayed]
	res 1, a
	ld [wChannelsPlayed], a
	jp SetRegs_Ch2

Sfx2_StopWithRegs:
	ld hl, Sfx2_StopRegs
	call SetRegs_Ch2
Sfx2_Stop:
	xor a
	ld [wSfx2Timer], a
	ld [wSfx2Step], a
	ld [wSfx2Playing], a
	ld [wSfx2Priority], a
	ld hl, wCh2Flags
	res 7, [hl]
	ret

Sfx2_StopRegs:
	db $3f, $08, $00, $c1, $01
Sfx4Wave_StartPriority:
	ld a, $01
	ld [wSfx4Priority], a
; Start a slot-4 effect on ch3: hl = NR30-NR34 + frames.
Sfx4Wave_Start:
	call Sfx4Wave_Take
	jp SetRegs_Ch3

Sfx4Wave_Take:
	ld a, [wSfx4Request]
	ld [wSfx4Playing], a
	xor a
	ld [wSfx4Timer], a
	ld [wSfx4Step], a
	push hl
	ld hl, wCh3Flags
	set 7, [hl]
	pop hl
	ret

Sfx4Wave_StopRegs:
	db $00, $00, $00, $00, $00, $01
; End a slot-4 ch3 effect and tell the music to reload its wave.
Sfx4Wave_Stop:
	ld hl, Sfx4Wave_StopRegs
	call SetRegs_Ch3
	xor a
	ld [wSfx4Playing], a
	ld [wSfx4Timer], a
	ld [wSfx4Step], a
	ld [wSfx4Counter], a
	ld [wSfx4Priority], a
	ld hl, wCh3Flags
	res 7, [hl]
	ld a, $01
	ld [wReloadWave], a
	ret

