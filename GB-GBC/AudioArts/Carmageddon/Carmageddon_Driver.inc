; Carmageddon (GBC) - driver code $4000-$45F4

; ---------------------------------------------------------------------------
; Called once per frame: each channel block, the ghost stepper, then the wave morph (if the build has one).
; Channel 1: count the tempo; when a tick is due count the note length; at 0 read the next event.
Musicd::
    ld hl, tempo1
    dec [hl]
    jr z, Ch1_TempoReload
    inc hl
    jp Ch1_Update

Ch1_TempoReload:
    ld [hl], $07
    inc hl
    dec [hl]
    jr z, Ch1_NextEvent
    jp Ch1_Update

; ---------------------------------------------------------------------------
; Read the next pattern byte: $FF = song jump (word = step list), $00 = end of pattern.
Ch1_NextEvent:
    inc hl
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld a, [de]
    cp a, $FF
    jr nz, Ch1_NotSongJump
    inc hl
    inc de
    ld a, [de]
    ld b, a
    inc de
    ld a, [de]
    ld d, a
    ld a, b
    ld e, a
    jr Ch1_LoadStep

Ch1_NotSongJump:
    cp a, $00
    jr nz, Ch1_ReadLength
    inc hl
    inc hl
    ld e, [hl]
    inc hl
    ld d, [hl]
    dec hl
    dec hl

; ---------------------------------------------------------------------------
; Step = transpose, pattern number. Point seqadr at the pattern; its first byte is a length.
Ch1_LoadStep:
    ld a, [de]
    ld [hl], a
    inc de
    ld a, [de]
    inc de
    inc hl
    ld [hl], e
    inc hl
    ld [hl], d
    ld e, a
    ld d, $00
    ld hl, PatternTable
    add hl, de
    add hl, de
    ld de, seqadr1
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hl]
    ld [de], a
    ld hl, seqadr1
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld hl, seqadr1+1
    ld a, [de]

; ---------------------------------------------------------------------------
; Store the length; the next byte is $FF hold, $FE key off, $FD key on, or a note.
Ch1_ReadLength:
    dec hl
    dec hl
    ld [hli], a
    inc de
    ld a, [de]
    cp a, $FF
    jr nz, Ch1_NotHold
    inc de
    ld [hl], e
    inc hl
    ld [hl], d
    jp Ch1_Update

Ch1_NotHold:
    cp a, $FE
    jr nz, Ch1_NotKeyOff
    ld a, [note1de]
    ldh [rNR12], a
    inc de
    ld [hl], e
    inc hl
    ld [hl], d
    jp Ch1_Update

Ch1_NotKeyOff:
    cp a, $FD
    jr nz, Ch1_Note
    ld a, [note1at]
    ldh [rNR12], a
    inc de
    ld [hl], e
    inc hl
    ld [hl], d
    jp Ch1_Update

; ---------------------------------------------------------------------------
; Note: add transpose, load the instrument (NRx1, envelopes, arp/freq/combine tables).
Ch1_Note:
    inc de
    ld b, a
    ld a, [transp1]
    add a, b
    ld [note1], a
    ld a, [de]
    inc de
    ld [hl], e
    inc hl
    ld [hl], d
    ld e, a
    ld d, $00
    ld hl, InstrumentTable
    add hl, de
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld a, [de]
    ldh [rNR11], a
    inc de
    ld a, [de]
    ldh [rNR12], a
    ld [note1at], a
    inc de
    ld a, [de]
    ld [note1de], a
    inc de
    ld hl, freqval1
    xor a, a
    ld [hli], a
    ld [hl], a
    inc a
    ld [freqtim1], a
    ld [arptim1], a
    ld [combtim1], a
    ld hl, arptabadr1
    ld a, [de]
    inc de
    ld [hli], a
    ld a, [de]
    inc de
    ld [hl], a
    ld hl, freqtabadr1
    ld a, [de]
    inc de
    ld [hli], a
    ld a, [de]
    inc de
    ld [hl], a
    ld hl, combtabadr1
    ld a, [de]
    inc de
    ld [hli], a
    ld a, [de]
    inc de
    ld [hl], a
    ld a, $01
    ld [noterset1], a
    jp Ch2_Sequencer

; ---------------------------------------------------------------------------
; Every frame: retrigger if noterset, then walk the freq, arp and combine tables.
Ch1_Update:
    ld hl, noterset1
    ld a, [hl]
    cp a, $00
    jr z, Ch1_Tables
    ld a, $00
    ld [hl], a
    ld a, $80
    ldh [rNR14], a

Ch1_Tables:
    inc hl
    ld e, l
    ld d, h
    inc hl
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [de]
    dec a
    jr nz, Ch1_FreqApply
    inc hl
    inc hl
    ld a, [hli]
    cp a, $00
    jr nz, Ch1_FreqApply
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [hli]

; ---------------------------------------------------------------------------
; Freq table entry: add the signed delta to freqval.
Ch1_FreqApply:
    ld [de], a
    ld a, l
    ld d, h
    ld b, [hl]
    inc hl
    ld e, [hl]
    ld hl, freqtabadr1
    ld [hli], a
    ld [hl], d
    inc hl
    ld a, b
    add a, [hl]
    ld [hli], a
    ld a, e
    adc a, [hl]
    ld [hli], a
    ld e, l
    ld d, h
    inc hl
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [de]
    dec a
    jr nz, Ch1_ArpApply
    inc hl
    ld a, [hli]
    cp a, $00
    jr nz, Ch1_ArpApply
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [hli]

; ---------------------------------------------------------------------------
; Arp table entry: semitone offset for this frame.
Ch1_ArpApply:
    ld [de], a
    ld a, l
    ld d, h
    ld c, [hl]
    ld hl, arptabadr1
    ld [hli], a
    ld [hl], d
    inc hl
    ld e, l
    ld d, h
    inc hl
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [de]
    dec a
    jr nz, Ch1_CombApply
    inc hl
    ld a, [hli]
    cp a, $00
    jr nz, Ch1_CombApply
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [hli]

; ---------------------------------------------------------------------------
; Combine: 0 = freqval only, 1 = note, 2 = note + freqval.
Ch1_CombApply:
    ld [de], a
    ld a, l
    ld d, h
    ld e, [hl]
    ld hl, combtabadr1
    ld [hli], a
    ld [hl], d
    inc hl
    ld b, e
    ld a, b
    cp a, $00
    jr nz, Ch1_NotePeriod
    ld d, $00
    ld e, d
    jr Ch1_AddFreqval

Ch1_NotePeriod:
    ld a, [hl]
    add a, c
    ld e, a
    ld d, $00
    ld hl, FreqTable
    add hl, de
    add hl, de
    ld a, [hli]
    ld e, a
    ld d, [hl]
    ld a, b
    cp a, $02
    jr nz, Ch1_WritePeriod

Ch1_AddFreqval:
    ld hl, freqval1
    ld a, [hli]
    add a, e
    ld e, a
    ld a, [hl]
    adc a, d
    ld d, a

; ---------------------------------------------------------------------------
; Write the period (no restart bit).
Ch1_WritePeriod:
    ld a, d
    and a, $07
    ldh [rNR14], a
    ld a, e
    ldh [rNR13], a

; ---------------------------------------------------------------------------
; Channel 2. While noteechanadr = tempo2 the SFX struct (tempoe...) runs here instead of the music.
Ch2_Sequencer:
    ld a, [noteechanadr]
    cp a, LOW(tempo2)
    jr nz, Ch2_MusicTempo
    ld hl, tempoe
    jp Ch2_CountTempo

Ch2_MusicTempo:
    ld hl, tempo2

Ch2_CountTempo:
    dec [hl]
    jr z, Ch2_TempoReload
    inc hl
    jp Ch2_Update

Ch2_TempoReload:
    ld [hl], $07
    inc hl
    dec [hl]
    jr z, Ch2_NextEvent
    jp Ch2_Update

Ch2_NextEvent:
    inc hl
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld a, [de]
    cp a, $FF
    jr nz, Ch2_NotSongJump
    inc hl
    inc de
    ld a, [de]
    ld b, a
    inc de
    ld a, [de]
    ld d, a
    ld a, b
    ld e, a
    jp Ch2_LoadStep

Ch2_NotSongJump:
    cp a, $00
    jr nz, Ch2_ReadLength
    ld a, [noteechanadr]
    cp a, LOW(tempo2)
    jr nz, Ch2_NextStep
    ld a, $FF
    ld [effend], a
    jp Ch2_Update

Ch2_NextStep:
    inc hl
    inc hl
    ld e, [hl]
    inc hl
    ld d, [hl]
    dec hl
    dec hl

Ch2_LoadStep:
    ld a, [de]
    ld [hl], a
    inc de
    ld a, [de]
    inc de
    inc hl
    ld [hl], e
    inc hl
    ld [hl], d
    ld e, a
    ld d, $00
    ld hl, PatternTable
    add hl, de
    add hl, de
    ld de, seqadr2
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hl]
    ld [de], a
    ld hl, seqadr2
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld hl, seqadr2+1
    ld a, [de]

Ch2_ReadLength:
    dec hl
    dec hl
    ld [hli], a
    inc de
    ld a, [de]
    cp a, $FF
    jr nz, Ch2_NotHold
    inc de
    ld [hl], e
    inc hl
    ld [hl], d
    jp Ch2_Update

Ch2_NotHold:
    cp a, $FE
    jr nz, Ch2_NotKeyOff
    ld a, [note2de]
    ldh [rNR22], a
    inc de
    ld [hl], e
    inc hl
    ld [hl], d
    jp Ch2_Update

Ch2_NotKeyOff:
    cp a, $FD
    jr nz, Ch2_Note
    ld a, [note2at]
    ldh [rNR22], a
    inc de
    ld [hl], e
    inc hl
    ld [hl], d
    jp Ch2_Update

Ch2_Note:
    inc de
    ld b, a
    ld a, [noteechanadr]
    cp a, LOW(tempo2)
    jr nz, Ch2_Transpose
    ld a, $00
    jp Ch2_AddTranspose

Ch2_Transpose:
    ld a, [transp2]

Ch2_AddTranspose:
    add a, b
    ld [note2], a
    ld a, [de]
    inc de
    ld [hl], e
    inc hl
    ld [hl], d
    ld e, a
    ld d, $00
    ld hl, InstrumentTable
    add hl, de
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld a, [de]
    ldh [rNR21], a
    inc de
    ld a, [de]
    ldh [rNR22], a
    ld [note2at], a
    inc de
    ld a, [de]
    ld [note2de], a
    inc de
    ld hl, freqval2
    xor a, a
    ld [hli], a
    ld [hl], a
    inc a
    ld [freqtim2], a
    ld [arptim2], a
    ld [combtim2], a
    ld hl, arptabadr2
    ld a, [de]
    inc de
    ld [hli], a
    ld a, [de]
    inc de
    ld [hl], a
    ld hl, freqtabadr2
    ld a, [de]
    inc de
    ld [hli], a
    ld a, [de]
    inc de
    ld [hl], a
    ld hl, combtabadr2
    ld a, [de]
    inc de
    ld [hli], a
    ld a, [de]
    inc de
    ld [hl], a
    ld a, $01
    ld [noterset2], a
    jp Ch4_Sequencer

Ch2_Update:
    ld hl, noterset2
    ld a, [hl]
    cp a, $00
    jr z, Ch2_Tables
    ld a, $00
    ld [hl], a
    ld a, $80
    ldh [rNR24], a

Ch2_Tables:
    inc hl
    ld e, l
    ld d, h
    inc hl
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [de]
    dec a
    jr nz, Ch2_FreqApply
    inc hl
    inc hl
    ld a, [hli]
    cp a, $00
    jr nz, Ch2_FreqApply
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [hli]

Ch2_FreqApply:
    ld [de], a
    ld a, l
    ld d, h
    ld b, [hl]
    inc hl
    ld c, [hl]
    ld hl, freqtabadr2
    ld [hli], a
    ld [hl], d
    inc hl
    ld a, b
    add a, [hl]
    ld [hli], a
    ld a, c
    adc a, [hl]
    ld [hli], a
    ld e, l
    ld d, h
    inc hl
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [de]
    dec a
    jr nz, Ch2_ArpApply
    inc hl
    ld a, [hli]
    cp a, $00
    jr nz, Ch2_ArpApply
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [hli]

Ch2_ArpApply:
    ld [de], a
    ld a, l
    ld d, h
    ld c, [hl]
    ld hl, arptabadr2
    ld [hli], a
    ld [hl], d
    inc hl
    ld e, l
    ld d, h
    inc hl
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [de]
    dec a
    jr nz, Ch2_CombApply
    inc hl
    ld a, [hli]
    cp a, $00
    jr nz, Ch2_CombApply
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [hli]

Ch2_CombApply:
    ld [de], a
    ld a, l
    ld d, h
    ld e, [hl]
    ld hl, combtabadr2
    ld [hli], a
    ld [hl], d
    inc hl
    ld b, e
    ld a, b
    cp a, $00
    jr nz, Ch2_NotePeriod
    ld d, $00
    ld e, d
    jr Ch2_AddFreqval

Ch2_NotePeriod:
    ld a, [hl]
    add a, c
    ld e, a
    ld d, $00
    ld hl, FreqTable
    add hl, de
    add hl, de
    ld a, [hli]
    ld e, a
    ld d, [hl]
    ld a, b
    cp a, $02
    jr nz, Ch2_WritePeriod

Ch2_AddFreqval:
    ld hl, freqval2
    ld a, [hli]
    add a, e
    ld e, a
    ld a, [hl]
    adc a, d
    ld d, a

Ch2_WritePeriod:
    ld a, d
    and a, $07
    ldh [rNR24], a
    ld a, e
    ldh [rNR23], a

; ---------------------------------------------------------------------------
; Channel 4 (noise). Like channel 2 (SFX capable); the note value is ignored.
Ch4_Sequencer:
    ld a, [noteechanadr]
    cp a, LOW(tempo4)
    jr nz, Ch4_MusicTempo
    ld hl, tempoe
    jp Ch4_CountTempo

Ch4_MusicTempo:
    ld hl, tempo4

Ch4_CountTempo:
    dec [hl]
    jr z, Ch4_TempoReload
    inc hl
    jp Ch4_Update

Ch4_TempoReload:
    ld [hl], $07
    inc hl
    dec [hl]
    jr z, Ch4_NextEvent
    jp Ch4_Update

Ch4_NextEvent:
    inc hl
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld a, [de]
    cp a, $FF
    jr nz, Ch4_NotSongJump
    inc hl
    inc de
    ld a, [de]
    ld b, a
    inc de
    ld a, [de]
    ld d, a
    ld a, b
    ld e, a
    jp Ch4_LoadStep

Ch4_NotSongJump:
    cp a, $00
    jr nz, Ch4_ReadLength
    ld a, [noteechanadr]
    cp a, LOW(tempo4)
    jr nz, Ch4_NextStep
    ld a, $FF
    ld [effend], a
    jp Ch4_Update

Ch4_NextStep:
    inc hl
    inc hl
    ld e, [hl]
    inc hl
    ld d, [hl]
    dec hl
    dec hl

Ch4_LoadStep:
    ld a, [de]
    ld [hl], a
    inc de
    ld a, [de]
    inc de
    inc hl
    ld [hl], e
    inc hl
    ld [hl], d
    ld e, a
    ld d, $00
    ld hl, PatternTable
    add hl, de
    add hl, de
    ld de, seqadr4
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hl]
    ld [de], a
    ld hl, seqadr4
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld hl, seqadr4+1
    ld a, [de]

Ch4_ReadLength:
    dec hl
    dec hl
    ld [hli], a
    inc de
    ld a, [de]
    cp a, $FF
    jr nz, Ch4_NotHold
    inc de
    ld [hl], e
    inc hl
    ld [hl], d
    jp Ch4_Update

Ch4_NotHold:
    cp a, $FE
    jr nz, Ch4_NotKeyOff
    ld a, [note4de]
    ldh [rNR42], a
    inc de
    ld [hl], e
    inc hl
    ld [hl], d
    jp Ch4_Update

Ch4_NotKeyOff:
    cp a, $FD
    jr nz, Ch4_Note
    ld a, [note4at]
    ldh [rNR42], a
    inc de
    ld [hl], e
    inc hl
    ld [hl], d
    jp Ch4_Update

Ch4_Note:
    inc de
    ld b, a
    ld a, [noteechanadr]
    cp a, LOW(tempo4)
    jr nz, Ch4_Transpose
    ld a, $00
    jp Ch4_AddTranspose

Ch4_Transpose:
    ld a, [transp4]

Ch4_AddTranspose:
    add a, b
    ld a, [de]
    inc de
    ld [hl], e
    inc hl
    ld [hl], d
    ld e, a
    ld d, $00
    ld hl, NoiseInstrumentTable
    add hl, de
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld a, [de]
    ldh [rNR41], a
    inc de
    ld a, [de]
    ldh [rNR42], a
    ld [note4at], a
    inc de
    ld a, [de]
    ld [note4de], a
    inc de
    ld a, $01
    ld [noisetim4], a
    ld [noise2tim4], a
    ld hl, noisetabadr4
    ld a, [de]
    inc de
    ld [hli], a
    ld a, [de]
    inc de
    ld [hl], a
    ld hl, noise2tabadr4
    ld a, [de]
    inc de
    ld [hli], a
    ld a, [de]
    inc de
    ld [hl], a
    ld a, $01
    ld [noterset4], a
    jp Ghost_Step

; ---------------------------------------------------------------------------
; Every frame: noise table -> NR43, second table -> NR44.
Ch4_Update:
    ld hl, noterset4
    ld a, [hl]
    cp a, $00
    jr z, Ch4_Tables
    ld a, $00
    ld [hl], a
    ld a, $80
    ldh [rNR44], a

Ch4_Tables:
    inc hl
    ld e, l
    ld d, h
    inc hl
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [de]
    dec a
    jr nz, Ch4_NoiseApply
    inc hl
    ld a, [hli]
    cp a, $00
    jr nz, Ch4_NoiseApply
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [hli]

Ch4_NoiseApply:
    ld [de], a
    ld a, l
    ld d, h
    ld c, [hl]
    ld hl, noisetabadr4
    ld [hli], a
    ld [hl], d
    inc hl
    ld a, c
    ldh [rNR43], a
    ld e, l
    ld d, h
    inc hl
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [de]
    dec a
    jr nz, Ch4_NoiseCtlApply
    inc hl
    ld a, [hli]
    cp a, $00
    jr nz, Ch4_NoiseCtlApply
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [hli]

Ch4_NoiseCtlApply:
    ld [de], a
    ld a, l
    ld d, h
    ld c, [hl]
    ld hl, noise2tabadr4
    ld [hli], a
    ld [hl], d
    inc hl
    ld a, c
    ldh [rNR44], a

; ---------------------------------------------------------------------------
; Ghost stepper: steps the music struct displaced by a sound effect, without sound,
; so it is in the right place when the effect ends.
Ghost_Step:
    ld hl, noteechanadr
    ld a, [hli]
    ld h, [hl]
    ld l, a
    cp a, $FF
    jr nz, Ghost_CountTempo
    jp Sfx_FreeSlot

Ghost_CountTempo:
    dec [hl]
    jr z, Ghost_TempoReload
    inc hl
    jp Sfx_FreeSlot

Ghost_TempoReload:
    ld [hl], $07
    inc hl
    dec [hl]
    jr z, Ghost_NextEvent
    jp Sfx_FreeSlot

Ghost_NextEvent:
    inc hl
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld a, [de]
    cp a, $FF
    jr nz, Ghost_NotSongJump
    inc hl
    inc de
    ld a, [de]
    ld b, a
    inc de
    ld a, [de]
    ld d, a
    ld a, b
    ld e, a
    jr Ghost_LoadStep

Ghost_NotSongJump:
    cp a, $00
    jr nz, Ghost_ReadLength
    inc hl
    inc hl
    ld e, [hl]
    inc hl
    ld d, [hl]
    dec hl
    dec hl

Ghost_LoadStep:
    ld a, [de]
    ld [hl], a
    inc de
    ld a, [de]
    inc de
    inc hl
    ld [hl], e
    inc hl
    ld [hl], d
    ld e, a
    ld d, $00
    ld hl, PatternTable
    add hl, de
    add hl, de
    ld a, [noteechanadr]
    cp a, LOW(tempo2)
    jr nz, Ghost_Ch4Pattern
    ld de, seqadr2
    jp Ghost_SetPattern

Ghost_Ch4Pattern:
    ld de, seqadr4

Ghost_SetPattern:
    ld a, [hli]
    ld [de], a
    inc de
    ld a, [hl]
    ld [de], a
    dec de
    ld l, e
    ld h, d
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld a, [de]

Ghost_ReadLength:
    dec hl
    dec hl
    ld [hli], a
    inc de
    ld a, [de]
    cp a, $FF
    jr nz, Ghost_NotHold
    inc de
    ld [hl], e
    inc hl
    ld [hl], d
    jp Sfx_FreeSlot

Ghost_NotHold:
    cp a, $FE
    jr nz, Ghost_NotKeyOff
    inc de
    ld [hl], e
    inc hl
    ld [hl], d
    jp Sfx_FreeSlot

Ghost_NotKeyOff:
    cp a, $FD
    jr nz, Ghost_Note
    inc de
    ld [hl], e
    inc hl
    ld [hl], d
    jp Sfx_FreeSlot

Ghost_Note:
    inc de
    ld b, a
    add a, b
    ld a, [de]
    inc de
    ld [hl], e
    inc hl
    ld [hl], d
    ld e, a
    ld d, $00
    ld hl, InstrumentTable
    add hl, de
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]

; ---------------------------------------------------------------------------
; effend = $FF -> noteechanadr = $FF: the channel goes back to the music.
Sfx_FreeSlot:
    ld a, [effend]
    cp a, $FF
    jr nz, Musicd_Done
    ld [noteechanadr], a

Musicd_Done:
    ret

; ---------------------------------------------------------------------------
; E = song. Load the song entry, reset the channels it uses, copy the wave to wave RAM.
MusicInit::
    ld hl, SongTable
    ld d, $00
    add hl, de
    add hl, de
    add hl, de
    add hl, de
    add hl, de
    add hl, de
    ld a, [hli]
    ld [patadr1], a
    ld a, [hli]
    ld [patadr1+1], a
    ld a, [hli]
    ld [patadr2], a
    ld a, [hli]
    ld [patadr2+1], a
    ld a, [hli]
    ld [patadr4], a
    ld a, [hli]
    ld [patadr4+1], a
    ld a, $1E
    ld [note1], a
    ld a, $00
    ldh [rNR14], a
    ldh [rNR11], a
    ldh [rNR24], a
    ldh [rNR21], a
    ldh [rNR44], a
    ldh [rNR42], a
    ld [freqval1], a
    ld [freqval1+1], a
    ld a, $01
    ld [freqtim1], a
    ld [tempo1], a
    ld [tempo2], a
    ld [tempo4], a
    ld hl, $4851
    ld a, l
    ld [freqtabadr1], a
    ld a, h
    ld [freqtabadr1+1], a
    ld a, $01
    ld [arptim1], a
    ld hl, $4852
    ld a, l
    ld [arptabadr1], a
    ld a, h
    ld [arptabadr1+1], a
    ld a, $01
    ld [combtim1], a
    ld hl, $4852
    ld a, l
    ld [combtabadr1], a
    ld a, h
    ld [combtabadr1+1], a
    ld a, $01
    ld [notelen1], a
    ld [notelen2], a
    ld [notelen4], a
    ld hl, BlankPattern
    ld a, l
    ld [seqadr1], a
    ld [seqadr2], a
    ld [seqadr4], a
    ld a, h
    ld [seqadr1+1], a
    ld [seqadr2+1], a
    ld [seqadr4+1], a
    ld a, $77
    ldh [rNR50], a
    ld a, $FF
    ldh [rNR51], a
    ldh [rNR52], a
    ret

; ---------------------------------------------------------------------------
; E = id. Start the effect if the slot is free or its priority is >= the current one.
SoundFX::
    ld d, $00
    ld hl, SfxTable
    add hl, de
    add hl, de
    add hl, de
    ld a, [hli]
    ld [seqadre], a
    ld a, [hli]
    ld [seqadre+1], a
    ld a, [hli]
    cp a, $02
    jr nz, Sfx_UseCh4
    ld de, tempo2
    jr Sfx_SetChannel

Sfx_UseCh4:
    ld de, tempo4

Sfx_SetChannel:
    ld hl, noteechanadr
    ld [hl], e
    inc hl
    ld [hl], d
    ld a, $01
    ld [tempoe], a
    ld [notelene], a
    ld a, $00
    ld [effend], a
    ret
