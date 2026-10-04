# QuickThunder — V-Rally 3 revision
## Does it software-mix? Yes — partly. Analysis, and diff against the 2001 Robocop build.

*QuickThunder is the engine; this document covers the later revision of it that ships in
V-Rally 3, compared against the 2001 Robocop build analysed in the companion reference.*

**Subject:** `V-Rally 3 (E) (M5).gba` — 4 MiB, header title `V-RALLY 3`, game code `AVRP`,
maker `70` (Atari/Infogrames). Engine code and data at ROM `0x36C000`–`0x3702xx`
(`0x0836C000`–`0x0836E200`), sample table at `0x083FAFB8`, PCM spread from `0x08370718`
to the end of the cartridge.

**Short answer:** it is a **hybrid**. The 2001 Robocop build of QuickThunder is pure
hardware playback. The V-Rally 3 revision adds a genuine **two-voice 8-bit software mixer**
that fills a rotating set of RAM buffers played out of FIFO A by DMA1 at a fixed rate —
and it *keeps* one hardware-driven DirectSound channel on FIFO B alongside it. So: software
mixing for two of the three sample channels, hardware DirectSound for the third.

---

## 1. Identification

The engine is unmistakably the same lineage. Byte-identical data survives:

| Table | Robocop (`musicd.o`) | V-Rally 3 |
|---|---|---|
| `FreqTable` (72 × u16 PSG pitches) | `.text+0xCD0` | `0x0836E31E` — **identical 144 bytes** |
| `sampfreqtab` (61 × u32 timer words) | `.text+0xD60` | `0x0836E1F4` — **identical 244 bytes** |
| FIFO DMA control word `0xF6600004` | `.text+0x868` | `0x0836DC2C` |

The sequencer code is near instruction-for-instruction the same: the same two-counter
tempo/note-length skeleton, the same `FF`/`FE`/`FD` pattern opcodes, the same 3-byte
frequency / 2-byte arpeggio / 2-byte combine table walker with its `00 rel8` relative-loop
terminator, the same `0xFF` + align-to-4 + pointer "end of song" marker, the same two-slot
priority SFX allocator with the ghost stepper. Everything documented in the Robocop-build
reference still applies unless listed below.

What changed is the back end.

---

## 2. What's new

### 2.1 Seven channels instead of six

`musicd()` now walks seven channel blocks, and the song table grew from 36 to **40 bytes**
per entry to carry the seventh step-list pointer.

| # | Channel | Address | Output path |
|---|---|---|---|
| 1 | PSG square 1 | `0x0836D2E6` | `SOUND1CNT_*` |
| 2 | PSG square 2 | `0x0836D4BA` | `SOUND2CNT_*` |
| 3 | PSG wave ("rdc") | `0x0836D65C` | `SOUND3CNT_*` |
| 4 | PSG noise | `0x0836D830` | `SOUND4CNT_*` |
| 5 | **pitched sample** | `0x0836D960` | **software mixer voice A** |
| 6 | **streaming sample** | `0x0836DA54` | **software mixer voice B** |
| 7 | one-shot sample | `0x0836DB44` | **hardware** DirectSound B / DMA2 / Timer 1 |

Song table entry (40 bytes): `u16 tempo`, `u16 channel mask`, seven `u32` step-list
pointers at `+4 … +28`, unused `u32` at `+32`, wave-RAM pointer at `+36`.

### 2.2 The software mixer

Two entry points, differing only in how many samples they produce per call:

```
0x0836D1F8   mix 176 samples   (0xB0)   → 10512 Hz
0x0836D270   mix 112 samples   (0x70)   →  6689 Hz
```

Each is the game's "call once per frame" routine — the equivalent of `musicd()` — and each
begins by mixing, then falls through into the seven-channel sequencer pass.

The mix loop, decompiled:

```c
if (!sound_enabled) return;

// rotate through five output buffers
idx = (idx == 16) ? 0 : idx + 4;            // 0,4,8,12,16
buf = buftab[idx];                          // 5 pointers, table in ROM at 0x0836D340

for (i = 0; i < 176; i++) {                 // or 112
    int acc = 0;

    /* ---- voice A: pitched, looping, 16.8 fixed point ---- */
    if (m->step) {                          // step == 0 means idle
        pos = m->pos + m->step;
        if (pos >= m->end) {
            if (m->loop == 0) { m->step = 0; goto voiceB; }   // one-shot: stop
            pos = m->loop + (pos - m->end);                   // wrap
        }
        m->pos = pos;
        acc += (int8_t) m->base[pos >> 8];
    }
voiceB:
    /* ---- voice B: 1:1 stream, no pitch, no loop ---- */
    if (m->cur != m->end2) acc += *m->cur++;

    buf[i] = (uint8_t) acc;                 // wrap-around, no clip, no scaling
}
```

Mixer state (28 bytes at `0x0203E928`, EWRAM):

```
+0   u32 base      voice A sample base address
+4   u32 step      voice A 16.8 pitch increment (0 = voice idle)
+8   u32 pos       voice A 16.8 position, relative to base
+12  u32 end       voice A 16.8 end offset
+16  u32 loop      voice A 16.8 loop-start offset (0 = one-shot)
+20  u32 cur       voice B current byte pointer
+24  u32 end2      voice B end byte pointer
+28  u32           unused
```

Five 176-byte buffers live back-to-back in EWRAM at `0x0203E970`, `…EA20`, `…EAD0`,
`…EB80`, `…EC30` (880 bytes total; the 6689 Hz init clears only 560). A separate routine at
`0x0836D1D0`, registered as the V-Blank handler, stops DMA1, re-points `DMA1SAD` at the
buffer the mixer just filled and restarts it with `DMA1CNT = 0xB6600004` — **note bit 14
clear: no IRQ**, unlike the Robocop build. Straight fixed-rate streaming.

Two things worth calling out about the mixer's arithmetic:

* Voice B is read with `ldrb` (unsigned) while voice A uses `ldrsb` (signed). Because the
  result is stored back with `strb`, the two are congruent mod 256, so it makes no
  difference — but it does mean the mixer is a **plain modulo-256 additive mix with no
  clipping and no per-voice volume**. Two loud samples will wrap rather than clip. The
  content must be authored quiet enough to avoid it.
* There is no interpolation. Voice A point-samples at `pos >> 8`.

### 2.3 The seventh channel is still pure hardware

Channel 7 is the 2001 DirectSound path, essentially unchanged: per-note it stops
DMA2 and Timer 1, writes the sample address to `DMA2SAD`, resets FIFO B via
`SOUNDCNT_H = 0xF302 | volbits`, sets `DMA2DAD = 0x040000A4`, starts
`DMA2CNT = 0xF6600004` (IRQ **on**) and loads `TM1CNT` from `sampfreqtab[note]`. The DMA2
FIFO interrupt handler at `0x0836E064` counts 16-byte blocks and shuts the channel down at
zero, exactly as before.

One refinement: both the note-start and the IRQ handler now stop the DMA with a
**double write separated by three `nop`s** —

```asm
    ldr  r0, =0x49248440
    str  r0, [r1, #8]     @ DMA2CNT
    nop
    nop
    nop
    ldr  r0, =0x00000440
    str  r0, [r1, #8]
```

— the known idiom for safely tearing down a FIFO DMA on real hardware. The Robocop build
wrote a single zero.

### 2.4 Sample-rate and mixing setup

Two init routines, one per quality mode:

```
0x0836DF94   10512 Hz : TM0CNT = TM1CNT = 0x0080F9C4 ; clears 880 bytes of buffer
0x0836DF58    6689 Hz : TM0CNT = TM1CNT = 0x0080F634 ; clears 560 bytes of buffer
```

Both set `DMA1DAD = 0x040000A0` (FIFO A), `DMA2DAD = 0x040000A4` (FIFO B),
`SOUNDCNT_L = SOUNDCNT_X = 0xFFFF`, and

```
SOUNDCNT_H = 0xF30E    DMG 100%, DSound A 100%, DSound B 100%,
                       A → L+R on Timer 0, B → L+R on Timer 1, B FIFO reset
```

176 samples × 59.7275 fps = 10512.0 Hz exactly; 112 × 59.7275 = 6689.5 Hz. The game picks
per scene: of the six places where it registers its sound callbacks, **four use the
10512 Hz mixer and two use the 6689 Hz one** — almost certainly full rate in menus and
front-end, reduced rate while the 3-D renderer is running.

### 2.5 A proper public API

The engine is reached through a 9-entry jump table at `0x0806BB2C`:

| Offset | Address | Function |
|---|---|---|
| +0 | `0x0836DF95` | `sound_init_10512()` |
| +4 | `0x0836DF59` | `sound_init_6689()` |
| +8 | `0x0836DE0D` | `musicinit(song)` |
| +12 | `0x0836D1F9` | `musicd_176()` — mix + sequence, 10512 Hz |
| +16 | `0x0836D271` | `musicd_112()` — mix + sequence, 6689 Hz |
| +20 | `0x0836E105` | `SFX(n)` |
| +24 | `0x0836E009` | `set_voiceA_pitch(x)` → `mixer.step = x + 0x80` |
| +28 | `0x0836D18D` | `sound_off()` — stop DMA1+DMA2, `SOUNDCNT_X = 0` |
| +32 | `0x0836D1A9` | `sound_on()` — `SOUNDCNT_X = 0x8F`, `SOUNDCNT_L = 0xFFFF` |

Plus two entry points not in the table: a master-volume setter at `0x0836E020`
(`SOUNDCNT_H = 0x730E − (vol << 2)`, giving four steps by toggling the two DirectSound
volume bits) and a "sample channel 5 finished?" poll at `0x0836E0B0`.

`set_voiceA_pitch` is the interesting one — a direct, per-frame handle on the pitched
mixer voice's playback rate, which is exactly what a racing game needs to make an engine
sample rev. Sample 2 in the table is a 6634-byte blob with `loop = 1`, i.e. a fully
looping sustain, and the mixer voice is the only thing in the engine that can loop.

### 2.6 Sample table

At `0x083FAFB8`, still 16 bytes per entry, but now **polymorphic** — the meaning of the
fields depends on which channel plays the entry:

```
            +0            +4                    +8                  +12
channel 5   base addr     end offset (16.8)     loop offset (16.8)  —
channel 6   start addr    end addr              (unused)            —
channel 7   base addr     DMA block count       —                   volume flags
```

That is a neat unification and also a trap: playing a channel-7 entry on channel 5 would
treat a block count as a 16.8 end offset.

---

## 3. Why the music sounds "more PCM-based"

Because it is. The song table holds 10 songs, and in **every single one** the four PSG
channels point at the same four tiny blank step lists (`0x0836ED6C`, `…70`, `…74`, `…78`)
— one step each, into patterns that are pure rests. Only channels 5, 6 and 7 carry real
step lists, and those differ per song.

So V-Rally 3's music runs entirely on the three sample channels: one pitched/loopable
software voice, one 1:1 software stream, and one hardware one-shot. The PSG hardware is
present in the engine and completely unused by the content. Most songs run at `tempo = 1`
(one tick per frame) with pattern events of ~224 ticks, which is the shape you get when
you are streaming multi-second PCM blocks rather than sequencing notes.

---

## 4. Bugs: fixed, and new

**Fixed since the Robocop build** (all four of the memory-corrupting defects in §10 of the
Robocop-build reference):

* The effect-release path now clears `priority` at `+14` on the *current* slot
  (`0x0836D716`, `strb r0,[r2,#14]`), not the stray `+30` that in Robocop hit slot 2's
  priority or wrote past the end of `.bss`.
* The SFX allocator's synthetic step lists are now at `EffectSeq1+32` and `EffectSeq2+20`
  — both correct, both in bounds.
* The two saved-sequence-pointer slots are addressed at `+52` and `+56` — distinct and
  correct.
* The slot-1 steal path reloads `EffSeq1Chan` explicitly (`ldrb r4,[r2,#15]`) instead of
  inheriting whatever was left in `r4`, so the "hand slot 1's parked pointer to slot 2's
  channel" bug is gone.

**Still present or new:**

* **`sampfreqtab2` entry 36 is wrong.** The mixer's 16.8 increment table at `0x0836E3B0`
  runs `… 0x0B5, 0x0BF, 0x100, 0x0D7, 0x0E4, 0x0F1, 0x100 …`. Entry 40 is unity (`0x100`)
  and the ratio between adjacent entries is the semitone `2^(1/12)` everywhere except
  index 36, which should be `0x0CB` (0.794×) and instead duplicates unity. A note 36 on
  channel 5 plays a minor sixth sharp.
* **`musicinit` clears the wrong two pointer slots.** It zeroes the array words at
  `+28`/`+32` (the positions the effect-save slots occupied in the six-channel version)
  while the seven-channel code uses `+48`/`+52`. Harmless — the ghost steppers are guarded
  by `EffSeqNChan`, which *is* cleared correctly — but it is leftover from the port.
* **No clipping in the mixer** (see §2.2). A design choice rather than a bug, but it means
  loud simultaneous voices wrap to the opposite rail rather than saturate.

---

## 5. Side-by-side

| | Robocop (2001) | V-Rally 3 |
|---|---|---|
| Channels | 6 | 7 |
| PSG channels used by music | 4 | 0 (blank in all 10 songs) |
| Sample playback | 2 × hardware DirectSound | 2 × software mixer + 1 × hardware |
| Mixer | none | 2 voices, 8-bit, mod-256 add, no clip |
| Output rate | per-note timer (sample rate = pitch) | fixed 10512 Hz or 6689 Hz for FIFO A |
| FIFO A DMA | `0xF6600004` (IRQ on, retriggered per note) | `0xB6600004` (IRQ off, restarted each V-Blank) |
| Looping samples | no | yes, on mixer voice A |
| Output buffers | none | 5 × 176 bytes in EWRAM |
| Driver state | 252 bytes in IWRAM | ~1.6 KB in EWRAM incl. buffers |
| Song table entry | 36 bytes | 40 bytes |
| Public API | 5 functions | 9-entry jump table + 2 extras |
| SFX allocator bugs | 4 (two write out of bounds) | fixed |
| Runtime pitch control | none | `set_voiceA_pitch()` |

The through-line: across both revisions QuickThunder keeps the sequencer, the pattern
byte-code, the instrument-macro tables and the SFX arbitration exactly as they were — that
part of the engine is stable across at least two years and two publishers — and the sample
back end was replaced when the content moved from PSG-led music with sampled drums to fully
sampled music.

---

## 6. Method / reproducibility

Everything above came from static analysis of the two artefacts, no emulation:

1. Fingerprinted the ROM against `musicd.o` by searching for the byte-exact `FreqTable`,
   `sampfreqtab` and the `0xF6600004` DMA word.
2. Disassembled `0x0836D180`–`0x0836E200` as Thumb and resolved every literal-pool word by
   reading it out of the ROM image.
3. Recovered the API jump table by searching the whole ROM for Thumb-tagged pointers
   (`addr | 1`) to each entry point.
4. Decoded the song, pattern, instrument and sample tables using the formats established
   from the Robocop object.

The one thing worth verifying on hardware or in an emulator, if you want certainty: which
scenes select 6689 Hz versus 10512 Hz. The static evidence (four registration sites for the
176-sample mixer, two for the 112-sample one) says both are live, but not which is which.
