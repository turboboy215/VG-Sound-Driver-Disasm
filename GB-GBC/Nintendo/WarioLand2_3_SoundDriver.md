# Wario Land II / Wario Land 3 (GBC): sound driver

Disassembly of the sound driver shared by *Wario Land II* (`Wario Land II (U) [C][!].gbc`, `CGBWARIOLAND2`, MBC5, 2 MB) and *Wario Land 3* (`Wario Land 3 (JU) (M2) [C][!].gbc`, `WARIOLAND3`, MBC5, 2 MB). The sources in `GBAudioLab\Wario` rebuild the driver, all sound data and the home-bank glue of both games **byte-exact** with RGBDS 0.9.1 (`-Wall` clean).

| | Wario Land II | Wario Land 3 |
|---|---|---|
| Driver bank | `$18` (code `$4000–$50A5`, tables `$50A6–$5438`, `SoundTable` `$5439`) | `$0C` (code `$4000–$502A`, tables `$502B–$555D`, `SoundTable` `$555E`) |
| Data banks | `$18` (`$5B83–$7EEE`), `$19`, `$1A`, `$1B` (to `$5013`) | `$0C` (`$6726–$7DE8`), `$0D`, `$0E`, `$0F` (to `$7391`) |
| Home glue | `$3F00–$3FC2` | `$3F00–$3FC2` (same layout) |
| RAM | `$CD00–$CF7F` | `$D000–$D27F` in WRAM bank 3 (the game's wrappers set `SVBK` = 3) |
| Ids | SFX `$001–$0FF`, songs `$100–$136` | songs `$001–$100`, SFX `$101–$238` |
| Sounds | 207 distinct SFX, 55 songs | 58 songs, 254 distinct SFX |

**SFX before songs.** In *Wario Land II* the SFX ids come first (`$001–$0FF`) and the songs follow (`$100–$136`); the SFX data also comes first in the ROM. *Wario Land 3* reverses both: songs take ids `$001–$03A` (`$03B–$100` are fillers) and SFX start at `$101`, and the song data comes first (banks `$0C–$0E`) with the SFX data after it (`$0E–$0F`).

```
build_check.sh WL2 <rom>     # assemble, link over the ROM and compare; then link bare and compare the regions
build_check.sh WL3 <rom>
harness/build.sh WL2|WL3     # test ROM: the rebuilt banks plus a loop that calls Sound_Update every frame
harness/verify.py WL2|WL3 <rom> [song frames] [sfx frames]   # play every id, check every byte the driver reads
python tools/wlgen.py wl2|wl3 <rom> <outdir>                   # regenerate the sources
python tools/wlsongs.py wl2|wl3 <rom>                          # song lengths and loop points
python tools/wlcompare.py <wl2 rom> <wl3 rom>                  # sounds Wario Land 3 took from Wario Land II
```

---

## 1. Provenance

**Not related to Wario Land.** The first *Wario Land* runs the Metroid II driver (`Tanaka_Lineage_Metroid2_WarioLand_Sanrio2.md`, §2.6): fixed channels, a Tanaka-style song header, `$F1–$F5` commands and SFX written as code. Nothing of that survives here. There's no shared code, the data format is different, and the note table is a different construction (§3.8).

**A MIDI-derived format.** The sequence data reads like a direct conversion of Standard MIDI files:

- **Running status.** A byte below `$80` repeats the previous command with a new parameter, exactly as in MIDI. Most notes in the data are written this way.
- **Notes.** Notes carry a MIDI key number (`$3C` = C4) and a velocity.
- **Controllers.** The command set maps onto MIDI channel messages: program change, volume, pan, pitch bend, bend range and modulation (as an LFO).
- **Timing.** Delta times are quantised to a 49-entry table built around 24 ticks per quarter note.
- **Header extras.** Converter-made headers also list, for every track, its loop point and the address of its final `END`. The driver never reads these (§3.2).

**No sound credit or version text** in either ROM.

**Wario Land 3 is a revision of the Wario Land II driver.** Aligning the two drivers instruction by instruction, every routine has a counterpart. The changes are listed in §4. *Wario Land 3* also reuses Wario Land II material:

- 70 of its SFX are byte-identical (once pointers are made relative) to Wario Land II SFX, and 14 more are near-identical.
- 8 songs are taken over: `$16–$1B`, `$25` and `$36` are Wario Land II's `$120–$126` and `$135`, two of them (`$18`, `$25`) with small edits (§6).

---

## 2. API and integration

The home bank holds 13 six-byte stubs at `$3F00` (`call` lock, `jp` driver), the bank switch, a re-entrancy lock and the two data readers. All driver data access goes through `Snd_ReadByte`/`Snd_ReadWord`, which switch to `wSndBank`, read `[de]`, and switch back to the driver bank.

| Stub | Routine | In | Effect |
|---|---|---|---|
| `$3F00` | `Sound_Init` | | clear driver RAM (keeps the saved bank), tempo `$4A`, scales `$40`, APU on, NR50 `$77`, NR51 `$FF` |
| `$3F06` | `Sound_Update` | | one frame (§3.1) |
| `$3F0C` | `Sound_PlaySfx` | bc = id | start in the SFX slots; bc = 0: stop all SFX |
| `$3F12` | `Sound_PlayMusic` | bc = id | start in the music slots; bc = 0: pause the music |
| `$3F18` | `Sound_PlayMusicIfNew` | bc | play unless bc is the current music and a music slot is active |
| `$3F1E` | `Sound_StopSfx` | bc | stop every SFX slot playing id bc (bc = 0: all) |
| `$3F24` | `Sound_StopMusic` | | pause: music slots inactive, `wMusicPaused` = `$FF` |
| `$3F2A` | `Sound_ResumeMusic` | | reactivate the paused music slots where they stopped |
| `$3F30` | `Sound_GetActive` | | out d = active SFX slots (bits 0–3), e = active music slots |
| `$3F36` | `Sound_SetParam` | a, bc, d, e | §3.10 |
| `$3F3C` | `Sound_FadeOut` | a = frames per step | §3.10 |
| `$3F42` | `Sound_Query` | a | out bc: a = 0 current music id (0 if no music slot active); a = 1–4 id in SFX slot a−1 (0 if idle) |
| `$3F48` | `Sound_PlayOrResume` | bc | play if new, otherwise resume |

**Locking.** Every stub except `Sound_Update` goes through `Snd_Enter`:

- If `wSndFlags` bit 7 is already set, the call returns `a` = `$FF` and does nothing.
- Otherwise it sets the bit, saves the game's bank (`wRomBank`: HRAM `$FFA4` in *Wario Land II*, read and written with 3-byte loads; `$C5FF` in *Wario Land 3*) and selects the driver bank.

`Sound_Update` can arrive from an interrupt in the middle of another call. In that case `Snd_EnterUpdate` sets bit 6, stores its own return address in `wSndDeferred` and returns at once. `Snd_Exit`, at the end of the interrupted call, then jumps into the update before restoring the bank. A second update in the same window is dropped.

**Ids.** `LookupSound` aborts the call (pops its return address) for ids above `$136` (*Wario Land II*) or `$238` (*Wario Land 3*). Callers treat id 0 as "stop", so table entry 0 is never looked up.

**Game side.**

- *Wario Land II* calls the stubs directly. Its per-frame routine (`$122E`, from `$03F1`):
  1. takes an SFX request from `$FFAB/$FFAC`;
  2. takes a music request from `$C69A/$C69B` (`$FF` = stop) and passes it to `Sound_PlayOrResume`;
  3. runs `Sound_Update`.

  Pausing (`$1273`) stops the music and all SFX, and unpausing (`$128F`) resumes the music. `Sound_SetParam` 2 ducks the music to a quarter (`$10`) and restores it (`$40`), from banks `$13` and `$27`.
- *Wario Land 3* wraps every stub in a home routine (`$0FB0–$106F`) that selects WRAM bank 3 and restores the previous one.

---

## 3. Engine

### 3.1 Track slots, groups and timing

There are **8 track slots** of `$3C` bytes at `wTracks`. Slots 0–3 are the **SFX group** and slots 4–7 the **music group**. Each group has its own tempo:

- **Step.** Every frame the group adds `step = tempo × scale / 64` (clamped to 1–`$FF`) to an accumulator. Each time the accumulator reaches 74 (`$4A`), the group runs one tick.
- **Defaults.** Tempo `$4A` and scale `$40` give exactly one tick per frame.
- **BPM.** A quarter note is 24 ticks, so tempo *t* is *t* × 59.73 × 60 / (74 × 24) ≈ **2.02 × *t* BPM** (tempo 74 ≈ 149 BPM).

`TEMPO` sets the tempo of whichever group the track belongs to (`wSndFlags` bit 5 marks SFX processing). It is a group setting, not a per-track one.

`Sound_Update`, per frame:

1. `UpdateFade`.
2. **SFX group.** If no tick is due, every SFX track gets `TrackRefresh` (it applies parameter changes only). Otherwise, for each tick due: every channel owned by an SFX track counts down its gate (`TickSfxChannel`), then every SFX track runs `TrackTick`.
3. **Music group.** The same, with `TickMusicChannel`.
4. **Channels.** Every hardware channel runs `UpdateChannel`: envelope phase, then the register writes flagged dirty.
5. **Bookkeeping.** Advance the 15-frame counter `wFrame15` (§3.7), rebuild `wActiveMask` (bit *n* = slot *n* active) and clear the per-tick dirty bits.

**Track flags** (`TRK_FLAGS`):

| Bit | Meaning |
|---|---|
| 7 | active |
| 6 | started |
| 5 | claimed but not started yet (`$A0`) |
| 4 | drum kit (§3.6) |
| 2 | pitch dirty |
| 1 | volume dirty |
| 0 | pan dirty |

The first tick of a claimed slot (`StartTrack`) fetches the data pointer from the header and resets everything:

| Field | Reset to |
|---|---|
| attack/decay, sustain/release | `$FF` |
| volume | `$FF` |
| volume scale | `$40` |
| pan, bend | centre |
| bend range | 2 |
| LFO speed | `$17` |
| everything else | 0 |

The running status starts as 0, so the first byte of a track must be a command.

**Starting a sound.**

- **`Sound_PlaySfx`** uses the table entry's slot byte as the first SFX slot. The sound's tracks fill consecutive slots from there up to slot 3, and tracks that don't fit are dropped. A track replaces the slot's current sound if its priority is the same or higher; otherwise that track is skipped.
- **Slot byte bit 7** would instead take free slots first, then lower-priority ones (`PlaySfx_AutoSlot`). No table entry sets it.
- **`Sound_PlayMusic`** cancels the fade and fills slots 4 onwards, then frees the music slots it didn't use. The slot byte is ignored for music.

### 3.2 Sound table and headers

`SoundTable` has one entry per id:

```
SOUND  header, priority, slot, tracks        ; Wario Land II: dw header / db BANK(header), priority, slot, tracks
SOUND8 header, priority, slot, tracks        ; Wario Land 3:  dw header / db BANK(header), 0, priority, slot, tracks, 0
```

Every song has priority `$64`; SFX use `$C8–$FF`. Unused ids point at a placeholder:

- *Wario Land II*: 49 SFX ids point at SFX `$01`'s header.
- *Wario Land 3*: 199 song ids **and 58 SFX ids** point at **song `$01`**. An unused SFX id would play the title music in the SFX slots.

A header is:

```
Song_100::
	db 4, 2              ; track count, header type (0 or 2)
	dw Song_100_T0, ...  ; one pointer per track: the only part the driver reads
	dw ...               ; type 2 only: loop point of each track, then the address of its final END
```

The driver reads the count from the table, not the header, and skips the first two header bytes. The extra pointer sets of type-2 headers match the data: each track ends with `GOTO <loop point>` followed by an unreachable `END`, and the third set points at that `END`.

Some SFX headers are cut short and the next sound's data starts inside them, so they read `BD 00 BC 4A` (`TRANSPOSE 0, TEMPO 74`) as pointers (§5).

Data is laid out tracks first, header last, sound after sound.

### 3.3 Sequence bytes

| Byte | Meaning |
|---|---|
| `$00–$7F` | running status: parameter(s) for the last `$BE–$FF` command |
| `$80` | no-op (wait 0) |
| `$81–$B0` | `WAIT` `LengthTable[byte − $80]` ticks |
| `$B1–$CF` | commands (§3.4) |
| `$D0–$FF` | `NOTE`: gate = `LengthTable[byte − $CF]` ticks, then its parameters |

`LengthTable` (49 entries, the same in both games): 0–24, 28, 30, 32, 36, 40, 42, 44, 48, 52, 54, 56, 60, 64, 66, 68, 72, 76, 78, 80, 84, 88, 90, 92, 96. Only waits and notes use it.

**Note parameters.** A note command is followed by up to three bytes in any order, each recognised by its range:

| Range | Meaning |
|---|---|
| `$24–$7F` | key (MIDI number, C2 = `$24`) |
| `$00–$1F` | velocity *v* (stored as *v* × 8 + 7) |
| `$20–$23` | adds 32–35 ticks to the gate |

The list ends at the first byte ≥ `$80` or at the first range seen twice. That byte isn't consumed, so a second key starts a new note through running status. A note without a key reuses the track's last key, and one without a velocity reuses the last velocity.

**Time and chords.** Notes take no time; only waits advance the track. Several notes without a wait between them sound together, each on the channel its instrument selects. In practice:

- every note is `NOTE gate, key[, vel]`, `NOTE_ key[, vel]`, `NOTE_ vel` or `NOTE gate`;
- the gate extension is never used.

**Source macros.** A trailing underscore marks the running-status form of a command: `NOTE_ G3, 9` is `db G3, 9`. Waits and gates are written in ticks: `WAIT 12` assembles to `$8C`, `NOTE 24, C4` to `$E7 $3C`.

### 3.4 Commands

| Byte | Macro | Effect |
|---|---|---|
| `$B1` | `END` | free the track |
| `$B2` | `GOTO addr` | jump |
| `$B3` | `GOSUB addr` | call, 5 levels deep; a 6th nested call **ends the track** |
| `$B4` | `RETURN` | return; with nothing called it does nothing, which the data relies on (tracks start with "subroutines" that fall through) |
| `$B5` | `LOOP n, addr` | jump back until taken *n* − 1 times; *n* = 0 jumps always (unused) |
| `$BC` | `TEMPO t` | group tempo (§3.1) |
| `$BD` | `TRANSPOSE n` | semitones (signed), added to keys |
| `$BE` | `INSTRUMENT n` | load `InstrumentTable[n]`; *n* = 40 switches the track to the drum kit (§3.6) |
| `$BF` | `VOLUME n` | track volume, `TRK_VOLUME` = 2*n* |
| `$C0` | `PAN n` | < 32 left, 32–95 centre, ≥ 96 right (unused) |
| `$C1` | `BEND n` | pitch bend, 64 = centre, full range ± `BEND_RANGE` semitones |
| `$C2` | `BEND_RANGE n` | semitones (default 2) |
| `$C3` | `LFO_SPEED n` | added to the LFO phase every tick (triangle period 256/*n* ticks); 0 also re-centres |
| `$C4` | `LFO_DELAY n` | ticks after each note before the LFO moves |
| `$C5` | `LFO_DEPTH n` | ± *n*/64 semitone (pitch LFO) |
| `$C6` | `LFO_TYPE n` | 0 pitch; *Wario Land II* also 1 volume, 2 pan (data uses 0 only) |
| `$C9` | `DETUNE n` | fine pitch, 64 = centre, ± 1 semitone in 1/64 steps (unused) |
| `$CA` | `CMD_CA n` | stores `TRK_UNUSED_CA`, which nothing reads (unused) |
| `$CD` | `EXT sub, v` | `$01` type, `$0A` length, `$0B` sweep (instrument bytes 1–3); `$02/$03/$04/$05` attack/decay/sustain/release nibble; `$06/$07` echo level/rate (§3.7). Other subs end the track. Unused |
| `$CE` | `NOTE_HOLD` | a note with no gate, held until `NOTE_OFF` |
| `$CF` | `NOTE_OFF [key]` | release this track's held (`NOTE_HOLD`) note of that key |
| `$B6–$BB`, `$C7`, `$C8`, `$CB`, `$CC` | | undefined: end the track |

Commands `$BE–$FF` set the running status; `$B1–$BD` and waits don't.

**Usage in the data:**

| Commands | Used |
|---|---|
| `INSTRUMENT`, `VOLUME`, `TEMPO`, `TRANSPOSE` | at the start of almost every track |
| `BEND` | often as running-status runs (pitch slides) |
| `LFO_*` | in some songs |
| `NOTE_HOLD`/`NOTE_OFF` | 22/22 times in *Wario Land II*, 14/13 in *Wario Land 3* |
| `PAN`, `DETUNE`, `CMD_CA`, `EXT`, `LOOP` | never |

### 3.5 Channels and voice allocation

Tracks don't own hardware channels; **every note picks one**. The instrument's type byte selects it:

| Type byte | Channel | Low bits |
|---|---|---|
| `$00–$07` | ch1 | duty in bits 0–1 |
| `$08–$0F` | ch2 | duty in bits 0–1 |
| `$10–$3F` | ch3 | wave = type − `$10` |
| `$40+` | ch4 | bit 0 = 7-bit noise |

`NoteOn` decides as follows:

- **Free or releasing channel** (`CH_FLAGS` bit 5 clear): it is taken at once.
- **Held note on the channel:** the new note takes it only if its track priority is higher, or equal with an owner byte ≥ the current one. The owner byte is 4 − the slot's index in its group (slot 0 = 4), plus `$80` for SFX tracks, so at equal priority the lower slot wins. Otherwise the note is dropped.

So SFX (`$C8+`) always beat music (`$64`). Music gets the channel back at its next note after the SFX note has started to release. A channel whose owning track is no longer active is freed on the next frame, so pausing the music silences it.

Channel record (`CH_*`, `$18` bytes at `wChannels`):

| Field | Content |
|---|---|
| flags | active, new note, held, envelope ramp |
| priority, owner | from the track (§3.5) |
| key | as transposed |
| track | owning track pointer |
| velocity, gate | from the note |
| instrument | the 5 instrument bytes |
| pitch key | for drums, the kit's key |
| level, NRx2 image, envelope timer, NRx4 image | envelope state (§3.7) |

### 3.6 Instruments, waves and the drum kit

`InstrumentTable` entries are 6 bytes (`INST type, length, sweep, AD, SR, drum key`): 110 entries in *Wario Land II*, 123 in *Wario Land 3*.

- **Length.** 0 = no length counter. Otherwise NRx1 = −*n* (ch1/2/4: 6 bits, ch3: 8 bits) with the length enable set.
- **Sweep.** NR10 (ch1). For ch2 the byte goes to the unused register `$FF15`.
- **AD / SR.** Four envelope nibbles (§3.7).
- **Drum key.** Read only by the drum kit. Normal instruments hold `$3C`.

At a note start, `WriteChannelSetup` writes these:

- ch1/ch2: duty/length, NRx4 length enable and sweep;
- ch3: length and the wave, copied to wave RAM only when it differs from `wCurWave`;
- ch4: width bit and length, then a trigger.

**Drum kit.** `INSTRUMENT 40` sets track flag 4 (any other `INSTRUMENT` clears it). From then on each note's key *k* loads instrument *k* + 4, and the note plays at that instrument's drum key. Entries 40 and up are the kit: keys `$24–$69` in *Wario Land II*, `$24–$76` in *Wario Land 3*. Entry 40 is also the kit's first drum (key `$24`).

**Waves.** 16 bytes each, 11 in *Wario Land II*, 12 in *Wario Land 3*. **The last wave runs into `SoundTable`:** its final bytes are table entry 0, which is never looked up:

- *Wario Land II*: wave 10 = 10 bytes + entry 0's six zero bytes. Instrument 99 uses it.
- *Wario Land 3*: wave 11 = 8 bytes + entry 0's 8 bytes (`56 64 44 43 32 22 21 10`), the second half of a sine-like shape. Instrument 95 uses it.

### 3.7 Envelopes

The volume shape is an ADSR built from the hardware envelope. Each phase writes NRx2 with a start level and a direction/rate, then retriggers. The driver counts envelope steps in software to know when to change phase.

**Rates.** `CH_TIMER` advances once per frame, and twice every 15th frame, to follow the 64 Hz envelope clock at 59.7 frames per second. A nibble *N* gives the hardware rate `(~N >> 1) & 7`, where rate 0 means instant: `F` and `E` are instant, `D` is the fastest real rate, `0`/`1` the slowest.

**Levels.**

| Level | Formula |
|---|---|
| Velocity *V* | `(v × 8 + 7) >> 4` |
| Track volume `VOLOUT` | `((2n >> 4) × (scale >> 4) + 15) & $F0` × 4, saturated at `$FF` |
| Peak | `(VOLOUT >> 4) × V`, rounded up to a nibble |
| Sustain | `S × V`, rounded up, then `× VOLOUT` the same way |

With the default scale, `VOLOUT` only takes 5 values (0, `$40`, `$80`, `$C0`, `$FF` for *n* = 0–7, 8–39, 40–71, 72–103, 104–127).

**Phases.**

1. **Attack** (A): rises from 0 at the attack rate until the peak (instant if the rate is 0).
2. **Decay** (D): falls at the decay rate to the sustain level. With rate 0 it jumps there; with sustain 0 it goes straight to the end.
3. **Sustain** (S): held while the gate runs. The gate counts the owner group's ticks.
4. **Release** (R): starts when the gate ends or at `NOTE_OFF`; falls at the release rate. A note whose gate ends before its first frame is cut at once.
5. **End:** if the track's echo level, echo rate and volume are all nonzero, the note restarts once at a steady echo level (volume × echo level) with the echo rate in `CH_TIMER`. Otherwise the channel is freed.

**Echo** is never used: no data and no game call sets it. As written, the echo countdown is cancelled by the per-frame timer advance, so the channel would stay allocated (but stealable) until the timer wraps.

**Ch3** has no envelope unit. Its level's top two bits drive NR32 (100 / 50 / 25 % / mute), and NR32 is rewritten whenever the level crosses one of those steps.

### 3.8 Pitch

**Final pitch.** The pitch is recomputed only when pitch-dirty. `TRK_PITCH` (8.8 semitones) is the sum of:

- detune × 2 (signed);
- the bend: (*n* − 64)/64 × range semitones for `BEND n`;
- the API pitch offset;
- the pitch LFO.

The key played is `CH_PITCHKEY + high byte`. Ch3 adds 12, because its period counts double.

**Period.** `KeyToPeriod` returns a period and a slope, and `WritePitch` adds `fraction × slope / 256` for the semitone fraction. NRx3/NRx4 are written without a trigger (the trigger value is kept for the volume writes).

- *Wario Land II*: `PitchTable` holds one octave, C2–B2, as `$800`-relative offsets with slopes. `period = $800 + offset >> octave` (rounded in the last shift), and the slope halves too. Keys are clamped to `$24–$A7`.
- *Wario Land 3*: `PitchTable` holds 120 explicit periods with slopes, keys `$24–$9B` (C2 = `$02C` … `$7FE`). The values agree with the Wario Land II calculation, but no shifting is needed.

**Noise (ch4).** The key maps straight to NR43. With *x* = `~(key − 13)`, the divisor code is *x* & 3; for keys up to `$4C` (*x* ≥ `$C0`) it gains bit 2 and the shift is bits 2–5 of *x*. The width bit is kept. Lower keys give lower noise, and writing the pitch retriggers ch4.

**LFO.** Every tick, `TRK_LFOPHASE` += speed and the phase folds into a triangle 0–`$FE`. During the LFO delay after a note the phase is held at `$40` (centre). `(triangle × (depth + API depth) >> 8) − depth/2` is the signed output:

- pitch: × 8, in 1/256 semitones;
- volume (*Wario Land II* type 1): `$FF − 2 × out`;
- pan (type 2): `(out × 2) & $E0` added to the pan.

### 3.9 Pan

`PAN n` → `TRK_PAN` = 2*n* − 128, plus the API pan offset (and the pan LFO in *Wario Land II*). `WritePan` turns bits 7–6 of the result into NR51 for the channel: `10` left only, `01` right only, otherwise both. All data leaves pan at centre.

### 3.10 Parameters and fade

`Sound_SetParam` takes a = parameter, b = value (c = low byte where a word is needed), d = SFX slot mask, e = music slot mask (bits 0–3 each):

| a | Parameter | Effect on the selected tracks |
|---|---|---|
| 0 | tempo scale | b → SFX group if d ≠ 0, music group if e ≠ 0 (`$40` = normal) |
| 1 | pitch offset | `TRK_PITCHOFS` = bc (1/256 semitones) |
| 2 | volume scale | `TRK_VOLSCALE` = b (`$40` = normal) |
| 3 | pan offset | `TRK_PANOFS` = b |
| 4 | LFO depth offset | `TRK_LFODEPTHOFS` = b |
| 5 | echo | `TRK_ECHOLEVEL` = c, `TRK_ECHORATE` = b |
| 6 | LFO speed | b; b = 0 stops the LFO at centre, b = `$80` runs it at speed `$80` from phase 0 (a square) |

**Fade.** `Sound_FadeOut` *a* lowers the music's volume scale from `$40` by 4 every *a* frames (16 steps), through parameter 2 with e = `$FF`, then pauses the music. In *Wario Land II* the fade only advances while the music is **paused** (§5), so it does nothing. *Wario Land II* never calls it. *Wario Land 3* has the fix and a home wrapper for it (`$103E`).

---

## 4. Wario Land II → Wario Land 3

| | Wario Land II | Wario Land 3 |
|---|---|---|
| RAM | `$CD00` | `$D000`, WRAM bank 3. Variables shifted: one spare byte at `$D002`, `wSndBank` moved to `$D026` |
| Track record | — | `TRK_UNUSED5` inserted at `$05`; fields `$05–$28` move up one (the spare byte at WL2's `$29` absorbs it) |
| Sound table | 6-byte entries, ids to `$136` | 8-byte entries (two zero bytes), ids to `$238`; songs and SFX swapped in id order |
| Pitch | one octave + shifts | full 120-key period table |
| LFO | pitch, volume, pan | pitch only (types 1 and 2 removed) |
| Tone NRx4 write | | when the length counter is off, also clears the NRx1 length bits |
| Fade | runs only while paused (bug) | fixed |
| `StartTrack` | | its reset list is one byte late at the end: `TRK_VOLOUT` keeps 0 and `$FF` goes to the first stack entry (§5) |
| Instruments / waves | 110 / 11 | 123 / 12 |

Everything else is the same code with relocated addresses: dispatch, commands, voice allocation, envelopes, API and home glue.

---

## 5. Quirks

1. **The last wave overlaps `SoundTable` entry 0** in both games (§3.6).
2. ***Wario Land II*: the fade can't run.** `UpdateFade` returns if `wMusicPaused` is 0 (`ret z` at `$4529`), and `Sound_FadeOut` doesn't pause. *Wario Land 3* changed it to `ret nz`.
3. ***Wario Land 3*: `TRK_VOLOUT` starts at 0** instead of `$FF` (`$43C5`), and `$FF` lands on the first stack entry. A track would be silent until its first `VOLUME`. Every track in both games sets `VOLUME` before its first note, so it can't be heard.
4. ***Wario Land II* SFX `$4A`.** Its header and table entry say 2 tracks but hold one pointer. The second pointer would be read from the next sound's first bytes (`BD 00` → `$00BD`, in the home bank). Its slot byte is 3, so only one track fits and the second never starts (verified: the driver never reads below `$4000`).
5. **Cut-short type-2 headers.** Three SFX in *Wario Land II* and four in *Wario Land 3* have a type-2 header whose loop/end pointer sets are partly replaced by the next sound's data (§3.2). The driver never reads them:
   - *Wario Land II*: `$0C`, `$4E`, `$4F`;
   - *Wario Land 3*: `$10B`, `$171`, `$22D`, `$22F`.
6. **`RETURN` with an empty stack does nothing**, and the data depends on it: tracks begin with their subroutines and fall through them (§3.4).
7. **Echo can't time out** (§3.7). No data uses it.
8. **Dead code.** `IterAllTracks` (`$4152`, all 8 slots) is never called. A `dec hl` at `$4D93` (*Wario Land 3* `$4D3A`) sits just before a branch target and can't be reached.
9. **Unreachable data.** Each looping track ends `GOTO loop / END`, and the `END` can't be reached: 138 of them in *Wario Land II*, 116 in *Wario Land 3*. There are also dead track tails after a final `GOTO` or `END`: 5 (18 events) in *Wario Land II*, 46 (509 events, up to 35 bytes each) in *Wario Land 3*. The sources decode all of them and mark them `; unreachable`.
10. ***Wario Land 3* filler ids** (199 song ids, 58 SFX ids) all point at song `$01` (§3.2).
11. **`PAN` boundaries:** 3 positions only; `VOLUME` has 5 effective levels at the default scale (§3.7).

---

## 6. Songs

Lengths are from the parse of track 1 (`tools/wlsongs.py`): intro up to the loop point, then the loop. Ticks are converted with the song's first tempo, so songs that change tempo are approximate. Song titles weren't identified.

- *Wario Land II* `$12F` is the long through-composed piece (229 s, no loop), presumably the ending.
- *Wario Land 3* songs `$16–$1B`, `$25` and `$36` are *Wario Land II* songs.

**Wario Land II**

| Id | Header | Tracks | Tempo | Length (track 1) | Note |
|---|---|---|---|---|---|
| `$100` | `$19:4545` | 4 | 70 | 5.8 s + loop 42.5 s |  |
| `$101` | `$19:47B0` | 4 | 80 | 0.6 s + loop 32.7 s |  |
| `$102` | `$19:493A` | 3 | 44 | 1.3 s + loop 24.3 s |  |
| `$103` | `$19:4D53` | 4 | 48 | 6.0 s + loop 54.5 s |  |
| `$104` | `$19:51AF` | 4 | 50 | 10.5 s + loop 59.5 s |  |
| `$105` | `$19:54A2` | 3 | 43 | 1.2 s + loop 55.3 s |  |
| `$106` | `$19:5748` | 2 | 60 | 6.8 s + loop 27.8 s |  |
| `$107` | `$19:59FB` | 3 | 65 | 0.8 s + loop 32.9 s |  |
| `$108` | `$19:6012` | 3 | 36 | 14.6 s + loop 79.3 s |  |
| `$109` | `$19:63A1` | 4 | 49 | 5.9 s + loop 77.7 s |  |
| `$10A` | `$19:6613` | 2 | 77 | 3.7 s + loop 37.1 s |  |
| `$10B` | `$19:694A` | 3 | 75 | 0.7 s + loop 60.3 s |  |
| `$10C` | `$19:6BCC` | 4 | 40 | 1.4 s + loop 38.7 s |  |
| `$10D` | `$19:6F68` | 4 | 50 | 10.5 s + loop 38.1 s |  |
| `$10E` | `$19:7216` | 4 | 55 | 0.9 s + loop 38.9 s |  |
| `$10F` | `$19:745E` | 3 | 87 | 0.6 s + loop 32.8 s |  |
| `$110` | `$19:76E2` | 2 | 70 | 4.1 s + loop 40.8 s |  |
| `$111` | `$19:79BF` | 3 | 40 | 1.2 s + loop 59.5 s |  |
| `$112` | `$19:7AF9` | 3 | 60 | 0.8 s + loop 19.8 s |  |
| `$113` | `$19:7C1A` | 2 | 120 | ends, 14.2 s |  |
| `$114` | `$19:7D58` | 3 | 90 | ends, 10.5 s |  |
| `$115` | `$19:7EDE` | 4 | 60 | 7.9 s + loop 7.9 s |  |
| `$116` | `$1A:4328` | 4 | 75 | 5.6 s + loop 25.4 s |  |
| `$117` | `$1A:4797` | 4 | 75 | 8.8 s + loop 25.4 s |  |
| `$118` | `$1A:4D5A` | 4 | 75, 90 | 10.4 s + loop 33.3 s |  |
| `$119` | `$1A:531F` | 4 | 75, 90 | 10.4 s + loop 33.3 s |  |
| `$11A` | `$1A:53CF` | 3 | 45 | ends, 0.9 s |  |
| `$11B` | `$1A:5516` | 4 | 70 | loop 6.8 s |  |
| `$11C` | `$1A:56E5` | 4 | 65 | 3.7 s + loop 7.3 s |  |
| `$11D` | `$1A:57BA` | 4 | 55 | ends, 3.9 s |  |
| `$11E` | `$1A:584F` | 3 | 100 | ends, 2.5 s |  |
| `$11F` | `$1A:58D6` | 2 | 85 | loop 5.6 s |  |
| `$120` | `$1A:5952` | 2 | 70 | loop 6.8 s |  |
| `$121` | `$1A:5A6B` | 3 | 37 | 0.8 s + loop 25.7 s |  |
| `$122` | `$1A:5BE6` | 3 | 85 | loop 11.2 s |  |
| `$123` | `$1A:5D2C` | 3 | 56 | loop 17.0 s |  |
| `$124` | `$1A:5EBF` | 3 | 51 | 4.7 s + loop 21.0 s |  |
| `$125` | `$1A:5F97` | 2 | 50 | 0.2 s + loop 19.0 s |  |
| `$126` | `$1A:607B` | 3 | 72 | 0.4 s + loop 9.9 s |  |
| `$127` | `$1A:6200` | 3 | 80 | loop 11.9 s |  |
| `$128` | `$1A:62A2` | 2 | 60 | loop 7.9 s |  |
| `$129` | `$1A:638D` | 3 | 80 | 5.9 s + loop 11.9 s |  |
| `$12A` | `$1A:64BA` | 4 | 45 | ends, 5.4 s |  |
| `$12B` | `$1A:657A` | 4 | 87 | ends, 3.5 s |  |
| `$12C` | `$1A:678B` | 4 | 60 | 4.0 s + loop 15.9 s |  |
| `$12D` | `$1A:6800` | 4 | 60 | ends, 1.0 s |  |
| `$12E` | `$1A:698D` | 3 | 60 | loop 15.9 s |  |
| `$12F` | `$1A:78CD` | 4 | 74 | ends, 229.4 s |  |
| `$130` | `$1A:7ADC` | 3 | 40 | loop 71.4 s |  |
| `$131` | `$1A:7B06` | 1 | 74 | ends, 0.2 s |  |
| `$132` | `$1B:454D` | 4 | 40, 60 | loop 130.8 s |  |
| `$133` | `$1B:471C` | 2 | 60 | loop 31.7 s |  |
| `$134` | `$1B:4A4D` | 4 | 85 | 2.8 s + loop 22.4 s |  |
| `$135` | `$1B:4F74` | 4 | 60 | 4.0 s + loop 47.6 s |  |
| `$136` | `$1B:500A` | 4 | 60 | ends, 2.0 s |  |

**Wario Land 3**

| Id | Header | Tracks | Tempo | Length (track 1) | Note |
|---|---|---|---|---|---|
| `$01` | `$0C:6A98` | 4 | 55 | 4.3 s + loop 51.9 s |  |
| `$02` | `$0C:6D27` | 3 | 45 | 10.6 s + loop 58.1 s |  |
| `$03` | `$0C:6EED` | 2 | 30 | loop 95.2 s |  |
| `$04` | `$0C:72E7` | 3 | 45 | 5.3 s + loop 84.6 s |  |
| `$05` | `$0C:75AF` | 3 | 45 | 5.3 s + loop 60.8 s |  |
| `$06` | `$0C:77F9` | 3 | 60 | loop 53.5 s |  |
| `$07` | `$0C:7B2E` | 4 | 60 | loop 37.7 s |  |
| `$08` | `$0C:7DD5` | 3 | 35 | 3.4 s + loop 54.4 s |  |
| `$09` | `$0D:4391` | 3 | 80 | loop 55.8 s |  |
| `$0A` | `$0D:481C` | 3 | 60 | loop 74.3 s |  |
| `$0B` | `$0D:4A50` | 3 | 40 | loop 71.4 s |  |
| `$0C` | `$0D:4D69` | 3 | 55 | loop 56.2 s |  |
| `$0D` | `$0D:5179` | 3 | 90 | loop 50.2 s |  |
| `$0E` | `$0D:547A` | 4 | 60 | loop 35.7 s |  |
| `$0F` | `$0D:5718` | 4 | 40 | loop 53.5 s |  |
| `$10` | `$0D:5A63` | 4 | 65 | 3.7 s + loop 36.6 s |  |
| `$11` | `$0D:5F44` | 4 | 40 | loop 86.2 s |  |
| `$12` | `$0D:64C6` | 4 | 42 | 5.7 s + loop 96.3 s |  |
| `$13` | `$0D:67CB` | 4 | 60 | 7.9 s + loop 71.4 s |  |
| `$14` | `$0D:6997` | 4 | 40 | loop 47.6 s |  |
| `$15` | `$0D:7450` | 4 | 50, 54, 55, 59, 65 | ends, 109.7 s |  |
| `$16` | `$0D:75C1` | 3 | 85 | loop 11.2 s | WL2 $122 |
| `$17` | `$0D:76E0` | 3 | 37 | 0.8 s + loop 25.7 s | WL2 $121 |
| `$18` | `$0D:7829` | 3 | 56 | 0.5 s + loop 17.0 s | WL2 $123 |
| `$19` | `$0D:7901` | 2 | 50 | 0.2 s + loop 19.0 s | WL2 $125 |
| `$1A` | `$0D:79E5` | 3 | 72 | 0.4 s + loop 9.9 s | WL2 $126 |
| `$1B` | `$0D:7B78` | 3 | 51 | 4.7 s + loop 21.0 s | WL2 $124 |
| `$1C` | `$0D:7CF0` | 3 | 45 | loop 21.1 s |  |
| `$1D` | `$0D:7DF8` | 3 | 82 | 2.9 s + loop 11.6 s |  |
| `$1E` | `$0D:7F41` | 3 | 90 | loop 15.9 s |  |
| `$1F` | `$0E:41E6` | 2 | 110 | loop 17.3 s |  |
| `$20` | `$0E:4351` | 3 | 60 | 2.0 s + loop 33.7 s |  |
| `$21` | `$0E:46F6` | 4 | 65 | loop 58.6 s |  |
| `$22` | `$0E:4951` | 3 | 50 | loop 42.8 s |  |
| `$23` | `$0E:4A63` | 3 | 60 | loop 7.9 s |  |
| `$24` | `$0E:4B5E` | 4 | 50 | ends, 4.8 s |  |
| `$25` | `$0E:4BD6` | 2 | 70 | loop 6.8 s | WL2 $120 |
| `$26` | `$0E:4F13` | 3 | 65 | loop 29.3 s |  |
| `$27` | `$0E:5308` | 4 | 75 | 1.6 s + loop 41.2 s |  |
| `$28` | `$0E:54CC` | 4 | 75 | 6.3 s + loop 6.3 s |  |
| `$29` | `$0E:55E1` | 2 | 60 | loop 15.9 s |  |
| `$2A` | `$0E:5641` | 3 | 90 | ends, 2.3 s |  |
| `$2B` | `$0E:56BC` | 4 | 100 | ends, 2.1 s |  |
| `$2C` | `$0E:57F2` | 3 | 50 | ends, 18.4 s |  |
| `$2D` | `$0E:58B4` | 2 | 35 | loop 13.6 s |  |
| `$2E` | `$0E:5991` | 2 | 75 | loop 12.7 s |  |
| `$2F` | `$0E:5BA8` | 4 | 50 | 7.1 s + loop 19.0 s |  |
| `$30` | `$0E:5D53` | 3 | 40 | loop 47.6 s |  |
| `$31` | `$0E:5DB7` | 3 | 74 | loop 0.4 s |  |
| `$32` | `$0E:5F11` | 2 | 45 | loop 21.1 s |  |
| `$33` | `$0E:62EF` | 4 | 60 | 4.0 s + loop 31.7 s |  |
| `$34` | `$0E:6641` | 3 | 60, 69, 90 | ends, 19.2 s |  |
| `$35` | `$0E:6C2B` | 4 | 70 | 8.5 s + loop 68.0 s |  |
| `$36` | `$0E:7152` | 4 | 60 | 4.0 s + loop 47.6 s | WL2 $135 |
| `$37` | `$0E:72A6` | 3 | 60 | loop 33.7 s |  |
| `$38` | `$0E:748D` | 3 | 40 | loop 59.5 s |  |
| `$39` | `$0E:74E5` | 3 | 90 | ends, 1.3 s |  |
| `$3A` | `$0E:7834` | 4 | 90 | loop 31.7 s |  |

**SFX.** The SFX are numbered by id in `SoundTable`; the sources label them `Sfx_<id>`. `tools/wlcompare.py` lists the 70 *Wario Land 3* SFX that are byte-identical to *Wario Land II* ones; the first of them map almost one to one (WL3 `$102` = WL2 `$02`, `$103` = `$03`, …).

---

## 7. Verification

- **Byte-exact rebuild.** `build_check.sh` links all objects over the original ROM with `rgblink -O` and compares the whole ROM. It then links them bare and compares each sound region on its own: the home glue, the driver bank and every data bank, in both games. Both pass.
- **Emulator harness.** `harness/` builds a test ROM: the rebuilt ROM, plus a loader in free home space and a main loop in an empty bank (`$41` / `$16`). The loop calls `Sound_Update` once per frame and starts whatever `verify.py` requests. `verify.py` (PyBoy) plays every id: songs for 14,400 frames (4 minutes, enough for the 229 s `$12F`), SFX for 900 frames. It hooks the three `[de]` reads in `Snd_ReadByte`/`Snd_ReadWord` and checks each byte read against the parse.

  | Game | Reachable events | Read | Reads outside the parse | Look-ahead bytes past an `END` |
  |---|---|---|---|---|
  | Wario Land II | 32,208 | 32,208 | 0 | 266 |
  | Wario Land 3 | 36,977 | 36,977 | 0 | 261 |

  The check is strict: only reachable events and each header's track pointers count as parsed, not the unreachable events, the header type byte or the loop/end sets. Every reachable event is read during play, and nothing outside them is. The one exception is the second byte of the 2-byte fetch at an `END`, which is read but never used (one per track end). No read goes below `$4000`, so SFX `$4A`'s missing track never starts.
- **Not verified.** Anything on hardware; the echo path, `PAN`, `DETUNE`, `EXT`, `LOOP` and the auto-slot mode, which no data uses; the *Wario Land II* volume/pan LFO types; the game contexts of the songs.

## Files (`GBAudioLab\Wario`)

| File | Content |
|---|---|
| `WL2\WL2_Bank18.asm` | driver code (labelled, struct offsets named), tables, `SoundTable`, the SFX data in bank `$18` |
| `WL2\WL2_Bank19.asm`, `…1A.asm`, `…1B.asm` | sound data |
| `WL2\WL2_Home.asm` | `$3F00–$3FC2`: stubs, lock, bank switch, readers |
| `WL2\WL2_RAM.inc` | RAM map, `TRK_*` and `CH_*` offsets |
| `WL3\…` | the same for *Wario Land 3* (banks `$0C–$0F`) |
| `common\WL_Macros.inc` | sequence macros (`NOTE`, `WAIT`, `GOSUB`, …, `_` = running status), key names, `INST`, `PITCH`, `SOUND`, `SOUND8` |
| `common\GB_Hardware.inc` | sound registers |
| `build_check.sh`, `tools\regions_cmp.py` | rebuild check |
| `harness\harness.asm`, `harness\build.sh`, `harness\verify.py` | emulator check |
| `tools\wlgen.py` | source generator (with `sm83.py`, `wlseq.py` parser, `wlnames.py` names and notes, `addrmap_wl2_wl3.json` and `ram_wl2_wl3.json` code/RAM alignment) |
| `tools\wlsongs.py`, `tools\wlcompare.py` | song lengths; sounds shared between the games |
