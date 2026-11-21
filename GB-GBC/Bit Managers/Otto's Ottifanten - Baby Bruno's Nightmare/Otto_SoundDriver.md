# Otto's Ottifanten: Baby Bruno's Nightmare (GB): sound driver

ROM: `Otto's Ottifanten (E).gb` (DMG, MBC1, 256 KB, internal title `OTTIFANTEN`).

Part of the AJG family (Alberto José González / Bit Managers), see `AJG_SoundEngine_Family.md`. This is **version 4**, documented in full in `Smurfs_SoundDriver.md`.

**The driver code is Die Maus's** (`Maus_SoundDriver.md`), instruction for instruction. That includes:

- the look-ahead `PORTA step, lead` / `PORTA_OFF`, and `NOTE_HOOK` at `$82`;
- no `SLIDE_UP`/`SLIDE_DOWN`;
- Prisoners of the Sun's pause model;
- pages `$C1–$C4` and globals `$C14B`;
- `INSTR` stopping vibrato and auto-duty;
- the timer tick.

Only three constants in the code differ: the arpeggio table that `SndInit` sets, the SFX table address, and the bank (3 instead of 15). So Otto's Ottifanten belongs to the Lucky Luke group, on the Die Maus line.

The game is the finished form of the cancelled 1993 *Adventures of Pinocchio* prototype (`Pinocchio_SoundDriver.md`, version 3). The final game does not keep the prototype's version-3 driver: it was rebuilt on the current version-4 driver. Five of its six songs are Pinocchio's songs converted to the version-4 format (§3).

| | |
|---|---|
| Bank | the driver and all its data fill **ROM bank 3** (`$4000–$719F`; then 3680 bytes of leftovers to the end of the bank, mostly PC memory garbage with Windows paths such as `C:\WINDOWS\EXPLORER.EXE`) |
| Command table | `$4000` (37 commands, `$60–$84`, Die Maus's set: `NOTE_HOOK $82`, `PORTA $83`, `PORTA_OFF $84`) |
| API jump table | `$404A`: `SndUpdate $40C9`, `SndPause $4090`, `SndResume $4089`, `StopAll $4516`, `PlaySfx $491A`, `SndInit $44FB`, `SongFadeIn $495D`, `SongFadeOut $4957`, **12 song slots** (`$4062–$407D`: 6 songs, then 6 dead slots), `PlaySfxNow $491D` (`$4080`) |
| Tick | timer interrupt, re-synchronised to VBlank every frame: once per frame (§1) |
| RAM | pages Ch1 `$C1xx`, Ch2 `$C2xx`, Ch3 `$C3xx`, SFX `$C4xx` (fields `$00–$4A`); globals `$C14B–$C16E` (as Die Maus) |
| Ranges | `INSTR $85–$92` (14), `ARP $93–$AB` (25), `VOLENV $AC–$BB`, `LEN $BC–$EB` (1–48), `REPEAT $EC–$FF` (2–21); drum tempo bytes `$BC–$FE` (as Die Maus) |
| Tables | SFX `$6D61` (25 entries), arpeggios **`$6962`** (set by `SndInit` and by every song except song 4), CH3 volume `$41BA`, drums `$49F3` (9) |
| Counts | 6 songs, 25 SFX, 2 instrument tables (`$6886`: 14 entries read, `$6918`: 6), 1 arpeggio table, 16 waves, 9 drum sounds + 7 noise routines called with `CALL_CODE`, 18 drum patterns |

`Otto_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over the whole of bank 3:

```
rgbasm -Wall -o otto.o Otto_SoundDriver.asm
rgblink -o otto.gb otto.o
python tools/cmp_banked.py otto.gb "Otto's Ottifanten (E).gb" 3:4000-7FFF
```

---

## 1. Game glue (bank 0)

The sound runs in the **timer interrupt** (`$0050` → `$0255`), as in Die Maus. The handler does the following:

- **SFX:** if `$FFF2` holds an id, it switches to bank 3, calls `PlaySfx` (API slot 4), switches back to bank 1 and clears `$FFF2`.
- **Update:** it calls `$0278`, which switches to bank 3, calls `SndUpdate` with interrupts off, and restores the bank from `$FFF7`.

The timer runs at 4096 Hz (TAC = `$04`):

- **Normally:** the VBlank handler (`$1660`) reloads TIMA and TMA with `$D0` while `$FF93` is set. The timer then fires once per frame, 48 counts (about 11.7 ms) after VBlank.
- **While `$FF93` is clear:** TMA is `$BB` (set at `$01DD`), so the timer runs free at 4096 / 69 = **59.36 Hz**.

This is the same model as Die Maus.

Bank 0 calls the API directly:

- `SndPause` (`$1767`) and `SndResume` (`$17F0`), so **the pause code is used here**, unlike in Die Maus;
- `StopAll`, `SndInit`, and songs 1, 5 and 6 by their slots;
- other songs through tables.

`wStereo` (`$C14C`) is never written, so NR51 stays `$FF`. **The pan commands in the data have no effect.** There are only two of them, both `AUTOPAN`; there are no `PAN_C/R/L` and no drum-pattern pan bytes.

## 2. Differences from Die Maus

| | Die Maus | Otto's Ottifanten |
|---|---|---|
| Bank | 15 | **3** |
| `SndInit` arpeggio table | `$6933` | **`$6962`** |
| `PlaySfx` table base (`$4944`) | `$6A4C` | **`$6D5F`** |
| Song slots | 12 (9 songs; slots 1 and 10–12 start song 1) | 12 (**6 songs; slots 7–12 are `jp $6888`**, the start of instrument table 1, never called) |
| Song routines | set `wInstrTable` only (song 1 sets nothing) | set `wInstrTable` **and `wArpTable`** (the same `$6962` as `SndInit`; song 4 sets only `wInstrTable`) |
| `PORTA` use | SFX 21 only | **songs 1, 2, 3, 5 and 6** (15 `PORTA` commands in patterns, mostly on CH3) and SFX 7, 11, 15 |
| Pause / resume | as Prisoners of the Sun, never called | as Prisoners of the Sun, **called by the game** |

Everything else, including the command table, ranges, RAM layout, CH3 volume table and drum table addresses, is unchanged. `tools/v4diff.py` finds no other difference in the code.

## 3. Music: Pinocchio's songs

Five of the six songs are the 1993 prototype's songs. Their patterns have the same note sequences as Pinocchio's (compared transposition-free, pattern by pattern):

| Otto's Ottifanten | Pinocchio prototype |
|---|---|
| Song 1 | Song 1 (30 matching patterns) |
| Song 2 | Song 3 |
| Song 3 | Song 4 |
| Song 4 | – (new) |
| Song 5 | Song 5 |
| Song 6 | Song 2 |

The patterns were re-encoded for version 4. Commands, instruments, envelopes and drum patterns were all rewritten (version 3 has `ORDER_JUMP` and its own byte values), and `PORTA` was added in places. The notes, as well as the pattern boundaries of the matching patterns, stayed the same.

## 4. Data notes

- **Dead song slots 7–12:** `jp $6888` (instrument table 1, the first entry). They are labelled `InstrTable1` in the asm and commented as never called.
- **Unreferenced ranges** (18):
  - the unreferenced `SetVolEnvBC` (`$436E`, 39 bytes, as in Die Maus) and a block of 122 zero bytes (`$4786`);
  - order-list terminators of one-shot channels (`dw 0, loop`, never read because the pattern ends with `END`);
  - a few unused arpeggio, drum, noise and wave bytes;
  - the leftovers after `$71A0`.
- Song 5 is the only song that ends (after 1370 ticks); the others loop.

## 5. Verification

`verify/v4trace.py` (as for the other version-4 builds) runs the real driver from the ROM in PyBoy and checks every song and SFX against the data walk at every tick (stream pointers, order positions and drum-pattern positions on walked items). Result: 31 tests, 32 769 ticks, **0 problems** (`verify/run_v4.log`).

## 6. Files

- `Otto_SoundDriver.asm`;
- entries `otto` in `tools/v4cfg.py` and `tools/v4games.py`. Names are carried from Die Maus (`ref='maus'`).

Regenerate with `python tools/gen_v4.py otto "Otto's Ottifanten (E).gb" Otto_SoundDriver.asm`; `verify/run_v4.sh` rebuilds and checks all sixteen version-4 builds.
