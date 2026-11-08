# Source Sound Drivers: Workboy, Double Dragon 3, Pyramids of Ra

Disassembly and documentation of the sound code in three Game Boy ROMs whose audio was done by the British developer Source. Everything here comes from the code. No earlier research was used. The interfaces and timing were checked in PyBoy.

| ROM | Size | Mapper | Driver | Sound code / data |
|---|---|---|---|---|
| Workboy (U) (Unreleased) [!] | 128 KB | MBC1+RAM+batt | **Source v1** | bank 0 $0B76–$0B98, $33B1–$38CC, $398E–$3FAC; bank 3 $461E–$47A1 |
| Double Dragon 3 (U) [!] | 128 KB | MBC1 | **Source v2** | bank 0 $3AD2–$3FFF; bank 7 $4000–$5B58 |
| Pyramids of Ra (U) | 64 KB | MBC1 | **Ra** (unrelated) | bank 2 $4000–$7FFF (whole bank) |

## Summary

- There are **two unrelated drivers**:
  - **Workboy and Double Dragon 3 share one engine.** Workboy has the earlier version (v1) and DD3 a reworked one (v2). They share the same routine layout, frequency table, pitch-envelope format with its `$63` terminator, default envelope (`00 01 FF 63`) and NR51-gating method. Large parts of the code are instruction-for-instruction the same.
  - **Pyramids of Ra uses a different engine.** It plays time-stamped **MIDI events**: a 12-bit bar number, a 12-bit tick, a MIDI status byte and a data byte, with MIDI note numbers. It has nothing in common with the Source engine except the standard GB period values.
- **Source engine design.** It has two layers:
  - a **voice layer**: `Play(note, instrument, pan, length)` starts a note on the channel the instrument names, then a per-frame stepper runs its pitch envelope and length;
  - a simple **sequencer** of (note, length) pairs that calls `Play` whenever a voice goes idle.
  
  Notes end by **removing the channel's NR51 bits**, not by volume envelope.
- **Workboy is an organiser cartridge, not a game.** Its own code uses the voice layer for beeps and for a two-tone dialler (DTMF-like, raw frequencies on ch1 + ch2). Music is two-channel (ch1/ch2).
- **DD3 (v2)** adds:
  - a master volume nibble;
  - tempo-scaled length codes;
  - a third sequenced channel (ch4 drums);
  - a song-loop command;
  - a separate table-driven SFX routine.
  
  It drops ch3 support.

---

## 1. Source engine

### 1.1 Interface

| | Workboy (v1) | DD3 (v2) | Use |
|---|---|---|---|
| `Snd_Play` | $33FC | $3B6B | a = note index, b = instrument, c = NR51 bits, `wSndDuration` = length |
| `Snd_Voices` | $357E | $3CCE | per-frame voice stepper |
| `Snd_Sequencer` | $379C | $3E5C | per-frame music reader |
| `Snd_Update` | – | $3B00 | v2 wrapper: sequencer if `wMusPlaying`, then voices |
| `Snd_PlaySong` | $376C | $3E30 | a = song id |
| `Snd_StopMusic` | $380D | $3EF5 | stops music and clears ch1/ch2 from NR51 |
| `Snd_LoopSong` | – | $3EEF | restarts `wMusSong` (`$FE`) |
| `Snd_PlaySfx` | – | $3FA7 | a = SFX id (§1.7) |

**How each game drives it:**

- **Workboy.** The VBlank path calls `WbSnd_Voices` (from $260B). It then calls `WbSnd_Sequencer` while `wMusPlaying` ≠ 0 (from $265F).
  - Songs are started from $31D3 and from the bank-3 music player ($421E).
  - The game calls `WbSnd_Play` directly for its own sounds. For example, $2651 plays a=$2C, b=4, c=$11. The dialler at 3:$69D8 sets both gates to $FF and plays a=$FF (raw frequency in DE) on instruments 5 and 6 together.
- **DD3.** The main loop maps bank 7 and calls $3A21. That routine skips sound while paused, then jumps to `DdSnd_Update`.
  - Boot ($05E7) fills $C000–$C026 with $FF, stops music, then sets `wSndVolume`=$F0 and `wSndTempo`=4. Neither value changes again.
  - Seen in PyBoy: title song 6, which loops through `$FE`, with volume $F0 and tempo 4.

### 1.2 `Snd_Play`

1. **Frequency.**
   - The note index selects a word from the 48-entry frequency table (C2–B5, starting at $002C).
   - A rest arrives as the sequencer's note byte 0 minus the base: $D0 in v1, $DC (ch1/ch2) or $B8 (ch4) in v2. A rest uses frequency 0.
   - a = $FF uses the frequency in DE as given.
2. **Instrument.** b indexes the instrument table, and the instrument's first byte names the channel:

| Type | Bytes | Channel |
|---|---|---|
| 1 | NR11, NR12, envelope ptr | ch1 |
| 2 | NR21, NR22, envelope ptr | ch2 |
| 3 (v1 only) | NR32, envelope ptr, wave ptr | ch3: 16 wave bytes copied to $FF30 |
| 4 | NR42, NR43 | ch4 (no envelope) |

   - **Gates.** In v1, ch1 and ch2 do nothing but set the voice length while their **gate** (`wSndGate1/2`, the sequencer's last note byte for that channel) is 0. The gate check applies to every caller, not only music.
   - **v2 volume.** In v2, NRx2 = (instrument byte & $0F) + `wSndVolume`. On ch4 the raw byte is used if `wSndVolume` ≥ $A0.
   - **v2 type dispatch.** v2 has `jp` where v1 has `jp z`, so every type ≥ 4 (and type 3) goes to ch4.
3. **Start.** The first envelope entry is loaded, then frequency, trigger and length are written. c is ORed into NR51 (after clearing the channel's bits), and the channel bit is ORed into NR52. The NR52 low bits are read-only, so that write does nothing.

### 1.3 Voices (every frame)

For ch1 and ch2 (v1 also ch3):

1. **Length.** If the voice is active, its length counter is decremented. At 0 the voice is switched off: the channel's NR51 bits are cleared and State = $FF.
2. **Gate.** If the gate is 0, the channel's NR51 bits are cleared.
3. **Envelope.** Every *rate* frames, signed *delta* is added to the 11-bit frequency, which is written to NRx3/NRx4 without trigger. After *steps* steps the next entry loads. `$63` switches the voice off.

ch4 has only the length counter.

**v1 ch3 quirk.** ch3 decrements its length only when its envelope timer fires, so ch3 lengths count envelope steps, not frames.

### 1.4 Pitch envelopes

`env_step delta, steps, frames` (3 bytes) … `env_end` ($63).

| Envelope | Data | Effect |
|---|---|---|
| `WbEnv_Hold`, `DdEnv_Hold` | `0,1,255` | holds the note for 255 frames, then the voice ends |
| `WbEnv_Blip` | `0,3,1` | 3 frames |
| `WbEnv_Short` | `0,1,10` | 10 frames |
| `WbEnv_Vibrato` | `±4,2,1` × 10 | 20-frame wobble, then the voice ends |

Workboy's `WbEnv_Vibrato` and `WbEnv_Short` sit in bank 0 at $0B76, between game routines. The other two envelopes are next to the driver.

### 1.5 Sequencer

Each music channel reads its next pair only when its voice is idle (State = $FF). So a voice cut short by its envelope advances early.

| | Workboy (v1) | DD3 (v2) |
|---|---|---|
| Channels | ch1 (inst 0, NR51 $11), ch2 (inst 3, $11) | ch1 (inst 0, **NR51 $0B**), ch2 (inst 3, $11), ch4 (inst 8, $11) |
| Note byte | $30 + index (0 = rest) | ch1/2: $24 + index; ch4: any nonzero byte = hit (0 = rest) |
| Length | raw frames | code 1–6 → `DdDurTable[tempo*8 + code]` |
| `$F0–$FE` | skipped (low nibble discarded); every track starts with `$F0` | `$FE` = restart song |
| `$FF` | stop all music (followed by a `$01` that is never read) | stop all music |
| Song header | `dw ch2, ch1` (16 songs) | `dw ch2, ch1, ch4` (7 songs, data in bank 7) |

**Notes on the table:**
- Any channel's `$FE`/`$FF` acts on the whole song.
- **Duration table.** `DdDurTable` row *r* gives 1×, 2×, 3×, 4×, 6×, 8× of (r+3) frames. DD3 uses row 4, so code 1 = 7 frames.
- **DD3 ch4 drums.** There is a single drum instrument (`DdInst_Noise`: NR42 $A1 + volume, NR43 $21). The note byte is only used to look up a frequency whose nonzero-ness decides hit or rest.
- **DD3 songs.** Songs 4 and 5 end with `$FF` (jingles). The others loop with `$FE`.

Verified in PyBoy on Workboy song 0: ch1 pairs `49 0C`, `4D 18` advance after 12 and 24 frames.

### 1.6 RAM

| v1 | v2 | Name | Use |
|---|---|---|---|
| $C3B2/$C3BC/$C3C6 | $C001/$C00B | `wSndV1/2/3State` | 0 sounding, $FF idle |
| +1/2 | +1/2 | `…EnvPtr` | next envelope entry |
| +3, +4, +5, +6 | same | `…EnvDelta`, `Count`, `Rate`, `Timer` | |
| +7/8 | +7/8 | `…FreqLo/Hi` | |
| +9 | +9 | `…Dur` | length counter |
| $C3D0/$C3D1 | $C015/$C016 | `wSndV4State/Dur` | $80 sounding, $FF idle |
| – | $C000 | `wSndVolume` | NRx2 high nibble |
| $C3D2 | $C017 | `wSndPan` | NR51 bits |
| $C3D3/4 | $C018/9 | `wSndFreqLo/Hi` | |
| $C3D5 | $C01A | `wSndDuration` | length argument |
| $C3D6/7 | $C01B/C/D | `wSndGate1/2(/4)` | last sequencer note byte (gate 4 never read) |
| – | $C01E | `wSndTempo` | duration row |
| $C3D8, $C3DA | $C01F, $C021, $C023 | `wMusPtr1/2(/4)` | sequence pointers |
| $C3DC/$C3DD | – | `wMusInst1/2` | sequencer instruments (0, 3) |
| $C3DE | $C025 | `wMusSong` | |
| $C3DF | $C026 | `wMusPlaying` | |

### 1.7 DD3 sound effects

`DdSnd_PlaySfx(a)` writes a 5-byte entry from `DdSfxTable` straight to the registers.
- **Ids 0–4** are noise (NR41–NR44, plus an unused byte).
- **Ids 5–8** are ch1 (NR10–NR14).

An SFX does not claim the voice, so it lasts until the next music note on that channel. The pulse path sets NR51 with `ld a,[$0011]`, which reads the ROM byte $CF, where `ld a,$11` was clearly meant (see §4).

### 1.8 v1 → v2 differences

1. RAM moved ($C3B2 → $C000) and the ch3 voice was removed.
2. `wSndVolume` nibble added to every NRx2 write.
3. Length codes scaled by a tempo table replace raw frame counts.
4. A third sequenced channel (ch4 drums) was added. The sequencer's instruments are hard-coded instead of being kept in RAM.
5. `$FE` song loop added. `$Fx` skips and the `$FF,$01` end marker were dropped.
6. Note base changed from $30 to $24 (ch4 $48).
7. A `Snd_Update` wrapper and a table-driven SFX routine were added.
8. `Snd_PlaySong` no longer calls `Snd_StopMusic` first. Song headers grew from 4 to 6 bytes.

---

## 2. Pyramids of Ra driver

### 2.1 Interface (bank 2)

| Address | Entry | Called from |
|---|---|---|
| $4000 | `RaSnd_PlaySong(a)` | $0678 |
| $40A4 | `RaSnd_Update` | VBlank ISR via $0664, while $C388 ≠ 0. Before calling, the game copies its music option ($C48B) to `wRaMusicOn` |
| $431E | `RaSnd_PlaySfx(a)` | $0648, only if the SFX option ($C48C) is on. The wrapper first clears `wRaSfxActive`, so a new SFX always replaces the old one |
| $40D1 | `RaSnd_StopMusic` | never called |

- `RaSnd_PlaySong` loads the song header, resets the clock and sets NR50=$77, **NR51=$93** and NR52=$8F. With NR51=$93, ch1 plays on both sides, ch2 right only and ch4 left only.
- The driver does nothing while `wRaSndEnabled` ($C511) = 0.
- Seen in PyBoy: songs 0 and 4, SFX 13 and 17.

### 2.2 Timing

Each frame, `RaSnd_Update`:

1. counts down the SFX timer;
2. runs *ticks-per-frame* clock ticks (8 or 9 from the header). PyBoy shows the clock moving 9 per frame in song 0.

Each tick:
- **While music is on:** process the ch1, ch2 and ch4 events due now, then advance the clock.
- **Always:** run the ch1/ch2 vibrato.

**The clock** is a 12-bit tick counter (`wRaClockHi/Lo`) plus a bar counter (`wRaBar`).
- A bar is **$2FC ticks**. The data puts notes on a grid of $60 ticks, so a bar is eight such steps ($300). The last 4 ticks of each bar are dropped, and no event uses them.
- When the bar counter reaches the header's bar count, the song restarts. **Every song loops.**

### 2.3 Song header (12 bytes)

`dw ch4, ch2, ch1, ch3` then `db ticks_per_frame, bars, transpose1, transpose2`. The ch3 pointer is always 0 and is never used.

| Song | ch4 | ch2 | ch1 | Ticks/frame | Bars | Tr1 | Tr2 |
|---|---|---|---|---|---|---|---|
| 0 | $44CE | $4CB2 | $5211 | 9 | 40 | $2A | $1E |
| 1 | $585B | $5DB0 | $624C | 9 | 32 | $2A | $1E |
| 2 | $6756 | $6756 | $6756 | 8 | 24 | $1F | $1F |
| 3 | $6756 | $711F | $7723 | 9 | 40 | $24 | $24 |
| 4 | $7DBD | $7EB2 | $7F4D | 9 | 4 | $24 | $24 |

Song 2 plays the shared drum track on all three channels. ch1 and ch2 play the drum note numbers as pitched notes.

### 2.4 Events (5 bytes)

`bar:12 | tick:12 | status | data`. Each channel processes all its events whose bar (low 8 bits) and tick match the clock.

| Status | ch1 | ch2 | ch4 |
|---|---|---|---|
| `$9n` note on | freq = `RaFreqTable[note − transpose]`. Negative = skipped. Instrument 0 is reloaded. Skipped while an SFX plays | same (NR21/NR22 from the instrument) | NR41 = `RaNoiseLenTable[note − $48]` (notes $48–$53), NR42=$F9, NR43=$17, NR44=$C0 |
| `$Cn` program change | skipped | skipped | **not checked: played as a drum** |
| `$01` | stop music | – | – |
| `$74` | park the track | park the track | – |
| `$00` (`track_end`) | sentinel one bar past the end; never reached | | |

**Data facts:**
- There are no note-offs. Notes decay by NRx2 ($F4).
- `$01` and `$74` never appear in the data.
- Frequency table: 54 words. Entries 0–5 are 0, entry 6 is C2 and entry 53 is B5.

### 2.5 Instruments and SFX

The instrument table holds 24 entries of 8 bytes: NR12, NR10, NR11, SFX note, SFX frames, vibrato pattern, vibrato step, vibrato rate mask.

- **Music** always uses instrument 0 ($F4, $00, $40, …, pattern $CC, step 2, mask $1F), because program changes are skipped.
- **SFX:** `RaSnd_PlaySfx(a)` plays instrument a on ch1. It uses the instrument's own note index (no transpose) and holds ch1 for *SFX frames*.
- **Vibrato:** when (tick count & mask) = 0, the pattern byte is rotated right. A carry adds *step* to NR13, otherwise *step* is subtracted. Only the low frequency byte changes.

### 2.6 RAM

| Address | Name | |
|---|---|---|
| $C4EF / $C4F1 / $C4F3 / $C4F5 | `wRaPtrCh4/2/1/3` | event pointers |
| $C4F9 / $C504 | `wRaInstCh1/2` | always 0 |
| $C4FA / $C505 | `wRaTransposeCh1/2` | |
| $C4FB–$C503 | ch1 NR12, NR10, NR11, SFX timer, SFX note, freq lo, vibrato pattern/step/mask | |
| $C506–$C50E | ch2 equivalents | |
| $C50F | `wRaSfxActive` | |
| $C510 | `wRaMusicOn` | |
| $C511 | `wRaSndEnabled` | |
| $C512 | `wRaTickCount` | |
| $C513 / $C514 | `wRaClockHi/Lo` | |
| $C515 | `wRaBar` | |
| $C516 | `wRaSongBars` | |
| $C517 | `wRaSong` | |
| $C518 | `wRaTicksPerFrame` | |

---

## 3. Sound tables

| ROM | Music | SFX | Unreferenced / non-sound |
|---|---|---|---|
| Workboy | 16 songs (song 15 in bank 3) | game-driven via `WbSnd_Play`; 7 instruments | $38CD–$398D game code inside the sound region; $3FAD–$3FFF leftover x86 code from the PC tools |
| DD3 | 7 songs | 9 | bank 0 before $3AD2 and bank 7 $5B59–$7FFF are fill |
| Pyramids of Ra | 5 songs | 24 instruments (= SFX ids) | $7FF2–$7FFF fill |

## 4. Quirks

**Workboy**

- **Song 15's data is in bank 3** ($461E/$46C8). It only plays correctly while bank 3 is mapped, which it is when the bank-3 music player starts it.
- **Song 2 ch2 has no end marker.** Its last note ($3D) takes ch1's first byte ($F0 = 240 frames) as its length, then runs on through ch1's data. Song 13 ch1 runs on into song 14 ch2. In both cases music stops at the first `$FF` on either channel.
- **Notes off the end of the table.** Song 13 ch2 has a `C_6` and song 15 ch1 a `Cs6` (indexes 48/49). These are past the end of the frequency table, so they play the first song-table words as frequencies.
- **Gates also block game sounds.** A gate of 0 silences game sounds on ch1/ch2 too, which is why the dialler sets both gates to $FF first.
- No instrument has type 4, so the ch4 path is unreachable.
- Instruments 1 and 4 (`WbEnv_Vibrato`) always cut off after 20 frames.

**DD3**

- **Wrong SFX pan.** `DdSnd_PlaySfx` (pulse) uses `ld a,[$0011]` and gets NR51 |= $CF.
- **Unusual ch1 pan.** Music ch1 uses NR51 bits **$0B** (ch1, ch2 and ch4 on the right) where the other channels use $11.
- **Shared byte.** `DdInst_Noise`'s NR43 byte ($21) is the first byte of `DdDurTable`.
- `DdSnd_Play` tests `cp $DC` twice.

**Pyramids of Ra**

- Bar length is $2FC, not $300 (§2.2).
- **Program changes on ch4 play drums.** Songs 1–3 begin their drum track with a `prog_chg`. ch4 doesn't check the status byte, so it plays a hit with NR41 read from $442C (inside the instrument data) at song start.
- **Top note.** Song 0/1 ch2 reach frequency index 52 (note $52 − transpose $1E). Index 53 is the top entry.

---

## 5. Files

In `GBAudioLab\Source\`:

| File | Contents |
|---|---|
| `Workboy_sound.asm` | v1 driver, instruments, envelopes, wave, 16 songs (4 sections: bank 0 ×3, bank 3) |
| `DoubleDragon3_sound.asm` | v2 driver, tables, SFX (bank 0) + 7 songs (bank 7) |
| `PyramidsOfRa_sound.asm` | Ra driver and all data (bank 2) |
| `source_sound.inc` | Source macros and note constants; define `SRC_VER` (1 or 2) before including |
| `ra_sound.inc` | Ra macros (`song_header`, `ra_inst`, `note_on`, `prog_chg`, `track_end`) and MIDI note constants (C_4 = 60) |
| `hardware.inc` | register names |
| `tools\gen_src.py`, `gen_ra.py` | generators: `gen_src.py <Workboy ROM> <DD3 ROM> [outdir]`, `gen_ra.py <Ra ROM> [out.asm]` |
| `tools\verify.py` | assembles all three (rgbasm/rgblink on PATH) and compares them with the ROMs |
| `tools\emit.py`, `sm83.py` | disassembler / emitter used by the generators |

Every file assembles **byte-identical** with RGBDS 1.0.0 to the matching ROM regions:

```
rgbasm -o ra.o PyramidsOfRa_sound.asm
rgblink -p 0xFF -o ra.gb ra.o          ; compare bank $02 $4000-$7FFF
python tools\verify.py "Workboy (U) (Unreleased) [!].gb" "Double Dragon 3 (U) [!].gb" "Pyramids of Ra (U).gb"
```

| File | Bytes checked | Mismatches |
|---|---|---|
| Workboy | 3,298 | 0 |
| Double Dragon 3 | 8,327 | 0 |
| Pyramids of Ra | 16,384 | 0 |
