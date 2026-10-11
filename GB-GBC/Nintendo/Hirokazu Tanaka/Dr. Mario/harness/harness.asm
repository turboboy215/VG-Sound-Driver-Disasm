; Test ROM: bank 1 = the rebuilt sound driver. Calls the update once per frame.
INCLUDE "GB_Hardware.inc"
SECTION "entry", ROM0[$100]
	nop
	jp Start
	ds $150 - @, 0
Start:
	di
	ld sp, $cfff
	call $7ff6          ; Sound_InitStub
.loop:
	ldh a, [rLY]
	cp 144
	jr nz, .loop
	call $7ff0          ; Sound_UpdateStub
.wait:
	ldh a, [rLY]
	cp 144
	jr z, .wait
	jr .loop
