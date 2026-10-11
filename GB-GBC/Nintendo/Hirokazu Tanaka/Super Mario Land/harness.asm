; Test ROM: MBC1, bank 3 = the rebuilt sound driver. Calls the update once per frame.
INCLUDE "GB_Hardware.inc"
SECTION "vectors", ROM0[$40]
REPT 5
	reti
	ds 7, 0
ENDR
SECTION "entry", ROM0[$100]
	nop
	jp Start
	ds $150 - @, 0
Start:
	di
	ld sp, $cfff
	ld a, 3
	ld [$2000], a       ; ROM bank 3
	xor a
	ldh [rIE], a
	call $7ff3          ; Sound_StopStub (the game has no separate init)
	ld a, $80
	ldh [rNR52], a
	ld a, $77
	ldh [rNR50], a
.loop:
	ldh a, [rLY]
	cp 144
	jr nz, .loop
	call $7ff0          ; Sound_UpdateStub (ends with reti)
	di
.wait:
	ldh a, [rLY]
	cp 144
	jr z, .wait
	jr .loop
