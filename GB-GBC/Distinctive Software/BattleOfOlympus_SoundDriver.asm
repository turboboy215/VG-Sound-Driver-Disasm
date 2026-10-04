; =============================================================================
;  The Battle of Olympus (Game Boy, 1993)  -  SOUND DRIVER DISASSEMBLY
;  ROM: "Battle of Olympus, The (UE) (M5).gb"  header title OLYMPUS, lic $9C
;  Developer: Radical Entertainment   Publisher: Imagineer
;
;  Driver code  : ROM0 $22DB-$2716  (tables to $2816)
;  Music/SFX    : ROM bank $0F  (wSnd_Bank is set to $0F at 04:$6B5D)
;  Update hook  : VBlank handler calls Snd_Update at $01A9
;
;  Re-assembles byte-exact with RGBDS (verified).  Each line carries the ROM
;  address and original bytes after the ';'.  Everything after '|' is a note.
; -----------------------------------------------------------------------------
;  ARCHITECTURE
;   * 9 "tracks" (virtual voices, slots 0-8) share the 4 hardware channels.
;     Songs fill slots 0..n-1; sound effects are dropped into the highest
;     free slot by Snd_PlaySFX.  One update per frame, no tempo scaling
;     (all times are in frames; the DD "tempo" command is stored but unused).
;   * Channel arbitration: every note looks up its instrument's hardware
;     channel and priority.  If priority >= the channel's current owner, it
;     takes the channel and sets a hold timer ((param+1)*4 frames); when the
;     timer runs out the channel's priority drops to 0.  Lower-priority notes
;     are silently dropped.  This is how SFX override the music.
;   * Envelopes: hardware only (NRx2), built from instrument volume plus the
;     low 4 bits of the per-note parameter.
;   * CH3 (wave): wave RAM is loaded, but the CH3 note-on is disabled (jumps
;     straight to exit); an unreachable CH3 routine remains at $26C9.
;
;  SONG HEADER (bank $0F)      db nTracks  /  dw track[0..n-1]
;    Several headers are followed by orphaned 14-byte instrument records in
;    the Top Gun format (see notes/comparison) which this driver never reads.
;
;  TRACK STREAM  =  repeated  [delta][event][args]
;    delta   : var-length frame count before the NEXT event (see ReadVarLen)
;    event   : $00-$D8  note.  bit7 = one extra byte follows (ignored)
;                       then  var-length note parameter:
;                        bits 0-2  -> envelope pace ((p&7)/2+1)
;                        bit  3    -> envelope direction
;                        whole     -> channel hold time (p+1)*4 frames
;                       CH1/2: freq = FreqTable[(n&$7F)+transpose]
;                       CH4  : NR43 = raw note byte
;              $D9       restart song from header
;              $DA       stop all (Snd_Reset)
;              $DB       restart song (same as D9)
;              $DC w     set instrument (16-bit pointer to 6-byte record)
;              $DD b     tempo (stored in wSnd_Tempo, never read)
;              $DE b / $DF w / $E2 b   parsed, but executing them restarts
;                        the song (Snd_BadCommand) - never used in BO data
;              $E3       loop this track (reload its header pointer)
;              $EA       end this track (free the slot; used by SFX)
;
;  INSTRUMENT (6 bytes)  +0 channel 0-3  +1 NRx1 duty  +2 priority
;                        +3 NR10 sweep   +4 transpose   +5 NRx2 volume nibble
; =============================================================================

INCLUDE "hardware.inc"

; ---- RAM used by the sound driver ----
DEF wSnd_SavedBankB EQU $de22
DEF wSnd_SavedBankA EQU $de23
DEF wSnd_Lock EQU $de34
DEF wSnd_Bank EQU $de35
DEF wSnd_Enabled EQU $de36
DEF wSnd_SongHeader EQU $de38
DEF wSnd_SongDE EQU $de3a
DEF wSnd_Unused3C EQU $de3c
DEF wSnd_Unused40 EQU $de40
DEF wSnd_ChanPriority EQU $de48
DEF wSnd_ChanTimer EQU $de4c
DEF wSnd_NumTracks EQU $de50
DEF wSnd_TrackPtr EQU $de51
DEF wSnd_TrackWait EQU $de63
DEF wSnd_TrackEvent EQU $de75
DEF wSnd_TrackNoteParam EQU $de7e
DEF wSnd_TrackInstr EQU $de90
DEF wSnd_TrackTranspose EQU $dea2
DEF wSnd_EventArg EQU $deab
DEF wSnd_InstrTable EQU $dead
DEF wSnd_Tempo EQU $deaf
DEF wSnd_Unused_B0 EQU $deb0
DEF wSnd_NoteByte EQU $deb1
DEF wSnd_CurInstr EQU $deb4
DEF wSnd_FreqLo EQU $deb7
DEF wSnd_FreqHi EQU $deb8
DEF wSnd_TmpPtr EQU $deb9
DEF wSnd_EnvBits EQU $debb

; ---- outside the driver ----
DEF WaitNextFrame EQU $0285
DEF MBC_ROMB EQU $2100
DEF wFrameCounter EQU $de00
DEF wROMBank EQU $de21
DEF wROMBankIRQ EQU $de24

SECTION "BO Sound Driver", ROM0[$22db]


; =============================================================================
; Snd_PlaySong  (called 8x from game code)
;   in:  HL = song header (in sound bank wSnd_Bank = $0F)
;        DE = unused by callers (stored, only matters for restarts)
; =============================================================================
Snd_PlaySong:
    ld a, $01                     ; 22db: 3e 01    | lock out Snd_Update while we rebuild state
    ld [wSnd_Lock], a             ; 22dd: ea 34 de
    ld a, [wROMBankIRQ]           ; 22e0: fa 24 de | save IRQ-restore bank
    ld [wSnd_SavedBankB], a       ; 22e3: ea 22 de
    ld a, [wSnd_Bank]             ; 22e6: fa 35 de | map in sound bank ($0F)
    ld [wROMBankIRQ], a           ; 22e9: ea 24 de
    ld [MBC_ROMB], a              ; 22ec: ea 00 21
    call Snd_APUOff               ; 22ef: cd ce 23 | NR52=0: hard-silence all channels
    push de                       ; 22f2: d5
    push hl                       ; 22f3: e5
    call Snd_StartSong            ; 22f4: cd 64 23 | set up the new song
    call WaitNextFrame            ; 22f7: cd 85 02 | wait one frame (halt until wFrameCounter changes)
    pop hl                        ; 22fa: e1
    pop de                        ; 22fb: d1
    ld a, [wSnd_SavedBankB]       ; 22fc: fa 22 de | restore previous bank
    ld [wROMBankIRQ], a           ; 22ff: ea 24 de
    ld [MBC_ROMB], a              ; 2302: ea 00 21
    xor a                         ; 2305: af       | unlock
    ld [wSnd_Lock], a             ; 2306: ea 34 de
    ret                           ; 2309: c9

; =============================================================================
; Snd_PlaySFX / Snd_PlaySFX_IRQBank
;   in:  HL = SFX event stream (bank $0F)
;   An SFX is just a single track stream that is dropped into the first free
;   track slot (8 down to 0), running alongside the music.  Channel stealing
;   is decided per note by instrument priority (see Snd_NoteOn).
; =============================================================================
Snd_PlaySFX_IRQBank:
    di                            ; 230a: f3       | variant using the IRQ bank shadow
    ld a, [wROMBankIRQ]           ; 230b: fa 24 de
    ld [wSnd_SavedBankB], a       ; 230e: ea 22 de
    ld a, [wSnd_Bank]             ; 2311: fa 35 de
    ld [wROMBankIRQ], a           ; 2314: ea 24 de
    ld [MBC_ROMB], a              ; 2317: ea 00 21
    call Snd_AddTrack             ; 231a: cd 46 23 | HL = SFX stream
    ld a, [wSnd_SavedBankB]       ; 231d: fa 22 de
    ld [wROMBankIRQ], a           ; 2320: ea 24 de
    ld [MBC_ROMB], a              ; 2323: ea 00 21
    ei                            ; 2326: fb
    ret                           ; 2327: c9

Snd_PlaySFX:
    di                            ; 2328: f3       | variant using the main bank shadow
    ld a, [wROMBank]              ; 2329: fa 21 de
    ld [wSnd_SavedBankA], a       ; 232c: ea 23 de
    ld a, [wSnd_Bank]             ; 232f: fa 35 de
    ld [wROMBank], a              ; 2332: ea 21 de
    ld [MBC_ROMB], a              ; 2335: ea 00 21
    call Snd_AddTrack             ; 2338: cd 46 23 | HL = SFX stream
    ld a, [wSnd_SavedBankA]       ; 233b: fa 23 de
    ld [wROMBank], a              ; 233e: ea 21 de
    ld [MBC_ROMB], a              ; 2341: ea 00 21
    ei                            ; 2344: fb
    ret                           ; 2345: c9

; Snd_AddTrack: find a free track slot (pointer == 0) and point it at DE
Snd_AddTrack:
    ld d, h                       ; 2346: 54       | DE = stream pointer
    ld e, l                       ; 2347: 5d
    ld bc, $0008                  ; 2348: 01 08 00 | start at track slot 8 (highest)

.scan:
    ld hl, wSnd_TrackPtr          ; 234b: 21 51 de
    add hl, bc                    ; 234e: 09
    add hl, bc                    ; 234f: 09
    ld a, [hl+]                   ; 2350: 2a       | slot free? (pointer == 0)
    or [hl]                       ; 2351: b6
    jr z, .found                  ; 2352: 28 07
    dec c                         ; 2354: 0d       | no: try next slot down
    ld a, c                       ; 2355: 79
    inc a                         ; 2356: 3c
    jr z, .full                   ; 2357: 28 07    | wrapped past slot 0: nothing free
    jr .scan                      ; 2359: 18 f0

.found:
    ld a, d                       ; 235b: 7a       | claim slot: store pointer
    ld [hl-], a                   ; 235c: 32
    ld a, e                       ; 235d: 7b
    ld [hl], a                    ; 235e: 77

.done:
    ret                           ; 235f: c9

.full:
    nop                           ; 2360: 00       | all 9 slots busy: SFX dropped
    jp .done                      ; 2361: c3 5f 23

; =============================================================================
; Snd_StartSong
;   in:  HL = song header:   db nTracks   /   dw track0, track1, ... (n <= 9)
; =============================================================================
Snd_StartSong:
    push hl                       ; 2364: e5
    push de                       ; 2365: d5
    call Snd_Reset                ; 2366: cd d8 23 | stop everything first
    pop de                        ; 2369: d1
    pop hl                        ; 236a: e1
    ld a, l                       ; 236b: 7d
    ld [wSnd_SongHeader], a       ; 236c: ea 38 de | remember header (for D9/DB restart, E3 loop)
    ld a, h                       ; 236f: 7c
    ld [wSnd_SongHeader+1], a     ; 2370: ea 39 de
    ld a, e                       ; 2373: 7b
    ld [wSnd_SongDE], a           ; 2374: ea 3a de | remember DE (only used for restarts)
    ld [wSnd_InstrTable], a       ; 2377: ea ad de | DE also copied here - never read in BO (vestige of TG-style instrument table)
    ld a, d                       ; 237a: 7a
    ld [wSnd_SongDE+1], a         ; 237b: ea 3b de
    ld [wSnd_InstrTable+1], a     ; 237e: ea ae de
    ld a, [hl+]                   ; 2381: 2a       | header byte 0 = number of tracks
    ld [wSnd_NumTracks], a        ; 2382: ea 50 de
    ld b, a                       ; 2385: 47
    ld de, wSnd_TrackPtr          ; 2386: 11 51 de | copy N track start pointers

.copyPtrs:
    ld a, [hl+]                   ; 2389: 2a
    ld [de], a                    ; 238a: 12
    inc de                        ; 238b: 13
    ld a, [hl+]                   ; 238c: 2a
    ld [de], a                    ; 238d: 12
    inc de                        ; 238e: 13
    dec b                         ; 238f: 05
    jr nz, .copyPtrs              ; 2390: 20 f7
    ld a, [wSnd_NumTracks]        ; 2392: fa 50 de
    ld b, a                       ; 2395: 47
    xor a                         ; 2396: af
    ld hl, wSnd_TrackWait         ; 2397: 21 63 de | zero N wait counters

.clrWait:
    ld [hl+], a                   ; 239a: 22
    ld [hl+], a                   ; 239b: 22
    dec b                         ; 239c: 05
    jr nz, .clrWait               ; 239d: 20 fb
    ld a, [wSnd_NumTracks]        ; 239f: fa 50 de
    ld b, a                       ; 23a2: 47
    xor a                         ; 23a3: af
    ld hl, wSnd_TrackNoteParam    ; 23a4: 21 7e de | zero N note params

.clrParam:
    ld [hl+], a                   ; 23a7: 22
    ld [hl+], a                   ; 23a8: 22
    dec b                         ; 23a9: 05
    jr nz, .clrParam              ; 23aa: 20 fb
    ld a, $60                     ; 23ac: 3e 60    | "tempo" = $60 (never read by this driver)
    ld [wSnd_Tempo], a            ; 23ae: ea af de
    ld a, $ff                     ; 23b1: 3e ff    | APU on
    ldh [rNR52], a                ; 23b3: e0 26
    ld a, $77                     ; 23b5: 3e 77    | master volume L=7 R=7
    ldh [rNR50], a                ; 23b7: e0 24
    ld a, $ff                     ; 23b9: 3e ff    | all channels to both speakers
    ldh [rNR51], a                ; 23bb: e0 25
    ld a, $01                     ; 23bd: 3e 01    | driver enabled flag
    ld [wSnd_Enabled], a          ; 23bf: ea 36 de
    ret                           ; 23c2: c9

; Small enable/disable/APU helpers
Snd_Disable:
    xor a                         ; 23c3: af       | (unreferenced) clear enabled flag
    ld [wSnd_Enabled], a          ; 23c4: ea 36 de
    ret                           ; 23c7: c9

Snd_Enable:
    ld a, $01                     ; 23c8: 3e 01    | (unreferenced) set enabled flag
    ld [wSnd_Enabled], a          ; 23ca: ea 36 de
    ret                           ; 23cd: c9

Snd_APUOff:
    ld a, $00                     ; 23ce: 3e 00
    ldh [rNR52], a                ; 23d0: e0 26
    ret                           ; 23d2: c9

Snd_APUOn:
    ld a, $ff                     ; 23d3: 3e ff    | (unreferenced)
    ldh [rNR52], a                ; 23d5: e0 26
    ret                           ; 23d7: c9

; Snd_Reset: stop all tracks, clear channel ownership (song-end command DA)
Snd_Reset:
    xor a                         ; 23d8: af
    ld [wSnd_Enabled], a          ; 23d9: ea 36 de
    ld [wSnd_Unused_B0], a        ; 23dc: ea b0 de
    ld bc, $0008                  ; 23df: 01 08 00 | 9 track slots (8..0)

.clrTracks:
    xor a                         ; 23e2: af
    ld hl, wSnd_TrackPtr          ; 23e3: 21 51 de
    add hl, bc                    ; 23e6: 09
    add hl, bc                    ; 23e7: 09
    ld [hl+], a                   ; 23e8: 22
    ld [hl], a                    ; 23e9: 77
    dec bc                        ; 23ea: 0b
    ld a, c                       ; 23eb: 79
    inc a                         ; 23ec: 3c
    jr nz, .clrTracks             ; 23ed: 20 f3
    xor a                         ; 23ef: af
    ld bc, $0004                  ; 23f0: 01 04 00
    ld hl, wSnd_Unused3C          ; 23f3: 21 3c de | clear 4 bytes (never used elsewhere - see notes)

.clr3C:
    ld [hl+], a                   ; 23f6: 22
    dec b                         ; 23f7: 05
    jr nz, .clr3C                 ; 23f8: 20 fc
    ld bc, $0004                  ; 23fa: 01 04 00
    ld hl, wSnd_Unused40          ; 23fd: 21 40 de | clear 4 bytes (never used elsewhere)

.clr40:
    ld [hl+], a                   ; 2400: 22
    dec b                         ; 2401: 05
    jr nz, .clr40                 ; 2402: 20 fc
    ld bc, $0004                  ; 2404: 01 04 00
    ld hl, wSnd_ChanTimer         ; 2407: 21 4c de | clear 4 channel hold timers

.clrTimer:
    ld [hl+], a                   ; 240a: 22
    dec b                         ; 240b: 05
    jr nz, .clrTimer              ; 240c: 20 fc
    ld bc, $0004                  ; 240e: 01 04 00
    ld hl, wSnd_ChanPriority      ; 2411: 21 48 de | clear 4 channel priorities

.clrPrio:
    ld [hl+], a                   ; 2414: 22
    dec b                         ; 2415: 05
    jr nz, .clrPrio               ; 2416: 20 fc
    ret                           ; 2418: c9

; Snd_KillTrack: BC = track (command EA)
Snd_KillTrack:
    ld hl, wSnd_TrackPtr          ; 2419: 21 51 de | BC = track index; clear its pointer
    add hl, bc                    ; 241c: 09
    add hl, bc                    ; 241d: 09
    ld a, $00                     ; 241e: 3e 00
    ld [hl+], a                   ; 2420: 22
    ld [hl], a                    ; 2421: 77
    ret                           ; 2422: c9

; =============================================================================
; Snd_Update  - called once per frame from the VBlank handler ($01A9)
; =============================================================================
Snd_Update:
    ld a, [wSnd_Lock]             ; 2423: fa 34 de | mid-reset? skip this frame
    or a                          ; 2426: b7
    ret nz                        ; 2427: c0
    ld a, [wROMBank]              ; 2428: fa 21 de | save main bank, switch to sound bank
    ld [wSnd_SavedBankA], a       ; 242b: ea 23 de
    ld a, [wSnd_Bank]             ; 242e: fa 35 de
    ld [wROMBank], a              ; 2431: ea 21 de
    ld [MBC_ROMB], a              ; 2434: ea 00 21
    ld a, $04                     ; 2437: 3e 04    | 4 hardware channels: 3..0
    dec a                         ; 2439: 3d
    ld c, a                       ; 243a: 4f
    ld b, $00                     ; 243b: 06 00

.chanLoop:
    push bc                       ; 243d: c5
    call Snd_TickChanTimer        ; 243e: cd 61 24
    pop bc                        ; 2441: c1
    dec c                         ; 2442: 0d
    ld a, c                       ; 2443: 79
    inc a                         ; 2444: 3c
    jr nz, .chanLoop              ; 2445: 20 f6
    ld a, $09                     ; 2447: 3e 09    | 9 tracks: 8..0 (fixed - wSnd_NumTracks is ignored)
    dec a                         ; 2449: 3d
    ld c, a                       ; 244a: 4f
    ld b, $00                     ; 244b: 06 00

.trackLoop:
    push bc                       ; 244d: c5
    call Snd_UpdateTrack          ; 244e: cd 7b 24
    pop bc                        ; 2451: c1
    dec c                         ; 2452: 0d
    ld a, c                       ; 2453: 79
    inc a                         ; 2454: 3c
    jr nz, .trackLoop             ; 2455: 20 f6
    ld a, [wSnd_SavedBankA]       ; 2457: fa 23 de | restore bank
    ld [wROMBank], a              ; 245a: ea 21 de
    ld [MBC_ROMB], a              ; 245d: ea 00 21
    ret                           ; 2460: c9

; Snd_TickChanTimer: BC = hardware channel 0-3
Snd_TickChanTimer:
    ld hl, wSnd_ChanTimer         ; 2461: 21 4c de | channel hold timer
    add hl, bc                    ; 2464: 09
    ld a, [hl]                    ; 2465: 7e
    or a                          ; 2466: b7
    jr z, .ret                    ; 2467: 28 09
    dec [hl]                      ; 2469: 35       | count down; at 0 the channel is released
    jr nz, .ret                   ; 246a: 20 06
    ld hl, wSnd_ChanPriority      ; 246c: 21 48 de | priority 0 = any track may take the channel
    add hl, bc                    ; 246f: 09
    xor a                         ; 2470: af
    ld [hl], a                    ; 2471: 77

.ret:
    ret                           ; 2472: c9

Snd_NRx2Regs:
    db $12, $ff, $17, $ff, $1c, $ff, $21, $ff ; 2473 | (unreferenced) dw rNR12, rNR22, rNR32, rNR42

; =============================================================================
; Snd_UpdateTrack  BC = track index 0-8
; =============================================================================
Snd_UpdateTrack:
    ld hl, wSnd_TrackPtr          ; 247b: 21 51 de | track pointer
    add hl, bc                    ; 247e: 09
    add hl, bc                    ; 247f: 09
    ld a, [hl+]                   ; 2480: 2a
    or [hl]                       ; 2481: b6
    jp z, .ret                    ; 2482: ca 32 25 | 0 = track inactive
    ld hl, wSnd_TrackWait+1       ; 2485: 21 64 de | 16-bit wait counter (frames)
    add hl, bc                    ; 2488: 09
    add hl, bc                    ; 2489: 09
    ld a, [hl-]                   ; 248a: 3a
    or [hl]                       ; 248b: b6
    jr z, .nextEvent              ; 248c: 28 06
    dec [hl]                      ; 248e: 35       | wait != 0: decrement (16-bit) and exit
    ld a, [hl+]                   ; 248f: 2a
    inc a                         ; 2490: 3c
    ret nz                        ; 2491: c0
    dec [hl]                      ; 2492: 35
    ret                           ; 2493: c9

.nextEvent:
    ld hl, wSnd_TrackPtr          ; 2494: 21 51 de
    add hl, bc                    ; 2497: 09
    add hl, bc                    ; 2498: 09
    ld a, [hl+]                   ; 2499: 2a
    ld h, [hl]                    ; 249a: 66
    ld l, a                       ; 249b: 6f
    call Snd_ReadEvent            ; 249c: cd 33 25 | parse event at the stream pointer
    ld hl, wSnd_TrackEvent        ; 249f: 21 75 de | event byte just parsed
    add hl, bc                    ; 24a2: 09
    ld a, [hl]                    ; 24a3: 7e
    cp $d9                        ; 24a4: fe d9    | < $D9 = note
    jr nc, .command               ; 24a6: 30 05
    call Snd_NoteOn               ; 24a8: cd e4 25
    jr .readDelta                 ; 24ab: 18 6d

.command:
    cp $dc                        ; 24ad: fe dc
    jp z, .cmdDC_Instrument       ; 24af: ca 10 25
    cp $dd                        ; 24b2: fe dd
    jr z, .cmdDD_Tempo            ; 24b4: 28 5f
    cp $da                        ; 24b6: fe da
    jp z, Snd_Reset               ; 24b8: ca d8 23
    cp $d9                        ; 24bb: fe d9
    jp z, .cmdD9_RestartSong      ; 24bd: ca fd 24
    cp $e3                        ; 24c0: fe e3
    jp z, .cmdE3_LoopTrack        ; 24c2: ca d9 24
    cp $ea                        ; 24c5: fe ea
    jp z, .cmdEA_EndTrack         ; 24c7: ca d3 24
    cp $db                        ; 24ca: fe db
    jp z, .cmdD9_RestartSong      ; 24cc: ca fd 24
    nop                           ; 24cf: 00       | DE/DF/E2 and anything else end up here
    jp Snd_BadCommand             ; 24d0: c3 f9 26

.cmdEA_EndTrack:
    call Snd_KillTrack            ; 24d3: cd 19 24
    jp .ret                       ; 24d6: c3 32 25

.cmdE3_LoopTrack:
    ld a, [wSnd_SongHeader]       ; 24d9: fa 38 de | E3: restart THIS track from its header pointer
    ld l, a                       ; 24dc: 6f
    ld a, [wSnd_SongHeader+1]     ; 24dd: fa 39 de
    ld h, a                       ; 24e0: 67
    inc hl                        ; 24e1: 23
    add hl, bc                    ; 24e2: 09
    add hl, bc                    ; 24e3: 09
    ld a, [hl+]                   ; 24e4: 2a
    ld [wSnd_TmpPtr], a           ; 24e5: ea b9 de
    ld a, [hl-]                   ; 24e8: 3a
    ld [wSnd_TmpPtr+1], a         ; 24e9: ea ba de
    ld hl, wSnd_TrackPtr          ; 24ec: 21 51 de
    add hl, bc                    ; 24ef: 09
    add hl, bc                    ; 24f0: 09
    ld a, [wSnd_TmpPtr]           ; 24f1: fa b9 de
    ld [hl], a                    ; 24f4: 77
    inc hl                        ; 24f5: 23
    ld a, [wSnd_TmpPtr+1]         ; 24f6: fa ba de
    ld [hl], a                    ; 24f9: 77
    jp .readDelta                 ; 24fa: c3 1a 25

.cmdD9_RestartSong:
    ld a, [wSnd_SongHeader]       ; 24fd: fa 38 de | D9/DB: restart whole song
    ld l, a                       ; 2500: 6f
    ld a, [wSnd_SongHeader+1]     ; 2501: fa 39 de
    ld h, a                       ; 2504: 67
    ld a, [wSnd_SongDE]           ; 2505: fa 3a de
    ld e, a                       ; 2508: 5f
    ld a, [wSnd_SongDE+1]         ; 2509: fa 3b de
    ld d, a                       ; 250c: 57
    jp Snd_StartSong              ; 250d: c3 64 23

.cmdDC_Instrument:
    call Snd_SetInstrument        ; 2510: cd a5 25
    jr .readDelta                 ; 2513: 18 05

.cmdDD_Tempo:
    call Snd_SetTempo             ; 2515: cd f2 26
    jr .readDelta                 ; 2518: 18 00

.readDelta:
    ld hl, wSnd_TrackPtr          ; 251a: 21 51 de | peek the delta-time that precedes the next event
    add hl, bc                    ; 251d: 09
    add hl, bc                    ; 251e: 09
    ld a, [hl+]                   ; 251f: 2a
    ld h, [hl]                    ; 2520: 66
    ld l, a                       ; 2521: 6f
    call Snd_ReadVarLen           ; 2522: cd 09 27
    ld a, d                       ; 2525: 7a
    or e                          ; 2526: b3
    jr z, .storeWait              ; 2527: 28 01    | wait = delta-1 (this frame counts)
    dec de                        ; 2529: 1b

.storeWait:
    ld hl, wSnd_TrackWait         ; 252a: 21 63 de
    add hl, bc                    ; 252d: 09
    add hl, bc                    ; 252e: 09
    ld a, e                       ; 252f: 7b
    ld [hl+], a                   ; 2530: 22
    ld [hl], d                    ; 2531: 72

.ret:
    ret                           ; 2532: c9

; =============================================================================
; Snd_ReadEvent  HL = stream pointer, BC = track
;   Stream = [delta][event][args...] [delta][event]...  The delta in front of
;   the CURRENT event was already consumed (it set the wait), so skip it.
; =============================================================================
Snd_ReadEvent:
    call Snd_ReadVarLen           ; 2533: cd 09 27 | skip the delta-time (already loaded into the wait counter)
    ld a, [hl]                    ; 2536: 7e       | event byte
    push hl                       ; 2537: e5
    ld hl, wSnd_TrackEvent        ; 2538: 21 75 de
    add hl, bc                    ; 253b: 09
    ld [hl], a                    ; 253c: 77
    pop hl                        ; 253d: e1
    inc hl                        ; 253e: 23       | point past event byte
    cp $d9                        ; 253f: fe d9    | < $D9: note event
    jr c, .note                   ; 2541: 38 44
    cp $d9                        ; 2543: fe d9    | no-argument commands: D9 DA DB E3 EA
    jr z, .savePtr                ; 2545: 28 35
    cp $da                        ; 2547: fe da
    jr z, .savePtr                ; 2549: 28 31
    cp $db                        ; 254b: fe db
    jr z, .savePtr                ; 254d: 28 2d
    cp $e3                        ; 254f: fe e3
    jr z, .savePtr                ; 2551: 28 29
    cp $ea                        ; 2553: fe ea
    jr z, .savePtr                ; 2555: 28 25
    cp $dc                        ; 2557: fe dc    | DC/DF: 2-byte arg
    jr z, .twoArgs                ; 2559: 28 13
    cp $dd                        ; 255b: fe dd    | DD/DE/E2: 1-byte arg
    jr z, .oneArg                 ; 255d: 28 19
    cp $de                        ; 255f: fe de
    jr z, .oneArg                 ; 2561: 28 15
    cp $e2                        ; 2563: fe e2
    jr z, .oneArg                 ; 2565: 28 11
    cp $df                        ; 2567: fe df
    jr z, .twoArgs                ; 2569: 28 03
    jp Snd_BadCommand             ; 256b: c3 f9 26 | unknown command -> restart song

.twoArgs:
    ld a, [hl+]                   ; 256e: 2a
    ld [wSnd_EventArg], a         ; 256f: ea ab de
    ld a, [hl+]                   ; 2572: 2a
    ld [wSnd_EventArg+1], a       ; 2573: ea ac de
    jr .savePtr                   ; 2576: 18 04

.oneArg:
    ld a, [hl+]                   ; 2578: 2a
    ld [wSnd_EventArg], a         ; 2579: ea ab de

.savePtr:
    ld d, h                       ; 257c: 54
    ld e, l                       ; 257d: 5d
    ld hl, wSnd_TrackPtr          ; 257e: 21 51 de
    add hl, bc                    ; 2581: 09
    add hl, bc                    ; 2582: 09
    ld a, e                       ; 2583: 7b
    ld [hl+], a                   ; 2584: 22
    ld [hl], d                    ; 2585: 72
    ret                           ; 2586: c9

.note:
    bit 7, a                      ; 2587: cb 7f    | bit 7 of the note byte = an extra byte follows
    jr z, .noteParam              ; 2589: 28 04
    ld a, [hl+]                   ; 258b: 2a       | (read into EventArg, never used for notes)
    ld [wSnd_EventArg], a         ; 258c: ea ab de

.noteParam:
    call Snd_ReadVarLen           ; 258f: cd 09 27 | note parameter (var-length)
    push hl                       ; 2592: e5
    ld hl, wSnd_TrackNoteParam    ; 2593: 21 7e de | -> TrackNoteParam
    add hl, bc                    ; 2596: 09
    add hl, bc                    ; 2597: 09
    ld a, e                       ; 2598: 7b
    ld [hl+], a                   ; 2599: 22
    ld [hl], d                    ; 259a: 72
    pop de                        ; 259b: d1
    ld hl, wSnd_TrackPtr          ; 259c: 21 51 de
    add hl, bc                    ; 259f: 09
    add hl, bc                    ; 25a0: 09
    ld a, e                       ; 25a1: 7b
    ld [hl+], a                   ; 25a2: 22
    ld [hl], d                    ; 25a3: 72
    ret                           ; 25a4: c9

; Snd_SetInstrument (command DC ptr16)
Snd_SetInstrument:
    ld hl, wSnd_TrackInstr        ; 25a5: 21 90 de | BC = track; EventArg = instrument pointer
    add hl, bc                    ; 25a8: 09
    add hl, bc                    ; 25a9: 09
    ld a, [wSnd_EventArg]         ; 25aa: fa ab de
    ld [hl+], a                   ; 25ad: 22
    ld a, [wSnd_EventArg+1]       ; 25ae: fa ac de
    ld [hl-], a                   ; 25b1: 32
    ld a, [wSnd_EventArg]         ; 25b2: fa ab de
    ld e, a                       ; 25b5: 5f
    ld a, [wSnd_EventArg+1]       ; 25b6: fa ac de
    ld d, a                       ; 25b9: 57
    ld a, $04                     ; 25ba: 3e 04    | instrument byte 4 = transpose
    add e                         ; 25bc: 83
    ld e, a                       ; 25bd: 5f
    jr nc, .transpose             ; 25be: 30 01
    inc d                         ; 25c0: 14

.transpose:
    ld hl, wSnd_TrackTranspose    ; 25c1: 21 a2 de
    add hl, bc                    ; 25c4: 09
    ld a, [de]                    ; 25c5: 1a
    ld [hl], a                    ; 25c6: 77
    ld a, c                       ; 25c7: 79       | track 2 only (track index, NOT channel!)
    cp $02                        ; 25c8: fe 02
    ret nz                        ; 25ca: c0
    xor a                         ; 25cb: af       | wave ch off
    ldh [rNR30], a                ; 25cc: e0 1a
    ld hl, Snd_WaveTable          ; 25ce: 21 17 27 | upload 16-byte wave
    ld de, _AUD3WAVERAM           ; 25d1: 11 30 ff

.copyWave:
    ld a, [hl+]                   ; 25d4: 2a
    ld [de], a                    ; 25d5: 12
    inc e                         ; 25d6: 1c
    ld a, e                       ; 25d7: 7b
    cp $40                        ; 25d8: fe 40
    jr nz, .copyWave              ; 25da: 20 f8
    ld a, $80                     ; 25dc: 3e 80    | wave ch on
    ldh [rNR30], a                ; 25de: e0 1a
    xor a                         ; 25e0: af       | NR34 = 0
    ldh [rNR34], a                ; 25e1: e0 1e
    ret                           ; 25e3: c9

; =============================================================================
; Snd_NoteOn  BC = track.  Instrument record (6 bytes, BO format):
;   +0 hw channel (0=CH1 1=CH2 2=CH3 3=CH4)   +1 NRx1 duty/length
;   +2 priority                                +3 NR10 sweep (CH1 only)
;   +4 transpose (signed semitones)            +5 NRx2 initial volume (hi nibble)
; =============================================================================
Snd_NoteOn:
    push bc                       ; 25e4: c5
    ld hl, wSnd_TrackInstr        ; 25e5: 21 90 de | current instrument pointer
    add hl, bc                    ; 25e8: 09
    add hl, bc                    ; 25e9: 09
    ld a, [hl+]                   ; 25ea: 2a
    ld [wSnd_CurInstr], a         ; 25eb: ea b4 de
    ld h, [hl]                    ; 25ee: 66
    ld l, a                       ; 25ef: 6f
    ld a, h                       ; 25f0: 7c
    ld [wSnd_CurInstr+1], a       ; 25f1: ea b5 de
    push hl                       ; 25f4: e5
    ld de, $0002                  ; 25f5: 11 02 00 | instr +2 = priority
    add hl, de                    ; 25f8: 19
    ld a, [hl]                    ; 25f9: 7e
    pop hl                        ; 25fa: e1
    push af                       ; 25fb: f5
    ld de, $0000                  ; 25fc: 11 00 00 | instr +0 = hardware channel (0-3)
    add hl, de                    ; 25ff: 19
    ld a, [hl]                    ; 2600: 7e
    ld d, $00                     ; 2601: 16 00
    ld e, a                       ; 2603: 5f
    pop af                        ; 2604: f1
    ld hl, wSnd_ChanPriority      ; 2605: 21 48 de | compare against priority of whoever holds the channel
    add hl, de                    ; 2608: 19
    cp [hl]                       ; 2609: be
    jr nc, .claim                 ; 260a: 30 02    | new priority >= current: take channel
    pop bc                        ; 260c: c1       | lower priority: note dropped
    ret                           ; 260d: c9

.claim:
    ld [hl], a                    ; 260e: 77       | channel now owned at this priority
    ld hl, wSnd_TrackNoteParam    ; 260f: 21 7e de | note param -> NRx2 envelope bits:
    add hl, bc                    ; 2612: 09
    add hl, bc                    ; 2613: 09
    ld a, [hl]                    ; 2614: 7e
    and $07                       ; 2615: e6 07    |   sweep pace = (p & 7)/2 + 1
    sra a                         ; 2617: cb 2f
    inc a                         ; 2619: 3c
    ld [wSnd_EnvBits], a          ; 261a: ea bb de
    ld a, [hl]                    ; 261d: 7e
    and $08                       ; 261e: e6 08    |   direction = p bit 3
    push hl                       ; 2620: e5
    ld hl, wSnd_EnvBits           ; 2621: 21 bb de
    or [hl]                       ; 2624: b6
    pop hl                        ; 2625: e1
    ld [wSnd_EnvBits], a          ; 2626: ea bb de
    ld a, [hl]                    ; 2629: 7e       | hold timer = (p + 1) * 4 frames
    inc a                         ; 262a: 3c
    sla a                         ; 262b: cb 27
    sla a                         ; 262d: cb 27
    ld hl, wSnd_ChanTimer         ; 262f: 21 4c de
    add hl, de                    ; 2632: 19
    ld [hl], a                    ; 2633: 77
    ld hl, wSnd_TrackEvent        ; 2634: 21 75 de | raw note byte
    add hl, bc                    ; 2637: 09
    ld a, [hl+]                   ; 2638: 2a
    ld [wSnd_NoteByte], a         ; 2639: ea b1 de
    ld a, e                       ; 263c: 7b
    cp $03                        ; 263d: fe 03    | noise channel: no frequency lookup
    jr z, .dispatch               ; 263f: 28 1b
    ld a, [wSnd_NoteByte]         ; 2641: fa b1 de | index = note + transpose
    and $7f                       ; 2644: e6 7f
    ld hl, wSnd_TrackTranspose    ; 2646: 21 a2 de
    add hl, bc                    ; 2649: 09
    add [hl]                      ; 264a: 86
    ld hl, Snd_FreqTable          ; 264b: 21 2b 27 | Snd_FreqTable
    add a                         ; 264e: 87
    add l                         ; 264f: 85
    ld l, a                       ; 2650: 6f
    jr nc, .gotFreq               ; 2651: 30 01
    inc h                         ; 2653: 24

.gotFreq:
    ld a, [hl+]                   ; 2654: 2a
    ld [wSnd_FreqLo], a           ; 2655: ea b7 de
    ld a, [hl-]                   ; 2658: 3a
    ld [wSnd_FreqHi], a           ; 2659: ea b8 de

.dispatch:
    ld hl, wSnd_CurInstr          ; 265c: 21 b4 de
    ld a, [hl+]                   ; 265f: 2a
    ld h, [hl]                    ; 2660: 66
    ld l, a                       ; 2661: 6f
    ld a, [hl]                    ; 2662: 7e
    ld c, a                       ; 2663: 4f
    ld b, $00                     ; 2664: 06 00
    push hl                       ; 2666: e5
    ld a, c                       ; 2667: 79       | switch on hardware channel
    or a                          ; 2668: b7
    jr z, .ch1                    ; 2669: 28 0e
    dec a                         ; 266b: 3d
    jr z, .ch2                    ; 266c: 28 36
    dec a                         ; 266e: 3d
    jr z, .ch3                    ; 266f: 28 55
    dec a                         ; 2671: 3d
    jr z, .ch4                    ; 2672: 28 68
    pop bc                        ; 2674: c1       | channel > 3 -> restart song
    pop bc                        ; 2675: c1
    jp Snd_BadCommand             ; 2676: c3 f9 26

.ch1:
    ld bc, $0005                  ; 2679: 01 05 00
    add hl, bc                    ; 267c: 09
    ld a, [wSnd_EnvBits]          ; 267d: fa bb de | NR12 = env bits | instr +5 (initial volume)
    or [hl]                       ; 2680: b6
    ldh [rNR12], a                ; 2681: e0 12
    pop hl                        ; 2683: e1
    push hl                       ; 2684: e5
    ld bc, $0003                  ; 2685: 01 03 00 | NR10 = instr +3 (sweep)
    add hl, bc                    ; 2688: 09
    ld a, [hl]                    ; 2689: 7e
    ldh [rNR10], a                ; 268a: e0 10
    pop hl                        ; 268c: e1
    push hl                       ; 268d: e5
    ld bc, $0001                  ; 268e: 01 01 00 | NR11 = instr +1 (duty)
    add hl, bc                    ; 2691: 09
    ld a, [hl]                    ; 2692: 7e
    ldh [rNR11], a                ; 2693: e0 11
    ld a, [wSnd_FreqLo]           ; 2695: fa b7 de | freq
    ldh [rNR13], a                ; 2698: e0 13
    ld a, [wSnd_FreqHi]           ; 269a: fa b8 de
    set 7, a                      ; 269d: cb ff    | trigger
    ldh [rNR14], a                ; 269f: e0 14
    jp .done                      ; 26a1: c3 ef 26

.ch2:
    ld bc, $0005                  ; 26a4: 01 05 00
    add hl, bc                    ; 26a7: 09
    ld a, [wSnd_EnvBits]          ; 26a8: fa bb de | NR22 = env bits | instr +5
    or [hl]                       ; 26ab: b6
    ldh [rNR22], a                ; 26ac: e0 17
    pop hl                        ; 26ae: e1
    push hl                       ; 26af: e5
    ld bc, $0001                  ; 26b0: 01 01 00 | NR21 = instr +1 (duty)
    add hl, bc                    ; 26b3: 09
    ld a, [hl]                    ; 26b4: 7e
    ldh [rNR21], a                ; 26b5: e0 16
    ld a, [wSnd_FreqLo]           ; 26b7: fa b7 de | freq
    ldh [rNR23], a                ; 26ba: e0 18
    ld a, [wSnd_FreqHi]           ; 26bc: fa b8 de
    set 7, a                      ; 26bf: cb ff    | trigger
    ldh [rNR24], a                ; 26c1: e0 19
    jp .done                      ; 26c3: c3 ef 26

.ch3:
    jp .done                      ; 26c6: c3 ef 26 | wave channel note-on is DISABLED: jumps straight out

.ch3_dead:
    ld a, $20                     ; 26c9: 3e 20    | --- unreachable: TG-style CH3 note-on (see Top Gun $28F4) ---
    ldh [rNR32], a                ; 26cb: e0 1c
    ld a, [hl]                    ; 26cd: 7e
    ldh [rNR33], a                ; 26ce: e0 1d
    inc hl                        ; 26d0: 23
    ld a, d                       ; 26d1: 7a
    adc [hl]                      ; 26d2: 8e
    ldh [rNR34], a                ; 26d3: e0 1e
    set 7, a                      ; 26d5: cb ff
    ldh [rNR34], a                ; 26d7: e0 1e
    jp .done                      ; 26d9: c3 ef 26

.ch4:
    ld bc, $0005                  ; 26dc: 01 05 00
    add hl, bc                    ; 26df: 09
    ld a, [wSnd_EnvBits]          ; 26e0: fa bb de | NR42 = env bits | instr +5
    or [hl]                       ; 26e3: b6
    ldh [rNR42], a                ; 26e4: e0 21
    ld a, [wSnd_NoteByte]         ; 26e6: fa b1 de | NR43 = raw note byte (noise poly counter)
    ldh [rNR43], a                ; 26e9: e0 22
    ld a, $80                     ; 26eb: 3e 80    | trigger
    ldh [rNR44], a                ; 26ed: e0 23

.done:
    pop bc                        ; 26ef: c1       | discard instr ptr
    pop bc                        ; 26f0: c1       | restore BC (track)
    ret                           ; 26f1: c9

; Snd_SetTempo (command DD n) - vestigial
Snd_SetTempo:
    ld a, [wSnd_EventArg]         ; 26f2: fa ab de | DD: store tempo - nothing reads it
    ld [wSnd_Tempo], a            ; 26f5: ea af de
    ret                           ; 26f8: c9

; Snd_BadCommand: unknown event / bad channel -> silence and restart song
Snd_BadCommand:
    ld a, [wSnd_SongHeader]       ; 26f9: fa 38 de | reload song header
    ld l, a                       ; 26fc: 6f
    ld a, [wSnd_SongHeader+1]     ; 26fd: fa 39 de
    ld h, a                       ; 2700: 67
    push hl                       ; 2701: e5
    call Snd_APUOff               ; 2702: cd ce 23 | APU off
    pop hl                        ; 2705: e1
    jp Snd_StartSong              ; 2706: c3 64 23 | restart song (DE = whatever is in DE)

; Snd_ReadVarLen: MIDI-style length.  < $80 : one byte.
;   $80-$FF : 2 bytes, value = rrca(b & $7F) + b2  -> correct only for b = $81
;   (i.e. values 128-255), which is all the converter ever emits.
Snd_ReadVarLen:
    ld d, $00                     ; 2709: 16 00    | result in DE (D always 0)
    ld a, [hl+]                   ; 270b: 2a
    bit 7, a                      ; 270c: cb 7f    | bit 7 set: two-byte form
    jr z, .done                   ; 270e: 28 05
    and $7f                       ; 2710: e6 7f    | (b & $7F) rotated right ...
    rrca                          ; 2712: 0f
    add [hl]                      ; 2713: 86       | ... + next byte (8-bit! max 255)
    inc hl                        ; 2714: 23

.done:
    ld e, a                       ; 2715: 5f
    ret                           ; 2716: c9

; Wave pattern loaded into CH3 wave RAM by Snd_SetInstrument (track 2)
Snd_WaveTable:
    db $00, $00, $00, $00, $00, $08, $ff, $ff ; 2717
    db $ff, $ff, $ff, $ff, $ff, $ff, $a5, $00 ; 271f

; (unreferenced) NR32 output levels: mute, 25%, 50%, 100% - identical bytes in Top Gun
Snd_WaveVolTable:
    db $00, $60, $40, $20         ; 2727

; Frequency table: 118 x dw, starting at C2 ($002C).  Byte-identical to
; Top Gun: Guts & Glory $29A7.
Snd_FreqTable:
    dw $002c                      ; 272b | n=  0 C  2  65.4 Hz
    dw $009d                      ; 272d | n=  1 C# 2  69.3 Hz
    dw $0108                      ; 272f | n=  2 D  2  73.5 Hz
    dw $016d                      ; 2731 | n=  3 D# 2  77.9 Hz
    dw $01cc                      ; 2733 | n=  4 E  2  82.5 Hz
    dw $0225                      ; 2735 | n=  5 F  2  87.4 Hz
    dw $027a                      ; 2737 | n=  6 F# 2  92.7 Hz
    dw $02ca                      ; 2739 | n=  7 G  2  98.3 Hz
    dw $0315                      ; 273b | n=  8 G# 2  104.1 Hz
    dw $035c                      ; 273d | n=  9 A  2  110.3 Hz
    dw $039f                      ; 273f | n= 10 A# 2  116.9 Hz
    dw $03de                      ; 2741 | n= 11 B  2  123.9 Hz
    dw $041a                      ; 2743 | n= 12 C  3  131.3 Hz
    dw $0452                      ; 2745 | n= 13 C# 3  139.1 Hz
    dw $0487                      ; 2747 | n= 14 D  3  147.4 Hz
    dw $04b9                      ; 2749 | n= 15 D# 3  156.2 Hz
    dw $04e9                      ; 274b | n= 16 E  3  165.7 Hz
    dw $0515                      ; 274d | n= 17 F  3  175.5 Hz
    dw $053f                      ; 274f | n= 18 F# 3  185.9 Hz
    dw $0567                      ; 2751 | n= 19 G  3  197.1 Hz
    dw $058d                      ; 2753 | n= 20 G# 3  209.0 Hz
    dw $05b0                      ; 2755 | n= 21 A  3  221.4 Hz
    dw $05d1                      ; 2757 | n= 22 A# 3  234.5 Hz
    dw $05f1                      ; 2759 | n= 23 B  3  248.7 Hz
    dw $060f                      ; 275b | n= 24 C  4  263.7 Hz
    dw $062b                      ; 275d | n= 25 C# 4  279.5 Hz
    dw $0645                      ; 275f | n= 26 D  4  295.9 Hz
    dw $065e                      ; 2761 | n= 27 D# 4  313.6 Hz
    dw $0676                      ; 2763 | n= 28 E  4  332.7 Hz
    dw $068c                      ; 2765 | n= 29 F  4  352.3 Hz
    dw $06a1                      ; 2767 | n= 30 F# 4  373.4 Hz
    dw $06b5                      ; 2769 | n= 31 G  4  396.0 Hz
    dw $06c7                      ; 276b | n= 32 G# 4  418.8 Hz
    dw $06d9                      ; 276d | n= 33 A  4  444.3 Hz
    dw $06ea                      ; 276f | n= 34 A# 4  471.5 Hz
    dw $06f9                      ; 2771 | n= 35 B  4  498.4 Hz
    dw $0708                      ; 2773 | n= 36 C  5  528.5 Hz
    dw $0716                      ; 2775 | n= 37 C# 5  560.1 Hz
    dw $0723                      ; 2777 | n= 38 D  5  593.1 Hz
    dw $0730                      ; 2779 | n= 39 D# 5  630.2 Hz
    dw $073c                      ; 277b | n= 40 E  5  668.7 Hz
    dw $0747                      ; 277d | n= 41 F  5  708.5 Hz
    dw $0751                      ; 277f | n= 42 F# 5  749.0 Hz
    dw $075b                      ; 2781 | n= 43 G  5  794.4 Hz
    dw $0764                      ; 2783 | n= 44 G# 5  840.2 Hz
    dw $076d                      ; 2785 | n= 45 A  5  891.6 Hz
    dw $0775                      ; 2787 | n= 46 A# 5  943.0 Hz
    dw $077d                      ; 2789 | n= 47 B  5  1000.5 Hz
    dw $0785                      ; 278b | n= 48 C  6  1065.6 Hz
    dw $078c                      ; 278d | n= 49 C# 6  1129.9 Hz
    dw $0792                      ; 278f | n= 50 D  6  1191.6 Hz
    dw $0798                      ; 2791 | n= 51 D# 6  1260.3 Hz
    dw $079e                      ; 2793 | n= 52 E  6  1337.5 Hz
    dw $07a4                      ; 2795 | n= 53 F  6  1424.7 Hz
    dw $07a9                      ; 2797 | n= 54 F# 6  1506.6 Hz
    dw $07ae                      ; 2799 | n= 55 G  6  1598.4 Hz
    dw $07b2                      ; 279b | n= 56 G# 6  1680.4 Hz
    dw $07b7                      ; 279d | n= 57 A  6  1795.5 Hz
    dw $07bb                      ; 279f | n= 58 A# 6  1899.6 Hz
    dw $07bf                      ; 27a1 | n= 59 B  6  2016.5 Hz
    dw $07c3                      ; 27a3 | n= 60 C  7  2148.7 Hz
    dw $07c6                      ; 27a5 | n= 61 C# 7  2259.9 Hz
    dw $07c9                      ; 27a7 | n= 62 D  7  2383.1 Hz
    dw $07cc                      ; 27a9 | n= 63 D# 7  2520.6 Hz
    dw $07cf                      ; 27ab | n= 64 E  7  2674.9 Hz
    dw $07d2                      ; 27ad | n= 65 F  7  2849.4 Hz
    dw $07d5                      ; 27af | n= 66 F# 7  3048.2 Hz
    dw $07d7                      ; 27b1 | n= 67 G  7  3196.9 Hz
    dw $07d9                      ; 27b3 | n= 68 G# 7  3360.8 Hz
    dw $07dc                      ; 27b5 | n= 69 A  7  3640.9 Hz
    dw $07de                      ; 27b7 | n= 70 A# 7  3855.1 Hz
    dw $07e0                      ; 27b9 | n= 71 B  7  4096.0 Hz
    dw $07e1                      ; 27bb | n= 72 C  8  4228.1 Hz
    dw $07e3                      ; 27bd | n= 73 C# 8  4519.7 Hz
    dw $07e5                      ; 27bf | n= 74 D  8  4854.5 Hz
    dw $07e6                      ; 27c1 | n= 75 D# 8  5041.2 Hz
    dw $07e8                      ; 27c3 | n= 76 E  8  5461.3 Hz
    dw $07e9                      ; 27c5 | n= 77 F  8  5698.8 Hz
    dw $07ea                      ; 27c7 | n= 78 F# 8  5957.8 Hz
    dw $07ec                      ; 27c9 | n= 79 G  8  6553.6 Hz
    dw $07ed                      ; 27cb | n= 80 G# 8  6898.5 Hz
    dw $07ee                      ; 27cd | n= 81 A  8  7281.8 Hz
    dw $07ef                      ; 27cf | n= 82 A# 8  7710.1 Hz
    dw $07f0                      ; 27d1 | n= 83 B  8  8192.0 Hz
    dw $07f1                      ; 27d3 | n= 84 C  9  8738.1 Hz
    dw $07f2                      ; 27d5 | n= 85 C# 9  9362.3 Hz
    dw $07f2                      ; 27d7 | n= 86 D  9  9362.3 Hz
    dw $07f3                      ; 27d9 | n= 87 D# 9  10082.5 Hz
    dw $07f4                      ; 27db | n= 88 E  9  10922.7 Hz
    dw $07f5                      ; 27dd | n= 89 F  9  11915.6 Hz
    dw $07f5                      ; 27df | n= 90 F# 9  11915.6 Hz
    dw $07f6                      ; 27e1 | n= 91 G  9  13107.2 Hz
    dw $07f6                      ; 27e3 | n= 92 G# 9  13107.2 Hz
    dw $07f7                      ; 27e5 | n= 93 A  9  14563.6 Hz
    dw $07f7                      ; 27e7 | n= 94 A# 9  14563.6 Hz
    dw $07f8                      ; 27e9 | n= 95 B  9  16384.0 Hz
    dw $07f8                      ; 27eb | n= 96 C  10  16384.0 Hz
    dw $07f9                      ; 27ed | n= 97 C# 10  18724.6 Hz
    dw $07f9                      ; 27ef | n= 98 D  10  18724.6 Hz
    dw $07fa                      ; 27f1 | n= 99 D# 10  21845.3 Hz
    dw $07fa                      ; 27f3 | n=100 E  10  21845.3 Hz
    dw $07fa                      ; 27f5 | n=101 F  10  21845.3 Hz
    dw $07fb                      ; 27f7 | n=102 F# 10  26214.4 Hz
    dw $07fb                      ; 27f9 | n=103 G  10  26214.4 Hz
    dw $07fb                      ; 27fb | n=104 G# 10  26214.4 Hz
    dw $07fb                      ; 27fd | n=105 A  10  26214.4 Hz
    dw $07fc                      ; 27ff | n=106 A# 10  32768.0 Hz
    dw $07fc                      ; 2801 | n=107 B  10  32768.0 Hz
    dw $07fc                      ; 2803 | n=108 C  11  32768.0 Hz
    dw $07fc                      ; 2805 | n=109 C# 11  32768.0 Hz
    dw $07fd                      ; 2807 | n=110 D  11  43690.7 Hz
    dw $07fd                      ; 2809 | n=111 D# 11  43690.7 Hz
    dw $07fd                      ; 280b | n=112 E  11  43690.7 Hz
    dw $07fd                      ; 280d | n=113 F  11  43690.7 Hz
    dw $07fd                      ; 280f | n=114 F# 11  43690.7 Hz
    dw $07fd                      ; 2811 | n=115 G  11  43690.7 Hz
    dw $07fe                      ; 2813 | n=116 G# 11  65536.0 Hz
    dw $07fe                      ; 2815 | n=117 A  11  65536.0 Hz
