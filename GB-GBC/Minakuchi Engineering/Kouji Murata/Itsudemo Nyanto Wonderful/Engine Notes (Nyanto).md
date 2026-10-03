# Kouji Murata sound engine — Itsudemo Nyanto Wonderful

Notes from disassembling the audio in *Itsudemo Nyanto Wonderful* (J), covering
how it differs from the Bionic Commando / Mega Man III engine and from the
later Mega Man IV / V one.

## Where the audio lives

| | |
|---|---|
| ROM | `Itsudemo Nyanto Wonderful (J) [S][!].gb` — 256 KB, MBC3 + timer + RAM, SGB |
| Audio bank | `$0D` |
| Disassembled range | `$4000`–`$60EE` |
| Rest of the bank | `$60EF`–`$6BFF` is `$FF` padding; `$6C00` onwards is 2bpp tile graphics, left out |

`$4000`–`$60EE` reassembles **byte-for-byte identical** to the original ROM.

**There is no jump vector.** Every other game in this family starts its audio
bank with four or five `jp` instructions; here the song table sits at `$4000`
and the game calls the three entry points at their bare addresses:

| Routine | Address |
|---|---|
| `LoadSong` | `$4134` |
| `PlayAudio` | `$4204` |
| `InitSound` | `$4A9C` |

There is also no game-specific hook routine, and the engine makes no calls
outside the bank at all — so no `FUNCTION.ASM` stubs are needed to build it.

## Where the audio RAM lives

The RAM block is **rearranged** relative to every other game in the family. In
Bionic Commando, Mega Man III, IV and V the order is scalars → track blocks →
hardware-register mirrors. Here it is:

| Block | Address | Notes |
|---|---|---|
| Track blocks (8 × `$2C`) | `$C700`–`$C85F` | `MusC1RAM` = `$C700` |
| Register mirrors + copies + gate flags | `$C860`–`$C88D` | |
| *(unused)* | `$C88E`–`$C89F` | 18 bytes |
| Scalar variables | `$C8A0`–`$C8AB` | `CurTrack` = `$C8A0` |

It also sits in `WRAM0` (`$C000`–`$CFFF`) rather than the switchable
`WRAMX` bank the Mega Man games use.

## Engine lineage

This is essentially the **Bionic Commando / Mega Man III** engine — the voice
command table is identical, `$F4` and `$F5` are both `EventNop`, and the
pointer look-ups are *not* wrapped in `push af`/`pop af` the way Mega Man IV
and V wrap them. But two of the later games' changes are already present:

| | BC | MM3 | **Nyanto** | MM4 | MM5 |
|---|---|---|---|---|---|
| Jump vector entries | 5 | 5 | **none** | 4 | 4 |
| "Music playing" flag | – | – | **yes** | yes | yes |
| `ProcNoteLen` second entry point | – | – | **yes** | yes | yes |
| `push af`/`pop af` around look-ups | – | – | **–** | yes | yes |
| Blank song-table entries allowed | – | – | – | yes | yes |
| Added `$F4` voice command | – | – | – | – | yes |
| Fade-out song slot | `$0A` | `$0A` | **`$06`** | `$0A` | `$0A` |

### 1. The "music playing" flag (`$C8AB`)

`CheckAllTracks` ends by ORing the song-number byte of the four music tracks
together and storing the result — the same addition Mega Man IV and V have:

```
	ld hl, MusC1MusNum
	ld de, TrackRAMSize
	ld a, [hl]
	add hl, de
	or [hl]
	add hl, de
	or [hl]
	add hl, de
	or [hl]
	ld [MusPlaying], a
	ret
```

### 2. `ProcNoteLen` has a second entry point

`EventVibrato` loads the channel's speed field itself and jumps in past
`ProcNoteLen`'s own set-up, exactly as in Mega Man IV and V:

```
EventVibrato:
	inc bc
	ld a, [bc]
	swap a
	and %00001111
	ld hl, $000B
	add hl, de
	call ProcNoteLen2
```

### 3. The fade-out slot is song `$06`

`LoadSong` checks `cp $06` where every other game in the family checks
`cp $0A`. This is the only genuine constant change anywhere in the engine —
every other immediate that differs from Mega Man III's is just the `LOW()` or
`HIGH()` half of a table address.

### 4. Byte-saving `inc l` / `inc e` in the register output

`OutputTracks` and its helpers advance through the register-mirror block with
`inc l` / `inc e` / `dec l` instead of `inc hl` / `inc de` / `dec hl`. The
block (`$C860`–`$C88D`) never crosses a page boundary, so only the low byte
ever changes and the shorter, faster form is safe. Mega Man III uses the
16-bit forms throughout. There are seven such sites.

Apart from those four things, every instruction matches Mega Man III's.

## Data differences

* **Frequency table** — byte-identical to Mega Man III's, 95 entries.
* **Envelope sequences** — 17 entries instead of 18. `EnvSeq00`–`$0F` are
  unchanged, `EnvSeq10` was rewritten (`$22 $82 $43 $2F` → `$84 $51 $21 $11`),
  and Mega Man III's `EnvSeq11` has no counterpart here.
* **Vibrato table** — still 16 entries but only eight distinct sequences.
  `Vibrato0`–`Vibrato6` are unchanged; `Vibrato7` through `VibratoF` all share
  one sequence (`$03 $13 $23 $13`), which is the entry Mega Man III shares
  across `8`–`F`. Mega Man III's own `Vibrato7` is not present.
* **Waveforms** — the table is 16 entries instead of 17, and holds only
  **three** distinct waveforms where Mega Man III has ten:

  | Entries | Waveform | Same as MM3's |
  |---|---|---|
  | `$00`–`$06` | `03 69 CF FC 96 30 03 56 77 65 44 33 20 00 52 00` | `Waveform06` |
  | `$07`–`$08` | `01 11 12 23 34 45 56 67 78 89 9A AB BC CD DD D0` | `Waveform08` |
  | `$09`–`$0F` | `01 23 45 67 89 AB CD EF ED CB A9 87 65 43 21 00` | `Waveform00` |

## The song table

37 entries (`$00`–`$24`), in clean blocks:

| Range | Contents |
|---|---|
| `$00` | silence (channel mask `%00000000`) |
| `$01`–`$05` | percussion, played on SFX channel 4 by music channel 4 |
| `$06` | fade the current music out (handled specially by `LoadSong`) |
| `$07` | empty entry covering the four music channels, priority 2 |
| `$08` | empty entry covering the four SFX channels, priority 15 |
| `$09`–`$17` | sound effects (15) |
| `$18`–`$24` | music (13), all four music channels, priority 0 |

Entries `$00` and `$06` point at the same header, so the disassembly carries
both labels (`Perc_Empty` and `FadeOutTrack`) at that address, the way the
Mega Man III disassembly does.

Everything in the table is reachable and there is no leftover or orphaned
sequence data anywhere in the audio region — unlike Mega Man IV and V, which
each carry two unused song headers per bank.

## How this was verified

The bank was reassembled with RGBDS and compared byte-for-byte against the
original ROM across `$4000`–`$60EE`; it matches exactly, with no `db`-filled
gaps. The included player ROM was then booted in an emulator with randomized
WRAM (20 out of 20 clean boots), and every music entry and sound effect was
confirmed to play, with effects layering correctly over the music.
