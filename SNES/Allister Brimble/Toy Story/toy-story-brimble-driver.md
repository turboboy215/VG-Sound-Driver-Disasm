# Toy Story (SNES) — Allister Brimble Sound Driver

Reverse-engineered from `03 - That Old Army Game.spc` (ID666: *Toy Story*, "That Old Army Game", artist Randy Newman / Patrick J. Collins, dumper Knurek, length 101 s + 12 s fade). Companion files:

- `TS_Brimble_Driver.asm`: full annotated disassembly of the driver code and tables ($0200–$13F8)
- `ts_extract.py`: dumps the song header, every track's events, the programs/regions, samples and pitch envelopes from any SPC made with this driver
- `army_game_dump.txt`: output of the extractor for this SPC

> This is a completely different design from the Arsys driver (§ PoP/BZD doc). There's no MML or bytecode language. Songs are **MIDI-style event lists**: 4-byte events with a note number, velocity and duration, played on **16 tracks** that share **8 voices** through dynamic voice allocation with priorities. Instruments are **program → region chains** (key splits and layers), and the driver can also **synthesise waveforms** (pulse/PWM, noisy square, random-noise blocks) into per-voice BRR buffers.

---

## 1. Overview

- **16 tracks, 8 voices.** Tracks own no voice. Each note allocates the lowest-priority voice at or below its own priority, and a program can trigger several voices at once (layers).
- **Event list format.** Every event is exactly 4 bytes: `[note|cmd] [velocity|value] [duration] [delta]`. Velocities and gate lengths are humanised (e.g. vel 71/76/79, dur 8–15 on straight eighths), so the data almost certainly comes from a MIDI conversion.
- **Two timers:**
  - timer 0 is the **sequencer clock**. Its period is set by the tempo event (10000/BPM × 125 µs, which gives 48 ticks per quarter note).
  - timer 1 is a fixed **10 ms frame** that runs key-ons, envelopes, pitch, volume and every effect.
- **Pitch** is note-based (MIDI note + transpose + 1/256-semitone fine tune), converted through a 192-entry, 1/16-semitone table with linear interpolation.
- **Song data, samples and instrument tables are uploaded at runtime** through CPU commands into a bump-allocated area from $2179 upward.

## 2. Memory map (ARAM)

| Range | Contents |
|---|---|
| $0000–$005A | Zero page: driver variables (cleared at reset) |
| $00F0–$00FF | SPC700 I/O |
| $0100–$011F | **Sample directory, 8 entries only** (DIR = $01). SRCN *n* = voice *n*, and the entry is rewritten at every key-on |
| $0120–$01FF | Stack (SP = $FF) |
| $0200–$13F8 | **Driver code + tables** (checksummed into port 3 at reset) |
| $13F9–$14F8 | Per-track arrays, 16 bytes each (§11) |
| $14F9–$15F8 | Sample pointer table, lo/hi × 128 |
| $15F9–$1EF8 | **Region tables**: 18 × 128 bytes, column-major (§5) |
| $1EF9–$1FD8 | Per-voice arrays, 8 bytes each (§11) |
| $1FD9–$2058 | Pitch-envelope pointer table, lo/hi × 64 |
| $2059–$2178 | Synth wave buffers, 36 bytes (4 BRR blocks) per voice |
| $2179–… | **Upload area**: pitch envelopes, samples, song. Pointer `$14/$15`, mark `$16/$17` |
| top of RAM | Echo buffer (ESA = ~(EDL×8)). Unused in practice (§9) |

Reset clears **everything** from $13F9 to $FFFF. In this SPC the upload area holds samples 1–66, the vibrato envelope at $4E03 and the song at **$373B**. Sample 32 sits at $3725, just in front of it.

Constant tables inside the code block:

| Address | Table |
|---|---|
| $02E6 | CPU command jump table (27 words, $00–$1A) |
| $0875 | Pulse-edge bytes (16) |
| $0A22 | Default pitch envelope (flat) |
| $0C1C | Noise masks `10 11 13 33 37 77 7F FF` |
| $0DB9 | Auto-pan modes, 16 × 4 bytes |
| $0FC0 / $1080 | **Pitch table** hi / lo, 192 entries (one octave in 1/16 semitones, $215B…$4278) |
| $1193 | Silent BRR block |
| $11A5 / $11AD | Voice buffer address hi / lo |
| $11B5 | Bit masks `01 02 04 … 80` |
| $11BD | Global PWM wave (4 blocks) |
| $11E1 | 8 noise BRR blocks (rewritten constantly) |
| $1229 | Synth BRR headers `B0 84 58 5C` |
| $122D–$1318 | 4-bit wave data (squares, saws, triangles, steps) |
| $1319 / $1339 / $1379 / $13B9 | Synth wave tune / source / init routine / per-frame modulator (32 each) |

## 3. Timing

- **Timer 1** ($FB = $50) → one **frame every 10.0 ms**. The main loop calls `FrameUpdate`, `GlobalFX` and the master fade once per frame. It doesn't catch up if several ticks elapsed.
- **Timer 0** ($FA) is the **sequencer**. Tempo event `$84 n` sets $FA = 10000/n, so one tick = 1.25 s / BPM = **1/48 quarter note**. Reset value $53 ≈ 120 BPM. Because $FA is 8 bits, tempos below 40 BPM overflow.
- **Clock.** The 16-bit clock `$2B/$2C` += ticks × multiplier (`$50`, CPU command $16, default 1).
  - The `MUL` result's high byte is discarded, so ticks × multiplier must stay below 256.
  - The clock is **never reset**. A song starts at "clock + initial delay", and event times are compared as signed 16-bit differences, so wraparound is harmless.
- **That Old Army Game:** `$84 168` → $FA = 59 → 7.375 ms/tick. Each track loops after **6912 ticks** (36 bars of 4/4) = **50.98 s**, so the ID666 length of 101 s ≈ 2 loops.

## 4. Song format

```
song+0   word × 16   track data offset (relative to song base; 0 = unused)
track+0  byte        initial delay (ticks)
track+1  4-byte events …
```

| b0 | b1 | b2 | b3 | Meaning |
|---|---|---|---|---|
| $01–$7F | velocity | duration | delta | **Note** (MIDI number, 60 = C4). Velocity 0 = **note off** (releases every voice of this track playing that note). Duration in ticks, 0 = hold until a note-off |
| $00 | *hh* | – | delta | **Wait**: next event time += *hh*×256 + delta |
| $80 | – | – | (delta) | **LoopEnd**: jump to the LoopStart point if one is set, otherwise the track ends. A taken LoopEnd **never reads its own delta**, because the LoopStart's delta is re-applied |
| $82 | – | – | delta | **LoopStart** (one level only, no counter, so the loop is infinite) |
| $83 | vol | – | delta | Track volume (`$14C9`) |
| $84 | BPM | – | delta | Tempo (global timer 0) |
| $85 | prog | – | delta | Program (also loads the program's default polyphony/priority if non-zero) |
| $86 | n | – | delta | Polyphony (`$14D9`, §7) |
| $87 | n | – | delta | Glide / legato (`$14A9`, §7) |
| $88 | n | – | delta | Priority (`$14E9`, voice priority = n×2+1) |
| $89 | pan | – | delta | Track pan (`$14B9`, $40 = centre) |
| $8A | n | – | delta | Pitch-envelope enable (`$1499`, 0 = off, default $7F) |
| $81, $8B–$FF | – | – | delta | Ignored |

All events are processed while (event time − clock) is negative, so several events with delta 0 form a chord. The song uses 1420 notes, 10 program changes and 1 tempo event on 7 tracks. Track 6 ends with a LoopEnd whose delta of 24 is never used.

## 5. Instruments: programs and regions

Instruments are **128 regions** stored column-major: field *k* of region *r* is at `$15F9 + k×$80 + r`. CPU command $03 uploads a record by writing down a column. A **program number is its head region**, and further regions are linked through `next`.

| k | Table | Field |
|---|---|---|
| 0 | $15F9 | Key-on delay in frames (**must be ≥ 1**: 0 never keys on) |
| 1 | $1679 | Fine tune (1/256 semitone) |
| 2 | $16F9 | Transpose (semitones, added to the note) |
| 3 / 4 | $1779 / $17F9 | Key range low / high |
| 5 | $1879 | Sample number. **Bit 7 = synth wave** (§6.3) |
| 6 / 7 | $18F9 / $1979 | Synth parameters (PWM step / limit, noise mask) |
| 8 | $19F9 | Pitch-envelope number (bit 7 = none) |
| 9 / 10 | $1A79 / $1AF9 | **Program defaults**, read only on the head region: polyphony / priority |
| 11 / 12 | $1B79 / $1BF9 | ADSR1 (bit 7 forced) / ADSR2 |
| 13 | $1C79 | Release rate (GAIN $A0 \| rate = exponential decrease) |
| 14 | $1CF9 | Velocity sensitivity (signed) |
| 15 | $1D79 | Pan (bit 7 = auto-pan mode, $FF = use the track pan) |
| 16 | $1DF9 | Volume |
| 17 | $1E79 | Next region (bit 7 = end of chain) |

**Note-on:** every region in the chain whose key range contains the note starts a voice.

- Programs 10/11/12 each use a 5-region **octave split** over samples 1–5: C-1–B3, C4, C5, C6, C7+. Each split has its own transpose (+36…−12), pan and volume.
- Programs 0, 1, 4, 5 and 15 are single-region.
- Program 15 is the only one with a pitch envelope (vibrato).

**Velocity → volume:** v = (vel−64)×2+1; v = hi(v × vsens) + $41; voice volume = hi(v × vol×2).

**Samples:** each entry has a 4-byte header (`fine`, `semitone`, `loop offset` word) followed by BRR. The tune bytes are 0 in this SPC, so tuning lives in the regions. At key-on the voice's own DIR slot is written with start and start+loop.

## 6. Voices

### 6.1 Allocation and polyphony

- **Priority** = track priority × 2 + 1. The free voice, or the busy voice with the **lowest priority ≤ the new one**, is taken. If none qualifies, the note is dropped.
- Busy voices decay by 1 every 4 frames, down to a floor of 1, so older notes are stolen first.
- A voice is freed when its ENVX changes and reaches 0.
- **Polyphony limit:** each new note on a track decrements `$1F71` of the track's older voices. A voice that hits 0 is cut (KOF). This gives *n*-note polyphony per track (0 = 256).

### 6.2 Key-on and release

- **Key-on is delayed** by the region's delay (≥ 1 frame). In that frame the voice is keyed off, its DIR entry and ADSR are written, and KON is collected and written once at the end of the frame.
- **Release** (duration expired or note-off): the voice switches to GAIN $A0|rate (exponential decay) with ADSR off.

### 6.3 Synth waves (sample number ≥ $80)

`$80 | h<<5 | n`: *h* picks the BRR header (amplitude), and *n* (0–31) picks the wave.

| n | Wave |
|---|---|
| 0–13 | Fixed 4-block (64-sample) or 1-block (16-sample) shapes copied from $122D–$1318, with tune offsets +36 and +24 |
| 16–23 | **Random-noise BRR blocks** at $11E1, which the main loop rewrites on every pass (the DSP noise generator is never used) |
| 24 | **PWM**: one square edge moves back and forth every frame (step = param 1, limit = param 2) |
| 25 | 4-block copy of the noise blocks |
| 26 / 27 | **Noisy square**: each frame one byte is replaced by random & mask XOR $88/$77 |
| 28 | Global PWM wave ($11BD, swept by `GlobalFX`) |

None of these are used in this song.

## 7. Pitch and effects (per frame)

- **Pitch** (8.8 semitones) = note + transpose : fine, plus glide offset, pitch envelope and sample tune.
  - The high byte is clamped to 119.
  - The table index is (hi mod 12)×16 + lo/16. The value is interpolated by lo & 15, then shifted right by 9 − hi div 12.
  - Note 108 = $215B, so a 16-sample cycle plays at true pitch.
- **Glide / legato** (track `$14A9` ≠ 0): a new note re-uses a held voice of the same track and region **without key-on**.
  - $01–$7E and $FF: the pitch difference goes into a glide offset that shrinks by value×4/256 semitone per frame (portamento).
  - $7F–$FE: the pitch jumps.
- **Pitch envelope** (region field 8, enabled per track by `$8A`): the table starts `[end][–][loop][–]`, followed by 5-byte segments `value(16) slope(16) frames`. At each segment start the value is loaded, then slope is added every frame. After the last segment it continues from `loop`. This song's envelope 1 is a ±50/256-semitone triangle with a 24-frame period: **vibrato at ≈ 4.2 Hz**.
- **Auto-pan** (region pan bit 7): 4 global LFOs (`$54` slow, `$29` frame counter, `$55` fast, `$53` random walk) × 4 widths. The pan value is folded into a triangle, shifted and offset.

### 7.1 Volume and the pan law

L = R = (track volume × voice volume) >> 7. With stereo on (`$51`), d = pan − $40, and the far side is multiplied by (4×(31−|d|)+2)/128, **signed**:

| Pan | Left | Right |
|---|---|---|
| $40 | full | full |
| $20 | full | 0 (hard left) |
| $00 | full | **−full** (phase-inverted "surround") |
| $60 / $7F | mirror | mirror |

## 8. Global effects

- The master volume fade (command $08) steps 4/speed units per frame toward the target.
- `GlobalFX` sweeps the global PWM wave, decays priorities and runs the per-voice synth modulators.

## 9. Echo

Command $13 sets EDL/ESA, EFB, EVOL and a fixed FIR (`FF 08 17 24 24 17 08 FF`), but **EON is never written** (DSPReset zeroes it). No voice can reach the echo, so echo is effectively absent from the driver. The DSP snapshot agrees: EON = 0, EVOL = 0, EDL = 0.

## 10. CPU ↔ APU protocol

A command is accepted when **port 0 changes** and reads stable twice. Ports 1–3 carry arguments. After the handler returns, the SPC echoes port 0 (ack).

- Bulk transfers (commands $01/$02/$04: words in ports 2/3) and $03 (byte pairs) use the same scheme per packet. The CPU writes a new token to port 0, and the SPC echoes it.
- At boot the SPC writes $33 to ports 0–2 and waits for the CPU to echo it. Port 3 holds the driver checksum.

| Cmd | Args (p1, p2, p3) | Action |
|---|---|---|
| $00 | – | No-op |
| $01 | sample, count (p2/p3 words) | Sample *n* = upload pointer; receive header + BRR |
| $02 | env, count | Pitch envelope *n* (0–63) = pointer; receive |
| $03 | first region, pair count | Upload region record(s) column-wise |
| $04 | –, count | Song base = pointer; receive song |
| $05 | – | Return to the IPL ROM ($FFC0) |
| $06 | – | Mark = upload pointer |
| $07 | flag | ≠0: pointer = mark; 0: pointer = mark = $2179 |
| $08 | target, speed | Master volume fade |
| $09 | – | Start the song (clears pause) |
| $0A | – | Stop all |
| $0B | flag | Pause (sequencer frozen, song voices keyed off every tick) |
| $0C | program, note, velocity | Play a note on the SFX track (`$4F`, default 15) |
| $0D | track | Select SFX track |
| $0E / $0F / $10 / $11 | value | SFX track polyphony / priority / glide / volume |
| $12 | vol | Song volume (all active tracks + default) |
| $13 | EDL, EFB, EVOL | Echo set-up (inaudible, §9) |
| $14 | flag | Stereo on/off |
| $15 | – | DSP reset |
| $16 | n | Clock multiplier |
| $17 | – | Measure levels (ENVX per voice/track into $2F–$46) |
| $18 | n | Return word $2F+2n (ports 2/3) |
| $19 | – | Return the active-track mask |
| $1A | – | Return free memory ($FFFF − pointer) |

## 11. RAM variables

**Zero page:** `$00` last command · `$01–$03` args · `$12/$13` LFSR · `$14/$15` upload pointer · `$16/$17` mark · `$18` song volume · `$19/$1A/$1B/$1C` master volume, target, speed, counter · `$1D` KON bits · `$1E` voice · `$1F` region · `$20–$23` track, note, velocity, duration · `$24` noise index · `$25/$26` event pointer · `$27/$28` song base · `$29/$53/$54/$55` LFOs · `$2B/$2C` clock · `$2D` ticks this pass · `$4F` SFX track · `$50` multiplier · `$51` stereo · `$57–$59` global PWM · `$5A` pause.

**Per track** (+0–15): $13F9/$1409 pointer · $1419/$1429 loop (hi 0 = none) · $1439/$1449 next time · $1459 active · $1489 program · $1499 pitch-env enable · $14A9 glide · $14B9 pan · $14C9 volume · $14D9 polyphony · $14E9 priority.

**Per voice** (+0–7): $1EF9 last ENVX · $1F01 key-on delay · $1F09 region · $1F11 track · $1F19 note · $1F21/$1F29 pitch · $1F31 velocity volume · $1F39 priority · $1F41/$1F49 envelope counter/offset · $1F51/$1F59 envelope value · $1F61/$1F69 slope · $1F71 polyphony counter · $1F79 flags (b0 pitch dirty, b6 volume dirty, b7 released) · $1F81 gate · $1F89 pan · $1F99/$1FA1 glide · $1FA9 sample · $1FB1/$1FB9 sample tune · $1FC1/$1FC9/$1FD1 synth position/step/limit.

## 12. Quirks and bugs

- **No echo** (EON never set), even though command $13 configures everything else.
- A region key-on delay of **0 never keys on**.
- A taken LoopEnd ignores its delta. There's only one loop level per track.
- **Pans beyond ±32 from centre invert the phase of the far channel.** This is probably deliberate (surround), but it collapses in mono.
- The clock add drops the high byte of ticks × multiplier.
- Pitch interpolation for index 191 (B + 15/16) reads $1140, which is unrelated data → wrong pitch step in that last 1/16 semitone.
- The legato "jump" mode (glide $7F–$FE) doesn't mark pitch dirty, so the new pitch waits for a glide or pitch-envelope update.
- **Unloaded samples** point at `DefaultSample` ($119C), whose BRR runs into the tables without an end flag.
- Sending the same command twice requires a different port-0 value in between.
- The tempo byte must be ≥ 40.
- `$1140–$1192` and `$058B–$05AE` (an unreferenced multiply routine) are dead bytes.

## 13. How the findings were checked

Checks were run against the DSP snapshot, taken one tick after song start, with all 8 voices just keyed on:

- **Pitch**: all 8 voices match the formula. Examples:
  - voice 0: note 60 + transpose 29 = 89 → idx $50 → $2C86 >> 2 = **$0B21**
  - voice 4: note 55 + 24 = 79 → $31FA >> 3 = **$063F**
  - voice 1: 95 → $3EF7 >> 2 = **$0FBD**
- **Volume and velocity**: voice 3 (vel 86, vsens 127, vol 100): $1F31 = $43, × track volume 80 → **$29/$29** ✓.
- **Pan law, including phase inversion**:
  - voice 1, pan $7F → **$FC/$08**
  - voice 2, pan $04 → **$26/$F0**
  - Both are exact.
- **Instrument**: voice 4 ADSR $FF/$F1 = region 0. DIR slot 4 = $8BB7/$8FF8 = sample 24.
- **Gate**: voice 4 gate 48 = the duration of track 2's first note.
- **KON**: KON = $FF and every key-on delay is 0, which means FrameUpdate has just run.
- **Snapshot**: PC $0874 is the `RET` of `WritePulseEdge`, called from `GlobalFX` ($0F8B) inside `TimerService` ($02A6), as the stack shows.
- **Song length**: all 7 tracks loop at exactly 6912 ticks. At $FA = 59 that's 50.98 s, and ×2 ≈ the ID666 length of 101 s.
- **Tempo**: the event `$84 168` → 10000/168 = 59 = the timer-0 target in the snapshot.

Not yet verified by ear: the synth waves (unused by this song), auto-pan modes and the glide rate.
