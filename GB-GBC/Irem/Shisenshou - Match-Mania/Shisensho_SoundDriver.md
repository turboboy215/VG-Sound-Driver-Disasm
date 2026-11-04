# Shisensho: Match-Mania (J) — sound driver

ROM: `Shisenshou - Match-Mania (J).gb` (DMG, 32 KB, no mapper, internal title `SHISENSYO`, licensee `$49` Irem). Title screen: "MATCH-MANIA © IREM CORP. © TAMTEX ALL RIGHTS RESERVED LICENSED BY NINTENDO" (stored as text shifted by $0F).

This is the **Tamtex/Irem driver in the form closest to the common ancestor** of Lenar's copy (Mercenary Force, Knight Quest) and Irem's Kid Niki / Hammerin' Harry drivers. 332 of its 338 driver instructions match Mercenary Force's in sequence, and Kid Niki's driver is this one plus additions. Lineage and comparison: `Irem_SoundEngine_Family.md`. The engine itself (tracks, rows, output, commands) is described in full in `Lenar_SoundDriver.md`. This doc lists only what differs.

`Shisensho_sound.asm` rebuilds **byte-exact** with RGBDS 1.0 (2,903 bytes, 0 mismatches):

```
rgbasm -o ss.o Shisensho_sound.asm      ; DEF SHISENSHO_NOTES is set inside the file
rgblink -p 0xFF -o ss.gb ss.o           ; compare $7460-$7ADE and $7AF0-$7FC7 with the ROM
```

---

## 1. Memory map (32 KB ROM, address = file offset)

| Region | Contents |
|---|---|
| `$7460-$7ADE` | music/SFX data, part 1 (songs) |
| `$7AF0-$7CFC` | driver code; command table `$7C1A` (15 words) |
| `$7D00-$7DBF` | `SndTable`: 24 ids × 4 track pointers |
| `$7DC0` / `$7DC1` | shared `$86` (id 0) / `$87` (unused channel slots) |
| `$7E00-$7E0F` | `SndWaveTable`: **one** wave (saw `00 11 22 … FF`) |
| `$7E10-$7EE7` | music/SFX data, part 2 (id $01 and the SFX), packed into the wave page |
| `$7F00-$7F5F` | `SndFreqTable`: **48** entries, C3-B6 |
| `$7F80-$7FC7` | `SoundUpdate` |

The tables are on the same fixed pages as in Lenar and Kid Niki (`ld h,$7D` / `ld h,$7E` / `ld d,$7F`).

## 2. Interface

| | |
|---|---|
| Update | `SoundUpdate` `$7F80`, called from the **VBlank** handler (`$0040` → `$0200` → `call $7F80`), once per frame |
| SFX request | `$DF0E` → SFX set `$DF00` |
| Music request | `$DF1E` → music set `$DF40` |
| Idle request value | **`$FF`**: the load routine ignores `$FF` and writes `$FF` back after starting a sound. **0 is a valid id** (id $00 ends the set at once, so starting it is harmless) |
| Driver variables | `wSndChanOfs` `$DF90`, `wSndSetFlag` `$DF91`, in the driver's RAM page (Kid Niki uses the same offsets in `$C8xx`) |

Ids written as immediates by the game: music `$02-$07` (to `$DF1E`), SFX `$09-$10`, `$12`, `$17` (to `$DF0E`).

## 3. Differences from Lenar's copy

| | Shisensho | Lenar (MF/KQ) |
|---|---|---|
| Frequency index | `(note + transpose) × 2` (`add [hl]`) | `(note − transpose) × 2` |
| Request handshake | `$FF` = idle, write `$FF` | 0 = idle, write 0 |
| `$8A` | NR51 = x | NR51 = x, plus a shadow byte in game RAM |
| `$8C` wave copy | 2 × `Snd_Copy8` (a `call Snd_Copy4` that falls into `Snd_Copy4`) | 4 × `Snd_Copy4` |
| Variables | `$DF90/$DF91` | game RAM |
| Called from | VBlank | main loop |
| Tables | 48 periods (= entries 12-59 of Lenar's 72), 1 wave | 72 periods, 5 waves |

Everything else is the same code: SFX-over-music channel selection, rows set by `$90-$FF`, the 15-entry command table (`$84`, `$88` and `$8D` are no-ops, `$8F` would crash), the one-level `$85` call, `$86` ending the whole set outside a call, `$89` hold, NR30 = `$80` every frame, and NR34 `| $C0`.

**Notes**: value 0 = C3 here (one octave higher than the same value in Lenar or Kid Niki data). The asm uses `DEF SHISENSHO_NOTES` so `lenar_sound.inc` defines `C_3` = 0 … `B_6` = 47. Transposes are positive (they raise the pitch): `$05`, `$07`, `$0C`, `$11`, `$13`, `$18`.

## 4. Sounds (24 ids)

| Id | Channels | Type |
|---|---|---|
| `$00` | all `$86` | ends the set (can be requested, harmless) |
| `$01` | 1, 2, 3 + `$86` on ch4 | "mute": ch3 sets NR51 = 0, then ch4's `$86` ends the set in the same frame |
| `$02`, `$07` | 1234 | looping music |
| `$03`, `$04`, `$06` | 123- | looping music |
| `$05` | 123- | one-shot (jingle) |
| `$08` | 1--- | looping SFX |
| `$09`, `$0A`, `$0C`, `$0D`, `$13`, `$14`, `$16`, `$17` | 1--- | SFX |
| `$0B`, `$0E`, `$0F`, `$12` | ---4 | noise SFX |
| `$10` | 12-- | SFX |
| `$11` | --3- | wave SFX |
| `$15` | 1--4 | SFX |

All data is referenced; there are no unused streams. `$81` sweep is used by several SFX, and every ch3 stream except id $01's loads the wave with `$8C $00`.

## 5. Files (in `GBAudioLab\Lenar`)

- `Shisensho_sound.asm`: full disassembly (driver, update, tables, all data)
- `lenar_sound.inc`: shared macros. It now has a Shisensho note mode, and `KnightQuest_sound.asm` / `MercenaryForce_sound.asm` still build byte-exact with it
- `hardware.inc`
