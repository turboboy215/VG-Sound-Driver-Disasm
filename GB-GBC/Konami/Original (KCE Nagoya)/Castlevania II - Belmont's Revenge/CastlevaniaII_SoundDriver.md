# Castlevania II: Belmont's Revenge (GB): sound driver

ROM: `Castlevania II - Belmont's Revenge (U) [!].gb` (DMG, MBC1, 128 KB, internal title `CASTLEVANIA2 BEL`). Konami, 1991.

Part of the Konami family, see `Konami_SoundEngine_Family.md`. This is the **later variant**, as in Nemesis, with further changes: it runs from **VBlank** instead of the timer, tracks are larger, `PAN` stores raw NR51 bits per track, a new `$ED` duty-step command, and a request is aborted part-way when a track refuses it.

| | |
|---|---|
| API | bank 7 `$4018` `SndInit`, `$40CF` `PlaySound` (A = id, 0 = stop all; keeps DE), `$40D5` `StopSound`, `$40DD` `StartFade` (A = sound to start afterwards), `$4251` `SndPause`, `$425C` `SndUnpause`. ROM0 `$3553` `PlaySoundFar`, `$358D` `StartFadeFar`, `$35A4` `StopSoundFar`, `$356A` `PlayStageMusic` (game) |
| Game inputs | `wPauseFlags` `$C88B` bit 0 |
| Tick | **VBlank**, 59.73 Hz: the VBlank handler calls `SndUpdateFar` (`$3537`) after `ei` on every frame (PyBoy: 6000 updates in 6000 frames) → bank 7 `$42F6` `SndUpdate` |
| Music rate | 59.73 Hz × (1 − tempo/256) |
| Driver code | bank 7 `$4000–$4024`, `$40CF–$498B` (2.3 KB) + ROM0 glue `$3537–$35C6` |
| Tables + data | bank 7 `$4025–$40CE`, `$498C–$7FF2` (13.9 KB), `$FF` pad and the bank number at `$7FFF` |
| RAM | seven tracks at `$C080 + n×$100` (`$80–$B5`), globals `$C0B9–$C0CB`, shadows `$C1B6–$C1C9`; lock `$C885` |
| Channels | Sfx1 (CH1), Sfx2 (CH2), SfxN (CH4), Ch1, Ch2, Ch3, Drm (drums = sound ids `$01–$05` through a 13-entry map) |
| Counts | 107 sound ids (`$01–$6B`): 5 drum hits, SFX/jingles `$06–$53`, music `$54–$6B` |

`CV2_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over ROM0 `$0028–$002C`, `$3537–$35C6` and bank 7 `$4000–$7FFF`. It assembles cleanly with `-Wall`.

```
rgbasm -Wall -o cv2.o CV2_SoundDriver.asm
rgblink -o cv2.gb cv2.o
python tools/cmp_ranges.py cv2.gb "Castlevania II - Belmont's Revenge (U) [!].gb" 0:0028-002C 0:3537-35C6 7:4000-7FFF
```

---

## 1. Structure

Tracks are processed in place. Track n's page is `H = $C0 + n`, fields at `L = $80–$B5`. Offsets `$80–$A3` are the same as in MM and Nemesis; new are:

| L | Name | Use |
|---|---|---|
| `$A4` | TRK_DUTYCNT | ticks since the note started (duty step) |
| `$A5` / `$A6` | TRK_DUTYSTEP / TRK_DUTYTICKS | duty for the start of each note, and for how many ticks |
| `$B5` | TRK_PAN | this track's NR51 byte (§3) |

`$A7–$B4` are unused, but `StopAll` clears the whole `$37`-byte area.

| # | Page | Name | Channel (reg base) | NR51 at start | PAN bits |
|---|---|---|---|---|---|
| 0 | `$C080` | Sfx1 | CH1 (`$00`) | `$11` | `$11` |
| 1 | `$C180` | Sfx2 | CH2 (`$05`) | `$22` | `$22` |
| 2 | `$C280` | SfxN | CH4 (`$0F`) | `$88` | `$88` |
| 3 | `$C380` | Ch1 | CH1 (`$00`) | `$11` | `$11` |
| 4 | `$C480` | Ch2 | CH2 (`$05`) | `$22` | `$22` |
| 5 | `$C580` | Ch3 | CH3 (`$0A`) | `$44` | `$44` |
| 6 | `$C680` | Drm | – (plays sounds) | – | (skipped) |

Ch1 is muted while Sfx1 plays and Ch2 while Sfx2 plays (`IsBlocked`), and now that also covers `PAN` on both music channels.

### 1.1 Globals

| Addr | Name | Use |
|---|---|---|
| `$C0B9` / `$C0BA` | wTrackIdx / wRegBase | |
| `$C0BB` / `$C0BC` / `$C0BD` | wTempo / wTempoAcc / wTempoSkip | |
| `$C0BE` | wQueuedSnd | fade target, started at the end of `SndUpdate` |
| `$C0BF` | wNR51 | |
| `$C0C0` | wSweepVal | write-only |
| `$C0C1` / `$C0C2` | wReqId / wReqPrio | |
| `$C0C3` / `$C0C4` | wRegVal / wRegIdx | |
| `$C0C5` | wMusicHold | read, never written |
| `$C0C8` / `$C0C9` / `$C0CA` | wFadeReq / wFadeTimer / wFadeLevel | §2.3 |
| `$C0CB` | wReqRefused | §2.4 |

---

## 2. Timing

### 2.1 Glue (ROM0)

`SndUpdateFar` (`$3537`) and `PlaySoundFar` (`$3553`) share `wSndLock` (`$C885`). The update is **skipped** (tick lost) while the main thread is inside `PlaySoundFar`, and `PlaySoundFar` **drops** a request if the lock is already held (a request from an interrupt during the update). Both map bank 7 and restore the caller's bank from `$7FFF`, where every bank stores its number.

### 2.2 Update order and tempo

`FadeTick`, `TempoTick`, then the tracks: 0–2 always, and the loop stops before track 3 when `wTempoSkip` (or `wMusicHold`) is set. Last, `wQueuedSnd` is started. There's no lockout and no follow-up queue any more.

Tempos in the data: `$00`, `$10`, `$20`, `$25`, `$30`, `$37`, `$40`, `$4A`, `$50`, `$5A`, `$60`, `$70`, `$80`, `$90`.

### 2.3 Fade-out

`StartFade` sets `wFadeReq` = A | `$80`. While bit 7 is set (and not paused), `wFadeLevel` goes up by one every **32** ticks, and new notes are that much quieter (CH3: half), as in Nemesis. At level 5 (160 ticks, 2.7 s) bits 0–6 are queued and the fade is cleared. There's no stop path: **with target 0 nothing is queued, and the music carries on at full volume** unless the game stops it.

### 2.4 Requests

The mask bits are handled in three groups: Sfx1; Sfx2 and SfxN; then Ch1, Ch2, Ch3, Drm. `StartTrack` sets `wReqRefused` = 1 when the priority test fails and 0 when it passes. After the first and the second group, a set flag **aborts the rest of the request**, including the NR51 write (the NR51 bits of the tracks so far are already in `wNR51`), and clears the flag.

The flag is never cleared at the start of a request. So when the last track of one request is refused (for example `$2A` or `$31`, whose empty Ch3 track meets music of priority `$40`), **the next request aborts at its first check** unless it contains an Sfx1 track that's accepted. Drum hits are requests too, so during music the victim is usually the next drum hit; otherwise a music request or an SfxN-only sound is dropped.

NR10 = 8 is written for every Sfx1 request, and for Ch1 when Sfx1 is idle, before the priority test (as before).

### 2.5 Pause

The game's pause code (`$09C0`) calls `SndPause` (NR12/NR17/NR21/NR1C = 0) and plays `$06`. While `wPauseFlags` bit 0 is set only track 1 runs, and only for `$06`. The unpause code (`$0A1F`) clears the flag and jumps to `SndUnpause`, which copies the shadows back for each channel with an active track (CH4 for any SfxN sound, drums included), without retriggering.

---

## 3. Data format

The command language is Nemesis' (see the Nemesis and CVA docs), with these changes:

| Byte | Nemesis | Belmont's Revenge |
|---|---|---|
| `$ED xy` | no-op | `DUTY_STEP y, x`: each note starts with duty y for x ticks, then the voice duty is written again. `ED 00` turns it off. Not applied on CH3 at note start |
| `$EF x` | NR51 bits = swap(x) | **TRK_PAN = x**, raw NR51 bits; this track's bits of x are copied into NR51 (dropped while blocked). On the drum track the command is skipped, but it skips one byte too many |
| `EA 4n` | stores n \| 2 in the flags | the same, and the data uses it: `EA 42` (autopan on) and `EA 40`. It also clears the duty step, the force flag and the release/rest flags |
| autopan | swap NR51 halves of this channel | swap TRK_PAN's nibbles, then apply it as `PAN` (not on the noise SFX track) |

Everything else (notes, `$E0` voices, octaves, `$E7–$E9`, `EA 0n–3n`, `$EE`, `$F0–$FA`, flow, vibrato tables) is unchanged. Rests write NRx2 = 0 only, and a release with env 0 retriggers at the same volume (one stream uses it: Sfx1 of `$13`, `VOICE 1, 13, 4, 0, 15`, so its notes retrigger one tick before they end).

### 3.1 Tables

| Addr | Name | Content |
|---|---|---|
| `$4025` | `PeriodTable` | **85** periods: the same values, cut after C of the top octave (index 84). Indices outside it read code (§5) |
| `$45EE` | (inline) | per-track `PAN` bit routines |
| `$498C` | `RegBaseTable` | `00 05 0F 00 05 0A 0F` |
| `$4993` | `WaveTable` | 12 pointers to 6 waves (`$49AB–$4A0A`): 1/2, 3/4, 5/6, 7/8 share, 9, 10–12 share |
| `$4A0B` | `VibratoTable` | 15 pointers (several shared) → `$4A29–$4A7A`. All offsets positive, including a 0/+31 trill (`Vib01`) |
| `$4A7B` | `SoundTable` | 107 pointers (the code loads `SoundTable − 2`) |
| `$4B51–$4DC2`, `$4DD0–$4DE3` | headers | |
| `$4DC3` | `DrumMap` | `01 02 05 02 01 02 01 03 04 04 04 04 04` |
| `$4DE4–$7FF2` | streams | |

---

## 4. Sounds

Lengths in ticks (59.73 Hz for SFX tracks, the §2.2 rate for music). "a+b" = intro + loop period.

| Id | Prio | Tracks | Length |
|---|---|---|---|
| `$01`–`$05` | `$01` | SfxN | 1, 1, 3, 2, 1 (drum hits) |
| `$06` | `$80` | Sfx2 | 48 (pause jingle) |
| `$07`–`$52` | `$30`–`$39` | Sfx1, SfxN, or both; a few with Sfx2 | 2–160 mostly |
| `$0F` | `$30` | Ch1–Ch3, all empty | 0 (stops music of priority ≤ `$30`) |
| `$22`, `$25`, `$4E`, `$50` / `$26`, `$2F`, `$46`, `$4C`, `$4D` | `$30`–`$36` | Sfx1 / SfxN, empty | 0 (they cut a running SFX of lower or equal priority) |
| `$2A` | `$35` | Sfx1 + Sfx2 + Ch3 (empty) | 160 / 172 / 0 |
| `$31` | `$30` | Sfx1 + Sfx2 + Ch3 (empty) | looping: 42252+38400 / 3852+38400 |
| `$4A` | `$30` | Sfx1 + Sfx2 + SfxN | 400 / 406 / 612 |
| `$4F` | `$30` | Sfx1 | 3840 |
| `$11` | `$38` | Ch1–Ch3 | 90 / 45 / 42 |
| `$53` | `$30` | Ch1–Ch3 | 130 / 110 / 130 |
| `$54`, `$57`, `$59`, `$5A`, `$66` | `$40` | Ch1–Ch3 (+ Drm) | 312, 288 (Drm 540), 192, 192, 4336 / 4320 / 4128: end |
| `$55`, `$56`, `$58`, `$5B`–`$65`, `$67`–`$6B` | `$40` | Ch1–Ch3 + Drm | looping, periods 360–7680 ticks |

The full per-id list (prio, mask, stream addresses) is in the asm, and the intro/loop lengths per track can be printed with `tools/kdata.py`. `PlayStageMusic` (`$356A`) maps the stage number to `$56 $56 $5B $5C $60 $62 $5D $67`.

---

## 5. Quirks and bugs

1. **Stale refusal flag** (§2.4): a refused last track makes the next request abort.
2. **Aborted requests skip the NR51 write**, but their NR51 bits are already in `wNR51` and appear with the next request.
3. **NR51/NR10 are set even when the priority test fails** (as before).
4. **Fade to 0 doesn't silence anything** (§2.3).
5. **`EA 4n` overwrites the flags byte**, so `EA 42`/`EA 40` also cancel a duty step set earlier in the stream.
6. **`PAN` on the drum track skips an extra byte** (not in the data).
6a. **Notes below the period table.** Ch1/Ch2 of `$62` (one note each) and Ch2 of `$64` (seven notes) play `OCTAVE 1` notes under `TRANSPOSE_DOWN 12`, so the index wraps to 244–255 and the period comes from `StopAll`'s code at `$420D–$4224`: `$036` (65.7 Hz, close to the bottom C, so the note sounds an octave higher than written), `$0CD`, `$140`, and for index 255 `$C680`, whose high byte `$C6` goes to NR24 with bit 6 set, so the length counter cuts that note after 1/4 s. Nemesis stays inside its table (highest index 78).
7. **Release with env 0 retriggers** instead of cutting (Sfx1 of `$13`).
8. **CH3 decay counts the attenuation twice** (as Nemesis).
9. **`StopAll` sets wNR51 = `$FF` without writing NR51.**
10. **Ticks lost / requests dropped** around `wSndLock` (§2.1).
11. **One return slot** and **persistent fields above `$8C`** (as before).
12. **Dead code/data:** `wMusicHold`, `wSweepVal`, the `push af` / `pop af` pair and the double `wReqId` store at `$40EA–$40EF`, an extra `$FF` after jumps at `$5234`, `$537A`, `$599B`, `$6497`, `$7D0C`, an unreachable `$FF` in the vibrato data at `$4A30`, an orphan noise stream at `$5412–$5423`, an orphan `SND_CALL` at `$6C4D`.

---

## 6. Verification

- **Byte-exact rebuild** of all three ranges.
- **Rate:** one update per VBlank in the attract loop (6000/6000 frames).
- **Model vs emulator** (`verify/vmodel2.py`, `tools/kmodel2.py`, same method as Nemesis: all seven tracks byte for byte including the new fields and TRK_PAN, shadows, every global including `wReqRefused`, NR51, wave RAM, triggers per tick; the game's own requests dropped):
  - each of the 107 ids alone for 7000 ticks: **0 mismatches**;
  - two mixed 9000-tick scenarios: both blocking paths and restores, three SFX tracks at once, a refused request (`$0F` against music) followed by an aborted one (the next drum hit), the refusal left by `$2A` cleared by an accepted Sfx1, pause with `$06`, a fade to `$55` and a fade to 0, `StopAll`, looping SFX `$31`, songs with duty steps and autopan: **0 mismatches**.
- **Not verified:** `SndPause`/`SndUnpause` and the game's own fade calls were only read (the tests poke `wPauseFlags` and `wFadeReq`). Nothing was checked on hardware or against audio output.

## Files (in `GBAudioLab\Kon`)

- `CV2_SoundDriver.asm`: labelled, commented RGBDS source, byte-exact
- `tools/cfg_cv2.py`, shared `tools/kmodel2.py`, `verify/vmodel2.py`, `verify/run_all2.sh`, `verify/run_combo2.sh`, logs

Regenerate: `python tools/gen_asm.py cv2 CV2_SoundDriver.asm`.
