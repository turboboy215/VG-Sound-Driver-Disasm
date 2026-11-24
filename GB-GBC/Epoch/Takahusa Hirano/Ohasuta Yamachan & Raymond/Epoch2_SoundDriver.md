# Epoch Sound Driver, type 2 — Ohasuta Yamachan & Raymond (J), Doraemon: Aruke Aruke Labyrinth (J), Sylvanian Families: Otogi no Kuni no Pendant (J)

Disassembly and documentation of the sound driver shared by three Epoch Game Boy Color games. Everything here comes from the code. The format was checked by running every song and SFX through the real driver code and comparing driver RAM, sound registers and every register write, frame by frame, against a Python model written from this document (§11).

This driver has nothing in common with the one in Doraemon (J) / Dragon Slayer I (J) (`Epoch_SoundDriver.md`): no shared code, RAM layout or data format. "Type 2" is used here to tell them apart.

| Game | ROM | Mapper | Version | Sound RAM | SFX bank | Music banks | Call order per frame |
|---|---|---|---|---|---|---|---|
| Ohasuta Yamachan & Raymond (J) | 256 KB | MBC5 | **A** | $CC00 | $08 | $09–$0C | music, then SFX |
| Doraemon: Aruke Aruke Labyrinth (J) | 1 MB | MBC5 | **B** | $DF00 | $05 | $06–$09, $2C, $2D, $3D–$3F | SFX, then music |
| Sylvanian Families: Otogi no Kuni no Pendant (J) | 2 MB | MBC5 | **C** | $CF00 | $7A | $70–$78 | SFX, then music |

## Summary

- There are **two drivers**, a music driver and an SFX driver. They are near-copies of each other with separate RAM, and they share four **channel lock** bytes that decide who owns each hardware channel (§8).
- The music driver is **copied into every music bank** together with that bank's songs, tables and frequency table. Each sound bank starts with `jp Init` / `jp Update`, so the game only switches banks and calls $4000 or $4003.
- All four channels are written out in full (no loops over channels, no channel structs). Pointers are kept **big-endian** in RAM.
- A track row is **3 bytes**: note, volume, length in frames. There is no tempo and no length table; `length` is the number of frames.
- Commands: `$E0` rest, `$F0` instrument, `$F1` pan, `$F2` pitch modulation, `$FF $00/$01/$FF` loop point / jump / end.
- Instruments are register images per channel type; the wave channel's instrument carries its own 16-byte wave. Drums come from the note byte through a drum table.
- Three versions, one per game: B and C fix several A bugs but keep others (§9).
- The SFX driver reads the frequency table one entry lower than the music driver (SFX note *n* = music note *n−1*), and its ch3 `$F0` reads the drum table as a wave instrument (§10).

---

## 1. Sound bank layout

Every sound bank (music or SFX) has the same parts. Only their order differs.

| Part | Content |
|---|---|
| $4000 | `jp Init`, `jp Update` |
| $4006 | `SongTable`: one word per id (32 entries; 64 in Sylvanian banks $74–$78 and $7A) |
| tables | `Ch1InstTable`, `Ch2InstTable`, `WaveTable`, `NoiseTable` (§6) |
| songs | headers and tracks (§3) |
| driver | the code (~2.6 KB music, ~2.2 KB SFX) |
| `FreqTable` | 72 words, C2–B7. It sits right after the code because the code addresses it as `FreqTable − 2` |
| silent song | id $1F (Ohasuta, Doraemon) or $00 (Sylvanian): ch1–ch3 `$F1 $00 $F0 $00 [$E0 $01] $FF $FF`, ch4 `$F1 $00 [$E0 $01] $FF $FF` (the `$E0 $01` only in Sylvanian) |

- **Ohasuta**: jumps, table, driver, `FreqTable`, instrument tables, songs.
- **Doraemon / Sylvanian**: jumps, table, instrument tables, songs, driver, `FreqTable`, silent song.

**Song tables are indexed by the global id.** Every music bank has a full table, but only the ids stored in that bank point anywhere useful. Ohasuta fills the other entries with the silent song or the bank's first song. Doraemon and Sylvanian use 0.

**Id → bank** is decided by the game:

| Game | Where | Notes |
|---|---|---|
| Ohasuta | byte table at $0DDE (32 ids) | ids $1B–$1E map to bank $09, whose table points them at id $04's song |
| Doraemon | byte table at $2B10 (32 ids) | ids $0E, $15, $16, $1D, $1E map to bank $06, where their entry is 0 (header read from $0000): unused. $0F/$10 and $17/$18 share a song |
| Sylvanian | compare chain at $3DE1 | $00–$03 → $70, $04–$06 → $71, $07–$16 → $72, $17–$1D → $73, $1E–$21 → $75, $22 → $76, $23–$25 → $77, $26–$27 → $78, $28–$37 → $74 |

The instrument, wave and drum tables are identical in every music bank of a game.

**Stale bytes.** In Doraemon banks $07–$3E and Sylvanian banks $71–$78, the bytes after the sound data are left over from an earlier build: each run is identical to another sound bank at the same addresses (e.g. Doraemon $07: $77FE–$7CE8 = bank $3E). Nothing reads them. The disassembly includes them so the whole used part of the bank reassembles. Sylvanian bank $7A holds unrelated, non-sound data after $56A7, which is not included.

## 2. Interface

| Call | Music bank | SFX bank |
|---|---|---|
| start | `wMusicId` = id, call $4000 (`Mus_Init`) | `wSfxId` = id, call $4000 (`Sfx_Init`) |
| per frame | call $4003 (`Mus_Update`) | call $4003 (`Sfx_Update`) |
| stop | start the silent song | start the silent SFX |

There is no separate stop routine. A driver stops by itself when all four tracks have reached `$FF $FF`: it sets its id to $FF, and `Update` then does nothing.

**`Mus_Init`** (A/B):
1. NR52 = 0, then $80. This clears every sound register, including any SFX in progress. NR50 = $77, NR51 = $FF.
2. Header = `SongTable[wMusicId]`. The four track words are offsets from the header; the driver adds the header address.
3. Clears the row counters, end flags, modulation modes, the four locks and the four pan bytes.

It does **not** reset instruments, rest bytes, loop points, modulation settings or instrument pointers. A song that sends a note before `$F0` uses the previous song's values.

Version C differs:
- It silences only the channels the SFX does not hold (lock ≠ 1): NR12, NR22, NR30, NR42/NR43 = 0.
- It does not toggle NR52 and keeps the locks.
- A busy flag (`wMusBusy`) is set for the duration, and `Mus_Update` returns at once while it is set.

**`Sfx_Init`** reads `SongTable[wSfxId]` the same way and clears counters, end flags and modulation modes. It then sets **all four locks to 2**, so the music restores every channel at its next note (§8). It does not touch the registers. Version C adds the busy flag `wSfxBusy`.

The fifth header word is the size of the data (offset of its end). Init stores it lo/hi but reads it back hi/lo, so the stored value is garbage. Nothing reads it.

## 3. Songs and tracks

**Header**: 5 little-endian words, offsets from the header: ch1, ch2, ch3, ch4 tracks, end of data.

**Track bytes** (anything that is not a command is a note row):

| Bytes | Meaning |
|---|---|
| `nn vv ll` | note row: note *nn*, volume *vv*, length *ll* frames |
| `$E0 ll` | rest for *ll* frames (§5) |
| `$F0 n` | instrument *n* (ch1–ch3). **On ch4 the driver hangs** (below) |
| `$F1 p` | pan: 0 both sides, 1 left only, 2 right only |
| `$F2 m [d c s1…sc]` | pitch modulation (§7); `$F2 $00` turns it off |
| `$FF $00` | loop point: the next row |
| `$FF $01` | jump to the loop point |
| `$FF $FF` | end of track |

Commands take no time. The channel keeps reading until it reaches a note row or a rest.

**Note rows**

- **Tone channels (ch1, ch2).**
  - Music: frequency = `FreqTable[nn]`, so $00 = C2 … $47 = B7.
  - SFX: frequency = `FreqTable[nn − 1]` (§10).
  - The low nibble of *vv* replaces the NR12/NR22 volume nibble (the envelope bits come from the instrument).
  - NRx3/NRx4 are written with the trigger bit.
- **Wave channel (ch3).**
  - Music: NR30 = 0 and NR31 = 0, then NR32 = instrument level, NR33, NR30 = $80, NR34 with trigger.
  - SFX: NR30 = 0 (B/C also NR31 = 0), NR32, NR30 = $80, NR33, NR34.
  - *vv* is ignored. In the music driver, NR30/NR31 are cleared **even when the SFX owns ch3**, which cuts a ch3 SFX.
- **Noise channel (ch4).**
  - *nn* is a drum number. NR42, NR43 and the NR44 byte come from `NoiseTable[nn]` (3 bytes each).
  - *vv* replaces the NR42 volume nibble, and NR44 is written with bit 7 set.
  - The noise handler also loads `FreqTable − 2` into hl and never uses it.

**Loops.** `$FF $00` stores the address of the next row, and `$FF $01` jumps there. Every `$FF $01` in the data has an `$FF $00` before it in the same track. Without one, the jump goes to the previous song's loop point (or $0000 after power-on).

Tracks that loop are followed by an unreached `$FF $FF` (sometimes `$E0 $01 $FF $FF`).

**Hangs.**
- An `$FF` followed by anything other than $00, $01 or $FF re-reads the same byte forever: the handler does not store the advanced pointer.
- The same happens with `$F0` on ch4, in both drivers.

Neither occurs in the data.

## 4. Timing

- Each track has a frame counter. A row sets it to `length − 1`; each later frame decrements it, and the next row is read when it is 0.
- A row therefore lasts exactly *length* frames (0 = 256). The data never uses 0 and goes up to 255.
- Every channel is independent. Durations come straight from the data; there is no tempo.
- Pitch modulation runs only on frames where the counter was non-zero, i.e. not on the frame a row is read.

## 5. Rests

`$E0` uses the last instrument's rest value:

| Channel | Rest value | When non-zero |
|---|---|---|
| ch1 | instrument byte 3 | NR12 = 0, NR12 = envelope, NR14 = rest value |
| ch2 | instrument byte 2 | NR22 = 0, NR22 = envelope, NR24 = rest value |
| ch3 | instrument byte 1 | NR30 = 0 |
| ch4 | drum byte 2 (NR44) | NR42 = NR43 = 0, then NR42, NR43, NR44 from the drum |

Writing NRx2 = 0 turns the channel's DAC off. The rest values in the data are $00 or $40, so a rest never retriggers. With $40 the channel is cut; with $00 the rest does nothing and the note keeps ringing.

A rest also restarts the modulation list (§7), like a note.

## 6. Instruments

| Table | Entry | Bytes |
|---|---|---|
| `Ch1InstTable` | 4 | NR10, NR11, NR12, rest value (NR14) |
| `Ch2InstTable` | 3 | NR21, NR22, rest value (NR24) |
| `WaveTable` | 18 | NR32, rest flag, 16 bytes of wave RAM |
| `NoiseTable` | 3 | NR42, NR43, NR44 |

**`$F0 n`** stores a pointer to entry *n* (index × size via an 8×8 multiply) and, if the music owns the channel, writes it:

- **ch1**: NR10, NR11, NR12 are written. NR12 and the rest value are kept in RAM.
- **ch2**: NR21, NR22 are written. NR22 and the rest value are kept in RAM.
- **ch3**: level and rest flag are kept in RAM. The 16 bytes go to $FF30–$FF3F, then NR30 = $80. B/C write NR30 = 0 first, so wave RAM is never written while ch3 is playing; A writes it with the channel on.

Indices are not range-checked:
- Several Doraemon and Sylvanian ch3 tracks are just `$F0 $56 $FF $FF`. Entry $56 lies far past `WaveTable`, so this loads song data into wave RAM and turns NR30 on, but no note follows.

| Game | ch1 | ch2 | wave | drums |
|---|---|---|---|---|
| Ohasuta (music) | 13 | 6 | 20 | 15 |
| Doraemon (music) | 5 | 3 | 20 | 15 |
| Sylvanian (music) | 6 | 4 | 9 | 11 |
| Ohasuta (SFX) | 19 | — | — | 11 |
| Doraemon (SFX) | 19 | 3 | — | 10 |
| Sylvanian (SFX) | 18 | 3 | — | 12 |

The SFX banks have no wave table (and Ohasuta's has no ch2 table either). The SFX driver's pointers for these point at `NoiseTable` (§10).

## 7. Pitch modulation (`$F2`)

```
$F2 mode delay count  step1 … step_count
$F2 $00                                    off
```

- The *count* step bytes are copied into an 18-byte RAM buffer per channel (ch1–ch3; ch4 has none).
- At every note and rest, the step pointer, delay and count are restarted.
- On each frame after the row's first, the delay counts down. Once it is 0, each frame takes the next step *s* and writes NRx3 = base frequency low byte ± *s*.
- NRx4 is only written when that addition carries (hi + 1) or the subtraction borrows (hi − 1), and never with the trigger bit. After a frame that carried, later frames that do not carry leave NRx4 at hi + 1.

| Mode | Direction | When the list is used up |
|---|---|---|
| 1, 2, ≥ 6 | add | start the list again |
| 3 | subtract | start again |
| 4 | add | stop (the last value stays) |
| 5 | subtract | stop |

**Limits**
- The data uses modes 2, 4 and 5, with 3–26 steps. Sylvanian song $34 uses 26-step lists on ch1 and ch2, which overrun the 18-byte buffers into the next channel's buffer.
- A count of 0 copies 256 bytes, and in modes 1–3 the empty list then loops forever.

**When modulation pauses** (music driver)
- A/B: while the channel's lock is not 0.
- C: only while the lock is 1.

## 8. Channel locks and SFX

`wCh1Lock`–`wCh4Lock` (offsets $40–$43) are shared by the two drivers:

| Lock | Meaning |
|---|---|
| 0 | music owns the channel |
| 1 | SFX owns it: the music driver keeps reading its track but writes nothing to that channel |
| 2 | SFX has released it: the music driver restores the channel at its next note |

**What the SFX driver does**
- `Sfx_Init` sets all four locks to 2.
- Every SFX note sets its channel's lock to 1.
- An SFX rest that does something (rest value ≠ 0) sets the lock to 2.
- An SFX track end sets the lock to 2. In B/C it does so only if the lock is not already 0.
- In C, `$F0`, `$F1` and `$F2` also set the lock to 1.

**What the music driver does at a note while lock = 2**
1. Re-applies its stored pan.
2. Rewrites the instrument from its stored pointer: ch1/ch2 registers, the ch3 wave, or the ch4 drum.
3. In B/C, restarts modulation.
4. Sets the lock to 0.

While the lock is not 0:
- Music `$F0` only stores the pointer.
- Music `$F1` only stores the value.
- Music rests skip the registers only for lock 1.

A music note that is still sounding when the SFX releases the channel stays silent (or keeps the SFX's sound) until the next music note.

The SFX driver never checks the locks before writing, except the B/C end-of-track case above.

## 9. Versions

### Music driver

| | A (Ohasuta) | B (Doraemon) | C (Sylvanian) |
|---|---|---|---|
| Init | NR52 off/on, clears locks | same, plus a dead `xor a` | silences channels not held by the SFX, keeps locks, busy flag |
| Update while Init runs | — | — | skipped (`wMusBusy`) |
| `pop` order at the end of Update | push order (registers come back swapped) | same | fixed |
| NR30 before writing wave RAM | no | NR30 = 0 first | NR30 = 0 first |
| Restore (lock 2) | pan + instrument | + modulation restart | + modulation restart |
| Pan: values ≥ 3 | both sides on | both sides on | ignored |
| Pan on restore: values 1/2 | clear one side only (does not set both first) | same | set both, then clear one |
| Modulation pauses for | lock ≠ 0 | lock ≠ 0 | lock = 1 |

### SFX driver

| | A | B | C |
|---|---|---|---|
| ch3 note | NR30=0, NR32, NR30=$80, NR33, NR34 | + NR31 = 0 | + NR31 = 0 |
| NR30 before wave RAM (`$F0`) | no | yes | yes |
| End of track | lock = 2 | lock = 2 only if lock ≠ 0 | same as B |
| `$F0`/`$F1`/`$F2` | — | — | lock = 1 |
| Rest | lock = 2 | lock = 2 | lock = 2 and modulation off |
| Busy flag, `pop` order | — / push order | — / push order | `wSfxBusy` / fixed |

**Code size**

| Version | Music driver | SFX driver |
|---|---|---|
| A | 1,308 instructions ($4046–$4AA8 in bank $09) | 1,066 |
| B | 1,340 | 1,081 |
| C | 1,378 | 1,116 |

## 10. Bugs and quirks

| # | Where | Effect |
|---|---|---|
| 1 | `$FF xx` (xx ≠ $00/$01/$FF), `$F0` on ch4 | endless loop (pointer not stored). Unused |
| 2 | SFX note lookup | SFX note *n* plays `FreqTable[n−1]`, one semitone below the music driver's note *n*. Note 0 reads the 2 code bytes before the table (`pop bc` / `ret` = $C9C1). Doraemon SFX $05 and Sylvanian SFX $04 use note 0 on ch1 |
| 3 | SFX `$F0` on ch3 | reads 18 bytes from `NoiseTable` as level, flag and wave. A also reads ch2 instruments from `NoiseTable`. Used by the silent SFX $1F in Ohasuta and Doraemon (`$F0 $00` on ch2/ch3), so playing it overwrites wave RAM with drum bytes until the music's next ch3 note restores the wave |
| 4 | music ch3 note | NR30/NR31 cleared before the lock check, cutting a ch3 SFX |
| 5 | header word 5 | stored byte-swapped, never read |
| 6 | A/B `Update` | pops af/bc/de/hl in push order, so callers get their registers back swapped |
| 7 | `Update` | stray `xor b` after the four channel calls (harmless) |
| 8 | modulation | NRx4 written only on carry/borrow; NRx4 can stay at hi±1 |
| 9 | `$F2` count | > 18 overruns the next buffer (Sylvanian song $34: 26). 0 copies 256 bytes |
| 10 | `$F0 $56` on ch3 | Doraemon $0D, Sylvanian $04, $17, $18, $1C, $1F, $28, $33: past `WaveTable`, loads song bytes into wave RAM |
| 11 | C RAM | `wMusBusy` ($F8) is the last byte of the SFX ch3 modulation buffer ($E7–$F8). An 18-step SFX ch3 list would set it |
| 12 | Doraemon id table | 5 ids point at bank $06 entries that are 0 |

## 11. Files and verification

In `GBAudioLab\Epoch2\`:

| File | Contents |
|---|---|
| `Ohasuta\bank08.asm` … `bank0C.asm` | one file per sound bank: tables, songs and tracks; `INCLUDE`s the driver |
| `Doraemon\bank05.asm` … `bank3F.asm` | 10 banks |
| `Sylvanian\bank70.asm` … `bank7A.asm` | 10 banks |
| `driver\mus_A.inc`, `mus_B.inc`, `mus_C.inc`, `sfx_A.inc`, `sfx_B.inc`, `sfx_C.inc` | the driver code, once per version |
| `epoch2_sound.inc` | EQUs only: register names and RAM names (`SOUND_RAM + offset`) |
| `tools\e2_gen.py` | generator for everything above (`python e2_gen.py OUTDIR`) |
| `tools\e2_parse.py`, `e2_code.py`, `e2_names.py`, `sm83.py`, `da.py` | bank analysis, driver rendering, names and comments, disassembler |
| `tools\e2_verify.py` | assembles every bank and compares it with the ROMs |
| `tools\e2_cpu.py`, `e2_model.py`, `e2_check.py`, `e2_fuzz.py`, `e2_pyboy_check.py` | interpreter, model and the three checks below |

The tools read the three ROMs from the `Epoch2` folder under their original file names.

**Source format**
- **No macros.** Code is plain instructions with EQU names.
- Each bank file is assembled on its own, so the driver labels (`Mus_Init`, `Mus_Ch1`, …) are local to it and the same include works in every bank. The bank file defines `SOUND_RAM` and the table labels the include uses.
- Code lines end with their offset from the driver start; `Mus_Init` is at $4046 in Ohasuta's banks and moves from bank to bank in the other two games.
- Every data row has a comment, for example:

```
    db $2D, $0E, $1B                     ; A5   vol 14  27f
    db $E0, $11                          ; rest 17f
    db $F2, $02, $06, $06                ; pitch mod: add, repeat, delay 6, 6 steps
        db $00, $01, $02, $03, $02, $01
    db $FF, $01                          ; jump to loop point
    db $FF, $FF                          ; end of track (not reached)
```

**Byte-identical** with RGBDS 1.0.0:

```
rgbasm -I . -o b.o Ohasuta\bank09.asm
rgblink -p 0xFF -o b.gb b.o            (pad $00 for Doraemon and Sylvanian)
```

| Game | Banks | Bytes checked | Mismatches |
|---|---|---|---|
| Ohasuta | 5 | 60,276 | 0 |
| Doraemon | 10 | 144,800 | 0 |
| Sylvanian | 10 | 152,633 | 0 |

The rest of each bank is padding. The one exception is Sylvanian $7A, whose other data is outside the sound region.

**Behaviour checks.** `e2_model.py` is a Python model written from this document, not from the instruction stream.

**1. Real data (`e2_check.py`).** `e2_cpu.py` (a small SM83 interpreter) runs the driver code from the ROM. After every call, its driver RAM, sound registers and the exact list of register writes are compared with the model. The runs were:
- every music header for 4,000 frames;
- every SFX for 600 frames;
- every SFX started on top of each bank's longest song (in the game's call order) for 900 frames;
- the same with the music restarted while the SFX plays.

| Game | Runs | Frames | Differences |
|---|---|---|---|
| Ohasuta | 220 | 237,400 | 0 |
| Doraemon | 641 | 496,800 | 0 |
| Sylvanian | 881 | 746,200 | 0 |

The real data reaches 85–87% of the music driver and 50–70% of the SFX driver code.

**2. Random data (`e2_fuzz.py`).** Random songs and SFX are written into a scratch copy of each ROM. They use every command, all modulation modes, lists of 1–40 steps, notes 0–72, loops, and non-zero rest values on every channel. Each run plays them together for 1,200 frames, with SFX and music restarts at random frames.

- Results: 150 runs per game, 0 differences.
- Coverage: every instruction of all six drivers is executed, except the endless-loop paths of bug 1.
- Those paths are tested separately: the driver code and the model both hang.

**3. PyBoy (`e2_pyboy_check.py`).** Checks the interpreter itself. Each game ROM gets a small bank-0 harness that calls $4000/$4003 in a given bank when Python asks. The driver RAM in PyBoy and in `e2_cpu` is compared after every call.

- Calls: 6 songs per game, each 1,500 frames with an SFX started at frame 200.
- Result: 18,012 calls per game, 0 differences.
