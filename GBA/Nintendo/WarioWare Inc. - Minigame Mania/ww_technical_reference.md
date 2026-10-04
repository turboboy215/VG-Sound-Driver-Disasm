# WarioWare, Inc. sound driver
## Reverse-engineering report and technical reference

**Subject file:** `…/GBAAudioLab/Nint1/WarioWare Inc. (E) (M5).gba` (game code `AZWP`, 8 MiB)

**Provenance.** The ROM contains no symbols and no credit or version string for its sound code. Every
function, variable, structure and table name in this document and in the sources was assigned during
this analysis. The game is a Nintendo R&D1 title, so the driver is presumably Nintendo's own *(inferred;
nothing in the ROM names it)*. The only names that come from the ROM are the **song name strings**
(`m_BGM_Title_01`, `s_BASIC_BUTTON_A` …, 1342 of them), the **track names** inside the MIDI files
(`Brass_melo_v`, `Bass` …) and the MIDI **marker texts** (`[`, `]`, `END` …).

Everything below comes from disassembling the ROM. Where something is an inference rather than a
direct reading of the code, it is marked *(inferred)*. All sources rebuild **byte-identical** to the
ROM (§15), and the instrument / sample / pitch / volume model was checked against the ROM's own code
running in an emulator (§15).

---

## 1. Executive summary

The driver is a **MIDI synthesizer**: the music and the sound effects are **Standard MIDI Files**
(format 1, 24 ticks per quarter note) stored unchanged in the ROM, played through **instrument banks**
of sampled and PSG instruments by a **software mixer**.

* **1342 sounds, all MIDI.** Every piece of music *and every sound effect* is a MIDI file (436 `m_`
  songs, 905 `s_` effects, 1 test file). A sound effect is just a short MIDI file on another player.
* **Nine players, one synth each.** Players 0–2 (12 channels) mainly play music, 3–8 (9, 5, 5, 5, 3,
  3 channels) mainly effects and refuse lower-priority sounds while busy. A sound id selects the player.
* **Tracks are channels.** Track *k* of the file drives synth channel *k*; the channel nibble of the
  MIDI status bytes is ignored. Track 0 (the conductor track) holds tempo and markers.
* **Instruments.** A song selects one of 16 **banks** (arrays of instrument pointers); the MIDI program
  number indexes it. An instrument is one of four records, identified by an ASCII type byte:
  **`A`** a sample with an envelope, **`P`** a Game Boy PSG sound (square 1/2, wave, noise) with an
  envelope, **`R`** a drum map (key → another instrument) and **`S`** a key split (key → key map →
  another instrument). `R` and `S` point into the other banks, which are therefore drum kits and
  split tables rather than program banks. Only banks 1, 2 and 3 are used as program banks.
* **Samples.** 711 sample headers `{length, rate, root key, loop start, loop end, data}` over 1.83 MB
  of 8-bit signed PCM at various rates (13 379, 10 512, 7 884, 5 734, 3 200 Hz …).
* **Pitch** is in **Hz from a 128-entry table of rounded integer frequencies** (key 69 = 440): the
  mixer step is `rate/13379 × freq[key]/freq[root]` in 18.14 fixed point. Pitch bend, fine tune and
  vibrato work on those Hz values.
* **Envelopes** are linear ADSR in 7.16 fixed point, one step per frame (attack, decay to sustain,
  optional sustain decay, release; a faster release when the sequencer stops notes).
* **Controllers.** Besides volume, pan, expression, modulation and pitch bend, the driver uses its own
  controller numbers for bend range (CC20), LFO speed/type/delay (CC21/22/26), voice priority (CC33),
  an effect send (CC72), a master filter and a tempo-synced **filter sweep** (CC73–77, SysEx), echo
  parameters (CC78–81), **random pitch** and **random notes snapped to a scale** (CC82–84, SysEx), and
  **CC14/CC16 to write variables the game code reads** (music-synchronised gameplay).
* **Loops** are marker meta-events: `[` sets the loop start, `]` jumps back.
* **Mixer.** 8 voices, 13 379 Hz nominal (13 389.6 Hz actual), 8-bit **stereo**, linear interpolation,
  a 1568-sample ring buffer per side fed to FIFO A (right) and FIFO B (left) by DMA1/DMA2, refilled from
  the main loop. The ARM inner loops are copied to IWRAM. An **echo** feeds the output from one ring
  length (117 ms) earlier back into the mix through a high-pass and a low-pass filter, and a **one-pole
  low-/high-pass filter** can be applied to the voices sent to the effect bus (CC72).
* **PSG.** Four more "notes" drive the four Game Boy channels directly (49 `P` instruments).

Content: **1342 MIDI files** (1.26 MB), **841 instruments** (765 `A`, 49 `P`, 19 `R`, 8 `S`) in
**16 banks**, **711 samples** (1.83 MB).

---

## 2. Build and ROM layout

The Thumb code is **GCC** output *(inferred from idioms: `adds rX, rY, #0` moves, `push {…}; pop {r0};
bx r0` epilogues, `_call_via_rX`, `__divsi3`/`__modsi3`/`__udivsi3`, 64-bit `__muldi3`/`__udivdi3`,
`mov pc, r0` switch tables)*. The ARM mixing loops are hand-written.

| Region | ROM range | Size | Contents |
|---|---|---|---|
| **Driver code** | `0x080F05B4`–`0x080F4988` | 17 364 B | 151 functions: 10 ARM loops, 141 Thumb |
| Driver tables | `0x083FD1CC`–`0x083FD770` | 1 444 B | key frequencies, semitone ratios, sine/cosine, PSG tables, loop markers |
| Key maps, PSG waves | `0x083FD770`–`0x083FD900` | 400 B | 4 × 72-byte key maps, 7 × 16-byte waves |
| Instruments | `0x083FD900`–`0x0840407C` | 26 492 B | 841 records |
| Banks | `0x0840407C`–`0x08405310` | 4 756 B | 16 pointer arrays, packed back to back |
| Bank table | `0x08405310`–`0x08405350` | 64 B | 16 pointers |
| Song names | `0x08405350`–`0x0840BB10` | 26 560 B | 1342 strings |
| Song table | `0x0840BB10`–`0x084123E8` | 26 840 B | 1342 × 20 bytes |
| Song pointer table | `0x084123E8`–`0x084140C8` | 7 392 B | max id + 1847 pointers (not read by any code) |
| Sound id table | `0x084140C8`–`0x08417A84` | 14 780 B | count + 1847 × {song, player} |
| Player set-up | `0x08417A84`–`0x08417BD8` | 340 B | player count, live-MIDI config, 9 player pointers, 9 configs, 9 groups |
| Sample headers | `0x08417BD8`–`0x0841BE80` | 17 064 B | 711 × 24 bytes |
| **MIDI files** | `0x0841BE80`–`0x0854FC14` | 1 260 948 B | 1342 SMF files, 4-byte aligned |
| **Sample PCM** | `0x08155D74`–`0x08316338` | 1 836 484 B | 8-bit signed |

External helpers (libgcc, right after the driver): `__ashldi3` `0x080F4988`, `_call_via_r1`/`r2`
`0x080F49C0`/`C4`, `__divsi3` `0x080F49F8`, `__modsi3` `0x080F4B08`, `__muldi3` `0x080F4BD8`,
`__udivdi3` `0x080F4C48`, `__udivsi3` `0x080F5020`.

---

## 3. Public API and host integration

### 3.1 Calls made by the game

| Address | Function | Called from |
|---|---|---|
| `080F4898` | `sndInit()` | boot, `0x0800030C` |
| `080F4468` | `sndSetReverbBase(level, delay, lpShift, hpShift)` | boot: `(0x23, 2, 2, 4)` |
| `080F4298` | `sndMain()` | once per frame from the main loop, `0x08000458` |
| `080F4480` | `sndNop()` (`bx lr`) | once per frame |
| `080F1418` | `sndDma2Irq()` | IRQ table entry 0 (DMA2, the first IRQ the game's dispatcher tests) |
| `080F3650` | `sndPlay(u16 id)` | the game's wrappers at `0x08001E9C`/`0x08001EE4`, which take a song entry and use its id |
| `080F36F4` / `3700` | `playerPause(p)` / `playerResume(p)` | |
| `080F370C` / `373C` | `sndPauseAll()` / `sndResumeAll()` | |
| `080F376C` | `playerSetVolume(p, –, v)` | 0x100 = 1.0 |
| `080F3770` | `playerSetTune(p, –, v)` | semitones in 8.8 |
| `080F3780` | `playerSetPan(p, –, v)` | |
| `080F3824` | `playerSetTempoScale(p, s)` | 0x100 = 1.0; 19 call sites *(inferred: the music speeds up with the game)* |
| `080F38E8` / `3908` | `playerFadeOutStop(p, t)` / `playerFadeIn(p, t)` | fade over `t × 16` frames |
| `080F1D90` / `1D9C` | `mixSetFilter(c)` / `mixSetFilterGain(g)` | one screen drives the master filter directly (`0x08025CC2`) |

Players are addressed through `sndGroups[k].player` (`0x08417B6C`); the game walks that table itself
to fade or pause "every player playing song X".

### 3.2 Other entry points

`playerFadeOutPause`, `sndPauseSound(id)`, the live-MIDI input (`liveInit`, `liveMidiInput`) and a few
setters are never called (§13.3).

---

## 4. Hardware resources

| | Setting |
|---|---|
| Output | Timer 0, reload −1253 → **13 389.6 Hz** (the code computes 0xFFFED9 / 13 379 = 1253; the mixer assumes 13 379 Hz) |
| `SOUNDCNT_H` | `0xA90E`: FIFO A → **right** only, FIFO B → **left** only, both 100 %, both timer 0, PSG 100 % |
| DMA1 | right ring buffer → FIFO A, `0xB600` (repeat, 32-bit, FIFO timing) |
| DMA2 | left ring buffer → FIFO B, `0xF600` (same **plus IRQ**): the interrupt fires every 16 samples |
| `SOUNDCNT_L` | rewritten every frame by the PSG code: master volume 7/7, each PSG channel left / right / both by its channel's pan |
| `SOUNDCNT_X` | `0x80` |
| PSG | channels 1–4 played by `P` instruments |

Mono modes exist (`mixInit` mode 1: FIFO B only; mode 2: the same buffer on both FIFOs) but the game uses
mode 0.

---

## 5. Per-frame flow

```
main loop, once per frame                          sndMain()
    for each of the 9 players:  playerFadeTick, playerTick (MIDI), synthLfoTick; sum the echo offsets
    (live-MIDI player: never set up)
    filter sweep: sweepTick(ticks this frame); mixSetFilter(out * depth >> 8)
    noteUpdateAll():  per note: pitch -> voice step, volume -> voice, envelope step;  PSG registers
    mixSetReverb(clamped sums); mixFrame()

mixFrame()      keep ~480 samples queued ahead of the DMA read position
    in blocks of <= 128 samples:
        acc = echo(ring output from one ring length ago)        mixReverb
        + wet voices (CC72)  -> master filter (if any wet voice)
        + dry voices
        -> clip table -> 8-bit right / left rings                mixDownmix

DMA2 IRQ, every 16 samples (836 Hz)                sndDma2Irq()
    readPos += 4 words; at the ring end, or if it catches up with the write position (the
    previous 16 samples are then played again), DMA1/DMA2 are restarted at the right address
```

**Timing.** Sequencing is per frame: all MIDI events due in a frame are processed at once, so event
timing is quantised to 16.7 ms. The tick rate is `BPM × tempoScale × ppqn / 3600` MIDI ticks per frame
(8.8 fixed point), which assumes 60 frames/s; the GBA runs at 59.73, so everything plays **0.46 %
slow**. Tempo meta-events are converted to **whole BPM** (truncated), and 660 of the 1630 tempo events
(in 396 files) are not whole BPM.

---

## 6. RAM maps and structures

All field lists with comments are the `.equ` blocks in `ww_sound.inc`.

### 6.1 Memory used (IWRAM)

```
03000E78 gSndRandSeed         03000E80 PSG retrigger flags, last volume, last frequency, last wave
03000EA0 live-MIDI player      03000EAF 4 "game variables" written by CC16 (gGameVars points here)
03000EB4 Player[9]  (0x30)     03001068 ring buffers: right 0x620 bytes, then left 0x620
03001CA8 mix accumulator (128 stereo s32)   030020A8 Voice[8] (0x20)   030021A8 Note[8] (0x20)
030022A8.. per player: Chan[12/9/5/3] (0x20), Synth (0x28), Track[n] (0x24)
03006550.. mixer and effect globals (see ww_sound.inc)
03006610 PsgNote[4]            03006690 clip table [512]
030068C0 addresses of the IWRAM copies of the ARM loops;  03006910.. the copies (≈1.4 KB)
```

### 6.2 Structures

| Structure | Size | Key fields |
|---|---|---|
| **Voice** (mixer channel) | 0x20 | flags (1 active, 2 needs resampling, 4 no interpolation, 8 wet), volume, left/right gains (s8, right may be negative), pcm, position/loop start/end/step (18.14), base step |
| **Note** (a playing key) | 0x20 | key, velocity, frequency (17 bits, Hz), instrument, synth, channel, bend spans, vibrato span, priority, pan offset, envelope (state + 24-bit level) |
| **Chan** (MIDI channel) | 0x20 | program, volume, pan, expression, modulation depth, LFO (type/speed/phase/delay/value), bend, bend range, gain, priority, wet, invert, random pitch / key fields |
| **Synth** | 0x28 | volume, transpose, pan, tune, frequency table, bank, channel count, priority, channels, 12-note scale |
| **Track** | 0x24 | active, running status, start, read pointer, time to next event (ticks << 8), loop and snapshot state |
| **Player** | 0x30 | tracks, tempo (whole BPM), priority check, paused, synth, tracks, song, tick rate, ppqn, tempo scale, volume, fade, echo offsets |

Sampled notes and mixer voices are paired: **note slot *i* always drives voice *i*** (8 of each).

---

## 7. Mixing

### 7.1 Routines

The Thumb wrappers set up registers and jump to the IWRAM copy of an ARM loop:

| # | Routine (stereo) | Job |
|---|---|---|
| 0 | `mixArm_ReverbStereo` | initialise the accumulator with the filtered, scaled old output (echo) |
| 1 | `mixArm_DownmixStereo` | accumulator `>> 7` → clip table → 8-bit right/left rings |
| 2 | `mixArm_VoiceDirectStereo` | step exactly 1.0: copy samples (4 per word read when aligned) |
| 3 | `mixArm_VoiceInterpStereo` | resample with linear interpolation |
| 4 | `mixArm_VoicePointStereo` | resample without interpolation (instrument flag) |
| 5 | `mixArm_Filter` | one-pole low-pass or high-pass over the accumulator |

A voice uses routine 2 when its step is exactly 0x4000, otherwise 4 if its instrument has the
"no interpolation" bit (no instrument has it), else 3.

### 7.2 Resampling

Positions are 18.14 fixed point. Interpolation uses the top 8 bits of the fraction:
`s = p[i] + (p[i+1] − p[i]) × (pos & 0x3FC0) >> 14`. The fast path mixes 4 samples without end tests
while `pos + 4·step < end`; near the end it tests after every sample and wraps by the (negative) loop
length, or stops the voice.

### 7.3 Volume and pan

```
voice gain   = gainR/L (s8, from the pan law) × (voice volume + boost) >> 7
acc[R] += s × gainR;  acc[L] += s × gainL            s = signed 8-bit sample
output       = clip[(acc >> 7) & 0x1FF]              saturates to −128..127
```

The pan law is linear and keeps the near side at full level: `right = pan ≤ 63 ? 2·pan : 127`,
`left = pan ≥ 64 ? 2·(127 − pan) : 127`. CC75 ("invert") negates the right gain (a phase-inverted
"surround" effect).

### 7.4 Echo ("reverb")

The ring buffers hold 1568 samples per side (117 ms). Before any voice is mixed, the accumulator is set
to the output from roughly one ring length earlier: the right ring at the write position, the left ring
`4 × delay` samples further on. Each side goes through a DC-blocking high-pass
(`hp += x − hp >> hpShift; y = x − hp >> hpShift`) and a low-pass (`lp += y − lp >> lpShift`) and is
scaled by `level >> lpShift`. With the game's settings (level 0x23, delay 2, lpShift 2, hpShift 4) the
feedback is about `8 × 4 / 128 = ¼` *(inferred from the formulas)*: a short, decaying room echo on
everything. Players can offset the four parameters with CC78–81.

### 7.5 Master filter and the effect bus

Voices of channels with **CC72** on ("wet") are mixed first; if any was mixed, `mixArm_Filter` then
filters the accumulator, which at that point holds the echo and the wet voices; dry voices are added
afterwards. The filter value `c` (low byte of `gMixFilter`): `0x00–0x7F` low-pass with coefficient
`2c/256`, `0x80–0xFF` high-pass with `2(c − 0x80)/256`. CC74 sets it directly (`2v − 128`, so values
below 64 give a high-pass, above 64 a low-pass, 64 = off); in high-pass mode wet voices get louder by
`vol × (256 − c) × gain / 128` (`gain` = CC77 / SysEx, default 4) to make up for the lost bass. A
**sweep** (CC73, SysEx 00) moves the filter with a sine LFO measured in MIDI ticks (delay, fade-in,
period, start phase, optional end phase for a one-shot sweep) and can restart on every note of a wet
channel.

---

## 8. Instruments and samples

### 8.1 From a MIDI note to a sample

```
song entry  ──bank index──►  sndBankTable[16]  ──►  bank (Instrument *[n])
MIDI program (channel)  ──────────────────────────►  bank[program]  = instrument
    'A' / 'P'  : play it (key = MIDI key + synth transpose)
    'R' drum   : ins = ins.table[key − ins.base]; play it at ITS OWN key, with ITS pan offset
    'S' split  : ins = ins.table[ins.keymap[key − ins.base]]; play it at the MIDI key
    'F'        : (code only) like 'A' but always at the sample's root key, native rate
    'Q'        : (code only) treated like 'P'
'A' ──► SampleHeader ──► PCM
```

Only one level of `R`/`S` is followed; a sub-instrument of type `R` or `S`, or a null pointer, is
silent. There is no range check: an `R` table is simply the next bank in memory, so a key outside the
kit reads the neighbouring bank (§13.1).

The songs use three program banks: **bank 3** (1120 files, music and effects), **bank 1** (221 files)
and **bank 2** (1 file). The other 13 banks are the tables of the `R` and `S` instruments: bank 0 (22
entries) serves the key splits, banks 4–15 are drum kits. Banks are stored without trailing empty
entries (bank 0 has 22 entries, bank 2 127), so a program past the end reads the next bank *(no
song does this)*.

| Bank | Entries | Contents |
|---|---|---|
| 1 | 128 | 38 P, 19 A, 6 R, 3 S |
| 2 | 127 | 10 A, 1 R, 1 S |
| 3 | 128 | 56 A, 12 R, 9 P, 4 S |
| 0 | 22 | the `S` sub-instruments (17 A) |
| 4–15 | 22–99 | drum kits (the `R` targets) |

### 8.2 Instrument records

**`A` sampled instrument (0x20 bytes), `P` PSG instrument (0x24 bytes)**

| Offset | Field | Notes |
|---|---|---|
| `+00` | `u8 type` | `'A'` 0x41, `'P'` 0x50 (`'F'` 0x46 and `'Q'` 0x51 are handled but unused) |
| `+01` | `u8 key \| noInterp << 7` | the key played when the instrument is used from a drum map (60 in 739 of 765 `A`); bit 7 = mix without interpolation (never set) |
| `+02` | `s16 pan` | pan offset when used from a drum map; 127 = none (all instruments have 127) |
| `+04` | `SampleHeader *` | `P`: the 16-byte wave for the wave channel, else 0 |
| `+08` | `u32 envStart` | initial level (0x7F0000 in 684 instruments = no attack, 0 in 81) |
| `+0C` | `u32 sustain` | sustain level |
| `+10` | `u32 attack` | added per frame |
| `+14` | `u32 decay` | subtracted per frame down to the sustain level |
| `+18` | `u32 sustainRate` | subtracted per frame while held (0 in every instrument; negative values would swell, capped at full) |
| `+1C` | `u32 release` | subtracted per frame after note-off |
| `+20` | `u32 psg` (`P` only) | bits 0–1 channel (square 1, square 2, wave, noise), 2–9 low byte of the length/duty register (non-zero = the hardware length counter ends the note), 10–16 sweep (square 1), 17–18 duty, 19–31 OR'd into the noise register (bit 3 of `SOUND4CNT_H` = 7-bit noise) |

Levels are 7.16 fixed point: `0x7F0000` is full, the note volume uses `level >> 16` (0–127).

**`R` drum map (8 bytes):** `u32 'R' | base << 8; Instrument **table` — key *k* plays `table[k − base]`
(base 36, or 24 for banks 12–14).

**`S` key split (12 bytes):** `u32 'S' | base << 8; u8 *keymap; Instrument **table` — key *k* plays
`table[keymap[k − base]]`. The four key maps are 72 bytes (keys 36–107); all splits use bank 0 as
their table.

### 8.3 Sample headers and PCM

```
SampleHeader (24 bytes):  u32 length; u32 rate (Hz); u32 rootKey; u32 loopStart; u32 loopEnd; s8 *pcm
```

* Lengths and loop points are in samples. `loopStart = loopEnd = 0` means one-shot (313 samples);
  otherwise the voice plays to `loopEnd` and jumps back to `loopStart` (398 samples).
* PCM is **signed 8-bit**, stored in header order, each sample padded to a multiple of 4 bytes.
* Rates: 13 379 Hz (313 samples), 7 884 (181), 10 512 (92), 3 200 (91), 5 734 (28), and one or two
  each of 44 100, 22 050, 5 000, 2 628 and 1 000 Hz. Root keys: 60 (335) and 72 (284) dominate.
* For 396 of the 398 looped samples the data continues after `loopEnd`; that tail (516 KB, **28 % of
  all PCM**) is never played. The interpolator reads the byte after `loopEnd` when it wraps, i.e. the
  sample's natural continuation.
* After each looped sample the converter wrote a copy of its **loop-start byte** (an interpolation
  guard, 397 of 398), but because loops end before the data does, only the two loops that end at the
  data's end use it *(inferred purpose)*.
* 77 headers are 0–2-sample placeholders, used by 74 instruments of drum kit bank 14 and 3 of bank 7;
  34 notes in two files hit them.

### 8.4 Pitch

The synth works with **frequencies in Hz** from `sndKeyFreqTable` (`0x083FD1CC`): 128 rounded integers,
key 69 = 440, key 60 = 262, key 0 = 8, key 127 = 12 544.

```
at note-on:     f = freq[key]          (key = MIDI key + transpose, or the drum map's key)
voiceSetSample: baseStep = ceil(rate · 2^28 / (freq[rootKey] · 13379))
voiceSetPitch:  step = baseStep · f >> 14             (18.14; 0x4000 = one input sample per output sample)
```

so `step ≈ 2^14 × rate/13379 × freq[key]/freq[rootKey]`. Before `voiceSetPitch`, `noteCalcPitch`
modifies `f` every frame:

* **Pitch bend** (14-bit, 0x2000 centre): the spans `freq[k] − freq[k − range]` and
  `freq[k + range] − freq[k]` are stored at note-on (range = CC20, default 2). The bend is spread over
  the span with the 13-entry table `(2^(n/12) − 1)·65536`, interpolated in steps of 8192/12, which
  gives an exponential curve.
* **Tune** (`playerSetTune`, semitones 8.8): whole octaves by doubling/halving, the rest from the same
  table.
* **Vibrato** (LFO type 0): `f += lfo × (freq[k + 1] − freq[k]) >> 5` (lfo −127…127).
* **Random pitch** (CC82): each note-on picks a factor between `128/(128+v)` and `256/(256−v)`.

*Example:* bank 3 program 2, MIDI key 40. Sample 40: 10 512 Hz, root 60. `freq[60] = 262`,
`freq[40] = 82`, `baseStep = 805 009`, `step = 4028` (0.2458 input samples per output sample). The exact
ratio would be 0.2475: the note is 11.5 cents flat, because 82.41 Hz was rounded to 82. The rounded
table is off by up to ±11 cents between keys 36 and 96, ±18 cents at keys 24–35 and up to 138 cents
below that; the errors of the note and of the root key combine.

*Drum example:* bank 3 program 117 is `R` over bank 4; MIDI key 38 → `bank_04[2]`, an `A` whose key is
60 over a 13 379 Hz sample with root 60 → `step = 0x4000` exactly → the 1:1 mixing routine.

### 8.5 Volume

```
channel gain (per frame) = synth.volume × CC7 × CC11 × tremolo >> 21          (0..127; tremolo 0..0xA0, 0x80 = 1)
synth.volume             = song volume × player volume >> 8 × fade >> 8 >> 7
note volume              = channel gain × velocity × (envelope level >> 16) >> 14   (0..127)
```

Volume and pitch are recomputed every frame for every note (with the envelope level of the previous
frame), then the envelope advances.

### 8.6 Envelope

| State | Per frame | Next |
|---|---|---|
| 0 attack | `+= attack` | ≥ 0x7F0000 → full, state 1 |
| 1 decay | `−= decay` | ≤ sustain → sustain, state 2 |
| 2 sustain | `−= sustainRate` | ≤ 0 → note ends |
| 3 release (note-off) | `−= release` | ≤ 0 → note ends |
| 4 stop (end of track, loop jump, player stopped) | `−= release` (0x60000 if 0) | ≤ 0 → note ends |

A one-shot sample that runs out also ends the note. In the data: no attack in 684 of 765 `A`
instruments (2–7 frames in the rest), decay 0–348 frames (median 8), release 1–375 frames (median 6),
no sustain decay.

### 8.7 Voice allocation and priority

A sampled note takes, in order: a free slot; the **released** note with the lowest `gain × velocity`;
or the note with the **lowest priority** not above the new note's, and among equals the quietest (notes
started in the same frame at the new note's priority are kept if they are louder). A channel's
priority is CC33 plus the song's priority (song table, 0–119). PSG notes are not allocated: each `P`
instrument names its Game Boy channel, and a new note simply replaces the previous one.

### 8.8 PSG instruments

`P` notes drive `SOUND1`–`SOUND4`: frequency `2048 − 131072 / f` from the same Hz values (noise: the
key, clamped to 21–80, selects a divider from `psgNoiseTable`), volume `(vol >> 3) × 1.5` (0–15) as the
envelope start volume, duty/length/sweep from the instrument. Because the GB envelope volume only
changes on a trigger, the note is re-triggered whenever its volume changes. Pan is hard: left, right or
both, from the channel's CC10. Wave instruments copy their 16-byte wave to wave RAM on every note.

---

## 9. MIDI files and the sequencer

### 9.1 Songs, ids and players

```
SongEntry (20 bytes): MIDI *; u32 {bits 0-4 player, 5-14 bank, 15-21 volume, 22-31 priority}; u32 0xFF; char *name; u32 id
SoundId  (8 bytes):   SongEntry *; u32 group (player)          sndSoundIdTable, 1847 ids, 1342 used
PlayerConfig (20):    u16 {0-4 index, 5-9 channels, 10 priority check}; Chan *; Synth *; Track *; Player *
```

`sndPlay(id)` starts the id's song on `sndGroups[group].player`. On a player with the priority check
(3–8), a new sound is refused if the current one has a higher priority and the player is not paused.
The files are format 1 with 24 ticks per quarter note, 2–9 tracks; a player plays at most its channel
count of tracks.

### 9.2 Events

| Event | Effect |
|---|---|
| Note on / off | queued (20 per track per tick) and applied after the tick's other events, on channel = track index |
| Controller | §9.3 |
| Program change | channel program (0–127) |
| Pitch bend | 14-bit |
| Poly / channel pressure | skipped |
| SysEx `F0` | §9.4 |
| Meta `2F` | end of track: its notes get the fast release, and its LFO speed is zeroed |
| Meta `51` | tempo, stored as whole BPM |
| Meta `06` marker | `[` loop start, `]` loop end |
| other meta | skipped |

### 9.3 Controllers

| CC | Meaning | CC | Meaning |
|---|---|---|---|
| 0 / 32 | bank select MSB/LSB — stored, never used | 72 | wet: channel goes through the master filter |
| 1 | LFO depth | 73 | sweep mode: 0/1 stop (1 = restart on wet notes), 2 start now |
| 7 | volume | 74 | master filter `2v − 128`, stops the sweep |
| 10 | pan | 75 | invert the right side (phase) |
| 11 | expression | 76 | sweep depth `2v` |
| 14 | select game variable (0–3) | 77 | high-pass volume make-up gain |
| 16 | write the selected game variable (`0x03000EAF+i`) | 78–81 | player's echo level/delay/lpShift/hpShift offsets (64 = none) |
| 20 | pitch-bend range (semitones) | 82 | random pitch per note |
| 21 | LFO speed (`v << 8` phase per frame) | 83 | random key ±v, snapped with the 12-note scale |
| 22 | LFO type: 0 vibrato, 1 tremolo, 2 auto-pan | 84 | re-randomise held notes every v frames |
| 26 | LFO delay (frames) | 33 | voice priority |

All other controller numbers are ignored (no sustain pedal, no RPN, no all-notes-off). CC16 is used by
`m_BGM_AFRO_BOSS_10` and `m_BGM_BOMB_14`; game code near `0x08058A4C` reads the variables.

### 9.4 SysEx

`F0 len 00 d0..d6`: effect set-up — sweep depth `2·d0`, sweep delay/fade-in/period/phase/end `2·d1..2·d5`
(ticks), high-pass make-up gain `d6`; clears the filter and sweep. `F0 len 01 s0..s11`: the synth's
12-note scale for random keys, `s − 64` semitones per pitch class.

### 9.5 Loops

At the frame in which a `[` marker is read, the state of every track *from the start of that frame* is
kept (read pointer, time, running status, active); when a `]` marker is read later, every track goes
back to it, its notes get the fast release, and the loop start's events run again in the same frame.
`]` only works after a `[`. 83 files have `[`, 79 of them also `]`. Other markers (`END` in 1044
files, `A_1` …) are ignored. Files without a loop stop when every track has ended.

---

## 10. Channel LFO and randomisation

Each channel has one LFO: a 256-entry sine read at `phase >> 8`, `phase += speed` each frame, scaled by
the depth (CC1) to −127…127, restarted and held for `delay` frames at every note. It modulates pitch
(`f += lfo × span >> 5`, span = one semitone), volume (gain × (128 + lfo)/128, capped at 160/128) or pan
(`pan + lfo/2`) depending on CC22. The random generator is `seed = seed × 109 + 1021` (16-bit).

---

## 11. Game-side extras

* The echo base parameters come from `sndSetReverbBase` (boot) plus the per-player CC78–81 offsets of
  every playing player, summed and clamped each frame.
* `playerSetTempoScale` speeds up the music as the game gets faster; `playerFade*`, `playerPause`,
  `sndPauseAll` are used by the menus and transitions.
* A **live-MIDI player** (`sndConfig`: enabled 1, bank 3, volume 127, priority 0, 150 BPM) would play
  raw MIDI bytes pushed with `liveMidiInput` (real channels, running status, SysEx). The code is
  complete, but nothing sets it up *(inferred: a development / link-cable feature)*.

---

## 12. PSG code details

`psgUpdate` writes a channel only when its volume or frequency changed or the note was just triggered.
Square 1 notes with a sweep are left alone after the trigger. A non-zero length in the instrument lets
the hardware end the note; `psgUpdate` notices through `SOUNDCNT_X` and frees the slot.

---

## 13. Bugs, quirks and dead code

### 13.1 Audible or data-dependent

1. **Integer-Hz key table**: pitch errors of up to ±11 cents in the normal range, much more at the
   bottom (§8.4).
2. **Whole-BPM tempo**: tempos are truncated to integers (660 of 1630 tempo events are not whole).
3. **60 Hz assumption**: tempo and LFOs run 0.46 % slow on real hardware; the output rate is 13 389.6
   Hz while pitch is computed for 13 379 Hz (+1.4 cents).
4. **Frame-quantised events**: every event is delayed to the next frame boundary.
5. **Drum keys outside the kit** read the neighbouring bank: 118 notes in 8 files play instruments of
   another kit, e.g. `m_BGM_PAINT_BGM_3` keys 31 and 34 on program 127 (kit bank 5) play entries 17 and
   20 of bank 4 (103 notes).
6. **Missing instruments**: 40 notes use empty programs and 41 hit empty drum slots; they are silent.
7. **Placeholder samples**: 34 notes (two `m_BGM_ROPE_BGM_KAEDE` files) play 2-sample placeholders.
8. **Loop tails and guard bytes**: 28 % of the PCM is never played; the interpolation guard bytes are
   in the wrong place (§8.3).
9. **Tempo at the loop jump** is not restored (`savedTickRate` is written, never read).
10. **Note queue**: more than 20 notes on one track in one tick are dropped *(no file reaches it)*.
11. **Released-note stealing** ignores a released note whose `gain × velocity` is exactly 127·127.

### 13.2 Latent

1. **Mono mixer modes** (never used): routine 2 is an alias of the interpolating loop but called with
   the direct loop's registers; the mono list has no filter routine; `mixArm_VoicePointMono` adds the
   2nd and 4th sample of each group to the wrong register.
2. **`psgInit`** writes a zero byte through `gPsgLastWave`, which holds 0; **`gPsgLastWave`** is never
   updated, so the wave RAM is reloaded on every wave note.
3. **`voiceSetPitch(0)`** (for `F` instruments) sets step 1.0 with the "needs resampling" flag clear —
   correct, but no instrument is `F`.
4. **`synthKeyToFreq`** maps negative keys −65…−1 to key 0 and −128…−66 to key 127.
5. **Mode-3 fades** (fade out and pause) stay active at level 0, so `playerFadeTick` pauses the player
   again every frame: only a new `playerFade` can resume it (the game only uses modes 1 and 2).
6. **Running status** survives meta and SysEx events.

### 13.3 Dead code and data

* **Never called:** `playerFadeOutPause`, `sndPauseSound`, `liveInit`, `liveMidiInput` (and so
  `liveParse`/`liveTick` never run), `mixDmaStop`, `noteFindQuietest`, `synthSetTranspose`,
  `synthSetBendRange`, `synthSetFreqTable`, `synthSetField6`, `chanSetVibRange`, `chanSetField6`,
  `chanSetFlag0`.
* **Written, never read:** channel bank select, `Voice.lengthWords`, `Synth.field6`, `Chan.field6`,
  `Player.savedTickRate`, the VCOUNT profiling snapshots.
* **Data:** `sndCosTable` (256 entries), five of the seven PSG waves, the song pointer table, the song
  entry's player bits and `0xFF` word, the group table's channel count and priority fields.

---

## 14. Content inventory

| | |
|---|---|
| Sounds | 1342 MIDI files: 436 music (`m_`), 905 effects (`s_`), 1 test (`x_TEST`); 1847 ids, 1342 used |
| Players (songs) | 0: 318, 1: 101, 2: 37 (music); 3: 77, 4: 271, 5: 189, 6: 107, 7: 198, 8: 44 |
| MIDI | format 1, 24 ppqn, 2–9 tracks; 103 851 note-ons, 28 441 controllers, 28 061 bends, 4 034 program changes, 1 630 tempo events |
| Song volume / priority | 0–120 / 0–119 (22 distinct priorities) |
| Instruments | 841: 765 `A`, 49 `P` (19 square 1, 13 square 2, 2 wave, 15 noise), 19 `R`, 8 `S` |
| Banks | 16 (3 program banks, 1 split table, 12 drum kits) |
| Samples | 711 headers, 1 834 755 bytes of PCM, 398 looped, 77 placeholders, longest 24 893 samples (2.4 s) |

The complete tables are in `ww_data_summary.txt`; `ww_data_dump.txt` adds, per file and track, the
notes, programs, controllers, markers and the instruments each program/key actually resolves to.

---

## 15. Rebuild and verification

`make -f ww.mk check ROM="WarioWare Inc. (E) (M5).gba"` (needs `arm-none-eabi-as/ld/objcopy` and
Python 3) extracts the MIDI files and the PCM with `ww_tool.py extract`, assembles the five sources,
links them at their ROM addresses and compares all five ranges of §2 with the ROM:

```
.snd_code    080F05B4-080F4988    17364 bytes  identical   driver code (Thumb + ARM)
.snd_rodata  083FD1CC-083FD770     1444 bytes  identical   driver tables
.snd_data    083FD770-0841BE80   124688 bytes  identical   keymaps, waves, instruments, banks, songs, players, sample headers
.snd_midi    0841BE80-0854FC14  1260948 bytes  identical   MIDI files
.snd_pcm     08155D74-08316338  1836484 bytes  identical   sample PCM
```

`ww_verify.py` runs the ROM's own driver (Unicorn) on 50 files (25 of them using drum maps or key
splits, 12 s each) and checks the model of §8 against it: at every one of the 3929 sampled note-ons the
instrument, sample, frequency and pan offset match; in 71 984 voice-frames the base step and the step
(with bend, vibrato and random pitch) match exactly; the volume and envelope match in 59 986 / 56 835
frames, the 5 differences being notes re-struck on the same voice, which the checker cannot tell apart.

---

## 16. Notes for tooling

* **Playing the MIDI files elsewhere:** remap channels to track numbers (the files' own channel
  numbers are not what the game uses), select the song's bank, turn CC20 into RPN 0, and drop the
  driver-only controllers. `ww_tool.py midi` does this; `ww_tool.py sf2` builds a SoundFont whose
  bank/program numbers are the driver's (`A` → one zone, `S` → one zone per key-map run, `R` → one
  zone per key with the drum's own key and pan, `P` → synthesized square/wave/noise loops). The
  envelope shapes, the echo, the filter, random pitch/keys and the Hz-table detuning are not
  reproduced, so it is an approximation.
* **Exact rendering:** `ww_emu.py` runs the ROM's driver and writes what the DMA would send to the
  FIFOs.
* **To sound like the game:** mix at 13 379 Hz with 8-bit interpolation and 8-bit output, sequence
  per frame at 60 ticks-per-second arithmetic, use the Hz table, truncate tempos to whole BPM, and add
  the echo.

---

## 17. Deliverables

In `…/GBAAudioLab/Nint1/`:

| File | Contents |
|---|---|
| `ww_sound.s` | the driver: labelled Thumb and ARM source with pseudo-C above every function |
| `ww_sound_rodata.s` | driver tables |
| `ww_music_data.s` | key maps, waves, all 841 instruments (macros), banks, song names, song/id tables, players, sample headers |
| `ww_midi_data.s` | the 1342 MIDI files (`.incbin midi/NNNN_name.mid`) |
| `ww_sample_data.s` | the PCM, one label per sample (`.incbin ww_sample_pcm.bin`) |
| `ww_sound.inc`, `ww_macros.inc` | RAM addresses, IO registers, every structure field; data macros |
| `ww.ld`, `ww.mk`, `romcheck.py` | link at the original addresses and compare with the ROM |
| `ww_tool.py` | `extract`, `dump`, `summary`, `wav`, `midi`, `sf2` |
| `ww_emu.py`, `ww_verify.py` | render with the ROM's own driver; check the model against it |
| `ww_data_dump.txt`, `ww_data_summary.txt` | decoded data |
| `ww_midi.zip` | the 1342 MIDI files as stored, and a `gm/` set remapped for normal players |
| `ww_wav.zip` | the 711 samples as WAV (root key and loop in a `smpl` chunk) |
| `ww.sf2` | the three program banks as a SoundFont |

---

## Appendix A: function map

```
Mixer (ARM loops marked *)
080F0612 mixLoadRoutines       080F0626 mixLoadRoutines_veneer 080F0638 mixCopyRoutineList
080F0658 mixCopyRoutine        080F0674 mixCallRamRoutine     080F068C mixVoiceInterp
080F0708 mixArm_VoiceInterpStereo*  080F089C mixArm_VoiceInterpMono*  080F0A18 mixVoiceInterp_veneer
080F0A2C mixReverb             080F0AAC mixArm_ReverbStereo*  080F0C20 mixArm_ReverbMono*
080F0CD4 mixDownmix            080F0D3C mixArm_DownmixStereo* 080F0DCC mixArm_DownmixMono*
080F0E14 mixReverbDownmix_veneer 080F0E70 mixVoiceDirect      080F0EF4 mixArm_VoiceDirectStereo*
080F1018 mixVoiceDirect_veneer 080F102C mixVoicePoint          080F10A8 mixArm_VoicePointStereo*
080F11A4 mixArm_VoicePointMono* 080F1280 mixVoicePoint_veneer 080F1294 mixFilter
080F12B8 mixArm_Filter*        080F1408 mixFilter_veneer      080F1418 sndDma2Irq
Voices and frame mixing
080F1560 voiceSetSample        080F15E8 voiceStart            080F1604 voiceStop
080F161C voiceSetPan           080F1638 voiceSetVolume        080F1648 voiceSetPitch
080F16A4 voiceSetNoInterp      080F16C4 voiceSetWet           080F16E4 mixInit
080F1A40 mixFrame              080F1CF8 mixDmaStop            080F1D54 mixSetReverb
080F1D7C voiceIsActive         080F1D90 mixSetFilter          080F1D9C mixSetFilterGain
080F1DA8 mixClearEffects
Synth
080F1DE0 chanLfoTick           080F1E9C synthLfoTick          080F1EC4 chanReleaseAll
080F1F34 chanKillAll           080F1FB8 synthReleaseAll       080F1FE0 synthKillAll
080F2008 synthSetPriority      080F2040 chanReset             080F2118 synthInit
080F2184 synthSetBank          080F2188 noteCalcPitch         080F2364 noteCalcVolume
080F237C noteEnvelopeTick      080F241C noteUpdate            080F2488 noteUpdateAll
080F24B4 noteInit              080F24F4 noteFindPlaying       080F2550 noteFindFree
080F2588 noteFindQuietestReleased 080F25E4 noteFindQuietest   080F2638 noteFindStealable
080F26F8 chanNoteOff           080F276C noteAlloc             080F27A4 panRightGain
080F27BC panLeftGain           080F27D8 synthKeyToFreq        080F27F8 chanNoteOn
080F2B60 chanSetPitchBend      080F2B7C chanSetVolume         080F2B9C chanSetPan
080F2BC4 chanGetPan            080F2C00 chanUpdatePan         080F2CA8 chanSetProgram
080F2CC8 chanSetExpression     080F2CE8 chanSetBankSelect     080F2D44 chanSetFlag0
080F2D60 chanSetModDepth       080F2D80 chanSetField6         080F2DA0 chanSetWet
080F2DC0 chanSetLfoType        080F2DE0 chanSetVibRange       080F2DEC chanSetLfoSpeed
080F2DF8 chanSetLfoDelay       080F2E04 chanSetBendRange      080F2E10 chanSetInvert
080F2E38 chanSetPriority       080F2E60 chanSetRandomPitch    080F2EB8 chanSetRandomKey
080F2EC4 chanSetRandomKeyRate  080F2ED8 synthSetTranspose     080F2EDC synthSetVolume
080F2EE0 synthSetPan           080F2F0C synthSetTune          080F2F10 synthSetBendRange
080F2F3C synthSetField6        080F2F40 synthSetFreqTable     080F2F44 sweepInit
080F2F7C sweepStart            080F2F88 sweepStop             080F2F94 sweepTick
Random, PSG
080F3034 sndRandom             080F3058 psgInit               080F309C psgTrigger
080F30CC psgFreqToReg          080F3100 psgVolToReg           080F3118 psgUpdate
080F33EC psgUpdateAll          080F344C readBE16              080F3458 readBE32
080F3470 strLen8
Players, sequencer, API
080F3490 playerStart           080F3650 sndPlay               080F367C playerStop
080F3690 playerSetPause        080F36BC playerIsPlaying       080F36F4 playerPause
080F3700 playerResume          080F370C sndPauseAll           080F373C sndResumeAll
080F376C playerSetVolume       080F3770 playerSetTune         080F3780 playerSetPan
080F3790 sndPauseSound         080F37D8 memEqual              080F3804 calcTickRate
080F3824 playerSetTempoScale   080F3848 playerFade            080F38E8 playerFadeOutStop
080F38F8 playerFadeOutPause    080F3908 playerFadeIn          080F3918 seqSysEx
080F39A4 seqMetaEvent          080F3A84 seqControlChange      080F3D84 seqQueueNote
080F3DE8 seqTrackEvent         080F3F18 seqTrackTick          080F4030 playerFadeTick
080F40CC playerTick            080F4298 sndMain               080F4468 sndSetReverbBase
080F4480 sndNop                080F4484 playerInit            080F44B8 readVarLen
080F44E0 liveInit              080F45DC liveMidiInput         080F4628 liveParse
080F47E8 liveTick              080F4898 sndInit
```
