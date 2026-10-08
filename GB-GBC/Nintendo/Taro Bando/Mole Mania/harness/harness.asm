; Test harness: runs the rebuilt sound banks on an emulator.
; verify.py pokes hBank / the driver's request variables and steps frames.
INCLUDE "../GB_Hardware.inc"
DEF hBank EQU $FF80

SECTION "stat", ROM0[$48]
	reti

SECTION "header", ROM0[$100]
	nop
	jp Start
	ds $150 - @, 0


SECTION "main", ROM0[$0150]
Start:
	di
	ld sp, $DFF0
	ld hl, $C000          ; clear WRAM like the game does
	ld bc, $2000 - $10
.clr
	xor a
	ld [hli], a
	dec bc
	ld a, b
	or c
	jr nz, .clr
	ld a, $07
	ldh [hBank], a
	ld [$2000], a
	call $4000            ; Sound_Init
	ld a, $80
	ldh [rLCDC], a
	ld a, 10              ; update at line 10, so a frame boundary never cuts it
	ldh [$FF45], a        ; LYC
	ld a, $40
	ldh [$FF41], a        ; STAT: LYC interrupt
	ld a, $02
	ldh [rIE], a
	xor a
	ldh [rIF], a
	ei
.loop
	halt
	ldh a, [hBank]
	ld [$2000], a
	call $4002            ; Sound_Update
	ld hl, $FF81          ; update counter, for verify.py
	inc [hl]
	jr .loop
