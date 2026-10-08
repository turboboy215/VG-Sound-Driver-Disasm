# Star Wars Episode I: Racer (GBC): sound driver

The sound driver of `Star Wars Episode I - Racer (UE) [C][!].gbc` (internal title `EPISODE1RCR`, MBC5 + rumble, 2 MB, CGB only, runs in double speed). It is a different engine from Mole Mania's. Everything is in bank `$03`, except the voice sample player, which is in bank `$05`. The sources in `MM-SWR\SWRacer` rebuild both regions **byte-exact** with RGBDS 0.9.1 (`-Wall` clean).

| Region | Content |
|---|---|
| `$03:4000–5685` | driver code, with its jump tables and small tables |
| `$03:5686–76A9` | drums, pitch envelopes, 10 songs, 40 SFX, wave, length tables, frequency table, two 264-entry engine-pitch tables |
| `$03:76AA–7FFF` | not sound: a signed sine table and game code (`$772A`, `$7942`, `$7A0E` are called from the home bank) |
| `$05:5075–6E21` | voice player (`$5075–$5161`) and a 7,359-byte 4-bit sample ending in `$80` |

No credit text was found in either region.

```
SWRacer\build_check.sh          # assemble both regions, link over the ROM, compare
SWRacer\harness\build.sh <rom>  # test ROM with the rebuilt banks
SWRacer\harness\verify.py <rom> # play every song/SFX, check every event the driver reads
python tools\swrgen.py <rom> SWRacer   # regenerate the sources (also writes pcm\VoiceSample.wav)
```

---

## 1. API and integration

The game calls the driver with its far-call `rst $20` (inline `dw target`, `db bank`). The driver returns with `rst $28`.

| Entry | Routine | Use |
|---|---|---|
| `$4000` | `Sound_Init` | boot (`$15EE`): rumble off, clear all state, load `MusicWave`, NR52 `$8F`, NR51 `$FF`, NR50 `$77` |
| `$420A` | `Sound_Update` | every VBlank (`$026A`) |
| `$55BF` | `Music_Request` | after `ld [wSong], a` (`$CB0A`); 11 call sites |
| `$55CF` | `Music_FadeOut` | after `ld [wFadeSpeed], a` (`$CB74`, the game uses 5); 13 call sites |
| `$55D5` | `Sfx_Request` | after `ld [wSfxRequest], a` (`$CB92`); 80 call sites |

`Music_RequestNear` (`$55C7`) and `Sfx_RequestNear` (`$5649`) are the in-bank versions the driver uses itself.

**Flags the game sets directly:**

| Variable | Meaning |
|---|---|
| `wSoundEnable` (`$CAFB`) | sound option. When it is 0, the APU is powered off, no music is processed, SFX skip their register writes, and the voice routine only waits |
| `wSoundPause` (`$CAF9`) | pause. The music freezes, the APU is reset with NR51 = `$22` (only ch2 audible: the menu SFX 1–4 and 7 are on ch2), and rumble stops. On release: NR51 = `$DD` and the engine sounds come back on |
| `wSoundKill` (`$CAF7`) | `Sound_Reset` every frame. If SFX 7 was queued, it is queued again |
| `wEngineOn` (`$CBCB`) | racer engine synthesis (§4) |
| `wVoiceRequest` (`$CBF3`) | play the voice sample once (§5); set at `$02:77C7` |

**Update order:** pause/kill handling → music (if `wSong` ≠ 0) → engine (if `wEngineOn`) → SFX watchers → SFX tracks → start queued SFX → rumble → voice → APU power latch.

---

## 2. Music

### 2.1 Songs

`SongTable` (`$575F`) has 11 little-endian entries. Entry 0 is `$0000`, songs 1–10 point to a header:

```
SONG LengthTableN, Song01_Ch1, Song01_Ch2, Song01_Ch3, Song01_Ch4
```

Each channel is a byte stream read by `Music_ReadEvent`. Reading continues until a note, rest, drum or `STOP_MUSIC`. One pointer (`wReadPtr`) is shared and saved back per channel. Channels are processed ch4 → ch1. All ten songs loop: every channel stream ends with a `JUMP` back.

### 2.2 Events

The high nibble selects the handler:

| Byte | Constant | Effect |
|---|---|---|
| `$0n` | `_C … _B`, `_HiC … _HiDs` | note: period = `FreqTable[n + wOctave]`, length − gate frames on, then *gate* frames off. Ch4 uses the period's low byte as NR43; ch3 is always at full level |
| `$1n` | `LENn` | length += `table[n]`, keep reading. **Consecutive `LEN`s add up** (`LEN10, LEN14` = sum); a note or rest closes the sum |
| `$2n` | `RESTn` | rest of `table[n]` frames |
| `$30` | `RESTC` | rest with the current length (low nibble ignored) |
| `$40` / `$41–$4F` | `OCT_UP` / `OCT_DN` | ± 12 semitones |
| `$5n` | `OCTn` | octave n (base 12 × n; 0–7) |
| `$60` / `$61–$6F` | `VOL_UP` / `VOL_DN` | volume ± 1, into the NRx2 high nibble |
| `$7n` | `VOLn` | volume n |
| `$80–$83` / `$84–$87` | `DUTY1_x` / `DUTY2_x` | write NR11 / NR21 duty at once, whichever stream it is in |
| `$90/$91/$92` | `PAN_L/R/LR` | this channel's NR51 bits, written at once |
| `$Bn` | `DRUMn` | ch4 drum (§2.4) |
| `$Cn` | `GATEn` | the last n frames of each note are silent |
| `$Dn` | `PENVn` / `PENV_OFF` | pitch envelope (§2.5) |
| `$An`, `$En`, `$FE` | – | `jr $`: hangs the game. None occur |

`$Fx` commands:

| Byte | Macro | Effect |
|---|---|---|
| `$F0 x` | `ENV x` | NRx2 = x; if x < `$10`, the current volume is kept |
| `$F2` | `LOOP` | push the position (4 slots per channel) |
| `$F3 n` | `ENDLOOP n` | play the block n times in total |
| `$F4 n, addr` | `JUMP_N` | jump to *addr* n times, then fall through. Unused |
| `$F5 addr` | `JUMP` | |
| `$F6` | `STOP_MUSIC` | stop the music and silence it. Unused |
| `$F7` / `$F8` | `FADE_STEP` / `MASTER_RESET` | NR50 − `$11` / NR50 = `$77`. Unused |
| `$F1`, `$F9–$FD`, `$FF` | | no-op |

**Lengths.** Five 15-byte tables at `$719A`, `$71A9`, `$71B8`, `$71C6` (unused) and `$71D3`. Entry 15 reads the next table's first byte. Songs 2, 6, 8 use table 0 (192, 128, 96 … 1 frames); songs 1, 3, 4, 5, 9 use table 1 (176, 128, 88, 66, 44, 33, 22, 16, 11, **0**, 5, **0**, 2, 2, 1); song 10 uses table 2; song 7 uses table 4. The zeros in table 1 only make sense with the additive `LEN`. SFX use table 0.

**Frequency table.** 84 little-endian periods, C2 (`$002C`) to B8. `OCT7` plus a high note would index past it into `EngineFreqA`.

### 2.3 Loops

`LOOP`/`ENDLOOP` keep 4 slots of 4 bytes per channel at `wLoopStack + 16 × channel`. `JUMP_N` keeps its counter at `wLoopStack + 4 × channel`, which is inside **ch1's** loop slots. Mixing the two would corrupt ch1's loops, but no song uses `JUMP_N`.

### 2.4 Drums (`DrumTable`, `$5686`)

`DRUMn` makes ch4 play two noise hits within one note length. The byte is read twice: the first pass rewinds the read pointer, the second moves on.

1. **First hit:** lasts `def[0]` frames. It writes `def[2]` to **both NR42 and NR43**: the code reads the same byte twice. `def[1]` looks like the intended NR42 (`$F1`, `$A1`, …) but is never read.
2. **Second hit:** NR42 = `def[4]`, NR43 = `def[5]`, for the rest of the note length. `def[3]` is never read.

If the channel volume is nonzero, it replaces the NR42 high nibble. Only `DRUM0` and `DRUM1` are used (404 times). `$5690` (3 bytes) and a second copy of `Drum1` at `$569F` are unreferenced.

### 2.5 Pitch envelopes (`PitchEnvTable`, `$56B7`)

The tables hold signed offsets around `$50`, end with `$FF`, and loop. Every frame of a note, the offset is added to the period low byte, with the carry into NRx4, and written straight to the channel without retriggering.

- There is one table pointer and one position for the whole driver, so ch1 and ch2 using envelopes at the same time share and advance the same position.
- Only ch1 and ch2 are handled; on ch3 or ch4 the code would modify ch1.
- `PENV5` and `PENV9–15` point to a lone `$FF`. Selecting one loops forever.

Songs use `PENV1`, `PENV2`, `PENV4` and `PENV8`, on ch1 and ch2 only.

### 2.6 Fade-out

`Music_FadeOut` lowers NR50 by `$11` every (`wFadeSpeed` + 1) × 4 frames. After 8 steps it stops the music. With speed 5 that takes 192 frames.

---

## 3. Sound effects

### 3.1 Requests and the queue

`Sfx_Request` appends `wSfxRequest` to an 8-entry queue (`wSfxQueue`, `$CBB3`, 0-terminated, no bounds check), with special cases:

- `$10` marks the frame; later `$0D`/`$0E`/`$0F` requests in the same frame are dropped and the chain is cleared.
- `$12`, `$1F`, `$20` start a **watcher** (`SfxWatch_Update`). The game must keep requesting them: after 12 updates without a new `$12` the driver plays `$13`, and after 4 without `$1F`/`$20` it plays `$21`. These are "held" sounds with an automatic release sound.
- `$1A` is replaced by `wEngineSfx` (`$1A` or `$1B` by engine volume), or dropped if the rival engine is silent.

The queue is started at the next update (`Sfx_StartQueued`).

### 3.2 SFX header (`SfxTable`, `$6C87`, 40 entries)

```
SFX_HEADER flags, ?, chain, ?     ; flags bit 0: don't restart while playing
SFX_TRACK prio, ?, stream         ; or SFX_NO_TRACK ? (2 bytes), for each of
                                  ; ch1, ch2, ch3, ch4, rumble
```

- **Priority.** A track takes its channel if `prio` ≥ the priority of what is playing there. The SFX it replaces loses its "playing" flag (`wSfxPlaying`, one byte per SFX number).
- **Chain.** When the SFX ends, *chain* is started (1 = none). SFX 13, 14, 15, 31 and 32 chain to themselves, so they repeat until something replaces them; `$10` clears the chain.
- **Rumble track.** The fifth track has no sound. Its notes only time `RUMBLEn` commands. SFX 13–16, 18, 19, 28–33 are rumble-only.

Other hard-coded ids:

- `$0C` makes the next SFX end queue `$24`;
- `$23` and `$22` set and clear `wNoiseHold` (keeps the engine noise from being silenced at standstill);
- `$18` turns the engine sounds off and resets the APU.

SFX 11, 30 and 37–40 have no tracks.

### 3.3 SFX streams

The same nibble scheme as music, with these differences:

- `$An` = `RUMBLEn`: pattern `RumblePatterns[n]` (`$00`, `$24`, `$54`, `$6C`, `$FC`). The pattern byte is rotated every frame, plus 2 extra steps every 7th frame; bit 7 switches the MBC5 rumble motor. `RUMBLE_OFF` stops it at once.
- `$Bn–$En` hang; `$FF` = `SFX_END`; only `$F0` (`ENV`) and `$F5` (`JUMP`) are commands.
- No gate and no pitch envelope.
- At `SFX_END`, NRx2 = 1 (silent) and NR51/NR50 are restored if the engine is off.

**Interaction with music.** Music skips ch1–ch3 while an SFX track owns them, and is heard again from its next note. **Ch4 is not protected:** music notes, drums and gate-offs on ch4 write NR42–NR44 even while a ch4 SFX plays.

---

## 4. Engine sounds (`Engine_Update`, `$4BCE`)

With `wEngineOn` set, the driver synthesises the podracers every frame from the game's racer structures: racer 0 at `$D400` (the player), racer 1 at `$D500` (the rival). It reads offsets `+$7E` (flags), `+$83/$84` and `+$86/$87` (two 16-bit position coordinates, here called A and B) and `+$9D/$9E` (speed).

- **Ch2, rival engine** (skipped when `$D72E` ≥ 4):
  - **Volume.** The distance comes from `ApproxDistance` (home bank `$233A`: max + min / 2 of the two coordinate differences). NR22 volume is 15 − distance / 16, and silent at 256 or more.
  - **Pitch.** From the rival's speed: index = (speed high byte, max 11) × 16 + low byte / 16. It is updated every (12 − high) / 2 frames, and falls by 5 per frame in between, a sawtooth like a revving engine.
  - **Doppler.** `wRivalDoppler` = `$80` ± (coordinate B difference) / 4 is added to or subtracted from the index.
  - **Output.** The period comes from `EngineFreqA` (264 entries, about 3¼ octaves). The channel is retriggered every frame at 12.5 % duty.
  - The bit-3 flag test selects between two `ld hl` that both load `EngineFreqA`.
- **Ch3, player engine:** the same pitch scheme from the player's speed, with `EngineFreqA` if flag bit 3 is set and `EngineFreqB` otherwise. It is played on the music wave and retriggered every frame.
- **Ch4, engine noise:** NR43 = `$20 | wNoiseShift`, NR42 `$40`, retriggered every 3 frames. The shift steps down to 1 while flag bit 0 is set and up otherwise (1, 2, 3, then 5). It is silenced at speed 0 unless `wNoiseHold` is set, and gives way to ch4 SFX.

---

## 5. Voice sample (bank `$05`)

`Voice_Play` saves NR10–NR43 and IE/IF, disables interrupts, and far-calls `$05:5075`. The player sets ch1/ch2 to period `$7FF` (far above hearing, so effectively a DC level), ch3 to an all-`$FF` wave and ch4 to slow noise. It then plays each 4-bit sample by retriggering every channel with that value as its volume (NR32 from a 16-byte level table). A delay loop gives 1,046 cycles per sample: **8,020 Hz in double speed** (4,010 Hz in single speed). That's 14,718 samples, about 1.8 s with the game frozen. Afterwards the registers and the music wave are restored.

With sound off, `$5138` runs the same delays silently, so the game's timing doesn't change. `pcm\VoiceSample.bin` is the raw sample; `pcm\VoiceSample.wav` is an 8,020 Hz decode (nibble × 17).

---

## 6. Quirks

1. **Hangs.** Music `$An`/`$En`/`$FE` and SFX `$Bn–$En` are `jr $` loops; `PENV5`, `PENV9–15` loop on a lone `$FF`. None occur in the data.
2. **Drum first hit** writes the same byte to NR42 and NR43 (§2.4).
3. **One pitch-envelope state** for all channels (§2.5).
4. **`JUMP_N` counters overlap ch1's loop stack** (§2.3).
5. **Ch4 music overrides ch4 SFX** (§3.3).
6. **A note shorter than the gate** plays its full length and then the full gate, so it lasts length + gate frames.
7. **`DUTYx_y` writes the hardware channel it names**, not the stream's channel. Song ch1 streams set ch2 duty twice and ch2 streams set ch1 duty three times.
8. **Pause** writes `wSoundPause` into the ch4 SFX timer every paused frame, so a ch4 SFX advances one event per frame while paused.
9. **`wSoundKill` with sound off** still calls `Sfx_RequestNear` with whatever `wSfxRequest` holds.
10. **The rival's engine table choice** has two identical branches (§4).
11. **Unused variables:** `wDebugLY` (LY at update start), and several bytes only cleared or set at init (`$CAF2/3/5/6`, `$CAFE`, `$CB0D–10`, `$CB25–28`, `$CB95–99`, `$CBC9`, `$CBCC/D`, `$CBD0/1`, `$CBE7–EA`, `$CBEE/F`).
12. **Unreferenced data:** `$5690` (3 bytes), the duplicate drum at `$569F`, `LengthTable3`, and two unreachable `ret` bytes in the code (`$473A`, `$54C0`).

---

## 7. Verification

- **Byte-exact rebuild** of `$03:4000–76A9` and `$05:5075–6E21` (`build_check.sh`; also compared without the overlay).
- **Emulator harness** (`harness\`): a CGB ROM that links the **rebuilt** banks. The home-bank routines the driver calls (far call/return, bank switch, rumble, distance) are copied from the original ROM at their own addresses. The update runs from an LYC interrupt through the game's own far call. `verify.py` (PyBoy) plays every song for 7,200 frames and every SFX for 600 frames, with PC hooks on the event reads of `Music_ReadEvent` (`$4552`) and `Sfx_ReadEvent` (`$510D`).

  | | Read outside the parse | Events read |
  |---|---|---|
  | Songs 1–10 | 0 | 4,936 / 4,936 |
  | SFX 1–40 | 0 | 484 / 500 |

  It also runs a fade-out (the song stops after the 8th step), the engine with test racer values (rival volume `$D0` for a distance of `$20`, as computed in §4), and the voice sample (the driver resumes and the request is cleared).
- **Not verified:** how the engine and rumble sound or feel (no hardware), the meaning of the racer-structure fields (named from their use here), the game contexts of the songs, and what the voice clip says. Listen to `VoiceSample.wav`.

## Files (`MM-SWR\SWRacer`)

| File | Content |
|---|---|
| `SWR_Bank03.asm` | bank `$03` section: `SWR_Driver.inc` + `SWR_Data.inc` |
| `SWR_Driver.inc` | driver code, labelled, with comments on the entry points |
| `SWR_Data.inc` | drums, pitch envelopes, song table and songs, SFX table and SFX, wave, length/frequency/engine tables |
| `SWR_Voice.asm`, `pcm\` | bank `$05` voice player, raw sample, WAV |
| `SWR_Macros.inc`, `SWR_RAM.inc`, `GB_Hardware.inc` | constants and macros, RAM map `$CAF0–$CC40` plus the game variables and home-bank routines used |
| `tools\` | `swrgen.py`, `swrparse.py`, `swrnames.py`, `swrram.py`, `gbdis.py`, `emit.py`, `hwinc.py` |
| `harness\` | `harness.asm`, `build.sh`, `verify.py` |
