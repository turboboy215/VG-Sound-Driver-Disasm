# Tintin in Tibet (GB): sound driver

ROM: `Tintin in Tibet (E) (M4) (Eng-Fre-Ger-Dut) [S].gb` (DMG with SGB support, MBC1, 256 KB, internal title `TINTIN AU TIBET`). Infogrames, 1995/96 (sources differ).

Part of the AJG family (Alberto José González / Bit Managers), see `AJG_SoundEngine_Family.md`. This is **version 4**, documented in full in `Smurfs_SoundDriver.md`. The driver is **the Astérix & Obélix GB build** (`Obelix_SoundDriver.md`, §2) moved to bank 15, with three changes: the command table moves to the start of the bank, the globals move, and `PlaySfx` loses its SFX-29 test. Command bytes, ranges, field layout, period table and the rest of the code are the same, and so are the 11 drum sounds.

| | |
|---|---|
| Bank | the driver and all its data fill **ROM bank 15** (`$4000–$7FFF`; text and zero fill after `$7F13`) |
| Command table | **`$4000`** (36 commands, `$60–$83`, as Obélix GB); Obélix GB had it at `$4400` |
| API jump table | **`$4048`**: `SndUpdate $40BA`, `SndPause $4094`, `SndResume $408D`, `StopAll $44AA`, `PlaySfx $491A`, `SndInit $448F`, `SongFadeIn $495D`, `SongFadeOut $4957`, **14 song entries** (`$4060–$4087`), `PlaySfxNow $491D` (`$408A`) |
| Tick | VBlank, once per frame (59.73 Hz) |
| RAM | pages Ch1 `$C1xx`, Ch2 `$C2xx`, Ch3 `$C3xx`, SFX `$C4xx` (fields `$00–$3B`); **globals `$C13C–$C15F`**, packed into page `$C1` straight after the last channel field (Obélix GB `$C196`, same order) |
| Ranges | `INSTR $84–$90`, `ARP $91–$AC`, `VOLENV $AD–$BC`, `LEN $BD–$EC` (1–48), `REPEAT $ED–$FF` (2–20); drum tempo bytes `$BD–$FE` (all as Obélix GB) |
| Counts | 14 songs, 28 SFX, 11 instrument tables, 1 arpeggio table (28 entries, 15 used), 19 waves, 11 drum sounds (10 used) + 9 noise routines called with `CALL_CODE`, 22 drum patterns |

`TintinTibet_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over the whole of bank 15:

```
rgbasm -Wall -o tibet.o TintinTibet_SoundDriver.asm
rgblink -o tibet.gb tibet.o
python tools/cmp_banked.py tibet.gb "Tintin in Tibet (E) (M4) (Eng-Fre-Ger-Dut) [S].gb" 15:4000-7FFF
```

---

## 1. Game glue (bank 0)

The VBlank handler (`$1434`) switches to bank 15 and does the following:

- **Mailbox:** the game posts an API slot address with `ld hl, slot` / `call $00CB` (HL → `$C1DB/$C1DC`, A → `$C1DD`). The next VBlank clears the post and calls the slot with `jp hl` (`$18FF`). Songs are started this way, and so are `StopAll` and `SndPause` (from `$0090`).
- **SFX and update:** these run only while a sound-on flag `$C1D8` is set. The glue takes queued SFX ids (count `$C1DE`, ids from `$C1DF`) through API slot 4 (`PlaySfx`), then calls `SndUpdate` once.

`SndResume` is called directly through a wrapper at `$007C`. A `SndUpdate` wrapper at `$0068` has no direct caller. The bytes around it, in the RST area, are fragments of the text `BIT-MANAGERS`.

**`wStereo` is never set:** neither the driver nor the game writes `$C13D`, and it stays 0 through boot and the title screen. NR51 is therefore `$FF` all the time, so the data's `PAN_*` commands and drum pan bytes have no effect.

## 2. Differences from Astérix & Obélix GB

| | Astérix & Obélix GB | Tintin in Tibet |
|---|---|---|
| Bank | 6 | **15** |
| Command table | `$4400` | **`$4000`** (`StreamCommand` uses `ld b, $40`) |
| API jump table | `$4000` | `$4048` (after the command table) |
| Globals | `$C196–$C1B9` | **`$C13C–$C15F`** |
| `PlaySfx` | ignored while SFX 29 plays; `PlaySfxNow` skips the test | **no test.** `PlaySfx` (`$491A`) is `jp $408A`, the API table's last slot, which is `jp $491D`; both API SFX entries lead to the same code |
| Arpeggio table | `SndInit` sets `$74AB`, and every song sets it again | `SndInit` sets `$7560`; **no song sets it** (as in The Smurfs) |
| SFX table / CH3 volume table / drum table | `$7597` / `$414E` / `$49FB` | `$7665` (from `$7663`) / `$4190` / `$49F3` (from `$49F1`) |

The driver code otherwise matches Obélix GB instruction for instruction. `tools/v4diff.py` finds only the address constants above. (The arpeggio difference is in the song routines, which are data.)

### 2.1 Songs

| Song (API entry) | Routine | Ch1 / Ch2 / Ch3 order lists | Instr. table | Length (ticks) |
|---|---|---|---|---|
| 1 (`$4060`) | `$4B23` | `$4B43 / $4B5B / $4B73` | 1 `$4E17` | loops |
| 2 | `$4E75` | `$4E8A / $4E9A / $4EAA` | – | loops |
| 3 | `$507C` | `$509B / $50AD / $50BF` | 2 `$52E7` | loops |
| 4 | `$53A1` | `$53E0 / $53D0 / $53C0` | 3 `$5849` | loops |
| 5 | `$588B` | `$58A0 / $58C0 / $58B0` | – | loops |
| 6 | `$5B18` | `$5B37 / $5B4F / $5B67` | 4 `$5DD5` | loops |
| 7 | `$5E29` | `$5E48 / $5E5C / $5E4E` | 5 `$6180` | loops |
| 8 | `$61FE` | `$621D / $6229 / $6223` | 6 `$641A` | loops |
| 9 | `$642C` | `$644C / $6480 / $6466` | 7 `$6734` | loops |
| 10 | `$6794` | `$67D6 / $67C6 / $67B4` | 8 `$6A4C` | loops |
| 11 | `$6A98` | `$6AB8 / $6AD8 / $6AC8` | 9 `$6E7F` | loops |
| 12 | `$6EE3` | `$6F2A / $6F16 / $6F02` | 10 `$725E` | loops |
| 13 | `$729B` | `$72B0 / $72B4 / $72B2` | – | 1408, ends |
| 14 (`$4087`) | `$73B8` | `$73EB / $73E1 / $73D7` | 11 `$7541` | 1920, ends |

Instrument tables (instruments used): 1 (9), 2 (3), 3 (4), 4 (3), 5 (3), 6 (2), 7 (7), 8 (2), 9 (6), 10 (2), 11 (2). `INSTR n` reads entry n + 1. All songs use the arpeggio table `$7560`.

Data usage: 80 `REPEAT`s, 40 `VIBRATO`s. Not used: `VIB_OFF`, `STOP_ALL`, `AUTOPAN`, `FADE`, `FADE_OFF`, `VOL`, `SLIDE_UP`.

### 2.2 Sound effects

28 SFX, all on the CH3 page; noise comes from `CALL_CODE` inside the streams. They use `WAVE`, `LEN`, `VOLENV`, notes, `WAIT`, `REST`, `GLIDE`, `GLIDE_OFF`, `ARP`, `VIBRATO`, `SLIDE_DOWN`, `RELEASE`, `CALL_CODE` and `END`.

| Id | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 40 | 40 | 40 | 40 | 40 | 24 | 24 | 6 | 13 | 9 | 12 | 5 | 25 | 11 |

| Id | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 12 | 3 | 16 | 46 | 13 | 11 | 29 | 6 | 27 | 27 | 12 | 12 | 30 | 28 |

### 2.3 Noise

The 11 drum sounds have **the same NR43/NR42 sequences as Astérix & Obélix GB**, in the same order (routines `$7D8F`, `$7DD4`, `$7E00`, `$7E1D`, `$7E3A`, `$7E57`, `$7E74`, `$7DAC`, `$7E91`, `$7EB3`, `$7ED0`); drum 11 is unused.

`CALL_CODE` noise routines: `$7836` (NR42 = `$F2`, hold 19), `$7863` (NR42 = `$F1`, hold 19), `$78C1`, `$78E3`, `$79C0`, `$79F1`, `$7A1A` (hold 15), `$792C` (hold 10), `$7AA1` (hold 4). Drum 6 (`$7E57`) is also started directly with `CALL_CODE`.

---

## 3. Quirks

1. **Panning is dead** (§1): `wStereo` stays 0, so NR51 = `$FF`.
2. The Smurfs/Obélix quirks 4–7 (duty writes to NR21 from the CH3/SFX page, `STOP_ALL` from a stream, SFX end resets the noise timer and speed, `ResetChannel` leftovers) apply.
3. **Unreferenced (marked in the asm):**
   - the zero fill before the period table (`$471A`, 230 bytes);
   - stray `ret` bytes after five song routines and after `Cmd_CallCode`;
   - the end of song 14's three order lists (never reached: the patterns end with `END`);
   - 13 unused arpeggio table entries (`$757E`) and their arpeggios (`$7617`);
   - five noise routines (`$7890`, `$7965`, `$7A47`, `$7AD0`, `$7D87`);
   - a dozen wave-sized blocks (`$7B5D–$7D0C`);
   - text and data after the fade tables (`$7F13`).

## 4. Verification (lighter)

- **Byte-exact rebuild** of bank 15 (`tools/cmp_banked.py`).
- **Emulator trace** (`verify/v4trace.py`, as for The Smurfs): every song (6000 ticks) and SFX 1–28. On every tick, stream pointers, order positions and every byte the drum sequencer reads must be on walked items, including 600 ticks after a one-shot song ends. **0 problems** (`verify/run_v4.log`). The lengths above come from this run.
- Not done: no independent model; effects are documented from the code.

## Files (in `GBAudioLab\AJG`)

- `TintinTibet_SoundDriver.asm`: labelled, commented RGBDS source (names carried from The Smurfs through Obélix GB by code alignment), byte-exact
- shared version-4 tools and verification: see `Smurfs_SoundDriver.md`

Regenerate: `python tools/gen_v4.py tibet "Tintin in Tibet (E) (M4) (Eng-Fre-Ger-Dut) [S].gb" TintinTibet_SoundDriver.asm`.
