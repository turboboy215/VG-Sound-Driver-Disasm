; Test harness: runs the reassembled sound driver; agenda_pyboy_check.py
; drives it through wCmd/wArg and checks RAM at HookPoint after every update.
DEF wCmd EQU $C000
DEF wArg EQU $C001

SECTION "entry", ROM0[$0100]
    nop
    jp Main

SECTION "main", ROM0[$0150]
Main::
    di
    ld sp,$CF00
    ld hl,$C000             ; clear WRAM $C000-$DFFF
    ld bc,$2000
.clr
    xor a
    ld [hl+],a
    dec bc
    ld a,b
    or c
    jr nz,.clr
    ld hl,$FF80             ; clear HRAM $FF80-$FFFE
    ld b,$7F
    xor a
.clrh
    ld [hl+],a
    dec b
    jr nz,.clrh
    ld a,BANK(Sound_Init)
    ld [$2000],a
    call Sound_Init
InitDone::
    nop
Loop::
    ld a,[wCmd]
    or a
    jr z,.update
    ld b,a
    xor a
    ld [wCmd],a
    ld a,[wArg]
    dec b
    jr nz,.n1
    call Sound_PlayMusic
    jr .update
.n1 dec b
    jr nz,.n2
    call Sound_PlaySfx
    jr .update
.n2 dec b
    jr nz,.n3
    call Sound_StopMusic
    jr .update
.n3 dec b
    jr nz,.n4
    call Sound_SaveMusic
    jr .update
.n4 dec b
    jr nz,.n5
    call Sound_RestoreMusic
    jr .update
.n5 dec b
    jr nz,.update
    ld hl,UnusedSong        ; start the 4 pointers at UnusedSong
    call SND_STARTMUSIC
.update
    call Sound_Update
HookPoint::
    nop
    jr Loop

UnusedSong::
    dw UNUSED1, UNUSED2, UNUSED3, UNUSED4
