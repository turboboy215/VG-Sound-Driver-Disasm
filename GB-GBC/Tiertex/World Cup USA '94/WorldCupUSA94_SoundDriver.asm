; =============================================================================
; World Cup USA '94 (Game Boy) - sound driver
; ROM: "World Cup USA '94 (UE) (M8) [!].gb"  (MBC1+RAM+BATTERY, 256 KB)
;
; Bank 0  $0F24-$0FB5   public API: PlayMusic, StopMusic, PlaySfx
; Bank 3  $4000-$4674   driver code
;         $4675-$573D   tables, instruments, music streams, SFX table
; Tick    SndUpdate (3:$40A1) + SndUpdateSfx (3:$462A) are called from the
;         STAT interrupt ($11C3, LYC=$50) once per frame. SndUpdate skips every
;         6th call, so music runs at 50 ticks/s; SFX run at 60 ticks/s.
;
; Rebuild check (RGBDS 0.9.1):
;   rgbasm -o snd.o WorldCupUSA94_SoundDriver.asm
;   rgblink -p 0xFF -o snd.gb snd.o
;   -> 0:$0F24-$0FB5 and 3:$4000-$573D match the original ROM byte for byte.
; =============================================================================

INCLUDE "hardware.inc"

DEF hCurROMBank EQU $FF8D   ; game keeps the current ROMX bank here; rst $08 switches bank

; ------------------------------- WRAM ----------------------------------------
DEF wSfxActive   EQU $D480  ; 1 while an SFX plays on CH1
DEF wSfxIdX2     EQU $D481  ; last SFX id * 2 (write-only)
DEF wSfxInsByte  EQU $D482  ; SFX instrument byte ($80|index)
DEF wSfxInsPtr   EQU $D483  ; 2 bytes
DEF wSfxVibIdx   EQU $D485  ; position in the instrument's period-delta table
DEF wSfxTimer    EQU $D486  ; ticks left
DEF wSfxFreq     EQU $D487  ; 2 bytes, current CH1 period
DEF wMusicOn     EQU $D489  ; nonzero = music playing
DEF wSongX2      EQU $D48A  ; song index * 2
DEF wTickDiv     EQU $D48B  ; 0-5 frame counter, tick skipped when it reaches 6

; Per-channel block, $12 bytes each: CH1 $D48C, CH2 $D49E, CH3 $D4B0, CH4 $D4C2
;  +$00 Ptr (2)      stream read pointer
;  +$02 Note         current note byte (0 = rest; vibrato only runs if nonzero)
;  +$03 Freq (2)     current period (CH1-3)
;  +$05 Wait         ticks until next event
;  +$06 InsByte      last instrument byte ($80-$BF)
;  +$07 InsPtr (2)   instrument record pointer
;  +$09 VibIdx       index into the instrument's period-delta table
;  +$0A Duty         instrument +5 copy (CH1/CH2, written but never read)
;  +$0B LoopCnt      FC/FD counter
;  +$0C LoopPtr (2)  FC/FD loop start
;  +$0E SubCnt       F9/F8 repeat counter
;  +$0F SubRet (2)   address of the F9 pointer operand (return = +2)
;  +$11 Transpose    F9 transpose, added to note bytes (ignored on CH4)
FOR CH, 1, 5
    DEF BASE = $D48C + (CH - 1) * $12
    DEF wCh{d:CH}Ptr       EQU BASE + $00
    DEF wCh{d:CH}Note      EQU BASE + $02
    DEF wCh{d:CH}Freq      EQU BASE + $03
    DEF wCh{d:CH}Wait      EQU BASE + $05
    DEF wCh{d:CH}InsByte   EQU BASE + $06
    DEF wCh{d:CH}InsPtr    EQU BASE + $07
    DEF wCh{d:CH}VibIdx    EQU BASE + $09
    DEF wCh{d:CH}Duty      EQU BASE + $0A
    DEF wCh{d:CH}LoopCnt   EQU BASE + $0B
    DEF wCh{d:CH}LoopPtr   EQU BASE + $0C
    DEF wCh{d:CH}SubCnt    EQU BASE + $0E
    DEF wCh{d:CH}SubRet    EQU BASE + $0F
    DEF wCh{d:CH}Transpose EQU BASE + $11
    PURGE BASE
ENDR

; --------------------------- stream macros -----------------------------------
; Byte     Args          Meaning
; $00      dur           rest: key-off (length 1 + retrigger), NRx2 = $01 (DAC off)
; $01-$7F  dur           note (CH1-3: period = FreqTable[note+transpose];
;                        CH4: drum = NoiseTable[note-1], transpose ignored)
; $80-$BF  -             select instrument (byte-$80); CH4 ignores it. Reads on.
; $F8      -             pattern return: --SubCnt; if nonzero replay the pattern,
;                        else continue after the F9 and clear transpose
; $F9      n, t, ptr     call pattern ptr, play it n times, transpose t (signed)
; $FC      n             loop start, n passes
; $FD      -             loop end: --LoopCnt; if nonzero jump back to loop start
; $FE      -             stop all music
; $FF      -             restart the song (all four channels)
; $C0-$F7, $FA, $FB      no-op, 1 byte ($ED is tested but also does nothing)
MACRO rest
    db $00, \1
ENDM
MACRO note
    db \1, \2
ENDM
MACRO instr
    db $80 + \1
ENDM
MACRO ret_pat
    db $F8
ENDM
MACRO call_pat
    db $F9, \1, LOW(\2)
    dw \3
ENDM
MACRO loop_start
    db $FC, \1
ENDM
MACRO loop_end
    db $FD
ENDM
MACRO music_stop
    db $FE
ENDM
MACRO song_restart
    db $FF
ENDM
MACRO cmd_nop
    db \1
ENDM


SECTION "Sound API", ROM0[$0F24]

; -----------------------------------------------------------------------------
; PlayMusic: start song A (0-8).
; Stores A*2, calls SndInitSong in bank 3, then sets wMusicOn. Also clears the
; sweep and sets 50% duty on CH1/CH2. Game calls: songs 1, 2, 3, 7, 8.
; Songs 0, 4, 5, 6 have no caller found in the ROM.
; -----------------------------------------------------------------------------
PlayMusic::
    add a
    ld [wSongX2], a                 ; song index * 2
    ldh a, [hCurROMBank]            ; save current ROM bank
    push af
    ld a, $03
    rst $08                         ; rst $08 = switch ROM bank to A
    call SndInitSong
    pop af
    rst $08                         ; restore bank
    ld a, $01
    ld [wMusicOn], a
    ld a, $00
    ldh [rNR10], a                  ; no sweep
    ld a, $80
    ldh [rNR11], a                  ; 50% duty
    ldh [rNR21], a
    ret

; -----------------------------------------------------------------------------
; StopMusic: clear wMusicOn and set NRx2 = 0 on all four channels (DAC off).
; -----------------------------------------------------------------------------
StopMusic::
    xor a
    ld [wMusicOn], a
    ldh [rNR12], a
    ldh [rNR22], a
    ldh [rNR32], a
    ldh [rNR42], a
    ld [wTickDiv], a                ; resets the tick divider
    ret

; -----------------------------------------------------------------------------
; PlaySfx: start sound effect A (0-6) on CH1.
; Refused (returns) if an SFX is already running OR music is playing, so SFX
; only sound while the music is stopped. There is no priority or queue.
; An SFX is one pulse instrument: start period from instrument +1/+2, duty +5,
; envelope +6, then SndUpdateSfx adds the instrument's period deltas each frame
; until the SfxTable duration runs out. NR10 (+4) is not written here.
; -----------------------------------------------------------------------------
PlaySfx::
    add a
    ld [wSfxIdX2], a
    ld hl, SfxTable                 ; hl = SfxTable + id*2 (read after the bank switch)
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [wSfxActive]
    and a
    ret nz                          ; SFX already running -> ignore

    ld a, [wMusicOn]
    and a
    ret nz                          ; music playing -> ignore

    ldh a, [hCurROMBank]
    push af
    ld a, $03
    rst $08
    ld a, [hl+]
    ld [wSfxInsByte], a             ; instrument byte ($80|n)
    ld a, [hl+]
    ld [wSfxTimer], a               ; duration in frames
    ld a, [wSfxInsByte]
    add a                           ; index * 2 (bit 7 drops out)
    ld hl, InstrumentTable
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [hl+]
    ld [wSfxInsPtr], a
    ld h, [hl]
    ld l, a
    ld a, h
    ld [wSfxInsPtr+1], a
    inc hl                          ; skip +0 (table length)
    ld a, [hl+]                     ; +1/+2: start period
    ld [wSfxFreq], a
    ld a, [hl+]
    ld [wSfxFreq+1], a
    ld a, [hl+]                     ; skip +3
    ld a, [hl+]                     ; skip +4 (NR10)
    ld a, [hl+]
    ldh [rNR11], a                  ; +5 -> NR11 (whole byte, incl. length bits)
    ld a, [hl+]
    ldh [rNR12], a                  ; +6 -> NR12
    ld a, [wSfxFreq]
    ldh [rNR13], a
    ld a, [wSfxFreq+1]
    or $80
    ldh [rNR14], a                  ; trigger
    xor a
    ld [wSfxVibIdx], a              ; restart the delta table
    ld a, $01
    ld [wSfxActive], a
    pop af
    rst $08
    ret


SECTION "Sound driver", ROMX[$4000], BANK[3]

; =============================================================================
; SndInitSong: load the four stream pointers for song wSongX2/2 and reset
; the per-channel wait, note and transpose (CH4 transpose is not cleared).
; Writes NR50/NR51/NR52 from the song tables, silences all channels and
; cancels any SFX. Loop/pattern counters and vibrato indexes are NOT reset.
; Also used by command $FF (restart song) from inside the tick.
; =============================================================================
SndInitSong::
    ld hl, SongTable_Ch1            ; CH1 stream pointer for this song
    ld a, [wSongX2]
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [hl+]
    ld [wCh1Ptr], a
    ld a, [hl+]
    ld [wCh1Ptr+1], a
    xor a
    ld [wCh1Wait], a
    ld [wCh1Note], a
    ld [wCh1Transpose], a
    ld hl, SongTable_Ch2            ; CH2
    ld a, [wSongX2]
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [hl+]
    ld [wCh2Ptr], a
    ld a, [hl+]
    ld [wCh2Ptr+1], a
    xor a
    ld [wCh2Wait], a
    ld [wCh2Note], a
    ld [wCh2Transpose], a
    ld hl, SongTable_Ch3            ; CH3
    ld a, [wSongX2]
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [hl+]
    ld [wCh3Ptr], a
    ld a, [hl+]
    ld [wCh3Ptr+1], a
    xor a
    ld [wCh3Wait], a
    ld [wCh3Note], a
    ld [wCh3Transpose], a
    ld hl, SongTable_Ch4            ; CH4
    ld a, [wSongX2]
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [hl+]
    ld [wCh4Ptr], a
    ld a, [hl+]
    ld [wCh4Ptr+1], a
    xor a
    ld [wCh4Wait], a
    ld [wCh4Note], a                ; CH4 transpose is not cleared
    ld a, [wSongX2]
    ld hl, SongTable_NR50_51        ; NR50 / NR51 per song
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [hl+]
    ldh [rNR50], a
    ld a, [hl+]
    ldh [rNR51], a
    ld a, [wSongX2]
    ld hl, SongTable_NR52           ; NR52 per song
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [hl+]
    ldh [rNR52], a
    ld a, [hl+]                     ; second byte read and discarded
    xor a
    ldh [rNR12], a
    ldh [rNR22], a
    ldh [rNR32], a
    ldh [rNR42], a
    ld [wSfxActive], a              ; cancel SFX
    ld [wTickDiv], a
    ret

; =============================================================================
; SndUpdate: music tick, called once per frame from the STAT ISR.
; Every 6th call is skipped (60 Hz -> 50 ticks/s). Channels are processed in
; the order CH1, CH2, CH3, CH4; if one of them hits $FE (stop) the rest are
; skipped for this tick.
; =============================================================================
SndUpdate::
    ld a, [wTickDiv]
    inc a
    ld [wTickDiv], a
    cp $06                          ; every 6th frame: no tick
    jr nz, .run
    xor a
    ld [wTickDiv], a
    ret

.run
    ld a, [wMusicOn]
    or a
    ret z

    call SndUpdateCh1
    ld a, [wMusicOn]
    and a
    call nz, SndUpdateCh2
    ld a, [wMusicOn]
    and a
    call nz, SndUpdateCh3
    ld a, [wMusicOn]
    and a
    call nz, SndUpdateCh4
    ret

; =============================================================================
; SndUpdateCh1 (pulse + sweep). CH2 and CH3 are copies of this routine.
; If the wait counter is still running and a note is sounding, apply one
; step of the instrument's period-delta table ("vibrato"/slide): the index
; advances 1,2..n-1,0,1.. and the signed delta is ADDED to the current
; period, so the table describes a cumulative pitch path. NRx4 is written
; without the trigger bit. When the wait reaches 0 the next event is read.
; =============================================================================
SndUpdateCh1:
    ld a, [wCh1Wait]
    and a
    jr z, .nextEvent
    dec a
    ld [wCh1Wait], a
    jr z, .nextEvent
    ld a, [wCh1Note]
    and a
    jr z, .done
    ld a, [wCh1InsPtr]              ; hl = instrument, [hl] = delta-table length
    ld l, a
    ld a, [wCh1InsPtr+1]
    ld h, a
    ld a, [wCh1VibIdx]
    inc a
    cp [hl]                         ; wrap at length
    jr nz, .vibWrap
    xor a
.vibWrap
    ld [wCh1VibIdx], a
    ld de, $0007                    ; deltas start at +7
    add hl, de
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld c, [hl]
    ld b, $00
    bit 7, c                        ; sign-extend delta into bc
    jr z, .vibPos
    dec b
.vibPos
    ld a, [wCh1Freq]
    add c
    ldh [rNR13], a
    ld [wCh1Freq], a
    ld a, [wCh1Freq+1]
    adc b
    and $07
    ldh [rNR14], a                  ; no trigger bit: pitch change only
    ld [wCh1Freq+1], a
.done
    ret

; Event reader. Loops over instrument bytes and commands until it reads a
; note or rest (which sets the wait and returns).
.nextEvent
    ld hl, wCh1Ptr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
.readByte
    ld a, [hl+]
    bit 7, a
    jr nz, .notNote
    and a                           ; 0 = rest
    jr nz, .noteOn
    ld [wCh1Note], a
    ld a, [hl+]                     ; duration
    ld [wCh1Wait], a
    ld a, l
    ld [wCh1Ptr], a
    ld a, h
    ld [wCh1Ptr+1], a
    ldh a, [rNR11]                  ; rest: length = 1 step ...
    or $3F
    ldh [rNR11], a
    ldh a, [rNR14]
    or $C0                          ; ... retrigger with length enabled -> cuts the note
    ldh [rNR14], a
    ld a, $01
    ldh [rNR12], a                  ; volume 0 (DAC off)
    ret

; Note: NR12 = instrument +6, period = FreqTable[note + transpose], trigger.
.noteOn
    ld [wCh1Note], a
    push hl
    ld hl, wCh1InsPtr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, $06                       ; instrument +6: envelope
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [hl]
    ldh [rNR12], a
    pop hl
    ld a, [hl+]                     ; duration
    ld [wCh1Wait], a
    ld a, l
    ld [wCh1Ptr], a
    ld a, h
    ld [wCh1Ptr+1], a
    ld a, [wCh1Note]
    ld hl, wCh1Transpose            ; note + transpose
    add [hl]
    ld hl, FreqTable                ; FreqTable
    add a                           ; 8-bit index * 2
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [hl+]
    ldh [rNR13], a
    ld [wCh1Freq], a
    ld a, [hl+]
    ld [wCh1Freq+1], a
    or $80
    ldh [rNR14], a
    ld a, $00
    ld [wCh1VibIdx], a
    ret

; $80-$BF: select instrument. Takes effect immediately (not at the next note):
; NR10 = +4, NR11 = +5 & $C0 (duty, length 0), NR12 = +6.
.notNote
    cp $C0
    jr nc, .command                 ; $C0+ -> command
    ld [wCh1InsByte], a
    add a
    ld de, InstrumentTable
    add e
    ld e, a
    adc d
    sub e
    ld d, a
    ld a, [de]
    ld [wCh1InsPtr], a
    ld c, a
    inc de
    ld a, [de]
    ld [wCh1InsPtr+1], a
    ld b, a
    inc de
    ld a, $04                       ; instrument +4
    add c
    ld c, a
    adc b
    sub c
    ld b, a
    ld a, [bc]
    ldh [rNR10], a                  ; +4 -> NR10 sweep
    inc bc
    ld a, [bc]
    ld [wCh1Duty], a                ; +5 copy, never read back
    and $C0
    ldh [rNR11], a                  ; +5 duty
    inc bc
    ld a, [bc]
    ldh [rNR12], a                  ; +6 envelope
    inc bc
    jp .readByte

; $C0-$FF commands. Anything not listed is skipped as a 1-byte no-op
; ($ED is compared but both outcomes continue the same way).
.command
    cp $FF
    jr z, .cmdRestart
    cp $FE
    jr z, .cmdStop
    cp $FD
    jr z, .cmdLoopEnd
    cp $FC
    jr z, .cmdLoopStart
    cp $F9
    jr z, .cmdCallPat
    cp $F8
    jr z, .cmdRetPat
    cp $ED                          ; no-op compare
    jp .readByte

; $FF: restart. Re-inits the whole song, then runs the CH1 update (from any
; channel). The channel that hit $FF starts again one tick later than CH1.
.cmdRestart
    call SndInitSong
    jp SndUpdateCh1

; $FE: stop all music.
.cmdStop
    xor a
    ld [wMusicOn], a
    ldh [rNR12], a
    ldh [rNR22], a
    ldh [rNR32], a
    ldh [rNR42], a
    ret

; $FC n: loop start. One loop level per channel.
.cmdLoopStart
    ld a, [hl+]
    ld [wCh1LoopCnt], a
    ld a, l
    ld [wCh1LoopPtr], a
    ld a, h
    ld [wCh1LoopPtr+1], a
    jp .readByte

; $FD: loop end. --count; nonzero -> back to the loop start.
.cmdLoopEnd
    ld a, [wCh1LoopCnt]
    dec a
    ld [wCh1LoopCnt], a
    jp z, .readByte
    ld hl, wCh1LoopPtr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    jp .readByte

; $F9 n, t, ptr: play pattern ptr n times with transpose t. Saves the address
; of ptr as the return point. One level only: patterns cannot call patterns.
.cmdCallPat
    ld a, [hl+]
    ld [wCh1SubCnt], a
    ld a, [hl+]
    ld [wCh1Transpose], a
    ld a, l
    ld [wCh1SubRet], a
    ld a, h
    ld [wCh1SubRet+1], a
    ld a, [hl+]                     ; jump to the pattern
    ld h, [hl]
    ld l, a
    jp .readByte

; $F8: pattern end. --count; nonzero -> replay the pattern, else resume
; after the $F9 and reset the transpose to 0.
.cmdRetPat
    ld a, [wCh1SubCnt]
    dec a
    ld [wCh1SubCnt], a
    jr nz, .repeatPat
    ld hl, wCh1SubRet
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    inc hl                          ; skip the 2-byte pointer
    inc hl
    xor a
    ld [wCh1Transpose], a
    jp .readByte

.repeatPat
    ld hl, wCh1SubRet
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, [hl+]                     ; re-read the pattern pointer
    ld h, [hl]
    ld l, a
    jp .readByte

; =============================================================================
; SndUpdateCh2 (pulse). Same as CH1 except: the instrument's NR10 byte is
; read and dropped, and the rest writes NR21/NR24 before reading the wait.
; =============================================================================
SndUpdateCh2:
    ld a, [wCh2Wait]
    and a
    jr z, .nextEvent
    dec a
    ld [wCh2Wait], a
    jr z, .nextEvent
    ld a, [wCh2Note]
    and a
    jr z, .done
    ld a, [wCh2InsPtr]
    ld l, a
    ld a, [wCh2InsPtr+1]
    ld h, a
    ld a, [wCh2VibIdx]
    inc a
    cp [hl]
    jr nz, .vibWrap
    xor a
.vibWrap
    ld [wCh2VibIdx], a
    ld de, $0007
    add hl, de
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld c, [hl]
    ld b, $00
    bit 7, c
    jr z, .vibPos
    dec b
.vibPos
    ld a, [wCh2Freq]
    add c
    ldh [rNR23], a
    ld [wCh2Freq], a
    ld a, [wCh2Freq+1]
    adc b
    and $07
    ldh [rNR24], a
    ld [wCh2Freq+1], a
.done
    ret

.nextEvent
    ld hl, wCh2Ptr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
.readByte
    ld a, [hl+]
    bit 7, a
    jr nz, .notNote
    and a
    jr nz, .noteOn
    ld [wCh2Note], a
    ldh a, [rNR21]
    or $3F
    ldh [rNR21], a
    ldh a, [rNR24]
    or $C0
    ldh [rNR24], a
    ld a, [hl+]
    ld [wCh2Wait], a
    ld a, l
    ld [wCh2Ptr], a
    ld a, h
    ld [wCh2Ptr+1], a
    ld a, $01
    ldh [rNR22], a
    ret

.noteOn
    ld [wCh2Note], a
    push hl
    ld hl, wCh2InsPtr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, $06
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [hl]
    ldh [rNR22], a
    pop hl
    ld a, [hl+]
    ld [wCh2Wait], a
    ld a, l
    ld [wCh2Ptr], a
    ld a, h
    ld [wCh2Ptr+1], a
    ld a, [wCh2Note]
    ld hl, wCh2Transpose
    add [hl]
    ld hl, FreqTable
    add a
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [hl+]
    ldh [rNR23], a
    ld [wCh2Freq], a
    ld a, [hl+]
    ld [wCh2Freq+1], a
    or $80
    ldh [rNR24], a
    ld a, $00
    ld [wCh2VibIdx], a
    ret

.notNote
    cp $C0
    jr nc, .command
    ld [wCh2InsByte], a
    add a
    ld de, InstrumentTable
    add e
    ld e, a
    adc d
    sub e
    ld d, a
    ld a, [de]
    ld [wCh2InsPtr], a
    ld c, a
    inc de
    ld a, [de]
    ld [wCh2InsPtr+1], a
    ld b, a
    inc de
    ld a, $04
    add c
    ld c, a
    adc b
    sub c
    ld b, a
    ld a, [bc]                      ; +4 read and dropped (no sweep on CH2)
    inc bc
    ld a, [bc]
    ld [wCh2Duty], a
    and $C0
    ldh [rNR21], a
    inc bc
    ld a, [bc]
    ldh [rNR22], a
    inc bc
    jp .readByte

.command
    cp $FF
    jr z, .cmdRestart
    cp $FE
    jr z, .cmdStop
    cp $FD
    jr z, .cmdLoopEnd
    cp $FC
    jr z, .cmdLoopStart
    cp $F9
    jr z, .cmdCallPat
    cp $F8
    jr z, .cmdRetPat
    cp $ED
    jp .readByte

.cmdRestart
    call SndInitSong
    jp SndUpdateCh1

.cmdStop
    xor a
    ld [wMusicOn], a
    ldh [rNR12], a
    ldh [rNR22], a
    ldh [rNR32], a
    ldh [rNR42], a
    ret

.cmdLoopStart
    ld a, [hl+]
    ld [wCh2LoopCnt], a
    ld a, l
    ld [wCh2LoopPtr], a
    ld a, h
    ld [wCh2LoopPtr+1], a
    jp .readByte

.cmdLoopEnd
    ld a, [wCh2LoopCnt]
    dec a
    ld [wCh2LoopCnt], a
    jp z, .readByte
    ld hl, wCh2LoopPtr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    jp .readByte

.cmdCallPat
    ld a, [hl+]
    ld [wCh2SubCnt], a
    ld a, [hl+]
    ld [wCh2Transpose], a
    ld a, l
    ld [wCh2SubRet], a
    ld a, h
    ld [wCh2SubRet+1], a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    jp .readByte

.cmdRetPat
    ld a, [wCh2SubCnt]
    dec a
    ld [wCh2SubCnt], a
    jr nz, .repeatPat
    ld hl, wCh2SubRet
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    inc hl
    inc hl
    xor a
    ld [wCh2Transpose], a
    jp .readByte

.repeatPat
    ld hl, wCh2SubRet
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    jp .readByte

; =============================================================================
; SndUpdateCh4 (noise). No vibrato and no instruments: $80-$BF bytes fall
; through to the command chain and are ignored. Note n = drum n, read from
; NoiseTable[n-1]; the transpose is stored by $F9 but never applied.
; =============================================================================
SndUpdateCh4:
    ld a, [wCh4Wait]
    and a
    jr z, .nextEvent
    dec a
    ld [wCh4Wait], a
    jr z, .nextEvent
    ret

.nextEvent
    ld hl, wCh4Ptr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
.readByte
    ld a, [hl+]
    bit 7, a
    jr nz, .command
    and a
    jr nz, .noteOn
    ld [wCh4Note], a
    ld a, [hl+]
    ld [wCh4Wait], a
    ld a, l
    ld [wCh4Ptr], a
    ld a, h
    ld [wCh4Ptr+1], a
    ld a, $01                       ; rest: CH4 volume 0 (no retrigger)
    ldh [rNR42], a
    ret

; Drum: NR43, NR42 from the table, NR41 = ctl & $3F, and trigger with
; NR44 = $C0 (length on) or $80 (ctl bit 6 set: length off).
.noteOn
    ld [wCh4Note], a
    ld a, [hl+]
    ld [wCh4Wait], a
    ld a, l
    ld [wCh4Ptr], a
    ld a, h
    ld [wCh4Ptr+1], a
    ld a, [wCh4Note]
    dec a                           ; (note - 1) * 3
    ld b, a
    add a
    add b
    ld hl, NoiseTable               ; NoiseTable
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [hl+]
    ldh [rNR43], a
    ld a, [hl+]
    ldh [rNR42], a
    ld a, [hl+]
    ld c, a
    and $3F
    ldh [rNR41], a
    ld a, c
    and $40
    ld c, a
    ld a, $C0                       ; bit 6 set -> $80, clear -> $C0
    xor c
    ldh [rNR44], a
    ret

.command
    cp $FF
    jr z, .cmdRestart
    cp $FE
    jr z, .cmdStop
    cp $FD
    jr z, .cmdLoopEnd
    cp $FC
    jr z, .cmdLoopStart
    cp $F9
    jr z, .cmdCallPat
    cp $F8
    jr z, .cmdRetPat
    cp $ED
    jp .readByte

.cmdRestart
    call SndInitSong
    jp SndUpdateCh1

.cmdStop
    xor a
    ld [wMusicOn], a
    ldh [rNR12], a
    ldh [rNR22], a
    ldh [rNR32], a
    ldh [rNR42], a
    ret

.cmdLoopStart
    ld a, [hl+]
    ld [wCh4LoopCnt], a
    ld a, l
    ld [wCh4LoopPtr], a
    ld a, h
    ld [wCh4LoopPtr+1], a
    jp .readByte

.cmdLoopEnd
    ld a, [wCh4LoopCnt]
    dec a
    ld [wCh4LoopCnt], a
    jp z, .readByte
    ld hl, wCh4LoopPtr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    jp .readByte

.cmdCallPat
    ld a, [hl+]
    ld [wCh4SubCnt], a
    ld a, [hl+]
    ld [wCh4Transpose], a
    ld a, l
    ld [wCh4SubRet], a
    ld a, h
    ld [wCh4SubRet+1], a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    jp .readByte

.cmdRetPat
    ld a, [wCh4SubCnt]
    dec a
    ld [wCh4SubCnt], a
    jr nz, .repeatPat
    ld hl, wCh4SubRet
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    inc hl
    inc hl
    xor a
    ld [wCh4Transpose], a
    jp .readByte

.repeatPat
    ld hl, wCh4SubRet
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    jp .readByte

; =============================================================================
; SndUpdateCh3 (wave). Same as CH1 but the period-delta table starts at
; instrument +$11 (after the 16 wave bytes).
; =============================================================================
SndUpdateCh3:
    ld a, [wCh3Wait]
    and a
    jr z, .nextEvent
    dec a
    ld [wCh3Wait], a
    jr z, .nextEvent
    ld a, [wCh3Note]
    and a
    jr z, .done
    ld a, [wCh3InsPtr]
    ld l, a
    ld a, [wCh3InsPtr+1]
    ld h, a
    ld a, [wCh3VibIdx]
    inc a
    cp [hl]
    jr nz, .vibWrap
    xor a
.vibWrap
    ld [wCh3VibIdx], a
    ld de, $0011                    ; deltas start at +$11 on wave instruments
    add hl, de
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld c, [hl]
    ld b, $00
    bit 7, c
    jr z, .vibPos
    dec b
.vibPos
    ld a, [wCh3Freq]
    add c
    ldh [rNR33], a
    ld [wCh3Freq], a
    ld a, [wCh3Freq+1]
    adc b
    and $07
    ldh [rNR34], a
    ld [wCh3Freq+1], a
.done
    ret

.nextEvent
    ld hl, wCh3Ptr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
.readByte
    ld a, [hl+]
    bit 7, a
    jr nz, .notNote
    and a
    jr nz, .noteOn
    ld [wCh3Note], a
    ldh a, [rNR31]                  ; rest: length = 1 step, level 0, retrigger
    or $FF
    ldh [rNR31], a
    ld a, $00
    ldh [rNR32], a
    ldh a, [rNR34]
    or $C0
    ldh [rNR34], a
    ld a, [hl+]
    ld [wCh3Wait], a
    ld a, l
    ld [wCh3Ptr], a
    ld a, h
    ld [wCh3Ptr+1], a
    ret

; Note: NR32 = $40 (50% level) always, NR30 = $80, period from FreqTable.
.noteOn
    ld [wCh3Note], a
    ld a, [hl+]
    ld [wCh3Wait], a
    ld a, l
    ld [wCh3Ptr], a
    ld a, h
    ld [wCh3Ptr+1], a
    ld a, [wCh3Note]
    ld hl, wCh3Transpose
    add [hl]
    ld hl, FreqTable
    add a
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, $40                       ; 50% output level
    ldh [rNR32], a
    ld a, $80                       ; wave DAC on
    ldh [rNR30], a
    ld a, [hl+]
    ldh [rNR33], a
    ld [wCh3Freq], a
    ld a, [hl+]
    ld [wCh3Freq+1], a
    or $80
    ldh [rNR34], a
    ld a, $00
    ld [wCh3VibIdx], a
    ret

; $80-$BF: copy the instrument's 16 wave bytes to wave RAM. The channel is not
; disabled first (NR30 stays on), which is unreliable on DMG hardware.
.notNote
    cp $C0
    jr nc, .command
    ld [wCh3InsByte], a
    add a
    ld de, InstrumentTable
    add e
    ld e, a
    adc d
    sub e
    ld d, a
    ld a, [de]
    ld [wCh3InsPtr], a
    ld c, a
    inc de
    ld a, [de]
    ld [wCh3InsPtr+1], a
    ld b, a
    inc bc                          ; skip +0, bc -> wave data
    push hl
    ld hl, _AUD3WAVERAM             ; wave RAM $FF30
    ld e, $10
.copyWave
    ld a, [bc]
    ld [hl+], a
    inc bc
    dec e
    jr nz, .copyWave
    pop hl
    jp .readByte

.command
    cp $FF
    jr z, .cmdRestart
    cp $FE
    jr z, .cmdStop
    cp $FD
    jr z, .cmdLoopEnd
    cp $FC
    jr z, .cmdLoopStart
    cp $F9
    jr z, .cmdCallPat
    cp $F8
    jr z, .cmdRetPat
    cp $ED
    jp .readByte

.cmdRestart
    call SndInitSong
    jp SndUpdateCh1

.cmdStop
    xor a
    ld [wMusicOn], a
    ldh [rNR12], a
    ldh [rNR22], a
    ldh [rNR32], a
    ldh [rNR42], a
    ret

.cmdLoopStart
    ld a, [hl+]
    ld [wCh3LoopCnt], a
    ld a, l
    ld [wCh3LoopPtr], a
    ld a, h
    ld [wCh3LoopPtr+1], a
    jp .readByte

.cmdLoopEnd
    ld a, [wCh3LoopCnt]
    dec a
    ld [wCh3LoopCnt], a
    jp z, .readByte
    ld hl, wCh3LoopPtr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    jp .readByte

.cmdCallPat
    ld a, [hl+]
    ld [wCh3SubCnt], a
    ld a, [hl+]
    ld [wCh3Transpose], a
    ld a, l
    ld [wCh3SubRet], a
    ld a, h
    ld [wCh3SubRet+1], a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    jp .readByte

.cmdRetPat
    ld a, [wCh3SubCnt]
    dec a
    ld [wCh3SubCnt], a
    jr nz, .repeatPat
    ld hl, wCh3SubRet
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    inc hl
    inc hl
    xor a
    ld [wCh3Transpose], a
    jp .readByte

.repeatPat
    ld hl, wCh3SubRet
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    jp .readByte

; =============================================================================
; SndUpdateSfx: SFX tick on CH1, every frame (60/s, not divided).
; While wSfxTimer > 0: decrement and apply one period-delta step, like the
; music vibrato. At 0: clear wSfxActive and set NR12 = 0.
; =============================================================================
SndUpdateSfx::
    ld a, [wSfxActive]
    and a
    ret z

    ld a, [wSfxTimer]               ; duration left?
    and a
    jr z, .end
    dec a
    ld [wSfxTimer], a
    ld hl, wSfxInsPtr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, [wSfxVibIdx]
    inc a
    cp [hl]
    jr nz, .vibWrap
    xor a
.vibWrap
    ld [wSfxVibIdx], a
    add $07                         ; deltas at +7
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld c, [hl]
    ld b, $00
    bit 7, c
    jr z, .vibPos
    dec b
.vibPos
    ld a, [wSfxFreq]
    add c
    ld [wSfxFreq], a
    ldh [rNR13], a
    ld a, [wSfxFreq+1]
    adc b
    and $07
    ld [wSfxFreq+1], a
    ldh [rNR14], a
    ret

.end
    xor a                           ; end: SFX off, CH1 silent
    ld [wSfxActive], a
    ldh [rNR12], a
    ret


; ============================ Tables ============================

SongTable_Ch1:  ; one stream pointer per song (index = song*2)
    dw Song0_Ch1     ; song 0
    dw Song1_Ch1     ; song 1
    dw Song2_Ch1     ; song 2
    dw Track_Silent  ; song 3
    dw Track_Silent  ; song 4
    dw Track_Silent  ; song 5
    dw Track_Silent  ; song 6
    dw Song7_Ch1     ; song 7
    dw Song8_Ch1     ; song 8
SongTable_Ch2:  ; one stream pointer per song (index = song*2)
    dw Song0_Ch2     ; song 0
    dw Song1_Ch2     ; song 1
    dw Song2_Ch2     ; song 2
    dw Track_Silent  ; song 3
    dw Track_Silent  ; song 4
    dw Track_Silent  ; song 5
    dw Track_Silent  ; song 6
    dw Song7_Ch2     ; song 7
    dw Song8_Ch2     ; song 8
SongTable_Ch3:  ; one stream pointer per song (index = song*2)
    dw Song0_Ch3     ; song 0
    dw Song1_Ch3     ; song 1
    dw Song2_Ch3     ; song 2
    dw Track_Silent  ; song 3
    dw Track_Silent  ; song 4
    dw Track_Silent  ; song 5
    dw Track_Silent  ; song 6
    dw Song7_Ch3     ; song 7
    dw Song8_Ch3     ; song 8
SongTable_Ch4:  ; one stream pointer per song (index = song*2)
    dw Song0_Ch4     ; song 0
    dw Song1_Ch4     ; song 1
    dw Track_Silent  ; song 2
    dw Song3_Ch4     ; song 3
    dw Song4_Ch4     ; song 4
    dw Song5_Ch4     ; song 5
    dw Song6_Ch4     ; song 6
    dw Song7_Ch4     ; song 7
    dw Track_Silent  ; song 8

SongTable_NR50_51:  ; NR50 (master volume), NR51 (panning) per song
    db $FF, $FF   ; song 0
    db $FF, $FF   ; song 1
    db $FF, $FF   ; song 2
    db $FF, $FF   ; song 3
    db $FF, $FF   ; song 4
    db $FF, $FF   ; song 5
    db $FF, $FF   ; song 6
    db $FF, $FF   ; song 7
    db $FF, $FF   ; song 8

SongTable_NR52:  ; NR52 value per song + one pad byte that is read and discarded
    db $8F, $00   ; song 0
    db $8F, $00   ; song 1
    db $8F, $00   ; song 2
    db $8F, $00   ; song 3
    db $8F, $00   ; song 4
    db $8F, $00   ; song 5
    db $8F, $00   ; song 6
    db $8F, $00   ; song 7
    db $8F, $00   ; song 8

; 103 GB period words, index = note byte + transpose. Entries 0-22 are 0 (unused),
; 23 = C2. Entry 24 ($056) is a data error: it should be C#2 (~$09D).
FreqTable:
    dw $0000   ;   0 $00  (0)
    dw $0000   ;   1 $01  (0)
    dw $0000   ;   2 $02  (0)
    dw $0000   ;   3 $03  (0)
    dw $0000   ;   4 $04  (0)
    dw $0000   ;   5 $05  (0)
    dw $0000   ;   6 $06  (0)
    dw $0000   ;   7 $07  (0)
    dw $0000   ;   8 $08  (0)
    dw $0000   ;   9 $09  (0)
    dw $0000   ;  10 $0A  (0)
    dw $0000   ;  11 $0B  (0)
    dw $0000   ;  12 $0C  (0)
    dw $0000   ;  13 $0D  (0)
    dw $0000   ;  14 $0E  (0)
    dw $0000   ;  15 $0F  (0)
    dw $0000   ;  16 $10  (0)
    dw $0000   ;  17 $11  (0)
    dw $0000   ;  18 $12  (0)
    dw $0000   ;  19 $13  (0)
    dw $0000   ;  20 $14  (0)
    dw $0000   ;  21 $15  (0)
    dw $0000   ;  22 $16  (0)
    dw $002C   ;  23 $17  C2 (65.4 Hz)
    dw $0056   ;  24 $18  C2 (66.8 Hz)
    dw $0106   ;  25 $19  D2 (73.4 Hz)
    dw $016B   ;  26 $1A  D#2 (77.8 Hz)
    dw $01C9   ;  27 $1B  E2 (82.4 Hz)
    dw $0223   ;  28 $1C  F2 (87.3 Hz)
    dw $0277   ;  29 $1D  F#2 (92.5 Hz)
    dw $02C6   ;  30 $1E  G2 (98.0 Hz)
    dw $0311   ;  31 $1F  G#2 (103.8 Hz)
    dw $0358   ;  32 $20  A2 (110.0 Hz)
    dw $039B   ;  33 $21  A#2 (116.5 Hz)
    dw $03DB   ;  34 $22  B2 (123.5 Hz)
    dw $0416   ;  35 $23  C3 (130.8 Hz)
    dw $0460   ;  36 $24  C#3 (141.2 Hz)
    dw $0484   ;  37 $25  D3 (146.9 Hz)
    dw $04B6   ;  38 $26  D#3 (155.7 Hz)
    dw $04E5   ;  39 $27  E3 (164.9 Hz)
    dw $0511   ;  40 $28  F3 (174.5 Hz)
    dw $053B   ;  41 $29  F#3 (184.9 Hz)
    dw $0563   ;  42 $2A  G3 (195.9 Hz)
    dw $0589   ;  43 $2B  G#3 (207.7 Hz)
    dw $05AC   ;  44 $2C  A3 (219.9 Hz)
    dw $05CE   ;  45 $2D  A#3 (233.2 Hz)
    dw $05ED   ;  46 $2E  B3 (246.8 Hz)
    dw $060B   ;  47 $2F  C4 (261.6 Hz)
    dw $0627   ;  48 $30  C#4 (277.1 Hz)
    dw $0641   ;  49 $31  D4 (293.2 Hz)
    dw $065A   ;  50 $32  D#4 (310.6 Hz)
    dw $0672   ;  51 $33  E4 (329.3 Hz)
    dw $0688   ;  52 $34  F4 (348.6 Hz)
    dw $069D   ;  53 $35  F#4 (369.2 Hz)
    dw $06B1   ;  54 $36  G4 (391.3 Hz)
    dw $06C4   ;  55 $37  G#4 (414.8 Hz)
    dw $06D6   ;  56 $38  A4 (439.8 Hz)
    dw $06E6   ;  57 $39  A#4 (464.8 Hz)
    dw $06F6   ;  58 $3A  B4 (492.8 Hz)
    dw $0705   ;  59 $3B  C5 (522.2 Hz)
    dw $0713   ;  60 $3C  C#5 (553.0 Hz)
    dw $0720   ;  61 $3D  D5 (585.1 Hz)
    dw $072D   ;  62 $3E  D#5 (621.2 Hz)
    dw $0739   ;  63 $3F  E5 (658.7 Hz)
    dw $0744   ;  64 $40  F5 (697.2 Hz)
    dw $074E   ;  65 $41  F#5 (736.4 Hz)
    dw $0758   ;  66 $42  G5 (780.2 Hz)
    dw $0762   ;  67 $43  G#5 (829.6 Hz)
    dw $076B   ;  68 $44  A5 (879.7 Hz)
    dw $0773   ;  69 $45  A#5 (929.6 Hz)
    dw $077B   ;  70 $46  B5 (985.5 Hz)
    dw $0782   ;  71 $47  C6 (1040.3 Hz)
    dw $0789   ;  72 $48  C#6 (1101.4 Hz)
    dw $0790   ;  73 $49  D6 (1170.3 Hz)
    dw $0796   ;  74 $4A  D#6 (1236.5 Hz)
    dw $079C   ;  75 $4B  E6 (1310.7 Hz)
    dw $07A2   ;  76 $4C  F6 (1394.4 Hz)
    dw $07A7   ;  77 $4D  F#6 (1472.7 Hz)
    dw $07AC   ;  78 $4E  G6 (1560.4 Hz)
    dw $07B1   ;  79 $4F  G#6 (1659.1 Hz)
    dw $07B5   ;  80 $50  A6 (1747.6 Hz)
    dw $07B9   ;  81 $51  A#6 (1846.1 Hz)
    dw $07BD   ;  82 $52  B6 (1956.3 Hz)
    dw $07C1   ;  83 $53  C7 (2080.5 Hz)
    dw $07C4   ;  84 $54  C#7 (2184.5 Hz)
    dw $07C8   ;  85 $55  D7 (2340.6 Hz)
    dw $07CB   ;  86 $56  D#7 (2473.1 Hz)
    dw $07CE   ;  87 $57  E7 (2621.4 Hz)
    dw $07D1   ;  88 $58  F7 (2788.8 Hz)
    dw $07D3   ;  89 $59  F#7 (2912.7 Hz)
    dw $07D6   ;  90 $5A  G7 (3120.8 Hz)
    dw $07D8   ;  91 $5B  G#7 (3276.8 Hz)
    dw $07DA   ;  92 $5C  A7 (3449.3 Hz)
    dw $07DC   ;  93 $5D  A#7 (3640.9 Hz)
    dw $07DE   ;  94 $5E  B7 (3855.1 Hz)
    dw $07DF   ;  95 $5F  B7 (3971.9 Hz)
    dw $07E2   ;  96 $60  C#8 (4369.1 Hz)
    dw $07E4   ;  97 $61  D8 (4681.1 Hz)
    dw $07E5   ;  98 $62  D#8 (4854.5 Hz)
    dw $07E7   ;  99 $63  E8 (5242.9 Hz)
    dw $07E8   ; 100 $64  F8 (5461.3 Hz)
    dw $07E9   ; 101 $65  F8 (5698.8 Hz)
    dw $07EB   ; 102 $66  G8 (6241.5 Hz)

; CH4 "drum" records, 3 bytes each; stream note n (1-16) uses entry n-1.
;   +0 NR43 (clock/LFSR), +1 NR42 (envelope),
;   +2 ctl: bits 0-5 -> NR41 length, bit 6 set -> NR44=$80 (no length), clear -> NR44=$C0
NoiseTable:
    db $A8, $C1, $32   ; drum 1
    db $34, $A1, $14   ; drum 2
    db $35, $0C, $40   ; drum 3
    db $35, $F7, $40   ; drum 4
    db $51, $0D, $40   ; drum 5
    db $55, $28, $40   ; drum 6
    db $45, $F7, $40   ; drum 7
    db $45, $0C, $40   ; drum 8
    db $51, $F7, $40   ; drum 9
    db $00, $0F, $00   ; drum 10
    db $00, $0F, $00   ; drum 11
    db $00, $0F, $00   ; drum 12
    db $00, $0F, $00   ; drum 13
    db $34, $21, $00   ; drum 14
    db $34, $41, $00   ; drum 15
    db $50, $45, $1E   ; drum 16

; 64 instrument pointers, selected by stream bytes $80-$BF (index = byte-$80).
; 1-19 are pulse (CH1/CH2 and SFX) records, 32-36 are wave (CH3) records. 0 = none.
InstrumentTable:
    dw 0       ; $80
    dw Ins01   ; $81
    dw Ins02   ; $82
    dw Ins03   ; $83
    dw Ins04   ; $84
    dw Ins05   ; $85
    dw Ins06   ; $86
    dw Ins07   ; $87
    dw 0       ; $88
    dw Ins09   ; $89
    dw Ins10   ; $8A
    dw Ins11   ; $8B
    dw Ins12   ; $8C
    dw Ins13   ; $8D
    dw Ins14   ; $8E
    dw Ins15   ; $8F
    dw Ins16   ; $90
    dw Ins17   ; $91
    dw Ins18   ; $92
    dw Ins19   ; $93
    dw 0       ; $94
    dw 0       ; $95
    dw 0       ; $96
    dw 0       ; $97
    dw 0       ; $98
    dw 0       ; $99
    dw 0       ; $9A
    dw 0       ; $9B
    dw 0       ; $9C
    dw 0       ; $9D
    dw 0       ; $9E
    dw 0       ; $9F
    dw Ins32   ; $A0
    dw Ins33   ; $A1
    dw Ins34   ; $A2
    dw Ins35   ; $A3
    dw Ins36   ; $A4
    dw 0       ; $A5
    dw 0       ; $A6
    dw 0       ; $A7
    dw 0       ; $A8
    dw 0       ; $A9
    dw 0       ; $AA
    dw 0       ; $AB
    dw 0       ; $AC
    dw 0       ; $AD
    dw 0       ; $AE
    dw 0       ; $AF
    dw 0       ; $B0
    dw 0       ; $B1
    dw 0       ; $B2
    dw 0       ; $B3
    dw 0       ; $B4
    dw 0       ; $B5
    dw 0       ; $B6
    dw 0       ; $B7
    dw 0       ; $B8
    dw 0       ; $B9
    dw 0       ; $BA
    dw 0       ; $BB
    dw 0       ; $BC
    dw 0       ; $BD
    dw 0       ; $BE
    dw 0       ; $BF

; Pulse instrument: +0 n = pitch-table length, +1/+2 start period (SFX only),
;   +3 unused, +4 NR10 (CH1 only), +5 NR11 duty (&$C0), +6 NR12 envelope,
;   +7.. n signed per-tick period deltas (cumulative; cycled 1,2..n-1,0,1..)
; Wave instrument: +0 n, +1..+16 wave RAM, +17.. n signed period deltas
Ins16:
    db 1   ; pitch-table length
    dw $012C   ; start period (SFX use only)
    db $FF   ; unused
    db $00, $C0, $61   ; NR10, NR11, NR12
    db -50   ; period deltas
Ins15:
    db 1   ; pitch-table length
    dw $0500   ; start period (SFX use only)
    db $FF   ; unused
    db $00, $80, $F1   ; NR10, NR11, NR12
    db -5   ; period deltas
Ins01:
    db 2   ; pitch-table length
    dw $07C0   ; start period (SFX use only)
    db $FF   ; unused
    db $00, $80, $FF   ; NR10, NR11, NR12
    db 5, -5   ; period deltas
Ins09:
    db 1   ; pitch-table length
    dw $0001   ; start period (SFX use only)
    db $01   ; unused
    db $00, $80, $B2   ; NR10, NR11, NR12
    db 0   ; period deltas
Ins18:
    db 1   ; pitch-table length
    dw $0001   ; start period (SFX use only)
    db $01   ; unused
    db $00, $80, $52   ; NR10, NR11, NR12
    db 0   ; period deltas
Ins10:
    db 1   ; pitch-table length
    dw $0001   ; start period (SFX use only)
    db $01   ; unused
    db $00, $80, $F1   ; NR10, NR11, NR12
    db 0   ; period deltas
Ins05:
    db 1   ; pitch-table length
    dw $0001   ; start period (SFX use only)
    db $01   ; unused
    db $00, $80, $F1   ; NR10, NR11, NR12
    db -99   ; period deltas
Ins12:
    db 1   ; pitch-table length
    dw $0001   ; start period (SFX use only)
    db $01   ; unused
    db $00, $80, $81   ; NR10, NR11, NR12
    db -99   ; period deltas
Ins11:
    db 1   ; pitch-table length
    dw $0001   ; start period (SFX use only)
    db $01   ; unused
    db $00, $80, $D1   ; NR10, NR11, NR12
    db 0   ; period deltas
Ins19:
    db 1   ; pitch-table length
    dw $0001   ; start period (SFX use only)
    db $01   ; unused
    db $00, $80, $51   ; NR10, NR11, NR12
    db 0   ; period deltas
Ins06:
    db 1   ; pitch-table length
    dw $0001   ; start period (SFX use only)
    db $01   ; unused
    db $00, $80, $F1   ; NR10, NR11, NR12
    db 0   ; period deltas
Ins13:
    db 1   ; pitch-table length
    dw $0001   ; start period (SFX use only)
    db $01   ; unused
    db $00, $80, $F2   ; NR10, NR11, NR12
    db 0   ; period deltas
Ins07:
    db 1   ; pitch-table length
    dw $0001   ; start period (SFX use only)
    db $01   ; unused
    db $00, $80, $01   ; NR10, NR11, NR12
    db 0   ; period deltas
Ins02:
    db 1   ; pitch-table length
    dw $0000   ; start period (SFX use only)
    db $01   ; unused
    db $00, $80, $F3   ; NR10, NR11, NR12
    db 0   ; period deltas
Ins03:
    db 1   ; pitch-table length
    dw $0064   ; start period (SFX use only)
    db $FF   ; unused
    db $00, $C0, $F1   ; NR10, NR11, NR12
    db -30   ; period deltas
Ins14:
    db 1   ; pitch-table length
    dw $012C   ; start period (SFX use only)
    db $FF   ; unused
    db $00, $C0, $81   ; NR10, NR11, NR12
    db -10   ; period deltas
Ins04:
    db 1   ; pitch-table length
    dw $0001   ; start period (SFX use only)
    db $FF   ; unused
    db $00, $C0, $B1   ; NR10, NR11, NR12
    db 0   ; period deltas
Ins17:
    db 1   ; pitch-table length
    dw $0001   ; start period (SFX use only)
    db $FF   ; unused
    db $00, $C0, $F1   ; NR10, NR11, NR12
    db 0   ; period deltas
Ins32:
    db 6   ; pitch-table length
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $11, $11, $11, $11, $11, $11, $11, $11   ; wave RAM
    db 0, 1, 0, 0, -1, 0   ; period deltas
Ins33:
    db 1   ; pitch-table length
    db $02, $48, $BD, $EF, $FF, $FE, $B8, $76, $66, $77, $88, $77, $65, $43, $21, $10   ; wave RAM
    db 0   ; period deltas
    db $FB, $05   ; unused leftover bytes
Ins34:
    db 6   ; pitch-table length
    db $02, $46, $8A, $CE, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $EC, $A8, $64, $20   ; wave RAM
    db 0, 1, 2, 0, -1, -2   ; period deltas
Ins36:
    db 1   ; pitch-table length
    db $F4, $C1, $96, $18, $B3, $E9, $1B, $9D, $62, $8F, $2E, $3D, $4C, $5B, $6A, $79   ; wave RAM
    db 0   ; period deltas
Ins35:
    db 8   ; pitch-table length
    db $8A, $BC, $DE, $FF, $FE, $CA, $85, $45, $8B, $CB, $86, $42, $00, $01, $34, $58   ; wave RAM
    db 0, 1, 1, 1, 0, -1, -1, -1   ; period deltas

; ============================ Music streams ============================
; Commands are macros (see top of file). Note bytes are freq-table indices before
; transpose; on CH4 they are drum numbers. Durations are in driver ticks (50/s).

Track_Silent:  ; also Song2_Ch4, Song3_Ch1, Song3_Ch2, Song3_Ch3, Song4_Ch1, Song4_Ch2, Song4_Ch3, Song5_Ch1, Song5_Ch2, Song5_Ch3, Song6_Ch1, Song6_Ch2, Song6_Ch3, Song8_Ch4
    loop_start 255
    call_pat 255, 0, Pat_4965
    loop_end

Pat_4965:
    rest 255
    ret_pat

Song0_Ch1:
    call_pat 7, -3, Pat_4A2F
    call_pat 1, 0, Pat_4D97
    call_pat 7, -3, Pat_4A2F
    call_pat 1, 0, Pat_4D97
    call_pat 1, 0, Pat_4D97
    call_pat 1, -3, Pat_4A2F
    call_pat 1, 0, Pat_4D97
    call_pat 1, -3, Pat_4A2F
    song_restart

Song0_Ch3:
    call_pat 1, 9, Pat_4B1F
    call_pat 1, 9, Pat_4B6B
    call_pat 1, 9, Pat_4D49
    call_pat 1, 9, Pat_4B1F
    call_pat 1, 9, Pat_4B6B
    call_pat 1, 9, Pat_4D03
    call_pat 1, 9, Pat_4BB7
    call_pat 1, 2, Pat_4D97
    call_pat 1, 9, Pat_4B1F
    call_pat 1, 9, Pat_4B6B
    call_pat 1, 9, Pat_4D49
    call_pat 1, 9, Pat_4B1F
    call_pat 1, 9, Pat_4B6B
    call_pat 1, 9, Pat_4D03
    call_pat 1, 9, Pat_4BB7
    call_pat 1, 2, Pat_4D97
    call_pat 2, 5, Pat_4D97
    call_pat 1, -3, Pat_4D97
    call_pat 1, 2, Pat_4D97
    song_restart

Song0_Ch2:
    call_pat 8, 0, Pat_4A79
    call_pat 8, 0, Pat_4A79
    call_pat 1, 0, Pat_4DBF
    call_pat 3, 0, Pat_4A79
    song_restart

Song0_Ch4:
    call_pat 7, 0, Pat_4D9C
    call_pat 1, 2, Pat_4D9C
    call_pat 7, 0, Pat_4D97
    call_pat 1, 2, Pat_4D9C
    call_pat 1, 0, Pat_4D9C
    call_pat 1, 0, Pat_4D97
    call_pat 1, 0, Pat_4D9C
    call_pat 1, 0, Pat_4D97
    song_restart

Pat_4A2F:
    instr 6
    note $22, 11
    note $22, 11
    note $25, 5
    note $22, 11
    note $22, 11
    note $22, 6
    note $25, 11
    note $25, 11
    note $22, 11
    note $22, 11
    note $22, 11
    note $25, 6
    note $22, 11
    note $25, 11
    note $25, 6
    note $25, 11
    note $27, 11
    note $29, 11
    note $22, 11
    note $22, 11
    note $25, 6
    note $22, 11
    note $22, 11
    note $22, 5
    note $25, 11
    note $25, 12
    note $22, 11
    note $22, 11
    note $25, 11
    note $25, 5
    note $22, 11
    note $25, 12
    note $25, 5
    note $25, 11
    note $24, 11
    note $23, 11
    ret_pat

Pat_4A79:
    instr 4
    note $18, 22
    instr 5
    note $29, 16
    instr 4
    note $18, 11
    note $18, 6
    note $18, 11
    instr 5
    note $29, 11
    instr 4
    note $18, 11
    note $18, 22
    instr 5
    note $29, 17
    instr 4
    note $18, 11
    note $18, 6
    instr 4
    note $18, 11
    instr 5
    note $29, 11
    instr 4
    note $18, 11
    note $18, 22
    instr 5
    note $29, 17
    instr 4
    note $18, 11
    note $18, 5
    note $18, 11
    instr 5
    note $29, 12
    instr 4
    note $18, 11
    note $18, 22
    instr 5
    note $29, 16
    instr 4
    note $18, 12
    note $18, 5
    instr 4
    note $18, 11
    instr 5
    note $29, 11
    instr 4
    note $18, 11
    ret_pat

; unreferenced: nothing in the ROM points at $4AC5-$4AFD
Unused_4AC5:
    note $01, 22
    note $02, 16
    note $01, 11
    note $01, 6
    note $01, 11
    note $02, 11
    note $01, 11
    note $01, 22
    note $02, 17
    note $01, 11
    note $01, 6
    note $01, 11
    note $02, 11
    note $01, 11
    note $01, 22
    note $02, 17
    note $01, 11
    note $01, 5
    note $01, 11
    note $02, 12
    note $01, 11
    note $01, 22
    note $02, 16
    note $01, 12
    note $01, 5
    note $01, 11
    note $02, 11
    note $01, 11
    ret_pat

; unreferenced: nothing in the ROM points at $4AFE-$4B1E
Unused_4AFE:
    note $01, 22
    note $01, 22
    note $01, 22
    note $01, 22
    note $01, 22
    note $01, 23
    note $01, 22
    note $01, 22
    note $01, 22
    note $01, 22
    note $01, 22
    note $01, 23
    note $01, 22
    note $01, 22
    note $01, 22
    note $01, 22
    ret_pat

Pat_4B1F:
    instr 32
    rest 11
    note $3A, 4
    rest 7
    note $3A, 3
    rest 2
    note $3A, 4
    rest 7
    note $3A, 5
    rest 6
    note $3C, 3
    rest 3
    note $3C, 4
    rest 7
    note $3C, 5
    rest 6
    note $38, 4
    rest 7
    note $38, 4
    rest 7
    note $3A, 4
    rest 7
    note $3C, 7
    note $3D, 4
    rest 7
    note $3A, 4
    rest 56
    note $3D, 4
    rest 7
    note $3C, 5
    rest 6
    note $3A, 5
    rest 6
    note $3C, 9
    rest 8
    note $38, 8
    rest 9
    note $35, 99
    ret_pat

Pat_4B6B:
    instr 32
    rest 11
    note $3A, 4
    rest 7
    note $3A, 3
    rest 2
    note $3A, 4
    rest 7
    note $3A, 5
    rest 6
    note $3C, 3
    rest 3
    note $3C, 4
    rest 7
    note $3C, 5
    rest 6
    note $38, 4
    rest 7
    note $38, 4
    rest 7
    note $3A, 4
    rest 7
    note $3C, 7
    note $3D, 4
    rest 7
    note $3A, 4
    rest 56
    note $3D, 4
    rest 7
    note $3C, 5
    rest 6
    note $3A, 5
    rest 6
    note $3C, 9
    rest 8
    note $38, 8
    rest 9
    note $3A, 99
    ret_pat

Pat_4BB7:
    instr 32
    note $46, 22
    note $41, 22
    note $42, 22
    note $41, 22
    note $3A, 22
    note $41, 23
    note $42, 22
    note $41, 22
    note $46, 22
    note $41, 22
    note $42, 22
    note $41, 23
    note $3A, 22
    note $41, 22
    note $42, 22
    note $41, 22
    ret_pat

; unreferenced: nothing in the ROM points at $4BD9-$4C5A
Unused_4BD9:
    instr 5
    note $2E, 5
    note $31, 6
    note $35, 5
    note $3A, 6
    note $3D, 5
    note $41, 6
    note $46, 5
    note $49, 6
    note $2E, 5
    note $31, 6
    note $35, 5
    note $3A, 6
    note $3D, 6
    note $41, 5
    note $46, 6
    note $49, 5
    note $2E, 6
    note $31, 5
    note $35, 6
    note $3A, 5
    note $3D, 6
    note $41, 5
    note $46, 6
    note $49, 6
    note $2E, 5
    note $31, 6
    note $35, 5
    note $3A, 6
    note $3D, 5
    note $41, 6
    note $46, 5
    note $49, 6
    note $2E, 5
    note $31, 6
    note $35, 6
    note $3A, 5
    note $3D, 6
    note $41, 5
    note $46, 6
    note $49, 5
    note $2E, 6
    note $31, 5
    note $35, 6
    note $3A, 5
    note $3D, 6
    note $41, 6
    note $46, 5
    note $49, 6
    note $2E, 5
    note $31, 6
    note $35, 5
    note $3A, 6
    note $3D, 5
    note $41, 6
    note $46, 5
    note $49, 6
    note $2E, 6
    note $31, 5
    note $35, 6
    note $3A, 5
    note $3D, 6
    note $41, 5
    note $46, 6
    note $49, 5
    ret_pat

; unreferenced: nothing in the ROM points at $4C5B-$4CEC
Unused_4C5B:
    instr 8
    note $32, 3
    rest 8
    note $35, 3
    rest 8
    note $35, 3
    rest 2
    note $32, 5
    rest 6
    note $32, 5
    rest 6
    note $32, 4
    rest 2
    note $35, 4
    rest 7
    note $35, 5
    rest 6
    note $32, 5
    rest 6
    note $32, 4
    rest 7
    note $35, 4
    rest 7
    note $35, 5
    rest 1
    note $32, 5
    rest 6
    note $32, 5
    rest 6
    note $32, 4
    rest 2
    note $35, 4
    rest 7
    note $35, 4
    rest 7
    note $32, 4
    rest 7
    note $32, 5
    rest 6
    note $35, 3
    rest 8
    note $35, 4
    rest 2
    note $32, 4
    rest 7
    note $32, 5
    rest 6
    note $32, 4
    rest 1
    note $35, 5
    rest 6
    note $35, 5
    rest 7
    note $32, 5
    rest 6
    note $32, 4
    rest 7
    note $35, 3
    rest 8
    note $35, 4
    rest 1
    note $32, 5
    rest 6
    note $32, 5
    rest 7
    note $32, 3
    rest 2
    note $35, 5
    rest 6
    note $35, 5
    rest 6
    note $32, 5
    rest 6
    ret_pat

; unreferenced: nothing in the ROM points at $4CED-$4D02
Unused_4CED:
    instr 5
    rest 255
    note $7F, 55
    note $30, 6
    note $30, 5
    note $30, 6
    note $30, 5
    note $30, 6
    note $30, 5
    note $30, 6
    note $30, 5
    ret_pat

Pat_4D03:
    instr 32
    note $3A, 3
    rest 19
    note $3A, 5
    rest 28
    note $46, 6
    rest 16
    note $3A, 3
    rest 8
    note $3A, 5
    rest 17
    note $3A, 7
    rest 16
    rest 5
    rest 11
    rest 6
    rest 11
    rest 5
    rest 6
    note $3A, 6
    rest 16
    note $3A, 5
    rest 28
    note $46, 8
    rest 15
    note $3A, 3
    rest 8
    note $3A, 5
    rest 33
    rest 6
    rest 6
    rest 11
    rest 5
    rest 11
    rest 11
    ret_pat

Pat_4D49:
    instr 32
    rest 11
    note $3A, 4
    rest 12
    note $38, 4
    rest 13
    note $3A, 5
    rest 11
    note $38, 5
    rest 12
    note $3A, 4
    rest 18
    note $3A, 4
    rest 13
    note $38, 4
    rest 13
    note $3A, 5
    rest 17
    note $3D, 33
    note $3A, 4
    rest 13
    note $38, 4
    rest 12
    note $3A, 5
    rest 12
    note $38, 5
    rest 12
    note $3A, 4
    rest 18
    note $3A, 4
    rest 12
    note $38, 5
    rest 12
    note $3A, 4
    rest 18
    rest 6
    rest 5
    rest 6
    rest 5
    ret_pat

Pat_4D97:
    rest 255
    rest 99
    ret_pat

Pat_4D9C:
    rest 11
    note $10, 22
    note $10, 22
    note $10, 22
    note $10, 22
    note $10, 22
    note $10, 23
    note $10, 22
    note $10, 22
    note $10, 22
    note $10, 22
    note $10, 23
    note $10, 22
    note $10, 22
    note $10, 22
    note $10, 22
    note $10, 11
    ret_pat

Pat_4DBF:
    instr 4
    note $19, 22
    note $19, 22
    note $19, 22
    note $19, 22
    note $19, 22
    note $19, 23
    note $19, 22
    note $19, 22
    note $19, 22
    note $19, 22
    note $19, 22
    note $19, 23
    note $19, 22
    note $19, 22
    note $19, 22
    note $19, 22
    ret_pat

Song1_Ch3:
    call_pat 1, 10, Pat_5074
    call_pat 1, 4, Pat_504C
    call_pat 1, 4, Pat_4F1E
    call_pat 1, 16, Pat_4F66
    call_pat 1, 4, Pat_502A
    call_pat 1, 5, Pat_4F1E
    call_pat 1, 17, Pat_4F66
    call_pat 1, 4, Pat_504C
    call_pat 1, 4, Pat_4FAE
    call_pat 1, 4, Pat_502A
    song_restart

Song1_Ch2:
    call_pat 1, 10, Pat_5068
    call_pat 1, 10, Pat_4E62
    call_pat 5, 10, Pat_4E62
    call_pat 2, 4, Pat_4FC0
    call_pat 1, 10, Pat_4E62
    song_restart

Song1_Ch1:
    call_pat 1, 10, Pat_5058
    call_pat 1, -8, Pat_4EB4
    call_pat 3, -8, Pat_4EB4
    call_pat 2, -7, Pat_4EB4
    call_pat 3, -8, Pat_4EB4
    song_restart

Song1_Ch4:
    call_pat 1, 0, Pat_513D
    call_pat 1, 0, Pat_507C
    call_pat 3, 0, Pat_507C
    call_pat 2, 0, Pat_507C
    call_pat 3, 0, Pat_507C
    song_restart

Pat_4E62:
    instr 4
    note $0E, 21
    instr 5
    note $27, 16
    instr 4
    note $0E, 5
    instr 4
    note $0E, 10
    instr 4
    note $0E, 11
    instr 5
    note $27, 21
    instr 4
    note $0E, 21
    instr 5
    note $27, 16
    instr 4
    note $0E, 6
    instr 4
    note $0E, 10
    instr 4
    note $0E, 11
    instr 5
    note $27, 10
    instr 5
    note $27, 6
    instr 5
    note $27, 5
    instr 4
    note $0E, 21
    instr 5
    note $27, 16
    instr 5
    note $27, 5
    instr 4
    note $0E, 11
    instr 4
    note $0E, 11
    instr 5
    note $27, 21
    instr 4
    note $0E, 21
    instr 5
    note $27, 16
    instr 4
    note $0E, 5
    instr 4
    note $0E, 11
    instr 4
    note $0E, 10
    instr 5
    note $27, 11
    instr 4
    note $0E, 9
    ret_pat

Pat_4EB4:
    instr 6
    note $26, 10
    note $26, 5
    note $26, 6
    note $26, 10
    note $26, 6
    note $26, 5
    note $26, 5
    note $26, 5
    note $26, 6
    note $26, 5
    note $26, 11
    note $26, 5
    note $26, 5
    note $26, 11
    note $26, 5
    note $26, 5
    note $26, 11
    note $26, 5
    note $26, 6
    note $26, 5
    note $26, 5
    note $26, 6
    note $26, 5
    note $26, 10
    note $26, 6
    note $26, 5
    note $26, 11
    note $26, 5
    note $26, 5
    note $26, 11
    note $26, 5
    note $26, 5
    note $26, 6
    note $26, 5
    note $26, 5
    note $26, 6
    note $26, 10
    note $26, 5
    note $26, 6
    note $26, 10
    note $26, 6
    note $26, 5
    note $26, 11
    note $26, 5
    note $26, 5
    note $26, 5
    note $26, 6
    note $26, 5
    note $26, 5
    note $26, 11
    note $26, 5
    note $26, 4
    ret_pat

Pat_4F1E:
    instr 32
    note $42, 4
    rest 6
    note $43, 6
    rest 5
    note $45, 6
    rest 4
    note $43, 21
    note $42, 6
    rest 5
    note $40, 5
    rest 6
    note $3E, 21
    note $40, 6
    rest 4
    note $42, 8
    rest 3
    note $40, 32
    note $39, 21
    note $42, 6
    rest 5
    note $43, 7
    rest 3
    note $45, 8
    rest 3
    note $43, 21
    note $42, 5
    rest 6
    note $40, 5
    rest 5
    note $3E, 21
    note $40, 8
    rest 3
    note $42, 6
    rest 5
    note $40, 51
    ret_pat

Pat_4F66:
    instr 32
    note $39, 4
    rest 6
    note $3B, 6
    rest 5
    note $3E, 6
    rest 4
    note $3B, 21
    note $39, 6
    rest 5
    note $37, 5
    rest 6
    note $36, 21
    note $37, 6
    rest 4
    note $39, 8
    rest 3
    note $37, 32
    note $34, 21
    note $39, 6
    rest 5
    note $3B, 7
    rest 3
    note $3E, 8
    rest 3
    note $3B, 21
    note $39, 5
    rest 6
    note $37, 5
    rest 5
    note $36, 21
    note $37, 8
    rest 3
    note $39, 6
    rest 5
    note $34, 51
    ret_pat

Pat_4FAE:
    instr 32
    note $36, 31
    note $34, 53
    note $32, 32
    note $34, 53
    note $36, 32
    note $34, 53
    note $32, 32
    note $34, 51
    ret_pat

Pat_4FC0:
    instr 11
    note $32, 5
    note $32, 5
    note $32, 11
    note $32, 10
    note $32, 6
    note $32, 5
    note $32, 5
    note $32, 5
    note $32, 11
    note $32, 11
    note $32, 5
    note $32, 5
    note $32, 6
    note $32, 5
    note $32, 10
    note $32, 11
    note $32, 5
    note $32, 6
    note $32, 5
    note $32, 5
    note $32, 6
    note $32, 5
    note $32, 5
    note $32, 5
    note $32, 6
    note $32, 5
    note $32, 5
    note $32, 6
    note $32, 10
    note $32, 11
    note $32, 5
    note $32, 5
    note $32, 6
    note $32, 5
    note $32, 11
    note $32, 10
    note $32, 5
    note $32, 6
    note $32, 5
    note $32, 5
    note $32, 11
    note $32, 11
    note $32, 5
    note $32, 5
    note $32, 5
    note $32, 6
    note $32, 5
    note $32, 5
    note $32, 6
    note $32, 5
    note $32, 5
    note $32, 4
    ret_pat

Pat_502A:
    instr 32
    note $39, 21
    note $42, 21
    note $39, 21
    note $42, 21
    note $37, 21
    note $40, 22
    note $3B, 21
    note $43, 21
    note $39, 21
    note $42, 21
    note $39, 22
    note $42, 21
    note $37, 21
    note $40, 21
    note $3B, 21
    note $43, 20
    ret_pat

Pat_504C:
    instr 32
    rest 255
    note $7F, 82
    ret_pat

; unreferenced: nothing in the ROM points at $5052-$5057
Unused_5052:
    instr 4
    rest 255
    note $7F, 82
    ret_pat

Pat_5058:
    instr 4
    note $0E, 21
    note $0E, 21
    note $0E, 21
    note $0E, 5
    note $0E, 6
    note $0E, 5
    note $0E, 5
    ret_pat

Pat_5068:
    rest 63
    instr 5
    note $27, 5
    note $27, 6
    note $27, 5
    note $27, 5
    ret_pat

Pat_5074:
    instr 32
    rest 84
    ret_pat

; unreferenced: nothing in the ROM points at $5078-$507B
Unused_5078:
    instr 5
    rest 84
    ret_pat

Pat_507C:
    note $10, 1
    rest 4
    note $10, 2
    rest 3
    note $10, 4
    rest 7
    note $10, 3
    rest 2
    note $10, 4
    rest 1
    note $10, 4
    rest 7
    note $10, 3
    rest 2
    note $10, 3
    rest 2
    note $10, 4
    rest 7
    note $10, 3
    rest 2
    note $10, 3
    rest 3
    note $10, 4
    rest 6
    note $10, 4
    rest 2
    note $10, 3
    rest 2
    note $10, 4
    rest 6
    note $10, 4
    rest 2
    note $10, 3
    rest 2
    note $10, 4
    rest 7
    note $10, 3
    rest 2
    note $10, 3
    rest 2
    note $10, 4
    rest 7
    note $10, 3
    rest 2
    note $10, 3
    rest 2
    note $10, 4
    rest 7
    note $10, 3
    rest 2
    note $10, 4
    rest 2
    note $10, 3
    rest 7
    note $10, 3
    rest 2
    note $10, 4
    rest 2
    note $10, 3
    rest 7
    note $10, 3
    rest 3
    note $10, 3
    rest 2
    note $10, 3
    rest 8
    note $10, 2
    rest 3
    note $10, 3
    rest 2
    note $10, 4
    rest 7
    note $10, 2
    rest 3
    note $10, 3
    rest 2
    note $10, 4
    rest 7
    note $10, 3
    rest 2
    note $10, 3
    rest 3
    note $10, 3
    rest 7
    note $10, 3
    rest 2
    note $10, 3
    rest 3
    note $10, 3
    rest 7
    note $10, 3
    rest 3
    note $10, 2
    rest 3
    note $10, 3
    rest 6
    ret_pat

Pat_513D:
    note $10, 3
    rest 18
    note $10, 4
    rest 17
    note $10, 4
    rest 17
    note $10, 4
    rest 16
    ret_pat

Song2_Ch3:
    call_pat 1, 5, Pat_5186
    music_stop

Song2_Ch2:
    call_pat 1, 0, Pat_5172
    music_stop

Song2_Ch1:
    call_pat 1, 5, Pat_5160
    music_stop

Pat_5160:
    instr 6
    note $1F, 7
    note $1D, 7
    note $1C, 7
    instr 13
    note $18, 22
    note $1A, 15
    instr 6
    note $1C, 7
    note $1C, 7
    ret_pat

Pat_5172:
    instr 4
    note $24, 7
    instr 5
    note $32, 7
    instr 4
    note $24, 7
    note $24, 22
    instr 5
    note $32, 15
    note $32, 7
    instr 4
    note $24, 7
    ret_pat

Pat_5186:
    instr 32
    note $43, 7
    note $41, 7
    note $40, 7
    note $3C, 22
    note $3E, 7
    rest 7
    note $40, 7
    note $40, 7
    note $32, 45
    ret_pat

Song3_Ch4:
    note $03, 100
    note $04, 150
    music_stop

Song4_Ch4:
    note $08, 10
    note $07, 100
    music_stop

Song5_Ch4:
    note $05, 15
    note $09, 150
    music_stop

Song6_Ch4:
    loop_start 255
    loop_start 255
    note $06, 255
    loop_end
    loop_end
    music_stop

Song7_Ch3:
    call_pat 4, 23, Pat_51CA
    song_restart

Song7_Ch4:
    call_pat 4, 0, Pat_5486
    song_restart

Song7_Ch2:
    call_pat 4, 30, Pat_540D
    song_restart

Song7_Ch1:
    call_pat 4, -1, Pat_53BE
    song_restart

Pat_51CA:
    instr 32
    note $2A, 3
    rest 3
    note $2A, 3
    rest 3
    note $2C, 3
    rest 3
    note $2C, 3
    rest 3
    note $31, 3
    rest 3
    note $31, 3
    rest 3
    note $2A, 3
    rest 3
    note $2A, 3
    rest 3
    note $2C, 3
    rest 3
    note $2C, 3
    rest 3
    note $31, 3
    rest 3
    note $31, 3
    rest 3
    note $2A, 3
    rest 3
    note $2A, 3
    rest 3
    note $2C, 3
    rest 3
    note $2C, 3
    rest 3
    note $31, 3
    rest 3
    note $31, 3
    rest 3
    note $2A, 3
    rest 3
    note $2A, 3
    rest 3
    note $2C, 3
    rest 3
    note $2C, 3
    rest 3
    note $31, 3
    rest 3
    note $31, 3
    rest 3
    note $2C, 3
    rest 3
    note $2C, 3
    rest 3
    note $2E, 3
    rest 3
    note $2E, 3
    rest 3
    note $33, 3
    rest 3
    note $33, 3
    rest 3
    note $2C, 3
    rest 3
    note $2C, 3
    rest 3
    note $2D, 3
    rest 3
    note $2D, 3
    rest 3
    note $2F, 3
    rest 3
    note $2F, 3
    rest 3
    note $34, 3
    rest 3
    note $34, 3
    rest 3
    note $2D, 3
    rest 3
    note $2D, 3
    rest 3
    note $2F, 3
    rest 3
    note $2F, 3
    rest 3
    note $34, 3
    rest 3
    note $34, 3
    rest 3
    note $2D, 3
    rest 3
    note $2D, 3
    rest 3
    note $2F, 3
    rest 3
    note $2F, 3
    rest 3
    note $34, 3
    rest 3
    note $34, 3
    rest 3
    note $2D, 3
    rest 3
    note $2D, 3
    rest 3
    note $2F, 3
    rest 3
    note $2F, 3
    rest 3
    note $34, 3
    rest 3
    note $34, 3
    rest 3
    note $2D, 3
    rest 3
    note $2D, 3
    rest 3
    note $2F, 3
    rest 3
    note $2F, 3
    rest 3
    note $34, 3
    rest 3
    note $34, 3
    rest 3
    note $34, 3
    rest 3
    note $34, 3
    rest 3
    note $2A, 3
    rest 3
    note $2A, 3
    rest 3
    note $2C, 3
    rest 3
    note $2C, 3
    rest 3
    note $31, 3
    rest 3
    note $31, 3
    rest 3
    note $2A, 3
    rest 3
    note $2A, 3
    rest 3
    note $2C, 3
    rest 3
    note $2C, 3
    rest 3
    note $31, 3
    rest 3
    note $31, 3
    rest 3
    note $2A, 3
    rest 3
    note $2A, 3
    rest 3
    note $2C, 3
    rest 3
    note $2C, 3
    rest 3
    note $31, 3
    rest 3
    note $31, 3
    rest 3
    note $2A, 3
    rest 3
    note $2A, 3
    rest 3
    note $2C, 3
    rest 3
    note $2C, 3
    rest 3
    note $31, 3
    rest 3
    note $31, 3
    rest 3
    note $2C, 3
    rest 3
    note $2C, 3
    rest 3
    note $2E, 3
    rest 3
    note $2E, 3
    rest 3
    note $33, 3
    rest 3
    note $33, 3
    rest 3
    note $2C, 3
    rest 3
    note $2C, 3
    rest 3
    note $2D, 3
    rest 3
    note $2D, 3
    rest 3
    note $2F, 3
    rest 3
    note $2F, 3
    rest 3
    note $34, 3
    rest 3
    note $34, 3
    rest 3
    note $2D, 3
    rest 3
    note $2D, 3
    rest 3
    note $2F, 3
    rest 3
    note $2F, 3
    rest 3
    note $34, 3
    rest 3
    note $34, 3
    rest 3
    note $2D, 3
    rest 3
    note $2D, 3
    rest 3
    note $2F, 3
    rest 3
    note $2F, 3
    rest 3
    note $33, 3
    rest 3
    note $33, 3
    rest 3
    note $2E, 3
    rest 3
    note $2E, 3
    rest 3
    note $2C, 3
    rest 3
    note $2C, 3
    rest 3
    note $33, 3
    rest 3
    note $33, 3
    rest 3
    note $2E, 3
    rest 3
    note $2E, 3
    rest 3
    note $2C, 3
    rest 3
    note $2C, 3
    rest 3
    note $25, 24
    ret_pat

Pat_53BE:
    instr 6
    loop_start 6
    note $1E, 6
    note $1E, 6
    note $1C, 6
    note $1E, 6
    loop_end
    loop_start 2
    note $20, 6
    note $20, 6
    note $1E, 6
    note $20, 6
    loop_end
    loop_start 8
    note $21, 6
    note $21, 6
    note $1C, 6
    note $21, 6
    loop_end
    loop_start 6
    note $1E, 6
    note $1E, 6
    note $1C, 6
    note $1E, 6
    loop_end
    loop_start 2
    note $20, 6
    note $20, 6
    note $1E, 6
    note $20, 6
    loop_end
    loop_start 4
    note $21, 6
    note $21, 6
    note $1C, 6
    note $21, 6
    loop_end
    loop_start 4
    note $22, 6
    note $22, 6
    note $20, 6
    note $22, 6
    loop_end
    ret_pat

Pat_540D:
    instr 4
    note $06, 24
    instr 5
    note $14, 18
    instr 4
    note $06, 6
    note $06, 24
    instr 5
    note $14, 18
    note $14, 6
    instr 4
    note $06, 24
    instr 5
    note $14, 18
    instr 4
    note $06, 6
    note $06, 24
    instr 5
    note $14, 24
    instr 4
    note $06, 24
    instr 5
    note $14, 18
    instr 4
    note $06, 6
    note $06, 24
    instr 5
    note $14, 18
    note $14, 6
    instr 4
    note $06, 24
    instr 5
    note $14, 18
    instr 4
    note $06, 6
    note $06, 24
    instr 5
    note $14, 24
    instr 4
    note $06, 24
    instr 5
    note $14, 18
    instr 4
    note $06, 6
    note $06, 24
    instr 5
    note $14, 18
    note $14, 6
    instr 4
    note $06, 24
    instr 5
    note $14, 18
    instr 4
    note $06, 6
    note $06, 24
    instr 5
    note $14, 24
    instr 4
    note $06, 24
    instr 5
    note $14, 18
    instr 4
    note $06, 6
    note $06, 24
    instr 5
    note $14, 18
    note $14, 6
    instr 4
    note $06, 24
    instr 5
    note $14, 18
    instr 4
    note $06, 6
    note $06, 24
    instr 5
    note $14, 24
    ret_pat

Pat_5486:
    loop_start 32
    note $0F, 12
    note $0E, 12
    loop_end
    ret_pat

Song8_Ch3:
    call_pat 1, 24, Pat_555B
    loop_start 255
    call_pat 2, 24, Pat_5571
    call_pat 1, 27, Pat_5571
    call_pat 1, 24, Pat_5571
    call_pat 1, 24, Pat_5503
    call_pat 1, 25, Pat_5503
    call_pat 1, 0, Pat_5709
    loop_end
    song_restart

Song8_Ch1:
    call_pat 1, 0, Pat_572A
    loop_start 255
    call_pat 2, 0, Pat_56CD
    call_pat 1, 3, Pat_55EF
    call_pat 1, 0, Pat_55EF
    call_pat 1, 12, Pat_5615
    call_pat 1, 13, Pat_5615
    call_pat 1, -12, Pat_5701
    loop_end
    song_restart

Song8_Ch2:
    call_pat 1, 0, Pat_572A
    loop_start 255
    call_pat 2, 0, Pat_56E7
    call_pat 1, 3, Pat_55C7
    call_pat 1, 0, Pat_55C7
    call_pat 1, 12, Pat_5673
    call_pat 1, 13, Pat_5673
    call_pat 1, 0, Pat_5705
    loop_end
    song_restart

Pat_5503:
    instr 32
    note $16, 30
    note $11, 5
    note $13, 5
    note $16, 50
    note $11, 5
    note $13, 5
    note $16, 5
    note $18, 5
    note $16, 5
    note $13, 5
    note $16, 40
    note $1A, 5
    note $1B, 5
    note $1A, 5
    note $18, 5
    note $1D, 5
    note $1B, 5
    note $1A, 5
    note $18, 5
    note $16, 5
    rest 5
    note $18, 5
    rest 5
    note $13, 5
    rest 5
    note $16, 5
    rest 5
    note $1D, 5
    rest 5
    note $1F, 5
    rest 5
    note $1B, 5
    rest 5
    note $1D, 5
    rest 5
    note $1A, 5
    rest 5
    note $1B, 5
    rest 5
    note $18, 5
    rest 5
    note $1A, 5
    rest 5
    ret_pat

Pat_555B:
    instr 32
    note $1E, 2
    note $1D, 2
    note $1C, 2
    note $1B, 2
    note $1A, 2
    note $19, 2
    note $18, 2
    note $17, 2
    note $16, 2
    note $15, 2
    ret_pat

Pat_5571:
    instr 32
    note $1A, 5
    rest 5
    note $15, 5
    rest 5
    note $18, 20
    rest 10
    note $13, 10
    rest 10
    note $15, 5
    rest 5
    note $1A, 10
    rest 10
    note $1A, 10
    rest 5
    note $13, 5
    note $15, 5
    rest 5
    note $13, 5
    rest 5
    note $18, 10
    rest 10
    note $1A, 5
    rest 5
    note $13, 5
    rest 5
    note $15, 20
    rest 10
    note $13, 20
    rest 10
    note $1A, 10
    rest 10
    note $1A, 10
    rest 5
    note $13, 5
    note $15, 5
    rest 5
    note $1D, 5
    rest 5
    note $1C, 5
    rest 5
    note $18, 5
    rest 5
    ret_pat

Pat_55C7:
    instr 11
    rest 15
    note $34, 5
    note $34, 5
    note $34, 5
    note $34, 5
    note $34, 5
    note $35, 25
    note $34, 20
    note $34, 10
    note $34, 80
    note $34, 5
    note $34, 5
    note $34, 5
    note $34, 5
    note $34, 5
    note $35, 25
    note $34, 20
    note $34, 10
    note $35, 65
    ret_pat

Pat_55EF:
    instr 11
    note $34, 5
    note $34, 5
    note $34, 5
    note $34, 5
    note $34, 5
    note $35, 25
    note $34, 20
    note $34, 10
    note $34, 80
    note $34, 5
    note $34, 5
    note $34, 5
    note $34, 5
    note $34, 5
    note $35, 25
    note $34, 20
    note $34, 10
    note $35, 80
    ret_pat

Pat_5615:
    instr 9
    note $3A, 29
    note $38, 4
    note $3A, 2
    note $38, 5
    note $37, 29
    note $35, 4
    note $37, 2
    note $35, 5
    note $33, 29
    note $32, 4
    note $33, 2
    note $32, 6
    note $30, 18
    note $2E, 21
    note $32, 5
    note $33, 5
    note $32, 5
    note $30, 5
    note $35, 5
    note $33, 5
    note $32, 5
    note $30, 5
    note $2E, 5
    rest 5
    note $30, 5
    rest 5
    note $2B, 5
    rest 5
    note $2E, 5
    rest 5
    note $29, 5
    rest 5
    note $2B, 5
    rest 5
    note $27, 5
    rest 5
    note $29, 5
    rest 5
    note $26, 5
    rest 5
    note $27, 5
    rest 5
    note $24, 5
    rest 5
    note $26, 5
    rest 5
    ret_pat

Pat_5673:
    instr 18
    rest 15
    note $3A, 29
    note $38, 4
    note $3A, 2
    note $38, 5
    note $37, 29
    note $35, 4
    note $37, 2
    note $35, 5
    note $33, 29
    note $32, 4
    note $33, 2
    note $32, 6
    note $30, 18
    note $2E, 21
    note $32, 5
    note $33, 5
    note $32, 5
    note $30, 5
    note $35, 5
    note $33, 5
    note $32, 5
    note $30, 5
    note $2E, 5
    rest 5
    note $30, 5
    rest 5
    note $2B, 5
    rest 5
    note $2E, 5
    rest 5
    note $29, 5
    rest 5
    note $2B, 5
    rest 5
    note $27, 5
    rest 5
    note $29, 5
    rest 5
    note $26, 5
    rest 5
    note $27, 5
    rest 5
    note $24, 5
    ret_pat

Pat_56CD:
    instr 9
    rest 20
    note $43, 30
    note $3E, 10
    note $3E, 10
    note $3C, 10
    note $3E, 20
    note $40, 80
    note $43, 30
    note $3E, 10
    note $3E, 10
    note $3C, 10
    note $3E, 80
    ret_pat

Pat_56E7:
    instr 18
    rest 35
    note $43, 30
    note $3E, 10
    note $3E, 10
    note $3C, 10
    note $3E, 20
    note $40, 80
    note $43, 30
    note $3E, 10
    note $3E, 10
    note $3C, 10
    note $3E, 65
    ret_pat

Pat_5701:
    instr 9
    note $26, 80
    ret_pat

Pat_5705:
    instr 9
    note $35, 80
    ret_pat

Pat_5709:
    instr 35
    note $39, 60
    instr 35
    note $36, 2
    note $35, 2
    note $34, 2
    note $33, 2
    note $32, 2
    note $31, 2
    note $30, 2
    note $2F, 2
    note $2E, 2
    note $2D, 2
    ret_pat

; unreferenced: nothing in the ROM points at $5722-$5725
Unused_5722:
    instr 33
    note $48, 80
    ret_pat

; unreferenced: nothing in the ROM points at $5726-$5729
Unused_5726:
    instr 33
    note $4C, 80
    ret_pat

Pat_572A:
    rest 20
    ret_pat

; unreferenced: nothing in the ROM points at $572D-$572F
Unused_572D:
    rest 80
    ret_pat

; SFX: 2 bytes each = instrument byte ($80|index), duration in ticks (60/s).
; Game calls: 0, 3, 4, 5, 6 (1 and 2 have no caller found).
SfxTable:
    db $81,   3   ; SFX 0
    db $81,  20   ; SFX 1
    db $81,  35   ; SFX 2
    db $83,   1   ; SFX 3
    db $8E,   1   ; SFX 4
    db $8F,  15   ; SFX 5
    db $90,   5   ; SFX 6
