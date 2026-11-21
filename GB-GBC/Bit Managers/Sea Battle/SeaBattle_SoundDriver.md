# Sea Battle (GB): sound driver

ROM: `Sea Battle (E) (M4).gb` (DMG, MBC1, 128 KB, internal title `SEA BATTLE`).

Part of the AJG family (Alberto José González / Bit Managers), see `AJG_SoundEngine_Family.md`. This is **version 4**, documented in full in `Smurfs_SoundDriver.md`.

**The driver is The Smurfs' Nightmare's** (`Smurfs3_SoundDriver.md`, Lucky Luke group). The bank even carries the same version string, `GBS 3.4 (C) 1990 - 1997 Alberto Jose Gonzalez & Bit Managers S.L.` at `$4B23`. Sea Battle changes two things:

- **the RAM moves up one page**, to pages `$DC–$DF` and globals `$DC42` (the Prisoners of the Sun group's addresses), instead of `$DB–$DE` / `$DB42`;
- **`StopAll` sets a default instrument table** (`wInstrTable` = `$543B`) before silencing, as in Hugo 2.

Everything else is The Smurfs' Nightmare's code, including:

- Lucky Luke's command set and ranges;
- the single NRx4 write;
- NR50 forcing;
- the Smurfs-style pause;
- `INSTR` stopping auto-duty.

| | |
|---|---|
| Bank | the driver and all its data in **ROM bank 4** (`$4000–$6110`). The bank ends with `Final de la rutina de musicaicaicaica` (`$60EC`) and 7919 bytes of PC memory garbage. |
| Command table | `$4000` (37 commands, `$60–$84`, Spirou's set with `NOTE_HOOK $84`) |
| API jump table | `$404A`: `SndUpdate $40E6`, `SndPause $40A2`, `SndResume $409B`, `StopAll $453D`, `PlaySfx $491A`, `SndInit $4522`, `SongFadeIn $495D`, `SongFadeOut $4957`, **18 song slots** (`$4062–$4095`: 5 songs, then 13 dead slots), `PlaySfxNow $491D` (`$4098`) |
| `StartMusicCh1/2/3` | `$48F0` / `$48F4` / `$48F8` (4 bytes apart, as in The Smurfs' Nightmare) |
| Tick | VBlank, once per frame (59.73 Hz) |
| RAM | pages Ch1 `$DCxx`, Ch2 `$DDxx`, Ch3 `$DExx`, SFX `$DFxx` (fields `$00–$41`); globals **`$DC42–$DC65`** |
| Ranges | `INSTR $85–$93` (15), `ARP $94–$AF`, `VOLENV $B0–$BF`, `LEN $C0–$EF` (1–48), `REPEAT $F0–$FF` (2–17); drum tempo bytes `$C0–$FE` (as Lucky Luke) |
| Tables | SFX `$5576` (13 entries), arpeggios `$54BD` (set by `SndInit`), one instrument table `$543B` (15 entries read, from `$543D`), CH3 volume `$41CE`, drums `$49F3` (10) |
| Counts | 5 songs, 13 SFX, 7 waves, 10 drum sounds + 7 noise routines called with `CALL_CODE`, 6 drum patterns |

`SeaBattle_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over the whole of bank 4:

```
rgbasm -Wall -o seabattle.o SeaBattle_SoundDriver.asm
rgblink -o seabattle.gb seabattle.o
python tools/cmp_banked.py seabattle.gb "Sea Battle (E) (M4).gb" 4:4000-7FFF
```

---

## 1. Game glue (bank 0)

The VBlank handler (`$0040` → `$2BFD`) calls `$2BC7`, which switches to bank 4 and does the following:

- **Songs:** if the mailbox `$C80B/$C80C` holds a routine address, it is cleared and called (through `$304F`).
- **SFX:** if the queue count `$C804` is not 0, it is decremented and the queued id at `$C805 + count` goes to `PlaySfx` (API `$4056`). That is one SFX per frame.
- **Update:** then `SndUpdate`.

It is the same shape as Turok's handler. Bank 0 also calls `SndInit` (`$0196`) and `StopAll` (`$0199`). No other API entry is called directly.

`wStereo` (`$DC43`) is never written, so NR51 stays `$FF`. The data has no pan commands anyway: no `PAN_C/R/L`, no `AUTOPAN`, no drum-pattern pan bytes.

## 2. Differences from The Smurfs' Nightmare

| | The Smurfs' Nightmare | Sea Battle |
|---|---|---|
| Bank | 2 | **4** |
| Pages / globals | `$DB–$DE` / `$DB42` | **`$DC–$DF` / `$DC42`** (every `ld h, page` and `cp page` in the code moves up by 1) |
| `StopAll` (`$453D`) | silence, reset the pages | **first sets `wInstrTable` = `$543B`**, then as before. `SndInit` falls through into it. |
| `SndInit` arpeggio table | `$75DF` | `$54BD` |
| `PlaySfx` table base (`$4944`) | `$7696` | `$5574` |
| Song slots | 18, all songs | 18: **5 songs, slots 6–18 are `jp $53A9`** (pattern data: `TRANSPOSE 0`, `NEXT`), never called |

The four extra bytes in `StopAll` shift the code from `$453D` to `$48F0` by 10 bytes. From `StartMusicCh1` on, the addresses are The Smurfs' Nightmare's again.

Every song routine calls `StopAll`, then sets `wInstrTable` = `$543B` itself (the same value), then starts its channels. So the whole game uses one instrument table.

## 3. Songs and data notes

- **Song 1 has no CH2:** its routine starts only `StartMusicCh1` and `StartMusicCh3`. All five songs loop.
- **Dead song slots 6–18:** `jp $53A9`, a 3-byte pattern (`TRANSPOSE $00`, `NEXT`) inside song 1's data. They are labelled and commented in the asm.
- **Unreferenced SFX material (1817 bytes in 26 ranges, `$5549–$6092`):** SFX streams and noise-SFX starter routines that no table entry reaches. They are not stray bytes from another game. The streams use this bank's own addresses: for example `CALL_CODE $5A0D`, a noise routine that SFX 1 also calls. The routines write this build's globals (`$DC47`, `$DC57–$DC5C`). So they look like effects dropped from the SFX table, which now has 13 entries.
- Other unreferenced ranges: `SetVolEnvBC` (`$4372`, 39 bytes, as in The Smurfs' Nightmare), a few small ranges next to the instrument, arpeggio and SFX tables, and the bank tail.

## 4. Verification

`verify/v4trace.py` runs the real driver from the ROM in PyBoy and checks every song and SFX against the data walk at every tick. Result: 18 tests, 30 368 ticks, **0 problems** (`verify/run_v4.log`).

## 5. Files

- `SeaBattle_SoundDriver.asm`;
- entries `seabattle` in `tools/v4cfg.py` and `tools/v4games.py`. Names are carried from The Smurfs' Nightmare (`ref='smurfs3'`); `StopAll` and `StartMusicCh1/2/3` are named explicitly, because the alignment does not carry them across the changed `StopAll`.

Regenerate with `python tools/gen_v4.py seabattle "Sea Battle (E) (M4).gb" SeaBattle_SoundDriver.asm`.
