# Spirou (GB): sound driver

ROM: `Spirou (E) (M4) [S][!].gb` (DMG with SGB support, MBC1, 256 KB, internal title `SPIROU`). Infogrames, 1996.

Part of the AJG family (Alberto José González / Bit Managers), see `AJG_SoundEngine_Family.md`. This is **version 4**, documented in full in `Smurfs_SoundDriver.md`. It sits **between the GB builds (The Smurfs, Astérix & Obélix GB, Tintin in Tibet) and the later GBC-style builds (Prisoners of the Sun, Astérix & Obélix GBC)**:

- **From the later builds** it already has the command table at `$4000`, the 37th command `NOTE_HOOK` (and **uses it**), no SFX priority and no duty shadows.
- **From the GB builds** it keeps the output code, the pause model and the NR50 handling.

Its command ranges are its own.

| | |
|---|---|
| Bank | the driver and all its data fill **ROM bank 15** (`$4000–$7EE0`; then the text `Final de la rutina de musica` and x86 assembler leftovers) |
| Command table | `$4000` (37 commands, `$60–$84`, the Obélix GBC set) |
| API jump table | `$404A`: `SndUpdate $40D7`, `SndPause $4093`, `SndResume $408C`, `StopAll $451F`, `PlaySfx $491A`, `SndInit $4504`, `SongFadeIn $495D`, `SongFadeOut $4957`, **13 song entries** (`$4062–$4086`), `PlaySfxNow $491D` (`$4089`) |
| Tick | VBlank, once per frame (59.73 Hz) |
| RAM | pages Ch1 `$C1xx`, Ch2 `$C2xx`, Ch3 `$C3xx`, SFX `$C4xx` (fields `$00–$41`); globals **`$C142–$C165`** (as Obélix GBC, without the duty shadows) |
| Ranges | **`INSTR $85–$91` (13), `ARP $92–$AD` (28), `VOLENV $AE–$BD`, `LEN $BE–$ED` (1–48), `REPEAT $EE–$FF` (2–19)**; drum tempo bytes `$BE–$FE` (`DRUM_TEMPO` = `$BD`) |
| Counts | 13 songs, 31 SFX, 1 instrument table (13 entries, 10 used), 1 arpeggio table (28 entries, 16 used), 18 waves, 10 drum sounds + 16 noise routines called with `CALL_CODE`, 22 drum patterns |

The ranges are Obélix GB's sizes (13 instruments, 28 arpeggios), each shifted up by one byte to make room for `NOTE_HOOK`. Obélix GBC and Prisoners of the Sun instead have 17 instruments and `REPEAT` 2–15.

`Spirou_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over the whole of bank 15:

```
rgbasm -Wall -o spirou.o Spirou_SoundDriver.asm
rgblink -o spirou.gb spirou.o
python tools/cmp_banked.py spirou.gb "Spirou (E) (M4) [S][!].gb" 15:4000-7FFF
```

---

## 1. Game glue (bank 0)

The VBlank handler switches to bank 15 at `$1659`, then:

- **Mailbox:** a routine address posted in `$C1E0/$C1E1` (A = `$C1E2`) is cleared and called (`$1B29`). The game posts API slot addresses there (songs, `StopAll`, `SndInit`, `SongFadeOut`).
- **SFX:** queued ids (count `$C1E3`, ids from `$C1E4`) go to `PlaySfx` (API slot 4), **except while `$C5E4` is set** (the queue is then kept).
- **Update:** then `SndUpdate`, once.

`wStereo` (`$C143`) is never written by the driver or the game, and it stays 0 through boot and the title screen. NR51 is therefore `$FF`. The data uses no `PAN_*` commands.

## 2. Differences from Astérix & Obélix GBC

| | Astérix & Obélix GBC | Spirou |
|---|---|---|
| Bank / globals | 6 / `$C142–$C167` | **15** / `$C142–$C165` |
| Ranges | `INSTR $85–$95`, `ARP $96–$B1`, `VOLENV $B2`, `LEN $C2`, `REPEAT $F2` (2–15) | **`INSTR $85–$91`, `ARP $92–$AD`, `VOLENV $AE`, `LEN $BE`, `REPEAT $EE` (2–19)** |
| Duty | shadows, NR11/NR21 rewritten every tick | **straight to NR11/NR21** (`INSTR` still leaves auto-duty running) |
| Pulse NRx4 | one write (high \| `$80` with the envelope, else high when changed) | **as The Smurfs:** high byte when changed, then high \| `$80` with the envelope |
| CH3 / noise steps | NR31 = 0 / NR41 = 0 | no NR31 / NR41 writes |
| `SndPause` / `SndResume` | both silence and reset the SFX page; `StopAll`, `STOP_ALL` and `SongFadeIn` call `SndResume` | **as The Smurfs:** pause silences (CH3 only without an SFX), resume reloads the music wave; nothing else calls them |
| `SndInit` | also `wStereo` = `$FF` | no `wStereo` write |
| `HWENV` | values pass through `HwEnvAtten` (stub) | no stub |
| Fades | NR50 not forced; `$80` byte pauses; `StartFade` reloads the music wave | **as The Smurfs:** NR50 forced to `$77` while no fade runs (unless 0), `StartMusicCh3` sets NR50 = `$77`; no `$80` byte, no wave reload |
| Note on, vibrato/slide direction | always reset to down | reset to down **unless bit 4 of the vibrato delay is set** (§2.1) |
| `NOTE_HOOK` | unused | **used by song 3** (§2.2) |
| `SndInit` arpeggio table / SFX table / CH3 volume table / drum table | `$74AC` / `$7598` / `$41CA` / `$49F4` | `$7603` (no song sets it) / `$76AC` / `$41AD` / `$49F3` |

`PlaySfx` is the same as Obélix GBC: no priority test, and both API SFX entries lead to it through the `jp` in the API table's last slot.

### 2.1 Note-on direction test

Where The Smurfs has `bit 5, [hl]` (keep the direction for slides) and Obélix GBC has nothing (always clear b4), Spirou has **`bit 4, a`**, with A = the vibrato delay just copied to its counter. Slides have delay 0, so after a note both `SLIDE_UP` and `SLIDE_DOWN` slide down, as in Obélix GBC; only `SLIDE_DOWN` is used. A vibrato whose delay has bit 4 set (16–31, 48–63, …) keeps its direction across notes. This looks like a slip for the Smurfs test, with little audible effect.

### 2.2 `NOTE_HOOK` in song 3

Song 3's Ch3 (wave) track starts with:

```
Pat_532E:
	VIBRATO $05, $01, $04
	LEN 9
	CH_TRANSPOSE $0C
	WAVE Wave_7D10
	VOLENV 15, $11, $1F, $11
	NOTE_HOOK Song3HookNote, Song3HookWait
```

The hook stays on for the whole track; the order list loops back to this pattern. The two routines are in the song data (`$5543`, `$5549`) and each loads BC with a 4-byte envelope and jumps to `SetVolEnvBC` (`$4357`), a `VOLENV` that reads its bytes from BC:

- **at each note:** `VOLENV 15, $11, $1F, $11` (`Song3EnvNote`, `$554F`);
- **at each `WAIT`:** `VOLENV 10, $10, $1F, $11` (`Song3EnvWait`, `$5553`). The driver then plays **the previous note** (field `$3C`) as a new note on.

The patterns alternate note / `WAIT`, so every note is followed by a quieter replay of the note before it: an echo in the style of Metal Masters' `ECHO`, built from song code. **A converter must emulate this for song 3** (on `WAIT` with the hook on: retrigger the note in `$3C` with the hook's envelope).

`SetVolEnvBC` is also present, unreferenced, in Prisoners of the Sun and Astérix & Obélix GBC. The Obélix document's "older `VOLENV` body" is this routine.

### 2.3 Songs

| Song (API entry) | Routine | Ch1 / Ch2 / Ch3 order lists | Instr. table | Length (ticks) |
|---|---|---|---|---|
| 1 (`$4062`) | `$734A` | `$735F / $737F / $736F` | – | loops |
| 2 | `$4B23` | `$4B42 / $4B6A / $4B56` | `$75B0` | loops |
| 3 | `$4FF2` | `$5011 / $503B / $5023` | `$75B0` | loops (`NOTE_HOOK`) |
| 4 | `$5557` | `$5576 / $55A6 / $558E` | `$75B0` | loops |
| 5 | `$58EF` | `$590E / $593A / $5924` | `$75B0` | loops |
| 6 | `$5C6E` | `$5C8E / $5CBA / $5CA4` | `$75B0` | loops |
| 7 | `$602D` | `$604C / $6078 / $6060` | `$75B0` | loops |
| 8 | `$62E3` | `$6302 / $6316 / $6330` | `$75B0` | loops |
| 9 | `$679C` | `$67BC / $67EC / $67D4` | `$75B0` | loops |
| 10 | `$6A28` | `$6A3D / $6A65 / $6A51` | – | loops |
| 11 | `$6D2B` | `$6D40 / $6D42 / $6D44` | – | 648, ends |
| 12 | `$6E02` | `$6E21 / $6E39 / $6E2D` | `$75B0` | loops |
| 13 (`$4086`) | `$6FEC` | `$700B / $701B / $702B` | `$75B0` | loops |

Song 1's routine is the last song routine in the bank. `INSTR n` reads entry n + 1 of `$75B0`; all songs use the arpeggio table `$7603` from `SndInit`.

Data usage: 149 `REPEAT`s (some inside SFX), 23 `VIBRATO`s, 1 `NOTE_HOOK`. Not used: `VIB_OFF`, `STOP_ALL`, `PAN_C/R/L`, `AUTOPAN`, `FADE`, `FADE_OFF`, `VOL`, `SLIDE_UP`.

### 2.4 Sound effects

31 SFX on the CH3 page. They use `WAVE`, `LEN`, `VOLENV`, notes, `WAIT`, `REST`, `GLIDE`, `GLIDE_OFF`, `ARP`, `VIBRATO`, `SLIDE_DOWN`, `RELEASE`, **`REPEAT`/`REPEAT_END`**, `CALL_CODE` and `END`.

| Id | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 75 | 15 | 10 | 8 | 27 | 27 | 16 | 10 | 9 | 13 | 28 | 45 | 29 | 10 | 32 | 11 |

| Id | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 | 30 | 31 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 36 | 13 | 16 | 30 | 20 | 21 | 30 | 30 | 9 | 25 | 12 | 6 | 3 | 5 | 33 |

### 2.5 Noise

The same new drum sounds as Prisoners of the Sun (`TintinSun_SoundDriver.md` §2.4), arranged differently:

| Drum | 1 | 2 | 3 = 4 | 5 | 6 | 7 = 9 | 8 | 10 |
|---|---|---|---|---|---|---|---|---|
| Routine | `$7DDC` | `$7DF9` | `$7E25` | `$7E42` | `$7E5F` | `$7E7C` | `$7DF9` (= drum 2) | `$7E9E` |
| As Sun drum | 1 | 2 | 3 | 5 | 6 | 9 | 2 | 10 |

Drum 7/9 is Sun's drum 9 (NR43 `51 32`, NR42 `F0 62`); there is no equivalent of Sun's drum 7 or drum 8. As in Prisoners of the Sun, **the drum table's 11th slot (`$4A07` → `$7EBB`) is not a routine** but points at the next data.

`CALL_CODE` noise routines (hold in ticks):

| Routine | Hold | Note |
|---|---|---|
| `$78F4` | 19 | NR42 = `$F2` |
| `$794C` | 24 | NR42 = `$A2` |
| `$79FA` | 19 | NR42 = `$F1` |
| `$7A27` | 36 | NR42 = `$F3` |
| `$7AE1` | 15 | NR42 = `$C2` |
| `$7988` | 10 | |
| `$79BA` | 25 | |
| `$7A76`, `$7A98`, `$7B27`, `$7B58`, `$7B81` | 15 | |
| `$7BAE`, `$7BDB` | 4 | |
| `$7C0A` | 35 | |
| `$7C4A` | 33 | |

---

## 3. Quirks

1. **Note-on direction test on the vibrato delay** (§2.1).
2. **Song 3 depends on `NOTE_HOOK`** (§2.2).
3. **Panning is dead** (§1).
4. The Smurfs quirks 4–7 apply.
5. **Unreferenced (marked in the asm):**
   - stray `ret` bytes;
   - data before the period table (`$478F`);
   - the drum table's 11th slot (`$4A07`);
   - a `NEXT` after a pattern (`$5377`);
   - 12 unused arpeggio table entries and arpeggios (`$7623`, `$768F`);
   - an SFX-like stream after SFX 31 that is not in the table (`$785E`, ends with `END`);
   - noise-table pieces (`$797F`, `$7B15`, `$7EC0`);
   - the end text.

## 4. Verification (lighter)

- **Byte-exact rebuild** of bank 15 (`tools/cmp_banked.py`).
- **Emulator trace** (`verify/v4trace.py`): every song (6000 ticks, including song 3 with its hook routines running) and SFX 1–31. **0 problems** (`verify/run_v4.log`). The lengths above come from this run.
- Not done: no independent model; effects (including the hook echo) are documented from the code.

## Files (in `GBAudioLab\AJG`)

- `Spirou_SoundDriver.asm`: labelled, commented RGBDS source (names carried from The Smurfs through Obélix GBC by code alignment), byte-exact
- shared version-4 tools and verification: see `Smurfs_SoundDriver.md`

Regenerate: `python tools/gen_v4.py spirou "Spirou (E) (M4) [S][!].gb" Spirou_SoundDriver.asm`.
