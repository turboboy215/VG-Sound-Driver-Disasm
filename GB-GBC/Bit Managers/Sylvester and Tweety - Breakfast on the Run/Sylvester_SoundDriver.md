# Sylvester and Tweety: Breakfast on the Run (GBC): sound driver

ROM: `Sylvester and Tweety (E) (M6) [C][!].gbc` (GBC-compatible, MBC5, 1 MB, internal title `SYLVESTER`).

Part of the AJG family (Alberto José González / Bit Managers), see `AJG_SoundEngine_Family.md`. This is **version 4**, documented in full in `Smurfs_SoundDriver.md`. The build is **Die Maus's driver** (`Maus_SoundDriver.md`) with **one more instrument**, so every range above `INSTR` moves up by 1. Nothing else in the code changes apart from table addresses. Like Otto's Ottifanten, it is a Die Maus-line driver in a later game; unlike Otto's, its ranges differ.

| | |
|---|---|
| Bank | the driver and all its data fill **ROM bank 15** (`$4000–$7AF9`, then `Final de la rutina de musica` at `$7AFA` and zeros to the end) |
| Command table | `$4000` (37 commands, `$60–$84`, Die Maus's set: `NOTE_HOOK $82`, `PORTA $83`, `PORTA_OFF $84`, no `SLIDE_UP/DOWN`) |
| API jump table | `$404A`: `SndUpdate $40C9`, `SndPause $4090`, `SndResume $4089`, `StopAll $4516`, `PlaySfx $491A`, `SndInit $44FB`, `SongFadeIn $495D`, `SongFadeOut $4957`, **12 song slots** (`$4062–$4094`), `PlaySfxNow $491D` |
| Tick | timer interrupt, reloaded at VBlank (§1) |
| RAM | pages Ch1 `$C1xx`, Ch2 `$C2xx`, Ch3 `$C3xx`, SFX `$C4xx` (fields up to `$4A`); globals from `$C14B` (as Die Maus) |
| Ranges | **`INSTR $85–$93` (15), `ARP $94–$AC` (25), `VOLENV $AD–$BC`, `LEN $BD–$EC` (1–48), `REPEAT $ED–$FF` (2–20)**; drum tempo bytes `$BD–$FE` |
| Tables | SFX `$7073` (56 entries), arpeggios `$6F5C` (set by `SndInit`), CH3 volume `$41BA`, drums `$49F3` |
| Counts | 9 songs (12 slots), 56 SFX, **1 instrument table** (`$6EB4`, 15 entries read), 1 arpeggio table (21 entries read), 18 waves, 11 drum sounds (10 used), 8 drum patterns |

`Sylvester_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over the whole of bank 15:

```
rgbasm -Wall -o sylvester.o Sylvester_SoundDriver.asm
rgblink -o sylvester.gb sylvester.o
python tools/cmp_banked.py sylvester.gb "Sylvester and Tweety (E) (M6) [C][!].gbc" 15:4000-7FFF
```

---

## 1. Game glue (bank 0)

The glue follows Die Maus's: the sound runs in the **timer interrupt** (`$0050` → `$03EC`).

- **Timer handler** (`$03EC`): switches to bank 15, then:
  1. if the song flag `$DBF2` is set, it calls the routine whose address is in `$DBF0/$DBF1` (through `jp hl` at `$154A`) and clears the flag;
  2. if `$FFDB` ≠ 0, it plays SFX `$FFDB` through `PlaySfxEntry` (`$4056`) and clears it;
  3. it calls `SndUpdate` (`$0422`, inside `di`/`ei`).
- **Tick rate:** TAC = `$04` (4096 Hz). The VBlank handler (`$1FCC`) reloads TIMA and TMA with `$D8` every frame while `$FF93` is set, so the timer fires **once per frame**, 40 counts (about 9.8 ms) after VBlank. While `$FF93` is clear, TMA is `$BB` (written at `$035D` and `$1A65`): the timer runs free at **59.36 Hz**, as in Die Maus (whose reload value is `$D0`).
- **Boot:** `SndInit` and `StopAll` are called through the far call `rst $08` (`$0350`, bank 15).
- **Requests:** the game writes an API address into the mailbox `$DBF0/$DBF1` and sets `$DBF2`. A level table at `$0466` holds song slots 2, 4, 9, 1, 5 (by the high nibble of `$DE88`); other code posts slots 3, 6, 7, **`SndPause` and `SndResume`** (unlike Die Maus, whose game never calls them), or `StopAll`.

`wStereo` (`$C14C`) is never written, so NR51 is `$FF` and the pan commands have no effect (as in Die Maus).

## 2. Differences from Die Maus

| | Die Maus | Sylvester and Tweety |
|---|---|---|
| Bank | 15 | 15 |
| `INSTR` / `ARP` | `$85–$92` / `$93–$AB` | **`$85–$93` / `$94–$AC`** |
| `VOLENV` / `LEN` / `REPEAT` | `$AC` / `$BC` / `$EC` (2–21) | **`$AD` / `$BD` / `$ED`** (2–20) |
| Drum tempo bytes from | `$BC` | `$BD` |
| `SndInit` arpeggio table / SFX table | `$6933` / `$6A4C` | `$6F5C` / `$7071` |
| VBlank timer reload | `$D0` | `$D8` |
| Pause / resume | never called | **called by the game** (mailbox) |
| Songs / SFX | 9 (12 slots) / 61 | 9 (12 slots) / 56 |

The range checks change in `ReadStream` (`$4308–$431F`), the `INSTR`/`ARP` offsets (`$433C`, `$4344`, `$4395`), the drum tempo test (`$49CF`, `$4A09`) and the look-ahead `PORTA` scan (`$4BDD`, `$4BE1`). `tools/v4diff.py` (with end `4C74`) shows nothing else.

Everything else is Die Maus's code: the look-ahead `PORTA`, `INSTR` stopping auto-duty and vibrato, Prisoners of the Sun's pause code, Lucky Luke's output and NR50 forcing, `NOTE_HOOK` and `SetVolEnvBC` present but unused.

### 2.1 Songs

| Song | Routine | Ch1 / Ch2 / Ch3 order lists | API slots | Length (ticks) |
|---|---|---|---|---|
| 1 | `$6B8E` | `$6BD5 / $6BC1 / $6BAD` | **1, 10, 11, 12** (via `$6B85`, §3.1) | loops |
| 2 | `$4C74` | `$4D03 / $4CDB / $4C93` | 2 | loops |
| 3 | `$55DC` | `$561F / $5613 / $55FB` | 3 | loops |
| 4 | `$5857` | `$58A6 / $588E / $5876` | 4 | loops |
| 5 | `$5D3D` | `$5D90 / $5D76 / $5D5C` | 5 | loops |
| 6 | `$613F` | `$617E / $616E / $615E` | 6 | loops |
| 7 | `$6445` | `$6474 / $646C / $6464` | 7 | loops |
| 8 | `$6605` | `$6628 / $6626 / $6624` | 8 | 414, ends |
| 9 | `$66EA` | `$675D / $6741 / $6709` | 9 | loops |

As in Die Maus, song 1 sits last in the bank and fills slots 1 and 10–12. Every song routine calls `StopAll` and then sets the one instrument table `$6EB4`; all use the arpeggio table from `SndInit`. Most routines start Ch3 first.

Data usage:

- Music has 27 `REPEAT`s, 23 `PAT_CALL`s, 399 `WAIT2`s, 8 `VIBRATO`s, 3 `AUTODUTY`s, 2 `PAT_GOTO`s and 6 `TRANSPOSE`s.
- Not used in the music: `PORTA`, `PORTA_OFF`, `FADE`, `NOTE_HOOK`, `CALL_CODE`, `DRUMS_OFF`, pan commands, `VOL`.

### 2.2 Sound effects

56 SFX on the CH3 page. They use `WAVE`, `LEN`, `LENGTH`, `VOLENV`, notes, `WAIT`, `REST`, `GLIDE`, `GLIDE_OFF`, `ARP`, `VIBRATO`, `CH_TRANSPOSE`, `RELEASE`, `REPEAT`, `CALL_CODE` (24, the noise part) and `END`. **SFX 13 uses `PORTA $02, $1E`**, the only `PORTA` in the bank. SFX 1–3 have the lengths of Die Maus's and Lucky Luke's SFX 1–3.

| Id | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 25 | 13 | 9 | 28 | 10 | 20 | 33 | 27 | 10 | 10 | 57 | 44 | 37 | 37 |

| Id | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 10 | 11 | 9 | 21 | 72 | 3 | 40 | 9 | 13 | 6 | 40 | 24 | 40 | 20 |

| Id | 29 | 30 | 31 | 32 | 33 | 34 | 35 | 36 | 37 | 38 | 39 | 40 | 41 | 42 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 16 | 13 | 28 | 30 | 6 | 12 | 13 | 9 | 45 | 10 | 10 | 10 | 15 | 10 |

| Id | 43 | 44 | 45 | 46 | 47 | 48 | 49 | 50 | 51 | 52 | 53 | 54 | 55 | 56 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 27 | 27 | 16 | 10 | 9 | 13 | 45 | 29 | 32 | 37 | 13 | 30 | 25 | 12 |

### 2.3 Noise

11 drum sounds; drum 2 = drum 8 (`$79BB`), drum 11 (`$7AB7`) is in the table but no pattern plays it:

| Drum | 1 | 2 = 8 | 3 | 4 | 5 | 6 | 7 | 9 | 10 | 11 |
|---|---|---|---|---|---|---|---|---|---|---|
| Routine | `$799E` | `$79BB` | `$79E7` | `$7A04` | `$7A21` | `$7A3E` | `$7A5B` | `$7A78` | `$7A9A` | `$7AB7` (unused) |

`CALL_CODE` noise routines (SFX only; one SFX also calls drum 5's routine): `$7427`, `$7494`, `$74D4`, `$7588`, `$75C4`, `$7604`, `$7631`, `$7662`, `$7684`, `$76CD`, `$7713`, `$7744`, `$776D`, `$779A`, `$77C9`, `$77FF`.

---

## 3. Quirks

### 3.1 Song slots 1 and 10–12 jump 9 bytes early

The four slots point at `$6B85`, not at song 1's routine (`$6B8E`). The 9 bytes in between are three tiny patterns that songs 2, 3 and 9 use from their order lists (`TRANSPOSE 2 / NEXT`, `TRANSPOSE 1 / NEXT`, `TRANSPOSE 0 / NEXT`); the song label was evidently placed in front of them. Run as code they are:

```
ld l, c / ld [bc], a / ld l, d / ld l, c / ld bc, $696A / nop / ld l, d
```

and execution falls through into song 1's routine. So the song still starts. The game does use slot 1 (level table `$046C`), and when it does, the timer handler calls the slot with A = `$40` and the interrupted code's BC: **`ld [bc], a` writes `$40` to whatever address BC holds** at that moment.

Die Maus also fills slots 1 and 10–12 with song 1, but there they point at the routine itself.

### 3.2 Other

1. **Panning is dead** (§1); no song uses the pan commands anyway.
2. Song 8 is the only one-shot (414 ticks).
3. **Unreferenced (marked in the asm):**
   - `SetVolEnvBC` (`$436E`, 39 bytes, left as data), stray `ret`s at `$4413` and `$4B69`;
   - zeros before the period table (`$4786`, 122 bytes);
   - two noise routines `$7510` and `$7539` (they set `wDrumHold` 8 / 10 and an NR43/NR42 sequence; nothing calls them) and drum 11;
   - a stray `NEXT` byte after a `PAT_GOTO` (`$5F3E`), two unused SFX stream fragments (`$71C0`, `$73BE`);
   - unused arpeggio table entries and arpeggio data (`$6F86`, `$7034`), noise-table pieces (`$75BB`, `$7601`, `$76CC`, `$7701`);
   - the end text and the zeros after it (`$7AFA`).

## 4. Verification (lighter)

- **Byte-exact rebuild** of bank 15 (`tools/cmp_banked.py`).
- **Emulator trace** (`verify/v4trace.py`): songs 1–9 (6000 ticks each) and SFX 1–56, **0 problems** (`verify/run_v4.log`). The lengths above come from this run. The harness starts song 1 at `$6B8E`, not through the early slot.
- **Code comparison** with Die Maus: `tools/v4diff.py … 4C74` shows only the range constants and table addresses.
- **Glue:** the timer handler, the VBlank reload and the request mailbox were read from the bank-0 code; the tick rate was not measured in an emulator run.
- Not done: no independent model.

## Files (in `GBAudioLab\AJG`)

- `Sylvester_SoundDriver.asm`: labelled, commented RGBDS source (names carried along The Smurfs → Obélix GBC → Spirou → Lucky Luke → Die Maus), byte-exact
- shared version-4 tools and verification: see `Smurfs_SoundDriver.md`

Regenerate: `python tools/gen_v4.py sylvester "Sylvester and Tweety (E) (M6) [C][!].gbc" Sylvester_SoundDriver.asm`.
