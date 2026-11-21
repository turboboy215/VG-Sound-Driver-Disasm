# The Smurfs' Nightmare (GB): sound driver

ROM: `Smurfs 3, The (E) (M4) [!].gb` (DMG, MBC1, 256 KB, internal title `THE SMURFS 3`). In-game title *The Smurfs' Nightmare*.

Part of the AJG family (Alberto José González / Bit Managers), see `AJG_SoundEngine_Family.md`. This is **version 4**, documented in full in `Smurfs_SoundDriver.md`. The build is **Lucky Luke's driver with one code change** (`LuckyLuke_SoundDriver.md`): `INSTR` stops auto-duty again. It is in a different bank and has its own data. The command ranges, RAM layout, output, pause and fade code are Lucky Luke's.

The bank also has the driver's own name and version, the only one found so far in the family. It sits as text between the driver code and the first song (`$4B23`):

```
GBS 3.4 (C) 1990 - 1997 Alberto Jose Gonzalez & Bit Managers S.L.
```

| | |
|---|---|
| Bank | the driver and all its data fill **ROM bank 2** (`$4000–$7D04`; then `Final de la rutina de musica` twice and x86 assembler leftovers) |
| Command table | `$4000` (37 commands, `$60–$84`, as Lucky Luke; `NOTE_HOOK` is unused) |
| API jump table | `$404A`: `SndUpdate $40E6`, `SndPause $40A2`, `SndResume $409B`, `StopAll $453D`, `PlaySfx $491A`, `SndInit $4522`, `SongFadeIn $495D`, `SongFadeOut $4957`, **18 song entries** (`$4062–$40AD`), `PlaySfxNow $491D` (`$40B0`) |
| Tick | once per frame, called by the game (§1) |
| RAM | pages Ch1 `$DBxx`, Ch2 `$DCxx`, Ch3 `$DDxx`, SFX `$DExx` (fields `$00–$41`); globals `$DB42–$DB65` (as Lucky Luke) |
| Ranges | `INSTR $85–$93` (15), `ARP $94–$AF` (28), `VOLENV $B0–$BF`, `LEN $C0–$EF` (1–48), `REPEAT $F0–$FF` (2–17); drum tempo bytes `$C0–$FE` (as Lucky Luke) |
| Tables | SFX `$7698` (16 entries), arpeggios `$75DF` (set by `SndInit`; no song sets one), CH3 volume `$41CE`, drums `$49F3` |
| Counts | 18 songs, 16 SFX, **4 instrument tables** (`$7572` 15 entries read, `$5DB2` 3, `$626A` 6, `$6FE2` 3), 1 arpeggio table (20 entries read), 24 waves, 11 drum sounds + 4 noise routines called with `CALL_CODE`, 26 drum patterns |

`Smurfs3_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over the whole of bank 2:

```
rgbasm -Wall -o smurfs3.o Smurfs3_SoundDriver.asm
rgblink -o smurfs3.gb smurfs3.o
python tools/cmp_banked.py smurfs3.gb "Smurfs 3, The (E) (M4) [!].gb" 2:4000-7FFF
```

---

## 1. Game glue (bank 0)

The glue is the same as Lucky Luke's: there is no sound code in the interrupt handlers, and bank 0 has one wrapper per API entry (`$38B9–$3940`).

- **SndUpdate:** the game calls the wrapper `$38B9` from its frame loops (16 call sites). In an emulator run of the intro it was called 1115 times in 1200 frames: frames that run long skip a call.
- **SndInit wrapper** (`$390D`): also clears the music-off flag `$FF8D`. (Lucky Luke's flag is `$DEED`.)
- **Fade wrappers** pass a fixed speed of 4.
- **PlaySfx wrapper** (`$38F5`, A = id): switches back to bank 1 afterwards.
- **Songs:** `$3941` reads a routine address from a table in bank 1 and calls it in bank 2, unless `$FF8D` is set. `$3964` calls the routine at HL.

`wStereo` (`$DB43`) is never written, so NR51 is `$FF`. **The pan commands in songs 6 and 7 (`PAN_C/R/L`, `AUTOPAN`) have no effect.**

## 2. Differences from Lucky Luke

| | Lucky Luke | The Smurfs' Nightmare |
|---|---|---|
| Bank | 12 | **2** |
| `INSTR` | clears arpeggio, glide and arpeggio offset; auto-duty keeps running | **also clears field `$2F`**, so auto-duty stops, as in The Smurfs (one `ld l, $2F / ld [hl], a` added) |
| `SndInit` arpeggio table / SFX table / CH3 volume table | `$76C9` / `$777E` / `$41CB` | `$75DF` / `$7698` / `$41CE` |
| Version text | – | `$4B23` (65 bytes, unreferenced) |

The `INSTR` change matters here because this game uses `AUTODUTY` (songs 3 and 10): an `INSTR` after `AUTODUTY` ends the duty cycling.

Everything else is Lucky Luke's code, apart from addresses:

- the single NRx4 write;
- the direction always reset at note on;
- Spirou's pause model and NR50 forcing;
- no SFX priority;
- `NOTE_HOOK` and `SetVolEnvBC` present but unused (`SetVolEnvBC` at `$4372`).

### 2.1 Songs

| Song (API slot) | Routine | Ch1 / Ch2 / Ch3 order lists | Instr. table | Length (ticks) |
|---|---|---|---|---|
| 1 (1) | `$4B64` | `$4B83 / $4B95 / $4BA7` | `$7572` | loops |
| 2 (2) | `$4D59` | `$4D79 / $4DA7 / $4D8F` | `$7572` | loops |
| 3 (3) | `$50BE` | `$50DE / $510E / $50F6` | `$7572` | loops |
| 4 (4) | `$537F` | `$539F / $53AB / $53B7` | `$7572` | loops |
| 5 (5) | `$55E1` | `$5600 / $5610 / $5620` | `$7572` | loops |
| 6 (6) | `$58B5` | `$58F4 / $58E4 / $58D2` | `$7572` | loops |
| 7 (7) | `$5A79` | `$5A96 / $5AA8 / $5ABA` | `$5DB2` | loops |
| 8 (8) | `$5DD0` | `$5DEF / $5E07 / $5DFB` | `$7572` | loops |
| 9 (9) | `$5F15` | `$5F5D / $5F49 / $5F35` | `$626A` | loops |
| 10 (10) | `$62B9` | `$62D8 / $62E6 / $62F4` | `$7572` | loops |
| 11 (11) | `$6665` | `$6685 / $6697 / $66A9` | `$7572` | loops |
| 12 (12) | `$6931` | `$6946 / $6950 / $695A` | – | loops |
| 13 (13) | `$6A59` | `$6A6E / $6A80 / $6A92` | – | loops |
| 14 (14) | `$6C8B` | `$6CE5 / $6CD3 / $6CAB` | `$6FE2` | loops |
| 15 (15) | `$6FFC` | `$702F / $701B / $7047` | `$7572` | loops |
| 16 (16) | `$7387` | `$73A6 / $73AC / $73B2` | `$7572` | 309, ends |
| 17 (17) | `$740F` | `$742E / $7434 / $743A` | `$7572` | 521, ends |
| 18 (18) | `$74E3` | `$7502 / $7504 / $7506` | `$7572` | 379, ends |

Unlike Lucky Luke, the song routines are in bank order (song 1 first). The order lists are not always stored in channel order (in songs 6, 9 and 14 Ch3's list comes first).

- **Instrument tables:** songs 7, 9 and 14 have their own small tables; the others use `$7572`.
- **Songs 12 and 13** set no instrument table, but they have no `INSTR` either.
- **Arpeggios:** all songs use the table from `SndInit`.

Data usage:

- Music has 111 `REPEAT`s, 57 `PAT_CALL`s, 134 `WAIT2`s, 32 `VIBRATO`s and 3 `VIB_OFF`s.
- It also has 10 `AUTODUTY`s, 5 `DRUMS_OFF`s and a few `PAN_*`/`AUTOPAN` (dead), plus 1 `PAT_GOTO` and 1 `CALL_CODE`.
- Not used anywhere: `STOP_ALL`, `FADE`, `FADE_OFF`, `NOTE_HOOK`.

### 2.2 Sound effects

16 SFX on the CH3 page. They use `WAVE`, `LEN`, `VOLENV`, `VOL`, notes, `WAIT`, `REST`, `GLIDE`, `ARP`, `CH_TRANSPOSE`, `SLIDE_UP`, `SLIDE_DOWN`, `RELEASE`, `CALL_CODE` and `END`. SFX 1–3 have the same lengths as Lucky Luke's SFX 1–3.

| Id | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 25 | 13 | 9 | 14 | 18 | 24 | 9 | 20 | 7 | 24 | 72 | 90 | 33 | 11 | 36 | 12 |

### 2.3 Noise

11 drum sounds; drum 3 = 4 share a routine, the others are separate (unlike Lucky Luke, drum 8 is not drum 2 and drum 9 is not drum 7):

| Drum | 1 | 2 | 3 = 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 |
|---|---|---|---|---|---|---|---|---|---|---|
| Routine | `$7B65` | `$7BAA` | `$7BD6` | `$7BF3` | `$7C10` | `$7C2D` | `$7B82` | `$7C4A` | `$7C6C` | `$7C89` |
| As Lucky Luke | ≈ 1 | 2 | 3 | new | 6 | new | new | 7/9 | new | new |

Drum 1 differs from Lucky Luke's in the first NR43 byte only (`$01` for `$02`). Drums 5, 7, 8, 10 and 11 are new sounds.

`CALL_CODE` noise routines: `$7809` (hold 36, NR42 = `$F3`), `$7858` (15), `$7894` (4), `$78C1` (33, noise speed 2).

---

## 3. Quirks

1. **Panning is dead** although songs 6 and 7 use the pan commands (§1).
2. As Lucky Luke: after a note, `SLIDE_UP` and `SLIDE_DOWN` both slide down. Each is used once, in SFX.
3. Two drum patterns have no `DRUM_LOOP` and run into the next data (`$73FF`, `$74C4`; marked in the asm).
4. The Smurfs quirks 4–7 apply.
5. **Unreferenced (marked in the asm):**
   - `SetVolEnvBC` (`$4372`);
   - a stray `ret` (`$443D`) and the `ret`s after several song routines;
   - x86 leftovers before the period table (`$47AD`, 83 bytes);
   - the version text (`$4B23`);
   - stream fragments after patterns of song 6 (`$58FA`, `$5900`, `$5931`);
   - the loop words of songs 16 and 17's order lists;
   - unused arpeggio table entries (`$7607`);
   - unused waves (`$7927–$7AF7`, 16 or 32 bytes each);
   - noise-table pieces (`$7B4E`, `$7CBA`);
   - the end texts and x86 leftovers (`$7D3E`, 706 bytes).

## 4. Verification (lighter)

- **Byte-exact rebuild** of bank 2 (`tools/cmp_banked.py`).
- **Emulator trace** (`verify/v4trace.py`): songs 1–18 (6000 ticks each) and SFX 1–16. **0 problems** (`verify/run_v4.log`). The lengths above come from this run.
- **Code comparison** with Lucky Luke: `tools/v4diff.py` shows only the `INSTR` change and the table addresses.
- Not done: no independent model.

## Files (in `GBAudioLab\AJG`)

- `Smurfs3_SoundDriver.asm`: labelled, commented RGBDS source (names carried along The Smurfs → Obélix GBC → Spirou → Lucky Luke), byte-exact
- shared version-4 tools and verification: see `Smurfs_SoundDriver.md`

Regenerate: `python tools/gen_v4.py smurfs3 "Smurfs 3, The (E) (M4) [!].gb" Smurfs3_SoundDriver.asm`.
