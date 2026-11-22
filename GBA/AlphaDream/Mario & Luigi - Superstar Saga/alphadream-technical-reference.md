# AlphaDream GBA sound driver
## Reverse-engineering report and technical reference

**Subject files** (`…/GBAAudioLab/Alpha/`):

| Game | Code | Driver revision |
|---|---|---|
| Mario & Luigi - Superstar Saga (E) (M5) | `A88P` | **C** (fully disassembled, see §15) |
| Hamtaro - Rainbow Rescue (E) (M5) | `A84P` | **A** |
| Hamtaro - Ham-Ham Games (E) (M5) | `B85P` | **B** |
| Minna no Soft Series - Happy Trump 20 (J) | `BTLJ` | **B** |

**Provenance.** The ROMs contain no symbols or debug strings for the driver. Every name below was assigned in this
analysis. "Revision A/B/C" are labels for the three code variants found; they describe feature sets, not a proven
release order. Inferences are marked *(inferred)*. All addresses are for M&L:SS unless a game is named.

**Not part of this engine:** M&L:SS also carries the *Mario Bros. Classic* link-play images (GBA headers
`SUPER MARIODAX4E` at `0x08F50000` and `…DAX4J` at `0x08F6F5C8`). Those use Nintendo's MP2K (`Smsh` ident) and are
independent of the AlphaDream driver.

---

## 1. Executive summary

* **One engine, three revisions.** All four games share the same core: a 15 768 Hz stereo software mixer for **8
  DirectSound channels** plus the **4 PSG channels**, **3 players × 12 tracks**, and an own bytecode
  (`0xE0`–`0xFF` commands, everything below is a note). Code matches across games apart from the differences in §3.
* **Track n always drives hardware channel n**: tracks 0–7 → DirectSound channels 0–7, track 8 → square 1,
  9 → square 2, 10 → wave, 11 → noise. A song header is a 12-bit track mask plus offsets.
* **Players:** 0 = sound effects, 1 and 2 = music (M&L:SS plays BGM on player *slot + 1*). Lower players win a
  channel; a displaced track keeps running silently and takes the channel back afterwards (§4.2).
* **Notes:** `len key` (rev C) or `len key velocity` (rev A/B). `len` 1–0xDF is the gate time *and* the delta to the
  next event; `len 0` is a tie. Key bit 7 means "a delay byte follows" (§6.2).
* **Timing:** each track adds its `SPEED` (default 120) to an accumulator every frame and emits one tick per
  `divisor` (75). At 48 ticks per quarter note, BPM ≈ SPEED × 0.9955.
* **Instruments:** program → list of 8-byte key splits `{lo, hi, sample (bit 15 = fixed pitch), A, D, S, R}`.
  **Samples use the MP2K WaveData header** (`flags, rate·1024, loop start, length, s8 PCM`); key 60 plays at the
  recorded rate.
* **Mixer quirks:** the decay stage jumps straight to the sustain level on the next frame (D is effectively unused);
  release is linear (`env −= R` per frame); output wraps instead of clipping; pan runs from 0x00 = **right** to
  0xFF = **left**.

---

## 2. Map (M&L:SS, `A88P`)

| Item | Address |
|---|---|
| Driver code + tables | `0x0819B2D8`–`0x0819CBFF` (Thumb, one ARM fragment at `0x0819B2FC`) |
| IWRAM mixer (LZ77) | `0x0819B580` (289 bytes) → unpacked to `0x03001080` (344 bytes, ARM) |
| Song data | starts at `0x0819CC00` (song 0) |
| Song table | `0x0821DC50`: 51 × `u8 *` |
| SFX table | `0x0821DD20`: 355 × `u8 *` |
| Instrument table | `0x0821E2AC`: 261 × u16 offsets, entries follow |
| Sample table | `0x08A82088`: 236 × u32 offsets (relative to the table; 0 = empty) |
| Channel vtables | `0x08A82058`: 12 pointers → `0x0821DA64` (DS ×8), `0x0821DB88` (sq1), `0x0821DBA4` (sq2), `0x0821DBC0` (wave), `0x0821DBDC` (noise); `0x0821DC2C` = silent vtable |
| PSG register tables | `0x0821DBF8` (freq/control regs), `0x0821DC08` (envelope regs), `0x0821DC18` (duty regs) |
| PSG pitch table | `0x0821DA80`: u16 per semitone from key 36 (GB reg = 2048 − value) |
| Noise table | `0x0821DB4C`: NR43 byte per key 0x15–0x50 |
| Wave-volume codes | `0x0821DC28`: `60 40 80 20` (25 %, 50 %, 75 %, 100 %) |
| Wave patterns | `0x0821EC3E`: 16 bytes each |
| Pitch tables | `0x0819B310` (13 × u32 = 2^(n/12)·2^23), `0x0819B344` (key → octave/semitone byte) |
| Opcode table | `0x0819C5F4`: 32 Thumb pointers, `E0`–`FF` |
| Command table | `0x0819C428`: 10 pointers |
| Work area | `[0x03007FF0]` = `0x02000480` (set by `snd_Init`) |

### 2.1 Functions

| Address | Name | Role |
|---|---|---|
| `0819B510` | `snd_InitHardware` | unpack mixer, sound regs, DMA1/2, timer 0 |
| `0819C07C` | `snd_Init(work)` | store work pointer at `0x03007FF0`, reset players |
| `0819CA30` | `snd_Frame` | per frame: `snd_ProcessQueue`, `snd_UpdatePlayers`, `psg_UpdateAll` |
| `0819B6A6` | `snd_VCountIRQ` | flip playing half; re-arm DMA when half 0 starts |
| `0819B6D4` | `snd_MixIfNeeded` | mix the idle half via `snd_MixFrame` |
| `0819B3C4` | `snd_MixFrame` | envelopes + 8 channels → 264 stereo samples |
| `0819B46C` | `snd_MixChannel` | one channel (calls IWRAM loops) |
| `0819B2D8` | `snd_CalcStep` | pitch → resample step |
| `0819C3F0` / `0819C4EC` | `snd_ProcessQueue` / `snd_QueueCommand` | command ring |
| `0819C938` | `snd_UpdatePlayers` | channel arbitration, calls `trk_Step` |
| `0819C524` | `trk_Step` | the sequencer |
| `0819C1E4` | `plr_StartSong(p, n)` | |
| `0819C300` | `sfx_Start(n)` | |
| `0819B9C0` | `inst_Lookup(prog, key)` | |
| `0819B8C0`… | `ds_*` | DirectSound vtable (§9) |
| `0819BBB8`… | `psg_*`, `wave_*`, `noise_*` | PSG vtables, `psg_UpdateEnvelope` at `0819BD58` |
| `0819CA44`–`0819CB90` | `m_*` | API wrappers (§5) |

The ASM source (§15) carries all 62 function names with one-line descriptions. External helpers: `0x081DBB40`
`_call_via_r1`, `0x081DBB78` `__divsi3`, `0x081DBCE8` `__udivsi3`.

Game side (M&L:SS): `0x080196A8` runs `snd_Frame` + `snd_MixIfNeeded` when sound is enabled; IRQ slot 3 (VCount) →
`0x080196D0` → `snd_VCountIRQ`. `0x0801931C(slot, song, fade)` plays BGM on player `slot + 1`; `0x080195C8` →
`m_PlaySfx` (1 164 call sites).

---

## 3. Revisions

| | **A** (Rainbow Rescue) | **B** (Ham-Ham Games, Happy Trump 20) | **C** (M&L:SS) |
|---|---|---|---|
| Note | `len key vel` | `len key vel` | `len key` |
| `F1` | not a command | not a command | **VOLUME** |
| `FA` | not a command | **SFX priority** | not a command |
| SFX priority | none | table `u8[nSfx]` + `FA` (§5.2) | none |
| Velocity applied | every note (vtable[1]) | every note (vtable[2]) | — (`F1` only) |
| Tempo divisor | constant 75 in `trk_Step` | per player, cmd 8 | per player, cmd 8 |
| Commands | 0–7 incl. **fade out / fade in** | 0–9 (3, 4 = no-op) | 0–9 (3, 4 = no-op) |
| Channel vtable | 6 slots `on, vol, pan, pitch, off, restore` | 8 slots `on, on, vol, pan, pitch, off, restore, kill` | 7 slots `on, on, vol, pan, pitch, off, restore` |
| Extra | per-player fade delta (work `+0x49E`) | per-player clock (§4.3); vtable[7] cuts the channel before a restore | player flag bit 1 cleared at song start but never read |

Everything else — mixer, IWRAM loops, envelope, LFOs, loops `E8`–`EF`, PSG handling, header and instrument/sample
formats — is the same. Rev B's Happy Trump 20 also writes `entry.field << 3` into the noise control word (noise width
from the instrument).

### 3.1 Per-game addresses

| | Rainbow Rescue (A) | Ham-Ham Games (B) | Happy Trump 20 (B) | M&L:SS (C) |
|---|---|---|---|---|
| Driver code | `081996F8`– | `08094B7C`– | `08033FAC`– | `0819B2D8`–`0819CBFF` |
| Opcode table | `0819A9DC` | `08095FFC` | `08035420` | `0819C5F4` |
| Songs | `08694300` (40) | `080DED20` (56) | `0805A040` (23 + NULL) | `0821DC50` (51) |
| SFX | `086943A0` (110) | `080DEE00` (156) | `0805A0A0` (29) | `0821DD20` (355) |
| SFX priority | — | `080DF070` | `0805A114` | — |
| Instruments | `08694558` (130 progs) | `080DF10C` (256) | `0805A134` (64) | `0821E2AC` (260) |
| Samples | `08BCD510` (149, 109 empty) | `08100000` (368, 148 empty) | `0814B188` (112, 28 empty) | `08A82088` (236, 25 empty) |
| Vtable pointers | `08BCD4E0` | `080DECE4` | `0805A008` | `08A82058` |
| IWRAM mixer / DS channels | `03004080` / `03004B20` | `030059E4` / `0200CCF0` | `03004660` / `030076C0` | `03001080` / `03001B50` |

Happy Trump 20 also contains a link-play multiboot image (header at `0x0805B16C`, runs at `0x02000000`) with its own
rev B driver copy; its 24-entry song-pointer table (`0x0808911C` in ROM, `0x0202DFB0` at run time) is all zero in ROM, so it
was not analysed further.

---

## 4. Architecture

### 4.1 Frame flow

1. **VCount IRQ** (`snd_VCountIRQ`): toggle the playing half; when half 0 starts again, rewrite DMA1/DMA2 control
   (`0x8440`, `0x0440`, `0xB600`) to re-sync the FIFOs.
2. **Game frame** → `snd_Frame`: drain the command ring, step every active track of players 0, 1, 2, then update the
   PSG envelopes (square 1, square 2, wave, noise).
3. `snd_MixIfNeeded`: mix 264 samples (one frame at 15 768 Hz) into whichever half is not playing.

### 4.2 Players, tracks, channels

* 3 players × 12 tracks × 0x20 bytes at work `+0x000`. Track *n* of every player maps to channel *n*.
* `snd_UpdatePlayers` walks players 0 → 2. The first active track to reach channel *n* owns it. A later player's
  track *n* is flagged muted (`0x0002`) and stepped with the silent vtable, so it stays in time. When it gets the
  channel back it calls `restore` (rev B: `kill` first) and, if its note is still held, `note on` again.
* Player 0 is the SFX player. `sfx_Start` loads tracks into player 0 only for the bits set in the SFX mask and
  records the SFX id per track (work `+0x4B0`, used by `sfx_Stop` and `m_GetSfxTracks`).
* M&L:SS music avoids tracks 0–1 (49 of 51 songs; masks such as `07C`, `0FC`, `3FC`), leaving them to SFX. In the
  other three games nearly every song uses tracks 0–1 too, so an SFX on those channels mutes the music track while
  it plays.

### 4.3 Per-player clock (rev B)

Each frame, work `+0x4B0+4p` += 75; while it is ≥ the player's divisor it is reduced and `+0x4BC+4p` is incremented.
Both are cleared by `plr_StartSong`. The driver itself never reads `+0x4BC` *(inferred: a song-time counter for the
game)*.

---

## 5. Game interface

### 5.1 Command ring

`snd_QueueCommand(u16)` stores into an 8-entry ring at work `+0x480` (write index `+0x492`, read index `+0x490`,
both mod 8, no overflow check). `snd_ProcessQueue` runs every frame and dispatches on `cmd >> 12`:

| cmd | Rev B/C | Rev A | Arguments |
|---|---|---|---|
| 0 | play song | play song | `p = (c >> 8) & 0xF`, `song = c & 0xFF` |
| 1 | stop player | stop player | `p` |
| 2 | resume player (set active bit) | resume | `p` |
| 3 | — | fade out over `n` frames | `p`, `n = c & 0xFF`: volume 0xFFFF, step −0x10000/n; stops the player at 0 |
| 4 | — | fade in over `n` frames | volume 0, step +0x10000/n |
| 5 | play SFX | play SFX | `id = c & 0xFFF` |
| 6 | stop SFX | stop SFX | `id` |
| 7 | stop all SFX | stop all SFX | — |
| 8 | tempo divisor | — | `p`, `div = c & 0xFF` (`plr_StartSong` resets it to 75) |
| 9 | player volume | — | `p`, `v = c & 0xFF` → `v · 0x101` |

API wrappers (M&L:SS): `m_PlaySong(p, n)`, `m_StopPlayer(p)`, `m_ResumePlayer(p)`, `m_SetPlayerVolume(p, v)`,
`m_PlaySfx(id)`, `m_StopSfx(id)`, `m_StopAllSfx()`, `m_SetTempoDiv(p, d)`; `m_GetActivePlayers()` returns a player
bitmask, `m_GetSfxTracks(id)` the player-0 tracks playing that id.

### 5.2 SFX priority (rev B)

`prio = sfxPriority[id]`. For each track in the mask: if channel *n*'s player-0 track is active and its stored
priority (work `+0x4E0 + n`) is **lower** than `prio`, the track is skipped; otherwise the priority is stored and the
track starts. Lower values win; equal values replace. `FA p` changes the stored priority while the SFX plays. None
of the songs or SFX in the two rev B games use `FA`.

---

## 6. Sequence data

### 6.1 Song / SFX header

```
u16 mask              bit n = track n (= channel n) is used
u16 offset[popcount]  one per set bit, low bit first, relative to the header
```

`plr_StartSong` stops the player, resets the divisor to 75, sets the active bit and initialises each track:
flags `0x83`, data pointer, read offset 0, SPEED 120, wait 1, program 0, volume 200 (`0xC8`), pan `0x7F`, bend range
2, bend 0, detune 0. Song 0 of M&L:SS (and of Happy Trump 20) is an empty header (mask 0).

### 6.2 Notes (bytes `0x00`–`0xDF`)

```
rev C:    len key [extra]
rev A/B:  len key vel [extra]
```

* `key` bits 0–6 = key (60 = sample's own pitch, §9.1). Bit 7: an `extra` byte follows (see below).
* `vel` (rev A/B) is written to the track volume (`+0x0D`) and applied before the note sounds.
* **`len` 1–0xDF:** note on; after `len` ticks the note is released and the next event is read. If key bit 7 was set,
  the track sets flag `0x20` and from then on reads a rest byte *after each note's release*. The driver never clears
  `0x20`, so a bit-7 note would turn every later note into a 3-/4-byte note; the data never does this (every bit-7 key
  is on a tie, below).
* **`len` 0 (tie):** note on without a release. If the track is already in a tie, only the pitch changes (legato, no
  retrigger). Key bit 7 → `extra` = ticks to wait; without bit 7 the next event follows immediately. A later note
  with `len > 0` ends the tie (legato pitch change, then release after `len`).
* Before a non-legato note: LFO delays restart, `pitch` then `note on` are called.

### 6.3 Commands

| Byte | Args | Name | Effect (track offset) |
|---|---|---|---|
| `E0` | d, p, w | PITCH_LFO | +0x18 depth (1/256 semitone), +0x19 half-period (frames), +0x1A delay |
| `E1` / `E2` | — | PITCH_LFO on / off | flag `0x0100` |
| `E3` | d, p, w | VOL_LFO | +0x14 depth (volume units), +0x15 half-period, +0x16 delay |
| `E4` / `E5` | — | VOL_LFO on / off | flag `0x0800` |
| `E6`, `E7` | | — | not commands: read as a note with `len` 0xE6/0xE7 |
| `E8`–`EB` | n, s16 | LOOP_A (counter c = op & 3) | `++c > n` → jump; else `c = 0` |
| `EC`–`EF` | n, s16 | LOOP_B | `++c ≤ n` → jump and `c = 0`; else continue |
| `F0` | p | PROGRAM | +0x0C |
| `F1` | v | VOLUME (**rev C only**) | +0x0D, volume update |
| `F2` | p | PAN | +0x0E, pan update |
| `F3` | s8 | DETUNE | +0x11 (1/256 semitone, used at the next pitch update) |
| `F4` | r | BEND_RANGE | +0x0F, pitch update |
| `F5` | s8 | BEND | +0x10, pitch update |
| `F6` | t | REST | wait t ticks |
| `F7` | [t] | NOTE_OFF | release a non-tied note; if flag `0x20`, a rest byte follows |
| `F8` | s16 | GOTO | read offset += s16 (relative to the byte after the operand) |
| `F9` | s | SPEED | +0x02 |
| `FA` | p | SFX_PRIORITY (**rev B only**) | work `+0x4E0 + channel` = p |
| `FB`–`FE` (and `FA` in A/C) | | — | read as a note |
| `FF` | | END | release, track off |

Loop offsets are relative to the byte after the operands. `LOOP_A`/`LOOP_B` and `DETUNE` are almost unused: no game
uses `E8`–`EF`; `F3` appears 9 times (Rainbow Rescue, Ham-Ham Games). The LFO commands appear only in Happy Trump 20.
Songs end with a backward `F8` (loop) or `FF`.

### 6.4 Track record (0x20 bytes)

| Off | Field |
|---|---|
| +0x00 | u16 flags: `0001` active, `0002` muted, `0020` rest byte after notes, `0040` tie, `0080` note sounding, `0100` pitch LFO, `0200`/`0400` pitch-LFO phase, `0800` volume LFO, `1000`/`2000` volume-LFO phase |
| +0x02 | SPEED |
| +0x03 | tempo accumulator |
| +0x04 | u32 data pointer |
| +0x08 | u16 read offset |
| +0x0A | wait counter |
| +0x0B | key |
| +0x0C | program |
| +0x0D | volume / velocity |
| +0x0E | pan |
| +0x0F | bend range |
| +0x10 | s8 bend |
| +0x11 | s8 detune |
| +0x12 | channel (= track index) |
| +0x13 | player |
| +0x14–0x17 | volume LFO: depth, half-period, delay, counter |
| +0x18–0x1B | pitch LFO: depth, half-period, delay, counter |
| +0x1C–0x1F | loop counters for `E8`–`EF` |

### 6.5 Timing

Every frame (`trk_Step`): `acc += SPEED`; `ticks = 0; while (acc > div) { acc −= div; ticks++; }` with `div` = 75
(rev A) or the player's divisor (default 75). The wait counter is decremented by `ticks`; when it runs out, the
excess carries into the next events, so timing is exact over the song.

* Ticks per second = SPEED / div × 59.7275.
* With 48 ticks per quarter note (the data uses 12/24/48/96-tick values), **BPM = SPEED × 59.7275 × 60 / (div × 48)
  ≈ SPEED × 0.9955** at div 75.
* SPEED is per track, but every track of a song sets it; all songs start their tracks with the same value except one
  in Happy Trump 20. Mid-song changes occur in 6 M&L:SS songs, 2 Rainbow Rescue songs and 1 Happy Trump 20 song.

### 6.6 LFOs

Both LFOs are square waves that run only while a note sounds. On each non-legato note the counter is reloaded with
the delay. When the counter expires it is reloaded with the half-period; the first expiry enables the LFO phase
(`0x1000`/`0x0400`), later ones flip the sign. The value is ±depth: the volume LFO adds to the volume (clamped
0–255), the pitch LFO adds to the 8.8 pitch.

---

## 7. Instruments

`inst_table`: u16 offsets (relative to the table) indexed by program; program p's entries run from `off[p]` to
`off[p+1]`. Entries are 8 bytes, the first whose key range contains the key is used (none → note is silent):

| Off | Field |
|---|---|
| +0 / +1 | lowest / highest key |
| +2 | u16: DirectSound: sample index, bit 15 = fixed pitch (always played as key 60); square: duty (low byte, `<< 6` into NRx1); wave: wave pattern number; noise (Happy Trump 20): `<< 3` into the noise control word |
| +4–+7 | A, D, S, R |

M&L:SS: 261 offsets (260 programs; `F0` reaches 0–255), 241 entries, 42 fixed-pitch. Drum kits are programs with
one fixed-pitch entry per key (e.g. program 0: keys 0x21, 0x23, 0x24, 0x28, … → samples 0x24, 0x23, 0x64, 0x91, …).

---

## 8. Samples

`sample_table`: u32 offsets relative to the table; offset 0 = empty slot. The header is MP2K's WaveData:

| Off | Field |
|---|---|
| +0x00 | u32 flags: `0x40000000` = looped (byte 3 bit 6) |
| +0x04 | u32 rate = Hz × 1024 |
| +0x08 | u32 loop start (samples) |
| +0x0C | u32 length (samples) |
| +0x10 | s8 PCM |

M&L:SS: 211 samples (198 at 15 768 Hz, 7 at 44 100 Hz, 2 each at 7 884, 10 512 and 21 024 Hz), 2.47 MB of PCM.

---

## 9. DirectSound channels and mixer

### 9.1 Pitch

`ds_SetPitch`: `pitch = key·256 + bend·range·2 + detune (+ pitch LFO)` (8.8 semitones) → channel `+0x0A`.
`snd_CalcStep(rate, key, fine)`:

```
idx   = KeyOctaveMap[key]                      ; high nibble = octave shift, low = semitone
f     = (T[s] + (T[s+1] − T[s]) · fine / 256) >> octave     ; T = 2^(n/12) · 2^23
hi    = (rate · f) >> 32
step  = hi + (hi · 0x0A080000 >> 32)           ; ≈ hi · 16384/15768
```

`step` is in 1/1024 sample per output sample, so **step = Hz × 2^((key − 60)/12) / 15 768**: key 60 plays the
sample at its recorded rate. Bend ±127 at range r ≈ ±r semitones.

### 9.2 Channel record (16 bytes, `0x03001B50` + 16·ch)

| Off | Field |
|---|---|
| +0 | status: 0 off, `0x80` start, `0x81` attack, `0x82` decay, `0x83` sustain, `| 0x40` release |
| +1 | envelope (0–255) |
| +2 | u16 sample index (bit 15 = fixed pitch) |
| +4 | u32 position (samples × 1024) |
| +8 / +9 | right / left volume (0–0x7F) |
| +0x0A | u16 pitch (fine, key) |
| +0x0C–0x0F | A, D, S, R |

### 9.3 Envelope (once per frame, in `snd_MixFrame`)

| State | Per frame |
|---|---|
| start | → attack, env = A |
| attack | env += A; at ≥ 255: env = 255 → decay |
| decay | if env ≥ D: env = S → sustain (always true, since env = 255 on entry) |
| sustain | hold |
| release | env −= R; at ≤ R: off |

So D has no audible effect and the release is linear. `ds_NoteOff` only sets bit 6. A non-looped sample that
reaches its end turns the channel off; a looped one jumps back by `length − loopStart`.

### 9.4 Volume and pan

`ds_SetVolume`: `v = vol (+ volume LFO, clamped 0–255)`; `v = v · (playerVol/256 + 1) / 256`;
pan `p` (signed): `p ≥ 0` → right 0x7F, left `p`; `p < 0` → right `0xFF − p`, left 0x7F; each side `= side · (v+1) / 256`.
**0x00 = hard right, 0x7F/0x80 = centre, 0xFF = hard left.** PSG pan uses the same scale (≤ 0x80 enables right,
> 0x7E enables left).

### 9.5 Mixer

* `snd_MixFrame` (Thumb) runs the envelope, packs the channel volume as `R | L << 16` (× env / 256) and calls
  `snd_MixChannel`, which resamples through the IWRAM routines:
  * `mix_Resample` (`0x03001080`): `acc += u8sample · packedVol`, 7 samples per iteration, two 16-bit lanes per word;
  * `mix_AddConstant` (`0x0300111C`): pads a channel that ended;
  * `mix_Output` (`0x0300117C`): subtracts the bias Σ vol·128 (samples are read unsigned), takes bits 8–15 of each
    lane and writes 4 bytes to each of the left (FIFO A) and right (FIFO B) buffers. There is **no clipping**; sums
    wrap.
* Mix buffer `0x030011E0` (264 words); output `0x03001600`/`0x03001708` (left halves),
  `0x03001810`/`0x03001918` (right halves); flags at `0x030011D8`.
* `snd_InitHardware` clears only the first 64 bytes (4 records) of the channel array.

---

## 10. PSG channels

Vtables: square 1/2 `psg_*`, wave `wave_NoteOn`, noise `noise_SetPitch`; the 4 PSG states live at work
`+0x4C8 + 12·n` (n = 0 sq1, 1 sq2, 2 wave, 3 noise): A, D, S, R, volume, counter, duty, state, u16 freq, last
envelope byte.

* **Pitch:** `psg_KeyToFreq(8.8 key)`: table `0x0821DA80` from key 36, interpolated; register = 2048 − value
  (= standard GB tuning, key 60 = C4). **Bend is half as deep as on DirectSound** (`bend·range`, no × 2).
* **Volume:** `vol4 = vol · (playerVol/256 + 1) >> 12` (0–15).
* **Envelope:** emulated with the hardware envelope. Steps are `(255 − X) >> 5` (0 = no envelope). States: 1 note on
  (attack: start at 0, rising; or straight to decay if A = 0xFF), 2 attack, 3 decay (falls until
  `S·vol/256`, then constant), 4 sustain, 5 release (falling at R's step), 6 releasing; 0 off. Each state change
  re-triggers the channel.
* **Wave:** the instrument field selects a 16-byte pattern (`wave_Load`, cached at work `+0x4F8`); volume via
  `0x0821DC28` (vol>>2 → 25/50/75/100 %).
* **Noise:** `noise_KeyToNr43(key)`: `0x0821DB4C[key − 0x15]` for keys 0x15–0x50, `0xD7` below, 0 above.

---

## 11. Hardware setup (`snd_InitHardware`, identical in all four games)

| Register | Value |
|---|---|
| `SOUNDCNT_X` | `0x80` |
| `SOUNDBIAS` | `0x4200` |
| `SOUNDCNT_H` | `0x8800` (FIFO reset), then `0x120E`: PSG 100 %, A/B 100 %, **A → left, B → right**, both timer 0 |
| FIFO | 8 × zero words each |
| DMA1 | `0x03001600` → `0x040000A0`, `0xB6000004`; DMA2 `0x03001810` → `0x040000A4` |
| Timer 0 | reload `0xFBD8` (1064 cycles → **15 768 Hz**), enabled |
| `psg_InitRegs` | `SOUNDCNT_L` low byte `0x77`, `SOUNDCNT_X` `0x8F`, PSG volume bits = 2 |

264 samples per frame (15 768 / 59.7275).

---

## 12. Work area (rev C, `0x02000480` in M&L:SS)

| Off | Field |
|---|---|
| +0x000 | tracks: player p, track t at `0x180·p + 0x20·t` |
| +0x480 | u16 command ring [8] |
| +0x490 / +0x492 | ring read / write index |
| +0x494 | u8 player flags [3] (bit 0 active) |
| +0x498 | u16 player volume [3] (init 0xFFFF) |
| +0x4A4 | u32 tempo divisor [3] |
| +0x4B0 | u16 SFX id per player-0 track [12] |
| +0x4C8 | PSG states [4] × 12 bytes |
| +0x4F4 | u16 noise NR43 |
| +0x4F8 | u8 loaded wave pattern (0xFF = none) |

Rev B inserts the clock words (`+0x4B0`/`+0x4BC`) and shifts what follows: SFX ids `+0x4C8`, SFX priorities
`+0x4E0` [12], PSG states `+0x4EC`. Rev A has the fade delta at `+0x49E`.

---

## 13. Detection (for GBA2MID)

Byte signatures (Thumb, the first halfword is the `ldr rX, [pc, #imm]` that loads the table; `.` = any byte):

| Table | Signature | Revisions |
|---|---|---|
| Songs | `. 48 [AD|A4] 00 [2D|24] 18 [2D|24] 68 [A8|A0] 46` | A, B, C |
| SFX | `. 48 42 46 91 00 09 18 0C 68 A1 46` | A, C |
| SFX + priority | `. 49 98 00 40 18 04 68 A2 46 . 48` (2nd `ldr` = priority table) | B |
| Instruments | `. 4A 41 00 89 18 09 88 89 18 01 30` | A, B, C |
| Samples | `. 49 50 04 C0 0B 0F 58 7F 18` | A, B, C |
| Opcode table | `E0 38 0A 1C 1F 28 . . 80 00 . 49 40 18` (`ldr` at +10) | A, B, C |

Revision from the opcode table: `F1 ≠ E6` → rev C (2-byte notes); otherwise `FA ≠ E6` → rev B; otherwise rev A.
Song count: pointers up to the SFX table (or a NULL). Skip EWRAM literals (Happy Trump 20's multiboot copy). Other
cues: `0x03007FF0` used as the work-area pointer (as m4a does, so not unique), timer reload `0xFBD8` with
`SOUNDCNT_H = 0x120E`, and `SVC 0x11` right before it.

---

## 14. Notes for the MIDI converter

* **Channels:** track index = output channel. Tracks 0–7 are sampled; 8/9 square, 10 wave, 11 noise.
* **Time:** 48 PPQN; tempo from the first `SPEED` (BPM ≈ SPEED × 0.9955; exact: SPEED × 59.7275 × 60 / 3600). If a
  game sends cmd 8, scale by 75/div.
* **Notes:** emit note on at the event, note off after `len` (non-tie). Ties: hold until the next note with
  `len > 0` ends; pitch changes inside a tie are legato (portamento off, overlapping note-on/off or pitch bend).
* **Velocity / volume:** rev A/B velocity → MIDI velocity (`vel / 2`); rev C `F1` changes constantly (31 142 events in
  M&L:SS songs) → CC7 or CC11 (`v / 2`), notes at a fixed velocity.
* **Pan:** MIDI = 127 − pan/2 (the driver's scale is reversed).
* **Bend:** MIDI bend = bend × 64 with RPN 0 = range on tracks 0–7, range/2 on tracks 8–10. `DETUNE` → fine tune or
  folded into the bend.
* **Programs:** M&L:SS has up to 260 programs (only 0–255 reachable); map via a table. Fixed-pitch entries are drum
  kits.
* **Loops:** the backward `F8` gives the loop point; emit markers.
* **SFX** are songs on player 0; rev B priorities only matter for in-game mixing.
* `alphadream_seq.py` implements the walk above and finds all tables by signature.

---

## 15. Deliverables

* `mlss_sound_driver.s` — annotated GNU-as source of `0x0819B2D8`–`0x0819CBFF` (62 functions, jump tables, pitch
  tables, LZ77 mixer blob). Reassembles byte-identically
  (`arm-none-eabi-as`, `ld -Ttext=0x0819B2D8`, `objcopy -O binary`).
* `mlss_mixer_iwram.s` — the unpacked IWRAM mixer (`0x03001080`, ARM). Byte-identical to the BIOS-LZ77 output.
* `alphadream_seq.py` — reference parser (table detection, revision detection, event walk).

Tables per game: `alphadream-data-dump.md`.
