# Krazy Racers — KCE Kobe GBA Sound Driver
## Reverse-engineering report and technical reference

*Konami Krazy Racers / Wai Wai Racing Advance (GBA, 2001). Sound driver written in-house by KCE Kobe. No other GBA title using this driver is known; it is analysed here as a standalone engine.*

**Subject file** (`…/GBAAudioLab/KR/`)

| File | Role |
|---|---|
| `Krazy Racers (E).gba` | 4 MiB retail ROM, header `KRAZY RACERS`, game code `AKWP` |

**What was done.** There are no symbols, so everything below comes from a recursive-descent disassembly of the ROM (all 108 driver functions, about 37 KB of Thumb code), a decode of every sound in the sound table, and a rebuild of the driver as GNU-as source that reassembles **byte-identical** to the ROM (see §13). Claims are read directly from the code unless marked *(inferred)*. Function and variable names are mine. Addresses are GBA bus addresses (ROM = `0x08000000` + file offset).

---

## 1. Executive summary

The driver is **compiled C** (old GCC Thumb output, the AGB-SDK toolchain), linked into the game at `0x0803C128–0x08045278` with all state in EWRAM at `0x0201C700–0x0201CE83`. It drives all six GBA sound outputs and has two layers:

* **A sequencer** with **11 fixed logical channels**, ticked from a **Timer 1 interrupt that fires twice per frame (~119.5 Hz)**. Each channel has its own tempo accumulator, call/return, two loop levels, a loop point, a pitch-envelope (vibrato/bend) engine and a gate/release model. The channels are hard-wired to hardware: square 1, square 2 and wave for music; square 1, wave and noise for sound effects; a **drum track** that has no hardware of its own; and **four PCM voices**.
* **A 4-voice software mixer** feeding **both DirectSound FIFOs as a true stereo pair** (FIFO A = left, FIFO B = right). It runs inside the **DMA1 interrupt**, mixing 16 samples per side each time the FIFO asks for data, at a sequence-selectable output rate (20 rates, 8.2–43.7 kHz; 10.9 kHz by default). PCM voices play samples **1:1 at the output rate — there is no resampling or pitch**. The mixer is a 16-way `switch` on the set of active voices, fully unrolled per case, which is why it takes up 26 KB of the 37 KB.

Three design choices stand out:

1. **Music and sound effects are the same thing.** Every sound — song, jingle, engine noise, drum hit, voice clip — is an entry in one 397-entry table. An entry has a priority, a "music" flag and a bitmask of the logical channels it uses. `SndPlay(id)` starts every channel in the mask that the new sound's priority can claim.
2. **Drums are sound effects.** The music has no percussion channel. A dedicated *drum track* plays "notes" that each fire `SndPlay(DrumMap[note])`, and those sounds land wherever their own mask says. In the shipped data every drum sound is a one-shot noise program, so drums compete on priority with real noise effects.
3. **Square 1 and wave are shared between music and SFX by priority.** Both a music channel and an SFX channel own state for those two outputs at all times. Whichever has the higher priority drives the registers. When the effect ends, the music channel is told to rewrite every register it owns (wave RAM, duty, sweep, pan, volume, frequency), and it carries on from wherever its sequence has got to.

There is also a game-facing **engine-pitch** feature: command `95` plays a note whose frequency comes from `EngineFreqTable[g_enginePitch]`, a byte the game updates from car speed *(inferred from use)*. The 18 engine sounds (152–167, 395, 396) are wave-channel loops of `95` notes. This explains why none of the 37 songs at ids 1–37 (presumably the race music) uses the music wave channel: it is kept free for the player's engine.

---

## 2. Build, location and interrupt facts

### 2.1 Module map

| Range | Size | Contents |
|---|---|---|
| `0x0803C128–0x0803EACB` | 10.6 KB | sequencer, command handlers, API, PCM voice control |
| `0x0803EACC–0x08045277` | 26.0 KB | `SndDma1Irq` — the mixer (one function) |
| `0x08046960` / `0x080469C0` / `0x08046BBC` | — | libc `memcpy`, `memset`, GCC `_call_via_r1` (outside the module) |
| `0x08058AAC–0x080596DB` | 3.1 KB | driver constant tables (§9, §11 of the data dump) |
| `0x080596DC–0x08194A4F` | 1.2 MB | sound data: sound table, waves, drum map, kits, sequences, sample table, PCM |
| `0x083FBD08–0x083FCBE3` | 3.8 KB | command-handler tables, frequency tables, pitch envelopes, kit table |

The code is GCC Thumb with these toolchain fingerprints: `mov r7,r8 / push {r7}` prologues, `adds rX, rY, #0` used as a move, literal pools after every function, and **`bl` used as a long unconditional branch inside a function** (old GCC did this when the target was beyond `b` range). The mixer uses that trick 71 times. A naive disassembler treats those as calls and runs into literal pools. Command handlers are dispatched through `_call_via_r1`.

### 2.2 RAM map (EWRAM)

| Address | Name | Use |
|---|---|---|
| `0201C700` | `g_seqPtr` | sequence read pointer for the channel being processed (shared global) |
| `0201C704` | `g_fadeAcc` | fade-rate accumulator |
| `0201C774` | `g_fadeSpeed` | fade rate (bits 0–6) + bit 7 = software fade |
| `0201C778` | `g_curSoundId` | id being started |
| `0201C7E4` | `g_curSoundMusicFlag` | `0x80` if that sound is music |
| `0201C854` | `g_tickBusy` | bit 0 = tick running, bit 1 = API call running |
| `0201C8C4` | `g_stopMask` | one-shot pause-toggle mask (§8.6) |
| `0201C934` | `g_fadeToggle` | freezes the fade while paused |
| `0201C938` | `g_curSoundPrio` | priority being started |
| `0201CA14` | `g_fadeLevel` | software fade level 0…0xFF |
| `0201CA18` | `g_enginePitch` | index into `EngineFreqTable` |
| `0201CA84` | `g_curChId` | logical-channel id being processed |
| `0201CB64` | `g_dynPcmToggle` | round-robin bit for dynamic PCM allocation |
| `0201CBD4` | `g_dynPcmSingleMode` | written by the game; restricts dynamic PCM to voice 2 |
| `0201C710…0201CBDF` | `chXX` | 11 channel structs × 0x70 (§10), scattered in linker order |
| `0201CBE0 / CBF0` | `g_pcmPtrL/R[4]` | per-voice sample read pointer, left / right |
| `0201CC00 / CD00` | `g_fifoBufA/B` | 256-byte ring buffers feeding FIFO A / B |
| `0201CE00` | `g_pcmRateIdx` | current output-rate index |
| `0201CE10 / CE20` | `g_pcmShiftL/R[4]` | per-voice right shift = 4 − volume |
| `0201CE30 / CE40` | `g_pcmVolL/R[4]` | per-voice volume 0…4 |
| `0201CE50 / CE54` | `g_fifoWrIdxA/B` | mixer write index into the ring buffers |
| `0201CE60 / CE70` | `g_pcmBlocksL/R[4]` | 16-byte blocks left to play |
| `0201CE80` | `g_pcmActiveMask` | bits 0–3 = voice active on left, bits 4–7 = on right |

Channel structs (ids explained in §6.1): `ch11` `0201C710`, `ch81` `0201C780`, `ch34` `0201C7F0`, `ch22` `0201C860`, `ch52` `0201C8D0`, `ch40` `0201C940`, `ch83` `0201C9B0`, `ch82` `0201CA20`, `ch00` `0201CA90`, `ch80` `0201CB00`, `ch63` `0201CB70`.

### 2.3 Interrupts and the host

The game uses the AGB-SDK `crt0` with a ROM `IntrTable` at `0x08046F84`. The driver depends on three entries:

| IRQ | Handler | Driver work |
|---|---|---|
| V-Blank | `0x08000465` (game) | last call: `SndVBlankResync` — Timer 1 := `0x00C1FACC` |
| Timer 1 | `0x080005D1` (game stub) | Timer 1 := `0x00C1F777`, then `SndTimerIrq` |
| DMA 1 | `SndDma1Irq` `0x0803EACD` | the mixer |

Boot calls `SndInit()` and then `SndInitDirectSound()`. `REG_IE` has V-Blank, V-Count, Timer 1, DMA 1, serial and Game Pak enabled.

---

## 3. Public API

| Address | Name (mine) | Signature | Game call sites | Behaviour |
|---|---|---|---:|---|
| `0803E1C4` | `SndInit` | `void(void)` | 1 | NR50=0x77, NR51=0xFF, master on, PSG 100 %, wave DAC on; clears globals; sets each channel's pan bits / voice index; `SndStopAll` |
| `0803E67C` | `SndInitDirectSound` | `void(void)` | 1 | sets up DMA1/DMA2 + FIFOs + stereo routing, voice volumes 4/4, write indices 0x80, rate index 11 |
| `0803E2AC` | `SndPlay` | `void(u16 id)` | 253 | sets busy bit 1, clears the SOUNDBIAS resolution bits, `SndPlayInternal(id)`. `id 0` = stop all |
| `0803E2E8` | `SndStop` | `void(u16 id)` | 54 | runs the END handler on every channel currently playing `id` |
| `0803E0C0` | `SndStopAll` | `void(void)` | (internal) | clears all channels, fade state, PCM voices; NR50/51 restored; rate reset to `DefaultPcmRateIdx`; SOUNDBIAS res = 3 |
| `0803E418` | `SndFadeOutHw` | `void(u8 speed)` | 13 | if anything is playing: `g_fadeSpeed = speed & 0x7F` (hardware fade, §8.5) |
| `0803E438` | `SndFadeOutSw` | `void(u8 speed)` | 10 | `g_fadeSpeed = speed \| 0x80` (software fade); `speed 0` cancels and resets the fade |
| `0803E46C` | `SndGetFadeSpeed` | `u8(void)` | — | |
| `0803E478` | `SndSetPauseToggleMask` | `void(u32 mask)` | 3 | writes `g_stopMask`; the game passes `0x3CF` |
| `0803E484` / `0803E494` | `SndTogglePauseMusic/All` | `void(void)` | 0 | mask `0x78F` / `0x7FF` (unused) |
| `0803E4A4` | `SndSetEnginePitch` | `void(u8)` | 1 | `g_enginePitch` |
| `0803E4B0` | `SndGetMusicIds` | `u16(void)` | — | OR of the ids on the eight music-side channels |
| `0803E500` | `SndIsPlaying` | `bool(u16 id)` | 55 | |
| `0803E590` | `SndGetAllIds` | `u16(void)` | — | OR of all 11 channel ids (non-zero = something playing) |
| `0803E644` | `SndPlayMusicIfIdle` | `bool(u16 id)` | 2 | if no fade is running and no music is playing: `SndPlay(0); SndPlay(id)`, return 1. If music is playing, start a hardware fade at speed 0x40 and return 0 (the caller retries). One call site passes 42, the title loop (§12) |
| `0803E600` | `SndChangeMusic` | `bool(u16 id)` | 0 | like the above, but returns 1 without restarting if `id` is already playing (dead code) |

`SndPlay` and `SndStop` set bit 1 of `g_tickBusy` around their work. A Timer 1 tick that lands during the call sees the busy flag and is **dropped** rather than deferred. This is the driver's only re-entrancy guard.

---

## 4. Timing

### 4.1 The tick

Timer 1 runs with prescaler /64 and IRQ enabled. V-Blank reloads it with `0xFACC` (1 332 counts = 85 248 cycles). The Timer 1 handler reloads it with `0xF777` (2 185 counts = 139 840 cycles) and calls `SndTimerIrq`. That gives one tick 85 248 cycles after V-Blank and a second 139 840 cycles later (225 088). A third would land at 364 928, past the next V-Blank (280 896), so V-Blank re-arms the timer before it fires. The result is **exactly two ticks per frame**, spaced about 140 000 cycles apart: **119.455 Hz**.

### 4.2 Tempo

Every channel has an 8-bit `tempo` and a 16-bit accumulator. Each tick:

```
acc += tempo
if acc > 0xFF:  acc &= 0xFF;  elapsed++;  if elapsed >= length: read next event
```

So **steps per second = 119.455 × tempo / 256**, and an event of length *L* lasts *L* steps. A new channel starts with `acc = 0xFF, tempo = 1, length = 1`, so it reads its first events on the first tick. Songs set tempo on every track independently. Command `D0`/`DB` loads `tempo` and zeroes the accumulator.

Check against the data: the title loop (sound 42) plays a 117 808-byte sample at 16 384 Hz (7.19 s) in an 846-step slot at tempo 255 (7.11 s). The next trigger cuts it about 1 % before its natural end.

### 4.3 Per-tick flow

```
SndTimerIrq:          if g_tickBusy == 0: g_tickBusy = 1; SndUpdate(); g_tickBusy &= ~1
SndUpdate:            fade bookkeeping (§8.5), then SndUpdateAllChannels
SndUpdateAllChannels: for id in 00,11,22,34,40,52,63,80,81,82,83:
                          g_curChId = id; ChUpdate(&ch[id])
ChUpdate:             pause-toggle mask check (§8.6) → ChProcess
ChProcess:            if active: fade-kill, priority mute/restore, then ChTick
ChTick:               envelope / pitch-env / volume work, tempo step, event fetch
```

The channel id is passed in a **global** (`g_curChId`). Almost every helper runs a `switch(g_curChId)` to pick its hardware registers.

---

## 5. Hardware resources

| Resource | Use |
|---|---|
| `SOUND1CNT_L/H/X` | square 1 (music `ch00` or SFX `ch40`) |
| `SOUND2CNT_L/H` | square 2 (music `ch11` only) |
| `SOUND3CNT_L/H/X`, `WAVE_RAM` | wave (music `ch22` or SFX `ch52`; also every engine sound) |
| `SOUND4CNT_L/H` | noise (`ch63`: noise SFX and drum hits) |
| `SOUNDCNT_L` (NR50/NR51) | master volume (hardware fade, `D4`), per-channel pan masks |
| `SOUNDCNT_H` | PSG 100 %; DSA = 100 %, **left only**, Timer 0; DSB = 100 %, **right only**, Timer 0 (`0x9A0E`) |
| `SOUNDCNT_X` | master enable |
| `SOUNDBIAS` bits 14–15 | resolution: cleared by every `SndPlay`, set per song by `D6`/`DA`, set to 3 by `SndStopAll` |
| **Timer 0** | PCM output rate (prescaler /64) |
| **Timer 1** | sequencer tick |
| **DMA 1** → `FIFO_A` | from `g_fifoBufA`, `CNT = 0xF6000000` (repeat, 32-bit, FIFO timing, **IRQ**) |
| **DMA 2** → `FIFO_B` | from `g_fifoBufB`, `CNT = 0xB6000000` (same, no IRQ) |

DMA 0/3 and Timers 2/3 are untouched.

---

## 6. Architecture

### 6.1 The eleven logical channels

| Id | Struct | Mask bit | Output | Interpreter | Pan/voice byte (`+0x5E`) |
|---|---|---|---|---|---|
| `0x00` | `ch00` | `0x001` | square 1, music | PSG | `0x11` |
| `0x11` | `ch11` | `0x002` | square 2, music | PSG | `0x22` |
| `0x22` | `ch22` | `0x004` | wave, music (and engine sounds) | PSG | `0x44` |
| `0x34` | `ch34` | `0x008` | none — drum track | drum | `0x00` |
| `0x40` | `ch40` | `0x010` | square 1, SFX | PSG | `0x11` |
| `0x52` | `ch52` | `0x020` | wave, SFX | PSG | `0x44` |
| `0x63` | `ch63` | `0x040` | noise | noise | `0x88` |
| `0x80` | `ch80` | `0x080` | PCM voice 0 | PCM | voice 0 |
| `0x81` | `ch81` | `0x100` | PCM voice 1 | PCM | voice 1 |
| `0x82` | `ch82` | `0x200` | PCM voice 2 | PCM | voice 2 |
| `0x83` | `ch83` | `0x400` | PCM voice 3 | PCM | voice 3 |
| — | `ch82`/`ch83` | `0x800`, `0x1000` | dynamically chosen PCM voice 2 or 3 | PCM | — |

The id encodes *role* in the high nibble (0–3 music, 4–6 SFX, 8 PCM) and *hardware channel* in the low nibble. The `0x34` drum id breaks that pattern. Square 2 has no SFX twin, and the noise channel has no music twin.

### 6.2 Starting a sound — `SndPlayInternal(id)`

```
entry = SoundTable[id-1]                        ; id 0 → SndStopAll
g_curSoundPrio = entry.byte0 & 0x7F
g_curSoundMusicFlag = entry.byte0 & 0x80
slot = 0
for each fixed channel in order 00,11,22,34,40,52,63,80,81,82,83:
    if entry.mask & channel.bit:
        if g_curSoundPrio >= channel.prio:  ChStart(channel, entry.track[slot])
        slot++                               ; consumed even if the channel refused
for bit in 0x800, 0x1000:  SndAllocDynamicPcm(id, bit, slot) → maybe ChStart(ch82 or ch83, ...)
then arbitrate square 1 (if mask has 0x001 or 0x010) and wave (0x004 or 0x020):
    the lower-priority channel of each music/SFX pair gets flags: −0x2 (no hardware), +0x4 (mute request);
    ties go to the music channel
```

* **Priority**: a new sound takes a channel if its priority is **≥** the priority already there. An idle channel has priority 0. Shipped priorities run from 7 to 20. Music is 9–10 (one entry each at 12 and 15), most SFX are 10–12, and the engine loops are 7. Entries 246–256 use 20: they are channel silencers (§12).
* `ChStart` writes the priority, id, track-table pointer and start pointer. It resets all channel state, sets flags `0x102 | music<<7`, ORs the channel's `+0x5E` into NR51 and, for the two square-1 channels, writes NR10 = 8 (sweep off).
* **Dynamic PCM** (`SndAllocDynamicPcm`). If `g_dynPcmSingleMode` is set, only voice 2 is used: it is taken when idle, or stolen when the new priority is ≥ and the id differs. Otherwise the routine chooses between voices 2 and 3. It prefers an idle voice, then a lower-priority voice, and alternates through `g_dynPcmToggle` when both are equal, without restarting a voice that is already playing the same id. 180 of the 397 sounds (all the short PCM effects and voice clips) use mask `0x800` alone.

### 6.3 Handing the hardware back

When an SFX channel (`0x40`/`0x52`) reaches END, the END handler sets flags `|= 3` on its music twin (`ch00`/`ch22`): `2` = owns the hardware again, `1` = restore request. On its next tick the music channel's `ChProcess` rewrites everything it owns. For wave that means wave RAM (`ChLoadWaveRam`); for all of them it means volume, frequency and pan, plus duty and sweep for square 1. Then it clears bit 0. While muted (flag `4` set, `2` clear), the music channel kept running its sequence normally, so it comes back in time. This is the same "keep the displaced music stepping" idea as QuickThunder's ghost stepper, but here it falls out of having two independent channel structs per output instead of one struct with a swappable pointer.

### 6.4 Drum track

`ch34` reads notes 1–0xB8 (only 1–34 have map entries) and calls `SndPlayInternal(DrumMap[note-1])`. Rests do nothing. Commands start at `0xB9` and share the PSG handler table. Every drum sound in the shipped data is a short noise program with priority 9 and the music flag set, so drums fade with the music and lose to any noise SFX of priority ≥ 10.

### 6.5 Engine pitch

Command `95 len` behaves like a note, except its frequency is `EngineFreqTable[g_enginePitch] + detune` and it sets flag `0x40000`. The engine loops (sounds 152–167, 395, 396) repeat `95 01` — e.g. sound 152 at tempo 200 and then 142 (93 and 66 notes per second) — alternating `DETUNE 20 / DETUNE 0` for a growl. That way the pitch follows the game's speed value within about 15 ms.

---

## 7. Data formats

### 7.1 Sound table — `SoundTable` `0x080596DC`, 397 × 36 bytes

```
+0  u8   priority (bits 0–6) | 0x80 = music (fade-affected)
+1  u8   0
+2  u16  channel mask (§6.1)
+4  u32  trackTable[8]   one per set mask bit, in bit order (bit 0 first, 0x1000 last)
```

There is no count and no bounds check. Sound ids are 1-based, and 0 means stop all.

### 7.2 Track tables

`trackTable[k]` points at an array of u32. **Element 0 is the sequence start**, and elements 1… are subroutine entry points for `FD n`. Track tables of consecutive sounds sit back to back from `0x083FCBE4`.

### 7.3 PSG interpreter (`SeqReadPsg`) — channels 00, 11, 22, 40, 52

| Byte | Meaning |
|---|---|
| `00` | rest; followed by a length byte (unless fixed-length mode) |
| `01–60` | note *n* (n = 1 → C2); frequency `PsgFreqTable[n + transpose − 1] + detune`; length byte follows unless fixed-length |
| `61–FF` | command: handler `SeqCmdTable[b − 0x61]` |

After each command the handler returns 1 to keep reading or 0 to end the event. Lengths are 8-bit steps.

**Command set** (argument bytes in brackets; ✱ = never used by the shipped data):

| Byte(s) | Args | Effect |
|---|---|---|
| `61–6C` | — | transpose = +(b & 0xF) semitones |
| `70–7C` | — | transpose = −(b & 0xF) (`70` = reset to 0) |
| `7D` | `d` | detune: `d` added to the frequency register (the same struct byte holds the kit number on PCM channels) |
| `7E` | `i` [`dly`] | pitch envelope `i` (1-based) starting after `dly` steps; `7E 00` = off |
| `7F` | `w` | wave `w` → wave RAM (wave channels) |
| `80–8F` | — | wave `b & 0xF` |
| `90–93` | — | duty `(b & 3) << 6` → NRx1 (on a wave channel this would select wave 0x90–0x93) |
| `94` | `s` | ✱ sweep → NR10 |
| `95` | `len` | engine-pitch note (§6.5) |
| `96` | `g e` | gate offset `g` steps, release envelope `e` (§8.2) |
| `97` | `x` | hardware attack envelope byte (raw NRx2); enabled if `x & 7` |
| `A0–A7, A9–AB` | — | pitch-envelope scale `b & 0xF` (0/8 = ×1, 1–7 = ≪1…≪7 capped at 127, 9–11 = ≫1…≫3) |
| `B0` ✱ | `t g e` | tempo + gate/env |
| `B1` ✱ | `vp g e` | volume/pan + gate/env |
| `B2` ✱ | `t d g e` | tempo + duty + gate/env |
| `B3` ✱ | `t vp g e` | |
| `B4` ✱ | `t vp d` | |
| `B5` ✱ | `vp d g e` | |
| `B6` ✱ | `t vp d g e` | |
| `BD` ✱ | `n` | tie: the next note takes *n* length bytes, played back-to-back without retrigger |
| `BE` | `len` / — | toggle fixed-length mode: when it turns on, it reads `len` (u8; u16 BE on PCM) and later notes carry no length byte; the next `BE` turns it off and takes no argument |
| `BF` | — | repeat the last note with the same length |
| `C0–CF` | — | volume = `b & 0xF` (NRx2 high nibble) |
| `D0` | `t` | tempo |
| `D1/D2/D3` | — | pan centre / left / right (NR51 mask `FF`/`F0`/`0F`) |
| `D4` | `v` | NR50 = `v` (master volume) |
| `D5` | `e` | release envelope only |
| `D6` | `r` | SOUNDBIAS resolution `r` (0–3) |
| `DF` | — | noise channel: NR42=8 + restart (silence), ends the event |
| `E0` ✱ | `t e` | tempo + envelope |
| `E1` ✱ | `t vp` | tempo + volume/pan (`vp`: high nibble volume, low nibble 1=C 2=L 3=R) |
| `E2` ✱ | `vp e` | |
| `E3` ✱ | `t vp e` | |
| `FB` | — / `n` | loop A: the first `FB` marks the start; the second `FB n` jumps back until the body has played *n* times in total |
| `FC` | — / `n` | loop B (second nesting level), same rules |
| `FD` | `i` / — | call subroutine `trackTable[i]`; inside the subroutine a bare `FD` returns (one level) |
| `FE` | — | first `FE` = loop point; second `FE` = jump back to it, forever |
| `FF` | — | end of track (§8.7) |
| others | — | no-op (`6D–6F 98–9F A8 AC–AF B7–BC D7–DE E4–FA`) |

Because `FB`, `FC`, `FD`, `FE` and `BE` change meaning with channel state, a static decoder has to track that state. All 707 tracks and 178 subroutines decode cleanly that way. Each track ends in `FF` (395) or a second `FE` (312), and each subroutine ends in a bare `FD`.

### 7.4 Drum interpreter (`SeqReadDrum`) — channel 34

Notes `01–B8` trigger `DrumMap[n-1]`, `00` is a rest, and lengths are u8. Commands `B9–FF` use the same table entries as the PSG interpreter.

### 7.5 Noise-SFX interpreter (`SeqReadNoiseSfx`) — channel 63

Every byte `00–BF` is written **directly to NR43**, together with NR42 = `volume | env` and a restart, **once per tempo step** (this channel skips the length logic). Commands are `C0–FF`, with `C0–CF` volume, `D0` tempo, `D5` envelope and `DF` noise off. Example (sound 100, drum note 3): `TEMPO 127, VOL 4, 51 52 53, TEMPO 1, ENV 04, 52, END`.

### 7.6 PCM interpreter (`SeqReadPcm`) — channels 80–83

| Byte | Meaning |
|---|---|
| `00` | rest = stop the voice; **16-bit big-endian length** follows |
| `01–BD` | note = kit slot: plays sample `Kit[kit][n-1]` from the start, at the output rate; u16 BE length |
| `BE` | fixed-length toggle (u16 BE length when turning on) |
| `BF` | repeat last note |
| `C0–D8` | volume/pan preset: L = (b−0xC0) / 5, R = (b−0xC0) % 5, each 0–4 |
| `D9 k` | kit `k` |
| `DA r` | SOUNDBIAS resolution |
| `DB t` | tempo |
| `DC–EF` | **global** output rate index b − 0xDC (§9.3) — affects all four voices |
| `F0–FA` | no-op |
| `FB–FF` | loops / call / loop point / end, as in §7.3 |

Handlers come from `SeqCmdTablePcm` (`0x083FBF84`), which is simply entries 159–224 of the same 225-entry array.

### 7.7 Pitch envelope (`PitchEnvTable`, 255 pointers)

A byte stream run by `ChPitchEnvStep`:

| Byte | Meaning |
|---|---|
| `1x–Ex` | one step: hold for (high nibble − 1) further ticks; value = low nibble, bit 3 = negative, magnitude = bits 0–2 |
| `0h vv` | two-byte step: hold = h − 1 ticks (`00` = 255); `vv` = sign (bit 7) + 7-bit magnitude |
| `FE` | first: mark loop point; second: jump back to it |
| `FB` | counted loop (no shipped table uses it, and the comparison is inverted — §11) |
| other `Fx` | end: pitch envelope off |

The magnitude is scaled by the `A0–AB` shift and added to or subtracted from the channel's base frequency register (`ChWriteFreq`). The result is clamped: values above 0xAFF become 0, values above 0x7FF become 0x7F7. Before the envelope starts there is a delay of `dly` steps (from `7E`) unless the note is tied. The engine then advances one table step whenever its hold counter reaches zero, checked once per tick. 19 of the 255 tables are used. They are classic vibratos (#3–7, #36–38) plus downward scoops and falls (#1, #9, #13–15, #17, #21, #50). Table #7 alone is referenced 1 356 times.

### 7.8 Waves, kits, samples, frequency tables

* **WaveTable** `0x0805CEB0`: 256 slots × 16 bytes (32 four-bit samples). `ChLoadWaveRam` writes `NR30 = 0xC0`, so bank 1 plays and the CPU writes land in bank 0. It copies the 16 bytes as four words, then switches playback to bank 0 (`NR30 = 0x80`) and restarts with the current frequency. The bank swap avoids writing the bank that is playing. 30 different waves are referenced, up to index 50.
* **KitTable** `0x083FCBC4`: 8 pointers to u16 sample-id arrays (kits 6 and 7 are the same array). Sample 4 is 16 bytes of silence and fills unused slots.
* **SampleTable** `0x08081E88`: 145 × `{u32 address, u32 length}`. The samples are 8-bit signed, mono and uncompressed, with lengths multiples of 16. They are contiguous at `0x08082310–0x08194A50` (1 124 160 bytes, 27 % of the ROM). There is no loop information: every sample is a one-shot, and a sustained sound is made by re-triggering it.
* **PsgFreqTable** `0x083FC08C`: 96 u16 values, note 1 = C2 (32 → 65.0 Hz) through note 96 = B9.
* **EngineFreqTable** `0x083FC14C`: 256 u16 values, rising from 44 (index 1, 65 Hz) to 1 547 (index 255, 262 Hz). Index 0 is 2047, effectively silent.

---

## 8. Channel processing in detail

### 8.1 Note start

On a note, the PSG path calls `ChResetNoteState` (clears volume/release counters, copies the pitch-envelope index into the active slot, reloads the hw-envelope trackers, zeroes `elapsed`), then `ChCalcGate`, `ChPitchEnvStart` (runs the first envelope step immediately) and `ChNoteOnVolume`. That last call writes NRx2 = volume (or the raw `97` byte when the hardware attack envelope is enabled) and NRx4 = frequency | 0x8000 (restart). A rest calls `ChNoteRest`. It sets flag `0x8000` and writes frequency `0x7FF` with no restart (131 kHz, inaudible); square 1 also gets NR10 = 8, and noise gets NR43 = `0xDF`. The following tick's `ChVolumeTick` sees `0x8000` and writes volume 0 (NRx2 = 8).

### 8.2 Gate and release

`96 g e`: the gate point is `length − g` steps into the note (`+0x2A`), or `tieTotal − g` for ties. When `elapsed ≥ gate` and `e ≠ 0`:

* **square / noise**: flag `0x4000` (releasing). `ChVolumeTick` rewrites NRx2 = `volume | e`, so the **hardware** envelope performs the release with step `e & 7`. A software counter decrements the level by one every `2·e` ticks and sets flag `0x8000` when the level reaches zero, so the driver knows the note is silent.
* **wave**: immediate cut (`ChNoteRest`), because the wave channel has no envelope.

With `e = 0` there is no release, and the note sustains until the next event.

### 8.3 Volume writes retrigger

`ChWriteVolume` skips the write if the value equals the last one written. Otherwise it writes NRx2 (wave: NR32 = `v & 0xE0`) and **restarts the channel** with the stored frequency, as the DMG requires for envelope changes. Volume 0 is written as `0x08` (increase from 0), the standard silent value.

### 8.4 Wave and PCM volume mapping

Wave volume 0–15 → `WaveVolLevelMap` (0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4) → NR32 code (mute, 25 %, 50 %, 75 %, 100 %). PCM volumes 0–4 per side are scaled by the current hardware master (`PcmVolByMaster[vol][NR50>>4]`) or, during a software fade, by `PcmVolByFade[vol][fadeLevel>>4]`. That makes the PCM voices follow both kinds of fade even though DirectSound has no volume register of its own.

### 8.5 Fades

`SndUpdate` runs every tick: `g_fadeAcc += g_fadeSpeed & 0x7F`. When it overflows 0xFF:

* **hardware fade** (bit 7 clear): NR50 −= 0x11 (both sides down one step). When NR50 reaches 0, `SndStopAll`.
* **software fade** (bit 7 set): `g_fadeLevel += 0x10`, capped at 0xFF. Music-flagged channels subtract it from their volume through `ChWriteScaledVolume`. **When `g_fadeLevel == 0xFF`, `ChProcess` ends every music channel**, while SFX keep playing. The level is not reset afterwards. Any music started before `SndFadeOutSw(0)`, `SndStopAll` or `SndInit` is killed on its first tick, which is why the game issues `SndFadeOutSw(0)` at seven call sites.

### 8.6 Pause toggles — `g_stopMask`

`ChUpdate` consumes **one bit per channel per tick**: `bit = mask & 1; mask >>= 1`, in channel order (bit 0 = `ch00` … bit 10 = `ch83`). A set bit **toggles** the channel's pause flag `0x10`. Pausing silences the hardware (or stops the PCM voice) and skips processing. Resuming clears `0x10 | 0x1` and continues. The mask is therefore a one-shot "toggle these channels" request that drains within a single tick. The game writes `0x3CF`, which toggles `ch00 ch11 ch22 ch34 ch63 ch80 ch81 ch82` and leaves square-1 SFX, wave SFX and PCM voice 3 alone. While a toggle request is pending, `g_fadeToggle` flips, freezing any running fade until the next toggle.

### 8.7 End of track (`FF`)

`Cmd_End` clears flag `0x100` (active) and silences the channel's hardware. For PCM it stops the voice; for noise it writes NR42 = 8 and restarts. For SFX channels `0x40`/`0x52` it hands the hardware back to the music twin (§6.3). Finally `ChClear` zeroes priority, id and flags. A track that ends with a second `FE` never reaches this point.

---

## 9. The PCM mixer

### 9.1 Buffers and DMA

There are two 256-byte rings: `g_fifoBufA` (left) and `g_fifoBufB` (right). DMA1 and DMA2 run in FIFO mode with repeat, starting at the ring bases. The mixer keeps write indices `g_fifoWrIdxA/B`, which start at 0x80 so writing stays half a ring ahead of the DMA read position. Every time a write index wraps to 0x80, the mixer **restarts that DMA from the ring base**. If the display is not in V-Blank it first waits for the next H-Blank edge, presumably to avoid contending with video DMA *(inferred)*. Re-anchoring every 256 samples keeps read and write from drifting apart.

### 9.2 `SndDma1Irq`

DMA1 raises an IRQ for every FIFO request, which is four words (16 bytes). Each IRQ therefore produces **16 left samples and 16 right samples**:

```
switch (g_pcmActiveMask & 0x0F)  — 16 cases, jump table at 0x0803EB00
switch (g_pcmActiveMask & 0xF0)  — 16 cases, compare tree at 0x08041ECE
```

Each case is the C loop "for 16 samples: sum the active voices; store" **fully unrolled** for that exact set of voices:

```
out = Σ  (s8)*ptr[v]++ >> shift[v]          ; shift = 4 − volume (0…4)
1 voice:   stored directly
2/3/4 voices: through a saturating table (Clip2 / Clip3 / Clip4)
```

After the 16 samples each active voice's block counter is decremented. At zero, that voice's bit for that side is cleared. Left and right playheads are independent, so a sample panned to one side only consumes that side. Instruction counts per side are 86 (silence fill), 214 (1 voice), ~400 (2), ~560 (3) and 766 (4). The worst case is about 1 530 Thumb instructions per IRQ. At the default 10 923 Hz there are 683 IRQs per second, around 1 M instructions per second *(estimate, executed from ROM)*.

### 9.3 Output rate

`PcmSetRate(force, idx)` writes `TM0CNT = 0x00810000 | PcmRateTable[idx]` (prescaler /64), so the rate is 262 144 / (65 536 − reload): 43 690, 32 768, 21 845, 16 384 and then 15 420 down to 8 192 Hz in fine steps. Index 11 (10 922.7 Hz) is the default and is restored by `SndStopAll`. The title vocals use index 3 (16 384 Hz). The rate is global, so a sound that changes it retunes every voice already playing.

### 9.4 Voice control

* `PcmVoiceStart(v, sampleId)`: clears the voice's bits; loads both playheads and both block counters (`length >> 4`); `PcmVoiceUpdateRouting(v)` sets the left/right bits for whichever side has a non-zero volume.
* `PcmVoiceSetVolume(v, L, R)`: stores volumes and shifts. A side whose volume becomes 0 has its bit cleared mid-sample. A side is never *re*-enabled until the next start.
* `PcmVoiceStop(v)`: clears both bits.

---

## 10. Channel struct (0x70 bytes)

```
+00 u8  priority            +02 u16 sound id          +04 u32 track table      +08 u32 seq pointer
+0C u8  note                +0E u16 note length (tie accounting)               +10 u16 length (steps)
+12 u16 elapsed steps       +14 u32 flags
+18 u8  detune (PSG) / kit (PCM)     +19 s8 transpose      +1A u8 duty bits / wave index
+1B u8  hw attack env byte  +1C u8 hw-env tick countdown   +1D u8 hw-env level tracker   +1E u8 sweep
+20 u16 tempo accumulator   +22 u8 tempo              +23 u8 tie lengths remaining
+24 u16 base frequency (noise: NR43 byte)             +26 u16 last frequency written
+28 u8  volume<<4 (PCM: left 0–4)    +29 u8 last volume written (PCM: right 0–4)
+2A u8  gate step           +2B u8 gate offset        +2C u8 release env       +2D u8 release countdown
+2E u8  release level       +2F u8 pan mask (FF/F0/0F)
+30 u8  pitch-env index     +31 u8 active pitch-env index      +32 u8 pitch-env delay
+34 u32 pitch-env pointer   +38 u8 pitch offset (bit 7 = negative)  +39 u8 pitch-env scale
+3A u8  pitch-env hold      +3B u8 pitch-env FB counter  +3C u32 pitch-env FB pointer  +40 u32 pitch-env FE pointer
+44 u8  loop-A counter      +48 u32 loop-A pointer    +4C u8 loop-B counter     +50 u32 loop-B pointer
+54 u32 call return         +58 u32 loop point        +5C u16 fixed length
+5E u8  NR51 bits (PSG) / voice (PCM)    +5F u8 volume at note-on    +60 u16 tie total
```

**Flags**: `1` restore hardware · `2` owns hardware · `4` mute request · `10` paused · `20` tie continuing · `40` pitch-env (re)starting · `80` music · `100` active · `200` hw attack running · `400` hw attack enabled · `800` fixed length · `1000` pitch env running · `2000` gate armed · `4000` releasing · `8000` silent · `10000` pitch-env FB loop · `20000` pitch-env FE loop · `40000` engine note · `100000` loop A · `200000` loop B · `400000` in subroutine · `800000` loop point set.

---

## 11. Bugs, dead code and anomalies

1. **Sound 246 has nine channel bits.** Its mask `0x19CF` needs nine track pointers, but an entry holds eight. The ninth (second dynamic PCM voice) is read from the next entry's header: `0x198F0014`, which is not a ROM address. 246 is a priority-20 "silence everything" sound (a one-step rest and `END` on every channel). If the allocator grants it a second dynamic voice, that channel's sequence pointer is fetched from unmapped memory (open bus). It most likely ends quickly or plays garbage until stolen, but it is a genuine out-of-bounds read.
2. **`ChStart` ORs a PCM voice index into NR51.** The `+0x5E` byte is a pan mask for PSG channels but a voice number for PCM channels. Starting `ch81/82/83` therefore does `NR51 |= 1/2/3`, enabling square 1/2 on the right. It is harmless in practice because NR51 is normally 0xFF.
3. **Inverted comparison in the pitch-envelope `FB` loop.** The sequence `FB` loops while `n > counter`. The pitch-envelope `FB` branches back when `n < counter`, so `FB n` falls through on the first pass and never repeats. No shipped table uses it.
4. **DUTY on a wave channel selects a nonsense wave.** On wave channels `90–93` store the command byte itself as the wave index, loading wave slot 144–147. Unused by the data.
5. **Software-fade latch** (§8.5). After a software fade completes, `g_fadeLevel` stays at 0xFF and silently kills new music until it is reset. The game works around this.
6. **Hardware-attack tracker assumes a rising envelope.** The `97` tracker always counts `15 − initial` steps and ignores the direction bit, so a release that starts during a *decreasing* attack begins from the wrong level.
7. **Drum map entry 34 is 0**, which means `SndStopAll`. A drum note 34 would stop every sound. Unused.
8. **Ticks dropped during API calls.** A Timer 1 tick that arrives while `SndPlay`/`SndStop` runs is skipped, not deferred, so music can lose a tick (8.4 ms) whenever the game triggers a sound at the wrong moment.
9. **Dead code.** `SndChangeMusic`, `SndTogglePauseMusic`, `SndTogglePauseAll`, `PcmStopAll`, `PcmVoiceRefresh` and an `ENV`-handler duplicate at `0x0803CB10` have no callers. Commands `94 B0–B6 BD E0–E3` have handlers but are never used. `F9`/`FA` have separate handlers that do nothing.

---

## 12. Content inventory

| | |
|---|---|
| Sound entries | 397 (143 music-flagged, 254 SFX) |
| Tracks / subroutines | 707 / 178 (one more track pointer is invalid, §11.1) |
| Sequence events | 93 585 |
| PCM samples | 145, 1 124 160 bytes, 8-bit signed |
| Kits | 7 distinct |
| Waves used | 30 of 256 |
| Pitch envelopes used | 19 of 255 |
| Drum map | 34 entries, 26 used |

Rough grouping from channel masks and content:

* **1–37**: songs on `S1 S2 DR P1`, a few adding `P3` or a dynamic voice (2 and 3 are PCM/drum-only loops). None uses the music wave channel, which stays free for the engine, so these are almost certainly the race tracks *(inferred)*.
* **38–65, 185, 392**: music that also uses the wave channel or all four PCM voices; 38 and 63 use every music-side channel.
* **41 / 42: the title theme — "Wai Wai Racing" vocals.** PCM only, kit 4, 16 384 Hz. Voice 0 loops long backing samples (108, 108, 109; 7.2 + 7.2 + 3.7 s). Voice 1 drops in shorter vocal phrases (110, 111, 112) at fixed points. Sound 41 adds a one-shot intro (sample 107). The game starts 42 through `SndPlayMusicIfIdle`. The kit-4 samples are by far the longest in the ROM. A render of sound 41 made by emulating the driver's PCM path is included as `kr_sound041_title_vocal_render.wav`. The identification comes from this structure and the known description of the title theme; it has not been checked by listening.
* **66–100**: drum hits: one-shot noise programs, priority 9, music flag set, all referenced from `DrumMap`.
* **101–147, 171–245**: sound effects: PCM clips (fixed voice 0 or dynamic), noise programs and noise+PCM combinations.
* **148–170**: wave-channel effects, including the 16 engine loops 152–167 (priority 7).
* **246–256: priority-20 silencers.** 246 rests every channel, 247 every channel except noise, and 248–256 each silence one channel (P0, P1, P2, P3, S1, S2, WV, DR, NZ).
* **257–389**: 133 dynamic-PCM clips in a repeating pattern (one music-flagged priority-10 entry, then two or five priority-11 entries). They are probably per-character voice sets *(inferred)*.
* **390–397**: odds and ends, including two more engine loops (395, 396).

---

## 13. Deliverables and verification

* **`kr_sound.s` + `kr_sound.ld`**: reconstructed GNU-as source of the whole driver: `0x0803C128–0x08045277` (code and literal pools, every branch symbolic, 108 named functions) plus the two driver-owned constant blocks (`0x08058AAC–0x080596DB`, `0x083FBD08–0x083FCBE3`). `arm-none-eabi-as -mcpu=arm7tdmi` + `ld -T kr_sound.ld` reproduces all three ranges **byte-identical** to the ROM (0 differences in 0x9150 + 0xC30 + 0xEDC bytes).
* **`krazyracers-data-dump.md`**: all tables plus representative sounds decoded.
* **`kr_sequences.txt`**: disassembly of every track and subroutine of all 397 sounds.
* **`kr_seqdump.py`**: the decoder that produced it (handles the stateful opcodes).
* **`kr_sound041_title_vocal_render.wav`** and **`samples/kr_sample107–112.wav`**: the title theme rendered through a model of the PCM path, and its raw samples.

Self-consistency checks: every track decodes to a terminator with no unknown opcode under the argument lengths given in §7. The sequence-loop semantics were confirmed on the engine sounds (`FB … 95 01 … FB 19`). The tempo formula agrees with the sample lengths of the title loop to within 1 %.

---

## 14. Notes for reimplementation or tooling

* **A player needs**: the 11-channel tick of §4–8 at 119.455 Hz, the three interpreters (PSG/drum/noise share one command table), the priority rules of §6.2, and a 4-voice stereo mixer with shift volumes and no resampling. The DMG side needs no tables beyond `PsgFreqTable`, the wave table and the pitch envelopes.
* **To rip music**, use the sound table. The songs are the multi-channel music-flagged entries (1–65, 185, 392); drum hits and some voice clips also carry the music flag. A song's tracks are self-contained, apart from drum notes, which pull in other sound entries through `DrumMap`.
* **Compared with QuickThunder** (the AudioArts driver in this project): both keep displaced music running silently under an SFX. QuickThunder does it with one struct and a swappable pointer plus a ghost stepper; KCE Kobe gives every shared output two permanent channel structs and arbitrates by priority. QuickThunder plays PCM by pointing DMA straight at samples, while this driver mixes four voices in software with stereo placement. Volume and envelope handling here stay very close to the DMG hardware (4-bit volumes, hardware envelopes for release, NR51 masks for pan, register restarts on every volume change). That fits a design carried over from KCE Kobe's Game Boy Color driver *(inferred — no GBC binary was compared)*.

---

## Appendix — function map

| Address | Name | Role |
|---|---|---|
| `0803C128` | SndTimerIrq | Timer 1 tick entry with busy guard |
| `0803C150` | SndVBlankResync | re-arm Timer 1 from V-Blank |
| `0803C164` | SndUpdate | fade bookkeeping + all channels |
| `0803C1F4` | SndUpdateAllChannels | the 11-channel loop |
| `0803C29C` | ChUpdate | pause-toggle mask |
| `0803C37C` | ChProcess | fade kill, mute/restore |
| `0803C428` | ChTick | envelopes, tempo, event fetch |
| `0803C53C / C8D4 / C96C / CA28` | SeqReadPsg / Drum / Pcm / NoiseSfx | interpreters |
| `0803C5DC` | ChNoteRest | |
| `0803C694` | ChPitchEnvStart | |
| `0803C6EC` | ChNoteOnVolume | |
| `0803C7C0` | ChResetNoteState | |
| `0803C82C` | ChCalcGate | |
| `0803C8A4` | ChTieNextLength | |
| `0803CC08` | ChHwEnvTrack | |
| `0803CC50` | ChReleaseTick | |
| `0803CCEC` | ChVolumeTick | |
| `0803CD80` | ChWriteScaledVolume | fade / wave scaling |
| `0803CE54` | ChWriteVolume | NRx2 + restart |
| `0803CF10` | PcmChUpdateVolume | |
| `0803CFB8 / D008` | ChPitchEnvTick / Step | |
| `0803D190 / D1C8` | ChUpdateFreqFromNote / ChWriteFreq | |
| `0803D26C` | ChLoadWaveRam | |
| `0803D318 / D388 / D3A4` | ChWriteDuty / Pan / Sweep | |
| `0803D3BC–0803DB10` | Cmd_* | the command handlers (44 distinct functions behind 225 table slots) |
| `0803DC04` | SndPlayInternal | |
| `0803DDF0` | SndAllocDynamicPcm | |
| `0803DFA0` | ChStart | |
| `0803E0C0` | SndStopAll | |
| `0803E1B8` | ChClear | |
| `0803E1C4–0803E644` | API | §3 |
| `0803E67C` | SndInitDirectSound | |
| `0803E718 / E760` | PcmSetRate / PcmResetRate | |
| `0803E774 / E7EC / E8E8 / E918 / E924 / E930` | PcmVoiceStart / SetVolume / Stop / StopAll / Refresh / UpdateRouting | |
| `0803EACC` | SndDma1Irq | mixer |
