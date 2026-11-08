# Xantera Sound Driver: 4x4 World Trophy

Disassembly and documentation of the sound code in **4x4 World Trophy (E) (M5) [C][!].gbc** (1 MB, MBC5, CGB). The sound is by the German developer Xantera. Everything here comes from the code. The interfaces, timing and SFX paths were checked in PyBoy.

| Part | Location |
|---|---|
| Waves, noise table, older SFX records | bank 0 $3343–$33FB |
| Driver code | bank 0 $33FC–$385C |
| Engine gear table, SFX records | bank 0 $385D–$3918 |
| Songs (2) | bank $3C $4000–$6D3B |

## Summary

- **Time-stamped events.** A song is one stream of events for all four channels. Each event is `time:16 (big-endian) | command | data`, where *time* is the absolute frame count since the song started. There are no per-channel tracks, durations or note-offs.
- **Raw registers.** Notes carry NRx2 and an 11-bit period directly. The driver has no frequency table and no envelopes. The only lookup is a 10-entry noise instrument table.
- **SFX are register images.** An SFX record is a repeat timer followed by the 4–5 bytes written to NRx0/NRx1–NRx4. The game sets a pointer and calls one of four per-channel start routines. While an SFX owns a channel, music notes on it are skipped until the hardware shows the channel has stopped.
- **Engine voice.** ch3 doubles as the truck engine. The game writes an rpm value, and a timer-interrupt routine turns it into a ch3 period with a "gear" step every 16 rpm.
- **Only two songs**: a 53.8 s title/menu song and a 9.2 s jingle. Music never plays during races. The game stops it before the race starts.

---

## 1. Interface

| Address | Routine | Use |
|---|---|---|
| $33FC | `XSnd_Init` | NR50=$77, NR51=$FF, NR52=$8F, loads wave 0, NR32=$20, clears flags and SFX timers. Called at boot ($01AF) |
| $343B | `XSnd_PlaySong` | a = bank, de = song. Called from 00:3C7A, 0B:408A, 0B:7A89 (`XSong_Title`) and 0B:60EC (`XSong_Jingle`), always with bank $3C |
| $3473 | `XSnd_StopMusic` | playing = 0, ch3 DAC off. Called from 00:01F6, 00:07E6 |
| $348F | `XSnd_QueueSong` | de = song, b = bank, sets flag bit 7. Only used by `XSnd_EvEnd` |
| $34A0 | `XSnd_Update` | sequencer. VBlank ($025F) |
| $3530 | `XSnd_SfxTimers` | SFX repeat timers. VBlank ($0262) |
| $377D / $3717 / $3749 / $3766 | `XSnd_SfxCh1/2/3/4Start` | start the SFX at `wXSfxPtrN` |
| $372E | `XSnd_PlaySfxCh3` | hl = wave: saves the music wave, loads hl, starts the ch3 SFX |
| $37A0 / $37AD / $37BE / $37CD | `XSnd_SfxCh1/2/3/4Stop` | timer = 0, release the channel |
| $382A | `XSnd_EngineOn` | 00:0A95, 03:4F83 |
| $384D | `XSnd_EngineOff` | 03:4671 |
| $37DE | `XSnd_EngineUpdate` | timer interrupt ($0050 → $03D3) |

**Game-side SFX calls:**

- **Start.** The game writes the pointer big-endian (`ld hl,rec / ld a,h / ld [wXSfxPtrN],a / ld a,l / ld [wXSfxPtrN+1],a`), then calls the start routine.
- **Stop.** The game's stop helpers are:
  - 03:4671: engine off + all four channels;
  - 03:4681: ch1 + ch4;
  - 03:57E7: ch1. During a race this one runs every frame.
- **ch2.** `wXSfxPtr2` is never written, so ch2 SFX are never used.

**Bank switching.** VBlank first copies the game's bank shadow ($CB7A) to `wXCurBank`. `XSnd_Update` saves it, maps `wXMusBank` through $2000, and maps the saved bank back before returning. Each bank write is preceded by a `ld a,a` ($7F) no-op.

---

## 2. Sequencer

### 2.1 Clock

`wXMusTime` is a 16-bit frame clock that starts at 0 in `XSnd_PlaySong`. Each `XSnd_Update` call does this:

1. Read the next event's time.
2. If it is ≤ the clock, run the event and go back to step 1.
3. Otherwise increment the clock and return.

**Consequences:**

- An event with time *t* runs on the *(t+1)*-th update call.
- Any number of events can share a frame.
- The clock only advances when the update runs. Frames with the LCD off (no VBlank) stretch the song. In PyBoy the title song took 3,250 frames for its 3,213 ticks.
- The "late" branch (event high byte < clock high byte) also processes the event. It can only trigger if the data runs backwards, which it never does.

PyBoy check: all **2,457 events** of both songs were dispatched with the clock exactly equal to their time stamp, in stream order.

### 2.2 Events

| Command | Data | Effect |
|---|---|---|
| `$10` ch1 note | env, hi, lo | NR10=$80; NR12=env; NR11=hi\|$80; NR13=lo; NR14=(hi&7)\|$80 |
| `$11` ch2 note | env, hi, lo | NR22=env; NR21=hi\|$80; NR23=lo; NR24=(hi&7)\|$80 |
| `$12` ch3 note | vol\|hi, lo | NR34=0; NR30=$80; NR32=byte&$F0; NR33=lo; NR34=(hi&7)\|$80 |
| `$13` ch4 note | vol<<4 \| inst | NR41..NR44 from `XNoiseTable[inst]`, with NR42 = vol<<4 \| table nibble |
| `$2x` | – | NR30 = 0 (ch3 off) unless an SFX owns ch3 |
| `$3n` | – | NR32 = n<<4 unless an SFX owns ch3 |
| `$4n` | – | load wave n (`XWaveTable` + 16n) |
| `$5c` | lo, hi | NR(c)3=lo, NR(c)4=hi&7 without trigger (c = 0–2) |
| anything else | – | `XSnd_EvEnd`: stop, then start `XSong_Title` |

**Notes on the commands:**

- **Duty.** For pulse notes, byte 2 is ORed with $80 for NRx1. The data only uses 0–7, so the duty is always 50% and the "hi" byte is just the period's high bits.
- **No length.** Notes never enable length. ch1/ch2 notes end through their envelope, and every envelope in the data has a pace of 1–6.
- **ch3 staccato.** ch3 notes are always followed by a `$22` off event: 490 pairs in the title song, 33 in the jingle.
- **Unused commands.** `$3n` and `$5c` never appear in the data. The only `$4n` is `wave 0, 2` at the start of each song.
- **SFX ownership** is checked for each note (§3.2).

### 2.3 Songs

| Song | Address | Events | Length | Started from | At the end |
|---|---|---|---|---|---|
| `XSong_Title` | $3C:$4000 | 2,108 | 3,212 frames | 00:3C7A, 0B:408A, 0B:7A89 | restarts itself |
| `XSong_Jingle` | $3C:$661A | 349 | 551 frames | 0B:60EC | starts `XSong_Title` |

Both end with `$60`.

**End handling.** `XSnd_EvEnd` hard-codes $3C:$4000. It stops the music, queues the title song and immediately starts it. So every song "loops" into the title song. Verified in PyBoy: the jingle ended at its 552nd tick and `XSnd_PlaySong($3C,$4000)` followed in the same frame.

**Periods.** Each pitch in the data uses a single fixed period value (52 notes, C2–A♯6). These are mostly the floor of the exact equal-tempered value, and up to 17 cents flat at the top. `xantera_sound.inc` names them `C_2`…`As6`. The same period on ch3 sounds an octave lower than the name.

**Noise.** Notes use instruments 3, 4 and 8, with volumes 6, 7, $A, $B, $E and $F.

---

## 3. Sound effects

### 3.1 Records

| Channel | Bytes | Registers |
|---|---|---|
| ch1 | 6 | timer, NR10, NR11, NR12, NR13, NR14 |
| ch2 | 5 | timer, NR21–NR24 |
| ch3 | 6 | timer, NR30–NR34 (NR30 and NR34 are zeroed first) |
| ch4 | 5 | timer, NR41–NR44 |

**Timer.** Each frame `XSnd_SfxTimers` decrements every nonzero timer. When a timer *reaches 1*, the SFX restarts from its record, which reloads the timer.
- 0 or 1: one-shot.
- *n* > 1: retriggers every *n*−1 frames until a stop routine clears it.
- The ch3 timer does not restart while the engine is on.

**Records in the ROM** (all bank 0):
- **$3865–$3918:** 41 records. 20 are referenced by the game:
  - ch1: `XSfx1_3887`…`XSfx1_390D`, 14 records;
  - ch4: 5 records;
  - ch3: `XSfx_Engine`.
- **$33CB–$33FB:** an older set of 9 records that nothing points to. It holds the only ch2 records.
- The unreferenced records fit exactly between the referenced ones as ch1/ch4 records.

**Seen in PyBoy during a race:**
- `XSfx1_3887` and `XSfx1_388D` play on the start countdown (game code 03:55A6 / 03:55E9).
- `XSfx1_390D` (timer 7) is a repeating beep.

### 3.2 Channel ownership

**Claiming.** Starting an SFX sets bit *n* of `wXSndFlags`. When a music note arrives for that channel:

- **ch1, ch2, ch4.** If the NR52 status bit is still set, the note is skipped. Otherwise the flag is cleared and the note plays.
- **ch3.** The test is NR30 bit 7 (DAC on) instead. When ch3 is handed back, the music wave is reloaded from `wXWaveSave`.

**When a channel counts as finished.**
- The NR52 bit only clears when a length counter expires or the DAC is turned off. Many ch1 records ($3887, $388D, $3893, …) have no length enable (NR14 = $8x), so the channel stays claimed until `XSnd_SfxCh1Stop`.
- `XSnd_SfxCh1Stop` only clears the flag and timer. It does not touch the hardware.
- The ch2/ch3/ch4 stops zero NR22/NR30/NR42.

**Muting music channels.** `XSnd_PlaySong` and `XSnd_StopMusic` both write `NR52 & ((flags | $80) & $8F)`, which is meant to mute the music channels. Only NR52 bit 7 is writable, so this does nothing. `XSnd_StopMusic` therefore leaves ch1, ch2 and ch4 notes to decay on their own. Only ch3 is cut.

### 3.3 Engine voice

**`XSnd_EngineOn`.**
1. Points `wXSfxPtr3` at `XSfx_Engine` (NR30=$80, NR31=$74, NR32=$20, NR33=0, NR34=$80).
2. Calls `XSnd_PlaySfxCh3` with `XWave_Engine`. This is the same wave (2) that the songs use.
3. Sets flag bit 4.

**`XSnd_EngineUpdate`** runs from the timer interrupt. When `wXEngineRpm` differs from the last value:

```
period = 0                                        if rpm = 0
period = XEngineGearBase[rpm >> 4] + 32 * (rpm & $0F)   otherwise
NR33 = LOW(period); NR34 = HIGH(period) | $80     ; retrigger
```

`XEngineGearBase` = $0200, $01A0, $0150, $0100.

- **Gear shifts.** The pitch rises across each block of 16 rpm, then falls back at the next block, which sounds like a gear shift.
- **The rpm value.** The game writes rpm = (a game value in bc) >> 3, apparently the truck speed, at 00:0E4B and clears it at 00:099E. In PyBoy, holding the accelerator reached rpm $2A, so gear 2.

**`XSnd_EngineOff`** clears bit 4 and calls `XSnd_SfxCh3Stop`.

### 3.4 RAM

| Address | Name | |
|---|---|---|
| $C37B | `wXMusPlaying` | |
| $C37C | `wXMusTime` | big-endian |
| $C37E | `wXMusPtr` | big-endian |
| $C380 / $C382 | `wXQueuedPtr` / `wXQueuedBank` | |
| $C383 | `wXSndFlags` | bits 0–3 SFX ch1–4, bit 4 engine, bit 7 queued |
| $C384–$C387 | `wXSfxTimer1–4` | |
| $C388–$C38F | `wXSfxPtr1–4` | big-endian |
| $C390 | `wXWaveCur` | last loaded wave |
| $C392 | `wXWaveSave` | music wave to restore |
| $C394 | `wXMusBank` | |
| $C396 | `wXSavedBank` | |
| $C398 / $C399 | `wXEngineRpm` / `wXEngineRpmLast` | |
| $C39A | `wXCurBank` | game's bank shadow |

---

## 4. Tables

| Table | Address | Contents |
|---|---|---|
| `XWaveTable` | $3343 | 6 waves. 0: default, loaded at init and song start. 2: songs and engine. 1, 3 (ramp), 4 (square) and 5 (random-looking) are unused |
| `XNoiseTable` | $33A3 | 10 × (NR41, NR42 low nibble, NR43, NR44). The songs use entries 3, 4 and 8 |
| `XEngineGearBase` | $385D | 4 big-endian words |

`$4n` and the ch4 instrument index have no bound checks. Waves 6+ would read the noise table and the SFX records.

## 5. Quirks and bugs

1. **ch4 skip size.** When an SFX still owns ch4, the note is skipped with `hl += 2`, but ch4 notes are 1 byte. The stream then desyncs, and the next event's time byte is read as a command. This can only happen if a ch4 SFX plays during music.
2. **Wave save in `XSnd_PlaySong`.** With a ch3 SFX active, `XSnd_PlaySong` stores `h` twice, so `wXWaveSave` = $3333 instead of `XWaveTable`. That address is 16 bytes of the game table just before the waves.
3. **Wave save in `XSnd_EvWave`.** With a ch3 SFX active, the wave index *n* is written to the high byte of `wXWaveSave`, so the wave later restored comes from $0n33.
4. **Wave not restored.** `XSnd_EngineOff` and `XSnd_SfxCh3Stop` don't restore the music wave. This is harmless here because the engine and both songs use the same wave.
5. **No-op NR52 writes.** See §3.2.
6. **ch1 pitch event.** `$50` (unused) checks only the ch1 SFX flag, not NR52 like the note path.
7. **Gear table bound.** rpm ≥ $40 would read SFX bytes as gear bases.
8. **Dead code.** The pulse note paths contain a dead `ld e,4 / srl e`. There is also a `ld a,a` before every bank write.
9. **Unreachable ch2 SFX.** The ch2 SFX path (start, timer, stop) is complete but never used.

## 6. Files

In `GBAudioLab\Xan\`:

| File | Contents |
|---|---|
| `4x4WorldTrophy_sound.asm` | driver, tables and SFX (bank 0 section) + both songs (bank $3C section) |
| `xantera_sound.inc` | RAM names, flag bits, event macros (`ch1_note`…`ch4_note`, `ch3_off`, `ch3_vol`, `wave`, `pitch`, `song_end`), `noise_inst`, `sfx1`–`sfx4`, `bigw`, note period constants |
| `hardware.inc` | register names |
| `tools\gen_xan.py` | generator: `python tools\gen_xan.py <ROM> [outdir]` |
| `tools\verify.py` | assembles and compares with the ROM (rgbasm/rgblink on PATH) |
| `tools\emucheck.py` | PyBoy check of event timing and order (`python tools\emucheck.py <ROM> 5300`) |
| `tools\sm83.py`, `tools\parse.py` | disassembler and event-stream parser |

The output is **byte-identical** with RGBDS 1.0.0:

```
rgbasm -o x.o 4x4WorldTrophy_sound.asm
rgblink -p 0xFF -o x.gb x.o
python tools\verify.py "4x4 World Trophy (E) (M5) [C][!].gbc"
```

| Region | Bytes checked | Mismatches |
|---|---|---|
| bank 0 $3343–$3918 | 1,494 | 0 |
| bank $3C $4000–$6D3B | 11,580 | 0 |
