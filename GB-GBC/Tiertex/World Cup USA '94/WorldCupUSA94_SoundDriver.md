# World Cup USA '94 (GB): sound driver

ROM: `World Cup USA '94 (UE) (M8) [!].gb` (MBC1+RAM+battery, 256 KB)

| | |
|---|---|
| API (bank 0) | `PlayMusic` `$0F24`, `StopMusic` `$0F43`, `PlaySfx` `$0F53` |
| Driver code | bank 3 `$4000–$4674` |
| Tables / instruments / streams / SFX | bank 3 `$4675–$573D` |
| Tick | STAT ISR `$11C3` (LYC = `$50`) calls `3:$40A1` (music) and `3:$462A` (SFX) once per frame |
| Music rate | 50 ticks/s (every 6th frame is skipped) |
| SFX rate | 60 ticks/s |
| RAM | `$D480–$D4D3` |
| Songs / SFX | 9 songs, 7 SFX |

`WorldCupUSA94_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 for both ranges (0:`$0F24–$0FB5`, 3:`$4000–$573D`).

```
rgbasm -o snd.o WorldCupUSA94_SoundDriver.asm
rgblink -p 0xFF -o snd.gb snd.o
```

---

## 1. Architecture

This is a small, fixed four-channel driver. Each hardware channel has exactly one stream, with no channel allocation and no software envelopes. It has two update routines:

- **Music** (`SndUpdate`): runs CH1 → CH2 → CH3 → CH4. Each channel has its own copy of the event reader: CH1/CH2 are pulse, CH3 is wave, CH4 is noise. If any channel hits `$FE` (stop), the channels after it are skipped for that tick.
- **SFX** (`SndUpdateSfx`): one effect on CH1. `PlaySfx` **refuses to start while music is playing** or while another SFX is running, so the two never overlap. The game stops the music before gameplay SFX.

### Per-channel state (`$12` bytes each: CH1 `$D48C`, CH2 `$D49E`, CH3 `$D4B0`, CH4 `$D4C2`)

| Off | Name | Use |
|---|---|---|
| +00 | Ptr (2) | stream pointer |
| +02 | Note | current note (0 = rest; pitch table only runs when nonzero) |
| +03 | Freq (2) | current period (CH1–3) |
| +05 | Wait | ticks until the next event |
| +06 | InsByte | last `$80–$BF` byte |
| +07 | InsPtr (2) | instrument record |
| +09 | VibIdx | position in the period-delta table |
| +0A | Duty | copy of instrument +5 (CH1/2); written, never read |
| +0B | LoopCnt | `FC`/`FD` counter |
| +0C | LoopPtr (2) | loop start |
| +0E | SubCnt | `F9`/`F8` repeat count |
| +0F | SubRet (2) | address of the `F9` pointer operand |
| +11 | Transpose | from `F9`, added to note bytes |

Globals: `$D480` SFX active, `$D481` SFX id×2 (write-only), `$D482` SFX instrument byte, `$D483` SFX instrument pointer, `$D485` SFX delta index, `$D486` SFX timer, `$D487` SFX period, `$D489` music on, `$D48A` song×2, `$D48B` frame divider.

---

## 2. Stream format and command set

A stream is a byte sequence. Notes and rests carry their own duration. Everything else is read in the same tick until a note or rest ends the read.

| Byte | Args | Macro | Effect |
|---|---|---|---|
| `$00` | dur | `rest d` | Key-off. CH1–3: set length to 1 step and retrigger with length enabled (cuts the note), then NRx2 = `$01` (DAC off); CH3 uses NR31 = `$FF`, NR32 = 0. CH4: NR42 = `$01` only. Wait = dur. |
| `$01–$7F` | dur | `note n, d` | CH1–3: period = `FreqTable[n + transpose]`, envelope from instrument +6 (CH3: NR32 = `$40`, 50% level, fixed), trigger. CH4: drum n → `NoiseTable[n-1]`, transpose ignored. Wait = dur. |
| `$80–$BF` | – | `instr i` | Instrument i = byte − `$80`. Applied **immediately**. CH1: NR10 = +4, NR11 = +5 & `$C0`, NR12 = +6. CH2: same without NR10. CH3: copies 16 wave bytes to `$FF30`. CH4: ignored. |
| `$F8` | – | `ret_pat` | Pattern end: `--SubCnt`; if nonzero, replay the pattern, else continue after the `F9` and set transpose to 0. |
| `$F9` | n, t, ptr16 | `call_pat n, t, ptr` | Play pattern `ptr` n times with signed transpose t. Only one level deep. |
| `$FC` | n | `loop_start n` | Loop start, n passes. Only one level deep. |
| `$FD` | – | `loop_end` | `--LoopCnt`; if nonzero, jump back to the loop start. |
| `$FE` | – | `music_stop` | Stop music: `wMusicOn` = 0, NRx2 = 0 on all four channels. |
| `$FF` | – | `song_restart` | Re-initialise the whole song (`SndInitSong`), then run the CH1 update. |
| other `$C0–$FF` | – | `cmd_nop` | 1-byte no-op. `$ED` is compared explicitly, but both paths do the same thing. None are used in the data. |

Durations are in ticks. A value of 0 behaves like 1.

**Pitch table ("vibrato").** Every instrument ends in a table of n signed period deltas. While a note is held, each tick advances the index (1, 2 … n−1, 0, 1 …) and **adds** that delta to the current period. NRx4 is written without the trigger bit. The table is cumulative, so `0,1,0,0,-1,0` gives a vibrato and a single `-50` gives a continuous downward slide. SFX use the same mechanism.

## 3. Data layout (bank 3)

| Address | Content |
|---|---|
| `$4675` / `$4687` / `$4699` / `$46AB` | CH1 / CH2 / CH3 / CH4 stream pointer per song (9 words each) |
| `$46BD` | NR50, NR51 per song (all `$FF,$FF`) |
| `$46CF` | NR52 per song (`$8F`) plus a pad byte that is read and ignored |
| `$46E1` | Frequency table: 103 period words. 0–22 are 0, 23 = C2 … 102 = G8 |
| `$47AF` | Noise table: 16 × {NR43, NR42, ctl}. ctl bits 0–5 = NR41; bit 6 set → NR44 `$80`, else `$C0` |
| `$47DF` | Instrument pointer table: 64 words, used by `$80–$BF`. Entries 1–19 are pulse, 32–36 are wave, the rest are 0 |
| `$485F–$495C` | Instrument records |
| `$495D–$572F` | Music streams and patterns |
| `$5730` | SFX table: 7 × {instrument byte, duration} |

**Pulse instrument:** `+0` n, `+1/+2` start period (SFX only), `+3` unused, `+4` NR10, `+5` NR11, `+6` NR12, `+7…` n deltas.
**Wave instrument:** `+0` n, `+1…+16` wave RAM, `+17…` n deltas.

### Songs

| # | Caller(s) | Content | End |
|---|---|---|---|
| 0 | none found | full 4-channel song | `FF` loop |
| 1 | 2:`$401F` | full song | `FF` loop |
| 2 | 0:`$1BD0` | CH1–3 jingle | `FE` stop |
| 3 | 1:`$6C7F`, `$6DFD` | CH4 only: drum 3, drum 4 | `FE` |
| 4 | none found | CH4 only: drum 8, drum 7 | `FE` |
| 5 | none found | CH4 only: drum 5, drum 9 | `FE` |
| 6 | none found | CH4 only: drum 6 held in nested loops | never ends (see quirks) |
| 7 | 2:`$4198`, `$6C91`, `$6D57`, `$6E14`, `$7A08`, `$7A77`, `$7ADE` | full song | `FF` loop |
| 8 | 2:`$4449` | full song | `FF` loop |

Channels a song doesn't use point at `Track_Silent` (`$495D`), which loops a 255-tick rest forever.

### SFX (`PlaySfx`, CH1)

| # | Instr | Ticks | Start period | Delta/tick | Callers |
|---|---|---|---|---|---|
| 0 | 1 | 3 | `$7C0` | +5, −5 (trill) | 1:`$55DE` |
| 1 | 1 | 20 | `$7C0` | +5, −5 | none found |
| 2 | 1 | 35 | `$7C0` | +5, −5 | none found |
| 3 | 3 | 1 | `$064` | −30 | 1:`$6857` |
| 4 | 14 | 1 | `$12C` | −10 | 1:`$6F37` |
| 5 | 15 | 15 | `$500` | −5 (falling) | 1:`$6CF8`, `$6E71` |
| 6 | 16 | 5 | `$12C` | −50 | 3:`$6185` |

---

## 4. Quirks and bugs

1. **Frequency table entry 24 is wrong.** It holds `$056` (≈66.8 Hz, about C2 + 37 cents) where C#2 (≈`$09D`) belongs. Index 24 appears about 115 times in the decoded pulse parts (mostly CH2), so those bass notes sound as a slightly sharp C instead of C#.
2. **Out-of-range note in song 1.** Pattern `$504C` (CH3, transpose +4) contains `note $7F, 82`. The driver computes `(note+t)*2` in 8 bits, so index 131 wraps to 3, which is a zero period (64 Hz). Static reading says this is an 82-tick low hum on the wave channel. It looks like a converter artefact for a long rest. Verify in an emulator.
3. **Nested loops share one counter.** Song 6 uses `FC FF FC FF … FD FD`. The inner loop overwrites the outer loop's counter and pointer, so the outer `FD` always re-enters the inner loop and the track never reaches its `FE`. Patterns can't nest either (`F9` inside a pattern would overwrite `SubRet`), but no data does that.
4. **Restart is CH1-centred.** `$FF` on any channel calls `SndInitSong` and then runs **CH1's** update. The channel that hit `$FF` reads its first event one tick after the others.
5. **Wave RAM is written with CH3 enabled.** The instrument change doesn't clear NR30 first, which is unreliable on DMG.
6. **Instrument changes are immediate.** NR10/NR11/NR12 are written when `$80–$BF` is read, not at the next note-on.
7. **The frame divider keeps running** while music is stopped, and `SndInitSong` resets it.
8. **Dead state:** the `Duty` bytes (`$D496`, `$D4A8`), `wSfxIdX2` and the second NR52 byte are never read. `SndInitSong` doesn't reset CH4's transpose, the loop and pattern counters, or the vibrato indexes.
9. `PlaySfx` writes the full instrument +5 byte to NR11, length bits included. Music masks it with `& $C0`.

## 5. Unreferenced data

Nothing in the ROM points at these blocks. They decode cleanly as streams and are labelled `Unused_xxxx` in the `.asm`:

- `$4AC5–$4B1E`: two CH4 drum patterns (drums 1/2)
- `$4BD9–$4D02`: three melodic patterns. `$4C5B` selects instrument 8, which has a null pointer, so it could not play correctly anyway.
- `$5052`, `$5078`, `$5722`, `$5726`, `$572D`: small `instr/rest/…/F8` fragments
- `$4919–$491A` (`FB 05`): leftover bytes after wave instrument 33
- `$573E–$573F` (`FF F7`) after the SFX table. Mostly `$FF` filler follows, with scattered non-`$FF` bytes (the first at `$5793`) that no sound code reads. Game code resumes at `$6000`.

## 6. Caveats

- All analysis is static. Nothing was run in an emulator. Items 2, 3 and 5 in section 4 should be checked by ear or in a debugger.
- "No caller found" means no `call`/`jp` to the API with that immediate value exists in the ROM. An indirect call (a value loaded from a table) would not show up that way.

## Files

- `WorldCupUSA94_SoundDriver.asm`: labelled and commented RGBDS source with stream macros, byte-exact (needs `hardware.inc`, included)
- `WorldCupUSA94_SongData.txt`: decoded songs with patterns expanded, instruments, drum and frequency tables, SFX and a coverage report
- `tools/wcparse.py`: the stream walker that produces the `.txt`
