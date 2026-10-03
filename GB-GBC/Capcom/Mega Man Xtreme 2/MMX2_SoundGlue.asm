;; ROM0 glue for the sound driver (Mega Man Xtreme 2)

DEF NUM_SOUND_IDS EQU $7D
INCLUDE "MMX_Sound.inc"

DEF SndJT_Update EQU $4000
DEF SndJT_Play   EQU $4003
DEF hCurROMBank  EQU $FF92
DEF wStage       EQU $C05F

SECTION "MMX2 VBlank sound update", ROM0[$01D5]

;; Inside the VBlank handler
VBlank_SndUpdate:
	ldh a, [hCurROMBank]
	push af
	ldh a, [hSndBank]
	ldh [hCurROMBank], a
	ld [rROMB0], a
	call SndJT_Update
	pop af
	ldh [hCurROMBank], a
	ld [rROMB0], a

SECTION "MMX2 sound glue", ROM0[$0A10]

;; GamePlayStageMusic: stop all, then play StageMusicTable[wStage]
GamePlayStageMusic:
	ld a, [wStage]
	ld hl, $0A25
	ld b, $00
	ld c, a
	add hl, bc
	ld a, [hl]
	ld a, a
	ldh [hSndID], a
	call GameStopSound
	call GamePlaySound
	ret

;; Music id per stage (13 stages)
StageMusicTable:
	db $01, $02, $03, $0D, $0C, $04, $05, $0A, $0B, $0E, $0E, $0E, $0F

;; GamePlaySound: hSndID = id. $F0 goes to the current bank; music ids
;; ($01-$1F) first set hSndBank from MusicBankTable (0 = no such song);
;; SFX ($20-$7C) play in the current bank; ids >= $7D are ignored.
;; Switching the bank does NOT stop a running SFX (see docs).
GamePlaySound:
	push bc
	push de
	push hl
	ldh a, [hSndID]
	cp a, $F0
	jr z, .play
	ldh a, [hSndID]
	sub a, $20
	jr nc, .l0A52
	ldh a, [hSndID]
	ld b, $00
	ld c, a
	ld hl, $0A79
	add hl, bc
	ld a, [hl]
	and a, a
	jr z, .done
	ldh [hSndBank], a
	jr .play
.l0A52:
	ldh a, [hSndID]
	sub a, $20
	jr c, .done
	ldh a, [hSndID]
	sub a, $7D
	jr nc, .done
	jr .play
.play:
	ldh a, [hCurROMBank]
	push af
	ldh a, [hSndBank]
	ldh [hCurROMBank], a
	ld [rROMB0], a
	ldh a, [hSndID]
	call SndJT_Play
	pop af
	ldh [hCurROMBank], a
	ld [rROMB0], a
.done:
	pop hl
	pop de
	pop bc
	ret

;; Sound bank for each music id $00-$1F (0 = none)
MusicBankTable:
	db $00, $02, $02, $02, $02, $02, $02, $02, $03, $03, $03, $03, $03, $03, $03, $03
	db $03, $03, $03, $03, $03, $03, $03, $00, $00, $00, $00, $00, $00, $00, $00, $00

;; GameStopSound: hSndBank = 2, command $F0 (stop all)
GameStopSound:
	ldh a, [hCurROMBank]
	push af
	ld a, $02
	ldh [hSndBank], a
	ldh [hCurROMBank], a
	ld [rROMB0], a
	ld a, $F0
	call SndJT_Play
	pop af
	ldh [hCurROMBank], a
	ld [rROMB0], a
	ret
