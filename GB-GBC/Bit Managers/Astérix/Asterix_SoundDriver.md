# Astérix (GB): sound driver

ROM: `Asterix (UE) (M5) [!].gb` (DMG, MBC1, 128 KB, internal title `ASTERIX`). Infogrames, 1993.

Part of the AJG family (Alberto José González / Bit Managers), see `AJG_SoundEngine_Family.md`. This is **version 3**, the reference for the two other version-3 games documented with it (`Pinocchio_SoundDriver.md`, an earlier variant, and `MetalMasters_SoundDriver.md`, a later one). It keeps version 2's design (Bomb Jack) and adds: banked code with globals in WRAM, a 37-command table, portamento, a per-note pan sweep, an envelope divider, `CALL_CODE` (run machine code from a stream), NR50 fades from the stream, song-specific drum sounds written as code, and an SFX-only pause mode. Software volume no longer retriggers the pulse channels every tick.

| | |
|---|---|
| Bank | the whole driver and all its data are in **ROM bank 3**, `$4A8C–$7F1A` |
| API | `$52E3` `SndInit`, `$4AAC` `SndUpdate`, `$4E6F` `StopAll`, `$56A6` `PlaySfx` (A = id 1–24), `$5181` `StartFade` (A = speed, HL = NR50 table), `$4A91` / `$4A8C` `SndPause` / `SndResume`, `$56D6/$56DA/$56DE` `PlayOnCh1/2/3` (SFX on a music page). Songs: one start routine per song (§3.1); `$5709` `SongFadeOut` |
| Tick | **VBlank**, every frame (59.73 Hz). The game's VBlank handler ends in its sound glue at `$0914` (bank 0) |
| Game glue (bank 0) | `$0914`: switch to bank 3; if the word at `$DB44` is set, clear it and call that address (how the game starts songs and `SongFadeOut`); if `$DB42` ≠ `$FF`, play that SFX unless a **lower** id is playing (`$DB42` is filled by `$0976`, which also keeps the lower id); then `SndUpdate`. `$0988` (reset) calls `StopAll` + `SndUpdate` |
| RAM | four `$100`-byte pages: Ch1 `$DCxx`, Ch2 `$DDxx`, Ch3 `$DExx`, SFX `$DFxx` (fields `$00–$3F`); globals `$DB46–$DB6B` |
| Channels | music on CH1–CH3; SFX on **CH3** (the SFX page replaces Ch3 in the output, as in Bomb Jack). CH4 is driven by the drum sequencer and the noise sequences |
| Counts | 13 songs, 24 sound effects, 3 instrument tables (10 + 6 + 10 instruments), 1 arpeggio table (13), 14 waves, 10 drum sounds + 7 more noise routines called with `CALL_CODE`, 16 drum patterns |

`Asterix_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over ROM0 `$0000–$0002`, `$0008–$000B`, `$0018–$001D`, `$1A90–$1A98` and bank 3 `$4A8C–$7F1A`. It assembles cleanly with `-Wall` and needs no `hardware.inc`.

```
rgbasm -Wall -o asterix.o Asterix_SoundDriver.asm
rgblink -o asterix.gb asterix.o
python tools/cmp_banked.py asterix.gb "Asterix (UE) (M5) [!].gb" 0000-0002 0008-000B 0018-001D 1A90-1A98 3:4A8C-7F1A
```

---

## 1. Structure

`SndUpdate`:

1. `DoFade` (§4.3).
2. If `wPaused` (`$DB54`): tick and output **only the SFX page**, skip to 5.
3. `ChannelTick` on Ch1, Ch2, Ch3, SFX; `DrumTick` (drum hold, drum timer → `DrumStep`, then `NoiseSeqTick`).
4. `OutputAll`: Ch1, Ch2, then **the SFX page if it plays, otherwise Ch3**.
5. NR51 = Ch1 field `$3D` | Ch2 `$3D` rotated 1 | (SFX or Ch3) `$3D` rotated 2 | `wNoisePan`, but **`$FF` while `wStereo` (`$DB55`) = 0**. Astérix sets `wStereo` = 1 at boot.

`SndInit` copies a 12-byte init block into fields `$00–$0B` of each page (fields `$06/$08/$0A` = I/O addresses of NRx3/NRx4/NRx2, the SFX page gets Ch3's), clears `$0C–$3F`, sets **NR52 = `$FF`** once (version 2 rewrote NR52 every tick), noise pan centre, `StopAll`.

`SndPause` silences CH1–CH4 (NRx2 = 0, trigger) and sets `wPaused`; `SndResume` clears it. The game never calls either.

### 1.1 Output (`OutputChannel`)

- NRx3 = period low every tick; NRx4 = period high (no trigger) only when it differs from the shadow (`wShFreqHi1–3` `$DB46–$DB48`; the SFX page uses `$DB49`, which is also the NR32 shadow).
- **Software volume** (field `$27` = 0): pulse channels compute vol << 4 and compare it with the **NRx2 register itself**; only when it differs it is written with a retrigger (NR14 = shadow | `$80` for Ch1, NR24 for anything else). So a held note is no longer retriggered every tick. CH3: NR32 = `Ch3VolTable[vol]` when it differs from `wShNR32`.
- **Hardware envelope** (field `$27` ≠ 0): when field `$32` is set, NRx2 = field `$31` and the same retrigger.

### 1.2 Channel fields

| Off | Use |
|---|---|
| `$00/$01` | order position |
| `$02/$03` | stream pointer |
| `$04` | flags: b0 arpeggio, b1 release armed, b2 released, b3 vibrato, b4 portamento, b6 vibrato direction |
| `$05` | ticks left |
| `$06/$07`, `$08/$09`, `$0A` | NRx3 address / period low, NRx4 address / period high, NRx2 address |
| `$0B` | volume 0–15 |
| `$0C`, `$0D` | note, length |
| `$0E` | glide (added to the note every tick) |
| `$0F` | channel transpose |
| `$10` | active; on the SFX page the SFX id (`$DF10`) |
| `$11–$16`, `$17` | `VOLENV` attack/decay (split at note on), start volume |
| `$18/$19`, `$1E/$1F` | envelope release phase: never set (dead, as in version 2) |
| `$1A–$1D` | attack / decay rate counters and reloads |
| `$1F/$20`, `$21` | arpeggio pointer, index |
| `$22–$26` | vibrato: delay counter, depth, counter, speed, delay |
| `$27–$2A` | `HWENV`: envelope (0 = software volume), env2 delay / counter, env2 |
| `$2B–$2D`, `$2E–$30` | auto-pan, auto-duty: period / counter / step |
| `$31`, `$32` | NRx2 value to write, write flag |
| `$33`, `$34` | `PORTA` speed, delay |
| `$35`, `$36`, `$37/$38` | portamento delay counter, direction (1 down, 2 up), target period |
| `$39`, `$3A` | `RELEASE` minimum length / ticks left, release envelope |
| `$3B/$3C` | `PAT_CALL` return address (one level) |
| `$3D` | pan bits for NR51 (`$11` centre, `$01` right, `$10` left; rotated per channel) |
| `$3E` | `ENV_DIV`: reload (hi) / counter (lo) |
| `$3F` | `NOTE_PAN`: `$80` + n while a note runs |

### 1.3 Globals (`$DB46–$DB6B`)

Period-hi shadows `$DB46–$DB48`, `wShNR32` `$DB49`, `wInInstr` `$DB4A` (`$C9` while an instrument macro runs), `wTranspose` `$DB4B`, `wNoisePan` `$DB4C`, `wDrumHold` `$DB4D`, `wInstrTable` `$DB4E/4F`, `wArpTable` `$DB50/51`, `wMusicWave` `$DB52/53`, `wPaused` `$DB54`, `wStereo` `$DB55`, `wNoiseAutoPan` `$DB56`. Drums: pattern `$DB57/58` (**hi byte first**), position `$DB59`, on `$DB5A`, tempo `$DB5B`, timer `$DB5C`. Noise sequence: NR43 / NR42 table pointers `$DB5D–$DB60` (hi first), position `$DB61`, on `$DB62`, attenuation `$DB63`, timer `$DB64`, speed `$DB65`. Fade: table `$DB66/67`, position `$DB68`, timer `$DB69`, speed `$DB6A`, on `$DB6B`.

---

## 2. One tick (`ChannelTick`, active pages only)

1. auto-duty, 2. auto-pan, 3. glide, 4. envelope (through the divider), 5. arpeggio, 6. vibrato, 7. portamento, 8. release check, 9. note-pan, 10. `len` − 1 → at 0 read the stream.

- **Envelope divider** (`ENV_DIV n`, field `$3E`): the software envelope runs only when the low nibble is 0; it then reloads it from the high nibble. With `$3E` = `$h0` the envelope steps every h + 1 ticks. `VOLENV` clears `$3E`.
- **Auto-duty** (`AUTODUTY n`): every n ticks 50 %, 12.5 %, 50 %, 12.5 % … (strict alternation). **Auto-pan** (`AUTOPAN n`): left, right, left, right, centre, repeat. Instruments switch both off.
- **Arpeggio:** the next table byte is added to the note; `$6A` (the `NEXT` byte) loops, `$FF` holds.
- **Vibrato:** as version 2.
- **Portamento** (`PORTA speed, delay`): see §3.4.
- **Release check** (`RELEASE t, env`, t = `$mT`): skipped for notes whose length is below m; on the tick where `len` = T, unless the next stream byte is `WAIT` (`$65`): pulse NRx2 = env (via `$31/$32`); CH3/SFX volume = env >> 4. **`WAIT2` (`$62`) is a tie that does not stop the release**; this is the only difference between the two.
- **Note-pan** (`NOTE_PAN n`): counted from the note's start: centre at 0, left after n ticks, right after 2n, centre after 3n, then it stops until the next note.

**Note on** (byte < `$60`): store note and pointer, period, restart the arpeggio (first step applied at once), reload the hardware envelope, start the portamento search, `len` = length, arm the note-pan, restart vibrato, clear the released flag, volume = start volume, split the attack/decay bytes.

**Period:** index = note − 12 + `wTranspose` (not on the SFX page) + channel transpose → `PeriodTable` (the same 81 entries as versions 1 and 2, from C2).

---

## 3. Data format

### 3.1 Songs

A song is started by a routine in the data area: NR50 = `$77`, fade off, set `wInstrTable`/`wArpTable`, then `StartMusicCh1/2/3` with an order list each (`StartMusicChN` resets the page and starts the first pattern). Order lists are `dw pattern …, 0, loop_position` as before; several songs have one-entry "lists" whose pattern ends with `END`.

| Song | Routine | Ch1 / Ch2 / Ch3 order lists | Instr. table | Length (ticks) |
|---|---|---|---|---|
| 1 | `$5712` | `$5747 / $574B / $5749` | 1 | 576, ends |
| 2 | `$585F` | `$5894 / $58A4 / $58B4` | 1 | loops |
| 3 | `$5D42` | `$5DEC / $5DBC / $5D77` | 3 | loops |
| 4 | `$5E3C` | `$5E6B / $5F1A / $5FB8` | 3 | loops |
| 5 | `$60B8` | `$60E7 / $6131 / $617C` | 3 | loops |
| 6 | `$61FC` | `$622B / $62E2 / $6382` | 3 | loops |
| 7 | `$654B` | `$657A / $657C / $657E` | 3 | 516, ends |
| 8 | `$66AF` | `$66DE / $66E0 / $66E2` | 3 | 132, ends |
| 9 | `$676B` | `$679A / $6806 / $67E4` | 3 | loops |
| 10 | `$6A95` | `$6AC4 / $6B08 / $6AEA` | 2 | loops |
| 11 | `$6E62` | `$6E96 / $6E9A / $6E98` | 2 | 476, ends; also starts SFX 12 |
| 12 | `$76CB` | `$7700 / $7710 / $7720` | 1 | loops |
| 13 | `$7C65` | `$7C9A / $7CA8 / $7CB8` | 1 | loops |

(Numbering is by address; the game refers to the routines from its level tables in bank 0.) Instrument tables: 1 `$5CDC`, 2 `$75C0`, 3 `$7600`; all songs use the arpeggio table `$7668`. `INSTR n` reads entry n + 1 of the table (entry 0 is never read; table 3's entry 0 is the last two bytes of table 2's last instrument). **SFX use whatever tables the last song set** (none of the 24 uses instruments).

### 3.2 Stream bytes

| Byte | Macro | Meaning |
|---|---|---|
| `$00–$5F` | `NOTE p, o` | note, ends the tick |
| `$60 n` / `$61` | `GLIDE n` / `GLIDE_OFF` | note += n every tick |
| `$62` | `WAIT2` | wait one length; the release still happens |
| `$63 d, depth, speed` / `$64` | `VIBRATO` / `VIB_OFF` | |
| `$65` | `WAIT` | wait one length (tie); suppresses the release |
| `$66` | `REST` | volume 0 (pulse pages also NRx2 = 0), wait |
| `$67` | `STOP_ALL` | |
| `$68` | `END` | centre pan; SFX page: restore the music wave; reset the page |
| `$69 n` | `TRANSPOSE n` | global |
| `$6A` | `NEXT` | return from `PAT_CALL`, else next order entry |
| `$6B w` | `ORDER_JUMP w` | |
| `$6C n` | `LENGTH n` | |
| `$6D t, w` / `$6E` | `DRUMS` / `DRUMS_OFF` | drum pattern w, one step every t ticks (§4.1) |
| `$6F` / `$70` / `$71` | `PAN_C/R/L` | |
| `$72` / `$73` / `$74` | `DUTY_50/75/12` | written straight to NR11/NR21 (CH1/CH2 pages only) |
| `$75 e, 0` / `$75 e, t, e2` | `HWENV` | hardware envelope mode; NRx2 = e2 after t ticks |
| `$76 n` / `$77 n` | `AUTOPAN` / `AUTODUTY` | 0 = off |
| `$78 s, w` / `$79` | `FADE` / `FADE_OFF` | NR50 table w, one byte every s + 1 ticks (§4.3) |
| `$7A w` | `WAVE w` | Ch3: remember w, load it unless an SFX plays; other pages: load w |
| `$7B speed, delay` / `$7C` | `PORTA` / `PORTA_OFF` | §3.4 |
| `$7D n` | `CH_TRANSPOSE n` | |
| `$7E 0` / `$7E t, env` | `RELEASE` | t = min length << 4 \| ticks left |
| `$7F` | `ARP_OFF` | |
| `$80 w` / `$81 w` | `PAT_GOTO` / `PAT_CALL` | `PAT_CALL` is one level deep |
| `$82 w` | `CALL_CODE w` | call machine code at w (it returns into the command loop) |
| `$83 n` | `ENV_DIV n` | §2 |
| `$84 n` | `NOTE_PAN n` | §2 |
| `$85–$9D` | `INSTR n` | instrument n (0–24) of the song's table |
| `$9E–$AC` | `ARP n` | arpeggio 0–14 |
| `$AD–$BC` | `VOL v` | start volume |
| `$BD–$CC a d r` | `VOLENV v, atk, dec, rates` | start volume + envelope; software volume mode, clears `ENV_DIV` |
| `$CD–$FF` | `LEN n` | length 1–51 |

Not used by the data: `WAIT2`, `VIB_OFF`, `STOP_ALL`, `ORDER_JUMP`, `FADE`, `FADE_OFF`, `ENV_DIV`.

### 3.3 Instruments and arpeggios

`INSTR n` clears vibrato, arpeggio, glide, auto-pan, auto-duty, hardware-envelope mode and the note-pan, centres the pan, sets 50 % duty, then runs the macro until `END` (`$68`) or `NEXT` (`$6A`). Macros use commands only: here `VOLENV`, `HWENV`, `ARP`, `WAVE`, `DUTY_*`, `PAN_*`, `GLIDE`, `RELEASE`, `AUTOPAN`, `AUTODUTY`, `NOTE_PAN`. Arpeggios are offset lists ending in `$6A` (loop) or `$FF` (hold).

### 3.4 Portamento

`PORTA speed, delay` (flag b4). At each note the driver looks ahead in the stream for the next note: the slide starts after this note's length (plus one length per following `WAIT`/`REST`) minus `delay` ticks, and moves the period by `speed` per tick towards the next note's period, stopping on it. `END`/`NEXT` before the next note cancel it. The look-ahead only skips the arguments of `PORTA` and `VOLENV`; other commands with arguments between two notes would be misread (the data never does this).

### 3.5 Sound effects

`PlaySfx` (A = id): resets the SFX page if it is busy (no priority test: the bank-0 glue keeps the lower id), starts the stream from `SfxTable` (`$700C`, 24 entries) and runs its first tick and output inside the call. SFX streams use `WAVE`, `LEN`, `LENGTH`, `VOL`/`VOLENV`, notes, `WAIT`, `REST`, `GLIDE`, `ARP`, `PORTA`, `RELEASE`, `CALL_CODE`, `END`.

| Id | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 24 | 60 | 17 | 10 | 0* | 7 | 13 | 15 | 19 | 14 | 74 | 39 | 25 | 3 | 27 | 23 | 9 | 0* | 3 | 15 | 9 | 7 | 52 | 29 |

\* SFX 5 and 18 are noise only: `CALL_CODE` starts a noise routine (`$74F2`, `$74C5`) and the stream ends at once.

`$6F94–$7009` holds 24 stubs `ld a, id / jp PlaySfx` (no callers found). `PlayOnCh1/2/3` (SFX stream on a music page, which ends that channel's music) exist but are unused in Astérix; Metal Masters uses them.

### 3.6 Waves

14 waves are referenced (`Wave_xxxx`): 13 at `$71F3–$7302` and one at `$7F0B` (the last bytes of the driver's data). A few unreferenced 16-byte blocks between them look like more waves. Loading: NR30 = 0, copy, NR30 = NR34 = Ch3 period-hi shadow | `$80`.

---

## 4. Noise and fades

### 4.1 Drum sequencer

`DRUMS t, w`: one step every t ticks. A step reads pattern bytes:

| Byte | Meaning |
|---|---|
| `$00` | nothing (end of step) |
| `$FF` | back to the start (re-read) |
| `$32` / `$33` / `$34` | noise pan centre / right / left (`$33`/`$34` ignored while `wDrumHold` runs), read on |
| `$35 n` | noise auto-pan: centre, right after n noise steps, left after 2n, centre after 3n; read on |
| `$64–$73` | noise level 0–15 (NR42 volume − (15 − level)), read on |
| `$74+` | noise sequence speed (one step every b − `$74` + 1 ticks), read on |
| others | drum sound n from `DrumTable` (`$4FB3`), skipped while `wDrumHold` runs |

Drum sounds and the noise routines called with `CALL_CODE` are **code in the song data**: each sets the noise-sequence pointers (NR43 table, optional NR42 table) and starts it. The `CALL_CODE` ones also set `wDrumHold` (8–19 ticks) and centre the noise pan, and some write NR42/NR44 themselves and use an NR43-only sequence.

| Drum | Routine | NR43 sequence | NR42 sequence |
|---|---|---|---|
| 1 | `$738B` | `02 51 61 71 91 71 60` | `F0 F0 D0 90 70 50 41` |
| 2 | `$73DC` | `60 52 42 41 22 11 04` | `F0 F0 F0 A0 30 40 53` |
| 3 | `$7434` | `50 41 50 51 52 53 51` | `F0 70 F0 70 D0 70 83` |
| 4 | `$7451` | `04 02 06 06` | `C0 80 60 54` |
| 5 | `$746E` | `04 02 01 01 04 02 01` | `A0 60 33 23 A0 60 33` |
| 6 | `$748B` | `04 02 01 01` | `80 60 40 23` |
| 7 | `$74A8` | `06 04 03 03 07` | `F0 F0 D0 C0 85` |
| 8 | `$73B0` | as 1 | `F0 F0 F0 F0 F0 70 52` |
| 9 | `$7EC7` | `51 32` | `F0 81` |
| 10 | `$7EE9` | `51 32` | `90 51` |

`CALL_CODE` noise routines: `$7383` (drum 1 + hold 8), `$73A8` (drum 8 + hold 10), `$73F9` (hold 8), `$74C5`, `$74F2`, `$7534`, `$7561` (NR42 written directly, NR43-only sequences, hold 10–19).

### 4.2 Noise sequences

Every speed + 1 ticks: NR43 = `seq43[i]`; with an NR42 table also NR42 = `seq42[i]` − attenuation << 4 (on underflow only the envelope bits are kept) and NR44 = `$80`. `$FF` in the NR43 table ends it. The `$35` auto-pan is applied here.

### 4.3 NR50 fades

`StartFade` / `FADE`: one table byte into NR50 every speed + 1 ticks; `$6A` loops, `$FF` ends. `SongFadeOut` uses `FadeOutTable` (`77 66 55 44 33 22 11 00 FF`) at speed 4. Three more tables (`$51F3–$522B`: two stereo sweeps and a fade-in/out) are unused. **While no fade runs, NR50 is forced to `$77` every tick unless it is 0.**

---

## 5. Timing

59.73 Hz. Songs 1, 7, 8, 11 are one-shot (576, 516, 132, 476 ticks); the others loop.

---

## 6. Quirks and bugs

1. **`ResetChannel` always silences the channel**, also on the SFX page while Ch3 plays: the test reuses the Z flag of an earlier compare (same bug as Bomb Jack). It also leaves `HWENV` mode (`$27`), `RELEASE` and `ENV_DIV` set; only `VOLENV`/`INSTR` clear the hardware-envelope mode.
2. **The SFX page's period-hi shadow is `wShNR32`** (shared with the CH3 volume shadow); reset/`END` bump it so the next CH3 volume write isn't skipped.
3. **`SndPause` jumps into `RestoreMusicWave` with the caller's H**: it writes NR32 from `[(H − 1):0B]` (via the game's `$DB44` call, `$DA0B`). Unused by the game.
4. **`HWENV` on CH3** writes the envelope byte to NR32 and retriggers **NR24** (CH2), as in Bomb Jack.
5. **`END` on the SFX page** restores the music wave and writes NR32 = Ch3's raw volume field.
6. **Drum pattern `$6F8D` has no `$FF`**: it is followed by the SFX stubs. Song 11 turns the drums off 3 notes later, before step 7 would be read.
7. **Portamento look-ahead** misreads commands with arguments other than `PORTA`/`VOLENV` (§3.4).
8. **`PAT_CALL` is one level**; a pending return takes priority over `ORDER_JUMP`.
9. **Arpeggio `$FF` hold** at the first entry would hang (none does).
10. **Song routines don't call `StopAll`:** `StartMusicChN` resets only its own page, so drums or a noise sequence left by the previous song keep running until the new song's first `DRUMS`/`DRUMS_OFF`, unless the game has called `StopAll` before (it also posts `StopAll` through `$DB44`).
11. **Dead code/data:** `$4D46` (`ret`), `$50B7–$50D5` (old NR51 pan routines), `$510F` (`ret`), `$55F0–$55F3`, the unused fade tables, `PlayOnCh1–3`, `SndPause`/`SndResume`, the SFX stubs, entry 0 of the SFX table, and some unreferenced patterns, waves and noise tables in the data area (marked "Unreferenced" in the asm).

---

## 7. Verification (lighter)

- **Byte-exact rebuild** of all ranges (`tools/cmp_banked.py`).
- **Emulator trace** (`verify/v3trace.py`): the real driver runs in PyBoy from a harness written over the game's start-up code; every song (6000 ticks) and every SFX is started after `StopAll`, and on every tick the saved stream pointer and order position of each active page, and the drum pattern position, must fall on items of the data walk that generated the asm. **0 problems** (`verify/run_v3.log`). This checks the command lengths, terminators, order lists and drum patterns that the asm encodes, and gives the lengths above.
- **Not done this time:** no independent model of the driver (versions 1 and 2 had one), so effects, envelopes and output are documented from the code, not cross-checked tick by tick.

## Files (in `GBAudioLab\AJG`)

- `Asterix_SoundDriver.asm`: labelled, commented RGBDS source with data macros, byte-exact
- `tools/`: `gen_v3.py` (generator for all three version-3 games), `v3cfg.py` (command sets and per-game constants), `v3data.py` (data walker), `v3names.py` (Astérix names and comments, carried over to the other two by code alignment), `v3games.py` (entries, songs, sections), `bank.py`, `cmp_banked.py`, `handlers.py`, `v3list.py`
- `verify/`: `v3trace.py`, `run_v3.sh`, `run_v3.log`

Regenerate: `python tools/gen_v3.py asterix "Asterix (UE) (M5) [!].gb" Asterix_SoundDriver.asm` (from the `AJG` folder).
