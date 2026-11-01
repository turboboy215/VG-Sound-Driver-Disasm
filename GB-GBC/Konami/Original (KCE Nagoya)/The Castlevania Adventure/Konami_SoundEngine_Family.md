# Konami GB sound engine family (original driver)

A running overview of Konami's in-house Game Boy sound driver across games. Each game has its own doc with the details, and this page tracks what's shared and what changes. Covered so far: **The Castlevania Adventure** and **Motocross Maniacs** (session 1, 1989), **Nemesis** (1990) and **Castlevania II: Belmont's Revenge** (1991) (session 2), **Blades of Steel**, **Nemesis II: The Return of the Hero** and **TMNT II: Back from the Sewers** (1991) (session 3), **Ganbare Goemon: Sarawareta Ebisumaru!** (1991) and **Tiny Toon Adventures: Babs' Big Break** (1992) (session 4).

| Game | ROM | Variant | Driver location | Ids | Doc / asm |
|---|---|---|---|---|---|
| The Castlevania Adventure | `Castlevania Adventure, The (E) [!].gb` | early, 6-track, working copy | bank 2 `$4000–$663E` | 49 | `CastlevaniaAdventure_SoundDriver.md`, `CVA_SoundDriver.asm` |
| Motocross Maniacs | `Motocross Maniacs (E) [!].gb` | early, 7-track, in place | `$6576–$7FFF` | 32 | `MotocrossManiacs_SoundDriver.md`, `MM_SoundDriver.asm` |
| Nemesis | `Nemesis (E) [!].gb` | later, timer | bank 7 `$4000–$7404` | 57 | `Nemesis_SoundDriver.md`, `NEM_SoundDriver.asm` |
| Castlevania II: Belmont's Revenge | `Castlevania II - Belmont's Revenge (U) [!].gb` | later, VBlank | bank 7 `$4000–$7FFF` | 107 | `CastlevaniaII_SoundDriver.md`, `CV2_SoundDriver.asm` |
| Blades of Steel | `Blades of Steel (E) [!].gb` | later, VBlank + glide | bank 7 `$4000–$6C2E` | 51 | `BladesOfSteel_SoundDriver.md`, `BOS_SoundDriver.asm` |
| Nemesis II: The Return of the Hero | `Nemesis II - The Return of the Hero (E) [!].gb` | **third generation**, 128 Hz, 3 banks | ROM0 + banks 13–15 | 140 | `NemesisII_SoundDriver.md`, `N2_SoundDriver.asm` |
| TMNT II: Back from the Sewers | `Teenage Mutant Hero Turtles - Back from the Sewers (E) [!].gb` | **fourth generation**, 256 Hz, 2 banks, PCM | ROM0 + banks 14–15 | 205 + 4 PCM | `TMNT2_SoundDriver.md`, `TM2_SoundDriver.asm` |
| Ganbare Goemon: Sarawareta Ebisumaru! | `Ganbare Goemon (J).gb` | fourth generation **extended**, 256 Hz, one code copy for 3 banks | ROM0 + bank 14 (data 13–15) | 185 | `GanbareGoemon_SoundDriver.md`, `GG_SoundDriver.asm` |
| Tiny Toon Adventures: Babs' Big Break | `Tiny Toon Adventures - Babs' Big Break (E) [!].gb` | third generation **reworked**, VBlank, 1 bank | bank 7 `$4000–$4E14` | 99 | `TinyToon_SoundDriver.md`, `TT_SoundDriver.asm` |

## Generations

1. **Early** (CVA, MM): 64 Hz timer, CVA on a working copy, MM in place.
2. **Later** (Nemesis, Belmont's Revenge, Blades of Steel): MM's code reorganised; same command language. Belmont's Revenge moves to VBlank; Blades of Steel is Belmont's Revenge plus a glide.
3. **Third** (Nemesis II): the track code reshuffled and copied into each of three sound banks, a 128 Hz timer with the music at half rate, a new flow syntax and a new vibrato command.
   - **Tiny Toon** reworks it: Nemesis II's track page, requests, shadows and table formats on VBlank in one bank, but with the generation 1–2 flow commands back, a `$D0–$DF` command block, a shadowed `WriteReg` for every register, envelope tables, and some serious bugs (the fade's stops break the stack, a refusal leaves the request flag set).
4. **Fourth** (TMNT II): a rewrite that keeps the third generation's data ideas but changes the code, the track layout and the update scheme, and adds PCM.
   - **Ganbare Goemon** is TMNT II's track code with additions (volume envelopes, a working duty step, a counted jump, raw-frame slides and repeats) and a single copy of the code reading streams from three banks through a ROM0 buffer; no PCM.

## What's shared (generations 1–2)

- **Sound ids** index a pointer table of headers `db priority, track mask` + one `dw` per mask bit. Id 0 = stop everything. A track is taken when the new priority ≥ the track's current priority.
- **Fixed track roles:** CH1 SFX, CH4 (noise) SFX, music CH1/CH2/CH3 and a **drum track** whose notes start sound ids through a drum map; from MM on also a CH2 SFX track. A music channel keeps running silently while its SFX track has the channel.
- **The same command language** ($00–$DF notes with pitch/length nibbles, `$E0` voice, `$E1–$E6` octave, `$E7–$EF` table, `$F0–$FA` attenuation, `$FB–$FF` flow with **a single return slot**), the same vibrato table format, the same period values, the same envelope model (volume-only attack, release at a gate fraction, software decay for CH3).
- **Shadowed register writes** (skip if unchanged unless forced) and NRx4 = shadow | `$80` triggers.
- Persisting quirks: NR51/NR10 are set even when the priority test fails, fields above the cleared area persist across sounds, the CH3 decay sets NR32 bit 4, `$EB`/`$EC` are no-ops, and the music uses "call as goto" so streams have to be followed by simulating the reader state (`tools/kdata.py` `walk_stream`).

The third and fourth generations keep: the header format, the seven track roles (TMNT II moves the second SFX track to CH3), notes with pitch/length nibbles, `$E0`/`$E1–$E6`/`$E7`/`$E8`/`$E9`/`$EE`/`$F0+` in their old places, and an 85-entry-style period table. Their flow commands change: `$FB`/`$FC` become paired loop markers (the first met marks, the next one `FB n` loops), `$FD addr` calls and a bare `$FD` returns, `$FE` marks and then jumps back forever, `$FF` ends; TMNT II adds `$FA addr` (jump). Vibrato steps become one byte (time, negate, offset × depth).

## Lineage

- **Early (CVA, MM).** CVA works on a copy of each 6-track slot and runs music at half rate; MM has 7 tracks in place at `$C0xx`, full-rate music, and game-specific extras (engine pitch, course follow-up).
- **Nemesis** is MM's code reorganised: MM's engine-sound check is still in it, unreachable (`$41F3`). Tracks move to `$C180 + n×$100`, MM's extras are gone, and it adds a **fade-out**, a **lockout timer** that refuses all requests for the first seconds of five songs, and **follow-up songs** at the end of three ids.
- **Belmont's Revenge** continues from Nemesis: driven by **VBlank** (59.7 Hz) instead of the 64 Hz timer, `$37`-byte tracks at `$C080 + n×$100`, `PAN` keeps a raw NR51 byte per track, new `$ED` **duty step**, a request **aborts part-way** when a track refuses it (with a stale-flag bug), no lockout or follow-ups, a shorter (85-entry) period table.
- **Blades of Steel** is Belmont's Revenge's driver at the same entry points with a **glide** (`EA 5n`, sliding to the next note, found by a look-ahead parser; implemented but unused by the data, and buggy: the tail of the track tick runs two or three times while it's on), **Nemesis-style `PAN`/autopan** again, a non-sticky vibrato negate, and a 16-tick fade step with a stop path.
- **Nemesis II** keeps Belmont's Revenge's request groups (and the stale refusal flag), raw `PAN` byte, duty step and register shadows, but: three banks each with a copy of the track code (chosen per track by the sound id's top bits; the copies differ in small ways), a 128 Hz timer with music tracks in alternating pairs (64 Hz), a tempo that skips four consecutive music-track calls, a **progressive music fade** (drums, then CH3, then CH1/CH2 stop), `$EB n xy` vibrato with delay and depth, raw register-frame streams (`$E1` first byte), and a refused track **passing its stream pointer** to the next track.
- **Ganbare Goemon** keeps TMNT II's code (the bank-14 track code nearly instruction for instruction, the ROM0 update and requests), one page higher (`$D080 + n×$100`, fields to `$CF`). There is one copy of the track code: `FarRead` copies 4 stream bytes from the track's bank (14, 15 or 13 by id) into `wReadBuf`. New: `$EC` volume envelopes (the release waits while one runs), `$ED` duty step working, `$F9 n addr` jump on the n-th pass, pitch 13 = the last pitch an octave up, raw frames with `$EB` slides and `$ED`/`$EE` repeats with accumulating offsets, the fade added to CH3's level code, drums stopping at `$50`. Gone: PCM, the `TRK_SWEEP` copy, `PanRight`'s `$0B` bug.
- **Tiny Toon** starts from Nemesis II: `$80–$8E` of the track page are identical, `$90–$B6` moved up a byte to make room for envelope fields, the globals moved to `$C784`, the shadows to `$C79F`. It runs every track once per VBlank (a tempo carry skips all music tracks for a frame, as in Belmont's Revenge), in one bank, and returns to the old flow commands (`$FB` segno, `$FC` return, `$FD` call, `$FE n` repeat / `$FE $FF` jump). New: `$D0–$DF` (no-ops, a register write, the old `$EA` extensions, `PAN` as `$DF`), `$EA` octave shift + transpose, `$E9` duty step, `$EC` envelopes, `$ED` detune, raw streams marked by `$01`. A refused track now ends the whole request (and the flag stays set), and the fade's stops jump into the end handler with the wrong return address on the stack.
- **TMNT II** rewrites the code: 256 Hz, one music track per update in turn (64 Hz each) plus all SFX tracks, per-track register addresses and a descriptor byte, the second SFX track on CH3, priority-then-id track header, SFX requests refused as a whole, volumes compared with the register read-back (no retrigger when unchanged), detune, `$FA` jump, and **four 1-bit PCM voice clips** played with interrupts off.

## Differences

| | CVA | MM | Nemesis | Belmont's Revenge | Blades of Steel |
|---|---|---|---|---|---|
| Tick | timer 64 Hz | timer 64 Hz | timer 64 Hz | **VBlank 59.7 Hz** | VBlank 59.7 Hz |
| Music rate | 32 Hz minus tempo skips on odd ticks | tick × (1 − tempo/256) | same | same | same |
| Tracks / storage | 6, `$25`-byte slots + working copy | 7, in place, page `$C0+n`, `$80–$A3` | 7, page `$C1+n`, `$80–$A3` | 7, page `$C0+n`, `$80–$B5` | same (`$A7–$B4` glide) |
| Channel blocking | Ch1 by Sfx1 | Ch1 by Sfx1, Ch2 by Sfx2 | same | same, and PAN blocked on both | same; PAN blocked on Ch1 only |
| `EA 4n` | autopan | no-op | stores n \| 2 in the flags (unused) | same bug, used by the data | same bug |
| `EA 5n` | – | – | – | garbage | **glide** (unused) |
| `$ED` | no-op | no-op | no-op | duty step | duty step |
| `$EF` PAN | swap(x) into NR51 | same | same | raw x stored per track | swap(x) again |
| Rest | NRx2 = 0, NRx4 = `$80` | same | NRx2 = 0 only | same | same |
| Release, env 0 | cut | cut | retrigger at same volume | same | same |
| `VIBRATO 0` | keeps offset | keeps offset | clears offset | clears offset | clears offset |
| Vibrato negate | sticky | sticky | sticky | sticky | per step |
| CH3 level stored | vol/2 | vol/2 | + atten + fade/2 (decay adds atten again) | same | same |
| End of SFX | restore duty | restore duty + period, NRx2 = 0 + trigger | restore duty + period, NRx2 = 0 | same | same |
| Fade-out | – | – | game writes the target, 64 ticks/step, 5 steps, stop or queue | `StartFade`, 32 ticks/step, queue only | 16 ticks/step, queue or stop (< 5) |
| Request extras | – | engine pitch, `$11` follow-up | lockout for `$2E–$32`, follow-ups `$14`/`$21`/`$37`, `$0F` no restart | abort on refusal | abort on refusal |
| `StopAll` NR51 | shadow 0 | shadow 0 | shadow `$FF` | shadow `$FF` | shadow `$FF` |
| Period table | 96 | 96 | 96 | 85 (`$62`/`$64` play below it) | 85 (`$24` plays below it) |
| Drum map / waves | 4 / 3 | 13 / 9 | 13 / 10 | 13 / 6 (12 pointers) | 11 / 13 (15 pointers) |

| | Nemesis II | TMNT II |
|---|---|---|
| Tick | timer **128 Hz**; SFX every tick, music in alternating pairs (64 Hz) | timer **256 Hz**; SFX every tick, one music track per tick (64 Hz) |
| Banks | 13 (`$01–$5D`), 14 (`$81–$96`), 15 (`$C1–$D9`); track code copied into each | 14 (`$01–$9E`), 15 (`$C1–$F3`); track code in both (bank 15 without raw frames) |
| Tracks | page `$C0+n`, `$80–$B7`, shadows at `$C1B7` | page `$C0+n`, `$80–$C5` with per-track register addresses, no shadows (reads the registers back) |
| Sfx2 channel | CH2 | **CH3** |
| Requests | groups with abort and stale flag; a refused track passes its pointer on | any refused SFX track drops the whole request; music needs Ch1 |
| Tempo | every 4th music-track call; a carry skips the next 4 calls | once per 4 ticks; a carry makes all music tracks skip one tick |
| Fade | game sets `wFadeReq`; `$70` calls/step; drums, CH3, CH1/CH2 stop at steps 5/7/9 | game sets `wFadeRate`; `$10` per step; drums stop at `$40`, the rest at `$70` |
| Vibrato | `$EB n xy` (delay, depth); `$FE n` repeat in the table | `$EB n xy`; `$FB` loop markers / `$FE` mark in the table |
| New | raw register-frame streams, `$96` stops all first | detune, `$FA` jump, volume `$F8/$F9`, noise hold mode, PCM `$9A–$9D` |
| Pause | only the `$5D` track runs (bank 13) | SFX keep running; CH2 isn't restored |

| | Ganbare Goemon | Tiny Toon |
|---|---|---|
| Tick | timer 256 Hz; SFX every tick, one music track per tick (64 Hz) | VBlank 59.7 Hz; all tracks every tick, music skips a tick on a tempo carry |
| Banks | ids `$01–$9F` 14, `$A0–$EF` 15, `$F0–$FF` 13; one copy of the track code (bank 14), stream bytes through `FarRead` | one bank (7) |
| Tracks | page `$D0+n`, `$80–$CF`, per-track register addresses, read-back compares | page `$C0+n`, `$80–$BF`, shadows `$C79F–$C7B3` through `WriteReg` |
| Sfx2 channel | CH3 | CH2 |
| Requests | any refused SFX track drops the whole request; music needs Ch1 | groups as Nemesis II, but a refusal returns from `PlaySound` with the flag still set |
| Flow | `$FB`/`$FC` loop markers, `$FD`, `$FE`, `$FA` jump, **`$F9 n addr`** | **`$FB` segno, `$FC` return, `$FD` call, `$FE n` / `$FE $FF addr`** |
| Fade | as TMNT II (drums at `$50`); CH3 level + fade | every `$30` updates; steps 5/7/9 stop drums, Ch3, Ch1/Ch2, mostly through the stack bug; never ends by itself |
| New | envelopes, working duty step, slides, raw repeats, pitch 13 = last pitch + octave | `$D0–$DF`, octave shift, envelopes (unused by the data), raw streams (unused) |

## Tooling (in `GBAudioLab\Kon`)

- Generations 1–2: `tools/kdata.py` holds per-game profiles (`PROFILES`: `cva`, `mm`, `nem`, `cv2`, `bos`) with table addresses and track roles, and decodes/walks the data (with optional `orphans`). `tools/gen_asm.py <game> out.asm` with `cfg_<game>.py` generates the byte-exact asm. Models: `tools/kmodel.py` (early), `tools/kmodel2.py` (later: Nemesis, Belmont's Revenge, Blades of Steel). Verifiers `verify/vmodel.py` and `verify/vmodel2.py`.
- Generations 3–4: `tools/kdata3.py` (Nemesis II), `tools/kdata4.py` (TMNT II), `tools/kdata5.py` (Goemon) and `tools/kdata6.py` (Tiny Toon) decode the new formats; `tools/gen_asm3.py n2|tm2|gg|tt out.asm` is the multi-bank generator (labels and segments per bank, decoder chosen by the config; a config may post-process the lines with `postfix`). Models `tools/kmodel3.py`–`tools/kmodel6.py` are transliterations over a RAM image; `verify/vmodel3.py`–`verify/vmodel6.py` compare them with PyBoy every update (from `vmodel4.py` on also the exact sequence of register writes). `verify/patch_gg.py` and `verify/patch_tt.py` write ROM copies that exercise features the data doesn't use.
- `run_all*.sh` (every id alone) and `run_combo*.sh` (mixed scenarios) per game, with logs.
- A new game needs a profile, a `cfg_<game>.py`, and a model branch or a new model, plus the update/play/trigger hook addresses and the RAM layout in the verifier.

## Open points for later sessions

- Which early variant is older: the CVA and MM ROMs are 1989 games in EU releases, and nothing in the code dates them. Nemesis contains MM's code, so MM → Nemesis is a direct line.
- Where the glide of Blades of Steel went: neither Nemesis II nor TMNT II has it.
- Whether other 1991–92 Konami GB games use the third or the fourth generation, and whether the PCM player appears elsewhere. So far the fourth generation has two branches (TMNT II with PCM, Goemon with envelopes and slides) and the third a reworked descendant (Tiny Toon).
- Whether Goemon's driver came before or after TMNT II's: the code doesn't say, but Goemon's additions sit on top of TMNT II's bank-14 code.
