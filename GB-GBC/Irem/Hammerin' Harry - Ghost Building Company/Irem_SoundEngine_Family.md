# Irem GB sound driver: Kid Niki and Hammerin' Harry

Two Irem Game Boy games, one driver lineage. **Kid Niki (J)** has an early, minimal version; **Hammerin' Harry: Ghost Building Company (U)** has a later one that names itself **"\*\* Ver 6.04 \*\*"**. Same engine, different versions: Harry's driver is Kid Niki's code extended, with the core routines kept (some rewritten with `jr`/`or a` in place of `jp`/`cp $00`) and new features added around them. Kid Niki's has no version string.

Details: `KidNiki_SoundDriver.md`, `HammerinHarry_SoundDriver.md`.

## What they share

- **Two sets of four tracks** (SFX = set 0, music = set 1, CH1-CH4 each), 16 bytes per track, the music set `$40` above the SFX set; the request bytes and NR51 variables live in unused fields of the first tracks (`$xx0E/$xx1E` in Kid Niki, `$xx0F/$xx1F/...` in Harry).
- **Sound table**: 8 bytes per id, four stream pointers (CH1-CH4); a request restarts all four tracks of its set with speed 1.
- **Row timing**: `TRK_TICK` counts to `TRK_SPEED` (set by a speed byte); each row runs commands until a note or `$89` (hold). One update per VBlank.
- **Output**: a channel is written only on a row of its owner, and the **SFX track owns the channel whenever it is on** (same owner-test routine, `$7A00` / `$4011`); every write sets all the channel's registers and retriggers. CH4's note byte is NR43.
- **Field layout `$0-$B`**: speed, tick, pointer, (return), call state, NR10, NRx1, NRx2, note, transpose; `TRK_NRX4` ORed into NR14/NR24 (and NR44 in Harry); CH3's NR34 always `| $C0`.
- **Commands** with the same meaning: `$80` NRx1, `$81` NR10, `$82` transpose, `$83` NRx2, `$85` call, `$86` return/end, `$87` track off, `$88` NRx4 bits, `$89` hold, `$8A` music pan, `$8B` jump, `$8C` wave (16 bytes copied to wave RAM), `$8F` SFX pan.
- **Period table**: Harry's first 72 entries are Kid Niki's 72 (C2-B7), indexed by `(note + transpose) × 2` in 8 bits. Kid Niki's five waves are Harry's waves 0, 5, 3, 4 and 6.

## What changed

| | Kid Niki | Hammerin' Harry (Ver 6.04) |
|---|---|---|
| Driver size | 0.7 KB code, bank 1 `$7A00`, tables on fixed pages (`ld h,$7D`) | 1.9 KB code, bank 1 `$4000`, 16-bit table lookups |
| Ids | 32 (id × 8 in 8 bits) | 69 (16-bit) |
| Speed bytes | `$90-$FF` | `$91-$FF` (`$90` became a command) |
| `$84` / `$8D` / `$8E` | no-op / no-op / NR50 | NR50 / **software envelope** / **pitch table** |
| `$90` | (speed 0) | **pan mask** |
| Calls | one level (`TRK_RET`, flag) | stack per track at `$DF00` (8 levels) |
| `$86` at top level | ends **all four** tracks of the set | ends **this** track; the request byte clears when all four are off |
| Envelopes / vibrato | hardware envelope only | 8 envelope blocks (15 tables × 8 NRx2 steps, retriggered) and 7 vibrato blocks (10 tables × 24 period offsets), suspended/resumed as the SFX takes and gives back a channel |
| NR51 | `wMusPan \| (SFX on ? wSfxPan : 0)` | `(wMusPan & wPanMask) \| (SFX on ? wSfxPan : 0)` |
| New SFX load | just restarts the set | also resets the channels the old SFX held, clears a frame counter |
| CH3 | NR30 = `$80` every update | NR30 = 0 then `$80` on each note |
| CH4 | NR41 never written | NR41 = `TRK_NRX1`, NR44 = `TRK_NRX4 \| $80` |
| Track fields `$C-$E` | `$C` = NRx4 bits | `$C` last period low, `$D` NRx4 bits, `$E` last NRx4 |
| Game interface | the game writes the request bytes | ROM0 front end with an SFX priority table, re-entry guard, a slow-motion delay |
| PCM | none | 3 voice clips in 5 script opcodes (`$1A`), NR50 modulation at 4228 Hz (one clip can use 6721 Hz), 3-bit RLE bitstream (ROM0 player/decoder) |

Leftover from the old version in Harry: the code of Kid Niki's `$84`/`$8D` no-op (`ld a,[bc] / inc bc / jp ReadByte`) is still at `$4358`, unreferenced, and fields `$4/$5` (Kid Niki's return address) are unused.

## Converting

Both formats are row-based with a constant row length per track (`TRK_SPEED` updates at 59.7 Hz), so a MIDI/MOD converter can treat each note byte as one row: a new note (with its NRx2 envelope) on every non-hold row, `$89` = let ring. `tools/iremdata.py` walks every stream (calls, jumps, channel), `tools/iremlen.py` gives the intro/loop lengths, `tools/knmodel.py` / `tools/hhmodel.py` are verified register-write models (0 mismatches against the ROM code) that a converter can drive directly. In Harry, envelopes (`$8D`) and pitch tables (`$8E`) need the block logic from `hhmodel.py`; notes ≥ 84 and the `wPanMask` interplay are edge cases (see the quirks).
