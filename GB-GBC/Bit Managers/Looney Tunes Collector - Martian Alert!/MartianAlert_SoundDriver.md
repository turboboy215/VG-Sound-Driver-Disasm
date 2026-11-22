# Looney Tunes Collector: Martian Alert!: sound driver

ROM: `Looney Tunes Collector - Martian Alert! (E) (M6) [C][!].gbc` (GBC-only, MBC5, 2 MB, internal title `MA1`). Sound bank **48**. The sequel (Martian Revenge!) uses the same audio data; it is not covered separately.

Part of the AJG family (Alberto José González / Bit Managers), see `AJG_SoundEngine_Family.md`. This is **version 4**, Rage Wars line (`TurokRageWars_SoundDriver.md`). The bank names the driver right after its code (`$4C78`): `(Music & Sound Driver by Alberto Jose Gonzalez, 1999)`. There is no `Final de la rutina de musica` text.

**The driver is Turok: Rage Wars' driver at an earlier stage.** It has Rage Wars' command set, ranges, RAM layout, `PlaySong`, `WAVE_SEQ`, `PINGPONG`, drum bytes and output code, but lacks three small changes that Rage Wars has (§2). Radikal Bikers and Baby Felix are built from this stage, not from Rage Wars.

| | |
|---|---|
| Bank | 48: driver `$4000–$4C77`, credit text, song data from `$4CAD`; sound data up to `$7FE9` |
| Command table | `$4000`, 43 commands (`$60–$8A`), as Rage Wars |
| API jump table (`$4056`) | `SndUpdate $40DD`, `SndPause $40C2`, `SndResume $40BB`, `StopAll $4571`, `PlaySong $4071` (A = 0–11), `PlaySfx $4A16` (A = 1–38), `SndInit $4556`, `SongFadeIn $4A64`, `SongFadeOut $4A5E` |
| Song table | `$74C2`, 12 entries (no repeats) |
| Default instrument table (`PlaySong`) | `$737C` (21 instruments used); songs 1 and 2 set their own (`$731B`, `$5221`) |
| `StartMusicCh1/2/3` | `$49F0` / `$49F4` / `$49F8` |
| Tick | once per frame, in VBlank, through a bank-0 far call (return address `$3F3F`) |
| RAM | **WRAM bank 7** (the game has SVBK = 7 at every call): pages Ch1 `$D2xx`, Ch2 `$D3xx`, Ch3 `$D4xx`, SFX `$D5xx` (fields `$00–$3F`); globals `$D240–$D265`, as Rage Wars |
| Ranges | `INSTR $8B–$9F`, `ARP $A0–$B7`, `VOLENV $B8–$C7`, `LEN $C8–$F7` (1–48), `REPEAT $F8–$FF` (2–9); drum tempo bytes `$C8–$FE`; Rage Wars' drum bytes (`drum_fmt='rw'`) |
| Tables | arpeggios `$744B` (16 used, set by `SndInit`), SFX `$74EA` (38), CH3 volume `$41C9`, drums `$4B7D` (14), period table `$4900`; fades `$7FD6` / `$7FE0` |
| Counts | 12 songs, 38 SFX, 18 waves, 14 drum sounds, 31 drum patterns |

It rebuilds **byte-exact** with RGBDS 0.9.1 over the whole sound bank:

```
rgbasm -Wall -o martian.o MartianAlert_SoundDriver.asm
rgblink -o martian.gb martian.o
python tools/cmp_banked.py martian.gb "Looney Tunes Collector - Martian Alert! (E) (M6) [C][!].gbc" 48:4000-7FFF
```

---

## 1. Game side

The game calls `SndUpdate` once per frame from VBlank through a far call in bank 0 (return address `$3F3F`) that maps bank 48. WRAM bank 7 is selected at every call, so the driver's pages and globals live there.

## 2. Differences from Turok: Rage Wars

The code is Rage Wars' instruction for instruction except for these points:

| | Rage Wars | Martian Alert |
|---|---|---|
| `ResetSfxPage` | also clears the SFX page's glissando fields `$3E/$3F` | **doesn't**: a glissando speed set by one SFX stays for the next |
| `WAVE` | stops a running `WAVE_SEQ` (clears field `$31`) | **doesn't**: only `INSTR` stops it |
| `SLIDE_UP` | `set 3` / `set 4` on the flags | `or $18` (Ronaldo's code; same effect) |
| `PlaySfx` priority | ids 1–6 don't cut 7+ | **ids 1–5 don't cut 6+** (SFX 1–5 are the drums' CH3 hits) |

`SLIDE_UP` is Ronaldo's code, and the priority limit (5) sits between Ronaldo's (2) and Rage Wars' (6), so this build looks like a step between Ronaldo V-Football and Rage Wars, although both credit texts say 1999. (On the SFX page's glissando, Ronaldo clears the speed, Rage Wars the offset and the speed, Martian Alert neither.) Neither of the two behaviour differences matters for the data: no SFX uses a glissando and no song uses `WAVE_SEQ`.

The 243 bytes before the period table are not zeros as in Rage Wars but PC memory garbage (UTF-16 text from a Windows Media profile, and x86 code).

## 3. Songs

| A | Routine | Instrument table | Length |
|---|---|---|---|
| 0 | `$4CAD` | `$731B` (14) | loops |
| 1 | `$5086` | `$5221` (6) | 768, ends |
| 2 | `$526C` | default `$737C` | loops |
| 3 | `$56AE` | default | loops |
| 4 | `$59C4` | default | loops |
| 5 | `$5C39` | default | loops |
| 6 | `$5F72` | default | loops |
| 7 | `$641E` | default | 448, ends |
| 8 | `$64D5` | default | loops |
| 9 | `$6847` | default | loops |
| 10 | `$6B71` | default | loops |
| 11 | `$6F91` | default | loops |

The asm numbers songs 1–12 in table order (song n = A = n − 1).

**Panning is heard** (NR51 always follows the pan bits, as in Rage Wars): the data has 19 `PINGPONG`, 6 `PAN_R`, 6 `PAN_L` and 2 `AUTOPAN`.

## 4. Sound effects

`PlaySfx` (A = 1–38). SFX 1–5 are the drums' CH3 hits. Lengths (ticks): 2, 2, 3, 3, 3, 25, 20, 8, 28, 10, 36, 9, 23, 255, 9, 11, 12, 19, 10, 24, 27, 25, 54, 10, 21, 20, 45, 28, 35, 6, 11, 20, 24, 30, 40, 25, 44, 52.

## 5. Data notes

- **Drum-hit wave:** the 16 bytes right after the song table (`$74DA`) are a wave, used by SFX 1–5 (the drums' CH3 hits) and by instrument 13 of the default table. Radikal Bikers and Baby Felix have the same wave in the same place; Rage Wars has no copy of it.
- **Unreferenced:** as Rage Wars, `SetVolEnvBC`, the 3-byte `jp` before `SndResume` and the old noise auto-pan fragment (`$4C38`); 16 bytes after the arpeggio table (`$746B`, eight words pointing at the song table), two 16-byte blocks among the waves (`$7CF7`, `$7D47`), a few noise-table bytes and the last 23 bytes of the bank.
- **Unterminated drum patterns:** `$55DA`, `$5C17` (the songs turn the drums off before the end is read).
- **Not used by the data:** `VIB_OFF`, `STOP_ALL`, `PAN_C`, `DUTY_25`, `FADE`, `FADE_OFF`, `SLIDE_UP`, `PINGPONG_OFF`; no `WAVE_SEQ` (no wave lists).

## 6. Verification

`verify/v4trace.py` starts every song through `PlaySong` and every SFX through `PlaySfx` and checks them against the data walk at every tick: **50 tests, 63 495 ticks, 0 problems** (`verify/run_v4.log`).

## 7. Files

- `MartianAlert_SoundDriver.asm`;
- entry `martian` in `tools/v4cfg.py` and `tools/v4games.py` (Rage Wars' command set and globals; names carried from Rage Wars, `ref='ragewars'`).

Regenerate with `python tools/gen_v4.py martian <rom> MartianAlert_SoundDriver.asm`.
