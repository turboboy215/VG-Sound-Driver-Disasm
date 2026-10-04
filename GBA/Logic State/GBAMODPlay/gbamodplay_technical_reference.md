# GBAModPlay (Logik State)
## Reverse-engineering report and technical reference: versions 1, 2 and 3

**Subject files** (`…/GBAAudioLab/GBAMOD/`)

| Version | Module magic | Game (ROM) | ROM credit string |
|---|---|---|---|
| 1 | `"GBAMOD1."` | *Pinball Challenge Deluxe* (E) | "MUSIC REPLAY LICENSED FROM LOGIK STATE" |
| 2 | `"GBAMOD2."` | *Aero the Acro-Bat: Rascal Rival Revenge* (E) | "LOGIK STATE" |
| 3 | `"GBAMOD30"` | *Need for Speed: Underground 2* (U) (M4) | `"GBAModPlay (C) Logik State 2003 www.LogikState.com"` at `0x087574AC` |

**Provenance.** Only version 3 names itself (the copyright string above, next to the player's
rate tables). Versions 1 and 2 are identified by their module magic and by the Logik State credit
in each game. There are no symbols in any of the ROMs: every function, variable and table name in
this document and in the sources was assigned during this analysis.

This engine has **no code or data in common** with QuickThunder (AudioArts) or Mark Cooksey's
driver, the project's other subjects. Unlike both of them it is a **software mixer**: every note
is resampled by the CPU into an 8-bit buffer that DMA feeds to the DirectSound FIFOs. The PSG
channels are never used.

Everything below comes from disassembling the three ROMs. Where something is an inference rather
than a direct reading of the code, it is marked *(inferred)*.

---

## 1. Executive summary

GBAModPlay plays **ProTracker-style modules converted to a GBA-specific binary format**. The
module header begins with an 8-byte magic that carries the version. The three versions are one
code lineage, but each changed the module format, so a module only plays on its own version.

Common to all three:

* **GCC-compiled Thumb C** for the sequencer and control API, plus a **hand-written ARM module**
  (mixers, DMA restart veneer, BIOS stubs, VCOUNT waits). The ARM files of all three versions
  contain the same `0x12345676` marker words.
* **Software mixing at 21 024 Hz** (Timer 0 reload `0xFCE2`), **mono, 8-bit signed**. Every
  channel is added into the buffer with `*dst += sample * vol >> 8`. **Nothing clips**: the 8-bit
  add wraps, so a loud mix overflows audibly.
* **20.12 fixed-point** sample positions and steps. Sample loops are a one-time
  `ptr += loopStart` followed by `end = loopLen`.
* **Double buffering, one frame of latency.** Each frame the host restarts the sound DMA at the
  buffer mixed last frame (352 bytes = 21 024 / 59.73 Hz), then the player mixes the other one.
* **Row and tick countdowns in samples.** The mixer works in slices that end at the next row or
  the next tick, so row and effect timing is sample-accurate within a frame.
* **ProTracker effects** 0–F, with a different subset, and a different set of bugs, in each version
  (§10.2).
* **"Jingles"** (a second song position or module that interrupts the music and returns to it),
  **priority**, **skip** and **queued order changes**. Most of this API is unused in all three games.

What changes between versions:

| | v1 (Pinball) | v2 (Aero) | v3 (NFSU2) |
|---|---|---|---|
| Channels | 4 music + 2 SFX, fixed | module-defined, max 8 incl. 2 SFX (Aero: 6 music) | module-defined, max 12 incl. SFX |
| Globals | fixed EWRAM variables, some in `.data` | fixed IWRAM variables | host-supplied work block (`gmpState`), two players |
| Pitch | per-module step table, 296 entries | per-module step + Amiga period tables, 976 entries | ROM Amiga period table + per-rate step tables, **or XM linear frequency** |
| Samples | inside each module | shared external bank (headers still per module) | shared 256-slot bank with `relNote`/finetune (XM-like) |
| Patterns | 4-byte cells, only stored rows | 4-byte cells, only stored rows | **three RLE streams per channel** (note, volume column, effect) |
| Volume column | — | — | yes |
| Tempo | ticks fixed at 50 Hz | ticks fixed at 50 Hz (BPM changes only the row length) | BPM × 2/5 Hz ticks |
| SFX | via `gmpPlayNote` on a second player | SFX bank, pitch from the module's step table | SFX bank with a rate in Hz, priority allocator |
| Mixer | 8× unrolled, copied to EWRAM | simple loop, copied to IWRAM | LZ77-packed, unpacked to IWRAM; mono loop or 1 004-byte all-channel mixer |
| Mix rates | 21 024 | 21 024 | 9-entry table (10 512–44 100); NFSU2 uses 21 024 |
| FIFOs | A only | A and B, same buffer | A, or A and B from the same buffer (NFSU2) |
| Volume controls | subtractive attenuation | subtractive attenuation | multiplicative (`vol × music × master × fade`) |
| Extras | — | — | echo, test tone, jingle-on-beat, fade-in (all unused except the fade) |

---

## 2. Lineage between the versions

The code is clearly one lineage: function order, variable layout and many idioms carry over.

* **v1 → v2.** The same C source, extended. The fixed four channels become a module field; the
  EWRAM globals move to IWRAM; the module gains a 976-entry Amiga **period** table next to the step
  table, and effects now slide periods instead of steps (which introduced the instant tone
  portamento, §11.1). Samples move to one shared bank and an SFX bank is added. The 8× unrolled
  EWRAM mixer is replaced by a simpler loop in IWRAM. `gmpJumpSong`/`gmpSetReturn` with loop ranges
  become `gmpJumpOrder`/`gmpSetReturnOrder` without them.
* **v2 → v3.** A rewrite into a relocatable **library**: all state lives in one block the host
  passes to `gmpInit`, there are two player structs (music and jingle), and the channel struct
  doubles to 0x98 bytes. The format gains XM features (linear frequency mode, sample `relNote`,
  a volume column, up to 12 channels, a module name field) and **RLE-compressed patterns**. The
  mixers are stored LZ77-compressed. The ARM module is a descendant of v1's: the same `bx r3`
  veneers, VCOUNT waits, RLE window fill and LZ77 SWI stubs appear in both, in the same order.
* **Recurring code.** `gmpPlayJingle`, `gmpQueueOrder`, `gmpSkipPattern`, `gmpPause`,
  `gmpPauseAfterJingle`, `gmpResume`, `gmpMixChannelC` (a C copy of the mixer) and the
  "tick effects keyed by `CH_tickFx`" switch exist in all versions that have them, with the same
  structure. Several bugs survive from version to version (§11.1).

---

## 3. Build and ROM layout

All three players are **Thumb compiled by GCC** *(inferred from idioms: `adds rX, rY, #0` moves,
`push {…}; pop {r0}; bx r0` epilogues, `mov pc, r0` switch tables)*, linked with libgcc/newlib
(`__divsi3`, `__udivsi3`, `memcpy`, `memset`). v3 divides through BIOS SWI 6 stubs instead.

### 3.1 v1: Pinball Challenge Deluxe (E)

| Region | ROM range | Size | Contents |
|---|---|---|---|
| **Player (Thumb)** | `0x08004234`–`0x0800519C` | 3 944 B | 23 functions |
| host DMA/sound-on helpers (game code) | `0x0800DD60`–`0x0800DDDC` | 124 B | `hostStartDma`, `hostSoundOff/On` |
| **ARM module** | `0x080CE0C0`–`0x080CE758` | 1 688 B | veneers, 3 mixers, VCOUNT waits, DMA restart, RLE fill, LZ77 stubs |
| **Rodata** | `0x083C27C8`–`0x083C28B4` | 236 B | vibrato sine, 2 switch tables |
| `.data` initialisers | `0x083E16D0` → `0x02000000` | | copied at boot; `gmpPortaScale = 4`, `gmpTonePortaScale = 40`, volumes 64 |
| **Modules** | `0x0805993C`–`0x080A50E8`, `0x0814CCF4`–`0x081C8C5E`, `0x0826A58C`–`0x08316E1C` | | 11 modules in three ranges (game data sits between them) |

### 3.2 v2: Aero the Acro-Bat (E)

| Region | ROM range | Size | Contents |
|---|---|---|---|
| (Nintendo EEPROM_V122 library) | before `0x081036C4` | | not part of the player |
| **Player (Thumb)** | `0x081036C4`–`0x08104980` | 4 796 B | 41 functions |
| **ARM module** | `0x08104980`–`0x08104B00` | 384 B | DMA restart veneer, `bx r3`, mixer |
| **Rodata** | `0x08356E5C`–`0x083576C8`, `0x08357AB0` (4 B) | | vibrato sine, an unreferenced 960-entry period table, 2 switch tables; buffer size 352 |
| **Sound data** | `0x08036220`–`0x08103294` | 839 796 B | 22 modules, sample bank `0x0809B410`, SFX bank `0x080A6040` |
| song table (game) | `0x083576C8` | | 25 module pointers |

### 3.3 v3: Need for Speed: Underground 2 (U)

| Region | ROM range | Size | Contents |
|---|---|---|---|
| **Player (Thumb)** | `0x08135C84`–`0x08138220` | 9 628 B | 73 functions |
| **Period/step tables** | `0x08138220`–`0x08141300` | 37 088 B | `gmpAmigaPeriods[976]`, `gmpStepTables[9][976]` |
| **ARM module** | `0x08141300`–`0x081418DC` | 1 500 B | SWI stubs, DMA restart, unused helpers, **two LZ77-packed mixers** |
| **Rodata** | `0x08756E8C`–`0x08757528` | 1 692 B | vibrato sine, `gmpLinearFreq[768]`, copyright, rate tables |
| rate→table pointers | `0x0878E7AC`–`0x0878E7D0` | 36 B | `gmpRateStepTab[9]` |
| **Sound data** | `0x08000210`–`0x080FBE74` | 1 031 268 B | SFX bank `0x08000210`, 9 modules `0x0803A2C8`, sample bank `0x080431FC` |
| song table (game) | `0x0877B834` | | 9 module pointers |

---

## 4. Public API and host integration

### 4.1 v1

| Address | Function | Notes |
|---|---|---|
| `08004234` | `gmpInit()` | `malloc`s two 0xA00 mixer copies, two 352-byte buffers and an unused 0x2C0 block; copies the mixers. Pinball: `0x080075C2` at boot |
| `08004380` | `gmpLoadModule(player, module)` | checks `"GBAMOD1."`, builds sample and pattern pointers |
| `08004428` | `gmpStartSong(order, loopStart, loopEnd)` | Pinball passes `(order, order, -1)`: no loop range |
| `08004560` | `gmpJumpSong(order, loopStart, loopEnd)` | restart without resetting volumes/SFX |
| `08004650` | `gmpPlayJingle(order, loopStart, loopEnd, pri)` | a jingle is a range of orders in the current module |
| `08004718` | `gmpQueueOrder(order, loopStart, loopEnd, pri)` | taken at the next row (see §11.1) |
| `0800478C` | `gmpSetReturn(order, loopStart, loopEnd)` | |
| `080047B0` | `gmpEndJingle()` | also called by `Bxx` during a jingle |
| `08004824`… | `gmpSkipPattern`, `gmpPause`, `gmpPauseAfterJingle`, `gmpResume`, `gmpClearMusic` | |
| `080048A0` | `gmpMixNext()` | per frame |
| `08004C58` | `gmpPlayNote(player, ins, note, channel)` | Pinball's sound effects |

**Host glue (Pinball).** `hostStartDma` (`0x0800DD60`) sets `SOUNDCNT_H = 0x8B0E`, DMA1 → FIFO A,
Timer 0 = `0xFCE2`, and waits on VCOUNT with the ARM module's (correct) waits. Each frame
(`0x080088E2`) the game calls `gmpDmaRestart(gmpBuf[gmpCur])` (ARM), then `gmpMixNext()`, and if
that returns 0 it marks the current buffer free and flips `gmpCur`.

**Pinball's sound effects** use a *second player struct* at `0x02002840`. At `0x0800767C` the game
loads module 0 (`0x0805993C`, a one-pattern module whose three samples are the effects) into it,
then plays effects with `gmpPlayNote(0x02002840, ins, 0x93, 5)`: step index 0x93, SFX channel 5.
Channel state is global (`gmpChan[6]`), so only the sample pointers come from the second player.

### 4.2 v2

| Address | Function | Notes |
|---|---|---|
| `08103840` | `gmpInit(iwram)` | bump-allocates the mixer (0x258) and two 352-byte buffers from `iwram` |
| `08103770` | `gmpPlaySong(module, order, bank)` | `gmpClearChannels`, `gmpLoadModule`, `gmpStartSong` |
| `081037D8` | `gmpVBlank()` | per frame: DMA restart, mix next buffer, flip |
| `0810379C`/`A8` | `gmpSoundOff/On()` | `SOUNDCNT_X` |
| `081037B4`–`CC` | `gmpSetMasterVolume/MusicVolume/SfxVolume(v)` | 0..64, used as attenuation (§8) |
| `0810429C` | `gmpLoadSfxBank(bank)` | |
| `081042C0` | `gmpPlaySfx(sfx, note, channel, vol)` | |
| `08104354` | `gmpStopSfx(channel)` | |
| `08103BB0` | `gmpJumpOrder(order)` | |
| `08103C84`… | `gmpPlayJingle`, `gmpQueueOrder`, `gmpSetReturnOrder`, `gmpEndJingle`, `gmpSkipPattern`, `gmpPause`, `gmpPauseAfterJingle`, `gmpResume` | jingle API, unused by Aero |
| `08104214` | `gmpPlayNote(player, ins, note, channel)` | unused |

**Host glue (Aero).** At `0x0802C61E`: `gmpInit(0x03005D50); gmpPlaySong(module, 0, 0x0809B410);
gmpSetMasterVolume(0); gmpLoadSfxBank(0x080A6040); gmpSoundOn()`. `gmpVBlank()` is called once per
frame from `0x08029702`. The game plays every SFX at note index 194 (≈ 7 930 Hz).

### 4.3 v3

| Address | Function | Notes |
|---|---|---|
| `081366E8` | `gmpInit(params, rateIdx, maxSfx, dmaMode)` | returns SFX count, or −1 (IWRAM too small), −2 (work block too small), −3 (no sample bank) |
| `08135F60` | `gmpRequestSong(module)` | started at the next `gmpFrame` |
| `08136130` | `gmpDmaRestart()` | **first** call of the frame |
| `0813629C` | `gmpFrame()` | mixes the next buffer |
| `081363C4` | `gmpFlip()` | **last** call of the frame |
| `08135EC4` | `gmpStop()` | silence + DMA/timer off |
| `081360CC`… | `gmpSoundOn`, `gmpSetMasterVolume`, `gmpSetMusicVolume`, `gmpSetSfxVolume`, `gmpSetRate`, `gmpSetLoop` | |
| `08137514` | `gmpPlaySfx(sfx, rate, sfxChannel, vol)` | rate 0 = the bank's rate |
| `081372F4` | `gmpPlaySfxAuto(sfx, rate, pri, vol)` | priority allocation, unused by NFSU2 |
| `08137620`… | `gmpSetSfx`, `gmpStopSfx`, `gmpClearSfxVol`, `gmpSfxPlaying` | |
| `08136994`… | `gmpPlayJingle`, `gmpPlayJingleOnBeat`, `gmpEndJingle(2)`, `gmpSkipPattern`, `gmpPause`, `gmpResume` | jingles are *separate modules* on player 1 |
| `0813711C`… | `gmpEchoInit`, `gmpSetEcho` | unused |
| `0813686C`… | `gmpGetRow`, `gmpGetOrder`, `gmpGetLoopCount`, `gmpGetBPM`, `gmpSetBPM`, `gmpGetChannelVolume` | unused |

`params` is `{iwram, iwramSize, work, workSize, sampleBank, sfxBank, mixMode}`. The work block must
be ≥ `0x1E4C` bytes; the IWRAM block must hold `2 × bufBytes + (mixMode ? 0x3EC : 0xA0)`.

**Host glue (NFSU2).** At start-up (`0x080FCD2C`):
`gmpInit(&{0x03005B10, 0x54C, malloc(0x26AC), 0x2000, 0x080431FC, 0x08000210, 0}, 4, 4, 2);
gmpSetMasterVolume(64); …`: rate index 4 (21 024 Hz), four SFX channels, both FIFOs, mixer mode 0.
Every frame (`0x080FC2D8`): `gmpDmaRestart(); …; gmpFrame(); gmpFlip();`. Songs start with
`gmpRequestSong(songTable[n])`.

---

## 5. Hardware resources

| | v1 | v2 | v3 |
|---|---|---|---|
| Timer 0 | `0xFCE2` (21 024 Hz) | `0xFCE2` | `gmpRateTimer[i]` (`0xFCE2` in NFSU2) |
| Timer 1 | — | `0xFCE2` too (clocks FIFO B) | — |
| DMA1 → FIFO_A | yes | yes | yes |
| DMA2 → FIFO_B | — | yes, **same buffer** | mode 2: yes, **same buffer** |
| `SOUNDCNT_H` | `0x8B0E` (A on L+R, Timer 0) | `0xFB0E` (A on T0, B on T1, both L+R) | mode 1 `0x0B0E`, mode 2 `0xBB0E` |
| `SOUNDCNT_X` | `0x80` / `0` for pause | same | same |
| DMA control | `0xB600` (enable, FIFO timing, 32-bit, repeat) | same | same |

Feeding both FIFOs from one buffer (v2, v3 mode 2) does **not** give stereo: it simply plays the
same mono signal through both DirectSound channels, doubling the level.

**VCOUNT waits.** The DMA start is meant to wait until the display leaves scanlines 0x3E and 0x3D
*(the purpose of this is not clear; inferred as a start-up sync)*. Only v1 gets this right: its
game glue calls the ARM `gmpWaitVCountLeave` (`0x080CE668`), which reads `REG_VCOUNT`. v2's C wait
loop never loads the register address and reads through whatever `r2` holds (`0xFCE2`, a BIOS
address). v3's C version reads `REG_DISPCNT` instead of `REG_VCOUNT`, while correct ARM copies at
`0x081414CC`/`0x081414DA` go unused. In v2 and v3 the wait therefore does nothing.

---

## 6. Per-frame flow

### 6.1 v1 and v2

```
host (v1: game code at 0x080088E2; v2: gmpVBlank)
    gmpDmaRestart(gmpBuf[gmpCur])        DMA plays the buffer mixed last frame
    if (gmpMixNext() == 0) { gmpBufFree[gmpCur] = 1; gmpCur ^= 1 }

gmpMixNext:
    if (paused) return 0;  if (!gmpRate) return 1
    (v1: if gmpOrder >= songLen, clear the music channels)
    b = gmpCur ^ 1; if (gmpBufFree[b]) { gmpBufFree[b] = 0; gmpMix(gmpBuf[b]) }

gmpMix(dst):                                      352 samples
    attM/attS from master/music/sfx volumes (§8)
    memset(dst, 0, 352)
    while not full:
        if (!rowLeft)  { gmpProcessRow();  rowLeft = rowLen }
        if (!tickLeft) { if (rowLeft != rowLen) gmpProcessTick(); tickLeft = tickLen }
        n = min(rowLeft, tickLeft, remaining)
        for each channel: v = CH_vol - att; if (v > 0 && CH_end > 2) mixer(ch, dst, n)
        dst += n; rowLeft -= n; tickLeft -= n
```

`tickLen = rate / 50` and `rowLen = rate × speed / 50`, so ticks run at a fixed **50 Hz**. The
row's first tick is skipped, as in ProTracker.

### 6.2 v3

```
gmpDmaRestart()                        re-arm DMA1+DMA2 at (&ST_buf0)[ST_cur]
gmpFrame():
    gmpApplyRate()                     pending rate change; fade-in ramp (+3/frame up to 64)
    gmpServiceSongRequest()            start a queued gmpRequestSong module on player 0
    gmpServiceJingle()                 switch player 0 <-> player 1 (optionally on a row % 4 == 0)
    back = (&ST_buf0)[ST_cur ^ 1]
    clear back unless the mode-1 mixer overwrites it
    if (ST_paused || !ST_rateHz) return
    if (gmpTestTone(back)) return      disabled factory test (A440 saw)
    mode 0: gmpMix(back, 0, nMusic); if (echo) gmpApplyEcho(back)
    mode 1: gmpMix(back, 0, nChan)     music + SFX in one pass
gmpFlip():
    mode 0: gmpMixSfx(back)            SFX added after the echo
    ST_prev = ST_cur; ST_cur ^= 1
```

`gmpMix` has the same row/tick slicing as v1/v2, but `tickHz = BPM × 2 / 5`,
`tickLen = rate / tickHz` and `rowLen = rate × speed / tickHz`, and ticks are processed on every
tick including the row's first one. The two counters run independently (§11.4).

---

## 7. RAM maps and structures

The complete lists, with a comment on every field, are the `.equ` blocks at the top of each
`gbamodN_player.s`. The main points:

### 7.1 v1 (EWRAM)

```
020006C0..0200071B  control variables (queue, skip, pause, jingle, loop range, volumes, tick)
02000434/438        game options copied into the music/SFX volume by gmpStartSong
020029E0            gmpMixerCode, gmpMixerCode2   -> EWRAM mixer copies (0xA00 each)
020029E8            gmpBuf[2]                      -> 352-byte buffers
02002A00            gmpPlayer {module; patPtr[64]; smpPtr[31]}   (music)
02002840            Pinball's second player (SFX module)
02002B80..02002B98  step table ptr, order, cell, row/tick lengths and countdowns
02002BA0            gmpChan[6]   0x3C bytes each (4 music + 2 SFX)
02002D08..02002D18  return order, buffer-free flags, gmpCur
```

### 7.2 v2 (IWRAM `0x030066D0`–`0x03006B6C`)

```
030066D0  gmpPlayer {module; patPtr[64]; smpPtr[31]}  (0x180)
03006850  master/music/SFX volumes, buffers, gmpCur, buffer-free flags, IWRAM allocator, mixer ptr
03006880  pattern rows ptr, channel count, speed, BPM, rate, E6x mark, tick Hz, step/period tables,
          order, cell, row/tick lengths and countdowns
030068C0  gmpChan[8]   0x4C bytes each (music first, SFX in the last two)
03006B20  jumped, tick, jingle/queue/skip/pause state, arpeggio tick, SFX bank pointers
```

### 7.3 v1/v2 channel struct

| Off | Field | Meaning |
|---|---|---|
| `00` | `ptr` | sample data |
| `04` | `pos` | 20.12 position |
| `08` | `step` | 20.12 step |
| `0C` | `end` | u16 length; `2` = stopped |
| `0E` | `loopStart` | u16, added to `ptr` at the first wrap |
| `10` | `loopLen` | u16, 0 = one-shot |
| `14` | `vol` | 0..64 |
| `18`/`1C`/`1E` | `ins` / `fine` / `note` | note = step-table index (v1) or period-table index (v2) |
| `20` | `tickFx` | effect run on ticks, −1 = none |
| `24`–`3A` | slide, arpeggio, vibrato, portamento state | |

v2's struct is 0x4C bytes with the same fields; nothing in the player addresses bytes 0x3C–0x4B.

### 7.4 v3

```
*0x030065D0  gmpState   -> host work block (0x1E4C bytes)
*0x030065DC  gmpPlayer  -> &ST_player0 or &ST_player1
 0x030065D8  gmpMixCount (debug counter, never read)

GmpState:  +0x000 buffers, cur/prev, test tone, rate index/Hz, step table, IWRAM allocator,
                  mixer pointer, jingle/pause/fade flags
           +0x05C ST_player0    music player   (0xBA0 bytes)
           +0xBFC ST_player1    jingle player
           +0x179C sample headers pointer, +0x17A0 smpPtr[256]
           +0x1BA0 SFX entries/data, volumes, SFX count, playing/loop, limits, buffer sizes,
                  echo state, mixer mode, song/jingle requests
GmpPlayer: +0x00 module, amiga flag, rows, skip, speed, tempo lock, tickHz, row/tick countdowns,
                 tick, arpeggio tick, BPM, row, order, loop count, jumped, pattern base
           +0x054 chan[12]      0x98 bytes each
           +0x774 rowState[12]  0x58 bytes each (RLE stream readers + the decoded 6-byte cell)
           +0xB94 nMusic, nSfx, nChan
GmpChannel (0x98): v2's fields at new offsets, plus relNote (+3C), linear porta/vibrato offsets
                   (+80, +84), porta memory (+88), volume column (+8C), SFX priority (+90),
                   linear target (+94), E6x row/count (+78, +7A), SFX compressed flag and an
                   ADPCM state area (+20..+2F) that nothing uses
```

---

## 8. Mixing and volume

### 8.1 Mixer routines

| | v1 | v2 | v3 mode 0 | v3 mode 1 |
|---|---|---|---|---|
| Routine | `gmpMixChannelUnrolled` (0x290 B) | `gmpMixChannel` (0x118 B) | mono mixer (160 B) | multi mixer (1 004 B) |
| Stored | ARM in ROM, copied to EWRAM (0xA00 B) | ARM in ROM, copied to IWRAM (0x258 B) | LZ77 in ROM, unpacked to IWRAM | LZ77 in ROM, unpacked to IWRAM |
| Structure | 8 samples per pass + remainder via a jump table | 1 sample per pass, fast path at vol 64 | 1 sample per pass | 16 samples × all channels per pass, self-modifying remainder |
| Used by | Pinball | Aero | NFSU2 | — |

Per sample, all of them do:

```
if (pos >> 12 >= end) { ptr += loopStart; loopStart = 0; end = loopLen; ... }
*dst++ += ptr[pos >> 12] * vol >> 8;  pos += step
```

v1/v2 keep only the fraction at a wrap (`pos &= 0xFFF`); v3 subtracts `end` (`pos -= end`),
which is correct for steps above 1.0.

**v3 multi mixer.** `gmpMix` builds a list of 5-word records on the stack (`{src, vol, pos
fraction << 20, step fraction << 20, step integer}`), shortens the slice so no channel passes its
end, and calls the mixer once. The mixer sums 16 output samples per channel pass as 16-bit pairs
in `r6`–`r12` **and `sp`** (so an interrupt taken on the same stack would crash). The last 4, 8 or
12 samples are handled by **patching a branch and the store instruction into its own code**, then
restoring them. In the paired sums a negative low half borrows from the high half, so odd samples
can be 1 LSB off. It contains `mul` with Rd == Rm, which ARMv4 declares unpredictable (it works on
the ARM7TDMI). NFSU2 does not use this mixer.

**Unused mixers.** v1 also has a plain per-channel mixer and a no-volume mixer (copied to EWRAM
but never called); v2 and v1 have C versions (`gmpMixChannelC`, v2 also a 32-bit accumulator
variant); v3 keeps an uncompressed older build of the mono mixer (`gmpMixerMonoOld`).

### 8.2 Volume

* **v1, v2: subtractive.** `attM = clamp(max(64 − master, 64 − music), 0, 64)` (likewise `attS`
  for SFX), and a channel plays at `CH_vol − att`. Setting the music volume to 32 therefore does
  not halve the music: it removes 32 steps from every channel, so quiet channels go silent first.
* **v3: multiplicative.** `v = CH_vol × (music or sfx) / 64 × master / 64 × fade / 64`. `ST_fade`
  drops to 0 when a jingle ends and ramps back by 3 per frame.

---

## 9. Data formats

### 9.1 v1 module (`"GBAMOD1."`)

```
+0x000  "GBAMOD1."
+0x008  u32 pattern bytes
+0x00C  u32 sample bytes
+0x010  u32 mix rate (21024)
+0x014  u32 song length
+0x018  u32 step[296]         20.12 at 21024 Hz, 8 steps per semitone; 0 = B-0, 8 = C-1, 288 = B-3
+0x4B8  31 x {u16 length, finetune, volume, loopStart, loopLen, 0}
+0x62C  u32 number of patterns
+0x630  u8 orders[128]
+0x6B0  u8 rows[64]           rows stored per pattern; missing rows play as empty
+0x6F0  64 unused bytes
+0x730  patterns: 4 channels x rows x 4-byte cells
        then 8-bit signed PCM for the 31 samples, in order
```

### 9.2 v2 module (`"GBAMOD2."`)

```
+0x0000  "GBAMOD2."
+0x0008  u32 channels
+0x000C  u32 pattern bytes
+0x0010  u32 sample bytes
+0x0014  u32 mix rate
+0x0018  u32 song length
+0x001C  u32 step[976]        20.12 at 21024 Hz
+0x0F5C  u16 period[976]      Amiga periods, 8 per semitone: 8 = C-0 (1712), 104 = C-1 (856), 200 = C-2 (428)
+0x16FC  31 x {u16 length, finetune, volume, loopStart, loopLen, 0}   play parameters
+0x1870  u32 number of patterns
+0x1874  u8 orders[128]
+0x18F4  u32 rows[64]
+0x19F4  256 unused bytes
+0x1AF4  s32 flag             < 0: ignore the bank and use samples after the patterns
+0x1AF8  patterns: channels x rows x 4-byte cells
```

In Aero every module's step and period tables are identical. The **sample bank** (`0x0809B410`)
has the same 31 headers followed by the PCM, but `gmpLoadModule` takes only the data pointers from
it: length, loop, volume and finetune always come from the module's own headers.

### 9.3 v1/v2 pattern cell (4 bytes)

```
u16 a = ins << 9 | note        note 9 bits (0x1FF = none), ins 5 bits (0 = none)
u16 b = cmd << 8 | param       ProTracker effect
```

### 9.4 v2 SFX bank

```
u32 count; count x {u32 offset, u32 length, u16 ?, u16 volume, u16 loopStart, u16 loopLen, u32 ?}; PCM
```

### 9.5 v3 module (`"GBAMOD30"`)

```
+0x000  "GBAMOD30"
+0x008  char name[32]         (empty in NFSU2)
+0x028  u32 channels          music channels (max 12)
+0x02C  u32, +0x030 u32       0, unused
+0x034  u32 song length
+0x038  u8 insMap[256]        converter's instrument map; the player does not read it
+0x138  u32 number of patterns
+0x13C  u32 rows per pattern
+0x140  u32 frequency mode    1 = Amiga periods, 0 = XM linear
+0x144  u32 initial BPM
+0x148  u32 initial speed
+0x14C  u8 orders[256]        0xFF-terminated
+0x24C  u32 patOffs[256]      from +0x650
+0x64C  u32                   0
+0x650  pattern data
```

**Pattern.** For each channel in turn, a block:

```
u32 notesLen, volOfs, fxOfs, fxEnd, blockLen     offsets from the start of the notes stream
notes stream   runs {u8 count, u8 hi, u8 lo}   value = note << 7 | ins (note 0x1FF = none)
0
volume stream  runs {u8 count, u8 value}       0 = none, else volume + 1
0
effect stream  runs {u8 count, u8 cmd, u8 par}
0
"PAD" filler up to blockLen
```

Notes are XM numbers (1 = C-0, 49 = C-4); `ins` is a sample-bank slot + 1. The decoder
(`gmpDecodeRow`) opens the streams on row 0 and afterwards only reads forward: it **cannot seek**.

### 9.6 v3 sample bank

```
256 x {u16 length, finetune, volume, loopStart, loopLen, relNote}  (0xC00 bytes); then 8-bit PCM
```

A sample at C-4 plays at `8363 × 2^((relNote + finetune/128) / 12)` Hz in linear mode.

### 9.7 v3 SFX bank

```
u32 count
count x {u32 offset, u32 length, u16 finetune, u16 volume (unused), u16 loopStart, u16 loopLen,
         u32 rate Hz, u8 compressed, 3 pad}
PCM
```

The compressed flag makes `gmpPlaySfx` set up an ADPCM-style state, but no mixer decodes it.

### 9.8 v3 tables

* `gmpAmigaPeriods[976]`: same values as v2's in-module period table.
* `gmpStepTables[9][976]`: `step = (7093789.2 / (period × 2) << 12) / rate`, one table per rate.
* `gmpLinearFreq[768]`: `16384 × 2^(i/768) × 8363/8192`; `freq(period) = (tab[x % 768] × 4) >> (7 − x / 768)`
  with `x = 7680 − period` (8363 Hz at period 4608).
* Rate tables (index 0–8):

| idx | Hz | Timer 0 | samples/frame |
|---|---|---|---|
| 0 | 10 512 | 63 940 | 176 |
| 1 | 13 379 | 64 278 | 224 |
| 2 | 15 282 | 64 439 | 256 |
| 3 | 18 157 | 64 604 | 304 |
| **4** | **21 024** | **64 738** | **352** (NFSU2) |
| 5 | 26 758 | 64 908 | 446 |
| 6 | 31 536 | 65 003 | 526 |
| 7 | 36 314 | 65 073 | 606 |
| 8 | "44 100" | 65 073 | 606 |

`gmpInit` clamps the index to 4, so entries 5–8 are unreachable. Entry 8 claims 44 100 Hz but
repeats entry 7's timer and buffer size.

---

## 10. Sequencer and effects

### 10.1 Row processing

* **v1/v2**: `gmpCell` counts cells (row × channels). A row past the pattern's stored rows plays
  as empty. At cell 64 × channels the order advances; v2 always loops the song, v1 stops at the
  end of the order list (`gmpMixNext` silences the music).
* **v3**: decode one row from each channel's streams, `PL_row++`, then run row effects (so `Dxx`
  and `Bxx` overwrite the row counter). At the end of the order list the loop counter increases
  and playback stops unless `ST_loop` is set.

### 10.2 Effect support

| Effect | v1 | v2 | v3 |
|---|---|---|---|
| `0xy` arpeggio | parsed, **no effect** (overwritten each tick) | **wrong order**: x, y, y instead of base, x, y | parsed, **no effect** (offsets never applied) |
| `1xx`/`2xx` porta | yes, in step units (`xx × 4`) | yes, in periods (ch 1–4 only) | yes; linear mode also `FFx`/`EEx` fine slides and parameter memory |
| `3xx` tone porta | yes (step units, speed `xx × 40`) | **instant** | linear: yes; Amiga: **instant** |
| `4xy` vibrato | yes, restarts every row | yes, restarts every row | linear: yes; Amiga: one-sided, reads past the table |
| `5xy` porta + slide | — | yes | yes |
| `6xy` vibrato + slide | — | yes | yes |
| `7`, `8`, `9` | — | — | — |
| `Axy` volume slide | yes (channel-skip bug when `x & y`) | yes | yes |
| `Bxx` order jump | yes; ends a jingle | yes; ends a jingle | yes; ends a jingle |
| `Cxx` volume | yes, no clamp | yes, no clamp | yes, no clamp |
| `Dxx` pattern break | next order, row `xx` (hex) | `cell = xx × 4` | row `xx` (hex); **only row 0 decodes correctly** |
| `Exy` | — | `E6x` only, **broken** | `E6x` only (only a loop to row 0 decodes correctly) |
| `Fxx` speed/tempo | `xx < 32` speed; `xx ≥ 32` gives a row `xx × 2/5` samples long | speed; BPM changes row length but not tick length | speed and BPM (ignored after `gmpSetBPM`) |
| volume column | — | — | yes |
| tick 0 skipped | yes | yes | no |

`Dxx` and the loop parameters are taken as **hex**, not BCD as in ProTracker, in all three
versions *(the converter may have compensated when writing the modules; not checked)*.

---

## 11. Bugs, quirks and dead code

### 11.1 In more than one version

1. **VCOUNT waits do nothing** in v2 (uninitialised `r2`) and v3 (reads `DISPCNT`) (§5).
2. **Queued order changes wait for the wrong rows** (v1, v2). `gmpProcessRow` takes the queued
   change when `(row & 3) != 0`, i.e. on any row that is *not* a multiple of 4. v3's
   jingle-on-beat test is the right way round.
3. **`Dxx` is hex, not BCD**, and **`Cxx` is not clamped** (all versions).
4. **Vibrato restarts every row** (v1, v2): `if (!tick) pos = 0`.
5. **Tone portamento is instant** in v2 and in v3's Amiga mode: a period offset is added to a step
   value and compared with the target step, which is already past on the first tick.
6. **Arpeggio does nothing or the wrong thing** in every version (§10.2).

### 11.2 v1 (Pinball)

1. **Arpeggio has no effect.** The tick code computes the arpeggio step, then the common code
   below it overwrites the step. Pinball's modules have 597 arpeggio cells.
2. **`Axy` with `x & y != 0` skips `ch++`**: the jump goes past the increment, so the same channel
   is processed again instead of the next one. Pinball has `A15` six times.
3. **Index clamp writes 576 instead of 296**, reading far past the 296-entry step table (only for
   very high notes with vibrato).
4. **`Fxx ≥ 0x20`** sets the row length to `xx × 2/5` *samples* (a few dozen). Pinball only uses
   speeds.
5. **Loop ranges.** With a loop range set, the order is not advanced at a pattern end: the
   pattern repeats until a `Bxx`, and `Bxx` (which stores `xx − 1` and relies on the increment)
   lands one order early. Ranges only behave for single-pattern loops. Pinball's `gmpStartSong`
   call passes no range, but some `gmpPlayJingle` calls do.
6. **Unsupported effects that the data uses**: `6xy` (1 002 cells), `9xx` (36), `E9x` (364), `E0x`
   (1). The converter wrote them; the player ignores them.
7. **Mixer copies over-read**: 0xA00 bytes are copied for 0x290- and 0x254-byte routines. The
   unrolled mixer's jump table holds **absolute ROM addresses**, so the last 1–7 samples of every
   call run from ROM even though the loop runs in EWRAM. The no-volume mixer and the 0x2C0-byte
   spare block are never used.

### 11.3 v2 (Aero)

1. **Tick effects run on four channels only** (`cmp r5, #3`), but all Aero modules have six:
   21 of the 72 portamento cells are on channels 5–6 and are ignored.
2. **Arpeggio** plays x, y, y (see above).
3. **`Fxx` BPM** recomputes the row length but not the tick length, so effects keep ticking at 50 Hz.
   21 of the 22 modules set a BPM.
4. **`Dxx`** sets `cell = xx × 4`, correct only for 4 channels: with 6 it lands mid-row and shifts
   the channels. **`E6x`**: `E60` stores a mark; `E6x` (x ≠ 0) clears a stored mark and does *not*
   jump, but jumps to row 0 when no mark is stored. Marked loops never repeat; unmarked ones
   repeat forever.
5. **SFX length is 16 bits**: SFX 25 (68 027 bytes) is cut to 2 491. **SFX pitch** comes from the
   *current module's* step table (identical in every Aero module, so harmless there).
6. **Volumes are subtractive** (§8.2).
7. **`gmpJumpOrder`** resets the timing to speed 6 / 125 BPM while `gmpSpeed`/`gmpBPM` keep their
   old values, and leaves the last two music channels sounding.
8. **One-shot samples** replay `ptr[0]` for the rest of the mix call after their end (`end = 0`);
   `pos &= 0xFFF` at a wrap drops the integer part.
9. **Mixer copy** takes 0x258 bytes for a 0x118-byte routine (0x140 bytes of libc come along).
10. **Dead code**: `gmpCheckMixer`, `gmpMixChannelC`, `gmpMixChannelC32`, `gmpPlayNote`, the
    jingle/queue API, and a 960-entry period table in rodata that nothing references. Module 4
    (`0x08049AC0`) is referenced nowhere.

### 11.4 v3 (NFSU2)

1. **Arpeggio**: `arpX`/`arpY` are stored but never added.
2. **RLE streams cannot seek**: `Dxx` to a row other than 0 and `E6x` back to a row other than 0
   keep reading the old stream position, so the wrong rows play.
3. **Amiga mode**: tone porta is instant; vibrato is one-sided and indexes a 32-entry sine table
   up to 63, reading into `gmpLinearFreq`; `gmpApplyRate` refreshes steps with the linear formula
   even in Amiga mode (wrong pitch until the next note, only after a rate change).
4. **Row/tick drift**: `rowLen = rate × speed / tickHz` is not a multiple of `tickLen`, and the
   counters are independent, so the tick phase drifts by 2 samples per row at 21 024 Hz, speed 6,
   125 BPM.
5. **Rate table**: entries 5–8 unreachable; entry 8's timer/buffer are entry 7's.
6. **`gmpPlaySfxAuto`**: the third fallback tests the loop counter (`r5`) instead of the pick
   (`r7`) and always fails.
7. **`gmpStop`** writes the E.T.-style `0x84400004` DMA constant with `strh`, so only the count
   (4) lands.
8. **`nSfx`** is computed from the unclamped channel count (a 13+ channel module would give a
   negative SFX count).
9. **Compressed SFX** flag is honoured by `gmpPlaySfx` but no mixer decodes the data.
10. **Portamento memory** is cleared on every note.
11. **`ST_sameBuf`** is only set when `gmpDmaRestart` sees `ST_cur == ST_prev`, which normal
    operation never produces; it only gates the disabled test tone.
12. **Dead code**: `gmpDeadTempoLoop` (an endless loop nothing calls), ARM `gmpDmaRestartCur`
    (starts with `bx pc` and skips its own push), `gmpEndJingle2` (duplicate), `gmpSetFlag10`,
    the echo, the test tone, the single-FIFO DMA restarts, `gmpRleFill`, the correct VCOUNT waits,
    the multi mixer and `gmpMixerMonoOld`.

NFSU2 uses only effects 1, 2, 3, 4, A and `D00`, all in linear mode, so none of the v3 sequencer
bugs is audible in the game.

---

## 12. Content inventory

| | v1 Pinball | v2 Aero | v3 NFSU2 |
|---|---|---|---|
| Modules | 11 (module 0 = SFX module; module 2 unreferenced) | 22 (module 4 unreferenced) | 9 |
| Song table | none (pointers in game tables) | 25 entries at `0x083576C8` | 9 entries at `0x0877B834` |
| Channels | 4 | 6 in every module | 1, 2 or 8 |
| Samples | per module (`gbamod1_samples_m0..m10.bin`) | 17 in the shared bank | 90 used slots in the 256-slot bank (6 unused by any module) |
| SFX | 3 samples in module 0 | 78 | 30 (four are 1-byte placeholders) |
| Frequency mode | step table | Amiga | linear in every module |
| Effects used | 0 1 2 3 4 6 9 A B C D E0 E9 F | 1 2 B C F | 1 2 3 4 A D00 |
| WAV exports | 229 files | 95 files | 118 files |

Per-module details (orders, rows, instruments, effects, sample tables, and v3's fully decoded
patterns) are in the three `gbamodN_data_dump.txt` files.

---

## 13. Notes for reimplementation or tooling

* **Identify the version** from the magic at module + 0: `GBAMOD1.`, `GBAMOD2.` or `GBAMOD30`.
* **Converting to .MOD/.XM.** v1/v2 cells map directly (note index → period via the module's own
  table; v1 index 8 = C-1, v2 index 8 = C-0). v3 needs the RLE streams expanded per channel;
  `fmt/formats.py` (`v3_module`) does this. v3 sample pitch uses `relNote`/`finetune` as in XM.
* **Playing the data as the games do**, emulate the bugs that are audible in each game: v1's
  ignored arpeggio and `6xy`/`9xx`/`Exy`, the A15 channel skip; v2's four-channel tick limit, 50 Hz
  ticks after a BPM change and instant tone porta. NFSU2 plays correctly with a standard XM-style
  linear player.
* **Clipping**: all versions wrap at 8 bits. A faithful renderer must wrap, not saturate.
* **Contrast with the other engines in this project**: QuickThunder and Cooksey's driver drive
  the PSG and play samples through DMA without a mixer; GBAModPlay is purely a software mixer and
  never uses the PSG.

---

## Appendix A: function maps

```
v1  08004234 gmpInit            0800428C gmpSetupPatterns   080042D4 gmpCheckMixers
    08004330 gmpCopyMixers      08004380 gmpLoadModule      08004428 gmpStartSong
    08004560 gmpJumpSong        08004650 gmpPlayJingle      08004718 gmpQueueOrder
    0800478C gmpSetReturn       080047B0 gmpEndJingle       08004824 gmpSkipPattern
    08004830 gmpPause           08004844 gmpPauseAfterJingle 08004850 gmpResume
    08004864 gmpClearMusic      080048A0 gmpMixNext         08004910 gmpProcessRow
    08004A40 gmpMixChannelC     08004ABC gmpMix             08004C58 gmpPlayNote
    08004CE0 gmpProcessTick     08004E9C gmpRowEffects
    host: 0800DD60 hostStartDma 0800DDC4 hostSoundOff       0800DDD0 hostSoundOn
    ARM:  080CE0C0 gmpCallR3    080CE0D8 gmpMixChannel      080CE184 gmpMixChannelUnrolled
          080CE414 gmpMixChannelNoVol 080CE668 gmpWaitVCountLeave 080CE67C gmpWaitVCount
          080CE694 gmpDmaRestart 080CE6BC gmpRleFill        080CE750 swiLZ77UnCompWram/Vram

v2  081036C4 gmpWaitLine        081036D0 gmpWaitLineLeave   081036DC gmpStartDma
    08103770 gmpPlaySong        0810379C gmpSoundOff        081037A8 gmpSoundOn
    081037B4 gmpSetMasterVolume 081037C0 gmpSetMusicVolume  081037CC gmpSetSfxVolume
    081037D8 gmpVBlank          08103818 gmpIwramAlloc      08103840 gmpInit
    08103880 gmpSetupPatterns   081038E8 gmpCheckMixer      0810391C gmpCopyMixer
    08103958 gmpLoadModule      08103A50 gmpStartSong       08103BB0 gmpJumpOrder
    08103C84 gmpPlayJingle      08103D1C gmpQueueOrder      08103D68 gmpSetReturnOrder
    08103D7C gmpEndJingle       08103DDC gmpSkipPattern     08103DE8 gmpPause
    08103DFC gmpPauseAfterJingle 08103E08 gmpResume         08103E1C gmpClearChannels
    08103E50 gmpMixNext         08103EA4 gmpProcessRow      08103F98 gmpMixChannelC
    08104014 gmpMixChannelC32   0810408C gmpMix             08104214 gmpPlayNote
    0810429C gmpLoadSfxBank     081042C0 gmpPlaySfx         08104354 gmpStopSfx
    0810437C fxVolumeSlide      081043C0 fxTonePorta        08104430 fxVibrato
    08104468 gmpProcessTick     081045C4 gmpRowEffects
    ARM:  08104980 gmpDmaRestartAB 081049C0 gmpCallR3       081049E4 gmpMixChannel

v3  08135C84 gmpLinearFreq_     08135CC8 gmpNoteToLinear    08135D28 gmpUpdateLinearStep
    08135D5C gmpWaitLine        08135D6C gmpWaitLineLeave   08135D7C gmpStartDma
    08135EC4 gmpStop            08135F60 gmpRequestSong     08135F74 gmpServiceSongRequest
    08135FB8 gmpCopySfxChannels 08135FF0 gmpServiceJingle   08136090 gmpClearBuffers
    081360CC gmpSoundOn         081360D8 gmpSetMasterVolume 081360EC gmpSetMusicVolume
    08136100 gmpSetSfxVolume    08136114 gmpSetRate         08136130 gmpDmaRestart
    0813615C gmpApplyRate       08136234 gmpTestTone        0813629C gmpFrame
    081363C4 gmpFlip            08136400 gmpIwramAlloc      08136434 gmpSetupIwram
    081364D4 gmpRle8Next        08136500 gmpRle16Next       08136544 gmpUnpackMixer
    08136578 gmpLoadModule      08136638 gmpLoadSampleBank  081366B0 gmpLoadSfxBank
    081366E8 gmpInit            0813686C gmpGetRow          08136878 gmpGetOrder
    08136884 gmpGetLoopCount    08136890 gmpStartSong       08136994 gmpPlayJingle
    081369EC gmpPlayJingleOnBeat 08136A48 gmpEndJingle      08136A70 gmpEndJingle2
    08136A98 gmpSkipPattern     08136AA8 gmpPause           08136AC0 gmpSetFlag10
    08136AD0 gmpResume          08136AE8 gmpSilenceMusic    08136B38 gmpGetChannelVolume
    08136B68 gmpDecodeRow       08136C2C gmpProcessRow      08136D28 gmpSetLoop
    08136D3C gmpMix             0813711C gmpEchoInit        08137188 gmpSetEcho
    0813719C gmpApplyEcho       08137260 gmpMixSfx          081372F4 gmpPlaySfxAuto
    08137514 gmpPlaySfx         08137620 gmpSetSfx          08137664 gmpStopSfx
    08137694 gmpClearSfxVol     081376C0 gmpSfxPlaying      081376F4 fxVolumeSlide
    0813773C fxTonePorta        08137868 fxVibrato          08137908 fxPortaDownLin
    0813796C fxPortaUpLin       081379D0 fxVolumeColumn     081379E0 gmpProcessTick
    08137C8C gmpGetBPM          08137C98 gmpSetBPM          08137CE0 gmpRowEffects
    081381E8 gmpDeadTempoLoop
    ARM:  08141300 swiDiv/swiDivArm/swiMod/swiModArm 08141320 gmpDmaRestartAB 08141360 gmpCallR3
          08141370 gmpDmaRestartA 081413A0 gmpDmaRestartB 081413D0 gmpDmaRestartCur
          08141428 gmpMixerMonoOld 081414CC gmpWaitVCountLeave 081414DA gmpWaitVCount
          081414F0 gmpRleFill   08141584 swiLZ77UnCompWram/Vram
          0814158C gmpMixerMonoLZ 08141634 gmpMixerMultiLZ
```

## Appendix B: deliverables

One folder per version (`v1_Pinball`, `v2_Aero`, `v3_NFSU2`):

| File | Contents |
|---|---|
| `gbamodN_player.s` | labelled, commented Thumb source of the player, with a pseudo-C header on every function |
| `gbamodN_arm.s` | the ARM module (mixers, veneers, DMA restart) |
| `gbamod1_host.s` | (v1) Pinball's DMA-start and sound on/off glue |
| `gbamod3_mixer_mono.s`, `gbamod3_mixer_multi.s` + `.lz` | (v3) sources of the two packed mixers and the packed images |
| `gbamodN_rodata.s` | constant tables (sine, periods, step tables, rate tables, switch tables) |
| `gbamodN_data.s` | all modules and banks as macros (`R`/`CELL` rows for v1/v2; `N`/`V`/`X` RLE runs for v3; `SFX`/`SMP` entries) |
| `*.bin` | PCM pulled in with `.incbin` (v1 per module; v2/v3 sample and SFX banks) |
| `gbamodN.ld`, `gbamodN.mk`, `romcheck.py` (+ `lz77check.py`) | link at the original addresses and compare |
| `gbamodN_data_dump.txt` | human-readable decode of every module, bank and SFX (v3 includes every pattern) |
| `gbamodN_wav.zip` | every sample and SFX as WAV |

`make -f gbamodN.mk check ROM="<rom file>"` with `arm-none-eabi-as/ld/objcopy`
(`-mcpu=arm7tdmi`) rebuilds every range listed in §3. All 18 ranges have been checked to be
**byte-identical** to the ROMs, and v3's two mixer sources assemble to exactly the bytes the BIOS
LZ77 decoder unpacks from the ROM images.
