# Lucky Luke (GB): sound driver

ROM: `Lucky Luke (E) (M4) [M].gb` (DMG, MBC1, 256 KB, internal title `LUCKY LUKE`).

Part of the AJG family (Alberto José González / Bit Managers), see `AJG_SoundEngine_Family.md`. This is **version 4**, documented in full in `Smurfs_SoundDriver.md`. The build mixes the two later lines of the driver:

- **From Prisoners of the Sun** it has the pulse output with a single NRx4 write, and a note on that always resets the vibrato/slide direction.
- **From Spirou** it keeps the pause model, the NR50 forcing and the fade code. It has no `PlayCh1Tone`, no `HwEnvAtten` stub and no `$80` fade byte.

It moves the RAM to `$DB00–$DEFF` and has its own command ranges (two more instruments than Spirou). The Smurfs' Nightmare uses almost the same build (`Smurfs3_SoundDriver.md`), and Die Maus builds on it (`Maus_SoundDriver.md`).

| | |
|---|---|
| Bank | the driver and all its data fill **ROM bank 12** (`$4000–$7FD1`; then a noise-table piece and the cut-off text `Final de la ` at `$7FF3`) |
| Command table | `$4000` (37 commands, `$60–$84`, the Spirou / Obélix GBC set; `NOTE_HOOK` is unused) |
| API jump table | `$404A`: `SndUpdate $40E3`, `SndPause $409F`, `SndResume $4098`, `StopAll $4537`, `PlaySfx $491A`, `SndInit $451C`, `SongFadeIn $495D`, `SongFadeOut $4957`, **17 song entries** (`$4062–$40AA`), `PlaySfxNow $491D` (`$40AD`) |
| Tick | once per frame, called by the game (§1) |
| RAM | **pages Ch1 `$DBxx`, Ch2 `$DCxx`, Ch3 `$DDxx`, SFX `$DExx`** (fields `$00–$41`); globals **`$DB42–$DB65`** (Spirou's layout in page `$DB`) |
| Ranges | **`INSTR $85–$93` (15), `ARP $94–$AF` (28), `VOLENV $B0–$BF`, `LEN $C0–$EF` (1–48), `REPEAT $F0–$FF` (2–17)**; drum tempo bytes `$C0–$FE` (`DRUM_TEMPO` = `$BF`) |
| Tables | SFX `$777E` (40 entries), arpeggios `$76C9` (set by `SndInit`; no song sets one), CH3 volume `$41CB`, drums `$49F3` |
| Counts | 17 songs, 40 SFX, 1 instrument table (`$763C`, 14 entries read), 1 arpeggio table (19 entries read), 17 waves, 10 drum sounds + 15 noise routines called with `CALL_CODE`, 17 drum patterns |

`LuckyLuke_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over the whole of bank 12:

```
rgbasm -Wall -o luckyluke.o LuckyLuke_SoundDriver.asm
rgblink -o luckyluke.gb luckyluke.o
python tools/cmp_banked.py luckyluke.gb "Lucky Luke (E) (M4) [M].gb" 12:4000-7FFF
```

---

## 1. Game glue (bank 0)

There is no sound code in the interrupt handlers (`$0040` and `$0050` are `reti`). Bank 0 has one wrapper per API entry at `$3DF7–$3E7B` (switch to bank 12, call the slot, restore registers). The `PlaySfx` wrapper (`$3E33`, A = id) switches back to bank 1 afterwards.

- **SndUpdate:** the game calls the wrapper `$3DF7` from its frame loops (16 call sites). In an emulator run it is called exactly once per frame (600 calls in 600 frames) once the game is past the start-up screens.
- **Songs:** `$3E7C` reads a routine address from a table in bank 1 (HL) and calls it in bank 12, unless `$DEED` is set. `$3EA0` calls the routine at HL directly.

`wStereo` (`$DB43`) is never written, by the driver or the game, so NR51 is `$FF`. The data has no `PAN_*` or `AUTOPAN` commands anyway.

## 2. Differences from Spirou

| | Spirou | Lucky Luke |
|---|---|---|
| Bank / pages / globals | 15 / `$C1–$C4` / `$C142–$C165` | **12 / `$DB–$DE` / `$DB42–$DB65`** |
| Ranges | `INSTR $85–$91`, `ARP $92–$AD`, `VOLENV $AE`, `LEN $BE`, `REPEAT $EE` (2–19) | **`INSTR $85–$93`, `ARP $94–$AF`, `VOLENV $B0`, `LEN $C0`, `REPEAT $F0` (2–17)** |
| Pulse NRx4 | high byte when changed, then high \| `$80` with the envelope (two writes) | **one write**, as Prisoners of the Sun: high \| `$80` with the envelope, else the high byte when it changed |
| Note on, vibrato/slide direction | reset to down unless bit 4 of the vibrato delay is set | **always reset to down** (as Prisoners of the Sun and Obélix GBC) |
| `NOTE_HOOK` | used by song 3 | **unused**; `SetVolEnvBC` is present but unreferenced (`$436F`) |
| `SndInit` arpeggio table / SFX table / CH3 volume table | `$7603` / `$76AC` / `$41AD` | `$76C9` / `$777E` / `$41CB` |

The rest is Spirou's code:

- **Pause:** `SndPause` silences CH1, CH2 and CH4, and CH3 unless an SFX plays; `SndResume` reloads the music wave. Nothing in the driver calls them.
- **NR50:** forced to `$77` while no fade runs (unless it is 0); `StartMusicCh3` sets NR50 = `$77`. Fades have no `$80` byte and no wave reload.
- **SFX:** `PlaySfx` has no priority test. Both API SFX entries lead to it.
- **Instruments:** `INSTR` leaves auto-duty running. No duty shadows, no NR31/NR41 writes.

### 2.1 Compared with Prisoners of the Sun

Lucky Luke has Prisoners of the Sun's output and note-on code, but not its other changes:

- no `PlayCh1Tone` (the API has 8 entries before the songs, as Spirou);
- no `HwEnvAtten` stub;
- `SndPause`/`SndResume` are not called from `StopAll`, `STOP_ALL` or `SongFadeIn`;
- NR50 is forced to `$77`;
- the fade table has no `$80` pause byte.

### 2.2 Songs

| Song (API slot) | Routine | Ch1 / Ch2 / Ch3 order lists | Instr. table | Length (ticks) |
|---|---|---|---|---|
| 1 (1) | `$732E` | `$734D / $7365 / $737D` | `$763C` | loops |
| 2 (2) | `$4B23` | `$4B43 / $4B57 / $4B6B` | `$763C` | loops |
| 3 (3) | `$4DD7` | `$4DF6 / $4E0A / $4E1E` | `$763C` | loops |
| 4 (4) | `$50BC` | `$50DB / $50EF / $5103` | `$763C` | loops |
| 5 (5) | `$5348` | `$5367 / $5375 / $5383` | `$763C` | loops |
| 6 (6) | `$573E` | `$575D / $5771 / $5785` | `$763C` | loops |
| 7 (7) | `$5987` | `$59A6 / $59B4 / $59C2` | `$763C` | loops |
| 8 (8) | `$5CEF` | `$5D0E / $5D16 / $5D1E` | `$763C` | loops |
| 9 (9) | `$5F12` | `$5F31 / $5F47 / $5F5D` | `$763C` | loops |
| 10 (10) | `$6230` | `$624F / $625B / $6267` | `$763C` | loops |
| 11 (11) | `$644A` | `$6469 / $646F / $6475` | `$763C` | 384, ends |
| 12 (12) | `$64BF` | `$64DE / $64E6 / $64EE` | `$763C` | loops |
| 13 (13) | `$66B7` | `$66D6 / $66E6 / $66F6` | `$763C` | loops |
| 14 (14) | `$68FB` | `$691A / $6920 / $6926` | `$763C` | loops |
| 15 (15) | `$69D4` | `$69F3 / $69F9 / $69FF` | `$763C` | 798, ends |
| 16 (16) | `$6A58` | `$6A77 / $6A81 / $6A8B` | `$763C` | loops |
| 17 (17) | `$6BEF` | `$6C0E / $6C28 / $6C42` | `$763C` | loops |

As in Spirou, song 1's routine is the last song routine in the bank. Every song sets the instrument table `$763C` and uses the arpeggio table from `SndInit`. `INSTR n` reads entry n + 1; the songs use instruments 0, 1, 3–6 and 9–13.

Data usage: music has 46 `REPEAT`s, 18 `VIBRATO`s, 2 `PAT_CALL`s, 11 `RELEASE`s and 28 `WAVE`s. Not used anywhere: `VIB_OFF`, `STOP_ALL`, `DRUMS_OFF`, `PAN_C/R/L`, `AUTOPAN`, `AUTODUTY`, `FADE`, `FADE_OFF`, `PAT_GOTO`, `VOL`, `SLIDE_UP`, `NOTE_HOOK`.

### 2.3 Sound effects

40 SFX on the CH3 page. They use `WAVE`, `LEN`, `VOLENV`, notes, `WAIT`, `REST`, `GLIDE`, `GLIDE_OFF`, `ARP`, `VIBRATO`, `SLIDE_DOWN`, `RELEASE`, `REPEAT`/`REPEAT_END`, `CALL_CODE` and `END`. Eight ids share a stream with a later id (same pointer): 1 = 36, 2 = 32, 8 = 40, 9 = 22, 11 = 27, 12 = 26, 13 = 28, 19 = 25.

| Id | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 25 | 13 | 9 | 11 | 28 | 30 | 6 | 33 | 27 | 12 | 13 | 9 | 45 | 10 | 75 | 20 |

| Id | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 | 30 | 31 | 32 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 8 | 10 | 10 | 15 | 10 | 27 | 27 | 16 | 10 | 9 | 13 | 45 | 29 | 32 | 36 | 13 |

| Id | 33 | 34 | 35 | 36 | 37 | 38 | 39 | 40 |
|---|---|---|---|---|---|---|---|---|
| Ticks | 16 | 30 | 30 | 25 | 12 | 3 | 5 | 33 |

### 2.4 Noise

**The drum sounds are Spirou's**, with the same table layout:

| Drum | 1 | 2 = 8 | 3 = 4 | 5 | 6 | 7 = 9 | 10 |
|---|---|---|---|---|---|---|---|
| Routine | `$7EEE` | `$7F0B` | `$7F37` | `$7F54` | `$7F71` | `$7F8E` | `$7FB0` |

The NR43/NR42 sequences match Spirou's drums 1, 2, 3, 5, 6, 7/9 and 10 byte for byte. The patterns use drums 1–10.

`CALL_CODE` noise routines (hold in ticks):

| Routine | Hold | Note |
|---|---|---|
| `$79E4` | 80 | noise speed 3 |
| `$7AAF` | 24 | NR42 = `$A2` |
| `$7AEB` | 25 | |
| `$7B2B` | 19 | NR42 = `$F1`, noise pan `$88` |
| `$7B58` | 8 | |
| `$7B89` | 36 | NR42 = `$F3` |
| `$7BD8`, `$7BFA`, `$7C89`, `$7CBA`, `$7CE3` | 15 | |
| `$7C43` | 15 | NR42 = `$C2` |
| `$7D10`, `$7D3D` | 4 | |
| `$7D6C` | 33 | noise speed 2 |

---

## 3. Quirks

1. **Panning is dead** (§1).
2. Spirou's note-on test on the vibrato delay is gone, so after a note `SLIDE_UP` and `SLIDE_DOWN` both slide down (only `SLIDE_DOWN` is used, once, in an SFX).
3. The Smurfs quirks 4–7 apply.
4. **Unreferenced (marked in the asm):**
   - `SetVolEnvBC` (`$436F`, 39 bytes);
   - stray `ret` bytes (`$4437`, `$4B42`);
   - 89 zero bytes before the period table (`$47A7`);
   - the drum table's 11th slot (`$4A07`);
   - the loop words of songs 11 and 15's order lists, which end with `END`;
   - a 15th instrument entry (`$765A`) and its macro (`$76C3`);
   - unused arpeggio table entries and data (`$76EF`, `$7761`);
   - an SFX-like stream not in the table (`$7969`);
   - two noise routines with their tables, not called from anywhere (`$7A24`, 111 bytes);
   - noise-table pieces (`$7AE2`, `$7B28`, `$7C42`, `$7C77`, `$7FD2`);
   - the cut-off end text.

## 4. Verification (lighter)

- **Byte-exact rebuild** of bank 12 (`tools/cmp_banked.py`).
- **Emulator trace** (`verify/v4trace.py`): songs 1–17 (6000 ticks each) and SFX 1–40. **0 problems** (`verify/run_v4.log`). The lengths above come from this run.
- Glue: the once-per-frame call rate was measured in PyBoy.
- Not done: no independent model.

## Files (in `GBAudioLab\AJG`)

- `LuckyLuke_SoundDriver.asm`: labelled, commented RGBDS source (names carried from The Smurfs through Obélix GBC and Spirou by code alignment), byte-exact
- shared version-4 tools and verification: see `Smurfs_SoundDriver.md`

Regenerate: `python tools/gen_v4.py luckyluke "Lucky Luke (E) (M4) [M].gb" LuckyLuke_SoundDriver.asm`.
