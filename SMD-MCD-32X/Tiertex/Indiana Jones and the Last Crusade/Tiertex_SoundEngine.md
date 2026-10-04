# Tiertex Mega Drive Sound Engine (Donald Campbell)

Games covered: **Indiana Jones and the Last Crusade (JE)** (`TT/Indiana Jones and the Last Crusade (JE) [c][!].bin`) and **Strider II (E)** (`TT/Strider II (E) [x].bin`).

The two games run the same engine. Strider II has a later revision of it: the Z80 driver gains a portamento command (F3), SFX 1 gets a volume patch, the voice bank can have any size, and the game adds a 68k speech player with Huffman-packed samples.

Files that go with this document:

| File | Contents |
|---|---|
| `IndyJones_Z80_driver.asm`, `Strider2_Z80_driver.asm` | Labelled, commented Z80 driver disassemblies (z80dasm syntax) |
| `IndyJones_68k_sound.asm`, `Strider2_68k_sound.asm` | Labelled 68000 sound API, VBlank cue hook and, for Strider II, the speech loader and both Huffman unpackers |
| `IndyJones_SoundData.txt`, `Strider2_SoundData.txt` | Every song, called block, SFX and voice bank decoded to command level, plus the DAC/speech tables |
| `samples/…wav` | Every DAC sample and every decompressed speech sample, rendered at the PAL playback rate |
| `tools/tiertex.py` (+ helpers) | Python ripper/parser that produced the data dumps and WAVs; `python3 tiertex.py rom.bin ij|s2 outdir` |

---

## 1. Architecture

* The Z80 does everything at run time: it sequences 6 FM channels, plays one DAC sample on FM6, and runs off YM2612 timers. It uses no interrupts, and the **PSG is not used at all**.
  * **Timer B = $DD** is the sequencer tick: 53267/(16·35) = **95.1 Hz NTSC** / 52781/560 = **94.3 Hz PAL**.
  * **Timer A** is the DAC sample clock. Its value is chosen for each sample.
  * The main loop polls the timer flags, and Timer B wins if both are set. While the channels are being updated, `UpdateTrack` also polls Timer A before each track so the DAC keeps running.
* The 68k only uploads data and writes requests into Z80 RAM, with the bus held:
  * A song is started by copying every track of the song into Z80 RAM at $0E00, writing each track's start pointer and setting its start flag.
  * An SFX is copied (256 bytes) into a per-channel slot at $1B00–$1E00.
  * A DAC SFX is started by filling in the sample descriptor at $09F6–$09FE.
* Song data is **position-independent**: the only branch command (F9) uses a relative offset, and the FC/FF commands use addresses captured at run time.

### Z80 memory map

| Z80 addr | Use |
|---|---|
| $0000–$0615 (Indy) / $0000–$073B (Strider II) | Driver code |
| $0800–$091F | Music track RAM FM1–FM6 ($30 bytes each: $0800, $0830, $0860, $0890, $08C0, $08F0) |
| $0920–$09DF | SFX track RAM FM3–FM6 ($0920, $0950, $0980, $09B0) |
| $09E0/$09E2 | Saved DAC length / HL across a tick |
| $09E4 | DAC half volume (68k sets it to 1 while music is playing) |
| $09ED | DAC finished, so FM6 needs its voice back |
| $09EE / $09EF | Paused (this tick) / paused on the previous tick |
| $09F0 | DAC active |
| $09F1 | Pause request from the 68k ($FF = pause, 0 = run) |
| $09F6 (w) | Timer A value for the sample (low byte = 2 LSBs → reg $25, high byte = 8 MSBs → reg $24) |
| $09F8 (w) | Sample address in the bank window ($8000 + (addr & $7FFF)) |
| $09FA (w) | Sample length |
| $09FC (w) | **Sample trigger** = 9-bit bank (addr >> 15). Non-zero starts the sample on the next tick; the driver clears it. |
| $09FE (w) | Loop bank: when the sample ends, it restarts from this bank if non-zero. The 68k always clears it, so looping is never active in either game. |
| $0A00–$0DDF | Voice bank (31 voices × 32 bytes) |
| $0E00–$1AFF | Song track data (largest song ends at $1A5A in Indy and $1835 in Strider II) |
| $1B00/$1C00/$1D00/$1E00 | SFX data slots for FM3/FM4/FM5/FM6 (256 bytes each) |
| $1F00–$1FC1 | Frequency table, built at boot. It doubles as a dummy YM port: channel writes go to $1F00/$1F01 while a channel is muted. |
| $2000 | Stack top |

### Track RAM structure ($30 bytes; IX in the driver)

| Off | Meaning |
|---|---|
| +00/01 | Sequence pointer (0 = track inactive) |
| +02/03 | Delay counter (ticks until the next event, 16-bit) |
| +04 | Active voice transpose (from the keysplit) |
| +05/06 | Track start pointer (written by the 68k; used by FF) |
| +07 | Start request: when the 68k writes 1, the driver keys off, sets ptr = start and clears +02…+2F except +05/06 and +11/12 |
| +08 | Keysplit note (0 = keysplit off) |
| +09 | Current keysplit side (0 = low, 1 = high) |
| +0A/+0B | Low-side voice / transpose |
| +0C/+0D | High-side voice / transpose |
| +0E, +0F/10 | FC/FD loop counter and loop address |
| +11/12 | Frequency base (EF). If non-zero, notes are raw F-number offsets instead of table lookups |
| +13/14 | Duration fraction accumulator |
| +15/16 | Duration fraction increment (F7/FB) |
| +17/18 | F9 return address |
| +19/1A | F9 target address |
| +1B | F9 repeat counter |
| +1C | F9 transpose |
| +1D | Fixed duration (F6); 0 = each note carries a duration byte |
| +1E | Last pan/AMS/FMS byte written |
| +1F/20 | Pointer to the current voice (used to reload it after an SFX, DAC or pause) |
| +21 | Legato flag (F5) |
| +22 | *(Strider II)* Glide: shift value from F3, then the remaining step count |
| +23/24 | *(Strider II)* Current F-number (11 bits) |
| +25/26 | *(Strider II)* Glide step per tick (signed) |
| +27 | *(Strider II)* Current block << 3 |

### Channel arbitration

FM1 and FM2 are music only. FM3–FM6 each have a music track and an SFX track.

* While an SFX is active on a channel, its music track keeps running, but all of the music's register writes go to the dummy port at $1F00.
* When the SFX ends, the driver keys off, reloads the music voice from +1F/20, and resumes the music on the next note.
* FM6 is also the DAC channel. While a sample plays (`DAC_Active`), FM6's FM writes are muted the same way. When the sample ends, the driver restores FM6 (SFX voice first, then music).

### Pause

The 68k writes $FF to $09F1. On every tick while paused, the driver loads a silent voice (TL=$7F), keys off, sets pan to 0 on every channel, and skips DAC output. After unpausing, each channel's voice is reloaded.

---

## 2. Sequence format

Tracks are byte streams. Each tick, a track with a delay of 0 reads events until it reaches a note or a rest, which sets a new delay.

### Notes

`nn [dd] [7F xx]…`, where `nn` = $00–$7F:

* **$00 is a rest** (key off). $01–$60 are notes; note 1 is C0 (F-num $28E, block 0) and each +12 is one block higher. The table covers notes 0–96.
* The note played = `nn` + F9 transpose (while inside an F9 block) + voice transpose (from the keysplit). If the result is 0, it is treated as a rest.
* **Duration** `dd` (1 byte) follows unless a fixed duration (F6) is active. Each following `7F xx` adds `xx` to the duration, so durations above 126 are written as `dd 7F xx 7F xx…`.
* When the duration fraction (F7/FB) is set, a 16-bit accumulator adds the increment on every note, and each carry adds 1 tick. This produces non-integer tempos and swing.
* **Key-on happens at every note, with no retrigger key-off**: the key-off comes automatically **one tick before** the next event, unless legato (F5) is on.
* The driver writes the frequency to $A4/$A0+ch and then key-on $F0|ch.

### Voice selection

| Byte | Params | Meaning |
|---|---|---|
| $80–$9E | – | Load voice n = byte & $1F from the voice bank (Z80 $0A00 + n·32). Cancels keysplit. |
| $9F | `sp vL tL vH tH` | **Keysplit**: notes below `sp` use voice `vL` with transpose `tL` (signed); notes ≥ `sp` use voice `vH` + `tH`. The voice is reloaded whenever the side changes. |
| $A0 | 32 bytes | **Inline voice**: a voice definition embedded in the track (used by most SFX). Cancels keysplit. |

### Commands

| Byte | Params | Meaning |
|---|---|---|
| $A1–$EE | – | No-op (1 byte) |
| $EF | `lo hi` | Frequency base. While non-zero, a note becomes `base + note` as a raw $A4:$A0 value, with no table lookup. Unused in both games; the 68k clears it when an SFX starts. |
| $F0–$F2 | – | No-op |
| $F3 | `n` | **Strider II only**: glide into the next note over 2ⁿ ticks. In Indy, F3 is a no-op. Not used by any Strider II data. |
| $F4 | – | **Cue to 68k**: switches the Z80 bank to $1FF and writes 1 to $FFFF, which sets 68k byte `$FFFFFF` = 1. The VBlank handler then plays the next SFX from the song's cue list (§3.3). |
| $F5 | – | Toggle legato (no automatic key-off) |
| $F6 | `d` | Fixed duration: notes carry no duration byte while `d` ≠ 0 (`F6 00` switches this off) |
| $F7 | `lo hi` | Set the duration fraction increment |
| $F8 | – | End of a called block: decrement the F9 count; if non-zero, jump back to the block start, otherwise return |
| $F9 | `cnt tr offL offH` | **Call/repeat**: play the block at (address of `offL`) + offset (signed 16-bit LE) `cnt` times, adding transpose `tr` to its notes, then continue after the F9. **One level only.** This is the main pattern mechanism: most tracks are lists of F9 calls into shared blocks. |
| $FA | – | Clear the duration fraction (accumulator and increment) |
| $FB | `lo hi n` | $F7 `lo hi` followed by $FC `n` |
| $FC | `n` | Loop start, count `n` (one level) |
| $FD | – | Loop end: if --count ≠ 0, go to loop start |
| $FE | – | Stop the track: pointer = 0, pan = 0, key off |
| $FF | – | Jump back to the track start pointer (+05/06); this is how songs loop |

> The driver's jump table at Z80 $030D (Indy) / $03A2 (Strider II) is indexed by `cmd − $F0`. The parsers in `tools/tiertex.py` walk every track, follow every F9 target and account for every byte of each song. The only bytes they don't reach are small padding and one unused 657-byte phrase in Indy song $0A.

### Voice format (32 bytes, 30 used)

```
+00       $B0 FB/ALG
+01..+04  $30 DT/MUL    op1 op3 op2 op4   (register order $30,$34,$38,$3C)
+05..+08  $40 TL
+09..+0C  $50 RS/AR
+0D..+10  $60 AM/D1R
+11..+14  $70 D2R
+15..+18  $80 D1L/RR
+19..+1C  $90 SSG-EG
+1D       $B4 pan/AMS/FMS   (0 is written as $C0 = L+R)
+1E..+1F  padding
```

`WriteVoice` keys the channel off before writing. There are no volume or TL commands in the format, so volume lives only in the voices.

### Strider II glide (F3)

* When a note follows `F3 n`, the driver expresses the target F-number in the current block (±$244 per octave; the driver treats one octave as $244 F-number units) and computes `step = (target − current) >> n`. It then plays the *current* pitch.
* Each tick, `UT_Glide` adds the step, wraps the F-number into $28E–$4D1 (adjusting the block), and rewrites $A4/$A0 and the key-on.

---

## 3. 68k-side interface and tables

### 3.1 Routines

| Routine | Indiana Jones | Strider II |
|---|---|---|
| Z80_RequestBus | $F07E | $3278A |
| LoadSoundDriver (reset + copy driver, then run) | $F092 (driver $F0E2, $616 bytes; default voices $FEF8 → $0A00) | $3279E (driver $327D8, $73C bytes) |
| LoadDefaultVoices / LoadVoiceBank | $F6F8 | $32F14 (a1 = source, d7 = size − 1) |
| **PlayMusic** (d0.w = song; 0 = silence) | $F71E | $32F24 |
| **PlaySFX** (d0.w = id \| channel<<12) | $F838 (ids < $2B) | $33024 (ids < $40; ignored while `$FFC192` ≠ 0) |
| PlayDAC_68k (a4 = data, d1 = length, d3 = Hz) | $FA06 (unused) | $33226 (speech; START aborts) |
| WaitMusicEnd | – | $333B2 |
| PauseSound / ResumeSound | $FAEA / $FAF6 | $3345A / $33466 |
| LoadSpeech (d0 = speech number) | – | $39E8 |
| VBlank music-cue hook | $274 | $246 |

**PlayMusic**:

* Reads a 36-byte song entry: 6 longs (FM1–FM6 track pointers), then 6 words (track lengths).
* Copies each track into Z80 RAM starting at $0E00, one after another, writes the Z80 address to +05/06 and sets +07 = 1.
* A pointer of **0** means the 40-byte `SilentTrack` stub is copied instead (inline silent voice, rest, FF). A **negative** pointer means that channel is left alone.
* Sets `DAC_HalfVol` = 1 whenever the song is non-zero, then loads the song's voice bank.

**PlaySFX**:

* Bits 12–15 of d0 force a channel (3–6). With 0, the driver takes the first free channel in the order **FM6, FM4, FM3, FM5**; if none is free, the SFX is dropped.
* It copies 256 bytes into that channel's slot and sets the start flag.
* If the top byte of the SFX table entry is non-zero, it is a **DAC sample number** instead. The 68k then:
  * reads the length and rate from the DAC table;
  * writes the bank, address and length, plus `TA = $400 − ($CE2A / rate)`;
  * gives the FM6 SFX slot the silent track.
* **A negative length would mean a looped sample**, but `$09FE` is then cleared again, so no sample ever loops.
* In Strider II, SFX 1 ("Bubble Bubble") also gets op4's TL in its inline voice patched to `min($FFC194 + 2, $63)` (distance-based volume). The patch always goes to the FM5 slot.

### 3.2 Data tables

| Table | Indiana Jones | Strider II |
|---|---|---|
| Song table (36 bytes/song, song 0 = null) | $FB14, songs $01–$12 | $33480, songs $01–$12 |
| Voice bank per song | long table $16F5C (always $3E0 bytes) | in the song extension table $3372C (10 bytes/song from song 1: `cue.l, bank.l, size−1.w`) |
| Cue lists | flags $FDC0 (bytes) + pointers $FDD0 (longs); all flags are 0, so this is unused | cue pointer in $3372C; only song $07 has one, at $337E0: SFX $10 ("Strider"), $10, $09, then `$FFFF` |
| SFX table (long: `sample#<<24 \| ptr`) | $FE18, $2B entries | $337E8, $40 entries (names at ROM $2B72, 16 chars each) |
| DAC table (`len.w, Hz.w`, index 1-based) | $FEC4 | $338E8 |
| Default voice bank | $FEF8 | $3390C |
| Speech table (6 bytes: `ptr.l, Hz.w`) | – | $3AAA, 17 entries |

### 3.3 Music cues

The Z80 command **F4** sets `$FFFFFF`. On the next VBlank, if the song has a cue list, the 68k clears the flag and calls PlaySFX with the next word from the list, wrapping at `$FFFF`. Strider II song $07 uses this to trigger the "Strider!" voice sample and an explosion in sync with the music.

---

## 4. PCM samples and rates

The DAC table rates are nominal Hz. The real playback rate is set by Timer A:

```
TA        = 1024 − floor(52778 / rate)          (68k, both games)
real rate = FMclock/144 / (1024 − TA)            NTSC 53267/N   PAL 52781/N,  N = floor(52778/rate)
```

52778 is the PAL FM sample rate (7.6 MHz/144), so the code was tuned for PAL. The integer division is coarse; for example, 9500 Hz nominal gives N = 5, so the real rate is 10653/10556 Hz. The **real rates** below are what the hardware plays. The WAVs use the PAL rate.

* Samples are **8-bit unsigned** with $80 as center.
* While music is playing, the Z80 halves every sample (`DAC_HalfVol`), so they come out at half amplitude around $40.
* A sample must not cross a 32 KB bank boundary.

### Indiana Jones (all uncompressed; played by the Z80 through SFX)

| DAC# | ROM addr | Length | Nominal | Real NTSC / PAL | SFX id |
|---|---|---|---|---|---|
| 1 | $0E8000 | $1282 | 9500 | 10653 / 10556 | $06 |
| 3 | $0EB98C | $0FC5 | 7500 | 7610 / 7540 | $08 |
| 4 | $0EC951 | $0712 | 2000 | 2049 / 2030 | $09 |
| 6 | $0E9282 | $270A | 6800 | 7610 / 7540 | $17 |
| 8 | $0F0000 | $3071 | 6400 | 6658 / 6598 | $28 |
| 9 | $0F3071 | $3ADB | 6400 | 6658 / 6598 | $29 |
| 10 | $0ED063 | $0AC4 | 7400 | 7610 / 7540 | $15 |
| 11 | $0F6B0D | $11E1 | 7400 | 7610 / 7540 | $16 |
| 12 | $0EDB27 | $0A44 | 6400 | 6658 / 6598 | $24 |

* Entries 2 ($2000 @ 7500) and 7 ($11B7 @ 9000) are leftover table entries with no SFX pointing at them; the first three rows of the table are identical to Strider II's. Entry 5 is empty.
* Sample 9's length runs $3F bytes into sample 11.
* The sample data occupies $0E8000–$0EE56A and $0F0000–$0F7CED.

### Strider II – Z80 DAC samples (uncompressed)

| DAC# | ROM addr | Length | Nominal | Real NTSC / PAL | SFX |
|---|---|---|---|---|---|
| 1 | $0F9BA3 | $2000 | 7500 | 7610 / 7540 | $06 "Explode 1" |
| 2 | $0FD8A6 | $2000 | 7500 | 7610 / 7540 | $07 "Explode 2" |
| 3 | $0FBDE9 | $0FC5 | 7500 | 7610 / 7540 | $08 "Scream" |
| 4 | $0FCDAE | $0712 | 2000 | 2049 / 2030 | $09 "Explode 3" |
| 5 | $0FD4C0 | $03E6 | 4000 | 4097 / 4060 | $0A "Clang" |
| 6 | $0F8000 | $1BA3 | 7500 | 7610 / 7540 | $10 "Strider" (also speech $04) |
| 7 | $0FFA14 | $055D | 10000 | 10653 / 10556 | $1D "Strider Sword" |
| 8 | $0F6E3D | $0E01 | 7100 | 7610 / 7540 | $2E "Trooper Die" |

### Strider II – speech (mostly compressed)

`LoadSpeech` ($39E8) unpacks a speech sample into RAM at `$FF0000`. `PlayDAC_68k` then plays it from `$FF0002`, driven by the 68k with the Z80 held and polling Timer A (START aborts). Callers: the cutscene-script opcode at $1E842/$1E856 (speech number taken from the script), fixed calls for $10 ($1E87E, $20F3E), $06 ($20F96) and $07 ($20FEE, $27292), and the options-screen *Speech Test* ($2FBC), which can play any entry.

The pointer in each speech-table entry selects the decoding path:

* **0**: the rate word holds an SFX id instead, and the sample is copied raw from the DAC table (entry $04 = DAC #6).
* **bit 31 clear**: *byte Huffman* (`Huff_Unpack`, $BE70)
  * Header: tree bits at +0, leaf bytes at +$40, output count−1 at +$140 (long), data at +$148.
* **bit 31 set**: *nibble-interleaved Huffman* (`HuffN_Unpack`, $BFA6)
  * Same scheme, but every byte is assembled from the high nibbles of two 16-bit words (`(p)&$F0 | (p+2)>>4`, then p += 4).
  * The tree is at +0, leaves at +$100, the 32-bit count in 8 high nibbles at +$500, and data at +$520.
  * The low 12 bits of every word are not part of the stream.

Huffman details:

* **Tree**: recursive and LSB-first. Bit 0 = leaf: the next leaf byte is stored as word `$00xx`. Bit 1 = node: the word holds the negative offset to the right child, and the left child follows the node directly.
* **Data bits**: LSB-first, starting at the left child for bit 0.
* **After unpacking**: the first output word is the sample length N. The following N bytes are **deltas**: `acc += b; out = acc·4` (8-bit wrap). This amounts to about 6-bit DPCM.

| # | Packing | ROM addr | Packed span | Samples | Nominal | Real NTSC / PAL |
|---|---|---|---|---|---|---|
| $00 | nibble Huffman | $0A2908 | $9D8C | 17570 | 7500 | 7610 / 7540 |
| $01 | nibble Huffman | $07CFB4 | $7D5C | 13971 | 7500 | 7610 / 7540 |
| $02 | byte Huffman | $0DF206 | $1B89 | 11712 | 7500 | 7610 / 7540 |
| $03 | byte Huffman | $0E0D8E | $418A | 29977 | 7500 | 7610 / 7540 |
| $04 | raw (= DAC #6) | $0F8000 | – | 7075 | 7500 | 7610 / 7540 |
| $05 | nibble Huffman | $085106 | $BB9C | 20028 | 7500 | 7610 / 7540 |
| $06 | byte Huffman | $0E4F18 | $2E72 | 19926 | 7500 | 7610 / 7540 |
| $07 | byte Huffman | $0E7D8A | $1163 | 7480 | 7500 | 7610 / 7540 |
| $08 | byte Huffman | $0E8EEC | $24B7 | 16572 | 7500 | 7610 / 7540 |
| $09 | byte Huffman | $0EB3A4 | $1497 | 8617 | 7500 | 7610 / 7540 |
| $0A | byte Huffman | $0EC83C | $2592 | 15467 | 7500 | 7610 / 7540 |
| $0B | byte Huffman | $0EEDCE | $1CB0 | 12057 | 7500 | 7610 / 7540 |
| $0C | nibble Huffman | $09AEC2 | $7A3C | 16702 | 6600 | 7610 / 7540 |
| $0D | nibble Huffman | $09299C | $83D4 | 18382 | 6600 | 7610 / 7540 |
| $0E | byte Huffman | $0F53B2 | $13E9 | 10836 | 7600 | 8878 / 8797 |
| $0F | byte Huffman | $0F3CF0 | $16C2 | 11723 | 7600 | 8878 / 8797 |
| $10 | byte Huffman | $0F0A7E | $3271 | 20430 | 6400 | 6658 / 6598 |

In the speech-table rows above, "nominal" is the value from the table. Rows $0C/$0D (6600) and $0E/$0F (7600) show clearly how the integer Timer A formula moves the real rate away from the intended one.

---

## 5. Differences between the two builds

* **Z80 driver** ($616 → $73C bytes). Everything else is instruction-for-instruction identical after relocation:
  * The F3 glide command handler.
  * The per-tick glide in `UT_Glide`.
  * Glide set-up in the note path.
  * Track fields +22…+27.
* **Voice banks**: Indy always copies $3E0 bytes; Strider II gives each song its own size and a cue pointer (`SongExtTable`).
* **Cue lists**: disabled by the flag table in Indy; used by song $07 in Strider II.
* **Strider II additions**:
  * `$FFC192` SFX mute.
  * The SFX 1 volume patch.
  * `WaitMusicEnd`.
  * A 68k speech player that reads pads 1 and 2.
  * The Huffman + delta speech format.
* **Unused in both**: the $EF frequency base, sample looping, and PlayDAC_68k in Indy. The shared DAC table rows show Indy's table was built from the same template as Strider II's.
