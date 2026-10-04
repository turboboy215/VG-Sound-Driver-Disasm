; =============================================================================
;  Bill Elliott's NASCAR Fast Tracks (Game Boy, 1991)  -  SOUND DRIVER
;  ROM: "Bill Elliott's NASCAR Fast Tracks (U).gb"  title NASCARFASTTRACKS, lic $A4
;  Developer: Distinctive Software   Publisher: Konami
;
;  Driver code  : ROM0 $1CAB-$20BA   tables/data $20BB-$228E
;  Music data   : ROM bank $05 (song tables $4000, $5782, $66C6, $66CC)
;                 and bank $02 ($6C7E) - wSnd_Bank is set by each caller
;  Update hook  : VBlank handler calls Snd_Update at $01A9
;  Call sequence: Snd_Stop, A=0/HL=song -> Snd_LoadSong, Snd_Start
;
;  Re-assembles byte-exact with RGBDS (verified).  Each line carries the ROM
;  address and original bytes after ';'.  Text after '|' is commentary.
; -----------------------------------------------------------------------------
;  THE OLDEST FORM OF THE DRIVER FAMILY (see SoundEngine_Comparison.md)
;   * Tracker-style: 4 fixed channels, each with an ORDER LIST of 3-byte
;     entries (dw pattern, db transpose) and 2-byte PATTERN ROWS.
;     (Top Gun / Battle of Olympus / Wayne's World switched to MIDI-like
;     delta-time streams but kept the command numbers D9-DC.)
;   * Row = [note][duration]      duration bit 7 = tie into the next row
;           note $75 = rest (freq table's last entry, $07FE, is inaudible)
;         = [DA][--]  stop            = [D9][--]  next order, all channels
;         = [DB][--]  rewind song     = [DC][n]   instrument n
;         = [E0][n]   decay stage on/off for this channel
;   * Software ADSR that really drives NRx2/NR32 every frame (the later
;     Top Gun version keeps the ADSR but stubs its output).
;   * Detune per instrument; a vibrato whose accumulator is never applied.
;   * CH4 drums: a note -> NR43 map plus 6 drum records - carried over
;     almost verbatim into Top Gun.
; =============================================================================

INCLUDE "hardware.inc"

; ---- RAM used by the sound driver ----
DEF wSnd_Bank EQU $de40
DEF wSnd_Enabled EQU $de41
DEF wSnd_MusicOption EQU $de42
DEF wSnd_Unused43 EQU $de43
DEF wSnd_SongNum EQU $de44
DEF wSnd_SongEntry EQU $de45
DEF wSnd_InstrTable EQU $de47
DEF wSnd_OrderTable EQU $de4b
DEF wSnd_SongWord3 EQU $de4d
DEF wSnd_ChanInstr EQU $de53
DEF wSnd_PatTranspose EQU $de5b
DEF wSnd_OrderPos EQU $de5f
DEF wSnd_Row EQU $de63
DEF wSnd_Duration EQU $de67
DEF wSnd_TieFlag EQU $de6b
DEF wSnd_InstrTranspose EQU $de6f
DEF wSnd_DecayEnable EQU $de73
DEF wSnd_NoteDelay EQU $de77
DEF wSnd_AttackAcc EQU $de7b
DEF wSnd_DecayAcc EQU $de7f
DEF wSnd_Volume EQU $de83
DEF wSnd_Detune EQU $de87
DEF wSnd_Note EQU $de8f
DEF wSnd_VibDelay EQU $de93
DEF wSnd_VibAcc EQU $de97
DEF wSnd_VibCounter EQU $de9b

; ---- outside the driver ----
DEF MBC_ROMB EQU $2100
DEF wROMBank EQU $de22
DEF wROMBankIRQ EQU $de2b

SECTION "NASCAR Sound Driver", ROM0[$1cab]


; =============================================================================
; Snd_LoadSong   A = song number, HL = song table (bank wSnd_Bank)
;   song entry (16 bytes, only 6 used):
;     +0 dw instrument pointer table   +2 dw order table   +4 dw (unused)
; =============================================================================
Snd_LoadSong:
    ld [wSnd_SongNum], a          ; 1cab: ea 44 de | A = song number
    swap a                        ; 1cae: cb 37    | * 16 = entry size
    ld c, a                       ; 1cb0: 4f
    ld b, $00                     ; 1cb1: 06 00
    add hl, bc                    ; 1cb3: 09
    ld a, [wSnd_Bank]             ; 1cb4: fa 40 de | map in sound bank (5 or 2)
    ld [wROMBankIRQ], a           ; 1cb7: ea 2b de
    ld [MBC_ROMB], a              ; 1cba: ea 00 21
    ld a, l                       ; 1cbd: 7d       | remember entry
    ld [wSnd_SongEntry], a        ; 1cbe: ea 45 de
    ld a, h                       ; 1cc1: 7c
    ld [wSnd_SongEntry+1], a      ; 1cc2: ea 46 de
    ld a, [hl+]                   ; 1cc5: 2a       | +0 dw instrument pointer table
    ld [wSnd_InstrTable], a       ; 1cc6: ea 47 de
    ld a, [hl+]                   ; 1cc9: 2a
    ld [wSnd_InstrTable+1], a     ; 1cca: ea 48 de
    ld a, [hl+]                   ; 1ccd: 2a       | +2 dw order table (4 channel order lists)
    ld [wSnd_OrderTable], a       ; 1cce: ea 4b de
    ld a, [hl+]                   ; 1cd1: 2a
    ld [wSnd_OrderTable+1], a     ; 1cd2: ea 4c de
    ld a, [hl+]                   ; 1cd5: 2a       | +4 dw (copied, never used)
    ld [wSnd_SongWord3], a        ; 1cd6: ea 4d de
    ld a, [hl]                    ; 1cd9: 7e
    ld [wSnd_SongWord3+1], a      ; 1cda: ea 4e de
    xor a                         ; 1cdd: af       | stop playback while loading
    ld [wSnd_Enabled], a          ; 1cde: ea 41 de
    ld hl, wSnd_OrderPos          ; 1ce1: 21 5f de | clear OrderPos/Row/Duration/Tie/InstrTranspose/DecayEnable (24 bytes)
    ld b, $18                     ; 1ce4: 06 18
    xor a                         ; 1ce6: af

.clr:
    ld [hl+], a                   ; 1ce7: 22
    dec b                         ; 1ce8: 05
    jr nz, .clr                   ; 1ce9: 20 fc
    ld b, $04                     ; 1ceb: 06 04    | NoteDelay[4] = 1
    inc a                         ; 1ced: 3c

.setDelay:
    ld [hl+], a                   ; 1cee: 22
    dec b                         ; 1cef: 05
    jr nz, .setDelay              ; 1cf0: 20 fc
    ld a, [wROMBank]              ; 1cf2: fa 22 de | restore bank
    ld [wROMBankIRQ], a           ; 1cf5: ea 2b de
    ld [MBC_ROMB], a              ; 1cf8: ea 00 21
    ret                           ; 1cfb: c9

; Snd_Start: begin playback (unless music is disabled in the options)
Snd_Start:
    ld a, [wSnd_MusicOption]      ; 1cfc: fa 42 de | music switched off in options?
    or a                          ; 1cff: b7
    ret z                         ; 1d00: c8
    ld a, $01                     ; 1d01: 3e 01    | playing
    ld [wSnd_Enabled], a          ; 1d03: ea 41 de
    ld a, $ff                     ; 1d06: 3e ff    | APU on
    ldh [rNR52], a                ; 1d08: e0 26
    ld a, $77                     ; 1d0a: 3e 77    | master volume L=7 R=7
    ldh [rNR50], a                ; 1d0c: e0 24
    ld a, $ff                     ; 1d0e: 3e ff    | all channels both sides
    ldh [rNR51], a                ; 1d10: e0 25
    ret                           ; 1d12: c9

; Snd_Stop (also command DA)
Snd_Stop:
    xor a                         ; 1d13: af       | stop, APU off
    ld [wSnd_Enabled], a          ; 1d14: ea 41 de
    ldh [rNR52], a                ; 1d17: e0 26
    ret                           ; 1d19: c9

Snd_SetUnused43:
    ld [wSnd_Unused43], a         ; 1d1a: ea 43 de | (sets a byte nothing in the driver reads)
    ret                           ; 1d1d: c9

; =============================================================================
; Snd_Update - called every frame from the VBlank handler ($01A9)
;   Four fixed channels, one per hardware channel (c = 3..0).
; =============================================================================
Snd_Update:
    ld a, [wSnd_Enabled]          ; 1d1e: fa 41 de | not playing?
    or a                          ; 1d21: b7
    ret z                         ; 1d22: c8
    ld a, [wSnd_Bank]             ; 1d23: fa 40 de | map sound bank (caller restores)
    ld [MBC_ROMB], a              ; 1d26: ea 00 21
    ld bc, $0003                  ; 1d29: 01 03 00 | channels 3..0 (channel = track here)

Snd_ChannelLoop:
    ld hl, wSnd_Duration          ; 1d2c: 21 67 de | duration left?
    add hl, bc                    ; 1d2f: 09
    ld a, [hl]                    ; 1d30: 7e
    or a                          ; 1d31: b7
    jp z, Snd_FetchRow            ; 1d32: ca 36 1e | 0 -> fetch next row
    ld hl, wSnd_NoteDelay         ; 1d35: 21 77 de | note-on delay (instr +7)
    add hl, bc                    ; 1d38: 09
    ld a, [hl]                    ; 1d39: 7e
    or a                          ; 1d3a: b7
    jr z, .running                ; 1d3b: 28 04
    dec [hl]                      ; 1d3d: 35       | still delaying
    jp Snd_NextChannel            ; 1d3e: c3 2e 1e

.running:
    ld hl, wSnd_Duration          ; 1d41: 21 67 de | count duration down
    add hl, bc                    ; 1d44: 09
    dec [hl]                      ; 1d45: 35
    ld a, c                       ; 1d46: 79       | noise channel resting ($75)?
    cp $03                        ; 1d47: fe 03
    jr nz, .envelope              ; 1d49: 20 08
    ld a, [wSnd_Note+3]           ; 1d4b: fa 92 de
    cp $75                        ; 1d4e: fe 75
    jp z, Snd_NextChannel         ; 1d50: ca 2e 1e

.envelope:
    ld hl, wSnd_ChanInstr         ; 1d53: 21 53 de | instr +9 = attack peak (level in LOW nibble)
    add hl, bc                    ; 1d56: 09
    add hl, bc                    ; 1d57: 09
    ld a, [hl+]                   ; 1d58: 2a
    ld h, [hl]                    ; 1d59: 66
    add $09                       ; 1d5a: c6 09
    ld l, a                       ; 1d5c: 6f
    jr nc, .atkCmp                ; 1d5d: 30 01
    inc h                         ; 1d5f: 24

.atkCmp:
    push hl                       ; 1d60: e5
    ld d, [hl]                    ; 1d61: 56
    ld hl, wSnd_AttackAcc         ; 1d62: 21 7b de | attack acc is kept nibble-swapped
    add hl, bc                    ; 1d65: 09
    ld a, [hl]                    ; 1d66: 7e
    swap a                        ; 1d67: cb 37
    cp d                          ; 1d69: ba       | reached peak?
    jr z, .attackDone             ; 1d6a: 28 11
    pop hl                        ; 1d6c: e1
    dec hl                        ; 1d6d: 2b       | instr +8 = attack step
    ld d, [hl]                    ; 1d6e: 56
    ld hl, wSnd_AttackAcc         ; 1d6f: 21 7b de
    add hl, bc                    ; 1d72: 09
    ld a, [hl]                    ; 1d73: 7e
    add d                         ; 1d74: 82       | acc += step
    ld [hl], a                    ; 1d75: 77
    ld hl, wSnd_DecayAcc          ; 1d76: 21 7f de | decay acc follows
    add hl, bc                    ; 1d79: 09
    ld [hl], a                    ; 1d7a: 77
    jr .setVolume                 ; 1d7b: 18 37

.attackDone:
    pop hl                        ; 1d7d: e1
    push hl                       ; 1d7e: e5
    inc hl                        ; 1d7f: 23       | instr +$0B = sustain level
    inc hl                        ; 1d80: 23
    ld d, [hl]                    ; 1d81: 56
    ld hl, wSnd_DecayAcc          ; 1d82: 21 7f de
    add hl, bc                    ; 1d85: 09
    ld a, [hl]                    ; 1d86: 7e
    swap a                        ; 1d87: cb 37    | reached sustain?
    cp d                          ; 1d89: ba
    jr z, .release                ; 1d8a: 28 14
    ld hl, wSnd_DecayEnable       ; 1d8c: 21 73 de | E0 flag: decay stage enabled?
    add hl, bc                    ; 1d8f: 09
    ld a, [hl]                    ; 1d90: 7e
    or a                          ; 1d91: b7
    jr z, .release                ; 1d92: 28 0c
    pop hl                        ; 1d94: e1
    inc hl                        ; 1d95: 23       | instr +$0A = decay step
    ld d, [hl]                    ; 1d96: 56
    ld hl, wSnd_DecayAcc          ; 1d97: 21 7f de
    add hl, bc                    ; 1d9a: 09
    ld a, [hl]                    ; 1d9b: 7e
    sub d                         ; 1d9c: 92       | decay acc -= step
    ld [hl], a                    ; 1d9d: 77
    jr .setVolume                 ; 1d9e: 18 14

.release:
    ld hl, wSnd_Volume            ; 1da0: 21 83 de | volume already 0?
    add hl, bc                    ; 1da3: 09
    ld a, [hl]                    ; 1da4: 7e
    and $f0                       ; 1da5: e6 f0
    pop hl                        ; 1da7: e1
    jr z, .vibrato                ; 1da8: 28 3e
    inc hl                        ; 1daa: 23       | instr +$0C = release step
    inc hl                        ; 1dab: 23
    inc hl                        ; 1dac: 23
    ld d, [hl]                    ; 1dad: 56
    ld hl, wSnd_Volume            ; 1dae: 21 83 de
    add hl, bc                    ; 1db1: 09
    ld a, [hl]                    ; 1db2: 7e
    sub d                         ; 1db3: 92       | volume -= release step

.setVolume:
    ld hl, wSnd_Volume            ; 1db4: 21 83 de | store volume
    add hl, bc                    ; 1db7: 09
    ld [hl], a                    ; 1db8: 77
    and $f0                       ; 1db9: e6 f0    | upper nibble = NRx2 volume
    ld e, a                       ; 1dbb: 5f
    ld a, c                       ; 1dbc: 79
    or a                          ; 1dbd: b7
    jr nz, .volNotCh1             ; 1dbe: 20 05
    ld a, e                       ; 1dc0: 7b
    ldh [rNR12], a                ; 1dc1: e0 12    | NR12 (no retrigger)
    jr .vibrato                   ; 1dc3: 18 23

.volNotCh1:
    dec a                         ; 1dc5: 3d
    jr nz, .volNotCh2             ; 1dc6: 20 05
    ld a, e                       ; 1dc8: 7b
    ldh [rNR22], a                ; 1dc9: e0 17    | NR22 (no retrigger)
    jr .vibrato                   ; 1dcb: 18 1b

.volNotCh2:
    dec a                         ; 1dcd: 3d
    jr nz, .volCh4                ; 1dce: 20 11
    ld a, e                       ; 1dd0: 7b
    swap a                        ; 1dd1: cb 37    | CH3: (vol>>4) & 3 ...
    and $03                       ; 1dd3: e6 03
    ld e, a                       ; 1dd5: 5f
    ld d, $00                     ; 1dd6: 16 00
    ld hl, Snd_WaveVolTable       ; 1dd8: 21 cb 20 | ... -> NR32 output level via Snd_WaveVolTable
    add hl, de                    ; 1ddb: 19
    ld a, [hl]                    ; 1ddc: 7e
    ldh [rNR32], a                ; 1ddd: e0 1c
    jr .vibrato                   ; 1ddf: 18 07

.volCh4:
    ld a, e                       ; 1de1: 7b
    ldh [rNR42], a                ; 1de2: e0 21    | NR42
    ld a, $80                     ; 1de4: 3e 80    | NR44 retrigger every frame
    ldh [rNR44], a                ; 1de6: e0 23

.vibrato:
    ld hl, wSnd_ChanInstr         ; 1de8: 21 53 de | instrument
    add hl, bc                    ; 1deb: 09
    add hl, bc                    ; 1dec: 09
    ld a, [hl+]                   ; 1ded: 2a
    ld h, [hl]                    ; 1dee: 66
    ld l, a                       ; 1def: 6f
    ld de, $000d                  ; 1df0: 11 0d 00 | instr +$0D = vibrato on?
    add hl, de                    ; 1df3: 19
    ld a, [hl+]                   ; 1df4: 2a
    or a                          ; 1df5: b7
    jp z, Snd_NextChannel         ; 1df6: ca 2e 1e
    ld d, h                       ; 1df9: 54
    ld e, l                       ; 1dfa: 5d
    ld hl, wSnd_VibDelay          ; 1dfb: 21 93 de | vibrato start delay
    add hl, bc                    ; 1dfe: 09
    ld a, [hl]                    ; 1dff: 7e
    or a                          ; 1e00: b7
    jp z, .vibRun                 ; 1e01: ca 08 1e
    dec [hl]                      ; 1e04: 35
    jp Snd_NextChannel            ; 1e05: c3 2e 1e

.vibRun:
    ld hl, wSnd_VibCounter        ; 1e08: 21 9b de | vibrato period counter
    add hl, bc                    ; 1e0b: 09
    ld a, [hl]                    ; 1e0c: 7e
    or a                          ; 1e0d: b7
    jr z, .vibStep                ; 1e0e: 28 04
    dec [hl]                      ; 1e10: 35
    jp Snd_NextChannel            ; 1e11: c3 2e 1e

.vibStep:
    push hl                       ; 1e14: e5       | reload period from instr +$0F
    ld h, d                       ; 1e15: 62
    ld l, e                       ; 1e16: 6b
    inc hl                        ; 1e17: 23
    ld a, [hl]                    ; 1e18: 7e
    pop hl                        ; 1e19: e1
    ld [hl], a                    ; 1e1a: 77
    ld h, d                       ; 1e1b: 62
    ld l, e                       ; 1e1c: 6b
    inc hl                        ; 1e1d: 23
    inc hl                        ; 1e1e: 23
    ld a, [hl+]                   ; 1e1f: 2a       | instr +$10 = step
    ld d, h                       ; 1e20: 54
    ld e, l                       ; 1e21: 5d
    ld hl, wSnd_VibAcc            ; 1e22: 21 97 de | VibAcc += step
    add hl, bc                    ; 1e25: 09
    add [hl]                      ; 1e26: 86
    ld [hl], a                    ; 1e27: 77
    push hl                       ; 1e28: e5
    ld h, d                       ; 1e29: 62       | reads instr +$12 and throws it away
    ld l, e                       ; 1e2a: 6b
    inc hl                        ; 1e2b: 23
    ld a, [hl+]                   ; 1e2c: 2a
    pop hl                        ; 1e2d: e1       | --- VibAcc is never applied to the pitch: unfinished feature ---

Snd_NextChannel:
    dec c                         ; 1e2e: 0d
    ld a, c                       ; 1e2f: 79
    cp $ff                        ; 1e30: fe ff
    jp nz, Snd_ChannelLoop        ; 1e32: c2 2c 1d
    ret                           ; 1e35: c9

; =============================================================================
; Snd_FetchRow  C = channel.  Pattern rows are 2 bytes: [note|cmd][arg]
; =============================================================================
Snd_FetchRow:
    ld hl, wSnd_OrderTable        ; 1e36: 21 4b de | order table -> this channel's order list
    ld a, [hl+]                   ; 1e39: 2a
    ld h, [hl]                    ; 1e3a: 66
    ld l, a                       ; 1e3b: 6f
    add hl, bc                    ; 1e3c: 09
    add hl, bc                    ; 1e3d: 09
    ld a, [hl+]                   ; 1e3e: 2a
    ld h, [hl]                    ; 1e3f: 66
    ld l, a                       ; 1e40: 6f
    push hl                       ; 1e41: e5
    ld hl, wSnd_OrderPos          ; 1e42: 21 5f de | entry = list + 3 * OrderPos
    add hl, bc                    ; 1e45: 09
    ld a, [hl]                    ; 1e46: 7e
    sla a                         ; 1e47: cb 27
    add [hl]                      ; 1e49: 86
    pop hl                        ; 1e4a: e1
    add l                         ; 1e4b: 85
    ld l, a                       ; 1e4c: 6f
    jr nc, .gotOrder              ; 1e4d: 30 01
    inc h                         ; 1e4f: 24

.gotOrder:
    push hl                       ; 1e50: e5
    inc hl                        ; 1e51: 23       | entry +2 = pattern transpose
    inc hl                        ; 1e52: 23
    ld a, [hl]                    ; 1e53: 7e
    ld hl, wSnd_PatTranspose      ; 1e54: 21 5b de
    add hl, bc                    ; 1e57: 09
    ld [hl], a                    ; 1e58: 77
    pop hl                        ; 1e59: e1       | entry +0 = pattern pointer
    ld a, [hl+]                   ; 1e5a: 2a
    ld h, [hl]                    ; 1e5b: 66
    ld l, a                       ; 1e5c: 6f
    push hl                       ; 1e5d: e5
    ld hl, wSnd_Row               ; 1e5e: 21 63 de | row = pattern + 2 * Row
    add hl, bc                    ; 1e61: 09
    ld a, [hl]                    ; 1e62: 7e
    pop hl                        ; 1e63: e1
    sla a                         ; 1e64: cb 27
    add l                         ; 1e66: 85
    ld l, a                       ; 1e67: 6f
    jr nc, .gotRow                ; 1e68: 30 01
    inc h                         ; 1e6a: 24

.gotRow:
    ld a, [hl+]                   ; 1e6b: 2a       | row byte 0
    cp $da                        ; 1e6c: fe da    | DA: stop song
    jp z, Snd_Stop                ; 1e6e: ca 13 1d
    cp $d9                        ; 1e71: fe d9    | D9: next order (all channels)
    jp z, Snd_CmdD9_NextOrder     ; 1e73: ca b8 1f
    cp $db                        ; 1e76: fe db    | DB: rewind song
    jp z, Snd_CmdDB_Rewind        ; 1e78: ca e5 1f
    cp $dc                        ; 1e7b: fe dc    | DC n: instrument
    jp z, Snd_CmdDC_Instrument    ; 1e7d: ca 0b 20
    cp $e0                        ; 1e80: fe e0    | E0 n: decay enable
    jp z, Snd_CmdE0_DecayEnable   ; 1e82: ca a7 20
    ld d, [hl]                    ; 1e85: 56       | row byte 1 = duration (bit 7 = tie)
    ld e, $00                     ; 1e86: 1e 00
    ld hl, wSnd_Duration          ; 1e88: 21 67 de
    add hl, bc                    ; 1e8b: 09
    bit 7, d                      ; 1e8c: cb 7a
    jr z, .note                   ; 1e8e: 28 04
    res 7, d                      ; 1e90: cb ba
    ld e, $01                     ; 1e92: 1e 01

.note:
    ld [hl], d                    ; 1e94: 72       | duration
    ld hl, wSnd_TieFlag           ; 1e95: 21 6b de | previous row tied?
    add hl, bc                    ; 1e98: 09
    ld d, [hl]                    ; 1e99: 56
    ld [hl], e                    ; 1e9a: 73
    ld hl, wSnd_Row               ; 1e9b: 21 63 de | Row++
    add hl, bc                    ; 1e9e: 09
    inc [hl]                      ; 1e9f: 34
    bit 0, d                      ; 1ea0: cb 42    | tied: keep sounding, no retrigger
    jp nz, Snd_NextChannel        ; 1ea2: c2 2e 1e
    ld hl, wSnd_Note              ; 1ea5: 21 8f de | remember note
    add hl, bc                    ; 1ea8: 09
    ld [hl], a                    ; 1ea9: 77
    cp $75                        ; 1eaa: fe 75    | $75 = rest (not transposed)
    jr z, .lookup                 ; 1eac: 28 0a
    ld hl, wSnd_InstrTranspose    ; 1eae: 21 6f de | + instrument transpose
    add hl, bc                    ; 1eb1: 09
    add [hl]                      ; 1eb2: 86
    ld hl, wSnd_PatTranspose      ; 1eb3: 21 5b de | + pattern transpose
    add hl, bc                    ; 1eb6: 09
    add [hl]                      ; 1eb7: 86

.lookup:
    sla a                         ; 1eb8: cb 27    | NB: 8-bit index*2
    ld e, a                       ; 1eba: 5f
    ld d, $00                     ; 1ebb: 16 00
    ld hl, Snd_FreqTable          ; 1ebd: 21 cf 20 | Snd_FreqTable
    add hl, de                    ; 1ec0: 19
    ld e, [hl]                    ; 1ec1: 5e
    inc hl                        ; 1ec2: 23
    ld d, [hl]                    ; 1ec3: 56
    ld hl, wSnd_Detune            ; 1ec4: 21 87 de | + detune (instr +4..+6)
    add hl, bc                    ; 1ec7: 09
    add hl, bc                    ; 1ec8: 09
    ld a, c                       ; 1ec9: 79
    or a                          ; 1eca: b7
    jr nz, .notCh1                ; 1ecb: 20 12
    ld a, $08                     ; 1ecd: 3e 08    | NR12 = $08: vol 0, env up, pace 0 (software env takes over)
    ldh [rNR12], a                ; 1ecf: e0 12
    ld a, e                       ; 1ed1: 7b
    add [hl]                      ; 1ed2: 86
    ldh [rNR13], a                ; 1ed3: e0 13
    inc hl                        ; 1ed5: 23
    ld a, d                       ; 1ed6: 7a
    adc [hl]                      ; 1ed7: 8e
    set 7, a                      ; 1ed8: cb ff    | trigger
    ldh [rNR14], a                ; 1eda: e0 14
    jp Snd_NoteOnTail             ; 1edc: c3 91 1f

.notCh1:
    dec a                         ; 1edf: 3d
    jr nz, .notCh2                ; 1ee0: 20 12
    ld a, $08                     ; 1ee2: 3e 08    | NR22 = $08
    ldh [rNR22], a                ; 1ee4: e0 17
    ld a, e                       ; 1ee6: 7b
    add [hl]                      ; 1ee7: 86
    ldh [rNR23], a                ; 1ee8: e0 18
    inc hl                        ; 1eea: 23
    ld a, d                       ; 1eeb: 7a
    adc [hl]                      ; 1eec: 8e
    set 7, a                      ; 1eed: cb ff
    ldh [rNR24], a                ; 1eef: e0 19
    jp Snd_NoteOnTail             ; 1ef1: c3 91 1f

.notCh2:
    dec a                         ; 1ef4: 3d
    jr nz, .ch4                   ; 1ef5: 20 0f
    xor a                         ; 1ef7: af       | NR32 = mute (software env sets level)
    ldh [rNR32], a                ; 1ef8: e0 1c
    ld a, e                       ; 1efa: 7b
    add [hl]                      ; 1efb: 86
    ldh [rNR33], a                ; 1efc: e0 1d
    inc hl                        ; 1efe: 23
    ld a, d                       ; 1eff: 7a
    adc [hl]                      ; 1f00: 8e
    ldh [rNR34], a                ; 1f01: e0 1e    | NR34 without trigger bit
    jp Snd_NoteOnTail             ; 1f03: c3 91 1f

.ch4:
    ld a, $08                     ; 1f06: 3e 08    | NR42 = $08
    ldh [rNR42], a                ; 1f08: e0 21
    ld a, [wSnd_Note+3]           ; 1f0a: fa 92 de | drum map on raw note byte (same table as Top Gun)
    cp $08                        ; 1f0d: fe 08
    jr z, .drumD                  ; 1f0f: 28 54
    cp $0c                        ; 1f11: fe 0c
    jr z, .drumA                  ; 1f13: 28 35
    cp $0e                        ; 1f15: fe 0e
    jr z, .drumB                  ; 1f17: 28 3a
    cp $11                        ; 1f19: fe 11
    jr z, .drumB                  ; 1f1b: 28 36
    cp $12                        ; 1f1d: fe 12
    jr z, .drumD                  ; 1f1f: 28 44
    cp $15                        ; 1f21: fe 15
    jr z, .drumB                  ; 1f23: 28 2e
    cp $18                        ; 1f25: fe 18
    jr z, .drumB                  ; 1f27: 28 2a
    cp $19                        ; 1f29: fe 19
    jr z, .drumA                  ; 1f2b: 28 1d
    cp $1b                        ; 1f2d: fe 1b
    jp z, .drumD                  ; 1f2f: ca 65 1f
    ld a, $75                     ; 1f32: 3e 75    | unmapped drum -> rest
    ld [wSnd_Note+3], a           ; 1f34: ea 92 de
    jp Snd_NoteOnTail             ; 1f37: c3 91 1f

; unreachable leftovers
.dead_a:
    ld a, $12                     ; 1f3a: 3e 12
    ld [wSnd_Note+3], a           ; 1f3c: ea 92 de
    jp .setDrum                   ; 1f3f: c3 85 1f

.dead_b:
    ld a, $12                     ; 1f42: 3e 12
    ld [wSnd_Note+3], a           ; 1f44: ea 92 de
    jp .setDrum                   ; 1f47: c3 85 1f

.drumA:
    ld a, $88                     ; 1f4a: 3e 88    | NR43 = $88
    ldh [rNR43], a                ; 1f4c: e0 22
    ld hl, Snd_DrumInstruments    ; 1f4e: 21 bb 21 | drum record 0
    jr .setDrum                   ; 1f51: 18 32

.drumB:
    ld a, $30                     ; 1f53: 3e 30    | NR43 = $30
    ldh [rNR43], a                ; 1f55: e0 22
    ld hl, $21dd                  ; 1f57: 21 dd 21 | drum record 1
    jr .setDrum                   ; 1f5a: 18 29

; unreachable drum variants
.dead_drumC:
    ld a, $60                     ; 1f5c: 3e 60
    ldh [rNR43], a                ; 1f5e: e0 22
    ld hl, $2243                  ; 1f60: 21 43 22
    jr .setDrum                   ; 1f63: 18 20

.drumD:
    ld a, $70                     ; 1f65: 3e 70    | NR43 = $70
    ldh [rNR43], a                ; 1f67: e0 22
    ld hl, $2221                  ; 1f69: 21 21 22 | drum record 3
    jr .setDrum                   ; 1f6c: 18 17

.dead_drumE:
    ld a, $50                     ; 1f6e: 3e 50
    ldh [rNR43], a                ; 1f70: e0 22
    ld hl, $2243                  ; 1f72: 21 43 22
    jr .setDrum                   ; 1f75: 18 0e

.dead_drumF:
    ld a, $40                     ; 1f77: 3e 40
    ldh [rNR43], a                ; 1f79: e0 22
    ld hl, $2243                  ; 1f7b: 21 43 22
    jr .setDrum                   ; 1f7e: 18 05

.dead_g:
    ld a, $0c                     ; 1f80: 3e 0c
    ld [wSnd_Note+3], a           ; 1f82: ea 92 de

.setDrum:
    ld a, l                       ; 1f85: 7d       | CH4 instrument := drum record
    ld [wSnd_ChanInstr+6], a      ; 1f86: ea 59 de
    ld a, h                       ; 1f89: 7c
    ld [wSnd_ChanInstr+7], a      ; 1f8a: ea 5a de
    ld a, $80                     ; 1f8d: 3e 80    | trigger
    ldh [rNR44], a                ; 1f8f: e0 23

; Snd_NoteOnTail: shared by all four note-on paths
Snd_NoteOnTail:
    ld hl, wSnd_ChanInstr         ; 1f91: 21 53 de | common note-on tail
    add hl, bc                    ; 1f94: 09
    add hl, bc                    ; 1f95: 09
    ld a, [hl+]                   ; 1f96: 2a
    ld h, [hl]                    ; 1f97: 66
    ld l, a                       ; 1f98: 6f
    push hl                       ; 1f99: e5
    ld de, $0007                  ; 1f9a: 11 07 00 | instr +7 = note-on delay
    add hl, de                    ; 1f9d: 19
    ld a, [hl]                    ; 1f9e: 7e
    ld hl, wSnd_NoteDelay         ; 1f9f: 21 77 de
    add hl, bc                    ; 1fa2: 09
    ld [hl], a                    ; 1fa3: 77
    pop hl                        ; 1fa4: e1
    ld de, $000e                  ; 1fa5: 11 0e 00 | instr +$0E = vibrato delay
    add hl, de                    ; 1fa8: 19
    ld a, [hl]                    ; 1fa9: 7e
    ld hl, wSnd_VibDelay          ; 1faa: 21 93 de
    add hl, bc                    ; 1fad: 09
    ld [hl], a                    ; 1fae: 77
    ld hl, wSnd_AttackAcc         ; 1faf: 21 7b de | attack restarts
    add hl, bc                    ; 1fb2: 09
    ld [hl], $00                  ; 1fb3: 36 00
    jp Snd_ChannelLoop            ; 1fb5: c3 2c 1d | continue with this channel

; Command D9: advance to the next order entry
Snd_CmdD9_NextOrder:
    ld a, [wSnd_OrderPos]         ; 1fb8: fa 5f de | order pos = channel 0's + 1, for ALL channels
    inc a                         ; 1fbb: 3c
    ld [wSnd_OrderPos], a         ; 1fbc: ea 5f de
    ld [wSnd_OrderPos+1], a       ; 1fbf: ea 60 de
    ld [wSnd_OrderPos+2], a       ; 1fc2: ea 61 de
    ld [wSnd_OrderPos+3], a       ; 1fc5: ea 62 de
    xor a                         ; 1fc8: af       | rows = 0
    ld [wSnd_Row], a              ; 1fc9: ea 63 de
    ld [wSnd_Row+1], a            ; 1fcc: ea 64 de
    ld [wSnd_Row+2], a            ; 1fcf: ea 65 de
    ld [wSnd_Row+3], a            ; 1fd2: ea 66 de
    xor a                         ; 1fd5: af       | durations = 0
    ld [wSnd_Duration], a         ; 1fd6: ea 67 de
    ld [wSnd_Duration+1], a       ; 1fd9: ea 68 de
    ld [wSnd_Duration+2], a       ; 1fdc: ea 69 de
    ld [wSnd_Duration+3], a       ; 1fdf: ea 6a de
    jp Snd_FetchRow               ; 1fe2: c3 36 1e

; Command DB: rewind to order 0
Snd_CmdDB_Rewind:
    xor a                         ; 1fe5: af       | everything back to the first order
    ld [wSnd_OrderPos], a         ; 1fe6: ea 5f de
    ld [wSnd_OrderPos+1], a       ; 1fe9: ea 60 de
    ld [wSnd_OrderPos+2], a       ; 1fec: ea 61 de
    ld [wSnd_OrderPos+3], a       ; 1fef: ea 62 de
    ld [wSnd_Row], a              ; 1ff2: ea 63 de
    ld [wSnd_Row+1], a            ; 1ff5: ea 64 de
    ld [wSnd_Row+2], a            ; 1ff8: ea 65 de
    ld [wSnd_Row+3], a            ; 1ffb: ea 66 de
    ld [wSnd_Duration], a         ; 1ffe: ea 67 de
    ld [wSnd_Duration+1], a       ; 2001: ea 68 de
    ld [wSnd_Duration+2], a       ; 2004: ea 69 de
    ld [wSnd_Duration+3], a       ; 2007: ea 6a de
    ret                           ; 200a: c9       | NB: leaves Snd_Update early this frame

; Command DC n: instrument = InstrTable[n] (34-byte record).
;   +0 NRx1 duty   +2 NR10 sweep   +3 transpose   +4 detune sign   +5/+6 detune
;   +7 note delay  +8 attack step  +9 attack peak  +A decay step   +B sustain
;   +C release step  +D vibrato on  +E vib delay  +F vib period  +10 vib step
Snd_CmdDC_Instrument:
    ld e, [hl]                    ; 200b: 5e       | n * 2
    sla e                         ; 200c: cb 23
    ld d, $00                     ; 200e: 16 00
    ld hl, wSnd_InstrTable        ; 2010: 21 47 de | instrument table
    ld a, [hl+]                   ; 2013: 2a
    ld h, [hl]                    ; 2014: 66
    ld l, a                       ; 2015: 6f
    add hl, de                    ; 2016: 19
    ld a, [hl+]                   ; 2017: 2a
    ld h, [hl]                    ; 2018: 66
    ld l, a                       ; 2019: 6f
    ld e, l                       ; 201a: 5d
    ld d, h                       ; 201b: 54
    ld hl, wSnd_ChanInstr         ; 201c: 21 53 de | -> this channel's instrument
    add hl, bc                    ; 201f: 09
    add hl, bc                    ; 2020: 09
    ld a, e                       ; 2021: 7b
    ld [hl+], a                   ; 2022: 22
    ld [hl], d                    ; 2023: 72
    ld h, d                       ; 2024: 62
    ld l, e                       ; 2025: 6b
    ld a, c                       ; 2026: 79
    or a                          ; 2027: b7
    jr nz, .notCh1                ; 2028: 20 05
    ld a, [hl]                    ; 202a: 7e       | CH1: NR11 = instr +0 (duty)
    ldh [rNR11], a                ; 202b: e0 11
    jr .sweep                     ; 202d: 18 08

.notCh1:
    dec a                         ; 202f: 3d
    jr nz, .sweep                 ; 2030: 20 05
    ld a, [hl]                    ; 2032: 7e       | CH2: NR21 = instr +0
    ldh [rNR21], a                ; 2033: e0 16
    jr .sweep                     ; 2035: 18 00

.sweep:
    inc hl                        ; 2037: 23
    inc hl                        ; 2038: 23
    ld a, c                       ; 2039: 79
    or a                          ; 203a: b7
    jr nz, .transpose             ; 203b: 20 03
    ld a, [hl]                    ; 203d: 7e       | CH1: NR10 = instr +2 (sweep)
    ldh [rNR10], a                ; 203e: e0 10

.transpose:
    inc hl                        ; 2040: 23
    ld a, [hl]                    ; 2041: 7e       | instr +3 = transpose
    push hl                       ; 2042: e5
    ld hl, wSnd_InstrTranspose    ; 2043: 21 6f de
    add hl, bc                    ; 2046: 09
    ld [hl], a                    ; 2047: 77
    pop hl                        ; 2048: e1
    push de                       ; 2049: d5
    inc hl                        ; 204a: 23       | instr +5/+6 = detune, +4 = sign (1 = up)
    inc hl                        ; 204b: 23
    ld e, [hl]                    ; 204c: 5e
    inc hl                        ; 204d: 23
    ld d, [hl]                    ; 204e: 56
    dec hl                        ; 204f: 2b
    dec hl                        ; 2050: 2b
    ld a, [hl]                    ; 2051: 7e
    cp $01                        ; 2052: fe 01
    jr z, .storeDetune            ; 2054: 28 07
    ld a, e                       ; 2056: 7b       | negate
    cpl                           ; 2057: 2f
    ld e, a                       ; 2058: 5f
    ld a, d                       ; 2059: 7a
    cpl                           ; 205a: 2f
    ld d, a                       ; 205b: 57
    inc de                        ; 205c: 13

.storeDetune:
    ld hl, wSnd_Detune            ; 205d: 21 87 de | store detune
    add hl, bc                    ; 2060: 09
    add hl, bc                    ; 2061: 09
    ld [hl], e                    ; 2062: 73
    inc hl                        ; 2063: 23
    ld [hl], d                    ; 2064: 72
    pop de                        ; 2065: d1
    ld h, d                       ; 2066: 62
    ld l, e                       ; 2067: 6b
    ld de, $000d                  ; 2068: 11 0d 00 | instr +$0D vibrato flag
    add hl, de                    ; 206b: 19
    ld a, [hl+]                   ; 206c: 2a
    or a                          ; 206d: b7
    jr z, .rowDone                ; 206e: 28 0c
    ld a, [hl+]                   ; 2070: 2a       | instr +$0E vibrato delay
    ld hl, wSnd_VibDelay          ; 2071: 21 93 de
    add hl, bc                    ; 2074: 09
    ld [hl], a                    ; 2075: 77
    ld hl, wSnd_VibAcc            ; 2076: 21 97 de
    add hl, bc                    ; 2079: 09
    ld [hl], $00                  ; 207a: 36 00

.rowDone:
    ld hl, wSnd_Row               ; 207c: 21 63 de | Row++
    add hl, bc                    ; 207f: 09
    inc [hl]                      ; 2080: 34
    ld hl, wSnd_Duration          ; 2081: 21 67 de | duration 0 -> next row now
    add hl, bc                    ; 2084: 09
    ld [hl], $00                  ; 2085: 36 00
    ld a, c                       ; 2087: 79       | wave channel (here channel == track, so this is correct)
    cp $02                        ; 2088: fe 02
    jp nz, Snd_FetchRow           ; 208a: c2 36 1e
    xor a                         ; 208d: af
    ldh [rNR30], a                ; 208e: e0 1a    | wave off
    ld hl, Snd_WaveTable          ; 2090: 21 bb 20 | Snd_WaveTable
    ld de, _AUD3WAVERAM           ; 2093: 11 30 ff

.copyWave:
    ld a, [hl+]                   ; 2096: 2a
    ld [de], a                    ; 2097: 12
    inc e                         ; 2098: 1c
    ld a, e                       ; 2099: 7b
    cp $40                        ; 209a: fe 40
    jr nz, .copyWave              ; 209c: 20 f8
    ld a, $80                     ; 209e: 3e 80    | wave on
    ldh [rNR30], a                ; 20a0: e0 1a
    ldh [rNR34], a                ; 20a2: e0 1e    | NR34 trigger
    jp Snd_FetchRow               ; 20a4: c3 36 1e

; Command E0 n: enable/disable the decay stage for this channel
Snd_CmdE0_DecayEnable:
    ld a, [hl]                    ; 20a7: 7e       | E0 argument
    ld hl, wSnd_DecayEnable       ; 20a8: 21 73 de
    add hl, bc                    ; 20ab: 09
    ld [hl], a                    ; 20ac: 77
    xor a                         ; 20ad: af       | duration 0, Row++ -> next row now
    ld hl, wSnd_Duration          ; 20ae: 21 67 de
    add hl, bc                    ; 20b1: 09
    ld [hl], a                    ; 20b2: 77
    ld hl, wSnd_Row               ; 20b3: 21 63 de
    add hl, bc                    ; 20b6: 09
    inc [hl]                      ; 20b7: 34
    jp Snd_FetchRow               ; 20b8: c3 36 1e

; Wave pattern - byte-identical to Top Gun $2993
Snd_WaveTable:
    db $ff, $00, $dd, $00, $bb, $00, $aa, $00 ; 20bb
    db $88, $00, $66, $00, $44, $00, $22, $00 ; 20c3

; NR32 output levels (mute, 25%, 50%, 100%) - USED here; unused in TG/BO/WW
Snd_WaveVolTable:
    db $00, $60, $40, $20         ; 20cb

; Frequency table: 118 x dw from C2.  Byte-identical in all four games.
; Entry $75 (117) = $07FE (inaudible) is the REST note.
Snd_FreqTable:
    dw $002c                      ; 20cf | n=  0 C  2  65.4 Hz
    dw $009d                      ; 20d1 | n=  1 C# 2  69.3 Hz
    dw $0108                      ; 20d3 | n=  2 D  2  73.5 Hz
    dw $016d                      ; 20d5 | n=  3 D# 2  77.9 Hz
    dw $01cc                      ; 20d7 | n=  4 E  2  82.5 Hz
    dw $0225                      ; 20d9 | n=  5 F  2  87.4 Hz
    dw $027a                      ; 20db | n=  6 F# 2  92.7 Hz
    dw $02ca                      ; 20dd | n=  7 G  2  98.3 Hz
    dw $0315                      ; 20df | n=  8 G# 2  104.1 Hz
    dw $035c                      ; 20e1 | n=  9 A  2  110.3 Hz
    dw $039f                      ; 20e3 | n= 10 A# 2  116.9 Hz
    dw $03de                      ; 20e5 | n= 11 B  2  123.9 Hz
    dw $041a                      ; 20e7 | n= 12 C  3  131.3 Hz
    dw $0452                      ; 20e9 | n= 13 C# 3  139.1 Hz
    dw $0487                      ; 20eb | n= 14 D  3  147.4 Hz
    dw $04b9                      ; 20ed | n= 15 D# 3  156.2 Hz
    dw $04e9                      ; 20ef | n= 16 E  3  165.7 Hz
    dw $0515                      ; 20f1 | n= 17 F  3  175.5 Hz
    dw $053f                      ; 20f3 | n= 18 F# 3  185.9 Hz
    dw $0567                      ; 20f5 | n= 19 G  3  197.1 Hz
    dw $058d                      ; 20f7 | n= 20 G# 3  209.0 Hz
    dw $05b0                      ; 20f9 | n= 21 A  3  221.4 Hz
    dw $05d1                      ; 20fb | n= 22 A# 3  234.5 Hz
    dw $05f1                      ; 20fd | n= 23 B  3  248.7 Hz
    dw $060f                      ; 20ff | n= 24 C  4  263.7 Hz
    dw $062b                      ; 2101 | n= 25 C# 4  279.5 Hz
    dw $0645                      ; 2103 | n= 26 D  4  295.9 Hz
    dw $065e                      ; 2105 | n= 27 D# 4  313.6 Hz
    dw $0676                      ; 2107 | n= 28 E  4  332.7 Hz
    dw $068c                      ; 2109 | n= 29 F  4  352.3 Hz
    dw $06a1                      ; 210b | n= 30 F# 4  373.4 Hz
    dw $06b5                      ; 210d | n= 31 G  4  396.0 Hz
    dw $06c7                      ; 210f | n= 32 G# 4  418.8 Hz
    dw $06d9                      ; 2111 | n= 33 A  4  444.3 Hz
    dw $06ea                      ; 2113 | n= 34 A# 4  471.5 Hz
    dw $06f9                      ; 2115 | n= 35 B  4  498.4 Hz
    dw $0708                      ; 2117 | n= 36 C  5  528.5 Hz
    dw $0716                      ; 2119 | n= 37 C# 5  560.1 Hz
    dw $0723                      ; 211b | n= 38 D  5  593.1 Hz
    dw $0730                      ; 211d | n= 39 D# 5  630.2 Hz
    dw $073c                      ; 211f | n= 40 E  5  668.7 Hz
    dw $0747                      ; 2121 | n= 41 F  5  708.5 Hz
    dw $0751                      ; 2123 | n= 42 F# 5  749.0 Hz
    dw $075b                      ; 2125 | n= 43 G  5  794.4 Hz
    dw $0764                      ; 2127 | n= 44 G# 5  840.2 Hz
    dw $076d                      ; 2129 | n= 45 A  5  891.6 Hz
    dw $0775                      ; 212b | n= 46 A# 5  943.0 Hz
    dw $077d                      ; 212d | n= 47 B  5  1000.5 Hz
    dw $0785                      ; 212f | n= 48 C  6  1065.6 Hz
    dw $078c                      ; 2131 | n= 49 C# 6  1129.9 Hz
    dw $0792                      ; 2133 | n= 50 D  6  1191.6 Hz
    dw $0798                      ; 2135 | n= 51 D# 6  1260.3 Hz
    dw $079e                      ; 2137 | n= 52 E  6  1337.5 Hz
    dw $07a4                      ; 2139 | n= 53 F  6  1424.7 Hz
    dw $07a9                      ; 213b | n= 54 F# 6  1506.6 Hz
    dw $07ae                      ; 213d | n= 55 G  6  1598.4 Hz
    dw $07b2                      ; 213f | n= 56 G# 6  1680.4 Hz
    dw $07b7                      ; 2141 | n= 57 A  6  1795.5 Hz
    dw $07bb                      ; 2143 | n= 58 A# 6  1899.6 Hz
    dw $07bf                      ; 2145 | n= 59 B  6  2016.5 Hz
    dw $07c3                      ; 2147 | n= 60 C  7  2148.7 Hz
    dw $07c6                      ; 2149 | n= 61 C# 7  2259.9 Hz
    dw $07c9                      ; 214b | n= 62 D  7  2383.1 Hz
    dw $07cc                      ; 214d | n= 63 D# 7  2520.6 Hz
    dw $07cf                      ; 214f | n= 64 E  7  2674.9 Hz
    dw $07d2                      ; 2151 | n= 65 F  7  2849.4 Hz
    dw $07d5                      ; 2153 | n= 66 F# 7  3048.2 Hz
    dw $07d7                      ; 2155 | n= 67 G  7  3196.9 Hz
    dw $07d9                      ; 2157 | n= 68 G# 7  3360.8 Hz
    dw $07dc                      ; 2159 | n= 69 A  7  3640.9 Hz
    dw $07de                      ; 215b | n= 70 A# 7  3855.1 Hz
    dw $07e0                      ; 215d | n= 71 B  7  4096.0 Hz
    dw $07e1                      ; 215f | n= 72 C  8  4228.1 Hz
    dw $07e3                      ; 2161 | n= 73 C# 8  4519.7 Hz
    dw $07e5                      ; 2163 | n= 74 D  8  4854.5 Hz
    dw $07e6                      ; 2165 | n= 75 D# 8  5041.2 Hz
    dw $07e8                      ; 2167 | n= 76 E  8  5461.3 Hz
    dw $07e9                      ; 2169 | n= 77 F  8  5698.8 Hz
    dw $07ea                      ; 216b | n= 78 F# 8  5957.8 Hz
    dw $07ec                      ; 216d | n= 79 G  8  6553.6 Hz
    dw $07ed                      ; 216f | n= 80 G# 8  6898.5 Hz
    dw $07ee                      ; 2171 | n= 81 A  8  7281.8 Hz
    dw $07ef                      ; 2173 | n= 82 A# 8  7710.1 Hz
    dw $07f0                      ; 2175 | n= 83 B  8  8192.0 Hz
    dw $07f1                      ; 2177 | n= 84 C  9  8738.1 Hz
    dw $07f2                      ; 2179 | n= 85 C# 9  9362.3 Hz
    dw $07f2                      ; 217b | n= 86 D  9  9362.3 Hz
    dw $07f3                      ; 217d | n= 87 D# 9  10082.5 Hz
    dw $07f4                      ; 217f | n= 88 E  9  10922.7 Hz
    dw $07f5                      ; 2181 | n= 89 F  9  11915.6 Hz
    dw $07f5                      ; 2183 | n= 90 F# 9  11915.6 Hz
    dw $07f6                      ; 2185 | n= 91 G  9  13107.2 Hz
    dw $07f6                      ; 2187 | n= 92 G# 9  13107.2 Hz
    dw $07f7                      ; 2189 | n= 93 A  9  14563.6 Hz
    dw $07f7                      ; 218b | n= 94 A# 9  14563.6 Hz
    dw $07f8                      ; 218d | n= 95 B  9  16384.0 Hz
    dw $07f8                      ; 218f | n= 96 C  10  16384.0 Hz
    dw $07f9                      ; 2191 | n= 97 C# 10  18724.6 Hz
    dw $07f9                      ; 2193 | n= 98 D  10  18724.6 Hz
    dw $07fa                      ; 2195 | n= 99 D# 10  21845.3 Hz
    dw $07fa                      ; 2197 | n=100 E  10  21845.3 Hz
    dw $07fa                      ; 2199 | n=101 F  10  21845.3 Hz
    dw $07fb                      ; 219b | n=102 F# 10  26214.4 Hz
    dw $07fb                      ; 219d | n=103 G  10  26214.4 Hz
    dw $07fb                      ; 219f | n=104 G# 10  26214.4 Hz
    dw $07fb                      ; 21a1 | n=105 A  10  26214.4 Hz
    dw $07fc                      ; 21a3 | n=106 A# 10  32768.0 Hz
    dw $07fc                      ; 21a5 | n=107 B  10  32768.0 Hz
    dw $07fc                      ; 21a7 | n=108 C  11  32768.0 Hz
    dw $07fc                      ; 21a9 | n=109 C# 11  32768.0 Hz
    dw $07fd                      ; 21ab | n=110 D  11  43690.7 Hz
    dw $07fd                      ; 21ad | n=111 D# 11  43690.7 Hz
    dw $07fd                      ; 21af | n=112 E  11  43690.7 Hz
    dw $07fd                      ; 21b1 | n=113 F  11  43690.7 Hz
    dw $07fd                      ; 21b3 | n=114 F# 11  43690.7 Hz
    dw $07fd                      ; 21b5 | n=115 G  11  43690.7 Hz
    dw $07fe                      ; 21b7 | n=116 G# 11  65536.0 Hz
    dw $07fe                      ; 21b9 | REST ($75)  n=117 A  11  65536.0 Hz

; Drum instruments: 6 x 34-byte records for CH4.  Top Gun's 6 x 14-byte
; drum records at $2A93 are converted copies of these (same order).
Snd_DrumInstruments:
    db $00, $00, $00, $00, $00, $00, $00, $00, $f0, $0f, $00, $0f, $f0, $00, $00, $00, $00 ; 21bb | NR43=$88
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $f0, $0f, $00, $0f, $78, $00, $00, $00, $00 ; 21dd | NR43=$30
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $f0, $0f, $00, $0f, $78, $00, $00, $00, $00 ; 21ff | unreferenced
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $30, $03, $00, $03, $30, $00, $00, $00, $00 ; 2221 | NR43=$70
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $c0, $0c, $00, $0c, $60, $00, $00, $00, $00 ; 2243 | dead code only
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $f0, $0f, $00, $0f, $78, $00, $00, $00, $00 ; 2265 | unreferenced
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

; Tiny shared patterns referenced from order lists
Snd_PatRewind:
    db $db, $00                     ; 2287 | DB: rewind song
Snd_PatStop:
    db $da, $00                     ; 2289 | DA: stop
Snd_PatRestNext:
    db $75, $e0, $d9, $00           ; 228b | rest 224 frames, then D9 next order
