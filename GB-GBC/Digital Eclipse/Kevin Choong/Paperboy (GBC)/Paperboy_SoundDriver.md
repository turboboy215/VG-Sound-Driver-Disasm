# Paperboy (GBC): sound driver

ROM: `Paperboy (U) [C][!].gbc` (CGB-only, MBC5, 1 MB, internal title `PAPERBOY`). Midway, 1999.

| | |
|---|---|
| API (ROM0) | `$3095` `PlaySample` (A = id, or `$FF` + HL → slot), `$30F4` `SndInit`, `$3114` `PlaySong` (A = id), `$3318` `SndStop`, `$332E` `SndResume`, `$3335` `PlaySong0F` (= music off) |
| Tick | **timer IRQ only** (`$0050`: `ei / call $3189 / reti`), 97.52 Hz. Music on every 3rd IRQ (32.51 Hz). No VBlank involvement. |
| Driver code + tables | ROM0 `$3095–$3553` (code `$3095–$33D3`, `SongTable` `$33D4`, `SampleTable` `$34E4`) |
| Music data | bank `$3B` `$4000–$5AB5` |
| Sample data | banks `$3C` `$4000–$5545`, `$3D` `$4000–$6568`, `$3E` `$4000–$6697` (4-bit PCM, 26 324 bytes) |
| RAM | WRAM `$D0A5–$D0D4`, flags `$C8D2/$C8D3/$C8D7`, bank shadow `$C0A2` |
| Channels | music: CH1, CH2, CH4. Samples: CH3 only. |
| Counts | 17 songs (10 used), 14 samples (10 used) |

`Paperboy_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over all six ranges (0:`$0050–$0054`, 0:`$3095–$3553`, `$3B`:`$4000–$5AB5`, `$3C`:`$4000–$5545`, `$3D`:`$4000–$6568`, `$3E`:`$4000–$6697`). It assembles cleanly with `-Wall` and needs no `hardware.inc`. The sample data comes in through `INCBIN "samples/sample_XX.bin"`.

```
rgbasm -Wall -o pb.o Paperboy_SoundDriver.asm
rgblink -p 0x00 -o pb.gbc pb.o
```

---

## 1. What it is

A very small, self-contained driver (about 830 bytes of code) that does everything from the **timer interrupt**. It has no command language. Music is a flat list of `period, duration` events per channel. Samples are raw 4-bit data pushed into wave RAM 16 bytes at a time. Nothing links it to the other drivers in this project.

**Timing.** The game switches to CGB double speed at boot (`$01D3`) and never switches back. The unused routine at `$01F7` would return to normal speed, but it's buggy and never called. With TAC = `%100` (4096 Hz, doubled to 8192 Hz) and TMA = `$AC` (84 counts):

- timer IRQ = 8192 / 84 = **97.524 Hz** (10.254 ms). Measured in PyBoy: 97.55 Hz steady state.
- music tick = every 3rd IRQ = **32.508 Hz** (30.76 ms). For a MOD conversion that's BPM 81.27 at speed 1.

**Order inside the ISR:** music tick (if `wMusicEnable` ≠ 0 and the divider hits 0), then sample tick (if `wSampleEnable` ≠ 0), then restore the ROM bank from the game's shadow `wCurBank`. The vector re-enables interrupts first, so VBlank/STAT can nest inside it.

### RAM

| Addr | Name | Use |
|---|---|---|
| `$C8D2` / `$C8D3` | wMusicEnable / wSampleEnable | 0 skips that half of the ISR (set to 1 by the game at `$16ED`) |
| `$C8D7` | wSampleMute | ≠ 0: blocks still advance but CH3 isn't retriggered (set during two game screens, banks 3–5 `$4037`/`$4002`) |
| `$D0A5–$D0A8` | period lo/hi for CH1, CH2 | |
| `$D0A9` / `$D0AA` / `$D0B9` | CH1 / CH2 / CH4 timer | ticks until the next event |
| `$D0AB` / `$D0AD` / `$D0B5` | stream pointers | |
| `$D0AF` / `$D0B1` / `$D0B7` | stream starts | loop points |
| `$D0B3` | wMusicBank | from the song entry (always `$3B`) |
| `$D0B4` | wMusicDivider | 3, 2, 1 |
| `$D0BB` | wSampPtr | last block copied |
| `$D0BF` | wSampStart | written, never read |
| `$D0C1` / `$D0C3` / `$D0C4` | wSampEnd / wSampBank / wSampPrio | priority 0 = idle |
| `$D0C5` / `$D0CD` | wSampSlot1 / 2 | 8-byte copies of a `SampleTable` entry, for parked samples (§3.3) |

---

## 2. Music

### 2.1 Song table (`$33D4`, 17 × 16 bytes)

`dw ch1, ch2, ch4` + `db bank` + 9 unused zero bytes. All 17 songs are in bank `$3B`. `PlaySong` copies the three pointers to both "pointer" and "start", sets all timers to 1 and the divider to 3, and writes the fixed channel setup:

| Reg | Value | Meaning |
|---|---|---|
| NR10 | `$08` | sweep off |
| NR11 / NR21 | `$80` | 50 % duty |
| NR12 / NR22 | `$80` | volume 8, **no envelope**, for the whole song |
| NR41 | `$01` | (length not enabled) |

There's no per-note volume, duty, envelope or effect. Every note is a fresh trigger at volume 8.

### 2.2 Streams

| Channel | Event | Meaning |
|---|---|---|
| CH1, CH2 | `hi lo dur` (3 bytes) | NRx3 = lo, NRx4 = hi \| `$80`. dur = ticks until the next event (0 = 256, never used). |
| | `$FF $FF dur` | **rest**: retrigger at period `$7FF` (131 kHz, inaudible). NRx4 = `$FF` also sets length-enable, so the channel turns itself off after 250 ms (NRx1 length = 0). |
| CH4 | `nr43 dur` (2 bytes) | NR42 = `$79` (vol 7, decay 1), NR43 = value, NR44 = `$80` |
| | `$FF dur` | rest: NR42 = 0 |
| all | `$BB` | end: **restarts all three channels** (§2.3) |

Each stream is followed by one `$00` pad byte (never read). Macros in the asm: `NOTE period, dur`, `REST dur`, `NHIT nr43, dur`, `NREST dur`, `SONG_END`. Note names in the comments use f = 131072 / (2048 − period). The data is in equal temperament with A4 = `$6D6`: all 52 distinct periods are within ±7 cents, except `$15A` at −17 cents.

### 2.3 Looping

There's no loop command. The first channel to read `$BB` jumps to `MusicRestartAll` (`$337C`). That reloads all three pointers from their starts, sets all timers to 1 and re-runs the tick from CH1. Two consequences:

- **The song's period is set by whichever channel ends first.** Songs 0, 10 and 12 have channels of slightly different lengths, so the tail of the longer channel is never heard (song 0: CH2 2366 vs CH1 2368, CH4 2367; song 10: CH2 320 vs CH1 328; song 12: CH2 594 vs CH1 595).
- **Every song loops forever.** Jingles keep repeating until the game requests another song or calls `SndStop`.

Songs 1–16 share one CH4 stream, `SharedNoise` (`$5A3D`): a single 1-tick hit (NR43 = `$08`) followed by 3775 ticks of rest. It's longer than every tone channel, so it never reaches its own `$BB`. In practice each song (re)start gets **a short noise click** on its first tick, including the "silent" song 15.

### 2.4 Songs

| # | CH1 / CH2 / CH4 | Loop (ticks) | Length | Use |
|---|---|---|---|---|
| 0 | `$4527` / `$4B17` / `$4FD8` | 2366 | 72.8 s | **in-game street music** (confirmed; the only song with its own drum track) |
| 1 | `$5249` / `$5338` / shared | 576 | 17.7 s | bank 3/4 `$43E9`, `$4420`, `$4457`, `$4574` (not identified) |
| 2 | `$5412` / `$5516` | 528 | 16.2 s | **unused** |
| 3 | `$4000` / `$404D` | 128 | 3.9 s | **unused** |
| 4 | `$58D8` / `$58FB` | 46 | 1.4 s | **unused** |
| 5 | `$409A` / `$40B1` | 32 | 1.0 s | **unused** |
| 6 | `$40C8` / `$4100` | 104 | 3.2 s | title / high-score screen (confirmed) |
| 7 | `$591E` / `$5959` | 64 | 2.0 s | **unused** |
| 8 | `$4138` / `$4167` | 64 | 2.0 s | **unused** |
| 9 | `$4187` / `$41C5` | 96 | 3.0 s | **unused** |
| 10 | `$41FA` / `$42BC` | 320 | 9.8 s | route select, "The Daily Sun" (confirmed) |
| 11 | `$430C` / `$4353` | 1218 | 37.5 s | ROM0 `$06AC` (not identified) |
| 12 | `$439D` / `$4465` | 594 | 18.3 s | bank 8 `$5B3E` (not identified) |
| 13 | `$55B1` / `$5757` | 512 | 15.7 s | ROM0 `$1657` (not identified) |
| 14 | `$586A` / `$589C` | 24 | 0.74 s | ROM0 `$072B`, `$3889`, `$38F7`, `$394C` (+ copies in banks 1–7) |
| 15 | `$58CE` / `$58D3` | 64 | 2.0 s | **rests only = music off.** Used on a crash and before game over (confirmed); `PlaySong0F` wrapper |
| 16 | `$5994` / `$59ED` | 192 | 5.9 s | ROM0 `$0770` (not identified) |

"Unused" means there's no `PlaySong` call with that id anywhere in the ROM. Every call site loads A with an immediate, so the list is complete.

---

## 3. Samples

### 3.1 Sample table (`$34E4`, 14 × 8 bytes)

`db priority, 0` / `dw start, end` / `db bank, 0`. Byte 1 and byte 7 are always 0 and never read. **There's no per-sample rate field.**

| # | Prio | Bank | Range | Bytes | Blocks heard | Duration | Requested from |
|---|---|---|---|---|---|---|---|
| 0 | 4 | `$3C` | `$4000–$43FE` | 1023 | 63 | 0.65 s | bank 8 `$5F0A`, `$5F50`: crash (comes right before song 15) |
| 1 | 1 | `$3C` | `$43FF–$457D` | 383 | 23 | 0.24 s | bank 8 `$6BC6`: most frequent in-game sound, probably the paper throw |
| 2 | 1 | `$3C` | `$457E–$4EBA` | 2365 | 147 | 1.51 s | bank 8 `$6224`, `$6291` |
| 3 | 1 | `$3C` | `$4EBB–$5545` | 1675 | 104 | 1.07 s | **unused** |
| 4 | 3 | `$3D` | `$4000–$46AD` | 1710 | 106 | 1.09 s | **unused** |
| 5 | 1 | `$3D` | `$46AE–$5167` | 2746 | 171 | 1.75 s | bank `$1B` `$46ED` |
| 6 | 1 | `$3D` | `$5168–$5817` | 1712 | 106 | 1.09 s | bank `$1B` `$4609` (periodic during play) |
| 7 | 2 | `$3E` | `$58FA–$5C6F` | 886 | 55 | 0.56 s | bank 8 `$6078` |
| 8 | 1 | `$3D` | `$5818–$60D7` | 2240 | 139 | 1.43 s | bank 6 `$402E` |
| 9 | 1 | `$3D` | `$60D8–$6568` | 1169 | 73 | 0.75 s | bank 8 `$6E1F`, `$6E4E`, `$6E60`, `$6E75` (hits) |
| 10 | 1 | `$3E` | `$4000–$58F9` | 6394 | 399 | 4.09 s | **unused** (the longest sample) |
| 11 | 2 | `$3E` | `$5C70–$6100` | 1169 | 73 | 0.75 s | bank 8 `$6C51`, `$6D3D`, `$6D79`, `$6DB5` (hits). First 247 bytes identical to #9. |
| 12 | 2 | `$3E` | `$6101–$62D2` | 466 | 29 | 0.30 s | bank 8 `$6C6D`, `$6C8F`, `$6CB1`, `$6D05`, `$6DFA` (hits) |
| 13 | 2 | `$3E` | `$62D3–$6697` | 965 | 60 | 0.62 s | **unused** |

The ranges are back to back and not 16-byte aligned (they look like raw converter output). Format: 4-bit unsigned, 2 samples per byte, high nibble first (wave RAM order). Played at NR32 = `$20` (100 %).

### 3.2 Playback and the actual sample rate

`PlaySample` stores start/end/bank/priority and turns the CH3 DAC off. Then **every timer IRQ** (97.52 Hz) does this:

1. `ptr += 16`. If `ptr ≥ end`, the sample is over (§3.3).
2. CH3 DAC off, copy 16 bytes from `ptr` to wave RAM `$FF30`, DAC on.
3. NR33 = `$CB`, NR34 = `$85` (period `$5CB`, trigger), unless `wSampleMute` ≠ 0.

So the driver has **one fixed rate for every sample**, and it involves two different clocks:

| Quantity | Value |
|---|---|
| CH3 sample clock, period `$5CB` | 2097152 / 565 = **3711.8 Hz** (32 samples in 8.62 ms) |
| Data consumed (32 nibbles per IRQ) | 32 × 97.524 = **3120.8 Hz** |
| One IRQ | 10.254 ms ≈ 38.06 CH3 periods |

Within each 10.25 ms tick, CH3 plays the 32 new nibbles at 3712 Hz. Then, for the remaining ~6 periods, it wraps around and replays the start of the same block until the next IRQ retriggers it. Per Pan Docs, a trigger starts at nibble 1 and the first period outputs the stale sample buffer. So what you hear per tick is: stale, 1 … 31, 0, 1 … ~5. The effects are:

- **Local pitch/speed is that of 3712 Hz**, but **overall duration is that of 3121 Hz.** Material sampled at 3121 Hz sounds ~19 % (3 semitones) sharp. Material sampled at 3712 Hz keeps its pitch but is stretched by 19 % with a stutter.
- The retrigger and DAC toggling 97.5 times a second add a **97.5 Hz buzz** component to every sample.

I found nothing in the driver or game code that varies the rate per sound: NR33/NR34, TMA and TAC are written only at the sites above, and the speed mode never changes. The "slightly differing rates" you hear are therefore most likely the source material: each sample was presumably converted at its own rate and is played through this one fixed path, plus the stutter. From the ROM alone I can't tell which of 3121 Hz or 3712 Hz the samples were meant for. For extraction, the raw data at **3121 Hz gives the in-game duration**, and the `_ingame` renders reproduce the actual output (§6).

### 3.3 Priority, parking and resume

- A new sample replaces the current one only if its priority is **strictly higher** (`wSampPrio − new < 0`). Idle is priority 0.
- Otherwise `SampQueue` copies its table entry into slot 1 if that's free, else slot 2 if *slot 1 is busy and slot 2 free*, else drops it.
- **Parked slots keep running in the background:** each IRQ, `SampSlotAdvance` adds 16 to the slot pointer and frees the slot when it passes the end. So a parked sample is "virtually" playing.
- When the current sample ends: DAC off, priority 0, then the slot with the higher priority (slot 1 on ties) is resumed via `PlaySample` with A = `$FF`, **from its current position**, and that slot is freed. The resumed sample starts copying on the next IRQ, so there's always **one silent tick** at the handover.

Confirmed in PyBoy by injecting calls (§6): main = #0 (prio 4), then #1 → slot 1, then #2 → slot 2. When #0 ended, #2 resumed exactly from its parked pointer + 16.

---

## 4. Game interface

- **Boot:** `$01A8` double speed → `$01BB` `SndInit` (CH1/CH2 retriggered at `$7FF`, CH3/CH4 DACs off, timer IRQ masked; then TIMA/TMA/TAC, NR52 = `$8F`, NR51 = `$FF`, NR50 = `$77`).
- **Main loop entry** `$16E3`: wMusicEnable = wSampleEnable = 1, `SndStop` + `SndInit`.
- **Screen changes:** `SndStop` (clears IE bit 2, so **music and samples both freeze**) and `SndResume` (sets IE bit 2) bracket loading code at many sites in banks 0–7. `SndResume` doesn't reset anything: the song carries on from where it froze.
- `PlaySong` / `PlaySample` are called directly with an immediate id. Bank 8 holds most of the gameplay SFX calls.
- **Bank switching:** the game writes `wCurBank` before `$2000` (`$188F`), and the ISR restores from `wCurBank`, so an IRQ between the two writes is harmless.

---

## 5. Quirks and bugs

1. **Block 0 of every sample is never heard.** `PlaySample` sets `ptr = start`, and the ISR adds 16 *before* copying. The first 32 nibbles of all 14 samples are skipped. Confirmed: sample 1 starts at `$43FF`, first block copied = `$440F`.
2. **Reads past the end.** The last block is used whenever `ptr + 16 < end`, so up to 15 bytes of the next sample (or of whatever follows) are played as the tail.
3. **Two clocks for one sample stream** (3712 Hz playback vs 3121 Hz consumption): wrap-around stutter plus 97.5 Hz buzz (§3.2).
4. **Slot 2 freezes when slot 1 is empty.** `SampSlotAdvance` starts with `ld a,[bc] / jr z` and nothing sets the flags. For slot 2, Z comes from slot 1's processing: when slot 1 is empty, `SubHLDE` (16 − 0) leaves Z set, so slot 2 is skipped. A sample parked in slot 2 stops advancing as soon as slot 1 is free, and later resumes from where it froze instead of where it "should" be. Confirmed in PyBoy (slot 2 stuck at `$46BE` from the tick slot 1 ended). Slot 1 itself always runs: the caller's `and a` on wSampleEnable leaves NZ.
5. **First channel to end restarts the song** (§2.3), so the tails of songs 0, 10 and 12 are cut.
6. **No one-shot songs:** song 15 ("off") and the jingles loop. Every song start, including "off", gets the shared noise click.
7. **Rests are notes:** period `$7FF` with a trigger, and length enable from the `$FF` high byte.
8. **`ld a,[$0026]` / `ld a,[$0025]`** at `$32D3`/`$32DA` read ROM (both `$00`) instead of NR52/NR51 (missing `h`). They're harmless because the results are ORed with `$8F` / `$FF` and written back every block.
9. **Non-atomic `PlaySample`:** the main thread writes pointer, end and bank one byte at a time with the timer IRQ live. An IRQ in the middle could copy one block with the new pointer and the old end/bank. Not observed.
10. **Dead code/data:** `TIMA = 0` immediately overwritten (`$30F7`); `jr nz,+0` (`$3238`); wSampStart is write-only; sample entry bytes 1/7 and 9 bytes per song entry are unused.
11. **`SndStop` silences by triggering:** CH1/CH2 get period `$7FF` + trigger (with length enable, so they end 250 ms later), CH3/CH4 DACs off.
12. **The unused normal-speed routine `$01F7`** writes `$00FF`/`$0000` instead of `$FFFF`/`$FF00`. If it were called, the timer and with it all music and samples would run at half speed.
13. The tails of banks `$3B–$3E` after the sound data are leftover fill shared with banks `$39–$3A`. They're not audio. In particular, bank `$3C` `$5546–$7FFF` looks like song data only because it's a byte-identical copy of bank `$3B` at the same addresses.

## 6. Verification

- **Byte-exact rebuild** (`tools/cmp_ranges.py`, all six ranges).
- **Timer rate:** 97.55 Hz measured in PyBoy (CGB mode, KEY1 = `$80`, TMA = `$AC`): 1.63 IRQs per frame, pattern 2-2-1.
- **Music:** all 17 songs, forced via a hook on `PlaySong`, 2900 music ticks each (past song 0's loop at 2366). Every period/NR43 value the ISR loads, and the tick it loads it on, matches an exact model walk of the parsed streams, including the restart-all behaviour (`verify/vmusic.py`).
- **Samples:** block sequence for sample 1 (23/23 blocks, block 0 skipped, one tick latency), priority parking and resume, and quirk 4 (`verify/vsample.py`).
- **In game:** title/high-score → song 6, route select → song 10, start of street → song 0, crash → sample 0 then song 15, game over → song 15; samples 1, 6, 9, 11 and 12 heard during play; resume events (`A = $FF`) occur in normal play.
- **Not verified:** the `_ingame` WAV renders model CH3 from Pan Docs behaviour. PyBoy's APU doesn't output CH3 for this retrigger pattern, so they weren't compared against emulator or hardware audio. The roles of songs 1, 11–14 and 16 and most samples are still unidentified, and nothing was checked on hardware.

## Files (in `GBAudioLab\PBGBC`)

- `Paperboy_SoundDriver.asm`: labelled, commented RGBDS source with music/sample macros, byte-exact
- `samples/sample_XX.bin`: raw sample data (INCBINed by the asm)
- `wav/sample_XX_raw3121.wav` (all nibbles of the range, 8-bit, 3121 Hz) and `wav/sample_XX_ingame.wav` (44.1 kHz render of the driver's actual output)
- `tools/`: `sm83.py`, `pbparse.py` (data parser), `gen_pb.py` (generates the asm), `pbsamples.py` (WAV export), `cmp_ranges.py`
- `verify/`: PyBoy scripts used for §6

Regenerate: `python tools/gen_pb.py "Paperboy (U) [C][!].gbc" .` and `python tools/pbsamples.py <rom> wav`. The verify scripts read the ROM path from `PB_ROM` (needs `pip install pyboy`).
