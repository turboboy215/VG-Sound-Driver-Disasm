# Kouji Murata sound engine — Pocket King

Notes from disassembling the audio in *Pocket King* (J), covering how it differs
from the earlier games in this family.

## Where the audio lives

| | |
|---|---|
| ROM | `Pocket King (J) [C][!].gbc` — 2 MB, MBC5 + RAM + battery, GBC + SGB |
| Engine bank | `$0E` (`$4000`–`$5E0B`; game code follows from `$5E0C`) |
| Data banks | `$0E` and `$0F` — `$0F` is nothing but channel data |

Both ranges reassemble **byte-for-byte identical** to the original ROM.

There is no jump vector. The game calls the entry points directly:

| Routine | Address |
|---|---|
| `AudioOff` | `$4000` (start of the bank) |
| `LoadSong` | `$407A` — song number is passed in `SFXNum` (`$DEF2`), not in `A` |
| `FadeOutMus` | `$4136` |
| `CallSFX` | `$413F` — takes the number in `A` |
| `PlayAudio` | `$4165` |

There is no `InitSound`: nothing in the bank sets `NR50`, so the game does that
itself. The player ROM here calls `AudioOff`, then sets `NR50`/`NR50Val` and
forces `NewWave` to `$FF`.

## Bank switching is built into the engine

This is the big structural change. **Each song table entry names the ROM bank
its channel data lives in**, and every single byte of sequence data is fetched
through a trampoline in ROM0:

```
GetSeqByte:				;$3FBB in ROM0
	push hl
	ld hl, $002E		;this track's channel data bank
	add hl, de
	ld a, [hl]
	call SetRomBank		;$1499 - the game's generic MBC5 bank select
	ld a, [bc]			;read the byte
	push af
	ld a, $0E			;map the engine bank back in
	call SetRomBank
	pop af
	pop hl
	ret
```

So the bank is per-track state (offset `$2E` of each track's RAM block), set
from the song header when the track starts, and never changed afterwards — a
song's channel data is always entirely within one bank.

Both routines are stubbed in `FUNCTION.ASM` at their original addresses.

## The song header gained a third byte

```
	db %00001111		;Channel mask
	db 0				;Priority
	db $0F				;ROM bank holding this entry's channel data
	dw Mus43_A
	dw Mus43_B
	dw Mus43_C
	dw Mus43_D
```

Everything else about the header is unchanged.

## The track RAM blocks are no longer evenly spaced

Earlier games walk the track blocks with a fixed `$2C` stride. Pocket King's
blocks are `$30` bytes but the scalar variables sit *between* SFX channel 1 and
SFX channel 2, so the engine keeps a pointer table (`TrackRAMPtrs`) and looks
each block up by track number instead:

| Block | Address |
|---|---|
| Music channels 1–4 | `$DE00`, `$DE30`, `$DE60`, `$DE90` |
| SFX channel 1 | `$DEC0` |
| Scalar variables | `$DEF0`–`$DEFF` |
| SFX channels 2–4 | `$DF00`, `$DF30`, `$DF60` |
| Register mirrors | `$DF90` onwards |

## Field layout changes inside a track block

Two of Mega Man III's fields are gone and the note delay became 16-bit, so
everything from `$09` up shifts down by two:

| Field | MM3 | Pocket King |
|---|---|---|
| Note delay | `$07` (8-bit), note time at `$08` | **`$07`–`$08`, 16-bit** |
| Speed | `$0B` | `$09` |
| Duty/volume (and CH3 waveform) | `$0C` | `$0A` |
| Decay | `$0D` | `$0B` |
| Envelope value | `$11` | `$0F` |
| Song position | `$20` | `$20` (unchanged) |
| Channel data bank | – | **`$2E`** |

`ProcTrack` decrements the 16-bit delay properly — when the low byte wraps past
zero it borrows from `$08` — so a single note can now last longer than 255
ticks.

The per-track waveform number is a further consequence: Mega Man III keeps
`WaveformMus`/`WaveformSFX` as globals, but Pocket King reads the waveform out
of the CH3 track's own `$0A` field. Only `NewWave` (`$DEF7`) remains global.

## Command set changes

The note, rest and parameter-block encodings are unchanged, and so are the
boundaries (`< $C0` note, `$C0`–`$CF` rest, `$D0`–`$DF` parameters,
`$E0`–`$FF` voice commands). Three commands differ:

* **`$ED` is now always two bytes.** In Mega Man III it writes the CH3 waveform
  and consumes only one byte on any other track. Here it unconditionally stores
  its parameter into track offset `$0A`, so it is two bytes everywhere. A tool
  written against the Mega Man III lengths will desynchronise on it.
* **`$F4` is a real command** (two bytes) rather than a nop. It stores its
  parameter into track offset `$2D`, a flag byte the rest handler tests
  (`and %00001000`). `$F5` is still a one-byte nop.
* **`$EA` (sweep) masks its parameter with `%01111111`** before storing it.

`$F0` also gained the envelope-sequence reload that `$EE` has — if the value's
top bit is clear it re-reads the same byte as a sequence index — but the byte
count is unchanged.

## Other engine differences

* The **"music playing" flag** is present (`$DEFA`), built at the end of
  `CheckAllTracks` from the four music tracks' song numbers, as in Mega Man
  IV/V, Monster Traveler and Itsudemo Nyanto Wonderful.
* `ProcNoteLen` has the **second entry point** used by `EventVibrato`, as in the
  other later games.
* The channel-3 envelope states are dispatched through a **jump table**
  (`EnvStatesCh3`) instead of Mega Man III's `cp 1 / cp 2 / cp 3 / cp 4` chain.
* The **fade-out slot is song `$06`**, as in Itsudemo Nyanto Wonderful, rather
  than `$0A`.
* There are **no `push af`/`pop af` wrappers** around the pointer-table
  look-ups, so this is the Bionic Commando / Mega Man III lineage rather than
  the Mega Man IV/V one.

## The song table

96 entries (`$00`–`$5F`):

| Range | Contents |
|---|---|
| `$00` | silence |
| `$01`–`$05` | percussion, played on SFX channel 4 |
| `$06` | fade the current music out |
| `$07` | empty entry covering the four music channels |
| `$08` | empty entry covering the four SFX channels |
| `$09`–`$42` | sound effects (some take over the music channels at priority 14) |
| `$43`–`$5F` | music (29 tracks), all four music channels, priority 0 |

Entries `$00` and `$06` share a header, so both `Perc_Empty` and `FadeOutTrack`
label the same address. 24 of the entries name bank `$0F` for their data.

## The GBS rip

`Pocket King.gbs` is 94 subsongs — every table entry except `$00` (silence) and
`$06` (fade out). Subsong *n* is the *n*-th surviving entry, so subsong 1 is
song `$01` and subsong 94 is song `$5F`.

Because the engine switches banks by number, the rip remaps them: original bank
`$0E` becomes GBS bank 1 and `$0F` becomes bank 2, and the third byte of every
song header is rewritten to match. Nothing else in the data is touched — the
engine contains no hardcoded bank constants, so the only other place a bank
number appears is the `GetSeqByte` trampoline, which the rip supplies itself.

`INIT` wipes the engine's RAM, maps bank 1, silences the channels, sets
`NR50`, looks the subsong up in a 94-byte table and calls `LoadSong`. `PLAY`
re-maps bank 1 (the trampoline leaves other banks mapped) and calls
`PlayAudio`. Timing is V-blank; the title, author and copyright fields are
`<?>`.

All 94 subsongs were confirmed to start under emulation; 17 of them are
one-shot percussion or short effects that finish within a few frames.

## How this was verified

Both bank ranges were reassembled with RGBDS and compared byte-for-byte against
the original ROM — no differences, and no `db`-filled gaps. The player ROM was
booted with randomized WRAM (20/20 clean), all 29 music entries were confirmed
to start, and the sound effects layer over the music. The GBS was exercised by
driving its `INIT`/`PLAY` entry points from a test ROM.
