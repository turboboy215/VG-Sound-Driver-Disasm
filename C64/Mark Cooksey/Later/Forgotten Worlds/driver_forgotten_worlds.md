# Forgotten Worlds (1989 US Gold / Capcom): late driver

Source: `disasm/forgotten_worlds_sound.s`. Rip: `Forgotten_Worlds.sid`, PSID v2, load $E000-$FA4F, 2 songs, VBI (50 Hz).

## Two driver builds in one rip

| | Title build (`T_`) | In-game build (`G_`) |
|---|---|---|
| Rip song | 1 | 2 |
| Address | $E000-$EDA1 | $EE00-$FA4F |
| Instruments | 7 | 3 |
| Patterns | 21 | 18 |
| Pulse-width modulation | yes | no (columns still in the table, never read) |
| Filter presets + cutoff sweep | yes (`$69`/`$6A`) | no (`$69`/`$6A` point at a variable) |
| Vibrato, tie, transpose, repeats | yes | yes |
| Where it ran in the game | (unknown) | $C000 |

Each build holds one song. `Rip_Init` ($EDD0, the ripper's code) patches two `JMP`s to pick the build and calls its `Init` with A = 0. The song number indexes the track table directly, so only 0 is valid.

### The ripper's relocation errors

The in-game build was moved by the ripper from $C000 to $EE00 (`RIP_RELOC` = $2E00). Only addresses on code paths the in-game tune runs were fixed. The rest still point into $C000-$C2FF:

- 15 instruction operands: the stopped-driver exit in `G_Play`, the vibrato delay countdown, `G_Cmd_Stop`, `G_Cmd_Tie`, `G_Cmd_Nop62` and `G_Cmd_Restart`;
- 5 command table entries ($61, $62, $67, $69, $6A);
- the patched `JMP` in `G_CmdJump` still holds the snapshot value $C1D5 (= `G_Cmd_Rest` before relocation). That one is harmless because `G_Command` rewrites it before use.

The source writes these as `Label-RIP_RELOC`, so the intended target is readable and the bytes stay identical. None of them run while the in-game tune plays (no instrument has a vibrato delay, and the tune never uses `$61`, `$62`, `$67` or `$6B`). Played in a SID player, `CMD_STOP` would jump into empty memory at $C19F. These errors belong to the rip, not to the game.

## Entry points

| Offset | Routine |
|---|---|
| +$00 | `Init`: A = song (0); track pointers, timers = 2, clear the SID, volume 15, enable |
| +$03 | `Play`: once per frame; voices 2, 1, 0 |

`Play` saves and restores $FB/$FC (`zTrkPtr`), which is the only zero page it uses.

## Track and pattern data

Tracks and patterns use the same stream format. A track is usually a list of `CMD_CALL`s ending with `CMD_JUMP`; a pattern ends with `CMD_RETURN`.

**Note event (2 bytes)**

```
byte 0  bit 7     instrument bit 4
        bits 0-6  note $00-$5F (C0-B7); the current call's transpose is added
byte 1  bits 4-7  instrument bits 0-3
        bits 0-3  length index: DurTable[i] = frames, RelTable[i] = frames until the gate is released
```

Any byte 0 with bit 7 set is a note; $60-$7F are commands. Each event is read one frame before it starts (when the note timer reaches 1).

| Byte | Name | Params | Effect |
|---|---|---|---|
| $60 | `CMD_REST` | len | rest |
| $61 | `CMD_TIE` | | toggle tie: no release, and the next note does not retrigger (the gate is never cleared) |
| $62 | `CMD_NOP62` | x | stores x; nothing reads it |
| $63 | `CMD_VOLUME` | v | master volume (title build keeps the filter mode bits) |
| $64 | `CMD_CALL` | pat, trn | play pattern once with transpose trn |
| $65 | `CMD_CALLN` | cnt, pat, trn | play pattern cnt times (cnt 0 = once) |
| $66 | `CMD_RETURN` | | end of pattern; transpose back to 0 after the last repeat |
| $67 | `CMD_RESTART` | | back to the start of the track |
| $68 | `CMD_JUMP` | .word | continue at address |
| $69, $6A | `CMD_FILTER` | n | filter preset n (title build only) |
| $6B | `CMD_STOP` | | silence and disable the driver |

`$64` enters the `$65` handler after the count byte, so it reuses the count left by the last call (0 after any call has finished: play once). Calls do not nest: there is one return address per voice.

**Duration tables**

| Build | DurTable (frames) | RelTable (frames) |
|---|---|---|
| Title | 3 4 6 9 12 18 24 36 48 72 96 144 192 8 16 32 | 2 2 4 6 8 12 16 24 32 52 64 96 128 5 11 21 |
| In-game | 2 3 5 7 10 15 20 30 40 60 80 120 160 8 4 6 | 1 2 3 4 6 10 13 20 26 40 60 80 110 6 2 4 |

## Instruments

Stored as 11 column tables, one byte per instrument: `InsCtrl` (gate on), `InsCtrlRel` (gate off), `InsAD`, `InsSR`, `InsPwLo`, `InsPwHi`, `InsPwmStep`, `InsPwmLen`, `InsVibDepth`, `InsVibLen`, `InsVibDelay`.

- **PWM** (title build): the pulse width moves by `InsPwmStep` every frame, changing direction every `InsPwmLen` frames.
- **Vibrato**: after `InsVibDelay` frames the frequency moves by `mVibDepth` every frame, changing direction every `InsVibLen` frames. The depth doubles after the first change so the swing is centred on the note. The step is in raw frequency units, so it is wider in cents on low notes.
- The release writes `InsCtrlRel` (normally the same waveform without the gate).

## Filter (title build)

Presets 0-3, one column each: `FltMode` (SID_MODE_VOL high nibble), `FltRoute` (SID_RES_FILT, also used to test whether a voice is filtered), `FltCutoff`, `FltStep`, `FltLen`. A note on a filtered voice (not tied) restarts the cutoff, and the cutoff moves by `FltStep` per frame for `FltLen` frames, then back. All four presets in this tune have a step of 0, so the sweep never moves. Preset 0 routes no voice; with `mFilter` negative `SID_RES_FILT` gets $F0.

## Frequency table

96 entries, C0-B7, PAL tuned (A4 = $1D46 = 440.1 Hz). Two entries are off: D0 is $0128 (should be about $0139, a semitone flat) and B7 is $FD2E, because the correct value ($106D0) does not fit in 16 bits. Both builds have the same table.

## Bugs and oddities

- `sta mPlaying` without `,x` at the release (always voice 0); `mPlaying`, `mNote`, `mRest` and `mNop62` are written but never read.
- No `CLC` before adding the vibrato step (`T_VibApply`, `G_VibApply`), so a leftover carry sometimes adds 1.
- A rest re-arms the release timer with the previous note's release value (harmless).
- `G_Track_V2` is followed by two bytes (`$60,$0A`) that nothing reaches.
