# Factor 5 MusyX — GBA sound driver
## Reverse-engineering report and technical reference

*MusyX is Factor 5's cross-platform sound system (Game Boy Color, Nintendo 64, Game Boy Advance,
GameCube). This document covers the **GBA runtime**, analysed from two retail games, plus what the
`gm2song.exe` converter reveals about how MIDI files become MusyX songs on every platform.*

**Subject files** (`…/GBAAudioLab/MusyX/`)

| File | Role |
|---|---|
| `Earthworm Jim 2 (E) (M5).gba` | 8 MiB ROM, AGB-AJ4P. MusyX built as **Thumb** code. Primary disassembly target. |
| `I Spy Challenger (U).gba` | 8 MiB ROM, AGB-A4CE. MusyX built as **32-bit ARM** code. Same library, different build. |
| `gm2song.exe` | Win32 console tool, "GM2SONG - GM-File converter V1.32, (C)2001 Factor 5, written by T.Engel & J.Petersam", PE timestamp 2001-02-19. |

**Method.** Both ROMs were loaded into Ghidra and decompiled. The EWJ2 driver region was then
regenerated as a GNU-as source file and **reassembled byte-identically** (§13). `gm2song.exe` was run
under Wine on purpose-built MIDI files. All 11 EWJ2 songs and all 28 I Spy songs were converted back to
MIDI with the tool in this package and fed through `gm2song -A` again. 7 of 11 EWJ2 songs and 16 of 28
I Spy songs came back **byte-identical** to the ROM data. The rest differ only where the original MIDI
held information that gm2song throws away (§11.4). Claims that rest on inference rather than a direct
read of code are marked *(inferred)*.

---

## 1. Executive summary

MusyX GBA is a **C-coded, macro-driven, software-mixing** driver with a small hand-written ARM core.

* **Two voice families.** The four DMG/PSG channels (square 1, square 2, wave, noise) are driven
  directly. There are also *N* DirectSound **software voices** (10 in EWJ2, 8 in I Spy), which are mixed by
  ARM routines into a 16-bit buffer and streamed to FIFO A/B by DMA1/DMA2.
* **Everything is a SoundMacro.** A note, a sound effect or a drum hit starts a *macro*: a small
  byte-code program, 54 opcodes, run once per frame per voice. The program starts samples, sets
  envelopes and pans, does vibrato, sweeps and portamento, branches on key/velocity/random/flags,
  and waits for key-off. This is the same "SoundMacro" idea as GameCube MusyX. The GBA opcode set is its
  own, though, with PSG-specific commands (duty, hardware envelope, noise, wave RAM) and a
  **pulse-width-modulated square synthesiser on DirectSound voices**.
* **Songs are MIDI-derived.** `gm2song -A` turns a GM/MIDI file into per-MIDI-channel *track lists*
  of *patterns*. Patterns are compact note streams: delta, velocity, key and length. A tempo track and
  a single loop section are supported. The MusyX project tool then prepends a 0x410-byte header that
  maps each MIDI program (with a separate map for MIDI channel 10) to a macro. MIDI channels 1–4 drive the
  PSG; channels 5–16 drive DirectSound voices.
* **Output.** A stereo or mono 8-bit stream at about 11.4 kHz (Timer 0) with optional linear interpolation
  and an optional feedback **echo** ("reverb"). Mixing runs from a Timer 1 IRQ every 128 samples.
  Sequencing and macros run from the VBlank handler.
* **Why I Spy Challenger is not detected.** It is the same library version, with identical data formats,
  tables and ARM mixer. It was compiled as **ARM code** with APCS frames instead of Thumb, its global state
  lives in **EWRAM** rather than IWRAM, its constant tables are **not at the end of the ROM** (newlib data follows
  them), and it builds I/O addresses with `mov/add` so the FIFO addresses never appear as literals. Any
  signature keyed on Thumb opcodes, odd handler pointers, `0x03006830`, `0x040000A0` literals or a
  table at ROM end will miss it. §12 gives a signature that finds both.

---

## 2. Where everything is

### 2.1 Earthworm Jim 2 (E)

| Region | Address | Notes |
|---|---|---|
| Driver code (Thumb) | `0x08062830–0x08068173` | 155 functions, GCC Thumb. |
| ARM mixer/echo kernels | `0x08068174–0x08068BC3` | Copied to IWRAM by `sndInit`. |
| libgcc helpers used | `0x08068BD0…`, `0x08069040…` | `_call_via_rN`, `__divsi3`, `__udivsi3`, `__umodsi3`, soft-float. |
| PSG frequency table | `0x08725BCE` | 84 × u16, in `.rodata`, just before libgcc's `__clz_tab`. |
| **Project (sound data)** | `0x0872AB74–0x087FFC67` | 852 KiB: macros, FX, 11 songs, 125 samples. |
| Driver constant tables | `0x087FFC68–0x087FFF27` | Register pointers, wave-volume LUT, square wave, pitch tables. |
| Macro opcode table | `0x087FFF28–0x087FFFFF` | 54 Thumb pointers. Ends **exactly at the 8 MiB boundary**. |
| Global state pointer | `[0x03006830]` (IWRAM) | Points at `G` (§5). |
| Driver memory block | `0x03000070…` (IWRAM) | Mixer code + state + buffers (§4.2). |

`sndInit` is called from `0x08061762` with the config `{rate 11025, 10 voices, flags 0x01, echo 0 ms,
project 0x0872AB74}`. `sndHandle` (`0x08064740`) is called from the VBlank handler `0x080624F8`, which has
a reentrancy counter. `sndMixFrame` (`0x08065278`) is called from the Timer 1 IRQ stub `0x08062530`.

### 2.2 I Spy Challenger (U)

| Region | Address | Notes |
|---|---|---|
| Driver code (ARM) | `0x0802FD24–0x08037DB7` | 154 functions, ARM mode, APCS frame pointers. |
| ARM mixer/echo kernels | `0x08037DB8–0x08038807` | **Byte-identical** to EWJ2's 2 640 bytes. |
| PSG frequency table | `0x086AB04E` | Identical contents. |
| **Project** | `0x086AC6FC–0x087046EF` | 352 KiB: 83 objects, 43 FX, 28 songs, 43 samples. |
| Driver constant tables | `0x087046F0–0x087049AF` | Identical to EWJ2. |
| Macro opcode table | `0x087049B0–0x08704A87` | 54 **ARM** (even) pointers, then newlib `.data` (malloc bins, …). |
| ROM data end | `0x087053C8` | Padded with `0xFF` to 8 MiB. |
| Global state pointer | `[0x020340D4]` (EWRAM) | |
| Driver memory block | `0x03000000…` (IWRAM) | |

Config passed by the game (`0x08022BA4`): `{rate 11397, 8 voices, flags 0x01, echo 0, project
0x086AC6FC}`. It then calls `sndSetEchoParams(0x7FFF,0xFFFF,0x7FFF)` (the I Spy address of that function is
`0x08030E60`).

In both games the project is linked **immediately before** the driver's constant tables. The last
sample of the project ends at the first byte of the register-pointer table.

---

## 3. Public API (reconstructed)

Names are descriptive. No symbols survive, and none of these strings appear in either ROM. Signatures come
from the decompiled code. Addresses are EWJ2. The same functions exist in I Spy in the same source order.

**Initialisation and output**

```c
u32  sndGetMemSize(const SndConfig *cfg, u32 sizes[4]);   // 0x08067F70  -> total bytes
void sndSetMemLayout(const u32 sizes[4], void *base, void *blocks[4]); // 0x0806815C
int  sndInit(const SndConfig *cfg, void *blocks[4], void (*lock)(void), void (*unlock)(void)); // 0x08062830
void sndQuit(void);                        // 0x08062C20
void sndHandle(void);                      // 0x08064740  once per frame (VBlank)
void sndMixFrame(void);                    // 0x08065278  Timer 1 IRQ, every 128 output samples
void sndOutputStop(void), sndOutputResume(void);         // 0x080651DC / 0x08065544
void sndSetActiveVoices(u8 n);             // 0x08063344  0 stops output entirely
void sndSilence(void);                     // 0x08062B64  stop every voice and macro, clear echo
```

```c
typedef struct {       // 12 bytes
    u16  rate;         // requested mix rate in Hz (EWJ2 11025, I Spy 11397)
    u8   voices;       // DirectSound software voices (0 = PSG only)
    u8   flags;        // bit0 no interpolation, bit1 mono, bit2 half-rate mono echo, bit3 run mixer from ROM
    u16  echoMs;       // echo delay in ms (0 = no echo buffer)
    u16  pad;
    const void *project;
} SndConfig;
```

**Sound effects** (handles are `voice<<16 | serial | random<<24`, checked against a table)

```c
u32  sndFXStart(u16 fx, u8 key, u8 vol, u8 pan);  // 0x08062C74  0x80+ = take default from FX table
int  sndFXKeyOff(u32 h);       // 0x08063388      int sndKeyOffAll(void);   // 0x080633C4
int  sndFXCheck(u32 h);        // 0x0806340C
u8   sndFXVolume(u32 h,u8 v);  // 0x08062EA4      u8 sndFXGetVolume(u32 h); // 0x08063450
     sndFXPan(u32 h,u8 p);     // 0x08062F44      u8 sndFXGetPan(u32 h);    // 0x08063038
u16  sndFXPitch(u32 h,u16 p);  // 0x080630AC      u16 sndFXGetPitch(u32 h); // 0x080634A8
```

**Sequencer**

```c
int  sndSeqLoad(u32 song);     // 0x08067168  sets up a song (state = loaded)
int  sndSeqStart(void);        // 0x08067D40  loaded -> playing
int  sndSeqStop(int mode);     // 0x08067324  mode 0 let ring, 1 key-off, 2 cut
int  sndSeqPause(int mode);    // 0x080673DC       int sndSeqContinue(void);   // 0x08067D6C
int  sndSeqIsActive(void);     // 0x08067490       int sndSeqSpeed(u16 x4_12); // 0x08067DA0
int  sndSeqGetStateSize(void); // 0x08067DE4 (=0x150)
int  sndSeqSaveState(void*), sndSeqRestoreState(const void*);  // 0x08067548 / 0x08067630
```

**Volume, echo, flags**

```c
sndSetMusicMasterVolume(u8) 0x080629D4   sndSetFXMasterVolume(u8)  0x08062A64
sndSetSongVelScale(u8)      0x080635B4   sndSetFXVelScale(u8)      0x080635CC
sndSetPSGMasterVolume(u8)   0x080635F4   (SOUNDCNT_L low byte & 0x77)
sndSetSOUNDCNT_H_lo(u8)     0x080635E4   (PSG/DirectSound mix ratio)
sndSetReverb(int on)        0x08063504   sndSetEchoParams(fb, ?, wet) 0x08062AF4
sndGetFlags/SetFlags/TestFlag/SetFlag/ClearFlag   0x0806353C–0x08063594   (macro flag word, §8 SETFLAG/IFFLAG)
```

**PCM streams** (four slots, filled by a callback through `_call_via_r4`)

```c
u32 sndStreamStart(int slot, cb, rate, ..., vol, int reverb) 0x08063124
sndStreamVolume 0x08063244   sndStreamPan 0x08063744   sndStreamReverb 0x08063778
sndStreamActivate 0x080636CC sndStreamFree 0x08063700  sndStreamCalcBlocks 0x080637B8
```

---

## 4. Hardware use and the output pipeline

### 4.1 Registers

| Resource | Use |
|---|---|
| Timer 0 | Sample clock. `TM0CNT = 0x00800000 \| (-ticks)`, where `ticks = (16 777 216 / rate) & 0xFFC0`. |
| Timer 1 | Mix IRQ. Prescaler 64, reload `-2·ticks`, so it fires every 128 samples (`0x00C1xxxx`). |
| DMA1 / DMA2 | `0xB6600004` (enable, IRQ, FIFO timing, 32-bit, repeat) → FIFO A / FIFO B. |
| `SOUNDCNT_H` hi byte | Written `0x9A` on start (FIFO A → left, FIFO B → right, both on Timer 0, FIFOs reset) and `0x88` on stop (reset only). |
| PSG regs | Through pointer tables at `0x087FFC68` (freq regs) and `0x087FFC78` (envelope regs). |
| Wave RAM | Loaded from a type-1 sample: one 32-step bank, or two banks for 64-step waves. |

Because of the `& 0xFFC0` rounding, any requested rate between ≈11 300 and 11 397 Hz becomes **11 397.6 Hz**
(1 472 cycles per sample). Both games run at exactly that rate.

### 4.2 Memory

`sndGetMemSize` returns four sizes:

| Index | Size | Contents |
|---|---|---|
| [0] | `0x318 + voices·0x84` | State: `G`, macro states, sequencer, voices. |
| [1] | ARM kernel bytes | Mixer code copied to IWRAM. Absent when flags bit 3 is set. |
| [2] | `0x500` stereo / `0x280` mono | Mix buffer and FIFO rings. |
| [3] | `blocks·0x100` (or `·0x200`) | Echo delay line. `blocks = rate·ms/128000`, clamped to 1…255. |

`sndSetMemLayout` places them as `[1] code, [0] state, [2] buffers, [3] echo` from the base address.

### 4.3 Mixing (`sndMixFrame`, Timer 1 IRQ)

1. On the first call, start Timer 1. Advance the triple-buffer index `0→1→2→0`. On index 1, restart
   DMA1/2 at the start of the two 3×128-byte FIFO rings.
2. For each active mixer voice, call the selected **voice kernel**. It mixes 128 samples into the 16-bit
   dry buffer, or into the echo input if the voice's send flag is set. A return value of 1 means the sample
   ended, and the voice is unhooked. Streams refill here.
3. If the echo is active, run the **echo kernel**: a single feedback delay line with three 16-bit gains
   (`G+0x110/0x112/0x114`, defaults 0x7332 / 0xFFFF / 0xCCCC). Its output is added to the dry buffer.
4. Run the **output kernel**, which clamps to ±127, packs to 8-bit and writes to ring slot *n*, then
   clears the mix buffer.

**Kernels** (hand-written ARM, identical in both games). `sndInit` picks one of each from `flags`:

| Address | Role |
|---|---|
| `0x08068174` | Output, stereo: interleaved L/R → FIFO A and B |
| `0x08068288` | Output, mono: one buffer, both FIFOs read it |
| `0x08068320` | Voice, stereo, linear interpolation |
| `0x08068500` | Voice, stereo, nearest *(used by both games: flags = 1)* |
| `0x0806868C` | Voice, mono, interpolated |
| `0x08068840` | Voice, mono, nearest |
| `0x080689CC` | Echo, stereo full-rate (256 samples) |
| `0x08068A70` | Echo, mono 128 → duplicated to L/R (flags bit 2) |
| `0x08068B20` | Echo, mono |

The voice kernels play **signed 8-bit PCM**. The step is 4.12 fixed point. Playback runs forward, or
**backward** if `end < cur`. A loop wraps to the loop start. Per-voice volumes are separate 8-bit L/R values.
A "surround" flag negates the right channel.

### 4.4 Mixer voice (0x1C bytes, array at `G+0xC8`)

```
+00 ptr  sample header          +10 u32 loop length
+04 ptr  current                +14 u16 step (4.12)
+08 ptr  end                    +16 u16 fraction
+0C ptr  loop start (0 = none)  +18 u8 volL  +19 u8 volR  +1A u8 invertR  +1B u8 echoSend
```

---

## 5. Global state `G` (pointer at 0x03006830 / 0x020340D4)

```
+000 fn   lock()   (IRQ off)           +0C4 u16 music master volume (0x100 = unity)
+004 fn   unlock()                     +0C6 u16 FX master volume
+008 u8   active DS voices             +0C8 ptr mixer voices[n]     (0x1C each)
+009 u8   reserved voices (alloc start)+0CC ptr active mixer list[n]
+00A u16  actual output rate (Hz)      +0D0 ptr DS voices[n]        (0x40 each, §6)
+00C u32  RNG state (×0xA8351D63)      +0D4 ptr active DS voice list[n]
+010 u32  macro flag bits              +0D8 fn  voice kernel  +0DC fn echo-send kernel
+014 u16  song velocity scale          +0E0 fn  output kernel +0E4 fn echo kernel
+016 u16  FX velocity scale            +0E8 ptr mix buffer   +0EC ring A  +0F0 ring B  +0F4 end
+018 u32  PSG channel flags[4]         +0F8 u8 ring index  +0F9 u8 timer running  +0FA u16 TM1 reload
+028      PSG pitch blocks[3] ×0x24    +0FC echo {in, start, rd, wr, end} +110 fb +112 ? +114 wet
+094      PSG envelopes[4] ×8          +116 u8 echo active     +117 u8 config flags
+0B4 u16  PSG priority[4]              +118 ptr project
+0BC u16  last PSG freq value[3]       +11C ptr macro states[n+4] (0x10 each)
+0C2 u8   SOUNDCNT_L pan shadow        +120 ptr sequencer state (0x154)
+0C3 u8   lock nesting                 +124 u16 handle serial  +128 ptr handle table  +12C stream cb[4]
```

**Voice numbering.** 0–3 are the PSG channels (square 1, square 2, wave, noise). 4… are DirectSound voices.
Every per-voice table (macro state, handle, sequencer note record) is indexed this way.

**Macro state (0x10 bytes):** `+0 pc`, `+4 key-off trap address`, `+8 u16 loop counter`,
`+A u16 wait counter`, `+C u16 macro/object id`.

---

## 6. Voices, envelopes and modulation

### 6.1 DirectSound voice (0x40 bytes)

PSG channels 0–2 carry the same first 0x24 bytes at `G+0x28+ch·0x24`. Their envelope and flags live in
`G+0x94`/`G+0x18`.

```
+00 s16 base pitch (note<<8)          +22 s16 previous pitch (for LASTNOTE / portamento)
+02 s16 pitch offset                  +24 ptr ADSR table, or s32 fade rate
+04 s16 sweep 1 value, +06 step, +08 limit   +28 u16 envelope level (0…0xFF00)
+0C s16 sweep 2 value, +0E step, +10 limit   +2A u8 final volume  +2B u8 volume·2+1
+0A s16 pan sweep value, +12 step, +1A/+1B min/max
+14 s16 vibrato value, +16 step, +18 counter, +19 half-period
+1C s16 portamento value, +1E step, +20 target
+2C s16 pulse duty / loop-scan position, +2E step, +30/+31 min/max (or count), +32/+33 period
+34 u16 priority (bit 8 set = started as FX)   +36 u16 age   +38 u32 flags
+3C u8 pan (0–127, bit 7 = surround)   +3D u8 song voice   +3E u8 stream slot   +3F u8 age speed
```

**Flags** (`+0x38`, and `G+0x18+ch·4` for PSG):

| Bit | Meaning |
|---|---|
| 0 | ADSR active |
| 1–2 | ADSR phase: 0 attack, 1 decay, 2 sustain, 3 release |
| 3 | Ignore key-off |
| 4 | Release pending |
| 5 | Fade active |
| 6 | Pitch dirty |
| 7 | Volume/pan dirty |
| 8 | Key-off received |
| 9 | Trigger pending |
| 10 | Pulse synth |
| 11 | Loop-scan |
| 12 | Sample playing |
| 13 | Pan-sweep bounce |
| 14 | Loop-scan bounce |
| 15 | Voice done |
| 16 | FX-owned |
| 17 | Stream |

**Pitch.** The final pitch is base + offset + sweep 1 + sweep 2 + vibrato + portamento, in 8.8 semitones.
For DS voices: `step = sample.rate · 2^((key−root)/12) / outRate`, in 4.12. It uses the 128-entry up/down tables
at `0x087FFD28`/`0x087FFE28` with linear interpolation on the fraction. For PSG:
`psg_FreqTable[note mod 84]` plus a fractional interpolation, written only when the value changes.

**Volume and pan.** `vol = (env>>8)+1 · volume·2+1 >> 8`, then a two-segment linear pan law.
The centre point uses `0xB538/65536 ≈ 0.707` on both sides, and the master volume (music or FX) is applied
last. PSG volume is quantised: `vol>>3` goes to the envelope nibble. The wave channel uses the 16-entry LUT
at `0x087FFC88`. PSG pan is just left/centre/right through `SOUNDCNT_L`: <42 left, >85 right.

**Envelopes.** An ADSR table is four u16 values: `{attackAdd, decaySub, sustainLevel, releaseSub}`, applied
per frame to a 0…0xFF00 level. `FADE` is a linear ramp with no table. Neither game uses ADSR tables:
the ADSR offset equals the FX offset in both headers, which makes the table empty. Every release is
done with `WAIT keyoff; FADE out; WAIT; SILENCE`.

**Voice allocation** (`ds_VoiceAlloc`). The search runs from `G+9` (reserved voices) to `G+8`. A free voice
wins. Otherwise the lowest priority wins, then the lowest age. The new priority must be ≥ the victim's.
FX get `+0x100`, so they beat song notes of equal priority. Age starts at `0xC000` and drops by
"age speed" each frame. PSG channels compare priority only.

### 6.2 Per-frame order (`sndHandle`)

`macro_Execute` → pitch sweeps → vibrato → portamento → pulse-width sweep → loop-scan → envelopes →
pan sweep → PSG register writes (freq/vol/trigger) → DS voice volumes, steps and starts (under lock) →
`seq_Handle`. Note-ons issued by the sequencer therefore start their macros on the **next** frame.

---

## 7. Project data format

All offsets are relative to the project base. Everything is little-endian. Objects are 4-aligned and
macro operands are 2-aligned.

```
+00 u32 object table      (EWJ2 0x20)   u32 offset per object; count = (first entry - 0x20)/4
+04 u32 ADSR table        u32 offset per ADSR id (empty when equal to +0C)
+08 u32 (unused; = +04)
+0C u32 FX table          u32 count, then count × 8 bytes
+10 u32 0
+14 u32 0
+18 u32 song table        u32 count, then count × u32 offset
+1C u32 sample table      u32 offset per sample; count = (first entry - this)/4
```

**Object.** A 4-byte header, then a body:

| Byte | Macro | Keymap |
|---|---|---|
| 0 | channel: 0–3 PSG, 4+n DS voice n, `0xFF` any | `0xFF` |
| 1 | flags: bit 0 alternate square 1/2, bit 7 legato (no retrigger) | 0 |
| 2 | 0 | 1 |
| 3 | 0 | 0 |
| body | macro byte-code (§8) | `u16 count` + count × `{u16 sample, s16 pitch(8.8), s8 pan, u8 ?, u8 fixedRate, u8 ?}` |

A keymap is used through the `KEYMAP` macro command: key + offset selects an entry, and that entry
starts its sample on the voice.

**FX entry (8 bytes):** `u16 object, u8 priority, u8 (0xFF, unused), u8 channel (0xFF any),
u8 vol, u8 pan, u8 key`. Both games use priority 10, vol 127, pan 64, key 60 throughout.

**Sample (16-byte header + data):**

```
+00 u32 length (bytes)   +04 s32 loop start (-1 = one-shot)   +08 u16 rate (Hz at root key)
+0A u8 root key          +0B u8 type (0 = signed 8-bit PCM, 1 = DMG wave: 16 or 32 bytes of 4-bit)
+0C u32 0                +10 data
```

**Song:** a 0x410-byte header added by the project tool, followed by the gm2song output (§9):

```
+000 u8[16]   initial program per MIDI channel
+010 [128]    program -> {u16 object, u8 priority, u8 (0xFF)}   channels 1-9, 11-16
+210 [128]    program -> {u16 object, u8 priority, u8 (0xFF)}   MIDI channel 10 (drums)
+410 ...      gm2song GBA output
```

---

## 8. SoundMacro byte-code (GBA)

The dispatcher is `macro_Execute` (`0x0806691C`). It loops `handler(voice, &state)` until a handler returns 0
(yield until next frame). The table is at `0x087FFF28` (EWJ2) or `0x087049B0` (I Spy). Sizes include the
opcode byte. 32-bit operands are stored as two halfwords. Jump offsets are relative to the opcode address.

| Op | Name | Size | Operands → behaviour |
|---|---|---|---|
| 00 | END | 2 | Voice priority 0, voice done (macro ends; voice is freed when silent) |
| 01 | STOP | 2 | Same handler as END |
| 02 | VOLUME | 2 | `u8 v` → volume = v × vel-scale |
| 03 | KEYON | 2 | `u8 dry` → trigger the voice; echo send = (dry == 0) when echo is on |
| 04 | WAIT | 4 | `u8 flags, s16 ticks` (-1 forever). Flags: 1 end on key-off, 2 random 0…ticks, 4 end when sample stops |
| 05 | SILENCE | 2 | `u8 waitEnv` → hard-stop the channel (optionally after the envelope dies) |
| 06 | LOOP | 6 | `u8 flags, u16 count(-1=∞), s16 offset` (same flags as WAIT) |
| 07 | PANNING | 4 | `u8 pan, u8 rnd` → pan ± random |
| 08 | SETPITCH | 4 | `-, s16 pitch` → absolute pitch (8.8) |
| 09 | ADDPITCH | 4 | `u8 abs, s16 v` → pitch offset += v (or = v) |
| 0A | VIBRATO | 4 | `u8 halfPeriod, s16 step` → triangle vibrato |
| 0B | PITCHSWEEP | 6 | `u8 idx(0/1), s16 step, s16 limit` → saw sweep that wraps |
| 0C | PORTAMENTO | 6 | `u8 abs, s16 target, u16 frames` |
| 0D | GOTO | 6 | `-, s32 offset` |
| 0E | SETADSR | 4 | `u8 ignoreKeyOff, u16 adsrId` |
| 0F | STARTSAMPLE | 8 | `u8 flags, u16 sample, u32 offset`. Bit 0 = play at native rate. A nonzero offset is scaled by velocity (bit 7 clear: vel·off/128; set: off − vel·off/128). On the wave channel a type-1 sample is loaded into wave RAM |
| 10 | TRAPKEYOFF | 6 | `-, s32 offset` → jump there when the voice receives key-off |
| 11 | UNTRAPKEYOFF | 2 | |
| 12 | SAMPLEREGION | 10 | `u8 flags, u32 start, u32 len`. Bit 7 = loop the region; low bits = reverse |
| 13 | PULSESWEEP | 6 | `u8 duty, s8 min, s8 max, s16 step` → DS voice plays a 64-byte window of the square table: PWM synth |
| 14 | PULSEVEL | 4 | `s8 add, s8 min, s8 max` → fixed duty from velocity |
| 15 | FADE | 4 | `u8 in, u16 rate` → linear fade in/out of the envelope level |
| 16 | RNDPITCH | 6 | `u8 flags, u16 lo, u16 hi` |
| 17 | SPLITKEY | 6 | `u8 key, s32 off` → jump if note ≥ key |
| 18 | SPLITVEL | 6 | `u8 vel, s32 off` → jump if velocity ≥ vel |
| 19 | SPLITRND | 6 | `u8 p, s32 off` → jump if rand(255) ≥ p |
| 1A | MODOFF | 2 | `u8 mask` → stop vibrato(1)/portamento(2)/sweep 1(4)/sweep 2(8)/pulse(10)/loop-scan(20)/pan sweep(40) |
| 1B | MODRESET | 2 | `u8 mask` → zero those values |
| 1C | LASTNOTE | 4 | `-, s16 add` → pitch = previous note on this song channel + add |
| 1D | KEYMAP | 6 | `-, u16 object, s16 keyAdd` → play keymap entry for key+add |
| 1E | PLAYMACRO | 8 | `-, u8 flags, s8 keyAdd, u8 prio, u8 chan, u16 macro` → spawn another voice |
| 1F | NOP | 2 | (used as a 2-byte pad/marker by the tool) |
| 20 | PSGDUTY | 2 | `u8 duty` (0xFF = from velocity>>5), squares only |
| 21 | NOISEPARAM | 2 | `u8` → `SOUND4CNT_H` low byte |
| 22 | SENDKEYOFF | 2 | `u8 voice` (0xFF = self) |
| 23 | KEYOFFMACRO | 4 | `-, u16 macro` → key-off every voice running it |
| 24 | PSGENV | 2 | `u8` → raw hardware envelope (bit 3 set = write whole byte) |
| 25 | PSGENVOFF | 2 | Hardware envelope 0 + retrigger |
| 26 | SETPRIO | 2 | `u8` → low byte of priority |
| 27 | ADDPRIO | 2 | `s8` → **buggy** (§10) |
| 28 | SETAGE | 4 | `-, u16 age` |
| 29 | ADDAGE | 4 | `-, s16` (clamped) |
| 2A | SETFLAG | 4 | `-, u8 set, u8 bit` → global macro flag word `G+0x10` |
| 2B | IFFLAG | 6 | `u8 bit, s32 off` → jump if flag set |
| 2C | REVERB | 2 | `u8 dry` → echo send without retrigger |
| 2D | PANSWEEP | 6 | `u8 bounce, u8 min, u8 max, s16 step` |
| 2E | KEYOFF | 2 | Start release on self |
| 2F | SCALEVOL | 6 | `u8 useCur, s8 add, u16 scale` → vol = vel·scale/256 + add |
| 30 | LOOPSCAN | 8 | `u8 bounce, s16 step, u16 count, u8 period` → slide the loop window through the sample (wavetable scan) |
| 31 | SETWAVE | 4 | `-, u16 sample` → use a 64-byte window of a sample as the pulse/wave source |
| 32 | PORTAFROMLAST | 6 | `-, s16 target, u16 frames` → glide from the previous note |
| 33 | ADDLOOPLEN | 4 | `-, s16` |
| 34 | AGESPEED | 2 | `u8` |
| 35 | SETLOOPLEN | 6 | `-, u32 len` |

The operand layouts above decode every object in both projects with no unknown opcodes. 209 objects
were checked in total. A typical EWJ2 instrument is:

```
STARTSAMPLE 0,n,0 / KEYON 1 / WAIT 5,-1 (key-off or sample end) / FADE 0,2105 / WAIT 4,31 / SILENCE / END
```

A typical I Spy PSG lead is:

```
NOP / VOLUME 127 / PSGDUTY 2 / PSGENV 2 / KEYON 0 / WAIT 0,10 / VIBRATO 5,7 / WAIT 0,31 / SILENCE / END
```

Macros may jump into another object's code: I Spy's ping-pong pan objects share a tail through IFFLAG/GOTO.

---

## 9. Song format (gm2song `-A` output, at song+0x410)

```
+00 u32 track-table offset (=0x0C)      all offsets relative to this point
+04 u32 pattern-table offset
+08 u32 initial BPM
+0C u32[17] track list offsets          tracks 0-15 = MIDI channels 1-16, 16 = tempo track; 0 = unused
```

**Track list.** Entries of `{u32 delay, s32 pattern}`. *delay* is ticks since the previous entry.
`pattern = -1` ends the track. `pattern = -2` is followed by `{u32 targetOffset, u32 delay}`: jump to
the entry at *targetOffset* (bytes from the list start) and wait *delay* before it. Only one loop section
is allowed on GBA and GB. The loop start is `time(target) − delay`.

**Pattern (music).** The first `u16` is the delay from the section start. After that come events, each
followed by the `u16` delta to the next:

| Bytes | Event |
|---|---|
| `s8 vel ≥1, u8 key, u16 len` | Note (6 bytes). `len = 0` is a no-op, used as a filler for gaps > 65 535 ticks. |
| `s8 vel ≥1, u8 key\|0x80, u16 prog, u16 len` | Program change + note (8 bytes) |
| `0, u8 prog` | Program change (4 bytes) |
| `0, u8 n\|0x80` | Reserve *n* voices (`G+9`), from **MIDI CC 104** |
| `s8 <0` / `FFFF FFFF` | End of pattern |

The tempo track's pattern is `{u16 delta, u16 BPM}` pairs ending with `FFFF FFFF`.

**Timing.** 96 ticks per quarter note. gm2song rescales any MIDI PPQ to 96. The per-frame increment is
`BPM·0x6000/3600` in 8.8 fixed point, multiplied by the speed scale (`sndSeqSpeed`). Tracks 0–3 (PSG)
start late by `BPM·0x60000/(rate·5)`. This is a latency compensation so PSG notes line up with the
buffered DirectSound output *(inferred purpose; the arithmetic is read from the code)*.

**Playback rules** (`seq_Handle` / `seq_NoteOn`):

* The object is chosen through the program map. MIDI channel 10 uses the drum map.
* Tracks 0–3 go to PSG channel *t*. The macro's channel byte can override this, and macro flag bit 0
  alternates between square 1 and square 2.
* Other tracks allocate a DS voice.
* Velocity × song vel-scale becomes the voice volume.
* The note record counts *len* down and sends key-off at zero.
* Notes with `len = 0xFFFF` are effectively held. These come from MIDI notes with no note-off.

---

## 10. Bugs and oddities

1. **ADDPRIO (0x27) is wrong.** It ORs the sign-extended operand into the priority word and then clamps
   to 0…255. A positive *n* sets the low byte to *n* and wipes the FX bit (unless the high byte was set,
   which gives 0xFF). A negative *n* gives 0. This is present in both builds.
2. **`sndQuit` never unlocks.** It increments the lock counter (calling `lock()` on the first nesting),
   silences everything, sets the active-voice count to 0 and stops output, but never decrements the
   counter or calls `unlock()`. The driver stays locked afterwards. That may be deliberate for a shutdown
   call *(inferred)*.
3. **The END/STOP handler zeroes the macro PC** but leaves the voice sounding until its own envelope or
   SILENCE stops it. Macros therefore always end with `SILENCE` before `END`.
4. The `0x08`-offset header field is never read. Neither game ships ADSR tables.
5. The FX entry byte 3 (always 0xFF) is never read by the GBA runtime.

---

## 11. `gm2song.exe` — MIDI → song conversion

### 11.1 Usage

```
GM2SONG [options] <MIDI-file> <song-file>
  -G  Game Boy (Color)   -A  Advance Game Boy   -N  Nintendo 64   -D  Dolphin (GameCube)
```

It prints the file type (Single Track / Syncronous / Asynchronous = MIDI format 0/1/2), track count,
PPQ, BPM and loop range. The message strings are UTF-16 in a resource string table, not in `.data`.

### 11.2 Rules (all four targets)

* One song track per MIDI **channel**. MIDI tracks are merged. More than 256 MIDI tracks is an error.
  The 32-bit formats (N64/GC) allow at most 64 tracks.
* **Loop markers are CC 102 (start) and CC 103 (end).** Exactly one of each is allowed, and the end must
  be after the start. GB and GBA reject multiple loop sections. N64 and GC print `Section %d: %d - %d`.
* Each channel is cut into a pre-loop and a loop pattern. A pattern begins at the first MIDI event of
  *any* kind in its section. Events dropped later, such as controllers, still set where the pattern starts.
* Overlapping notes of the same key pair first-on with first-off. Hanging notes become length 0xFFFF.
* Tempo changes go into the tempo track. BPM is truncated, for example 90 → 89 from the µs tempo.

### 11.3 Target differences

| Target | Observed output |
|---|---|
| **GBA** (`-A`) | §9. Keeps velocity (raw), notes, program changes and CC 104. **Drops all other CCs, pitch bend and aftertouch.** |
| **GB** (`-G`) | Big-endian u16 header `{trackTableOff, patternTableOff, BPM}`. 4 track slots only (MIDI channels 1–4). Track entries `{u16 delay, u8 pattern}` with `0xFE` loop and `0xFF` end. Ticks /4 (24 PPQ). Events `[vel/8 <<4 \| delta>>8][delta lo][key\|0x80 → +prog][len, ≥0x80 as 2 bytes]`, ending `F0 00 FF`. *(Decoded from test files only; partial.)* |
| **N64** (`-N`) / **GC** (`-D`) | **Byte-identical to each other.** This is the classic big-endian MusyX `.son`: header with track-index, region-index and channel-map offsets, initial tempo, a 64-entry per-track table, then region and track data. Same family as the GameCube format documented by the open-source *Amuse* project. |

### 11.4 Round-trip validation

`song_to_midi()` (in `musyx_gba.py`) rebuilds a MIDI from ROM song data. Each channel gets a CC 7 at tick 0
to anchor the pattern, and CC 102/103 go on channel 16 in the conductor track. Converting those MIDIs with
`gm2song -A` reproduced the ROM bytes exactly for:

* EWJ2 songs 0, 2, 3, 4, 5, 9, 10
* I Spy songs 1–7, 17–20, 22, 24–27

Every remaining difference traces to information that does not survive conversion: where a dropped
controller started a pattern, track-end padding, or hanging notes.

---

## 12. Detecting MusyX GBA (why I Spy Challenger slips through)

| Property | EWJ2 | I Spy Challenger |
|---|---|---|
| Driver code | Thumb, GCC | **ARM**, GCC, APCS frame pointers |
| Opcode table entries | odd (Thumb) | **even** |
| Opcode table position | last 0xD8 bytes of the 8 MiB ROM | **0x087049B0**, followed by newlib `.data`; ROM data ends at 0x087053C8 |
| Global state pointer | `0x03006830` (IWRAM) | **`0x020340D4`** (EWRAM) |
| FIFO/DMA addresses | Literal pool words (`0x040000A0` …) | **Built with `mov/add`**, no literals |
| Memory block | `0x03000070` | `0x03000000` |
| Voices / rate | 10 / 11025 requested | 8 / 11397 requested (both 11397.6 Hz actual) |
| Data formats, constant tables, ARM kernels, macro set | identical | identical |

**Robust signature** (implemented as `find_musyx()`):

1. Find the 32-byte register-pointer table:
   ```
   64 00 00 04  6C 00 00 04  74 00 00 04  7C 00 00 04
   62 00 00 04  68 00 00 04  72 00 00 04  78 00 00 04
   ```
2. Confirm 64×`7F` followed by 64×`80` at +0x40.
3. The opcode table is at +0x2C0, 54 pointers. If bit 0 is set the build is Thumb; if clear it is ARM.
4. The project is the 4-aligned block whose header starts `20 00 00 00` and whose last sample ends at the
   start of the register-pointer table.

A secondary signature is the 2 640-byte ARM kernel block. It is identical in both games because it is
hand-written assembly.

Both games resolve uniquely with this method.

---

## 13. Deliverables

| File | What it is |
|---|---|
| `musyx_ewj2.s` | Reconstructed GNU-as source of the whole EWJ2 driver (`0x08062830–0x08068BC3`): 164 named functions, Thumb + ARM. Reassembles **byte-identically** with `arm-none-eabi-as -mcpu=arm7tdmi` + `ld -Ttext=0x08062830`. |
| `musyx_ewj2_rodata.s` | The two read-only blocks (PSG frequency table; register/pulse/pitch/opcode tables). Byte-identical. |
| `musyx_gba.py` | Python tool: `find_musyx`, project parser, macro disassembler, song decoder, `song_to_midi`. |
| `ewj2_midi/`, `ispy_midi/` | All 11 + 28 songs as MIDI. Channel = song track: 1–4 PSG, 10 drums; loop = CC 102/103 on channel 16. |
| `musyx-ewj2-data-dump.md`, `musyx-ispy-data-dump.md` | Full decode of both projects: header, FX, samples, songs, every macro and keymap. |
