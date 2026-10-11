; Test ROM: 32 KB, no MBC. $6480-$7FFF = the rebuilt Tetris sound driver; the update ($7FF0)
; runs once per frame. Requests are written by the test script into the driver's RAM.
INCLUDE "GB_Hardware.inc"
SECTION "entry", ROM0[$100]
	nop
	jp Start
	ds $150 - @, 0
Start:
	di
	ld sp, $cfff
	xor a
	ld hl, $df00
.clear:
	ld [hl+], a
	ld a, h
	cp $e0
	ld a, 0
	jr nz, .clear
	ldh [$ffe4], a
	ld a, $80
	ldh [rNR52], a
	ld a, $77
	ldh [rNR50], a
	ld a, $ff
	ldh [rNR51], a
	call $7ff3          ; stop: clears the state
.loop:
	ldh a, [rLY]
	cp 144
	jr nz, .loop
	call $7ff0
.wait:
	ldh a, [rLY]
	cp 144
	jr z, .wait
	jr .loop
