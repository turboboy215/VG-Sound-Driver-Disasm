# Castlevania Legends (GB): sound driver

ROM: `Castlevania - Legends (UE) [S][!].gb` (DMG with SGB support, MBC1, 256 KB, internal title `CASTLEVANIA`). Konami, 1997 (Japan; 1998 in North America and Europe).

Part of the Konami family, see `Konami_SoundEngine_Family.md`. This is the latest Konami driver covered so far, and it descends from **Raging Fighter's** (`RagingFighter_SoundDriver.md`): PlaySound, the header reading, the update loop, the tempo, the fade and `FarRead` in ROM0, the track code in bank 14, two sound banks read through a 4-byte buffer, the same seven tracks with the same descriptors, track fields from `$A0`, the fourth-generation flow commands. About 990 of its 1,890 instructions line up with Raging Fighter's (about 800 with Batman's, 370 with Tiny Toon 2's). Much of the track code is new:

- **no packed SFX notes**: Sfx1 and Sfx2 read ordinary notes. Instead `$E0 u|$80 v x` puts any tone or wave track into a **note-volume mode** where a note's low nibble is its **volume** and every note lasts one unit (most SFX use it);
- **changed commands**: `$EC` selects a **volume envelope** (Raging Fighter: start a fade; a voice with volume 0 selects one too), `$F8` is one more attenuation (was volume), **`$F9 x` is a "break on the last pass"** of loop 1 or 2 (was a counted jump), and in note-volume mode `$EE` becomes a **slide-repeat** (`$EE` … `$EE x y n`); `$EB`, `$ED`, `$EE`, `$EF`, `$FA–$FF` keep their meanings;
- `$EA` gains `Ax y` (an **NR50 left/right wobble**), `Bx` (hold all requests) and `Cx`; the fade is still there but nothing in the live code starts it;
- bank 15 starts at id **`$50`** (Raging Fighter: `$A0`), the track pages are at **`$D0A0`**, and there is a **pause** (the game's `$D7DC`).

| | |
|---|---|
| API | ROM0 `$0875` `PlaySoundFar` (A = id, 0 = stop all; 136 call sites) → `$08F8` `PlaySound` |
| Game inputs | `wPauseFlag` `$D7DC` (1 = paused), `wSndDim` `$D7D9` bit 0 (NR50 left alone by requests) |
| Tick | **VBlank**: the handler (`$0068`) calls `SndUpdateFar` `$0098` → `SndUpdate` `$0A38`, skipped while `wSndBusy` `$C523` bit 0 or 1 is set (bit 1 = a request in progress). The timer vector is a `reti` |
| Driver code | ROM0 `$0098–$00AA`, `$0875–$0BC0` (0.9 KB); bank 14 `$465C–$5353` (3.3 KB, jump tables at `$4DA8`, `$4DEA`, `$4F0C`) |
| Data | bank 14 `$4000–$465B` (table, headers, waves, periods, vibrato/semitone/envelope tables, drum hits) and `$5354–$5E13` (SFX, two songs); bank 15 `$4000–$7FCC` (table, headers, songs); the rest is `$FF` |
| RAM | seven tracks at `$D0A0 + n×$100` (`$A0–$FF`), globals `$D7C1–$D7DC`, `wReadBuf` `$D7D1–$D7D4` |
| Channels | Sfx1 (CH1), Sfx2 (CH3), SfxN (CH4), Ch1, Ch2, Ch3, Drm (drum notes = bank-14 ids) |
| Counts | 88 ids: bank 14 `$01–$42` (12 drum hits, SFX, two songs), bank 15 `$51–$66` (22 songs and stops) |

`CVL_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over ROM0 `$0098–$00AA`, `$0875–$0BC0` and all of banks 14 and 15. It assembles cleanly with `-Wall`.

```
rgbasm -Wall -o cvl.o CVL_SoundDriver.asm
rgblink -o cvl.gb cvl.o
python tools/cmp_ranges.py cvl.gb "Castlevania - Legends (UE) [S][!].gb" 0:0098-00AA 0:0875-0BC0 E:4000-7FFF F:4000-7FFF
```

---

## 1. Structure

### 1.1 Tracks and descriptors

| # | Page | Name | Descriptor | Registers (`$BB–$BE`) |
|---|---|---|---|---|
| 0 | `$D0A0` | Sfx1 | `$40` | NR11–NR14 |
| 1 | `$D1A0` | Sfx2 | `$52` | NR31–NR34 |
| 2 | `$D2A0` | SfxN | `$63` | NR41–NR44 |
| 3 | `$D3A0` | Ch1 | `$00` | NR11–NR14 |
| 4 | `$D4A0` | Ch2 | `$11` | NR21–NR24 |
| 5 | `$D5A0` | Ch3 | `$22` | NR31–NR34 |
| 6 | `$D6A0` | Drm | `$34` | none (0) |

As in Raging Fighter the drum track's register addresses stay 0 (its writes go to `$FF00`), and music Ch1 / Ch3 are blocked while Sfx1 / Sfx2 play (`WriteRegChecked`).

### 1.2 Track fields

The page runs from `$A0` to `$FF` (Raging Fighter: `$A0–$E0`). The asm names the fields the code makes clear:

| L | Name | Use |
|---|---|---|
| `$A0` / `$A1` / `$A2` / `$A4` | PRIO, ID, PTR, LEN | |
| `$A5` | FLAGS | 1 **note-volume mode**, 2/5 channel given back, 4 tempo skip, 6/7 noise volume |
| `$A6` | PANFLAGS | 0 autopan, 1 side, 3 envelope running, 5 slide, 6 autopan both, 7 `$EA Cx` |
| `$A7` | FLOW | 0 loop 1, 1 loop 2, 2 in a call, 3 mark set, 6/7 envelope loop/mark |
| `$A9–$B2` | loop 1 (start, count), loop 2 (start, count), mark, return | |
| `$B3` / `$B4` / `$B5` / `$B9` / `$BA` | UNIT, ATTEN, PERIOD, VOL, LASTVOL | |
| `$BB–$BE` | register addresses | |
| `$BF` / `$C1` / `$C3` / `$C4` / `$C5` | GATE, ENV, PAN bits, VIB, ENVNO | |
| `$C6` / `$C8` / `$C9–$CB` / `$CC` / `$CD` | DETUNE, TRANSP, duty step, OCTAVE, DUTY | |
| `$DD–$E6` | envelope pointer, position, timer, loop, mark | |
| `$E7` | RELVOL | |
| `$EA–$EF` | **loop breaks**: pass counter and exit address for loops 1 and 2 | |
| `$F1–$F7` | **slide**: mark, pass counter, attenuation counter, pitch offset | |
| `$FF` | MUTE | tested before every read, never set (as Raging Fighter's `$E0`) |

A start clears `$A5–$A8`, `$B4`, `$C4–$CA`, `$E8–$EF`, `$BF–$C2`, `$F1–$F7` (not the unit, the loop/return pointers or the envelope position).

### 1.3 Globals

`wTrackDesc` `$D7C1`, `wTempo`/`wTempoAcc` `$D7C5/6`, `wReqPrio`/`wReqId` `$D7C7/8`, `wFadeDir`/`wFadeRate`/`wFadeTimer`/`wFadeStep` `$D7C9–$D7CC`, `wWaveId` `$D7CE`, `$D7CF` (cleared, never read), `wReadBuf` `$D7D1–$D7D4`, the wobble `$D7D5–$D7D8`, `wSndDim` `$D7D9`, `wReqHold` `$D7DA`, `wHeldReq` `$D7DB` (written, never read), `wPauseFlag` `$D7DC`; the game's bank is in `wRomBank` `$C522`.

---

## 2. Timing

### 2.1 Update

Once per VBlank. While `wPauseFlag` is 1, CH2 is muted (NR22 = 8, trigger) and only the SFX tracks run. Else: `FadeCheck`/`FadeTick`, `WobbleTick`, `TempoTick`, then Ch1, Ch2, Ch3, Drm, SfxN, Sfx2, Sfx1, each through `RunTrack` (descriptor, nothing if the id is 0, map bank 14, `jp TrackTick`); the game's bank is mapped again at the end. Every read goes through `FarRead` (bank 15 for ids ≥ `$50`).

### 2.2 Tempo

As Raging Fighter (all four music tracks skip an update on a carry). Tempos in the data: `$08`, `$10`, `$20`, `$40`, `$58`, `$90`.

### 2.3 Fade and wobble

The fade is Raging Fighter's (NR50 − `$11` every `wFadeRate` updates down to `$11`, then the stop steps `$10` Drm, `$18` Ch1, `$1C` Ch2, `$20` Ch3) with a fade-in direction added (`wFadeDir` bit 0: NR50 + `$11` up to `$77`). It only runs while music Ch3 plays, and `wReqHold` bit 2 cancels it. `$EC` no longer starts it, and **no live code does**: the only writers of `wFadeRate` are three routines nothing calls (`StartFadeOut`, `StartFadeIn` and `EndFadeIn`, the last one skipped over by `Cmd_End`).

`$EA Ax y` starts a **wobble**, a stereo sweep: every `y >> 4` updates one volume step of NR50 moves between the sides (the right side down while the left goes up, capped at 7, then the other way), turning round when a side reaches `7 − (y & 7)`. `y = 0` ends it with NR50 = `$77`; every request switches it off. It is unused by the data.

### 2.4 Requests

`PlaySound` (ROM0), id in A:

| Id | Action |
|---|---|
| 0 | `StopAll` (bank 14): ids and priorities cleared, NRx2 = 8 on all channels, NR30 = 8, triggers, NR51 = `$FF`, NR10 = 8, NR50 = `$77`, wobble and hold off |
| any, while `wReqHold` bit 0 | stored in `wHeldReq` (never read) – the request is lost |
| `$01–$4F` | header from bank 14 `SoundTable` (`$3FFE` + 2 × id; valid `$01–$42`) |
| `$50–$FF` | header from bank 15 `SoundTable15` (`$3FFE` + 2 × (id − `$50`); valid `$51–$66`, `$50` reads ROM0) |

Before the header: the wobble is switched off, and NR50 = `$77` unless `wSndDim` bit 0 or a fade is set. Then Raging Fighter's logic: if any SFX track of the mask holds a higher priority nothing starts; SFX tracks start without tests (Sfx1: NR10 = 8, SfxN: NR51 |= `$88`); music needs the Ch1 bit and a priority ≥ Ch1's, resets the tempo and the fade step (and the fade rate unless a fade direction is set). Drum notes start the bank-14 hit with the note's high nibble as id, each of its SFX tracks with its own priority test.

### 2.5 Pause

The game sets `wPauseFlag` = 1: music stops updating, CH2 is muted on every update (CH1 and CH3 are left as they were), and SFX keep playing. `SndDim`/`SndUndim` (NR50 = `$44` / `$77`, unreferenced) suggest a dimming that the game does through `wSndDim` itself.

---

## 3. Data format

### 3.1 Notes

| Byte | Track | Meaning |
|---|---|---|
| `$00–$DF` | tone, wave | hi = pitch (0 = rest, 13 = the last pitch an octave up), lo × unit (lo 0: (unit & 15) × 16; 0 = 256) |
| `$00–$DF` | tone, wave in **note-volume mode** | hi = pitch, **lo = volume**, length = one unit |
| `$00–$DF` | Drm | **drum hit id = hi** (bank 14), lo × unit; hi 0 = a rest that writes to `$FF00` |
| `$00–$BF` | SfxN | NR43, one unit |
| `$C0–$CF` / `$D0` / `$D1–$DF` | SfxN | volume nibble (no time) / a muted unit / volume nibble and a unit |

### 3.2 Commands

| Byte | Meaning |
|---|---|
| `$E0 u v g` | voice (u bit 7 clear): unit u, duty = v >> 4 (CH3: wave), volume = v & 15; g = gate << 4 \| env – or, **with volume 0, g = envelope number**; note-volume mode off |
| `$E0 u\|$80 v x` | **note-volume voice**: unit, duty = v; x = NR10 on the CH1 tracks (ignored elsewhere); 4 bytes |
| `$E0 u v` | SfxN: unit, NR42 (u bit 7: written at once); 3 bytes |
| `$E1–$E6` | octave (`OctaveCodes` `$18 … $90`) |
| `$E7 x` / `$E8 xy` / `$E9 x` | unit / gate + env (release volume 0, envelope off) / NR10 |
| `$EA xy` | 0 duty (wave), 1 pan both (autopan off), 2 left, 3 right, 4 autopan, 5 autopan both, 6 = 1, 7/8 transpose up/down 2y, 9 release volume, **A wobble (3 bytes)**, **B `wReqHold` = y**, **C PANFLAGS bit 7**; D–F run into the code |
| `$EB n xy` / `$EB n\|$80` / `$EB 0` | vibrato table n with delay and depth / semitone table n / off |
| `$EC n` | **volume envelope n** (0 = off) |
| `$ED xy` | duty step |
| `$EE x` | tempo; **in note-volume mode**: the first `$EE` marks, the next `$EE x y n` adds x to a pitch offset and steps the attenuation by y, and goes back to the mark until the n-th pass – x, y, n are read with `ld a, [de]`, i.e. from bank 14 even for a bank-15 stream |
| `$EF x` | detune (sign-extended) |
| `$F0–$F8` | attenuation (CH3: its own scale); 1 byte |
| `$F9 x` | **break**: on the last pass of loop 1 (x odd) / loop 2 (x even) jump to the byte after its `$FB n` / `$FC n` |
| `$FA addr` | jump |
| `$FB` / `$FB n`, `$FC` / `$FC n` | two loop levels: the first marks, the next loops n times |
| `$FD addr` / `$FD` | call / return |
| `$FE` / `$FE` | mark / jump back to it |
| `$FF` | end (NR51 = `$FF`; Sfx1/Sfx2 give their channel back to music) |

The break works with a counter armed by the first `$F9`: at the next `$FB n` the remaining passes and the exit address are stored, and each later `$F9` counts down. The vibrato, semitone and envelope tables all use one-byte steps with `$FB` / `$FB n` loops, `$FE` mark/jump and `$FF` end (envelope steps: time << 4 | volume).

In the data: notes, `$E0` (92 voices, 15 note-volume voices on tone tracks and 5 on wave tracks, 73 noise voices), `$E1–$E8`, `$EA 1x/2x/3x/4x/7x/8x/9x`, `$ED`, `$EE` (tempo), `$EF`, `$F0–$F8`, `$F9` (twice, in `$38`), `$FB`/`$FD`/`$FE`/`$FF`. **Not used:** vibrato, semitone tables, envelopes (no `$EC`; the one voice with volume 0, `$24`'s, selects envelope 0), the slide, `$EA A/B/C`, `$E9`, `$FA`, `$FC`.

### 3.3 Tables (bank 14)

| Addr | Name | Content |
|---|---|---|
| `$4000` | `SoundTable` | ids `$01–$42` (from `$3FFE`); headers `$4084–$41DF`, two unreferenced (`$412E`, `$41CC`) |
| `$41E0` | `WaveTable` | 15 waves at `$41FE` (from `$41DE`, the last header's pointer; wave = duty nibble) |
| `$42EE` | `PeriodTable` | 85 periods (from `$42D4`) |
| `$4398` | `VibratoTable` | 15 (from `$4396`) |
| `$4408` | `Vibrato2Table` | 12 semitone tables, then 4 entries pointing at `EnvelopeTable` (from `$4406`) |
| `$4485` | `EnvelopeTable` | 23 envelopes (from `$4483`) |
| `$453B` | drum hits | streams to `$465B` |
| `$4DA8` / `$4DEA` | `CommandTable` / `CommandTableVol` | `$E7–$FF`; the second (note-volume mode) differs only at `$EE` |
| `$4ECD` | `OctaveCodes` | `$18 $30 $48 $60 $78 $90` |
| `$4F0C` | `ExtTable` | `$EA x0–xC` |

Bank 15: `SoundTable15` `$4000` (ids `$51–$66`), headers `$402C–$40FD`, songs.

---

## 4. Sounds

Lengths in updates (59.7 Hz; music minus tempo skips).

| Ids | Bank | Prio | Tracks | Notes |
|---|---|---|---|---|
| `$01–$0C` | 14 | `$20` | SfxN (`$06–$08` + Sfx1) | drum hits, 2–13 ticks |
| `$0D` | 14 | `$FF` | Sfx1 + empty Sfx2/SfxN | an SFX that also stops the other SFX |
| `$0E–$16`, `$18–$3E` | 14 | `$90–$D0` | Sfx1, Sfx2 and/or SfxN | SFX, up to 768 ticks (`$3A`'s Sfx2 loops; `$24`'s Sfx1, §5.1); several start with an empty Sfx1 to cut it |
| `$17` | 14 | `$C0` | Ch1–Ch3 | a short jingle (90 ticks) |
| `$3F`, `$40` | 14 | `$F0` | empty SFX tracks | stop the SFX |
| `$41`, `$42` | 14 | `$40` | Ch1–Ch3 + Drm | two looping songs |
| `$51–$56`, `$58`, `$59`, `$5B`, `$5E–$65` | 15 | `$40` | Ch1–Ch3 + Drm | looping songs |
| `$57`, `$5A` | 15 | `$40` | Ch1–Ch3 + Drm, all on one `$FF` | stop the music |
| `$5C`, `$5D`, `$66` | 15 | `$40` | Ch1–Ch3 + Drm | tunes that end (384, ≈ 2040, ≈ 470 ticks) |

`python tools/kdata12.py -v` prints every id with its intro/loop lengths.

---

## 5. Quirks and bugs

1. **Id `$24` points Sfx1 and SfxN at the same bytes.** SfxN plays them as noise (192 ticks); Sfx1 reads `$E0 01 80 00` as a voice with volume 0 and envelope 0 and then the noise bytes as 191 notes – CH1 is held by a silent-volume Sfx1 for 1,616 updates, keeping music Ch1 off it.
2. **The slide reads its arguments from bank 14** (`ld a, [de]` instead of the buffer), so in a bank-15 stream it would take x, y and n from the wrong bank. No data uses the slide.
3. **The loop break skips a byte** when the `$FB n` that arms it is also the loop's last pass (n = 1); with an earlier pass it works as meant.
4. **Requests during `$EA Bx` are lost**: `PlaySound` stores them in `wHeldReq`, which nothing reads. A music start clears `wReqHold`. Unused by the data.
5. **The fade is dead code**: nothing reachable sets `wFadeRate` (§2.3). `FadeCheck` also returns early while music Ch3 is idle.
6. **The pause only mutes CH2**; music CH1/CH3 keep their last note, and the noise channel is left to the SFX.
7. **Drum rests write the joypad register** (`$FF00`), and **`TRK_MUTE` is dead** (as Raging Fighter).
8. **`$EA Dx–Fx` run past `ExtTable`** into the code; `Ext_Wobble` loads `wSndDim` and sets bit 0 in A without storing it.
9. **A track start doesn't set the unit**, and the loop/return pointers survive it (no data depends on either).
10. **Unused:** `StartFadeOut`, `StopAndFadeIn`, `StartFadeIn`, `SndDim`, `SndUndim` and `EndFadeIn` are never called; the vibrato, semitone and envelope tables; two unreferenced headers (`$412E`: Sfx1 + Sfx2, `$41CC`: Ch1–Ch3) and their streams; orphan streams in bank 14 (`$460F`, `$5705`, `$59E7`, `$5A72`, `$5AFF`, `$5B1A`, `$5BC3`, `$5BDE`) and bank 15 (`$4B3C`, `$7B3E`); id `$50` reads its header pointer from ROM0 `$3FFE`.

---

## 6. Verification

- **Byte-exact rebuild** of the ranges above.
- **Rate:** one update per VBlank.
- **Streams vs emulator** (`verify/vstream12.py`, as for Raging Fighter): every id of both banks alone for 4000 updates, the game's own requests dropped, the id injected through `PlaySoundFar` at update 100 (the game clears its RAM, the track pages too, around update 48). Every store of `TRK_LEN` (notes, rests, drum notes, noise bytes) is hooked; the stream address and length of each must equal the decoder's (`tools/kdata12.py`) in order, each lasting its length plus the tempo skips, and the tracks the decoder ends must end. This covers the note-volume mode, the loop break (`$38`) and `$24`'s double reading. **88 ids, 0 mismatches**, `TRK_MUTE` never set (`verify/run_stream_cvl.log`). A deliberately wrong note length in the decoder is caught.
- **Not verified:** the register writes (no update-by-update model), the volumes, vibrato and envelopes, the slide, the wobble, the fade and the pause were only read; nothing was checked on hardware.

## Files (in `GBAudioLab\Kon`)

- `CVL_SoundDriver.asm`: labelled, commented RGBDS source, byte-exact
- `tools/kdata12.py` (decoder), `tools/cfg_cvl.py`, shared `tools/gen_asm3.py`, `tools/gaps12.py`, `verify/vstream12.py`, `verify/run_stream_cvl.sh`, log

Regenerate: `python tools/gen_asm3.py cvl CVL_SoundDriver.asm`.
