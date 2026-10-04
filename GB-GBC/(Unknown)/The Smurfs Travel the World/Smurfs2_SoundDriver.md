# The Smurfs Travel the World (GB): sound driver

ROM: `Smurfs 2, The (E) (M4).gb` (MBC1, 128 KB, internal title `SMURFS2`). Developer: Virtual Studio. Publisher: Infogrames, Europe 1996 (TCRF). The ROM's own text says "INFOGRAMES … 1995". No sound credit is known.

| | |
|---|---|
| API | bank 4 jump table: `SndPlaySong` `$4000` (L = song, A = speed), `$4003` (unused, `RET`), `SndPlaySfx` `$4006` (L = SFX, A = speed), `SndInit` `$4009`, `SndUpdate` `$400C` |
| Game glue | ROM0 `$28FD–$2980`: `GamePlaySongFromHL`, `GamePlaySong` (B = song, C = speed), `GameStopMusic`, `GamePlaySfx` (B, C), `GamePlaySfxIndex` (A → 18-entry list), `GameSndUpdate`, `GameSndInit` |
| Driver code | bank 4 `$4000–$4395` (tables inside, see §3) |
| Songs / SFX / patterns | bank 4 `$4396–$60E5` |
| Tick | **main loop**, not an interrupt. All interrupt vectors are `RETI`; the game polls LY and calls `GameSndUpdate` once per frame. 59.7 ticks/s, and slowdowns slow the music. |
| RAM | `$DF00–$DFAD` |
| Songs / SFX | 13 songs, 18 SFX, 179 patterns |

`Smurfs2_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 for both ranges (0:`$28FD–$2980`, 4:`$4000–$60E5`) and assembles cleanly with `-Wall`.

```
rgbasm -o snd.o Smurfs2_SoundDriver.asm
rgblink -p 0xFF -o snd.gb snd.o
```

---

## 1. Architecture

This is a compact **order-list + pattern** driver. It shares no code or tables with the other drivers in this project: there's no `00 60 40 20` frequency-table prefix (Distinctive/Radical family) and none of the MOD structure of On the Tiles. The data looks MIDI-converted. Durations are multiples of 96 units with small "humanised" offsets (194/190, 184/202).

- **Five voices, one routine.** CH1, CH2, CH3, CH4 and one SFX voice each have a `$1B`-byte block. Every tick, `SndRunVoice` copies a block to `wWork` (`$DF00`), advances the timer and parses events. `SndStoreVoice` copies it back. Only bytes +`$00`–+`$0C` mean anything. The other 14 bytes are copied twice per voice per tick for nothing.
- **Note handler through a RAM `JP`.** `wNoteHandler` (`$DFA6`) holds `C3 xx 41`. `SndUpdate` patches the low byte to switch between `ToneNoteHandler` (`$41F6`) and `NoiseNoteHandler` (`$41C7`) per voice.
- **Tone voices don't touch the hardware.** They build an NRx1–NRx4 image in `wRegNRx1..4` (`$DFA2–$DFA5`). `SndUpdate` writes it to CH1/CH2/CH3 right after each voice, but only if NRx4 is nonzero, meaning a note started this tick. The noise handler writes NR41–NR44 directly.
- **No software envelopes, vibrato or slides.** A note sets duty/length (NRx1), a hardware envelope (NRx2 = volume | instrument bits) and the period, then triggers. Everything else is hardware decay or the length counter.
- **Fractional timer.** Each tick adds `speed − 256` to the voice's 16-bit timer. While it's negative, events are read and their waits added. Tempo is the `A` argument of `SndPlaySong`/`SndPlaySfx`: one tick consumes `256 − speed` units. The game uses `$EF–$F6` (13 units/tick at `$F3`, so a 96-unit wait ≈ 7.4 frames).
- **Relative pitch.** Every note byte carries a pitch step of −15…+15 semitones from the previous note. Order entries set the starting pitch.
- **SFX** borrow CH1 (tone) or CH4 (noise), with full priority. The music voice underneath keeps running but its output is thrown away (§5.6).

### Voice block (`$1B` bytes: CH1 `$DF1B`, CH2 `$DF36`, CH3 `$DF51`, SFX `$DF6C`, CH4 `$DF87`; work copy `$DF00`)

| Off | Name | Use |
|---|---|---|
| +00 | Timer (2) | counts up; events are read while negative |
| +02 | Stream (2) | pattern pointer |
| +04 | Order (2) | order-list pointer |
| +06 | Loop (2) | loop list, used when the order list hits `$00` |
| +08 | – | never written or read |
| +09 | Pitch | current pitch (`FreqTable` index + `$2B`) |
| +0A, +0B | – | written by commands 3/4 (init `$40`), never read |
| +0C | Instr | `ToneInstruments` index. Init: CH1/CH2 0, CH3/CH4 1, SFX 2 |
| +0D–+1A | – | copied, never used |

Globals: `$DFA2–$DFA5` register image (NRx4 = 0 means no note), `$DFA6–$DFA8` `wNoteHandler`, `$DFA9` music speed, `$DFAA` SFX speed, `$DFAB` speed save, `$DFAC` SFX mode (0 none, 1 noise, 2 tone), `$DFAD` "order list not ended" flag (`$FF`, cleared on wrap).

### `SndUpdate` order

CH1 (tone handler) → **tone SFX** (if mode 2, at the SFX speed) → write CH1 → CH2 → write CH2 → CH3 → write CH3 → CH4 (noise handler, or the tone handler when mode 1) → **noise SFX** (if mode 1). An SFX ends when its order list wraps, which sets mode 0.

---

## 2. Data format

### Songs and SFX

`SongTable` (`$5E68`): 16 bytes per song = (order list, loop list) for CH1, CH2, CH3, CH4. `SfxTable` (`$5F38`): 4 bytes per SFX = (order list, loop list). Every SFX's loop list is `SilentOrder`.

`SndPlaySfx` picks the channel from the **first order byte**: `(t >> 1) == 1` (t = 2 or 3) → noise SFX on CH4, anything else → tone SFX on CH1.

### Order list

| Bytes | Macro | Meaning |
|---|---|---|
| `00` | `ENDLIST` | continue at the loop list, clear `$DFAD` |
| `1xxxxxxx yy` | `OREST n` | rest of `((x << 8 \| yy) << 1) & $FFFF` units |
| `0ttttttt pp` | `PLAY pat, pitch` | pitch = `(t + $52) >> 1`, pattern = `((t + $52) & 1) << 8 \| pp` (9-bit) |

Songs that end (0, 4, 9, 10) and all SFX loop to `SilentOrder` (`$4398`): `PLAY 0, $49` then `ENDLIST`, with pattern 0 being a 254-unit rest. Song 12's loop lists are song 0's order lists, so song 12 runs into song 0 and then silence.

### Pattern stream

A pattern starts with a wait, then events. Each event except `$00` is followed by a wait.

**Wait:** `0nnnnnnn` = 2n units, or `1nnnnnnn hh` = `hh × 256 + 2n` units. A wait of 0 reads the next event in the same tick.

| Byte | Macro | Meaning |
|---|---|---|
| `00` | `ENDPAT` | back to the order list |
| `01 xx` | `INSTR x, w` | voice +0C = x (tone instrument) |
| `02/05/06 xx` | `CMD` | ignored |
| `03/04 xx` | `CMD` | voice +0A / +0B = x (never read) |
| `07 tt` | `TRANSP t` | tone voices: pitch += tt (signed), then a note byte follows |
| `sssss vvv` (≥ `08`) | `NOTE step, v, w` | tone: pitch += s − 16, volume v |
| `x iiii vvv` (≥ `07`) | `DRUM i, v, w` | noise: `NoiseInstruments[i]`, volume v. `$07` is drum 0 here, not an escape. |

Only command 1 appears in the data (202×, in 179 patterns). `TRANSP` appears 15×. Every pitch in every pattern and order context stays within `$2C–$5F`.

**Volume:** the NRx2 volume nibble is `2v + 1` (v = 1…7 → 3…15). On tone channels v = 0 gives nibble 0. On noise, v = 0 gives nibble 1 (§5.4). The music never uses v = 7. CH1/CH2 peak at 13.

**CH3 volume:** `SndUpdate` turns the NRx2 image into NR32 with `rrca / cpl / add $20`. Only the volume nibble matters:

| v | 0–1 | 2–3 | 4–5 | 6–7 |
|---|---|---|---|---|
| NR32 | mute | 25 % | 50 % | 100 % |

### Instruments (bank 4)

`ToneInstruments` (`$4154`, 2 bytes: NRx1, NRx2 low bits). A nonzero NRx1 length also sets the length-enable bit.

| # | NRx1 | NRx2 low | Used by |
|---|---|---|---|
| 0 | `$D8` 12.5 %, length 24 | none | CH3 (15×): short notes (NR31 = `$D8`) |
| 1 | `$80` 50 % | down, step 7 | CH1/CH2, CH3 default, one SFX |
| 2 | `$80` 50 % | down, 3 | CH1/CH2, SFX default |
| 3 | `$40` 25 % | down, 2 | CH1/CH2, CH3 once |
| 4 | `$40` 25 % | none | CH3 once |
| 5 | `$40` 25 % | down, 1 | SFX |
| 6 | `$80` 50 % | down, 2 | CH1/CH2 |
| 7 | `$80` 50 % | down, 1 | SFX |

`NoiseInstruments` (`$4161`, 3 bytes: NR41, NR42 low bits, NR43) **overlaps** tone entries 6–7. The music uses drums 1 (`00 01 00`, 40 hits in unique patterns) and 3 (`00 02 02`, 5). Drums 4–8 appear once each in SFX. Drums 0 and 2 are unused. Entry 9 onwards would read the code at `$417C`.

`FreqTable` (`$432C`): 53 periods, pitch `$2B` = G2 (`$2C6`) … `$5F` = B6 (`$7BE`). The driver indexes it as `$42D6 + 2 × pitch`, an address inside `SndInit`. Pulse and wave use the same table because the wave is a two-cycle square (`FF FF FF FF 00 00 00 00` ×2, loaded once by `SndInit`).

---

## 3. Layout (bank 4)

| Address | Content |
|---|---|
| `$4000` | jump table (5 × `JP`) |
| `$400C–$4153` | `SndUpdate`, `SndStoreVoice`, `SndRunVoice`/`ReadEvent`/`ReadWait` |
| `$4154` / `$4161` | `ToneInstruments` / `NoiseInstruments` (overlapping) |
| `$417C–$431B` | `NextOrder`, `NoiseNoteHandler`, `ToneNoteHandler`, `SndPlaySong`, `InitVoice`, `SndNop`, `SndPlaySfx`, `SndInit` |
| `$431C` | wave data (16 bytes) |
| `$432C` | `FreqTable` |
| `$4396` | pattern 0 (`SilentStream` = `$4397`, its `$00`), `SilentOrder` `$4398`, `SilentSong` `$439B` (8 × `SilentOrder`) |
| `$43AB–$5837` | patterns 1–178 |
| `$5838–$5E67` | order lists |
| `$5E68` / `$5F38` / `$5F80` | `SongTable` (13) / `SfxTable` (18) / `PatternTable` (179) |
| `$60E6–` | game data (not sound) |

All 7,504 bytes from `$4396` to `$60E5` are decoded, with no gaps or overlaps, and every pattern is used.

### Songs

Lengths are from the harness at the game's speed, up to the first order-list wrap.

| # | Speed | Used for | Caller | Length | End |
|---|---|---|---|---|---|
| 0 | `$F3` | intro story | 0:`$17C8` | 31.7 s | silence |
| 1 | `$F2` | title / options menu | 0:`$18E6` | 38.6 s | loops (the intro isn't repeated) |
| 2 | `$F3` | world map ("– AFRICA –") | 0:`$1D1A` | 15.8 s | loops |
| 3 | `$F3` | level music | level headers `$2AD3`, `$2C61`, `$2DCC` | 67.3 s | loops |
| 4 | `$F4` | jingle | 0:`$1DF4` | 4.3 s | silence |
| 5 | `$F3` | level music (Africa level 1) | `$2A2E`, `$2BA8`, `$2D0F` | 63.3 s | loops |
| 6 | `$F2` | level music | `$2B1A`, `$2C98`, `$2E03` | 79.1 s | loops |
| 7 | `$F6` | level music | `$2A9C`, `$2C26`, `$2D91` | 63.3 s | loops |
| 8 | `$F1` | level music | `$2B61`, `$2CD4`, `$2E3A` | 83.1 s | loops |
| 9 | `$EF` | jingle | 0:`$0667` | 4.6 s | silence |
| 10 | `$F3` | jingle | 0:`$06B4`, `$0AA3`, `$11BC` | 4.0 s | silence |
| 11 | `$F3` | level music | `$2A65`, `$2BDF`, `$2D4A` | 79.1 s | loops |
| 12 | `$F3` | intro variant, then song 0 | 0:`$1E3A` | 23.7 s + song 0 | silence |

Level headers (tables at 0:`$29C2` and `$29F8`) end with (song, speed). The level songs rotate in two sets of three: 5/11/7 and 3/6/8. Only 1, 2, 5 and 0 were identified on screen. The jingle roles are guesses. The level song is started only at level start (0:`$0254`), so after a non-looping jingle the level stays silent until the next level start. **Only songs 3, 5–8 and 11 use CH4 (drums).**

### SFX

| # | Channel | Speed | Frames | Reached via |
|---|---|---|---|---|
| 0 | CH1 | `$F4` | 9 | list 0 |
| 1 | CH1 | `$E0` | 7 | list 1 |
| 2 | CH1 | `$F1` | 26 | list 2 |
| 3 | CH1 | `$E2` | 17 | list 3, 0:`$0E4E` |
| 4 | CH1 | `$DE` | 23 | list 4, 0:`$08E6`, 2:`$5182`. Jump, confirmed in game. |
| 5 | CH1 | `$E6` | 30 | list 5, 0:`$0E71` |
| 6 | CH1 | `$EB` | 28 | list 6 |
| 7 | CH1 | – | 16* | **unreachable** (list 7 points at SFX 9) |
| 8 | CH1 | `$EE` | 43 | list 8, 0:`$06C8` |
| 9 | CH1 | `$E6` | 30 | lists 7 and 9 |
| 10 | CH1 | – | 4* | **unreachable** (list 10 points at SFX 15) |
| 11 | CH4 | `$E0` | 49 | list 11, 0:`$12DE`, 2:`$468B` etc. |
| 12 | CH4 | `$E0` | 25 | list 12 (2:`$4AE3`) |
| 13 | CH4 | `$E3` | 27 | list 13 |
| 14 | CH4 | `$E1` | 50 | list 14 (2:`$46B4`, `$533C`, …) |
| 15 | CH4 | `$EE`/`$DC` | 43 | lists 10 and 15, 0:`$08C2` (2:`$4A32`) |
| 16 | CH1 | `$DD` | 22 | list 16 |
| 17 | CH1 | `$EA` | 44 | list 17 (2:`$46C9`, `$5AF2`) |

"List n" is `GamePlaySfxIndex` entry n (0:`$294B`, (SFX, speed) pairs). Bank-2 object code also calls it with indexes read from data, so which list entries are actually used isn't fully known. Frames are counted until the SFX voice's order list wraps. \* = rendered at `$E0`.

---

## 4. Game interface

- **Boot** (0:`$01C4`): `GameSndInit`, then `GameStopMusic`. `SndInit` writes the RAM `JP`, NR10 = `$08`, NRx2 = `$08`, the wave, triggers all four channels, sets NR50 = `$77`, NR51 = `$FF`, NR52 = `$FF`, then starts `SilentSong` at speed 0.
- **Songs**: `GamePlaySong` (B, C) from the intro, title, map and jingle code. `GamePlaySongFromHL` at level start (skipped when music is OFF, flag `$D8E2`). `GameStopMusic` = song `$FF` (anything > 14 plays `SilentSong`) followed by one update.
- **SFX**: bank-0 code calls `GamePlaySfx` (B, C). Bank-2 code calls `GamePlaySfxIndex`, which remaps bank 2 afterwards. The other glue routines leave bank 4 mapped.
- **Pause** (0:`$2742`): toggles `$D8D8`, writes NR50 = NR51 = `$00`/`$FF` and writes the same value to `$DF02`. `$DF02` is a byte of `wWork` that's overwritten on the next voice, so that write does nothing. `SndUpdate` keeps being called, so **the music keeps playing silently during pause** and resumes further on (confirmed: 25 notes written over 200 paused frames).

---

## 5. Quirks and bugs

1. **SFX 7 and 10 are unreachable.** `GameSfxList` entry 7 is (9, `$E6`), a duplicate of entry 9, and entry 10 is (15, `$EE`). No direct call uses 7 or 10. Both look like typos in the list. SFX 7 is a 16-frame tone effect, SFX 10 a 4-frame blip.
2. **Songs 13 and 14 are accepted.** The bounds check is `cp $0E` (0–14 valid), but only 13 songs exist. Song 13 reads the first 16 bytes of `SfxTable`, so it would play SFX 0–3 on CH1–CH4 (a tone SFX list on the noise channel). The game never asks for it.
3. **Overlapping tables.** `NoiseInstruments` starts inside `ToneInstruments` (tone 6/7 = noise 0's bytes), and noise index 9–15 would read code. `FreqTable` is addressed from `$42D6`, so pitches below `$2B` would read `SndInit` code as periods. None of this is reached by the data.
4. **Noise volume 0 isn't silent.** The noise handler always computes `(2v + 1) << 4`, so v = 0 gives volume 1. The tone handler special-cases 0. Unused by the data.
5. **SFX channel is guessed from the data.** A noise SFX is recognised only by its first order byte being 2 or 3 (pitch `$2A`). The driver has no explicit flag.
6. **SFX priority is total, and there's no restore.** `SndRunVoice` clears the NRx4 image before the SFX voice runs, so **every music CH1 note is dropped while a tone SFX plays**. During a noise SFX, music CH4 runs with the tone handler and its output is never written. The music voices keep time. When the SFX ends, the channel keeps the SFX's last (decaying) note until the music's next note on that channel. Confirmed: jump SFX 4 in game; SFX 12 over song 11's drums in the harness.
7. **Music CH4 is parsed as tone during a noise SFX.** A drum byte `$07` (drum 0, volume 15) would be read as the `TRANSP` escape and desynchronise the CH4 stream. It's latent, because the music never uses drum 0.
8. **No SFX queueing.** A new SFX restarts the SFX voice. `SndPlaySong` clears the SFX mode (the SFX is cut, and its channel may keep ringing).
9. **CH3 is gated for every note.** NR30 is switched off and on around every CH3 note, which can click on hardware. The wave is never reloaded. v 0/1 and 2/3 etc. give the same CH3 level.
10. **`SndPlaySfx` leaves interrupts disabled** (`DI` without `EI`). `SndPlaySong` has both. That's harmless in this game because every interrupt handler is `RETI` and the game polls LY.
11. **Tempo depends on the frame loop.** The update runs from the main loop, so heavy frames slow the music. Loading loops call `GameSndUpdate` themselves, and `GameStopMusic` adds an extra update, which gives two ticks in that frame.
12. **Dead state and commands.** Commands 2–6 do nothing useful and aren't in the data. Voice +08, +0A, +0B and +0D–+1A are never read, yet 27 bytes are copied out and back for each of five voices every tick. The `$4003` entry is just `RET`. `GamePlaySong` passes `C = 8`, which the driver ignores.

## 6. Unreferenced data

None in the sound area: every byte from `$4396` to `$60E5` belongs to a referenced pattern, order list or table, and all 179 patterns are played by some song or SFX. Only SFX 7 and 10 (§5.1) and the unused instrument/drum entries (tone 0–7 all used, drums 0 and 2 unused) have no path to them.

## 7. Verification and caveats

- The byte-exact rebuild covers the glue, the driver, all tables and all data. `gen_asm.py` asserts that the regions tile `$4396–$60E5` exactly.
- **PyBoy, real ROM:** boot → language → intro (song 0) → title (song 1) → map (song 2) → Africa level 1 (song 5). Confirmed: exactly one update per frame (two in frames with `GameStopMusic`). The first CH1–CH3 notes of song 0 match the decoded periods, instruments, volumes and frame timing (192 units at `$F3` = 14–15 frames). Also confirmed: jump SFX 4 overrides CH1, and pause keeps the music running.
- **Test harness** (`harness/`: a small ROM that links the rebuilt driver and takes commands from `$C000`): all 13 songs play with the four channels wrapping within 2 frames of each other (no desync), and noise SFX muting of CH4 was checked there. The MP3 renders come from it.
- Not verified: the roles of songs 3/4/6–12 (level assignment is from the level headers, the jingle roles are guesses), and which `GameSfxList` entries the bank-2 data actually uses. Nothing was checked on hardware.

## Files (in `GBAudioLab\Smurfs2`)

- `Smurfs2_SoundDriver.asm`: labelled, commented RGBDS source with stream/order macros, byte-exact (+ `hardware.inc`, `build_check.sh`)
- `Smurfs2_SongData.txt`: tables, every order list and pattern decoded with note names, SFX list, coverage note
- `tools/smparse.py` (decoder → `.txt`), `tools/gen_asm.py` (generates the `.asm` from `code_part.asm` + `glue_part.asm` + data)
- `harness/`: test-harness ROM source, `render.py`, and `audio/` with MP3 renders of all 13 songs and 18 SFX (PyBoy APU, one pass each)

Sources: [TCRF – The Smurfs Travel the World (GB)](https://tcrf.net/The_Smurfs_Travel_the_World_(Game_Boy)) · [MobyGames](https://www.mobygames.com/game/31137/the-smurfs-travel-the-world/)
