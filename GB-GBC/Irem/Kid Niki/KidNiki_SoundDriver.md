# Kid Niki (GB): sound driver

ROM: `Kid Niki (J).gb` (DMG, MBC1, 64 KB, internal title `KID NIKI`, licensee `$49` Irem).

The older of the two Irem drivers studied here; Hammerin' Harry's "Ver 6.04" is a direct descendant (see `Irem_SoundEngine_Family.md`). It is a very small driver: **two sets of four tracks** (SFX and music), **one row per tick count**, every row retriggers its note, no envelopes, no vibrato, no slides. Hardware envelopes, CH3 waves and NR51 masks are the only "instruments".

| | |
|---|---|
| API | the game writes an id to `wSfxReq` `$C80E` or `wMusReq` `$C81E` directly (no ROM0 call); `KN_SndReset` ROM0 `$130E` (fade out, clear `$C800-$C8FF`, silence, fade in) |
| Tick | **VBlank**: the game's VBlank code selects bank 1 (`rst $08`) and calls `KN_SndUpdate` bank 1 `$7E50` (ROM0 `$01AC`), once per frame |
| Driver code | bank 1 `$7A00-$7C35` and `$7E50-$7EB7` (0.7 KB) |
| Data | bank 1 `$6600-$74F3` (streams), `$7B30` command table, `$7D00` sound table, `$7E00` waves, `$7F00` periods; `$4000-$65FF` is other game data |
| RAM | `$C800-$C891`: SFX tracks `$C800 + n×$10`, music tracks `$C840 + n×$10`, globals inside unused track fields |
| Channels | CH1-CH4 in both sets; an SFX track owns its channel whenever it is on |
| Counts | 32 ids `$00-$1F` (8 bytes each): SFX `$01`, `$02`, `$0D-$1F`; songs/jingles `$03-$0C` |

`KN_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over ROM0 `$130E-$1380` and bank 1 `$6600-$7FFF`, cleanly with `-Wall`.

```
rgbasm -Wall -o kn.o KN_SoundDriver.asm
rgblink -p 0xff -o kn.gb kn.o
python tools/cmp_ranges.py kn.gb "Kid Niki (J).gb" 0:130E-1380 1:6600-7FFF
```

---

## 1. Structure

### 1.1 Tracks

| Set | Tracks | Request | Channel order |
|---|---|---|---|
| 0, SFX | `$C800`, `$C810`, `$C820`, `$C830` | `wSfxReq` `$C80E` | CH1, CH2, CH3, CH4 |
| 1, music | `$C840`, `$C850`, `$C860`, `$C870` | `wMusReq` `$C81E` | CH1, CH2, CH3, CH4 |

| Field | Name | Use |
|---|---|---|
| `$0` | `TRK_SPEED` | ticks per row; **0 = track off** (also the "on" flag) |
| `$1` | `TRK_TICK` | counts up to `TRK_SPEED`; 0 = the row was read this update |
| `$2` | `TRK_PTR` | stream pointer (word) |
| `$4` | `TRK_RET` | `$85` return address (word, one level only) |
| `$6` | `TRK_INCALL` | 1 inside a `$85` call |
| `$7` | `TRK_NR10` | CH1 sweep |
| `$8` | `TRK_NRX1` | NRx1 (duty/length; CH3: NR31) |
| `$9` | `TRK_NRX2` | NRx2 (envelope; CH3: NR32 level) |
| `$A` | `TRK_NOTE` | note (period index), `$89` = hold; CH4: the NR43 byte |
| `$B` | `TRK_TRANSP` | added to the note |
| `$C` | `TRK_NRX4` | ORed into NR14/NR24 (`$40` = length enable) |

Fields `$D-$F` are unused; the globals live there: `wSfxReq` `$C80E`, `wMusPan` `$C80F`, `wMusReq` `$C81E`, `wSfxPan` `$C81F`, and `wCurTrack` `$C890`, `wCurSet` `$C891` (the track being read and its set, used by `$86`).

### 1.2 Requests

`KN_LoadRequest` (`$7A9F`) runs for `wSfxReq` then `wMusReq` at the start of every update: 0 and `$FF` do nothing; any other id is replaced by `$FF` and the four tracks of the set get `TRK_SPEED` = 1, `TRK_TICK` = 0, `TRK_PTR` from `KN_SoundTable + id×8`, `TRK_INCALL` = 0 (the other fields keep their old values). The table offset is computed in 8 bits, so ids `$20-$FF` wrap onto `$00-$1F` (and id 0 can't be requested). There is no priority: a new request always restarts the whole set. When a set ends (`$86` outside a call, §3) its request byte is set back to 0, so the game can poll it.

---

## 2. Timing

### 2.1 Update

`KN_SndUpdate`, once per VBlank (59.7 Hz):

1. load the SFX request, then the music request;
2. step the four SFX tracks, then the four music tracks (`wCurSet` 0/1);
3. NR51 (§2.3);
4. channel output CH1, CH2, CH3, CH4 (§2.2).

### 2.2 Rows and channel output

A track's `TRK_TICK` is incremented every update; when it equals `TRK_SPEED` it is cleared and a **row** is read: bytes are executed until a note (`$00-$7F`) or a hold (`$89`) is stored in `TRK_NOTE`. A started track (speed 1, tick 0) reads its first row on the first update.

Each channel is written by **at most one track per update** (`KN_ChanOwner`, `$7A00`):

- if the SFX track of that channel is on, it owns the channel; it writes only on an update where it read a row whose note isn't `$89`, and **the music track is not written at all while the SFX track is on**, even between the SFX rows;
- otherwise the music track writes on its new rows (again not on `$89`).

A write sets every register of the channel and retriggers:

| Channel | Writes |
|---|---|
| CH1 | NR10 = `TRK_NR10`, NR11 = `TRK_NRX1`, NR12 = `TRK_NRX2`, NR13/NR14 = period, NR14 \|= `TRK_NRX4` \| `$80` |
| CH2 | NR21-NR24 the same way |
| CH3 | **NR30 = `$80` every update** (written or not); NR31 = `TRK_NRX1`, NR32 = `TRK_NRX2`, NR33/NR34 = period, NR34 \|= `$C0` (`TRK_NRX4` ignored) |
| CH4 | NR42 = `TRK_NRX2`, NR43 = `TRK_NOTE`, NR44 = `$80` (NR41 never written) |

The period is `KN_PeriodTable[(TRK_NOTE + TRK_TRANSP) × 2]`, the index computed in 8 bits (§5).

So every row is a new note with a fresh hardware envelope; `$89` lets the previous note ring on (its envelope or length runs on).

### 2.3 NR51

`NR51 = wMusPan | (any SFX track on ? wSfxPan : 0)`, written every update. "Any SFX track on" is the 8-bit sum of the four SFX `TRK_SPEED` bytes. The songs set `wMusPan` with `$8A`, the SFX set `wSfxPan` with `$8F`; neither is cleared when a sound ends.

---

## 3. Data format

| Byte | Meaning |
|---|---|
| `$00-$7F` | note (period index, `C_2` = 0 … `B_7` = 71); CH4: the NR43 value. Ends the row |
| `$80 x` | `TRK_NRX1` = x |
| `$81 x` | `TRK_NR10` = x |
| `$82 x` | `TRK_TRANSP` = x |
| `$83 x` | `TRK_NRX2` = x |
| `$84 x` | nothing (argument skipped; not in the data) |
| `$85 addr` | call (one level: `TRK_RET` = next byte, `TRK_INCALL` = 1) |
| `$86` | return from a call; **outside a call: ends the whole set** (all four tracks off, the request byte = 0) |
| `$87` | this track off (`TRK_SPEED` = 0) |
| `$88 x` | `TRK_NRX4` = x |
| `$89` | hold: ends the row without a write |
| `$8A x` | `wMusPan` = x |
| `$8B addr` | jump |
| `$8C x` | NR30 = 0, wave RAM = 16 bytes from `KN_WaveTable + x` (CH3 is switched back on by the next update's NR30 write) |
| `$8D x` | nothing (as `$84`; not in the data) |
| `$8E x` | NR50 = x (not in the data) |
| `$8F x` | `wSfxPan` = x |
| `$90-$FF` | `TRK_SPEED` = byte − `$90` (`$90` turns the track off; not in the data) |

The asm writes these as macros (`nrx1`, `nr10`, `transpose`, `nrx2`, `skip84`, `sndcall`, `sndret`, `sndstop`, `nrx4`, `muspan`, `sndjump`, `wave`, `skip8d`, `nr50`, `sfxpan`, `speed n`) and notes as `db C_4, HOLD, …`.

### 3.1 Tables (bank 1)

| Addr | Name | Content |
|---|---|---|
| `$7B30` | `KN_CmdTable` | 16 handlers for `$80-$8F` (low nibble) |
| `$7D00` | `KN_SoundTable` | 32 × 4 stream pointers (CH1-CH4) |
| `$7E00` | `KN_WaveTable` | 5 waves (the data uses offsets `$00` and `$10`) |
| `$7F00` | `KN_PeriodTable` | 72 periods, C2-B7 (the same values as Hammerin' Harry's first 72) |

Two shared streams: `$74F2` = `$86` (used only by id 0) and `$74F3` = `$87` (every unused channel of an id).

---

## 4. Sounds

Lengths in updates (59.7 Hz), from `python tools/iremlen.py kn`.

| Ids | Set | Content |
|---|---|---|
| `$00` | - | four `$86` streams; can't be requested (id 0 = no request) |
| `$01`, `$02`, `$0D`, `$10-$15`, `$17-$1F` | SFX | 1-60 updates, CH1 and/or CH2/CH4; `$1A` loops (a 3-update noise loop); `$02` is a 1-update silent note on CH1 and CH4 |
| `$03-$08` | music | 4-channel loops (loop 320-1760 updates) |
| `$09` | music | 7008 updates, ends |
| `$0A-$0C` | music | jingles, 36-140 updates, end |
| `$0E`, `$0F`, `$16` | SFX data with `$8A` | 44-140 updates (jingle-like SFX that set the music pan) |

In the demo the game requests `wSfxReq` = `$01` and `wMusReq` = `$02`, `$06`, `$0A`.

---

## 5. Quirks and bugs

1. **The SFX track blocks the music on its channel for its whole life**, not only on its rows; a held (`$89`) SFX row neither writes nor lets the music through.
2. **One `$86` ends all four tracks of the set**, even tracks still playing.
3. **Calls are one level deep**: a `$85` inside a call overwrites `TRK_RET`, so the inner `$86` returns to the outer subroutine and the outer `$86` then ends the set (not in the data).
4. **Index arithmetic is 8-bit**: ids wrap at 32; `(note + transpose) × 2` wraps at 128, and indexes 72-127 read the `$FF` fill after the table (period `$FFFF`, i.e. NRx3 = `$FF`, NRx4 = `$FF`).
5. **"Any SFX on" is an 8-bit sum** of the four speeds: speeds adding up to 256 count as "off" for NR51.
6. **CH3**: NR30 = `$80` every update; `$8C` switches the DAC off until the end of the update; `TRK_NRX4` is ignored and NR34 always gets `$C0` (length enabled).
7. **CH4**: NR41 is never written; `TRK_TRANSP` doesn't apply.
8. `KN_SndReset` busy-waits (14 × 127 loop iterations) and clears the whole page `$C800-$C8FF`.
9. Unused: `$84`, `$8D`, `$8E`, speed 0, fields `$D-$F` (except the globals), waves 2-4, id 0.

---

## 6. Verification

- **Byte-exact rebuild** of the ranges above.
- **Rate:** one update per frame in game (1352 updates in 1353 frames).
- **Three-way check per update** (`verify/vrun.py`): on every call of `KN_SndUpdate` in PyBoy the driver RAM `$C800-$C8FF` is copied into (a) a Python transliteration (`tools/knmodel.py`) and (b) a small SM83 interpreter (`tools/cpu.py`) that runs the real ROM code; at the return to ROM0 `$01AF` the RAM of all three must agree byte for byte, and the model's **exact sequence of register writes** must equal the one the ROM code produced (wave RAM included):
  - each id `$01-$1F` alone, first in the SFX set (600 updates) then in the music set (2500 updates), 96,200 updates: **0 mismatches**;
  - three random 12,000-update mixes of SFX and music requests over the game's own sounds and input (`verify/combo*_kn.json`): **0 mismatches**;
  - **unused features**, on a copy of the ROM with test streams in the `$FF` fill at `$74F4` (`verify/patch_test.py`): `$84`, `$8D`, `$8E`, a nested call, notes past the period table, speed 0, wave 4, `$87` on CH3, a noise loop, four SFX speeds summing to 256, ids `$21` and `$29` (wrapping): **0 mismatches**.
- **Not verified:** nothing on hardware or against audio output; the game's own request sites were only sampled.

## Files (in `GBAudioLab\Irem`)

- `KN_SoundDriver.asm` (+ `hardware.inc`): labelled, commented RGBDS source, byte-exact
- `tools/`: `gen_asm.py` + `cfg_kn.py` (generator), `iremdata.py` (stream walker), `iremlen.py` (lengths), `knmodel.py`, `cpu.py`, `sm83.py`, `cmp_ranges.py`
- `verify/`: `vrun.py`, `mkscripts.py`, `patch_test.py`, scripts and logs

Regenerate: `python tools/gen_asm.py kn KN_SoundDriver.asm`.
