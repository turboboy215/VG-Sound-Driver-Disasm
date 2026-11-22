# Agenda Sound Driver — Doraemon 2 (J), Pokonyan! - Yume no Daibouken (J)

Disassembly and documentation of the sound driver used by two Agenda Game Boy games. Everything here comes from the code. The format was checked by running every song and SFX through the real driver in PyBoy and comparing the driver RAM and the readable sound registers, after every update call, against a Python model written from this document (§11).

| Game | ROM | Mapper | Driver | Sound region |
|---|---|---|---|---|
| Doraemon 2 (J) | 128 KB | MBC1 | **v1** | bank $01, $4000–$7F30 (16,177 bytes); $7F31–$7FFF is $FF padding |
| Pokonyan! - Yume no Daibouken (J) [S] | 256 KB | MBC1 | **v2** | bank $07, $4000–$7C2F (15,408 bytes); $7C30–$7FFF is $FF padding |

## Summary

- **Pokonyan uses the same engine.** Its bank 7 holds the Doraemon 2 driver almost instruction for instruction (1,144 of its 1,157 instructions align), with different RAM addresses and five small changes (§9).
- The driver runs **4 music tracks and 1 SFX track**. The SFX can take any of the 4 channels. While it does, the music track on that channel keeps running silently.
- Track data is **one byte per note**: the byte is the note number (MIDI numbering, $3C = C4), optionally followed by a length code $80–$9F. Commands are $A0–$B7.
- Lengths come from a fixed **LengthTable**. Music ticks once every *tempo+1* frames; the SFX ticks every 2nd frame.
- Instruments are built from commands rather than a table: volume, duty, an optional **envelope list** of (NRx2, ticks) pairs, a **sweep list** on ch1, and **drum kits** of (noise list, envelope list) pairs on ch4. There are also vibrato/slide, gate, slur, transpose and detune commands.
- The wave is loaded by a command; there are 12 waves in each game, in groups of 3.
- Bugs: the channel freed by an SFX always gets centre pan (§8); every song start writes $01 to $00A8/$00A9 (ROM, i.e. MBC RAM-enable).
- Pokonyan also has a complete **unused song** (4 tracks) that no table points to (§10), and on a **Super Game Boy** it doesn't use this driver at all (§12).

---

## 1. Interface

Both games start the driver bank with a jump table. The order differs:

| Doraemon 2 | Pokonyan | Label | Use |
|---|---|---|---|
| $4000 | $400B | `Sound_Init` | boot |
| $4003 | $4002 | `Sound_Update` | once per frame |
| $4006 | $400E | `Sound_PlayMusic` | a = song id |
| $4009 | $4008 | `Sound_PlaySfx` | a = SFX id |
| $400C | $4005 | `Sound_StopMusic` | starts the silent song |
| $400F | $4011 | `Sound_SaveMusic` | back up the music state, then silence |
| $4012 | $4014 | `Sound_RestoreMusic` | restore it |

Pokonyan's bank 7 starts with `$07 $07` (every bank of that ROM starts with its own number twice), so its table is at $4002.

**Call sites.**
- Doraemon 2: Init at $0186/$019D; Update from a bank-switching wrapper at $02AF (and once at $01A8); the other entries from bank-0 wrappers at $05D6–$0636. The music wrapper clears `hSndMarker` before playing. If `[$D128]` ≠ 0 it first replaces the id through `MusicRemap` ($4020); the SFX wrapper does the same through `SfxRemap` ($4040) when `[$FFBA]` = 1. These two tables are game data stored in the driver bank; the driver itself never reads them.
- Pokonyan: Init $0194, Update $2AF8, StopMusic $2ABF, PlayMusic $2B2A, PlaySfx $2B6B. On a Super Game Boy the same wrappers call bank 8 instead (§12). Save/Restore are not used on the GB path.

**Interrupt masking.** `Save`, `Restore`, `Snd_StartSfx` and `Snd_StartMusic` clear IE bit 1 (LCD STAT) while they change the structs and restore IE afterwards.

**`Sound_Init`**:
- writes NR52 = 0 then $8F, NR51 = $FF, NR50 = $77, and NR10–NR23 from the 20-byte `InitRegs`;
- clears `hSndFlags`, `hSndMarker`, `hSndSfxChannel`, `hSndSfxPriority` and the flags of all 5 structs;
- falls into `Sound_StopMusic`.

**`Sound_PlayMusic`** stores the id in `hSndMusicId` and starts `MusicTable[id]`: four track pointers, ch1–ch4. `Snd_StartMusic` then:
- clears channel bits 0–3 of `hSndFlags`. Bits 4 (SFX) and 7 (no-loop) are kept;
- sets tempo and tempo counter to 4, so the first update ticks at once;
- runs `Snd_InitTrack` on structs 0–3. This clears the struct (except `TRKF_SFXOWNED`) and sets `TRK_START` = `TRK_PTR` = data, default length 1, length 1, volume $C;
- writes $01 to $00A8 and $00A9 (see §8), NR30 = $80, then NR32 = 0 and NR30 = 0;
- sets channel bits 0–3.

`Sound_StopMusic` does the same with `SilentSong`: four copies of a track that sets NR50 = $77 and volume 0, plays one rest and ends.

**`Sound_PlaySfx`** stores the id in `hSndSfxId` and reads the header at `SfxTable[id]`:

| Byte | Meaning |
|---|---|
| 0 | hardware channel 0–3 |
| 1 | priority |
| 2… | track data |

- If priority < `hSndSfxPriority`, the call is ignored. Equal or higher priority replaces the playing SFX.
- A playing SFX is ended first (`Cmd_End` on struct 4, §8).
- Then `hSndSfxPriority` = priority, `hSndSfxChannel` = channel, the music struct of that channel gets `TRKF_SFXOWNED`, struct 4 is initialised with the track, and `hSndFlags` bit 4 is set.

**`Sound_SaveMusic`** copies the 256-byte struct page to `wSndSave` and the 16 HRAM bytes over its last 16 bytes, clears channel bits 0–3 and calls `Sound_StopMusic`. **`Sound_RestoreMusic`** copies both back. Wave RAM and the sound registers are not saved, so each restored channel sounds again at its next note. Doraemon 2 uses this around jingles.

## 2. RAM

| Doraemon 2 | Pokonyan | Name | Use |
|---|---|---|---|
| $FF90 | $FFB0 | `hSndChannel` | hardware channel being processed (0–3) |
| $FF91 | $FFB1 | `hSndStructOfs` | struct offset: $00/$30/$60/$90 music, $C0 SFX |
| $FF92 | $FFB2 | `hSndTempo` | frames per tick − 1 |
| $FF93 | $FFB3 | `hSndTempoCount` | frame counter |
| $FF94 | $FFB4 | `hSndFlags` | bits 0–3 channel on, bit 4 SFX playing, bit 7 no-loop |
| $FF95 | $FFB5 | `hSndMarker` | last `$B4` argument, read by the game |
| $FF96 | $FFB6 | `hSndSlur` | 1 = `$A4` seen in the current row |
| $FF97 | $FFB7 | `hSndMasterVol` | NR50 copy (`$B6`) |
| $FF98 | $FFB8 | `hSndSfxChannel` | channel of the SFX |
| $FF99 | $FFB9 | `hSndMuted` | 1 = this channel belongs to the SFX: no register writes |
| $FF9A | $FFBA | `hSndRetrigger` | ≠ 0 = write NRx4 with the trigger bit at the end of the tick |
| $FF9B | $FFBB | `hSndSfxId` | |
| $FF9C | $FFBC | `hSndSfxPriority` | 0 when no SFX |
| $FF9D | $FFBD | `hSndMusicId` | |
| $FF9E | $FFBE | — | not used |
| $FF9F | $FFBF | `hSndSfxFrame` | SFX frame divider |
| $C100 | $DD00 | `wSndTracks` | 5 structs of $30 bytes: ch1, ch2, ch3, ch4, SFX |
| $C200 | $DE00 | `wSndSave` | Save/Restore copy (256 bytes; the last 16 hold the HRAM copy) |

All struct access goes through `Snd_GetVar`/`Snd_SetVar` (and the word versions): l = field offset, the address is `wSndTracks` + `hSndStructOfs` + l.

**Track struct:**

| Offset | Name | Meaning |
|---|---|---|
| $00 | `TRK_START` | first byte of the track; `$A0` loops here |
| $02 | `TRK_PTR` | data pointer |
| $04 | `TRK_ENVBASE` | envelope list (`$A8`, or the drum's) |
| $06 | `TRK_CALLRET` | address of the `$AC` pointer (the return slot) |
| $08 | `TRK_LOOPPTR` | `$A3` loop start |
| $0A | `TRK_FREQ` | period, written to NRx3/NRx4 |
| $0C | `TRK_SEQTABLE` | `$AB`/`$AD` pointer: sweep list (ch1) or drum kit (ch4) |
| $0E | `TRK_FLAGS` | bit 0 SFX owns the channel, 1 slur, 2 envelope set, 3 table set, 4 noise/sweep list running, 5 envelope running, 7 SFX just ended here |
| $0F | `TRK_DEFLEN` | default length (ticks) |
| $10 | `TRK_LENGTH` | ticks left in the row |
| $11 | `TRK_VOLUME` | ch1/2/4: volume 0–15; ch3: NR32 value |
| $12 | `TRK_DUTY` | NRx1 value |
| $13 | `TRK_PAN` | last `$A7` argument |
| $14 | `TRK_NOTE` | note |
| $15 | `TRK_TRANSPOSE` | semitones |
| $16 | `TRK_DETUNE` | signed period offset (also the vibrato's position) |
| $17 | `TRK_PREVNOTE` | previous note |
| $18 | `TRK_GATE` | gate in eighths, 0 = off |
| $19 | `TRK_GATECOUNT` | ticks until note-off |
| $1A | `TRK_LOOPCOUNT` | `$A3`/`$A9` pass counter |
| $1B | `TRK_CALLCOUNT` | `$AC` repeat counter |
| $1C / $1E | `TRK_ENVPTR` / `TRK_SEQPTR` | positions in the envelope / noise or sweep list |
| $20 / $21 | `TRK_SEQCOUNT` / `TRK_SEQVALUE` | noise list countdown and last value |
| $22 / $23 | `TRK_ENVCOUNT` / `TRK_ENVVALUE` | envelope countdown and last value |
| $24–$2C | `TRK_VIB*` | vibrato: step, mode, delay (count, reload), half period (count, reload), rate (count, reload), depth |

## 3. Timing

**`Sound_Update`:**
1. If `hSndTempoCount` ≠ `hSndTempo`, it is incremented and the music is skipped this frame. Otherwise it is reset to 0 and each music channel whose bit is set in `hSndFlags` ticks once (with `hSndMuted` = that struct's `TRKF_SFXOWNED`).
2. If an SFX is playing, `hSndSfxFrame` is incremented. When it is even, the SFX struct ticks once on channel `hSndSfxChannel` (never muted).

So music ticks every **tempo+1 frames** and the SFX every **2 frames**. Both games only use tempo 0 or 1 (1 or 2 frames per tick).

**One tick (`Snd_TickTrack`):**
- `TRK_LENGTH` − 1. At 0 a new row is read (§4), and nothing else happens this tick.
- Otherwise, if `TRK_GATECOUNT` is already 0 (note released), nothing happens.
- Otherwise `TRK_GATECOUNT` − 1; at 0 the note is released (§5).
- Otherwise, unless `TRKF_CLOBBERED` is set: the envelope list steps (not ch3), the noise list steps (ch4), the vibrato steps (ch1/ch2).
- Finally, if `hSndRetrigger` is set and the channel isn't muted, NRx4 is written with the trigger bit (ch3 also gets NR32 and NR30 = $80 first).

**LengthTable** (row lengths in ticks, codes $80 upwards):

| | $80 | $81 | $82 | $83 | $84 | $85 | $86 | $87 | $88 | $89 | $8A | $8B | $8C | $8D | $8E | $8F | $90 | $91 | $92 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Doraemon 2 | 64 | 48 | 32 | 24 | 16 | 12 | 8 | 6 | 4 | 3 | 2 | 1 | 1 | 1 | | | | | |
| Pokonyan | 128 | 96 | 64 | 48 | 32 | 24 | 16 | 12 | 8 | 6 | 4 | 3 | 2 | 1 | 144 | 72 | 36 | 18 | 9 |

Codes past the end of the table would read the period table; the data never uses them. Pokonyan's whole note is 128 ticks, twice Doraemon 2's.

## 4. Track format

Rows are read until a note or rest. Bytes:

| Byte | Meaning |
|---|---|
| $00–$7F | note, optionally followed by a length code $80–$9F. Without one, the row uses `TRK_DEFLEN`. **Rest** = $00 (Doraemon 2) / $7F (Pokonyan) |
| $80–$9F | length code. Only valid after a note or as the `$A5` argument |
| $A0–$B7 | command (below) |

**Notes.** The period is `FreqTable[note − $24 + transpose] + detune` (detune is signed). FreqTable has 89 entries from $24 (C2, period $002C) to $7C. Notes below $24 give period 0; on tone channels the data never uses them. On ch4 the note picks a drum: entry `(note − $0A) & 7` of the drum kit.

The note numbers are MIDI numbers ($3C = middle C). On ch3 the same period sounds an octave lower.

**Commands:**

| Cmd | Args | Effect |
|---|---|---|
| $A0 | – | **end**. SFX: stop it (§8). Music: jump to `TRK_START`. If no-loop mode is on, stop the channel instead (note-off, clear its bit). A track whose first byte is $A0 also stops |
| $A1 | – | loop mode **on** (`hSndFlags` bit 7 = 0) |
| $A2 | – | loop mode **off**: tracks stop at their `$A0`. This flag is global and survives song changes; only `$A1` and `Sound_Init` clear it |
| $A3 | – | loop start: `TRK_LOOPPTR` = here, passes = 0 |
| $A4 | – | slur: tie this row's note into the next note if it has the same pitch (§5) |
| $A5 | len | default length = LengthTable[len − $80] |
| $A6 | v | volume. ch1/2/4: `TRK_VOLUME` = v (0–15). ch3: `TRK_VOLUME` = WaveVolTable[v]: 0–1 mute, 2–5 25%, 6–9 50%, 10–15 100% |
| $A7 | p | pan, NR51 bits of this channel: 1 = right, 2 = left, 0/3 = both. Written at once |
| $A8 | ptr | envelope list (§6) |
| $A9 | n | loop end: passes + 1; jump back while passes < n, so the body plays n times. **Not nestable.** $FF = 255 passes, Pokonyan's "forever" |
| $AA | d | duty (ch1/ch2 only): `TRK_DUTY` = d × $40 |
| $AB, $AD | ptr | ch1: sweep list. ch4: drum kit. No effect on ch2/ch3 (Doraemon 2 has one on ch2, at $72E9). Identical commands |
| $AC | n, ptr | call `ptr` n times. The subroutine ends with `$B5`. **One level only** |
| $AE | x, ptr | load a wave (§6). x is read and ignored |
| $AF | t | tempo: tick every t+1 frames. Ignored from the SFX |
| $B0 | d | detune (signed period offset) |
| $B1 | t | transpose (semitones, signed) |
| $B2 | g | gate = g & 7 (eighths of the row, 0 = off) |
| $B3 | ptr | jump |
| $B4 | x | `hSndMarker` = x (the game reads it; only Doraemon 2 uses it, 8 times) |
| $B5 | – | return from `$AC`: counter − 1; at 0 continue after the `$AC`, else run the subroutine again |
| $B6 | v | NR50 = v (also kept in `hSndMasterVol`) |
| $B7 | m, delay, rate, half | vibrato/slide (§6). m bits 6–7 = mode, bits 0–5 = step |

In Doraemon 2 a byte $80–$9F or $B8–$FF where a command is expected would jump through garbage; the data never has one. Pokonyan ignores such bytes (§9).

After a command the parser continues with the next byte. For the SFX it stops if the SFX has ended; for music, if the channel has been switched off.

**How tracks end.**
- Doraemon 2: 54 tracks end with `$B3` back to a loop point; each is followed by an `$A0` that is never reached. 120 `$A0`s are reached; SFX end with `$A0`.
- Pokonyan loops with `$A3 … $A9 $FF` (22 times). After 255 passes, 2 of those reach an `$A0` and 19 would fall through into the next track's data. The last track in the bank (song $0F ch4) would run into the $FF padding, which v2 treats as ignored commands.

## 5. Notes, gate and slur

When a note row is read:
1. `TRK_PREVNOTE` = old note, `TRK_NOTE` = new note.
2. A **rest** clears the slur flag and releases the note.
3. A **note** computes the period. Then it keys on, unless it is tied:
   - `$A4` in this row and the slur flag was clear: set the flag, key on;
   - `$A4` in this row and the flag was set: key on only if the pitch differs;
   - no `$A4` and the flag was set: clear the flag; key on only if the pitch differs;
   - otherwise: key on.
4. **Key-on**: release, then (if not muted) set `hSndRetrigger` and write NRx3/NRx4 (ch4: start the drum, §6). Then ch1 starts its sweep list, ch1/2/4 run `Snd_VolumeInit`, ch1/ch2 reset the vibrato.
5. The length: a following $80–$9F byte, else `TRK_DEFLEN`. `TRK_GATECOUNT` = the length, or with gate g, max(1, length ÷ 8) × g. The note is released after that many ticks if that is before the next row.

**Release** (`Snd_NoteOff`, skipped when muted): NRx2 = $08 and NRx4 = $80 (volume 0, retriggered); ch3: NR32 = 0, NR30 = 0.

**`Snd_VolumeInit`** (ch1/2/4, skipped when muted): NRx2 = volume × $10 + the low nibble NRx2 already has. Right after a release that nibble is 8 (no envelope). NRx1 = `TRK_DUTY`. If an envelope list is set, it starts and its first value replaces NRx2.

## 6. Instruments

**Envelope lists** (`$A8`, and each drum's second pointer) are (NRx2 value, ticks) pairs. The first pair is written at key-on. When its ticks run out the next pair is written and the note is **retriggered** (NRx2 changes need a trigger). A duration of **$FE** restarts the list, **$FF** stops it. Most lists are a single pair such as `$E4, $F0` (start volume 14, decreasing, 240 ticks), then `$00, $FF`. They only step while the note sounds.

**Sweep lists** (`$AB`/`$AD` on ch1) have the same layout, but only the first value is ever used: it is written to NR10 at each key-on. The list is never stepped, because the stepping routine only runs on ch4. Examples: `$08` (no sweep), `$27` (sweep time 2, down, shift 7).

**Drum kits** (`$AB`/`$AD` on ch4) have 8 entries: (noise list, envelope list). A ch4 note selects entry `(note − $0A) & 7`. At key-on:
- the envelope pointer is set, and `Snd_VolumeInit` starts it;
- the noise list starts: (NR43 value, ticks) pairs, written without retrigger. When a step's ticks run out, the next value is written and the channel retriggered;
- noise list duration **$FE** re-runs the drum setup: the noise list restarts and the envelope pointer is reset, but the running envelope isn't restarted. **$FF** stops the noise list.

Each game has 4 kits. Doraemon 2's first kit (at $4BDB) and its lists are byte-identical to Pokonyan's (at $4C28).

**Waves.** `$AE x ptr`: ptr points to a 4-byte entry, a wave address and `$01 $00` (never read). The 16 bytes are copied into wave RAM with NR30 off, then NR30 = $80 and `hSndRetrigger` = $80. Nothing happens while the SFX owns ch3. Both games have the same 12 waves, stored as 4 groups of [3 entries, 3 waves]. Wave volume comes from `$A6`.

**Vibrato** (`$B7 m delay rate half`, ch1/ch2 only, reset at every key-on):

| Mode (m bits 6–7) | Effect |
|---|---|
| 0 | off |
| 1 | one-sided triangle: after *delay* ticks, every *rate* ticks detune += step; after *half* steps the step changes sign. The pitch goes from 0 up to half × step and back |
| 2 | slide down: detune −= step every *rate* ticks, forever (8-bit, so it wraps) |
| 3 | slide up, the same way |

Changes rewrite NRx3/NRx4 without retrigger. Key-on with vibrato on sets detune to 0, which cancels `$B0`. Doraemon 2 uses modes 1 and 2; Pokonyan's 8 `$B7`s are all `$B7 $00 $00 $00 $00` (off).

## 7. Output

The driver writes registers in three places:
- the command handlers (`$A7`, `$B6`, `$AE`);
- key-on and release, as the row is read;
- the end-of-tick trigger write: NRx4 = $80 | period high (ch4: $80).

All track-driven writes are skipped while the SFX owns the channel (`hSndMuted`); the end-of-SFX cleanup and the song-start writes are not. Writes to NR52 OR in the channel's bit (those bits are read-only, so this does nothing).

## 8. SFX

- The SFX track uses struct 4 and the same format as music. In both games SFX use only ch1 and ch4, apart from the two unused ch3 SFX in Doraemon 2.
- The music track on that channel keeps running, but `hSndMuted` blocks all of its register writes. A muted key-on doesn't even set `hSndRetrigger`.

**End (`$A0` in the SFX, or a new SFX of equal or higher priority):**
1. release the channel; clear `hSndFlags` bit 4; `hSndSfxPriority` = 0;
2. silence it: NRx2 = 8, NRx4 = $80. Ch1 also gets NR14 = $08 first; ch3 is left alone;
3. the music struct of that channel: clear `TRKF_SFXOWNED`, set `TRKF_CLOBBERED`. Its envelope, noise list and vibrato are paused until its next row, and it sounds again at its next key-on;
4. **bug**: it then means to restore the music's pan. The code does `ld a,c / add a,$13 / ld a,[hl]` without `ld l,a`, so it reads `TRK_FLAGS` (≥ $80 at this point) as the pan value. The channel always ends up **centre-panned** until the music's next `$A7`.

**Pokonyan only:** `Sound_StopMusic` (and so `Sound_Init`) runs this end sequence too. If no SFX is playing it still silences `hSndSfxChannel`'s channel and sets its pan to centre; the music struct is cleared right after anyway.

### Other quirks
- `Snd_StartMusic` writes $01 to $00A8 and $00A9. Those are ROM addresses, so on MBC1 the writes only disable cartridge RAM, which neither game has. They look like a typo for two RAM variables.
- `$A1`/`$A2` are global (one bit for all tracks) and survive `Sound_PlayMusic`.
- `$A3`/`$A9` and `$AC`/`$B5` have one slot each per track, so they can't be nested within their own kind (an `$AC` subroutine may contain an `$A3` loop).

## 9. v1 → v2 differences (Doraemon 2 → Pokonyan)

| | Doraemon 2 (v1) | Pokonyan (v2) |
|---|---|---|
| RAM | $C100/$C200, HRAM $FF90 | $DD00/$DE00, HRAM $FFB0 |
| Rest | $00 | $7F |
| Bytes $80–$9F, $B8–$FF as commands | jump through garbage | ignored (1 byte) |
| LengthTable | 14 entries, 64-tick whole note | 19 entries, 128-tick whole note, plus 144/72/36/18/9 |
| Ending the SFX | inline in `Snd_StartSfx` | subroutine `Snd_EndSfx`, also called by `Sound_StopMusic` |
| `Cmd_End` clearing bit 4 | `ldh a / res 4,a / ldh` | `push hl / res 4,[hl] / pop hl` |
| Jump table | at $4000, Init first | at $4002 after the bank bytes, Update first |
| Id remap tables | `MusicRemap`/`SfxRemap` at $4020 (game data) | none ($FF padding) |

Everything else is identical, including the pan bug and the $00A8 writes.

## 10. Sound data

| | Doraemon 2 | Pokonyan |
|---|---|---|
| Music ids | 32 ($00–$1F), 128 different tracks, all 4-channel | 17 ($00–$10), 68 tracks |
| SFX ids | 64 ($00–$3F), 43 headers; 22 ids point at a silent "null" SFX | 34 ($00–$21), 33 headers ($21 = $00) |
| `$AC` subroutines | 8 | none |
| Envelope / sweep lists | 55 / 3 (+17 unreferenced) | 58 / 7 (+47 unreferenced) |
| Drum kits | 4 × 8 | 4 × 8 |
| Waves | 12 | 12 |
| Unreferenced data | 2 identical ch3 SFX ($7991, $7C91); one wave entry and wave ($4BA7, $4BCB); unused kit entries | **a complete song** at $5F21/$5FDE/$6088/$60FF (4 tracks, starts with `$A1 $AF $01`); unused kit entries |

Layout: driver, tables, `MusicTable`, then a shared instrument block (envelope and sweep lists, wave groups, drum kits), then the tracks. Doraemon 2's `SfxTable` sits between the music and the SFX data; Pokonyan's is after the instrument block. Every byte of both regions is reached from a table, or listed above as unreferenced.

## 11. Files

In `GBAudioLab\Agenda\`:

| File | Contents |
|---|---|
| `Doraemon2_sound.asm` | bank 1 $4000–$7F30: driver v1, tables, all music and SFX |
| `Pokonyan_sound.asm` | bank 7 $4000–$7C2F: driver v2 + data, including the unused song |
| `agenda_sound.inc` | EQUs only: sound registers, `TRK_*` offsets and flag bits. HRAM/WRAM names are in each .asm (the addresses differ) |
| `tools\agenda_gen.py` | generator for both files (`python agenda_gen.py dora2 > ..\Doraemon2_sound.asm`, `poko`) |
| `tools\agenda_cfg.py`, `agenda_parse.py`, `agenda_align.py`, `agenda_names.py`, `trace.py`, `sm83.py` | addresses per game, data walker, Doraemon↔Pokonyan code alignment, routine names/comments, code tracer, SM83 disassembler |
| `tools\agenda_verify.py` | reassembles both files and compares them with the ROMs |
| `tools\agenda_model.py`, `agenda_pyboy_check.py`, `harness.asm` | the Python model and the PyBoy test |

**No macros** are used. Code uses plain instructions with EQU names; every code line ends with its ROM address. Data is plain `db`/`dw`, one row per line with a comment:

```
    db $A5, $87                     ; default length 6
    db $A8                          ; envelope
    dw Env_4A43
    db $40, $85                     ; E4, 12
    db $34                          ; E3
    db $A9, $02                     ; loop end: 2 passes
```

The 7 entry points are exported (`::`). Labels: `MusicNN_ChN`, `SfxNN`, `Sub_xxxx`, `Env_`/`Sweep_`/`Noise_`/`DrumKit_`/`WavePtr_`/`Wave_xxxx`, `Pairs_xxxx` for unreferenced lists.

**Byte-identical** with RGBDS 1.0.0 (`python agenda_verify.py`; set `RGBDS` to the folder with the tools if they aren't on PATH):

| File | Bytes checked | Mismatches |
|---|---|---|
| Doraemon 2 | 16,177 | 0 |
| Pokonyan | 15,408 | 0 |

**PyBoy test.** `harness.asm` links the reassembled driver into a small MBC1 ROM. Its loop calls `Sound_Update` back to back, and a hook compares, after every call, all driver RAM (struct page, save page, 16 HRAM bytes) and the readable registers NR10, NR12, NR22, NR42, NR43, NR50 and NR51 with `agenda_model.py`.

| Run | Length |
|---|---|
| every music id | 3,000 updates |
| every SFX (after Stop) | 600 updates |
| music 00 with each SFX on top | 900 updates |
| each song + SFX, then Save, an SFX, Restore | 1,550 updates |
| Pokonyan's unused song | 3,000 updates |

| Game | Updates | Mismatches |
|---|---|---|
| Doraemon 2 | 257,741 | 0 |
| Pokonyan | 138,321 | 0 |

As a sanity check, removing the vibrato from the model gives 24,709 mismatching updates on Doraemon 2's music.

Paths the data never reaches (vibrato mode 3, `$A1`/`$A2` in Doraemon 2, `$AC` in Pokonyan) are modelled from the code but not exercised. To run: `pip install pyboy`, then `python agenda_pyboy_check.py dora2` (or `poko`).

## 12. Pokonyan on a Super Game Boy

Bank 8 has its own jump table. At boot, bank-0 code calls bank 8 `$4005`, which checks for an SGB (an `MLT_REQ` packet). If one is found it sets `[$C760]` = 1 and sends 8 `DATA_SND` packets ($79…).

From then on, the wrappers in §1 call bank 8 instead of bank 7:
- music (bank 8 `$400E`): the id maps through the table at $4FC5 to a 16-byte SGB `SOUND` packet (e.g. song $00 = `$41 $00 $00 $00 $01`, song $01 = score $05);
- SFX (bank 8 `$4011`): the id maps through $5107;
- Init/Stop (bank 8 `$400B`) send a fixed packet; the Update wrapper only counts down a timer at `[$C765]`.

So on an SGB the music comes from the SNES side, and this GB driver is never used. That path is packet tables, not a sound driver, and isn't part of this disassembly.
