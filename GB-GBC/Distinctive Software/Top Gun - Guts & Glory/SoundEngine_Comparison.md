# One sound driver, four games: Distinctive Software → Radical Entertainment (Game Boy, 1991–1993)

**Verdict: all four games use one driver family that evolved over time.** *Bill Elliott's NASCAR Fast Tracks* has the oldest, tracker-style version. *Top Gun: Guts & Glory* rewrote it to play MIDI-like event streams, keeping NASCAR's data tables and envelope design. *The Battle of Olympus* is a Radical Entertainment fork of the Top Gun driver that adds sound-effect channel priorities. *Wayne's World* is a direct, debugged descendant of the Battle of Olympus driver.

```
NASCAR Fast Tracks (Distinctive, 1991)   tracker: order lists + 2-byte rows, 4 fixed channels
        │  same tables, drum map, ADSR record, command numbers D9–DC
        ▼
Top Gun: Guts & Glory (Distinctive, 1993)   MIDI-style delta streams, 9 tracks, 14-byte instruments
        │  same RAM layout (+3/+9/+10), same routines, same unused vestiges
        ▼
Battle of Olympus (Radical, 1993)   pointer instruments, channel priority, SFX slots
        │  same RAM layout (moved by −$1B0C), same routines (90–100 % match)
        ▼
Wayne's World (Radical, Nov 1993)   bug fixes, wave channel on, note key-off
```

| | NASCAR (NF) | Top Gun (TG) | Battle of Olympus (BO) | Wayne's World (WW) |
|---|---|---|---|---|
| Driver | ROM0 `$1CAB–$228E` | ROM0 `$259E–$2AE6` | ROM0 `$22DB–$2816` | bank `$0A` `$6815–$6D40` |
| Music data | banks 5 & 2 | bank 6 | bank `$0F` | bank `$0A` (with the driver) |
| Format | order lists + rows | delta streams | delta streams | delta streams |
| Disassembly | `NASCARFastTracks_SoundDriver.asm` | `TopGunGutsGlory_…` | `BattleOfOlympus_…` | `WaynesWorld_…` |

All four `.asm` files re-assemble **byte-exact** with RGBDS 0.9.1. That check is built into the build.

---

## 1. Shared by all four

- **Frequency table** (118 words from C2, `$002C` … `$07FE`, 236 bytes) is byte-identical in all four ROMs. NASCAR explains the odd tail: note `$75` (117) is its **rest**, a pitch too high to hear.
- **`00 60 40 20` NR32 level table** sits in front of the frequency table in all four. Only NASCAR reads it; TG, BO and WW carry it unused.
- **Command numbers**: `DA` = stop, `DB` = restart/rewind and `DC` = select instrument in every game. `D9` changes meaning across the family: next order (NF), stop all (TG), restart song (BO), end track (WW).
- The **wave RAM is loaded only when an instrument is selected for channel/track 2**, using the same 16-byte copy loop (`cp $40`) in every version.
- Every version stores a **"tempo" of `$60` that is never read** (TG/BO/WW), and all use a 1-frame tick.

## 2. NASCAR → Top Gun (Distinctive Software)

The data format was rewritten (pattern rows became MIDI-like delta streams), but much of NASCAR survives in Top Gun:

- **Wave pattern**: NF `$20BB` = TG `$2993` (byte-identical).
- **Instrument layout**: TG's 14-byte record is one channel byte followed by NASCAR's 34-byte record, bytes +0..+12: duty, (0), sweep, transpose, detune, delay, attack step, peak, decay step, sustain, release. TG rescales peak/sustain from the low nibble to the high nibble (`$0F` → `$F0`). TG's driver reads release from +B, but its data still stores NASCAR's release value at +D.
- **Drum records**: TG's six CH4 records at `$2A93` are converted copies of NASCAR's six at `$21BB`, in the same order. Records 0, 2, 3, 4 and 5 keep NASCAR's attack/decay/release values; only record 1 was changed.
- **Drum map**: the same note → NR43 code (the note→NR43 decision code), with the same NR43 values (`$88`, `$30`, `$70`). The same dead `$60/$50/$40` branches pointing at record 4, and the same tail order `cp $15 / $18 / $19 / $1B` with identical results.
- **Pitch-offset vestige**: NASCAR writes `ld a,e / add [hl] / ldh [NR13] / inc hl / ld a,d / adc [hl] / set 7,a / ldh [NR14]` to add per-instrument detune. TG has the same sequence with DE forced to 0, so a no-op add remains.
- **Software ADSR**: NASCAR's envelope really writes NRx2/NR32 every frame. TG keeps the attack/decay/sustain/release state machine but its output routine starts with `RET`.

## 3. Top Gun → Battle of Olympus (Distinctive → Radical)

These are the findings from the first report, now confirmed by NASCAR: TG is the older side.

- Same RAM order: BO = TG +3, +9 or +10, depending on the block. BO still clears TG's two envelope arrays, which it never uses, and stores DE into TG's instrument-table slot without ever reading it.
- Same routines: StartSong 0.91, ReadEvent 0.89, SetInstrument 0.72, ReadVarLen and SetTempo 1.00 (normalized similarity scores).
- BO's music bank still holds orphaned **TG-format 14-byte instrument records** after three song headers, and BO contains an unreachable **TG-style CH3 note-on**.
- New in BO: 16-bit instrument pointers (6-byte records), channel priority with hold timers, and SFX dropped into free track slots.

## 4. Battle of Olympus → Wayne's World (Radical)

- **The RAM layout is BO's, moved by exactly −`$1B0C`** (`$DE51` → `$C345`, `$DE63` → `$C357`, … `$DEAF` → `$C3A3`).
- Per-routine instruction match with BO: AddTrack 1.00, BadCommand 1.00, SetTempo 1.00, ReadEvent 0.98, StartSong 0.96, UpdateTrack 0.91, SetInstrument 0.89, Update 0.81, NoteOn 0.67.
- BO vestiges are still present: the DE→"instrument table" store that is never read, the unused tempo `$60`, and the `nop / jp` "slots full" path in AddTrack.
- **Fixes and changes:**
  - ReadVarLen now decodes real 15-bit lengths (the `rrca` bug is gone).
  - A delta of 0 now plays the next event in the same frame.
  - The wave reload now tests the instrument's *channel*; BO tested the *track* index.
  - CH3 is enabled and reloads its wave on every note.
  - The note parameter became a gate: when the channel timer expires, the driver keys the note off (length-enable on CH1/2, parks CH3, NR42=0).
  - NRx2 now comes straight from the instrument.
  - CH4 reads NR43/NR42/NR41 from the instrument.
  - `D9` now ends a track, and `DB` restarts the tracks without resetting the APU.
  - NR52=`$8F` and NR51=`$DE` (CH1 left only, CH2 right only).
  - Everything moved into bank `$0A`, which starts with a bank-ID byte.
- **PCM is separate**, as you suspected. Four copies of a small player (banks `$03`, `$06` ×2 and `$0E`) turn interrupts off and push 4-bit nibbles through CH3 wave RAM, retriggering CH3 for each one. It shares no code with the driver. Sample data is at `03:$7411`, `06:$6495`, `06:$68A6` and `0E:$65E9`.

## 5. Game framework

TG, BO and WW share identical boot/reset code (`ld sp,$DFFF / … ldh a,[rLCDC] …`, at `$2AE7` / `$2817` / `$0CEE`) and an identical `WaitNextFrame` routine (`$0CA0` / `$0285` / `$02C9`). NASCAR has neither, so the shared framework appears after NASCAR, while the sound driver goes back further. NF and BO both call their sound update from `$01A9` in the VBlank code.

## 6. How each version works (short reference)

| | NF | TG | BO | WW |
|---|---|---|---|---|
| Voices | 4 fixed | ≤9 tracks | 9 tracks | 9 tracks |
| Time unit | row duration | delta (8-bit, buggy) | delta (8-bit, buggy) | delta (15-bit) |
| Instrument | 34 B, index | 14 B, index | 6 B, pointer | 6–8 B, pointer |
| Envelope | software ADSR (live) | software ADSR (output stubbed) | HW NRx2 + note param | HW NRx2 from instrument |
| Channel arbitration | n/a | none | priority + hold timer | priority + timer + key-off |
| SFX | not in driver | game code | driver slots | driver slots |
| CH3 wave | yes (no trigger) | yes | disabled | yes |
| CH4 drums | note→NR43 map + records | same map | raw NR43 | instrument NR43 |
| Vibrato | accumulated, never applied | — | — | — |

## 7. Caveats
- The analysis is static: I did not run any of this in an emulator. Behaviour notes that depend on hardware quirks are observations to confirm in a debugger. Examples: NASCAR and TG writing NRx2 without a retrigger, TG's missing NR44 trigger, and WW's length-counter key-off.
- Developer and year attributions: NASCAR (1991, Konami licence `$A4`) is credited to Distinctive Software; Wayne's World (Nov 1993) to Radical Entertainment (VGMPF). Radical was founded in 1991 by ex-Distinctive staff.
- Signature for finding more members of the family: the frequency table with `00 60 40 20` in front of it. For the stream-based versions, also the event parser's `cp $D9 … cp $EA` chain.

## Files
- `*_SoundDriver.asm` ×4: labelled, commented, byte-exact RGBDS source (+ `hardware.inc`)
- `*_SongData.txt` ×4: every song, track/order list, SFX and instrument decoded
- `tools/songparse.py`: stream walkers (BO/TG variant and the WW variant)

Sources: [Top Gun: Guts and Glory – Wikipedia](https://en.wikipedia.org/wiki/Top_Gun:_Guts_and_Glory) · [The Battle of Olympus (GB) – TCRF](https://tcrf.net/The_Battle_of_Olympus_(Game_Boy)) · [Radical Entertainment – Wikipedia](https://en.wikipedia.org/wiki/Radical_Entertainment) · [Wayne's World – VGMPF](https://vgmpf.com/Wiki/index.php?title=Wayne%27s_World) · [NASCAR Fast Tracks – MobyGames](https://www.mobygames.com/game/31864/bill-elliotts-nascar-fast-tracks/)
