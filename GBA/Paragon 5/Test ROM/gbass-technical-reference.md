# GBASS (Game Boy Advance Sound System) — GBA
## Reverse-engineering report and technical reference

*Subject: the distributed object `gbass.o` with its header `gbass.h`, the HTML manual (`gbassdoc/`), the demo
source (`ex.src/`) and the linked demo ROM `gbass.bin`; plus a check of David Beckham Soccer (E) (M5).
Function and global names come from the object's symbol table; struct fields, labels and command mnemonics are
mine. Statements marked (inferred) are deductions, not direct reads of the code.*

**Subject files** (`…/GBAAudioLab/P5/`)

| File | What it is |
|---|---|
| `gbass.o` | ELF32 ARM relocatable, 587 359 bytes, not stripped: engine code + one demo song and its instrument set |
| `gbass.h`, `gbasscontent.h` | public API (39 functions) and the song constants (`SONG_Title`, intro 360 / loop 5 134 frames) |
| `gbass.bin` | demo ROM linked from `ex.src` + `gbass.o` (engine at `0x0800226C` + object offset) |
| `ex.src/main.c` | demo/test program, header `Copyright (C) 2000 Stephane Hockenhull`; Makefile takes `gbass.o` from `../_out/blades/` |
| `David Beckham Soccer (E) (M5).gba` | `DAVIDBECKHAM` / `ABQP` |

**Provenance.** The demo source and HTML manual credit Stephane Hockenhull (2000). The object is an `ld -r` of
four inputs: a hand-written ARM mixer, `gbass.c` and `digi.c` (both gcc 2.x Thumb, each starting with a
`.gcc2_compiled.` marker), and the output of a content converter (sample, instrument and song symbols with names
like `gbass_Wave$$piano_3`, `gbass_Inst$$5$$$kwak`, `gbass_Pat$$title$$3$7`). It includes Nintendo's
`AgbDefine.s` equates (896 absolute symbols), so the mixer was assembled with the official SDK headers.

---

## 1. Executive summary

* **Hybrid engine.** Music and effects play on the **four PSG channels** *and* on **software-mixed 8-bit PCM
  channels** at the same time. In the demo, a song has 12 tracks: 4 on the PSG and 8 digital.
* **Frame-locked.** Everything happens once per V-Blank: one sequencer tick per frame at speed 1.0, and one
  frame of audio mixed per call (`rate × 64` samples, rate 1/2/4/8 → 3 830/7 660/15 340/30 610 Hz; default
  rate 4 = 256 samples per frame at 15 340 Hz).
* **Output** is true stereo through DirectSound A (left) and B (right) on Timer 0, fed by DMA1/DMA2 from a
  double buffer that is **re-armed at every V-Blank** (`GBASS_DMACriticalProcess`), not run as a ring.
* **Mixing** is done in pairs: an ARM routine (`GBASS_Mov_2MOD`) mixes **two voices into one 64-byte 8-bit
  buffer**; a second routine (`GBASS_Mix_Buffers`) sums up to eight such buffers with saturation into the left
  or right output; an optional headphone cross-mix follows. The routines run from IWRAM and use self-modifying
  code and the banked Undefined-mode stack pointer.
* **Music is a script language**, not patterns of rows: each channel runs a 3-level stack of byte-code scripts
  (song track → pattern → instrument), with waits in ticks, notes in 1/16-semitone resolution, loops, jumps,
  sustain/release, effects (arpeggio, portamento, slide-to-note, vibrato, volume slides, sample offset,
  retrigger, wave sweep) and PSG controls.
* **Sound effects are instruments.** `GBASS_SFX_Start(n, …)` runs instrument `n`'s script on a 4th script level
  of a digital channel, temporarily replacing that channel's music voice (the music voice keeps advancing
  silently), with two-bit priorities, handles, stereo allocation and release; instruments that begin with
  `99 cc` play on PSG channel `cc` instead.
* **David Beckham Soccer uses GBASS** — an earlier, smaller build of the same engine with the same data format
  (§12).

---

## 2. Object layout

| Section | Size | Contents |
|---|---|---|
| `.text` 0x0000–0x028F | 0x290 | ARM: `GBASS_Mix_Table`, `GBASS_Mov_None`, `GBASS_Mov_2MOD`, `GBASS_Mix_Buffers`, `GBASS_CrossMix`, `GBASS_Mix_BLOCKEND` |
| `.text` 0x0290–0x48DF | 0x4650 | Thumb, `gbass.c`: 64 functions (player, mixer driver, API) |
| `.text` 0x48E0–0x50B3 | 0x7D4 | Thumb, `digi.c`: 10 hardware functions |
| `.rodata` | 0x534 | `gbass_mixingrates`, `gb_notes`, `digi_notes`, `vibrato_table`, `wavevibrato_table` |
| `.data` | 0x7B73C | 50 waves (496 725 bytes PCM), wave/instrument/type/song tables, 59 instruments, 1 song, 132 patterns, `gbass_DigiBufferModes`, `gbass_module` |
| `.slowram` (EWRAM) | 0x2C0 | digi.c state, `gbass_ram`, digital and GB channel blocks |
| `.medram3/2/1`, `.fastram` | 0x100/0x100/0x80/0x664 | sfx mixers, music mixers, mix buffers; silence word, DMA buffers, IWRAM code area |

External references: `__divsi3`, `__muldi3`, `_call_via_r3` (libgcc). The five RAM sections are what the
manual asks the user to place with a custom linker script.

---

## 3. Public API

API functions that change channel or mixer state take a lock (`gbass_ram+08`); if `GBASS_Process` is called
from the interrupt while the lock is held it only counts the call (`+0C`), and the unlocking API function runs it
on exit. Simple setters and getters (transpose, speed, headphone, no-music mode) write their field directly. Example-ROM address = `0x0800226C` + object offset.

| Function | .o offset | What it does |
|---|---|---|
| `GBASS_Init()` | 0x2EFC | initialise state from `gbass_module`, `DigiInit`, clear buffers, copy ARM routines to IWRAM, enable sound, `GBASS_Reset` |
| `GBASS_Reset()` | 0x2DE8 | stop music and sfx, reset mixers, master volumes 256, transpose 0, speed 1.0, silence PSG |
| `GBASS_DMACriticalProcess()` | 0x2B90 | start of V-Blank: re-arm both DMAs on the half just mixed, flip halves |
| `GBASS_Process()` | 0x23E4 | end of V-Blank: sequencer ticks, sfx, mix one frame (§5) |
| `GBASS_Suspend()` / `GBASS_Resume()` | 0x341C / 0x3578 | stop DMA/timers and PSG / program timer 0 rate, DMA1→FIFO A, DMA2→FIFO B, A=left, B=right, start |
| `GBASS_AudioRateDivide(d)` | 0x3440 | rate = default/d (≥1); rescales every voice's pitch constant, clears buffers, Suspend/Resume |
| `GBASS_GetAudioRate()`, `GBASS_GetDefaultAudioRate()` | 0x3114, 0x3120 | current / default rate (1, 2, 4, 8) |
| `GBASS_AudioMode(n)`, `GBASS_GetAudioMode()` | 0x3090, 0x3160 | number of mix buffers (channel pairs) processed |
| `GBASS_HeadPhoneMode(on)` | 0x2ED4 | cross-mix flag; **on by default** (Init sets flags = 0x0C) |
| `GBASS_OutputBufferLeft/Right()` | 0x312C / 0x3144 | the left/right DMA half being filled this frame (for user DSP) |
| `GBASS_NoMusicMode(on)` | 0x48B8 | skip silent advancing of music voices hidden by sfx |
| `GBASS_Song_Play(i)`, `GBASS_Song_Stop()` | 0x3348, 0x328C | start/stop a song |
| `GBASS_Song_Transpose(h16)` | 0x316C | transpose in 1/16 semitones, clamped ±768 |
| `GBASS_Song_Speed(s)` | 0x3190 | 16.16 playback speed (ticks per frame) |
| `GBASS_Song_MasterVolume(v)` | 0x319C | 31…256 → music mixers and NR50 |
| `GBASS_Song_Time()`, `GBASS_Song_Title(i)` | 0x333C, 0x3314 | ticks since `Song_Play`; name string |
| `GBASS_Song_SaveStateBufferSize/SaveState/LoadState` | 0x35F0 / 0x3600 / 0x3784 | `pairs·128 + 152` bytes; music state only, sound effects keep running |
| `GBASS_SFX_MasterVolume(v)` | 0x3220 | 0…256 → sfx mixers |
| `GBASS_SFX_Start/StartStereo` | 0x4238 / 0x4244 | allocate and start (§7) |
| `GBASS_SFX_StartChnl` | 0x45FC | start on an explicit channel |
| `GBASS_SFX_Restart/RestartStereo` | 0x4634 / 0x4644 | reuse a handle's channel(s) |
| `GBASS_SFX_Stop/StopAll/IsActive/Volume/VolumeStereo/Pitch/Release` | 0x3ADC / 0x39A0 / 0x3A6C / 0x3BDC / 0x3C84 / 0x3E60 / 0x3D94 | per-handle control |

Not in `gbass.h` but exported: `GBASS_ReverbClear`, `GBASS_ReverbMusicOn/Off/Mode` (0x4814–0x4864) only set flag
bits 3–8 that nothing in this build reads — a stub for a reverb DSP that is not linked in.

Internal functions: `GBASS_Process_GB` (0x03F4), `GBASS_Process_Digital` (0x15C0), `GBASS_SilentMix` (0x2384),
`GBASS_GBTranspose` (0x0290), `GBASS_DigiTranspose` (0x02F8), `GBASS_GetNewSFXID` (0x0358), `GBASS_MixerReset`,
`GBASS_ScriptPtrReset`, `GBASS_PlayerStatusReset`, `GBASS_PlayerChannelMusicStop`, `GBASS_PlayerChannelOrderSet`,
`GBASS_PlayerReset`, `GBASS_Reset_GBCChannel`, `GBASS_Reset_GBC` (0x2BC4–0x2D60), `GBASS_SFX_StartReuse` (0x3F30),
`GBASS_SFX_StartChnlReuse` (0x4368); `digi.c`: `DigiInit`, `DigiStop`, `DigiDMA`, `DigiReSeekStereo`,
`DigiReSeek`, `DigiSeek`, `DigiRate`, `DigiRateAGB`, `DigiPan`, `DigiStart` (0x48E0–0x5004). Each one is commented
in `gbass.s`.

**Host obligations** (manual + code): call `GBASS_DMACriticalProcess` first thing in V-Blank and
`GBASS_Process` at its end, every frame; never call another GBASS function from an interrupt that may preempt
one; don't use DMA1/DMA2/Timer 0; never be in Undefined mode when `GBASS_Process` runs (the mixer borrows
`r13_und`).

---

## 4. The module descriptor

The code never names a content symbol directly; everything goes through `gbass_module` (80 bytes, end of
`.data`), which the converter emits together with the RAM sections sized for the project:

| Off | Demo value | Meaning |
|---|---|---|
| +00 | 4 | default rate (samples per frame / 64) |
| +04, +08 | 1, `gbass_SongTable` | songs |
| +0C, +10, +14 | 59, `gbass_InstrumentTable`, `gbass_InstrumentTypeTable` | instruments |
| +18, +1C | 50, `gbass_WaveTable` | waves |
| +20 | 4 | digital channel **pairs** (8 channels) |
| +24, +28, +2C | music mixers, sfx mixers, digital channel blocks | RAM |
| +30, +34, +38 | 2, mix buffers, `gbass_DigiBufferModes` = `01 01` | mix buffers (each stereo = one pair left, one pair right) |
| +3C | GB channel blocks | RAM |
| +40, +44, +48 | DMA buffers, silence word, IWRAM code area | RAM |
| +4C | 0x0F | which `GBASS_Mix_Table` routines to copy |

---

## 5. Output stage and the frame

### 5.1 Hardware

| Resource | Use |
|---|---|
| Timer 0 | sample clock, reload `2^24 / gbass_mixingrates[rate]` (rate 4: 15 340 Hz → reload 1 093 → 15 350 Hz) |
| DMA1 / DMA2 | left buffer → FIFO A / right buffer → FIFO B, control `0xB660` (DMA2 `0xF660` if its IRQ is enabled), count 4 |
| `SOUNDCNT_H` | A 100 % left only, B 100 % right only, both on Timer 0, PSG at 100 % (shadowed in `.slowram`) |
| `SOUNDCNT_X` | 0x80; `NR50` = 0x77 (or song master volume >> 5); `NR51` from per-channel pan commands |
| PSG | channels 1–4 driven register-by-register by `GBASS_Process_GB`; wave RAM double-banked |

### 5.2 The double buffer

The DMA buffer (`.fastram+4`) is `L0 L1 R0 R1`, each `rate·64` bytes. `GBASS_DMACriticalProcess` stops Timer 0,
points DMA1 at `L[cur]` and DMA2 at `R[cur]`, restarts the timer and flips `cur`; `GBASS_Process` then fills
the other half. Because both DMAs restart together on a stopped timer, the channels stay sample-aligned and no
interrupt is needed. The timer actually runs about 0.4 % fast (279 808 of the 280 896 cycles in a frame), so at
the end of each frame the FIFO DMA reads a little past its half before the restart (inferred; at most one
16-byte FIFO burst).

### 5.3 `GBASS_Process`

```
if locked: pending++ ; return
acc += speed * tempo >> 16                        ; both 16.16, default 1.0 each
while acc >= 1.0:                                  ; one tick per whole step
    acc -= 1.0 ; song_time++
    for each digital channel: Process_Digital(music status, channel, music mixer, level 0)
    for GB channels 0-3:      Process_GB(music status, channel, gbchan, level 0)
for each digital channel: Process_Digital(sfx status, channel, sfx mixer, level 3)
for GB channels with an sfx running: Process_GB(..., level 3)
repeat rate times (64 samples each):
    for each active mix buffer b:
        left pair:  voice = sfx mixer if the channel runs an sfx (SilentMix the music mixer) else music mixer
                    Mov_2MOD(voice0, voice1, buffer b)          ; slot +24, or +28 if mode bit 3
        right pair: same into buffer b (stereo buffers only)
    Mix_Buffers(buffers, L, n) ; Mix_Buffers(buffers, R, n)  ; or direct output in single-buffer mode
if headphone: CrossMix(L, R, rate)
```

`GBASS_Song_Time` therefore counts ticks, which equal frames at speed 1.0 and tempo 1.0.

---

## 6. Voices and mixing

### 6.1 Mixer (32 bytes, `MIX_*` equates in the object)

```
+00 src     sample pointer            +10 speed   16.16 note ratio (digi_notes)
+04 vol     0–255 (scripts)           +14 loop    16.16 loop length; == speed means one-shot
+08 pos     16.16 position            +18 cvol    u16 channel volume 0–256
+0C end     16.16 loop/sample end     +1A mvol    u16 master volume (song or sfx)
                                       +1C rate    16.16 wave rate << rate shift
```

`Mov_2MOD` computes per voice `v = vol·cvol·mvol >> 16` and `step = speed·rate >> 16`, then for 64 samples
`out = (A[pos_A]·v_A + B[pos_B]·v_B) >> 9` (no interpolation). Past `end` the position is pulled back by
`loop`; a one-shot voice is pulled back by its own step, so it parks on its last sample — the converter ends
every one-shot wave on silence. Two full-volume voices reach ±127 together; `Mix_Buffers` adds up to eight
buffers with saturation (the overflow test is `(x ^ x>>1) & 0xF80`). The manual's "32-bit mixing" therefore
holds inside `Mov_2MOD` only; between pairs the precision is 8-bit.

### 6.2 The ARM routines

`GBASS_Init` copies the routines listed in `GBASS_Mix_Table` to IWRAM and stores their RAM addresses in
`gbass_ram+18…+28`. `Mix_Buffers` patches its own first chain instruction (`mod_load` / `mod_add`) to enter an
8× unrolled add chain at the right buffer count, so it must run from RAM. `Mov_2MOD` saves CPSR, switches to
Undefined mode and uses its banked `sp` as a twelfth work register — the reason for the manual's warnings about
Undefined mode and User mode.

---

## 7. The sequencer

### 7.1 Channels and levels

Digital channels come in pairs (96-byte blocks); the four PSG channels use two more blocks. Each channel has
four script levels of 8 bytes `{u16 wait, u8 loop count, u8 release, u8 *pc}`:

| Level | Started by | Holds |
|---|---|---|
| 0 | `GBASS_Song_Play` | the song track ("order list") |
| 1 | `1x pppp` at level 0 | a pattern |
| 2 | `2n ii` at level 1 (music) | the instrument script |
| 3 | `GBASS_SFX_Start` or `2n ii` in an sfx | the sound-effect instrument script |

A tick decrements each level's wait; when it reaches zero the level runs commands until the next wait. Music
runs levels 0, 1, 2; a sound effect runs level 3 only. The note state lives in an 8-byte status record (music
and sfx separately): note 0–191 (12 semitones × 16), octave, wave, effect, two effect parameters.

### 7.2 Command set

| Byte(s) | Mnemonic | Effect |
|---|---|---|
| `0n` / `00 nn` | wait | wait n (1–15) / nn ticks; `00 00` stops the level |
| `1x pp pp pp pp` | play | start the next level at the pointer (wait 1) |
| `2n ii` | note | note n (C…B), start instrument ii on the next level; `2C ii` = instrument only |
| `3n`, `3F ww`, `3E` | wave | select wave n / ww (digital); duty/width (GB 1,2,4); upload wave to wave RAM (GB 3); `3E` stops looping and plays on to the release end |
| `4n` | pitch | set note n without restarting; `4C` key off; `4D` stop instrument + key off; `4E` stop instrument; `4F` release |
| `5n` | octave | octave n |
| `60 p`, `61 nn`, `62 p`, `63 p` | jump, loopcount, loop, sustain | `63` jumps while the release flag is clear — the converter's `$$$kwak` sustain loops |
| `70`, `71 vv`, `72 vv`, `73 vv` | volume | voice volume 0 / vv; channel volume; song master volume (also NR50) |
| `80` | fx off | |
| `81 xy` | arpeggio | note, +x, +y semitones cycling per tick |
| `82 xy`, `83 xy` | porta up/down | |
| `84 tn ss` | slide to note | target octave t, semitone n; speed ss |
| `85 xy` | vibrato | waveform/depth x, rate y (0x4000/(y+4)) |
| `86 ss`, `87 ss`, `88` | volume slide, channel-volume slide, slides off (volume 255) | signed per tick, clamped 0–255 |
| `89 xy` | wave sweep | moves the sample start through the wave with `wavevibrato_table` (PWM-like) |
| `8A oo` | sample offset | start + oo·65 536 (·256 samples) |
| `8B nn` | retrigger | every nn ticks (`8B 00` = restart now) |
| `92` | trigger | restart the PSG note (NRx4 bit 7) |
| `93`/`94`/`95` | pan | PSG right / left / both (NR51) |
| `96 ss` | sweep | NR10 (GB channel 1) |
| `97 tt` | tempo | tempo factor = tt/150 (150 = one tick per frame) |
| `98` | wait sample | digital: wait until a one-shot voice has finished |
| `99 cc` | GB header | first bytes of an instrument that belongs to PSG channel cc; skipped when executed |
| `9A ii`, `9B ii xy zz` | GB sfx | start PSG instrument ii from another channel (9B also presets its octave x and note byte y; zz unused) |
| `A0`–`FF`, unused codes | — | stop the level: the opcode is consumed and the wait counter stays 0, so the level is dead until restarted |

### 7.3 Pitch

Notes are 1/16 semitones (192 per octave), so slides and vibrato are smooth. Digital: `speed = digi_notes[note]
<< (octave−5)` with `digi_notes[n] = 65 536·2^(n/192)`; octave 5, note C plays a wave at the mixing rate.
GB: register `= 2048 − (gb_notes[note] scaled by octave)`, `gb_notes[n] = 131 072/f` for octave 5 (C = 262 Hz);
octaves clamp to 3–8. A song transpose (`GBASS_Song_Transpose`) goes through `GBASS_DigiTranspose` /
`GBASS_GBTranspose`; a wave whose data pointer has bit 31 set ignores it and is played at `rate × song speed`
(tempo-synced loops).

---

## 8. Sound effects

* The handle is `flags << 16 | tag << 8 | channel`, with `tag = priority << 6 | id` (6-bit id from
  `GBASS_GetNewSFXID`, unique among running effects). `channel` is 255 for a PSG effect; −1 means nothing was
  started.
* Allocation (`GBASS_SFX_StartReuse`): first a channel whose level 3 is idle, in a buffer of the requested kind
  (mono buffer, or the left/right pair of a stereo buffer); otherwise a channel whose running tag is not higher
  in priority. `SFX_PRIO_LOCK` (3) only displaces lower priorities, matching the manual. `SFX_MONO` takes a mono
  buffer if one exists, else one voice on each side; `SFX_STEREO` always takes two.
* While level 3 runs, the channel outputs the **sfx mixer** instead of the music mixer; the music mixer is
  advanced silently (`GBASS_SilentMix`) so the music stays in time — this is the "music gets cut off by sound
  effects" case in the manual's troubleshooting page. PSG effects own their channel until they end, then the
  channel is flagged in `gbass_ram+6F` and the music's registers are restored.
* Volume, stereo volume, pitch (wave rate) and release act on every channel carrying the tag.

---

## 9. Data formats

```
Song     u32 tracks, Track *table, char *name                        (12 bytes)
Track    u8 *script, s16 channel (0-3 PSG 1-4, 4+ digital n-4), s16 master volume (256)
Wave     u32 data (bit31 = tempo-synced), u32 rate 16.16, u32 start 16.16,
         u32 loop end 16.16, u32 loop length 16.16 (0 = one-shot), u32 release end 16.16   (24 bytes)
Instrument table: u8 *script[n];  type table: u8[n], 0-3 = PSG channel 1-4, 4 = digital
Scripts  byte code of §7.2; pointers are absolute, little-endian, unaligned
```

Track scripts are `play pattern; wait length` pairs ending in `jump LoopPoint` (or `00 00` for a non-looping
song); patterns are notes, waits and effects for one channel; instruments set wave and volume, slide, and
usually sit in a `wait 1; sustain` loop until the pattern sends `4F release`. The converter names everything
after its source (`gbass_Pat$$title$$<pattern>$<track>`), and writes `INTROTIME`/`LOOPTIME` per song into
`gbasscontent.h` — the demo's 360/5 134 match the track lengths exactly.

---

## 10. RAM (demo build)

| Symbol | Section | Size | Contents |
|---|---|---|---|
| `SOUNDCNT_H`, `dma`, `dmaintenable`, `timer`, `rate` | `.slowram` +00 | 16 | `digi.c` state |
| `gbass_ram` | `.slowram` +10 | 0x70 | global state (field list in `gbass.s` header) |
| `gbass_DigiPlayerPairRam` | `.slowram` +80 | 4 × 96 | digital channels |
| `gbass_GBPlayerPairRam` | `.slowram` +200 | 2 × 96 | PSG channels |
| `gbass_DigiMixersSFXRam`, `gbass_DigiMixersMusicRam` | `.medram3`, `.medram2` | 8 × 32 each | mixers |
| `gbass_DigiBufferRam` | `.medram1` | 2 × 64 | pair mix buffers |
| `gbass_SilenceRam`, `gbass_DMABufferRam`, `gbass_MixProcRam` | `.fastram` | 4, 0x400, 0x260 | idle-script target, DMA double buffer, ARM code |

---

## 11. Quirks and bugs

1. **Music volume slides share a byte with the track loop counter.** `86`/`87` store their per-tick amounts in
   bytes +2/+3 of level 0 (music) or level 1 (sfx) — the same bytes `61`/`62` use as the loop counter and `4F`
   as the release flag at those levels. Harmless in the demo (tracks contain no loops), but a track that loops
   with `61/62` while its instrument slides would corrupt both (inferred).
2. **`9A`/`9B` from a sound effect copy the wrong tag.** For level 3 the code reads the tag from
   `channel − 13` instead of `channel + 11`, i.e. from the previous channel's data, so a PSG effect started by
   a digital effect gets an unrelated tag (inferred; no demo instrument does this).
3. **Reverb API is a stub**: four exported functions set flags nothing reads.
4. **Headphone cross-mix is on after `GBASS_Init`** although the manual describes it as an option to offer.
5. **Timer slightly fast** (§5.2): a few samples per frame are read past the end of each half.
6. **No interpolation, 8-bit buffers between pairs**; the "32-bit mixing" claim applies to the pair mixer only.
7. **Unused `gbass_ram+04`** and `gbass_mixingrates` entries for rates other than 1/2/4/8 (13 entries, up to
   45 964 Hz).

---

## 12. David Beckham Soccer

**Verdict: yes — the game uses GBASS**, but an earlier and smaller build than this `gbass.o`. It shares the data
format, the hardware layer and the core mixer; the C player was rewritten in between.

### 12.1 Evidence

| Part | Beckham ROM | Relation to `gbass.o` |
|---|---|---|
| `digi.c` | `080130DC–08013884` | `DigiDMA`, `DigiReSeekStereo`, `DigiReSeek`, `DigiSeek`, `DigiRate`, `DigiRateAGB`, `DigiPan`, `DigiStart` byte-identical (relocations masked); `DigiInit` differs only in the initial `SOUNDCNT_H` shadow (0x0002 vs 0x000E); `DigiStop` at `0801314C` |
| ARM mixer | `08013884–08013A74` (copied to IWRAM `0300310C`) | `Mov_None` and `Mix_Buffers` byte-identical; `Mov_2MOD` identical except that it saves `sp` in a literal instead of switching to Undefined mode; **no `CrossMix`** |
| constant tables | `08030AEC`, `08030B20`, `08030CA0`, `08030FA0` | `gbass_mixingrates`, `gb_notes`, `digi_notes`, `vibrato_table` byte-identical; **no `wavevibrato_table`** |
| module descriptor | `0820FCB0` | same fields with one extra pair after the song table (`0`, `082073B0`): rate 4, 7 songs, 65 instruments, 52 waves, 2 pairs, 1 stereo buffer |
| digi state / `gbass_ram` | `02004608` / `020046E0` | same layout at the start (`SOUNDCNT_H`, `dma`, `dmaintenable`, `timer`, `rate`); lock/pending fields at +08/+0C |
| data | waves `081B4464–08206ECF`, wave table `08206ED0`, instruments `082073B0` (types `082074B4`), songs `0820792C`, scripts to `0820FCAF` | decode with the same command table and structs |

### 12.2 Function map (Beckham names are by correspondence)

| Function | Beckham | Notes |
|---|---|---|
| `GBASS_Process_GB` | `08013A74` | 3 228 bytes (4 556 in .o) |
| `GBASS_Process_Digital` | `08014710` | 2 248 bytes (3 522) |
| `GBASS_Process` | `08014FD8` | no speed/tempo accumulator: exactly one tick per frame; no cross-mix; called from `08000720` |
| `GBASS_DMACriticalProcess` | `080152E4` | uses the default rate (no rate divider); called from `08000692` |
| `GBASS_MixerReset`, `ScriptPtrReset`, `PlayerStatusReset` | `08015314`, `08015340`, `08015358` | 90–100 % similar |
| sfx start (no handles) | `08015378` (+ wrapper `08015368` = play with volume 255/255, channel 0) | `play(sfx, volL, volR, channel)`; sound n = instrument n+52; ≤59 digital, >59 PSG 1 — decided by a constant compare, not the type table; 25 call sites |
| `GBASS_PlayerChannelOrderSet`, `GBASS_PlayerReset` | `080154C0`, `08015500` | |
| `GBASS_Reset_GBCChannel`, `GBASS_Reset_GBC` | `08015538`, `080155F4` | |
| `GBASS_Reset`, `GBASS_Init` | `08015678`, `08015744` | Init copies the mixer block and relocates its pointer table |
| `GBASS_Song_MasterVolume`, `GBASS_Song_Play` | `08015838`, `080158AC` | |
| `GBASS_Suspend`, `GBASS_Resume` | `0801595C`, `08015968` | |

### 12.3 What the older build lacks

No `CrossMix`/headphone mode, no `AudioRateDivide`, no song speed, transpose, save/load state, no handles,
priorities, `IsActive`/`Stop`/`Release`/`Pitch` for effects; channel blocks are 80 bytes instead of 96. Script
commands `89`–`8B` (wave sweep, sample offset, retrigger) and `97`–`9B` (tempo, wait-sample, GB header and
cross-channel GB effects) are absent (the `8x` dispatch has 9 entries instead of 12, effect modes 0–5 instead
of 0–11); none of them appear in the game's data. The data that it does use is the same format, so a GBASS
song extractor written from §9 reads Beckham's music unchanged (with the module descriptor's two extra words).

### 12.4 Content

| | Demo (`gbass.o`) | David Beckham Soccer |
|---|---|---|
| songs | 1 ("Title", 12 tracks: 4 PSG + 8 digital) | 7 (FrontEnd, PreMatch, SeasonEnd, LeagueWin, LeagueLose loop; MatchWin, MatchLose one-shot), 8 tracks each: 4 PSG + 4 digital |
| instruments | 59 (49 digital, 10 PSG) | 65 (52 music + 13 effects; 8 digital and 5 PSG-1 effects) |
| waves | 50, 496 725 bytes | 52, 338 540 bytes (`081B4464–08206ECF`) |
| mix | 4 pairs in 2 stereo buffers, 15 340 Hz | 2 pairs in 1 stereo buffer, 15 340 Hz |

Song lengths (track 0, ticks = frames): FrontEnd 3 456, PreMatch 1 728, SeasonEnd 3 584, LeagueWin 1 536,
LeagueLose 1 280, MatchWin 512, MatchLose 316.

---

## 13. Delivered files

In `P5/gbass_disasm/`:

| File | Contents |
|---|---|
| `gbass.s` | full source of the object: ARM + Thumb code with labels and per-function documentation, `.rodata` tables, `.data` with every script decoded one command per line, RAM sections |
| `gbass_agbdefs.inc` | the 896 equates present in the object |
| `gbass_wavedata.bin` | the 50 waves' PCM, pulled in with `.incbin` |
| `gbass.mk`, `verify_gbass.py` | `make -f gbass.mk check` assembles with `arm-none-eabi-as -mcpu=arm7tdmi -mthumb-interwork` and compares every section after relocation and every symbol with the original: **identical** |
| `gbass_waves_wav.zip` | the 50 waves as 8-bit WAV at 15 340 Hz (loop points in the names) |
| `gbass-technical-reference.md`, `gbass-data-dump.md` | this document and the content tables |
