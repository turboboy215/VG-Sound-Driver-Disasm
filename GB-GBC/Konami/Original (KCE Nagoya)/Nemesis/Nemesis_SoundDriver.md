# Nemesis (GB): sound driver

ROM: `Nemesis (E) [!].gb` (DMG, MBC1, 128 KB, internal title `NEMESIS`). Konami, 1990/1991 (E).

Part of the Konami family, see `Konami_SoundEngine_Family.md`. This is the **later variant**: Motocross Maniacs' 7-track layout and command language, plus a fade-out, a lockout timer for some music, follow-up songs and several changed details.

| | |
|---|---|
| API | bank 7 `$4100` `SndInit`, `$5B6E` `PlaySound` (A = id, 0 = stop all), `$5B14` `PlaySoundSafe` (same, keeps all registers), `$5CE4` `SndPause`, `$5CEF` `SndUnpause`, `$5B20` `StartFade` (unused). ROM0 `$035F` `PlaySoundFar` (the game's entry) |
| Game inputs | `wFadeTarget` `$C1B6` (the game writes it directly to start a fade), `wGameC081` `$C081` (picks the follow-up of sound `$14`), `wPause` `$C013` |
| Tick | **timer IRQ only**, 64 Hz (TAC = `%111`, TMA = 0; PyBoy measured 63.93 IRQs/s during the attract loop, every one reaching the update). `$0050` → `$0222` `TimerISR` → bank 7 `$41BD` `SndUpdate` |
| Music rate | 64 Hz × (1 − tempo/256), as in Motocross Maniacs |
| Driver code | bank 7 `$4000–$47E1` and `$5B14–$5D4E` (~2.6 KB) + ROM0 glue |
| Tables + data | bank 7 `$4040–$40FF`, `$47E2–$5B13`, `$5D4F–$7404` (14 KB); `$7405–$7FFF` is `$FF` |
| RAM | seven tracks at `$C180 + n×$100` (`$80–$A3`), globals `$C1A7–$C1B8`, shadows `$C2A4–$C2B7`; ISR lock `$C00D`, call lock `$C025` |
| Channels | Sfx1 (CH1), Sfx2 (CH2), SfxN (CH4), Ch1, Ch2, Ch3, Drm (drums = sound ids through a 13-entry map) |
| Counts | 57 sound ids (`$01–$39`): 7 drum hits, SFX/jingles `$08–$2C`, music mostly `$2D–$39` |

`NEM_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over ROM0 `$0008–$000B`, `$0028–$002C`, `$0050–$0052`, `$0222–$024E`, `$0334–$037C`, `$0441–$0478` and bank 7 `$4000–$7404`. It assembles cleanly with `-Wall`.

```
rgbasm -Wall -o nem.o NEM_SoundDriver.asm
rgblink -o nem.gb nem.o
python tools/cmp_ranges.py nem.gb "Nemesis (E) [!].gb" 0:0008-000B 0:0028-002C 0:0050-0052 0:0222-024E 0:0334-037C 0:0441-0478 7:4000-7404
```

---

## 1. Structure

As in Motocross Maniacs the tracks are processed **in place**. Track n's page is `H = $C1 + n` (`GetTrackPage`), fields at `L = $80–$A3` with the same offsets as MM (`TRK_*` in the asm). The globals sit in track 0's page after its fields, and the shadows in track 1's page.

| # | Page | Name | Channel (reg base) | NR51 at start | Runs |
|---|---|---|---|---|---|
| 0 | `$C180` | Sfx1 | CH1 (`$00`) | `$11` | every tick |
| 1 | `$C280` | Sfx2 | CH2 (`$05`) | `$22` | every tick |
| 2 | `$C380` | SfxN | CH4 (`$0F`) | `$88` | every tick |
| 3 | `$C480` | Ch1 | CH1 (`$00`) | `$11` | music ticks |
| 4 | `$C580` | Ch2 | CH2 (`$05`) | `$22` | music ticks |
| 5 | `$C680` | Ch3 | CH3 (`$0A`) | `$44` | music ticks |
| 6 | `$C780` | Drm | – (plays sounds) | – | music ticks |

**Channel sharing** is MM's: Ch1 is muted while Sfx1 plays and Ch2 while Sfx2 plays (`IsBlocked`), a music `PAN` is dropped only on Ch1, and drum notes go through `PlaySound(DrumMap[n−1])`.

`PlaySound` sets id, prio, ptr, `len = 1`, `flags = $40` and zeroes `$86–$8C`. Everything above that persists across sounds.

### 1.1 Globals

| Addr | Name | Use |
|---|---|---|
| `$C1A7` | wTrackIdx | |
| `$C1A8` | wRegBase | NR register base of the current track |
| `$C1A9` / `$C1AA` / `$C1AB` | wTempo / wTempoAcc / wTempoSkip | |
| `$C1AC` | wQueuedSnd | started at the end of `SndUpdate` |
| `$C1AD` | wNR51 | |
| `$C1AE` | wSweepVal | write-only |
| `$C1AF` / `$C1B0` | wReqId / wReqPrio | |
| `$C1B1` / `$C1B2` | wRegVal / wRegIdx | `WriteReg` arguments |
| `$C1B3` | wMusicHold | read, never written |
| `$C1B4` | wLockout (2) | §2.4 |
| `$C1B6` / `$C1B7` / `$C1B8` | wFadeTarget / wFadeTimer / wFadeLevel | §2.3 |

---

## 2. Timing

### 2.1 Interrupt glue (ROM0)

`TimerISR` (`$0222`) re-enables interrupts at once and skips the tick if `wSndCallLock` (`$C025`) or `wIsrLock` (`$C00D`) is held; otherwise it maps bank 7, runs `SndUpdate` and maps `wCurBank` again. `PlaySoundFar` (`$035F`) holds `wSndCallLock` while it calls `PlaySound`, so **a timer tick arriving meanwhile is lost**, as in MM. It always maps bank 1 on return, not the caller's bank.

### 2.2 Update order and tempo

`SndUpdate` runs `FadeTick`, `LockoutTick` and `TempoTick` (`wTempoAcc += wTempo`, a carry sets `wTempoSkip`), then the tracks. Tracks 0–2 always run. The loop stops before track 3 when `wTempoSkip` (or `wMusicHold`) is set, so music runs at **64 × (1 − tempo/256) Hz**. MM's engine-sound special case is gone (its check is still there, unreachable, at `$41F3`). Last, a sound in `wQueuedSnd` is started.

Tempos in the data: `$00`, `$04`, `$10`, `$20`, `$30`, `$34`, `$38`, `$40`, `$84`.

### 2.3 Fade-out

The game starts a fade by writing a sound id to `wFadeTarget`. While it's non-zero (and not paused), `wFadeTimer` counts every tick and `wFadeLevel` goes up by one every 64 ticks. Each new note is played `wFadeLevel` steps quieter (`NoteVolume`: NRx2 = (vol − atten − level) << 4, floored at 0; CH3 adds level/2 to its level code). Notes already sounding aren't touched. When the level reaches 5 (after 320 ticks, 5 s):

- target < 7: `StopAll` (the game writes 1 in one place);
- otherwise the target is queued (another place writes `$34`, a third a computed value) and the fade is cleared.

Any request with an id ≥ `$2E` (except those refused by the lockout) cancels a running fade.

### 2.4 Lockout

`CheckLockout` (`$5B2C`) runs before every request except `$2C` (pause jingle) and `$13`. While `wLockout` ≠ 0 the request is **refused**. Ids `$2E–$32` load the counter from `LockoutTable` (`$5B64`), and `LockoutTick` counts it down every tick:

| Id | `$2E` | `$2F` | `$30` | `$31` | `$32` |
|---|---|---|---|---|---|
| Ticks | 357 (5.6 s) | 62 | 500 (7.8 s) | 312 | 357 |

So nothing (no SFX, no other music, **not even drum hits**) can start for the first seconds of these songs. Drums are requests too, but `$2E–$32` have no drum track, so this only matters for an older song's drum track that is still running.

### 2.5 Follow-ups and special ids

- When a track of `$37` ends it queues `$34`; `$21` queues `$36`; `$14` queues `$34` if `wGameC081` = 2, else `$33` (`QueueFollowUp`). `$21`'s Ch1–Ch3 are empty, so `$36` starts at once while `$21`'s own drum track keeps playing alongside it (a short fill, then a 254 × 180-tick silent loop, after which it would read on into `$22`'s data).
- `$0F` doesn't restart while it's already playing on Sfx1.

### 2.6 Pause

`PauseToggle` (`$0441`, game code) calls `SndPause` (NR12/NR17/NR1C/NR21 = 0) and plays `$2C`. While `wPause` ≠ 0 only track 1 runs, and only while it plays `$2C`; the fade is frozen. On unpause `SndUnpause` copies the shadows back for each channel that has an active track (CH4 only for SfxN ids ≥ 8, i.e. not a drum), without retriggering.

---

## 3. Data format

The command language is the earlier one (see the CVA doc §3.2). Differences:

| | MM | Nemesis |
|---|---|---|
| `EA 4n` | no-op | `Ext_Autopan`, but it **stores n \| 2 into the whole flags byte** (0 for n = 0). Not used in the data |
| `EF x` | NR51 bits = swap(x) | same |
| Rest | NRx2 = 0, NRx4 = `$80` | NRx2 = 0 only |
| Release with env 0 | NRx2 = 0 (cut) | NRx2 = stored level, **retrigger at the same volume** |
| `VIBRATO 0` | keeps the offset | **clears** it (fixes the stale offset) |
| Note-on volume | vol − atten | vol − atten − wFadeLevel, floored at 0 |
| CH3 level stored | vol/2 | vol/2 + atten + level/2 (so the decay adds the attenuation a second time) |
| End of Sfx1/Sfx2 | NRx2 = 0 + trigger, restore duty + period | NRx2 = 0 (no trigger), restore duty + period |
| Sound table index | `SoundTable[id − 1]` | the code loads `SoundTable − 2` and adds 2 × id (same result) |

### 3.1 Tables

| Addr | Name | Content |
|---|---|---|
| `$4040` | `PeriodTable` | 96 periods (same values) |
| `$44B3` | `PanMaskTable` | NR51 bits each track keeps (`EE DD 77 EE DD BB FF`) |
| `$47E2` | `RegBaseTable` | `00 05 0F 00 05 0A 0F` |
| `$47E9` | `VibratoTable` | 15 pointers → `$4807–$48A7` |
| `$5B64` | `LockoutTable` | 5 words (§2.4) |
| `$67CE` | `SoundTable` | 57 pointers |
| `$6840–$6983`, `$6991–$69AE` | headers | |
| `$6984` | `DrumMap` | `01 02 01 03 03 03 03 04 05 06 07 07 22` |
| `$69EE` | `WaveTable` | 10 pointers → `$6A02–$6AA1` (16 bytes each) |
| `$4807–$5B13`, `$5D4F–$7404` | streams | |

Vibrato tables: besides the usual small vibratos (+1…+5), `Vib04`/`Vib0B`/`Vib0C` use the negate flag (−1), and `Vib07` (`$4848`) is a 29-step downward dive (offsets −1 … −1169).

---

## 4. Sounds

Lengths in ticks. SFX tracks run at 64 Hz, music tracks at the §2.2 rate. "a+b" = intro + loop period.

| Id | Prio | Tracks | Length |
|---|---|---|---|
| `$01`–`$07` | `$01` | SfxN (`$06`: + an empty Sfx1) | 1, 1, 65, 9, 2, 8, 1 (drum hits) |
| `$08`–`$11`, `$16`–`$1A`, `$1F`, `$20`, `$23`, `$24`, `$27`, `$29` | `$04`–`$2F` | Sfx1 | 10–66 |
| `$12` | `$2F` | Sfx1 + Sfx2 | 50 |
| `$1B`, `$1C`, `$28`, `$2B` | `$10`–`$20` | Sfx1 + SfxN | 41/39, 47/39, 33/27, 147 |
| `$2A` | `$10` | Sfx1 + Sfx2 + SfxN | 40 |
| `$22` | `$40` | SfxN | 117 |
| `$2C` | `$80` | Sfx2 | 48 (pause jingle) |
| `$13` | `$41` | SfxN + Ch1–Ch3 | 89 / 82 / 96 / 0 |
| `$14` | `$40` | Ch1–Ch3 | 288, then `$33`/`$34` |
| `$15` | `$30` | Ch1, Ch2 | 48 |
| `$1D`, `$1E`, `$25` | `$40` | SfxN + Ch1–Ch3 + Drm | 161/156/180/156/0, 131/135/135/114/0, 401/431/412/392/0 |
| `$26` | `$30` | SfxN + Ch1–Ch3 | 161 / 156 / 180 / 156 (each track is a `SND_CALL` into `$1D`'s streams: `$1D` without drums) |
| `$21` | `$40` | Ch1–Ch3 (empty) + Drm | starts `$36` at once (§2.5) |
| `$2D` | `$40` | 4 tracks | 0+768 |
| `$2E` | `$40` | Ch1–Ch3 | 1440+1248 |
| `$2F` | `$40` | Ch1–Ch3 | 576+1800 |
| `$30` | `$40` | Ch1–Ch3 | 1+1224 / 1152+1224 / 0+1224 |
| `$31` | `$40` | Ch1–Ch3 | 288+1440 |
| `$32` | `$40` | Ch1–Ch3 | 1152+1536 / 384+1536 / 384+1536 |
| `$33` | `$40` | 4 tracks | 384+768 |
| `$34` | `$40` | 4 tracks | 0+1392 |
| `$35` | `$40` | Ch1–Ch3 | 0+1536 / 864+1536 / 0+1536 |
| `$36` | `$40` | Ch1–Ch3 | 78+384 / 78+384 / 78+24 |
| `$37` | `$40` | Ch1–Ch3 | 1614, then `$34` |
| `$38` | `$40` | 4 tracks | 204+576 (Drm 204+768) |
| `$39` | `$50` | Ch1–Ch3 | 276 |

The per-id table with stream addresses is in the asm (`SoundTable` / `SndHdrXX`).

---

## 5. Quirks and bugs

1. **Lost ticks** while `PlaySoundFar` runs (§2.1), as in MM.
2. **NR51/NR10 are set even when the priority test fails** (as before).
3. **One return slot**, used as goto (as before).
4. **Fields above `$8C` persist** across sounds on a track.
5. **Lockout refuses drum hits too** (§2.4).
6. **`EA 4n` overwrites the whole flags byte** (§3). Unused here, but Belmont's Revenge uses it.
7. **Release with env 0 retriggers the note** at the same volume instead of cutting it (`VOICE …, 0, g` with g ≠ 0). No stream in this game combines env 0 with a gate.
8. **CH3 decay counts the attenuation twice** (and the fade once).
9. **`StopAll` sets wNR51 = `$FF` without writing NR51**, so the next sound turns every channel on both sides. It also clears one byte past the shadows (`$C2B8`).
10. **A cancelled fade keeps `wFadeTimer`**, so the first step of the next fade can come sooner than 64 ticks.
11. **Vibrato negate is sticky** until the track restarts (as before). `VIBRATO 0` now clears the offset.
12. **Dead code/data:** `$41F3–$4203` (MM's engine check), `StartFade` `$5B20`, `wMusicHold`, `wSweepVal`, `jr nz,+0` at `$4588`, orphan stream bytes `$5FBC–$5FC3`, `$21`'s drum stream running on into `$22` (§2.5).

---

## 6. Verification

- **Byte-exact rebuild** of all seven ranges.
- **Timer:** 63.93 IRQs/s measured, all reaching `SndUpdate` when the game's requests are dropped.
- **Model vs emulator** (`verify/vmodel2.py` + `tools/kmodel2.py`, an independent model of this variant): PyBoy injects `PlaySound` calls at chosen ticks. The game's own requests are dropped (its attract loop stops sounds about every 16 s). On every tick the following are compared: all seven tracks byte for byte, the 20 shadows, every driver global (tempo, queue, NR51, sweep, request, lockout, fade), hardware NR51, wave RAM (while CH3 is off) and the exact set of triggers.
  - Each of the 57 ids alone for 7000 ticks (`verify/run_all2.sh`): **0 mismatches**.
  - Two mixed 9000-tick scenarios (`verify/run_combo2.sh`): both blocking paths and restores, noise SFX against drums, `$0F` no-restart, pause with `$2C`, a fade to `$34` and a fade to `StopAll`, the lockout refusing `$0A` and the running drum track's hits while `$13` passes, chained lockouts `$30`/`$31`/`$32`, all three follow-ups (`$14` with both `wGameC081` values), `StopAll`: **0 mismatches**.
- **Not verified:** `SndPause`/`SndUnpause` and the game's own fade writes were only read, not run (the tests poke `wPause` and `wFadeTarget`). Nothing was checked on hardware or against audio output.

## Files (in `GBAudioLab\Kon`)

- `NEM_SoundDriver.asm`: labelled, commented RGBDS source, byte-exact
- `tools/cfg_nem.py` (asm config), `tools/kmodel2.py` (model of the later variant, shared with Belmont's Revenge), `verify/vmodel2.py`, `verify/run_all2.sh`, `verify/run_combo2.sh`, logs

Regenerate: `python tools/gen_asm.py nem NEM_SoundDriver.asm`.
