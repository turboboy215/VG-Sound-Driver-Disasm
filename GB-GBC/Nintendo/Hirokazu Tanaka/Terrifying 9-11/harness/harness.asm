; Test ROM: MBC5, banks $28 / $29 = the rebuilt sound banks. Like the game, it calls the
; updates of bank $28 (music, $4001) and $29 (SFX, $4001) once per frame. Requests are written
; by the test script into WRAM mailboxes ($C000 song, $C001 / $C002 / $C003 SFX) and copied
; into the driver's request bytes ($C868, $C860, $C870, $C878) before the updates.
INCLUDE "GB_Hardware.inc"
SECTION "entry", ROM0[$100]
	nop
	jp Start
	ds $150 - @, 0
Start:
	di
	ld sp, $dfff
	xor a
	ld hl, $c000
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld a, $28
	ld [$2000], a
	call $4004          ; init (clears $C800-$C8FF)
.loop:
	ldh a, [rLY]
	cp 144
	jr nz, .loop
	ld hl, $c000
	ld de, $c868
	call Copy
	ld de, $c860
	call Copy
	ld de, $c870
	call Copy
	ld de, $c878
	call Copy
	ld a, $28
	ld [$2000], a
	call $4001
	ld a, $29
	ld [$2000], a
	call $4001
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
