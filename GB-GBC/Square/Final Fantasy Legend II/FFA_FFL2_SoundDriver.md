# Final Fantasy Adventure & Final Fantasy Legend II (GB): sound driver

ROMs: `Final Fantasy Adventure (U) [!].gb` (internal title `SEIKEN DENSETSU`, MBC2, 256 KB) and `Final Fantasy Legend II (U) [!].gb` (`SAGA2`, MBC1 + RAM, 256 KB). Square, 1991 / 1990.

These are the middle generation of Square's GB driver. **Apart from syntax, the two games have the same code instruction for instruction**, with a handful of exceptions (§6). FFL1 (§7) uses an older, unrelated design, and FFL3 is a rework of this one.

| | FFA | FFL2 |
|---|---|---|
| Bank / range | `$0F` `$4000–$7EB3` (rest of the bank is `$00`) | `$0E` `$4000–$7FE8` (rest `$00`) |
| Code + driver tables | `$4000–$4A11` | `$4000–$49F4` |
| Song table | `$4A12`, **30 songs** | `$49F5`, **19 songs** |
| Music streams | `$4AC9–$7A4E` | `$4A68–$79FD` |
| Effect tables, waves | `$7A4F–$7B3B` (6 waves + 1 unused) | `$79FE–$7AC4` (5 waves) |
| SFX tables | `$7B3C` / `$7B86`, **37 SFX** | `$7AC5` / `$7B37`, **57 SFX** |
| RAM | `$C100–$C1CA`, HRAM `$FF90–$FF9D` | `$CB00–$CBC7`, HRAM `$FFB0–$FFBD` |
| Called from | `$2180`, once per frame | `$170B` (frame interrupt, with a re-entry guard at `$FF9C`), once per frame |

### Files

| File | What it is |
|---|---|
| `FFA_SoundDriver.asm` (new) | **byte-exact** RGBDS rebuild of FFA bank `$0F` `$4000–$7EB3`. Label and RAM names come from the FFA disassembly below. |
| `FFL2_SoundDriver.asm` (new) | **byte-exact** RGBDS rebuild of FFL2 bank `$0E` `$4000–$7FE8`, including the music and SFX data the `.s` file leaves out. Label names come from `FFL2_audio.s`; RAM names come from its `mctrl.N.*` / `hram.audio.*` symbols (`w_mctrl1_stream_ptr`, `h_bg_music` …) with their addresses, which are now known (below). |
| `FFA_bank0F_soundengine.asm` | third-party BadBoy disassembly of FFA bank `$0F` with all the data and music macros. It needs that project's `include/*.inc`. **All 14 510 bytes in its byte comments match the ROM.** |
| `FFL2_audio.s` | third-party WLA-DX source of FFL2 bank `$0E` `$4000–$49F4` (code and driver tables only). **Walked against the ROM instruction by instruction with no mismatch** (`tools/align_ffl2.py`). That recovers every symbol's address: `music_time_divider` `$CB00`, `mctrl.1` `$CB02` … `mctrl.4` `$CB4A`, `sfx_tone_stream_ptr` `$CBC4`, `hram.audio.bg_music` `$FFB0` … `sfx_noise_loop_counter` `$FFBD`. |

```
rgbasm -Wall -o snd.o FFA_SoundDriver.asm   &&  rgblink -o snd.gb snd.o
python tools/cmp_bank.py FFA_SoundDriver.asm "Final Fantasy Adventure (U) [!].gb" snd.gb
```

Regenerate: `python tools/gen_g2.py ffa <rom> FFA_bank0F_soundengine.asm .` (or `ffl2 <rom> FFL2_audio.s .`).

---

## 1. Interface

| | FFA | FFL2 |
|---|---|---|
| Update (once per frame) | `runSoundEngine` `$4000` (`jr` → `$4006`) | `xe_update_audio` |
| Init / stop | `initSoundEngine` `$4003` (`jr` → `$4048`) | `xe_reset_audio` |
| Song request | `hCurrentMusic` `$FF90` (1-based, 0 = stop); the driver tracks `hPlayingMusic` `$FF93` | `bg_music` `$FFB0` / `current_bg_music` `$FFB3` |
| SFX request | `hSFX` `$FF92` (1-based) | `sfx` `$FFB2` |
| Special song | `hMusicSpecialSongRequest` `$FF91`, flag `$FF99` | `fg_music` `$FFB1`, `fg_music_flag` `$FFB9` |

**Frame order:**

1. Special-song start, check or resume.
2. Otherwise, if no CH1 SFX is running and the request differs, start the song (0 → full reset).
3. Start a requested SFX.
4. `musicPlayStep` / `update_music`.
5. SFX step.

Starting a song is deferred while a CH1 SFX runs.

## 2. RAM (FFA addresses; FFL2 is the same layout from `$CB00`)

`+0` tempo accumulator (reset to `$FF`), `+1` tempo (default `$3C`), then **four `$18`-byte channel structs** in driver order **CH2 (`$C102` / `$CB02`), CH1, CH3, CH4**. FFL2's `mctrl.1` = CH2, `.2` = CH1, `.3` = CH3, `.4` = CH4. Music uses only the first three. CH4's struct is only an SFX timer plus an "ended" flag.

| Off | FFA name (CH2) | FFL2 name | Use |
|---|---|---|---|
| `$00` | `wSoundEffectDuration…` | `sound_timer` | SFX timer (meaningful for CH1 and CH4) |
| `$01` | `wMusicNoteDuration…` | `music_timer` | ticks left |
| `$02` | `wMusicInstructionPointer…` | `stream_ptr` | stream pointer |
| `$04–$08` | `wMusicVibrato…` | `pitch_fx_*` | pitch effect: timer, start pointer, current pointer |
| `$09` | `wMusicOctave…` | `octave` | octave × 24 |
| `$0A` | `wMusicNR21DutyCycle…` | `wave_duty` | duty copy |
| `$0B` | `wMusicCurrentPitch…` | `freq_low/high` | base period (2) |
| `$0D` | `wMusicLoopCounter1…` | `loop_counter` | counter A |
| `$0E` | `wMusicNR22DefaultVolume…` | `wave_volume` | default volume copy (CH3: NR32 value) |
| `$0F` | `wMusicNotePitch…` | `last_note` | last pitch nibble |
| `$10` | `wMusicStereoPan…` | `pan` | CH1 pan copy |
| `$11` | `wMusicEndedOn…` | `enable` | `$FF` = track ended |
| `$12–$16` | `wMusicVolume…` | `volume_fx_*` | volume effect: timer, start pointer, current pointer |
| `$17` | `wMusicLoopCounter2…` | `alt_loop_counter` | counter B |

HRAM: effect-channel rotor, note-timer copies, wave pointer, SFX loop counters. The special-song backup copies `$62` bytes from `+0`.

**Song start** copies `musicChannelInitData` / `audio_init_data` into each struct (`$18` bytes). That gives:

- counter A = 0;
- the default vibrato and the `$FF $F0` volume hold;
- counter B = 0 in **FFA**, but **10 in FFL2**: FFL2's init block is only 23 bytes long, so the 24th byte copied is `default_pitch_fx`'s first byte (`$0A`). No FFL2 song uses `loop_b` before `set_b`, so this is latent.

## 3. Music format

The song table has 6 bytes per song (`dw ch2, ch1, ch3`), indexed by id − 1.

| Byte | Meaning |
|---|---|
| `$00–$CF` | note: **high nibble = length index, low nibble = pitch**. `0–B` = C…B, **`C`/`D` = C/C# of the next octave**, **`E` = tie**, **`F` = rest** (period `$7FF`, no trigger) |
| `$D0–$D7` | octave = n (×24) |
| `$D8–$DF` | octave +1…+4 / −1…−4 |
| `$E0–$EB` | command (low nibble indexes a per-channel table) |
| `$F0–$FE` | the same commands again (only the low nibble is used). No song uses them |
| `$FF` | end of track |

**Lengths** (13): 96, 72, 48, **32, 36**, 24, **16, 18**, 12, 8, 6, 4, 3. The triplet values are interleaved, not sorted.

**Pitch:** 85 periods | `$8000`, index = octave×24 + pitch×2. CH1/CH2 retrigger on every note. CH3 writes NR34 & 7 (no trigger).

| Cmd | Macro | CH2 | CH1 | CH3 | Args |
|---|---|---|---|---|---|
| `$E0` | `vol_fx` / `volume` | volume effect pointer | volume effect pointer | **NR32 volume** (1 byte) | dw / db |
| `$E1` | `jump` | ✓ | ✓ | ✓ | dw |
| `$E2` | `loop_a` | `--A ≠ 0` → jump | ✓ | ✓ | dw |
| `$E3` | `set_a` | ✓ | ✓ | ✓ | db |
| `$E4` | `pitch_fx` | ✓ | ✓ | ✓ | dw |
| `$E5` | `duty` | NR21 | NR11 (not written during an SFX) | – | db |
| `$E6` | `pan` | 0–3 | mirrored | ✓ | db |
| `$E7` | `tempo` | ✓ | – | – | db |
| `$E8` | `wave` | – | – | load 16 bytes, NR30 on, NR32 = 0, NR34 = `$87` | dw |
| `$E9` | `loop_b` | `--B ≠ 0` → jump | ✓ | ✓ | dw |
| `$EA` | `set_b` | ✓ | ✓ | ✓ | db |
| `$EB` | `if_a` | `A == n` → jump | ✓ | ✓ | db, dw |
| `$EC` | `doubletime` | **FFA only**: flag (§6) | – | – | db |

"–" = undefined: **FFA hangs** (`musicOpCodeHalt`: `jp` to itself, inside the interrupt), **FFL2 ignores it** (`music_command_null_handler`: `ret`). Bytes past the end of a table (FFA CH2 `$ED+`, all other cases `$EC+`) use the first bytes of the next routine as a pointer, so they crash.

### Effects

Each frame does two things:

- **Tempo:** `acc += tempo`; on carry it runs the stream tick **twice**. Ticks per second = tempo × 59.7275 / 128.
- **Effects:** one of CH2/CH1/CH3 gets its effects per frame (19.9 Hz each). They're skipped while the channel's SFX timer is set, on rests, and when the note-timer copy is 0.

Both effect types are lists of `(ticks, value)` pairs, where ticks 0 = jump to the following `dw`:

- **Pitch** (`frequencyDeltaData`): signed period offset.
- **Volume** (`volumeEnvelopeData`): NRx2 value, rewritten with a retrigger at the base period. Ticks `$FF` = hold.

### Songs

Tempo = the first `tempo` on CH2. Intro + loop are CH2's, in ticks. "One-shot" lengths are at the starting tempo (≈ when the tempo changes).

**FFA** (30):

| # | Tempo | Intro + loop | Length | | # | Tempo | Intro + loop | Length |
|---|---|---|---|---|---|---|---|---|
| `$01` | `$41` | 0 + 1440 | 47.5 s | | `$10` | `$87` | 1056 + 2592 | 41.1 s |
| `$02` | `$4B` | 48 + 1536 | 43.9 s | | `$11` | `$6B` | one-shot 96 | 1.9 s |
| `$03` | `$39` | **no loop counter set; hangs after 256 passes** (§6) | ~2 h 3 min | | `$12` | `$6C` | one-shot 384 | 7.7 s |
| `$04` | `$3E` | 0 + 768 | 26.5 s | | `$13` | `$82` | 192 + 2496 | 41.1 s |
| `$05` | `$7C` | 192 + 384 | 6.6 s | | `$14` | `$78` | 0 + 2304 | 41.1 s |
| `$06` | `$82` | 384 + 1152 | 19.0 s | | `$15` | `$3E` | one-shot 5472 | ≈ 3:09 |
| `$07` | `$60` | 24 + 1920 | 42.9 s | | `$16` | `$73` | 0 + 2304 | 42.9 s |
| `$08` | `$5A` | 0 + 1440 | 34.3 s | | `$17` | `$3C` | 0 + 768 | 27.4 s |
| `$09` | `$91` | 0 + 768 | 11.4 s | | `$18` | `$5D` | 96 + 960 | 22.1 s |
| `$0A` | `$7F` | 0 + 768 | 13.0 s | | `$19` | `$7D` | 384 + 2304 | 39.5 s |
| `$0B` | `$3E` | 0 + 1536 | 53.1 s | | `$1A` | `$7B` | 0 + 768 | 13.4 s |
| `$0C` | `$82` | 0 + 3072 | ≈ 51 s | | `$1B` | `$3C` | 24 + 1536 | 54.9 s |
| `$0D` | `$37` | 0 + 672 | ≈ 26 s | | `$1C` | `$6F` | one-shot 138 | 2.7 s |
| `$0E` | `$5D` | 0 + 1728 | ≈ 40 s | | `$1D` | `$7D` | one-shot 288 | 4.9 s |
| `$0F` | `$85` | 0 + 2304 | 37.1 s | | `$1E` | `$4B` | 0 + 192 | 5.5 s |

**FFL2** (19):

| # | Tempo | Intro + loop | Length | | # | Tempo | Intro + loop | Length |
|---|---|---|---|---|---|---|---|---|
| `$01` | `$46` | one-shot 1152 | ≈ 35 s | | `$0B` | `$8E` | 12 + 2688 | 40.6 s |
| `$02` | `$78` | 768 + 2304 | 41.1 s | | `$0C` | `$78` | 192 + 1536 | 27.4 s |
| `$03` | `$7D` | 204 + 768 | ≈ 13 s | | `$0D` | `$46` | 0 + 1920 | ≈ 59 s |
| `$04` | `$96` | 0 + 384 | 5.5 s | | `$0E` | `$49` | 96 + 1056 | ≈ 29 s |
| `$05` | `$4B` | 384 + 1536 | 43.9 s | | `$0F` | `$42` | one-shot 6528 | ≈ 3:32 |
| `$06` | `$78` | 0 + 1728 | 30.9 s | | `$10` | `$4C` | 0 + 2304 | ≈ 65 s |
| `$07` | `$46` | 0 + 768 | 23.5 s | | `$11` | `$91` | 2112 + 2784 | 41.1 s |
| `$08` | `$55` | 0 + 1440 | 36.3 s | | `$12` | `$87` | 0 + 2112 | 33.5 s |
| `$09` | `$6B` | 0 + 1344 | 26.9 s | | `$13` | `$96` | 1920 + 2304 | 31.9 s |
| `$0A` | `$49` | 0 + 2304 | 67.6 s | | | | | |

Song roles weren't identified.

## 4. Sound effects

id − 1 indexes two pointer tables. A missing part points at a single `$00`. **Both timers are always set to 1**, so every SFX takes CH1 and CH4 for at least one frame. There's no priority and no range check.

| Byte | CH1 stream | CH4 stream |
|---|---|---|
| `$01–$EE` | frames, then NR10–NR14 (5 bytes), NR51 \|= `$11` | frames, then NR42, NR43; NR44 = `$80`, NR51 \|= `$88` |
| `$EF` dw | `--count ≠ 0` → jump | same |
| `$Fn` | count = n | same |
| `$00` | end → restore CH1 | end → mute CH4 |

The CH1 restore rewrites NR10–NR14 and the CH1 pan. NR11/NR12 come from the music's copies. NR13/NR14 are:

- **FFA:** `wSoundsMusicRestorePitchChannel1`, which only a CH1 rest writes (`$FF`/`$07`), so no trigger.
- **FFL2:** the constants `$FF`/`$87`, a retrigger at period `$7FF`.

Either way **the CH1 note that was playing is lost** until the next note, even after a noise-only SFX.

**Endless SFX in FFA:** SFX `$17` (CH4) and `$1B` (CH1 + CH4) end with `$EF` pointing back at their own `$F4` count byte. The count is reset on every pass, so they never stop on their own; the game has to replace them. Confirmed: still running after 3000–5000 frames. FFL2 has none.

## 5. Special song ("foreground music")

Start, on a request:

1. Mute.
2. Clear both SFX timers.
3. Back up `$62` bytes.
4. `musicSongPlay(request)`.
5. Set the flag.

When CH2, CH1 and CH3 have all ended, or the request is cleared, it:

1. Mutes.
2. Restores the backup.
3. Clears both flags.
4. Rewrites NR21, NR22 and NR24 = `$87` (no NR23 write, so CH2 retriggers at whatever period is left over).
5. Reloads the wave from the saved pointer.
6. Falls into the CH1 restore.

## 6. FFA vs FFL2: every code difference

| | FFA (`$0F`) | FFL2 (`$0E`) |
|---|---|---|
| `$EC` on CH2 | `musicOpCodeSetDoubletimeMode`: stores a flag | no entry (table is 12 long) |
| Second tick | `ld a,[flag] / or a / call` (the condition is never tested, so it's always 2 ticks) | plain `call / call` |
| Init | also clears the double-time flag | – |
| Init data | 24 bytes | 23 bytes (counter B starts at 10, §2) |
| Undefined commands | hang | `ret` (ignored) |
| CH1 rest | also stores `$FF/$07` in `wSoundsMusicRestorePitchChannel1` | – |
| CH1 SFX restore, NR13/NR14 | from that variable | `$FF`, `$87` |
| SFX step | one redundant `or a` | – |

So FFL2 is the cleaned-up version. FFL3 brought back FFA's hang loop together with the leftover `$FC`.

### Bugs and quirks

1. **FFA song `$03` freezes the game after about 2 hours.** None of its three channels sets counter A before its final `loop_a`, so the counter starts at 0 and the body repeats 256 times. Then CH1 (and CH3) fall off the end of their streams: CH1 runs into CH3's data at `$4D86`, where `$E8` is an undefined command on CH1, and lands in `musicOpCodeHalt` (`$4361`), an endless `jp` inside the frame interrupt. The model puts this at 196 800 ticks ≈ **123 minutes** of continuous play; CH2 would get there at 246 min.
   - **Confirmed in PyBoy** (`verify/ffa_song03_hang.py`). A full run tracked CH1's counter down on schedule: 222 at 17 min, 118 at 67 min, 14 at 117 min, so 0 at about 122 min. The run was stopped there by a time limit.
   - The script's quick mode then sets the counter to 1 and plays the last pass. The game froze with PC at `$4361` and stayed there (CH1 pointer `$4D87`, i.e. just past the `$E8`).
2. **CH1's end of track silences CH2.** On `$FF`, CH1's code writes NR23/NR24 instead of NR13/NR14, in both games. FFL3 fixed this.
3. **Dead code at note start:** `ld a,l / ld a,[vol_ptr] / ld a,h / ld a,[vol_ptr+1]`. These are loads where stores were meant. They're harmless because the effect restart copies start → current right after.
4. **CH1 `$E0`** sets only the start pointer. Harmless for the same reason.
5. **Out-of-range commands crash**, `$F0–$FE` alias `$E0–$EE`, and **SFX always claim CH1 and CH4**.
6. **FFA data leftovers:**
   - After each song's last stream there are 2 bytes `E7 14` (a `tempo $14` that's never read).
   - Before many songs' first stream there's a 6-byte copy of that song's table entry.
   - 3 bytes `FF E7 14` follow the song table.
   - There's 1 unreferenced wave.

   It all looks like converter output. FFL2 has just one unreachable byte, after its song table.

## 7. The Square GB driver family

| | FFL1 (1989) | FFL2 (1990) / FFA (1991) | FFL3 (1993) |
|---|---|---|---|
| Docs | `FFL1_SoundDriver.md` | this file | `FFL3_SoundDriver.md` |
| Bank | `$07` | `$0E` / `$0F` | `$0F` |
| Music channels | CH1, CH2, CH3 | CH2, CH1, CH3 | CH2, CH1, CH3, **CH4** |
| Code style | one routine, struct base in HRAM | per-channel copies | per-channel copies |
| Note byte | `pitch<<4 \| len` (C rest, D tie) | **`len<<4 \| pitch`** (C/D = C/C#+1, E tie, F rest) | `pitch<<4 \| len` (C tie, D rest) |
| Lengths | 15: 96 … 2 | 13, interleaved | 16: **144**, 96 … 2 |
| Tempo | ticks/second (acc ≥ 60) | acc overflow → 2 ticks | same as FFA |
| Instruments | 4 sequences (vol, pitch, duty, **pan**) selected by `$F7`, stepped per tick | volume + pitch effect pointers, stepped per frame (1/3) | same as FFA, plus an `$FE` init macro |
| Volume | env level × channel volume (`$E1–$EF`) | NRx2 values directly | same as FFA |
| Loops | one counter, 1–3, `$FC` / `$FD` | counters A/B, `if A == n` | same as FFA |
| Undefined cmd | `$F6` → `jp $0000` | FFA hang / FFL2 `ret` | hang |
| SFX loop codes | `$En` count, `$Fx` jump | `$Fn` count, `$EF` jump | same as FFA |
| SFX channel claim | always both | always both | only the parts present |
| Special song | yes | yes | removed |
| RAM | `$CE00` | FFA `$C100`, FFL2 `$CB00` | `$CB00` |

Shared throughout: the same 85-entry period table (with the trigger bit from FFL2 on), CH1 SFX frames as 5 raw NR10–NR14 bytes, CH4 SFX frames as NR42/NR43, and SFX restore through RAM copies.

## 8. Verification

- **Byte-exact rebuilds** of both banks (`tools/cmp_bank.py`), `-Wall` clean. The third-party sources were checked against the ROMs (§Files).
- **Music:** every song forced from the title screen in PyBoy (`verify/vmusic.py ffa|ffl2`). Every note the real driver reads (address and tick, all three channels) matches the model in `tools/g2.py` over 6000 ticks: FFA 30 songs / 36 455 notes, FFL2 19 songs / 28 581 notes. FFL2 matched with counter B starting at 10.
- **SFX:** all 37 / 57. Busy length per channel matches the model (loops expanded), and FFA's two endless SFX are still running at the end (`verify/vsfx.py`).
- **Rate:** exactly one call per frame in both (`verify/rate.py`).
- **FFA song `$03` hang:** confirmed, see §6.1.
- **Not verified:** song and SFX roles, the special song in either game, and hardware audio.

Files are in `GBAudioLab\FF\FFA_FFL2`: both asm files, `tools/` (`g2.py` model, `gen_g2.py`, `align_ffl2.py`, `g2stats.py`, `trace.py`, `sm83.py`, `cmp_bank.py`) and `verify/` (ROM paths from `FFA_ROM` / `FFL2_ROM`).
