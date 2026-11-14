# The Mummy (GBC): sound driver

ROM: `Mummy, The (E) (M3) [C][!].gbc` (Game Boy Color only, MBC5, 1 MB, internal title `THE MUMMY`). Konami, 2000. Bank `$0C` holds the text **"Sound Programmed By Jun Yamaguchi."** between the period and vibrato tables.

Part of the Konami family, see `Konami_SoundEngine_Family.md`. This is **Cyborg Kuro-chan's driver** (`CyborgKurochan_SoundDriver.md`): 2,850 of its 2,860 instructions line up with Kuro-chan's (2,450 with World Soccer GB2's). Everything in that doc holds – banks `$0C–$0F`, streams in `$0C` + the priority nibble, instrument macros, the speed-up tempo, the drum-set table pointer, the macro's `$0065` bug – with these differences:

- the track pages are in **CGB WRAM bank 1** (Kuro-chan: 7), still at `$D000 + n×$100`; the game's ROM/WRAM bank copies are `$C00A`/`$C00B`, its busy flags `$C017`;
- **music from id `$65`** (`$65–$88`);
- two new ROM0 entry points: **`IsSoundPlaying`** (`$1BDA`; A = id → A = the page of the first track playing it, or 0) and **`SetPeriodOffset`** (`$1C19`; `wPeriodOfs` `$D72D` = HL);
- **`WritePeriodOfs`** (`$4AE2`): every period write goes through it, and **on the Sfx2 track only** (descriptor `$52`, the CH3 SFX) `wPeriodOfs` is added first – a pitch the game can bend for one SFX channel;
- 119 wave pointers, 16 vibrato, 11 semitone, 30 envelope and 10 macro tables; the drum set 1 table at `$4444` (11 hits) – unused here too.

| | |
|---|---|
| API | ROM0 `$17F0` `PlaySoundFar` (A = id, 0 = stop all; 165 call sites) → `$1863` `PlaySound`; `$17D2` `PlaySoundFarSet1` (never called); `$1733` `SndInit`; `$1BDA` `IsSoundPlaying`, `$1C19` `SetPeriodOffset`; `$1C3B` `StartFadeOut`, `$1C73` `StopAndFadeIn`, `$1CA2` `SndUndim`, `$1CCC` `SndDim` |
| Game inputs | `wPauseFlag` `$D71D`, `wSndDim` `$D71A` bit 0, `wPeriodOfs` `$D72D` (through `SetPeriodOffset`) |
| Tick | **VBlank**: the handler calls `SndUpdate` `$19CF` at `$00B2` |
| Driver code | ROM0 `$1733–$1CF5` (1.5 KB); bank `$0C` `$4488–$5316` (3.7 KB, jump tables at `$4D01`, `$4D43`, `$4E71`, `$4EB2`) |
| Data | bank `$0C` `$4000–$4487` (table sets, `SoundTable`, headers, drum set 1) and `$5317–$75B3`; banks `$0D` `$4000–$7A64`, `$0E` `$4000–$7E70`, `$0F` `$4000–$5137`; the rest of the four banks is `$FF` |
| RAM | WRAM bank 1: tracks `$D000–$D667`, globals `$D700–$D72E`, `$D780–$D7D0` |
| Counts | 136 ids: SFX `$01–$64`, 36 songs `$65–$88`; drum set 1: 11 hits |

`MUMMY_SoundDriver.asm` rebuilds **byte-exact** with RGBDS over ROM0 `$1733–$1CF5`, bank `$0C` `$4000–$75B3`, `$0D` `$4000–$7A64`, `$0E` `$4000–$7E70` and `$0F` `$4000–$5137`, and assembles cleanly with `-Wall`:

```
rgbasm -Wall -o mummy.o MUMMY_SoundDriver.asm
rgblink -o mummy.gbc mummy.o
```

---

## 1. Data

In the data: 8,758 notes and only 42 note-volume notes (4 note-volume voices), 2,189 drum notes and **165 drum escapes** `$Dx n`, 1,520 noise bytes, 412 voices, 2,326 releases, 991 vibratos, 462 envelopes, 405 + 216 + 193 pans, 372 detunes, 454 + 58 loops and 109 loop breaks, 108 calls, tempos `$00`, `$19`, `$20`, **5 instrument commands** (macros 3, 8, 10 on wave tracks; 2 offs). **Not used:** the speed-up tempo, `$EA Fx` (drum set 1), `$EA Ax/B/C/D/E`, the slide.

| Address (bank `$0C`) | Contents |
|---|---|
| `$4000` | `SoundTableSets`: set 0 = `$4002`, set 1 = `$4444` |
| `$4002` | `SoundTable`, ids `$01–$88` (entry 0 = the set-1 pointer) |
| `$4444` | `DrumSet1Table`, 11 hits, headers `$445C–$4487` |
| `$5317` | `WaveTable`, 119 pointers, waves `$5405–$5B74` |
| `$5B75` | `PeriodTable`, 96 periods |
| `$5C35` | the credit text (34 bytes) |
| `$5C57` | `VibratoTable`, 16 pointers |
| `$5F0A` | `Vibrato2Table`, 11 semitone tables |
| `$5F5B` | `EnvelopeTable`, 30 envelopes |
| `$60A0` | `MacroTable`, 10 instrument macros (`$60B4–$624A`) |

---

## 2. Quirks

1. The period offset is added **only on the Sfx2 track** (`cp $52`), not on the music tracks (the family page said "every channel but CH3" before; corrected).
2. Kuro-chan's macro bug is still there (`ld [$0065], a` at `$46CF`; Kuro-chan `$49D1`).
3. A few envelope tables end in unreachable bytes (`$1F $FE` after their loop at `$5FB8`, `$6080`, `$6097`).

---

## 3. Verification

As Kuro-chan (previous session, re-run in this one): `verify/vstream13.py mummy`, every id alone for 6,500 updates through `PlaySoundFar`, `TRK_LEN` stores at `$44F6`/`$4A5F` compared with `tools/kdata13.py`: **136 ids, 101,043 reads, 0 mismatches** (`verify/run_stream_mummy.sh` → `run_stream_mummy.log`). The drum set 1 hits (decoded in the asm through `tools/kdata16.py`) are not reachable from the data and were not checked.

---

## Files (in `GBAudioLab\Kon`)

- `MUMMY_SoundDriver.asm` – the disassembly (driver + all sound data), byte-exact.
- `tools/kdata16.py`, `tools/cfg16common.py`, `tools/cfg_mummy.py`.
- `verify/vstream13.py`, `verify/run_stream_mummy.sh`, `verify/run_stream_mummy.log`.
