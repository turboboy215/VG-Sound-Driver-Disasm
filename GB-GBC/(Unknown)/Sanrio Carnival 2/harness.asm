; Test ROM: 32 KB, no MBC. Bank 1 = the original game bytes $4000-$5FFF (drum 3 reads there) and the
; rebuilt sound driver $6000-$7FFF. Init once, then the update runs once per frame; the test script
; writes the requests into the driver's RAM (wSongRequest, wSfxRequest1-4).
INCLUDE "GB_Hardware.inc"
SECTION "entry", ROM0[$100]
	nop
	jp Start
	ds $150 - @, 0
Start:
	di
	ld sp, $cfff
	ld a, $80
	ldh [rNR52], a
	call $6000
.loop:
	ldh a, [rLY]
	cp 144
	jr nz, .loop
	call $6003
.wait:
	ldh a, [rLY]
	cp 144
	jr z, .wait
	jr .loop

SECTION "game bank 1", ROMX[$4000], BANK[1]
	INCBIN "orig.gb", $4000, $2000
