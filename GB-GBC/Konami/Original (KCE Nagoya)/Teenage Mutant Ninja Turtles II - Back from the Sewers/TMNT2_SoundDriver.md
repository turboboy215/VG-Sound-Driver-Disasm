# Teenage Mutant Ninja Turtles II: Back from the Sewers (GB): sound driver

ROM: `Teenage Mutant Hero Turtles - Back from the Sewers (E) [!].gb` (DMG, MBC1, 256 KB, internal title `TMHT BACK FROM S`). Konami, 1991.

Part of the Konami family, see `Konami_SoundEngine_Family.md`. This is a **fourth generation**, a rewrite rather than a variant. It keeps Nemesis II's data ideas (paired `$FB`/`$FC` loop markers, `$FD` call/return, `$FE` mark/jump, banked sounds, one-byte vibrato steps) but the code, the track layout and the update scheme are new:

- the timer runs at **256 Hz**; each update runs the three SFX tracks and **one** music track in turn, so music runs at 64 Hz;
- the **second SFX track plays on CH3** (wave), not CH2;
- every track carries its **own register addresses** (set once at boot), and a **descriptor** byte tells the code which track/channel it is running;
- volumes are compared with what the register **reads back**: an unchanged volume is neither written nor retriggered;
- **four 1-bit PCM voice clips** (`$9A–$9D`), played with interrupts off.

| | |
|---|---|
| API (ROM0) | `$04D2` `PlaySound` (A = id, 0 = stop all), `$029A` `PlaySoundFar`, `$029D` `PlaySoundFarChecked` (the game's usual entry, 131 call sites; drops requests in one game state) |
| Game inputs | `wPauseFlags` `$C794` bit 0, `wFadeRate` `$C0D4` (written by the game at `$3CAC`) |
| Tick | **timer, 256 Hz** (TMA `$C0`, TAC 16384 Hz): `$0050` → `TimerISR` `$00A1` → `SndUpdate` `$0610`, skipped while `wSndLock` `$C78D` bit 0/1 is set |
| Banks | 14: ids `$01–$9E` (index = id): drum hits, SFX, a few jingles, PCM ids `$9A–$9D`, the PCM player and samples; 15: ids `$C1–$F3` (index = id − `$C0`): drum hits, the music, a few SFX |
| Driver code | ROM0 `$0168–$0196` and `$021A` (boot setup), `$00A1–$00BC`, `$029A–$0349`, `$04D2–$07C7` (≈ 0.9 KB); bank 14 `$4000–$48BD` (2.2 KB) + `$6990–$6A09` (PCM); bank 15 `$4000–$47D6` (2.0 KB) |
| Data | bank 14 `$48BE–$698F` (tables, 158 headers, streams), `$6A0A–$7FD2` (PCM wave and samples); bank 15 `$47D7–$7FD0` |
| RAM | seven tracks at `$C080 + n×$100` (`$80–$C5`), globals `$C0CA–$C0D9` |
| Channels | Sfx1 (CH1), **Sfx2 (CH3)**, SfxN (CH4), Ch1 (CH1), Ch2 (CH2), Ch3 (CH3), Drm (no channel) |

`TM2_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over the ROM0 ranges above and all of banks 14 and 15 (the PCM samples as `db`). It assembles cleanly with `-Wall`. Bank labels carry a `B14_`/`B15_` prefix.

```
rgbasm -Wall -o tm2.o TM2_SoundDriver.asm
rgblink -o tm2.gb tm2.o
python tools/cmp_ranges.py tm2.gb "Teenage Mutant Hero Turtles - Back from the Sewers (E) [!].gb" 0:0050-0052 0:00A1-00BC 0:0168-0196 0:021A-0224 0:029A-0349 0:04D2-07C7 E:4000-7FFF F:4000-7FFF
```

---

## 1. Structure

### 1.1 Tracks and descriptors

| # | Page | Name | Descriptor | Registers (`$C2–$C5`) |
|---|---|---|---|---|
| 0 | `$C080` | Sfx1 | `$40` | NR11–NR14 |
| 1 | `$C180` | Sfx2 | `$52` | NR31–NR34 |
| 2 | `$C280` | SfxN | `$63` | NR41–NR44 |
| 3 | `$C380` | Ch1 | `$00` | NR11–NR14 |
| 4 | `$C480` | Ch2 | `$11` | NR21–NR24 |
| 5 | `$C580` | Ch3 | `$22` | NR31–NR34 |
| 6 | `$C680` | Drm | `$34` | none (0) |

The descriptor's low nibble is the channel (it also shifts the NR51 bits); the code tests the whole byte for the special cases. Music Ch1 is blocked while Sfx1 plays and music Ch3 while Sfx2 plays (`WriteRegChecked`); music Ch2 is never blocked. The register addresses are set by the boot code and never cleared; the drum track has none, so its register writes go to `$FF00`, the joypad register (§5.1).

### 1.2 Track fields

| L | Name | Use |
|---|---|---|
| `$80` / `$81` | PRIO / ID | priority comes first now |
| `$82` / `$84` | PTR, LEN | |
| `$85` | FLAGS | 0 rest, 1 raw frames, 2 retrigger a long note, 3 noise hold mode, 4 tempo skip, 5 reload the duty |
| `$86` | PANFLAGS | 0 autopan, 1 autopan side, 2 vibrato running |
| `$87` | FLOW | 0/1 loops open, 2 in a call, 3 mark set, 4 vibrato loop, 5 vibrato mark |
| `$88` | VIB | vibrato number |
| `$8A` | DETUNE | signed period offset (word) |
| `$8C` / `$8D` | ATTEN (`<< 4`), TRANSP (semitones × 2) | |
| `$8E` / `$8F` | duty step ticks / counter | nothing sets `$8E` (§5.6) |
| `$90` / `$91` | SWEEP (NR10 copy) / `$ED` high nibble | |
| `$92` / `$93` | UNIT, OCTAVE (× 24) | |
| `$94` / `$96` | PERIOD, last written period | |
| `$98` / `$99` | VOL (`<< 4`), last NRx2 | |
| `$9A` / `$9B` | DUTY, last NRx1 / wave | |
| `$9C` / `$9D` / `$9E` / `$9F` | GATE, RELTICK, ENV, CH3 decay counter | |
| `$A0` | PAN | this track's NR51 bits |
| `$A1–$AD` | vibrato pointer, cursor, timer, delay, depth, loop and mark | |
| `$B8–$C1` | loop 1, loop 2, mark, return | |
| `$C2–$C5` | register addresses | |

### 1.3 Globals

`wTrackDesc` `$C0CA`, `wMusicSlot` `$C0CB`, `wTempo`/`wTempoAcc` `$C0CC/D`, `wReqPrio`/`wReqId` `$C0CE/F`, `wPauseLast` `$C0D1`, `wFadeTimer`/`wFadeLevel`/`wFadeRate` `$C0D2–$C0D4`, `wWaveId` `$C0D5` (wave in CH3 RAM), `$C0D6` (cleared, never read), `wPcmPtr` `$C0D8`.

---

## 2. Timing

### 2.1 Update

Every 256 Hz tick: pause edges (§2.5); then, unless paused, **one music track**, `wMusicSlot & 3` = Ch1, Ch2, Ch3, Drm in turn (`FadeTick` and `TempoTick` run in Ch1's slot); then SfxN, Sfx2, Sfx1. A track runs in bank 15 if its id is ≥ `$C0`, else in bank 14. SFX run at 256 Hz, music tracks at 64 Hz each.

### 2.2 Tempo

Once per four updates `wTempoAcc += wTempo`; a carry sets the skip flag on all four music tracks (else clears it), so each music track skips its next tick. `$EE` sets the tempo and clears the accumulator. Tempos in the data (bank 15): `$03`, `$05`, `$08`, `$10`, `$18`, `$1C`, `$20`, `$30`, `$50`, `$58`.

### 2.3 Fade-out

The game writes `wFadeRate`. Every `wFadeRate` calls (one call per four updates) `wFadeLevel += $10`, which comes off the volume of new music notes. At `$40` the drum track stops; at `$70` Ch1, Ch2 and Ch3 stop (CH1 is muted if Sfx1 is idle, CH2 always, CH3 if Sfx2 is idle) and the fade ends. Nothing is queued.

### 2.4 Requests

`PlaySound`: 0 → `StopAll` (bank 14: priorities and ids of all tracks cleared, every channel muted, NR51 = `$FF`; tempo and fade are left as they are). `$9A–$9D` → PCM (§2.6). Otherwise the header is read from the id's bank. **If any SFX track in the mask holds a higher priority, nothing at all is started.** The SFX tracks are then started without further tests. Music needs the Ch1 bit and a priority ≥ Ch1's; it resets tempo, fade and the music slot, writes NR10 = 8, and starts Ch2/Ch3/Drm without priority tests. A started track gets LEN = 1, FLAGS…SWEEP = 0, `wWaveId` = 0 and NRx2 = 0 on its channel; Sfx1 also NR10 = 8, SfxN NR51 |= `$88`.

Drum notes start the sound of the same bank whose index is the note's high nibble (1–13), each SFX track with its own priority test; in bank 15 the track id gets `| $C0` so it runs there.

### 2.5 Pause

The game sets `wPauseFlags` bit 0; the driver reacts on the edges. Pausing stops SfxN and mutes CH4 and CH2. Unpausing stops all three SFX tracks, mutes CH1/CH4, sets NR32 = 0, gives CH1 and CH3 back to the music (NR51 bits and period, no trigger) and marks Ch1–Ch3 for a retrigger of a long note. While paused no music track runs, but the SFX tracks do.

### 2.6 PCM voices

`$9A–$9D` (in bank 14 they also have dummy headers) play a clip at `$6A1A`, `$6FFB`, `$74DC`, `$77ED` (1504, 1248, 784 and 2021 bytes). The player sets NR52/NR51/NR50, loads a fixed wave, starts CH3 at the lowest frequency with NR32 = 100%, then **with interrupts off** writes NR32 = 100% or mute for every bit (LSB first, ≈ 10.5 kHz, so the clips last 0.6–1.5 s) until a `$DD` byte. The game and the driver stop meanwhile; afterwards NR32 = 0 and `wWaveId` = 0, so the next CH3 note reloads its wave. NR51 stays `$FF`.

---

## 3. Data format

| Byte | Meaning |
|---|---|
| `$00–$DF` | note: hi = pitch (0 = rest), lo × unit (lo 0: (unit & 15) × 16). Drum track: plays sound hi of the bank. Noise SFX: NR43 = byte (no retrigger), length = unit, 0 = rest; in hold mode two bytes, volume and NR43 (retriggered if the volume changed) |
| `$E0 u …` | voice. Tone/wave: `E0 u, duty<<4\|vol, gate<<4\|env` (CH3: duty = wave). Noise SFX: `E0 u, NR42` (written + trigger). `u \| $80`: noise SFX → hold mode (two bytes); bank 14 tone/wave → raw frames, `E0 u\|$80, NRx1, NR10`; bank 15 tone → only the unit |
| raw frames | (bank 14, unused) two bytes `vol<<4 \| period>>8`, `period & $FF`; also `$E1–$E6` and `$F0–$F7` are frames in this mode |
| `$E1–$E6` | octave |
| `$E7 x` / `$E8 x` / `$E9 x` | unit / gate<<4 \| env / NR10 (written at once; bank 14 also keeps it in TRK_SWEEP) |
| `$EA xy` | 0 duty (CH3: wave), 1 pan both, 2 right, 3 left, 4/5 autopan (starting right / left), 6 autopan off + both, 7 transpose up y, 8 down y |
| `$EB n xy` | vibrato n & `$7F`, delay x × unit, depth y; `$EB 00` off |
| `$EC x` | no-op |
| `$ED x` | TRK_ED_HI = x & `$F0`, TRK_SWEEP = TRK_DUTYCNT = x & 15 (x & 15 = 0: the duty is rewritten) |
| `$EE x` / `$EF x` | tempo / detune (signed) |
| `$F0–$F7` | attenuation |
| `$F8 x`, `$F9 x` | volume = swap(x) (noise SFX: written at once unless in hold mode; else the attenuation is reset) |
| `$FA addr` | jump |
| `$FB`/`$FC`, `$FD`, `$FE`, `$FF` | loop markers, call/return, mark/jump, end (as Nemesis II) |

Note-on: period from the table at `TRK_OCTAVE + 2 × pitch + TRK_TRANSP`, plus the detune; the release tick is length × gate / 16; at the release NRx2 = env \| level and a retrigger (env 0: cut to 8). On CH3 the release steps NR32 down one level every env ticks. Vibrato steps are one byte: time << 4 \| negative << 3 \| offset, × depth, added to the period; `$FB` loop markers, `$FE` mark/jump, `$FF` ends the vibrato.

### 3.1 Tables

| | Bank 14 | Bank 15 |
|---|---|---|
| `SoundTable` | `$49C8` (entry 1 at `$49CA`), `$01–$9E` | `$4975` (entry 1 at `$4977`), `$C1–$F3` |
| `PeriodTable` | `$48BE` (85; the code adds from `$48A4`) | `$47D7` (72; from `$47BD`) |
| `WaveTable` | `$4968`, 4 waves at `$498A` (indices 1–13; 14–15 point into the sound table) | `$4867`, 15 waves at `$4887` |
| `VibratoTable` | 2 entries at `$4E71` (the code adds from `$4E6F`) | 14 entries at `$4C2D` |
| `CommandTable` | `$437F` (+ `$43BF` for raw mode) | `$4346` |

---

## 4. Sounds

Lengths: SFX in 256 Hz ticks, music in track ticks (64 Hz minus tempo skips).

| Ids | Prio | Tracks | Notes |
|---|---|---|---|
| `$01–$0D` | `$10` | SfxN (+ Sfx1) | bank 14 drum hits: **all one empty stream** (`$4E70`) |
| `$10–$98` | `$80–$E0` | Sfx1, SfxN, a few Sfx2 | SFX, 12–3972 ticks; many ids share streams |
| `$0E`, `$0F`, `$41`, `$5A`, `$64`, `$73`, `$7C`, `$99` | `$80–$E0` | jingles with music tracks (`$41`, `$64`, `$73` all seven) | |
| `$9A–$9D` | – | PCM voices | the headers are never used |
| `$9E` | `$F0` | Sfx1 + Sfx2 | ends through the `$9E` special case |
| `$C1–$CD` | `$10–$20` | SfxN (+ Sfx1) | bank 15 drum hits |
| `$CE–$F1` | `$40–$A0` | Ch1–Ch3 + Drm | the music; most loop, `$CE`, `$D1–$D8`, `$EB`, `$F0`, `$F1` end |
| `$E6` | `$F1` | Sfx1 + Sfx2 + SfxN | looping |
| `$F2`, `$F3` | `$A0` | Sfx1 + SfxN | |

---

## 5. Quirks and bugs

1. **The drum track writes to the joypad register.** Its register addresses are 0, so a drum-track start writes `$FF00` = 0, a drum rest `$FF00` = 8 and then `$80` (the "trigger"), and a voice command on it would write the duty there and set NR51 bit 4. The bank-15 music has 20 drum rests, so this happens in play.
2. **The note-on volume can wrap**: `TRK_VOL − TRK_ATTEN − wFadeLevel` only tests the borrow of the second subtraction, so an attenuation larger than the volume gives a loud note.
3. **An unchanged volume isn't retriggered**: `WriteVolume` compares with what NRx2 reads back and skips both the write and the trigger when they match (on CH1 only while TRK_SWEEP is 8). CH3 is only retriggered when a wave is loaded.
4. **Bank 14's drum hits are empty**, so drum notes in bank-14 jingles only cut CH4 SFX of lower priority.
5. **Song `$41` reads echo RAM**: it asks for vibrato `$8A`, but bank 14 has only two; entry 10 is data (`$E0FE`), so the vibrato steps come from WRAM `$C0FE…` (368 such reads in a run).
6. **The duty step is dead**: nothing sets TRK_DUTYTICKS. `$ED` writes TRK_SWEEP instead, which bank 14 would write to NR10 at every note-on (bank 14 data doesn't use `$ED`).
7. **Bank 15 `PanRight` stores `$0B` in TRK_PAN** instead of the track's bit, so a later restore after an SFX sets NR51 bits `$0B`.
8. **Pausing mutes CH2, unpausing doesn't give it back** (Ch2 comes back at its next note).
9. **A refused SFX drops the whole request**, including tracks that were free.
10. **Mis-nested loop** in Ch3 of `$DA`/`$DB` (`15:$577F` read both as a loop start and an end; the asm marks it): the track only returns to its starting state after ≈ 360,000 ticks.
11. **PCM blocks everything** for up to 1.5 s and leaves NR51 = `$FF`.
12. **Unused:** raw frames (bank 14), the bank-15 `E0 u|$80` form, `$C0D6`, `PlaySoundFar`'s second entry check, entry 0 of every table (garbage words), CH3 wave pointers 14–15, the dummy headers of `$9A–$9D`.

---

## 6. Verification

- **Byte-exact rebuild** of the ROM0 ranges and banks 14–15.
- **Rate:** 257 updates per 60 frames (256 Hz).
- **Model vs emulator** (`verify/vmodel4.py`, `tools/kmodel4.py`, a transliteration over a RAM image): all seven track pages `$80–$C5` and the globals `$C0CA–$C0D9` byte for byte, and the **exact sequence of register writes** of every update (every `ld [c],a`/`ldh [n],a` in the driver is hooked, joypad writes included); register reads use the hardware read masks; RAM outside the driver's fields follows the emulator; the game's own requests dropped:
  - each of the 209 ids alone (bank 14 `$01–$9E` including the four PCM voices, bank 15 `$C1–$F3`) for 8000 updates (31 s): **0 mismatches** (`verify/run_all_tm2.sh`);
  - three mixed 10000-update scenarios (`verify/run_combo_tm2.sh`): a bank-15 song with SFX on CH1, CH3 and CH4 (blocking, restore, long-note retrigger), pause and unpause, a fade to the end, all four PCM voices (one over a song), `StopAll`, the jingles of bank 14 (including the echo-RAM vibrato), the `$9E` end, looping SFX, priority refusals, tempo and autopan songs: **0 mismatches**.
  - **raw frames**: a copy of the ROM with the voice of `$10`, `$1E` and `$41`'s Ch1 switched to raw mode (unit bit 7), so the rest of those streams is read as frames: **0 mismatches**.
- **Not verified:** the bank-15 `E0 u|$80` form (no data uses it); `PlaySoundFarChecked`'s game-state test was only read. Nothing was checked on hardware or against audio output.

## Files (in `GBAudioLab\Kon`)

- `TM2_SoundDriver.asm`: labelled, commented RGBDS source, byte-exact
- `tools/kdata4.py` (data decoder), `tools/cfg_tm2.py`, shared `tools/gen_asm3.py`, `tools/kmodel4.py`, `verify/vmodel4.py`, `verify/run_all_tm2.sh`, `verify/run_combo_tm2.sh`, logs

Regenerate: `python tools/gen_asm3.py tm2 TM2_SoundDriver.asm`.
