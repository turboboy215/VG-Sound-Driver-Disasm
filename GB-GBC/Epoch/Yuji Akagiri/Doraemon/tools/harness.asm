; test harness: plays one song (and optionally an SFX later), calling the
; driver once per loop; FrameDone is hooked from Python.
SECTION "entry", ROM0[$100]
    nop
    jp Main
    ds $150 - $104, 0
SECTION "main", ROM0[$150]
Main:
    di
    ld sp,$DFF0
    ld hl,$C000
    ld bc,$1F00
.clr
    xor a
    ld [hli],a
    dec bc
    ld a,b
    or c
    jr nz,.clr
    xor a
    ldh [$FF80],a
    ldh [$FF83],a
    ld a,BANK(Sound_Init)
    ld [$2000],a
    call Sound_Init
.wait
    ldh a,[$FF80]
    and a
    jr z,.wait
    ldh a,[$FF81]
    ld b,a
    ldh a,[$FF82]
    and a
    ld a,b
    jr nz,.sfx
    call Sound_PlayMusic
    jr MainLoop
.sfx
    call Sound_PlaySfx
MainLoop:
    call Sound_Output
    call Sound_Update
FrameDone::
    nop
    ldh a,[$FF83]
    and a
    jr z,MainLoop
    xor a
    ldh [$FF83],a
    ldh a,[$FF84]
    call Sound_PlaySfx
    jr MainLoop
