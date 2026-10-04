
; =============================================================================
; Game glue (ROM0 $28FD-$2980).  Only GamePlaySfx restores a bank (bank 2,
; where all its callers live); the others leave bank 4 mapped.
; =============================================================================

SECTION "SoundGlue", ROM0[$28FD]

; HL -> (song, speed); used by level start (0:$0254) with the level header
GamePlaySongFromHL::
    ld b, [hl]
    inc hl
    ld c, [hl]
    inc hl
; B = song, C = speed
GamePlaySong::
    sub a
    ld [$DF02], a               ; clears a byte of wWork: no effect (see doc)
    ld a, BANK(SndPlaySong_Entry)
    ld [$2000], a
    push hl
    ld l, b
    ld a, c
    ld c, 8                     ; C is not an argument of the driver
    call SndPlaySong_Entry
    pop hl
    ret

; silent song at speed 0, then one update
GameStopMusic::
    ld a, BANK(SndPlaySong_Entry)
    ld [$2000], a
    ld l, $FF
    sub a
    ld c, a
    call SndPlaySong_Entry
    jr GameSndUpdate

; B = SFX, C = speed (bank 0 callers)
GamePlaySfx::
    push bc
    push hl
.fromIndex:
    push af
    push de
    ld a, BANK(SndPlaySfx_Entry)
    ld [$2000], a
    ld l, b
    ld a, c
    ld c, 8
    call SndPlaySfx_Entry
    ld a, 2                     ; back to bank 2
    ld [$2000], a
    pop de
    pop af
    pop hl
    pop bc
    ret

; A = index into GameSfxList (bank 2 callers)
GamePlaySfxIndex::
    push bc
    push hl
    ld hl, GameSfxList
    add a
    ld b, 0
    ld c, a
    add hl, bc
    ld b, [hl]
    inc hl
    ld c, [hl]
    jr GamePlaySfx.fromIndex

GameSfxList: ; (SFX, speed)
    db $00, $F4 ;  0
    db $01, $E0 ;  1
    db $02, $F1 ;  2
    db $03, $E2 ;  3
    db $04, $DE ;  4
    db $05, $E6 ;  5
    db $06, $EB ;  6
    db $09, $E6 ;  7  -> SFX 9, not 7
    db $08, $EE ;  8
    db $09, $E6 ;  9
    db $0F, $EE ; 10  -> SFX 15, not 10
    db $0B, $E0 ; 11
    db $0C, $E0 ; 12
    db $0D, $E3 ; 13
    db $0E, $E1 ; 14
    db $0F, $DC ; 15
    db $10, $DD ; 16
    db $11, $EA ; 17

; once per frame from the main loops
GameSndUpdate::
    ld a, BANK(SndUpdate)
    ld [$2000], a
    call SndUpdate
    ret

; power-on (0:$01CB)
GameSndInit::
    ld a, BANK(SndInit_Entry)
    ld [$2000], a
    call SndInit_Entry
    ret
