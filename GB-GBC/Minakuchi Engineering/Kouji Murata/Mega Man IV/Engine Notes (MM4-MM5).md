# Kouji Murata sound engine — Mega Man IV and Mega Man V

Notes gathered while disassembling the two audio banks of each game. Everything
here is about how these two games differ from the engine already documented in
the Bionic Commando and Mega Man III disassemblies; the differences are **not**
repeated as comments in the ASM files except where a comment was needed to make
a routine readable.

## What was disassembled

| | Mega Man IV | Mega Man V |
|---|---|---|
| ROM | `Megaman IV (E).gb` | `Megaman V (E) [S].gb` |
| Audio bank 1 | `$02` → `MM4_1.ASM` | `$02` → `MM5_1.ASM` |
| Audio bank 2 | `$17` → `MM4_2.ASM` | `$17` → `MM5_2.ASM` |

Each bank holds a **complete, independent copy of the sound engine** plus its own
song table, sequence data, envelope/vibrato/waveform tables and frequency table.
The two copies are not shared code — the game maps whichever bank it needs into
`$4000` and calls through the four-entry jump vector at the start of it.

Labels in bank `$02` are prefixed `Audio1_` and labels in bank `$17` are prefixed
`Audio2_`, so both files can be assembled into the same ROM. The shared defines
and the audio RAM map live in file 1; file 2 relies on them, so file 1 is
included first.

Both banks of both games reassemble **byte-for-byte identical** to the original
ROMs.

## Engine lineage at a glance

| | Bionic Commando | Mega Man III | Mega Man IV | Mega Man V |
|---|---|---|---|---|
| Audio banks | 1 | 1 | 2 | 2 |
| Jump vector entries | 5 | 5 | 4 | 4 |
| Audio RAM base | `$C302` | `$DB02` | `$DB02` | `$DB02` |
| Variables before track RAM | 11 | 11 | **12** | **12** |
| Track RAM base | `$C30D` | `$DB0D` | **`$DB0E`** | **`$DB0E`** |
| Track RAM size | `$2C` | `$2C` | `$2C` | `$2C` |
| Song table entries | 61 | 83 | 112 per bank | 127 per bank |
| Envelope sequences | 17 | 18 | **20** | **20** |
| Vibrato table entries | 16 | 16 | 16 | 16 |
| Waveform table entries | 16 | 17 | 17 | 17 |
| Frequency table entries | 95 | 95 | 95 | 95 |
| Voice commands | `$E0`–`$FF` | `$E0`–`$FF` | `$E0`–`$FF` | `$E0`–`$FF`, **`$F4` used** |

## Engine code differences

### 1. A new "music playing" flag (`$DB0D`)

`CheckAllTracks` gained a tail that ORs the song-number byte of the four music
tracks together and stores the result in a new variable:

```
	ld hl, MusC1MusNum
	ld de, $2C
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

That one extra byte sits between `FadeTime` and the start of the track RAM, so
**every audio RAM address from the track blocks onwards is shifted up by one**
compared with Mega Man III and Bionic Commando. It is the only change to the
RAM layout; the per-track field order and the `$2C` stride are unchanged.

### 2. Song table entries may be blank

Mega Man III's song table is dense. In Mega Man IV and V a good number of slots
are `dw $0000` (19 and 22 in the two Mega Man IV banks, 18 and 15 in Mega Man
V's), so `LoadSong` gained a null check right after fetching the pointer:

```
	ld a, [hl+]
	ld h, [hl]
	ld l, a
	or h
	jr z, .LoadSongRet
```

`CallSFX` does not have the same check — percussion entries are never blank.

### 3. `A` is preserved across every pointer-table look-up

Mega Man III computes table pointers with the accumulator and lets it be
clobbered. Every one of those look-ups in Mega Man IV/V is wrapped in
`push af` / `pop af`:

```
	push af
	add a
	add LOW(SongTab)
	ld l, a
	ld a, HIGH(SongTab)
	adc 0
	ld h, a
	pop af
```

This happens at sixteen or seventeen sites per bank (song table, envelope state
table, VCMD table, frequency table, envelope-sequence table, vibrato table,
waveform table, channel/track masks, prep-state table, `Vol3LUT` and the four
duty/pan tables). It is behaviourally neutral in most of them — it looks like a
defensive change made once and applied everywhere.

### 4. `ProcNoteLen` gained a second entry point

`ProcNoteLen` starts by loading the channel's speed field:

```
ProcNoteLen:
	ld hl, $0B
	add hl, de
ProcNoteLen2:
	or a
	...
```

`EventVibrato` now does that set-up itself and jumps in at `ProcNoteLen2`:

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

The net effect is the same; it just avoids recomputing `hl`.

### 5. Mega Man V only: a new voice command in slot `$F4`

`$F4` and `$F5` are both `EventNop` in Bionic Commando, Mega Man III and Mega
Man IV. In Mega Man V, `$F4` points at a new handler (`EventAddParam` in the
disassembly):

```
	db $F4, <offset>, <value>
```

It adds a signed byte to one of the current channel's RAM fields, selected by a
raw offset into the track block:

```
EventAddParam:
	inc bc
	ld a, [bc]			;parameter 1 = offset into the channel's RAM block
	push af
	ld l, a
	xor a
	ld h, a
	add hl, de
	inc bc
	ld a, [bc]			;parameter 2 = value to add (signed)
	add [hl]
	ld [hl], a
	pop af
	cp $11				;offset $11 = envelope value
	jr z, .ReloadEnv
	jp EventNop
.ReloadEnv
	ld a, [hl]
	jp GetEnvSeq2
```

If the offset is `$11` (the envelope value field) the envelope sequence pointer
is reloaded from the new value, so the command doubles as a relative
"change envelope" command. `$F5` remains a plain nop.

The command is used sparingly — four times in bank `$02` and fourteen times in
bank `$17`. It is three bytes long, which matters when reading the sequence
data: a tool written against the Mega Man III command lengths will desynchronise
on it.

### 6. Mega Man V only: `NoAudio` is entered one instruction early

Mega Man V has a three-byte stub immediately in front of `NoAudio`:

```
NoAudio2:
	call NoAudio
NoAudio:
	push bc
	...
```

`LoadSong` (song number 0) and `PlayAudio`'s fade-out path both jump to
`NoAudio2`, so the silence routine runs, returns, and then falls straight
through and runs again. Harmless, but it looks unintentional. Mega Man IV jumps
straight to `NoAudio`.

### 7. No other code changes

Every other instruction in the engine matches Mega Man III's, including all the
immediate constants. The only immediates that differ are the `LOW()`/`HIGH()`
halves of table addresses. The `Extra` routine that Mega Man III and Bionic
Commando expose as a fifth jump-vector entry is gone; the vector is four entries
in both of these games, and in bank `$17` the fourth entry is a bare `ret`.

## Data and format differences

* **Frequency table** — byte-identical to Mega Man III's (95 entries) in all
  four banks.
* **Waveforms** — the 17-entry table is laid out the same way (entries `$09`–`$0F`
  share one row, `$10` is separate), but the shared row differs:
  Mega Man III uses `$01 $23 $45 $67 $89 $AB $CD $EF $ED $CB $A9 $87 $65 $43 $21 $00`,
  Mega Man IV/V use `$13 $57 $9B $DF $00 $00 $00 $00 $13 $57 $9B $DF $00 $00 $00 $00`.
  All other waveforms are unchanged.
* **Vibrato table** — still 16 entries, but Mega Man III has nine distinct
  sequences (`0`–`7`, plus one shared by `8`–`F`); Mega Man IV/V have eleven
  (`0`–`9` distinct, `A`–`F` shared). `Vibrato0`–`Vibrato7` and the shared
  `A`–`F` entry are unchanged; `Vibrato8` and `Vibrato9` are new:
  * `Vibrato8`: `$81 $91 $A1 $B1 $C1 $D1 $E1 $F1 $0F $0F $0F $0F $0F $0F`
  * `Vibrato9`: `$31 $21 $11 $0F $0F $0F $0F $0F $0F`
* **Envelope sequences** — 20 entries instead of 18. `EnvSeq00`–`$0F` are
  unchanged, `EnvSeq10` and `EnvSeq11` were rewritten, and `EnvSeq12`/`EnvSeq13`
  are new:
  * `EnvSeq10`: `$22 $82 $43 $2F` → `$B2 $52 $92 $42 $72 $32 $52 $22`
  * `EnvSeq11`: `$92 $42 $62 $5F` → `$92 $42 $72 $32 $52 $22 $32 $12`
  * `EnvSeq12` (new): `$B3` then `$43 $63` repeated ten times, then `$43`
  * `EnvSeq13` (new): `$83` then `$23 $43` repeated ten times, then `$23`

  (All four are `$FF`-terminated as usual.)
* **Song headers** — unchanged in format (`db` channel mask, `db` priority, then
  one `dw` per set mask bit, low bits = music channels 1–4, high bits = SFX
  channels 1–4). Entry `$00` is the silent entry and entry `$0A` is still the
  fade-out slot handled specially by `LoadSong`; both carry a `dw` pointing at
  the empty sequence that is never read.
* **Leftover data** — each of the four banks contains exactly two song headers
  that nothing in the song table points at, plus the sequence data they
  reference. They are labelled `AudioN_UnusedSong00`/`01` in the disassembly.
  There are also a handful of orphaned sequence blocks (`AudioN_UnusedData_xxxx`)
  and, at the end of each bank, unused padding.

## The game-specific routine (bank `$02` only)

The fourth jump-vector entry in bank `$02` leads to the same kind of
stage-music selector Mega Man III has, expanded a little. It clears two request
flags as it reads them, picks a boss theme from the current stage number, looks
the stage theme up in `StageMusIDs`, and then calls three routines in the game's
own ROM0 bank (`$01C5`, `$0222`, `$0225`). Those are stubbed out as
`StageMacro1`–`3` in `FUNCTION.ASM`, exactly as Mega Man III's `StageMacro` is.

The game-side RAM addresses it touches are given descriptive names
(`CurStage`, `BossMus`, `StageMus`, `StageMusFlag`, `BossMusFlag`,
`LabMusIndex`) but those names are educated guesses — confirming them needs the
rest of the game.

### `$FF` and `$00` in the stage-music tables

Both tables use `$FF` and `$00` as "no music", but they are handled by
different paths and mean different things:

```
StartStageMus:
	cp $FF
	ret z			;<-- $FF stops here
	push af
	call InitSound
	call StageMacro1
	pop af
	ld [StageMus], a
	call StageMacro2
	jp StageMacro3
```

* **`$FF` — leave the audio alone.** The routine returns immediately.
  `InitSound` is never called, `StageMus` is never written, and none of the
  three game routines run. Whatever was already playing carries on untouched.
* **`$00` — stop the music.** The entry falls through the whole sequence:
  `InitSound` runs (`AudioOff` plus the RAM reset — NR50 zeroed, NR52 reset,
  all four hardware channels and all eight track blocks cleared), `StageMus` is
  set to 0, and `StageMacro1`–`3` all run. `$00` is also the silent song-table
  entry, so a later `LoadSong` with it lands on `NoAudio`.

So the distinction is "this room inherits whatever was playing" versus "this
room actively kills the music and goes through the normal change sequence".
Mega Man IV's table has eleven `$FF` entries and five `$00` entries (one of them
dead — see below); Mega Man V's has ten and six.

The boss-music half of the routine stores the same two values into `BossMus`
(`$FF` when `BossMusFlag` was set, `$00` for stages `$15` and `$0E` in Mega Man
IV), but that byte is only read by code outside these banks, so whether the same
convention holds there is still unconfirmed.

### Dr. Light's lab

Stage `$10` is Dr. Light's lab. It is intercepted before the main table is
indexed:

```
	ld a, [CurStage]
	cp $10
	jp z, GetLabMus
```

`GetLabMus` reads a five-entry table (`LabMusIDs`) with `LabMusIndex` masked to
three bits, then rejoins `StartStageMus`, so `$FF` and `$00` behave there
exactly as above. The two games use the same shape:

```
Mega Man IV:  $69 $69 $66 $FF $69
Mega Man V:   $78 $78 $79 $FF $78
```

Two quirks fall out of this:

* **The main table's slot for stage `$10` is dead** in both games — the `cp $10`
  diverts before the lookup, so the `$00` sitting in that slot is never read.
  It looks like a leftover from before the lab got its own table.
* **Mega Man V's lab table is not a separate table.** It is read from
  `StageMusIDs+36`, i.e. the tail of the main table, so the lab entries share
  their bytes with stages `$25`–`$29`. The disassembly puts a second label
  (`LabMusIDs`) at that offset rather than writing the arithmetic out. Mega Man
  IV's lab table is a separate five-byte table sitting after `GetLabMus`.
* The masked index allows 0–7 but only five entries exist, so values above 4
  run off the end — into the song table in Mega Man IV, into `SetStageMus`'s own
  code in Mega Man V. `LabMusIndex` is presumably never above 4.

In bank `$17` the fourth vector entry is a bare `ret` — that bank has no
game-specific hook.

## How this was verified

Each bank was reassembled with RGBDS and compared byte-for-byte against the
original ROM; all four banks match exactly, with no `db`-filled gaps. The
included player ROMs were then booted in an emulator and used to confirm that
both banks initialise, play music and sound effects, and switch cleanly.
