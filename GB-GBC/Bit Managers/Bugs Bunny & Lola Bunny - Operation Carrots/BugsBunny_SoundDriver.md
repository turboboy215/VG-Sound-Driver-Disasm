# Bugs Bunny & Lola Bunny: Operation Carrots (GBC): sound driver

ROM: `Bugs Bunny & Lola Bunny - Operation Carrots (E) (M6) [C][!].gbc` (GBC-compatible, MBC5, 1 MB, internal title `BUGS BUNNY`).

Part of the AJG family (Alberto José González / Bit Managers), see `AJG_SoundEngine_Family.md`. This is **version 4**, documented in full in `Smurfs_SoundDriver.md`. The build is **Sea Battle's driver with The Smurfs' Nightmare's RAM addresses**, which makes it The Smurfs' Nightmare's driver (`Smurfs3_SoundDriver.md`) plus one change: **`StopAll` first sets a default instrument table** (`$7020`). The command set, ranges, output, pause and fade code are The Smurfs' Nightmare's (the Lucky Luke group, “GBS 3.4”), but the version text is not in this bank.

| | |
|---|---|
| Bank | the driver and its data fill **ROM bank 2 up to `$77FF`**; `$7800–$7FFF` is game graphics (§3) |
| Command table | `$4000` (37 commands, `$60–$84`, as Lucky Luke; `NOTE_HOOK` is unused) |
| API jump table | `$404A`: `SndUpdate $40E6`, `SndPause $40A2`, `SndResume $409B`, `StopAll $453D`, `PlaySfx $491A`, `SndInit $4522`, `SongFadeIn $495D`, `SongFadeOut $4957`, **18 song slots** (`$4062–$40AD`), `PlaySfxNow $491D` (`$40B0`) |
| Tick | once per frame, called by the game (§1) |
| RAM | pages Ch1 `$DBxx`, Ch2 `$DCxx`, Ch3 `$DDxx`, SFX `$DExx` (fields `$00–$41`); globals `$DB42–$DB65` (as The Smurfs' Nightmare) |
| Ranges | `INSTR $85–$93` (15), `ARP $94–$AF` (28), `VOLENV $B0–$BF`, `LEN $C0–$EF` (1–48), `REPEAT $F0–$FF` (2–17); drum tempo bytes `$C0–$FE` (as Lucky Luke) |
| Tables | SFX `$71A6` (21 entries), arpeggios `$70C5` (set by `SndInit`; no song sets one), CH3 volume `$41CE`, drums `$49F3` |
| Counts | 16 songs (18 slots), 21 SFX, **2 instrument tables** (`$7020` 15 entries read, set by `StopAll`; `$6F93` 15), 1 arpeggio table (24 entries read), 18 waves, 11 drum sounds (9 used) + 1 noise routine called with `CALL_CODE`, 20 drum patterns |

`BugsBunny_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over the whole of bank 2:

```
rgbasm -Wall -o bugs.o BugsBunny_SoundDriver.asm
rgblink -o bugs.gb bugs.o
python tools/cmp_banked.py bugs.gb "Bugs Bunny & Lola Bunny - Operation Carrots (E) (M6) [C][!].gbc" 2:4000-7FFF
```

---

## 1. Game glue (bank 0)

As in Lucky Luke and The Smurfs' Nightmare, there is no sound code in the interrupt handlers (`$40`, `$48`, `$50` are `reti`). Bank 0 has one wrapper per API entry (`$3DFB–$3E8A`):

- **SndUpdate** (`$3DFB`): called from the game's frame loops (18 call sites).
- **PlaySfx** (`$3E1B`, A = id): saves BC/DE/HL and switches back to bank 1 afterwards.
- **SndInit** (`$3E31`): also clears the music-off flag `$DEFE`.
- **Fades** (`$3E3D`, `$3E47`): fixed speed 4; the fade-out wrapper is used together with a palette fade (`$3DDC`).
- **Songs:** `$3E51` reads an API slot address from a table in bank 6 (the word after one of the game's loader lists) and calls it in bank 2, unless `$DEFE` is set. `$3E71` calls the slot at HL (used with slots 5 and 12).

`wStereo` (`$DB43`) is never written, so NR51 is `$FF` and the pan commands would have no effect (no song uses them).

## 2. Differences from The Smurfs' Nightmare and Sea Battle

| | The Smurfs' Nightmare | Sea Battle | Bugs Bunny |
|---|---|---|---|
| Bank | 2 | 4 | 2 |
| Pages / globals | `$DB–$DE` / `$DB42` | `$DC–$DF` / `$DC42` | **`$DB–$DE` / `$DB42`** |
| `StopAll` | – | sets `wInstrTable` = `$543B` | sets `wInstrTable` = **`$7020`** |
| `SndInit` arpeggio table / SFX table / CH3 volume | `$75DF` / `$7698` / `$41CE` | `$54BD` / `$5576` / `$41CE` | `$70C5` / `$71A6` / `$41CE` |
| Version text after the code | `$4B23` | `$4B23` | **none** (song 1 starts at `$4B23`) |
| Songs / SFX | 18 / 16 | 5 (18 slots) / 13 | 16 (18 slots) / 21 |

`tools/v4diff.py` against Sea Battle shows only the page bytes (`ld h, $DB` / `cp $DD` …) and the table addresses; against The Smurfs' Nightmare only the four `StopAll` instructions and the table addresses.

### 2.1 Songs

| Song (API slot) | Routine | Ch1 / Ch2 / Ch3 order lists | Instr. table | Length (ticks) |
|---|---|---|---|---|
| 1 (1) | `$4B23` → `$4B26` | `$4B4B / $4B43 / $4B3B` | `$7020` (`StopAll`) | loops |
| 2 (2) | `$513F` → `$4CBD` | `$4D12 / $4CEE / $4CD2` | `$7020` (`StopAll`) | loops |
| 3 (3) | `$5142` | `$5177 / $5167 / $5157` | `$7020` (`StopAll`) | loops |
| 4 (4) | `$541E` | `$5437 / $5435 / $5433` | `$7020` (`StopAll`) | 768, ends |
| 5 (5) | `$5537` | `$5550 / $554E / $554C` | `$7020` (`StopAll`) | 384, ends |
| 6 (6) | `$55C9` | `$55F2 / $55E8 / $55DE` | `$7020` (`StopAll`) | loops |
| 7 (7) | `$5867` | `$5887 / $58C7 / $58A7` | `$6F93` | loops |
| 8 (8) | `$5B73` | `$5B93 / $5BAB / $5BC3` | `$6F93` | loops |
| 9 (9) | `$5E6A` | `$5EBB / $5E9D / $5E7F` | `$7020` (`StopAll`) | loops |
| 10 (10) | `$6152` | `$6172 / $6188 / $619E` | `$6F93` | loops |
| 11 (11) | `$64C9` | `$64FA / $64EC / $64DE` | `$7020` (`StopAll`) | loops |
| 12 (12) | `$66DF` | `$66FE / $6704 / $670A` | `$6F93` | 297, ends |
| 13 (13) | `$6792` | `$67B3 / $67AD / $67A7` | `$7020` (`StopAll`) | 448, ends |
| 14 (14) | `$6816` | `$6837 / $6831 / $682B` | `$7020` (`StopAll`) | 384, ends |
| 15 (15) | `$6904` | `$6955 / $6937 / $6919` | `$7020` (`StopAll`) | loops |
| 16 (16) | `$6C37` | `$6C56 / $6C7A / $6C68` | `$6F93` | loops |

Slots 17 and 18 point at `$6F8F` (§3); the game never calls them.

**Songs 1 and 2 (the long version of song 1).** Song 1 is two patterns per channel, looped. Song 2's order lists start with the same two patterns, then go on with song 2's own patterns (Ch1: 16 entries, Ch2: 16, Ch3: 12), so it is a longer arrangement of song 1. The two song routines are reached through `jp` stubs:

- slot 1 → `$4B23`, a `jp $4B26` to the very next instruction, where song 1's routine is;
- slot 2 → `$513F`, a `jp $4CBD`. Song 2's routine (`$4CBD`) and its data sit right after song 1's data, and the stub sits after song 2's data, just in front of song 3's routine.

So song 2 is in the API table, but its routine is not where the song routines normally are (at the start of each song's data block). No other bank holds sound data or a song routine: the driver and its period table exist only in bank 2, and the song pointers in the game's bank-6 tables are API slot addresses.

Data usage:

- Music has 74 `REPEAT`s, 38 `PAT_CALL`s, 150 `WAIT2`s, 13 `VIBRATO`s, 10 `AUTODUTY`s, 9 `DRUMS_OFF`s, 12 `CALL_CODE`s (all to drum 7's routine `$7728`) and 3 `PAT_GOTO`s.
- Not used in the music: `STOP_ALL`, `FADE`, `FADE_OFF`, `NOTE_HOOK`, pan commands, `SLIDE_UP/DOWN`, `VOL`.

### 2.2 Sound effects

21 SFX on the CH3 page. They use `WAVE`, `LEN`, `VOLENV`, `VOL`, notes, `WAIT`, `REST`, `GLIDE`, `ARP`, `ARP_OFF`, `CH_TRANSPOSE`, `SLIDE_UP`, `SLIDE_DOWN`, `RELEASE`, `CALL_CODE` and `END`.

| Id | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 16 | 68 | 7 | 14 | 8 | 25 | 7 | 9 | 33 | 28 | 12 |

| Id | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 |
|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 20 | 11 | 12 | 36 | 52 | 44 | 48 | 9 | 8 | 36 |

### 2.3 Noise

11 drum sounds; drum 3 = 4 share a routine (as in The Smurfs' Nightmare); drums 10 and 11 are in the table but no pattern plays them:

| Drum | 1 | 2 | 3 = 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 |
|---|---|---|---|---|---|---|---|---|---|---|
| Routine | `$7658` | `$769D` | `$76D1` | `$76EE` | `$770B` | `$7728` | `$7675` | `$7745` | `$7767` (unused) | `$7784` (unused) |

Drum 7's routine is also the music's `CALL_CODE` target. The SFX call `$7377`, `$73C6`, `$7402`, `$742F`, `$7463` and `$7499` with `CALL_CODE`.

---

## 3. Quirks

1. **Slots 17 and 18 jump into data** (`$6F8F`): six unreferenced bytes `TRANSPOSE 0 / NEXT / TRANSPOSE 2 / NEXT`, then instrument table 1. The game never calls them. This looks like the same slip as Sylvester and Tweety's slots 1 and 10–12 (`Sylvester_SoundDriver.md` §3.1): a song label in front of small transpose patterns. Here the patterns are unused and nothing falls through to a song.
2. **Songs 1 and 2 go through `jp` stubs** (§2.1).
3. **Not sound data:** `$7800–$7FFF` is compressed game graphics, which the game's loader lists in bank 6 read from bank 2 (from `$7908`, `$7BD3–$7C61`, `$7C00`, `$7E1D`, `$7E7C`, `$7EB1`, `$7F07`, `$7F6C`). It is kept as bytes in the asm.
4. The Smurfs' Nightmare's quirks 1, 2 and 4 apply (dead panning, `SLIDE_UP` after a note slides down, The Smurfs quirks 4–7).
5. One drum pattern (`$677B`) has no `DRUM_LOOP` and runs into the next data (marked in the asm).
6. **Unreferenced (marked in the asm):**
   - `SetVolEnvBC` (`$4372`, left as data), a stray `ret` (`$443D`) and the `ret`s after three song routines;
   - zeros before the period table (`$47B7`, 73 bytes);
   - the loop words of songs 12–14's order lists;
   - a stray `NEXT` after a `PAT_GOTO` (`$6AB7`);
   - unused instrument and arpeggio table entries (`$6FB3`, `$70F5`), SFX stream fragments (`$7019`, `$7083`, `$70C4`);
   - an unused wave (`$755A`), noise tables and the noise routine `$7650` (it sets `wDrumHold` 8 and runs into drum 1's routine), drums 10 and 11, and arpeggio-like data (`$77B5`).

## 4. Verification (lighter)

- **Byte-exact rebuild** of bank 2 (`tools/cmp_banked.py`).
- **Emulator trace** (`verify/v4trace.py`): songs 1–16 (6000 ticks each) and SFX 1–21, **0 problems** (`verify/run_v4.log`). The lengths above come from this run.
- **Code comparison** with Sea Battle and The Smurfs' Nightmare (`tools/v4diff.py`): as in §2.
- Not done: no independent model; the game's frame-loop call rate was not measured.

## Files (in `GBAudioLab\AJG`)

- `BugsBunny_SoundDriver.asm`: labelled, commented RGBDS source (names carried along The Smurfs → Obélix GBC → Spirou → Lucky Luke → The Smurfs' Nightmare → Sea Battle), byte-exact
- shared version-4 tools and verification: see `Smurfs_SoundDriver.md`

Regenerate: `python tools/gen_v4.py bugs "Bugs Bunny & Lola Bunny - Operation Carrots (E) (M6) [C][!].gbc" BugsBunny_SoundDriver.asm`.
