# RADriver — Aggressive Inline (E) build
## Disassembly, byte-identical rebuild and emulator-verified model

*A companion to **`radriver-technical-reference.md`**. That document surveys the engine across
five games. This one documents a single build in full: the R2 revision as linked in Aggressive
Inline. Names are descriptive because the ROM has no symbols. Addresses are GBA bus addresses.
Claims read directly from the code are stated plainly; deductions are marked* (inferred).

**Subject file**

| File | Header | SHA-1 |
|---|---|---|
| `Aggressive Inline (E) (M3).gba` (8 MiB) | `AGGRESSIVE I` / `AILP` | `05ab06b8988d0bb6f037b121f73bc40644aff4e8` |

**What was done**

* A recursive-descent disassembly covers the whole driver: 26 Thumb functions (2636 bytes) and 2 ARM
  routines (844 bytes) that run from IWRAM. Every byte of the code range is either an instruction, a
  literal-pool word, a jump-table entry or one of 17 alignment halfwords.
* The driver, its constant tables, the sound bank, all 30 effects, all 16 music streams and their
  131 ADPCM blocks were turned into GNU-as source. Linked at the original addresses, the source
  rebuilds **8 ranges, 2 777 570 bytes, byte-identical** to the ROM (§6).
* `radriver_model.py` is a Python model of the driver. The ROM's own code was run in an ARM emulator
  (unicorn, ARM926 core) side by side with the model. **Every byte of driver RAM** (ring buffer,
  accumulator, voices, variables, pitch table, sequencer tracks) is identical after `snd_init` and
  after each of **20 431 `snd_update` calls**. That covers the game's own use of the driver, a
  synthetic song that exercises the sequencer this game never uses, and a corruption case (§8.1).

---

## 1. Summary

Aggressive Inline runs RADriver at **11 025 Hz with 2 voices**: one for music and one for sound
effects. All music is **streamed ADPCM**: 16 streams built from 131 blocks, using 2.56 MB of ROM.
The 30 effects are 8-bit PCM. The MIDI-derived sequencer is linked in and runs every frame, but no
song is ever started, so `seq_tick` returns at its first test. Seven of the 26 Thumb functions
are dead code. Error reporting is compiled out: the driver's `dbg_printf` calls go to a
three-instruction stub, so allocation failures and voice exhaustion are completely silent.

---

## 2. Where everything is

| Range | Bytes | Contents | Source file |
|---|---|---|---|
| `08000284–08031690` | 201 740 | 30 PCM effects, each with a 768-byte guard band, then the bank | `radriver_data.s` |
| `0805B284–0805BCD0` | 2 636 | Thumb driver (26 functions) | `radriver_thumb.s` |
| `080690A4–0806AF5C` | 7 864 | block tables, order lists, stream table | `radriver_data.s` |
| `0806DDA4–0806DDAC` | 8 | long-call pointers to the two IWRAM routines | `radriver_rodata.s` |
| `0806DDC0–082DF502` | 2 561 858 | 131 ADPCM music blocks | `radriver_data.s` |
| `087E0894–087E0B28` | 660 | MIDI note-frequency table, 4 error strings | `radriver_rodata.s` |
| `087E0BB0–087E1358` | 1 960 | OKI ADPCM tables (49×16 diffs, 49×8 next index) | `radriver_rodata.s` |
| `087E2070–087E23BC` | 844 | ARM mixer and downmix, linked for `03006808` | `radriver_arm.s` |

The ARM routines are part of the game's single IWRAM `.data` image (ROM `087E1594` →
`03005D2C–03007204`), which crt0 copies at boot. The driver's variables lie just below that
image (`.bss`, `03005CB0–03005D2C`) and at `03001298–030012AC`. The game's ARM long-call table at
`0806DD90` is shared with other modules. Only its entries `0806DDA4` and `0806DDA8` belong to the driver.

**External routines** (game and libgcc, not rebuilt): `__udivsi3` `0805D2C4`, `__umodsi3`
`0805D33C`, `__muldi3` `0805D254`, `__udivdi3` `0805CD88`, `_call_via_r3` `0805CD58`, the game
heap `iwram_alloc` `080534D8` / `exram_alloc` `0805353C` / `mem_free` `080535A0`, and
`dbg_printf` `08050F9C` (`push {r0-r3}; add sp,#16; bx lr`).

The full function map and RAM map are in the data dump, §1–2.

---

## 3. How the game drives it

| Game code | What it does |
|---|---|
| `08048406` (boot) | `snd_init(11025, 2)`, then `snd_setBank(0x08031608)` |
| `080485AE` | calls `snd_timer1IRQ` (Timer 1 interrupt) |
| 6 call sites | `snd_update()`. Each is preceded by a call to `08050D20` *(inferred: the wait for V-blank)* |
| `08042380` `playMusic(n)` | Stops the previous music handle, reads a volume from game state `+0x2B6` (and starts nothing if it is 0), then `h = snd_playStream(table[n])` and `snd_setVolume(h, vol)` |
| `080422E8` `playEffect(id, key)` | **Stops the previous effect**, reads a volume from state `+0x2B4` (and does nothing if it is 0), then `h = snd_playSfx(id, key)` and `snd_setVolume(h, vol)`. Keys used include 60 (`0x3C`), the original pitch |
| `0804242E` / `0804244A` etc. | Pause and resume of the stored handles |

Because the game itself allows only one effect at a time, two voices are always enough.
*(Inferred)* The two volume words are the options-menu music and effect volumes. A volume of 0
means "do not start" rather than "start silently".

---

## 4. This build's numbers

| Quantity | Value |
|---|---|
| Ring buffer | `bufSize = (11025/40 + 15) & ~15 = 288` samples (26.1 ms of latency) |
| IWRAM block | 944 bytes: ring `+0`, accumulator `+288` (s16 ×288), voices `+864` (2×40) |
| EWRAM block | 0x440 bytes: pitch table (128 × u32), then 16 sequencer tracks (36 B each) |
| Timer 0 | reload `0x10000 − 16 780 000/11 025 = 0x10000 − 1521 = 0xFA0F`, so the real output rate is 2²⁴/1521 = **11 030.4 Hz**: everything plays 0.85 cents sharp |
| Timer 1 | cascade + IRQ, reload `−290` at start and `−288` after the first wrap |
| Samples mixed per frame | ≈184.7 (varies 184–186, always even) |
| Pitch, key 60 | step `0x1009D139` = 1.00240: 4.1 cents sharp, because the formula uses 261 instead of 261.63 Hz |
| PCM pitch, effective | a further +9.3 cents from the n+1 mixing loop (§8.3), so ≈ **+14.3 cents** in total with the timer error. ADPCM music is only +0.85 cents |
| Gain | `amp = volume × 256 >> 12` = 0–16; full-scale PCM at volume 256 is exactly unity |

---

## 5. Data

### 5.1 Effects and guard bands

The bank at `08031608` reads `{0 songs, 30 samples, songs = samples = 08031618}`. Every sample is
type 1 (PCM), and only `sfx00` loops (from byte 4543). Each sample is followed by **exactly 768
bytes of guard band**, then zero padding to a 4-byte boundary. The guard band is silence after a
one-shot, and a copy of the first 768 bytes of the loop region after a looped sample.

The guard band exists because the mixer reads past the end of a sample. End-of-sample handling
happens only after a whole frame has been mixed, so a voice reads up to `n × step` bytes past the
end before `voice_mix` frees or wraps it. The guard covers steps up to 768/186 ≈ 4.1, i.e.
**keys up to about 84**. *(Inferred)* A higher key on a one-shot reads past the guard into the
next sample's header and data. The game uses key 60, which overruns by at most 186 bytes.

### 5.2 Streams

Each of the 16 entries at `0806AEDC` is `{Sample **blocks, s16 *order}`; streams 10 and 11 are
identical. Blocks are type 0 (ADPCM, XOR `0xEC`) with no guard band, because the mixer clamps ADPCM
to the block end and continues into the next block within the same call.

There is no loop point. When the mixer reaches `−1` it restarts the order list from entry 0,
**including any intro**. The content tool works around this by writing the looping section out
many times:

| Stream | Entries | Structure (intro, then the repeated section) |
|---|---|---|
| 0 | 174 | 4 intro entries, then a 17-entry section ×10 |
| 1 | 1000 | 6 intro, then 55 ×18 |
| 2 | 89 | 9 intro, then block 0 (a 54-second block) ×80 |
| 4 | 953 | 1 intro, then 56 ×17 |
| 8 | 836 | 4 intro, then 52 ×16 |
| 10, 11 | 144 | 8 ×18 |
| 15 | 91 | 1 intro, then block 1 (38.6 s) ×90 |
| 9 | 55 | ends with block 0 (296 bytes of near-silence) ×12 |
| 3, 5, 6, 7, 13, 14 | 14–74 | through-composed, or only short repeats at the end |
| 12 | 1 | a single 3.6 s block |

So the music returns to its intro only after about 3.5 minutes (streams 10 and 11) to 72 minutes (stream 2).

Every block is decoded from a reset state (predictor 0, smallest step). Many blocks start where the
previous one ended at a large value: for example, stream 0 block 1 ends at 754, and block 2, which
follows it in the order list, starts −10, 20, 83. *(Inferred)* Each join therefore has a ramp of a few samples, heard as a slight
softening or click at segment boundaries.

---

## 6. The sources

```
AI_RADriver/
  src/radriver.inc        externals, RAM variables, I/O registers
  src/radriver_thumb.s    26 Thumb functions -- banner, pseudo-C header, inline comments
  src/radriver_arm.s      snd_mixVoice_arm, snd_downmix_arm (ARM, IWRAM)
  src/radriver_rodata.s   note frequencies (annotated per key), strings, ADPCM tables, pfn table
  src/radriver_data.s     SAMPLE macro; bank, effects, block tables, order lists, blocks
  src/bin/                30 x sfxNN.pcm, 131 x sNN_bMM.adpcm  (payloads for .incbin)
  src/radriver.ld         places every section at its ROM address (IWRAM code: VMA 03006808, LMA 087E2070)
  src/Makefile            make check | make emucheck | make wav
  src/romcheck.py         compares every allocated ELF section with the ROM at its load address
  src/radriver_model.py   reference model on emulated memory
  src/emucheck.py         unicorn harness: ROM code vs model, frame by frame
  src/export_wav.py       WAV export (decoder checked against the model)
  radriver-ai-data-dump.md
  radriver-ai-wav.zip     30 effects, 131 blocks, 16 stream renders (one pass, capped at 300 s)
```

`make check` needs `arm-none-eabi-as`/`ld` (binutils 2.42 was used). Branches and literal pools use
labels throughout. Literal loads carry `@ =symbol` comments, and RAM, I/O and table references are
symbolic. Externals are declared with `.thumb_set` at their ROM addresses.

```
.sfx       08000284 (ROM 08000284)   201740 bytes  identical
.text      0805B284 (ROM 0805B284)     2636 bytes  identical
.streams   080690A4 (ROM 080690A4)     7864 bytes  identical
.pfn       0806DDA4 (ROM 0806DDA4)        8 bytes  identical
.blocks    0806DDC0 (ROM 0806DDC0)  2561858 bytes  identical
.rodata_a  087E0894 (ROM 087E0894)      660 bytes  identical
.rodata_b  087E0BB0 (ROM 087E0BB0)     1960 bytes  identical
.iwram     03006808 (ROM 087E2070)      844 bytes  identical
2777570 bytes checked: ALL IDENTICAL
```

---

## 7. Emulator verification

`emucheck.py` maps the ROM, copies the crt0 IWRAM image, replaces the game heap with two fixed
blocks, and calls the driver's real entry points (`snd_init`, `snd_setBank`, `snd_playStream`,
`snd_playSfx`, `snd_stop`, `snd_pause`, `snd_resume`, `snd_setVolume`, `snd_setPitch`,
`seq_playSong`, `snd_update`). It makes the same calls on the model, and before each update it
writes the same Timer 1 count to both. After every call it compares driver IWRAM and EWRAM byte
for byte, and it compares return values.

| Scenario | Frames | Covers |
|---|---|---|
| 1. Game use | 14 400 (4 min) | `snd_init(11025, 2)`; all 16 streams in turn (15 s each, so every block change and order-list restart occurs); random effects at keys 48–140 with random volumes, including out-of-range ids; pause, resume, stop and pitch changes; cursor steps of 2–450 samples, including ring wraps |
| 2. Sequencer | 6 000 | 8 voices; a synthetic 40-bar song in EWRAM, with AI's effects as programs, that uses every status byte (8x, 9x, Ax, B0–B3, B7, Cx, Dx, Ex, deltas, tempo changes) and a restart every 25 s |
| 3. Repeated update | 31 | §8.1: both corrupt the same pointer to the same value |

All three pass. The WAV decoder in `export_wav.py` was checked against the model's mixer output for
four blocks (stream 0 blocks 0–1, stream 2 block 1, stream 12 block 0), and the two agree sample for
sample.

---

## 8. Findings in this build

**8.1 An update with no cursor movement overwrites voice 0's sample pointer.** If `snd_update`
runs when Timer 1 has not advanced since the last call (or has advanced by exactly a full ring), the
wrap branch computes `n = bufSize`. The PCM mix loop then writes `n+1` accumulator entries, and entry
288 is the first halfword of voice 0 (`Voice.sample`, low half). In scenario 3 the looped `sfx00`
(`08000284`) became `0800FC40`. From then on the voice plays from the middle of unrelated data, using
whatever "header" it finds there. ADPCM voices are not affected, because their loop count is exact.
*(Inferred)* The game always waits for V-blank before calling `snd_update`, so this is latent in
Aggressive Inline. A game that called the update twice in a row would hit it.

**8.2 ADPCM on the accumulate path is skipped** (R2/R3 behaviour, see the survey document §12.2).
The model reproduces the skip and matches the ROM. In this game the music normally owns voice 0.
*(Inferred)* If an effect holds voice 0 when `playMusic` runs, the music lands in voice 1 and
pauses, silently and without advancing, until the effect ends.

**8.3 PCM plays sharp.** The mix loop reads `n+1` source steps for `n` output samples, and the
extra sample is overwritten by the next update. That alone is +9.3 cents at 184.7 samples per frame. With the 261 Hz reference and the timer error,
effects play ≈14.3 cents sharp. ADPCM is unaffected by the n+1 loop.

**8.4 `snd_playSfx` with an out-of-range id returns `sampleCount` (30), not −1.** The game stores
it as a handle. A later `snd_stop(30)` would only stop a voice if handle 30 happened to be live.

**8.5 Smaller items.**
* `snd_shutdown` leaves `snd_exramBlock` stale.
* `snd_cfg.unused` is loaded by `snd_update` and discarded.
* `snd_unused12AA` is written and never read.
* The first Timer 1 period is `bufSize + 2` samples.
* `snd_timer1IRQ` also clears `DMA2CNT`, which the driver never uses.

**8.6 Dead code.** These functions are never called: `snd_setMasterVolume`, `snd_getMasterVolume`,
`snd_halt`, `snd_restart`, `snd_setPitch`, `seq_continue` and `seq_playSong`. The sequencer runs
only as far as its `seq_playing` test. The B0–B3 meta-commands, note handling and track table
nevertheless behave exactly as described in the survey document; scenario 2 checks them against
this build's code.

---

## 9. Reusing this work

* **The other R2/R3 builds.** MO and PM differ from this build by a handful of functions and one
  branch condition (survey §4). Their sources can be generated with the same scripts by changing the
  function map and addresses.
* **Format tools.** `radriver_model.py` already implements the sequencer, so a PK/MO song → MIDI
  converter or a song renderer only needs that game's bank and sample addresses. For accurate
  playback, use the model rather than an idealised mixer: it includes the n+1 pitch effect and the
  ADPCM skip.
