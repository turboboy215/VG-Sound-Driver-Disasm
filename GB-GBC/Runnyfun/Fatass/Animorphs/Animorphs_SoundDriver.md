# Animorphs (GBC): sound driver

ROM: `Animorphs (E) (M5) [C][!].gbc` (MBC5+RAM+battery, 1 MB, CGB-only)

The driver is the playback routine of Jeremy Evers' **F.A. tracker**, adapted for ROM songs. The game's credits list "music system and additional code: jeremy evers" and "music: randy wilson". The tracker ROM in the same folder (v0.14) credits Evers for code/art/music and Wilson for additional music. Its bank-$10 player is the same code as this one: the tables are byte-identical, and the code matches except for the changes listed in section 8.

| | |
|---|---|
| API (bank 0) | `PlaySongCold` `$05C4`, `PlaySong` `$05D5`, `SndUpdateFar` `$05E6` (game uses far wrapper `$0649`) |
| Bank helpers (bank 0) | `ReadSongByte` `$05F0`, `ReadStreamByte` `$0603`, `ReadPeriodByte` `$0617`, `SndBankRestore` `$061B` |
| Driver code | bank 9 `$67E0–$747F` (3,232 bytes) |
| Driver tables | bank 9 `$4000–$67DF` (vibrato, noise, shuffle, wave distortion, 256 wave presets, command table) |
| Period table | bank $0A `$4000–$647F` (4,672 words, 64 per semitone) |
| Song table | bank 9 `$7480` (20 pointers), `$74A8` (20 banks) |
| Song data | banks 9, $0A–$0F: 74,585 bytes, 20 songs |
| Tick | VBlank tail `$023E` calls `SndUpdateFar` on every **second** frame (≈29.9 Hz) |
| RAM | `$CA00–$CAFF` (globals `$CA00–$CA2F`, four `$34`-byte channel structs from `$CA30`) |
| SFX | none. The game has no separate sound-effect driver; jingles are songs. |

`Animorphs_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 for every range above: 0:`$05B2–$062A`, 0:`$0649–$0654`, banks 9–$0E whole, and $0F:`$6990–$7FFF`. That covers the code, all tables, all 20 songs as macros, and the `$FF` fill.

```
rgbasm -o snd.o Animorphs_SoundDriver.asm
rgblink -p 0xFF -o snd.gbc snd.o
python3 tools/verify.py "Animorphs (E) (M5) [C][!].gbc" snd.gbc
```

---

## 1. Architecture

This is a tracker player with four fixed tracks, one per hardware channel.

- **Song** = header, name, **sequence**, **pattern table**, then streams.
- **Sequence**: a byte list of pattern numbers interleaved with global commands (speed, shuffle, song transpose, pan). It ends in `FF`, which restarts the song.
- **Pattern**: four stream pointers, one per channel. A stream is a list of rows. Each row is any number of commands followed by one row terminator: a note, a note off, or a wait.
- **Per-update effects**: arpeggio, vibrato, portamento, auto-pan, auto-PWM and retrigger run every update, independent of rows.
- **CH3 is a synthesiser**: commands load one of 256 waveform presets into a working buffer, distort it through 128 nibble-mapping tables, or mix in a resampled second preset. The buffer is uploaded to wave RAM when it changes.

`SndUpdate` (once per update):

1. `inc = max(1, (wSpeed2 × ShuffleTable[ptr]) >> 5)`. Only the low byte is used.
2. `wTickAcc += inc`. On carry a row is due. The shuffle phase advances, and every channel gets `CH_ROWS += 1` with its trigger-delay counter reloaded.
3. `SndUpdateChannel` runs for CH1 → CH4: row reading (if due) and then all effects and register writes.
4. If any channel read `FF` (end of pattern), the sequence is read and step 2's row bookkeeping and step 3 run again in the same update. The next pattern's row 0 therefore starts with no gap.

## 2. Timing

- Updates run at ≈29.9 Hz. This was measured in an emulator: exactly 300 updates per 600 frames once the game is running.
- With no shuffle a row takes `256 / (2·speed)` updates, so **rows/s = speed × 0.2333**. The data uses speed `$16–$40`, which is 5.1–14.9 rows/s. `$40` gives one row every 2 updates.
- **Shuffle** (`FC phase, depth<<4|rate`) multiplies the per-update increment by `ShuffleTable[depth][phase>>8] / 32`. Depth 0 is flat (×1). Depth 15 swings from ×0.06 to ×1.94. The 12-bit phase advances by `$1000/(rate+1)` per row, so the swing repeats every rate+1 rows (the tracker help says "7 repeats in 8 lines"). Rate 0 freezes the phase.
- The tracker updates once per frame (60 Hz; measured on the tracker ROM). This driver updates at half that rate and stores speed doubled (`sla a` in three places), so **rows play at the tracker's tempo, but every per-update effect runs at half the tracker's rate**. That covers vibrato, portamento, arpeggio, auto-pan/PWM, trigger and retrigger delays.

## 3. Data format

### Song header (at the song pointer)

| Off | Size | Content |
|---|---|---|
| +0 | word | sequence offset from song start |
| +2 | word | pattern-table offset from song start |
| +4 | word | song length in bytes (matches the real extent for all 20 songs) |
| +6 | byte | number of patterns |
| +7 | n | song name, terminated by `$00` or `$FF` (the driver ignores bytes +4 onwards) |

### Sequence

| Byte | Args | Effect |
|---|---|---|
| `00–FA` | – | play pattern n |
| `FB` | p | pan: CH*k* = p & (`$11` << k) |
| `FC` | phase, dr | shuffle (as above) |
| `FD` | t | song transpose (signed semitones) |
| `FE` | s | speed (stored ×2) |
| `FF` | – | restart: reload the header and read the sequence from the top |

Every song ends in `FF`, so all 20 loop, including the short jingles. Starting a pattern clears every channel's wait count and macro return.

### Pattern table

`npat × 4` words. Each word is an offset **from the pattern table** to that channel's stream. Streams are shared freely: 180 of them are referenced by more than one pattern slot.

### Stream events

| Byte | Channel | Effect |
|---|---|---|
| `$00` | all | **note off**: the channel's NR51 bits are written as 0 this update. The note keeps running and the next note restores pan. Ends the row. |
| `$01–$48` | CH1–3 | **note** n (1 = C2 … 72 = B7). Pitch = `$4000 + n·$80`. Sets the trigger and refreshes freq, pan and NRx1. Ends the row. |
| `$49–$7F` | CH1–3 | empty row (ends the row, no effect; not used) |
| `$01–$7F` | CH4 | **noise**: bit 6 = 7-bit LFSR, bits 0–5 = noise index. Ends the row. |
| `$80–$BF` | all | **wait**: end this row and skip `n = b & $3F` more |
| `$C0–$FF` | all | command (below), then keep reading |

A pattern ends as soon as **any** channel reads `FF`. That makes its length the shortest stream's row count. In 31 patterns the four streams have different lengths, and the longer ones are cut off. Channels later in the CH1→CH4 order than the one that hit `FF` still read their row for that tick, and the next pattern's row 0 then follows in the same update.

### Commands

| Byte | Args | Macro | Effect |
|---|---|---|---|
| `D3` | lo, hi | `call_macro` | Call a macro at `wPatTable + hi:lo`, one level deep. `FF` returns. A nested D3 is ignored. Not used in any song. |
| `D4` | steps, rate | `auto_pwm` | CH1/2: cycle the duty through four 2-bit steps every `rate` updates. Rate 0 = off; NRx1 is rewritten from its shadow (the `EA` duty). |
| `D5` | steps, rate | `auto_pan` | Cycle the pan through four 2-bit steps (00 off, 01 R, 10 L, 11 C). |
| `D6` | n | `wave_dist` | CH3: map every nibble of the wave buffer through `WaveDistTables[n]`. n = type·16 + gain, with 8 types and gain 8 = unity. |
| `D7` | preset, step | `wave_mix` | CH3: average the buffer with a preset resampled at step/32 nibbles per output nibble |
| `D8` | – | `stop_sample` | CH3: no-op (the tracker stopped its sample player here) |
| `D9` | – | `reset_vib` | Vibrato phase = 0 |
| `DA` | n | `wave_preset` | CH3: load wave preset n into the buffer |
| `DB` | f | `fine_tune` | CH1–3: signed fine tune, 1/64 semitone (`$40` = +1 semitone) |
| `DC` | n | `play_sample` | CH3: stub (see section 7) |
| `DD` | s12, s34, rate | `arpeggio` | Four 4-bit semitone steps, one step per `rate` updates. Rate 0 = off and resets the transpose. |
| `DE` | b | `glissando` | Round the final pitch to the nearest semitone (CH4: also selects the LFSR width) |
| `DF` | note | `porta_src` | Set the current pitch to `note` without triggering. The next note slides from there. |
| `E0` | r | `porta_rate` | Portamento: 2r pitch units (r/64 semitone) per update, 0 = off |
| `E1` | depth, rate | `vibrato` | Depth `$00–$1F` (0.12–24 semitones, the tracker help table). Phase step = rate, with 64 steps per cycle. `$40` is fastest; values above `$40` run backwards. |
| `E2` | – | `restart_env` | Retrigger on the next frequency write |
| `E3` | n | `retrig_delay` | Restart the note every n updates (0 = off) |
| `E4` | n | `trig_delay` | Delay each row by n updates (not used) |
| `E5` | b | `use_duration` | 0 = infinite, else set NRx4 length enable |
| `E6` | v | `sweep` | CH1: NR10 (not used) |
| `E7` | v | `env_volume` | NRx2 high nibble. CH3: NR32 = v. |
| `E8` | v | `env_rate` | NRx2 low nibble. CH3: NR32 = v. |
| `E9` | v | `duration` | NRx1 length bits. CH3: NR31 = v. |
| `EA` | v | `duty` | CH1/2: NRx1 duty bits |
| `FB` | p | `pan` | This channel's pan = p & (`$11` << ch) |
| `FC` | phase, dr | `shuffle` | Global shuffle |
| `FD` | t | `transpose` | Track transpose (signed semitones) |
| `FE` | s | `speed` | Global speed |
| `FF` | – | `end_pattern` | End of pattern, or return from a macro |
| others | – | – | 1-byte no-ops (`$C0–$D2`, `$EB–$FA`) |

Usage across all songs: 18,046 waits, 13,399 notes, 9,055 noise hits, 11,712 `E7`, 3,504 `E2`, 2,211 `DA`, 1,825 `E1`, 1,013 `D6`, 940 `E0`, 464 `D4`, 419 `DD`, 255 `D5`, and only one `D7`. `D3`, `D8`, `DC`, `E4` and `E6` never occur.

## 4. Pitch, period and the synth tables

- **Final pitch** = `CH_PITCH` + (song transpose + track transpose + arpeggio step)·`$80`. Glissando rounding is applied next, then the vibrato table entry, then fine tune·2 (CH1–3). The result is clamped to `$4000–$647E` and used **as an address** into the period table in bank $0A. One word per even pitch value gives 64 periods per semitone.
- **Noise**: index = `(pitch − $4000) / $80`, clamped 0–63, then `NR43 = NoiseTable[index]` (| 8 for 7-bit). Transposes, arpeggio and vibrato all work on the noise index.
- **Vibrato tables** (`$4000`): 32 depths × 64 signed words, already scaled to pitch units (depth 0 peaks at ±16, ⅛ semitone; depth `$1F` at ±3072, 24 semitones).
- **Wave presets** (`$5560`): 256 × 16 bytes, grouped as the tracker help describes ("sine feedback", "sine to square" … "bad speakers", "sine width fun"). `$6560–$675F` is an exact copy of presets 0–31. It is a guard for `D7`, whose resampling can read past the chosen preset.
- **Distortion tables** (`$5160`): 128 tables of 16 nibbles, 8 types (magneto, SF dirt, SF fuzz, SF hard clip, lofi, HKN, wavewarm, mangle) × 16 gains.

## 5. RAM

| Address | Name | Use |
|---|---|---|
| `$CA00` | wSongNum | current song |
| `$CA01` | wSongBank | its bank |
| `$CA02` | wPatTable (2) | absolute pattern-table address |
| `$CA04` | wSeqPtr (2) | next sequence byte |
| `$CA06` | wTickAcc | row accumulator |
| `$CA07` | wSpeed2 | speed × 2 |
| `$CA08` | wSongTranspose | |
| `$CA09` | wCurChan | low byte of the struct being processed |
| `$CA0A–$CA0E` | shuffle rate×2, table pointer, 12-bit phase | |
| `$CA0F` | wSeqAdvance | bit 0 = a channel read `FF` |
| `$CA10` | wCh3Reload | forces a CH3 wave reload; never set |
| `$CA11`, `$CA12` | mix step, sample number | |
| `$CA20` | wWaveBuf (16) | working waveform |

Channel structs `$CA30` / `$CA64` / `$CA98` / `$CACC`:

| Off | Name | Off | Name |
|---|---|---|---|
| +00 | stream ptr (2) | +13 | vibrato table ptr / phase (2) |
| +02 | current pitch (2) | +15 | vibrato rate |
| +04 | portamento target (2) | +16 | arpeggio steps (2) |
| +06 | note pitch (2) | +18/+19 | arpeggio counter / rate |
| +08 | pan bits | +1A | portamento rate |
| +09 | NRx1 shadow | +1B | fine tune |
| +0A | NRx2 shadow | +1C–1E | auto-pan steps / rate / counter |
| +0B | ctrl: b7 trigger, b6 length enable, b1 sample, b0 glissando/LFSR | +1F–21 | auto-PWM steps / rate / counter |
| +0C | NR10 shadow (CH1) | +22 | macro return (2) |
| +0D | effective transpose | +24 | wait rows |
| +0E | track transpose | +27 | dirty: b0 freq, b1 pan, b2 NRx1, b3 NRx2, b5 wave/sweep, b7 mute |
| +0F | rows pending | +25/26, +28–33 | unused |
| +10/+11/+12 | trigger delay / countdown / retrigger | | |

Game-side: `$C320` toggles each VBlank (update when 1), `hFF86` holds the current bank, and `hFF89` is the tracker's "sample playing" flag (always 0 here).

## 6. Songs

| # | Range | Name | Patterns | Seq length | Rows per loop | First speed (rows/s) |
|---|---|---|---|---|---|---|
| 0 | `09:7CA0–7CCF` | TEMPLATE | 1 | 1 | 64 | $16 (5.1) |
| 1 | `0E:72EF–7DAC` | MORPH2 | 10 | 28 | 1396 | $20 (7.5) |
| 2 | `0C:6962–7F1B` | AINTUS | 14 | 14 | 1008 | $20 (7.5) |
| 3 | `0B:4000–4F33` | INTROA | 14 | 14 | 808 | $20 (7.5) |
| 4 | `0F:6990–7778` | INTRO2 | 9 | 9 | 416 | $20 (7.5) |
| 5 | `0E:566B–72EE` | WANDERIN | 23 | 31 | 2204 | $40 (14.9) |
| 6 | `0B:4F34–506F` | MORPH3 | 1 | 1 | 64 | $18 (5.6) |
| 7 | `0D:5181–6126` | DBASS | 14 | 16 | 976 | $20 (7.5) |
| 8 | `09:7B54–7C9F` | MORPH | 1 | 1 | 64 | $18 (5.6) |
| 9 | `0D:4000–5180` | ILLUSION | 7 | 7 | 1048 | $40 (14.9) |
| 10 | `0D:6127–7178` | SHATURATOR | 12 | 18 | 604 | $20 (7.5) |
| 11 | `0C:4000–51BA` | JOURNEY | 21 | 35 | 1824 | $40 (14.9) |
| 12 | `0C:661E–6961` | WORLD1 | 1 | 1 | 112 | $36 (12.6) |
| 13 | `0C:51BB–661D` | STEPUP | 16 | 16 | 1936 | $20 (7.5) |
| 14 | `0D:7179–7EDD` | SHITSACK | 8 | 20 | 1216 | $20 (7.5) |
| 15 | `0A:6480–7B8E` | SOPHISTO | 19 | 30 | 2252 | $40 (14.9) |
| 16 | `0B:5070–66AE` | MISSIONC | 25 | 29 | 1888 | $20 (7.5) |
| 17 | `09:74BC–7B53` | ULOSE | 3 | 3 | 304 | $20 (7.5) |
| 18 | `0E:4000–566A` | FAGGAGS | 23 | 26 | 1664 | $34 (12.1) |
| 19 | `0B:66AF–7AA5` | MISSIONA | 15 | 15 | 816 | $20 (7.5) |

Names are the tracker's internal song names, exactly as stored in the ROM. Many songs change speed and shuffle between patterns. "Rows per loop" sums each pattern's played length (its shortest stream).

**Callers.** These pass the song number as an immediate:

- 0: boot, through `PlaySongCold` (an empty song)
- 2: 0:`$2DFC`
- 3: 0:`$1DD7`, `$2D23`
- 4: `3F:4E9E`
- 6: `3F:422B`
- 7: `3F:48B7`
- 8: `3F:420F`
- 10: 0:`$1DE4`, `$2D31`
- 12: `3F:41D0`
- 17: `3F:5DB5`
- 19: `3F:6D32`

The remaining songs come from data:

- 0:`$104F` takes the first byte of the current area's record and skips the call if that song is already playing.
- 0:`$14D8` restores a song saved at `$C336`.
- 0:`$2DEE` and `3F:59FF` pass a register.

In an emulator, the boot and title sequence played 0, 7, 4, 12 and then 5.

## 7. Quirks and bugs

1. **Rising portamento skips its last semitone.** At `$7148`, `jr nc` stands where `jr nz` was meant. When the high bytes of the current and target pitch are equal, the slide always subtracts, lands below the target, and snaps to it. Note pitches are multiples of `$80`, so a rising slide to an **odd** note jumps the last semitone in one update. Falling slides and slides to even notes are fine. Confirmed in an emulator (`$51F8 → $5200 → $5280`). The unreachable code after the branch (`$714A–$7150`) has the same `jr c`/`jr nc` pattern.
2. **Arpeggio steps can be lost.** The frequency is only rewritten while `CH_ARP`, the current and next step, is nonzero. A rotation where both are 0 writes nothing, and the previous step's pitch is held. `0,C,C,0` (an octave pattern used in song 1 CH3, among others) plays as 0,C,C,C. 49 of the 163 active arpeggios have two adjacent zero steps. Vibrato or portamento on the same channel forces the write and hides the bug. Confirmed in an emulator.
3. **The high pitch clamp only works when the low byte is ≥ `$7E`.** At `$73BC` a pitch of `$6500` or above with a low byte below `$7E` passes unclamped and reads song 15's bytes as a period. The highest case in the data (song 2 pattern 3 CH3: E7 + 12 + arpeggio 12, approached by a slow slide) never got past `$6480` in an emulator, so the data appears not to hit this.
4. **Argument-count mismatches.** On CH3/CH4, `D4` skips one of its two operands. On channels other than CH3, `D6` skips two bytes for its one operand. Either would desync a stream. The data only uses them on their proper channels.
5. **Pattern length = shortest stream.** 31 patterns have streams of different lengths. Commands placed before a long stream's `FF`, which are often cleanup like `porta_rate 0` or `transpose 0`, never run when another stream ends first.
6. **Note off is a pan mute.** `$00` zeroes the channel's NR51 bits for one write. With auto-pan running, the next update writes the pan again, so the mute lasts one update. No pattern in the data puts an off after an active auto-pan.
7. **The retrigger keeps the trigger bit set.** While `E3` is nonzero, the trigger bit is never cleared, so every frequency write retriggers. That includes every update when vibrato or arpeggio is active. `E3` is used only 9 times, all on CH4.
8. **Samples are stubbed.** `DC` sets the CH3 sample flag and calls `SndBankRestore`, which only selects bank 9. While the flag is set (until the next note), CH3 retriggers also go to the stub. `D8` does nothing, `hFF89` is never set, and `SndTimerInit` programs a 128 Hz timer with its interrupt disabled. None of this is reached by the data.
9. **Leftovers.** `wCh3Reload` (`$CA10`) is checked every update but never set. Dirty bit 4 is set by notes and `E5` but never tested. `SndUnusedRet` (`$6A29`) and `FarSndUpdate` (`$064E`) are unreferenced. `wShuffleRate` isn't reset on song start (only a `FC` sets it).
10. **The CH4 LFSR width shares the glissando bit.** `DE` on CH4 toggles 7-bit noise, and any noise byte with bit 6 set turns on glissando rounding for that channel.

## 8. Differences from the tracker v0.14 player

All of the following were found by an instruction-level diff of bank 9 against the tracker's bank $10, with the RAM base normalised (`$C0xx` → `$CAxx`):

- **Song source.** The tracker plays one song copied to WRAM `$D000`. This driver adds `SongPtrTable`/`SongBankTable`, and every sequence and stream read goes through the bank-0 bank-switching readers.
- **Tempo.** Speed is stored doubled in `SndPlaySong`, sequence `FE` and stream `FE`, to make up for the 30 Hz update.
- **Init** also sets `CH_CTRL = $40` (length enable) on all channels.
- **Samples removed.** `D8` and `DC` no longer call the tracker's sample stop/play routines.
- **Editor hooks removed**: the row counter, sequence position and per-channel pattern pointers kept for the display (`$C2D4–$C2E5`), "play looping" and play-mode flags (`$C2E8/E9/EE`), and the trigger flags used for the VU meters (`$C2EB–$C2ED`).

Bugs 1–4 and 10 are in the tracker's player too. The code there is identical.

## 9. Caveats

- The command semantics come from the code. The names follow the tracker's own help screens.
- Emulator checks (PyBoy) covered the update rate, bugs 1 and 2 (on patched test ROMs), the song order at boot and title, and a probe of bug 3. Everything else is static.
- "Not used" counts are taken from walking every pattern reachable from the 20 pattern tables. All 20 songs' bytes are fully accounted for, with no gaps, and there are no unreferenced patterns.

## Files

- `Animorphs_SoundDriver.asm`: RGBDS source, byte-exact. It holds all code and tables plus the 20 songs as sequence and stream macros (needs `hardware.inc`, included).
- `Animorphs_SongData.txt`: every song decoded row by row: sequence, patterns with played lengths, per-channel rows and commands, plus a coverage report.
- `tools/faparse.py`: song walker (`faparse.py ROM [--json out.json]`)
- `tools/mkasm.py` + `comments.py` + `asm_header.inc` + `z80tab.py`: the `.asm` generator
- `tools/verify.py`: compares a rebuilt ROM against the original over the driver ranges
