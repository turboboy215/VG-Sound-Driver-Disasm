; =============================================================================
;  Wayne's World (Game Boy, 1993)  -  SOUND DRIVER DISASSEMBLY
;  ROM: "Wayne's World (U).gb"  title WAYNE'S WORLD, lic $78 (THQ)
;  Developer: Radical Entertainment   Music: Paul Wilkinson
;
;  Everything lives in ROM bank $0A:
;    $4000        bank-ID byte ($0A)
;    $4001        Snd_PlayMusic (C = song #) + song table $4012
;    $4032-$67C6  song headers, tracks, 6-byte instruments;
;                 SFX pointer table at $5747 (33 streams)
;    $6815-$6C40  driver code,  $6C41-$6D40 tables
;  Bank 0 code maps bank $0A around each call (call sites $0C6C, $0F9A,
;  $1C3B reset; $1ADF SFX; $134E Snd_Update, gated by flag $C328).
;
;  PCM: the digitised samples are played by a SEPARATE routine (4 copies,
;  banks $03/$06/$0E) that bit-bangs CH3 wave RAM with interrupts off.
;  It shares no code with this driver - see the comparison notes.
;
;  Re-assembles byte-exact with RGBDS (verified, both sections).
; -----------------------------------------------------------------------------
;  A DIRECT DESCENDANT OF THE BATTLE OF OLYMPUS DRIVER
;   * RAM layout = BO's, moved from $DExx to $C3xx (BO address - $1B0C)
;   * Same stream format, same 6-byte instruments, same priority/SFX slots
;   Changes vs BO:
;   * ReadVarLen bug fixed (15-bit lengths); delta 0 chains events in 1 frame
;   * CH3 (wave) enabled; wave reload keyed on the instrument's CHANNEL
;   * Note param is now a gate: when the channel timer expires the note is
;     keyed off (length-enable trick on CH1/2, park CH3, NR42=0 on CH4)
;   * NRx2 comes straight from the instrument (no param envelope bits)
;   * D9 ends the track (BO: restart song); DB restarts the tracks in place
;   * NR52=$8F, NR51=$DE (BO: $FF/$FF)
; =============================================================================

INCLUDE "hardware.inc"

; ---- RAM used by the sound driver ----
DEF wSnd_Enabled EQU $c32a
DEF wSnd_SongHeader EQU $c32c
DEF wSnd_SongDE EQU $c32e
DEF wSnd_Block EQU $c330
DEF wSnd_ChanPriority EQU $c33c
DEF wSnd_ChanTimer EQU $c340
DEF wSnd_NumTracks EQU $c344
DEF wSnd_TrackPtr EQU $c345
DEF wSnd_TrackWait EQU $c357
DEF wSnd_TrackEvent EQU $c369
DEF wSnd_TrackNoteParam EQU $c372
DEF wSnd_TrackInstr EQU $c384
DEF wSnd_TrackTranspose EQU $c396
DEF wSnd_EventArg EQU $c39f
DEF wSnd_InstrTable EQU $c3a1
DEF wSnd_Tempo EQU $c3a3
DEF wSnd_Unused_A4 EQU $c3a4
DEF wSnd_NoteByte EQU $c3a5
DEF wSnd_Ch1FreqHi EQU $c3a6
DEF wSnd_Ch2FreqHi EQU $c3a7
DEF wSnd_Ch3FreqHi EQU $c3a8
DEF wSnd_CurInstr EQU $c3a9
DEF wSnd_FreqLo EQU $c3ac
DEF wSnd_FreqHi EQU $c3ad
DEF wSnd_TmpPtr EQU $c3ae
DEF wSnd_ParamCopy EQU $c3b0
DEF wSnd_TrackUnusedB1 EQU $c3b1

; ---- outside the driver ----

SECTION "WW Sound Entry", ROMX[$4000], BANK[$0a]


; Bank-ID byte: bank 0 code reads $4000 to know which bank to restore
    db $0a                        ; 4000

Snd_PlayMusic:
    ld a, c                       ; 4001: 79       | C = song number
    ld hl, Snd_SongTable          ; 4002: 21 12 40 | Snd_SongTable
    sla a                         ; 4005: cb 27
    ld c, a                       ; 4007: 4f
    ld b, $00                     ; 4008: 06 00
    add hl, bc                    ; 400a: 09
    ld a, [hl+]                   ; 400b: 2a
    ld h, [hl]                    ; 400c: 66
    ld l, a                       ; 400d: 6f
    call Snd_PlaySong             ; 400e: cd 15 68 | HL = header
    ret                           ; 4011: c9

; 16 song headers (entries 0/1 and 11/15 are duplicates)
Snd_SongTable:
    dw $4032                      ; 4012 | song 0
    dw $4032                      ; 4014 | song 1
    dw $5b8d                      ; 4016 | song 2
    dw $43b0                      ; 4018 | song 3
    dw $5cd9                      ; 401a | song 4
    dw $5dd5                      ; 401c | song 5
    dw $449b                      ; 401e | song 6
    dw $475b                      ; 4020 | song 7
    dw $4a63                      ; 4022 | song 8
    dw $4da4                      ; 4024 | song 9
    dw $4e68                      ; 4026 | song 10
    dw $5425                      ; 4028 | song 11
    dw $5f6b                      ; 402a | song 12
    dw $5ffe                      ; 402c | song 13
    dw $678e                      ; 402e | song 14
    dw $5425                      ; 4030 | song 15

SECTION "WW Sound Driver", ROMX[$6815], BANK[$0a]


; =============================================================================
; Snd_PlaySong  HL = song header (bank 10).  Called from Snd_PlayMusic ($4001).
;   Header: db nTracks / dw track[0..n-1]   (Battle of Olympus format)
; =============================================================================
Snd_PlaySong:
    call Snd_APUOff               ; 6815: cd cf 68 | NR52 = 0 first
    push de                       ; 6818: d5       | HL = song header
    push hl                       ; 6819: e5
    call Snd_StartSong            ; 681a: cd 20 68
    pop hl                        ; 681d: e1
    pop de                        ; 681e: d1
    ret                           ; 681f: c9

Snd_StartSong:
    push hl                       ; 6820: e5
    push de                       ; 6821: d5
    call Snd_Reset                ; 6822: cd d9 68 | stop everything (clears whole RAM block)
    pop de                        ; 6825: d1
    pop hl                        ; 6826: e1
    ld a, l                       ; 6827: 7d       | remember header
    ld [wSnd_SongHeader], a       ; 6828: ea 2c c3
    ld a, h                       ; 682b: 7c
    ld [wSnd_SongHeader+1], a     ; 682c: ea 2d c3
    ld a, e                       ; 682f: 7b       | DE stored (only used by restarts)
    ld [wSnd_SongDE], a           ; 6830: ea 2e c3
    ld [wSnd_InstrTable], a       ; 6833: ea a1 c3 | DE copy never read - same vestige as Battle of Olympus
    ld a, d                       ; 6836: 7a
    ld [wSnd_SongDE+1], a         ; 6837: ea 2f c3
    ld [wSnd_InstrTable+1], a     ; 683a: ea a2 c3
    ld a, [hl+]                   ; 683d: 2a       | header byte 0 = track count
    ld [wSnd_NumTracks], a        ; 683e: ea 44 c3
    ld b, a                       ; 6841: 47
    ld de, wSnd_TrackPtr          ; 6842: 11 45 c3 | copy track pointers

.copyPtrs:
    ld a, [hl+]                   ; 6845: 2a
    ld [de], a                    ; 6846: 12
    inc de                        ; 6847: 13
    ld a, [hl+]                   ; 6848: 2a
    ld [de], a                    ; 6849: 12
    inc de                        ; 684a: 13
    dec b                         ; 684b: 05
    jr nz, .copyPtrs              ; 684c: 20 f7
    ld a, [wSnd_NumTracks]        ; 684e: fa 44 c3
    ld b, a                       ; 6851: 47
    xor a                         ; 6852: af
    ld hl, wSnd_TrackWait         ; 6853: 21 57 c3 | zero waits

.clrWait:
    ld [hl+], a                   ; 6856: 22
    ld [hl+], a                   ; 6857: 22
    dec b                         ; 6858: 05
    jr nz, .clrWait               ; 6859: 20 fb
    ld a, [wSnd_NumTracks]        ; 685b: fa 44 c3
    ld b, a                       ; 685e: 47
    xor a                         ; 685f: af
    ld hl, wSnd_TrackNoteParam    ; 6860: 21 72 c3 | zero note params

.clrParam:
    ld [hl+], a                   ; 6863: 22
    ld [hl+], a                   ; 6864: 22
    dec b                         ; 6865: 05
    jr nz, .clrParam              ; 6866: 20 fb
    ld a, $60                     ; 6868: 3e 60    | "tempo" $60, never read
    ld [wSnd_Tempo], a            ; 686a: ea a3 c3
    ld a, $8f                     ; 686d: 3e 8f    | NR52 = $8F
    ldh [rNR52], a                ; 686f: e0 26
    ld a, $77                     ; 6871: 3e 77    | master volume 7/7
    ldh [rNR50], a                ; 6873: e0 24
    ld a, $de                     ; 6875: 3e de    | NR51 = $DE: CH1 left only, CH2 right only (BO/TG: $FF)
    ldh [rNR51], a                ; 6877: e0 25
    ld a, $01                     ; 6879: 3e 01    | enabled
    ld [wSnd_Enabled], a          ; 687b: ea 2a c3
    ret                           ; 687e: c9

; Snd_RestartTracks (command DB)
Snd_RestartTracks:
    ld a, [hl+]                   ; 687f: 2a       | DB: reload track pointers + clear waits, no APU reset
    ld [wSnd_NumTracks], a        ; 6880: ea 44 c3
    ld b, a                       ; 6883: 47
    ld de, wSnd_TrackPtr          ; 6884: 11 45 c3

.copyPtrs:
    ld a, [hl+]                   ; 6887: 2a
    ld [de], a                    ; 6888: 12
    inc de                        ; 6889: 13
    ld a, [hl+]                   ; 688a: 2a
    ld [de], a                    ; 688b: 12
    inc de                        ; 688c: 13
    dec b                         ; 688d: 05
    jr nz, .copyPtrs              ; 688e: 20 f7
    ld a, [wSnd_NumTracks]        ; 6890: fa 44 c3
    ld b, a                       ; 6893: 47
    xor a                         ; 6894: af
    ld hl, wSnd_TrackWait         ; 6895: 21 57 c3

.clrWait:
    ld [hl+], a                   ; 6898: 22
    ld [hl+], a                   ; 6899: 22
    dec b                         ; 689a: 05
    jr nz, .clrWait               ; 689b: 20 fb
    ret                           ; 689d: c9

Snd_AddTrackWrapA:
    call Snd_AddTrack             ; 689e: cd a6 68 | (unreferenced wrapper)
    ret                           ; 68a1: c9

Snd_AddTrackWrapB:
    call Snd_AddTrack             ; 68a2: cd a6 68 | (unreferenced wrapper)
    ret                           ; 68a5: c9

; Snd_AddTrack: HL = SFX stream -> first free slot 8..0 (bank 0 call at $1ADF)
Snd_AddTrack:
    ld d, h                       ; 68a6: 54       | DE = SFX stream
    ld e, l                       ; 68a7: 5d
    ld bc, $0008                  ; 68a8: 01 08 00 | from slot 8 down

.scan:
    ld hl, wSnd_TrackPtr          ; 68ab: 21 45 c3
    add hl, bc                    ; 68ae: 09
    add hl, bc                    ; 68af: 09
    ld a, [hl+]                   ; 68b0: 2a
    or [hl]                       ; 68b1: b6
    jr z, .found                  ; 68b2: 28 07
    dec c                         ; 68b4: 0d
    ld a, c                       ; 68b5: 79
    inc a                         ; 68b6: 3c
    jr z, .full                   ; 68b7: 28 07
    jr .scan                      ; 68b9: 18 f0

.found:
    ld a, d                       ; 68bb: 7a
    ld [hl-], a                   ; 68bc: 32
    ld a, e                       ; 68bd: 7b
    ld [hl], a                    ; 68be: 77

.done:
    ret                           ; 68bf: c9

.full:
    nop                           ; 68c0: 00       | all busy: SFX dropped
    jp .done                      ; 68c1: c3 bf 68

; enable / disable / APU helpers
Snd_Disable:
    xor a                         ; 68c4: af       | (unreferenced)
    ld [wSnd_Enabled], a          ; 68c5: ea 2a c3
    ret                           ; 68c8: c9

Snd_Enable:
    ld a, $01                     ; 68c9: 3e 01    | (unreferenced)
    ld [wSnd_Enabled], a          ; 68cb: ea 2a c3
    ret                           ; 68ce: c9

Snd_APUOff:
    ld a, $00                     ; 68cf: 3e 00
    ldh [rNR52], a                ; 68d1: e0 26
    ret                           ; 68d3: c9

Snd_APUOn:
    ld a, $ff                     ; 68d4: 3e ff    | (unreferenced)
    ldh [rNR52], a                ; 68d6: e0 26
    ret                           ; 68d8: c9

; Snd_Reset (command DA)
Snd_Reset:
    xor a                         ; 68d9: af
    ld [wSnd_Enabled], a          ; 68da: ea 2a c3
    ld [wSnd_Unused_A4], a        ; 68dd: ea a4 c3
    ld bc, $0008                  ; 68e0: 01 08 00

.clrTracks:
    xor a                         ; 68e3: af
    ld hl, wSnd_TrackPtr          ; 68e4: 21 45 c3 | computes the TrackPtr slot...
    add hl, bc                    ; 68e7: 09
    add hl, bc                    ; 68e8: 09
    ld hl, wSnd_TrackUnusedB1     ; 68e9: 21 b1 c3 | ...then overwrites HL: only wSnd_TrackUnusedB1 is cleared here
    add hl, bc                    ; 68ec: 09
    add hl, bc                    ; 68ed: 09
    ld [hl+], a                   ; 68ee: 22
    ld [hl], a                    ; 68ef: 77
    dec bc                        ; 68f0: 0b
    ld a, c                       ; 68f1: 79
    inc a                         ; 68f2: 3c
    jr nz, .clrTracks             ; 68f3: 20 ee
    xor a                         ; 68f5: af
    ld b, $84                     ; 68f6: 06 84    | clear $C330-$C3B3 (covers everything anyway)
    ld hl, wSnd_Block             ; 68f8: 21 30 c3

.clrBlock:
    ld [hl+], a                   ; 68fb: 22
    dec b                         ; 68fc: 05
    jr nz, .clrBlock              ; 68fd: 20 fc
    ret                           ; 68ff: c9

; Snd_KillTrack (commands D9 / EA)
Snd_KillTrack:
    ld hl, wSnd_TrackPtr          ; 6900: 21 45 c3 | track pointer = 0
    add hl, bc                    ; 6903: 09
    add hl, bc                    ; 6904: 09
    ld a, $00                     ; 6905: 3e 00
    ld [hl+], a                   ; 6907: 22
    ld [hl], a                    ; 6908: 77
    ld hl, wSnd_TrackUnusedB1     ; 6909: 21 b1 c3 | and its B1 entry
    add hl, bc                    ; 690c: 09
    add hl, bc                    ; 690d: 09
    ld a, $00                     ; 690e: 3e 00
    ld [hl+], a                   ; 6910: 22
    ld [hl], a                    ; 6911: 77
    ret                           ; 6912: c9

Snd_KillTrack_dead:
    ld hl, wSnd_TrackUnusedB1     ; 6913: 21 b1 c3 | --- unreachable duplicate of the KillTrack body ---
    ld hl, wSnd_TrackPtr          ; 6916: 21 45 c3
    add hl, bc                    ; 6919: 09
    add hl, bc                    ; 691a: 09
    ld a, $00                     ; 691b: 3e 00
    ld [hl+], a                   ; 691d: 22
    ld [hl], a                    ; 691e: 77
    ret                           ; 691f: c9

; =============================================================================
; Snd_Update - called from bank 0 ($134E, only while $C328 != 0) with bank 10 mapped
; =============================================================================
Snd_Update:
    ld a, $04                     ; 6920: 3e 04    | 4 channel hold timers 3..0
    dec a                         ; 6922: 3d
    ld c, a                       ; 6923: 4f
    ld b, $00                     ; 6924: 06 00

.chanLoop:
    push bc                       ; 6926: c5
    call Snd_TickChanTimer        ; 6927: cd d6 6b
    pop bc                        ; 692a: c1
    dec c                         ; 692b: 0d
    ld a, c                       ; 692c: 79
    inc a                         ; 692d: 3c
    jr nz, .chanLoop              ; 692e: 20 f6
    ld a, $09                     ; 6930: 3e 09    | 9 tracks 8..0
    dec a                         ; 6932: 3d
    ld c, a                       ; 6933: 4f
    ld b, $00                     ; 6934: 06 00

.trackLoop:
    push bc                       ; 6936: c5
    call Snd_UpdateTrack          ; 6937: cd 41 69
    pop bc                        ; 693a: c1
    dec c                         ; 693b: 0d
    ld a, c                       ; 693c: 79
    inc a                         ; 693d: 3c
    jr nz, .trackLoop             ; 693e: 20 f6
    ret                           ; 6940: c9

; =============================================================================
; Snd_UpdateTrack  BC = track 0-8
; =============================================================================
Snd_UpdateTrack:
    ld hl, wSnd_TrackPtr          ; 6941: 21 45 c3 | track active?
    add hl, bc                    ; 6944: 09
    add hl, bc                    ; 6945: 09
    ld a, [hl+]                   ; 6946: 2a
    or [hl]                       ; 6947: b6
    jp z, Snd_UpdateTrackRet      ; 6948: ca f8 69
    ld hl, wSnd_TrackWait+1       ; 694b: 21 58 c3 | 16-bit wait
    add hl, bc                    ; 694e: 09
    add hl, bc                    ; 694f: 09
    ld a, [hl-]                   ; 6950: 3a
    or [hl]                       ; 6951: b6
    jr z, Snd_NextEvent           ; 6952: 28 06
    dec [hl]                      ; 6954: 35       | still waiting: decrement, exit
    ld a, [hl+]                   ; 6955: 2a
    inc a                         ; 6956: 3c
    ret nz                        ; 6957: c0
    dec [hl]                      ; 6958: 35
    ret                           ; 6959: c9

Snd_NextEvent:
    ld hl, wSnd_TrackPtr          ; 695a: 21 45 c3
    add hl, bc                    ; 695d: 09
    add hl, bc                    ; 695e: 09
    ld a, [hl+]                   ; 695f: 2a
    ld h, [hl]                    ; 6960: 66
    ld l, a                       ; 6961: 6f
    call Snd_ReadEvent            ; 6962: cd f9 69 | parse event
    ld hl, wSnd_TrackEvent        ; 6965: 21 69 c3 | event byte
    add hl, bc                    ; 6968: 09
    ld a, [hl]                    ; 6969: 7e
    cp $d9                        ; 696a: fe d9    | < $D9: note
    jr nc, .command               ; 696c: 30 05
    call Snd_NoteOn               ; 696e: cd b2 6a
    jr Snd_ReadDelta              ; 6971: 18 6c

.command:
    cp $dc                        ; 6973: fe dc
    jp z, .cmdDC                  ; 6975: ca d5 69
    cp $dd                        ; 6978: fe dd
    jr z, .cmdDD                  ; 697a: 28 5e
    cp $da                        ; 697c: fe da    | DA: stop all
    jp z, Snd_Reset               ; 697e: ca d9 68
    cp $d9                        ; 6981: fe d9    | D9: end this track (BO: restart song)
    jp z, .cmdKill                ; 6983: ca 98 69
    cp $e3                        ; 6986: fe e3    | E3: loop this track
    jp z, .cmdE3_LoopTrack        ; 6988: ca 9e 69
    cp $ea                        ; 698b: fe ea    | EA: end this track
    jp z, .cmdKill                ; 698d: ca 98 69
    cp $db                        ; 6990: fe db    | DB: restart all tracks
    jp z, .cmdDB_Restart          ; 6992: ca c2 69
    jp Snd_BadCommand             ; 6995: c3 1e 6c | anything else: restart song

.cmdKill:
    call Snd_KillTrack            ; 6998: cd 00 69
    jp Snd_UpdateTrackRet         ; 699b: c3 f8 69

.cmdE3_LoopTrack:
    ld a, [wSnd_SongHeader]       ; 699e: fa 2c c3
    ld l, a                       ; 69a1: 6f
    ld a, [wSnd_SongHeader+1]     ; 69a2: fa 2d c3
    ld h, a                       ; 69a5: 67
    inc hl                        ; 69a6: 23
    add hl, bc                    ; 69a7: 09
    add hl, bc                    ; 69a8: 09
    ld a, [hl+]                   ; 69a9: 2a
    ld [wSnd_TmpPtr], a           ; 69aa: ea ae c3
    ld a, [hl-]                   ; 69ad: 3a
    ld [wSnd_TmpPtr+1], a         ; 69ae: ea af c3
    ld hl, wSnd_TrackPtr          ; 69b1: 21 45 c3
    add hl, bc                    ; 69b4: 09
    add hl, bc                    ; 69b5: 09
    ld a, [wSnd_TmpPtr]           ; 69b6: fa ae c3
    ld [hl], a                    ; 69b9: 77
    inc hl                        ; 69ba: 23
    ld a, [wSnd_TmpPtr+1]         ; 69bb: fa af c3
    ld [hl], a                    ; 69be: 77
    jp Snd_ReadDelta              ; 69bf: c3 df 69

.cmdDB_Restart:
    ld a, [wSnd_SongHeader]       ; 69c2: fa 2c c3
    ld l, a                       ; 69c5: 6f
    ld a, [wSnd_SongHeader+1]     ; 69c6: fa 2d c3
    ld h, a                       ; 69c9: 67
    ld a, [wSnd_SongDE]           ; 69ca: fa 2e c3
    ld e, a                       ; 69cd: 5f
    ld a, [wSnd_SongDE+1]         ; 69ce: fa 2f c3
    ld d, a                       ; 69d1: 57
    jp Snd_RestartTracks          ; 69d2: c3 7f 68

.cmdDC:
    call Snd_SetInstrument        ; 69d5: cd 6a 6a
    jr Snd_ReadDelta              ; 69d8: 18 05

.cmdDD:
    call Snd_SetTempo             ; 69da: cd 17 6c
    jr Snd_ReadDelta              ; 69dd: 18 00

Snd_ReadDelta:
    ld hl, wSnd_TrackPtr          ; 69df: 21 45 c3
    add hl, bc                    ; 69e2: 09
    add hl, bc                    ; 69e3: 09
    ld a, [hl+]                   ; 69e4: 2a
    ld h, [hl]                    ; 69e5: 66
    ld l, a                       ; 69e6: 6f
    call Snd_ReadVarLen           ; 69e7: cd 2e 6c | delta before the next event
    ld a, d                       ; 69ea: 7a
    or e                          ; 69eb: b3
    jp z, Snd_NextEvent           ; 69ec: ca 5a 69 | delta 0 -> process the next event THIS frame (BO waits a frame)
    dec de                        ; 69ef: 1b       | wait = delta - 1
    ld hl, wSnd_TrackWait         ; 69f0: 21 57 c3
    add hl, bc                    ; 69f3: 09
    add hl, bc                    ; 69f4: 09
    ld a, e                       ; 69f5: 7b
    ld [hl+], a                   ; 69f6: 22
    ld [hl], d                    ; 69f7: 72

Snd_UpdateTrackRet:
    ret                           ; 69f8: c9

; Snd_ReadEvent - identical to Battle of Olympus apart from RAM addresses
Snd_ReadEvent:
    call Snd_ReadVarLen           ; 69f9: cd 2e 6c | skip the delta already used
    ld a, [hl+]                   ; 69fc: 2a
    push hl                       ; 69fd: e5
    ld hl, wSnd_TrackEvent        ; 69fe: 21 69 c3
    add hl, bc                    ; 6a01: 09
    ld [hl], a                    ; 6a02: 77
    pop hl                        ; 6a03: e1
    cp $d9                        ; 6a04: fe d9    | < $D9: note
    jr c, .note                   ; 6a06: 38 44
    cp $d9                        ; 6a08: fe d9    | no-arg commands: D9 DA DB E3 EA
    jr z, .savePtr                ; 6a0a: 28 35
    cp $da                        ; 6a0c: fe da
    jr z, .savePtr                ; 6a0e: 28 31
    cp $db                        ; 6a10: fe db
    jr z, .savePtr                ; 6a12: 28 2d
    cp $e3                        ; 6a14: fe e3
    jr z, .savePtr                ; 6a16: 28 29
    cp $ea                        ; 6a18: fe ea
    jr z, .savePtr                ; 6a1a: 28 25
    cp $dc                        ; 6a1c: fe dc    | DC/DF: 2 bytes
    jr z, .twoArgs                ; 6a1e: 28 13
    cp $dd                        ; 6a20: fe dd    | DD/DE/E2: 1 byte
    jr z, .oneArg                 ; 6a22: 28 19
    cp $de                        ; 6a24: fe de
    jr z, .oneArg                 ; 6a26: 28 15
    cp $e2                        ; 6a28: fe e2
    jr z, .oneArg                 ; 6a2a: 28 11
    cp $df                        ; 6a2c: fe df
    jr z, .twoArgs                ; 6a2e: 28 03
    jp Snd_BadCommand             ; 6a30: c3 1e 6c | unknown: restart song

.twoArgs:
    ld a, [hl+]                   ; 6a33: 2a
    ld [wSnd_EventArg], a         ; 6a34: ea 9f c3
    ld a, [hl+]                   ; 6a37: 2a
    ld [wSnd_EventArg+1], a       ; 6a38: ea a0 c3
    jr .savePtr                   ; 6a3b: 18 04

.oneArg:
    ld a, [hl+]                   ; 6a3d: 2a
    ld [wSnd_EventArg], a         ; 6a3e: ea 9f c3

.savePtr:
    ld d, h                       ; 6a41: 54
    ld e, l                       ; 6a42: 5d
    ld hl, wSnd_TrackPtr          ; 6a43: 21 45 c3
    add hl, bc                    ; 6a46: 09
    add hl, bc                    ; 6a47: 09
    ld a, e                       ; 6a48: 7b
    ld [hl+], a                   ; 6a49: 22
    ld [hl], d                    ; 6a4a: 72
    ret                           ; 6a4b: c9

.note:
    bit 7, a                      ; 6a4c: cb 7f    | bit 7 = extra byte follows (ignored)
    jr z, .noteParam              ; 6a4e: 28 04
    ld a, [hl+]                   ; 6a50: 2a
    ld [wSnd_EventArg], a         ; 6a51: ea 9f c3

.noteParam:
    call Snd_ReadVarLen           ; 6a54: cd 2e 6c | note parameter
    push hl                       ; 6a57: e5
    ld hl, wSnd_TrackNoteParam    ; 6a58: 21 72 c3
    add hl, bc                    ; 6a5b: 09
    add hl, bc                    ; 6a5c: 09
    ld a, e                       ; 6a5d: 7b
    ld [hl+], a                   ; 6a5e: 22
    ld [hl], d                    ; 6a5f: 72
    pop de                        ; 6a60: d1
    ld hl, wSnd_TrackPtr          ; 6a61: 21 45 c3
    add hl, bc                    ; 6a64: 09
    add hl, bc                    ; 6a65: 09
    ld a, e                       ; 6a66: 7b
    ld [hl+], a                   ; 6a67: 22
    ld [hl], d                    ; 6a68: 72
    ret                           ; 6a69: c9

; Snd_SetInstrument (DC ptr16).  Instrument = BO 6-byte layout (7-8 for CH4)
Snd_SetInstrument:
    ld hl, wSnd_TrackInstr        ; 6a6a: 21 84 c3 | instrument pointer from DC
    add hl, bc                    ; 6a6d: 09
    add hl, bc                    ; 6a6e: 09
    ld a, [wSnd_EventArg]         ; 6a6f: fa 9f c3
    ld [hl+], a                   ; 6a72: 22
    ld a, [wSnd_EventArg+1]       ; 6a73: fa a0 c3
    ld [hl-], a                   ; 6a76: 32
    ld a, [wSnd_EventArg]         ; 6a77: fa 9f c3
    ld e, a                       ; 6a7a: 5f
    ld a, [wSnd_EventArg+1]       ; 6a7b: fa a0 c3
    ld d, a                       ; 6a7e: 57
    push de                       ; 6a7f: d5
    ld a, $04                     ; 6a80: 3e 04    | instr +4 = transpose
    add e                         ; 6a82: 83
    ld e, a                       ; 6a83: 5f
    jr nc, .transpose             ; 6a84: 30 01
    inc d                         ; 6a86: 14

.transpose:
    ld hl, wSnd_TrackTranspose    ; 6a87: 21 96 c3
    add hl, bc                    ; 6a8a: 09
    ld a, [de]                    ; 6a8b: 1a
    ld [hl], a                    ; 6a8c: 77
    pop de                        ; 6a8d: d1
    ld a, $00                     ; 6a8e: 3e 00    | instr +0 = channel
    add e                         ; 6a90: 83
    ld e, a                       ; 6a91: 5f
    jr nc, .checkCh               ; 6a92: 30 01
    inc d                         ; 6a94: 14

.checkCh:
    ld a, [de]                    ; 6a95: 1a
    cp $02                        ; 6a96: fe 02    | wave channel? (BO tested the TRACK index)
    ret nz                        ; 6a98: c0

Snd_LoadWave:
    xor a                         ; 6a99: af
    ldh [rNR30], a                ; 6a9a: e0 1a    | wave off
    ld hl, Snd_WaveTable          ; 6a9c: 21 41 6c | Snd_WaveTable
    ld de, _AUD3WAVERAM           ; 6a9f: 11 30 ff

.copy:
    ld a, [hl+]                   ; 6aa2: 2a
    ld [de], a                    ; 6aa3: 12
    inc e                         ; 6aa4: 1c
    ld a, e                       ; 6aa5: 7b
    cp $40                        ; 6aa6: fe 40
    jr nz, .copy                  ; 6aa8: 20 f8
    ld a, $80                     ; 6aaa: 3e 80    | wave on
    ldh [rNR30], a                ; 6aac: e0 1a
    xor a                         ; 6aae: af       | NR34 = 0
    ldh [rNR34], a                ; 6aaf: e0 1e
    ret                           ; 6ab1: c9

; =============================================================================
; Snd_NoteOn  BC = track.  Same priority arbitration as Battle of Olympus.
;   instr: +0 channel  +1 duty (CH4: NR43)  +2 priority  +3 NR10  +4 transpose
;          (CH4: NR42 if non-zero)  +5 NRx2  (+6/+7 CH4 NR41 length)
; =============================================================================
Snd_NoteOn:
    push bc                       ; 6ab2: c5
    ld hl, wSnd_TrackInstr        ; 6ab3: 21 84 c3
    add hl, bc                    ; 6ab6: 09
    add hl, bc                    ; 6ab7: 09
    ld a, [hl+]                   ; 6ab8: 2a
    ld [wSnd_CurInstr], a         ; 6ab9: ea a9 c3
    ld h, [hl]                    ; 6abc: 66
    ld l, a                       ; 6abd: 6f
    ld a, h                       ; 6abe: 7c
    ld [wSnd_CurInstr+1], a       ; 6abf: ea aa c3
    push hl                       ; 6ac2: e5
    ld de, $0002                  ; 6ac3: 11 02 00 | instr +2 = priority
    add hl, de                    ; 6ac6: 19
    ld a, [hl]                    ; 6ac7: 7e
    pop hl                        ; 6ac8: e1
    push af                       ; 6ac9: f5
    ld de, $0000                  ; 6aca: 11 00 00 | instr +0 = channel
    add hl, de                    ; 6acd: 19
    ld a, [hl]                    ; 6ace: 7e
    ld d, $00                     ; 6acf: 16 00
    ld e, a                       ; 6ad1: 5f
    pop af                        ; 6ad2: f1
    ld hl, wSnd_ChanPriority      ; 6ad3: 21 3c c3
    add hl, de                    ; 6ad6: 19
    cp [hl]                       ; 6ad7: be       | priority >= owner's ?
    jr nc, .claim                 ; 6ad8: 30 02
    pop bc                        ; 6ada: c1       | no: note dropped
    ret                           ; 6adb: c9

.claim:
    ld [hl], a                    ; 6adc: 77       | take the channel
    ld hl, wSnd_TrackNoteParam    ; 6add: 21 72 c3
    add hl, bc                    ; 6ae0: 09
    add hl, bc                    ; 6ae1: 09
    ld a, [hl]                    ; 6ae2: 7e
    ld [wSnd_ParamCopy], a        ; 6ae3: ea b0 c3 | (copy never read)
    ld a, [hl]                    ; 6ae6: 7e
    ld hl, wSnd_ChanTimer         ; 6ae7: 21 40 c3 | hold timer = note param (frames) -> key-off when it expires
    add hl, de                    ; 6aea: 19
    ld [hl], a                    ; 6aeb: 77
    ld hl, wSnd_TrackEvent        ; 6aec: 21 69 c3 | raw note byte
    add hl, bc                    ; 6aef: 09
    ld a, [hl+]                   ; 6af0: 2a
    ld [wSnd_NoteByte], a         ; 6af1: ea a5 c3
    ld a, e                       ; 6af4: 7b
    cp $03                        ; 6af5: fe 03    | CH4: no frequency
    jr z, .dispatch               ; 6af7: 28 1b
    ld a, [wSnd_NoteByte]         ; 6af9: fa a5 c3
    and $7f                       ; 6afc: e6 7f
    ld hl, wSnd_TrackTranspose    ; 6afe: 21 96 c3
    add hl, bc                    ; 6b01: 09
    add [hl]                      ; 6b02: 86
    ld hl, Snd_FreqTable          ; 6b03: 21 55 6c | Snd_FreqTable
    add a                         ; 6b06: 87
    add l                         ; 6b07: 85
    ld l, a                       ; 6b08: 6f
    jr nc, .gotFreq               ; 6b09: 30 01
    inc h                         ; 6b0b: 24

.gotFreq:
    ld a, [hl+]                   ; 6b0c: 2a
    ld [wSnd_FreqLo], a           ; 6b0d: ea ac c3
    ld a, [hl-]                   ; 6b10: 3a
    ld [wSnd_FreqHi], a           ; 6b11: ea ad c3

.dispatch:
    ld hl, wSnd_CurInstr          ; 6b14: 21 a9 c3
    ld a, [hl+]                   ; 6b17: 2a
    ld h, [hl]                    ; 6b18: 66
    ld l, a                       ; 6b19: 6f
    ld a, [hl]                    ; 6b1a: 7e
    push hl                       ; 6b1b: e5
    or a                          ; 6b1c: b7
    jr z, .ch1                    ; 6b1d: 28 10
    dec a                         ; 6b1f: 3d
    jr z, .ch2                    ; 6b20: 28 3a
    dec a                         ; 6b22: 3d
    jp z, .ch3                    ; 6b23: ca 80 6b
    dec a                         ; 6b26: 3d
    jp z, .ch4                    ; 6b27: ca 9d 6b
    pop bc                        ; 6b2a: c1
    pop bc                        ; 6b2b: c1
    jp Snd_BadCommand             ; 6b2c: c3 1e 6c

.ch1:
    ld bc, $0001                  ; 6b2f: 01 01 00 | NR11 = instr +1 | $3F (length 63, for the later key-off)
    add hl, bc                    ; 6b32: 09
    ld a, [hl]                    ; 6b33: 7e
    or $3f                        ; 6b34: f6 3f
    ldh [rNR11], a                ; 6b36: e0 11
    pop hl                        ; 6b38: e1
    push hl                       ; 6b39: e5
    ld bc, $0003                  ; 6b3a: 01 03 00 | NR10 = instr +3
    add hl, bc                    ; 6b3d: 09
    ld a, [hl]                    ; 6b3e: 7e
    ldh [rNR10], a                ; 6b3f: e0 10
    pop hl                        ; 6b41: e1
    push hl                       ; 6b42: e5
    ld bc, $0005                  ; 6b43: 01 05 00 | NR12 = instr +5 (no param bits, unlike BO)
    add hl, bc                    ; 6b46: 09
    ld a, [hl]                    ; 6b47: 7e
    ldh [rNR12], a                ; 6b48: e0 12
    ld a, [wSnd_FreqLo]           ; 6b4a: fa ac c3
    ldh [rNR13], a                ; 6b4d: e0 13
    ld a, [wSnd_FreqHi]           ; 6b4f: fa ad c3 | keep freq hi for key-off
    ld [wSnd_Ch1FreqHi], a        ; 6b52: ea a6 c3
    set 7, a                      ; 6b55: cb ff    | trigger
    ldh [rNR14], a                ; 6b57: e0 14
    jp .done                      ; 6b59: c3 d3 6b

.ch2:
    ld bc, $0001                  ; 6b5c: 01 01 00 | NR21 = instr +1 | $3F
    add hl, bc                    ; 6b5f: 09
    ld a, [hl]                    ; 6b60: 7e
    or $3f                        ; 6b61: f6 3f
    ldh [rNR21], a                ; 6b63: e0 16
    pop hl                        ; 6b65: e1
    push hl                       ; 6b66: e5
    ld bc, $0005                  ; 6b67: 01 05 00 | NR22 = instr +5
    add hl, bc                    ; 6b6a: 09
    ld a, [hl]                    ; 6b6b: 7e
    ldh [rNR22], a                ; 6b6c: e0 17
    ld a, [wSnd_FreqLo]           ; 6b6e: fa ac c3
    ldh [rNR23], a                ; 6b71: e0 18
    ld a, [wSnd_FreqHi]           ; 6b73: fa ad c3 | keep freq hi
    ld [wSnd_Ch2FreqHi], a        ; 6b76: ea a7 c3
    set 7, a                      ; 6b79: cb ff
    ldh [rNR24], a                ; 6b7b: e0 19
    jp .done                      ; 6b7d: c3 d3 6b

.ch3:
    call Snd_LoadWave             ; 6b80: cd 99 6a | CH3 is live: reload wave on every note
    ld a, [wSnd_FreqLo]           ; 6b83: fa ac c3
    ldh [rNR33], a                ; 6b86: e0 1d
    ld a, [wSnd_FreqHi]           ; 6b88: fa ad c3
    res 7, a                      ; 6b8b: cb bf    | freq hi, no trigger
    ldh [rNR34], a                ; 6b8d: e0 1e
    ld [wSnd_Ch3FreqHi], a        ; 6b8f: ea a8 c3
    set 7, a                      ; 6b92: cb ff    | then trigger
    ldh [rNR34], a                ; 6b94: e0 1e
    ld a, $20                     ; 6b96: 3e 20    | NR32 = 100%
    ldh [rNR32], a                ; 6b98: e0 1c
    jp .done                      ; 6b9a: c3 d3 6b

.ch4:
    inc hl                        ; 6b9d: 23       | CH4: NR43 = instr +1
    ld a, [hl]                    ; 6b9e: 7e
    ldh [rNR43], a                ; 6b9f: e0 22
    pop hl                        ; 6ba1: e1
    push hl                       ; 6ba2: e5
    ld bc, $0004                  ; 6ba3: 01 04 00 | NR42 = instr +4 if non-zero ...
    add hl, bc                    ; 6ba6: 09
    ld a, [hl]                    ; 6ba7: 7e
    cp $00                        ; 6ba8: fe 00
    jp z, .ch4vol5                ; 6baa: ca b2 6b
    ldh [rNR42], a                ; 6bad: e0 21
    jp .ch4len                    ; 6baf: c3 bb 6b

.ch4vol5:
    pop hl                        ; 6bb2: e1
    push hl                       ; 6bb3: e5
    ld bc, $0005                  ; 6bb4: 01 05 00 | ... else instr +5
    add hl, bc                    ; 6bb7: 09
    ld a, [hl]                    ; 6bb8: 7e
    ldh [rNR42], a                ; 6bb9: e0 21

.ch4len:
    inc hl                        ; 6bbb: 23       | NR41 = instr +6 or +7 (depends on the branch above)
    inc hl                        ; 6bbc: 23
    ld a, [hl]                    ; 6bbd: 7e
    ldh [rNR41], a                ; 6bbe: e0 20
    cp $00                        ; 6bc0: fe 00
    jp z, .ch4nolen               ; 6bc2: ca cc 6b
    ld a, $c0                     ; 6bc5: 3e c0    | length enabled + trigger
    ldh [rNR44], a                ; 6bc7: e0 23
    jp .done                      ; 6bc9: c3 d3 6b

.ch4nolen:
    ld a, $80                     ; 6bcc: 3e 80    | trigger
    ldh [rNR44], a                ; 6bce: e0 23
    jp .done                      ; 6bd0: c3 d3 6b

.done:
    pop bc                        ; 6bd3: c1
    pop bc                        ; 6bd4: c1
    ret                           ; 6bd5: c9

; Snd_TickChanTimer: C = channel.  NEW vs BO: expiry sends a key-off
Snd_TickChanTimer:
    ld hl, wSnd_ChanTimer         ; 6bd6: 21 40 c3 | channel hold timer
    add hl, bc                    ; 6bd9: 09
    ld a, [hl]                    ; 6bda: 7e
    or a                          ; 6bdb: b7
    jr z, .ret                    ; 6bdc: 28 38
    dec [hl]                      ; 6bde: 35       | expired?
    jr nz, .ret                   ; 6bdf: 20 35
    ld hl, wSnd_ChanPriority      ; 6be1: 21 3c c3 | free the channel
    add hl, bc                    ; 6be4: 09
    xor a                         ; 6be5: af
    ld [hl], a                    ; 6be6: 77
    ld a, c                       ; 6be7: 79       | and key it off:
    or a                          ; 6be8: b7
    jr z, .off1                   ; 6be9: 28 0d
    dec a                         ; 6beb: 3d
    jr z, .off2                   ; 6bec: 28 13
    dec a                         ; 6bee: 3d
    jr z, .off3                   ; 6bef: 28 19
    dec a                         ; 6bf1: 3d
    jr z, .off4                   ; 6bf2: 28 1e
    pop bc                        ; 6bf4: c1
    jp Snd_BadCommand             ; 6bf5: c3 1e 6c

.off1:
    ld a, [wSnd_Ch1FreqHi]        ; 6bf8: fa a6 c3 | CH1: set length-enable (NR11 length 63 runs out)
    set 6, a                      ; 6bfb: cb f7
    ldh [rNR14], a                ; 6bfd: e0 14
    jr .ret                       ; 6bff: 18 15

.off2:
    ld a, [wSnd_Ch2FreqHi]        ; 6c01: fa a7 c3 | CH2: same
    set 6, a                      ; 6c04: cb f7
    ldh [rNR24], a                ; 6c06: e0 19
    jr .ret                       ; 6c08: 18 0c

.off3:
    ld a, $ff                     ; 6c0a: 3e ff    | CH3: park at an inaudible pitch
    ldh [rNR33], a                ; 6c0c: e0 1d
    ld a, $07                     ; 6c0e: 3e 07
    ldh [rNR34], a                ; 6c10: e0 1e

.off4:
    ld a, $00                     ; 6c12: 3e 00    | CH4: NR42 = 0
    ldh [rNR42], a                ; 6c14: e0 21

.ret:
    ret                           ; 6c16: c9

; Snd_SetTempo (DD) - vestigial
Snd_SetTempo:
    ld a, [wSnd_EventArg]         ; 6c17: fa 9f c3 | store tempo - unused
    ld [wSnd_Tempo], a            ; 6c1a: ea a3 c3
    ret                           ; 6c1d: c9

; Snd_BadCommand
Snd_BadCommand:
    ld a, [wSnd_SongHeader]       ; 6c1e: fa 2c c3 | restart song from header
    ld l, a                       ; 6c21: 6f
    ld a, [wSnd_SongHeader+1]     ; 6c22: fa 2d c3
    ld h, a                       ; 6c25: 67
    push hl                       ; 6c26: e5
    call Snd_APUOff               ; 6c27: cd cf 68 | APU off
    pop hl                        ; 6c2a: e1
    jp Snd_StartSong              ; 6c2b: c3 20 68

; Snd_ReadVarLen - the rrca bug from BO/TG is FIXED here:
;   $80-$FF lead byte -> ((b & $7F) << 7) + b2, a real 15-bit length
Snd_ReadVarLen:
    ld d, $00                     ; 6c2e: 16 00    | result DE (15-bit now)
    ld a, [hl+]                   ; 6c30: 2a
    bit 7, a                      ; 6c31: cb 7f
    jr z, .done                   ; 6c33: 28 0a
    and $7f                       ; 6c35: e6 7f    | two-byte form:
    srl a                         ; 6c37: cb 3f    | D = (b & $7F) >> 1
    ld d, a                       ; 6c39: 57
    ld a, $00                     ; 6c3a: 3e 00    | carry (b bit 0) -> bit 7 ...
    rra                           ; 6c3c: 1f
    add [hl]                      ; 6c3d: 86       | ... + b2 = E
    inc hl                        ; 6c3e: 23

.done:
    ld e, a                       ; 6c3f: 5f
    ret                           ; 6c40: c9

; Wave pattern - byte-identical to Battle of Olympus $2717
Snd_WaveTable:
    db $00, $00, $00, $00, $00, $08, $ff, $ff ; 6c41
    db $ff, $ff, $ff, $ff, $ff, $ff, $a5, $00 ; 6c49

; (unreferenced) NR32 levels - same 4 bytes as the other three games
Snd_WaveVolTable:
    db $00, $60, $40, $20         ; 6c51

; Frequency table - byte-identical to NASCAR / Top Gun / Battle of Olympus
Snd_FreqTable:
    dw $002c                      ; 6c55 | n=  0 C  2  65.4 Hz
    dw $009d                      ; 6c57 | n=  1 C# 2  69.3 Hz
    dw $0108                      ; 6c59 | n=  2 D  2  73.5 Hz
    dw $016d                      ; 6c5b | n=  3 D# 2  77.9 Hz
    dw $01cc                      ; 6c5d | n=  4 E  2  82.5 Hz
    dw $0225                      ; 6c5f | n=  5 F  2  87.4 Hz
    dw $027a                      ; 6c61 | n=  6 F# 2  92.7 Hz
    dw $02ca                      ; 6c63 | n=  7 G  2  98.3 Hz
    dw $0315                      ; 6c65 | n=  8 G# 2  104.1 Hz
    dw $035c                      ; 6c67 | n=  9 A  2  110.3 Hz
    dw $039f                      ; 6c69 | n= 10 A# 2  116.9 Hz
    dw $03de                      ; 6c6b | n= 11 B  2  123.9 Hz
    dw $041a                      ; 6c6d | n= 12 C  3  131.3 Hz
    dw $0452                      ; 6c6f | n= 13 C# 3  139.1 Hz
    dw $0487                      ; 6c71 | n= 14 D  3  147.4 Hz
    dw $04b9                      ; 6c73 | n= 15 D# 3  156.2 Hz
    dw $04e9                      ; 6c75 | n= 16 E  3  165.7 Hz
    dw $0515                      ; 6c77 | n= 17 F  3  175.5 Hz
    dw $053f                      ; 6c79 | n= 18 F# 3  185.9 Hz
    dw $0567                      ; 6c7b | n= 19 G  3  197.1 Hz
    dw $058d                      ; 6c7d | n= 20 G# 3  209.0 Hz
    dw $05b0                      ; 6c7f | n= 21 A  3  221.4 Hz
    dw $05d1                      ; 6c81 | n= 22 A# 3  234.5 Hz
    dw $05f1                      ; 6c83 | n= 23 B  3  248.7 Hz
    dw $060f                      ; 6c85 | n= 24 C  4  263.7 Hz
    dw $062b                      ; 6c87 | n= 25 C# 4  279.5 Hz
    dw $0645                      ; 6c89 | n= 26 D  4  295.9 Hz
    dw $065e                      ; 6c8b | n= 27 D# 4  313.6 Hz
    dw $0676                      ; 6c8d | n= 28 E  4  332.7 Hz
    dw $068c                      ; 6c8f | n= 29 F  4  352.3 Hz
    dw $06a1                      ; 6c91 | n= 30 F# 4  373.4 Hz
    dw $06b5                      ; 6c93 | n= 31 G  4  396.0 Hz
    dw $06c7                      ; 6c95 | n= 32 G# 4  418.8 Hz
    dw $06d9                      ; 6c97 | n= 33 A  4  444.3 Hz
    dw $06ea                      ; 6c99 | n= 34 A# 4  471.5 Hz
    dw $06f9                      ; 6c9b | n= 35 B  4  498.4 Hz
    dw $0708                      ; 6c9d | n= 36 C  5  528.5 Hz
    dw $0716                      ; 6c9f | n= 37 C# 5  560.1 Hz
    dw $0723                      ; 6ca1 | n= 38 D  5  593.1 Hz
    dw $0730                      ; 6ca3 | n= 39 D# 5  630.2 Hz
    dw $073c                      ; 6ca5 | n= 40 E  5  668.7 Hz
    dw $0747                      ; 6ca7 | n= 41 F  5  708.5 Hz
    dw $0751                      ; 6ca9 | n= 42 F# 5  749.0 Hz
    dw $075b                      ; 6cab | n= 43 G  5  794.4 Hz
    dw $0764                      ; 6cad | n= 44 G# 5  840.2 Hz
    dw $076d                      ; 6caf | n= 45 A  5  891.6 Hz
    dw $0775                      ; 6cb1 | n= 46 A# 5  943.0 Hz
    dw $077d                      ; 6cb3 | n= 47 B  5  1000.5 Hz
    dw $0785                      ; 6cb5 | n= 48 C  6  1065.6 Hz
    dw $078c                      ; 6cb7 | n= 49 C# 6  1129.9 Hz
    dw $0792                      ; 6cb9 | n= 50 D  6  1191.6 Hz
    dw $0798                      ; 6cbb | n= 51 D# 6  1260.3 Hz
    dw $079e                      ; 6cbd | n= 52 E  6  1337.5 Hz
    dw $07a4                      ; 6cbf | n= 53 F  6  1424.7 Hz
    dw $07a9                      ; 6cc1 | n= 54 F# 6  1506.6 Hz
    dw $07ae                      ; 6cc3 | n= 55 G  6  1598.4 Hz
    dw $07b2                      ; 6cc5 | n= 56 G# 6  1680.4 Hz
    dw $07b7                      ; 6cc7 | n= 57 A  6  1795.5 Hz
    dw $07bb                      ; 6cc9 | n= 58 A# 6  1899.6 Hz
    dw $07bf                      ; 6ccb | n= 59 B  6  2016.5 Hz
    dw $07c3                      ; 6ccd | n= 60 C  7  2148.7 Hz
    dw $07c6                      ; 6ccf | n= 61 C# 7  2259.9 Hz
    dw $07c9                      ; 6cd1 | n= 62 D  7  2383.1 Hz
    dw $07cc                      ; 6cd3 | n= 63 D# 7  2520.6 Hz
    dw $07cf                      ; 6cd5 | n= 64 E  7  2674.9 Hz
    dw $07d2                      ; 6cd7 | n= 65 F  7  2849.4 Hz
    dw $07d5                      ; 6cd9 | n= 66 F# 7  3048.2 Hz
    dw $07d7                      ; 6cdb | n= 67 G  7  3196.9 Hz
    dw $07d9                      ; 6cdd | n= 68 G# 7  3360.8 Hz
    dw $07dc                      ; 6cdf | n= 69 A  7  3640.9 Hz
    dw $07de                      ; 6ce1 | n= 70 A# 7  3855.1 Hz
    dw $07e0                      ; 6ce3 | n= 71 B  7  4096.0 Hz
    dw $07e1                      ; 6ce5 | n= 72 C  8  4228.1 Hz
    dw $07e3                      ; 6ce7 | n= 73 C# 8  4519.7 Hz
    dw $07e5                      ; 6ce9 | n= 74 D  8  4854.5 Hz
    dw $07e6                      ; 6ceb | n= 75 D# 8  5041.2 Hz
    dw $07e8                      ; 6ced | n= 76 E  8  5461.3 Hz
    dw $07e9                      ; 6cef | n= 77 F  8  5698.8 Hz
    dw $07ea                      ; 6cf1 | n= 78 F# 8  5957.8 Hz
    dw $07ec                      ; 6cf3 | n= 79 G  8  6553.6 Hz
    dw $07ed                      ; 6cf5 | n= 80 G# 8  6898.5 Hz
    dw $07ee                      ; 6cf7 | n= 81 A  8  7281.8 Hz
    dw $07ef                      ; 6cf9 | n= 82 A# 8  7710.1 Hz
    dw $07f0                      ; 6cfb | n= 83 B  8  8192.0 Hz
    dw $07f1                      ; 6cfd | n= 84 C  9  8738.1 Hz
    dw $07f2                      ; 6cff | n= 85 C# 9  9362.3 Hz
    dw $07f2                      ; 6d01 | n= 86 D  9  9362.3 Hz
    dw $07f3                      ; 6d03 | n= 87 D# 9  10082.5 Hz
    dw $07f4                      ; 6d05 | n= 88 E  9  10922.7 Hz
    dw $07f5                      ; 6d07 | n= 89 F  9  11915.6 Hz
    dw $07f5                      ; 6d09 | n= 90 F# 9  11915.6 Hz
    dw $07f6                      ; 6d0b | n= 91 G  9  13107.2 Hz
    dw $07f6                      ; 6d0d | n= 92 G# 9  13107.2 Hz
    dw $07f7                      ; 6d0f | n= 93 A  9  14563.6 Hz
    dw $07f7                      ; 6d11 | n= 94 A# 9  14563.6 Hz
    dw $07f8                      ; 6d13 | n= 95 B  9  16384.0 Hz
    dw $07f8                      ; 6d15 | n= 96 C  10  16384.0 Hz
    dw $07f9                      ; 6d17 | n= 97 C# 10  18724.6 Hz
    dw $07f9                      ; 6d19 | n= 98 D  10  18724.6 Hz
    dw $07fa                      ; 6d1b | n= 99 D# 10  21845.3 Hz
    dw $07fa                      ; 6d1d | n=100 E  10  21845.3 Hz
    dw $07fa                      ; 6d1f | n=101 F  10  21845.3 Hz
    dw $07fb                      ; 6d21 | n=102 F# 10  26214.4 Hz
    dw $07fb                      ; 6d23 | n=103 G  10  26214.4 Hz
    dw $07fb                      ; 6d25 | n=104 G# 10  26214.4 Hz
    dw $07fb                      ; 6d27 | n=105 A  10  26214.4 Hz
    dw $07fc                      ; 6d29 | n=106 A# 10  32768.0 Hz
    dw $07fc                      ; 6d2b | n=107 B  10  32768.0 Hz
    dw $07fc                      ; 6d2d | n=108 C  11  32768.0 Hz
    dw $07fc                      ; 6d2f | n=109 C# 11  32768.0 Hz
    dw $07fd                      ; 6d31 | n=110 D  11  43690.7 Hz
    dw $07fd                      ; 6d33 | n=111 D# 11  43690.7 Hz
    dw $07fd                      ; 6d35 | n=112 E  11  43690.7 Hz
    dw $07fd                      ; 6d37 | n=113 F  11  43690.7 Hz
    dw $07fd                      ; 6d39 | n=114 F# 11  43690.7 Hz
    dw $07fd                      ; 6d3b | n=115 G  11  43690.7 Hz
    dw $07fe                      ; 6d3d | n=116 G# 11  65536.0 Hz
    dw $07fe                      ; 6d3f | n=117 A  11  65536.0 Hz
