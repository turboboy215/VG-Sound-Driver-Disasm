# Blades of Steel (GB): sound driver

ROM: `Blades of Steel (E) [!].gb` (DMG, MBC1, 128 KB, internal title `BLADES OF STEEL`). Konami, 1991.

Part of the Konami family, see `Konami_SoundEngine_Family.md`. This is **Belmont's Revenge's driver** (same entry points, RAM layout, VBlank tick, request groups with the stale refusal flag, duty step) with four changes: a new **glide** command (`EA 5n`) with a look-ahead parser for the next note, **Nemesis-style `PAN`/autopan** again (the raw per-track NR51 byte is gone), a **16-tick fade step with a stop path**, and a vibrato negate flag that is **no longer sticky**. The glide is never used by the data.

| | |
|---|---|
| API | bank 7 `$4018` `SndInit`, `$40CF` `PlaySound` (A = id, 0 = stop all; keeps DE), `$40D5` `StopSound`, `$40DD` `StartFade` (A = sound to start afterwards, < 5 = stop), `$4251` `SndPause`, `$425C` `SndUnpause`. ROM0 `$0F1F` `PlaySoundFar` (also `jp` at `$00B8`), `$0F68` `StartFadeFar` (`$00C7`), `$0F46` `SndPauseFar`, `$0F57` `SndUnpauseFar` |
| Game inputs | `wPauseFlags` `$D81D` |
| Tick | **VBlank**, 59.73 Hz: every branch of the VBlank handler calls `SndUpdateFar` (`$0F01`) once → bank 7 `$42F7` `SndUpdate` (PyBoy: one update per frame) |
| Music rate | 59.73 Hz × (1 − tempo/256) |
| Driver code | bank 7 `$4000–$4024`, `$40CF–$4B41` (2.7 KB) + ROM0 glue `$0F01–$0F80` |
| Tables + data | bank 7 `$4025–$40CE`, `$4B42–$6C2E` (8.2 KB). `$6C2F–$7FFE` is graphics (copied to VRAM by ROM0 `$0F81`/`$0FA1`), `$7FFF` the bank number |
| RAM | seven tracks at `$C080 + n×$100` (`$80–$B5`), globals `$C0B9–$C0CB`, shadows `$C1B6–$C1C9`; lock `$D805` |
| Channels | Sfx1 (CH1), Sfx2 (CH2), SfxN (CH4), Ch1, Ch2, Ch3, Drm (drums = sound ids `$01–$05` through an 11-entry map) |
| Counts | 51 sound ids (`$01–$33`): 5 drum hits, SFX/jingles `$06–$26`, music `$27–$32`, `$33` = stop music |

`BOS_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over ROM0 `$0F01–$0F80` and bank 7 `$4000–$6C2E`. It assembles cleanly with `-Wall`.

```
rgbasm -Wall -o bos.o BOS_SoundDriver.asm
rgblink -o bos.gb bos.o
python tools/cmp_ranges.py bos.gb "Blades of Steel (E) [!].gb" 0:0F01-0F80 7:4000-6C2E
```

---

## 1. Structure

Same as Belmont's Revenge: tracks in place at `H = $C0 + n`, `L = $80–$B5`, `$80–$A6` unchanged (including the duty step fields `$A4–$A6`). `TRK_PAN` (`$B5`) is gone; `$A7–$B4` now hold the glide state:

| L | Name | Use |
|---|---|---|
| `$A7` | TRK_GLLEN | glide length in units (`EA 5n`) |
| `$A8` | TRK_GLOCTAVE | octave seen by the look-ahead (set by `$E1–$E6` too) |
| `$A9` | TRK_GLTARGET | period of the next note |
| `$AB` | TRK_GLPERIOD | current glide period (= the note's period at note start) |
| `$AD` | TRK_GLSTART | glide starts when this many ticks of the note are left (len − n × unit) |
| `$AE` | TRK_GLDIR | bit 0 = downwards |
| `$AF` | TRK_GLDELTA | distance to the target |
| `$B1` / `$B2` / `$B3` | TRK_GLTIMER / TRK_GLRELOAD / TRK_GLSTEP | step timing and size |
| `$B4` | TRK_GLLOOPCNT | the look-ahead's own `$FE` loop counter |

Track roles, register bases and the music/SFX blocking (`IsBlocked`: Ch1 while Sfx1 plays, Ch2 while Sfx2 plays) are unchanged. The globals are at the same addresses as in Belmont's Revenge (`wTrackIdx` `$C0B9` … `wReqRefused` `$C0CB`).

---

## 2. Timing

### 2.1 Glue (ROM0)

`SndUpdateFar` (`$0F01`) and `PlaySoundFar` (`$0F1F`) share `wSndLock` (`$D805`): the update is skipped while the main thread is inside `PlaySoundFar`, and `PlaySoundFar` drops a request while the lock is held. `PlaySoundFar` keeps HL and BC and only sets the lock after bank 7 is mapped. `StartFadeFar` doesn't use the lock. All wrappers restore the caller's bank from `$7FFF`.

### 2.2 Update order and tempo

As in Belmont's Revenge: `FadeTick`, `TempoTick`, tracks 0–2 always, tracks 3–6 unless the tempo accumulator carried, then `wQueuedSnd`. While `wPauseFlags` bit 0 is set only track 1 runs, and only for `$06`. Tempos in the data: `$00`, `$20`, `$40`, `$50`, `$60`, `$90`.

### 2.3 Fade-out

`StartFade` sets `wFadeReq` = A | `$80`. `wFadeLevel` goes up every **16** ticks (Belmont's Revenge: 32). At level 5 (80 ticks, 1.3 s) bits 0–6 are queued; **a target below 5 calls `StopAll`** instead (a stop path again, as in Nemesis, where the limit was 7), so `StartFade` with 0 now silences everything.

### 2.4 Requests and pause

Unchanged from Belmont's Revenge, including the **stale `wReqRefused` flag** that makes the next request abort after a refused last track. The game's pause code calls `SndPauseFar`, sets `wPauseFlags` = 1 and plays `$06`; unpause clears it and calls `SndUnpauseFar`, which now refuses to run when any bit of `wPauseFlags | wMusicHold` is set (Belmont's Revenge tested bit 0).

---

## 3. Data format

The command language is Belmont's Revenge's with these changes:

| Byte | Belmont's Revenge | Blades of Steel |
|---|---|---|
| `EA 5n` | (jumps into garbage) | `GLIDE n`: TF_GLIDE (flags bit 5) on, TRK_GLLEN = n; `GLIDE 0` off. Unused by the data |
| `$EF x` | TRK_PAN = x (raw bits) | this track's NR51 bits = **swap(x)**, through a keep-mask table (`$4650`: `EE DD 77 EE DD BB FF`), as in Nemesis. Dropped on music Ch1 while Sfx1 plays (not on Ch2). No extra byte skipped on the drum track |
| autopan | swap TRK_PAN's nibbles | swap the halves of this track's NR51 bits, on every track and without the blocking check (Nemesis) |
| vibrato step | negate flag sticky | negate flag set **or cleared** by each step |
| `EA 4n` | overwrites the flags | the same, so it also turns the glide off |

Everything else (notes, `$E0` voices, octaves, `$E7–$E9`, `EA 0n–3n`, `$ED` duty step, `$EE`, `$F0–$FA`, flow, vibrato tables, rests = NRx2 0, release with env 0 retriggers) is unchanged.

### 3.1 Glide

At each tone or CH3 note with TF_GLIDE set, `GlideSetup` reads ahead from the next byte to the next note, following `$FB`/`$FC`/`$FD`/`$FE` (it writes TRK_SEGNO and TRK_RET on the way and counts loops in its own TRK_GLLOOPCNT), skipping other commands and noting octave changes. An `$FF` ahead turns TF_GLIDE off. With the target period:

- TRK_GLSTART = note length − n × unit; 0 = no glide for this note;
- same period: timer `$FF`, step 0;
- distance d < start: step 1 every ⌊start/d⌋ + 1 ticks; d = start: step 1 every tick; d > start (or ≥ 256): step ⌊d/start⌋ + 1 every tick (8-bit).

`GlideTick` then moves TRK_GLPERIOD every TRK_GLRELOAD ticks once the note has TRK_GLSTART ticks or fewer left, and writes it to NRx3/NRx4. It doesn't stop at the target (the step rounds up, so it overshoots), and **vibrato doesn't run while TF_GLIDE is set**.

### 3.2 Tables

| Addr | Name | Content |
|---|---|---|
| `$4025` | `PeriodTable` | 85 periods (as Belmont's Revenge) |
| `$4650` | `PanKeepMask` | NR51 bits kept by `PAN`/autopan, per track |
| `$4B42` | `RegBaseTable` | `00 05 0F 00 05 0A 0F` |
| `$4B49` | `SoundTable` | 51 pointers (the code loads `SoundTable − 2`) |
| `$4BAF–$4CE2`, `$5234–$5247` | headers | |
| `$513B` | `WaveTable` | 15 pointers to 13 waves (`$5159–$5228`; 9–11 share) |
| `$5229` | `DrumMap` | `01 02 01 03 03 03 03 04 05 05 05` |
| `$5267` | `VibratoTable` | 15 pointers → `$5285–$5326` |
| `$4CE3–$6C2E` | streams | |

---

## 4. Sounds

Lengths in ticks (59.73 Hz for SFX tracks, the §2.2 rate for music). "a/b" = total / loop start.

| Id | Prio | Tracks | Length |
|---|---|---|---|
| `$01`–`$05` | `$01` | SfxN | 1, 1, 0, 3, 2 (drum hits; `$03` is empty and only cuts the noise SFX) |
| `$06` | `$80` | Sfx2 | 48 (pause jingle) |
| `$07`–`$26` | `$30`–`$42` | Sfx1, SfxN, or both; a few with Sfx2 | 0–242 |
| `$0A` | `$41` | Sfx1 (empty) + SfxN | 424 |
| `$0B` | `$41` | Sfx1 + Sfx2 (empty) + SfxN | SfxN loops (200/154) |
| `$0C` / `$0D` | `$42` | Sfx1 + Sfx2 / SfxN | 215 / 194 / 242 |
| `$13` | `$33` | Ch1–Ch3 | 320 / 328 / 316 |
| `$14` | `$41` | `$0C` + `$0D` + `$13` in one header (six tracks) | as those |
| `$15` | `$33` | Ch1–Ch3 + Drm (empty) | 272 |
| `$27`, `$29`, `$31`, `$32` | `$30` | Ch1–Ch3 + Drm | 256, 222, ≈3740, 768: end |
| `$28`, `$2A`–`$30` | `$30` | Ch1–Ch3 + Drm | looping, periods 384–5040 ticks (some drum tracks end) |
| `$33` | `$40` | Ch1–Ch3 + Drm, all empty | 0 (stops the music) |

The full per-id list is in the asm, and the intro/loop lengths per track can be printed with `tools/kdata.py`.

---

## 5. Quirks and bugs

1. **The tail of `TrackTick` runs more than once with TF_GLIDE.** `GlideTick` (when its timer is still counting) and `GlideOrVibrato` jump into the tail (CH3 decay / release retrigger) with their return address still on the stack, so the tail runs twice per tick, or three times while the glide timer counts: CH3 decays two or three times as fast, and the release writes and retriggers more than once. Latent, since nothing uses the glide; checked with a patched ROM (§6).
2. **The look-ahead writes TRK_SEGNO and TRK_RET.** For a glided note followed by `SND_RET` and then a `SND_CALL`, or by a `$FE` and then a new `$FB`, the real reader would later return or loop to the wrong place. Also latent.
3. **Glide overshoots** and keeps going until the note ends (§3.1).
4. **`EA 4n` clears the glide** (and the duty step and force flag), as it overwrites the flags byte.
5. **Stale refusal flag** and **aborted requests skip the NR51 write** (as Belmont's Revenge).
6. **NR51/NR10 are set even when the priority test fails** (as before).
7. **A note below the period table**: Sfx1 of `$24` plays `OCTAVE 1 G` under `TRANSPOSE_DOWN 15`; the index wraps to 248 and the period comes from `StopAll`'s code at `$4215` (`$C580`), so NR14 gets `$C5` with the length-enable bit set. It's a one-tick note.
8. **`PAN` isn't blocked on music Ch2** (only Ch1), and autopan is never blocked.
9. **CH3 decay counts the attenuation twice**, **`StopAll` sets wNR51 = `$FF` without writing NR51**, **one return slot**, **persistent fields above `$8C`** (as before).
10. **Dead code/data:** the unreachable Ch2 tempo check in `SndUpdate` (`$432C–$433C`), `wMusicHold`, `wSweepVal`, the `push af`/`pop af` pair and triple `wReqId` store, the glide itself, an extra `$FF` after jumps or ends at `$53EB`, `$5487`, `$556A`, `$5668`, `$56BD`, `$5CB6`, `$5EC3`, `$5F64`, `$5F8A`, `$63B2`, `$65BB`, `$67EB`, `$6934`, `$6962`, `$6A0C`, `$6A7E`, `$6AF1`, `$6C19`, an orphan noise stream at `$4D0C` and three orphan music subroutines at `$6270`, `$637E`, `$63FB` (decoded in the asm).

---

## 6. Verification

- **Byte-exact rebuild** of both ranges.
- **Rate:** one update per VBlank (7044 updates in 7140 frames, the difference being boot).
- **Model vs emulator** (`verify/vmodel2.py bos`, `tools/kmodel2.py` BoS branch: all seven tracks byte for byte including the glide fields, shadows, every global, NR51, wave RAM, triggers per tick; the game's own requests dropped):
  - each of the 51 ids alone for 7000 ticks: **0 mismatches** (`verify/run_all_bos.sh`);
  - two mixed 9000-tick scenarios (`verify/run_combo_bos.sh`): songs with SFX on all three SFX tracks, blocking and restores, `PAN`/autopan while blocked, a refusal chain (`$14` then `$13` refused at Ch3, the next request aborted), pause with `$06`, a fade to a song, a fade to `$02` (stop) and to 0: **0 mismatches**;
  - **glide**: a copy of the ROM with every `VIBRATO n` changed to `GLIDE n` (and some `VIBRATO 0` to `GLIDE 0`), 18 ids alone and one mixed scenario: **0 mismatches**, including the repeated tail (§5.1).
- **Not verified:** `SndPause`/`SndUnpause` and the game's own fade calls were only read. Nothing was checked on hardware or against audio output.

## Files (in `GBAudioLab\Kon`)

- `BOS_SoundDriver.asm`: labelled, commented RGBDS source, byte-exact
- `tools/cfg_bos.py`, shared `tools/kdata.py` (profile `bos`, orphan streams) and `tools/kmodel2.py`, `verify/vmodel2.py`, `verify/run_all_bos.sh`, `verify/run_combo_bos.sh`, logs

Regenerate: `python tools/gen_asm.py bos BOS_SoundDriver.asm`.
