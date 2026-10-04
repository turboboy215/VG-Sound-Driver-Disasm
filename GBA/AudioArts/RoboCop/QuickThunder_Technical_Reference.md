# QuickThunder — GBA Sound Driver
## Reverse-engineering report and technical reference — 2001 Robocop build

*QuickThunder is the name of the engine itself, not of one game's build of it. This document
analyses the 2001 Robocop build; the V-Rally 3 revision of the same engine is covered in the
companion document.*

**Subject files** (`…/GBAAudioLab/AA/`)

| File | Role |
|---|---|
| `musicd.o` | ELF32 ARM relocatable, 161 128 bytes — the driver, unstripped, 1718 symbol entries |
| `musicd.h` | C/C++ declarations of the five public entry points |
| `music.h` | `#define`s for the 3 songs and 20 sound effects |
| `musicd.bin` | 109 808-byte GBA ROM containing a linked sound-test build |
| `README.TXT` | Integration instructions from the audio programmer |

**Provenance.** QuickThunder was written by **Michael Delaney** at **AudioArts**, a British audio
house active c. 1999–2003, and is the GBA descendant of Delaney's earlier Game Boy Color sound
engine. File timestamps here are 2001-05-10/2001-05-22; `music.h` names Robocop, hostages, a
chainsaw and a flamethrower, so this particular build is the audio driver for the Game Boy Advance
*Robocop* (2001). The README's "speak to Hakkim if you are using the ARM linker" confirms it was
delivered as middleware to client studios rather than written in-house by the game team.

A later revision of QuickThunder ships in **V-Rally 3 (GBA)**, where it gains a software mixer,
a seventh channel and fixes for most of the defects listed in §10. See the companion document
*QuickThunder — V-Rally 3 revision* for that analysis. Everything below describes the 2001
build; where the two revisions differ, the companion document says so.

Everything below was derived from disassembly of `musicd.o` and from the linked image in
`musicd.bin`. Where a claim is an inference rather than a direct read of the code it is marked
*(inferred)*.

---

## 1. Executive summary

This build of QuickThunder is a **hand-written Thumb assembly, register-driving, zero-mixing**
GBA sound driver.
It drives all six GBA audio channels — the four DMG/PSG channels and both DirectSound FIFO
channels — but it never touches a sample buffer with the CPU. The two sample channels are played
by giving DMA1/DMA2 the raw PCM start address and setting a hardware timer to the required
playback rate; the CPU's only involvement is a two-instruction interrupt handler that counts
16-byte FIFO refills and shuts the channel down at the end of the sample.

That design is what makes the README's "0.8% processor usage" claim credible: there is no mixer.
The cost per frame is one linear pass over six small state structures — roughly 3.3 KB of straight-
line Thumb code with no loops beyond table walks of one step each.

Musically it is a **tracker-style engine**: a song is six independent step lists; a step names a
pattern and a transpose; a pattern is a byte-code stream of `(duration, note, instrument)` events;
an instrument on a PSG channel is a set of pointers to small looping **frequency / arpeggio /
combine** tables, which is the classic C64/NES-style "instrument macro" model rather than the
sample-and-envelope model of Nintendo's contemporaneous **MediaPlayer2000** (`m4a`) driver.

Sound effects are not a separate playback path. An SFX is an ordinary pattern that **temporarily
steals one of the six music channels** via a two-slot, priority-arbitrated allocator; the displaced
music sequence keeps being stepped (silently) so it is still in the right place when the effect
ends and the channel is handed back.

---

## 2. Build and link facts

```
musicd.o   ELF32 LSB relocatable, ARM, EABI, interworking enabled
  .text    0x1A9E4 (109 028 bytes)   code AND all read-only data
  .data    0 bytes
  .bss     0xFC   (252 bytes)        all driver state
  .rel.text  391 relocations, all R_ARM_ABS32 (literal pools only)
  undefined symbols: none — the object is completely self-contained
```

There are no `$a`/`$t` mapping symbols and no `.data`; the source is a single hand-written `.s`
file assembled with the GNU assembler, including an AGB SDK register-equate header (the symbol
table is full of absolute `REG_*`, `SOUND_*`, `DISP_*` equates that the driver never uses).
All code is **Thumb**; every relocation is a 32-bit literal-pool word, and literal pools sit
*inline between basic blocks* — which is why a naive linear disassembly of `.text` shows
occasional garbage instructions at labels such as `s1ptrptr`, `FreqTablePTR`, `dma1cntval`.

### Layout inside `musicd.bin`

`musicd.bin` is an AGB-SDK crt0 + a small sound-test `main` + this object.

| Region | ROM offset | Address | Size |
|---|---|---|---|
| Cartridge header | `0x000` | `0x08000000` | 0xC0 |
| crt0 + IRQ dispatcher | `0x0C0` | `0x080000C0` | 0x10C |
| **`musicd.o` `.text`** | **`0x1CC`** | **`0x080001CC`** | 0x1A9E4 |
| sound-test `main`, key reader, `IntrTable` | `0x1ABB0` | `0x0801ABB0` | 0x140 |

`.bss` is linked at **`0x03000000`** (start of IWRAM).

Key absolute addresses in this build:

```
musicd               0x080001CC      FreqTable    0x08000E9C
musicinit            0x08000BE0      sampfreqtab  0x08000F2C
SoundIntDMA1Handler  0x08000D28      InsTab       0x08001430
SoundIntDMA2Handler  0x08000D48      InsTab4      0x080014BC
SFX                  0x08000D8C      PatTab       0x080014E0
                                     songtab      0x0800168C
                                     SFXTab       0x080016F8
                                     sampletab    0x08002524
                                     PCM data     0x08002704 .. 0x0801ABB0
```

Code + tables occupy the first 9 528 bytes of `.text`; the remaining **99 500 bytes (91 % of `.text`) is 8-bit PCM sample data.**

### The sound test in `musicd.bin`

`main` sets `REG_IME=1`, `REG_IE=0x0601` (V-Blank | DMA1 | DMA2), `REG_DISPSTAT=0x18`, calls
`musicinit(0)` and then polls the key pad: **A** = next song, **B** = previous song,
**Right** = next SFX, **Left** = previous SFX. `IntrTable[0]` is a thumb stub that calls
`musicd()`, and `IntrTable[9]`/`IntrTable[10]` are `SoundIntDMA1Handler`/`SoundIntDMA2Handler` —
exactly the arrangement the README prescribes.

---

## 3. Public API

```c
extern "C" void musicd(void);                  // call once per frame
extern "C" void musicinit(int song);           // start song; 0 = silence
extern "C" void SFX(int sfx);                  // trigger sound effect
extern "C" void SoundIntDMA1Handler(void);     // hook to IRQ vector  9 (DMA1)
extern "C" void SoundIntDMA2Handler(void);     // hook to IRQ vector 10 (DMA2)
```

All five are Thumb, AAPCS-compatible (`push {lr}` / `pop {r0}` / `bx r0`), and take/return
nothing but the one `int` argument. They clobber nothing the ABI protects.

**Host obligations** (from `README.TXT`, all confirmed in the code):

1. Install `SoundIntDMA1Handler` at DMA1 and `SoundIntDMA2Handler` at DMA2 in `IntrTable`.
2. Enable `DMA1_INTR_FLAG | DMA2_INTR_FLAG` (and V-Blank) in `REG_IE`, with `REG_IME = 1`.
3. Call `musicinit(0)` once after DMA setup.
4. Call `musicd()` exactly once per frame.

There is no "stop", no pause, no per-channel mute and no master volume entry point.
`musicinit(0)` (song 0 = all-blank step lists) is the only way to stop the music, and it
also clears both SFX slots.

---

## 4. Hardware resources consumed

The driver owns the following and assumes nothing else writes them:

| Resource | Use |
|---|---|
| `REG_SOUND1CNT_L/H/X` (`0x04000060/62/64`) | PSG square 1 — "tone channel 1" |
| `REG_SOUND2CNT_L/H` (`0x04000068/6C`) | PSG square 2 — "tone channel 2" |
| `REG_SOUND3CNT_L/H/X` (`0x04000070/72/74`) | PSG wave — "rdc channel" |
| `REG_WAVE_RAM` (`0x04000090..9F`) | 16 bytes of wavetable, uploaded by `musicinit` |
| `REG_SOUND4CNT_L/H` (`0x04000078/7C`) | PSG noise |
| `REG_SOUNDCNT_L/H/X` (`0x04000080/82/84`) | master mixing and enable |
| `REG_FIFO_A` / `REG_FIFO_B` (`0x040000A0/A4`) | DirectSound destinations |
| **DMA1** (`0x040000BC..C7`) | feeds FIFO A → "sample channel 1" |
| **DMA2** (`0x040000C8..D3`) | feeds FIFO B → "sample channel 2" |
| **Timer 0** (`0x04000100`) | sample-channel-1 playback rate |
| **Timer 1** (`0x04000104`) | sample-channel-2 playback rate |

Timers 2 and 3, DMA0 and DMA3 are left alone. `REG_SOUNDBIAS` is **never written** — the driver
relies on the BIOS/host default (9-bit, 32.768 kHz PWM).

### Values written by `musicinit`

```
REG_SOUNDCNT_L   = 0xFFFF    all four PSG channels to both speakers, max L/R volume
REG_SOUNDCNT_X   = 0xFFFF    master sound enable (bit 7)
REG_SOUNDCNT_H   = 0x7302    DMG mix 100%, DSA+DSB volume 50%,
                             DSA L+R on / Timer 0, DSB L+R on / Timer 1
REG_SOUND1CNT_L  = 0x0008    sweep off
REG_SOUND1CNT_H  = 0x01C0    75% duty, envelope volume 0
REG_SOUND1CNT_X  = 0x8200    restart, freq 0x200
REG_SOUND2CNT_L  = 0x01C0    (same for square 2)
REG_SOUND2CNT_H  = 0x8200
REG_SOUND3CNT_L  = 0x40 → wave RAM copied → 0x80    (bank select, load, enable)
REG_SOUND3CNT_H  = 0x8000    force 75% volume
```

### Values written when a sample note starts

Sample channel 1 (DirectSound A / DMA1 / Timer 0):

```
DMA1CNT      = 0                     stop
TM0CNT       = 0                     stop
DMA1SAD      = sampletab[ins].start
SOUNDCNT_H   = 0x7B02 + volbits      (0x7302 | 0x0800 = DSound A FIFO reset)
DMA1DAD      = 0x040000A0            FIFO_A
DMA1CNT      = 0xF6600004            enable | IRQ | special timing | 32-bit | repeat
TM0CNT       = sampfreqtab[note]     0x0080_xxxx = enable, prescaler 1, reload xxxx
```

Sample channel 2 is identical with DMA2 / Timer 1 / `FIFO_B` and `SOUNDCNT_H = 0xF302 + volbits`
(`0x8000` = DSound **B** FIFO reset).

`volbits` is assembled from a persistent `VolumeSetting` halfword: the channel keeps the *other*
channel's DirectSound volume bit and takes its own (bit 2 for A, bit 3 for B) from the sample's
flag word — so an individual sample selects 50 % or 100 % DirectSound volume.

Playback rate = `16 777 216 / (65536 − reload)` Hz.

---

## 5. Per-frame execution flow — `musicd()`

`musicd()` is one flat, fully unrolled sequence. There are no function calls and no loops other
than the single-step table walks.

```
musicd:
  push {lr}; push {r1-r7}
  chan1   tone / square 1        (0x0000)
  chan2   tone / square 2        (0x01A2)
  chan3   wave  "rdc"            (0x0344)
  chan4   noise                  (0x051A)
  chan5   DirectSound A          (0x0646)
  chan6   DirectSound B          (0x0768)
  effs16  effect slot 1 ghost-step   (0x088C)
  effs2   effect slot 2 ghost-step   (0x093C)
  pop {r1-r7}; pop {r0}; bx r0
```

Every channel block has the same skeleton:

```
 1  seq = *SeqNPTR                    indirection — may point at a music struct
                                      OR at an effect struct if an SFX stole the channel
 2  if (--seq.tempoCounter != 0) goto 6
 3  reload  = seq.tempoReload
    if (--seq.noteLenCounter != 0) goto 5
 4  ---- fetch the next pattern event (see §7) ----
 5  store noteLenCounter
 6  store tempoCounter
 7  if (noteReset != 0) { write envelope register; write restart bit }  ; key on/off
 8  walk the frequency table  → accumulate a 16-bit detune value
 9  walk the arpeggio  table  → signed semitone offset
10  walk the combine   table  → choose freq source
11  write the resulting 11-bit value to the channel's frequency register
```

Two nested counters therefore control time:

* **`tempoCounter`** — frames per *tick*, reloaded from the song's tempo (`tempoReload`).
* **`noteLenCounter`** — ticks until the next event, reloaded from the event's duration byte.

Song 1 and 2 use tempo 7 → one tick every 7 frames ≈ 117 ms at 59.727 Hz, i.e. a 16th note at
**128 BPM**. Song 0 uses tempo 6. SFX sequences always run at tempo 1 (one tick per frame; the
source has an `SFXTempo = 1` equate).

Sample channels 5 and 6 have no steps 7–11: once DMA and the timer are running, the hardware
plays the sample unattended.

---

## 6. RAM map — all 252 bytes of `.bss`

Linked at `0x03000000` in `musicd.bin`. Offsets below are relative to `.bss`.

### 6.1 Channel pointer array (`0x00`–`0x1F`)

```
0x00  Seq1PTR    0x04  Seq2PTR    0x08  Seq3PTR    0x0C  Seq4PTR
0x10  Seq5PTR    0x14  Seq6PTR    0x18  Seqe1PTR   0x1C  Seqe2PTR
```

`Seq1PTR..Seq6PTR` are the **live sequence pointer** for each of the six channels. Normally each
points at that channel's own static struct. When an SFX steals channel *n*, `SeqnPTR` is swapped to
point at an effect struct and the displaced value is parked in `Seqe1PTR`/`Seqe2PTR` — which
doubles as the pointer the "ghost stepper" (`effs16`/`effs2`) advances so the muted music sequence
stays in time. This single indirection is the whole channel-stealing mechanism.

The SFX allocator addresses this array through a literal holding **`.bss − 4`** (`0x02FFFFFC`) and
indexes it with `(channel + 1) * 4`, so channel ids are 0-based (`tonech1=0 … samplech2=5`) while
`0` also serves as the "slot free" sentinel in `EffSeqNChan`.

### 6.2 Sequence struct — channels 1, 3, 4, 5, 6 (20 bytes)

```
+0   u8   tempoCounter        counts down every musicd() call
+1   u8   noteReset           0 = nothing, else byte offset of the envelope value to poke
+2   u16  patternOffset       byte offset inside the current pattern
+4   u32  stepPtr             pointer into the step list
+8   u16  noteAttackValue     instrument's key-on register value
+10  u16  noteReleaseValue    instrument's key-off register value
+12  u8   tempoReload         frames per tick
+13  u8   noteLenCounter      ticks left on the current event
+14..    channel-specific (see below)
```

`noteReset` is literally an *offset*: the key-on/key-off handler does
`value = *(u16*)((u8*)seq + 4 + noteReset)`, so `noteReset = 4` selects `noteAttackValue` and
`6` selects `noteReleaseValue`. Channel 2's struct is packed differently and uses `2`/`4`.

### 6.3 Per-channel modulation state ("Eff" sub-structs)

Channels 1, 2, 3, 4 each carry an "Eff" block that the modulation code addresses with its own
base pointer.

Channel 1 — `Eff1` at `0x2C`:

```
+0  u8  tempoReload (aliased)     +8   u32 freqTablePtr
+1  u8  noteLenCounter (aliased)  +12  u32 arpTablePtr
+2  u16 freqAccumulator           +16  u32 combineTablePtr
+4  u8  freqTimer
+5  u8  arpTimer
+6  u8  note                      (transpose + note byte)
+7  u8  combineTimer
```

Channel 3 (`Eff3` at `0x88`) adds `+20 volTablePtr`, `+24 volReleaseTablePtr`, `+28 volTimer`.
Channel 4 (`Eff4` at `0x6C`) replaces freq/arp/combine with `+2 noiseTimer`, `+4 noiseTablePtr`,
`+12 note`.

Full allocation:

```
0x20 Seq1 / 0x2C Eff1        channel 1 (square 1)
0x40 vars2                   channel 2 (square 2) — repacked layout
0x60 Seq4 / 0x6C Eff4        channel 4 (noise)
0x7C Seq3 / 0x88 Eff3        channel 3 (wave)
0xA8 Seq5 / 0xB4 Eff5        channel 5 (DirectSound A)   0xB8 = DmaCount5
0xBC Seq6 / 0xC8 Eff6        channel 6 (DirectSound B)   0xCC = DmaCount6
0xD0 VolumeSetting           u16, DirectSound volume bits
0xD4 EffectSeq1              SFX slot 1  (16 bytes)
0xE4 EffectSeq2              SFX slot 2  (16 bytes)
0xF4 fakestep1               4-byte synthetic step list for slot 1
0xF8 fakestep2               4-byte synthetic step list for slot 2
```

Effect struct (16 bytes, same first 14 bytes as a sequence struct):

```
+12 u8 tempoReload   +13 u8 noteLenCounter   +14 u8 priority   +15 u8 channel|0x80-when-finished
```

Note `musicinit` deliberately leaves `Seqe1PTR` and `Seqe2PTR` **null**; the ghost steppers are
guarded by `EffSeqNChan != 0`, so the null is never dereferenced.

---

## 7. Data formats

### 7.1 Song table — `songtab`, 36 bytes per entry

```
+0   u16  tempo            frames per tick
+2   u16  channel mask     bit n = enable channel n+1 (all three songs use 0x3F)
+4   u32  ch1 step list
+8   u32  ch2 step list
+12  u32  ch3 step list
+16  u32  ch4 step list
+20  u32  ch5 step list
+24  u32  ch6 step list
+28  u32  unused  (points into the wavetable blob; never read — see §10)
+32  u32  wave-RAM data    16 bytes copied to REG_WAVE_RAM at init
```

`musicinit(n)` reads `songtab + n*36`. **There is no bounds check** and no song count in the
table; the caller must stay within 0..2.

Only channels whose mask bit is set are (re)initialised; unmasked channels are left running
whatever they were doing.

### 7.2 Step list — 4 bytes per step

```
+0  s8   transpose      added to every note byte in the pattern
+1  u8   unused         (always 0 in the shipped data)
+2  u16  pattern number index into PatTab
```

The list has no terminator of its own. It ends because the *last pattern it plays* ends with the
`0xFF` opcode, which carries the address of the step list to continue with — usually the same list,
which is how a song loops.

### 7.3 Pattern byte-code

A pattern is a stream of variable-length events. The first byte is always a duration.

| Encoding | Bytes | Meaning |
|---|---|---|
| `len note ins` | 3 | play `transpose + note` with instrument `ins`, key on |
| `len 0xFF` | 2 | hold — no register writes, envelopes and modulation continue |
| `len 0xFE` | 2 | key **off** — re-poke the envelope register with the instrument's release value and restart |
| `len 0xFD` | 2 | key **on** — re-poke with the attack value and restart (retrigger, same pitch) |
| `0x00 lo hi` | 3 | **end of pattern** |
| `0xFF` + pad-to-4 + `u32` | ≤8 | **end of song** — load a new step list pointer |

`len` is in ticks and must be non-zero. `note` is a semitone index; the source uses `c1 = 0`
equates, so `c1`…`b1` = 0–11, `c4` = 36, `g4` = 43.

**End of pattern** behaves differently depending on who is playing it:

* *music sequence* — `stepPtr += 4`, `patternOffset = 0`: advance to the next step. The `lo hi`
  bytes are ignored (in the shipped data they are simply the next pattern's first bytes).
* *effect sequence* — `loop = lo | hi<<8`. If `loop == 0` the effect **ends**: the channel's
  `SeqnPTR` is restored to the music struct and the slot is flagged finished. If non-zero,
  `patternOffset = loop − 1` and the pattern continues from there — a loop-back byte offset.
  Every shipped SFX uses `loop = 0`.

**End of song (`0xFF`)**: the driver steps one byte past the marker, rounds the address **up to the
next 4-byte boundary**, reads a 32-bit pointer there, and uses it as the new step list, resetting
`patternOffset` to 0. `PAT_32`, the last pattern of song 1's channel-1 list, ends with a pointer
straight back to `LEVEL1_1`.

### 7.4 Instruments

Two tables, selected by channel type:

* `InsTab` (35 pointers) — shared by tone channels 1/2 and wave channel 3. Entries **0 and
  4–26 and 34** are 16-byte *tone* instruments; entries **1–3 and 27–33** are 20-byte *wave*
  instruments. The engine does not type-check: pointing a square channel at `ins_rdclead` would
  reinterpret two table pointers as envelope halfwords.
* `InsTab4` (9 pointers) — noise channel 4 only.

**Tone instrument (16 bytes)**

```
+0   u16  attack value   raw SOUND1CNT_H / SOUND2CNT_L  (duty, length, envelope)
+2   u16  release value  ditto
+4   u32  arpeggio table
+8   u32  frequency table
+12  u32  combine table
```

e.g. `ins_bass1`: attack `0xF2C0` = envelope volume 15, decreasing, step 2, 75 % duty;
release `0x3180` = volume 3, step 1, 50 % duty.

**Wave instrument (20 bytes)** — used by channel 3

```
+0   u32  volume-attack table      +12  u32  frequency table
+4   u32  volume-release table     +16  u32  combine table
+8   u32  arpeggio table
```

**Noise instrument (16 bytes)** — `InsTab4`

```
+0   u16  attack value   raw SOUND4CNT_L (envelope)
+2   u16  release value
+4   u32  noise table    drives SOUND4CNT_H low byte
+8   u32  (loaded into a register and immediately discarded — dead, see §10)
```

The noise channel **ignores the note byte entirely**: all pitch comes from the table.

### 7.5 Modulation tables

All four table kinds share one walker. Each entry begins with a duration in ticks; a duration of
**0** marks the terminator, whose next byte is a **signed 8-bit relative offset** back into the
table (loop point), or `−1`-style self-reference for "hold forever".

| Table | Entry | Fields |
|---|---|---|
| frequency | 3 bytes | `len`, `delta_lo`, `delta_hi` — a signed 16-bit value **added to an accumulator** every tick |
| arpeggio | 2 bytes | `len`, `s8 semitone offset` added to the note before the pitch lookup |
| combine | 2 bytes | `len`, `mode` |
| wave volume | 2 bytes | `len`, high byte of `SOUND3CNT_H` (`0x20`=100 %, `0x40`=50 %, `0x60`=25 %, `0x80`=75 %, `0x00`=mute) |
| noise | 2 bytes | `len`, low byte of `SOUND4CNT_H` (clock shift / width / divider) |

Terminator form: `00 rr` (2-byte tables) or `00 00 rr` in the 3-byte table's slot 3/4, where `rr`
is added to the table pointer. `ff 02` therefore means "duration 255, value 2, and never loop
because the duration never expires" — the idiom used for constant tables such as `normal_combine`
(`ff 02`) and `vol_med` (`ff 40`).

**Combine modes** (this is the pitch-source selector, and the most distinctive part of the engine):

| mode | pitch written to the channel |
|---|---|
| `0` | `freqAccumulator` alone — pure table-driven sweep, note ignored |
| `1` | `FreqTable[note + arp]` alone — pure chromatic pitch, accumulator ignored |
| `≥2` | `FreqTable[note + arp] + freqAccumulator` — chromatic pitch plus vibrato/slide |

The result is masked to 11 bits and written to the channel's frequency register **without** the
restart bit, so vibrato does not retrigger the envelope.

Examples from the shipped data:

```
vibrato_small   03 02 00  03 fe ff  03 fe ff  03 02 00  00 f7
                +2 for 3 ticks, −2, −2, +2, then loop back 9 bytes → a ±2 square vibrato
arp_37          01 00  01 03  01 07            a 0-3-7 major chord arpeggio, one tick per note
vol_whistle     02 60  01 40  01 80  ff 20     25%→50%→75%→100% attack shape on the wave channel
rocket_tab      01 55 01 54 01 53 01 52 01 30 ... ff 56 00 da
                a 20-step noise sweep, then hold, then loop back 38 bytes
```

The noise table byte is built in the source from `courseN`/`fineN` equates: `courseN` are
multiples of 8 from `course14 = 0` to `course1 = 104`, `fineN` are 0–7. The register byte
is `(course * 2) | fine`, i.e. `course` selects the clock shift (bits 4–7) and `fine` the divider
ratio (bits 0–2). *(inferred — the equates are absolute symbols with no surviving use site, but
the arithmetic reproduces every shipped table value, e.g. `0x32` = `course11 (24)*2 | fine6 (2)`.)*

### 7.6 Sample table — `sampletab`, 16 bytes per entry, 30 entries

```
+0   u32  PCM start address
+4   u32  DMA block count — number of 16-byte FIFO refills; length = count * 16 bytes
+8   u32  unused          — a timer word (0x0080FC15 in every entry but #0); leftover from the
                            conversion tool, never read by the driver
+12  u32  volume flags    — bit 2 sets DirectSound A to 100 %, bit 3 sets DirectSound B to 100 %
                            (0xFFFFFFFF = loud, 0x00000000 = 50 %)
```

PCM is **8-bit signed**, mono, uncompressed, concatenated back to back.

### 7.7 Pitch tables

**`FreqTable`** — 72 × `u16`, PSG frequency register values, one per semitone, `note 0 = C2`
(65.4 Hz, register value 44) through `note 71 = B7`. Rate = `131072 / (2048 − x)`.

**`sampfreqtab`** — 61 × `u32`, timer reload + control (`0x0080_xxxx`). Note 36 gives
**8363 Hz** — the classic Amiga/ProTracker C-3 tuning, so samples authored in a tracker drop
straight in. Notes 0–23 are a **byte-for-byte duplicate of notes 24–47**; only 24–60 are unique.
*(inferred: a safety pad so that a downward transpose on a sample channel produces a sane rate
instead of reading off the front of the table.)*

The two shipped sample notes are 36 (8363 Hz, used for speech) and 43 (12 539 Hz, used for the
hit/gunshot/impact effects).

---

## 8. The channel engines in detail

### Channels 1 and 2 — PSG squares

Identical code, different struct packing (channel 2's fields are re-ordered into `vars2`,
presumably a hand optimisation pass that was never back-ported to channel 1).

On a note event: write `note = transpose + noteByte`, copy the instrument's attack/release
halfwords into the sequence struct, copy the three table pointers into the Eff block, reset the
three table timers to 1, clear `freqAccumulator`, and set `noteReset` to the attack offset.

Per tick: key-on/off writes `SOUNDnCNT_H` (envelope/duty) and then `0x8000` to the frequency
register to restart; then the freq/arp/combine walk produces the 11-bit frequency.

### Channel 3 — PSG wave ("rdc")

Different in three ways:

* Its instrument carries **two volume tables** — attack and release. A new note loads the attack
  table; a `0xFE`/`0xFD` event swaps `volTablePtr` to the release table and restarts the timer.
  This is the only channel with a real two-stage envelope, because the GBA wave channel has no
  hardware envelope generator.
* A new note does **not** set `noteReset` — the volume table alone does the work.
* Its wavetable comes from the song, not the instrument: `musicinit` copies 16 bytes
  (32 four-bit samples) from `songtab[song].waveData` into `REG_WAVE_RAM`. Songs 1 and 2 use
  `wave_saw` = `00 11 22 33 44 55 66 77 88 99 AA BB CC DD EE FF` — a linear ramp, i.e. a sawtooth.
  Song 0 uses an all-zero table.

Because only one 16-byte bank is uploaded and it is uploaded only at `musicinit`, **the waveform is
fixed for the duration of a song.** The `morph_blank` symbol next to `wave_saw` and the unused
`+28` song-table pointer suggest a wave-morphing feature that was planned and cut. *(inferred)*

### Channel 4 — PSG noise

Note value is stored and never used. Pitch, width and timbre all come from the noise table, which
writes the low byte of `SOUND4CNT_H` directly; on a key-on the driver ORs in `0x8000` (restart).
This makes the noise instruments pure "drum machine" programs: `snare_tab = ff 32` (a constant),
`explode_tab` a 12-step descending sweep, `rocket_tab` a 20-step rising-then-falling sweep.

### Channels 5 and 6 — DirectSound

No modulation at all. On a note event:

1. `note = transpose + noteByte` → `sampfreqtab[note]` → the timer word.
2. `instrument` → `sampletab[ins]` (16-byte stride).
3. Stop DMA and timer, set `DMAnSAD` from the table, reset the FIFO via `SOUNDCNT_H`,
   point `DMAnDAD` at the FIFO, start DMA with `0xF6600004`, start the timer.
4. Copy the block count into `DmaCount5`/`DmaCount6`.

The IRQ handlers are as small as they can be:

```asm
SoundIntDMA1Handler:
    push {lr}; push {r1}
    ldr  r1, =Seq5
    ldr  r0, [r1,#16]      ; DmaCount5
    subs r0, #1
    str  r0, [r1,#16]
    bne  int1end
    ldr  r1, =0x040000BC   ; DMA1SAD
    movs r0, #0
    str  r0, [r1,#8]       ; DMA1CNT  = 0   → stop DMA
    adds r1, #68
    str  r0, [r1,#0]       ; TM0CNT   = 0   → stop timer
int1end:
    pop {r1}; pop {r0}; bx r0
```

Nine instructions in the common case. That, and the absence of any mixing, is the whole
performance story.

**Consequences of this design:**

* Sample playback is **rate-shifted, not resampled** — changing the note changes the timer, which
  changes the playback speed. There is no interpolation and no per-sample volume ramp.
* There is **no looping**: a sample plays once and stops.
* DirectSound volume is a per-sample 50 %/100 % flag, not a continuous level.
* The FIFO IRQ fires every 16 bytes (4 words), so at 8363 Hz that is ~523 interrupts/second per
  active sample channel — the dominant CPU cost of the driver, and still tiny.

---

## 9. The sound-effect subsystem

### Model

There are exactly **two effect slots**. Each slot, when active, has:

* a **priority** (`0`–`127`; **higher wins**),
* a **channel id** (`0`–`5`, +1 internally so that `0` means "free"; bit 7 is set to flag
  "finished, please clean up"),
* a 16-byte sequence struct running at tempo 1,
* a 4-byte **synthetic step list** in RAM (`fakestep1`/`fakestep2`) holding transpose 0 and the
  effect's pattern number.

`SFXTab` is 4 bytes per effect:

```
+0  u8   priority
+1  u8   channel     0=tone1 1=tone2 2=wave 3=noise 4=sampleA 5=sampleB
+2  u16  pattern number
```

### Allocation, step by step (`SFX(n)`)

1. Read `SFXTab[n]`; `want = channel + 1`.
2. If slot 2 already owns `want` → jump to the slot-2 path.
3. Else if slot 1 owns `want` → compare priorities; if the running effect's priority is **strictly
   higher**, give up on slot 1 and try slot 2; otherwise (including on a tie — the newcomer wins
   ties) hand slot 1's channel back and reuse it.
4. Else if slot 1 is free → take slot 1.
5. Else if slot 2 is free → slot-2 path.
6. Else → try slot 2 with the same priority comparison.

Taking a slot:

```
saved            = SeqPTR[want]          ; the music sequence that was on that channel
SeqPTR[want]     = &EffectSeqN           ; channel now plays the effect
SeqeNPTR         = saved                 ; park it so the ghost stepper can keep it in time
EffSeqNChan      = want
EffectSeqN.priority       = SFXTab.priority
EffectSeqN.tempoReload    = 1            ; SFXTempo
EffectSeqN.noteLenCounter = 1
EffectSeqN.patternOffset  = 0
EffectSeqN.stepPtr        = &fakestepN
fakestepN                 = { transpose 0, pattern SFXTab.pattern }
```

### Release

When the effect pattern hits `00 00 00`, the channel block that was running it detects that its
sequence pointer is *not* the channel's own static struct, reads the loop word, finds it zero, and:

```
SeqPTR[channel] = &SeqN                  ; music has its channel back
EffSeqNChan    |= 0x80                   ; flag "finished"
```

On the next frame the ghost stepper sees the flag, clears `EffSeqNChan` and the priority, and the
slot is free again.

### The ghost stepper

`effs16`/`effs2` run the sequence at `SeqeNPTR` — the *displaced music sequence* — through the
same event-fetch logic as a channel, but **without any register writes**. Tempo counters, note
lengths, pattern offsets and step advances all continue; the channel is simply silent. When the
effect ends, the music resumes exactly where it would have been. This is the cleanest part of the
design.

### Shipped effects

All 20 effects in `music.h` are one-shot: a single note event followed by a hold and
`END(loop=0)`. Of the 19 audible ones, **14 play PCM** — 12 on sample channel B and the two
hostage speech lines on channel A — **4 are pure noise programs** (flamethrower, rocket, both
explosions) and one, `SFX_BONUS`, is a square-wave arpeggio on tone channel 1.

Priorities in the shipped table: speech 120 > punch/gun/impact/enemy-death 100 >
chainsaw/gunshot/hit/machinegun 90 > window-break/bullet-bounce/explosions 80 > jump 70 >
bonus 25 > flamethrower/rocket 20. `SFX_BLANK` has priority 127 and plays a silent pattern — it
is the "force-stop the effect channel" primitive.

---

## 10. Bugs, dead code and anomalies

These are things a reimplementation should know about, and things worth checking if this driver
ever misbehaved in the field.

**1. Cross-slot priority clobber.** When an effect ends, the release code writes the "clear
priority" zero at **`effectStruct + 30`** rather than `+14`. For slot 1 (`EffectSeq1` at `0xD4`)
`+30` lands on **`prioritye2`** — slot 2's priority — so the end of a slot-1 effect silently drops
slot 2's priority to 0, letting the next effect of any priority steal a still-playing slot-2
sound. The correct field (`prioritye1`) does get cleared a frame later by the ghost stepper, so
the visible symptom is only the spurious slot-2 reset.

**2. Out-of-bounds write on slot-2 release.** The same `+30` store with slot 2's base (`0xE4`)
targets `.bss + 0x102` — **6 bytes past the end of `.bss`** (which is `0xFC` long). In
`musicd.bin` that is `0x03000102` in IWRAM, i.e. whatever the linker placed after the driver.

**3. Out-of-bounds write on slot-2 allocation.** `SFX()` builds slot 2's synthetic step list at
`EffectSeq2 + 36` = `.bss + 0x108`, but `fakestep2` is at `.bss + 0xF8` (`EffectSeq2 + 20`). Both
stray offsets are exactly `+16` from the correct slot-1-relative values (`14`→`30`, `20`→`36`),
so the cause is clear: the offsets were written relative to `EffectSeq1` and then used with
`EffectSeq2`'s base. The effect is that a slot-2 sound effect reads its pattern number from
uninitialised memory past the end of `.bss` **and** writes 8 bytes there.

*Practical impact:* slot 2 is only reached when two effects overlap on different channels, and
`Seq5`/`Seq6` structs being 20 bytes means `0x102`/`0x108` sit in whatever follows the driver's
`.bss`. If the game's own `.bss` followed `musicd.o`'s, this is a live memory corruption bug. It
may well be why the shipped `music.h` effect set leans so heavily on a single channel.

**4. Slot-1 allocation uses slot 2's channel id.** In `SFX()`, when *both* slots are busy and
neither owns the requested channel, control falls through into the slot-1 steal path with `r4`
still holding **`EffSeq2Chan`** instead of the wanted channel. The steal code then executes
`SeqPTR[EffSeq2Chan] = Seqe1PTR` — it hands slot 1's parked music pointer to slot **2**'s channel.
The channel slot 1 was actually using is never restored and keeps pointing at `EffectSeq1`, so two
channels end up running the same effect sequence and one channel's music pointer is lost until the
next `musicinit()`. The equivalent slot-2 path (`sfxc1`) is written correctly, so this is a
copy-paste slip in one branch. Reachable whenever three effects on three different channels
overlap.

**5. Unaligned DMA sources.** Sample start addresses are packed back to back with no alignment;
**25 of 30** entries are not word-aligned (`0x08003175`, `0x08003C6B`, …). DMA1/2 in 32-bit mode
force the source address down to a word boundary, so those samples start up to 3 bytes early —
a sub-millisecond artefact, audible at worst as a click.

**6. Duplicate sample entries.** `sampletab` entries 3–8 all point at the same address
(`.text+0x3A9F`) with six different lengths (960 … 9312 bytes); 11/12, 15/16 and 19/20 likewise
share a start address. In the symbol table `sample_3` … `sample_8` are all defined at the same
offset, which means the source declared the labels consecutively with a single `.incbin` after
them. Whether that is deliberate (six truncations of one long recording) or a content-pipeline
slip, effects 2–7 in `SFXTab` play overlapping regions of one blob.

**7. Dead wave-channel restart.** Channel 3's pitch write adds `0x8000` (the `SOUND3CNT_X`
restart bit) and then masks the result with `0x7FF`, which removes it again. The wave channel is
therefore never explicitly restarted after `musicinit`.

**8. Dead second noise table.** Every noise instrument has a second table pointer at `+8`. The
code loads it into `r0` and overwrites `r0` with `1` on the very next instruction. `wn2tabadr4`
and `wn2tim4` exist in `.bss` and are never read. A second modulation lane for the noise channel
was clearly intended.

**9. Unused song-table field.** `songtab + 28` is loaded by nothing; all three songs set it to
`.text+0x234D`, an address *inside* the `wave_saw` blob. Together with the `morph_blank` /
`morph_blanke` symbols this looks like a cut wave-morphing feature.

**10. Partial `patternOffset` clear.** `SFX()` zeroes `patternOffset` with a byte store, leaving
the high byte of the halfword untouched. Harmless in practice (patterns are far shorter than 256
bytes) but it is a latent bug for any pattern longer than 255 bytes.

**11. No bounds checking anywhere.** `musicinit(song)`, `SFX(n)`, instrument indices, pattern
indices and note values are all used raw. A note above 71 on a PSG channel or above 60 on a
sample channel reads past the end of its pitch table.

---

## 11. Content inventory

| | |
|---|---|
| Songs | 3 — `MUSIC_BLANK`, `MUSIC_LEVEL1`, `MUSIC_LEVEL2` (both real songs use 5 of 6 channels; channel 6 is reserved for SFX) |
| Patterns | 100 |
| Tone/wave instruments | 35 (`InsTab`) |
| Noise instruments | 9 (`InsTab4`) |
| Modulation tables | ~60 named tables (`vibrato_*`, `arp_*`, `vol_*`, `*_tab`) |
| PCM samples | 30 table entries, 22 distinct start addresses, 99 500 bytes total |
| Sound effects | 20 (`SFXTab`) |

Song 1 (`LEVEL1`) is 12 steps long on channel 1 and loops back to its own step list; both songs
run at 128 BPM with a 16th-note tick.

The instrument naming is a useful window on the composer's palette: `ins_bass1/2`,
`ins_longbass`, `ins_banjo`, `ins_banjo_slide`, `ins_square_leed(_slide)`, eleven fixed
arpeggio-chord instruments (`ins_arp_0c`, `ins_arp_37`, `ins_arp_47`, `ins_arp_58` …, named for
their semitone sets), `ins_tom`, `ins_tonekick`, and the wave-channel set
`ins_rdclead / rdcflute / rdcwhistle / rdcloud / rdcmed / rdcquiet`.

A full decode of every table, pattern and step list is in **`quickthunder_data_dump.txt`**; the
raw Thumb listing of the 3.3 KB code region is in **`quickthunder_code_disasm.txt`**; and
**`musicd.s`** is a reconstructed assembler source for the whole object — symbols, labels,
relocations and data directives — verified to reassemble to a byte-identical `.text` and `.bss`
with `arm-none-eabi-as -mcpu=arm7tdmi -mthumb` (the PCM blob is supplied alongside it as
`musicd_samples.bin` and pulled in with `.incbin`).

---

## 12. Notes for reimplementation or tooling

**To play this data on a modern emulator/player**, you need: the six channel state machines of
§5, the pattern decoder of §7.3, the table walker of §7.5, and the two pitch tables. Everything
else is hardware.

**To author new content**, the source-level vocabulary was (all recovered as absolute symbols):

```
note names      c1 cs1 d1 ds1 e1 f1 fs1 g1 gs1 a1 as1 b1  …  c9      (c1 = index 0 = C2 real pitch)
channel ids     tonech1=0 tonech2=1 rdch=2 noisech=3 samplech1=4 samplech2=5
noise pitch     course1..course14  (104..0, step 8)   fine1..fine8 (7..0)
instrument ids  flamethrower=5 rocket=6 explos1=7 explos2=8 pickup=34 tonefx=34 noisefx=5
misc            SFXTempo=1  mixlevel=2
```

**The three things that most distinguish QuickThunder from Nintendo's MediaPlayer2000 (`m4a`):**

1. No software mixer — MediaPlayer2000 mixes up to 12 DirectSound voices in a CPU-filled buffer;
   this build uses the two FIFOs as literal one-shot sample players and spends its CPU budget on
   nothing. (The V-Rally 3 revision does add a small two-voice software mixer — see the companion
   document.)
2. Instrument macros (freq/arp/combine tables) rather than ADSR envelopes — a C64/NES tracker
   idiom, and the reason the PSG channels sound as busy as they do.
3. SFX as channel-stealing sequences with a ghost stepper, rather than a separate voice pool.

**If you port this,** fix the slot-2 offset bugs (§10.1–3) and the slot-1 allocation slip (§10.4)
first — those four are the only defects that can corrupt memory or state outside the driver.

---

## Appendix — module map of `.text`

```
0x00000 – 0x00CD0   engine code (Thumb) + inline literal pools     3 280 B
  0x00000 chan1   0x001A2 chan2   0x00344 chan3   0x0051A chan4
  0x00646 chan5   0x00768 chan6   0x0088C effs16  0x0093C effs2
  0x00A14 musicinit   0x00B5C/0x00B7C IRQ handlers   0x00BC0 SFX
0x00CD0 – 0x00D60   FreqTable            72 × u16
0x00D60 – 0x00E5C   sampfreqtab          61 × u32
0x00E5C – 0x01264   modulation tables and instrument definitions
0x01264 – 0x012F0   InsTab               35 pointers
0x012F0 – 0x01314   InsTab4               9 pointers
0x01314 – 0x014A4   PatTab              100 pointers
0x014A4 – 0x014C0   blank step lists
0x014C0 – 0x0152C   songtab               3 × 36 B
0x0152C – 0x0157C   SFXTab               20 × 4 B
0x0157C – 0x02340   pattern and step-list data (with a few instruments interleaved)
0x02340 – 0x02350   wave_saw             16 B wavetable
0x02358 – 0x02538   sampletab            30 × 16 B
0x02538 – 0x1A9E4   8-bit signed PCM     ~97 KB
```
