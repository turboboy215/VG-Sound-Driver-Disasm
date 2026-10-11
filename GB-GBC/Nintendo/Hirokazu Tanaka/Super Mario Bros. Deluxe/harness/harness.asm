; Test ROM: MBC5, banks $1D / $1F = the rebuilt sound banks. Like the game, it calls
; the updates of bank $1D (music) and $1F (SFX) once per frame. Requests are written by
; the test script into WRAM mailboxes ($C000 song, $C001 / $C002 / $C003 SFX slots) and
; copied into the driver's request bytes just before the updates, so that a request can't
; land between the music update and the SFX update that clears it.
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
	ld a, $1f
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
	ld de, $de70
	call Copy
	ld de, $de78
	call Copy
	ld a, $1d
	ld [$2000], a
	call $4006
	ld a, $1f
	ld [$2000], a
	call $4006
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
