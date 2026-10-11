; Test ROM: MBC1+RAM, bank 4 = the rebuilt sound driver. Calls the update once per frame.
; Requests are passed through WRAM ($C000 song, $C001 ch1 SFX, $C002 ch3 SFX, $C003 ch4 SFX)
; and copied into the driver's variables in cartridge RAM by this code.
INCLUDE "GB_Hardware.inc"
SECTION "entry", ROM0[$100]
	nop
	jp Start
	ds $150 - @, 0
Start:
	di
	ld sp, $cfff
	xor a
	ld hl, $c000
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld a, $0a
	ld [$0000], a       ; enable cartridge RAM (the driver's variables are at $A400)
	ld a, 4
	ld [$2100], a       ; ROM bank 4
	call $4000          ; Sound_Init
.loop:
	ldh a, [rLY]
	cp 144
	jr nz, .loop
	ld hl, $c000
	ld de, $a468        ; wSongRequest
	call Copy
	ld de, $a460        ; wSfx1Request
	call Copy
	ld de, $a470        ; wSfx3Request
	call Copy
	ld de, $a478        ; wSfx4Request
	call Copy
	call $4030          ; Sound_Update
.wait:
	ldh a, [rLY]
	cp 144
	jr z, .wait
	jr .loop
Copy:
	ld a, [hl]
	and a
	jr z, .none
	ld [de], a
	xor a
	ld [hl], a
.none:
	inc hl
	ret
