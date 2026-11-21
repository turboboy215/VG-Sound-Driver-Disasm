# Tintin: Prisoners of the Sun (GB): sound driver

ROM: `Les Aventures De TinTin - Le Temple du Soleil (E) (M3) [M].gb` (DMG, MBC1, 256 KB, internal title `TINTIN TEMPLESUN`). Infogrames, 1997.

Part of the AJG family (Alberto José González / Bit Managers), see `AJG_SoundEngine_Family.md`. This is **version 4**, documented in full in `Smurfs_SoundDriver.md`. Of the documented builds, its driver is **closest to the Astérix & Obélix GBC build** of 1999 (`Obelix_SoundDriver.md`, §3), from which it differs in only five points:

- the pages are at `$DC–$DF`;
- there are no duty shadows;
- there are no NR31/NR41 writes;
- `SndInit` doesn't set `wStereo`;
- an extra API routine plays a game-driven tone on CH1.

It has the same command table (37 commands, with `NOTE_HOOK`), the same command ranges, the same pause and SFX model and the same output code. The Obélix GBC driver looks like this one carried over to the GBC.

| | |
|---|---|
| Bank | the driver and all its data fill **ROM bank 15** (`$4000–$7A70`; then the text `Final de la rutina de musica` and `$FF` fill) |
| Command table | `$4000` (37 commands, `$60–$84`) |
| API jump table | `$404A`: `SndUpdate $40F0`, `SndPause $40B7`, `SndResume $40B0`, `StopAll $4544`, `PlaySfx $4916`, `SndInit $4529`, `SongFadeIn $4959`, `SongFadeOut $4953`, **`PlayCh1Tone $409B`** (new, `$4062`), **17 song slots** (`$4065–$4095`, 14 songs), `PlaySfxNow $4919` (`$4098`) |
| Tick | VBlank, once per frame (59.73 Hz) |
| RAM | **pages Ch1 `$DCxx`, Ch2 `$DDxx`, Ch3 `$DExx`, SFX `$DFxx`** (fields `$00–$41`); **globals `$DC42–$DC65`** in page `$DC` (Obélix GBC `$C142`, same order, without the duty shadows) |
| Ranges | `INSTR $85–$95`, `ARP $96–$B1`, `VOLENV $B2–$C1`, `LEN $C2–$F1` (1–48), `REPEAT $F2–$FF` (2–15); drum tempo bytes `$C2–$FE` (all as Obélix GBC) |
| Counts | 14 songs (17 API slots), 21 SFX, 1 instrument table (17 entries), 1 arpeggio table (28 entries, 18 used), 19 waves, 10 drum sounds + 10 noise routines called with `CALL_CODE`, 18 drum patterns |

`TintinSun_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over the whole of bank 15:

```
rgbasm -Wall -o sun.o TintinSun_SoundDriver.asm
rgblink -o sun.gb sun.o
python tools/cmp_banked.py sun.gb "Les Aventures De TinTin - Le Temple du Soleil (E) (M3) [M].gb" 15:4000-7FFF
```

---

## 1. Game glue (bank 0)

The VBlank handler (`$0DB4`) switches to bank 15 (at `$0DEA`) and does the following:

- **CH1 tone:** while `$C2E5` is set, it calls `PlayCh1Tone` with BC = `$C2F5/$C2F6`. One game mode sets the flag (bank 2, `$6BDD`) and writes `$C2F5/$C2F6` = a game variable (`$DCDF`) × 8 (bank 2, `$7C0E`).
- **Songs:** a routine address posted in `$C2E1/$C2E2` (A = `$C2E0`) is cleared and called (`jp hl` at `$1437`).
- **SFX:** queued ids (count `$C2DA`, ids from `$C2DB`) go to `PlaySfx` (API slot 4).
- **Update:** then `SndUpdate`, once.

`wStereo` (`$DC43`) is never written by the driver or the game, and it stays 0 through boot and the title screen. NR51 is therefore `$FF` all the time. The data uses no `PAN_*` commands.

## 2. Differences from Astérix & Obélix GBC

| | Astérix & Obélix GBC | Prisoners of the Sun |
|---|---|---|
| Bank | 6 | **15** |
| Pages / globals | `$C1–$C4` / `$C142–$C167` | **`$DC–$DF` / `$DC42–$DC65`** (all page tests are renumbered: `cp $DC`, `cp $DE`, …) |
| API | 8 entries + 16 songs + `PlaySfxNow` | 8 entries + **`PlayCh1Tone`** + 17 song slots + `PlaySfxNow` |
| Duty | `DUTY_*`, auto-duty and `INSTR` write `wDutyCh1/2`, output rewrites NR11/NR21 every tick | **written straight to NR11/NR21** (no shadows); `INSTR` still leaves auto-duty running |
| CH3 | NR31 = 0 at every output and wave load | no NR31 writes |
| Noise steps | NR41 = 0 before NR43 and before NR44 | no NR41 writes |
| `SndInit` | also `wStereo` = `$FF` | **no `wStereo` write** (so NR51 = `$FF`, §1) |
| `SndInit` arpeggio table | `$74AC` | `$7145` (no song sets it) |
| SFX table / CH3 volume table / drum table | `$7598` / `$41CA` / `$49F4` | `$7236` (from `$7234`) / `$41D8` / `$49F4` (from `$49F2`) |

Everything else is as in Obélix GBC §3, including:

- the pause model: `SndPause` and `SndResume` both silence CH1–CH4 and reset the SFX page, and `StopAll` and `SongFadeIn` call `SndResume`;
- no SFX priority;
- the single NRx4 write (high | `$80` with the envelope, else high when changed);
- the `HwEnvAtten` stub;
- `NOTE_HOOK` (unused here);
- note on always resets the vibrato/slide direction to down;
- NR50 not forced to `$77`, with `$80` in a fade table pausing the driver (unused by the two tables).

### 2.1 `PlayCh1Tone` (API slot 9, `$409B`)

BC = period. It writes the Ch1 page's period (`$DC05/$DC06`), puts NRx2 = `$F0` with the write flag set (`$DC32/$DC33`), and writes NR11 = `$C0` (75 % duty). The Ch1 output, which runs every tick whether the page is active or not, then plays the tone at volume 15 with no envelope. Because the game calls it every frame, CH1 is retriggered every frame at a pitch the game controls. A playing Ch1 track would overwrite it.

**Song 10 starts no Ch1 track** (only Ch2 and Ch3), so CH1 is free for the tone while it plays. This fits the tone mode, but the code paths weren't followed far enough to confirm that the tone mode plays song 10.

### 2.2 Songs

| Song (API slot) | Routine | Ch1 / Ch2 / Ch3 order lists | Length (ticks) |
|---|---|---|---|
| 1 (slots 1, 15, 16, 17) | `$6E68` | `$6E88 / $6EA0 / $6EB8` | loops |
| 2 | `$4B24` | `$4B43 / $4B67 / $4B55` | loops |
| 3 | `$4DDF` | `$4DFE / $4E04 / $4E1C` | loops |
| 4 | `$4F47` | `$4F66 / $4F92 / $4F7C` | loops |
| 5 | `$5207` | `$5227 / $5241 / $525B` | loops |
| 6 | `$5698` | `$56B7 / $56C7 / $56D7` | loops |
| 7 | `$5864` | `$5883 / $58A3 / $5893` | loops |
| 8 | `$5B6D` | `$5B8C / $5B9C / $5BAC` | loops |
| 9 | `$5E60` | `$5E7F / $5E93 / $5EA7` | loops |
| 10 | `$60E7` | **– / `$6100` / `$6110`** | loops |
| 11 | `$63FC` | `$641B / $642B / $643B` | loops |
| 12 | `$67D5` | `$67F4 / $6804 / $6814` | loops |
| 13 | `$6B83` | `$6BA2 / $6BB8 / $6BCE` | loops |
| 14 | `$6D8A` | `$6DA9 / $6DB9 / $6DB1` | 880, ends |

Songs are numbered by first API slot. **Slot 1 and the last three slots (15–17) all start song 1.** All songs set the one instrument table `$70B4` (17 instruments, all used) and use the arpeggio table `$7145` from `SndInit`. A converter walking the API table should dedupe by routine.

Data usage: 94 `REPEAT`s, 24 `VIBRATO`s. Not used: `STOP_ALL`, `PAN_C/R/L`, `AUTOPAN`, `FADE`, `FADE_OFF`, `VOL`, `SLIDE_UP`, `NOTE_HOOK`.

### 2.3 Sound effects

21 SFX on the CH3 page. SFX 21 (`$7264`) is noise only: `CALL_CODE $7654`, `END`. They use `WAVE`, `LEN`, `VOLENV`, notes, `WAIT`, `REST`, `GLIDE`, `GLIDE_OFF`, `ARP`, `VIBRATO`, `SLIDE_DOWN`, `CALL_CODE` and `END`.

| Id | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 7 | 8 | 13 | 6 | 13 | 9 | 12 | 25 | 11 | 12 | 3 |

| Id | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 |
|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 16 | 13 | 11 | 12 | 27 | 27 | 28 | 5 | 40 | 9 |

### 2.4 Noise

**A new drum kit** (shared with Spirou). Drums 2, 7, 8 and 10 have the Obélix sequences.

| Drum | Routine | NR43 sequence | NR42 sequence |
|---|---|---|---|
| 1 | `$7926` | `02 61 71 A1 B1 B1 A1` | `C1 F0 A0 90 70 40 33` |
| 2 | `$796B` | `60 52 42 41 22 11 04` | `F0 F0 F0 A0 70 40 51` |
| 3 = 4 | `$7997` | `04 02 01 01 01 01 01` | `70 40 40 40 40 43 FF` |
| 5 | `$79B4` | `04 02 01 01 01 01 01` | `A0 60 32 FF FF FF FF` |
| 6 | `$79D1` | `04 02 01 01 01 01 01` | `60 30 12 FF FF FF FF` |
| 7 | `$79EE` | `06 04 03 03 07` | `F0 C0 80 60 55` |
| 8 | `$7943` | `04 02 01 00 00` | `40 60 70 82 71` |
| 9 | `$7A0B` | `51 32` | `F0 62` |
| 10 | `$7A2D` | `51 32` | `90 61` |

`$FF` in an NR42 sequence means no NR42 write and no retrigger: the running sound continues with the new NR43 value. **The drum table's 11th slot (`$4A08` → `$7A4A`) is not a routine.** It points at the next data, an NR43 table (`DrumTable` has 10 entries here; Obélix has 11).

`CALL_CODE` noise routines: `$737D` (NR42 = `$F2`, hold 19), `$73AA` (NR42 = `$F1`, hold 19), `$74D9` (NR42 = `$F2`, hold 15), `$750D`, `$753E`, `$756F` (hold 15), `$74A0`, `$7621` (hold 10), `$7473`, `$75F2` (hold 4). Drum 7 (`$79EE`) is also started directly with `CALL_CODE`.

---

## 3. Quirks

1. **Duplicate song slots** (1, 15, 16, 17 → song 1).
2. **Panning is dead** (§1).
3. The Obélix GBC quirks apply:
   - slides lose their direction at every note;
   - `HwEnvAtten` is a stub;
   - `NOTE_HOOK` and the `$80` fade byte are unused;
   - The Smurfs quirks 4–7.
4. **Unreferenced (marked in the asm):**
   - `Unused_SetVolEnvBC` at `$437C`: the `NOTE_HOOK` envelope helper that Spirou uses (§ there);
   - code fragments before the period table (`$47C3`);
   - stray `ret` bytes, the drum table's 11th slot (`$4A08`);
   - unreached pattern bytes in songs 2 and 9 (`$4B97`, `$4B9D`, `$5F4D`);
   - the end of song 14's order lists;
   - 10 unused arpeggio table entries (`$7169`) and arpeggios (`$7211`);
   - an SFX-like stream not in the SFX table (`$72BD`: `CALL_CODE $7598`, `END`) and the two noise routines at `$7598`/`$75C5`;
   - four more noise routines (`$73D7`, `$7408`, `$742A`, `$7692`);
   - wave-sized blocks (`$76CF–$78AE`);
   - the rest of an NR43/NR42 pair (`$7A4F`);
   - the end text and fill.

## 4. Verification (lighter)

- **Byte-exact rebuild** of bank 15 (`tools/cmp_banked.py`).
- **Emulator trace** (`verify/v4trace.py`): the 14 song routines (6000 ticks) and SFX 1–21. On every tick, stream pointers, order positions and every byte the drum sequencer reads must be on walked items. **0 problems** (`verify/run_v4.log`). The lengths above come from this run. `PlayCh1Tone` is not exercised by the trace.
- Not done: no independent model.

## Files (in `GBAudioLab\AJG`)

- `TintinSun_SoundDriver.asm`: labelled, commented RGBDS source (names carried from The Smurfs through Obélix GBC by code alignment), byte-exact
- shared version-4 tools and verification: see `Smurfs_SoundDriver.md`

Regenerate: `python tools/gen_v4.py sun "Les Aventures De TinTin - Le Temple du Soleil (E) (M3) [M].gb" TintinSun_SoundDriver.asm`.
