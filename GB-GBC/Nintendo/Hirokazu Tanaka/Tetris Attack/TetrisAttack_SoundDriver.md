# Tetris Attack (GB): sound driver

*Tetris Attack* (`Tetris Attack (U) (V1.1) [S].gb`, MBC1 + SGB, 512 KB) has a Tanaka-family **music** driver and an unrelated **sound-effect** engine. Three pieces of the ROM rebuild **byte-exact** with RGBDS 0.9.1 from the sources in `Nint1\TetrisAttack`:

| Piece | Content | Files |
|---|---|---|
| home `$1500–$1644` | per-frame sound routine (bank switching, pause, request routing) | `TA_Home.asm`, `TA_Home.inc` |
| bank `$08` | music driver copy A + songs `$01–$1C` (28 headers, 107 lists, 158 patterns) | `TA_Bank08.asm`, `TA_08_*.inc` |
| bank `$07` | SFX engine and data (`$4000–$67A2`), music driver copy B + songs `$1D–$23` (7 songs, 6 headers) | `TA_Bank07.asm`, `TA_07_*.inc` |

```
TetrisAttack\build_check.sh      # assemble home + both banks, link over the ROM, compare
TetrisAttack\harness\build.sh    # test ROM with the three rebuilt pieces
TetrisAttack\harness\verify.py   # play every song and effect, check every data read
python TetrisAttack\gen_ta.py <rom> TetrisAttack   (needs ..\LADX\ladx_music.py and ..\tools)
```

**Short answer on its origin.** The music driver is the **Super Mario Land 2** version of Tanaka's driver, cut back to Dr. Mario's command set and refitted with **Dr. Mario's tables**: its note table, wobble table and packed length tables, plus Dr. Mario's six waves, left unreferenced. It is not LA DX's driver, although it shares LA's RAM page. The effect engine has nothing to do with the Tanaka design. §5 has the evidence.

---

## 1. Per-frame routine (home `$1500`)

The game calls `Sound_Frame` once per frame (home `$0253` / `$0291`, plus calls from other banks).

1. `wPauseRequest` (`$D3F0`): 1 = pause: take all four channels from the music and silence them (no jingle); 2 = resume.
2. A new song request goes to **bank `$08`** for songs below `$1D`, otherwise to **bank `$07`**. A request for the song already playing is ignored.
3. Bank `$07`: `Sfx_Update` (effects) and `Noise_Update` (the noise slot).
4. The music update of the bank that owns the playing song.
5. Clear all request bytes. **Exception:** when `wSongRequest` is `$1C` or `$22`, the routine returns before clearing anything.

Each bank also carries a dummy header (`DummySongHeader`) for the songs that belong to the other bank.

| Variable | | |
|---|---|---|
| `wSongRequest` / `wSongPlaying` | `$D368` / `$D369` | song `$01–$23`, `$FF` = stop, `$24+` ignored |
| `wSfx1Request` | `$D360` | effect `$01–$50` |
| `wSfx3Request` | `$D370` | 1 = the noise-slot effect |
| `wFadeStep` / `wFadeTimer` | `$D38D` / `$D38C` | song fade-out (§2.3) |
| `wSfxActive` / `wSfxChannels` / `wSfxPriority` | `$D3FE` / `$D3FB` / `$D3E3` | effect streams (§3) |
| `wWaveCopy` | `$D400–$D40F` | copy of the music's current wave |

---

## 2. Music (banks `$08` and `$07`)

Both banks hold the same driver (bank `$08`: 905 traced instructions); bank `$07`'s names come from bank `$08` by code alignment.

### 2.1 Format

The *Dr. Mario* / *LA* format: an 11-byte header `SONG transpose, LengthTable, Ch1List … Ch4List`, section lists (`LIST_END`, `LIST_LOOP`), patterns.

| Byte | Macro | Uses |
|---|---|---|
| `$9B n` / `$9C` | `REPEAT` / `REPEAT_END` | 319 |
| `$9D` | `INSTR env, release, duty` / `INSTR_WAVE wave, level` | 228 / 81 |
| `$9E ptr` | `TEMPO` | |
| `$9F n` | `TRANSPOSE` | |
| `$A0–$AF` | lengths | |
| ch4 | drums: `NoiseTable` offsets `1 + 5n` (11 drums). There is no `$FF` drum as in *LA* | |

No *SML2* / *LA* extra commands (bend, drop, ch3 fades).

### 2.2 Engine

- **Release** (from *SML2*): the second `INSTR` byte sets a release point (bit 7 = ½, bit 6 = ¼ of the length, else ¾), at which `ReleaseEnvelopes[n − 1]` is written and the note retriggered (ch1, ch2). Tetris Attack's own release values: `52 31 21 00 00 00 00`.
- **Pitch effect** (from *Dr. Mario*): low nibble of the third `INSTR` byte; 1 = vibrato from `VibratoTable` (one signed nibble per frame, indexed by `NoteFrames / 2`), other non-zero = period − 1. The table is Dr. Mario's 55-byte wobble table with its repeating cycle extended to 135 bytes. The 30 zero bytes after it (`VibratoTable_Pad`) are the ones that follow the table in *Dr. Mario*; here they are never read.
- **Note table:** Dr. Mario's (C♯7 = `$7C4`, A♯5 = `$773`), not *SML2*'s / *LA*'s.
- **Length tables:** packed and overlapping, Dr. Mario-style.
- **Panning:** *SML2* / *LA*'s 6-byte entries (mode, period, NR51 ×4).
- **Wave mirror:** `LoadWave` also copies the wave to `wWaveCopy` (`$D400`), so the effect engine can restore it.
- **Command `$9D` during a fade-out** is read but not applied.

### 2.3 Fade-out

While `wFadeStep` ≠ 0 (the game sets it at home `$0545`): mute ch3 and ch4, then every 6 frames step the ch1/ch2 envelopes down through `FadeOutEnvelopes` (`$54 … $14`). At the end, stop and **request song `$22`**. `Music_StartFadeOut` (`wFadeStep = 1`) exists in both banks but nothing calls it.

### 2.4 Unreferenced code and data

| Item | |
|---|---|
| `Music_SaveState_Unused` / `Music_RestoreState_Unused` | *SML2*'s routines (save `$D310–$D349` to `$D390`, `wSavedSong` = 5). *SML2*'s versions test the wrong register in both loops; these test the right one |
| `Unused_SetRegs`, `Unused_SfxGetInitPointer` | the Tanaka-style effect helpers, with no effects left to use them |
| `Unused_MuteAll` (bank `$08`), `Music_Trigger.unused` | |
| `Unused_DrMarioWaves` (`$08:$488E`, `$07:$6F63`) | **Dr. Mario's six waves** (`$6BC3–$6C22` there), in Dr. Mario's order, then the start of a Dr. Mario-style length-table area |
| `Unused_Waves_7CA0`, `Unused_Wave_7CD0` (bank `$08`), `Unused_7F31` (bank `$07`, a copy of bank `$08`'s `Wave_7C80`) | waves |

### 2.5 Songs

28 songs in bank `$08`, 7 in bank `$07`. Song `$21` plays a short jingle and then loops a 1/32-note rest on every channel, so it reads its data every couple of frames.

---

## 3. Sound effects (bank `$07` `$4000–$67A2`)

Not the Tanaka design (no per-frame routine per effect). An effect's init routine (`SfxInitTable`, `$00–$50`; `$00` is a `ret`, `$47` shares an init) takes the channels it needs (`TakeChN`, which silences them). It then points up to four **channel streams** and a wave stream at data, and one routine, `Sfx_PlayStreams`, plays them all. Stream pointers are stored big-endian.

| Stream | Row | |
|---|---|---|
| ch1 | NR10–NR14 + frames (6 bytes) | |
| ch2 | NR21–NR24 + frames (5) | |
| ch3 | flag, NR31–NR34 + frames (6) | flag `$FF` = load the next 16 bytes of the wave stream first |
| ch4 | NR42, NR43 + frames (3) | a 4-register form exists but is never used |
| noise slot | NR42, NR43 + frames | `wSfx3Request` = 1, one stream (`NoiseStream_6300`) |

A frame count of `$FF` ends the stream; the channel then goes back to the music, unless the game is paused. The end of a ch3 stream restores the music's wave from `wWaveCopy`.

**Priority:** `SfxPriorityTable` gives each effect a value; a request starts only if its value is ≤ the playing effect's (`wSfxPriority`, `$FF` = none).

An unreferenced ch1 stream sits at `$5C5A`.

---

## 4. Verification

- **Byte-exact rebuild** of `$1500–$1644`, bank `$07` and bank `$08` (`ASSERT`s at every file boundary).
- **Emulator harness** (PyBoy). The test ROM contains the three rebuilt pieces and calls `Sound_Frame` once per frame.

  | | Reads | Outside the parse |
  |---|---|---|
  | Bank `$08`, songs `$01–$1C`, 3,600 frames each (pattern / list) | 54,692 / 3,969 | 0 |
  | Bank `$07`, songs `$1D–$23` | 42,036 / 14,607 | 0 |
  | Effects `$01–$50` + noise slot, 400 frames each (register rows) | 5,581 | 0 |

- **Not verified:** what songs `$1C` / `$22` are (the requests that stay set); song and effect identities; hardware.

---

## 5. Where it comes from

Code alignment of bank `$08`'s 905 traced instructions:

| Compared with | Aligned |
|---|---|
| Super Mario Land 2 | **73 %** |
| Link's Awakening DX (`$1B`) | 69 % |
| Dr. Mario | 64 % |
| Tetris | 54 % |
| Super Mario Land | 51 % |

Per routine:
- **From *SML2* / *LA* only:** release and release point, panning init, the length-release code. *SML2* only: the save/restore-state routines.
- **From *Dr. Mario* only:** the pitch-effect routine (59 of 59 instructions; *SML2* / *LA* have a different vibrato), `Vibrato_GetStep`.
- **Tables:** all Dr. Mario's (note table, wobble table, length-table packing, waves).
- **New:** fade-out, wave mirror, the request routing and the effect engine.

*SML2*'s 13-byte header, fast mode, and its bend / drop / ch3-fade commands are absent. The 11-byte header and the `$D300` RAM page match *LA DX*, yet the code is closer to *SML2* than to *LA DX*. That points to a branch taken around the *SML2* / original *Link's Awakening* (1993) period, but the 1993 game isn't in this set, so this is an inference.
