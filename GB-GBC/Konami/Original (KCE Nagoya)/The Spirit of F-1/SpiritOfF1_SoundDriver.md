# The Spirit of F-1 (GB): sound driver

ROM: `Spirit of F-1, The (E) [!].gb` (DMG, MBC1, 128 KB, internal title `THE SPIRIT OF F1`). Konami, 1991 (*F-1 Spirit* in Japan, *World Circuit Series* in North America).

Part of the Konami family, see `Konami_SoundEngine_Family.md`. Like *Hyper Dunk* this driver sits **between the second generation and Nemesis II**: the second generation's single-bank framework (bank 7, VBlank, Belmont's Revenge's update loop, tempo, register shadows, `IsBlocked`, raw per-track `PAN` byte and **request groups with the stale refusal flag**) around **Nemesis II's track code**. It is the closest relative of Nemesis II found so far: about 1,105 of its 1,414 instructions line up with Nemesis II's bank-13 code (about 910 with Belmont's Revenge's, 955 with Hyper Dunk's), its track fields are Nemesis II's up to `$B0`, and its command set is Nemesis II's (`$EB n xy` vibrato, `$EA 2x`/`$EC`/`$ED` no-ops, the paired loop markers, `$FD` call/return, `$FE` mark/jump, raw streams). What Nemesis II adds on top of it is the multi-bank layout, the 128 Hz timer with half-rate music, its tempo scheme, the fade and the duty step.

Game-specific: an **engine sound** on Sfx1 (id `$1A`) whose period follows a game variable every update, comes back after every Sfx1 SFX, and is stopped by `$1B`; and SFX `$0E` mutes CH3 while it plays.

| | |
|---|---|
| API | ROM0 `$02A6` `PlaySoundFar` (A = id, 0 = stop all; 55 call sites) → bank 7 `$4014` `PlaySound`; `$41AA` `SndPause` / `$41B4` `SndUnpause` (the game's pause code) |
| Game inputs | `wPauseFlags` `$C0C5` bit 0 (the game's own pause flag), `wEngineVar` `$C159` (`$00–$6F`) |
| Tick | **VBlank**: the handler (`$0068`, normal path) calls `SndUpdateFar` `$0095` → bank 7 `$425B` `SndUpdate`, skipped while `wSndLock` `$C0C1` bit 0, 1 (a `PlaySoundFar` in progress) or 2 is set. One update per frame in PyBoy |
| Driver code | ROM0 `$0028` (rst), `$0095–$00B7`, `$02A6–$02C6`, `$02E0–$02EC`; bank 7 `$4000–$4B03` (2.8 KB, inline jump tables at `$4394`, `$44D1`, `$451A`, `$45EE`, `$4A01`) |
| Data | bank 7 `$4B04–$7BD1`; `$7BD2–$7FFF` is game data (pointer tables the game code reads) |
| RAM | seven tracks at `$D780 + n×$100` (`$80–$B4`), globals `$D7B8–$D7D4`, shadows `$D8B5–$D8C8` |
| Channels | Sfx1 (CH1), Sfx2 (CH2), SfxN (CH4), Ch1, Ch2, Ch3, Drm (drums = sound ids through a 13-entry map) |
| Counts | 48 ids `$01–$30`: 13 drum hits, SFX `$0E–$1B` (pause jingle `$19`, engine `$1A`, engine stop `$1B`), 21 songs `$1C–$30` |

`F1_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over ROM0 `$0028–$002C`, `$0095–$00B7`, `$02A6–$02C6`, `$02E0–$02EC` and all of bank 7. It assembles cleanly with `-Wall`.

```
rgbasm -Wall -o f1.o F1_SoundDriver.asm
rgblink -o f1.gb f1.o
python tools/cmp_ranges.py f1.gb "Spirit of F-1, The (E) [!].gb" 0:0028-002C 0:0095-00B7 0:02A6-02C6 0:02E0-02EC 7:4000-7FFF
```

---

## 1. Structure

### 1.1 Tracks

Track n's page is `H = $D7 + n`, fields at `L = $80–$B4`; the track order, `RegBaseTable` (`00 05 0F 00 05 0A 0F`), the blocking (Ch1 while Sfx1 plays, Ch2 while Sfx2 plays) and the shadowed `WriteReg` are Belmont's Revenge's.

| # | Page | Name | Channel |
|---|---|---|---|
| 0 | `$D780` | Sfx1 | CH1 |
| 1 | `$D880` | Sfx2 | CH2 |
| 2 | `$D980` | SfxN | CH4 |
| 3 | `$DA80` | Ch1 | CH1 |
| 4 | `$DB80` | Ch2 | CH2 |
| 5 | `$DC80` | Ch3 | CH3 |
| 6 | `$DD80` | Drm | – (plays sound ids) |

### 1.2 Track fields

`$80–$B0` are exactly Nemesis II's (see `NemesisII_SoundDriver.md` §1.2): `FLAGS` `$85` (1 autopan, 2 vibrato on, 3 vibrato negate, 6 force, 7 rest; bit 4 is tested by `TrackTick` but never set), `FLAGS2` `$86` (4+5 raw stream), loop counters `$87/$88`, `VIB`/`TRANSP`/`ATTEN` `$89–$8B`, `VIBOFS` `$8C`, `VIBLOOPCNT` `$8E`, `FLOW` `$8F`, `UNIT`/`OCTAVE`/`PERIOD` `$90–$93`, raw period `$94/$95`, `VOL`–`RELTICK` `$96–$9A`, vibrato and CH3 timers `$9B–$9E`, `LEVEL` `$A0`, `LOOPPTR`/`LOOP2PTR`/`RET`/`SEGNO` `$A1–$A8`, `VIBPTR`/`VIBIDX`/`VIBLOOPIDX`/`VIBDEPTH` `$A9–$AD`, vibrato delay `$AE–$B0`. There are no duty-step fields, and `PAN` is at `$B4` (Nemesis II: `$B6`).

### 1.3 Globals

`wTrackIdx` `$D7B8`, `wRegBase` `$D7B9`, `wTempo`/`wTempoAcc`/`wTempoSkip` `$D7BA–$D7BC`, `wQueuedSnd` `$D7BD`, `wNR51` `$D7BE`, `wSweepVal` `$D7BF`, `wReqId`/`wReqPrio` `$D7C0/1`, `wRegVal`/`wRegIdx` `$D7C2/3`, `wMusicHold` `$D7C4`, `wFadeLevel` `$D7C9`, `wReqRefused` `$D7CA`; engine: `wEnginePhase` `$D7CB`, `wEngineTimer` `$D7CC`, `wEngineIdx` `$D7CE`, `wEnginePtr` `$D7CF`, `wEnginePeriod` `$D7D1`, `wCh3Mute` `$D7D3`, `wEngineOn` `$D7D4`. `wQueuedSnd`, `wMusicHold` and `wFadeLevel` are read but never written.

---

## 2. Timing

### 2.1 Update

Once per VBlank (on the handler's normal path) `SndUpdateFar` maps bank 7 and calls `SndUpdate`: `TempoTick`, then tracks 0–6. While `wPauseFlags` bit 0 is set only track 0 runs, and only for id `$19` (the pause jingle). Otherwise the loop stops before track 3 when `wTempoSkip` or `wMusicHold` is set (a second test for track 4 is unreachable). Last, `wQueuedSnd` would be started. `PlaySoundFar` sets `wSndLock` bit 1 and maps bank 1 afterwards (always).

### 2.2 Tempo

As Belmont's Revenge: `wTempoAcc += wTempo` every update, the carry skips the music tracks for that update; `$EE` sets `wTempo`. Tempos in the data: `$08`, `$10`, `$14`, `$15`, `$1B`, `$21`, `$22`, `$28`, `$2B`, `$2F`, `$32`, `$40`.

### 2.3 Fade-out

None. `NoteVolume` subtracts `wFadeLevel` (CH3: half), which stays 0.

### 2.4 Requests

`PlaySound`, id in A: ids `≥ $31` are ignored, 0 = `StopAll`, `$10` is not restarted while Sfx1 plays it; else the header from `SoundTable` (`priority, mask, pointers`). The tracks are started in **Belmont's Revenge's groups**: Sfx1; Sfx2 and SfxN; Ch1, Ch2, Ch3, Drm. `StartTrack` sets `wReqRefused` to 1 on a refusal and 0 on a pass; after the first and the second group a set flag **aborts the rest of the request**, including the NR51 write, and clears the flag. As in Belmont's Revenge the flag is not cleared at the start of a request, so a refused last track (Ch3/Drm) makes the next request without Sfx1 abort at its first check.

A started track gets `TRK_PRIO`, `TRK_ID`, `TRK_PTR`, LEN 1, `TRK_FLAGS` = `$40`, `$86–$8F` = 0, raw-stream bits for a stream starting with `$E1`; a refused one skips its pointer; both get `TRK_PAN` = `$FF`. Sfx1 on a pass: NR10 = 8, its NR51 bits, and the id rules of §3.3 (`$1A` starts the engine, `$1B` stops it, `$0E` sets `wCh3Mute`). Ch1 writes NR10 = 8 when Sfx1 is idle.

### 2.5 Pause

The game's pause code sets `wPauseFlags`, calls `SndPause` (NRx2 = 0 on CH1/CH2/CH4, NR32 = 0) and plays `$19`. `SndUnpause` (unless `wPauseFlags` or `wMusicHold` is set) copies the shadows back for every channel with a playing track, without a retrigger. The engine doesn't run while paused.

---

## 3. Data format

Nemesis II's command language (`NemesisII_SoundDriver.md` §3), with:

| Byte | Meaning |
|---|---|
| `$00–$DF` | note: hi = pitch, lo × unit (**lo = 0: (unit & 15) × 16**); SfxN: NR43, length = unit; Drm: `DrumMap[hi − 1]` |
| `$E0` | `VOICE unit, vol\|duty<<4, env\|gate<<4` (SfxN: `unit, vol<<4\|env`, NR42 + trigger at once; Drm: unit only) |
| `$E1–$E6`, `$E7`, `$E8`, `$E9` | octave, unit, gate + env, NR10 |
| `$EA xy` | 0 transpose up, 1 transpose down, 2 no-op, 3 duty (CH3: wave), 4 autopan on/off (only the flag bit; unused) |
| `$EB n yz` | vibrato table n & 15 (TRK_FLAGS bit 2), delay (y + 1) × unit ticks (y = 0: none), depth z; n & 15 = 0: off (two bytes) |
| `$EC x`, `$ED x` | no-ops (unused) |
| `$EE x`, `$EF x` | tempo, PAN (raw NR51 bits; on the drum track one byte too many is skipped, not in the data) |
| `$F0–$FA` | attenuation (SfxN: NR42 at once) |
| `$FB`/`$FC`, `$FD`, `$FE`, `$FF` | loop markers (two levels), call/return, mark/jump, end |

The note-on and the per-tick work are Nemesis II's (no duty step, no fade, everything at the update rate): release tick = length × gate / 16, period from `PeriodTable`, the vibrato restarts with its delay reloaded, NRx2 and a trigger; per tick the release flag, the vibrato (after its delay, every timer + 1 ticks), the CH3 decay, and at the release tick NRx2 = env | level with a trigger.

### 3.1 Raw streams

As Hyper Dunk and Nemesis II (`$E1` header at the start of a pass, `$00` rest, two-byte frames, `$E7` sets the unit). Used by the pause jingle `$19` and by the Sfx1 parts of the drum hits `$03–$07`, `$0C`, `$0D`.

### 3.2 Vibrato

One-byte steps (ticks << 4 | negate << 3 | offset × depth), `$FB` loop point, `$FE n` repeat, `$FF` hold, as Nemesis II. Tables 1–10 and 12–14 are used.

### 3.3 The engine (`$1A`, `$1B`, `$0E`)

`$1A`'s header (priority 1, Sfx1) points at `EngineTable` (`$7AE4`), not a stream. Starting it sets `wEngineOn` and resets the engine state; from then on `TrackTick` sends Sfx1 playing `$1A` to `EngineTick` every update (not while paused): `TRK_ID` = `$1A`, LEN = 1; every 16 updates duty 0, the Sfx1 NR51 bits and NRx2 = `$C0`; the period `EngineTable[wEngineVar]`, **minus `$60` on every other update** (`wEnginePhase`), written with a trigger. Since its priority is 1, any Sfx1 SFX takes the channel, and when that SFX ends `Cmd_End` goes straight back to `EngineTick` while `wEngineOn` is set; even the drum hits with an Sfx1 part (priority 2) interrupt it. `$1B` (an empty Sfx1 stream, priority `$31`) clears `wEngineOn`. `$0E` sets `wCh3Mute`, which zeroes CH3's level in `NoteVolume` and the decay until an Sfx1 sound ends.

### 3.4 Tables (bank 7)

| Addr | Name | Content |
|---|---|---|
| `$4B04` | `SoundTable` | ids `$01–$30`; the unused id-0 slot is the operand of the `jp` before it (the code reads `SoundTable − 2 + 2 × id`); headers `$4B64–$4CAA` |
| `$4C5C` | `DrumMap` | 13 entries |
| `$4D6D` | `PeriodTable` | 85 periods |
| `$4E17` | `WaveTable` | 12 entries, from 1; 4 waves at `$4E2F–$4E6E`; entries 11 and 12 point at `VibratoTable` (unused: the data uses waves 3, 6, 10) |
| `$4E6F` | `VibratoTable` | 15 (from 1) → `$4E8D–$4EED` |
| `$7AE4` | `EngineTable` | 119 periods (`$02C3` … `$0773`); `wEngineVar` reaches the first 112 |
| `$49B9` | `RegBaseTable` | in the code |

---

## 4. Sounds

Lengths in updates (59.7 Hz; music minus tempo skips). "a+b" = intro + loop period.

| Ids | Prio | Tracks | Notes |
|---|---|---|---|
| `$01–$0D` | `$02` | SfxN (`$03–$07`, `$0C`, `$0D` + a raw Sfx1 part) | drum hits, 2–31 ticks |
| `$0E`, `$0F` | `$31` | Sfx1 + Sfx2 + SfxN | 110–242; `$0E` mutes CH3 |
| `$10` | `$31` | Sfx1 + SfxN | 12 / 25 (not restarted while Sfx1 plays it) |
| `$11` | `$31` | Sfx1 | the songs' shared intro (§5.1); never requested |
| `$12–$18` | `$2F`/`$30` | Sfx1 | 9–108 |
| `$19` | `$80` | Sfx1 (raw) | pause jingle, 40 |
| `$1A` | `$01` | Sfx1 = engine | §3.3 |
| `$1B` | `$31` | Sfx1 (empty) | stops the engine |
| `$1C` | `$40` | Ch1–Ch3 + Drm | looping: intros 48–816, loop 1152 |
| `$1D`, `$1F`, … `$29` | `$40` | Ch2, Ch3, Drm | seven songs; every stream starts with a call to the shared intro (`$4F4B`/`$4F71`/`$4F86`); loops of 1536–3072 |
| `$1E`, `$20`, … `$2A` | `$40` | Ch2, Ch3, Drm | the same songs without the intro (each stream 3 bytes later) |
| `$2B`, `$2E–$30` | `$40` | Ch1–Ch3 + Drm | end after 1140–1176, 366–376, 1458–1488, 980–1000 |
| `$2C`, `$2D` | `$40` | Ch1–Ch3 + Drm | looping, 50+640 and 40+640 (Ch3: 320) |

The race songs leave Ch1 alone, so the engine on Sfx1 never blocks music. The full per-id list is in the asm; `python tools/kdata10.py f1` prints the intro/loop lengths per track.

---

## 5. Quirks and bugs

1. **SFX `$11` would play ROM0 as music.** Its Sfx1 stream (`$4F4B`) is the shared intro that the songs call, ending in a bare `$FD` (return). Started as a sound, nothing has called it, so that `$FD` is a **call to `$09E0`** (the next two bytes) and the driver reads game code as a stream. The game never requests `$11`.
2. **`wEngineVar ≥ $70` crashes**: `EngineTick` returns from inside a `push hl`, so the `ret` jumps to the track page address. The game keeps the variable lower.
3. **The stale refusal flag** aborts the next request after a refused last track (as Belmont's Revenge and Nemesis II).
4. **`wCh3Mute` is cleared by the end of any Sfx1 sound**, not only `$0E`'s.
5. **`TrackTick` tests `TRK_FLAGS` bit 4**, which nothing sets (left from the duty step).
6. **`$EF` on the drum track** skips an extra byte, and in a raw stream **`$E8`, `$EB`, `$EC`, `$ED`** go to the frame code with the jump-table return address still on the stack (as Nemesis II); neither is in the data.
7. **The CH3 decay sets NR32 bit 4** and counts the attenuation twice; **`StopAll` sets `wNR51` = `$FF` without writing NR51** (as before).
8. **`PlaySoundFar` always maps bank 1 afterwards**; `SndUpdateFar` has a leftover `ld a, c` before its call.
9. **Unused / dead:** the track-4 tempo test in `SndUpdate` (`$428D`), `$EA 2x`, `$EC`, `$ED`, autopan, wave entries 11–12, the last seven `EngineTable` entries, `wQueuedSnd`/`wMusicHold`/`wFadeLevel`, and an orphan subroutine at `$7A6E` (decoded in the asm).

---

## 6. Verification

- **Byte-exact rebuild** of the ranges above.
- **Rate:** one update per VBlank (4049 updates in 4200 frames from boot).
- **Streams vs emulator** (`verify/vstream10.py`, as for Hyper Dunk): every id alone for 4000 updates, the game's own requests dropped, the id injected into bank-7 `PlaySound` from the VBlank glue; every note, noise byte, raw frame and raw rest the driver reads (address and length, at the `TRK_LEN` stores) must equal the decoder's (`tools/kdata10.py`) in order, each lasting its length plus the music skips, and the tracks the decoder ends must end. The engine's Sfx1 is checked to read nothing; `$11` is compared up to its call into ROM0. **48 ids, 28,410 reads, 0 mismatches** (`verify/run_stream_f1.log`). A deliberately wrong note length in the decoder is caught at once.
- **Not verified:** the register writes (no update-by-update model), the vibrato values, the engine's sound and the pause; nothing was checked on hardware.

## Files (in `GBAudioLab\Kon`)

- `F1_SoundDriver.asm`: labelled, commented RGBDS source, byte-exact
- `tools/kdata10.py`, `tools/cfg_f1.py`, shared `tools/gen_asm3.py`, `tools/gaps10.py`, `verify/vstream10.py`, `verify/run_stream_f1.sh`, log

Regenerate: `python tools/gen_asm3.py f1 F1_SoundDriver.asm`.
