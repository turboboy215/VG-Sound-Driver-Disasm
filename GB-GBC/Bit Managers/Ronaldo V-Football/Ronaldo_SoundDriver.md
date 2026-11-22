# Ronaldo V-Football and UEFA 2000: sound driver

ROMs:

- `Ronaldo V.Football (E) (M7) [C][!].gbc` (GBC-compatible, MBC5, 1 MB, internal title `RONALDO`). Sound bank **31**.
- `UEFA 2000 (E) (M6) [C][!].gbc` (GBC-only, MBC5, 1 MB, internal title `UEFA 2000`). Sound bank **31**.

Part of the AJG family (Alberto José González / Bit Managers), see `AJG_SoundEngine_Family.md`. This is **version 4**, documented in full in `Smurfs_SoundDriver.md`. The bank names the driver right after the period table (`$49A2`): `(Music & Sound Driver (C) 1999 by Alberto Jose Gonzalez :)`.

**The two games run the same driver, byte for byte** (`$4000–$4CFA`); only the music data and the addresses of the data tables differ. The game's sound-effect glue, the SFX streams and the drum routines are also the same (moved).

**The driver is V-Rally GBC's** (`VRally_SoundDriver.md`: Turok's driver, GBC revision), with:

- the race-engine code and its 14 API entries removed;
- **semitone glissando**, four new commands `GLISS_1/2/3` and `GLISS_OFF` (§2.1), so every range above `INSTR` moves up by 4;
- RAM one page higher than V-Rally, at the Prisoners of the Sun group's pages `$DC–$DF`, with globals at **`$DC44`** (two more page fields);
- **`SndInit` sets `wStereo` = `$FF`**: NR51 comes from the pan bits, so `AUTOPAN` in the music is heard (§2.3);
- **`PlayOnCh1/2/3`**: play a stream directly on a music page (§3.2);
- **SFX priority** again: SFX 1 and 2 do not interrupt SFX 3–5;
- a **crowd-noise** routine on CH4 for the game (§2.4);
- the SFX page is ticked after the drums, and NR31 is also cleared in `RestoreMusicWave`.

| | Ronaldo V-Football | UEFA 2000 |
|---|---|---|
| Bank | 31: driver and data `$4000–$6419` (song data from `$4CFB`); the rest of the bank is leftover bytes (§5) | 31: `$4000–$5F2B`, then leftover bytes |
| Command table | `$4000`, 41 commands (`$60–$88`) | as Ronaldo |
| API jump table (`$4052`) | `SndUpdate $40E8`, `SndPause $4098`, `SndResume $4091`, `StopAll $4580`, **`PlaySfx` slot → game glue `$5CE9`**, `SndInit $4562`, `SongFadeIn $4ADC`, `SongFadeOut $4AD6`; **13 song slots** (`$406A–$408E`): 6 songs, 7 × `jp $5B30` (the first instrument-table entry; never called). No `PlaySfxNow` | as Ronaldo, glue `$57F0`; 13 song slots: **5 songs**, 8 × `jp $5634` |
| Driver `PlaySfx` | `$4A90` (A = 1–5), reached only through the glue | as Ronaldo |
| `StartMusicCh1/2/3` | `$4A4C` / `$4A5A` / `$4A68` (14 bytes apart, as V-Rally), each sets `wInstrTable` = `$5B2E` | as Ronaldo, `$5632` |
| Tick | **timer interrupt** (`$0050` → `$03C5`): it switches to bank 31, plays the SFX ids the game queued (`$C0BD`/`$C0BE…`) through the glue, then `SndUpdate` | as Ronaldo (`$0050` → `$03DD`) |
| RAM | pages Ch1 `$DCxx`, Ch2 `$DDxx`, Ch3 `$DExx`, SFX `$DFxx` (fields `$00–$43`); globals `$DC44–$DC6B` | as Ronaldo |
| Ranges | `INSTR $89–$9B` (19), `ARP $9C–$B7` (28), `VOLENV $B8–$C7`, `LEN $C8–$F7` (1–48), `REPEAT $F8–$FF` (2–9); drum tempo bytes `$C8–$FE` | as Ronaldo |
| Tables | instruments `$5B30` (14 used), arpeggios `$5BC9` (8 used, set by `SndInit`), SFX `$5FA5` (5), game SFX `$5CF7` (18), CH3 volume `$41DE`, drums `$4B77` (12), crowd NR43 `$4CAE` (16), period table `$4900` | instruments `$5634` (14), arpeggios `$56CD` (21), SFX `$5AB7` (5), game SFX `$57FE` (18), the rest as Ronaldo |
| Counts | 6 songs, 5 SFX + 18 game SFX ids, 6 waves, 12 drum sounds, 13 drum patterns | 5 songs, the same SFX, 6 waves, 12 drum sounds (9 used), 9 drum patterns |

Both rebuild **byte-exact** with RGBDS 0.9.1 over the whole sound bank:

```
rgbasm -Wall -o ronaldo.o Ronaldo_SoundDriver.asm
rgblink -o ronaldo.gb ronaldo.o
python tools/cmp_banked.py ronaldo.gb "Ronaldo V.Football (E) (M7) [C][!].gbc" 31:4000-7FFF

rgbasm -Wall -o uefa.o UEFA2000_SoundDriver.asm
rgblink -o uefa.gb uefa.o
python tools/cmp_banked.py uefa.gb "UEFA 2000 (E) (M6) [C][!].gbc" 31:4000-7FFF
```

---

## 1. Game side

- **Tick:** the timer interrupt. The game's start-up switches a GBC to double speed (`$0164`); the sound start-up (`$2220`) sets TAC = `$04` and TMA = `$76` on a GBC (8192 Hz / 138 = **59.36 Hz**) or `$BC` on a DMG (4096 Hz / 68 = **60.24 Hz**). UEFA 2000 has the same code (`$24C9`).
- **Sound effects:** the game queues SFX ids; the timer handler posts each through the `PlaySfx` API slot, which is the game's glue in the sound bank (§3), then calls `SndUpdate`.
- `SndInit` is called at `$01A2`, `StopAll` at `$01A5`/`$01C8`.

## 2. Changes from V-Rally GBC

| | V-Rally GBC | Ronaldo V-Football / UEFA 2000 |
|---|---|---|
| Pages / globals | `$DB–$DE` / `$DB42` | **`$DC–$DF` / `$DC44`** (+ `wCrowdNoise $DC6A`, `wCrowdLevel $DC6B`) |
| Page fields | `$00–$41` | **`$42` glissando offset, `$43` glissando speed** |
| Commands | 37 (`$60–$84`) | **41**: `GLISS_1 $85`, `GLISS_2 $86`, `GLISS_3 $87`, `GLISS_OFF $88` |
| API | 8 + 14 engine entries + 13 song slots + `PlaySfxNow` | 8 + 13 song slots; the `PlaySfx` slot goes to the game's glue |
| `SndUpdate` | engine hook, then Ch1–Ch3, SFX page, drums | **no engine hook**; Ch1–Ch3, **drums, then the SFX page** (a drum that starts an SFX is heard in the same tick) |
| `SndInit` | | **`wStereo` = `$FF`** |
| `StopAll` | `EngineStop`, NR10 = `$08`, silence | NR10 = `$08`, **`wCrowdLevel` = 0**, silence |
| `PlaySfx` | no priority | **ids 1–2 are ignored while SFX 3 or higher plays** |
| `ResetChannel` | | also clears the glissando fields (`ResetSfxPage`: the speed only) |
| `RestoreMusicWave` | NR30 off, copy, NR30/NR34 on | also **NR31 = 0** |
| Noise step | returns when no noise sequence runs | runs **`CrowdNoise`** when no noise sequence runs |
| Period table | `$4800`, then the date text | **`$4900`** (the code no longer fits below `$4800`), then the credit text |
| Drum table | 9 entries | **12**; five drum sounds also start SFX 1 or 2 (§2.2) |

Unchanged: the 37-command set up to `NOTE_HOOK`, Turok's `CheckRelease`, the Prisoners of the Sun output, pause and NR50 model, the GBC duty shadows (`$DC68/$DC69`, written every tick), the unreferenced `SetVolEnvBC`.

### 2.1 Glissando (`GLISS_1`/`2`/`3`, `GLISS_OFF`)

`GLISS_n` sets the speed (field `$43`) to n semitones per tick; `GLISS_OFF` sets it to 0.

- **At a note on**, while the speed is not 0: offset (field `$42`) = previous note − new note.
- **Every tick:** a positive offset goes down by the speed and a negative one goes up, stopping at 0. The offset is added to the period index with the other transposes.

So each note starts at the previous note's pitch and moves to its own pitch in semitone steps. Ronaldo uses it in its music (14 commands); UEFA 2000 does not.

### 2.2 Drums with a CH3 hit

Drum sounds 1, 2, 7, 9, 11 and 12 start a noise sequence and also call `PlaySfx` with id 1 or 2: two short SFX (2 ticks each) on the SFX page with their own wave, so the drum also sounds on CH3. Because of the new priority, these hits never cut SFX 3–5.

### 2.3 Panning

`SndInit` sets `wStereo`, so NR51 is built from the channels' pan bits (`$11` centre, as in The Smurfs and Astérix & Obélix GBC). The music uses `AUTOPAN` (Ronaldo 2, UEFA 2000 4) but no `PAN_*` commands. The glue's noise SFX set the noise pan to `$88` (centre).

### 2.4 Crowd noise

`CrowdNoise` (`$4CBE`) runs in the noise step whenever no noise sequence is on:

- **`wCrowdLevel` ≠ 0:** NR43 = `CrowdNoiseNR43[wCrowdNoise]` (16 values at `$4CAE`), NR42 = level << 4 (no envelope). Each register is written only when it differs from what the chip holds; NR42 writes retrigger.
- **`wCrowdLevel` = 0 and `wCrowdNoise` ≠ 0:** NR43 = 0, NR42 = 0 and trigger, `wCrowdNoise` = 0 (silence once).

The game sets the two bytes through game SFX 12–14 (§3). Drums and noise SFX interrupt it; it resumes when their noise sequence ends. `StopAll` clears the level.

## 3. The game's sound effects (glue in the bank)

The `PlaySfx` API slot jumps to `GamePlaySfxGlue` (Ronaldo `$5CE9`, UEFA 2000 `$57F0`): game SFX id n (1–18) jumps to entry n of `GlueSfxTable`. Each handler is game code in the sound bank:

| Id | What it does | Ticks |
|---|---|---|
| 1, 2 | driver `PlaySfx` 3, 4 | 4, 27 |
| 3 | stream on the **Ch1 page** (`PlayOnCh1`) | 32 |
| 4–7, 9–11 | noise sequence (noise pan `$88`, `wDrumHold` 8, id 7: 15), plus a stream on the **Ch2 page** (`PlayOnCh2`) | 4–13 |
| 8 | noise sequence only (hold 12) | 8 |
| 12, 13, 14 | crowd noise on: level 2 / 5 / 8, NR43 index 9 / 7 / 5 | (no page; runs until changed) |
| 15–18 | stream on the **Ch3 page** (`PlayOnCh3`): short musical cues | 176, 448, 312, 512 |


### 3.1 Driver SFX

`PlaySfx` (A = 1–5) works as in version 4, with the new priority. SFX 1 and 2 are the drum hits, 3 and 4 are game SFX 1 and 2, 5 (40 ticks) is not referenced by the glue.

### 3.2 `PlayOnCh1/2/3`

Reset the page, set length 1, ticks left 1, active, and point it at the stream in DE (no order list). The music on that channel is lost until the next song starts; the stream plays to its `END`, which stops the page. This is version 3's `PlayOnChN` idea again (Metal Masters), used here by the game's glue only.

## 4. Songs

| Song (slot) | Ronaldo routine | Ronaldo length | UEFA 2000 routine | UEFA 2000 length |
|---|---|---|---|---|
| 1 | `$4CFB` | loops | `$4CFB` | loops |
| 2 | `$5333` | 448, ends | `$4F04` | loops |
| 3 | `$5461` | 576, ends | `$5069` | loops |
| 4 | `$556A` | loops | `$52DF` | loops |
| 5 | `$57E0` | loops | `$5584` | 304, ends |
| 6 | `$5A85` | see below | – | – |

Every song routine calls `StopAll`, then `StartMusicCh3`, `Ch2` and `Ch1`. All songs use the one instrument table that `StartMusicChN` sets and the arpeggio table from `SndInit`.

**Ronaldo song 6 bug:** song 6 is a one-shot. Its Ch3 pattern ends with `CALL_CODE Drum7`, and `Drum7` ends with `jp PlaySfx`. `PlaySfx` returns with **H = the SFX page and DE pointing into the SFX table**, and the command loop goes on with those:

- it reads the SFX table as a stream and stores the note into the SFX page, which then plays it (with SFX id 1 set);
- the Ch3 page is left with its stream pointer before the `CALL_CODE` and ticks left = 0, so 256 ticks later it reads `LENGTH`, `DRUMS_OFF`, `CALL_CODE Drum7` again.

So the song never ends: drum 7 and a few table bytes on CH3 repeat every 256 ticks. The emulator check lists this as a known effect, not a walk error.

## 5. Data notes

- **Unreferenced:**
  - `SetVolEnvBC` (39 bytes);
  - `$4817–$48FF`: **leftover bytes of an older build**: the second half of a period table and envelope / `StartMusicCh` code for pages `$C1–$C3` (Smurfs-era RAM);
  - more arpeggio pointers and unused arpeggios after the used ones, several 16-byte waves and noise tables;
  - after `FadeInTable` and the text `Final de la rutina de musica`: Ronaldo `$641A–$7FFF` (7142 bytes), UEFA 2000 `$5F2C–$7FFF` (8404 bytes). These are stale copies of older sound data and glue code (Ronaldo has the same text twice more), not referenced.
- **Unterminated drum patterns:** Ronaldo `$5B19` (song 6) runs into the instrument table, `$545B` and `$5566` into the next data; UEFA 2000 `$5618`. Each song turns the drums off before the end is read.
- Commands not used by either game: `VIB_OFF`, `STOP_ALL`, `PAN_C/R/L`, `FADE`, `FADE_OFF`, `PAT_CALL`, `VOL`, `SLIDE_UP/DOWN`, `NOTE_HOOK`. UEFA 2000 also does not use `CALL_CODE`, `WAIT2` or the glissando.

## 6. Verification

`verify/v4trace.py` runs the real driver from each ROM in PyBoy and checks every song, every driver SFX (through `PlaySfx`) and every game SFX id (through the glue) against the data walk at every tick. Results (`verify/run_v4.log`):

- Ronaldo: 29 tests, 27 890 ticks, **0 problems** (song 6's SFX-page reads of the SFX table are reported as the known effect of §4);
- UEFA 2000: 28 tests, 26 569 ticks, **0 problems**.

The harness never sets the crowd-noise bytes outside game SFX 12–14, which are covered by the byte-exact rebuild only.

## 7. Files

- `Ronaldo_SoundDriver.asm`, `UEFA2000_SoundDriver.asm`;
- entries `ronaldo` and `uefa` in `tools/v4cfg.py` and `tools/v4games.py`. Names are carried from V-Rally GBC (`ref='vrallygbc'`), then Ronaldo → UEFA 2000.

Regenerate with `python tools/gen_v4.py ronaldo|uefa <rom> <asm>`.
