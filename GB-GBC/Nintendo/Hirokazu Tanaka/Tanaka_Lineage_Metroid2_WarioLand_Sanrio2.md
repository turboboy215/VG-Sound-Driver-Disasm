# Tanaka GB sound driver: lineage of Metroid II / Wario Land and Sanrio Carnival 2

This note answers two questions about the Hirokazu Tanaka driver family (*Super Mario Land*, *Tetris*, *Dr. Mario*, *Super Mario Land 2*, *Link's Awakening DX*, *Super Mario Bros. Deluxe*, *Tetris Attack*, unlicensed *Metal Slug 2*):

1. Is the Metroid II / Wario Land driver (Ryohji Yoshitami) derived from Tanaka's, and do they share code?
2. Is the Sanrio Carnival 2 driver related to Tanaka's at all?

**Short answers**

1. **Yes, derived, with some shared code.** The Metroid II driver uses Tanaka's song data model with the command bytes renumbered. It carries Tanaka's note table value for value, including the early version's C♯7 value. It keeps Tanaka's length-table layout. A set of low-level routines are near-verbatim copies of the *Dr. Mario*-era driver: init, stop/mute, the register-image writer, the pointer-table lookup, the wave loader, the pause jingle, the request/playing SFX dispatch and the entry-stub order. The sequencer core (pattern reader, per-channel state handling) was rewritten. Wario Land runs the same driver as Metroid II, with game-specific SFX and additions.
2. **No relationship in code.** Sanrio Carnival 2 has a different architecture, data format, command set, note table and coding style. Its similarity to the Tanaka drivers is at the level of an unrelated driver. If Tanaka did write music for it, the music was entered into someone else's driver. The full disassembly (`SanrioCarnival2_SoundDriver.md`) confirms this.

Also: *Metal Slug 2* is derived from *Link's Awakening DX* specifically; its SFX bank is LA DX's, copied as binary (§5). *Tetris* sits between *SML1* and *Dr. Mario*. *Tetris Attack*'s music driver is the *SML2* version refitted with *Dr. Mario*'s tables (§6).

Sources: the ROMs in `GBAudioLab\Nint1`, plus the bank-04 disassemblies `Metroid2_bank_004.asm` (mgbdis, labelled) and `WarioLand_bank04.asm`. Addresses are CPU addresses in the sound bank: *Dr. Mario* bank 1, *SML* bank 3, *SML2* bank 4, *LA DX* banks `$1B/$1E/$1F`, *Sanrio Carnival 2* bank 1.

---

## 1. Where the drivers are

| Game | Bank | Entry points | Note table | Notes |
|---|---|---|---|---|
| Super Mario Land | 3 | `$7FF0 jp $6762` (update, runs as an interrupt: `reti`), `$7FF3 jp $6B26` (stop) | `$6F70` | commands `$9D` only |
| Tetris | 1 (32 KB ROM) | `$7FF0` update (from the main loop), `$7FF3` stop | `$6E02` | commands `$9D` only |
| Dr. Mario | 1 | `$7FF0 jp $65C0` update (from the timer interrupt), `$7FF3 jp $6507` stop, `$7FF6 jp $66A4` init | `$6B12` | `$9B–$9F` |
| Super Mario Land 2 | 4 | `$4000` init (no stub table), `$4030` update | `$5AF4` | |
| Link's Awakening DX | `$1B`, `$1E` music, `$1F` SFX | `$4000 jp init`, `$4003 jp stop`, `$4006 jp update` | `$49C2` (`$1B`), `$49BF` (`$1E`) | |
| SMB Deluxe | `$1D`, `$1F` | same 3-stub layout as LA | `$4C2F` (`$1D`), `$4100` (`$1F`) | |
| Tetris Attack | `$08`, `$07` music; SFX in `$07` | home routine `$1500` | `$47C4` (`$08`) | own SFX engine |
| Metal Slug 2 (unl.) | `$28` music, `$29` SFX | tag byte, then `$4001` update, `$4004` init, `$4007` stop | `$4789` | SFX bank = LA DX `$1F` (§5) |
| Metroid II | 4 | `$4000 jp handleAudio`, `$4003 jp silenceAudio`, `$4006 jp initializeAudio` | `musicNotes` | |
| Sanrio Carnival 2 | 1 | `$6000 jp $60BE` init, `$6003` update | `$69EF` | |

---

## 2. Metroid II / Wario Land vs. Tanaka

### 2.1 Same data model, renumbered commands

Both drivers use the same three-level song structure and the same pattern semantics.

```
song header:  db transpose                ; M2: bit 0 = square-2 detune flag
              dw lengthTable              ; tempo = which length table
              dw ch1List, ch2List, ch3List, ch4List   ; 0 = channel unused
section list: dw pattern, pattern, ...  then  $0000 = end, or a loop marker + target
pattern:      notes, lengths, commands, $00 = end of pattern
```

| Meaning | Tanaka (*Dr. Mario* / *SML2* / *LA*) | Metroid II / Wario Land |
|---|---|---|
| end of pattern | `$00` | `$00` |
| rest | `$01` | `$01` |
| note | even byte = offset into the note table (entry 0 special) | same; transpose added the same way |
| length | `$A0+n`: entry *n* of the current length table | `$A0+n` (`$9F–$F0` accepted, `res 7 / res 5`) |
| instrument (3 bytes: ch1/2 envelope, duty/len, flags; ch3 wave pointer + volume) | `$9D` | `$F1` |
| select length table (tempo) | `$9E` + pointer | `$F2` + pointer |
| transpose | `$9F` + n | `$F3` + n |
| repeat start (count) | `$9B` + n | `$F4` + n |
| repeat end | `$9C` | `$F5` |
| section-list loop | `$FFFF` + target | `$00F0` + target |
| stop all | | `$F6+` |
| echo notes | | `$03`, `$05` (re-trigger at a lower envelope) |

The third instrument byte selects a per-frame pitch effect in both drivers. In *Dr. Mario*, routine `$6A32` reads its low nibble: types 1 and 2 index the tables at `$6ABD` and `$6A9F`, type 3 applies a fixed offset of −2. In Metroid II, `songEffectIndex` takes the low 6 bits: 2, 3, 4, 9 and A are 16-step tables, and 6, 7 and 8 are per-frame slides (+1, +4, −3). Metroid II also adds song interruptions (item-get jingle with state save/restore), a scripted fade-out and the square-2 detune flag.

*SML1*'s and *Tetris*'s drivers only have `$9D` (no tempo, transpose or repeat commands). Metroid II's command set therefore corresponds to the *Dr. Mario* level of the engine or later.

### 2.2 Same note table

All 72 note values in Metroid II's `musicNotes` (index 1–72, C2–B7) are **identical** to *SML1*'s, *Tetris*'s and *Dr. Mario*'s once bit 15 is masked off. Metroid II stores each value with bit 15 set, the NRx4 trigger bit.

Compared with exact rounding (A4 = 440 Hz), every version of the Tanaka table has the same five low-note deviations: C♯2, D2, G2 and C4 are one below, A2 two below (`$356` for `$358`). Two more entries tell the versions apart:

| Entry | Exact | SML1, Tetris, Dr. Mario, Tetris Attack | SML2 | LA DX, SMB DX, Metal Slug 2 | Metroid II |
|---|---|---|---|---|---|
| A♯5 | 1907.41 → `$773` | `$773` | `$773` | **`$774`** | `$773` |
| C♯7 | 1988.89 → `$7C5` | **`$7C4`** | `$7C5` | `$7C5` | **`$7C4`** |

*SML2* corrected C♯7; LA DX changed A♯5. Metroid II has all five shared deviations plus the early C♯7 value, so its table was copied from the *SML1* / *Tetris* / *Dr. Mario* table rather than computed independently.

Sanrio Carnival 2's table deviates from exact rounding in six entries of its own: C2, E2, A2, E3 and F♯3 one high, C4 three low. Only A2 and C4 deviate in the Tanaka table too, and A2 in the opposite direction (§3.3).

### 2.3 Same length tables

A Tanaka length table lists 1/32, 1/16, 1/8, 1/4, 1/2 and 1/1 notes (entries 0–5), then three dotted values (6–8) and two triplets (9–10). Metroid II's tables have this exact layout.

- **Entries 0–8** match *Dr. Mario*'s value for value in every tempo the two drivers share. This includes rounded values such as 3 frames for the 1/32 note at 56 frames per whole note.
- **The two triplet entries** also match where *Dr. Mario*'s table isn't cut short by the next one. *Dr. Mario* packs its tables so that they overlap.
- *SML2* and *LA* reorganised the triplet slots (`02 05 …`). Metroid II follows the *Dr. Mario* order.
- Metroid II appends two entries (1/128 and a whole note) to each table.

| Tempo | Dr. Mario | Metroid II | SML2 / LA |
|---|---|---|---|
| `$6C4C` / `tempoTable_75` | `03 06 0C 18 30 60 12 24 48` `08 10` | `03 06 0C 18 30 60 12 24 48` `08 10` `02 C0` | `… 48` `03 08` |
| `$6C5A` / `tempoTable_64` | `03 07 0E 1C 38 70 15 2A 54` `09 12` | `03 07 0E 1C 38 70 15 2A 54` `09 12` `02 E0` | `… 54` `04 09` |
| `$6C2D` / `tempoTable_149` | `03 06 0C 18 30 09 12 24` `04 08` (from entry 1) | `02 03 06 0C 18 30 09 12 24` `04 08` `01 60` | `… 24` `02 04` |
| `$6C67` / `tempoTable_56` | `04 08 10 20 40 80 18 30 60` `0A 15` | `04 08 10 20 40 80 18 30 60` `0A 14` `02 FF` | `… 60` `04 02` |

### 2.4 Shared routines

Most of the shared code is in the outer layer: init, stop, mute, pause and SFX plumbing. Each pair below is from *Dr. Mario* (bank 1) and Metroid II.

**Mute all channels: identical, 12 instructions.** *SML1*'s version (`$6B4B`) writes `$01` and no trigger. *Tetris*'s is already the 12-instruction version below, and Metroid II matches it.

```
Dr. Mario $653F              Metroid II muteSoundChannels
ld a,$08                     ld a,$08
ldh [NR12],a                 ldh [rAUD1ENV],a     ; NR12
ldh [NR22],a                 ldh [rAUD2ENV],a     ; NR22
ldh [NR42],a                 ldh [rNR42],a
ld a,$80                     ld a,$80
ldh [NR14],a                 ldh [rAUD1HIGH],a    ; NR14
ldh [NR24],a                 ldh [rAUD2HIGH],a    ; NR24
ldh [NR44],a                 ldh [rNR44],a
xor a                        xor a
ldh [NR10],a                 ldh [rNR10],a
ldh [NR30],a                 ldh [rAUD3ENA],a     ; NR30
ret                          ret
```

**Init.** Same register order. The clear loop differs only because Metroid II's RAM isn't page-aligned.

```
Dr. Mario $66A4              Metroid II initializeAudio
ld a,$80 / ldh [NR52],a      ld a,$80 / ldh [rNR52],a
ld a,$77 / ldh [NR50],a      ld a,$77 / ldh [rNR50],a
ld a,$FF / ldh [NR51],a      ld a,$ff / ldh [rNR51],a
ld hl,$DF00                  ld hl,sfxRequest_square1
.l: ld [hl],0 / inc l        .loop: ld [hl],0 / inc hl
jr nz,.l                     ld a,h / cp $d0 / jr nz,.loop
ret                          ret
```

**Stop** (*Dr. Mario* `$6507` / Metroid II `silenceAudio`; *Tetris* `Sound_Stop` is the same): set NR51 = `$FF`, clear the request and playing bytes of every channel and the music, then fall through into the mute routine above.

**Update prologue: identical control flow.**

```
Dr. Mario $65C0                      Metroid II handleAudio
ld a,[$DF7F]  ; pause control        ld a,[audioPauseControl]
cp 1 / jr z,pause                    cp pause   / jp z,audioPause
cp 2 / jp z,unpause                  cp unpause / jp z,audioUnpause
ld a,[$DF7E]  ; pause timer          ld a,[audioPauseSoundEffectTimer]
and a / jp nz,paused                 and a / jp nz,handleAudio_paused
...                                  ...
(end) xor a, clear every request     (end) xor a, clear every request
byte and the pause control           byte and audioPauseControl
```

**Pause jingle.** Pausing sets a timer: `$30` in *SML1*, *Tetris* and *Dr. Mario*, `$40` in Metroid II. While paused, the routine decrements it each frame and writes fixed register images on chosen frames. When the timer reaches `$10` it re-increments it, holding it there until unpause. The hold trick is identical:

```
Dr. Mario $6684                       Metroid II handleAudio_paused
ld hl,$DF7E / dec [hl] / ld a,[hl]    ld hl,audioPauseSoundEffectTimer / dec [hl] / ld a,[hl]
cp $28 / jr z,...                     cp $3f / jr z,...   (7 frames, ch1 + noise images)
cp $20 / jr z,...                     ...
cp $18 / jr z,...                     cp $24 / jr z,...
cp $10 / jr nz,done                   cp $10 / jp nz,done
inc [hl]                              inc [hl]
```

**Register-image writer.** Both drivers have four entries, in the same order and with the same byte counts: ch1 NR10 ×5, ch2 NR21 ×4, ch3 NR30 ×5, ch4 NR41 ×4. *Dr. Mario* (`$64B8/$64BF/$64C6/$64CD`) loops `ld a,[hl+] / ldh [c],a`. Metroid II's `setChannelOptionSet` copies from `de` to `hl`, the same idea written differently.

**Pointer-table lookup** (*Dr. Mario* `$64DF` / Metroid II `loadPointerFromTable`): `dec a`, double it, `ld b,0 / ld c,a / add hl,bc`, then `ld c,[hl] / inc hl / ld b,[hl] / ld l,c / ld h,b`. The code is identical except that the shift instruction differs (`sla a` vs `add a`) and *Dr. Mario* adds a trailing `ld a,h`.

**Wave loader** (*Dr. Mario* `$64FA` / Metroid II `writeToWavePatternRam`): `push bc`, `ld c,$30`, copy with `ldh [c],a / inc c`, loop until `c = $40`.

**SFX architecture.** Both drivers keep one request byte and one playing byte per channel. Each SFX ID indexes a pair of jump tables (init and playback) through the pointer lookup, ending in `jp hl`. Effects are written as code, not bytecode. An effect's init sets a frame timer and writes a register image. Its playback decrements the timer, compares it with specific frame numbers and writes the next image.

```
SML1 SFX:     ld a,len / ld hl,image / jp $6AB9 (store timer, write image)
Metroid II:   ld a,len / ld de,image / jp playSquare1Sfx (store timer, setChannelOptionSet)
playback:     call decrementTimer / cp N / jr z,.setN / ... / .setN: ld de,image / jp setChannelOptionSet
```

**The final `ret` of init reused as a no-op table entry.** *Dr. Mario*'s `Sfx4_PlayTable` points its third entry at `$66B8`, the `ret` that ends `Sound_Init`. Metroid II's SFX pointer tables fill their unused slots with `initializeAudio.ret`, the same trick on the same routine.

**Entry-stub order.** *Dr. Mario* puts update, stop, init at `$7FF0/$7FF3/$7FF6` (*SML1* and *Tetris*: update, stop). Metroid II uses the same order at `$4000/$4003/$4006`. LA uses the reverse order (init, stop, update). The Wario Land disassembly's own comment notes that these stubs exist to make the driver reusable across games.

**Data fragment.** One of Metroid II's unused wave patterns starts with `FE DC BA 98 8A A8 32 10`. This exact 8-byte run is the second half of a *Dr. Mario* wave at `$6BC3`. The run is short and only suggestive on its own. *Tetris Attack* carries Dr. Mario's whole wave set, including that wave (§6), which shows the waves did travel with the driver.

### 2.5 What was rewritten

The sequencer core does not match at the instruction level.

- **Tanaka**: one loop runs over 16-byte channel structures (`$DF90 + $10·n` in *Tetris* and *Dr. Mario*) with a channel counter (`$DF70`). The command dispatch is a chain of `cp $9D/$9E/$9F/$9B/$9C` tests followed by the `$Ax` and note handling.
- **Metroid II**: there are four separate per-channel handlers (`handleSong_loadNextChannelSound_square1/2/wave/noise`). Each copies a 9-byte channel state into a working area (`copyChannelSongProcessingState`), runs a shared `loadNextSound`, and copies the state back. Commands are tested with `cp $F1 … $F5 / call z`. Noise notes index 4-byte register sets.

RAM is in a different place (`$CExx–$CFxx` vs the `$DF00` page) and the variable layout differs.

**Interpretation.** Yoshitami's driver is not a patched Tanaka binary. It was most likely written on top of Tanaka's source or documentation from around the *Dr. Mario* period (1990), keeping the song format and the utility routines and rewriting the music core. This fits the timing (Metroid II, 1991) and both being R&D1 projects, but the code alone can't show who handed what to whom.

### 2.6 Wario Land = Metroid II driver

The Wario Land bank-04 disassembly is the same driver. It has the same stubs, the same `$F1–$F5` command set and `$00F0` loop marker, and the same per-channel handlers, song interruption and pause code. Aligning Wario Land's routines against Metroid II's, every core music routine matches 100 % (`Sound_DoCurrentBGM_Ch1–4`, `Sound_SetBGMCh1–4`, `Sound_ParseBGMCommand` 52/55, `Sound_DoBGMCmd_SetLength` 17/17, …), 73 % of all instructions overall. The remainder is game-specific SFX code.

### 2.7 Overall similarity (for scale)

To put a number on it, each Metroid II core routine (`handleAudio` through `resetSongSoundChannelOptions`, 1,369 instructions) was aligned locally against each driver's traced code. Instructions were normalised so that registers, small constants and I/O registers count, while RAM addresses and labels don't. The table gives the fraction of instructions that land in an aligned match.

| Compared with | Aligned |
|---|---|
| Wario Land (same driver) | 73 % overall, ~100 % on music routines |
| Dr. Mario | 20.4 % |
| Link's Awakening DX (`$1B`) | 19.4 % |
| Super Mario Land 2 | 19.0 % |
| Metal Slug 2 | 18.3 % |
| Super Mario Land | 15.5 % |
| *Sanrio Carnival 2 (unrelated control)* | *11.1 %* |

The Tanaka excess over the control (about 8 points) is concentrated in the routines in §2.4. It is not spread through the music code. That pattern is what you'd expect from a rewritten core around reused utility routines.

---

## 3. Sanrio Carnival 2: not related

### 3.1 Architecture

| | Tanaka | Sanrio Carnival 2 |
|---|---|---|
| Register output | written directly while processing | shadow registers `$DE64–$DE7F` with per-channel dirty flags, flushed at the end of each update (`$600D–$60BD`) |
| SFX | code per effect, register images | **bytecode**: requests are bit masks per slot (`$DE01–$DE04`); in an effect stream `$00–$3F` = register writes (low bits say which registers follow), `$40–$5F` = hold/resume the music (`$DE09`), `$60–$6F` = end, `$70–$7F` = channel set, `$80+` = wait *n* frames |
| Song layout | header → section lists → patterns | song table `$6DB2`: 4 stream pointers per song, one byte stream per channel with jumps, calls and returns |
| Notes | even offsets, separate `$Ax` length commands | `$00–$7F` = note index (×2 into the table), followed by a packed byte: high nibble = length index, low nibble = number of following notes that reuse it |
| Commands | `$9B–$9F` | `$80–$9F` through a jump table at `$688A`: `$80` wave pointer, `$81` NR50, `$82` NR51 masks, `$83–$8E` per-channel parameters, `$8F` length table, `$93` jump, `$94–$97` call, `$98–$9B` return, `$9C–$9F` end of channel (`$90–$92` unused) |
| Instruments | envelope / duty via the 3-byte command | envelope and pitch macro tables in the `$6Dxx` page (`$00` = loop) |
| Length table | 1/32 … 1/1, 3 dotted, 2 triplets | 16 entries, different order (`05 0A 14 28 50 00 78 3C 64 32 1E …`) |
| Style | `and a` zero tests, `$DFxx` page structures | `or a` zero tests, `add a,a` carry tests, `ld bc,n / dec bc / ld a,c / or b` loops |

### 3.2 Search for shared bytes

All runs of 8 or more identical bytes between Sanrio's sound region (`$6000–$7FFF`) and the sound banks of *SML1*, *Dr. Mario*, *SML2* and *LA* were listed. They fall into three groups:

- parts of the note table (equal-temperament values converge in the upper octaves, so any two tables share these);
- the plain triangle wave `01 23 … EF FE … 10`;
- the 8 bytes `ld a,$08 / ldh [NR12],a / ldh [NR22],a / ldh [NR42],a`, a common idiom.

None of these show copying. There is no shared code beyond that.

### 3.3 Note table

Sanrio's table (85 entries, C2–C9) differs from the Tanaka table in ten of its first 72 entries: C2 `$2D` vs `$2C`, C♯2, D2, E2, G2, A2 `$359` vs `$356`, E3, F♯3, C4 `$608` vs `$60A`, and C♯7. Against exact rounding it has six deviations of its own (§2.2). This is an independently produced table.

### 3.4 Code similarity

Sanrio's code was split into routines (at `ret` / `jp`) and aligned the same way as in §2.7. It matches 6.8–8.2 % against every driver tested (Metroid II 7.7 %, *Dr. Mario* 8.0 %, *SML1* 6.8 %, *SML2* 8.2 %, *LA* 8.0 %). The longest aligned match is 8 instructions. That is the noise floor, with no preference for the Tanaka drivers.

**Conclusion.** The Sanrio Carnival 2 driver shares no code, data format or tables with the Tanaka family. If Tanaka contributed music to the game, it was written for, or converted into, an unrelated driver. Credits would have to settle that question; the code can't.

---

## 4. Limits

- Metroid II and Wario Land were compared through the supplied disassemblies, not their ROMs. Symbolic constants in those files (e.g. `cp songInterruption_itemGet`) were treated as wildcards in the alignment.
- *Tetris* is now in the set (§6). Its mute, stop and pause code, note table and length-table packing are already what Metroid II shares, but it has only the `$9D` command. Metroid II's command set (tempo, transpose, repeat) still places its base no earlier than *Dr. Mario*.
- The routine traces used for the percentages in §2.7 may include some non-sound code where a bank mixes sound and game code (*SML1* bank 3).

---

## 5. Addendum: LA DX → SMB Deluxe and Metal Slug 2

These findings come from the full disassemblies (`LinksAwakeningDX_SoundDriver.md`, `SMBDeluxe_SoundDriver.md`, `MetalSlug2_SoundDriver.md`).

| Pair | Aligned instructions | Relationship |
|---|---|---|
| LA `$1E` ← LA `$1B` music | 1,096 / 1,157 | two copies of one driver; `$1B` has vibrato 2, `$1E` does not |
| SMB DX `$1D` ← LA `$1B` music | 1,006 / 1,409 | same driver, extended: envelope tables, hurry mode, new commands; LA's dropped commands left in as dead code |
| SMB DX `$1F` ← LA `$1F` SFX | helpers only | same machinery, new effects and slot layout |
| **MS2 `$29` ← LA DX `$1F` SFX** | **3,304 / 3,329** | LA DX's SFX bank copied as binary and renumbered |
| MS2 `$28` ← LA `$1B` music | engine yes, sequencer no | LA's RAM layout, effects and tables around a new byte-code sequencer |

**Metal Slug 2 is derived from Link's Awakening DX, not from SMB Deluxe.**
- Its SFX bank has LA's slot layout. SMB moved slot 2 to ch2 and renumbered effects globally.
- It keeps LA DX's `rP1` write at the end of `Sound_Stop`.
- Its noise table is LA bank `$1E`'s.
- Four absolute references were never relocated and still hold LA DX addresses: `$53B5`, `$63CC`, `$7A20` and an 11-entry step table. In MS2 they point into jump tables or code. Those are binary copies, not reassemblies of source.

The bank tag bytes `$1D` / `$1E` at the start of MS2's banks are probably bank numbers from the developers' own layout.

---

## 6. Addendum: Tetris, Tetris Attack, Sanrio Carnival 2

From the full disassemblies (`Tetris_SoundDriver.md`, `TetrisAttack_SoundDriver.md`, `SanrioCarnival2_SoundDriver.md`).

### 6.1 Tetris: between SML1 and Dr. Mario

| Pair | Aligned |
|---|---|
| Tetris ← SML1 | 738 / 1,101 (67 %) |
| Tetris ← Dr. Mario | 758 / 1,101 (69 %) |
| Dr. Mario ← SML1 | 630 / 1,293 (49 %) |

- **Like *SML1*:** `$9D` is the only command, triggers use NRx4 | `$80`, rests write envelope `$01`, and the vibrato type test jumps unconditionally.
- **Like *Dr. Mario*:** all variables in the `$DF00` page with channel structures at `$DF90`, the 12-instruction mute, and a pause that reloads a wave.
- **Shared by all three:** the note table, the 55-byte wobble table and the pause-jingle images.
- **A Tetris leftover in Dr. Mario.** Tetris's ch3 effects take all four channels and, at their end, reload wave `$6EC9` for song 5 or `$6EE9` otherwise. *Dr. Mario* has the same two routines unreferenced (`Sfx3_Start_Unused` / `Sfx3_Stop_Unused`): they reload `$6BD3` / `$6BF3` with the same song-5 test, and those are the same two waves byte for byte.

So *Dr. Mario*'s driver was built from the Tetris version.

### 6.2 Tetris Attack: SML2 code, Dr. Mario tables

| Tetris Attack bank `$08` music driver vs. | Aligned |
|---|---|
| Super Mario Land 2 | 662 / 905 (73 %) |
| Link's Awakening DX `$1B` | 623 / 905 (69 %) |
| Dr. Mario | 578 / 905 (64 %) |
| Tetris | 489 / 905 (54 %) |
| Super Mario Land | 466 / 905 (51 %) |

- **From *SML2* (or *SML2* / *LA*):** release envelopes and the release point, 6-byte panning entries, the length-release code. It also keeps *SML2*'s save/restore-state routines (unreferenced, with *SML2*'s loop bug fixed), which LA DX dropped.
- **From *Dr. Mario*:** the pitch-effect routine (59 / 59 instructions), the note table with C♯7 = `$7C4`, the wobble table (its cycle extended to 135 bytes), packed length tables, and **all six of Dr. Mario's waves** (`$6BC3–$6C22`), present but unreferenced in both music banks.
- **Like *LA DX*:** the 11-byte header and the `$D300` RAM page. The command set is cut back to `$9B–$9F`.
- **The effect engine is not Tanaka's:** one stream player for up to four register-row streams per effect, with big-endian stream pointers.

### 6.3 Sanrio Carnival 2

The full disassembly confirms §3. Shadow registers, bit-mask SFX slots with a byte-code interpreter, per-channel byte streams with calls and returns, envelope / pitch / drum macros. Nothing in it matches the Tanaka family.

---

## 7. Addendum: Kirby Tilt 'n' Tumble

From the full disassembly (`KirbyTiltNTumble_SoundDriver.md`).

| Pair | Aligned | Relationship |
|---|---|---|
| KTT `$0E` ← SMB DX `$1D` music | 1,127 / 1,383 | same driver, extended (LA `$1B`: 923) |
| KTT `$0F` ← KTT `$0E` | 1,340 / 1,350 | two copies, split `$01–$3F` / `$40–$7F` like LA's `$1B` / `$1E` |
| KTT `$11` helpers ← SMB DX `$1F` | 326 / 835 (LA `$1F`: 281) | same helper library; new four-slot dispatch with a priority table |
| KTT `$14` ← KTT `$11` helpers | 600 / 628 | relocated copy for effects `$80+` |

- **Built from SMB DX:** envelope tables, rest envelopes, `$9A` volume, drop of 32, vibrato type 2, `SetRegsSkip0`. The note table (A♯5 = `$774`, C♯7 = `$7C5`), vibrato table and nine length tables are SMB DX's.
- **Back from LA:** two music banks, the `$9E` tempo command, a ch3 SFX slot.
- **New:** per-channel transpose and envelope commands, list-level commands, per-song drum kits, per-song hurry length tables, and PCM played through NR50 from the home bank.
