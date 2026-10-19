; Test ROM: the rebuilt sound sources + a minimal main loop.
; HRAM requests (set by verify.py): hReqSong / hReqSfx, $FF = none, hReqSong $FE = stop.
INCLUDE "../GB_Hardware.inc"

DEF hReqSong EQU $FF80
DEF hReqSfx  EQU $FF81

SECTION "Header", ROM0[$100]
	nop
	jp Start
	ds $150 - @, 0

SECTION "Main", ROM0[$150]
Start:
	di
	ld sp, $CFFF
	ld a, $FF
	ldh [hReqSong], a
	ldh [hReqSfx], a
	ld a, 7
	ldh [rSVBK], a
	ld a, $2D
	call Sound_SelectBank
	call Sound_APUOn
.frame
	ldh a, [rLY]                  ; same timing as the game: wait for line $90
	cp $8F
	jr nz, .frame
.wait
	ldh a, [rLY]
	cp $90
	jr nz, .wait
	ld a, 7
	ldh [rSVBK], a
	ldh a, [hReqSfx]
	cp $FF
	jr z, .nosfx
	call Sound_PlaySfx
	ld a, $FF
	ldh [hReqSfx], a
.nosfx
	ldh a, [hReqSong]
	cp $FF
	jr z, .nosong
	push af
	call Sound_Stop
	call Sound_APUOn
	pop af
	cp $FE                        ; $FE = stop only
	call nz, Sound_PlaySong
	ld a, $FF
	ldh [hReqSong], a
.nosong
	call Sound_Update
	jr .frame
