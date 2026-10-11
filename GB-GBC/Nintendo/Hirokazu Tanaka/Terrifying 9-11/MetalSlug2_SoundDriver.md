# Metal Slug 2 (unlicensed GBC): sound driver

The sound code of the unlicensed *Metal Slug 2* (`Metal Slug 2 (Unl) [C][f1].gbc`, 2 MB) is in banks `$28` (music) and `$29` (SFX), with variables at `$C800–$C8FF`. Both banks rebuild **byte-exact** from the sources in `Nint1\MS2`.

**Short answer on its origin.** It is derived from **Link's Awakening DX**, not from *SMB Deluxe*:
- the SFX bank is LA DX's SFX bank copied **as binary**. Some absolute pointers were not relocated and still hold LA's addresses (§2.2);
- the music bank keeps LA DX's engine (RAM layout, channel loop, effects, tables) around a **new sequencer with a new song format**.

```
MS2\build_check.sh   MS2\harness\build.sh   MS2\harness\verify.py
python MS2\gen_ms2.py <ms2 rom> <la dx rom> MS2      (the SFX names come from the LA DX bank)
```

**Calls** (home `$0490–$04B0`): `$28:$4001` (music update) then `$29:$4001` (SFX update) every frame. `$28:$4004` = init, `$28:$4007` = stop. Each bank starts with a tag byte (`$1D`, `$1E`) before its stubs.

---

## 1. Music (bank `$28`)

### 1.1 What is LA's

- The RAM layout is LA's moved from `$D300` to `$C800`. The request bytes are at `$C860/$C868/$C870/$C878`.
- The channel loop and effects are LA bank `$1B`'s: vibrato after 24 frames, detune, drop −100, ch3 fade-out / fade-in, release envelopes with LA's values. Most `jr` became `jp`.
- So are the music drum, `StopSfx4`, `Sound_Stop` / `Sound_StopMusic` / `Music_ClearState`, the note table and the vibrato table.
- The noise table is LA bank `$1E`'s (12 entries). LA's length tables follow it, unused, the last one missing its final byte.
- Unreferenced LA routines remain: `LoadWave`, `Music_Stop`, `CopyWordIndirect`/`CopyWord`, the `$9D` handler, `IncPtr2`.

### 1.2 What is new

- **Song table** `$4A28`: songs 1–10. A new request first re-initialises all sound RAM and the APU.
- **Header**: `channels − 1`, then per channel `STREAM channel, address` (bit 15 of the address masked off). Every song uses ch1–ch3; no song uses ch4.
- **Streams** (byte code; channel state: octave, speed, transpose, mark):

| Byte | Macro | |
|---|---|---|
| `$00–$BF` | `NsxL` | note: high nibble = semitone 0–11, low nibble = length − 1. Frames = (speed + 1) × length. `NoteTable[(5 − octave) × 12 + semitone + transpose]` |
| `$C0–$CF` | `RL` | rest |
| `$D0–$DF a b c` | `INSTR speed, env, release, duty` | ch3: env = byte offset into `WaveTable` (10 waves) |
| `$E0–$E5` | `OCTAVE n` | |
| `$E6 n` | `SPEED n` | |
| `$E7` / `$E8` / `$E9` | `CH3_FADEOUT_ON` / `CH3_FADES_OFF` / `CH3_FADEIN_ON` | |
| `$EA n` | `TRANSPOSE n` | semitones, signed |
| `$EB` / `$EC` | `DROP_ON` / `_OFF` | one flag for all channels |
| `$ED` / `$EE` | `CH3_SFX_PAUSE` / `_RESUME` | |
| `$EF v a` | `POKE v, $C8a` | write a byte into sound RAM |
| `$FB` / `$FE n` | `MARK` / `REPEAT_MARK n` | go back to the mark n more times |
| `$FD addr` | `JUMP` | only the low byte of the operand pointer is incremented (`inc c`); no operand crosses a page |
| other `$F0+` | `END_SONG` | stops the music |

Every stream ends with a `JUMP` (loop) or a stop, followed by one `$00` that is never read. 30 stream segments, 4,137 events.

`$6010–$775F` in the music bank is **not sound data**: 2bpp tiles of a 1bpp font (`$FF` in every other byte).

---

## 2. Sound effects (bank `$29`)

### 2.1 LA's SFX bank, renumbered

3,304 of the 3,329 traced instructions align with LA DX bank `$1F`. The changes:
- RAM moved to `$C800`;
- the ch4 low-health check became a `ret`;
- the DX volume / HRAM code and the nop slide are gone. `Sound_Stop` still ends with LA DX's `rP1` write, now followed by `ret`;
- **renumbered tables** (65 / 35 / 61 effects). Each effect in the source carries a comment naming the LA effect it came from:

| MS2 | LA DX |
|---|---|
| ch1 `$01–$0F`, `$11`, `$12` | same numbers |
| ch1 `$10` | new: init and play are both `ret` (LA `$10` dropped) |
| ch1 `$13–$41` | LA `$12–$40` (LA `$12` appears twice) |
| ch3 `$01–$23` | same numbers |
| ch4 `$01–$20` | same numbers |
| ch4 `$21–$3D` | LA `$22–$3F` without `$21` and `$3C`; `$37`/`$38` = LA `$39`/`$38` |

### 2.2 Pointers left at LA's addresses

These are absolute references whose value is still LA's. In MS2's layout they point at unrelated bytes. The source writes them as raw numbers with a comment:

| MS2 | Value | In LA | In MS2 |
|---|---|---|---|
| ch1 effect `$33` play, `$4DA5` | `jp z, $53B5` | `Sfx1_StopWithRegs` | inside `Sfx3_PlayTable`: the CPU would execute table bytes |
| ch3 effect 3, `$5485` | `ld hl, $63CC` | `SfxWave_63CC` | inside `Sfx4_PlayTable`: loads table bytes as the wave |
| ch3 effect `$21` end, `$5D53` | `ld hl, $7A20` | `Sfx4_StopRegs` | inside `Sfx1_AddPitch` |
| ch4 effect `$2D` table, `$702D` | 11 `dw` | LA `Sfx4_2E`'s step pointers | unrelated bytes |

The code was copied from the LA binary (not reassembled from source) and relocated by hand or by a tool that missed these.

---

## 3. Verification

- **Byte-exact rebuild** of both banks.
- **Emulator harness** (PyBoy, game order, WRAM mailboxes). Songs 1–10, 3,600 frames each: 11,105 stream reads, **0** outside the parsed streams.
- The effect play check (`verify.py`, second half) has not been completed: in this session the run stalled, probably on one of the broken effects in §2.2. The SFX bank is verified by the byte-exact rebuild and the alignment with LA only.
- **Not verified:** what the 10 songs are; hardware.
