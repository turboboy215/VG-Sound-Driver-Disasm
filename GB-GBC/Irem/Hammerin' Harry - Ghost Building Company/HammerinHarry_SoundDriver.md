# Hammerin' Harry: Ghost Building Company (GB): sound driver

ROM: `Hammerin' Harry - Ghost Building Company (U).gb` (DMG, MBC1, 256 KB, internal title `GENSAN`, licensee `$49` Irem).

The driver calls itself **"\*\* Ver 6.04 \*\*"** (bank 1 `$4003`). It is Kid Niki's driver grown up (see `Irem_SoundEngine_Family.md`): the same two sets of four tracks, the same row/tick timing, the same "one row = one retriggered note" output and the same command numbering for `$80-$83` and `$85-$8C`, plus:

- **software volume envelopes** (`$8D`, 15 tables of 8 NRx2 steps) and **pitch tables** (`$8E`, 10 tables of 24 period offsets), one block per track, handed between the SFX and the music with the channel;
- a **call stack** per track (calls nest), `$86` ending only its own track;
- a **pan mask** (`$90`) the SFX use to cut the music out of NR51, `$84` = NR50;
- a ROM0 front end with an **SFX priority table**;
- **PCM speech** played through NR50 from the game's script (three voice clips in five opcodes, §6).

| | |
|---|---|
| API | the game writes `hSfxReq` `$FFD1` / `hMusReq` `$FFD3`; `HH_SndVBlank` ROM0 `$0B9F` passes them on (SFX through `HH_SfxPriority`) as `wSfxReq` `$DE0F` / `wMusReq` `$DE1F`; `hCurMusic` `$FFD4` = last music id |
| Tick | **VBlank**: the VBlank handler ends with `jp HH_SndVBlank` (ROM0 `$00CC`, interrupts enabled); bank 1 `$4000` `jp HH_SndUpdate` (`$461F`), once per frame. Skipped while a PCM sample plays (`hTimerVec` ≠ 0) |
| Driver code | bank 1 `$4000-$47F1` (1.9 KB, with small tables inside) |
| Data | bank 1 `$47F2-$4C52` (tables), `$4C53-$7FBE` (streams) |
| ROM0 | `$0B9F-$0C55` glue + priority table, `$2350-$2422` PCM loader/player, `$261A-$268F` PCM decoder; PCM opcodes in bank `$6` `$4000-$4778` and bank `$E` `$402E-$4395`, `$4413-$4DF6` |
| RAM | tracks `$DE00-$DE7F`, globals `$DE0F-$DE91`, vibrato blocks `$DEA0-$DEBB`, envelope blocks `$DEC0-$DEFF`, call stacks `$DF00-$DF7F`; `wSndBusy` `$DFFF`; PCM buffer `$C300` up |
| Counts | 69 ids `$00-$44`: songs `$01-$11`, SFX `$12-$44` |

`HH_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1, cleanly with `-Wall`:

```
rgbasm -Wall -o hh.o HH_SoundDriver.asm
rgblink -p 0xff -o hh.gb hh.o
python tools/cmp_ranges.py hh.gb "Hammerin' Harry - Ghost Building Company (U).gb" 0:0B9F-0C55 0:2350-2422 0:261A-268F 1:4000-7FFF 6:4000-4778 E:402E-4395 E:4413-4DF6
```

---

## 1. Structure

### 1.1 Tracks

| Set | Tracks | Request |
|---|---|---|
| 0, SFX | `$DE00`, `$DE10`, `$DE20`, `$DE30` (CH1-CH4) | `wSfxReq` `$DE0F` |
| 1, music | `$DE40`, `$DE50`, `$DE60`, `$DE70` (CH1-CH4) | `wMusReq` `$DE1F` |

| Field | Name | Use |
|---|---|---|
| `$0` | `TRK_SPEED` | ticks per row; 0 = off |
| `$1` | `TRK_TICK` | 0 = the row was read this update |
| `$2` | `TRK_PTR` | stream pointer |
| `$6` | `TRK_DEPTH` | call depth (return addresses at `wCallStack` `$DF00` + track + 2 × level) |
| `$7` | `TRK_NR10` | CH1 sweep |
| `$8` / `$9` | `TRK_NRX1` / `TRK_NRX2` | NRx1, NRx2 (CH3: NR31, NR32) |
| `$A` | `TRK_NOTE` | period index, `$89` hold; CH4: NR43 |
| `$B` | `TRK_TRANSP` | added to the note |
| `$C` | `TRK_PERLO` | the period low byte last computed (the vibrato adds to it) |
| `$D` | `TRK_NRX4` | ORed into NRx4 (`$40` = length enable) |
| `$E` | `TRK_LASTNRX4` | the NRx4 value last computed (the envelope retriggers with it) |
| `$F` | | globals: `wSfxReq`, `wMusReq`, `wMusPan` `$DE2F`, `wSfxPan` `$DE3F`, `wPanMask` `$DE4F`, `wSndFrame` `$DE5F`, `wSfxEndFrame` `$DE6F/$DE7F` (+ `$DE8F`, `$DE9F`) |

`wCurTrack` `$DE90`, `wCurSet` `$DE91`. Fields `$4/$5` are unused (Kid Niki's return address).

### 1.2 Envelope and vibrato blocks

One per track, indexed by track number k (0-3 SFX CH1-CH4, 4-7 music CH1-CH4):

| | Envelope `wEnv` `$DEC0 + 8k` | Vibrato `wVib` `$DEA0 + 4k` (k = 0-6) |
|---|---|---|
| +0 | flags: bit 7 on, bit 0 suspended | flags: bit 7 on, bit 0 suspended |
| +1 | rate | table |
| +2 | wait counter | step (0-23) |
| +3 | step (0-7) | unused |
| +4 | table | |
| +5 | `$8D` argument & 15 (never read) | |

The command sets the flags to `$81` (or `$01` for argument 0 = off): **suspended until the next note write**. Every channel write clears bit 0 of the owning set's blocks for that channel (and resets envelope wait/step and vibrato step to 0) and sets bit 0 of the other set's (§2.3). So an envelope or vibrato restarts on every note, and an SFX freezes the music's blocks on its channel.

### 1.3 Requests

`HH_SndVBlank` (ROM0, each VBlank): returns at once while a PCM sample plays or if it is already running (`wSndBusy`). A game SFX request is taken when no SFX is pending/playing (`wSfxReq` = 0) or when its `HH_SfxPriority` value is **≤** the current one's (`hSfxPrio`): lower values win, equal values replace. A music request is always taken. Both bytes are cleared, bank 1 is selected, `hCurMusic` is updated, and the driver runs (after a 4096-iteration delay when `wSlowMo` `$DFFD` and `$DFFE` are both set).

`HH_LoadRequest` (bank 1 `$41D5`), SFX then music, at the start of the update: 0/`$FF` nothing; else `$FF` is stored, and for an SFX `wSndFrame` and the end stamps are cleared and `HH_SilenceSfxChans` resets every channel an old SFX still holds (§4). The four tracks get speed 1, tick 0, depth 0 and the pointers from `HH_SoundTable + id × 8` (16-bit, no wrap).

---

## 2. Timing

### 2.1 Update

`HH_SndUpdate`: `wSndFrame` += 1; requests; the four SFX tracks then the four music tracks; NR51; CH1, CH2, CH3, CH4 output (each with its ownership hand-over); envelopes; vibratos. 59.7 Hz.

### 2.2 Rows and channel output

As in Kid Niki: `TRK_TICK` counts to `TRK_SPEED`, then commands run until a note or `$89`. A channel is written by the SFX track whenever it is on (only on its rows, not on holds) and by the music track only when the SFX track is off.

| Channel | Writes |
|---|---|
| CH1 | NR10, NR11, NR12, NR13 = period low (→ `TRK_PERLO`), NR14 = period high \| `TRK_NRX4` \| `$80` (→ `TRK_LASTNRX4`) |
| CH2 | NR21-NR24 the same way |
| CH3 | NR30 = 0 then `$80`, NR31, NR32, NR33 (→ `TRK_PERLO`), NR34 = high \| `$C0` |
| CH4 | NR41 = `TRK_NRX1`, NR42, NR43 = `TRK_NOTE`, NR44 = `TRK_NRX4` \| `$80` (→ `TRK_LASTNRX4`) |

Period = `HH_PeriodTable[(note + transpose) × 2]` (8-bit index).

### 2.3 Hand-over

After a write by an SFX track: its channel's SFX envelope/vibrato blocks lose bit 0 and restart, the music blocks get bit 0. After a write by a music track: the reverse. CH3 has only vibrato blocks, CH4 only envelope blocks in this hand-over. When an SFX track ends with `$86`, `HH_TrackCleanup` turns its blocks off (`$01`) and clears bit 0 of the music blocks (if on), restarting the music envelope's wait; a music track's end turns its blocks off.

While the music's CH1, CH2 or CH4 envelope is on, its period/NRx4 copies are recomputed on its rows even under an SFX (`HH_Ch1Shadow` etc.), so the envelope retriggers the current note when it resumes.

### 2.4 Envelopes (`HH_EnvTick`)

For each block that is on: if the wait counter isn't 0 it counts up to `rate` and then back to 0; when it is 0 and the block isn't suspended, `NRx2 = HH_EnvTables[table × 8 + step]` is written **with a retrigger** (CH1: NR10-NR14, CH2: NR21-NR24, CH4: NR41-NR44, using `TRK_PERLO`/`TRK_LASTNRX4`/`TRK_NOTE`; CH3: nothing), skipped when the value is 0; then the step advances (and the wait = 1) until step 7, which is applied again every update (all 15 tables end with 0 there, so nothing is written). So a step lasts `rate + 1` updates.

### 2.5 Vibrato (`HH_VibTick`)

For blocks 0-6 that are on and not suspended: `NRx3 = TRK_PERLO + HH_VibTables[table × 24 + step]` (no carry, no retrigger); the step advances 0 → 23, then loops 12-23 (suspended blocks advance too).

### 2.6 NR51

`NR51 = (wMusPan & wPanMask) | (SFX on ? wSfxPan : 0)`, "SFX on" = (speed0 + speed1 + speed2) | speed3. The songs set `wMusPan` (`$8A`) and `wPanMask` = `$FF` (`$90`); the SFX set `wSfxPan` (`$8F`) and usually `wPanMask` (e.g. `$EE`: the music's CH1 left out while the SFX holds CH1), then `$8F $00`/`$90 $FF` on their last row.

---

## 3. Data format

| Byte | Meaning |
|---|---|
| `$00-$7F` | note (C2 = 0 … B8 = 83); CH4: NR43. Ends the row |
| `$80 x` / `$81 x` / `$82 x` / `$83 x` | `TRK_NRX1` / `TRK_NR10` / `TRK_TRANSP` / `TRK_NRX2` |
| `$84 x` | NR50 = x (not in the data) |
| `$85 addr` | call (nested, stack of 8 per track) |
| `$86` | return; at depth 0: this track ends (clean-up, request byte = 0 when all four tracks of the set are off; SFX: end stamp) |
| `$87` | this track off (no clean-up) |
| `$88 x` | `TRK_NRX4` |
| `$89` | hold |
| `$8A x` | `wMusPan` |
| `$8B addr` | jump |
| `$8C x` | NR30 = 0, wave RAM = `HH_WaveTable + x` (16 waves) |
| `$8D x` | envelope: preset `HH_EnvPresets[x & 15]` = table << 4 \| rate; x = 0 off |
| `$8E x` | vibrato: table x & 15 (10 tables), x = 0 off; the step is not reset here |
| `$8F x` | `wSfxPan` |
| `$90 x` | `wPanMask` |
| `$91-$FF` | `TRK_SPEED` = byte − `$91` |

Macros in the asm: `nrx1 nr10 transpose nrx2 nr50 sndcall sndret sndstop nrx4 muspan sndjump wave envelope vibrato sfxpan panmask speed`; notes `db C_4, HOLD`.

### 3.1 Tables (bank 1)

| Addr | Name | Content |
|---|---|---|
| `$426E` | `HH_CmdTable` | `$80-$90` |
| `$446C` | `HH_EnvApplyTable` | per block: CH1, CH2, none, CH4 |
| `$450F` | `HH_WaveTable` | 16 waves |
| `$460F` / `$4617` | `HH_VibPerField` / `HH_VibNRx3` | per vibrato block: `TRK_PERLO` address, NRx3 (`$13 $18 $1D $1D` ×2) |
| `$46B5` | `HH_CleanupTable` | 8 track clean-ups |
| `$47F2` | `HH_PeriodTable` | 84 periods C2-B8 |
| `$489A` | `HH_VibTables` | 10 × 24 signed deltas: 0 ramp +2…+48, 9 ramp −2…−48, 6 and 8 falls to −128 / −92 then held, 1/3/5/7 vibratos ±2/±3/±6/±12, 2/4 the same ±3/±6 after 12 flat steps |
| `$498A` | `HH_VibIndex` | table × 24 |
| `$4994` | `HH_EnvTables` | 15 × 8 NRx2 values |
| `$4A0C` | `HH_EnvPresets` | 15 bytes (+ the first of the next table as preset 15 = table 0, rate 0) |
| `$4A1B` | `HH_EnvIndex` | table × 8 |
| `$4A2B` | `HH_SoundTable` | 69 × 4 stream pointers |

`$4C53` (`$86`) is id 0's stream, `$4C54` (`$87`) every unused channel. Ten orphan streams (no pointer reaches them, e.g. `$51EF`, `$7F9E`) are decoded in the asm as `HH_Orphan_xxxx`; `$7FBF-$7FFF` is leftover non-`$FF` bytes.

---

## 4. Sounds

Lengths in updates, from `python tools/iremlen.py hh`.

| Ids | Content |
|---|---|
| `$00` | `$86` ×4; can't be requested |
| `$01` | 2-update silence (all four channels); requested in both sets before and after PCM |
| `$02`, `$03`, `$0B`, `$0E`, `$0F` | songs/jingles that end (79-1416 updates) |
| `$04-$0A`, `$0C`, `$0D`, `$10` | looping songs (track loops of 56-2912 updates) |
| `$11` | ~5100 updates, then short loops (56-448) |
| `$12-$44` | SFX, 8-569 updates; ids `$14`, `$2B`, `$2C`, `$38`, `$3C`, `$3D` noise only |

`HH_SfxPriority` (lower = stronger): `$01` 0, `$20` 1, `$1F` 2, `$15` 3, `$17` 8 … `$26 $35 $3B $41 $42 $44` `$70`; music ids `$02-$11` have `$FE`, id 0 `$FF`.

When an SFX loads while another one holds channels, `HH_SilenceSfxChans` resets them: CH1 NR10 = 8, NR11 = `$3F`, NR12 = 8, NR13 = 0, NR14 = `$C0` (CH2, CH4 alike; CH3 NR30 = 0) and the track's fields 7-E to 8, `$3F`, 8, 0, 0, 0, `$40`, `$C0`.

---

## 5. Quirks and bugs

1. **An SFX blocks the music on its channel for its whole life**; after it ends, the channel keeps the SFX's last note until the music's next row.
2. **`wPanMask` is only restored by the SFX itself**: an SFX cut off by another SFX before its last row leaves its mask until some stream sets it again (the songs set `$FF`).
3. **"SFX on" for NR51 mixes `add` and `or`** (8-bit sum of three speeds, OR the fourth).
4. **The SFX CH4 vibrato block never runs**: nothing ever clears its bit 0 (CH4 writes only hand over envelope blocks); if it did, it would write NR33 from `$DE3C`. The music CH4 has no vibrato block, CH3 no envelope (the CH3 envelope blocks step but write nothing).
5. **The vibrato changes only the low byte** of the period (no carry into NRx4), so large deltas wrap within 256 periods.
6. **Index arithmetic**: `(note + transpose) × 2` wraps at 128; notes 84-127 read `HH_VibTables` as periods; ids ≥ `$45` read stream bytes as pointers.
7. **Call stacks are 16 bytes per track**: more than 8 levels overwrite the next track's stack (the data goes 5 deep).
8. **`$87` skips the clean-up**: the other set's blocks stay suspended until its next note.
9. **Dead code**: `HH_UnusedSkipArg` (`$4358`, Kid Niki's `$84`/`$8D` no-op) has no table entry; the envelope's argument field and the vibrato's 4th byte are never read; envelope rate 0 makes 256-update steps (preset 15, not in the data); `$84`, `$87` (except the empty stream) are not in the data.
10. `wSndFrame`/`wSfxEndFrame` are maintained (cleared by every SFX load) but not read by the driver.
11. The update runs with interrupts enabled in the VBlank handler; `wSndBusy` guards against re-entry. With `wSlowMo` set, every update is preceded by a 4096-iteration busy loop.

---

## 6. PCM

### 6.1 Playback

Opcode `$1A` of the game's script interpreter (ROM0 `$2344`, table at `$221F`) is `HH_ScriptPlayPCM` (`$2350`). The script continues with a **negative 16-bit sample count** and the bitstream:

1. the stream is decoded (`HH_PCMDecode`) into one byte per sample at `$C300` up, each 3-bit level v stored as `v × $11` (an NR50 value, both sides), and `$FF` is appended;
2. SFX 1 and music 1 (silence) are requested, and it waits until the driver has taken them and the music has ended;
3. `HH_PCMStart` (`$238F`): `hTimerVec` = `HH_PCMTimerISR`, `wSfxReq` = `wMusReq` = 1 (so the driver silences both sets after the sample), APU off/on with wave RAM all `$FF`, all four channels set to constant output (CH1/CH2 duty 50 % at period 0, CH3 level 100 %, CH4 NR42 = `$20`), NR51 = `$FF`, and the timer interrupt enabled; it waits until the ISR clears `hTimerVec`, then NR50 = `$77`.

`HH_PCMTimerISR`, on every timer overflow (TAC = 5, TMA = `$C2`: 262144 / 62 = **4228 Hz**, PyBoy runs it 70 times per frame; the script can change TMA first, see §6.3): NR50 = next byte, NR43 = `$D0`, and NR14/NR19/NR1E/NR23 = `$C0` (retrigger, so the outputs stay constant); on `$FF`: NR50 = 0, APU off and on, `hTimerVec` = 0, NR50 = `$77`. The **master volume is the sample**: 8 levels, level 0 still 1/8 of full scale. The sound driver doesn't run while a sample plays.

### 6.2 Bitstream

MSB first. `hPCMLast` (L) starts at 0:

| Code | Output |
|---|---|
| `1` | L |
| `0 vvv` (v ≠ L) | v |
| `0 LLL vvv` (v ≠ L) | v, and L = v |
| `0 LLL LLL nnnn vvv` | v, then the next 11 + n values are raw `vvv` |

### 6.3 Samples

Five `$1A` opcodes, found by walking every script reachable from the game's script calls (`tools/hhscript.py`: it follows calls into other banks, jumps, conditional jumps and the `$1C` jump tables, runs the graphics-decompression opcodes in `tools/cpu.py` to get their lengths, and stops at `$00`/`$12`). Three of them play back to back as one clip, so the game has three clips:

| Label | Addr | Samples | Seconds | Script |
|---|---|---|---|---|
| `HH_PCM_0E_4413` | `E:4413` | 1568 | 0.371 | E:43B3: NR50 faded `$66` → 0 with `$02 $24 xx` steps, then the three opcodes back to back (one clip; plays in the attract demo, PyBoy frames 791-883) |
| `HH_PCM_0E_468F` | `E:468F` | 1456 | 0.344 | |
| `HH_PCM_0E_48C6` | `E:48C6` | 3488 | 0.825 | then `$12` (return) |
| `HH_PCM_06_4000` | `6:4000` | 5856 | 1.385 | one opcode, called through E:4DF8 (from scripts E:766C, 09:69C4, 0D:55AD); a 0.385 s silence at 0.46 s splits it in two |
| `HH_PCM_0E_402E` | `E:402E` | 2400 | 0.568 (0.357 at 6721 Hz) | E:4023: when hFFA4 = `$0C`, `$02 $06 $D9` sets **TMA = `$D9` (6721 Hz)** first; `$02 $06 $C2` restores it afterwards |

These are the only script writes to TMA, so every other opcode plays at 4228 Hz.

`python tools/hhpcm.py <rom> pcm` writes 8-bit WAVs: the five opcodes, `HH_PCM_0E_4413-48C6_joined.wav` (the three parts joined), and `HH_PCM_0E_402E_6721Hz.wav`.

---

## 7. Verification

- **Byte-exact rebuild** of all seven ranges.
- **Three-way check per update** (`verify/vrun.py`), as for Kid Niki: PyBoy's RAM `$DE00-$DFFF` at each call of bank 1 `$4000` seeds the transliteration `tools/hhmodel.py` and the SM83 interpreter `tools/cpu.py` running the ROM code; at the return to ROM0 `$0C00` all three RAMs must agree and the model's register-write sequence must equal the ROM code's:
  - each id `$01-$44` alone in the SFX set (600 updates) and in the music set (2500 updates), 210,900 updates: **0 mismatches**;
  - three random 12,000-update mixes with the game's own sounds and input: **0 mismatches**;
  - **unused features** on a patched copy (test streams in `$7FBF-$7FEE`, id `$44` repointed; `verify/patch_test.py`): `$84`, three nested calls, a note past the period table, envelope and vibrato on CH3 and CH4, envelope preset 7 on CH1: **0 mismatches**.
- **PCM** (`verify/vpcm2.py`): for all five opcodes, `tools/hhpcm.py`'s decoder, the ROM decoder run in `tools/cpu.py` and the buffer PyBoy builds at `$C300` agree byte for byte (PyBoy: the game's first PCM call is redirected to each opcode in turn); each stream ends where its script continues.
- **Not verified:** nothing on hardware or against audio; the pause code (`$0C56`, plays SFX `$20` and sets NR50 = `$11`) and `wSlowMo` were only read.

## Files (in `GBAudioLab\Irem`)

- `HH_SoundDriver.asm` (+ `hardware.inc`): labelled, commented RGBDS source, byte-exact
- `pcm/`: the WAVs (§6.3)
- `tools/`: `gen_asm.py` + `cfg_hh.py`, `iremdata.py`, `iremlen.py`, `hhmodel.py`, `hhpcm.py`, `hhscript.py`, `cpu.py`, `sm83.py`, `cmp_ranges.py`
- `verify/`: `vrun.py`, `vpcm.py`, `vpcm2.py`, `mkscripts.py`, `patch_test.py`, scripts and logs

Regenerate: `python tools/gen_asm.py hh HH_SoundDriver.asm`.
