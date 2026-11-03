# Biox / Japan System House Sound Drivers — Noobow, Pocket Bowling, Daiku no Gensan, Burger Burger Pocket

Disassembly and documentation of the sound code in four Game Boy games. No earlier research was used. Everything here comes from the code, and the interfaces were checked in PyBoy.

| Game | ROM | Mapper | Driver | Sound bank(s) | Region |
|---|---|---|---|---|---|
| Noobow (J) | 256 KB | MBC1 | **A1** | $0F | $4000–$6E1C |
| Pocket Bowling (U) [C] | 512 KB | MBC5 | **A2** | $1F | $4000–$79DC |
| Burger Burger Pocket (J) [C] | 1 MB | MBC5 | **B1** | $02 | $4000–$659F |
| Daiku no Gensan – Kachikachi no Tonkachi ga Kachi (J) [C] | 1 MB | MBC5+RAM+batt | **B2** | $3C, $3D, $3E | $4000–$7D88 / $7DFC / $61C7 |

## Summary

- The four games use **two unrelated drivers**:
  - **Driver A** (Noobow and Pocket Bowling) runs off the timer interrupt.
  - **Driver B** (Burger Burger Pocket and Daiku no Gensan) runs once per frame, uses a request queue and keeps each track's working state in HRAM.
- The two drivers share no code, no RAM layout and no data format. Even their frequency tables differ in a few entries (A has `$009D, $01CA…`, B has `$009C, $01C9…`).
- **Pocket Bowling** uses the Noobow driver almost unchanged, seven years later. Its version adds bug fixes, a `$FE` raw-length command and direct (non-indirected) song tables.
- **Burger Burger Pocket does use a version of Daiku's engine.** Its bank-2 driver is an earlier, smaller revision of driver B. It has the same queue, the same HRAM working copy and the same tempo divider, but a different byte map and fewer commands. It is not related to the Noobow/Bowling driver.
- BBP's *leftover* sound code and data in banks $2A and $27 belong to a third, unrelated driver. The game cannot run it (see §5).

---

## 1. Driver A (Noobow = A1, Pocket Bowling = A2)

### 1.1 Interface

The jump table at the start of the bank:

| Address | Entry | Called from |
|---|---|---|
| $4000 | `Snd_Play(a = id)` | game code. Music ids are < 8 (A1) or < $0E (A2); higher ids are SFX |
| $4003 | `Snd_TimerUpdate`, the music tick | **timer interrupt** (Noobow $04BF, Bowling $040E) |
| $4006 | `Snd_FrameUpdate`, the SFX tick | once per frame (VBlank path) |
| $4009 | `Snd_Init` | boot |
| $400C | `Snd_IsSfxIdle`: Z = 1 when both SFX tracks are off | Noobow only ($375F) |

`Snd_Init` sets every track pointer to $FFFF, NR31=$FF, NR32=0, NR34=$40, TIMA=TMA=$40 and TAC=$04 (4096 Hz), and enables the timer interrupt in IE.

**Music timing.** Music runs at the timer rate, 4096 / (256 − TMA) Hz, where TMA = `hSndTempo` (command `$E6`). In PyBoy the Noobow title runs at TMA=$BB, which is 59.4 Hz. On every timer interrupt:

1. If LY ≥ $70, the driver sets TIMA=TMA=$E6, which retries about 6.3 ms later, and skips the tick. This keeps the music tick out of the bottom of the screen and VBlank.
2. Otherwise it reloads TIMA/TMA from `hSndTempo` and updates music ch1–ch4.
3. Finally it records profiling data in `wSndProf*` ($DED0–$DED4): start LY, end LY, a running average and the maximum number of lines used. The driver never reads these back.

Pocket Bowling's ISR runs the tick only on every other interrupt while game variable $CEA9 = 2. This is game code, not driver code.

**SFX timing.** The two SFX tracks advance one tick per frame through $4006. SFX track 1 plays on hardware ch2 and SFX track 2 on ch4.

`Snd_Play` with a **music** id:
- loads the four track pointers from the song header;
- clears the four length counters, loop counters and call depths;
- sets NR50/NR51/NR52 = $FF (A2: NR50=$77);
- resets the profiler.

With an **SFX** id it loads the two SFX pointers and clears their counters. Tempo, instruments and envelopes are *not* reset. Interrupts are disabled while it runs.

Ids seen in PyBoy runs: Noobow music $01, $06 and SFX $09. Bowling music $00 (silence), $01, $03, $06, $07, $08, and SFX $22–$41, $5C, $66, $67. The power-meter SFX $32–$41 climbs in pitch.

### 1.2 Tables (bank $0F / $1F)

| Table | Noobow | Bowling | Format |
|---|---|---|---|
| `SndCommandTable` | $440E | $440C | 32 words, $E0–$FF |
| `SndPanTable` | $44FF | $44FD | `$00,$80,$08,$88` |
| `SndFreqTable` | $4811 (128 words) | $4828 (99 words, truncated) | rows of 16 words: 13 notes C..C' then 3 zero words |
| `SndLengthTable` | $4911 | $48EE | 16 bytes (same in both games) |
| `SndEnvTable` + sequences | $4921 / $4927–$497E | *empty* | 3 pointers, then (count, NRx2) pairs ending in count 0 |
| `SndWaveTable` | $497F (16 × 16; 7 defined, 9 filled with $FF) | $48FE (2 waves) | |
| `SndVibratoTable` | $4A7F (22 × 4) | *empty* | delay, half-period, step (word) |
| Music table | $4AD7: 8 words → 8 headers of 4 track words | $513A: 14 headers of 4 words, inline | $FFFF = channel unused |
| SFX table | $6B5B: 25 words → headers of 2 words | $491E: 96 headers of 2 words, inline | (ch2 track, ch4 track) |

In Bowling the envelope and vibrato tables have zero length, so their labels resolve to the same address as the song table ($513A). An `$E2` on ch1/2/4 or an `$E4` would read song pointers as envelope or vibrato data. Bowling's data never uses either command.

Length table: index 0–F = 2, 3, 4, 6, 9, 8, 12, 18, 16, 24, 36, 32, 48, 72, 64, 96 ticks.

### 1.3 RAM (identical in both games)

| Address | Name | Use |
|---|---|---|
| $FFC0–$FFCB | `hSndPtrCh1..4`, `hSndPtrSfx2`, `hSndPtrSfx4` | track pointers ($FFFF = off) |
| $FFCC | `hSndTempo` | TMA value |
| $FFCD–$FFCF | `hSndUnusedCD/CE` | written by `$E6`/`$E7`/`$E8`, never read |
| $FFD0+c | `hSndLastNote[6]` | last note byte |
| $FFD6+c | `hSndLastLen[6]` | last length in ticks |
| $FFDC+c | `hSndLenCount[6]` | ticks left in the row |
| $FFE2+c | `hSndInst[6]` | `$E2` value |
| $FFED / $FFEE | last music / SFX id | |
| $DE00 + $1E·n | `wSndCh1..4`, `wSndSfx2`, `wSndSfx4` | track structs (below) |
| $DEC8 | `wSndLastByte` | last parsed byte (for `$F3`) |
| $DEC9 | `wSndSfxOwns` | $FF while the SFX track holds this hardware channel |
| $DECA / $DECB / $DECC | slur / new-vibrato / new-instrument flags (one row) | |
| $DECD / $DECF | struct offset / NRx0 register offset of the current track | |
| $DED5 / $DEE1 | envelope-sequence pointers / counters | |
| $DEE7 | $80 when the envelope stepper changed NRx2 (forces a retrigger) | |
| $DEE8 | $FF on ticks where a new row was parsed | |

The track index **c** is 0–3 for music ch1–4, 4 for SFX ch2 and 5 for SFX ch4.

**Struct fields:**

| Offset | Meaning |
|---|---|
| +3/4 | current frequency |
| +5 | NRx2 shadow (`$E5`) |
| +7 | vibrato index |
| +8 | vibrato delay |
| +9/A | base frequency |
| +B/C | vibrato half-period / counter |
| +D/E | vibrato step |
| +F/10 | vibrato accumulator |
| +11–14 | loop counters |
| +15 | call depth |
| +16–1D | call stack (4 words) |

### 1.4 Track format

| Byte | Meaning |
|---|---|
| `$00–$9F` | **note**. The hi nibble is the octave row and the lo nibble is 0–B = C..B, C = the next C. Lo nibble **D–F = rest** (only `$0D` is used). A `$Ax` byte directly after the note gives the length; without one, the last length is reused. On noise tracks (c = 3, 5) the byte is nibble-swapped into NR43 and NR44=$80 |
| `$A0–$AF` | a lone **length** byte. It re-strikes the last note with the new length. If the previous byte was `$F3`, it only extends the note |
| `$B0–$DF` | ends the track (no handler) |
| `$E0–$FF` | commands |

Frequency = `SndFreqTable[(note − $10) & $7F]`, so `$10` is C2 (65.4 Hz on ch1/2). The macros name notes with octave = hi nibble + 1 (`C_2` = $10).

A row lasts *length* ticks. While the counter runs, the steppers run instead of parsing. On the tick that parses a new row, the steppers are skipped (`wSndNewRow`).

| Cmd | Args | Macro | Effect |
|---|---|---|---|
| $E0, $E9, $EA, $EC, $ED, $F6–$FD, $FF | – | `snd_end` | end of track (pointer → $FFFF). Data only uses $FF |
| $E1 | xx | `snd_sweep` | NR10 (music ch1 only; skipped elsewhere) |
| $E2 | xx | `snd_inst` | ch1/2/4/SFX: envelope sequence xx (0 = none). ch3: wave xx, loaded at the next note |
| $E3 | xx | `snd_duty` | NR11, **music ch1 only**. Nothing ever writes NR21 |
| $E4 | xx | `snd_vibrato` | vibrato entry, taken by the next note |
| $E5 | xx | `snd_env` | NRx2 (ch3: NR32 level) |
| $E6 | xx | `snd_tempo` | TMA = TIMA = xx (0 = keep); clears $FFCD–CF |
| $E7 / $E8 | ww | `snd_unused_e7/e8` | store −ww / ww in $FFCE (never read; unused by data) |
| $EB | n | `snd_pan` | NR51 bits of this channel: 0 = off, 1 = right, 2 = left, 3 = both |
| $EE | ptr | `snd_call` | 4-level stack. A 5th call **ends the track** |
| $EF | – | `snd_ret` | return. At depth 0 it ends the track |
| $F0 | count, idx, ptr | `snd_loop` | counter = +11+idx. **A1:** jumps whenever counter ≠ count, but never increments, so it loops forever unless count = 0 (unused in Noobow data). **A2:** increments, so it jumps *count* times then resets |
| $F1 | ptr | `snd_jump` | jump |
| $F2 | xx | `snd_mastervol` | NR50 (A2: & $77) |
| $F3 | – | `snd_tie` | a following lone length extends the note |
| $F4 | nn | `snd_rawnote` | plays byte nn as a note without the < $A0 check. Used for noise values ≥ $A0 |
| $F5 | – | `snd_slur` | next note: no envelope write, no vibrato reset, NRx4 without trigger |
| $FE | xx | `snd_length` | **A2 only** (A1: end): sets the row length to xx ticks for the next note(s), then keeps parsing |

### 1.5 Note start and steppers

- **Envelope** (`Snd_NoteEnvelope`). Skipped while the SFX owns the channel or under slur.
  - ch3: NR30=$7F. If `$E2` ran in this row, the wave loads. NR32 = level.
  - Others: if an instrument is set, the first (count, value) pair loads into the counter and the NRx2 shadow, then NRx2 is written.
  - A2 skips all of this on rests.
- **Envelope stepper** (ch1, ch2, SFX ch2). When the counter reaches 0, the next pair is written to NRx2 and `wSndTrigger`=$80 makes the next frequency write retrigger. Count 0 holds.
- **Vibrato**. A note right after `$E4` loads delay, half-period and step; any other note only clears the accumulator. Each tick: accumulator += step, and the step is negated every half-period ticks. The frequency is base + (accumulator >> 3). So the vibrato swings between the base pitch and one side of it.
- **Frequency out**. NRx3 = lo. NRx4 = hi | `wSndTrigger`. The value is clamped to $0000–$07FF.
- **ch3** skips vibrato and frequency output on the last tick of each row (it checks `hSndLenCount+2` ≠ 0).
- **Rests and ended tracks.** On every tick of a rest row (lo nibble ≥ D) and every tick after a track ends, music ch1 gets NR12=0, ch2 NR22=0 (if no SFX), ch3 NR32=0 and ch4 NR42=0 (if no SFX). That is what silences a rest. SFX rests only skip the steppers.

**SFX vs music.** Music ch2 and ch4 keep parsing while an SFX plays on that channel, but `wSndSfxOwns` blocks their envelope, frequency and trigger writes. When the SFX ends, the music returns at its next note.

### 1.6 A1 → A2 differences (Noobow → Pocket Bowling)

Apart from address shifts:

1. **Vibrato delay.** A1's `Snd_VibratoStep` pops 4 registers it never pushed when the delay is nonzero, which corrupts the stack. Noobow's table only uses delay 0. A2 returns normally.
2. **`$F0` loop.** A2 adds the missing `inc [hl]`.
3. **`$FE`** raw-length command added.
4. **Rests** no longer write NRx2 at note start.
5. `$F2` masks NR50 with $77, and `Snd_Play` sets NR50=$77.
6. **Song and SFX tables** are inline arrays (8/4 bytes per id) instead of pointer tables.
7. `cpl` replaces `xor $FF` in the vibrato negate.

### 1.7 Quirks

- Music ch2's envelope **stepper** writes NR22 even while an SFX owns ch2. Only its frequency writes are blocked.
- Noobow song $07 ch4 points to a lone `$FF` at $6B42. The 24 bytes after it ($6B43) are an unreferenced noise pattern.
- Noobow SFX $08 ch4 points to `$FF` at $6C00. $6C01–$6D38 is an unreferenced **noise test** that steps through every NR43 value $00–$FD (using `$F4` for values ≥ $A0).
- Bowling $6C77–$79DC (3.4 KB) holds 12 unreferenced tracks, looking like three cut songs. One of them jumps back into song $0D's data. $4C61 holds a cut SFX fragment, and $51D4 two orphan `$4AA7` pointers.

---

## 2. Driver B (Burger Burger Pocket = B1, Daiku no Gensan = B2)

### 2.1 Interface

| Address | Entry | Use |
|---|---|---|
| $4000 | `Snd_Update` | once per frame (BBP from its interrupt handler $2E5B, Daiku from the main loop $0F6B with bank = `hCurRomBank`) |
| $4003 | `Snd_Init` | boot |
| $4006 | `Snd_Request(a)` | queues a byte. The queue holds 8 bytes; when full it returns carry and drops the byte |

Requests are handled at the start of the next `Snd_Update`. The queue is processed **newest first**. No requests are taken while a fade runs. If the game's pause flag is nonzero (`hSndPause`: BBP $FFBA, Daiku $FFC1), music and fades freeze, but the queue and SFX keep running.

| Request | B1 (BBP) | B2 (Daiku) |
|---|---|---|
| music | $00–$7F (19 songs, $00–$12) | $00–$3F (28 songs, $00–$1B) |
| SFX | $80–$BF → index & $3F (52 SFX) | $40–$EF → index − $40 (64 SFX, $40–$7F) |
| system | $C0–$C7 | $F0–$F7 |

The system commands are, in order:

1. stop all
2. stop music
3. stop SFX
4. fade in (NR50 set to 0, then +$11 every 10 frames up to $77)
5. fade out (−$11 every 10 frames; at 0 everything stops)
6. NR50 = $11
7. NR50 = $77
8. silence ch1–4 (envelope 0 + trigger; tracks keep running)

Bytes past these ranges index past the tables and crash.

Ids seen in PyBoy runs: BBP music $07 and $08, SFX $84, $86, $8F, system $C0. Daiku music $00, $06, $0C, $13, $15, SFX $40, $71, system $F4.

**Starting music:**
- calls `Snd_Off` (NR50=0, NR52=0);
- clears the music tracks;
- sets the pointers from the header, the active bits and NR52=$80, NR51=$FF, NR50=$77;
- loads the song's initial wave from `SndMusicWaveTable[id]`;
- resets NR51=$FF, NR10=8, NR30=$80, NR32=0 (Daiku also NR31=0).

**Daiku bank switching.** A music id indexes `SndMusicBankTable` ($45BA: pairs of bank, index). The driver writes the bank to `hCurRomBank`, $FFAA and $2000 *while running inside the bank*. This works because $4000–$5310 (driver, tables, waves, envelopes and all SFX) is **byte-identical in banks $3C, $3D and $3E**. Each bank holds its own song table at $5311:

| Bank | Song ids |
|---|---|
| $3C | $00–$0B |
| $3D | $0C–$19 |
| $3E | $1A–$1B |

**SFX priority.** A new SFX is ignored if `priority[new] < priority[current]` (byte compare). Daiku's table ($4B0E) uses values $10–$F0. BBP's ($4832) is all zero, so every new SFX replaces the old one.

Starting an SFX silences the channels the old SFX used. Music tracks on channels the SFX uses are **muted**: they keep running but write nothing.

**Timing.**
- SFX: 1 tick per frame.
- Music: a 16-bit accumulator gains `tempo × 256 / 150` per frame (BBP: `/ 300`). The change in the high byte is the number of ticks run that frame (0, 1, 2, …).
- The initial tempo is 120 (0.8 ticks/frame in Daiku).
- `Snd_Init` also writes TIMA/TMA=$BC, which is vestigial: the timer is not used.

### 2.2 RAM

| | B1 (BBP) | B2 (Daiku) |
|---|---|---|
| music structs | $C001 + $18·n | $D44C + $19·n |
| SFX structs | $C061 + $18·n | $D4B0 + $19·n |
| queue / ptr / count | $C0C1 / $C0C9 / $C0CB | $D514 / $D51C / $D51E |
| current NRx1 addr / channel | $C0CC / $C0CD | $D51F / $D520 |
| fade mode / timer | $C0CE / $C0D0 | $D521 / $D523 |
| current / saved wave ptr | – | $D524 / $D526 |
| current music / SFX ($FF = none) | $FFD0 / $FFD1 | $FFD0 / $FFD1 |
| tempo, step, accumulator, ticks | $FFD2, $FFD3, $FFD5, $FFD7 | same |

Each struct is copied into **HRAM $FFD8–** before it is processed and copied back after (`Snd_LoadChan` / `Snd_SaveChan`):

| HRAM | B1 | B2 |
|---|---|---|
| $FFD8 | flags: 7 active, 4 pitch env, 3 muted | flags: 7 active, 6 ch3 length bit, 3 pitch env, 2 muted, 1 octave env |
| $FFD9/DA | data pointer | same |
| $FFDB / $FFDC | tick counter / row length | same |
| $FFDD / $FFDE | loop count / loop pointer | same |
| $FFE0 | return pointer (1 level) | same |
| $FFE2–E7 | unused | unused |
| $FFE8 | pitch-env pointer | env start pointer |
| $FFEA | frequency | env current pointer |
| $FFEC | NRx2 | frequency |
| $FFED | NRx1 | – |
| $FFEE | transpose | NRx2 |
| $FFEF | unused | NRx1 |
| $FFF0 | – | transpose |

### 2.3 Track format

|  | B1 | B2 | Meaning |
|---|---|---|---|
| length | $00–$31 | $00–$7F | sets the row length in ticks; parsing continues |
| note | $32–$8F | $80–$D3 | index + transpose into `SndFreqTable` (index 0 = C2, $002C). Writes NRx1..NRx4 with trigger. ch3 also cycles NR30 $7F→$80 and sets NR34 bit 6 (B1: always; B2: if flag 6). On ch4 the table's low byte goes to NR43 |
| drum | $90–$95 (6 valid) | $D4–$E3 (16) | NRx2 and NRx3 from `SndDrumEnvTable` / `SndDrumFreqTable`, NRx4=$80 |

| B1 | B2 | Args | Macro | Effect |
|---|---|---|---|---|
| $ED | $E4 | len, NR42, NR43 | `snd_noise` | writes NR41–NR44 directly from **any** track and ignores the SFX mute |
| $EE | $E5 | x | `snd_hold` | waits one row while the previous note keeps sounding; the argument is skipped |
| $EF | $E6 | – | `snd_off` | silence (NRx2=8 + trigger; ch3 NR30=$7F, NR32=0) and wait one row. Daiku's usual rest |
| $F0 | $E7 | – | `snd_end` | end of track (flags = 0, channel silenced) |
| $F1 | $E8 | ptr | `snd_jump` | |
| $F2 / $F3 | $E9 / $EA | ptr / – | `snd_call` / `snd_ret` | one level |
| $F4 / $F5 | $EB / $EC | n / – | `snd_loop` / `snd_endloop` | the body runs *n* times; no nesting |
| $F6 | $ED | t | `snd_tempo` | ticks/frame = t/150 (B1: t/300). Global |
| $F7 | $EE | xx | `snd_env` | NRx2 |
| $F8 | $EF | ptr | `snd_pitchenv` | additive pitch envelope. B2: ptr 0 = off. B1 has no 0 check |
| $F9 | $F0 | – | `snd_nop` | |
| $FA | $F1 | xx | `snd_duty` | NRx1, written immediately |
| $FB | $F2 | xx | `snd_pan` | NR51 (global) |
| $FC | $F3 | xx | `snd_transpose` | |
| – | $F4 / $F5 | $x0 / $0x | `snd_vol` / `snd_envlo` | NRx2 high / low nibble |
| – | $F6 | ptr | `snd_octenv` | octave envelope |
| – | $F7 / $F8 | ptr / – | `snd_wave` / `snd_wave_restore` | load 16 wave bytes, remembering the previous wave / reload the previous wave |
| – | $F9 | xx | `snd_env2` | NRx2 (same as $EE) |
| – | $FA | x | `snd_ch3len` | ≠ 0 sets the ch3 length-enable bit |
| $FD–$FF | $FB–$FF | | | off the end of the jump table, crash |

**Envelope streams** (`env_stop` = $80, `env_jump ptr` = $81 ptr; any other byte is a value). The stream advances one byte per tick, before the row counter.

- **Pitch env** (B1 bit 4, B2 bit 3): frequency += signed value, written to NRx3/NRx4 without trigger. The change accumulates.
  - B1 runs the stream once from the `$F8` command and clears the bit at $80.
  - B2 **restarts it on every note and rest** and holds at $80.
- **Octave env** (B2 bit 1): writes the note's frequency shifted by the value without changing it. +n = n octaves down (`<< n`), −n = n octaves up (`(f | $800) >> n`). Used as an arpeggio or octave flutter.

### 2.4 B1 → B2 differences

1. New byte map, with more length values (0–127) and 16 drum presets.
2. Separate start and current envelope pointers, so envelopes restart per note.
3. **Octave envelope** added.
4. **Wave commands** `$F7`/`$F8` added (B1 only loads a wave at song start).
5. NRx2 nibble commands, `snd_env2` and `snd_ch3len` added.
6. ch3 length-enable becomes optional.
7. Tempo divisor 300 → 150.
8. Struct grows from $18 to $19 bytes.
9. Three-bank layout with the bank-switching music start.
10. SFX ids move from $80–$BF to $40–$EF; system commands from $C0 to $F0.
11. `Snd_ClearMusic` gets its `xor a`, and stop-music / stop-SFX no longer switch the APU off (see below).

### 2.5 Quirks

- **BBP pitch-env garbage at song start.** `Snd_StartMusic` calls `Snd_SetMusicFlags` straight after `Snd_Off`, which leaves A = $FF. The missing `xor a` sets *every* flag bit on all four music tracks, including the pitch-envelope bit 4. Any track that doesn't issue `$F8` then runs a pitch envelope from whatever pointer its struct holds.
  - After power-on that pointer is $0000, so BBP's ch4 drums get NR43 modulated by bank-0 bytes for 323 ticks. That lasts until the stream reaches the first $80 byte, which is the CGB flag at $0143.
  - Confirmed in PyBoy: flags = $FF on all tracks at song start, and ch4's pointer advances $0000→$0002→$0007.
- **BBP song $0C** has channel mask $F but only three pointers. The fourth pointer is read from the first two track bytes, giving $82F6 (VRAM). Its ch3 is `SndNullTrack` ($48E2).
- Daiku's `SndMusicWaveTable` has only 19 entries. Ids $13–$1B take their initial wave pointer from the wave data itself. Every one of those songs loads its own wave with `$F7`.
- `snd_noise` ignores the SFX mute. Daiku only uses it inside SFX.
- **BBP stop commands kill all sound.** BBP's stop-music ($C1) and stop-SFX ($C2) both end in `Snd_Off` (NR52=0), so stopping only the SFX also silences the music until the next song starts. Daiku's versions silence only their own channels.
- Each game has one null track (`$E7` / `$F0`) that unused channels point to: Daiku $4B0D, BBP $48E2.

---

## 3. Sound tables

| Game | Music | SFX | Unreferenced data in the asm |
|---|---|---|---|
| Noobow | 8 (ids $00–$07), all 4 channels | 25 (ids $08–$20) | `SndUnused_6B43`, `SndUnused_6C01` (noise test) |
| Pocket Bowling | 14 ($00 = silence, all channels → $4AA7) | 96 ($0E–$6D) | $4C61, 12 tracks at $6C77–$79DC |
| Burger Burger Pocket | 19 ($00–$12), all mask $F | 52 ($80–$B3) | one stream at $4F1B; 9 of 13 waves and 13 envelope streams unreferenced |
| Daiku no Gensan | 28 ($00–$1B, banks $3C/$3D/$3E), all mask $F | 64 ($40–$7F) | two tiny fragments in bank $3D ($6BA8, $7A1D); 12 envelope streams unreferenced |

Track labels follow the headers:
- `MusXX_ChN` / `SfxXX_ChN` (Daiku: `Mus<bank>_<index>_ChN`);
- `Trk_xxxx` for jump, call and loop targets;
- `SndUnused_xxxx` for streams nothing points to.

## 4. Driver comparison at a glance

| | A (Noobow/Bowling) | B (BBP/Daiku) |
|---|---|---|
| Music clock | timer IRQ, TMA tempo | per frame, fractional ticks (tempo/150) |
| Requests | direct `Snd_Play(id)` | 8-byte queue, newest first |
| Tracks | 4 music + 2 SFX (ch2, ch4) | 4 music + 4 SFX |
| Note byte | octave/pitch nibbles, + optional `$Ax` length after | length byte first, then note index + transpose |
| Pitch effects | triangle vibrato, slur | pitch-delta stream; B2 adds octave stream |
| Volume | envelope sequences (A1) | NRx2 per note, nibble commands (B2) |
| Calls | 4-level stack, 4 loop counters | 1 level, 1 loop |

## 5. The BBP leftover driver (banks $2A / $27)

Bank $2A $6041–$7FFF and bank $27 $4000–$5FB6 hold the same bytes; the bank-27 copy is the 2A block from $6049 on. They contain a **third driver**, unrelated to A and B. It has its own RAM ($D430+, $D5B0+), masks the timer interrupt while it sets up, uses a different period table ($6ACC) and its own parser (`cp $D0/$D6/$D8/$E0`), followed by song tables and data.

It is dead code:
- It sits $41 bytes away from where it was assembled. For example, the multiply routine at $2A:$6041 ends with `jp nz,$6007`, which lands in tile data.
- All of BBP's sound calls go to bank $02.

It looks like stale build filler and was not disassembled.

---

## 6. Files

In `GBAudioLab\Biox\`:

| File | Contents |
|---|---|
| `Noobow_sound.asm` | bank $0F $4000–$6E1C: driver A1, tables, all music, SFX and unused streams |
| `PocketBowling_sound.asm` | bank $1F $4000–$79DC: driver A2 + data |
| `BurgerBurgerPocket_sound.asm` | bank $02 $4000–$659F: driver B1 + data |
| `Daiku_sound_common.inc` | shared $4000–$5310 (driver B2, tables, waves, envelopes, SFX) |
| `Daiku_sound_bank3C.asm`, `_bank3D.asm`, `_bank3E.asm` | each INCLUDEs the common part, then that bank's song table and songs |
| `bioxA_sound.inc` / `bioxB_sound.inc` | macros and note constants (set `BIOXB_VER` to 1 or 2 before including B) |
| `hardware.inc` | register names |
| `tools\*.py` | the generators used to produce the .asm files (they read the ROMs as `noobow.gb`, `bowl.gbc`, `daiku.gbc`, `bbp.gbc`) |

Every file assembles **byte-identical** with RGBDS 1.0.0 to the matching ROM region:

```
rgbasm -o noobow.o Noobow_sound.asm
rgblink -p 0xFF -o noobow.gb noobow.o      ; compare bank $0F $4000-$6E1C
```

| File | Bytes checked | Mismatches |
|---|---|---|
| Noobow | 11,805 | 0 |
| Pocket Bowling | 14,813 | 0 |
| Burger Burger Pocket | 9,632 | 0 |
| Daiku bank $3C / $3D / $3E | 15,753 / 15,869 / 8,648 | 0 |

The Daiku banks are assembled separately, one object per bank. Labels in the common include are file-local, so the three copies don't collide.
