; QuickThunder test harness: Python writes a command to $DFF0 (1 = song, 2 = SFX)
; and the id to $DFF1; the main loop calls the driver once per frame (LY = 144).
INCLUDE "hconf.inc"   ; QT_BANK, QT_INIT, QT_SFX, QT_UPDATE

SECTION "Vectors", ROM0[$40]
    reti
    ds 7, 0
    reti
    ds 7, 0
    reti
    ds 7, 0
    reti
    ds 7, 0
    reti

SECTION "Header", ROM0[$100]
    nop
    jp Start
    ds $150 - @, 0

SECTION "Main", ROM0
Start:
    di
    ld sp, $DFE0
    xor a
    ldh [$FFFF], a
    ld [$DFF0], a
    ld a, QT_BANK
    ld [$2000], a
    ld e, 0
    call QT_INIT
.loop
    ldh a, [$FF44]
    cp 144
    jr nz, .loop
    ld a, [$DFF0]
    and a
    jr z, .run
    ld b, a
    xor a
    ld [$DFF0], a
    ld a, [$DFF1]
    ld e, a
    ld d, 0
    ld a, b
    cp 1
    jr nz, .sfx
    call QT_INIT
    jr .run
.sfx
    call QT_SFX
.run
    call QT_UPDATE
    ld hl, $DFF2          ; frame counter
    inc [hl]
.wait
    ldh a, [$FF44]
    cp 144
    jr z, .wait
    jr .loop
