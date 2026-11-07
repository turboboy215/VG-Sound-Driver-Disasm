# Brownie Brown sound driver, revision 2 (Sword of Mana)
## Reverse-engineering report and technical reference

**Subject file:** `…/GBAAudioLab/Brownie/Sword of Mana (E).gba` (`AVSP`, 16 MiB).
**Earlier revision:** Magical Vacation, see `brownie-magvac-technical-reference.md`. This document lists everything
for SoM and marks what changed from MV (**[new]** / **[changed]**).

**Provenance.** The ROM has no symbols; all names were assigned in this analysis. The driver block
`0x080A0510`–`0x080A2997` (mixer IRQ, 5-voice mixer, Thumb glue, tables, sequencer, length and envelope tables) and
its linker veneer island `0x0836D8A4`–`0x0836D8DB` have been disassembled into a labelled GNU-as source. The source
rebuilds **byte-identical** (9 352 + 56 bytes, §11). All 1 447 tracks in the 745 sound ids were walked with the
documented command set. Inferences are marked *(inferred)*.

---

## 1. Executive summary

* **Same engine family as MV.** It keeps the same 0x38-byte track struct, `{slot, seq, patterns} … 0xFF` song headers,
  PSG note/envelope handling, `F0`–`FF` command page, SE-over-music muting and one-id-per-frame queue.
* **[new] Software PCM mixer.** Output is a fixed **16 384 Hz** on timer 0. DMA1/DMA2 feed FIFO A/B from 16-byte
  IWRAM buffers. Each DMA IRQ mixes the next 16 samples (1 024 IRQs/s).
  * There are two mixer paths, selected by the sequence command `E2`. The 2-voice ROM/IWRAM path mixes voices 0–1
    with plain sample repetition. The 5-voice IWRAM path mixes voices 0–4 with midpoint interpolation.
  * Stereo is hard-wired: FIFO A goes to the **right** speaker and FIFO B to the **left**. Each voice has its own A/B
    volume.
* **[changed] PCM pitch has no rate table.** An instrument is a list of **12 pre-pitched samples, one per semitone**.
  The octave comes from the voice's ×1/×2/×4/×8 upsampling mode (note 36–47 = ×1 … 0–11 = ×8).
* **[changed] 13 tracks:** 0–3 PSG music, 4–7 PSG SE (mute 0–3), 8–12 PCM (voices 0–4). There is no automatic PCM
  SE muting; sequences use `E8`/`E9`.
* **[changed] Tempo per track:** `EE nn` picks a row offset into a 24-row length table (rows 0–7: quarter = 32 + 4·row
  frames).
* **[changed] Fade-out pauses** all tracks (flag 0x80). Fade-in (API or `E3`) resumes them and queues id 0x36.
* **8-slot queue.** Ids 0x3B/0x3D are only started when the noise channel is free.
* State moved to **IWRAM** (`0x03002ACC`…). The mixer code is DMA-copied to IWRAM `0x03003150`/`0x03003750` at init.

---

## 2. ROM / RAM map

| Item | Address |
|---|---|
| Mixer IRQ `sndMixIrq` | `0x080A0510`–`0x080A0987` (+ 16-byte `mixSilence` `0x080A0988`, pool `0x080A0998`) |
| 5-voice mixer `sndMixFull` | `0x080A09DC`–`0x080A0EB7` (pool `0x080A0EB8`) |
| Thumb glue (7 wrappers) | `0x080A0ED8`–`0x080A0F7F` |
| PSG freq table | `0x080A0F80`: 84 × u16, entry 0 = `0x078` (68.0 Hz, about C2 + 66 cents; octaves exact) **[changed]** |
| PSG register / pan tables | `0x080A1028` CNT_H addrs, `0x080A1048` CNT_X addrs, `0x080A1068` pan bits, `0x080A1074` masks (same as MV) |
| Constants | `0x080A1080` `0xFC00` (TM0 reload), `0x080A1084` `0xFFFFF9FF` |
| Sequencer core | `0x080A1088`–`0x080A204F`; command table `0x080A1B10` (32 words); pool `0x080A2050`–`0x080A219B` |
| Length table | `0x080A219C`: 24 × 16 bytes **[changed]** |
| Envelope table | `0x080A231C`: 160 pointers → scripts `0x080A259C`–`0x080A2997` |
| Song table | `0x080A2998`: 745 pointers (to `0x080A353B`) |
| Instrument table | `0x080C2884`: 24 × `Sample **` (20 used, 4 null) **[new]** |
| Wave table | `0x0836723C`: 24 × 16-byte wave pointers |
| Veneers | `0x0836D8A4`–`0x0836D8DB` (7) |
| Tracks | IWRAM `0x03002ACC` + 0x38·n; 14 cleared, 13 updated |
| Queue | `0x03002DDC` read, `0x03002DDD` write, `0x03002DDE` u16[8] (0 = empty) |
| Mix mode | `0x03002DEE` (u8, `E2`) |
| Master | `0x03002DF0`: +0 volume, +1 step, +2 u16 fade-out frames, +4/+6 out acc/period (8.8), +8/+0xA in acc/period, +0x18 fade-in frames (read as u8) |
| SOUNDCNT_L shadow | `0x03002DFC` |
| Voices | `0x03002E0C`: 6 × 16 bytes (0–4 mixed) |
| Mix buffers | `0x03002E6C` (A, right) / `0x03002E7C` (B, left), 16 bytes each; staging `0x03002E8C` (5 × 16) |
| IWRAM code | `0x03003150` ← ROM `0x080A0510` (0x600 bytes effective); `0x03003750` ← ROM `0x080A09DC` (0xC00) |

### 2.1 Functions

| Address | Name | Callers | Purpose |
|---|---|---|---|
| `080A0ED8` | `Sound_Play(u16 id)` | 375 | → `sndQueueSound`; skipped when `*(u8*)0x02000000 ≠ 0` and id > 0x2F |
| `080A0EFC` | `Sound_Init()` | boot `0x08000514` | `sndInit`, then DMA3 copies of the mixer to IWRAM (also done by game code at `0x0808E874`) |
| `080A0F3C` | `Sound_Frame()` | 4 | → `sndFrame` |
| `080A0F48` / `080A0F54` | `Sound_DmaIrqA/B()` | IRQ stubs `0x08001404` / `0x08001410` | → ROM `sndMixIrq`. The IRQ vector tables at `0x0836D8DC`… point DMA1/DMA2 at IWRAM `0x03003150` directly |
| `080A0F60` | `Sound_FadeOut(u8 n)` | 24 (constant arguments seen: 1–4) | → `sndFadeOut` |
| `080A0F70` | `Sound_FadeIn(u8 n)` | 3 | → `sndFadeIn` |
| `080A0510` | `sndMixIrq` | | §7 |
| `080A09DC` | `sndMixFull` | via `ldr pc, =0x03003750` | §7 |
| `080A1088` | `sndQueueSound` | | `queue[w] = id; w = (w + 2) & 0xF` |
| `080A10A8` | `sndFadeIn` | | §8 |
| `080A1160` | `sndFadeOut` | | §8 |
| `080A11D0` | `sndInit` | | §9 |
| `080A129C` | `sndFrame` | | §4 |

---

## 3. Sequence data

### 3.1 Song header

Same as MV: `{u32 slot; u8 *seq; u8 **patterns}` repeated, ended by `u32 0xFF`. Starting a slot sets flags = 1 and
clears +0x24…+0x2F, including the tempo row (+0x2F). Only slots 4–7 mute slot − 4. Of the 745 ids, 96 are empty.

### 3.2 Track bytecode

| Byte(s) | Meaning |
|---|---|
| `00`–`7F` | Note |
| `80`–`DF` | Length = `lengthTable[(b & 0x7F) + 16·tempoRow]` **[changed]** |
| `E0 nn` | **Envelope jump [new]**: envelope position = `envelopeTable[nn]`, step next frame, then wait one length (tie) |
| `E1 nn` | **Instrument [changed]**: `inst = instTable[nn]` (a 12/13-sample table) |
| `E2 nn` | **Mix mode [new]**: `sndMixMode = nn`. 0 = 2-voice path and clears the flags of tracks 10–13; non-zero = 5-voice mixer. Values used: 0, 1, 16 |
| `E3` | **Resume [new]**: master volume 0, fade-in over 64 frames (step 4), resume paused tracks, start TM0, queue id 0x36, and **return from `sndFrame` at once**. Used by ids 90 and 685 |
| `E8` | **Unmute music [new]**: track − 4 flags &= 0x81 |
| `E9` | **Mute music [new]**: track − 4 flags \|= 2 |
| `EA nn` | **PCM volume A/B [new]**: volA (right) = lo·16 + 15, volB (left) = hi·16 + 15; a 0 nibble gives 0 |
| `EC` | Rest (PCM): wait one length, stop the envelope, zero the voice |
| `ED` | Rest (PSG): as MV |
| `EE nn` | **Tempo row [new]** (+0x2F) |
| `F0 nn` | Envelope |
| `F1`–`F9` | Duty, volume, transpose, loop start/end, call, return, jump, detune (as MV) |
| `FA` / `FB` | Sweep / sweep off |
| `FC nn` | Wave = `waveTable[nn]` |
| `FD nn` | PSG pan (NR51 bits `nn << (slot & 3)`) |
| `FE` | Tie |
| `FF` | End of track |
| `E4`–`E7`, `EB`, `EF` | No-op (unused) |

MV's duplicate `E2`–`E9` page is gone. `EF` no longer ends a track.

### 3.3 Length table and tempo rows

`index = (b − 0x80) + 16·row`, so a track with row r reads table rows r … r + 5 through bytes `80`–`DF`.

* **Rows 0–7** are clean tempo rows with quarter (column A) = 32, 36, 40, 44, 48, 52, 56, 60 frames (112.0 … 59.7 BPM
  at 59.73 fps). Column E is the whole note (128 … 240).
* **Rows 8–23** have other quarter values (32, 36, 108, 56, 32, 54, 50, 46, 54, 72, 70, 64, 80, 50, 50, 38). They hold
  less regular data that tracks reach with a large row offset *(inferred: tuned for specific songs)*.
* `EE` values used: 0–19, 22, 23. The highest index reached is 381 of 383.

---

## 4. Frame update (`sndFrame`)

As in MV, for tracks 0–12: wait countdown → parse; envelope countdown → step; PCM slide countdown (period 1) →
slide. Then:

1. If fade-in frames ≠ 0, run the fade-in tick; else if fade-out frames ≠ 0, run the fade-out tick.
2. Queue: `id = queue[r]`. If it is non-zero, clear the slot, set `r = (r + 2) & 0xF` and start the id. If the slot
   is 0 but `r ≠ w`, both indices are reset to 0.
3. Ids **0x3B / 0x3D** start only if NR42's volume nibble is 0, or track 3 is inactive, or track 3 has fewer than 3
   frames left. Otherwise they are dropped.

**Track struct changes:**
* +0x14 is now the instrument table pointer (+0x18 is unused).
* +0x2A/+0x2B are the PCM volA/volB on PCM tracks.
* +0x2E is always 1.
* +0x2F is the tempo row.
* flags bit 7 = paused.

**Voice struct (16 bytes, voice = track & 7):** +0 mode (0 ×1, bit 0 ×2, bit 1 ×4, bit 2 ×8), +1 mode copy, +2 volA,
+3 volB, +4 cur, +8 end, +0xC loop.

---

## 5. Pitch

### 5.1 PSG

Same algorithm as MV (`psgFreqTable[n + transpose] + detune`; noise tracks 3/7: NR43 = nibble-swapped note, no
transpose). The table starts at 68.0 Hz instead of 65.4 Hz, so the whole PSG scale is about **+66 cents** sharp of MV's
equal-tempered C2 base *(inferred: tuned to match the PCM instruments)*. Square: MIDI ≈ n + 36 (+0.66 semitone);
wave: n + 24.

### 5.2 PCM

```
n = (note + transpose) & 0x7F;   if (n & 0xC0) n = 47
n < 12 → mode ×8, k = n        n < 24 → mode ×4, k = n − 12
n < 36 → mode ×2, k = n − 24   else   → mode ×1, k = n − 36   (n = 48 → k = 12)
voice ← inst[k] = {start, end, loop}
```

* Output is always 16 384 Hz. Sample k is recorded so that at ×1 it sounds semitone k of the top octave.
* Upsampling ×2/×4/×8 drops 1/2/3 octaves (the 5-voice path interpolates midpoints, the 2-voice path repeats samples).
* Notes 49–63 would read past the table. In SoM only instruments with a 13th entry get note 48, and nothing goes higher.
* **MIDI:** note n → MIDI `K + n − 36`, where K is the pitch of `inst[0]` at ×1 *(sample roots not determined)*.

---

## 6. Envelopes and volume

### 6.1 PSG

`{frames, nrx2}` pairs, identical to MV, including re-triggering on every step.

### 6.2 PCM

Scripts are `{frames, slide, level}` triples.

* `level` sets +0x28. The slide applies **every frame** (period fixed at 1) **[changed]**: bit 7 = down, bits 0–6 =
  amount, clamped 0–255.
* `E0 nn` restarts the script at a new envelope mid-note.

Each step, slide and note-on recomputes:

```
pcmVol = (volume + 1) · level >> 8
volA   = ((master + 1) · pcmVol · (t.volA + 1)) >> 16        (likewise volB)
```

The fade ticks rewrite volA/volB for all active PCM tracks with the same formula.

---

## 7. PCM output (mixer)

### 7.1 `sndMixIrq` (DMA1/DMA2 IRQ, normally at IWRAM `0x03003150`)

```
IF = DMA1 | DMA2;  DMA1/2CNT_H = 0x400 (stop);  SAD1 = sndMixA, SAD2 = sndMixB;  DMA1/2CNT_H = 0xF640
IE &= ~(DMA1|DMA2)
if (sndMixMode) goto 0x03003750 (sndMixFull)
for v in 0, 1:  src = voice[v] idle ? mixSilence : stage 16 bytes (mode 0: the sample itself;
                ×2/×4/×8: each byte repeated 2/4/8 times);  cur += 16/8/4/2 bytes
for i in 0..15: A[i] = (s0·volA0 + s1·volA1 + 0x80) >> 8;  B[i] likewise with volB   (sign-magnitude)
IE |= DMA1|DMA2
```

`0xF640` = enable, IRQ, FIFO timing, 32-bit, repeat, fixed destination. Restarting SAD every IRQ makes the 16-byte
buffer a ring that the CPU refills while the FIFO plays the previous block. Latency is 16 samples (≈ 1 ms).

### 7.2 `sndMixFull` (IWRAM `0x03003750`)

For voices 0–4 it stages 16 bytes into `0x03002E8C + 16·v`:

| Mode | Staging |
|---|---|
| 0 | Copy 16 bytes |
| ×2 | s, avg(s, s′), … |
| ×4 | s, s, avg, avg |
| ×8 | s ×4, avg ×4 |

`avg` is the offset-binary midpoint; the code peeks one byte past the block. Then
`out = (Σ s_v·vol_v + 0x80) >> 8` for A and B.

**No clipping in either path**: sums outside −128…127 wrap. With 5 voices at full volume this can overflow
*(data-dependent; not measured)*.

Idle test: a voice is silent when `cur == end` and `loop == end`; at `cur == end` with a loop, `cur = loop`.

---

## 8. Fades and pause

* **`sndFadeOut(n)`**: frames = 8n; step = n ≥ 32 ? 1 per 8n/256 frames : ⌊32/n⌋ per frame (as MV). At the end it
  does **not** stop sounds. Instead:
  1. volume = 0 and the PSG/FIFO registers are reset (SOUNDCNT_X, SOUNDCNT_H `0x8802` → `0x210E`); TM0 is stopped.
  2. Every track that is active or paused becomes **paused** (flags = 0x80).
  3. The queue is cleared and the master word is set to `0xFF` (volume 0xFF, no fade).
* **`sndFadeIn(n)`**:
  1. volume = 0; fade-in frames = 8n (stored as u16, **read as u8**, so n ≥ 32 wraps; n = 32 would leave the volume at
     0). Constant arguments at the call sites are 1–4.
  2. NR50 = 0.
  3. Paused or active tracks get flags = 1. TM0 is started.
  4. **Id 0x36 is queued.**

  Each tick: volume += step (max 0xFF), NR50 = `(volume >> 5)·0x11`, and PCM voice volumes are updated. When it
  finishes, volume = 0xFF and NR50 = 0x77.
* **`E3`** performs the same resume from inside a sequence (64 frames, step 4). It writes the queue index with `& 7`
  instead of `& 0xF` (a bug; harmless while the write index is below 8).

---

## 9. Hardware setup (`sndInit`)

| Register | Value |
|---|---|
| `SOUNDCNT_X` | `0` → `0x8F` |
| `SOUNDCNT_H` | `0x8802` (FIFO reset) → **`0x210E`**: PSG 100 %, A/B 100 %, **A → right only, B → left only, both timer 0** |
| `SOUNDCNT_L` | `0x77` (shadowed) |
| DMA1 | SAD `0x03002E6C`, DAD `FIFO_A`; DMA2 SAD `0x03002E7C`, DAD `FIFO_B`; CNT_H 0 until the first PCM note |
| Timer 0 | Reload `0xFC00` (16 384 Hz); started by the first PCM note-on (`0x80`) or a fade-in |
| State | 14 tracks cleared, queue cleared, `0x03002E0C`–`0x03002EEB` cleared, master volume 0xFF |

At a PCM note-on, if DMA1 is not enabled, the driver clears both mix buffers, reprograms DMA1/2, enables the DMA IRQs
and starts the DMAs.

---

## 10. Quirks

* PCM track end: the driver stops TM0 and DMA1/2 when `(voice0.cur | voice1.cur) & 0xFF == 0`. This is meant as
  "both idle", but it only tests the low byte, so a 256-aligned current pointer also counts as idle.
* The PCM note clamp only catches n ≥ 64. Notes 49–63 index past a 12/13-entry instrument table (unused in SoM).
* `E3` queue write mask `& 7` (see §8). The fade-in frame count is truncated to u8.
* The PSG note-on writes CNT_X twice (harmless).
* Neither mixer clips (wraps on overflow).
* Slot 13 exists in RAM (cleared, voice 5) but is never updated or mixed.

---

## 11. Disassembly source

Folder `…/Brownie/som_asm/`:

| File | Content |
|---|---|
| `som_sound.s` | Driver block `0x080A0510`–`0x080A2997` and veneer island. Both mixer paths, the glue, all tables (length 24 × 16, 160 envelopes with script data) and the sequencer. Named functions with pseudo-C headers; symbolic Track / Voice / Master / I-O offsets; literal pool labelled by content |
| `som_sound.inc` | `.equ` for I/O, IWRAM state, outside ROM tables, Track / Voice / Master offsets |
| `som_sound.ld` | `.text.som_sound` at `0x080A0510`, `.text.som_veneer` at `0x0836D8A4` |
| `som_sound.mk` | `make -f som_sound.mk` (default `ROM="../Sword of Mana (E).gba"`) |
| `som_compare.py` | Result: 9 352 bytes and 56 bytes, 0 differences |

The mixer functions are assembled at their ROM addresses. They use only PC-relative literals and branches, so the same
bytes are valid at their IWRAM addresses (`IW_sndMixIrq` / `IW_sndMixFull` in the `.inc`).

---

## 12. Notes for the MIDI converter

* **Clock:** 1 tick = 1 frame. Tempo is per track. For rows 0–7, quarter = 32 + 4·row frames. For other rows, follow
  the actual frame lengths.
* **PSG:** as MV, with +66 cents (pitch bend ≈ +0.66 semitone, or retune).
* **PCM:** program = instrument (`E1`), note → MIDI `K + n − 36` (§5.2). Export each instrument as a 12/13-zone
  multisample at 16 384 Hz, zone k = MIDI K + k. Octaves below are the same zones played 1–3 octaves down.
* **Volume and pan:** `EA` lo/hi → stereo volume (CC7 = max, CC10 from the ratio; A = right, B = left). `F2` → CC7.
* **Envelopes:** `E0` envelope jumps → CC11 automation or a new note velocity.
* **Ignore for BGM:** `E2` mix mode, `E3` resume and `E8`/`E9` muting are engine control.

Song table, instruments, waves, length rows and envelopes are in `brownie-som-data-dump.md`.
