# Hugo 2 (GB): sound driver

ROM: `Hugo 2 (G) [S][!].gb` (DMG, MBC1, 128 KB, internal title `HUGO2`).

Part of the AJG family (Alberto José González / Bit Managers), see `AJG_SoundEngine_Family.md`. This is **version 4**, documented in full in `Smurfs_SoundDriver.md`. The driver is **Prisoners of the Sun's** (`TintinSun_SoundDriver.md`) with the same RAM layout, command table and command ranges. It differs in three points:

- `PlayCh1Tone` is gone;
- `StopAll` sets a default instrument table;
- the game's SFX glue sits right after the API table.

The Turok games (`Turok_SoundDriver.md`) are the other members of this Prisoners of the Sun group.

| | |
|---|---|
| Bank | the driver and its data fill **ROM bank 7** from `$4000` to `$68EE`; the rest of the bank (`$68EF–$7FFF`) is other game data, not sound |
| Command table | `$4000` (37 commands, `$60–$84`, with `NOTE_HOOK`) |
| API jump table | `$404A`: `SndUpdate $40DC`, `SndPause $40A3`, `SndResume $409C`, `StopAll $4530`, `PlaySfx $4916` (→ glue), `SndInit $4515`, `SongFadeIn $4959`, `SongFadeOut $4953`, **8 song slots** (`$4062–$4077`), **7 dead slots** (`$407A–$408C`, all `jp $5F8E`); no `PlayCh1Tone`, no `PlaySfxNow` |
| Glue | `GamePlaySfxGlue` at `$408F`, right after the table (§1) |
| Tick | VBlank, once per frame (59.73 Hz) |
| RAM | pages Ch1 `$DCxx`, Ch2 `$DDxx`, Ch3 `$DExx`, SFX `$DFxx`; globals `$DC42–$DC65` (as Prisoners of the Sun) |
| Ranges | `INSTR $85–$95`, `ARP $96–$B1`, `VOLENV $B2–$C1`, `LEN $C2–$F1` (1–48), `REPEAT $F2–$FF` (2–15); drum tempo bytes `$C2–$FE` (all as Prisoners of the Sun) |
| Tables | SFX `$63CB` (from `$63C9`, 16 entries), arpeggios `$62A3` (set by `SndInit`; no song sets one), CH3 volume `$41C4`, drums `$49F4` (from `$49F2`, 11 entries) |
| Counts | 8 songs, 16 SFX (2 of them noise routines), 2 instrument tables (`$61A7`, 12 entries; `$6229`, 15 entries), 1 arpeggio table (28 entries, 19 arpeggios used), 12 waves, 11 drum sounds + 5 noise routines called with `CALL_CODE`, 15 drum patterns |

`Hugo2_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over the whole of bank 7:

```
rgbasm -Wall -o hugo2.o Hugo2_SoundDriver.asm
rgblink -o hugo2.gb hugo2.o
python tools/cmp_banked.py hugo2.gb "Hugo 2 (G) [S][!].gb" 7:4000-7FFF
```

---

## 1. Game glue

**Bank 0.** The VBlank handler (`$0F30`) switches to bank 7 (`$0F63`) and does the following:

- **Songs:** a routine address posted in `$C2DF/$C2E0` (A = `$C2DE`) is cleared and called.
- **SFX:** if the queue count `$C2D8` is not 0, it is decremented and that one queued id (from `$C2D9`) goes to `PlaySfx` (API slot 4). That is one SFX per frame.
- **Update:** then `SndUpdate`.

The same handler shape as both Turok games.

**Bank 7.** `PlaySfxEntry` (`$4916`, API slot 4) jumps to `GamePlaySfxGlue` (`$408F`), just after the API table:

- id 2 jumps to `Sfx02_Noise` (`$64F1`);
- id 3 jumps to `Sfx03_Noise` (`$6561`);
- anything else goes on to `jp PlaySfx` (`$4099`).

The two noise routines work like drum sounds:

- they set `wNoiseOn`, the hold timer (`wDrumHold`: 10 and 8) and NR43/NR42 sequence pointers (`$6513/$651F` and `$6583/$6587`);
- they don't touch the SFX page;
- **their SFX table entries are placeholders.** Entry 2 holds `$63CD` and entry 3 `$63CF`, the addresses of the entries themselves.

This is the same idea as The Smurfs' noise SFX 30–32, but here the glue lives in the sound bank.

`wStereo` (`$DC43`) is never written, by the driver or the game, so NR51 is `$FF`. The data has no `PAN_*` or `AUTOPAN` commands anyway.

## 2. Differences from Prisoners of the Sun

| | Prisoners of the Sun | Hugo 2 |
|---|---|---|
| Bank | 15 | **7** (shared with other game data from `$68EF`) |
| API | 8 entries + `PlayCh1Tone` + 17 song slots + `PlaySfxNow` | 8 entries + **8 song slots + 7 dead slots**; no `PlayCh1Tone`, no `PlaySfxNow` |
| `PlaySfxEntry` | `jp PlaySfx` | **`jp GamePlaySfxGlue`** (§1) |
| `PlayCh1Tone` | `$409B` | **removed**; the code before `$4530` is `$14` bytes shorter |
| `StopAll` | `SndResume`, then silence and page resets | also **sets `wInstrTable` = `$6227`** after `SndResume` (`$4533`) |
| `SndInit` arpeggio table / SFX table / CH3 volume table | `$7145` / `$7236` / `$41D8` | `$62A3` / `$63CB` / `$41C4` |

From `PlaySfx` (`$4919`) on, the code is at the same addresses as in Prisoners of the Sun and identical apart from table addresses. Everything else is as there, including:

- the pause model (`SndPause` and `SndResume` both silence and reset the SFX page; `StopAll` and `SongFadeIn` call `SndResume`);
- no SFX priority;
- the single NRx4 write;
- the `HwEnvAtten` stub (`$4611`);
- note on always resets the slide direction;
- no NR50 forcing;
- unused `NOTE_HOOK`, with `SetVolEnvBC` unreferenced (`$4368`).

### 2.1 Songs

Every song routine first calls `StopAll`, which sets instrument table 2 (`$6227`). Songs 2–4 keep it; songs 1 and 5–8 then set instrument table 1 (`$61A5`).

| Song (API slot) | Routine | Ch1 / Ch2 / Ch3 order lists | Instr. table | Length (ticks) |
|---|---|---|---|---|
| 1 (1) | `$5F97` | `$5FCF / $5FC3 / $5FB7` | `$61A5` | loops |
| 2 (2) | `$4B24` | `$4B3A / $4B6E / $4B54` | `$6227` | loops |
| 3 (3) | `$4E6F` | `$4EC9 / $4EB3 / $4E85` | `$6227` | loops |
| 4 (4) | `$5171` | `$5187 / $51AF / $519B` | `$6227` | loops |
| 5 (5) | `$554B` | `$556A / $5596 / $5580` | `$61A5` | loops |
| 6 (6) | `$59E0` | `$5A00 / $5A20 / $5A10` | `$61A5` | loops |
| 7 (7) | `$5DDF` | `$5DFE / $5E0A / $5E04` | `$61A5` | 384, ends |
| 8 (8) | `$5EE9` | `$5F08 / $5F14 / $5F0E` | `$61A5` | 317, ends |

**API slots 9–15 are dead.** All seven `jp $5F8E`, which is not a routine. It is a small pattern, `TRANSPOSE 0`, `NEXT`, followed by `TRANSPOSE 1`, `NEXT` (`$5F91`). Song 3's Ch3 order list uses both patterns to change key. Nothing calls those slots. A converter must skip them, not dedupe them.

Data usage: 31 `REPEAT`s, 15 `VIBRATO`s, 5 `CALL_CODE`s, 12 `PAT_CALL`s. Not used: `STOP_ALL`, `PAN_C/R/L`, `AUTOPAN`, `FADE`, `FADE_OFF`, `PAT_GOTO`, `VOL`, `SLIDE_UP`, `SLIDE_DOWN`, `NOTE_HOOK`.

### 2.2 Sound effects

16 ids. Ids 2 and 3 are the glue's noise routines (§1); the other 14 are CH3-page streams. **SFX 16 (`$63EB`) starts right after the table**, and its entry is the table's last word (`$63E9`).

| Id | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| Ticks | 25 | 11 (noise) | 3 (noise) | 13 | 9 | 10 | 20 | 33 |

| Id | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 |
|---|---|---|---|---|---|---|---|---|
| Ticks | 9 | 27 | 12 | 28 | 57 | 66 | 12 | 81 |

### 2.3 Noise

Prisoners of the Sun's kit, with some sequences changed. The drum table has **11 entries** (Prisoners of the Sun 10); drum 8 reuses drum 2's routine.

| Drum | Routine | NR43 sequence | NR42 sequence |
|---|---|---|---|
| 1 | `$674C` | `01 61 71 A1 B1 B1 A1` | `C1 F0 A0 90 70 40 33` |
| 2 = 8 | `$6778` | `60 52 42 41 22 11 04` | `F0 F0 F0 A0 70 40 51` |
| 3 | `$67A4` | `50 41 50 51 42 53 51` | `D0 70 90 60 C0 50 61` |
| 4 | `$67C1` | `04 02 01 01 01 01 01` | `70 FF FF FF FF 54 FF` |
| 5 | `$67ED` | `02 00 00 00 00 00 00` | `90 52 FF FF FF FF FF` |
| 6 | `$6819` | `04 02 01 01 01 01 01` | `60 30 32 FF FF FF FF` |
| 7 | `$6845` | `06 04 03 03 07` | `F0 C0 80 60 55` |
| 9 | `$686D` | `51 32` | `F0 62` |
| 10 | `$688F` | `51 32` | `70 52` |
| 11 | `$68AC` | `51 32 32 32 32 51 32` | `70 51 FF FF FF 70 51` |

Drums 10 and 11 are in the table (and disassembled) but no drum pattern uses them. `CALL_CODE` noise routines: `$652A` (hold 40), `$658A` (hold 19), `$65D3`, `$660F` (hold 15), `$6640` (hold 4).

---

## 3. Quirks

1. **Dead API song slots 9–15** jump into pattern data (§2.1).
2. **Placeholder SFX entries** 2 and 3 point into the SFX table itself; the glue plays those ids as noise routines (§1).
3. **Panning is dead** (§1).
4. **The driver shares its bank** with non-sound data from `$68EF`; it is the only version-4 build so far that doesn't have a bank to itself.
5. The Prisoners of the Sun quirks apply (slides lose their direction at every note, the `HwEnvAtten` stub, unused `NOTE_HOOK` and `$80` fade byte).
6. **Unreferenced (marked in the asm):**
   - `Unused_SetVolEnvBC` (`$4368`);
   - padding before the period table (`$47B9`): a stale copy of SM83 code from the wave loader, then PC memory garbage (x86 code bytes);
   - stray `ret` bytes;
   - unreached order-list ends (`$5E00–$5F16`, from songs 7 and 8);
   - unreached bytes after the transpose patterns (`$5F94`: `TRANSPOSE 2`, `NEXT`) and a lone `NEXT` byte after song 1's routine (`$5FB6`);
   - the last 4 arpeggio table entries (`$62D3`) and the unused arpeggio they point at (`$638C`);
   - wave-sized blocks.

## 4. Verification (lighter)

- **Byte-exact rebuild** of bank 7 (`tools/cmp_banked.py`).
- **Emulator trace** (`verify/v4trace.py`): the 8 song routines (6000 ticks) and SFX 1–16, all through `PlaySfxEntry`, so the glue and both noise routines run. On every tick, stream pointers, order positions and every byte the drum sequencer reads must be on walked items. **0 problems** (`verify/run_v4.log`). The lengths above come from this run.
- Not done: no independent model.

## Files (in `GBAudioLab\AJG`)

- `Hugo2_SoundDriver.asm`: labelled, commented RGBDS source (names carried from The Smurfs through Obélix GBC and Prisoners of the Sun by code alignment), byte-exact
- shared version-4 tools and verification: see `Smurfs_SoundDriver.md` and the family doc §4

Regenerate: `python tools/gen_v4.py hugo2 "Hugo 2 (G) [S][!].gb" Hugo2_SoundDriver.asm`.
