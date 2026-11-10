# Hyper Dunk (GB): sound driver

ROM: `Hyper Dunk (U).gb` (DMG, MBC1, 128 KB, internal title `HYPER DUNK`). Konami. *Hyper Dunk* is the European name (1994) of *Double Dribble: 5 on 5* (US, December 1991; *Konami Basketball* in Japan, 1992); the driver could be the 1991 code or a later revision, and nothing in it says which.

Part of the Konami family, see `Konami_SoundEngine_Family.md`. This driver, and the one in *The Spirit of F-1*, sit **between the second generation and Nemesis II**. The framework is the second generation's: one bank (7) holds the driver, the tables and all the sounds; it runs once per VBlank; the update loop, `TempoTick`, the register shadows, `IsBlocked`, the raw per-track `PAN` byte and the request starts are Belmont's Revenge's. The **track code, field layout and command language are Nemesis II's**: the paired `$FB`/`$FC` loop markers, `$FD` call/return, `$FE` mark/jump, `$EB n xy` vibrato with a delay and depth, one-byte vibrato steps and raw register-frame streams. Instruction alignment: about 900 of its 1,420 instructions line up with Nemesis II's bank-13 code, about 780 with Belmont's Revenge's.

On top of that, Hyper Dunk has:

- **volume envelope tables** (`$EC n`): per-note volume steps in the vibrato-table format, with a retrigger at each step;
- Belmont's Revenge's **`$ED` duty step** and an **`$EA 2n` vibrato** (no delay) next to `$EB` (both unused by the data);
- **no request groups**: every track of a request gets its own priority test and nothing aborts (`wReqRefused` is set but never read);
- a **game-controlled tone** on Sfx1 for ids `$11`/`$12`: its period comes from a 144-entry table indexed by a game variable, on every update;
- a few id rules in `PlaySound` (ids `≥ $31` ignored, `$21` stops everything first, `$14` not restarted).

| | |
|---|---|
| API | ROM0 `$02B0` `PlaySoundFar` (A = id, 0 = stop all; 42 call sites) → bank 7 `$4AD2` `PlaySound`; `$4014` `SndInit` (boot), `$4C9F` `SndPause` / `$4CAA` `SndUnpause` (the game's pause code at `$04C5`) |
| Game inputs | `wPauseFlags` `$C014` (bit 0 toggled by the game; the driver tests the byte), `wVarToneVar` `$C122` (written in 3 places) |
| Tick | **VBlank**: the handler (`$0068`, normal path) calls `SndUpdateFar` `$0099` → bank 7 `$4098` `SndUpdate`, skipped while `wSndLock` `$C00D` bit 0 or 1 is set (bit 1 = a `PlaySoundFar` in progress). One update per frame in PyBoy |
| Driver code | ROM0 `$0028` (rst), `$0099–$00B5`, `$02B0–$02DA`, `$02F4–$02F8`; bank 7 `$4000–$4D0F` (3.3 KB, inline jump tables at `$4202`, `$434F`, `$4398`, `$44D1`, `$49E4`) |
| Data | bank 7 `$4D10–$6CD1`; `$6CD2–$7FFF` is `$FF` |
| RAM | seven tracks at `$C080 + n×$100` (`$80–$BD`), globals `$C0C1–$C0D9`, shadows `$C1BE–$C1D1` |
| Channels | Sfx1 (CH1), Sfx2 (CH2), SfxN (CH4), Ch1, Ch2, Ch3, Drm (drums = sound ids through a 15-entry map) |
| Counts | 48 ids `$01–$30`: 15 drum hits, pause jingle `$10`, SFX `$11–$26`, 10 songs `$27–$30` |

`HD_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over ROM0 `$0028–$002C`, `$0099–$00B5`, `$02B0–$02DA`, `$02F4–$02F8` and all of bank 7. It assembles cleanly with `-Wall`.

```
rgbasm -Wall -o hd.o HD_SoundDriver.asm
rgblink -o hd.gb hd.o
python tools/cmp_ranges.py hd.gb "Hyper Dunk (U).gb" 0:0028-002C 0:0099-00B5 0:02B0-02DA 0:02F4-02F8 7:4000-7FFF
```

---

## 1. Structure

### 1.1 Tracks

Track n's page is `H = $C0 + n`, fields at `L = $80–$BD`. As in Belmont's Revenge the register base comes from `RegBaseTable` (`00 05 0F 00 05 0A 0F`), Ch1 is blocked while Sfx1 plays and Ch2 while Sfx2 plays (`IsBlocked`), and every register write goes through a shadow (`WriteReg`, skipped when unchanged unless `TRK_FLAGS` bit 6 is set).

| # | Page | Name | Channel |
|---|---|---|---|
| 0 | `$C080` | Sfx1 | CH1 |
| 1 | `$C180` | Sfx2 | CH2 |
| 2 | `$C280` | SfxN | CH4 |
| 3 | `$C380` | Ch1 | CH1 |
| 4 | `$C480` | Ch2 | CH2 |
| 5 | `$C580` | Ch3 | CH3 |
| 6 | `$C680` | Drm | – (plays sound ids) |

### 1.2 Track fields

`$80–$8E` are Nemesis II's; from `TRK_FLOW` on everything is one byte higher (an envelope loop counter is inserted at `$8F`), and the envelope and duty-step fields follow the vibrato:

| L | Name | Use |
|---|---|---|
| `$80` / `$81` / `$82` / `$84` | ID, PRIO, PTR, LEN | |
| `$85` | FLAGS | 0 released, 1 autopan, 3 vibrato negate, 4 duty step, 6 force, 7 rest |
| `$86` | FLAGS2 | 0 envelope step pending, 1 envelope held, 4+5 raw stream, 7 vibrato delay running |
| `$87` / `$88` | LOOPCNT / LOOP2CNT | |
| `$89` / `$8A` / `$8B` | VIB, TRANSP, ATTEN | |
| `$8C` / `$8E` / `$8F` | VIBOFS (word), VIBLOOPCNT, ENVLOOPCNT | |
| `$90` | FLOW | 0/1 loop open, 2 in a call, 3 mark set |
| `$91` / `$92` / `$93` | UNIT, OCTAVE, PERIOD (word) | |
| `$95` / `$96` | raw period | |
| `$97`–`$9B` | VOL, DUTY, ENV, GATE, RELTICK | |
| `$9C` / `$9D` / `$9E` / `$9F` / `$A1` | VIBTIMER, VIBRELOAD, CH3TIMER, CH3RELOAD, LEVEL | |
| `$A2` / `$A4` / `$A6` / `$A8` | LOOPPTR, LOOP2PTR, RET, SEGNO | |
| `$AA` / `$AC` / `$AD` / `$AE` | VIBPTR, VIBIDX, VIBLOOPIDX, VIBDEPTH | |
| `$AF` / `$B0` / `$B1` | vibrato delay: units, reload, counter | |
| `$B2`–`$B9` | ENVNUM, ENVTIMER, ENVRELOAD, ENVVOL, ENVPTR (word), ENVIDX, ENVLOOPIDX | |
| `$BA` / `$BB` / `$BC` | duty step: counter, duty, ticks | |
| `$BD` | PAN | raw NR51 bits (as Belmont's Revenge) |

### 1.3 Globals

`wTrackIdx` `$C0C1`, `wRegBase` `$C0C2`, `wTempo`/`wTempoAcc`/`wTempoSkip` `$C0C3–$C0C5`, `wQueuedSnd` `$C0C6`, `wNR51` `$C0C7`, `wSweepVal` `$C0C8`, `wReqId`/`wReqPrio` `$C0C9/A`, `wRegVal`/`wRegIdx` `$C0CB/C`, `wMusicHold` `$C0CD`, `wFadeLevel` `$C0D2`, `wReqRefused` `$C0D3`, and the variable tone's `wVarToneStart` `$C0D4`, `wVarToneIdx` `$C0D5`, `wVarTonePeriod` `$C0D6`, `wVarTonePtr` `$C0D8`. `wQueuedSnd`, `wMusicHold` and `wFadeLevel` are read but never written (only cleared by `StopAll`/`SndInit`); `wC0D0` is written by an unreferenced routine.

---

## 2. Timing

### 2.1 Update

Once per VBlank (on the handler's normal path) `SndUpdateFar` maps bank 7 and calls `SndUpdate`: `FadeTick` (a bare `ret`), `TempoTick`, then tracks 0–6 in turn. While `wPauseFlags` is non-zero only track 1 runs, and only for id `$10` (the pause jingle). Otherwise the loop stops before track 3 when `wTempoSkip` or `wMusicHold` is set (a second test for track 4 is unreachable). Last, `wQueuedSnd` would be started.

`PlaySoundFar` sets `wSndLock` bit 1, maps bank 7, runs `PlaySound` and then maps **bank 1** (always, whatever the caller had mapped); an update that falls inside it is skipped.

### 2.2 Tempo

As Belmont's Revenge: every update `wTempoAcc += wTempo`; the carry skips all four music tracks for that update. `$EE` sets `wTempo` only. Tempos in the data: `$00`, `$10`, `$1C`, `$20`, `$24`.

### 2.3 Fade-out

None: `FadeTick` is an empty routine, and `NoteVolume` still subtracts `wFadeLevel` (CH3: half of it), which stays 0.

### 2.4 Requests

`PlaySound`, id in A:

| Id | Action |
|---|---|
| `≥ $31` | ignored |
| 0 | `StopAll` |
| `$21` | `StopAll`, then played |
| `$14` | not restarted while Sfx1 plays it |
| `$11`, `$12` | `wVarToneStart` = 1, then played |
| else | header from `SoundTable` |

The header is `priority, mask` and one pointer per mask bit, as before. The tracks start in the order Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm, **each with its own test** (priority ≥ the track's): no request groups, no abort. A started track gets `TRK_PRIO`, `TRK_ID`, `TRK_PTR`, LEN 1, `TRK_FLAGS` = `$40` (force), `$86–$90` = 0, and raw-stream bits when the stream starts with `$E1`; a refused one skips its pointer. Both get `TRK_PAN` = `$FF`. Sfx1 (on a pass) writes NR10 = 8 and its NR51 bits, Ch1 writes NR10 = 8 when Sfx1 is idle, Ch2/Ch3/Sfx2/Drm OR their NR51 bits in without a test, SfxN only on a pass. NR51 is written at the end.

### 2.5 Pause

The game's pause code (`$04C5`) toggles `wPauseFlags` bit 0, calls `SndPause` (NRx2 = 0 on CH1/CH2/CH4, NR32 = 0) and plays `$10`; on unpause it calls `SndUnpause`, which (unless `wPauseFlags` or `wMusicHold` is set) copies the shadows back for every channel with a playing track, without a retrigger.

---

## 3. Data format

| Byte | Meaning |
|---|---|
| `$00–$DF` | note: hi = pitch (0 = rest), lo × unit = length, **lo = 0: (unit & 15) × 16**. SfxN: NR43 = byte, length = unit. Drm: plays `DrumMap[hi − 1]` |
| `$E0` | `VOICE unit, vol\|duty<<4, env\|gate<<4` (SfxN: `unit, vol<<4\|env`, NR42 + trigger at once; Drm: unit only). **Also turns the envelope off** |
| `$E1–$E6` | octave |
| `$E7 x` / `$E8 xy` / `$E9 x` | unit / gate + env / NR10 |
| `$EA xy` | 0 transpose up, 1 transpose down, **2 vibrato table y (no delay; unused)**, 3 duty (CH3: wave), 4 autopan (`TRK_FLAGS` = y, then bit 1 set or cleared; unused) |
| `$EB x yz` | **vibrato** table x (the whole byte), delay y × unit ticks (0 = none), depth z; `$EB 0` off (two bytes) |
| `$EC n` | **volume envelope** n (0 = off; §3.2) |
| `$ED xy` | duty step: notes start with duty y, the voice duty is back after x ticks; `ED 00` off (unused) |
| `$EE x` | tempo |
| `$EF x` | PAN (raw NR51 bits); on the drum track it skips one byte too many (not in the data) |
| `$F0–$FA` | attenuation (SfxN: NR42 at once) |
| `$FB` / `$FC` | loop markers, two levels: the first one met marks, the next one is `FB n` / `FC n` (loop n times) |
| `$FD addr` / `$FD` | call (one return slot) / return |
| `$FE` / `$FE` | the first marks, the next jumps back to the mark, forever |
| `$FF` | end |

The asm uses `LOOP_START`/`LOOP_END n`, `LOOP2_START`/`LOOP2_END n`, `SND_CALL`/`SND_RET`, `SND_SEGNO`/`SND_LOOP` for the flow bytes, as the reader takes them.

Note-on: autopan, length, release tick = length × gate / 16 (gate 15: length − 1), the duty step's first duty, the period from `PeriodTable` with octave and transpose, the vibrato and the envelope restart (`VibratoRead`, `EnvRead`), then NRx2 (the envelope's volume when one runs) and a trigger. Per tick: release flag, the vibrato (after its delay), the envelope, the CH3 decay, and at the release tick NRx2 = env | level with a trigger (no release while an envelope runs).

### 3.1 Raw streams

As Nemesis II: a stream starting with `$E1` is raw. A pass that starts on `$E1` reads a header (`unit, duty, NR10`), `$00` is a rest of one unit, and every other byte starts a two-byte **frame** (`vol<<4 | period>>8`, `period & $FF`: NRx2 without envelope, the period, a trigger; one unit). `$E7` (unit), `$E9`, `$EA`, `$EE`, `$EF` and the flow commands work as usual. Used by the pause jingle `$10`, by Sfx1/Sfx2 of 13 SFX (`$14–$23`) and by both channels of `$26`.

### 3.2 Envelopes and vibrato

Both table kinds use one byte per step with `$FB` (loop point), `$FE n` (repeat n times, `$FF` = forever) and `$FF` (hold):

- **vibrato**: ticks << 4 | negate << 3 | offset 0–7, the offset multiplied by the depth;
- **envelope**: ticks << 4 | volume. At each step the volume is written to NRx2 with a retrigger; `$FF` holds the last volume without further retriggers.

Envelopes are used by Ch1/Ch2 of the songs (18 different tables); the vibrato only through `$EB` (tables 4–7).

### 3.3 The variable tone (`$11`, `$12`)

Their header's Sfx1 pointer is `VarToneTable` (`$5AF0`), not a stream. On every update `TrackTick` sends Sfx1 (or Ch1) playing `$11`/`$12` to `VarToneTick`: LEN = 1; at the start duty 2 and NRx2 = `$40`; the period is `VarToneTable[wVarToneVar]` (the index doubled with `rla`, so a carry left from before goes into bit 0), written every update, with a trigger the first time. It runs until something else takes Sfx1. A Sfx2 sound that ends while Sfx1 plays `$11`/`$12` requests `$12` again.

### 3.4 Tables (bank 7)

| Addr | Name | Content |
|---|---|---|
| `$4D10` | `PeriodTable` | 96 periods |
| `$4DD0` | `WaveTable` | 16 waves at `$4DF0`, **indexed from 0**; the last wave's last two bytes are `SoundTable`'s unused id-0 slot (the code reads `SoundTable − 2 + 2 × id`) |
| `$4EF0` | `SoundTable` | ids `$01–$30`; headers `$4F50–$5082` |
| `$502E` | `DrumMap` | 15 entries: ids `$01–$0F` |
| `$5207` | `VibratoTable` | 15 (from 1) |
| `$5276` | `EnvelopeTable` | 32 (from 1) → `$52B6–$53D4` |
| `$5AF0` | `VarToneTable` | 144 periods (`$05FF` … `$0796`) |
| `$4987` | `RegBaseTable` | in the code |

---

## 4. Sounds

Lengths in updates (59.7 Hz; music minus tempo skips). "a+b" = intro + loop period.

| Ids | Prio | Tracks | Notes |
|---|---|---|---|
| `$01–$0F` | `$01` | SfxN (`$04`, `$08–$0A`, `$0C` + Sfx1) | drum hits, 2–304 ticks; `$0E`, `$0F` empty |
| `$10` | `$A0` | Sfx2 (raw) | pause jingle, 40 |
| `$11`, `$12` | `$80` | Sfx1 = variable tone (`$11` + SfxN) | §3.3 |
| `$13–$25` | `$70–$A0` | Sfx1, Sfx2 and/or SfxN | SFX, 5–165; `$13`, `$19`, `$24`, `$25` have an empty Sfx1 (they cut Sfx1, e.g. the variable tone) |
| `$26` | `$30` | SfxN + Ch1 + Ch2 (raw) | a jingle on the music channels, 152 |
| `$27–$29` | `$40` | Ch1–Ch3 + Drm | three songs with an intro (Ch1 has an 84-tick part, Drm is empty): 404+1280, 404+1120, 84+1680 |
| `$2A–$2C` | `$40` | Ch1–Ch3 + Drm | the same three songs from their loop point (Ch1, Drm empty) |
| `$2D` | `$40` | SfxN + Ch1–Ch3 + Drm | looping, 24+1056 (SfxN empty) |
| `$2E–$30` | `$40` | Ch1–Ch3 + Drm | end after 1624–1736, 1608–1624, 800–936 |

The full per-id list is in the asm, and the intro/loop lengths per track can be printed with `python tools/kdata10.py hd`.

---

## 5. Quirks and bugs

1. **No request groups**: unlike Belmont's Revenge, Nemesis II and The Spirit of F-1 a refused track never aborts the rest of a request; `wReqRefused` is written by every start and never read (an unreferenced `ClearReqRefused` is left at `$4B39`).
2. **`PlaySoundFar` always maps bank 1 afterwards**, whatever bank its caller had mapped.
3. **`wVarToneVar` index uses `rla`**: a carry left over from the code before goes into the table index (bit 0), so the tone can be one entry off.
4. **`$EA 4n` overwrites `TRK_FLAGS`** (as Belmont's Revenge), cancelling a duty step, the force flag and the rest/release flags; unused by the data.
5. **`$EF` on the drum track skips an extra byte**, and in a raw stream **`$E8`, `$EB`, `$EC`, `$ED`** go to the frame code with the jump-table return address still on the stack (as Nemesis II); neither is in the data.
6. **The CH3 decay sets NR32 bit 4** (the carry of `cp 4` goes into `rla`) and counts the attenuation twice (as before); **`StopAll` sets `wNR51` = `$FF` without writing NR51**.
7. **No fade**: `FadeTick` is a bare `ret`, and `wFadeLevel`, `wMusicHold`, `wQueuedSnd` are read but never written.
8. **Dead code**: the track-4 tempo test in `SndUpdate` (`$40D0`), `SetC0D0` (`$4ACE`), `ClearReqRefused` (`$4B39`), `$EA 2n`, `$ED` and autopan are never used by the data.

---

## 6. Verification

- **Byte-exact rebuild** of the ranges above.
- **Rate:** one update per VBlank (4001 updates in 4200 frames from boot).
- **Streams vs emulator** (`verify/vstream10.py`, the same lighter method as Batman / Raging Fighter): every id alone for 4000 updates (67 s), the game's own requests dropped, the id injected into bank-7 `PlaySound` from the VBlank glue. Every store of `TRK_LEN` for a note, noise byte, raw frame and raw rest is hooked; the stream address and length of each must equal the decoder's (`tools/kdata10.py`) in order, each lasting its length plus the music skips (tempo carry, read after `TempoTick`), and the tracks the decoder ends must end. The variable tone's Sfx1 is checked to read nothing. **48 ids, 9,206 reads, 0 mismatches** (`verify/run_stream_hd.log`). A deliberately wrong note length in the decoder is caught at once.
- **Not verified:** the register writes (no update-by-update model), the envelopes' and vibrato's values, the variable tone, the pause; nothing was checked on hardware.

## Files (in `GBAudioLab\Kon`)

- `HD_SoundDriver.asm`: labelled, commented RGBDS source, byte-exact
- `tools/kdata10.py` (decoder for Hyper Dunk and The Spirit of F-1), `tools/cfg_hd.py`, shared `tools/gen_asm3.py`, `tools/gaps10.py` (unowned data bytes), `verify/vstream10.py`, `verify/run_stream_hd.sh`, log

Regenerate: `python tools/gen_asm3.py hd HD_SoundDriver.asm`.
