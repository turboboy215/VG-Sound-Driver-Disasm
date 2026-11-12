# Zen: Intergalactic Ninja (GB): sound driver

ROM: `Zen - Intergalactic Ninja (E).gb` (DMG, MBC1, 128 KB, internal title `ZEN`). Konami, 1993 (Europe).

Part of the Konami family, see `Konami_SoundEngine_Family.md`. This is **Tiny Toon Adventures' reworked third-generation driver** (`TinyToon_SoundDriver.md`): about 1,410 of its 1,770 instructions line up with Tiny Toon's, the stream language is Tiny Toon's (generation 1–2 flow commands, the `$D0–$DF` block, `$EA` octave shift, `$E9` duty step, `$EC` envelopes, `$ED` detune, raw streams marked by `$01`), and so are the register shadows, the request groups and the track code. The changes:

- the track page moved **`$40` up** (tracks at `$C0C0 + n×$100`, fields `$C0–$FF`); the globals are at `$C7C3`, the shadows at `$C7DD`;
- **a 5-byte voice**: `$E0 unit, duty|vol, x, gate|env` on tone and wave tracks – the reader skips the fourth byte (0 in the data except once);
- a **pause** (the game's flag `$DEEB`: only Sfx1 runs, and only for the pause jingle `$09`) and a working **unpause** (Tiny Toon's unused `RestoreRegs`);
- a **new, simpler fade**: one level every 32 updates, taken off every note's volume (SFX too), and at level 5 a queued follow-up request – which never works as meant (§5.1);
- a refused track **no longer breaks the stack**: it sets `wReqRefused` and the groups abort as in Belmont's Revenge (with the same stale flag);
- `StopAll` clears whole pages, the octave-shift table has a 0 in entry 8, and the envelope table has a single (empty) entry; no data uses envelopes or raw streams.

| | |
|---|---|
| API | ROM0 `$0339` `PlaySoundFar` (A = id, 0 = stop all; 44 call sites, plus `$0369` `StopSoundFar`, 25), `$0351` `StartFadeFar` (1) → bank 7 `$4F21` `PlaySound`, `$4F2F` `StartFade`; `$505C` `SndMute` and `$5067` `SndUnpause` are called by the game's pause code |
| Game inputs | `wPauseFlag` `$DEEB` (any value pauses) |
| Tick | **VBlank**: the handler (`$0063`, both paths) calls `SndUpdateFar` `$0318` → bank 7 `$510D` `SndUpdate`, skipped while `wSndLock` `$DEE5` bit 0 is set (`PlaySoundFar` drops requests while it is set). Each bank holds its own number at `$7FFF`, which the wrappers use to map the caller's bank back |
| Driver code | ROM0 `$0000–$0002`, `$0008–$0014`, `$0028–$002C` (the game's `rst` helpers), `$0318–$036D`, `$0392–$0397`; bank 7 `$4F16–$5ABE` (3.0 KB, inline jump tables) |
| Data | bank 7 `$5ABF–$7F07`; `$4000–$4F15` is game code, `$7F08–$7FFE` is `$FF` |
| RAM | seven tracks at `$C0C0 + n×$100` (`$C0–$FF`), globals `$C7C3–$C7D4`, shadows `$C7DD–$C7F1` |
| Channels | Sfx1 (CH1), Sfx2 (CH2), SfxN (CH4), Ch1, Ch2, Ch3, Drm (drum notes = sound ids through a 14-entry map) |
| Counts | 110 ids `$01–$6E`: 8 drum hits, pause jingle `$09`, SFX and jingles `$0A–$60`, 14 songs `$61–$6E` |

`ZEN_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over the ROM0 ranges above and bank 7 `$4F16–$7F07`. It assembles cleanly with `-Wall`.

```
rgbasm -Wall -o zen.o ZEN_SoundDriver.asm
rgblink -o zen.gb zen.o
python tools/cmp_ranges.py zen.gb "Zen - Intergalactic Ninja (E).gb" 0:0000-0002 0:0008-0014 0:0028-002C 0:0318-036D 0:0392-0397 7:4F16-7F07
```

---

## 1. Structure

### 1.1 Tracks

| # | Page | Name | Channel |
|---|---|---|---|
| 0 | `$C0C0` | Sfx1 | CH1 |
| 1 | `$C1C0` | Sfx2 | CH2 |
| 2 | `$C2C0` | SfxN | CH4 |
| 3 | `$C3C0` | Ch1 | CH1 |
| 4 | `$C4C0` | Ch2 | CH2 |
| 5 | `$C5C0` | Ch3 | CH3 |
| 6 | `$C6C0` | Drm | – (plays sound ids) |

The register bases (`RegBaseTable` `00 05 0F 00 05 0A 0F`), the blocking (music Ch1 while Sfx1 plays, Ch2 while Sfx2 plays) and `WriteReg` with its shadows and force flag are Tiny Toon's.

### 1.2 Track fields

Tiny Toon's field at L is here at L + `$40`, all of them (`TRK_ID` `$C0` … `TRK_DETUNE` `$FF`); see `TinyToon_SoundDriver.md` §1.1. `TRK_FLAGS` `$C5`, `TRK_FLAGS2` `$C6`, `TRK_UNIT` `$D1`, `TRK_SEGNO` `$E2`, `TRK_RET` `$E6`, `TRK_PAN` `$FD`.

### 1.3 Globals

`wTrackIdx` `$C7C3`, `wRegBase` `$C7C4`, `wTempo`/`wTempoAcc`/`wTempoSkip` `$C7C5–$C7C7`, `wQueuedSnd` `$C7C8`, `wNR51` `$C7C9`, `wReqId`/`wReqPrio` `$C7CB/C`, `wRegVal`/`wRegOff` `$C7CD/E`, `wMusicHold` `$C7CF` (never set), `wCountdown` `$C7D0`, `wFadeReq` `$C7D1`, `wFadeTimer` `$C7D2`, `wFadeLevel` `$C7D3`, `wReqRefused` `$C7D4`, `wRegShadow` `$C7DD–$C7F1`. Tiny Toon's countdown word (`$C791/2`, which nothing set) became `$C7D0/1` and now **overlaps `wFadeReq`** (§5.1).

---

## 2. Timing

### 2.1 Update

Once per VBlank: `FadeTick`, `CountdownTick`, `TempoTick`, then tracks 0–6 (each only if its id is set), then `wQueuedSnd`. While `wPauseFlag` is set the fade is skipped and only Sfx1 runs, and only while it plays `$09`. A tempo carry (or `wMusicHold`) skips tracks 3–6 for the update. The second test for track 4 (`$5143`) is dead, as in Tiny Toon.

### 2.2 Tempo

As Tiny Toon. Tempos in the data: `$00`, `$10`, `$20`, `$50`.

### 2.3 Fade

`StartFade` sets `wFadeReq` = A | `$80`. While it is set, every 32 updates `wFadeLevel` goes up by one; `CalcVolume` takes it off the volume of **every** new note (Tiny Toon: music only; CH3 gets half). At level 5 the fade ends: `wQueuedSnd` = `wFadeReq` (with `StopAll` for a request below 2, which bit 7 rules out), level and request 0; the queued id is requested at the end of the same update. See §5.1 for what actually happens.

### 2.4 Requests

`PlaySoundA` (`$4F35`), id in A: 0 → `StopAll`. Else the header from `SoundTable − 2 + 2 × id` (no range check): priority, mask, pointers. Sfx1 starts first; if `wReqRefused` is set it is cleared and the request ends; then Sfx2 and SfxN, the same test; then the music tracks; then NR51 = `wNR51`. A start ORs the channel's NR51 bits in (before the priority test; Sfx1, and Ch1 while Sfx1 is idle, also write NR10 = 8) and is made when the priority is ≥ the track's: ID, PRIO, PTR, LEN 1, FLAGS = `$40`, `$C6–$D0` = 0, the raw bits if the stream starts with `$01`. **Every start sets `wReqRefused` to 0 or 1**, so only the last track of a group counts at the checks, and a refused last track leaves it set for the next request (§5.3). Unlike Tiny Toon a refusal returns normally.

Drum notes play `DrumMap[hi − 1]` (`01 02 07 02 01 02 01 03 04 05 06 08`, plus two unreachable bytes) as ordinary requests.

### 2.5 Pause

The game's pause code (`$0425`) sets its flags, calls `SndMute` (NR12, NR17, NR21, NR32 = 0) and plays `$09`; the unpause (`$046F`) jumps to `SndUnpause`, which – unless `wPauseFlag` or `wMusicHold` is set – copies the shadows back to the registers of every channel with a playing track (CH1 five registers, CH2 four, CH3 five, CH4 four), without a trigger. This is Tiny Toon's `RestoreRegs`, which nothing called there.

---

## 3. Data format

Tiny Toon's (`TinyToon_SoundDriver.md` §3), except:

| Byte | Meaning |
|---|---|
| `$E0` | tone/wave tracks: `VOICE unit, duty<<4|vol, x, gate<<4|env` – **5 bytes, x skipped** (always 0 except one `$0F`); SfxN: `unit, vol<<4|env` (3 bytes); Drm: unit only |
| `$EA xy` | octave shift x through `OctaveShiftTable` `00 0C 18 24 30 3C 48 54 00 F4 E8 DC D0 C4 B8 AC`: 0–7 up, **8 none**, 9–15 down 1–7 octaves (Tiny Toon: 8–15 down 1–8); semitones y, negated for x ≥ 8 |
| `$EC n` | envelope n & 15 from a one-entry table (entry 1 = an empty envelope, 2–15 would read the period table); unused |

Everything else – notes (`lo` 0 = 256), the noise bytes (NR43 without a retrigger), `$D0–$DF`, `$E1–$E9`, `$EB n xy`, `$ED`, `$EE`, `$EF`, `$F0–$FA`, `$FB` segno, `$FC` return, `$FD` call, `$FE n` / `$FE $FF addr`, `$FF`, the raw streams – is unchanged. A track start leaves `TRK_UNIT`, `TRK_SEGNO` and `TRK_RET` alone.

Used by the data: `$D1` (no-op), `$DA 0x/1x/3x/4x` (transposes, duty/wave, autopan flags), `$DF` pan, `$E9` duty step, `$EA` (4 times), `$EB` vibrato (tables 1, 4, 5, 6, 11), `$ED` detune; not used: raw streams, envelopes, `$D0`, `$D2–$D9`, `$DB–$DE`, `$EF`.

### 3.1 Tables (bank 7)

| Addr | Name | Content |
|---|---|---|
| `$56BC` | `OctaveShiftTable` | in the code, see above |
| `$592C` | `RegBaseTable` | in the code |
| `$5ABF` | `SoundTable` | ids `$01–$6E` (the code adds 2 × id to `$5ABD`, the last code bytes); headers `$5B9B–$5DFA` (drum hits at `$5F44`) |
| `$5DFB` | `EnvelopeTable` | 1 entry → `$5DFD` (`$FF`) |
| `$5DFE` | `PeriodTable` | 85 periods, the same as Tiny Toon's |
| `$5EA8` | `WaveTable` | 15 pointers (duty − 1), 7 waves `$5EC6–$5F35`; entries 11–15 point at the drum map |
| `$5F36` | `DrumMap` | 14 bytes, 12 reachable |
| `$5F9F` | `VibratoTable` | 15 pointers, steps `$5FBD–$5FEE` |

---

## 4. Sounds

Lengths in updates (59.7 Hz; music minus tempo skips).

| Ids | Prio | Tracks | Notes |
|---|---|---|---|
| `$01–$08` | `$00` | SfxN (`$04`, `$05` + Sfx1) | drum hits, 1–19 ticks |
| `$09` | `$80` | Sfx1 | pause jingle, 42 |
| `$0A–$57`, `$5A–$5C` | `$29–$50` | Sfx1, Sfx2 and/or SfxN | SFX, up to 960 ticks; `$0F` loops |
| `$1E`, `$2A`, `$2B`, `$30`, `$31`, `$58`, `$59`, `$5D–$60` | `$30–$45` | music channels (some with Sfx1/Sfx2/SfxN) | jingles that end, up to 515 ticks |
| `$61–$6E` | `$40` | Ch1–Ch3 + Drm | the songs, all looping (`$6C`'s drum track is empty) |

`python tools/kdata11.py zen -v` prints every id with its intro/loop lengths.

---

## 5. Quirks and bugs

1. **The fade's follow-up plays garbage.** The game starts the one fade in its code with A = `$6A` (song `$6A`), so `wFadeReq` = `$EA`. `CountdownTick` then treats `$C7D0/$C7D1` as one word and counts it down, so the request is `$E9` from the first update on (and drops by one every 256). After 160 updates `$E9` is requested: its `SoundTable` entry is a word inside the header area, pointing at bytes of SFX `$33`, which read as priority `$E0`, Ch2 + Ch3, with pointers into nowhere – Ch2 and Ch3 start playing junk at priority `$E0`, and the fade level is back at 0. In the game this never shows: the same countdown that starts the fade (106 frames before the end) stops all sound before the fade ends, so the fade only gets three levels down. (Checked in PyBoy by starting the fade by hand.)
2. **Song `$68`'s header has one pointer too few**: its mask `$78` asks for four tracks, but the fourth pointer is the first word of `$69`'s header (`40 78` → `$7840`). The drum track reads one drum note from the middle of `$66`'s Ch2 data and then a bare `$FC` (return) with no call, which goes to whatever `TRK_RET` an earlier sound left in the drum page (`$0000` after `StopAll` or boot: the drum track then plays ROM0 code).
3. **The stale refusal flag**: a refused last track (SfxN, Ch3 or Drm) leaves `wReqRefused` = 1, and the next request without an Sfx1 part is cut at its first check (as Belmont's Revenge and Nemesis II).
4. **The fade comes off SFX too** (`CalcVolume` lost Tiny Toon's music test), and the follow-up test `cp 2` can never succeed because `StartFade` sets bit 7.
5. **A track start doesn't set the unit**: a stream that plays a note before its first voice or `$E7` uses the unit left by the previous sound on that track (0 after `StopAll`/boot, so the note lasts 256 ticks). Only `$68`'s stray drum track (2.) does this.
6. From Tiny Toon, unchanged: the lagging vibrato index after a finished `$FE n` repeat, raw streams crashing on `$E8`/`$EB–$ED`, CH3 switched off between notes, noise notes without a retrigger, the octave shift skipped at octave 1, `Flow_End` giving back only the duty and period, `$DA` with x ≥ 5 running past its table, `$DF` on the drum track skipping a byte.
7. **Unused / dead:** `SndInit` (`$4F16`) and `StopSound` (`$4F27`) are never called, `wMusicHold`, the track-4 tempo test, raw streams, envelopes, the wave table entries 11–15, two unreachable drum map bytes, orphan streams at `$63D4` (Sfx1) and `$63EE` (SfxN), unreachable bytes at `$5FED`, `$6820` and `$72CA` (a call after a jump), and a few `$FF` bytes after ends.

---

## 6. Verification

- **Byte-exact rebuild** of the ranges above.
- **Rate:** one update per VBlank.
- **Streams vs emulator** (`verify/vstream11.py`, the lighter method of Batman / Raging Fighter / Hyper Dunk): every id alone for 4000 updates, the game's own requests and fades dropped, the id injected into bank-7 `PlaySound` from the VBlank glue. Every store of `TRK_LEN` for a note, noise byte, raw frame and raw rest is hooked; the stream address and length of each must equal the decoder's (`tools/kdata11.py`) in order, each lasting its length plus the music skips, and the tracks the decoder ends must end. The game clears all its RAM about 1,830 updates after the request (its attract loop restarts), so the driver's RAM is saved after every update and put back when something else changed it. `$68`'s drum track is compared up to its stray return. **110 ids, 30,327 reads, 0 mismatches** (`verify/run_stream_zen.log`). A deliberately wrong note length in the decoder is caught.
- **The fade path** (§5.1) was run once by hand in PyBoy: `wFadeReq` `$EA` → `$E9`, level 5 after 160 updates, Ch2/Ch3 taken by id `$E9` at priority `$E0`.
- **Not verified:** the register writes (no update-by-update model), the vibrato and volume values, the pause; nothing was checked on hardware.

## Files (in `GBAudioLab\Kon`)

- `ZEN_SoundDriver.asm`: labelled, commented RGBDS source, byte-exact
- `tools/kdata11.py` (decoder; Tiny Toon's `kdata6.py` with the 5-byte voice), `tools/cfg_zen.py`, shared `tools/gen_asm3.py` (now handles a header that runs into the next one), `tools/gaps11.py`, `verify/vstream11.py`, `verify/run_stream_zen.sh`, log

Regenerate: `python tools/gen_asm3.py zen ZEN_SoundDriver.asm`.
