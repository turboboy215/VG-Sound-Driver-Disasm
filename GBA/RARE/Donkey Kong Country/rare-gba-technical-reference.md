# Rare GBA sound driver — Donkey Kong Country 1 / 2 / 3
## Reverse-engineering report and technical reference

*The driver has no name in the ROMs. "Rare GBA driver" is used here. It is the same engine in all
three Donkey Kong Country GBA ports, with small revisions. All three builds were disassembled in
full and reassemble byte-identical. The text describes DKC1 as the reference build; DKC2 and DKC3
are covered as differences from it (§10).*

**Subject files** (`…/GBAAudioLab/RARE/`)

| File | Code | Size | Driver build |
|---|---|---|---|
| `Donkey Kong Country (E) (M5).gba` | `A5NP` | 8 MB | reference (§2–§9) |
| `Donkey Kong Country 2 (E) (M5).gba` | `B2DP` | 8 MB | revision 2 (§10) |
| `Donkey Kong Country 3 (E) (M5).gba` | `BDQP` | 16 MB | revision 3 (§10) |

**Deliverables**

| File | What it is |
|---|---|
| `rare-gba-technical-reference.md` | this document |
| `rare-gba-data-dump.md` | every song, instrument, key-split zone and SFX in all three games, decoded |
| `asm/dkc1_sound.s` | reconstructed assembler source for the whole DKC1 driver (ROM `0x08031BC4`–`0x0803462F`): code, tables and strings, with names and comments |
| `asm/dkc2_sound.s` | the same for DKC2 (`0x080321F4`–`0x08034C83`) |
| `asm/dkc3_sound.s` | the same for DKC3 (`0x080AECB4`–`0x080B1A07`), with DKC3's new code named and commented |
| `asm/build.sh` | reassembles all three; each output is **byte-identical** to its ROM range |
| `tools/rare_gba_midi.py` | reference extractor: any song from the three ROMs to a Standard MIDI File |
| `tools/gen_asm.py` + `dkc1_syms.py` / `dkc2_syms.py` / `dkc3_syms.py` | the generator (capstone) and the per-build symbol, RAM and comment tables that produce the three sources: `gen_asm.py ROM out.s dkcN_syms`. The DKC2/DKC3 tables were carried over from DKC1 by aligning the instruction streams, then extended by hand |
| `midi/` | all 117 songs (39 + 47 + 31) exported with that tool |

**Provenance.** The ROMs carry the driver's own debug strings (`AUDIO ERROR, midi_command table
exceeded`, `… incorrect note mapping for rhythm_set`, `… too many notes on channel 5. increase
polyphony RAM or modify tune (perhaps reduce envelope release times)`, 32 in all; DKC3 adds a
33rd, `could not find startpoint`). Their asserts
were compiled out of these release builds, so nothing references the strings, but they give the
original vocabulary: *tune*, *fx*, *rhythm_set*, *keysplit*, *adsr_acts*, *midi delta time*,
*polyphony RAM*, *audio RAM code*. Nothing in the driver is MP2K/`m4a`: no `SoundMain`, no
`Smsh` header, no `MPlayTable`. It is Rare's own code.

Everything below was derived from disassembly. Where a claim is an inference rather than a direct
read of the code it is marked *(inferred)*. Nothing was checked in an emulator.

---

## 1. Executive summary

The Rare GBA driver is **a MIDI file player with a software sampler**. A song is a set of up to 16
tracks. Each track is a compacted Standard MIDI stream: one byte holds the MIDI channel in its high
nibble and a command in its low nibble. Timing is real MIDI timing: each song has its own division
(384 or 480 ticks per quarter note), tempo events carry microseconds per quarter note, and the
sequencer keeps a 64-bit microsecond clock per track. Conversion back to MIDI is lossless at the
event level (`tools/rare_gba_midi.py`, about 150 lines).

The synthesis side is a **sampler built like a General MIDI module**. Every song shares one
program map (MIDI program → instrument) and one instrument table. An instrument is a single
sample, a **key split** (a keymap selecting different samples by key, transposed) or a
**rhythm set** (a drum kit: one sample per key, each at its own pitch). Each sample carries an
ADSR envelope with 0–99 parameters, fine tuning, a pitch-bend range and vibrato settings. The
player honours note on/off with velocity, program change, pitch bend, CC1 modulation, CC7 volume,
CC126/127 mono/poly mode, and two private controllers, CC102/CC103, for loop start and loop end.

Output is **one DirectSound channel (FIFO A), mono, 8-bit, 13 379 Hz, 224 samples per frame**,
double-buffered. DMA1 is restarted every V-blank. The mixer is hand-written ARM code copied to
IWRAM (4.2 KB). It mixes up to 8 voices per frame with linear interpolation into a 16-bit buffer,
then clips to 8 bits. The voice pool is 96 music voices (16 channels × 6) plus 5 SFX voices.
Voices over the 8-voice budget keep running silently. SFX are always mixed first.

What sets it apart from the other drivers in this project:

1. **The song format is MIDI.** MP2K also comes from MIDI but converts to its own tick-and-wait
   script. Rare keeps MIDI semantics intact: division, µs-per-quarter tempo and 14-bit pitch bend.
2. **The mixer never writes playback positions back.** A separate pass advances every active
   voice, mixed or not, with exact 64-bit arithmetic. Voices outside the budget therefore stay
   in sync.
3. **SFX use the same sample format as music instruments.** The SFX table is just an array of
   instrument pointers, and SFX get their own 5-voice pool addressed by handles.

---

## 2. Build and layout (DKC1)

The driver has two parts, linked together:

* an **ARM block** that `snd_init` copies to IWRAM: mixer, envelope generator, sequencer and
  maths helpers;
* a **Thumb API layer** that runs from ROM: init, frame update, V-blank swap, SFX and music
  control. It calls into IWRAM through `mov r0,pc / adds r0,#7 / mov lr,r0 / ldr r0,=… / bx r0`
  veneers.

Every public Thumb entry saves `r4–r7` and `r8–r12` before doing anything, because the ARM code
clobbers every register. Each returns with `bx r1`, so it is interworking-safe.

| Region | ROM | Run address | Size |
|---|---|---|---|
| IWRAM block size word (`iwram_code_size`) | `08031BC4` | — | 4 |
| **ARM block** (mixer, envelopes, sequencer) | `08031BC8` | IWRAM `03002B40` | `0x1098` (4 248) |
| **Thumb API** + literal pools | `08032C60` | ROM | `0x084C` (2 124) |
| `pitch_table` 128 × u32 | `080334AC` | ROM | 512 |
| `adsr_rate_table` 100 × u8 | `080336AC` | ROM | 100 |
| `lfo_sine_table` 257 × s32 | `08033710` | ROM | 1 028 |
| debug strings (unreferenced) | `08033B14` | ROM | 2 842 |
| end of driver | `08034630` | | **10 860 bytes total** |

`snd_init` checks the block size against `0x13EC` (5 100 bytes, the IWRAM reserved for it). The
check compiles to `ble` to the next instruction because its assert body was compiled out. It is
dead code.

Data the driver reads from outside its own region:

| ROM | Use |
|---|---|
| `0809BD5C` | config: pointer to 8-bit output buffer A (`03002570`) |
| `0809BD64` | config: pointer to output buffer B (`03002730`) — `…BD60` and `…BD68` are unused second pointers |
| `0809BD6C` | config: music voice pool size in bytes, `0xF00` = 96 voices |
| `0809BD70` | config: voices per channel in bytes, `0xF0` = 6 |
| `0809BD74` / `…BD78` | config: SFX pool `0xC8` bytes = 5 voices |
| `0809BD80` | config: 6 voices per channel (used by `init_music_voices`) |
| `08562668` | song table, 39 entries |
| `08562294` | SFX table, 245 entries |

The config block is game data, not part of the driver. Pool sizes are therefore a per-game build
setting; all three games use the same values (§10).

---

## 3. Public API

All entries are Thumb. Addresses for DKC2 and DKC3 were found by aligning instruction streams
against DKC1 and then checked by hand.

| Function | DKC1 | DKC2 | DKC3 | Arguments → result |
|---|---|---|---|---|
| `snd_init` | `08032CAC` | `08033300` | `080AFF48` | — |
| `snd_frame` | `08032D94` | `080333E8` | `080B003A` | call once per frame |
| `snd_vblank` | `08032C84` | `080332D8` | `080AFF10` | call from the V-blank IRQ |
| `snd_request_song` | `08032C60` | `080332B4` | `080AFEEC` | `r0` = song; starts at the next `snd_frame` |
| `snd_get_song` | `08033308` | `0803395C` | `080B05F4` | → current song, −1 when none or finished |
| `snd_music_stop` | `08033120` | `08033774` | `080B03FC` | frees all music voices |
| `snd_music_pause` / `_resume` | `0803318A` / `08033192` | `080337DE` / `080337E6` | `080B0466` / `080B046E` | freezes the sequencer and music voices |
| `snd_set_music_volume` | `0803314C` | `080337A0` | `080B0428` | `r0` = 0–128 (init 128; DKC1 sets 127) |
| `snd_set_sfx_volume` | `08033152` | `080337A6` | `080B042E` | `r0` = 0–128 |
| `snd_get_tempo` / `snd_set_tempo` | `08033158` / `0803315E` | `080337AC` / `080337B2` | `080B0434` / `080B043A` | µs per quarter note |
| `snd_sfx_play` | `080331CE` | `08033822` | `080B04AA` | `r0` = id, `r1` = volume (0 → no-op, returns −1), `r2` = pitch ×65536 → handle or −1 |
| `snd_sfx_play_timed` | `080331D2` | `08033826` | `080B04AE` | as above, plus `r3` = frames until automatic key-off (0 = never) |
| `snd_sfx_release` | `0803319A` | `080337EE` | `080B0476` | `r0` = handle; key-off, so the release runs |
| `snd_sfx_stop` | `080330CE` | `08033722` | `080B03AA` | `r0` = handle; frees the voice at once |
| `snd_sfx_stop_all` | `080330FC` | `08033750` | `080B03D8` | |
| `snd_sfx_is_playing` | `0803302A` | `0803367E` | `080B0306` | `r0` = handle → 1/0 |
| `snd_sfx_set_volume` | `080330A2` | `080336F6` | `080B037E` | `r0` = handle, `r1` = volume |
| `snd_sfx_set_pitch` | `08033076` | `080336CA` | `080B0352` | `r0` = handle, `r1` = pitch ×65536 |
| `snd_set_mix_rate` | `0803328E` | `080338E2` | `080B057A` | `r0` = Hz; above 13379 → −1, otherwise 0 (see §4) |
| `snd_set_max_voices` | `0803330E` | `08033962` | `080B05FA` | voices mixed per frame (init 8) |
| `snd_shutdown` | `08033280` | `080338D4` | `080B055C` | stops DMA1 and the APU |

In DKC1, the game has 628 call sites for `snd_sfx_play`, 54 for `snd_set_music_volume`, 46 for
`snd_request_song`, 19 for `snd_get_song`, 17 for `snd_music_stop` and 16 for `snd_sfx_stop`. The
V-blank handler at `08000364` calls `snd_vblank` through a one-line wrapper (`08020100`), and
`snd_frame` is called through another wrapper (`0802010C`) from two sites. `snd_sfx_play_timed`,
`snd_get_tempo` and `snd_set_tempo` have no callers.

There is no bounds checking on song numbers, SFX ids or instrument indices. The asserts for these
(`tune num > max tunes available`, `invalid fx number`) were compiled out.

---

## 4. Hardware resources and output path

| Resource | Use |
|---|---|
| DirectSound A / `REG_FIFO_A` | the only output, mono |
| **DMA1** | FIFO A feed, special timing, 32-bit, repeat, IRQ bit set |
| **Timer 0** | sample clock |
| DMA2 (DKC1) or DMA1 (DKC2/3) | one-time memory fills and the IWRAM code copy during `snd_init` |
| `REG_SOUNDCNT_H/X`, `REG_SOUNDBIAS` | set once |

The PSG channels (`SOUND1`–`SOUND4`), DirectSound B and Timer 1 are never touched.

`snd_init` sets the following values:

```
SOUNDCNT_X  = 0                         (the first snd_vblank writes 0x80 = master enable)
DMA1CNT_H   = 0, TM0CNT_H = 0
SOUNDCNT_H  = 0, then |= 0x8800         FIFO A and B reset; one 0x80 byte written to each FIFO
SOUNDCNT_H |= 0x030C                    DSA 100 %, DSA left+right, DSA on Timer 0 (DSB vol bit set but DSB off)
SOUNDBIAS_H = (x & 0x3F) | 0x40         amplitude resolution 8-bit / 65 536 Hz PWM
TM0CNT_L    = −1254 (0xFB1A), TM0CNT_H = 0x80     → 16 777 216 / 1254 = 13 378.8 Hz
```

**Double buffering.** `snd_vblank` flips `dma_buffer_flag`. It then stops DMA1 and restarts it on
the buffer that was mixed during the previous frame: SAD = buffer, DAD = `FIFO_A`,
CNT = `0xF6000000`. 224 samples at 13 379 Hz is exactly one 59.73 Hz frame, so the FIFO DMA runs
from V-blank to V-blank and no DMA interrupt is needed. `mix_frame` always writes the other buffer.
The output buffers in DKC1 are `03002570` and `03002730`, 448 bytes apart.

### Mixing rates

`snd_set_mix_rate` has settings for four rates, each giving a whole number of samples per frame:

| Rate | Timer 0 reload | Samples/frame | `mix_pitch_scale` (2³⁸/rate) |
|---|---|---|---|
| 10 512 Hz | −1596 | 176 | `0x018F0064` |
| **13 379 Hz** (used) | −1254 | 224 | `0x01397FC3` |
| 18 157 Hz | −924 | 304 | `0x00E70086` |
| 21 024 Hz | −798 | 352 | `0x00C78032` |

The function first rejects anything above 13 379 Hz with −1 (the compiled-out
`requested playback freq exceeds max freq` assert). The 18 157 and 21 024 Hz rows are therefore
unreachable. The cap matches the 16-bit mix buffer, which holds exactly 224 samples (448 bytes).
A value of 13 379 or below that is neither 10 512 nor 13 379 falls through every comparison and
gets the **21 024 Hz** settings while returning success (§11.3).

---

## 5. Per-frame execution — `snd_frame`

```
snd_frame:
  if seq_pending_song >= 0:                         start song (§8.1)
  clear_mix_buffer
  if !music_paused and seq_current_song >= 0:
      seq_update              (IWRAM)   sequencer, may end the song
      lfo_update                         vibrato phases
      env_update_music        (IWRAM)   one envelope step per music voice
  sfx_timer_update                       auto key-off countdowns
  env_update_sfx              (IWRAM)
  mix_frame                   (IWRAM)   ≤ mix_max_voices voices → s16 → s8 buffer
  if !music_paused: advance_music_voices (IWRAM)
  advance_sfx_voices          (IWRAM)
```

Envelopes, vibrato and pitch are updated once per frame, at 60 Hz, before mixing. Within a frame,
gain and step are constant.

### Timing model

The sequencer keeps one signed 64-bit clock per track (`seq_track_time`). Its unit is
**microseconds × 256**.

* Each frame, `seq_frame_time` is subtracted from every clock. `set_tempo_internal` computes it as
  60 000 000 / 3600 = **16 666.67 µs**. The driver therefore assumes exactly 60 frames/s. The real
  GBA rate is 59.727 Hz, so all music plays **0.46 % slow**. Pitch is unaffected.
* While a track's clock is negative, its events run. A delta-time event adds
  `delta × tempo / division` microseconds, computed in 64-bit with a 64/32 signed divide
  (`sdiv_64_32`). Events continue until the clock becomes non-negative.
* A tempo change affects only deltas read after it. Each delta is converted to microseconds
  when it is read, using the tempo at that moment. A track that is in the middle of a wait when the
  tempo changes finishes that wait at the old tempo. The result is exact only if every track has a
  delta boundary at the tempo-change tick. Only one shipped song changes tempo at all (DKC3 song 0,
  three changes on track 0 at ticks 157 440–161 280), and most of its tracks are mid-wait there, so
  in-game they drift slightly against the conductor.

At song start, `seq_frame_time` is set to 1 and `seq_tempo` to 0. The first frame therefore runs
the tick-0 events, including the first tempo event, which sets the real frame time.

---

## 6. RAM map (DKC1)

All driver state lives in IWRAM, `03001410`–`03004008`: about 11 KB including the 4.2 KB of code,
or a third of IWRAM.

| Address | Name | Notes |
|---|---|---|
| `03001410` | `seq_num_tracks` | |
| `03001414` | `mix_samples_per_frame` | 224 |
| `03001418` | `mix_timer_reload` | |
| `0300141C` | `seq_prog_map_ptr` | song +0x0C |
| `03001420` | `seq_current_song` | −1 = none |
| `03001430` | `seq_loop_ptr[16]` | per track, set by CC102 |
| `03001470` | `chan_mod[16]` | {u32 CC1 value, u32 LFO phase (24-bit)} |
| `030014F0` | `sfx_table_ptr` | |
| `030014F4` | `seq_frame_time` | µs×256 per frame |
| `03001500` | `seq_track_ptr[16]` | |
| `03001540` | `seq_division` | |
| `03001544` | `sfx_master_volume` | |
| `03001548` | `music_paused` | |
| `03001550` | `chan_cc100[16]` | written by CC100, **never read** |
| `03001560` | `chan_volume[16]` | CC7, reset to 127 only by `snd_init` |
| `03001570` | `mix_max_voices` | 8 |
| `03001580` | `chan_bend[16]` | u32, 0x2000 = centre |
| `030015C0` | `mix_pitch_scale` | 2³⁸ / rate |
| `030015C4` | `seq_pending_song` | |
| `030015D0` | `chan_instrument[16]` | pointer |
| `03001610` | `chan_mono[16]` | CC126 → 1, CC127 → 0 |
| `03001620` | `music_voices[96]` | 0x28 each; channel *c* owns voices 6c–6c+5 |
| `03002520` | `music_master_volume` | |
| `03002530` | `sfx_handle[8]` | 5 used |
| `03002550` | `sfx_timer[8]` | 5 used |
| `03002570` / `03002730` | 8-bit output buffers A / B | from the config block |
| `030028F0` | `seq_track_time[16]` | s64 |
| `03002970` | `mix_buffer` | s16 × 224 |
| `03002B30` | `seq_inst_table_ptr` | song +0x10 |
| `03002B40` | **IWRAM code** | to `03003BD8` |
| `03003F2C` | `sfx_handle_counter` | |
| `03003F30` | `sfx_voices[5]` | 0x28 each |
| `03003FF8` | `mix_rate_hz` | |
| `03003FFC` | `seq_tempo` | µs per quarter note |
| `03004000` | `dma_buffer_flag` | |
| `03004004` | `song_table_ptr` | |

### Voice structure (0x28 bytes)

```
+00 u8   state         0x10 free, 0x11 key on, 0x12 released
+01 u8   loop mode     from sample +04: 1/3 one-shot, 2/4 looped
+02 u8   key           MIDI key as played, used for note-off matching
+03 u8   volume        velocity+1 (music) or SFX volume
+04 u8   env phase     0–6, §8.4
+05 u8   pitch key     key used for pitch: the played key, or the sample root for rhythm sets and SFX
+06 s8   channel       0–15, or −1 for SFX voices
+08 u32  step cache    this frame's step, written by the mixer, cleared by the advance pass
+0C ptr  position      current sample address
+10 u32  fraction      23-bit sub-sample position
+14 u32  env level     0 … 0x80000
+18 u32  env increment
+1C u32  sustain level
+20 ptr  sample        sample-instrument actually playing
+24 u32  pitch mult    16.16; 0x10000 for music, caller-supplied for SFX
```

---

## 7. Data formats

### 7.1 Song table and song header

`song_table` is an array of pointers with no count. Each points at a 20-byte header:

```
+00 u32 track count        1–16 (DKC1 uses 5–15)
+04 u32 division           ticks per quarter note: 384 or 480
+08 ptr track pointer array
+0C ptr program map        128 bytes
+10 ptr instrument table   array of instrument pointers
```

In all three games every song points at the same program map and instrument table. The
instrument set is global, like a GM module's.

### 7.2 Track event stream

A track is a byte stream. Each event begins with one byte:

```
bit 7-4  MIDI channel (0–15); ignored for timing, tempo and end events (always 0 in the data)
bit 3-0  command
```

| Cmd | Length | Meaning | MIDI equivalent |
|---|---|---|---|
| `0` | 4 | tempo: 24-bit little-endian µs per quarter note | `FF 51 03` |
| `1` | 2 | delta time, 8-bit ticks | VLQ delta |
| `2` | 3 | delta time, 16-bit LE | |
| `3` | 4 | delta time, 24-bit LE | |
| `4` | 3 | note on: key, velocity *(never used in the data)* | `9n` |
| `5` | 3 | note on: key, velocity (all shipped data) | `9n` |
| `6` | 3 | note off: key, velocity (ignored) | `8n` |
| `7` | 3 | controller: number, value | `Bn` |
| `8` | 2 | program change | `Cn` |
| `9` | 2 | one byte, skipped *(channel-pressure slot; never used)* | `Dn` |
| `A` | 3 | pitch bend: 16-bit LE holding the 14-bit value 0–16383, centre 8192 | `En` |
| `B` | 1 | end of track | `FF 2F` |
| `C` | 1 | no operation *(never used)* | |
| `D`–`F` | — | invalid: the dispatch reads past its 13-entry table into a literal pool | |

Deltas come *between* events, as in SMF, but they are optional: consecutive events with no delta
are simultaneous. There is no running status. The converter's error string `midi delta time of 4
bytes unsupported` shows that deltas are capped at 24 bits.

**Controllers.**

| CC | Effect |
|---|---|
| 1 | mod wheel → vibrato depth (§8.3) |
| 7 | channel volume |
| 100 | stored in `chan_cc100`, never used. DKC1 songs 26, 27 and 29–32 send CC100 = 1 repeatedly on channel 15, which plays no notes. It looks like a leftover from a General MIDI RPN select *(inferred)* |
| **102** | **loop start**: saves this track's position in `seq_loop_ptr[track]` |
| **103** | **loop end**: jumps back to the saved position, unconditionally (infinite loop) |
| 126 / 127 | mono / poly mode. Mono channels always reuse voice slot 0 |
| other | ignored (DKC1 data also contains CC2) |

Loops are per track: each track carries its own CC102/CC103 pair, and the jump back is
unconditional, so a looping track never reaches its END. In DKC1 and DKC2 all of a song's pairs
sit at the same two ticks. (Three DKC2 tracks have a CC102 with no CC103; they simply run on to
END.) DKC3 staggers them: in 21 of its 31 songs the loop points differ between tracks. Some songs
loop tracks over **different lengths**, so the layers phase against each other. DKC3 song 10, for
example, loops its four tracks over 9 600, 9 600, 28 800 and 55 680 ticks. A converter that wants
one global loop point has to unroll each track separately. Events after a CC103 are unreachable;
DKC3 song 12 track 1 has 37 000 ticks of them.

A track that reaches END (cmd B) stays parked there. `seq_update` re-executes END every frame and
counts it. When all tracks are parked, `seq_current_song` becomes −1 and the song is over. Several
conductor tracks hold nothing but the tempo and END at tick 0.

### 7.3 Program map and instrument table

`program map[prog]` gives an index into the instrument table. 255 means unmapped; nothing checks
for it, so an unmapped program change loads a pointer from past the end of the table.

### 7.4 Instrument / sample structure (0x44 bytes)

One structure serves as a plain instrument, a key-split or rhythm-set header, a sub-instrument
(zone) and an SFX entry.

```
+00 u32 type        0x20 sample · 0x21 sample (same code path, unused) · 0x22 rhythm set · 0x23 key split
+04 u32 loop mode   1 one-shot, 2 looped (music) · 3 one-shot, 4 looped (SFX) · −1 in split headers
+08 u32 sample rate Hz at the root key (11025, 13379, 8000, 12000, 16000, …)
+0C u32 root key    MIDI key at which the sample plays at +08 Hz
+10 ptr start       first PCM byte
+14 u32 loop length bytes
+18 ptr end         last PCM byte (inclusive)
+1C ptr keymap      split/rhythm only: 128 bytes, key → zone index (255 = silent)
+20 ptr zone table  split/rhythm only: array of sub-instrument pointers
+24 u32 attack      0–99
+28 u32 decay       0–99
+2C u32 sustain     0–99
+30 u32 release     0–99
+34 s32 fine tune   cents
+38 u32 bend range  semitones
+3C u32 LFO speed   phase step per frame, 24-bit phase (0x111111 = 4 Hz)
+40 u32 mod depth   vibrato depth in cents at mod wheel 127
```

For a key split or rhythm set, the **header** supplies bend range, LFO speed and mod depth. The
**zone** supplies the sample, root, rate, fine tune, loop mode and ADSR.

**PCM** is 8-bit signed mono. Samples are packed back to back with no headers or alignment: the
next sample starts at `end + 1`. A looped sample loops over `[end − loop length, end)`. The byte at
`end` is read only as the interpolation partner of the last sample, so a seamless loop needs it to
equal the loop-start byte. For export to SF2/WAV:

```
length     = end − start + 1
loop_start = end − start − loop_length
loop_end   = end − start          (exclusive)
```

### 7.5 SFX table

`sfx_table[id]` points at a 0x44-byte structure of type 0x20 with loop mode 3 or 4. SFX play at
their own root key and rate, so pitch comes only from the caller's multiplier.

---

## 8. The engine in detail

### 8.1 Starting a song

`snd_request_song` only latches the number. At the next `snd_frame` the driver:

1. reads the song header;
2. copies the track pointers (DKC1 uses DMA2, `count` words; DKC2/3 always copy 16 words);
3. zeroes the 16 track clocks;
4. sets `seq_frame_time = 1` and `seq_tempo = 0`;
5. frees all 96 music voices;
6. centres pitch bends and clears modulation.

Channel volumes, mono flags and channel instruments are **not** reset. In every shipped song each
channel gets a program change before its first note.

### 8.2 Notes and voice allocation

**Note on** (`ev_note_on`):

1. Look up the channel's instrument.
2. Find a slot among the channel's own 6 voices: first a free one (0x10), then a released one
   (0x12). If none is available the note is dropped. That is the `too many notes on channel N`
   condition, whose assert was compiled out. A mono-mode channel skips the search and takes slot 0.
3. Resolve the sample by type:
   * `0x20`/`0x21`: the instrument itself, pitch key = played key.
   * `0x22` rhythm set: `zone = zones[keymap[key]]`, pitch key = **zone root** (the drum plays at
     its natural pitch).
   * `0x23` key split: `zone = zones[keymap[key]]`, pitch key = played key.
4. `voice_start` sets volume = velocity + 1 and pitch multiplier = 1.0, records the key, resets the
   envelope to phase 0 and keys on.

**Note off** releases the first key-on voice in the channel's six whose stored key matches. Voices
never migrate between channels, so polyphony per channel is a hard 6.

### 8.3 Pitch — `calc_pitch`

The driver computes pitch once per voice per frame, either in the mixer or, for unmixed voices, in
the advance pass. It works in **32.32 fixed-point semitones**:

```
fine   = sample.fine_cents   × (2^32 / 100)
bend   = (chan_bend − 0x2000) × header.bend_range × 2^19          (±range at full deflection)
vib    = sine[phase] × (CC1 + 1) × header.mod_depth                (sine peak = 2^32 / 12800)
total  = fine + bend + vib
semi   = (voice.pitch_key − sample.root) + hi32(total)
ratio  = lerp(pitch_table[64 + semi], pitch_table[65 + semi], lo32(total))    2^(semi/12) in 9.23
step   = ratio × sample.rate × mix_pitch_scale >> 38                           9.23 fixed
```

So the step is `2^((key − root + cents/100 + bend + vibrato) / 12) × rate / 13379`. The mixer
multiplies it by the voice's 16.16 pitch multiplier, which is 1.0 for music and the caller's value
for SFX. `pitch_table` covers −64…+63 semitones around the root with no clamp. The
`pitch frequency too low/high` asserts were compiled out.

**Vibrato.** `lfo_update` advances `chan_mod[ch].phase` by the header's LFO speed each frame, but
only while the channel's CC1 is non-zero. The phase is 24-bit. The sine table has 256 steps plus a
guard entry and is linearly interpolated on the low 16 bits.

### 8.4 Envelope — `env_step`

The envelope is linear in amplitude. Its level runs 0…0x80000 (2¹⁹) and it steps once per frame.
`adsr_rate_table` maps a 0–99 rate to frames: 0 → 254 frames (4.25 s), 50 → 24, 99 → 0.

| Phase | Action |
|---|---|
| 0 attack init | `t = (99 − A) × 32 / 99`. If `t = 0`, jump straight to decay at full level; otherwise ramp over `t + 1` frames (A = 0 → 33 frames, 0.55 s) |
| 1 attack | add the increment; at 0x80000 go to 2. A key-off here goes straight to 5 |
| 2 decay init | `sustain = S × 128 / 99` (8.8 fixed); frames = `adsr_rate_table[D]`. 0 frames goes straight to sustain |
| 3 decay | ramp down to sustain. **If sustain < 0x1000, the voice is freed when decay ends.** This is how percussive instruments (S = 0) end without a note-off |
| 4 sustain | hold until key-off |
| 5 release init | frames = `adsr_rate_table[R]`; 0 frames (R = 99) cuts at once |
| 6 release | ramp down to 0, then free |

### 8.5 Mixer — `mix_frame` and `mix_voice`

Voices are visited in a fixed priority order:

1. SFX key-on
2. SFX released
3. music key-on (skipped while paused)
4. music released

Each pool is scanned from its first voice up. After `mix_max_voices` voices (8) the scan stops.
Remaining voices are not heard this frame but still advance.

Per voice:

```
gain   = (channel ≥ 0) ? music_master × (CC7 + 1) >> 7 : sfx_master
gain   = gain × volume >> 7                 volume = velocity+1, or SFX volume
gain   = gain × env_level >> 19
sample = s[i] + ((s[i+1] − s[i]) × frac >> 23)                   linear interpolation
mix[n] (+)= sample × gain >> 7
```

The first voice of the frame stores into the buffer and later voices add. At unity
(master 128, CC7 127, velocity 127, envelope full) a voice reaches the mix at its original
amplitude. If no voice was mixed, the buffer is zeroed (again — `snd_frame` already cleared it).
The 16-bit sum is then **hard-clipped to −128…127** and written to the idle output buffer.
There is no headroom scaling: eight loud voices clip.

At the end of a sample, one-shots (modes 1/3) are freed in the mixer and mixing of that voice stops.
Looped samples (2/4) subtract the loop length and carry on.

### 8.6 Advance pass — `voice_advance`

The mixer reads positions but never writes them back. After mixing, `advance_music_voices` and
`advance_sfx_voices` walk every key-on and released voice. For each, they use the cached step from
`+08`, or call `calc_pitch` if the voice was not mixed. They advance the position by
`step × pitch_mult × 224` in a single 64-bit multiply-accumulate on `(address << 23 | fraction)`,
apply loop or end, and store it. Voices over the mixing budget therefore stay sample-accurate, and
a voice that gets a mixing slot back resumes where it would have been.

### 8.7 Sound effects

* There are 5 voices and no priorities. `snd_sfx_play` takes a free voice, otherwise a released
  one, otherwise it fails and returns −1. Playing SFX are never stolen. Music never takes SFX
  voices, and SFX never take music voices.
* Every start draws a new **handle** from a 32-bit counter that skips −1. All per-SFX calls look
  the handle up, so a stale handle simply does nothing.
* `snd_sfx_play_timed`'s countdown (`sfx_timer`) is decremented each frame while the voice is key-on.
  At zero the voice is released.
* SFX gain is `sfx_master × volume`; there is no channel volume or velocity. Pitch is the root rate
  × the caller's 16.16 multiplier, which can be changed live with `snd_sfx_set_pitch`.

---

## 9. Content inventory

| | DKC1 | DKC2 | DKC3 |
|---|---|---|---|
| Songs | 39 | 47 | 31 |
| Division | 384 / 480 | 480 | 480 |
| Programs mapped | 56 | 102 | 117 |
| Key splits / rhythm sets | 11 / 2 | 2 / 1 | 33 / 9 |
| Distinct music samples | 135 (602 KB) | 124 (523 KB) | 1 190 (6.1 MB) |
| SFX ids | 245 | 320 | 203 |
| Distinct SFX samples | 232 (1.64 MB) | 283 (1.82 MB) | 198 (1.71 MB) |
| Note events | 39 722 | 45 408 | 45 261 |
| Pitch-bend events | 6 633 | 8 031 | 28 172 |
| Controllers used | 1 2 7 100 102 103 | 0 1 7 102 103 | 1 7 20–24 102 103 104 |

Every event in all 117 songs decodes with the table in §7.2: there are no invalid commands and
every track ends in END. Initial tempos are round BPM values
(75, 100, 130, 165 …), which supports the microseconds-per-quarter reading of command 0. Music
samples are almost all 11 025 Hz in DKC1/2 and 13 379 Hz (the mixing rate) in DKC3. Full listings
are in `rare-gba-data-dump.md`.

---

## 10. Differences between the three builds

### Layout

| | DKC1 | DKC2 | DKC3 |
|---|---|---|---|
| ARM block in ROM | `08031BC8` | `080321F8` | `080AECB8` |
| ARM block size | `0x1098` | `0x10BC` | `0x1234` |
| IWRAM address | `03002B40` | `03002190` | `03002A20` |
| Thumb API | `08032C60`–`080334AC` | `080332B4`–`08033B00` | `080AFEEC`–`080B085C` |
| Pitch / ADSR / sine tables | `080334AC` | `08033B00` | `080B085C` |
| Debug strings | `08033B14` | `08034168` | `080B0EC4` |
| Config block | `0809BD5C` | `080D3BD8` | `080E4A70` |
| Song / SFX table | `08562668` / `08562294` | `0854B5B0` / `0854B0B0` | `0871F970` / `0871F644` |
| Pending / current song | `030015C4` / `03001420` | `03000DC4` / `03000C20` | `03001464` / `030012A0` |
| Music / SFX voices | `03001620` / `03003F30` | `03000E20` / `03003580` | `030014C0` / `03003C60` |
| Mix buffer | `03002970` | `03001FC0` | `03002850` |

The pool sizes (96 + 5 voices), the 13 379 Hz rate, the 8-voice budget, every table and all error
strings are identical in the three games.

### DKC2 (revision 2)

* **Faster s16 → s8 conversion:** two samples per iteration with one word load and one halfword
  store, clipped by comparing against `0x800000` with shifted operands. The results match DKC1.
* `snd_init` does its fills and the IWRAM copy with DMA1 instead of DMA2. Starting a song copies
  the 16 track pointers with `ldm`/`stm` instead of a DMA.
* Everything else, including the §11.1 bug, is unchanged.

### DKC3 (revision 3)

* **Per-channel envelope override, CC20–CC23.** A new array of 4 bytes per channel
  (`030023F0`) holds attack, decay, sustain and release overrides. Values below 0x80 replace the
  instrument's: **CC20/CC21/CC23 give the attack/decay/release time directly in frames**,
  bypassing the 0–99 curves, and **CC22 gives the sustain level in 1/128 steps**. A program change,
  and every song start, resets all four to 0xFF ("use the instrument"). SFX voices are not affected.
* **Start markers, CC104.** When the game writes a marker number to `030023C0` before starting a
  song (the game does this at `080ACC6E`), song start runs a new routine (`080B07D4`). For each
  track except the conductor, it skips forward over events until it finds `CC104 = marker`,
  recording any CC102 loop start it passes. The song then begins mid-way with loops intact. The
  skip uses an event-length table at `080B0834`. The sequencer itself treats CC104 as a no-op.
  DKC3 data contains 261 such markers.
* **Per-channel gain.** A new byte per channel at `03001400` (initialised to 0x80) multiplies
  the channel's gain in `mix_voice`. A channel at 0 is skipped entirely and **no longer uses up the
  8-voice budget**: the budget decrement moved from `mix_frame_voice` into `mix_voice`, after the
  zero test. Game code writes this array directly. The routine at `0808697C` moves two groups of
  MIDI channels in opposite directions, by 16 per call or by 128 (instantly) depending on a game
  flag. This looks like a dynamic-music layer switch *(inferred from that routine)*.
* **§11.1 bug fixed** (`strb r3,[r0]`).
* **A performance regression.** The ARM block grew past the reach of the `sub pc, pc, #imm`
  returns that DKC1/2 use in the sequencer. Five handlers (program change, skip-1, pitch bend, end
  of track, no-op) were changed to `ldr pc, =label`. The literal holds the label's **ROM** address
  (`080AF520` / `080AF554`), not its IWRAM copy. After any of these events the rest of that
  frame's sequencing runs from the cartridge copy of the ARM code: same instructions, but ARM
  fetches from ROM. Behaviour is correct; it only costs CPU time, especially on pitch-bend-heavy
  DKC3 songs (28 172 bends). Execution returns to IWRAM only through the `bx lr` back to Thumb.
* `snd_vblank` and `snd_shutdown` re-arm DMA1 with a 4-word transfer (`0x84400004`) before setting
  the real FIFO configuration. This looks like a fix for a FIFO start-up glitch *(inferred)*.
* `snd_init`'s dead space check compares against `0x1234` (the exact block size) instead of
  `0x13EC`, and its `beq` now skips a single `0xEFFF` halfword: the trap left behind by the
  compiled-out assert.
* A 33rd debug string, `AUDIO ERROR, could not find startpoint`, belongs to the start-marker
  search. Its check, like the others, was compiled out: an END before the marker simply returns.
* New Thumb helpers: `reset_adsr_override` (`080B06A0`), `reset_channel_gain` (`080B06FE`),
  `seek_start_marker` (`080B07D4`) and its `event_length_table` (`080B0834`). New RAM:
  `seq_start_marker` `030023C0`, `chan_adsr_override` `030023F0`, `chan_gain` `03001400`. Most
  other variables moved; `asm/dkc3_sound.s` lists the full DKC3 RAM map.

---

## 11. Bugs, dead code and anomalies

**1. One-shot music voices freed through the wrong register (DKC1, DKC2).** In `voice_advance`,
loop mode 1 ends a voice with `strb r3,[r8]` where every other path uses `[r0]`
(DKC1 `08031E70`). This path runs only for voices that reach their end in the advance pass, i.e.
voices **outside the mixing budget** (mixed voices are freed by the mixer first). At that point
`r8` holds the low word of the last `calc_pitch` fine-tune product, or a mixer counter. Two things
follow:

* the voice is not freed. It stays key-on past its end and keeps a channel slot until note-off
  and release;
* one byte of 0x10 is written to an unrelated address.

With the shipped data the stray address is always in BIOS or unmapped space: every mode-1 fine
tune is 0 in DKC1, and −50/−25/0/20/50 in DKC2. A fine tune of ≡1 mod 100 cents would aim it into
EWRAM (`0x028F5C29` → `02035C29`). Mode 3 (SFX) is correct, which points to a copy-paste slip.
DKC3 fixed it.

**2. Envelopes freeze when a song ends.** `env_update_music` and `seq_update` are gated on
`seq_current_song ≥ 0`, but `mix_frame` and `advance_music_voices` are not. When a non-looping
song reaches END, any music voice that is still sounding is frozen at its current envelope
level. A looped sample keeps sounding until the next `snd_request_song` or `snd_music_stop`.
Shipped jingles leave tails of 0–1 s between the last note-off and END, so a release longer than
that hangs *(behaviour read from the code; not observed in an emulator)*.

**3. Unsupported mixing rates select the 21 024 Hz settings.** `snd_set_mix_rate` caps the rate
at 13 379 Hz, then compares it against 10 512, 13 379, 18 157 and 21 024. Each comparison loads
that rate's parameters first, and the last `beq` jumps to the very next instruction. Any other
value, for example 8 000 or 11 025, is stored as the rate, but Timer 0, the pitch scale and the
frame length are set for 21 024 Hz (352 samples), and the function returns 0. The output then
plays at the wrong rate. Worse, `clear_mix_buffer` and `mix_voice` write 704 bytes into the
448-byte `mix_buffer`, corrupting `seq_inst_table_ptr` and the start of the IWRAM code directly
above it. Only `snd_init` calls the function, with 13 379, so the bug is latent in all three
games.

**4. The tempo base assumes 60 Hz.** `seq_frame_time` = 60 000 000 / 3600 µs is recomputed on
every tempo event but is constant. Music runs 0.46 % slow on hardware (§5).

**5. No validation anywhere.** Unmapped programs (255), a note before any program change, more
than 16 tracks, command nibbles 13–15, pitch beyond ±64 semitones and keys outside a keymap all
read past their tables. These are exactly the cases the 32 compiled-out asserts covered.

**6. Dead state.** `chan_cc100` is written and never read. The config block's second pointer of
each buffer pair (`0809BD60`/`…68`) is unused, perhaps reserved for a stereo DirectSound B path
*(inferred)*. Command 4 (a second note on) and command C (no-op) never occur in the data. The
`0x21` instrument type is handled but unused.

**7. A one-entry over-read in `pitch_table`.** Interpolation reads `pitch_table[65 + semi]`, so a
pitch 63 semitones above the root reads the first word of `adsr_rate_table` as its upper
neighbour. This is unreachable with real data.

**8. Redundant buffer clear.** `snd_frame` always clears the mix buffer, and `mix_frame` clears it
again when nothing was mixed. The first voice of a frame stores instead of adding anyway, so the
clear only matters for one-shots that end mid-frame.

---

## 12. Notes for GBA2MID and other tooling

**Detection.** Search for the string `AUDIO ERROR, midi_command table exceeded` (present in all
three builds) or for the IWRAM-copy literal triple `ARM-block-ROM, IWRAM-dest, ARM-block-ROM − 4`
next to `0x04000089`. The song and SFX table addresses are the two ROM pointers in `snd_init`'s
literal pool just before the `0x3443` (13 379) literal.

**Songs → MIDI** is a direct translation (`tools/rare_gba_midi.py`):

| Rare | SMF |
|---|---|
| header division | `MThd` division |
| track | `MTrk`, one per track, format 1 |
| cmd 0 tempo | `FF 51 03` |
| cmd 1/2/3 delta | accumulate into the next VLQ delta |
| cmd 4/5 note on | `9n kk vv` |
| cmd 6 note off | `8n kk vv` |
| cmd 7 CC | `Bn cc vv`. Also emit markers for 102 (`loopStart`), 103 (`loopEnd`) and 104 (`startMarker n`) so a player can loop |
| cmd 8 program | `Cn pp`. The program is the game's own, not GM: map it through §7.3 for a SoundFont |
| cmd A bend | `En lsb msb` with `lsb = v & 0x7F`, `msb = v >> 7` |
| cmd B | `FF 2F 00` |

All 117 exported files load cleanly in `mido`.

**Instruments → SoundFont.** Each music sample-instrument maps onto one SF2 sample plus zone. Use
the loop formula in §7.4, with root key = `+0C`, sample rate = `+08` and fine tune = `+34` cents.
The envelope converts as:

* attack ≈ `((99 − A) × 32 / 99 + 1)` frames;
* decay ≈ `adsr_rate_table[D]` frames to a sustain of `S/99`;
* release ≈ `adsr_rate_table[R]` frames;
* all ramps are linear in amplitude, at 59.73 frames/s.

Key splits become multi-zone presets. Rhythm sets become drum presets whose zones each play at
their own root.

**Rendering faithfully** needs:

* 13 379 Hz, mono;
* linear interpolation;
* gain arithmetic exactly as in §8.5, including the s8 hard clip;
* the 8-voice budget with SFX-first priority;
* envelopes, pitch and vibrato stepped once per 60 Hz frame;
* the 0.46 % tempo error.

---

## Appendix — module map of the DKC1 driver

ARM block (ROM address / IWRAM address):

```
08031BC8 / 03002B40  voice_start
08031C0C / 03002B84  mix_frame            08031D30  mix_frame_voice
08031D64 / 03002CDC  advance_sfx_voices   08031D7C / 03002CF4 advance_music_voices
08031DB4 / 03002D2C  voice_advance
08031E84 / 03002DFC  env_update_sfx       08031E9C / 03002E14 env_update_music
08031ED4             env_step  (+ env_jump_table 08031EE8, phases 08031F04–08032094)
080320A4             ev_tempo             080320CC / 03003044 set_tempo_internal
0803210C 08032168 080321CC  ev_delta8 / 16 / 24
08032248             ev_note_on
08032334 / 030032AC  seq_update           08032404 seq_cmd_table (13 entries) + literal pool
0803250C ev_note_off  08032564 ev_controller  08032618 ev_program  08032648 ev_skip1
08032650 ev_pitch_bend  0803266C ev_end_track  08032680 ev_nop
08032684             udiv_32_16           0803271C sdiv_64_32
08032904             mix_voice            08032ABC calc_pitch
```

Thumb part: see §3 for the public entries. Internal helpers:

```
08032F50 lfo_update             08032F82 sfx_timer_update     08032FAC sfx_start_voice
0803304E sfx_find_handle        08033240 sfx_play_common      08033314 wait_vcount_160
08033324 reset_pitch_bend       08033334 reset_modulation     08033342 clear_mix_buffer
080333B4 init_music_voices      080333DC init_sfx_voices      080333F4 reset_channel_volume
08033402 reset_mono_flags
```
