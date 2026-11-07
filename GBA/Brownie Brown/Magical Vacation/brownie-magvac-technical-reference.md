# Brownie Brown sound driver (Magical Vacation / Sword of Mana)
## Reverse-engineering report and technical reference

**Subject files:** `…/GBAAudioLab/Brownie/Magical Vacation (J).gba` (`AMVJ`, 8 MiB) — primary;
`…/Brownie/Sword of Mana (E).gba` (`AVSP`, 16 MiB) — later revision, compared in §11.

**Provenance.** The ROM has no symbols or sound strings; all names were assigned in this analysis. The Magical
Vacation driver — Thumb glue `0x0805B564`–`0x0805B5B3`, tables `0x0805B5B4`–`0x0805BEAB`, ARM core
`0x0805BEAC`–`0x0805CE7F` (code, jump table, literal pool), tables `0x0805CE80`–`0x0805D2DB`, plus the linker veneer
island `0x080C2044`–`0x080C2073` — has been disassembled into a labelled GNU-as source that rebuilds
**byte-identical** (7 544 + 48 bytes, §10). Every one of the 600 tracks in the 278 sound ids was walked with the
documented command set. The fade step was checked by simulation. Remaining inferences are marked *(inferred)*.

---

## 1. Executive summary

* **Own engine, not MP2K.** About 3.7 KB of hand-written-style ARM code that **runs from ROM** (no IWRAM copy). The
  game reaches it through six one-line Thumb C wrappers and `bx pc` veneers.
* **12 tracks × 0x38 bytes** with fixed hardware roles: 0–3 = PSG music (square 1, square 2, wave, noise), 4–7 = PSG
  sound effects that **mute** 0–3 while they play, 8/9 = **PCM music** on FIFO A/B, 10/11 = PCM SE that mute 8/9
  (unused in MV).
* **No software mixer.** Each FIFO plays exactly one sample stream. Pitch is set by changing the **timer reload**
  (sample rate = 1024·2^(i/144) Hz). The DMA1/DMA2 IRQ handlers copy one word (4 samples) into the FIFO at a time and
  scale each sample by the channel volume on the fly.
* **Byte format:** `00`–`7F` note, `80`–`DF` length from a 96-byte table, `E0`–`FF` commands. There is **no tempo
  command**. The length table has six rows of 16 entries, each a fixed tempo (quarter = 32/40/48/56/36/44 frames).
  One tick = one frame.
* **Envelopes are scripts:** `{frames, NRx2}` pairs for PSG, which re-trigger the channel with each new hardware
  envelope byte, and `{frames, slide, level}` triples for PCM.
* **Pitch:** square MIDI note = n + 36 (note 0 = C2), wave = n + 24, noise byte = NR43 with its nibbles swapped,
  PCM = timer table (root depends on the sample, §5.3).
* **Sound start** goes through a 4-slot u16 queue. `sndFrame` starts at most one id per frame.
* **Sword of Mana** uses a later revision of the same engine: same track struct, header and envelope formats, but 13
  active tracks, conventional FIFO DMA with mixed PCM voices that have L/R volumes, a per-track tempo row and 745 ids (§11).

---

## 2. ROM / RAM map (Magical Vacation)

| Item | Address |
|---|---|
| Thumb glue (6 wrappers) | `0x0805B564`–`0x0805B5B3` |
| Veneers (`bx pc; nop; b`) | `0x080C2044`–`0x080C2073` |
| ARM core | `0x0805BEAC`–`0x0805CD83`; command jump table `0x0805C994` (32 words); literal pool `0x0805CD84`–`0x0805CE7F` |
| PSG frequency table | `0x0805B5B4`: 84 × u16 GB frequency values, note 0 = C2 |
| PSG register tables | `0x0805B65C` CNT_H addresses (8 words), `0x0805B67C` CNT_X addresses (8 words) |
| Pan tables | `0x0805B69C` enable bits[12] (`11 22 44 88` ×3), `0x0805B6A8` masks[12] |
| PCM pitch table | `0x0805B6B4`: 1020 × u16 timer reloads (85 notes × 12 fine steps) |
| Length table | `0x0805CE80`: 96 bytes (bytes `80`–`DF`) |
| Envelope table | `0x0805CEE0`: 72 pointers → scripts at `0x0805D000`–`0x0805D2DB` |
| Song table | `0x0805D2DC`: 278 pointers → headers + sequence data from `0x0805D734` |
| Sample table | `0x0806C988`: 16 pointers to `{start, end, loop}` headers; PCM follows each header |
| Wave table | `0x08097174`: 16 pointers to 16-byte wave patterns |
| Tracks | `0x02000EF0` + 0x38·n, n = 0–11 |
| Sound queue | `0x02001190` u8 read offset, `0x02001191` u8 write offset, `0x02001192` u16[4] |
| Stream A / B | `0x0200119C` / `0x020011AC`: `{u8 *cur, u8 *end, u8 *loop, u32 volume}` |
| SOUNDCNT_L shadow | `0x020011BC` (u16: NR50 low byte, NR51 high byte) |
| Master | `0x020011D0`: +0 volume (0xFF), +1 fade step, +2 u16 fade frames, +4 u16 acc (8.8), +8 u16 period (8.8) |

### 2.1 Functions

| Address | Name | Called from | Purpose |
|---|---|---|---|
| `0805B564` | `Sound_Play(u16 id)` | 392 game sites | → `sndQueueSound` |
| `0805B574` | `Sound_Init()` | boot `0x080003E4`, `0x08097358` | → `sndInit` |
| `0805B580` | `Sound_Frame()` | VBlank handler `0x080015BC`, `0x0802446E`, `0x080BF41E` | → `sndFrame` |
| `0805B58C` / `0805B598` | `Sound_FifoAIrq` / `Sound_FifoBIrq` | IRQ stubs `0x0800170C` / `0x08001718` | → DMA1 / DMA2 handlers |
| `0805B5A4` | `Sound_FadeOut(u8 n)` | 8 sites | → `sndFadeOut` |
| `0805BEAC` | `sndQueueSound` | | Push an id into the 4-slot ring |
| `0805BECC` | `sndFadeOut` | | §8 |
| `0805BF3C` | `sndInit` | | Registers, clear tracks, queue, master volume |
| `0805BFD8` / `0805C150` | `sndFifoAIrq` / `sndFifoBIrq` | | §7 |
| `0805C2C8` | `sndFrame` | | Track update, fade, queue (§4) |
| `0805C700` | `.Lparse` | | Sequence interpreter (§3) |
| `0805CA14`… | `cmd*` | | Command handlers (§3.2) |

---

## 3. Sequence data

### 3.1 Song header

```
SongHeader: repeat { u32 slot (0..11); u8 *seq; u8 **patterns }  until u32 0xFF
```

Starting an id sets, for each listed slot: flags |= 1, `ptr = seq`, `patterns = patterns`, clears +0x24…+0x2F
(duty, sweep, volume, detune, level, length, pan, transpose, slide), `wait = 1`, and loads pan bits/mask from the pan
tables. Slots 4–7 set flag 2 (**muted**) on slot − 4; slots 10/11 set it on slot − 2. Envelope pointers (+0x30) and
sample pointers (+0x14…) are **not** reset. `patterns` is the table used by `F6`/`F8`.

### 3.2 Track bytecode

| Byte(s) | Meaning |
|---|---|
| `00`–`7F` | **Note** n. Plays for the current length. No argument bytes |
| `80`–`DF` | **Length** = `lengthTable[b − 0x80]` frames (sticky until the next length byte) |
| `E1 nn` | **Sample** (PCM): load start/end/loop from `smpTable[nn]` |
| `EC` | **Rest (PCM)**: wait one length, stop the envelope, stop the track's timer (TM0 for even tracks, TM1 for odd) |
| `ED` | **Rest (PSG)**: wait one length, stop the envelope, write envelope 0 and re-trigger (DAC off) |
| `F0 nn` | **Envelope** = `envelopeTable[nn]` |
| `F1 nn` | **Duty/length byte** (low byte of CNT_H; NR11/NR21 duty, NR31 length) |
| `F2 nn` | **Volume** (+0x26). PSG: subtracted from the NRx2 byte. PCM: multiplier `(nn + 1)·level >> 8` |
| `F3 nn` | **Transpose** (s8, semitones) |
| `F4 nn` | **Loop start**, count nn (single level; 0 = 256) |
| `F5` | **Loop end**: `if (--count) ptr = loopStart` |
| `F6 nn` | **Call** `patterns[nn]` (single-level return) |
| `F7` | **Return** |
| `F8 nn` | **Jump** to `patterns[nn]` (all 187 looping tracks loop this way) |
| `F9 nn` | **Detune**. PSG: added unsigned to the frequency value. PCM: s8 in 1/12 semitone |
| `FA nn` | **Sweep** (+0x25 → SOUND1CNT_L at note-on on tracks 0/4) |
| `FB` | Sweep off |
| `FC nn` | **Wave** = `waveTable[nn]`; loaded into wave RAM at once unless muted (also restored after a wave SE ends) |
| `FD nn` | **Pan**: NR51 bits `nn << (slot & 3)` (`0x11` both, `0x01` right, `0x10` left). MV only uses `0x11` |
| `FE` | **Tie**: wait one length, no re-trigger |
| `FF`, `EF` | **End of track** (§4.2) |
| `E2`–`E9` | Same as `F2`–`F9` (unused in MV) |
| `E0`, `EA`, `EB`, `EE` | No-op (unused) |

There is no explicit tempo. A note, rest or tie always takes the current length. A length of 0 makes the
countdown wrap, so the event lasts 256 frames.

### 3.3 Length table (tempo rows)

| Bytes | Quarter (frames) | BPM at 59.73 fps |
|---|---|---|
| `80`–`8F` | 32 | 112.0 |
| `90`–`9F` | 40 | 89.6 |
| `A0`–`AF` | 48 | 74.7 |
| `B0`–`BF` | 56 | 64.0 |
| `C0`–`CF` | 36 | 99.6 |
| `D0`–`DF` | 44 | 81.5 |

Columns (low nibble): 4 = 1/32, 6 = 1/16, 8 = 1/8, A = 1/4, C = 1/2, E = whole; odd columns are dotted (×1.5).
Values that do not fit are rounded or 0 (full rows in the data dump). 29 ids mix rows within one song, so tempo is a
property of each length byte, not of the song.

---

## 4. Frame update (`sndFrame`)

```
for n in 0..11, if t.flags & 1:
    if --t.wait == 0:  parse events until a note / rest / tie / end      (next track)
    else:
        if t.envWait && --t.envWait == 0:  envelope step                  (§6)
        if n >= 8 && t.slideWait && --t.slideWait == 0:  PCM volume slide (§6.2)
fade tick (§8)
if queue not empty: start queue[read]; read = (read + 2) & 7              (one id per frame)
```

`sndFrame` is called from the VBlank handler, so one tick is one frame (≈ 16.74 ms).

### 4.1 Track struct (0x38 bytes)

| Off | Field | Off | Field |
|---|---|---|---|
| +0 | flags (bit 0 active, bit 1 muted by SE) | +0x20 | u16 freq value (PSG) / timer reload (PCM) |
| +1 | wait (frames) | +0x22 | u16 CNT_H value = duty byte \| env << 8 |
| +2 | envelope countdown (0 = hold) | +0x24 | PSG duty byte / PCM slide countdown |
| +3 | loop count | +0x25 | PSG sweep / PCM effective volume |
| +4 | read pointer | +0x26 | volume (`F2`) |
| +8 | loop start | +0x27 | detune (`F9`) |
| +0xC | return pointer | +0x28 | envelope level |
| +0x10 | pattern table | +0x29 | length |
| +0x14 | sample start | +0x2A / +0x2B | pan bits / mask |
| +0x18 | sample end | +0x2C | transpose |
| +0x1C | sample loop (PCM) / wave pointer (PSG) | +0x2D / +0x2E | PCM slide / slide period |
| | | +0x30 / +0x34 | envelope script start / position |

### 4.2 SE priority and end of track

* An SE on slot 4–7 mutes music slot − 4. The music track keeps running silently and only updates its RAM copy.
* When the SE ends (`FF`), the music slot is un-muted. If it is still active, its last CNT_H/CNT_X values, NR51 bits
  and (for slot 4) sweep are written back and the channel is re-triggered. For the wave slot, the wave RAM is reloaded
  first. If the music track has already ended, the channel is silenced.
* A PCM SE on slot 10/11 un-mutes slot 8/9 and stops the timer. The music sample does not resume until its next note.
* A music track ending on slot 0–3 silences its channel unless it is muted.

---

## 5. Pitch

### 5.1 PSG

| Slot (`& 3`) | Computation | MIDI |
|---|---|---|
| 0, 1 (square) | `freq = psgFreqTable[(n + transpose) & 0x7F] + detune` | n + 36 |
| 2 (wave) | same table; 32-step wave, so one octave lower | n + 24 |
| 3 (noise) | `NR43 = (n << 4 \| n >> 4) & 0xFF`, no transpose | — |

`psgFreqTable[0] = 0x02C` (131072/(2048 − 44) = 65.4 Hz = C2). The table has 84 entries (C2–B8). The CNT_X write sets
bit 15 (trigger). For noise, the note byte's low nibble is the NR43 shift and the high nibble is width + ratio
(MV noise notes are 1–60).

### 5.2 PCM

```
index  = ((n + transpose) & 0x7F) * 12 + (s8)detune
reload = pcmPitchTable[index]          rate = 16 777 216 / (0x10000 − reload) = 1024 · 2^(index/144) Hz
```

The timer for slot 8/10 is TM0 (FIFO A) and for 9/11 TM1 (FIFO B), matching SOUNDCNT_H `0x730E`. MV PCM notes are
14–70, so rates run from 2.3 kHz to 58 kHz.

### 5.3 Sample root

Sample headers hold no rate or root note. A sample plays at its recorded pitch when the output rate equals its
recording rate R, i.e. at note `12·log2(R/1024)` (R = 16 384 Hz → note 48). For export, write each sample at a chosen
rate R_exp with root key K. Note n then maps to MIDI `K + n − 12·log2(R_exp/1024)`. With R_exp = 16 384 Hz this is
`K − 48 + n`. *(The intended recording rates were not determined.)*

---

## 6. Envelopes

`F0 nn` selects `envelopeTable[nn]`. On every note the script restarts from its first entry. Each entry's first byte
is how many frames it lasts; 0 holds it forever.

### 6.1 PSG `{u8 frames, u8 nrx2}`

* At note-on: `env = nrx2 − volume`; if `nrx2 < volume`, env = `0x08` (volume 0, DAC kept on).
* At each step: `env = max(nrx2 − volume, 0)`. CNT_H = `duty | env << 8` and CNT_X = `freq | 0x8000`. **Every step
  re-triggers the channel**, so each pair is a new hardware envelope (e.g. env 9 = `30 E0 00 E7`: 48 frames at
  volume 14 with no envelope, then volume 14 with a decay of step 7).
* Wave slot: the byte is the NR32 volume code (`20` 100 %, `40` 50 %, `60` 25 %, `80` 75 %), envelopes 16–24.
* Envelopes 0–15 and 48–63 are square/noise scripts; 16–31 are wave scripts.

### 6.2 PCM `{u8 frames, u8 slide, u8 level}`

* `level` sets +0x28. Effective volume `+0x25 = (volume + 1)·level >> 8`.
* `slide` high nibble = period P, low nibble = bit 3 down / bits 0–2 amount. Every P frames the level moves by the
  amount (clamped 0–255) and the stream volume is updated.
* Example: env 39 = `01 1F FF` then `01 1F 90` …: start at 0xFF and slide down 7 per frame, with level jumps every
  frame.
* Envelopes 32–47 and 64–71 are PCM scripts.

---

## 7. PCM output (FIFO IRQs)

Note-on on a PCM track, when not muted:

1. `TMxCNT_H = 0`.
2. Write the first 4 sample bytes **raw** into the FIFO.
3. Stream = `{start + 4, end, loop, volume = +0x25}`.
4. `IE |= DMA1` (or DMA2).
5. Set `TMxCNT_L = reload`, `DMAxCNT_H = 0xF600` (enable, IRQ, FIFO timing, 32-bit, repeat), then
   `TMxCNT_H = 0x80`.

The game **never writes DMA1/DMA2 SAD or DAD**; they stay at their reset value 0. The DMA serves only as the "FIFO
wants data" interrupt. The handler (`sndFifoAIrq` / `sndFifoBIrq`) does the copy itself:

```
IF = DMA1;  w = *cur++;  if (cur == end) { if (loop == end) { TM0CNT_H = 0; return; } cur = loop; }
for each byte s of w:  s' = sign(s) · ((|s| · (vol + 1) + 0x80) >> 8)
FIFO_A = s'0 | s'1 << 8;  FIFO_A+2 = s'2 | s'3 << 8
```

So each IRQ adds one word (4 samples) to the FIFO.

**Arithmetic error (simulated over all 65 536 byte pairs).** The two scaled bytes are combined with
`hi + (lo >> 8)` on a 32-bit negative value. As a result, **byte 1 (and byte 3) is 1 LSB low whenever byte 0 (byte 2)
is negative and non-zero**. Below full volume, negative samples also round toward −∞ rather than to nearest. At volume
0xFF the even bytes are exact. *(Inferred: hardware raises the FIFO request even though DAD is not
a FIFO address, and the DMA's own 16-byte transfer from address 0 to address 0 has no effect.)* There is one voice per
FIFO and no interpolation. The volume is applied per sample.

---

## 8. Master volume and fade

`sndFadeOut(n)` sets `frames = 8n`:

* n ≥ 32: `acc = period = 8n` (8.8) and step 1, so one level every 8n/256 frames.
* n < 32: `acc = period = 0x100` and step = ⌊32/n⌋ (simulated: 32, 16, 10, 8, 6, 5, 4, 4, 3 …), so one step every
  frame.

Each frame: `acc −= 1.0`. When it underflows, `acc += period` and `volume −= step` (floor 0). Then NR50 = `(volume >> 5)·0x11`
and the stream volumes of active, unmuted PCM tracks are set to `(volume + 1)·t.vol25 >> 8`. When `frames` reaches 0,
everything is re-initialised as in `sndInit` (all tracks off, volume back to 0xFF). n = 0 does nothing.

---

## 9. Hardware setup and driver quirks

| Register | Value |
|---|---|
| `SOUNDCNT_H` | `0xC80E` (FIFO reset) → `0x730E`: PSG 100 %, A/B 100 %, A and B both sides, A ← TM0, B ← TM1 |
| `SOUNDCNT_L` | `0x77` + NR51 bits from the pan tables (shadow `0x020011BC`) |
| `SOUNDCNT_X` | `0` → `0x8F` |
| PSG | All CNT_H = 0, CNT_X = `0x8000` at init |

Quirks found while reading the code:

* `sndInit` writes `0x8000` to `0x0400007A` (unused) instead of SOUND4CNT_H (`0x0400007C`).
* `ED`/`FD` on PCM slots read entries 8–11 of 8-entry register tables. `ED` on slot 8/9 writes 0 to SOUND1CNT_X /
  SOUND2CNT_H. This affects ids 37, 41–43, 60 and 75.
* `EC` on a PSG slot stops TM0/TM1. This affects id 74, track 1, and would cut PCM channel B for one note.
* `ED` re-triggers CNT_X with a stale `r5`. This is harmless because the envelope is already 0.
* The FIFO handler's byte packing borrows from the odd byte after a negative even byte (1 LSB error, §7).
* At note-on, PCM stream volume is not scaled by the master volume until the next fade tick or envelope step. The
  envelope step uses `master` and the slide uses `master + 1`.

---

## 10. Disassembly source

Folder `…/Brownie/brownie_asm/`:

| File | Content |
|---|---|
| `bb_sound.s` | Whole driver block `0x0805B564`–`0x0805D2DB` and the veneer island. Named functions with pseudo-C headers, symbolic Track/I-O offsets, literal pool labelled by content, tables as data with notes |
| `bb_sound.inc` | `.equ` for I/O registers, EWRAM state, outside ROM tables, and Track/Stream/Master/Sample offsets |
| `bb_sound.ld` | `.text.bb_sound` at `0x0805B564`, `.text.bb_veneer` at `0x080C2044` |
| `bb_sound.mk` | `make -f bb_sound.mk` (default `ROM="../Magical Vacation (J).gba"`): assemble, link, objcopy, compare |
| `bb_compare.py` | Result: 7 544 bytes and 48 bytes, 0 differences |

Requires `arm-none-eabi-binutils` and Python 3.

---

## 11. Sword of Mana (AVSP) — revision 2 of the engine

The two drivers share no code bytes, but the design is clearly the same engine, developed further.

| | Magical Vacation | Sword of Mana |
|---|---|---|
| Thumb glue | `0x0805B564` | `0x080A0ED8`… (7 wrappers; `Play` drops ids > 0x2F when `0x02000000` ≠ 0) |
| Veneers | `0x080C2044` | `0x0836D8A4`–`0x0836D8DB` |
| ARM core | ROM `0x0805BEAC`, runs from ROM | ROM `0x080A0510`–`0x080A2050`; init DMA-copies `0x080A0510` → IWRAM `0x03003150` and `0x080A09DC` → `0x03003750` (0x300 words each, overlapping) |
| Init / frame / IRQ | `0805BF3C` / `0805C2C8` / `0805BFD8`,`0805C150` | `080A11D0` / `080A129C` / `080A0510` (both FIFO IRQ wrappers); two u8 entries `080A1160`, `080A10A8` *(fade-type, not traced)* |
| State | EWRAM `0x02000EF0` | IWRAM `0x03002ACC` (tracks), `0x03002DDC` queue, `0x03002DF0` master, `0x03002DFC` SOUNDCNT_L shadow, `0x03002E0C` 6 × 16-byte PCM voice records |
| Tracks | 12 | 14 slots cleared, **13 updated per frame** (8 PSG + 5 PCM) |
| PCM | 1 stream per FIFO, CPU copy, volume per IRQ | DMA1/DMA2 properly set (SAD = IWRAM `0x03002E6C` / `0x03002E7C`, DAD = FIFO A / B). PCM tracks write **separate L/R volumes** (track +0x2A/+0x2B × level) into voice records, so several voices are mixed *(mixer loop not traced)* |
| Length table | 6 rows, row chosen by the length byte | `0x080A219C`, 8 rows; index = `(b − 0x80) + 16 ·` **track +0x2F** (per-track tempo row offset) |
| Queue | 4 × u16 | 8 × u16 (`& 0xF`); ids 0x3B/0x3D special-cased |
| Fade | out only | out and **in** (master +0x18) |
| Song table | `0x0805D2DC`, 278 | `0x080A2998`, 745 |
| Command table | `0x0805C994` | `0x080A1B10` (32 entries, different assignment) |
| Unchanged | Track stride 0x38 and most fields, `{slot, seq, patterns}` header with `0xFF` end, PSG register tables, pan tables (`11 22 44 88` …), PSG note-on, envelope scripts, SE muting of slots 0–3 | |

The full SoM decode and its byte-identical disassembly are in `brownie-som-technical-reference.md`. (The ARM block at `0x0809F400`–`0x0809FD00` is game video code, not sound.) Note: the SoM rows above were read before the full decode. The length table is 24 rows (row offset = track +0x2F), SoM has 5 mixed PCM voices with a 16 384 Hz fixed-rate mixer, and the two u8 entries are fade-in `080A10A8` and fade-out `080A1160`.

---

## 12. Notes for the MIDI converter

* **Clock:** 1 tick = 1 frame. For example, use PPQN 48 with tempo 803 650 µs per quarter (48 × 16 742.7 µs), or
  follow each length row's BPM (§3.3).
* **Notes:** square MIDI = n + 36 + transpose; wave = n + 24 + transpose. Noise → a drum note keyed by the NR43
  byte. PCM → the sample's root as in §5.3.
* **Program:** PSG program = `(slot, duty F1, envelope F0, wave FC)`; PCM program = sample `E1` + envelope `F0`.
* **Volume:** `F2` → CC7. For PSG it is attenuation: `vel ≈ (env_hi − F2/16)/15`.
* **Pan:** `FD` → CC10 (MV only uses centre). `F9` detune → pitch bend (PCM: 1/12 semitone; PSG: frequency units).
* **Loops:** `F4`/`F5` unroll. `F6`/`F7` inline. `F8` back to an earlier pattern = loop point.
* **Muting:** SE slots 4–7 are separate ids and do not need converting together with BGM.

Song table, samples, waves and envelopes are listed in `brownie-magvac-data-dump.md`.
