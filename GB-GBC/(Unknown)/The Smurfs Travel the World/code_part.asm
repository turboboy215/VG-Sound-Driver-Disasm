; =============================================================================
; Driver code (bank 4, $4000-$431B)
; =============================================================================

SECTION "SoundDriver", ROMX[$4000], BANK[4]

; ---- jump table (the game calls these with bank 4 mapped) -------------------
SndPlaySong_Entry::     jp SndPlaySong  ; L = song (0-12), A = speed
SndNop_Entry::          jp SndNop       ; unused: just RET
SndPlaySfx_Entry::      jp SndPlaySfx   ; L = SFX (0-17), A = speed
SndInit_Entry::         jp SndInit      ; power-on init, starts the silent song

; -----------------------------------------------------------------------------
; SndUpdate ($400C) - called once per frame from the game's main loop
; (0:$296F).  Order: CH1 [tone SFX] -> write CH1, CH2 -> write CH2,
; CH3 -> write CH3, CH4 [noise SFX].
; -----------------------------------------------------------------------------
SndUpdate::
    ; --- voice 1 (CH1) with the tone note handler
    ld a, LOW(ToneNoteHandler)
    ld [wNoteHandler + 1], a
    ld l, LOW(wCh1 + VOICE_SIZE - 1)
    call SndRunVoice
    ld l, LOW(wCh1 + VOICE_SIZE - 1)
    call SndStoreVoice

    ; --- tone SFX runs here, after the music CH1 voice.  SndRunVoice clears
    ;     wRegNRx4 first, so any CH1 music note of this tick is dropped.
    ld a, [wSfxMode]
    cp SFXMODE_TONE
    jr nz, .ch1Write

    ld a, [wSpeed]              ; run the SFX voice at its own speed
    ld [wSpeedSave], a
    ld a, [wSfxSpeed]
    ld [wSpeed], a
    ld l, LOW(wSfx + VOICE_SIZE - 1)
    call SndRunVoice
    ld l, LOW(wSfx + VOICE_SIZE - 1)
    call SndStoreVoice
    ld a, [wSpeedSave]
    ld [wSpeed], a
    ld a, [wListNotEnded]       ; order list hit $00 this tick -> SFX over
    or a
    jr nz, .ch1Write
    ld [wSfxMode], a

.ch1Write:
    ld a, [wRegNRx4]            ; 0 = no note this tick
    or a
    jr z, .ch2

    ld l, LOW(wRegNRx1)
    ld a, [hl+]
    ldh [rNR11], a
    ld a, [hl+]
    ldh [rNR12], a
    ld a, [hl+]
    ldh [rNR13], a
    ld a, [hl]
    ldh [rNR14], a

.ch2:
    ld l, LOW(wCh2 + VOICE_SIZE - 1)
    call SndRunVoice
    ld l, LOW(wCh2 + VOICE_SIZE - 1)
    call SndStoreVoice
    ld a, [wRegNRx4]
    or a
    jr z, .ch3

    ld l, LOW(wRegNRx1)
    ld a, [hl+]
    ldh [rNR21], a
    ld a, [hl+]
    ldh [rNR22], a
    ld a, [hl+]
    ldh [rNR23], a
    ld a, [hl]
    ldh [rNR24], a

.ch3:
    ld l, LOW(wCh3 + VOICE_SIZE - 1)
    call SndRunVoice
    ld l, LOW(wCh3 + VOICE_SIZE - 1)
    call SndStoreVoice
    ld a, [wRegNRx4]
    or a
    jr z, .ch4

    xor a                       ; DAC off, write, DAC on (every note)
    ldh [rNR30], a
    ld l, LOW(wRegNRx1)
    ld a, [hl+]
    ldh [rNR31], a
    ld a, [hl+]                 ; NRx2 image -> NR32 output level (see doc)
    rrca
    cpl
    add $20
    ldh [rNR32], a
    ld a, $80
    ldh [rNR30], a
    ld a, [hl+]
    ldh [rNR33], a
    ld a, [hl]
    ldh [rNR34], a

.ch4:
    ; --- voice 4 (CH4).  During a noise SFX it keeps the *tone* handler, so
    ;     it keeps time but its results are never written.
    ld a, [wSfxMode]
    cp SFXMODE_NOISE
    jr z, .ch4Run
    ld a, LOW(NoiseNoteHandler)
    ld [wNoteHandler + 1], a
.ch4Run:
    ld l, LOW(wCh4 + VOICE_SIZE - 1)
    call SndRunVoice
    ld l, LOW(wCh4 + VOICE_SIZE - 1)
    call SndStoreVoice

    ld a, [wSfxMode]
    cp SFXMODE_NOISE
    ret nz

    ; --- noise SFX: same voice block as the tone SFX, noise handler
    ld a, LOW(NoiseNoteHandler)
    ld [wNoteHandler + 1], a
    ld a, [wSpeed]
    ld [wSpeedSave], a
    ld a, [wSfxSpeed]
    ld [wSpeed], a
    ld l, LOW(wSfx + VOICE_SIZE - 1)
    call SndRunVoice
    ld l, LOW(wSfx + VOICE_SIZE - 1)
    call SndStoreVoice
    ld a, [wSpeedSave]
    ld [wSpeed], a
    ld a, [wListNotEnded]
    or a
    ret nz
    ld [wSfxMode], a
    ret

; -----------------------------------------------------------------------------
; SndStoreVoice: copy wWork ($DF00-$DF1A) back to the voice block ending at
; $DF00+L.
; -----------------------------------------------------------------------------
SndStoreVoice:
    ld de, wWork + VOICE_SIZE - 1
    ld h, d
.loop:
    ld a, [de]
    ld [hl-], a
    dec e
    jr nz, .loop
    ld a, [de]
    ld [hl], a
    ret

; -----------------------------------------------------------------------------
; SndRunVoice: copy the voice block ending at $DF00+L to wWork, advance its
; timer, and parse events while it is due.  HL = wWork on the way through.
; -----------------------------------------------------------------------------
SndRunVoice:
    ld de, wWork + VOICE_SIZE - 1
    ld h, d
.copy:
    ld a, [hl-]
    ld [de], a
    dec e
    jr nz, .copy
    ld a, [hl]
    ld [de], a
    ld l, e                     ; HL = wWork
    xor a
    ld [wRegNRx4], a            ; no note yet
    cpl
    ld [wListNotEnded], a
    ld a, [wSpeed]              ; timer += speed - 256
    add [hl]
    ld [hl+], a
    ld a, $FF
    adc [hl]
    ld [hl+], a
    ret c                       ; still >= 0: nothing due

    ld e, [hl]                  ; DE = stream pointer
    inc l
    ld d, [hl]

ReadEvent:
    ld a, [de]
    cp 7
    jp nc, wNoteHandler         ; $07-$FF: note (via the RAM JP)
    or a
    jp z, NextOrder             ; $00: end of pattern
    inc de
    dec a
    jr nz, .not1
    ld a, [de]                  ; 1 xx: instrument
    ld l, VOICE_INSTR
    ld [hl], a
    jr SkipParamReadWait
.not1:
    dec a
    dec a
    jr nz, .not3
    ld a, [de]                  ; 3 xx: +$0A (never read)
    ld l, VOICE_UNUSED_A
    ld [hl], a
    jr SkipParamReadWait
.not3:
    dec a
    jr nz, SkipParamReadWait    ; 2, 5, 6 xx: ignored
    ld a, [de]                  ; 4 xx: +$0B (never read)
    ld l, VOICE_UNUSED_B
    ld [hl], a

SkipParamReadWait:
    inc de
ReadWait:                       ; wait: 0nnnnnnn = 2n, 1nnnnnnn hh = hh*256 + 2n
    ld b, 0
    ld a, [de]
    inc de
    add a
    ld c, a
    jr nc, AddWait
    ld a, [de]
    ld b, a
    inc de
AddWait:
    ld l, VOICE_TIMER
    ld a, [hl]
    add c
    ld [hl+], a
    ld a, [hl]
    adc b
    ld [hl+], a
    jr nc, ReadEvent            ; still negative: next event in this tick
    ld [hl], e                  ; save stream pointer
    inc l
    ld [hl], d
    ret

; -----------------------------------------------------------------------------
; Instrument tables.  They overlap: the tone table is indexed by voice +$0C
; (only 0-7 are used), the noise table by (note >> 3) & 15 (only 0-8 used;
; entry 9 would read the first code bytes of NextOrder).
; -----------------------------------------------------------------------------
ToneInstruments:                ; NRx1 (duty | length), NRx2 low bits
    db $D8, $00     ; 0  12.5 %, length 24 (CH3: length 40), no envelope
    db $80, $07     ; 1  50 %, env down /7   (CH3/CH4 default)
    db $80, $03     ; 2  50 %, env down /3   (SFX default)
    db $40, $02     ; 3  25 %, env down /2
    db $40, $00     ; 4  25 %, no envelope
    db $40, $01     ; 5  25 %, env down /1
    db $80          ; 6  50 %, env ...
NoiseInstruments:               ; NR41, NR42 low bits, NR43 (3 bytes each)
    db $02, $80, $01    ; 0      (tone 6 = $80,$02 / tone 7 = $80,$01)
    db $00, $01, $00    ; 1      (tone 8 = $00,$01 ...)
    db $00, $01, $8B    ; 2
    db $00, $02, $02    ; 3
    db $00, $04, $02    ; 4
    db $00, $01, $51    ; 5
    db $00, $01, $56    ; 6
    db $00, $05, $62    ; 7
    db $00, $01, $61    ; 8
                        ; 9+ = code below

; -----------------------------------------------------------------------------
; NextOrder: pattern ended ($00) - read the voice's order list.
;   $00        end of list: clear wListNotEnded, continue at the loop list
;   1xxxxxxx yy  rest of ((x << 8 | yy) << 1) & $FFFF units
;   0ttttttt pp  play pattern ((t+$52)&1)<<8 | pp with pitch (t+$52)>>1
; -----------------------------------------------------------------------------
NextOrder:
    ld l, VOICE_ORDER
    ld e, [hl]
    inc l
    ld d, [hl]
.loop:
    ld a, [de]
    or a
    jp z, .listEnd
    bit 7, a
    jp z, .play

    ld b, a                     ; rest
    inc de
    ld a, [de]
    inc de
    add a
    ld c, a
    rl b
    ld [hl], d
    dec l
    ld [hl], e
    ld de, SilentStream         ; empty stream: back here when the rest ends
    jp AddWait

.play:
    add $52
    rra
    ld l, VOICE_PITCH
    ld [hl], a
    ld a, 0                     ; B = bit 0 of (t + $52) = pattern bit 8
    rla
    ld b, a
    inc de
    ld a, [de]
    inc de
    ld l, VOICE_ORDER
    ld [hl], e
    inc l
    ld [hl], d
    ld c, a
    ld hl, PatternTable
    add hl, bc
    add hl, bc
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld h, HIGH(wWork)
    jp ReadWait                 ; a pattern starts with a wait

.listEnd:
    ld [wListNotEnded], a       ; A = 0
    inc l
    ld e, [hl]                  ; DE = loop list
    inc l
    ld d, [hl]
    dec l
    dec l
    jr .loop

; -----------------------------------------------------------------------------
; NoiseNoteHandler (CH4 music and noise SFX): note byte = 0iiiivvv / 1iiiivvv
;   i = NoiseInstruments entry, v = volume (0 or 2v+1).  Writes NR41-44 now.
;   $07 is not an escape here: it is drum 0 at volume 15.
; -----------------------------------------------------------------------------
NoiseNoteHandler:
    and %01111000
    add a
    swap a
    ld b, 0
    ld c, a
    ld hl, NoiseInstruments
    add hl, bc
    add hl, bc
    add hl, bc
    ld b, $80                   ; NR44: trigger
    ld a, [hl+]
    or a
    jr z, .noLength
    ld b, $C0                   ;       + length enable
.noLength:
    ldh [rNR41], a
    ld a, [hl+]
    ld c, a
    ld a, [de]
    and 7
    add a
    inc a
    swap a
    or c
    ldh [rNR42], a
    ld a, [hl]
    ldh [rNR43], a
    ld a, b
    ldh [rNR44], a
    ld h, HIGH(wWork)
    jp SkipParamReadWait

; -----------------------------------------------------------------------------
; ToneNoteHandler (CH1-3, tone SFX): note byte = sssssvvv
;   pitch += s - 16 (s = 1..31, so -15..+15 semitones), volume v (0 or 2v+1)
;   $07 tt nn: pitch += tt (signed), then note nn
; Result goes to wRegNRx1..4; SndUpdate writes it for CH1-3.
; -----------------------------------------------------------------------------
ToneNoteHandler:
    cp 7
    jr nz, .note
    inc de
    ld a, [de]
    ld l, VOICE_PITCH
    add [hl]
    ld [hl], a
    inc de
    ld a, [de]
.note:
    rrca
    rrca
    rrca
    and $1F
    ld b, a
    ld l, VOICE_PITCH
    ld a, [hl]
    add b
    sub 16
    ld [hl], a
    ld hl, FreqTable - 2 * PITCH_MIN    ; = $42D6 (inside SndInit)
    ld b, 0
    add a                       ; 8-bit: pitch >= $80 would wrap
    ld c, a
    add hl, bc
    ld c, [hl]
    inc hl
    ld b, [hl]
    ld hl, ToneInstruments
    ld a, [wWork + VOICE_INSTR]
    add a
    add l
    ld l, a
    ld a, h
    add 0
    ld h, a
    ld a, [hl+]
    ld [wRegNRx1], a
    and $3F
    jr z, .noLength
    set 6, b                    ; length enable if a length is given
.noLength:
    ld a, [hl]
    ld hl, wRegNRx4
    set 7, b                    ; trigger (also marks "note this tick")
    ld [hl], b
    dec l
    ld [hl], c                  ; wRegNRx3
    dec l
    ld c, a
    ld a, [de]
    and 7
    jr z, .vol0
    add a
    or 1
    swap a
.vol0:
    or c
    ld [hl], a                  ; wRegNRx2
    jp SkipParamReadWait

; -----------------------------------------------------------------------------
; SndPlaySong: L = song, A = speed.  Cancels any SFX.
; -----------------------------------------------------------------------------
SndPlaySong:
    ld de, SongTable
    di
    ld [wSpeed], a
    xor a
    ld [wSfxMode], a
    ld a, $0E                   ; accepts 0-14, but only 0-12 are songs
    cp l
    jr nc, .valid
    ld hl, SilentSong
    jr .setHeader
.valid:
    ld h, 0
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, de
.setHeader:
    ld e, l
    ld d, h
    ld b, 0
    ld hl, wCh1
    call InitVoice
    ld l, LOW(wCh2)
    call InitVoice
    ld b, 1
    ld l, LOW(wCh3)
    call InitVoice
    ld l, LOW(wCh4)
    call InitVoice
    ld a, $01                   ; NRx2 = $01 (DAC on, vol 0); NR1C = mute
    ldh [rNR12], a
    ldh [rNR22], a
    ldh [rNR32], a
    ldh [rNR42], a
    ei
    ret

; InitVoice: HL = voice block, DE -> (order list, loop list), B = instrument
InitVoice:
    ld a, 1                     ; timer = 1: first event next tick
    ld [hl+], a
    xor a
    ld [hl+], a
    ld a, LOW(SilentStream)     ; stream = empty: go straight to the order list
    ld [hl+], a
    ld a, HIGH(SilentStream)
    ld [hl+], a
    ld a, [de]
    inc de
    ld [hl+], a
    ld a, [de]
    inc de
    ld [hl+], a
    ld a, [de]
    inc de
    ld [hl+], a
    ld a, [de]
    inc de
    ld [hl+], a
    inc l                       ; +8 untouched
    ld a, $40
    ld [hl+], a                 ; +9 pitch
    ld [hl+], a                 ; +A
    ld [hl+], a                 ; +B
    ld [hl], b                  ; +C instrument
    ret

SndNop:
    ret

; -----------------------------------------------------------------------------
; SndPlaySfx: L = SFX, A = speed.  Noise SFX if the first order byte is 2/3.
; Leaves interrupts disabled (harmless: this game polls LY, all ISRs are RETI)
; -----------------------------------------------------------------------------
SndPlaySfx:
    ld de, SfxTable
    di
    ld [wSfxSpeed], a
    ld h, 0
    add hl, hl
    add hl, hl
    add hl, de
    ld e, l
    ld d, h
    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    ld h, a
    dec de
    ld a, [hl]
    rra
    cp 1
    jr z, .setMode              ; 1 = SFXMODE_NOISE
    ld a, SFXMODE_TONE
.setMode:
    ld [wSfxMode], a
    ld b, 2                     ; instrument 2
    ld hl, wSfx
    call InitVoice
    ret

; -----------------------------------------------------------------------------
; SndInit: RAM JP, APU registers, wave RAM, then the silent song at speed 0
; -----------------------------------------------------------------------------
SndInit:
    ld a, $C3                   ; jp
    ld [wNoteHandler], a
    ASSERT HIGH(ToneNoteHandler) == HIGH(NoiseNoteHandler)
    ld a, HIGH(ToneNoteHandler)
    ld [wNoteHandler + 2], a
    ld a, $08
    ldh [rNR10], a
    ld a, $08
    ldh [rNR12], a
    ldh [rNR22], a
    ldh [rNR32], a
    ldh [rNR42], a
    xor a
    ldh [rNR30], a
    ld c, LOW(_AUD3WAVERAM + 15)
    ld b, 16
    ld hl, WaveData
.waveLoop:
    ld a, [hl+]
    ldh [c], a
    dec c
    dec b
    jr nz, .waveLoop
    ld a, $80
    ldh [rNR14], a
    ldh [rNR24], a
    ldh [rNR34], a
    ldh [rNR44], a
    ld a, $77
    ldh [rNR50], a
    ld a, $FF
    ldh [rNR51], a
    ldh [rNR30], a
    ldh [rNR52], a
    ld hl, SilentSong
    ld a, 0
    jp SndPlaySong

WaveData:   ; written to $FF3F down to $FF30: square, 2 cycles per 32 samples
    db $FF, $FF, $FF, $FF, $00, $00, $00, $00
    db $FF, $FF, $FF, $FF, $00, $00, $00, $00

FreqTable:  ; pitch $2B (G2) ... $5F (B6)
    dw $02C6, $0310, $0358, $039B, $03DA, $0416, $044E, $0483, $04B5, $04E5, $0511, $053B    ; G2  - F#3
    dw $0563, $0588, $05AC, $05CE, $05ED, $060B, $0627, $0642, $065B, $0672, $0689, $069E    ; G3  - F#4
    dw $06B2, $06C4, $06D6, $06E7, $06F7, $0706, $0714, $0721, $072D, $0739, $0744, $074F    ; G4  - F#5
    dw $0759, $0762, $076B, $0773, $077B, $0783, $078A, $0790, $0797, $079D, $07A2, $07A7    ; G5  - F#6
    dw $07AC, $07B1, $07B6, $07BA, $07BE                                                      ; G6  - B6
