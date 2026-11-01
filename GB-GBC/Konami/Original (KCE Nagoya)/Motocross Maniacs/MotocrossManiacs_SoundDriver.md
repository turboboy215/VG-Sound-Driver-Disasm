# Motocross Maniacs (GB): sound driver

ROM: `Motocross Maniacs (E) [!].gb` (DMG, no MBC, 32 KB, internal title `MOTOCROSSMANIAC`). Konami, 1989.

Part of the Konami family, see `Konami_SoundEngine_Family.md`. This is the **7-track variant**: the same command language as The Castlevania Adventure, but a reorganised driver.

| | |
|---|---|
| API | `$6576` `SndInit`, `$6C1F` `PlaySound` (A = id, 0 = stop all; keeps all registers), `$6BCA` `SndPause`, `$6BDF` `SndUnpause`, `$7FE3`/`$7FDE` `SetCourseTempoA/B` (game-side tempo override) |
| Game inputs | `wEnginePitch` `$C10D` (engine sound pitch, written every frame from `$C7A0`), `wCourse` `$C018` (picks the follow-up music) |
| Tick | **timer IRQ only**, 64 Hz (TAC = `%111`, TMA = 0; PyBoy counted 63.8 updates/s; the shortfall is presumably ticks skipped by the locks, §2.1). `$0050` → `$006D` `TimerISR` → `$6591` `SndUpdate` |
| Music rate | 64 Hz × (1 − tempo/256) (§2.2) |
| Driver code | `$6576–$6DCD` (2.1 KB) + ROM0 helpers (`rst $28`, `rst $38`, `$0229`, `$0243–$0251`, `$02B2–$02D0`) |
| Tables + data | `$6DCE–$7FDD` (4.6 KB), then the course tempo routine + tables `$7FDE–$7FFE` |
| RAM | seven tracks at `$C080 + n×$100` (`$25` bytes each), globals `$C100–$C10D`, shadows `$C200–$C213`; locks `$C00B` (ISR), `$C01F` (PlaySound), pause `$C012` |
| Channels | Sfx1 (CH1), Sfx2 (CH2), SfxN (CH4), Ch1, Ch2, Ch3, Drm (drums = SFX ids 1–7 on SfxN) |
| Counts | 32 sound ids: 7 drum hits, 17 SFX/jingles (`$08–$18`), 8 music (`$19–$20`) |

`MM_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over ROM0 `$0028–$002C`, `$0038–$003A`, `$0050–$0052`, `$006D–$008E`, `$0229–$022F`, `$0243–$0251`, `$02B2–$02D0`, `$0480–$04AC` and `$6576–$7FFF`. It assembles cleanly with `-Wall`.

```
rgbasm -Wall -o mm.o MM_SoundDriver.asm
rgblink -o mm.gb mm.o
python tools/cmp_ranges.py mm.gb "Motocross Maniacs (E) [!].gb" 0:0028-002C 0:0038-003A 0:0050-0052 0:006D-008E 0:0229-022F 0:0243-0251 0:02B2-02D0 0:0480-04AC 1:6576-7FFF
```

---

## 1. Structure

The tracks are processed **in place**, with no working copy. Track n's page is `H = $C0 | n` (`GetTrackPage`), and its fields sit at `L = $80–$A3` (`TRK_*` constants in the asm).

| # | Page | Name | Channel (reg base) | NR51 at start | Runs |
|---|---|---|---|---|---|
| 0 | `$C080` | Sfx1 | CH1 (`$00`) | `$11` | every IRQ |
| 1 | `$C180` | Sfx2 | CH2 (`$05`) | `$22` | every IRQ |
| 2 | `$C280` | SfxN | CH4 (`$0F`) | `$88` | every IRQ |
| 3 | `$C380` | Ch1 | CH1 (`$00`) | `$11` | music ticks (every IRQ while it holds sound `$09`) |
| 4 | `$C480` | Ch2 | CH2 (`$05`) | `$22` | music ticks |
| 5 | `$C580` | Ch3 | CH3 (`$0A`) | `$44` | music ticks |
| 6 | `$C680` | Drm | – (plays SFX) | – | music ticks |

**Channel sharing:** Ch1 is muted while Sfx1 plays, and Ch2 while Sfx2 plays (`IsBlocked`). A music `PAN` is dropped only on Ch1. CH4 works as in CVA: drum notes are `PlaySound(DrumMap[n−1])` (priority 1) on SfxN.

### 1.1 Track fields (`L` offset)

| L | Name | | L | Name |
|---|---|---|---|---|
| `$80` | id | | `$8F` | period (2) |
| `$81` | prio | | `$91` / `$92` | vol / duty (CH3: wave) |
| `$82` | ptr (2) | | `$93` / `$94` | env / gate |
| `$84` | len | | `$95` | reltick |
| `$85` | flags (b0 released, b3 vib negate, b6 force, b7 rest) | | `$96` / `$97` | vibrato timer / reload |
| `$86` | repeat counter | | `$98` / `$99` | CH3 decay timer / reload |
| `$87` | vibrato index | | `$9B` | level: CH3 level code, other tracks the last NRx2 volume byte (write-only there) |
| `$88` | transpose | | `$9C` | segno (2) |
| `$89` | attenuation | | `$9E` | return address (2, one slot) |
| `$8A` | vibrato offset (2) | | `$A0` | vibrato pointer (2) |
| `$8C` | vibrato repeat counter | | `$A2` / `$A3` | vibrato index / loop index |
| `$8D` / `$8E` | unit / octave | | | |

`PlaySound` sets id, prio, ptr, `len = 1`, `flags = $40` and zeroes `$86–$8C`. As in CVA, everything above that persists.

### 1.2 Globals

| Addr | Name | Use |
|---|---|---|
| `$C100` | wTrackIdx | |
| `$C101` | wRegBase | |
| `$C102` | wTempo | |
| `$C103` | wTempoAcc | |
| `$C104` | wTempoSkip | |
| `$C105` | wQueuedSnd | started at the end of `SndUpdate` |
| `$C106` | wNR51 | |
| `$C107` | wSweepVal | write-only |
| `$C108`–`$C10B` | | temporaries |
| `$C10C` | wMusicHold | read, never written |
| `$C10D` | wEnginePitch | |

---

## 2. Timing

### 2.1 Interrupt glue

`TimerISR` (`$006D`) re-enables interrupts at once. It runs `SndUpdate` unless `PlaySound` is in progress (`wPlayLock` `$C01F` bit 0) or the ISR is already inside the update (`wIsrLock` `$C00B`). **Either case loses that tick.** The game calls `PlaySound` directly (no banking), so every main-thread request that overlaps an IRQ costs a tick. That's presumably why PyBoy counted 63.8 updates per second instead of 64.0.

### 2.2 Music rate and tempo

Every IRQ: `wTempoAcc += wTempo`, and a carry sets `wTempoSkip`. Tracks 0–2 always run. Normally the update stops before track 3 when the skip flag (or `wMusicHold`) is set. If track 3 holds the engine sound `$09`, track 3 runs anyway and the stop is moved to track 4. There's no half-rate parity as in CVA, so music runs at **64 × (1 − tempo/256) Hz** (exact, measured).

| Tempo | Rate | Used by |
|---|---|---|
| `$18` | 58.0 Hz | `$19`, `$1B` (start) |
| `$20` | 56.0 Hz | `$1A`, `$1B`, `$1C` |
| `$34` | 51.0 Hz | `$1E`, `$20` |
| `$40`, `$50`, `$60` | 48, 44, 40 Hz | `$1B`, `$1C`; `$1D` = `$50` |
| `$84` | 31.0 Hz | `$1F` |

**Course tempo override.** The race code at `$0B21` calls `SetCourseTempoB` (`$7FDE`, table `$7FFB`: `50 38 80 30`). When `$C882` = 0 and `$C881` < `$10` (apparently the race timer under 10) it calls `SetCourseTempoA` instead (`$7FE3`, table `$7FF7`: `28 18 70 10`, i.e. faster), or plays `$12` once in the other game mode (`$C008` bit 2). Both only act if Ch3 holds a course song `$1D–$20`, and set `wTempo = table[id − $1D]`. So the course songs' own `TEMPO` commands are overridden in play (`$1D`: `$50` → same; `$1E`: `$34` → `$38`; `$1F`: `$84` → `$80`; `$20`: `$34` → `$30`).

### 2.3 Pause

While `wPause` ≠ 0 only track 1 runs, and only while it plays `$08` (the pause jingle; `PauseToggle` `$0480` calls `SndPause` then plays `$08`). The queued-sound check still runs. `SndUnpause` copies the shadows back, but CH4 only if the SfxN id is ≥ 8 (not a drum). Nothing is retriggered.

### 2.4 Engine sound and follow-up music

- **`$09` (engine)** is a 2-tick looping Ch1 stream with priority 8. `WritePeriod` replaces the vibrato offset of sound `$09` by `wEnginePitch × 8` on every period write. The game writes `wEnginePitch` from `$C7A0` each frame (`$0A80`), presumably the bike speed. The course songs (`$1D–$20`) use only Ch2 and Ch3, leaving CH1 to the engine.
- **`$11`** (a jingle on Sfx2 + Ch3): when one of its tracks ends, `QueueFollowUp` puts `FollowUpTable[wCourse − 1]` (`$678D`: `20 1E 1F 1D 20 1E 1F 1D`) into `wQueuedSnd`. `SndUpdate` starts it after the last track, so the course music follows the start jingle automatically. With `wCourse = 0` it would read `$688C` (code) and start garbage.

---

## 3. Data format

Identical to The Castlevania Adventure (see that doc, §3.2–3.4), with these differences:

| | CVA | MM |
|---|---|---|
| Track roles for `E0`/notes | SfxN = 1, Drm = 5, CH3 = 4 | SfxN = 2, Drm = 6, CH3 = 5 |
| `EA 4n` | autopan | **no-op** (`EXT_NOP`) |
| Effects on the drum track | vibrato/release code runs (harmless) | skipped |
| `VIBRATO n` | loads the pointer | also clears the vibrato repeat counter |
| End of an Sfx1/Sfx2 track | restore duty (+ NR10 = 0) | restore duty **and period** of the music track (+ NR10 = 0 on CH1); silence via NRx2 = 0 + trigger instead of NRx4 = `$80` |
| Wave pointer index | | 9 waves at `$6EA0`, 16 bytes each, no overlap |

### 3.1 Tables

| Addr | Name | Content |
|---|---|---|
| `$6DCE` | `PeriodTable` | 96 periods, same values as CVA |
| `$6E8E` | `WaveTable` | 9 pointers → `$6EA0–$6F2F` |
| `$6F30` | `SoundTable` | 32 pointers |
| `$6F70–$7001`, `$700F–$702A` | headers | |
| `$7002` | `DrumMap` | 13 entries `01 02 01 03 03 03 03 04 05 06 07 07 07` |
| `$7061` | `VibratoTable` | 15 pointers (entries 1, 4–8, 11, 14 = `Vib01`) |
| `$707F–$70C7` | vibrato data | `Vib01` +1, `Vib02` −1, `Vib03` −2 (negated), `Vib0D`/`Vib0A`/`Vib0C` +2/+3 vibratos (`Vib09` adds a long delay and falls through into `Vib0A`), `Vib0F` a +1 … +12 bend |
| `$702B–$7FDD` | streams | |

---

## 4. Sounds

Lengths in ticks. SFX tracks run at 64 Hz, music tracks at the §2.2 rate.

| Id | Prio | Tracks | Length |
|---|---|---|---|
| `$01`–`$07` | `$01` | SfxN | 1, 7, 65, 130, 9, 65, 2 (drum hits) |
| `$08` | `$80` | Sfx2 | 42 (pause jingle) |
| `$09` | `$08` | Ch1 | 2-tick loop (engine) |
| `$0A`, `$0B`, `$0C`, `$17` | `$04` | Sfx1 + SfxN | 42/64, 62/82, 6/5, 8/26 |
| `$0D`, `$0E`, `$15` | `$04` | Sfx1 | 40, 48, 2 |
| `$0F` | `$04` | Sfx1 + Sfx2 | 54 / 60 |
| `$10`, `$11` | `$04` | Sfx2 + Ch3 | 36/37, 54/55 (`$11` queues the course song) |
| `$12` | `$08` | Sfx1 | 120 |
| `$13`, `$14`, `$16`, `$18` | `$03`/`$04`/`$04`/`$08` | SfxN | 48, 26, 54, 232 |
| `$19` | `$10` | 4 tracks | 896 loop (Drm 42+224) |
| `$1A`, `$1B`, `$1C` | `$10` | 4 tracks | 366, 486, 235, end |
| `$1D` | `$10` | Ch2, Ch3 | 1920 loop |
| `$1E` | `$10` | Ch2, Ch3 | 1536+1728 / 1280+1728 |
| `$1F` | `$10` | Ch2, Ch3 | 192+768 |
| `$20` | `$10` | Ch2, Ch3 | 320+2960 |

Music uses priority `$10`. So the jingles `$10`/`$11` (priority 4) only get Ch3 when no music holds it, and the engine `$09` (priority 8) only gets Ch1 when no 4-track song holds it.

---

## 5. Quirks and bugs

1. **Lost ticks** whenever `PlaySound` overlaps the timer IRQ (§2.1).
2. **NR51/NR10 are set even when the priority test fails** (as CVA).
3. **One return slot**, used as goto (as CVA).
4. **Fields above `$8C` persist** across sounds on a track.
5. **Sticky negate + stale offset:** `Vib02`/`Vib03` set flag b3, which stays set until the track restarts, and `VIBRATO 0` keeps the last offset. Ch1 of `$1A` (`VIBRATO 2` then 0) and Ch3 of `$20` (alternating 2 and 0) therefore play their "plain" notes 1 period unit flat. Ch3 of `$1B` keeps +1, and Ch2 of `$20` (`Vib09`/`Vib0A` → 0) keeps whichever value its vibrato loop was on (+3 or 0).
6. **A drum-track `REST` cuts the noise SFX** (NR42 = 0 / NR44 = `$80`). There are 4 in the data.
7. **SfxN notes don't retrigger** (as CVA).
8. **CH3 decay sets NR32 bit 4** (as CVA).
9. **`$11` with `wCourse = 0`** would start a garbage id (§2.4). Doesn't happen in normal play.
10. **Dead code/data:** `wMusicHold` (never written), `wSweepVal` (write-only), `and $04` before an unconditional call at `$6732`, a stray `ret` at `$6897`, a `$FF` after four `SND_JUMP`s (`$7808`, `$78CA`, `$7B65`, `$7E23`), 41 unreferenced bytes at `$79A1–$79C9`, and the `$FF` pad at `$7FFF`.

---

## 6. Verification

- **Byte-exact rebuild** of all nine ranges.
- **Timer:** 1.0687 IRQs per frame measured on the title screen (63.83 Hz; nominal 64 Hz).
- **Model vs emulator** (`verify/vmodel.py`, same method as CVA: all seven tracks byte for byte, shadows, NR51, tempo/skip/queue, wave RAM, triggers per tick):
  - each of the 32 ids alone for 7000 ticks: **0 mismatches** (`$11` run with `wCourse` = 1, so it queues `$20`);
  - one mixed 9000-tick scenario: music + SFX on all three SFX tracks, both blocking paths and the end-of-SFX restores, engine sound with changing `wEnginePitch`, `$11` → follow-up with `wCourse` = 3, pause with `$08`, `StopAll`: **0 mismatches**.
- **Not verified:** `SndPause`/`SndUnpause` and the course tempo routine were only read, not run. Nothing was checked on hardware.

## Files (in `GBAudioLab\Kon`)

- `MM_SoundDriver.asm`: labelled, commented RGBDS source, byte-exact
- shared `tools/` and `verify/` (see the CVA doc), config `tools/cfg_mm.py`

Regenerate: `python tools/gen_asm.py mm MM_SoundDriver.asm`.
