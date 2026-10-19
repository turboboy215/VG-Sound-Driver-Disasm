; Test ROM: MBC5, banks $0E / $0F / $11 / $14 = the rebuilt sound banks. Like the game, it calls
; the init of bank $11 once, then every frame the updates of $0E and $0F (music), $11 and $14
; (SFX). Requests are written by the test script into WRAM mailboxes ($C000 song, $C001-$C004
; slots 1, 2, 3, 4) and copied into the driver's request bytes just before the updates, so that
; a request can't land between two updates. $C005 (not cleared) forces wHurryMode.
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
	ld [hl+], a
	ld a, $11
	ld [$2000], a
	call $4000          ; init (clears $DE00-$DEFF)
.loop:
	ldh a, [rLY]
	cp 144
	jr nz, .loop
	ld hl, $c000
	ld de, $de68       ; wSongRequest
	call Copy
	ld de, $de60       ; wSfx1Request
	call Copy
	ld de, $de70       ; wSfx2Request
	call Copy
	ld de, $de80       ; wSfx3Request
	call Copy
	ld de, $de78       ; wSfx4Request
	call Copy
	ld a, [$c005]      ; non-zero: hurry mode (the game sets wHurryMode itself)
	and a
	jr z, .noHurry
	ld [$ded0], a      ; wHurryMode
.noHurry:
	ld a, $0e
	call Update
	ld a, $0f
	call Update
	ld a, $11
	call Update
	ld a, $14
	call Update
.wait:
	ldh a, [rLY]
	cp 144
	jr z, .wait
	jr .loop
Update:
	ld [$2000], a
	jp $4006
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
