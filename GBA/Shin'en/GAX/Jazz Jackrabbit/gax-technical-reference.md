# Shin'en GAX Sound Engine (GBA): technical reference

Covers GAX **v1.99d through 3.05A**: song data, the full pattern (sequence) format, instruments, samples, pitch and volume, mixing, version differences, and the gaxm converter's bugs. Companion file: `claude/gax-data-dump.md` (every song in the eight test ROMs).

**Sources.** Engine code:

* the matched C decompilation of **GAX 2.01D** in the Crash Bandicoot XS decomp (`lib/gax/`, `docs/audio.md`);
* the work-in-progress decompilation of **GAX 3.05A** (`shinen-gax-decomp-main`, `src/tracker.c` and friends);
* direct ARM/Thumb disassembly of the 1.99d (Iridion 3D) and 3.03A (Iridion II) mixers, to settle points the 3.05A decomp gets wrong.

Every format claim below was checked by an independent parser (`gaxlib.py`) against all 130 songs in eight ROMs (1.99d, 2.01b, 2.35, 3.0, 3.01, 3.03A). In every song, decoding the patterns with the rules in §6 ends exactly at the song's `"title" © artist` string.

Addresses are ROM file offsets unless written as `0x08xxxxxx`.

---

## 1. Versions and format generations

| Version string | Date | Test ROM | Song layer | SongInfo | Instrument layout | Sample PCM | Mix-rate table |
|---|---|---|---|---|---|---|---|
| v1.99d | Mar 13 2001 | Iridion 3D | GAX2 handler graph | 0x14 bytes: no volume, no rate | old (28-byte waves) | **signed** | 12 rates |
| v1.99d | Mar 30 2001 | Earthworm Jim | " | " | " | signed | 12 |
| v2.01b | Jun 22 2001 | Comix Zone, Jackie Chan | GAX2 handler graph | 0x1C bytes | old | signed | 12 |
| 2.01D | Sep 28 2001 | Crash Bandicoot XS (decomp) | " | 0x1C | old | signed | 12 |
| 2.35 | Jun 17 2002 | Bruce Lee | " | 0x1C | old | signed | **13** (+9079) |
| **3.0** | Jul 16 2002 | Tony Hawk's Pro Skater 4 | **GAX3 header** | 0x20 | **old** | **unsigned** | 13 |
| 3.01 | Sep 13 2002 | Jazz Jackrabbit | GAX3 header | 0x20 | **new (0x18 + 24-byte waves)** | unsigned | 13 |
| 3.03A | Mar 5 2003 | Iridion II | GAX3 header | 0x20 | new | unsigned | 13 |
| 3.05A (header says 3.04) | — | (decomp target) | GAX3 header | 0x20 | new | unsigned | 13 |

Key points:

* The **pattern format is identical in every version** (§6).
* **3.0 is a hybrid.** It already has the GAX3 song header, the new unsigned-PCM mixer and the GAX3 API strings, but it still uses the **old instrument struct**. Tools that key the instrument layout on "major version ≥ 3" fail on it. That is the THPS4 failure in gaxm (§13).
* PCM sign: the 1.99d–2.35 resamplers load with `ldrsb` (signed); every 3.x resampler loads with `ldrb` and removes the DC offset after mixing. The gist's comment that "GAX 2 and later use unsigned 8-bit" is wrong: 2.x is signed.
* The version string `GAX Sound Engine <ver> (<date>) © Shin'en Multimedia. Code: B.Wodok` is right in front of the mix-rate table. 2.35+ also have a halt-screen banner `GAX ENGINE V<ver> <date>`. Jazz Jackrabbit contains **two** 3.01 engine copies (`0x00175B4`, `0x03DFB70`).

### 1.1 Mix rates

Each table entry is `{rate, Timer0 reload}`: u32 pairs up to 2.01D, u16 pairs from 3.0. A requested rate is rounded **up** to the next entry.

* 1.99d–2.01D (12 rates): 5735, 10513, 11469, 13380, 15769, 18158, 21025, 26760, 31537, 36316, 40138, 42049
* 2.35+ (13 rates): the same list plus **9079**, inserted after 5735

---

## 2. Finding songs

**GAX3 (3.0+).** A song is the 0xC8-byte header in §3.2, found with these tests:

* `nch` is 1–32;
* `rows` is 1–0x1FF and `orders` is 1–0xFF;
* `loop` < `orders`;
* the three data pointers are in ROM;
* exactly `nch` channel pointers are non-NULL and the rest are 0.

This finds every song and nothing else in all four 3.x ROMs.

**GAX2 (≤ 2.35).** A song is a pointer list `{u32 count; mixer*; info*; unk*; channel*[count-3]}`. Accept it when all of these hold:

* the mixer and info handlers have ROM function pointers;
* `info.data` passes the SongInfo checks above;
* `mixer.childCount` equals `nch`;
* every mixer child's data pointer is in ROM.

**Title.** The song title sits immediately after the **highest-addressed byte of pattern data** consumed by any channel. It is padded with zeros to a word boundary and is often *not* NUL-terminated when it ends exactly on one. No pointer refers to it. The trailing junk bytes the dump shows (e.g. `© Manfred LinznerU\x01`) are the start of the following pattern table.

---

## 3. Song layer

### 3.1 GAX2 (v1.99d – 2.35): handler graph

A song is a set of "SoundHandler" types (Crash decomp names in brackets).

```
GAX2_Song                       [GaxHandlerLayout]
  +00 u32  count                = 3 + channels
  +04 ptr  mixer handler type   (children = channel types, data = echo params)
  +08 ptr  info handler type    (data = SongInfo)
  +0C ptr  layout list / same in every song of a ROM
  +10 ptr  channel type[count-3]

HandlerType (28 bytes)          [GaxHandlerType]
  +00 init_fn   +04 unknown_fn (always an empty stub)   +08 play_fn
  +0C u32 childCount            +10 ptr childTypes[]
  +14 u32 instanceSize          (gaxm calls it "TypeFlags"; e.g. 0x1C info, 0x4C channel, 0x48 SFX voice)
  +18 ptr data                  info -> SongInfo, channel -> order table, mixer -> echo params
```

Each channel type has one child, a shared one-entry array that points at the info type. The mixer's children array lists the channel types in **logical** channel order. Their physical order in ROM can differ.

**Mixer data** (28 bytes: 7 × u32): `{echoChannels, delay0_ms, gain0, delay1_ms, gain1, delay2_ms, gain2}`.

* An echo buffer of `delay * mixRate / 1000` samples is allocated.
* Each tap is added as `sample * gain >> 4`.
* `echoChannels`: the song's first *n* channels are mixed before the echo pass, so they get the echo.
* All zero = no echo.
* Examples: Iridion 3D uses `(4, 200,7, 145,3, 0,0)`; Bruce Lee uses `(2,120,4,…)`.

### 3.2 GAX3 (3.0 – 3.05A): flat song header (0xC8 bytes)

```
+00  SongInfo (0x20 bytes, §4)
+20  ptr  orderTable[32]      one per channel; entries >= nch are NULL
+A0  u32  echoChannels        (same meaning as the GAX2 mixer data)
+A4  u32  delay_ms[3]
+B0  u32  gain[3]
+BC  u32  ?  +C0 u32 ?  +C4 u32 ?   (Iridion II: BC = C0 = delay_ms[0], C4 = 0; zero elsewhere)
```

Sound-effect banks use the same SongInfo with `nch = 0`, reached through `GAXParams.fx_data`.

---

## 4. SongInfo

| Off | 1.99d | 2.x | 3.x | Meaning |
|---|---|---|---|---|
| 00 | u16 | u16 | u16 | channels (`num_channels`) |
| 02 | u16 | u16 | u16 | rows per pattern (`num_steps_per_pattern`); one value for the whole song |
| 04 | u16 | u16 | u16 | orders per channel |
| 06 | u16 | u16 | u16 | loop order (restart position after the last order) |
| 08 | — | u16 | u16 | master volume, Q8 (0x100 = 1.0; values over 0x400 occur) |
| 0A | — | u16 | u16 | 0 |
| 0C / **08** | ptr | ptr | ptr | sequence (pattern) data base |
| 10 / **0C** | ptr | ptr | ptr | instrument pointer table |
| 14 / **10** | ptr | ptr | ptr | sample table |
| 18 | — | u16 | u16 | mix rate (Hz) |
| 1A | — | u8 numFx | u16 FX mix rate (0 = same as music) | |
| 1B | — | u8 halfRateFx | — | 2.x: mix SFX voices at half rate |
| 1C | — | — | u8 FX channels | |
| 1D | — | — | u8 (0) | |
| 1E | — | — | u16 (0) | |

In 1.99d the three pointers sit at 0x08/0x0C/0x10 and the struct ends at 0x14. gaxm's exception for "1.99f" adds the volume field; no 1.99f ROM was available to check that.

---

## 5. Order table (per channel)

One 4-byte entry per order position:

```
+0 u16 offset of the pattern from SongInfo.sequence data   (patterns are shared by offset)
+2 s8  transpose in semitones (added to the pattern note, not to fixed-pitch instrument notes)
+3 u8  0
```

Every channel advances through its list in lock-step. There is no separate pattern-number layer: an "order" *is* the pattern reference. Sequence data per song is therefore limited to 64 KiB.

---

## 6. Pattern (sequence) data format

This was missing from every public source. It is identical in `GaxChannelDecodeRow` (2.01D) and `GAXTracker_process_step` (3.05A), and it validates against all 130 songs.

**Header.** A pattern starts with a single **empty flag** byte. If it is non-zero, the whole pattern is silent and nothing more is read. Otherwise the step stream follows, and exactly one step is consumed per row:

| First byte | Size | Meaning |
|---|---|---|
| `0xFF n` | 2 | **Run of empty rows**: this row and the next `n-1` are empty (engine sets `rowSkip = n-1`; `n = 0` would mean 256 rows). |
| `0x80` | 1 | One empty row. |
| `0x81`–`0xF9` (bit 7 set, low 7 bits 1–121) | 2 | **Note + instrument**, no effect: `note = b & 0x7F`, `instrument = next byte`. |
| `0xFA`–`0xFE` (low 7 bits 122–126) | 3 | **Effect only**: `effect = b1`, `param = b2`. Only `0xFA` is ever written by the editor. |
| `0x00`–`0x7F` | 4 | **Full step**: `note, instrument, effect, param`. |

**Field meanings:**

* **note:** 0 = no note; 1 = **note off**; 2–121 = pitch, where **2 = C-0** and pitch index = `(note-2)*32` (1/32 semitone).
* **instrument:** 0 = keep the current instrument (no retrigger); 1–255 = index into the instrument table.

**What a step does**, in this order:

1. **Note** (skipped when the effect is `3`, tone portamento):
   * note 1 = release. If the instrument's envelope has **no sustain point**, the note is cut at once.
   * note ≥ 2: `pitch = (note-2)*32` and the release flag is cleared.
2. **Instrument** (if ≠ 0): rebind and **restart** everything per-note:
   * envelope position, vibrato phase/delay, instrument-sequence position/timer/loop counter;
   * `vol = 0xFF`, tone-porta state, sequence speed.
   * Instrument 0 in the table is a `blank` placeholder.
3. **Effect** (§7).

The **legato note**, `note ≥ 2` with instrument 0, is frequent (1164 times in Iridion II, 862 in Iridion 3D). It only changes the pitch. Sample, envelope and instrument sequence keep running.

No end marker exists: a pattern is exactly `rows` steps long. The next pattern, or the title, follows directly. Patterns are stored once and shared between channels and orders.

---

## 7. Pattern effects

Per-row slides are reset at the start of every row. All per-tick effects act on **every tick including the first** (unlike XM).

| Cmd | Name | Semantics (from the engine) |
|---|---|---|
| 1xx | Porta up | `pitch += xx` per tick, units of 1/32 semitone. |
| 2xx | Porta down | `pitch -= xx` per tick. |
| 3xx | Tone porta | The note is *not* triggered. `rate = (target - pitch) / xx`, so **xx is the number of ticks to arrive**, not a speed. The slide continues across rows until it crosses the target, then snaps to it. If an instrument is also given, it *is* retriggered. |
| 7xy | Alternating speed | `speed = x \| y<<8`. Rows alternate between x and y ticks (swing / fractional tempo); the current row lasts x ticks. |
| Axx | Volume slide up | `vol += xx` per tick, 0–255 scale, clamped. |
| Bxx | Volume slide down | `vol -= xx` per tick. |
| Cxx | Set volume | `vol = xx` (0xFF = unity in 2.x). |
| Dxx | Pattern break | Jumps to **row 0** of the next order. `xx` is stored but never read (every ROM stores 00). |
| EDx | Note delay | Note and instrument are applied after x ticks, with the effect dropped. Other `Exx` values do nothing. |
| Fxx | Set speed | Ticks per row = xx (up to 255; Iridion II uses F30 = 48). **F00 stops the song** (the info handler stops advancing and sets "song end"). |
| 0, 4, 5, 6, 8, 9 | — | Ignored by the pattern decoder. 5, 6 and 8 exist only in instrument sequences. |

Effects used across the eight ROMs: 1 2 3 7 A B C D E F.

---

## 8. Timing and song position (Info handler)

* One tick per `GAX_play` call, i.e. one per video frame (59.73 Hz). The XM equivalent is 149.3 BPM.
* Every song starts at speed 6 (`GaxInfoResetPosition`).
* A new row starts when the low byte of `speed` is non-zero and the tick counter reaches 0. If the high byte is set, the two bytes swap on every row (7xy).
* At the end of a pattern (`row >= rows`, or a pending Dxx), `orderPos++`. Past the last order the song:
  * stops if it was started as a jingle or with `GAX_STOP_ON_SONGEND`;
  * otherwise jumps to `loop`.
  * Either way it sets `songEnded`.

---

## 9. Instruments

The instrument table is `ptr[]`, indexed by instrument number. Entry 0 is the blank placeholder (`+00 = 1`).

### 9.1 Common header

```
+00 u8  blank            (non-zero = empty placeholder)
+01 u8  wave[4]          sample-table index for wave slots 1-4 (0 = none)
+05 u8  pad[3]           (the 3.05A decomp mislabels these as vibrato fields)
+08 u8  vibratoDelay     ticks before the vibrato phase starts moving (no fade-in)
+09 u8  vibratoDepth     0 = off
+0A u8  vibratoSpeed     phase step per tick on a 64-entry sine (±127)
+0B u8  0
```

Vibrato offset = `sine[phase] * depth >> 8` (1/32 semitone), i.e. up to about depth/64 semitones.

### 9.2 Old layout (v1.99d – **3.0**), size 0x8C

```
+0C  WaveParam2[4]   (4 x 28 bytes)
+7C  ptr  volume envelope
+80  ptr  second envelope (one flat point, never read)
+84  u8   sequence speed (ticks per step, 0 = no sequence)
+85  u8   sequence length
+86  u16  0
+88  ptr  instrument sequence
WaveParam2 (28): +00 u8 modulate  +01 u8 pingpong  +02 u16 0
                 +04 s32 start  +08 s32 loopStart  +0C s32 loopEnd
                 +10 s32 modSize  +14 s32 modStep  +18 u16 modSpeed  +1A s16 tune
```

### 9.3 New layout (3.01+)

```
+0C  ptr  volume envelope
+10  u8   sequence speed
+11  u8   sequence length
+12  u16  0
+14  ptr  instrument sequence
+18  WaveParam3[n]   n = highest wave slot used by the sequence (24 bytes each)
WaveParam3 (24): +00 s16 tune  +02 u8 modulate  +03 u8 pingpong
                 +04 s32 start  +08 s32 loopStart  +0C s32 loopEnd
                 +10 s32 modSize  +14 u16 modStep  +16 u16 modSpeed
```

Field names follow the GHX2 editor screenshot used by the 3.05A decomp (`init`, `min`, `max`, `mod_size`, `mod_step`, `mod_speed`). For 3.03A, disassembly confirms that `modulate` is at wave+2 and `pingpong` at wave+3.

### 9.4 Volume envelope

```
+0 u8 pointCount  +1 u8 sustain (0xFF = none)  +2 u8 loopStart  +3 u8 loopEnd (0xFF = none)
+4 point[pointCount], 8 bytes each: u16 tick, s16 slope (Q8 per tick from the previous point), u8 volume (0-255), u8 pad[3]
```

The engine runs the envelope position like this:

1. **Sustain:** the position holds on the sustain tick until release.
2. **Loop:** while the note is held, reaching `loopEnd`'s tick jumps back to `loopStart`'s tick. The loop stops at release.
3. **Last point:** the position holds there. If that point's volume is 0 and no loop reaches it, the note ends.

The value between points is `prev.volume + (pos - prev.tick) * cur.slope >> 8`. The result is truncated to u8, so some slopes in the data are stored modulo 256.

The point count can exceed XM's limit of 12: Iridion II "tutorial" instrument 0x12 has 16 points.

### 9.5 Instrument sequence ("perf list")

Each instrument also has a per-instrument step sequence. It runs alongside the pattern at its own speed (`sequence speed` ticks per step; 0 = no sequence). Arpeggios, drum kits and attack/decay changes live here.

Entry (8 bytes):

```
+0 u8 note    0 = keep; else seqPitch = (note-2)*32
+1 u8 fixed   1 = ignore the pattern note and transpose (fixed-pitch drums, SFX)
+2 u8 wave    1-4 = switch wave slot and restart the sample at `start` (0 = keep)
+3 u8 0
+4 u16 fx0    = cmd<<8 | param
+6 u16 fx1    = cmd<<8 | param
```

Sequence commands:

| Cmd | Effect |
|---|---|
| `1xx` / `2xx` | seqPitch ± xx per tick |
| `5xx` | Go to step xx, with the loop counter |
| `6xx` | Set the repeat count to xx+1 |
| `Axx` / `Bxx` | Wave-volume slide |
| `Cxx` | Set wave volume (resets to 0xFF on each wave switch) |
| `Fxx` | Set the sequence speed |

Past the last step the sequence stops.

---

## 10. Samples

The sample table is `{ptr data; u32 length}[]`, indexed by `instrument.wave[slot]`.

* **Entry 0** is a dummy whose data pointer marks the start of the sample pool. In 3.03A, the mixer computes a one-shot sample's wrap distance relative to entry 0's data pointer (seen in disassembly at `0x0801BD1E`). The note ends once the position passes the sample end.
* PCM is 8-bit mono, signed (≤ 2.35) or unsigned (3.x). The 3.x mixer subtracts a DC correction (`dc_correction_val`).
* No per-sample rate is stored. The rate comes entirely from the pitch (§11).

---

## 11. Pitch

```
index = seqPitch                                  (instrument sequence note, (n-2)*32)
      + vibrato
      + [ patternPitch + transpose*32 ]           (omitted when the sequence step is `fixed`)
      + wave.tune                                 (1/32 semitone)
index is clamped to 0..~0xEF3
sample rate (Hz) = period[index] / 2048           (step per output sample, Q11 = period * (2^32/mixRate) >> 32)
```

`period[0] = 1071618`, so index 0 = 523.25 Hz. Index 1536 (pattern note C-4 with seqPitch 0 and tune 0) = **8372 Hz**: within 2 cents of XM's 8363 Hz at C-4.

* GAX2 stores the period table flat (`gGaxPeriodTable`, 0xEF4 entries).
* GAX3 stores one octave (12 × 32 entries) and shifts it by octave. Octave 9 is shifted left by one.

To convert to XM: XM note = GAX note − 1 + transpose, relative note = `tune/32 + (seqNote-2)`, finetune = `(tune % 32) * 4`.

---

## 12. Volume and mixing

**Channel volume** is the product of these Q8 factors, applied in this order:

1. envelope;
2. wave volume (sequence `C`);
3. pattern volume (`C/A/B`);
4. per-channel API volume;
5. info/global volume;
6. song master volume (music only).

In 2.x, a factor of 0xFF counts as unity.

### 12.1 How a sample plays

The resampler takes the nearest sample, without interpolation. Positions are Q11.

* **Normal loop** (`modulate == 0 && loopStart < loopEnd`): samples play while `pos < loopEnd`, then `pos -= (loopEnd - loopStart)`. The loop region is **[loopStart, loopEnd)**: `loopEnd` is *exclusive* and the length is `loopEnd - loopStart`. This is confirmed in the 1.99d, 2.01D and 3.03A mixers.
* **Ping-pong** (`pingpong != 0` with a normal loop): at `loopEnd` the direction reverses; going backwards, it bounces off `loopStart`.
* **Modulation / window sweep** (`modulate != 0`, and `loopStart < loopEnd`, `modSize > 0`, `modStep > 0`, `modSpeed > 0`):
  * The sample loops over a window `[pos, pos+modSize)` that starts at `start`.
  * Every `modSpeed` ticks the window moves by `modStep`, bouncing between `loopStart` and `loopEnd`.
  * A PWM-like timbre sweep (40 distinct waves in Iridion 3D, 36 in Iridion II).
  * If `modulate` is set but the sweep conditions fail, the sample plays one-shot.
* **One-shot:** the note ends at the sample's end.
* **Start offset:** every note starts at `start`, not at 0. Iridion II has 67 distinct waves with a non-zero start.

**Correction to the 3.05A decomp.** `GAXTracker_generate_audio` (56% match) has the loop test inverted (`use_modulation = modulation && min < max`). The 3.03A ROM tests `ldrb [wave+2]; bne` → no loop. A plain loop therefore requires `modulate == 0`, as in 2.01D.

---

## 13. gaxm: investigation and fixes

gaxm (byvar/gaxm @ c79910e + BinarySerializer.Audio.GBA @ d3ec399) was built here for .NET 8 and run on all eight ROMs.

| Issue | Root cause | Fix (in `gaxm-fixes.patch`) |
|---|---|---|
| **THPS4 does nothing** (stage 1) | `GAX_Settings` parses "3.0" as minor `"0".TrimStart('0') = ""`, so `int.TryParse` fails. The version scan therefore keeps reading strings at every pointer target, hits one within 17 bytes of the end of the ROM, and an uncaught `EndOfStreamException` aborts the program. | Treat an empty minor as 0; bounds check plus try/catch in `FindVersion`. |
| **THPS4: no songs found** (stage 2) | 3.0 uses the *old* instrument struct, but gaxm picks the layout by `MajorVersion >= 3`, so it reads `RowsPointer` from the wrong offset, gets `Rows = null`, and `Rows.Max()` throws for every song. | `UsesV3InstrumentFormat` = 3.01+; samples stay unsigned for every 3.x (`UsesUnsignedSamples`). |
| **Iridion II "tutorial" fails** | Instrument 0x12 has a 16-point envelope; `PointsForVolumeEnvelope` holds 12 → `IndexOutOfRangeException`. | Reduce to ≤ 12 points (keep first/last/sustain/loop points, drop the least significant interior points). |
| **Loop point off by one** | XM loop length was `(LoopEnd - LoopStart) - 1`; the engine's loop end is exclusive. | Length = `LoopEnd - LoopStart`. |
| Loops on sweep-mode waves | `loop = LoopStart != 0 \|\| LoopEnd != 0` ignored the `modulate` flag. | Loop only when `modulate == 0 && start < end`. Sweep waves loop their initial `modSize` window; the `start` offset is honoured by trimming the sample. |
| Iridion 3D "empty", Iridion II "fx" missing | All patterns are empty, so there are no instruments, and `InstrumentSet.Max()` throws on an empty sequence. | Guard empty sets. |
| Bruce Lee "Title/UI" not written | `/` in the file name. | Sanitize file names. |
| **Legato notes become silence** | A note with instrument 0 was written with the XM instrument for GAX instrument 0, the blank placeholder. | No instrument column plus `3FF` (or volume-column `FF`) to change pitch without a retrigger. |
| Tone portamento wrong | GAX `3xx` = ticks to the target; gaxm copied it as an XM speed. | Speed computed from the note distance and the current ticks per row. |
| 1xx/2xx, A/B wrong scale; A/B doubled | GAX units: 1/32 semitone and 1/255 volume per tick, on every tick. gaxm also wrote a volume-column fine slide *and* `Axy`. | Scaled per row speed; single effect. |
| Cxx: 0xFF → 63 | `>> 2`. | `(p*64+127)/255` (0xFF → 64). |
| Dxx row | The engine always starts the next pattern at row 0. | Write `D00`. |
| Vibrato rate | `speed % 0x3F`; GAX's sine has 64 steps, XM's 256. | `speed * 4`. |
| 0xFB–0xFE steps, `FF 00` | Mapped to NoteOnly / 0 rows. | Effect-only / 256 rows, as in the engine (absent from these ROMs; correctness only). |

After the patch, gaxm converts **130 / 130** songs: 12 + 24 + 11 + 24 + 30 + 10 + 9 + 10, with zero exceptions. Every XM loads in libopenmpt 0.7.3; THPS4 "gummy yap", for example, renders 55.9 s of non-silent audio. Before the patch: THPS4 0/10, Iridion II 28/30, Iridion 3D 23/24, Bruce Lee 11/12.

**Remaining XM limitations** (inherent to the format, not bugs):

* Instrument sequences are reduced to their first step, so arpeggios, multi-wave drums and sequence volume changes are lost.
* Window sweeps become static loops.
* 7xy becomes an average speed, and speeds above 31 are clamped.
* GAX slides act on tick 0 too.

A custom player built on `gaxlib.py` / the decomps is the only exact route.

---

## 14. Corrections to loveemu's gist

* PCM: signed in 1.99d–2.35, unsigned in 3.x (not "GAX2+ unsigned").
* Mix rates: 9079 Hz exists only in 2.35+. 1.99d–2.01D have 12 rates.
* FX channels: `MAX_FX_CHANNELS` = 8 in 3.05A (not "up to 4").
* The v2 SongInfo has no FX-rate field; it ends with `u16 mixRate, u8 numFx, u8 halfRateFx`. 1.99d has neither these nor the volume field.
* Instrument header, envelope, instrument sequence and the sequence (pattern) data are documented above (§6–9). They were TBA in the gist.

## 15. Open questions

* GAX3 header words `+BC`, `+C0`, `+C4` (copies of the first echo delay in Iridion II).
* SongInfo 3.x `+1D` and `+1E` (always 0 in the test set).
* Instrument `+80` second-envelope pointer in the old layout: never read in 2.01D. Does any version use it?
* Whether "1.99f" really adds the volume field (gaxm assumes so; untested).
* The GAX3 speech path (`GAX_SPEECH`, `speech.c`) is not covered.
