# Cyborg Kuro-chan: Devil Fukkatsu (GBC): sound driver

ROM: `Cyborg Kuro-chan - Devil Fukkatsu (J) [C][!].gbc` (Game Boy Color only, MBC5 + 8 KB battery RAM, 1 MB, internal title `KURO CHAN`). Konami, 2000.

Part of the Konami family, see `Konami_SoundEngine_Family.md`. This is **World Soccer GB2's driver** (`WorldSoccerGB2_SoundDriver.md`, the Castlevania Legends → Power Pro GB → ISS '99 line): about 2,440 of its 2,780 instructions line up with World Soccer GB2's. Its command language, track fields `$00–$57`, descriptors, `FarRead` buffer, requests, fade and wobble are World Soccer GB2's. What changes:

- the track code and all headers move to **bank `$0C`**, the streams of a sound to bank **`$0C` + (priority byte >> 4)** (banks `$0C–$0F`);
- the track pages move from cartridge RAM to **CGB WRAM bank 7**, `$D000 + n×$100` (fields up to `$67`), the globals to `$D700–$D72C`; **every ROM0 entry point maps WRAM bank 7 first** and the game's bank (its copy at `wWramBank` `$C006`) again at the end;
- **instrument macros** (`$EA 11 n`): with every note a timed list of steps changes the duty / CH3 wave and adds a signed period offset (§3.2); `$EA 10` is still pan both (the `$EA 1x` handler now dispatches on x);
- a **speed-up tempo** (`$EE $80|n`): one tick comes off the length of every music track every n updates, in place of the tempo skip (§2.2);
- the **table-set pointer** is used: set 1 is a second drum-hit table, selected by **`$EA Fx`** (`wDrumSet` = x & 3) – the pitch drift is gone;
- **no PCM**: `$EA 6x` is the second pan-both again, the sample player is gone;
- 96 wave pointers (90 waves) and 96 periods (World Soccer GB2: 16 waves, 85 periods).

| | |
|---|---|
| API | ROM0 `$2093` `PlaySoundFar` (A = id, 0 = stop all; 216 call sites) → `$2106` `PlaySound`; `$2075` `PlaySoundFarSet1` (table set 1, never called); `$1FD6` `SndInit`; `$2477` `StartFadeOut`, `$24AF` `StopAndFadeIn`, `$24DE` `SndUndim`, `$2508` `SndDim` |
| Game inputs | `wPauseFlag` `$D71D`, `wSndDim` `$D71A` bit 0 (through the entry points) |
| Tick | **VBlank**: the handler calls `SndUpdate` `$226C` at `$00AE` (`wSndBusy` `$C012` bits 1/2 mark a request / init in progress) |
| Driver code | ROM0 `$1FD6–$2531` (1.4 KB); bank `$0C` `$478A–$5606` (3.6 KB, jump tables at `$4FF1`, `$5033`, `$5161`, `$51A2`) |
| Data | bank `$0C` `$4000–$4789` (table sets, `SoundTable`, headers, drum set 1) and `$5607–$7E84` (waves, periods, vibrato/semitone/envelope/macro tables, SFX, songs); banks `$0D` `$4000–$7902`, `$0E` `$4000–$7C17`, `$0F` `$4000–$672C` (songs); the rest of the four banks is `$FF` |
| RAM | WRAM bank 7: tracks `$D000–$D667`, globals `$D700–$D72C`, `$D780–$D7D0` |
| Counts | 246 ids: SFX `$01–$D6`, 32 songs `$D7–$F6`; drum set 1: 11 hits; 13 vibrato, 11 semitone, 24 envelope, 10 macro tables |

`KURO_SoundDriver.asm` rebuilds **byte-exact** with RGBDS over ROM0 `$1FD6–$2531`, bank `$0C` `$4000–$7E84`, `$0D` `$4000–$7902`, `$0E` `$4000–$7C17` and `$0F` `$4000–$672C`, and assembles cleanly with `-Wall`:

```
rgbasm -Wall -o kuro.o KURO_SoundDriver.asm
rgblink -o kuro.gbc kuro.o
```

---

## 1. Structure

### 1.1 Tracks and fields

World Soccer GB2's tracks and descriptors (Sfx1 `$40`, Sfx2 `$52` on CH3, SfxN `$63`, Ch1 `$00`, Ch2 `$11`, Ch3 `$22`, Drm `$34`) and fields `$00–$57`, plus the instrument fields:

| Field | Offset | |
|---|---|---|
| `TRK_INSTR` | `$58` | macro number (0 = none) |
| `TRK_INSFLAGS` | `$59` | `$01` running, bit 3 mark set; 0 = stopped |
| `TRK_INSTIMER` | `$5A` | ticks left of the current step |
| `TRK_INSPTR` | `$5B–$5C` | next step |
| `TRK_INSMARK` | `$63–$64` | the `$FE` mark |
| `TRK_INSOFS` | `$66–$67` | the signed period offset of the current step |

`$5D–$62` are cleared with them; `$65` is never written as a field (see §5.1). `SndClearRAM` clears `$70` bytes of each page, `$D700–$D76F` and `$D780–$D7D0`.

### 1.2 Globals

World Soccer GB2's (`$A7xx` → `$D7xx`), with `$D728` `wDrumSet`, `$D729` `wGameWramBank` (the game's WRAM bank while the driver runs), `$D72B` `wSpeedRate`, `$D72C` `wSpeedTimer`; the drift and PCM variables are gone. The game's `$C005` (mapped ROM bank), `$C006` (WRAM bank), `$C012` (busy flags).

---

## 2. Timing

### 2.1 Update

`SndUpdate` (from VBlank) maps WRAM bank 7, then World Soccer GB2's update: the pause (CH2 muted once), `FadeCheck`/`FadeTick`, `WobbleTick`, **`SpeedTick`**, Ch1, Ch2, Ch3, Drm (not while paused), SfxN, Sfx2, Sfx1 (skipped while `wReqHold` bit 3 is set), and the game's ROM and WRAM banks again. Each track runs with bank `$0C` mapped; `FarRead` maps the stream bank for every 4-byte read.

### 2.2 Tempo and speed-up

`$EE x` (x < `$80`): `wTempo` = x, the accumulator and the speed-up cleared; `TempoTick` sets the skip flag of the four music tracks on a carry. `$EE $80|n`: `wSpeedRate` = `wSpeedTimer` = n. While `wSpeedRate` is set, `SpeedTick` replaces `TempoTick`: every n updates the `LEN` of Ch1, Ch2, Ch3 and Drm goes down by one more tick – unless one of the playing music tracks is about to read (`LEN` < 2), in which case the step is put off to the next update. In the data only `$EE $90` (twice) – no ordinary tempo is set.

### 2.3 Requests

| Id | Action |
|---|---|
| 0 | `wMusicId` = 0, `StopAll` |
| any, while `wReqHold` bit 0 | stored in `wHeldReq` (never read) |
| `$D7–$FF` equal to `wMusicId` | ignored |
| other | header from `[SoundTableSets + 2 × wTableSet] + 2 × id` (always set 0 = `SoundTable` from `PlaySoundFar`) |

A song start resets the fade, tempo and speed-up. Priorities compare their low nibbles; the SFX priority test works (World Soccer GB2's fix).

### 2.4 Fade, wobble, pause, dim

World Soccer GB2's, reached through the SVBK-mapping entry points.

---

## 3. Data format

### 3.1 Commands

World Soccer GB2's (Castlevania Legends' note-volume mode, envelopes, loop breaks, drum escapes `$Dx n`, two-byte vibrato steps), with this `$EA` table:

| `$EA` | | `$EA` | |
|---|---|---|---|
| `0y` / `0F n` | duty / CH3 wave (any wave with `$0F`) | `9y` | release volume |
| `10` | pan both | `Ay n` | NR50 wobble |
| **`11 n`** | **instrument macro n** (3 bytes) | `By` / `Ey` | hold bits set / clear |
| `2y`, `3y` | pan left / right | `Cy` | flag 7 |
| `4y`, `5y` | autopan / autopan both | `Dy` | noise attenuation |
| `6y` | pan both | **`Fy`** | **`wDrumSet` = y & 3** |
| `7y`, `8y` | transpose up / down | | |

In the data: 9,236 notes and 2,944 note-volume notes, 3,566 drum notes and one drum escape, 2,979 noise bytes, 280 + 399 voices, 1,939 releases, 702 vibratos, 104 envelopes, 1,151 + 682 + 245 duty/wave commands, 410 + 56 loops and 115 loop breaks, 128 calls, **41 instrument commands** (macros 1, 3, 6, 7 and 17 offs), two speed-ups. **Not used:** `$EA Fx` (so drum set 1 is never selected), `$EA Ax`, `$EA B/C/D/E`, the slide.

### 3.2 Instrument macros

`$EA 11 n` sets `TRK_INSTR` = n and starts macro n (`MacroTable` + 2 × (n − 1)); n = 0 turns it off. Every note restarts it from its first step (`TRK_INSTIMER` 1, so the first step is read on the next tick). A step is 3 bytes: **ticks, a wave byte, a signed period offset**. The wave byte is swapped and written as the duty – on CH3 as the wave (`LoadWave`, keeping NR32), and on a music track only while Sfx2 is idle. The offset is added to every period the track writes while the macro runs (also under vibrato). `$FE` marks the next step the first time and jumps back to the mark after that; `$FF` ends the macro (the last offset stays in `TRK_INSOFS` but is no longer added). The ten macros (`$60F3–$62AC`) step through runs of consecutive waves – the wave byte is the wave number, `$10, $11, $12…` (macros 1–4, 9), `$20…`, `$30…`, `$3F` down, `$40…`, `$50…` – some with small period offsets (macros 6, 8, 9): a sampled-instrument effect on CH3. The data uses them only on wave tracks.

### 3.3 Tables (bank `$0C`)

| Address | Contents |
|---|---|
| `$4000` | `SoundTableSets`: set 0 = `$4002`, set 1 = `$4746` |
| `$4002` | `SoundTable`, ids `$01–$F6` (entry 0 = the set-1 pointer) |
| `$41F0–$4745` | headers |
| `$4746` | `DrumSet1Table`, 11 hits (entry 0 unused), headers `$475E–$4789` |
| `$5607` | `WaveTable`, 96 pointers (the wave byte swapped, × 2), waves `$56C7–$5C66` |
| `$5C67` | `PeriodTable`, 96 periods (the last is also `VibratoTable` entry 0) |
| `$5D27` | `VibratoTable`, 13 pointers; `$5FB6–$5FD5` is vibrato data nothing points at |
| `$5FD6` | `Vibrato2Table`, 11 semitone tables |
| `$6018` | `EnvelopeTable`, 24 envelopes |
| `$60DF` | `MacroTable`, 10 instrument macros (`$60F3–$62AC`) |

---

## 4. Sounds

SFX `$01–$D6` (drum hits among them), 32 songs `$D7–$F6` on Ch1, Ch2, Ch3, Drm, in banks `$0C` (priority nibble 0), `$0D`, `$0E` and `$0F`. One orphan subroutine (bank `$0E` `$4F35`) is decoded in the asm.

---

## 5. Quirks and bugs

1. **The macro's skipped wave goes to ROM**: when a music track's step falls while Sfx2 plays, the wave byte is stored with `ld [$0065], a` (`$49D1`) – a write to the MBC's RAM-enable range – instead of to the track field `$65`.
2. **Song `$D8`'s drum track runs off its end**: its last `LOOP2_END $FE` (`$0E:$453A`) is read as a loop start the first time, and the track runs on into Ch1's subroutines (`$453C`), reading their notes as drum hits and their closing `$FD` as a call to `$01E0` in ROM0. It is far into the song before that happens (the asm notes the bytes).
3. Song `$F0`: Ch1 calls the part it shares with Ch2 (`$0F:$4F77`), and its loop back to its segno is Ch2's first byte (`$4F7A`).
4. `$EA 1x` with x ≥ 2 jumps through the two-entry table into code; none in the data.
5. Drum set 1 and `PlaySoundFarSet1` are never used.

---

## 6. Verification

Lighter verification (done in the previous session and re-run in this one): `verify/vstream13.py kuro` drops the game's requests, injects every id through `PlaySoundFar` and hooks the `TRK_LEN` stores (`$47F8` notes, `$4D61` noise bytes); every read's address and length must match `tools/kdata13.py`'s timeline, with the tempo skips and the speed-up decrements in between. **Every id alone for 6,500 updates: 246 ids, 149,236 reads, 0 mismatches** (`verify/run_stream_kuro.sh` → `run_stream_kuro.log`, identical on the re-run). The asm uses `tools/kdata16.py` (kdata13's decoding plus the full table sizes, the macro tables and the drum-set-1 streams).

---

## Files (in `GBAudioLab\Kon`)

- `KURO_SoundDriver.asm` – the disassembly (driver + all sound data), byte-exact.
- `tools/kdata16.py` – `kdata13.py` with the macro walker and full tables (Kuro-chan, The Mummy); `tools/cfg16common.py` (fields, macros, emitter shared with The Mummy); `tools/cfg_kuro.py`.
- `verify/vstream13.py`, `verify/run_stream_kuro.sh`, `verify/run_stream_kuro.log`.
