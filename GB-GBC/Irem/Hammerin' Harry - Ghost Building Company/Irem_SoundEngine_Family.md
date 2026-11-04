# Irem/Tamtex GB sound driver: Shisensho, Lenar, Kid Niki, Hammerin' Harry

One driver lineage across six Game Boy games:

| Version | Games | Notes |
|---|---|---|
| **Tamtex** (closest to the original) | Shisensho: Match-Mania (J) (Irem / Tamtex, released mid-1990; title screen "© 1990 IREM CORP. © 1989 TAMTEX") | 32 KB ROM, driver at `$7AF0`, `$DFxx` RAM; see `Shisensho_SoundDriver.md` |
| **Lenar branch** | Mercenary Force (UE) (code dated "LIVE PLANNING AT 1990"), Knight Quest (U) (Taito, 1991) | bank 3, `$DFxx` RAM; Shisensho's code with Lenar's own changes; see `Lenar_SoundDriver.md` |
| **Irem: Kid Niki** | Kid Niki (J) (Irem, 1991) | bank 1, `$C8xx` RAM; Shisensho's code with features added; see `KidNiki_SoundDriver.md` |
| **Irem: Ver 6.04** | Hammerin' Harry: Ghost Building Company (U) (Irem, 1992) | Kid Niki's code greatly extended; see `HammerinHarry_SoundDriver.md` |

```
          Tamtex/Irem driver (Shisensho: © 1989 Tamtex, © 1990 Irem)
                 /                              \
   Lenar copy (Mercenary Force 1990,       Irem: Kid Niki (1991)
               Knight Quest 1991)                   |
                                         Hammerin' Harry "Ver 6.04" (1992)
```

## Instruction match

Driver code + update routine, addresses normalised; the counts are identical instructions in the same order:

| | Shisensho | Merc. Force | Knight Quest | Kid Niki |
|---|---|---|---|---|
| Shisensho (338) | – | **332** | 329 | 299 |
| Mercenary Force (340) | | – | 335 | 302 |
| Knight Quest (340) | | | – | 307 |
| Kid Niki (370) | | | | – |

Shisensho's driver is the same code as Mercenary Force's to within 6 instructions. Kid Niki is Shisensho plus additions.

## Feature comparison

| | Shisensho (Tamtex) | Lenar (MF / KQ) | Kid Niki (Irem) |
|---|---|---|---|
| Driver code | `$7AF0-$7CFC` (ROM-only) | bank 3 `$7AE0-$7CF6` | bank 1 `$7A00-$7C35` |
| Update | `$7F80`, called from **VBlank** | MF `$4000` / KQ `$7F90`, called from the main loop | `$7E50`, called from **VBlank** |
| Track RAM | `$DF00` SFX / `$DF40` music | `$DF00` / `$DF40` | `$C800` / `$C840` |
| Request bytes | `$DF0E` SFX, `$DF1E` music | `$DF0E`/`$DF1E` (KQ swaps them) | `$C80E` SFX, `$C81E` music |
| Current track / set vars | **`$DF90` / `$DF91`** (in the driver page) | moved to game RAM (MF `$C116/7`, KQ `$C005/6`) | **`$C890` / `$C891`** (in the driver page) |
| Idle request value | **`$FF`** (load writes `$FF`; 0 is a valid id) | 0 (load writes 0) | **0 or `$FF`** (load writes `$FF`; `$86` clears to 0) |
| Freq index | **note + transpose** | note − transpose | **note + transpose** |
| Commands | 15 (`$8F` crashes) | 15 (`$8F` crashes) | 16 (`$8F` = SFX pan) |
| `$88` | no-op | no-op | NRx4 bits (field `+C`) |
| `$8A` | NR51 = x | NR51 = x, plus shadow byte | `wMusPan` = x; NR51 mixed each update |
| Request cleared at end of song | no | no | yes |
| Period table at `$7F00` | **48 entries, C3-B6** (= the others' entries 12-59) | 72 entries, C2-B7 | 72 entries, C2-B7 (identical to Lenar's) |
| Waves at `$7E00` | **1** (saw); sound data follows at `$7E10` | 5 | the same 5, first two swapped |
| Ids | 24 (`$7D00-$7DBF`), null `$86/$87` at `$7DC0` | 32 / 26 | 32 |
| `$8C` wave copy | 2 × (call-into-call) 8-byte copy | 4 × `Copy4` | 4 × `Copy4` |

### Reading the differences

- **Shisensho is closest to the root.** Kid Niki shares Shisensho's choices: transpose added, `$FF` request handshake, driver variables at `+$90/+$91` of the driver RAM page, update from VBlank. Kid Niki only adds to it (`$8F`, `$88` NRx4, NR51 mixing, request cleared at end, 0 also ignored).
- **Lenar's copy was changed by Lenar.** It agrees with Shisensho in structure, code layout, `$DF` RAM page and 15-entry command table, but changes everything at the game boundary: the transpose is subtracted, the idle request is 0, the variables live in game RAM, there is an NR51 shadow byte, and it is called from the main loop. The earlier conclusion that Lenar's driver is simply an earlier version of Kid Niki's should be refined: Lenar's form branched off before Kid Niki's additions, but it is a modified copy, not the original.
- **The full tables existed before Shisensho's.** Lenar and Kid Niki both have the same 72-entry period table and the same five waves. Shisensho's 48-entry table is an exact slice of it, and it keeps only one wave, which looks like trimming to fit a 32 KB ROM (its sound data is packed into the wave-table page). In Shisensho note value 0 = C3, 12 semitones higher than the same value in Lenar or Kid Niki.
- **`xor a` vs `ld a,$00`.** Shisensho and Mercenary Force use `xor a` in the same six places, while Kid Niki and Knight Quest use `ld a,$00` there. So the two 1990 games share one source revision and the two 1991 games another. Which form is older is not certain.
- **Who wrote it:** Shisensho's title screen reads "© 1990 IREM CORP. © 1989 TAMTEX". Tamtex is Irem's subsidiary, and its 1989 date is the earliest one attached to any game using this driver. That puts the driver's origin at Tamtex in 1989, before any Lenar game (Mercenary Force's code is dated 1990). Its later development continued at Irem (Kid Niki, Harry). Lenar most likely received the driver from Tamtex/Irem staff, or shared staff with them. Lenar's Mercenary Force uses the same 1990 source revision as Shisensho.

Data format: all three use the same event bytes. A Kid Niki converter reads Shisensho data directly, but with the period table offset by 12 (note 0 = C3). It reads Lenar data with four switches: transpose subtracted, `$88` ignored, `$8A` = NR51 directly, and wave offsets `$00`/`$10` swapped.

## Kid Niki vs Hammerin' Harry

Two Irem games, one driver lineage. **Kid Niki (J)** has an early, minimal version; **Hammerin' Harry: Ghost Building Company (U)** has a later one that names itself **"\*\* Ver 6.04 \*\*"**. Harry's driver is Kid Niki's code extended. The core routines are kept, some rewritten with `jr`/`or a` in place of `jp`/`cp $00`, and new features are added around them. Neither Shisensho, Kid Niki nor Lenar has a version string.

### What they share

- **Two sets of four tracks** (SFX = set 0, music = set 1, CH1-CH4 each), 16 bytes per track, the music set `$40` above the SFX set. The request bytes and NR51 variables live in unused fields of the first tracks (`$xx0E/$xx1E` in Kid Niki and Lenar, `$xx0F/$xx1F/...` in Harry).
- **Sound table**: 8 bytes per id, four stream pointers (CH1-CH4). A request restarts all four tracks of its set with speed 1.
- **Row timing**: `TRK_TICK` counts to `TRK_SPEED` (set by a speed byte). Each row runs commands until a note or `$89` (hold). One update per VBlank.
- **Output**: a channel is written only on a row of its owner, and the **SFX track owns the channel whenever it is on** (same owner-test routine: Shisensho `$7AF0`, Lenar `$7AE0`, KN `$7A00`, Harry `$4011`). Every write sets all the channel's registers and retriggers. CH4's note byte is NR43.
- **Field layout `$0-$B`**: speed, tick, pointer, (return), call state, NR10, NRx1, NRx2, note, transpose. `TRK_NRX4` is ORed into NR14/NR24 (and NR44 in Harry). CH3's NR34 is always `| $C0`.
- **Commands** with the same meaning: `$80` NRx1, `$81` NR10, `$82` transpose, `$83` NRx2, `$85` call, `$86` return/end, `$87` track off, `$88` NRx4 bits, `$89` hold, `$8A` music pan, `$8B` jump, `$8C` wave (16 bytes copied to wave RAM), `$8F` SFX pan.
- **Period table**: Harry's first 72 entries are Kid Niki's 72 (C2-B7), which are Lenar's 72. Indexed by `(note + transpose) × 2` in 8 bits. Kid Niki's five waves are Harry's waves 0, 5, 3, 4 and 6.

### What changed

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

All three formats are row-based with a constant row length per track (`TRK_SPEED` updates at 59.7 Hz). A MIDI/MOD converter can treat each note byte as one row: a new note (with its NRx2 envelope) on every non-hold row, and `$89` = let ring. See the section above for the differences between Shisensho, Lenar and Kid Niki data.

Tools: `tools/iremdata.py` walks every stream (calls, jumps, channel), and `tools/iremlen.py` gives the intro/loop lengths. `tools/knmodel.py` and `tools/hhmodel.py` are verified register-write models (0 mismatches against the ROM code) that a converter can drive directly. In Harry, envelopes (`$8D`) and pitch tables (`$8E`) need the block logic from `hhmodel.py`; notes ≥ 84 and the `wPanMask` interplay are edge cases (see the quirks).
