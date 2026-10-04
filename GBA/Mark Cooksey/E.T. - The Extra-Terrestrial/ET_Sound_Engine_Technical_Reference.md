# Mark Cooksey's GBA sound engine
## Reverse-engineering report and technical reference: *E.T.: The Extra-Terrestrial* (GBA, 2001)

**Subject file** (`…/GBAAudioLab/MC/`)

| File | Role |
|---|---|
| `E.T. - The Extra-Terrestrial (E) (M6).gba` | 4 MB retail ROM, game code `AETP`, header title `ETTHEEXTRAT`. No symbols, no debug data. |

**Provenance.** The ROM's credits string reads *"Music and sound effects by Mark Cooksey"* next to
*"(c) 2001 NewKidCo"* and *"TM and (c) Universal Studios"*. The driver has no name string or version
tag, so this document calls it by its author. Every function, variable and table name below was
assigned during this analysis. None of them come from the ROM.

This engine has **no code or data in common with QuickThunder** (the AudioArts driver covered in the
project's other documents). The two share only the GBA hardware they drive.

**Lineage.** Like QuickThunder, this is a port of its author's Game Boy (Color) driver. The GB
version is documented in Will Trowbridge's disassembly of *Earthworm Jim: Menace 2 the Galaxy*
(GBC) bank 1, `EWJ2A.ASM`. Cooksey also wrote NES and Game Gear drivers that closely resemble the
GB one, and the whole family may descend from his Commodore 64 engine. That last link comes from
Will's research and was not checked here. §1a lists what carried over to the GBA version and what
changed.

Everything below comes from disassembling the ROM. Where something is an inference rather than a
direct reading of the code, it is marked *(inferred)*.

---

## 1. Executive summary

The music driver is a **compiled-C, register-driving, PSG-first** engine with no software mixer.

* **Six channels.** The four DMG/PSG channels play the music. The two DirectSound FIFOs can play
  looping PCM instruments, which only one song (song 15) uses. The CPU never touches a sample:
  DirectSound playback is DMA plus a timer, with no mixer.
* **Tracker-style data.** Each song has one *sequence* (order list) per channel. A sequence entry
  plays a *pattern* with a transpose and a repeat count. A pattern is a stream of 3-byte events
  `{note, instrument, length-index}`. The length index goes through a per-song table of tick counts.
* **Instrument macros.** A PSG instrument carries up to three tick-driven tables: a **volume
  envelope** (re-programs the hardware envelope and restarts the channel on each step), a
  **pitch-delta** table (vibrato and slides), and an **arpeggio** table (semitone offsets, used for
  fast chord arpeggios and octave jumps). The three tables are the GB driver's envelope, vibrato
  and pitch-modulation sequences, rewritten in C (§1a).
* **Fractional tempo.** An 8.8 accumulator adds the song tempo every frame. The sequencer ticks
  whenever the accumulator passes 0x100, so tempo 205 means about 0.8 ticks per frame. The table
  effects, however, run on **ticks, not frames**.
* **Three built-in sound-effect systems, all unused in E.T.:** a PSG "register script" player that
  borrows music channels, a two-slot DirectSound sample player, and a looping "stream" player.
  Their code is present and working, but nothing calls it. The DirectSound tables are zero-filled,
  while twelve PSG scripts are still in the ROM.
* **E.T.'s actual sound effects** come from a **separate module** (§9) that streams **complete
  RIFF/WAV files** (94 effects, 66 distinct WAVs, about 710 KB) through the same two FIFOs. It uses
  per-effect priorities, a pitch factor, and Timer 2/3 IRQs as length counters. Because it shares
  DMA1/DMA2 with music channels 5/6, the game refuses SFX while song 15 is playing, and it has to
  kill the DMA by hand when it leaves that song (§10.1).

Per-frame cost is small: one pass over six channel structs, a few table walks, and one 32-bit
division per sample note-on. The largest CPU cost is actually the GCC code itself: the channel
loop is fully unrolled into six `if (ch == n)` branches, about 4 KB of Thumb for `mcUpdate` alone.

---

## 1a. Relationship to the Game Boy (Color) driver

This section compares the GBA driver with `EWJ2A.ASM` (Earthworm Jim: Menace 2 the Galaxy, GBC).
The GBA code is a straight C re-implementation, not a translation of the Z80 source. The data
model and command numbers carry over almost unchanged.

| Feature | GB/GBC (EWJ2) | GBA (E.T.) |
|---|---|---|
| Frequency table | 96 values starting `$009D, $0107, $016B …` | **the same values** (`157, 263, 363 …`), 97 entries with 0 at the end |
| Song table entry | 4 channel pointers + note-length table pointer (10 bytes) | 6 channel pointers + note-length table pointer (28 bytes) |
| Tempo | `BeatCounter += Tempo`; the song runs only on 8-bit carry | `mcTempoAcc += mcTempo`; the song runs only when it reaches ≥ 0x100 (same rule, 32-bit) |
| Effects gated by tempo | yes: `Audio1_PlaySong` returns before any channel work when there is no carry | yes (§5). This is inherited, not a porting slip |
| Note event | 2 bytes: note (bit 7 = instrument bit 4) + `inst<<4 \| len` nibbles | 3 bytes `{note, inst, len}`, with the length index going through the table as before |
| Envelope sequence | `{value, delay}`, `$FF` = end | `{value, ticks}`, `0xFF` = hold, `0xFE,n` = loop |
| Vibrato sequence | `{delta, delay}`, `$7E` stop, `$7D` loop | pitch table `{delta, ticks}`, `0xFF` / `0xFE` |
| Pitch-modulation (arpeggio) sequence | `{delay, semitone}`, `$FF` + pointer = loop | arpeggio table `{ticks, semitones}`. The GB "delay first" order explains why this table is swapped relative to the other two |
| Noise | `$63` command and a separate noise vibrato sequence set NR43 | the noise-parameter table (instrument `+0x18`) |
| SFX map | `Audio1_SFXTab`: 4 macro numbers per effect, `$FF` = none | `mcPsgSfxMap`: identical layout |
| SFX script | first byte = channel, then `{delay, NRx1, NRx2, NRx4, NRx3}`, `$FF` stop, `$FE`+ptr jump | first halfword = channel, then `{frames, v1lo, v1hi, v2hi, v2lo}`. That is **the same five fields in the same order**, widened to halfwords. `0xFF` / `0xFE,0xFD` stop, `0xFE,n` jump |
| SFX vs music | SFX pointer non-zero → music skips the channel | `owned` flag, same effect |
| Wave RAM | `AA×8, 00×8` | `FF×8, 00×8` |

**Commands.** The GB driver has a dispatch table for `$60`–`$6D`. The GBA driver tests seven
values with an if-chain, and the four sequence-level ones now live in the 32-bit sequence stream
rather than in the note stream:

| Cmd | GB/GBC | GBA |
|---|---|---|
| `$60` | tie (extend the note by a length) | sequence: skip 3 words, no effect. Pattern: `0x60` = rest |
| `$61` | stop channel | `SEQ_END` |
| `$62` | jump to pointer | `SEQ_JUMP` to a word index |
| `$63` | set noise NR43 | — (noise table instead) |
| `$64` | call macro with transpose and repeat count | `SEQ_PAT` (pattern pointer, transpose, repeat) |
| `$65` | return from macro | pattern end byte `0x65` |
| `$66` | conditional flag (`LoopFlag`, not read by the driver) | `SEQ_CONDFLAG` → `mcCondFlag`, likewise never read |
| `$67` | global panning (NR51) | `SEQ_PAN`: `SOUNDCNT_L = v<<8 \| 0x77`. Bits 8–15 are the GBA's NR51 |
| `$68` | set note-length table | — (fixed per song) |
| `$69` | tempo | `SEQ_TEMPO` |
| `$6A`–`$6D` | per-channel panning | — |

In the GB driver, macros (patterns) are called from a channel stream that can also hold notes.
The GBA version splits this into two levels. Sequences hold only commands and pattern calls.
Patterns hold only notes, rests and the `0x65` return.

---

## 2. Build and ROM layout

The code is **Thumb, compiled by an early GCC** *(inferred)*. The signs are GCC 2.9x idioms:
`adds rX, rY, #0` register moves, `push {…}; … pop {r0}; bx r0` epilogues, and `bl` used as a
*long branch inside a function* (four such targets in `mcUpdate`). It calls libgcc's `__udivsi3`
(0x080108A4).

| Region | ROM address | Size | Contents |
|---|---|---|---|
| crt0 + IRQ dispatcher | `0x080000C0` | | AGB-SDK style; `IntrTable` at `0x03000350` |
| **Music driver (module A)** | **`0x080025EC`–`0x08003CE8`** | 5 884 B | 12 functions, §3 |
| game code | `0x08003CE8`–`0x08004944` | | (atan2 lookup, RNG, IRQ setup, … not sound) |
| **WAV SFX player + glue (module B)** | **`0x08004944`–`0x08004DBC`** | 1 144 B | 9 functions, §9 |
| `__udivsi3` | `0x080108A4` | | libgcc |
| **Music data** | **`0x08016790`–`0x08027AF0`** | 70 496 B | tables, 2 PCM samples, 210 patterns, 66 sequences, 31 instruments |
| **SFX table** | `0x080284FC`–`0x080287EC` | 752 B | 94 × 8 bytes |
| WAV files | `0x0833EB9C`–`0x083F03FC` | ≈710 KB | 66 RIFF/WAVE files, 8-bit mono 11025 Hz |

Driver RAM is the first 0x268 bytes of IWRAM (`0x03000000`–`0x03000267`). Module B keeps 20 bytes
at `0x03002CB0` and reads three flags in the game's state struct at `0x03002CE0`.

### Music data map

```
08016790  mcSmpNoteTable   96 x 12   {rate Hz, samples/frame, timer period}   (DirectSound notes)
08016C10  sample 0 PCM     5 688 B   8-bit signed
08018248  sample 1 PCM     9 088 B   8-bit signed
0801A5C8  mcDsSfxTable     90 x 16   all zero (unused SFX-sample / stream table)
0801AB68  mcSmpInstTable    2 x 8    {PCM address, length}
0801AB78  mcPsgSfxMap      16 x 4    PSG SFX -> script per channel (unused)
0801ABB8  PSG SFX scripts  12        (unused)
0801B1C4  mcPsgSfxScripts  16 ptrs   (12 used)
0801B204  durTable0        28 words  note-length table (15 songs)
0801B274  durTable1        18 words  note-length table (song 1)
0801B2BC  patterns         210       13 936 events, 42 020 B
080256E0  sequences        66        5 972 B
08026E34  mcFreqLo         97 B      PSG frequency, low byte
08026E95  mcFreqHi         97 B      PSG frequency, high byte
08026EF8  mcSongTable      16 x 28
080270B8  modulation tables 33       envelope / pitch / arpeggio
08027618  instruments      31 x 36
08027A74  mcInstTable      31 ptrs
```

---

## 3. Public API and host integration

| Address | Name | Called from | Purpose |
|---|---|---|---|
| `080025EC` | `mcSoundInit()` | `main` | reset hardware + state |
| `08002794` | `mcPlaySong(int song)` | `PlayMusic`, `StopMusic` | start a song |
| `08002A9C` | `mcUpdateSamples()` | both VBlank handlers | loop the DirectSound music samples |
| `08002CC4` | `mcUpdate()` | both VBlank handlers | SFX slots, tempo, sequencer, effects |
| `08002940` | `mcPause()` | *(no callers)* | freeze sequencer, silence free PSG channels |
| `0800299C` | `mcResume()` | *(no callers)* | |
| `080028B8` | `mcPlayPsgSfx(int n)` | *(no callers)* | PSG register-script SFX |
| `0800270C` | `mcDsSfxStart(idx, chan, vol)` | *(no callers)* | DirectSound SFX |
| `080029A8` | `mcDsSfxStop(chan)` | *(no callers)* | |
| `08002A24` | `mcStreamStart(idx, param, vol)` | *(no callers)* | looping stream |
| `08002A60` | `mcStreamStop()` | *(no callers)* | |
| `08002A90` | `mcStreamSetParam(x)` | *(no callers)* | writes a variable nothing reads |

**Host obligations** (all visible in the E.T. game code):

```
main (0x080053A4):
    ... IntrTable[5] = SfxTimer2IRQ; IntrTable[6] = SfxTimer3IRQ ...
    mcSoundInit();            0x0800546A
    SfxInit();                0x0800546E   (module B; overrides SOUNDCNT_H)
    PlayMusic(15);            0x0800548C   the first song the game starts
VBlank handlers (0x08001B10 and 0x08001B34), in this order:
    SfxVBlank();  mcUpdateSamples();  mcUpdate();
```

The driver needs no interrupts of its own. Only module B uses IRQs (Timers 2 and 3).

---

## 4. Hardware resources

| Resource | Owner | Use |
|---|---|---|
| SOUND1–4 registers | music channels 1–4 (and the unused PSG SFX) | |
| `REG_WAVE_RAM` | driver | loaded once at init with a 50 % square wave (`FF×8, 00×8`), both banks |
| `SOUNDCNT_L` | driver | `0xFF77` at init. Sequence command `0x67` (`SEQ_PAN`) sets the PSG L/R enables (panning) |
| `SOUNDCNT_H` | driver, then module B | driver writes `0xFB0E`, then `SfxInit` writes `0x7301` (final) |
| `SOUNDCNT_X` | driver | `0x8F` |
| `SOUNDBIAS` | module B | `(bias & 0x3FF) \| 0x4000`: 8-bit / 65.536 kHz PWM |
| DMA1 → `FIFO_A`, Timer 0 | music ch 5 **and** WAV channel A | shared |
| DMA2 → `FIFO_B`, Timer 1 | music ch 6 **and** WAV channel B | shared |
| Timer 2 / Timer 3 | module B | one-shot length counters with IRQ |

Final mix after `SfxInit`: `SOUNDCNT_H = 0x7301` sets PSG to 50 %, DirectSound A and B to 50 %,
both routed L+R, with A on Timer 0 and B on Timer 1.

**DMA idioms** (used identically in both modules):

```
stop:   DMAxCNT = 0x84400004     enable | 32-bit | dest fixed, count 4, immediate  -> a dummy
        DMAxCNT_H = 0x0440       transfer that leaves the channel idle
start:  DMAxSAD = pcm; DMAxDAD = FIFO; DMAxCNT = 0xBE400000 (driver) / 0xB6400004 (module B)
        = enable | FIFO timing | 32-bit | repeat | dest fixed
timer:  TMxCNT = 0x810000 - period   = enable (0x80), reload 0x10000 - period
```

---

## 5. Per-frame flow

### `mcUpdateSamples()`

```
for ch in 5..6:
   if (active == 1 && seqPtr && owned)
      if (--smpFramesLeft <= 1) {             restart the sample 1 frame before it ends
         stop DMA/timer, DMAxSAD = mcSmpInstTable[inst].addr, DMAxDAD = FIFO,
         TMxCNT = enable | (0x10000 - mcSmpNoteTable[note].period), start DMA
         smpFramesLeft = smpFrameReload
      }
if (mcStreamActive)  -- stream player, never active in E.T.
```

### `mcUpdate()`

```
1  DirectSound SFX slots 0..1         (unused)
2  PSG SFX slots, PSG channels 1..4   (unused)
3  if (mcPaused) return
4  mcTempoAcc += mcTempo
   if (mcTempoAcc < 0x100) return     <- at most ONE tick per frame
   mcTempoAcc -= 0x100
5  for ch in 1..6:
      if (active != 1 || !seqPtr) continue
      if (ticks) {
          ticks--
          if (owned) run this channel's table effects (§8)     channels 1-4 only
      }
      if (ticks == 0) {
          if (!patPtr) run sequence commands until SEQ_PAT or SEQ_END (§7.2)
          if (patPtr) {
              b = pattern[patPos]
              if (b == 0x65) { repeat or drop the pattern; go back to the sequence }
              else note event (§7.3) + note-on register writes (§8)
          }
      }
```

Everything below step 3 runs only on frames where the tempo accumulator produces a tick. **The
table effects (envelope, vibrato, arpeggio) therefore also run at the song tempo, not at 60 Hz**:
their "frames" are really ticks. At tempo 164 (song 5) an effect table advances only on about 64 %
of frames.

A note event is fetched on the same tick that `ticks` reaches 0, so a length of *n* ticks lasts
exactly *n* ticks.

---

## 6. RAM map

All addresses are in IWRAM.

```
03000000  mcPsgSfxCur        u32   last PSG SFX number
03000004  mcStreamIndex      u32   stream player: entry in mcDsSfxTable
03000008  mcDsSfxFrames[2]   u32   DS SFX frames remaining
03000010  mcDsSfxAddr[2]     u32   DS SFX PCM address
03000018  mcStreamActive     u32
0300001C  mcTempo            u32   8.8 ticks per frame (init 0x100)
03000020  mcPaused           u32
03000024  mcStreamPeriod     u32
03000028  mcTempoAcc         u32
0300002C  mcMasterPan        u32   SOUNDCNT_L shadow (GB MasterPan). Init stores 7 and uses it as a
                                   volume; SEQ_PAN stores the whole v<<8|0x77. Never read afterwards
03000030  mcDurTable         ptr   current song's note-length table
03000034  --                       (12 bytes, never referenced)
03000040  mcPsgSfx[6]        12 B  {ptr, index, timer}; 4 used, 6 cleared at init
03000088  mcDsSfxPending[2]  u32
03000090  mcDsSfxLoopFrames[2] u32 0 = one-shot
03000098  --                       (8 bytes, never referenced)
030000A0  mcChan[6]          0x48 B each  -> 03000250
03000250  mcCondFlag         u32   conditional / end-of-song flag (SEQ_CONDFLAG, GB LoopFlag); never read
03000254  mcStreamParam      u32   init 0x2B11, never read
03000258  mcStreamOffset     u32
0300025C  --
03000260  mcDsSfxIndex[2]    u32
```

### Channel struct (`mcChan[n]`, 0x48 bytes, 18 words)

| Off | Name | Meaning |
|---|---|---|
| `00` | `active` | 1 = channel runs (set by `mcPlaySong`, cleared at init) |
| `04` | `owned` | 1 = music may write the registers. `mcPlayPsgSfx` clears it and the SFX script's end sets it again |
| `08` | `seqIdx` | **word** index into the sequence |
| `0C` | `patPos` | byte offset into the current pattern |
| `10` | `ticks` | ticks left on the current note |
| `14` | `note` | note after transpose (8-bit wrap) |
| `18` | `freq` | current 11-bit frequency value (PSG) |
| `1C` | `inst` | instrument number |
| `20` | `seqPtr` | sequence start (0 = channel unused in this song) |
| `24` | `patPtr` | current pattern (0 = fetch from the sequence) |
| `28` | `transpose` | signed, from `SEQ_PAT` |
| `2C` | `patRepeat` | remaining plays of the pattern |
| `30`/`34` | `envIdx` / `envTimer` | envelope table walker; **on ch 5/6: frames-left / frame reload** |
| `38`/`3C` | `pitchIdx` / `pitchTimer` | pitch table walker (noise-parameter table on ch 4) |
| `40`/`44` | `arpIdx` / `arpTimer` | arpeggio table walker |

Table indices count **halfwords** (a table entry is two halfwords, so an index advances by 2).

---

## 7. Data formats

### 7.1 Song table: `mcSongTable`, 16 × 28 bytes

```
+0..+20  ptr  sequence for channels 1..6 (0 = unused)
+24      ptr  note-length table (durTable0 or durTable1)
```

There is no song count and no bounds check. 15 songs use channels 1–4 only. **Song 15** uses all
six and is the only one with DirectSound samples. Song 0 is a single silent note followed by
`SEQ_END`: it is the "stop" song. Song 14 is a 12.7-second jingle that ends. The others loop.

### 7.2 Sequence (order list): 32-bit words

| Words | Macro | Effect |
|---|---|---|
| `0x64, pat, transpose, repeat` | `SEQ_PAT` | play `pat` `repeat` times (0 or 1 = once), notes + `transpose`. Ends the command loop |
| `0x62, n` | `SEQ_JUMP` | `seqIdx = n` (a **word** index; 0 or 4 in the data) |
| `0x61` | `SEQ_END` | silence the channel. The index is **not** advanced, so this re-executes every tick |
| `0x67, v` | `SEQ_PAN` | **global panning**: `SOUNDCNT_L = v<<8 \| 0x77`. `v` is the GB NR51 byte (bits 0–3 right, 4–7 left, one per PSG channel). The `0x77` is master volume 7/7. Every song uses `0xFF` (all channels on both sides) |
| `0x69, t` | `SEQ_TEMPO` | `mcTempo = t` (8.8; 154–255 in the data) |
| `0x66, v` | `SEQ_CONDFLAG` | **conditional flag**: `mcCondFlag = v`. The driver never reads it, as in the GB driver. Every song has `0x66, 1` in channel 1 just before its `SEQ_JUMP`/`SEQ_END`, so it serves as an "end of song reached" flag the game could poll. E.T. does not poll it |
| `0x60, a, b` | — | skips 3 words. This is the GB tie command's number but has no effect here, and the data never uses it |

Command words are global, not per channel. `SEQ_TEMPO` and `SEQ_PAN` appear only in channel 1's
sequence, before the loop point, and `SEQ_JUMP 4` skips over them on each loop.

### 7.3 Pattern: 3-byte events

```
note  inst  len          note 0..0x5F  pitch (0x00 = C#2 on PSG)
                         note 0x60     rest
0x65                     end of pattern
```

* `inst` indexes `mcInstTable`. `len` indexes the song's note-length table.
* **Rest (`0x60`)**: on PSG channels the note becomes **0x30** and the event is otherwise a
  normal note-on. The rest is silent only because the data always pairs it with **instrument 0**,
  which is all zeros (envelope volume 0). On channels 5/6 the note stays 0x60 and the `> 0x5F`
  check simply skips the trigger, so the previous sample carries on (see §10.1).
* End (`0x65`): if `patRepeat` counts down to a non-zero value the pattern restarts. Otherwise
  `patPtr = 0` and the channel goes straight back to the sequence in the same tick.

### 7.4 Note-length tables

```
durTable0 (15 songs):  3 4 6 9 12 18 24 36 48 72 96 144 192 8 16 32 40 64 80 84 15 54 60 42 30 108 132 156
durTable1 (song 1):    3 4 6 9 12 18 24 36 48 72 96 144 192 8 16 32 10 40
```

The first 16 entries are shared. The first 13 form a dotted and straight note ladder on a 12-tick
beat: 12 = 1/4, 24 = 1/2, 48 = whole, 18 = dotted 1/4 *(inferred)*.

### 7.5 Instruments: 36 bytes, 9 words

```
+00 b0        <<8 into the frequency register (0x40 = length enable)
+04 lo        low byte of the envelope/duty register (duty+length, wave length, noise length)
+08 hi        high byte of that register (hardware envelope / wave volume) when no envelope table
+0C envOn     \
+10 env       |  each table has an "on" word the code never reads;
+14 pitchOn   |  the driver tests only the pointer
+18 pitch     |
+1C arpOn     |
+20 arp       /
```

How the fields map per channel:

| | ch 1/2 square | ch 3 wave | ch 4 noise |
|---|---|---|---|
| `lo`/`hi` → | `SOUNDxCNT_H`/`_L` (duty, length, envelope) | `SOUND3CNT_H` (length, volume) | `SOUND4CNT_L` (length, envelope) |
| env table value → | envelope byte, **then restart** | volume byte (`0x20` 100 %, `0x40` 50 %, `0x60` 25 %, `0x80` 75 %, `0` mute), restart | envelope byte, restart |
| pitch table → | freq += delta | freq += delta | **noise parameter** (`SOUND4CNT_H` low byte), no restart |
| arp table → | freq = Freq[note + semis] | same | *(not used)* |
| on channels 5/6 | `inst` indexes `mcSmpInstTable` instead | | |

The envelope tables do not ramp the GBA hardware envelope. Each entry is a fixed start volume
with step 0 (e.g. `0xF0`, `0x70`, `0x30`), and the driver rewrites it and restarts the channel,
so the envelope shape is drawn in software at tick rate.

### 7.6 Modulation tables: s16 pairs

| Table | Pair | Walker |
|---|---|---|
| envelope | `{value, ticks}` | first pair applied at note-on |
| pitch | `{delta, ticks}` | first pair applied at note-on *(see §10.4)* |
| arpeggio | `{ticks, semitones}` | first pair applied at note-on. **Order is swapped** relative to the other two, inherited from the GB pitch-modulation sequence `{delay, semitone}` |

Control values sit in the first halfword of a pair: `0xFE, n` means *loop to halfword n* and
`0xFF` means *hold forever* (the walker steps back onto the `0xFF` each time). Values are compared
as signed, so negative deltas are fine, but no entry can hold the value 254 or 255.

Examples from the data:

```
mod_0802743C  pitch   1/3 -1/3 -1/3 1/3 LOOP->0        slow vibrato (7 tone instruments)
mod_08027454  pitch   4/2 -4/2 -4/2 4/2 LOOP->0        wider, faster vibrato (wave instruments)
mod_08027558  arp     1:+0 1:+4 1:+7 ... LOOP->0       major-chord arpeggio, one note per tick
mod_08027494  arp     1:+24 23:+0 4:+0 4:-12 ... LOOP  2-octave "blip" then octave warble
mod_08027154  env     0x10 0x30 0x50 0x80(5) 0x70(10) 0x60(100) ...   swell then long decay
mod_08027360  pitch   55/2 100/2 34/1 55/1 ...          noise-parameter "snare" sequence
```

There are six arpeggio chord tables (major and minor triads in three inversions) for instruments
19–24.

### 7.7 Frequency table

`mcFreqLo` and `mcFreqHi` hold 97 entries between them (split into low/high bytes). The register
value `x` gives `131072 / (2048 − x)` Hz. Index 0 = 157 = **69.3 Hz (C#2)**, and each index is one
semitone. Entry 96 is 0. Above about index 78 the 11-bit resolution pushes the table
progressively sharp (more than 0.5 semitone, up to ~5 semitones at 94–95). The music stays at or
below index 84 apart from one bad note (§10.6).

Entries 0–95 are **identical, value for value, to `Audio1_FreqsLo/Hi` in the GB driver** (checked
against `EWJ2A.ASM`). The table was carried over directly, and so was its tuning, with index 0 at
69.3 Hz.

### 7.8 DirectSound music samples

`mcSmpNoteTable[note] = {rate, rate/60, 16 777 216/rate}` for notes 24–84 in equal-tempered steps
with **note 48 = 11 025 Hz, 60 = 22 050, 72 = 44 100**. Entries 0–23 are the dummy `{10,10,10}`
and 84–95 repeat 88 200 Hz.

Two samples (`mcSmpInstTable`), 8-bit signed PCM recorded at 11 025 Hz:

| | Address | Bytes | Used by |
|---|---|---|---|
| sample 0 | `08016C10` | 5 688 (0.52 s) | song 15 ch 5, instrument 0, notes 39–69 |
| sample 1 | `08018248` | 9 088 (0.82 s) | song 15 ch 6, instrument 1, notes 35–58 |

At note-on: `frames = length / samplesPerFrame` (the one `__udivsi3` call). `mcUpdateSamples`
restarts the sample when `frames` reaches 1, so a held note becomes a loop of the sample,
**slightly truncated** (the last partial frame plus one frame is never played).

---

## 8. Channel engines

**Note-on (channels 1–4)** writes the envelope register first, then the frequency register with
the restart bit. For channel 1:

```
v  = inst.lo | inst.hi << 8
if (env)   { v = inst.lo | env[0] << 8; envIdx = 0; envTimer = env[1] }
if (owned) SOUND1CNT_H = v
if (arp)   { freq = Freq[note + arp[1]]; arpIdx = 0; arpTimer = arp[0] }
x  = inst.b0 << 8
x |= pitch ? (pitch[0] + 0x8000) : 0x8000;  pitchIdx = 0; pitchTimer = pitch[1]
if (owned) SOUND1CNT_X = x | freq
```

**Per-tick effects**, in the order arpeggio, then pitch, then envelope, each gated by its own
timer:

* arpeggio step: `freq = Freq[note + semis]` → frequency register, no restart
* pitch step: `freq += delta` → frequency register, no restart
* envelope step: envelope register `= value<<8 | lo`, then frequency register with restart

Channel 3 (wave) behaves the same, but the "envelope" is the 2-bit wave volume code.

Channel 4 (noise) has **no arpeggio** and **no `0xFE` loop support** in either of its tables
(§10.3). The note number is ignored because its pitch comes only from the noise-parameter table.
If an instrument has no noise table, `SOUND4CNT_H` is never written at note-on, so there is no
restart.

Channels 5/6 have no effects. A note-on computes the loop length, stops the DMA and timer, points
DMA at the sample, and starts the timer at the note's rate. The `owned` flag is not checked.

---

## 9. Sound effects

### 9.1 In the driver (all unused in E.T.)

**PSG register scripts** (`mcPlayPsgSfx`). An effect maps to up to four scripts. A script's first
halfword is its channel. After that come records `{frames, v1lo, v1hi, v2hi, v2lo}`: after
`frames` frames the driver writes `v1` to the envelope/duty register and `v2` to the
frequency/control register. `0xFF` or `0xFE, 0xFD` ends the script (the registers are zeroed and
the music channel gets `owned = 1` back). `0xFE, n` loops to halfword *n*. The ghost-channel idea
is simple: while `owned == 0` the music keeps sequencing but writes nothing, so it resumes in time
when the effect ends. The 12 scripts in the ROM include rising and falling square sweeps (scripts
6/7 form a two-channel arpeggio jingle, 9–11 a three-channel fanfare) and a noise burst. Effect 0
silences all four channels.

**DirectSound one-shots/loops** (`mcDsSfxStart`, two slots, fixed 11.27 kHz timer) and the
**stream player** (`mcStreamStart`, which re-points DMA every frame to `base + offset` and advances
by a per-frame step). Both read `mcDsSfxTable`, which is zero-filled. These look like features of
the driver kept for other games *(inferred)*.

### 9.2 Module B: WAV SFX player (what E.T. actually uses)

```c
struct SfxEntry { u8 priority; u8 pan; u16 pitch; const u8 *wav; };   // SfxTable[94]
struct {                                  // gSfx @ 03002CB0
    u8  prioA, prioB;                     // playing priorities (0 = channel free)
    u8  reqPrioA, reqPrioB;               // requests latched this frame
    u16 idA, idB;                         // playing effect ids
    u16 reqIdA, reqIdB;
    s32 ticksA, ticksB;                   // remaining length, 16 384 Hz ticks
} gSfx;
```

* `PlaySfx(n)` only **latches** a request. There are two request slots per frame, and a
  higher-priority request replaces a lower one. It does nothing if `gGame.sfxOff` (+0x15) is set or
  `gGame.curSong == 15`. `PlaySfxUnique(n)` additionally skips effects already playing.
* `SfxVBlank()` starts the latched requests through `SfxStartWav` and stores the id in the returned
  slot.
* `SfxStartWav(wav, pitch, pan, prio)` works as follows:
  * **Channel steal**: the lower-priority busy channel is freed if the new priority is ≥ its
    priority. If neither channel ends up free, it returns a dummy halfword and the effect is lost.
  * **Pan** (0 both, 1 left, 2 right) goes into `SOUNDCNT_H`'s DS enable bits. All 94 entries use 0.
  * The DMA source is `wav + 0x2C`: it **assumes a canonical 44-byte WAV header** and reads the
    sample rate from `+0x18` and the data size from `+0x28`.
  * `rate = sampleRate × pitch / 256`, `period = 2²⁴ / rate`, `ticks = dataSize × 15 800 / (2²⁴/period)`.
  * Timer 2 (A) or Timer 3 (B) counts `ticks` at the 1/1024 prescaler (16 384 Hz) in chunks of
    65 536, and its IRQ stops the channel. The timer value is written as `0xC40000 − ticks`: the
    borrow turns the control byte into `0xC3` (enable | IRQ | ÷1024) and leaves `0x10000 − ticks`
    in the reload field.
* `SfxInit()` sets `SOUNDBIAS` and the final `SOUNDCNT_H = 0x7301`.
* `PlayMusic(song)` records `gGame.curSong` (+0x13) and calls `mcPlaySong` unless `gGame.musicOff`
  (+0x14) is set. `StopMusic()` stops DMA1/DMA2 if the current song is 15, then plays song 0.
  *(The field names are inferred from use.)*

The SFX priorities range from 1 to 240. Pitch factors of 128, 384, 512 and 768 are used to get
extra effects out of the same WAV (for example SFX 5 and 6 are the same file at ×1 and ×3).

---

## 10. Bugs, quirks and dead code

**1. DirectSound music channels are never stopped by the driver.** A rest on channel 5/6 is
simply not triggered, and `mcUpdateSamples` keeps re-starting the last sample for as long as the
song runs. When a different song starts, `seqPtr` for channels 5/6 becomes 0, so the re-trigger
stops. But the FIFO DMA is in **repeat mode and keeps running**, reading on through sample 1, the
zero table and then the pattern data as audio. The game works around this in `StopMusic`, which
kills DMA1/DMA2 by hand when leaving song 15, and in `PlaySfx`, which refuses effects during song
15 because they would fight over the same DMA channels. 30 of the game's 38 `PlayMusic` call
sites come straight after a `StopMusic` call. This analysis did not trace whether any of the other
eight can run while song 15 is playing. In any host without this glue the glitch would be
audible.

**2. Effects run at tempo rate.** Envelope, vibrato and arpeggio timers count sequencer ticks, not
frames (§5), so the same instrument decays faster in a fast song. This is inherited from the GB
driver, which also skips all channel processing on frames without a tempo carry, so it is by
design rather than a porting error. The tempo can also never exceed one tick per frame: the accumulator overflows at most
once per frame, and a tempo above 0x100 just makes it grow.

**3. The noise channel ignores `0xFE` loop markers.** Instrument 6's noise table ends
`… 35/1 70/1 0xFE 0`. Channel 4's walker only knows `0xFF`, so it writes **`0xFE` into
`SOUND4CNT_H`** (the slowest 7-bit noise) with a timer of 0, which then wraps to 2³²−1 and holds.
It is barely audible, because instrument 6's envelope has already decayed to 1/15 by that tick.

**4. The first pitch-table value is ORed, not added.** At note-on the register gets
`freq | (pitch[0] + 0x8000)`, and `chan.freq` is not updated. With the common vibrato table
(`+1, −1, −1, +1`) the vibrato is therefore centred one unit flat, and the note-on pitch can be
off by one unit when `freq` is even.

**5. Rests on PSG channels are ordinary notes.** A rest keys note 0x30 with the event's
instrument, so it is silent only because every rest in the data uses instrument 0.

**6. One wrong note.** Song 2, channel 2, pattern `0x0802435E` at byte `0x08024397` has note
byte `0` inside a melody around note 72, with transpose −41. The wrapped index 215 reads
`FreqLo`/`FreqHi` 118 bytes past their end, inside the song table, and yields register `0x1400`:
a **128 Hz blip** where about 415 Hz was intended. It is almost certainly a data-entry slip (a
missing note number).

**7. Loop truncation on sample channels.** `frames = length / samplesPerFrame` rounds down and
the restart happens at 1 frame left. The looped sample loses up to about two frames of its tail
(§7.8).

**8. `mcPlaySong` forces `owned = 1`.** Starting a song while a PSG SFX runs would hand the
channel back to the music mid-effect. This does not matter in E.T.

**9. DS SFX slot 1 stops its timer by writing `TM1CNT = 1`** (slot 0 writes 0). This is harmless
because the enable bit is clear, but it is inconsistent.

**10. Module B edge cases.** A remaining length of exactly 0x10000 ticks makes `0xC40000 − t`
produce control byte `0xC4`, which is **cascade mode**, so Timer 2/3 would count Timer 1/2
overflows instead of ÷1024 ticks. Long effects re-arm with reload 2 (65 534 ticks) but subtract
65 536. The `15 800` constant instead of 16 384 ends every effect about 3.6 % early, probably a
deliberate safety margin against reading past the data *(inferred)*.

**11. Song 1 loses its percussion after one pass.** Channel 4's sequence is `SEQ_PAT pat_080242AC ×8,
SEQ_END, SEQ_JUMP 0`. The `SEQ_END` comes before the jump, so the noise channel plays its
4 608-tick pass once and then stays silent, while channels 1–3 loop the same 4 608 ticks forever.
The unreachable `SEQ_JUMP 0` shows the loop was intended. Every other song's channels loop in
step (all channels of each song were checked to have identical loop lengths).

**12. Dead state and code.** Sequence command `0x60`, the driver side of `0x66` (`mcCondFlag` is written but never read; see §7.2), `mcStreamParam`,
the `…On` words in every instrument, the PSG SFX, DS SFX and stream players, `mcPause` and
`mcResume` are all dead, as are 12 bytes at `0x03000034` and 8 bytes at `0x03000098`. See also
§10.11.

**13. No bounds checks** on song, instrument, pattern, length or note indices. `durTable1` has
only 18 entries, and song 1's maximum length index is exactly 17.

---

## 11. Content inventory

| | |
|---|---|
| Songs | 16: 0 = silence, 14 = one-shot jingle, 15 = six-channel song with samples (started first by `main`), the rest loop on 4 PSG channels |
| Tempos | 154–255 (0.60–1.0 ticks/frame) |
| Loop lengths (ch 1) | ~31 s to ~193 s |
| Sequences / patterns / events | 66 / 210 / 13 936 |
| Instruments | 31 (0 = silent; 1–6 noise; 7–10, 13, 15–30 square; 11, 12, 14 wave) |
| Modulation tables | 17 envelope, 7 pitch/noise, 9 arpeggio |
| Music samples | 2 (14 776 bytes PCM) |
| WAV sound effects | 94 table entries, 66 distinct RIFF files, 8-bit mono 11 025 Hz |
| Unused | 12 PSG SFX scripts (5 effects), empty 90-entry DS SFX table, 4 null script pointers |

Per-channel instrument use: the noise channel uses only instruments 1–6. The wave channel uses 11,
12 and 14. The two square channels share the rest, and channel 1 mostly carries lead instruments
16 and 17 (the arpeggio and octave-warble instruments).

---

## 12. Notes for reimplementation or tooling

* **To play the music** you need: the 8.8 tempo gate, the sequence command loop, 3-byte pattern
  events, the note-length table, three table walkers per PSG channel (arpeggio → pitch →
  envelope, with the arpeggio pair order swapped), and the frequency table. Treat envelope-table
  values as literal NRx2 bytes followed by a trigger.
* **To convert to MIDI or a tracker**, one tick is `256/tempo` frames. The `durTable0` ladder puts
  a quarter note at 12 ticks, so song 1 at tempo 205 is ≈ 59.7275 × 60 × (205/256) / 12 ≈
  **239 BPM** in 12-tick quarters, or half that if you read 24 ticks as the beat *(inferred)*.
* **To port the driver**, stop DMA1/DMA2 in `mcPlaySong` (§10.1), make the noise walker honour
  `0xFE` (§10.3), and add the first pitch delta properly (§10.4).
* **Porting heritage**: see §1a. Cooksey's GBA driver keeps the GB data model almost unchanged,
  so converters written for the GB/GBC format should need only the widened field sizes and the
  split into sequence and pattern levels.
* **Contrast with QuickThunder**: QuickThunder is hand-written assembly with a byte-code
  `{len, note, ins}` stream, "combine" pitch modes and SFX that steal channels through a ghost
  stepper. Cooksey's driver is compiled C with 32-bit order lists, 3-byte `{note, ins, len}`
  events with a length table, and tick-driven envelope, pitch and arpeggio tables. Its PSG SFX use
  the same "keep sequencing silently" idea (the `owned` flag), but E.T. never uses them and plays
  WAV files instead.

---

## Appendix A: function map

```
module A  080025EC mcSoundInit      0800270C mcDsSfxStart    08002794 mcPlaySong
          080028B8 mcPlayPsgSfx     08002940 mcPause         0800299C mcResume
          080029A8 mcDsSfxStop      08002A24 mcStreamStart   08002A60 mcStreamStop
          08002A90 mcStreamSetParam 08002A9C mcUpdateSamples 08002CC4 mcUpdate (-> 08003CE4)
            far-branch targets inside mcUpdate: 08002FB6 seqChanLoop, 08002FF6 seqChanRetry,
            08003C84 seqNextChan, 08003C90 exit
module B  08004944 PlayMusic        08004964 StopMusic       080049A8 PlaySfxUnique
          080049D4 PlaySfx          08004A2C SfxVBlank       08004A8C SfxTimer2IRQ
          08004B08 SfxTimer3IRQ     08004B84 SfxInit         08004BB8 SfxStartWav
```

## Appendix B: deliverables

| File | Contents |
|---|---|
| `et_musicdrv.s` | labelled, commented Thumb source of module A |
| `et_sfxwav.s` | labelled, commented Thumb source of module B |
| `et_sound_data.s` | the whole music data blob as macros and directives (sequences, patterns, instruments, tables) plus the SFX table |
| `et_music_samples.bin` | the two PCM samples (pulled in with `.incbin`) |
| `et_sound.ld`, `et_sound_data.ld`, `et_sound.mk` (makefile: `make -f et_sound.mk`) | link at the original addresses |
| `et_sound_data_dump.txt` | human-readable decode of every song, sequence, instrument, table and SFX |
| `et_music_sample0.wav`, `et_music_sample1.wav` | the two music samples as WAV |

`make -f et_sound.mk` with `arm-none-eabi-as/ld/objcopy` (`-mcpu=arm7tdmi -mthumb`) rebuilds all four ROM ranges
(`080025EC–08003CE8`, `08004944–08004DBC`, `08016790–08027AF0`, `080284FC–080287EC`). Each one
has been checked to be **byte-identical** to the ROM.
