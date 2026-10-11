# Super Mario Land (GB): sound driver
 
This is Hirokazu Tanaka's driver in *Super Mario Land* (`Super Mario Land (W) (V1.0) [!].gb`, MBC1, 64 KB). It is the oldest version of the family in this set. Bank 3 holds game code up to `$66EF`, `$FF` fill at `$66F0–$66FF`, and the sound driver from `$6700` to the end of the bank. That region, `$6700–$7FFF`, rebuilds **byte-exact** with RGBDS 0.9.1 (`-Wall` clean) from the sources in `Nint1\SML1`.
 
| Range | Content | File |
|---|---|---|
| `$6700–$6F38` | SFX tables, song table, driver code, SFX data | `SML_Driver.inc` |
| `$6F39–$7093` | wobble table, note table, noise table, 4 waves, length tables | `SML_Tables.inc` |
| `$7094–$7FEC` | 19 song headers, 62 section lists, 118 patterns | `SML_Songs.inc` |
| `$7FED–$7FFF` | `$FF` fill, entry stubs | `SML_Tail.inc` |
 
```
SML1\build_check.sh            # assemble, link over the ROM, compare
SML1\harness\build.sh          # test ROM (MBC1): harness + rebuilt bank 3
SML1\harness\verify.py [N]     # play every song/SFX, check every data read (N = coverage frames)
python SML1\gen_sml1.py <rom> SML1    # regenerate the sources
```
 
The engine is the same design as *Dr. Mario*'s (`DrMario_SoundDriver.md`), with fewer features. This document mostly lists the differences.
 
---
 
## 1. API
 
| Address | | |
|---|---|---|
| `$7FF0` | `jp Sound_Update` (`$6762`) | once per frame, from the game's **timer interrupt** |
| `$7FF3` | `jp Sound_Stop` (`$6B26`) | stop everything, NR51 = `$FF`, pan mode 3 |
 
There is no init stub. `Sound_Update` saves the registers and sets IE = 3 (VBlank and STAT only) before `ei`, so it can itself be interrupted by the display interrupts. It ends with IE = 7 and `reti`.
 
| Variable | | Meaning |
|---|---|---|
| `wSongRequest` | `$DFE8` | 1–19 = song, `$FF` = stop. No range check: the number is masked with `$1F` |
| `wSfx1Request` | `$DFE0` | 1–11, ch1 effects |
| `wSfx4Request` | `$DFF8` | 1–4, ch4 effects |
| `wSfx3Request` | `$DFF0` | 1, the only ch3 effect |
| `hPauseRequest` | `$FFDF` | 1 = pause (jingle), 2 = resume |
| `hSfx08Request` | `$FFD3` | non-zero: request ch1 effect 8 (cleared by the driver) |
| `hGameState` | `$FFB3` | game variable: value 5 forces NR51 = `$FF` |
 
Some variables are in HRAM (`hMusicChannel` `$FFD0`, `hSfxId` `$FFD1`, panning `$FFD5–$FFDA`, pause `$FFDE–$FFDF`). The rest are in the `$DF00` page: four 16-byte channel structures at `$DF10`, `$DF20`, `$DF30`, `$DF40`, and SFX variables at `$DFE0` / `$DFF0` / `$DFF8`.
 
**Order.**
1. Pause.
2. `hSfx08Request`.
3. ch1 effects.
4. ch4 effects.
5. The ch3 effect.
6. Song request.
7. Music.
8. Panning.
9. Clear the requests.
---
 
## 2. Data
 
The song structure is the same as *Dr. Mario*'s: a `SONG` header, section lists ending in `LIST_END` (`$0000`) or `LIST_LOOP` (`$FFFF`, target), and patterns ending in `PAT_END`. Three things differ.
 
- **Only one command, `$9D`** (`INSTR` / `INSTR_WAVE`). Every other byte below `$A0` is a note (`$01` = rest).
  - There is no tempo command: each song keeps the length table of its header.
  - There is no transpose. The header's transpose byte is copied to `wTranspose` and never used.
  - There are no repeats. Bytes `+C/+D` of the channel structure are unused.
- **Five length tables** (`$7057–$7093`, packed like *Dr. Mario*'s). The quarter note (`L4`) lasts 12, 16, 20, 24 or 28 frames.
- **Three drums** in `NoiseTable` (`NOISE1–3`, pattern bytes `$06`, `$0B`, `$10`), with the same 5-byte layout.
| Song | Length table (L4) | Lists | | Song | Length table (L4) | Lists |
|---|---|---|---|---|---|---|
| 1 | 12 | jingle, ch1–3 | | 11 | 16 | 1 entry each, loop |
| 2 | 24 | jingle, ch1–3 | | 12 | 16 | ch1/2 10 entries, end; ch3 2; ch4 loops |
| 3 | 16 | loop → 1 (ch4: 1 entry) | | 13 | 12 | jingle, ch1 + ch3 |
| 4 | 24 | 1 entry, loop (no ch3) | | 14 | 16 | jingle, ch1–2 |
| 5–8 | 12 / 16 / 16 / 24 | loop → 1 | | 15 | 28 | 4 entries, end (ch1–2) |
| 9 | 20 | 1 entry, loop (no ch3) | | 16 | 28 | jingle, ch1–3 |
| 10 | 24 | jingle, ch1–3 | | 17 | 24 | loop → 2 / 2 / 5 / 4 |
| | | | | 18 | 24 | 1 entry, loop (ch1–2) |
| | | | | 19 | 24 | loop → 1 |
 
The headers are in three places: songs 1–8 at `$7094`, songs 9–16 and 18–19 at `$79C1`, and song 17 at `$7E4F`.
 
As in *Dr. Mario*, ch1's list alone ends a song, and the other channels' jingle lists have no terminator. This version also has patterns without a `PAT_END`:
 
- **Song 10, ch3** (`Pattern_7D92`) runs into song 9's lists.
- **Song 14, ch2** (`Pattern_7C03`) runs into song 12's lists.
Neither matters, because ch1 stops the song first. The same cut-off removes the **last 9 bytes of song 13's ch3 pattern** (`$7BDF–$7BE7`): ch1 ends before ch3 gets there, so those notes are never heard.
 
---
 
## 3. Engine
 
The channel structure is *Dr. Mario*'s layout: list pointer, length counter, length, pattern pointer, Env/Flag/Duty, Freq, Rest, NoteFrames, Flags. The frame logic is the same: sustain or read-and-trigger, ch1→ch4. The differences:
 
| | Super Mario Land | Dr. Mario |
|---|---|---|
| Trigger | NRx4 = period high \| **`$80`**: no length counter, so notes are not cut by NRx1 | `| $C0`: hardware length cuts notes |
| Rest / mute envelope | `$01` | `$08` |
| ch3 trigger | NR31 = 0 always | `$EF` when level bit 7 |
| Pitch effect | any non-zero low nibble of the Duty byte = **wobble table**; the type test is `cp $01 / jr .table`, an unconditional jump, so the detune code after it (`ld hl,-1`) is unreachable | 1 wobble, 2 fall, 3+ detune −2 |
| Note trigger side effect | clears bit 0 of `wChNFlags` (never set or tested anywhere) | |
| Song end | `wSongPlaying` = 0, channels muted | `Sound_Stop` |
 
The ch3 "level bit 7" release (NR32 = `$40` 6 frames before the note ends) and the stray-NRx2 quirk of a non-zero flag byte are already present here, unchanged in *Dr. Mario*.
 
The wobble table (55 bytes) is indexed by `NoteFrames / 2` with no bound. From 110 frames into a note it reads `NoteTable` bytes as pitch offsets.
 
**Panning** (`SongPanTable`, 4 bytes per song: mode, period, NR51 A, NR51 B):
- mode 1: fixed NR51 A;
- mode 3: `$FF` (both sides);
- mode 2: alternate A and B every *period* frames;
- no song playing, or `hGameState` = 5: NR51 = `$FF`.
While ch4 effect 1 plays, `Music_Sfx4Panning` bounces NR51 between `$F7` and `$7F`. The caller then continues and rewrites NR51 in every mode except mode 2 between its toggle frames, so the bounce is only audible during mode-2 songs.
 
`NoteTable` has the same 72 values as *Dr. Mario* (A♯5 `$773`, C♯7 `$7C4`).
 
---
 
## 4. Sound effects
 
The effects work the same way as *Dr. Mario*'s: init and per-frame routines, register images, `Sfx_Start` / `Sfx_Tick`, and bit 7 of `wChNFlags`.
 
| ch1 # | Frames/step | Effect |
|---|---|---|
| 1 | 16 | one image; the period word in `wSfx1Step/Var` starts at `$860A` and rises by 15 every frame |
| 2, 7, 9, 10 | 3, 8, 14, 3 | one image (`Sfx1_PlayOneStep`) |
| 3 | 8 | two images |
| 4, 11 | 5 | NR13 = `wSfx1Var2` + `$10` every 5 frames until `$E0` (start `$10` / `$60`) |
| 5 | own counter | image 2 at frame 4, stop at frame 24 |
| 6 | 6 | NR12 sequence, ends on 0 |
| 8 | 6 | six images |
 
| ch4 # | Effect |
|---|---|
| 1 | one image, 48 frames; bounces the panning (§3) |
| 2, 4 | one image, 21 / 22 frames; 2 is refused while 1 plays |
| 3 | NR43 sequence every 6 frames; refused while 1 plays |
 
**Priority.** The ch1 checks refuse to start an effect while certain others play:
 
| Check | Refuses while playing |
|---|---|
| `Sfx1_IsBusy_468B` | 4, 6, 8, 11 |
| `Sfx1_IsBusy_4568B` | 4, 5, 6, 8, 11 |
| `Sfx1_IsBusy_34568B` | 3, 4, 5, 6, 8, 11 |
 
Effect 6 is refused while 8 plays.
 
**ch3 effect** (`wSfx3Request` = 1, the only one):
1. Takes ch3 and loads `Wave_7047`.
2. Starts at a random pitch: `$D0` + (DIV & `$1F`) in NR33.
3. Rises 2 per frame for 14 frames, then falls 3 per frame until frame 30.
4. Ends by reloading the current song's wave. Its pointer is still in `wCh3InstrEnv/Flag`.
The low 3 bits of NR33 are re-randomised from DIV every frame. *Dr. Mario* keeps a ch3-effect start/stop pair that nothing calls (`Sfx3_Start_Unused`).
 
**Pause.** Request 1 mutes, cancels the effects and starts `hPauseTimer` = `$30`. The ch2 jingle plays image A at `$30`, B at `$28`, A at `$20`, B at `$18`. At `$10` the timer holds there until resumed. The jingle images are the same as *Dr. Mario*'s. Unlike *Dr. Mario*, the pause doesn't reload a wave.
 
---
 
## 5. Verification
 
- **Byte-exact rebuild** of `$6700–$7FFF` (`build_check.sh`).
- **Emulator harness.** The test ROM is MBC1, bank 3 = **rebuilt** driver; the update stub is called once per frame, with `reti` vectors installed. `verify.py` (PyBoy, via `tools\playcheck.py`) plays each song for 3,600 frames and each effect for 600, hooking the pattern read, the list read, the register-image copy, the SFX table reads and the wave loader.
  | | Reads | Outside the parse |
  |---|---|---|
  | Songs 1–19 (pattern / list) | 20,092 / 1,538 | 0 |
  | ch1 effects 1–11 | 104 | 0 |
  | ch4 effects 1–4 | 22 | 0 |
  | ch3 effect | 37 | 0 |
  With 12,000 frames per song, every parsed pattern byte is read except the final `PAT_END`s of non-ch1 jingle channels and the 9-byte tail of song 13's ch3 (§2).
- **Not verified:** song titles and effect contexts, and anything on hardware.
## Files (`Nint1\SML1`)
 
| File | Content |
|---|---|
| `SML_Sound.asm` | the section; includes the files below |
| `SML_Driver.inc` | code `$6700–$6F38`, labelled and commented, with SFX images |
| `SML_Tables.inc` | `VibratoTable_Wobble`, `NoteTable`, `NoiseTable`, waves `$7017/$7027/$7037/$7047`, length tables |
| `SML_Songs.inc` | headers, lists, patterns |
| `SML_Tail.inc` | `$7FED–$7FFF` |
| `SML_Macros.inc`, `SML_RAM.inc` | macros (`INSTR`, notes, lengths, `NOISE1–3`); RAM/HRAM map |
| `gen_sml1.py` | generator (uses `tools\gbdis.py`, `tools\tanaka.py`) |
| `harness\` | `harness.asm`, `build.sh`, `verify.py`, `model.json` |