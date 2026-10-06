; Colin McRae Rally (E) - timer interrupt that plays the QuickThunder PCM channel
; ROM0 $0050 (vector) and $0238-$02DF. Each interrupt copies 16 bytes (32 4-bit samples)
; into wave RAM and restarts channel 3 at NR33/NR34 = $00/$87 (period $700 -> 8192 Hz).
; The timer runs at 4096 Hz / 32 (TMA = $E0); the game runs in double speed, so 256 Hz,
; which is exactly 32 samples x 256 = 8192 samples per second.
INCLUDE "QT_Macros.inc"
DEF wRomBank EQU $C000
DEF rROMB0 EQU $2000
DEF pcmcount EQU $C167
DEF pcmactive EQU $C169
DEF pcmbank EQU $C16A
DEF pcmadr EQU $C16B
DEF pcmprio EQU $C16E
DEF rSTAT EQU $FF41

SECTION "TimerVector", ROM0[$0050]
TimerVector::
    jp PcmTimerIrq

SECTION "PcmTimerIrq", ROM0[$0238]
PcmTimerIrq::
    push af
    push hl
    push bc
    push de
    ldh a, [rIF]
    and a, $FB
    ldh [rIF], a
    ei
    ld a, [wRomBank]
    push af
    ld hl, pcmcount
    ld a, [hli]
    or a, [hl]
    jr z, .l02CD
    ld a, [pcmbank]
    ld [wRomBank], a
    ld [rROMB0], a
    ld hl, pcmadr
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld c, $30
    ld de, rNR30
    ld a, [hli]
    ld b, a
    ld a, $BB
    ldh [rNR51], a
    xor a, a
    ldh [rNR30], a
    ld [de], a
    ld a, b
    ldh [c], a
    inc c
    ld a, [hli]
    ldh [c], a
    inc c
    ld a, [hli]
    ldh [c], a
    inc c
    ld a, [hli]
    ldh [c], a
    inc c
    ld a, [hli]
    ldh [c], a
    inc c
    ld a, [hli]
    ldh [c], a
    inc c
    ld a, [hli]
    ldh [c], a
    inc c
    ld a, [hli]
    ldh [c], a
    inc c
    ld a, [hli]
    ldh [c], a
    inc c
    ld a, [hli]
    ldh [c], a
    inc c
    ld a, [hli]
    ldh [c], a
    inc c
    ld a, [hli]
    ldh [c], a
    inc c
    ld a, [hli]
    ldh [c], a
    inc c
    ld a, [hli]
    ldh [c], a
    inc c
    ld a, [hli]
    ldh [c], a
    inc c
    ld a, [hli]
    ldh [c], a
    ld a, d
    ld [de], a
    ld a, $80
    ldh [rNR30], a
    ld a, $87
    ldh [rNR34], a
    ld a, $FF
    ldh [rNR51], a
    ld a, l
    ld [pcmadr], a
    ld a, h
    ld [pcmadr+1], a
    ld hl, pcmcount
    ld e, [hl]
    inc hl
    ld d, [hl]
    dec de
    ld [hl], d
    dec hl
    ld [hl], e
    ld a, d
    or a, e
    jr nz, .l02CD
    xor a, a
    ld [pcmactive], a
    ld [pcmprio], a
    ld hl, rNR51
    ld a, [hl]
    and a, $BB
    ld [hl], a
.l02CD
    pop af
    ld [wRomBank], a
    ld [rROMB0], a
    ei
    pop de
    pop bc
    pop hl
.l02D8
    ldh a, [rSTAT]
    bit 1, a
    jr nz, .l02D8
    pop af
    reti

