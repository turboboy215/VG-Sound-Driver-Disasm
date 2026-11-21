# Die Maus (GB): sound driver

ROM: `Maus, Die (E) (M4) [M].gb` (DMG, MBC1, 256 KB, internal title `DIE MAUS`).

Part of the AJG family (Alberto José González / Bit Managers), see `AJG_SoundEngine_Family.md`. This is **version 4**, documented in full in `Smurfs_SoundDriver.md`. The build is **based on Lucky Luke's driver** (`LuckyLuke_SoundDriver.md`), but it changes more than any other version-4 build so far:

- **a new portamento** (`PORTA step, lead` / `PORTA_OFF`) that looks ahead in the stream for the next note;
- `SLIDE_UP` and `SLIDE_DOWN` are dropped, and `NOTE_HOOK` moves from `$84` to `$82`;
- **Prisoners of the Sun's `SndPause`/`SndResume`** (both silence all channels and reset the SFX page);
- `INSTR` also stops vibrato and auto-duty;
- pages back at `$C1–$C4`, globals at `$C14B`;
- the driver is ticked from the **timer interrupt**.

| | |
|---|---|
| Bank | the driver and all its data fill **ROM bank 15** (`$4000–$7578`; then 2695 bytes of leftovers to the end of the bank) |
| Command table | `$4000` (37 commands, `$60–$84`: Lucky Luke's `$60–$81`, then **`NOTE_HOOK $82`, `PORTA $83`, `PORTA_OFF $84`**) |
| API jump table | `$404A`: `SndUpdate $40C9`, `SndPause $4090`, `SndResume $4089`, `StopAll $4516`, `PlaySfx $491A`, `SndInit $44FB`, `SongFadeIn $495D`, `SongFadeOut $4957`, **12 song slots** (`$4062–$407D`; 9 songs), `PlaySfxNow $491D` (`$4080`) |
| Tick | timer interrupt, re-synchronised to VBlank every frame (§1): once per frame |
| RAM | pages Ch1 `$C1xx`, Ch2 `$C2xx`, Ch3 `$C3xx`, SFX `$C4xx` (fields **`$00–$4A`**); globals **`$C14B–$C16E`** (Spirou's layout, 9 bytes higher) |
| Ranges | **`INSTR $85–$92` (14), `ARP $93–$AB` (25), `VOLENV $AC–$BB`, `LEN $BC–$EB` (1–48), `REPEAT $EC–$FF` (2–21)**; drum tempo bytes `$BC–$FE` (`DRUM_TEMPO` = `$BB`) |
| Tables | SFX `$6A4E` (61 entries), arpeggios `$6933` (set by `SndInit`; no song sets one), CH3 volume `$41BA`, drums `$49F3` |
| Counts | 9 songs, 61 SFX, 3 instrument tables (`$68A5` 10 entries read, `$5A38` 5, `$5EC8` 2), 1 arpeggio table (19 entries read), 16 waves, 9 drum sounds + 16 noise routines called with `CALL_CODE`, 7 drum patterns |

`Maus_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over the whole of bank 15:

```
rgbasm -Wall -o maus.o Maus_SoundDriver.asm
rgblink -o maus.gb maus.o
python tools/cmp_banked.py maus.gb "Maus, Die (E) (M4) [M].gb" 15:4000-7FFF
```

---

## 1. Game glue (bank 0)

The sound runs in the **timer interrupt** (`$0050` → `$0305`). The handler switches to bank 15 and then:

- **Mailbox:** if `$DBD2` is set, it calls the routine whose address is in `$DBD0/$DBD1` (through `jp hl` at `$1AC6`) and clears the flag. The game posts API slot addresses there.
- **SFX:** if `$FFD8` holds an id, it calls `PlaySfx` (API slot 4) and clears it.
- **Update:** it calls `SndUpdate` (`$033B`, with interrupts off), then restores the bank.

The timer runs at 4096 Hz (TAC = `$04`):

- **Normally:** the VBlank handler (`$19AA`) reloads TIMA and TMA with `$D0` every frame while `$FF93` is set. The timer then fires once per frame, 48 timer counts (about 11.7 ms) after VBlank. In an emulator run `SndUpdate` was called 600 times in 600 frames.
- **While `$FF93` is clear:** TMA is `$BB` (set at `$02A2` and `$1DF9`), so the timer runs free at 4096 / 69 = **59.36 Hz**. This is the same idea as Pop Up's LCD-off timer.

`wStereo` (`$C14C`) is never written, so NR51 is `$FF`. The data has no pan commands.

## 2. Differences from Lucky Luke

| | Lucky Luke | Die Maus |
|---|---|---|
| Bank / pages / globals | 12 / `$DB–$DE` / `$DB42` | **15 / `$C1–$C4` / `$C14B`** |
| Fields | `$00–$41` | **`$00–$4A`** (porta state `$42–$4A`) |
| Ranges | `INSTR $85–$93`, `ARP $94–$AF`, `VOLENV $B0`, `LEN $C0`, `REPEAT $F0` (2–17) | **`INSTR $85–$92`, `ARP $93–$AB`, `VOLENV $AC`, `LEN $BC`, `REPEAT $EC` (2–21)** |
| Commands `$82–$84` | `SLIDE_UP`, `SLIDE_DOWN`, `NOTE_HOOK` | **`NOTE_HOOK`, `PORTA step, lead`, `PORTA_OFF`** (§2.1) |
| Output | period + pitch offset | `AddPortaOffset` first moves the period fields `$05/$06` by the porta offset (CH1, CH2 and the CH3/SFX output) |
| Note on | | clears the porta state (`$48–$4A`) and runs `PortaStart` |
| `INSTR` | clears arpeggio, glide, arpeggio offset | **also vibrato (bit 3) and auto-duty (field `$2F`)** |
| `VIBRATO` / `VIB_OFF` | `or $18` / `and $E7` | `set 3` + `set 4` / **`res 3` only** (the direction bit stays) |
| `RELEASE t, env` | env as given | **an env byte of 0 becomes `$11`** (not used by the data) |
| `SndPause` / `SndResume` | pause silences CH1, CH2, CH4 (CH3 unless an SFX plays); resume reloads the wave | **as Prisoners of the Sun:** both silence CH1–CH4 and reset the SFX page (which reloads the music wave) |
| Calls to `SndResume` | none | none (unlike Prisoners of the Sun, `StopAll`, `STOP_ALL` and `SongFadeIn` do not call it) |

Unchanged from Lucky Luke:

- the single NRx4 write and the direction reset at note on;
- NR50 forced to `$77` while no fade runs, and no `$80` fade byte;
- no SFX priority;
- no `PlayCh1Tone`, no `HwEnvAtten`;
- `SetVolEnvBC` present but unreferenced (`$436E`).

### 2.1 `PORTA step, lead`

`PORTA` (`$83`, two bytes) sets field `$42` = step, `$43` = lead and flag bit 6 of field `$04`; `PORTA_OFF` (`$84`) clears the flag. While the flag is on, every note slides to the next note:

1. **At note on** (`PortaStart`, `$4BAE`) the driver scans the stream after the note:
   - The delay (`$44`) starts at this note's length; each `WAIT` or `REST` adds another length.
   - `VOLENV` (4 bytes) and `PORTA` (3 bytes) are skipped whole. **Any other byte counts as one byte**: `LEN` changes are not followed, and command arguments are read as commands.
   - `END` or `NEXT` before a note: no slide.
2. **At the next note** the delay becomes delay − lead (not below 0), and the direction is set: `$45` = 1 down, 2 up, 0 for the same note.
3. **The distance** is the difference between the two notes' periods, stored in `$46/$47`. Each note includes the channel and global transposes, but not the arpeggio.
4. **Each tick** (`PortaTick`, `$4B40`):
   - The delay counts down first.
   - Then the offset `$48/$49` grows by `step` per tick, with `$4A` = 1 for down.
   - When it reaches the distance it is clamped and the slide stops.
5. **At output** (`AddPortaOffset`, `$4B23`) the offset is added to the period, or subtracted from it when `$4A` = 1.

So the pitch glides from the current note towards the next during the last `lead` ticks before it, at `step` period units per tick, and stops at the target. The next note on resets the offset.

**Only SFX 21 uses it:** `PORTA $02, $1E`, a 35-tick D6 followed by a 1-tick C1. The slide starts after 5 ticks and drops 2 period units per tick for 30 ticks (60 units, far short of C1), with vibrato on top.

### 2.2 Songs

| Song (API slot) | Routine | Ch1 / Ch2 / Ch3 order lists | Instr. table | Length (ticks) |
|---|---|---|---|---|
| 1 (1, 10, 11, 12) | `$6696` | `$66AB / $66B7 / $66C3` | – | loops |
| 2 (2) | `$4C74` | `$4C94 / $4CC8 / $4CAE` | `$68A5` | loops |
| 3 (3) | `$510C` | `$512B / $513B / $514B` | `$68A5` | loops |
| 4 (4) | `$550B` | `$5544 / $555E / $552A` | `$5A38` | loops |
| 5 (5) | `$5AAA` | `$5AE5 / $5AD7 / $5AC9` | `$5EC8` | loops |
| 6 (6) | `$5EE1` | `$5F1C / $5F0E / $5F00` | `$5A38` | loops |
| 7 (7) | `$62DB` | `$630A / $6302 / $62FA` | `$68A5` | loops |
| 8 (8) | `$6460` | `$648B / $6485 / $647F` | `$68A5` | loops |
| 9 (9) | `$6519` | `$6548 / $6540 / $6538` | `$68A5` | 2400, ends |

- **Song slots:** song 1 fills slots 1 and 10–12, as Prisoners of the Sun repeats its song 1. Dedupe by routine.
- **Song 1** sets no instrument table and has no `INSTR`. Songs 7–9 set `$68A5` but have no `INSTR` either.
- **Arpeggios:** all songs use the table from `SndInit`.
- **Usage:** music has 136 `WAIT`s, 53 `WAIT2`s, 10 `VIBRATO`s, 6 `RELEASE`s and 1 `PAT_GOTO`, and no `REPEAT`.
- **Not used anywhere:** `VIB_OFF`, `STOP_ALL`, `TRANSPOSE`, `DRUMS_OFF`, `PAN_C/R/L`, `AUTOPAN`, `AUTODUTY`, `FADE`, `FADE_OFF`, `ARP_OFF`, `PAT_CALL`, `VOL`, `NOTE_HOOK`, `PORTA_OFF`.

### 2.3 Sound effects

61 SFX on the CH3 page. They use `WAVE`, `LEN`, `VOLENV`, notes, `WAIT`, `REST`, `GLIDE`, `GLIDE_OFF`, `ARP`, `VIBRATO`, `CH_TRANSPOSE`, `RELEASE`, `REPEAT`/`REPEAT_END` (once), `CALL_CODE`, `PORTA` (SFX 21) and `END`. SFX 1–3 have the same lengths as Lucky Luke's and The Smurfs' Nightmare's SFX 1–3.

| Id | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 25 | 13 | 9 | 40 | 40 | 40 | 40 | 40 | 3 | 58 | 10 | 20 | 33 | 27 | 5 | 10 |

| Id | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 | 30 | 31 | 32 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 10 | 57 | 65 | 44 | 37 | 14 | 126 | 28 | 17 | 13 | 9 | 11 | 28 | 30 | 6 | 12 |

| Id | 33 | 34 | 35 | 36 | 37 | 38 | 39 | 40 | 41 | 42 | 43 | 44 | 45 | 46 | 47 | 48 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 13 | 9 | 45 | 10 | 75 | 20 | 10 | 10 | 10 | 15 | 10 | 27 | 27 | 16 | 10 | 9 |

| Id | 49 | 50 | 51 | 52 | 53 | 54 | 55 | 56 | 57 | 58 | 59 | 60 | 61 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 13 | 45 | 29 | 32 | 37 | 13 | 16 | 30 | 30 | 25 | 12 | 3 | 33 |

### 2.4 Noise

9 drum sounds, with the shared slots of Lucky Luke's table (2 = 8, 7 = 9):

| Drum | 1 | 2 = 8 | 3 | 4 | 5 | 6 | 7 = 9 |
|---|---|---|---|---|---|---|---|
| Routine | `$743A` | `$7457` | `$7483` | `$74A0` | `$74BD` | `$74DA` | `$74F7` |
| As Lucky Luke | ≈ 1 | 2 | new | 3 | new | 6 | 7/9 |

Drum 1 is The Smurfs' Nightmare's drum 1, and drum 5 is its drum 5. Drum 3 is new.

`CALL_CODE` noise routines (hold in ticks):

| Routine | Hold | Note |
|---|---|---|
| `$6DDA` | 45 | |
| `$6E47` | 80 | noise speed 3 |
| `$6EC3`, `$6FE4` | 8 | |
| `$6F3B` | 24 | NR42 = `$A2` |
| `$6F77` | 25 | |
| `$6FB7` | 19 | NR42 = `$F1`, noise pan `$88` |
| `$7015`, `$7037`, `$70C6`, `$70F7`, `$7120` | 15 | |
| `$7080` | 15 | NR42 = `$C2` |
| `$714D`, `$717A` | 4 | |
| `$71A9` | 33 | noise speed 2 |

---

## 3. Quirks

1. **`PortaStart` reads the stream loosely** (§2.1): a `LEN`, `REPEAT`, pattern jump or command argument between the two notes gives a wrong delay or target. The one use (SFX 21) has a single `LEN` byte in between, which only counts as one skipped byte.
2. `VIB_OFF` leaves the direction bit set (not used by the data).
3. **Panning is dead** (§1).
4. The Smurfs quirks 4–7 apply.
5. **Unreferenced (marked in the asm):**
   - `SetVolEnvBC` (`$436E`);
   - stray `ret` bytes (`$4413`, `$4B69`, `$4C93`);
   - 122 mostly zero bytes before the period table (`$4786`);
   - the drum table's 10th and 11th slots (`$4A05`);
   - a stream fragment after a `PAT_GOTO` (`$4E6C`);
   - the loop words of song 9's order lists;
   - unused instrument entries and macros (`$68BB`, `$6900`, `$6913`);
   - unused arpeggio entries and data (`$6959`, `$6A0C`);
   - an SFX-like stream not in the table (`$6D6F`);
   - noise routines and table pieces not called from anywhere (`$6E87`, `$6EEC`, `$6F6E`, `$6FB4`, `$707F`, `$70B4`, `$7519`), including two drum-style routines at `$7519`;
   - unused waves (`$71EF–$73DF`);
   - leftovers from `$7579` to the end of the bank.

## 4. Verification (lighter)

- **Byte-exact rebuild** of bank 15 (`tools/cmp_banked.py`).
- **Emulator trace** (`verify/v4trace.py`): songs 1–9 (6000 ticks each) and SFX 1–61, including SFX 21 with `PORTA`. **0 problems** (`verify/run_v4.log`). The lengths above come from this run.
- **Glue:** the tick rate and the timer setup (TAC, TMA) were checked in PyBoy.
- Not done: no independent model. The `PORTA` behaviour is documented from the code.

## Files (in `GBAudioLab\AJG`)

- `Maus_SoundDriver.asm`: labelled, commented RGBDS source (names carried along The Smurfs → Obélix GBC → Spirou → Lucky Luke; the porta routines named here), byte-exact
- shared version-4 tools and verification: see `Smurfs_SoundDriver.md`

Regenerate: `python tools/gen_v4.py maus "Maus, Die (E) (M4) [M].gb" Maus_SoundDriver.asm`.
