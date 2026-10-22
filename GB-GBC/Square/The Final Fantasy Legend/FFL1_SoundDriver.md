# Final Fantasy Legend (GB): sound driver

ROM: `Final Fantasy Legend, The (U) [!].gb` (DMG, MBC2, 128 KB, internal title `SAGA`). Square, 1989/1990 (*Makai Toushi SaGa*).

| | |
|---|---|
| API (bank `$07`) | `$4000` `SoundInit` (jp → `$4006`, called once at boot from `$02D5`), `$4003` `SoundUpdate` (jp → `$4030`, every frame) |
| Requests (HRAM) | `hSongRequest` `$FFE0` (0–17), `hSpecialSong` `$FFE2` (a song played on top of the current one, which then resumes), `hSfxRequest` `$FFE4` (1–36) |
| Tick | `SoundUpdate` once per frame from the LCD (LYC) interrupt (ROM0 `$06D0` → `$06DB`). Inside it, music ticks run at **tempo ÷ 60 per frame**, so the tempo byte is roughly ticks per second |
| Code | bank `$07` `$4000–$462E` and `$6A3D–$6BC6` |
| Music data | `SongTable` `$462F` (18 × 6 bytes), streams `$469B–$686F`, instrument sequences `$6870–$69BC`, 8 CH3 waves `$69BD–$6A3C` |
| SFX | `SfxToneTable` `$6BC7`, `SfxNoiseTable` `$6C0F` (36 each), streams `$6C57–$6DF9` |
| RAM | WRAM `$CE00–$CE5F` (3 channel structs), `$CE60–$CEBF` (saved copy), `$CEC0–$CEC7`; HRAM `$FFE0–$FFEE` |
| Channels | music: **CH1, CH2, CH3**. SFX: CH1 + CH4 (CH4 is SFX-only) |

`FFL1_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over both ranges: ROM0 `$06D0–$06E4` and bank `$07` `$4000–$6DF9`. It assembles cleanly with `-Wall`.

```
rgbasm -Wall -o ffl1snd.o FFL1_SoundDriver.asm
rgblink -o ffl1snd.gb ffl1snd.o
python tools/cmp_ranges.py "Final Fantasy Legend, The (U) [!].gb" ffl1snd.gb
```

---

## 1. What it is

This is a **different and older design** from the FFA / FFL2 / FFL3 driver. The only parts carried over are the 85-entry period table (here without the trigger bit), the 5-byte CH1 SFX frames, and the "special song" push/pop. Everything else is different:

- **One routine for all channels.** It works on a struct pointer in `hChannelBase` (`$FFE7`), and every field access goes through `ChannelField` (`ld hl, offset / call $45B5`). FFA–FFL3 instead have three or four copy-pasted routines, one per channel.
- **Instruments are four independent sequences** per channel, each with its own id, position and timer, all stepped once per music tick (not per frame):
  - volume envelope;
  - pitch effect;
  - duty;
  - **pan**.

  `$F7` selects one by kind and id.
- **The volume** is computed as envelope level × channel volume (`$E1–$EF`).
- **The tempo** is a ticks-per-second value: each frame `wTempoAcc += hTempo`, and while the result is ≥ 60 the driver subtracts 60 and runs one tick. The tempo is global; any channel can set it.
- **The note byte** is `pitch << 4 | length`. That's the layout FFL3 went back to; FFA and FFL2 swap the nibbles.

### Tick order

`MusicTick` (`$40CD`):

1. Start the requested song if `hSongRequest ≠ hSongCurrent`.
2. NR10 = 0 unless an SFX owns CH1.
3. `ChannelOutput` for CH1–CH3. This acts on the event byte read on the **previous** tick and runs the four sequences.
4. `StreamTick` for CH1–CH3: `--Timer`, and when it reaches 0, read commands up to the next note/rest/tie byte and store it in `Event`.

This adds a uniform one-tick latency, so it doesn't affect relative timing. A note's length is loaded into `Timer` when the event is processed.

---

## 2. Channel struct (`$CE00` CH1, `$CE20` CH2, `$CE40` CH3, `$20` bytes)

| Off | Name | Use |
|---|---|---|
| `$00` | Flags | bit 7 = stopped, bit 0 = an SFX owns the channel (CH1 only) |
| `$01` | Timer | ticks until the next stream read |
| `$02` | Ptr (2) | stream pointer |
| `$04` | Event | last note/rest/tie byte, `$0F` = none |
| `$05` | Octave | 0–4 |
| `$06` | LoopCount | the single loop counter |
| `$09` | Freq (2) | note period, `$FFFF` = rest |
| `$0B` | Volume | 1–15 (`$E1–$EF`) |
| `$0C–$0E` | VolEnv id / pos / timer | |
| `$0F–$11` | Pitch id / pos / timer | |
| `$12–$14` | Duty id / pos / timer | |
| `$15–$17` | Pan id / pos / timer | |
| `$18–$1B` | NRx1–NRx4 copies | NRx2–NRx4 are kept up to date. NRx1 only changes via `$F5` (no song uses it). They're used to restore CH1 after an SFX |
| `$1C` | PanByte | last pan step |

`$07`, `$08` and `$1D–$1F` are unused. `StartSong` (`$4059`) clears all three structs, then sets Event = `$0F`, Timer = 1, the four sequence timers = 1 and Flags = 0, and writes NR52 = `$8F`, NR30 = `$FF`, NR50 = `$77`. It does **not** reset `hTempo` (every song sets its tempo on tick 0 anyway).

---

## 3. Music format

### 3.1 Song table (`$462F`, 18 × 6 bytes)

`dw ch1, ch2, ch3`, indexed by the id directly (no `dec`). **Song 0** is silence: all three pointers go to a lone `end_track` at `$50EE`. There's no range check.

### 3.2 Stream bytes

| Byte | Macro | Meaning |
|---|---|---|
| `$00–$BF` | `note p, len` | pitch 0–11 (C…B) in the high nibble, length index in the low nibble |
| `$C0–$CF` | `rest len` | Freq = `$FFFF` → NRx2 = `$08` (silent, DAC on), CH1/CH2 retriggered |
| `$D0–$DF` | `tie len` | extend the current note, sequences carry on |
| `$E0 n` | `tempo n` | global tempo (ticks per second) |
| `$E1–$EF` | `volume n` | channel volume 1–15 |
| `$F0–$F4` | `octave n` | |
| `$F5 n` | `set_nrx1` | sets the NRx1 copy (+`$18`) only; unused |
| `$F6` | – | table entry is `$0000` → **jumps to the reset vector** (crash); unused |
| `$F7 kk iiiiii` | `instr kind, id` | select sequence `kind` (0 vol, 1 pitch, 2 duty, 3 pan) = id, and restart it |
| `$F8 n` | `wave n` | load `WaveTable + n×16`, NR30 on, retrigger CH3 (NR34 from the cached high byte) |
| `$F9/$FA/$FB` | `loop_count 1/2/3` | LoopCount = 1–3 |
| `$FC ptr` | `loop` | count 0 → fall through, else `--count` and jump (so `loop_count n` = n+1 passes) |
| `$FD ptr` | `if_done` | count 0 → jump (the "last pass" exit) |
| `$FE ptr` | `jump` | |
| `$FF` | `end_track` | stop: Flags bit 7, NRx2 = 0 |

Commands are read until a note/rest/tie byte, then reading stops until the timer expires.

**Lengths** (`NoteLengthTable` `$4403`): 96, 72, 48, 36, 32, 24, 18, 16, 12, 9, 8, 6, 4, 3, 2. Index 15 would read the first byte of `NoteFreqTable` (44 ticks), and the byte `$0F` (C, index 15) can't be played at all, because `$0F` means "no event". No song uses index 15.

**Pitch:** `NoteFreqTable[octave×24 + note×2]` (`$4412`). The values are the same 85 periods as the later games, without the `$80` bit.

### 3.3 Instrument sequences

All four are stepped once per music tick. The volume, pitch and duty sequences restart on each new note (not on ties or rests). **The pan sequence never restarts.**

| Kind | Table | Entry format | Effect |
|---|---|---|---|
| 0 volume | `VolEnvTable` `$6870` (13) | (ticks, level<<4 \| NRx2 low nibble) pairs | level = `(env × Volume + 16) >> 4` → NRx2 with the entry's low nibble, and **every step retriggers** CH1/CH2. CH3: level → `Ch3VolumeTable` (0–2 mute, 3–6 25 %, 7–10 50 %, 11–15 100 %) → NR32. An env level of 0 still gives level 1 |
| 1 pitch | `PitchFxTable` `$68D3` (9) | (ticks, signed offset) pairs | Freq + offset → NRx3/NRx4, written only when changed, no trigger |
| 2 duty | `DutyTable` `$69AE` (3) | `duty<<6 \| ticks` bytes | NRx1 = duty (on CH3 the write goes to NR31) |
| 3 pan | `PanTable` `$692F` (14) | `R<<7 \| L<<6 \| ticks` bytes | NR51 bits for the channel |

Timer 0 = `seq_goto pos`, which jumps to a byte offset from the sequence start. The volume envelopes use no gotos. Each one ends on a `$FF` (255-tick) hold followed by one stray byte, and the tables overlap. The longest note + ties in any song is 168 ticks, so the holds never expire.

### 3.4 Songs

Tempo ≈ ticks per second (exactly tempo × 59.7275 / 60). Intro + loop are in ticks.

| # | Tempo | Intro + loop | Loop | Notes |
|---|---|---|---|---|
| 0 | – | – | – | silence |
| 1 | 55 | 12 + 2400 | 43.8 s | requested at ROM0 `$289F` |
| 2 | 68 | 24 + 2304 | 34.0 s | |
| 3 | 62 → 30 | one-shot, 7032 | **2:27** | several tempo changes, final ritardando (likely the ending) |
| 4 | 48 | 0 + 2304 (CH2 768) | 48.2 s | |
| 5 | 70 | 576 + 3072 | 44.1 s | slows 70 → 65 in the intro |
| 6 | 70 | 768 + 2232 | 32.0 s | |
| 7 | 33 | 24 + 1536 | 46.8 s | |
| 8 | 65 | 0 + 2304 | 35.6 s | |
| 9 | 35 | 0 + 2304 | ~66 s | each loop ends with a ritardando 35 → 30 |
| 10 | 64 | 24 + 2304 | 36.2 s | |
| 11 | 54 | 384 + 1536 | 28.6 s | |
| 12 | 54 → 60 | 192 + 768 | 12.9 s | |
| 13 | 35 | 192 + 768 | 22.0 s | |
| 14 | 30 | 384 + 1536 (CH1/CH3 384) | 51.4 s | **title screen** (confirmed) |
| 15 | 100 | one-shot, 312 | 3.1 s | jingle |
| 16 | 45 → 30 | one-shot, 111 | 3.2 s | jingle (no CH3) |
| 17 | 35 | 24 + 768 | 22.0 s | |

The game's script command for sound (`$1ACB`) splits a byte: `$00–$3F` → `hSongRequest`, `$40–$7F` → `hSpecialSong`, `$80+` → `hSfxRequest`. That's why most song ids come from data, and why the other roles weren't identified.

---

## 4. Special song (`$FFE2`)

`SpecialSongUpdate` (`$6A44`) runs before the music each frame:

- **Start.** On a request (when not already active), it saves `hTempo`, the song id and all three structs (`$60` bytes → `$CE60`). Then it sets `hSongRequest` = the special id and clears `hSongCurrent` so it starts.
- **Resume.** While active, as soon as **all three channels are stopped** it copies the structs back and restores tempo and song id. The old song continues from exactly where it was. Confirmed: song 15 over the title song, title resumed after 190 frames at the same stream pointers.

Same idea as FFA's "special song" and FFL2's "foreground music".

---

## 5. Sound effects

`SfxUpdate` (`$6AA8`) runs once per frame. For a request it loads both pointers, sets CH1's Flags bit 0 and `wSfxNoiseOn`, and sets both timers to 1. **Every SFX claims both CH1 and CH4**: when one part is absent its pointer goes to a bare `sfx_end` at `$6C57`, which ends on the first frame. There's no priority and no range check.

| Byte | Tone (CH1) | Noise (CH4) |
|---|---|---|
| `$En` | loop count = n | same |
| `$Fx ptr` | `--count ≠ 0` → jump (any `$Fx`; data uses `$F0`) | same |
| `$00` | end: release CH1 | end: `wSfxNoiseOn` = 0, CH4 out of NR51 |
| other | frames, then NR10–NR14 (5 bytes); NR51 \|= `$11` | frames, then NR41 = 0, NR42, NR43, NR44 = `$80`; NR51 \|= `$88` |

**Releasing CH1** clears bit 0, NR10 = 0, **NR51 &= `$EE`**, and copies the struct's NRx1–NRx4 copies to NR11–NR14 (no trigger).

---

## 6. Quirks and bugs

1. **CH1 music goes quiet after every SFX.** The release takes CH1 out of NR51, and only the pan sequence puts it back. That sequence isn't restarted by notes and its steps are up to 63 ticks long. Measured on the title song with SFX 1: CH1 was out of NR51 for **83 frames (1.4 s)** after the SFX ended (`verify/sfx_pan.py`).
   - This happens even with noise-only SFX, since they claim CH1 too.
   - The release also sets NR11 from a copy only `$F5` writes (always 0), so CH1 is at 12.5 % duty until its next note restarts the duty sequence.
2. **`$F6` jumps to `$0000`.** The command table entry is zero, so the byte would reset the game.
3. **The command table has 15 entries.** The 16th slot is the first instruction of `Cmd_Octave` (`$0FE6`); `$FF` never reaches it.
4. **Length index 15** reads the period table; byte `$0F` is unplayable (§3.2).
5. **An envelope level of 0 gives volume 1**, not silence (`+16` before the shift).
6. **`hTempo` isn't reset on a song change** (harmless, since every song sets it at tick 0).
7. **Tick bursts.** At tempo > 60 several ticks run in the same frame (song 15 at 100: 1 or 2 ticks per frame, alternating).
8. **Special-song resume restores only the RAM structs.** Wave RAM, NR51 and the channel registers aren't rewritten, so a special song that loads another wave leaves it in place until the resumed song's next `wave`.
9. **The duty sequence writes NR31 on CH3** (wave length). It's harmless: length isn't enabled.
10. **`RegStop` has a 4th entry (NR42)** and `IsChannelFree` is generic: leftovers that suggest a 4-channel layout was planned.
11. **Dead bytes:** `$462D–$462E` (`C9 01`), the stray byte after each volume envelope, and struct bytes `$07/$08/$1D–$1F`.

---

## 7. Verification

- **Byte-exact rebuild** of both ranges (`tools/cmp_ranges.py`), `-Wall` clean.
- **Music:** all 17 songs forced from the title screen (`verify/vmusic.py`, PyBoy). Every note/rest/tie byte the real driver reads (address and tick, all three channels) matches the model in `tools/ffl1parse.py` for 7300 ticks, past every loop point and through the end of the one-shots: 23 603 notes.
- **SFX:** all 36. The frames the driver keeps CH1 and CH4 busy match the model length, loops expanded (`verify/vsfx.py`).
- **Special song** push/resume (`verify/special.py`), **song 3** runs 147.4 s (`verify/song3.py`), **rate** is exactly one call per frame (3000 in 3000 frames, `verify/caller.py`), and the CH1-after-SFX quirk (`verify/sfx_pan.py`).
- **Not verified:** the role of songs other than 14 (title), and hardware audio.

## Files (in `GBAudioLab\FF\FFL1`)

- `FFL1_SoundDriver.asm`: labelled, commented RGBDS source with music, instrument and SFX macros, byte-exact
- `tools/`: `sm83.py`, `trace.py`, `ffl1parse.py` (stream model), `dumpsong.py`, `dyn.py`, `sfx.py`, `gen_ffl1.py` (generates the asm), `cmp_ranges.py`
- `verify/`: PyBoy scripts for §7 (ROM path from `FFL1_ROM`)

Regenerate: `python tools/gen_ffl1.py "Final Fantasy Legend, The (U) [!].gb" .`
