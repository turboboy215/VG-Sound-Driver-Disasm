# McDonaldLand (E) / M.C. Kids: Charles Deenen sound engine

Source ROM: `McDonaldLand (E) [!].nes` (MMC3, 128 KB PRG, 128 KB CHR, PRG-RAM enabled).
Disassembly: `disasm\mcdonaldland_sound.s` (ca65). It reassembles byte-identical: run `disasm\build.bat` (needs ca65/ld65 and Python on PATH).
Generator and helper scripts are in `disasm\tool\`:
- `gen_disasm.py` regenerates the .s and .cfg from the ROM.
- `verify.py` assembles the source and compares it with the ROM.
- `m6502.py` is the tracer.
- `sim.py` is a py65 harness that runs the driver itself.
- `check_bugs.py` reproduces the two bugs described below.

| | |
|---|---|
| Code | PRG bank 10, $807A-$870F (1,686 bytes, including 14 bytes of dead code) |
| Tables + data | bank 10 $8000-$8079 and $8710-$9C36; bank 4 $A000-$B41C |
| Channels | 4 music tracks (Sq1, Sq2, Tri, Noise) + 1 SFX track that takes over one hardware channel |
| Songs / SFX | 14 / 26 |
| Tracks | 81 slots (79 used, $4B and $4C are null) |
| Patterns | 131 (pointer $7F is unused) + 14 orphaned DMC patterns |
| Instruments | 32 music (26 used) + 22 SFX (21 used) |
| Envelopes | 15 volume, 11 duty, 33 music pitch, 16 SFX pitch |

## Banking and game interface
The game maps bank 10 at $8000 (MMC3 R6) and bank 4 at $A000 (R7) before every call. The game uses $8000 bit 7 (CHR inversion) and keeps bit 6 = 0. The driver writes `$80` to $A001 on every entry because its state lives in PRG-RAM.

| Address | Routine | Input |
|---|---|---|
| $807A | Music_Play | Y = song. Calls Sound_Init first, which also kills the running SFX, then Chan_Start for each non-$FF entry of the 5 song columns. |
| $80C8 | Sound_Init | Clears $A7-$FB, $07A0-$07C8 and $7F4C-$7FBE, silences the APU and sets $4015 = $0F. |
| $81A5 | Sfx_Play | X = effect. X >= $7F cancels the effect (Sfx_Cancel). |
| $8237 | Sound_Update | Once per frame. |

Game side (fixed bank 14):
- `$C7DD` plays song Y unless it equals the current song ($0322). It clears the NMI flag $FB around the call.
- `$C830` runs once per frame. It takes the request in $0321 ($FF = none) and checks a priority table at $C817. That table has 25 bytes: all $08, except entry 14 = $10. Effect 25 reads the next code byte ($48) as its priority. The routine also does `CPX $80` (a zero-page compare) before the priority test.
- `$C885` is called from NMI and runs Sound_Update when $FB is nonzero.
- `$C7BA` (stop everything) has no direct JSR.

## Timing
Each channel has its own speed byte (from the track table), `$hl`:
- A tick happens every h+1 frames.
- When l > 0, every l+1 frames the tick counter is held for one frame. If the counter is at 0 when it is held, that frame ticks again.
- Every speed in the game has l as a multiple of h+1, so the hold always lands on a tick and adds one.
- Result: (l/(h+1) + 1) ticks per l+1 frames.

| Speed | Frames per tick |
|---|---|
| $00 | 1 |
| $10 | 2 |
| $12 | 1.5 |
| $14 | 1.67 |
| $18 | 1.8 |
| $23 | 2 |
| $29 | 2.5 |

These values were checked against the emulated driver.

On a tick, `chTicksLeft` is decremented. When it underflows, the next pattern event is read.

## Track format (TrackTbl at $89D5: 81 x {word pointer, speed byte})
| Byte | Meaning |
|---|---|
| $00-$9F | Pattern number |
| $A0-$FD | Transpose = byte - $A0, for the following patterns |
| $FE | Stop the channel |
| $FF | Loop to the start of the track |

- Tone tracks normally start with $A7 (+7); noise tracks start with $A0.
- A track has no speed or transpose state of its own beyond these bytes.

## Pattern format (PatPtrLo/Hi at $88A1/$8925, 132 entries)
One event, in the order the parser checks it:

`[$FE legato] [$FC vol] ( $E0-$FB rest | [$C0+i instrument] [$80+n duration] [$60+e pitch env] note )`

- **$00-$5E**: note (C2 = 0). The track transpose is added to it. The period table covers C2-G#7 (69 entries). The note lasts the current duration.
- **$80-$BF**: duration = n ticks for all following notes ($80 = 256).
- **$E0-$FB**: rest of n ticks ($E0 = 256). Pulse and noise get volume 0; the triangle gets $4008 = $80.
- **$C0-$DF**: instrument. This also selects the instrument's pitch envelope (chPEnvSel bit 7 set).
- **$60-$7F**: explicit pitch envelope e for this and later notes (e = 0 means none). It forces the envelope to restart.
- **$FC v**: volume 0-15. It picks a row of VolTable, so the envelope value is scaled by v/15.
- **$FD target, delay, speed**: portamento.
  - It can come first, or right after a duration byte. A note always follows it.
  - Once `delay` ticks of the note have passed, the period moves toward the target by 7 << (speed-1) each frame, then snaps to it.
  - While it slides, the pitch envelope and vibrato are suspended.
- **$FE**: legato. The pitch envelope is not restarted on the next note, unless a $60+ byte is also present.
- **$FF**: end of pattern. The next track entry is read.

The parser only looks for each prefix at its fixed place in this chain, so a misplaced byte is taken for whatever the next check expects:
- After an instrument, any byte >= $80 is a duration.
- After `VOL`, any byte >= $E0 (including $FC-$FF) is a rest.
- After a duration, any byte >= $60 is a pitch-envelope selector.

Pat_0B and Pat_10 (song 1, Sq1) contain `$FE $84 $FE $1D`: LEGATO, DUR 4, then a second $FE. The parser reads that second $FE as pitch-envelope selector $9E. That still means "use the instrument's envelope", but it forces a restart, so the legato does nothing.

## Instruments (6 bytes; InstrTbl $901E, SfxInstrTbl $8DF9)
| Byte | Meaning |
|---|---|
| 0 | Duty bits. Reg0 = $30 EOR byte 0, so constant volume and length halt are set. Not used for the triangle. |
| 1 | Duty envelope number (pulse only; 0 = none) |
| 2 | Volume envelope number (not for the triangle) |
| 3 | Pitch envelope number |
| 4 | Vibrato: bits 0-2 speed, bits 4-6 depth shift |
| 5 | Bits 4-7: vibrato delay in ticks since note start |

All envelope numbers are 1-based.

## Envelopes
Shared byte codes: $FD = set loop point here, $FE = hold, $FF = jump to the loop point (the start if none is set).

- **Volume** (VolEnvOfs $8C10 + VolEnvData $8C1F): values 0-15, one per frame, scaled through VolTable.
- **Duty** (DutyEnvOfs $8D4E + DutyEnvData $8D59): values $00/$40/$80, which replace reg0 bits 7-6.
- Both tables store 8-bit offsets, so a position wraps at 256.
- **Pitch / arpeggio** (music: PEnvPtrLo/Hi $8AC8/$8AE9; SFX: $8E7D/$8E8D): word pointers.
  - A value < $80 is a semitone offset from the note.
  - $80 | n is the absolute note n. The noise channel uses this to pick drum sounds.
  - The envelope writes the period directly, every frame.
  - Pitch envelope 31 and 32 share one pointer. SFX envelope 5 is the last 3 bytes of envelope 4.

## Vibrato
- It needs a nonzero instrument byte 4, no slide in progress, and a channel other than noise.
- It starts after the delay. On the note's first frame it only resets its state.
- Depth = (period[n-1] - period[n]) >> ((byte4 >> 4) & 7), i.e. a fraction of a semitone.
- The period is moved by the depth every frame, and the direction flips every (byte4 & 7) + 1 frames.
- The first leg is about half that length, so the wobble is roughly centred on the note.

## Output
Channels are processed in the order 4 (SFX), 3, 2, 1, 0.

- **Pulse and noise**: `$4000+o = (reg0 AND $CF) EOR $30` (constant volume and halt are always set). $4001 is written from a shadow that is never set, so the sweep is always 0. $4002+o gets the period low byte. $4003+o is written only when the period high byte changes, which avoids the pulse phase reset.
- **Triangle**: $4008 = $87 while a note sounds (linear-counter control set, so it sustains) and $80 at a rest. It has no volume envelope.
- **Noise**: the note indexes the same period table. PeriodLo[note] goes to $400E: bit 7 is the mode and the low nibble is the noise period. So the noise "notes" are just indices into that table.
- A music channel whose hardware channel is held by the SFX keeps running but skips its register writes.

## Sound effects
- Each effect is a normal track, played on internal channel 4. SfxTrackTbl ($8000) gives the track and SfxHwChTbl ($801A) the hardware channel.
- Every effect uses channel 1 (Sq2) or 3 (noise). The triangle path would apply pulse-style volume handling, but no effect uses it.
- Effects use their own instrument table and pitch-envelope table. They share the volume and duty envelopes with the music.
- Sfx_Play silences the target channel and starts the track with its own speed and transpose 0. Its fractional-speed counter ($D9) is not reset. A new effect always replaces the old one; priority is handled by the game (see above).
- The effect's instrument and pitch-envelope selection are not reset between effects. Every effect pattern starts with an instrument byte, so this has no audible effect.
- When the effect's track ends ($FE), Chan_Stop sets zSfxHwCh = 4, and the music takes the channel back on its next register write.

## RAM
All per-channel arrays have 5 entries (X = 0-4; 4 = SFX).
- **Zero page $A7-$FA**: track pointer and position, note, tick counters, pitch-envelope state, register offsets (chRegOfs = 0, 4, 8, 12, plus the SFX channel x 4), and zSfxHwCh at $DF (4 = none).
- **$07A0-$07C8**: vibrato state and volume-envelope position and loop point. $07C1 and $07C6 also serve as the slide-speed temporaries; they are the triangle's slots in the volume-envelope arrays, which the triangle never uses.
- **$7F4C-$7FBE (PRG-RAM)**: everything else, including register shadows and the $4003 write cache.

All names are in the .s file.

## Vestigial DMC drum track (removed)
These are leftovers of a fifth DMC channel:
- **SongTbl_Dmc ($806C)** has entries 0-3 for songs 0, 4, 5 and 7. Music_Play passes them to Chan_Start with X = 5, which just returns.
- **DmcTrackTbl ($89C5)** holds 4 x {pointer, 2 bytes}, and **DmcPatPtr ($89A9)** holds 14 pattern pointers. Nothing reads either table.
- The data they point to is still in the ROM: $9770-$9822, $A00F-$A094, $A50C-$A50D, $A5AD-$A5E1, $A7F4-$A7FE and $AC25-$ACC1. It uses the normal pattern format, with every note D#3 and instruments 0-6, i.e. the sample numbers.
- **DmcSampleTbl ($8710)**: 7 x 4 bytes, unreferenced. Its third byte is $C0-$E0, which as a DMC address points at $F000-$F800. That area now holds code in the fixed bank, so the samples themselves are gone.
- **Code vestiges**: Sound_Update ends with an `LDA $A8` test that writes $4010/$4015. Nothing ever sets $A8. Chan_Stop with X = 5 jumps to Dmc_Stop ($8702).

## Bugs and quirks
1. **Track end aborts the frame.** TEND reaches Chan_Stop by JMP, and Chan_Stop's RTS returns from Sound_Update. Every channel later in the loop (lower numbers) misses that frame. Because the SFX channel is processed first, every effect that ends makes all four music channels lose one frame of timing. Confirmed in emulation (`check_bugs.py`).
2. **Stale $4003 write cache.** Chan_Start and Chan_Stop write $00 to $4003+o but do not reset chLastPerHi. After an effect frees Sq2, the music keeps the wrong period high bits until its high byte changes. This was confirmed in emulation:
   - song 2 + effect 1: 5 frames
   - songs 1 and 4 + effect 1: 1 frame
   - song 9 + effect 4: 1 frame
3. **Absolute/relative test in the pitch envelope.** The test uses the N flag left by `CMP #$FD`, so any value $7D-$FC counts as absolute. In practice this is the same as testing bit 7; no envelope uses $7D-$7F.
4. **Volume envelope 12 wraps.** It starts at offset 227 and runs past 255, so it wraps into envelope 1. Its real tail and one more envelope sit at $8D1F-$8D4D, where no offset can reach. Only the unused instrument 30 refers to it.
5. **Vibrato on note 0** would read PeriodLo-1/PeriodHi-1: the last DMC-table byte and PeriodLo[68]. This never happens in the game's data.
6. **Dead code.**
   - $83DC-$83E9 (unreachable): a "no slide on noise" check.
   - $8389: a `CMP #$FE` whose result is discarded.
   - $83BF: `LDY chRegOfs,x`, overwritten right away.
   - $8494: a branch to the next instruction.
   - Write-only variables: $B1, $E0, $07AF+.
7. Sound_Init leaves $7F4B and $A6 alone, and clears the game's $FB.

## Data
| Item | Location |
|---|---|
| Songs | 0-13 |
| One-shot songs (TEND) | 3, 5, 7, 11, 12, 13 |
| Looping songs | All others |
| Two-channel song | 3 (Sq1 + Sq2 only) |
| Pattern data in bank 10 | $90DE-$9C36 |
| Pattern data in bank 4 | $A000-$B41C |
| Tracks | Stored in the same areas as the patterns, interleaved with them |
| Unused music instruments | 5, 13, 16, 23, 30, 31 |
| Unused SFX instrument | 17 |
