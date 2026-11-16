# Paperboy (1986 Elite): middle driver

Source: `disasm/paperboy_sound.s`. Rip: `Paperboy.sid`, PSID v2, load $A5FE-$C017, 5 rip songs, CIA timing, PAL, 6581.

## Memory map

| Range | Contents |
|---|---|
| $A5FE-$A6CE | music variables (per-voice arrays of 3) |
| $A6CF-$B069 | player |
| $B06A | `Play` (the PSID play address) |
| $B0C5-$B104 | drum table and the one drum |
| $B108-$B10F | sound effect variables |
| $B110-$B257 | sound effect player |
| $B258-$B4E1 | sound effect table and 9 distinct effects |
| $B4E6-$BFDF | 4 songs: init routine, order lists, patterns |
| $BFE0-$C017 | SID ripper wrapper and its song table |

Zero page: `zPat1` $92, `zPat2` $94, `zPat3` $4B (pattern pointers, not in order), `zOrder` $4F, `zCmd` $51 (command/drum data), `zSfx` $96. $4D/$4E are written before every voice and never read (left over from Bomb Jack, where $4D was the voice 2 pointer).

## Compared with Bomb Jack

Same pattern idea (length byte + note byte, `$00` ends a pattern, commands from `$C8`, order lists of `.word`s ending with a high byte of 0), same octave-5 table with shifts. New:

- one player loop indexed by voice (`SelectV1/2/3` set `mVoice`, `mRegOfs`, `mVoiceBit`), all variables are 3-byte arrays;
- commands dispatched through `CmdTable` and `JMP (mCmdVector)`, the same commands work on every voice, and every command has a defined length;
- per-voice effects with their own speed and delay: pulse sweep, octave trill, vibrato, slide, waveform alternation;
- a gate release point (`C_RELEASE`): the gate goes off when that many ticks of the note are left;
- drum macros with step lists, and a sound effect player;
- PAL tuning (C5 = $22D2 = 523.5 Hz).

## Entry points and timing

| Entry | Use |
|---|---|
| `Song0_Init` $B4E6 ... `Song3_Init` $BD4C | start a song. They begin with `SEI` and never `CLI`. |
| `Play` $B06A | call at the song's rate |
| `sRequest` $B108 | the game writes 1-15 here to start a sound effect |

`Play` order: `Patterns` (every `mSpeed` calls = one tick), `WriteRegs`, `Effects`, `WriteRegs` again, then the drum steps (every `mDrumSpeed` calls), then `Sfx_Update`.

The ripper's wrapper sets CIA 1 timer A per song:

| Rip song | Init | Timer | Rate (PAL) |
|---|---|---|---|
| 1 | Song0 | $1997 | 150.4 Hz |
| 2 | Song0 | $4CC7 | 50.1 Hz |
| 3 | Song1 | $4CC7 | 50.1 Hz |
| 4 | Song2 | $4CC7 | 50.1 Hz |
| 5 | Song3 | $2663 | 100.3 Hz |

So rip songs 1 and 2 are the same tune at two speeds. The driver itself has no notion of the call rate.

## Pattern format

| Bytes | Meaning |
|---|---|
| `$00` | end of pattern |
| `$01-$C7`, `nn` | note of that many ticks; `nn` bits 0-3 semitone (1 = C ... 12 = B, 0 = rest), bits 4-6 octave |
| `$C8-$DE` [params] | command (bytes $DF-$EF would jump through garbage) |
| `$F0-$FF`, `len` | drum (`C_DRUM`+n) for `len` ticks |

A note writes the control register with the gate off and then on, if the voice's `mOutputOn` bit is set, sets the frequency and the vibrato base, and restarts all effect delays (`NoteResetFx`). A rest (`nn` = 0) only writes the gate off.

### Commands

| Byte | Name | Params | Effect |
|---|---|---|---|
| $C8 | `C_VOLUME` | v | volume (`mModeVol` low nibble kept with the filter mode) |
| $C9 | `C_SPEED` | s | calls per tick |
| $CA | `C_AD` | ad | attack/decay |
| $CB | `C_SR` | sr | sustain/release |
| $CC | `C_WAVE` | w | control value without gate |
| $CD | `C_PULSE` | hi, lo | pulse width |
| $CE | `C_FILTER` | mode, cut hi, cut lo | route this voice into the filter; mode ORed into SID_MODE_VOL |
| $CF | `C_PWSWEEP` | speed, delay, step hi, step lo, reset | pulse sweep on; reset ≠ 0 restarts the pulse at each note |
| $D0 | `C_TRILL` | speed, delay | octave trill on |
| $D1 | `C_VIBRATO` | speed, delay, depth hi, depth lo | vibrato on (4 phases: base, +depth, base, -depth) |
| $D2 | `C_SLIDE` | delay, from note, to note | slide on |
| $D3 | `C_WAVEALT` | speed, delay, wave A, wave B | alternate two control values (gate bit kept) |
| $D4 | `C_PWSWEEP_OFF` | | also clears the pulse reset bit |
| $D5 | `C_TRILL_OFF` | | |
| $D6 | `C_VIBRATO_OFF` | | |
| $D7 | `C_SLIDE_OFF` | | does nothing: slides end themselves at the target |
| $D8 | `C_WAVEALT_OFF` | | |
| $D9 | `C_FILTER_OFF` | | take this voice out of the filter |
| $DA | `C_RELEASE` | n | release the gate when n ticks are left |
| $DB | `C_SLIDESTEP` | speed, step hi, step lo | slide rate |
| $DC | `C_PWRANGE` | start hi, lo, limit hi, lo | pulse sweep range (the limit low byte is never read) |
| $DD | `C_DRUMSPEED` | n | drum step every n calls |
| $DE | `C_STOP` | | all voices off (`mTrackOn` = `mOutputOn` = 0) |

All commands take no time: the next event is read in the same call.

## Drums

`DrumTable` has 5 entries ($F0-$F4) that all point at `Drum0`. A drum header is AD, SR, pulse hi, pulse lo, filter flag, control, freq hi, freq lo; the control value is written and then written again +1 (gate on). Then come steps of control, freq hi, freq lo, one every `mDrumSpeed` calls, until $FF. Drum bytes $F5-$FF would read past the table. While a drum plays the voice's effects and register writes are skipped and its pattern waits `len` ticks.

## Sound effects

Never triggered by the rip. `SfxTable` holds 16 pointers (entry 0 cannot be requested and repeats entry 1; 10-15 are all the same effect: 9 distinct effects). An effect is:

```
speed, AD1, SR1, pulse hi 1, pulse lo 1
0 | routing, mode, cutoff hi, cutoff lo      filter (routing -> SID_RES_FILT)
0 | flag, AD2, SR2, pulse hi 2, pulse lo 2   voice 2 used?
ctrl1, freq hi 1, freq lo 1 [, ctrl2, freq hi 2, freq lo 2]   first step
... more steps every `speed` calls ...
$FF                                          end
```

Starting an effect mutes music voice 1 only. A two-voice effect therefore shares voice 2 with the music, which keeps rewriting its frequency, pulse, AD and SR every call. At the end the player restores the filter shadows and turns music voices 1 **and** 2 back on. Every effect in the table is followed by a second, unused `$FF`.

## Bugs and oddities

- `WaveAltFlip`: `ORA mWaveB` without `,x`, so every voice gets voice 1's second waveform ($A932).
- `mSlideArmed` is one flag for all voices: any note sets it, the first slide to arrive clears it. A slide that arrives while it is clear does not snap to the target or switch off; it just stops moving.
- `SlideUpUnused` ($A85C) is never called. `$B065-$B069` is a leftover code fragment.
- `NOP` before each voice's pointer update (`V1_Nop` ...).
