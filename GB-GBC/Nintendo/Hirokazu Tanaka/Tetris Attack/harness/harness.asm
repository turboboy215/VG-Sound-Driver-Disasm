; Test ROM: MBC1, $1500-$1644 = the rebuilt home sound routine, banks $07/$08 = the rebuilt sound
; banks. The home routine (Sound_Frame) runs once per frame, as in the game. Requests are written by
; the test script into the driver's RAM (wSongRequest $D368, wSfx1Request $D360, wSfx3Request $D370).
INCLUDE "GB_Hardware.inc"
SECTION "entry", ROM0[$100]
	nop
	jp Start
	ds $150 - @, 0
Start:
	di
	ld sp, $cfff
	xor a
	ld hl, $d300
.clear:
	ld [hl+], a
	ld a, h
	cp $d5
	ld a, 0
	jr nz, .clear
	ld a, $80
	ldh [rNR52], a
	ld a, $77
	ldh [rNR50], a
	ld a, $ff
	ldh [rNR51], a
	ld a, $ff
	ld [$d3e3], a       ; no SFX priority
	ld a, 1
	ldh [$fffd], a
	ld [$2100], a
.loop:
	ldh a, [rLY]
	cp 144
	jr nz, .loop
	call $1500
.wait:
	ldh a, [rLY]
	cp 144
	jr z, .wait
	jr .loop
