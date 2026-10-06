# Prince of Persia (SFC/SNES) — Arsys Software Sound Driver

Reverse-engineered from `04 - Stage 1.spc` (ID666: *Prince of Persia*, "Stage 1", composers Toshiya Yamanaka & Tetsuya Nakano, dumper FirebrandX). Companion files:

- `PoP_Arsys_Driver.asm`: full annotated disassembly of the driver code ($0460–$150D)
- `pop_mml_extract.py`: dumps a song's order lists, ASCII MML and instruments from any SPC made with this driver
- `stage1_dump.txt`: output of the extractor for this SPC

> Driver lineage: VGMPF lists only "Arsys Software's custom sound driver" for this game. **Battle Zeque Den** (1994), Arsys's only other Super Famicom title, uses a revised version of the same driver. This is confirmed from `bzd-01.spc` ("Opening", Kenichi Yaguchi). The differences are in **§15**, and its annotated disassembly is in `BZD_Arsys_Driver.asm`.

---

## 1. Overview

- The music is stored as **plain ASCII MML text** and interpreted at runtime by the SPC700. No compiler or bytecode is involved. Phrases are NUL-terminated strings, and the only binary structures are a small song header, per-channel *order lists* (repeat count + phrase pointer), and an 11-byte instrument table.
- There are **16 logical channels**: 0–7 for music and 8–15 for SFX. SFX channel *n*+8 plays on DSP voice *n* and masks music channel *n* while active.
- Music runs at a **tempo-scaled tick rate**. SFX and all effects (LFOs, portamento, auto-pan, fade) run at a fixed **frame rate of 16.25 ms (~61.5 Hz)**.
- Two song buffers exist (A @ $1A80, B @ $3680), so the CPU can upload the next song while the current one plays.

## 2. Memory map (ARAM)

| Range | Contents |
|---|---|
| $0000–$00DF | Zero page: driver variables (cleared at reset) |
| $00F0–$00FF | SPC700 I/O |
| $0100–$01CF | Stack (SP initialised to $CF) |
| $0200–$044F | Per-channel arrays, 16 bytes each (see §11) |
| $0450–$0457 | Misc: $0452 last SFX slot, $0454/55 last SFX slot pointer, $0456 sync counter |
| $0460–$150D | **Driver code** |
| $1560–$1571 | SFX bank header: word instrument-table offset ($0312), then 8 slot offsets |
| $1572–$1871 | 8 SFX slots × $60 bytes (raw MML strings) |
| $1872–$1A7F | SFX instrument table (11-byte entries; 46 slots fit) |
| $1A80–$367F | **Song buffer A** ($1C00 bytes) |
| $3680–$3CFF | Song buffer B ($680 bytes) |
| $3D00–$3DFF | Sample directory, music SRCN $00–$3F |
| $3E00–$3EFF | Sample directory, SFX SRCN $40–$7F (relocated on upload) |
| $3F00–… | BRR sample data (music first, then SFX; $CB/$CC = next free address) |
| top of RAM | Echo buffer, ESA = –(EDL×8) pages (EDL 4 → $E000, EDL 1 → $F800) |

Constant tables inside the code block:

| Address | Table |
|---|---|
| $04EF | CPU command jump table (32 words, push/RET dispatch) |
| $083E | FIR presets, 4 × 8 bytes (preset 0 = `7F 00 00 00 00 00 00 00`) |
| $0B58 | Volume table, 16 entries: `00 03 07 0B 0F 13 18 1E 24 2B 34 3E 4C 60 78 7F` |
| $0B68 | Note pitch table, 14 words (see §6.2) |
| $0B84 | Quarter-sine table, 128 entries $00–$FF (equal-power pan law) |
| $0CFD | MML character dispatch table (32 words) |
| $149D | Bit masks `01 02 04 … 80` |

## 3. Timing

- Timer 0 target = $1A → one timer tick every **3.25 ms**. The main loop polls `$FD` and calls `TimerService` ($0868).
- **Frame**: every 5 timer ticks (16.25 ms) → `FrameUpdate` ($0893). This covers echo apply, fade, master volume, per-channel effects, and **one tick of every active SFX channel**.
- **Music tick**: an accumulator `$C1 += timerTicks × 16`. When it reaches **T** (`$25`), one sequencer tick runs for all music channels.
  - Tick period = **T × 0.203125 ms**, so a *larger* T is *slower*.
  - Stage 1 uses `T100` → 20.31 ms per tick. Its loop is 1728 ticks ≈ 35.1 s, which matches the ID666 length of 70 s (two loops).
  - T is never reset between songs. A song that doesn't set T inherits the previous one.
- Note lengths are raw tick counts. In practice the composers used **144 = whole note** (72 half, 36 quarter, 24 quarter-triplet, 18 eighth, 12 eighth-triplet, …). Every Stage 1 loop is exactly 12 × 144 ticks.

## 4. Song format

```
+0  word   instrument table offset (relative to song base)
+2  byte   channel enable mask (bit n = music channel n)
+3  word×8 order-list offset for channels 0–7 (relative to song base)
```

All offsets are relative to the song base ($1A80 or $3680).

### Order list (3-byte entries)

| count | word | Meaning |
|---|---|---|
| $01–$FD | phrase offset | Play the MML phrase *count* times |
| any | $0000 | Entry skipped |
| $FE | target offset | Jump: continue the order list at *base+target* (loop) |
| $FF | — | This channel ends (bit cleared in `$2E`, key-off) |
| $00 | — | Stop everything (`StopAll`) |

A phrase is an ASCII string ending in $00. When the repeat count runs out, the next order entry is read. Driver state (default length, octave, volume, instrument, flags) **carries across phrase boundaries**, so a phrase that omits `@`/`O`/`V`/lengths inherits them.

## 5. Instruments (11 bytes)

Table address = base + word[base+0]; entry = table + `@n` × 11.

| Byte | Meaning |
|---|---|
| 0 | SRCN (sample number; $40+ = SFX samples) |
| 1 | ADSR1 (driver forces bit 7 = ADSR on) |
| 2 | ADSR2 (GAIN is written as 0) |
| 3, 4 | **Tremolo** depth, period (frames). Added to volume |
| 5, 6 | **Vibrato** depth, period (frames) |
| 7 | LFO mode (shared by both LFOs, see §8) |
| 8 | Vibrato delay (frames after key-on before vibrato starts) |
| 9, 10 | Signed 16-bit fine tune *t*: pitch × (1 + *t*/256) |

Stage 1 instruments 0–2 use tune −28 (≈ –2 semitones), +30 on the snare-type @7/@10. See `stage1_dump.txt` for the full table.

## 6. MML command reference

The parser (`MML_ReadNext`, $0CC1) reads one byte at a time, **masks bit 7**, and dispatches via `(c & $3E)`, so every table slot serves two adjacent characters. Commands that don't consume time `RET` straight back into the parser. Notes and rests pop that return address, which ends the channel's work for the tick.

Numbers are unsigned decimal (`ReadNumber`, 8-bit wraparound). "n" below means an optional decimal argument, and a missing number reads as 0 unless noted.

### 6.1 Command table

| Cmd | Effect | Code |
|---|---|---|
| `A`–`G` *len* | Note. Optional length in ticks; **the length is sticky** (becomes the new default) | $0FFC |
| `#X` / `"X` | Sharp: the prefix comes *before* the letter (`#C`, `#F`) | $0EF9 |
| `R` *len*, `S` *len* | Rest (same sticky length) | $0ECB |
| `&` (also `'`) | Tie/slur: the next note changes pitch without key-on and keeps LFO phase | $0F04 |
| `[` (also `Z`) | Legato block start: next note keys on, following `&`-joined notes slur without restarting vibrato delay | $0F0B |
| `]` (also `\`) | Legato block end | $0F12 |
| `O` n | Octave 0–7 (default 4) | $0E58 |
| `+` / `-` | Octave up / down (wraps within 0–7) | $0F24/$0F2A |
| `@` n | Instrument n (no-op if unchanged; key-off, loads ADSR/LFO/tune) | $0E35→$11D8 |
| `V` n (also `W`) | Volume 0–15 via table $0B58 (default 13) | $0EDF |
| `^` | Volume +1 (wraps 15→0) | $0EE5 |
| `_` | Volume −1 (ignored at 0) | $0EE5 |
| `Q` n | Gate: key-off after len × n/16 ticks; `Q0` = full length | $0E98 |
| `P` n | Portamento speed (0 = off). Glide toward each new note at n × (3 << octave) per frame | $0E98 |
| `(` n / `)` n | Detune, signed byte, pitch × (1 + n/256). Plus the instrument tune | $0F1B |
| `=` n | Pan 0–127 (127 = left, 64 = centre, 0 = right). Also sets the auto-pan range = \|n−64\| | $0F34 |
| `<` / `>` | Pan hard left (127) / hard right (0) | $0F34 |
| `L` n | **Auto-pan** speed: pan sweeps by n/4 per frame between the `=` position and its mirror | $0DD3 |
| `T` n (also `U`) | Tempo (music only, ignored in SFX) | $0ED4 |
| `H` n | Echo on for this channel, echo volume = VolTable[n]; `H0` = echo off for the channel | $0D45 |
| `I` n | Echo feedback (EFB) = n | $0D7E |
| `J` n | Echo delay (EDL) = n & 15 (re-places the echo buffer) | $0D8B |
| `K` n | Echo balance 0–127 (64 = centre) | $0D98 |
| `$` n | Load FIR preset n (from $083E) | $0DE5 |
| `$`r`,`v | Write FIR coefficient r (DSP reg $r F) = v | $0E18 |
| `M` n | Pitch modulation (PMON) on (n≠0) / off for this voice | $0DAB |
| `N` n | Noise on with noise clock n (FLG bits 0–4); bare `N` / `N255` = noise off | $0E66 |
| `!` | Increment sync counter $0456 (CPU reads it with command $13) | $0D3D |
| `%…%` | Comment: everything up to the next `%` is skipped | $0E2A |
| space, `*` | Ignored | — |
| `X Y . /` and `` ` `` | No-op | $0D44 |
| $00 | End of phrase | $0F6D |

### 6.2 Pitch

Table at $0B68, indexed by `letter − 'A'`, with `#` adding 7:

| A | B | C | D | E | F | G | #A | #B | #C | #D | #E | #F | #G |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 4000 | 47D0 | 2600 | 2AB0 | 2FF0 | 32C0 | 3900 | 43D0 | 47D0 | 2850 | 2D40 | 32C0 | 35C8 | 3C60 |

- DSP pitch = table >> (6 − O), clamped to $3FFF. **A in O4 = $1000** (the sample's native rate).
- **Octaves 6 and 7 are identical** (no left shift is ever applied).
- `#B` = B and `#E` = F. There is no flat command.
- Final pitch = base × (1 + (detune + tune + vibrato)/256).

### 6.3 Example (Stage 1, channel 2)

```
)1@5V7=42O4L7C130)0+@17R8[#G6&#G72&#G]
```

Detune +1, instrument 5, volume 7, pan 42 with auto-pan at speed 7, octave 4, C for 130 ticks, detune back to 0, octave up, instrument 17, rest 8, then a legato block: #G for 6 ticks slurred into #G for 72, then #G again for 72 (sticky length).

## 7. Note processing (per tick)

1. When a channel's duration counter (`$30+X`) runs out, parsing resumes.
2. **Note/rest**: the length is read (sticky). Gate countdown = len×Q/16. Flags `$0220`:
   - bit 0 = tie pending (`&`)
   - bit 1 = inside `[ ]`
   - bit 2 = voice keyed-off / needs retrigger
   - bit 4 = resting
3. If neither a tie nor portamento is active, the voice gets a key-off, then LFO phases and the vibrato delay reset.
4. Key-on happens unless the note is tied or portamento is gliding. A note after a gate-off is always re-keyed.
5. Key-on writes SRCN/ADSR1/ADSR2/GAIN, then PMON, NON and KON.

## 8. LFOs (per frame)

There are two identical LFO engines per channel (`LFO_Step`, $0C04). The tremolo engine uses the arrays at $02A0–$0310, and the vibrato engine uses the same layout +$80 ($0320–$0390). Each engine holds depth, period, a step of depth/period with a fractional remainder, an accumulator, a value and a counter.

- **Tremolo**: volume index = VolTable[V] + |value| (clamped to $FF).
- **Vibrato**: pitch offset = |value| − depth/2, added to the detune. It is held at 0 for *VibDelay* frames after key-on.
- **Mode byte** (inst byte 7):
  - bit 1 = 0 (ramp mode): the value ramps by step each frame and is negated at each period, which gives a triangle once the abs() is applied. With bit 0 set, the value resets each period (to depth if bit 7 is set, otherwise 0) for a saw shape.
  - bit 1 = 1 (stepped mode): the value changes once per period. With bit 0 = 0 it toggles 0↔depth (square). With bit 0 = 1 it takes a random value from the LFSR at `$2C/$2D` × depth.
  - bit 7 sets the starting phase at key-on: modes 0/1 start at −depth, mode 2 at +depth, mode 3 at 0.

These shapes are traced from the code, not yet confirmed by ear.

Also per frame:

- **Portamento** steps the current pitch toward the target.
- **Auto-pan** bounces the pan between centre ± range. The volume write uses the equal-power sine table: L = vol·sin[pan], R = vol·sin[127−pan]. Mono mode (`$C3`) forces pan 64.

## 9. Echo

- Music and SFX keep separate echo state:
  - music: EON mask `$D0`, volume `$D7`, balance `$D8`, EFB `$D9`
  - SFX: EON mask `$D1`, volume `$DA`, balance `$DB`, EFB `$DC` (stored but unused)
- Echo writes use a **dirty countdown** in `$CE`. Any H/I/J/K command or an EDL change makes it negative, and when it counts back up to 0 the driver writes FLG/EON/EFB/EVOL once.
  - After a `J` change the wait is EDL+2 frames, so the new buffer region has time to settle before echo writes are re-enabled.
  - If no channel has echo, FLG bit 5 (echo-write disable) is set and EVOL is zeroed.
- EON = (music mask & ~SFX-active) | (SFX mask & SFX-active).
- EVOL comes from the SFX set while any SFX is playing, and from the music set otherwise.

## 10. SFX system

- The SFX bank header at $1560 is built at reset: instrument offset $0312 (→ $1872), then 8 slot offsets $0012 + n×$60.
- Command $0D *n* uploads a raw MML string into slot *n* and starts it on channel 8+*n* (= DSP voice *n*). There's no order list. The $00 terminator ends the effect, clears the channel's bit in `$2F`, and keys the voice off.
- SFX channels tick at **frame rate**, so lengths are in 16.25 ms frames and `T` is ignored.
- While SFX *n* plays, music channel *n* keeps sequencing silently. Its register writes are suppressed via `$2F`, and the music resumes on that voice afterwards.
- SFX instruments use SRCN $40+. Their directory entries are uploaded to $3E00 as **offsets** and relocated by the free-sample pointer `$CB`.

## 11. CPU ↔ APU protocol

**Status (always published):** port 2 = `$2F` (active SFX mask), port 3 = `$2E` (active music mask).

**Command handshake:**

1. CPU: port 0 = command, then port 1 = 1.
2. SPC: port 1 = 2 (ack).
3. CPU: port 1 = 0.

Arguments then follow with these handshakes:

| Routine | Handshake |
|---|---|
| `IO_RecvByte` $07DC | SPC sets port1=1 → CPU sets port1=1 with the byte in port0 → SPC 2 → CPU 0 |
| `IO_RecvWord` $076B | Same, but SPC signals 3 and the word arrives in ports 2 (lo) / 3 (hi) |
| `IO_RecvBlock` $0782 | 3 bytes per packet in ports 0/2/3. Port 1 is a packet counter the SPC echoes back. Every 16 packets the SPC services the timer, **so music keeps playing during uploads** |
| `IO_SendByte` $07EF | SPC puts the byte in port0 and sets port1=1. CPU acks |

| Cmd | Args | Action |
|---|---|---|
| $00 | — | Stop all music and SFX |
| $01 | byte buf | Play song from buffer A ($1A80, buf=0) or B ($3680) |
| $02 | word dirSize, block; word smpSize, block | Load the music sample dir → $3D00 and BRR → $3F00 (dirSize 0 = reset the free pointer only) |
| $03 | byte buf, word size, block | Upload song data to buffer A/B (stops it first if it's playing) |
| $04 | byte speed | Fade out (master volume steps every *speed* frames, then StopAll) |
| $05 | — | **Null entry, jumps to $0000** (avoid) |
| $06 | word size, block | Upload SFX bank to $1560, then start SFX channel 8 |
| $07–$09 | — | No-op |
| $0A | word addr, word len | Read back ARAM: sends *len* bytes via `IO_SendByte` |
| $0B | byte reg, byte value | Write a DSP register |
| $0C | byte count, count×11 bytes, word dirSize, block, word smpSize, block | Load SFX instruments → $1872 and SFX samples (dir → $3E00, relocated) |
| $0D | byte slot, word size, block | Upload an SFX MML string into a slot and play it |
| $0E | byte slot | Stop an SFX slot |
| $0F | IPL-style transfer | Writes $AA/$BB, waits for $CC, then receives blocks like the boot ROM and jumps to the address given (driver reload) |
| $10 | — | Pause music (key-off and zero the music voices, echo volume 0) |
| $11 | — | Resume music (re-keys the held notes) |
| $12 | (ack byte) | Status refresh |
| $13 | — | Return sync counter $0456 (set by MML `!`), then decrement it |
| $14 | byte | Mono flag (`$C3`) |
| $15 | — | Null (same as $05) |
| $16–$1F | — | Mirror $06–$0F (command is masked with $1F) |

## 12. RAM variables

**Zero page**

| Addr | Use |
|---|---|
| $08/$09 | Current song base |
| $12/$13 | Current bank base (song, or $1560 while running SFX) |
| $14/$15 | MML read pointer |
| $1A/$1B/$1C/$1F | Fade active / frame counter / level 0–15 / speed |
| $1E | Current channel bit |
| $24 | 1 while processing SFX channels |
| $25 | Tempo T |
| $28 | Music paused |
| $2C/$2D | Random LFSR |
| $2E | Active music channels |
| $2F | Active SFX channels |
| $30+X | Tick countdown |
| $40/$50+X | Phrase read pointer |
| $60/$70+X | Order-list pointer |
| $80/$90+X | Phrase start (for repeats) |
| $A0+X | Vibrato delay counter |
| $BF/$C1 | Frame / tempo accumulators |
| $C3 | Mono |
| $C4–$CC | Transfer size / dest / counter / SFX-dir dest / free-sample pointer |
| $CD | EDL |
| $CE | Echo dirty countdown |
| $CF | FLG shadow |
| $D0–$DC | Echo / PMON / NON masks and levels (see §9) |

**Per-channel arrays** (+X, X = 0–15)

| Base | Use |
|---|---|
| $0200 | Default length |
| $0210 | Detune |
| $0220 | Flags |
| $0230 | Volume |
| $0240 | Octave |
| $0250 | Instrument ($80 = none) |
| $0260 | Phrase repeat count |
| $0270 | Pan |
| $0280 | Vibrato delay |
| $0290 | LFO mode |
| $02A0–$0310 | Tremolo LFO state |
| $0320–$0390 | Vibrato LFO state |
| $03B0/$03C0 | Current pitch |
| $03D0/$03E0 | Target pitch |
| $03F0 | Portamento speed |
| $0400 | Q |
| $0410 | Gate countdown |
| $0420 | Pan fraction |
| $0430 | Auto-pan range |
| $0440 | Auto-pan speed |

Write-only or vestigial: `$11`, `$17`, `$1D`, `$22` (set to 1 on order-list jump), `$C0`, `$C2`, `$03A0`.

## 13. Quirks and bugs

- CPU commands $05/$15 jump to $0000.
- O6 = O7. `#B` = B and `#E` = F (no octave carry).
- Tempo persists across songs.
- `^` wraps volume 15 → 0.
- Lowercase `b`/`c` hit the sharp handler.
- Any stray character from `0` to `?` outside a command is handled as a pan command, chosen by its low 2 bits: `&3`=0 or 3 → `<`, 1 → `=n`, 2 → `>`. Example: a bare `1` acts like `=`.
- Command $06 starts SFX channel 8 using the *last* slot pointer ($0454/55), not slot 0.
- The SFX echo feedback (`$DC`) is stored but never written to the DSP. EFB always comes from the music set.

## 14. How the findings were checked

- **Phrase timing**: an independent tick counter run over the extracted MML gives a loop length of exactly 1728 ticks on all eight channels. Channel 4 is a 144-tick pattern, so it's 12 repeats; channels 2 and 6 have a 14-tick intro before the loop. This confirms the sticky lengths and the order-list semantics.
- **Pitch**: the DSP voice 0 pitch in the snapshot ($04C1) equals D/O3 ($2AB0>>3 = $0556) × (1 − 28/256). That confirms the pitch table, the octave shift and the fine-tune formula.
- **Volume**: voice 0 VOL ($24/$24) = VolTable[10] ($34) × sin[64] ($B5) >> 8. That confirms the volume table and the pan law.
- **Instrument**: voice 0 SRCN/ADSR (07/FF/EA) match instrument @16.
- **Snapshot**: it was taken mid-way through the first music tick. The return address $09A7 on the stack sits inside the `MusicTick` channel loop, and only channel 0 has been initialised.
- **Song length**: the ID666 length of 70 s ≈ 2 × 35.1 s loops at T100.

---

## 15. Battle Zeque Den revision (compared with Prince of Persia)

Source: `bzd-01.spc` (*Battle Zeque Den*, "Opening", composer Kenichi Yaguchi). Full annotated listing: `BZD_Arsys_Driver.asm`.

**What stays the same.** The song format, order-list codes ($00/$FE/$FF), 11-byte instrument layout, ASCII MML parser and character dispatch table, number parser, pitch/volume/pan tables, FIR presets 0–3 and tempo formula are all identical. `pop_mml_extract.py` now auto-detects the revision and decodes both games. Two checks back this up:

- The BZD Opening runs 5760 ticks at `T62` = 72.5 s, which matches the ID666 length of 72 s.
- `$3` loads FIR preset 3, `I60` gives EFB $3C, and `H11`+`K64` give EVOL $1F/$1F. All three match the DSP snapshot.

The code is a rebuild rather than a patch. It's shifted by +$20 at the start, the tables moved to the end, and roughly half of the routines changed.

### 15.1 Memory map

| | Prince of Persia | Battle Zeque Den |
|---|---|---|
| Driver code | $0460–$150D | $0480–$1503 |
| Tables (vol / pitch / sine / FIR) | $0B58 / $0B68 / $0B84 / $083E | $1504 / $1514 / $1530 / $15B0 |
| FIR presets | 4 | 4 + RAM user preset 4 @ $15D0 |
| Misc vars | $0450–$0457 | $0470–$0477 (+ $0450/$0460 arrays) |
| SFX bank header / slots | $1560 / $1572 + n×$60 | $1600 / $1612 + n×$60 |
| SFX instrument tables | 1 @ $1872 | 3 banks @ $1912, $1A7D, $1B01 |
| Song buffer A | $1A80 | $1B60 |
| Song buffer B | $3680 | $2D20 (**overlaps the sample directory**, so effectively unusable) |
| Sample directory | $3D00 (DIR $3D) | $2D00 (DIR $2D) |
| BRR data | $3F00, with free pointer `$CB` | $2E00. SFX banks at fixed $83F0 / $A4D0 / $CA20 |
| Initial EDL | 4 | 3 |

### 15.2 Timing: a second timer

- **Timer 1** ($FB = $1A, 3.25 ms) now does what timer 0 did in PoP: frame every 5 ticks (16.25 ms) plus the tempo accumulator. Tempo and lengths are unchanged.
- **Timer 0** ($FA = $21, **4.125 ms**) is a new *fast tick* (`FastTick`, $09A9). It handles:
  - deferred key-ons
  - auto-pan
  - the tremolo LFO
  - voice volume writes
- Portamento and vibrato stay at frame rate (`FrameFX_PortaVibrato`, $0AA7). KOF is cleared once per frame instead of per voice.

### 15.3 Deferred key-on (de-click)

- **PoP:** KOF and KON happen in the same tick, and DIR is rewritten on every key-on.
- **BZD:** a new note keys the voice off, sets `$80+X` = 1 (pending) and `$90+X` = 3. Three fast ticks later (~8–12 ms) `FastTick` writes SRCN/ADSR/GAIN, volume, PMON and NON, then KON. That gap gives the old note time to release before the new one starts.
- Tied/legato notes rewrite the voice registers without KON.
- Because of this, the phrase-restart pointer moved from `$80/$90` (PoP) to the new arrays `$0450/$0460`.
- When an SFX ends, the driver sets `$90+n` = 1 for the music channel it displaced. The music voice's instrument registers are then restored on the next fast tick (PoP left the SFX's registers on the voice until the next key-on).
- Resume-after-pause also goes through the delayed path.

### 15.4 Effects

| | PoP | BZD |
|---|---|---|
| Tremolo LFO | frame rate, period = inst[4] | fast-tick rate, period = inst[4]×4 (≈ same speed, smoother). **inst[4] ≥ 64 overflows** |
| Vibrato depth | inst[5] | **inst[5] / 2** (same data gives half the depth) |
| `@` change | key-off, LFO parameters reloaded, immediate volume write | no key-off and no volume write. LFO parameters/state reset. Registers apply at the next note |
| Auto-pan step | speed/4 per frame (≥ range bounces) | speed as signed 4.4 per fast tick (≈ same rate); bounces only when > range |
| Voice volume | 8-bit result can exceed $7F → **phase-inverted output** | each side clamped to $7F |
| `V` / `^` / `_` | written immediately | stored; written at the next note, or right away if auto-pan/tremolo is running |
| `^` at V15 | wraps to 0 | stays at 15 |
| Gate (`Q`) key-off | sets flag bit 2 | sets bits 2+4 (counts as resting, so resume won't re-key it) |
| Rest after `&` | not keyed off | always keyed off |

### 15.5 MML changes

- **`$r,v`** now writes coefficient r&7 into the RAM user FIR at $15D0. When r=7 the whole 8-tap set is written to the DSP, so a custom filter is entered as `$0,a$1,b…$7,h`. In PoP each `$r,v` wrote one DSP coefficient directly. `$4` recalls the user set.
- **`J`** (echo delay) is ignored inside SFX.
- The echo-delay change wait (`$CE`) uses a new formula, observed as −(30 − 2×(old+new)) frames for sums ≤ 14. It looks like a sign slip (probably meant 2×(old+new)+2), but it's harmless.
- SFX echo: EON = (music mask & ~SFX) | SFX mask. EON is zeroed when no channel has echo. The SFX echo balance is initialised by StopAll.
- **SFX instrument banks:** CPU command $0D's first byte is copied into the SFX channel's flag byte. Bit 5 or bit 6 makes `@n` index bank 1 ($1A7D) or bank 2 ($1B01) instead of bank 0 ($1912).
- Lowercase still isn't supported. The lowercase strings at $19E3–$1A7C (`t80H12=64Q0v13@0A2…`) are stale data inside the SFX instrument area, not live MML.

### 15.6 CPU protocol and commands

The handshake was redesigned. Every routine reports its state in port 1, then finishes with `IO_Ack`:

1. SPC writes 1 and mirrors port 1-in onto port 0-out until the CPU sends 3.
2. SPC writes $FF and waits for the CPU to send 0.

State codes on port 1: 1 = ack, 2 = wants a byte, 3 = wants a word, 4 = block transfer, 5 = sending a byte.

`IO_RecvBlock` now stores exactly *size* bytes. PoP always wrote whole 3-byte packets and could overrun by up to 2 bytes.

| Cmd | Prince of Persia | Battle Zeque Den |
|---|---|---|
| $02 | dir → $3D00, BRR → $3F00, sets free pointer | dir → $2D00, BRR → $2E00 (no free pointer) |
| $06 | upload SFX bank to $1560 + start | **no-op** |
| $0A | read ARAM back to CPU | **no-op** |
| $0B | write DSP register | **no-op** |
| $0C | SFX instruments → $1872; SFX dir → $3E00, relocated | byte **bank 0–2**, byte count, count×11 bytes → bank table; dir → $2D80/$2DC0/$2DE0; BRR → $83F0/$A4D0/$CA20 (fixed, no relocation) |
| $0D | byte slot, block | **byte flags** (→ $0477: $00/$20/$40 picks the SFX instrument bank), byte slot, block |
| $0F | IPL-style upload + jump | Same handshake, but **received bytes are discarded** (only the pointer advances). In practice it's "jump to address" |
| $05/$15 | null → $0000 | still null |

Commands $00, $01, $03, $04, $0E and $10–$14 behave the same. They use the new buffers and handshake, and the mirrors at $16–$1F are unchanged.

### 15.7 Summary

BZD is a maintenance revision of the PoP engine. The music data format is fully compatible: a PoP song would play on it, with half-depth vibrato and smoother tremolo. The revision:

- fixes clicks (deferred key-on), volume overflow, the `^` wrap and the transfer overrun
- adds banked SFX instruments and a programmable FIR
- drops the debug-style commands $06/$0A/$0B and the working upload in $0F
