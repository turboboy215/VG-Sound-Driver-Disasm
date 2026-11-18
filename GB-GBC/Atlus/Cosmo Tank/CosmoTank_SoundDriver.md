# Atlus / Tsukasa Masuko Sound Driver: Cosmo Tank (GB)

Disassembly and documentation of the sound driver in *Cosmo Tank* (Atlus, 1990), whose sound is by Tsukasa Masuko. The last section compares it with his GBA driver for Brownie Brown's *Magical Vacation*, using `brownie-magvac-technical-reference.md` (GBAAudioLab\Brownie) and the MV ROM's own tables.

| ROM | Size | Driver | Driver RAM |
|---|---|---|---|
| `Cosmo Tank (U) [!].gb` | 128 KB, MBC1 | bank 4 `$4000–$5A9B` (code `$4000–$4465`) | WRAM `$DF00–$DFC7` |

Everything here comes from the code; the behaviour was checked in PyBoy against a model written from this document (§9).

## Summary

- **A small driver.** 1,126 bytes of code (including the 32-byte command table), which use bit tricks on `l` to step through the track record. Bank 4 holds only the sound data; `$5A9C–$7FFF` is fill.
- **Eight tracks, fixed roles.** Tracks 0–3 are the music on CH1–CH4; tracks 4–7 are SFX on CH1–CH4. An SFX track **mutes** the music track on its channel. The music keeps running silently and is restored when the SFX ends.
- **One sound table** of 36 ids for music and SFX. A header lists `{track, pointer}` pairs; id 0 stops everything.
- **Byte stream with no tempo.** `$00–$53` note (C2–B8), `$54` rest, `$80–$BF` length from a 64-entry frame table, `$C0–$DF` pan, `$F0–$FF` commands (the driver decodes only the low nibble, so `$E0–$EF` are aliases). One tick = one frame (VBlank).
- **Envelopes are scripts** of `{frames, NRx2}` pairs. Each step rewrites NRx2 and re-triggers the channel.
- **Same engine as Magical Vacation.** The MV driver (2001) has the same track roles and SFX muting, the same `{track, pointer}` headers with `$FF` end, and the same note/length/command byte layout. Its commands `F0–FC` mean the same as here, and it uses the same envelope scripts. Its 84-entry period table is **byte-identical**, and its first length row is too (§8).

---

## 1. Interface

The driver has no jump table. The game calls bank 4 `$4000` / `$407C` through bank-0 wrappers that map the bank with `$099A` and restore it with `$0997` (`[$C628]` = current bank):

| Bank 0 | | Effect |
|---|---|---|
| `$0030` (`rst $30`) | `SndQueue` | b = id. If `wSndQueueCount` + 1 < 5: count++, `wSndQueue[count − 1]` = b. A fifth request is dropped |
| `$1603` | `PlaySound` | saves af/bc/de/hl, `rst $30`. 83 call sites, almost all `ld b, id` |
| `$160D` | `SoundUpdate` | `di`, bank 4, `SndUpdate`, restore, `ei`. Called from the **VBlank** handler (`$0040` → `$0482`), so 59.73 Hz |
| `$161B` | `SoundInit` | saves registers, `di`, bank 4, `SndInit`, restore, `ei`. 37 call sites (boot, screen changes) |

| Bank 4 | Routine | |
|---|---|---|
| `$4000` | `SndInit` | NR52 = `$80`, NR30 = `$80`, NR12/22/32/42 = `$08`, NR14/24/34/44 = `$80`, NR50 = `$77`, NR10 = 0, NR51 = 0, the 8 track flags = 0. The queue is not cleared |
| `$407C` | `SndUpdate` | tracks 7 → 0, then `SndStartQueued` |

### 1.1 Sound ids and the queue

`SndStartQueued` runs at the end of each update. If the queue is not empty it decrements the count and starts `wSndQueue[count]`, so the **last** id queued starts first, **one id per frame**.

- `id × 2` is computed in 8 bits. If it is 0 (ids `$00` and `$80`), `SndInit` runs instead: every track stops.
- Otherwise `SoundTable[id]` points at a header: `{db track; dw first_event − 1}` repeated, ended by `$FF`. For each entry:
  - SFX track (4–7): set bit 7 (**muted**) in the flags of track − 4.
  - flags = (flags | 1) & `$81` (active; the mute bit is kept); timer = 1; attenuation, fine tune and transpose = 0; pointer.
  - The length, NRx1, envelope, pan, period and loop/call slots are **not** reset. Each stream sets what it needs.
- A sound replaces only the tracks it lists. A song does not stop SFX, and an SFX does not touch the other channels.

Ids in the game code (as `ld b, n`): `$01 $03–$05 $08 $0B–$18 $1A–$1E $20 $22 $23`; `$02`/`$06` via `[$CC89]` (stage music) and `$08 + n` from two computed sites. `$09`, `$0A`, `$07` and `$21` are not referenced directly.

---

## 2. Streams

The track pointer points at the last byte read; the header and `call`/`jump` targets are stored accordingly (the `track` macro writes `label − 1`). The driver reads events until a note, a rest or an end.

| Byte | Macro | Effect |
|---|---|---|
| `$00–$53` | `note C_2…B_8` | timer = length; play (§3.3). CH4: `noise $xy` (§3.4) |
| `$54` | `rest` | timer = length; `wTrackVol` = 8, flags bit 1; unless muted, clear the track's NR51 bits |
| `$55–$7F` | – | would read past the period table (unused) |
| `$80–$BF` | `len i` | length = `LengthTable[i]` frames (0 = 256) |
| `$C0–$DF` | `pan i` | `wTrackPan` = `PanTable[i + (track & 3)]`. Written to NR51 at the next note |
| `$F0 n` | `env n` | envelope of new notes = `EnvTable[n]` |
| `$F1 n` | `duty n` | NRx1 value (written at each note: duty for CH1/2, NR31 for CH3; not used for CH4) |
| `$F2 n` | `atten n` | subtracted from every NRx2 value (`$10` = one volume step; `$80`/`$B0`/`$C0`/`$D0` are common) |
| `$F3 n` | `transpose n` | added to the note (8-bit) |
| `$F4 n` | `loop_start n` | loop count = n, loop point = here (one level per track) |
| `$F5` | `loop_end` | count−−; if not 0, back to the loop point. So the body plays n times (0 = 256) |
| `$F6 addr` | `seq_call` | save the return, continue at addr (one level per track) |
| `$F7` | `seq_ret` | |
| `$F8 addr` | `seq_jump` | every looping track ends with a jump back |
| `$F9 n` | `fine n` | added to the period (unsigned) |
| `$FA n` | `sweep n` | track 0: `wSweepSave` = n, flags bit 2, NR10 = n unless muted. **Any other track: NR10 = n at once** |
| `$FB` | `sweep_off` | the same with 0, clearing bit 2 |
| `$FC addr` | `wave addr` | track 6: load the wave now. Other tracks: `wWavePtr` = addr, then load it unless muted (§3.5) |
| `$FD`, `$FF` | `seq_end_d`, `seq_end` | end of track (§4.2). Only `$FF` is used |
| `$FE` | `seq_nop` | nothing (unused) |
| `$E0–$EF` | | same as `$F0–$FF`: `CmdTable` is indexed by the low nibble. Unused |

Only `$F0–$FC` and `$FF` occur: 1,091 commands in the data.

**Lengths** (`LengthTable`, `$4556`). Four rows of 16; inside a row, columns `$4/$6/$8/$A/$C/$E` are 1/32, 1/16, 1/8, 1/4, 1/2 and whole notes, and the odd columns between them are dotted:

| Bytes | Quarter | Values |
|---|---|---|
| `$80–$8F` | 32 | 0 1 2 3 4 6 8 12 16 24 32 48 64 96 128 192 |
| `$90–$9F` | 40 | 72 144 94 0 · 5 7 10 15 20 30 40 60 80 120 160 240 |
| `$A0–$AF` | 44 | 6 9 12 18 · 5 0 11 16 22 33 44 66 88 132 176 0 |
| `$B0–$BF` | 56 | 0 0 0 0 · 7 0 14 21 28 42 56 84 112 168 224 0 |

The data uses 37 of the 64 entries.

**Pan** (`PanTable`, `$5A8C`): `pan 0` = both sides (`$11 $22 $44 $88` for CH1–4), `pan 4` = SO1/right (`$01 $02 $04 $08`), `pan 8` = SO2/left (`$10 $20 $40 $80`), `pan $C` = `$01 $20 $44 $88` (unused). Song `$06` alternates `PAN_R`/`PAN_L`/`PAN_C` note by note for an echo effect.

---

## 3. Frame update

```
for n = 7 .. 0, if flags[n] & 1:
    if --timer == 0:  read events (wCurTrack = n)              (§2)
    elif --envCount == 0:                                       envelope step (§3.2)
SndStartQueued
```

### 3.1 Track record

16 bytes at `$DF00 + 16n` (`TRK_*` in `cosmotank_sound.inc`):

| Off | Field | | Off | Field |
|---|---|---|---|---|
| +0 | flags: b0 active, b1 resting (never read), b2 sweep on (track 0), b7 muted by SFX | | +8 | stream pointer (2) |
| +1 | timer | | +A | length |
| +2 | envelope countdown | | +B | NRx1 |
| +3 | envelope position (2) | | +C | NRx3 / NR43 |
| +5 | attenuation | | +D | NRx4 (bit 7 = trigger) / `$80` |
| +6 | fine | | +E | envelope of new notes (2) |
| +7 | transpose | | | |

### 3.2 Envelopes

`EnvTable` (`$4596`) has 16 pointers. A script is `{frames, NRx2}` pairs (`env_step`):

| Env | Script | Use |
|---|---|---|
| 0 | `$FF,$F8` | full volume, held |
| 1 | `$FF,$20` | CH3 100 % |
| 2 | `1,$F8` `$FF,$08` | 1 frame at full volume, then silent |
| 3, 4, 5, 6 | `$FF,$F2` / `$F4` / `$F7` / `$F1` | full volume with a hardware decay (step 2/4/7/1) |
| 7, 8, 9, 10 | `10/8/5/4,$20` `$FF,$00` | CH3 staccato: 100 % for 10/8/5/4 frames, then mute |
| 11–15 | `$FF,$08` | silent (unused) |

- **Note-on**: countdown = the first frames byte; volume = NRx2 − attenuation. Below 0 it becomes `$00` on CH1–3 and `$08` on CH4.
- **Step** (countdown reaches 0): move to the next pair, volume = max(NRx2 − attenuation, 0). Unless muted, write NRx2 and **NRx4 = the stored period high byte with the trigger bit**.
- A frames byte of 0 lasts 256 frames. There is **no hold and no end marker**: a script ends with a `$FF`-frame pair, and after it the pointer would run on into the next script (§7).
- The countdown is not touched by events other than notes. It keeps stepping through **rests** (§7).

### 3.3 Notes (CH1–CH3)

```
period = Periods[(note + transpose) & $7F] + fine
trigger = $80, except on a CH3 track while NR52 bit 2 says CH3 is still playing
```

`Periods` (`$4466`) has 84 GB period values, index 0 = C2 (`$002C`, 65.4 Hz) … B8 (`$07EF`). CH3 sounds an octave lower. Unless muted, the note writes **NRx2, NRx1, NR51** (track pan bits replace the channel's old ones), **NRx3, NRx4**.

The CH3 rule avoids restarting the wave on every note, so legato on CH3 doesn't click. A `wave` command turns the DAC off, so the next CH3 note always triggers. Every CH3 track sets a wave before its first note.

### 3.4 Noise (CH4)

No transpose or fine. NR43 = the note byte with its nibbles swapped (the asm writes `noise $NR43`); NR44 = `$80`. The note writes NR42, NR51, NR43, NR44; NR41 is never written.

### 3.5 Waves

`LoadWave`: NR32 = 0, NR30 = 0, NR34 = `$80`, 16 bytes into wave RAM, NR30 = `$80`. Four waves at `$45D8` (`$45E8` is unused):

| Wave | Bytes |
|---|---|
| 0 `$45D8` | `01 23 45 67 89 AB CD EF FE DC BA 98 76 54 32 10` triangle |
| 1 `$45E8` | `FF F0 FF 0F 00 F0 FF FF 00 …` (unused) |
| 2 `$45F8` | `FF FF 88 88 FF FF FF FF 00 00 88 88 00 00 00 00` |
| 3 `$4608` | `13 57 9B DF FF FF FF FF EC A8 64 20 00 00 00 00` rounded pulse |

Music track 2 keeps its wave in `wWavePtr`, so it can be reloaded after a CH3 SFX.

---

## 4. Sound effects

### 4.1 Muting

Starting an SFX track sets bit 7 of the music track on the same channel. While it is set, the music track runs normally (timer, events, envelope, `wTrackVol`, period) but writes **no** sound register. Exceptions: its sweep and wave commands only update `wSweepSave` / `wWavePtr`.

### 4.2 End of track (`$FF`)

| Track | Effect |
|---|---|
| music (0–3) | flags bit 0 = 0; unless muted, NRx2 = `$08`, NRx4 = `$80` (silence, DAC on) |
| SFX, music track stopped | unmute it; silence the channel the same way |
| SFX, music track active | unmute it, then restore: **CH1** NR10 = `wSweepSave` if its flags bit 2 else 0; **CH3** reload `wWavePtr`; NR51 pan bits; NRx2 = `wTrackVol[music]`; NRx3, NRx4 + trigger |

So the music comes back immediately, mid-note, at its current envelope volume (but see §7, bugs 1 and 2). NRx1 (duty) is not restored.

---

## 5. Sound table

`SoundTable` (`$450E`), 36 entries. Frames at 59.73 Hz.

| Id | Header | Tracks | Length | Notes |
|---|---|---|---|---|
| `$00` | `$4618` | – | – | stop all (`SndInit`); the empty header is also `EmptyTrack` |
| `$01` | `$4619` | 0–3 | loop 4,224 f (70.7 s) | |
| `$02` | `$48ED` | 0–3 | loop 1,024 f (17.1 s) | via `$CC89` |
| `$03` | `$4A45` | 0–3 | loop 640 f (10.7 s) | |
| `$04` | `$4B0B` | 0–3 | loop 224 f (3.8 s) | |
| `$05` | `$4B9F` | 0–3 | loop 1,920 f (32.1 s) | |
| `$06` | `$4E82` | 0–3 | loop 2,048 f (34.3 s) | via `$CC89`; pan echo |
| `$07` | `$4FF7` | 0–3 | 4 f | all four tracks just end: **stop the music, keep SFX** |
| `$08–$10`, `$12–$14`, `$17`, `$1A–$1E` | | 4–7 | 4–36 f | SFX |
| `$0A` | `$502A` | 4, 6 | 6 f | track 4 = `EmptyTrack`: also cancels a CH1 SFX |
| `$0E`, `$1C` | | 4 | loop 10 f / 3 f | looping SFX (engine-like), until replaced |
| `$11`, `$15`, `$16`, `$18` | | music tracks | 90 / 66 / 28 / 130 f | jingles |
| `$19`, `$1F`, `$21` | | – | – | empty |
| `$1D` | `$5344` | 4, 5, 7 | 28 f | jingle `$16`'s streams played on the SFX tracks |
| `$20` | `$535C` | 0–3 | loop 224 f | |
| `$22` | `$5487` | 0–3 | 2,122 f (35.5 s) | ends |
| `$23` | `$575B` | 0–3 | 3,266 f (54.7 s) | ends |

Most song headers list track 1 first, then 0, 2, 3. Song `$06` track 0 loops with a `seq_call` into its own body, which never returns.

---

## 6. RAM

| Address | Name | |
|---|---|---|
| `$DF00` | `wTracks` | 8 × 16 (§3.1) |
| `$DF80` | `wSndQueueCount` | |
| `$DF81` | `wSndQueue` | 4 ids |
| `$DF8B` | `wCurTrack` | track whose events were read last |
| `$DF8C` | `wSweepSave` | |
| `$DF8D` | `wWavePtr` | |
| `$DF90` | `wTrackPan` | 8 NR51 masks |
| `$DF98` | `wTrackVol` | 8 current NRx2 values |
| `$DFA0` | `wCallStack` | 8 × return pointer |
| `$DFB0` | `wLoopStack` | 8 × {count, pointer} |

`$DF85–$DF8A` and `$DF8F` are not used by the driver.

---

## 7. Quirks and bugs

1. **Envelope volume goes to the wrong track.** The envelope step stores its volume at `wTrackVol + [wCurTrack]`. `wCurTrack` is only set when a track reads events (or an SFX ends), so the value lands in the slot of whichever track read events last. `wTrackVol` is only used to restore a channel after an SFX, which then gets another track's volume. In the emulator check this changed the restored NRx2 in 91 of 73,793 ticks (e.g. CH1 music restored at `$00` instead of `$74`, CH4 at `$38` instead of `$00`).
2. **Rests only clear NR51.** The envelope keeps stepping, rewriting NRx2 and re-triggering the old note silently. Flags bit 1 is never read, so an SFX ending during a music rest turns the channel's NR51 bits back on and re-triggers the old note. Its NRx2 is `wTrackVol`: the rest set it to `$08` (silent), but envelope steps may have overwritten it since (bug 1), and the next step rewrites NRx2 anyway, so the old note can sound until the music's next event.
3. **No envelope hold.** Scripts end with a 255-frame pair. Rests don't restart the envelope, so a note plus the rests after it lasting more than that would read past the script into the next one (then the waves and the headers). The data never does: notes are at most 192 frames, and running every sound for 17,200 frames in the model never moved an envelope past its script.
4. **Underflow differs.** At note-on, volume < 0 gives `$08` on CH4 but `$00` on CH1–3. At envelope steps it is `$00` for all.
5. **`sweep`/`sweep_off` on any track except 0 write NR10 directly**, even from CH2–CH4 tracks or while muted. Only track 4 uses it.
6. **NRx1 is not restored** after an SFX; the SFX's duty stays until the music's next note.
7. **8-bit index arithmetic.** Note + transpose wraps at 128; ids `$80–$FF` alias `$00–$7F` (and `$80` = stop all). Ids ≥ 36 would read past `SoundTable` (none are used).
8. **Pan index** `i + (track & 3)` can reach `$22`, past the 16-entry table. The data uses 0, 4 and 8.
9. **After `SndInit` CH3 is playing.** It was triggered with the DAC on at volume 0, so a CH3 note without a preceding `wave` would not re-trigger. All data sets a wave first.
10. **LIFO queue, one per frame.** Several ids queued in one frame start over several frames, last first, and a fifth one is dropped.
11. **Stale wave on restore.** Tracks run 7 → 0, so a CH3 SFX that ends in the same frame a song starts restores music track 2 *before* that track reads its first `wave` command. `LoadWave` then gets the old `wWavePtr`; at power-on (0) that is bank 0 `$0000–$000F`. The restore also re-triggers the stale period. Found by the random test (seed 6).
12. **`$5A9C–$7FFF`** is an `$00`/`$FF` fill pattern, never read. The asm keeps it as `Leftover`.

---

## 8. Comparison with Magical Vacation (GBA, 2001)

The MV driver is Masuko's at Brownie Brown (`brownie-magvac-technical-reference.md`). Eleven years later it is clearly **the same engine**, rewritten in ARM and extended with PCM tracks:

| | Cosmo Tank (GB, 1990) | Magical Vacation (GBA, 2001) |
|---|---|---|
| Code | SM83, 1.1 KB | ARM, ~3.7 KB, runs from ROM |
| Tracks | 8 × 16 bytes: 0–3 music CH1–4, 4–7 SFX CH1–4 | 12 × `0x38`: the **same 0–7**, plus 8/9 PCM music, 10/11 PCM SE |
| SFX muting | SFX on n mutes n − 4 (flag bit 7). The muted track runs silently. At its end: NR10 (CH1), wave (CH3), NR51, NRx2, NRx3/4 + trigger, or silence if the music has ended | **identical** (flag bit 1); also n − 2 for PCM |
| Header | `{u8 track, u16 ptr − 1}` … `$FF` | `{u32 slot, seq, patterns}` … `0xFF` |
| Start | active, timer 1; clears attenuation/fine/transpose; envelope not reset | active, wait 1; clears +0x24…+0x2F; envelope not reset |
| Queue | 4 ids, one started per frame (LIFO) | 4 ids, one started per frame (ring, FIFO) |
| Frame | timer−−; 0 → events, else envelope step | **identical** |
| Notes | `$00–$53` (+ `$54` rest) | `$00–$7F` (rest = `ED`, PCM `EC`) |
| Lengths | `$80–$BF`, 4 rows × 16 | `$80–$DF`, 6 rows × 16. **Row `$80` is byte-identical**; CT `$90` = MV `$90` from column 4 on; CT `$B0` = MV `$B0` except 2 entries; CT `$A0` = MV `$D0` (quarter 44) from column 5 on. Same column layout (4 = 1/32 … E = whole, odd = dotted) |
| Tempo | none: one tick = one frame | none: one tick = one frame |
| Pan | `$C0–$DF` index | `FD nn` |
| `F0` env, `F1` duty/NRx1, `F2` volume (subtracted from NRx2), `F3` transpose, `F4`/`F5` loop (single level, 0 = 256), `F6`/`F7` call/return (single level), `F8` jump, `F9` detune (added to the period), `FA` sweep (track 0/4), `FB` sweep off, `FC` wave | **all the same** | **all the same** |
| `F6`/`F8`/`FC` argument | 16-bit address | byte index into the song's pattern table / wave table |
| `FA` sweep | NR10 written when the command runs | written at note-on |
| `FD`, `FE`, `FF` | end, nop, end | pan, tie, end |
| `$E0–$EF` | aliases of `$F0–$FF` | `E2–E9` = `F2–F9`, `EF` = end, `E1` sample, `EC`/`ED` rests, others no-op |
| Envelopes | `{frames, NRx2}`, minus volume, every step re-triggers | **same**. `{frames, slide, level}` for PCM |
| Frames 0 | 256 frames | hold forever |
| Underflow | `$08` on CH4, `$00` CH1–3 (note-on) | `$08` (note-on) |
| Periods | 84 values, C2 `$002C` … B8 | **byte-identical** (`0x0805B5B4`) |
| Noise | NR43 = note nibble-swapped, no transpose | **same** |
| Channel tables | `RegTable`: NRx2/NRx4 per track | CNT_H/CNT_X address tables per track; pan tables `11 22 44 88` |
| Not in CT | | PCM (FIFO, timer pitch, sample command `E1`), tie, master fade |

The decisive matches are the command numbering `F0–FC` (13 commands in the same order with the same meanings), the identical period table and first length row, and the same SFX mute/restore design. Even the oddities carry over: the low-nibble command decode that makes `E0–EF` aliases, single-level loops and calls, "0 length = 256 frames", and volume as an NRx2 subtraction. In CT the pan is a byte range, and `FD`/`FE` are spare. MV later used those two slots for pan and tie, and took a separate rest byte instead of note `$54`.

*Sword of Mana* (2003) is a later revision of the MV engine (same track struct, headers and envelope format; per-track tempo row, mixed PCM), see `brownie-som-technical-reference.md`.

---

## 9. Verification

**Rebuild.** `tools/verify.py` assembles `CosmoTank_SoundDriver.asm` (`-Wall`, no warnings) and compares bank 4: **16,384 bytes, 0 mismatches**.

**Emulator.** `verify/emucheck.py` links the generated asm into a harness ROM (`verify/harness.asm`: `SndInit` at boot, `SndUpdate` once per VBlank). It runs the harness in PyBoy, hooking all 41 `ldh` stores in the driver, the NR52 read and `SndUpdate` itself. A script queues ids the way `rst $30` does. `tools/model.py` was written from this document. Each sound-register write, tick by tick, the NR52 reads, and the RAM state (track records, `wTrackVol`, `wTrackPan`, `wCurTrack`, sweep, wave, loop and call slots) were compared with the model's:

- every id alone, after a stop, until its tracks end (3,000-frame cap for loops);
- every song with every SFX fired on top, then five ids queued in one frame;
- random ids (bursts of 1–5, stops included) with 9 seeds of 20,000 ticks each.

Result (`verify/emucheck.log`): **0 mismatching ticks, 0 NR52 mismatches, 0 RAM mismatches**. The fixed cases plus 5 complete random seeds give 156,343 ticks and 419,839 register writes. The other 4 seeds also matched for 8,000–13,000 ticks each, until PyBoy froze.

**PyBoy freeze.** PyBoy 2.9 can hang inside one of `LoadWave`'s first register writes (NR32/NR30/NR34, straight-line code with no branch), in some APU states only. That's an emulator fault, not the driver. Long runs are therefore split into seeds (`emucheck.py <rom> <ticks> <seed>`), and progress lines keep the partial result. The harness must also run with sound emulation on (the NR52 channel bits are wrong without it) and `tick(…, sound=False)`.

Sensitivity: the first version of the model stored the envelope volume in the track's own slot (bug 1 "fixed"). It failed 91 ticks of a run with 20,000 random ticks; `FIXBUG=1` still reproduces this (48 ticks with 2,000). So the check catches a single wrong value in a RAM slot that is only read when an SFX ends.

## 10. Files

In `GBAudioLab\Atlus\`:

| File | Contents |
|---|---|
| `CosmoTank_SoundDriver.asm` | bank 4: driver (commented), tables, envelopes, waves, 36 sounds, leftover |
| `cosmotank_sound.inc` | registers, track fields, note names, macros (`track`, `hdr_end`, `env_step`, `note`, `noise`, `rest`, `len`, `pan`, `env`, `duty`, `atten`, `transpose`, `loop_start`, `loop_end`, `seq_call`, `seq_ret`, `seq_jump`, `fine`, `sweep`, `sweep_off`, `wave`, `seq_end`, `seq_end_d`, `seq_nop`), WRAM |
| `tools\gen_ct.py`, `tools\inc_static.txt` | generator |
| `tools\ct.py`, `tools\sm83.py`, `tools\listing.py` | data parser, disassembler, listing helper |
| `tools\verify.py`, `tools\model.py` | rebuild check, reference model |
| `verify\harness.asm`, `verify\build.sh`, `verify\emucheck.py`, `verify\emucheck.log` | emulator check |

RGBDS 0.9.1, PyBoy 2.9:

```
python tools\gen_ct.py "Cosmo Tank (U) [!].gb" .
python tools\verify.py "Cosmo Tank (U) [!].gb" .
sh verify\build.sh
python verify\emucheck.py "Cosmo Tank (U) [!].gb" 20000 1990   (fixed cases + random seed 1990; other seeds: random only)
```
