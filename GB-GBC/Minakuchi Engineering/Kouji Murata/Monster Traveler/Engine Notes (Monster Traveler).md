# Engine Notes — Monster Traveler

Monster Traveler (J) (V1.1) [C][!] — Kouji Murata / Minakuchi Engineering.

This is the last of the seven games and by far the furthest from the original
Bionic Commando / Mega Man III engine. The skeleton is still recognisable —
song table, per-track RAM blocks, a voice-command jump table, a shadow set of
NR registers written out once a frame — but the sequence format has been
rewritten from scratch and several parts of the player work differently.

Everything below is relative to the Mega Man III / Pocket King versions of the
engine, which the earlier notes describe.

## Where everything lives

| | |
|---|---|
| Engine, tables, most data | bank `$C0` |
| Extra channel data | banks `$C1`–`$C5` |
| `GetSeqByte` | ROM0 `$3E4C` |
| Track RAM | `$DE00`–`$DF07`, `$DF20`–`$DF77` |
| Variables | `$DF08`–`$DF1F` |
| Register shadows | `$DF78`–`$DF8E` |

The audio RAM sits in the `$D000` half of WRAM, so on a Game Boy Color it is
in a switchable WRAM bank.

## Bank switching

Pocket King put the data bank in each track's RAM block and had `GetSeqByte`
read it from there. Monster Traveler still keeps a copy per track (offset
`$2B`), but `ProcTrack` copies it into a single global, `SeqBank` (`$DF8E`),
before stepping the track, and `GetSeqByte` reads that global:

```
GetSeqByte:
	ld a, [SeqBank]
	ldh [$FF9C], a          ;the game's own copy of the current bank
	ld [$2000], a
	ld a, [bc]
	push af
	ld a, $C0
	ldh [$FF9C], a
	ld [$2000], a
	pop af
	ret
```

There is no `SetRomBank` helper — `GetSeqByte` writes `$2000` itself, and it
is the only routine in the whole engine that touches the MBC. Only the low
bank register is written, which is fine because every bank number involved
fits in eight bits.

## Track RAM

Each track block is `$2C` bytes, and the eight blocks are **not** contiguous:
tracks 0–5 run from `$DE00` to `$DF07`, the variable block sits at
`$DF08`–`$DF1F`, and tracks 6 and 7 follow at `$DF20` and `$DF4C`. As in
Pocket King the engine reaches them through a pointer table (`TrackRAMPtrs`,
`$48A0`) rather than by scaling the track number.

| Offset | Field | Offset | Field |
|---|---|---|---|
| `$00` | MusNum | `$16` | VolDelay |
| `$01` | Priority | `$17` | (unused) |
| `$02` | Sweep | `$18` | PitchVal |
| `$03` | Transpose | `$19` | FreqOut (2) |
| `$04` | Tuning | `$1B` | Freq (2) |
| `$05` | PanMode | `$1D` | VolVal |
| `$06` | Panning | `$1E` | SongPos (2) |
| `$07` | Gate (2) | `$20` | Repeat1Start (2) |
| `$09` | NoteDelay (2) | `$22` | Repeat2Start (2) |
| `$0B` | Speed | `$24` | Macro1Pos (2) |
| `$0C` | DutyVol | `$26` | Macro2Pos (2) |
| `$0D` | (write only) | `$28` | Repeat1Times |
| `$0E` | (unused) | `$29` | Repeat2Times |
| `$0F` | PitchSeqPtr (2) | `$2A` | Flags |
| `$11` | VolSeqPtr (2) | `$2B` | DataBank |
| `$13` | PitchSeqPos | | |
| `$14` | VolSeqPos | | |
| `$15` | PitchDelay | | |

Both note counters are now sixteen bits. `Gate` is how long the note sounds
and `NoteDelay` is how long until the next command, and both are counted down
every frame by `ProcTrack`.

## Song table and headers

`SongTab` at `$48F8` has 144 entries. A header is

```
db  channel mask
db  priority
db  ROM bank holding this entry's channel data
dw  sequence pointer   ;one per set mask bit
```

which is the three-byte Pocket King header. Mask bit 0 is music channel 1 and
bit 7 is sound effect channel 4, so music entries use mask `$0F` and effects
use `$10`, `$30`, `$80` or `$90`. Entries `$00` and `$0D` have a mask of zero
and never play; `$0E` and `$0F` point every one of their channels at an empty
track and exist to silence the music or the effects.

Headers are not all in one run — they are scattered through the data area of
bank `$C0` in several groups, and 29 of the 144 table entries share a header
with another entry.

## Sequence format

This is the part that has been rewritten. The note/command split is at `$80`,
not `$C0`/`$D0`/`$E0`:

* `$00`–`$7F` — a note, `$00` being a rest. The note number plus `Transpose`
  indexes `FreqTab`.
* `$80`–`$9F` — voice command, dispatched through `VCMDTab` at `$440B`.
* `$FF` — end of track. It is checked before the table lookup, so it is not a
  table entry.

**Every note is followed by two lengths**, read by `GetLength` at `$43A4`:
the gate time and then the step time. Each is one byte when bit 7 is clear,
or a fifteen-bit value built from two bytes when bit 7 of the first byte is
set. A note is therefore three, four or five bytes long. No earlier game in
the family has a gate time at all.

`Speed` (`$0B`) multiplies both lengths, so it works as a tempo divider rather
than the per-note length of the earlier games.

### Voice commands

| | | |
|---|---|---|
| `$80 xx` | writes offset `$0D`, which nothing reads back | 2 |
| `$81 xx` | transpose | 2 |
| `$82 xx` | duty cycle and volume (waveform number on channel 3) | 2 |
| `$83 xx` | tuning | 2 |
| `$84 xx` | panning mode | 2 |
| `$85 xx` | duty cycle, or noise mode on effect channel 4 | 2 |
| `$86 xx` | unimplemented | 2 |
| `$87 xx` | speed | 2 |
| `$88 xx` | frequency sweep | 2 |
| `$89` | sweep off | 1 |
| `$8A`, `$8B` | unimplemented | 2 |
| `$8C ll hh` | set pitch sequence pointer | 3 |
| `$8D` | unimplemented | 2 |
| `$8E ll hh` | set volume sequence pointer | 3 |
| `$8F`–`$91` | unimplemented | 2 |
| `$92 ll hh` | call macro 1 | 3 |
| `$93` | return from macro 1 | 1 |
| `$94` | unimplemented | 2 |
| `$95` | mark start of repeat 1 | 1 |
| `$96 xx` | end of repeat 1, `xx` times (`$00` = forever) | 2 |
| `$97`–`$99` | unimplemented | 2 |
| `$9A` | end of track | 1 |
| `$9B ll hh` | call macro 2 | 3 |
| `$9C` | return from macro 2 | 1 |
| `$9D` | mark start of repeat 2 | 1 |
| `$9E xx` | end of repeat 2 | 2 |
| `$9F` | end of track | 1 |

Twelve of the thirty-two slots point at `VCmdSkip`, which just steps past one
parameter byte. Songs loop with `$96 $00` (repeat forever), and the data
almost always has a dead `$FF` sitting after it that can never be reached.

The big change from every earlier game is `$8C` and `$8E`: instead of an index
into an `EnvSeqTab`/`VibTab` pointer table they carry a **full sixteen-bit
pointer**, and the sequence lives inline in the same data bank as the channel
that names it. There are no envelope or vibrato pointer tables at all.

### Envelope sequences

Two kinds, in slightly different formats.

**Pitch sequences** (`$8C`). The first byte is the delay before the first
step; delay/value pairs follow from offset 1, and `$FF` restarts the sequence
at offset 1, so it loops. Each value is a signed offset added to the note's
frequency, which is how the arpeggios and pitch slides are done.

**Volume sequences** (`$8E`). Delay/value pairs from offset 0. Each value is
written straight to the channel's NRx2 register. `$FE` is a one-byte control
that steps past itself, marking the loop point, and `$FF` holds the last value
until the next note.

## Panning

`Panning` (`$06`) is a two-bit value — 1 right, 2 left, 3 both — and the four
`ChanNPanTab` groups at `$45D7` hold the rNR51 AND mask for the channel plus
those three values. When `PanMode` (`$05`) is zero, `NextPan` flips the
panning between left and right before each note, so a track set that way
ping-pongs across the stereo field by itself. Nothing like this exists in any
of the earlier games.

## Output

`OutputTracks` at `$45E7` walks C along each channel's register block and
calls one small helper per register — `OutSweep`, `OutDuty`, `OutVol`,
`OutFreqLo`, `OutFreqHi` — with `SkipReg` stepping past registers a channel
does not use. Each channel takes its values from the sound effect track if
that track is playing and from the music track otherwise, the same override
scheme the earlier games use.

rNR50 is forced to `$77` every frame, and rNR51 is rebuilt from `TracksUsed`
and the panning shadow, so the engine owns the mixer completely.

## Percussion

Music channel 4 is a percussion track: `NextCommand` treats a note number on
track 3 as an index (masked to six bits) into `PercSongIDs` at `$48B8`, and
starts the sound effect it finds there instead of playing a note. Song table
entries `$01`–`$06` are those drums. Sound effect channel 4 (track 7) takes
the note number as a raw rNR43 value instead.

## Waveforms

`WaveTab` at `$6134` is a sixteen-entry pointer table into bank `$C0`; ten
distinct sixteen-byte waveforms follow it. The waveform number is the
channel 3 track's `DutyVol` field, and `LoadWaveMus`/`LoadWaveSFX` skip the
copy when the same waveform is already loaded.

## Assembling

`MT_1.ASM` through `MT_6.ASM` reassemble to the original banks `$C0`–`$C5`
byte for byte. `MT_1.ASM` has to come first — it carries all the defines and
the RAM layout.
