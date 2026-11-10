# Konami GB sound engine family (original driver)

A running overview of Konami's in-house Game Boy sound driver across games. Each game has its own doc with the details, and this page tracks what's shared and what changes. Covered so far: **The Castlevania Adventure** and **Motocross Maniacs** (session 1, 1989), **Nemesis** (1990) and **Castlevania II: Belmont's Revenge** (1991) (session 2), **Blades of Steel**, **Nemesis II: The Return of the Hero** and **TMNT II: Back from the Sewers** (1991) (session 3), **Ganbare Goemon: Sarawareta Ebisumaru!** (1991) and **Tiny Toon Adventures: Babs' Big Break** (1992) (session 4), **Parodius** (1991) and **Tiny Toon Adventures 2: Montana's Movie Madness** (1993) (session 5), **Batman: The Animated Series** and **Raging Fighter** (1993) (session 6), **The Spirit of F-1** (1991) and **Hyper Dunk** (Double Dribble: 5 on 5, 1991; this ROM is the 1994 European release) (session 7).

| Game | ROM | Variant | Driver location | Ids | Doc / asm |
|---|---|---|---|---|---|
| The Castlevania Adventure | `Castlevania Adventure, The (E) [!].gb` | early, 6-track, working copy | bank 2 `$4000–$663E` | 49 | `CastlevaniaAdventure_SoundDriver.md`, `CVA_SoundDriver.asm` |
| Motocross Maniacs | `Motocross Maniacs (E) [!].gb` | early, 7-track, in place | `$6576–$7FFF` | 32 | `MotocrossManiacs_SoundDriver.md`, `MM_SoundDriver.asm` |
| Nemesis | `Nemesis (E) [!].gb` | later, timer | bank 7 `$4000–$7404` | 57 | `Nemesis_SoundDriver.md`, `NEM_SoundDriver.asm` |
| Castlevania II: Belmont's Revenge | `Castlevania II - Belmont's Revenge (U) [!].gb` | later, VBlank | bank 7 `$4000–$7FFF` | 107 | `CastlevaniaII_SoundDriver.md`, `CV2_SoundDriver.asm` |
| Blades of Steel | `Blades of Steel (E) [!].gb` | later, VBlank + glide | bank 7 `$4000–$6C2E` | 51 | `BladesOfSteel_SoundDriver.md`, `BOS_SoundDriver.asm` |
| The Spirit of F-1 | `Spirit of F-1, The (E) [!].gb` | **bridge 2→3**: second-gen frame, Nemesis II track code, VBlank | bank 7 `$4000–$7BD1` | 48 | `SpiritOfF1_SoundDriver.md`, `F1_SoundDriver.asm` |
| Hyper Dunk | `Hyper Dunk (U).gb` | **bridge 2→3** + envelopes, duty step, no request groups, VBlank | bank 7 `$4000–$6CD1` | 48 | `HyperDunk_SoundDriver.md`, `HD_SoundDriver.asm` |
| Parodius | `Parodius (UE) [!].gb` | later, **Nemesis branch**, VBlank, banked streams | ROM0 + bank 14 (data 14–15) | 106 | `Parodius_SoundDriver.md`, `PAR_SoundDriver.asm` |
| Nemesis II: The Return of the Hero | `Nemesis II - The Return of the Hero (E) [!].gb` | **third generation**, 128 Hz, 3 banks | ROM0 + banks 13–15 | 140 | `NemesisII_SoundDriver.md`, `N2_SoundDriver.asm` |
| TMNT II: Back from the Sewers | `Teenage Mutant Hero Turtles - Back from the Sewers (E) [!].gb` | **fourth generation**, 256 Hz, 2 banks, PCM | ROM0 + banks 14–15 | 205 + 4 PCM | `TMNT2_SoundDriver.md`, `TM2_SoundDriver.asm` |
| Ganbare Goemon: Sarawareta Ebisumaru! | `Ganbare Goemon (J).gb` | fourth generation **extended**, 256 Hz, one code copy for 3 banks | ROM0 + bank 14 (data 13–15) | 185 | `GanbareGoemon_SoundDriver.md`, `GG_SoundDriver.asm` |
| Tiny Toon Adventures: Babs' Big Break | `Tiny Toon Adventures - Babs' Big Break (E) [!].gb` | third generation **reworked**, VBlank, 1 bank | bank 7 `$4000–$4E14` | 99 | `TinyToon_SoundDriver.md`, `TT_SoundDriver.asm` |
| Tiny Toon Adventures 2: Montana's Movie Madness | `Tiny Toon Adventures 2 - Montana's Movie Madness (U) [!].gb` | fourth generation, **Goemon branch**, VBlank, 1 bank | ROM0 + bank 7 `$43F9–$7F54` | 112 | `TinyToon2_SoundDriver.md`, `TT2_SoundDriver.asm` |
| Batman: The Animated Series | `Batman - The Animated Series (U).gb` | Tiny Toon 2's driver, **update in ROM0, 64 Hz timer** | ROM0 + bank 7 `$4000–$7A97` | 99 | `Batman_SoundDriver.md`, `BM_SoundDriver.asm` |
| Raging Fighter | `Raging Fighter (UE) [!].gb` | Batman's driver in **2 banks** (`FarRead`), VBlank | ROM0 + banks 14–15 | 119 | `RagingFighter_SoundDriver.md`, `RF_SoundDriver.asm` |

## Generations

1. **Early** (CVA, MM): 64 Hz timer, CVA on a working copy, MM in place.
2. **Later** (Nemesis, Belmont's Revenge, Blades of Steel, Parodius): MM's code reorganised; same command language. Belmont's Revenge moves to VBlank; Blades of Steel is Belmont's Revenge plus a glide.
   - **The Spirit of F-1** and **Hyper Dunk** keep the second generation's frame (one bank, VBlank, Belmont's Revenge's update loop, tempo, shadows, raw `PAN` byte, request starts) but run **Nemesis II's track code and command language** (paired `$FB`/`$FC` loops, `$FD` call/return, `$FE` mark/jump, `$EB n xy` vibrato, one-byte vibrato steps, raw streams). The Spirit of F-1 is the closest relative of Nemesis II so far; Hyper Dunk adds volume envelopes (`$EC`) and keeps the duty step, but drops the request groups.
   - **Parodius** goes back to Nemesis's code (no request groups, Nemesis `PAN`, lockout, the pause that only runs the pause jingle) with Belmont's Revenge's VBlank tick and duty step, and reads every stream byte through ROM0 from a bank named in the sound header.
3. **Third** (Nemesis II): the track code reshuffled and copied into each of three sound banks, a 128 Hz timer with the music at half rate, a new flow syntax and a new vibrato command.
   - **Tiny Toon** reworks it: Nemesis II's track page, requests, shadows and table formats on VBlank in one bank, but with the generation 1–2 flow commands back, a `$D0–$DF` command block, a shadowed `WriteReg` for every register, envelope tables, and some serious bugs (the fade's stops break the stack, a refusal leaves the request flag set).
4. **Fourth** (TMNT II): a rewrite that keeps the third generation's data ideas but changes the code, the track layout and the update scheme, and adds PCM.
   - **Ganbare Goemon** is TMNT II's track code with additions (volume envelopes, a working duty step, a counted jump, raw-frame slides and repeats) and a single copy of the code reading streams from three banks through a ROM0 buffer; no PCM.
   - **Tiny Toon 2** keeps Goemon's track code (counted jump, working duty step, pitch 13) without envelopes or raw frames, on VBlank in one bank, with packed two-notes-per-byte SFX, noise volume bytes, semitone vibrato, CH3 wave alternation and an NR50 fade.
     - **Batman** is Tiny Toon 2's driver with the update, pause, tempo and fade moved to ROM0 (the track code entered per track through a bank switch), on a 64 Hz timer, with a staged fade, a volume ramp, field clear, key transpose and tempo − 3 commands, `$EC` = NR50, and the wave alternation and the octave-in-voice gone.
     - **Raging Fighter** is Batman's driver over two sound banks (ids `< $A0` bank 14, `≥ $A0` bank 15), every stream byte read through a ROM0 `FarRead` buffer as in Goemon, on VBlank, without a pause, with `$EC` = start a fade and a delayed request; most of Batman's new commands are dropped again.

## What's shared (generations 1–2)

- **Sound ids** index a pointer table of headers `db priority, track mask` + one `dw` per mask bit (Parodius: `db priority, bank, track mask`). Id 0 = stop everything. A track is taken when the new priority ≥ the track's current priority.
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
- **Parodius** is Nemesis's code (about 1,100 of its 1,400 instructions line up with Nemesis's, 930 with Belmont's Revenge's) at `$C080 + n×$100`, with a `TRK_BANK` field inserted at `$86` (everything after it one byte up), on **VBlank**, with Belmont's Revenge's `$ED` duty step. The header carries the **bank of its streams**, and `ReadStreamByte` in ROM0 maps it for every byte, so the songs can live in banks 14 and 15. Nemesis's fade (now started through `StartFade`, 32 updates per step, stop for targets below 6), lockout (now for ids `$67–$6A`) and pause (only the pause jingle runs) are kept; the follow-ups and the `$0F` special case are gone. New: **`PauseSound`/`ResumeSound`** (mute, then restore the channels from the shadows) and write-only **channel activity flags** set by every SfxN/music note.
- **The Spirit of F-1** is the second generation's frame around Nemesis II's track code: about 1,105 of its 1,414 instructions line up with Nemesis II's bank-13 code (about 910 with Belmont's Revenge's), its track fields are Nemesis II's up to `$B0` (`PAN` at `$B4`), and its commands are Nemesis II's, including the `$EA 2x`/`$EC` no-ops and the raw streams. Missing compared with Nemesis II: the banks, the 128 Hz timer and half-rate music, its tempo scheme, the fade and the duty step. Request groups with the stale refusal flag as Belmont's Revenge. Tracks at `$D780 + n×$100`. Game-specific: an **engine sound** on Sfx1 (`$1A`, period from a table indexed by a game variable, minus `$60` on every other update) that comes back after each Sfx1 SFX, `$1B` to stop it, and `$0E` muting CH3. A latent bug: SFX `$11` (the songs' shared intro subroutine) would read its closing `$FD` as a call into ROM0.
- **Hyper Dunk** has the same frame and Nemesis II language (about 900 instructions in common with Nemesis II, 780 with Belmont's Revenge, 955 with The Spirit of F-1), with the fields from `TRK_FLOW` on one byte higher and three additions: **volume envelope tables** (`$EC n`, steps of ticks | volume with a retrigger each), Belmont's Revenge's **`$ED` duty step**, and `$EA 2n` as a delay-less vibrato; `$EB x yz` takes the whole byte as the table number and a delay of y × unit. **No request groups** (every track tested alone; `wReqRefused` written, never read), no fade (`FadeTick` is a `ret`). Game-specific: a **game-controlled tone** on Sfx1 (`$11`/`$12`, period from a 144-entry table indexed by a game variable) and a few id rules in `PlaySound`.
- **Nemesis II** keeps Belmont's Revenge's request groups (and the stale refusal flag), raw `PAN` byte, duty step and register shadows, but: three banks each with a copy of the track code (chosen per track by the sound id's top bits; the copies differ in small ways), a 128 Hz timer with music tracks in alternating pairs (64 Hz), a tempo that skips four consecutive music-track calls, a **progressive music fade** (drums, then CH3, then CH1/CH2 stop), `$EB n xy` vibrato with delay and depth, raw register-frame streams (`$E1` first byte), and a refused track **passing its stream pointer** to the next track.
- **Ganbare Goemon** keeps TMNT II's code (the bank-14 track code nearly instruction for instruction, the ROM0 update and requests), one page higher (`$D080 + n×$100`, fields to `$CF`). There is one copy of the track code: `FarRead` copies 4 stream bytes from the track's bank (14, 15 or 13 by id) into `wReadBuf`. New: `$EC` volume envelopes (the release waits while one runs), `$ED` duty step working, `$F9 n addr` jump on the n-th pass, pitch 13 = the last pitch an octave up, raw frames with `$EB` slides and `$ED`/`$EE` repeats with accumulating offsets, the fade added to CH3's level code, drums stopping at `$50`. Gone: PCM, the `TRK_SWEEP` copy, `PanRight`'s `$0B` bug.
- **Tiny Toon** starts from Nemesis II: `$80–$8E` of the track page are identical, `$90–$B6` moved up a byte to make room for envelope fields, the globals moved to `$C784`, the shadows to `$C79F`. It runs every track once per VBlank (a tempo carry skips all music tracks for a frame, as in Belmont's Revenge), in one bank, and returns to the old flow commands (`$FB` segno, `$FC` return, `$FD` call, `$FE n` repeat / `$FE $FF` jump). New: `$D0–$DF` (no-ops, a register write, the old `$EA` extensions, `PAN` as `$DF`), `$EA` octave shift + transpose, `$E9` duty step, `$EC` envelopes, `$ED` detune, raw streams marked by `$01`. A refused track now ends the whole request (and the flag stays set), and the fade's stops jump into the end handler with the wrong return address on the stack.
- **TMNT II** rewrites the code: 256 Hz, one music track per update in turn (64 Hz each) plus all SFX tracks, per-track register addresses and a descriptor byte, the second SFX track on CH3, priority-then-id track header, SFX requests refused as a whole, volumes compared with the register read-back (no retrigger when unchanged), detune, `$FA` jump, and **four 1-bit PCM voice clips** played with interrupts off.
- **Batman** is Tiny Toon 2's driver (about 1,600 of its 1,860 instructions line up). `SndUpdate`, the pause (now on the whole `$DB04` byte), `TempoTick`, the fade and `SndInit` sit in ROM0, and `RunTrack` maps bank 7 and jumps to the track code at `$4000` for every track; PlaySound and the tables stay in bank 7. It runs on a **64 Hz timer**, the tracks are one page up (`$C180`). New: a **staged fade** (NR50 down by `$11`, then Drm, Ch3, Ch1, Ch2 stop and NR50 is restored; CH4 muted on every fade update; a last request of `$12` cuts the music), a **volume ramp over notes** (`$EA Fx`, PANFLAGS bits 5/6, two new fields), `$EA Ax` field clear, `$EA Dx` transpose by a game variable, `$EA Ex` tempo − 3, `$EC` = NR50, `$F8` = volume, a 7-bit unit in the voice byte, the detune always added. Gone: the CH3 wave alternation, the octave in the voice byte, Tiny Toon 2's dead note-volume fade, the joypad write of drum rests.
- **Raging Fighter** is Batman's driver (about 1,490 of Batman's 1,860 instructions line up) with **two sound banks**: PlaySound and the header reading move to ROM0, the id picks the bank (`< $A0` 14, `≥ $A0` 15) and **`FarRead`** copies 4 stream bytes into `wReadBuf` before every read, as in Goemon. VBlank again, no pause, tracks at `$C0A0` with one byte inserted after `TRK_VIB`. Request `$0F` is a delayed `$10`; every request resets NR50. `$EC x` starts the fade (songs fade themselves out), whose stop order is Drm, Ch1, Ch2, Ch3. The packed SFX always start with the high nibble, `$E0 u|$80` is a noise-style voice on any track, noise volume bytes write NR42 at once, `$E8` clears the release volume. Of Batman's additions only `$EA Ax` and `$F8` stay; the drum rests write the joypad register again.
- **Tiny Toon 2** keeps the fourth generation's requests, descriptors (same values), read-back volume compares, loop/call/mark flow and joypad-writing drum track, and Goemon's `$F9` counted jump, working `$ED` duty step and pitch 13. It runs all seven tracks once per **VBlank** in **one bank** (no `FarRead`, no music slots); fields `$89–$AC` sit one byte lower than in TMNT II, the loop/mark/return fields follow at `$AD–$B6`, the register addresses at `$B7–$BA`. Envelopes, raw frames and slides are gone. New: **two notes per byte** on the tone SFX tracks (nibble `$E` = new unit, `$F` = escape to a command), **noise volume bytes** `$C0–$DF`, the octave packed into the voice's unit byte, **semitone vibrato tables** (`$EB n|$80`), **CH3 wave alternation** (`$EC xy`), a **release volume** (`$EA 9x`), pan commands that also set the attenuation, two autopan modes, and a fade that turns **NR50** down (the note-volume fade is still there but its level never moves).

## Differences

| | CVA | MM | Nemesis | Belmont's Revenge | Blades of Steel | Parodius |
|---|---|---|---|---|---|---|
| Tick | timer 64 Hz | timer 64 Hz | timer 64 Hz | **VBlank 59.7 Hz** | VBlank 59.7 Hz | VBlank 59.7 Hz |
| Music rate | 32 Hz minus tempo skips on odd ticks | tick × (1 − tempo/256) | same | same | same | same |
| Tracks / storage | 6, `$25`-byte slots + working copy | 7, in place, page `$C0+n`, `$80–$A3` | 7, page `$C1+n`, `$80–$A3` | 7, page `$C0+n`, `$80–$B5` | same (`$A7–$B4` glide) | 7, page `$C0+n`, `$80–$A7` (`$86` bank) |
| Streams | with the driver | with the driver | with the driver | with the driver | with the driver | **bank per sound** (14/15), read through ROM0 |
| Channel blocking | Ch1 by Sfx1 | Ch1 by Sfx1, Ch2 by Sfx2 | same | same, and PAN blocked on both | same; PAN blocked on Ch1 only | as Nemesis |
| `EA 4n` | autopan | no-op | stores n \| 2 in the flags (unused) | same bug, used by the data | same bug | same bug, used by the data |
| `EA 5n` | – | – | – | garbage | **glide** (unused) | runs past the table |
| `$ED` | no-op | no-op | no-op | duty step | duty step | duty step |
| `$EF` PAN | swap(x) into NR51 | same | same | raw x stored per track | swap(x) again | swap(x) (Nemesis) |
| Rest | NRx2 = 0, NRx4 = `$80` | same | NRx2 = 0 only | same | same | same |
| Release, env 0 | cut | cut | retrigger at same volume | same | same | same |
| `VIBRATO 0` | keeps offset | keeps offset | clears offset | clears offset | clears offset | clears offset |
| Vibrato negate | sticky | sticky | sticky | sticky | per step | sticky |
| CH3 level stored | vol/2 | vol/2 | + atten + fade/2 (decay adds atten again) | same | same | same |
| End of SFX | restore duty | restore duty + period, NRx2 = 0 + trigger | restore duty + period, NRx2 = 0 | same | same | same |
| Fade-out | – | – | game writes the target, 64 ticks/step, 5 steps, stop or queue | `StartFade`, 32 ticks/step, queue only | 16 ticks/step, queue or stop (< 5) | `StartFade`, 32 ticks/step, queue or stop (< 6) |
| Request extras | – | engine pitch, `$11` follow-up | lockout for `$2E–$32`, follow-ups `$14`/`$21`/`$37`, `$0F` no restart | abort on refusal | abort on refusal | lockout for `$67–$6A`; refused tracks skipped |
| Pause | – | – | only track 1 runs, while it plays `$2C` | same with `$06` | same with `$06` | same with `$07`, plus `PauseSound` (mute) and `ResumeSound` (restore from the shadows) |
| `StopAll` NR51 | shadow 0 | shadow 0 | shadow `$FF` | shadow `$FF` | shadow `$FF` | `$FF` (written) |
| Period table | 96 | 96 | 96 | 85 (`$62`/`$64` play below it) | 85 (`$24` plays below it) | 96 |
| Drum map / waves | 4 / 3 | 13 / 9 | 13 / 10 | 13 / 6 (12 pointers) | 11 / 13 (15 pointers) | 12 / 12 (15 pointers) |

| | Belmont's Revenge | The Spirit of F-1 | Hyper Dunk | Nemesis II |
|---|---|---|---|---|
| Tick | VBlank | VBlank | VBlank | timer 128 Hz, music at 64 Hz |
| Banks | 7 | 7 | 7 | 13–15, code copied into each |
| Tracks | `$C080+n×$100`, `$80–$B5` | `$D780+n×$100`, `$80–$B4` (Nemesis II's fields) | `$C080+n×$100`, `$80–$BD` (Nemesis II's + 1 from `$8F`, envelope and duty-step fields) | `$C080+n×$100`, `$80–$B7` |
| Requests | groups, stale flag | groups, stale flag | **each track alone**, no abort | groups, stale flag, refused pointer passed on |
| Flow | `$FB` segno, `$FC` ret, `$FD` call, `$FE n` | paired `$FB`/`$FC`, `$FD`, `$FE` | as F-1 | as F-1 |
| Vibrato | `EA 2n`, 2-byte steps | `$EB n yz` (delay (y+1) units), 1-byte steps | `$EB x yz` (delay y units) and `EA 2n`; 1-byte steps | as F-1 |
| `$EC` / `$ED` | no-op / duty step | no-ops | **envelope** / duty step | no-op / duty step |
| Raw streams | – | yes | yes | yes |
| Fade | `StartFade` | none | none | progressive |
| Extras | – | engine sound `$1A` | variable tone `$11`/`$12` | – |

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

| | Ganbare Goemon | Tiny Toon | Tiny Toon 2 |
|---|---|---|---|
| Tick | timer 256 Hz; SFX every tick, one music track per tick (64 Hz) | VBlank 59.7 Hz; all tracks every tick, music skips a tick on a tempo carry | VBlank 59.7 Hz; all tracks every tick, music skips a tick on a tempo carry |
| Banks | ids `$01–$9F` 14, `$A0–$EF` 15, `$F0–$FF` 13; one copy of the track code (bank 14), stream bytes through `FarRead` | one bank (7) | one bank (7) |
| Tracks | page `$D0+n`, `$80–$CF`, per-track register addresses, read-back compares | page `$C0+n`, `$80–$BF`, shadows `$C79F–$C7B3` through `WriteReg` | page `$C0+n`, `$80–$C1`, register addresses at `$B7–$BA`, read-back compares |
| Sfx2 channel | CH3 | CH2 | CH3 |
| Requests | any refused SFX track drops the whole request; music needs Ch1 | groups as Nemesis II, but a refusal returns from `PlaySound` with the flag still set | as Goemon |
| Flow | `$FB`/`$FC` loop markers, `$FD`, `$FE`, `$FA` jump, **`$F9 n addr`** | **`$FB` segno, `$FC` return, `$FD` call, `$FE n` / `$FE $FF addr`** | as Goemon |
| Fade | as TMNT II (drums at `$50`); CH3 level + fade | every `$30` updates; steps 5/7/9 stop drums, Ch3, Ch1/Ch2, mostly through the stack bug; never ends by itself | **NR50** − `$11` every `wFadeRate` updates (rate doubles at `$33`), `StopAll` at 0; a noise SFX cancels it |
| New | envelopes, working duty step, slides, raw repeats, pitch 13 = last pitch + octave | `$D0–$DF`, octave shift, envelopes (unused by the data), raw streams (unused) | packed SFX notes, noise volume bytes, semitone vibrato, wave alternation, release volume, octave in the voice byte |

| | Tiny Toon 2 | Batman | Raging Fighter |
|---|---|---|---|
| Tick | VBlank 59.7 Hz | **timer 64 Hz** | VBlank 59.7 Hz |
| Code | bank 7 (+ ROM0 stubs) | **ROM0 update/fade/tempo/pause**, bank 7 track code and PlaySound | ROM0 update/fade/tempo, **PlaySound**, `FarRead`; bank 14 track code |
| Sound banks | 7 | 7 | **14 (ids `< $A0`), 15 (ids `≥ $A0`)**, read through a 4-byte buffer |
| Tracks | page `$C0+n`, `$80–$C1` | page `$C1+n`, `$80–$C2` | page `$C0+n`, `$A0–$E0` (byte inserted at `$A9`) |
| Voice `$E0` | 5-bit unit + octave code | 7-bit unit | 7-bit unit; `u\|$80` = noise-style voice on any track |
| Packed SFX | a voice starts with the high nibble; `$F` forces a command | as Tiny Toon 2 | always high nibble first; `$F` goes on with the next byte |
| `$EA` | 0–C (D–F run into code) | 0–F: **A clear, D key transpose, E tempo − 3, F volume ramp** | 0–A (A clear) |
| `$EC` | CH3 wave alternation | NR50 = x | **start a fade** |
| `$F8` | attenuation | volume | volume |
| Fade | NR50 − `$11` (rate doubles at `$33`), `StopAll` at 0; noise SFX cancels it | NR50 to `$11`, then Drm/Ch3/Ch1/Ch2 stop, NR50 = `$77`; CH4 muted meanwhile; `$12` cuts it | NR50 to `$11`, then Drm/Ch1/Ch2/Ch3 stop, NR50 stays `$11`; any request resets NR50 |
| Pause | `$DD6C` bit 0 | `$DB04` (any value) | none |
| Drum rest | writes `$FF00` | no write | writes `$FF00` |
| Requests | game-state filter | dropped on `wSndMute` bit 0 | `$0F` = delayed `$10`; bank 15 locked by `wSndLock15` |

## Tooling (in `GBAudioLab\Kon`)

- Generations 1–2: `tools/kdata.py` holds per-game profiles (`PROFILES`: `cva`, `mm`, `nem`, `cv2`, `bos`) with table addresses and track roles, and decodes/walks the data (with optional `orphans`). `tools/gen_asm.py <game> out.asm` with `cfg_<game>.py` generates the byte-exact asm. Models: `tools/kmodel.py` (early), `tools/kmodel2.py` (later: Nemesis, Belmont's Revenge, Blades of Steel). Verifiers `verify/vmodel.py` and `verify/vmodel2.py`.
- Parodius uses the multi-bank tools: `tools/kdata7.py` walks `kdata.py`'s format per bank (headers in bank 14, streams in the header's bank); `gen_asm3.py` now takes a config `emit_header` and streams in another bank than their header. Model `tools/kmodel7.py`, verifier `verify/vmodel7.py`.
- Generations 3–4: `tools/kdata3.py` (Nemesis II), `tools/kdata4.py` (TMNT II), `tools/kdata5.py` (Goemon), `tools/kdata6.py` (Tiny Toon) and `tools/kdata8.py` (Tiny Toon 2) decode the new formats; `tools/gen_asm3.py n2|tm2|gg|tt|par|tt2 out.asm` is the multi-bank generator (labels and segments per bank, decoder chosen by the config; a config may post-process the lines with `postfix`). Models `tools/kmodel3.py`–`tools/kmodel8.py` are transliterations over a RAM image; `verify/vmodel3.py`–`verify/vmodel8.py` compare them with PyBoy every update (from `vmodel4.py` on also the exact sequence of register writes). `verify/patch_gg.py`, `verify/patch_tt.py`, `verify/patch_par.py` and `verify/patch_tt2.py` write ROM copies that exercise features the data doesn't use.
- `run_all*.sh` (every id alone) and `run_combo*.sh` (mixed scenarios) per game, with logs.
- Batman and Raging Fighter (session 6): `tools/kdata9.py` decodes both (`bm`, `rf`, with orphan streams and orphan subroutines), `tools/cfg_bm.py` / `tools/cfg_rf.py` for `gen_asm3.py`. New helpers: `tools/align.py` aligns two drivers instruction by instruction (difflib on normalised listings, with a field-offset map) and was used to carry labels from Tiny Toon 2 to Batman and from Batman to Raging Fighter; `tools/gaps9.py` lists data bytes no stream or table owns. Verification was lighter this time: `verify/vstream9.py` hooks the driver's TRK_LEN stores and checks every note/rest read (address, length, duration with tempo skips, ends) against the decoder, every id alone (`run_stream_bm.sh`, `run_stream_rf.sh`); no update-by-update model.
- The Spirit of F-1 and Hyper Dunk (session 7): `tools/kdata10.py` decodes both (`f1`, `hd`; Nemesis II's flow walker, HD's envelope tables, the engine/variable-tone headers that point at period tables), `tools/cfg_f1.py` / `tools/cfg_hd.py` for `gen_asm3.py` (which gained a plain `words` data kind), `tools/gaps10.py` for unowned data bytes. Verification as for Batman/Raging Fighter: `verify/vstream10.py` (TRK_LEN stores of notes, noise bytes, raw frames and raw rests vs the decoder, every id alone; requests injected straight into bank-7 `PlaySound` from the VBlank glue), `run_stream_f1.sh`, `run_stream_hd.sh`.
- A new game needs a profile, a `cfg_<game>.py`, and a model branch or a new model, plus the update/play/trigger hook addresses and the RAM layout in the verifier.
- **PyBoy hooks:** never hook two adjacent instructions (e.g. a shadow store right before the register store); PyBoy 2.6–2.8 then fires the second hook forever and the emulation hangs. `vmodel7.py` hooks only the stores that can reach a register. Games that clear WRAM in their demo loop (Tiny Toon 2) need the model re-seeded there.

## Open points for later sessions

- Which early variant is older: the CVA and MM ROMs are 1989 games in EU releases, and nothing in the code dates them. Nemesis contains MM's code, so MM → Nemesis is a direct line.
- Where the glide of Blades of Steel went: neither Nemesis II, TMNT II nor Parodius has it.
- Whether other 1991–93 Konami GB games use the third or the fourth generation, and whether the PCM player appears elsewhere. So far the second generation has a Nemesis branch (Parodius) next to the Belmont's Revenge one, the fourth generation two branches (TMNT II with PCM; Goemon with envelopes and slides, continued by Tiny Toon 2) and the third a reworked descendant (Tiny Toon).
- Which came first, Batman or Raging Fighter: Raging Fighter shares Batman's ROM0 layout and code but drops most of Batman's new commands and its fix of the drum-rest joypad write, which suggests both branched from a common later Tiny Toon 2 version rather than one from the other; the code alone doesn't settle it.
- Where The Spirit of F-1 and Hyper Dunk sit exactly: both carry Nemesis II's track code inside a second-generation frame, so they look like the step from Belmont's Revenge to Nemesis II (F-1 the closer one). Hyper Dunk's envelopes don't reappear in Nemesis II (Goemon and Tiny Toon later have `$EC` envelopes too; the formats weren't compared); whether Hyper Dunk's driver is the 1991 *Double Dribble: 5 on 5* code or a later revision for this 1994 release isn't settled.
- Whether Goemon's driver came before or after TMNT II's: the code doesn't say, but Goemon's additions sit on top of TMNT II's bank-14 code, and Tiny Toon 2 builds on Goemon's.
