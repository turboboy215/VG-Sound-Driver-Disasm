# Lenar Sound Driver — Mercenary Force / Knight Quest

Disassembly and documentation of the sound driver Lenar used in two Game Boy games:

| Game | ROM | Mapper | Driver bank |
|---|---|---|---|
| Mercenary Force (UE) [!] | 128 KB | MBC1 | 3 |
| Knight Quest (U) | 128 KB | MBC1 | 3 |

Both games use the **same driver code at the same addresses** ($7AE0–$7CF6 in bank 3). The only code differences are cosmetic: Mercenary Force writes `xor a` where Knight Quest writes `ld a,$00` (so everything from $7BC5 on moves down by up to 3 bytes), and the three driver variables live at different RAM addresses. The pointer table, wave table and frequency table sit at the same fixed addresses in both ROMs.

> **Lineage:** this is Lenar's copy of the Irem/Tamtex GB sound driver. The closest version to the original is in Shisensho: Match-Mania (Irem/Tamtex, 1990), which matches Mercenary Force's driver to within 6 of 338 instructions. Lenar changed the interface: transpose is subtracted instead of added, the idle request value is 0 instead of `$FF`, the driver variables moved to game RAM, `$8A` gained an NR51 shadow byte, and the update is called from the main loop instead of VBlank. Irem's own line continued as Kid Niki → Hammerin' Harry "Ver 6.04". See `Irem_SoundEngine_Family.md`.

It is a small driver (about 530 bytes of code). It is built like a tracker: each track is a stream of fixed-length rows, and every note row retriggers the channel. There are no software envelopes, vibrato, portamento or volume slides. All timbre comes from hardware registers that the data sets directly.

---

## 1. Memory map (bank 3)

| Region | Knight Quest | Mercenary Force | Contents |
|---|---|---|---|
| Per-frame update routine | $7F90–$7FD7 | $4000–$4046 | `SoundUpdate` |
| Music/SFX data | $402C–$5238 | $4047–$5071 | track streams |
| Driver code | $7AE0–$7CF6 | $7AE0–$7CF2 | |
| Command jump table | $7C0B (15 words) | $7C0A (15 words) | inside the code |
| Filler | $7CF7–$7CFF (9 junk bytes) | $7CF3–$7CFF ($FF) | |
| `SndTable` | $7D00–$7DFF (32 ids) | $7D00–$7DCF (26 ids) + null track $7DD0 | 4 track pointers per id |
| `SndWaveTable` | $7E00–$7E4F | $7E00–$7E4F | 5 × 16-byte waves (identical) |
| `SndFreqTable` | $7F00–$7F8F | $7F00–$7F8F | 72 frequency words (identical) |

The driver hard-codes the high bytes $7D, $7E and $7F for the three tables. Any port has to keep those tables page-aligned.

In Knight Quest, $7E50–$7EF2 (between the wave table and the frequency table) and $7700–$7ADF are **game code**, not part of the driver. Bank 3 $4000–$402B in KQ holds a `jp $7F90` followed by the game's script-pointer table.

---

## 2. Interface

The game requests a sound by writing a `SndTable` id to one of two request bytes. The update routine starts the sound on its next call and clears the request byte.

| | Knight Quest | Mercenary Force |
|---|---|---|
| SFX request → SFX set ($DF00) | **$DF1E** | **$DF0E** |
| Music request → music set ($DF40) | **$DF0E** | **$DF1E** |
| `wSndChanOfs` (current track offset) | $C005 | $C116 |
| `wSndSetFlag` (0 = SFX set, 1 = music set) | $C006 | $C117 |
| `wSndNR51` (shadow of last `$8A` value) | $C400 | $C141 |

The two games swap the meaning of $DF0E and $DF1E. Both bytes are the otherwise unused +$0E byte of SFX tracks 0 and 1.

Music and SFX share one id space (`SndTable`). Any id can be started in either set; what makes something an "SFX" is only which request byte the game writes. The id is shifted left 3 times in 8 bits, so ids wrap modulo 32.

`SoundUpdate` is called once per frame from the main loop with bank 3 mapped (KQ via `$0827`, MF via `$087E` in bank 0). Under PyBoy, both games make exactly one call per frame in normal play, with occasional catch-up calls during lag. Mercenary Force also uses $C116/$C117 as temporaries in game code outside the driver.

### SoundUpdate

```
1. Snd_StartRequest(SFX request,   $DF00)
   Snd_StartRequest(music request, $DF40)
2. wSndSetFlag = 0 : update tracks $DF00, $DF10, $DF20, $DF30
   wSndSetFlag = 1 : update tracks $DF40, $DF50, $DF60, $DF70
3. SndOut_Ch1 (b=$00), SndOut_Ch2 (b=$10), SndOut_Ch3 (b=$20), SndOut_Ch4 (b=$30)
```

---

## 3. Track RAM

There are two sets of four tracks, each track $10 bytes. Track *n* of a set always drives hardware channel *n*+1.

| Offset | Meaning |
|---|---|
| +0 | row length in frames (0 = track idle) |
| +1 | frame counter |
| +2/+3 | data pointer |
| +4/+5 | return pointer (`$85` call) |
| +6 | call flag (1 = inside a call) |
| +7 | NR10 sweep (`$81`; ch1 only) |
| +8 | NRx1: duty/length (ch1/2), NR31 length (ch3) (`$80`) |
| +9 | NRx2: envelope (ch1/2/4), NR32 output level (ch3) (`$83`) |
| +A | current note / row byte |
| +B | transpose, **subtracted** from the note (`$82`) |
| +C..+F | unused (+E of SFX tracks 0/1 = request bytes) |

`Snd_StartRequest` sets, for all four tracks of the set: length = 1, counter = 0, pointer = `SndTable[id][n]`, call flag = 0. Every other field keeps its old value. Starting a sound therefore restarts **all four** tracks of that set. Starting any SFX cancels all running SFX, and starting music restarts all music tracks. Unused channels point to a shared one-byte `$87` track, which ends on the first frame.

---

## 4. Sequencing

Each frame, for each active track: counter += 1. When counter == length, the counter resets to 0 and events are read until a row byte is found:

| Byte | Meaning |
|---|---|
| `$00–$7F` | **note row**. Stored in +A; the channel is retriggered this frame |
| `$80–$8E` | command (table below); reading continues |
| `$8F` | **invalid**: the 15-entry jump table has no 16th entry, so the pointer is read from the first code bytes after the table ($030A) and the game crashes |
| `$90–$FF` | set row length = byte − $90 (0–111 frames); reading continues. `$90` (length 0) makes the track idle |

Because the counter is compared after the increment, a row lasts exactly *length* frames. The length stays in force until the next `$9x`.

### Commands

| Cmd | Args | Macro | Effect |
|---|---|---|---|
| `$80` | xx | `snd_duty` | +8 = xx → NR11/NR21 (duty \| length), NR31 (ch3 length) |
| `$81` | xx | `snd_sweep` | +7 = xx → NR10 (only ch1's output reads it) |
| `$82` | xx | `snd_transpose` | +B = xx; freq index = (note − xx). Positive values lower the pitch |
| `$83` | xx | `snd_env` | +9 = xx → NR12/NR22/NR42 envelope, NR32 level |
| `$84` | xx | `snd_unused84` | parameter skipped, no effect |
| `$85` | lo hi | `snd_call` | save pointer after the operand at +4/+5, set +6 = 1, jump. **One level only** |
| `$86` | – | `snd_ret` / `snd_endsong` | if +6 = 1: clear it and return. Otherwise **end of song**: zero the length byte of all 4 tracks of the set being processed (chosen by `wSndSetFlag`) |
| `$87` | – | `snd_end` | end this track only (length = 0) |
| `$88` | xx | `snd_unused88` | parameter skipped, no effect |
| `$89` | – | `snd_hold` | a row whose note byte is $89: the output routine skips it, so nothing is written and the previous note keeps ringing or decaying. This is the driver's only "rest"; a true silence needs an envelope of 0 or `$87` |
| `$8A` | xx | `snd_pan` | NR51 = xx immediately (global), copy to `wSndNR51` |
| `$8B` | lo hi | `snd_jump` | jump (loops) |
| `$8C` | xx | `snd_wave` | NR30 = 0, copy 16 bytes from `SndWaveTable + xx` to $FF30 |
| `$8D` | xx | `snd_unused8d` | parameter skipped, no effect |
| `$8E` | xx | `snd_mastervol` | NR50 = xx immediately (global) |

`$84`, `$88` and `$8D` share one handler that reads and discards the parameter. Neither game's data uses them. Neither game uses `$8E` either, and `$81` appears only once (`$81 $00` in id $01).

---

## 5. Output (hardware writes)

For each hardware channel, `SndOut_SelectSource` picks the source track:

1. If the SFX track's length ≠ 0, use it. Otherwise use the music track; if that is idle too, write nothing.
2. Write registers **only if the chosen track's counter == 0**, i.e. on the frame a new row started, and only if the row byte ≠ $89.

So each note row is a single register write plus trigger. Nothing is written between rows. When an SFX ends, the music on that channel comes back at its next row. Music keeps advancing silently while an SFX covers it.

| Channel | Writes on a new row |
|---|---|
| ch1 | +7→NR10, +8→NR11, +9→NR12, freq lo→NR13, freq hi\|$80→NR14 |
| ch2 | +8→NR21, +9→NR22, freq lo→NR23, freq hi\|$80→NR24 |
| ch3 | (NR30=$80 **every frame**), +8→NR31, +9→NR32, freq lo→NR33, freq hi\|**$C0**→NR34 (length counter enabled, so the NR31 value from `$80` sets the note's maximum length) |
| ch4 | +9→NR42, **note byte raw**→NR43, $80→NR44 |

The frequency index is `(note − transpose) × 2` into `SndFreqTable`, computed in 8 bits. `SndFreqTable` has 72 entries: index 0 = C2 (65.4 Hz on ch1/2, an octave lower on ch3) up to B7. Indexes ≥ 72 read past the table (in KQ into `SoundUpdate`'s code, in MF into $FF padding). Knight Quest's id $01 deliberately plays note $53 on ch2 with envelope 0 as a "silence" row.

On ch4 the note byte is the NR43 value itself (clock shift / width / divisor), so ch4 values are limited to $00–$7F.

`SndOut_Ch1` loads `h = $DF`; ch2–ch4 rely on `h` still being $DF.

### Wave table (both games)

| `$8C` arg | Bytes |
|---|---|
| $00 | `01 23 45 67 89 AB CD EF FE DC BA 98 76 54 32 10` (triangle) |
| $10 | `00 11 22 33 44 55 66 77 88 99 AA BB CC DD EE FF` (saw), **the only wave used by either game** |
| $20 | `00 21 42 63 84 A5 C6 E7 08 29 4A 6B 8C AD CE EF` |
| $30 | `04 08 0C 0F 0C 08 04 00 00 …` |
| $40 | `02 46 8A CE FF FF FF FF ED CB A9 87 65 43 21 00` |

---

## 6. Sound tables

"Seen as" lists the request byte each id is written to as an immediate (`ld a,$xx / ld [$DFxE],a`) in the game code. Ids loaded indirectly from tables don't appear.

### Knight Quest (32 ids, null track = $402D)

| Id | Channels | Type | Seen as |
|---|---|---|---|
| $00 | 1234 | same pointers as $01 | – |
| $01 | 1234 | one-shot "silence/init" | music |
| $02–$0B | 1234 | looping music | $0B music |
| $0C | 1234 | one-shot | – |
| $0D–$0F | 1234 | looping music | $0D, $0F music |
| $10, $11, $14, $18 | 12-- | SFX | SFX ($10, $14 also music) |
| $12 | -2-- | SFX | SFX |
| $13 | 1--- | SFX | SFX |
| $15, $16, $17, $19 | ---4 | noise SFX | SFX |
| $1A, $1B, $1D, $1F | 1234 | looping music | – |
| $1C, $1E | 1234 | one-shot jingles | music |

KQ also has **13 unreferenced streams** in the data area ($402C, $4045–$40E1 ×9, $4144–$415E ×3), which look like left-over or cut SFX. They are disassembled as `SndUnused_xxxx`.

### Mercenary Force (26 ids, null track = $7DD1)

| Id | Channels | Type | Seen as |
|---|---|---|---|
| $00 | – | all four point to the null track | – |
| $01 | 1234 | one-shot "silence/init" (same data as KQ $01) | – |
| $02–$0A | 123- | looping music | $04, $08, $09 music |
| $0B–$10 | -2-- | SFX on ch2 | $0B–$0E SFX |
| $11 | 12-- | looping SFX | SFX |
| $12–$14, $17–$19 | 123- | looping music | music |
| $15, $16 | 123- | one-shot jingles | music |

In Mercenary Force, ch4 of every music id points to the ch4 init stub of id $01 at $4057 (silent noise row, then `$87`), and no SFX uses ch4, so **the game never plays the noise channel**. MF has one unreferenced stream at $463E.

---

## 7. Quirks and edge cases

- **`$8F` crashes** (no jump-table entry).
- **Length `$90`** (0 frames) silences the track permanently, because a length byte of 0 means "idle".
- **One-level calls**: a nested `$85` overwrites the return address. A `$86` with no call pending is "end of song" for the **whole set**, not just the track.
- **`$8A` / `$8E` are global**: an SFX that changes NR51 or NR50 leaves the value in place for the music afterwards. The driver never restores it, and `wSndNR51` is only a shadow copy for the game.
- **`$8C` wave load** sets NR30 = 0. Ch3 output sets NR30 = $80 again on the next frame, whatever track is playing.
- **Transpose is subtracted** and stays in force after `snd_ret`. Music commonly uses `$82 $04`, i.e. everything sounds 4 semitones below the written value.
- Starting a sound restarts all four tracks of its set (see §3).
- KQ id $00 is a copy of id $01. Since id 0 means "no request", it can never be started.

---

## 8. Files

In `GBAudioLab\Lenar\`:

| File | Contents |
|---|---|
| `KnightQuest_sound.asm` | full disassembly: driver code, `SoundUpdate`, tables, all track data (incl. unused streams) |
| `MercenaryForce_sound.asm` | same for Mercenary Force |
| `lenar_sound.inc` | command macros (`snd_*`) and note constants `C_2`…`B_7` |
| `hardware.inc` | register names |

Both `.asm` files assemble byte-identical with RGBDS 1.0 to the matching regions of the original ROMs:

```
rgbasm -o kq.o KnightQuest_sound.asm
rgblink -p 0xFF -o kq.gb kq.o      ; compare bank 3 sections with the ROM
```

The check covered 5,717 bytes (KQ) and 5,234 bytes (MF) with 0 mismatches. In the data, note names are the raw stored values, before transpose. Ch4 and unused streams use hex, because their bytes are raw NR43 values or come from an unknown channel.
