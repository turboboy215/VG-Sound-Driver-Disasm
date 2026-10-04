# SLICK/Audio v1.01 (Bitmasters, 1994) — SPC700 sound driver

These notes are based on the driver image used in **Earthworm Jim** (SNES): `Earthworm Jim ($0580).bin`, the SPC snapshot `04 - Snot a Problem.spc` and the SPCdas listing `Earthworm Jim.s`. The labeled disassembly is in `SLICK_EarthwormJim_labeled.s`. `slick_dump.py` dumps the banks, sounds, sequences, instruments and samples of any SPC made with this driver.

Signature string at `$0C70`: `SLICK/Audio v1.01 Copyright(C)1994 Bitmasters,Inc.`

Notation: `$xx` is hex. "Track" means a sequencer channel (22 of them). "Voice" means a DSP voice (8 of them). p0/p1/p2 are event parameters.

---

## 1. Overview

SLICK is a MIDI-like driver:

* The sequence data is a compact form of a Standard MIDI File. It has 7-bit note numbers, optional velocities, MIDI variable-length delta times, a separate gate time per note, pitch-bend events and a small set of `$E0-$EF` commands.
* **22 tracks** are shared between music and sound effects. Each started "sound" takes one track per part. **8 voices** are handed out to notes dynamically, based on priority and age. A track has no fixed voice.
* The 65816 can also send **raw MIDI channel messages** (note on/off, program, controller, pitch bend) through the event queue, so the SPC can be used as a live 22-channel MIDI synth.
* Samples, instruments and sound banks are uploaded and registered separately, and they can be placed anywhere in RAM. An upload evicts any registered bank that overlaps it.
* Every BRR sample carries its own **pitch table** (27 bytes before its start address), so tuning is per sample and needs no global frequency table.

## 2. Memory map

| Range | Contents |
|---|---|
| `$0000-$00EF` | Direct page: scratch, globals, per-track timers, per-voice state (see RAM equates in the `.s`) |
| `$0100-$01FF` | Stack |
| `$0200-$0243` | Queue write index (`$0202`) and 64-byte event ring (`$0204`, 16 × 4 bytes) |
| `$0264-$0273` | 16 **sync flags** (written by `EC/ED/EE`, read by the CPU) |
| `$0278-$02B6` | Globals: start params, pause, master volume, echo state, bank list |
| `$02B7-$04C6` | Track arrays, 22 bytes each |
| `$04C7-$057E` | Voice arrays, 8 bytes each |
| `$0580-$1D78` | **Driver code/data** (entry point `Reset` = `$0878`) |
| `$1E00-$22FF` | Instrument table: 10 arrays × 128 instruments |
| `$2300-$23FF` | Sample directory (DIR register = `$23`) |
| `$2400-…` | Free for uploaded banks, samples, key-split records |
| echo buffer | At the top of RAM: ESA = `$FF - EDL*8` |
| `$FF08-$FFA9` | More track/voice arrays in high RAM (`$FF12…`, `$FF94…`) |

CONTROL = `$03` (bit7 clear) hides the IPL ROM, so all of `$FFxx` is readable RAM. The v1.01 arrays end below `$FFC0` anyway; the older driver (see `SLICK_Version_Comparison.md`) uses RAM up to `$FFF5`.

## 3. Timing and tempo

* Timer 0 runs at 64 × 125 µs = **8 ms** (125 Hz). Timer 1 is enabled but unused.
* Each track has its own tempo, `TrkTempo = (T + 40) / 60` in 8.8 fixed point, where T is the tempo byte (header or `E7`) plus the tempo offset. Every 8 ms the track timer is decreased by `TrkTempo × ticks_elapsed`.
* The result is **BPM = T + 40 at 125 ticks per quarter note**. The Earthworm Jim data is written at 128 ticks per quarter (for example, 512-tick bars), so it plays about 2.3 % slower than the nominal BPM.
* A note's gate (length) counts down with the tempo of the track that owns it. Gates are stored **halved** in the data (value × 2 = ticks).

## 4. CPU ↔ APU protocol

### 4.1 Command handshake (`PollCPU`, `$192E`)

The driver polls APUIO0 while it waits for the next 8 ms tick.

1. The CPU writes a counter `c` to APUIO1 and a command (`$02-$16`) to APUIO0.
2. The driver echoes `c` on APUIO1 and sets its expected counter to `c+1`. It then runs the command.
3. The driver writes **Status** to APUIO2 and `0` to APUIO0. It then waits until APUIO1 = expected counter.
4. The CPU writes the next command (or `0`) to APUIO0 and the counter to APUIO1. The driver acknowledges on APUIO1. A non-zero value runs immediately, so commands can be chained. `0` ends the chain.

**Status** byte (APUIO2):

* bit0: a sync flag changed (set by `EC/ED/EE`, cleared by I/O `$08`).
* bit1: events were queued (set by I/O `$0A`, cleared when the main loop has run the queue).

### 4.2 I/O commands (`IoCmdTable`, `$0583`)

| Cmd | Handler | Function |
|---|---|---|
| `$02` | `$196D` | **Write byte stream.** For each byte: APUIO0 = data, APUIO2/3 = destination address, APUIO1 = counter. The driver stores the byte and echoes the counter. To end, send a counter value ahead of the expected one. |
| `$04` | `$1A12` | **Block upload** (FastReceive, 2 bytes per step). |
| `$06` | `$1993` | **Read byte stream.** APUIO2/3 = address, APUIO1 = counter. The byte is returned in APUIO3. Ends the same way as `$02`. |
| `$08` | `$198A` | Clear Status bit0, then the same as `$06`. |
| `$0A` | `$19AD` | **Queue events.** The driver puts its queue write index in APUIO2. The CPU answers with the byte count (APUIO3, a multiple of 4) and block-writes the events to `$0204+index` with FastReceive. Sets Status bit1. |
| `$0C` | `$1961` | Map the IPL ROM and jump to `$FFC0`, so a new driver can be uploaded (see bug list). |
| `$0E` | `$1A06` | Receive **LoadID** (word → `$02`) and **LoadAddr** (word → `$04`), then block upload like `$04`. |
| `$10` | `$1A33` | Install the **sample block** at LoadAddr into the DIR. *Ends the command chain.* |
| `$12` | `$1A8D` | Register the **sound bank** at LoadAddr, adding LoadID to its IDs. *Ends the chain.* |
| `$14` | `$1ADE` | Install the **instrument block** at LoadAddr, adding LoadID to the numbers. *Ends the chain.* |
| `$16` | `$1990` | Refresh `$FF08-$FF0F` (\|ENVX\| of each voice) and `$FF10` (mask of playing voices), then read like `$06`. |

**FastReceive** (`$19CB`) moves two bytes per step:

* APUIO0/1 carry the data. APUIO2/3 carry the destination address.
* A change in APUIO2 is the handshake, so the address must advance every step.
* The driver acknowledges by writing 0 and 1 alternately to APUIO0.
* The transfer ends on a step where APUIO3 (address hi) = `$01`. The two bytes of that last step are still written, into page 1 (the stack).

Install commands (`$10/$12/$14`) finish with `InstallExit`, which drops the dispatcher's return address. They always end the current command chain. Each one first calls `EvictOverlappingBanks`, which unregisters every sound bank whose range overlaps the new block.

## 5. Event queue (I/O `$0A` → `ProcessEventQueue`, `$1BAE`)

The queue is processed once per 8 ms frame. Each event is 4 bytes: `type, p0, p1, p2`.

| Type | Handler | Meaning |
|---|---|---|
| 0 | `QEv_Midi` `$1C52` | MIDI channel message: p0 = status, p1/p2 = data (§7) |
| 1 | `QEv_System` `$10A8` | System command p0 (§6) |
| 2 | `QEv_StartSound` `$1BE3` | Start sound **p0**, key offset **p1**, handle/ID **p2**. Uses a second 4-byte entry. |
| 3 | `QEv_Nop` | – |
| 4 | `QEv_RestartSound` `$1BD7` | Stop all tracks with handle p2, then the same as type 2 |

Second entry for types 2 and 4: `pan, volume, tempo offset, unused`.

* **pan**: bit7 set = use each track's pan from the header. Otherwise every track gets this pan (`$00-$7F`, `$40` = centre).
* **volume**: goes to TrkVolume (`$00-$7F`).
* **tempo offset**: added to the tempo byte (8-bit wrap, so it acts as signed).

The **handle** p2 is stored as `TrkSoundID`. All later control commands address a sound by this value. Handles **`$E0-$FF` count as music** and `$00-$DF` as SFX, which matters for track stealing (§10.2).

## 6. System commands (queue type 1)

| p0 | Meaning |
|---|---|
| `$01` | Stop everything: all voices off, all tracks free, echo delay/volume 0 |
| `$20-$3F` | Pitch-bend every track of sound p1. Semitones = low 5 bits of p0, sign-extended (−16…+15); fraction = p2/256 |
| `$80+n` | Sub-command `n` = p0 & `$7F`, listed below (`$0A` = p1, `$0B` = p2) |

| Sub | Meaning |
|---|---|
| `$02` | Stop sound p1 (`$FF` = all): tracks freed, voices keyed off |
| `$04` | Write DSP register p1 = p2 |
| `$05` | Stop all tracks and voices |
| `$06` | p2 ≠ 0: **pause**. Voice volumes are halved step by step, and the sequencer stops. p2 = 0: resume and restore the volumes |
| `$07` | Clear the instrument SRCN table (`$1E00-$1E7F` = `$FF`) and the bank list |
| `$10` | Tempo offset of sound p1 = p2 |
| `$14` | Ask sound p1 to **stop at its next loop end (`E2 nn`) or stop point (`EB`)**. If p2 ≠ `$FF`, the pair (p1, p2) is also stored in a 4-entry "chain" list at `$027B`. Nothing reads that list and the chain hook `$0F3B` is an empty `RET`, so chaining is unimplemented in this version |
| `$15` | Master volume = p2 (`$80+` = full), all volumes recomputed |
| `$20` | Stereo mode = **p1**: 0 mono, 1 stereo, 2 stereo with "surround" (right channel inverted on voices whose flags have bit5) |
| `$22` | Mute (p2 bit4 = 1) or unmute track `p2&$0F` (0 = all) of sound p1 |
| `$40-$4F` | Track n (`$40` = all) of sound p1: p2 < `$80` → program p2; p2 ≥ `$80` → change flags (param `$12`) |
| `$50-$5F` | p2 in `$C0-$3F` (signed −64…+63) → key offset. p2 in `$40-$BF` → transpose = p2 xor `$80` |
| `$60-$6F` | Pan = p2 |
| `$70-$7F` | p2 < `$80` → volume. p2 ≥ `$80` → velocity scale. Bit7 stays set, so only `$FF` means ×1.0 |

For `$4n-$7n`, **n is the track number inside the sound** (1…15; 0 = all tracks). Other sub-command values are ignored.

## 7. Live MIDI (queue type 0)

The MIDI channel (low nibble of p0) selects **track** 0-15 directly. Send `F0` on channel `$F` first. That runs `MidiReset`, which turns all 22 tracks into idle MIDI channels: the sequencer is disabled, ID = track index, volume/velocity `$7F`, pan `$40`, priority 0.

| Status | Action |
|---|---|
| `8n kk vv` | Note off: releases the oldest voice of track n playing key kk |
| `9n kk vv` | Note on (vv = 0 → note off). The voice is allocated with the track's program and priority. The gate is effectively infinite |
| `An`, `Dn` | Ignored |
| `Bn cc vv` | CC 7 → volume, CC 10 → pan. Other controllers ignored |
| `Cn pp` | Program change |
| `En p1 p2` | Pitch bend. **Non-standard**: p1 = signed semitones, p2 = fraction |
| `Fn` | n = `$C`: all voices off. n = `$F`: all voices off + MidiReset |

Messages to a track with the mute bit (TrkStatus bit0) set are ignored.

## 8. Parameter indexes

System commands, `E9` and MIDI all go through one pair of dispatch tables: `TrkParamTable` (`$05A9`, applied to the track) and `VoiceParamTable` (`$05C6`, applied to the voices already playing for that track, so the change is heard immediately).

| Idx | Track field | Voice action |
|---|---|---|
| `$00` | TrkVolume | VVolume, recalc volume |
| `$02` | TrkPan | VPan, recalc volume |
| `$04` | TrkKeyOffset | VKeyOffset, recalc pitch |
| `$06` | TrkTempoOfs (tempo recomputed) | – |
| `$08` | TrkVelocity | VVelScale, recalc volume |
| `$0A` | TrkBend (semitones + fraction) | VBend, recalc pitch |
| `$0C` | TrkTranspose | VTranspose, recalc pitch |
| `$0E` | TrkProgram | – (next note) |
| `$10` | Mute: TrkStatus bit0 = value bit4 | VMod bit1, recalc volume |
| `$12` | Flags: value bits 1/3/5 = new state, bits 0/2/4 = "change" masks | VFlags, recalc volume |
| `$14` | – | value ≠ 0 → VOL = 0; value 0 → recalc (pause/resume) |
| `$16` | – | recalc volume (after a master volume change) |
| `$18` | TrkChanVol | VChanVol, recalc volume |

## 9. Data formats

### 9.1 Sample block (I/O `$10`)

```
+0  word  block size
+2  byte  n = number of samples (max 64)
+3  byte  first SRCN (LoadID is added)
+4  n × { word start, word loop }   offsets relative to +3
```

The routine writes the DIR entries with **self-modifying code**. It patches the operands of the two `mov $xxxx+x,a` instructions at `$1A75/$1A7E` (see §12).

### 9.2 BRR sample pitch header

The 27 bytes in front of every sample's start address:

```
start-27  13 words  pitch values for C..B and the next C, for one octave
start-1   byte      base octave of that table
```

The pitch is computed as follows (`$163F`):

* `note = base + key offset + transpose + bend` (semitones), plus a fraction from fine tune + bend + vibrato.
* `P = table[note%12]`, linearly interpolated toward `table[note%12+1]` by the fraction.
* P is then shifted left or right by `note/12 − base octave`.
* `InstFlags2` bit0 clears the low nibble of P(L).

In the dump, most "loop" addresses equal `start-27`, which points at this header.

### 9.3 Instrument block (I/O `$14`) and instrument record

```
+0  word  block size
+2  word  offset to the records (from block start)
records: { instrument# (+LoadID, &$7F; $FF = end), 10 bytes }
```

The 10 bytes go to the ten 128-byte tables:

| Table | Byte | Meaning |
|---|---|---|
| `$1E00` InstSRCN | 0 | Sample number. `$FF` = empty. `$F8-$FE` = key-split / drum map (the install relocates it when ≥ `$FD`) |
| `$1E80` InstADSR1 | 1 | ADSR1, or GAIN value if flags bit2 = 0. For key splits: record pointer lo |
| `$1F00` InstADSR2 | 2 | ADSR2. For key splits: record pointer hi |
| `$1F80` InstFlags | 3 | bit0 echo, bit1 tremolo, bit2 ADSR (else GAIN), bit3 noise (note → noise clock), bit4 ignore ENDX (looped sample), bit5 release GAIN `$B7`, bit6 one-shot (no release; release `$B0`) — otherwise release `$BF` |
| `$2000` InstTranspose | 4 | Semitones added to the note |
| `$2080` InstFineTune | 5 | Pitch fraction |
| `$2100` InstFlags2 | 6 | bit0 coarse P(L), bit3 vibrato, bits4-7 tremolo rate |
| `$2180` InstVelTrem | 7 | bits0-3 velocity sensitivity: vel × (n+1)/16; n = 15 → raw velocity. bits4-7 tremolo depth |
| `$2200` InstVibrato | 8 | bits0-3 vibrato step, bits4-7 depth (`(hi>>1)|7`) |
| `$2280` InstModDelay | 9 | Vibrato/tremolo delay = nibble-swapped value / 2 (ticks) |

### 9.4 Key-split / drum-map record (`KeySplitLookup`, `$07AD`)

```
+0 ADSR1, +1 ADSR2, +2 n, then n × { key, target, flags }
```

* A zone matches when `key == note`. It can also match a few keys above the key:
  * flags bits0-2 ≠ 0: key+1 also matches, pitch + (flags & 7)
  * flags bit3: key+1 … key+4 also match, pitch + 6 / 11 / 15 / 0
  * flags bit4: key+1 … key+5 also match, pitch + 6 / 9 / 12 / 15 / 32
* The first matching zone wins.
* target bit7 = 1 → SRCN = target & `$7F`, using this record's ADSR. Otherwise target is an instrument number, and all of that instrument's parameters are used.
* The played note becomes **60** + flags bits5-7 + the near-match offsets above, so drum hits play at their natural pitch.

### 9.5 Sound bank (I/O `$12`) and sound entry

The bank starts at LoadAddr+2, after the block-size word. It is a chain of entries:

```
+0  word  entry size (next entry = this + size)
+2  byte  sound ID (+LoadID); $FF = end of bank
+3  byte  number of tracks n
+4  byte  tempo T (BPM = T+40)
+5  byte  sound flags (OR-ed into every track's flags)
+6  byte  echo present (0/1)
[+7 12 bytes if echo: EDL, EVOL L, EVOL R, EFB, FIR0..FIR7]
then n × 8-byte track headers:
    flags, priority, velocity, pan, transpose, program, word data offset (from entry)
pattern base = first byte after the track headers
```

Up to **8 banks** can be registered at once (BankStart/BankEnd at `$0297/$02A7`). `StartSound` (`$113D`) searches them in order.

**Track flags** (TrkFlags `$030F`, copied to VFlags):

| Bit | Meaning |
|---|---|
| 0 | Note events have **no velocity byte** (velocity `$7F`) |
| 1 | Don't treat a decaying envelope (< 8) as the end of the note |
| 2 | **Order-list mode**: the data offset points at a word list of pattern offsets |
| 3 | **Monophonic**: reuse the voice already owned by this track |
| 4 | Must stay 0 (driver bug, see §13) |
| 5 | Surround: right channel inverted when stereo mode = 2 |
| 7 | `E3` loops back to the loop point instead of ending |

**Priority**: a higher value wins. Only bits 0-5 are compared for voices; the full byte is compared for track stealing.

### 9.6 Order list (flag bit2)

* A list of words. Each word is an offset from the pattern base.
* A track starts at `base + word[0] + 1`, and `E8` moves to the next word. The first byte of every pattern is **skipped**.
* The list has no terminator. Patterns end the song with `E3`, or loop with `E2`.
* `E2 00` saves both the sequence pointer and the order-list position.

## 10. Sequence format

Every event is followed by a **delta time** (MIDI VLQ: 1-3 bytes, 7 bits each, bit7 = more). A track also begins with one delta.

| Byte | Event |
|---|---|
| `00-7F` | **Note**: `nn [vel] gate delta`. vel is present only if flag bit0 = 0. gate = VLQ, played as gate×2 ticks |
| `80-BF` | Ignored: `xx dd delta` |
| `C0-DF` | **Pitch bend**: `cs ff delta`. Semitones = low 5 bits of cs, sign-extended; ff = fraction/256 |
| `E0-EF` | Command (below), then delta |
| `F0-FF` | **Illegal**: indexes past the command table into code |

### 10.1 Commands `$E0-$EF` (`VcmdTable`, `$0CA2`)

| Cmd | Params | Meaning |
|---|---|---|
| `E0` `E1` `E4` `E5` `EA` `EF` | – | No operation |
| `E2 00` | 1 | **Loop start**: saves the pointer and the order-list position |
| `E2 nn` (nn ≠ 0) | 0 | **Loop end**: jump back to loop start, forever. If a stop was requested (system `$14`), the track ends instead. nn is not consumed |
| `E3` | – | **End of track**. If flag bit7 is set, loops back to the loop start |
| `E6 pp` | 1 | Program (instrument) pp |
| `E7 tt` | 1 | Tempo: BPM = tt + 40 (+ tempo offset) |
| `E8` | – | **End of pattern** → next order-list entry (order-list mode only) |
| `E9 cc vv` | 2 | Controller: cc = 1 → channel volume (param `$18`), cc = 2 → pan (param `$02`). Other cc values are skipped |
| `EB` | – | **Stop point**: the track ends here if a stop was requested, otherwise continues |
| `EC n` | 1 | SyncFlag[n&15] = 0, Status bit0 set |
| `ED n` | 1 | SyncFlag[n&15] = 1, Status bit0 set |
| `EE n` | 1 | SyncFlag[n&15] += 1, Status bit0 set |

`E0/E1/E4/E5/EA/EF` are free for a converter to use as padding. The Earthworm Jim data uses `EB` at the end of every pattern, so a stop request takes effect at the next pattern boundary.

Example (music track 1 of "Snot a Problem", 8 tracks, echo, order-list mode, no velocities):

```
91eb: 01          (skipped first byte of pattern)
91ec: 00          delta 0
91ed: e2 00  84 00   loop start, delta 512
91f1: eb     00      stop point, delta 0
91f3: e8             next pattern
```

## 11. Playback internals

### 11.1 Main loop (`$08D0`), once per 8 ms tick

1. Run the event queue. Clear Status bit1.
2. Wait for timer 0, calling `PollCPU` while waiting.
3. Volume fades (TrkStatus/VoiceState bit3). Nothing sets bit3 in this build.
4. Echo start-up state machine.
5. For voices 7…0:
   * age++
   * pending key-on → `VoiceKeyOn`
   * end detection (ENDX, or envelope 0 after release, or an envelope decaying below 8)
   * tremolo and vibrato
   * gate countdown → release
6. Unless paused, for tracks 21…0: `timer -= tempo`. While the timer is ≤ 0, run events (each delta is added back).

### 11.2 Voice allocation (`AllocVoice`, `$0B38`)

1. If the track is monophonic: the voice it already owns.
2. The **oldest free** voice.
3. The oldest voice with **lower** priority.
4. The oldest voice with **equal** priority.

The chosen voice is cut with GAIN `$9F`, and the new note is keyed on during the next voice pass. When a one-shot voice's gate runs out, its age is set to `$8000` so it is stolen first.

### 11.3 Track allocation (`AllocTrack` `$0F3C`, `StealTrack` `$1025`)

The driver takes the first free track of 22. If none is free:

* **Music** (handle ≥ `$E0`) takes any SFX track first. Otherwise it takes the lowest-priority music track, if that priority ≤ the new one.
* **SFX** takes the lowest-priority SFX track, if that priority ≤ the new one.

### 11.4 Volume (`$1584`)

```
v = vel' · f(VVelScale) · f(VVolume) · f(VChanVol) · g(Master)
f(n) = (2n+2)/256   ($7F → 1.0)      g(m) = 2m/256  (m ≥ $80 → 1.0)
R = v·2p/256,  L = v·($FF−2p)/256    (p = pan, $40 = centre)
```

In mono mode L = R = average. Surround mode inverts R. Tremolo scales L/R by `255 − (phase/4)·(depth+1)`, with a triangle phase 0…`$3F`. Vibrato adds a triangle offset (±depth, step = rate) to the pitch fraction.

### 11.5 Release

When the gate runs out, the voice switches to GAIN mode with `$B7`, `$B0` or `$BF`, chosen by instrument flags bit5/bit6. One-shot instruments (bit6) are not released.

### 11.6 Echo

A sound with echo data calls `SetEchoDelay`:

1. Echo writes are disabled and EVOL/EFB are zeroed. EDL and ESA are set.
2. After `$4F` ticks (~0.63 s), echo writes are enabled.
3. After `$28` more ticks, EFB is written and EVOL L/R ramp by 1 per tick to their targets.

This avoids noise from uninitialised echo memory.

### 11.7 Pause

`PauseState = $40` halves every voice's VOL L/R once per frame. PauseState goes up by 1 per voice, so the halving stops after 8 frames, when it reaches `$80` (VOL ÷ 256). While paused, the sequencer and voice ages stop.

## 12. Corrections to the SPCdas listing

1. **`$086F-$0877` is data** (`KeySplitOffsetTable`, read by `mov a,$086f+y` at `$0855`). SPCdas showed it as `nop / or a,(x) / asl $0f / nop / or a,(x) / or ($0f),($0c)`.
2. **`$1005-$1024` are 32 unreferenced garbage bytes.** Decoding them as code also **mis-aligned the real routine `StealTrack` at `$1025`** (called from `$0F54`). SPCdas showed `1023: sbc ($78),($e4) / 1026: clrv / 1027: asl $90 / 1029: lsr $8f / 102b: stop / 102c: or a,$ff8f+y …`. The correct code is `1025: cmp $0b,#$e0 / 1028: bcc $1075 / 102a: mov $16,#$ff / 102d: mov $17,#$ff / 1030: mov $18,#$ff / 1033: mov $19,#$ff`. The two listings agree again from `$1036`.
3. `$05F1` is a RAM variable. The `.s` shows `$2b` (the SPC snapshot value); the `.bin` has `$3d`.
4. `$1A75` and `$1A7E` are **self-modified**. Their operand `$2324` is only the snapshot value.
5. The `jmp ($0581+x)` at `$0580` uses base `$0581` because commands start at `$02`. The table really starts at `$0583`.

Every other instruction was checked byte for byte against an independent SPC700 opcode table: mnemonics, operand order of dp,dp / dp,#imm forms, branch targets, `bbc/bbs`, `mov1`, `cbne`, `dbnz`. All match. A recursive trace from `Reset`, `PollCPU` and all five jump tables reaches every byte of the image except the data areas above, the copyright string, the echo tables at `$1850` and one dead `RET` at `$1960`. The labeled listing reproduces the `.bin` exactly.

## 13. Bugs and quirks in the original driver

* **`$0D06`**: a note on a track with flag bit4 set jumps to a `RET` while the note byte is still pushed, which corrupts the stack. Flag bit4 must never be set.
* **`$0D93`**: at end of track, the loop meant to clear `VOwnerTrack[]` compares A (a status value) instead of X (the track). Stale links can let later parameter changes reach voices of a finished track.
* **`$1961`** (I/O `$0C`): `mov $f3,#$6c / mov $f2,#$ff` has its operands swapped. The intent was clearly FLG (`$6C`) = `$FF`.
* **`$18E8`**: `SetEchoDelay` compares with `EchoDelayCur`, which is only ever `$FF`, so the echo restarts on every song with echo data.
* **`$07AD`**: the near-match ranges of key-split zones are one key wider than the offset table. With flag bit4, key+5 reads `$20` from the first byte of `Reset`.
* System `$7n` with p2 ≥ `$80` stores the velocity scale with bit7 set. The volume formula only handles `$00-$7F` (and `$FF`) correctly.
* Unused or leftover: `EchoRegList` (`$1850`), the chain list (`$027B`), `ProcessFades`, the delayed key-on states 2/3, `UnusedRet` (`$1960`) and `$05E0`.

## 14. Files

| File | Contents |
|---|---|
| `SLICK_EarthwormJim_labeled.s` | Full labeled/commented disassembly (SPCdas syntax, addresses and bytes kept), RAM equates, corrections |
| `SLICK_Engine_Notes.md` | This document |
| `slick_dump.py` | `python3 slick_dump.py file.spc [--seq]`: lists banks, sounds, track headers, instruments and samples, and decodes all sequences |
| `SLICK_Aero_Circus_labeled.s` | Labeled disassembly of the older (1993, Aero the Acro-Bat) driver |
| `SLICK_Version_Comparison.md` | Comparison of the three driver versions (Home Alone, Aero, v1.01) |
| `slick_old_dump.py` | Dumper for SPCs made with the older driver |
| `SLICK_HomeAlone_labeled.s` | Labeled disassembly of the earliest (1991, Home Alone) driver |
| `slick_ha_dump.py` | Dumper for the Home Alone song format |
