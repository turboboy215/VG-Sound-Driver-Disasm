; test harness: drives the driver from $C000 commands (1 = song, 2 = SFX)
INCLUDE "hardware.inc"
SECTION "hdr", ROM0[$100]
    nop
    jp Main
    ds $150 - @, 0
SECTION "main", ROM0[$150]
Main:
    di
    ld sp, $DFFF - $40      ; below the driver RAM? driver uses $DF00-$DFAD
    ld sp, $D000
    xor a
    ld [$C000], a
    call GameSndInit
.frame:
    ldh a, [rLY]
    cp $90
    jr nz, .frame
    ld a, [$C000]
    or a
    jr z, .upd
    ld hl, $C001
    ld b, [hl]
    inc hl
    ld c, [hl]
    cp 1
    jr nz, .sfx
    call GamePlaySong
    jr .done
.sfx:
    call GamePlaySfx
.done:
    xor a
    ld [$C000], a
.upd:
    call GameSndUpdate
.wait:
    ldh a, [rLY]
    cp $90
    jr z, .wait
    jr .frame
