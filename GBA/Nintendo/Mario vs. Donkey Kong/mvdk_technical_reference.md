# Mario vs. Donkey Kong sound driver
## Reverse-engineering report and technical reference

**Subject file:** `…/GBAAudioLab/Nint2/Mario vs. Donkey Kong (E) (M5).gba` (game code `BM5P`, 16 MiB)

**Provenance.** The ROM contains no symbols, no credit and no version string for its sound code.
Every function, variable, structure and table name in this document and in the sources was
assigned during this analysis. The game was developed by Nintendo Software Technology, so the driver
is presumably theirs *(inferred; nothing in the ROM names it)*. The only names that come from the
ROM are data names: module names such as `BGM_1A` + `XM` (the converter dropped the dot of
`BGM_1A.XM`), the tracker name field `untitled`, instrument and sample names (General MIDI names like
`Vibraphone`, `Picked Bs.`), and SFX names (`CLIMB`, `SKID`, `POUND` …).

Everything below comes from disassembling the ROM. Where something is an inference rather than a
direct reading of the code, it is marked *(inferred)*. All sources rebuild **byte-identical** to the
ROM (§14).

---

## 1. Executive summary

The driver is a **software mixer** that plays **FastTracker 2 modules converted to a compact,
GBA-specific format**, plus sampled sound effects, into a **16 384 Hz, 8-bit, true-stereo** stream.

* **XM semantics.** Linear frequency slides only (the XM `7680 − 64·note − finetune/2` period
  space, with a 768-entry frequency table), multi-sample instruments with a 120-note keymap,
  12-point volume and panning envelopes with sustain and loop, fadeout, sample auto-vibrato,
  relative note and finetune, the XM volume column, and most XM effects.
* **Converted, not raw.** Modules drop everything the player does not need: patterns are
  re-packed with an **IT-style mask scheme** (a channel byte, an optional mask byte, and "reuse
  the last value" bits), instruments and samples live in **one shared bank** (156 instruments,
  328 sample headers) referenced through a per-module instrument map, sample lengths are 24.8
  fixed point, and a **panning column** carries what used to be `8xx` effects.
* **Normalised samples.** Almost every sample is scaled to full 8-bit range; a per-sample
  **amplitude factor** (x/64) restores its level at mix time *(inferred from the data: all 59 PCM blocks
  used with a factor below 64 peak at ≥ 120)*.
* **A fixed voice budget shared with SFX.** Up to 16 module channels share **8 mixing voices**
  (voice stealing by loudness). Every SFX voice **takes one of those 8 voices away from the music**
  while it plays; which one is chosen per song (the song table's 3-byte "voice map"). This keeps
  the CPU cost of music + SFX roughly constant.
* **Mixing.** GCC-compiled Thumb for the sequencer; the inner loops are **hand-written ARM** copied
  to IWRAM at start-up. Channels are resampled (18.14 fixed point, no interpolation) into a 16-bit
  stereo accumulator with a **constant-power pan law**, then clamped to 8 bits into two buffers.
* **Buffering.** Triple-buffered 288-sample blocks. **DMA1 → FIFO A (left)** and **DMA2 → FIFO B
  (right)**, both clocked by **Timer 1**. The buffer swap is done by a **DMA1 interrupt
  countdown** (18 IRQs × 16 samples), not by VBlank; the VBlank handler only mixes when a swap
  happened.
* **SFX** are plain 8-bit samples (211 of the 230 real sounds at 8 000 Hz) with rate, volume, priority,
  optional loop, pan and a **"wide" stereo control** that adds a phase-inverted copy.
* A **PSG register sequencer** (Timer 0 IRQ at 256 Hz, wave channel + frequency slides) is
  initialised and ticks forever, but **nothing ever starts it**.

Content: **70 songs** (70 modules, all distinct), **156 instruments**, **328 sample headers** over
**124 PCM blocks** (1.19 MB), **254 SFX** (2.40 MB of PCM).

---

## 2. Build and ROM layout

The Thumb part is **GCC** output *(inferred from idioms: `adds rX, rY, #0` moves, `push {…};
pop {r0}; bx r0` epilogues, `_call_via_rX` veneers, `__divsi3`/`__modsi3`, `mov pc, r0` switch
tables)*.

| Region | ROM range | Size | Contents |
|---|---|---|---|
| ARM module A | `0x0800023C`–`0x080003D0` | 404 B | `Clear32`, `Downmix`, `DmaIrq` (copied to RAM), an unused older mixer |
| ARM module B | `0x08001840`–`0x08001BA4` | 868 B | `MixSpan`, `MixChannel` (copied to RAM) |
| **Driver (Thumb)** | `0x080725D8`–`0x08074F40` | 10 600 B | 71 functions |
| SFX names | `0x0807A2D0`–`0x0807ACFC` | 2 604 B | 254 strings, in the game's rodata |
| **Rodata** | `0x08B91F60`–`0x08B92E20` | 3 776 B | frequency, vibrato, octave, arpeggio, pan-law tables; effect tables |
| SFX table | `0x08B92E20`–`0x08B949EC` | 7 116 B | count (254) + 254 × 28-byte entries |
| SFX PCM | `0x08B949EC`–`0x08DDD85A` | 2 395 758 B | 8-bit signed |
| Song table | `0x08DDD85C`–`0x08DDDBA8` | 844 B | count (70) + 70 × 12-byte entries |
| Music PCM | `0x08DDDBA8`–`0x08EFF83C` | 1 186 964 B | 124 blocks |
| Sample headers | `0x08EFF83C`–`0x08F035BC` | 15 744 B | 328 × 0x30 |
| Instruments | `0x08F035BC`–`0x08F0F64C` | 49 296 B | 156 × 0x13C |
| Modules | `0x08F0F64C`–`0x08F8A0CC` | 502 400 B | 70 modules |

External helpers the driver calls: `_call_via_r0`–`r5` (`0x080758DC`–`0x080758F0`), `__divsi3`
(`0x08075918`), `__modsi3` (`0x080759B0`), and the game's BIOS stubs `swiCpuSet` (`0x08074F40`) and
`swiLZ77UnCompWram` (`0x08074F48`).

**RAM copies.** `sndInit` DMA-copies 0xE8 bytes of module A and 0x390 bytes of module B into the
driver's state block (IWRAM). Both copy lengths are slightly off: module A's copy takes the first 12
bytes of the unused old mixer, module B's copy takes 0x2C bytes of the unrelated Thumb code that
follows it. Neither extra part is ever executed.

---

## 3. Public API and host integration

### 3.1 Set-up and per-frame calls

| Address | Function | Notes |
|---|---|---|
| `0807278C` | `sndInit(heap, size, nSfxVoices, unused, maxMusicVoices)` | MvDK: `sndInit(malloc(0x15A4), 0x15A4, 3, 3, 8)` at `0x08031A54` |
| `08072A6C` | `sndVBlank()` | first thing in the VBlank IRQ (`0x08033E8C`) |
| `08072920` | `sndFrame()` | last thing in the VBlank IRQ (`0x08033EFC`): mixes one buffer |
| `08072CEC` | `sndDmaIrq()` | IRQ table entry 9 (DMA1), calls the RAM copy of `sndArmA_DmaIrq` |
| `08074C9C` | `psgTimerIrq()` | IRQ table entry 4 (Timer 0) |
| `08072D00` / `08072D20` | `sndDmaStop()` / `sndDmaStart()` | |
| `08073004` | `sndShutdown()` | DMA, master sound and Timer 1 off |
| `08073310` / `08073324` | `sndIsStereo()` / `sndSetStereo(on)` | mono forces every pan to centre |

The game's IRQ dispatcher runs handlers with IRQs masked, so all mixing happens inside the VBlank
interrupt.

### 3.2 Music

| Address | Function | Notes |
|---|---|---|
| `0807316C` | `musPlaySong(song, vol, loop)` | 43 call sites; volume = table volume × vol / 128 |
| `080730C0` | `musPlayModuleEx(module, vol, loop, voiceMap)` | used with the three getters below |
| `08073084` / `98` / `AC` | `musGetSongVolume` / `musGetSongModule` / `musGetSongVoiceMap` | |
| `080731CC` | `musStop()` | order = −2 |
| `08073204` / `08073238` | `musPause()` / `musResume()` | order = −1 and back |
| `08073104` | `musGetCurrentSong()` | −1 stopped, −2 not in the table |
| `08073260` / `08073158` | `musIsStopped()` / `musGetModule()` | |
| `08073030`, `0807304C`, `08073068`, `0807496C` | `musPlayModule`, `musPlayModule2`, `musRestart`, `musPlayPacked` | unused |

`musPlayPacked` would LZ77-unpack a module to `0x02000000` and start it; nothing uses it.
`musPlayModule` on its own leaves the song paused at volume 0 (only `musSetParams` starts it).

### 3.3 SFX

| Address | Function | Notes |
|---|---|---|
| `08072AB0` | `sfxPlay(id, flags, prio, pan, wide, vol, pitch)` → handle | 366 call sites |
| `08072EBC` | `sfxStop(handle)` | |
| `08072F34` | `sfxStopId(id)` | |
| `08072F9C` | `sfxStopPriority(prio, all)` | `all = 0`: looping voices only |
| `08072D44` / `8C` / `F4` | `sfxStopAll` / `sfxStopAllExcept(id)` / `sfxStopLooping` | |
| `08072E48` | `sfxSetPan(handle, pan, wide)` | |
| `080732C0` | `sfxIsDone(handle)` | |
| `08073284` | `sfxCountActive()` | unused |

`sfxPlay` arguments: `flags` 4 = loop, 8 = restart the voice if this SFX is already playing, 0x10 =
return the existing handle instead of starting it again; `prio` 0–15 (> 15 = the entry's default);
`pan` 0–127 (64 = centre); `wide` 0–127; `vol` 0–255 (scaled by the entry's volume/128); `pitch` 0 =
entry rate, > 0 = rate × pitch / 8192, < 0 = −pitch Hz. A free voice is used first, otherwise the
voice with the lowest priority below the new one is stolen; otherwise the call fails (−1).

**Stop entries.** 24 SFX entries are 1 byte long. For those, `sfxPlay` plays nothing and calls
`sfxStopPriority(prio, 0)`: they are "stop the looping sound of this priority class" commands.

---

## 4. Hardware resources

| | Setting |
|---|---|
| Output | 16 384 Hz (Timer 1, reload `0xFC00` = 1024 cycles), 8-bit, stereo |
| `SOUNDCNT_H` | `0xDE0C`: FIFO A → left only, FIFO B → right only, both 100 %, both on Timer 1; PSG 25 % (100 % after `psgInit`) |
| DMA1 → FIFO A | left buffer; `0xF660` control (enable, IRQ, FIFO timing, 32-bit, repeat) |
| DMA2 → FIFO B | right buffer; same control. Its IRQ is also enabled but the game routes it to a dummy handler |
| DMA1 IRQ | every 16 samples; the 18th swaps buffers (`sndArmA_DmaIrq`) |
| Timer 0 IRQ | 256 Hz (prescaler 64, reload `0xFC00`) for the unused PSG sequencer |
| `SOUNDCNT_L` | `0xCC00` after `psgInit`: PSG 3/4 enabled on both sides, PSG master volume at its lowest |
| PSG | only written by the PSG sequencer, which never runs |

A buffer holds 288 samples = 17.58 ms, a frame is 16.74 ms (274.3 samples), so roughly every 21st
VBlank sees no buffer swap and skips mixing.

---

## 5. Per-frame flow

```
DMA1 IRQ (every 16 samples)              sndArmA_DmaIrq, from RAM
    if (--irqCount > 0) return
    stop DMA1/2; playBuf = nextBuf; restart DMA1/2 at buffers[nextBuf].L / .R
    irqCount = 18; flags |= SWAPPED

VBlank IRQ (game handler 0x08033E74)
    sndVBlank():  if (flags & SWAPPED) { flags &= ~(SWAPPED|SKIP); nextBuf = lastMixed }
                  else { flags |= SKIP; if DMA not stopped: rewrite DMA1/2 control }
    ... game work ...
    sndFrame():   if (flags & (SKIP|BUSY)) return
                  clear the 288 × 2 × s16 accumulator
                  if (music order != -1) for (i = 0; i < 288; ) i += musMix(player, acc + i, 288 - i)
                  for each active SFX voice: sfxMixVoice(voice, acc, 288)
                  Downmix(acc -> buffers[mixBuf].L, .R, clamp ±127)
                  lastMixed = mixBuf; mixBuf = (mixBuf + 1) % 3
```

`musMix` never crosses a tick boundary: it mixes up to the end of the current tick and returns the
count, so ticks (and rows) land on exact sample positions.

**Timing:** `tickHz = BPM × 50 / 125` (integer), `rowLen = speed × 16384 / tickHz`,
`tickLen = rowLen / speed` (both integer). All 70 modules start at speed 3, 130 BPM (52 Hz, 315
samples per tick); 41 different BPM values are set with `Fxx`. The integer `tickHz` makes BPMs
that are not multiples of 2.5 up to 1.6 % slow (127 BPM → 50 Hz instead of 50.8).

---

## 6. RAM maps and structures

The complete field lists, with comments, are the `.equ` blocks in `mvdk_sound.inc`.

### 6.1 Globals (IWRAM)

```
030007E8 gMusTickPos       samples already mixed in the current tick (0 = tick start)
030007EC gMusTick          tick in the row
03000808 gPsgSeq           PSG sequencer state (0x40)
03001F50 gSndClearFn       \
03001F54 gSndMixSpanFn      |
03001F58 gSndDmaIrqFn       |  pointers into the RAM copies of the ARM routines
03001F68 gSndDownmixFn      |
03001F6C gSndMixChannelFn  /
03001F70..78               profiling: a timer value nobody writes, its delta and running sum
03001F80 gSnd              -> SndState
03001F84..8C               bump allocator (size, base, used)
03001F94 gMusVolume        song volume for MixChannel
03001F98 gMusCurChannel    channel being mixed (written, never read)
```

### 6.2 SndState (heap block; MvDK: 0x1518 bytes in a 0x15A4 IWRAM block)

```
+0x000  u8 nVoices, flags, irqCount, unused, unused, mixBuf, playBuf, nextBuf, lastMixed
        flags: 1 skip (no swap since VBlank), 2 swapped, 4 DMA stopped, 8 mixing, 0x10 stereo
+0x00C  u32 SFX handle counter
+0x010  u8  buffers[3][2][288]     8-bit output, L then R
+0x6D0  s16 mix[288][2]            accumulator
+0xB50  ARM module A copy (0xE8)
+0xC38  ARM module B copy (0x390)
+0xFC8  MusPlayer (0x514)
+0x14DC SfxVoice[nVoices]          0x14 each
```

### 6.3 SfxVoice (0x14)

`flags` (bits 0–1 active, bit 2 loop, bits 4–7 priority), `pan`, `wide`, `vol`, `handle`,
`pos` (18.14), `step` (Hz), `sfx` (entry pointer).

### 6.4 MusPlayer (0x514)

```
+0x000  module
+0x004  MusChannel chan[16]            0x4C each
+0x4C4  voiceOwner[8]                  channel pointer, 0 free, 1 reserved by an SFX
+0x4E4  pattern read pointer
+0x4E8  volume (0-128+), tickHz, speed, loop flag
+0x4F0  lastOrder, order (-1 paused, -2 stopped), lastRow, row, savedOrder
+0x4FA  nChannels, maxVoices, rowMask (channels with a cell in the current row)
+0x500  tick, tickPos, rowLen (never read), tickLen
+0x510  voiceMap[3]                    from the song table
```

### 6.5 MusChannel (0x4C)

| Off | Field | Off | Field |
|---|---|---|---|
| `00` | volume envelope state (value 8.8, point index, tick) | `26` | period (used by the mixer) |
| `08` | panning envelope state | `28` | base period |
| `10`–`1B` | note, instrument, volume column, pan column, effect, parameter (each + last value) | `2A` | tone-portamento target |
| `1C` | finetune | `2C`/`2D` | volume 0–64 / pan 0–64 |
| `1D` | bit 0 owns a voice, bits 1–7 last mixed loudness | `2E`/`2F` | channel volume / mix factor |
| `1E` | mixer direction (never read) | `30`/`32` | fadeout volume / fadeout speed ×2 \| released |
| `20` | sample position 18.14 | `34`–`3B` | effect memory (8 slots) |
| `24` | base volume | `3C`/`40` | instrument / sample pointer |
| `25` | last pattern mask | `44`–`4A` | vibrato/tremolo waveforms, auto-vibrato, vibrato and tremolo positions |

---

## 7. Mixing

### 7.1 ARM routines (run from IWRAM)

| Routine | ROM | Job |
|---|---|---|
| `sndArmA_Clear32` | `0800023C` | clear the accumulator |
| `sndArmA_Downmix` | `08000260` | s16 L/R → two s8 buffers, clamped to ±127 |
| `sndArmA_DmaIrq` | `080002A0` | buffer swap countdown (§5) |
| `sndArmB_MixSpan` | `08001840` | resample one sample into the accumulator: `acc += s × vol >> 6` per side, 18.14 position, no interpolation, fast path without end tests when the span cannot reach the end |
| `sndArmB_MixChannel` | `08001968` | per music channel: auto-vibrato, period → step, volume, pan law, calls MixSpan |
| `sndArmA_OldMixSpan` | `08000318` | unused older mixer (8-bit fraction, `>> 7` volumes, forward loops only) |

### 7.2 Pitch

The output rate (16 384 Hz) equals 2¹⁴, and positions have 14 fraction bits, so **the step equals
the playback frequency in Hz**:

```
x    = 7680 - period                       (0..7640; 64 per semitone)
o    = sndOctaveTab[x >> 8]                (octave shift | which third of the table)
step = sndLinearFreq[(x & 0xFF) | (o & 0x300)] * 4 >> (7 - (o & 15))
period = 7680 - finetune/2 - (note + relNote - 13) * 64          (note byte 13 = C-0)
```

`sndLinearFreq[i] = 16726 × 2^(i/768)`. This is exactly FT2's linear frequency (8363 Hz at C-4,
period 4608).

### 7.3 Volume and pan

```
v   = clamp((vol * fade >> 16) * volEnv * mixVol >> 12, 0, 64)
      mixVol = channelVolume * instrumentVolume / 64 * sampleAmp / 64
v   = v * songVolume >> 7                   (songVolume = table volume * caller volume / 128)
L   = sndPanLaw[(64 - pan) * v >> 5] / 2,   R = sndPanLaw[pan * v >> 5] / 2
```

`sndPanLaw[0..128]` is 128·sin(iπ/256), so a centred full-volume voice contributes ±89 to each
side and a hard-panned one ±127. The accumulator is clamped to ±127 (saturation, not wrap) when
it is converted to 8 bits. Song volumes go up to 200/128, so loud songs can clip.

SFX voices use the same law with a 0–127 pan: `L = sndPanLaw[(128 − pan) × dry >> 7]`, where
`dry = vol × (128 − wide) / 128`. When `wide > 4`, `sfxMixVoiceWide` adds a second tap with volume
`vol × wide / 128`, ¼ sample ahead, panned towards the centre and with the **right channel
inverted**, which widens the stereo image.

### 7.4 Voice allocation

`musAllocVoice` runs on every note:

* **≤ 8 channels:** channel *n* always uses voice *n*.
* **> 8 channels:** a free voice, otherwise the voice whose last mixed loudness is lowest and
  below the new note's volume. The loser keeps playing silently (its position still advances).

When an SFX starts, `musReserveVoice` marks voice `voiceMap[k] − 1` (or `7 − k` when the map entry
is 0) as taken by SFX voice *k*; the music channel on it goes silent. When the SFX ends the voice is
freed, but the channel only gets a voice back at its **next note**. Several songs map all three SFX
voices to the same music voice (e.g. `BGM_1B`: 4,4,4), sacrificing only one channel.

---

## 8. Data formats

### 8.1 Song table (`0x08DDD860`, count at `0x08DDD85C`)

```
u32 module; u16 volume (x/128); u8 voiceMap[3]; u8 flag (read only by the game); u16 0
```

### 8.2 Module

```
+0x000  char name[32]                ("BGM_1AXM" ...)
+0x020  char tracker[20]             ("untitled")
+0x034  u16 songLength, restart, channels, patterns, instruments, speed, BPM, flags (0)
+0x044  u8  orders[256]
+0x144  s16 insMap[128]              module instrument n+1 -> musInstruments[insMap[n]]
+0x244  u8  chanSet[32][2]           channel volume, pan (all 64, 32 in MvDK)
+0x284  {u32 rows, u32 offset}[patterns]     offset from the module start
        packed patterns, each 4-byte aligned
```

### 8.3 Packed rows

Each row is a list of cells ended by a 0 byte:

```
b = channel byte: bits 0-5 = channel + 1, bit 7 = a new mask byte follows
mask (else: the channel's previous mask):
    0x02 instrument byte      0x20 reuse last instrument
    0x04 volume + pan bytes   0x40 reuse last volume + pan
    0x08 effect + parameter   0x80 reuse last effect + parameter
    0x01 note byte            0x10 reuse last note
field order in the stream: instrument, volume, pan, effect, parameter, note
```

* **Note:** 1–120 (13 = C-0, so XM note = byte − 12), 121 = key off, > 121 = note cut.
* **Volume column:** the XM encoding (`0x10`–`0x50` set, `0x60`/`0x70` slides, `0x80`/`0x90`
  fine slides, `0xA0`–`0xF0` …).
* **Pan column:** 0–64, `0x80` = none. The converter moved `8xx` here (values ÷ 4).
* **Effects:** `0x00`–`0x0F` = XM `0`–`F`; `0x17`/`0x18` = `X1x`/`X2x`; `0x19 + x` = `Ex`
  (e.g. `0x22` = `E9x`, `0x26` = `EDx`). The rows cannot be entered anywhere but at the start
  (§11).

### 8.4 Instrument (0x13C)

```
+0x00  char name[22]; u8 volume (64); u8 pan (bit 7 = override the channel pan)
+0x18  u16 sampleCount, 0
+0x1C  u8  keymap[120]              note 1..120 -> sample
+0x94  Envelope volume; +0xE4 Envelope panning
+0x134 u16 fadeout, 0; +0x138 SampleHeader *samples
Envelope (0x50): {u16 x, y}[12]; u8 count, sustain, sustain (copy), loopStart, loopEnd,
                 type (1 on, 2 sustain, 4 loop); s16 slope[12] (y<<7 per tick); u16 0
```

The per-segment slopes are precomputed by the converter, so the player never divides.

### 8.5 Sample header (0x30)

```
+0x00 u32 length, loopStart, loopLength     24.8 fixed point (bytes << 8)
+0x0C u8 volume; u8 amp (x/64); s8 finetune; u8 loopType (0 none, 1 forward, 2 ping-pong)
+0x10 u8 pan (bit 7 = none); s8 relNote; char name[22]
+0x28 u8 vibType (> 2 = off), vibRate, vibDepth, vibSweep (ignored); u8 *data (8-bit signed)
```

In MvDK: no ping-pong loops; 105 of the 328 headers are 1-byte stubs (unused keymap slots; no note
in any song reaches one); 13 samples use auto-vibrato; the amp factor is below 64 for 200 headers (100 of them real samples).

### 8.6 SFX entry (0x1C, table at `0x08B92E24`, count at `0x08B92E20`)

```
u32 length; u8 *data; u32 rate (Hz); char *name; u16 volume (x/128); u8 priority; u8 flag (not read);
u32 loopStart, loopEnd (bytes; used when sfxPlay's loop flag is set)
```

### 8.7 Driver tables (`mvdk_sound_rodata.s`)

| Table | Address | Contents |
|---|---|---|
| `sndLinearFreq[768]` | `08B91F60` | 16726·2^(i/768) |
| `sndVibratoTables[3][64]` | `08B92560` | sine, square, ramp (s32, ±65536); no random table |
| `musFxMemSlot[41]` | `08B92860` | effect → memory slot |
| `sndOctaveTab[31]` | `08B9288C` | octave shift and table third |
| `musArpOffsets[16]` | `08B92908` | 64·n |
| `musTickFxTable[41]` | `08B92948` | tick handlers |
| `sndPanLaw[513]` | `08B929EC` | 0–128 sine quarter, then linear |
| `psgRegTab[4]` | `08B92DF0` | PSG register pairs and masks |

---

## 9. Sequencer and effects

### 9.1 Row and tick processing

At the first sample of a row `musMix` reloads the pattern pointer if the order changed, advances
the row counter (and the order, skipping order entries ≥ the pattern count, looping to `restart`
or stopping), then `musReadRow` decodes the row. For each cell: instrument (sets instrument, resets
volume/pan to the **previous** sample's defaults), note (picks the sample from the keymap, resets
position, envelopes, fadeout, volume; allocates a voice), pan column, **row effect**, volume
column.

At the first slice of every tick, `musMixSlice` restores `period`/`vol` from their base values and
then, for channels **with a cell in the current row**, runs `musTickVolume` (fadeout,
volume-column slides, envelopes) and the effect's tick handler; channels without a cell only run
their envelopes. Every tick handler also mixes the channel. Effects run on **all** ticks
including tick 0; the slides test `gMusTick != 0` themselves.

### 9.2 Effect support

| Effect | Support | Used in MvDK |
|---|---|---|
| `0xy` arpeggio | yes (0, x, y by tick % 3) | — |
| `1xx`/`2xx` porta | yes, ×4 period units, memory | 15 / 790 cells |
| `3xx` tone porta | yes, memory | — |
| `4xy` vibrato | yes, advances on tick 0 too, disables auto-vibrato | — |
| `5xy`/`6xy` | yes | — |
| `7xy` tremolo | yes | — |
| `8xx` pan | raw value on the 0–64 scale (128–255 end up hard left) | converted to the pan column |
| `9xx` offset | yes | — |
| `Axy` volume slide | yes, **no memory** (A00 does nothing) | — |
| `Bxx` jump | yes; **stops the song** when not looping | — |
| `Cxx` volume | yes | — |
| `Dxx` break | decimal row; the stream cannot seek (§11) | — |
| `Fxx` speed/tempo | ≤ 0x20 speed, else BPM | 139 cells, BPM 100–240 |
| `E1x`/`E2x`, `X1x`/`X2x` | yes (no memory) | — |
| `E4x`/`E7x` waveform | yes (waveform 3 → sine) | — |
| `E8x` pan | raw 0–15 on the 0–64 scale | — |
| `E9x` retrig | every x+1 ticks | — |
| `EAx`/`EBx` | yes | — |
| `ECx` cut, `EDx` delay | yes | — |
| `E3x E5x E6x EEx`, `Gxx Hxx Kxx Lxx Pxx Rxx Txx` | no | — |
| volume column set | `0x10`–`0x4F` (**0x50 is ignored**) | 60 990 cells |
| volume column slides `6x 7x 8x 9x`, `Dx Ex` pan slides | yes (per tick incl. tick 0) | — |
| volume column `Ax` vibrato speed | yes | — |
| volume column `Bx` | sets the vibrato **waveform** (should be depth) | — |
| volume column `Cx` pan | raw 0–15 (should be ×4) | — |
| volume column `Fx` tone porta | no | — |
| pan column | yes | 3 425 cells |
| key off (121) | starts the fadeout; envelopes leave sustain | 39 751 cells |

Only `1xx`, `2xx`, `Fxx`, volume-column "set volume", the pan column and key-off occur in the data.

---

## 10. PSG sequencer (unused)

`psgInit` (called by `sndInit`) starts **Timer 0 at 256 Hz with its IRQ**, so `psgTimerIrq` runs
256 times a second for the whole game, only to find the sequencer idle. `psgPlay` is never called.
Its data format: 16 bytes of wave RAM, three initial frequencies at `+0x20`, an event count at
`+0x26` and 8-byte events `{u16 delay, u8 channel, u8 type, u16 a, u16 b}` at `+0x28`; type 0 writes
the channel's two registers, type 1 starts a frequency slide. The slides are applied to PSG 1–3 each
IRQ. `psgPause`/`psgResume` mute and unmute through `SOUNDCNT_L`.

---

## 11. Bugs, quirks and dead code

### 11.1 Audible or potentially audible in MvDK

1. **Fadeout only advances on rows where the channel has a cell.** `musTickVolume` (which applies
   the fadeout) is only called for channels in the row mask. After a key-off on an instrument
   with a volume envelope, the envelope's release still ends the note, so this rarely shows. The
   three instruments without a volume envelope (`softbass`, the two voice clips in
   `INTRO_FINALBOSS`/`INTRO_FINALBOSS2`) keep sounding after their key-offs, where FT2 would cut
   them. The XM export removes those 22 key-offs so that it sounds like the game.
2. **Envelope timing.** The tick counter is not advanced on the tick that reaches a point, so every
   envelope segment lasts one tick longer than written.
3. **Tempo.** `tickHz = BPM × 2 / 5` truncated: up to 1.6 % slow for BPMs that are not multiples
   of 2.5.
4. **DMA IRQ countdown and masked interrupts** *(inferred, not measured)*: the buffer swap needs
   every DMA1 IRQ (one per 0.98 ms), but `sndFrame` runs inside the VBlank IRQ with interrupts
   masked. If the VBlank handler runs longer than ~1 ms, IRQ requests merge, the countdown falls
   behind and the DMA plays past the end of the 288-byte buffer (into the right buffer / the next
   buffer) before swapping.

### 11.2 Latent (the data never triggers them)

1. **Looped envelopes freeze.** With the loop flag set, arriving at any point other than the loop
   end does not advance to the next point, so the envelope stops at its first point. No MvDK
   envelope has the loop flag.
2. **Ping-pong loops:** the backward loop in `MixSpan` indexes `src[pos >> 8]` instead of
   `pos >> 14`; the direction is lost at every call; `~step` is used for `−step`.
3. **Volume column 0x50** (volume 64) is ignored. All 32 470 such cells come with a note on a
   sample whose default volume is already 64, so it makes no difference in MvDK.
4. **Volume column `Bx`** sets the vibrato waveform instead of the depth; **`Cx`**, **`E8x`** and
   **`8xx`** write their raw values to the 0–64 pan scale.
5. **`Axy` has no parameter memory**; **`E9x`** retriggers every x+1 ticks instead of every x.
6. **Note cut** (note > 121) only zeroes the current volume; the next tick restores it.
7. **Packed patterns cannot seek:** `Dxx` with a row other than 0 starts the next pattern from its
   first row (and ends it early); `Bxx` to the order that is already playing does not reload the
   pattern pointer and reads past the pattern's end.
8. **`Bxx` stops the song** when the song is not looping, instead of jumping.
9. **Volume-column slides** run on tick 0 as well (speed × x instead of (speed − 1) × x).
10. **"Surround" pan** in `MixChannel` (negative pan → right channel inverted) is dead: the pan is
    clamped to 0–64 just before the test.
11. **Silent channels' loop wrap** compares the 18.14 position with an unshifted loop end, so a
    silent looping channel's position is wrong; it is reset by its next note anyway.
12. **Instrument-only cells** reset the volume to the *previous* sample's default; a note without
    an instrument also resets the volume to the sample default (FT2 keeps it).
13. **`sfxPlay` without flags 8/0x10** ORs its whole `flags` byte into the voice flags (only bit 2
    is meant to be kept).
14. **`sfxMixVoice`**: a voice whose dry volume is 0 (full `wide`) ends without releasing the music
    voice it reserved.
15. **`musStart`** clears all voice reservations, so SFX that are playing when a song starts no
    longer hold a music voice.

### 11.3 Dead code and data

* **Functions never called:** `musPlayModule`, `musPlayModule2`, `musRestart`, `musPlayPacked`,
  `sfxCountActive`, `sndIsStereo`, `psgPlay`, `psgPause`, `psgResume`, `sndArmA_OldMixSpan`.
* **`psgTimerIrq`** runs at 256 Hz for nothing; **DMA2's IRQ** is enabled and ignored.
* **`rowLen`** is computed (and even patched from 945 to 944 samples when `Fxx` sets exactly speed 3
  / 130 BPM) but never read.
* **Profiling counters** `gSndCpuLast`/`gSndCpuTotal` difference a timer variable that nothing
  writes. `gMusCurChannel` and `MusChannel.dir` are written and never read.
* **Instrument byte `+0x32`** of each envelope duplicates the sustain point and is not read.
* **SFX entry flag** (`+0x13`) and **song entry flag** (`+9`) are not read by the driver.

---

## 12. Content inventory

| | |
|---|---|
| Songs / modules | 70 / 70, names from the modules (`BGM_1A` … `OUTRO_MINIGAME`) |
| Channels | 1–8 per module, so every song uses the fixed channel → voice mapping (no stealing) |
| Patterns / rows | 774 patterns, 97 902 rows, 101 542 cells, 60 989 notes |
| Instruments | 156 (all volume 64, fadeout 1024 but one; 84 with volume envelope + sustain, 69 envelope without sustain, 3 without) |
| Samples | 328 headers, 124 PCM blocks, 1.19 MB; 105 one-byte stubs |
| SFX | 254 entries: 230 sounds (211 at 8 000 Hz, 18 at 11 025, 1 at 16 000), 24 stop entries, 2 with loop points |
| Song volumes | 75–200 (/128) |
| Voice maps | 26 songs reserve specific voices for SFX, the other 44 use the default (8, 7, 6) |

Per-song details (orders, instrument maps, every pattern) are in `mvdk_data_dump.txt`; the same
without patterns in `mvdk_data_summary.txt`.

---

## 13. Notes for reimplementation or tooling

* **Converting to XM** (`mvdk_tool.py xm`): note − 12; 121 → key off; volume column unchanged; pan
  column → `8xx` (×4); effects `0x17`/`0x18` → `X1x`/`X2x`, `0x19 + x` → `Ex`; instruments from the
  shared bank through `insMap`, keymap shifted by 12, envelopes/fadeout/relNote/finetune
  unchanged, auto-vibrato moved from the sample to the instrument, the amp factor baked into the
  PCM. All 70 exported modules load and play in libopenmpt.
* **To sound like the game**, a player must also: use 16 384 Hz with no interpolation and 8-bit
  saturation; apply the integer tick lengths; not advance the fadeout on rows without a cell; let
  SFX mute the music channel given by the voice map until its next note; apply the song volume.
* **Sample positions** are 18.14 fixed point, and sample lengths are stored as bytes << 8.

---

## 14. Deliverables

In `…/GBAAudioLab/Nint2/`:

| File | Contents |
|---|---|
| `mvdk_sound_thumb.s` | labelled Thumb source of the driver, with pseudo-C above every function |
| `mvdk_sound_arm.s` | the two ARM modules |
| `mvdk_sound_rodata.s` | constant tables |
| `mvdk_sfx_data.s` | SFX table, names and PCM (`.incbin mvdk_sfx_pcm.bin`) |
| `mvdk_music_data.s` | song table, sample headers, instruments, modules; every packed row decoded in a comment (`.incbin mvdk_music_pcm.bin`) |
| `mvdk_sound.inc` | RAM addresses, IO registers and every structure field |
| `mvdk.ld`, `mvdk.mk`, `romcheck.py` | link at the original addresses and compare with the ROM |
| `mvdk_tool.py` | `dump`, `summary`, `wav`, `xm` |
| `mvdk_data_dump.txt`, `mvdk_data_summary.txt` | decoded data |
| `mvdk_xm.zip` | the 70 songs as `.xm` |
| `mvdk_wav.zip` | 123 music samples and 230 SFX as WAV (with loop points) |

`make -f mvdk.mk check ROM="Mario vs. Donkey Kong (E) (M5).gba"` (needs `arm-none-eabi-as/ld/objcopy`)
rebuilds all seven ranges of §2 and reports them **byte-identical** to the ROM.

---

## Appendix A: function map

```
Thumb (0x080725D8-0x08074F40)
080725D8 sfxMixVoice          080726D8 sfxMixVoiceWide      0807278C sndInit
08072920 sndFrame             08072A6C sndVBlank            08072AB0 sfxPlay
08072CEC sndDmaIrq            08072D00 sndDmaStop           08072D20 sndDmaStart
08072D44 sfxStopAll           08072D8C sfxStopAllExcept     08072DF4 sfxStopLooping
08072E48 sfxSetPan            08072EBC sfxStop              08072F34 sfxStopId
08072F9C sfxStopPriority      08073004 sndShutdown          08073030 musPlayModule
0807304C musPlayModule2       08073068 musRestart           08073084 musGetSongVolume
08073098 musGetSongModule     080730AC musGetSongVoiceMap   080730C0 musPlayModuleEx
08073104 musGetCurrentSong    08073158 musGetModule         0807316C musPlaySong
080731CC musStop              08073204 musPause             08073238 musResume
08073260 musIsStopped         08073284 sfxCountActive       080732C0 sfxIsDone
08073310 sndIsStereo          08073324 sndSetStereo         08073348 sndHeapInit
08073384 sndHeapAlloc         080733B0 sndHeapReset         080733BC musAllocVoice
0807347C musReadRow           08073864 musEnvelopeTick      08073940 musTickVolume
08073A04 fxArpeggio           08073B18 fxPortaUp            08073B9C fxPortaDown
08073C24 fxTonePorta          08073CBC fxVibrato            08073D88 fxTonePortaVolSlide
08073E68 fxVibratoVolSlide    08073F78 fxTremolo            08074040 fxVolumeSlide
080740DC musMixSlice          080742D8 musRowEffect         08074578 musVolumeColumn
0807460C musStart             080746E4 musReset             080747B4 musMix
0807496C musPlayPacked        08074990 musSetParams         080749E8 musReserveVoice
08074A24 musReleaseVoice      08074A58 fxNone               08074ABC fxRetrig
08074B40 fxNoteCut            08074BB8 fxNoteDelay          08074C24 psgInit
08074C9C psgTimerIrq          08074DF4 psgPlay              08074ED0 psgPause
08074EF4 psgResume            08074F20 psgStop
ARM
0800023C sndArmA_Clear32      08000260 sndArmA_Downmix      080002A0 sndArmA_DmaIrq
08000318 sndArmA_OldMixSpan   08001840 sndArmB_MixSpan      08001968 sndArmB_MixChannel
```
