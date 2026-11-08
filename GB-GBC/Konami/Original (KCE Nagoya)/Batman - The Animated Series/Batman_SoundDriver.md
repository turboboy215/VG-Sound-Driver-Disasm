# Batman: The Animated Series (GB): sound driver

ROM: `Batman - The Animated Series (U).gb` (DMG, MBC1, 128 KB, internal title `BATMAN ANIMATED`). Konami, 1993.

Part of the Konami family, see `Konami_SoundEngine_Family.md`. This is **Tiny Toon 2's driver** (fourth generation, Goemon branch): the same track code, track layout, packed two-notes-per-byte SFX, noise volume bytes, semitone vibrato, descriptors, requests and flow commands. About 1,600 of its 1,860 instructions line up with Tiny Toon 2's. What changes:

- **SndUpdate, the pause, the tempo, the fade and SndInit move to ROM0**; every track is entered through a ROM0 `RunTrack` that maps bank 7 and jumps to the track code at `$4000`. PlaySound and the tables stay in bank 7;
- it runs on a **64 Hz timer** (TMA 0, 16384 Hz input), not on VBlank;
- tracks one page up (`$C180 + n×$100`), globals at `$C1C3`;
- **a new fade**: NR50 steps down, then the music tracks stop one by one (drums, Ch3, Ch1, Ch2) and NR50 comes back to `$77`; CH4 is muted on every update while it runs, and a request for id `$12` cuts the music at once;
- **the voice byte holds a 7-bit unit again** (no octave in it), **`$EC` writes NR50**, `$F8` sets the volume, **CH3 wave alternation is gone**, and four `$EA` commands are new: field clear (`Ax`), a transpose by a game variable (`Dx`), tempo − 3 (`Ex`) and a **volume ramp** over notes (`Fx`);
- **a drum-track rest no longer writes the joypad register** (it goes to the drum-note code, which ignores id 0); Tiny Toon 2's dead note-volume fade is removed.

| | |
|---|---|
| API | ROM0 `$0307` `PlaySoundFar` (A = id, 0 = stop all; 112 call/jump sites) → bank 7 `$4FDF` `PlaySound` (id in `wReqId` `$C1C8`); `$0CE3` `SndInit` |
| Game inputs | `wPauseFlags` `$DB04` (any value; the driver acts on its changes), `wFadeRate` `$C1CA` (written by the game in 15 places), `wSndMute` `$C8C6` bit 0 (requests dropped), `hKey` `$FFDF` (`$EA Dx`) |
| Tick | **timer, 64 Hz**: `$0050` → `$0085` (enables interrupts, then) `SndUpdate` `$0B18`, skipped while `wSndBusy` `$DB22` bit 0 or 1 is set (bit 1 = a `PlaySoundFar` in progress). 6429 updates in 6000 frames in PyBoy |
| Driver code | ROM0 `$0307–$0330`, `$07C7–$07CF` and `$07E9–$07F0` (the game's bank helpers), `$0B18–$0D19`; bank 7 `$4000–$49BA` (2.5 KB, jump tables at `$4423` and `$44F5`) and `$4FDF–$50B6` |
| Data | bank 7 `$49BB–$4FDE` (tables, headers, drum hits) and `$50B7–$7A97` (streams); `$7A98–$7FFF` is other game data |
| RAM | seven tracks at `$C180 + n×$100` (`$80–$C2`), globals `$C1C3–$C1CE` |
| Channels | Sfx1 (CH1), Sfx2 (CH3), SfxN (CH4), Ch1, Ch2, Ch3, Drm (no channel) |
| Counts | 99 ids `$01–$63`: 13 drum hits, SFX `$0E–$51`, 18 songs `$52–$63` |

`BM_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over ROM0 `$0307–$0330`, `$07C7–$07CF`, `$07E9–$07F0`, `$0B18–$0D19` and bank 7 `$4000–$7A97`. It assembles cleanly with `-Wall`.

```
rgbasm -Wall -o bm.o BM_SoundDriver.asm
rgblink -o bm.gb bm.o
python tools/cmp_ranges.py bm.gb "Batman - The Animated Series (U).gb" 0:0307-0330 0:07C7-07CF 0:07E9-07F0 0:0B18-0D19 7:4000-7A97
```

---

## 1. Structure

### 1.1 Tracks and descriptors

| # | Page | Name | Descriptor | Registers (`$B7–$BA`) |
|---|---|---|---|---|
| 0 | `$C180` | Sfx1 | `$40` | NR11–NR14 |
| 1 | `$C280` | Sfx2 | `$52` | NR31–NR34 |
| 2 | `$C380` | SfxN | `$63` | NR41–NR44 |
| 3 | `$C480` | Ch1 | `$00` | NR11–NR14 |
| 4 | `$C580` | Ch2 | `$11` | NR21–NR24 |
| 5 | `$C680` | Ch3 | `$22` | NR31–NR34 |
| 6 | `$C780` | Drm | `$34` | none (0) |

As Tiny Toon 2: `SndInit` sets the register addresses of tracks 0–5 and the drum track keeps 0. Music Ch1 is blocked while Sfx1 plays and music Ch3 while Sfx2 plays; Ch2 is never blocked.

### 1.2 Track fields

Tiny Toon 2's layout from `$80` to `$BF` (`TRK_PRIO` … `TRK_PANATTEN`), with these changes:

| L | Name | Use |
|---|---|---|
| `$86` | PANFLAGS | 0 autopan, 1 autopan side, 2 vibrato running, 4 semitone vibrato, **5 volume ramp louder, 6 volume ramp quieter**, 7 autopan with both sides (Tiny Toon 2's bits 5/6 were the wave alternation) |
| `$91` | UNIT | the whole 7-bit unit of the voice (`$92` OCTAVE only from `$E1–$E6`) |
| `$BC` | FLAGS3 | 0 high nibble next (Sfx1/Sfx2), 2 noise retrigger pending (Tiny Toon 2's bit 5, octave 6, is gone) |
| `$C0` | – | unused (Tiny Toon 2: TRK_WAVEA) |
| `$C1` / `$C2` | RAMPSTEP / RAMPCNT | **volume ramp**: notes per step, countdown |

### 1.3 Globals

`wTrackDesc` `$C1C3`, `$C1C4` and `$C1CE` (cleared, never read), `wTempo`/`wTempoAcc` `$C1C5/6`, `wReqPrio`/`wReqId` `$C1C7/8`, `wPauseLast` `$C1C9`, `wFadeRate`/`wFadeTimer`/`wFadeStep` `$C1CA–$C1CC`, `wWaveId` `$C1CD`. Tiny Toon 2's `wFadeLevel` is gone; `$C1CA–$C1CC` are a new fade.

---

## 2. Timing

### 2.1 Update

Timer interrupt, 64 Hz. The handler enables interrupts first and skips the update while `wSndBusy` (`$DB22`) bit 0 (an update) or bit 1 (`PlaySoundFar`) is set, so a request from the main loop can cost an update. `SndUpdate` (ROM0): pause edges (§2.5); unless paused `FadeTick`, `TempoTick` and the music tracks Ch1, Ch2, Ch3, Drm; then SfxN, Sfx2, Sfx1 (also while paused). Each track goes through `RunTrack` (descriptor into `wTrackDesc`, nothing if the id is 0, map bank 7, `jp TrackTick`); the game's bank (`hRomBank` `$FFA3`) is mapped again at the end.

### 2.2 Tempo

As Tiny Toon 2: every update `wTempoAcc += wTempo` (when the tempo isn't 0); the carry sets the skip flag of all four music tracks for that update. `$EE` sets the tempo and clears the accumulator; `$EA Ex` takes 3 off `wTempo` (no borrow test). Tempos in the data: `$00`, `$08`, `$10`, `$14`, `$18`, `$1A`, `$20` and `$E0` (song `$59`, whose music then moves on in one update of eight).

### 2.3 Fade-out

The game writes `wFadeRate`. `FadeTick`:

- `wFadeRate` 0: NR50 is set back to `$77` (when it reads otherwise) – on **every** update, so an `$EC` NR50 write only lasts until the next update when no fade runs;
- otherwise, and only while music Ch2 plays: if `wReqId` (the **last request**) is `$12` all four music tracks stop at once and the fade ends; else CH4 is muted (NR42 = 8, NR44 = `$80`) and every `wFadeRate` updates NR50 goes down by `$11`. When NR50 reads `$11` the rate becomes 1 and `wFadeStep` counts the updates: **4 stops Drm, 8 stops Ch3** (and mutes CH3 unless Sfx2 plays), **12 stops Ch1** (mutes CH1 unless Sfx1 plays), **18 stops Ch2**, clears the fade and writes NR50 = `$77`.

Starting a song clears `wFadeRate`/`wFadeTimer`/`wFadeStep`. Tiny Toon 2's NR50 fade with the doubling rate and its dead note-volume fade are gone, and a noise SFX no longer cancels the fade.

### 2.4 Requests

`PlaySoundFar` drops the request while `wSndMute` bit 0 is set; otherwise it sets `wSndBusy` bit 1, stores `wReqId`, maps bank 7 (`MapBank7`), runs `PlaySound` and maps the game's bank again (`SetBank`).

`PlaySound` is Tiny Toon 2's with two lines removed: 0 → `StopAll`; else the header from `SoundTable` (`$49BB`, the code adds `2 × id` to `$49B9`). **If any SFX track of the mask holds a higher priority, nothing starts.** SFX tracks start without tests (Sfx1 NR10 = 8, SfxN NR51 |= `$88`). Music needs the Ch1 bit and a priority ≥ Ch1's: it resets tempo and fade, clears `$C1C4`, writes NR10 = 8 and starts Ch1–Ch3/Drm. A started track gets LEN = 1, `$85–$8F` = 0, FLAGS3 = RELVOL = 0, `wWaveId` = 0 and NRx2 = 0 (the drum track: `$FF00` = 0). The SfxN start no longer cancels a fade, and the music start no longer writes NR50.

Drum notes start drum hits `$01–$0D` (SfxN, `$07`/`$08` also Sfx1, all at priority `$20`), each SFX track with its own priority test; **a drum-track rest (hi 0) goes the same way and does nothing.**

### 2.5 Pause

As Tiny Toon 2, but on the whole byte `wPauseFlags` (`$DB04`) compared with `wPauseLast`: a change to non-zero pauses (stop SfxN, mute CH4 and CH2), a change to 0 unpauses (stop Sfx1 and Sfx2, NR10 = 8, mute CH1, NR32 = 0, give CH1 and CH3 back to the music, mark Ch1–Ch3 for a long-note retrigger). No music track runs while paused.

---

## 3. Data format

Tiny Toon 2's format (see `TinyToon2_SoundDriver.md` §3) except:

| Byte | Meaning |
|---|---|
| `$00–$DF` (Drm) | drum hit hi; **hi 0 is a rest without a register write** |
| `$E0 u v g` | voice: **unit = u & `$7F`** (no octave code), duty/wave = v >> 4, vol = v & 15, gate = g >> 4, env = g & 15; autopan off, **volume ramp off**, attenuation 0, **release volume 0**, both sides. SfxN: `$E0 u v`, unit = u & `$7F`, NR42 = swap(v) at the next noise note |
| `$EA xy` | 0 duty (CH3: wave), 1/2/3 pan both / high nibble / low nibble + attenuation y (also stops the ramp), 4/5 autopan, 7/8 transpose up/down y, 9 release volume y, **A clear: y bit 3 vibrato, bit 2 duty step, bit 1 detune, bit 0 attenuation**, **D transpose by (hKey mod 3) + y semitones**, **E tempo − 3**, **F volume ramp**: every (y & 7) + 1 notes the attenuation goes up one level (y & 8; quieter) or every y + 1 notes down one level (louder), 6/B/C no-ops. All 16 entries are in `ExtTable` |
| `$EC x` | **NR50 = x** (at once) |
| `$F0–$F7` | attenuation (`$F0–$F8` in Tiny Toon 2); also stops the volume ramp |
| `$F8 x` | **volume = swap(x), attenuation 0** |

Everything else is unchanged: packed SFX notes (a voice sets FLAGS3 bit 0, so the next byte starts with its high nibble; low nibble `$E` = new unit, `$F` = the next byte is a command), the noise bytes `$C0–$DF`, `$E1–$E6` octave, `$E7` unit, `$E8` gate/env, `$E9` NR10, `$EB n xy` / `$EB n|$80` vibrato, `$ED xy` duty step, `$EE` tempo, `$EF` detune, `$F9 n addr`, `$FA addr`, `$FB`/`$FC` loop markers, `$FD` call/return, `$FE` mark/jump, `$FF` end.

Note-on as Tiny Toon 2 with two changes: the **detune is always added** (Tiny Toon 2 skipped it when its low byte was 0), and after the vibrato restart the **volume ramp** steps: when PANFLAGS bit 5 or 6 is set, RAMPCNT counts down and at 0 is reloaded from RAMPSTEP and ATTEN goes `$10` down (bit 5) or up (bit 6). NRx2 = TRK_VOL − TRK_ATTEN through `WriteVolume` (no fade term).

Release: as Tiny Toon 2, but a pending long-note retrigger is also done after the release tick (Tiny Toon 2 only before it), and on CH3 the release volume is written once at the release tick instead of on every tick after it.

### 3.1 Tables (bank 7)

| Addr | Name | Content |
|---|---|---|
| `$49BB` | `SoundTable` | ids `$01–$63` (the code adds from `$49B9`, the last two code bytes); headers `$4A81–$4D26` |
| `$4D27` | `WaveTable` | 15 entries, 9 distinct waves at `$4D45` (from `$4D25`) |
| `$4DD5` | `PeriodTable` | 85 periods (the code adds from `$4DBB`) |
| `$4E7F` | `VibratoTable` | 11 (from `$4E7D`) |
| `$4F06` | `Vibrato2Table` | 16 semitone tables (from `$4F04`) |
| `$4F4B` | drum hits | streams to `$4FDE` |
| `$4423` | `CommandTable` | `$E7–$FF` (from `$4415`) |
| `$44C0` | `OctaveCodes` | `$18 $30 $48 $60 $78 $90` for `$E1–$E6` |
| `$44F5` | `ExtTable` | `$EA x0–xF` |

---

## 4. Sounds

Lengths in updates (64 Hz; music minus tempo skips).

| Ids | Prio | Tracks | Notes |
|---|---|---|---|
| `$01–$0D` | `$20` | SfxN (`$07`, `$08` + Sfx1) | drum hits, 1–101 ticks (`$0B` 1507, `$0D` loops) |
| `$0E–$51` | `$10–$FF` | Sfx1, Sfx2 and/or SfxN | SFX, up to 281 ticks |
| `$10`, `$11` | `$20` / `$10` | SfxN + Ch1–Ch3 (+ Drm) | short tunes on the music tracks that end (≈ 1600 ticks) |
| `$23`, `$2A`, `$2B`, `$50` | `$40–$FF` | SFX tracks + all four music tracks on an empty stream (`$50D7`) | SFX that stop the music |
| `$24`, `$42`, `$51` | `$40`/`$FF` | SFX tracks + music tracks | SFX with music parts (`$42` loops) |
| `$52–$63` | `$40` | Ch1–Ch3 + Drm | the songs; `$56` and `$5E` end, the rest loop |

The intro/loop lengths per track: `python tools/kdata9.py bm -v`.

---

## 5. Quirks and bugs

1. **A track start still writes the joypad register**: the drum track's NRx2 = 0 goes to `$FF00` (every song start). Drum rests no longer do (16 drum rests in the data).
2. **The fade mutes CH4 on every update** while it runs (with music Ch2 playing), so noise SFX are cut during fades; and **a last request of `$12`** (a noise SFX) **stops the music** at the next fade update.
3. **`$EC` is undone at the next update**: without a fade `FadeTick` writes NR50 = `$77` whenever it reads otherwise. Used once (Sfx1 of `$4D`).
4. **The volume ramp has no bounds**: ATTEN goes up or down by `$10` without a test, and the note volume TRK_VOL − TRK_ATTEN isn't tested for a borrow either (as Tiny Toon 2).
5. **`$EA Dx` depends on game state** (`hKey`, `$FFDF`, mod 3); it is used 9 times, in Ch1–Ch3 of songs `$5C` and `$62`. The volume ramp is used in Ch1/Ch2 of 15 sounds, `$EA Ax` once (Ch1 of `$62`).
6. **`$EA Ex` can wrap the tempo** (`wTempo − 3` without a test); used once, by the Sfx1 stream of SFX `$4F`, so that SFX slows the running song down.
7. **The unit isn't set at a track start**: id `$11`'s drum stream (`DRUM $0B, 3` with no voice) gets 3 × whatever unit the drum track had before (256 updates after a power-on).
8. **An unchanged volume isn't retriggered** (`WriteVolume` compares with the read-back, as Tiny Toon 2).
9. **Pausing mutes CH2, unpausing doesn't give it back** (as Tiny Toon 2).
10. **`$EA 4x` clears the vibrato-running flag** (as Tiny Toon 2).
11. **Unused / dead:** `$C1C4`, `$C1CE`, field `$C0`, FLAGS bit 1, `DeadSavePtr` (`$48E0`), a dead `ld a,b` in `Cmd_Volume`, `$EA 6x/Bx/Cx`; four orphan streams at `$50B7`, `$50C0`, `$5109`, `$5128` (decoded in the asm), 14 unreachable `$FF` bytes after ends.

---

## 6. Verification

- **Byte-exact rebuild** of the ranges above.
- **Rate:** one update per 64 Hz timer interrupt (6429 updates in 6000 frames in PyBoy; TMA 0, TAC 4).
- **Streams vs emulator** (`verify/vstream9.py`, lighter than the earlier models): every id alone for 4000 updates (62 s), with the game's own requests dropped; every store of TRK_LEN in the track code is hooked, and the stream address and length of each note, rest and noise byte the driver reads must equal the decoder's (`tools/kdata9.py`) in order, each lasting its length plus the tempo skips, and the tracks the decoder ends must end. Reads after a track is taken over (drum hits on SfxN) are left out. **99 ids, 43,160 reads, 0 mismatches** (`verify/run_stream_bm.log`).
- **Not verified:** the register writes (no update-by-update model this time), the fade, the pause, the volume ramp and `$EA Dx` were only read; nothing was checked on hardware.

## Files (in `GBAudioLab\Kon`)

- `BM_SoundDriver.asm`: labelled, commented RGBDS source, byte-exact
- `tools/kdata9.py` (data decoder for Batman and Raging Fighter), `tools/cfg_bm.py`, shared `tools/gen_asm3.py`, `tools/align.py` (instruction alignment against another driver), `tools/gaps9.py` (unowned data bytes), `verify/vstream9.py`, `verify/run_stream_bm.sh`, log

Regenerate: `python tools/gen_asm3.py bm BM_SoundDriver.asm`.
