# Mega Man Xtreme 2 (GBC): sound driver, compared with Mega Man Xtreme

ROM: `Megaman Xtreme 2 (U) [C][!].gbc` (MBC5, 1 MB, GBC only). Capcom / Tose, 2001.

**Short version:** the driver is the same program. Banks 2 and 3 hold code that is byte-identical to Mega Man Xtreme's `$4000–$4B3F`, and the generator renders it to exactly the same source text. The sources here therefore INCLUDE `../MegaManXtreme/MMX_SoundDriver.inc` instead of carrying a copy. Everything that differs is data and ROM0 glue:

| | Mega Man Xtreme | Mega Man Xtreme 2 |
|---|---|---|
| Sound banks | 3 (2, 3, 4) | **2** (2, 3) |
| Header `$4B40` | `$7E` ids, instruments `$4C41`, waves `$4E19` | `$7D` ids, instruments `$4C3F`, waves `$4E17` |
| Songs | 25: ids `$01–$1D` (`$04/$05/$12/$14` unused) | 22: ids `$01–$16`, bank 2 = `$01–$07`, bank 3 = `$08–$16` |
| SFX | 96: `$1E–$7D` | 93: `$20–$7C` |
| Instruments / waves | 59 / 19, same in all banks | 59 / **10**, same in both banks. Only 3 instruments (14, 40, 41) are identical to MMX1. 5 of the 10 waves are copies of MMX1 waves 1, 5 and 11 (wave 5 appears three times). |
| Bank choice | game code sets `hSndBank`, then `GameSelectSoundBank` **stops all sound** before switching | `GamePlaySound` picks the bank from `MusicBankTable` (ROM0 `$0A79`) by music id. **No stop.** |
| Data end | 2:`$7D3E`, 3:`$7BE3`, 4:`$7886` | 2:`$7EF7`, 3:`$7E08` |

No song is shared between the games. Of the 93 SFX, 12 are MMX1 effects with renumbered instruments (e.g. `$7B`/`$7C` = MMX1 `$1E`/`$1F`, `$66–$68` ≈ `$41`/`$46`/`$42`). About 29 more have exactly the segment timing of an MMX1 effect and look like edits. About 52 are new.

## Build

```
./build_check.sh        # needs ../MegaManXtreme (driver source + MMX_Sound.inc)
```

`MMX2_SoundBank2.asm` and `MMX2_SoundBank3.asm` each define `NUM_SOUND_IDS = $7D`, then INCLUDE `MMX_Sound.inc` and `MMX_SoundDriver.inc` (`-I ../MegaManXtreme`). They also contain the bank's pointer table, instruments, waves, songs and SFX. `MMX2_SoundGlue.asm` covers ROM0. All of it rebuilds **byte-exact** (RGBDS 0.9.1, `-Wall` clean) for 2:`$4000–$7EF7`, 3:`$4000–$7E08`, 0:`$01D5–$01E7` and 0:`$0A10–$0AB0`. The format, commands, envelopes and quirks are as described in `MegaManXtreme_SoundDriver.md`.

## Glue (ROM0)

| Addr | Name | |
|---|---|---|
| `$01D5` | VBlank | maps `hSndBank`, calls `SndUpdate` |
| `$0A10` | `GamePlayStageMusic` | `GameStopSound`, then plays `StageMusicTable[wStage]` (`$C05F`) |
| `$0A25` | `StageMusicTable` | `01 02 03 0D 0C 04 05 0A 0B 0E 0E 0E 0F` (13 entries) |
| `$0A32` | `GamePlaySound` | `$F0` → current bank. `$01–$1F` → `hSndBank = MusicBankTable[id]`, ignored if 0. `$20–$7C` → current bank. ≥ `$7D` ignored. |
| `$0A79` | `MusicBankTable` | 32 bytes: id 0 → 0, `$01–$07` → 2, `$08–$16` → 3, `$17–$1F` → 0 |
| `$0A99` | `GameStopSound` | `hSndBank = 2`, command `$F0` |

The game tracks its current ROM bank in `$FF92`. MMX1 read it from each bank's `$7FFE`.

## Songs

| Id | Bank | Addr | Bytes | Tempo | End | Notes |
|---|---|---|---|---|---|---|
| `$01` | 2 | `$4EB7` | 1695 | `$0266` | loops | stage 0 |
| `$02` | 2 | `$555A` | 1482 | `$022E` | loops | stage 1 |
| `$03` | 2 | `$5B28` | 1876 | `$0216` | loops | stage 2 |
| `$04` | 2 | `$6280` | 1755 | `$0266` | loops | stage 5 |
| `$05` | 2 | `$695F` | 1325 | `$0180` | loops | stage 6 |
| `$06` | 2 | `$6E90` | 168 | `$0266` | loops | |
| `$07` | 2 | `$6F3C` | 721 | `$0266` | loops | |
| `$08` | 3 | `$4EB7` | 392 | `$0266` | loops | |
| `$09` | 3 | `$5043` | 325 | `$022E` | ends | |
| `$0A` | 3 | `$5188` | 870 | `$01A7` | loops | stage 7 |
| `$0B` | 3 | `$54F2` | 1144 | `$0266` | loops | stage 8 |
| `$0C` | 3 | `$596E` | 630 | `$01A7` | loops | stage 4 |
| `$0D` | 3 | `$5BE8` | 834 | `$0266` | loops | stage 3 |
| `$0E` | 3 | `$5F2E` | 1126 | `$0333` | loops | stages 9–11 |
| `$0F` | 3 | `$6398` | 203 | `$01C7` | loops | **title** (confirmed), stage table entry 12 |
| `$10` | 3 | `$6467` | 375 | `$0249` | loops | |
| `$11` | 3 | `$65E2` | 426 | `$01C7` | loops | |
| `$12` | 3 | `$6790` | 335 | `$0266` | ends | |
| `$13` | 3 | `$68DF` | 625 | `$0286` | loops | after Start on the title (story scene) |
| `$14` | 3 | `$6B6D` | 789 | `$0199` | loops | |
| `$15` | 3 | `$6E86` | 329 | `$022E` | loops | |
| `$16` | 3 | `$6FD3` | 331 | `$036D` | loops | |

SFX seen on screen: `$3A` (after the title), `$39` (story text). Durations run from 3 frames to 191 (`$41`), apart from `$5F`.

## Differences that matter

1. **Switching banks no longer stops the SFX.** `GamePlaySound` changes `hSndBank` for a song in the other bank, but an SFX that is playing keeps its stream pointer, and the SFX sit at different addresses in the two banks (`$20` is at `$7211` in bank 2, `$7122` in bank 3). After the switch, the next segment is read from the other bank's bytes. In the test harness, SFX `$28` (bank 2) followed 10 frames later by song `$08` (bank 3) read a garbage segment from 3:`$72F4` (setting flags with bits above 4 → `SfxChannelSetting` indexes past its 5-entry table), and the emulated CPU stopped making progress one frame later. The game avoids this wherever it goes through `GamePlayStageMusic`, which stops all sound first. I didn't check whether any other call path can hit it. MMX1 can't, because its bank switch always stops everything.
2. **SFX `$5F` never ends:** its second segment is `SEG_LOOP 0` back to the first. Its loop flag (priority bit 7) isn't set, so it isn't resumed after a higher-priority SFX. It runs until it's stopped or replaced (priority 12). An unreachable `SFX_END` follows it in both banks.
3. **Unreferenced music fragments** in bank 3, right after song `$13`'s CH1 (`$69BA–$69C5`) and CH2 (`$6A6F–$6A7D`) streams. Both are short note/command sequences ending in `END`, apparently cut-off leftovers. Like MMX1, every `JUMP` is followed by an unreachable `END` (28 in bank 2, 50 in bank 3).
4. Only 10 waves (MMX1 had 19). The instrument table has the same 59-entry size but almost entirely new contents.

## Verification

- Byte-exact rebuild of both banks and the glue. The driver part matches MMX1's generated source line for line (asserted by `gen_mmx2.py`).
- **Harness** (`harness/`, linking the rebuilt MMX2 banks): all 22 songs, 3600 frames each, have the same `PlayNote` pitches on all four channels as the decoded streams. 92 of the 93 SFX in each bank end exactly at their decoded end marker. `$5F` loops by design.
- **Real ROM:** title → `$0F` (bank 3), Start → `$13` (bank 3).
- Not verified: stage names, the roles of most songs/SFX, and whether the game ever triggers difference 1. Nothing was checked on hardware.
