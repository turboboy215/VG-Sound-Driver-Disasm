; Super Mario Bros. Deluxe SFX: slot 1 dispatch, bank $1F $43A2-$448B

; Requests $80 and above: Sfx1_Note. Effects $42-$78; the others are dropped. While a
; priority effect plays only some effects get through: priority 1 lets $4D, $4E and
; $53-$5E (except $57) through; priority 2 lets $4D, $4E, $56 and $5B-$5E through.
Sfx1_Update:
	ld hl, wSfx1Request
	ld a, [hl]
	and a
	jr z, .playing
	cp $80
	jp nc, Sfx1_Note
	cp $42
	jp c, Sfx1_Refuse
	cp $79
	jp nc, Sfx1_Refuse
	ld a, [wSfx1Priority]
	and a
	jr z, .start
	cp $01
	jr z, .priority1
	ld a, [hl]
	cp $4d
	jr z, .start
	cp $4e
	jr z, .start
	cp $56
	jr z, .start
	cp $5b
	jp c, Sfx1_Refuse
	cp $5f
	jp nc, Sfx1_Refuse
	jr .start

.priority1:
	ld a, [hl]
	cp $4d
	jr z, .start
	cp $4e
	jr z, .start
	cp $53
	jp c, Sfx1_Refuse
	cp $5f
	jp nc, Sfx1_Refuse
	cp $57
	jp z, Sfx1_Refuse
.start:
	ld a, [hl]
	ld hl, Sfx1_InitTable
	jr .dispatch

.playing:
	inc hl
	ld a, [hl]
	and a
	ret z
	ld hl, Sfx1_PlayTable
.dispatch:
	call GetPointer
	ld de, wSfx1Timer
	ld bc, wSfx1Step
	jp hl

Sfx1_StartPriority2:
	ld a, $02
	jr Sfx1_StartPriority.store

; unreferenced
Sfx1_StartVar_Unused:
	ld a, $01
	ld [wSfx1Var], a
Sfx1_StartPriority:
	ld a, $01
.store:
	ld [wSfx1Priority], a
; Start a ch1 effect: hl = NR10-NR14 + frames. Takes ch1 from the music.
Sfx1_Start:
	ld a, [wSfx1Request]
	ld [wSfx1Playing], a
	xor a
	ld [wSfx1Timer], a
	ld [wSfx1Step], a
	ld [wSfx1Var5], a
	ld a, [wCh1Flags]
	set 7, a
	ld [wCh1Flags], a
	ld a, [wChannelsPlayed]
	res 0, a
	ld [wChannelsPlayed], a
	jp SetRegs_Ch1

Sfx1_StopSilent:
	ld a, $11
	ldh [rNR12], a
	ld a, $80
	ldh [rNR14], a
	jr Sfx1_Stop

Sfx1_StopWithRegs:
	ld hl, Sfx1_StopRegs
	call SetRegs_Ch1
Sfx1_Stop:
	xor a
	ld [wSfx1Playing], a
	ld [wSfx1Timer], a
	ld [wSfx1Step], a
	ld [wSfx1Counter], a
	ld [wSfx1Var], a
	ld [wSfx1Priority], a
	ld a, $08
	ldh [rNR10], a
	ld a, [wCh1Flags]
	res 7, a
	ld [wCh1Flags], a
	ret

Sfx1_StopRegs:
	db $08, $3f, $08, $00, $c1, $01
Sfx1_WritePeriod:
	ld b, $02
	ld c, $13
	ld de, wSfx1Timer
	jp SetRegs_Copy

Sfx2_WritePeriod:
	ld b, $02
	ld c, $18
	ld de, wSfx2Timer
	jp SetRegs_Copy

Sfx1_Refuse:
	xor a
	ld [wSfx1Request], a
	jp Sfx1_Update

