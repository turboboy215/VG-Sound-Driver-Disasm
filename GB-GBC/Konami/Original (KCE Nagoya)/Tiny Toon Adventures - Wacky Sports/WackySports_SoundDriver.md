# Tiny Toon Adventures: Wacky Sports (GB): sound driver

ROM: `Tiny Toon Adventures - Wacky Sports (E) [!].gb` (MBC1, 128 KB, internal title `TINY TOON WACKY`). Konami, 1994 (Wacky Sports Challenge in the US).

Part of the Konami family, see `Konami_SoundEngine_Family.md`. This is **Batman's driver** (`Batman_SoundDriver.md`, the Tiny Toon 2 line of the fourth generation): about 1,500 of its 1,750 instructions line up with Batman's (1,310 with Tiny Toon 2's). The track code, track page (`$C180 + n×$100`, fields `$80–$BE`), descriptors, packed two-notes-per-byte SFX, noise volume bytes, semitone vibrato, `$F8` volume, `$EA Ax` field clear and flow commands are Batman's; most `jp` are shortened to `jr`. What changes:

- **everything is back in bank 7** (as in Tiny Toon 2): the update, pause, tempo and fade move from ROM0 back into the bank, and the driver runs on **VBlank** again (Batman: a 64 Hz timer); ROM0 keeps a VBlank check, `PlaySoundFar` and `SndUpdateFar`;
- **the volume ramp, the key transpose and the tempo step are gone**: `$EA` has 11 entries (`0`–`A`); `$EA Bx`–`$EA Fx` would jump through the code after the table;
- **`$EC x` (and `$EA 6x`, with x = `$6x`) set NR50 and a new `wMasterVol`**, and NR51 = `$DD` for `$66`, else `$FF`; the fade restores NR50 from `wMasterVol`;
- **a new fade**, started by **request `$07`** (`PlaySound` never plays header `$07`): NR50 steps down by `$11`, then Drm, Ch1, Ch2 and Ch3 stop one per step and NR50 comes back (§2.3); Batman's CH4 muting and its `$12` cut are gone;
- the request id is passed in `wReqId` (`PlaySoundFar` stores it before the call);
- `SndInit` also gives the drum track its register addresses (Batman left them 0) and no longer writes NR50–NR52;
- **the sound table doubles as the drum map**: a drum note's high nibble is a sound id (the drum headers are ids `$01–$06`).

| | |
|---|---|
| API | ROM0 `$01D0` `PlaySoundFar` (A = id; 0 = stop all, 7 = fade) → bank 7 `$5098` `PlaySound` (id in `wReqId` `$C1C4`); bank 7 `$4A62` `SndInit` (from the boot code) |
| Game inputs | `wPauseFlag` `$C011` (any value; the driver acts on its changes) |
| Tick | **VBlank**: `$008C` → (unless `wSndBusy` `$C004` bit 0 or 1 is set) `SndUpdateFar` `$0A09` → bank 7 `SndUpdate` `$4000` |
| Driver code | ROM0 `$008C–$009E`, `$01D0–$01EF`, `$0A09–$0A17`; bank 7 `$4000–$4A93` (2.6 KB, jump tables at `$4539` and `$4623`) and `$5098–$5181` |
| Data | bank 7 `$4A94–$5097` (tables, headers, drum hits) and `$5182–$7E14` (streams); `$7E15–$7FFF` is `$FF` |
| RAM | seven tracks at `$C180 + n×$100` (`$80–$BE`), globals `$C1BF–$C1CC` |
| Channels | Sfx1 (CH1), Sfx2 (CH3), SfxN (CH4), Ch1, Ch2, Ch3, Drm |
| Counts | 113 ids `$01–$71`: 6 drum hits, the fade request `$07`, SFX `$08–$5D`, 20 songs `$5E–$71`; 15 vibrato tables, 8 semitone tables, 15 wave pointers (10 waves), 85 periods |

`WS_SoundDriver.asm` rebuilds **byte-exact** with RGBDS over ROM0 `$008C–$009E`, `$01D0–$01EF`, `$0A09–$0A17` and bank 7 `$4000–$7E14`, and assembles cleanly with `-Wall`:

```
rgbasm -Wall -o ws.o WS_SoundDriver.asm
rgblink -o ws.gb ws.o
```

---

## 1. Structure

### 1.1 Tracks and fields

Batman's: descriptors Sfx1 `$40`, Sfx2 `$52`, SfxN `$63`, Ch1 `$00`, Ch2 `$11`, Ch3 `$22`, Drm `$34` (low nibble = channel), per-track register addresses `TRK_REG_NRX1–4` (`$B7–$BA`), volumes compared with the register read-back. The fields are Batman's up to `$BE`; `TRK_PANATTEN`, `TRK_RAMPSTEP` and `TRK_RAMPCNT` are gone. `TRK_FLAGS3` bit 5 is set by `OCTAVE 6` and cleared by the other octaves; nothing reads it.

### 1.2 Globals

`$C1BF` `wTrackDesc`, `$C1C0` (cleared by a song start, never read), `$C1C1` `wTempo`, `$C1C2` `wTempoAcc`, `$C1C3` `wReqPrio`, `$C1C4` `wReqId`, `$C1C5` `wPauseLast`, `$C1C6` `wFadeRate`, `$C1C7` `wFadeTimer`, `$C1C8` `wFadeStep`, `$C1C9` `wWaveId`, `$C1CA` (cleared by every request, never read), `$C1CC` **`wMasterVol`** (NR50, `$77` after `SndInit`). The game's `$C002` (mapped ROM bank), `$C004` (`wSndBusy`), `$C011` (pause).

---

## 2. Timing

### 2.1 Update

Once per VBlank, in bank 7: on a change of `wPauseFlag` pause or unpause (Batman's `PauseEdge`/`Unpause`, unchanged). Not paused: `FadeTick`, `TempoTick` (only while `wTempo` is not 0), Ch1, Ch2, Ch3, Drm; then SfxN, Sfx2, Sfx1 (also while paused). `RunTrack` sets `wTrackDesc` and runs a track whose id is set.

### 2.2 Tempo

`wTempoAcc += wTempo`; the carry sets the skip flag (`TRK_FLAGS` bit 4) of the four music tracks, which skip the update. `$EE x` sets `wTempo` and clears the accumulator. Tempos in the data: `$05`, `$0A`, `$0D`, `$0F`, `$10`, `$13`, `$16`, `$20`, `$25`, `$2A`, `$3A`.

### 2.3 Fade

Request `$07` sets `wFadeRate` = 8. While it is set (and not `$FF`), every `wFadeRate` updates NR50 goes down by `$11`; when it would reach 0 it stays at `$11` and `wFadeStep` goes up by `$10` instead, once per interval: `$10` stops Drm, `$20` Ch1 (CH1 muted unless Sfx1 plays), `$30` Ch2 (CH2 muted), `$40` Ch3 (NR30/NR32 = 0 unless Sfx2 plays) and ends the fade. With `wFadeRate` 0, `FadeTick` writes NR50 = `wMasterVol` on every update – which is how the volume comes back after a fade. A new song clears the fade.

### 2.4 Requests

`PlaySound` (id in `wReqId`): `$07` starts the fade, 0 is `StopAll`, any other id reads its header from `SoundTable` (`$4A92` + 2 × id): priority, mask, pointers. If any SFX track of the mask holds a higher priority the whole mask is cleared and nothing starts; otherwise the SFX tracks start without further tests (SfxN also sets the CH4 bits of NR51). Music needs the Ch1 bit and a priority ≥ Ch1's; it resets tempo and fade, NR10 = 8, and starts Ch1–Ch3/Drm. Batman's request filters are gone.

### 2.5 Pause

As Batman: pausing stops SfxN and mutes CH4 and CH2; unpausing stops Sfx1 and Sfx2, mutes CH1, NR32 = 0, gives CH1 and CH3 back to the music (NR51 bits and period, no trigger) and marks Ch1–Ch3 for a retrigger of a long note.

---

## 3. Data format

Batman's (`kdata9.py` `bm`), with this `$EA` table:

| `$EA` | | `$EA` | |
|---|---|---|---|
| `0y` | duty / CH3 wave | `6y` | NR50 = `$6y` (as `$EC`) |
| `1y`, `2y`, `3y` | pan both / left / right (y ignored) | `7y`, `8y` | transpose up / down |
| `4y`, `5y` | autopan / autopan both | `9y` | release volume |
| | | `Ay` | clear fields (bit 3 vibrato, 2 duty step, 1 detune, 0 attenuation) |

`$E0 u v g` voices (SfxN: `$E0 u v`, NR42 = swap(v) at the next noise note), `$E1–$E6` octave, `$E7` unit, `$E8` gate/env, `$E9` NR10, `$EB` vibrato (`n xy`, `n | $80` semitone table, 0 off), `$EC` NR50, `$ED` duty step, `$EE` tempo, `$EF` detune, `$F0–$F7` attenuation, `$F8` volume, `$F9 n addr` counted jump, `$FA addr` jump, paired `$FB`/`$FC` loops, `$FD addr` call / `$FD` return, `$FE` mark/jump, `$FF` end.

In the data: 2,806 music notes, 369 packed SFX note bytes (and 328 `$F` escapes to a command), 497 drum notes, 495 noise bytes, 294 voices, 1,096 octaves, 231 release volumes, 76 vibratos and 32 semitone vibratos, 92 detunes, 45 `$F8` volumes, 51 NR10 writes, 117 + 5 loops, 99 calls, 11 jumps, 2 counted jumps, one `$EC` (sound `$0A`: NR50 = `$77`). **Not used:** `$EA 6x`, `$EA Ax`.

### 3.1 Tables (bank 7)

| Address | Contents |
|---|---|
| `$4A94` | `SoundTable`, ids `$01–$71` (from `$4A92` + 2 × id, the last two code bytes) |
| `$4B76–$4DF5` | headers |
| `$4DF6` | `WaveTable`, 15 pointers (from `$4DF4`, the last header pointer), waves `$4E14–$4EB3` |
| `$4EB4` | `PeriodTable`, 85 periods |
| `$4F5E` | `VibratoTable`, 15 pointers; tables `$4F7C–$502D` |
| `$502E` | `Vibrato2Table`, 8 semitone tables (`$503E–$505C`) |
| `$505D–$5097` | the six drum-hit streams (SfxN) |

---

## 4. Sounds

Drum hits `$01–$06` (SfxN; drum notes use hi nibbles 1–6). `$07` is the fade request (its header – SfxN on the empty stream at `$5182` – is never read). `$08`–`$0A` are silencers on Sfx1, Sfx2 and SfxN (priorities `$FE`, `$73`, `$FF`; `$0A` also sets NR50 = `$77`). SFX `$0B–$5D`, songs `$5E–$71` (Ch1, Ch2, Ch3, Drm).

---

## 5. Quirks and bugs

1. `$EA Bx`–`$EA Fx` run past the 11-entry `ExtTable` into code (none in the data).
2. While the fade sits at its last steps NR50 stays at `$11`; a request for music in the middle of a fade clears it at once (and NR50 is restored on the next update).
3. `$C1C0`, `$C1CA` and `TRK_FLAGS3` bit 5 are written and never read; `DeadSavePtr` (`$494B`) is unreachable.

---

## 6. Verification

Lighter verification, as for Batman and Raging Fighter: `verify/vstream15.py` (`vstream9.py` with a `ws` configuration) boots the game in PyBoy, drops the game's requests at `PlaySoundFar`, injects the id through `PlaySoundFar` from the VBlank check at update 30, and hooks the two `TRK_LEN` stores (`$4203` notes, packed SFX notes and drum notes; `$44E5` noise bytes): every read's address and length must equal the decoder's timeline (`tools/kdata15.py`), with the tempo skips in between, and a stream the decoder ends must end. **Every id alone (except the fade request `$07`) for 6,500 updates: 112 ids, 53,497 reads, 0 mismatches** (`verify/run_stream_ws.sh` → `run_stream_ws.log`).

---

## Files (in `GBAudioLab\Kon`)

- `WS_SoundDriver.asm` – the disassembly (driver + all sound data), byte-exact.
- `tools/kdata15.py` – decoder (`ws`; registers a profile in `kdata9.py` and overrides its `$EA` table); `tools/cfg_ws.py` – `gen_asm3.py` config; `tools/gaps14.py` – unowned data bytes.
- `verify/vstream15.py`, `verify/run_stream_ws.sh`, `verify/run_stream_ws.log`.
