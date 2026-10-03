; =============================================================================
; On the Tiles - Franky, Joe & Dirk (Game Boy) - sound driver
; ROM: "On the Tiles - Franky, Joe & Dirk (E) [!].gb"  (MBC1, 128 KB)
; Audio Visual Magic / Elite Systems, 1993
;
; A 3-voice MOD-style tracker player.  Songs are small ProTracker-like
; modules (128-entry order list, 64-row patterns, 3 voices, effects 0/1/2/
; 8/B/C/D/F); voices 0-2 drive CH1-CH3, and any voice can borrow CH4 for
; noise.  SFX are 3-byte-per-tick register streams that take over CH2.
;
; Bank 0  $1B42-$1B5F   PlaySfx wrapper (game side)
; Bank 1  $4000-$4A90   driver code
;         $4A91-$4C0F   tables
;         $4C10-$5CAF   4 songs
;         $5CB0-$5DBC   instruments, pitch tables, volume envelopes
;         $5DBD-$615E   SFX table and SFX data
; Tick    SndUpdate (1:$41A4) is called from VBlank (0:$2E9E).  It skips every
;         6th call, so music and SFX run at 50 ticks/s.
;
; Rebuild check (RGBDS 0.9.1):
;   rgbasm -o snd.o OnTheTiles_SoundDriver.asm
;   rgblink -p 0xFF -o snd.gb snd.o
;   -> 0:$1B42-$1B5F and 1:$4000-$615E match the original ROM byte for byte.
; =============================================================================

INCLUDE "hardware.inc"

; ------------------------------- WRAM ----------------------------------------
DEF wMusicEnabled    EQU $C8AA  ; game: MUSIC ON/OFF option
DEF wModule          EQU $C8AB  ; 2: song module base (after the $FF prefix)
DEF wOrderTable      EQU $C8AD  ; 2: module + 6
DEF wPatternTable    EQU $C8AF  ; 2: module + $86
DEF wInstrTable      EQU $C8B1  ; 2: instrument pointer table (DE of SndInitSong)
DEF wSfxTable        EQU $C8B3  ; 2: SFX pointer table
DEF wExtFormat       EQU $C8B5  ; 1 if the song began with $FF (transpose byte + 13-byte instruments)
DEF wSongTranspose   EQU $C8B6  ; song transpose (semitones)
DEF wMusicStopped    EQU $C8B7  ; nonzero = music not running (SFX still run)
DEF wSpeed           EQU $C8B8  ; ticks per row (effect F)
DEF wSpeedCount      EQU $C8B9  ; tick countdown to the next row
DEF wRowTick         EQU $C8BA  ; 1 on ticks that read a new row
DEF wRow             EQU $C8BB  ; row in pattern, 0-63
DEF wOrderPos        EQU $C8BC  ; position in the order list
DEF wSongLength      EQU $C8BD  ; order list length
DEF wRestartPos      EQU $C8BE  ; order position used after the last one
DEF wJumpPending     EQU $C8BF  ; 1 = effect B/D seen this row
DEF wJumpTarget      EQU $C8C0  ; effect B target order, $FF = next order (effect D)
DEF wFadeOn          EQU $C8C1  ; fade-out running
DEF wFadeTimer       EQU $C8C2  ; ticks to the next fade step
DEF wFadeLevel       EQU $C8C3  ; NR50 level ($77 -> 0)
DEF wRowNote         EQU $C8C4  ; row decode: note ($3F = none)
DEF wRowFx           EQU $C8C5  ; row decode: effect
DEF wRowParam        EQU $C8C6  ; row decode: parameter
DEF wRowShort        EQU $C8C7  ; 1 = effect 7 row (2 bytes, no parameter)
DEF wFrameDiv        EQU $C8C8  ; 6-frame divider: every 6th call is skipped
DEF wSfxOn           EQU $C8C9  ; SFX playing
DEF wSfxPtr          EQU $C8CA  ; 2: SFX frame pointer
DEF wHwVol1          EQU $C9A0  ; last volume written to CH1
DEF wHwVol2          EQU $C9A1  ; last volume written to CH2
DEF wHwVol3          EQU $C9A2  ; last volume written to CH3 (wave RAM level)
DEF wHwNoiseVol      EQU $C9A3  ; last volume written to CH4
DEF wHwNoiseIdx      EQU $C9A4  ; meant to be the last noise index (see SndWriteHardware)
DEF wMixPeriod1      EQU $C9A5  ; 2: music mix, CH1 period
DEF wMixPeriod2      EQU $C9A7  ; 2: CH2 period
DEF wMixPeriod3      EQU $C9A9  ; 2: CH3 period
DEF wMixNoise        EQU $C9AB  ; noise index
DEF wMixMask         EQU $C9AC  ; bit 0-2 = CH1-3 muted, bit 3-5 = voice 0-2 NOT driving CH4
DEF wMixVol1         EQU $C9AD  ; CH1 volume 0-15
DEF wMixVol2         EQU $C9AE  ; CH2 volume
DEF wMixVol3         EQU $C9AF  ; CH3 volume
DEF wMixUnused       EQU $C9B0  ; 4: copied but never used
DEF wOutPeriod1      EQU $C9B5  ; output copy of wMix ($0F bytes); the SFX overwrites CH2 here
DEF wOutPeriod2      EQU $C9B7
DEF wOutPeriod3      EQU $C9B9
DEF wOutNoise        EQU $C9BB
DEF wOutMask         EQU $C9BC
DEF wOutVol1         EQU $C9BD
DEF wOutVol2         EQU $C9BE
DEF wOutVol3         EQU $C9BF
DEF wOutUnused       EQU $C9C0
DEF wRomBank         EQU $C2C5  ; game: current ROMX bank
DEF wSfxDisabled     EQU $C2D8  ; game: nonzero = PlaySfx wrapper does nothing

; Voice block ($34 bytes).  SndUpdate copies each voice to wCur, works on it,
; and copies it back.
DEF VC_RowPtr        EQU $00  ; (2) pattern stream read pointer
DEF VC_PeriodSlot    EQU $02  ; offset of this voice's period in wMix (0/2/4)
DEF VC_VolSlot       EQU $03  ; offset of this voice's volume in wMix (8/9/10)
DEF VC_ToneOnMask    EQU $04  ; AND mask for wMixMask: enable this voice's tone channel
DEF VC_ToneOffMask   EQU $05  ; OR mask: disable the tone channel
DEF VC_NoiseOnMask   EQU $06  ; AND mask: let this voice drive CH4
DEF VC_NoiseOffMask  EQU $07  ; OR mask: this voice stops driving CH4
DEF VC_InsPitch      EQU $08  ; (2) instrument pitch table (0 = none, tone stays off)
DEF VC_InsNoise      EQU $0A  ; (2) instrument noise table (0 = none)
DEF VC_InsEnv        EQU $0C  ; (2) instrument volume envelope (0 = none)
DEF VC_InsVibSpeed   EQU $0E  ; vibrato half-period in ticks
DEF VC_InsVibDelay   EQU $0F  ; vibrato delay in ticks
DEF VC_InsVibOn      EQU $10  ; 1 = instrument has vibrato
DEF VC_InsBurst      EQU $11  ; noise burst: bit 7 = on, bits 0-6 = ticks
DEF VC_PitchPos      EQU $12  ; (2) pitch table cursor
DEF VC_NoisePos      EQU $14  ; (2) noise table cursor
DEF VC_EnvPos        EQU $16  ; (2) volume envelope cursor
DEF VC_VibTimer      EQU $18  ; ticks until the vibrato offset toggles
DEF VC_VibDelay      EQU $19  ; vibrato delay countdown
DEF VC_VibState      EQU $1A  ; bit 0 = waiting for delay, bit 1 = running
DEF VC_Burst         EQU $1B  ; noise burst countdown (bit 7 = running)
DEF VC_RowFlags      EQU $1C  ; bit 0 = skipping empty rows, bit 1 = portamento, bit 2 = porta up
DEF VC_SkipCount     EQU $1D  ; empty rows left
DEF VC_InsTranspose  EQU $1E  ; instrument transpose (semitones)
DEF VC_Note          EQU $1F  ; current note index into FreqTable
DEF VC_Period        EQU $20  ; (2) current period (before vibrato)
DEF VC_NoiseNote     EQU $22  ; noise note index (noise table accumulator)
DEF VC_NoiseOut      EQU $23  ; noise index sent to wMixNoise (0 = none)
DEF VC_InsNoiseVal   EQU $24  ; instrument fixed noise index
DEF VC_Instr         EQU $25  ; current instrument number ($FF = none loaded)
DEF VC_ArpParam      EQU $26  ; effect 0 parameter (0 = no arpeggio)
DEF VC_ArpPhase      EQU $27  ; arpeggio phase 0/1/2
DEF VC_PortaSpeed    EQU $28  ; effect 1/2 parameter
DEF VC_EnvTimer      EQU $29  ; ticks left on the current envelope step
DEF VC_VolSet        EQU $2A  ; 1 = effect C seen on this row
DEF VC_EnvVol        EQU $2B  ; current envelope volume
DEF VC_Atten         EQU $2C  ; attenuation from effect C (15 - volume)
DEF VC_Unused2D      EQU $2D  ; (2) never used
DEF VC_InsFineVol    EQU $2F  ; instrument +5, added by effect C
DEF VC_VibPhase      EQU $30  ; vibrato: current offset (toggles between 0 and depth)
DEF VC_VibDepth      EQU $31  ; vibrato depth
DEF VC_VibOffset     EQU $32  ; (2) period offset added on output
DEF VC_SIZEOF        EQU $34

DEF wCur             EQU $C8CF
DEF wVoice0          EQU $C904  ; -> CH1
DEF wVoice1          EQU $C938  ; -> CH2
DEF wVoice2          EQU $C96C  ; -> CH3
DEF wCurRowPtr       EQU wCur + VC_RowPtr
DEF wCurPeriodSlot   EQU wCur + VC_PeriodSlot
DEF wCurVolSlot      EQU wCur + VC_VolSlot
DEF wCurToneOnMask   EQU wCur + VC_ToneOnMask
DEF wCurToneOffMask  EQU wCur + VC_ToneOffMask
DEF wCurNoiseOnMask  EQU wCur + VC_NoiseOnMask
DEF wCurNoiseOffMask EQU wCur + VC_NoiseOffMask
DEF wCurInsPitch     EQU wCur + VC_InsPitch
DEF wCurInsNoise     EQU wCur + VC_InsNoise
DEF wCurInsEnv       EQU wCur + VC_InsEnv
DEF wCurInsVibSpeed  EQU wCur + VC_InsVibSpeed
DEF wCurInsVibDelay  EQU wCur + VC_InsVibDelay
DEF wCurInsVibOn     EQU wCur + VC_InsVibOn
DEF wCurInsBurst     EQU wCur + VC_InsBurst
DEF wCurPitchPos     EQU wCur + VC_PitchPos
DEF wCurNoisePos     EQU wCur + VC_NoisePos
DEF wCurEnvPos       EQU wCur + VC_EnvPos
DEF wCurVibTimer     EQU wCur + VC_VibTimer
DEF wCurVibDelay     EQU wCur + VC_VibDelay
DEF wCurVibState     EQU wCur + VC_VibState
DEF wCurBurst        EQU wCur + VC_Burst
DEF wCurRowFlags     EQU wCur + VC_RowFlags
DEF wCurSkipCount    EQU wCur + VC_SkipCount
DEF wCurInsTranspose EQU wCur + VC_InsTranspose
DEF wCurNote         EQU wCur + VC_Note
DEF wCurPeriod       EQU wCur + VC_Period
DEF wCurNoiseNote    EQU wCur + VC_NoiseNote
DEF wCurNoiseOut     EQU wCur + VC_NoiseOut
DEF wCurInsNoiseVal  EQU wCur + VC_InsNoiseVal
DEF wCurInstr        EQU wCur + VC_Instr
DEF wCurArpParam     EQU wCur + VC_ArpParam
DEF wCurArpPhase     EQU wCur + VC_ArpPhase
DEF wCurPortaSpeed   EQU wCur + VC_PortaSpeed
DEF wCurEnvTimer     EQU wCur + VC_EnvTimer
DEF wCurVolSet       EQU wCur + VC_VolSet
DEF wCurEnvVol       EQU wCur + VC_EnvVol
DEF wCurAtten        EQU wCur + VC_Atten
DEF wCurUnused2D     EQU wCur + VC_Unused2D
DEF wCurInsFineVol   EQU wCur + VC_InsFineVol
DEF wCurVibPhase     EQU wCur + VC_VibPhase
DEF wCurVibDepth     EQU wCur + VC_VibDepth
DEF wCurVibOffset    EQU wCur + VC_VibOffset

; --------------------------- data macros --------------------------------------
DEF ___ EQU $3F                    ; no note
; note constants: C_2 = 0 (FreqTable index), Cs2 = 1 ... B_7 = 71
FOR OCT, 2, 8
    DEF C_{d:OCT} EQU (OCT - 2) * 12 + 0
    DEF Cs{d:OCT} EQU (OCT - 2) * 12 + 1
    DEF D_{d:OCT} EQU (OCT - 2) * 12 + 2
    DEF Ds{d:OCT} EQU (OCT - 2) * 12 + 3
    DEF E_{d:OCT} EQU (OCT - 2) * 12 + 4
    DEF F_{d:OCT} EQU (OCT - 2) * 12 + 5
    DEF Fs{d:OCT} EQU (OCT - 2) * 12 + 6
    DEF G_{d:OCT} EQU (OCT - 2) * 12 + 7
    DEF Gs{d:OCT} EQU (OCT - 2) * 12 + 8
    DEF A_{d:OCT} EQU (OCT - 2) * 12 + 9
    DEF As{d:OCT} EQU (OCT - 2) * 12 + 10
    DEF B_{d:OCT} EQU (OCT - 2) * 12 + 11
ENDR

DEF FX_ARP        EQU $0
DEF FX_PORTA_UP   EQU $1
DEF FX_PORTA_DOWN EQU $2
DEF FX_STOP       EQU $8
DEF FX_JUMP       EQU $B
DEF FX_VOLUME     EQU $C
DEF FX_BREAK      EQU $D
DEF FX_SPEED      EQU $F

MACRO row      ; note, instrument (0 = keep), effect, parameter
    db \1, (\2 << 4) | \3, \4
ENDM
MACRO row7     ; note, instrument: effect 7, two-byte row with no parameter
    db \1, (\2 << 4) | 7
ENDM
MACRO empty    ; n empty rows (0 and 1 both mean one row)
    db $80 | \1
ENDM
MACRO instrument ; transpose, burst ticks, burst noise, vibrato (depth<<4|speed), vib delay,
                 ; fine volume, unused, pitch table, noise table, envelope
    db LOW(\1), \2, \3, \4, \5, \6, \7
    dw \8, \9, \<10>
ENDM
MACRO sfx_frame ; c, d, e (see SndMixSfx)
    db \1, \2, \3
ENDM


SECTION "PlaySfx wrapper", ROM0[$1B42]

; -----------------------------------------------------------------------------
; PlaySfx (game side): C = SFX number.  Pages in bank 1 and calls SndPlaySfx
; unless the game's SFX-off flag is set.
; -----------------------------------------------------------------------------
PlaySfx:
    ld a, [wRomBank]
    push af
    ld a, $01
    ld [wRomBank], a
    ld [rROMB0], a
    ld a, [wSfxDisabled]
    or a
    jr nz, .skip
    ld a, c
    call SndPlaySfx
.skip:
    pop af
    ld [wRomBank], a
    ld [rROMB0], a
    ret


SECTION "Sound driver", ROMX[$4000], BANK[1]

; -----------------------------------------------------------------------------
; SndHaltMusic: set wMusicStopped without touching the hardware.
; The music freezes on its current notes (volumes stay where they are).
; No caller found in the ROM.
; -----------------------------------------------------------------------------
SndHaltMusic:
    push af
    ld a, $01
    ld [wMusicStopped], a
    pop af
    ret

; -----------------------------------------------------------------------------
; SndInitSong: start a song.  HL = song (the $FF prefix), DE = instrument
; pointer table (the game always passes InstrumentTable).
; Clears the three voice blocks, reads the header, points every voice at the
; first pattern of order 0, loads VoiceConfig and resets the hardware.
; Does not stop a running SFX.
; -----------------------------------------------------------------------------
SndInitSong:
    push af
    push bc
    push de
    push hl
    push de
    push hl
    ld a, $01                               ; hold the music while the state is rebuilt
    ld [wMusicStopped], a
    xor a
    ld hl, wVoice0                          ; clear wVoice0-wVoice2 (3 x $34 bytes)
    ld c, $9c
.clear:
    ld [hl+], a
    dec c
    jr nz, .clear
    pop hl
    xor a
    ld [wExtFormat], a
    ld [wSongTranspose], a
    ld [wOrderPos], a
    ld [wRow], a
    ld [wJumpPending], a
    ld [wFadeOn], a
    dec a                                   ; $FF: no jump pending
    ld [wJumpTarget], a
    ld a, $06                               ; speed 6 ticks/row
    ld [wSpeed], a
    dec a                                   ; first row is read after 5 ticks
    ld [wSpeedCount], a
    ld a, [hl]
    cp $ff                                  ; $FF prefix: extended format + transpose byte
    jr nz, .noPrefix
    ld a, $01
    ld [wExtFormat], a
    inc hl
    ld a, [hl]
    ld [wSongTranspose], a
    inc hl
.noPrefix:
    push af
    ld a, l
    ld [wModule], a
    ld a, h
    ld [wModule + 1], a
    pop af
    push hl                                 ; HL = module base
    push hl
    ld a, [hl]                              ; +0 song length
    ld [wSongLength], a
    inc hl
    ld a, [hl]                              ; +1 restart position
    ld [wRestartPos], a
    dec hl
    ld bc, $0006                            ; +6 order list (128 bytes)
    add hl, bc
    push af
    ld a, l
    ld [wOrderTable], a
    ld a, h
    ld [wOrderTable + 1], a
    pop af
    pop hl
    ld bc, $0086                            ; +$86 pattern offset table
    add hl, bc
    push af
    ld a, l
    ld [wPatternTable], a
    ld a, h
    ld [wPatternTable + 1], a
    pop af
    push af
    ld a, [wOrderTable]
    ld l, a
    ld a, [wOrderTable + 1]
    ld h, a
    pop af
    ld a, [hl]                              ; first order entry
    add a
    ld b, $00
    ld c, a
    push af
    ld a, [wPatternTable]
    ld l, a
    ld a, [wPatternTable + 1]
    ld h, a
    pop af
    add hl, bc
    ld c, [hl]
    inc hl
    ld b, [hl]
    pop hl
    add hl, bc                              ; pattern = module + offset
    push hl
    push hl
    push hl
    push hl
    ld de, $0004                            ; voice 0 stream = pattern + 4
    add hl, de
    push af
    ld a, l
    ld [wVoice0], a
    ld a, h
    ld [wVoice0 + VC_RowPtr + 1], a
    pop af
    pop hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    push hl
    pop bc
    pop hl
    add hl, bc
    ld bc, $0004
    add hl, bc                              ; voice 1 stream = pattern + word[0] + 4
    push af
    ld a, l
    ld [wVoice1], a
    ld a, h
    ld [wVoice1 + VC_RowPtr + 1], a
    pop af
    pop hl
    inc hl
    inc hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    push hl
    pop bc
    pop hl
    add hl, bc
    ld bc, $0004
    add hl, bc
    push af
    ld a, l
    ld [wVoice2], a                         ; voice 2 stream = pattern + word[2] + 4
    ld a, h
    ld [wVoice2 + VC_RowPtr + 1], a
    pop af
    pop de
    ld a, e                                 ; DE: instrument table
    ld [wInstrTable], a
    ld a, d
    ld [wInstrTable + 1], a
    ld a, $ff                               ; current instrument = $FF so the first one always loads
    ld [wVoice0 + VC_Instr], a
    ld [wVoice1 + VC_Instr], a
    ld [wVoice2 + VC_Instr], a
    ld hl, VoiceConfig                      ; copy the 6 VoiceConfig bytes to +2..+7 of each voice
    ld de, wVoice0 + VC_PeriodSlot
    ld c, $06
.cfg0:
    ld a, [hl+]
    ld [de], a
    inc de
    dec c
    jr nz, .cfg0
    ld de, wVoice1 + VC_PeriodSlot
    ld c, $06
.cfg1:
    ld a, [hl+]
    ld [de], a
    inc de
    dec c
    jr nz, .cfg1
    ld de, wVoice2 + VC_PeriodSlot
    ld c, $06
.cfg2:
    ld a, [hl+]
    ld [de], a
    inc de
    dec c
    jr nz, .cfg2
    call SndInitHardware
    ld a, $06                               ; frame divider
    ld [wFrameDiv], a
    ld a, $77                               ; fade level
    ld [wFadeLevel], a
    xor a                                   ; start playing
    ld [wMusicStopped], a
    pop hl
    pop de
    pop bc
    pop af
    ret

; -----------------------------------------------------------------------------
; SndSetSfxTable: HL = SFX pointer table.  Game passes SfxTable.
; -----------------------------------------------------------------------------
SndSetSfxTable:
    push af
    ld a, l
    ld [wSfxTable], a
    ld a, h
    ld [wSfxTable + 1], a
    pop af
    ret

; -----------------------------------------------------------------------------
; SndReset: re-initialise the hardware (NR50/NR51/NR52 on again), cancel any
; SFX and leave the music stopped.  Game calls: 0:$0274 and 0:$028A (each
; followed by SndSetSfxTable), and 0:$1B68 / 0:$2B4D right before SFX 2 / 4.
; -----------------------------------------------------------------------------
SndReset:
    push af
    push bc
    push de
    push hl
    call SndInitHardware
    ld a, $06
    ld [wFrameDiv], a
    ld a, $77
    ld [wFadeLevel], a
    xor a
    ld [wSfxOn], a
    inc a
    ld [wMusicStopped], a
    pop hl
    pop de
    pop bc
    pop af
    ret

; -----------------------------------------------------------------------------
; SndPlaySfx: A = SFX number.  Replaces any SFX already playing; no priority.
; Clobbers DE and HL.  Game wrapper: PlaySfx (0:$1B42), C = number.
; -----------------------------------------------------------------------------
SndPlaySfx:
    push af
    ld a, [wSfxTable]
    ld l, a
    ld a, [wSfxTable + 1]
    ld h, a
    pop af
    add a
    ld e, a
    ld d, $00
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    push af
    ld a, l
    ld [wSfxPtr], a
    ld a, h
    ld [wSfxPtr + 1], a
    pop af
    ld a, $01
    ld [wSfxOn], a
    ret

; -----------------------------------------------------------------------------
; SndStopMusic: stop the music and silence the output.  It also writes
; NR50 = NR51 = 0, so SFX stay inaudible until SndReset or SndInitSong
; turns the terminals back on.  Game calls: 0:$057A and 0:$26C6 (MUSIC OFF).
; -----------------------------------------------------------------------------
SndStopMusic:
    ld a, $01
    ld [wMusicStopped], a
    xor a
    ld [wMixVol1], a
    ld [wMixVol2], a
    ld [wMixVol3], a
    ld a, $3f
    ld [wMixMask], a
    call SndMixSfx
    call SndWriteHardware
    xor a
    ldh [rNR50], a
    ldh [rNR51], a
    ret

; -----------------------------------------------------------------------------
; SndFadeOut: fade the master volume: NR50 steps $77 -> $66 ... -> 0, one step
; every 33 update ticks, then the music stops.  No caller found in the ROM.
; -----------------------------------------------------------------------------
SndFadeOut:
    ld a, $01
    ld [wFadeOn], a
    ld a, $20
    ld [wFadeTimer], a
    ret

; -----------------------------------------------------------------------------
; SndUpdate: called once per frame from the VBlank handler (0:$2E9E).
; Every 6th call returns at once, so the driver runs at 50 ticks/s (music and
; SFX alike).  Each tick: fade, row timing, then for each of the three voices:
; copy the voice block into wCur, read a row (on row ticks), run the
; per-tick effects, copy it back.  Then order/row advance, SFX mix and the
; hardware write.
; -----------------------------------------------------------------------------
SndUpdate:
    push af
    push bc
    push de
    push hl
    ld a, [wFrameDiv]
    dec a
    jr nz, .notSkipped
    ld a, $06                               ; skipped frame: nothing at all runs (not even SFX)
    ld [wFrameDiv], a
    jp .exit
.notSkipped:
    ld [wFrameDiv], a
    ld a, [wMusicStopped]
    and a                                   ; music stopped: only the SFX mix and output run
    jr z, .running
    jp .output
.running:
    ld a, [wFadeOn]
    and a
    jr z, .noFade
    ld a, [wFadeTimer]
    and a
    jr nz, .fadeWait
    ld a, $20
    ld [wFadeTimer], a
    ld a, [wFadeLevel]
    sub $11                                 ; NR50 level - $11
    ld [wFadeLevel], a
    push af
    or $88                                  ; bits 3/7 (VIN) set as well
    ldh [rNR50], a
    pop af
    and a
    jr nz, .noFade
    xor a
    ld [wFadeOn], a
    inc a
    ld [wMusicStopped], a
    ld a, $3f
    ld [wMixMask], a
    xor a
    ldh [rNR50], a
    ldh [rNR51], a
    jp .output
.fadeWait:
    dec a
    ld [wFadeTimer], a
.noFade:
    xor a
    ld [wRowTick], a
    ld a, [wSpeedCount]
    dec a                                   ; row every wSpeed ticks
    ld [wSpeedCount], a
    jr z, .rowTick
    jp .voices
.rowTick:
    ld a, $01
    ld [wRowTick], a
    ld a, [wSpeed]
    ld [wSpeedCount], a
.voices:
    ld hl, wVoice0
    ld de, wCurRowPtr
    call SndCopyVoice
    call SndReadRow
    call SndVoiceTick
    ld hl, wCurRowPtr
    ld de, wVoice0
    call SndCopyVoice
    ld hl, wVoice1
    ld de, wCurRowPtr
    call SndCopyVoice
    call SndReadRow
    call SndVoiceTick
    ld hl, wCurRowPtr
    ld de, wVoice1
    call SndCopyVoice
    ld hl, wVoice2
    ld de, wCurRowPtr
    call SndCopyVoice
    call SndReadRow
    call SndVoiceTick
    ld hl, wCurRowPtr
    ld de, wVoice2
    call SndCopyVoice
    ld a, [wMusicStopped]
    and a
    jp nz, .output
    ld a, [wRowTick]
    and a
    jr nz, .rowDone
    jp .output
.rowDone:
    ld a, [wJumpPending]
    cp $01                                  ; effect B/D pending?
    jr nz, .nextRow
    xor a
    ld [wJumpPending], a
    ld a, [wJumpTarget]
    cp $ff                                  ; $FF = effect D (next order)
    jr z, .nextOrder
    push af                                 ; effect B: A = target order.  wOrderPos is NOT updated (see doc)
    ld a, $ff
    ld [wJumpTarget], a
    pop af
    jp .setOrder
.nextRow:
    ld a, [wRow]
    inc a
    ld [wRow], a
    cp $40                                  ; 64 rows per pattern
    jr z, .nextOrder
    jp .output
.nextOrder:
    ld a, [wOrderPos]
    inc a
    ld [wOrderPos], a
    push af
    ld a, [wSongLength]
    ld c, a
    pop af
    cp c                                    ; end of the order list: go to the restart position
    jr nz, .setOrder
    ld a, [wRestartPos]
    ld [wOrderPos], a
.setOrder:
    ld b, $00
    ld c, a
    push af
    ld a, [wOrderTable]
    ld l, a
    ld a, [wOrderTable + 1]
    ld h, a
    pop af
    add hl, bc
    ld a, [hl]
    ld b, $00
    add a
    ld c, a
    push af
    ld a, [wPatternTable]
    ld l, a
    ld a, [wPatternTable + 1]
    ld h, a
    pop af
    add hl, bc
    ld c, [hl]
    inc hl
    ld b, [hl]
    push af
    ld a, [wModule]
    ld l, a
    ld a, [wModule + 1]
    ld h, a
    pop af
    add hl, bc
    push hl
    push hl
    push hl
    push hl
    ld de, $0004
    add hl, de
    push af
    ld a, l
    ld [wVoice0], a
    ld a, h
    ld [wVoice0 + VC_RowPtr + 1], a
    pop af
    pop hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    push hl
    pop bc
    pop hl
    add hl, bc
    ld bc, $0004
    add hl, bc
    push af
    ld a, l
    ld [wVoice1], a
    ld a, h
    ld [wVoice1 + VC_RowPtr + 1], a
    pop af
    pop hl
    inc hl
    inc hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    push hl
    pop bc
    pop hl
    add hl, bc
    ld bc, $0004
    add hl, bc
    push af
    ld a, l
    ld [wVoice2], a
    ld a, h
    ld [wVoice2 + VC_RowPtr + 1], a
    pop af
    xor a                                   ; new pattern: row 0 and the empty-row state of all voices cleared
    ld [wRow], a
    ld [wVoice0 + VC_RowFlags], a
    ld [wVoice1 + VC_RowFlags], a
    ld [wVoice2 + VC_RowFlags], a
.output:
    call SndMixSfx
    call SndWriteHardware
.exit:
    pop hl
    pop de
    pop bc
    pop af
    ret

; -----------------------------------------------------------------------------
; SndMixSfx: copy the music mix (wMix, 15 bytes) to wOut, then, if an SFX is
; playing, apply one SFX frame to CH2 (and optionally CH4).
; Frame = 3 bytes c, d, e:
;   c  bits 4-7: CH2 volume; bits 0-3: period high bits, stored inverted
;   d  period low bits, stored inverted
;   e  bit 7: noise on (index = bits 0-4, volume = CH2 volume)
;      bit 6: tone on (otherwise CH2 stays muted this tick)
;      bit 5: last frame
; Effective period = ((~c & $15) & 7) << 8 | ~d.  The mask keeps bits 0 and 2
; only, so period bit 9 can never be set (see doc).
; -----------------------------------------------------------------------------
SndMixSfx:
    ld hl, wMixPeriod1
    ld de, wOutPeriod1
    ld c, $0f
.copy:
    ld a, [hl+]
    ld [de], a
    inc de
    dec c
    jr nz, .copy
    ld a, [wSfxOn]
    and a
    ret z
    ld a, [wOutMask]
    or $12                                  ; mute CH2 tone and take CH4 away from voice 1 until the frame says otherwise
    ld [wOutMask], a
    ld hl, wSfxPtr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld c, [hl]
    inc hl
    ld d, [hl]
    inc hl
    ld e, [hl]
    inc hl
    push af
    ld a, l
    ld [wSfxPtr], a
    ld a, h
    ld [wSfxPtr + 1], a
    pop af
    ld a, c
    srl a                                   ; volume = c >> 4
    srl a
    srl a
    srl a
    ld [wOutVol2], a
    ld a, c
    xor $ff                                 ; high = (~c & $15) & 7: bit 1 always lost
    and $15
    ld h, a
    ld a, d
    xor $ff                                 ; low = ~d
    ld l, a
    ld a, h
    and $07
    ld [wOutPeriod2 + 1], a
    ld a, l
    ld [wOutPeriod2], a
    ld a, e
    and $1f
    bit 7, e                                ; bit 7: noise on, driven by the CH2 volume
    jr z, .noNoise
    ld [wOutNoise], a
    ld a, [wOutMask]
    and $ef
    ld [wOutMask], a
.noNoise:
    bit 6, e                                ; bit 6: tone on
    jr z, .keepTone
    ld a, [wOutMask]
    and $fd
    ld [wOutMask], a
.keepTone:
    bit 5, e                                ; bit 5: end
    jr z, .done
    xor a
    ld [wSfxOn], a
.done:
    ret

; -----------------------------------------------------------------------------
; SndReadRow: read one row for the voice in wCur (row ticks only).
; Row format:
;   1xxxxxxx          n = x empty rows ($80 and $81 both mean one row)
;   0?nnnnnn iiiieeee [pp]
;        n = note ($3F = no note), bit 6 ignored
;        i = instrument 1-15 (0 = keep), loaded only if different from the
;            current one
;        e = effect; the parameter byte pp is absent when e = 7
; -----------------------------------------------------------------------------
SndReadRow:
    ld a, [wRowTick]
    and a
    ret z
    xor a                                   ; arpeggio, effect-C flag and short-row flag last one row
    ld [wCurArpParam], a
    ld [wCurVolSet], a
    ld [wRowShort], a
    ld a, [wCurRowFlags]
    and $01                                 ; still inside a run of empty rows?
    jp nz, .skipping
    push af
    ld a, [wCurRowPtr]
    ld l, a
    ld a, [wCurRowPtr + 1]
    ld h, a
    pop af
    ld a, [hl+]
    bit 7, a                                ; bit 7: run of empty rows
    jp nz, .emptyRows
    ld e, a
    and $3f                                 ; note
    ld [wRowNote], a
    ld a, [hl+]
    ld d, a
    and $0f                                 ; effect
    ld [wRowFx], a
    ld a, [hl]
    ld [wRowParam], a
    xor a                                   ; clears the portamento bits too
    ld [wCurRowFlags], a
    ld a, d
    srl a                                   ; instrument = high nibble
    srl a
    srl a
    srl a
    and a
    jr z, .noInstr
    ld hl, wCurInstr
    ld b, [hl]
    cp b                                    ; same instrument as before: nothing to load
    jr z, .noInstr
    and $1f
    ld [wCurInstr], a
    dec a
    call SndLoadInstrument
.noInstr:
    ld b, $00
    ld a, [wRowParam]
    ld c, a
    ld a, [wRowFx]
    and $0f                                 ; effect 0: arpeggio (param 0 = none)
    and a
    jr nz, .notFx0
    ld a, c
    and a
    jr nz, .arpeggio
    jp .note
.arpeggio:
    ld a, c
    ld [wCurArpParam], a
    xor a
    ld [wCurArpPhase], a
    jp .note
.notFx0:
    cp $0f                                  ; effect F: speed
    jr nz, .notFxF
    ld a, c
    ld [wSpeed], a
    jp .note
.notFxF:
    cp $01                                  ; effect 1: portamento up (period + param per tick)
    jr nz, .notFx1
    ld a, c
    ld [wCurPortaSpeed], a
    ld a, [wCurRowFlags]
    or $06
    ld [wCurRowFlags], a
    jp .note
.notFx1:
    cp $02                                  ; effect 2: portamento down
    jr nz, .notFx2
    ld a, c
    ld [wCurPortaSpeed], a
    ld a, [wCurRowFlags]
    or $02
    ld [wCurRowFlags], a
    jp .note
.notFx2:
    cp $0c                                  ; effect C: volume 0-$40 via VolumeTable (no range check)
    jr nz, .notFxC
    ld hl, VolumeTable
    add hl, bc
    ld a, [hl]
    and a
    jr z, .setAtten
    ld hl, wCurInsFineVol
    add [hl]                                ; plus instrument fine volume (only if the table value is nonzero)
.setAtten:
    xor $0f                                 ; attenuation = 15 - volume
    ld [wCurAtten], a
    ld a, $01
    ld [wCurVolSet], a
    jp .note
.notFxC:
    cp $0d                                  ; effect D: pattern break (parameter ignored, next pattern starts at row 0)
    jr nz, .notFxD
    ld a, $01
    ld [wJumpPending], a
    jp .note
.notFxD:
    cp $0b                                  ; effect B: position jump
    jr nz, .notFxB
    ld a, $01
    ld [wJumpPending], a
    ld a, c
    ld [wJumpTarget], a
    jp .note
.notFxB:
    cp $08                                  ; effect 8: stop the music and mute NR50/NR51, rest of the row ignored
    jr nz, .notFx8
    ld a, $01
    ld [wMusicStopped], a
    xor a
    ld [wMixVol1], a
    ld [wMixVol2], a
    ld [wMixVol3], a
    xor a
    ldh [rNR50], a
    ldh [rNR51], a
    jp .advance
.notFx8:
    cp $07                                  ; effect 7: nothing, but the row has no parameter byte
    jr nz, .note
    ld a, $01
    ld [wRowShort], a
.note:
    ld a, [wRowNote]
    cp $3f                                  ; no note
    jr nz, .noteOn
    jp .advance
.noteOn:
    ld [wCurNote], a                        ; note-on
    xor a
    ld [wCurNoiseOut], a
    ld a, [wSongTranspose]
    ld hl, wCurNote
    add [hl]                                ; + song transpose
    ld hl, wCurInsTranspose
    add [hl]                                ; + instrument transpose
    ld [wCurNote], a
    ld [wCurNoiseNote], a
    push af
    add a
    ld hl, FreqTable                        ; period = FreqTable[note] (index doubled in 8 bits)
    ld b, $00
    ld c, a
    add hl, bc
    ld c, [hl]
    inc hl
    ld b, [hl]
    ld a, c
    ld [wCurPeriod], a
    ld a, b
    ld [wCurPeriod + 1], a
    pop af
    ld b, a
    ld a, [wCurInsNoise + 1]                ; instrument has a noise table: noise index starts at the note
    and a
    jr z, .noNoiseTbl
    ld a, b
    ld [wCurNoiseOut], a
.noNoiseTbl:
    ld a, [wCurInsBurst]
    bit 7, a                                ; fixed noise burst: use the instrument noise value and hand CH4 to this voice
    jr z, .noFixedNoise
    ld a, [wCurInsNoiseVal]
    ld [wCurNoiseOut], a
    ld a, [wMixMask]
    ld hl, wCurNoiseOnMask
    and [hl]
    ld [wMixMask], a
.noFixedNoise:
    ld a, [wCurVolSet]
    and a                                   ; no effect C on this row: full volume
    jr nz, .keepAtten
    ld [wCurAtten], a
.keepAtten:
    ld a, [wCurInsPitch]                    ; restart the instrument tables
    ld [wCurPitchPos], a
    ld a, [wCurInsPitch + 1]
    ld [wCurPitchPos + 1], a
    ld a, [wCurInsNoise]
    ld [wCurNoisePos], a
    ld a, [wCurInsNoise + 1]
    ld [wCurNoisePos + 1], a
    ld a, [wCurInsEnv]
    ld [wCurEnvPos], a
    ld a, [wCurInsEnv]
    ld [wCurEnvPos], a
    ld a, [wCurInsEnv + 1]
    ld [wCurEnvPos + 1], a
    ld a, [wCurInsVibSpeed]
    ld [wCurVibTimer], a
    ld a, [wCurInsVibDelay]
    ld [wCurVibDelay], a
    ld a, [wCurInsVibOn]
    ld [wCurVibState], a
    ld a, [wCurInsBurst]
    ld [wCurBurst], a
    xor a
    ld [wCurEnvTimer], a
    ld [wCurVibOffset], a
    ld [wCurVibOffset + 1], a
.advance:
    push af
    ld a, [wCurRowPtr]
    ld l, a
    ld a, [wCurRowPtr + 1]
    ld h, a
    pop af
    inc hl                                  ; advance past the row: 2 bytes if effect 7, else 3
    inc hl
    ld a, [wRowShort]
    and a
    jr nz, .storePtr
    inc hl
.storePtr:
    push af
    ld a, l
    ld [wCurRowPtr], a
    ld a, h
    ld [wCurRowPtr + 1], a
    pop af
    ret
.skipping:
    ld a, [wCurSkipCount]
    cp $01
    jr nz, .skipDec
    xor a
    ld [wCurSkipCount], a
    ld [wCurRowFlags], a
    ret
.skipDec:
    dec a
    ld [wCurSkipCount], a
    ret
.emptyRows:
    and $7f                                 ; $80/$81 = one row, $82+ = n rows
    jr z, .emptyStore
    cp $01
    jr z, .emptyStore
    dec a
    ld [wCurSkipCount], a
    ld a, $01
    ld [wCurRowFlags], a
.emptyStore:
    push af
    ld a, l
    ld [wCurRowPtr], a
    ld a, h
    ld [wCurRowPtr + 1], a
    pop af
    ret

; -----------------------------------------------------------------------------
; SndLoadInstrument: A = instrument - 1.  Record (13 bytes when wExtFormat):
;   +0 transpose   +1 noise burst ticks (0 = none)   +2 burst noise index
;   +3 vibrato: depth << 4 | speed (0 = none)   +4 vibrato delay
;   +5 fine volume (+6 skipped)      [ext format only]
;   +7 pitch table   +9 noise table   +11 volume envelope   (words, 0 = none)
; Channel enables are recomputed: tone and noise off, then on again if the
; instrument has a pitch table / noise table.
; -----------------------------------------------------------------------------
SndLoadInstrument:
    add a
    push af
    ld a, [wInstrTable]
    ld l, a
    ld a, [wInstrTable + 1]
    ld h, a
    pop af
    add l
    ld l, a
    jr nc, .gotRecord
    inc h
.gotRecord:
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    push hl
    ld a, [wMixMask]                        ; mute this voice's tone and release CH4
    ld hl, wCurToneOffMask
    or [hl]
    ld hl, wCurNoiseOffMask
    or [hl]
    ld [wMixMask], a
    pop hl
    xor a
    ld [wCurInsBurst], a
    ld a, [hl+]
    ld [wCurInsTranspose], a
    ld a, [hl+]
    and a
    jr nz, .burst
    inc hl
    jp .vibrato
.burst:
    set 7, a                                ; burst ticks | $80
    ld [wCurInsBurst], a
    ld a, [hl+]
    ld [wCurInsNoiseVal], a
.vibrato:
    xor a
    ld [wCurInsVibOn], a
    ld a, [hl+]
    and a
    jr nz, .vibOn
    inc hl
    jp .fineVol
.vibOn:
    push af
    srl a                                   ; depth
    srl a
    srl a
    srl a
    ld [wCurVibPhase], a
    ld [wCurVibDepth], a
    pop af
    and $0f                                 ; speed
    ld [wCurInsVibSpeed], a
    ld a, [hl+]
    ld [wCurInsVibDelay], a
    ld a, $01
    ld [wCurInsVibOn], a
.fineVol:
    ld a, [wExtFormat]                      ; extended format: fine volume, then one unused byte
    and a
    jr z, .pointers
    ld a, [hl+]
    ld [wCurInsFineVol], a
    inc hl
.pointers:
    ld c, [hl]
    inc hl
    ld b, [hl]
    inc hl
    ld a, c
    ld [wCurInsPitch], a
    ld a, b
    ld [wCurInsPitch + 1], a
    and a                                   ; pitch table present: tone channel on
    jr z, .noPitch
    push hl
    ld a, [wMixMask]
    ld hl, wCurToneOnMask
    and [hl]
    ld [wMixMask], a
    pop hl
.noPitch:
    ld c, [hl]
    inc hl
    ld b, [hl]
    inc hl
    ld a, c
    ld [wCurInsNoise], a
    ld a, b
    ld [wCurInsNoise + 1], a
    and a                                   ; noise table present: CH4 on for this voice
    jr z, .noNoise
    push hl
    ld a, [wMixMask]
    ld hl, wCurNoiseOnMask
    and [hl]
    ld [wMixMask], a
    pop hl
.noNoise:
    ld c, [hl]
    inc hl
    ld b, [hl]
    ld a, c
    ld [wCurInsEnv], a
    ld a, b
    ld [wCurInsEnv + 1], a
    ret

; -----------------------------------------------------------------------------
; SndVoiceTick: per-tick processing for the voice in wCur.
; Pitch/noise tables: one signed semitone step per tick, cumulative;
;   $80 = stop, $81 n = continue from entry n.
; Envelope: pairs (ticks-1, volume); $FF = hold.  Output volume =
;   envelope - attenuation, floored at 0.
; Vibrato: after the delay the period offset toggles between 0 and depth
;   every speed+1 ticks (a square wave, upward in pitch).
; Arpeggio: phase 1 = note + x, 2 = note + y, 0 = no write, so the pattern
;   is x, y, y and the plain note is never played (unless y = 0).
; -----------------------------------------------------------------------------
SndVoiceTick:
    ld a, [wCurVibState]
    bit 0, a                                ; vibrato delay
    jr z, .burst
    ld a, [wCurVibDelay]
    and a
    jr nz, .vibDelayDec
    ld a, $02
    ld [wCurVibState], a
    jp .burst
.vibDelayDec:
    dec a
    ld [wCurVibDelay], a
.burst:
    ld a, [wCurBurst]
    bit 7, a                                ; noise burst countdown
    jr z, .pitchTable
    ld a, [wCurBurst]
    and $7f
    and a
    jr nz, .burstDec
    xor a                                   ; burst over: release CH4
    ld [wCurBurst], a
    ld a, [wMixMask]
    ld hl, wCurNoiseOffMask
    or [hl]
    ld [wMixMask], a
    jp .pitchTable
.burstDec:
    dec a
    or $80
    ld [wCurBurst], a
.pitchTable:
    ld a, [wCurInsPitch + 1]
    and a                                   ; pitch table (skipped while an arpeggio runs)
    jr z, .noiseTable
    ld a, [wCurArpParam]
    and a
    jr nz, .noiseTable
    push af
    ld a, [wCurPitchPos]
    ld l, a
    ld a, [wCurPitchPos + 1]
    ld h, a
    pop af
    ld a, [hl]
    cp $80                                  ; $80: table finished
    jr z, .noiseTable
    cp $81                                  ; $81 n: loop
    jr nz, .pitchStep
    inc hl
    ld d, $00
    ld e, [hl]
    push af
    ld a, [wCurInsPitch]
    ld l, a
    ld a, [wCurInsPitch + 1]
    ld h, a
    pop af
    add hl, de
    ld a, l
    ld [wCurPitchPos], a
    ld a, h
    ld [wCurPitchPos + 1], a
.pitchStep:
    ld b, [hl]
    inc hl
    ld a, l
    ld [wCurPitchPos], a
    ld a, h
    ld [wCurPitchPos + 1], a
    ld a, [wCurNote]
    add b                                   ; note += step
    ld [wCurNote], a
    add a
    ld d, $00
    ld e, a
    ld hl, FreqTable
    add hl, de
    ld c, [hl]
    inc hl
    ld b, [hl]
    ld a, c
    ld [wCurPeriod], a
    ld a, b
    ld [wCurPeriod + 1], a
.noiseTable:
    ld a, [wCurInsNoise + 1]
    and a                                   ; noise table
    jr z, .vibrato
    push af
    ld a, [wCurNoisePos]
    ld l, a
    ld a, [wCurNoisePos + 1]
    ld h, a
    pop af
    ld a, [hl]
    cp $80
    jr z, .vibrato
    cp $81
    jr nz, .noiseStep
    inc hl
    ld d, $00
    ld e, [hl]
    push af
    ld a, [wCurInsNoise]
    ld l, a
    ld a, [wCurInsNoise + 1]
    ld h, a
    pop af
    add hl, de
    ld a, l
    ld [wCurNoisePos], a
    ld a, h
    ld [wCurNoisePos + 1], a
.noiseStep:
    ld b, [hl]
    inc hl
    ld a, l
    ld [wCurNoisePos], a
    ld a, h
    ld [wCurNoisePos + 1], a
    ld a, [wCurNoiseNote]
    add b
    ld [wCurNoiseNote], a
    ld [wCurNoiseOut], a
.vibrato:
    ld a, [wCurVibState]
    bit 1, a                                ; vibrato running?
    jr z, .porta
    ld a, [wCurVibTimer]
    cp $00
    jr nz, .vibDec
    ld a, [wCurInsVibSpeed]
    ld [wCurVibTimer], a
    ld a, [wCurVibPhase]
    ld hl, wCurVibDepth
    ld b, [hl]
    xor b                                   ; toggle 0 <-> depth
    ld [wCurVibPhase], a
    ld [wCurVibOffset], a
    xor a
    ld [wCurVibOffset + 1], a
    jp .porta
.vibDec:
    dec a
    ld [wCurVibTimer], a
.porta:
    ld a, [wCurRowFlags]
    bit 1, a                                ; portamento
    jr z, .arpeggio
    push af
    ld a, [wCurPeriod]
    ld l, a
    ld a, [wCurPeriod + 1]
    ld h, a
    pop af
    ld d, $00
    ld a, [wCurPortaSpeed]
    ld e, a
    ld a, [wCurRowFlags]
    bit 2, a                                ; bit 2 set: up (period grows)
    jr nz, .portaUp
    ld a, l
    sub e
    ld l, a
    ld a, h
    sbc d
    ld h, a
    jp .portaStore
.portaUp:
    add hl, de
.portaStore:
    push af
    ld a, l
    ld [wCurPeriod], a
    ld a, h
    ld [wCurPeriod + 1], a
    pop af
.arpeggio:
    ld a, [wCurArpParam]
    and a                                   ; arpeggio
    jr z, .envelope
    ld a, [wCurArpPhase]
    inc a
    ld [wCurArpPhase], a
    cp $03                                  ; phase 3 -> 0 without writing: keeps note + y
    jr nz, .arpNotWrap
    xor a
    ld [wCurArpPhase], a
    jp .envelope
.arpNotWrap:
    cp $01
    jr nz, .arpLow
    ld a, [wCurArpParam]
    srl a                                   ; phase 1: x = high nibble
    srl a
    srl a
    srl a
    jp .arpSet
.arpLow:
    ld a, [wCurArpParam]
    and $0f                                 ; phase 2: y = low nibble
.arpSet:
    ld hl, wCurNote
    ld b, [hl]
    add b
    add a
    ld d, $00
    ld e, a
    ld hl, FreqTable
    add hl, de
    ld c, [hl]
    inc hl
    ld b, [hl]
    ld a, c
    ld [wCurPeriod], a
    ld a, b
    ld [wCurPeriod + 1], a
.envelope:
    ld a, [wCurInsEnv + 1]
    and a                                   ; volume envelope
    jr z, .period
    ld a, [wCurEnvTimer]
    and a
    jr nz, .envDec
    push af
    ld a, [wCurEnvPos]
    ld l, a
    ld a, [wCurEnvPos + 1]
    ld h, a
    pop af
    ld a, [hl]
    cp $ff                                  ; $FF: hold
    jr nz, .envStep
    jp .envOut
.envStep:
    ld [wCurEnvTimer], a
    inc hl
    ld a, [hl]
    ld [wCurEnvVol], a
    inc hl
    ld a, l
    ld [wCurEnvPos], a
    ld a, h
    ld [wCurEnvPos + 1], a
    jp .envOut
.envDec:
    dec a
    ld [wCurEnvTimer], a
.envOut:
    ld d, $00                               ; write volume to wMix + VolSlot
    ld a, [wCurVolSlot]
    ld e, a
    ld hl, wMixPeriod1
    add hl, de
    ld a, [wCurEnvVol]
    push hl
    ld hl, wCurAtten
    sub [hl]                                ; minus attenuation
    pop hl
    bit 7, a
    jr z, .envStore
    xor a
.envStore:
    ld [hl], a
.period:
    push af                                 ; write period + vibrato offset to wMix + PeriodSlot
    ld a, [wCurPeriod]
    ld l, a
    ld a, [wCurPeriod + 1]
    ld h, a
    pop af
    ld a, [wCurVibOffset]
    ld e, a
    ld a, [wCurVibOffset + 1]
    ld d, a
    add hl, de
    push hl
    pop bc
    ld d, $00
    ld a, [wCurPeriodSlot]
    ld e, a
    ld hl, wMixPeriod1
    add hl, de
    ld [hl], c
    inc hl
    ld [hl], b
    ld a, [wCurNoiseOut]                    ; noise index (the last voice with one wins)
    and a
    ret z
    ld [wMixNoise], a
    ret

; -----------------------------------------------------------------------------
; SndInitHardware: clear wMix/wOut, mute everything in wMixMask, turn on the
; APU with NR50 = $FF, NR51 = $DB (CH2 right only, CH3 left only).
; NR43 is never written, here or anywhere else.
; -----------------------------------------------------------------------------
SndInitHardware:
    ld hl, wMixPeriod1
    ld de, wOutPeriod1
    xor a
    ld c, $0f
.clear:
    ld [hl+], a
    ld [de], a
    inc de
    dec c
    jr nz, .clear
    ld a, $3f                               ; all tone channels muted, no voice drives CH4
    ld [wMixMask], a
    ld [wOutMask], a
    ld a, $ff
    ldh [rNR50], a
    ld a, $db
    ldh [rNR51], a
    ld a, $08
    ldh [rNR10], a
    ld a, $40
    ldh [rNR11], a
    xor a
    ldh [rNR12], a
    ld a, $80
    ldh [rNR14], a
    ld a, $c0
    ldh [rNR21], a
    xor a
    ldh [rNR22], a
    ld a, $80
    ldh [rNR24], a
    ld a, $80
    ldh [rNR30], a
    xor a
    ldh [rNR31], a
    ld a, $20
    ldh [rNR32], a
    ld b, $10                               ; zero wave RAM
    ld c, $30
    xor a
.wave:
    ldh [c], a
    inc c
    dec b
    jr nz, .wave
    ld a, $ff
    ldh [rNR33], a
    ld a, $87
    ldh [rNR34], a
    xor a
    ldh [rNR42], a
    ld a, $80
    ldh [rNR44], a
    ld a, $ff
    ldh [rNR52], a
    ld a, $ff                               ; force every volume to be rewritten
    ld [wHwVol1], a
    ld [wHwVol2], a
    ld [wHwVol3], a
    ld [wHwNoiseVol], a
    ld [wHwNoiseIdx], a
    ret

; -----------------------------------------------------------------------------
; SndWriteHardware: write wOut to the APU.
; CH1/CH2: volume changes go to NRx2 with a retrigger; the period is written
;   every tick without trigger.
; CH3: NR32 stays at 100 %.  A volume change rewrites wave RAM with a square
;   wave of that amplitude (two cycles per 32 samples, so the pulse periods
;   work unchanged) and retriggers.
; CH4: volume from the first voice (2, 1, 0) whose "not driving CH4" bit is
;   clear.  NR43 is never written: see .noiseFreq.
; -----------------------------------------------------------------------------
SndWriteHardware:
    ld a, [wOutMask]
    ld e, a
    bit 0, e                                ; CH1 muted?
    jr z, .ch1Vol
    xor a
    jp .ch1SetVol
.ch1Vol:
    ld a, [wOutVol1]
    ld b, a
    ld a, [wHwVol1]
    cp b
    jr z, .ch1Freq
    ld a, b
.ch1SetVol:
    ld [wHwVol1], a
    sla a
    sla a
    sla a
    sla a
    ldh [rNR12], a
    ldh a, [rNR14]                          ; NR14 reads back as $BF: trigger with period high = 7 for a moment
    or $80
    ldh [rNR14], a
.ch1Freq:
    ld a, [wOutPeriod1]
    ldh [rNR13], a
    ld a, [wOutPeriod1 + 1]
    ldh [rNR14], a
    bit 1, e
    jr z, .ch2Vol
    xor a
    jp .ch2SetVol
.ch2Vol:
    ld a, [wOutVol2]
    ld b, a
    ld a, [wHwVol2]
    cp b
    jr z, .ch2Freq
    ld a, b
.ch2SetVol:
    ld [wHwVol2], a
    sla a
    sla a
    sla a
    sla a
    ldh [rNR22], a
    ldh a, [rNR24]
    or $80
    ldh [rNR24], a
.ch2Freq:
    ld a, [wOutPeriod2]
    ldh [rNR23], a
    ld a, [wOutPeriod2 + 1]
    ldh [rNR24], a
    bit 2, e                                ; CH3 muted?
    jr z, .ch3Vol
    xor a
    jp .ch3SetVol
.ch3Vol:
    ld a, [wOutVol3]
    ld b, a
    ld a, [wHwVol3]
    cp b
    jr z, .ch3Freq
    ld a, b
.ch3SetVol:
    ld [wHwVol3], a
    and $0f                                 ; wave byte = level in both nibbles
    ld b, a
    swap a
    or b
    push af
    xor a                                   ; DAC off while wave RAM is rewritten
    ldh [rNR30], a
    pop af
    ldh [_AUD3WAVERAM + $0], a              ; samples 0-7 and 16-23 = level
    ldh [_AUD3WAVERAM + $1], a
    ldh [_AUD3WAVERAM + $2], a
    ldh [_AUD3WAVERAM + $3], a
    ldh [_AUD3WAVERAM + $8], a
    ldh [_AUD3WAVERAM + $9], a
    ldh [_AUD3WAVERAM + $A], a
    ldh [_AUD3WAVERAM + $B], a
    xor a                                   ; samples 8-15 and 24-31 = 0
    ldh [_AUD3WAVERAM + $4], a
    ldh [_AUD3WAVERAM + $5], a
    ldh [_AUD3WAVERAM + $6], a
    ldh [_AUD3WAVERAM + $7], a
    ldh [_AUD3WAVERAM + $C], a
    ldh [_AUD3WAVERAM + $D], a
    ldh [_AUD3WAVERAM + $E], a
    ldh [_AUD3WAVERAM + $F], a
    ld a, $80
    ldh [rNR30], a
    ldh a, [rNR34]
    or $80
    ldh [rNR34], a
.ch3Freq:
    ld a, [wOutPeriod3]
    ldh [rNR33], a
    ld a, [wOutPeriod3 + 1]
    ldh [rNR34], a
    ld a, [wOutMask]
    ld e, a
    ld hl, wOutVol3
    bit 5, e                                ; CH4 volume source: voice 2 first
    jr nz, .notVoice2
    ld a, [hl]
    jp .noiseVol
.notVoice2:
    dec hl
    bit 4, e
    jr nz, .notVoice1
    ld a, [hl]
    jp .noiseVol
.notVoice1:
    dec hl
    bit 3, e
    jr nz, .noVoice
    ld a, [hl]
    jp .noiseVol
.noVoice:
    xor a
.noiseVol:
    and a                                   ; volume 0 is written (and triggered) every tick
    jr z, .noiseSetVol
    ld b, a
    ld a, [wHwNoiseVol]
    cp b
    jr z, .noiseFreq
    ld a, b
.noiseSetVol:
    ld [wHwNoiseVol], a
    sla a
    sla a
    sla a
    sla a
    ldh [rNR42], a
    ldh a, [rNR44]
    or $80
    ldh [rNR44], a
.noiseFreq:
    ld a, [wOutNoise]
    ld b, a
    ld [wHwNoiseIdx], a                     ; BUG: stores before comparing, so the compare always matches
    cp b                                    ; always equal: the NR43 write below is never reached
    jr z, .done
    ld a, b
    ld [wHwNoiseIdx], a
    ld e, a
    ld d, $00
    ld hl, NoiseShiftTable                  ; dead code: NR43 = NoiseShiftTable[index] << 4 | $0F
    add hl, de
    ld a, [hl]
    sla a
    sla a
    sla a
    sla a
    or $0f
    ldh [rNR43], a
    ldh a, [rNR44]
    or $80
    ldh [rNR44], a
.done:
    ret

; -----------------------------------------------------------------------------
; SndCopyVoice: copy $34 bytes HL -> DE (fully unrolled).
; -----------------------------------------------------------------------------
SndCopyVoice:
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl+]
    ld [de], a
    inc de
    ret

; ============================================================================
; Tables
; ============================================================================

; 96 note periods, index 0 = C2 (65.4 Hz).  Standard equal temperament.
FreqTable:
    dw $02C, $09D, $107, $16B, $1CA, $223, $277, $2C7, $312, $358, $39B, $3DA  ; octave 2
    dw $416, $44F, $484, $4B6, $4E5, $512, $53C, $564, $589, $5AC, $5CE, $5ED  ; octave 3
    dw $60B, $628, $642, $65B, $673, $689, $69E, $6B2, $6C5, $6D6, $6E7, $6F7  ; octave 4
    dw $706, $714, $721, $72E, $73A, $745, $74F, $759, $763, $76B, $774, $77C  ; octave 5
    dw $783, $78A, $791, $797, $79D, $7A3, $7A8, $7AD, $7B2, $7B6, $7BA, $7BE  ; octave 6
    dw $7C2, $7C5, $7C9, $7CC, $7CF, $7D2, $7D4, $7D7, $7D9, $7DB, $7DD, $7DF  ; octave 7
    dw $7E1, $7E3, $7E5, $7E6, $7E8, $7E9, $7EA, $7EC, $7ED, $7EE, $7EF, $7F0  ; octave 8
    dw $7F1, $7F2, $7F3, $7F3, $7F4, $7F5, $7F5, $7F6, $7F7, $7F7, $7F8, $7F8  ; octave 9

; NR43 shift clock per note index (6 notes per step).  Only read by the dead
; NR43 code in SndWriteHardware.
NoiseShiftTable:
    db $0F, $0F, $0F, $0F, $0F, $0F, $0E, $0E, $0E, $0E, $0E, $0E
    db $0D, $0D, $0D, $0D, $0D, $0D, $0C, $0C, $0C, $0C, $0C, $0C
    db $0B, $0B, $0B, $0B, $0B, $0B, $0A, $0A, $0A, $0A, $0A, $0A
    db $09, $09, $09, $09, $09, $09, $08, $08, $08, $08, $08, $08
    db $07, $07, $07, $07, $07, $07, $06, $06, $06, $06, $06, $06
    db $05, $05, $05, $05, $05, $05, $04, $04, $04, $04, $04, $04
    db $03, $03, $03, $03, $03, $03, $02, $02, $02, $02, $02, $02
    db $01, $01, $01, $01, $01, $01, $00, $00, $00, $00, $00, $00

; Per-voice constants copied to VC_PeriodSlot..VC_NoiseOffMask at song start.
;     period slot, volume slot, tone on, tone off, noise on, noise off
VoiceConfig:
    db $00, $08, $FE, $01, $F7, $08  ; voice 0 -> CH1
    db $02, $09, $FD, $02, $EF, $10  ; voice 1 -> CH2
    db $04, $0A, $FB, $04, $DF, $20  ; voice 2 -> CH3

; Effect C: MOD volume $00-$40 -> 0-15.  The last 12 bytes are only reachable
; with parameters $41-$4C (none in the data).
VolumeTable:
    db 0, 1, 2, 3, 4, 5, 6, 7, 8, 8, 8, 8, 8, 8, 8, 9
    db 9, 9, 9, 9, 9, 9, 10, 10, 10, 10, 10, 10, 10, 11, 11, 11
    db 11, 11, 11, 11, 12, 12, 12, 12, 12, 12, 12, 13, 13, 13, 13, 13
    db 13, 13, 14, 14, 14, 14, 14, 14, 14, 15, 15, 15, 15, 15, 15, 15
    db 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15

; ============================================================================
; Songs (MOD-style modules).  SndInitSong is given the address of the $FF
; prefix.  Offsets in the module are relative to the byte after the prefix.
; ============================================================================

; Song1: id 1: boot/title and MUSIC ON (0:$0293, 0:$26A0)
Song1:
    db $FF, 0                    ; extended format, song transpose
Song1_Module:
    db 22, 0                     ; order list length, restart position
    dw Song1_Pat0 - Song1_Module, Song1_End - Song1_Module  ; not read by the driver
    db 0, 1, 1, 2, 3, 2, 3, 1, 1, 2, 3, 1, 1, 2, 3, 0, 1, 1, 1, 1, 2, 3  ; order list
    ds 106, 0
.patternTable:
    dw Song1_Pat0 - Song1_Module, Song1_Pat1 - Song1_Module, Song1_Pat2 - Song1_Module, Song1_Pat3 - Song1_Module, Song1_Pad - Song1_Module, 0

Song1_Pat0:
    dw .voice1 - Song1_Pat0 - 4, .voice2 - Song1_Pat0 - 4
.voice0:
    row E_4, 3, FX_SPEED, $05         ; 00
    empty 1                           ; 01
    row7 E_4, 3                       ; 02
    empty 1                           ; 03
    row7 G_4, 3                       ; 04
    empty 1                           ; 05
    row7 G_4, 3                       ; 06
    empty 1                           ; 07
    row7 C_4, 3                       ; 08
    empty 1                           ; 09
    row7 C_4, 3                       ; 10
    empty 1                           ; 11
    row7 A_4, 3                       ; 12
    empty 1                           ; 13
    row7 A_4, 3                       ; 14
    empty 1                           ; 15
    row7 E_4, 3                       ; 16
    empty 1                           ; 17
    row7 E_4, 3                       ; 18
    empty 1                           ; 19
    row7 G_4, 3                       ; 20
    empty 1                           ; 21
    row7 G_4, 3                       ; 22
    empty 1                           ; 23
    row7 B_4, 3                       ; 24
    empty 1                           ; 25
    row7 B_4, 3                       ; 26
    empty 1                           ; 27
    row7 G_4, 3                       ; 28
    empty 1                           ; 29
    row7 G_4, 3                       ; 30
    empty 1                           ; 31
    row7 E_4, 3                       ; 32
    empty 1                           ; 33
    row7 E_4, 3                       ; 34
    empty 1                           ; 35
    row7 G_4, 3                       ; 36
    empty 1                           ; 37
    row7 G_4, 3                       ; 38
    empty 1                           ; 39
    row7 C_4, 3                       ; 40
    empty 1                           ; 41
    row7 C_4, 3                       ; 42
    empty 1                           ; 43
    row7 A_4, 3                       ; 44
    empty 1                           ; 45
    row7 A_4, 3                       ; 46
    empty 1                           ; 47
    row7 E_4, 3                       ; 48
    empty 1                           ; 49
    row7 G_4, 3                       ; 50
    empty 1                           ; 51
    row7 G_4, 3                       ; 52
    empty 1                           ; 53
    row7 B_4, 3                       ; 54
    empty 1                           ; 55
    row7 B_4, 3                       ; 56
    empty 1                           ; 57
    row7 D_5, 3                       ; 58
    empty 1                           ; 59
    row7 D_4, 3                       ; 60
    empty 1                           ; 61
    row7 E_5, 3                       ; 62
    empty 1                           ; 63
.voice1:
    row7 C_5, 1                       ; 00
    empty 7                           ; 01
    row7 C_5, 1                       ; 08
    empty 7                           ; 09
    row7 C_5, 1                       ; 16
    empty 7                           ; 17
    row7 C_5, 1                       ; 24
    empty 7                           ; 25
    row7 C_5, 1                       ; 32
    empty 3                           ; 33
    row7 C_5, 2                       ; 36
    empty 3                           ; 37
    row7 C_5, 1                       ; 40
    empty 3                           ; 41
    row7 C_5, 2                       ; 44
    empty 3                           ; 45
    row7 C_5, 1                       ; 48
    empty 3                           ; 49
    row7 C_5, 2                       ; 52
    empty 3                           ; 53
    row7 C_5, 1                       ; 56
    empty 3                           ; 57
    row7 C_5, 2                       ; 60
    empty 1                           ; 61
    row7 C_5, 2                       ; 62
    row7 C_5, 2                       ; 63
.voice2:
    row E_4, 4, FX_ARP, $70           ; 00
    row ___, 0, FX_ARP, $70           ; 01
    row E_4, 4, FX_ARP, $70           ; 02
    row ___, 0, FX_ARP, $70           ; 03
    empty 2                           ; 04
    row G_4, 4, FX_ARP, $70           ; 06
    row ___, 0, FX_ARP, $70           ; 07
    empty 2                           ; 08
    row C_4, 4, FX_ARP, $70           ; 10
    row ___, 0, FX_ARP, $70           ; 11
    empty 2                           ; 12
    row A_4, 4, FX_ARP, $70           ; 14
    row ___, 0, FX_ARP, $70           ; 15
    row E_4, 4, FX_ARP, $70           ; 16
    row ___, 0, FX_ARP, $70           ; 17
    row E_4, 4, FX_ARP, $70           ; 18
    row ___, 0, FX_ARP, $70           ; 19
    empty 2                           ; 20
    row G_4, 4, FX_ARP, $70           ; 22
    row ___, 0, FX_ARP, $70           ; 23
    empty 2                           ; 24
    row B_4, 4, FX_ARP, $70           ; 26
    row ___, 0, FX_ARP, $70           ; 27
    empty 2                           ; 28
    row G_4, 4, FX_ARP, $70           ; 30
    row ___, 0, FX_ARP, $70           ; 31
    row E_4, 4, FX_ARP, $70           ; 32
    row ___, 0, FX_ARP, $70           ; 33
    row E_4, 4, FX_ARP, $70           ; 34
    row ___, 0, FX_ARP, $70           ; 35
    empty 2                           ; 36
    row G_4, 4, FX_ARP, $70           ; 38
    row ___, 0, FX_ARP, $70           ; 39
    empty 2                           ; 40
    row C_4, 4, FX_ARP, $70           ; 42
    row ___, 0, FX_ARP, $70           ; 43
    empty 2                           ; 44
    row A_4, 4, FX_ARP, $70           ; 46
    row ___, 0, FX_ARP, $70           ; 47
    row E_4, 4, FX_ARP, $70           ; 48
    row ___, 0, FX_ARP, $70           ; 49
    row G_4, 4, FX_ARP, $70           ; 50
    row ___, 0, FX_ARP, $70           ; 51
    empty 2                           ; 52
    row B_4, 4, FX_ARP, $70           ; 54
    row ___, 0, FX_ARP, $70           ; 55
    empty 2                           ; 56
    row D_5, 4, FX_ARP, $70           ; 58
    row ___, 0, FX_ARP, $70           ; 59
    empty 2                           ; 60
    row E_5, 4, FX_ARP, $70           ; 62
    row ___, 0, FX_ARP, $70           ; 63

Song1_Pat1:
    dw .voice1 - Song1_Pat1 - 4, .voice2 - Song1_Pat1 - 4
.voice0:
    row7 E_4, 3                       ; 00
    empty 1                           ; 01
    row7 E_4, 3                       ; 02
    empty 1                           ; 03
    row7 G_4, 3                       ; 04
    empty 1                           ; 05
    row7 G_4, 3                       ; 06
    empty 1                           ; 07
    row7 C_4, 3                       ; 08
    empty 1                           ; 09
    row7 C_4, 3                       ; 10
    empty 1                           ; 11
    row7 A_4, 3                       ; 12
    empty 1                           ; 13
    row7 A_4, 3                       ; 14
    empty 1                           ; 15
    row7 E_4, 3                       ; 16
    empty 1                           ; 17
    row7 E_4, 3                       ; 18
    empty 1                           ; 19
    row7 G_4, 3                       ; 20
    empty 1                           ; 21
    row7 G_4, 3                       ; 22
    empty 1                           ; 23
    row7 B_4, 3                       ; 24
    empty 1                           ; 25
    row7 B_4, 3                       ; 26
    empty 1                           ; 27
    row7 G_4, 3                       ; 28
    empty 1                           ; 29
    row7 G_4, 3                       ; 30
    empty 1                           ; 31
    row7 E_4, 3                       ; 32
    empty 1                           ; 33
    row7 E_4, 3                       ; 34
    empty 1                           ; 35
    row7 G_4, 3                       ; 36
    empty 1                           ; 37
    row7 G_4, 3                       ; 38
    empty 1                           ; 39
    row7 C_4, 3                       ; 40
    empty 1                           ; 41
    row7 C_4, 3                       ; 42
    empty 1                           ; 43
    row7 A_4, 3                       ; 44
    empty 1                           ; 45
    row7 A_4, 3                       ; 46
    empty 1                           ; 47
    row7 E_4, 3                       ; 48
    empty 1                           ; 49
    row7 G_4, 3                       ; 50
    empty 1                           ; 51
    row7 G_4, 3                       ; 52
    empty 1                           ; 53
    row7 B_4, 3                       ; 54
    empty 1                           ; 55
    row7 B_4, 3                       ; 56
    empty 1                           ; 57
    row7 D_5, 3                       ; 58
    empty 1                           ; 59
    row7 D_4, 3                       ; 60
    empty 1                           ; 61
    row7 E_5, 3                       ; 62
    row ___, 0, FX_VOLUME, $20        ; 63
.voice1:
    row7 C_5, 1                       ; 00
    empty 1                           ; 01
    row E_4, 4, FX_ARP, $70           ; 02
    row ___, 0, FX_ARP, $70           ; 03
    row7 C_5, 2                       ; 04
    empty 1                           ; 05
    row G_4, 4, FX_ARP, $70           ; 06
    row ___, 0, FX_ARP, $70           ; 07
    row7 C_5, 1                       ; 08
    empty 1                           ; 09
    row C_4, 4, FX_ARP, $70           ; 10
    row ___, 0, FX_ARP, $70           ; 11
    row7 C_5, 2                       ; 12
    empty 1                           ; 13
    row A_4, 4, FX_ARP, $70           ; 14
    row ___, 0, FX_ARP, $70           ; 15
    row7 C_5, 1                       ; 16
    empty 1                           ; 17
    row E_4, 4, FX_ARP, $70           ; 18
    row ___, 0, FX_ARP, $70           ; 19
    row7 C_5, 2                       ; 20
    empty 1                           ; 21
    row G_4, 4, FX_ARP, $70           ; 22
    row ___, 0, FX_ARP, $70           ; 23
    row7 C_5, 1                       ; 24
    empty 1                           ; 25
    row B_4, 4, FX_ARP, $70           ; 26
    row ___, 0, FX_ARP, $70           ; 27
    row7 C_5, 2                       ; 28
    empty 1                           ; 29
    row G_4, 4, FX_ARP, $70           ; 30
    row ___, 0, FX_ARP, $70           ; 31
    row7 C_5, 1                       ; 32
    empty 1                           ; 33
    row E_4, 4, FX_ARP, $70           ; 34
    row ___, 0, FX_ARP, $70           ; 35
    row7 C_5, 2                       ; 36
    empty 1                           ; 37
    row G_4, 4, FX_ARP, $70           ; 38
    row ___, 0, FX_ARP, $70           ; 39
    row7 C_5, 1                       ; 40
    empty 1                           ; 41
    row C_4, 4, FX_ARP, $70           ; 42
    row ___, 0, FX_ARP, $70           ; 43
    row7 C_5, 2                       ; 44
    empty 1                           ; 45
    row A_4, 4, FX_ARP, $70           ; 46
    row ___, 0, FX_ARP, $70           ; 47
    row7 C_5, 1                       ; 48
    empty 1                           ; 49
    row G_4, 4, FX_ARP, $70           ; 50
    row ___, 0, FX_ARP, $70           ; 51
    row7 C_5, 2                       ; 52
    empty 1                           ; 53
    row B_4, 4, FX_ARP, $70           ; 54
    row ___, 0, FX_ARP, $70           ; 55
    row7 C_5, 1                       ; 56
    empty 1                           ; 57
    row D_5, 4, FX_ARP, $70           ; 58
    row ___, 0, FX_ARP, $70           ; 59
    row7 C_5, 2                       ; 60
    empty 1                           ; 61
    row E_5, 4, FX_ARP, $70           ; 62
    row ___, 0, FX_ARP, $70           ; 63
.voice2:
    row D_5, 5, FX_PORTA_UP, $03      ; 00
    row7 E_5, 5                       ; 01
    row ___, 0, FX_VOLUME, $20        ; 02
    row D_5, 5, FX_PORTA_UP, $03      ; 03
    row7 E_5, 5                       ; 04
    row ___, 0, FX_VOLUME, $20        ; 05
    row7 E_5, 5                       ; 06
    row ___, 0, FX_VOLUME, $20        ; 07
    row7 E_4, 5                       ; 08
    row ___, 0, FX_VOLUME, $00        ; 09
    row7 E_5, 5                       ; 10
    row ___, 0, FX_VOLUME, $00        ; 11
    row7 G_4, 5                       ; 12
    row ___, 0, FX_VOLUME, $00        ; 13
    row7 G_5, 5                       ; 14
    row ___, 0, FX_VOLUME, $00        ; 15
    row D_5, 5, FX_PORTA_UP, $03      ; 16
    row7 E_5, 5                       ; 17
    row ___, 0, FX_VOLUME, $20        ; 18
    row D_5, 5, FX_PORTA_UP, $03      ; 19
    row7 E_5, 5                       ; 20
    row ___, 0, FX_VOLUME, $20        ; 21
    row7 E_5, 5                       ; 22
    row ___, 0, FX_VOLUME, $20        ; 23
    row7 A_4, 5                       ; 24
    row ___, 0, FX_VOLUME, $00        ; 25
    row7 A_5, 5                       ; 26
    row ___, 0, FX_VOLUME, $00        ; 27
    row7 E_4, 5                       ; 28
    row ___, 0, FX_VOLUME, $00        ; 29
    row7 E_5, 5                       ; 30
    row ___, 0, FX_VOLUME, $00        ; 31
    row D_5, 5, FX_PORTA_UP, $03      ; 32
    row7 E_5, 5                       ; 33
    row ___, 0, FX_VOLUME, $20        ; 34
    row D_5, 5, FX_PORTA_UP, $03      ; 35
    row7 E_5, 5                       ; 36
    row ___, 0, FX_VOLUME, $20        ; 37
    row7 E_5, 5                       ; 38
    row ___, 0, FX_VOLUME, $20        ; 39
    row7 E_4, 5                       ; 40
    row ___, 0, FX_VOLUME, $00        ; 41
    row7 E_5, 5                       ; 42
    row ___, 0, FX_VOLUME, $00        ; 43
    row7 G_4, 5                       ; 44
    row ___, 0, FX_VOLUME, $00        ; 45
    row7 G_5, 5                       ; 46
    row ___, 0, FX_VOLUME, $00        ; 47
    row D_5, 5, FX_PORTA_UP, $03      ; 48
    row7 E_5, 5                       ; 49
    row ___, 0, FX_VOLUME, $20        ; 50
    row D_5, 5, FX_PORTA_UP, $03      ; 51
    row7 E_5, 5                       ; 52
    row ___, 0, FX_VOLUME, $20        ; 53
    row7 E_5, 5                       ; 54
    row ___, 0, FX_VOLUME, $20        ; 55
    row7 A_4, 5                       ; 56
    row ___, 0, FX_VOLUME, $00        ; 57
    row7 A_5, 5                       ; 58
    row ___, 0, FX_VOLUME, $00        ; 59
    row7 E_4, 5                       ; 60
    row ___, 0, FX_VOLUME, $00        ; 61
    row7 E_5, 5                       ; 62
    row ___, 0, FX_VOLUME, $00        ; 63

Song1_Pat2:
    dw .voice1 - Song1_Pat2 - 4, .voice2 - Song1_Pat2 - 4
.voice0:
    row7 E_4, 3                       ; 00
    empty 1                           ; 01
    row7 E_4, 3                       ; 02
    empty 1                           ; 03
    row7 G_4, 3                       ; 04
    empty 1                           ; 05
    row7 G_4, 3                       ; 06
    empty 1                           ; 07
    row7 C_4, 3                       ; 08
    empty 1                           ; 09
    row7 C_4, 3                       ; 10
    empty 1                           ; 11
    row7 A_4, 3                       ; 12
    empty 1                           ; 13
    row7 A_4, 3                       ; 14
    empty 1                           ; 15
    row7 E_4, 3                       ; 16
    empty 1                           ; 17
    row7 E_4, 3                       ; 18
    empty 1                           ; 19
    row7 G_4, 3                       ; 20
    empty 1                           ; 21
    row7 G_4, 3                       ; 22
    empty 1                           ; 23
    row7 B_4, 3                       ; 24
    empty 1                           ; 25
    row7 B_4, 3                       ; 26
    empty 1                           ; 27
    row7 G_4, 3                       ; 28
    empty 1                           ; 29
    row7 G_4, 3                       ; 30
    empty 1                           ; 31
    row7 E_4, 3                       ; 32
    empty 1                           ; 33
    row7 E_4, 3                       ; 34
    empty 1                           ; 35
    row7 G_4, 3                       ; 36
    empty 1                           ; 37
    row7 G_4, 3                       ; 38
    empty 1                           ; 39
    row7 C_4, 3                       ; 40
    empty 1                           ; 41
    row7 C_4, 3                       ; 42
    empty 1                           ; 43
    row7 A_4, 3                       ; 44
    empty 1                           ; 45
    row7 A_4, 3                       ; 46
    empty 1                           ; 47
    row7 E_4, 3                       ; 48
    empty 1                           ; 49
    row7 G_4, 3                       ; 50
    empty 1                           ; 51
    row7 G_4, 3                       ; 52
    empty 1                           ; 53
    row7 B_4, 3                       ; 54
    empty 1                           ; 55
    row7 B_4, 3                       ; 56
    empty 1                           ; 57
    row7 D_5, 3                       ; 58
    empty 1                           ; 59
    row7 D_4, 3                       ; 60
    empty 1                           ; 61
    row7 E_5, 3                       ; 62
    row ___, 0, FX_VOLUME, $20        ; 63
.voice1:
    row7 C_5, 1                       ; 00
    empty 7                           ; 01
    row7 C_5, 2                       ; 08
    empty 5                           ; 09
    row7 C_5, 1                       ; 14
    empty 1                           ; 15
    row7 C_5, 1                       ; 16
    empty 3                           ; 17
    row7 C_5, 1                       ; 20
    empty 3                           ; 21
    row7 C_5, 2                       ; 24
    empty 7                           ; 25
    row7 C_5, 1                       ; 32
    empty 7                           ; 33
    row7 C_5, 2                       ; 40
    empty 5                           ; 41
    row7 C_5, 1                       ; 46
    empty 1                           ; 47
    row7 C_5, 1                       ; 48
    empty 3                           ; 49
    row7 C_5, 1                       ; 52
    empty 3                           ; 53
    row7 C_5, 2                       ; 56
    empty 3                           ; 57
    row7 C_5, 2                       ; 60
    empty 1                           ; 61
    row7 C_5, 2                       ; 62
    empty 1                           ; 63
.voice2:
    row7 E_4, 5                       ; 00
    empty 3                           ; 01
    row ___, 0, FX_VOLUME, $35        ; 04
    empty 2                           ; 05
    row ___, 0, FX_VOLUME, $30        ; 07
    empty 1                           ; 08
    row ___, 0, FX_VOLUME, $20        ; 09
    row ___, 0, FX_VOLUME, $15        ; 10
    row ___, 0, FX_VOLUME, $10        ; 11
    row7 G_4, 5                       ; 12
    row ___, 0, FX_VOLUME, $20        ; 13
    row7 B_4, 5                       ; 14
    empty 3                           ; 15
    row ___, 0, FX_VOLUME, $30        ; 18
    empty 1                           ; 19
    row ___, 0, FX_VOLUME, $20        ; 20
    empty 1                           ; 21
    row ___, 0, FX_VOLUME, $10        ; 22
    empty 5                           ; 23
    row7 G_4, 5                       ; 28
    row ___, 0, FX_VOLUME, $20        ; 29
    row7 A_4, 5                       ; 30
    row ___, 0, FX_VOLUME, $20        ; 31
    row7 B_4, 5                       ; 32
    empty 1                           ; 33
    row ___, 0, FX_VOLUME, $30        ; 34
    row ___, 0, FX_VOLUME, $10        ; 35
    row7 C_5, 5                       ; 36
    row ___, 0, FX_VOLUME, $20        ; 37
    row7 D_5, 5                       ; 38
    row ___, 0, FX_VOLUME, $20        ; 39
    row7 E_5, 5                       ; 40
    row ___, 0, FX_VOLUME, $20        ; 41
    empty 1                           ; 42
    row ___, 0, FX_VOLUME, $10        ; 43
    row7 A_4, 5                       ; 44
    row ___, 0, FX_VOLUME, $20        ; 45
    row7 E_5, 5                       ; 46
    row ___, 0, FX_VOLUME, $30        ; 47
    empty 1                           ; 48
    row ___, 0, FX_VOLUME, $20        ; 49
    empty 1                           ; 50
    row ___, 0, FX_VOLUME, $10        ; 51
    empty 12                          ; 52

Song1_Pat3:
    dw .voice1 - Song1_Pat3 - 4, .voice2 - Song1_Pat3 - 4
.voice0:
    row7 E_4, 3                       ; 00
    empty 1                           ; 01
    row7 E_4, 3                       ; 02
    empty 1                           ; 03
    row7 G_4, 3                       ; 04
    empty 1                           ; 05
    row7 G_4, 3                       ; 06
    empty 1                           ; 07
    row7 C_4, 3                       ; 08
    empty 1                           ; 09
    row7 C_4, 3                       ; 10
    empty 1                           ; 11
    row7 A_4, 3                       ; 12
    empty 1                           ; 13
    row7 A_4, 3                       ; 14
    empty 1                           ; 15
    row7 E_4, 3                       ; 16
    empty 1                           ; 17
    row7 E_4, 3                       ; 18
    empty 1                           ; 19
    row7 G_4, 3                       ; 20
    empty 1                           ; 21
    row7 G_4, 3                       ; 22
    empty 1                           ; 23
    row7 B_4, 3                       ; 24
    empty 1                           ; 25
    row7 B_4, 3                       ; 26
    empty 1                           ; 27
    row7 G_4, 3                       ; 28
    empty 1                           ; 29
    row7 G_4, 3                       ; 30
    empty 1                           ; 31
    row7 E_4, 3                       ; 32
    empty 1                           ; 33
    row7 E_4, 3                       ; 34
    empty 1                           ; 35
    row7 G_4, 3                       ; 36
    empty 1                           ; 37
    row7 G_4, 3                       ; 38
    empty 1                           ; 39
    row7 C_4, 3                       ; 40
    empty 1                           ; 41
    row7 C_4, 3                       ; 42
    empty 1                           ; 43
    row7 A_4, 3                       ; 44
    empty 1                           ; 45
    row7 A_4, 3                       ; 46
    empty 1                           ; 47
    row7 E_4, 3                       ; 48
    empty 1                           ; 49
    row7 G_4, 3                       ; 50
    empty 1                           ; 51
    row7 G_4, 3                       ; 52
    empty 1                           ; 53
    row7 B_4, 3                       ; 54
    empty 1                           ; 55
    row7 B_4, 3                       ; 56
    empty 1                           ; 57
    row7 D_5, 3                       ; 58
    empty 1                           ; 59
    row7 D_4, 3                       ; 60
    empty 1                           ; 61
    row7 E_5, 3                       ; 62
    row ___, 0, FX_VOLUME, $20        ; 63
.voice1:
    row7 C_5, 1                       ; 00
    empty 7                           ; 01
    row7 C_5, 2                       ; 08
    empty 5                           ; 09
    row7 C_5, 1                       ; 14
    empty 1                           ; 15
    row7 C_5, 1                       ; 16
    empty 3                           ; 17
    row7 C_5, 1                       ; 20
    empty 3                           ; 21
    row7 C_5, 2                       ; 24
    empty 7                           ; 25
    row7 C_5, 1                       ; 32
    empty 7                           ; 33
    row7 C_5, 2                       ; 40
    empty 5                           ; 41
    row7 C_5, 1                       ; 46
    empty 1                           ; 47
    row7 C_5, 1                       ; 48
    empty 3                           ; 49
    row7 C_5, 1                       ; 52
    empty 3                           ; 53
    row7 C_5, 2                       ; 56
    empty 3                           ; 57
    row7 C_5, 2                       ; 60
    empty 1                           ; 61
    row7 C_5, 2                       ; 62
    empty 1                           ; 63
.voice2:
    row D_4, 5, FX_PORTA_UP, $03      ; 00
    row7 E_4, 5                       ; 01
    row ___, 0, FX_VOLUME, $20        ; 02
    empty 1                           ; 03
    row7 A_4, 5                       ; 04
    empty 1                           ; 05
    row7 B_4, 5                       ; 06
    empty 1                           ; 07
    row D_5, 5, FX_PORTA_UP, $03      ; 08
    row7 E_5, 5                       ; 09
    row ___, 0, FX_VOLUME, $30        ; 10
    row ___, 0, FX_VOLUME, $10        ; 11
    row7 E_5, 5                       ; 12
    row ___, 0, FX_VOLUME, $20        ; 13
    row7 B_4, 5                       ; 14
    row ___, 0, FX_VOLUME, $20        ; 15
    row D_5, 5, FX_PORTA_UP, $03      ; 16
    row7 E_5, 5                       ; 17
    empty 2                           ; 18
    row7 G_5, 5                       ; 20
    row ___, 0, FX_VOLUME, $20        ; 21
    row7 E_5, 5                       ; 22
    row ___, 0, FX_VOLUME, $20        ; 23
    row7 B_4, 5                       ; 24
    row ___, 0, FX_VOLUME, $20        ; 25
    empty 2                           ; 26
    row7 A_4, 5                       ; 28
    row ___, 0, FX_VOLUME, $20        ; 29
    row7 B_4, 5                       ; 30
    row ___, 0, FX_VOLUME, $20        ; 31
    row E_5, 5, FX_VOLUME, $20        ; 32
    row ___, 0, FX_VOLUME, $00        ; 33
    row E_5, 5, FX_VOLUME, $20        ; 34
    row ___, 0, FX_VOLUME, $00        ; 35
    row G_5, 5, FX_VOLUME, $20        ; 36
    row ___, 0, FX_VOLUME, $00        ; 37
    row G_5, 5, FX_VOLUME, $20        ; 38
    row ___, 0, FX_VOLUME, $00        ; 39
    row C_5, 5, FX_VOLUME, $20        ; 40
    row ___, 0, FX_VOLUME, $00        ; 41
    row C_5, 5, FX_VOLUME, $20        ; 42
    row ___, 0, FX_VOLUME, $00        ; 43
    row A_5, 5, FX_VOLUME, $20        ; 44
    row ___, 0, FX_VOLUME, $00        ; 45
    row A_5, 5, FX_VOLUME, $20        ; 46
    row ___, 0, FX_VOLUME, $00        ; 47
    row E_5, 5, FX_VOLUME, $20        ; 48
    row ___, 0, FX_VOLUME, $00        ; 49
    row G_5, 5, FX_VOLUME, $20        ; 50
    row ___, 0, FX_VOLUME, $00        ; 51
    row G_5, 5, FX_VOLUME, $20        ; 52
    row ___, 0, FX_VOLUME, $00        ; 53
    row B_4, 5, FX_VOLUME, $20        ; 54
    row ___, 0, FX_VOLUME, $00        ; 55
    row B_4, 5, FX_VOLUME, $20        ; 56
    row ___, 0, FX_VOLUME, $00        ; 57
    row D_5, 5, FX_VOLUME, $20        ; 58
    row ___, 0, FX_VOLUME, $00        ; 59
    row D_5, 5, FX_VOLUME, $20        ; 60
    row ___, 0, FX_VOLUME, $00        ; 61
    row E_5, 5, FX_VOLUME, $20        ; 62
    row ___, 0, FX_VOLUME, $00        ; 63
Song1_Pad:
    db $00
Song1_End:

; Song2: id 2 (0:$2D25)
Song2:
    db $FF, 0                    ; extended format, song transpose
Song2_Module:
    db 8, 0                     ; order list length, restart position
    dw Song2_Pat0 - Song2_Module, Song2_End - Song2_Module  ; not read by the driver
    db 0, 1, 2, 0, 1, 0, 1, 2  ; order list
    ds 120, 0
.patternTable:
    dw Song2_Pat0 - Song2_Module, Song2_Pat1 - Song2_Module, Song2_Pat2 - Song2_Module, Song2_Pad - Song2_Module, 0

Song2_Pat0:
    dw .voice1 - Song2_Pat0 - 4, .voice2 - Song2_Pat0 - 4
.voice0:
    row7 G_3, 3                       ; 00
    empty 1                           ; 01
    row7 G_4, 3                       ; 02
    empty 1                           ; 03
    row7 G_3, 3                       ; 04
    empty 1                           ; 05
    row7 G_4, 3                       ; 06
    empty 1                           ; 07
    row7 G_3, 3                       ; 08
    empty 1                           ; 09
    row7 G_4, 3                       ; 10
    empty 1                           ; 11
    row7 G_3, 3                       ; 12
    empty 1                           ; 13
    row7 G_4, 3                       ; 14
    empty 1                           ; 15
    row7 E_3, 3                       ; 16
    empty 1                           ; 17
    row7 E_4, 3                       ; 18
    empty 1                           ; 19
    row7 E_3, 3                       ; 20
    empty 1                           ; 21
    row7 E_4, 3                       ; 22
    empty 1                           ; 23
    row7 E_3, 3                       ; 24
    empty 1                           ; 25
    row7 E_4, 3                       ; 26
    empty 1                           ; 27
    row7 E_3, 3                       ; 28
    empty 1                           ; 29
    row7 E_4, 3                       ; 30
    empty 1                           ; 31
    row7 F_3, 3                       ; 32
    empty 1                           ; 33
    row7 F_4, 3                       ; 34
    empty 1                           ; 35
    row7 F_3, 3                       ; 36
    empty 1                           ; 37
    row7 F_4, 3                       ; 38
    empty 1                           ; 39
    row7 F_3, 3                       ; 40
    empty 1                           ; 41
    row7 F_4, 3                       ; 42
    empty 1                           ; 43
    row7 F_3, 3                       ; 44
    empty 1                           ; 45
    row7 F_4, 3                       ; 46
    empty 1                           ; 47
    row7 D_3, 3                       ; 48
    empty 1                           ; 49
    row7 D_4, 3                       ; 50
    empty 1                           ; 51
    row7 D_3, 3                       ; 52
    empty 1                           ; 53
    row7 D_4, 3                       ; 54
    empty 1                           ; 55
    row7 E_3, 3                       ; 56
    empty 1                           ; 57
    row7 E_4, 3                       ; 58
    empty 1                           ; 59
    row7 E_3, 3                       ; 60
    empty 1                           ; 61
    row7 E_4, 3                       ; 62
    empty 1                           ; 63
.voice1:
    row7 C_5, 1                       ; 00
    empty 1                           ; 01
    row G_4, 4, FX_ARP, $47           ; 02
    row ___, 0, FX_ARP, $47           ; 03
    row7 C_5, 2                       ; 04
    empty 1                           ; 05
    row G_4, 4, FX_ARP, $47           ; 06
    row G_4, 4, FX_ARP, $47           ; 07
    row7 C_5, 1                       ; 08
    empty 1                           ; 09
    row G_4, 4, FX_ARP, $47           ; 10
    row ___, 0, FX_ARP, $47           ; 11
    row7 C_5, 2                       ; 12
    empty 1                           ; 13
    row G_4, 4, FX_ARP, $47           ; 14
    row G_4, 4, FX_ARP, $47           ; 15
    row7 C_5, 1                       ; 16
    empty 1                           ; 17
    row E_4, 4, FX_ARP, $47           ; 18
    row ___, 0, FX_ARP, $47           ; 19
    row7 C_5, 2                       ; 20
    empty 1                           ; 21
    row E_4, 4, FX_ARP, $47           ; 22
    row E_4, 4, FX_ARP, $47           ; 23
    row7 C_5, 1                       ; 24
    empty 1                           ; 25
    row E_4, 4, FX_ARP, $47           ; 26
    row ___, 0, FX_ARP, $47           ; 27
    row7 C_5, 2                       ; 28
    empty 1                           ; 29
    row E_4, 4, FX_ARP, $47           ; 30
    row E_4, 4, FX_ARP, $47           ; 31
    row7 C_5, 1                       ; 32
    empty 1                           ; 33
    row F_4, 4, FX_ARP, $47           ; 34
    row ___, 0, FX_ARP, $47           ; 35
    row7 C_5, 2                       ; 36
    empty 1                           ; 37
    row F_4, 4, FX_ARP, $47           ; 38
    row F_4, 4, FX_ARP, $47           ; 39
    row7 C_5, 1                       ; 40
    empty 1                           ; 41
    row F_4, 4, FX_ARP, $47           ; 42
    row ___, 0, FX_ARP, $47           ; 43
    row7 C_5, 2                       ; 44
    empty 1                           ; 45
    row F_4, 4, FX_ARP, $47           ; 46
    row F_4, 4, FX_ARP, $47           ; 47
    row7 C_5, 1                       ; 48
    empty 1                           ; 49
    row D_4, 4, FX_ARP, $47           ; 50
    row ___, 0, FX_ARP, $47           ; 51
    row7 C_5, 2                       ; 52
    empty 1                           ; 53
    row D_4, 4, FX_ARP, $47           ; 54
    row D_4, 4, FX_ARP, $47           ; 55
    row7 C_5, 1                       ; 56
    empty 1                           ; 57
    row7 C_5, 2                       ; 58
    empty 1                           ; 59
    row7 C_5, 2                       ; 60
    empty 1                           ; 61
    row7 C_5, 2                       ; 62
    row7 C_5, 2                       ; 63
.voice2:
    row7 E_5, 5                       ; 00
    row ___, 0, FX_VOLUME, $00        ; 01
    empty 2                           ; 02
    row7 D_5, 5                       ; 04
    row ___, 0, FX_VOLUME, $00        ; 05
    empty 2                           ; 06
    row7 C_5, 5                       ; 08
    row ___, 0, FX_VOLUME, $00        ; 09
    empty 2                           ; 10
    row7 B_4, 5                       ; 12
    row ___, 0, FX_VOLUME, $00        ; 13
    empty 2                           ; 14
    row7 A_4, 5                       ; 16
    row ___, 0, FX_VOLUME, $20        ; 17
    row7 B_4, 5                       ; 18
    empty 1                           ; 19
    row ___, 0, FX_VOLUME, $30        ; 20
    row ___, 0, FX_VOLUME, $20        ; 21
    row ___, 0, FX_VOLUME, $00        ; 22
    empty 5                           ; 23
    row A_4, 5, FX_VOLUME, $30        ; 28
    row ___, 0, FX_VOLUME, $00        ; 29
    row B_4, 5, FX_VOLUME, $30        ; 30
    row ___, 0, FX_VOLUME, $00        ; 31
    row7 C_5, 5                       ; 32
    empty 6                           ; 33
    row ___, 0, FX_VOLUME, $30        ; 39
    row ___, 0, FX_VOLUME, $20        ; 40
    row ___, 0, FX_VOLUME, $10        ; 41
    row7 D_5, 5                       ; 42
    row ___, 0, FX_VOLUME, $30        ; 43
    row7 A_4, 5                       ; 44
    row ___, 0, FX_VOLUME, $00        ; 45
    row7 C_5, 5                       ; 46
    row ___, 0, FX_VOLUME, $00        ; 47
    row7 D_5, 5                       ; 48
    empty 6                           ; 49
    row ___, 0, FX_PORTA_DOWN, $03    ; 55
    row E_5, 5, FX_VOLUME, $25        ; 56
    empty 1                           ; 57
    row ___, 0, FX_VOLUME, $40        ; 58
    empty 1                           ; 59
    row ___, 0, FX_VOLUME, $25        ; 60
    empty 1                           ; 61
    row B_4, 5, FX_VOLUME, $30        ; 62
    row ___, 0, FX_VOLUME, $00        ; 63

Song2_Pat1:
    dw .voice1 - Song2_Pat1 - 4, .voice2 - Song2_Pat1 - 4
.voice0:
    row7 G_3, 3                       ; 00
    empty 1                           ; 01
    row7 G_4, 3                       ; 02
    empty 1                           ; 03
    row7 G_3, 3                       ; 04
    empty 1                           ; 05
    row7 G_4, 3                       ; 06
    empty 1                           ; 07
    row7 G_3, 3                       ; 08
    empty 1                           ; 09
    row7 G_4, 3                       ; 10
    empty 1                           ; 11
    row7 G_3, 3                       ; 12
    empty 1                           ; 13
    row7 G_4, 3                       ; 14
    empty 1                           ; 15
    row7 E_3, 3                       ; 16
    empty 1                           ; 17
    row7 E_4, 3                       ; 18
    empty 1                           ; 19
    row7 E_3, 3                       ; 20
    empty 1                           ; 21
    row7 E_4, 3                       ; 22
    empty 1                           ; 23
    row7 E_3, 3                       ; 24
    empty 1                           ; 25
    row7 E_4, 3                       ; 26
    empty 1                           ; 27
    row7 E_3, 3                       ; 28
    empty 1                           ; 29
    row7 E_4, 3                       ; 30
    empty 1                           ; 31
    row7 F_3, 3                       ; 32
    empty 1                           ; 33
    row7 F_4, 3                       ; 34
    empty 1                           ; 35
    row7 F_3, 3                       ; 36
    empty 1                           ; 37
    row7 F_4, 3                       ; 38
    empty 1                           ; 39
    row7 F_3, 3                       ; 40
    empty 1                           ; 41
    row7 F_4, 3                       ; 42
    empty 1                           ; 43
    row7 F_3, 3                       ; 44
    empty 1                           ; 45
    row7 F_4, 3                       ; 46
    empty 1                           ; 47
    row7 D_3, 3                       ; 48
    empty 1                           ; 49
    row7 D_4, 3                       ; 50
    empty 1                           ; 51
    row7 D_3, 3                       ; 52
    empty 1                           ; 53
    row7 D_4, 3                       ; 54
    empty 1                           ; 55
    row7 E_3, 3                       ; 56
    empty 1                           ; 57
    row7 E_4, 3                       ; 58
    empty 1                           ; 59
    row7 E_3, 3                       ; 60
    empty 1                           ; 61
    row7 E_4, 3                       ; 62
    empty 1                           ; 63
.voice1:
    row7 C_5, 1                       ; 00
    empty 1                           ; 01
    row G_4, 4, FX_ARP, $47           ; 02
    row ___, 0, FX_ARP, $47           ; 03
    row7 C_5, 2                       ; 04
    empty 1                           ; 05
    row G_4, 4, FX_ARP, $47           ; 06
    row G_4, 4, FX_ARP, $47           ; 07
    row7 C_5, 1                       ; 08
    empty 1                           ; 09
    row G_4, 4, FX_ARP, $47           ; 10
    row ___, 0, FX_ARP, $47           ; 11
    row7 C_5, 2                       ; 12
    empty 1                           ; 13
    row G_4, 4, FX_ARP, $47           ; 14
    row G_4, 4, FX_ARP, $47           ; 15
    row7 C_5, 1                       ; 16
    empty 1                           ; 17
    row E_4, 4, FX_ARP, $47           ; 18
    row ___, 0, FX_ARP, $47           ; 19
    row7 C_5, 2                       ; 20
    empty 1                           ; 21
    row E_4, 4, FX_ARP, $47           ; 22
    row E_4, 4, FX_ARP, $47           ; 23
    row7 C_5, 1                       ; 24
    empty 1                           ; 25
    row E_4, 4, FX_ARP, $47           ; 26
    row ___, 0, FX_ARP, $47           ; 27
    row7 C_5, 2                       ; 28
    empty 1                           ; 29
    row E_4, 4, FX_ARP, $47           ; 30
    row E_4, 4, FX_ARP, $47           ; 31
    row7 C_5, 1                       ; 32
    empty 1                           ; 33
    row F_4, 4, FX_ARP, $47           ; 34
    row ___, 0, FX_ARP, $47           ; 35
    row7 C_5, 2                       ; 36
    empty 1                           ; 37
    row F_4, 4, FX_ARP, $47           ; 38
    row F_4, 4, FX_ARP, $47           ; 39
    row7 C_5, 1                       ; 40
    empty 1                           ; 41
    row F_4, 4, FX_ARP, $47           ; 42
    row ___, 0, FX_ARP, $47           ; 43
    row7 C_5, 2                       ; 44
    empty 1                           ; 45
    row F_4, 4, FX_ARP, $47           ; 46
    row F_4, 4, FX_ARP, $47           ; 47
    row7 C_5, 1                       ; 48
    empty 1                           ; 49
    row D_4, 4, FX_ARP, $47           ; 50
    row ___, 0, FX_ARP, $47           ; 51
    row7 C_5, 2                       ; 52
    empty 1                           ; 53
    row D_4, 4, FX_ARP, $47           ; 54
    row D_4, 4, FX_ARP, $47           ; 55
    row7 C_5, 1                       ; 56
    empty 1                           ; 57
    row7 C_5, 2                       ; 58
    empty 1                           ; 59
    row7 C_5, 2                       ; 60
    empty 1                           ; 61
    row7 C_5, 2                       ; 62
    row7 C_5, 2                       ; 63
.voice2:
    row7 E_5, 5                       ; 00
    row ___, 0, FX_VOLUME, $00        ; 01
    row D_5, 5, FX_VOLUME, $30        ; 02
    row7 C_5, 5                       ; 03
    row7 D_5, 5                       ; 04
    row ___, 0, FX_VOLUME, $00        ; 05
    row C_5, 5, FX_VOLUME, $30        ; 06
    row7 B_4, 5                       ; 07
    row7 C_5, 5                       ; 08
    row ___, 0, FX_VOLUME, $00        ; 09
    row B_4, 5, FX_VOLUME, $30        ; 10
    row7 A_4, 5                       ; 11
    row7 B_4, 5                       ; 12
    row ___, 0, FX_VOLUME, $00        ; 13
    row7 C_5, 5                       ; 14
    empty 1                           ; 15
    row7 A_4, 5                       ; 16
    row ___, 0, FX_VOLUME, $20        ; 17
    row7 B_4, 5                       ; 18
    empty 1                           ; 19
    row ___, 0, FX_VOLUME, $30        ; 20
    row ___, 0, FX_VOLUME, $20        ; 21
    row ___, 0, FX_VOLUME, $00        ; 22
    empty 5                           ; 23
    row A_4, 5, FX_VOLUME, $30        ; 28
    row ___, 0, FX_VOLUME, $00        ; 29
    row B_4, 5, FX_VOLUME, $30        ; 30
    row A_4, 5, FX_VOLUME, $30        ; 31
    row7 C_5, 5                       ; 32
    empty 6                           ; 33
    row ___, 0, FX_VOLUME, $30        ; 39
    row ___, 0, FX_VOLUME, $20        ; 40
    row ___, 0, FX_VOLUME, $10        ; 41
    row7 D_5, 5                       ; 42
    row ___, 0, FX_VOLUME, $30        ; 43
    row7 A_4, 5                       ; 44
    row ___, 0, FX_VOLUME, $00        ; 45
    row7 C_5, 5                       ; 46
    row B_4, 5, FX_VOLUME, $30        ; 47
    row7 D_5, 5                       ; 48
    empty 5                           ; 49
    row C_5, 5, FX_VOLUME, $30        ; 54
    empty 1                           ; 55
    row E_5, 5, FX_VOLUME, $20        ; 56
    empty 1                           ; 57
    row ___, 0, FX_VOLUME, $30        ; 58
    empty 1                           ; 59
    row ___, 0, FX_VOLUME, $40        ; 60
    row ___, 0, FX_VOLUME, $20        ; 61
    row C_5, 5, FX_VOLUME, $20        ; 62
    row ___, 0, FX_VOLUME, $05        ; 63

Song2_Pat2:
    dw .voice1 - Song2_Pat2 - 4, .voice2 - Song2_Pat2 - 4
.voice0:
    row7 G_3, 3                       ; 00
    empty 1                           ; 01
    row7 G_4, 3                       ; 02
    empty 1                           ; 03
    row7 G_3, 3                       ; 04
    empty 1                           ; 05
    row7 G_4, 3                       ; 06
    empty 1                           ; 07
    row7 G_3, 3                       ; 08
    empty 1                           ; 09
    row7 G_4, 3                       ; 10
    empty 1                           ; 11
    row7 G_3, 3                       ; 12
    empty 1                           ; 13
    row7 G_4, 3                       ; 14
    empty 1                           ; 15
    row7 E_3, 3                       ; 16
    empty 1                           ; 17
    row7 E_4, 3                       ; 18
    empty 1                           ; 19
    row7 E_3, 3                       ; 20
    empty 1                           ; 21
    row7 E_4, 3                       ; 22
    empty 1                           ; 23
    row7 E_3, 3                       ; 24
    empty 1                           ; 25
    row7 E_4, 3                       ; 26
    empty 1                           ; 27
    row7 E_3, 3                       ; 28
    empty 1                           ; 29
    row7 E_4, 3                       ; 30
    empty 1                           ; 31
    row7 F_3, 3                       ; 32
    empty 1                           ; 33
    row7 F_4, 3                       ; 34
    empty 1                           ; 35
    row7 F_3, 3                       ; 36
    empty 1                           ; 37
    row7 F_4, 3                       ; 38
    empty 1                           ; 39
    row7 F_3, 3                       ; 40
    empty 1                           ; 41
    row7 F_4, 3                       ; 42
    empty 1                           ; 43
    row7 F_3, 3                       ; 44
    empty 1                           ; 45
    row7 F_4, 3                       ; 46
    empty 1                           ; 47
    row7 D_3, 3                       ; 48
    empty 1                           ; 49
    row7 D_4, 3                       ; 50
    empty 1                           ; 51
    row7 D_3, 3                       ; 52
    empty 1                           ; 53
    row7 D_4, 3                       ; 54
    empty 1                           ; 55
    row7 E_3, 3                       ; 56
    empty 1                           ; 57
    row7 E_4, 3                       ; 58
    empty 1                           ; 59
    row7 E_3, 3                       ; 60
    empty 1                           ; 61
    row7 E_4, 3                       ; 62
    empty 1                           ; 63
.voice1:
    row7 C_5, 1                       ; 00
    empty 1                           ; 01
    row G_4, 4, FX_ARP, $47           ; 02
    row ___, 0, FX_ARP, $47           ; 03
    row7 C_5, 2                       ; 04
    empty 1                           ; 05
    row G_4, 4, FX_ARP, $47           ; 06
    row G_4, 4, FX_ARP, $47           ; 07
    row7 C_5, 1                       ; 08
    empty 1                           ; 09
    row G_4, 4, FX_ARP, $47           ; 10
    row ___, 0, FX_ARP, $47           ; 11
    row7 C_5, 2                       ; 12
    empty 1                           ; 13
    row G_4, 4, FX_ARP, $47           ; 14
    row G_4, 4, FX_ARP, $47           ; 15
    row7 C_5, 1                       ; 16
    empty 1                           ; 17
    row E_4, 4, FX_ARP, $47           ; 18
    row ___, 0, FX_ARP, $47           ; 19
    row7 C_5, 2                       ; 20
    empty 1                           ; 21
    row E_4, 4, FX_ARP, $47           ; 22
    row E_4, 4, FX_ARP, $47           ; 23
    row7 C_5, 1                       ; 24
    empty 1                           ; 25
    row E_4, 4, FX_ARP, $47           ; 26
    row ___, 0, FX_ARP, $47           ; 27
    row7 C_5, 2                       ; 28
    empty 1                           ; 29
    row E_4, 4, FX_ARP, $47           ; 30
    row E_4, 4, FX_ARP, $47           ; 31
    row7 C_5, 1                       ; 32
    empty 1                           ; 33
    row F_4, 4, FX_ARP, $47           ; 34
    row ___, 0, FX_ARP, $47           ; 35
    row7 C_5, 2                       ; 36
    empty 1                           ; 37
    row F_4, 4, FX_ARP, $47           ; 38
    row F_4, 4, FX_ARP, $47           ; 39
    row7 C_5, 1                       ; 40
    empty 1                           ; 41
    row F_4, 4, FX_ARP, $47           ; 42
    row ___, 0, FX_ARP, $47           ; 43
    row7 C_5, 2                       ; 44
    empty 1                           ; 45
    row F_4, 4, FX_ARP, $47           ; 46
    row F_4, 4, FX_ARP, $47           ; 47
    row7 C_5, 1                       ; 48
    empty 1                           ; 49
    row D_4, 4, FX_ARP, $47           ; 50
    row ___, 0, FX_ARP, $47           ; 51
    row7 C_5, 2                       ; 52
    empty 1                           ; 53
    row D_4, 4, FX_ARP, $47           ; 54
    row D_4, 4, FX_ARP, $47           ; 55
    row7 C_5, 1                       ; 56
    empty 1                           ; 57
    row7 C_5, 2                       ; 58
    empty 1                           ; 59
    row7 C_5, 2                       ; 60
    empty 1                           ; 61
    row7 C_5, 2                       ; 62
    row7 C_5, 2                       ; 63
.voice2:
    row B_4, 5, FX_VOLUME, $10        ; 00
    row ___, 0, FX_VOLUME, $15        ; 01
    row ___, 0, FX_VOLUME, $20        ; 02
    row ___, 0, FX_VOLUME, $25        ; 03
    row ___, 0, FX_VOLUME, $30        ; 04
    row ___, 0, FX_VOLUME, $35        ; 05
    row ___, 0, FX_VOLUME, $40        ; 06
    empty 5                           ; 07
    row D_5, 5, FX_VOLUME, $20        ; 12
    row ___, 0, FX_VOLUME, $30        ; 13
    empty 2                           ; 14
    row7 C_5, 5                       ; 16
    row ___, 0, FX_VOLUME, $00        ; 17
    row E_5, 5, FX_VOLUME, $20        ; 18
    row ___, 0, FX_VOLUME, $25        ; 19
    row ___, 0, FX_VOLUME, $30        ; 20
    row ___, 0, FX_VOLUME, $35        ; 21
    row ___, 0, FX_VOLUME, $40        ; 22
    empty 5                           ; 23
    row7 C_5, 5                       ; 28
    row B_4, 5, FX_VOLUME, $20        ; 29
    empty 1                           ; 30
    row ___, 0, FX_VOLUME, $20        ; 31
    row7 C_5, 5                       ; 32
    empty 5                           ; 33
    row ___, 0, FX_VOLUME, $20        ; 38
    empty 2                           ; 39
    row ___, 0, FX_VOLUME, $10        ; 41
    row7 A_4, 5                       ; 42
    empty 1                           ; 43
    row7 C_5, 5                       ; 44
    row7 B_4, 5                       ; 45
    empty 2                           ; 46
    row7 D_5, 5                       ; 48
    empty 7                           ; 49
    row7 E_5, 5                       ; 56
    empty 5                           ; 57
    row7 G_5, 5                       ; 62
    row ___, 0, FX_VOLUME, $20        ; 63
Song2_Pad:
    db $00
Song2_End:

; Song3: id 3, a one-pattern jingle that ends with effect 8 (0:$0B52, 0:$19C6)
Song3:
    db $FF, 0                    ; extended format, song transpose
Song3_Module:
    db 1, 0                     ; order list length, restart position
    dw Song3_Pat0 - Song3_Module, Song3_End - Song3_Module  ; not read by the driver
    db 0  ; order list
    ds 127, 0
.patternTable:
    dw Song3_Pat0 - Song3_Module, Song3_Pad - Song3_Module, 0

Song3_Pat0:
    dw .voice1 - Song3_Pat0 - 4, .voice2 - Song3_Pat0 - 4
.voice0:
    row7 A_5, 5                       ; 00
    row7 G_5, 5                       ; 01
    row7 F_5, 5                       ; 02
    row7 E_5, 5                       ; 03
    row7 D_5, 5                       ; 04
    row7 C_5, 5                       ; 05
    row7 B_4, 5                       ; 06
    row7 A_4, 5                       ; 07
    row7 G_4, 5                       ; 08
    row7 F_4, 5                       ; 09
    row7 E_4, 5                       ; 10
    row7 D_4, 5                       ; 11
    row7 C_4, 5                       ; 12
    empty 1                           ; 13
    row7 C_5, 5                       ; 14
    row7 Cs5, 5                       ; 15
    row7 C_5, 5                       ; 16
    row7 Cs5, 5                       ; 17
    row7 C_5, 5                       ; 18
    row7 Cs5, 5                       ; 19
    row ___, 0, FX_VOLUME, $30        ; 20
    row ___, 0, FX_VOLUME, $20        ; 21
    row ___, 0, FX_VOLUME, $00        ; 22
    row ___, 0, FX_STOP, $00          ; 23
    empty 40                          ; 24
.voice1:
    row7 D_4, 3                       ; 00
    empty 3                           ; 01
    row7 Fs4, 3                       ; 04
    empty 1                           ; 05
    row7 A_4, 3                       ; 06
    empty 3                           ; 07
    row7 F_4, 3                       ; 10
    empty 3                           ; 11
    row7 C_4, 3                       ; 14
    row7 Cs4, 3                       ; 15
    row7 C_4, 3                       ; 16
    row7 Cs4, 3                       ; 17
    row7 C_4, 3                       ; 18
    row7 Cs4, 3                       ; 19
    row ___, 0, FX_VOLUME, $30        ; 20
    row ___, 0, FX_VOLUME, $20        ; 21
    row ___, 0, FX_VOLUME, $00        ; 22
    empty 41                          ; 23
.voice2:
    row7 D_5, 4                       ; 00
    empty 1                           ; 01
    row7 D_5, 4                       ; 02
    empty 3                           ; 03
    row7 A_4, 4                       ; 06
    empty 7                           ; 07
    row7 C_5, 4                       ; 14
    empty 5                           ; 15
    row ___, 0, FX_VOLUME, $30        ; 20
    row ___, 0, FX_VOLUME, $20        ; 21
    row ___, 0, FX_VOLUME, $00        ; 22
    empty 41                          ; 23
Song3_Pad:
    db $00
Song3_End:

; Song4: ids 4, 5 and 6: level music (0:$07A6/$07AD/$07B4)
Song4:
    db $FF, 0                    ; extended format, song transpose
Song4_Module:
    db 6, 0                     ; order list length, restart position
    dw Song4_Pat0 - Song4_Module, Song4_End - Song4_Module  ; not read by the driver
    db 0, 1, 2, 1, 2, 3  ; order list
    ds 122, 0
.patternTable:
    dw Song4_Pat0 - Song4_Module, Song4_Pat1 - Song4_Module, Song4_Pat2 - Song4_Module, Song4_Pat3 - Song4_Module, Song4_Pad - Song4_Module, 0

Song4_Pat0:
    dw .voice1 - Song4_Pat0 - 4, .voice2 - Song4_Pat0 - 4
.voice0:
    row C_5, 1, FX_SPEED, $06         ; 00
    empty 3                           ; 01
    row7 C_5, 1                       ; 04
    empty 3                           ; 05
    row7 C_5, 1                       ; 08
    empty 3                           ; 09
    row7 C_5, 1                       ; 12
    empty 3                           ; 13
    row7 C_5, 1                       ; 16
    empty 3                           ; 17
    row7 C_5, 1                       ; 20
    empty 3                           ; 21
    row7 C_5, 1                       ; 24
    empty 3                           ; 25
    row7 C_5, 1                       ; 28
    empty 1                           ; 29
    row C_5, 2, FX_VOLUME, $20        ; 30
    row7 C_5, 2                       ; 31
    row7 C_5, 1                       ; 32
    empty 3                           ; 33
    row7 C_5, 1                       ; 36
    empty 3                           ; 37
    row7 C_5, 1                       ; 40
    empty 3                           ; 41
    row7 C_5, 1                       ; 44
    empty 3                           ; 45
    row7 C_5, 1                       ; 48
    empty 1                           ; 49
    row C_5, 2, FX_VOLUME, $20        ; 50
    row7 C_5, 2                       ; 51
    row7 C_5, 1                       ; 52
    empty 1                           ; 53
    row7 C_5, 2                       ; 54
    empty 1                           ; 55
    row7 C_5, 1                       ; 56
    empty 1                           ; 57
    row7 C_5, 2                       ; 58
    empty 1                           ; 59
    row7 C_5, 2                       ; 60
    empty 1                           ; 61
    row7 C_5, 2                       ; 62
    row7 C_5, 2                       ; 63
.voice1:
    row7 C_4, 3                       ; 00
    row7 D_4, 3                       ; 01
    empty 1                           ; 02
    row7 D_4, 3                       ; 03
    empty 2                           ; 04
    row D_4, 3, FX_VOLUME, $20        ; 06
    empty 1                           ; 07
    row7 C_4, 3                       ; 08
    row7 D_4, 3                       ; 09
    empty 1                           ; 10
    row7 D_4, 3                       ; 11
    empty 2                           ; 12
    row7 G_4, 3                       ; 14
    empty 1                           ; 15
    row7 C_4, 3                       ; 16
    row7 D_4, 3                       ; 17
    empty 1                           ; 18
    row7 D_4, 3                       ; 19
    empty 2                           ; 20
    row D_4, 3, FX_VOLUME, $20        ; 22
    empty 1                           ; 23
    row7 C_4, 3                       ; 24
    row7 D_4, 3                       ; 25
    empty 1                           ; 26
    row7 D_4, 3                       ; 27
    empty 2                           ; 28
    row D_4, 3, FX_VOLUME, $20        ; 30
    empty 1                           ; 31
    row7 C_4, 3                       ; 32
    row7 D_4, 3                       ; 33
    empty 1                           ; 34
    row7 D_4, 3                       ; 35
    empty 2                           ; 36
    row D_4, 3, FX_VOLUME, $20        ; 38
    empty 1                           ; 39
    row7 C_4, 3                       ; 40
    row7 D_4, 3                       ; 41
    empty 1                           ; 42
    row7 D_4, 3                       ; 43
    empty 2                           ; 44
    row7 G_4, 3                       ; 46
    empty 1                           ; 47
    row7 C_4, 3                       ; 48
    row7 D_4, 3                       ; 49
    empty 1                           ; 50
    row7 D_4, 3                       ; 51
    empty 2                           ; 52
    row D_4, 3, FX_VOLUME, $20        ; 54
    empty 1                           ; 55
    row7 C_4, 3                       ; 56
    row7 D_4, 3                       ; 57
    empty 1                           ; 58
    row7 D_4, 3                       ; 59
    empty 2                           ; 60
    row D_4, 3, FX_VOLUME, $20        ; 62
    empty 1                           ; 63
.voice2:
    row7 C_4, 5                       ; 00
    row7 D_4, 5                       ; 01
    row D_4, 5, FX_VOLUME, $20        ; 02
    row7 D_4, 5                       ; 03
    row ___, 0, FX_VOLUME, $10        ; 04
    row D_4, 5, FX_VOLUME, $20        ; 05
    row ___, 0, FX_VOLUME, $05        ; 06
    row D_4, 5, FX_VOLUME, $10        ; 07
    row ___, 0, FX_VOLUME, $00        ; 08
    row D_4, 5, FX_VOLUME, $05        ; 09
    empty 2                           ; 10
    row ___, 0, FX_VOLUME, $00        ; 12
    empty 3                           ; 13
    row7 C_4, 5                       ; 16
    row7 D_4, 5                       ; 17
    row ___, 0, FX_VOLUME, $20        ; 18
    row D_4, 5, FX_VOLUME, $30        ; 19
    row ___, 0, FX_VOLUME, $15        ; 20
    row D_4, 5, FX_VOLUME, $20        ; 21
    row G_4, 5, FX_VOLUME, $35        ; 22
    row ___, 0, FX_VOLUME, $10        ; 23
    row G_4, 5, FX_VOLUME, $30        ; 24
    row ___, 0, FX_VOLUME, $15        ; 25
    row G_4, 5, FX_VOLUME, $25        ; 26
    row ___, 0, FX_VOLUME, $10        ; 27
    row G_4, 5, FX_VOLUME, $20        ; 28
    row ___, 0, FX_VOLUME, $05        ; 29
    row G_4, 5, FX_VOLUME, $10        ; 30
    row ___, 0, FX_VOLUME, $05        ; 31
    row7 C_4, 5                       ; 32
    row7 D_4, 5                       ; 33
    row D_4, 5, FX_VOLUME, $20        ; 34
    row7 D_4, 5                       ; 35
    row ___, 0, FX_VOLUME, $20        ; 36
    row ___, 0, FX_VOLUME, $10        ; 37
    row ___, 0, FX_VOLUME, $00        ; 38
    empty 7                           ; 39
    row7 C_4, 5                       ; 46
    empty 1                           ; 47
    row7 E_4, 5                       ; 48
    row7 D_4, 5                       ; 49
    row7 E_4, 5                       ; 50
    row7 F_4, 5                       ; 51
    row7 G_4, 5                       ; 52
    row7 F_4, 5                       ; 53
    row7 G_4, 5                       ; 54
    row7 A_4, 5                       ; 55
    row7 B_4, 5                       ; 56
    row7 A_4, 5                       ; 57
    row7 B_4, 5                       ; 58
    row7 C_5, 5                       ; 59
    empty 1                           ; 60
    row ___, 0, FX_PORTA_DOWN, $08    ; 61
    row ___, 0, FX_PORTA_DOWN, $08    ; 62
    row ___, 0, FX_PORTA_DOWN, $08    ; 63

Song4_Pat1:
    dw .voice1 - Song4_Pat1 - 4, .voice2 - Song4_Pat1 - 4
.voice0:
    row7 C_5, 1                       ; 00
    empty 3                           ; 01
    row7 C_5, 2                       ; 04
    empty 1                           ; 05
    row7 C_5, 1                       ; 06
    empty 1                           ; 07
    row7 C_5, 1                       ; 08
    empty 3                           ; 09
    row7 C_5, 2                       ; 12
    empty 1                           ; 13
    row7 C_5, 2                       ; 14
    row7 C_5, 2                       ; 15
    row7 C_5, 1                       ; 16
    empty 1                           ; 17
    row7 C_5, 1                       ; 18
    empty 1                           ; 19
    row7 C_5, 2                       ; 20
    empty 1                           ; 21
    row7 C_5, 1                       ; 22
    empty 1                           ; 23
    row7 C_5, 1                       ; 24
    empty 3                           ; 25
    row7 C_5, 2                       ; 28
    empty 2                           ; 29
    row7 C_5, 2                       ; 31
    row7 C_5, 1                       ; 32
    empty 3                           ; 33
    row7 C_5, 2                       ; 36
    empty 1                           ; 37
    row7 C_5, 1                       ; 38
    empty 1                           ; 39
    row7 C_5, 1                       ; 40
    empty 3                           ; 41
    row7 C_5, 2                       ; 44
    empty 1                           ; 45
    row7 C_5, 2                       ; 46
    row7 C_5, 2                       ; 47
    row7 C_5, 1                       ; 48
    empty 1                           ; 49
    row7 C_5, 1                       ; 50
    empty 1                           ; 51
    row7 C_5, 2                       ; 52
    empty 1                           ; 53
    row7 C_5, 1                       ; 54
    empty 1                           ; 55
    row7 C_5, 1                       ; 56
    empty 3                           ; 57
    row7 C_5, 2                       ; 60
    empty 2                           ; 61
    row7 C_5, 2                       ; 63
.voice1:
    row7 C_4, 3                       ; 00
    row7 D_4, 3                       ; 01
    empty 1                           ; 02
    row7 D_4, 3                       ; 03
    empty 2                           ; 04
    row7 D_4, 3                       ; 06
    empty 1                           ; 07
    row7 C_4, 3                       ; 08
    row7 D_4, 3                       ; 09
    empty 1                           ; 10
    row7 D_4, 3                       ; 11
    empty 2                           ; 12
    row7 D_4, 3                       ; 14
    empty 1                           ; 15
    row7 C_4, 3                       ; 16
    row7 D_4, 3                       ; 17
    empty 1                           ; 18
    row7 D_4, 3                       ; 19
    empty 2                           ; 20
    row7 D_4, 3                       ; 22
    empty 1                           ; 23
    row7 C_4, 3                       ; 24
    row7 D_4, 3                       ; 25
    empty 1                           ; 26
    row7 D_4, 3                       ; 27
    empty 2                           ; 28
    row7 D_4, 3                       ; 30
    empty 1                           ; 31
    row7 C_4, 3                       ; 32
    row7 D_4, 3                       ; 33
    empty 1                           ; 34
    row7 D_4, 3                       ; 35
    empty 2                           ; 36
    row7 D_4, 3                       ; 38
    empty 1                           ; 39
    row7 C_4, 3                       ; 40
    row7 D_4, 3                       ; 41
    empty 1                           ; 42
    row7 D_4, 3                       ; 43
    empty 2                           ; 44
    row7 D_4, 3                       ; 46
    empty 1                           ; 47
    row7 C_4, 3                       ; 48
    row7 D_4, 3                       ; 49
    empty 1                           ; 50
    row7 D_4, 3                       ; 51
    empty 2                           ; 52
    row7 D_4, 3                       ; 54
    empty 1                           ; 55
    row7 C_4, 3                       ; 56
    row7 D_4, 3                       ; 57
    empty 1                           ; 58
    row7 D_4, 3                       ; 59
    empty 2                           ; 60
    row7 D_4, 3                       ; 62
    empty 1                           ; 63
.voice2:
    row7 D_5, 5                       ; 00
    row7 D_4, 5                       ; 01
    row D_5, 5, FX_VOLUME, $20        ; 02
    row7 C_5, 5                       ; 03
    row7 D_4, 5                       ; 04
    row D_5, 5, FX_VOLUME, $20        ; 05
    row7 B_4, 5                       ; 06
    row7 D_4, 5                       ; 07
    row D_5, 5, FX_VOLUME, $20        ; 08
    row7 C_5, 5                       ; 09
    row7 D_4, 5                       ; 10
    row D_5, 5, FX_VOLUME, $20        ; 11
    row7 D_5, 5                       ; 12
    row7 D_4, 5                       ; 13
    row7 D_5, 5                       ; 14
    row ___, 0, FX_VOLUME, $20        ; 15
    row7 C_5, 5                       ; 16
    row7 C_4, 5                       ; 17
    row C_5, 5, FX_VOLUME, $20        ; 18
    row7 B_4, 5                       ; 19
    row7 C_4, 5                       ; 20
    row C_5, 5, FX_VOLUME, $20        ; 21
    row7 A_4, 5                       ; 22
    row7 C_4, 5                       ; 23
    row C_5, 5, FX_VOLUME, $20        ; 24
    row7 B_4, 5                       ; 25
    row7 C_4, 5                       ; 26
    row C_5, 5, FX_VOLUME, $20        ; 27
    row7 C_5, 5                       ; 28
    row7 C_4, 5                       ; 29
    row7 C_5, 5                       ; 30
    row ___, 0, FX_VOLUME, $20        ; 31
    row7 D_5, 5                       ; 32
    row7 D_4, 5                       ; 33
    row D_5, 5, FX_VOLUME, $20        ; 34
    row7 C_5, 5                       ; 35
    row7 D_4, 5                       ; 36
    row D_5, 5, FX_VOLUME, $20        ; 37
    row7 B_4, 5                       ; 38
    row7 D_4, 5                       ; 39
    row D_5, 5, FX_VOLUME, $20        ; 40
    row7 C_5, 5                       ; 41
    row7 D_4, 5                       ; 42
    row D_5, 5, FX_VOLUME, $20        ; 43
    row7 D_5, 5                       ; 44
    row7 D_4, 5                       ; 45
    row7 D_5, 5                       ; 46
    row ___, 0, FX_VOLUME, $20        ; 47
    row7 C_5, 5                       ; 48
    row7 C_4, 5                       ; 49
    row C_5, 5, FX_VOLUME, $20        ; 50
    row7 B_4, 5                       ; 51
    row7 C_4, 5                       ; 52
    row C_5, 5, FX_VOLUME, $20        ; 53
    row7 A_4, 5                       ; 54
    row7 C_4, 5                       ; 55
    row C_5, 5, FX_VOLUME, $20        ; 56
    row7 B_4, 5                       ; 57
    row7 C_4, 5                       ; 58
    row C_5, 5, FX_VOLUME, $20        ; 59
    row7 C_5, 5                       ; 60
    row7 C_4, 5                       ; 61
    row7 C_5, 5                       ; 62
    row ___, 0, FX_VOLUME, $20        ; 63

Song4_Pat2:
    dw .voice1 - Song4_Pat2 - 4, .voice2 - Song4_Pat2 - 4
.voice0:
    row7 C_5, 1                       ; 00
    empty 3                           ; 01
    row7 C_5, 2                       ; 04
    empty 1                           ; 05
    row7 C_5, 1                       ; 06
    empty 1                           ; 07
    row7 C_5, 1                       ; 08
    empty 3                           ; 09
    row7 C_5, 2                       ; 12
    empty 1                           ; 13
    row7 C_5, 2                       ; 14
    row7 C_5, 2                       ; 15
    row7 C_5, 1                       ; 16
    empty 1                           ; 17
    row7 C_5, 1                       ; 18
    empty 1                           ; 19
    row7 C_5, 2                       ; 20
    empty 1                           ; 21
    row7 C_5, 1                       ; 22
    empty 1                           ; 23
    row7 C_5, 1                       ; 24
    empty 3                           ; 25
    row7 C_5, 2                       ; 28
    empty 2                           ; 29
    row7 C_5, 2                       ; 31
    row7 C_5, 1                       ; 32
    empty 3                           ; 33
    row7 C_5, 2                       ; 36
    empty 1                           ; 37
    row7 C_5, 1                       ; 38
    empty 1                           ; 39
    row7 C_5, 1                       ; 40
    empty 3                           ; 41
    row7 C_5, 2                       ; 44
    empty 1                           ; 45
    row7 C_5, 2                       ; 46
    row7 C_5, 2                       ; 47
    row7 C_5, 1                       ; 48
    empty 1                           ; 49
    row7 C_5, 1                       ; 50
    empty 1                           ; 51
    row7 C_5, 2                       ; 52
    empty 1                           ; 53
    row7 C_5, 1                       ; 54
    empty 1                           ; 55
    row7 C_5, 1                       ; 56
    empty 3                           ; 57
    row7 C_5, 2                       ; 60
    empty 2                           ; 61
    row7 C_5, 2                       ; 63
.voice1:
    row7 C_4, 3                       ; 00
    row7 D_4, 3                       ; 01
    empty 1                           ; 02
    row7 D_4, 3                       ; 03
    empty 2                           ; 04
    row7 D_4, 3                       ; 06
    empty 1                           ; 07
    row7 C_4, 3                       ; 08
    row7 D_4, 3                       ; 09
    empty 1                           ; 10
    row7 D_4, 3                       ; 11
    empty 2                           ; 12
    row7 D_4, 3                       ; 14
    empty 1                           ; 15
    row7 C_4, 3                       ; 16
    row7 D_4, 3                       ; 17
    empty 1                           ; 18
    row7 D_4, 3                       ; 19
    empty 2                           ; 20
    row7 D_4, 3                       ; 22
    empty 1                           ; 23
    row7 C_4, 3                       ; 24
    row7 D_4, 3                       ; 25
    empty 1                           ; 26
    row7 D_4, 3                       ; 27
    empty 2                           ; 28
    row7 D_4, 3                       ; 30
    empty 1                           ; 31
    row7 C_4, 3                       ; 32
    row7 D_4, 3                       ; 33
    empty 1                           ; 34
    row7 D_4, 3                       ; 35
    empty 2                           ; 36
    row7 D_4, 3                       ; 38
    empty 1                           ; 39
    row7 C_4, 3                       ; 40
    row7 D_4, 3                       ; 41
    empty 1                           ; 42
    row7 D_4, 3                       ; 43
    empty 2                           ; 44
    row7 D_4, 3                       ; 46
    empty 1                           ; 47
    row7 C_4, 3                       ; 48
    row7 D_4, 3                       ; 49
    empty 1                           ; 50
    row7 D_4, 3                       ; 51
    empty 2                           ; 52
    row7 D_4, 3                       ; 54
    empty 1                           ; 55
    row7 C_4, 3                       ; 56
    row7 D_4, 3                       ; 57
    empty 1                           ; 58
    row7 D_4, 3                       ; 59
    empty 2                           ; 60
    row7 D_4, 3                       ; 62
    empty 1                           ; 63
.voice2:
    row7 B_4, 5                       ; 00
    row7 B_3, 5                       ; 01
    row B_4, 5, FX_VOLUME, $20        ; 02
    row7 A_4, 5                       ; 03
    row7 B_3, 5                       ; 04
    row B_4, 5, FX_VOLUME, $20        ; 05
    row7 G_4, 5                       ; 06
    row7 B_3, 5                       ; 07
    row B_4, 5, FX_VOLUME, $20        ; 08
    row7 A_4, 5                       ; 09
    row7 B_3, 5                       ; 10
    row B_4, 5, FX_VOLUME, $20        ; 11
    row7 G_4, 5                       ; 12
    row7 B_3, 5                       ; 13
    row7 B_4, 5                       ; 14
    row ___, 0, FX_VOLUME, $20        ; 15
    row7 C_5, 5                       ; 16
    row7 C_4, 5                       ; 17
    row C_5, 5, FX_VOLUME, $20        ; 18
    row7 B_4, 5                       ; 19
    row7 C_4, 5                       ; 20
    row C_5, 5, FX_VOLUME, $20        ; 21
    row7 A_4, 5                       ; 22
    row7 C_4, 5                       ; 23
    row C_5, 5, FX_VOLUME, $20        ; 24
    row7 B_4, 5                       ; 25
    row7 C_4, 5                       ; 26
    row C_5, 5, FX_VOLUME, $20        ; 27
    row7 C_5, 5                       ; 28
    row7 C_4, 5                       ; 29
    row7 C_5, 5                       ; 30
    row ___, 0, FX_VOLUME, $20        ; 31
    row7 D_5, 5                       ; 32
    row7 D_4, 5                       ; 33
    row D_5, 5, FX_VOLUME, $20        ; 34
    row7 C_5, 5                       ; 35
    row7 D_4, 5                       ; 36
    row D_5, 5, FX_VOLUME, $20        ; 37
    row7 B_4, 5                       ; 38
    row7 D_4, 5                       ; 39
    row D_5, 5, FX_VOLUME, $20        ; 40
    row7 C_5, 5                       ; 41
    row7 D_4, 5                       ; 42
    row D_5, 5, FX_VOLUME, $20        ; 43
    row7 D_5, 5                       ; 44
    row7 D_4, 5                       ; 45
    row7 D_5, 5                       ; 46
    row ___, 0, FX_VOLUME, $20        ; 47
    row7 E_5, 5                       ; 48
    row7 E_4, 5                       ; 49
    row E_5, 5, FX_VOLUME, $20        ; 50
    row7 D_5, 5                       ; 51
    row7 E_4, 5                       ; 52
    row E_5, 5, FX_VOLUME, $20        ; 53
    row7 C_5, 5                       ; 54
    row7 E_4, 5                       ; 55
    row E_5, 5, FX_VOLUME, $20        ; 56
    row7 D_5, 5                       ; 57
    row7 E_4, 5                       ; 58
    row E_5, 5, FX_VOLUME, $20        ; 59
    row7 E_5, 5                       ; 60
    row7 E_4, 5                       ; 61
    row7 E_5, 5                       ; 62
    row ___, 0, FX_VOLUME, $20        ; 63

Song4_Pat3:
    dw .voice1 - Song4_Pat3 - 4, .voice2 - Song4_Pat3 - 4
.voice0:
    row7 C_5, 1                       ; 00
    empty 1                           ; 01
    row7 E_5, 7                       ; 02
    empty 3                           ; 03
    row7 C_5, 1                       ; 06
    empty 1                           ; 07
    row7 C_5, 1                       ; 08
    empty 1                           ; 09
    row7 E_5, 7                       ; 10
    empty 1                           ; 11
    row7 C_5, 2                       ; 12
    empty 1                           ; 13
    row7 C_5, 2                       ; 14
    row7 C_5, 2                       ; 15
    row7 C_5, 1                       ; 16
    empty 1                           ; 17
    row7 C_5, 1                       ; 18
    empty 3                           ; 19
    row7 C_5, 1                       ; 22
    empty 1                           ; 23
    row7 C_5, 1                       ; 24
    empty 1                           ; 25
    row7 E_5, 7                       ; 26
    empty 1                           ; 27
    row7 C_5, 2                       ; 28
    empty 1                           ; 29
    row7 E_5, 7                       ; 30
    row7 C_5, 2                       ; 31
    row7 C_5, 1                       ; 32
    empty 1                           ; 33
    row7 E_5, 7                       ; 34
    empty 3                           ; 35
    row7 C_5, 1                       ; 38
    empty 1                           ; 39
    row7 C_5, 1                       ; 40
    empty 1                           ; 41
    row7 E_5, 7                       ; 42
    empty 1                           ; 43
    row7 C_5, 2                       ; 44
    empty 1                           ; 45
    row7 C_5, 2                       ; 46
    row7 C_5, 2                       ; 47
    row7 C_5, 1                       ; 48
    empty 1                           ; 49
    row7 C_5, 1                       ; 50
    empty 3                           ; 51
    row7 C_5, 1                       ; 54
    empty 1                           ; 55
    row7 C_5, 1                       ; 56
    empty 1                           ; 57
    row C_5, 2, FX_VOLUME, $30        ; 58
    empty 1                           ; 59
    row7 C_5, 2                       ; 60
    empty 1                           ; 61
    row C_5, 2, FX_VOLUME, $30        ; 62
    row7 C_5, 2                       ; 63
.voice1:
    row7 D_4, 3                       ; 00
    row7 D_4, 3                       ; 01
    empty 1                           ; 02
    row7 D_4, 3                       ; 03
    empty 2                           ; 04
    row7 D_4, 3                       ; 06
    empty 1                           ; 07
    row7 C_4, 3                       ; 08
    row7 D_4, 3                       ; 09
    empty 1                           ; 10
    row7 D_4, 3                       ; 11
    empty 2                           ; 12
    row7 D_4, 3                       ; 14
    empty 1                           ; 15
    row C_4, 3, FX_VOLUME, $40        ; 16
    row C_4, 3, FX_VOLUME, $40        ; 17
    empty 1                           ; 18
    row C_4, 3, FX_VOLUME, $40        ; 19
    empty 2                           ; 20
    row C_4, 3, FX_VOLUME, $40        ; 22
    empty 1                           ; 23
    row E_4, 3, FX_VOLUME, $40        ; 24
    row E_4, 3, FX_VOLUME, $40        ; 25
    empty 1                           ; 26
    row E_4, 3, FX_VOLUME, $40        ; 27
    empty 2                           ; 28
    row E_4, 3, FX_VOLUME, $40        ; 30
    empty 1                           ; 31
    row D_4, 3, FX_VOLUME, $40        ; 32
    row D_4, 3, FX_VOLUME, $40        ; 33
    empty 1                           ; 34
    row7 D_4, 3                       ; 35
    empty 2                           ; 36
    row7 D_4, 3                       ; 38
    empty 1                           ; 39
    row D_4, 3, FX_VOLUME, $40        ; 40
    row D_4, 3, FX_VOLUME, $40        ; 41
    empty 1                           ; 42
    row7 D_4, 3                       ; 43
    empty 2                           ; 44
    row7 D_4, 3                       ; 46
    empty 1                           ; 47
    row D_4, 3, FX_VOLUME, $40        ; 48
    row7 D_4, 3                       ; 49
    empty 1                           ; 50
    row7 D_4, 3                       ; 51
    empty 2                           ; 52
    row7 D_4, 3                       ; 54
    empty 1                           ; 55
    row7 C_4, 3                       ; 56
    row7 D_4, 3                       ; 57
    empty 1                           ; 58
    row7 D_4, 3                       ; 59
    empty 2                           ; 60
    row7 D_4, 3                       ; 62
    empty 1                           ; 63
.voice2:
    row7 D_4, 5                       ; 00
    row ___, 0, FX_VOLUME, $20        ; 01
    row7 D_4, 5                       ; 02
    row ___, 0, FX_VOLUME, $15        ; 03
    row7 D_3, 5                       ; 04
    row ___, 0, FX_VOLUME, $10        ; 05
    row7 D_3, 5                       ; 06
    row ___, 0, FX_VOLUME, $05        ; 07
    row7 D_5, 5                       ; 08
    row ___, 0, FX_VOLUME, $20        ; 09
    row7 D_5, 5                       ; 10
    row ___, 0, FX_VOLUME, $20        ; 11
    row7 D_4, 5                       ; 12
    row ___, 0, FX_VOLUME, $20        ; 13
    row7 D_4, 5                       ; 14
    row ___, 0, FX_VOLUME, $20        ; 15
    row7 C_3, 5                       ; 16
    row ___, 0, FX_VOLUME, $20        ; 17
    row7 C_3, 5                       ; 18
    row ___, 0, FX_VOLUME, $15        ; 19
    row7 C_4, 5                       ; 20
    row ___, 0, FX_VOLUME, $10        ; 21
    row7 C_4, 5                       ; 22
    row ___, 0, FX_VOLUME, $05        ; 23
    row7 E_5, 5                       ; 24
    row ___, 0, FX_VOLUME, $20        ; 25
    row7 E_5, 5                       ; 26
    row ___, 0, FX_VOLUME, $15        ; 27
    row7 E_4, 5                       ; 28
    row ___, 0, FX_VOLUME, $10        ; 29
    row7 E_4, 5                       ; 30
    row ___, 0, FX_VOLUME, $05        ; 31
    row7 D_3, 5                       ; 32
    row ___, 0, FX_VOLUME, $20        ; 33
    row7 D_3, 5                       ; 34
    row ___, 0, FX_VOLUME, $15        ; 35
    row7 D_4, 5                       ; 36
    row ___, 0, FX_VOLUME, $10        ; 37
    row7 D_4, 5                       ; 38
    row ___, 0, FX_VOLUME, $05        ; 39
    row7 D_5, 5                       ; 40
    row ___, 0, FX_VOLUME, $20        ; 41
    row7 D_5, 5                       ; 42
    row ___, 0, FX_VOLUME, $20        ; 43
    row7 D_4, 5                       ; 44
    row ___, 0, FX_VOLUME, $20        ; 45
    row7 D_4, 5                       ; 46
    row ___, 0, FX_VOLUME, $20        ; 47
    row7 D_4, 5                       ; 48
    row ___, 0, FX_VOLUME, $20        ; 49
    row7 D_4, 5                       ; 50
    row ___, 0, FX_VOLUME, $20        ; 51
    row7 D_3, 5                       ; 52
    row ___, 0, FX_VOLUME, $20        ; 53
    row7 D_3, 5                       ; 54
    row ___, 0, FX_VOLUME, $20        ; 55
    row7 D_5, 5                       ; 56
    row ___, 0, FX_VOLUME, $20        ; 57
    row7 D_5, 5                       ; 58
    row ___, 0, FX_VOLUME, $20        ; 59
    row7 D_4, 5                       ; 60
    row ___, 0, FX_VOLUME, $20        ; 61
    row7 D_4, 5                       ; 62
    row ___, 0, FX_VOLUME, $20        ; 63
Song4_Pad:
    db $00
Song4_End:

; ============================================================================
; Instruments (SndInitSong DE).  instrument transpose, burst ticks, burst
; noise, vibrato, vibrato delay, fine volume, unused, pitch, noise, envelope
; ============================================================================
InstrumentTable:
    dw Ins_Kick          ; 1
    dw Ins_Snare         ; 2
    dw Ins_Bass          ; 3
    dw Ins_Chord         ; 4
    dw Ins_Lead          ; 5
    dw Ins_Unused6       ; 6
    dw Ins_HiHat         ; 7
    dw Ins_Bass          ; 8
    dw Ins_Bass          ; 9
    dw Ins_Null          ; 10
    dw Ins_Null          ; 11
Ins_Null:
    instrument 0, 0, $00, $00, 0, 0, 0, 0, 0, 0
Ins_Lead:
    instrument 0, 0, $00, $23, 5, 0, 0, Pitch_Lead, 0, Env_Lead
Ins_Chord:
    instrument 0, 0, $00, $00, 0, 0, 0, Pitch_Chord, 0, Env_Chord
Unused_Ins_LeadHi:
    instrument 12, 0, $00, $23, 6, 0, 0, Pitch_Lead, 0, Unused_Env_LeadHi
Ins_Unused6:
    instrument 1, 0, $00, $23, 6, 0, 0, Pitch_Lead, 0, Env_Unused6
Ins_Bass:
    instrument -12, 0, $00, $73, 1, 0, 0, Pitch_Bass, 0, Env_Bass
Ins_Kick:
    instrument 0, 1, $54, $00, 0, 0, 0, Pitch_Kick, 0, Env_Kick
Ins_HiHat:
    instrument 24, 1, $54, $00, 0, 0, 0, 0, 0, Env_HiHat
Ins_Snare:
    instrument 9, 1, $54, $00, 0, 0, 0, Pitch_Snare, 0, Env_Snare

; Pitch tables: signed semitone steps per tick, $80 = stop, $81 n = loop to entry n.
; Envelopes: ticks-1, volume pairs, $FF = hold.
Pitch_Chord:
    db $04, $03, $F9, $81, $00  ; +4 +3 -7 loop 0
Pitch_Kick:
    db $FC, $81, $00  ; -4 loop 0
Pitch_Bass:
    db $06, $FA, $00, $80  ; +6 -6 +0 stop
Pitch_Lead:
    db $0C, $F4, $00, $80  ; +12 -12 +0 stop
Unused_Pitch_5D4B:
    db $FA, $FA, $FA, $00, $80  ; -6 -6 -6 +0 stop
Pitch_Snare:
    db $FC, $81, $00  ; -4 loop 0
Env_Snare:
    db 2, 8, 2, 7, 1, 6, 1, 5, 1, 0, $FF  ; 8 x3, 7 x3, 6 x2, 5 x2, 0 x2, hold
Env_Kick:
    db 1, 9, 2, 8, 1, 7, 1, 6, 1, 0, $FF  ; 9 x2, 8 x3, 7 x2, 6 x2, 0 x2, hold
Env_HiHat:
    db 2, 12, 1, 0, $FF  ; 12 x3, 0 x2, hold
Env_Bass:
    db 1, 8, 1, 9, 2, 7, 1, 6, 1, 4, 1, 3, 1, 0, $FF  ; 8 x2, 9 x2, 7 x3, 6 x2, 4 x2, 3 x2, 0 x2, hold
Env_Lead:
    db 1, 10, 2, 12, 64, 11, 64, 12, 64, 12, 64, 12, 64, 12, 1, 0, $FF  ; 10 x2, 12 x3, 11 x65, 12 x65, 12 x65, 12 x65, 12 x65, 0 x2, hold
Env_Chord:
    db 1, 12, 2, 13, 1, 10, 1, 9, 1, 8, 1, 6, 1, 0, $FF  ; 12 x2, 13 x3, 10 x2, 9 x2, 8 x2, 6 x2, 0 x2, hold
Unused_Env_LeadHi:
    db 1, 10, 1, 12, 40, 10, 1, 9, 1, 8, 1, 7, 1, 0, $FF  ; 10 x2, 12 x2, 10 x41, 9 x2, 8 x2, 7 x2, 0 x2, hold
Env_Unused6:
    db 1, 6, 1, 7, 5, 7, 1, 6, 1, 6, 1, 5, 1, 4, 1, 2, $FF  ; 6 x2, 7 x2, 7 x6, 6 x2, 6 x2, 5 x2, 4 x2, 2 x2, hold

; ============================================================================
; Sound effects (one frame per tick on CH2, see SndMixSfx)
; ============================================================================
SfxTable:
    dw Sfx_5DDF          ; 0
    dw Sfx_6060          ; 1
    dw Sfx_60AE          ; 2
    dw Sfx_5F82          ; 3
    dw Sfx_5F46          ; 4
    dw Sfx_5EFE          ; 5
    dw Sfx_5EE0          ; 6
    dw Sfx_611A          ; 7
    dw Sfx_5E57          ; 8
    dw Sfx_5E27          ; 9
    dw Sfx_5EA4          ; 10
    dw Sfx_5DDF          ; 11
    dw Sfx_6021          ; 12
    dw Sfx_5DE2          ; 13
    dw Sfx_5DF1          ; 14
    dw Sfx_5FF4          ; 15
    dw Sfx_5E80          ; 16
Sfx_5DDF:                          ; SFX 0, 11
    sfx_frame $00, $00, $20           ; vol  0, tone off , end
Sfx_5DE2:                          ; SFX 13
    sfx_frame $F3, $80, $40           ; vol 15, tone $47F
    sfx_frame $E3, $A0, $40           ; vol 14, tone $45F
    sfx_frame $D3, $B0, $40           ; vol 13, tone $44F
    sfx_frame $D3, $A0, $40           ; vol 13, tone $45F
    sfx_frame $00, $00, $20           ; vol  0, tone off , end
Sfx_5DF1:                          ; SFX 14
    sfx_frame $A0, $80, $40           ; vol 10, tone $57F
    sfx_frame $C0, $80, $40           ; vol 12, tone $57F
    sfx_frame $F0, $80, $40           ; vol 15, tone $57F
    sfx_frame $E0, $80, $40           ; vol 14, tone $57F
    sfx_frame $D0, $80, $40           ; vol 13, tone $57F
    sfx_frame $C0, $80, $40           ; vol 12, tone $57F
    sfx_frame $B0, $80, $40           ; vol 11, tone $57F
    sfx_frame $A0, $80, $40           ; vol 10, tone $57F
    sfx_frame $90, $80, $40           ; vol  9, tone $57F
    sfx_frame $80, $80, $40           ; vol  8, tone $57F
    sfx_frame $70, $80, $40           ; vol  7, tone $57F
    sfx_frame $60, $80, $40           ; vol  6, tone $57F
    sfx_frame $50, $80, $40           ; vol  5, tone $57F
    sfx_frame $40, $80, $40           ; vol  4, tone $57F
    sfx_frame $30, $80, $40           ; vol  3, tone $57F
    sfx_frame $20, $80, $40           ; vol  2, tone $57F
    sfx_frame $10, $80, $40           ; vol  1, tone $57F
    sfx_frame $00, $00, $20           ; vol  0, tone off , end
Sfx_5E27:                          ; SFX 9
    sfx_frame $F3, $70, $40           ; vol 15, tone $48F
    sfx_frame $F3, $50, $40           ; vol 15, tone $4AF
    sfx_frame $F3, $30, $40           ; vol 15, tone $4CF
    sfx_frame $F3, $10, $40           ; vol 15, tone $4EF
    sfx_frame $F3, $00, $40           ; vol 15, tone $4FF
    sfx_frame $F2, $70, $40           ; vol 15, tone $58F
    sfx_frame $F2, $50, $40           ; vol 15, tone $5AF
    sfx_frame $F2, $30, $40           ; vol 15, tone $5CF
    sfx_frame $F2, $10, $40           ; vol 15, tone $5EF
    sfx_frame $F2, $00, $40           ; vol 15, tone $5FF
    sfx_frame $F1, $70, $40           ; vol 15, tone $48F
    sfx_frame $E1, $50, $40           ; vol 14, tone $4AF
    sfx_frame $E1, $30, $40           ; vol 14, tone $4CF
    sfx_frame $E1, $10, $40           ; vol 14, tone $4EF
    sfx_frame $E1, $00, $40           ; vol 14, tone $4FF
    sfx_frame $00, $00, $20           ; vol  0, tone off , end
Sfx_5E57:                          ; SFX 8
    sfx_frame $F0, $00, $85           ; vol 15, tone off , noise
    sfx_frame $C0, $00, $85           ; vol 12, tone off , noise
    sfx_frame $A0, $00, $86           ; vol 10, tone off , noise
    sfx_frame $90, $00, $87           ; vol  9, tone off , noise
    sfx_frame $70, $00, $88           ; vol  7, tone off , noise
    sfx_frame $50, $00, $89           ; vol  5, tone off , noise
    db $00, $00                     ; frame 7 c, d; e = next byte ($F0: bit 5 ends SFX 8)
Unused_Sfx8Copy:                    ; complete copy of SFX 8, never referenced
    sfx_frame $F0, $00, $85           ; vol 15, tone off , noise
    sfx_frame $C0, $00, $85           ; vol 12, tone off , noise
    sfx_frame $A0, $00, $86           ; vol 10, tone off , noise
    sfx_frame $90, $00, $87           ; vol  9, tone off , noise
    sfx_frame $70, $00, $88           ; vol  7, tone off , noise
    sfx_frame $50, $00, $89           ; vol  5, tone off , noise
    sfx_frame $00, $00, $20           ; vol  0, tone off , end
Sfx_5E80:                          ; SFX 16
    sfx_frame $80, $00, $9F           ; vol  8, tone off , noise
    sfx_frame $70, $00, $97           ; vol  7, tone off , noise
    sfx_frame $60, $00, $8F           ; vol  6, tone off , noise
    sfx_frame $50, $00, $87           ; vol  5, tone off , noise
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $00, $00, $20           ; vol  0, tone off , end
Sfx_5EA4:                          ; SFX 10
    sfx_frame $E1, $40, $40           ; vol 14, tone $4BF
    sfx_frame $F1, $40, $40           ; vol 15, tone $4BF
    sfx_frame $D1, $40, $40           ; vol 13, tone $4BF
    sfx_frame $A1, $40, $40           ; vol 10, tone $4BF
    sfx_frame $81, $40, $40           ; vol  8, tone $4BF
    sfx_frame $41, $40, $40           ; vol  4, tone $4BF
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $01, $40, $40           ; vol  0, tone $4BF
    sfx_frame $E1, $40, $40           ; vol 14, tone $4BF
    sfx_frame $F1, $40, $40           ; vol 15, tone $4BF
    sfx_frame $E1, $40, $40           ; vol 14, tone $4BF
    sfx_frame $D1, $50, $40           ; vol 13, tone $4AF
    sfx_frame $C1, $60, $40           ; vol 12, tone $49F
    sfx_frame $A1, $70, $40           ; vol 10, tone $48F
    sfx_frame $91, $80, $40           ; vol  9, tone $47F
    sfx_frame $71, $90, $40           ; vol  7, tone $46F
    sfx_frame $51, $A0, $40           ; vol  5, tone $45F
    sfx_frame $31, $B0, $40           ; vol  3, tone $44F
    sfx_frame $11, $C0, $40           ; vol  1, tone $43F
    sfx_frame $00, $00, $20           ; vol  0, tone off , end
Sfx_5EE0:                          ; SFX 6
    sfx_frame $F7, $FF, $C0           ; vol 15, tone $000, noise
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $E7, $FF, $C0           ; vol 14, tone $000, noise
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $00, $00, $20           ; vol  0, tone off , end
Sfx_5EFE:                          ; SFX 5
    sfx_frame $E4, $80, $40           ; vol 14, tone $17F
    sfx_frame $F4, $80, $40           ; vol 15, tone $17F
    sfx_frame $F4, $80, $40           ; vol 15, tone $17F
    sfx_frame $F4, $80, $40           ; vol 15, tone $17F
    sfx_frame $F4, $80, $40           ; vol 15, tone $17F
    sfx_frame $F4, $80, $40           ; vol 15, tone $17F
    sfx_frame $C4, $80, $40           ; vol 12, tone $17F
    sfx_frame $A4, $80, $40           ; vol 10, tone $17F
    sfx_frame $94, $80, $40           ; vol  9, tone $17F
    sfx_frame $54, $80, $40           ; vol  5, tone $17F
    sfx_frame $E5, $FF, $40           ; vol 14, tone $000
    sfx_frame $F5, $FF, $40           ; vol 15, tone $000
    sfx_frame $E5, $FF, $40           ; vol 14, tone $000
    sfx_frame $D5, $FF, $40           ; vol 13, tone $000
    sfx_frame $C5, $FF, $40           ; vol 12, tone $000
    sfx_frame $B5, $FF, $40           ; vol 11, tone $000
    sfx_frame $A5, $FF, $40           ; vol 10, tone $000
    sfx_frame $95, $FF, $40           ; vol  9, tone $000
    sfx_frame $75, $FF, $40           ; vol  7, tone $000
    sfx_frame $55, $FF, $40           ; vol  5, tone $000
    sfx_frame $45, $FF, $40           ; vol  4, tone $000
    sfx_frame $25, $FF, $40           ; vol  2, tone $000
    sfx_frame $15, $FF, $40           ; vol  1, tone $000
    sfx_frame $00, $00, $20           ; vol  0, tone off , end
Sfx_5F46:                          ; SFX 4
    sfx_frame $F1, $80, $40           ; vol 15, tone $47F
    sfx_frame $F1, $80, $40           ; vol 15, tone $47F
    sfx_frame $E1, $80, $40           ; vol 14, tone $47F
    sfx_frame $E1, $80, $40           ; vol 14, tone $47F
    sfx_frame $D1, $80, $40           ; vol 13, tone $47F
    sfx_frame $D1, $80, $40           ; vol 13, tone $47F
    sfx_frame $C1, $80, $40           ; vol 12, tone $47F
    sfx_frame $C1, $80, $40           ; vol 12, tone $47F
    sfx_frame $B1, $80, $40           ; vol 11, tone $47F
    sfx_frame $A1, $80, $40           ; vol 10, tone $47F
    sfx_frame $91, $80, $40           ; vol  9, tone $47F
    sfx_frame $81, $80, $40           ; vol  8, tone $47F
    sfx_frame $71, $80, $40           ; vol  7, tone $47F
    sfx_frame $61, $80, $40           ; vol  6, tone $47F
    sfx_frame $51, $80, $40           ; vol  5, tone $47F
    sfx_frame $41, $80, $40           ; vol  4, tone $47F
    sfx_frame $31, $80, $40           ; vol  3, tone $47F
    sfx_frame $21, $80, $40           ; vol  2, tone $47F
    sfx_frame $11, $80, $40           ; vol  1, tone $47F
    sfx_frame $03, $80, $60           ; vol  0, tone $47F, end
Sfx_5F82:                          ; SFX 3
    sfx_frame $C0, $FF, $40           ; vol 12, tone $500
    sfx_frame $D0, $FF, $40           ; vol 13, tone $500
    sfx_frame $E0, $FF, $40           ; vol 14, tone $500
    sfx_frame $F0, $FF, $40           ; vol 15, tone $500
    sfx_frame $E0, $FF, $40           ; vol 14, tone $500
    sfx_frame $D0, $FF, $40           ; vol 13, tone $500
    sfx_frame $C0, $FF, $40           ; vol 12, tone $500
    sfx_frame $B0, $FF, $40           ; vol 11, tone $500
    sfx_frame $A0, $FF, $40           ; vol 10, tone $500
    sfx_frame $90, $FF, $40           ; vol  9, tone $500
    sfx_frame $80, $FF, $40           ; vol  8, tone $500
    sfx_frame $70, $FF, $40           ; vol  7, tone $500
    sfx_frame $60, $FF, $40           ; vol  6, tone $500
    sfx_frame $50, $FF, $40           ; vol  5, tone $500
    sfx_frame $40, $FF, $40           ; vol  4, tone $500
    sfx_frame $30, $FF, $40           ; vol  3, tone $500
    sfx_frame $20, $FF, $40           ; vol  2, tone $500
    sfx_frame $10, $FF, $40           ; vol  1, tone $500
    sfx_frame $00, $00, $40           ; vol  0, tone $5FF
    sfx_frame $C1, $FF, $40           ; vol 12, tone $400
    sfx_frame $D1, $FF, $40           ; vol 13, tone $400
    sfx_frame $E1, $FF, $40           ; vol 14, tone $400
    sfx_frame $F1, $FF, $40           ; vol 15, tone $400
    sfx_frame $E1, $FF, $40           ; vol 14, tone $400
    sfx_frame $D1, $FF, $40           ; vol 13, tone $400
    sfx_frame $C1, $FF, $40           ; vol 12, tone $400
    sfx_frame $B1, $FF, $40           ; vol 11, tone $400
    sfx_frame $A1, $FF, $40           ; vol 10, tone $400
    sfx_frame $91, $FF, $40           ; vol  9, tone $400
    sfx_frame $81, $FF, $40           ; vol  8, tone $400
    sfx_frame $71, $FF, $40           ; vol  7, tone $400
    sfx_frame $61, $FF, $40           ; vol  6, tone $400
    sfx_frame $51, $FF, $40           ; vol  5, tone $400
    sfx_frame $41, $FF, $40           ; vol  4, tone $400
    sfx_frame $31, $FF, $40           ; vol  3, tone $400
    sfx_frame $21, $FF, $40           ; vol  2, tone $400
    sfx_frame $11, $FF, $40           ; vol  1, tone $400
    sfx_frame $00, $00, $60           ; vol  0, tone $5FF, end
Sfx_5FF4:                          ; SFX 15
    sfx_frame $F0, $80, $40           ; vol 15, tone $57F
    sfx_frame $F0, $70, $40           ; vol 15, tone $58F
    sfx_frame $E0, $60, $40           ; vol 14, tone $59F
    sfx_frame $D0, $50, $40           ; vol 13, tone $5AF
    sfx_frame $C0, $40, $40           ; vol 12, tone $5BF
    sfx_frame $B0, $30, $40           ; vol 11, tone $5CF
    sfx_frame $00, $00, $40           ; vol  0, tone $5FF
    sfx_frame $F0, $80, $40           ; vol 15, tone $57F
    sfx_frame $F0, $70, $40           ; vol 15, tone $58F
    sfx_frame $E0, $60, $40           ; vol 14, tone $59F
    sfx_frame $D0, $50, $40           ; vol 13, tone $5AF
    sfx_frame $C0, $40, $40           ; vol 12, tone $5BF
    sfx_frame $B0, $30, $40           ; vol 11, tone $5CF
    sfx_frame $00, $00, $40           ; vol  0, tone $5FF
    sfx_frame $00, $00, $20           ; vol  0, tone off , end
Sfx_6021:                          ; SFX 12
    sfx_frame $F3, $FF, $40           ; vol 15, tone $400
    sfx_frame $F3, $FF, $40           ; vol 15, tone $400
    sfx_frame $F3, $FF, $40           ; vol 15, tone $400
    sfx_frame $F3, $FF, $40           ; vol 15, tone $400
    sfx_frame $F3, $80, $40           ; vol 15, tone $47F
    sfx_frame $F3, $80, $40           ; vol 15, tone $47F
    sfx_frame $F3, $80, $40           ; vol 15, tone $47F
    sfx_frame $F3, $80, $40           ; vol 15, tone $47F
    sfx_frame $E3, $FF, $40           ; vol 14, tone $400
    sfx_frame $E3, $FF, $40           ; vol 14, tone $400
    sfx_frame $D3, $FF, $40           ; vol 13, tone $400
    sfx_frame $D3, $FF, $40           ; vol 13, tone $400
    sfx_frame $C3, $80, $40           ; vol 12, tone $47F
    sfx_frame $C3, $80, $40           ; vol 12, tone $47F
    sfx_frame $B3, $80, $40           ; vol 11, tone $47F
    sfx_frame $B3, $80, $40           ; vol 11, tone $47F
    sfx_frame $A3, $FF, $40           ; vol 10, tone $400
    sfx_frame $A3, $FF, $40           ; vol 10, tone $400
    sfx_frame $73, $FF, $40           ; vol  7, tone $400
    sfx_frame $53, $FF, $40           ; vol  5, tone $400
    sfx_frame $00, $00, $20           ; vol  0, tone off , end
Sfx_6060:                          ; SFX 1
    sfx_frame $F3, $00, $9E           ; vol 15, tone off , noise
    sfx_frame $F3, $00, $99           ; vol 15, tone off , noise
    sfx_frame $F3, $00, $94           ; vol 15, tone off , noise
    sfx_frame $F3, $00, $8F           ; vol 15, tone off , noise
    sfx_frame $F3, $00, $8A           ; vol 15, tone off , noise
    sfx_frame $F0, $00, $8A           ; vol 15, tone off , noise
    sfx_frame $F0, $00, $92           ; vol 15, tone off , noise
    sfx_frame $D0, $00, $9E           ; vol 13, tone off , noise
    sfx_frame $D0, $00, $99           ; vol 13, tone off , noise
    sfx_frame $D0, $00, $94           ; vol 13, tone off , noise
    sfx_frame $D3, $00, $8F           ; vol 13, tone off , noise
    sfx_frame $D3, $00, $8D           ; vol 13, tone off , noise
    sfx_frame $D3, $00, $90           ; vol 13, tone off , noise
    sfx_frame $D3, $00, $93           ; vol 13, tone off , noise
    sfx_frame $D0, $00, $8A           ; vol 13, tone off , noise
    sfx_frame $D0, $00, $8A           ; vol 13, tone off , noise
    sfx_frame $D0, $00, $8A           ; vol 13, tone off , noise
    sfx_frame $C0, $00, $8A           ; vol 12, tone off , noise
    sfx_frame $A0, $00, $8A           ; vol 10, tone off , noise
    sfx_frame $90, $00, $8A           ; vol  9, tone off , noise
    sfx_frame $80, $00, $8A           ; vol  8, tone off , noise
    sfx_frame $70, $00, $8A           ; vol  7, tone off , noise
    sfx_frame $60, $00, $8A           ; vol  6, tone off , noise
    sfx_frame $50, $00, $8A           ; vol  5, tone off , noise
    sfx_frame $40, $00, $8A           ; vol  4, tone off , noise
    sfx_frame $30, $00, $20           ; vol  3, tone off , end
Sfx_60AE:                          ; SFX 2
    sfx_frame $F0, $00, $9E           ; vol 15, tone off , noise
    sfx_frame $F0, $00, $9C           ; vol 15, tone off , noise
    sfx_frame $F0, $00, $9A           ; vol 15, tone off , noise
    sfx_frame $F0, $00, $99           ; vol 15, tone off , noise
    sfx_frame $F0, $00, $98           ; vol 15, tone off , noise
    sfx_frame $F0, $00, $98           ; vol 15, tone off , noise
    sfx_frame $F0, $00, $98           ; vol 15, tone off , noise
    sfx_frame $F0, $00, $98           ; vol 15, tone off , noise
    sfx_frame $E0, $00, $98           ; vol 14, tone off , noise
    sfx_frame $E0, $00, $98           ; vol 14, tone off , noise
    sfx_frame $E0, $00, $98           ; vol 14, tone off , noise
    sfx_frame $E0, $00, $98           ; vol 14, tone off , noise
    sfx_frame $E0, $00, $98           ; vol 14, tone off , noise
    sfx_frame $E0, $00, $98           ; vol 14, tone off , noise
    sfx_frame $D0, $00, $98           ; vol 13, tone off , noise
    sfx_frame $D0, $00, $98           ; vol 13, tone off , noise
    sfx_frame $D0, $00, $98           ; vol 13, tone off , noise
    sfx_frame $D0, $00, $98           ; vol 13, tone off , noise
    sfx_frame $D0, $00, $98           ; vol 13, tone off , noise
    sfx_frame $D0, $00, $98           ; vol 13, tone off , noise
    sfx_frame $A0, $00, $98           ; vol 10, tone off , noise
    sfx_frame $A0, $00, $98           ; vol 10, tone off , noise
    sfx_frame $A0, $00, $98           ; vol 10, tone off , noise
    sfx_frame $90, $00, $98           ; vol  9, tone off , noise
    sfx_frame $90, $00, $98           ; vol  9, tone off , noise
    sfx_frame $90, $00, $98           ; vol  9, tone off , noise
    sfx_frame $80, $00, $98           ; vol  8, tone off , noise
    sfx_frame $80, $00, $98           ; vol  8, tone off , noise
    sfx_frame $80, $00, $98           ; vol  8, tone off , noise
    sfx_frame $70, $00, $98           ; vol  7, tone off , noise
    sfx_frame $70, $00, $98           ; vol  7, tone off , noise
    sfx_frame $70, $00, $98           ; vol  7, tone off , noise
    sfx_frame $60, $00, $98           ; vol  6, tone off , noise
    sfx_frame $40, $00, $98           ; vol  4, tone off , noise
    sfx_frame $20, $00, $98           ; vol  2, tone off , noise
    sfx_frame $00, $00, $20           ; vol  0, tone off , end
Sfx_611A:                          ; SFX 7
    sfx_frame $D0, $00, $80           ; vol 13, tone off , noise
    sfx_frame $E0, $00, $80           ; vol 14, tone off , noise
    sfx_frame $A0, $00, $80           ; vol 10, tone off , noise
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $C0, $00, $81           ; vol 12, tone off , noise
    sfx_frame $D0, $00, $81           ; vol 13, tone off , noise
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $C0, $00, $80           ; vol 12, tone off , noise
    sfx_frame $E0, $00, $80           ; vol 14, tone off , noise
    sfx_frame $C0, $00, $80           ; vol 12, tone off , noise
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $B0, $00, $80           ; vol 11, tone off , noise
    sfx_frame $E0, $00, $80           ; vol 14, tone off , noise
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $00, $00, $00           ; vol  0, tone off 
    sfx_frame $00, $00, $20           ; vol  0, tone off , end
