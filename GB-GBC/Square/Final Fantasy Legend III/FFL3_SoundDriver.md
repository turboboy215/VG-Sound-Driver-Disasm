# Final Fantasy Legend III (GB): sound driver

ROM: `Final Fantasy Legend III (U) [!].gb` (DMG, MBC3 + RAM + battery, 256 KB, internal title `SAGA3`). Square, 1993.

| | |
|---|---|
| API (bank `$0F`) | `$4000` vector → `$4006` `SoundUpdate_Main`, `$4003` vector → `$4031` `SoundReset` (no caller found). Requests go through HRAM: `hSongRequest` `$FFBA` (1–20, 0 = stop), `hSfxRequest` `$FFBC` (1–65) |
| Tick | once per frame, from the **STAT ISR** (`$0048` → `$C0BC` → `$1F27` → `$1F3A` far call). Also called at `$11DC`, `$3624` and `$3A60` (the last one right after the game zeroes the song request, so the stop takes effect at once) |
| Code + tables | bank `$0F` `$4000–$48CE` (code `$4000–$482E`, `SongTable` `$482F`) |
| Music data | `$48CF–$65D6` (streams), `$65D7–$66B1` (volume envelopes, pitch effects), `$66B2–$66F1` (4 CH3 waves) |
| SFX | `SfxToneTable` `$66F2`, `SfxNoiseTable` `$6774` (65 entries each), streams `$67F6–$6BAE` |
| RAM | WRAM `$CB00–$CB67`, HRAM `$FFBA–$FFC5` |
| Channels | music: **CH2, CH1, CH3, CH4** (in that internal order). SFX: CH1 and CH4. |
| Counts | 20 songs (one one-shot, 19 loop forever), 65 SFX |

`FFL3_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over both ranges (ROM0 `$1F27–$1F44`, bank `$0F` `$4000–$6BAE`). It assembles cleanly with `-Wall` and needs no `hardware.inc`.

```
rgbasm -Wall -o ffl3snd.o FFL3_SoundDriver.asm
rgblink -o ffl3snd.gb ffl3snd.o
python tools/cmp_ranges.py "Final Fantasy Legend III (U) [!].gb" ffl3snd.gb
```

---

## 1. The credits theme and its "hidden" ending

**The credits theme is song 7** (table index 6, `$4B92/$4C64/$4D23/$4E10`). Song 9 is an ordinary looping piece with no ending (each channel ends in a `jump`). Song 7 is the only song in the game whose tone channels end with `$FF` (`end_track`). All the others loop forever.

The ending isn't hidden in the data. It sits right after the main theme. It is only reached after **16 complete passes** of that theme:

```
Song07_Ch2:
    init_ch2 $57, PitchFx_667A, VolEnv_6625, $C0, 3
    octave 3
    set_b 16                 ; counter B = 16
.l4B9D:
    ...                      ; main theme, 1152 ticks (28.4 s)
    loop_b Song07_Ch2.l4B9D  ; $4C0E: --B != 0 -> repeat
    tempo $68                ; $4C11: CODA starts here
    ...                      ; new material, ritardando $68 → $60 → $5B → ... → $44
    end_track                ; $4C63
```

The other channels have the same structure: CH1 `set_b 16` at `$4C6B`, `loop_b` at `$4CD5`, coda `$4CD8–$4D22`. CH3 `set_b 16` at `$4D2A`, `loop_b` at `$4DC2`, coda `$4DC5–$4E0F`. CH4 has `set_b 32` at `$4E13` around a 15-round loop-A pattern, and its coda is `$4E3B–$4E5A`.

Timing at tempo `$57` (one driver call per frame, 59.73 Hz):

| | ticks | time |
|---|---|---|
| one pass of the theme | 1152 | 28.4 s |
| coda starts | 18 432 | **7:34.0** |
| CH4 stops | 19 008 | 7:46.7 |
| song ends | 19 368 | **7:57.3** |

So the coda is the last ~23 s of a ~8-minute piece, which is why you only hear it by sitting through the whole staff roll.

**Why rips and converters miss it.**

- **GBS rips.** The song is one-shot and very long. A playlist length or default track time of 2–5 minutes (and fade) cuts it off long before 7:34.
- **Converters.** A converter that treats the first backward jump (or the first revisit of an address) as the song's loop point stops after **pass 1**. The `loop_b` at `$4C0E` *looks* like the song loop, but the state isn't the same: counter B is different on every pass, and only reaches 0 after the 16th. To get the coda, a converter has to model the counters exactly:
  - both start at **0** when a song starts;
  - `loop_a`/`loop_b` decrement *first*, then jump if the result ≠ 0;
  - `if_a n` compares counter A only.

  Detect loops on the full state (address, counter A, counter B) rather than on the address alone. (Starting at 0 also means a `loop_x` with no `set_x` before it would repeat 256 times.)

**Confirmed on the real driver** (`verify/credits.py`, PyBoy): forcing song 7, the CH2 stream pointer enters the coda on driver call 27 120 = **454.1 s**, CH4 stops at 466.7 s and CH2/CH1/CH3 at 477.4 s. `verify/render_coda.py` writes `wav/song07_coda_from_7m20s.wav` (PyBoy APU, 7:20 to the end, 40 s) so you can hear the last pass and the coda.

Caveat: I couldn't reach the actual credits in the game, so the identification rests on the structure (the only one-shot song, an 8-minute 16-pass staff-roll form, a final ritardando cadence). Nothing in the driver changes speed, but if the credits scene called the driver more than once per frame the times above would scale. In the title scene it runs exactly once per frame.

---

## 2. Engine overview and lineage

It's the same Square driver family as FFA (bank `$0F` there too) and FFL2. The note-period table is the identical 85-entry `$802C…$87F0` table, and these all work the same way:

- the effect formats (timer/value pairs, 0 = jump);
- the 2-ticks-per-tempo-overflow scheme;
- the effect rotation (one channel per frame);
- the SFX formats.

What FFL3 changes:

| | FFA / FFL2 | FFL3 |
|---|---|---|
| Music channels | CH2, CH1, CH3 | **CH2, CH1, CH3, CH4** |
| Song table entry | 3 pointers (FFL2: 6 bytes) | 4 pointers (8 bytes) |
| Note byte | `length<<4 \| note`, `< $D0`; note `$E` tie, `$F` rest | **`note<<4 \| length`**, `< $E0`; note `$C` tie, `$D` rest |
| Length table | 13 entries (`$60 $48 $30 $20 $24 $18 $10 $12 $0C $08 $06 $04 $03`) | **16 entries**, sorted (`$90 $60 $48 $30 $24 $20 $18 $12 $10 $0C $09 $08 $06 $04 $03 $02`) |
| Octave | `$D0–$DF` | `$E0–$EF` (same bit-3 absolute/relative scheme, same delta table) |
| Commands | `$E0–$EB` (FFL2) / `$E0–$EC` (FFA) | `$F0–$FE`, same index order for 0–B, plus `$FC` and `$FE` |
| Undefined command | FFA: `jp` to itself (hang); FFL2: `ret` | hang (`jr $4616`), with FFA's orphan `ret` after it |
| Song "pause/resume" (FFL2 foreground music, FFA special song) | yes | **removed** |
| SFX restore | – | CH1 duty/pan and CH4 pan mirrored in RAM and restored after an SFX |

`$FC` on CH2 reads one byte and discards it. That's what's left of FFA's `$EC` "double-time" command, whose flag FFA never checked. FFL3 always runs two ticks per tempo overflow, as FFA effectively did.

### Tempo and ticks

Each driver call: `wTempoAcc += wTempo`. On carry, `MusicTick` runs **twice**. Ticks per second = 59.7275 × tempo / 128. A song start sets `wTempoAcc = $FF` and tempo `$3C`, and the CH2 `init_ch2` sets the song's tempo on the first tick. `SoundReset` sets tempo 0, so nothing ticks until the next song.

### Effects

After the ticks, `hFxChannel` rotates 0, 1, 2: frame 0 runs CH2 effects, frame 1 CH1, frame 2 CH3 pitch + CH4 volume. Each channel's effects run at **19.9 Hz**.

---

## 3. Music data format

### 3.1 Song table (`$482F`, 20 × 8 bytes)

`dw ch2, ch1, ch3, ch4`. `PlaySong` (`$4065`) ignores ids > 20, loads the four pointers and clears each channel struct (loop A/B = 0, SFX timer = 0, stopped = 0, timer = 1). Songs 3, 10 and 20 share one CH4 stream, a lone `end_track` at `$4B91` (no drums).

### 3.2 Stream bytes

| Byte | Meaning |
|---|---|
| `$00–$DF` | note: high nibble = pitch (`0–B` = C…B, `C` = tie, `D` = rest), low nibble = length index into `NoteLengthTable` |
| `$E0–$E7` | octave = n (CH1–CH3) |
| `$E8–$EB` / `$EC–$EF` | octave +1…+4 / −1…−4 (CH1–CH3) |
| `$F0–$FE` | command (table below). **On CH4, `$E0–$EF` are commands too** (low nibble) |
| `$FF` | end of track: the channel stops (`Stopped = $FF`) |

**Pitch:** `NoteFreqTable[octave×24 + note×2]`. The high byte has `$80` set, so CH1/CH2/CH4 notes retrigger.

- **CH3** writes NR33/NR34 with `& 7` (no trigger). Its volume comes from NR32 = channel volume. A rest is NR32 = 0. CH3 is retriggered only by a wave load.
- **CH4:** the note's pitch nibble indexes `NoiseNoteTable` (`$4619`: `64 59 54 2F 44 34 2E 24 2D 14 1D 04`) for NR43. NR42 comes from the envelope's first value, NR44 = `$80`. Octave is ignored.
- **Tie** extends the current note without touching hardware, and effects keep running. **Rest** on CH1/CH2: period `$7FF` with no trigger (inaudible). On CH4: NR42/NR43 = 0 + trigger.

### 3.3 Commands

Arguments follow the command byte. "–" = undefined on that channel → `Cmd_Hang`, an infinite loop that freezes the game.

| Cmd | Macro | Args | CH2 | CH1 | CH3 | CH4 |
|---|---|---|---|---|---|---|
| `$F0` | `env` / `volume` | dw / db | envelope | envelope | **NR32 volume (db)** | envelope |
| `$F1` | `jump` | dw | ✓ | ✓ | ✓ | ✓ |
| `$F2` | `loop_a` | dw | `--A ≠ 0` → jump | ✓ | ✓ | ✓ |
| `$F3` | `set_a` | db | ✓ | ✓ | ✓ | ✓ |
| `$F4` | `pitch_fx` | dw | ✓ | ✓ | ✓ | – |
| `$F5` | `duty` | db | NR21 | NR11 (mirrored; not written during an SFX) | – | – |
| `$F6` | `pan` | db 0–3 | NR51 bits (0 off, 1 right, 2 left, 3 both) | mirrored | ✓ | mirrored |
| `$F7` | `tempo` | db | ✓ | – | – | – |
| `$F8` | `wave` | dw | – | – | load 16 bytes, NR30 on, NR32 = 0, NR34 = `$87` | – |
| `$F9` | `loop_b` | dw | `--B ≠ 0` → jump | ✓ | ✓ | ✓ |
| `$FA` | `set_b` | db | ✓ | ✓ | ✓ | ✓ |
| `$FB` | `if_a` | db n, dw | `A == n` → jump | ✓ | ✓ | ✓ |
| `$FC` | `ignored` | db | argument dropped | – | – | – |
| `$FD` | – | | – | – | – | – |
| `$FE` | `init_ch2/1/3` | 7 / 6 / 6 | tempo, pitch_fx, env, duty, pan | pitch_fx, env, duty, pan | pitch_fx, volume, wave, pan | – |

Every song's CH1–CH3 starts with `$FE`. `$F8` and `$FC` aren't used by any song (waves are loaded only through `init_ch3`). No reachable stream hits an undefined command. Handlers are called with DE = stream pointer and return into the read loop, so a channel reads commands until it reaches a note. The pointer is only written back to RAM at a note.

### 3.4 Effect tables

Both kinds are `(fx ticks, value)` pairs. Timer 0 = `fx_jump` to the following pointer. One fx tick = 3 frames.

- **Volume envelopes** (`$65D7–$6662`): value → NRx2, then NRx4 is rewritten (CH4: NR44 = `$80`), i.e. a retrigger. Timer `$FF` = hold. At note start, NRx2 is set to the first value straight away. The tables are one long chain of `$63`-tick steps with no terminator: each label is an entry point, and a note held for more than 99 fx ticks walks on into the next table's values. The chain ends with `fx $FF, $00` at `$6661`.
- **Pitch effects** (`$6663–$66B1`): signed period offset added to the note's base period. Seven tables: `$6663` is "none" (`$63, 0` looping on itself); the rest are vibratos.
- **Waves** `Wave0–Wave3` at `$66B2/$66C2/$66D2/$66E2`.

### 3.5 Songs

Tempo is the `init_ch2` value. Loop = CH2 loop period; intro = ticks before the loop point. All four channels' loop periods are equal or divide each other, so no song drifts.

| # | Tempo | Intro + loop (ticks) | Loop | Notes |
|---|---|---|---|---|
| 1 | `$7E` | 60 + 1536 | 26.1 s | |
| 2 | `$7E` | 96 + 2112 | 35.9 s | |
| 3 | `$40` | 0 + 696 | 23.3 s | no CH4 |
| 4 | `$41` → `$82` | 504 + 768 | 12.7 s | tempo doubles to `$82` at tick 96 (in the intro) |
| 5 | `$78` | 36 + 2304 | 41.1 s | |
| 6 | `$60` | 384 + 1536 | 34.3 s | **title screen** (confirmed) |
| 7 | `$57` | one-shot, 19 368 | 7:57 | **credits**: 16 passes + coda (§1) |
| 8 | `$96` | 192 + 1344 | 19.2 s | |
| 9 | `$5D` | 144 + 1008 | 23.2 s | |
| 10 | `$42` | 0 + 1152 | 37.4 s | no CH4 |
| 11 | `$7D` | 48 + 1536 | 26.3 s | |
| 12 | `$5A` | 0 + 1224 | 29.1 s | |
| 13 | `$96` | 0 + 672 | 9.6 s | |
| 14 | `$82` | 36 + 1728 | 28.5 s | |
| 15 | `$4C` | 0 + 2040 | 57.5 s | |
| 16 | `$78` | 0 + 768 (CH1/CH3 2304) | 41.1 s full cycle | |
| 17 | `$8C` | 0 + 672 | 10.3 s | |
| 18 | `$C8` | 0 + 2880 | 30.9 s | |
| 19 | `$78` | 768 + 1536 | 27.4 s | |
| 20 | `$4A` | 0 + 1728 | 50.0 s | no CH4 |

Roles other than 6 and 7 weren't identified.

---

## 4. Sound effects

`PlaySfx` (`$4759`) runs when `hSfxRequest` ≠ 0: id − 1 indexes both tables, and a 0 pointer means that part is absent. It starts CH1 (`wSfxTonePtr`, timer 1) and/or CH4 (`wSfxNoisePtr`). There's **no priority and no range check**: a new SFX replaces the running one, and ids above 65 read past the tables.

| Byte | Tone stream (CH1) | Noise stream (CH4) |
|---|---|---|
| `$01–$EE` | frames, then 5 bytes → NR10–NR14; NR51 \|= `$11` | frames, then NR42, NR43; NR44 = `$80`; NR51 \|= `$88` |
| `$Fn` | loop count = n | same |
| `$EF` dw | `--count ≠ 0` → jump | same |
| `$00` | end: restore CH1 (NR11 = music duty, NR12 = 0, NR51 pan) | end: NR42 = `$08`, NR43 = 0, restore CH4 pan |

While an SFX runs, the music channel underneath keeps advancing its stream but writes nothing. After it ends, `wSfxToneHeld`/`wSfxNoiseHeld` keep that channel's effects off until its next note, so a tie can't resume at volume 0 with a stale envelope. **A song request is deferred while either SFX channel is busy** (`$400A`).

---

## 5. Quirks and bugs

1. **Credits coda only after 16 passes** (§1). It isn't a bug, but it's the reason the ending is "hidden".
2. **Undefined commands freeze the game** (`Cmd_Hang`, `jr $4616`): `$F7` off CH2, `$F8` off CH3, `$F4`/`$F5`/`$FE` on CH4, `$FD` anywhere, `$FC` off CH2. None is reachable in the shipped data.
3. **CH4 aliases `$E0–$EF` onto its command table** (so `$E1` = `jump` on CH4). No song uses that.
4. **Effects wait after a note that starts on the second tick of a pair.** Effects run only if the channel's `hChXTimerCopy` ≠ 0. That copy is the timer after the last tick, which is 0 when a note was just read. So a note read on the second tick gets no vibrato or volume steps until the next tempo overflow.
5. **A volume step retriggers at the base period's high byte** (`$CB0D` etc.), while NRx3 still holds the last vibrato-modified low byte. If a vibrato crosses a high-byte boundary, the pitch is momentarily wrong, and every volume step restarts the duty phase.
6. **Envelope chain has no terminators** (§3.4): a note longer than 99 fx ticks (~5 s) continues with the next table's envelope.
7. **`SoundReset` doesn't clear `wCh4SfxTimer`** (it clears only `wCh1SfxTimer`). A noise SFX running at a reset keeps playing.
8. **`SoundInit` (`$4003`) has no caller**. The game relies on song 0 / the reset path and the boot state of the APU.
9. **Song ids > 20** are stored in `hSongCurrent` but otherwise ignored. Re-requesting the current song does nothing (a restart needs a 0 in between).
10. **Song 20 CH1 `$5598`:** the last `loop_a` would fall through into CH3's `init_ch3` if counter A reached 0 there. Unreachable: A is always ≥ 2 at that point.
11. **`$FC` and the hang loop with its orphan `ret`** are FFA leftovers (§2).

---

## 6. Verification

- **Byte-exact rebuild** of both ranges (`tools/cmp_ranges.py`), `-Wall` clean.
- **Every song against the real driver** (`verify/vmusic.py`, PyBoy). Each of the 20 songs is forced from the title screen, and every note the driver reads (address and tick, on all four channels) is compared with the model walk in `tools/ffl3parse.py` over 6000 ticks, which is past every loop point (the longest is 3024 ticks). Song 7 was also checked over 20 000 ticks, i.e. to its end. All 20 match exactly (38 465 notes in the 6000-tick run).
- **Credits:** coda reached at 454.1 s, end at 477.4 s on the real driver (`verify/credits.py`). Matches the model (`tools/timeline.py 7 4C11 4C63`).
- **Rate:** exactly one driver call per frame once the game is running (28 514 calls in 28 514 frames during the credits test; 1133 in the first 1200 frames from power-on). Callers from `verify/caller.py`.
- **Not verified:** that the credits scene really requests song 7 (the identification is structural), the credits-scene call rate, the roles of the other songs, and hardware audio. The WAV comes from PyBoy's APU.

## Files (in `GBAudioLab\FF\FFL3`)

- `FFL3_SoundDriver.asm`: labelled, commented RGBDS source with music/effect/SFX macros, byte-exact
- `tools/`: `sm83.py` (disassembler), `ffl3parse.py` (stream model), `dumpsong.py`, `cover.py`, `dyn.py`, `timeline.py`, `sfx.py`, `gen_ffl3.py` (generates the asm), `cmp_ranges.py`
- `verify/`: PyBoy scripts used for §6 (ROM path from `FFL3_ROM`, needs `pip install pyboy`)
- `wav/song07_coda_from_7m20s.wav`: last pass + coda of the credits theme

Regenerate: `python tools/gen_ffl3.py "Final Fantasy Legend III (U) [!].gb" .`
