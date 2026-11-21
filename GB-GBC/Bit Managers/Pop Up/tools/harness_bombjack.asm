; Test harness for Bomb Jack: replaces the boot jump, calls the real driver once per loop.
; Mailbox $DF00: 1/6 song1, 2/7 song2, 3 sfx [$DF01], 4 StopAll, 8 song3, 9 song4, 10 song5,
;               11 StartFade(speed [$DF01], FadeOutTable)
DEF SndInit EQU $5BE2
DEF SndUpdate EQU $54EE
DEF StopAll EQU $57F0
DEF PlaySfx EQU $5E69
DEF StartFade EQU $5B0E

SECTION "boot", ROM0[$0101]
	jp Harness

SECTION "harness", ROM0[$7A10]
Harness:
	di
	ld sp, $DFF0
	xor a
	ldh [$FFFF], a
	ldh [$FF82], a
	ldh [$FF99], a
	ldh [$FFC0], a
	ld [$C001], a
	ld [$DF00], a
	ld hl, $C300
	ld b, 0
.cl	ld [hli], a
	dec b
	jr nz, .cl
	call SndInit
Loop:
	ld a, [$DF00]
	and a
	jp z, .tick
	cp 3
	jr nz, .n3
	ld a, [$DF01]
	call PlaySfx
	jp .done
.n3	cp 4
	jr nz, .n4
	call StopAll
	jp .done
.n4	cp 11
	jr nz, .n11
	ld a, [$DF01]
	ld hl, $5B75
	call StartFade
	jp .done
.n11	cp 12
	jr nz, .n12
	ld a, [$DF01]
	ldh [$FF82], a
	jp .done
.n12	cp 13
	jr nz, .n13
	ld a, [$DF01]
	ldh [$FFC0], a
	ld [$C001], a
	jp .done
.n13	cp 14
	jr nz, .n14
	call StopAll
	ld a, $44
	ld [$C31F], a
	ld a, $73
	ld [$C320], a
	ld a, $0C
	ld [$C321], a
	ld a, $74
	ld [$C322], a
	ld de, TestOrd1
	call $5D85
	ld de, TestOrd2
	call $5D89
	ld de, TestOrd3
	call $5D8D
	jp .done
.n14	ld hl, SongTable
	add a, a
	ld e, a
	ld d, 0
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, .done
	push de
	jp hl
.done	xor a
	ld [$DF00], a
.tick	call SndUpdate
TickDone::
	nop
	jp Loop
SongTable:
	dw Loop.done, $60FB, $642E, Loop.done, Loop.done, Loop.done, $60FB, $642E, $64E6, $6584, $743E

; ---- synthetic streams for commands / argument forms the game data never uses ----
SECTION "testdata", ROM0[$7B00]
TestOrd1:
	dw TP1, 0, TestOrd1
TestOrd1b:
	dw TP1b, 0, TestOrd1
TestOrd2:
	dw TP2, 0, TestOrd2
TestOrd3:
	dw TP3, 0, TestOrd3
TP1:
	db $C6+10, $A7+12, 36        ; LEN 10, VOL 12, NOTE
	db $7A
	dw Sub1                      ; PAT_CALL Sub1
	db 38, $77, 0                ; NOTE, RELEASE 0 (off)
	db $72, $F1, 0, 40           ; HWENV $F1, 0 ; NOTE
	db $72, $A3, 5, $51, 41      ; HWENV $A3, 5, $51 ; NOTE
	db $77, 4, $62, 43           ; RELEASE 4, $62 ; NOTE (pulse: env2 into NRx2)
	db $B7+10, $12, $13, $21, 43 ; VOLENV 10 ; NOTE
	db $6B, 4
	dw $60A9                     ; DRUMS 4, Drums_60A9
	db 45, $6B, 0, $7D, 47       ; NOTE, DRUMS 0, NOISE_HIT7, NOTE
	db $69
	dw TestOrd1b                 ; ORDER_JUMP
TP1b:
	db $60, 1, 30, $60, 0, $61   ; GLIDE 1, NOTE, GLIDE 0, WAIT2
	db $76, 2, 30, $76, 0        ; CH_TRANSPOSE 2, NOTE, CH_TRANSPOSE 0
	db $98, 36, $78, $68         ; ARP 0, NOTE, ARP_OFF, NEXT
Sub1:
	db 50, $73, 3, $74, 2, 52    ; NOTE, AUTOPAN 3, AUTODUTY 2, NOTE
	db $73, 0, $74, 0, $68       ; AUTOPAN 0, AUTODUTY 0, NEXT (= return)
TP2:
	db $C6+57, $A7+10, 40, 42, 44, 45
	db $6A, 200, 47              ; LENGTH 200, NOTE
	db $65, 30, $68              ; STOP_ALL, NOTE (read but not played), NEXT
TP3:
	db $75
	dw $5EFF                     ; WAVE
	db $C6+20, $A7+15            ; LEN 20, VOL 15
	db $77, 5, $80, 36           ; RELEASE 5, $80 (CH3: volume = 8) ; NOTE
	db $72, $20, 0, 38           ; HWENV $20 on CH3 (NR32 raw, CH2 retrigger) ; NOTE
	db $B7+15, $00, $00, $11, 40 ; VOLENV 15 (back to software volume) ; NOTE
	db $64, 41, $68              ; REST, NOTE, NEXT
