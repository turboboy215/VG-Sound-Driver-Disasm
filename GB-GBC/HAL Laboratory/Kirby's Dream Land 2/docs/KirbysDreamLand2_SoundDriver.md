# Kirby's Dream Land 2 (GB): sound driver

This is HAL Laboratory's sound driver in *Kirby's Dream Land 2* (`Kirby's Dream Land 2 (U) [S][!].gb`, MBC1 + RAM + battery, 512 KB). It is split three ways:

- **bank `$1E`** holds the engine's bank-switched half and all SFX;
- **bank `$1F`** holds all music;
- **bank 0** holds the track interpreter. It has to read whichever sound bank is mapped, so it can't live in either one.

All four regions rebuild **byte-exact** with RGBDS 0.9.1 (`-Wall` clean) from the sources in `HAL\KDL2`.

The data format and the interpreter are *Kirby's Dream Land*'s (`KirbysDreamLand_SoundDriver.md`). This document covers the split and the differences.

| Range | Content | File |
|---|---|---|
| bank 0 `$2B97–$30DF` | `Sound_StartTrack`, `Sound_Update`, main/envelope stream interpreter, noise/stack/tuning tables | `KDL2_Bank0.inc` |
| bank 0 `$3F56–$3FE5` | `PeriodTable` (72 big-endian periods, the same values as KDL's) | `KDL2_Periods.inc` |
| bank `$1E` `$4000–$5DBC` | instrument table + envelopes, `Sound_Init`/`Reset`, `Sound_PlaySfx`, register output, 3 waves, 98 SFX, 33 length sets, SFX tables | `KDL2_SfxBank.inc` |
| bank `$1F` `$4000–$7E6B` | instrument table + envelopes (identical copy), `Sound_PlaySong`, 47 songs, song table | `KDL2_MusicBank.inc` |

Game code follows the sound data in bank `$1E` (from `$5DBD`). Bank `$1F` ends in filler.

```
python tools\gen_kdl2.py <rom> KDL2 [kdl rom]
sh KDL2\build_check.sh <rom>
python tools\verify_kdl2.py KDL2 [song frames] [sfx frames]
```

---

## 1. API

The game reaches the driver through its far-call routine `$05CF` (a = bank, hl = address), with e = number:

| Call | Routine | |
|---|---|---|
| `$1E:$4232` | `Sound_Init` | copy the waves and length sets to RAM, then `Sound_Reset` (`$424A`) |
| `$1E:$4299` | `Sound_PlaySfx` | e = SFX 0–97, `$FF` = stop (callers `$109D`, `$10AA`, `$3BE6`, …) |
| `$1F:$4232` | `Sound_PlaySong` | e = song 0–46, `$FF` = stop (callers `$10BA`, `$2A43`, `$322B`, …) |
| `$2BFD` | `Sound_Update` | bank 0, called once per frame at `$0292` |

The RAM is KDL's layout at `$CE00` (`wTrkWait` `$CE52`, …). Additions:

| | | |
|---|---|---|
| `wSoundStacks` | `$DD64` | call/loop stacks |
| `wCurSong` | `$DDE4` | last song started |
| `wWaves` | `$DDE5` | 3 waves (48 bytes), copied from `$1E:$446E` |
| `wLengthSets` | `$DE15` | 33 length sets (198 bytes), copied from `$1E:$5B6F` |
| `hRegImage` / `hCurBank` | `$FF99` / `$FFA4` | |

---

## 2. Two sound banks

- `Sound_Update` maps bank `$1F` and runs music tracks 7–4. Before track 3 it maps bank `$1E` and runs the SFX tracks. It then jumps to `Sound_UpdateSfxAndOutput` in bank `$1E`, which frees ended SFX channels and writes the register images.
- Streams, envelopes and the instrument table are read from whichever bank is mapped, so each bank carries its own **`InstrumentTable` at `$4000`**: 42 instruments and their envelopes, byte-identical in both banks (`$4000–$4231`). The interpreter addresses it with `ld d, HIGH(InstrumentTable)`.
- Tables both kinds of track need regardless of the mapped bank are in bank 0 (period, noise, tuning, stack tables) or **copied to RAM** at init (waves, length sets). The 33 length sets are 11 distinct sets stored three times, so `length_set` 0–10, 11–21 and 22–32 are equivalent.
- `Sound_PlaySong` lives in the music bank, with its own default register image. **A request for the song already playing (`wCurSong`) is ignored.** `Sound_Reset` stops the music with a far call to `$1F:$4232` with e = `$FF`.

Instruments by bank:
- not used by any SFX: 5, 6, 9–12, 17, 18, 22, 24–26, 28, 29, 32, 34, 36, 38–40;
- not used by any song: 4, 8, 29, 30, 34, 39, 40;
- used by neither: 29, 34, 39, 40.

---

## 3. Other differences from KDL

| | KDL2 | KDL |
|---|---|---|
| gate multiply | the game's signed multiply `$293E` (i² tables at `$D700`/`$D800`) | the game's floor(i²/2) table at `$DC00` |
| CH3 volume | 4-entry `Ch3VolumeTable` (as in Lolo) | 16 entries |
| `base_note` on SFX | argument only (Lolo's SFX transposition isn't here) | argument only |
| pattern sequencer | none | none |

The commands, envelope bytes, header format, track model, SFX priority rules and register output are unchanged.

---

## 4. Verification

- **Byte-exact rebuild** of all four regions.
- **Emulator harness.** The harness keeps `hCurBank` in step with the mapped bank, and every read is checked against the parse of the bank mapped at that moment. The harness also copies an i² table to `$D700`/`$D800` for the game's multiply routine. Hooks: every `ld a,[de]` in the bank-0 interpreter, plus the header reads in `Sound_PlaySfx` and `Sound_PlaySong`.

  | Run (12,000 frames per song, 3,600 per SFX) | bank `$1E` | bank `$1F` |
  |---|---|---|
  | Addresses read | 5,994 | 15,638 |
  | Outside the parse | **0** | **0** |
  | Parsed bytes read | 5,916 of 6,119 | 15,498 of 15,559 |
  | Reads with another bank mapped | 0 | |

  All unread bytes are envelopes in the instrument-table copies (`$40B8–$4223`) of instruments that bank's own data doesn't select.
- **Unreferenced data:**
  - bank `$1E`: 8 orphaned stream fragments (`$4AD5–$4ADC`, `$4E17–$4E22`, `$5198–$51A8`, `$52E4–$52FA`, `$534B–$5357`, `$5559–$556C`, `$5591–$55A4`, `$594F–$5951`);
  - bank `$1F`: one (`$6098–$60D3`).

  They are emitted decoded and marked `unreferenced`.
- **Not verified:** song and SFX titles, and anything on hardware.

## Files (`HAL\KDL2`)

| File | Content |
|---|---|
| `KDL2_Sound.asm` | four sections (ROM0 `$2B97`, ROM0 `$3F56`, ROMX `$1E`, ROMX `$1F`) |
| `KDL2_Bank0.inc`, `KDL2_Periods.inc`, `KDL2_SfxBank.inc`, `KDL2_MusicBank.inc` | the four regions; labels in bank `$1E`'s data are prefixed `S` (`SEnv_`, `SSeq_`) so both banks can be assembled together |
| `KDL2_Macros.inc`, `KDL2_RAM.inc` | macros (same as KDL's), RAM, hardware and game-routine symbols |
| `tools\gen_kdl2.py`, `tools\verify_kdl2.py` | generator, harness check |
