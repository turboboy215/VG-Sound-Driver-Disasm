; Kirby Tilt 'n' Tumble: PCM sample player (home bank)
INCLUDE "GB_Hardware.inc"

DEF wPcmDone         EQU $DE8B
DEF hRomBank         EQU $FFA1
DEF hPcmTrampoline   EQU $FFE5
DEF hPcmPointer      EQU $FFE6
DEF hPcmHandler      EQU $FFE9
DEF hPcmBank         EQU $FFEB
DEF hPcmEnd          EQU $FFEC
DEF hPcmState        EQU $FFEE

SECTION "KTT Timer vector", ROM0[$0050]
; Timer interrupt: continue in the HRAM trampoline.
TimerVector:
	push af
	push hl
	jp hPcmTrampoline


SECTION "KTT PCM timer interrupt handlers", ROM0[$0353]
; not part of the player (3 bytes before it)
Unknown_0353:
	db $01, $02, $04
; First sample of the byte (bits 6-4) to both halves of NR50, then point the trampoline at
; PcmIrq_Low. The sample bank is mapped for the read and hRomBank restored afterwards.
PcmIrq_High:
	ldh a, [hPcmBank]
	ld [$2100], a
	ld a, [hl]
	and $70
	ld h, a
	swap a
	or h
	ldh [rNR50], a
	ld a, LOW(PcmIrq_Low)
	ldh [hPcmHandler], a
	ldh a, [hRomBank]
	ld [$2100], a
	pop hl
	pop af
	reti

; Second sample (bits 2-0), next byte. Past hPcmEnd: hPcmState = 2, timer interrupt off,
; wPcmDone = 1 (WRAM bank 7) for the sound driver, NR50 = $77.
PcmIrq_Low:
	ldh a, [hPcmBank]
	ld [$2100], a
	ld a, [hl+]
	push hl
	and $07
	ld h, a
	swap a
	or h
	ldh [rNR50], a
	pop hl
	ldh a, [hPcmEnd+1]
	cp h
	jr z, .sameHigh
	jr nc, .next
	jr .end

.sameHigh:
	ldh a, [hPcmEnd]
	cp l
	jr nc, .next
.end:
	ld a, $02
	ldh [hPcmState], a
	ldh a, [rIE]
	and $fb
	ldh [rIE], a
	ldh a, [rSVBK]
	push af
	ld a, $07
	ldh [rSVBK], a
	ld a, $01
	ld [wPcmDone], a
	pop af
	ldh [rSVBK], a
	ld a, $77
	ldh [rNR50], a
; Save the pointer in the trampoline's `ld hl` and point it back at PcmIrq_High.
.next:
	ld a, h
	ldh [hPcmPointer+1], a
	ld a, l
	ldh [hPcmPointer], a
	ld a, LOW(PcmIrq_High)
	ldh [hPcmHandler], a
	ldh a, [hRomBank]
	ld [$2100], a
	pop hl
	pop af
	reti


SECTION "KTT PCM sample tables and player", ROM0[$0DAC]
; sample n at index 3n: address, bank
PcmStartTable:
	dw $4000
	db $19	; sample 0
	dw $58c2
	db $19	; sample 1
	dw $7395
	db $19	; sample 2
	dw $4060
	db $1a	; sample 3
	dw $4a16
	db $1a	; sample 4
	dw $5b2e
	db $1a	; sample 5
	dw $6239
	db $1a	; sample 6
	dw $650d
	db $1a	; sample 7
; last byte of sample n (played too), bank (not read)
PcmEndTable:
	dw $58c2
	db $19	; sample 0
	dw $7395
	db $19	; sample 1
	dw $7ead
	db $19	; sample 2
	dw $4a16
	db $1a	; sample 3
	dw $5b2e
	db $1a	; sample 4
	dw $6239
	db $1a	; sample 5
	dw $650d
	db $1a	; sample 6
	dw $67f4
	db $1a	; sample 7
; a = 3 * sample number. Ignored while hPcmState is non-zero. Builds the trampoline
; (`ld hl, start` / `jp PcmIrq_High`), mutes ch1 / ch2 / ch4 (not for sample 0), fills wave
; RAM with $FF and starts ch3 at full level, period $7DB. hPcmState = 1: the main loop
; enables the timer interrupt and stops calling the sound driver. Timer: 32768 Hz (TAC = 7,
; double speed) / 4 = 8192 Hz, or / 5 = 6553.6 Hz for samples 6 and 7.
PlayPcm:
	ld c, a
	ld b, $00
	ldh a, [hPcmState]
	and a
	ret nz
	ld hl, PcmEndTable
	add hl, bc
	ld a, [hl+]
	ldh [hPcmEnd], a
	ld a, [hl]
	ldh [hPcmEnd+1], a
	ld hl, PcmStartTable
	add hl, bc
	ld a, [hl+]
	ld e, a
	ld a, [hl+]
	ld d, a
	ld a, [hl]
	ldh [hPcmBank], a
	ld hl, hPcmTrampoline
	ld a, $21	; ld hl, start
	ld [hl+], a
	ld a, e
	ld [hl+], a
	ld a, d
	ld [hl+], a
	ld a, $c3	; jp PcmIrq_High
	ld [hl+], a
	ld a, LOW(PcmIrq_High)
	ld [hl+], a
	ld a, HIGH(PcmIrq_High)
	ld [hl], a
	ld a, c
	and a
	jr z, .wave
	ld a, $08
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR42], a
	ld a, $80
	ldh [rNR14], a
	ldh [rNR24], a
	ldh [rNR44], a
.wave:
	xor a
	ldh [rNR30], a
	ld hl, $ff30
	ld a, $ff
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld [hl+], a
	ld a, $80
	ldh [rNR30], a
	ld a, $20
	ldh [rNR32], a
	ld a, $db
	ldh [rNR33], a
	ld a, $87
	ldh [rNR34], a
	ld a, $01
	ldh [hPcmState], a
	ld a, $03
	ldh [rTAC], a
	ld a, c
	cp $12
	ld a, $fb
	jr nc, .rate
	ld a, $fc
.rate:
	ldh [rTMA], a
	ldh [rTIMA], a
	ld a, $07
	ldh [rTAC], a
	ret


