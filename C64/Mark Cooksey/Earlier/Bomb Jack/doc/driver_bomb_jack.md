# Bomb Jack (1986 Elite): early driver

Source: `disasm/bomb_jack_sound.s`. Rip: `Bomb_Jack.sid`, PSID v2, load $73A0-$96FA, 6 songs, clock flag "unknown" (players treat it as PAL).

## Memory map

| Range | Contents |
|---|---|
| $73A0-$7447 | variables (inside the image; values are the ripper's snapshot) |
| $7448-$7E32 | player |
| $7E33-$7FFF | zero fill |
| $8000-$8171 | SID ripper wrapper (`Rip_...`), not the game's |
| $8400-$96FA | six song modules |

Zero page: `zPat1` $4B, `zPat2` $4D, `zPat3` $4F (pattern pointers), `zOrder` $51 (temporary order list pointer).

## Structure

The player is written out three times, once per voice (`V1_...`, `V2_...`, `V3_...`), with fixed SID addresses in each copy. Every SID register has a shadow byte (`mV1FreqLo` ... `mV3SR`, plus `mModeVol`, `mResFilt`, `mCutoffHi/Lo`); `Output` copies the shadows to the SID on every call. The control register is the exception: it is written directly when a note starts.

`Play` keeps the voice 1 and 2 pattern pointers in `SavedPtrs` ($7E2F) between calls and copies them to zero page on entry. Voice 3's pointer stays in $4F/$50 only, so the game must not touch those two bytes.

## Timing

- `Play` runs the effects and `Output` on every call.
- The patterns are read once every `mSpeed` calls (one **tick**). Songs set `mSpeed` to 3, 4 or 6.
- The rip's play routine (`Rip_Play`, $8020) calls `Play` **twice per 50 Hz frame**.

## Song modules

Each song is a self-contained block: an init routine, three order lists, then the patterns. The init routine writes the first pattern of each voice straight into zero page, the order list pointers, `mSpeed`, the counters (all 4) and the order index (2, because entry 0 is the pattern it has just loaded). Song 0 also sets the slide speed and step.

| Song | Init | mSpeed | Patterns |
|---|---|---|---|
| 0 | $8400 | 4 | 9 |
| 1 | $8C4F | 3 | 3 |
| 2 | $8D59 | 4 | 7 |
| 3 | $8F25 | 4 | 3 |
| 4 | $8FF5 | 4 | 3 |
| 5 | $9119 | 6 | 15 |

**Order list:** `.word` pattern pointers; a word with high byte 0 sends the voice back to entry 0. Every song loops.

## Pattern format

One event is read per tick per voice.

| Bytes | Meaning |
|---|---|
| `$00` | end of pattern: take the next order list entry |
| `$01-$C7`, `nn` | note lasting that many ticks. `nn` bits 0-3 = semitone (1 = C ... 12 = B), bits 4-6 = octave. `nn` = 0 (semitone 0) is a rest. |
| `$C8-$F5` [params] | command |
| `$F6-$FA`, `cnt` | drum |

**Notes.** `NoteToFreq` takes the semitone from `FreqTable` (octave 5) and shifts it: octaves 0-4 right by `OctaveShift`+1, octave 6 and 7 left by 1 or 2. Semitones 13-15 would read past the table. A rest writes the control register with the gate off. A note sets the shadow frequency, and if the voice's `mOutputOn` bit is set it writes the control register with the gate off and then on (a retrigger). With the bit clear the gate is left alone, which gives a legato note.

### Commands

Voice 1 knows every command. Voices 2 and 3 have shorter handler lists; on those voices any other byte in $C8-$F5 is skipped as a 1-byte command (a parameter after it would then be read as an event).

| Byte | Params | Effect | V1 | V2 | V3 |
|---|---|---|---|---|---|
| $C8 `C_VOLUME` | v | `mModeVol` (SID_MODE_VOL) | x | | |
| $C9 `C_WAVE` | w | control value (waveform + gate bit) | x | x | x |
| $CA `C_AD` | ad | attack/decay | x | x | x |
| $CB `C_SR` | sr | sustain/release | x | x | x |
| $CC / $CE | | voice 1 track on / off (`mTrackOn` bit 0) | x | | |
| $CD / $CF | | voice 1 SID output on / off (`mOutputOn` bit 0) | x | | |
| $D0 / $D4 | | octave trill on / off | x | x | x |
| $D1 / $D5 | | pulse sweep on / off | x | x | x |
| $D2 / $D6 | | slide on / off | x | x | |
| $D3 / $D7 | | slide that waits for the delay on / delay off | x | | |
| $D8 `C_PULSE` | lo, hi | pulse width | x | x | x |
| $D9 `C_SPEED` | s | `mSpeed` | x | | |
| $DA `C_PWRANGE` | min, max | pulse sweep range (high byte) | x | | |

Once `$CE` has turned voice 1's track off, nothing in the patterns can turn it back on: only the game can.

### Drums

`$F6 cnt` starts a noise burst on the voice (AD $08, SR $00, frequency high $FA, gate on) and holds the pattern for cnt-1 ticks (cnt = 1 gives 255). While a drum plays, `Output` leaves that voice alone. `$F7-$FA` are empty drums: their handlers are a bare `RTS` and never count down, so a voice that used one would stop for good. No song uses them. Bytes $FB-$FF are not drums and would misalign the pattern.

## Effects (run on every call)

- **Pulse sweep** (`mPwSweepOn` bits): every `mPwSweepSpeed` calls the pulse high byte goes up by 1; past `mPwSweepMax` it restarts at `mPwSweepMin`. Speed and range are shared by all voices.
- **Octave trill** (`mTrillOn` bits): every `mTrillSpeed` calls the frequency is doubled, then halved, in turn. Only voice 1 resets its trill phase on a new note; on voices 2 and 3 a note that starts in the "up" phase is first halved, so it drops an octave.
- **Slide** (`mSlideOn` bits 0-2): every `mSlideSpeed` calls the frequency moves by `mSlideStep` (shared) towards `mSlideFloor` (down) or `mSlideCeil` (up, if the voice's `mSlideUp` bit is set). With bits 3-5 (`C_SLIDE_DELAY`) the slide waits `mSlideDelayNSet` ticks after each note. The voice 3 variables are not laid out like the others (`mSlideCeil3` at $73E6, `mSlideDelay3` at $73D9), and no voice 3 command turns its slide on.

## Bugs and oddities

- Voice 2 `$D1`: loads 1 for the timer but never stores it (`$7C6E`).
- Voice 2 `$D8`: no `JMP` after the handler, so it falls into the `$D2` test with A = pulse high byte. Harmless, since a pulse high byte is never $D2.
- `PlayDone` is a `JMP` to the next instruction; `UnusedRts` ($7A57) is never reached.
- Many variable slots in $73A0-$7447 are never used (reserved space in the layout).

## Tuning

`FreqTable` is the NTSC table from the C64 Programmer's Reference Guide (C5 = $2187). See `tuning_and_timing.md`.
