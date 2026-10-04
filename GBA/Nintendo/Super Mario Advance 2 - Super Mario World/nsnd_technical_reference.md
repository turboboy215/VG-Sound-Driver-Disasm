# Nintendo "SMA" sound driver (Super Mario Advance 2–4, A Link to the Past GBA)
## Reverse-engineering report and technical reference

**Subject files** (`…/GBAAudioLab/Nint3/`)

| File | Game code | Size | Driver in it |
|---|---|---|---|
| `Super Mario Advance 2 - Super Mario World (E) (M4).gba` | `AA2P` | 4 MiB | main program + Mario Bros. multiboot image |
| `Super Mario Advance 3 - Yoshi's Island (E) (M5).gba` | `A3AP` | 8 MiB | main program + Mario Bros. multiboot image |
| `Super Mario Advance 4 - Super Mario Bros. 3 (E) (M5) (V1.0).bin` | `AX4P` | 8 MiB (see §1.1) | main program + Mario Bros. multiboot image |
| `Legend of Zelda, The - A Link To The Past with Four Swords (E) (M5).gba` | `AZLP` | 8 MiB | ALttP program only (Four Swords uses Nintendo's MP2000 / `m4a` driver) |

**Provenance.** The ROMs contain no symbols, file names or credit strings for this driver. Every
function, variable, structure and table name below was assigned during this analysis. All four
games are Nintendo EAD/R&D2 SNES and NES remakes, and the driver is clearly an in-house Nintendo
library shared between them *(inferred: identical code and data layout in four titles, with no
third-party markers)*. It is **not** MP2000 (`m4a`): no `Smsh` player headers, no MIDI-derived
data. Nor is it a port of the SNES N-SPC: the sequence format, instrument model and mixer are all
different.

Everything below comes from disassembly. The code of **seven** builds of the driver was
reassembled from generated sources and is **byte-identical** to the ROMs, and so is the complete
sound data of all four games (§15). A Python model written from this analysis was run side by
side with the ROM's own driver in an emulator and produces **identical mixed samples and PSG
register writes, frame for frame**, for every song and every usable sound effect (§15). Where
something is an inference rather than a direct reading of the code it is marked *(inferred)*.

---

## 1. Executive summary

The driver is a **byte-code sequencer driving a 7-voice software mixer plus the four Game Boy
channels**.

* **Output.** 10 512 Hz, 8-bit **stereo**: FIFO A = left, FIFO B = right, both on timer 0.
  176 samples per channel per frame, double-buffered and restarted by DMA every V-blank (no
  per-sample interrupt). Mixing is **nearest-neighbour** (no interpolation) into 16-bit
  accumulators, then saturated to 8 bits.
* **Echo.** An 18-frame (≈301 ms) feedback delay: voices of tracks with echo on are mixed into a
  "wet" bus that starts each frame with the output of 18 frames ago; the wet bus is added to the
  dry output and fed back, scaled by 2^-shift. Echo "strength" is that shift, moved one step per
  frame towards a target set by the game.
* **Sequences.** Each song is up to 10 tracks of a compact byte code: notes 0x00–0xBF (0x60+ with
  explicit length and velocity), commands 0xC0–0xFF (rest, program, bank, pan, volume, tempo,
  vibrato, portamento, tie, echo, jump, call, spawn-track, end). Timing: 24 ticks per quarter
  note; the tempo command value **is** the BPM (150 per frame = one tick per frame at 60 Hz).
* **Players.** 20 players (music plays on player 19 in SMA, 18 in ALttP), 24 tracks shared by all
  players. Sound effects are single-track sequences started on any player.
* **Instruments.** 8-byte records in "instrument banks": sampled instruments, the four PSG
  channels (square with duty sequences, sweep, wave with a 16-byte wave, noise), **drum kits**
  (key → instrument + fixed pan), **sample kits** (key → sample number) and **key splits**.
  Envelopes are tables of linear segments `{frames, level}`; PSG envelopes are *emulated with the
  hardware envelope* by reprogramming NRx2 at each segment start.
* **Samples.** `{length, rate, loopStart, loopEnd}` + signed 8-bit PCM, any source rate
  (10 512, 32 000, 44 100, 48 000 Hz …); the step is `rate × pitch / 10 512`.
* **Game interface.** A 46-entry **command queue**: the game calls `sndPlaySong`, `sndPlaySfx`,
  `sndFadeOut`, `sndPause`, `sndSetEcho` …, then `sndCommit()`; the driver applies the commands at
  the start of its next frame. Two hooks let the game intercept notes or a custom command.
* **Revisions.** Six distinct builds exist across the four ROMs (§2): the SMA2 generation (circular
  sentinel lists, 1-byte tempo, always-on echo), its echo-less multiboot twin, and the rewritten
  SMA3 generation used by SMA3, ALttP and SMA4 with small differences.

### 1.1 ROM sizes and scope

The European releases of SMA3, SMA4 and ALttP are 8 MiB: the other regions' cartridges are 4 MiB,
but Europe needed the extra space for five languages. SMA2 (E) is 4 MiB. *(As reported for these releases; consistent with
the files.)* The first SMA4 file supplied was a 4 MiB dump, cut off exactly at `0x08400000`, in the
middle of the PCM of sample bank 2, and without the song table at **`0x0846E0B8`**. It has been
replaced by a full 8 MiB dump whose first 4 MiB are byte-identical to the old file. Everything in
this report, and the whole rebuild and verification, uses the full dump.

Two related Nintendo titles are **not** covered: Super Mario Advance (SMB2) and The Minish Cap use
Nintendo's standard MP2000 (`m4a`) driver, not this one.

---

## 2. Builds and where they are

Seven copies of the driver exist in the four ROMs. The Mario Bros. classic mode of each Super Mario
Advance game sends a **multiboot image** to other GBAs; that image contains its own, older copy of
the driver, stored uncompressed in the ROM and linked at `0x02000000` (EWRAM).

| Build | Tag | Thumb code | ARM loops | Tables | Notes |
|---|---|---|---|---|---|
| SMA2 main | **A** | `0809C5A0`–`0809E8D4` | `0809E8D4`–`0809EBB4` | `081B43FC` | oldest main-program build |
| SMA2 multiboot (ROM `0xAD9C8`) | **A0** | `0201C0D0`–`0201E2D8` | `0201E2D8`–`0201E5B8` | `020225C4` | A without echo |
| SMA3 multiboot (ROM `0x13F8CC`) | **A0** | `0201C0F0`–`0201E2F8` | –`0201E5D8` | `020225E4` | identical code to the SMA2 multiboot |
| SMA3 main | **B** | `0812FA0C`–`08131F84` | –`0813223C` | `083A7D7C` | rewrite |
| ALttP | **Z** | `0812B714`–`0812DCA0` | –`0812DF58` | `081F9AE8` | B + two changes |
| SMA4 multiboot (ROM `0xF9E10`) | **B0** | `0201BF78`–`0201E384` | –`0201E63C` | `0202264C` | B without echo |
| SMA4 main | **C** | `080E8204`–`080EA7C8` | –`080EAA80` | `08308988` | newest |

The pseudo-C in this report and in the sources describes **build C (SMA4)**; every other build is
documented as differences from it (§14).

| Change | A0 | A | B | Z | B0 | C |
|---|---|---|---|---|---|---|
| Voice lists | circular + sentinels | same | NULL-terminated | same | same | same |
| Echo | none | always on (shift 31 = silent) | on/off at shift 16 | same | none | same |
| Tempo command E4 | 1 byte | 1 byte | varlen | varlen | varlen | varlen |
| Song volume EA | – | – | yes | yes | yes | yes |
| Commands 0x103 (bend), 0x304 (voices) | – | – | yes | yes | yes | yes |
| Pitch-bend formula | correct | correct | **changed** (§8.4) | same | same | same |
| Mixer precision | gain>>8 per sample | same | full 16-bit, >>7 at the end | same | same | same |
| DMA buffer cleared at init | no | no | no | yes | no | yes |
| Sample volume | ×1 | ×1 | ×1 | **×¾** | ×1 | ×1 |
| Pause | releases notes | same | same | same | same | **freezes voices** |

The Thumb code is **GCC** output *(inferred: `adds rX, rY, #0` moves, `push {…}; pop {r0}; bx r0`
epilogues, `_call_via_rX` indirect calls, libgcc `__divsi3`/`__udivsi3`, `mov pc, r0` switch
tables)*. The three ARM loops are hand-written and copied to IWRAM by `sndInit`.

---

## 3. Public API and game integration

| Function (C) | Command | Effect |
|---|---|---|
| `sndInit(const SndConfig *cfg)` | – | once at boot |
| `sndVSync()` | – | first thing in the V-blank handler: restarts the DMA |
| `sndMain()` | – | once per frame after `sndVSync` |
| `sndPlaySong(pl, song)` | 0x000 | start a song on player `pl` |
| `sndPlaySfx(pl, set, idx)` | 0x001 | start sound `idx` of effect set `set` |
| `sndFadeOut(pl, frames)` | 0x002 | fade to silence, then stop |
| `sndPause(pl, on)` | 0x003 | pause / resume |
| `sndSetTempo(pl, ofs)` | 0x004 | tempo offset added to the song tempo |
| `sndSetVolume2(pl, v)` | 0x005 | second player volume (0x80 default) |
| `sndSetHookFlags(pl, v)` | 0x006 | bit 0: send this player's notes to the note hook |
| `sndMuteTracks(pl, mask, on)` | 0x100 | mute tracks |
| `sndSetTrackPan(pl, mask, pan)` | 0x101 | |
| `sndSetTrackExpr(pl, mask, v)` | 0x102 | expression (0x80 default) |
| `sndSetTrackBend(pl, mask, range, bend)` | 0x103 | not in A/A0 |
| `sndFadeOutMask(mask, frames)` / `sndPauseMask(mask, on)` | 0x200 / 0x201 | several players |
| `sndSetEcho(shift)` | 0x300 | echo feedback 2^-shift; 16 (B/C) or ≥ 31 (A) = off |
| `sndCallback(fn, arg)` | 0x301 | call `fn(arg)` inside `sndMain` |
| `sndSetHookCA(fn)` / `sndSetHookNote(fn)` | 0x302 / 0x303 | install hooks |
| `sndSetVoices(n)` | 0x304 | number of sampled voices (≤ 7); not in A/A0 |
| `sndCommit()` | – | make the queued commands visible to the driver |
| `sndStopOutput()` / `sndStartOutput()` | – | stop / restart mixing and DMA |
| `sndGetPlayerState(pl)` | – | 0 idle, 1 playing, 2 fading (read directly) |

Commands are 12-byte records `{u16 op; u32 a; u32 b}` in a ring of 46. Only `sndCommit` publishes
them, so a game can queue several changes that take effect in the same frame. `cmdProcess`
dispatches on `op >> 8` through a four-entry table (`kCmdHandlers`).

Each game wraps this API in its own glue (sound-id tables, "area" echo settings, music on player
19 in SMA / 18 in ALttP). The glue is game code and is not part of the sources.

---

## 4. Hardware resources

| Resource | Setting |
|---|---|
| Timer 0 | reload `0xF9C4` → 16 777 216 / 1 596 = **10 512.03 Hz** |
| `SOUNDCNT_H` | low `0x0D`: PSG 50 %, FIFO A/B 100 %; high `0x9A`: FIFO A → left, FIFO B → right, both timer 0 |
| `SOUNDCNT_L` | `0xFF77` at init; the PSG code rewrites NR51 (high byte) for pan every frame |
| `SOUNDBIAS` | bits 14–15 = 1: 8-bit resolution, 65.536 kHz PWM |
| DMA1 / DMA2 | `0xB6400004`: repeat, 32-bit, FIFO timing, fixed destination — left / right buffer |
| PSG | channels 1–4, used by PSG instruments only |

The DMA buffers are 4 × 176 bytes (`A0 B0 A1 B1`). Each V-blank `mixDmaRestart` stops DMA1/2 and
restarts them on the pair mixed during the previous frame, then `mixFrame` fills the other pair.
There is no DMA interrupt; the timing relies on 176 samples lasting one frame
(176 × 59.7275 = 10 512.04).

---

## 5. Per-frame flow

```
V-blank     sndVSync()  -> mixDmaRestart(): timer 0 on, DMA1/2 restarted on buffer[idx], idx ^= 1
main loop   sndMain():
              cmdProcess()     apply committed commands
              playerTickAll()  fades; trackTick() on every track (sequencer)
              psgUpdate()      the 4 GB channels: pitch, envelope, pan, duty, key-on/off
              mixFrame()       if output enabled:
                wet  = echo history[pos]          (if the echo is on)
                dry  = 0
                for each sampled voice (active list): volume, pitch, mixVoice() -> dry or wet
                notes whose length ran out -> noteOff
                echo: dry += wet; wet >>= shift; history[pos] = wet; pos = (pos+1) % 18
                armDownmix(dry -> buffer[idx])    L -> FIFO A buffer, R -> FIFO B buffer
```

**Timing.** Sequencing is per frame: all events due in a frame run together. A track's `wait` is
in ticks × 150 and drops by `tempo + tempoOfs` each frame, so tempo 150 is one tick per frame and,
at 24 ticks per quarter, **the tempo value is the BPM** (×0.9955 on hardware, 59.73 Hz).

---

## 6. RAM and structures

All offsets are in `nsnd.inc`; the RAM addresses of each build are in `<build>_ram.inc`.

### 6.1 RAM map (SMA4; B and Z are the same layout at −0x70 / +0x28)

```
03000118 gDmaBufA[2], 03000120 gDmaBufB[2]   0300012A buffer index, 0300012B output on
03000128 timer reload (0xF9C4)               03000130 gKitInst (the RAM instrument of sample kits)
03000138 echo shift, 0300014D echo pos, 0300014E echo length (18), 0300014F target, 03000150 tail
0300013C last wave uploaded                  03000140 active / 03000144 free / 03000148 reserved voice lists
0300014C voice count (7)                     03000158 note hook, 0300015C command-CA hook
03000160 command queue [46] x 12             03000394..030003A0 read / write / committed / end
030003A4 gCfg                                030003A8..B0 IWRAM addresses of the ARM loops
030003B4 DMA buffers 4 x 176                 03000674 dry bus 2 x 176 s16,  03000934 wet bus
03000BF4 -> echo history (02036000: 18 x 0x2C0 bytes in EWRAM)
03000BF8 Track[24] (0x54)    030013D8 ARM loops (0x360)   03001738 Voice[7] sampled
03001A80 Voice[4] PSG        03001C60 Player[20] (0x48)
```

Build A keeps the same objects in a different order and replaces the three list heads by four
whole `Voice` structures used as sentinels (`gActiveHead/Tail`, `gFreeHead/Tail`).

### 6.2 Structures

| Structure | Size | Key fields |
|---|---|---|
| **Voice** | 0x78 | type (0 sampled, 1–4 PSG), state (0 free, 1 on, 2 released), track, priority, key, velocity, freq / outFreq, volume, length (frames), echo, fixed pan, pan, LFO phase/delay, portamento (delay, count, offset, total, step), envelope (level, target, count, step, table, index), instrument, release, sample, position (24.8) / PSG frame counter, PSG data, pool links, track links |
| **Track** | 0x54 | read pointer, sample bank, player, voices, LFO delay/speed/depth, portamento, call stack (3) + sp, wait, bank, program, note length, rest length, velocity, tie, mute, pan, echo, volume, expression, bend, bend range, transpose, priority, "notes advance time" |
| **Player** | 0x48 (A: 0x44) | bank map, base, tracks[10], tempo, tempo offset, volume (0x8000 = 1.0), fade step/target/count, flags (bit 0 paused), song volume, volume 2, state, isSfx, hook flags |
| **SndCmd** | 12 | op, a, b |

---

## 7. The mixer

### 7.1 Per voice (`mixVoice` + `armMixVoice`)

```
volL = vol × (127 − pan) >> 8,   volR = vol × pan >> 8          (A: >> 7 each)
for each of 176 output samples:  s = pcm[pos >> 8]  (signed 8-bit, no interpolation)
                                 L += s × volL;  R += s × volR;  pos += step
out = clamp(acc / 128, −128, 127)   (armDownmix)                  (A: gains >> 8 per sample, no final shift)
```

`step` (24.8) = `rate × (pitch >> 2) / 10 512 >> 5`, so a sample plays at its own rate at the
root key whatever that rate is. 48 kHz samples are therefore decimated by ~4.6 with no filtering
— a large part of these games' characteristic grit.

Looping: when a loop end falls inside the frame, the loop is split at exactly the output sample
where `pos` reaches `loopEnd`, and `pos` is moved back by `(loopEnd − loopStart) × 256`, as many
times as needed. A one-shot sample that ends frees the voice.

### 7.2 Voice allocation

Seven sampled voices in three lists: **free**, **active**, and **reserved** (voices removed by
`sndSetVoices`). The active list is kept sorted so that its head is the best victim: released
voices first (lowest priority first), then playing voices by priority; a new voice goes after
existing ones of equal priority. `voiceAlloc` takes a free voice, else steals the head if it is
released or its priority is not above the new note's. PSG instruments always use their own
channel, stealing it under the same priority rule. Track priority is 3 for music and 12 for
sound effects by default (command C4).

### 7.3 Volume

```
sampled:  x = player.volume × velocity × 128 >> 8;  x = x × songVolume >> 7;  x = x × volume2 >> 8
          x = x × track.volume >> 8;  x = x × expression >> 15;   level = envelope × x >> 11
          mix volume = level >> 8          (ALttP: level × 3 >> 9)
released: level = level × (release + 230) >> 9   every frame  (exponential, ×0.45 … ×0.95)
```

With every control at its default a full-velocity note has mix volume ≈127 and peaks at about
±31 in the 8-bit output, so the seven voices can just about sum without clipping.

### 7.4 Echo

The wet bus of frame *n* starts as the stored wet output of frame *n* − 18. Voices of tracks with
echo ≠ 0 are mixed into it. Then `dry += wet` and the history keeps `wet >> shift`
(`armEcho`). The result is a single 301 ms echo repeating with feedback 2^-shift: shift 1 = ½,
2 = ¼ … The game sets a target shift per area (`sndSetEcho`) and the driver moves one step per
frame. In B/C, shift 16 means off; the history keeps being fed for 18 more frames so the echo
tail dies naturally. In A the echo always runs and its default shift of 31 makes it silent.
Sound-effect tracks start with echo 127 (on), music tracks with echo 0 (command E3).

---

## 8. Instruments, samples and pitch

### 8.1 From a note to a sound

```
song/sfx bank map[track.bank]          -> instrument bank index      (command C7 selects the bank)
cfg.instBanks[index] + u16 table[prog]  -> instrument record          (command C2 selects the program)
cfg.instToSampleBank[index]            -> sample bank used for type-0 records
```

| Type | Record | Meaning |
|---|---|---|
| 0 sample | `type, flags, sample#, env, release, root` | sampled voice |
| 1 square 1 | same + `sweep, pad[3]` (12 bytes) | `data` = duty (0–3) or duty-sequence offset |
| 2 square 2 | same (8 bytes) | |
| 3 wave | same | `data` = offset of a 16-byte wave |
| 4 noise | same | `data` = 0: 15-bit LFSR, ≠ 0: 7-bit (or a sequence of these) |
| 0x10 drum kit | `data` = table, low byte of `env` = first key | 4-byte entries `{u16 instrument, u8 pan, 0}`; plays the entry at key 48 relative to its root with a fixed pan |
| 0x11 sample kit | 4-byte record, `data` = table | u16 sample number per key; played at the sample's rate with a flat envelope |
| 0x12 key split | 4-byte record, `data` = table | entries `{u8 highest key, 0, u16 instrument}` |

`flags` bit 0: `data` points at a **duty / noise-mode sequence** (`u16 n; u8 value[n]`, one per
frame, the last one held); bit 4: note length is not affected by the tempo offset.

### 8.2 Envelopes

A table of `{s16 frames, s16 level}` pairs; each segment moves linearly from the current level to
`level` (0–0x7FFF) in `frames` frames; a pair with negative `frames` ends the table and the
envelope holds. Typical: `{1, 0x7FFF}, {-1}` (instant attack, sustain full), or multi-segment
decays. Release is separate (§7.3).

For **squares and noise** the driver cannot change the volume every frame without retriggering,
so at the start of each segment `psgEnvelope` computes the start and end volumes (0–15) and
programs the hardware envelope with direction and a step time `(frames + 15) / |Δ|` (1–7), which
approximates the segment. The **wave** channel has no envelope: its volume is set directly
(mute/25/50/75/100 %), and its release is done in software.

### 8.3 Pitch

`n = key + 48 − root`, clamped to 0…120:

* sampled voices: `kDsPitch[n] = 32768 × 2^((n−48)/12)` multiplies the sample's own rate;
* squares / wave: `kPsgFreq[n]` = GB frequency register value, n = 48 is C4 (261.6 Hz);
* noise: n itself indexes `kNoiseTable` (NR43 clock-shift / ratio).

Drum and sample kits play at n = 48 (the sample's natural pitch).

### 8.4 Pitch bend, vibrato, portamento

* **Vibrato** (E5 delay, E6 speed, E7 depth): a 256-step sine; `pitch × (1 + depth × sine / 2^19)`
  (divided for negative values, applied to the period on PSG channels). Depth 255 ≈ ±1 semitone.
* **Portamento** (Dx): slide linearly between the note and a second key over `len/256` of the note,
  after an optional delay; mode bit 1 slides away from the note instead of towards it, bit 2 chains
  the next note from this one.
* **Pitch bend** (E1 bend, E2 range):
  * builds A/A0: `factor = 1 + bend/128 × (2^(range/12) − 1)` — bend ±128 = ±range semitones;
  * builds B/Z/B0/C: `factor = 1 + |bend|/128 × 2^(range/12)` up, divided by the same factor down.
    **The "− 1" was lost in the rewrite**: with the default range of 2, a bend of 32 is +0.5
    semitone in SMA2 but **+4.3 semitones** in SMA3, SMA4 and ALttP (§13, bug 1).

---

## 9. Sequence format

A song: `s8 trackCount, u8 0, u16 trackOffset[trackCount]` (0 = no track), offsets relative to the
song. A sound-effect set: `u16 offset[n]`, the table ending where the lowest offset begins; each
sound is one track (it can start more with F8). Jumps, calls and spawns are offsets from the
song / set start.

| Byte | Operands | Meaning |
|---|---|---|
| `00`–`5F` | – | note (key 0–95) with the previous length and velocity |
| `60`–`BF` | varlen length, u8 velocity | note key = byte − 0x60; length and velocity become the defaults |
| `C0` | – | rest for the previous rest length |
| `C1` | varlen | rest n ticks |
| `C2` / `C3` / `C4` | u8 | program / pan (0–127, 64 centre) / priority |
| `C5` / `C6` | – | tie on / off (a new note reuses the sounding voice; key-offs are ignored) |
| `C7` | u8 | bank (through the song's bank map); resets the program to 0 |
| `C8` / `C9` | – | notes advance time (default for SFX) / notes do not (chords; default for music) |
| `CA` | u8 | call the game's hook with the byte (skipped if no hook) |
| `D0`–`DF` | key, len[, delay if bit 0] | portamento (low nibble = mode) |
| `E0` / `E1` / `E2` / `E3` | u8 | volume / bend (s8) / bend range / echo |
| `E4` | varlen (A/A0: u8) | tempo (= BPM) |
| `E5` / `E6` / `E7` | u8 | vibrato delay / speed / depth |
| `E8` | – | portamento off |
| `E9` | s8 | transpose |
| `EA` | u8 | song volume (not in A/A0) |
| `F0` / `F4` | u16 | jump / call (return stack of 3, not checked) |
| `F8` | u8 slot, u16 | start another track of this player in that slot, inheriting the track settings |
| `FF` | – | return, or end of track at depth 0 |
| others | – | one-byte no-ops |

*varlen*: one byte 0–0x7F, or two bytes `1xxxxxxx yyyyyyyy` = `x << 8 | y`. The encoder often used
the two-byte form for small values (e.g. tempo `E4 80 45` = 69), so the sources keep both forms.

Songs usually loop with a final `F0` back into the track; tracks keep separate loops, so a song's
"loop" is the combination of its tracks'.

---

## 10. Data layout

```
SndConfig (7 pointers, passed to sndInit):
  +00 sampleBanks      u32 offset table (count = first/4) -> bank: u32 offsets -> SampleHdr + PCM
  +04 instBanks        u32 offset table -> bank: u16 program table, envelopes, records, kit tables, waves, duty sequences
  +08 songs            u32 offset table -> song header + track code
  +0C sfxSets          u32 offset table -> u16 offset table + track code
  +10 instToSampleBank u16 per instrument bank
  +14 songBankMaps     u32 offset table -> u16 bank map per song
  +18 sfxBankMaps      u32 offset table -> u16 bank map per set
SampleHdr: u32 length, u32 rate (Hz), u32 loopStart, u32 loopEnd (0 = one-shot), s8 pcm[]
```

All offsets are relative to the table or bank that holds them, so each block is position
independent. Stored PCM of looped samples stops shortly after the loop end, so `length` is
meaningless for them.

| | SMA2 | SMA3 | ALttP | SMA4 |
|---|---|---|---|---|
| Sound data | `08239C74`–`0833D510` (1.06 MB) | `083A8274`–`0849D879` (1.00 MB) | `081F9F5C`–`082A1BD8` (0.69 MB) | `08308F7C`–`08485E2B` (1.56 MB) |
| Config | `081B3EE4` | `083A7810` | `081F986C` | `083084BC` |
| Sample banks (samples) | 50 / 5 / 59 | 81 / 5 / 30 | 43 / 9 / 9 (banks 1 = 2) | 58 / 5 / 61 |
| Sample rates | 10 512 ×74, 32 k ×15, 44.1 k ×14, 48 k ×9 | 48 k ×61, 10 512 ×50 | 48 k ×29, 10 512 ×25 | 10 512 ×86, 32 k ×21, 48 k ×10, 44.1 k ×7 |
| Instrument records | 116 sample, 30 PSG, 3 kits, 1 sample kit | 128 sample, 35 PSG, 2 kits, 1 sample kit | 79 sample, 3 splits, 1 kit, 1 sample kit, no PSG | 110 sample, 43 PSG, 2 kits, 1 sample kit |
| Songs | 67 | 61 | 34 | 87 |
| Sound effects | 196 + 54 | 219 + 54 | 142 + 54 | 188 + 54 |
| Events / notes | 85 537 / 37 577 | 80 289 / 32 818 | 52 653 / 21 779 | 75 446 / 30 470 |

Effect set 1 (54 sounds) is the same data in SMA3, SMA4 and ALttP — a shared library of Mario
voice clips and jingles *(inferred from identical bytes)*; in ALttP its bank map points at a bank
that does not hold those programs, so it is unusable there (§13).

The complete decode of each game is in `<game>_data_dump.txt`; the data sources
(`<game>_sound_data.s`) show every sequence as macros.

---

## 11. Commands from the game in practice

Music: SMA2/3/4 always use player 19 and ALttP player 18; fades use `sndFadeOut` with the same
player; SMA3 and SMA4 pause the music with `sndPause`. The echo is set once per area from a game
table (`sndSetEcho`). Effects use per-sound player numbers from each game's glue tables, which is
how simultaneous effects avoid cutting each other off.

---

## 12. PSG details

* Pan is hard: 64 = both speakers, < 64 left only, > 64 right only; a hard-panned PSG note plays at
  double velocity to compensate.
* The frequency is rewritten every frame without retrigger when the envelope does not change
  (square 1 only when its sweep is off, sweep value 8).
* Key-off on squares/noise writes a decaying hardware envelope (`release >> 5` steps) and frees the
  channel immediately; the wave channel fades in software.
* Wave data is uploaded (CpuSet into the idle bank, then NR30 = 0xC0) only when it differs from
  the last upload.

---

## 13. Bugs, quirks and dead code

### 13.1 Audible or data-dependent

1. **Pitch bend (B, Z, B0, C)**: the rewritten bend formula drops the "− 1" (§8.4). Only a few
   sound effects use E1 (values 5–32 and −5 … −15), but those shared effects bend 4–8 times further
   in SMA3/SMA4/ALttP than in SMA2.
2. **Garbage instruments in SMA2 music.** Songs 0 and 1 (track 7) play key 43 on drum kit 127 of
   instrument bank 2, whose table has no such entry, and song 21 (track 7) plays notes without ever
   selecting a program, i.e. program 0, whose slot is empty. In both cases the driver reads the
   instrument from the program table itself: "sample 660" of a 50-sample bank, whose header pointer
   lands at `0x54701287` — outside any memory. On hardware that reads open bus, so the note plays
   whatever the bus returns *(the emulator gives zeros: the voice ends immediately)*.
3. **Long notes wrap (A, A0)**: note lengths are passed as `(u16)(ticks × 150)`, so notes longer
   than 436 ticks are cut: the 1176-tick notes of SMA2 songs 0 and 1 (track 7) last 302 ticks, and
   sound effect 0/88 (32 767 ticks) lasts 435.
4. **Square 2 key-on ignores duty sequences**: `psgKeyOn` writes the low byte of the sequence
   *pointer* as the duty for the first frame; the right value arrives one frame later.
5. **Released wave voice reads through NULL**: after a note-off the voice has no track, but
   `psgEnvelope` still reads `track->volume` etc. at each envelope segment start — i.e. the BIOS
   area. On hardware BIOS reads from ROM code return the last BIOS opcode, so the wave release
   volume can jump.
6. **ALttP effect set 1** (54 sounds shared with SMA3/SMA4) maps bank 0 to the sample-kit bank, so
   its programs point outside the program table; 36 of its 54 sounds use undefined instrument
   types. The game never plays them *(inferred: no path in the glue selects set 1)*.
7. **Key index 120**: `keyToFreq` clamps to 120 although the tables have 120 entries (0–119), so a
   note ≥ 72 semitones above the root reads the next table (`kDsPitch[120]` = the first sine bytes,
   0x09060300 — an ear-splitting pitch). Only reached by the unusable data of item 6.
8. **SMA3 and SMA4-multiboot do not clear the DMA buffer at init**; the first frame plays stale RAM.

### 13.2 Latent

1. `trackTick` F8 does not check that `trackAlloc` found a track: with all 24 in use it writes
   the inherited settings through NULL.
2. `playerStartSong` does not bound the track count by the 10 slots of a player.
3. The call stack has three slots and no check; a fourth call overwrites the stack pointer.
4. The command queue has no overflow check; `cmdProcess` does not range-check `op >> 8`.
5. `instLookup` leaves `inst` unset for types other than 0–4 and 0x10–0x12, and for a wave
   instrument inside a kit or split takes the wave from the kit's own `data`.
6. An envelope segment of 0 frames divides by zero (libgcc returns 0) and then counts from −1:
   the envelope freezes for 65 536 frames. Only garbage records (items 2 and 6) have one.
7. `playerFadeOut(pl, 0)` divides by zero.
8. Build A computes `step × 176 / 176` (a leftover no-op) and runs the echo at full CPU cost while it
   is inaudible.

### 13.3 Dead code

* `sndMuteTracks`, `sndSetTrackBend`, `sndSetVoices`, `sndCallback`, the hooks and the reserved
  voice list are complete but unused by these four games; `echoSetFeedback` is an empty function
  in the multiboot builds.

---

## 14. Differences between builds

(The per-function "In this build" notes in the sources give the details.)

* **A → B (rewrite for SMA3):** NULL-terminated voice lists and a reserved list with
  `sndSetVoices`; varlen tempo; song volume EA; bend command 0x103; echo switchable at shift 16 with
  a fading tail; mixer keeps 16-bit precision (`mla` into the accumulator, one `>> 7` at the end,
  round-towards-zero echo); `Div` BIOS call instead of `__udivsi3`; the bend formula change.
* **B → Z (ALttP):** DMA buffer cleared at init; sampled voices at ¾ volume.
* **B/Z → C (SMA4):** a paused player's voices are frozen (not mixed, PSG keyed off) instead of
  releasing every note of every track each frame.
* **Multiboot builds (A0, B0):** the corresponding main build with all echo code and buffers
  removed (`echoSetFeedback` empty).

---

## 15. Rebuild and verification

`make -f nsnd.mk check` in the source folder (needs `arm-none-eabi-as/ld/objcopy` and Python 3; the ROMs as
`sma2.gba`, `sma3.gba`, `sma4.gba`, `zelda.gba` next to the folder) extracts the PCM
(`nsnd_tool.py extract-pcm`), assembles everything, links each section at its original address
and compares:

```
sma2     .snd_code    0809C5A0-0809EBB4    9748 bytes  identical  driver code
sma2     .snd_rodata  081B43FC-081B4870    1140 bytes  identical  driver tables
sma3     .snd_code    0812FA0C-0813223C   10288 bytes  identical
sma3     .snd_rodata  083A7D7C-083A81F0    1140 bytes  identical
sma4     .snd_code    080E8204-080EAA80   10364 bytes  identical
sma4     .snd_rodata  08308988-08308DFC    1140 bytes  identical
zelda    .snd_code    0812B714-0812DF58   10308 bytes  identical
zelda    .snd_rodata  081F9AE8-081F9F5C    1140 bytes  identical
sma2_mb  .snd_code    0201C0D0-0201E5B8    9448 bytes  identical  (ROM 0xAD9C8)
sma3_mb  .snd_code    0201C0F0-0201E5D8    9448 bytes  identical  (ROM 0x13F8CC)
sma4_mb  .snd_code    0201BF78-0201E63C    9924 bytes  identical  (ROM 0xF9E10)
         (+ the three multiboot table sections)
sma2     .snd_data    08239C74-0833D510 1063068 bytes  identical  sound data   (+ SndConfig)
sma3     .snd_data    083A8274-0849D879 1005061 bytes  identical
sma4     .snd_data    08308F7C-08485E2B 1560239 bytes  identical
zelda    .snd_data    081F9F5C-082A1BD8  687228 bytes  identical
```

**Model check.** `nsnd_emu.py` runs the ROM's own driver in Unicorn (BIOS calls emulated),
calling `sndInit`, the queue functions, `sndVSync` and `sndMain` exactly like the games.
`nsnd_model.py` is an independent Python implementation of this report. `nsnd_verify.py` compares
both every frame — the 352 mixed output bytes and every PSG register write — and
`verify_scenario.py` exercises echo, pause/resume, tempo offset, volume and fade-out with a song
and an effect playing together:

| | frames per sequence | sequences | identical |
|---|---|---|---|
| Songs SMA2 / SMA3 / SMA4 / ALttP | 3 600 (60 s) | 67 / 61 / 87 / 34 | all 249 |
| Sound effects SMA2 / SMA3 / SMA4 / ALttP | 600 | 250 / 273 / 242 / 196 | all, except 36 of ALttP's unusable set 1 (undefined instrument types) |
| Command scenarios (all four games) | 1 200 | 14 (5 of them SMA4 songs) | all |

The multiboot builds were checked by reassembly only.

---

## 16. Deliverables

In `…/GBAAudioLab/Nint3/NintSMA/`:

| File | Contents |
|---|---|
| `src/<build>_sound.s` ×7 | the driver: labelled Thumb and ARM with pseudo-C above every function |
| `src/<build>_sound_rodata.s` ×7 | driver tables (pitch, noise, sine, wave volume, handlers) |
| `src/<game>_sound_data.s` ×4 | config, all tables, instrument banks, sample headers (PCM via `.incbin`) and every sequence as macros |
| `src/nsnd.inc`, `nsnd_macros.inc`, `<build>_ram.inc` | registers, structure offsets, RAM addresses; data macros |
| `src/nsnd.mk` (the Makefile), `<build>.ld`, `<game>_data.ld`, `romcheck.py` | rebuild and compare |
| `tools/nsnd_tool.py` | `extract-pcm`, `wav`, `dump`, `midi`, `render` |
| `tools/nsnd_data.py`, `gen_data.py`, `gen_s.py`, `gen_sources.py` | data parser and source generators |
| `tools/nsnd_emu.py`, `nsnd_model.py`, `nsnd_verify.py`, `verify_scenario.py` | ROM driver in Unicorn, model, checks |
| `tools/verify_all.py`, `rammap.py`, `make_syms.py`, `build_check.py`, `cdiff.py`, `fnorm.py` | analysis helpers used during the work |
| `syms_<build>.json` | address → name maps of every build (used by the emulator harness) |
| `doc/pseudo_ref.txt`, `doc/variants.txt` | the pseudo-C and per-build differences that `gen_sources.py` puts above each function |
| `dumps/<game>_data_dump.txt` | decoded data |
| `<game>_midi.zip` | songs and effects as MIDI (24 ppqn, program = bank×128+program via CC0) |
| `<game>_wav.zip` | every sample as WAV with root and loop in a `smpl` chunk |
| `sma2_song01.wav`, `sma3_song01.wav`, `sma4_song01.wav` | example renders through the ROM's own driver |

The tools find the ROMs by themselves in `$NSND_ROMDIR`, `NintSMA/` or `Nint3/` (short names
`sma2.gba` … `zelda.gba` or the original file names, `.gba` or `.bin`), so `cd src && make -f nsnd.mk check` works in place (rename nsnd.mk to Makefile if you prefer plain `make`).
The build first writes `<game>_pcm.bin` (the raw PCM, not shipped) with `extract-pcm`.

---

## 17. Notes for tooling

* **Playing the music elsewhere:** the MIDI files keep the driver's tick grid and tempo; map
  programs through the song's bank map to an instrument bank and build instruments from the
  WAVs. Echo, the linear envelopes, the PSG envelope emulation and nearest-neighbour resampling
  are not in the MIDI.
* **Exact audio:** `nsnd_tool.py render` plays through the ROM's own driver and adds a simple GB
  APU model for the PSG channels (approximate).
* **To sound like the game:** 10 512 Hz, no interpolation, 8-bit output, 60 Hz sequencing, and
  the 18-frame feedback echo.

---

## Appendix A: function map (build C, SMA4)

```
080E8204 sndInit            080E82D0 sndVSync          080E82DC sndMain           080E8300 mixInit
080E8394 mixDmaRestart      080E8444 sndStopOutput     080E8490 sndStartOutput    080E849C mixVoice
080E864C kitInstInit        080E8668 instLookup        080E8744 voiceInitAll      080E88F8 voiceListRemove
080E8914 voiceListPush      080E892C voiceListInsertActive 080E89B4 keyToFreq     080E8A08 noiseDivider
080E8A24 envStep            080E8A94 echoSetFeedback   080E8AA4 voiceSetCount     080E8B54 dsVolume
080E8BBC psgEnvelope        080E8CC8 voicePitch        080E8E5C mixFrame          080E9070 psgUpdate
080E9328 noteOn             080E94F4 noteOff           080E95E0 voiceStop         080E9678 psgKeyOn
080E97D8 voiceAlloc         080E9870 trackInitAll      080E989C trackAlloc        080E98C4 trackStart
080E9980 trackReleaseAll    080E99B0 trackStop         080E99C8 trackTick         080E9E34 trackAddVoice
080E9E50 trackRemoveVoice   080E9E7C readVarLen        080E9EA4 trackSetBank      080E9ED8 playerInitAll
080E9F0C playerReset        080E9F4C playerTickAll     080E9FDC doPlaySong        080EA004 doPlaySfx
080EA030 playerStartSong    080EA0B8 playerStartSfx    080EA124 playerStop        080EA160 playerFadeOut
080EA198 playerSetPause     080EA1BC sndGetPlayerState 080EA1D0 cmdNext           080EA1F8 cmdInit
080EA238 cmdPop             080EA274 sndCommit         080EA288 sndPlaySong       080EA2AC sndPlaySfx
080EA2D4 sndFadeOut         080EA2F8 sndPause          080EA31C sndFadeOutMask    080EA33C sndPauseMask
080EA360 sndSetTempo        080EA384 sndSetVolume2     080EA3A8 sndSetHookFlags   080EA3CC sndMuteTracks
080EA3F4 sndSetTrackExpr    080EA41C sndSetTrackBend   080EA44C sndSetTrackPan    080EA474 sndSetEcho
080EA494 sndSetVoices       080EA4B4 sndCallback       080EA4D4 sndSetHookCA      080EA4F0 sndSetHookNote
080EA50C cmdPlayer          080EA5A0 cmdTrack          080EA6BC cmdMask           080EA72C cmdGlobal
080EA794 cmdProcess         080EA7C8 armDownmix*       080EA8E8 armMixVoice*      080EA9E0 armEcho*
```
(* ARM, run from IWRAM.) The other builds' maps are the symbol tables at the top of their sources.
