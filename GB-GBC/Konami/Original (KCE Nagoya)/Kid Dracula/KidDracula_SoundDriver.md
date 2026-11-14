# Kid Dracula (GB): sound driver

ROM: `Kid Dracula (U) [!].gb` (MBC1, 256 KB, internal title `KID DRACULA`). Konami, 1993.

Part of the Konami family, see `Konami_SoundEngine_Family.md`. This is **Tiny Toon Adventures' reworked third-generation driver** (`TinyToon_SoundDriver.md`): about 1,340 of its 1,690 instructions line up with Tiny Toon's (1,020 with Zen's). The code is laid out as in Tiny Toon (helpers at `$4000`, `PlaySound` near the end), but the track pages, globals, pause and request flag are **Zen's** (`Zen_SoundDriver.md`), and it adds a second sound bank:

- **every header carries a stream bank** (`db priority, bank, mask`); sounds with id **`≥ $7F`** read every stream byte through a ROM0 **`FarRead`** that maps that bank (bank 15 for songs `$7F–$8F`); ids below read bank 14 directly. A `cp $7F` on `TRK_ID` precedes every read, but most command arguments go through `FarRead` whatever the id (all headers below `$7F` name bank 14, so that's harmless);
- **no volume envelopes and no raw streams**: `$EC x`, `$EA x` (Tiny Toon: octave shift + transpose) and `$D9 x` are 2-byte no-ops; the envelope fields are left over (cleared, tested, never set);
- tracks at **`$C0C0 + n×$100`** (Zen's place) with one field fewer than Zen's from `TRK_UNIT` on, globals at `$C7C3`, shadows at `$C7DF`;
- Zen's **pause** (`wPauseFlag` `$C9CB`: only Sfx1 runs, and only while it plays `$08`, `$0D` or `$1A`), `SndMute`/`SndUnpause`, and Zen's handling of a refused track (the flag is set and the request goes on, so a refused last track cuts the next request);
- a **fade** of one level per 3 updates whose only live stop is the drums (Tiny Toon's stack bug included, §5).

| | |
|---|---|
| API | ROM0 `$2C0F` `PlaySoundFar` (A = id, 0 = stop all; dropped while `wSndLock` `$C9C5` bit 0 is set) → bank 14 `$49D8` `PlaySound`; `$2C29` `StartFadeFar`; `$2C4D` `StopSoundFar` |
| Game inputs | `wPauseFlag` `$C9CB` bit 0 (set by the game's pause code at `$0460`/`$0361`, which also calls `SndMute` `$4BAC`; its unpause calls `SndUnpause` `$4BC9`) |
| Tick | **VBlank**: `SndUpdateFar` `$2BED` → bank 14 `SndUpdate` `$40CE` |
| Driver code | ROM0 `$0000–$002C` (rst helpers), `$2BED–$2C51`, `$3FE8–$3FF9` (`FarRead`); bank 14 `$4000–$4C20` (3.1 KB, inline jump tables after `rst $00`) |
| Data | bank 14 `$4C21–$7BFA` (tables, headers, SFX, songs `$73–$7E`); bank 15 `$4000–$5875` (songs `$7F–$8F`) |
| RAM | WRAM `$C0C0–$C6FF` (7 track pages), `$C7C3–$C7F3` |
| Counts | 143 ids: SFX `$01–$72`, songs `$73–$8F` (29); 7 drum hits, 11 vibrato tables, 15 wave pointers (13 waves), 85 periods |

`KD_SoundDriver.asm` rebuilds **byte-exact** with RGBDS over ROM0 `$0000–$0002`, `$0008–$000F`, `$0013–$0017`, `$0028–$002C`, `$2BED–$2C40`, `$2C4D–$2C51`, `$3FE8–$3FF9`, bank 14 `$4000–$7BFA` and bank 15 `$4000–$5875`, and assembles cleanly with `-Wall`:

```
rgbasm -Wall -o kd.o KD_SoundDriver.asm
rgblink -o kd.gb kd.o
```

---

## 1. Structure

### 1.1 Tracks

Seven tracks, Tiny Toon's roles and order: Sfx1 (CH1), Sfx2 (CH2), SfxN (CH4), Ch1, Ch2, Ch3, Drm, page `$C0+n`, fields `$C0–$FA`. Register base per track `00 05 0F 00 05 0A 0F` (`RegBaseTable`); every register write goes through `WriteReg` (blocked for music Ch1 while Sfx1 plays and music Ch2 while Sfx2 plays; skipped when equal to its shadow unless the force flag is set).

### 1.2 Track fields

Zen's field set moved down one byte from `TRK_UNIT` (`$D0`) on, with the envelope block shortened:

| Field | Offset | | Field | Offset |
|---|---|---|---|---|
| `TRK_ID`, `TRK_PRIO`, `TRK_PTR` | `$C0`, `$C1`, `$C2` | | `TRK_LEVEL` | `$E0` |
| `TRK_LEN`, `TRK_FLAGS`, `TRK_FLAGS2` | `$C4–$C6` | | `TRK_SEGNO`, `TRK_RET` | `$E1`, `$E5` |
| `TRK_REPCNT`, `TRK_VIB`, `TRK_TRANSP`, `TRK_ATTEN` | `$C7`, `$C9–$CB` | | vibrato pointer/index/depth/delay | `$E9–$F0` |
| `TRK_VIBOFS`, `TRK_VIBREPCNT` | `$CC`, `$CE` | | `TRK_ENVNO`, `TRK_ENVVOL` (leftovers) | `$F1`, `$F2` |
| `TRK_UNIT`, `TRK_OCTAVE`, `TRK_PERIOD` | `$D0`, `$D1`, `$D2` | | **`TRK_BANK`** | `$F3` |
| `TRK_VOL`, `TRK_DUTY`, `TRK_ENV`, `TRK_GATE`, `TRK_RELTICK` | `$D6–$DA` | | duty step, `TRK_PAN`, `TRK_OCTSHIFT`, `TRK_DETUNE` | `$F5–$FA` |
| vibrato timer, CH3 decay timer | `$DB–$DE` | | | |

`StartTrack` clears `$C6–$D0` – the unit included (Tiny Toon kept it), so a track that plays a note before its voice uses a unit of 0 (= 256 ticks per length step).

### 1.3 Globals

`$C7C3` `wTrackIdx`, `$C7C4` `wRegBase`, `$C7C5` `wTempo`, `$C7C6` `wTempoAcc`, `$C7C7` `wTempoSkip`, `$C7C8` `wQueuedSnd` (never set), `$C7C9` `wNR51`, `$C7CB` `wReqId`, `$C7CC` `wReqPrio`, `$C7CD`/`$C7CE` `wRegVal`/`wRegOff`, `$C7CF` `wMusicHold` (never set), `$C7D0` `wCountdown` (a word whose high byte is `wFadeReq` `$C7D1`), `$C7D2` `wFadeStep`, `$C7D3` `wFadeLevel`, `$C7D4` `wReqRefused`, `$C7DD` `wFadeDiv`, `$C7DE` `wReqBank`, `$C7DF–$C7F3` register shadows.

---

## 2. Timing

### 2.1 Update

Once per VBlank (skipped while a request is in progress): `FadeTick`, `CountdownTick`, `TempoTick`, then tracks 0–6. While paused only track 0 runs, and only if it plays `$08`, `$0D` or `$1A`; any other id ends the update. On a tempo carry the loop ends at track 3, so all four music tracks skip the frame (the test meant for track 4, `UpdateCheckCh2`, is unreachable). Each track: `LEN − 1`; at 0 the commands are read (Ch3: NR30 = 0 first); else duty step, release flag and, on a note of a tone or wave track, the vibrato, then the CH3 decay or the release write.

### 2.2 Tempo

`wTempoAcc += wTempo`; a carry skips the music for one update. Tempos in the data: `$00`, `$10`, `$20`, `$24`, `$25`, `$30`, `$40`, `$45`, `$50`, `$60`.

### 2.3 Fade

`StartFade` (A | `$80` to `wFadeReq`). While it is set, every 3 updates `wFadeLevel + 1` (taken off every music note's volume, half of it on CH3, with no upper limit) and `wFadeStep + 1`. At step `$30` the drum track stops – through `Flow_End` when SfxN is idle (§5.1), else by clearing its id and priority. The stops for Ch3 and Ch1/Ch2 test the same step after the routine has already returned: dead. Without a request the three fade variables are cleared on every update. The fade request is also counted down by `CountdownTick` every 256 updates (the word at `$C7D0` overlaps it, as in Zen).

### 2.4 Requests

| Id | Action |
|---|---|
| 0 | `StopAll` (clears `$C0–$FA` of every page, the globals and the shadows; `SndMute`) |
| `$01–$7E` | header from `SoundTable` (bank 14); streams read from bank 14 |
| `$7F–$8F` | header from `SoundTable` (bank 14); streams read through `FarRead` from the header's bank (15) |

Order: Sfx1, then (unless `wReqRefused`) Sfx2 and SfxN, then (unless `wReqRefused`) the music tracks, then NR51 = `wNR51`. A track starts when the new priority is ≥ its current one; each start sets `wReqRefused` to 1 (refused) or 0, and a set flag ends the request at the next check and is cleared there – so a refused last track leaves it set and cuts the next request that has no Sfx1 part (Zen's behaviour; Tiny Toon jumped out of `PlaySound` instead). SfxN only claims the CH4 bits of NR51 when it wins the priority test.

### 2.5 Pause

The game's pause sets `wPauseFlag` bit 0 and calls `SndMute` (NR12 = 0 unless the last request was `$0D` or `$1A`, then NR17, NR21, NR32 = 0); its unpause clears the flag and calls `SndUnpause` (the shadows copied back to the registers of every channel with a playing track, without a trigger).

---

## 3. Data format

Tiny Toon's, minus the envelopes and raw streams:

- **header** `db priority, bank, mask` + one `dw` per mask bit (Sfx1, Sfx2, SfxN, Ch1, Ch2, Ch3, Drm). Priorities in the data: `$01`–`$80`; all music `$40` with mask `$78`;
- notes `$00–$CF` (hi = pitch 1–12, 0 = rest; lo × unit, 0 = 256 ticks); drum notes (hi = `DrumMap` entry 1–7); SfxN bytes = NR43 values of one unit;
- `$D0–$D8`, `$D9`, `$DB–$DE` x: no-ops; `$DA` xy: 0 transpose up, 1 down, 2 no-op, 3 duty/wave, 4 flags (| 2 autopan); `$DF` x: NR51 bits (3 bytes on the drum track);
- `$E0` unit, vol|duty, env|gate (tone/wave), `$E0` unit, NR42 (SfxN), `$E0` unit (Drm); `$E1–$E6` octave; `$E7` unit; `$E8` gate/env; `$E9` duty step; `$EA`/`$EC`/`$EF` x no-ops; `$EB n xy` vibrato; `$ED` detune; `$EE` tempo; `$F0–$FA` attenuation;
- flow: `$FB` segno, `$FC` return, `$FD addr` call, `$FE n` repeat / `$FE $FF addr` jump, `$FF` end.

In the data: 6,657 notes, 912 drum notes, 204 noise bytes, 177 voices, 710 calls, 185 repeats, 245 `$DF` pans, 357 `$DA` extensions, 56 duty steps, 31 vibratos, 59 detunes, 39 tempos. **Not used:** the `$EA`/`$EC`/`$EF`/`$D0–$D9`/`$DB–$DE` no-ops, `$FE $FF` jumps.

### 3.1 Tables (bank 14)

| Address | Contents |
|---|---|
| `$4C21` | `PeriodTable`, 85 periods |
| `$4CCB` | `WaveTable`, 15 pointers (by duty − 1) to 13 waves at `$4CE9–$4DB8` |
| `$4DB9` | `SoundTable`, ids `$01–$8F` (read from `$4DB7` + 2 × id; entry 0 = the last two bytes of the last wave) |
| `$4ED7–$5244` | headers |
| `$5245` | `DrumMap`, 7 ids (`$01–$07`) |
| `$524C–$5264` | the drum headers, then SFX streams from `$5265` |
| `$5284` | `VibratoTable`, 11 pointers, tables to `$52C8` |
| `$5DB5–$7BFA` | songs `$73–$7E` (with SFX streams before) |
| bank 15 `$4000–$5875` | songs `$7F–$8F` |

---

## 4. Sounds

SFX `$01–$72` (drum hits `$01–$07` on SfxN; most SFX use Sfx1 alone, some add SfxN (mask `$05`) or Sfx2 (`$03`), `$2B` plays on the three music channels), songs `$73–$8F` on Ch1, Ch2, Ch3 and Drm. Four orphan Sfx1 streams (`$5662`, `$566D`, `$5676`, `$567F`) and one orphan drum stream (bank 15 `$483B`) are decoded in the asm.

---

## 5. Quirks and bugs

1. **The fade's drum stop breaks the stack** (Tiny Toon's bug): with SfxN idle `FadeTick` jumps to `Flow_End`, whose `pop hl` takes `SndUpdate`'s return address as the track page: the stop writes go to `$40C0`/`$40C1` (MBC), NRx2 = 0 goes to the last ticked track's channel, and the rest of the update is skipped.
2. **The Ch3 and Ch1/Ch2 fade stops are dead**, and the fade level has no limit (it wraps after 768 updates).
3. **CH3 levels**: `CalcVolumeCh3` mutes from level code 2 (Tiny Toon: 4), so CH3 plays at 100 % or not at all.
4. A refused last track **cuts the next request** (§2.4).
5. `StartTrack` reads the first stream byte from bank 14 even for a bank-15 song and sets `TRK_FLAGS2` bits 4/5 when it is `$01`; nothing reads them any more.
6. `CountdownTick` decrements the fade request (Zen's overlap).
7. The command arguments of bank-14 sounds are read through `FarRead` too (a bank switch per byte, to bank 14).

---

## 6. Verification

Lighter verification, as for the previous sessions: `verify/vstream14.py` boots the game in PyBoy, drops the game's own requests, calls the bank-14 `PlaySound` from the update glue at update 30 and hooks the two `TRK_LEN` stores (`$4662` notes/rests/drum notes, `$44CD` noise bytes): the stream address and length of every read must equal the decoder's timeline (`tools/kdata14.py`), the gaps between reads must be the lengths plus the tempo skips, and a stream the decoder ends must end. **Every id alone for 6,500 updates: 143 ids, 73,505 reads, 0 mismatches** (`verify/run_stream_kd.sh` → `run_stream_kd.log`). Bank-15 songs are read through `FarRead`, so the check covers the bank switch too.

---

## Files (in `GBAudioLab\Kon`)

- `KD_SoundDriver.asm` – the disassembly (driver + all sound data), byte-exact.
- `tools/kdata14.py` – decoder (`kd`; Tiny Toon/Zen's format from `kdata11.py`, the header bank, no raw streams); `tools/cfg_kd.py` – `gen_asm3.py` config; `tools/gaps14.py` – unowned data bytes (KD, WS, Kuro-chan, The Mummy).
- `verify/vstream14.py`, `verify/run_stream_kd.sh`, `verify/run_stream_kd.log`.
