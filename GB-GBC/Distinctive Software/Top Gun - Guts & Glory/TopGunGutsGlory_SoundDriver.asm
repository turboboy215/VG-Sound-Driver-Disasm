; =============================================================================
;  Top Gun: Guts & Glory (Game Boy, 1993)  -  SOUND DRIVER DISASSEMBLY
;  ROM: "Top Gun - Guts & Glory (U) [!].gb"  header title TOPGUN 2, lic $A4
;  Developer: Distinctive Software   Publisher: Konami
;
;  Driver code  : ROM0 $259E-$2992  (tables to $2AE6)
;  Music        : ROM bank $06  (wSnd_Bank set to $06 at $2C3A)
;  Update hook  : VBlank handler calls Snd_Update at $0B6D
;  In-game SFX  : NOT handled by this driver - gameplay code in bank 1
;                 writes the sound registers directly.
;
;  Re-assembles byte-exact with RGBDS (verified).  Each line carries the ROM
;  address and original bytes after the ';'.  Everything after '|' is a note.
; -----------------------------------------------------------------------------
;  ARCHITECTURE
;   * Up to 9 tracks (count from the song header), one hardware channel per
;     track chosen by its instrument.  No priorities, no SFX slots.
;   * Instruments come from a pointer table passed in DE at song start;
;     command DC takes a 1-byte index into it.
;   * Software ADSR envelope (Snd_EnvelopeTick) driven by the note gate -
;     but its output routine is stubbed with RET, so NRx2 stays at $F8.
;   * CH3 (wave) is fully playable here (disabled in BO).
;   * CH4 drums: raw note byte picks NR43 and swaps in a drum instrument.
;     Observation: the music path never writes NR44 (the only NR44 write
;     is inside the dead Snd_EnvWriteVolume body).
;
;  SONG HEADER (bank $06)   db nTracks / dw track[0..n-1]
;    followed directly by the instrument pointer table passed in DE
;    (e.g. header $4000, table $4013) and 14-byte instrument records.
;
;  TRACK STREAM  =  repeated  [delta][event][args]   - SAME FORMAT AS BO
;    event   : $00-$D8  note (bit7 = extra byte follows, ignored),
;                       then var-length GATE (frames until release)
;              $D9       stop all          (BO: restart song)
;              $DA       stop all
;              $DB       restart song
;              $DC b     instrument = InstrTable[b]   (BO: 16-bit pointer)
;              $DD b     tempo (stored, never read)
;              $DE b, $E2 b     ignored
;              $DF x y   ignored (each TG track starts with DF events)
;              $E3       parsed, ignored   (BO: loop track)
;              other     treated as 2-byte event, ignored (BO: restart song)
;
;  INSTRUMENT (14 bytes)  +0 channel 0-3  +1 duty* +2 (0)* +3 sweep*
;                         +4 transpose    +5..+8 unused
;                         +9 attack step  +A attack peak  +B decay/release step
;                         +C sustain level  +D unused      (* = ignored here)
;    Bytes +0..+4 have the same meaning and values as BO's 6-byte records.
; =============================================================================

INCLUDE "hardware.inc"

; ---- RAM used by the sound driver ----
DEF wSnd_Bank EQU $de32
DEF wSnd_Enabled EQU $de33
DEF wSnd_SongHeader EQU $de35
DEF wSnd_SongDE EQU $de37
DEF wSnd_EnvLevel EQU $de39
DEF wSnd_EnvPhase EQU $de3d
DEF wSnd_ChanActive EQU $de41
DEF wSnd_EnvInstr EQU $de45
DEF wSnd_NumTracks EQU $de47
DEF wSnd_TrackPtr EQU $de48
DEF wSnd_TrackWait EQU $de5a
DEF wSnd_TrackEvent EQU $de6c
DEF wSnd_TrackGate EQU $de75
DEF wSnd_TrackInstr EQU $de87
DEF wSnd_TrackTranspose EQU $de99
DEF wSnd_EventArg EQU $dea2
DEF wSnd_InstrTable EQU $dea3
DEF wSnd_Tempo EQU $dea5
DEF wSnd_Unused_A6 EQU $dea6
DEF wSnd_NoteByte EQU $dea7

; ---- outside the driver ----
DEF WaitNextFrame EQU $0ca0
DEF MBC_ROMB EQU $2100
DEF wFrameCounter EQU $de00
DEF wROMBank EQU $de21
DEF wROMBankIRQ EQU $de2a

SECTION "TG Sound Driver", ROM0[$259e]



; =============================================================================
; Snd_PlaySong  (called 4x from bank 2, and by command DB)
;   in:  HL = song header (bank wSnd_Bank = $06)
;        DE = instrument pointer table (dw instr0, instr1, ...)
; =============================================================================
Snd_PlaySong:
    push de                       ; 259e: d5       | (also the target of command DB)
    push hl                       ; 259f: e5
    call Snd_StartSong            ; 25a0: cd a8 25 | set song up...
    call WaitNextFrame            ; 25a3: cd a0 0c | ...wait one frame...
    pop hl                        ; 25a6: e1       | ...and fall through to set it up again
    pop de                        ; 25a7: d1

; Snd_StartSong  HL = header (db nTracks / dw track[0..n-1]), DE = instr table
Snd_StartSong:
    di                            ; 25a8: f3
    ld a, [wSnd_Bank]             ; 25a9: fa 32 de | map in sound bank ($06)
    ld [wROMBankIRQ], a           ; 25ac: ea 2a de
    ld [MBC_ROMB], a              ; 25af: ea 00 21
    push hl                       ; 25b2: e5
    push de                       ; 25b3: d5
    call Snd_Reset                ; 25b4: cd 20 26 | stop everything first (also APU off)
    pop de                        ; 25b7: d1
    pop hl                        ; 25b8: e1
    ld a, l                       ; 25b9: 7d       | remember header (for DB restart)
    ld [wSnd_SongHeader], a       ; 25ba: ea 35 de
    ld a, h                       ; 25bd: 7c
    ld [wSnd_SongHeader+1], a     ; 25be: ea 36 de
    ld a, e                       ; 25c1: 7b       | remember DE = instrument pointer table
    ld [wSnd_SongDE], a           ; 25c2: ea 37 de
    ld [wSnd_InstrTable], a       ; 25c5: ea a3 de | DE -> instrument table used by command DC
    ld a, d                       ; 25c8: 7a
    ld [wSnd_SongDE+1], a         ; 25c9: ea 38 de
    ld [wSnd_InstrTable+1], a     ; 25cc: ea a4 de
    ld a, [hl+]                   ; 25cf: 2a       | header byte 0 = number of tracks
    ld [wSnd_NumTracks], a        ; 25d0: ea 47 de
    ld b, a                       ; 25d3: 47
    ld de, wSnd_TrackPtr          ; 25d4: 11 48 de | copy N track start pointers

.copyPtrs:
    ld a, [hl+]                   ; 25d7: 2a
    ld [de], a                    ; 25d8: 12
    inc de                        ; 25d9: 13
    ld a, [hl+]                   ; 25da: 2a
    ld [de], a                    ; 25db: 12
    inc de                        ; 25dc: 13
    dec b                         ; 25dd: 05
    jr nz, .copyPtrs              ; 25de: 20 f7
    ld a, [wSnd_NumTracks]        ; 25e0: fa 47 de
    ld b, a                       ; 25e3: 47
    xor a                         ; 25e4: af
    ld hl, wSnd_TrackWait         ; 25e5: 21 5a de | zero N wait counters

.clrWait:
    ld [hl+], a                   ; 25e8: 22
    ld [hl+], a                   ; 25e9: 22
    dec b                         ; 25ea: 05
    jr nz, .clrWait               ; 25eb: 20 fb
    ld a, [wSnd_NumTracks]        ; 25ed: fa 47 de
    ld b, a                       ; 25f0: 47
    xor a                         ; 25f1: af
    ld hl, wSnd_TrackGate         ; 25f2: 21 75 de | zero N gates

.clrGate:
    ld [hl+], a                   ; 25f5: 22
    ld [hl+], a                   ; 25f6: 22
    dec b                         ; 25f7: 05
    jr nz, .clrGate               ; 25f8: 20 fb
    ld a, $60                     ; 25fa: 3e 60    | "tempo" = $60 (never read)
    ld [wSnd_Tempo], a            ; 25fc: ea a5 de
    ld a, $ff                     ; 25ff: 3e ff    | APU on
    ldh [rNR52], a                ; 2601: e0 26
    ld a, $77                     ; 2603: 3e 77    | master volume L=7 R=7
    ldh [rNR50], a                ; 2605: e0 24
    ld a, $ff                     ; 2607: 3e ff    | all channels to both speakers
    ldh [rNR51], a                ; 2609: e0 25
    ld a, $01                     ; 260b: 3e 01    | driver enabled
    ld [wSnd_Enabled], a          ; 260d: ea 33 de
    ld a, [wROMBank]              ; 2610: fa 21 de | restore main bank
    ld [wROMBankIRQ], a           ; 2613: ea 2a de
    ld [MBC_ROMB], a              ; 2616: ea 00 21
    ei                            ; 2619: fb       | NB: re-enables interrupts even when reached from the VBlank ISR (command DB)
    ret                           ; 261a: c9

; unreferenced
Snd_Disable:
    xor a                         ; 261b: af       | (unreferenced) clear enabled flag
    ld [wSnd_Enabled], a          ; 261c: ea 33 de
    ret                           ; 261f: c9

; Snd_Reset: driver off, APU off, envelopes cleared (commands D9/DA)
Snd_Reset:
    xor a                         ; 2620: af
    ld [wSnd_Enabled], a          ; 2621: ea 33 de
    ld [wSnd_Unused_A6], a        ; 2624: ea a6 de
    ldh [rNR52], a                ; 2627: e0 26    | NR52 = 0 (BO does this in a separate helper)
    ld bc, $0003                  ; 2629: 01 03 00 | channels 3..0

.clrChan:
    call Snd_ClearChannel         ; 262c: cd 42 28 | stub: returns immediately
    dec c                         ; 262f: 0d
    ld a, c                       ; 2630: 79
    inc a                         ; 2631: 3c
    jr nz, .clrChan               ; 2632: 20 f8
    xor a                         ; 2634: af
    ld b, $04                     ; 2635: 06 04
    ld hl, wSnd_EnvLevel          ; 2637: 21 39 de | envelope level = 0 x4

.clrLevel:
    ld [hl+], a                   ; 263a: 22
    dec b                         ; 263b: 05
    jr nz, .clrLevel              ; 263c: 20 fc
    ld b, $04                     ; 263e: 06 04
    ld hl, wSnd_EnvPhase          ; 2640: 21 3d de | envelope phase = 0 x4

.clrPhase:
    ld [hl+], a                   ; 2643: 22
    dec b                         ; 2644: 05
    jr nz, .clrPhase              ; 2645: 20 fc
    ret                           ; 2647: c9

; =============================================================================
; Snd_Update - called every frame from the VBlank handler ($0B6D)
; =============================================================================
Snd_Update:
    ld a, [wSnd_Enabled]          ; 2648: fa 33 de | driver running?
    or a                          ; 264b: b7
    ret z                         ; 264c: c8
    ld a, [wSnd_Bank]             ; 264d: fa 32 de | map sound bank (caller restores from wROMBankIRQ)
    ld [MBC_ROMB], a              ; 2650: ea 00 21
    call Snd_EnvelopeTick         ; 2653: cd 59 26
    jp Snd_UpdateTracks           ; 2656: c3 55 27 | then advance the tracks

; =============================================================================
; Snd_EnvelopeTick - software ADSR, one level per HARDWARE channel, but it is
; ticked once per TRACK that uses the channel.
;  phase 0 off / 1 attack / 3 decay / 2 sustain / 4 release
; =============================================================================
Snd_EnvelopeTick:
    ld a, [wSnd_NumTracks]        ; 2659: fa 47 de | for track = n-1 .. 0
    dec a                         ; 265c: 3d
    ld c, a                       ; 265d: 4f
    ld b, $00                     ; 265e: 06 00

.trackLoop:
    push bc                       ; 2660: c5
    ld hl, wSnd_TrackInstr        ; 2661: 21 87 de | instrument of this track
    add hl, bc                    ; 2664: 09
    add hl, bc                    ; 2665: 09
    ld a, [hl+]                   ; 2666: 2a
    ld [wSnd_EnvInstr], a         ; 2667: ea 45 de
    ld a, [hl-]                   ; 266a: 3a
    ld [wSnd_EnvInstr+1], a       ; 266b: ea 46 de
    ld a, [hl+]                   ; 266e: 2a
    ld h, [hl]                    ; 266f: 66
    ld l, a                       ; 2670: 6f
    ld c, [hl]                    ; 2671: 4e       | instr +0 = hardware channel
    ld b, $00                     ; 2672: 06 00
    ld hl, wSnd_ChanActive        ; 2674: 21 41 de | channel keyed?
    add hl, bc                    ; 2677: 09
    ld a, [hl]                    ; 2678: 7e
    or a                          ; 2679: b7
    jp z, .next                   ; 267a: ca 12 27
    ld hl, wSnd_EnvPhase          ; 267d: 21 3d de | envelope phase of that channel
    add hl, bc                    ; 2680: 09
    ld a, [hl]                    ; 2681: 7e
    cp $01                        ; 2682: fe 01    | 1 = ATTACK
    jr nz, .notAttack             ; 2684: 20 26
    ld hl, wSnd_EnvInstr          ; 2686: 21 45 de | instr +$0A = attack peak, +$09 = attack step
    ld a, [hl+]                   ; 2689: 2a
    ld h, [hl]                    ; 268a: 66
    ld l, a                       ; 268b: 6f
    ld a, $0a                     ; 268c: 3e 0a
    add l                         ; 268e: 85
    ld l, a                       ; 268f: 6f
    jr nc, .atkCmp                ; 2690: 30 01
    inc h                         ; 2692: 24

.atkCmp:
    ld a, [hl-]                   ; 2693: 3a
    ld d, [hl]                    ; 2694: 56
    ld hl, wSnd_EnvLevel          ; 2695: 21 39 de
    add hl, bc                    ; 2698: 09
    cp [hl]                       ; 2699: be       | peak > level ?
    jr z, .atkDone                ; 269a: 28 07
    jr c, .atkDone                ; 269c: 38 05
    ld a, [hl]                    ; 269e: 7e       | level += step
    add d                         ; 269f: 82
    ld [hl], a                    ; 26a0: 77
    jr .gate                      ; 26a1: 18 53

.atkDone:
    ld hl, wSnd_EnvPhase          ; 26a3: 21 3d de
    add hl, bc                    ; 26a6: 09
    ld a, $03                     ; 26a7: 3e 03    | -> phase 3 (DECAY)
    ld [hl], a                    ; 26a9: 77
    jr .gate                      ; 26aa: 18 4a

.notAttack:
    cp $03                        ; 26ac: fe 03    | 3 = DECAY
    jr nz, .notDecay              ; 26ae: 20 26
    ld hl, wSnd_EnvInstr          ; 26b0: 21 45 de | instr +$0C = sustain level, +$0B = decay step
    ld a, [hl+]                   ; 26b3: 2a
    ld h, [hl]                    ; 26b4: 66
    ld l, a                       ; 26b5: 6f
    ld a, $0c                     ; 26b6: 3e 0c
    add l                         ; 26b8: 85
    ld l, a                       ; 26b9: 6f
    jr nc, .decCmp                ; 26ba: 30 01
    inc h                         ; 26bc: 24

.decCmp:
    ld a, [hl-]                   ; 26bd: 3a
    ld d, [hl]                    ; 26be: 56
    ld hl, wSnd_EnvLevel          ; 26bf: 21 39 de
    add hl, bc                    ; 26c2: 09
    cp [hl]                       ; 26c3: be       | sustain < level ?
    jr z, .decDone                ; 26c4: 28 07
    jr nc, .decDone               ; 26c6: 30 05
    ld a, [hl]                    ; 26c8: 7e       | level -= step
    sub d                         ; 26c9: 92
    ld [hl], a                    ; 26ca: 77
    jr .gate                      ; 26cb: 18 29

.decDone:
    ld hl, wSnd_EnvPhase          ; 26cd: 21 3d de
    add hl, bc                    ; 26d0: 09
    ld a, $02                     ; 26d1: 3e 02    | -> phase 2 (SUSTAIN)
    ld [hl], a                    ; 26d3: 77
    jr .gate                      ; 26d4: 18 20

.notDecay:
    cp $04                        ; 26d6: fe 04    | 4 = RELEASE
    jr nz, .gate                  ; 26d8: 20 1c
    ld hl, wSnd_EnvInstr          ; 26da: 21 45 de | instr +$0B = release step
    ld a, [hl+]                   ; 26dd: 2a
    ld h, [hl]                    ; 26de: 66
    ld l, a                       ; 26df: 6f
    ld a, $0b                     ; 26e0: 3e 0b
    add l                         ; 26e2: 85
    ld l, a                       ; 26e3: 6f
    jr nc, .release               ; 26e4: 30 01
    inc h                         ; 26e6: 24

.release:
    ld d, [hl]                    ; 26e7: 56
    ld hl, wSnd_EnvLevel          ; 26e8: 21 39 de
    add hl, bc                    ; 26eb: 09
    ld a, [hl]                    ; 26ec: 7e       | level -= step
    sub d                         ; 26ed: 92
    ld [hl], a                    ; 26ee: 77
    jr nc, .gate                  ; 26ef: 30 05    | underflow -> channel off
    call Snd_EnvOff               ; 26f1: cd 1a 27
    jr .next                      ; 26f4: 18 1c

.gate:
    pop de                        ; 26f6: d1       | DE = track index
    push de                       ; 26f7: d5
    ld hl, wSnd_TrackGate+1       ; 26f8: 21 76 de | 16-bit gate (note length in frames)
    add hl, de                    ; 26fb: 19
    add hl, de                    ; 26fc: 19
    ld a, [hl-]                   ; 26fd: 3a
    or [hl]                       ; 26fe: b6
    jr z, .gateExpired            ; 26ff: 28 08
    dec [hl]                      ; 2701: 35       | gate != 0: count down
    ld a, [hl+]                   ; 2702: 2a
    inc a                         ; 2703: 3c
    jr nz, .output                ; 2704: 20 09
    dec [hl]                      ; 2706: 35
    jr .output                    ; 2707: 18 06

.gateExpired:
    ld hl, wSnd_EnvPhase          ; 2709: 21 3d de | gate ran out -> RELEASE
    add hl, bc                    ; 270c: 09
    ld [hl], $04                  ; 270d: 36 04

.output:
    call Snd_EnvWriteVolume       ; 270f: cd 27 27 | push level to hardware (STUBBED OUT)

.next:
    pop bc                        ; 2712: c1
    dec c                         ; 2713: 0d
    ld a, c                       ; 2714: 79
    inc a                         ; 2715: 3c
    jp nz, .trackLoop             ; 2716: c2 60 26
    ret                           ; 2719: c9

; Snd_EnvOff: BC = channel
Snd_EnvOff:
    ld hl, wSnd_EnvPhase          ; 271a: 21 3d de | phase = 0
    add hl, bc                    ; 271d: 09
    ld [hl], $00                  ; 271e: 36 00
    ld hl, wSnd_EnvLevel          ; 2720: 21 39 de | level = 0
    add hl, bc                    ; 2723: 09
    ld [hl], $00                  ; 2724: 36 00
    ret                           ; 2726: c9

; Snd_EnvWriteVolume: would copy the envelope level to NRx2/NR32.  The first
; byte was patched to RET, so the whole software envelope has no audible effect;
; notes play at the fixed $F8 set by Snd_NoteOn.
Snd_EnvWriteVolume:
    ret                           ; 2727: c9       | *** stub: the real body below is never executed ***

.dead_body:
    ld hl, wSnd_EnvLevel          ; 2728: 21 39 de | level of channel C
    add hl, bc                    ; 272b: 09
    ld a, [hl]                    ; 272c: 7e       | upper nibble only
    and $f0                       ; 272d: e6 f0
    ld d, a                       ; 272f: 57       | CH1
    ld a, c                       ; 2730: 79
    or a                          ; 2731: b7
    jr nz, .v_notCh1              ; 2732: 20 04
    ld a, d                       ; 2734: 7a
    ldh [rNR12], a                ; 2735: e0 12
    ret                           ; 2737: c9       | CH2

.v_notCh1:
    dec a                         ; 2738: 3d
    jr nz, .v_notCh2              ; 2739: 20 04
    ld a, d                       ; 273b: 7a
    ldh [rNR22], a                ; 273c: e0 17    | NR22 = level
    ret                           ; 273e: c9

.v_notCh2:
    dec a                         ; 273f: 3d       | CH3
    jr nz, .v_ch4                 ; 2740: 20 0b
    ld a, d                       ; 2742: 7a       | level bits 7-6 -> NR32 output-level code
    and $c0                       ; 2743: e6 c0
    rrca                          ; 2745: 0f
    xor $60                       ; 2746: ee 60
    add $20                       ; 2748: c6 20
    ldh [rNR32], a                ; 274a: e0 1c
    ret                           ; 274c: c9       | CH4

.v_ch4:
    ld a, d                       ; 274d: 7a       | NR42 = level
    ldh [rNR42], a                ; 274e: e0 21
    ld a, $80                     ; 2750: 3e 80    | NR44 trigger
    ldh [rNR44], a                ; 2752: e0 23
    ret                           ; 2754: c9

; Snd_UpdateTracks
Snd_UpdateTracks:
    ld a, [wSnd_NumTracks]        ; 2755: fa 47 de
    dec a                         ; 2758: 3d
    ld c, a                       ; 2759: 4f       | for track = n-1 .. 0 (uses wSnd_NumTracks, unlike BO)
    ld b, $00                     ; 275a: 06 00

.loop:
    push bc                       ; 275c: c5
    call Snd_UpdateTrack          ; 275d: cd 67 27
    pop bc                        ; 2760: c1
    dec c                         ; 2761: 0d
    ld a, c                       ; 2762: 79
    inc a                         ; 2763: 3c
    jr nz, .loop                  ; 2764: 20 f6
    ret                           ; 2766: c9

; =============================================================================
; Snd_UpdateTrack  BC = track index
; =============================================================================
Snd_UpdateTrack:
    ld hl, wSnd_TrackWait+1       ; 2767: 21 5b de | 16-bit wait counter
    add hl, bc                    ; 276a: 09
    add hl, bc                    ; 276b: 09
    ld a, [hl-]                   ; 276c: 3a
    or [hl]                       ; 276d: b6
    jr z, .nextEvent              ; 276e: 28 06    | wait != 0: decrement (16-bit) and exit
    dec [hl]                      ; 2770: 35
    ld a, [hl+]                   ; 2771: 2a
    inc a                         ; 2772: 3c
    ret nz                        ; 2773: c0
    dec [hl]                      ; 2774: 35
    ret                           ; 2775: c9

.nextEvent:
    ld hl, wSnd_TrackPtr          ; 2776: 21 48 de | NB: no "track inactive" check (BO has one)
    add hl, bc                    ; 2779: 09
    add hl, bc                    ; 277a: 09
    ld a, [hl+]                   ; 277b: 2a
    ld h, [hl]                    ; 277c: 66
    ld l, a                       ; 277d: 6f
    call Snd_ReadEvent            ; 277e: cd df 27 | parse event
    ld hl, wSnd_TrackEvent        ; 2781: 21 6c de | event byte
    add hl, bc                    ; 2784: 09
    ld a, [hl]                    ; 2785: 7e
    cp $d9                        ; 2786: fe d9    | < $D9 = note
    jr nc, .command               ; 2788: 30 05
    call Snd_NoteOn               ; 278a: cd 86 28
    jr .readDelta                 ; 278d: 18 37

.command:
    cp $dc                        ; 278f: fe dc    | DC: instrument
    jr nz, .notDC                 ; 2791: 20 05
    call Snd_SetInstrument        ; 2793: cd 43 28
    jr .readDelta                 ; 2796: 18 2e

.notDC:
    cp $dd                        ; 2798: fe dd    | DD: tempo
    jr nz, .notDD                 ; 279a: 20 05
    call Snd_SetTempo             ; 279c: cd 7e 29
    jr .readDelta                 ; 279f: 18 25

.notDD:
    cp $da                        ; 27a1: fe da    | DA: stop all
    jp z, Snd_Reset               ; 27a3: ca 20 26
    cp $d9                        ; 27a6: fe d9    | D9: stop all (BO: restart song)
    jp z, Snd_Reset               ; 27a8: ca 20 26
    cp $db                        ; 27ab: fe db    | DB: restart song
    jr nz, .readDelta             ; 27ad: 20 17    | E3/DE/DF/E2/other: ignored
    ld hl, wSnd_SongHeader        ; 27af: 21 35 de | HL = header
    ld a, [hl+]                   ; 27b2: 2a
    ld d, [hl]                    ; 27b3: 56
    ld e, a                       ; 27b4: 5f
    push de                       ; 27b5: d5
    ld hl, wSnd_SongDE            ; 27b6: 21 37 de | DE = instrument table
    ld a, [hl+]                   ; 27b9: 2a
    ld d, [hl]                    ; 27ba: 56
    ld e, a                       ; 27bb: 5f
    pop hl                        ; 27bc: e1
    pop bc                        ; 27bd: c1       | drop our return address...
    pop bc                        ; 27be: c1       | ...and the loop counter
    xor a                         ; 27bf: af
    ld [wSnd_Enabled], a          ; 27c0: ea 33 de
    jp Snd_PlaySong               ; 27c3: c3 9e 25 | re-enter via Snd_PlaySong (returns to Update's caller)

.readDelta:
    ld hl, wSnd_TrackPtr          ; 27c6: 21 48 de | peek delta-time in front of next event
    add hl, bc                    ; 27c9: 09
    add hl, bc                    ; 27ca: 09
    ld a, [hl+]                   ; 27cb: 2a
    ld h, [hl]                    ; 27cc: 66
    ld l, a                       ; 27cd: 6f
    call Snd_ReadVarLen           ; 27ce: cd 85 29
    ld a, d                       ; 27d1: 7a
    or e                          ; 27d2: b3
    jr z, .storeWait              ; 27d3: 28 01    | wait = delta-1
    dec de                        ; 27d5: 1b

.storeWait:
    ld hl, wSnd_TrackWait         ; 27d6: 21 5a de
    add hl, bc                    ; 27d9: 09
    add hl, bc                    ; 27da: 09
    ld a, e                       ; 27db: 7b
    ld [hl+], a                   ; 27dc: 22
    ld [hl], d                    ; 27dd: 72
    ret                           ; 27de: c9

; =============================================================================
; Snd_ReadEvent  HL = stream ptr, BC = track   (same stream format as BO)
; =============================================================================
Snd_ReadEvent:
    call Snd_ReadVarLen           ; 27df: cd 85 29 | skip delta already consumed
    ld a, [hl]                    ; 27e2: 7e       | event byte
    push hl                       ; 27e3: e5
    ld hl, wSnd_TrackEvent        ; 27e4: 21 6c de
    add hl, bc                    ; 27e7: 09
    ld [hl], a                    ; 27e8: 77
    pop hl                        ; 27e9: e1
    inc hl                        ; 27ea: 23
    cp $d9                        ; 27eb: fe d9    | < $D9: note
    jr c, .note                   ; 27ed: 38 35
    cp $d9                        ; 27ef: fe d9    | no-arg: D9 DA DB E3 (no EA in TG)
    jr z, .savePtr                ; 27f1: 28 26
    cp $da                        ; 27f3: fe da
    jr z, .savePtr                ; 27f5: 28 22
    cp $db                        ; 27f7: fe db
    jr z, .savePtr                ; 27f9: 28 1e
    cp $e3                        ; 27fb: fe e3
    jr z, .savePtr                ; 27fd: 28 1a
    cp $dc                        ; 27ff: fe dc    | 1-byte arg: DC DD DE E2
    jr z, .oneArg                 ; 2801: 28 11
    cp $dd                        ; 2803: fe dd
    jr z, .oneArg                 ; 2805: 28 0d
    cp $de                        ; 2807: fe de
    jr z, .oneArg                 ; 2809: 28 09
    cp $e2                        ; 280b: fe e2
    jr z, .oneArg                 ; 280d: 28 05
    cp $df                        ; 280f: fe df    | DF and every unknown byte: 2 args, keep the 2nd
    jr z, .twoArgs                ; 2811: 28 00

.twoArgs:
    inc hl                        ; 2813: 23

.oneArg:
    ld a, [hl]                    ; 2814: 7e
    ld [wSnd_EventArg], a         ; 2815: ea a2 de
    inc hl                        ; 2818: 23

.savePtr:
    ld d, h                       ; 2819: 54
    ld e, l                       ; 281a: 5d
    ld hl, wSnd_TrackPtr          ; 281b: 21 48 de
    add hl, bc                    ; 281e: 09
    add hl, bc                    ; 281f: 09
    ld a, e                       ; 2820: 7b
    ld [hl+], a                   ; 2821: 22
    ld [hl], d                    ; 2822: 72
    ret                           ; 2823: c9

.note:
    bit 7, a                      ; 2824: cb 7f    | bit 7 = extra byte follows
    jr z, .noteParam              ; 2826: 28 04
    ld a, [hl+]                   ; 2828: 2a       | (into EventArg, unused by note-on)
    ld [wSnd_EventArg], a         ; 2829: ea a2 de

.noteParam:
    call Snd_ReadVarLen           ; 282c: cd 85 29 | note parameter = gate (var-length)
    push hl                       ; 282f: e5
    ld hl, wSnd_TrackGate         ; 2830: 21 75 de
    add hl, bc                    ; 2833: 09
    add hl, bc                    ; 2834: 09
    ld a, e                       ; 2835: 7b
    ld [hl+], a                   ; 2836: 22
    ld [hl], d                    ; 2837: 72
    pop de                        ; 2838: d1
    ld hl, wSnd_TrackPtr          ; 2839: 21 48 de
    add hl, bc                    ; 283c: 09
    add hl, bc                    ; 283d: 09
    ld a, e                       ; 283e: 7b
    ld [hl+], a                   ; 283f: 22
    ld [hl], d                    ; 2840: 72
    ret                           ; 2841: c9

; Snd_ClearChannel: empty (called 4x by Snd_Reset)
Snd_ClearChannel:
    ret                           ; 2842: c9       | stub

; Snd_SetInstrument (command DC n): instrument = InstrTable[n]
Snd_SetInstrument:
    ld hl, wSnd_InstrTable        ; 2843: 21 a3 de | instrument table (from DE at song start)
    ld a, [hl+]                   ; 2846: 2a
    ld h, [hl]                    ; 2847: 66
    ld l, a                       ; 2848: 6f
    ld a, [wSnd_EventArg]         ; 2849: fa a2 de | index = DC argument
    add a                         ; 284c: 87
    add l                         ; 284d: 85
    ld l, a                       ; 284e: 6f
    jr nc, .gotPtr                ; 284f: 30 01
    inc h                         ; 2851: 24

.gotPtr:
    ld a, [hl+]                   ; 2852: 2a
    ld d, [hl]                    ; 2853: 56
    ld e, a                       ; 2854: 5f
    ld hl, wSnd_TrackInstr        ; 2855: 21 87 de | -> this track's instrument pointer
    add hl, bc                    ; 2858: 09
    add hl, bc                    ; 2859: 09
    ld a, e                       ; 285a: 7b
    ld [hl+], a                   ; 285b: 22
    ld [hl], d                    ; 285c: 72
    ld a, $04                     ; 285d: 3e 04    | instr +4 = transpose
    add e                         ; 285f: 83
    ld e, a                       ; 2860: 5f
    jr nc, .transpose             ; 2861: 30 01
    inc d                         ; 2863: 14

.transpose:
    ld hl, wSnd_TrackTranspose    ; 2864: 21 99 de
    add hl, bc                    ; 2867: 09
    ld a, [de]                    ; 2868: 1a
    ld [hl], a                    ; 2869: 77
    ld a, c                       ; 286a: 79       | track 2 only (track index, NOT channel!)
    cp $02                        ; 286b: fe 02
    ret nz                        ; 286d: c0
    xor a                         ; 286e: af       | wave ch off
    ldh [rNR30], a                ; 286f: e0 1a
    ld hl, Snd_WaveTable          ; 2871: 21 93 29 | upload 16-byte wave
    ld de, _AUD3WAVERAM           ; 2874: 11 30 ff

.copyWave:
    ld a, [hl+]                   ; 2877: 2a
    ld [de], a                    ; 2878: 12
    inc e                         ; 2879: 1c
    ld a, e                       ; 287a: 7b
    cp $40                        ; 287b: fe 40
    jr nz, .copyWave              ; 287d: 20 f8
    ld a, $80                     ; 287f: 3e 80    | wave ch on
    ldh [rNR30], a                ; 2881: e0 1a
    ldh [rNR34], a                ; 2883: e0 1e    | NR34 = $80 (BO writes 0)
    ret                           ; 2885: c9

; =============================================================================
; Snd_NoteOn  BC = track.  No channel priority/arbitration (BO has it).
; =============================================================================
Snd_NoteOn:
    push bc                       ; 2886: c5
    ld hl, wSnd_TrackEvent        ; 2887: 21 6c de | raw note byte
    add hl, bc                    ; 288a: 09
    ld a, [hl]                    ; 288b: 7e
    ld [wSnd_NoteByte], a         ; 288c: ea a7 de
    and $7f                       ; 288f: e6 7f    | index = note + transpose
    ld hl, wSnd_TrackTranspose    ; 2891: 21 99 de
    add hl, bc                    ; 2894: 09
    add [hl]                      ; 2895: 86
    ld hl, Snd_FreqTable          ; 2896: 21 a7 29 | Snd_FreqTable
    add a                         ; 2899: 87
    add l                         ; 289a: 85
    ld l, a                       ; 289b: 6f
    jr nc, .gotFreq               ; 289c: 30 01
    inc h                         ; 289e: 24

.gotFreq:
    push hl                       ; 289f: e5
    ld de, $0000                  ; 28a0: 11 00 00 | DE = 0 (freq offset, always 0 here)
    ld hl, wSnd_TrackInstr        ; 28a3: 21 87 de | instrument -> hardware channel
    add hl, bc                    ; 28a6: 09
    add hl, bc                    ; 28a7: 09
    ld a, [hl+]                   ; 28a8: 2a
    ld h, [hl]                    ; 28a9: 66
    ld l, a                       ; 28aa: 6f
    ld c, [hl]                    ; 28ab: 4e
    ld b, $00                     ; 28ac: 06 00
    ld hl, wSnd_EnvPhase          ; 28ae: 21 3d de | envelope phase = ATTACK
    add hl, bc                    ; 28b1: 09
    ld [hl], $01                  ; 28b2: 36 01
    ld hl, wSnd_ChanActive        ; 28b4: 21 41 de | channel keyed
    add hl, bc                    ; 28b7: 09
    ld [hl], $01                  ; 28b8: 36 01
    pop hl                        ; 28ba: e1
    ld a, c                       ; 28bb: 79
    or a                          ; 28bc: b7
    jr nz, .notCh1                ; 28bd: 20 19
    ld a, $f8                     ; 28bf: 3e f8    | NR12 = $F8 fixed (vol 15, no env) - instr volume unused
    ldh [rNR12], a                ; 28c1: e0 12
    ld a, e                       ; 28c3: 7b       | freq lo
    add [hl]                      ; 28c4: 86
    ldh [rNR13], a                ; 28c5: e0 13
    inc hl                        ; 28c7: 23
    ld a, d                       ; 28c8: 7a       | freq hi
    adc [hl]                      ; 28c9: 8e
    set 7, a                      ; 28ca: cb ff    | trigger
    res 6, a                      ; 28cc: cb b7    | clear length-enable
    ldh [rNR14], a                ; 28ce: e0 14
    ld a, $80                     ; 28d0: 3e 80    | NR10 = $80 (no sweep)
    ldh [rNR10], a                ; 28d2: e0 10
    ldh [rNR11], a                ; 28d4: e0 11    | NR11 = $80 (50% duty) - instr duty unused
    pop bc                        ; 28d6: c1
    ret                           ; 28d7: c9

.notCh1:
    dec a                         ; 28d8: 3d
    jr nz, .notCh2                ; 28d9: 20 16
    ld a, $f8                     ; 28db: 3e f8    | NR22 = $F8
    ldh [rNR22], a                ; 28dd: e0 17
    ld a, e                       ; 28df: 7b
    add [hl]                      ; 28e0: 86
    ldh [rNR23], a                ; 28e1: e0 18
    inc hl                        ; 28e3: 23
    ld a, d                       ; 28e4: 7a
    adc [hl]                      ; 28e5: 8e
    set 7, a                      ; 28e6: cb ff
    res 6, a                      ; 28e8: cb b7
    ldh [rNR24], a                ; 28ea: e0 19
    xor a                         ; 28ec: af       | NR21 = $00 (12.5% duty)
    ldh [rNR21], a                ; 28ed: e0 16
    pop bc                        ; 28ef: c1
    ret                           ; 28f0: c9

.notCh2:
    dec a                         ; 28f1: 3d
    jr nz, .ch4                   ; 28f2: 20 13
    ld a, $20                     ; 28f4: 3e 20    | NR32 = $20 (100%)
    ldh [rNR32], a                ; 28f6: e0 1c
    ld a, e                       ; 28f8: 7b
    add [hl]                      ; 28f9: 86
    ldh [rNR33], a                ; 28fa: e0 1d
    inc hl                        ; 28fc: 23
    ld a, d                       ; 28fd: 7a
    adc [hl]                      ; 28fe: 8e
    set 7, a                      ; 28ff: cb ff
    res 6, a                      ; 2901: cb b7
    ldh [rNR34], a                ; 2903: e0 1e
    pop bc                        ; 2905: c1
    ret                           ; 2906: c9

.ch4:
    ld a, $f8                     ; 2907: 3e f8
    ldh [rNR42], a                ; 2909: e0 21    | NR42 = $F8
    ld a, [wSnd_NoteByte]         ; 290b: fa a7 de | drum map on raw note byte
    cp $08                        ; 290e: fe 08
    jr z, .drumD                  ; 2910: 28 45
    cp $18                        ; 2912: fe 18
    jr z, .drumA                  ; 2914: 28 26
    cp $1a                        ; 2916: fe 1a
    jr z, .drumB                  ; 2918: 28 2b
    cp $1c                        ; 291a: fe 1c
    jr z, .drumB                  ; 291c: 28 27
    cp $1e                        ; 291e: fe 1e
    jr z, .drumD                  ; 2920: 28 35
    cp $15                        ; 2922: fe 15
    jr z, .drumB                  ; 2924: 28 1f
    cp $18                        ; 2926: fe 18
    jr z, .drumB                  ; 2928: 28 1b
    cp $19                        ; 292a: fe 19
    jr z, .drumA                  ; 292c: 28 0e
    cp $1b                        ; 292e: fe 1b
    jp z, .drumD                  ; 2930: ca 57 29
    jp .drumA                     ; 2933: c3 3c 29 | default

; unreachable leftovers of the drum map
.dead_jp:
    jp .setDrumInstr              ; 2936: c3 72 29
    jp .setDrumInstr              ; 2939: c3 72 29

.drumA:
    ld a, $88                     ; 293c: 3e 88    | NR43 = $88
    ldh [rNR43], a                ; 293e: e0 22
    ld de, Snd_DrumInstruments    ; 2940: 11 93 2a | drum instrument record
    jr .setDrumInstr              ; 2943: 18 2d

.drumB:
    ld a, $30                     ; 2945: 3e 30    | NR43 = $30
    ldh [rNR43], a                ; 2947: e0 22
    ld de, $2aa1                  ; 2949: 11 a1 2a
    jr .setDrumInstr              ; 294c: 18 24

.dead_drumC:
    ld a, $60                     ; 294e: 3e 60
    ldh [rNR43], a                ; 2950: e0 22
    ld de, $2acb                  ; 2952: 11 cb 2a
    jr .setDrumInstr              ; 2955: 18 1b

.drumD:
    ld a, $70                     ; 2957: 3e 70    | NR43 = $70
    ldh [rNR43], a                ; 2959: e0 22
    ld de, $2abd                  ; 295b: 11 bd 2a
    jr .setDrumInstr              ; 295e: 18 12

.dead_drumE:
    ld a, $50                     ; 2960: 3e 50
    ldh [rNR43], a                ; 2962: e0 22
    ld de, $2acb                  ; 2964: 11 cb 2a
    jr .setDrumInstr              ; 2967: 18 09
    ld a, $40                     ; 2969: 3e 40
    ldh [rNR43], a                ; 296b: e0 22
    ld de, $2acb                  ; 296d: 11 cb 2a
    jr .setDrumInstr              ; 2970: 18 00

.setDrumInstr:
    pop bc                        ; 2972: c1       | restore track index
    ld hl, wSnd_TrackInstr        ; 2973: 21 87 de | track now uses the drum record for its envelope
    add hl, bc                    ; 2976: 09
    add hl, bc                    ; 2977: 09
    ld a, e                       ; 2978: 7b
    ld [hl+], a                   ; 2979: 22
    ld [hl], d                    ; 297a: 72
    ret                           ; 297b: c9

.dead_ret:
    pop bc                        ; 297c: c1
    ret                           ; 297d: c9

; Snd_SetTempo (command DD n) - vestigial, same as BO
Snd_SetTempo:
    ld a, [wSnd_EventArg]         ; 297e: fa a2 de | DD: store tempo - nothing reads it
    ld [wSnd_Tempo], a            ; 2981: ea a5 de
    ret                           ; 2984: c9

; Snd_ReadVarLen - see BO notes
Snd_ReadVarLen:
    ld d, $00                     ; 2985: 16 00    | identical bytes to BO $2709
    ld a, [hl+]                   ; 2987: 2a
    bit 7, a                      ; 2988: cb 7f
    jr z, .done                   ; 298a: 28 05
    and $7f                       ; 298c: e6 7f    | (b & $7F) rotated right ...
    rrca                          ; 298e: 0f
    add [hl]                      ; 298f: 86       | ... + next byte (8-bit, max 255)
    inc hl                        ; 2990: 23

.done:
    ld e, a                       ; 2991: 5f
    ret                           ; 2992: c9

; Wave pattern for CH3 (sawtooth-ish ramp)
Snd_WaveTable:
    db $ff, $00, $dd, $00, $bb, $00, $aa, $00 ; 2993
    db $88, $00, $66, $00, $44, $00, $22, $00 ; 299b

; (unreferenced) NR32 output levels - identical bytes in BO $2727
Snd_WaveVolTable:
    db $00, $60, $40, $20         ; 29a3

; Frequency table: 118 x dw from C2.  Byte-identical to BO $272B
Snd_FreqTable:
    dw $002c                      ; 29a7 | n=  0 C  2  65.4 Hz
    dw $009d                      ; 29a9 | n=  1 C# 2  69.3 Hz
    dw $0108                      ; 29ab | n=  2 D  2  73.5 Hz
    dw $016d                      ; 29ad | n=  3 D# 2  77.9 Hz
    dw $01cc                      ; 29af | n=  4 E  2  82.5 Hz
    dw $0225                      ; 29b1 | n=  5 F  2  87.4 Hz
    dw $027a                      ; 29b3 | n=  6 F# 2  92.7 Hz
    dw $02ca                      ; 29b5 | n=  7 G  2  98.3 Hz
    dw $0315                      ; 29b7 | n=  8 G# 2  104.1 Hz
    dw $035c                      ; 29b9 | n=  9 A  2  110.3 Hz
    dw $039f                      ; 29bb | n= 10 A# 2  116.9 Hz
    dw $03de                      ; 29bd | n= 11 B  2  123.9 Hz
    dw $041a                      ; 29bf | n= 12 C  3  131.3 Hz
    dw $0452                      ; 29c1 | n= 13 C# 3  139.1 Hz
    dw $0487                      ; 29c3 | n= 14 D  3  147.4 Hz
    dw $04b9                      ; 29c5 | n= 15 D# 3  156.2 Hz
    dw $04e9                      ; 29c7 | n= 16 E  3  165.7 Hz
    dw $0515                      ; 29c9 | n= 17 F  3  175.5 Hz
    dw $053f                      ; 29cb | n= 18 F# 3  185.9 Hz
    dw $0567                      ; 29cd | n= 19 G  3  197.1 Hz
    dw $058d                      ; 29cf | n= 20 G# 3  209.0 Hz
    dw $05b0                      ; 29d1 | n= 21 A  3  221.4 Hz
    dw $05d1                      ; 29d3 | n= 22 A# 3  234.5 Hz
    dw $05f1                      ; 29d5 | n= 23 B  3  248.7 Hz
    dw $060f                      ; 29d7 | n= 24 C  4  263.7 Hz
    dw $062b                      ; 29d9 | n= 25 C# 4  279.5 Hz
    dw $0645                      ; 29db | n= 26 D  4  295.9 Hz
    dw $065e                      ; 29dd | n= 27 D# 4  313.6 Hz
    dw $0676                      ; 29df | n= 28 E  4  332.7 Hz
    dw $068c                      ; 29e1 | n= 29 F  4  352.3 Hz
    dw $06a1                      ; 29e3 | n= 30 F# 4  373.4 Hz
    dw $06b5                      ; 29e5 | n= 31 G  4  396.0 Hz
    dw $06c7                      ; 29e7 | n= 32 G# 4  418.8 Hz
    dw $06d9                      ; 29e9 | n= 33 A  4  444.3 Hz
    dw $06ea                      ; 29eb | n= 34 A# 4  471.5 Hz
    dw $06f9                      ; 29ed | n= 35 B  4  498.4 Hz
    dw $0708                      ; 29ef | n= 36 C  5  528.5 Hz
    dw $0716                      ; 29f1 | n= 37 C# 5  560.1 Hz
    dw $0723                      ; 29f3 | n= 38 D  5  593.1 Hz
    dw $0730                      ; 29f5 | n= 39 D# 5  630.2 Hz
    dw $073c                      ; 29f7 | n= 40 E  5  668.7 Hz
    dw $0747                      ; 29f9 | n= 41 F  5  708.5 Hz
    dw $0751                      ; 29fb | n= 42 F# 5  749.0 Hz
    dw $075b                      ; 29fd | n= 43 G  5  794.4 Hz
    dw $0764                      ; 29ff | n= 44 G# 5  840.2 Hz
    dw $076d                      ; 2a01 | n= 45 A  5  891.6 Hz
    dw $0775                      ; 2a03 | n= 46 A# 5  943.0 Hz
    dw $077d                      ; 2a05 | n= 47 B  5  1000.5 Hz
    dw $0785                      ; 2a07 | n= 48 C  6  1065.6 Hz
    dw $078c                      ; 2a09 | n= 49 C# 6  1129.9 Hz
    dw $0792                      ; 2a0b | n= 50 D  6  1191.6 Hz
    dw $0798                      ; 2a0d | n= 51 D# 6  1260.3 Hz
    dw $079e                      ; 2a0f | n= 52 E  6  1337.5 Hz
    dw $07a4                      ; 2a11 | n= 53 F  6  1424.7 Hz
    dw $07a9                      ; 2a13 | n= 54 F# 6  1506.6 Hz
    dw $07ae                      ; 2a15 | n= 55 G  6  1598.4 Hz
    dw $07b2                      ; 2a17 | n= 56 G# 6  1680.4 Hz
    dw $07b7                      ; 2a19 | n= 57 A  6  1795.5 Hz
    dw $07bb                      ; 2a1b | n= 58 A# 6  1899.6 Hz
    dw $07bf                      ; 2a1d | n= 59 B  6  2016.5 Hz
    dw $07c3                      ; 2a1f | n= 60 C  7  2148.7 Hz
    dw $07c6                      ; 2a21 | n= 61 C# 7  2259.9 Hz
    dw $07c9                      ; 2a23 | n= 62 D  7  2383.1 Hz
    dw $07cc                      ; 2a25 | n= 63 D# 7  2520.6 Hz
    dw $07cf                      ; 2a27 | n= 64 E  7  2674.9 Hz
    dw $07d2                      ; 2a29 | n= 65 F  7  2849.4 Hz
    dw $07d5                      ; 2a2b | n= 66 F# 7  3048.2 Hz
    dw $07d7                      ; 2a2d | n= 67 G  7  3196.9 Hz
    dw $07d9                      ; 2a2f | n= 68 G# 7  3360.8 Hz
    dw $07dc                      ; 2a31 | n= 69 A  7  3640.9 Hz
    dw $07de                      ; 2a33 | n= 70 A# 7  3855.1 Hz
    dw $07e0                      ; 2a35 | n= 71 B  7  4096.0 Hz
    dw $07e1                      ; 2a37 | n= 72 C  8  4228.1 Hz
    dw $07e3                      ; 2a39 | n= 73 C# 8  4519.7 Hz
    dw $07e5                      ; 2a3b | n= 74 D  8  4854.5 Hz
    dw $07e6                      ; 2a3d | n= 75 D# 8  5041.2 Hz
    dw $07e8                      ; 2a3f | n= 76 E  8  5461.3 Hz
    dw $07e9                      ; 2a41 | n= 77 F  8  5698.8 Hz
    dw $07ea                      ; 2a43 | n= 78 F# 8  5957.8 Hz
    dw $07ec                      ; 2a45 | n= 79 G  8  6553.6 Hz
    dw $07ed                      ; 2a47 | n= 80 G# 8  6898.5 Hz
    dw $07ee                      ; 2a49 | n= 81 A  8  7281.8 Hz
    dw $07ef                      ; 2a4b | n= 82 A# 8  7710.1 Hz
    dw $07f0                      ; 2a4d | n= 83 B  8  8192.0 Hz
    dw $07f1                      ; 2a4f | n= 84 C  9  8738.1 Hz
    dw $07f2                      ; 2a51 | n= 85 C# 9  9362.3 Hz
    dw $07f2                      ; 2a53 | n= 86 D  9  9362.3 Hz
    dw $07f3                      ; 2a55 | n= 87 D# 9  10082.5 Hz
    dw $07f4                      ; 2a57 | n= 88 E  9  10922.7 Hz
    dw $07f5                      ; 2a59 | n= 89 F  9  11915.6 Hz
    dw $07f5                      ; 2a5b | n= 90 F# 9  11915.6 Hz
    dw $07f6                      ; 2a5d | n= 91 G  9  13107.2 Hz
    dw $07f6                      ; 2a5f | n= 92 G# 9  13107.2 Hz
    dw $07f7                      ; 2a61 | n= 93 A  9  14563.6 Hz
    dw $07f7                      ; 2a63 | n= 94 A# 9  14563.6 Hz
    dw $07f8                      ; 2a65 | n= 95 B  9  16384.0 Hz
    dw $07f8                      ; 2a67 | n= 96 C  10  16384.0 Hz
    dw $07f9                      ; 2a69 | n= 97 C# 10  18724.6 Hz
    dw $07f9                      ; 2a6b | n= 98 D  10  18724.6 Hz
    dw $07fa                      ; 2a6d | n= 99 D# 10  21845.3 Hz
    dw $07fa                      ; 2a6f | n=100 E  10  21845.3 Hz
    dw $07fa                      ; 2a71 | n=101 F  10  21845.3 Hz
    dw $07fb                      ; 2a73 | n=102 F# 10  26214.4 Hz
    dw $07fb                      ; 2a75 | n=103 G  10  26214.4 Hz
    dw $07fb                      ; 2a77 | n=104 G# 10  26214.4 Hz
    dw $07fb                      ; 2a79 | n=105 A  10  26214.4 Hz
    dw $07fc                      ; 2a7b | n=106 A# 10  32768.0 Hz
    dw $07fc                      ; 2a7d | n=107 B  10  32768.0 Hz
    dw $07fc                      ; 2a7f | n=108 C  11  32768.0 Hz
    dw $07fc                      ; 2a81 | n=109 C# 11  32768.0 Hz
    dw $07fd                      ; 2a83 | n=110 D  11  43690.7 Hz
    dw $07fd                      ; 2a85 | n=111 D# 11  43690.7 Hz
    dw $07fd                      ; 2a87 | n=112 E  11  43690.7 Hz
    dw $07fd                      ; 2a89 | n=113 F  11  43690.7 Hz
    dw $07fd                      ; 2a8b | n=114 F# 11  43690.7 Hz
    dw $07fd                      ; 2a8d | n=115 G  11  43690.7 Hz
    dw $07fe                      ; 2a8f | n=116 G# 11  65536.0 Hz
    dw $07fe                      ; 2a91 | n=117 A  11  65536.0 Hz

; Drum instrument records (14-byte TG format, channel 3 = CH4).  Only
; $2A93, $2AA1 and $2ABD are reachable; $2ACB is used only by dead code.
Snd_DrumInstruments:
    db $03, $00, $00, $00, $00, $00, $00, $00, $00, $f0, $f0, $00, $f0, $f0 ; 2a93 | NR43=$88 default/$18/$19
    db $03, $00, $00, $00, $00, $00, $00, $00, $00, $c0, $c0, $30, $00, $00 ; 2aa1 | NR43=$30 notes $15/$1A/$1C
    db $03, $00, $00, $00, $00, $00, $00, $00, $00, $f0, $f0, $00, $f0, $78 ; 2aaf | unreferenced
    db $03, $00, $00, $00, $00, $00, $00, $00, $00, $30, $30, $00, $30, $30 ; 2abd | NR43=$70 notes $08/$1B/$1E
    db $03, $00, $00, $00, $00, $00, $00, $00, $00, $c0, $c0, $00, $c0, $60 ; 2acb | dead code only
    db $03, $00, $00, $00, $00, $00, $00, $00, $00, $f0, $f0, $00, $f0, $78 ; 2ad9 | unreferenced
