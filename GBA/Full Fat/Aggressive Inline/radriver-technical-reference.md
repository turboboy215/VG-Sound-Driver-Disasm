# RADriver — Full Fat GBA Sound Driver
## Identification survey and technical reference — five-ROM study

*RADriver ("RA Driver") is Full Fat's in-house GBA sound engine. This document confirms
which of the five supplied games use it, explains how the engine works, and sets out how the
revisions found in these games differ from one another. It is based on static disassembly of the five ROMs. A claim is marked
*(inferred)* when it is a deduction rather than a direct reading of the code. Addresses are in the
cartridge address space (`0x08xxxxxx`) or in IWRAM (`0x03xxxxxx`).*

**Subject files** (`…/GBAAudioLab/RA/`)

| Key | File | Header code |
|---|---|---|
| PK | `Punch King - Arcade Boxing (E) (M3).gba` | `APGP` |
| AI | `Aggressive Inline (E) (M3).gba` | `AILP` |
| MO | `Monopoly (E) (M4).gba` | `BUMP` |
| PM | `Pac-Man World (E) (M5).gba` | `BPAP` |
| NF | `Need for Speed - Underground (U) (M4).gba` | `BNSE` |

Companion files: **`radriver-data-dump.md`** holds a decoded listing of every sound bank, sample
header, sequenced song and streamed-music table in all five ROMs. **`radriver-ai-technical-reference.md`**
(with `radriver-ai-data-dump.md`) documents the full disassembly of the Aggressive Inline build. That
build has been rebuilt byte-identically from source, and its driver code has been checked against a
Python model in an ARM emulator. Statements below marked *(verified in AI)* rest on that work.

---

## 1. Executive summary

**All five games use RADriver, Punch King included.** Every ROM contains the same software
mixer architecture, the same 40-byte voice structure, the same voice API, and the same 49-step
ADPCM tables. Four of the five also share the same MIDI-derived sequencer byte-code. Punch King
contains the oldest revision of the engine. Need for Speed: Underground contains a later
branch that was restructured (state moved into a context struct, the sequencer removed) and is
the only build that names the engine in its strings.

**One engine, two music paths.** RADriver offers two ways to play music, and each game uses one of them:

| Path | How music is stored | Used by |
|---|---|---|
| **Sequencer** | A compact, MIDI-derived event stream (note on/off, program change, tempo, loop). Each program is a single PCM sample, played on the software mixer. | Punch King, Monopoly |
| **Segment streamer** | Pre-rendered music cut into ADPCM *blocks*, plus a `-1`-terminated *order list* of block indices that plays them back to back and loops. | Aggressive Inline, Pac-Man World, NFSU |

So **Pac-Man World's compressed streaming is RADriver.** It goes through the same
`voice_startChain` + ADPCM mixer path that Aggressive Inline and NFSU use. NFSU's
`playRADriverCompressedSong()` is the same feature under its real name. AI and Pac-Man World
still contain the sequencer code, but nothing in either game calls it.

**It is not a tracker.** The sequencer is a stripped-down, converted SMF stream with 16 MIDI
channels and no patterns. The only tracker-like element is the streamer's order list, which
reuses blocks the way a MOD order list reuses patterns.

**Mixer.** A software mixer produces **mono** output on DirectSound A only, through DMA1 and
Timer 0. Timer 1 runs in cascade as a hardware play cursor over a self-timed ring buffer. The
PSG channels are never used. There are up to 16 voices (games use 2–12) at a game-chosen rate:
8000, 11025 or 22050 Hz in these titles. Two sample formats are supported: 8-bit signed PCM
(resampled, so it can be pitched) and 4-bit Dialogic/OKI ADPCM (fixed rate, used for streams).

---

## 2. Provenance

* NFSU's licence screen contains, in reverse display order, **"RA Driver / 2001-2003 / Full Fat. /
  All rights reserved."** under the heading "Licensed Technology". NFSU's error strings use the
  API names **`playRADriverCompressedSong()`** and **`playRADriverSound()`**, plus the `[RADriver]`
  prefix. No other build names the engine.
* The four older builds share a distinctive set of error strings with one another, and none of
  them names the engine: `Not enough RAM for sound mixer: requires %i bytes`, `Not enough EXRAM for sound tables: requires %i bytes` (absent in PK),
  `Out of audio channels`, and `End Track Here`.
* Credits: **James Barnard** is credited as audio lead on PK and AI and for "Gameplay & Audio" on PM.
  **Andrew Docking** is credited for "Engine Support" (PK), "Programming" (AI) and "Technology"
  (PM). None of these games names the driver's author. What "RA" stands for was not found.
* The NFSU copyright range of 2001–2003 is consistent with PK holding the oldest code.

---

## 3. Evidence of shared code

| Marker | PK | AI | MO | PM | NF |
|---|---|---|---|---|---|
| Error-string block (`sound mixer` / `Out of audio channels` / `End Track Here`) | ✓ (no EXRAM line) | ✓ | ✓ | ✓ | — (`[RADriver]` strings instead) |
| `snd_init`: rate clamped to `0xABEA`, voices to 16, voice stride `0x28` | ✓ | ✓ | ✓ | ✓ | ✓ (voices ≤16, stride `0x28`) |
| Same DMA1/TM0/TM1 setup (`SOUNDCNT_H=0x0B04`, `DMA1CNT=0xB6000000`, `TM1=0xC4…`) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Voice API (start, startChain, find, stop, pause, resume, setVolume) matched by opcode signature | ✓ | ✓ | ✓ | ✓ | ✓ |
| Sequencer dispatch (`status>>4 − 8`, 6-way jump table) | ✓ | ✓ | ✓ | ✓ | — |
| Pitch table built as `freq[k]·11025·2¹²/261/rate` | ✓ | ✓ | ✓ | ✓ | ✓ (2048 entries) |
| 49×16 OKI ADPCM step table, byte-identical | `0x087E02E0` | `0x087E0BB0` | `0x082AAB38` | `0x082DA5F0` | `0x08622D48` |
| ADPCM byte `XOR 0xEC` | — | ✓ | ✓ | ✓ | ✓ |

Opcode-level similarity of the Thumb module against AI's (mnemonics compared, branch targets and
literal offsets masked): MO 0.82, PM 0.76, PK 0.69. Most of the difference comes from the
functions MO and PM add (§4). The ARM mixers of AI, MO and PM are instruction-for-instruction
identical apart from addresses and one branch condition (§12.4).

---

## 4. Revisions and lineage

| | **R1** | **R2** | **R3** | **R2-N (branch)** |
|---|---|---|---|---|
| Game | PK | AI | MO, PM | NF |
| State | Globals; pitch table and track table **static in IWRAM** | Globals; pitch table (0x200) and track table (0x240) in a **0x440-byte EXRAM block** | as R2 | **Single context struct** (pointer at `0x03006B3C`), caller supplies the RAM |
| Ring buffer size | `rate/50`, rounded up to 16 | `rate/40`, rounded up to 16 | as R2 | Fixed `0x120` (288) |
| Timer 0 clock constant | `0x01000AE0` (16 780 000) | `0x01000AE0` (at 11 025 Hz: reload `0xFA0F`, real rate 11 030.4 Hz) | **`0x01000000`** (16 777 216, exact) | Hard-coded `0x80FA0F` (11 030.4 Hz, the same value) |
| Mix rate | Game-chosen | Game-chosen | Game-chosen | **Fixed 11 025 Hz** |
| ADPCM encoding | Raw nibbles | Bytes `XOR 0xEC` | as R2 | as R2 |
| ADPCM mixed when not the first active voice | ✓ | **✗ (skipped, §12.2)** | ✗ | ✓ (fixed) |
| End of order list (`-1`) | Stream stops | **Loops to the start of the list** | as R2 | as R2 |
| Downmix loop count | n+1 | n+1 | **n (fixed)** | n+1 |
| Pitch resolution | 128 semitone steps | 128 | 128 | **2048 steps (1/16 semitone)** |
| Sequencer | ✓ | ✓ (present, unused) | ✓ (MO uses it; PM does not) | **Removed** |
| Extras | — | — | Full stop and restart of the sound hardware; wrap counter in the Timer 1 IRQ | Workspace-size queries, `getState`, `hasLooped` (voice `+0x26`), debug-print callback (ctx `+0x44`), separate IWRAM workspace for the mixer code |

*(Inferred)* R3 and NF both descend from R2 but independently: NF carries the n+1 downmix that R3
fixes, while R3 keeps the ADPCM restriction that NF removes.

---

## 5. Per-game configuration and entry points

| | PK | AI | MO | PM | NF |
|---|---|---|---|---|---|
| `snd_init(rate, voices)` call | 22050 Hz, 12 | 11025, 2 | 11025, 8 | 8000, 2 | (fixed 11025), 4 |
| Music path | sequencer | stream | sequencer | stream | stream |
| `snd_init` | `0813AE04` | `0805B3C8` | `080A1500` | `0808FD08` | `08026CB0` (`init(iwramWork, ctx, voices)`) |
| `snd_setBank` | `0813B2C4` | `0805B99C` | `080A1BE0` | `080903E8` | `08027218` |
| `snd_update` (per frame) | `0813AFDC` | `0805B66C` | `080A1894` | `0809009C` | `08026E8C` |
| `voice_mix` | `0813AF94` | `0805B624` | `080A184C` | `08090054` | `08026E38` |
| `seq_tick` | `0813B3B4` | `0805BAA0` | `080A1CE4` | — | — |
| `seq_playSong` | `0813B338` | `0805BA24` | `080A1C68` | `08090474` | — |
| `snd_playStream` (chain) | `0813B168` (unused) | `0805B80C` | `080A1A50` | `08090258` | `0802703C` / `playRADriverCompressedSong` `08027008` |
| `snd_playSample` | `0813B1C8` | `0805B86C` | `080A1AB0` | `080902B8` | `080270A0` / `playRADriverSound` `08027224` |
| ARM mixer | `030051D4` (ROM `087E1180`) | `03006808` (ROM `087E2070`) | `03004AC4` (ROM `082AC000`) | `03006E10` (ROM `0870B324`) | ROM `08027350`, copied to caller RAM |
| Sound bank | `0812B588` | `08031608` | `0807CCD4` | `0804E850` | `0806ADB8` |
| Stream table | — | `0806AEDC` | — | `080A18FC` | `086585B0` |

R1–R3 copy the mixer into IWRAM with the crt0 `.data` copy loop, and reach it through ROM function
pointers (AI: `0806DDA4` mixer, `0806DDA8` downmix). NF copies it with DMA3 in `init`.

---

## 6. Public API (R2 names are descriptive; NF names come from its strings)

```c
void  snd_init(u32 rate, u32 voices);      // rate ≤ 44010, voices ≤ 16; allocates and starts the hardware
void  snd_setBank(const Bank *b);
void  snd_update(void);                    // once per frame: sequencer tick + mix up to the play cursor
void  snd_timer1IRQ(void);                 // must be hooked to the Timer 1 interrupt (restarts DMA1)
int   snd_playSample(const Sample *s, u32 key);         // returns handle or -1
int   snd_playSfx(u32 index, u32 key);                  // bank->samples[index]; R2: bounds-checked
int   snd_playStream(Sample *const *blocks, const s16 *order);
void  snd_stop(int h);  void snd_pause(int h);  void snd_resume(int h);
void  snd_setVolume(int h, u32 vol);       // 0..256
void  snd_setPitch(int h, u32 key);        // 0..127 (NF: 0..2047)
void  seq_playSong(u32 index);             // index < bank->songCount
```

Handles come from an incrementing 32-bit counter and are stored at voice `+0x18`. Voice
allocation takes the first free voice; it never steals one. When every voice is busy the call
prints `Out of audio channels` and returns `-1`.

`key` is a MIDI note number, and **60 plays a sample at its stored rate**. AI's game code passes
`0x3C` for one-shot effects.

---

## 7. Hardware use and the ring buffer

| Register | Value / use |
|---|---|
| `SOUNDCNT_X` | `0x0080`: master enable |
| `SOUNDCNT_H` | `0x0B04`: DirectSound A at 100 %, left and right, Timer 0, FIFO A reset. DSB and PSG are unused |
| `DMA1SAD/DAD/CNT` | ring buffer → `FIFO_A`; `0xB6000000` = enable, FIFO timing, 32-bit, repeat |
| `TM0CNT` | `0x00800000 | (0x10000 − clk/rate)`: the sample clock |
| `TM1CNT` | `0x00C40000 | (−bufsize − 2)` at start, `−bufsize` in the IRQ; cascade + IRQ, counting samples played |

**RAM.** `bufsize×3 + voices×40` bytes are allocated from the game's IWRAM heap. That holds the
8-bit ring buffer (`bufsize`), a 16-bit accumulation buffer (`bufsize×2`) directly after it, and
the voice array, all cleared with DMA3. R2/R3 additionally allocate 0x440 bytes of EXRAM: a
512-byte pitch table followed by sixteen 36-byte sequencer tracks.

**Timing model.** DMA1 plays the ring continuously. When Timer 1 overflows, the IRQ handler
re-arms DMA1 at the start of the ring. `snd_update` reads `TM1CNT_L` (rounded up to even) as the
play cursor and mixes every sample between the last cursor and the current one. When the ring
has wrapped, it does this as two downmix segments. The CPU therefore always fills the part of the
ring that has just been played, so latency is one ring length: about 25 ms in R2/R3 and 20 ms in R1.
The number of samples mixed varies from frame to frame.

---

## 8. Per-frame flow — `snd_update` (R2)

```
if (!mixerAllocated || !running) return;
seq_tick();                                   // §10
cur = (TM1CNT_L + 1) & ~1;  if (cur == 0x10000) cur = bufsizeNeg;
n   = samples from lastCursor to cur (with wrap split)
voicesMixed = 0
for each voice v (index order):  voice_mix(v, n, masterVol)   // masterVol = 0x100
downmix(writePtr, firstSegment);  if wrapped: downmix(ringStart, secondSegment)
```

`voice_mix` calls the ARM mixer for any voice with `state == 1`. It then handles the end of the
sample: if `pos ≥ end`, the voice either loops (`pos = loopStart + (pos − end) mod (end − loopStart)`)
or is freed (`state = 0`). NF also sets voice `+0x26` bit 0 when a loop wraps.

The **first** voice mixed in a frame *stores* into the accumulation buffer; later voices *add*. The
downmix does `>>4`, clamps to s8 and writes the result to the ring. If no voice played this frame,
it writes silence.

---

## 9. Data formats

### 9.1 Sound bank (16 bytes)

```
+0  u32  songCount          (sequenced songs)
+4  u32  sampleCount
+8  SongEntry *songs        8 bytes each: { u8 *start; u8 *loopTarget; }
+12 Sample   **samples      shared by SFX playback AND sequencer program numbers
```

Banks without sequenced songs (AI, PM, NF) set `songs == samples`.

### 9.2 Sample (16-byte header followed by data)

```
+0  u8   type        0 = 4-bit ADPCM, 1 = 8-bit signed PCM
+1  u8[3] pad
+4  u32  length      bytes of data
+8  u32  loopStart   byte offset; 0 = one-shot. Loop region = [loopStart, length)
+12 u32  0
+16 data
```

Because `loopStart = 0` means "no loop", a whole-sample loop cannot be expressed. The content
tool works around this with `loopStart = 1`: all 11 looped NF samples (engine loops) and two MO
samples use 1. The sample's own rate is never stored. Samples are assumed to be recorded at
11 025 Hz, and key 60 plays them back at that rate.

### 9.3 Sequenced song — event stream

The stream is read a byte at a time. A wait counter (16.16) has `tempo` subtracted from it once
per frame, and events are processed while the counter is ≤ 0.

| Bytes | Meaning |
|---|---|
| `0x00–0x7F hh` | **Delta**: 15-bit big-endian tick count `(b0<<8|b1)`; `counter += delta<<16` |
| `8c kk vv` | **Note off**, channel *c*, key *kk* (*vv* ignored) — stops the voice immediately |
| `9c kk vv` | **Note on**: plays `program[c]` at key *kk*, volume = *vv* (clamped to 256). Ignored if *kk* is already sounding on *c*, or if all 4 slots on *c* are in use |
| `Cc pp` | **Program change**: `program[c] = bank->samples[pp]` |
| `Dc xx` | Channel pressure — skipped |
| `B0` | **Loop**: `ptr = song.loopTarget` |
| `B1 xx` | Skipped (1 operand) |
| `B2 tt tt tt tt` | **Tempo**, big-endian 16.16 *ticks per frame* |
| `B3` | **End marker** — prints `End Track Here` and then **carries on reading** |
| `B4–BF`, `An`, `En`, `Fn` | Status byte consumed with no operands *(so pitch bend etc. must be stripped by the converter)* |

There are 16 channels with up to 4 notes each. The tracks are 36 bytes:
`{Sample *program; struct { u8 active, key, pad[2]; int handle; } slot[4];}`.
Channel 9 has no special treatment. There is no volume, pan, envelope, controller or
pitch-bend handling. Note velocity is the only dynamics control.

All 38 songs in PK and MO begin with `B2` (the tempo starts at 0) and have `loopTarget == start`.
Looping songs end `B0 B3`; MO's ten jingles (songs 11–20) end with `B3` alone.

### 9.4 Streamed music

```
blocks : Sample *[]   — ADPCM samples (type 0), one per musical segment
order  : s16[]        — block indices, terminated by -1
```

Starting a stream (`voice_startChain`) plays `blocks[order[0]]`. When a block runs out partway
through a mix call, the mixer fetches the next index and continues inside the same call, so the
join is seamless. ADPCM state (predictor and step index) is **reset at every block**, which means
each block is encoded independently. Reaching `-1` loops back to `order[0]` in R2 and later, and
ends the stream in R1. The stream tables used by the games are 8-byte `{blocks, order}` pairs (§5).

### 9.5 ADPCM

The ADPCM is **Dialogic/OKI (VOX) ADPCM** with 49 step sizes, a 12-bit predictor clamped to
[−2048, 2047], and the standard index adjust `{−1,−1,−1,−1,2,4,6,8}`. The tables are stored
pre-expanded: `diff[49][16]` (s16, `= step·(2m+1)/8`, signed by bit 3) and `next[49][8]`.
The high nibble is decoded first. Output is `(pred >> 3) × amp`. From R2 onward every data byte
is XORed with `0xEC` before decoding. There is no resampling: one byte gives two output samples
at the mix rate, so blocks are authored at the game's mix rate.

### 9.6 Pitch

`step[k] = freq[k] · 11025 · 2¹² / 261 / mixRate`, stored as **4.28 fixed point**, with
`freq[]` = the MIDI note-frequency table in 16.16 (AI `087E0894`; `freq[60] = 261.626 Hz`). NF uses
a 2048-entry table (`08620C50`, 16 steps per semitone, `freq[960] = 261.626`). Key arguments are
clamped to 127 (or 2047 in NF). *(Inferred)* NF's finer table suits continuously varied engine
pitch for its looped engine samples.

### 9.7 Voice (40 bytes)

```
+0x00 Sample *sample        +0x14 s16 adpcmPredictor
+0x04 u8 *pos               +0x16 u8  state (0 free, 1 play, 2 paused)
+0x08 u32 step (4.28)       +0x17 u8  adpcmStepIndex
+0x0C u32 posFrac           +0x18 int handle
+0x10 u16 volume (0..256)   +0x1C Sample **chainBlocks
                            +0x20 s16 *chainOrder
                            +0x24 u16 chainIndex   +0x26 u16 flags (NF: bit0 = looped)
```

Gain is `amp = volume × master >> 12`, where master is `0x100` (so amp is 0–16). The mix is then
`acc += s8 × amp` for PCM and `acc += (pred>>3) × amp` for ADPCM.

---

## 10. NF context struct (partial)

`init(iwramWork, ctx, voices)` takes two blocks of work memory from the caller. The size of each comes from a query function: `iwramSize() = 0x6A8` and
`ctxSize(n) = n×40 + 0x2048`. The ARM mixer is DMA-copied into the IWRAM block.

```
+0x08 u8 voicesMixed   +0x09 u8 voiceCount   +0x0C Bank*   +0x10 ring   +0x14 writePtr
+0x18 accum            +0x1C u16 bufsize      +0x1E u16 −bufsize            +0x20 u16 master
+0x24 Voice*  (= ctx+0x2048)   +0x28 rate     +0x2C lastCursor   +0x30 pitch table (= ctx+0x48)
+0x34 handle counter   +0x38 IRQ wrap count  +0x3C mixer fn   +0x40 downmix fn   +0x44 debugPrint fn
```

---

## 11. Content inventory

| | Samples (bank) | Looped | Sequenced songs | Streams |
|---|---|---|---|---|
| PK | 100 PCM8 | 7 | 17 (all looping, 16–105 s) | — |
| AI | 30 PCM8 | 1 | — | 16 table entries (10 and 11 identical), 1–17 blocks each |
| MO | 49 PCM8 | 6 | 21 (11 looping themes, 10 jingles) | 1 call site only (see §12.6) |
| PM | 29 PCM8 | 0 | — | 6 streams, 6–11 blocks, ≈30–45 s per pass at 8 kHz |
| NF | 24 PCM8 | 11 (`loopStart=1`) | — | 4 streams, 11–31 blocks, ≈400 KB each |

The full tables are in `radriver-data-dump.md`.

---

## 12. Bugs, quirks and anomalies

**1. `B3` does not stop the song.** `End Track Here` is only a debug print. MO's ten
non-looping jingles end with `B3` and are followed by alignment padding (`00 00` = a zero delta)
and then the *next song's* data. *(Inferred)* The game must stop jingles itself, or playback
runs on into the following song; after MO song 20, the next bytes are sample 0's header and PCM data.

**2. R2/R3: ADPCM is only mixed as the first active voice.** On the accumulate path (every voice
after the first) the mixer skips type-0 samples entirely, and the position does not advance.
The skip is *(verified in AI)*. *(Inferred consequence)* In AI and PM, music silently pauses whenever a lower-numbered voice
is playing an effect, and resumes when that voice frees. The design works only because music is
started first, so it lands in voice 0. R1 and NF mix ADPCM on both paths.

**3. Off-by-one loop counts.** The PCM mix loop runs `n+1` iterations for `n` output samples in
every revision, and the downmix writes `n+1` bytes in R1, R2 and NF (R3 fixes the downmix only).
The extra accumulated sample is overwritten on the next frame, but the PCM source position has
already advanced one extra step, so pitched samples play `(n+1)/n` sharp *(verified in AI)*. That is
+9.3 cents at 11 025 Hz (184.7 samples per frame), about +5 cents at 22 050 Hz and +13 cents at 8000 Hz.
It adds to the +4.1 cents of the 261 Hz reference (§9.6) and, in R1/R2, the timer rounding (§4).
ADPCM is decoded exactly `n` samples and is unaffected.

**4. NF song index bound.** `playRADriverCompressedSong` accepts indices 0–4 (`cmp #4; bhi`),
but the table has only four valid entries. Entry 4 is `{0x00000000, 0x00000FD2}`.

**5. No whole-sample loop.** See §9.2. `loopStart = 0` cannot mean "loop from the beginning".

**6. MO stream call.** MO's single `snd_playStream` call passes the same address (`080A6038`) as
both block table and order list. The resulting block pointer is `0xFFFF0000`. Whether that path is
reachable was not checked.

**7. ADPCM headroom.** At volume 256 a full-scale ADPCM stream reaches ±255 after the downmix
shift and clips at ±127. *(Inferred)* Stream volumes have to be kept at or below about 128.

**8. Unsequenced status bytes.** Status bytes `A`, `E` and `F` and the unused `Bx` codes consume no
operands, so stray MIDI data would desynchronise the stream. The shipped data contains none.

**9. A full-ring update corrupts voice 0** *(verified in AI)*. If `snd_update` runs when the
Timer 1 count has not moved since the previous call, the wrap branch computes `n = bufSize`. The
n+1th PCM accumulator write then lands on the low halfword of voice 0's `sample` pointer, which
follows the accumulator in the same heap block. AI only calls the update after waiting for V-blank,
so this is latent there *(inferred)*. See the AI document, §8.1.

**10. Guard bands** *(AI)*. Every PCM sample is followed by 768 bytes of silence, or by a copy of
its loop region, because the end of a sample is only handled after a whole frame has been mixed. That
covers pitch steps up to about ×4.1 (keys up to about 84 at 11 025 Hz).

**11. Errors are compiled out** *(AI)*. The error strings are passed to a game `printf` that is an
empty stub in the release build, so allocation failures and "Out of audio channels" are silent.

---

## 13. Notes for tooling and the next disassembly

* **Sequenced → MIDI.** §9.3 is enough to write a lossless converter for PK and MO: map
  delta → MIDI delta (the tempo is ticks/frame at 59.7275 Hz), `B2` → tempo meta event,
  `B0` → loop marker, and programs → bank sample indices.
* **Streams → WAV.** Decode each ADPCM block (after XOR `0xEC` for R2 and later; reset state per
  block) and concatenate them in order-list order at the game's mix rate. AI's order lists are
  long and repetitive (up to 1000 entries), so render one pass up to the `-1`.
* **Disassembly status.** **AI (R2) is done**: there is labelled source, a byte-identical rebuild and an
  emulator-verified model (see `radriver-ai-technical-reference.md`). **PK** would document R1, and
  **NF** the context-struct branch, which also has the only real API names. MO and PM differ from AI
  only in the R3 additions (§4), so the AI generator scripts can be adapted to them directly.
