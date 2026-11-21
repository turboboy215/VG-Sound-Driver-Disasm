# AJG (Alberto José González / Bit Managers) GB sound engine family

Sound driver written by Alberto José González at Bit Managers, used in their Game Boy games (many published by Infogrames). It was revised from game to game, so it is documented in several sessions. This file collects what the versions share and how they differ; each game has its own document and byte-exact disassembly in `GBAudioLab\AJG`.

| Game | ROM | Version | Doc |
|---|---|---|---|
| Pop Up | `Pop Up (U) [!].gb` (1991) | 1 | `PopUp_SoundDriver.md` |
| Bomb Jack | `Bomb Jack (U).gb` (1992) | 2 | `BombJack_SoundDriver.md` |
| The Adventures of Pinocchio (prototype) | `Adventures of Pinocchio, The (J).gb` (1993) | 3, early variant | `Pinocchio_SoundDriver.md` |
| Astérix | `Asterix (UE) (M5) [!].gb` (1993) | 3 (reference) | `Asterix_SoundDriver.md` |
| Metal Masters | `Metal Masters (U).gb` (1993) | 3, late variant | `MetalMasters_SoundDriver.md` |
| The Smurfs | `Smurfs, The (UE) (V1.0) (M4) [!].gb` (1994) | 4 (reference) | `Smurfs_SoundDriver.md` |
| Astérix & Obélix (GB) | `Obelix (E) (M2) (Eng-Spa) [S][!].gb` (1995) | 4 | `Obelix_SoundDriver.md` |
| Tintin in Tibet | `Tintin in Tibet (E) (M4) (Eng-Fre-Ger-Dut) [S].gb` (1995/96) | 4 | `TintinTibet_SoundDriver.md` |
| Spirou | `Spirou (E) (M4) [S][!].gb` (1996) | 4 | `Spirou_SoundDriver.md` |
| Tintin: Prisoners of the Sun | `Les Aventures De TinTin - Le Temple du Soleil (E) (M3) [M].gb` (1997) | 4 | `TintinSun_SoundDriver.md` |
| Astérix & Obélix (GBC) | `Obelix (E) (M4) [C][!].gbc` (1999) | 4, GBC revision | `Obelix_SoundDriver.md` |
| Lucky Luke | `Lucky Luke (E) (M4) [M].gb` | 4, Lucky Luke group | `LuckyLuke_SoundDriver.md` |
| The Smurfs' Nightmare | `Smurfs 3, The (E) (M4) [!].gb` | 4, Lucky Luke group (“GBS 3.4”) | `Smurfs3_SoundDriver.md` |
| Die Maus | `Maus, Die (E) (M4) [M].gb` | 4, Lucky Luke group, with `PORTA` | `Maus_SoundDriver.md` |
| Turok: Battle of the Bionosaurs | `Turok - Battle of the Bionosaurs (UE) (M4) [!].gb` | 4, Prisoners of the Sun group | `Turok_SoundDriver.md` |
| Turok 2: Seeds of Evil | `Turok 2 - Seeds of Evil (U) (M4) [C][!].gbc` | 4, Prisoners of the Sun group | `Turok_SoundDriver.md` |
| Hugo 2 | `Hugo 2 (G) [S][!].gb` | 4, Prisoners of the Sun group | `Hugo2_SoundDriver.md` |
| Otto's Ottifanten: Baby Bruno's Nightmare | `Otto's Ottifanten (E).gb` | 4, Lucky Luke group (Die Maus's driver) | `Otto_SoundDriver.md` |
| Sea Battle | `Sea Battle (E) (M4).gb` | 4, Lucky Luke group (The Smurfs' Nightmare's driver, “GBS 3.4”) | `SeaBattle_SoundDriver.md` |
| V-Rally: Championship Edition (GB) | `V-Rally - Championship Edition (U) (M3) [M][!].gb` (1998) | 4, Prisoners of the Sun group (Turok's driver) | `VRally_SoundDriver.md` |
| V-Rally: Championship Edition (GBC) | `V-Rally - Championship Edition (E) (M4) [C][!].gbc` | 4, Prisoners of the Sun group, GBC revision | `VRally_SoundDriver.md` |
| Sylvester and Tweety: Breakfast on the Run | `Sylvester and Tweety (E) (M6) [C][!].gbc` | 4, Lucky Luke group (Die Maus's driver, one more instrument) | `Sylvester_SoundDriver.md` |
| Bugs Bunny & Lola Bunny: Operation Carrots | `Bugs Bunny & Lola Bunny - Operation Carrots (E) (M6) [C][!].gbc` | 4, Lucky Luke group (Sea Battle's driver at The Smurfs' Nightmare's RAM) | `BugsBunny_SoundDriver.md` |

The three version-3 games are one driver at three stages: Pinocchio lacks a few of Astérix's features, Metal Masters adds an echo and shifts the command bytes. Their order by features is Pinocchio → Astérix → Metal Masters; all three are from 1993.

Version 4 reorganises the driver. Its first six builds, in order by features (which is also release order), are:

- The Smurfs;
- Astérix & Obélix GB, a small step;
- Tintin in Tibet, the Obélix GB driver moved to bank 15 with the command table first;
- Spirou, which adds `NOTE_HOOK` but keeps the GB output, pause and NR50 code;
- Prisoners of the Sun, the new output, pause and fade model;
- Astérix & Obélix GBC, Prisoners of the Sun's driver with duty shadows and NR31/NR41 writes.

§2.2 has the details. The Obélix GBC build carries the Obélix GB music data unchanged under the revised driver.

**Lucky Luke, The Smurfs' Nightmare and Die Maus form a further line, the Lucky Luke group (§2.3).** It combines:

- Prisoners of the Sun's pulse output (one NRx4 write) and its note on (direction always reset);
- Spirou's NR50 forcing and fades (Spirou's pause model too, except in Die Maus);
- no `PlayCh1Tone` and no `HwEnvAtten` stub.

Within the group:

- **The Smurfs' Nightmare** is Lucky Luke's driver with `INSTR` stopping auto-duty again. Its bank holds the driver's own name: `GBS 3.4 (C) 1990 - 1997 Alberto Jose Gonzalez & Bit Managers S.L.`
- **Die Maus** builds on Lucky Luke. It adds a look-ahead portamento (`PORTA`), drops `SLIDE_UP`/`SLIDE_DOWN`, takes Prisoners of the Sun's pause code, and runs from the timer interrupt.

Four more games use the group's drivers almost unchanged:

- **Otto's Ottifanten** runs Die Maus's driver code instruction for instruction (bank 3; only the `SndInit` arpeggio table and the SFX table address differ). It is the finished form of the 1993 Pinocchio prototype: five of its six songs are Pinocchio's songs re-encoded for version 4, and it uses Die Maus's `PORTA` in the music.
- **Sea Battle** runs The Smurfs' Nightmare's driver (same `GBS 3.4` string) with the RAM moved up one page to `$DC–$DF` / `$DC42`, and a `StopAll` that first sets a default instrument table (as in Hugo 2).
- **Sylvester and Tweety** (GBC) runs Die Maus's driver with one more instrument, so every range above `INSTR` moves up by 1 (`INSTR $85–$93` … `REPEAT $ED`). Its game calls `SndPause`/`SndResume`. Song slots 1 and 10–12 point 9 bytes before song 1's routine, into three `TRANSPOSE` patterns that run as code (with a stray `ld [bc], a`) and fall through into it.
- **Bugs Bunny & Lola Bunny** (GBC) runs Sea Battle's driver back at The Smurfs' Nightmare's RAM (`$DB–$DE` / `$DB42`); there is no version text. Song 2 is a longer version of song 1 (it starts with song 1's patterns); both are reached through `jp` stubs, song 2's from a stub placed in front of song 3. Song slots 17–18 jump into unused `TRANSPOSE` patterns. `$7800–$7FFF` of the sound bank is game graphics.

Where the group sits relative to Prisoners of the Sun is not clear from the code alone: it has some of Prisoners of the Sun's changes but not the others.

**Turok, Turok 2 and Hugo 2 use Prisoners of the Sun's driver itself, the Prisoners of the Sun group (§2.4).** They keep its RAM at `$DC–$DF`, its output, pause and NR50 model, and its 37-command table. The edits are game-specific:

- **Turok** has two more instruments (all ranges above `INSTR` shift by 2). Every `StartMusicChN` sets one fixed instrument table. `CheckRelease` gets an early exit with no audible effect. The drum kit is new.
- **Turok 2** is Turok's driver with one more range shift (+3 in all) and the instrument table also set in `SndInit`. It runs on the GBC but still uses the DMG driver.
- **Hugo 2** keeps Prisoners of the Sun's ranges, but `PlayCh1Tone` is gone and `StopAll` sets a default instrument table. The game's SFX glue (two noise-only SFX) sits in the sound bank right after the API table, and the last 7 API song slots jump into pattern data.
- **V-Rally** (GB 1998, and its GBC release) is Turok's driver (same ranges, `StartMusicChN` and `CheckRelease`) with Lucky Luke's RAM addresses (`$DB–$DE` / `$DB42`), no `PlayCh1Tone`, and the text `1998 by Alberto Jose Gonzalez.` after the period table. The game's race-engine sound lives in the sound bank: 14 extra API entries, and a hook at the top of `SndUpdate` that runs the engine routine instead of the music while it is on. `StopAll` also stops the engine. The **GBC release has a GBC revision** of this driver (duty shadows, NR31 writes, NR10 cleared in `StopAll`), unlike Turok 2.

## 1. What all versions so far share

- **One `$100`-byte RAM page per channel** (three music pages + one SFX page), addressed by setting H to the page and L to the field (`ld l, $xx`), so field numbers are page offsets. In versions 1–3 most field numbers are the same: `$00/$01` order position, `$02/$03` stream pointer, `$04` flags, `$05` ticks left, `$06–$0A` output (period low/high, volume), `$0B` volume, `$0C` note, `$0D` length. Version 4 keeps `$00–$04` and renumbers the rest.
- **Order lists**: per channel, a list of pattern pointers ending with `dw 0, loop_position`. `NEXT` reads the next pointer; `ORDER_JUMP w` sets the position. A song is started by a small routine per song that calls `StartMusicChN` with three order-list addresses.
- **Stream bytes:** below `$60` (`$5E` in Metal Masters) are notes (one byte each; the length comes from the last `LEN`). Above that come command ranges: a jump table of 30–39 commands, then instrument, arpeggio, volume, volume+envelope and length ranges (version 4: instrument, arpeggio, volume+envelope, length, repeat). A note ends the tick; so do `WAIT`, `REST`, `NOTE_OFF`/`END`.
- **Instruments are command macros**, not register sets. `INSTR n` runs a short command string (duty, `VOLENV`, vibrato, arpeggio, wave, noise…) up to `END`/`NEXT` (version 4: `END` only), then continues the main stream.
- **Software volume envelope** `VOLENV v, atk, dec, rates`: start volume v; attack = lo nibble count of +hi nibble steps; decay likewise downwards; rates byte = ticks per attack step (hi) / decay step (lo). Volume goes to NRx2 as `v << 4` with no hardware envelope. In version 4 only CH3 and the SFX page use it; the pulse channels use `HWENV` only.
- The same **81-entry period table** (note byte 12 = C2, 65.4 Hz), arpeggios (offset tables with a loop byte and `$FF` = hold), vibrato (delay, depth, speed), glide (note += n per tick), the CH3 volume table (`00 ×4, 60 ×4, 40 ×4, 20 ×4`), `PAN_C/R/L` (NR51 bits, rotated per channel) and `DUTY_50/75/12`.
- The SFX page plays the same stream format and replaces one music channel in the output while active. Its first tick is parsed inside the play call.

## 2. Version differences

| | Version 1 (Pop Up) | Version 2 (Bomb Jack) | Version 3 (Astérix) | Version 4 (The Smurfs) |
|---|---|---|---|---|
| Code location | 32 KB ROM | 32 KB ROM | one ROM bank with all its data (bank 3; Pinocchio and Metal Masters bank 2) | all of bank 6 (Tintin games, Spirou, Die Maus, Turok, Turok 2: bank 15; Lucky Luke 12; The Smurfs' Nightmare 2; Hugo 2 7, shared with other data; Otto's Ottifanten 3; Sea Battle 4; V-Rally GB 2, GBC 16, shared with other data; Sylvester and Tweety 15; Bugs Bunny 2, up to `$77FF`), API jump table at `$4000`; command table (`$4400`) and period table (`$4800`) page-aligned (from Tintin in Tibet on the command table is at `$4000`, the API table after it) |
| Pages | `$C1–$C4` | `$C4–$C7` | `$DC–$DF` (Pinocchio `$C1–$C4`, Metal Masters `$C6–$C9`), fields up to `$3F` (Metal Masters `$49`) | `$C1–$C4` (Prisoners of the Sun group and Sea Battle `$DC–$DF`, Lucky Luke, The Smurfs' Nightmare, V-Rally and Bugs Bunny `$DB–$DE`), fields up to `$3B` (37-command builds `$41`, Die Maus `$4A`) |
| Globals | HRAM + `$C339` | `$C318–$C338` | `$DB46–$DB6B` (Pinocchio HRAM `$FF91–$FFB5`, Metal Masters `$C5C0–$C5E5`) | `$C196–$C1B9`, in page `$C1` (Tibet `$C13C`, Spirou and Obélix GBC `$C142`, Prisoners of the Sun group and Sea Battle `$DC42`, Lucky Luke, The Smurfs' Nightmare, V-Rally and Bugs Bunny `$DB42`, Die Maus, Otto's Ottifanten and Sylvester and Tweety `$C14B`) |
| Tick | VBlank, or timer (53.89 Hz) while the LCD is off | VBlank only | VBlank (Pinocchio: timer, 53.89 Hz) | VBlank (Lucky Luke, The Smurfs' Nightmare, V-Rally, Bugs Bunny: the game's frame loop; Die Maus, Otto's Ottifanten, Sylvester and Tweety: timer reloaded every VBlank, 59.36 Hz when free-running) |
| SFX channel | CH1 (replaces Ch1) | CH3 (replaces Ch3; SFX use `WAVE`) | CH3 as v2, plus `PlayOnChN` (SFX stream on a music page, used by Metal Masters) | CH3 as v2; `PlayOnChN` gone; noise-only SFX through the game's glue (Smurfs) |
| SFX priority | the new SFX always wins | lower id wins | none in the driver; Astérix's glue keeps the lower id | lower id wins (Smurfs); none except SFX 29 (Obélix GB); none (all later builds) |
| Register output | `WriteReg` + handler table with shadows; fields `$06/$08/$0A` are table indices | direct writes to `$FF00 + field`; fields are I/O addresses | as v2 | as v2, plus a 16-bit pitch offset added to the period |
| Retrigger | only when the volume or period-hi bits change | pulse channels every tick (software volume), or at envelope writes (hardware mode) | software volume: only when NRx2 (read back) changes; hardware mode as v2 | pulse: only with NRx2 writes (note on, 2nd envelope, release, rest); **no software volume on pulse** |
| NR52 | | `$80` every tick | `$FF` once at init | `$FF` once at init |
| Hardware envelope | – | `HWENV` (NRx2 at note on, optional 2nd value after t ticks) | as v2 | `HWENV` is the pulse channels' only volume control |
| Release | `RELEASE t, rs` (software release phase), `NOTE_OFF` (decay table) | `RELEASE t, env` (one NRx2 write; CH3 sets the volume); the software release phase is dead | as v2, plus a minimum note length (hi nibble of t); `WAIT` blocks it, `WAIT2` doesn't | as v3 (CH3: decay rate and volume) |
| Command bytes | table `$60–$7F` (32), instr `$80–$99`, play-SFX `$9A–$AF`, arp `$B0–$BE`, vol `$BF–$CE`, vol+env `$CF–$DE`, length `$DF–$FF` (1–33) | table `$60–$7D` (30), instr `$7E–$97`, arp `$98–$A6`, vol `$A7–$B6`, vol+env `$B7–$C6`, length `$C7–$FF` (1–57) | table `$60–$84` (37), instr `$85–$9D`, arp `$9E–$AC`, vol `$AD–$BC`, vol+env `$BD–$CC`, length `$CD–$FF` (1–51). Pinocchio: table `$60–$83` (36), instr `$84–$9D`. Metal Masters: table `$5E–$84` (39) | table `$60–$83` (36; Spirou and later `$60–$84`), instr `$84–$8D`, arp `$8E–$A8`, vol+env `$A9–$B8`, length `$B9–$E8` (1–48), **repeat** `$E9–$FF` (later builds shifted, §2.2) |
| Instrument / arpeggio tables | one fixed table each | per song (`wInstrTable`/`wArpTable`, set by the song routine) | as v2 (`INSTR n` reads entry n + 1) | per song (Smurfs: one arpeggio table set by `SndInit`) |
| Pattern flow | `NEXT`, `ORDER_JUMP` | also `PAT_GOTO`, `PAT_CALL` (one level) | as v2, plus `CALL_CODE` (run machine code from a stream) | `NEXT`, `PAT_GOTO`, `PAT_CALL`, `CALL_CODE`, **`REPEAT n` / `REPEAT_END`**; `ORDER_JUMP` gone |
| Ch3 notes | −36 (written 3 octaves up) | no offset | no offset | no offset |
| Transpose | global | global + per channel | as v2 | as v2 (channel transpose defaults to −12) |
| Noise | fixed hits (`NOISE_HIT1/2`, instruments 2/3) | drum sequencer (`DRUMS`), 3 noise sequences, 7 drum sounds | drum sequencer whose sounds are **code in the song data** (each sets an NR43/NR42 sequence), plus pattern bytes for noise pan, level, speed and auto-pan; a "hold" timer protects long sounds; more noise routines through `CALL_CODE` | as v3, plus drum-pattern repeat and tempo bytes; `$FF` in an NR42 table = no write |
| Other | `CHORUS` (copy Ch1), `SLIDE`, `BEND`, dead NR51 "masks" | `WAVE`, `AUTOPAN`, `AUTODUTY`, NR50 fades (`StartFade`), stereo SFX via NR50 | adds `GLIDE_OFF`, `VIB_OFF`, `DRUMS_OFF`, `FADE`/`FADE_OFF` from the stream, `PORTA` (slide to the next note), `ENV_DIV` (envelope speed divider), `NOTE_PAN` (per-note pan sweep), SFX-only pause, NR51 only with a stereo flag; Metal Masters adds `ECHO_ON/OFF` | `PORTA`, `ENV_DIV`, `NOTE_PAN` gone; vibrato on a 16-bit pitch offset; new `SLIDE_UP/DOWN`, `VOL` as a command; Spirou and later add `NOTE_HOOK` |

Notable command renumbering from v1 to v2: `WAIT` `$6B` → `$63` (and `$61`), `REST` `$6C` → `$64`, `END` `$70` → `$66`, `NEXT` `$73` → `$68`, `ORDER_JUMP` `$74` → `$69`, `LENGTH` `$76` → `$6A`, `STOP_ALL` `$6D` → `$65`, `TRANSPOSE` `$72` → `$67`. The arpeggio loop byte follows `NEXT` (`$73` → `$68`), and the instrument terminators follow `END`/`NEXT`.

From v2 to v3 the order is kept but `GLIDE_OFF` is inserted after `GLIDE` and `VIB_OFF` after `VIBRATO`, so `WAIT2` and `VIBRATO` move up by 1 (`$62`, `$63`) and `WAIT` … `DRUMS` by 2 (`WAIT` `$65`, `REST` `$66`, `STOP_ALL` `$67`, `END` `$68`, `TRANSPOSE` `$69`, `NEXT` `$6A`, `ORDER_JUMP` `$6B`, `LENGTH` `$6C`, `DRUMS` `$6D`). Then `DRUMS_OFF` `$6E` is new, pan/duty/`HWENV`/`AUTOPAN`/`AUTODUTY` move up by 3 (`$6F–$77`), `FADE`/`FADE_OFF` are new (`$78/$79`), `WAVE` `$7A`, `PORTA`/`PORTA_OFF` new (`$7B/$7C`), `CH_TRANSPOSE` … `PAT_CALL` move up by 7 (`$7D–$81`), v2's `NOISE_SEQ2/3` and `NOISE_HIT7` are gone, and `CALL_CODE`, `ENV_DIV`, `NOTE_PAN` are new (`$82–$84`). The loop byte of arpeggios and fades is again the `NEXT` byte (`$6A`; Metal Masters `$68`). Metal Masters lowers every command by 2 (notes end at `$5D`) and appends `ECHO_ON/OFF` at `$83/$84`; Pinocchio has no `NOTE_PAN`, so its instruments start at `$84`.

Version 2 still contains version 1's `CHORUS_ON/OFF` handlers (no longer in the table) and still reads the v1 release fields, which suggests v2 was edited from v1's source rather than rewritten. Version 3 likewise still reads the dead release fields, keeps v2's `ResetChannel` Z-flag bug, and carries a few dead routines (old NR51 pan code in Astérix).

From v3 to v4 the bytes `$60–$6A` keep their meaning (`GLIDE` … `NEXT`). `ORDER_JUMP` is dropped, so `LENGTH` … `WAVE` move down by 1 (`LENGTH` `$6B`, `DRUMS` `$6C`, `DRUMS_OFF` `$6D`, `PAN_C/R/L` `$6E–$70`, `DUTY_50/75/12` `$71–$73`, `HWENV` `$74`, `AUTOPAN` `$75`, `AUTODUTY` `$76`, `FADE`/`FADE_OFF` `$77/$78`, `WAVE` `$79`). `PORTA`/`PORTA_OFF` are dropped, so `CH_TRANSPOSE` … `CALL_CODE` move down by 3 (`$7A–$7F`). `ENV_DIV` and `NOTE_PAN` are dropped. New are `REPEAT_END` `$80`, `VOL n` `$81` (no longer a range), `SLIDE_UP` `$82`, `SLIDE_DOWN` `$83` (Spirou, Prisoners of the Sun, Obélix GBC and the Lucky Luke group: `NOTE_HOOK` `$84`). Die Maus drops `SLIDE_UP`/`SLIDE_DOWN`: `NOTE_HOOK` moves to `$82`, and `PORTA step, lead` `$83` and `PORTA_OFF` `$84` are new. The arpeggio and fade loop byte stays `$6A`.

### 2.1 Within version 3

| | Pinocchio | Astérix | Metal Masters |
|---|---|---|---|
| Notes | `$00–$5F` | `$00–$5F` | `$00–$5D` |
| `NOTE_PAN` | – | `$84` | `$82` (also stops auto-pan) |
| Echo | – | – | `$83`/`$84` |
| Drum byte `$35` (noise auto-pan) | – | yes | yes |
| Auto-pan cycle | C R C L … | L R L R C | as Astérix |
| Auto-duty cycle | 75 12 75 50 … | 50 12 alternating | 50 75 12 |
| Handler call | bank-0 `push bc / ret` | local | local |
| Stereo flag set by the game | never (no panning) | yes | yes |

### 2.2 Within version 4

| | The Smurfs | Obélix GB | Tintin in Tibet | Spirou | Prisoners of the Sun | Obélix GBC |
|---|---|---|---|---|---|---|
| Year | 1994 | 1995 | 1995/96 | 1996 | 1997 | 1999 |
| Bank | 6 | 6 | 15 | 15 | 15 | 6 |
| Command table | `$4400`, 36 | `$4400`, 36 | **`$4000`**, 36 | `$4000`, **37** (`NOTE_HOOK`) | `$4000`, 37 | `$4000`, 37 |
| `INSTR` / `ARP` | `$84–$8D` / `$8E–$A8` | `$84–$90` / `$91–$AC` | as Obélix GB | `$85–$91` / `$92–$AD` | `$85–$95` / `$96–$B1` | as Prisoners of the Sun |
| `VOLENV` / `LEN` / `REPEAT` | `$A9` / `$B9` / `$E9` (2–24) | `$AD` / `$BD` / `$ED` (2–20) | as Obélix GB | `$AE` / `$BE` / `$EE` (2–19) | `$B2` / `$C2` / `$F2` (2–15) | as Prisoners of the Sun |
| Drum tempo bytes from | `$B9` | `$BD` | `$BD` | `$BE` | `$C2` | `$C2` |
| Pages / globals | `$C1–$C4` / `$C196` | `$C1–$C4` / `$C196` | `$C1–$C4` / `$C13C` | `$C1–$C4` / `$C142` | **`$DC–$DF` / `$DC42`** | `$C1–$C4` / `$C142` (+ duty shadows) |
| Arpeggio table | set by `SndInit` only | also set by every song | `SndInit` only | `SndInit` only | `SndInit` only | as Obélix GB |
| SFX priority | lower id wins | SFX 29 not interrupted | none | none | none | none |
| Pause / resume | pause silences, resume reloads the wave | as Smurfs | as Smurfs | as Smurfs | **both silence and reset the SFX page** (`StopAll`, `SongFadeIn` call resume) | as Prisoners of the Sun |
| Pulse NRx4 | high when changed, then high \| `$80` with the envelope | as Smurfs | as Smurfs | as Smurfs | **one write** | one write |
| Duty | NR11/NR21 directly | as Smurfs | as Smurfs | as Smurfs | as Smurfs | **shadows**, written every tick |
| NR31 / NR41 writes | – | – | – | – | – | **yes** |
| NR50 | forced to `$77` while no fade; `StartMusicCh3` = `$77` | also `StopAll` = `$77` | as Obélix GB | as Obélix GB | **no forcing**; fade byte `$80` = pause | as Prisoners of the Sun |
| Slide direction at note on | kept for slides (`bit 5`) | as Smurfs | as Smurfs | kept if bit 4 of the vibrato delay (slip) | always reset to down | as Prisoners of the Sun |
| `HWENV` | | | | | through `HwEnvAtten` (stub) | as Prisoners of the Sun |
| `SetVolEnvBC` (BC-fed `VOLENV` for hook code) | – | – | – | **used** by song 3's `NOTE_HOOK` | unreferenced | unreferenced |
| `wStereo` (NR51 = `$FF` while 0) | set by the game (`$01A8`) | **never written** (stays 0) | never written | never written | never written | `SndInit` sets `$FF` |
| Extra API | | `PlaySfxNow` | `PlaySfxNow` | `PlaySfxNow` | **`PlayCh1Tone`** (BC = period), `PlaySfxNow` | `PlaySfxNow` |

So only The Smurfs and Obélix GBC actually pan; in the other four builds (and in the Lucky Luke group, §2.3) the pan commands and drum pan bytes have no effect (no write to `wStereo` anywhere in the ROM, and it stays 0 through boot and the title screen in an emulator run).

### 2.3 The Lucky Luke group

| | Lucky Luke | The Smurfs' Nightmare | Die Maus |
|---|---|---|---|
| Bank | 12 | 2 | 15 |
| Command table | `$4000`, 37 (Spirou's set) | as Lucky Luke | `$4000`, 37: **`NOTE_HOOK $82`, `PORTA $83`, `PORTA_OFF $84`** (no `SLIDE_UP/DOWN`) |
| `INSTR` / `ARP` | `$85–$93` / `$94–$AF` | as Lucky Luke | `$85–$92` / `$93–$AB` |
| `VOLENV` / `LEN` / `REPEAT` | `$B0` / `$C0` / `$F0` (2–17) | as Lucky Luke | `$AC` / `$BC` / `$EC` (2–21) |
| Drum tempo bytes from | `$C0` | `$C0` | `$BC` |
| Pages / globals | **`$DB–$DE` / `$DB42`** | as Lucky Luke | `$C1–$C4` / **`$C14B`** (fields up to `$4A`) |
| Pulse NRx4 | one write (as Prisoners of the Sun) | as Lucky Luke | as Lucky Luke |
| Note-on direction | always reset | always reset | always reset |
| Pause / resume | as The Smurfs | as The Smurfs | **as Prisoners of the Sun**, but nothing else calls them |
| NR50 | forced to `$77` (as Spirou) | as Lucky Luke | as Lucky Luke |
| `INSTR` stops | – | **auto-duty** | **auto-duty and vibrato** |
| Porta | – | – | **look-ahead `PORTA`** (`PortaStart`, `PortaTick`, `AddPortaOffset`); used by one SFX |
| `NOTE_HOOK` / `SetVolEnvBC` | unused / unreferenced | unused / unreferenced | unused / unreferenced |
| Tick | game frame loop | game frame loop | timer, reloaded at VBlank |
| Songs / SFX | 17 / 40 | 18 / 16 | 9 (12 slots) / 61 |
| `wStereo` | never written | never written (songs 6–7 have pan commands) | never written |

Otto's Ottifanten and Sea Battle (details in their docs):

| | Otto's Ottifanten | Sea Battle | Sylvester and Tweety | Bugs Bunny & Lola Bunny |
|---|---|---|---|---|
| Driver | Die Maus's code unchanged | The Smurfs' Nightmare's, RAM one page higher, `StopAll` sets `wInstrTable` | Die Maus's, **ranges +1** (one more instrument) | Sea Battle's at The Smurfs' Nightmare's RAM (`StopAll` sets `wInstrTable` = `$7020`) |
| Bank | 3 | 4 | 15 | 2 (to `$77FF`; then game graphics) |
| Command set / ranges | as Die Maus | as Lucky Luke | Die Maus's set; **`INSTR $85–$93`, `ARP $94–$AC`, `VOLENV $AD`, `LEN $BD`, `REPEAT $ED`** (2–20) | as Lucky Luke |
| Pages / globals | `$C1–$C4` / `$C14B` | **`$DC–$DF` / `$DC42`** | `$C1–$C4` / `$C14B` | `$DB–$DE` / `$DB42` |
| Tick | timer, reloaded at VBlank (as Die Maus) | VBlank | timer, reloaded at VBlank (TMA `$D8`) | game frame loop |
| Pause / resume | as Die Maus, **called by the game** | as The Smurfs' Nightmare | as Die Maus, **called by the game** | as The Smurfs' Nightmare |
| Songs / SFX | 6 (12 slots; slots 7–12 jump into the instrument table) / 25 | 5 (18 slots; slots 6–18 jump into pattern data) / 13 | 9 (12 slots; slots 1, 10–12 = song 1 via 9 bytes of pattern data) / 56 | 16 (18 slots; slots 17–18 jump into unused patterns) / 21 |
| Song routines | set `wInstrTable` and `wArpTable` | `StopAll`, then `wInstrTable` (one table for all) | `StopAll`, then `wInstrTable` (one table for all) | `StopAll` (default table), 5 songs set a second table; songs 1 and 2 through `jp` stubs |
| `PORTA` | in songs 1, 2, 3, 5, 6 and SFX 7, 11, 15 | – | SFX 13 only | – |
| `wStereo` | never written | never written | never written | never written |

### 2.4 The Prisoners of the Sun group

| | Prisoners of the Sun | Turok | Turok 2 | Hugo 2 | V-Rally (GB / GBC) |
|---|---|---|---|---|---|
| Bank | 15 | 15 | 15 | **7** (sound data up to `$68EE`, then other data) | 2 / 16 (sound up to `$5F1F` / `$5FDA`, then other data) |
| `INSTR` / `ARP` | `$85–$95` / `$96–$B1` | **`$85–$97` / `$98–$B3`** | **`$85–$9A` / `$9B–$B6`** | as Prisoners of the Sun | as Turok |
| `VOLENV` / `LEN` / `REPEAT` | `$B2` / `$C2` / `$F2` (2–15) | **`$B4` / `$C4` / `$F4`** (2–13) | **`$B7` / `$C7` / `$F7`** (2–10) | as Prisoners of the Sun | as Turok |
| Drum tempo bytes from | `$C2` | `$C4` | `$C7` | `$C2` | `$C4` |
| API | 8 + `PlayCh1Tone` + 17 song slots + `PlaySfxNow` | 8 + `PlayCh1Tone` (unused by the game) + 13 + `PlaySfxNow` | as Turok | 8 + **8 songs + 7 dead slots** (`jp $5F8E`, pattern data); no `PlayCh1Tone`, no `PlaySfxNow` | 8 + **14 engine entries** + 13 song slots (7 / 8 songs, rest `jp` into the instrument table) + `PlaySfxNow`; no `PlayCh1Tone` |
| `StartMusicCh1/2/3` | `$48F0/$48F4/$48F8` | **`$48F0/$48FE/$490C`**, each sets `wInstrTable` = `$721A` | as Turok, `$732A` | as Prisoners of the Sun | **`$490E/$491C/$492A`**, each sets `wInstrTable` = `$5BCB` / `$5C6C` |
| Instrument table set by | each song | **`StartMusicChN`** (one table for all songs) | `StartMusicChN` and `SndInit` | **`StopAll`** (default `$6227`), then the song (5 of 8) | `StartMusicChN` (and each song) |
| `PlaySfxEntry` | `jp PlaySfx` | as Prisoners of the Sun | as Prisoners of the Sun | **game glue** at `$408F`: ids 2, 3 → noise routines `$64F1`, `$6561` | as Prisoners of the Sun |
| `CheckRelease` | | **"release on" tested first** (`$4442`; same result) | as Turok | as Prisoners of the Sun | as Turok |
| Drum table | 10 entries | 10 (new kit) | 10 | **11** | **9** |
| Songs / SFX | 14 (17 slots) / 21 | 13 / 39 | 13 / 31 (1–30 = Turok's) | 8 / 16 (2 noise-only) | 7 / 2 (GBC: 8 / 2) |
| End text | `Final de la rutina de musica` | `…de musicaca` | `…de musica` | – | `1998 by Alberto Jose Gonzalez.` (`$48A2`), `(Music & Sound Driver by Alberto Jose Gonzalez, 1998)` |
| Other | | | | | pages `$DB–$DE` / globals `$DB42`; `SndUpdate` → engine routine while `$DC91` ≠ 0; `StopAll` calls `EngineStop`; GBC: duty shadows, NR31, NR10 |

In Turok, Turok 2 and Hugo 2 the padding before the period table at `$4800` is PC memory garbage (x86 code bytes; Hugo 2 also a stale SM83 fragment); Prisoners of the Sun had a line of the driver's source there. In V-Rally it is zeros (and so is Otto's Ottifanten's); in Sea Battle it is x86 garbage again.

## 3. Notes for converters

- **Ticks:** one tick per frame (59.73 Hz) in Pop Up (normally), Bomb Jack, Astérix, Metal Masters, The Smurfs, Obélix, both Tintin games, Spirou, Lucky Luke, The Smurfs' Nightmare and Die Maus (its timer is reloaded every VBlank; free-running it would be 59.36 Hz); **53.89 Hz** (timer) in Pinocchio. Turok, Turok 2, Hugo 2 and Sea Battle run on VBlank (59.73 Hz) too; V-Rally from the game's frame loops; Otto's Ottifanten and Sylvester and Tweety like Die Maus (Sylvester's VBlank reload is `$D8`); Bugs Bunny from the game's frame loops. Obélix's glue runs `SndUpdate` twice every 4th frame for a while in some game states (25 % faster).
- **Lengths:** a note or wait lasts `length` ticks. `LEN`/`LENGTH` can also come from inside an instrument macro, so a converter has to run the instrument's commands to track the length (`tools/songlen.py` does this for v1/v2).
- **Instruments/arpeggios (v2, v3)** are looked up in the tables the song routine selected (the per-song table numbers are in each game's doc).
- **Pitch:** period index = note − 12 (v1 Ch3: − 48) + transposes. On CH3 the same period sounds an octave lower than on the pulse channels. In v3 also `GLIDE`, `PORTA` (slide to the next note's period) and, in Metal Masters, the echo (tied ticks take the pitch of an earlier note) change the pitch.
- **Ends:** `END` stops a channel, `STOP_ALL` the whole driver (in Pop Up song 2 this is how the jingle ends). Loops come only from the order lists (and `PAT_GOTO`).
- **v3 noise:** drum ids and `CALL_CODE` targets point at code; each game's doc lists what each routine plays (NR43/NR42 sequences, direct hits, NR10 sweep in Metal Masters).
- **v3 SFX:** Metal Masters plays most effects on the music pages (`PlayOnChN`), which ends the music on that channel.
- **v4 songs:** walk the API jump table for the songs. They start after the 8 API entries (`$4018` in The Smurfs and Obélix GB; Tibet `$4060`; Spirou, Obélix GBC, the Lucky Luke group and Hugo 2 `$4062`; Prisoners of the Sun, Turok and Turok 2 `$4065` after the ninth entry `PlayCh1Tone`), and the table ends with `PlaySfxNow`. Tell songs from other entries by whether the routine calls `StartMusicChN`. **Prisoners of the Sun repeats song 1 in slots 1 and 15–17, Die Maus in slots 1 and 10–12**: dedupe by routine. **The Smurfs has two jingles outside that table** (`$7DF3`, `$7ECD`), which the game starts by address. Songs are routines that may or may not set `wInstrTable`, and may start only two channels (Prisoners of the Sun song 10 has no Ch1).
- **Turok / Turok 2:** `StartMusicCh1/2/3` are at `$48F0/$48FE/$490C`, not 4 bytes apart, so a song routine scan must look for those three addresses. Every song uses the one instrument table that `StartMusicChN` sets (`$721A` / `$732A`).
- **Hugo 2:** API slots 9–15 are not songs (`jp $5F8E`, pattern data); stop at the first slot whose target doesn't call `StartMusicChN`, and don't dedupe them as songs. SFX 2 and 3 are noise routines started by the glue; their table entries are placeholders pointing into the table. The `PlaySfxNow` entry doesn't exist. Songs 2–4 use the instrument table `StopAll` sets (`$6227`).
- **Otto's Ottifanten:** song slots 7–12 are not songs (`jp $6888`, the instrument table). `PORTA` is used in the music (see the Die Maus note below).
- **Sea Battle:** song slots 6–18 are not songs (`jp $53A9`, pattern data). Song 1 starts only CH1 and CH3.
- **Sylvester and Tweety:** command ranges as Die Maus + 1 (read them from `tools/v4cfg.py`). Song slots 1 and 10–12 point at `$6B85`, 9 bytes of pattern data before song 1's routine (`$6B8E`): a routine scan that decodes from the slot target still reaches `StartMusicChN`, but dedupe them as song 1 and take the order lists from `$6B8E`. Tick as Die Maus (timer reloaded every VBlank).
- **Bugs Bunny & Lola Bunny:** slots 1 and 2 are `jp` stubs (follow the `jp`); song 2 (`$4CBD`) is the long version of song 1. Slots 17–18 are not songs (`jp $6F8F`, unused patterns, then the instrument table). Songs that set no instrument table use `StopAll`'s (`$7020`).
- **V-Rally:** after the 8 API entries come 14 engine entries (not songs; they don't call `StartMusicChN`), then the song slots; `StartMusicCh1/2/3` are at `$490E/$491C/$492A`. The last 6 (GB) / 5 (GBC) song slots jump into the instrument table. Songs use the one instrument table that `StartMusicChN` sets. During a race the engine routine replaces `SndUpdate` entirely, so no music plays there.
- **v4 `NOTE_HOOK`** (Spirou song 3, Ch3): with the hook on, every note calls `on_note`, and every `WAIT`/`WAIT2` calls `on_wait` and then **plays the previous note again** (field `$3C`). Spirou's hooks only set an envelope (`VOLENV` 15 at notes, 10 at waits), so this is an echo of the previous note at each wait.
- **v4 panning:** only The Smurfs and Obélix GBC set `wStereo`; for the other builds a converter should output no panning.
- **Die Maus `PORTA step, lead`:** from each note on, slide the period towards the next note during its last `lead` ticks, `step` period units per tick, stopping at the target. The driver finds the next note by a loose scan (`Maus_SoundDriver.md` §2.1). Only SFX 21 uses it.
- **v4 command ranges:** read them per game (`tools/v4cfg.py`); the Lucky Luke group adds three more sets of `INSTR`/`ARP`/`VOLENV`/`LEN`/`REPEAT` boundaries (Lucky Luke, The Smurfs' Nightmare, Sea Battle and Bugs Bunny share one; Die Maus and Otto's Ottifanten another; Sylvester and Tweety has its own), and Turok and Turok 2 one each (V-Rally uses Turok's, Hugo 2 Prisoners of the Sun's).
- **v4 repeats:** `REPEAT n` … `REPEAT_END` (one level per channel) inside patterns, and `DRUM_REPEAT` … `DRUM_REPEAT_END` in drum patterns.
- **v4 pitch:** period index = note + glide (accumulated per tick) + channel transpose (default −12) + arpeggio + global transpose, ≥ 80 wraps to 0. Vibrato and `SLIDE_UP/DOWN` add a 16-bit offset to the *period*, not the note. A slide runs for 255 ticks from every note.
- **v4 volume:** pulse channels play the `HWENV` NRx2 value (hardware envelope) at each note, optionally a second value t ticks later, `RELEASE`'s value, or 0 on `REST`. CH3 uses `VOLENV`/`VOL` and the software envelope.

## 4. Tools (shared, in `GBAudioLab\AJG\tools`)

`sm83.py` (decoder), `disasm.py` / `listing.py` / `codetrace.py` (disassembly and code tracing), `asmgen.py` (byte-exact RGBDS generator: code, labels, data items; now also writes the ROMX bank), `notes.py` (note names), per-game data walkers / generators / models, `songlen.py`, `cmp_ranges.py`. Verification: `verify/build_harness.py`, `vmodel.py`, `run_all.sh`.

Version 3 (banked ROMs): `bank.py` (bank 0 + bank n view), `v3cfg.py` (command sets, ranges and constants per game), `v3data.py` (data walker: order lists followed through `NEXT`, streams, instrument/arpeggio tables sized from what each song reaches, drum patterns, fades, waves, noise tables found by reading the drum and `CALL_CODE` routines), `v3names.py` (Astérix names and comments), `v3games.py` (entries, songs, sections, per-game overrides), `gen_v3.py` (one generator for all three; carries the Astérix routine names to the other games by aligning their code), `cmp_banked.py` (compare banked ranges), `handlers.py` / `v3list.py` (command handler dumps and normalized listings for comparing versions). Verification: `verify/v3trace.py` (PyBoy harness written over the game's start-up code, any bank; checks every song/SFX against the data walk), `verify/run_v3.sh`, `run_v3.log`.

Version 4 (now eighteen builds): `v4cfg.py` (command sets including Die Maus's, ranges, global layout, bank per game; `startmusic_list` for Turok's `StartMusicChN` spacing, `sfx_dummy` for SFX ids played by game glue), `v4data.py` (data walker; drum patterns are walked last and stop at other data, because several have no `$FF`), `v4names.py` (Smurfs names and comments, per-game comment overrides that the later builds inherit along the reference chain), `v4games.py` (per-game entries; `ref` gives the build a game's names are carried from: Smurfs → Obélix GB → Tibet, Smurfs → Obélix GBC → Prisoners of the Sun and Spirou, Spirou → Lucky Luke → The Smurfs' Nightmare and Die Maus, Prisoners of the Sun → Hugo 2 and Turok → Turok 2 and V-Rally GB → V-Rally GBC; Die Maus → Otto's Ottifanten and Sylvester and Tweety; The Smurfs' Nightmare → Sea Battle → Bugs Bunny; `text_items` for ASCII text in a bank, `jt_dead` for API slots that point into data (anywhere in the table), `jt_fall` for slots that point into data which runs into a song routine (Sylvester and Tweety), `noise_sfx` for glue-started noise SFX), `gen_v4.py` (generator for all eighteen builds), `v4diff.py` (normalised code diff of two v4 drivers; optional end address, `4C74` for the Die Maus line), `blist.py` (banked listing), `tlist.py` (traced banked listing from the API and command tables). Verification: `verify/v4trace.py` (as `v3trace.py`; it also checks every byte the drum sequencer reads, including 600 ticks after a one-shot song ends), `verify/run_v4.sh`, `run_v4.log`.

For a new game: a data walker (`<game>_data.py`, command arguments and terminators), a generator config (sections, entry points, labels, comments) and, for full verification, a model built from that game's document. For another version-3 game, a new entry in `v3cfg.py` and `v3games.py` is usually enough.
