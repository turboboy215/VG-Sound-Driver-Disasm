# GHX sound engine (Shin'en): disassembly notes

The GHX engine was written by Martin Wodok, and all the music here is by Manfred Linzner. This note covers the five builds in the four ROMs in `GHX`. Each `.asm` file holds one engine bank: all of its code plus all of its music and SFX data, written as labelled source rather than a separate text dump. Each file reassembles with RGBDS 0.9 to a **byte-identical** bank, and `build_and_verify.py` checks this against the ROMs.

All addresses below are CPU addresses inside the engine bank. Each build is dated from its version string, not from the game's release date.

## Builds, oldest first

| Build | ROM / bank | Version string | Date | Notes |
|---|---|---|---|---|
| v1 | GHX Example Sample, bank 1 | `GHX Audio Engine (c) 1999 Martin Wodok` | 1999 | One song; PCM samples in the same bank, played by the engine |
| v2.0207 | Tomb Raider, bank $7F | `GHX Sound Engine v2.0207` | 7 Feb 2000 | Positions hold track **pointers**; no PCM playback |
| v00218 | Tomb Raider, bank $7E | `GHX Sound Engine v00218` | 18 Feb 2000 | v2.0207 plus fixes (resume via fx $8, SFX time $FF on ch3) |
| 00530 | Jimmy White's Cueball, bank $10 | `Ver.00530` | 30 May 2000 | Track numbers again, row prefetch, banked PCM samples via the timer IRQ |
| 01206t | SpongeBob – Lost Spatula, bank $3D | `Ver.01206t` | 6 Dec 2000 | PCM removed again, master volume and fades, loop counts fixed |

The version strings read as YYMDD dates: 00218 = 2000-02-18, 00530 = 2000-05-30, 01206 = 2000-12-06. "v2.0207" is v2.0, built 7 Feb.

## Tomb Raider: which build is used

**Both builds are used.** Every sound call in bank 0 (`$061A`–`$0662`, through `$066B`) first switches to the bank stored in `$C1E5` and then calls the jump table.

- **Bank $7F (v2.0207) is the front end.** `$C1E5` is set to $7F at boot (`$0150`) and by the title/menu code (`$0EFD` starts subsong 0, the title music; `$18FF`). Subsongs 3–8 are jingles whose loop entries run on into the title positions.
- **Bank $7E (v00218) is in-game.** `$0596` sets `$C1E5` = $7E and starts a subsong chosen from `$C194`:

  | `$C194` | 0 | 3 | 6 | 9 | 11 | anything else |
  |---|---|---|---|---|---|---|
  | Subsong | 4 | 5 | 6 | 7 | 8 | 9 |

  It then plays **SFX 29**: a ch3 instrument at level 0 with time $FF. This silences channel 3 and locks it, which only works in v00218 because of its `cp $FF` change.
- **The game has its own PCM player** (`ghx_tombraider_bank0_pcm.asm`). The LYC interrupt (`$0398`, lines $14/$3B/$61/$87) writes 16 bytes of a 64-byte RAM buffer into wave RAM four times per frame, which gives about 7646 samples/s played at $6F0 = 7710 Hz. `PCM_FillBuffer` (`$06FE`) refills the buffer once per frame from one of 9 samples in banks $F8–$FA, listed in the table at `$06BA` as `[bank] [dw addr] [dw length in 64-byte chunks]`. A sample is started with `PCM_Play` (`$06A4`, A = sample number), which bank $0C calls.

The two Tomb Raider banks hold different data: v2.0207 has 10 subsongs, 29 SFX and 45 SFX instruments; v00218 has 11 subsongs, 32 SFX and 49 SFX instruments.

## Jump tables

| Slot | v1 | v2.0207 | v00218 | 00530 | 01206t |
|---|---|---|---|---|---|
| $4000 | Init (A = subsong, C = song) | Init | Init | Init | Init |
| $4003 | Play (once per frame) | Play | Play | Play | Play |
| $4006 | Stop | Stop | Stop | Stop | Stop |
| $4009 | SoundOn | SoundOn | SoundOn | SoundOn | SoundOn |
| $400C | TimerISR | SaveSong | SaveSong | SaveSong | SaveSong |
| $400F | PlaySFX (A) | RestoreSong | RestoreSong | RestoreSong | RestoreSong |
| $4012 | – | (ret) | (ret) | TimerISR | (ret) |
| $4015 | – | PlaySFX | PlaySFX | PlaySFX | PlaySFX |
| $4018 | – | Pause | Pause | Pause | Pause |
| $401B | – | – | (ret) | SetPCMBank (A = own bank, C = PCM base + 1) | (ret) |
| $401E | – | – | – | MuteMusic | MuteMusic |
| $4021 | – | – | – | – | FadeIn (A = step) |
| $4024 | – | – | – | – | FadeOut (A = step) |
| $4027 | – | – | – | – | SetMasterVolume (A = 0–7) |
| $402A | – | – | – | – | Stop (second entry) |

## Data formats

### Song header (12 bytes)

The header is copied into RAM by Init:

```
"GHX", subsongs, rows per pattern, unused, dw tracks, dw instruments, dw orders
```

- `dw tracks` is still written by the converter in v2.0207 and v00218, but those builds don't use it.
- In the TR v00218 bank (subsong 10) and in SpongeBob (subsong 17, "EMPTY"), the last subsong is a placeholder whose counts are garbage.

### Order table

There are two entries per subsong: an intro and a loop. Each entry is `[count] [dw positions]`, and **count + 1** positions are played. After the intro, the loop entry repeats forever.

### Positions

| Build | Size | Layout |
|---|---|---|
| v1, 00530, 01206t | 7 bytes | `trk1 tr1 trk2 tr2 trk3 tr3 trk4` (track numbers) |
| v2.0207, v00218 | 11 bytes | `dw trk1, tr1, dw trk2, tr2, dw trk3, tr3, dw trk4` (track pointers, `POS` macro) |

Channel 4 has no transpose.

### Tracks (patterns)

A pattern has the header's row count of rows. Each row is 1–3 bytes:

- **Byte 1:** note in bits 0–5, `$40` = instrument byte follows, `$80` = effect byte follows.
- **Instrument byte:** bits 0–5 = instrument + 1 (0 = change the volume only), bits 6–7 = volume shift. On ch1, ch2 and ch4 the shift divides the envelope volume: full, ½, ¼, off. On ch3 the two bits select NR32 directly: 1 = 25%, 2 = 50%, 3 = 100%.
- **Effect byte:** **parameter << 4 | command** (the command is in the low nibble).
  - $F = speed (ticks per row).
  - $8 = return to the saved song. Acted on from v00218 onwards; in v2.0207 it only sets the flag.
  - No other command is decoded, and only $F occurs in any of the songs.

Notes are frequency-table indices: 1 = C-2 (65.4 Hz) through 72 = B-7. The final index is `transpose + row note + playlist note − 1`.

### Instruments

| Build | Flag byte | Speed byte |
|---|---|---|
| v1 | bits 0–4 = steps, bit 5 = vibrato, bits 6–7 (ch3) = PCM rate | – |
| v2 and later | bits 0–5 = steps | bit 7 = vibrato |

Layouts by type:

- **Square:** `flags, speed, NRx2, [vib delay, depth<<4|speed], steps…`
- **Noise:** `flags, speed, NR42, steps…` (no vibrato)
- **Wave:** `flags, speed, NR32, [vib], step, flag, dw pos, dw lower, dw upper, sweep speed, base lo, base hi, steps…`
  - 16 bytes from base + pos are copied to wave RAM.
  - Toggling the sweep makes pos bounce between lower and upper (a PWM-like effect).
  - The 32-byte buffers are often read up to 14 bytes past their end; the file comments note where.
- **PCM:**
  - v1: `flags (rate<<6), dw sample, dw blocks`
  - 00530: `flags (bits 6–7 rate, bit 5 loop), bank (relative to the base bank), dw sample, dw blocks`
- **Ch3 flag bits 6–7 (v2) or 5–7 (01206t) without a PCM player:** these only release channel 3 to the game.

**Playlist steps** are 3 bytes: `[note] [cmd] [cmd]`.

- **Note byte:** bit 6 = absolute note; otherwise the value is relative, and 1 = unison.
- **Commands:**
  - $00: none.
  - $01–$3F: new playlist speed (v2 and later).
  - $40|v: volume v. On ch3 this sets the level 0–3.
  - $80|n: jump back n steps.
  - $C0|x: duty on ch1/2, wave-sweep toggle on ch3.
- **From 00530:** bits 2–5 of $C0|x set a loop count for the next jump (the default $FF means forever), and duty 3 means "keep the duty".
- **00530 bug:** the ch1/ch2 loop count is written to $001E/$0023 (the MBC RAM-enable register) instead of to RAM, so square-channel loops stay infinite. 01206t fixes this.

### SFX

- **Table:** 5 bytes per effect: `[ins ch1] [ins ch2] [ins ch3] [ins ch4] [time]`.
  - Instrument numbers are 1-based indices into `SFXInstTable`; 0 means the channel isn't used.
  - Music on each used channel is muted for `time` ticks. From v00218, a time of $FF on ch3 holds the channel.
- **v2 only:** bit 7 of the ch1 byte records the SFX as the ch3 owner (`wSFX_Ch3Owner`).

### Tables

| Table | Size |
|---|---|
| FreqTable | 73 words |
| NoiseTable | 30 bytes: NR43 indexed by (note + PLnote − 2) / 2 |
| VibratoTable | 16 × 16 signed bytes |
| PCM rate table (v1, 00530) | `TMA, TAC, NR33, NR34` |

Rate 1/2 = 256 IRQ/s, so 8192 Hz. Rate 3 = 512 IRQ/s, so 16384 Hz. Each IRQ delivers 16 bytes (32 samples).

## PCM

| Build | PCM handling |
|---|---|
| v1 | 5 PCM instruments in bank 1. The timer IRQ copies 16 bytes per interrupt, and the IRQ is switched off at the end of the sample. |
| 00530 | 32 commentary samples (SFX) in banks $11–$16. `GHX_SetPCMBank` copies a 15-byte stub to `$DEED` that switches to the sample bank, copies 16 bytes and switches back (the bank to restore is patched into the stub). Samples can cross banks. In double-speed mode only every second IRQ is used. |
| TR (both banks), 01206t | No engine PCM. Tomb Raider uses its own player (above). |

## Files

| File | Contents |
|---|---|
| `ghx_example_sample.asm` | Bank 1 of the example ROM: engine, song, 6 samples, SFX |
| `ghx_tombraider_bank7F_v2.0207.asm` | Front-end music engine |
| `ghx_tombraider_bank7E_v00218.asm` | In-game music engine |
| `ghx_tombraider_bank0_pcm.asm` | TR's own PCM player (bank 0 code) and the 9 samples in banks $F8–$FA |
| `ghx_jimmywhite_cueball_v00530.asm` | Engine bank $10 and PCM banks $11–$16 |
| `ghx_spongebob_lostspatula_v01206t.asm` | Engine bank $3D, including the 18 subsong names left in the bank |
| `ghx_hw.inc`, `ghx_macros.inc` | Shared register names, note names, and the row/position macros |
| `build_and_verify.py` | Assembles every file and compares it with the ROMs one folder up |
