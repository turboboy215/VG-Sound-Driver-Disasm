# The Adventures of Pinocchio (GB prototype): sound driver

ROM: `Adventures of Pinocchio, The (J).gb` (DMG, MBC1, 64 KB, internal title `INFREY QUEST`). Despite the (J) tag this is a cancelled 1993 Bit Managers prototype; its music was later reused in *Otto's Ottifanten*.

Part of the AJG family, see `AJG_SoundEngine_Family.md`. This is an **early variant of version 3**: the same driver as Astérix (`Asterix_SoundDriver.md`, the reference for everything not repeated here) with a few things missing or still different. Read this document as a list of differences plus this game's own data.

| | |
|---|---|
| Bank | driver and data in **ROM bank 2**, `$4000–$66FC` |
| API | `$476D` `SndInit`, `$401E` `SndUpdate`, `$4391` `StopAll`, `$4B27` `PlaySfx` (A = id 1–11), `$4626` `StartFade`, `$4004` / `$4000` `SndPause` / `SndResume`, `$4B57/$4B5B/$4B5F` `PlayOnCh1/2/3`, `$4B8A` `SongFadeOut`. Songs: one start routine each (§3) |
| Tick | **timer interrupt at 53.89 Hz** (TAC = `$04`, TMA = `$B4`: 4096 Hz / 76), set up at `$01CD` right after `SndInit`. The handler (`$079D`) calls `SndUpdate` through `$07D1` while `hFF90` = 0 and `wDB2F` ≠ 0 |
| Game glue (bank 0) | `$07B4`: `PlaySfx` (A = id) only while `wDA3C` ≠ 0, no priority test; `$12CA`: `StopAll` + SFX 3. Songs are started by calling their routines directly (`$01FD` song 1, `$199B` song 2, `$07F4` song 3 or 4 by level, `$17BF` song 5) |
| RAM | pages Ch1 `$C1xx`, Ch2 `$C2xx`, Ch3 `$C3xx`, SFX `$C4xx`; globals in **HRAM `$FF91–$FFB5`** |
| Counts | 5 songs, 11 sound effects, 2 instrument tables (14 + 6), 1 arpeggio table (5), 8 waves, 9 drum sounds (one empty), 15 drum patterns |

`Pinocchio_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over ROM0 `$0000–$0002`, `$0008–$000B`, `$0018–$001D`, `$0BA4–$0BAC`, `$0BE7–$0BE8` and bank 2 `$4000–$66FC`. It assembles cleanly with `-Wall`.

```
rgbasm -Wall -o pinocchio.o Pinocchio_SoundDriver.asm
rgblink -o pinocchio.gb pinocchio.o
python tools/cmp_banked.py pinocchio.gb "Adventures of Pinocchio, The (J).gb" 0000-0002 0008-000B 0018-001D 0BA4-0BAC 0BE7-0BE8 2:4000-66FC
```

---

## 1. Differences from Astérix

| | Pinocchio | Astérix |
|---|---|---|
| Globals | HRAM `$FF91–$FFB5` (same order: shadows `$FF91–$FF94`, `wInInstr` `$FF95`, `wTranspose` `$FF96`, `wNoisePan` `$FF97`, `wDrumHold` `$FF98`, tables `$FF99–$FF9E`, `wPaused` `$FF9F`, `wStereo` `$FFA0`, drums `$FFA1–$FFA6`, noise `$FFA7–$FFAF`, fade `$FFB0–$FFB5`) | WRAM `$DB46–$DB6B` |
| Tick | timer, 53.89 Hz | VBlank, 59.73 Hz |
| Commands | `$60–$83` (36): no `NOTE_PAN` | `$60–$84` (37) |
| `INSTR` | `$84–$9D` (26 instruments) | `$85–$9D` (25) |
| Command dispatch | through a bank-0 helper (`$0BE7`: `push bc` / `ret`) | local `CallBC` |
| Drum pattern bytes | no `$35` (noise auto-pan) | `$35 n` |
| Noise sequence | no auto-pan | auto-pan |
| Auto-pan cycle | centre, right, centre, left, centre, then right, centre, left, centre, … | left, right, left, right, centre |
| Auto-duty cycle | 75 %, 12.5 %, 75 %, 50 %, then 12.5 %, 75 %, 50 %, … | 50 % / 12.5 % alternating |
| Field `$3F` | unused (no note-pan) | `NOTE_PAN` |

Everything else (fields, envelope and divider, portamento, release with minimum length, `WAIT`/`WAIT2`, `CALL_CODE`, fades, waves, drums with hold, SFX page on CH3, output without constant retrigger, the quirks) is the same as Astérix, including the `ResetChannel` Z-flag bug.

**Panning has no effect:** NR51 is the computed pan value only while `wStereo` (`$FFA0`) ≠ 0, and no code in the ROM writes `$FFA0`, so NR51 stays `$FF`. The data only uses `AUTOPAN` (twice), never `PAN_*`.

## 2. Stream bytes

As Astérix §3.2 for `$00–$83`; then `$84–$9D` `INSTR`, `$9E–$AC` `ARP`, `$AD–$BC` `VOL`, `$BD–$CC` `VOLENV`, `$CD–$FF` `LEN` 1–51. Instrument macros end with `END` (`$68`) or `NEXT` (`$6A`); arpeggios and fades loop on `$6A`.

Not used by the data: `GLIDE_OFF`, `WAIT2`, `VIB_OFF`, `STOP_ALL`, `ORDER_JUMP`, `PAN_C/R/L`, `ENV_DIV`. Used here but not in Astérix: `FADE`/`FADE_OFF` (once) and the one-byte `RELEASE 0`.

## 3. Songs

| Song | Routine | Ch1 / Ch2 / Ch3 order lists | Instr. table | Length (ticks) |
|---|---|---|---|---|
| 1 | `$4C77` | `$4CA3 / $4CEB / $4D2B` | 1 | loops |
| 2 | `$552B` | `$555B / $556B / $557B` | 1 | loops |
| 3 | `$5859` | `$5885 / $5AD6 / $5999` | 1 | loops |
| 4 | `$5BF4` | `$5C20 / $5DBC / $5F13` | 2 | loops |
| 5 | `$6117` | `$6143 / $61A2 / $6206` | 2 | 1370, ends |

Song routines here call `StopAll` first (drums, noise and fade off), start the three channels, then set the tables; only song 2 also sets NR50 = `$77`. Instrument tables: 1 `$62B9` (14 used), 2 `$634B` (6 used); arpeggio table `$6395` (5). `INSTR n` reads entry n + 1. Ticks are timer ticks (53.89 Hz): song 5 lasts 25.4 s.

## 4. Sound effects

`SfxTable` `$4B93` (11 entries). SFX streams use `WAVE`, `LEN`, `VOL`/`VOLENV`, notes, `WAIT`, `GLIDE`, `VIBRATO`, `PORTA`, `END`.

| Id | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 15 | 15 | 53 | 13 | 39 | 39 | 60 | 6 | 23 | 23 | 3 |

## 5. Drums

`DrumTable` `$44B1` (9 entries; the dispatch at `$44AA` indexes from `$44AF`).

| Drum | Routine | NR43 sequence | NR42 sequence |
|---|---|---|---|
| 1 | `$6636` | `02 51 61 71 91 71 60` | `F0 F0 D0 90 00 50 43` |
| 2 | `$664D` | `60 52 42 41 22 11 04` | same table as 1 |
| 3 | `$6664` | `50 41 50 51 52 53 51` | `F0 60 F0 60 D0 50 72` |
| 4 | `$667B` | `04 02 06` | `A0 50 54` |
| 5 | `$6692` | – (just `ret`: a silent drum) | |
| 6 | `$6693` | `04 02 01` | `80 50 33` |
| 7 | `$66AA` | `06 04 03 03 07` | `F0 F0 D0 C0 85` |
| 8 | `$66C1` | `00 00 00`, speed `$55` (a step every 86 ticks) | `2F F7 20` |
| 9 | `$66DF` | `00 00`, speed `$55` | `2F F7` |

Drums 1–3 are Astérix's drums 1–3 with slightly different NR42 tables. Drums 8 and 9 point into bytes that look like leftover data; they set the noise sequence speed, which then also slows every later drum until a pattern byte `$74+` changes it. The only `CALL_CODE` in the data calls drum 3.

## 6. Quirks (in addition to Astérix's)

1. **`wStereo` is never set**, so panning is inaudible (§1).
2. **Drum 5 is empty** and drums 8/9 change the noise speed (§5).
3. `SndPause`/`SndResume`, `PlayOnCh1–3` and `SongFadeOut` have no callers in the ROM.

## 7. Verification (lighter)

Byte-exact rebuild; emulator trace of all 5 songs (6000 ticks) and 11 SFX with the stream pointer, order position and drum position checked against the data walk on every tick: **0 problems** (`verify/run_v3.log`). Routine names were carried over from Astérix by aligning the code, and the remaining differences were read by hand. No independent driver model.

## Files

`Pinocchio_SoundDriver.asm`; tools and verification as listed in `Asterix_SoundDriver.md`. Regenerate: `python tools/gen_v3.py pinocchio "Adventures of Pinocchio, The (J).gb" Pinocchio_SoundDriver.asm`.
