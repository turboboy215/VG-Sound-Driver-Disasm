# Toki Tori (GBC): sound driver

The sound driver of *Toki Tori* (`Toki Tori (U) (M5) [C][!].gbc`, internal title `TOKI TORI`, CGB-only, MBC5, 1 MB). Two Tribes, 2001; the credits name Martijn Reuvers for the music. The sources in `Toki\TokiTori` rebuild every sound region **byte-exact** with RGBDS 0.9.1 (`-Wall` clean).

| Region | Content |
|---|---|
| ROM0 `$3D00–$3FFF` | home-bank part: API, sequencer, row fetch, SFX stream, row-length table (`$3F80`) |
| bank `$2D` | the driver: effect jump tables, channel code, period/wave/LFO tables, song table, SFX |
| banks `$2E–$32`, `$33:$4000–$4604`, `$33:$47C1–$5430` | pattern streams |
| bank `$33` `$5431–$64A0` | the 11 order lists |
| WRAM bank 7 `$DF00–$DFA9` | driver RAM |

```
TokiTori\build_check.sh "..\Toki Tori (U) (M5) [C][!].gbc"   # assemble, link over the ROM, compare
TokiTori\harness\build.sh                                      # test ROM from the rebuilt sources
python TokiTori\harness\verify.py "..\Toki Tori (U) (M5) [C][!].gbc"
python TokiTori\tools\ttgen.py <rom> TokiTori                  # regenerate the sources
```

This is a **module player**. The data is a ProTracker-style conversion: four channels of rows (note, instrument, volume, effect, parameter), patterns of 64 rows (48 in parts of song 3), an order list, a speed in frames per row, and the ProTracker effect numbers `0`–`F` and `E0`–`EF`. It has nothing in common with the drivers documented so far in this project.

---

## 1. API and integration

| Address | Routine | |
|---|---|---|
| `$3D00` | `Sound_SelectBank` | a = `$2D`: stores it in `wSndBank`, maps it, jumps to `Driver_Init` |
| `$3D0A` | `Sound_APUOn` | NR52 `$80`, NR50 `$77`, NR51 `$FF` |
| `$3D1C` | `Sound_Stop` | `Driver_Init`, NR52 = 0, sequencer off |
| `$3D2C` | `Sound_Update` | once per frame |
| `$3D4B` | `Sound_PlaySfx` | a = SFX 0–17 |
| `$3D9E` | `Sound_PlaySong` | a = song 0–10 |

All driver RAM is in **WRAM bank 7**; the caller selects it (`SVBK` = 7) before every call. Data banks are stored relative to `wSndBank`, so the whole sound block could move as a unit.

**Game side.** Boot calls `Sound_SelectBank` with `$2D` (`$077E`) and requests song 4. The main loop waits for LY = `$90` and calls the glue at `$12D7`:

| Variable | Meaning |
|---|---|
| `$C010` | song request: 0–10, `$FE` = stop, `$FF` = none. A song request runs `Sound_Stop`, `Sound_APUOn`, `Sound_PlaySong` |
| `$C00F` | SFX request (`$FF` = none), honoured only if `$C015` ≠ 0 |
| `$C014` / `$C015` | the Music / SFX options (saved to SRAM). Turning music off sets `$C013`, and the glue stops the sound; turning it on requests song 4 |

`Sound_Update` order: `Seq_Tick` (home) → `Sfx_Update` (home) → `Music_Update` → `Sfx_Claim` → `Ch1_Output` … `Ch4_Output`.

---

## 2. Data

### 2.1 Song table (`$2D:$6000`, 11 × 8 bytes)

```
SONG orders, speed, loop      ; db bank-$2D, LOW, HIGH, speed, LOW(loop), HIGH(loop), 0, 0
```

The loop pointer has no bank byte; it's in the order list's bank. Every song loops to its first entry. Songs that end differently do it with `Bxx` in the patterns.

### 2.2 Order list

```
ORDER ch1, ch2, ch3, ch4, rows   ; 4 x (bank-$2D, LOW, HIGH), rows, 0, 0, 0   = 16 bytes
ORDER_END                        ; $FF + 15 zero bytes
```

Each channel has its **own pattern stream**, so an order entry is four independent pointers, not a pattern number. 566 distinct streams are referenced: 159 used on ch1 only, 160 ch2, 164 ch3, 81 ch4, plus 2 silent streams shared by all channels. The 3 zero bytes and the 15 after `$FF` are never read. `Bxx` addresses entries as `start + xx × 16`.

### 2.3 Rows

A row is variable-length. The first byte decides:

| First byte | Row |
|---|---|
| `$00–$7F` | full row: note (this byte), instrument, volume, effect, parameter (5 bytes) |
| `$80–$9F` | mask; one byte follows for each set bit: bit 0 **N** note, 1 **I** instrument, 2 **V** volume, 3 **X** effect, 4 **P** parameter |

Macros: `ROW n, i, v, x, p`, `___` (`$80`, empty row), and `R_<bits>` for each mask (`R_NI`, `R_V`, `R_XP` …).

- **X without P** gives parameter 0. **P without X** is effect 0 (arpeggio) with that parameter.
- **N or I without V sets the volume to `$3F`.** Like a MOD, a note with a sample resets the volume.
- Any N, I or V sets `RETRIG` = 1, so the channel is retriggered on that frame's output (§3.3).
- `Seq_FetchRow` copies at most 4 bytes after a mask. A mask with all five bits (`$9F`) would leave its 5th byte to be read as the next row. No row uses it.

Rows used: 31 full rows; the rest are masks (`$80` 13,069 times, `$87` 4,768, `$88` 3,768, `$83` 3,701 …).

**Notes** index a 72-entry period table, C2 (0) to B7 (71). The data uses 1–55. On ch4 the note byte is skipped (§3.4).

**Instrument** is a register value, not an instrument number:

| | Instrument column | Used |
|---|---|---|
| ch1, ch2 | written to NRx1 (duty in bits 6–7; length is never enabled) | `$00 $40 $80 $C0`, `$02` once |
| ch3 | wave number (swapped into a `WaveTable` offset) | 0–7, `$80` twice |
| ch4 | written to NR43 | `$22`, `$50` |

**Volume** is 0–`$3F` (the data has up to 64).

---

## 3. Engine

### 3.1 Sequencer timing

`wTickCounter` counts down the frames of a row. On the frame where it goes from 2 to 1, `Seq_Tick` **fetches the next row** of all four streams into the channels' `ROWBUF`. On the next frame it reaches 0: it reloads to `wSpeed`, sets `wRowFrame`, and decrements `wRowsLeft`; at 0 it loads the next order entry. `Music_Update` then decodes the four buffers.

- On a **row frame** only the row decoders run (ch1, ch2, ch3, ch4). On the other frames each channel's tick effect A (pitch) runs, then each channel's tick effect B (volume). This matches ProTracker ticks 1 … speed−1.
- After `Sound_PlaySong`, the first row frame decodes the `$80` that `Driver_Init` left in the buffers, so every song starts with one empty row.
- With speed 1 the counter never passes through 1, so **no rows are ever fetched**: the buffered rows repeat. The data's lowest speed is 2.

### 3.2 Effects

`ChN_ReadRow` first clears both tick effects, so an effect only lasts for its own row. The effect byte indexes a 32-entry table per channel (`ChN_RowFxTable`). The handler may set tick effect A or B, which index a 12-entry `ChN_TickFxTable` (`TFX_*`).

**Pitch** is note + `FINETUNE`/16 semitone. `FINETUNE` (8 = in tune) selects one of 16 period tables (`$2D:$4800 + ft × $100`); table *f* is tuned (*f* − 8)/16 semitone from equal temperament, A4 = 440 Hz. At ft 8 the notes in use are within 17 cents.

| Fx | Name | Row | Each tick |
|---|---|---|---|
| `0xy` | arpeggio | xy ≠ 0: start, count 2 | count down: base, +x, +y in the order shown below |
| `1xx`, `2xx` | slide up / down | xx ≠ 0: store speed | (note, finetune) ± xx/16 semitone, **kept** afterwards |
| `3xx` | tone portamento | xx ≠ 0: speed; set the period to the previous note | slide the previous note toward the new one; at or past it: finetune 8, period = target |
| `4xy` | vibrato | x speed, y depth (0 keeps the old value); phase isn't reset | phase += x (64 steps), period from (note, finetune + `VibratoTables[y][phase]` − `$10`) |
| `5xy` | porta + volume slide | xy → volume slide; porta direction from the notes | both |
| `6xy` | vibrato + volume slide | xy → volume slide | both |
| `7xy` | tremolo | x speed, y depth, base = current volume | phase += x (32 steps), volume = base + 4 × (`TremoloTables[y][phase]` − 8), retrigger |
| `Axy` | volume slide | xy ≠ 0: store | +x (if x ≠ 0) else −y, retrigger |
| `Bxx` | position jump | next entry = `start + xx × 16` | |
| `Cxx` | set volume | volume = xx, retrigger | |
| `Dxx` | pattern break | next row frame comes at once, then the next entry (xx ignored) | |
| `Fxx` | speed | `wSpeed` = xx | |
| `E1x`, `E2x` | fine slide up / down | store x | one tick of slide (shares the 1xx/2xx speed) |
| `EAx`, `EBx` | fine volume slide | store x as the slide value | see quirk 4 |
| `8`, `9`, `E`, other `Ex` | — | no-op | |

**Arpeggio order.** On the row frame the base note plays; then the ticks give +x, base, +y, +x, base, +y …

**Pitch slides aren't clamped**: `NOTE` can leave 0–71, and then `SetFreq` reads past the table. `2xx` handles the borrow correctly.

Effects in the distinct pattern streams: `4` (3,905 times), `0` (5,077, mostly parameter 0, which does nothing), `F` (1,569), `A` (725), `3` (136), `2` (111), `D` (20), `B` (7). `1`, `5`, `6`, `7`, `C` and all `Ex` are unused.

### 3.3 Output

Each frame `ChN_Output` checks `SFXFLAG` (§3.5), then counts down `RETRIG`:

- **At 0** it retriggers the channel and reloads `RETRIG` to **110 frames**, so a held note also restarts every 110 frames.
- **On other frames** it writes only the period (NRx3, and NRx4 without the trigger bit). Vibrato, slides and portamento therefore never restart the note.

A retrigger writes:

| Channel | Writes |
|---|---|
| ch1 | NR10 = 0, **NR12 = (3 × vol) & `$F0`**, NR13, NR11 = instrument, NR14 \| `$80` |
| ch2 | **NR22 = (2 × vol) & `$70`**, NR21 = instrument, NR23, NR24 \| `$80` |
| ch3 | NR30 = 0, NR32 = `Ch3VolTable[vol]`, NR31 = 0, the 16 wave bytes, NR33, NR30 = `$80`, NR34 \| `$80` |
| ch4 | NR41 = `$FF`, **NR42 = (2 × vol) & `$70` \| 1**, NR43 = instrument, NR44 = `$80` |

- **No envelopes.** NR12 and NR22 have envelope period 0, so volume changes work by retriggering. That is why every volume effect sets `RETRIG` = 1 on every tick; on ch3 each one also turns the DAC off and reloads the wave.
- **Levels.** At volume `$3F`, ch1 gets level 11 and ch2 level 7; ch2 and ch4 never pass 7.
- **Ch3 levels.** `Ch3VolTable` (256 entries) maps volume 0 → mute, 1–16 → 25 %, 17–32 → 50 %, 33+ → 100 %.
- **Ch4 decay.** NR42 always decays (period 1), so a noise note is a short hit.
- **Panning.** There is none: NR51 stays `$FF`.

### 3.4 Channel 4

`Ch4_ReadRow` has the same mask logic but **skips the note byte**: the noise pitch is the instrument column (NR43). The ch4 tables implement only `7`, `A`, `B`, `C`, `D`, `F` and `EA/EB`. Ch4 uses its own layout of the 33-byte structure (`CH4_*` in `TT_RAM.inc`).

### 3.5 Sound effects

18 SFX, all in bank `$2D`. `SfxTable` (`$6200`) has 4-byte entries (bank − `$2D`, pointer, 0). Each effect is a list of steps:

```
SFX_STEP frames, channel, regs...   ; db frames, count << 4 | channel, count bytes
SFX_END                              ; db 0
```

`Sfx_Update` reads a step into `wSfxRegs` and sets `wSfxNewChannel`. `Sfx_Claim` then hands that channel to the SFX (`SFXFLAG` = 1), and on its next output the channel writes the registers once: ch1 NR10–NR14 from values 1–5, ch2 NR21–NR24 from values 2–5, ch4 NR41–NR44 from values 1–4. `SFXFLAG` = `$FF` then keeps the music out of that channel. The music keeps decoding rows for the channel; only the output is suppressed.

When the SFX ends (`frames` = 0), or another SFX takes a different channel, the channel goes back to the music with **VOLUME = 0** (§4, quirk 2).

The 18 effects are single 15-frame steps: SFX 0–11 on ch1 (with sweep), 12–17 on ch4. Each one sets length-enable in NRx4, so the hardware length counter ends the sound.

---

## 4. Quirks

1. **Volume 64 is silent on ch2 and ch4.** 2 × 64 = `$80`, and `& $70` gives 0. NR22 = `$00` (or NR42 = `$01`) turns the DAC off. The distinct streams have volume 64 in 8 ch2 rows and 5 ch4 rows; `verify.py` sees 13 such writes, all `$00`/`$01`. On ch1, 64 gives level 12, louder than `$3F`. Upward volume slides clamp to `$3F` only on an 8-bit carry, so they could also wrap. The data has no upward slide that does.
2. **The music comes back silent after an SFX.** `Sfx_Release` and `Sfx_Claim` set the returned channel's `VOLUME` to 0, so it stays silent until a row sets a volume (a note, instrument or V).
3. **Ch3 can't play SFX.** `Ch3_Output` has no `SFXFLAG` check. None of the 18 effects uses ch3.
4. **Fine volume slide repeats.** `ChNTick_FineVol` clears `FXA` instead of `FXB`, so `EAx`/`EBx` slide on every tick of the row, like `Axy`. Unused in the data.
5. **Pattern break replays a row.** `Dxx` forces the next frame to be a row frame, but no fetch happens in between. The other three channels decode **the same row again**: they retrigger, and that copy lasts the full `speed`. Only the breaking channel's buffer is cleared to `$80`. `verify.py` confirms this at all 21 breaks it plays.
6. **Position jump plays one extra row.** `Bxx` only sets the order pointer and `wRowsLeft` = 1, so row *r* + 1 of the old patterns is fetched and played before the jump. The harness sees 33 fetches for a `B` on row 31 and 17 for one on row 15.
7. **`B`/`D` on an entry's last row act one entry late.** On that row frame `Seq_Tick` has already loaded the next entry, before the row is decoded. Two cases:
   - **`B` on the last row** (songs 3, 5, 6): the next entry (the loop to entry 0) plays one row, then the jump happens. The harness confirms this for songs 3 and 5.
   - **`D` on the last row** (song 8, entry 5, a 32-row entry): the already-loaded entry 6 gets no rows at all, apart from the re-decoded row of quirk 5. **Entry 6 is skipped.** Its `B06` on row 63, which was meant to make the song loop to entry 6, never runs, so song 8 loops back to entry 0.
8. **Slide residue.** `1xx`/`2xx` leave `FINETUNE` changed, and the next note uses it. Only a finished `3xx` resets it to 8.
9. **Speed 1 never fetches rows** (§3.1).
10. **Masks with 5 bits** lose their 5th byte (§2.3). An SFX step with count 0 would copy 256 bytes into `wSfxRegs`. Neither occurs.
11. **Unused code:** `ChNFx_VibratoReset_Unused` (`$66AD`, `$6A55`, `$6DFD`) is a vibrato setup that also zeroes the phase. It isn't in any table. There are also four unreachable `ret`s (`$41F6`, `$62DD`, `$64AF`), `wSndUnused01` (set to `$0F`, never read) and `NOTEFLAG` (cleared by notes, never read).
12. **Misaligned waves.** The instrument is swapped into a `WaveTable` offset, so `$80` reads bytes 8–23 (half of wave 0 + half of wave 1). Waves 0–3 and 8–15 are the same ramp, so the two `$80` rows sound normal. Waves 4–7 are pulse shapes.
13. **`FreqTables` finetune 0, note 0** is `$FFE0` (below the hardware minimum). It's unreachable, because the data starts at note 1.
14. **Unreferenced pattern data**: 2,848 valid rows in seven runs that no order entry points to. The runs are `$2E:$4000` (256 rows), `$2E:$7BB4` (256), `$2F:$4364` (576), `$2F:$6B17` (64), `$31:$4BD3` (864), `$32:$5112` (640) and `$33:$4605` (192). They are probably MOD patterns that the converter exported but the order lists don't use. They are emitted as `Unused_BB_AAAA` with row markers; the pattern boundaries inside them aren't known.

---

## 5. Songs

| Song | Orders | Rows | Speed | Patterns in | Requested at |
|---|---|---|---|---|---|
| 0 | 39 | 2,496 | 4 | `$2E` | `$3718` |
| 1 | 30 | 1,920 | 6 | `$2E` | `$3916` |
| 2 | 34 | 2,176 | 4 | `$2F` | `$3A9D` |
| 3 | 45 | 2,704 | 3 | `$30` | `$3B82` |
| 4 | 32 | 2,048 | 4 | `$31` | boot (`$0785`), options (`$27:$43CF`) |
| 5 | 4 | 256 | 5 | `$32`, `$2E` | `$01:$4B9F` |
| 6 | 4 | 256 | 6 | `$32`, `$2E` | `$01:$4BDA` and 4 more in bank 1 |
| 7 | 10 | 640 | 4 | `$32` | `$05F5` |
| 8 | 7 | 416 | 5 | `$32`, `$2E` | `$0632` |
| 9 | 21 | 1,344 | 3 | `$32` | `$0657` |
| 10 | 26 | 1,664 | 3 | `$32`, `$33` | `$06B1` |

The order lists are in bank `$33`. Song titles weren't identified.

---

## 6. Verification

- **Byte-exact rebuild** (`build_check.sh`): `rgblink -O` over the original ROM, plus each region on its own (ROM0 `$3D00–$3FFF`, banks `$2D–$33`).
- **Emulator harness** (`harness\`): a CGB ROM linked from the **rebuilt** objects. It selects WRAM bank 7, waits for LY = `$90` like the game, and calls `Sound_Update`. `verify.py` (PyBoy, CGB mode) plays each song until an order entry repeats, and plays every SFX. PC hooks on `Seq_FetchRow`, the order read and the SFX step read record what the driver reads. Each row fetch must be exactly row *k* of the current entry's stream for that channel (*k* = fetches since the entry loaded), with the parsed length.

  | | Result |
  |---|---|
  | songs | all 11; all 252 order entries loaded (song 8's entry 6 for no rows, quirk 7); 59,464 row fetches, **0 wrong** |
  | SFX | 36 / 36 steps read, 0 wrong |
  | pattern breaks | 21, all followed by a re-decode of the other channels' rows (quirk 5) |
  | volume 64 on ch2/ch4 | 13 writes, all `$00`/`$01` (quirk 1) |

  The unreferenced runs (quirk 14) are never read.
- **Not verified:** which game screens use which song, the arpeggio order and LFO shapes by ear, and anything on hardware.

## Files (`Toki\TokiTori`)

| File | Content |
|---|---|
| `TT_Home.asm` | ROM0 `$3D00–$3FFF`: API, sequencer, SFX stream, `RowLenTable_80` |
| `TT_Driver.asm` | bank `$2D`: jump tables, ch1–ch4 code, `FreqTables`, `WaveTable`, `Ch3VolTable`, `TremoloTables`, `VibratoTables`, `SongTable`, `SfxTable` and the SFX |
| `TT_Music_2E.asm` … `TT_Music_33.asm` | pattern streams (`Pat_BB_AAAA`), unreferenced runs, order lists (`SongNN_Orders`, bank `$33`) |
| `TT_Macros.inc` | notes, `FX_*`/`TFX_*`, row/order/song/SFX macros |
| `TT_RAM.inc`, `GB_Hardware.inc` | RAM map (`$DF00–$DFA9`, channel structures), registers |
| `build_check.sh` | rebuild and compare |
| `tools\` | `ttgen.py` (generator, data model), `ttnames.py` (labels, RAM, constants), `gbdis.py` (SM83 decoder) |
| `harness\` | `harness.asm`, `build.sh`, `verify.py` |
