; test harness: bank 0 = this, bank 4 = the rebuilt driver. One SndUpdate per VBlank.
INCLUDE "cosmotank_sound.inc"

SECTION "vblank", ROM0[$0040]
	jp VBlank

SECTION "header", ROM0[$0100]
	nop
	jp Start
	ds $150 - @, 0

SECTION "main", ROM0[$0150]
Start:
	di
	ld sp, $D000
	ld hl, $DF00
	xor a
.clr
	ld [hli], a
	bit 5, h
	jr z, .clr        ; clears $DF00-$DFFF
	ld a, 4
	ld [$2100], a
	call SndInit
	ld a, 1
	ldh [$FFFF], a       ; IE = VBlank
	xor a
	ldh [$FF0F], a
	ei
.loop
	halt
	nop
	jr .loop

VBlank:
	push af
	push bc
	push de
	push hl
	call SndUpdate
	pop hl
	pop de
	pop bc
	pop af
	reti
