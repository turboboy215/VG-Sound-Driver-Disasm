# Tiny Toon Adventures: Babs' Big Break (GB): sound driver

ROM: `Tiny Toon Adventures - Babs' Big Break (E) [!].gb` (DMG, MBC1, 128 KB, internal title `TINY TOON ADVENT`). Konami, 1992.

Part of the Konami family, see `Konami_SoundEngine_Family.md`. This is **Nemesis II's third-generation driver, reworked**. The track page is Nemesis II's, with the fields from `$90` on moved up one byte and envelope fields inserted. The request groups with a sticky refusal flag, the register shadows, the vibrato tables (`$FB` loop point, `$FE n` repeat, `$FF` hold), the raw streams (now marked by a first byte `$01`) and the staged music fade are Nemesis II's. Much is different:

- it runs from **one bank** (7) on **VBlank** (59.7 Hz), music and SFX at the same rate;
- the stream language **goes back to the generation 1–2 flow commands** (`$FB` segno, `$FC` return, `$FD` call, `$FE n` repeat / `$FE $FF` jump, `$FF` end) and gains a **`$D0–$DF` block** (mostly 2-byte no-ops, plus a register write, the old `$EA` extensions and `PAN`);
- all register writes go through one **`WriteReg`** with a shadow per register, skipped when unchanged unless the track's force flag is set;
- new **volume envelope** tables (`$EC n`), an **octave shift** (`$EA x`), a duty step and a detune with new encodings;
- a refused track **ends the whole request** at once.

Several of these come with bugs (§5). The worst: the fade's track stops jump into the end-of-track handler with the wrong return address on the stack.

| | |
|---|---|
| API | ROM0 `$0515` `PlaySoundFar` (A = id, 0 = stop all; 107 calls), `$050B` `StopSoundFar` (13), `$0510` `StopThenPlayFar` (23), `$052B` `StartFadeFar` (8); bank 7 `$4C08` `PlaySound`, `$4C0E` `StopSound`, `$4C16` `StartFade`, `$4014` `SndInit` |
| Game inputs | none besides the calls (`wMusicHold` `$C790` is read but never set) |
| Tick | **VBlank**: the handler (`$0061`, and its lag-frame path) calls `SndUpdateFar` `$04ED` → bank 7 `$4238` `SndUpdate`, skipped while `wSndLock` `$C985` bit 0 is set; `PlaySoundFar` drops requests while it is set |
| Driver code | ROM0 `$0028` (`AddHLA`, `rst $28`), `$04E7–$0540`; bank 7 `$4000–$4020`, `$4180–$4E14` (3.2 KB, with inline jump tables) |
| Data | bank 7 `$4021–$417F` (envelopes), `$4E15–$6FA2` (tables, headers, streams). `$6FA3–$7FFE` is other game data, `$7FFF` the bank number |
| RAM | seven tracks at `$C080 + n×$100` (`$80–$BF`), globals `$C784–$C796`, register shadows `$C79F–$C7B3` |
| Channels | Sfx1 (CH1), Sfx2 (CH2), SfxN (CH4), Ch1, Ch2, Ch3, Drm (drum notes = sound ids `$01–$06` through a 13-entry map) |
| Counts | 99 ids `$01–$63`: 6 drum hits, SFX/jingles `$07–$4D`, 22 songs `$4E–$63` |

`TT_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over ROM0 `$0028–$002C`, `$04E7–$0540` and bank 7 `$4000–$6FA2`. It assembles cleanly with `-Wall`.

```
rgbasm -Wall -o tt.o TT_SoundDriver.asm
rgblink -o tt.gb tt.o
python tools/cmp_ranges.py tt.gb "Tiny Toon Adventures - Babs' Big Break (E) [!].gb" 0:0028-002C 0:04E7-0540 7:4000-6FA2
```

---

## 1. Structure

### 1.1 Track fields

Track n is at `H = $C0 + n`, `L = $80–$BF`. Compared with Nemesis II, `$80–$8E` are the same, `$90–$B6` moved to `$91–$BF`, and `$B2–$B9` are new:

| L | Name | Use |
|---|---|---|
| `$80` / `$81` / `$82` / `$84` | ID, PRIO, PTR, LEN | |
| `$85` | FLAGS | 0 released, 1 autopan, 3 vibrato negative, 4 duty step, 6 force register writes, 7 rest |
| `$86` | FLAGS2 | 0 envelope step due, 1 envelope ended, 4+5 raw stream, 7 vibrato delay running |
| `$87` | REPCNT | `$FE n` counter |
| `$89` / `$8A` / `$8B` | VIB, TRANSP, ATTEN | |
| `$8C` / `$8E` / `$8F` | VIBOFS (word), vibrato and envelope repeat counters | |
| `$91` / `$92` / `$93` | UNIT, OCTAVE (0–5), PERIOD | |
| `$95` | raw-frame period | |
| `$97–$9B` | VOL, DUTY, ENV, GATE, RELTICK | |
| `$9C` / `$9D` / `$9E` / `$9F` / `$A1` | VIBTIMER, VIBRELOAD, CH3TIMER, CH3RELOAD, LEVEL | |
| `$A2` / `$A6` | SEGNO, RET | one segno, one return slot |
| `$AA` / `$AC` / `$AD` / `$AE` | VIBPTR, VIBIDX, VIBLOOPIDX, VIBDEPTH | |
| `$AF` / `$B0` / `$B1` | vibrato delay (units, reload, counter) | |
| `$B2` / `$B3` / `$B4` / `$B5` | **ENVNO, ENVTIMER, ENVRELOAD, ENVVOL** | |
| `$B6` / `$B8` / `$B9` | **ENVPTR, ENVIDX, ENVLOOPIDX** | |
| `$BA` / `$BB` / `$BC` | duty step: counter, start duty, ticks | |
| `$BD` / `$BE` / `$BF` | PAN (NR51 bits), OCTSHIFT, DETUNE | |

### 1.2 Globals and register writes

`wTrackIdx` `$C784`, `wRegBase` `$C785`, `wTempo`/`wTempoAcc`/`wTempoSkip` `$C786–$C788`, `wQueuedSnd` `$C789` (never set), `wNR51` `$C78A`, `wReg0Val` `$C78B` (never read), `wReqId`/`wReqPrio` `$C78C/D`, `wRegVal`/`wRegOff` `$C78E/F`, `wMusicHold` `$C790`, a countdown `$C791` (nothing sets it), `wFadeReq`/`wFadeStep`/`wFadeLevel` `$C793–$C795`, `wReqRefused` `$C796`.

`WriteReg` writes `wRegVal` to `$FF10 + wRegBase + wRegOff` (bases `00 05 0F 00 05 0A 0F` by track, offsets 0–4 = NRx0–NRx4) and keeps it in `wRegShadow + base + offset` (`$C79F–$C7B3`). It does nothing for music Ch1 while Sfx1 plays or music Ch2 while Sfx2 plays (Ch3 has no SFX), and skips the write when the shadow already holds the value, unless the current track's force flag (set at a track start and by rests, cleared at a note's volume) is on. `TriggerReg` writes NRx4 = shadow | `$80`. **`$C79F`, the NR10 shadow, is also the fade timer** (§5.2).

---

## 2. Timing

### 2.1 Update

Once per VBlank `SndUpdate` runs `FadeTick`, a countdown nothing uses, `TempoTick`, then tracks 0–6 in order (each only if its id is set), then `wQueuedSnd` (never set). SFX and music run at 59.7 Hz.

### 2.2 Tempo

Every update `wTempoAcc += wTempo`; on a carry `wTempoSkip` makes **all four music tracks skip this update** (the loop stops at track 3; `wMusicHold` would do the same). Music runs at 59.7 Hz × (1 − tempo/256). Tempos in the data: `$10`, `$20`, `$30`, `$40`, `$50`, `$60`.

### 2.3 Fade

`StartFade` sets `wFadeReq` = A | `$80`. Every `$30` updates (0.8 s) `wFadeLevel` and `wFadeStep` go up by one. `wFadeLevel` comes off the volume of new music notes (half of it on CH3's level code). Step 5 should stop the drum track, step 7 Ch3, step 9 Ch1 and Ch2 (resetting the counters), but only the stops where the matching SFX track is busy work as meant (§5.1). **The fade never ends by itself**: `wFadeReq` is cleared only by `StopAll`, so the steps go on (and after a working step 9 the fade starts over from level 0).

### 2.4 Requests

`PlaySound` (`$4C1C`): 0 → `StopAll`. Otherwise header from `SoundTable` (`$4F2F + 2 × id`): priority, track mask, pointers. Sfx1 is started first; then, if `wReqRefused` is set, it is cleared and the request ends; else Sfx2 and SfxN; the same test again; then the music tracks without a test; finally NR51 = `wNR51`. Each start ORs the channel's bits into `wNR51` (before the priority test), and Sfx1 (and Ch1 when Sfx1 is idle) writes NR10 = 8. A track is started when the new priority is ≥ its current one: ID, PRIO, PTR, LEN = 1, FLAGS = `$40` (force), `$86–$90` = 0, PAN = `$FF`, and FLAGS2 bits 4/5 when its first byte is `$01` (raw stream). **A refused track ends the request at once with `wReqRefused` still set** (§5.3).

A drum note plays `DrumMap[hi − 1]` (`01 02 05 02 01 02 01 03 06 04 04 04 06`) through `PlaySound`, so a drum hit is an ordinary request.

### 2.5 Pause

The driver has no pause handling. `RestoreRegs` (`$4DBE`), which copies the shadows back to the registers of every channel in use, is never called.

---

## 3. Data format

| Byte | Meaning |
|---|---|
| `$00–$CF` | note: hi = pitch 1–12 (0 = rest), lo × unit = length (lo 0: 256). Noise SFX: NR43 = byte (NR44 = 0 through the shadow, so no retrigger), length = unit. Drum track: `DrumMap[hi − 1]` |
| `$D0–$D8`, `$DB–$DE` `x` | no-ops (two bytes) |
| `$D9 x` | register offset 0 of the channel = x (NR10 on CH1, NR30 on CH3, unused `$FF15`/`$FF1F` otherwise) |
| `$DA xy` | 0 transpose up y, 1 down y, 2 no-op, 3 duty (CH3: wave), 4 FLAGS = y (with bit 1, autopan, when y ≠ 0) |
| `$DF x` | PAN: this channel's NR51 bits from x (not written for a blocked music track); on the drum track it skips one more byte |
| `$E0` | `VOICE unit, duty<<4\|vol, gate<<4\|env` (noise SFX: `unit, vol<<4\|env`, written to NR42 + trigger; drums: unit only). Turns the envelope off |
| `$E1–$E6` | octave |
| `$E7 x` / `$E8 xy` | unit / gate x (15 = release one tick before the end), env y |
| `$E9 xy` | duty step: notes start with duty y, the voice duty comes back after x ticks; `$E9 00` off |
| `$EA xy` | octave shift x (`OctaveShiftTable`: 0–7 = +0…+7 octaves, 8–15 = −1…−8) and y semitones, negative when x ≥ 8. The shift only applies when the octave isn't 1 (§5.8) |
| `$EB n xy` | vibrato table n, delay x × unit ticks, depth y; `$EB 00` off (offset cleared) |
| `$EC n` | envelope table n & 15 (0 = off) |
| `$ED x` | detune: period + 2x, or − 2(x & `$7F`) when bit 7 is set |
| `$EE x` / `$EF x` | tempo / no-op |
| `$F0–$FA` | attenuation (noise SFX: the volume is rewritten at once) |
| `$FB` / `$FC` / `$FD addr` | segno / return / call (one slot each) |
| `$FE n` / `$FE $FF addr` | back to the segno until the n-th pass / jump |
| `$FF` | end |

Note-on: period index = (pitch − 1) + transpose + 12 × octave + octave shift, from `PeriodTable` (85 entries); vibrato offset and detune are added. NRx2 = (vol − atten) << 4 with envelope 0 (music: minus `wFadeLevel`; 0 on a borrow), then a trigger. At the release tick NRx2 = level | env and a trigger; on CH3 the level code steps down every env ticks from there.

### 3.1 Envelopes and vibrato

Both are index-based tables of one-byte steps: `time << 4 | value`, `$FB` loop point, `$FE n` repeat n times back to it (`$FE $FF` forever), `$FF` end. Vibrato values are negative << 3 | offset, × depth; an envelope step sets the volume (NRx2 = vol << 4 and a trigger at each step; attenuation and fade only apply to the first step, at the note-on) until `$FF`. The envelope table has 32 entries but `$EC` reaches only 1–15.

### 3.2 Raw streams

A stream whose first byte is `$01` is read as raw: `$01 unit duty NR10` (the header, recognised whenever a read starts on `$01`), then two-byte frames `vol << 4 | period >> 8`, `period & $FF` (NRx3/NRx4, NRx2, trigger, and this channel's NR51 bits) or `$00` rests, one unit each. `$E7`, `$E9` (as `$D9`), `$EA` (as `$DA`), `$EE`, `$EF` (as `$DF`) and the flow commands work. No data uses raw streams.

### 3.3 Tables (bank 7)

| Addr | Name | Content |
|---|---|---|
| `$4021` | `EnvelopeTable` | 32 pointers, data `$4061–$417F` |
| `$47E5` | `OctaveShiftTable` | `00 0C 18 24 30 3C 48 54 F4 E8 DC D0 C4 B8 AC A0` |
| `$4A73` | `RegBaseTable` | `00 05 0F 00 05 0A 0F` |
| `$4E15` | `PeriodTable` | 85 periods |
| `$4EBF` | `WaveTable` | 15 pointers (index duty − 1) to overlapping waves at `$4EDD–$4F3F`; entries 9–12, 14 and 15 point at `$4F30`, inside the sound table |
| `$4F2F` | `SoundTable` | ids `$01–$63` (entry 0 unused); headers `$4FF7–$5208` |
| `$5209` | `DrumMap` | 13 entries; drum-hit headers `$5216–$522D` |
| `$5255` | `VibratoTable` | 15 pointers, data `$5273–$52A2` (the data uses 4, 5, 6) |

---

## 4. Sounds

Lengths in updates (59.7 Hz; music minus tempo skips).

| Ids | Prio | Tracks | Notes |
|---|---|---|---|
| `$01–$06` | `$01` | SfxN | drum hits, 1–65 ticks |
| `$07–$4D` | `$26–$37` | Sfx1 and/or SfxN; `$2D`, `$37` Sfx1 + Sfx2 | SFX, 0–132 ticks. `$4C` is `$07`'s stream at priority `$33`, `$4D` uses `$07`'s header |
| `$11` | `$40` | Ch1–Ch3 + Drm | jingle (56 ticks) |
| `$20` | `$31` | Sfx1 + Sfx2 + Ch3 | 100 ticks |
| `$28` / `$4B` | `$31` | Ch1 + Ch2 / Ch1–Ch3 | short jingles |
| `$4E–$63` | `$40` | Ch1–Ch3 + Drm | the songs; `$53`, `$54`, `$57`, `$58` end, the rest loop |

The intro/loop lengths per track can be printed with `python tools/kdata6.py -v`.

---

## 5. Quirks and bugs

1. **The fade's track stops break the stack.** At steps 5 and 7 (drums, Ch3), and at step 9 for Ch1/Ch2 when their SFX track is idle, `FadeTick` jumps (`jp`) or calls into `Flow_End`, which starts with the `pop hl` meant for the jump-table dispatch. That takes `FadeTick`'s return address as the track page: the two "stop" writes go to `$4280/$4281` or `$4180/$4181` (MBC registers), the track keeps playing, NRx2 = 0 is written for the channel of the last track ticked (by `wTrackIdx`/`wRegBase` left from the previous update), and after a `jp` **the rest of that update is skipped** (the `ret` returns from `SndUpdate`). Only the stops for a channel whose SFX track is busy at that moment clear the track. The music is silenced by `wFadeLevel` alone.
2. **The fade timer is the NR10 shadow** (`$C79F`): it is cleared every update while no fade runs, counts up during a fade, and is set to 8 by every Sfx1 start (which shifts the fade's timing). An NR10 write through `WriteReg` (`$D9` on CH1, a raw header) can be skipped or forced by the wrong shadow value.
3. **A refused track aborts the request with the flag left set.** `StartRefused` pops the start routine's saved AF into DE and its return address into AF, so its `ret` returns from `PlaySound`: no further tracks, no NR51 write, `wReqRefused` = 1. The next request is then cut after its Sfx1 part, or dropped entirely if it has no Sfx1. Drum hits are requests too, so a drum hit refused by a noise SFX can swallow the next sound.
4. **Envelopes never play**: the only `$EC` in the data (`$20`'s Sfx2) comes right before a `VOICE`, which turns it off.
5. **A finished `$FE n` repeat leaves the vibrato/envelope index one byte behind**, so the next step is read twice (or the count byte is read as a step). The data only uses `$FE $FF`.
6. **Raw streams: `$E8` and `$EB–$ED` crash.** The raw dispatcher sends them to the frame code with HL still pushed and H = `$4A`. No data uses raw streams.
7. **CH3 is switched off between notes**: every time LEN runs out NR30 = 0 is written before the next command is read, and the next note writes NR30 = `$80` again. Waves are copied to wave RAM with the channel on, unblocked.
8. **The octave shift needs an octave above 1**: the table term is skipped when TRK_OCTAVE is 0.
9. **Noise notes don't retrigger** (NR44 = 0 through the shadow), so they only change the frequency of the running noise; only `VOICE` and `ATTEN` trigger.
10. **`Flow_End` gives the duty and plain period back** to music Ch1/Ch2 when Sfx1/Sfx2 end (Sfx1 also NR10 = 0), but not the volume, NR51 or a trigger: the music comes back at its next note.
11. **`$DA x` with x ≥ `$50` runs past its 5-entry table**; `$DF` on the drum track skips an extra byte (not in the data).
12. **Unused / dead:** raw streams, the `$D0`–`$DE` no-ops, `$D9`, `$EF`, the duty step, envelopes, `wQueuedSnd`, `wMusicHold`, the `$C791` countdown, `wReg0Val`, `RestoreRegs`, the dead check at `$425F`, two orphan bytes at `$5371`, a few extra `$FF` bytes after streams.

---

## 6. Verification

- **Byte-exact rebuild** of the three ranges.
- **Rate:** one update per VBlank.
- **Model vs emulator** (`verify/vmodel6.py`, `tools/kmodel6.py`, a transliteration over a RAM image): all seven track pages `$80–$C0`, the globals and register shadows `$C784–$C7B3` byte for byte, and the **exact sequence of register writes** of every update (every `ldh [n],a`, `ld [c],a` and register `ld [de],a` in the driver is hooked); RAM outside the driver's fields follows the emulator; the game's own requests and fades dropped:
  - each of the 99 ids alone for 6000 updates (100 s): **0 mismatches** (`verify/run_all_tt.sh`);
  - three mixed 6000-update scenarios (`verify/run_combo_tt.sh`): songs with SFX on CH1, CH2 and CH4 (blocking, the end giving duty and period back), drum hits against noise SFX, refusals and the dropped request after them, fades through steps 5, 7 and 9 both with idle SFX tracks (the stack bug, MBC writes and the skipped updates) and with busy ones (the real stops and the restart), `StopAll`: **0 mismatches**;
  - **unused features**: a copy of the ROM (`verify/patch_tt.py`) with a raw stream (header, frames, rests, raw commands, segno/repeat), an envelope after the voice with a loop point and a repeat, a finished vibrato repeat (the lagging index), `$E9`, `$D0`, `$D9`, `$EF`, `$DA 2x` and a negative octave shift: **0 mismatches**.
- **Not verified:** nothing was checked on hardware or against audio output.

## Files (in `GBAudioLab\Kon`)

- `TT_SoundDriver.asm`: labelled, commented RGBDS source, byte-exact
- `tools/kdata6.py` (data decoder), `tools/cfg_tt.py`, shared `tools/gen_asm3.py`, `tools/kmodel6.py`, `verify/vmodel6.py`, `verify/run_all_tt.sh`, `verify/run_combo_tt.sh`, `verify/patch_tt.py`, logs

Regenerate: `python tools/gen_asm3.py tt TT_SoundDriver.asm`.
