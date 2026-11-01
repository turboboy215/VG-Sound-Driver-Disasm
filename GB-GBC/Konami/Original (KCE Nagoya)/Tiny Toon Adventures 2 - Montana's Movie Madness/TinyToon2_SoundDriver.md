# Tiny Toon Adventures 2: Montana's Movie Madness (GB): sound driver

ROM: `Tiny Toon Adventures 2 - Montana's Movie Madness (U) [!].gb` (DMG, MBC1, 128 KB, internal title `TINY TOON 2 MMM`). Konami, 1993.

Part of the Konami family, see `Konami_SoundEngine_Family.md`. This is the **fourth generation, Goemon branch**: TMNT II's track code as Ganbare Goemon extended it (priority-then-id track header, a descriptor byte per track, register addresses kept in each track, volumes compared with the register read-back, paired `$FB`/`$FC` loop markers, `$FD` call/return, `$FE` mark/jump, `$FA` jump, Goemon's `$F9 n addr` counted jump, working `$ED` duty step and pitch 13), rebuilt for a different game:

- it runs in **one bank (7) on VBlank**, all seven tracks every update (no 256 Hz timer, no music slots, no `FarRead`); Goemon's envelopes, raw frames and slides are gone;
- the **tone SFX tracks pack two notes per byte** (high nibble, then low nibble, one unit each; a low nibble `$E` changes the unit, `$F` escapes to a command);
- the **noise SFX track has volume bytes** (`$C0–$DF`) next to its NR43 notes;
- new commands: **semitone vibrato tables** (`$EB n | $80`), **CH3 wave alternation** (`$EC xy`, a different wave on every note), a **release volume** (`$EA 9x`), pan commands that also set the attenuation, autopan with two modes, the **octave in the voice byte**;
- the **fade-out turns the master volume NR50 down** (the old note-volume fade is still there but its level never moves).

| | |
|---|---|
| API | ROM0 `$03F0` `PlaySoundFar` (A = id, 0 = stop all; 163 call/jump sites) → bank 7 `$4ABA` `PlaySound` (id in `wReqId` `$C0C8`); `$0431` `SndInit` |
| Game inputs | `wPauseFlags` `$DD6C` bit 0 (the driver acts on its edges), `wFadeRate` `$C0CC` (written by the game in 15 places) |
| Tick | **VBlank**: the handler calls `SndUpdateFar` `$03DC` → bank 7 `$4BA6` `SndUpdate`, skipped while `hSndBusy` `$FF86` bit 0 is set |
| Driver code | ROM0 `$0388–$038D`, `$03DC–$046C`; bank 7 `$4ABA–$56A9` (3.1 KB, jump tables at `$513D` and `$5231`) |
| Data | bank 7 `$43F9–$4AB9` (tables, headers, drum hits) and `$56AA–$7F54` (streams); `$4000–$43F8` is other game data |
| RAM | seven tracks at `$C080 + n×$100` (`$80–$C1`), globals `$C0C3–$C0CE` |
| Channels | Sfx1 (CH1), **Sfx2 (CH3)**, SfxN (CH4), Ch1, Ch2, Ch3, Drm (no channel) |
| Counts | 112 ids `$01–$70`: 7 drum hits, SFX `$07–$57`, 22 songs `$59–$70` |

`TT2_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over ROM0 `$0388–$038D`, `$03DC–$046C` and bank 7 `$43F9–$7FFF`. It assembles cleanly with `-Wall`.

```
rgbasm -Wall -o tt2.o TT2_SoundDriver.asm
rgblink -o tt2.gb tt2.o
python tools/cmp_ranges.py tt2.gb "Tiny Toon Adventures 2 - Montana's Movie Madness (U) [!].gb" 0:0388-038D 0:03DC-046C 7:43F9-7FFF
```

---

## 1. Structure

### 1.1 Tracks and descriptors

| # | Page | Name | Descriptor | Registers (`$B7–$BA`) |
|---|---|---|---|---|
| 0 | `$C080` | Sfx1 | `$40` | NR11–NR14 |
| 1 | `$C180` | Sfx2 | `$52` | NR31–NR34 |
| 2 | `$C280` | SfxN | `$63` | NR41–NR44 |
| 3 | `$C380` | Ch1 | `$00` | NR11–NR14 |
| 4 | `$C480` | Ch2 | `$11` | NR21–NR24 |
| 5 | `$C580` | Ch3 | `$22` | NR31–NR34 |
| 6 | `$C680` | Drm | `$34` | none (0) |

`SndInit` sets the register addresses of tracks 0–5; the drum track keeps 0, so its writes go to `$FF00`, the joypad register (as TMNT II and Goemon). The descriptor's low nibble is the channel; bit 6 marks the SFX tracks. Music Ch1 is blocked while Sfx1 plays and music Ch3 while Sfx2 plays (`WriteRegChecked`); Ch2 is never blocked.

### 1.2 Track fields

TMNT II's layout from `$80` to `$88`; from `$89` to `$AC` every field sits one byte lower than in TMNT II (Goemon's duty-step and jump counters too), the loop/mark/return fields follow at `$AD–$B6`, and the register addresses moved from `$C2–$C5` to `$B7–$BA`.

| L | Name | Use |
|---|---|---|
| `$80` / `$81` / `$82` / `$84` | PRIO, ID, PTR, LEN | |
| `$85` | FLAGS | 0 rest, 2 retrigger a long note, 4 tempo skip, 5 reload the duty/wave (bit 1 is cleared, never set) |
| `$86` | PANFLAGS | 0 autopan, 1 autopan side, 2 vibrato running, **4 semitone vibrato, 5 wave alternation, 6 wave A loaded, 7 autopan with both sides** |
| `$87` | FLOW | 0/1 loops open, 2 in a call, 3 mark set, 4/5 vibrato loop/mark |
| `$88` | VIB | vibrato number (bit 7: semitone table) |
| `$89` / `$8B` / `$8C` | DETUNE (word), ATTEN, TRANSP (semitones × 2) | |
| `$8D` | JUMPCNT | `$F9` pass counter |
| `$8E` / `$8F` / `$90` | duty step: ticks, counter, start duty | |
| `$91` / `$92` | UNIT, OCTAVE (× 24, from `OctaveCodes`) | |
| `$93` / `$95` | PERIOD, last written period | |
| `$97` / `$98` | VOL (`<< 4`), last NRx2 | |
| `$99` / `$9A` | DUTY (`<< 4`; CH3: wave), last NRx1 / wave | |
| `$9B` / `$9C` / `$9D` / `$9E` | GATE, RELTICK, ENV, CH3 decay counter | |
| `$9F` | PAN | this track's NR51 bits |
| `$A0–$AC` | vibrato pointer, cursor, timer, delay, delay counter, depth, loop and mark | |
| `$AD–$B6` | loop 1, loop 2, mark, return | |
| `$B7–$BA` | register addresses NRx1–NRx4 | |
| `$BB` / `$BE` | last pitch × 2 (pitch 13), last period index (semitone vibrato) | |
| `$BC` | FLAGS3 | **0 low nibble next (Sfx1/Sfx2), 2 noise retrigger pending**, 5 octave 6 (never read) |
| `$BD` | RELVOL | **release volume** (`$EA 9x`) |
| `$BF` | PANATTEN | attenuation of the `AUTOPAN_BOTH` side notes |
| `$C0` / `$C1` | WAVEA / WAVEB | **wave alternation** |

### 1.3 Globals

`wTrackDesc` `$C0C3`, `$C0C4` and `$C0CE` (cleared, never read), `wTempo`/`wTempoAcc` `$C0C5/6`, `wReqPrio`/`wReqId` `$C0C7/8`, `wPauseLast` `$C0C9`, `wFadeTimer`/`wFadeLevel`/`wFadeRate` `$C0CA–$C0CC`, `wWaveId` `$C0CD` (the wave in CH3 RAM).

---

## 2. Timing

### 2.1 Update

Once per VBlank: pause edges (§2.5); unless paused, `FadeTick`, `TempoTick` and the music tracks Ch1, Ch2, Ch3, Drm; then SfxN, Sfx2, Sfx1 (also while paused). Everything runs at 59.7 Hz.

### 2.2 Tempo

Every update `wTempoAcc += wTempo` (when the tempo isn't 0); the carry sets the skip flag of all four music tracks, which then skip that update (else it is cleared). `$EE` sets the tempo and clears the accumulator. Tempos in the data: `$03`, `$08`, `$10`, `$19`, `$20`, `$2A`, `$30`, `$40`, `$70`, `$80`.

### 2.3 Fade-out

The game writes `wFadeRate`. Every `wFadeRate` updates the **master volume NR50** goes down by `$11` (written with the Vin bits, `| $88`); when it reaches level 3 (`$33`) the rate is doubled with `rlca`, and at 0 `wFadeTimer`/`wFadeRate` are cleared and `StopAll` runs. A new song and every **noise SFX start cancel the fade** (`wFadeRate` = 0, NR50 = `$77`). The note-on code also has a TMNT II-style volume fade with `wFadeLevel`, but nothing ever changes `wFadeLevel`, so it subtracts (CH3: adds) 0.

### 2.4 Requests

`PlaySound`: 0 → `StopAll` (priorities and ids of all tracks cleared, NRx2 = 8 on CH1, CH2, CH4, NR30 = NR32 = 8, triggers on CH1, CH2, CH4, NR51 = `$FF`). Otherwise the header comes from `SoundTable` (`$43F9 + 2 × id`): priority, mask, pointers. **If any SFX track of the mask holds a higher priority, the mask is cleared and nothing starts** (the music in that request neither). The SFX tracks are started without further tests; SfxN also ORs `$88` into NR51 and cancels a fade. Music needs the Ch1 bit and a priority ≥ Ch1's: it resets tempo and fade, writes NR10 = 8 and NR50 = `$77` and starts Ch1–Ch3/Drm. A started track gets LEN = 1, `$85–$8F` = 0, FLAGS3 = RELVOL = 0, `wWaveId` = 0 and NRx2 = 0 (the drum track: `$FF00` = 0); Sfx1 also NR10 = 8.

A drum note starts the drum hit whose id is the note's high nibble (`$01–$06`, `$0A`, all SfxN at priority `$20`), each SFX track with its own priority test, without register writes and without clearing `$88–$8F` or FLAGS3.

`PlaySoundFar` drops ids `$01–$55` except `$1C` while `hGameState` = 7 and `wGameMode` = `$0D`.

### 2.5 Pause

`wPauseFlags` bit 0 is compared with `wPauseLast`. Pausing stops SfxN and mutes CH4 and CH2. Unpausing stops Sfx1 and Sfx2, writes NR10 = 8, mutes CH1 (NR12 = 8 + trigger), sets NR32 = 0, gives CH1 and CH3 back to the music (NR51 bits and period, no trigger) and marks Ch1–Ch3 for a retrigger of a long note (Ch1 and Ch3 also for a duty/wave reload). While paused no music track runs, but the SFX tracks do.

---

## 3. Data format

| Byte | Meaning |
|---|---|
| `$00–$DF` (music) | note: hi = pitch (0 = rest; **13 = the previous pitch one octave up**), lo × unit (lo 0: (unit & 15) × 16). Drum track: drum hit hi |
| `$00–$DF` (Sfx1, Sfx2) | **two notes**, high nibble then low nibble, one unit each (0 = rest). A low nibble `$E`: the next byte is the new unit; `$F`: the next byte is a command. Before any voice only the low nibble of a byte plays |
| `$00–$BF` (SfxN) | NR43 = byte, NR44 = 0 (no retrigger unless marked), length = unit |
| `$C0` / `$C1–$CF` (SfxN) | mark a retrigger / set the volume nibble and mark (no time) |
| `$D0–$DF` (SfxN) | set the volume nibble and retrigger now, length = unit (`$D0`: NR42 = 8) |
| `$E0 u v g` | voice: unit = u & `$1F`, octave = `OctaveCodes[u >> 5]`, duty/wave = v >> 4, vol = v & 15, gate = g >> 4, env = g & 15; autopan off, attenuation 0, both sides. SfxN: `$E0 u v`, unit = u & `$7F`, NR42 = swap(v) at the next noise note |
| `$E1–$E6` | octave |
| `$E7 x` / `$E8 xy` / `$E9 x` | unit / gate x, env y / NR10 = x (at once, never blocked) |
| `$EA xy` | 0 duty (CH3: wave; ends a wave alternation), 1/2/3 pan both / high nibble / low nibble + attenuation y, 4 autopan (alternating sides), 5 autopan (low side at attenuation y, both sides at 0), 7 transpose up y, 8 down y, 9 release volume y, 6 and A–C no-ops |
| `$EB n xy` | vibrato table n, delay x × unit, depth y; `$EB n\|$80` semitone table n (no delay byte); `$EB 00` off |
| `$EC xy` | CH3 wave alternation: notes load wave x, y, x, … (`$EC 00` off: reloads the voice's wave) |
| `$ED xy` | duty step: notes start with duty x, the voice duty comes back after y ticks (y = 0: off, the duty is rewritten) |
| `$EE x` / `$EF x` | tempo / detune (signed) |
| `$F0–$F8` | attenuation (CH3: cpl(rlc(y << 4)), so it adds y level steps + 1) |
| `$F9 n addr` | jump on the n-th pass (one counter per track) |
| `$FA addr` | jump |
| `$FB` / `$FB n`, `$FC` / `$FC n` | loop markers: the first met marks, the next one loops n times |
| `$FD addr` / `$FD` | call / return |
| `$FE` | mark; the next one jumps back to the mark |
| `$FF` | end |

Note-on: period from `PeriodTable − 26 + 2 × pitch + TRK_OCTAVE + TRK_TRANSP`, plus the detune (only when its low byte isn't 0); the release tick is length × gate / 16. NRx2 = TRK_VOL − TRK_ATTEN through `WriteVolume` (no borrow test), which writes and triggers only when NRx2 reads back differently. At the release NRx2 = RELVOL, or env | level + trigger (env 0: 8); on CH3 the level steps down every env ticks. Vibrato steps are one byte: `time << 4 | negative << 3 | offset` × depth; semitone steps `time << 4 | code` (1–12 semitones, 13 = 19, 14 = 24, 15 = 36) from the note's period index, plus the detune; `$FB`/`$FB n` loops, `$FE` mark/jump, `$FF` ends (the last period is written again).

### 3.1 Tables (bank 7)

| Addr | Name | Content |
|---|---|---|
| `$43F9` | `SoundTable` | ids `$01–$70` (entry 0 is other data); headers `$44DB–$47B8` |
| `$47B9` | `PeriodTable` | 120 periods (the code adds from `$479F`, inside the last header) |
| `$48D4` | `VibratoTable` | 13 (from `$48D2`) |
| `$4994` | `WaveTable` | 10 waves at `$49A8` (from `$4992`); the last runs 2 bytes into the next table |
| `$4A48` | `Vibrato2Table` | 8 semitone tables (from `$4A46`) |
| `$513D` | `CommandTable` | `$E7–$FF` (from `$512F`, inside the code) |
| `$51FF` | `OctaveCodes` | `$18 $30 $48 $60 $78 $90` for codes 1–6; code 0 is the byte `$4D` of the `jp` before it, code 7 the `$E1` after it |
| `$5231` | `ExtTable` | `$EA x0–xC` |

---

## 4. Sounds

Lengths in updates (59.7 Hz; music minus tempo skips).

| Ids | Prio | Tracks | Notes |
|---|---|---|---|
| `$01–$06`, `$0A` | `$20` | SfxN | drum hits, 2–50 ticks |
| `$07–$57` | `$70–$FF` | Sfx1 and/or Sfx2, SfxN | SFX, up to 196 ticks; `$28`, `$29`, `$34`, `$42`, `$4E`, `$52` loop |
| `$16`, `$1C`, `$27`, `$2B`, `$2D`, `$53`, `$56` | `$73–$F5` | all seven, the others on an empty stream (`$622C`) | SFX that stop the music |
| `$57` / `$58` | `$F4` / `$40` | the three SFX / the four music tracks, all empty | stop the SFX / the music |
| `$59–$70` | `$40` | Ch1–Ch3 + Drm | the songs; `$59`, `$5F`, `$62`, `$63`, `$64`, `$6A` end, the rest loop; `$63` starts a few bytes into `$59`'s streams |

The intro/loop lengths per track can be printed with `python tools/kdata8.py -v`.

---

## 5. Quirks and bugs

1. **The drum track writes to the joypad register**: a drum-track start writes `$FF00` = 0 and every drum rest `$FF00` = 8 and `$80` (the "trigger").
2. **The note volume can wrap**: TRK_VOL − TRK_ATTEN isn't tested for a borrow.
3. **An unchanged volume isn't retriggered** (`WriteVolume` compares with the read-back; on CH1 it writes anyway while NR10 doesn't read 8). CH3 is only retriggered by a wave load.
4. **`OctaveCodes` entry 0 is a code byte** (`$4D`): a voice with octave code 0 (20 in the data, usually followed by an `$E1–$E6`) makes the next notes read their period at an odd offset, from the bytes of two entries; one note of `$0B`'s Sfx1 does.
5. **`$EC 00` on a tone track loads a wave into CH3** (unless Sfx2 plays) and triggers through the track's own NRx4 (not in the data).
6. **The fade's note-volume part is dead** (`wFadeLevel` never changes) and the NR50 fade doubles its rate at level 3; any noise SFX ends a running fade.
7. **A refused SFX drops the whole request**, music included.
8. **Pausing mutes CH2, unpausing doesn't give it back** (Ch2 comes back at its next note); an SfxN started during the pause keeps running.
9. **Drum hits don't reset the noise track**: FLAGS3, `$88–$8F` and the last volume carry over from the previous noise sound.
10. **`$EA xD–xF` run past `ExtTable`** into the code (not in the data), and `$EA 4x` also clears the vibrato-running flag, so a vibrato stops until the next note.
11. **Unused / dead:** `$C0C4`, `$C0CE`, FLAGS bit 1, FLAGS3 bit 5, `DeadSavePtr` (`$55C3`), the `$E` low nibble and the byte read before a voice in the SFX format, `$C0`, `$EA 6x/Ax/Cx`, two orphan Sfx1 streams (`$5868`, `$5D2A`, decoded in the asm), extra `$FF`/`$FE` bytes after three streams.

---

## 6. Verification

- **Byte-exact rebuild** of the ranges above.
- **Rate:** one update per VBlank (6050 updates in 6120 frames in PyBoy).
- **Model vs emulator** (`verify/vmodel8.py`, `tools/kmodel8.py`, a transliteration over a RAM image): all seven track pages `$80–$C1` and the globals `$C0C3–$C0CE` byte for byte, and the **exact sequence of register writes** of every update (every `ld [c],a` in the driver is hooked, joypad writes included); the registers the driver reads back follow the emulator; RAM outside the driver's fields follows the emulator; the game's own requests dropped. The game clears WRAM top-down and runs `SndInit` again in its demo loop (about four times in 6000 updates); the model is seeded again from the emulator there (when the clear routine or `SndInit` runs, while the register addresses read 0, and on an update whose only differences are fields the emulator now holds as 0):
  - each of the 112 ids alone for 6000 updates (100 s): **0 mismatches** (`verify/run_all_tt2.sh`);
  - three mixed 6000-update scenarios (`verify/run_combo_tt2.sh`): songs with SFX on CH1, CH3 and CH4 (blocking, the end giving CH1/CH3 back with the long-note retrigger), pause and unpause, NR50 fades to the end and a fade cut by a noise SFX, `StopAll`, the SFX that stop the music, priority refusals, drum hits against noise SFX, the looping SFX, every song (wave alternation, autopan, semitone vibrato, counted jumps): **0 mismatches**;
  - **unused features**: a copy of the ROM (`verify/patch_tt2.py`) with an SFX stream using a byte before the voice, a `$E` low nibble, `$EA 6x/Ax/Cx`, a delayed vibrato and `$EC 00` on CH1, and a noise stream with `$C0`, `$C5`, `$C9`, `$D0`, `$D7`: **0 mismatches**.
- **Not verified:** nothing was checked on hardware or against audio output; `PlaySoundFar`'s game-state test was only read.

## Files (in `GBAudioLab\Kon`)

- `TT2_SoundDriver.asm`: labelled, commented RGBDS source, byte-exact
- `tools/kdata8.py` (data decoder), `tools/cfg_tt2.py`, shared `tools/gen_asm3.py`, `tools/kmodel8.py`, `verify/vmodel8.py`, `verify/run_all_tt2.sh`, `verify/run_combo_tt2.sh`, `verify/patch_tt2.py`, logs

Regenerate: `python tools/gen_asm3.py tt2 TT2_SoundDriver.asm`.
