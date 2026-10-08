; Test harness: runs the rebuilt sound bank 3 (and the voice code in bank 5).
; The home-bank routines the driver calls (far call/return, bank switch,
; rumble, distance) are copied from the original ROM at their own addresses.
; verify.py writes a command to hCmd; the harness runs it at the next update.
INCLUDE "../GB_Hardware.inc"
DEF hCmd     EQU $FF80   ; 1 Music_Request, 2 Sfx_Request, 3 Music_FadeOut, 4 Sound_Init
DEF hCounter EQU $FF81
DEF ROM EQUS "\"rom.gbc\""

SECTION "rst20", ROM0[$20]
	INCBIN ROM, $20, 16          ; rst $20 far call, rst $28 far return
SECTION "stat", ROM0[$48]
	jp Update
SECTION "home1", ROM0[$0696]
	INCBIN ROM, $0696, $076A - $0696   ; rumble on/off, bank switching, far call/return
SECTION "home2", ROM0[$232C]
	INCBIN ROM, $232C, $2367 - $232C   ; approximate distance

SECTION "header", ROM0[$100]
	nop
	jp Start
	ds $150 - @, 0

SECTION "main", ROM0[$0150]
Start:
	di
	ld sp, $DFF0
	ld hl, $C000
	ld bc, $2000 - $10
.clr
	xor a
	ld [hli], a
	dec bc
	ld a, b
	or c
	jr nz, .clr
	ld a, 1
	ld [$C207], a               ; current ROM bank, as the game keeps it
	rst $20
	dw $4000                    ; Sound_Init
	db $03
	ld a, $80
	ldh [rLCDC], a
	ld a, 10
	ldh [$FF45], a
	ld a, $40
	ldh [$FF41], a
	ld a, $02
	ldh [rIE], a
	xor a
	ldh [rIF], a
	ei
.loop
	halt
	jr .loop

Update:
	ldh a, [hCmd]
	and a
	jr z, .frame
	cp 1
	jr nz, .n1
	rst $20
	dw $55BF                    ; Music_Request
	db $03
	jr .done
.n1	cp 2
	jr nz, .n2
	rst $20
	dw $55D5                    ; Sfx_Request
	db $03
	jr .done
.n2	cp 3
	jr nz, .n3
	rst $20
	dw $55CF                    ; Music_FadeOut
	db $03
	jr .done
.n3	rst $20
	dw $4000                    ; Sound_Init
	db $03
.done
	xor a
	ldh [hCmd], a
.frame
	rst $20
	dw $420A                    ; Sound_Update
	db $03
	ld hl, hCounter
	inc [hl]
	reti
