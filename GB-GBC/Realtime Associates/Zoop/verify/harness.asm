; Test harness: runs the driver bank (linked from the generated .asm) one update per frame
; and plays a script of calls written to WRAM by the PyBoy runner.
INCLUDE "rta_sound.inc"

DEF hGo      EQU $C001 ; 1 = start
DEF hBank    EQU $C002 ; driver bank
DEF wPtr     EQU $C004 ; script pointer
DEF wTicks   EQU $C010 ; 16-bit tick count
DEF wScript  EQU $C100 ; entries: tick lo, tick hi, op (0 play, 1 stop, 2 pause+play, 3 init), arg

IF DEF(SROTJ)
DEF SND_RAM EQU $FF8A
ELSE
DEF SND_RAM EQU $DF00
ENDC

SECTION "vblank", ROM0[$40]
	reti

SECTION "header", ROM0[$100]
	nop
	jp Start
	ds $150 - @, 0

SECTION "main", ROM0
Start::
	di
	ld sp, $CFFF
.wait:
	ld a, [hGo]
	cp 1
	jr nz, .wait
	ld a, [hBank]
	ld [$2000], a
	ld hl, SND_RAM
	ld b, 62
	xor a
.clear:
	ld [hli], a
	dec b
	jr nz, .clear
	ld a, $47
	ld [SND_RAM], a
	call $400D
	xor a
	ld [wTicks], a
	ld [wTicks + 1], a
	ld a, LOW(wScript)
	ld [wPtr], a
	ld a, HIGH(wScript)
	ld [wPtr + 1], a
	ld a, 1
	ldh [$FFFF], a
	ei
MainLoop::
	halt
	nop
.cmd:
	ld a, [wPtr]
	ld l, a
	ld a, [wPtr + 1]
	ld h, a
	ld a, [wTicks]
	cp [hl]
	jr nz, TickPoint
	inc hl
	ld a, [wTicks + 1]
	cp [hl]
	jr nz, TickPoint
	inc hl
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld c, a
	ld a, l
	ld [wPtr], a
	ld a, h
	ld [wPtr + 1], a
	ld a, b
	and a
	jr z, .play
	dec a
	jr z, .stop
	dec a
	jr z, .pause
	call $400D
	jr .cmd
.play:
	ld a, c
	call $4004
	jr .cmd
.stop:
	call $4007
	jr .cmd
.pause:
	ld a, c
	call $400A
	jr .cmd
TickPoint::
	call $4001
	ld hl, wTicks
	inc [hl]
	jr nz, MainLoop
	inc hl
	inc [hl]
	jr MainLoop
