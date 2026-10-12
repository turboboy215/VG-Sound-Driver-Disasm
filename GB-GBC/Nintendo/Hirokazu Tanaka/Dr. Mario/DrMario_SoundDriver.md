# Dr. Mario (GB): sound driver
 
This is Hirokazu Tanaka's driver as used in *Dr. Mario* (`Dr. Mario (W) (V1.0) [!].gb`, 32 KB, no MBC). The whole sound region, bank 1 `$6000–$7FFF`, rebuilds **byte-exact** with RGBDS 0.9.1 (`-Wall` clean) from the sources in `Nint1\DrMario`.
 
| Range | Content | File |
|---|---|---|
| `$6000–$6A9E` | SFX tables, song table, driver code, SFX data | `DrM_Driver.inc` |
| `$6A9F–$6CA7` | vibrato tables, note table, noise table, waves, length tables, pan table | `DrM_Tables.inc` |
| `$6CA8–$7FD0` | 10 song headers, 36 section lists, 129 patterns | `DrM_Songs.inc` |
| `$7FD1–$7FFF` | padding, entry stubs | `DrM_Stubs.inc` |
 
```
DrMario\build_check.sh          # assemble, link over the ROM, compare
DrMario\harness\build.sh        # test ROM: harness + rebuilt bank 1
DrMario\harness\verify.py       # play every song/SFX, check every data read
python DrMario\gen_drmario.py <rom> DrMario   # regenerate the sources (needs tools\)
```
 
This is the reference version for the family. *SML1* is older (fewer commands), *SML2* / *LA* / *SMB DX* / *Metal Slug 2* are later. The Metroid II / Wario Land driver was built from this version; see `Tanaka_Lineage_Metroid2_WarioLand_Sanrio2.md`.
 
---
 
## 1. API
 
| Address | Routine | |
|---|---|---|
| `$7FF0` | `jp Sound_Update` (`$65C0`) | once per frame |
| `$7FF3` | `jp Sound_Stop` (`$6507`) | stop music and effects, mute |
| `$7FF6` | `jp Sound_Init` (`$66A4`) | NR52 = `$80`, NR50 = `$77`, NR51 = `$FF`, clear `$DF00–$DFFF` |
 
All sound RAM is the `$DF00` page.
 
| Variable | | Meaning |
|---|---|---|
| `wSongRequest` | `$DFE8` | 1–10 = start song, `$FF` = stop |
| `wSfx1Request` | `$DFE0` | 1–14 = ch1 effect |
| `wSfx4Request` | `$DFF8` | 1–3 = ch4 effect |
| `wSfx3Request` | `$DFF0` | written by the game but **never read** (the ch3 effect code exists but is unreferenced, §4.4) |
| `wPauseRequest` | `$DF7F` | 1 = pause (jingle), 2 = resume |
| `wDangerBeep` | `$DF8A` | non-zero: keep requesting effect 9 |
| `wForceSfx0A` | `$DF8B` | non-zero: request effect 10 (cleared every frame) |
| `wPitchUpLevel` | `$DF8F` | 0–3, raises every note (§3.4); the game copies `$FFDE` here |
| `wSongDanceSpeed` | `$DF88` | out: per-song value from `SongDanceSpeedTable`; the game uses it as the speed of the dancing viruses |
| `wSong0AEnded` | `$DF89` | out: set when song 10 reaches its end |
 
**`Sound_Update` order.**
1. Pause: request 1 / 2, then the pause jingle while `wPauseTimer` ≠ 0.
2. Song request.
3. `wForceSfx0A` and the danger beep: request effect 9, unless effects 8, 10 or 11 are requested or playing.
4. ch1 effects. If an effect just requested song 10, the song request is handled in the same frame.
5. ch4 effects.
6. Music.
7. Clear every request byte.
---
 
## 2. Data
 
### 2.1 Songs
 
```
SongTable:   dw Song01_Header, ...                ; 10 entries, little-endian
SongNN_Header:
    SONG transpose, LengthTable, Ch1List, Ch2List, Ch3List, Ch4List   ; 0 = channel unused
SongNN_ChN:  dw Pattern, Pattern, ...             ; section list
             LIST_END                             ; dw $0000: the song ends
             LIST_LOOP target                     ; dw $FFFF, target
Pattern:     notes, lengths, commands ... PAT_END ; $00
```
 
- **Loop and end are detected from the high byte only.** A list entry whose high byte is `$00` ends the song (`Sound_Stop` is called, and `wSong0AEnded` is set for song 10). High byte `$FF` jumps.
- **Each channel has its own list, but one list ending stops everything.** The four jingles (songs 4, 5, 8, 10) rely on this: only ch1's list has a terminator. ch2–ch4 have a one-entry list that runs straight into the next channel's list. The harness confirms that their last `PAT_END` is never reached, because ch1 ends first.
### 2.2 Pattern bytes
 
| Byte | Meaning |
|---|---|
| `$00` | `PAT_END`: next list entry |
| `$01` | `REST`: envelope `$08` (silent); the period is not changed |
| `$02–$90` (even) | note C2–B7 = byte offset into `NoteTable` (ch1–ch3) |
| `$06,$0B,$10,$15,$1A` | ch4: `NOISE1–5` = byte offset into `NoiseTable` |
| `$9B n` | `REPEAT n`: repeat the following n times… |
| `$9C` | `REPEAT_END` |
| `$9D a b c` | `INSTR` (ch1/2/4) / `INSTR_WAVE wave, level` (ch3) |
| `$9E ptr` | `TEMPO`: select a length table |
| `$9F n` | `TRANSPOSE`: in table bytes (2 per semitone), signed; added to every note |
| `$A0–$AF` | length: entry n of the current length table; stays in force until the next one |
 
There is one repeat level per channel. Its count is kept in bits 0–6 of `wChNFlags`.
 
**Length tables** (`$6C23–$6C7F`) are packed, so neighbouring tables overlap:
 
| Entry | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Value | 1/32 | 1/16 | 1/8 | 1/4 | 1/2 | 1/1 | 1/8. | 1/4. | 1/2. | 1/8 triplet | 1/4 triplet | (next table) |
| Macro | `L32` | `L16` | `L8` | `L4` | `L2` | `L1` | `L8D` | `L4D` | `L2D` | `L8T` | `L4T` | `LEN11` |
 
The songs use four tables:
 
| Table | Quarter note | Songs |
|---|---|---|
| `$6C4C` | 24 frames (150 BPM) | 1, 3–8 |
| `$6C5A` | 28 frames (129 BPM) | 2 |
| `$6C67` | 32 frames (112 BPM) | 9 |
| `$6C2C` | 12 frames | 10 |
 
`$6C23` is never pointed to.
 
### 2.3 Instruments
 
`INSTR env, flag, duty` sets three channel fields. When a note triggers:
 
- **NRx1 = duty.** This byte holds the duty and the hardware length.
- **NRx2 = env.**
- **NRx4 = period high | `$C0`**, i.e. trigger plus **length enable**.
Two consequences:
 
- **The hardware length cuts notes.** With `duty = $80` (50 %, length 0) a note stops after 64/256 s, about 15 frames, whatever its length in the song. In emulation the channel goes off after 14 frames. Long notes therefore need an envelope that decays first, or a pitch effect (next point).
- **The low nibble of the duty byte also selects a pitch effect.** The effect is applied every frame after the trigger:
  - 0: none;
  - 1: wobble table;
  - 2: fall table;
  - 3–15: the period minus 2 (a fixed detune).
  The effect writes NRx3/NRx4 **without** the length-enable bit. So a note with an effect is no longer cut by the hardware length after its first frame.
The tables are indexed by `NoteFrames / 2`. Each byte holds two signed 4-bit offsets, high nibble on even frames. Neither table is bounded:
- the fall table (30 bytes) continues into the wobble table after 60 frames;
- the wobble table continues through 30 zero bytes and then into `NoteTable` after 170 frames.
The songs use types 0, 1 and 3 only.
 
**Flag byte.** If the flag byte is non-zero, the trigger skips loading NRx2. NRx2 then gets whatever is in `e`: the low byte of the channel's `Freq` address (`$99` on ch1, `$A9` on ch2), which happens to be a rising envelope. No song sets the flag.
 
**ch3.** `INSTR_WAVE wave, level` loads the 16-byte wave immediately (NR30 is turned off first). A trigger writes:
- NR30 off then on;
- NR31 = 0 for a long note, or `$EF` (a few frames) when level bit 7 is set;
- NR32 = level;
- the period, with NR34 | `$C0`.
With level bit 7 set, the channel also drops to 50 % volume 6 frames before the note ends. Two waves are used: `$6BF3` (all songs) and `$6BD3` (song 5).
 
**ch4.** A noise byte copies 5 bytes from `NoiseTable + byte` into the channel fields: env, flag, NR41, NR43, NR44. The trigger then writes them like a tone channel. There are five drums.
 
### 2.4 Panning
 
`SongPanTable` holds one 4-byte entry per song: mode, period, NR51 A, NR51 B. Mode 1 writes NR51 A once. Any other mode alternates A and B every *period* frames. `Sound_Stop` sets mode 3, but the NR51 values are not reloaded until the next song.
 
---
 
## 3. Engine
 
### 3.1 Channel structure
 
Each channel has a 16-byte structure at `$DF90 + $10·n` (`wChN…`):
 
| Offset | Field | Offset | Field |
|---|---|---|---|
| +0 | `ListPtr` (high byte 0 = channel off) | +9 | `Freq` (period, 2 bytes) |
| +2 | `LenCounter` | +B | `Rest` |
| +3 | `Length` | +C | `RepeatPtr` (2 bytes) |
| +4 | `PatPtr` (2 bytes) | +E | `NoteFrames` (ch1–3, for the pitch effects) |
| +6 | `InstrEnv` | +F | `Flags`: bit 7 = taken by an effect, bits 0–6 = repeat count |
| +7 | `InstrFlag` | | |
| +8 | `InstrDuty` | | |
 
### 3.2 Frame
 
`Music_Update` walks ch1→ch4 using `wMusicChannel`.
 
- If the channel's `LenCounter` hasn't run out, run `Music_Sustain`: the ch3 release step, then the pitch effect.
- Otherwise read commands until a note or rest, write the note (`Music_Trigger`) and reload `LenCounter` from `Length`.
Nothing is written to a channel whose `Flags` bit 7 is set. The music state still advances, so the music comes back at its next note when the effect releases the channel.
 
### 3.3 Notes
 
The note's period is `NoteTable[byte + transpose + pitch-up]`.
 
`NoteTable` is the Tanaka-family table: index 0 = `$0F00`, then C2 `$002C` … B7 `$07DF`. It contains the family's two tell-tale values: A♯5 = `$773` and C♯7 = `$7C4` (should be `$7C5`).
 
Nothing clamps the result. A transposed or raised note past B7 reads `NoiseTable`.
 
### 3.4 Pitch-up
 
`wPitchUpLevel` raises every note:
- level 1: +1 semitone;
- level 2: +2 semitones;
- level 3: +3 semitones, plus 1 more for every 256 frames spent at level 3 (`wPitchUpTimer`, at most 31).
---
 
## 4. Sound effects
 
### 4.1 Mechanism
 
Effects are code: one init routine and one per-frame routine per effect, reached through `Sfx1_InitTable` / `Sfx1_PlayTable` and `Sfx4_InitTable` / `Sfx4_PlayTable`.
 
**Start.** `Sfx_Start` (a = frames per step, hl = register image) does the following:
- sets `Playing` = the effect number;
- clears `Timer` / `Step`;
- sets bit 7 of the channel's `Flags`;
- writes the image (NR10–14, NR21–24, NR30–34 or NR41–44, through `SetRegs_ChN`).
**Each frame.** `Sfx_Tick` returns 0 every *period* frames. The per-frame routine then writes the next image or sequence entry, or stops.
 
**Priority.** Several ch1 effects do not start while certain others play:
 
| Check | Refuses while playing |
|---|---|
| `Sfx1_IsBusy_C8ABD` | 8, 10, 11, 12, 13 |
| `Sfx1_IsBusy_8ABD` | 8, 10, 11, 13 |
| `Sfx1_IsBusy_456` | 4, 5, 6 |
| `Sfx1_IsBusy_56` | 5, 6 |
 
### 4.2 ch1 effects
 
| # | Kind | Frames/step | Notes |
|---|---|---|---|
| 1 | 2 images | 5 | |
| 2 | 1 image twice | 4 | |
| 3 | 1 image | 2 | |
| 4 | 1 image | 3 | |
| 5, 6, 12 | image + NR12/NR13 sequences | 3, 5, 4 | end on NR12 = 0 |
| 7 | 1 image | 1 | |
| 8, 11, 13 | ch1 + ch2 in step (`Sfx1_PlayTwoChannelSequence`) | 4, 6, 4 | 13 requests song 10 at its end |
| 9 | danger beep, own counter | 1 | images on frames 4, 11, 15; ends at 48 |
| 10 | image ×9 | 8 | releases ch2 at start (no effect) |
| 14 | 2 images | 5 | |
 
**Two-channel sequences.** Each step writes NR13 from sequence A and NR23 from sequence B (`$FF` in A ends). The envelope is `$F2` on both channels, or `$08` when the B entry is 0.
 
The NR14 and NR24 values are read from fixed addresses inside effect 8's and effect 11's images: `Sfx1_08_Regs1+4` = `$C7`, and `Sfx1_0B_Regs1+3` = `$97`. The second is that image's NR13 byte, not an NR14 byte. It still works because `$97` has the trigger bit set and the same period-high bits as `$87`.
 
### 4.3 ch4 effects
 
| # | Effect |
|---|---|
| 1 | 1 image, 24 frames |
| 2 | NR43 cycles through 8 values every 3 frames, until stopped |
| 3 | stop the ch4 effect |
 
### 4.4 Unreferenced ch3 effect code
 
`$641D–$6470` contains two routines that nothing calls:
- `Sfx3_Start_Unused` takes **all four** channels and loads a wave;
- `Sfx3_Stop_Unused` releases them and reloads the song's wave (`$6BD3` for song 5, else `$6BF3`).
The game writes `wSfx3Request`, but `Sound_Update` only clears it. Their variables are cleared by `Sound_ClearState`.
 
### 4.5 Pause
 
Pause request 1 does the following:
1. mutes everything;
2. cancels the effects;
3. loads wave `$6BF3`;
4. sets `wPauseTimer` = `$30`.
While paused, ch2 plays a 4-note jingle: image A at `$30`, B at `$28`, A at `$20`, B at `$18`. At `$10` the timer is re-incremented, so it holds there until request 2 clears it. This is the same pause logic as *SML1*, and Metroid II copied it.
 
---
 
## 5. Quirks
 
1. **Hardware length cuts notes** without a pitch effect (§2.3). It is part of the sound.
2. **Unbounded pitch-effect tables** (§2.3).
3. **`InstrFlag` ≠ 0** sends a stray register value to NRx2 (unused, §2.3).
4. **Transpose and pitch-up are not clamped** (§3.3).
5. **Unterminated lists** in the jingles (§2.1).
6. **`Sfx1_PlayTwoChannelSequence`** takes NR24 from an NR13 byte (§4.2).
7. **ch3 effects:** request variable never read, code unreferenced (§4.4).
8. **`Music_Trigger_flagSet`** contains a no-op `push hl / pop hl`. `Music_Vibrato` tests `cp $03 / jr z` into the next instruction, so types 3–15 behave the same.
9. **`Music_LoadHeader`** reads the first list entry of every channel, including unused ones: song 7, all-silent, reads `$0000/$0001`.
10. **Sound_Init's final `ret`** is used as the "do nothing" entry of `Sfx4_PlayTable` (effect 3). Metroid II uses `initializeAudio.ret` the same way in its SFX tables.
---
 
## 6. Songs
 
| Song | Length table | Lists (entries) | End |
|---|---|---|---|
| 1 | `$6C4C` | 9 / 9 / 9 / 9 | loop → entry 1 |
| 2 | `$6C5A` | 11 / 9 / 7 / 8 | loop → 1 |
| 3 | `$6C4C` | 4 ×4 | loop → 1 |
| 4, 5, 8 | `$6C4C` | 1 each | end |
| 6 | `$6C4C` | 5 / 4 / 3 / 3 | loop → 2 |
| 7 | `$6C4C` | none | silent |
| 9 | `$6C67` | 14 ×4 | loop → 11 |
| 10 | `$6C2C` | 1 each | end, sets `wSong0AEnded` |
 
Song titles weren't identified, and neither were the game contexts of the effects.
 
---
 
## 7. Verification
 
- **Byte-exact rebuild** of `$6000–$7FFF` (`build_check.sh`: `rgblink -O` over the original ROM, then `cmp`).
- **Emulator harness.** The test ROM links the **rebuilt** bank 1 and calls the update stub once per frame. `verify.py` (PyBoy) then:
  - plays each song for 3,600 frames;
  - plays each effect for 600 frames;
  - hooks the pattern read (`ReadPtrByte`), the list read (`CopyWordIndirect`), the register-image copy, the wave loader and every SFX table read (shared checker: `tools\playcheck.py`).
  | | Reads | Outside the parse |
  |---|---|---|
  | Songs 1–10 (pattern / list reads) | 8,045 / 206 | 0 |
  | ch1 effects 1–14 | 300 data reads | 0 |
  | ch4 effects 1–3 | 207 data reads | 0 |
  Playing every song for 12,000 frames reads every parsed pattern byte except the final `PAT_END` of ch2–ch4 in the four jingles (9 bytes, §2.1).
- **Length-cut check.** In PyBoy, NR11 = `$80` with NR14 = `$C7` keeps ch1 on for 14 frames, and NR14 = `$87` keeps it on indefinitely.
- **Not verified:** song titles and effect contexts, and anything on hardware.
## Files (`Nint1\DrMario`)
 
| File | Content |
|---|---|
| `DrM_Sound.asm` | the section; includes the files below |
| `DrM_Driver.inc` | code `$6000–$6A9E` with labels and routine comments; SFX images and sequences |
| `DrM_Tables.inc` | pitch-effect tables, `NoteTable`, `NoiseTable`, 6 waves, length tables, `SongPanTable` |
| `DrM_Songs.inc` | `SONG` headers, section lists, patterns (notes as `C4`, `Fs3` …, lengths as `L8` …) |
| `DrM_Stubs.inc` | `$7FD1–$7FFF` |
| `DrM_Macros.inc`, `DrM_RAM.inc` | macros and constants; RAM map (`wCh1ListPtr` … `wCh4Flags`, request bytes) |
| `gen_drmario.py` | generator (uses `tools\gbdis.py`, `tools\tanaka.py`) |
| `harness\` | `harness.asm`, `build.sh`, `verify.py` (uses `tools\playcheck.py`; `verify.py 12000` adds the coverage pass), `model.json` |
