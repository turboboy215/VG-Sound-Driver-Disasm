; Test harness for Pop Up: replaces the boot jump, calls the real driver once per loop.
; Mailbox: $DF00 = op (1 title, 2 song2, 3 sound [$DF01], 4 StopAll, 5 sound on), cleared when done.
DEF StopAll EQU $51D2
DEF PlaySound EQU $50E4
DEF PlayTitleMusic EQU $59A6
DEF PlaySong2 EQU $5E43
DEF SndUpdate EQU $5135

SECTION "boot", ROM0[$0101]
	jp Harness

SECTION "harness", ROM0[$7E60]
Harness:
	di
	ld sp, $DFF0
	xor a
	ldh [$FFFF], a
	ld [$DF00], a
	ld [$C339], a
	; same as the game's init code at $06FE-$075F
	ld hl, $C100
	ld de, $C101
	ld bc, $03FF
	ld [hl], l
	rst $00
	ld h, $C1
	ld b, $03
	xor a
	ld c, $08
	ld d, $01
	ld e, $08
.ch	ld l, $06
	ld [hli], a
	inc a
	inc l
	ld [hli], a
	inc a
	inc l
	ld [hl], c
	inc c
	ld l, $1F
	ld [hl], d
	inc l
	ld [hl], e
	rlc d
	rlc e
	inc h
	dec b
	jr nz, .ch
	ld hl, $C100
	ld de, $C400
	ld bc, $0100
	rst $00
	ld hl, $FF30
	ld b, $10
	ld a, $0F
.wv	ld [hli], a
	dec b
	jr nz, .wv
	ld a, $80
	ldh [$FFF2], a
	ldh [$FFF3], a
	ldh [$FF11], a
	ldh [$FF16], a
	ld a, $FF
	ldh [$FF24], a
	ld a, $8F
	ldh [$FF26], a
	ld hl, $FF10
	ld b, $14
	xor a
.cl	ld [hli], a
	dec b
	jr nz, .cl
	ld a, $80
	ldh [$FF1A], a
	call StopAll
Loop:
	ld a, [$DF00]
	cp 1
	jr nz, .n1
	call PlayTitleMusic
	jr .on
.n1	cp 2
	jr nz, .n2
	call PlaySong2
	jr .on
.n2	cp 3
	jr nz, .n3
	ld a, [$DF01]
	ld hl, $D000
	call PlaySound
	jr .done
.n3	cp 4
	jr nz, .n4
	call StopAll
	jr .done
.n4	cp 6
	jr nz, .n6
	call StopAll
	ld de, TestOrd1
	call $584F
	ld de, TestOrd2
	call $5854
	ld a, $FF
	ldh [$FF25], a
	ldh [$FFF1], a
	jr .on
.n6	cp 5
	jr nz, .done
.on	ld a, 1
	ldh [$FFF5], a
.done	xor a
	ld [$DF00], a
	ldh a, [$FFF5]
	and a
	call nz, SndUpdate
TickDone::
	nop
	jr Loop

; ---- synthetic streams for commands the game data never uses ----
SECTION "testdata", ROM0[$7F40]
TestOrd1:
	dw TestPat1, TestPat1b, 0, TestOrd1
TestOrd2:
	dw TestPat2, 0, TestOrd2
TestPat1:
	db $DE+20, $BF+12            ; LEN 20, VOL 12
	db $61, 8, $21               ; RELEASE 8, $21
	db 36                        ; NOTE C_,4
	db $63, $10, $00, 5          ; SLIDE +$10 x5
	db 38
	db $63, $10, $80, 5          ; SLIDE -$10 x5
	db 40
	db $64, $40, $00, $08, $80, 6 ; BEND from +$40, -8 x6
	db 41, $65                   ; NOTE, BEND_OFF
	db $B1, 43, $62              ; ARP 1, NOTE, ARP_OFF
	db $66, 2, 3, 4, 45, $67     ; VIBRATO 2,3,4, NOTE, VIBRATO_OFF
	db $69, $6A, $68             ; MASK_B, MASK_AB, MASK_A
	db $60, 1, 24, $71           ; GLIDE 1, NOTE, GLIDE_OFF
	db $75, 3, 36, $75, 0        ; ATTEN 3, NOTE, ATTEN 0
	db $78, $76, 9, $6B          ; NOISE_HIT1, LENGTH 9, WAIT
	db $72, 2, 36, $72, 0        ; TRANSPOSE 2, NOTE, TRANSPOSE 0
	db $74
	dw TestOrd1+2                ; ORDER_JUMP (to the 2nd entry)
TestPat1b:
	db $CF+10, $32, $23, $21     ; VOLENV 10
	db 48, $77, 50               ; NOTE, NOTE_OFF, NOTE
	db $B0, 52, $62, $73         ; ARP 0, NOTE, ARP_OFF, NEXT
TestPat2:
	db $DE+30, $BF+9, 30         ; LEN 30, VOL 9, NOTE
	db $6E, 31, 33, $6F          ; CHORUS_ON, NOTEs, CHORUS_OFF
	db $9A+2, 35                 ; PLAY_SFX 2 (stack bug), NOTE (stops the SFX)
	db $6C, 37, $73              ; REST, NOTE, NEXT
