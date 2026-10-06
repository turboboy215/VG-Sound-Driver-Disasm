# AudioArts "QuickThunder" (GB/GBC): sound driver

AudioArts' Game Boy sound driver, written by Michael Delaney; the GBA QuickThunder (Robocop, V-Rally 3) is its descendant. This document covers nine builds in `GBAudioLab\AA`. Every one rebuilds **byte-exact** with RGBDS 0.9.1 (`-Wall` clean) from the generated sources in `AA\QuickThunder`.

| Key | File | Sound data | Driver code | Driver RAM | Songs / SFX |
|---|---|---|---|---|---|
| Carmageddon | `Carmageddon (UE) (M4) [C][!].gbc` | bank `$41`: `$4000–$53F9` | `$4000–$45F4` + engine-wave module `$532A–$5369` | `$D800–$D847` | 3 (+1 null entry) / 16 |
| Casper (U) | `Casper (U) [C][!].gbc` | bank `$1F`: `$4000–$675C` | `$4000–$4867` | `$D000–$D062` (WRAM bank 4) | 4 (+1 invalid) / 25 |
| Casper (E) | `Casper (E) (M3) (Eng-Fre-Ger) [C][!].gbc` | bank `$1F`: `$4000–$66CD` | `$4000–$4886` | `$D000–$D068` (WRAM bank 4) | 4 (+1 invalid) / 25 |
| Chicken Run (test) | `GB Audioarts Sounds - Chicken Run (PD).gb` | bank 1: `$4000–$7200` | `$4000–$4886` | `$C080–$C0E8` | 9 / 29 |
| Ghosts 'n Goblins (test) | `GB Audioarts Sounds - Ghosts n Goblins (PD).gb` | bank 1: `$4000–$5BD7` | `$4000–$4865` | `$C100–$C167` | 11 / 12 |
| Dukes of Hazzard (test) | `GB Audioarts Sounds - Dukes of Hazzard (PD).gb` | bank 1: `$4000–$5CAA` | `$4000–$48E3` | `$C100–$C16B` | 28 / 3 |
| Extreme Ghostbusters | `Extreme Ghostbusters (E) (M6) [C][!].gbc` | bank 2: `$4000–$7B50` | `$4000–$48E1` | `$C0A0–$C10B` | 10 / 18 |
| Colin McRae Rally | `Colin McRae Rally (E) [C][!].gbc` | bank `$7D`: `$4000–$57AD`; PCM `$7D:57AE–7ABB`, banks `$7E`, `$7F` | `$4000–$47B9` | `$C100–$C16E` | 46 / 4 + 31 PCM |
| 3-D Ultra Pinball: Thrillride | `musicd.bin` (raw, linked at `$4000`) | all 14,598 bytes: `$4000–$7905` | `$4000–$48DE` | `$C594–$C5FF` | 11 / 89 |

```
QuickThunder\build_check.sh   # assemble + link all nine, compare with the ROMs in AA\
QuickThunder\regen.sh         # regenerate the sources from the ROMs (tools\qtgen.py)
```

Release dates don't follow the driver versions. Grouped by features, the builds form four families. The rest of this document uses these names:

- **A:** Carmageddon. Three channels, fixed tempo, no wave channel.
- **B:** Casper (U).
- **C:** Casper (E) and the Chicken Run test ROM. Their code is identical except for the RAM base, the SFX tick and the two id limits. The Ghosts 'n Goblins test ROM is C without SFX priorities or id checks, which puts it between B and C.
- **D:** Dukes test, `musicd.bin` (Pinball), Extreme Ghostbusters, Colin McRae. Colin McRae is a PCM variant.

---

## 1. Sources and provenance

**Source text in the Dukes test ROM.** `$1530–$3FFF` and `$5CAB–$7FFF` of the Dukes ROM hold leftover source text in old RGBDS syntax, not code. It's the same fragment twice, starting mid-file. It contains:

- the sound-test program: button handling, the tune/SFX name lists, the `Gameboy Music V1` title, and `incbin "mmxfont.bin"`;
- `SECTION "Music",CODE[16384]` followed by `Musicd:` and the channel 1 and 2 code.

That source matches the ROM instruction for instruction. Names recovered from it, used in the generated RAM map:

- per-channel variables: `tempo1`, `tempstor1`, `notelen1`, `seqadr1` (pattern pointer), `patadr1` (step pointer), `transp1`, `note1at`/`note1de` (envelope on/off), `noterset1`, `duty1`, `freqtim1`/`freqtabadr1`/`freqval1`, `arptim1`/`arptabadr1`, `combtim1`, `note1`;
- SFX variables: `seqadre`, `notelene`, `noteechanadr`;
- tables `pattab`, `instab`; the SoundFX/MusicInit call names;
- channel 2 compares `cp a,tempo2&$ff`, which is the generated `cp a, LOW(tempo2)`.

The source steps through RAM with macros (`hlincby1 seqadr1`, `hldecby1d seqadr2,seqadre`). Families C and D assemble those as `inc l`/`dec l`, which needs all variables in one 256-byte page. A and B assemble them as `inc hl`, so the macros are probably a build option.

**GBA lineage.** The data model is the GBA QuickThunder one (`QuickThunder_Technical_Reference.md`), not a separate design:

| | GB (this doc) | GBA Robocop build |
|---|---|---|
| Entry points | `Musicd`, `MusicInit`, `SoundFX` | `musicd()`, `musicinit()`, `SFX()` (`musicd.bin` is also the GBA test-ROM's name) |
| Song | channel step lists + mask + morph + wave | step lists + mask + **unused `+28`** + wave |
| Step | 2 bytes, or 4 bytes `tr, 0, pattern16` | 4 bytes `tr, 0, pattern16` (= Casper U / Ghostbusters) |
| Pattern events | `len note ins`, `len FF/FE/FD`, `00` = next step, `FF ptr` = song jump | identical opcodes; the song jump is `FF`, align, `u32` |
| Instrument tables | freq (3-byte) / arp / combine / volume / noise, walker with `00` + **absolute** word | same tables, `00` + **relative** byte |
| Combine | 0 = freq table only, 1 = note, **2** = note + freq table (≥3 acts as 1) | 0, 1, **≥2** |
| Noise instrument | 2 tables: NR43 **and NR44**, both used | second table loaded and discarded |
| SFX | one slot, ch2 or ch4, priority, ghost stepper | two slots, any channel, priority, ghost stepper |
| Frequency table | 72 entries, note 0 = C2 = `$002C` | the same 72 values (checked against `musicd.s`) |

The GBA's unused song-table pointer, which the reference calls a "cut wave-morphing feature", is the GB **wave-morph table** (§4.6). It works in families C and D.

---

## 2. API and integration

| Build | `Musicd` (per frame) | `MusicInit` (E = song) | `SoundFX` (E = id) | Extra |
|---|---|---|---|---|
| Carmageddon | `$4000` | `$4522` | `$45C4` | `$532A` EngineOn, `$5351` EngineOff, `$5356` EnginePitch (E = 0–63) |
| Casper (U) | `$4000` | `$474A` | `$481A` | |
| Casper (E) | `$4000` | `$473F` | `$481F` | |
| Chicken Run | `$4000` | `$473F` | `$481F` | |
| Ghosts 'n Goblins | `$4000` | `$473F` | `$4819` | |
| Dukes | `$4000` | `$474B` | `$486B` | `$48CD` SirenVol (A → ch1 release), `$48DB` EnginePitch (DE → ch3 `freqval3`) |
| Pinball | `$4006` | `$4000` → `$4751` | `$4003` → `$4877` | |
| Ext. Ghostbusters | `$4006` | `$4000` → `$4760` | `$4003` → `$4880` | |
| Colin McRae | `$400C` | `$4000` → `$45EE` | `$4003` → `$46B4` | `$4006` → `$47B1` Pitch (DE → ch1 `freqval1`), `$4009` → `$4753` PCM timer init, `$47A3` SirenVol (no caller) |

The game glue in the home bank (bank variable / MBC register):

- **Carmageddon:** `$CD45` / `$2100`.
  - `$3179` play song, `$318E` play SFX.
  - `$31AD` frame update. While `$D111` ≠ 0 it also calls EnginePitch with `$C3CC`.
  - `$31D1` engine on/off.
- **Casper (U/E):** C wrappers (GBDK style, arguments read with `ld hl, sp+2`). They switch to **WRAM bank 4** (`$FF70`) and ROM bank `$1F` around every call, because the driver's RAM is in switchable WRAM:
  - U: `$2A58` (song), `$2A88` (SFX)
  - E: `$29A1` (song), `$29DA` (SFX)
- **Extreme Ghostbusters:** `$FFA2` / `$2000`. The SFX wrapper (`$17DA`) does nothing while `$CF03` = 0 (sound off).
- **Colin McRae:**
  - `$C000` / `$2000`.
  - The VBlank handler calls `Musicd` only while bit 7 of `$C459` is set.
  - The timer interrupt (`$0050` → `$0238`) streams the PCM; it's rebuilt in `ColinMcRae\ColinMcRae_PCMIrq.asm`.
  - The game switches to double speed (routine at `$0D:5161`).
- **Test ROMs:** `MusicInit` at boot and on L/R, `SoundFX` on U/D, `Musicd` from the main loop.

There is no stop, pause or volume call. Song 0 is the blank song in every build except Carmageddon, and `MusicInit(0)` is how music is stopped.

---

## 3. Engine

`Musicd` is one flat pass. Channel 1, channel 2, channel 3 (wave), channel 4 (noise), then the SFX "ghost stepper", then the wave-morph stepper (C and D).

Each channel block:

1. Count `tempoN` down. On zero, reload it (`tempstorN` / song tempo) and count `notelenN` down. On zero, fetch the next event.
2. If `noterset` is set, write the envelope register and the restart bit.
3. Walk the instrument tables **once per frame**: frequency (accumulated into `freqval`), arpeggio, combine (and volume on ch3, NR43/NR44 tables on ch4). Write the period.

**Timing.**

- Pattern lengths are in ticks of `tempo` frames, so a note lasts `length × tempo` frames.
- Table lengths are in **frames** (the GBA reference describes them in ticks).
- Tempo is per channel in family D: `MusicInit` copies the song's tempo to each channel in its mask, so a partial song can run at a different tempo from the music under it. It's one song-wide variable in B and C, and a constant 7 in A.

**Event fetch.**

- `[seqadr]` = `$FF`: song jump. The next word is a step-list address.
- `$00`: end of pattern, next step.
- Anything else is the event's length. The byte after it is `$FF` (hold), `$FE` (key off), `$FD` (key on) or a note, followed by an instrument number.

Loading a new pattern stores its **first byte as the length unchecked**, so a pattern can start with `$FF` or `$00` as a length. Colin McRae's `Pat006` is `FF 00 2E`: a note lasting 255 ticks, not a song jump.

**Notes.**

- Note + `transpN` indexes `FreqTable` (C2–B7).
- A note loads the instrument and resets the table timers.
- On ch1/2 it writes NRx1 and arms the attack envelope. On ch3 it starts the volume table. On ch4 the note value is ignored.
- Key off writes the release envelope (ch3: switches to the release volume table) and restarts the channel. Key on re-arms the attack value.

---

## 4. Data formats (macros in `QT_Macros.inc`)

### 4.1 Song table

| Build | Entry | Layout |
|---|---|---|
| A Carmageddon | 6 | `dw ch1, ch2, ch4` |
| B Casper (U) | 11 | `dw ch1, ch2, ch3, ch4` · `db tempo` · `dw wave` |
| C Casper (E), Chicken, Ghosts 'n Goblins | 13 | `dw ch1–ch4` · `db tempo` · `dw morph − 2, wave` |
| D | 14 | `db tempo, mask` · `dw` one pointer per mask bit (ch1, ch2, ch3, ch4) · `dw morph − 2, wave` if bit 2 (C/D wave builds) · padding |

**Masks (family D).** A mask allows partial songs: Dukes' ENGINE (`%0100`) and SIREN (`%0001`) "songs" take over one channel and leave the others playing. Bit 2 means both "channel 3" and "load wave + morph". Colin McRae keeps the morph/wave words in its songs but its `MusicInit` never reads them.

**Wave.** The wave (16 bytes) is copied to wave RAM at `MusicInit`.

**Loops and endings.** A song loops through the `SONGJUMP` at the end of its last pattern. One-shot tunes end with a jump to song 0's step list: one 16-tick hold that jumps to itself, so the channel stays silent.

### 4.2 Step lists

`STEP transpose, pattern`, 2 bytes, or 4 bytes `transpose, 0, pattern16` in Casper (U) and Ghostbusters (288 patterns). There is no terminator: the list ends at the step whose pattern ends in `SONGJUMP`.

### 4.3 Patterns

```
NOTE len, note, ins    HOLD len ($FF)    KEYOFF len ($FE)    KEYON len ($FD)
PATEND ($00)           SONGJUMP steps    ; music
SFXEND [lo] (00 lo 00) SFXLOOP addr      ; sound effects (B, C, D)
```

### 4.4 Instruments

One table (`instab`) serves ch1–3; noise has its own table (`instab4`).

```
INS_TONE  NRx1, env_on, env_off, arp, freq, comb      ; 9 bytes, ch1/ch2
INS_WAVE  vol_on, vol_off, arp, freq, comb            ; 10 bytes, ch3
INS_NOISE NR41, env_on, env_off, NR43_tab, NR44_tab   ; 7 bytes, ch4
```

The driver sets each table timer to 1 and steps once before reading, so the stored pointer is the first entry minus 1 (2-byte tables) or minus 2 (3-byte frequency tables). The macros take the table label and subtract.

As a result, pointers often aim into the previous table's terminator. Several frequency tables start with `TW 20, 0` and then loop over a vibrato: the vibrato starts after 20 frames. Instruments that point past that first entry get the same vibrato at once.

### 4.5 Tables

```
TB len, value      ; arp (signed semitones), combine (0/1/2), ch3 volume (NR32), noise (NR43 / NR44)
TW len, delta      ; frequency: signed 16-bit, added to freqval every frame
TLOOP addr         ; 00 + absolute address: continue there
```

**Combine** picks the period source:

- 0: `freqval` only (absolute sweeps; the engine sounds set `freqval` from the game);
- 1: the note;
- 2: note + `freqval`.

**Noise.** The NR44 table is written every frame, so its bit 7 can retrigger the noise channel per frame.

### 4.6 Wave morph (C, D)

`MORPH frames, register, value`, followed by `TLOOP`. It runs every frame. Each step:

1. turns ch3 off (NR30 = 0),
2. writes one wave-RAM byte (`$FF30–$FF3F`),
3. turns ch3 on and restarts it at the period saved in `wavefreqlo/hi`.

This animates the waveform byte by byte. Ghostbusters has an unreferenced 96-step morph table at `$7A21–$7B43`.

### 4.7 Sound effects

| Build | SFX table entry | Channels | Tick | End |
|---|---|---|---|---|
| A | `dw pattern` · `db chan` | 2 → ch2, else ch4 | 7 frames | `00` |
| B, Ghosts 'n Goblins | `dw pattern` · `db chan` | same | 5 frames | `00 lo hi` |
| C | `db prio` · `dw pattern` · `db chan` | same | 5 (Casper E) / 1 (Chicken) | `00 lo hi` |
| D | same as C | same | 1 frame | `00 lo hi` |

**One slot.** There is a single SFX slot. `noteechanadr` points at the music struct of the stolen channel (`tempo2` or `tempo4`), `$FF` = none.

**Starting an effect.**

- An effect starts if nothing is playing or its priority is ≥ the current one (C/D). A and B have no priorities: the newest effect wins.
- A replaced effect's channel is muted first.
- Effect notes are not transposed.

**While an effect plays.** The ghost stepper keeps stepping the displaced music, counting tempo and lengths and following steps and jumps, without touching the hardware or loading instruments.

**Ending.** `00 lo 00` sets the channel's envelopes to `$01` (silent) and frees the slot. The music only becomes audible again at its **next note**. Mega Man Xtreme restores the music note immediately; this driver does not.

### 4.8 Colin McRae PCM

Channel 3 is a sample channel.

- **Music.** A note on ch3 calls the PCM starter with the **instrument byte as sample number**. `$FE`/`$FD` aren't recognised there.
- **SFX.** Ids below `$1F` are samples; ids `$1F+` are the 4 sequenced SFX.

`PcmTable` (`$56F4`, 31 entries):

```
db prio      ; 1 = always starts, 0 = only if no prio-1 sample is playing
dw address
dw blocks    ; 16-byte blocks
db bank
```

The timer interrupt plays the samples:

- 4096 Hz / 32, doubled to **256 Hz** in double speed.
- Each interrupt copies 16 bytes (32 4-bit samples) to wave RAM and restarts ch3 at period `$700`, which gives **8192 Hz**.
- It turns ch3 off in NR51 when the count runs out.

Samples `$00–$03` (prio 0) are in bank `$7D`, `$04–$0D` in `$7E`, `$0E–$1E` in `$7F`. The lengths are rounded up to whole blocks, so 27 of the samples play a few bytes of the next one. `$0E`/`$0F` are 2-byte placeholders. Songs `$0F–$1C` and `$1E–$2D` are one- and two-sample PCM sequences on ch3.

`ColinMcRae\pcm\PcmXX.bin` holds the raw bytes (INCBIN'd by `ColinMcRae_PCM.inc`), and `wav\PcmXX.wav` the decoded 8192 Hz versions.

---

## 5. Version differences (code)

| | A Carm | B Casper U | B/C Ghosts 'n Goblins | C Casper E / Chicken | D Dukes | D Pinball | D Ghostbusters | D Colin McRae |
|---|---|---|---|---|---|---|---|---|
| Channels | 1, 2, 4 | 1–4 | 1–4 | 1–4 | 1–4 | 1–4 | 1–4 | 1, 2, 4 + PCM on 3 |
| Tempo | constant 7 | per song | per song | per song | per channel | per channel | per channel | per channel |
| Steps | 2 | **4** | 2 | 2 | 2 | 2 | **4** | 2 |
| Wave / morph | – / – | ✓ / – | ✓ / ✓ | ✓ / ✓ | ✓ / ✓ | ✓ / ✓ | ✓ / ✓ | – / – |
| SFX priority | – | – | – | ✓ | ✓ | ✓ | ✓ | ✓ (+ PCM prio) |
| Entry | direct | direct | direct | direct | direct | jp table | jp table | jp table (4) |
| Id check | – | – | – | ignores id = count (Casper: song 4 / SFX `$19`; Chicken: 9 / `$1D`) | – | song ≤ `$0A`, SFX ≤ `$58` | – | SFX < `$1F` = PCM |
| RAM stepping | `inc hl` | `inc hl` | `inc l` | `inc l` | `inc l` | `inc l` | `inc l` | `inc l` |

**Carmageddon** (oldest code shape):

- NR11/NR12 are written directly at the note.
- SFX use the music tempo, have no loop, and are ordinary entries in the pattern table (`Pat046–061`).
- `MusicInit` points ch1's tables at `$4851`/`$4852`: the bytes in front of song 0's step list, where there is no table. This is harmless because the first ch1 event is a note.
- A separate engine module plays a sawtooth drone on ch3 with a 64-step pitch table (`$537A`).

**Ghosts 'n Goblins** keeps Casper (E)'s code shape and RAM layout up to `$61`, but its `SoundFX` has no priority test and its SFX table no priority byte, like Casper (U). Its RAM tail is `songtempo` `$62`, `morphtim` `$63`, `morphadr` `$64`, `wavefreqlo/hi` `$66/$67`.

**Casper (U)** has dead code at `$4530` (`jp $4536` after an unconditional `jr`).

**Dukes vs Pinball** differ only by the jump table, the two id checks and Dukes' two game calls. **Ghostbusters** is Pinball's code with 4-byte steps and no id checks.

---

## 6. Casper (U) vs Casper (E)

The code differs as above: B vs C, so the E build gained morph tables and priorities. The data is mostly the same content re-exported. Songs 1–3 match step for step except:

- **Song 3, ch3:** every transpose is +12 in (E) (an octave up), and the wave changed from `000000FFFFFFFFFF000000FFFFFFFFFF` to `FFFFFFFF000000000000000000000000`.
- **Song 2:** the wave changed from a noisy wave (`AFFE9656…`) to a single spike (`F000…`).
- **Song 1, ch4:** the first step plays a drum note (64 ticks, noise instrument `$15`) where (U) rests.
- **Song 0 (blank):** (U) holds 64 ticks. (E) plays one note per channel on new silent instruments (`$36`, `$37`, noise `$15`).
- **Instruments:** 12 tone instruments have NRx1 `$D0` in (U) and `$C0` in (E). That's the same 75 % duty with a different length value, which isn't used because the length counter is never enabled. Instrument `$35` is a different instrument. (E) also adds 2 tone and 3 noise instruments.
- **SFX:** all 25 are identical in content and channel; (E) adds priority 50 to all of them.

---

## 7. Quirks and bugs

1. **Pinball SFX `$0E` ("light on") jumps to `$F300`.** Its pattern ends with a single `00`, and the next two bytes belong to the instrument after it (`00 F3`), so the driver treats the end as a loop to `$F300` (echo RAM). Confirmed in the harness: from frame 260 the SFX pointer sits at `$F303`.
2. **First frame of ch3** (C/D): `MusicInit` sets the volume timer to 2 with `BlankVol − 1`, so the first frame writes the byte in front of `BlankVol` to NR32: the driver's final `ret` (`$C9`), or in Casper (E) the last byte of an unreferenced morph table (`$48`). Both give 50 % volume for one frame.
3. **Id checks (C)** only reject id = count, which is the invalid 5th song entry in Casper. Larger ids read past the tables.
4. **Ghost stepper:** a leftover `add a, b` with no effect, and it loads the instrument pointer and discards it.
5. **SFX end reads 3 bytes** (B/C/D) even when the effect was written with a 1-byte end (point 1).
6. **Overlapping data, reproduced as-is:**
   - Dukes' two ch3 waves share 1 byte (`$5C6E`).
   - Colin McRae's PCM blocks run into the next sample.
   - A Carmageddon SFX instrument's combine pointer is the first bytes of its own arp table (`$1B01`, inside ROM0).
7. **Leftovers from the converter, kept as `db` with comments:**
   - Carmageddon: `00 nn 00` in front of each SFX pattern, where `nn` = the pattern's own number. The fourth song-table entry is 3 zero bytes plus the marker in front of `Pat046`.
   - Ghostbusters: 2 junk bytes after most step lists, plus unreachable steps.
   - Many unreferenced tables and instruments. They are emitted with "Orphan…" labels; the types are guesses from the byte pattern, and some may really be waves or other data.
   - Colin McRae: 12 null instrument pointers and a wave instrument (`$5278`) in a build without a wave channel.
   - `-- THE END --` at the end of the data in Casper (U/E), Ghostbusters and Pinball.

---

## 8. Songs

**Dukes of Hazzard** (names from the test ROM; tempo in frames per tick):

| Id | Name | Tempo | Channels | Id | Name | Tempo | Channels |
|---|---|---|---|---|---|---|---|
| `$00` | Music off | 1 | 1–4 | `$0E` | Collision2 | 1 | 2, 4 |
| `$01` | TITLE | 11 | 1–4, loops | `$0F` | Collision3 | 1 | 2, 4 |
| `$02` | ENGINE | 30 | 3 | `$10` | Collision4 | 1 | 2, 4 |
| `$03` | STOP ENGINE | 30 | 3 | `$11` | Arrows | 1 | 4 |
| `$04` | SIREN | 1 | 1, loops | `$12` | Horn | 1 | 2 |
| `$05` | STOP SIREN | 5 | 1 | `$13` | Horn 2 | 1 | 1, 2 |
| `$06` | TUNE 2 | 7 | 1–4, loops | `$14` | Get Turbo | 1 | 2 |
| `$07` | SKID ON | 1 | 4 | `$15` | pickup 1 | 1 | 2 |
| `$08` | SKID OFF | 1 | 4 | `$16` | pickup 2 | 1 | 2 |
| `$09` | CARHITCAR | 1 | 2, 4 | `$17` | Siren down | 4 | 1 |
| `$0A` | TNT EXPLSN | 1 | 2, 4 | `$18` | skid v2 | 4 | 2, 4 |
| `$0B` | Bridge on | 1 | 4, loops | `$19` | skid v2 off | 4 | 2, 4 |
| `$0C` | Bridge off | 1 | 4 | `$1A` | TRUCK ENGINE | 30 | 3 |
| `$0D` | Collision1 | 1 | 4 | `$1B` | STOP ENGINE | 30 | 3 |

Only TITLE and TUNE 2 are music. The rest are effects written as partial songs on one or two channels; ENGINE and TRUCK ENGINE start one held ch3 note with combine mode 2, so the pitch the game passes to EnginePitch (`freqval3`) is added to it. The 3 entries in the SFX table are menu sounds (Blank, Menu beep, select).

**Chicken Run:** `$00` Music off, `$01` Title, `$02` Briefing, `$03` Daytime 1, `$04` Daytime 2, `$05` Pie 1, `$06` Pie 2, `$07` Success, `$08` Gameover. The test ROM names the first 26 of the 29 SFX (`Blank`, `Pickup`, `Put down`, … `error`).

**Ghosts 'n Goblins:** `$00` Music off, `$01` Levels 1&2, `$02` Levels 3&4, `$03` Levels 5&6, `$04` Level 7, `$05` Intro pt 1, `$06` Intro pt 2, `$07` Strt level, `$08` Lose life, `$09` Game over, `$0A` Win level. The menu lists 35 SFX names (`Thrw weapn`, `Obj Appear`, … `heartsingl`), but the menu stops at `$0B` and the data has 12 SFX. The first 12 names are used in the sources; whether they belong to these 12 effects isn't confirmed.

**3-D Ultra Pinball:** names from the driver's `Readme.txt`. It also confirms the API (`$4000` Init, `$4003` SFX, `$4006` Frame) and the RAM (`$C594–$C5FF`). Songs: `$00` Music off, `$01` Bumper cars, `$02` Multi ball, `$03` Flying falcon, `$04` River rapids, `$05` Lights out, `$06` Nite Time, `$07` Thrill Ride, `$08` Shell, `$09` Daylite, `$0A` Thrillzone. The 89 SFX names match the 89 entries in `musicd.bin` (`$00` Blank … `$58` bump pop 2); the Readme came with an earlier copy of the sound data, so a few may have changed. The buggy SFX `$0E` (§7) is "light on".

All these names are in the generated `SongTable`/`SfxTable` comments.

The other games' song roles weren't identified. Per-song tempo, channels, step counts and loop points are in the generated `SongTable` and can be listed with `tools\qtsongs.py <key>`.

---

## 9. Verification

- **Byte-exact rebuild** of all nine sound regions, Colin McRae's PCM banks (`$7D:57AE–7ABB`, `$7E`, `$7F`) and its timer interrupt (`build_check.sh`).
- **Emulator harness** (`harness\`): a small ROM linking the **rebuilt** bank. Python (PyBoy) starts each song for 3600 frames and each SFX for 600 frames. Every frame it checks that each channel's pattern pointer is on an event and its step pointer is on a step, as found by the parser.

  | Build | Songs × frames | SFX | Off the parse | Events reached |
  |---|---|---|---|---|
  | Carmageddon | 3 × 3600 | 16 | 0 | 500 / 621 |
  | Casper (U) | 4 × 3600 | 25 | 0 | 631 / 1427 |
  | Casper (E) | 4 × 3600 | 25 | 0 | 633 / 1437 |
  | Chicken Run | 9 × 3600 | 29 | 0 | 1910 / 2299 |
  | Ghosts 'n Goblins | 11 × 3600 | 12 | 0 | 932 / 1048 |
  | Dukes | 28 × 3600 | 3 | 0 | 580 / 673 |
  | Ext. Ghostbusters | 10 × 3600 | 18 | 0 | 1830 / 2684 |
  | Colin McRae | 46 × 3600 | 4 | 0 | 243 / 325 |
  | Pinball | 11 × 3600 | 89 | SFX `$0E` only (bug 1) | 2087 / 2446 |

  The unreached events are in patterns no song uses, or past 3600 frames.
- **Not verified:** PCM playback itself (the harness has no timer interrupt handler, so samples are started but not streamed), the roles of most songs, and anything on hardware.

## Files (`GBAudioLab\AA\QuickThunder`)

| File | Content |
|---|---|
| `QT_Macros.inc` | hardware names, note names (`C2`…`B8`), all data macros |
| `<Game>\QT_<Game>.asm` | RAM map, `SECTION`, includes |
| `<Game>\<Game>_Driver.inc` | driver code, with descriptive labels (`Ch2_NextEvent`, `Ghost_Step`, `Morph_Step`, …) and a comment above each main routine |
| `<Game>\<Game>_Data.inc` | songs, steps, patterns, instruments, tables, waves (Carmageddon: + the engine module) |
| `ColinMcRae\ColinMcRae_PCM.inc`, `pcm\`, `wav\` | PCM sections, raw samples, WAVs |
| `ColinMcRae\ColinMcRae_PCMIrq.asm` | ROM0 timer interrupt |
| `tools\` | `qtcfg.py` (per-game table), `qtparse.py`, `qtgen.py`, `qtlabels.py` (label names: set by hand for Dukes, carried to the other builds by aligning their code), `sm83.py`, `trace.py`, `cmrpcm.py`, `cmrirq.py`, `qtcompare.py`, `qtsongs.py`, `qtstats.py`, `cmp.py` |
| `harness\` | `harness.asm`, `build.sh`, `verify.py` |
