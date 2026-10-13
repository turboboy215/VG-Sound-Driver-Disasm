# Webfoot sound engine — GBA
## Reverse-engineering report and technical reference

*Covers three builds of the same engine: Dragon Ball Z: The Legacy of Goku (v1), Dragon Ball Z: The Legacy
of Goku II (v2) and Hello Kitty: Happy Party Pals (v2.1). The ROMs carry no symbols, so every function,
variable and field name below is invented. Where a statement is an inference rather than a direct read of
the code it is marked* (inferred).

**Subject files** (`…/GBAAudioLab/WF/`)

| File | Game | Header | Engine build |
|---|---|---|---|
| `Dragon Ball Z - The Legacy of Goku (E) (M5).gba` | The Legacy of Goku (2002) | `DRAGONBALL Z` / `ALGP` | v1 |
| `Dragon Ball Z - The Legacy of Goku II (E) (M5).gba` | The Legacy of Goku II (2003) | `DRAGONBALL Z` / `ALFP` | v2 |
| `Hello Kitty - Happy Party Pals (E).gba` | Happy Party Pals | `HELLOKITTY` / `B86P` | v2.1 |

**Provenance.** All three games credit Webfoot Technologies (`(C)2003 Webfoot Technologies, Inc.` in LoG2),
and the sound code sits in the middle of each game's own code with no third-party strings, no version tag
and no separate library layout, so it is Webfoot's in-house engine (inferred, but nothing points the other
way). It is compiled C in v1 and object-style C/C++ in v2, built with the ARM toolchain (armcc-style `__call_via_rN` and
`__rt_udiv` helpers, `push {r3, lr}` stack alignment), plus a few hand-written ARM loops.

---

## 1. Executive summary

The engine is a **software-mixing tracker player** in the Amiga/PC tradition, not a register-driving
driver and not a MIDI-style sequencer:

* **All sound is PCM.** The PSG channels are never used. Up to **31 voices** — 15 music channels and 16
  sound-effect voices — are resampled (nearest-sample, 18.14 fixed point), volume-scaled, panned and summed
  by the CPU into a 32-bit stereo mix buffer, then clipped to 8 bits and played as **true stereo**:
  DirectSound A = left, B = right, both on Timer 0.
* **Mix rate:** 14 000 Hz nominal in v1 (passed to `Snd_Init`; the timer actually runs at 13 981 Hz);
  fixed 16 kHz nominal (15 978 Hz actual) in v2/v2.1.
* **Music is a converted tracker module.** A song is an order list plus packed patterns of variable length
  (2–176 rows), up to 15 channels, S3M/IT effect letters (A, B, D, E, F, G, H, K, L, O, Q, T, U, X and note
  delay), volumes 0–64, signed panning, and IT-style notes where note 60 (C-5) plays a sample at its own
  rate. Rows are compressed with a per-game **14-entry mask dictionary** chosen by the converter: 87 % of all
  channel events in the three games use it.
* **Timing is sample-accurate.** The player does not run once per video frame. While mixing, it splits each
  chunk wherever a tick falls (`samples per tick = 2.5 · rate / BPM`), so tempo is exact at any BPM.
* **Mixing is demand-driven.** `Snd_Mix` is called from the game's main loop; a DMA2 (v1/v2) or Timer 1
  (v2.1) interrupt counts playback position and, if the ring buffer is about to run dry, calls `Snd_Mix`
  itself with interrupts re-enabled. Output goes through two 1024-byte rings (about 64–73 ms of buffering).
* **Sound effects** are plain one-voice sample plays into a 16-voice pool: first free voice, no priorities,
  no stealing, nothing played if all 16 are busy.

Version 2 is a rewrite of v1 as objects (one `Snd` object containing a `Player` with embedded channel
voices and a voice pool) with a faster single-routine packed-stereo mixer; v2.1 changes the interrupt
scheme and replaces DMA copies by `memcpy`. The music data format is the same in all three apart from the
song header growing from 12 to 20 bytes.

---

## 2. Where everything is

### 2.1 Code and constant ranges

| Piece | v1 — LoG1 | v2 — LoG2 | v2.1 — Hello Kitty |
|---|---|---|---|
| ARM mixer + IRQ handler | ROM `080089EC–08008D4C` (copied to IWRAM `03003D44` by `Snd_Init`; IRQ handler is Thumb, runs from ROM) | ROM `087D744C–087D7750` = IWRAM `03000520–03000824` (part of the crt0 RW image at ROM `087D6F2C`) | ROM `0837E6B0–0837E9B4` = IWRAM `03000828–03000B2C` (crt0 RW image at `0837DE88`) |
| Pattern player | `08009CCC–0800A910` | `080202D0–08020FA4` | `08028334–08029008` |
| Voices / mixer front end / SFX | `0800A9F4–0800B0BC` | `0801FE84–080202D0` | `08027F04–08028334` |
| Sound object (init, mix, pause) | (in the range above) | `08020FA4–080211D4` | `08029008–080292B8` |
| Constant tables | `080113A8–08011AE0`, `FxTab` at `0818CDF8`, `RowMaskTab` at `08142518` | `087D61A8–087D6968` | `0837CD40–0837D500` |
| Music + SFX data | `0856A7D4–085E708C` (510 136 B) | `08313D10–084B8958` (1 723 464 B) | `08035EA4–081439C8` (1 104 676 B) |

Every one of these ranges is rebuilt byte-identically from the delivered sources (§13).

The constant tables are identical in all three games (§7.6); only the row-mask dictionary differs.

### 2.2 Layout of the data block

The converter emits one contiguous block per game, in this order:

```
v1  songs (orders, patterns, pattern tables) | music samples | instrument table | song table
    | sfx samples | sfx table
v2  music samples | instrument table | mask dictionary | songs | song table | sfx samples | sfx table
v2.1  sfx-A samples | sfx-B samples | sfx-A table | sfx-B table | music samples | instrument table
    | mask dictionary | songs | song table
```

Everything is packed: samples start at any byte address, patterns follow one another without padding,
and only the 32-bit tables are word-aligned (1–3 padding bytes before them). In v1 the mask dictionary is
not in the data block but beside the code's constants.

---

## 3. Public API

The game uses only a handful of entry points; the rest are internal. v1 uses globals; v2 passes the
object in `r0`.

```c
/* v1 (LoG1) */
void  Snd_Init(int rate);                 /* game passes 14000 */
void  Snd_Mix(void);                      /* call often (main loop); also called from the IRQ */
void  Snd_Pause(void), Snd_Resume(void), Snd_Shutdown(void);
void  Snd_SetMusicVolume(int bus), Snd_SetSfxVolume(int bus);   /* defaults 4 and 8 */
void  Mus_PlaySong(const Song *s), Mus_PlaySongIfNew(const Song *s), Mus_Stop(void);
Voice*Sfx_Play(int n);                    /* = Sfx_PlaySample(&SfxTab[n], 64, 0) */
Voice*Sfx_PlaySample(const SampleHdr *h, int vol, int pan);
void  Sfx_StopAll(void);  int Sfx_CountActive(void);
void  Sfx_Suspend(Voice save[16]), Sfx_Restore(const Voice save[16]);

/* v2 / v2.1 (LoG2, Hello Kitty): Snd snd; Player = &snd+0x0C; Pool = &snd+0x5C4 */
void  Snd_Init(Snd*), Snd_Mix(Snd*), Snd_Shutdown(void), Snd_Pause(void), Snd_Resume(void), Snd_Kill(void);
void  Player_PlaySong(Player*, const Song*), Player_SetVolume(Player*, int bus),
      Player_SetTempo(Player*, int bpm), Player_SkipPattern(Player*);
Voice*Pool_Play(Voice pool[16], const SampleHdr *h, int vol, int pan);
void  Pool_StopAll(Voice*), Pool_StopSample(Voice*, const SampleHdr*),
      Pool_StopMatch(Voice*, const SampleHdr*, int vol, int pan), Pool_AddVoice(Voice*, const Voice*),
      Pool_SetVolume(Voice*, int bus), Pool_Clear(Voice*);
int   Pool_CountActive(Voice*);
Voice*Pool_Suspend(Voice*);  void Pool_Restore(Voice*, Voice *saved);
```

`vol` is 0–64, `pan` is −64 (left) … +64 (right). v2 has no stop or play-if-new function; the game reads
the player itself before starting a song (`if (!(player->playing == 1 && player->song == s)) Player_PlaySong(...)`).

**Host obligations** (read from the game code around the calls):

1. The game's ARM IRQ dispatcher calls table entry *n* for IRQ bit *n* and supplies the return
   conventions the handlers rely on (v1: `r6` = ARM return; v2: `r3` = `&REG_IE`, `r4` = ARM return,
   `lr` = Thumb return stub). `Snd_Init` installs its own handler in that table and enables the IRQ bit.
2. Call `Snd_Mix` regularly (all three games call it once per main-loop pass); the interrupt path only
   guards against underruns.
3. Use `Pause`/`Resume` around anything that stops the CPU for long (both wait for the next sound IRQ
   before stopping Timer 0, so the DMA is never stopped mid-burst).

Complete address table of every function in the three builds:

| v1 name | v2 name (if renamed) | LoG1 | LoG2 | Hello Kitty |
|---|---|---|---|---|
| Mix_Side | Mix_Voice | 080089EC | 03000520 | 03000828 |
| Mix_Centre | — | 08008A94 | — | — |
| Mix_Stereo | — | 08008B68 | — | — |
| Mix_Output | = | 08008C2C | 03000704 | 03000A0C |
| Mix_Null | = | 08008CC0 | 0801FE84 | 08027F04 |
| Snd_Dma2Irq | = / Snd_Timer1Irq | 08008CC2 | 03000798 | 03000AA0 |
| Snd_IrqCallMix | — | 08008D0C | — | — |
| Fx_None | = | 08009CCC | 080202D0 | 08028334 |
| Fx_A_SetSpeed | = | 08009D4E | 08020360 | 080283C4 |
| Fx_B_PositionJump | = | 08009D60 | 08020376 | 080283DA |
| Tick_VolSlideDown / Up | = | 08009D7E / 08009DAA | 08020398 / 080203C6 | 080283FC / 0802842A |
| Fx_D_VolumeSlide | = | 08009DD6 | 080203F4 | 08028458 |
| Tick_PortaDown, Fx_E_PortaDown | = | 08009E52, 08009E70 | 08020478, 08020496 | 080284DC, 080284FA |
| Tick_PortaUp, Fx_F_PortaUp | = | 08009EE0, 08009EFE | 08020506, 08020524 | 0802856A, 08028588 |
| Tick_TonePortaDown / Up | = | 08009F6E / 08009FAC | 080205B0 / 080205F2 | 08028614 / 08028656 |
| Fx_G_TonePorta | = | 08009FEA | 08020634 | 08028698 |
| Tick_Vibrato, Fx_H_Vibrato | = | 0800A05C, 0800A0A0 | 080206A8, 080206F0 | 0802870C, 08028754 |
| Tick_VibratoVolDown / Up | = | 0800A12A / 0800A158 | 08020740 / 0802076A | 080287A4 / 080287CE |
| Fx_K_VibratoVolSlide | = | 0800A186 | 08020794 | 080287F8 |
| Fx_L_TonePortaVolSlide | = | 0800A21C | 08020858 | 080288BC |
| Fx_O_SampleOffset | = | 0800A318 | 08020958 | 080289BC |
| Tick_Retrig, Fx_Q_Retrig | = | 0800A33E, 0800A362 | 08020984, 080209B0 | 080289E8, 08028A14 |
| Tick_NoteDelay, Fx_NoteDelay | = | 0800A390, 0800A3A4 | 080209E4, 080209FC | 08028A48, 08028A60 |
| Fx_T_SetTempo | = | 0800A3BA | 08020A28 | 08028A8C |
| Fx_U_FineVibrato | = | 0800A3CC | 08020A46 | 08028AAA |
| Fx_X_SetPanning | = | 0800A40E | 08020A92 | 08028AF6 |
| Tick_TonePortaUpVolUp | = | 0800A42E | 08020AB2 | 08028B16 |
| Tick_TonePortaDownVolUp | = | 0800A49A | 08020B16 | 08028B7A |
| Tick_TonePortaUpVolDown | = | 0800A538 | 08020BA8 | 08028C0C |
| Tick_TonePortaDownVolDown | = | 0800A5A4 | 08020C0C | 08028C70 |
| Fx_Empty1 … 11 (unreferenced `bx lr`) | = | 0800A126 … 0800A42C | 0802073C … 08020AB0 | 080287A0 … 08028B14 |
| Mus_SetTempo | Player_SetTempo | 0800A620 | 08020A16 | 08028A7A |
| Mus_ChannelTick | Player_ChannelTick | 0800A638 | 08020CB4 | 08028D18 |
| Mus_ChannelRow | Player_ChannelRow | 0800A652 | 08020C70 | 08028CD4 |
| Mus_ReadRow | Player_ReadRow | 0800A692 | 08020CD0 | 08028D34 |
| Mus_Tick | Player_Tick | 0800A772 | 08020DBC | 08028E20 |
| Mus_MixVoices | Player_MixVoices | 0800A7DC (never called) | 08020E44 | 08028EA8 |
| Mus_Render | Player_Render | 0800A7FA | 08020E68 | 08028ECC |
| Mus_Stop | (inlined by the game) | 0800A864 | — | — |
| Mus_ResetChannels | Player_ResetChannels | 0800A86C | 08020ED2 | 08028F36 |
| Mus_PlaySong | Player_PlaySong | 0800A8A2 | 08020EFC | 08028F60 |
| Mus_PlaySongIfNew | (inlined by the game) | 0800A8D8 | — | — |
| — | Player_SkipPattern | — | 08020F46 | 08028FAA |
| Snd_SetMusicVolume | Player_SetVolume | 0800AC78 | 08020F78 | 08028FDC |
| Voice_Update | = | 0800A9F4 | 0801FE86 | 08027F06 |
| Voice_Mix | = | 0800AABA | 0801FF22 | 08027FA2 |
| Voice_Start | = | 0800AC38 | 080200A6 | 08028126 |
| Snd_SetSfxVolume | Pool_SetVolume | 0800AC4E | 08020206 | 0802827A |
| Sfx_StopAll | Pool_StopAll | 0800AF9A | 080200BC | 0802813C |
| — | Pool_StopSample, Pool_StopMatch | — | 080200D2, 080200FE | 08028152, 0802817C |
| Sfx_PlaySample | Pool_Play | 0800AFB2 | 0802014C | 080281C8 |
| Sfx_Play | (game indexes the table itself) | 0800AFE6 | — | — |
| — | Pool_AddVoice | — | 0802017C | 080281F8 |
| Sfx_CountActive | Pool_CountActive | 0800B022 | 080201A6 | 0802821A |
| — | Pool_Clear, Pool_UpdateAll, Pool_MixAll | — | 080201C0, 080201D2, 080201E8 | 08028234, 08028246, 0802825C |
| Sfx_Suspend, Sfx_Restore | Pool_Suspend, Pool_Restore | 0800B03C, 0800B064 | 08020228, 08020280 | 0802829C, 080282F0 |
| Snd_Init | = | 0800ACA2 | 08020FA4 | 08029008 |
| Snd_Shutdown | = | 0800ADE8 | 0802103C | 080290A0 |
| — | Snd_Kill | — | 0802105C | 080290B6 |
| Snd_Pause, Snd_Resume | = | 0800ADCE, 0800ADE0 | 0802106A, 08021080 | 080290C4, 080290D8 |
| Snd_Mix | = | 0800AE0C | 08021088 | 080290E0 |

---

## 4. Hardware use and the output stage

### 4.1 Resources

| Resource | Use |
|---|---|
| `REG_SOUNDCNT_H = 0x9A0E` | DirectSound A and B at 100 %, A → left only, B → right only, both on Timer 0; FIFO resets. PSG mix ratio bits are set but no PSG channel is ever started. |
| `REG_SOUNDCNT_X = 0x80`, `REG_SOUNDCNT_L = 0` | master enable, PSG off |
| Timer 0 | sample clock. v1: reload `-1200` (`= -(K+3)>>2` with `K = ceil(2^26/14000) = 4794`) → 13 981 Hz. v2/v2.1: reload `0xFBE6` = −1050 → 15 978 Hz |
| DMA1 | left ring → FIFO A (`0xB660`: enable, FIFO timing, 32-bit, repeat) |
| DMA2 | right ring → FIFO B; v1/v2 with the IRQ bit (`0xF660`), v2.1 without (`0xB660`) |
| Timer 1 (v2.1 only) | cascaded on Timer 0, reload −64, IRQ: one interrupt per 64 samples |
| DMA3 | v1/v2 only: clearing sound RAM, copying voice blocks (v2.1 uses `memset`/`memcpy`) |

`REG_SOUNDBIAS` is not touched.

### 4.2 Ring buffers

| | v1 | v2 | v2.1 |
|---|---|---|---|
| Left ring | `0203F800`, 1024 B | `02000000`, 1024 B | `02000000`, 1024 + 64 B guard |
| Right ring | `0203FC00`, 1024 B | `02000400`, 1024 B | `02000440`, 1024 + 64 B guard |
| IRQ | DMA2, every 16 samples | DMA2, every 16 samples | Timer 1, every 64 samples |
| Refill trigger | 128 samples left | 96 samples left | 128 samples left |

The two DMAs are deliberately **half a turn out of phase**: DMA1 starts at the beginning of the left ring,
DMA2 at the *middle* of the right ring. The IRQ handler re-arms one DMA every 512 samples — DMA2 when
`playpos` reaches 512, DMA1 (and `playpos` wraps to 0) at 1024 — so the two restarts never happen in the
same interrupt. Everything that writes the right ring therefore offsets the index by 512 (the `ring_R_512`
constants in the sources).

In v2.1 the interrupt only arrives every 64 samples, so a DMA can run up to 64 samples past the end of its
ring before it is re-armed; `Snd_Mix` copies the first 68 bytes of each ring behind its end after every
refill so that overrun replays the right data.

### 4.3 The interrupt path

```
IRQ (DMA2 or Timer 1)
  playpos += 16 (64 in v2.1)
  every 512 samples: re-arm DMA2 / DMA1 (count 4, control 0xF640 / 0xB640)
  if ((writepos - playpos) & 1023) == threshold  and  !snd.busy:
        enable IRQs (clear CPSR.I)  ->  Snd_Mix()      ; returns through the dispatcher
```

The DMA re-arm writes control `0xF640` for *both* channels in v1/v2, so after the first wrap DMA1 also
requests interrupts; only the DMA2 bit is enabled in `REG_IE`, so the extra request is ignored.

### 4.4 `Snd_Mix`

```
busy = 1
n = (playpos - writepos) & 1023              ; free space
if n > 64 (v1) / n >= 64 (v2):
    writepos = playpos
    update the 16 sfx voices (dirty flags)
    while n:
        chunk = min(n, 256 (v1) / 512 (v2))
        Mus_Render / Player_Render(chunk)     ; music, ticks applied mid-chunk
        mix the 16 sfx voices (chunk)
        Mix_Output(ringL + w, ringR + (w+512)&1023, mixbuf, ...)   ; split at 1024 and at 512
        w = (w + chunk) & 1023;  n -= chunk
busy = 0
```

All three games call `Snd_Mix` once per main-loop pass (LoG1 just before waiting for V-Blank), so a refill
normally mixes one frame's worth, about 230–270 samples. The interrupt path only fires when a frame runs
long, and then refills up to ~900 samples at once.

---

## 5. Voices and the mixer

### 5.1 The voice

A voice is 64 bytes (layout in the source headers). The important fields: an 18.14 fixed-point byte
position, a signed step, the sample pointer, loop start/end (18.14), the sample's own rate, a pitch factor
(16384 = native), volume 0–64, pan −64…+64, a **bus volume** (music or sfx master), the selected mix routine
and a byte of dirty flags:

| flag | meaning (handled by `Voice_Update`) |
|---|---|
| 0x01 | active |
| 0x02 | recompute the step |
| 0x04 | restart at position 0, direction forward |
| 0x08 | reload data pointer, loop points, loop type and rate from the sample header |
| 0x10 | recompute the two output volumes and choose the mix routine |

`Voice_Start` sets `0x1F`. The next byte is the loop state: bit 0 looped, bit 1 ping-pong, bit 2 running
backwards.

### 5.2 Volume, panning, pitch

```
volL = bus * vol * (64 - pan) >> 10
volR = bus * vol * (64 + pan) >> 10          ; linear pan, at most 64 each with bus 8
step = ((pitch * rate >> 14) * K + 0x7FF) >> 12       ; 18.14 fixed point
       K = ceil(2^26 / mixrate)   (v1: computed from the rate argument; v2: constant 0x1063 = 4195)
     = pitch/16384 * rate/mixrate   (bytes of sample per output sample)
```

Neither K matches the real timer rate exactly: v1 plays about 0.13 % flat (K is for 14 000 Hz, the
timer gives 13 981 Hz) and v2 about 0.12 % sharp (K for 16 000 Hz vs 15 978 Hz) — about 2 cents either way.

### 5.3 Inner loops

**v1** picks one of three ARM routines (all copied to IWRAM at start-up) by comparing the two volumes:

| case | routine | per sample |
|---|---|---|
| both 0 | `Mix_Null` | nothing (the position still advances) |
| one side 0 | `Mix_Side` | `buf[2i+side] += s * vol` (one `mla`) |
| equal | `Mix_Centre` | `buf[2i] += s*v; buf[2i+1] += s*v` (one `mul`, two adds) |
| different | `Mix_Stereo` | two `mla` |

The mix buffer is 256 frames of interleaved signed 32-bit L/R. `Mix_Null` is a bare `bx lr`; `Voice_Mix`
updates the position arithmetically after every call, so a silent voice keeps its place.

**v2** has one routine, `Mix_Voice`: the two volumes are stored as adjacent halfwords and loaded as one
word, so `buf[i] += s * (volL | volR << 16)` mixes both channels with a single multiply-accumulate into a
**packed** 32-bit buffer (512 entries, left in the low half). `Mix_Output` recovers the left sum from the
low 16 bits and the right sum as `word >> 22`, so a negative left sum borrowing from the high half shifts
the right output by at most one step. The left half only wraps once its sum passes ±32767 — four times the
level at which the output already clips (±8128) — so the trick holds for any sensible mix. The loop is
unrolled 8×, and a separate loop handles steps below 1.0 by advancing the pointer with conditional
pre-indexed loads (`ldrsbhs r0, [r3, #1]!`) instead of an add-with-carry.

**Output.** `Mix_Output` shifts each sum right by 6, clamps to −128…127, writes the two rings two bytes at a
time and clears the mix buffer behind itself. One voice at volume 64 on the sfx bus (8) reaches full scale
on its own; the music bus default (4) gives each music voice half that.

### 5.4 Loops and the end of a sample

`Voice_Mix` mixes in segments: it computes where the voice will be after `n` samples, and if that crosses
the loop end (or the start, when running backwards) it uses SWI 6 (`Div`) to find how many samples fit,
mixes those, folds the position and continues.

* **one-shot:** at the end the voice is switched off and its music channel's "note sounding" flag cleared
  (so tick effects of mode 1 stop too);
* **forward loop:** `pos -= loop_end - loop_start`;
* **ping-pong:** at the end the position is mirrored, `pos' = 2*end - p` (v2: `2*end - 1 - p`, so it can
  never land exactly on the end and read the byte after the loop), and the step is negated. At the start
  v2 mirrors correctly, `pos' = 2*start - p`. **v1 gets the sign wrong there** (see §11.4): with `p = pos -
  k·step` it computes `2*start - pos - k·step` instead of `2*start - pos + k·step`, so after every backward
  bounce the voice lands below the loop start by roughly twice the distance it covered in that mixing
  segment (hundreds of bytes at ordinary pitches) and plays forward from there.

The loop end is also the sample length: in all three games every looped sample loops to its last byte.

---

## 6. The music player

### 6.1 Timing

`samples_per_tick = 2.5 · rate / tempo` (v1: `(rate*2 + rate/2) / tempo`; v2: `40000 / tempo`), the usual
tracker definition (a tick is 2.5/BPM seconds). `Mus_Render` mixes the music voices up to the next tick
boundary, runs a tick, and carries on; the remainder is kept in `samples_left` across chunks, so ticks fall
on exact sample positions independent of the frame rate.

A tick (`Mus_Tick` / `Player_Tick`):

```
if --tick == 0:                    ; first tick of a row
    Mus_ReadRow()                  ; may advance the order list
    for each of 15 channels: Mus_ChannelRow(ch)     ; row effects
    tick = speed
else:
    for each channel: Mus_ChannelTick(ch)           ; tick handlers
for each channel voice: Voice_Update(voice)
```

### 6.2 Channels

Fifteen channels, each tied to one voice. Per channel: pitch factor, tone-portamento target, volume,
pan, effect memories (D, shared E/F/G, Q), vibrato speed/depth/phase, a counter, a **tick handler
pointer** and a 2-bit **tick mode**, and the last note/instrument/volume/effect/parameter read for it.

* `Mus_ChannelRow` clears the tick mode, restores the voice pitch from the channel pitch (undoing
  vibrato), then calls `FxTab[effect]` — effect 0 if the event has no effect byte. For a channel with no
  event in the row only the first two steps happen, so any slide or vibrato ends at the row boundary, as
  in any tracker.
* `Mus_ChannelTick` calls the tick handler when the mode is 1 and the note is still sounding, or when the
  mode is 2 (retrigger and note delay, which must run after the note ended).

Every row-effect handler except G, L and note delay begins by calling `Fx_None`, which plays the row's
note: pitch from `NoteFreqTab[note]`, volume = the channel's volume byte, voice restarted; with an
instrument reload (`flags 0x1F`) unless the event marks the instrument as "repeated" (mask bit 0x20), in
which case the sample header is not reloaded (`0x17`). Note 255 is note-off: the voice simply stops (no
release phase). There is no per-sample default volume — the converter always supplies a volume.

### 6.3 Effects

`FxTab` has 32 entries; numbering follows the S3M/IT letters (A = 1 … Z = 26), plus 27 for note delay.

| # | letter | behaviour |
|---|---|---|
| 1 | Axx | ticks per row = xx |
| 2 | Bxx | jump to order xx after this row |
| 4 | Dxy | volume slide (ST3 rules): Dx0 up, D0y down per tick (DF0/D0F also on the first tick), DxF fine up, DFy fine down; D00 = memory |
| 5 | Exx | portamento down xx/16 semitone per tick; EFx fine (x/16 once), EEx extra fine (x/64 once); shared E/F/G memory |
| 6 | Fxx | portamento up, same encoding |
| 7 | Gxx | tone portamento: the row's note becomes the target. Does nothing on a silent channel |
| 8 | Hxy | vibrato, speed x, depth y×4 (in 1/64-semitone units: ±y/16 semitone) |
| 11 | Kxy | vibrato + volume slide |
| 12 | Lxy | tone portamento + volume slide (tick handler from a 2×3 table) |
| 15 | Oxx | sample offset xx·256 |
| 17 | Qxy | retrigger every y ticks; x (volume change) ignored |
| 20 | Txx | tempo xx BPM |
| 21 | Uxy | fine vibrato (depth y, 4× finer than H) |
| 24 | Xxx | panning, signed −64…+64 |
| 27 | — | note delay xx ticks (the converter's SDx) |
| other | C, I, J, M, N, P, R, S, V, W, Y, Z | treated as effect 0 (note only) |

Pattern break (C) is not implemented; the songs only use B. Effects actually used by the three games are
counted in the data dumps (X and D dominate; LoG1 and Hello Kitty never use A).

### 6.4 Pitch arithmetic

All pitch work is multiplicative on the pitch factor, using exact equal-tempered tables:

| table | entries | value | use |
|---|---|---|---|
| `NoteFreqTab` | 120 × u32 | `512 · 2^(n/12)` | note → pitch; note 60 = 16384 = native rate |
| `PortaUpTab` | 256 × u16 | `16384 · 2^(i/192)` | slide up i/16 semitone: `(p·t) >> 14` |
| `PortaDownTab` | 256 × u16 | `65536 · 2^(−i/192)` (65535 for i = 0) | slide down: `(p·t) >> 16` |
| `PortaFineUpTab` | 64 × u16 | `32768 · 2^(i/768)` | extra-fine up, vibrato: `>> 15` |
| `PortaFineDownTab` | 64 × u16 | `65536 · 2^(−i/768)` | extra-fine down, vibrato: `>> 16` |
| `VibratoSine` | 64 × s8 | `64 · sin(2πi/64)` | vibrato waveform |

Vibrato does not change the channel's pitch; it writes `pitch · fine(offset)` to the voice each tick and
`Mus_ChannelRow` puts the plain pitch back on the next row.

---

## 7. Data formats

### 7.1 Sample header (12 bytes)

```
+0  u32  data          8-bit signed PCM, any byte address
+4  u8   loop type     0 one-shot, 1 forward, 3 ping-pong
+5  u8   0
+6  u16  loop start    bytes
+8  u16  loop end      bytes; also the length (every sample ends at its loop end)
+A  u16  rate          Hz at the reference note 60
```

The same header is used for music instruments and for sound effects. Lengths are 16-bit, so no sample can
exceed 65 535 bytes.

### 7.2 Song

```
v1 (12 bytes)                         v2 (20 bytes)
+0  u32 pattern table                 +0  u32 pattern table
+4  u32 order list                    +4  u32 order list
+8  u8  tempo (BPM)                   +8  u32 instrument table (sample headers)
+9  u8  speed (ticks/row)             +C  u32 row-mask dictionary (14 bytes)
+A  u16 0                             +10 u8 tempo   +11 u8 speed   +12 u16 0
```

In v1 the instrument table and mask dictionary are global (`wf1_MusInstrTab`, `RowMaskTab`); in v2 they
are per song, although every song of a game points at the same two.

### 7.3 Order list

Bytes, each a pattern number, terminated by `0xFF`. Reaching the terminator wraps to order 0: **every song
loops**; there is no end-of-song event.

### 7.4 Pattern

```
u8  rows                       (2 … 176 in the shipped data)
rows x { event* 0x00 }
event:
  u8  ctrl      low nibble  = channel + 1 (1..15)
                high nibble = 0      mask byte follows (and becomes the channel's "last mask")
                              1      reuse the channel's last mask
                              2..15  mask = dictionary[high - 2]
  [u8 mask]
  [u8 note]      if mask & 0x01   (0..119, 255 = note off)
  [u8 instr]     if mask & 0x02
  [u8 volume]    if mask & 0x04   (0..64)
  [u8 fx, u8 param]  if mask & 0x08
```

Mask bits 0x10/0x20/0x40/0x80 mean "note / instrument / volume / effect present, same value as this
channel's previous event" — no byte is read, the channel's stored value is used. So `0x11` and `0x10`
both trigger a note, `0x88` and `0x80` both run an effect. A channel without an event in a row runs no
effect at all (its slides stop, §6.2).

The dictionary is chosen per game by the converter (the 14 most useful masks, presumably the most
frequent — inferred):

```
LoG1  61 80 04 70 40 08 07 16 34 25 F0 E1 C0 78
LoG2  04 61 80 70 08 25 69 40 07 0F 34 2D E1 0C
HK    04 61 25 07 16 70 84 40 34 69 78 52 0F 80
```

### 7.5 What the converter's input was (inferred)

Pattern lengths other than 64 (2 … 176 rows), note numbering in which C-5 plays a sample at its own rate,
S3M/IT effect letters with an SDx-style note delay, a per-sample "C-5 speed" and ping-pong loops all match
**Impulse Tracker (.it)** modules better than S3M (fixed 64 rows, no ping-pong) or XM (different effect
letters). The converter flattened instruments to samples and the IT volume column to a plain 0–64 volume.

### 7.6 Constant tables

`NoteFreqTab`, the four portamento tables, `VibratoSine`, `FxTab` and the 6-entry L-effect handler table are
byte-identical in the three games apart from the code addresses inside the pointer tables. v2 adds two
constant pointers beside them: `p_player` (the player object, used by effect handlers to reach the
current song) and `p_intrmgr` (the game's interrupt-manager object).

---

## 8. Sound effects

* **v1:** `Sfx_Play(n)` plays `SfxTab[n]` at volume 64, centre, in the first free of the 16 sfx voices and
  returns the voice (or 0). `Sfx_PlaySample(h, vol, pan)` does the same for any header.
  `Sfx_Suspend`/`Sfx_Restore` save and restore all 16 voices (DMA3, 1 KB) and stop them in between.
* **v2/v2.1:** a 16-voice pool. The game computes `&SfxTab[n]` itself and calls `Pool_Play(pool, h, vol,
  pan)`; it can stop by sample (`Pool_StopSample`) or by exact sample/volume/pan (`Pool_StopMatch`).
  `Pool_Suspend` now moves only **looping** voices to a heap copy (one-shots finish normally) and
  `Pool_Restore` puts them back in free slots and frees the copy.
* Hello Kitty has two banks: 17 common effects (table `080B07E4`, referenced throughout the game code) and
  67 more (table `080B08B0`, referenced once).

There is no priority or voice stealing anywhere: when all 16 voices are busy a new effect is silently
dropped. Effects never take music channels, and music never takes sfx voices.

---

## 9. RAM

### v1 (LoG1)

| address | size | contents |
|---|---|---|
| `03003CF8` | 20 | player state: playing, row, rows, tick, speed, tempo, order, samples/tick, samples left, song, pattern pointer |
| `03003D28` | 28 | mixer state: bus volumes, rate, chunk, play/write position, pitch constant K, busy, output routine |
| `03003D44` | 0x2D4 | IWRAM copies of the four ARM routines |
| `03004018` | 0x800 | mix buffer, 256 × (s32 L, s32 R) |
| `0203EE24` | 15 × 36 | channels |
| `0203F040` | 15 × 64 | music voices |
| `0203F400` | 16 × 64 | sfx voices |
| `0203F800` | 2 × 1024 | output rings |

### v2 / v2.1

| | LoG2 | Hello Kitty |
|---|---|---|
| `Snd` object (0x11C4 bytes) | `030026BC` | `03003258` |
| `Player` (= `Snd + 0x0C`, 0x5B8 bytes, 15 channels × 0x60) | `030026C8` | `03003264` |
| voice pool (`Snd + 0x5C4`, 16 × 64) | `03002C80` | `0300381C` |
| packed mix buffer (`Snd + 0x9C4`, 512 × u32) | `03003080` | `03003C1C` |
| rings | `02000000`, `02000400` | `02000000`, `02000440` |

The whole sound state lives in IWRAM in v2 (v1 kept channels and voices in EWRAM).

---

## 10. Version differences

| | v1 — LoG1 | v2 — LoG2 | v2.1 — Hello Kitty |
|---|---|---|---|
| language / style | C, globals | C++-style objects, `this` in r0 | same as v2 |
| mix rate | parameter (14 000 → 13 981 Hz) | fixed, 15 978 Hz | same |
| mix routines | 3 (side / centre / stereo), interleaved s32 | 1, packed L/R in one s32 | same |
| chunk size | 256 | 512 | 512 |
| ARM code | copied to IWRAM by `Snd_Init` | in the crt0 IWRAM image | same |
| interrupt | DMA2, Thumb handler from ROM | DMA2, ARM handler in IWRAM | Timer 1 every 64 samples, guard bytes behind the rings |
| refill threshold | 128 | 96 | 128 |
| channel/voice | separate arrays, linked by pointers | voice embedded in the channel | same |
| song header | 12 bytes, global instruments & dictionary | 20 bytes, per-song instruments & dictionary | same |
| Q retrigger | fires once per row | repeats every y ticks | same |
| ping-pong bounce | wrong sign at the loop start (jumps back), end can read 1 byte past | both fixed | both fixed |
| SFX API | `Sfx_Play(n)`; suspend all voices | pool object; suspend only looping voices | same; copies with `memcpy` |
| player helpers | `Mus_Stop`, `Mus_PlaySongIfNew` | inlined in the game | same |

Hello Kitty's player code is instruction-for-instruction the same as LoG2's; only the sound-object
methods (init, IRQ, `Snd_Mix`, pause/shutdown) and the DMA3 → `memcpy` change differ, so v2.1 is a small
platform revision rather than a new engine. Nothing in the music format changed between v2 and v2.1.

---

## 11. Bugs, quirks and dead code

1. **L effect slips to the wrong direction.** `Tick_TonePortaUpVolUp` and `Tick_TonePortaUpVolDown`, on
   reaching volume 64 / 0, install `Tick_TonePortaDown` instead of `…Up` as the remaining tick handler.
   Because the pitch is below the target, the down handler immediately clamps it, so the rest of an upward
   slide is replaced by a jump to the target note. Present in all three builds.
2. **v1 Q retriggers only once.** `Tick_Retrig` stores 4 into the channel flags (clearing the tick mode)
   instead of OR-ing it; fixed in v2.
3. **G on a silent channel does nothing.** `Fx_G_TonePorta` returns early if no note is sounding, without
   playing the row's note — a G with a note on an empty channel is silent (ST3 would play it).
4. **v1 ping-pong loops jump at the loop start.** In `Voice_Mix` the reflection off the loop start
   subtracts `k·step` where it should add it (`0800AB12`: `subs r0, r1, r0`; v2 `0801FF7A`: `adds`). The
   voice resumes forward play well before the loop start — for a loop starting at 0 (LoG1 sfx 18), before
   the start of the sample, reading the end of the previous sample. Every backward bounce of LoG1's three
   ping-pong instruments (0, 1, 18) and that sfx is affected; a small glitch rather than a hang, because
   forward play then runs back into the loop. v2 fixes it, and also mirrors the end bounce to `2*end-1-p`
   so the position can no longer land exactly on the end (which in v1 reads the byte past the loop).
5. **Unaligned interrupt-table store (v1).** `Snd_Init` writes the DMA2 handler through the literal
   `0x03003BAF` = `IntrTable + 0x2B`. ARM7 word stores ignore the low two address bits, so it lands on
   `IntrTable + 0x28` — the DMA2 slot — and works by accident.
6. **DMA1 IRQ bit.** The re-arm value `0xF640` enables the DMA1 interrupt request too (v1/v2); harmless
   because `REG_IE` only has DMA2.
7. **Clock mismatch:** pitch constants are for 14 000 / 16 000 Hz while the timers give 13 981 / 15 978 Hz
   (±2 cents, §5.2); tempo is likewise 0.1 % slow.
8. **Dead code:** eleven empty `bx lr` effect functions (the converter maps unsupported effects to 0, and
   `FxTab` points them at `Fx_None`); `Mus_MixVoices` in v1 is never called; channel byte `+1F`/`+5F` is
   cleared on reset and never read.
9. **No range checks:** song, instrument, sample and effect numbers are used as raw indices; effect numbers
   above 31 would index past `FxTab`.
10. **No sample volume, no envelopes, no fade-out.** Note-off cuts the voice immediately; volume comes only
    from the pattern. The music bus default of 4 (half the sfx bus) is the only master-level control.

---

## 12. Content inventory

| | LoG1 | LoG2 | Hello Kitty |
|---|---|---|---|
| songs | 18 | 44 | 27 |
| patterns | 282 | 696 | 176 |
| pattern bytes (songs total) | 120 120 | 564 670 | 89 762 |
| channels used (max) | 10 | 13 | 8 |
| music samples | 20 (197 964 B) | 101 (419 857 B) | 90 (510 190 B) |
| loops (one-shot/forward/ping-pong) | 11/6/3 | 26/66/9 | 61/25/4 |
| sound effects | 31 (191 223 B) | 64 (736 060 B) | 17 + 67 (61 447 + 440 632 B) |
| tempo range, speeds | 78–150 BPM, 3/6 | 65–140, 3/4/6 | 60–150, 3–8 |
| sample rates | 4 470–44 100 Hz | 3 915–23 977 Hz | 4 000–21 361 Hz |

LoG1's music test (the `Play Music` option) steps through songs 0–17; song 17 is also started directly by a screen
set-up routine at `08004F2C`. Full tables per game are in the data dumps.

---

## 13. Delivered files and rebuilding

Per game (`wf1` = LoG1, `wf2` = LoG2, `wf3` = Hello Kitty):

| file | contents |
|---|---|
| `wfN_sound.s` | all sound code (Thumb + ARM), commented, with RAM/struct layouts in the header |
| `wfN_rodata.s` | constant tables |
| `wfN_data.s` + `wfN_samples.bin` | songs, patterns (one row per line), sample tables; PCM via `.incbin` |
| `wfN.ld`, `wfN.mk`, `romcheck.py` | linker script, makefile, ROM comparison |
| `wfN_data_dump.txt` | layout, sample tables, song table with order lists, channels, instruments, effects |
| `wfN_patterns.zip` | every pattern decoded in tracker form |
| `wfN_wav.zip` | every sample as an 8-bit WAV at its own rate (loop points in the file name) |

`make -f wfN.mk check ROM="…gba"` assembles with `arm-none-eabi-as -mcpu=arm7tdmi`, links every section at
its ROM address (IWRAM code at its run address with the ROM load address), and `romcheck.py` reports each
range as identical.

---

## 14. How it compares

Against Nintendo's MP2K/`m4a` driver, which the other GBA engines in this project are usually measured
against: both mix PCM in software into two FIFOs for stereo, but this engine plays **tracker modules**
(patterns and effects, not MIDI-like tracks with ADSR instruments), runs its mixer **from the main loop
and an underrun interrupt** with a ~1000-sample ring rather than once per V-Blank into a frame-sized
buffer, and schedules ticks with **sample accuracy** rather than once per frame. It has none of MP2K's
envelopes, LFOs, reverb, voice priorities or CGB channels. In spirit it is closest to a GBA port of a
PC/Amiga module player.
