# Adventures of Lolo (GB): sound driver

This is HAL Laboratory's sound driver in *Adventures of Lolo* (`Adventures of Lolo (U) [S][!].gb`, MBC1, 256 KB). The code and the song, SFX and pattern tables are in bank 0 at `$32AE–$3FFF`. All music and SFX data is in bank `$0F` at `$4000–$7DD4`; the rest of bank `$0F` is filler that doesn't look like data. Both regions rebuild **byte-exact** with RGBDS 0.9.1 (`-Wall` clean) from the sources in `HAL\Lolo`.

The data format and almost all of the engine are the same as *Kirby's Dream Land*'s (`KirbysDreamLand_SoundDriver.md`). This document lists the differences. The main one is the **pattern sequencer**, which lets the game switch a song between five arrangements on the beat.

| Range | Content | File |
|---|---|---|
| bank 0 `$32AE–$3C16` | far-call wrappers, driver code, period/noise/stack tables, initial wave, multiply | `Lolo_Driver.inc` |
| bank 0 `$3C17–$3FFF` | song and SFX tables, SFX masks/priorities, pattern groups/periods, 10 pattern tables | `Lolo_Tables.inc` |
| bank `$0F` `$4000–$7DD4` | 3 waves, 56 song + 27 SFX headers, streams, envelopes, 51 instruments, 18 length sets | `Lolo_Data.inc` |

```
python tools\gen_lolo.py <rom> Lolo [kdl rom]   # routine names are ported from KDL, so the KDL ROM is needed
sh Lolo\build_check.sh <rom>
python tools\verify_lolo.py Lolo [song frames] [sfx frames]
```

---

## 1. API

| Address | Routine | |
|---|---|---|
| `$32AE` / `$32C5` / `$32DC` | `Sound_PlaySfxFar` / `Sound_PlaySongFar` / `Sound_InitFar` | map bank `$0F` with `rst $30`, call, restore |
| `$32E9` | `Sound_Init` | also clears `wPatternVariant` and `wSfxTranspose` |
| `$334A` | `Sound_PlaySfx` | a = SFX 0–26, `$FF` = stop |
| `$3471` | `Sound_PlaySong` | a = song 0–55, `$FF` = stop |
| `$34D8` | `Sound_Update` | from the timer interrupt (`$0306` → `$0313`, guarded by the busy flag `$C6EA`) |

The RAM layout is KDL's moved to `$C800` (`wTrkWait` `$C852`, …). The call/loop stacks are at `$C8D2`, and the current-image byte is in HRAM (`hRegImage` `$FF8A`). New variables:

| | | |
|---|---|---|
| `wPatternGroup` | `$C955` | `$FF` = song without patterns |
| `wPatternTimer` / `wPatternPeriod` | `$C956` / `$C957` | ticks per row |
| `wPatternRow` / `wPatternRows` | `$C958` / `$C959` | row 0–7 / 8 |
| `wPatternVariant` | `$C95A` | **set by the game** |
| `wSfxTranspose` | `$C95B–$C95E` | per channel, added by `base_note` on SFX tracks |

---

## 2. Pattern sequencer

`Sound_PlaySong` reads two extra tables per song. `SongPatternGroups` holds `$FF` (none) or a group, and `SongPatternPeriods` holds ticks per row. `Sound_Update` first runs the sequencer:

1. If the song has a group, it counts `wPatternTimer` up to the period.
2. At the period, it advances the row (mod 8). It points tracks 7, 6, 5, 4 at the four entries of row *r* in `PatternTables[group × 5 + wPatternVariant]`, sets their waits to 1, and resets their call/loop stacks.
3. Envelopes, instruments and volumes carry over.

Each pattern table holds 8 rows × 4 track pointers in header order.

| Songs | Group | Row period | Header = row 0 of variant |
|---|---|---|---|
| 23, 24, 25, 26, 27 | 0 | `$30` (48 ticks) | 0, 1, 2, 3, 4 |
| 28, 29, 30, 31, 32 | 1 | `$38` (56 ticks) | 0, 1, **3, 2**, 4 |

So the ten songs are two 8-row pieces, each in five synchronised arrangements. The song number only chooses the arrangement of the first row. From row 1 on, the arrangement is whatever `wPatternVariant` says when the row starts. A change made by the game is heard at the next row boundary, in time with the music. Some variants share streams: in group 0, variants 0 and 1 share CH4, and variants 2 and 3 share CH3 and CH4; in group 1, variants 0, 2 and 3 share CH4.

The game writes `wPatternVariant` from bank 1:
- `$481F` writes 3, in a routine that resets a block of game state;
- `$49E9` writes 0 or 1, or 4 when a check (`call $5296`) returns `$0F`;
- `$49FE` writes 4 under the same check.

No write of 2 was found, so rows 1–7 of variant 2 may never be heard in the game. This hasn't been checked in play.

---

## 3. Other differences from KDL

| | Lolo | KDL |
|---|---|---|
| `base_note` (`$F5`) on SFX tracks | argument + `wSfxTranspose[channel]` (`Cmd_BaseNote`). The game writes the CH1/CH2 entries (bank 2 `$4905–$49F5`, bank 0 `$01B2`) to shift effects in pitch | argument |
| CH3 volume | `Ch3VolumeTable` has 4 entries (volume / 4) | 16 entries |
| gate multiply | shift-and-add `Multiply_BxE` in the driver | game's `$DC00` square table |
| wave for `env_timbre` | `Wave0–2` at the start of bank `$0F` | in the driver |
| `sync` (`$E1`) | used: songs 10–14 step `wSoundSync` through 0–14 on CH1. Bank-9 code (`$7D2A`) compares it with its own counter to advance a scene in time with the music | unused |

Everything else is unchanged: track model, header format, commands, envelope commands, register images, SFX priority rules, period/noise tables and default register image. Instruments 12, 13 and 26 are used with `STATIC`. Instruments 22, 23 and 27 are not used by any song or SFX.

---

## 4. Verification

- **Byte-exact rebuild** of bank 0 `$32AE–$3FFF` and bank `$0F` `$4000–$7DD4`.
- **Emulator harness** (as for KDL; the harness maps bank `$0F` and calls the driver directly). Every song is played. The ten pattern songs are played once per variant 0–4, with `wPatternVariant` set before each job. Every SFX is played too.

  | Run (12,000 frames per song, 3,600 per SFX) | |
  |---|---|
  | Addresses read | 15,423 |
  | Outside the parse | **0** |
  | Parsed header/stream/envelope bytes read | 15,247 of 15,299 |

  The 52 unread bytes are envelope tails, two loop-exit bytes (`$63CB`, `$658A`), and the envelopes of the 3 unused instruments.
- **Unreferenced data.** Bank `$0F` has 32 fragments that nothing points to. 22 are single bytes, mostly `snd_end`s after a jump or return. The rest are short orphaned stream or envelope pieces such as `$43E8–$441C` and `$664D–$665D`. They are emitted decoded and marked `unreferenced`; CH4 fragments are shown as tone notes. Bank 0 `$3FF7–$3FFF` (9 bytes after the last pattern table) is not referenced by the sound code.
- **Not verified:** song and SFX titles, the in-game variant logic, and anything on hardware.

## Files (`HAL\Lolo`)

| File | Content |
|---|---|
| `Lolo_Sound.asm` | two sections (ROM0 `$32AE`, ROMX bank `$0F`); includes the files below |
| `Lolo_Driver.inc`, `Lolo_Tables.inc` | bank 0 |
| `Lolo_Data.inc` | bank `$0F` |
| `Lolo_Macros.inc`, `Lolo_RAM.inc` | macros (same as KDL's), RAM and hardware symbols |
| `tools\gen_lolo.py`, `tools\verify_lolo.py` | generator, harness check |
