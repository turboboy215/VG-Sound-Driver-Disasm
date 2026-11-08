# Raging Fighter (GB): sound driver

ROM: `Raging Fighter (UE) [!].gb` (DMG, MBC1, 256 KB, internal title `RAGING FIGHTER`). Konami, 1993.

Part of the Konami family, see `Konami_SoundEngine_Family.md`. This is the **Batman driver in two banks**: Batman's ROM0 update/tempo/fade layout and track code (about 1,490 of Batman's 1,860 instructions line up), Tiny Toon 2's stream language, and Ganbare Goemon's way of reading streams from other banks. It differs from Batman in these ways:

- **two sound banks**: ids below `$A0` in bank 14, ids `$A0` and up in bank 15; PlaySound and the header reading move to ROM0, and **every stream read goes through ROM0 `FarRead`**, which copies 4 bytes from the track's bank into `wReadBuf` (`$C1E1`), as in Goemon;
- it runs on **VBlank** again (59.7 Hz), and has **no pause**;
- tracks at `$C0A0 + n×$100` with **one unused byte inserted after `TRK_VIB`** (all later fields one up from Batman's/Tiny Toon 2's, plus `$20`);
- **request `$0F` is a delayed `$10`** (47 updates later); every other request sets NR50 = `$77`;
- **`$EC x` starts a fade** (songs fade themselves out); the fade's stop order is Drm, Ch1, Ch2, Ch3, and it leaves NR50 at `$11`;
- the packed SFX notes **always start with the high nibble** (the voice doesn't touch the nibble flag), **`$E0 u|$80 v` is a 3-byte voice on any track** with NRx2 written at once, noise `$C1–$CF` write NR42 at once, `$E8` also clears the release volume;
- of Batman's new commands only `$EA Ax` (clear) and `$F8` (volume) are kept: no volume ramp, key transpose, tempo − 3 or `$EC` NR50 write; the pans don't set the attenuation;
- **drum-track rests write the joypad register again** (as Tiny Toon 2), but a track start writes no registers at all.

| | |
|---|---|
| API | ROM0 `$0EAE` `PlaySoundAlways` (A = id, 0 = stop all; 76 call/jump sites) and `$0EA4` `PlaySoundFar` (the same, but dropped while `wSndMute` `$C15B` is set; 3 sites) → ROM0 `$0F01` `PlaySound` (id in `wReqId` `$C0E6`); `$0ECA` `SndInit` |
| Game inputs | `wFadeRate` `$C0E8` (written by the game in 17 places, and by `$EC`), `wSndMute` `$C15B`, `wSndLock15` `$C26B` (bank-15 requests refused) |
| Tick | **VBlank**: the handler calls `SndUpdateFar` `$0098` → `SndUpdate` `$1001`, skipped while `wSndBusy` `$C004` bit 0 or 1 is set (bit 1 = a request in progress). The timer vector also points there, but the timer interrupt returns at once (`$0050` is a `reti`) |
| Driver code | ROM0 `$0098–$00AA`, `$01E2–$0212`, `$0EA4–$1119` (0.7 KB); bank 14 `$4654–$4FC2` (2.4 KB, jump tables at `$4A5D` and `$4B38`) |
| Data | bank 14 `$4000–$4653` (tables, headers, drum hits) and `$4FC3–$7C68` (songs); bank 15 `$4000–$7EC3` (table, headers, SFX, songs); the rest of both banks is `$FF` |
| RAM | seven tracks at `$C0A0 + n×$100` (`$A0–$E0`), globals `$C0E1–$C0EE`, `wReadBuf` `$C1E1–$C1E4` |
| Channels | Sfx1 (CH1), Sfx2 (CH3), SfxN (CH4), Ch1, Ch2, Ch3, Drm (no channel) |
| Counts | 119 ids: bank 14 `$01–$18` (11 drum hits, 13 music ids), bank 15 `$A1–$FF` (70 SFX `$A2–$E7`, 25 songs and stops) |

`RF_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over ROM0 `$0098–$00AA`, `$01E2–$0212`, `$0EA4–$1119` and all of banks 14 and 15. It assembles cleanly with `-Wall`. Bank-15 labels carry a `B15_` prefix where they aren't sound labels.

```
rgbasm -Wall -o rf.o RF_SoundDriver.asm
rgblink -o rf.gb rf.o
python tools/cmp_ranges.py rf.gb "Raging Fighter (UE) [!].gb" 0:0098-00AA 0:01E2-0212 0:0EA4-1119 E:4000-7FFF F:4000-7FFF
```

---

## 1. Structure

### 1.1 Tracks and descriptors

| # | Page | Name | Descriptor | Registers (`$D8–$DB`) |
|---|---|---|---|---|
| 0 | `$C0A0` | Sfx1 | `$40` | NR11–NR14 |
| 1 | `$C1A0` | Sfx2 | `$52` | NR31–NR34 |
| 2 | `$C2A0` | SfxN | `$63` | NR41–NR44 |
| 3 | `$C3A0` | Ch1 | `$00` | NR11–NR14 |
| 4 | `$C4A0` | Ch2 | `$11` | NR21–NR24 |
| 5 | `$C5A0` | Ch3 | `$22` | NR31–NR34 |
| 6 | `$C6A0` | Drm | `$34` | none (0) |

The descriptors, the register addresses (the drum track keeps 0) and the channel blocking are Batman's and Tiny Toon 2's.

### 1.2 Track fields

Tiny Toon 2's/Batman's field at L is here at L + `$20` up to `TRK_VIB`, and at L + `$21` from `TRK_DETUNE` on:

| L | Name | Batman L | Use |
|---|---|---|---|
| `$A0–$A8` | PRIO … VIB | `$80–$88` | |
| `$A9` | – | – | **inserted, unused** |
| `$AA–$DC` | DETUNE … LASTPITCH | `$89–$BB` | (register addresses `$D8–$DB`) |
| `$DD` | FLAGS3 | `$BC` | 0 **low nibble next** (Sfx1/Sfx2), 2 noise retrigger pending |
| `$DE` / `$DF` | RELVOL / PITCHIDX | `$BD` / `$BE` | |
| `$E0` | MUTE | (`$BF` PANATTEN) | bit 7: every stream byte only mutes the channel; nothing sets it |

PANFLAGS (`$A6`): 0 autopan, 1 autopan side, 2 vibrato running, 4 semitone vibrato, 5 set by a pitch-13 note (never read), 6 autopan with both sides (Batman's bit 7). The start clears `$A5–$AF` (up to DUTYTICKS; DUTYCNT is no longer in the cleared range).

### 1.3 Globals

`wTrackDesc` `$C0E1`, `wTempo`/`wTempoAcc` `$C0E3/4`, `wReqPrio`/`wReqId` `$C0E5/6`, `wFadeRate`/`wFadeTimer`/`wFadeStep` `$C0E8–$C0EA`, `wWaveId` `$C0EB`, `$C0EC` (cleared, never read), `wDelayTimer` `$C0EE`, `wReadBuf` `$C1E1–$C1E4`. The game keeps its bank in `wRomBank` `$C002`.

---

## 2. Timing

### 2.1 Update

Once per VBlank (so none while the game has the LCD off): `FadeTick`, `TempoTick`, `DelayTick`, then Ch1, Ch2, Ch3, Drm, SfxN, Sfx2, Sfx1, each through `RunTrack` (descriptor into `wTrackDesc`, nothing if the id is 0, map bank 14, `jp TrackTick`); the game's bank is mapped again at the end. `TrackTick` calls `FarRead` before every command or note it reads; the arguments come from `wReadBuf`, and each consumed byte is an `inc de`.

### 2.2 Tempo

As Batman and Tiny Toon 2. Tempos in the data: `$02`, `$08`, `$0C`, `$10`, `$18`, `$1C`, `$20`, `$30`.

### 2.3 Fade-out

`wFadeRate` is set by the game or by `$EC x` in a stream (Ch2 of songs `$13–$17` and `$FF`, Ch1 of `$A1`: those songs fade themselves out). Every `wFadeRate` updates NR50 goes down by `$11`; when it reads `$11` the rate becomes 1 and `wFadeStep` counts the updates: **`$10` stops Drm, `$18` Ch1** (CH1 muted unless Sfx1 plays), **`$1C` Ch2** (CH2 muted), **`$20` Ch3** (CH3 muted unless Sfx2 plays) and ends the fade. NR50 stays at `$11` until the next request. If music Ch2 isn't playing at a fade step, `wFadeRate` is cleared and the fade stops where it is. Starting a song clears the fade; **every request except 0 and `$0F` writes NR50 = `$77`** (even a refused one), and a running fade then starts its ramp again from there.

### 2.4 Requests

`PlaySound` (ROM0), id in A:

| Id | Action |
|---|---|
| 0 | `StopAll` (bank 14): priorities and ids cleared, CH1/CH2/CH4 muted and triggered, NR30 = NR32 = 8, **NR10 = 8**, NR51 = `$FF` |
| `$0F` | `wDelayTimer` = 1; `DelayTick` counts it to `$30` and then requests `$10` (47 updates later) |
| `$01–$9F` | NR50 = `$77`; header from bank 14 `SoundTable` (`$4000`, index id; valid `$01–$18`) |
| `$A0–$FF` | NR50 = `$77`; refused while `wSndLock15` is set; header from bank 15 `SoundTable15` (`$4000`, index id − `$A0`; valid `$A1–$FF`) |

Then Batman's logic: if any SFX track of the mask holds a higher priority nothing starts; SFX tracks start without tests (Sfx1 NR10 = 8, SfxN NR51 |= `$88`); music needs the Ch1 bit and a priority ≥ Ch1's and resets tempo and fade. A started track gets LEN = 1, `$A5–$AF` = 0, FLAGS3 = RELVOL = 0, `wWaveId` = 0 – **no NRx2 = 0 write** (so no joypad write at a start).

Drum notes start bank-14 drum hits `$01–$0A` (SfxN, `$07–$09` also Sfx2, priority `$20`); a refused drum-hit track skips its pointer bytes.

### 2.5 Pause

There is none: no pause flag is read; `PlaySoundFar`'s `wSndMute` and `wSndLock15` are the only game controls besides the fade.

---

## 3. Data format

Batman's format (§3 of `Batman_SoundDriver.md`, itself Tiny Toon 2's) except:

| Byte | Meaning |
|---|---|
| `$00–$DF` (Sfx1, Sfx2) | **two notes, high nibble first** (FLAGS3 bit 0 clear), then the same byte for the low nibble; low nibble `$E`: the next byte is the new unit; **`$F`: go on with the next byte**, read as usual (in the data always a command). The voice doesn't change the nibble order |
| `$00–$DF` (Drm) | drum hit hi; **hi 0 is a rest that writes NRx2 = 8 + trigger to `$FF00`** |
| `$C1–$CF` (SfxN) | volume nibble, **NR42 written at once**, retrigger at the next noise note |
| `$E0 u v g` | voice, unit = u & `$7F`: duty, vol, gate, env, autopan off, attenuation 0, release volume 0, both sides; also clears FLAGS bit 1 |
| `$E0 u\|$80 v` | **on any track**: unit = u & `$7F`, NRx2 = swap(v) at once, retrigger pending (the noise voice; used on SfxN and twice on Sfx1) |
| `$E8 xy` | gate x, env y, **release volume 0** |
| `$EA xy` | 0 duty (CH3: wave), 1/2/3 pan both / high nibble / low nibble (**no attenuation**), 4/5 autopan, 6 no-op, 7/8 transpose, 9 release volume, A clear (as Batman); `$B–$F` run past `ExtTable` into the code |
| `$EC x` | **start a fade**: `wFadeRate` = x |

Unchanged from Batman: `$E1–$E6`, `$E7`, `$E9`, `$EB n xy` / `$EB n|$80`, `$ED`, `$EE`, `$EF`, `$F0–$F7`, `$F8 x` volume, `$F9 n addr`, `$FA`, `$FB`/`$FC`, `$FD`, `$FE`, `$FF`, the noise bytes `$C0` and `$D0–$DF`. The note-on is Batman's without the volume ramp, and with **the detune skipped when its low byte is 0** (as Tiny Toon 2). The release is Tiny Toon 2's (the CH3 release volume is written on every tick after the release).

### 3.1 Tables (bank 14)

| Addr | Name | Content |
|---|---|---|
| `$4000` | `SoundTable` | ids `$01–$18` (the code adds from `$3FFE`); headers `$4030–$40E3` (one unreferenced, `$408A`) |
| `$40E4` | `WaveTable` | 15 waves at `$4102` (from `$40E2`) |
| `$41F2` | `PeriodTable` | 85 periods (from `$41D8`) |
| `$429C` | `VibratoTable` | 38 (from `$429A`) |
| `$447C` | `Vibrato2Table` | 32 semitone tables (from `$447A`) |
| `$4559` | drum hits | streams to `$4653` |
| `$4A5D` | `CommandTable` | `$E7–$FF` (from `$4A4F`) |
| `$4AFC` | `OctaveCodes` | `$18 $30 $48 $60 $78 $90` |
| `$4B38` | `ExtTable` | `$EA x0–xA` |

Bank 15: `SoundTable15` `$4000` (ids `$A1–$FF`, the code adds from `$3FFE`), headers `$40BE–$439B`, streams.

---

## 4. Sounds

Lengths in updates (59.7 Hz; music minus tempo skips).

| Ids | Bank | Prio | Tracks | Notes |
|---|---|---|---|---|
| `$01–$0B` | 14 | `$20` | SfxN (`$07–$09` + Sfx2) | drum hits, 2–47 ticks |
| `$0C–$0E`, `$12` | 14 | `$40` | Ch1–Ch3 + Drm | short tunes that end (≈ 250–300 ticks) |
| `$0F` | 14 | – | – | delayed `$10` (its header is `$10`'s, never started) |
| `$10`, `$11`, `$13–$18` | 14 | `$40` | Ch1–Ch3 + Drm | songs; `$13–$17` fade out on their own, `$15` then ends |
| `$A1` | 15 | `$40` | SfxN + Ch1–Ch3 + Drm | a song that ends (with a fade) |
| `$A2` | 15 | `$FF` | the three SFX tracks, empty | stops the SFX |
| `$A3–$E7` | 15 | `$70–$A4` | Sfx1/Sfx2/SfxN | SFX, up to 174 ticks; `$A7`, `$A9`, `$C1–$C4` also stop the music |
| `$E8–$FF` | 15 | `$40` | Ch1–Ch3 + Drm | songs; `$F6` and `$FA` are empty (stop the music), `$FB–$FF` end (`$FF` with a fade), `$FE` with SfxN |

The intro/loop lengths per track: `python tools/kdata9.py rf -v`.

---

## 5. Quirks and bugs

1. **Drum rests write the joypad register** (`$FF00` = 8, then `$80`), as Tiny Toon 2 (15 drum rests in the data); Batman had fixed it.
2. **Any request resets NR50**, even one refused by priority or by `wSndLock15`; during a fade this restarts the volume ramp, and a finished fade leaves NR50 at `$11` until then.
3. **A fade stops without its stop steps** when music Ch2 isn't playing at a step.
4. **`$E0 u|$80` is decided by the data, not by the track**: on a tone track it writes NRx2 at once and leaves duty, gate and envelope alone (Sfx1 of `$D8` and `$E6`).
5. **`$EA Bx–Fx` run past `ExtTable`** into the code (not in the data).
6. **`TRK_MUTE` is dead**: `TrackTick` tests bit 7 of `$E0` before every read, but nothing sets it (it stayed 0 in every verification run).
7. **The unit isn't set at a track start**, and FLAGS3 survives a drum hit's start (no data depends on either).
8. **Pitch 13 sets PANFLAGS bit 5**, which nothing reads.
9. **An unchanged volume isn't retriggered** (`WriteVolume` compares with the read-back).
10. **Unused:** field `$A9`, `$C0EC`, FLAGS bit 1, the `$0F` header, an unreferenced header (`$408A`) and vibrato table (`$435D`), orphan streams decoded in the asm (bank 14: SfxN `$45D7`, eight music streams `$568F–$59C5`, subroutines `$62B7` and `$7603`; bank 15: subroutine `$4FEA`, SfxN `$7628`, Sfx1 `$7907`), 11 unreachable bytes after ends.

---

## 6. Verification

- **Byte-exact rebuild** of the ranges above.
- **Rate:** one update per VBlank (6000 updates in 6000 frames in PyBoy).
- **Streams vs emulator** (`verify/vstream9.py`): every id of both banks alone for 4000 updates (67 s), the game's own requests dropped; the stream address and length of every note, rest and noise byte the driver reads (hooked at its TRK_LEN stores) must equal the decoder's (`tools/kdata9.py`), in order, each lasting its length plus the tempo skips, and the tracks the decoder ends must end. **119 ids, 93,118 reads, 0 mismatches**, `TRK_MUTE` never set (`verify/run_stream_rf.log`).
- **Delayed request:** `$0F` at update 30 starts `$10` at update 77.
- **Not verified:** the register writes (no update-by-update model this time), the fade and the `wSndMute`/`wSndLock15` paths were only read; nothing was checked on hardware.

## Files (in `GBAudioLab\Kon`)

- `RF_SoundDriver.asm`: labelled, commented RGBDS source, byte-exact
- `tools/kdata9.py`, `tools/cfg_rf.py`, shared `tools/gen_asm3.py`, `tools/align.py`, `tools/gaps9.py`, `verify/vstream9.py`, `verify/run_stream_rf.sh`, log

Regenerate: `python tools/gen_asm3.py rf RF_SoundDriver.asm`.
