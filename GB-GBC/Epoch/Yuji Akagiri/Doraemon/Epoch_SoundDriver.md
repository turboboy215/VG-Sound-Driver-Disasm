# Epoch Sound Driver — Doraemon (J), Dragon Slayer I (J)

Disassembly and documentation of the sound driver shared by two Epoch Game Boy games. Everything here comes from the code. The format was checked by running every song and SFX through the real driver in PyBoy and comparing the driver RAM, frame by frame, against a Python model written from this document (§8).

| Game | ROM | Mapper | Driver | Sound region |
|---|---|---|---|---|
| Doraemon (J) | 128 KB | MBC1 | **v1** | bank $07, $4000–$5AB5 (6,838 bytes); game code follows at $5AB8 |
| Dragon Slayer I (J) | 32 KB | none | **v2** | $7038–$7FFD (4,038 bytes); $7FFE–$7FFF are $FF padding |

## Summary

- Both games use **the same driver**, at different addresses and with different RAM bases (Doraemon $C700, Dragon Slayer $D100). The code is about 95% identical instruction for instruction.
- The two copies differ in three ways (§6):
  - Doraemon's tracks loop with an endless `$E0 $00` loop. Dragon Slayer uses a `$FE` restart command instead.
  - Volume-step instruments have 8 steps in Doraemon and 4 in Dragon Slayer.
  - The track struct is $1E bytes in Doraemon and $20 in Dragon Slayer (the extra word holds the restart address).
- The driver runs **4 music tracks and 2 SFX tracks**. The SFX tracks run on hardware ch1 (tone) and ch4 (noise), so the music keeps ch2 and ch3.
- Track data is **delta-coded**. Each row byte packs a length index (high nibble) and a pitch step (low nibble): −6…+7 semitones from the previous note, or "absolute note follows", rest, or tie.
- Lengths come from a **per-song length table**. Timing uses a 16-bit counter that loses `tempo` per frame, which allows fractional rates.
- There is one fixed wave, and instruments are 5-byte register images plus an optional mode: volume steps, or a gate that cuts the note early.
- **Mode 2 is broken** (it never releases a note). No data uses it.

---

## 1. Interface

The driver starts with a jump table (Doraemon $4000, Dragon Slayer $7038):

| Offset | Label | Use |
|---|---|---|
| +$00 | `Sound_Update` | sequencer tick, once per frame |
| +$03 | `Sound_Output` | register writes, once per frame, **called before** `Sound_Update` |
| +$06 | `Sound_Init` | boot |
| +$09 | `Sound_PlayMusic` | a = music id |
| +$0C | `Sound_PlaySfx` | a = SFX id |
| +$0F | `Sound_StopMusic` | |
| +$12 | `Sound_StopSfx` | |

**Call sites.**
- Dragon Slayer calls Output then Update from an interrupt handler ($0237).
- Doraemon calls them from bank 0 ($035D) after switching to bank 7. Its bank-0 wrappers around play/stop ($074D–$0784) also keep a small "previous music" history at $FFC7–$FFC9. That history is game code, not driver code.

Because Output runs first, the registers a row decides are written on the **next** frame.

**`Sound_Init`**:
- writes NR30=0, NR32=$20, NR50=$77, NR51=$FF, NR52=$FF and `wSndPan`=$FF;
- copies the 16-byte wave into wave RAM;
- stops music and SFX.

It is the only place the wave is loaded, so both games use one wave for everything:
`CE FE B8 BE FF FF FE B9 63 10 00 00 00 00 13 69`

**`Sound_PlayMusic`** reads the header at `MusicTable[id]`:

| Byte | Meaning |
|---|---|
| 0 | tempo |
| 1–2 | length-table pointer |
| 3–10 | track pointers ch1, ch2, ch3, ch4 (0 = unused) |

For each used track it then sets:
- status = 1;
- the data pointer;
- counter = 0 and loop depth = 0;
- (v2 only) `TRK_START` = the data pointer.

An unused track gets status 4, so the next Output counts it off. The routine also sets NR30=0 and `wSndMusicTracks`=4.

**`Sound_PlaySfx`** works the same way with `SfxTable`. The header holds tempo, a length table and **two** track pointers (ch1, ch4). It also sets `wSndPanFlag`=2. SFX have their own tempo and length table, so music and SFX can run at different speeds.

**Stop** routines set the track statuses to 4 and the track count to 4 (music) or 2 (SFX). The next Output silences each track and counts it down.

When the music count reaches 0, `wSndMusicId`=$FF; when the SFX count reaches 0, `wSndSfxId`=$FF. These are the only "is it playing" flags.

## 2. RAM

| Doraemon | Dragon Slayer | Name | Use |
|---|---|---|---|
| $C700 | $D100 | `wSndMusicId` | id, $FF when the song ended |
| $C701 | $D101 | `wSndSfxId` | id, $FF when the SFX ended |
| $C702 | $D102 | `wSndMusicTracks` | music tracks still running |
| $C703 | $D103 | `wSndSfxTracks` | SFX tracks still running; ≠ 0 selects the SFX output path |
| $C704 / $C705 | $D104 / $D105 | `wSndMusicTempo` / `wSndSfxTempo` | |
| $C706 | $D106 | `wSndPan` | NR51 value |
| $C707 | $D107 | `wSndPanFlag` | 1 = write NR51 at the next Output; 2 = SFX just started |
| $C708 | $D108 | `wSndTrackIndex` | 0–5 while SndUpdate runs |
| $C709 + $1E·n | $D109 + $20·n | `wSndCh1`…`wSndCh4`, `wSndSfxCh1`, `wSndSfxCh4` | track structs, n = 0–5 |
| $C7BD | $D1C9 | `wSndRowByte` | row byte being parsed |
| $C7C1 / $C7C3 | $D1D1 / $D1D3 | `wSndMusicLengths` / `wSndSfxLengths` | length-table pointers |

**Track struct:**

| Offset | Name | Meaning |
|---|---|---|
| $00 | `TRK_STATUS` | 0 off, 1 released/resting, 2 sounding. SndUpdate writes 4 (ending), 5 (release) or 6 (key on); SndOutput subtracts 4 after acting on it |
| $01 | `TRK_PTR` | data pointer |
| $03 | `TRK_COUNT` | 16-bit row counter |
| $05 | `TRK_NOTE` | current note (pitch steps apply to it) |
| $06–$0A | `TRK_NR0`–`TRK_NR4` | register images NRx0–NRx4. ch2/3/4 write only NRx1–NRx4 |
| $0B | `TRK_ENVMODE` | instrument mode |
| $0C | `TRK_ENVPARAM` | mode 1: rate; mode 3: gate (word) |
| $0D | `TRK_ENVCOUNT` | mode 1/2 frame counter |
| $0E | `TRK_ENVPTR` | mode 1: volume-step list; mode 3: gate countdown (word) |
| $10 | `TRK_ENVINDEX` | mode 1 step index |
| $11 | `TRK_LOOPDEPTH` | |
| $12–$1D | `TRK_LOOPSTACK` | 3 frames of (pass, passes, return word) |
| $1E | `TRK_START` | **v2 only**: first byte of the track, for `$FE` |

Neither `TRK_NOTE` nor `TRK_ENVMODE` is reset when a song starts. The first pitch on every track is therefore absolute (all data does this). Noise tracks never load an instrument, so their `TRK_ENVMODE` stays at its power-on value of 0.

## 3. Timing

Each frame, SndUpdate does `TRK_COUNT -= tempo` (the music tempo for tracks 0–3, the SFX tempo for 4–5).

- **No underflow:** only the instrument envelope runs (§5).
- **Underflow:** rows are parsed until a note, rest or tie. That row adds `length × 8` to the counter.

So a row lasts **length × 8 / tempo frames**, and the remainder carries over. The .asm comments give every length table entry and row in frames.

- Dragon Slayer song 06 has tempo 4, so 2 frames per length unit.
- Doraemon's music tempos run from $0A to $25.
- SFX tempos go up to $50.

## 4. Track format

### 4.1 Row bytes $00–$DF

| Part | Value | Meaning |
|---|---|---|
| high nibble | 0–C | length = `lengths[n]` (word) from the song's length table |
| | D | length = the next 2 bytes (little-endian). The pitch nibble still applies |
| low nibble | 0–5, 7 | note = previous + n |
| | 6 | absolute note in the next byte (after the raw length, for `$D6`) |
| | 8 | **rest**: status 5 (release) |
| | 9 | **tie**: the counter grows, nothing else changes, so the note keeps sounding |
| | A–F | note = previous − (16 − n), i.e. −6…−1 |

Each song and SFX has its own length table (1–11 entries). The order varies, so `$1x` is not a fixed note value across songs.

**Tone tracks.**
- Frequency = `FreqTable[note − $10]`, 93 entries. Note $10 is C2 ($002C) and $6C is G#9.
- Only bits 0–2 of `TRK_NR4` are replaced, so the instrument's trigger and length-enable bits stay.
- Notes ≥ $80 would wrap (`sla a`); none are used.

**Noise tracks** (music ch4, SFX ch4).
- NR41–NR44 are copied from `DrumTable[note − $34]`, 4 bytes each, 12 entries.
- The same delta coding applies, so drum "notes" also step up and down.

A note row sets status 6 (key on) and restarts the instrument mode (§5).

### 4.2 Commands $E0–$FF

| Cmd | Args | Effect |
|---|---|---|
| $F0 | n | instrument n. **Ignored on noise tracks** |
| $E0 | n | loop start: push (pass=1, n, return). Max depth 3 |
| $E1 | – | loop end: pass += 1, then jump back while pass ≤ n. With n = 0: v1 loops **forever**, v2 plays the body once |
| $E2 | p | pass marker / alternate ending (below) |
| $FE | – | **v2**: restart the track from `TRK_START` and clear the loop depth. **v1**: falls into the NR51 case |
| $FF | – | end of track (status 4) |
| any other ($E3–$EF, $F1–$FD) | xx | NR51 = xx, written by the next Output. Data only uses `$F1` ($FF or $7E) |

**`$E2 p` (alternate endings).** When the driver reaches an `$E2`, it scans forward from that byte for the first `$E2 p` whose p equals the current pass, and continues after it. If that pass is the last one, the loop frame is popped, because the last ending has no `$E1`.

A typical use is:

```
$E0 $02   body   $E2 $01   ending 1   $E1   $E2 $02   ending 2
```

The scanner knows the byte lengths of every row and command, so it can step over notes and other commands.

**How tracks end.**
- Doraemon music tracks end in an endless `$E0 $00 … $E1`, except ids $14/$15, which end with `$FF`. Its data has 189 loops and 20 `$E2` markers in total.
- Dragon Slayer uses `$FE` on 9 tracks and `$FF` on the rest.

## 5. Instruments

`InstTable` holds pointers. Each entry is:

```
NRx0 NRx1 NRx2 NRx3 NRx4  mode  [params]
```

The 5 register bytes become `TRK_NR0`–`TRK_NR4` (NRx3 is overwritten by the note). Every key-on writes them out.

| Mode | Params | Behaviour (only while the note sounds, status 2) |
|---|---|---|
| 0 | – | none |
| 1 | rate, then 8 (v1) or 4 (v2) volume steps | At key-on, step 0 becomes the NRx2 volume nibble. Every *rate* frames, the next step is loaded and the note is **retriggered**. Step 0 is used twice (at key-on and on the first refresh) and the last step repeats |
| 2 | frames | meant as "release after n frames". The counter is decremented with `dec`, then tested with `jp nc`, but the carry is always clear after the preceding `cp $02`, so the note is **never released**. Unused by both games |
| 3+ | n | **gate**: at `$F0`, gate = n × current tempo. At key-on, countdown = counter − gate; it loses tempo per frame and on underflow the note is released. This cuts the note about n frames before its row ends |

Notes on the instrument data:
- Doraemon uses modes 0, 1 and 3 (53 instrument changes to mode-1 instruments).
- Its ch3 instruments $10, $11, $14 and $15 are gate instruments: `$80,$00,$20,$00,$80` with gate 2 or 1.
- Dragon Slayer has two null slots (9 and 12). Its last three entries ($11–$13) are 7-byte mode-0 entries with an unused trailing $00.
- Doraemon's noise tracks all start with `$F0 $20`, an instrument that doesn't exist (the table has 26 entries). It is harmless, because noise tracks skip `$F0`.

## 6. Output and SFX

**`Sound_Output`, no SFX running.** If `wSndPanFlag`=1, NR51 = `wSndPan`. Then, per music track, the action depends on the status:

| Status | Action |
|---|---|
| 6 → 2 | key on: ch1 writes NR10–NR14; ch2 and ch4 write NRx1–NRx4 |
| 5 → 1 | release: NRx2 = shadow & $0F (volume 0) and NRx4 = shadow (retrigger) |
| 4 → 0 | end: NRx2=8, NRx4=$80, one track fewer; at 0, `wSndMusicId`=$FF |

Ch3 is handled differently:
- **Key on.** If NR52 says ch3 is still on, only NR33 and NR34 & $7F are written: a legato pitch change with no retrigger. Otherwise the driver writes NR31–NR33, then NR30=$80, then NR34.
- **Release and end.** NR30=0.

**SFX running** (`wSndSfxTracks` ≠ 0):
- On the first Output, NR51 = `wSndPan` | $99, so ch1 and ch4 are on both sides.
- Music ch1 and ch4 keep parsing, but their status is forced to 1. They write nothing, and their envelopes stop.
- SFX ch1 and ch4 are output like music tracks.
- When the last SFX track ends, `wSndPanFlag`=1 restores the music's NR51.
- Music ch1/ch4 **stay silent until their next note row**. A held note is not restored.

`Sound_Init` leaves `wSndSfxTracks`=2 with both SFX tracks ending, so the very first Output takes the SFX path. This is harmless.

### v1 → v2 differences (Doraemon → Dragon Slayer)

| | Doraemon (v1) | Dragon Slayer (v2) |
|---|---|---|
| Struct size | $1E | $20 (adds `TRK_START`) |
| `$FE` | NR51 (unused) | restart track |
| `$E1` with n = 0 | endless loop | single pass |
| Volume steps (mode 1) | 8 | 4 |
| Song start | reads the pointer once | reads its high byte with `ld a,[hld]` and re-reads the pointer for `TRK_START` |

Everything else is identical, including the dead `ld a,$05` before `ld a,$04` in SndPlayMusic.

## 7. Sound tables

| | Doraemon | Dragon Slayer |
|---|---|---|
| Music ids | 22 ($00–$15), each with its own header; 4 tracks on most, 3 on $01/$07/$08/$09, 2 on $14/$15 (ch1 + ch4) | 21 ($00–$14) but only 11 headers. Ids $00–$05, $07, $09, $0A, $0D, $0E all point to `Music00` |
| SFX ids | 12 ($00–$0B) | 15 ($00–$0E) |
| Instruments | 26 | 20 (2 empty) |
| Drums | 12 | 12 |
| Unreferenced data | none | none |

The data is laid out in groups of headers, each group followed by its length tables and tracks. Every byte between the tables is reached from a header.

## 8. Files

In `GBAudioLab\Epoch1\`:

| File | Contents |
|---|---|
| `Doraemon_sound.asm` | bank 7 $4000–$5AB5: driver v1, tables, all music and SFX |
| `DragonSlayer_sound.asm` | $7038–$7FFD (bank 1 in RGBDS terms): driver v2 + data |
| `epoch_sound.inc` | EQUs only: sound register names and `TRK_*` struct offsets |
| `tools\epoch_gen.py` | generator for both .asm files (`python epoch_gen.py dora > Doraemon_sound.asm`) |
| `tools\epoch_cfg.py`, `epoch_parse.py`, `epoch_align.py`, `sm83.py` | addresses per game, data walker, code alignment, SM83 disassembler |
| `tools\epoch_verify.py` | assembles both files and compares them with the ROMs |
| `tools\epoch_model.py`, `epoch_pyboy_check.py`, `harness.asm` | the Python model and the PyBoy test |

**No macros** are used. Code uses plain instructions with EQU names, and data is plain `db`/`dw`. Every data row has a comment, for example:

```
db $36, $2C            ; L3 (12f) E4
db $4B                 ; L4 (6f) -5 B3
db $E0, $06             ; loop start: 6 passes
```

Code lines end with their ROM address. The seven entry points are exported (`::`).

**Byte-identical** with RGBDS 1.0.0:

```
rgbasm -o dora.o Doraemon_sound.asm
rgblink -p 0xFF -o dora.gb dora.o       ; compare bank 7 $4000-$5AB5
```

| File | Bytes checked | Mismatches |
|---|---|---|
| Doraemon | 6,838 | 0 |
| Dragon Slayer | 4,038 | 0 |

**PyBoy test.** `harness.asm` links the reassembled driver into a small ROM. It calls Output and Update in a loop, and a hook compares all driver RAM (globals and the 6 structs) after every iteration with `epoch_model.py`.

| Run | Length |
|---|---|
| every music id | 3,000 ticks |
| every SFX | 600 ticks |
| music 00 with each SFX started on top | 900 ticks |

Both games had **0 mismatches**. To build and run the test:

```
rgbasm -I .. -o h.o harness.asm
rgbasm -I .. -o s.o ..\Doraemon_sound.asm
rgblink -o h.gb h.o s.o
rgbfix -v -m MBC1 -p 0xFF h.gb
python epoch_pyboy_check.py dora h.gb
```
