# Turok: Rage Wars and Turok 3: Shadow of Oblivion: sound driver

ROMs:

- `Turok - Rage Wars (UE) (M4) [C][!].gbc` (GBC-only, MBC5, 1 MB, internal title `TUROK: RAGE`). Sound bank **63**.
- `Turok 3 - Shadow of Oblivion (UE) (M4) [C][!].gbc` (GBC-only, MBC5, 1 MB, internal title `TUROK 3 SO`). Sound bank **63**.

Part of the AJG family (Alberto José González / Bit Managers), see `AJG_SoundEngine_Family.md`. This is **version 4**, documented in full in `Smurfs_SoundDriver.md`, in its latest form so far. The bank names the driver right after its code (`$4C78`):

- Rage Wars: `(Music & Sound Driver by Alberto Jose Gonzalez, 1999)`;
- Turok 3: `(Music & Sound Driver by Alberto Jose Gonzalez, 2000)`.

Both also end their data with `Final de la rutina de musica` (Rage Wars `$7862`, Turok 3 `$7BA1`).

**The two games run the same driver code** (`$4000–$4C77`); the only differences are the data addresses in `PlaySong`, `PlaySfx`, `SndInit` and the fades, and the song count. The drum-hit SFX 1–5 are the same in both, and Rage Wars SFX 33 is Turok 3's SFX 32.

The driver grew out of **Ronaldo V-Football's** (`Ronaldo_SoundDriver.md`): it keeps its glissando, its new `PlaySfx` priority, its drums that also play a CH3 hit, its period table at `$4900` and the GBC output, but it is reorganised again:

- **songs are started by number** (`PlaySong`, A = song) from a song table, and `PlaySong` sets the default instrument table;
- **`wStereo` is gone**: NR51 always comes from the pan bits;
- the RAM moves to **WRAM bank 3**, pages `$D2–$D5`, and several page fields are renumbered;
- new **`DUTY_25`** and a four-step auto-duty; **auto-pan** alternates right and left;
- **`AUTODUTY` on the Ch3 page becomes `WAVE_SEQ`**: a list of waves, one per note;
- **`PINGPONG`**: each note's first tick is panned alternately left and right (and a drum version);
- `NOTE_HOOK` and `HwEnvAtten` are gone;
- new drum-pattern bytes; the crowd noise and `PlayOnChN` of the football games are gone.

| | Turok: Rage Wars | Turok 3 |
|---|---|---|
| Bank | 63: driver `$4000–$4C77`, credit text, then song data from `$4CAD`; sound data up to `$787D`, then leftover bytes (§6) | 63: up to `$7BBC`, then leftover bytes |
| Command table | `$4000`, **43 commands** (`$60–$8A`) | as Rage Wars |
| API jump table (`$4056`) | `SndUpdate $40DD`, `SndPause $40C2`, `SndResume $40BB`, `StopAll $4573`, **`PlaySong $4071`** (A = 0–10), `PlaySfx $4A16` (A = 1–33), `SndInit $4558`, `SongFadeIn $4A64`, `SongFadeOut $4A5E`. No song slots, no `PlaySfxNow` | as Rage Wars; `PlaySong` A = 0–9, `PlaySfx` A = 1–32 |
| Song table | `$67BA`, 11 entries (A = 0 and 10 are the same song) | `$6D84`, 10 entries |
| Default instrument table (`PlaySong`) | `$67D0` (19 instruments, used by every song) | `$6D98` (20; songs 2, 3, 5); the other 7 songs set their own |
| `StartMusicCh1/2/3` | `$49F0` / `$49F4` / `$49F8` (4 bytes apart again; they no longer set an instrument table) | as Rage Wars |
| Tick | the VBlank handler (`$0040` → `$1A8C`, `SndUpdate` at `$1B21`); the timer handler (`$0050` → `$1C8E`) also calls it under a flag test (`$1CAE`) | an interrupt handler at `$1FCD` (the vectors jump to RAM trampolines at `$C5E1–$C5E7`) |
| RAM | **WRAM bank 3** (the game sets SVBK = 3 before every call): pages Ch1 `$D2xx`, Ch2 `$D3xx`, Ch3 `$D4xx`, SFX `$D5xx` (fields `$00–$3F`); globals `$D240–$D265` | as Rage Wars |
| Ranges | `INSTR $8B–$9F` (21), `ARP $A0–$B7` (24), `VOLENV $B8–$C7`, `LEN $C8–$F7` (1–48), `REPEAT $F8–$FF` (2–9); drum tempo bytes `$C8–$FE` | as Rage Wars |
| Tables | arpeggios `$687E` (24 used, set by `SndInit`), SFX `$6BB3` (33), CH3 volume `$41C9`, drums `$4B7D` (14), period table `$4900`; fades `$784F` / `$7859` | instruments: 7 tables (§4); arpeggios `$6E51` (21), SFX `$7189` (32), drums `$4B7D` (14, 13 used); fades `$7B8E` / `$7B98` |
| Counts | 10 songs, 33 SFX, 48 waves (3 wave lists), 14 drum sounds, 27 drum patterns, 20 `CALL_CODE` noise routines in SFX | 10 songs, 32 SFX, 45 waves (2 wave lists), 13 drum sounds used, 19 drum patterns |

Both rebuild **byte-exact** with RGBDS 0.9.1 over the whole sound bank:

```
rgbasm -Wall -o ragewars.o TurokRageWars_SoundDriver.asm
rgblink -o ragewars.gb ragewars.o
python tools/cmp_banked.py ragewars.gb "Turok - Rage Wars (UE) (M4) [C][!].gbc" 63:4000-7FFF

rgbasm -Wall -o turok3.o Turok3_SoundDriver.asm
rgblink -o turok3.gb turok3.o
python tools/cmp_banked.py turok3.gb "Turok 3 - Shadow of Oblivion (UE) (M4) [C][!].gbc" 63:4000-7FFF
```

---

## 1. Game side

Bank 0 calls the API through a far-call helper that maps bank 63 and sets **SVBK = 3**, so the driver's RAM is in WRAM bank 3. In Rage Wars a music wrapper (`$0295`) does nothing if the requested song is already playing (`$C1B0`); otherwise it calls `StopAll`, `SndUpdate` twice and `PlaySong`. SFX go straight to `PlaySfx` (`$02BE`).

## 2. API and songs

`PlaySong` (A = song number): `StopAll`, `wInstrTable` = the default table, then **A ≥ the song count → return** (silence); otherwise `wCurSong` (`$D265`) = A and jump to entry A of the song table. The song routines are as before (`StopAll` again, then `StartMusicCh3/2/1` with an order list each); in Turok 3 most of them first set their own instrument table.

`StartMusicCh1/2/3` reset the page and start it; `StartMusicCh3` also stops the fade and the drums. They no longer set `wInstrTable` (Ronaldo's and Turok's did).

## 3. Changes from Ronaldo V-Football

### 3.1 Command set

| Byte | Ronaldo | Rage Wars / Turok 3 |
|---|---|---|
| `$60–$73` | `GLIDE` … `DUTY_12` | unchanged |
| `$74` | `HWENV` | **`DUTY_25`** (new; unused by the data) |
| `$75–$84` | `AUTOPAN` … `NOTE_HOOK` | `HWENV` … `SLIDE_DOWN` (+1) |
| `$77` | (`FADE`) | **`AUTODUTY n`**, or on the Ch3 page **`WAVE_SEQ w`** (§3.4) |
| `$85` / `$86` | `GLISS_1` / `GLISS_2` | **`PINGPONG` / `PINGPONG_OFF`** (new, replace `NOTE_HOOK`) |
| `$87–$8A` | | `GLISS_1/2/3`, `GLISS_OFF` |
| `$8B–` | | `INSTR`, `ARP`, `VOLENV`, `LEN`, `REPEAT` (+2 from Ronaldo's) |

`NOTE_HOOK` is gone with its code (the hook in the note on and in `WAIT`), and so is `HwEnvAtten`. The stream bytes `$60–$73` and the meaning of `WAIT` (`$65`) and `NEXT` (`$6A`, also the arpeggio and fade loop byte) are unchanged.

### 3.2 RAM

| Field | Ronaldo | Rage Wars |
|---|---|---|
| `$00–$27`, `$34–$3B` | | unchanged |
| `$28`, `$29` | `HWENV` value, 2nd-envelope delay reload | **NRx2 value to write, write flag** (were `$32/$33`) |
| `$2A`, `$2B/$2C`, `$2D` | | `HWENV` value, 2nd-envelope delay reload / counter, 2nd value (were `$28–$2B`) |
| `$2E–$30` | | auto-pan period / counter / step (were `$2C–$2E`) |
| `$31–$33` | | auto-duty period / counter / step (were `$2F–$31`); **Ch3 page: `$80` + wave index, wave-list address** |
| `$3C`, `$3D` | `NOTE_HOOK` fields (`$3C–$41`) | **ping-pong: first-tick flag, side** |
| `$3E`, `$3F` | (Ronaldo `$42`, `$43`) | glissando offset, speed |

Globals start at `$D240` in the old order **without `wStereo`** (everything after `wPaused` moves down by 1: `wShNR32 $D241`, `wInstrTable $D245`, `wArpTable $D247`, drums `$D24C–$D253`, noise `$D254–$D25C`, fade `$D25D–$D262`, duty shadows `$D263/$D264`). `wNoiseAutoPan` (`$D24B`) is now the noise ping-pong state, and `wCurSong` (`$D265`) is new.

### 3.3 Duty, auto-duty, auto-pan, pan

- **Four duties:** `DUTY_50 $80`, `DUTY_75 $C0`, `DUTY_12 $00`, `DUTY_25 $40` (new), written to the duty shadows (`$D263` for the Ch1 page, `$D264` for any other page), which the pulse output writes to NR11/NR21 every tick.
- **Auto-duty** (pulse pages only; the SFX page has no effect now): every n ticks the next of 75, 12.5, 25, 50 % (repeating).
- **Auto-pan:** right, left, right, left … (no centre steps any more).
- **`INSTR`** now also stops auto-pan and auto-duty / wave sequence and centres the pan, besides what it did before.
- **NR51** = the pan bits of Ch1, Ch2, CH3 (Ch3 or SFX page) and the noise pan, **always**: there is no `wStereo` test, so the pan commands, `AUTOPAN` and `PINGPONG` are heard. The data uses them (Rage Wars: 29 `PAN_*`, 9 `AUTOPAN`, 21 `PINGPONG`; Turok 3: 6, 4, 3).

### 3.4 `WAVE_SEQ` (Ch3 page)

`$77 w` on the Ch3 page stores `$80` and the address of a **wave list** (`dw wave, …, 0`). At every Ch3 note on (`WaveSeqNoteOn`) the driver takes the next wave of the list, stores it as the music wave and loads it (unless an SFX plays); at the `0` it goes back to the first wave. `WAVE` and `INSTR` stop the sequence.

The lists step through 13–15 pulse-like waves of growing and then shrinking width (Rage Wars `$697F`, `$6AAD`; Turok 3 `$6F67`, `$7083`), so successive notes sweep the timbre like pulse-width modulation. Rage Wars also has a two-wave list (`$6979`).

**Converters:** the byte `$77` takes 1 argument byte on the pulse and SFX pages and 2 on the Ch3 page. One unused Rage Wars instrument (`$6806`) contains `$77`; it is rendered as `AUTODUTY`.

### 3.5 `PINGPONG`

With `PINGPONG` on (flag bit 5, which was the hook flag), the **first tick of each note** sets the channel's pan to left, then right on the next note, and so on; its other ticks are centred. `PINGPONG_OFF` stops it (the pan stays where it is).

The drum version works on the noise channel: drum byte `$35` turns it on, `$36` off. Then the first step of each noise sequence sets the noise pan to right, then left alternately, and its later steps to centre.

### 3.6 Other code changes

- **Period index** ≥ 95 wraps by subtracting 95 (Ronaldo: ≥ 80 → 0). Indices 80–94 would read past the 80-entry table; the data never reaches them.
- **`PlaySfx`:** ids 1–6 are ignored while SFX 7 or higher plays (Ronaldo: 1–2 / 3). SFX 1–6 are the drums' CH3 hits: drum sounds 1–3 and 7–14 start a noise sequence and one of SFX 1–6 (4–6 are noise only).
- **`DRUMS 0, w`** means tempo 6.
- **`StopAll`** resets the SFX page through the music-page path of `ResetChannel` (after `SndResume` has reset it as the SFX page).
- `StreamCommand` pushes the return address into `ReadStream` instead of calling the handler; the effect is the same.
- The 233 bytes before the period table are zeros.

### 3.7 Drum-pattern bytes

| Byte | Ronaldo | Rage Wars / Turok 3 |
|---|---|---|
| `$00`, `$01–$31`, `$32–$34`, `$FF` | end of step, drum sound, pan C/R/L, loop | unchanged |
| `$35` | `DRUM_AUTOPAN n` (2 bytes) | **`DRUM_PINGPONG`** (1 byte) |
| `$36` | `DRUM_REPEAT_END` | **`DRUM_PINGPONG_OFF`** |
| `$37` | level 0 | **`DRUM_REPEAT_END`** |
| level / speed / repeat | `$37–$46` / `$47–$5A` / `$5B–` (n = b − `$5A`) | **`$38–$47` / `$48–$5B` / `$5C–$C7`** (n = b − `$5B`) |
| tempo | `$C8–$FE` | `$C8–$FE` |

## 4. Songs

| A | Rage Wars routine | Length | Turok 3 routine | Instrument table | Length |
|---|---|---|---|---|---|
| 0 | `$6445` | loops | `$69A4` | `$6CD3` (17) | loops |
| 1 | `$4CAD` | loops | `$4CAD` | default `$6D98` | loops |
| 2 | `$5115` | loops | `$5089` | default | loops |
| 3 | `$53EE` | loops | `$5426` | `$56FA` (7) | loops |
| 4 | `$578A` | loops | `$573C` | default | loops |
| 5 | `$5A55` | 348, ends | `$58A6` | `$5CD7` (5) | loops |
| 6 | `$5B05` | loops | `$5CFE` | `$61B7` (6) | loops |
| 7 | `$5CEF` | loops | `$61F4` | `$61B7` | 256, ends |
| 8 | `$5F70` | loops | `$62C0` | `$6681` (7) | loops |
| 9 | `$60CA` | loops | `$66BE` | `$68E8` (16) | loops |
| 10 | `$6445` (= A 0) | | – | | |

Rage Wars uses the default table `$67D0` for every song. The two games share no music (the routine at `$4CAD` is at the same address by chance). The asm numbers songs 1–10 in table order (song n = A = n − 1).

## 5. Sound effects

`PlaySfx` (A = 1–33 / 1–32) resets the SFX page and points it at the stream from `SfxTable`. SFX streams use `WAVE`, `VOLENV`, notes, `GLIDE`, `ARP`, `VIBRATO`, `SLIDE_DOWN`, pans and `CALL_CODE` (20 / 18 noise routines). Rage Wars SFX 33's stream sits right after the table (`$6BF5`).

Lengths (ticks), Rage Wars: 2, 2, 4, 4, 4, 1, 55, 24, 27, 9, 5, 23, 28, 35, 40, 30, 30, 29, 45, 13, 15, 8, 13, 36, 25, 40, 26, 30, 20, 40, 6, 12, 56. Turok 3: 2, 2, 4, 4, 4, 1, 70, 28, 40, 26, 55, 24, 27, 20, 20, 23, 40, 35, 30, 30, 29, 45, 9, 13, 15, 8, 13, 36, 30, 80, 12, 56.

## 6. Data notes

- **Unreferenced:**
  - `SetVolEnvBC` (39 bytes), a 3-byte `jp $4A22` before `SndResume`, and 14 bytes of an older noise auto-pan routine (`$4C38`);
  - more arpeggio data, several 16-byte waves and noise tables (Rage Wars mostly between `$73BF` and `$764F`);
  - after the end text: Rage Wars `$787E–$7FFF`, Turok 3 `$7BBD–$7FFF` (leftover bytes).
- **Unterminated drum patterns:** Rage Wars `$5AED`, Turok 3 `$62A0`; the songs turn the drums off before the end is read.
- **Not used by the data:** `VIB_OFF`, `STOP_ALL`, `DUTY_25`, `FADE`, `FADE_OFF`, `VOL`, `SLIDE_UP` (both); Turok 3 also `PAN_C` and `PINGPONG_OFF`.

## 7. Verification

`verify/v4trace.py` runs the real driver from each ROM in PyBoy, starts every song through `PlaySong` (A = table index) and every SFX through `PlaySfx`, and checks them against the data walk at every tick (with `WAVE_SEQ`'s 2-byte form on the Ch3 page). Results (`verify/run_v4.log`):

- Rage Wars: 43 tests, 55 728 ticks, **0 problems**;
- Turok 3: 42 tests, 55 729 ticks, **0 problems**.

The harness leaves SVBK at its default (bank 1); the driver only uses its own pages, so this does not change the check.

## 8. Files

- `TurokRageWars_SoundDriver.asm`, `Turok3_SoundDriver.asm`;
- entries `ragewars` and `turok3` in `tools/v4cfg.py` and `tools/v4games.py` (command set `RAGEWARS_CMDS`, globals `RW_GLOBALS`, `song_table`, `api` order, `drum_fmt='rw'`). Names are carried from Ronaldo (`ref='ronaldo'`), then Rage Wars → Turok 3.

Regenerate with `python tools/gen_v4.py ragewars|turok3 <rom> <asm>`.
