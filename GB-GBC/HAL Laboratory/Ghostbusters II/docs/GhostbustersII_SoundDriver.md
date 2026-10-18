# Ghostbusters II (GB): sound driver

This is HAL Laboratory's sound driver in *Ghostbusters II* (`Ghostbusters II (UE) [!].gb`, MBC1, 128 KB). It is a separate branch of the HAL engine with its own command set:
- notes and lengths are separate bytes;
- commands are `$F0–$FF`;
- volume comes from simple frame/volume envelopes;
- the hardware registers are written directly.

It shares the period table, the noise table and the music/SFX channel model with the KDL family (see `HAL_SoundEngine_Family.md`).

The driver is in bank 7 at `$4000–$69EA`, with the request queue and init in bank 0 at `$07D4–$084C`. Both rebuild **byte-exact** with RGBDS 0.9.1 (`-Wall` clean) from the sources in `HAL\GB2`. Bank 7 continues at `$69EB` with the game's sound-test screen, which isn't part of the driver.

| Range | Content | File |
|---|---|---|
| bank 0 `$07D4–$084C` | `Sound_Request` (rst `$20`), `Sound_Init`, initial wave and register values | `GB2_Bank0.inc` |
| bank 7 `$4000–$45DB` | driver code; `CommandTable` at `$437F` | `GB2_Driver.inc` |
| bank 7 `$45DC–$48C0` | channel bits, octave, register-offset, period, noise, length tables; sound and envelope tables; 20 envelopes | `GB2_Driver.inc` |
| bank 7 `$48C1–$69EA` | 47 sound headers and their streams | `GB2_Data.inc` |

```
python tools\gen_gb2.py <rom> GB2
sh GB2\build_check.sh <rom>
python tools\verify_gb2.py GB2 [frames per sound]
```

---

## 1. API

| Address | Routine | |
|---|---|---|
| `rst $20` → `$07D4` | `Sound_Request` | a = sound id; appended to `hSoundQueue` (`$FFB3`, 10 entries max) with interrupts off |
| `$07FA` | `Sound_Init` | boot (`$019B`): no channels active, NR52/50/51, wave RAM, NR10–NR44 from `InitialRegs`, `wChLastNote[]` = `$7C` |
| `$0813` | `Sound_InitRegs` | the register part only (also jumped to from bank 4 `$585A`) |
| `$7:$40B9` | `Sound_Update` | through the game's `$01EC`, which maps bank 7 (called from the VBlank, LCD-STAT and timer handlers) |

`$01EC` calls the update once per frame, every other frame, or twice per frame when `$DA37` is 0, 1 or 2. Only the sound-test screen changes `$DA37`.

There is one sound list for music and effects: 47 entries, ids 1–46 (id 0 means "queue empty", so entry 0 can't be started). Each update starts at most one queued sound. A sound takes its channels without any priority check.

| Ids | |
|---|---|
| 1–13, 42 | music (channels 0–3) |
| 46 | stop music (channels 0–3 → `Sound_SilenceStream`) |
| 14–41, 43–45 | SFX (channels 4–7; 45 also uses music channels) |

**RAM.** Per-channel arrays of 8 at `$C511–$C5B8`, plus HRAM `$FFB2–$FFC6`:

| | |
|---|---|
| `wChPtr`, `wChEnvPtr`, `wChLoopPtr`, `wChReturnPtr`, `wChPeriod` | words, indexed by channel × 2 |
| `wChEnvIndex`, `wChWait`, `wChLength`, `wChEnvWait` | |
| `wChLoopCount`, `wChTranspose`, `wChAttenuation`, `wChDuty`, `wChSweep`, `wChNRx4`, `wChLastNote` | |
| `hActiveChannels` `$FFBD` | one bit per channel |
| `hCurCh` / `hCurCh2` / `hCurRegOffset` / `hStreamPtr` | `$FFC0` / `$C1` / `$C2` / `$C3` |
| `wFastMusic` `$D611` | set by the game: music uses the alternate length table |

---

## 2. Channels

There are 8 channels:
- **0–3 are music** on CH1–CH4;
- **4–7 are SFX** on the same hardware (channel & 3).

The update walks channels 0–7. While SFX channel *n*+4 is active, music channel *n* keeps running, but it doesn't write the hardware: bit 3 of `hChMask` is the twin's active bit. A music note still records its period in `wChPeriod`.

When an SFX channel ends while its music twin is active, `Ch_RestoreMusic` writes back the music channel's sweep, duty, period and current envelope step. The channel resumes immediately rather than at its next note.

Each channel counts `wChWait` down. At 0 it reads the stream until a note or rest. Otherwise it counts the envelope step (`wChEnvWait`) down, and at 0 applies the next step.

---

## 3. Data

### Headers

```
SoundNN: channel c, Stream   ; db c (0-7), dw pointer   (repeated)
         end_header           ; any byte with bit 7 set ($FF)
```

Starting a channel sets its active bit, transpose 0, attenuation 0, sweep `$08` and a wait of 1.

Sound 0's header (channels 4–7) has no terminator. It runs on into sound 46's entries (channels 0–3), and all eight point at the shared `$FF` that ends the list, which is also their stream (`snd_end`).

### Stream

| Byte | Macro | Meaning |
|---|---|---|
| `$00–$7B` | `note SEMI, oct` | high nibble = octave 0–7 (`OctaveTable`: × 12), low nibble = semitone (`C_`, `C#`, … `B_`); + transpose → `PeriodTable` (little-endian, the same 72 values as KDL's, octave 0 = C2) |
| CH4 | `drum n` | the byte indexes `NoiseTable` (NR43); NR44 is written with bit 7 set |
| `$7C` | `rest` | NRx2 = `$08`, retrigger |
| `$80–$BF` | `length n` | note length = `LengthTable[n]` for the following notes. While `wFastMusic` is set, music channels use entry n + 16 for n < 32 (shorter values) |
| `$F0 n` | `envelope n` | `EnvelopeTable` entry, restarted at every note |
| `$F1 v` | `duty v` | NRx1 = v OR `$3F`, written now |
| `$F2 n` | `attenuate n` | subtracted from every envelope volume |
| `$F3 n` / `$FA` | `transpose n` / `transpose_up` | |
| `$F4 n` / `$F5` | `loop n` / `endloop` | one level per channel |
| `$F6 ptr` / `$F7` | `snd_call` / `snd_ret` | one level per channel |
| `$F8 v` / `$F9` | `sweep v` / `sweep_off` | NR10 = (v XOR 8) AND `$7F`, written at every CH1 note / NR10 = `$08` |
| `$FB ptr` | `snd_jump` | |
| `$FC` | `snd_nop` | |
| `$FD n` | `play_sound n` | queue sound n |
| `$FE` / `$FF` | `snd_end_count` / `snd_end` | channel off; `$FE` also counts `hChannelsEnded` (`$FFBE`) |

The jump table only looks at the low nibble of `$C0–$FF`, so `$C0–$EF` would act as `$F0–$FF`. The data never uses them. `$FA`, `$FC`, `$FD` and `$FE` aren't used either. The game writes `$FFBE`, but no read of it was found.

### Envelopes

An envelope is a list of `(frames, volume)` pairs with no terminator (`env_step f, v`). In practice a 255-frame step (`env_hold v`) is the last one. Each step sets NRx2 = ((volume − attenuation) << 4) | 8 (constant volume) and retriggers the channel. CH3 is never retriggered. `Sound_Init` starts it (NR34 = `$80`) and it keeps running: notes change its period and set NR32 = `$40` (half volume), and rests set NR32 = `$08` (mute). Its wave is the sawtooth loaded at init; nothing changes it.

20 envelopes; 4, 8, 10 and 12 are not selected by any stream.

---

## 4. Verification

- **Byte-exact rebuild** of bank 0 `$07D4–$084C` and bank 7 `$4000–$69EA`.
- **Emulator harness.** It calls `Sound_Request` and `Sound_Update`, and runs `Sound_Init` between jobs. PyBoy hooks the 10 `ld a,[hl]`/`ld d,[hl]` instructions that read headers, streams, arguments and envelopes. Every id 1–46 is played for 12,000 frames, once with `wFastMusic` = 0 and once with 1.

  | | |
  |---|---|
  | Addresses read | 8,703 |
  | Outside the parse | **0** |
  | Parsed bytes read | 8,703 of 8,837 (every header and stream byte) |

  The 134 unread bytes are envelope steps never reached and the 4 unused envelopes.
- **Unreferenced data:** `$64B9–$64C3`, a short stream fragment, emitted decoded.
- **Not verified:** sound titles, and anything on hardware.

## Files (`HAL\GB2`)

| File | Content |
|---|---|
| `GB2_Sound.asm` | two sections (ROM0 `$07D4`, ROMX bank 7 `$4000`) |
| `GB2_Bank0.inc`, `GB2_Driver.inc`, `GB2_Data.inc` | |
| `GB2_Macros.inc`, `GB2_RAM.inc` | macros for this command set; RAM, hardware and game-routine symbols |
| `tools\gen_gb2.py`, `tools\verify_gb2.py` | generator, harness check |
