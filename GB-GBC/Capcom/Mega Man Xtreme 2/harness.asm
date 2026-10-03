; Test harness for the rebuilt Mega Man Xtreme 2 sound banks.
; Python writes: wHarnessBank ($C003) = sound bank, wHarnessID ($C002) = id,
; then wHarnessGo ($C001) = 1. The VBlank handler plays it and runs SndUpdate.
DEF NUM_SOUND_IDS EQU $7D
INCLUDE "MMX_Sound.inc"
DEF SndJT_Update EQU $4000
DEF SndJT_Play   EQU $4003
DEF wHarnessGo   EQU $C001
DEF wHarnessID   EQU $C002
DEF wHarnessBank EQU $C003
DEF wFrames      EQU $C004

SECTION "Harness VBlank", ROM0[$0040]
	jp HarnessVBlank

SECTION "Harness entry", ROM0[$0100]
	nop
	jp HarnessStart
	ds $150 - @, 0

SECTION "Harness code", ROM0[$1000]
HarnessStart:
	di
	ld sp, $DFF0
	xor a
	ld hl, $C000
	ld bc, $0100
.clr:
	ld [hli], a
	dec c
	jr nz, .clr
	ld a, 2
	ld [wHarnessBank], a
	ld [rROMB0], a
	ld a, $F0
	call SndJT_Play            ; stop all (also powers the APU on)
	ld a, $01
	ldh [$FFFF], a               ; IE = VBlank
	ld a, $91
	ldh [$FF40], a               ; LCD on
	ei
.loop:
	halt
	nop
	jr .loop

HarnessVBlank:
	push af
	push bc
	push de
	push hl
	ld a, [wHarnessBank]
	ld [rROMB0], a
	ld a, [wHarnessGo]
	and a
	jr z, .update
	xor a
	ld [wHarnessGo], a
	ld a, [wHarnessID]
	call SndJT_Play
.update:
	call SndJT_Update
	ld hl, wFrames
	inc [hl]
	pop hl
	pop de
	pop bc
	pop af
	reti
