# On the Tiles – Franky, Joe & Dirk (GB): sound driver

ROM: `On the Tiles - Franky, Joe & Dirk (E) [!].gb` (MBC1, 128 KB). Developer: Audio Visual Magic, publisher: Elite Systems, 1993. The credits name Gavin Wade (code), Chris Warren (art) and Scott Walsh (design). No one is credited for music.

| | |
|---|---|
| API | bank 1: `SndInitSong` `$4008`, `SndPlaySfx` `$4157`, `SndStopMusic` `$4179`, `SndReset` `$4139`, `SndSetSfxTable` `$412E`, `SndUpdate` `$41A4` (+ unused `SndHaltMusic` `$4000`, `SndFadeOut` `$4199`) |
| Game glue | `PlaySfx` 0:`$1B42` (C = SFX number) and inline bank switches around each call |
| Driver code | bank 1 `$4000–$4A90` |
| Tables / songs / instruments / SFX | bank 1 `$4A91–$615E` |
| Tick | VBlank handler (0:`$2E8E`) calls `SndUpdate` at 0:`$2E9E`. Every 6th call is skipped, so music **and** SFX run at 50 ticks/s |
| RAM | `$C8AB–$C9C3` (plus game flags `$C8AA` music on, `$C2D8` SFX off, `$C2D1` current song id) |
| Songs / SFX | 4 songs, 17 SFX slots (15 distinct effects, 2 empty) |

`OnTheTiles_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 for both ranges (0:`$1B42–$1B5F`, 1:`$4000–$615E`). It assembles cleanly with `-Wall`.

```
rgbasm -o snd.o OnTheTiles_SoundDriver.asm
rgblink -p 0xFF -o snd.gb snd.o
```

---

## 1. Architecture

This is a **MOD-style tracker player**, unrelated to the Distinctive/Radical family or the World Cup USA '94 driver. Each song is a small ProTracker-like module: a 128-entry order list, patterns of 64 rows, up to 15 instruments, and the effect numbers 0, 1, 2, B, C, D and F with their MOD meanings. Effect C's `$00–$40` volume range is mapped to 0–15 through a table. The 5-in-6 frame divider gives 49.8 ticks/s, so speed 6 is the usual 125 BPM of a PAL MOD. It looks like the music was written in a tracker and converted.

- **Three voices**, each tied to one channel: voice 0 → CH1, voice 1 → CH2, voice 2 → CH3 (wave). There is no fourth pattern channel. **CH4 is borrowed** by whichever voice plays an instrument with a noise burst. The noise volume follows that voice's envelope.
- **Voice processing.** Each tick, `SndUpdate` copies a voice's `$34`-byte block into a work area (`wCur`, `$C8CF`) with a fully unrolled copy loop. It then runs `SndReadRow` (row ticks only) and `SndVoiceTick` on it and copies it back. The voices are identical apart from six constants (`VoiceConfig`, `$4BB1`) that say where to write the period and volume and which mask bits belong to the voice.
- **Mix buffer.** Voices never touch the hardware. They write periods, volumes, a noise index and an enable mask into `wMix` (`$C9A5`, 15 bytes). `SndMixSfx` copies that to `wOut` (`$C9B5`), and a running SFX overwrites CH2's entries there. `SndWriteHardware` then writes `wOut` to the APU.
- **Volumes without envelopes.** NRx2 always gets `volume << 4` with envelope step 0. The channel is retriggered only when the volume changes. The period is written every tick without the trigger bit.
- **CH3 as a fourth "pulse" channel.** NR32 stays at 100 %. When the voice-2 volume changes, the driver switches the DAC off and fills wave RAM with a square wave of that amplitude: samples 0–7 and 16–23 = level, the rest 0. That gives two cycles per 32 samples, so the same period table works as for CH1/CH2. It then switches the DAC on and retriggers.
- **Stereo.** NR51 = `$DB`: CH1 and CH4 both sides, CH2 right only, CH3 left only.
- **SFX** are per-tick register streams on CH2 (plus optionally CH4). There is only one SFX at a time, with no priority. A new SFX replaces the old one, and music voice 1 keeps running silently underneath.

### Per-voice block (`$34` bytes: voice 0 `$C904`, voice 1 `$C938`, voice 2 `$C96C`; work copy `$C8CF`)

| Off | Name | Use |
|---|---|---|
| +00 | RowPtr (2) | pattern stream pointer |
| +02..+07 | PeriodSlot, VolSlot, Tone on/off masks, Noise on/off masks | from `VoiceConfig` |
| +08/+0A/+0C | InsPitch, InsNoise, InsEnv (2 each) | instrument table pointers (0 = none) |
| +0E/+0F/+10 | InsVibSpeed, InsVibDelay, InsVibOn | instrument vibrato |
| +11 | InsBurst | noise burst ticks \| `$80` |
| +12/+14/+16 | PitchPos, NoisePos, EnvPos (2 each) | table cursors, reset on note-on |
| +18/+19/+1A | VibTimer, VibDelay, VibState | vibrato runtime (bit 0 = waiting, bit 1 = running) |
| +1B | Burst | noise burst countdown |
| +1C | RowFlags | bit 0 = inside a run of empty rows, bit 1 = portamento, bit 2 = porta up |
| +1D | SkipCount | empty rows left |
| +1E | InsTranspose | instrument transpose |
| +1F | Note | current note (FreqTable index) |
| +20 | Period (2) | current period |
| +22/+23/+24 | NoiseNote, NoiseOut, InsNoiseVal | noise index machinery (dead, see §5) |
| +25 | Instr | current instrument (`$FF` after init) |
| +26/+27 | ArpParam, ArpPhase | effect 0 |
| +28 | PortaSpeed | effect 1/2 |
| +29/+2B | EnvTimer, EnvVol | envelope |
| +2A/+2C | VolSet, Atten | effect C (attenuation = 15 − volume) |
| +2D (2) | – | never used |
| +2F | InsFineVol | instrument +5, added by effect C |
| +30/+31/+32 | VibPhase, VibDepth, VibOffset (2) | vibrato output |

Globals (all named in the `.asm`): `$C8AB` module base, `$C8AD` order list pointer, `$C8AF` pattern table pointer, `$C8B1` instrument table, `$C8B3` SFX table, `$C8B5` extended-format flag, `$C8B6` song transpose, `$C8B7` music stopped, `$C8B8` speed, `$C8B9` speed counter, `$C8BA` row-tick flag, `$C8BB` row, `$C8BC` order position, `$C8BD` length, `$C8BE` restart, `$C8BF/$C8C0` pending jump, `$C8C1–$C8C3` fade, `$C8C4–$C8C7` row decode, `$C8C8` frame divider, `$C8C9/$C8CA` SFX on/pointer, `$C9A0–$C9A4` last values written to the hardware.

---

## 2. Song format

`SndInitSong` gets HL = song and DE = instrument table. The game always passes `$5CB0`.

```
[$FF, transpose]      optional prefix; sets "extended format" (13-byte instruments). All 4 songs have it.
module+$00  length        order list length
module+$01  restart       order position used after the last one
module+$02  word          offset of the first pattern     (not read by the driver)
module+$04  word          module size                     (not read by the driver)
module+$06  128 bytes     order list (pattern numbers)
module+$86  words         pattern offsets from the module base, then the end offset, then 0
pattern+0   word, word    offsets of the voice-1 and voice-2 streams (stream = pattern + offset + 4)
pattern+4                 voice-0 stream
```

Each voice stream holds exactly 64 rows (the decoder checks that every stream ends where the next begins):

| Bytes | Meaning |
|---|---|
| `1nnnnnnn` | n empty rows. `$80` and `$81` both mean one row. Data uses `$81`–`$A9`. |
| `0?nnnnnn iiiieeee pp` | note n (`$3F` = none; bit 6 ignored, never set), instrument i (0 = keep), effect e, parameter pp |
| `0?nnnnnn iiii0111` | effect 7: same, but **two bytes**, with no parameter. 814 rows use this compact form. |

Note n + song transpose + instrument transpose indexes `FreqTable` (96 periods, 0 = C2). Row notes in the data span C3–A5.

### Effects

| Fx | Effect | Driver behaviour | Uses |
|---|---|---|---|
| 0 xy | arpeggio | Tick phases 1, 2, 0 give note+x, note+y, *no write*. The note itself is never played unless y = 0 (§5.2). Lasts one row. | 156 (`$47`, `$70`) |
| 1 xx | porta up | period += xx every tick, including the note-on tick. No limit. | 11 |
| 2 xx | porta down | period −= xx every tick | 4 |
| 7 | – | nothing; marks a 2-byte row | 814 |
| 8 | stop | music stopped, mix volumes 0, **NR50 = NR51 = 0**; rest of the row skipped | 1 (end of song 3) |
| B xx | position jump | jump to order xx after this row (§5.4) | 0 |
| C xx | volume | attenuation = 15 − (`VolumeTable[xx]` + instrument fine volume). Applies to the note on that row and resets to 0 on the next note-on without C. | 295 |
| D xx | pattern break | next order, row 0; xx ignored | 0 |
| F xx | speed | ticks per row (no minimum; 0 → 256) | 2 |
| 3–6, 9, A, E | – | ignored (parameter still consumed) | 0 |

Pattern change (end of pattern, B or D) resets the row counter and the empty-row state of all three voices.

### Instruments (13 bytes in extended format)

| Off | Field |
|---|---|
| +0 | transpose (signed) |
| +1, +2 | noise burst: ticks (0 = none) and noise index. While the burst runs, CH4 follows this voice's volume. |
| +3, +4 | vibrato `depth << 4 \| speed` (0 = none) and delay |
| +5, +6 | fine volume (added by effect C), unused byte. These exist only with the `$FF` prefix. |
| +7, +9, +11 | pitch table, noise table, volume envelope (words, 0 = none) |

Loading an instrument first disables the voice's tone and noise. It then enables the tone again only if there is a pitch table, and CH4 only if there is a noise table (or, at note-on, a burst). An instrument number equal to the current one is ignored. The tables restart on every note-on.

- **Pitch / noise table:** signed semitone steps, one per tick, **cumulative**. `$80` = stop, `$81 n` = continue at entry n. For example, `+4 +3 −7, loop` is a major-chord arpeggio instrument, and `−4, loop` is a falling drum pitch.
- **Volume envelope:** `(ticks−1, volume)` pairs, `$FF` = hold.
- **Vibrato:** after the delay, the period offset toggles between 0 and +depth every speed+1 ticks. That is a square wave, and it only bends upwards.

| # | Record | Name in `.asm` | Content | Used in songs |
|---|---|---|---|---|
| 1 | `$5D14` | Ins_Kick | burst 1, pitch −4/tick (C-5 lands exactly on C2 at the last audible tick) | 113 |
| 2 | `$5D2E` | Ins_Snare | transpose +9, burst 1, pitch −4/tick | 108 |
| 3, 8, 9 | `$5D07` | Ins_Bass | transpose −12, vibrato 7/3 after 1 tick, `+6 −6 0` attack blip | 362 (as 3) |
| 4 | `$5CE0` | Ins_Chord | arpeggio table `+4 +3 −7` looping | 103 |
| 5 | `$5CD3` | Ins_Lead | `+12 −12 0` attack, vibrato 2/3 after 5 ticks, long sustain | 335 |
| 6 | `$5CFA` | Ins_Unused6 | transpose +1 variant of 5 | 0 |
| 7 | `$5D21` | Ins_HiHat | transpose +24, burst 1, no pitch table (noise only) | 6 |
| 10, 11 | `$5CC6` | Ins_Null | all zero: mutes the voice | 0 |

The names are my own guesses from the data.

---

## 3. Data layout (bank 1)

| Address | Content |
|---|---|
| `$4A91` | `FreqTable`: 96 period words, C2 (`$02C`) … B9 |
| `$4B51` | `NoiseShiftTable`: 96 NR43 shift values, 6 notes per step. Only the dead code reads it. |
| `$4BB1` | `VoiceConfig`: 3 × 6 bytes |
| `$4BC3` | `VolumeTable`: 77 bytes, effect C `$00–$40` → 0–15; the last 12 are reachable only with `$41–$4C` |
| `$4C10` | Song 1 (22 orders, 4 patterns) |
| `$5175` | Song 2 (8 orders, 3 patterns) |
| `$5610` | Song 3 (1 order, 1 pattern, 24 rows then effect 8) |
| `$570F` | Song 4 (6 orders, 4 patterns) |
| `$5CB0` | `InstrumentTable`: 11 words |
| `$5CC6–$5D3A` | 9 instrument records (one unreferenced) |
| `$5D3B–$5DBC` | pitch tables and volume envelopes |
| `$5DBD` | `SfxTable`: 17 words |
| `$5DDF–$615E` | SFX frames |

Each song ends with one `$00` pad byte, and the pattern table's end offset points at it. The next byte starts the next song or the instrument table. Game data follows at `$615F` (a pointer table, then "LEVEL COMPLETE").

### Songs

| # (`$C2D1`) | Song | Started from | Notes |
|---|---|---|---|
| 1 | `$4C10` | 0:`$0293` (boot, when music is on), 0:`$26A0` (MUSIC ON toggle) | title/menu music; `F05` on the first row. Confirmed playing at boot in an emulator. |
| 2 | `$5175` | 0:`$2D25` | loops |
| 3 | `$5610` | 0:`$0B52`, 0:`$19C6` | jingle; ends with effect 8. 0:`$0B52` runs after a 49-byte comparison at 0:`$0B24` succeeds, possibly the level-complete check (not verified). |
| 4, 5, 6 | `$570F` | 0:`$07A6/$07AD/$07B4` | level music. The id comes from a 32-entry level table at 1:`$6807` (values 4, 5, 6), but all three ids load the **same** song. Confirmed at level start in an emulator. |

Every start is guarded by `wMusicEnabled` (`$C8AA`). Songs 1–3 are also skipped when `$C2D1` already holds their id; the level-start path always restarts song 4.

### SFX (`SndPlaySfx`, CH2 + CH4)

Each frame is 3 bytes `c, d, e`, one per tick:

- `c`: bits 4–7 = CH2 volume; bits 0–3 = period high, inverted
- `d`: period low, inverted
- `e`: bit 7 = noise on (index e & `$1F`, volume = CH2 volume); bit 6 = tone on; bit 5 = last frame

The driver computes the period as `((~c & $15) & 7) << 8 | ~d` (§5.3).

| # | Address | Frames | Content | Callers (`ld c,n` before `call PlaySfx`) |
|---|---|---|---|---|
| 0, 11 | `$5DDF` | 1 | empty (`00 00 20`) | none |
| 1 | `$6060` | 26 | noise sweep 30→10, fade | none found |
| 2 | `$60AE` | 36 | noise sweep 30→24, long fade | 0:`$1B6B` (after `SndReset`) |
| 3 | `$5F82` | 38 | tone swell | 0:`$1570` |
| 4 | `$5F46` | 20 | tone decay | 0:`$14B8`, `$2B50` (after `SndReset`) |
| 5 | `$5EFE` | 24 | two-tone | 0:`$138B` |
| 6 | `$5EE0` | 10 | two tone+noise hits | none found |
| 7 | `$611A` | 23 | noise hits | 0:`$1482` |
| 8 | `$5E57` | 7 | noise decay (see §6) | 0:`$175D` |
| 9 | `$5E27` | 16 | tone sweep | 0:`$1ACD` |
| 10 | `$5EA4` | 20 | tone blips | 0:`$1187` |
| 12 | `$6021` | 21 | tone trill | 0:`$221B`, `$226A`, `$22BC`, `$2314` |
| 13 | `$5DE2` | 5 | short tone | none found |
| 14 | `$5DF1` | 18 | tone decay | none found |
| 15 | `$5FF4` | 15 | rising tone steps with decaying volume, twice | 0:`$15C5` |
| 16 | `$5E80` | 12 | noise blip | 0:`$2252`, `$22A1`, `$22F9`, `$2351` |

---

## 4. Game interface

- **Boot / options** (0:`$0259…`): if music is off and SFX are on, `SndReset` + `SndSetSfxTable($5DBD)`. If music is on and song 1 isn't already playing, `SndReset` + table + `SndInitSong($4C10, $5CB0)`.
- **MUSIC OFF** (0:`$26B8`) calls `SndStopMusic` and clears `$C8AA`.
- **Pause** (0:`$07F6`) saves NR51, writes 0, and restores it afterwards. It doesn't call the driver.
- **SFX** go through `PlaySfx` (0:`$1B42`), which returns early when `$C2D8` (SFX off) is set.

---

## 5. Quirks and bugs

1. **NR43 is never written, so the noise channel is a single fixed hiss.** In `SndWriteHardware` the noise-frequency check stores `wOutNoise` into `wHwNoiseIdx` **before** comparing the two (`ld [$C9A4],a / cp b`). The compare always matches, and the NR43 write at `$49EB` is unreachable. No other code in the ROM writes NR43, so it keeps its power-on value 0: 15-bit LFSR at the highest clock. All the noise index work (instrument noise values, noise tables, `NoiseShiftTable`, SFX noise indexes) has no audible effect. SFX 1 and 2 were written as noise pitch sweeps (index 30 → 10), but they play as a volume fade of the same hiss. Confirmed in an emulator: NR43 stayed `$00` throughout the title music and the first level.
2. **Arpeggio skips the base note.** The phase counter goes 1 (note+x), 2 (note+y), then 3 → 0 *without* writing a period, so the pattern is x, y, y. The row's own note is overwritten on the note-on tick because the tick routine runs in the same frame. The data uses `047` (84 rows), which plays as major third, fifth, fifth with no root, and `070` (72 rows), which comes out as fifth, root, root. Confirmed in an emulator on song 1 (voice 2, param `$70`: periods cycle note+7, note, note).
3. **SFX period mask.** The period high bits are computed as `(~c & $15) & 7`, which keeps bits 0 and 2 only. Period bit 9 can never be set, so SFX tones are limited to periods `$000–$1FF` and `$400–$5FF`, i.e. **≤ 255 Hz**. If `& 7` was meant, 135 of the 172 tone frames play at a different pitch than intended. If the effects were tuned by ear, the data just follows this formula.
4. **Position jump (B) doesn't update the order position.** `.setOrder` loads the target pattern but leaves `wOrderPos` alone, so play continues from the old position + 1 after the jumped-to pattern. Latent: no song uses B or D.
5. **Stopping mutes the SFX too.** `SndStopMusic` and effect 8 set NR50 = NR51 = 0, and only `SndInitHardware` (via `SndInitSong`/`SndReset`) turns them back on. After song 3 ends, or after MUSIC OFF, SFX are silent until one of those runs. The game calls `SndReset` before SFX 2 and 4 and on its boot/option path, which covers some of these cases.
6. **Every 6th frame nothing runs**, SFX included. Skipped frames stretch SFX by 20 % against their 60 Hz frame count.
7. **Retrigger side effects.** Volume changes retrigger CH1/CH2 through a read-back of NRx4, which reads `$BF`. For a few cycles the period high bits are 7, until the same routine writes the real period. CH4 at volume 0 is written and triggered every tick. Every CH3 volume change rewrites wave RAM with the DAC off, which clicks. None of the three are checked by ear.
8. **Note index wraps in 8 bits.** `FreqTable[note]` uses `note*2` in 8 bits, so notes ≥ 128 wrap, and 96–127 read past the table. The drum pitch tables keep falling after the envelope reaches 0 and do wrap, but only while silent.
9. **Order-list end check is equality only.** A B jump past the end, or a restart value ≥ length, would run through the 128-byte order list into the pattern table.
10. **Dead state.** Voice +`$2D/$2E`, `wMix` bytes `$C9B0–$C9B3`, header words +2/+4, and the pattern table's end and zero entries are never read. The extended-format byte +6 of each instrument is skipped. The `$FF` prefix is effectively mandatory: without it, the shared 13-byte records would be misparsed.

## 6. Unreferenced data

- `$5CED`: instrument record (transpose +12 lead with its own envelope `$5D9D`). Not in `InstrumentTable`.
- `$5D4B` (`FA FA FA 00 80`): pitch table, not used by any record.
- `$5E6C–$5E7F`: second copy of SFX 8. Together with the byte before it (`$5E6B` = `$F0`), it is a complete copy that ends properly in `00 00 20`. The referenced SFX 8 at `$5E57` has no end frame of its own. Its 7th frame (`00 00` + `F0`) takes the copy's first byte as its `e`, and `$F0` has bit 5 set, so it stops there (at volume 0, harmless).
- Instrument slots 6, 8, 9, 10 and 11 exist in the table but no song uses them. SFX 0, 1, 6, 11, 13 and 14 have no caller found.
- `SndHaltMusic` (`$4000`) and `SndFadeOut` (`$4199`) have no callers.

## 7. Verification and caveats

- The byte-exact rebuild covers the driver, the tables, the four songs, the instruments and the SFX. The decoder asserts that every voice stream ends exactly where the next begins, and all 5,838 data bytes from `$4A91–$615E` are accounted for.
- A short PyBoy run (boot → title → first level) confirmed the song-1 and song-4 starts, 50 ticks/s (every 6th frame skipped), the x, y, y arpeggio and NR43 = `$00` throughout. Songs 2 and 3 were not reached, and nothing was checked by ear.
- "No caller found" means no `call`/`ld` of that immediate exists in the ROM. An indirect call would not show up that way.

## Files

- `OnTheTiles_SoundDriver.asm`: labelled and commented RGBDS source with row/instrument/SFX macros and note constants, byte-exact (needs `hardware.inc`, included)
- `OnTheTiles_SongData.txt`: decoded songs as tracker grids, instruments with their tables, all SFX frame by frame with the effective period, and a coverage report
- `tools/otparse.py`: the decoder that produces the `.txt`
