# Nemesis II: The Return of the Hero (GB): sound driver

ROM: `Nemesis II - The Return of the Hero (E) [!].gb` (DMG, MBC1, 256 KB, internal title `NEMESIS 2 HERO`). Konami, 1991.

Part of the Konami family, see `Konami_SoundEngine_Family.md`. This is a **third generation** of the driver. The track layout, the request groups with the stale refusal flag, the register shadows, the raw `PAN` byte and the duty step continue from Belmont's Revenge, but much is new:

- the sounds are spread over **three banks** (13, 14, 15), chosen by the top bits of the sound id, and **each bank has its own copy of the track code** and its own tables; ROM0 holds the requests and the update loop;
- a **128 Hz timer** tick, with the music tracks running **at half rate** in alternating pairs;
- a **new flow syntax** (paired `$FB`/`$FC` loop markers, `$FD` call/return, `$FE` mark/jump);
- vibrato moved to **`$EB n xy`** with a **delay** and a **depth**, and one-byte vibrato steps;
- **raw streams** (first byte `$E1`) that write register frames directly;
- a new tempo scheme, a **progressive music fade** that stops the tracks one group at a time.

| | |
|---|---|
| API (ROM0) | `$09B2` `PlaySound` (A = id, 0 = stop all), `$0283` `PlaySoundFar` (what the game calls, 98 call sites), `$0B3A` `StopAll`, `$0B76` `SndPause`, `$0B80` `SndUnpause`, `$09AE` `StartMusicFade` (unused: the game writes `wFadeReq` directly) |
| Game inputs | `wPauseFlags` `$C794` bit 0, `wFadeReq` `$C0CB`, `wSndDisable` `$CC0E` bit 0 (PlaySoundFar ignores requests) |
| Tick | **timer, 128 Hz** (TMA `$80`, TAC 16384 Hz, set by the game's register init at `$0C6D`): `$0050` → `TimerISR` `$00B3` → `SndUpdate` `$0BDB`, skipped while `wSndLock` `$C78D` bit 0/1 is set |
| Banks | 13: ids `$01–$5D` (drum hits, SFX, pause jingle); 14: `$81–$96` (drum hits, 9 songs); 15: `$C1–$D9` (drum hits, 12 songs) |
| Driver code | ROM0 `$0028`, `$0050`, `$00B3–$00CD`, `$0254`, `$0283–$0307`, `$09AE–$0C6C`, `$0D85` (≈ 0.8 KB); per bank ≈ 2.6 KB (13: `$43C3–$43D6`, `$461A–$503A`; 14: `$41D9–$41EC`, `$4437–$4E50`; 15: `$41FD–$4210`, `$4443–$4E3F`) |
| Data | the rest of banks 13–15: sound table at `$4000`, headers, drum map, drum-hit streams, period/wave/vibrato tables, then the streams; `$FF` to the end of each bank |
| RAM | seven tracks at `$C080 + n×$100` (`$80–$B7`), globals `$C0BB–$C0DB`, shadows `$C1B7–$C1CA` |
| Channels | Sfx1 (CH1), Sfx2 (CH2), SfxN (CH4), Ch1, Ch2, Ch3, Drm (drums = sound ids of the same bank through a 13-entry map) |

`N2_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over the ROM0 ranges above and all of banks 13, 14 and 15. It assembles cleanly with `-Wall`. Bank-copy labels carry a `B13_`/`B14_`/`B15_` prefix.

```
rgbasm -Wall -o n2.o N2_SoundDriver.asm
rgblink -o n2.gb n2.o
python tools/cmp_ranges.py n2.gb "Nemesis II - The Return of the Hero (E) [!].gb" 0:0028-002C 0:0050-0053 0:00B3-00CD 0:0254-0259 0:0283-0307 0:09AE-0C6C 0:0D85-0D8D D:4000-7FFF E:4000-7FFF F:4000-7FFF
```

---

## 1. Structure

### 1.1 Banks and ids

`PlaySound` reads the header from the bank given by the id: `≥ $C0` bank 15 (index id & `$3F`), `$80–$BF` bank 14 (& `$3F`), else bank 13 (& `$7F`); every bank's table is at `$4000`, indexed from 1. The update loop does the same per track with the track's id (id 0 → bank 13), so a track always runs on the code of the bank its sound came from. A drum note plays a sound of the **same bank** through that bank's own `PlayDrumSound`, which is why each bank carries its own copy of the 13 drum hits (`$01–$0D`, `$81–$8D`, `$C1–$CD`).

The three copies are nearly identical. Differences:

| | Bank 13 | Bank 14 | Bank 15 |
|---|---|---|---|
| id mask in `PlayDrumSound` | `$7F` | `$3F` | `$3F` |
| while paused | the track playing `$5D` keeps running | nothing runs | nothing runs |
| half-rate pairs (phase 0 / 1) | Ch1, Ch2 / Ch3, Drm | same | **Drm, Ch2 / Ch3, Ch1** |
| fade attenuation on new notes | music tracks | music tracks | **all tone tracks** (older code) |

### 1.2 Track fields

Track n is at `H = $C0 + n`, `L = $80–$B7`. The fields were reshuffled:

| L | Name | Use |
|---|---|---|
| `$80` / `$81` / `$82` / `$84` | ID, PRIO, PTR, LEN | as before |
| `$85` | FLAGS | 1 autopan, 2 vibrato on, 3 vibrato negate, 4 duty step, 6 force |
| `$86` | FLAGS2 | 2 released, 3 rest, 4+5 raw stream |
| `$87` / `$88` | LOOPCNT / LOOP2CNT | |
| `$89` / `$8A` / `$8B` | VIB, TRANSP, ATTEN | |
| `$8C` / `$8E` | VIBOFS (word), VIBLOOPCNT | |
| `$8F` | FLOW | 0/1 loop open, 2 in a call, 3 mark set |
| `$90` / `$91` / `$92` | UNIT, OCTAVE, PERIOD | |
| `$94` / `$95` | raw period | |
| `$96`–`$9A` | VOL, DUTY, ENV, GATE, RELTICK | |
| `$9B` / `$9C` / `$9D` / `$9E` / `$A0` | VIBTIMER, VIBRELOAD, CH3TIMER, CH3RELOAD, LEVEL | |
| `$A1` / `$A3` / `$A5` / `$A7` | LOOPPTR, LOOP2PTR, RET, SEGNO | |
| `$A9` / `$AB` / `$AC` / `$AD` | VIBPTR, VIBIDX, VIBLOOPIDX, VIBDEPTH | |
| `$AE` / `$AF` / `$B0` | vibrato delay (units, counter, reload) | |
| `$B2`–`$B5` | duty step: duty, voice duty, counter, reload | |
| `$B6` | PAN | raw NR51 bits (as Belmont's Revenge) |

### 1.3 Globals

`wTrackIdx` `$C0BB`, `wRegBase` `$C0BC`, `wTempo`/`wTempoAcc`/`wTempoPhase`/`wTempoOn`/`wTempoSkip` `$C0BD–$C0C1`, `wNR51` `$C0C3`, `wSweepVal` `$C0C4`, `wReqId`/`wReqPrio` `$C0C5/6`, `wRegVal`/`wRegIdx` `$C0C7/8`, `wMusicHold` `$C0C9`, `wFadeReq`/`wFadeStep`/`wFadeTimer`/`wFadeLevel` `$C0CB–$C0CE`, `wReqRefused` `$C0CF`, `wHalfPhase` `$C0D0`, and a second, unused fade `$C0D3–$C0D5` that ROM0 counts but nothing reads.

---

## 2. Timing

### 2.1 Update

Every 128 Hz tick `SndUpdate` calls the track code for tracks 0–6 in turn (bank by id), then counts the unused second fade and, unless paused, toggles `wHalfPhase` (0, 1, 0, …). In the track code (`TrackEntry`):

- **SFX tracks** (0–2) run every tick: 128 Hz.
- **Music tracks** (3–6) first pass the tempo logic, then only one pair runs per tick (§1.1), so each music track runs at **64 Hz**. The running pair also calls `FadeStep` first.

### 2.2 Tempo

Every music-track call (four per tick, whether the track plays or not) advances `wTempoPhase`; on every fourth one `wTempoAcc += wTempo`, and a carry skips the next four music-track calls (the accumulator is then reloaded with `wTempo`, not left as the remainder). Four consecutive calls can fall across two ticks, so a skip can cost one pair a tick while the other pair loses its skipped calls on a tick where it wasn't running anyway. `$EE` sets both `wTempo` and `wTempoAcc`; `StartCh2` clears the tempo state. Tempos in the data: bank 14 `$08`, `$10`, `$16`, `$20`; bank 15 `$00`, `$0C`, `$10`, `$20`, `$24`, `$30`.

### 2.3 Music fade

The game sets `wFadeReq` = 1. `FadeStep` (two calls per tick) makes a step every `$70` calls (56 ticks, 0.44 s): `wFadeLevel` + 1 (new notes that much quieter, CH3 half), and at step 5 the drum track stops, at 7 Ch3 (NR32 = NR30 = 0), at 9 Ch1 and Ch2 (NRx2 = 8 and a retrigger if their SFX track is idle), and the fade ends (3.9 s). Nothing is queued afterwards. `StartCh2` (any new song) clears `wFadeReq`.

### 2.4 Requests

`PlaySound`: 0 → `StopAll`; `$96` → `StopAll`, then play it; `$56` is ignored while it plays on Sfx1. The mask groups and the stale `wReqRefused` flag work as in Belmont's Revenge. NR10 = 8 for Sfx1 and for Ch1 when Sfx1 is idle. A **refused track keeps the stream pointer**: the next track of the same request is started with the refused track's stream (§5.1). Every track that is offered a stream, refused or not, gets `TRK_PAN = $FF`. A stream whose first byte is `$E1` makes the track a raw stream.

### 2.5 Pause

The game's pause code sets `wPauseFlags` bit 0, calls `SndPause` (NRx2 = 0) and plays `$5D` (a raw stream on Sfx1). While paused only bank 13's copy runs, and only for the track playing `$5D`; `wHalfPhase` stops. `SndUnpause` copies the shadows back for each channel with an active track and then sets NR10 = 0.

---

## 3. Data format

| Byte | Meaning |
|---|---|
| `$00–$DF` | note: hi = pitch (0 = rest), lo × unit = length, **lo = 0: (unit & 15) × 16**. Noise SFX: NR43 = byte, NR44 = `$80`, length = unit. Drum track: plays `DrumMap[hi − 1]` |
| `$E0` | `VOICE unit, vol\|duty<<4, env\|gate<<4` (noise SFX: `unit, vol<<4\|env`, written to NR42 + trigger; drums: unit only) |
| `$E1–$E6` | octave (a stream starting with `$E1` is a raw stream instead, §3.2) |
| `$E7 x` / `$E8 x` / `$E9 x` | unit / env + gate / NR10 |
| `$EA xy` | 0 transpose up, 1 transpose down, **2 no-op**, 3 duty (CH3: wave), 4 autopan on/off (only the flag bit now) |
| `$EB n xy` | **vibrato** table n & 15, delay (x + 1) × unit ticks (x = 0: none), depth y; `$EB n` with n & 15 = 0 turns it off (two bytes). The data often has junk in the high nibble of n (`$87`, `$88`, …) |
| `$EC x` | no-op |
| `$ED xy` | duty step: notes start with duty y, the voice duty is back after x ticks; `ED 0y` off |
| `$EE x` | tempo |
| `$EF x` | PAN (raw NR51 bits); on the drum track it skips one byte too many (not in the data) |
| `$F0–$FA` | attenuation |
| `$FB` / `$FC` | loop markers, two levels: the first one met marks the start, the next one is `FB n` / `FC n`, loop n times |
| `$FD addr` / `$FD` | call (one return slot) / return |
| `$FE` / `$FE` | the first marks, the next one jumps back to the mark, forever |
| `$FF` | end |

The asm uses `LOOP_START`/`LOOP_END n`, `LOOP2_START`/`LOOP2_END n`, `SND_CALL`/`SND_RET`, `SND_SEGNO`/`SND_LOOP` for these, as the reader takes them.

### 3.1 Vibrato

Steps are **one byte**: delay (ticks) << 4, negate flag (bit 3, set or cleared by each step), offset 0–7, multiplied by the depth. `$FB` loop point, `$FE n` repeat, `$FF` hold. After the `$EB` delay counter has run out, `VibratoTick` waits the step's delay and then takes the next step.

### 3.2 Raw streams

A track whose stream starts with `$E1` reads: `$E1 unit duty sweep` (header: unit, duty → NRx1 or wave, NR10), then **frames** of two bytes, `vol<<4 | period>>8`, `period & $FF` (NRx2 with no envelope, NRx3/NRx4, trigger), one unit each, `$00` = rest. The flow commands, `$E9`, `$EA`, `$EF` work as usual and `$EB x` sets the unit. A header is read again whenever a pass starts on `$E1`. Raw streams have no release or vibrato. Used by `$27` and the pause jingle `$5D`.

### 3.3 Tables (per bank)

| | Bank 13 | Bank 14 | Bank 15 |
|---|---|---|---|
| `SoundTable` | `$4000`, 93 | `$4000`, 22 | `$4000`, 25 |
| `DrumMap` (13) | `$4270` | `$4086` | `$40AA` |
| `PeriodTable` (85, as Belmont's Revenge) | `$43D7` | `$41ED` | `$4211` |
| `WaveTable` (pointers / waves) | `$4481`, 12 / 14 | `$4297`, 14 / 14 | `$42BB`, 14 / 14 (one starts at `$42F8`, off the 16-byte grid) |
| `VibratoTable` | `$4579`, 15 | `$4393`, 15 | `$43B8`, 16 |
| `RegBaseTable` | `$4F88` | `$4D9E` | `$4D8D` |

---

## 4. Sounds

Lengths: SFX in 128 Hz ticks, music in track ticks (64 Hz, minus tempo skips). "a/b" = total / loop start.

| Ids | Prio | Tracks | Length |
|---|---|---|---|
| `$01–$0D`, `$81–$8D`, `$C1–$CD` | `$02` | SfxN, some with Sfx1 | 2–65 (drum hits, same in all banks) |
| `$0E–$5C` | `$2F–$3F` | Sfx1, SfxN, Sfx2 in various mixes | 6–768 mostly; `$2C` and `$2E` loop |
| `$27` | `$31` | Sfx1 (raw) | 37 |
| `$32` | `$31` | SfxN + Ch3 | 492 / 147 |
| `$4A`–`$4C`, `$51` | `$32` | SfxN + Ch1 + Ch2 (jingles; `$4A–$4C` share streams) | 1654 / 1054 / 1038; 96 / 488 / 456 |
| `$16` | `$30` | Sfx1–SfxN, all empty | 0 (cuts SFX of lower or equal priority) |
| `$5D` | `$80` | Sfx1 (raw) | 80 (pause jingle) |
| `$8E–$96` | `$40` | Ch1–Ch3 + Drm | looping, except `$95` (≈5700); `$96` stops everything first |
| `$CE–$D9` | `$40` | Ch1–Ch3 + Drm | looping, except `$CF` (273) and `$D1` (1680) |

The full per-id list (priority, mask, stream addresses) is in the asm; `tools/kdata3.py` prints the lengths.

---

## 5. Quirks and bugs

1. **A refused track passes its stream on.** `StartTrack` restores DE on refusal, so the next track in the mask starts with the refused track's pointer. Seen in the verification: `$5C` (priority `$3F`) still holds Sfx2 when `$12` (priority `$30`, Sfx1/Sfx2/SfxN) arrives just after `$5C`'s Sfx1 has ended: Sfx1 starts, Sfx2 is refused, and **SfxN starts `$12`'s Sfx2 tone stream on the noise channel**.
2. **Refused tracks get `TRK_PAN = $FF`** too, which changes the running sound's panning at its next `PAN`, autopan or SFX restore.
3. **Mis-nested loops in the data**: Ch3 of `$D7` and Drm of `$D6` jump back with `$FE` from inside an open `$FC` loop, so the next pass reads that `$FC` as a loop *end* with the following byte (`$FB`, 251 / `$FD`, 253) as the count. The track then repeats a section many times; Ch3 of `$D7` only comes back to its starting state after about 5.3 million track ticks. The two bytes are marked in the asm.
4. **The stale refusal flag** aborts the next request after a refused last track (as Belmont's Revenge).
5. **Tempo skips can split between the two music pairs** (§2.2), so the pairs can drift by a tick for a while.
6. **The vibrato `$FE n` exit advances the index by one only** (two bytes are skipped), so the step after an exited repeat is taken twice.
7. **`$F0–$FA` on the noise SFX track** ends the command reading without saving the pointer, which would hang the track (not in the data).
8. **In a raw stream, `$E7`, `$E8`, `$EC`, `$ED` and `$EE`** go to a handler that doesn't pop HL: it would write track fields into ROM (the MBC) and return into RAM. Not in the data.
9. **The CH3 decay sets NR32 bit 4** (the carry of `cp 4` goes into `rla`) and counts the attenuation twice; **`StopAll` sets wNR51 = `$FF` without writing NR51**; **`PAN` on the drum track skips an extra byte** (as before).
10. **Bank 15 fades the SFX tracks** too (older `NoteVolume`), banks 13/14 don't.
11. **Dead code/data:** `StartMusicFade`, the second fade (`$C0D3–$C0D5`), `wMusicHold`, `wSweepVal` (write-only), the bank copies of `StopAll` (only reachable with a drum map entry of 0), unreachable bytes in each copy (a stray `ret`, a 5-byte tempo test, an 11-byte duty restore for the duty step; marked in the asm), two unreferenced waves in bank 13, six unreferenced drum streams in each bank (`$4310`/`$4126`/`$414A`, noise + raw pairs), extra `$FF` bytes after ends and jumps, and a leftover `03 FF` after a `$FE` jump at bank 13 `$6074`.

---

## 6. Verification

- **Byte-exact rebuild** of the ROM0 ranges and banks 13–15.
- **Rate:** 7 track calls per tick at 128 Hz (PyBoy: ≈ 896 calls per 60 frames).
- **Model vs emulator** (`verify/vmodel3.py`, `tools/kmodel3.py`: a transliteration over a RAM image; all seven tracks `$80–$B7` byte for byte, shadows, all globals `$C0BB–$C0DB`, NR51, wave RAM, triggers per tick; sounds injected through `PlaySoundFar` from the timer ISR; the game's own requests dropped):
  - each of the 140 ids alone for 9000 ticks (70 s): **0 mismatches** (`verify/run_all_n2.sh`);
  - three mixed scenarios of 9000–12000 ticks (`verify/run_combo_n2.sh`): bank-14 and bank-15 songs with SFX from bank 13 (blocking and restores, drum hits against noise SFX), the refused-track pointer bug, pause with `$5D`, music fades in both banks, `$96`, `$56` not restarted, the jingles that use Ch1/Ch2/Ch3, raw streams over music, the mis-nested loops: **0 mismatches**.
- **Not verified:** `SndUnpause` and the game's own fade start were only read (the tests poke `wPauseFlags` and `wFadeReq`). Nothing was checked on hardware or against audio output.

## Files (in `GBAudioLab\Kon`)

- `N2_SoundDriver.asm`: labelled, commented RGBDS source, byte-exact
- `tools/kdata3.py` (third-generation data decoder), `tools/gen_asm3.py` (multi-bank generator), `tools/cfg_n2.py`, `tools/kmodel3.py`, `verify/vmodel3.py`, `verify/run_all_n2.sh`, `verify/run_combo_n2.sh`, logs

Regenerate: `python tools/gen_asm3.py n2 N2_SoundDriver.asm`.
