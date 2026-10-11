# Tetris (GB): sound driver

Hirokazu Tanaka's driver as used in *Tetris* (`Tetris (W) (V1.1) [!].gb`, 32 KB, no MBC). The sound region `$6480–$7FFF` rebuilds **byte-exact** with RGBDS 0.9.1 (`-Wall` clean) from the sources in `Nint1\Tetris`.

| Range | Content | File |
|---|---|---|
| `$6480–$6DCA` | SFX tables, song table, driver code, SFX data | `Tet_Driver.inc` |
| `$6DCB–$6F3E` | vibrato table, note table, noise table, 5 waves, length tables | `Tet_Tables.inc` |
| `$6F3F–$7FEF` | 17 song headers, 57 section lists, 119 patterns | `Tet_Songs.inc` |
| `$7FF0–$7FFF` | entry stubs | `Tet_Stubs.inc` |

```
Tetris\build_check.sh          # assemble, link over the ROM, compare
Tetris\harness\build.sh        # test ROM: harness + rebuilt driver
Tetris\harness\verify.py       # play every song / effect, check every data read
python Tetris\gen_tetris.py <rom> Tetris
```

**Place in the family.** Tetris sits between *Super Mario Land* and *Dr. Mario* (`SuperMarioLand_SoundDriver.md`, `DrMario_SoundDriver.md`). About 68 % of its instructions align with each of them, while *SML1* and *Dr. Mario* align with each other at only 49 %. The music core is *SML1*'s; the RAM layout, the effect plumbing and several tables are the ones *Dr. Mario* kept. §5 lists the evidence.

---

## 1. API

| Address | | |
|---|---|---|
| `$7FF0` | `jp Sound_Update` | once per frame, from the main loop (home `$02CA`) |
| `$7FF3` | `jp Sound_Stop` | stop everything, mute; also serves as init (home `$02A3` and five more call sites) |

There is no init stub; *Dr. Mario* adds one at `$7FF6`. `Sound_Update` saves all registers and ends with `ret`. Tetris is the only one of the three that calls it from the main loop: *SML1* and *Dr. Mario* call it from their timer interrupt.

All variables are in the `$DF00` page, laid out as in *Dr. Mario*: channel structures at `$DF90 + $10·n`, request / playing bytes at `$DFE0` (ch1 SFX), `$DFE8` (song), `$DFF0` (ch3 SFX), `$DFF8` (ch4 SFX), pause at `$DF7E/$DF7F`.

| Variable | | Meaning |
|---|---|---|
| `wSongRequest` | `$DFE8` | 1–17 = song (masked with `$1F`, no range check), `$FF` = stop |
| `wSfx1Request` | `$DFE0` | 1–8 |
| `wSfx3Request` | `$DFF0` | 1–2 |
| `wSfx4Request` | `$DFF8` | 1–4 |
| `wPauseRequest` | `$DF7F` | 1 = pause, 2 = resume |
| `hDemoMode` | `$FFE4` | game flag (apparently the attract-mode demo): every request is dropped while it is set |

**Order:** pause; ch1, ch4, ch3 effects; song request; music; panning; clear the requests.

---

## 2. Songs

The data model is the family one: `SONG transpose, LengthTable, Ch1List … Ch4List`, section lists ending in `LIST_END` / `LIST_LOOP`, patterns ending in `PAT_END`. As in *SML1*:

- **The only command is `$9D`** (`INSTR` / `INSTR_WAVE`). No tempo, transpose or repeat commands; the header's transpose byte is stored and never read.
- **Notes trigger with NRx4 | `$80`** (no hardware length) and **rests write envelope `$01`**.
- **Pitch effect:** any non-zero low nibble of the third `INSTR` byte gives the vibrato. The type test is followed by an unconditional `jr`, so the code for a fixed −1 offset after it is unreachable. *Dr. Mario* has the same code with −2 and makes it reachable.
- **Every list end stops the song**, not only ch1's: songs 10 and 11 have no ch1.

Four packed length tables (`$6EF9–$6F3E`). `INSTR`'s second byte (the flag) is 0 everywhere. Four drums in `NoiseTable` (`NR42, flag, NR41, NR43, NR44`). The songs use two waves: `$6EE9` (all songs) and `$6EC9` (song 5).

Six patterns have no `PAT_END` and run into the next list, header or pattern. The play check confirms nothing reads past them: the song ends on another channel first. `$753E` (5 bytes) is unreferenced.

**Panning** (`SongPanTable`, 4 bytes per song: mode, period, NR51 A, NR51 B): mode 1 = fixed A, mode 3 = `$FF`, any other mode alternates A/B every *period* frames (no song uses it). While a ch3 or ch4 effect plays, those channels are put on both sides.

---

## 3. Sound effects

The *SML1* / *Dr. Mario* design: per-effect init and per-frame routines, register images, `Sfx_Start` / `Sfx_Tick`, bit 7 of `wChNFlags` to take a channel.

| Slot | Effects | |
|---|---|---|
| ch1 | 1–8 (`Sfx1_InitTable` / `Sfx1_PlayTable`) | 4 and 5 share 2's per-frame routine; several refuse to start while ch1 effect 7 or ch3 effect 1 plays (`Sfx1_Is07`, `Sfx3_Is01` …); effect 7 requests ch3 effect 1 on its last step |
| ch4 | 1–4 | 2 and 3 share 1's per-frame routine |
| ch3 | 1–2, dispatched by code (no table) | each **takes all four channels** and loads its own wave; the end reloads the song's wave: `$6EC9` for song 5, `$6EE9` otherwise |

**Pause:** mute, cancel the effects, reload wave `$6EE9`, then the family's ch2 jingle (timer `$30`, images A/B at `$30/$28/$20/$18`, hold at `$10`). The images are the same bytes as in *SML1* and *Dr. Mario*.

---

## 4. Verification

- **Byte-exact rebuild** of `$6480–$7FFF`.
- **Emulator harness** (PyBoy; rebuilt driver, update once per frame). 3,600 frames per song, 600 per effect:

  | | Reads | Outside the parse |
  |---|---|---|
  | Songs 1–17 (pattern / list) | 11,427 / 662 | 0 |
  | ch1 effects 1–8 | 100 | 0 |
  | ch3 effects 1–2 | 25 | 0 |
  | ch4 effects 1–4 | 16 | 0 |

- **Not verified:** song titles and effect contexts; hardware.

---

## 5. Tetris between SML1 and Dr. Mario

| Feature | SML1 | **Tetris** | Dr. Mario |
|---|---|---|---|
| Commands | `$9D` only | `$9D` only | `$9B–$9F` |
| NRx4 on trigger / rest envelope | `$80` / `$01` | `$80` / `$01` | `$C0` / `$08` |
| Pitch effect | vibrato only, `jr` makes the rest unreachable | same | types 1, 2, 3 |
| Channel structures / variables | `$DF10` + HRAM | `$DF90`, all in the `$DF00` page | `$DF90`, all in the `$DF00` page |
| Stubs | `$7FF0` update, `$7FF3` stop | same | + `$7FF6` init |
| Update called from | timer interrupt (ends with `reti`) | main loop | timer interrupt (`$0050` → `$205D`) |
| Pause reloads a wave | no | `$6EE9` | `$6BF3` (the same wave) |
| ch3 effects taking all channels, song-5 wave rule | no | yes, used | **present but unreferenced** |

- **The note table** is identical in all three (72 entries, C♯7 = `$7C4`; see the lineage note).
- **The vibrato (wobble) table** is the same 55 bytes in all three.
- **Waves:** Tetris's `$6EC9` and `$6EE9` are *Dr. Mario*'s `$6BD3` and `$6BF3`. *Dr. Mario*'s unreferenced `Sfx3_Start_Unused` / `Sfx3_Stop_Unused` reload exactly these two, chosen by the same "song 5" test. That dead code is Tetris's ch3 effect plumbing, left in *Dr. Mario*.
- **Length tables:** most of Tetris's packed tables appear byte for byte inside *Dr. Mario*'s, which extends them.

So *Dr. Mario*'s driver was built from the Tetris version rather than directly from *SML1*'s. *SML1* (April 1989) and Tetris (June 1989) are close siblings; *SML1* kept some variables in HRAM.

## Files (`Nint1\Tetris`)

| File | Content |
|---|---|
| `Tet_Sound.asm` | the section; includes the files below |
| `Tet_Driver.inc`, `Tet_Tables.inc`, `Tet_Songs.inc`, `Tet_Stubs.inc` | sources with labels and comments |
| `Tet_Macros.inc`, `Tet_RAM.inc` | macros (`INSTR`, notes, lengths, `NOISE0–3`); RAM map |
| `gen_tetris.py`, `harness\` | generator (uses `tools\gbdis.py`, `tools\tanaka.py`), test ROM and checker |
