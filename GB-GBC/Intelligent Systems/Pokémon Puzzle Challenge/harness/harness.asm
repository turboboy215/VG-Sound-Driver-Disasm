; Test harness: boots, calls Sound_Init, then Sound_Update once per frame (at LY 144).
; Requests come through a mailbox written by verify.py:
;   wBoxCmd  1 music [wBoxArg]   2 engine A single request   3 engine A multi request
;            4 engine B effect   5 PCM sample (blocking)      6 song header at wBoxArg:bank, wBoxPtr
;            7 Sound_StopAll
INCLUDE "GB_Hardware.inc"
INCLUDE "PPC_RAM.inc"
INCLUDE "PPC_Macros.inc"

DEF rLY EQU $FF44
DEF wBoxCmd  EQU $DE00
DEF wBoxArg  EQU $DE01
DEF wBoxPtr  EQU $DE02
DEF wBoxType EQU $DE04   ; copied to hConsoleType every frame
DEF wFrames  EQU $DE05

SECTION "Entry", ROM0[$0100]
	nop
	jp Main
	ds $0150 - @, 0

SECTION "Harness", ROM0[$0150]
Main:
	di
	ld sp, $DFFE
	ld a, $01
	ldh [hROMBank], a
	ld [rROMB0], a
	call Sound_Init
.loop
.wait1
	ldh a, [rLY]
	cp 144
	jr nz, .wait1
	ld a, [wBoxType]
	ldh [hConsoleType], a
	ld a, [wBoxCmd]
	and a
	call nz, Dispatch
	call Sound_Update
	ld hl, wFrames
	inc [hl]
.wait2
	ldh a, [rLY]
	cp 144
	jr z, .wait2
	jr .loop

Dispatch:
	ld b, a
	xor a
	ld [wBoxCmd], a
	ld a, [wBoxArg]
	dec b
	jp z, Sound_PlayMusic
	dec b
	jr nz, .n2
	ld [wSfxRequest1], a
	ret
.n2
	dec b
	jr nz, .n3
	ld [wSfxMultiRequest], a
	ret
.n3
	dec b
	jr nz, .n4
	ld [wSfxBRequest], a
	ret
.n4
	dec b
	jp z, Sound_PlayPCM
	dec b
	jr z, PlayCustom
	dec b
	jp z, Sound_StopAll
	ret

PlayCustom:
	ld a, BANK(Music_Init)
	ldh [hROMBank], a
	ld [rROMB0], a
	call Music_Init
	ld a, [wBoxArg]
	ld [wMusicBank], a
	ld a, [wBoxPtr]
	ld l, a
	ld a, [wBoxPtr + 1]
	ld h, a
	ld de, wMusCh1Ptr
	ld b, 4
.ch
	push bc
	push de
	call Music_FetchHeaderByte
	ld a, e
	pop de
	ld [de], a
	inc de
	push de
	call Music_FetchHeaderByte
	ld a, e
	pop de
	ld [de], a
	ld a, e
	add $2F
	ld e, a
	ld a, d
	adc 0
	ld d, a
	pop bc
	dec b
	jr nz, .ch
	ld hl, wMusicFlags
	set 7, [hl]
	ld a, 6
	ld [wMusicTempo], a
	ld a, 30
	ld [wMusicTempoAcc], a
	ret

SECTION "FarCall", ROM0[$09A6]   ; copy of the game's FarCall (used by SfxB_Start)
HarnessFarCall:
	pop hl
	inc hl
	inc hl
	inc hl
	push hl
	dec hl
	ldh a, [hROMBank]
	push af
	ld a, [hl-]
	push af
	ld a, [hl-]
	ld l, [hl]
	ld h, a
	pop af
	ldh [hROMBank], a
	ld [rROMB0], a
	call .jphl
	pop af
	ldh [hROMBank], a
	ld [rROMB0], a
	ret
.jphl
	jp hl
