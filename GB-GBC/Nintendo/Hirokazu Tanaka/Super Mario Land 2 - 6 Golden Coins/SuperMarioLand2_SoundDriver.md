# Super Mario Land 2 (GB): sound driver
 
This is the Tanaka-family driver in *Super Mario Land 2: 6 Golden Coins* (`Super Mario Land 2 - 6 Golden Coins (UE) (V1.0) [!].gb`, MBC1+RAM, 512 KB). It fills all of bank 4, and **all of its variables are in cartridge RAM** (`$A400–$A5FF`). The bank, `$4000–$7FFF`, rebuilds **byte-exact** with RGBDS 0.9.1 (`-Wall` clean) from the sources in `Nint1\SML2`.
 
| Range | Content | File |
|---|---|---|
| `$4000–$5243` | init, update, SFX dispatch, 59 effects (code and data), SFX helpers | `SML2_SFX.inc` |
| `$5244–$5ACB` | song table, pan table, music code, pause, new effects | `SML2_Music.inc` |
| `$5ACC–$5CB2` | vibrato table, note table, 8 waves, noise table, 9 length tables, release envelopes | `SML2_Tables.inc` |
| `$5CB3–$7F5D` | 39 song headers (42 song numbers), 126 lists, 192 patterns | `SML2_Songs.inc` |
| `$7F5E–$7FFF` | `Sound_Stop` | `SML2_Stop.inc` |
 
```
SML2\build_check.sh             # assemble, link over the ROM, compare
SML2\harness\build.sh           # test ROM (MBC1+RAM) with the rebuilt bank 4
SML2\harness\verify.py [N]      # play every song/SFX, check every data read
python SML2\gen_sml2.py <rom> SML2
```
 
The core is the same as *Dr. Mario*'s (`DrMario_SoundDriver.md`): the 16-byte channel structures, the section lists, the `$9B–$9F` commands and the `$Ax` lengths. Both the music and the effects add a lot, as described below.
 
---
 
## 1. API
 
| Address | | |
|---|---|---|
| `$4000` | `Sound_Init` | clear `$A400–$A5FF`; NR52/NR50/NR51 |
| `$402D` | `jp Sound_Stop` | the routine itself sits **after the song data**, at `$7F5E` |
| `$4030` | `Sound_Update` | once per frame |
 
The game also calls `$4003`, which is the inner loop of the first clear. This clears from whatever `hl` holds to the end of that page, then the whole `$A500` page, and resets the sound registers.
 
| Variable | | Meaning |
|---|---|---|
| `wSongRequest` | `$A468` | 1–42 = song (`$2B+` ignored), `$FF` = stop |
| `wSfx1Request` | `$A460` | 1–24, ch1 effects |
| `wSfx3Request` | `$A470` | 1–24, **ch3** effects |
| `wSfx4Request` | `$A478` | 1–11, ch4 effects |
| `wPauseRequest` | `$A45E` | 1 = pause, 2 = resume |
| `wQuietMusic` | `$A53F` | non-zero: NR50 = `$33` instead of `$77` |
| `wInstrumentLock` | `$A48D` | non-zero: `$9D` commands are read but not applied (only read by the driver) |
 
**Order.** Pause, then the song request (a new song skips the effects that frame), then ch1, ch3 and ch4 effects, then music. The requests are cleared last.
 
---
 
## 2. Songs
 
### 2.1 Header
 
The header is **13 bytes**, with two length tables:
 
```
SONG transpose, LengthTable, FastLengthTable, Ch1List, Ch2List, Ch3List, Ch4List
```
 
**Fast mode** (`wFastMusic`) is set by song 9 and cleared by songs 2, 3, 12, 15 and 24. Every other song **keeps** whatever value it had. A song that starts in fast mode:
- adds 4 to its transpose (2 semitones up);
- uses `FastLengthTable`, which is shorter for 18 songs.
`SongTable` has 42 entries but only 39 headers:
- songs 7, 10, 41 and 42 share one header;
- songs 36–39 have their own headers (13 bytes before those of 32–35), and their lists point one entry into songs 32–35's lists. They are the same pieces without the first section.
`$7F52` is a shared "silent" list used as ch1 or ch3 by several songs. It plays `REPEAT $20, L1, REST, REPEAT_END` in a loop.
 
### 2.2 Pattern bytes
 
| Byte | | |
|---|---|---|
| `$00`, `$01`, notes, `$A0–$AF` | as *Dr. Mario* | |
| `$9B n` / `$9C` | `REPEAT` / `REPEAT_END` | 183 uses |
| `$9D` | `INSTR env, release, duty` / `INSTR_WAVE wave, level` | 207 |
| `$9E ptr` | `TEMPO` | 11 |
| `$9F n` | `TRANSPOSE` | unused |
| `$99` / `$9A` | `CH3_FADE_ON` / `_OFF` | 24 / 8 |
| `$97` / `$98` | `DROP_ON` / `_OFF` | 15 / 11 |
| `$95` / `$96` | `BEND_ON` / `_OFF` | 9 / 9 |
| ch4 `$1F` | `SFX_DRUM`: starts **ch4 effect 3** instead of a drum (unless an effect owns ch4) | |
 
**Length tables.** Nine tables of 15 entries (`$5C25 + 15·n`). The first 9 entries have the usual layout; the triplet and extra entries differ from *Dr. Mario*'s. `$5C25` isn't used by any header.
 
### 2.3 Instruments and per-note effects
 
The second `INSTR` byte, unused in *Dr. Mario* and *SML1*, becomes **release**:
- high nibble: bit 7 = release at half the note length, bit 6 = at a quarter, bits 5–4 only = at three quarters (at least frame 2);
- low nibble = index into `ReleaseEnvelopes` (7 NRx2 values).
When `NoteFrames` reaches the release point, the driver writes that envelope and retriggers the channel (ch1 and ch2 only).
 
| Effect | Source | Behaviour |
|---|---|---|
| Vibrato | Duty low nibble = 1 | from frame 25 of a note, add `VibratoTable` (20 big-endian offsets: 0, 0, +1, +1, +2, +2, 0, 0, −1, −1, −2, −2, 0, +1, +2, +1, 0, −1, −2, −1), cycled |
| Detune | Duty low nibble 2–15 | period − 1 |
| Bend | `BEND_ON` | start 4 below the note, rise 1 per frame for 4 frames |
| Drop | `DROP_ON` | the period falls 100 every frame |
| ch3 fade | `CH3_FADE_ON` | NR32: 50 % on frame 3, 25 % on 5, mute on 7, 25 % again on 10, mute on 13, then stop |
| ch3 level bit 7 | as *Dr. Mario* | 50 % for the last 6 frames |
 
Every note resets the bend, vibrato, drop and fade state of its channel.
 
The trigger writes NRx4 | `$80` (no length), as *SML1* does. A rest writes envelope `$08`, as *Dr. Mario* does.
 
**Shared variable.** `wVibrato` (`$A520`, ch1's vibrato frame counter) doubles as an SFX flag (§3.2).
 
### 2.4 Panning
 
`SongPanTable` holds 6 bytes per song: mode, period and four NR51 values. Any mode other than 1 cycles through the four values. All 42 entries are `01 00 FF FF 00 00`, i.e. fixed `$FF`.
 
---
 
## 3. Sound effects
 
### 3.1 Mechanism
 
There are three channels of effects: ch1 (24), **ch3** (24) and ch4 (11). Each channel has an init table and a play table. The channel's timer and step variables are passed in `de` / `bc`.
 
An effect is mostly data: **steps** of register bytes plus a frame count.
- ch1 / ch3: 5 registers + 1 byte;
- ch4: 4 + 1;
- 2 registers + 1 for period-only steps.
The per-frame routine does the following:
1. decrement the timer (`Sfx_DecTimer`);
2. when the timer reaches 0, increment the step (`Sfx_IncStep`);
3. compare the step with the effect's length;
4. write the next step, often picked from a **pointer table** of steps (`GetPointer`).
Pitch-moving effects add **big-endian offsets** to a running period (`Sfx_AddPitch`). ch3 effects load one of the waves at `$5B86–$5BF6`. When a ch3 effect ends, the song's wave is reloaded from `wCh3InstrEnv/Release`.
 
### 3.2 Priority
 
| Start routine | ch1 | ch3 | ch4 |
|---|---|---|---|
| plain | `Sfx1_Start` | `Sfx3_Start` | `Sfx4_Start` |
| priority | `Sfx1_StartPriority` (`wSfx1Priority`) | `Sfx3_StartPriority` | (`Sfx4_StartPriority_Unused`, unreferenced) |
 
While a priority effect plays, new requests on that channel are refused, with these exceptions:
- **ch1:** effects 9, 12, 15, 16, 17, 19, 20 and 23 always start;
- **ch3:** effect 20 always starts.
`Sfx1_StartInterruptible` is a priority start that also sets `wVibrato`. A non-zero `wVibrato` lets any ch1 effect through.
 
Because `wVibrato` is also ch1's music vibrato counter, a ch1 music note clears it. Music keeps reading notes while an effect owns the channel, so the next ch1 note turns an "interruptible" effect into an ordinary priority one.
 
ch3 effect 19's init and play entries both point to a bare `ret` (`Sfx3_Nothing`).
 
### 3.3 Pause
 
The pause mutes everything and cancels the effects, then plays a **5-step jingle on ch2** (`PauseJingleTable`, 4 registers + frames per step). After the last step it stays silent until resumed. This is a different design from *Dr. Mario*'s timer-frame jingle.
 
---
 
## 4. Unreferenced code and data
 
| Address | |
|---|---|
| `$401D–$402C` | 16 bytes |
| `$515E` | ch4 priority start |
| `$51E2`, `$51EE`, `$51F9` | counter / pitch helpers for SFX variables nothing else uses |
| `$52B4` / `$52C8` | **save / restore the music state** (`$A410–$A449` ↔ `$A490`): a song-interruption feature like Metroid II's. Both loops compare the wrong register's low byte (`e` in the save, `l` in the restore) against `$4A`, so each would copy 186 bytes instead of 58. Nothing calls them, and nothing else uses `wSavedChannels` / `wSavedSong` |
| `$7FFD–$7FFF` | 3 bytes after `Sound_Stop` |
 
---
 
## 5. Verification
 
- **Byte-exact rebuild** of `$4000–$7FFF`.
- **Emulator harness.** The test ROM is MBC1+RAM, bank 4 = **rebuilt** driver; `Sound_Update` runs once per frame. Requests go through WRAM mailboxes (`$C000–$C003`) copied by the harness, because PyBoy's direct writes to cartridge RAM were not reliably seen by the CPU once a song was running. `verify.py` hooks the pattern read, the list read, register-image copies, pointer-table and pitch-table reads, the wave loader, and the vibrato / release / noise table reads.
  | | Reads | Outside the parse |
  |---|---|---|
  | Songs 1–42, 3,600 frames each (pattern / list) | 59,390 / 2,863 | 0 |
  | ch1 effects 1–24 | 4,070 | 0 |
  | ch3 effects 1–24 | 4,115 | 0 |
  | ch4 effects 1–11 | 1,224 | 0 |
  With 12,000 frames per song, every parsed pattern byte is read except 16 final `PAT_END`s of channels that outlast ch1 in non-looping songs.
- **Not verified:** what the game uses fast mode, `wInstrumentLock` and `wQuietMusic` for; song and effect identities; anything on hardware.
## Files (`Nint1\SML2`)
 
| File | Content |
|---|---|
| `SML2_Sound.asm` | the section; includes the files below |
| `SML2_SFX.inc`, `SML2_Music.inc`, `SML2_Stop.inc` | code with labels and comments; effects named `Sfx1_01` … `Sfx4_0B`, their data `SfxN_XX_Data_addr` (rows of 6 / 5 / 3 / 2 bytes by consumer, pointer tables as `dw`) |
| `SML2_Tables.inc` | `VibratoTable`, `NoteTable`, waves, `NoiseTable`, length tables, `ReleaseEnvelopes` |
| `SML2_Songs.inc` | headers, lists, patterns |
| `SML2_Macros.inc`, `SML2_RAM.inc` | macros (adds `CH3_FADE_ON/OFF`, `DROP_ON/OFF`, `BEND_ON/OFF`, `SFX_DRUM`); cartridge-RAM map |
| `gen_sml2.py`, `harness\` | generator, test ROM and checker |