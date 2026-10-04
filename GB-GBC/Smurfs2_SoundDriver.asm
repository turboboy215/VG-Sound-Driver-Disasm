; =============================================================================
; The Smurfs Travel the World / "Smurfs 2, The (E) (M4).gb" - sound driver
; Bank 4, $4000-$60E5: driver code, tables, 13 songs, 18 SFX, 179 patterns.
; ROM0 $28FD-$2980: the game's glue routines.
;
; Rebuild (byte-exact against the ROM: 0:$28FD-$2980 and 4:$4000-$60E5):
;   rgbasm -o snd.o Smurfs2_SoundDriver.asm
;   rgblink -p 0xFF -o snd.gb snd.o
; =============================================================================

INCLUDE "hardware.inc"

; ---- RAM ($DF00-$DFAD) ------------------------------------------------------
DEF VOICE_SIZE      EQU $1B     ; bytes per voice block (only +$00-+$0C used)
DEF VOICE_TIMER     EQU $00     ; word, counts up; events are read while < 0
DEF VOICE_STREAM    EQU $02     ; word, pattern stream pointer
DEF VOICE_ORDER     EQU $04     ; word, order list pointer
DEF VOICE_LOOP      EQU $06     ; word, loop list pointer
                                ; +$08 never written or read
DEF VOICE_PITCH     EQU $09     ; current pitch (FreqTable index + $2B)
DEF VOICE_UNUSED_A  EQU $0A     ; set by command 3, never read
DEF VOICE_UNUSED_B  EQU $0B     ; set by command 4, never read
DEF VOICE_INSTR     EQU $0C     ; ToneInstruments index (command 1)
                                ; +$0D-+$1A copied every tick, never used

DEF wWork           EQU $DF00   ; work copy of the voice being processed
DEF wCh1            EQU $DF1B
DEF wCh2            EQU $DF36
DEF wCh3            EQU $DF51
DEF wSfx            EQU $DF6C
DEF wCh4            EQU $DF87
DEF wRegNRx1        EQU $DFA2   ; register image built by ToneNoteHandler
DEF wRegNRx2        EQU $DFA3
DEF wRegNRx3        EQU $DFA4
DEF wRegNRx4        EQU $DFA5   ; 0 = no note this tick
DEF wNoteHandler    EQU $DFA6   ; "jp ToneNoteHandler / NoiseNoteHandler"
DEF wSpeed          EQU $DFA9   ; music speed: timer += speed - 256 per tick
DEF wSfxSpeed       EQU $DFAA
DEF wSpeedSave      EQU $DFAB
DEF wSfxMode        EQU $DFAC   ; 0 none, 1 noise (CH4), 2 tone (CH1)
DEF wListNotEnded   EQU $DFAD   ; $FF, cleared when an order list wraps

DEF SFXMODE_NOISE   EQU 1
DEF SFXMODE_TONE    EQU 2
DEF PITCH_MIN       EQU $2B     ; FreqTable[0] = G2

; ---- stream macros ----------------------------------------------------------
; A wait of n timer units is 0nnnnnnn (n/2, n < 256) or 1nnnnnnn hh (long).
MACRO _W
    IF \1 & 1
        FAIL "odd wait"
    ENDC
    db (\1) >> 1
ENDM
MACRO _WL
    db $80 | (((\1) & $FF) >> 1), (\1) >> 8
ENDM

; DELAY / DELAYL n          - first byte(s) of every pattern
MACRO DELAY
    _W \1
ENDM
MACRO DELAYL
    _WL \1
ENDM
; NOTE / NOTEL step, vol, wait - pitch += step (-15..15), vol 0-7 (0, 3, 5 ... 15)
MACRO NOTE
    db (((\1) + 16) << 3) | (\2)
    _W \3
ENDM
MACRO NOTEL
    db (((\1) + 16) << 3) | (\2)
    _WL \3
ENDM
; TRANSP t                  - pitch += t, the next NOTE follows (escape $07)
MACRO TRANSP
    db 7, LOW(\1)
ENDM
; DRUM / DRUML idx, vol, wait - CH4: NoiseInstruments[idx], vol 0-7 (1, 3 ... 15)
MACRO DRUM
    db ((\1) << 3) | (\2)
    _W \3
ENDM
MACRO DRUML
    db ((\1) << 3) | (\2)
    _WL \3
ENDM
; INSTR / INSTRL n, wait    - command 1
MACRO INSTR
    db 1, \1
    _W \2
ENDM
MACRO INSTRL
    db 1, \1
    _WL \2
ENDM
; CMD c, param, wait        - commands 2-6 (unused by the data)
MACRO CMD
    db \1, \2
    _W \3
ENDM
MACRO ENDPAT
    db 0
ENDM

; ---- order list macros ------------------------------------------------------
; PLAY pattern, pitch       - t = 2*pitch + (pattern >> 8) - $52, must be 1-$7F
MACRO PLAY
    DEF _t = 2 * (\2) + ((\1) >> 8) - $52
    IF _t < 1 || _t > $7F
        FAIL "PLAY out of range"
    ENDC
    db _t, LOW(\1)
    PURGE _t
ENDM
; OREST n                   - rest of n units (n even, < $10000)
MACRO OREST
    db $80 | ((\1) >> 9), ((\1) >> 1) & $FF
ENDM
MACRO ENDLIST
    db 0
ENDM


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


; =============================================================================
; Music / SFX data ($4396-$60E5)
; =============================================================================

Pat_000: ; tone, silence (SilentOrder, i.e. every non-looping song/SFX end), entry pitch C#5
    DELAY 254
SilentStream:: ; InitVoice start stream and order-list rests
    ENDPAT

SilentOrder: ; sfx 0 SFX, sfx 1 SFX, sfx 10 SFX, sfx 11 SFX, sfx 12 SFX, sfx 13 SFX, sfx 14 SFX, sfx 15 SFX, sfx 16 SFX, sfx 17 SFX, sfx 2 SFX, sfx 3 SFX, sfx 4 SFX, sfx 5 SFX, sfx 6 SFX, sfx 7 SFX, sfx 8 SFX, sfx 9 SFX, song 0 CH1, song 0 CH2, song 0 CH3, song 0 CH4, song 10 CH1, song 10 CH2, song 10 CH3, song 10 CH4, song 4 CH1, song 4 CH2, song 4 CH3, song 4 CH4, song 9 CH1, song 9 CH2, song 9 CH3, song 9 CH4
    PLAY 0, $49
    ENDLIST

SilentSong: ; SndInit, and SndPlaySong with song > 14
    REPT 4
    dw SilentOrder, SilentOrder
    ENDR

Pat_001: ; tone, song 0 CH3, song 12 CH3, entry pitch G3
    DELAY 0
    NOTEL 0, 6, 288   ; G3
    NOTE  7, 6, 96    ; D4
    NOTE  -12, 6, 192   ; D3
    TRANSP 19
    NOTE  0, 6, 192   ; A4
    NOTE  -7, 6, 192   ; D4
    NOTE  -12, 6, 192   ; D3
    NOTE  2, 6, 192   ; E3
    NOTE  2, 6, 192   ; F#3
    ENDPAT

Pat_002: ; tone, song 0 CH2, song 12 CH2, entry pitch B4
    DELAY 0
    NOTE  0, 6, 192   ; B4
    NOTE  -4, 6, 96    ; G4
    NOTE  -5, 6, 96    ; D4
    NOTE  12, 6, 192   ; D5
    NOTE  -8, 6, 192   ; F#4
    NOTEL 1, 6, 768   ; G4
    ENDPAT

Pat_003: ; tone, song 0 CH1, song 12 CH1, entry pitch D6
    DELAY 0
    INSTR 2, 0
    NOTE  0, 6, 192   ; D6
    NOTE  -3, 6, 96    ; B5
    NOTE  -4, 6, 96    ; G5
    NOTE  4, 6, 194   ; B5
    NOTE  -5, 6, 190   ; F#5
    NOTEL 1, 6, 384   ; G5
    NOTEL 12, 6, 384   ; G6
    ENDPAT

Pat_004: ; tone, song 0 CH2, song 12 CH2, entry pitch G3
    DELAY 96
    INSTR 3, 96
    NOTE  0, 6, 96    ; G3
    NOTE  2, 6, 96    ; A3
    NOTE  10, 6, 192   ; G4
    NOTE  -7, 6, 192   ; C4
    NOTE  7, 6, 192   ; G4
    NOTE  -3, 6, 192   ; E4
    NOTE  -2, 6, 96    ; D4
    NOTE  5, 6, 96    ; G4
    NOTE  -3, 6, 96    ; E4
    NOTE  -2, 6, 96    ; D4
    NOTE  -3, 6, 192   ; B3
    NOTE  0, 6, 96    ; B3
    NOTE  1, 6, 96    ; C4
    NOTE  2, 6, 192   ; D4
    NOTE  -7, 6, 192   ; G3
    NOTEL -1, 6, 768   ; F#3
    ENDPAT

Pat_005: ; tone, song 0 CH3, song 12 CH3, entry pitch G3
    DELAY 0
    INSTR 0, 2
    NOTEL 0, 6, 382   ; G3
    NOTEL 7, 6, 288   ; D4
    NOTE  -7, 6, 96    ; G3
    NOTE  -7, 6, 192   ; C3
    TRANSP 19
    NOTE  0, 6, 192   ; G4
    NOTE  -1, 6, 192   ; F#4
    NOTE  -6, 6, 96    ; C4
    NOTE  -12, 6, 96    ; C3
    ENDPAT

Pat_006: ; tone, song 0 CH1, song 12 CH1, entry pitch B5
    DELAY 0
    INSTR 2, 0
    NOTEL 0, 6, 384   ; B5
    NOTEL 3, 6, 288   ; D6
    NOTE  -3, 6, 96    ; B5
    NOTE  5, 6, 192   ; E6
    NOTE  -4, 6, 192   ; C6
    NOTEL -3, 6, 384   ; A5
    ENDPAT

Pat_007: ; tone, song 0 CH3, song 12 CH3, entry pitch G3
    DELAY 0
    NOTEL 0, 6, 384   ; G3
    NOTEL 12, 6, 288   ; G4
    NOTE  -12, 6, 96    ; G3
    NOTE  -5, 6, 96    ; D3
    NOTE  12, 6, 96    ; D4
    NOTE  4, 6, 96    ; F#4
    NOTE  3, 6, 96    ; A4
    NOTE  5, 6, 96    ; D5
    NOTE  -5, 6, 96    ; A4
    NOTE  -3, 6, 96    ; F#4
    NOTE  -4, 6, 96    ; D4
    ENDPAT

Pat_008: ; tone, song 0 CH1, song 12 CH1, entry pitch B5
    DELAY 0
    NOTEL 0, 6, 288   ; B5
    NOTE  -2, 6, 96    ; A5
    NOTE  -2, 6, 184   ; G5
    NOTE  4, 6, 202   ; B5
    NOTEL -2, 6, 766   ; A5
    ENDPAT

Pat_009: ; tone, song 0 CH3, song 12 CH3, entry pitch G3
    DELAY 0
    NOTEL 0, 6, 384   ; G3
    NOTEL 7, 6, 288   ; D4
    NOTE  -7, 6, 96    ; G3
    NOTE  -7, 6, 192   ; C3
    TRANSP 26
    NOTE  0, 6, 192   ; D5
    NOTE  -5, 6, 192   ; A4
    NOTE  -9, 6, 96    ; C4
    NOTE  -12, 6, 96    ; C3
    ENDPAT

Pat_010: ; tone, song 0 CH2, song 12 CH2, entry pitch G4
    DELAYL 384
    NOTEL 0, 6, 576   ; G4
    NOTE  -3, 6, 192   ; E4
    NOTE  -2, 6, 192   ; D4
    NOTE  2, 6, 192   ; E4
    ENDPAT

Pat_011: ; tone, song 0 CH1, song 12 CH1, entry pitch B5
    DELAY 0
    NOTEL 0, 6, 384   ; B5
    NOTEL 3, 6, 288   ; D6
    NOTE  -3, 6, 96    ; B5
    NOTE  5, 6, 128   ; E6
    NOTE  -4, 6, 128   ; C6
    NOTE  -3, 6, 128   ; A5
    NOTEL -3, 6, 384   ; F#5
    ENDPAT

Pat_012: ; tone, song 0 CH3, song 12 CH3, entry pitch G3
    DELAY 0
    NOTE  0, 6, 192   ; G3
    NOTE  12, 6, 96    ; G4
    NOTE  -5, 6, 96    ; D4
    NOTE  -12, 6, 192   ; D3
    TRANSP 19
    NOTE  0, 6, 192   ; A4
    NOTE  -2, 6, 192   ; G4
    TRANSP -17
    NOTE  0, 6, 192   ; D3
    NOTE  2, 6, 192   ; E3
    NOTE  2, 6, 192   ; F#3
    ENDPAT

Pat_013: ; tone, song 0 CH2, song 12 CH2, entry pitch G6
    DELAY 0
    NOTE  0, 6, 96    ; G6
    NOTE  2, 6, 96    ; A6
    NOTE  -2, 6, 96    ; G6
    NOTE  -1, 6, 96    ; F#6
    NOTE  -4, 6, 192   ; D6
    NOTE  7, 6, 194   ; A6
    NOTE  -2, 6, 68    ; G6
    NOTE  2, 6, 58    ; A6
    NOTEL -2, 6, 640   ; G6
    ENDPAT

Pat_014: ; tone, song 0 CH1, song 12 CH1, entry pitch C6
    DELAY 0
    INSTR 3, 0
    NOTE  0, 6, 128   ; C6
    NOTE  -1, 6, 128   ; B5
    NOTE  -2, 6, 128   ; A5
    NOTE  2, 6, 128   ; B5
    NOTE  -2, 6, 128   ; A5
    NOTE  -3, 6, 128   ; F#5
    NOTEL 1, 6, 768   ; G5
    ENDPAT

Pat_015: ; tone, song 0 CH3, song 12 CH3, entry pitch A5
    DELAY 0
    INSTR 0, 0
    NOTE  0, 5, 128   ; A5
    NOTE  -2, 5, 128   ; G5
    NOTE  -1, 5, 128   ; F#5
    NOTE  1, 5, 128   ; G5
    NOTE  -1, 5, 128   ; F#5
    NOTE  -2, 5, 128   ; E5
    NOTE  2, 5, 128   ; F#5
    NOTE  -2, 5, 128   ; E5
    NOTE  -2, 5, 128   ; D5
    NOTE  2, 5, 128   ; E5
    NOTE  2, 5, 128   ; F#5
    NOTE  -4, 5, 128   ; D5
    NOTE  -1, 5, 192   ; C#5
    NOTE  3, 5, 192   ; E5
    NOTE  -3, 5, 192   ; C#5
    NOTE  -4, 5, 192   ; A4
    NOTE  -5, 5, 192   ; E4
    NOTE  -7, 5, 192   ; A3
    NOTE  4, 5, 192   ; C#4
    NOTE  3, 5, 192   ; E4
    ENDPAT

Pat_016: ; tone, song 0 CH2, song 12 CH2, entry pitch C3/C#3
    DELAY 0
    INSTR 1, 0
    NOTEL 0, 6, 1536  ; C3
    ENDPAT

Pat_017: ; tone, song 0 CH1, song 12 CH1, entry pitch C6
    DELAY 0
    INSTR 2, 0
    NOTE  0, 5, 128   ; C6
    NOTE  -1, 5, 128   ; B5
    NOTE  -2, 5, 128   ; A5
    NOTE  2, 5, 128   ; B5
    NOTE  -2, 5, 128   ; A5
    NOTE  -2, 5, 128   ; G5
    NOTE  2, 5, 128   ; A5
    NOTE  -2, 5, 128   ; G5
    NOTE  -1, 5, 128   ; F#5
    NOTE  1, 5, 128   ; G5
    NOTE  2, 5, 128   ; A5
    NOTE  -3, 5, 128   ; F#5
    NOTE  -2, 5, 168   ; E5
    INSTR 3, 24
    NOTE  5, 5, 192   ; A5
    NOTE  -5, 5, 192   ; E5
    NOTE  -3, 5, 192   ; C#5
    NOTE  -4, 5, 192   ; A4
    TRANSP -24
    NOTE  0, 5, 192   ; A2
    NOTE  4, 5, 192   ; C#3
    NOTE  3, 5, 192   ; E3
    ENDPAT

Pat_018: ; tone, song 0 CH1, song 12 CH1, song 4 CH1, entry pitch E5/B5
    DELAY 0
    INSTR 2, 0
    NOTEL 0, 6, 384   ; E5
    NOTEL 3, 6, 260   ; G5
    INSTR 3, 28
    NOTE  -3, 6, 96    ; E5
    NOTE  5, 6, 128   ; A5
    NOTE  -4, 6, 128   ; F5
    NOTE  -3, 6, 128   ; D5
    NOTE  -3, 6, 48    ; B4
    NOTE  1, 6, 48    ; C5
    NOTE  -1, 6, 48    ; B4
    NOTE  1, 6, 48    ; C5
    NOTE  -1, 6, 48    ; B4
    NOTE  1, 6, 48    ; C5
    NOTE  -1, 6, 96    ; B4
    ENDPAT

Pat_019: ; tone, song 0 CH2, song 12 CH2, song 4 CH2, entry pitch G4/D5
    DELAY 0
    INSTR 2, 0
    NOTEL 0, 6, 384   ; G4
    NOTE  4, 6, 250   ; B4
    INSTR 3, 12
    NOTE  -4, 6, 110   ; G4
    NOTE  5, 6, 142   ; C5
    NOTE  -3, 6, 126   ; A4
    NOTE  -4, 6, 128   ; F4
    INSTR 2, 0
    NOTEL -3, 6, 384   ; D4
    ENDPAT

Pat_020: ; tone, song 0 CH4, song 1 CH1, song 1 CH4, song 10 CH4, song 11 CH2, song 11 CH4, song 12 CH4, song 2 CH4, song 3 CH1, song 3 CH2, song 3 CH4, song 4 CH3, song 4 CH4, song 5 CH2, song 5 CH4, song 6 CH2, song 6 CH4, song 8 CH1, song 9 CH4, entry pitch ?$2A/E4
    DELAYL 1536
    ENDPAT

Pat_021: ; tone, song 0 CH2, song 0 CH3, song 12 CH2, song 12 CH3, entry pitch D3/D4
    DELAYL 384
    NOTEL 0, 6, 384   ; D3
    NOTEL 5, 6, 384   ; G3
    NOTEL 0, 6, 384   ; G3
    ENDPAT

Pat_022: ; tone, song 0 CH1, song 12 CH1, entry pitch D6
    DELAYL 356
    NOTE  0, 6, 28    ; D6
    NOTEL 4, 6, 356   ; F#6
    NOTE  -4, 6, 28    ; D6
    NOTEL 5, 6, 768   ; G6
    ENDPAT

Pat_023: ; tone, song 0 CH1, song 12 CH1, entry pitch G5
    DELAY 0
    INSTR 2, 0
    NOTE  0, 6, 192   ; G5
    NOTE  0, 6, 96    ; G5
    NOTE  2, 6, 96    ; A5
    NOTE  2, 6, 192   ; B5
    NOTE  1, 6, 192   ; C6
    NOTEL 4, 6, 384   ; E6
    NOTE  -4, 6, 96    ; C6
    NOTE  2, 6, 96    ; D6
    NOTE  -3, 6, 96    ; B5
    NOTE  -2, 6, 96    ; A5
    ENDPAT

Pat_024: ; tone, song 0 CH1, song 12 CH1, entry pitch G5
    DELAY 0
    NOTE  0, 6, 188   ; G5
    NOTE  0, 6, 100   ; G5
    NOTE  2, 6, 96    ; A5
    NOTE  2, 6, 192   ; B5
    NOTE  -4, 6, 186   ; G5
    NOTE  -5, 6, 198   ; D5
    NOTE  0, 6, 96    ; D5
    NOTE  2, 6, 96    ; E5
    NOTEL -2, 6, 384   ; D5
    ENDPAT

Pat_025: ; tone, song 0 CH1, song 12 CH1, entry pitch B3
    DELAY 0
    INSTR 3, 0
    NOTE  0, 6, 192   ; B3
    NOTE  3, 6, 64    ; D4
    NOTE  5, 6, 64    ; G4
    NOTE  4, 6, 64    ; B4
    NOTE  3, 6, 192   ; D5
    NOTE  -3, 6, 192   ; B4
    NOTE  1, 6, 192   ; C5
    NOTE  -3, 6, 192   ; A4
    NOTE  -3, 6, 192   ; F#4
    NOTE  -4, 6, 192   ; D4
    ENDPAT

Pat_026: ; tone, song 1 CH1, entry pitch F4
    DELAY 0
    INSTR 1, 0
    NOTEL 0, 6, 256   ; F4
    NOTE  4, 6, 128   ; A4
    NOTEL 3, 6, 256   ; C5
    NOTEL 5, 6, 384   ; F5
    NOTE  -12, 6, 128   ; F4
    NOTEL 4, 6, 256   ; A4
    NOTE  5, 6, 128   ; D5
    ENDPAT

Pat_027: ; tone, song 1 CH3, entry pitch F3
    DELAY 0
    NOTEL 0, 6, 256   ; F3
    NOTE  4, 6, 128   ; A3
    NOTEL -9, 6, 256   ; C3
    NOTE  9, 6, 128   ; A3
    NOTEL -4, 6, 256   ; F3
    NOTE  -5, 6, 128   ; C3
    NOTE  2, 6, 128   ; D3
    NOTE  1, 6, 128   ; D#3
    NOTE  1, 6, 128   ; E3
    ENDPAT

Pat_028: ; tone, song 1 CH2, entry pitch G3/C4
    DELAYL 256
    NOTEL 0, 6, 384   ; G3
    NOTEL 0, 6, 896   ; G3
    ENDPAT

Pat_029: ; tone, song 1 CH1, entry pitch F4
    DELAYL 256
    NOTE  0, 6, 128   ; F4
    NOTE  4, 6, 128   ; A4
    NOTE  3, 6, 128   ; C5
    NOTE  2, 6, 128   ; D5
    NOTEL -2, 6, 256   ; C5
    NOTE  7, 6, 128   ; G5
    NOTEL -2, 6, 256   ; F5
    NOTE  -1, 6, 128   ; E5
    ENDPAT

Pat_030: ; tone, song 1 CH2, entry pitch G3/C4/D4
    DELAY 0
    INSTRL 3, 256
    NOTEL 0, 6, 384   ; G3
    NOTEL 0, 6, 384   ; G3
    NOTEL 0, 6, 384   ; G3
    NOTE  0, 6, 128   ; G3
    ENDPAT

Pat_031: ; tone, song 1 CH3, entry pitch A3
    DELAY 0
    NOTEL 0, 6, 256   ; A3
    NOTE  8, 6, 128   ; F4
    NOTEL -12, 6, 256   ; F3
    NOTE  12, 6, 128   ; F4
    NOTEL -8, 6, 256   ; A3
    NOTE  8, 6, 128   ; F4
    NOTEL -12, 6, 256   ; F3
    NOTE  12, 6, 128   ; F4
    NOTEL -8, 6, 256   ; A3
    NOTE  2, 6, 128   ; B3
    NOTEL -4, 6, 256   ; G3
    NOTE  4, 6, 128   ; B3
    NOTEL -2, 6, 256   ; A3
    NOTE  2, 6, 128   ; B3
    NOTEL -4, 6, 256   ; G3
    NOTE  4, 6, 128   ; B3
    NOTEL -1, 6, 256   ; A#3
    NOTE  7, 6, 128   ; F4
    NOTEL -12, 6, 256   ; F3
    NOTE  12, 6, 128   ; F4
    NOTEL -7, 6, 256   ; A#3
    NOTE  7, 6, 128   ; F4
    NOTEL -12, 6, 256   ; F3
    NOTE  12, 6, 128   ; F4
    ENDPAT

Pat_032: ; tone, song 1 CH1, entry pitch A4
    DELAY 0
    NOTEL 0, 6, 256   ; A4
    NOTE  3, 6, 128   ; C5
    NOTEL 5, 6, 256   ; F5
    NOTEL 4, 6, 384   ; A5
    NOTE  -2, 6, 128   ; G5
    NOTEL -2, 6, 256   ; F5
    NOTE  -3, 6, 128   ; D5
    NOTEL -3, 6, 256   ; B4
    NOTE  1, 6, 128   ; C5
    NOTEL 2, 6, 256   ; D5
    NOTEL -7, 6, 384   ; G4
    NOTE  7, 6, 128   ; D5
    NOTE  -2, 6, 128   ; C5
    NOTE  2, 6, 64    ; D5
    NOTE  -2, 6, 64    ; C5
    NOTE  -1, 6, 128   ; B4
    ENDPAT

Pat_033: ; tone, song 1 CH1, entry pitch A#4
    DELAY 0
    NOTEL 0, 6, 256   ; A#4
    NOTE  4, 6, 128   ; D5
    NOTEL 3, 6, 256   ; F5
    NOTEL 5, 6, 384   ; A#5
    NOTE  -1, 6, 128   ; A5
    NOTEL -2, 6, 256   ; G5
    NOTE  -2, 6, 128   ; F5
    ENDPAT

Pat_034: ; tone, song 1 CH3, entry pitch E3
    DELAY 0
    NOTEL 0, 6, 256   ; E3
    NOTE  8, 6, 128   ; C4
    NOTEL -12, 6, 256   ; C3
    NOTE  12, 6, 128   ; C4
    NOTEL -8, 6, 256   ; E3
    NOTE  8, 6, 128   ; C4
    NOTEL -12, 6, 256   ; C3
    NOTE  12, 6, 128   ; C4
    ENDPAT

Pat_035: ; tone, song 1 CH1, entry pitch E5
    DELAY 0
    NOTEL 0, 6, 256   ; E5
    NOTE  1, 6, 128   ; F5
    NOTEL 2, 6, 256   ; G5
    NOTEL -7, 6, 384   ; C5
    NOTE  12, 6, 128   ; C6
    NOTEL -2, 6, 256   ; A#5
    NOTE  -1, 6, 128   ; A5
    ENDPAT

Pat_036: ; tone, song 1 CH1, entry pitch F4
    DELAYL 256
    NOTE  0, 6, 128   ; F4
    NOTEL 4, 6, 256   ; A4
    NOTEL 3, 6, 384   ; C5
    NOTE  -3, 6, 128   ; A4
    NOTEL 3, 6, 256   ; C5
    NOTE  2, 6, 128   ; D5
    ENDPAT

Pat_037: ; tone, song 1 CH3, entry pitch F3
    DELAY 0
    INSTR 0, 0
    NOTEL 0, 6, 256   ; F3
    NOTE  4, 6, 128   ; A3
    NOTEL -9, 6, 256   ; C3
    NOTE  9, 6, 128   ; A3
    NOTEL -4, 6, 256   ; F3
    NOTE  4, 6, 128   ; A3
    NOTEL -9, 6, 256   ; C3
    NOTE  9, 6, 128   ; A3
    ENDPAT

Pat_038: ; tone, song 1 CH1, entry pitch E5
    DELAY 0
    NOTEL 0, 6, 256   ; E5
    NOTE  1, 6, 128   ; F5
    NOTEL 2, 6, 256   ; G5
    NOTEL -7, 6, 384   ; C5
    NOTE  5, 6, 128   ; F5
    NOTEL -1, 6, 256   ; E5
    NOTEL -6, 6, 384   ; A#4
    NOTE  7, 6, 128   ; F5
    NOTEL -1, 6, 256   ; E5
    NOTEL -7, 6, 384   ; A4
    NOTE  5, 6, 128   ; D5
    NOTEL -2, 6, 256   ; C5
    NOTEL -5, 6, 2688  ; G4
    NOTE  -7, 6, 128   ; C4
    NOTE  1, 6, 128   ; C#4
    NOTE  1, 6, 128   ; D4
    NOTE  1, 6, 128   ; D#4
    ENDPAT

Pat_039: ; tone, song 1 CH3, entry pitch E3
    DELAY 0
    NOTEL 0, 6, 256   ; E3
    NOTE  8, 6, 128   ; C4
    NOTEL -12, 6, 256   ; C3
    NOTE  12, 6, 128   ; C4
    NOTEL -8, 6, 256   ; E3
    NOTE  -4, 6, 128   ; C3
    NOTE  2, 6, 128   ; D3
    NOTE  1, 6, 128   ; D#3
    NOTE  1, 6, 128   ; E3
    ENDPAT

Pat_040: ; tone, song 1 CH3, entry pitch E3
    DELAY 0
    NOTEL 0, 6, 256   ; E3
    NOTE  4, 6, 128   ; G#3
    NOTEL -8, 6, 256   ; C3
    NOTE  8, 6, 128   ; G#3
    NOTEL -4, 6, 256   ; E3
    NOTE  4, 6, 128   ; G#3
    NOTEL -8, 6, 256   ; C3
    NOTE  8, 6, 128   ; G#3
    ENDPAT

Pat_041: ; tone, song 1 CH1, entry pitch E4
    DELAY 0
    NOTEL 0, 6, 768   ; E4
    NOTEL 4, 6, 768   ; G#4
    ENDPAT

Pat_042: ; tone, song 1 CH3, entry pitch E3
    DELAY 0
    NOTEL 0, 6, 256   ; E3
    NOTE  4, 6, 128   ; G#3
    NOTEL -8, 6, 256   ; C3
    NOTE  8, 6, 128   ; G#3
    NOTEL -4, 6, 256   ; E3
    NOTE  -4, 6, 128   ; C3
    NOTE  2, 6, 128   ; D3
    NOTE  1, 6, 128   ; D#3
    NOTE  1, 6, 128   ; E3
    ENDPAT

Pat_043: ; tone, song 1 CH2, entry pitch C4
    DELAYL 258
    NOTEL 0, 6, 382   ; C4
    NOTE  0, 6, 224   ; C4
    INSTR 2, 164
    NOTE  0, 6, 124   ; C4
    NOTE  2, 6, 130   ; D4
    NOTE  1, 6, 128   ; D#4
    NOTE  1, 6, 126   ; E4
    ENDPAT

Pat_044: ; tone, song 1 CH1, song 2 CH1, entry pitch D4/E4
    DELAY 0
    NOTEL 0, 6, 1536  ; D4
    ENDPAT

Pat_045: ; tone, song 2 CH2, entry pitch A4
    DELAYL 896
    INSTR 3, 128
    NOTE  0, 6, 128   ; A4
    NOTE  2, 6, 128   ; B4
    NOTE  -2, 6, 128   ; A4
    NOTE  2, 6, 128   ; B4
    ENDPAT

Pat_046: ; tone, song 2 CH2, entry pitch F#3
    DELAY 64
    INSTR 3, 192
    NOTEL 0, 6, 384   ; F#3
    NOTEL 0, 6, 384   ; F#3
    NOTEL 0, 6, 384   ; F#3
    NOTE  0, 6, 128   ; F#3
    ENDPAT

Pat_047: ; tone, song 2 CH3, entry pitch D3/A3
    DELAY 0
    INSTR 0, 0
    NOTEL 0, 6, 256   ; D3
    NOTE  7, 6, 128   ; A3
    NOTEL -12, 6, 256   ; A2
    NOTE  12, 6, 128   ; A3
    NOTEL -7, 6, 256   ; D3
    NOTE  7, 6, 128   ; A3
    NOTEL -12, 6, 256   ; A2
    NOTE  12, 6, 128   ; A3
    ENDPAT

Pat_048: ; tone, song 2 CH1, entry pitch A4
    DELAY 0
    INSTR 2, 0
    NOTE  0, 6, 120   ; A4
    NOTE  2, 6, 124   ; B4
    NOTE  2, 6, 140   ; C#5
    NOTEL 1, 6, 256   ; D5
    NOTE  -1, 6, 128   ; C#5
    NOTEL -2, 6, 256   ; B4
    NOTE  -2, 6, 128   ; A4
    NOTEL 4, 6, 256   ; C#5
    NOTE  -2, 6, 128   ; B4
    NOTEL -2, 6, 256   ; A4
    NOTE  -2, 6, 128   ; G4
    NOTEL 4, 6, 256   ; B4
    NOTE  -2, 6, 128   ; A4
    NOTEL -2, 6, 256   ; G4
    NOTE  -1, 6, 128   ; F#4
    NOTEL -2, 6, 256   ; E4
    NOTE  -2, 6, 128   ; D4
    ENDPAT

Pat_049: ; tone, song 2 CH2, entry pitch A4
    DELAY 0
    NOTE  0, 5, 128   ; A4
    NOTE  7, 5, 128   ; E5
    NOTE  -3, 5, 128   ; C#5
    NOTE  8, 5, 128   ; A5
    NOTE  -5, 5, 128   ; E5
    NOTE  9, 5, 128   ; C#6
    NOTE  -4, 5, 128   ; A5
    NOTE  7, 5, 128   ; E6
    NOTE  -3, 5, 128   ; C#6
    NOTE  -4, 5, 128   ; A5
    NOTE  -5, 5, 128   ; E5
    NOTE  -3, 5, 128   ; C#5
    ENDPAT

Pat_050: ; tone, song 2 CH2, entry pitch A4
    DELAYL 384
    INSTRL 2, 256
    NOTE  0, 5, 128   ; A4
    NOTE  5, 5, 128   ; D5
    NOTE  -1, 5, 128   ; C#5
    NOTE  1, 5, 128   ; D5
    NOTE  -5, 5, 128   ; A4
    NOTE  2, 5, 128   ; B4
    NOTE  -2, 5, 128   ; A4
    NOTE  2, 5, 128   ; B4
    NOTE  2, 5, 128   ; C#5
    NOTE  1, 5, 128   ; D5
    NOTE  -1, 5, 128   ; C#5
    NOTE  -2, 5, 128   ; B4
    NOTE  -2, 5, 128   ; A4
    NOTE  2, 5, 128   ; B4
    NOTE  2, 5, 128   ; C#5
    NOTE  1, 5, 128   ; D5
    NOTE  -1, 5, 128   ; C#5
    NOTE  -2, 5, 128   ; B4
    NOTE  -2, 5, 128   ; A4
    ENDPAT

Pat_051: ; tone, song 2 CH1, entry pitch E5
    DELAY 0
    INSTR 1, 0
    NOTEL 0, 6, 1152  ; E5
    NOTE  -3, 6, 128   ; C#5
    NOTE  3, 6, 128   ; E5
    NOTE  -3, 6, 128   ; C#5
    NOTEL -4, 6, 384   ; A4
    NOTE  -8, 6, 128   ; C#4
    NOTE  3, 6, 128   ; E4
    NOTE  -3, 6, 128   ; C#4
    NOTEL -4, 6, 384   ; A3
    NOTEL 4, 6, 384   ; C#4
    NOTEL 1, 6, 896   ; D4
    NOTE  -2, 0, 128   ; C4
    NOTE  2, 6, 128   ; D4
    NOTE  4, 6, 128   ; F#4
    NOTE  3, 6, 128   ; A4
    NOTE  -3, 6, 128   ; F#4
    ENDPAT

Pat_052: ; tone, song 2 CH2, entry pitch D5
    DELAY 0
    INSTR 2, 0
    NOTE  0, 6, 64    ; D5
    NOTE  2, 6, 64    ; E5
    NOTE  -2, 6, 64    ; D5
    NOTE  2, 6, 64    ; E5
    NOTE  -2, 6, 64    ; D5
    NOTE  2, 6, 64    ; E5
    NOTE  -2, 6, 64    ; D5
    NOTE  2, 6, 64    ; E5
    NOTE  -2, 6, 64    ; D5
    NOTE  2, 6, 64    ; E5
    NOTE  -2, 6, 64    ; D5
    NOTE  2, 6, 64    ; E5
    NOTEL -2, 6, 768   ; D5
    ENDPAT

Pat_053: ; tone, song 2 CH3, entry pitch D3
    DELAY 0
    NOTEL 0, 6, 256   ; D3
    NOTE  7, 6, 128   ; A3
    NOTEL -12, 6, 256   ; A2
    NOTE  12, 6, 128   ; A3
    NOTEL -7, 6, 256   ; D3
    NOTE  -5, 6, 128   ; A2
    NOTE  2, 6, 128   ; B2
    NOTE  -2, 6, 128   ; A2
    NOTE  2, 6, 128   ; B2
    ENDPAT

Pat_054: ; tone, song 3 CH1, entry pitch E3/A3/B3
    DELAY 0
    INSTR 3, 0
    NOTE  0, 4, 128   ; E3
    NOTE  5, 4, 128   ; A3
    NOTE  -5, 4, 128   ; E3
    NOTE  7, 4, 128   ; B3
    NOTE  -7, 4, 128   ; E3
    NOTE  9, 4, 128   ; C#4
    NOTE  -9, 4, 128   ; E3
    NOTE  5, 4, 128   ; A3
    NOTE  -5, 4, 128   ; E3
    NOTE  7, 4, 128   ; B3
    NOTE  -7, 4, 128   ; E3
    NOTE  9, 4, 128   ; C#4
    ENDPAT

Pat_055: ; tone, song 3 CH3, song 8 CH3, entry pitch A2/B2/C#3/D3/E3/F#3
    DELAY 0
    INSTR 0, 0
    NOTEL 0, 5, 256   ; A2
    NOTE  7, 5, 128   ; E3
    NOTEL 2, 5, 256   ; F#3
    NOTE  -2, 5, 128   ; E3
    NOTEL -7, 5, 256   ; A2
    NOTE  7, 5, 128   ; E3
    NOTEL 2, 5, 256   ; F#3
    NOTE  -2, 5, 128   ; E3
    ENDPAT

Pat_056: ; tone, song 3 CH2, entry pitch C#5
    DELAY 0
    NOTEL 0, 5, 256   ; C#5
    NOTEL 3, 5, 896   ; E5
    NOTE  -3, 5, 128   ; C#5
    NOTE  3, 5, 128   ; E5
    NOTE  -3, 5, 128   ; C#5
    NOTEL -2, 5, 1152  ; B4
    NOTEL 2, 5, 256   ; C#5
    NOTEL -2, 5, 1280  ; B4
    NOTEL -7, 5, 256   ; E4
    NOTE  2, 5, 128   ; F#4
    ENDPAT

Pat_057: ; tone, song 3 CH2, entry pitch A4
    DELAY 0
    NOTEL 0, 5, 640   ; A4
    NOTEL 2, 5, 512   ; B4
    NOTEL 2, 5, 384   ; C#5
    NOTEL 3, 5, 384   ; E5
    INSTR 3, 0
    NOTEL 0, 5, 256   ; E5
    NOTE  0, 5, 128   ; E5
    NOTEL 0, 5, 256   ; E5
    NOTE  -2, 5, 128   ; D5
    INSTR 1, 0
    NOTE  -1, 5, 128   ; C#5
    NOTE  3, 5, 128   ; E5
    NOTE  -3, 5, 128   ; C#5
    NOTEL -2, 5, 1152  ; B4
    NOTEL -2, 5, 256   ; A4
    NOTEL -3, 5, 1664  ; F#4
    NOTEL -2, 5, 640   ; E4
    NOTEL 5, 5, 512   ; A4
    NOTEL 4, 5, 384   ; C#5
    NOTEL -2, 5, 640   ; B4
    NOTEL 2, 5, 512   ; C#5
    NOTEL 3, 5, 384   ; E5
    NOTEL -7, 5, 3072  ; A4
    ENDPAT

Pat_058: ; tone, song 3 CH1, entry pitch C#5
    DELAYL 384
    NOTEL 0, 5, 256   ; C#5
    NOTE  0, 5, 128   ; C#5
    NOTEL 0, 5, 256   ; C#5
    NOTE  -2, 5, 128   ; B4
    NOTEL -2, 5, 384   ; A4
    ENDPAT

Pat_059: ; tone, song 3 CH1, entry pitch A5
    DELAY 0
    INSTR 2, 0
    NOTE  0, 2, 64    ; A5
    NOTE  2, 2, 64    ; B5
    NOTE  -2, 2, 64    ; A5
    NOTE  2, 2, 64    ; B5
    NOTE  -2, 2, 64    ; A5
    NOTE  2, 2, 64    ; B5
    NOTE  -2, 2, 64    ; A5
    NOTE  2, 2, 64    ; B5
    NOTE  -2, 2, 64    ; A5
    NOTE  2, 2, 64    ; B5
    NOTE  -2, 2, 64    ; A5
    NOTE  2, 2, 64    ; B5
    NOTE  -2, 2, 64    ; A5
    NOTE  2, 2, 64    ; B5
    NOTE  -2, 2, 64    ; A5
    NOTE  2, 2, 64    ; B5
    NOTE  -2, 2, 64    ; A5
    NOTE  2, 2, 64    ; B5
    NOTE  -2, 2, 64    ; A5
    NOTE  2, 2, 64    ; B5
    NOTE  -2, 2, 64    ; A5
    NOTE  2, 2, 64    ; B5
    NOTE  -2, 2, 64    ; A5
    NOTE  2, 2, 64    ; B5
    INSTR 1, 0
    NOTEL -2, 2, 384   ; A5
    INSTR 3, 0
    TRANSP -22
    NOTE  0, 4, 128   ; B3
    NOTE  -7, 4, 128   ; E3
    NOTE  9, 4, 128   ; C#4
    NOTE  -9, 4, 128   ; E3
    NOTE  5, 4, 128   ; A3
    NOTE  -5, 4, 128   ; E3
    NOTE  7, 4, 128   ; B3
    NOTE  -7, 4, 128   ; E3
    NOTE  9, 4, 128   ; C#4
    ENDPAT

Pat_060: ; tone, song 3 CH2, entry pitch E3/D4/F#4/A4
    DELAY 0
    INSTR 1, 2
    NOTEL 0, 5, 1534  ; E3
    ENDPAT

Pat_061: ; tone, song 3 CH1, entry pitch D4
    DELAY 0
    NOTE  0, 4, 128   ; D4
    NOTE  4, 4, 128   ; F#4
    NOTE  3, 4, 128   ; A4
    NOTE  5, 4, 128   ; D5
    NOTE  4, 4, 128   ; F#5
    NOTE  3, 4, 128   ; A5
    INSTR 1, 0
    NOTE  0, 2, 64    ; A5
    NOTE  2, 2, 64    ; B5
    NOTE  -2, 2, 64    ; A5
    NOTE  2, 2, 64    ; B5
    NOTE  -2, 2, 64    ; A5
    NOTE  2, 2, 64    ; B5
    NOTE  -2, 2, 64    ; A5
    NOTE  2, 2, 64    ; B5
    NOTE  -2, 2, 64    ; A5
    NOTE  2, 2, 64    ; B5
    NOTE  -2, 2, 64    ; A5
    NOTE  2, 2, 64    ; B5
    NOTEL -2, 2, 1536  ; A5
    ENDPAT

Pat_062: ; tone, song 3 CH2, entry pitch A4
    DELAY 0
    INSTR 1, 0
    NOTEL 0, 5, 1152  ; A4
    NOTE  2, 5, 128   ; B4
    NOTE  -2, 5, 128   ; A4
    NOTE  2, 5, 128   ; B4
    ENDPAT

Pat_063: ; tone, song 3 CH2, entry pitch C#5
    DELAY 0
    NOTEL 0, 5, 256   ; C#5
    NOTEL -4, 5, 896   ; A4
    NOTE  -3, 5, 128   ; F#4
    NOTE  3, 5, 128   ; A4
    NOTE  -3, 5, 128   ; F#4
    NOTEL -2, 5, 1152  ; E4
    NOTEL -3, 5, 256   ; C#4
    NOTEL 3, 5, 1664  ; E4
    ENDPAT

Pat_064: ; tone, song 3 CH1, entry pitch A5
    DELAY 0
    INSTR 1, 0
    NOTE  0, 3, 128   ; A5
    NOTE  -1, 3, 128   ; G#5
    NOTE  -2, 3, 128   ; F#5
    NOTE  2, 3, 128   ; G#5
    NOTE  -2, 3, 128   ; F#5
    NOTE  -2, 3, 128   ; E5
    NOTE  2, 3, 128   ; F#5
    NOTE  -2, 3, 128   ; E5
    NOTE  -2, 3, 128   ; D5
    NOTE  2, 3, 128   ; E5
    NOTE  -2, 3, 128   ; D5
    NOTE  -1, 3, 128   ; C#5
    ENDPAT

Pat_065: ; tone, song 3 CH2, entry pitch A5
    DELAY 0
    INSTR 3, 0
    NOTE  0, 4, 128   ; A5
    NOTE  -5, 4, 128   ; E5
    NOTE  -3, 4, 128   ; C#5
    NOTE  3, 4, 128   ; E5
    NOTE  -3, 4, 128   ; C#5
    NOTE  -4, 4, 128   ; A4
    NOTE  12, 4, 128   ; A5
    NOTE  -8, 5, 128   ; C#5
    NOTE  0, 5, 128   ; C#5
    NOTE  0, 5, 128   ; C#5
    NOTE  -2, 5, 128   ; B4
    NOTE  -2, 5, 128   ; A4
    NOTEL 2, 5, 256   ; B4
    NOTEL 2, 5, 256   ; C#5
    NOTE  -4, 5, 192   ; A4
    INSTR 1, 64
    NOTEL -5, 5, 768   ; E4
    ENDPAT

Pat_066: ; tone, song 3 CH1, entry pitch E3
    DELAY 0
    NOTE  0, 3, 128   ; E3
    NOTE  5, 3, 128   ; A3
    NOTE  -5, 3, 128   ; E3
    NOTE  7, 3, 128   ; B3
    NOTE  -7, 3, 128   ; E3
    NOTE  9, 3, 128   ; C#4
    NOTE  -9, 3, 128   ; E3
    INSTR 2, 0
    TRANSP 17
    NOTE  0, 5, 128   ; A4
    NOTE  0, 5, 128   ; A4
    NOTE  0, 5, 128   ; A4
    NOTE  -1, 5, 128   ; G#4
    NOTE  -2, 5, 128   ; F#4
    NOTEL 2, 5, 256   ; G#4
    NOTEL 1, 5, 256   ; A4
    NOTEL -3, 5, 256   ; F#4
    NOTE  -5, 5, 128   ; C#4
    INSTR 3, 0
    NOTE  -4, 4, 128   ; A3
    NOTE  -5, 4, 128   ; E3
    NOTE  7, 4, 128   ; B3
    NOTE  -7, 4, 128   ; E3
    NOTE  9, 4, 128   ; C#4
    ENDPAT

Pat_067: ; tone, song 3 CH2, entry pitch A4
    DELAY 0
    INSTR 3, 0
    NOTE  0, 5, 128   ; A4
    NOTE  2, 5, 128   ; B4
    NOTE  2, 5, 128   ; C#5
    NOTE  1, 5, 128   ; D5
    NOTE  2, 5, 128   ; E5
    NOTE  2, 5, 128   ; F#5
    NOTE  1, 5, 128   ; G5
    NOTE  -1, 5, 128   ; F#5
    NOTE  -2, 5, 128   ; E5
    NOTE  -2, 5, 128   ; D5
    NOTE  -1, 5, 128   ; C#5
    NOTE  -2, 5, 128   ; B4
    ENDPAT

Pat_068: ; tone, song 3 CH1, entry pitch F#4
    DELAY 0
    INSTR 2, 0
    NOTE  0, 5, 128   ; F#4
    NOTE  2, 5, 128   ; G#4
    NOTE  1, 5, 128   ; A4
    NOTE  2, 5, 128   ; B4
    NOTE  2, 5, 128   ; C#5
    NOTE  1, 5, 128   ; D5
    NOTE  2, 5, 128   ; E5
    NOTE  -2, 5, 128   ; D5
    NOTE  -1, 5, 128   ; C#5
    NOTE  -2, 5, 128   ; B4
    NOTE  -2, 5, 128   ; A4
    NOTE  -1, 5, 128   ; G#4
    ENDPAT

Pat_069: ; tone, song 3 CH2, entry pitch C#4
    DELAY 0
    INSTR 1, 0
    NOTEL 0, 5, 1152  ; C#4
    NOTE  -2, 5, 64    ; B3
    NOTE  2, 5, 64    ; C#4
    NOTE  -2, 5, 64    ; B3
    NOTE  -2, 5, 192   ; A3
    ENDPAT

Pat_070: ; tone, song 4 CH3, entry pitch C#3
    DELAYL 384
    INSTR 0, 0
    NOTEL 0, 5, 384   ; C#3
    NOTEL -1, 5, 768   ; C3
    ENDPAT

Pat_071: ; tone, song 4 CH2, entry pitch C#4
    DELAYL 384
    NOTEL 0, 6, 384   ; C#4
    NOTEL -1, 6, 384   ; C4
    NOTEL -12, 6, 384   ; C3
    ENDPAT

Pat_072: ; tone, song 4 CH1, entry pitch A3
    DELAYL 384
    INSTR 2, 0
    NOTEL 0, 6, 384   ; A3
    NOTEL 0, 6, 768   ; A3
    ENDPAT

Pat_073: ; tone, song 5 CH1, entry pitch C4
    DELAY 0
    INSTRL 3, 384
    NOTEL 0, 6, 576   ; C4
    NOTEL 0, 6, 960   ; C4
    NOTEL 0, 6, 384   ; C4
    NOTE  4, 6, 192   ; E4
    NOTEL 0, 6, 384   ; E4
    NOTE  -9, 6, 192   ; G3
    ENDPAT

Pat_074: ; tone, song 5 CH3, entry pitch C3
    DELAY 0
    INSTR 0, 4
    NOTEL 0, 5, 380   ; C3
    NOTEL 7, 5, 384   ; G3
    NOTE  -7, 5, 192   ; C3
    NOTEL 7, 5, 576   ; G3
    NOTE  -7, 5, 192   ; C3
    NOTE  4, 5, 192   ; E3
    NOTE  3, 5, 192   ; G3
    NOTE  -8, 5, 192   ; B2
    NOTE  1, 5, 192   ; C3
    NOTE  7, 5, 192   ; G3
    NOTE  -7, 5, 192   ; C3
    NOTE  12, 5, 192   ; C4
    ENDPAT

Pat_075: ; tone, song 5 CH3, entry pitch E3
    DELAY 0
    NOTE  0, 5, 192   ; E3
    NOTE  4, 5, 192   ; G#3
    NOTE  3, 5, 192   ; B3
    NOTE  5, 5, 192   ; E4
    NOTE  7, 5, 192   ; B4
    NOTE  -3, 5, 192   ; G#4
    NOTE  -4, 5, 192   ; E4
    NOTE  -3, 5, 192   ; C#4
    NOTEL -2, 5, 384   ; B3
    NOTE  -3, 5, 192   ; G#3
    NOTE  -4, 5, 192   ; E3
    NOTE  4, 5, 192   ; G#3
    NOTE  0, 5, 192   ; G#3
    NOTE  -4, 5, 192   ; E3
    NOTE  4, 5, 192   ; G#3
    ENDPAT

Pat_076: ; tone, song 5 CH1, entry pitch G#3
    DELAYL 384
    NOTEL 0, 6, 576   ; G#3
    NOTEL 3, 6, 960   ; B3
    NOTEL 0, 6, 384   ; B3
    NOTE  3, 6, 192   ; D4
    NOTEL 0, 6, 384   ; D4
    NOTE  -3, 6, 192   ; B3
    ENDPAT

Pat_077: ; tone, song 5 CH2, entry pitch B5
    DELAY 0
    NOTEL 0, 4, 576   ; B5
    INSTR 2, 0
    NOTE  -3, 4, 96    ; G#5
    NOTE  -4, 4, 96    ; E5
    NOTE  7, 4, 192   ; B5
    NOTE  -3, 4, 192   ; G#5
    NOTE  -4, 4, 192   ; E5
    NOTE  -3, 4, 192   ; C#5
    NOTE  -2, 4, 48    ; B4
    NOTE  2, 4, 48    ; C#5
    NOTE  -2, 4, 48    ; B4
    NOTE  2, 4, 48    ; C#5
    NOTE  -2, 4, 48    ; B4
    NOTE  2, 4, 48    ; C#5
    NOTE  -2, 4, 48    ; B4
    NOTE  2, 4, 48    ; C#5
    NOTE  -2, 4, 192   ; B4
    NOTE  0, 4, 96    ; B4
    NOTE  3, 4, 96    ; D5
    NOTE  2, 4, 192   ; E5
    NOTEL -2, 4, 576   ; D5
    ENDPAT

Pat_078: ; tone, song 5 CH2, entry pitch G5
    DELAY 0
    INSTR 1, 0
    NOTEL 0, 4, 576   ; G5
    INSTR 2, 0
    NOTE  -3, 4, 96    ; E5
    NOTE  3, 4, 96    ; G5
    NOTE  5, 4, 192   ; C6
    NOTE  -1, 4, 192   ; B5
    NOTE  -4, 4, 192   ; G5
    INSTR 1, 0
    NOTEL -3, 4, 384   ; E5
    NOTEL 3, 4, 384   ; G5
    NOTE  -3, 4, 192   ; E5
    NOTE  7, 4, 192   ; B5
    NOTE  -2, 4, 192   ; A5
    NOTE  -2, 4, 192   ; G5
    INSTR 2, 0
    NOTE  -3, 4, 192   ; E5
    ENDPAT

Pat_079: ; tone, song 5 CH2, entry pitch G#4
    DELAY 0
    INSTR 1, 0
    NOTEL 0, 4, 576   ; G#4
    INSTR 2, 0
    NOTE  -4, 4, 64    ; E4
    NOTE  4, 4, 64    ; G#4
    NOTE  3, 4, 64    ; B4
    NOTE  5, 4, 192   ; E5
    NOTE  -5, 4, 192   ; B4
    NOTE  -3, 4, 192   ; G#4
    NOTE  -4, 4, 192   ; E4
    NOTE  -8, 4, 192   ; G#3
    INSTR 1, 0
    TRANSP 18
    NOTEL 0, 4, 384   ; D5
    INSTR 2, 0
    NOTE  -6, 4, 192   ; G#4
    INSTR 1, 0
    NOTEL 6, 4, 384   ; D5
    NOTEL -3, 4, 384   ; B4
    ENDPAT

Pat_080: ; tone, song 5 CH3, entry pitch A2
    DELAY 0
    NOTE  0, 5, 192   ; A2
    NOTE  7, 5, 192   ; E3
    NOTEL 5, 5, 960   ; A3
    NOTE  0, 5, 192   ; A3
    ENDPAT

Pat_081: ; tone, song 5 CH2, entry pitch A4
    DELAY 0
    INSTR 3, 0
    NOTE  0, 4, 192   ; A4
    NOTE  3, 4, 192   ; C5
    NOTE  4, 4, 192   ; E5
    NOTE  -4, 4, 192   ; C5
    NOTE  4, 4, 192   ; E5
    NOTE  -4, 4, 192   ; C5
    NOTE  -1, 4, 192   ; B4
    NOTE  1, 4, 192   ; C5
    ENDPAT

Pat_082: ; tone, song 5 CH1, entry pitch C4
    DELAY 0
    INSTR 1, 0
    NOTEL 0, 4, 1344  ; C4
    NOTE  2, 4, 192   ; D4
    NOTEL 2, 4, 1536  ; E4
    ENDPAT

Pat_083: ; tone, song 5 CH2, entry pitch G#4
    DELAY 0
    NOTE  0, 4, 192   ; G#4
    NOTE  3, 4, 192   ; B4
    NOTE  5, 4, 192   ; E5
    NOTE  -5, 4, 192   ; B4
    NOTE  5, 4, 192   ; E5
    NOTE  -5, 4, 192   ; B4
    NOTE  -3, 4, 192   ; G#4
    NOTE  3, 4, 192   ; B4
    NOTE  -3, 4, 192   ; G#4
    NOTE  3, 4, 192   ; B4
    NOTE  3, 4, 192   ; D5
    NOTE  -3, 4, 192   ; B4
    NOTE  3, 4, 192   ; D5
    NOTE  -3, 4, 192   ; B4
    NOTE  -5, 4, 192   ; F#4
    NOTE  2, 4, 192   ; G#4
    ENDPAT

Pat_084: ; tone, song 5 CH3, entry pitch G#2
    DELAY 0
    NOTE  0, 5, 192   ; G#2
    NOTE  8, 5, 192   ; E3
    NOTE  4, 5, 192   ; G#3
    NOTE  3, 5, 192   ; B3
    NOTE  5, 5, 192   ; E4
    NOTE  -5, 5, 192   ; B3
    NOTE  -3, 5, 192   ; G#3
    NOTE  -4, 5, 192   ; E3
    NOTE  -8, 5, 192   ; G#2
    NOTE  6, 5, 192   ; D3
    NOTE  6, 5, 192   ; G#3
    NOTE  3, 5, 192   ; B3
    NOTE  3, 5, 192   ; D4
    NOTE  -3, 5, 192   ; B3
    NOTE  3, 5, 192   ; D4
    NOTE  -3, 5, 192   ; B3
    ENDPAT

Pat_085: ; tone, song 5 CH2, entry pitch C5
    DELAY 0
    INSTR 1, 0
    NOTEL 0, 4, 384   ; C5
    INSTR 2, 0
    NOTE  7, 4, 192   ; G5
    NOTE  -7, 4, 192   ; C5
    NOTE  12, 4, 192   ; C6
    NOTEL -2, 4, 384   ; A#5
    INSTR 1, 0
    NOTEL -2, 4, 576   ; G#5
    INSTR 2, 0
    NOTE  -1, 4, 192   ; G5
    NOTE  -3, 4, 192   ; E5
    INSTR 1, 0
    NOTEL 3, 4, 384   ; G5
    NOTEL -3, 4, 384   ; E5
    ENDPAT

Pat_086: ; tone, song 5 CH1, entry pitch E4
    DELAY 0
    NOTEL 0, 4, 1536  ; E4
    NOTEL -2, 4, 1536  ; D4
    ENDPAT

Pat_087: ; tone, song 5 CH2, entry pitch B5
    DELAY 0
    INSTR 1, 0
    NOTE  0, 3, 48    ; B5
    NOTE  2, 3, 48    ; C#6
    NOTE  -2, 3, 48    ; B5
    NOTE  2, 3, 48    ; C#6
    NOTE  -2, 3, 48    ; B5
    NOTE  2, 3, 48    ; C#6
    NOTE  -2, 3, 48    ; B5
    NOTE  2, 3, 48    ; C#6
    NOTE  -2, 3, 48    ; B5
    NOTE  2, 3, 48    ; C#6
    NOTE  -2, 3, 48    ; B5
    NOTE  2, 3, 48    ; C#6
    NOTE  -2, 3, 48    ; B5
    NOTE  2, 3, 48    ; C#6
    NOTE  -2, 3, 48    ; B5
    NOTE  2, 3, 48    ; C#6
    NOTEL -2, 3, 768   ; B5
    ENDPAT

Pat_088: ; tone, song 5 CH3, entry pitch F3
    DELAY 0
    NOTE  0, 5, 192   ; F3
    NOTE  4, 5, 192   ; A3
    NOTE  2, 5, 192   ; B3
    NOTE  1, 5, 192   ; C4
    NOTE  4, 5, 192   ; E4
    NOTE  -4, 5, 192   ; C4
    NOTE  -1, 5, 192   ; B3
    NOTE  -2, 5, 192   ; A3
    NOTE  -4, 5, 192   ; F3
    NOTE  4, 5, 192   ; A3
    NOTE  2, 5, 192   ; B3
    NOTE  1, 5, 192   ; C4
    NOTE  2, 5, 192   ; D4
    NOTE  -2, 5, 192   ; C4
    NOTE  -1, 5, 192   ; B3
    NOTE  -2, 5, 192   ; A3
    ENDPAT

Pat_089: ; tone, song 5 CH2, entry pitch F4
    DELAY 0
    NOTE  0, 4, 192   ; F4
    NOTE  4, 4, 192   ; A4
    NOTE  7, 4, 192   ; E5
    NOTE  -7, 4, 192   ; A4
    NOTE  7, 4, 192   ; E5
    NOTE  -7, 4, 192   ; A4
    NOTE  -1, 4, 192   ; G#4
    NOTE  1, 4, 192   ; A4
    NOTE  -4, 4, 192   ; F4
    NOTE  4, 4, 192   ; A4
    NOTE  8, 4, 192   ; F5
    NOTE  -8, 4, 192   ; A4
    NOTE  8, 4, 192   ; F5
    NOTE  -8, 4, 192   ; A4
    NOTE  -1, 4, 192   ; G#4
    NOTE  1, 4, 192   ; A4
    ENDPAT

Pat_090: ; tone, song 5 CH3, entry pitch E3
    DELAY 0
    NOTEL 0, 5, 384   ; E3
    NOTEL 4, 5, 576   ; G#3
    NOTEL 0, 5, 576   ; G#3
    NOTEL -4, 5, 384   ; E3
    NOTEL 4, 5, 1152  ; G#3
    NOTE  -4, 5, 192   ; E3
    NOTE  4, 5, 192   ; G#3
    NOTE  3, 5, 192   ; B3
    NOTE  5, 5, 192   ; E4
    NOTE  7, 5, 192   ; B4
    NOTE  -3, 5, 192   ; G#4
    NOTE  -4, 5, 192   ; E4
    NOTE  -5, 5, 192   ; B3
    NOTE  -7, 5, 192   ; E3
    NOTE  4, 5, 192   ; G#3
    NOTE  3, 5, 192   ; B3
    NOTE  5, 5, 192   ; E4
    NOTE  0, 5, 192   ; E4
    NOTE  -2, 5, 192   ; D4
    NOTE  -2, 5, 192   ; C4
    NOTE  -1, 5, 192   ; B3
    ENDPAT

Pat_091: ; tone, song 5 CH2, entry pitch B3
    DELAYL 288
    INSTR 2, 96
    NOTEL 0, 5, 576   ; B3
    NOTE  5, 5, 192   ; E4
    NOTE  4, 5, 192   ; G#4
    NOTE  3, 5, 192   ; B4
    INSTR 1, 0
    NOTEL -3, 5, 2304  ; G#4
    INSTR 2, 192
    NOTE  -4, 5, 192   ; E4
    NOTE  4, 5, 192   ; G#4
    NOTE  3, 5, 192   ; B4
    INSTR 1, 0
    NOTEL 3, 5, 1536  ; D5
    ENDPAT

Pat_092: ; tone, song 5 CH1, entry pitch E5
    DELAYL 1536
    NOTEL 0, 5, 768   ; E5
    INSTR 3, 0
    NOTE  -12, 5, 160   ; E4
    NOTE  -2, 5, 80    ; D4
    NOTE  2, 5, 48    ; E4
    NOTE  -2, 5, 96    ; D4
    NOTE  -2, 5, 192   ; C4
    NOTE  -1, 5, 192   ; B3
    INSTR 1, 0
    NOTEL -3, 5, 1536  ; G#3
    NOTEL 15, 5, 768   ; B4
    INSTR 3, 0
    TRANSP -19
    NOTE  0, 5, 192   ; E3
    NOTE  -2, 5, 192   ; D3
    NOTE  -2, 5, 192   ; C3
    NOTE  -1, 5, 192   ; B2
    ENDPAT

Pat_093: ; tone, song 6 CH3, entry pitch G3/A3
    DELAY 96
    INSTR 0, 160
    NOTEL 0, 5, 384   ; G3
    NOTEL 0, 5, 384   ; G3
    NOTEL 0, 5, 384   ; G3
    NOTE  0, 5, 128   ; G3
    ENDPAT

Pat_094: ; tone, song 6 CH2, entry pitch A4
    DELAYL 704
    INSTR 2, 64
    NOTE  0, 4, 128   ; A4
    NOTE  2, 4, 128   ; B4
    NOTE  2, 4, 128   ; C#5
    NOTE  3, 4, 128   ; E5
    NOTE  2, 4, 128   ; F#5
    NOTE  2, 4, 128   ; G#5
    ENDPAT

Pat_095: ; noise, song 6 CH4
    DELAYL 256
    DRUM 1, 3, 128
    DRUML 1, 5, 256
    DRUML 1, 3, 384
    DRUM 1, 3, 128
    DRUML 1, 5, 256
    DRUM 1, 3, 128
    ENDPAT

Pat_096: ; tone, song 6 CH1, entry pitch E3/F#3
    DELAY 0
    INSTR 3, 0
    NOTEL 0, 5, 256   ; E3
    NOTE  7, 5, 128   ; B3
    NOTEL -12, 5, 256   ; B2
    NOTE  12, 5, 128   ; B3
    NOTEL -7, 5, 256   ; E3
    NOTE  7, 5, 134   ; B3
    NOTE  -12, 5, 128   ; B2
    NOTE  2, 5, 122   ; C#3
    NOTE  10, 5, 128   ; B3
    ENDPAT

Pat_097: ; tone, song 6 CH2, entry pitch A5
    DELAY 0
    INSTR 1, 0
    NOTEL 0, 4, 768   ; A5
    NOTEL -1, 4, 576   ; G#5
    NOTE  -2, 4, 96    ; F#5
    NOTE  2, 4, 96    ; G#5
    NOTEL -2, 4, 256   ; F#5
    NOTEL 2, 4, 256   ; G#5
    NOTEL -2, 4, 256   ; F#5
    NOTEL -5, 4, 768   ; C#5
    ENDPAT

Pat_098: ; tone, song 6 CH1, entry pitch G3/A3
    DELAY 0
    INSTR 3, 2
    NOTE  0, 5, 254   ; G3
    NOTE  4, 5, 132   ; B3
    NOTE  -10, 5, 252   ; C#3
    NOTE  10, 5, 120   ; B3
    NOTEL -4, 5, 264   ; G3
    NOTE  4, 5, 128   ; B3
    NOTEL -10, 5, 256   ; C#3
    NOTE  10, 5, 130   ; B3
    NOTE  -4, 5, 254   ; G3
    NOTE  4, 5, 124   ; B3
    NOTEL -10, 5, 260   ; C#3
    NOTE  10, 5, 122   ; B3
    NOTEL -4, 5, 262   ; G3
    NOTE  4, 5, 134   ; B3
    NOTE  -4, 5, 124   ; G3
    NOTE  2, 5, 126   ; A3
    NOTE  2, 5, 128   ; B3
    ENDPAT

Pat_099: ; tone, song 6 CH2, entry pitch C#5
    DELAY 0
    INSTR 2, 0
    NOTEL 0, 4, 256   ; C#5
    NOTE  1, 4, 128   ; D5
    NOTEL 2, 4, 256   ; E5
    NOTEL -2, 4, 384   ; D5
    NOTE  -1, 4, 128   ; C#5
    NOTE  -2, 4, 192   ; B4
    INSTR 1, 64
    NOTEL 2, 4, 1664  ; C#5
    ENDPAT

Pat_100: ; tone, song 6 CH2, entry pitch G5
    DELAY 0
    INSTR 3, 0
    NOTE  0, 3, 128   ; G5
    NOTE  4, 3, 128   ; B5
    NOTE  3, 3, 128   ; D6
    NOTE  -3, 3, 128   ; B5
    NOTE  -4, 3, 128   ; G5
    NOTE  4, 3, 128   ; B5
    NOTE  -4, 3, 128   ; G5
    NOTE  4, 3, 128   ; B5
    NOTE  3, 3, 128   ; D6
    NOTE  -3, 3, 128   ; B5
    NOTE  -4, 3, 128   ; G5
    NOTE  4, 3, 128   ; B5
    ENDPAT

Pat_101: ; tone, song 6 CH2, entry pitch G5
    DELAY 0
    NOTE  0, 3, 128   ; G5
    NOTE  4, 3, 128   ; B5
    NOTE  3, 3, 128   ; D6
    NOTE  -3, 3, 128   ; B5
    NOTE  -4, 3, 128   ; G5
    NOTE  4, 3, 128   ; B5
    NOTE  1, 3, 128   ; C6
    NOTE  2, 3, 128   ; D6
    NOTE  -2, 3, 128   ; C6
    NOTE  -1, 3, 128   ; B5
    NOTE  -4, 3, 128   ; G5
    NOTE  4, 3, 128   ; B5
    ENDPAT

Pat_102: ; tone, song 6 CH1, entry pitch A4
    DELAY 0
    INSTRL 2, 384
    NOTEL 0, 5, 768   ; A4
    NOTEL 0, 5, 768   ; A4
    NOTEL 4, 5, 384   ; C#5
    NOTEL 0, 5, 256   ; C#5
    NOTEL 3, 5, 256   ; E5
    NOTEL -3, 5, 640   ; C#5
    NOTEL -4, 5, 768   ; A4
    NOTEL 0, 5, 768   ; A4
    NOTEL 0, 5, 384   ; A4
    NOTEL 5, 5, 256   ; D5
    NOTEL -1, 5, 256   ; C#5
    NOTEL -4, 5, 256   ; A4
    ENDPAT

Pat_103: ; tone, song 6 CH3, entry pitch F#3
    DELAY 0
    NOTEL 0, 5, 256   ; F#3
    NOTE  7, 5, 128   ; C#4
    NOTEL -12, 5, 256   ; C#3
    NOTE  12, 5, 128   ; C#4
    NOTEL -7, 5, 256   ; F#3
    NOTE  7, 5, 134   ; C#4
    NOTE  -12, 5, 128   ; C#3
    NOTE  2, 5, 122   ; D#3
    NOTE  10, 5, 128   ; C#4
    ENDPAT

Pat_104: ; tone, song 6 CH2, entry pitch F#4
    DELAY 0
    INSTRL 2, 256
    NOTE  0, 5, 128   ; F#4
    NOTEL 7, 5, 640   ; C#5
    NOTE  -7, 5, 128   ; F#4
    NOTEL 7, 5, 640   ; C#5
    NOTE  -7, 5, 128   ; F#4
    NOTEL 3, 5, 384   ; A4
    NOTEL 0, 5, 256   ; A4
    NOTEL 0, 5, 256   ; A4
    NOTEL 0, 5, 512   ; A4
    NOTE  -5, 5, 128   ; E4
    NOTEL 9, 5, 640   ; C#5
    NOTE  -9, 5, 128   ; E4
    NOTEL 9, 5, 640   ; C#5
    NOTE  -9, 5, 128   ; E4
    NOTEL 9, 5, 384   ; C#5
    NOTEL -4, 5, 256   ; A4
    NOTEL 0, 5, 256   ; A4
    NOTEL 5, 5, 256   ; D5
    ENDPAT

Pat_105: ; tone, song 6 CH3, entry pitch A3
    DELAY 2
    NOTE  0, 5, 254   ; A3
    NOTE  4, 5, 132   ; C#4
    NOTE  -10, 5, 252   ; D#3
    NOTE  10, 5, 120   ; C#4
    NOTEL -4, 5, 264   ; A3
    NOTE  4, 5, 128   ; C#4
    NOTEL -10, 5, 256   ; D#3
    NOTE  10, 5, 130   ; C#4
    NOTE  -4, 5, 254   ; A3
    NOTE  4, 5, 124   ; C#4
    NOTEL -10, 5, 260   ; D#3
    NOTE  10, 5, 122   ; C#4
    NOTEL -4, 5, 262   ; A3
    NOTE  4, 5, 134   ; C#4
    NOTE  -4, 5, 124   ; A3
    NOTE  2, 5, 126   ; B3
    NOTE  2, 5, 128   ; C#4
    ENDPAT

Pat_106: ; tone, song 6 CH2, entry pitch C#5
    DELAY 0
    INSTR 2, 0
    NOTEL 0, 4, 256   ; C#5
    NOTE  1, 4, 128   ; D5
    NOTEL 2, 4, 256   ; E5
    NOTEL -2, 4, 384   ; D5
    NOTE  -3, 4, 128   ; B4
    NOTE  -3, 4, 192   ; G#4
    INSTR 1, 64
    NOTEL 1, 4, 1664  ; A4
    ENDPAT

Pat_107: ; tone, song 6 CH2, entry pitch A4
    DELAYL 704
    INSTR 2, 64
    NOTE  0, 5, 128   ; A4
    NOTE  2, 5, 128   ; B4
    NOTE  2, 5, 128   ; C#5
    NOTE  3, 5, 128   ; E5
    NOTE  2, 5, 128   ; F#5
    NOTE  2, 5, 128   ; G#5
    ENDPAT

Pat_108: ; tone, song 7 CH2, entry pitch B2/C#3/F#3/G#3
    DELAY 0
    INSTR 3, 0
    NOTE  0, 5, 192   ; B2
    NOTE  0, 5, 96    ; B2
    NOTE  0, 5, 96    ; B2
    NOTE  0, 5, 192   ; B2
    NOTE  0, 5, 192   ; B2
    NOTE  0, 5, 96    ; B2
    NOTE  0, 5, 96    ; B2
    NOTE  0, 5, 192   ; B2
    NOTE  0, 5, 192   ; B2
    NOTE  0, 5, 192   ; B2
    ENDPAT

Pat_109: ; tone, song 7 CH1, song 7 CH3, entry pitch C#5/D#5
    DELAY 0
    INSTR 3, 0
    NOTE  0, 3, 96    ; C#5
    NOTE  3, 3, 96    ; E5
    NOTE  5, 3, 96    ; A5
    NOTE  2, 3, 96    ; B5
    NOTE  5, 3, 96    ; E6
    NOTE  5, 3, 96    ; A6
    NOTE  -3, 3, 96    ; F#6
    NOTE  -2, 3, 96    ; E6
    ENDPAT

Pat_110: ; noise, song 7 CH4
    DELAYL 960
    DRUM 1, 4, 192
    DRUM 1, 4, 192
    DRUML 3, 3, 1152
    DRUM 1, 4, 96
    DRUM 1, 4, 96
    DRUML 1, 4, 384
    ENDPAT

Pat_111: ; tone, song 7 CH1, song 7 CH3, entry pitch C#6/D#6
    DELAY 0
    NOTE  0, 3, 96    ; C#6
    NOTE  -2, 3, 96    ; B5
    NOTE  -2, 3, 96    ; A5
    NOTE  -3, 3, 96    ; F#5
    NOTE  5, 3, 96    ; B5
    NOTE  -2, 3, 96    ; A5
    NOTE  -3, 3, 96    ; F#5
    NOTE  -2, 3, 96    ; E5
    ENDPAT

Pat_112: ; tone, song 7 CH1, entry pitch F#5
    DELAY 0
    INSTR 1, 2
    NOTEL 0, 4, 574   ; F#5
    NOTEL -3, 4, 960   ; D#5
    NOTEL 3, 4, 576   ; F#5
    NOTEL -3, 4, 960   ; D#5
    ENDPAT

Pat_113: ; tone, song 7 CH1, song 7 CH2, entry pitch B4/C#5
    DELAY 0
    NOTEL 0, 4, 1152  ; B4
    NOTEL 2, 4, 384   ; C#5
    NOTEL -4, 4, 1536  ; A4
    ENDPAT

Pat_114: ; noise, song 7 CH4
    DELAYL 960
    DRUM 1, 4, 192
    DRUML 1, 4, 1344
    DRUM 1, 4, 96
    DRUM 1, 4, 96
    DRUML 1, 4, 384
    ENDPAT

Pat_115: ; tone, song 7 CH1, entry pitch C#5
    DELAY 0
    NOTEL 0, 4, 576   ; C#5
    NOTEL 2, 4, 576   ; D#5
    NOTEL 1, 4, 384   ; E5
    NOTEL 2, 4, 1536  ; F#5
    ENDPAT

Pat_116: ; tone, song 7 CH1, song 7 CH2, entry pitch E5
    DELAY 0
    NOTEL 0, 4, 576   ; E5
    NOTEL -3, 4, 960   ; C#5
    NOTEL -2, 4, 576   ; B4
    NOTEL -2, 4, 960   ; A4
    ENDPAT

Pat_117: ; tone, song 7 CH3, entry pitch A2/B2/E3/F#3
    DELAY 0
    INSTR 0, 0
    NOTE  0, 5, 192   ; A2
    NOTE  0, 5, 96    ; A2
    NOTE  0, 5, 96    ; A2
    NOTE  0, 5, 192   ; A2
    NOTE  0, 5, 192   ; A2
    NOTE  0, 5, 96    ; A2
    NOTE  0, 5, 96    ; A2
    NOTE  0, 5, 192   ; A2
    NOTE  0, 5, 192   ; A2
    NOTE  0, 5, 192   ; A2
    ENDPAT

Pat_118: ; tone, song 7 CH1, entry pitch E5
    DELAY 0
    NOTEL 0, 4, 576   ; E5
    NOTEL -7, 4, 960   ; A4
    NOTEL 7, 4, 576   ; E5
    NOTEL -7, 4, 960   ; A4
    ENDPAT

Pat_119: ; tone, song 7 CH1, entry pitch F#4
    DELAY 0
    NOTEL 0, 4, 1152  ; F#4
    NOTEL 7, 4, 384   ; C#5
    NOTEL -4, 4, 1536  ; A4
    ENDPAT

Pat_120: ; tone, song 7 CH1, entry pitch B4
    DELAY 0
    NOTEL 0, 4, 576   ; B4
    NOTEL -2, 4, 960   ; A4
    NOTEL 2, 4, 576   ; B4
    NOTEL -2, 4, 960   ; A4
    ENDPAT

Pat_121: ; tone, song 7 CH1, entry pitch F#4
    DELAY 0
    NOTEL 0, 4, 576   ; F#4
    NOTEL 7, 4, 576   ; C#5
    NOTEL 1, 4, 384   ; D5
    NOTEL 2, 4, 1536  ; E5
    ENDPAT

Pat_122: ; tone, song 7 CH3, entry pitch E5
    DELAY 0
    INSTR 4, 0
    NOTEL 0, 4, 576   ; E5
    NOTEL -3, 4, 960   ; C#5
    NOTEL -2, 4, 576   ; B4
    NOTEL -2, 4, 960   ; A4
    ENDPAT

Pat_123: ; tone, song 7 CH3, entry pitch F#4
    DELAY 0
    NOTEL 0, 4, 1152  ; F#4
    NOTEL 2, 4, 384   ; G#4
    NOTEL -4, 4, 1528  ; E4
    NOTE  -5, 0, 8     ; B3
    ENDPAT

Pat_124: ; tone, song 7 CH2, entry pitch A3
    DELAY 2
    INSTR 1, 0
    NOTE  0, 5, 94    ; A3
    NOTE  2, 5, 96    ; B3
    NOTE  2, 5, 96    ; C#4
    NOTE  3, 5, 96    ; E4
    NOTE  2, 5, 192   ; F#4
    NOTE  -5, 5, 96    ; C#4
    NOTE  3, 5, 96    ; E4
    NOTE  2, 5, 96    ; F#4
    NOTE  3, 5, 96    ; A4
    NOTE  2, 5, 192   ; B4
    NOTE  -5, 5, 96    ; F#4
    NOTE  3, 5, 96    ; A4
    NOTE  2, 5, 96    ; B4
    NOTE  2, 5, 96    ; C#5
    NOTE  3, 5, 96    ; E5
    NOTE  -3, 5, 96    ; C#5
    NOTE  -2, 5, 96    ; B4
    NOTE  -2, 5, 96    ; A4
    NOTE  9, 5, 96    ; F#5
    NOTE  -2, 5, 96    ; E5
    NOTE  -3, 5, 96    ; C#5
    NOTE  -2, 5, 96    ; B4
    NOTE  10, 5, 96    ; A5
    NOTE  -3, 5, 96    ; F#5
    NOTE  -2, 5, 96    ; E5
    NOTE  -3, 5, 96    ; C#5
    NOTE  3, 5, 96    ; E5
    NOTE  2, 5, 96    ; F#5
    NOTE  3, 5, 96    ; A5
    NOTE  -3, 5, 96    ; F#5
    NOTEL 5, 5, 384   ; B5
    INSTR 2, 0
    NOTE  0, 5, 192   ; B5
    NOTE  -2, 5, 164   ; A5
    NOTE  2, 5, 28    ; B5
    NOTE  2, 5, 192   ; C#6
    INSTR 1, 0
    NOTEL -2, 5, 384   ; B5
    NOTE  -2, 5, 96    ; A5
    NOTE  -3, 5, 96    ; F#5
    NOTEL -2, 5, 1536  ; E5
    NOTEL -5, 5, 384   ; B4
    INSTR 2, 0
    NOTE  2, 5, 192   ; C#5
    INSTR 1, 0
    NOTEL 0, 5, 768   ; C#5
    NOTE  -9, 5, 192   ; E4
    NOTE  2, 5, 192   ; F#4
    NOTE  3, 5, 192   ; A4
    NOTE  2, 5, 192   ; B4
    NOTEL 2, 5, 768   ; C#5
    NOTE  -2, 5, 96    ; B4
    NOTE  -2, 5, 96    ; A4
    NOTEL 2, 5, 384   ; B4
    NOTE  -2, 5, 192   ; A4
    NOTE  -3, 5, 192   ; F#4
    NOTE  10, 5, 96    ; E5
    NOTE  -3, 5, 96    ; C#5
    NOTE  -2, 5, 96    ; B4
    NOTE  -2, 5, 96    ; A4
    NOTE  -3, 5, 96    ; F#4
    NOTE  -2, 5, 96    ; E4
    NOTE  2, 5, 96    ; F#4
    NOTEL -5, 5, 260   ; C#4
    INSTR 2, 16
    NOTE  -2, 5, 204   ; B3
    INSTR 1, 0
    NOTEL -2, 5, 1152  ; A3
    NOTE  0, 5, 96    ; A3
    NOTE  7, 5, 96    ; E4
    NOTE  -3, 5, 96    ; C#4
    NOTE  -2, 5, 96    ; B3
    NOTE  7, 5, 96    ; F#4
    NOTE  -2, 5, 96    ; E4
    NOTE  2, 5, 96    ; F#4
    NOTE  3, 5, 96    ; A4
    NOTE  2, 5, 96    ; B4
    NOTE  5, 5, 96    ; E5
    NOTE  -3, 5, 96    ; C#5
    NOTE  -2, 5, 96    ; B4
    NOTE  7, 5, 96    ; F#5
    NOTE  -2, 5, 96    ; E5
    NOTE  2, 5, 96    ; F#5
    NOTE  3, 5, 96    ; A5
    NOTE  -5, 5, 96    ; E5
    NOTE  -5, 5, 96    ; B4
    NOTE  7, 5, 96    ; F#5
    NOTE  -7, 5, 96    ; B4
    NOTE  10, 5, 96    ; A5
    NOTE  -10, 5, 96    ; B4
    NOTE  12, 5, 96    ; B5
    NOTE  -12, 5, 96    ; B4
    NOTE  14, 5, 96    ; C#6
    NOTE  -2, 5, 96    ; B5
    NOTE  -2, 5, 96    ; A5
    NOTE  -3, 5, 96    ; F#5
    NOTE  5, 5, 96    ; B5
    NOTE  -2, 5, 96    ; A5
    NOTE  -3, 5, 96    ; F#5
    NOTE  -9, 5, 96    ; A4
    NOTEL 2, 5, 384   ; B4
    INSTR 2, 0
    NOTE  0, 5, 192   ; B4
    NOTE  -2, 5, 192   ; A4
    NOTE  2, 5, 48    ; B4
    NOTE  2, 5, 48    ; C#5
    NOTE  -2, 5, 48    ; B4
    NOTE  -2, 5, 48    ; A4
    INSTR 1, 0
    NOTEL 2, 5, 432   ; B4
    NOTE  -5, 5, 48    ; F#4
    NOTE  3, 5, 48    ; A4
    NOTE  2, 5, 48    ; B4
    NOTE  2, 5, 240   ; C#5
    NOTE  -2, 5, 48    ; B4
    NOTE  -2, 5, 48    ; A4
    NOTE  -3, 5, 48    ; F#4
    NOTE  -2, 5, 240   ; E4
    NOTE  -3, 5, 48    ; C#4
    NOTE  3, 5, 48    ; E4
    NOTE  2, 5, 48    ; F#4
    NOTE  3, 5, 240   ; A4
    NOTE  -3, 5, 48    ; F#4
    NOTE  -2, 5, 48    ; E4
    NOTE  -2, 5, 48    ; D4
    NOTE  -1, 5, 192   ; C#4
    NOTE  0, 5, 48    ; C#4
    NOTE  1, 5, 48    ; D4
    NOTE  -1, 5, 48    ; C#4
    NOTE  -2, 5, 48    ; B3
    NOTEL -2, 5, 1536  ; A3
    ENDPAT

Pat_125: ; noise, song 8 CH4
    DELAYL 384
    DRUML 1, 5, 768
    DRUML 1, 5, 384
    ENDPAT

Pat_126: ; tone, song 8 CH2, entry pitch A4
    DELAY 0
    INSTR 2, 0
    NOTEL 0, 5, 384   ; A4
    NOTEL -1, 5, 384   ; G#4
    NOTEL -2, 5, 384   ; F#4
    NOTEL 2, 5, 256   ; G#4
    NOTE  -2, 5, 100   ; F#4
    NOTE  2, 5, 28    ; G#4
    NOTEL 1, 5, 384   ; A4
    NOTEL -1, 5, 384   ; G#4
    NOTEL -2, 5, 384   ; F#4
    NOTEL 2, 5, 256   ; G#4
    NOTE  0, 5, 128   ; G#4
    ENDPAT

Pat_127: ; tone, song 8 CH2, entry pitch B3
    DELAY 192
    INSTR 1, 64
    NOTEL 0, 5, 2240  ; B3
    INSTR 2, 64
    NOTE  7, 5, 128   ; F#4
    NOTEL 2, 5, 256   ; G#4
    NOTE  -2, 5, 128   ; F#4
    ENDPAT

Pat_128: ; tone, song 8 CH2, entry pitch G#4
    DELAY 0
    INSTR 2, 0
    NOTEL 0, 5, 384   ; G#4
    NOTEL 3, 5, 384   ; B4
    NOTEL 2, 5, 384   ; C#5
    NOTEL -2, 5, 384   ; B4
    NOTEL -1, 5, 384   ; A#4
    NOTE  -2, 5, 248   ; G#4
    INSTR 1, 8
    NOTEL -2, 5, 704   ; F#4
    INSTR 2, 64
    NOTEL 2, 5, 384   ; G#4
    NOTE  0, 5, 128   ; G#4
    NOTEL 3, 5, 384   ; B4
    NOTEL 2, 5, 384   ; C#5
    NOTEL -2, 5, 384   ; B4
    NOTEL -1, 5, 384   ; A#4
    NOTE  -2, 5, 192   ; G#4
    INSTR 1, 64
    NOTEL -2, 5, 758   ; F#4
    INSTR 2, 10
    NOTEL 2, 5, 384   ; G#4
    NOTE  0, 5, 128   ; G#4
    NOTEL 3, 5, 384   ; B4
    NOTEL 2, 5, 384   ; C#5
    NOTEL -2, 5, 384   ; B4
    NOTEL -3, 5, 384   ; G#4
    NOTEL 3, 5, 384   ; B4
    NOTEL 2, 5, 384   ; C#5
    NOTE  -2, 5, 192   ; B4
    INSTR 1, 64
    NOTEL 2, 5, 1664  ; C#5
    NOTEL 0, 4, 1536  ; C#5
    ENDPAT

Pat_129: ; tone, song 8 CH1, entry pitch E4
    DELAY 0
    INSTR 2, 0
    NOTEL 0, 5, 384   ; E4
    NOTEL 4, 5, 384   ; G#4
    NOTEL 1, 5, 384   ; A4
    NOTEL -1, 5, 384   ; G#4
    NOTEL -2, 5, 384   ; F#4
    NOTE  -5, 5, 248   ; C#4
    INSTR 1, 8
    NOTEL -3, 5, 704   ; A#3
    INSTR 2, 64
    NOTEL 6, 5, 384   ; E4
    NOTE  0, 5, 128   ; E4
    NOTEL 4, 5, 384   ; G#4
    NOTEL 1, 5, 384   ; A4
    NOTEL -1, 5, 384   ; G#4
    NOTEL -2, 5, 384   ; F#4
    NOTE  -5, 5, 248   ; C#4
    INSTR 1, 8
    NOTEL -3, 5, 760   ; A#3
    INSTR 2, 8
    NOTEL 6, 5, 384   ; E4
    NOTE  0, 5, 128   ; E4
    NOTEL 4, 5, 384   ; G#4
    NOTEL 1, 5, 384   ; A4
    NOTEL -1, 5, 384   ; G#4
    NOTEL -3, 5, 384   ; F4
    NOTEL 3, 5, 384   ; G#4
    NOTEL 2, 5, 384   ; A#4
    NOTE  -2, 5, 192   ; G#4
    INSTR 1, 64
    NOTEL 1, 5, 1664  ; A4
    NOTEL 1, 4, 1536  ; A#4
    ENDPAT

Pat_130: ; noise, song 8 CH4
    DELAYL 288
    DRUM 1, 5, 96
    DRUML 1, 5, 672
    DRUM 1, 5, 96
    DRUML 1, 5, 1440
    DRUM 1, 5, 96
    DRUML 1, 5, 384
    ENDPAT

Pat_131: ; tone, song 8 CH3, entry pitch F#3
    DELAY 0
    NOTEL 0, 5, 640   ; F#3
    NOTE  0, 5, 128   ; F#3
    NOTEL 0, 5, 768   ; F#3
    ENDPAT

Pat_132: ; tone, song 8 CH2, entry pitch B4
    DELAY 192
    INSTR 3, 64
    NOTEL 0, 5, 512   ; B4
    NOTEL 0, 5, 384   ; B4
    NOTEL -3, 5, 256   ; G#4
    NOTE  -2, 5, 128   ; F#4
    NOTEL 5, 5, 256   ; B4
    NOTEL 0, 5, 384   ; B4
    NOTEL 0, 5, 384   ; B4
    NOTE  -5, 5, 128   ; F#4
    INSTR 2, 0
    NOTEL 2, 5, 256   ; G#4
    NOTE  -2, 5, 100   ; F#4
    NOTE  2, 5, 28    ; G#4
    ENDPAT

Pat_133: ; tone, song 8 CH1, entry pitch F#4
    DELAY 192
    INSTR 3, 64
    NOTEL 0, 5, 512   ; F#4
    NOTEL 0, 5, 384   ; F#4
    NOTEL -2, 5, 256   ; E4
    NOTE  -1, 5, 128   ; D#4
    NOTEL 3, 5, 256   ; F#4
    NOTEL 0, 5, 384   ; F#4
    NOTEL 0, 5, 896   ; F#4
    ENDPAT

Pat_134: ; tone, song 8 CH2, entry pitch C#3
    DELAY 0
    INSTR 3, 0
    NOTEL 0, 5, 384   ; C#3
    NOTEL 2, 5, 384   ; D#3
    NOTEL 1, 5, 384   ; E3
    NOTEL 4, 5, 256   ; G#3
    NOTEL -2, 5, 1664  ; F#3
    ENDPAT

Pat_135: ; tone, song 9 CH3, entry pitch C#4
    DELAYL 2688
    INSTR 0, 0
    NOTE  0, 6, 48    ; C#4
    NOTE  1, 6, 48    ; D4
    NOTE  2, 6, 48    ; E4
    NOTE  2, 6, 48    ; F#4
    NOTE  2, 6, 48    ; G#4
    NOTE  1, 6, 48    ; A4
    NOTE  2, 6, 48    ; B4
    NOTE  2, 6, 48    ; C#5
    NOTE  1, 5, 144   ; D5
    NOTE  6, 5, 144   ; G#5
    NOTE  -11, 5, 144   ; A4
    NOTE  5, 5, 144   ; D5
    NOTE  6, 5, 144   ; G#5
    NOTE  -7, 5, 144   ; C#5
    NOTE  5, 5, 144   ; F#5
    NOTE  5, 5, 144   ; B5
    NOTE  5, 5, 144   ; E6
    NOTE  -3, 6, 240   ; C#6
    ENDPAT

Pat_136: ; tone, song 9 CH2, entry pitch A4
    DELAY 0
    INSTR 1, 0
    NOTEL 0, 6, 384   ; A4
    INSTR 2, 0
    NOTEL -5, 6, 256   ; E4
    NOTE  9, 6, 128   ; C#5
    INSTR 1, 0
    NOTEL -2, 6, 360   ; B4
    INSTR 2, 24
    NOTEL 2, 6, 256   ; C#5
    NOTE  1, 6, 128   ; D5
    INSTR 1, 0
    NOTEL 2, 6, 768   ; E5
    NOTEL -3, 6, 792   ; C#5
    INSTR 2, 72
    NOTE  5, 5, 144   ; F#5
    NOTE  -10, 5, 144   ; G#4
    NOTE  5, 5, 144   ; C#5
    NOTE  5, 5, 144   ; F#5
    NOTE  5, 5, 144   ; B5
    NOTE  -7, 5, 144   ; E5
    NOTE  5, 5, 144   ; A5
    NOTE  5, 5, 144   ; D6
    NOTE  6, 5, 48    ; G#6
    NOTE  1, 6, 240   ; A6
    ENDPAT

Pat_137: ; tone, song 9 CH1, entry pitch C#4
    DELAY 0
    INSTR 1, 0
    NOTEL 0, 6, 384   ; C#4
    INSTR 2, 0
    NOTEL 10, 6, 256   ; B4
    NOTE  -2, 6, 128   ; A4
    INSTR 1, 0
    NOTEL -5, 6, 384   ; E4
    INSTR 2, 0
    NOTEL 5, 6, 256   ; A4
    NOTE  2, 6, 128   ; B4
    INSTR 1, 0
    NOTEL 2, 6, 768   ; C#5
    NOTEL 8, 6, 768   ; A5
    INSTR 2, 48
    NOTE  -5, 5, 144   ; E5
    NOTE  -10, 5, 144   ; F#4
    NOTE  5, 5, 144   ; B4
    NOTE  5, 5, 144   ; E5
    NOTE  5, 5, 144   ; A5
    NOTE  -7, 5, 144   ; D5
    NOTE  6, 5, 144   ; G#5
    NOTE  5, 5, 144   ; C#6
    NOTE  5, 5, 96    ; F#6
    TRANSP -45
    NOTE  0, 6, 240   ; A2
    ENDPAT

Pat_138: ; tone, song 10 CH2, entry pitch C6
    DELAY 0
    INSTR 1, 0
    NOTEL 0, 6, 288   ; C6
    NOTE  -12, 6, 96    ; C5
    INSTR 2, 0
    NOTE  4, 6, 192   ; E5
    NOTE  -4, 6, 192   ; C5
    INSTR 1, 0
    NOTEL 7, 6, 288   ; G5
    NOTE  2, 6, 96    ; A5
    INSTR 2, 0
    NOTE  -2, 6, 192   ; G5
    NOTE  -2, 6, 168   ; F5
    INSTR 1, 24
    NOTEL -1, 6, 384   ; E5
    TRANSP -28
    NOTEL 0, 6, 312   ; C3
    INSTR 2, 8
    TRANSP 28
    NOTE  0, 6, 64    ; E5
    NOTEL 8, 6, 768   ; C6
    ENDPAT

Pat_139: ; tone, song 10 CH3, entry pitch F4
    DELAY 0
    INSTR 1, 0
    NOTE  0, 6, 192   ; F4
    NOTE  -1, 6, 48    ; E4
    NOTE  1, 6, 48    ; F4
    NOTE  -1, 6, 96    ; E4
    INSTR 0, 0
    NOTE  -2, 6, 192   ; D4
    NOTE  -2, 6, 192   ; C4
    INSTR 1, 0
    NOTEL -1, 6, 288   ; B3
    NOTE  1, 6, 96    ; C4
    INSTR 0, 0
    NOTE  2, 6, 192   ; D4
    NOTE  0, 6, 192   ; D4
    INSTR 1, 0
    NOTEL 2, 6, 384   ; E4
    INSTR 0, 0
    NOTEL -12, 6, 384   ; E3
    NOTEL 15, 6, 768   ; G4
    ENDPAT

Pat_140: ; tone, song 10 CH1, entry pitch A4
    DELAY 0
    INSTR 1, 0
    NOTE  0, 6, 192   ; A4
    NOTE  -2, 6, 48    ; G4
    NOTE  2, 6, 48    ; A4
    NOTE  -2, 6, 72    ; G4
    INSTR 2, 24
    NOTE  -2, 6, 192   ; F4
    NOTE  -1, 6, 168   ; E4
    INSTR 1, 24
    NOTEL -2, 6, 288   ; D4
    NOTE  2, 6, 84    ; E4
    INSTR 2, 12
    NOTE  1, 6, 192   ; F4
    NOTE  6, 6, 192   ; B4
    INSTR 1, 0
    NOTEL 1, 6, 360   ; C5
    INSTR 2, 24
    NOTEL -12, 6, 288   ; C4
    NOTE  12, 6, 64    ; C5
    NOTEL 7, 6, 800   ; G5
    ENDPAT

Pat_141: ; noise, song 11 CH4
    DELAY 0
    DRUM 1, 4, 196
    DRUM 1, 4, 184
    DRUM 3, 3, 176
    DRUM 1, 4, 208
    DRUM 1, 4, 100
    DRUM 1, 4, 82
    DRUM 1, 4, 202
    DRUM 3, 3, 196
    DRUM 1, 4, 190
    DRUM 1, 4, 190
    DRUM 1, 4, 194
    DRUM 3, 3, 194
    DRUM 1, 4, 92
    DRUM 1, 4, 92
    DRUM 1, 4, 102
    DRUM 1, 4, 92
    DRUM 1, 4, 198
    DRUM 1, 4, 188
    DRUM 3, 3, 192
    DRUM 1, 4, 4
    ENDPAT

Pat_142: ; tone, song 11 CH1, entry pitch E4/G4
    DELAY 2
    INSTR 2, 2
    NOTE  0, 5, 188   ; E4
    NOTE  4, 5, 192   ; G#4
    NOTE  3, 5, 192   ; B4
    NOTE  -3, 5, 192   ; G#4
    NOTE  -6, 5, 192   ; D4
    NOTE  4, 5, 192   ; F#4
    NOTE  3, 5, 192   ; A4
    NOTE  -3, 5, 192   ; F#4
    NOTE  -2, 5, 192   ; E4
    NOTE  4, 5, 192   ; G#4
    NOTE  3, 5, 192   ; B4
    NOTE  -3, 5, 192   ; G#4
    NOTE  -6, 5, 192   ; D4
    NOTE  4, 5, 192   ; F#4
    NOTE  3, 5, 96    ; A4
    NOTE  -1, 5, 96    ; G#4
    NOTE  -2, 5, 192   ; F#4
    ENDPAT

Pat_143: ; tone, song 11 CH2, entry pitch E5
    DELAY 0
    INSTR 2, 0
    NOTEL 0, 5, 384   ; E5
    NOTE  4, 5, 192   ; G#5
    NOTE  -4, 5, 192   ; E5
    NOTE  7, 5, 192   ; B5
    NOTEL -3, 5, 384   ; G#5
    NOTEL -4, 5, 384   ; E5
    NOTE  0, 5, 192   ; E5
    NOTE  4, 5, 192   ; G#5
    NOTE  -4, 5, 192   ; E5
    NOTE  5, 5, 192   ; A5
    NOTEL -1, 5, 576   ; G#5
    ENDPAT

Pat_144: ; tone, song 11 CH3, entry pitch E3/G3
    DELAY 0
    INSTR 0, 0
    NOTE  0, 5, 192   ; E3
    NOTE  7, 5, 192   ; B3
    NOTE  5, 5, 192   ; E4
    NOTE  -12, 5, 192   ; E3
    NOTE  -2, 5, 192   ; D3
    NOTE  0, 5, 192   ; D3
    NOTE  12, 5, 192   ; D4
    NOTE  -3, 5, 192   ; B3
    NOTE  -7, 5, 192   ; E3
    NOTE  0, 5, 192   ; E3
    NOTE  12, 5, 192   ; E4
    NOTE  -5, 5, 192   ; B3
    NOTE  -9, 5, 192   ; D3
    NOTE  0, 5, 192   ; D3
    NOTE  12, 5, 192   ; D4
    NOTE  -3, 5, 192   ; B3
    ENDPAT

Pat_145: ; tone, song 11 CH2, entry pitch B5
    DELAY 0
    INSTR 1, 0
    NOTEL 0, 5, 384   ; B5
    INSTR 6, 0
    NOTE  1, 5, 192   ; C6
    NOTE  -1, 5, 192   ; B5
    NOTE  3, 5, 192   ; D6
    NOTE  -2, 5, 190   ; C6
    NOTE  -1, 5, 194   ; B5
    INSTR 1, 0
    NOTEL 1, 5, 564   ; C6
    INSTR 6, 10
    NOTE  -1, 5, 186   ; B5
    NOTE  1, 5, 198   ; C6
    NOTE  2, 5, 190   ; D6
    NOTE  2, 5, 194   ; E6
    NOTE  -2, 5, 186   ; D6
    NOTE  -2, 5, 200   ; C6
    INSTR 1, 6
    NOTEL -4, 5, 378   ; G#5
    INSTR 6, 0
    NOTE  1, 5, 190   ; A5
    NOTE  -1, 5, 194   ; G#5
    NOTE  3, 5, 192   ; B5
    NOTE  -2, 5, 190   ; A5
    NOTE  -1, 5, 170   ; G#5
    INSTR 1, 24
    NOTEL 1, 5, 576   ; A5
    NOTE  -1, 5, 48    ; G#5
    NOTE  1, 5, 50    ; A5
    NOTEL -1, 5, 286   ; G#5
    NOTEL -4, 5, 768   ; E5
    ENDPAT

Pat_146: ; tone, song 11 CH3, entry pitch E3
    DELAY 0
    NOTE  0, 5, 192   ; E3
    NOTE  7, 5, 192   ; B3
    NOTE  5, 5, 192   ; E4
    NOTE  -12, 5, 192   ; E3
    NOTE  -2, 5, 192   ; D3
    NOTE  0, 5, 192   ; D3
    NOTE  12, 5, 192   ; D4
    NOTE  -3, 5, 192   ; B3
    NOTE  -7, 5, 192   ; E3
    NOTE  0, 5, 192   ; E3
    NOTE  0, 5, 192   ; E3
    NOTE  7, 5, 192   ; B3
    NOTE  -9, 5, 192   ; D3
    NOTE  0, 5, 192   ; D3
    NOTE  12, 5, 192   ; D4
    NOTE  -3, 5, 192   ; B3
    ENDPAT

Pat_147: ; tone, song 11 CH2, entry pitch B5
    DELAY 0
    INSTR 1, 0
    NOTEL 0, 3, 384   ; B5
    NOTEL 5, 3, 288   ; E6
    NOTE  -5, 3, 94    ; B5
    INSTR 6, 2
    NOTE  7, 3, 192   ; F#6
    NOTE  -4, 3, 192   ; D6
    NOTE  -5, 3, 192   ; A5
    NOTE  5, 3, 192   ; D6
    INSTR 1, 0
    NOTE  -1, 3, 192   ; C#6
    NOTE  1, 3, 96    ; D6
    NOTE  -1, 3, 96    ; C#6
    NOTE  -2, 3, 192   ; B5
    NOTE  2, 3, 96    ; C#6
    NOTE  -2, 3, 96    ; B5
    NOTE  -2, 3, 192   ; A5
    NOTE  2, 3, 96    ; B5
    NOTE  -2, 3, 96    ; A5
    NOTE  -1, 3, 192   ; G#5
    INSTR 6, 0
    NOTE  -2, 3, 192   ; F#5
    INSTR 1, 0
    NOTE  -2, 3, 192   ; E5
    NOTE  2, 3, 96    ; F#5
    NOTE  2, 3, 96    ; G#5
    INSTR 6, 0
    NOTE  1, 3, 192   ; A5
    NOTE  2, 3, 192   ; B5
    NOTE  2, 3, 192   ; C#6
    NOTE  -2, 3, 192   ; B5
    NOTE  -2, 3, 192   ; A5
    NOTE  4, 3, 192   ; C#6
    INSTR 1, 0
    NOTEL -2, 3, 1536  ; B5
    ENDPAT

Pat_148: ; tone, song 11 CH1, song 11 CH2, entry pitch G#4/B4
    DELAY 120
    INSTRL 6, 260
    NOTEL 0, 5, 580   ; G#4
    NOTEL 0, 5, 384   ; G#4
    NOTEL -2, 5, 384   ; F#4
    NOTEL 2, 5, 576   ; G#4
    NOTEL 0, 5, 768   ; G#4
    ENDPAT

Pat_149: ; tone, song 12 CH2, entry pitch E5
    DELAY 0
    INSTR 2, 0
    NOTEL 0, 6, 576   ; E5
    NOTE  0, 6, 96    ; E5
    NOTE  2, 6, 96    ; F#5
    INSTR 1, 0
    NOTEL -2, 6, 768   ; E5
    ENDPAT

Pat_150: ; tone, song 12 CH3, entry pitch F#5
    DELAY 0
    NOTE  0, 5, 128   ; F#5
    NOTE  2, 5, 128   ; G#5
    NOTE  2, 5, 128   ; A#5
    NOTE  1, 5, 128   ; B5
    NOTE  -1, 5, 128   ; A#5
    NOTE  -2, 5, 128   ; G#5
    NOTE  -2, 5, 128   ; F#5
    NOTE  2, 5, 128   ; G#5
    NOTE  2, 5, 128   ; A#5
    NOTE  1, 5, 128   ; B5
    NOTE  2, 5, 128   ; C#6
    NOTE  2, 5, 128   ; D#6
    ENDPAT

Pat_151: ; tone, song 12 CH2, entry pitch D#5
    DELAY 0
    NOTEL 0, 5, 1536  ; D#5
    NOTEL 2, 5, 384   ; F5
    INSTR 6, 0
    NOTE  0, 6, 128   ; F5
    NOTE  0, 6, 128   ; F5
    NOTE  0, 6, 128   ; F5
    INSTR 1, 0
    NOTEL 0, 6, 768   ; F5
    NOTEL -2, 5, 1536  ; D#5
    NOTEL 5, 5, 384   ; G#5
    INSTR 6, 0
    NOTE  0, 6, 128   ; G#5
    NOTE  0, 6, 128   ; G#5
    NOTE  0, 6, 128   ; G#5
    INSTR 1, 0
    NOTEL 0, 6, 768   ; G#5
    ENDPAT

Pat_152: ; tone, song 12 CH1, entry pitch B3
    DELAY 0
    NOTEL 0, 6, 576   ; B3
    INSTR 2, 64
    NOTE  -5, 6, 128   ; F#3
    NOTEL 5, 6, 256   ; B3
    NOTEL 2, 6, 256   ; C#4
    NOTEL 5, 6, 256   ; F#4
    INSTR 1, 0
    NOTEL -1, 6, 384   ; F4
    INSTR 6, 0
    NOTE  6, 6, 128   ; B4
    NOTE  0, 6, 128   ; B4
    NOTE  0, 6, 128   ; B4
    INSTR 1, 0
    NOTEL 0, 6, 768   ; B4
    INSTR 2, 0
    NOTEL -12, 6, 256   ; B3
    NOTEL 2, 6, 256   ; C#4
    NOTEL 2, 6, 256   ; D#4
    NOTEL -2, 6, 256   ; C#4
    NOTEL -2, 6, 256   ; B3
    NOTEL -5, 6, 256   ; F#3
    INSTR 1, 0
    NOTEL 2, 6, 384   ; G#3
    INSTR 6, 0
    TRANSP 21
    NOTE  0, 6, 128   ; F5
    NOTE  0, 6, 128   ; F5
    NOTE  0, 6, 128   ; F5
    INSTR 1, 0
    NOTEL 0, 6, 768   ; F5
    ENDPAT

Pat_153: ; tone, song 12 CH3, entry pitch F6
    DELAY 0
    NOTE  0, 5, 128   ; F6
    NOTE  -2, 5, 128   ; D#6
    NOTE  -2, 5, 128   ; C#6
    NOTE  -2, 5, 128   ; B5
    NOTE  -1, 5, 128   ; A#5
    NOTE  1, 5, 128   ; B5
    NOTE  2, 5, 128   ; C#6
    NOTE  -2, 5, 128   ; B5
    NOTE  -1, 5, 128   ; A#5
    NOTE  -2, 5, 128   ; G#5
    NOTE  -2, 5, 128   ; F#5
    NOTE  -1, 5, 128   ; F5
    ENDPAT

Pat_154: ; tone, song 12 CH3, entry pitch F6
    DELAY 0
    NOTE  0, 5, 128   ; F6
    NOTE  -2, 5, 128   ; D#6
    NOTE  -2, 5, 128   ; C#6
    NOTE  5, 5, 128   ; F#6
    NOTE  -1, 5, 128   ; F6
    NOTE  -2, 5, 128   ; D#6
    NOTE  5, 5, 128   ; G#6
    NOTE  -2, 5, 128   ; F#6
    NOTE  -1, 5, 128   ; F6
    NOTE  -2, 5, 128   ; D#6
    NOTE  -2, 5, 128   ; C#6
    NOTE  -2, 5, 128   ; B5
    ENDPAT

Pat_155: ; tone, song 12 CH3, entry pitch G3
    DELAY 0
    INSTR 1, 0
    NOTEL 0, 6, 1536  ; G3
    NOTEL 6, 6, 1536  ; C#4
    ENDPAT

Pat_156: ; tone, song 12 CH3, entry pitch G4
    DELAY 0
    INSTR 0, 192
    NOTE  0, 6, 192   ; G4
    NOTE  2, 6, 192   ; A4
    NOTE  2, 6, 192   ; B4
    NOTE  3, 6, 192   ; D5
    NOTE  -3, 6, 192   ; B4
    NOTE  -2, 6, 192   ; A4
    NOTEL -2, 6, 384   ; G4
    NOTE  0, 6, 192   ; G4
    NOTE  2, 6, 192   ; A4
    NOTE  2, 6, 192   ; B4
    NOTE  2, 6, 192   ; C#5
    NOTE  -2, 6, 192   ; B4
    NOTE  -2, 6, 192   ; A4
    NOTEL -2, 6, 384   ; G4
    NOTE  6, 6, 192   ; C#5
    NOTE  1, 6, 190   ; D5
    NOTE  2, 6, 194   ; E5
    NOTE  2, 6, 192   ; F#5
    NOTE  -2, 6, 192   ; E5
    NOTE  -2, 6, 192   ; D5
    NOTEL 4, 6, 384   ; F#5
    TRANSP -23
    NOTE  0, 6, 192   ; G3
    NOTE  2, 6, 192   ; A3
    NOTE  2, 6, 192   ; B3
    NOTE  2, 6, 192   ; C#4
    NOTE  -3, 6, 192   ; A#3
    NOTE  -3, 6, 192   ; G3
    NOTE  -3, 6, 192   ; E3
    ENDPAT

Pat_157: ; tone, song 12 CH2, entry pitch G4
    DELAY 0
    INSTR 1, 0
    NOTEL 0, 6, 1536  ; G4
    NOTEL 6, 6, 1536  ; C#5
    NOTEL -6, 6, 1536  ; G4
    ENDPAT

Pat_158: ; tone, song 12 CH1, entry pitch B4
    DELAY 0
    INSTR 1, 0
    NOTEL 0, 6, 768   ; B4
    NOTEL 3, 6, 768   ; D5
    NOTEL 2, 6, 1536  ; E5
    NOTEL -5, 6, 768   ; B4
    NOTEL 3, 6, 768   ; D5
    NOTEL -1, 6, 1536  ; C#5
    ENDPAT

Pat_159: ; tone, song 12 CH1, entry pitch G5
    DELAY 0
    NOTEL 0, 6, 628   ; G5
    INSTR 2, 12
    NOTE  -5, 6, 128   ; D5
    NOTEL 5, 6, 256   ; G5
    NOTEL 4, 6, 256   ; B5
    NOTEL 3, 6, 256   ; D6
    NOTE  -1, 6, 64    ; C#6
    NOTE  1, 6, 64    ; D6
    NOTE  -1, 6, 64    ; C#6
    NOTE  1, 6, 64    ; D6
    NOTE  -1, 6, 64    ; C#6
    NOTE  1, 6, 64    ; D6
    NOTE  -1, 6, 64    ; C#6
    NOTE  1, 6, 64    ; D6
    NOTE  -1, 6, 64    ; C#6
    NOTE  1, 6, 64    ; D6
    NOTE  -1, 6, 64    ; C#6
    NOTE  1, 6, 64    ; D6
    INSTR 1, 0
    NOTEL -1, 6, 256   ; C#6
    NOTEL -2, 6, 256   ; B5
    NOTEL -2, 6, 256   ; A5
    ENDPAT

Pat_160: ; tone, song 12 CH2, entry pitch B4
    DELAY 0
    NOTEL 0, 6, 1536  ; B4
    NOTEL -7, 6, 1536  ; E4
    ENDPAT

Pat_161: ; tone, sfx 16 SFX, entry pitch C3
    DELAY 0
    INSTR 5, 0
    NOTE  0, 7, 14    ; C3
    NOTE  1, 7, 20    ; C#3
    NOTE  1, 7, 26    ; D3
    NOTE  1, 7, 30    ; D#3
    NOTE  1, 7, 36    ; E3
    NOTE  1, 7, 40    ; F3
    NOTE  1, 7, 48    ; F#3
    NOTE  1, 7, 48    ; G3
    NOTE  1, 7, 54    ; G#3
    NOTEL 1, 7, 452   ; A3
    ENDPAT

Pat_162: ; tone, sfx 17 SFX, entry pitch A5
    DELAY 0
    INSTR 1, 0
    NOTE  0, 6, 18    ; A5
    NOTE  1, 6, 16    ; A#5
    NOTE  1, 7, 18    ; B5
    NOTE  1, 7, 20    ; C6
    NOTE  1, 7, 22    ; C#6
    NOTE  1, 7, 24    ; D6
    NOTE  1, 7, 26    ; D#6
    NOTE  1, 7, 22    ; E6
    NOTE  1, 6, 26    ; F6
    NOTE  1, 6, 32    ; F#6
    NOTE  1, 5, 28    ; G6
    NOTE  1, 5, 32    ; G#6
    NOTE  1, 4, 38    ; A6
    NOTE  0, 4, 36    ; A6
    NOTE  -1, 3, 36    ; G#6
    NOTE  0, 3, 32    ; G#6
    NOTE  -1, 3, 32    ; G6
    NOTE  0, 2, 38    ; G6
    NOTE  -1, 2, 34    ; F#6
    NOTE  0, 2, 40    ; F#6
    NOTE  -1, 1, 28    ; F6
    NOTE  0, 1, 38    ; F6
    NOTE  -1, 0, 44    ; E6
    NOTE  0, 0, 56    ; E6
    NOTE  -1, 0, 64    ; D#6
    NOTE  -1, 0, 160   ; D6
    ENDPAT

Pat_163: ; noise, sfx 15 SFX
    DELAY 0
    DRUML 8, 7, 768
    ENDPAT

Pat_164: ; noise, sfx 14 SFX
    DELAY 0
    DRUML 7, 7, 1536
    ENDPAT

Pat_165: ; noise, sfx 13 SFX
    DELAY 0
    DRUML 6, 7, 768
    ENDPAT

Pat_166: ; noise, sfx 12 SFX
    DELAY 0
    DRUML 5, 6, 768
    ENDPAT

Pat_167: ; tone, sfx 10 SFX, entry pitch E4
    DELAY 0
    INSTR 5, 0
    NOTE  0, 7, 48    ; E4
    NOTE  -4, 7, 48    ; C4
    ENDPAT

Pat_168: ; tone, sfx 9 SFX, entry pitch G5
    DELAY 0
    INSTR 7, 0
    NOTE  0, 7, 48    ; G5
    NOTE  2, 7, 48    ; A5
    NOTE  2, 7, 48    ; B5
    NOTE  1, 7, 48    ; C6
    NOTE  -5, 7, 48    ; G5
    NOTE  2, 7, 48    ; A5
    NOTE  2, 7, 48    ; B5
    NOTEL 1, 7, 432   ; C6
    ENDPAT

Pat_169: ; noise, sfx 11 SFX
    DELAY 0
    DRUML 4, 6, 1536
    ENDPAT

Pat_170: ; tone, sfx 8 SFX, entry pitch A6
    DELAY 0
    INSTR 5, 0
    NOTE  0, 7, 48    ; A6
    NOTE  2, 7, 48    ; B6
    NOTE  -2, 6, 48    ; A6
    NOTE  2, 6, 48    ; B6
    NOTE  -2, 5, 48    ; A6
    NOTE  2, 5, 48    ; B6
    NOTE  -2, 4, 48    ; A6
    NOTE  2, 4, 48    ; B6
    NOTE  -2, 3, 48    ; A6
    NOTE  2, 3, 48    ; B6
    NOTE  -2, 2, 48    ; A6
    NOTE  2, 2, 48    ; B6
    NOTE  -2, 1, 192   ; A6
    ENDPAT

Pat_171: ; tone, sfx 7 SFX, entry pitch B5
    DELAY 0
    INSTR 7, 0
    NOTE  0, 5, 32    ; B5
    NOTE  -1, 5, 32    ; A#5
    NOTE  -2, 5, 32    ; G#5
    NOTE  2, 5, 32    ; A#5
    NOTE  -2, 5, 32    ; G#5
    NOTE  -2, 5, 32    ; F#5
    NOTE  2, 5, 32    ; G#5
    NOTE  -2, 5, 32    ; F#5
    NOTE  -1, 5, 32    ; F5
    NOTE  1, 5, 32    ; F#5
    NOTE  2, 5, 32    ; G#5
    NOTE  -3, 5, 32    ; F5
    NOTE  1, 5, 96    ; F#5
    ENDPAT

Pat_172: ; tone, sfx 2 SFX, entry pitch G5
    DELAY 0
    INSTR 5, 2
    NOTE  0, 3, 30    ; G5
    NOTE  -6, 4, 32    ; C#5
    NOTE  6, 4, 32    ; G5
    NOTE  -6, 5, 32    ; C#5
    NOTE  6, 5, 32    ; G5
    NOTE  -6, 5, 32    ; C#5
    NOTE  6, 6, 32    ; G5
    NOTE  -6, 6, 32    ; C#5
    NOTE  6, 6, 32    ; G5
    NOTE  -6, 7, 32    ; C#5
    NOTE  6, 7, 32    ; G5
    NOTE  -6, 7, 32    ; C#5
    ENDPAT

Pat_173: ; tone, sfx 6 SFX, entry pitch F#3
    DELAY 0
    INSTR 7, 0
    NOTE  0, 7, 218   ; F#3
    NOTEL -6, 7, 358   ; C3
    ENDPAT

Pat_174: ; tone, sfx 5 SFX, entry pitch G4
    DELAY 0
    INSTR 7, 0
    NOTE  0, 7, 48    ; G4
    NOTE  3, 7, 48    ; A#4
    NOTE  3, 7, 48    ; C#5
    NOTE  3, 7, 48    ; E5
    NOTE  3, 7, 48    ; G5
    NOTE  3, 7, 48    ; A#5
    NOTE  3, 7, 48    ; C#6
    NOTE  -6, 7, 48    ; G5
    NOTE  3, 7, 48    ; A#5
    NOTE  3, 7, 48    ; C#6
    NOTE  3, 7, 48    ; E6
    NOTE  3, 7, 48    ; G6
    NOTE  3, 7, 48    ; A#6
    NOTE  -9, 7, 144   ; C#6
    ENDPAT

Pat_175: ; tone, sfx 4 SFX, entry pitch G3
    DELAY 0
    INSTR 7, 0
    NOTE  0, 7, 18    ; G3
    NOTE  1, 7, 22    ; G#3
    NOTE  1, 7, 28    ; A3
    NOTE  1, 7, 38    ; A#3
    NOTE  1, 7, 42    ; B3
    NOTE  1, 7, 44    ; C4
    NOTE  1, 6, 44    ; C#4
    NOTE  1, 6, 56    ; D4
    NOTE  1, 5, 62    ; D#4
    NOTEL 1, 5, 414   ; E4
    ENDPAT

Pat_176: ; tone, sfx 3 SFX, entry pitch C#6
    DELAY 0
    INSTR 7, 0
    NOTE  0, 7, 64    ; C#6
    NOTE  -4, 7, 64    ; A5
    NOTE  4, 7, 64    ; C#6
    NOTE  3, 7, 64    ; E6
    NOTE  5, 7, 224   ; A6
    ENDPAT

Pat_177: ; tone, sfx 1 SFX, entry pitch G#4
    DELAY 0
    INSTR 7, 0
    NOTE  0, 7, 32    ; G#4
    NOTE  4, 7, 32    ; C5
    NOTE  4, 7, 32    ; E5
    NOTE  4, 7, 32    ; G#5
    NOTE  4, 7, 32    ; C6
    NOTE  4, 7, 32    ; E6
    ENDPAT

Pat_178: ; tone, sfx 0 SFX, entry pitch C5
    DELAY 0
    INSTR 7, 0
    NOTE  0, 7, 32    ; C5
    NOTE  7, 7, 32    ; G5
    NOTE  5, 7, 32    ; C6
    ENDPAT

Song00_Ch1: ; song 0 CH1, song 12 CH1
    PLAY 23, $4F
    PLAY 24, $4F
    PLAY 25, $3B
    PLAY 3, $56
    PLAY 6, $53
    PLAY 8, $53
    PLAY 11, $53
    PLAY 14, $54
    PLAY 17, $54
    PLAY 6, $53
    PLAY 8, $53
    PLAY 11, $53
    PLAY 14, $54
    PLAY 18, $53
    PLAY 22, $56
    ENDLIST

Song00_Ch2: ; song 0 CH2, song 12 CH2
    PLAY 4, $37
    PLAY 10, $43
    PLAY 2, $47
    PLAY 4, $37
    PLAY 10, $43
    PLAY 13, $5B
    PLAY 16, $30
    PLAY 16, $31
    PLAY 4, $37
    PLAY 10, $43
    PLAY 13, $5B
    PLAY 19, $4A
    PLAY 21, $3E
    ENDLIST

Song00_Ch3: ; song 0 CH3, song 12 CH3
    PLAY 5, $37
    PLAY 7, $37
    PLAY 9, $37
    PLAY 1, $37
    PLAY 5, $37
    PLAY 7, $37
    PLAY 9, $37
    PLAY 12, $37
    PLAY 15, $51
    PLAY 5, $37
    PLAY 7, $37
    PLAY 9, $37
    PLAY 12, $37
    OREST 1536
    PLAY 21, $32
    ENDLIST

Song00_Ch4: ; song 0 CH4, song 12 CH4
    PLAY 20, $2A
    OREST 21504
    PLAY 20, $2A
    ENDLIST

Song01_Ch1: ; song 1 CH1
    PLAY 20, $40
    OREST 1536
Song01_Ch1_Loop: ; song 1 CH1
    PLAY 26, $41
    PLAY 36, $41
    PLAY 26, $41
    PLAY 29, $41
    PLAY 32, $45
    PLAY 33, $46
    PLAY 35, $4C
    PLAY 32, $45
    PLAY 33, $46
    PLAY 38, $4C
    PLAY 41, $40
    PLAY 41, $40
    PLAY 41, $40
    PLAY 44, $40
    ENDLIST

Song01_Ch2: ; song 1 CH2
    PLAY 30, $3C
    PLAY 28, $3C
Song01_Ch2_Loop: ; song 1 CH2
    PLAY 30, $3C
    PLAY 30, $3C
    PLAY 30, $3C
    PLAY 28, $3C
    PLAY 30, $3C
    PLAY 30, $3E
    PLAY 30, $3E
    PLAY 30, $37
    PLAY 30, $3C
    PLAY 30, $3E
    PLAY 30, $3E
    PLAY 30, $37
    PLAY 30, $37
    PLAY 30, $37
    PLAY 28, $37
    PLAY 30, $3C
    PLAY 30, $3C
    PLAY 30, $3C
    PLAY 43, $3C
    ENDLIST

Song01_Ch3: ; song 1 CH3
    PLAY 37, $35
    PLAY 27, $35
Song01_Ch3_Loop: ; song 1 CH3
    PLAY 37, $35
    PLAY 37, $35
    PLAY 37, $35
    PLAY 27, $35
    PLAY 31, $39
    PLAY 34, $34
    PLAY 31, $39
    PLAY 34, $34
    PLAY 34, $34
    PLAY 34, $34
    PLAY 39, $34
    PLAY 40, $34
    PLAY 40, $34
    PLAY 40, $34
    PLAY 42, $34
    ENDLIST

Song01_Ch4: ; song 1 CH4
    PLAY 20, $2A
    OREST 1536
Song01_Ch4_Loop: ; song 1 CH4
    PLAY 20, $2A
    OREST 26112
    PLAY 20, $2A
    ENDLIST

Song02_Ch1: ; song 2 CH1
    PLAY 48, $45
    PLAY 48, $45
    PLAY 51, $4C
    PLAY 44, $3E
    ENDLIST

Song02_Ch2: ; song 2 CH2
    PLAY 46, $36
    PLAY 46, $36
    PLAY 50, $45
    PLAY 49, $45
    PLAY 49, $45
    PLAY 52, $4A
    PLAY 45, $45
    ENDLIST

Song02_Ch3: ; song 2 CH3
    PLAY 47, $32
    PLAY 47, $32
    PLAY 47, $32
    PLAY 47, $32
    PLAY 47, $39
    PLAY 47, $39
    PLAY 47, $32
    PLAY 53, $32
    ENDLIST

Song02_Ch4: ; song 2 CH4
    PLAY 20, $2A
    OREST 3072
    PLAY 20, $2A
    OREST 4608
    PLAY 20, $2A
    ENDLIST

Song03_Ch1: ; song 3 CH1
    PLAY 54, $34
    PLAY 54, $34
Song03_Ch1_Loop: ; song 3 CH1
    PLAY 54, $34
    PLAY 54, $34
    PLAY 64, $51
    PLAY 54, $34
    PLAY 54, $34
    PLAY 54, $34
    PLAY 54, $3B
    PLAY 54, $3B
    PLAY 54, $34
    PLAY 58, $49
    PLAY 54, $39
    PLAY 54, $39
    PLAY 54, $34
    PLAY 54, $3B
    PLAY 59, $51
    PLAY 20, $40
    PLAY 61, $3E
    PLAY 68, $42
    PLAY 54, $34
    PLAY 54, $34
    PLAY 66, $34
    PLAY 20, $40
    PLAY 61, $3E
    PLAY 68, $42
    PLAY 54, $34
    PLAY 54, $34
    PLAY 66, $34
    ENDLIST

Song03_Ch2: ; song 3 CH2
    PLAY 20, $40
    PLAY 20, $40
Song03_Ch2_Loop: ; song 3 CH2
    PLAY 62, $45
    PLAY 63, $49
    PLAY 62, $45
    PLAY 56, $49
    PLAY 57, $45
    PLAY 60, $3E
    PLAY 60, $42
    PLAY 60, $45
    PLAY 67, $45
    PLAY 69, $3D
    PLAY 60, $34
    PLAY 65, $51
    PLAY 60, $3E
    PLAY 60, $42
    PLAY 60, $45
    PLAY 67, $45
    PLAY 69, $3D
    PLAY 60, $34
    PLAY 65, $51
    ENDLIST

Song03_Ch3: ; song 3 CH3
    PLAY 55, $2D
    PLAY 55, $2D
Song03_Ch3_Loop: ; song 3 CH3
    PLAY 55, $2D
    PLAY 55, $2D
    PLAY 55, $2D
    PLAY 55, $2D
    PLAY 55, $2D
    PLAY 55, $2D
    PLAY 55, $34
    PLAY 55, $34
    PLAY 55, $2D
    PLAY 55, $2D
    PLAY 55, $32
    PLAY 55, $32
    PLAY 55, $2D
    PLAY 55, $34
    PLAY 55, $2D
    PLAY 55, $2D
    PLAY 55, $32
    PLAY 55, $32
    PLAY 55, $32
    PLAY 55, $32
    PLAY 55, $2D
    PLAY 55, $2D
    PLAY 55, $2D
    PLAY 55, $2D
    PLAY 55, $32
    PLAY 55, $32
    PLAY 55, $32
    PLAY 55, $32
    PLAY 55, $2D
    PLAY 55, $2D
    PLAY 55, $2D
    PLAY 55, $2D
    ENDLIST

Song03_Ch4: ; song 3 CH4
    PLAY 20, $2A
    OREST 1536
Song03_Ch4_Loop: ; song 3 CH4
    PLAY 20, $2A
    OREST 4608
    PLAY 20, $2A
    OREST 4608
    PLAY 20, $2A
    OREST 4608
    PLAY 20, $2A
    OREST 4608
    PLAY 20, $2A
    OREST 4608
    PLAY 20, $2A
    OREST 4608
    PLAY 20, $2A
    OREST 4608
    PLAY 20, $2A
    OREST 3072
    PLAY 20, $2A
    ENDLIST

Song04_Ch1: ; song 4 CH1
    PLAY 18, $4C
    PLAY 72, $39
    ENDLIST

Song04_Ch2: ; song 4 CH2
    PLAY 19, $43
    PLAY 71, $3D
    ENDLIST

Song04_Ch3: ; song 4 CH3
    PLAY 20, $40
    PLAY 70, $31
    ENDLIST

Song04_Ch4: ; song 4 CH4
    PLAY 20, $2A
    PLAY 20, $2A
    ENDLIST

Song05_Ch1: ; song 5 CH1
    PLAY 73, $3C
    PLAY 76, $38
    PLAY 73, $3C
    PLAY 76, $38
    PLAY 73, $3C
    PLAY 76, $38
    PLAY 73, $3C
    PLAY 76, $38
    PLAY 73, $3C
    PLAY 76, $38
    PLAY 82, $3C
    PLAY 86, $40
    PLAY 82, $3C
    PLAY 86, $40
    PLAY 92, $4C
    ENDLIST

Song05_Ch2: ; song 5 CH2
    PLAY 20, $40
    OREST 3072
    PLAY 87, $53
    PLAY 85, $48
    PLAY 77, $53
    PLAY 78, $4F
    PLAY 79, $44
    PLAY 85, $48
    PLAY 77, $53
    PLAY 78, $4F
    PLAY 79, $44
    PLAY 81, $45
    PLAY 81, $45
    PLAY 83, $44
    PLAY 81, $45
    PLAY 81, $45
    PLAY 89, $41
    PLAY 91, $3B
    ENDLIST

Song05_Ch3: ; song 5 CH3
    PLAY 74, $30
    PLAY 75, $34
    PLAY 74, $30
    PLAY 75, $34
    PLAY 74, $30
    PLAY 75, $34
    PLAY 74, $30
    PLAY 75, $34
    PLAY 74, $30
    PLAY 75, $34
    PLAY 80, $2D
    PLAY 80, $2D
    PLAY 84, $2C
    PLAY 80, $2D
    PLAY 80, $2D
    PLAY 88, $35
    PLAY 90, $34
    ENDLIST

Song05_Ch4: ; song 5 CH4
    PLAY 20, $2A
    OREST 13824
    PLAY 20, $2A
    OREST 15360
    PLAY 20, $2A
    OREST 13824
    PLAY 20, $2A
    ENDLIST

Song06_Ch1: ; song 6 CH1
    PLAY 96, $36
    PLAY 96, $36
    PLAY 98, $39
Song06_Ch1_Loop: ; song 6 CH1
    PLAY 96, $36
    PLAY 96, $36
    PLAY 98, $39
    PLAY 96, $36
    PLAY 96, $36
    PLAY 98, $39
    PLAY 96, $34
    PLAY 96, $34
    PLAY 98, $37
    PLAY 96, $34
    PLAY 96, $34
    PLAY 98, $37
    PLAY 102, $45
    PLAY 102, $45
    PLAY 96, $34
    PLAY 96, $34
    PLAY 98, $37
    PLAY 96, $34
    PLAY 96, $34
    PLAY 98, $37
    PLAY 96, $36
    PLAY 96, $36
    PLAY 98, $39
    ENDLIST

Song06_Ch2: ; song 6 CH2
    PLAY 20, $40
    OREST 3072
    PLAY 94, $45
Song06_Ch2_Loop: ; song 6 CH2
    PLAY 97, $51
    PLAY 99, $49
    PLAY 97, $51
    PLAY 106, $49
    PLAY 100, $4F
    PLAY 101, $4F
    PLAY 100, $4F
    PLAY 101, $4F
    PLAY 100, $4F
    PLAY 101, $4F
    PLAY 100, $4F
    PLAY 101, $4F
    PLAY 104, $42
    PLAY 104, $42
    PLAY 100, $4F
    PLAY 101, $4F
    PLAY 100, $4F
    PLAY 101, $4F
    PLAY 100, $4F
    PLAY 101, $4F
    PLAY 100, $4F
    PLAY 101, $4F
    OREST 4608
    PLAY 107, $45
    ENDLIST

Song06_Ch3: ; song 6 CH3
    PLAY 93, $39
    PLAY 93, $39
    PLAY 93, $39
    PLAY 93, $39
Song06_Ch3_Loop: ; song 6 CH3
    PLAY 93, $39
    PLAY 93, $39
    PLAY 93, $39
    PLAY 93, $39
    PLAY 93, $39
    PLAY 93, $39
    PLAY 93, $39
    PLAY 93, $39
    PLAY 93, $37
    PLAY 93, $37
    PLAY 93, $37
    PLAY 93, $37
    PLAY 93, $37
    PLAY 93, $37
    PLAY 93, $37
    PLAY 93, $37
    PLAY 103, $36
    PLAY 103, $36
    PLAY 105, $39
    PLAY 103, $36
    PLAY 103, $36
    PLAY 105, $39
    PLAY 93, $37
    PLAY 93, $37
    PLAY 93, $37
    PLAY 93, $37
    PLAY 93, $37
    PLAY 93, $37
    PLAY 93, $37
    PLAY 93, $37
    PLAY 93, $39
    PLAY 93, $39
    PLAY 93, $39
    PLAY 93, $39
    ENDLIST

Song06_Ch4: ; song 6 CH4
    PLAY 20, $2A
    OREST 4608
Song06_Ch4_Loop: ; song 6 CH4
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    PLAY 95, $2A
    ENDLIST

Song07_Ch1: ; song 7 CH1
    PLAY 112, $4E
    PLAY 113, $49
    PLAY 112, $4E
    PLAY 113, $49
    PLAY 112, $4E
    PLAY 115, $49
    PLAY 116, $4C
    PLAY 119, $42
    PLAY 118, $4C
    PLAY 119, $42
    PLAY 120, $47
    PLAY 121, $42
    PLAY 109, $49
    PLAY 111, $55
    PLAY 109, $49
    PLAY 111, $55
    PLAY 109, $49
    PLAY 111, $55
    PLAY 109, $49
    PLAY 111, $55
    PLAY 109, $49
    PLAY 111, $55
    PLAY 109, $49
    PLAY 111, $55
    PLAY 109, $49
    PLAY 111, $55
    PLAY 109, $49
    PLAY 111, $55
    ENDLIST

Song07_Ch2: ; song 7 CH2
    PLAY 108, $2F
    PLAY 108, $2F
    PLAY 108, $2F
    PLAY 108, $2F
    PLAY 108, $2F
    PLAY 108, $2F
    PLAY 108, $2F
    PLAY 108, $2F
    PLAY 108, $38
    PLAY 108, $38
    PLAY 108, $31
    PLAY 108, $36
    PLAY 124, $39
    OREST 4608
    PLAY 116, $4C
    PLAY 113, $47
    ENDLIST

Song07_Ch3: ; song 7 CH3
    PLAY 109, $4B
    PLAY 111, $57
    PLAY 109, $4B
    PLAY 111, $57
    PLAY 109, $4B
    PLAY 111, $57
    PLAY 109, $4B
    PLAY 111, $57
    PLAY 109, $4B
    PLAY 111, $57
    PLAY 109, $4B
    PLAY 111, $57
    PLAY 109, $4B
    PLAY 111, $57
    PLAY 109, $4B
    PLAY 111, $57
    PLAY 109, $4B
    PLAY 111, $57
    PLAY 109, $4B
    PLAY 111, $57
    PLAY 109, $4B
    PLAY 111, $57
    PLAY 109, $4B
    PLAY 111, $57
    PLAY 117, $2D
    PLAY 117, $2D
    PLAY 117, $2D
    PLAY 117, $2D
    PLAY 117, $2D
    PLAY 117, $2D
    PLAY 117, $2D
    PLAY 117, $2D
    PLAY 117, $36
    PLAY 117, $36
    PLAY 117, $2F
    PLAY 117, $34
    PLAY 122, $4C
    PLAY 123, $42
    PLAY 117, $2D
    PLAY 117, $2D
    PLAY 117, $2D
    PLAY 117, $2D
    ENDLIST

Song07_Ch4: ; song 7 CH4
    PLAY 114, $2A
    PLAY 110, $2A
    PLAY 114, $2A
    PLAY 110, $2A
    PLAY 114, $2A
    PLAY 110, $2A
    PLAY 114, $2A
    PLAY 110, $2A
    PLAY 114, $2A
    PLAY 110, $2A
    PLAY 114, $2A
    PLAY 110, $2A
    PLAY 114, $2A
    PLAY 110, $2A
    PLAY 114, $2A
    PLAY 110, $2A
    ENDLIST

Song08_Ch1: ; song 8 CH1
    PLAY 20, $40
    OREST 4608
    PLAY 20, $40
    OREST 4608
    PLAY 129, $40
    OREST 3072
    PLAY 133, $42
    OREST 3072
    PLAY 133, $42
    PLAY 129, $40
    OREST 12288
    PLAY 133, $42
    ENDLIST

Song08_Ch2: ; song 8 CH2
    PLAY 126, $45
    PLAY 127, $3B
    PLAY 126, $45
    PLAY 127, $3B
    PLAY 128, $44
    PLAY 126, $45
    PLAY 132, $47
    PLAY 126, $45
    PLAY 132, $47
    PLAY 128, $44
    OREST 6144
    PLAY 134, $31
    OREST 3072
    PLAY 132, $47
    ENDLIST

Song08_Ch3: ; song 8 CH3
    PLAY 55, $2F
    PLAY 55, $34
    PLAY 55, $2F
    PLAY 55, $2F
    PLAY 55, $2F
    PLAY 55, $34
    PLAY 55, $2F
    PLAY 55, $2F
    PLAY 55, $34
    PLAY 55, $36
    PLAY 55, $34
    PLAY 55, $36
    PLAY 55, $34
    PLAY 55, $31
    PLAY 55, $2D
    PLAY 131, $36
    PLAY 55, $2F
    PLAY 55, $34
    PLAY 55, $2F
    PLAY 55, $2F
    PLAY 55, $2F
    PLAY 55, $34
    PLAY 55, $2F
    PLAY 55, $2F
    PLAY 55, $34
    PLAY 55, $36
    PLAY 55, $34
    PLAY 55, $36
    PLAY 55, $34
    PLAY 55, $31
    PLAY 55, $2D
    PLAY 131, $36
    PLAY 55, $2F
    PLAY 55, $34
    PLAY 55, $2F
    PLAY 55, $36
    OREST 3072
    PLAY 55, $2F
    PLAY 55, $2F
    PLAY 55, $2F
    PLAY 55, $2F
    ENDLIST

Song08_Ch4: ; song 8 CH4
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 130, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 130, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    PLAY 125, $2A
    OREST 4608
    PLAY 125, $2A
    ENDLIST

Song09_Ch1: ; song 9 CH1
    PLAY 137, $3D
    ENDLIST

Song09_Ch2: ; song 9 CH2
    PLAY 136, $45
    ENDLIST

Song09_Ch3: ; song 9 CH3
    PLAY 135, $3D
    ENDLIST

Song09_Ch4: ; song 9 CH4
    PLAY 20, $2A
    OREST 1536
    PLAY 20, $2A
    ENDLIST

Song10_Ch1: ; song 10 CH1
    PLAY 140, $45
    ENDLIST

Song10_Ch2: ; song 10 CH2
    PLAY 138, $54
    ENDLIST

Song10_Ch3: ; song 10 CH3
    PLAY 139, $41
    ENDLIST

Song10_Ch4: ; song 10 CH4
    PLAY 20, $2A
    PLAY 20, $2A
    ENDLIST

Song11_Ch1: ; song 11 CH1
    PLAY 142, $40
    PLAY 142, $40
Song11_Ch1_Loop: ; song 11 CH1
    PLAY 142, $40
    PLAY 142, $40
    PLAY 142, $43
    PLAY 142, $40
    PLAY 148, $47
    PLAY 148, $47
    PLAY 142, $43
    PLAY 142, $40
    PLAY 142, $40
    PLAY 142, $40
    PLAY 142, $40
    PLAY 142, $40
    PLAY 142, $40
    PLAY 142, $40
    PLAY 142, $43
    PLAY 142, $40
    PLAY 148, $47
    PLAY 148, $47
    ENDLIST

Song11_Ch2: ; song 11 CH2
    PLAY 20, $40
    OREST 4608
Song11_Ch2_Loop: ; song 11 CH2
    PLAY 143, $4C
    PLAY 143, $4C
    PLAY 145, $53
    PLAY 148, $44
    PLAY 148, $44
    PLAY 145, $53
    PLAY 147, $53
    PLAY 147, $53
    PLAY 143, $4C
    PLAY 143, $4C
    PLAY 145, $53
    PLAY 148, $44
    PLAY 148, $44
    ENDLIST

Song11_Ch3: ; song 11 CH3
    PLAY 144, $34
    PLAY 144, $34
Song11_Ch3_Loop: ; song 11 CH3
    PLAY 144, $34
    PLAY 144, $34
    PLAY 144, $37
    PLAY 144, $34
    PLAY 144, $34
    PLAY 144, $34
    PLAY 144, $37
    PLAY 144, $34
    PLAY 146, $34
    PLAY 146, $34
    PLAY 146, $34
    PLAY 146, $34
    PLAY 144, $34
    PLAY 144, $34
    PLAY 144, $37
    PLAY 144, $34
    PLAY 144, $34
    PLAY 144, $34
    ENDLIST

Song11_Ch4: ; song 11 CH4
    PLAY 141, $2A
    PLAY 141, $2A
Song11_Ch4_Loop: ; song 11 CH4
    PLAY 141, $2A
    PLAY 141, $2A
    PLAY 141, $2A
    PLAY 141, $2A
    PLAY 141, $2A
    PLAY 141, $2A
    PLAY 141, $2A
    PLAY 141, $2A
    PLAY 141, $2A
    PLAY 141, $2A
    PLAY 141, $2A
    PLAY 141, $2A
    PLAY 141, $2A
    PLAY 141, $2A
    PLAY 141, $2A
    PLAY 141, $2A
    OREST 4608
    PLAY 20, $2A
    ENDLIST

Song12_Ch1: ; song 12 CH1
    PLAY 158, $47
    PLAY 152, $3B
    PLAY 159, $4F
    PLAY 17, $54
    ENDLIST

Song12_Ch2: ; song 12 CH2
    PLAY 157, $43
    PLAY 149, $4C
    PLAY 151, $4B
    PLAY 160, $47
    PLAY 16, $30
    PLAY 16, $31
    ENDLIST

Song12_Ch3: ; song 12 CH3
    PLAY 156, $43
    PLAY 150, $4E
    PLAY 153, $59
    PLAY 150, $4E
    PLAY 154, $59
    PLAY 155, $37
    PLAY 15, $51
    ENDLIST

Song12_Ch4: ; song 12 CH4
    PLAY 20, $2A
    OREST 15360
    PLAY 20, $2A
    ENDLIST

Sfx00: ; sfx 0 SFX
    PLAY 178, $48
    ENDLIST

Sfx01: ; sfx 1 SFX
    PLAY 177, $44
    ENDLIST

Sfx02: ; sfx 2 SFX
    PLAY 172, $4F
    ENDLIST

Sfx03: ; sfx 3 SFX
    PLAY 176, $55
    ENDLIST

Sfx04: ; sfx 4 SFX
    PLAY 175, $37
    ENDLIST

Sfx05: ; sfx 5 SFX
    PLAY 174, $43
    ENDLIST

Sfx06: ; sfx 6 SFX
    PLAY 173, $36
    ENDLIST

Sfx07: ; sfx 7 SFX
    PLAY 171, $53
    ENDLIST

Sfx08: ; sfx 8 SFX
    PLAY 170, $5D
    ENDLIST

Sfx09: ; sfx 9 SFX
    PLAY 168, $4F
    ENDLIST

Sfx10: ; sfx 10 SFX
    PLAY 167, $40
    ENDLIST

Sfx11: ; sfx 11 SFX
    PLAY 169, $2A
    ENDLIST

Sfx12: ; sfx 12 SFX
    PLAY 166, $2A
    ENDLIST

Sfx13: ; sfx 13 SFX
    PLAY 165, $2A
    ENDLIST

Sfx14: ; sfx 14 SFX
    PLAY 164, $2A
    ENDLIST

Sfx15: ; sfx 15 SFX
    PLAY 163, $2A
    ENDLIST

Sfx16: ; sfx 16 SFX
    PLAY 161, $30
    ENDLIST

Sfx17: ; sfx 17 SFX
    PLAY 162, $51
    ENDLIST

SongTable: ; 16 bytes per song: (order list, loop list) for CH1, CH2, CH3, CH4
; SndPlaySong accepts 13 and 14 too: they read the SFX table below.
    dw Song00_Ch1, SilentOrder, Song00_Ch2, SilentOrder, Song00_Ch3, SilentOrder, Song00_Ch4, SilentOrder ; 0
    dw Song01_Ch1, Song01_Ch1_Loop, Song01_Ch2, Song01_Ch2_Loop, Song01_Ch3, Song01_Ch3_Loop, Song01_Ch4, Song01_Ch4_Loop ; 1
    dw Song02_Ch1, Song02_Ch1, Song02_Ch2, Song02_Ch2, Song02_Ch3, Song02_Ch3, Song02_Ch4, Song02_Ch4 ; 2
    dw Song03_Ch1, Song03_Ch1_Loop, Song03_Ch2, Song03_Ch2_Loop, Song03_Ch3, Song03_Ch3_Loop, Song03_Ch4, Song03_Ch4_Loop ; 3
    dw Song04_Ch1, SilentOrder, Song04_Ch2, SilentOrder, Song04_Ch3, SilentOrder, Song04_Ch4, SilentOrder ; 4
    dw Song05_Ch1, Song05_Ch1, Song05_Ch2, Song05_Ch2, Song05_Ch3, Song05_Ch3, Song05_Ch4, Song05_Ch4 ; 5
    dw Song06_Ch1, Song06_Ch1_Loop, Song06_Ch2, Song06_Ch2_Loop, Song06_Ch3, Song06_Ch3_Loop, Song06_Ch4, Song06_Ch4_Loop ; 6
    dw Song07_Ch1, Song07_Ch1, Song07_Ch2, Song07_Ch2, Song07_Ch3, Song07_Ch3, Song07_Ch4, Song07_Ch4 ; 7
    dw Song08_Ch1, Song08_Ch1, Song08_Ch2, Song08_Ch2, Song08_Ch3, Song08_Ch3, Song08_Ch4, Song08_Ch4 ; 8
    dw Song09_Ch1, SilentOrder, Song09_Ch2, SilentOrder, Song09_Ch3, SilentOrder, Song09_Ch4, SilentOrder ; 9
    dw Song10_Ch1, SilentOrder, Song10_Ch2, SilentOrder, Song10_Ch3, SilentOrder, Song10_Ch4, SilentOrder ; 10
    dw Song11_Ch1, Song11_Ch1_Loop, Song11_Ch2, Song11_Ch2_Loop, Song11_Ch3, Song11_Ch3_Loop, Song11_Ch4, Song11_Ch4_Loop ; 11
    dw Song12_Ch1, Song00_Ch1, Song12_Ch2, Song00_Ch2, Song12_Ch3, Song00_Ch3, Song12_Ch4, Song00_Ch4 ; 12

SfxTable: ; (order list, loop list); noise SFX start with PLAY x, $2A
    dw Sfx00, SilentOrder ; 0
    dw Sfx01, SilentOrder ; 1
    dw Sfx02, SilentOrder ; 2
    dw Sfx03, SilentOrder ; 3
    dw Sfx04, SilentOrder ; 4
    dw Sfx05, SilentOrder ; 5
    dw Sfx06, SilentOrder ; 6
    dw Sfx07, SilentOrder ; 7
    dw Sfx08, SilentOrder ; 8
    dw Sfx09, SilentOrder ; 9
    dw Sfx10, SilentOrder ; 10
    dw Sfx11, SilentOrder ; 11 noise
    dw Sfx12, SilentOrder ; 12 noise
    dw Sfx13, SilentOrder ; 13 noise
    dw Sfx14, SilentOrder ; 14 noise
    dw Sfx15, SilentOrder ; 15 noise
    dw Sfx16, SilentOrder ; 16
    dw Sfx17, SilentOrder ; 17

PatternTable:
    dw Pat_000, Pat_001, Pat_002, Pat_003, Pat_004, Pat_005, Pat_006, Pat_007
    dw Pat_008, Pat_009, Pat_010, Pat_011, Pat_012, Pat_013, Pat_014, Pat_015
    dw Pat_016, Pat_017, Pat_018, Pat_019, Pat_020, Pat_021, Pat_022, Pat_023
    dw Pat_024, Pat_025, Pat_026, Pat_027, Pat_028, Pat_029, Pat_030, Pat_031
    dw Pat_032, Pat_033, Pat_034, Pat_035, Pat_036, Pat_037, Pat_038, Pat_039
    dw Pat_040, Pat_041, Pat_042, Pat_043, Pat_044, Pat_045, Pat_046, Pat_047
    dw Pat_048, Pat_049, Pat_050, Pat_051, Pat_052, Pat_053, Pat_054, Pat_055
    dw Pat_056, Pat_057, Pat_058, Pat_059, Pat_060, Pat_061, Pat_062, Pat_063
    dw Pat_064, Pat_065, Pat_066, Pat_067, Pat_068, Pat_069, Pat_070, Pat_071
    dw Pat_072, Pat_073, Pat_074, Pat_075, Pat_076, Pat_077, Pat_078, Pat_079
    dw Pat_080, Pat_081, Pat_082, Pat_083, Pat_084, Pat_085, Pat_086, Pat_087
    dw Pat_088, Pat_089, Pat_090, Pat_091, Pat_092, Pat_093, Pat_094, Pat_095
    dw Pat_096, Pat_097, Pat_098, Pat_099, Pat_100, Pat_101, Pat_102, Pat_103
    dw Pat_104, Pat_105, Pat_106, Pat_107, Pat_108, Pat_109, Pat_110, Pat_111
    dw Pat_112, Pat_113, Pat_114, Pat_115, Pat_116, Pat_117, Pat_118, Pat_119
    dw Pat_120, Pat_121, Pat_122, Pat_123, Pat_124, Pat_125, Pat_126, Pat_127
    dw Pat_128, Pat_129, Pat_130, Pat_131, Pat_132, Pat_133, Pat_134, Pat_135
    dw Pat_136, Pat_137, Pat_138, Pat_139, Pat_140, Pat_141, Pat_142, Pat_143
    dw Pat_144, Pat_145, Pat_146, Pat_147, Pat_148, Pat_149, Pat_150, Pat_151
    dw Pat_152, Pat_153, Pat_154, Pat_155, Pat_156, Pat_157, Pat_158, Pat_159
    dw Pat_160, Pat_161, Pat_162, Pat_163, Pat_164, Pat_165, Pat_166, Pat_167
    dw Pat_168, Pat_169, Pat_170, Pat_171, Pat_172, Pat_173, Pat_174, Pat_175
    dw Pat_176, Pat_177, Pat_178


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
