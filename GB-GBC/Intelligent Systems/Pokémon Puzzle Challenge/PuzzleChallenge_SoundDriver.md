# Pokémon Puzzle Challenge (GBC): sound driver

Intelligent Systems' sound system for *Pokémon Puzzle Challenge* (`Pokemon Puzzle Challenge (E) (M5) [C][!].gbc`, internal title `POKEMONPCP`, MBC5 + RAM + battery, 2 MB). The sources in `PuzzleChallenge\` rebuild every byte of it **byte-exact** with RGBDS 0.9.1 (`-Wall` clean). That's 169,171 bytes in 12 regions: code, all tables, 97 songs, every sound effect and the 4 PCM samples.

It isn't one driver. There are four sound players, and their data is spread over 11 banks:

| Part | Region | Content |
|---|---|---|
| Home bank | `$128D–$1B15` | API, the bank-switching fetch stubs the music engine reads its data through, period/fine-tune/noise tables, the PCM player and the PCM sample table |
| Bank `$20` | `$4000–$771D` | **music engine** (4 channel copies), song table, 30 drum routines (code), 308 envelope pairs, 73 waves, 62 pitch macros |
| Bank `$21` | `$4000–$7A3E` | **SFX engine A** (4 channels, priorities) and all its effects |
| Bank `$7F` | `$4000–$4CCE` | **SFX engine B** (raw register streams, takes over the APU) and its 26 effects |
| Bank `$7F` | `$4CCF–$730E` | music: songs `$19–$1D` |
| Banks `$7C`, `$7D`, `$7E` | `$4000–$7CA8` / `–$7BAD` / `–$7C99` | music: songs `$00–$18` |
| Banks `$22–$26` | `$4000–$7A81` / `–$7F14` / `–$7E1C` / `–$7EED` / `–$7C4A` | music: songs `$1E–$20` and **64 unreferenced songs**; PCM samples 0–3 |

```
PuzzleChallenge\build_check.sh <rom> [rgbds dir]   # assemble the 12 regions, link over the ROM, compare
PuzzleChallenge\harness\build.sh [rgbds dir]       # test ROM from the rebuilt sections
PuzzleChallenge\harness\verify.py [frames]         # play everything, check every byte the code reads (needs build\model.json from ppcgen.py)
python tools\ppcgen.py <rom> PuzzleChallenge       # regenerate the sources (and build\model.json)
```

As far as is known, no other game uses this sound system. Song titles weren't identified, and the game situations behind each effect weren't traced.

---

## 1. API and integration

All entry points are in the home bank. Each one switches to the right bank and restores the caller's bank (`hROMBank` = `$FFA3`, register `$2100`).

| Address | Routine | Callers | Effect |
|---|---|---|---|
| `$1543` | `Sound_Init` | 5 | `Music_Init`, then `SfxA_Init` (which also stops engine B) |
| `$15B4` | `Sound_Update` | 13 | once per frame: engine B and engine A (bank `$21` → `$7F`), then the music |
| `$156A` | `Sound_PlayMusic` | 77 | `a` = song (0–`$60`); ignored while `wSoundOff` (`$C601`) ≠ 0 |
| `$1616` | `Sound_FadeOut` | 40 | `a` = frames per fade step (forced to 0 while `wSoundOff` ≠ 0) |
| `$15EF` | `Sound_StopAll` | 64 | stop engine B, the 4 engine A channels and the music |
| `$162B` | `Sound_LoadWave` | sound code only | copy music wave `wMusicWave` to wave RAM |
| `$1656` / `$166A` | `Sound_PauseMusic` / `Sound_ResumeMusic` | 1 / 1 (bank `$13`) | silence and stop ticking / reload the wave and run again |
| `$167E` / `$1692` | `Sound_SaveMusic` / `Sound_RestoreMusic` | **0** | copy `$C5F0–$C6CE` to/from `$C6CF` |
| `$16A6` | `Sound_IsIdle` | 6 | carry = sound is off, or no music channel is active and no fade is running |
| `$1ABA` | `Sound_PlayPCM` | 2 | `a` = sample 0–3, **blocks** until it ends; ignored while `wSfxDisable` ≠ 0 |
| `$16C9` | `Sound_SoundTest` | **0** | debug sound test (§3.10) |

Effects are requested by writing RAM; `Sound_Update` consumes the requests:

| Variable | Engine | Meaning |
|---|---|---|
| `wSfxRequest1` (`$C7CB`), `wSfxRequest2` (`$C7CC`) | A | bits 7–6 channel (0–3 = ch1–ch4), bits 5–0 effect number in that channel's table |
| `wSfxMultiRequest` (`$C7CD`) | A | multi-channel effect 1–47 (`SfxMultiTable`) |
| `wSfxBRequest` (`$C7C9`) | B | effect 1–26 (`SfxB_Table`) |
| `wSfxDisable` (`$C7CE`) | A, B, PCM | nonzero: engines A and B and the PCM player do nothing |
| `wSoundOff` (`$C601`) | music | nonzero: `Sound_PlayMusic`/`Sound_FadeOut` are ignored |

The game writes the effect requests directly, from dozens of places.

**Priorities between the players.**

- **Engine B** wins over everything. When an effect starts it clears engine A's RAM, resets the APU (NR52 off/on) and sets NR50 `$77`, NR51 `$FF`. While any of its channels runs, `SfxA_Update` returns at once and drops engine A's requests, and the music doesn't write NR50/NR52. It mutes music ch1, ch2 and ch4 (flags bit 0) every frame. Music ch3 isn't muted, so it carries on after its next trigger. Multi effects `$0A–$0C` stop engine B.
- **Engine A** mutes the music channel it plays on and unmutes it at the end (for ch3 it also reloads the music wave). The music keeps running and is heard again from its next note.
- The **PCM player** takes the CPU: it busy-waits for the whole sample with nothing else running.

---

## 2. Data layout

### 2.1 Music, where it lives

`SongTable` (`$20:$590E`) has 97 three-byte entries: pointer (LE) and bank. `Music_GetSongHeader` reads the entry backwards from `SongTable + 3n + 2`. Entry 0 and entries `$21–$60` point at the silent `Song_00` header (4 tracks that are just `TRACK_END`), except `$4F`/`$50` (= `$0D`) and `$54` (= `$06`). So 33 distinct headers are referenced.

```
Song_NN:     SONG_HEADER ch1, ch2, ch3, ch4      ; dw x4, 0 = channel unused
Song_NN_Ch1: ...track bytes...
```

Tracks are read one byte at a time through `Music_FetchByte` (home), with bank `wMusicBank`. GOTO/GOSUB targets are in the same bank.

### 2.2 The 64 unreferenced songs

Banks `$22–$26` hold **64 complete songs that nothing references**: 11 + 16 + 13 + 13 + 11. They have valid headers, all of them play through the engine without error (§6), and they use the same instruments. There are as many of them as there are placeholder slots (`$21–$60`). They are in the sources as `UnusedBB_AAAA` (bank, address), and `harness\verify.py` plays them with a custom header pointer.

Every music bank also contains **91 unreachable track fragments**. They're mostly subroutines that no track calls any more, and the bytes after a `GOTO`. They are labelled `OrphanBB_AAAA` and parse as normal track data. The 4 PCM samples are 16-byte aligned, with `$FF` padding in front.

---

## 3. Music engine (bank `$20`)

### 3.1 Structure

Each channel has its own copy of the sequence reader, the command handlers and the support routines (`MusCh1_*` at `$4000`, `MusCh2_*` at `$4525`, `MusCh3_*` at `$4A4A`, `MusCh4_*` at `$4F80`). They differ only in their RAM and register addresses, plus the ch3 wave handling and the ch4 noise lookup. They also have their own home-bank fetch stubs (`MusChN_FarGoto`, `…PitchMacFetch`, `…EnvFetch`, `…CallDrum`, …).

Each channel has a 48-byte structure at `$C602 + $30·n` (`wMusChN…` in `PPC_RAM.inc`). The global state is at `$C5F0–$C601`.

### 3.2 Timing

`Music_Update` adds ticks at `wMusicTempo` / 30 per frame: the accumulator starts at 30, loses `wMusicTempo` every frame, and on ≤ 0 it gets 30 back and a **tick** happens. `TEMPO 30` is one tick per frame, and `Music_Play` sets 6 (12 ticks/s). The songs use 5–30.

- **On a tick:** the 4 track readers, then pitch macros, then slides.
- **Every frame:** envelopes, drums, the fade, then `Music_WriteRegs`.

### 3.3 Track bytes

| Byte | Meaning |
|---|---|
| `$00` | `TRACK_END`: channel off |
| `$01–$6C` | length in ticks for the following events (read on, no wait) |
| `$6D–$89` | `DRM00–DRM28`: drum *n*, then wait |
| `$8A–$D1` | note `C_2–B_7` (ch4: noise index `NZ00–NZ71`), then wait |
| `$D2` | `REST`: release (unless `GATE` is set), wait |
| `$D3` | `HOLD`: wait |
| `$D4–$FF` | commands (§3.4) |

An event lasts *length* ticks. **Pitch** is kept as semitone × 8 + eighth (16-bit). A note sets it to (byte − `$8A` + `TRANSPOSE`) × 8. On ch4 it's the plain index, with no × 8.

### 3.4 Commands

| Byte | Macro | Effect |
|---|---|---|
| `$D4` | `PITCHMAC n` | pitch macro *n*, restarted at every note (ch4: argument ignored) |
| `$D5` | `PITCHMAC_OFF` | |
| `$D6` | `TEMPO n` | ticks per frame = n/30 (global; also resets the accumulator) |
| `$D7` | `TRANSPOSE n` | semitones (signed) |
| `$D8` | `ENVELOPE n` | envelope pair *n*: attack at note on, release at `REST`/gate |
| `$D9` | `ENVELOPE_OFF` | (unused) |
| `$DA` | `MASTERVOL x` | NR50 |
| `$DB/$DC/$DD` | `PAN_RIGHT/LEFT/CENTRE` | the channel's NR51 bits in `wMusicPan` |
| `$DE–$E1` | `DUTY 0–3` | NRx1 bits 6–7 |
| `$E2` | `WAVE n` | `wMusicWave` = *n*, wave loaded at once (quirk 2) |
| `$E3` | `DETUNE n` | signed, added to the period (no effect on ch4) |
| `$E4` | `PITCH_DETUNE n` | signed, added to the pitch before the lookup (unused) |
| `$E5` | `GATE n` | release when the event's tick counter equals *n* (unused) |
| `$E6` | `NRX2 x` | write NRx2 (this frame) |
| `$E7` | `GOTO p` | |
| `$E8–$EB` | `LOOP c, n, p` | counter *c* (1–4): repeat until it reaches *n* (unused; quirk 3) |
| `$EC` | `GOSUB p` | 3-entry stack (quirk 4) |
| `$ED` | `RETSUB` | |
| `$EE–$FD` | `NUDGE −8…−1, +1…+8` | pitch ± *n* eighths without a retrigger, then wait |
| `$FE` | `RETRIG` | retrigger the current pitch, wait (unused) |
| `$FF` | `SLIDE t, s, step` | glide *s* semitones over *t* ticks, *step* = 8.8 per tick; also sets the wait (unused) |

The songs (all 97) never use `$D9`, `$DB`, `$DC`, `$E4`, `$E5`, `$E8–$EB`, `$EF`, `$FC`, `$FE`, `$FF`.

### 3.5 Periods

`MusChN_CalcPeriod` → `Music_PitchToPeriod` (`$583C`) does:

period = `PeriodTable[pitch >> 3]` + `FineTuneTable[pitch]` (+ `DETUNE`)

with `PITCH_DETUNE` added to the pitch first. `PeriodTable` (`$16DD`) has 72 entries, C2 (`$002C`, 65.4 Hz) to B7. `FineTuneTable` (`$176D`) has 8 offsets per semitone. Ch4 instead uses `NoiseTable[index]` (`$19AD`, 60 NR43 values).

### 3.6 Instruments

- **Envelope pairs** (`EnvelopeTable`, 308 × `ENV_ENTRY attack, release`; the 97 songs use 165). The sequences run **every frame**:
  - `ENV_VOL x` writes NRx2 and retriggers.
  - `ENV_LEN n` (bit 7 set) writes the NRx1 length and enables the length counter.
  - `ENV_WAIT f`: the step lasts *f* frames.
  - `ENV_END` stops.

  `REST`/`GATE` switch to the release sequence once per note. Without one, the channel is cut (NRx2 = `$01`, DAC off).
- **Pitch macros** (`PitchMacroTable`, 62 entries; the songs use 25). They run **every tick**:
  - `PM_SPEED n`: ticks per step (sets it, then reads on).
  - `PM_DELTA d`: pitch += *d*/8 semitone, then wait.
  - `PM_GOTO p`
  - `PM_END`

  They're used for vibrato and arpeggios.
- **Waves** (`MusicWaves`, 73 × 16 bytes; the songs use 34). On a ch3 trigger, `Music_WriteRegs` turns the DAC off and on again (NR30 = 0, then the shadow) before writing NR34.
- **Drums** are **code**. `DRMnn` points a RAM trampoline (`wMusChNDrumJp` = `$C3` `jp`, then the address) at `DrumTable[n]` (ch1 from entry 0, ch2–ch4 from entry 7) and cuts the channel. Every frame, `MusChN_DrumUpdate` calls the routine. It writes the sound registers directly and returns the next routine in `de` (0 = done). The 30 entries are short frame-by-frame scripts: a kick that drops NR13/NR14 eight times, noise hits with fixed NR42/NR43, and so on. The songs use DRM00/01/04–06 on ch1 and DRM02–04/06/10–19 on ch4.

### 3.7 Register writes and muting

`Music_WriteRegs` (`$5521`) goes through each channel's `Update` byte:

- bit 7: trigger. Compute the period, set NRx4 bit 7, write all 5 registers, mark "release pending".
- bit 6: pitch changed. Write NRx3/NRx4.
- bit 5: NR51.
- bits 0–4: the single registers.

While a channel's flags bit 0 is set (an effect owns it), its writes are skipped, but the `Update` byte is still cleared. The music therefore takes the channel back only from its next trigger.

### 3.8 Fade, pause, save

`Sound_FadeOut(n)`: every *n* frames, take the next step of `FadeStepTable`. That's 7 × "NR50 left and right − 1", then NR50 = 0, then stop all channels, one idle step, and music off. `Music_Pause` silences and clears the running flag. `Music_Save`/`Restore` copy the whole state (`$DF` bytes) but nothing calls them.

### 3.9 Start and stop

`Music_Play` keeps the 4 mute bits and calls `Music_Init`, which clears `$C5F0–$C6CD` and **resets the APU** (NR52 off/on). It then loads the header and sets tempo 6. `Music_Stop` resets the APU as well.

### 3.10 Sound test

`Music_SoundTest` (`$5857`) is reached only through `Sound_SoundTest` (`$16C9`), which nothing calls. It reads `hJoyPressed` (`$FFBE`) with the usual bit layout:

- A / B: next / previous song (`wSoundTestSong`, 0–`$60`, wraps)
- Right / Down / Left / Up: toggle the mute bit of ch1 / ch2 / ch3 / ch4
- Select: `Sound_FadeOut(10)`
- Start: pause / resume

---

## 4. SFX engine A (bank `$21`)

**Requests.** `SfxA_StartSingle` takes the channel from bits 7–6 and the effect from bits 5–0. It looks up `Sfx1_Table` (`$60A4`, 64 entries, 55 used), `Sfx2_Table` (`$6EE5`, 16, **all empty**), `Sfx3_Table` (`$6F28`, 8, **all empty**) or `Sfx4_Table` (`$7106`, 24, 17 used). `SfxA_StartMulti` starts up to 4 channels from `SfxMultiTable` (`$4925`, 47 entries, 44 used). Most of them are ch1 + ch4; 4 use ch3.

**Priority.** Each table word is `(address & $3FFF) | priority << 14` (macro `SFX_PTR`). A request with a **lower** priority than the effect running on that channel is ignored; equal or higher replaces it. Address bits 0 (with any priority) mean "none".

**Streams** (one per channel). The format is read **every frame**:

| Byte | Meaning |
|---|---|
| `$01–$89` | wait *n* frames |
| `$8A–$D1` | note: set the period (and NRx3/NRx4 without a trigger); read on |
| `$00`, `$D2–$DF` | end: unmute the music channel (ch3: reload the music wave) |
| `$E0` `SFX_CALL p` / `$E1` `SFX_RET` | one-level call |
| `$E2` `SFX_LOOP n` / `$E3` `SFX_ENDLOOP` | repeat *n* times (0 = forever), one level |
| `$E4/$E5/$E6` `SFX_PAN_LEFT/RIGHT/CENTRE` | set bits in `wSfxPan`, which is never read (quirk 5) |
| `$E7` `SFX_SLIDE s, f` | ch1–ch3: glide *s* semitones in *f* frames |
| `$F0–…` | per channel, below |

| | ch1 | ch2 | ch3 | ch4 |
|---|---|---|---|---|
| `$F0` | `DUTY 0` (`$F0–$F3`) | `DUTY 0` (`$F0–$F3`) | `WAVE n` (4 waves, `SfxWaves`) | `LFSR15` |
| `$F1` | | | `LENGTH n` | `LFSR7` |
| `$F2` | | | `LENGTH_OFF` | `LENGTH n` |
| `$F3` | | | `LEVEL x` (NR32) | `LENGTH_OFF` |
| `$F4` | `LENGTH n` | `LENGTH n` | `TRIGGER` | `ENV x` (NR42) |
| `$F5` | `LENGTH_OFF` | `LENGTH_OFF` | `OFF` | `TRIGGER` |
| `$F6` | `ENV x` | `ENV x` | `TRANSPOSE n` | `OFF` |
| `$F7` | `TRIGGER` | `TRIGGER` | `FINE n` | `TRANSPOSE n` |
| `$F8` | `OFF` | `OFF` | | |
| `$F9` | `TRANSPOSE n` | `TRANSPOSE n` | | |
| `$FA` | `SWEEP x` (NR10) | `FINE n` | | |
| `$FB` | `FINE n` | | | |

The macros are `SFX1_…` to `SFX4_…`, because the opcode values depend on the channel. Unlisted bytes jump through a `$0000` table entry (to address 0). No stream contains one.

- `FINE` 0–7 is an eighth of a semitone (`FineTuneTable`); negative values borrow from the semitone below.
- ch4 notes index `NoiseTable`, or `NoiseTable7` after `LFSR7`.

**Unreferenced streams.** There are 32 blocks, labelled `SfxUnusedC_AAAA`. They include the streams stored right after the empty ch2/ch3 tables, and a ch3 stream that steps `SFX3_WAVE` through 1–86. That last one runs straight into `Sfx4_Table` with no end byte, so it was cut off when the table was placed after it.

---

## 5. SFX engine B (bank `$7F`)

`SfxB_Table` (`$7F:$4000`) has 27 words (entry 0 = none), each pointing at an 8-byte header: `SFXB_HEADER ch1, ch2, ch4`. The ch3 word is always 0 and is skipped. The streams are raw register rows read **every frame**:

| Bytes | Macro | Meaning |
|---|---|---|
| *f*, x2, x3, x4 | `SFXB_NOTE` | ch1/ch2: NRx2, NRx3, NRx4 (bit 7 forced), held *f* frames (0 = 1) |
| *f*, x2, x3 | `SFXB_NOISE` | ch4: NR42, NR43, trigger |
| `$FE` *d* | `SFXB_DUTYSEQ` | four 2-bit duties, rotated one step every frame |
| `$FD` *x* | `SFXB_SWEEP` | NR10 (the ch2 copy stores it in an unused byte) |
| `$FF` | `SFXB_END` | |

`SfxB_Start` far-calls `SfxA_Init` through the game's `FarCall` (`$09A6`, inline `dw`/`db`), and that clears engine A. While engine B plays, it owns the APU (§1). `SfxB_Update` returns the number of active channels. `SfxA_Update` uses it to stay out of the way.

---

## 6. PCM player (home `$1A25`)

`PcmTable` (`$1ADA`) has 4 entries: pointer, bank, length.

| Sample | Location | Bytes |
|---|---|---|
| 0 | `$22:$6CE0` | 3,131 |
| 1 | `$26:$5880` | 3,145 |
| 2 | `$24:$4000` | 1,900 |
| 3 | `$26:$64D0` | 1,631 |

`Pcm_Play` fills wave RAM with `$FF`, starts ch3 (NR30 `$80`, NR33/34 = period `$0FF`) and then plays the sample by writing **NR32** (output level mute/100/50/25 %) only. Each byte holds two samples:

- the first sample: level in bits 5–4, extra hold in bits 7–6 (in `Pcm_Delay` units)
- the second sample: level in bits 1–0, extra hold in bits 3–2

When `hConsoleType` (`$FFA8`, the boot value of A) is `$11` (CGB), every delay is done twice. The game has a CGB speed-switch routine (`$0B79`), but whether double speed is on during playback wasn't traced. The samples are `INCBIN`ed from `pcm\PcmSampleN.bin`.

**WAV renders** (`tools\pcm2wav.py`, written to `pcm\PcmSampleN.wav`, 44.1 kHz). The script models `Pcm_Play` cycle by cycle from its instruction timings, box-filters the four DC levels (0, 3, 7, 15) to 44.1 kHz, and applies a DC-blocking high-pass filter like the console's output capacitor.

| Sample | DMG length | Average rate |
|---|---|---|
| 0 | 0.613 s | 10.2 kHz |
| 1 | 0.625 s | 10.1 kHz |
| 2 | 0.353 s | 10.8 kHz |
| 3 | 0.329 s | 9.9 kHz |

PyBoy blocks for 36, 37, 21 and 19 frames playing them, which agrees with these lengths. `--cgb` writes `_cgb.wav` versions that assume double speed with the doubled delays. They come out about 3 % slower.

**Native rate.** The player's loop is built from steps of about 31 M-cycles: a sample with hold *n* lasts 31/32, 60/61, 91/92 or 122/123 cycles. The data is therefore run-length-coded audio at **1,048,576 / 31 ≈ 33,825 Hz**: each sample is its level repeated 1 + *hold* times. `tools\pcm2wav_native.py` writes `pcm\PcmSampleN_native.wav` on that grid with no resampling. The output is 8-bit unsigned, uses the raw levels 0/3/7/15 (× 17) and keeps the DC offset. Longer holds really run 2 cycles short per extra step, so these files come out about 1 % longer than the cycle-accurate renders. The CGB double-speed timing doesn't fall on a clean grid.

---

## 7. Songs

| Slot | Bank:addr | Channels | End |
|---|---|---|---|
| `$00` (+ `$21–$60` except `$4F/$50/$54`) | `7C:4000` | silent | stop |
| `$01–$06` (`$54` = `$06`) | `7C:56AF`, `400C`, `5D0A`, `4D11`, `6675`, `6F53` | 1–4 | loop |
| `$07` | `7C:75FD` | 1–3 | loop |
| `$08` | `7D:4000` | 1–4 | loop |
| `$09` | `7D:4BE2` | 1–3 | stop |
| `$0A–$0C` | `7D:4CE0`, `561D`, `5D83` | 1–4 | loop |
| `$0D` (= `$4F`, `$50`) | `7D:6872` | 1–3 | loop |
| `$0E` | `7D:6980` | 1–4 | loop |
| `$0F–$14` | `7E:4000`, `48D7`, `4A9F`, `54D9`, `5DDA`, `6BD0` | 1–4 | loop |
| `$15` | `7C:7940` | 1–4 | loop |
| `$16`, `$17` | `7E:6D33`, `7AE0` | 1–4 | loop |
| `$18` | `7E:7986` | 1–3 | stop |
| `$19–$1B` | `7F:4CCF`, `5389`, `60C2` | 1–4 | loop |
| `$1C` | `7F:7008` | 1–3 | loop |
| `$1D` | `7F:7233` | 1–4 | stop |
| `$1E` | `24:5365` | 1–4 | loop |
| `$1F` | `22:5F9E` | 1–4 | loop |
| `$20` | `23:7689` | 1–4 | loop |

GOSUB nesting reaches at most 2 levels across all 97 songs.

---

## 8. Quirks

1. **Pitch macro end** (`MusChN_PitchMacByte`). At `$00` the code does `xor a` / `ld a, [wMusChNPMacPtr + 1]` where `ld [..], a` was meant. The macro is never flagged as stopped, so it re-reads the `$00` every tick. It has no audible effect.
2. **`WAVE` while ch3 is muted.** Every channel's `$E2` handler skips the argument fetch when music ch3's mute bit is set (an engine A effect on ch3, or the sound test). The argument byte (a wave number 4–72) is then read as the next track byte, i.e. as a *length*. Any events that follow without their own length byte play at the wrong length, and `wMusicWave` isn't updated.
3. **`LOOP` exit** skips 3 bytes after the count, one more than the pointer. No song uses `LOOP`.
4. **GOSUB stack.** The check (`cp 7` / `jr nc, @`) allows a 4th push, which overwrites `StackPos` and `Transpose`. A 5th push hangs the CPU. The songs nest 2 deep.
5. **SFX pan does nothing.** `SFX_PAN_*` and every effect start set bits in `wSfxPan` (`$C832`), which nothing reads. `SfxA_Update` writes the *music's* `wMusicPan` to NR51.
6. **Dead code:**
   - `MusCh4_AddDetune_Unused` (`$52A2`), so `DETUNE`/`PITCH_DETUNE` do nothing on ch4;
   - `SfxA_Unused40E0` (a lone `ret`) and `SfxA_FindChannel_Unused` (`$40E1`);
   - `Sound_SaveMusic`/`Sound_RestoreMusic` and the sound test.
7. **Empty tables:**
   - `Sfx2_Table` and `Sfx3_Table` are all zero, but streams are stored right after them;
   - `Sfx1_Table` entry 49 is `$4000` (priority 1, no stream);
   - `SfxMultiTable` entries 37, 42 and 47 are empty.
8. **`Music_Play` and `SfxB_Start` reset the APU** (NR52 off/on), so any sound playing at that moment is cut.
9. **Engine B mutes music ch1/ch2/ch4 only.** Music ch3 keeps playing over engine B effects.
10. **Unused data:**
    - the 64 songs (§2.2) and 91 track fragments;
    - 32 SFX blocks, including the cut-off wave-test stream;
    - 2 envelope fragments (`EnvUnused_6986`, `_6C50`) and 2 pitch-macro fragments (`PMacUnused_7583`, `_758A`).

---

## 9. Verification

- **Byte-exact rebuild** (`build_check.sh`): `rgblink -O` over the original ROM gives an identical file. Each of the 12 regions also matches when linked **without** the overlay (`-p $FF`).
- **No raw bytes** in code or stream data: everything is decoded into instructions or macros. The only plain `db` lines are the waves, the noise tables and the 25 `$FF` padding bytes before the PCM samples.
- **Emulator harness** (`harness\`): a ROM built from the **rebuilt** sections. It has its own boot loop, which calls `Sound_Update` once per frame, and a copy of `FarCall`. `verify.py` (PyBoy 2.8) does 250 runs:
  - the 33 table songs and the 64 unreferenced songs, 3,600 frames each;
  - every engine A single (72) and multi (47) effect, and every engine B effect (26), 600 frames each;
  - the 4 PCM samples, in both DMG and CGB timing.

  223 hooks on the instructions that read through `bc`/`de`/`hl` (home stubs, engine A, engine B, the table readers) record every ROM byte read.

  | | Result |
  |---|---|
  | ROM bytes read | 129,067 distinct |
  | reads outside the generated data model | **0** |
  | runs where `Sound_Update` stopped (hang) | 0 |
  | music track items read | 16,947 / 18,938 (the rest are later sections not reached in 60 s) |
  | music orphan items read | 0 / 1,199 |
  | SFX stream items read | 7,563 / 7,776 |
  | SFX orphan items read | 0 / 1,325 |

- **Not verified:** what each song and effect is used for in the game, the CGB speed during PCM playback, and anything on hardware.

## Files (`PuzzleChallenge\`)

| File | Content |
|---|---|
| `PPC_Home.asm` | home section `$128D–$1B15`: API, fetch stubs, tables, PCM player |
| `PPC_Bank20.asm` | music engine, song table, drum routines, envelopes, waves, pitch macros |
| `PPC_Bank21.asm` | SFX engine A and its effects |
| `PPC_Bank7F.asm` | SFX engine B and its effects, songs `$19–$1D` |
| `PPC_Bank7C/7D/7E.asm` | songs `$00–$18` |
| `PPC_Bank22–26.asm` | songs `$1E–$20`, the 64 unreferenced songs, PCM samples |
| `PPC_Macros.inc`, `PPC_RAM.inc`, `GB_Hardware.inc` | macros and constants (`FarCall`, PCM lengths), RAM map, sound registers |
| `pcm\PcmSample0–3.bin`, `.wav`, `_cgb.wav`, `_native.wav` | the four 2-bit PCM samples and their WAV renders |
| `tools\` | `ppcgen.py` (generator), `ppcparse.py` (data model), `ppcnames.py`, `ppcram.py`, `ppcmacros.py`, `codegen.py`, `emit.py`, `gbdis.py` (standalone disassembler), `pcm2wav.py` (cycle-accurate PCM renderer), `pcm2wav_native.py` (native-rate PCM converter) |
| `harness\` | `harness.asm`, `build.sh`, `verify.py` |
