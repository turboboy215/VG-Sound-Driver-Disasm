# Astérix & Obélix (GB and GBC): sound drivers

ROMs:

- **GB:** `Obelix (E) (M2) (Eng-Spa) [S][!].gb` (DMG with SGB support, MBC1, 256 KB, internal title `OBELIX`). Infogrames, 1995.
- **GBC:** `Obelix (E) (M4) [C][!].gbc` (CGB only, MBC5, 1 MB, internal title `OBELIX`, code `AOLP`). Infogrames, 1999.

Part of the AJG family (Alberto José González / Bit Managers), see `AJG_SoundEngine_Family.md`. Both builds use **version 4** of the driver, documented in full in `Smurfs_SoundDriver.md`; this file only lists what differs.

- **The GB build** is The Smurfs' driver with small changes: wider instrument/arpeggio ranges, the arpeggio table set per song, no SFX priority, `NR50` set by `StopAll`.
- **The GBC build** carries **the same music and SFX data** (item for item, at addresses one byte higher) under a revised driver: relocated globals, a 37th command, a new SFX/pause model and changed output code.

| | GB | GBC |
|---|---|---|
| Bank | **6**, `$4000–$7D33` used (rest zero) | **6**, `$4000–$7D34` used (rest zero) |
| API jump table | `$4000` | `$404A` (the command table comes first, at `$4000`) |
| API order | `SndUpdate $4078`, `SndPause $4052`, `SndResume $404B`, `StopAll $4565`, `PlaySfx $491C`, `SndInit $454A`, `SongFadeIn $4965`, `SongFadeOut $495F`, 16 songs, `PlaySfxNow $4925` | `$40D5`, `$409C`, `$4095`, `$453B`, `$4916`, `$451D`, `$4959`, `$4953`, 16 songs, `$4919` |
| Pages | `$C1–$C4` (fields `$00–$3B`) | `$C1–$C4` (fields `$00–$41`) |
| Globals | `$C196–$C1B9` (as The Smurfs) | `$C142–$C167` (same order, `$54` lower, plus duty shadows `$C166/$C167`) |
| Counts | 16 songs, 29 SFX, 4 instrument tables (3 + 2 + 3 + 13), 1 arpeggio table (28 entries, 20 used), 15 waves, 11 drum sounds (10 used) + 11 noise routines called with `CALL_CODE`, 24 drum patterns | the same |

`ObelixGB_SoundDriver.asm` and `ObelixGBC_SoundDriver.asm` rebuild **byte-exact** with RGBDS 0.9.1 over the whole of bank 6 (`6:4000-7FFF`):

```
rgbasm -Wall -o obelixgb.o ObelixGB_SoundDriver.asm
rgblink -o obelixgb.gb obelixgb.o
python tools/cmp_banked.py obelixgb.gb "Obelix (E) (M2) (Eng-Spa) [S][!].gb" 6:4000-7FFF
```

(the same for `ObelixGBC_SoundDriver.asm` and the `.gbc`).

---

## 1. Game glue (bank 0)

Both builds (GB `$31A2`, GBC `$31E7`) run from the VBlank handler with bank 6 switched in:

- **SFX:** the id posted in `$FF8D` goes to `PlaySfx`, except id 3 while any SFX plays. While a game flag (GB `$DA95`, GBC `$CBCD`) is set, SFX 29 is requested every frame instead (it can't interrupt itself on GB). While either of two game states (GB `$DA5D`/`$DA3D`) is 2, SFX requests are dropped.
- **Songs** are started through their API entries, by a bank-0 helper at `$035E` (`ld hl, entry` / `call $035E`).
- **Speed-up:** after `SndUpdate`, the glue calls **`SndUpdate` a second time on every 4th frame** while a game counter (GB `$C0F7`, GBC `$C0F6`) is between 1 and `$7F`. The game loads it with `$25` and counts it down. Music and SFX then run 25 % faster (an average of 1.25 ticks per frame).

---

## 2. GB build: differences from The Smurfs

| | The Smurfs | Astérix & Obélix GB |
|---|---|---|
| `INSTR` | `$84–$8D` (10) | `$84–$90` (13) |
| `ARP` | `$8E–$A8` (27) | `$91–$AC` (28) |
| `VOLENV` | `$A9–$B8` | `$AD–$BC` |
| `LEN` | `$B9–$E8` (1–48) | `$BD–$EC` (1–48) |
| `REPEAT` | `$E9–$FF` (2–24) | `$ED–$FF` (2–20) |
| Drum tempo bytes | `$B9–$FE` | `$BD–$FE` (`DRUM_TEMPO` = `$BC`) |
| Arpeggio table | set once by `SndInit` | `SndInit` sets `$74AB`, and every song sets it again (the same table) |
| `StopAll` | | also NR50 = `$77` |
| `PlaySfx` | ignored while a lower id plays | **no priority**; only SFX 29 can't be interrupted. The API's last entry (`PlaySfxNow`, `$4925`) skips even that |
| SFX table | `$769F` | `$7597` (indexed from `$7595`) |
| CH3 volume table / drum table | `$4166` / `$49FD` | `$414E` / `$49FB` |

The command table (`$4400`, 36 commands), the field layout, the period table (`$4800`) and the rest of the code are the same as The Smurfs. (`VOLENV` clears the attack-step field at the end instead of the start, with the same result.)

### 2.1 Songs

| Song (API entry) | Routine | Ch1 / Ch2 / Ch3 order lists | Instr. table | Length (ticks) |
|---|---|---|---|---|
| 1 (`$4018`) | `$4B2B` | `$4B52 / $4B5A / $4B60` | 1 | loops |
| 2 | `$4EFA` | `$4F2E / $4F22 / $4F16` | 2 | loops |
| 3 | `$517F` | `$519B / $51A7 / $51B3` | 3 | loops |
| 4 | `$542A` | `$5446 / $5460 / $5476` | 3 | loops |
| 5 | `$5764` | `$5781 / $578D / $57A9` | 4 | loops |
| 6 | `$59BF` | `$59DB / $59F1 / $5A07` | 4 | loops |
| 7 | `$5C26` | `$5C43 / $5C53 / $5C63` | 4 | loops |
| 8 | `$5EB6` | `$5ED2 / $5EE0 / $5EEE` | 4 | loops |
| 9 | `$6243` | `$625F / $626F / $627F` | 4 | loops |
| 10 | `$67D8` | `$67FA / $680E / $6826` | 4 | loops |
| 11 | `$695C` | `$6978 / $6988 / $6998` | 4 | loops |
| 12 | `$6B80` | `$6B9C / $6BA4 / $6BAC` | 4 | loops |
| 13 | `$6D3F` | `$6D5B / $6D65 / $6D6F` | 4 | loops |
| 14 | `$6F04` | `$6F20 / $6F2A / $6F34` | 4 | loops |
| 15 | `$709C` | `$70B8 / $70BA / $70BC` | 4 | 72, ends |
| 16 (`$4045`) | `$70F8` | `$7115 / $7131 / $7123` | 4 | loops |

GBC: the same songs, each address + 1 (routines `$4B2C` … `$70F9`). Instrument tables (GB): 1 `$4EDF` (3 instruments), 2 `$5163` (2), 3 `$540E` (3), 4 `$7436` (13); arpeggio table `$74AB` (28 entries; the last 8 are unused). `INSTR n` reads entry n + 1.

Not used by the data: `VIB_OFF`, `STOP_ALL`, `PAN_C/R/L`, `FADE`, `FADE_OFF`, `VOL`, `SLIDE_UP` (and on GBC `NOTE_HOOK`).

### 2.2 Sound effects

29 SFX, all on the CH3 page (no noise-only ids; noise comes from `CALL_CODE` inside the streams). They use `WAVE`, `LEN`, `VOLENV`, notes, `WAIT`, `REST`, `GLIDE`, `ARP`, `SLIDE_DOWN`, `RELEASE`, `CH_TRANSPOSE`, `CALL_CODE`, `END`.

| Id | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 13 | 9 | 6 | 8 | 8 | 32 | 10 | 18 | 13 | 12 | 18 | 28 | 8 | 25 | 11 |

| Id | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 5 | 3 | 8 | 5 | 28 | 75 | 40 | 5 | 15 | 25 | 24 | 26 | 80 | 57 |

### 2.3 Noise

Drum sounds (GB addresses; GBC + 1). Drums 1, 2 and 4–11 have the same sequences as The Smurfs; drum 3 differs in two bytes.

| Drum | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Routine | `$7BB0` | `$7BF5` | `$7C21` | `$7C3E` | `$7C5B` | `$7C78` | `$7C95` | `$7BCD` | `$7CB2` | `$7CD4` | `$7CF1` (unused) |

Drum 3: NR43 `50 41 50 51 42 53 51`, NR42 `F0 70 F0 70 D0 70 61`.

`CALL_CODE` noise routines (GB): `$777E` (hold 8), `$77AF`, `$77D1`, `$780D` (hold 10), `$78A1`, `$78D2`, `$78FB` (hold 15), `$7928` (hold 8), `$7955`, `$7982` (hold 4), `$79F1` (hold 25). Drums 7 and 9 are also started directly with `CALL_CODE` (no hold). Three more noise routines (`$7846`, `$79B1`, `$7BA8`, the same kind of code as The Smurfs' noise SFX) are unreferenced.

---

## 3. GBC build: differences from the GB build

**Data:** identical. All 9804 walked items match at address + 1, including order lists, patterns, instruments and drum patterns. Command bytes are renumbered for the new ranges below, and the drum-pattern tempo bytes are re-encoded for the new tempo range (same tempos).

| | GB | GBC |
|---|---|---|
| Command table | `$4400`, `$60–$83` (36) | **`$4000`**, `$60–$84` (37: **`NOTE_HOOK`** added) |
| `INSTR` / `ARP` | `$84–$90` / `$91–$AC` | `$85–$95` (17) / `$96–$B1` (28) |
| `VOLENV` / `LEN` / `REPEAT` | `$AD–$BC` / `$BD–$EC` / `$ED–$FF` | `$B2–$C1` / `$C2–$F1` (1–48) / `$F2–$FF` (2–15) |
| Drum tempo bytes | `$BD–$FE` | `$C2–$FE` (`DRUM_TEMPO` = `$C1`) |
| Globals | `$C196–$C1B9` | `$C142–$C165`, plus `wDutyCh1/2` `$C166/$C167` |
| `SndInit` | | also **`wStereo` = `$FF`** (the driver sets stereo itself) |
| `SndPause` / `SndResume` | silence (pause only), set/clear the flag | **both** silence CH1–CH4 and reset the SFX page (which reloads the music wave). `StopAll` and `SongFadeIn` call `SndResume` first |
| `PlaySfx` | SFX 29 not interrupted | **no test at all** (both API SFX entries lead to the same code) |
| Duty | `DUTY_*`, auto-duty, `INSTR` write NR11/NR21 directly | they write duty shadows; **NR11/NR21 are rewritten every tick** from them |
| Pulse NRx4 | high byte written when changed, then again with `$80` if the envelope flag is set | one write: high \| `$80` with NRx2 when the flag is set, else the high byte when it changed |
| CH3 | | NR31 = 0 at every output and wave load |
| Noise steps | | NR41 = 0 before NR43 and again before NR44 |
| `HWENV` | | both values pass through `HwEnvAtten` (`sub 0`: a stub) |
| `INSTR` | clears auto-duty | leaves auto-duty running |
| `VIBRATO` / `SLIDE_*` | set b3 (+ b6 / b5) | set b3 + b4 (start upwards); a note on **always** resets the direction to down, so after the first note both slides go down (only `SLIDE_DOWN` is used) |
| Fades | NR50 forced to `$77` while no fade runs | no forcing; a `$80` table byte calls `SndPause` and ends the fade (unused by the two tables) |
| `StartMusicCh3` | also NR50 = `$77` | no NR50 write |

### 3.1 `NOTE_HOOK` (`$84`, GBC only, unused)

`NOTE_HOOK on_note, on_wait` (two code addresses, flag b5) or `NOTE_HOOK 0` (off). At every note, field `$3C` gets the previous note and `$3D` this one, then `on_note` is called. At every `WAIT`/`WAIT2`, `on_wait` is called and then the note in `$3C` is played as a new note on. It looks like a general version of Metal Masters' echo, left to song code. No data uses it.

---

## 4. Quirks and bugs

1. **Drum pattern `$70EC` (song 15, GB; GBC `$70ED`) has no `$FF`**; song 15 ends before the pattern runs out, and the drums are off afterwards.
2. GBC: **slides lose their direction** at every note (§3); harmless here.
3. GBC: `HwEnvAtten` is a stub; `NOTE_HOOK` and the `$80` fade byte are unused features.
4. Both: the Smurfs quirks 4–7 (duty writes to NR21 from the CH3/SFX page, `STOP_ALL` from a stream, SFX end resets the noise timer and speed, `ResetChannel` leftovers) apply.
5. **Dead code/data:** GB zero fill before the command table (`$434B–$43FF`) and the period table, a stray `ret` at `$447E`, three `ret` bytes after song routines, unreferenced noise routines, waves and arpeggios (marked "Unreferenced" in the asm); GBC an older `VOLENV` body at `$436E` that read its bytes through `bc`, a stray `ret` at `$4438`, and the rest as GB.

---

## 5. Verification (lighter)

- **Byte-exact rebuild** of bank 6 for both ROMs (`tools/cmp_banked.py`).
- **Emulator trace** (`verify/v4trace.py`, as for The Smurfs): every song (6000 ticks) and SFX 1–29 on each ROM. Stream pointers, order positions and every byte the drum sequencer reads must be on walked items, including 600 ticks after a one-shot song ends (the drums keep running). **0 problems** on both (`verify/run_v4.log`); GB and GBC give identical lengths.
- Not done: no independent model; effects are documented from the code.

## Files (in `GBAudioLab\AJG`)

- `ObelixGB_SoundDriver.asm`, `ObelixGBC_SoundDriver.asm`: labelled, commented RGBDS sources (names carried over from The Smurfs by code alignment), byte-exact
- shared version-4 tools and verification: see `Smurfs_SoundDriver.md`

Regenerate: `python tools/gen_v4.py obelixgb "Obelix (E) (M2) (Eng-Spa) [S][!].gb" ObelixGB_SoundDriver.asm` and `python tools/gen_v4.py obelixgbc "Obelix (E) (M4) [C][!].gbc" ObelixGBC_SoundDriver.asm`.
