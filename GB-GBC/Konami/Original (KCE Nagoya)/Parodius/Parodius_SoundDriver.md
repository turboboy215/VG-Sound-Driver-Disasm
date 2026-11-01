# Parodius (GB): sound driver

ROM: `Parodius (UE) [!].gb` (DMG, MBC1, 256 KB, internal title `PARODIUS`). Konami, 1991.

Part of the Konami family, see `Konami_SoundEngine_Family.md`. This is the **second generation, Nemesis branch**: the track code is Nemesis's instruction for instruction in most places (Nemesis-style `PAN` and autopan, sticky vibrato negate, the pause that only lets the pause jingle run, the queued fade, the request lockout, no request groups). From Belmont's Revenge it has the **VBlank tick** and the **`$ED` duty step**. What is new:

- **banked streams**: the sound header carries a ROM bank (`db prio, bank, mask` + pointers), stored per track (`TRK_BANK`, which pushes every later field up one byte), and **every stream byte is read through ROM0 `ReadStreamByte`**. The driver, the headers, the tables, the SFX and five songs are in bank 14; the other 23 songs in bank 15;
- **`PauseSound` / `ResumeSound`**: the pause silences the four channels and plays `$07`; the resume copies the register shadows back to the channels in use (Tiny Toon has the same routine but never calls it);
- **channel activity flags**: every note of SfxN and the music tracks sets `wChanLeft` / `wChanRight` + 2 × (track − 2) to 1 when NR51 has that channel on that side (nothing in the game reads them);
- the lockout now belongs to ids `$67–$6A`, and Nemesis's follow-up songs and `$0F` special case are gone.

| | |
|---|---|
| API | ROM0 `$044E` `PlaySoundFar` (A = id, 0 = stop all; 117 call/jump sites, some through the vector `$015C`), `$047A` `StartFadeFar` (A = the id to queue), `$049C` `PauseSoundFar`, `$04AD` `ResumeSoundFar`; bank 14 `$6909` `PlaySound`, `$6915` `StartFade`, `$6B0F` `PauseSound`, `$6B25` `ResumeSound`, `$6140` `SndInit` (boot, `$0247`) |
| Game inputs | `wPauseFlags` `$CB8B` bit 0 (set by `PauseSound`), `wSndMute` `$DE02` bit 0 and `wFadeToPlay` `$DD92` (tested by the far wrappers) |
| Tick | **VBlank**: the handler calls `SndUpdateFar` `$042F` → bank 14 `$6201` `SndUpdate`, skipped while `wSndBusy` `$CB85` bit 0 is set (a far call is running) |
| Driver code | ROM0 `$0028` (rst `$28`), `$0153` (vector), `$042F–$04BD`, `$0C6E–$0C7E`; bank 14 `$612C–$6B7B` (2.6 KB, with inline jump tables) |
| Data | bank 14 `$5BE1–$612B` (songs `$62–$66`) and `$6B7C–$7D00` (tables, headers, SFX); bank 15 `$4000–$7FF2` (songs `$4F–$61`, `$67–$6A`) |
| RAM | seven tracks at `$C080 + n×$100` (`$80–$A7`), globals `$C0AB–$C0BD`, register shadows `$C1A8–$C1BC` |
| Channels | Sfx1 (CH1), Sfx2 (CH2), SfxN (CH4), Ch1, Ch2, Ch3, Drm (drum notes = sound ids `$01–$06` through a 12-entry map) |
| Counts | 106 ids `$01–$6A`: 6 drum hits, the pause jingle `$07`, SFX and jingles `$08–$4E`, 28 songs `$4F–$6A` |

`PAR_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over ROM0 `$0028–$002C`, `$0153–$0155`, `$042F–$04BD`, `$0C6E–$0C7E`, bank 14 `$5BE1–$7D00` and all of bank 15. It assembles cleanly with `-Wall`.

```
rgbasm -Wall -o par.o PAR_SoundDriver.asm
rgblink -o par.gb par.o
python tools/cmp_ranges.py par.gb "Parodius (UE) [!].gb" 0:0028-002C 0:0153-0155 0:042F-04BD 0:0C6E-0C7E E:5BE1-7D00 F:4000-7FFF
```

---

## 1. Structure

### 1.1 Track fields

Track n is at `H = $C0 + n`, `L = $80–$A7`. Up to `$85` the layout is Nemesis's; `$86` is new, and every Nemesis field from `$86` on sits one byte higher. `$A5–$A7` are Belmont's Revenge's duty-step fields, also one higher.

| L | Name | Use |
|---|---|---|
| `$80` / `$81` / `$82` / `$84` | ID, PRIO, PTR, LEN | |
| `$85` | FLAGS | 0 released, 1 autopan, 3 vibrato negative (sticky), 4 duty step, 6 force register writes, 7 rest |
| `$86` | **BANK** | ROM bank of the streams (from the header) |
| `$87` | REPCNT | `$FE n` counter |
| `$88` / `$89` / `$8A` | VIB, TRANSP, ATTEN | |
| `$8B` / `$8D` | VIBOFS (word), vibrato repeat counter | |
| `$8E` / `$8F` / `$90` | UNIT, OCTAVE, PERIOD (word) | |
| `$92–$96` | VOL, DUTY, ENV, GATE, RELTICK | |
| `$97–$9A` | VIBTIMER, VIBRELOAD, CH3TIMER, CH3RELOAD | |
| `$9C` / `$9D` / `$9F` | LEVEL, SEGNO, RET | one segno, one return slot |
| `$A1` / `$A3` / `$A4` | VIBPTR, VIBIDX, VIBLOOPIDX | |
| `$A5` / `$A6` / `$A7` | duty step: counter, start duty, ticks | |

`SndInit` clears `$80–$FF` of every page, `StopAll` and a track start only `$80–$A7` and `$87–$8D`.

### 1.2 Globals and register writes

`wTrackIdx` `$C0AB`, `wRegBase` `$C0AC`, `wTempo`/`wTempoAcc`/`wTempoSkip` `$C0AD–$C0AF`, `wQueuedSnd` `$C0B0` (the fade target), `wNR51` `$C0B1`, `wSweepVal` `$C0B2`, `wReqId`/`wReqPrio` `$C0B3/4`, `wRegVal`/`wRegOff` `$C0B5/6`, `wMusicHold` `$C0B7` (read, never set), `wLockout` `$C0B8` (word), `wFadeReq`/`wFadeTimer`/`wFadeLevel` `$C0BA–$C0BC`, `wReqBank` `$C0BD`.

`WriteReg` writes `wRegVal` to `$FF10 + wRegBase + wRegOff` (bases `00 05 0F 00 05 0A 0F` by track) and keeps it in `wRegShadow + base + offset` (`$C1A8–$C1BC`). It does nothing for music Ch1 while Sfx1 plays or music Ch2 while Sfx2 plays, and skips the write when the shadow already holds the value unless the track's force flag is set (at a track start and by rests; cleared by a note just before its volume). `TriggerReg` writes NRx4 = shadow | `$80`.

`ReadStreamByte` (ROM0 `$0C6E`, through the vector `$0153`) maps the bank in `TRK_BANK` of page H, reads `[DE]` into L and maps the caller's bank back (from the `$7FFF` byte every bank carries). Vibrato tables, the drum map, periods and waves are read directly from bank 14.

---

## 2. Timing

### 2.1 Update

Once per VBlank `SndUpdate` runs `FadeTick`, `LockoutTick`, `TempoTick`, then tracks 0–6 in order (each only if its id is set), then a queued id. SFX and music run at 59.7 Hz.

### 2.2 Tempo

Every update `wTempoAcc += wTempo`; on a carry `wTempoSkip` stops the loop at track 3, so **all four music tracks skip the update** (`wMusicHold` would do the same). Music runs at 59.7 Hz × (1 − tempo/256). Tempos in the data: `$00`, `$10`, `$15`, `$20`, `$25`, `$30`, `$32`, `$35`, `$38`, `$40`, `$50`–`$90`.

### 2.3 Fade

`StartFade` sets `wFadeReq` = A | `$80` (A = the id to play when the fade is over). Every 32 updates `wFadeLevel` goes up by one; it comes off the volume of new music notes (half of it on CH3's level code). At level 5 the target is queued; if it is below 6, `StopAll` runs instead (and clears the queue, so nothing plays); otherwise the fade ends (level 0, `wFadeReq` 0) and the target plays at the end of the update. Nothing fades while paused.

`StartFadeFar` plays the id at once instead when `wFadeToPlay` is set.

### 2.4 Requests

`PlaySound` (`$6966`): 0 → `StopAll`. Then `CheckLockout`: `$07` and ids below 7 always pass; while `wLockout` runs only `$67–$6A` pass; otherwise `$67–$6A` load `wLockout` from `LockoutTable` (`$0140`, `$0140`, `$0150`, `$0141` updates, 5.4–5.6 s) and pass. A refused request returns silently.

The header comes from `SoundTable` (`$6D18 + 2 × id`): priority, bank, track mask, pointers. Each track in the mask is started when the new priority is ≥ the track's current one: ID, PRIO, PTR, LEN = 1, FLAGS = `$40` (force), BANK, `$87–$8D` = 0. **A refused track is just skipped**; the others still start. A started track ORs its NR51 bits into `wNR51`; Sfx1 (and Ch1 while Sfx1 is idle) writes NR10 = 8. Finally NR51 = `wNR51`.

A drum note plays `DrumMap[hi − 1]` (`01 02 01 03 03 03 03 04 05 06 06 06`) through `PlaySound`, so a drum hit is an ordinary request on SfxN with priority 1.

### 2.5 Pause

The game's pause toggle (`$3785`) calls `PauseSoundFar` / `ResumeSoundFar`. `PauseSound` mutes CH1, CH2, CH4 (NRx2 = 0) and CH3 (NR32 = 0), writes `wPauseFlags` = 1 and plays `$07` (priority `$80`, Sfx2). While bit 0 is set only track 1 runs, and only while it plays `$07` (the loop stops at track 1 otherwise), and the fade waits. `ResumeSound` writes `wPauseFlags` = 0 and copies the shadows back: NR10–NR14 if Sfx1 or Ch1 plays, NR21–NR24 if Sfx2 or Ch2, NR30–NR34 if Ch3, NR41–NR44 if SfxN plays an id ≥ 8 (not a drum hit). No trigger is written, so each channel comes back at its next note.

---

## 3. Data format

As Nemesis (`kdata.py`), with the duty step:

| Byte | Meaning |
|---|---|
| `$00–$DF` | note: hi = pitch 1–12 (0 = rest; 13 reads the next octave's C), lo × unit (lo 0: 256). Noise SFX: NR43 = byte (NR44 = 0 through the shadow, so no retrigger), length = unit. Drum track: `DrumMap[hi − 1]` |
| `$E0` | `VOICE unit, duty<<4\|vol, gate<<4\|env` (noise SFX: `unit, vol<<4\|env`, written to NR42 + trigger; drums: unit only) |
| `$E1–$E6` | octave |
| `$E7 x` / `$E8 xy` | unit / gate x (15 = release one tick before the end), env y |
| `$E9 x` | NR10 = x (through `WriteReg`, kept in `wSweepVal`) |
| `$EA xy` | 0 transpose up y, 1 down y, 2 vibrato y (0 = off, offset cleared), 3 duty (CH3: wave), 4 FLAGS = y \| 2 (y ≠ 0) or 0 |
| `$EB x` / `$EC x` | no-ops |
| `$ED xy` | duty step: notes start with duty y, the voice duty comes back after x ticks; `$ED 00` off |
| `$EE x` | tempo |
| `$EF x` | PAN: NR51 = (wNR51 & `PanMaskTable[track]`) \| (swap(x) & ~mask); not on Ch1 while Sfx1 plays |
| `$F0–$FA` | attenuation (noise SFX: the volume is rewritten at once) |
| `$FB` / `$FC` / `$FD addr` | segno / return / call (one slot each) |
| `$FE n` / `$FE $FF addr` | back to the segno until the n-th pass / jump |
| `$FF` | end |

Note-on: period index = (pitch − 1) + transpose + 12 × octave, from `PeriodTable` (96 entries); the vibrato offset is added (negated while FLAGS bit 3 is set, which nothing clears). NRx2 = (vol − atten − `wFadeLevel`) << 4 (0 on a borrow) with envelope 0, then a trigger. At the release tick NRx2 = level | env and a trigger; on CH3 the level code steps down every env ticks from there. CH3 notes write NR30 = `$80`; the level code is (vol / 2) & 3 + atten + `wFadeLevel` / 2, mute from 4.

Vibrato steps are two bytes: `time << 4 | negative << 3 | offset >> 8`, `offset & $FF`; `$FB` loop point, `$FE n` repeat (`$FE $FF` forever), `$FF` hold.

### 3.1 Tables (bank 14)

| Addr | Name | Content |
|---|---|---|
| `$653C` | `PanMaskTable` | `EE DD 77 EE DD BB FF` (bits kept by `PAN`) |
| `$665B` / `$665F` | `ChanLeftBits` / `ChanRightBits` | NR51 bits of SfxN, Ch1, Ch2, Ch3 |
| `$6902` | `RegBaseTable` | `00 05 0F 00 05 0A 0F` |
| `$695E` | `LockoutTable` | 4 words for `$67–$6A` |
| `$6B7C` | `PeriodTable` | 96 periods |
| `$6C3C` | `WaveTable` | 15 pointers (index duty − 1) to 12 waves at `$6C5A`; the last runs 2 bytes into the sound table |
| `$6D18` | `SoundTable` | ids `$01–$6A` (entry 0 unused); headers `$6DEE–$70A5`, drum hits `$70B2–$70F1` |
| `$70A6` | `DrumMap` | 12 entries |
| `$70F2` | `VibratoTable` | 15 pointers, data `$7110–$71D5` |

---

## 4. Sounds

Lengths in updates (59.7 Hz; music minus tempo skips).

| Ids | Prio | Bank | Tracks | Notes |
|---|---|---|---|---|
| `$01–$06` | `$01` | 14 | SfxN | drum hits, 1–3 ticks |
| `$07` | `$80` | 14 | Sfx2 | the pause jingle (48 ticks) |
| `$08–$4D` | `$05–$50` | 14 | Sfx1 and/or Sfx2 or SfxN | SFX, 3–153 ticks |
| `$2E`, `$2F`, `$34`, `$39`, `$45` | `$35`/`$50` | 14 | Ch1–Ch3 (`$2E`: Sfx1 + Sfx2 + Ch3) | short jingles on the music tracks |
| `$4E` | `$35` | 14 | Ch3 | an arpeggio repeated 240 times (10,800 ticks) |
| `$4F–$61`, `$67–$6A` | `$30` | 15 | Ch1–Ch3 + Drm | songs; `$67–$6A` start the lockout |
| `$62–$66` | `$30` | 14 | Ch1–Ch3 + Drm | songs; `$62`, `$64`, `$65` end, the rest loop |

The intro/loop lengths per track can be printed with `python tools/kdata7.py -v`.

---

## 5. Quirks and bugs

1. **`$EA x` with x ≥ `$50` runs past `ExtTable`** into the code at `Ext_TransposeUp` and jumps to `$CDE1` (WRAM). Not in the data.
2. **The CH3 wave is copied with the channel on**: `WriteDuty` writes wave RAM directly, without NR30 = 0 and without the blocking test (as Nemesis).
3. **`Flow_End` gives the duty and the plain period back** to music Ch1/Ch2 when Sfx1/Sfx2 end (Sfx1 also NR10 = 0), but not the volume, NR51 or a trigger; the writes use the ended SFX track's force flag. The music comes back at its next note.
4. **A fade to an id below 6 queues nothing**: `StopAll` clears `wQueuedSnd` right after it is set.
5. **The pause writes the whole `wPauseFlags`** (1, then 0), so the game's other bits there are cleared.
6. **The vibrato negate is sticky**: a negative step sets FLAGS bit 3 and nothing clears it until the track restarts.
7. **Noise notes don't retrigger** (NR44 = 0 through the shadow), so they only change the frequency of the running noise; only `VOICE` and `ATTEN` trigger.
8. **The activity flags are write-only**: `wChanLeft`/`wChanRight` are set by every SfxN/music note (from the real NR51) and never read or cleared by anything else in the ROM.
9. **Unused / dead:** `$EB`, `$EC`, `wMusicHold`, `DeadCheck` (`$6238`), three orphan Sfx1 streams (`14:$7207`, `$7838`, `$7A9F`, decoded in the asm), single `$FF` bytes after a few streams, wave entries that point into the sound table.

---

## 6. Verification

- **Byte-exact rebuild** of the ranges above.
- **Rate:** one update per VBlank (6026 updates in 6120 frames in PyBoy; the handler skips lag frames).
- **Model vs emulator** (`verify/vmodel7.py`, `tools/kmodel7.py`, a transliteration over a RAM image): all seven track pages `$80–$A7`, the globals `$C0AB–$C0BD` and the shadows `$C1A8–$C1BC` byte for byte, and the **exact sequence of register writes** of every update together with the writes to `wChanLeft`/`wChanRight`; RAM outside the driver's fields follows the emulator; the game's own requests dropped:
  - each of the 106 ids alone for 6000 updates (100 s): **0 mismatches** (`verify/run_all_par.sh`);
  - three mixed 6000-update scenarios (`verify/run_combo_par.sh`): songs from both banks with SFX on CH1, CH2 and CH4 (blocking, the end giving duty and period back), the jingles on the music tracks, pause and resume with `$07` (with an SFX and a noise SFX during the pause), fades to songs, to `$02` (`StopAll`) and to `$06`, the four lockout ids with refused and passing requests, priority refusals, drum hits against noise SFX, `StopAll`: **0 mismatches**;
  - **unused features**: a copy of the ROM (`verify/patch_par.py`) with `$EB`/`$EC` in a song, an attenuation on a noise SFX and a vibrato table with a finite `$FE n` repeat: **0 mismatches**.
- **Not verified:** nothing was checked on hardware or against audio output.

## Files (in `GBAudioLab\Kon`)

- `PAR_SoundDriver.asm`: labelled, commented RGBDS source, byte-exact
- `tools/kdata7.py` (data decoder, on top of `kdata.py`), `tools/cfg_par.py`, shared `tools/gen_asm3.py` (now with banked headers), `tools/kmodel7.py`, `verify/vmodel7.py`, `verify/run_all_par.sh`, `verify/run_combo_par.sh`, `verify/patch_par.py`, logs

Regenerate: `python tools/gen_asm3.py par PAR_SoundDriver.asm`.
