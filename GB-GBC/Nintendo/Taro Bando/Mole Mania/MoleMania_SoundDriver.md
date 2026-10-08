# Mole Mania (GB): sound driver

Taro Bando's driver for *Mole Mania* (`Mole Mania (U) [S][!].gb`, internal title `MOGURANYA`, MBC1, 512 KB). The sources in `MM-SWR\MoleMania` rebuild all three sound banks **byte-exact** with RGBDS 0.9.1 (`-Wall` clean).

| Bank | Selected by `wSoundBankSel` (`$D243`) | Region | Songs | Song data |
|---|---|---|---|---|
| `$07` | 0 | `$4000–$7FFF` (`$7FFF` = `$FF` fill) | 9 slots, 6 distinct | `$5BAB–$7FFE` |
| `$0B` | 1 | `$4000–$7FFF` (`$7FDF–$7FFF` = `$FF` fill) | 23 slots, 21 distinct | `$5BC7–$7FDE` |
| `$1A` | 2 | `$4000–$68FF` (game data follows from `$6900`) | 3 | `$5B9F–$6830` |

There are **three** sound banks, not two. Each one is a complete, self-contained copy of the driver: code `$4000–$4F36`, the length and frequency tables, the song table, the shared SFX/instrument block, then that bank's songs. Only the songs differ. The two frequency tables are in every bank, at `$4FD3` (DMG) and `$5067` (SGB).

```
MoleMania\build_check.sh      # assemble the 3 banks, link over the ROM, compare
MoleMania\harness\build.sh    # test ROM with the 3 rebuilt banks
MoleMania\harness\verify.py   # play every song/SFX, check every byte the driver reads
python tools\mmgen.py <rom> MoleMania   # regenerate the sources
```

---

## 1. Provenance

Bank `$1A` ends its sound data at `$6830`, pads with zeros to `$686F`, and stores this text at `$6870–$68FF` (16-character lines):

```
1996/4/19  PM 5:30  MOGURANYA  SOUND PROGRAM  & MUSIC  & SOUND EFFECTS
ALL DATA WERE  WRITTEN BY  TARO BANDO
```

The driver never reads it. Banks `$07` and `$0B` have no text.

The three driver copies are identical except for five table addresses: the song table is always at `$50FB`, but its length differs per bank (9, 23 or 3 entries), so everything after it moves:

| Table | `$07` | `$0B` | `$1A` |
|---|---|---|---|
| `SfxTable` | `$510D` | `$5129` | `$5101` |
| `EnvSeqTable` | `$5857` | `$5873` | `$584B` |
| `DutySeqTable` | `$5A79` | `$5A95` | `$5A6D` |
| `WaveTable` | `$5AF9` | `$5B15` | `$5AED` |
| `NoiseTable` | `$5B9B` | `$5BB7` | `$5B8F` |

The 2,718-byte block from `SfxTable` to the end of `NoiseTable` (88 SFX, 75 envelope sequences, 19 duty sequences, 9 waves, 16 noise values) is the same data in all three banks; only its internal pointers are relocated. The sources therefore have one `MM_Driver.inc`, one `MM_Tables.inc` and one `MM_Common.inc`, included by each of `MM_Bank07/0B/1A.asm`. Each bank is assembled as its own object, so the labels don't collide.

---

## 2. API and integration

| Address (every bank) | Routine | |
|---|---|---|
| `$4000` | `Sound_Init` | `jr` to the hardware init: NR52 on, NR51 `$FF`, NR50 `$77`, NR10 `$08`, all other channel registers 0 |
| `$4002` | `Sound_Update` | once per frame |

The game never calls the driver directly with arguments. Its VBlank handler (`$0331`, ending at `$0376`) re-enables interrupts and calls the home-bank glue at `$0463`:

1. copy `$D244` → `wSongRequest` (`$DC00`), `$D245` → `wCommandRequest` (`$DC01`), `$D246` → `wSfxStopMask` (`$DC02`), and clear the three;
2. switch to `[$048A + wSoundBankSel]` (`$07`, `$0B`, `$1A`) with `rst $10`, `call $4002`, restore the bank.

Boot calls `$4000` in bank `$07` (`$0176`).

**Requests.**

| Variable | Meaning |
|---|---|
| `wSongRequest` | song number, 1-based, in the selected bank's song table |
| `wCommandRequest` | lowest set bit wins: bit 0 **stop**, bit 1 **pause** (saves `$DC10–$DC18` and `$DC28–$DCCB` to `$DB10`/`$DB28`, silences), bit 2 **resume** (restores them) |
| `wSfxStopMask` | bits 0–3: kill the SFX on ch1–ch4 now |
| `wSfxRequestBits` (`$DC03–$DC0D`) | 88 bits; the game sets bit `b` of byte `n` for SFX `n*8+b+1` (`set n, [hl]` on `$DC03+n`) |
| `wQuietMode` (`$DC0F`) | nonzero halves volumes (§3.6). Set to 1 by two routines in bank `$09` and cleared by five others; the game state behind them wasn't traced |

`Sound_Update` order: song request → command → SFX requests (bits → per-channel slots, §4.7) → stop mask → command action → **SGB tempo check** → `Music_Update` → `Sfx_Update`.

---

## 3. Engine

### 3.1 Super Game Boy correction

On SGB hardware the whole Game Boy runs about 2.4 % fast (4.295 MHz vs 4.194 MHz), so both pitch and frame rate go up. `wSystemFlags` (`$C0A0`) bit 7 is the game's SGB flag. Boot sets it after a `MLT_REQ` joypad test (`$1543`). The driver corrects for it in two ways:

- **Pitch.** `GetNotePeriod` (`$4590`) reads `FreqTable_SGB` instead of `FreqTable_DMG` when bit 7 is set. Every SGB period is lower, by an average frequency ratio of 1.024 (the clock ratio is 1.0241). C2 can't go lower than the hardware minimum (64 Hz), so its SGB entry is `$0000` (64.0 Hz instead of 63.9 Hz).
- **Tempo.** With bit 7 set, `Sound_Update` counts `wSgbSkipCounter` 0–42, and on the 43rd frame it **returns before the music and SFX updates**. That makes 42 updates in 43 SGB frames: 61.17 Hz × 42/43 = 59.75 Hz, the DMG rate. The skip is suspended (the counter doesn't advance) in two cases:
  - song 6 is playing and the game variable `$D23B` is 1;
  - ch3's `CH3DECAY` is 1, the wave is 1 and ch3 is on the 2nd frame of a note.

  These are game-specific exceptions; what the two cases protect wasn't identified.

**SFX aren't pitch-corrected.** `Sfx_Note` (`$4D07`) always uses `FreqTable_DMG`. Only the frame skip applies to them.

### 3.2 Frequency tables

74 big-endian words each. Index 0 is `$0000` (64 Hz, used as "no note"); 1–73 are C2–C8 (C2 = `$002C` on DMG). Music notes use index = byte − `$70` + `TRANSPOSE`. SFX notes use index = byte − `$70` for bytes `$70–$EF`, so indices 74–127 would read past the DMG table into the SGB table and beyond. No SFX does that.

### 3.3 Song structure

```
SongTable:   dwb Song01, Song02, ...          ; big-endian pointers
SongNN:      STEP Frame_xxxx                  ; step list (big-endian frame pointers)
             ...
             SONG_LOOP n / SONG_END           ; 00 nn: back n steps / 00 00: stop
Frame_xxxx:  FRAME ch1, ch2, ch3, ch4         ; 4 pattern pointers, 0 = channel unused
```

Every pointer in the driver's data is big-endian.

**One step for all channels.** `PATEND` (`$00`) on any channel advances the shared step index, resets all four pattern positions and continues reading in the same frame. In practice ch1 ends every step and the other channels' patterns usually have no `PATEND` at all. Ch1 is processed first in a frame, so a channel that finishes its last note together with ch1 points one byte past its pattern for that frame, but never reads that byte. `verify.py` confirms this: no music read falls outside a parsed pattern.

**Zero-length steps.** A frame can hold a ch1 pattern made only of commands and `PATEND` (bank `$0B` songs 14 and 17: `TEMPO`, `TRANSPOSE`, `PATEND`). The step is set up and passed in the same frame. Songs use this to set tempo/transpose before the loop point.

The position within a pattern is 8-bit (`wPatPos`), so a pattern is at most 256 bytes.

### 3.4 Pattern bytes

| Byte | Meaning |
|---|---|
| `$00–$13` | commands (§3.5); `$14–$1F` do nothing |
| `$20–$2B` | length: entry 0–11 of the length table selected by `TEMPO` (`L32`, `L16`, `L8`, `L4`, `L2`, `L1`, `L8D`, `L4D`, `L2D`, `L8T`, `L4T`, `L11`) |
| `$2C–$2F` | ch3 output level `CH3LVL0–3`: 0 mute, 1 = 25 %, 2 = 50 %, 3 = 100 % (**global**, read by ch3) |
| `$30–$6F` | gate: release after (n × 4 / 256) of the length (`GATE00–63`); default `$FF` = whole note |
| `$70` | rest |
| `$71–$B9` | notes C2–C8 |
| `$BA` | tie: the gate-end look-ahead finds it and the next note isn't retriggered |
| `$BC+` | ch4: noise `NOISEnn`, NR43 = `NoiseTable[nn]` (16 entries) |

**Lengths.** 12 tables of 11 lengths (frames): whole note = 96, 112, 128, 144, 160, 80, 72, 84, 108, 120, 56, 88 frames for `TEMPO` 0–11 (quarter = 150, 129, 113, 100, 90, 180, 200, 171, 133, 120, 257, 164 BPM). `L11` (`$2B`) reads one byte past the 11-byte table, into the next table (for `TEMPO 11`, into `FreqTable_DMG`). No song uses it.

**Gate and release.** When `wLenCounter` reaches `length − gate frames`, the driver peeks the next byte. A `TIE` sets the tie flag. Otherwise, with `RELEASE` set it starts the release (retrigger with the release envelope, cut after *frames*); without it the channel is cut at once (NRx2 = 0, ch3: NR30 = 0).

### 3.5 Commands

| Byte | Macro | Effect |
|---|---|---|
| `$00` | `PATEND` | next step, all channels |
| `$01` | `TEMPO t` | length table (global) |
| `$02` | `WAVE w` | ch3 wave (global), loaded at the next ch3 trigger |
| `$03` | `VIBRATO delay, rate, depth` | from frame *delay* of each note: period + depth for rate + 1 frames, then alternately − depth / + depth for 2 × rate + 3 frames each. A square wave in raw period units, not a sine; it restarts at every trigger |
| `$04` | `VIBRATO_OFF` | |
| `$05` | `RELEASE frames, env` | at gate end: NRx2 = *env*, retrigger, cut after *frames* − 1 |
| `$06` | `RELEASE_OFF` | |
| `$07` | `PORTA delay, frames, note` | after *delay* frames, glide linearly from the note to *note* in *frames* frames (step = difference / frames, integer) |
| `$08`, `$0D` | `FRAMES n`, `FRAMES_0D n` | next lengths are *n* frames (songs only use `$0D`) |
| `$09` | `TRANSPOSE n` | semitones, added to notes and `PORTA` targets |
| `$0A/$0B/$0C` | `PAN_CENTRE/RIGHT/LEFT` | NR51 bits for the channel (written every frame from `wNR51`) |
| `$0E` | `CH3DECAY n` | ch3: level drops one step every *n* frames from the note start |
| `$0F` | `SCOOP xy` | the note starts x × y period units low and rises back over y frames (a "scoop" into the note) |
| `$10` | `DUTYSEQ n` | ch1/ch2 duty sequence |
| `$11` | `ENVSEQ n` | ch1/ch2/ch4 envelope sequence |
| `$12` | `PORTA_OFF` | |
| `$13` | `SCOOP_OFF` | |

The period is rebuilt from the note every frame. The effects then run in a fixed order: scoop, porta, vibrato (into the output period), duty sequence, envelope sequence, release, pan. The ch1–ch4 register writes come last.

### 3.6 Instruments

**Sequences** (`EnvSeqTable` 75 entries, `DutySeqTable` 19): pairs `SEQ value, frames`, ending with `SEQ_HOLD value` (frames = `$FF`). Each envelope step writes NRx2 and **retriggers** the channel, so volume shapes are built by restarting the note. Duty steps set NRx1 bits 6–7.

**Ch3.** NR32 levels come from `CH3LVL` (global) minus the `CH3DECAY` steps. A trigger turns the DAC off, waits for NR52 bit 2 to clear, turns it back on, copies the 16-byte wave and restarts. There are 9 waves.

**Quiet mode** (`wQuietMode` ≠ 0): every NRx2 written by the music passes through two 16-byte tables (`$495F`, `$496F`). The initial volume is halved (0–F → 0–8), and the envelope period is lengthened (1 → 3, 2 → 4, … 7 → 7), so notes fade at a similar rate from a lower level. Ch3 levels drop one step (100 % → 50 %, 50 % → 25 %, 25 % → mute).

### 3.7 Sound effects

88 SFX, the same in every bank (ids 65–67 share one effect; 84–88 share a 5-byte silent placeholder).

**Starting an effect.** `HandleSfxRequests` turns each set request bit into a per-channel request (`wSfxRequest[ch] = id`, the channel is the effect's first byte). It then applies hard-coded filters (`FilterSfxRequest`):

- ch4 effect `$1A` is dropped while ch4 is playing `$0C`;
- ch2 effect `$0A` is dropped while anything plays on ch2;
- ch3 effect `$04` is dropped while ch3 plays `$0B`, `$10` or `$04`;
- no effect can replace `$24`, `$25` or `$28` on their channel.

`Sfx_Start` then starts **one** pending request per frame. Requests waiting on other channels start on later frames.

**Format.**

```
SFX_CHANNEL c           ; 0-3
db C4                   ; $70-$EF: set the period (DMG table)
SFX_LEN n               ; $00-$6F: (re)trigger and play n+1 frames
SFX_DUTY d / SFX_ENV e / SFX_WAVE w / SFX_NOISE nr43 / SFX_CH3LVL l
SFX_SWEEP s             ; signed, added to the period every frame
SFX_PAN_CENTRE / RIGHT / LEFT
SFX_LEGATO              ; the next SFX_LEN doesn't retrigger
SFX_END                 ; $F0
```

`$FB–$FE` would jump through bytes past the 11-entry command table; `$FF` is a no-op. Neither occurs.

**Interaction with music.** While an SFX owns a channel, the music skips that channel's register writes but keeps running. `SFX_END` clears the channel (unless `SFX_LEGATO` came just before), and the music is heard again from its next trigger.

---

## 4. Quirks

1. **Three banks, three copies of the code and SFX** (§1). The game switches with `wSoundBankSel`, so the same song number means different music in each bank.
2. **SFX ignore the SGB pitch table** (§3.1).
3. **`L11`** reads the first byte of the next length table (§3.4).
4. **`Ch3Decay`** (`$4A52`): `ret z` after `ld a, [hl]` tests flags from the previous `and a`, so it never returns there.
5. **`wFreqOffsetHi/Lo`** (`$DC3C/$DC40`) are added to the vibrato output but nothing writes them.
6. **`wSfxKeepPan`** (`$DCF8`) is tested when an SFX starts but never set, so SFX pan always resets to centre.
7. **`StartSong`** keeps most channel state when `$D23B` = 1 and song `$0D` starts (it clears only scoop, transpose, porta, release, position, tie and vibrato); otherwise it clears `$DC70–$DCCB`.
8. **Leftover data:**
   - bank `$0B` has a second `$00` after both zero-length patterns (`$6D7A`, `$6D80`);
   - bank `$0B` has an unreferenced 6-byte pattern at `$77F7`;
   - the song tables repeat entries: bank `$07` songs 1 = 3, 2 = 6, 5 = 7; bank `$0B` songs 4 = 5, 22 = 23. Bank `$0B` song 17 starts inside song 14's step list and shares its second step.

---

## 5. Songs

| Bank `$07` | Steps | End | | Bank `$0B` | Steps | End | | Bank `$1A` | Steps | End |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 (= 3) | 8 | loop → 2 | | 1 | 11 | loop → 1 | | 1 | 1 | stop (ch1–3) |
| 2 (= 6) | 16 | loop → 1 | | 2 | 2 | loop → 1 (ch1–3) | | 2 | 16 | stop |
| 4 | 14 | loop → 7 | | 3 | 4 | loop → 2 | | 3 | 5 | loop → 1 |
| 5 (= 7) | 2 | loop → 0 | | 4 (= 5) | 1 | stop (ch1–3) | | | | |
| 8 | 12 | loop → 6 | | 6, 15, 16 | 1 | loop | | | | |
| 9 | 1 | loop | | 7, 9, 12, 19 | 1 | stop | | | | |
| | | | | 8, 13, 20 | 2 | loop | | | | |
| | | | | 10, 18 | 3 | loop | | | | |
| | | | | 11, 22 (= 23) | 7 | loop → 1 | | | | |
| | | | | 14, 17 | 2 | loop → 1 (ch1–2) | | | | |
| | | | | 21 | 8 | loop → 0 | | | | |

Song titles weren't identified; the step counts and loop points are in the generated `SongTable`/`SongNN` sources.

---

## 6. Verification

- **Byte-exact rebuild** of the three regions (`build_check.sh`: `rgblink -O` over the original ROM, plus a check of each region without the overlay).
- **Emulator harness** (`harness\`): a ROM that links the three **rebuilt** banks and calls `Sound_Update` once per frame (mid-frame, from an LYC interrupt, so a frame boundary never splits it). `verify.py` (PyBoy) plays every song for 3,600 frames on DMG and again with the SGB flag set, and every SFX for 600 frames. PC hooks on the pattern read (`$439A`), the gate-end look-ahead (`$4556`) and the SFX read (`$4CD9`) record every address the driver reads.

  | Bank | Songs | Reads outside the parse | Pattern events read | SFX events read |
  |---|---|---|---|---|
  | `$07` | 9 × 2 | 0 | 6,838 / 7,773 | 1,159 / 1,241 |
  | `$0B` | 23 × 2 | 0 | 7,142 / 7,237 | 1,159 / 1,241 |
  | `$1A` | 3 × 2 | 0 | 2,410 / 2,618 | 1,159 / 1,241 |

  The only reads past a pattern's last byte are the gate-end `TIE` look-aheads at the end of unterminated patterns (390 / 642 / 30). They only compare the byte with `$BA`.
- **Not verified:** what the two SGB-skip exceptions and the `$0D`/`$D23B` case are for, the game contexts of the three banks and of quiet mode, and anything on hardware.

## Files (`MM-SWR\MoleMania`)

| File | Content |
|---|---|
| `MM_Bank07.asm`, `MM_Bank0B.asm`, `MM_Bank1A.asm` | one section per bank, includes below |
| `MM_Driver.inc` | driver code `$4000–$4F36`, labelled, with the two jump tables and the quiet-mode tables |
| `MM_Tables.inc` | length tables, `FreqTable_DMG`, `FreqTable_SGB` |
| `MM_BankXX_SongTable.inc`, `MM_BankXX_Songs.inc` | per-bank song table and songs (bank `$1A` also has the credit text) |
| `MM_Common.inc` | SFX table and effects, envelope/duty sequences, waves, noise table |
| `MM_Macros.inc`, `MM_RAM.inc`, `GB_Hardware.inc` | macros and constants, RAM map (`$DC00–$DCFF`, save area `$DB10`/`$DB28`) |
| `tools\` | `mmgen.py` (generator), `mmparse.py` (data model), `mmnames.py`, `mmram.py`, `gbdis.py`, `emit.py`, `hwinc.py` |
| `harness\` | `harness.asm`, `build.sh`, `verify.py` |
