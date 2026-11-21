# The Smurfs (GB): sound driver

ROM: `Smurfs, The (UE) (V1.0) (M4) [!].gb` (DMG, MBC1, 128 KB, internal title `SMURFS`). Infogrames, 1994.

Part of the AJG family (Alberto José González / Bit Managers), see `AJG_SoundEngine_Family.md`. This is **version 4**, the reference for the two Astérix & Obélix builds documented with it (`Obelix_SoundDriver.md`). Version 4 keeps version 3's ideas (one RAM page per channel, order lists, command-macro instruments, drum sequencer with drum sounds as code, SFX on CH3) but is reorganised throughout:

- The driver opens its bank with an **API jump table**.
- The command table and the period table are **page-aligned**.
- **Pulse channels use hardware envelopes only**; the software envelope is left to CH3 and the SFX page.
- Vibrato and the new slides work on a **16-bit pitch offset** instead of the period.
- The old `LEN` range has given way to a **`REPEAT n` loop**, and `VOL` became a command.
- `ORDER_JUMP`, `PORTA`, `ENV_DIV` and `NOTE_PAN` are gone. `REPEAT_END`, `VOL`, `SLIDE_UP` and `SLIDE_DOWN` are new.

| | |
|---|---|
| Bank | the driver and all its data fill **ROM bank 6** (`$4000–$7FFF`) |
| API | jump table at `$4000`: `SndUpdate`, `SndPause`, `SndResume`, `StopAll`, `PlaySfx` (A = id), `SndInit`, `SongFadeIn`, `SongFadeOut` (A = speed), then **19 song entries** (`$4018–$404E`) |
| Tick | **VBlank**, every frame (59.73 Hz). The game's VBlank handler (`$1507`, bank 0) switches to bank 6, plays the SFX id posted in `$D942` (if not `$FF`) through `PlaySfx`, calls the address posted in `$D95A/$D95B` (how songs are started), then `SndUpdate` |
| RAM | four `$100`-byte pages: Ch1 `$C1xx`, Ch2 `$C2xx`, Ch3 `$C3xx`, SFX `$C4xx` (fields `$00–$3B`); globals `$C196–$C1B9`, in the unused upper part of page `$C1` |
| Channels | music on CH1–CH3; SFX on **CH3** (the SFX page replaces Ch3 in the output); CH4 from the drum sequencer and noise routines |
| Counts | 19 songs + **2 jingles outside the song table**, 29 SFX streams + 3 noise-only SFX, 11 instrument tables (2–6 instruments each), 1 arpeggio table (27), 24 waves, 11 drum sounds (10 used) + 5 noise routines called with `CALL_CODE`, 37 drum patterns |

`Smurfs_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over the whole of bank 6 (`6:4000-7FFF`; nothing in bank 0 is needed). It assembles cleanly with `-Wall` and needs no `hardware.inc`.

```
rgbasm -Wall -o smurfs.o Smurfs_SoundDriver.asm
rgblink -o smurfs.gb smurfs.o
python tools/cmp_banked.py smurfs.gb "Smurfs, The (UE) (V1.0) (M4) [!].gb" 6:4000-7FFF
```

---

## 1. Structure

`SndUpdate`:

1. If `wPaused` (`$C196`): NR50 fade, tick and output **only the SFX page**, NR51; done.
2. `ChannelTick` on Ch1, Ch2, Ch3, SFX; `DrumTick` (drum hold, drum timer → `DrumStep`, noise-sequence step).
3. Output: Ch1, Ch2, then **the SFX page if it plays (`$C427` ≠ 0), otherwise Ch3**.
4. NR51 = Ch1 field `$38` | Ch2 `$38` rotated 1 | (SFX or Ch3) `$38` rotated 2 | `wNoisePan`, but **`$FF` while `wStereo` (`$C197`) = 0**. The game sets `wStereo` itself, the driver never does.
5. `DoFade` (NR50).

`SndInit` sets NR52 = `$FF`, the arpeggio table (`$758B`, used by every song), clears a few flags and falls into `StopAll`. `StopAll` silences CH1–CH4 (NRx2 = 0, NRx4 = 0), turns the fade, drums and noise sequence off, centres the noise pan and resets the four pages.

`SndPause` silences CH1, CH2, CH4 and also CH3 when no SFX is playing (NRx2 = 0, trigger), then sets `wPaused`. `SndResume` clears it and reloads the music wave.

### 1.1 Output

- **Pulse pages:** NRx3 = period low + pitch offset (fields `$25/$26`). NRx4 = the high byte, without a trigger, whenever it differs from the shadow (`$07`). When the envelope flag `$33` is set, NRx2 = field `$32` and NRx4 = high | `$80` (retrigger), then the flag is cleared. **There is no software volume on the pulse channels:** the flag is only set at a note on (NRx2 = the `HWENV` value), by the second `HWENV` value, by `RELEASE`, by `REST` (NRx2 = 0) and by `ResetChannel`.
- **CH3 (Ch3 or SFX page):** the same period, then NR32 = `Ch3VolTable[volume]` (`00 ×4, 60 ×4, 40 ×4, 20 ×4`) when it differs from `wShNR32`.

### 1.2 Channel fields

| Off | Use |
|---|---|
| `$00/$01` | order position |
| `$02/$03` | stream pointer |
| `$04` | flags: b0 arpeggio, b1 release armed, b2 released, b3 vibrato/slide on, b4 direction (1 = up), b5 slide (keep the direction at note on), b6 set by `VIBRATO` (not read) |
| `$05/$06`, `$07` | period, period-high shadow |
| `$08` | volume 0–15 (CH3/SFX pages) |
| `$09`, `$0A` | length, ticks left |
| `$0B` | glide (added to the note every tick) |
| `$0C` | note |
| `$0D` | channel transpose (default −12, `CH_TRANSPOSE n` stores n − 12) |
| `$0E` | arpeggio offset |
| `$0F` | global transpose (copied into the three music pages by `TRANSPOSE`) |
| `$10`, `$13`, `$16`, `$17` | `VOLENV` attack byte, decay byte, start volume, decay-rate backup |
| `$11/$12`, `$14/$15` | attack steps / step size, decay steps / step size (split at note on) |
| `$18/$19`, `$1A/$1B` | attack / decay rate counter and reload |
| `$1D/$1E`, `$1F` | arpeggio pointer, index |
| `$20–$24` | vibrato: delay reload, delay counter, depth, counter, speed |
| `$25/$26` | pitch offset (16-bit, added to the period at output) |
| `$27` | active; on the SFX page the SFX id (`$C427`) |
| `$28`, `$29/$2A`, `$2B` | `HWENV` value, 2nd-envelope delay reload / counter, 2nd value |
| `$2C–$2E`, `$2F–$31` | auto-pan, auto-duty: period / counter / step |
| `$32`, `$33` | NRx2 value to write, write flag |
| `$34`, `$35` | `RELEASE` t (min length << 4 \| ticks left), env |
| `$36/$37` | `PAT_CALL` return address (one level; `$37` ≠ 0 = pending) |
| `$38` | pan bits for NR51 (`$11` centre, `$01` right, `$10` left; rotated per channel) |
| `$39`, `$3A/$3B` | `REPEAT` count, position (one level) |

### 1.3 Globals (`$C196–$C1B9`)

`wPaused` `$C196`, `wStereo` `$C197`, `wShNR32` `$C198`, `wInInstr` `$C199` (`$C9` while an instrument macro runs), `wNoisePan` `$C19A`, `wDrumHold` `$C19B`, `wInstrTable` `$C19C/9D`, `wArpTable` `$C19E/9F`, `wMusicWave` `$C1A0/A1`, `wNoiseAutoPan` `$C1A2`. Drums: pattern `$C1A3/A4` (**hi byte first**), position `$C1A5`, on `$C1A6`, tempo `$C1A7`, timer `$C1A8`, repeat count `$C1A9`, repeat position `$C1AA`. Noise sequence: NR43 / NR42 table pointers `$C1AB–$C1AE` (hi first), position `$C1AF`, on `$C1B0`, level `$C1B1`, timer `$C1B2`, speed `$C1B3`. Fade: table `$C1B4/B5`, position `$C1B6`, timer `$C1B7`, speed `$C1B8`, on `$C1B9`.

---

## 2. One tick (`ChannelTick`, active pages only)

1. auto-duty, 2. auto-pan, 3. ticks left − 1 → at 0 read the stream, 4. arpeggio, 5. **period**: note += glide, index = note + channel transpose + arpeggio offset + global transpose (≥ 80 → 0) → `PeriodTable`, 6. envelope, 7. release check, 8. vibrato/slide.

The stream is read **before** the effects, so a note's first tick already has its glide step, arpeggio step and period.

- **Auto-duty** (`AUTODUTY n`): every n ticks the next of 50, 75, 12.5, 75, 50 % (repeating). It writes NR11 on the Ch1 page and **NR21 on any other page**. `INSTR` turns it off. **Auto-pan** (`AUTOPAN n`): centre, right, centre, left, centre (repeating).
- **Arpeggio:** the next table byte goes into field `$0E`; `$6A` (the `NEXT` byte) loops, `$FF` holds.
- **Envelope:** pulse pages count down to the second `HWENV` value. CH3/SFX pages run the software envelope: the attack adds its step every attack-rate ticks (max 15) for its step count, then the decay subtracts its step every decay-rate ticks (min 0).
- **Release** (`RELEASE t, env`, t = `$mT`): skipped for notes whose length is below m. On the tick where ticks left = T, unless the next stream byte is `WAIT` (`$65`), a pulse page writes NRx2 = env. CH3/SFX pages set the decay rate = env & `$0F` and, if env >> 4 ≠ 0, volume = env >> 4. `WAIT2` (`$62`) is a tie that does not stop the release. A note on restores the decay rate from `$17`.
- **Vibrato** (`VIBRATO delay, depth, speed`): after the delay, the pitch offset moves by depth per tick, up while b4 is set and down while it is clear, and the direction flips every speed ticks. At a note on the offset is cleared, the counter starts at speed / 2 and the direction is down, so it swings around the note's period.
- **Slides** (`SLIDE_UP n` / `SLIDE_DOWN n`) use the same code with no delay, speed 1 and b5 set. At a note on the counter starts at 1 >> 1 = 0, so the first decrement wraps to 255: **the pitch offset moves n per tick, up or down, for 255 ticks from every note**. A slide set in the middle of a note does nothing until the next note. `VIB_OFF` clears b3/b4 but not b5.

**Note on** (byte < `$60`): store the pointer and the note, arpeggio index 0, ticks left = length, pitch offset 0, restart the vibrato, re-arm the release. CH3/SFX pages also split the envelope bytes and set volume = start volume. Pulse pages queue NRx2 = `HWENV` value and start the second-envelope timer.

---

## 3. Data format

### 3.1 Songs

A song is started by a routine in the data area: set `wInstrTable` (if the song uses instruments), then `StartMusicCh1/2/3` with an order list each. `StartMusicChN` resets the page, marks it active and starts the first pattern; `StartMusicCh3` also stops the fade and the drums and sets NR50 = `$77`. Order lists are `dw pattern …, 0, loop_position`; several songs have one-entry lists whose pattern ends with `END`.

| Song (API entry) | Routine | Ch1 / Ch2 / Ch3 order lists | Instr. table | Length (ticks) |
|---|---|---|---|---|
| 1 (`$4018`) | `$5D7E` | `$5D9A / $5DAA / $5DB2` | 4 | loops |
| 2 | `$4EAD` | `$4EC9 / $4EFD / $4EE5` | 2 | loops |
| 3 | `$710D` | `$7129 / $712D / $712B` | 11 | loops |
| 4 | `$4B2D` | `$4B49 / $4B57 / $4B65` | 1 | loops |
| 5 | `$6561` | `$657D / $658B / $6599` | 7 | loops |
| 6 | `$6D4D` | `$6D69 / $6D6B / $6D6D` | 10 | loops |
| 7 | `$5ABF` | `$5ADB / $5ADD / $5ADF` | 3 | loops |
| 8 | `$6106` | `$6122 / $6132 / $612C` | 5 | loops |
| 9 | `$52F7` | `$5309 / $5317 / $531F` | – | loops |
| 10 | `$637C` | `$6398 / $63A2 / $63AA` | 6 | loops |
| 11 | `$68E5` | `$6901 / $6921 / $690D` | 8 | loops |
| 12 | `$6BC1` | `$6BDD / $6BF1 / $6BEF` | 9 | loops |
| 13 | `$55C3` | `$55D5 / $55D7 / $55D9` | – | 238, ends |
| 14 | `$5649` | `$565B / $565D / $565F` | – | 168, ends |
| 15 | `$5797` | `$57A9 / $57AB / $57B5` | – | loops |
| 16 | `$56DA` | `$56EC / $56EE / $56F0` | – | loops (uses `FADE`) |
| 17 | `$4DA3` | `$4DB5 / $4DB7 / $4DB9` | – | loops |
| 18 | `$5927` | `$5939 / $5943 / $5945` | – | loops |
| 19 (`$404E`) | `$73E2` | `$73F4 / $73F6 / $73F8` | – | loops |
| **Jingle 1** | `$7DF3` | `$7E05 / $7E07 / $7E09` | – | 224, ends |
| **Jingle 2** | `$7ECD` | `$7EDF / $7EE1 / $7EE3` | – | 168, ends |

Songs are numbered by their API entry (song n = entry `$4018 + 3(n − 1)`). Songs without an instrument table use no `INSTR` (they keep whatever table was set, but never read it). **All songs use the arpeggio table `$758B`** set by `SndInit`; no song sets one.

**The two jingles** are complete song routines in the same bank (`$7DF3`, `$7ECD`, on either side of SFX 2's stream at `$7E99`) with their own order lists, patterns and drum patterns. **They are not in the API song table**, and nothing in bank 6 refers to them. The game starts them by posting the routine address straight into its song mailbox (`$D95A/$D95B`) from bank 0: Jingle 1 at `$1A1E` (in a stage-start sequence) and Jingle 2 at `$1DB1` (before a counting loop). A converter that only walks the API table misses them. Both play to an `END` on all channels (224 and 168 ticks). They use only `HWENV`, `VIBRATO`, `ARP`, `DUTY_*`, `WAVE`, `DRUMS` and plain notes (no instruments), and both drum patterns end in zero steps without a `DRUM_LOOP`. In the asm they are `PlayJingle1` / `PlayJingle2`.

Instrument tables (address order): 1 `$4D90` (2 instruments), 2 `$52DB` (3), 3 `$5D65` (3), 4 `$609F` (3), 5 `$6360` (3), 6 `$654F` (2), 7 `$68B5` (5), 8 `$6B0E` (5), 9 `$6D2D` (3), 10 `$70DB` (6), 11 `$73D0` (2). `INSTR n` reads entry n + 1 (entry 0 is never read).

### 3.2 Stream bytes

| Byte | Macro | Meaning |
|---|---|---|
| `$00–$5F` | `NOTE p, o` | note, ends the read |
| `$60 n` / `$61` | `GLIDE n` / `GLIDE_OFF` | note += n every tick |
| `$62` | `WAIT2` | wait one length; the release still happens |
| `$63 d, depth, speed` / `$64` | `VIBRATO` / `VIB_OFF` | §2 |
| `$65` | `WAIT` | wait one length (tie); suppresses the release |
| `$66` | `REST` | volume 0 (pulse: NRx2 = 0), wait |
| `$67` | `STOP_ALL` | `StopAll` (unused by the data) |
| `$68` | `END` | reset the page (channel stops); SFX page: reload the music wave |
| `$69 n` | `TRANSPOSE n` | global (field `$0F` of the three music pages) |
| `$6A` | `NEXT` | return from `PAT_CALL`, else next order entry |
| `$6B n` | `LENGTH n` | length n (any value; `LEN` covers 1–48) |
| `$6C t, w` / `$6D` | `DRUMS` / `DRUMS_OFF` | drum pattern w, one step every t ticks (§4.1) |
| `$6E` / `$6F` / `$70` | `PAN_C/R/L` | |
| `$71` / `$72` / `$73` | `DUTY_50/75/12` | NR11 on the Ch1 page, NR21 on any other page |
| `$74 e, 0` / `$74 e, t, e2` | `HWENV` | pulse NRx2 at each note on; NRx2 = e2 after t ticks |
| `$75 n` / `$76 n` | `AUTOPAN` / `AUTODUTY` | §2 |
| `$77 s, w` / `$78` | `FADE` / `FADE_OFF` | NR50 table w, one byte every s + 1 ticks (§4.3) |
| `$79 w` | `WAVE w` | Ch3: remember w, load it unless an SFX plays; other pages: load w |
| `$7A n` | `CH_TRANSPOSE n` | |
| `$7B 0` / `$7B t, env` | `RELEASE` | §2 |
| `$7C` | `ARP_OFF` | |
| `$7D w` / `$7E w` | `PAT_GOTO` / `PAT_CALL` | `PAT_CALL` is one level deep |
| `$7F w` | `CALL_CODE w` | call machine code at w (returns into the command loop) |
| `$80` | `REPEAT_END` | §3.3 |
| `$81 n` | `VOL n` | start volume (CH3/SFX) |
| `$82 n` / `$83 n` | `SLIDE_UP` / `SLIDE_DOWN` | §2 |
| `$84–$8D` | `INSTR n` | instrument n (0–9) of `wInstrTable` |
| `$8E–$A8` | `ARP n` | arpeggio 0–26 |
| `$A9–$B8 a d r` | `VOLENV v, atk, dec, rates` | start volume v + envelope (CH3/SFX pages) |
| `$B9–$E8` | `LEN n` | length 1–48 |
| `$E9–$FF` | `REPEAT n` | n = 2–24 (§3.3) |

Not used by the data: `VIB_OFF`, `STOP_ALL`, `FADE_OFF`. `SLIDE_UP` is used once (by an SFX).

### 3.3 Repeats

`REPEAT n` (byte − `$E7`) stores n and the position after it; `REPEAT_END` decrements the count and jumps back while it is not 0, so the enclosed bytes play n times. One level per page (fields `$39–$3B`), not saved by `PAT_CALL`. The data uses 112 of them.

### 3.4 Instruments and arpeggios

`INSTR n` clears the arpeggio, glide, arpeggio offset and auto-duty, sets 50 % duty on CH1/CH2 (straight to NR11/NR21), then runs the macro **until `END` (`$68`)**; `NEXT` no longer ends a macro. Macros contain commands only. Here they use `HWENV`, `VOLENV`, `ARP`, `DUTY_12/75`, `AUTODUTY`, `GLIDE`, `CH_TRANSPOSE` and `PAN_C`. Unlike version 3, instruments do not reset vibrato, auto-pan or the pan.

Arpeggios are offset lists ending in `$6A` (loop) or `$FF` (hold); the table has 27 entries, all used.

### 3.5 Sound effects

`PlaySfx` (A = id 1–29): **ignored while a lower id plays** (equal or higher ids restart). It resets the SFX page and points it at the stream from `SfxTable` (`$769F`, indexed from `$769D`). Its first tick happens in the next `SndUpdate`, not inside the call as in version 3. The API entry goes through the game's glue at `$7F82` first:

- ids `$1E`, `$1F`, `$20` (30–32) start the noise routines `$797A`, `$7A8B` and `$7910` (noise only, `wDrumHold` 50 / 25 / 20 ticks);
- id `$1C` (28) skips the priority test;
- the rest go to `PlaySfx`.

An older copy of this glue sits unused at `$4051`.

SFX streams use `WAVE`, `LEN`, `LENGTH`, `VOL`, `VOLENV`, notes, `WAIT`, `REST`, `GLIDE`, `GLIDE_OFF`, `ARP`, `VIBRATO`, `SLIDE_UP/DOWN`, `CH_TRANSPOSE`, `CALL_CODE` and `END` (no instruments).

| Id | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 36 | 72 | 28 | 24 | 50 | 10 | 46 | 25 | 10 | 10 | 20 | 31 | 8 | 30 | 30 | 16 |

| Id | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 | 30\* | 31\* | 32\* |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 14 | 5 | 8 | 4 | 12 | 13 | 24 | 12 | 11 | 40 | 26 | 44 | 30 | 28 | 5 | 7 |

\* noise sequence length.

### 3.6 Waves

24 waves are referenced. Three of them overlap (`$7B9D`, `$7BA4`, `$7BAD`: each starts inside the previous one). **SFX 28 loads its wave from `$4176`**, which is driver code (the start of `ChannelTick`, written `WAVE ChannelTick` in the asm), so it plays 16 code bytes as a waveform. Two more 16-byte blocks (`$7ABD`, `$7AFD`) look like unreferenced waves. Loading: NR30 = 0, copy, NR30 = NR34 = Ch3 period-hi shadow | `$80`.

---

## 4. Noise and fades

### 4.1 Drum sequencer

`DRUMS t, w`: one step every t ticks. A step reads pattern bytes until a `0` or a drum sound:

| Byte | Asm | Meaning |
|---|---|---|
| `$00` | `0` | end of step |
| `$01–$31` | `n` | drum sound n from `DrumTable` (`$49FD`), ends the step; skipped while `wDrumHold` runs |
| `$32` / `$33` / `$34` | `DRUM_PAN_C/R/L` | noise pan (R/L ignored while `wDrumHold` runs) |
| `$35 n` | `DRUM_AUTOPAN n` | noise auto-pan: centre, right after n noise steps, left after 2n, centre after 3n |
| `$36` | `DRUM_REPEAT_END` | repeat count − 1; while not 0, back to the repeat position |
| `$37–$46` | `DRUM_LEVEL + n` | noise level n (attenuation 15 − n) |
| `$47–$5A` | `DRUM_SPEED + n` | noise sequence speed (one step every n + 1 ticks) |
| `$5B–$B8` | `DRUM_REPEAT + n` | repeat the following bytes n times (new) |
| `$B9–$FE` | `DRUM_TEMPO + n` | drum tempo = n (new; also reloads the timer) |
| `$FF` | `DRUM_LOOP` | back to the start |

Drum sounds and the `CALL_CODE` noise routines are **code in the data area** that sets the noise-sequence pointers and starts it. The `CALL_CODE` ones also set `wDrumHold`.

| Drum | Routine | NR43 sequence | NR42 sequence |
|---|---|---|---|
| 1 | `$7C6F` | `02 51 61 71 91 71 60` | `F0 F0 D0 90 70 40 31` |
| 2 | `$7CB4` | `60 52 42 41 22 11 04` | `F0 F0 F0 A0 70 40 51` |
| 3 | `$7CE0` | `50 41 50 51 52 53 51` | `F0 70 F0 70 D0 70 83` |
| 4 | `$7CFD` | `04 02 06 06` | `C0 80 60 44` |
| 5 | `$7D1A` | `04 02 01 01 04 02 01` | `A0 60 33 23 A0 60 33` |
| 6 | `$7D37` | `04 02 01 01` | `80 40 30 23` |
| 7 | `$7D54` | `06 04 03 03 07` | `F0 C0 80 60 55` |
| 8 | `$7C8C` | `04 02 01 00 00` | `40 60 70 82 71` |
| 9 | `$7D71` | `51 32` | `F0 72` |
| 10 | `$7D93` | `51 32` | `90 61` |
| 11 | `$7DB0` | `51 32 32 32 32 51 32` | `80 51 FF FF FF 80 51` (unused drum) |

`CALL_CODE` routines: `$7946` (NR42 = `$F1` directly, NR43-only sequence, hold 10), `$79DA` (hold 15), `$7A10` (hold 10), `$7A46` (hold 50), `$7C67` (hold 8, then drum 1).

### 4.2 Noise sequences

Every speed + 1 ticks: NR43 = `seq43[i]`; with an NR42 table also NR42 = `seq42[i]` − level << 4 (level ignored while `wDrumHold` runs; on underflow only the envelope bits are kept) and NR44 = `$80`. **`$FF` in the NR42 table means "no write" this step** (new). `$FF` in the NR43 table ends the sequence. The `$35` auto-pan is applied here.

### 4.3 NR50 fades

`SongFadeOut` / `SongFadeIn` (A = speed) and `FADE`: one table byte into NR50 every speed + 1 ticks; `$6A` loops, `$FF` ends. Tables: `FadeOutTable` `$7DE1` (`77 66 … 00 FF`), `FadeInTable` `$7DEA` (`00 11 … 77 FF`). **While no fade runs, NR50 is forced to `$77` every tick unless it is 0**, so a finished fade-out stays silent. The game fades out with speed 5.

---

## 5. Timing

59.73 Hz, one tick per frame. Songs 13 and 14 and both jingles are one-shot; the other songs loop.

---

## 6. Quirks and bugs

1. **SFX 28 loads 16 bytes of driver code as its wave** (`WAVE $4176`, §3.6).
2. **Drum pattern `$56C8` (song 14) has no `$FF`**: it runs into the next song routine. Song 14 turns the drums off on the tick its last step is read, so the next byte is never read. The two jingles' patterns also have no `$FF`, but they end in zero steps.
3. **Slides last 255 ticks** after each note (the counter starts at 0), and a slide set mid-note waits for the next note. `VIB_OFF` leaves the slide's "keep direction" bit set, so a later `VIBRATO` would not reset its direction at note on.
4. **Auto-duty and `DUTY_*` on the Ch3/SFX page write NR21** (CH2's duty).
5. **`STOP_ALL` from a stream** resets every page and returns into `ReadStream` with H = the SFX page (unused by the data).
6. **Ending an SFX resets the noise timer and speed** (`wNoiseTimer`, `wNoiseSpeed`), which also affects a running drum's noise sequence.
7. `ResetChannel` leaves `REPEAT` and `RELEASE` data and the `HWENV` value; only the flags are cleared.
8. **Dead code/data:** the old glue at `$4051`, x86 assembler leftovers at `$4361–$43FF` and `$7F9D–$7FFF`, a stray `ret` at `$447E`, `$47D1–$47FF` before the period table, drum 11, an unreferenced drum pattern (`$60FF`), two unreferenced SFX-like streams (`$7806`, `$7860`) and two wave-sized blocks (marked "Unreferenced" in the asm).

---

## 7. Verification (lighter)

- **Byte-exact rebuild** of bank 6 (`tools/cmp_banked.py`).
- **Emulator trace** (`verify/v4trace.py`): the real driver runs in PyBoy from a harness written over the game's start-up code. Every song and both jingles (6000 ticks) and every SFX (1–32, through the API entry and the game's glue) are started after `StopAll`. On every tick, the saved stream pointer and order position of each active page must fall on items of the data walk that generated the asm, and every byte the drum sequencer reads must be a drum-pattern byte. **0 problems** (`verify/run_v4.log`). This checks the command lengths, terminators, repeats, order lists and drum patterns that the asm encodes, and gives the lengths above.
- **Not done:** no independent model of the driver, so effects, envelopes and output are documented from the code, not cross-checked tick by tick.

## Files (in `GBAudioLab\AJG`)

- `Smurfs_SoundDriver.asm`: labelled, commented RGBDS source with data macros, byte-exact
- `tools/`: `gen_v4.py` (generator for all three version-4 builds), `v4cfg.py` (command sets and per-game constants), `v4data.py` (data walker), `v4names.py` (Smurfs names and comments, carried over to Obélix by code alignment), `v4games.py`, `v4diff.py` (normalised code diff between two v4 drivers), `blist.py` (banked listing)
- `verify/`: `v4trace.py`, `run_v4.sh`, `run_v4.log`

Regenerate: `python tools/gen_v4.py smurfs "Smurfs, The (UE) (V1.0) (M4) [!].gb" Smurfs_SoundDriver.asm` (from the `AJG` folder).
