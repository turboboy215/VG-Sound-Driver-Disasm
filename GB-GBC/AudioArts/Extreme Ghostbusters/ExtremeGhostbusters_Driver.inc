; Extreme Ghostbusters (E) (GBC) - driver code $4000-$48E1

Snd_Init::
    jp MusicInit

Snd_FX::
    jp SoundFX

; ---------------------------------------------------------------------------
; Called once per frame: each channel block, the ghost stepper, then the wave morph (if the build has one).
; Channel 1: count the tempo; when a tick is due count the note length; at 0 read the next event.
Musicd::
    ld hl, tempo1
    dec [hl]
    jr z, Ch1_TempoReload
    jp Ch1_Update

Ch1_TempoReload:
    ld a, [tempstor1]
    ld [hl], a
    inc l
    dec [hl]
    jr z, Ch1_NextEvent
    jp Ch1_Update

; ---------------------------------------------------------------------------
; Read the next pattern byte: $FF = song jump (word = step list), $00 = end of pattern.
Ch1_NextEvent:
    inc l
    ld e, [hl]
    inc l
    ld d, [hl]
    ld a, [de]
    cp a, $FF
    jr nz, Ch1_NotSongJump
    inc l
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
    ld hl, patadr1
    ld e, [hl]
    inc l
    ld d, [hl]
    dec l
    dec l

; ---------------------------------------------------------------------------
; Step = transpose, pattern number. Point seqadr at the pattern; its first byte is a length.
Ch1_LoadStep:
    ld a, [de]
    ld [hli], a
    inc de
    inc de
    ld a, [de]
    ld c, a
    inc de
    ld a, [de]
    inc de
    ld [hl], e
    inc l
    ld [hl], d
    ld e, c
    ld d, a
    ld hl, PatternTable
    add hl, de
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld a, [de]
    ld hl, seqadr1+1

; ---------------------------------------------------------------------------
; Store the length; the next byte is $FF hold, $FE key off, $FD key on, or a note.
Ch1_ReadLength:
    dec l
    dec l
    ld [hli], a
    inc de
    ld a, [de]
    cp a, $FF
    jr nz, Ch1_NotHold
    inc de
    ld [hl], e
    inc l
    ld [hl], d
    jp Ch1_Update

Ch1_NotHold:
    cp a, $FE
    jr nz, Ch1_NotKeyOff
    ld a, [note1de]
    ldh [rNR12], a
    inc de
    ld [hl], e
    inc l
    ld [hl], d
    ld a, $80
    ldh [rNR14], a
    jp Ch1_Update

Ch1_NotKeyOff:
    cp a, $FD
    jr nz, Ch1_Note
    ld a, $01
    ld [noterset1], a
    ld a, [note1at]
    ldh [rNR12], a
    inc de
    ld [hl], e
    inc l
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
    inc l
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
    ld [duty1], a
    inc de
    ld a, [de]
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
    ld [noterset1], a
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
    jp Ch2_Sequencer

; ---------------------------------------------------------------------------
; Every frame: retrigger if noterset, then walk the freq, arp and combine tables.
Ch1_Update:
    ld hl, noterset1
    ld a, [hl]
    cp a, $00
    jr z, Ch1_Tables
    xor a, a
    ld [hl], a
    ld a, [note1at]
    ldh [rNR12], a
    ld a, $80
    ldh [rNR14], a

Ch1_Tables:
    inc l
    ld a, [hli]
    ldh [rNR11], a
    ld e, l
    ld d, h
    inc l
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
    inc l
    ld a, b
    add a, [hl]
    ld [hli], a
    ld a, e
    adc a, [hl]
    ld [hli], a
    ld e, l
    ld d, h
    inc l
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
    inc l
    ld e, l
    ld d, h
    inc l
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
    inc l
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
    dec [hl]
    jr z, Ch2_SfxTempo
    inc l
    jp Ch2_Update

Ch2_SfxTempo:
    ld a, $01
    jr Ch2_CountLength

Ch2_MusicTempo:
    ld hl, tempo2
    dec [hl]
    jr z, Ch2_TempoReload
    inc l
    jp Ch2_Update

Ch2_TempoReload:
    ld a, [tempstor2]

Ch2_CountLength:
    ld [hl], a
    inc l
    dec [hl]
    jr z, Ch2_NextEvent
    jp Ch2_Update

Ch2_NextEvent:
    inc l
    ld e, [hl]
    inc l
    ld d, [hl]
    ld a, [de]
    cp a, $FF
    jr nz, Ch2_NotSongJump
    inc l
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
    inc de
    inc de
    ld a, [de]
    cp a, $00
    jr z, Ch2_SfxEnd
    ld hl, seqadre+1
    ld [hld], a
    ld c, a
    dec de
    ld a, [de]
    ld [hld], a
    ld e, a
    ld d, c
    ld a, [de]
    jr Ch2_StoreLength

; ---------------------------------------------------------------------------
; SFX end ($00 + word, high byte 0): mute the channel and free the slot next frame.
Ch2_SfxEnd:
    ld a, $FF
    ld [effend], a
    ld a, $01
    ld [note2at], a
    ld [note2de], a
    jp Ch2_Update

Ch2_NextStep:
    inc l
    inc l
    ld e, [hl]
    inc l
    ld d, [hl]
    dec l
    dec l

Ch2_LoadStep:
    ld a, [de]
    ld [hli], a
    inc de
    inc de
    ld a, [de]
    ld c, a
    inc de
    ld a, [de]
    inc de
    ld [hl], e
    inc l
    ld [hl], d
    ld e, c
    ld d, a
    ld hl, PatternTable
    add hl, de
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld a, [de]
    ld hl, seqadr2+1

Ch2_ReadLength:
    dec l
    dec l

Ch2_StoreLength:
    ld [hli], a
    inc de
    ld a, [de]
    cp a, $FF
    jr nz, Ch2_NotHold
    inc de
    ld [hl], e
    inc l
    ld [hl], d
    jp Ch2_Update

Ch2_NotHold:
    cp a, $FE
    jr nz, Ch2_NotKeyOff
    ld a, [note2de]
    ldh [rNR22], a
    inc de
    ld [hl], e
    inc l
    ld [hl], d
    ld a, $80
    ldh [rNR24], a
    jp Ch2_Update

Ch2_NotKeyOff:
    cp a, $FD
    jr nz, Ch2_Note
    ld a, $01
    ld [noterset2], a
    ld a, [note2at]
    ldh [rNR22], a
    inc de
    ld [hl], e
    inc l
    ld [hl], d
    jp Ch2_Update

Ch2_Note:
    inc de
    ld b, a
    ld a, [noteechanadr]
    cp a, LOW(tempo2)
    jr nz, Ch2_Transpose
    xor a, a
    jp Ch2_AddTranspose

Ch2_Transpose:
    ld a, [transp2]

Ch2_AddTranspose:
    add a, b
    ld [note2], a
    ld a, [de]
    inc de
    ld [hl], e
    inc l
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
    ld [duty2], a
    inc de
    ld a, [de]
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
    ld [noterset2], a
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
    jp Ch3_Sequencer

Ch2_Update:
    ld hl, noterset2
    ld a, [hl]
    cp a, $00
    jr z, Ch2_Tables
    xor a, a
    ld [hl], a
    ld a, [note2at]
    ldh [rNR22], a
    ld a, $80
    ldh [rNR24], a

Ch2_Tables:
    inc l
    ld a, [hli]
    ldh [rNR21], a
    ld e, l
    ld d, h
    inc l
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
    inc l
    ld a, b
    add a, [hl]
    ld [hli], a
    ld a, c
    adc a, [hl]
    ld [hli], a
    ld e, l
    ld d, h
    inc l
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
    inc l
    ld e, l
    ld d, h
    inc l
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
    inc l
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
; Channel 3 (wave). Key off switches to the release volume table.
Ch3_Sequencer:
    ld hl, tempo3
    dec [hl]
    jr z, Ch3_TempoReload
    jp Ch3_Update

Ch3_TempoReload:
    ld a, [tempstor3]
    ld [hl], a
    inc l
    dec [hl]
    jr z, Ch3_NextEvent
    jp Ch3_Update

Ch3_NextEvent:
    inc l
    ld e, [hl]
    inc l
    ld d, [hl]
    ld a, [de]
    cp a, $FF
    jr nz, Ch3_NotSongJump
    inc l
    inc de
    ld a, [de]
    ld b, a
    inc de
    ld a, [de]
    ld d, a
    ld a, b
    ld e, a
    jp Ch3_LoadStep

Ch3_NotSongJump:
    cp a, $00
    jr nz, Ch3_ReadLength
    ld hl, patadr3
    ld e, [hl]
    inc l
    ld d, [hl]
    dec l
    dec l

Ch3_LoadStep:
    ld a, [de]
    ld [hli], a
    inc de
    inc de
    ld a, [de]
    ld c, a
    inc de
    ld a, [de]
    inc de
    ld [hl], e
    inc l
    ld [hl], d
    ld e, c
    ld d, a
    ld hl, PatternTable
    add hl, de
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld a, [de]
    ld hl, seqadr3+1

Ch3_ReadLength:
    dec l
    dec l
    ld [hli], a
    inc de
    ld a, [de]
    cp a, $FF
    jr nz, Ch3_NotHold
    inc de
    ld [hl], e
    inc l
    ld [hl], d
    jp Ch3_Update

Ch3_NotHold:
    cp a, $FE
    jr nz, Ch3_Note
    inc de
    ld [hl], e
    inc l
    ld [hl], d
    ld a, $01
    ld [voltim3], a
    ld hl, voltabadr3
    ld de, volreladr3
    ld a, [de]
    ld [hli], a
    inc de
    ld a, [de]
    ld [hl], a
    jp Ch3_Update

Ch3_Note:
    inc de
    ld b, a
    ld a, [transp3]
    add a, b
    ld [note3], a
    ld a, [de]
    inc de
    ld [hl], e
    inc l
    ld [hl], d
    ld e, a
    ld d, $00
    ld hl, InstrumentTable
    add hl, de
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld a, $01
    ld [voltim3], a
    ld hl, voltabadr3
    ld a, [de]
    ld [hli], a
    inc de
    ld a, [de]
    ld [hli], a
    inc de
    ld a, [de]
    ld [hli], a
    inc de
    ld a, [de]
    ld [hli], a
    inc de
    ld hl, freqval3
    xor a, a
    ld [hli], a
    ld [hl], a
    inc a
    ld [freqtim3], a
    ld [arptim3], a
    ld [combtim3], a
    ld [voltim3], a
    ld hl, arptabadr3
    ld a, [de]
    inc de
    ld [hli], a
    ld a, [de]
    inc de
    ld [hl], a
    ld hl, freqtabadr3
    ld a, [de]
    inc de
    ld [hli], a
    ld a, [de]
    inc de
    ld [hl], a
    ld hl, combtabadr3
    ld a, [de]
    inc de
    ld [hli], a
    ld a, [de]
    inc de
    ld [hl], a
    jp Ch4_Sequencer

; ---------------------------------------------------------------------------
; Every frame: volume table -> NR32, then freq/arp/combine as on channel 1.
Ch3_Update:
    ld hl, voltim3
    ld e, l
    ld d, h
    inc l
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [de]
    dec a
    jr nz, Ch3_VolApply
    inc hl
    ld a, [hli]
    cp a, $00
    jr nz, Ch3_VolApply
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [hli]

Ch3_VolApply:
    ld [de], a
    ld a, l
    ld d, h
    ld e, [hl]
    ld hl, voltabadr3
    ld [hli], a
    ld [hl], d
    inc l
    ld a, e
    ldh [rNR32], a
    ld hl, freqtim3
    ld e, l
    ld d, h
    inc l
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [de]
    dec a
    jr nz, Ch3_FreqApply
    inc hl
    inc hl
    ld a, [hli]
    cp a, $00
    jr nz, Ch3_FreqApply
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [hli]

Ch3_FreqApply:
    ld [de], a
    ld a, l
    ld d, h
    ld b, [hl]
    inc hl
    ld c, [hl]
    ld hl, freqtabadr3
    ld [hli], a
    ld [hl], d
    inc l
    ld a, b
    add a, [hl]
    ld [hli], a
    ld a, c
    adc a, [hl]
    ld [hli], a
    ld e, l
    ld d, h
    inc l
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [de]
    dec a
    jr nz, Ch3_ArpApply
    inc hl
    ld a, [hli]
    cp a, $00
    jr nz, Ch3_ArpApply
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [hli]

Ch3_ArpApply:
    ld [de], a
    ld a, l
    ld d, h
    ld c, [hl]
    ld hl, arptabadr3
    ld [hli], a
    ld [hl], d
    inc l
    ld e, l
    ld d, h
    inc l
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [de]
    dec a
    jr nz, Ch3_CombApply
    inc hl
    ld a, [hli]
    cp a, $00
    jr nz, Ch3_CombApply
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [hli]

Ch3_CombApply:
    ld [de], a
    ld a, l
    ld d, h
    ld e, [hl]
    ld hl, combtabadr3
    ld [hli], a
    ld [hl], d
    inc l
    ld b, e
    ld a, b
    cp a, $00
    jr nz, Ch3_NotePeriod
    ld d, $00
    ld e, d
    jr Ch3_AddFreqval

Ch3_NotePeriod:
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
    jr nz, Ch3_WritePeriod

Ch3_AddFreqval:
    ld hl, freqval3
    ld a, [hli]
    add a, e
    ld e, a
    ld a, [hl]
    adc a, d
    ld d, a

Ch3_WritePeriod:
    ld a, d
    and a, $07
    ldh [rNR34], a
    ld [wavefreqhi], a
    ld a, e
    ldh [rNR33], a
    ld [wavefreqlo], a
    ld a, $10
    ldh [rNR31], a

; ---------------------------------------------------------------------------
; Channel 4 (noise). Like channel 2 (SFX capable); the note value is ignored.
Ch4_Sequencer:
    ld a, [noteechanadr]
    cp a, LOW(tempo4)
    jr nz, Ch4_MusicTempo
    ld hl, tempoe
    dec [hl]
    jr z, Ch4_SfxTempo
    jp Ch4_Update

Ch4_SfxTempo:
    ld a, $01
    jr Ch4_CountLength

Ch4_MusicTempo:
    ld hl, tempo4
    dec [hl]
    jr z, Ch4_TempoReload
    jp Ch4_Update

Ch4_TempoReload:
    ld a, [tempstor4]

Ch4_CountLength:
    ld [hl], a
    inc l
    dec [hl]
    jr z, Ch4_NextEvent
    jp Ch4_Update

Ch4_NextEvent:
    inc l
    ld e, [hl]
    inc l
    ld d, [hl]
    ld a, [de]
    cp a, $FF
    jr nz, Ch4_NotSongJump
    inc l
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
    inc de
    inc de
    ld a, [de]
    cp a, $00
    jr z, Ch4_SfxEnd
    ld hl, seqadre+1
    ld [hld], a
    ld c, a
    dec de
    ld a, [de]
    ld [hld], a
    ld e, a
    ld d, c
    ld a, [de]
    jr Ch4_StoreLength

Ch4_SfxEnd:
    ld a, $FF
    ld [effend], a
    ld a, $01
    ld [note4at], a
    ld [note4de], a
    jp Ch4_Update

Ch4_NextStep:
    inc l
    inc l
    ld e, [hl]
    inc l
    ld d, [hl]
    dec l
    dec l

Ch4_LoadStep:
    ld a, [de]
    ld [hli], a
    inc de
    inc de
    ld a, [de]
    ld c, a
    inc de
    ld a, [de]
    inc de
    ld [hl], e
    inc l
    ld [hl], d
    ld e, c
    ld d, a
    ld hl, PatternTable
    add hl, de
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld a, [de]
    ld hl, seqadr4+1

Ch4_ReadLength:
    dec l
    dec l

Ch4_StoreLength:
    ld [hli], a
    inc de
    ld a, [de]
    cp a, $FF
    jr nz, Ch4_NotHold
    inc de
    ld [hl], e
    inc l
    ld [hl], d
    jp Ch4_Update

Ch4_NotHold:
    cp a, $FE
    jr nz, Ch4_NotKeyOff
    ld a, [note4de]
    ldh [rNR42], a
    ld a, $80
    ldh [rNR44], a
    inc de
    ld [hl], e
    inc l
    ld [hl], d
    jp Ghost_Step

Ch4_NotKeyOff:
    cp a, $FD
    jr nz, Ch4_Note
    ld a, $01
    ld [noterset4], a
    inc de
    ld [hl], e
    inc l
    ld [hl], d
    jp Ghost_Step

Ch4_Note:
    inc de
    ld b, a
    ld a, [noteechanadr]
    cp a, LOW(tempo4)
    jr nz, Ch4_Transpose
    xor a, a
    jp Ch4_AddTranspose

Ch4_Transpose:
    ld a, [transp4]

Ch4_AddTranspose:
    add a, b
    ld a, [de]
    inc de
    ld [hl], e
    inc l
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
    ld [note4at], a
    inc de
    ld a, [de]
    ld [note4de], a
    inc de
    ld a, $01
    ld [noisetim4], a
    ld [noise2tim4], a
    ld [noterset4], a
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
    jp Ghost_Step

; ---------------------------------------------------------------------------
; Every frame: noise table -> NR43, second table -> NR44.
Ch4_Update:
    ld hl, noterset4
    ld a, [hl]
    cp a, $00
    jr z, Ch4_Tables
    xor a, a
    ld [hl], a
    ld a, [note4at]
    ldh [rNR42], a
    ld a, $80
    ldh [rNR44], a

Ch4_Tables:
    ldh [rNR41], a
    inc l
    ld e, l
    ld d, h
    inc l
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
    inc l
    ld a, c
    ldh [rNR43], a
    ld e, l
    ld d, h
    inc l
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
    jp Sfx_FreeSlot

Ghost_TempoReload:
    ld a, [noteechanadr]
    cp a, LOW(tempo2)
    jr nz, Ghost_Ch4Tempo
    ld a, [tempstor2]
    jr Ghost_CountLength

Ghost_Ch4Tempo:
    ld a, [tempstor4]

Ghost_CountLength:
    ld [hl], a
    inc l
    dec [hl]
    jr z, Ghost_NextEvent
    jp Sfx_FreeSlot

Ghost_NextEvent:
    inc l
    ld e, [hl]
    inc l
    ld d, [hl]
    ld a, [de]
    cp a, $FF
    jr nz, Ghost_NotSongJump
    inc l
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
    inc l
    inc l
    ld e, [hl]
    inc l
    ld d, [hl]
    dec l
    dec l

Ghost_LoadStep:
    ld a, [de]
    ld [hl], a
    inc de
    inc de
    ld a, [de]
    ld c, a
    inc de
    ld a, [de]
    inc de
    inc l
    ld [hl], e
    inc l
    ld [hl], d
    ld e, c
    ld d, a
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
    inc e
    ld a, [hl]
    ld [de], a
    dec de
    ld l, e
    ld h, d
    ld e, [hl]
    inc l
    ld d, [hl]
    ld a, [de]

Ghost_ReadLength:
    dec l
    dec l
    ld [hli], a
    inc de
    ld a, [de]
    cp a, $FF
    jr nz, Ghost_NotHold
    inc de
    ld [hl], e
    inc l
    ld [hl], d
    jp Sfx_FreeSlot

Ghost_NotHold:
    cp a, $FE
    jr nz, Ghost_NotKeyOff
    inc de
    ld [hl], e
    inc l
    ld [hl], d
    jp Sfx_FreeSlot

Ghost_NotKeyOff:
    cp a, $FD
    jr nz, Ghost_Note
    inc de
    ld [hl], e
    inc l
    ld [hl], d
    jp Sfx_FreeSlot

Ghost_Note:
    inc de
    ld b, a
    add a, b
    ld a, [de]
    inc de
    ld [hl], e
    inc l
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
    jr nz, Morph_Step
    ld [noteechanadr], a

; ---------------------------------------------------------------------------
; Wave morph table (frames, wave RAM register, value): write one wave byte and restart ch3.
Morph_Step:
    ld hl, morphtim
    ld e, l
    ld d, h
    inc l
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [de]
    dec a
    jr z, Morph_NextEntry
    ld [de], a
    jr Musicd_Done

Morph_NextEntry:
    inc hl
    inc hl
    ld a, [hli]
    cp a, $00
    jr nz, Morph_Write
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld a, [hli]

Morph_Write:
    ld [de], a
    ld a, l
    ld d, h
    ld c, [hl]
    inc hl
    ld b, [hl]
    ld hl, morphadr
    ld [hli], a
    ld [hl], d
    inc l
    ld a, $FF
    ld h, a
    ld l, c
    xor a, a
    ldh [rNR30], a
    ld a, b
    ld [hl], a
    ld a, $80
    ldh [rNR30], a
    ld a, [wavefreqhi]
    xor a, $80
    ldh [rNR34], a
    ld a, [wavefreqlo]
    ldh [rNR33], a

Musicd_Done:
    ret

; ---------------------------------------------------------------------------
; E = song. Load the song entry, reset the channels it uses, copy the wave to wave RAM.
MusicInit:
    ld hl, SongTable
    ld d, $00
    add hl, de
    add hl, de
    add hl, de
    add hl, de
    add hl, de
    add hl, de
    add hl, de
    add hl, de
    add hl, de
    add hl, de
    add hl, de
    add hl, de
    add hl, de
    add hl, de
    ld a, [hli]
    ld c, a
    ld a, [hli]
    ld b, a
    and a, $01
    cp a, $00
    jr z, Init_Ch2
    ld a, [hli]
    ld [patadr1], a
    ld a, [hli]
    ld [patadr1+1], a
    xor a, a
    ld [note1at], a
    ld [freqval1], a
    ld [freqval1+1], a
    inc a
    ld [freqtim1], a
    ld [noterset1], a
    ld [notelen1], a
    ld [tempo1], a
    ld a, LOW(BlankPattern)
    ld [seqadr1], a
    ld a, HIGH(BlankPattern)
    ld [seqadr1+1], a
    ld a, c
    ld [tempstor1], a

Init_Ch2:
    ld a, b
    and a, $02
    cp a, $00
    jr z, Init_Ch3
    ld a, [hli]
    ld [patadr2], a
    ld a, [hli]
    ld [patadr2+1], a
    xor a, a
    ld [note2at], a
    inc a
    ld [notelen2], a
    ld [noterset2], a
    ld [tempo2], a
    ld a, LOW(BlankPattern)
    ld [seqadr2], a
    ld a, HIGH(BlankPattern)
    ld [seqadr2+1], a
    ld a, c
    ld [tempstor2], a

Init_Ch3:
    ld a, b
    and a, $04
    cp a, $00
    jr z, Init_Ch4
    ld a, [hli]
    ld [patadr3], a
    ld a, [hli]
    ld [patadr3+1], a
    ld a, LOW(BlankPattern)
    ld [seqadr3], a
    ld a, HIGH(BlankPattern)
    ld [seqadr3+1], a
    ld a, $01
    ld [notelen3], a
    ld [tempo3], a
    ld a, c
    ld [tempstor3], a

Init_Ch4:
    ld a, b
    and a, $08
    cp a, $00
    jr z, Init_Wave
    ld a, [hli]
    ld [patadr4], a
    ld a, [hli]
    ld [patadr4+1], a
    xor a, a
    ld [note4at], a
    inc a
    ld [tempo4], a
    ld [noterset4], a
    ld [notelen4], a
    ld a, LOW(BlankPattern)
    ld [seqadr4], a
    ld a, HIGH(BlankPattern)
    ld [seqadr4+1], a
    ld a, c
    ld [tempstor4], a

Init_Wave:
    ld a, b
    and a, $04
    cp a, $00
    jr z, Init_Mixer
    ld a, [hli]
    ld [morphadr], a
    ld a, [hli]
    ld [morphadr+1], a
    xor a, a
    ldh [rNR30], a
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ld de, _AUD3WAVERAM

Init_WaveCopy:
    ld a, [hli]
    ld [de], a
    inc e
    ld a, e
    cp a, $40
    jr nz, Init_WaveCopy
    ld a, $FF
    ldh [rNR52], a
    ld a, $80
    ldh [rNR30], a
    ld a, $10
    ldh [rNR31], a
    xor a, a
    ldh [rNR32], a
    dec a
    ld [noteechanadr], a
    ld a, $80
    ldh [rNR34], a
    ld a, $01
    ld [morphtim], a
    inc a
    ld [voltim3], a
    ld hl, voltabadr3
    ld de, $48F8
    ld a, e
    ld [hli], a
    ld a, d
    ld [hl], a

Init_Mixer:
    ld a, $77
    ldh [rNR50], a
    ld a, $FF
    ldh [rNR51], a
    ldh [rNR52], a
    ld a, $01
    ldh [rNR44], a
    ldh [rNR42], a
    ret

; ---------------------------------------------------------------------------
; E = id. Start the effect if the slot is free or its priority is >= the current one.
SoundFX:
    ld d, $00
    ld hl, SfxTable
    add hl, de
    add hl, de
    add hl, de
    add hl, de
    ld a, [noteechanadr]
    cp a, LOW(noteechanadr)
    jr z, Sfx_Start
    ld a, [effprio]
    dec a
    sub a, [hl]
    and a, $80
    jr z, Sfx_Done

Sfx_Start:
    ld a, [hli]
    ld [effprio], a
    ld a, [noteechanadr]
    cp a, LOW(tempo2)
    jr nz, Sfx_MuteCh4
    ld a, $01
    ld [noterset2], a
    ld [note2at], a
    jr Sfx_SetPattern

Sfx_MuteCh4:
    cp a, LOW(tempo4)
    jr nz, Sfx_SetPattern
    ld a, $01
    ld [noterset4], a
    ld [note4at], a

Sfx_SetPattern:
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
    xor a, a
    ld [effend], a

Sfx_Done:
    ret
