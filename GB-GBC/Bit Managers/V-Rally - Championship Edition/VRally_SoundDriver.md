# V-Rally: Championship Edition (GB and GBC): sound driver

ROMs:

- `V-Rally - Championship Edition (U) (M3) [M][!].gb` (DMG, MBC1, 256 KB, internal title `VRALLY`). Sound bank **2**.
- `V-Rally - Championship Edition (E) (M4) [C][!].gbc` (GBC-compatible, also runs on DMG; MBC5, 1 MB, internal title `VRALLY`). Sound bank **16**.

Part of the AJG family (Alberto José González / Bit Managers), see `AJG_SoundEngine_Family.md`. This is **version 4**, documented in full in `Smurfs_SoundDriver.md`. The bank names the driver twice:

- `1998 by Alberto Jose Gonzalez.` right after the period table (`$48A2`);
- `(Music & Sound Driver by Alberto Jose Gonzalez, 1998)` right after the driver code (GB `$4B60`, GBC `$4B63`).

**The driver is Turok's** (`Turok_SoundDriver.md`, Prisoners of the Sun group), with Turok's ranges (+2 instruments) and these features:

- `StartMusicChN` 14 bytes apart, each setting the one instrument table;
- the early exit in `CheckRelease`;
- Prisoners of the Sun's output, pause and NR50 model.

V-Rally changes the following:

- **RAM at Lucky Luke's addresses:** pages `$DB–$DE`, globals `$DB42`;
- **no `PlayCh1Tone`**;
- the date text after the period table, which shifts the rest of the code by 30 bytes;
- a **game hook in `SndUpdate`:** while the race-engine sound is on (`$DC91` ≠ 0), `SndUpdate` runs the game's engine routine instead of the music (§2);
- **`StopAll` also calls `EngineStop`**;
- 14 extra API entries for the engine sound, placed before the song slots.

The **GBC release has a GBC revision of this driver** (§3), in the manner of Astérix & Obélix GBC:

- duty shadows written every tick;
- NR31 writes;
- NR10 cleared in `StopAll`.

Turok 2 kept the DMG driver on the GBC; V-Rally does not.

| | GB | GBC |
|---|---|---|
| Bank | 2: driver, engine code and data `$4000–$5F1F`; the rest of the bank is other game data | 16: `$4000–$5FDA`, then other data |
| Command table | `$4000` (37 commands, `$60–$84`, with `NOTE_HOOK`) | as GB |
| API jump table (`$404A`) | `SndUpdate $40F6`, `SndPause $40BD`, `SndResume $40B6`, `StopAll $4556`, `PlaySfx $4952`, `SndInit $453B`, `SongFadeIn $4995`, `SongFadeOut $498F`; **14 engine entries** (`$4062–$4089`, §2); **13 song slots** (`$408C–$40B0`: 7 songs, 6 dead); `PlaySfxNow $4955` (`$40B3`) | as GB, but `StopAll $4565`, `SndInit $454A`; 13 song slots: **8 songs**, 5 dead |
| `StartMusicCh1/2/3` | `$490E` / `$491C` / `$492A`, each sets `wInstrTable` = `$5BCB` | as GB, `$5C6C` |
| Tick | the game's frame loops call `SndUpdate` (through `$2A91` in bank 0, from 10 places) | as GB (`$2A60`) |
| RAM | pages Ch1 `$DBxx`, Ch2 `$DCxx`, Ch3 `$DDxx`, SFX `$DExx`; globals `$DB42–$DB65`; engine variables `$DC80–$DC95` (inside Ch2's page, above the driver's fields) | as GB, plus duty shadows `$DB66/$DB67` |
| Ranges | `INSTR $85–$97` (19), `ARP $98–$B3`, `VOLENV $B4–$C3`, `LEN $C4–$F3` (1–48), `REPEAT $F4–$FF` (2–13); drum tempo bytes `$C4–$FE` (as Turok) | as GB |
| Tables | instruments `$5BCB` (16 entries read, from `$5BCD`), arpeggios `$5C45` (set by `SndInit`), SFX `$5D35` (2), CH3 volume `$41E5`, drums `$4A30` (9) | instruments `$5C6C`, arpeggios `$5CF0`, SFX `$5DE0` (2), CH3 volume `$41F2`, drums `$4A30` (9) |
| Counts | 7 songs, 2 SFX, 2 waves, 9 drum sounds, 11 drum patterns; no `CALL_CODE` | 8 songs, 2 SFX, 3 waves, 9 drum sounds, 12 drum patterns |

Both rebuild **byte-exact** with RGBDS 0.9.1 over the whole sound bank:

```
rgbasm -Wall -o vrally.o VRallyGB_SoundDriver.asm
rgblink -o vrally.gb vrally.o
python tools/cmp_banked.py vrally.gb "V-Rally - Championship Edition (U) (M3) [M][!].gb" 2:4000-7FFF

rgbasm -Wall -o vrallygbc.o VRallyGBC_SoundDriver.asm
rgblink -o vrallygbc.gb vrallygbc.o
python tools/cmp_banked.py vrallygbc.gb "V-Rally - Championship Edition (E) (M4) [C][!].gbc" 16:4000-7FFF
```

---

## 1. Game glue (bank 0)

The interrupt vectors at `$0040`/`$0048`/`$0050` are plain `reti`. The sound is driven from the game's frame loops, like Lucky Luke. Bank 0 has a row of small wrappers (GB `$2A86–$2B8x`, GBC `$2A55–$2B5x`), each of which switches to the sound bank and enters one API slot:

- **Songs:** the song wrapper (`$2A86`) calls `SndInit` and then jumps to the song routine whose address is in HL. Songs are started by address, not by slot.
- **Other wrappers:** `SndUpdate`, `StopAll`, `PlaySfx`, `SongFadeOut` and most of the engine entries (§2).

`wStereo` (`$DB43`) is never written, so NR51 stays `$FF`. The music has no pan commands.

## 2. The race-engine sound (game code in the sound bank)

The car sound in a race does not use the music driver. It is a separate set of routines placed after the driver (GB `$4B95–$4DED`, `$4EEC`; GBC +3 to +12 bytes). They write the sound registers directly, and their own variables are at `$DC80–$DC95`. `EngineStart` sets `$DC91`, and while it is set, **`SndUpdate` jumps straight to `EngineUpdate`**. So neither music nor SFX are ticked during a race.

| API slot (GB / GBC target) | Name | What it does | Called from bank 0 |
|---|---|---|---|
| `$4062` (`$4C36` / `$4C39`) | `EngineStart` | NR52 = `$FF`, NR51 = `$FF`, NR50 = `$FF` (GBC: `$77`); seeds; CH2 duty 75 %; silences all channels; `$DC91` = 1; loads wave B | yes |
| `$4065` (`$4CDF` / `$4CEA`) | `EngineUpdate` | base CH3 period = rpm (`$DC87`) × 8, then `EngineTick` | yes (and from `SndUpdate`) |
| `$4068` (`$4CF0` / `$4CFB`) | `EngineTick` | see below | – |
| `$406B` / `$406E` | `EngineWaveA` / `EngineWaveB` | switch the CH3 wave (only if the other one is loaded); CH3 volume `$20` | yes |
| `$4071`, `$4074`, `$4077` | `EngineHit2`, `EngineHit1`, `EngineHit3` | CH1 one-shot: NR11/NR12/NR14 written directly (envelopes `$70`, `$A0`, `$90`), and a new seed for CH1's random pitch | `EngineHit2` and `EngineHit3` |
| `$407A` | `EngineCh1Off` | NR12 = 0 | yes |
| `$407D`, `$4080`, `$4083` | `EngineNoise3`, `EngineNoise1`, `EngineNoise2` | start a CH4 sequence: an NR43 table and an NR42 table, one step per tick, `$FF` ends (in the NR42 table: no write) | no direct call found |
| `$4086` | `EngineCh2Seq` (A = id) | start one of 3 CH2 tone sequences (table GB `$4DEE`, GBC `$4DFA`) | yes |
| `$4089` | `EngineStop` | silence, clear `$DC91`, `$DC93`, `$DC8C`; also called by `StopAll` | yes |

**`EngineTick`** does three things every tick:

- **CH3 drone:** the base period plus a pseudo-random 0–31 (`EngineRandCh3`: add `$0E`, xor `$4D`), written to NR33/NR34. The trigger is set only when the high bits change.
- **CH1 rumble:** NR13 = `$FA` + a pseudo-random 0–31 (`EngineRandCh1`: add `$0D`, xor `$65`).
- **Sequences:** one step of the CH2 sequence and one of the noise sequence.

**The CH2 sequences reuse the driver's stream bytes:**

- notes `$00–$5F` are looked up in the driver's period table at `$4800` (NR22 = `$C3`);
- `$C4`+ sets the length;
- `$65` is `WAIT`, `$66` is `REST` and `$68` is `END`;
- other bytes are skipped.

The two **engine waves** are GB `$4F08` and `$4F18` (GBC `$4F14`, `$4F24`). The 10 bytes after wave B are unreferenced leftover code: `ld a, [$DC91] / and a / jp z, $4062 / jp $4089`, an older form of the engine hook.

There is also an unreferenced stub, `ld a, 0 / jp EngineCh2Seq` (GB `$4F03`).

## 3. Differences from Turok, and GB vs GBC

| | Turok | V-Rally GB | V-Rally GBC |
|---|---|---|---|
| Pages / globals | `$DC–$DF` / `$DC42` | **`$DB–$DE` / `$DB42`** | as GB |
| `PlayCh1Tone` | API slot after `SongFadeOut` | **gone** (engine entries instead) | gone |
| After the period table | code | **`1998 by Alberto Jose Gonzalez.`** (code from `StartMusicCh1` on is 30 bytes later) | as GB |
| `SndUpdate` | pause test, then the pages | **`$DC91` test first → `EngineUpdate`** | as GB |
| `StopAll` | `SndResume`, silence | `SndResume`, **`EngineStop`**, silence | also **NR10 = `$08`** (sweep off) |
| Duty (`SetDuty`, `INSTR`) | NR11/NR21 directly | as Turok | **shadows `$DB66`/`$DB67`**, written to NR11/NR21 by the pulse output every tick (as Astérix & Obélix GBC) |
| NR31 | | | **NR31 = 0** in `OutputWaveCh` and `RestoreMusicWave` (as Astérix & Obélix GBC; no NR41 write) |
| `SndInit` | | arpeggio table `$5C45` | `$5CF0` |
| Drum table | 10 entries | **9** | 9 |
| Song slots | 13 songs | 7 songs + 6 × `jp $5BCD` (the first instrument-table entry; never called) | 8 songs + 5 × `jp $5C6E` |
| SFX | 39 | **2** | 2 |

Unchanged from Turok:

- the `CheckRelease` early exit;
- the 14-byte `StartMusicChN` that sets the one instrument table (every song routine also calls `StopAll` and sets the same table itself);
- the pause model;
- no SFX priority;
- the `HwEnvAtten` stub;
- the unreferenced `SetVolEnvBC`.

**GB vs GBC music:** the GBC bank carries the GB music data unchanged; only the pointers move by 12 bytes. It adds **song 8** (slot `$40A1`, a one-shot of 301 ticks). The GBC engine code differs only in its output:

- `EngineStart` writes NR50 = `$77`, not `$FF`;
- the wave loader also clears NR31 and stores `$80` in `$DC84` (the last NR34 high bits), which makes the next `EngineTick` retrigger CH3.

## 4. Data notes

- **One-shot songs:** 3 (177 ticks), 5 (448), 6 (896) and, on the GBC, 8 (301); the others loop. Their order lists keep the `dw 0, loop` terminators, which are never read (unreferenced, 4 bytes each).
- **Unreferenced:**
  - the arpeggio table holds 22 more pointers than the songs use, plus 139 bytes of unused arpeggios;
  - a noise-SFX starter routine (`$5ED3`, 29 bytes) and 24 bytes of noise-table data after it;
  - one `ret` after some song routines;
  - `SetVolEnvBC`.
- The pan, slide, hook and `CALL_CODE` commands are not used by any song or SFX.

## 5. Verification

`verify/v4trace.py` runs the real driver from each ROM in PyBoy and checks every song and SFX against the data walk at every tick. Results (`verify/run_v4.log`):

- GB: 9 tests, 27 380 ticks, **0 problems**;
- GBC: 10 tests, 28 282 ticks, **0 problems**.

The harness never sets `$DC91`, so the engine routines are covered by the byte-exact rebuild only.

## 6. Files

- `VRallyGB_SoundDriver.asm` and `VRallyGBC_SoundDriver.asm`;
- entries `vrally` and `vrallygbc` in `tools/v4cfg.py` and `tools/v4games.py`. Names are carried from Turok (`ref='turok'`), then GB → GBC. The engine routines, engine tables, `StopAll` and `StartMusicCh1/2/3` are named explicitly.

Regenerate with `python tools/gen_v4.py vrally|vrallygbc <rom> <asm>`.
