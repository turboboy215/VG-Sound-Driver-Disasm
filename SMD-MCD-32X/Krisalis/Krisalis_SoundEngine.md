# Krisalis Mega Drive Sound Engine (Shaun Hollingworth)

Games covered (folder `Kris/`):

| Game | ROM | Z80 driver | 68k module |
|---|---|---|---|
| Chuck Rock (E) | `Chuck Rock (E) [c][!].bin` | revision 1 | revision 1 |
| Sensible Soccer (E) (M4) | `Sensible Soccer (E) (M4) [!].bin` | revision 2 | revision 2 |
| Boogerman (E) | `Boogerman (E) [!].bin` | revision 3 | revision 3 |
| Mickey Mania (E) | `Mickey Mania - Timeless Adventures of Mickey Mouse (E) [!].bin` | revision 3 (byte-identical to Boogerman's) | revision 3 |

All four games run the same design. The **68k is the sequencer**: once per frame it reads the patterns and sends the Z80 either a whole row of six pattern cells or a "tick". The **Z80 is a player**: it turns cells into YM2612 writes and plays one 8-bit PCM channel on FM6. The music data is a tracker module (sample table, pattern pointer table, order list, single-channel 64-row patterns), clearly descended from Krisalis' Amiga tracker tools.

Files that go with this document:

| File | Contents |
|---|---|
| `Kris_Z80_rev1_ChuckRock.asm`, `Kris_Z80_rev2_SensibleSoccer.asm`, `Kris_Z80_rev3_Boogerman_MickeyMania.asm` | Labelled, commented Z80 drivers (z80dasm-style syntax). Each reassembles byte-for-byte with `z80asm`; rev 3 matches both Boogerman's and Mickey Mania's copies. |
| `ChuckRock_68k_sound.asm`, `SensibleSoccer_68k_sound.asm`, `Boogerman_68k_sound.asm`, `MickeyMania_68k_sound.asm` | Labelled, commented 68k sound modules (asm68k/vasm syntax, RAM and module addresses as equates). Each reassembles byte-for-byte with `vasmm68k_mot -Fbin -no-opt`, including the driver `incbin`. |
| `*_Z80.bin` | The $1400-byte driver images exactly as the 68k uploads them (used by the `incbin`). |
| `*_SoundData.txt` | Per game: module layout, sample table with rates, all 64 voices decoded, the whole order list, playback flow of every song/jingle/SFX sequence (positions, loop point, length), and every pattern decoded cell by cell. |
| `samples/*.wav` | Every module sample (`<game>_smpN.wav`) and every extra sample (`bm_extNN.wav`, `mm_extNN.wav`), converted signed → unsigned and written at the PAL playback rate. |
| `tools/` | The Python tools that produced everything (see §9). |

---

## 1. Revisions at a glance

| | Rev 1 (Chuck Rock) | Rev 2 (Sensible Soccer) | Rev 3 (Boogerman, Mickey Mania) |
|---|---|---|---|
| Z80 driver size | $694 | $A97 | $C64 |
| Mailbox | $0E58 | $0F58 | $0FAC |
| PCM bank | fixed by the boot stub (bank 2) | per sample: music bank / SFX bank | same as rev 2 |
| DAC player | writes a byte every poll, pointer += rate/256 | writes a byte on each phase carry | same as rev 2, but polled from everywhere |
| DAC during a row | stalls (~12 ms) | stalls (~13.5 ms) | keeps playing |
| Volume / fades | – | music + jingle attenuation | same |
| Cell commands | $7D | $7A porta, $7B pan, $7C FMS, $7D | same |
| Sample start/end | whole sample | skips first 8 and last 4 bytes | same |
| 50/60 Hz | `Snd_NTSCAdjust` (+1) added to `$7D` speeds | skip every 6th frame on NTSC | same |
| 68k entry | direct calls | direct calls | jump table, 20 functions |
| Extra PCM | – | (path present, unused) | `Snd_PlaySampleAddr` / `Snd_PlayExtSample` |

---

## 2. Start-up and the Z80 side

### 2.1 Boot

`Snd_Init` resets the Z80 and copies a 27-byte **boot stub** to Z80 $0000. The stub writes a 9-bit bank number (the word the 68k pokes at stub offset 6) to the bank register $6000, writes $FF to $1000 and loops. The 68k waits for $1000 ≠ 0, then copies **$1400 bytes** of driver to Z80 **$0C00** (only $694/$A97/$C64 bytes are real code; the rest is whatever followed it in ROM), patches $0000 = `di / jp $0C00` and resets the Z80 again.

* Rev 1 passes bank **2** in the stub. That bank is never changed again, so all Chuck Rock samples live in $010000–$017FFF.
* Rev 2/3 pass 0 and set the bank for every sample instead.

The driver copies its RST handlers (YM busy waits) to $0008, `ei/ret` to $0038 and `nop / jp $0C00 / dw mailbox` to $0000. The 68k reads the **mailbox address from Z80 $0004/$0005**. Interrupts are not used. The YM is initialised with reg $22 = $0C (LFO on, 6.02 Hz) and reg $27 = 0. Timers are not used.

### 2.2 Z80 memory map

| Z80 | Rev 1 | Rev 2 | Rev 3 |
|---|---|---|---|
| $0000–$003F | vectors / RST busy-wait helpers | same | same (+ RST $18 DAC helper, unused) |
| $0400–$0BFF | voice bank, 64 × 32 bytes (uploaded by the 68k) | same | same |
| $0C00– | driver code | | |
| silent voice | $0C87 | $0D48 | $0D9C |
| register table | $0CA7 (6 × 32 × (port,reg)) | $0D68 | $0DBC |
| channel state | $0E27 (6 × 7) | $0EE8 (6 × 14) | $0F3C (6 × 14) |
| mailbox | $0E58–$0E91 | $0F58–$0F9E | $0FAC–$0FF2 |
| note table | $11D0 | $15CF | $179F |
| end of real code | $1294 | $1697 | $1863 |
| $1000 | "alive" flag of the boot stub | | |
| $8000–$FFFF | 32 KB ROM bank window | | |
| stack | $1FFF down | | |

### 2.3 Mailbox (offsets from the mailbox address)

| Off | Meaning | Rev |
|---|---|---|
| +00 | **command** from the 68k; the Z80 clears it when done (the 68k waits for 0 before writing another) | all |
| +01 | jingle state: 0 none, $FF jingle on FM5 (68k), $FE jingle voice loaded (Z80, rev 2/3) | all |
| +02…+0D | six pattern cells (lo,hi) for FM1–FM6; during a jingle the FM5 cell is the jingle's | all |
| +0E / +0F | upper voice bank flag for music / jingle (`$7D` bit 7) | all |
| +10/11 | SFX sample address, $8000 \| offset in bank (little-endian) | all |
| +12 | rate byte; +13 = initial phase (never written) | all |
| +14/15 | length (little-endian) | all |
| +16 | **trigger**: non-zero starts the SFX sample from the Z80 wait loop | all |
| +18…+37 | the module's 8-entry sample table (big-endian addr, len) | all |
| +38 | SFX sample busy ($FF), read back by the 68k | all |
| +3A / +3C | music / jingle attenuation (added to carrier TLs) | 2, 3 |
| +3E / +40 | SFX sample pan / jingle pan (0 = default) | 2, 3 |
| +42 / +44 | ROM bank of the SFX sample / of the music samples | 2, 3 |
| +46 | last jingle state (Z80 private) | 2, 3 |

### 2.4 Commands (+00)

| Cmd | Action |
|---|---|
| 1 | Tick: run the per-frame pitch slides / portamento |
| 2 | Reset channel state (slides off, pitch "no key", voices invalid); FM5 is left alone during a jingle |
| 3 | Load voice +02 on channel +03 (not used by any of the 68k modules) |
| 4 | Silence: silent voice on every channel (not FM5 during a jingle), stop a music sample, music volume = 0 (rev 2/3) |
| 7 | Reload every channel's voice (end of pause) |
| any other ($0A) | New row: process the six cells, then do a tick |

### 2.5 Channel state

Rev 1, 7 bytes: +0/1 slide step, +2/3 pitch (block<<11 \| F-num, bit 14 = key on), +4 voice.

Rev 2/3, 14 bytes:

* +0/1 slide step
* +2/3 current pitch
* +4/5 portamento target
* +6 portamento speed
* +8 voice
* +9 voice in the YM (rev 3 only; avoids reloading the same voice)
* +B FMS override
* +C pan override
* +D re-trigger flag

### 2.6 Voices

32 bytes per voice, 26 registers written in register-table order:

```
+00..03 $30 DT/MUL   +04..07 $40 TL   +08..0B $50 KS/AR   +0C..0F $60 AM/D1R
+10..13 $70 D2R      +14..17 $80 D1L/RR      (operator order 1,3,2,4)
+18 $B0 FB/ALG       +19 $B4 pan/AMS/FMS     +1A scratch (rev 2/3)   +1B..1F unused
```

SSG-EG is never written: the register list has entries for $90–$9C, but only 26 are used.

* **Volume** (rev 2/3): the attenuation is added to the TL of the carriers of the voice's algorithm and clamped at $7F.
* **Fades**: while the music volume is non-zero, the main loop rewrites the TLs after every command. Music drums are dropped while the volume is non-zero, so drums stop during fades.
* **Pan / FMS overrides**: these patch the copy of byte $19 that is written to $B4.

### 2.7 PCM (FM6 / DAC)

Samples are **signed 8-bit**; the Z80 adds $80 to each byte before writing it to reg $2A. The player state lives in the alternate registers: HL' = pointer, BC' = bytes left, and the rate/phase pair is in DE'.

* **Rev 1**: every poll of the idle loop writes the current byte and adds the rate to an 8-bit phase. When the integer part changes, the pointer advances. The DAC is therefore written at a constant ~12.3 kHz and the sample advances by rate/256 per write.
* **Rev 2/3**: phase += rate; a byte is written only on carry. Rev 2 polls only in the wait loop. Rev 3 polls after almost every instruction group of the driver (`exx / ld a,b / or c / call nz,DAC_Poll / exx`), so samples keep playing while voices are loaded.

Effective playback rate for rate byte *r* (idle loop, Z80 clock F = 3 546 895 Hz PAL / 3 579 545 Hz NTSC, p = r/256):

| Rev | Formula | $40 | $60 | $80 | $C0 | $FF (PAL) |
|---|---|---|---|---|---|---|
| 1 | p·F / (284 + 7p) | 3103 | 4641 | 6169 | 9197 | 12142 |
| 2 | p·F / (152 + 72p) | 5216 | 7431 | 9433 | 12913 | 15792 |
| 3 | p·F / (112 + 72p) | 6821 | 9569 | 11983 | 16025 | 19231 |

These were checked by running each driver in a Z80 emulator, which gave the same intervals (for example, rev 3 with r = $60 measured 9571 Hz). The emulator also measured a row with six voice changes:

| Rev | DAC during that row |
|---|---|
| 1 | silent for 12.0 ms |
| 2 | silent for 13.5 ms |
| 3 | longest gap 0.18 ms, at a lower average rate |

These measurements leave out the YM busy flag and the 68k's bus holds, so real hardware is slightly slower.

Other DAC details:

* **FM6 pan**: when a sample starts, the Z80 sets FM6's pan to L+R (or the SFX pan) and restores the voice's pan when the sample ends. To stop a voice load from overwriting it in the meantime:
  * rev 1/2 rewrite the pan on every poll;
  * rev 3 patches the FM6 `$B6` entry of the register table to `$28`, a write that lands on an unused part-II register.
* **Priority**: an SFX sample sets +38 busy, and music drums are ignored until it ends. A note (FM) on FM6 cuts a *music* sample, but not an SFX sample.
* **Banks** (rev 2/3): before each sample, `SetBank` writes A15–A22 serially to $6000, using +44 for music drums and +42 for SFX samples. A sample must not cross a 32 KB boundary; none do.

---

## 3. Module format

The module is a block in ROM whose layout is identical in all four games. Its address is compiled into the 68k code.

```
+$000  8 x (offset.w, length.w)   sample table, offsets inside ONE 32 KB ROM bank
+$020  word  order-format flag:   $FFFF = word order entries, $0000 = BYTE entries
+$022  long x N                   pattern pointers (N = (orders - (base+$22)) / 4)
orders 6 entries per row          pattern numbers for FM1..FM6 (bytes or words)
...    patterns
voices 64 x 32 bytes              uploaded to Z80 $0400 ($800 bytes)
```

| Game | Module | Flag | Patterns | Order rows | Voices | Sample bank |
|---|---|---|---|---|---|---|
| Chuck Rock | $018000 | $FFFF (words) | 384 (170 distinct) | 256 | $01BD64 | 2 ($010000–$017FFF) |
| Sensible Soccer | $075BFE | **$0000 (bytes)** | 99 | 54 | $077390 | $0F ($078000–$07FFFF) |
| Boogerman | $028000 | $FFFF | 426 | 150 | $02F85A | 4 ($020000–$027FFF) |
| Mickey Mania | $1D8000 | $FFFF | 511 | 237 | $1DFE06 | $3A ($1D0000–$1D7FFF) |

### 3.1 Patterns

A pattern is **one channel × 64 rows**, stored as 2-byte cells `lo, hi`:

* `lo, $FF` means `lo`+1 empty rows: run-length compression. The 68k keeps a "rows skipped" counter so that row *r* is read at `pattern + 2·(r − skipped)`.
* `$00 $00` is an explicit empty cell.
* Otherwise the cell word `hi:lo` holds three fields:

```
hi bits 7-1   N  note / command
hi bit 0 + lo bits 7-4   I  instrument 1-31 (0 = keep); voice I-1, or I-1+32 after "$7D" with bit 7 set
lo bits 3-0   E  pitch slide per tick: bits 0-2 magnitude, bit 3 = down
```

| N | Meaning |
|---|---|
| 0 | no note (instrument and/or slide only). **`--- 31` = note cut**: voice 30 (and 62) is all-TL-127 in every game. |
| 1–$6C | note; N=3 is C-0 (block 0, F-num $28D); 12 per octave, table up to N=97. A note keys off then on. In rev 2/3, a note on the same instrument while portamento is active glides without a re-trigger (legato). |
| $6D–$74 | **drum sample** N−$6D (0–7) on FM6; `lo` = rate byte. Ignored on other channels. |
| $75–$79 | ignored |
| $7A | (rev 2/3) portamento speed = `lo` (F-number units per tick, 0 = off) |
| $7B | (rev 2/3) pan override `lo&3`: 1 R, 2 L, 3 LR, 0 = voice |
| $7C | (rev 2/3) FMS override `lo&7` (LFO vibrato depth, LFO = 6.02 Hz) |
| $7D | speed = `lo & $7F` (68k); bit 7 selects voices 32–63 (Z80) |
| $7E | jump to order position `lo` after this row (see §4 for jingles/SFX) |
| $7F | pattern break: go to the next order position after this row |

**Slide**: step = ±(E&7)·4 F-number units. Rev 1 adds it once per tick with no block wrap; rev 2/3 add twice the step per tick and wrap the F-number between $269 and $4D0, adjusting the block.

**Note table** (identical in every revision): $0269, $028D, $02B4, $02DD, $0309, $0337, $0368, $039C, $03D3, $040D, $044B, $048C for each block (N = 2…13 in block 0). It is tuned for PAL: C-4 = 263.0 Hz, about +9 cents.

---

## 4. The 68k sequencer

A "song number" is simply an **order position**. Three independent readers use the same order list.

**Music** (`Snd_PlayMusic(pos)`) reads all 6 columns.

* Speed defaults to 6: a row every speed+1 = 7 frames.
* `$7E x` → position x; `$7F` → next position.
* At the end of the 64 rows, play continues with the next position.
* Position 0 means "music off" in every game; it cuts the notes. In rev 2/3, position 0 then jumps to position 1, whose rows are never sent (ticks below position 2 and rows at position 1 are skipped). In Chuck Rock, position 0 loops on itself and position 1 is the title tune.

**Jingle** (`Snd_PlayJingle(pos)`) reads **column 4 only** and plays it on FM5.

* While it plays, the music's FM5 cells are muted, but their commands still run.
* The jingle has its own speed (initially 0 = a row every frame, 1 in rev 1) and its own volume and pan.
* It ends with **`$7E 00`**, which wraps the position to 0. FM5's music instrument is then forced back.
* `Snd_PlayMusic` also stops a jingle.

**SFX sequence** (`Snd_PlaySFXSeq(pos)`) reads **column 5 only** and plays only its drum-sample cells as SFX samples.

* Speed is 1.
* The position is stored +1, so **`$7E x` goes to position x−1** and `$7E 00` ends the sequence.
* At the end, rev 1/2 cut the sample by "playing" one byte at Z80 $0000; rev 3 clears the busy flag.

Each frame, `Snd_Update` does the following:

1. Rev 2/3 only: skip every 6th frame on 60 Hz consoles. Sensible Soccer can also skip every 6th frame for `Snd_SlowMode`.
2. Handle a pause/resume request.
3. Start a requested jingle or music.
4. Advance the SFX sequence and send a pending direct sample.
5. Advance the music. On a music row, the jingle row (if any) replaces the FM5 cell and **command $0A** is sent. On other frames, a jingle-only row is sent if the jingle advanced (the other cells are cleared so nothing re-triggers); otherwise **command 1** (tick).

Rev 2/3 skip a row when all six cells are empty and no jingle plays.

`Snd_Pause` silences the Z80 (cmd 4) and keeps the jingle state; `Snd_Resume` sends cmd 7. Both act on the next update.

Reader structure (12 bytes per reader):

* +0 rows skipped
* +2 empty rows left
* +4/5 cell to send
* +6 last instrument·8
* +8 "force instrument": after a jingle, the next FM5 note gets its instrument re-inserted
* +A muted

### 4.1 Chuck Rock specifics (rev 1)

* Every row and every tick is sent; there are no 50/60 Hz frame skips.
* Speed compensation for 60 Hz comes from the game instead:
  * the game stores `1 − (VDP status bit 0)` in `Snd_NTSCAdjust` ($FFFF000E), so it is 1 on NTSC;
  * `$7D` speeds become `lo + Snd_NTSCAdjust − Game_SpeedOffset` ($FFFF0002, normally 0);
  * the default 6 at song start is only reduced by `Game_SpeedOffset`.
* No volume, pan or bank fields.

---

## 5. 68k entry points

### Chuck Rock (code $01C54E–$01CEA1, RAM $FFFF0008)

| Routine | Addr | Notes |
|---|---|---|
| Snd_Init | $01C57C | called from $32C |
| Snd_Update | $01C62C | VBlank ($CC4) |
| Snd_PlayMusic (d0 = position) | $01C5DA | |
| Snd_PlayJingle | $01C5F2 | |
| Snd_PlaySFXSeq | $01C60A | |
| Snd_Pause / Snd_Resume | $01C54E / $01C55E | no callers found |
| Snd_PlaySampleAddr | $01CC60 | no callers |
| LevelMusicTable | $01C544 | positions $16, $1F, $29, $32, $39 for levels 1–5 |
| game sound table | $01EB58 / $01EB7B | 35 sounds; position byte + flag (0 = jingle, 1 = SFX sequence) |

### Sensible Soccer (code $06D982–$06E4E1, RAM $FFFEFE)

| Routine | Addr |
|---|---|
| Snd_IsJinglePlaying | $06D982 |
| Snd_IsSFXSamplePlaying | $06D98A |
| Snd_Pause | $06D992 |
| Snd_Resume | $06D9A2 |
| Snd_Init | $06D9C0 |
| Snd_PlayMusic | $06DA40 |
| Snd_PlayJingle | $06DA6E |
| Snd_PlaySFXSeq | $06DA86 |
| Snd_Update | $06DAA8 |
| Snd_StopZ80 / Snd_StartZ80 | $06E306 / $06E32E |
| Snd_WaitZ80 | $06E4A4 |

`Snd_SlowMode` ($FFFF08) is set by the game before position 2.

### Boogerman ($098000, RAM $FF051A) and Mickey Mania ($1E05E6, RAM $FFF98C)

`moveq #fn,d7 / jsr Sound_Dispatch`. Mickey Mania mostly calls the functions directly.

| fn | Function | Boogerman | Mickey Mania |
|---|---|---|---|
| 0 | Snd_Update | $0981CE | $1E076C |
| 1 | Snd_PlayMusic(d0) | $09816C | $1E0720 |
| 2 | Snd_PlayJingle(d0) | $098194 | $1E0740 |
| 3 | Snd_PlaySFXSeq(d0) | $0981AC | $1E0752 |
| 4 / 5 | Snd_Pause / Snd_Resume | $0980C0 / $0980D0 | $1E068E / $1E069A |
| 6 | Snd_PlaySampleAddr(d0 = ROM addr, d1 = rate, d2 = len) | $098884 | $1E0D18 |
| 7 / 8 | IsJinglePlaying / IsSFXSamplePlaying | $0980B0 / $0980B8 | $1E0682 / $1E0688 |
| 9 / 10 | Music / jingle volume (d0, $FF = read) | $098080 / $098098 | $1E065A / $1E066E |
| 11–13 | Get music / jingle / SFX position (d0 = pos, d1 = row) | $098056… | $1E063C… |
| 14 / 15 | Stop / start Z80 | $098A10 / $098A30 | $1E0E86 / $1E0EA4 |
| 16 / 17 | Jingle pan / SFX pan | $098B6C / $098B84 | $1E0FBC / $1E0FD2 |
| 18 | Snd_Init | $0980EE | $1E06B0 |
| 19 | Snd_PlayExtSample(d0 = number, d1 = rate) | $098166 → $098BB8 | $1E071A → $1E0FE8 |
| – | Snd_CutSample(d1) (2 silent bytes) | $098B9C | – |

---

## 6. The extra PCM banks (Boogerman, Mickey Mania)

The 8-entry module table only holds **16-bit offsets into one 32 KB bank**: the drum bank, which the 68k writes to mailbox +44. Rev 3 adds a second path that can play **any** ROM sample.

**`Snd_PlaySampleAddr`** (function 6):

1. It takes a full 24-bit ROM address and computes:
   * the bank = address >> 15;
   * the window address = $8000 \| (address & $7FFF).
2. It stores these, with the rate and length, as a *pending sample* (`Snd_PendRate/Len/Addr/Bank`).
3. On the next `Snd_Update`, the pending sample is sent:
   * the bank goes to mailbox **+42**;
   * address, rate and length go to +10…+15;
   * trigger +16 = $FF, and the SFX sequence is stopped.
4. The Z80 starts the sample from its wait loop. It selects the bank with 9 writes to $6000, plays the sample at the SFX pan, and keeps music drums off until the sample ends.

**`Snd_PlayExtSample`** (function 19) looks the number up in a table of `(offset.l, length.w)` relative to a base and calls function 6.

| | Boogerman | Mickey Mania |
|---|---|---|
| Table | $098BE6, 53 entries | $1E1016, 11 entries |
| Base | $038000 | $1C8000 |
| Data | $038000–$096A07, banks $07–$12, 1–3 samples per bank | $1C8000–$1CF6F9, all in bank $39 |
| Rate | from the game's sound-event byte: normally $50 (≈ 8.2 kHz); also $18, $30, $40, $60 | $60 (≈ 9.6 kHz); $40 for #6 |

Boogerman's sound events are inline `(type, value)` pairs after `jsr $6FB8`:

* type 0: music
* type 1: jingle
* type 2: SFX sequence
* types 3/4: pause / resume
* type ≥ 5: extra sample `value` at rate `type`, unless the option byte $FF0264 is not $50, in which case it overrides the rate

Both tables are listed in the data files and exported as `bm_extNN.wav` / `mm_extNN.wav`. Sensible Soccer (rev 2) already has the pending-sample path and the bank fields, but nothing in the game sets it, so all of its samples come from bank $0F.

---

## 7. Sensible Soccer's track index

1. **Byte order entries.** The order-format flag at module+$20 ($075C1E) is **$0000**, so each order row is **6 bytes**. The other three games use $FFFF and 12-byte rows of words. The 68k reads the flag at run time (`tst.w Mod_OrderFlag`): it doubles the position before multiplying by 6 and switches between `move.b (a0)+` and `move.w (a0)+`. The jingle/SFX column offsets also switch, from +4/+5 to +8/+10. A ripper that assumes words reads Sensible Soccer's list as $0102, $0203, … and gets nonsense.
2. **The index is an order position.** It is not a table index:
   * music 0 (silence), 2 (main theme), $0F, $2D;
   * jingles $0E, $14, $17, $18;
   * SFX sequences $15, $16, $34, $35.

   These are passed directly by the game code at $4786–$4A32.
3. **`Snd_SlowMode`** ($FFFF08), set by the game only before `Snd_PlayMusic(2)`, drops every 6th update. That position plays at 5/6 speed: about 63 s per loop instead of 52.5 s.
4. Unlike the others, the module is not bank-aligned:
   * it sits at $075BFE;
   * its samples are in the following bank, $0F;
   * it is only 54 rows long.

---

## 8. Songs found

The data files hold full lists with positions, loop points and lengths. The table gives the order positions called by the game code.

| Game | Music | Jingles | SFX sequences |
|---|---|---|---|
| Chuck Rock | 0 off, 1 title, $16/$1F/$29/$32/$39 levels 1–5 | 15 rows in 228–250 (from the 35-entry sound table) | 7 rows in 234–254 |
| Sensible Soccer | 0, 2, $0F, $2D | $0E, $14, $17, $18 | $15, $16, $34, $35 |
| Boogerman | 0, 23, 75, 113 (events) + 13 level tunes selected through level data ($FF0A55) | 21 from the event table (115–148) | none used |
| Mickey Mania | 24 from the sound-test table $025842 + level table $0184FA | 36 (sound test $025872) | 5 (189–193) |

---

## 9. Tools

All in `tools/` (Python 3; needs `z80dis` and `capstone` from pip):

| Command | What it does |
|---|---|
| `python3 krisalis.py <rom> cr\|ss\|bm\|mm <outdir>` | Writes the data dump and WAVs; standalone. |
| `python3 make_all.py` | Regenerates every listing, dump and WAV in the Kris folder, using the four ROMs there under their original names (`roms.py`). |
| `zdis.py` / `mdis.py` | Recursive-descent Z80 / 68000 disassemblers. |
| `z80_v1.py`, `z80_v2.py`, `z80_v3.py`, `m68k_*.py` | Label and comment tables. Rev 2 and the Mickey Mania / Sensible Soccer / Chuck Rock 68k tables are carried over from the Boogerman ones by instruction alignment (`mapz80.py`, `map68k.py`) and then corrected by hand. |
| `z80sim.py` | Runs a driver in an emulator (pip `z80`) to measure DAC timing. |

Verification:

* All three Z80 listings reassemble byte-identically with `z80asm`.
* All four 68k listings reassemble byte-identically with `vasmm68k_mot -Fbin -m68000 -no-opt`.
