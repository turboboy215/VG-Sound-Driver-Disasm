# Bomb Jack (GB): sound driver

ROM: `Bomb Jack (U).gb` (DMG, no MBC, 32 KB, internal title `BOMB JACK`). Infogrames, 1992.

Part of the AJG family (Alberto José González / Bit Managers), see `AJG_SoundEngine_Family.md`. This is **version 2**: the same design as Pop Up's driver, but rewritten in many places (a different command layout, direct register addresses, per-song instrument tables, a drum sequencer, NR50 fades, pattern calls).

| | |
|---|---|
| API | `$5BE2` `SndInit`, `$5E69` `PlaySfx` (A = id 1–14, keeps all registers), `$57F0` `StopAll`, `$5B0E` `StartFade` (A = speed, HL = NR50 table). Songs: `$60FB` `PlaySong1`, `$642E` `PlaySong2`, `$64E6` `PlaySong3`, `$6584` `PlaySong4`, `$743E` `PlaySong5`; the game calls 2–4 through the jump vectors `$60F8/$60F5/$60F2`. The game also calls `$5A02` (a noise hit) directly |
| Tick | **VBlank**, every frame (59.73 Hz): the game's VBlank handler calls `SndUpdate` (`$54EE`) at `$0316` |
| Driver code + data | `$54EE–$7A00`: code `$54EE–$5E68` and `$5E69–$5EDE`, tables `$5EDF–$6068`, channel init `$6069–$608C`, songs (their start routines sit between the song data) `$608D–$7A00` |
| RAM | four `$100`-byte pages: Ch1 `$C4xx`, Ch2 `$C5xx`, Ch3 `$C6xx`, SFX `$C7xx` (fields `$00–$3C`); globals `$C318–$C338` |
| Channels | music on CH1, CH2, CH3; SFX on **CH3** (the SFX page replaces Ch3 in the output). CH4 is driven by the drum sequencer, noise sequences and noise hits, not by a page |
| Counts | 5 songs, 14 sound effects, 2 instrument tables × 26, 2 arpeggio tables × 5, 5 waves, 3 noise sequences, 7 drum sounds |

`BombJack_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over ROM0 `$0000–$0002`, `$0018–$001D`, `$0020–$0026`, `$0316–$0318`, `$1470–$1478` and `$54EE–$7A00`. It assembles cleanly with `-Wall` and needs no `hardware.inc`.

```
rgbasm -Wall -o bombjack.o BombJack_SoundDriver.asm
rgblink -t -o bombjack.gb bombjack.o
python tools/cmp_ranges.py bombjack.gb "Bomb Jack (U).gb" 0000-0002 0018-001D 0020-0026 0316-0318 1470-1478 54EE-7A00
```

---

## 1. Structure

`SndUpdate`:

1. NR52 = `$80`.
2. `DoFade` (§4.3).
3. `ChannelTick` on Ch1, Ch2, Ch3, SFX.
4. Drum timer: `wDrumTimer` − 1; at 0, one drum step (§4.1). Then one noise-sequence step (§4.2).
5. `OutputAll`: Ch1, Ch2, then **the SFX page if it's active, otherwise Ch3**.

`SndInit` copies a 12-byte init block into fields `$00–$0B` of each page and clears `$0C–$3C`. Fields `$06/$08/$0A` hold the **I/O addresses** of NRx3/NRx4/NRx2 (`$13/$14/$12`, `$18/$19/$17`, `$1D/$1E/$1C`; the SFX page gets Ch3's). Writes go straight to `$FF00 + field`; there's no handler table as in version 1. Then NR51 = `$FF` and `StopAll`.

### 1.1 Output (`OutputChannel`)

- NRx3 = period low, every tick.
- NRx4 = period high (**no trigger**), only when it differs from the shadow `wShFreqHi + (page − $C4)`: `$C318/$C319/$C31A`, and for the SFX page `$C31B`, which is also the NR32 shadow (§6.2).
- **Software volume** (field `$27` = 0):
  - pulse channels: NRx2 = vol << 4 (no envelope) and a **retrigger every tick** (NR14 = `$C318` | `$80` for Ch1, NR24 = `$C319` | `$80` for everything else);
  - CH3: NR32 = `Ch3VolTable[vol]` (mute/25/50/100 %) when it differs from `$C31B`, no retrigger.
- **Hardware envelope** (field `$27` ≠ 0, set by `HWENV`): only when field `$32` is set: NRx2 = field `$31` and the same retrigger as above. Field `$32` is set by `HWENV`, at each note in this mode, by the second envelope, by `RELEASE` and `REST`, and by `ResetChannel`.

### 1.2 Channel fields

| Off | Name | Use |
|---|---|---|
| `$00/$01` | order | order list position |
| `$02/$03` | ptr | stream pointer |
| `$04` | flags | b0 arpeggio, b1 release armed, b2 released (once per note), b3 vibrato, b5 (old chorus bit, unused), b6 vibrato direction |
| `$05` | len | ticks left |
| `$06/$07`, `$08/$09`, `$0A` | | NRx3 address / period low, NRx4 address / period high, NRx2 address |
| `$0B` | vol | current volume 0–15 |
| `$0C` | note | |
| `$0D` | length | note length in ticks |
| `$0E` | glide | added to the note every tick |
| `$0F` | | channel transpose (`CH_TRANSPOSE`) |
| `$10` | active | 0 = idle; on the SFX page this is `wSfxId` (`$C710`) |
| `$11`, `$12/$13` | attack | `VOLENV` byte; lo → count, hi → step |
| `$14`, `$15/$16` | decay | same |
| `$17` | vol0 | start volume of each note |
| `$18/$19`, `$1E/$1F` | | release phase of the envelope: never set (§6.4) |
| `$1A/$1B`, `$1C/$1D` | | attack / decay rate counter and reload |
| `$1F/$20`, `$21` | | arpeggio pointer, index |
| `$22`–`$26` | | vibrato: delay counter, depth, counter, speed, delay |
| `$27`, `$28/$29`, `$2A` | | `HWENV`: envelope byte (0 = software volume), env2 delay / counter, env2 |
| `$2B/$2C/$2D` | | auto-pan period / counter / step |
| `$2E/$2F/$30` | | auto-duty period / counter / step |
| `$31`, `$32` | | NRx2 value to write, write flag |
| `$39`, `$3A` | | `RELEASE` ticks-left point, release envelope |
| `$3B/$3C` | | `PAT_CALL` return address (one level, 0 = none) |

### 1.3 Globals (`$C318–$C338`)

Period-hi shadows `$C318–$C31A`, `wShNR32` `$C31B`, `wInInstr` `$C31C` (`$C9` while an instrument macro runs), `wTranspose` `$C31D`, `wShNR51` `$C31E`, `wInstrTable` `$C31F/20`, `wArpTable` `$C321/22`, `wMusicWave` `$C323/24`, fade `$C325/26` (table), `$C335` (position), `$C336` (timer), `$C337` (speed), `$C338` (on). Drums: `$C327/28` (pattern, **hi byte first**), `$C329` (position), `$C32A` (on), `$C32B` (tempo), `$C32C` (timer). Noise sequence: `$C32D–$C330` (NR43 / NR42 table pointers, hi byte first), `$C331` (position), `$C332` (on).

---

## 2. One tick (`ChannelTick`, active pages only)

Unlike version 1, the effects run **before** the length counter, on every tick, including the tick that reads a new note:

1. auto-duty, 2. auto-pan, 3. glide, 4. envelope, 5. arpeggio, 6. vibrato, 7. release check, 8. `len` − 1 → at 0 read the stream.

- **Auto-duty** (`AUTODUTY n`): every n ticks the next of 75 %, 12.5 %, 75 %, 50 %, then back to 12.5 % (the step after the 50 % one is reset to 1). **Auto-pan** (`AUTOPAN n`): centre, right, centre, left, centre, then from right again. Both are switched off by `AUTODUTY 0` / `AUTOPAN 0` and by every instrument.
- **Envelope:** in hardware mode, it counts `$29` down and then sends env2 (`$2A`) to NRx2. In software mode: attack while `$12` > 0 (vol += step, max 15, every `$1B` ticks), then decay while `$15` > 0 (vol −= step, min 0, every `$1D` ticks).
- **Arpeggio:** the next table byte is added to the note. `$68` loops to the start, `$FF` holds the last value (it steps back one entry and re-reads it).
- **Vibrato:** after `delay` ticks, ±depth on the period low byte (with carry), switching direction every `speed` ticks; it starts at speed / 2 on each note.
- **Release check** (`RELEASE t, env`): on the tick where `len` = t (before the decrement), unless the next stream byte is `WAIT`. Pulse channels: NRx2 = env (via `$31/$32`). CH3/SFX: volume = env >> 4.

**Note on** (byte < `$60`): store note and pointer, period, restart the arpeggio and apply its first step immediately, reload the hardware envelope (`$31` = `$27`, `$29` = `$28`), `len` = length, restart vibrato, clear the released flag, volume = `vol0`, split the attack/decay bytes.

**Period:** index = note − 12 + `wTranspose` (not on the SFX page) + channel transpose → `PeriodTable` (the same 81-entry table as version 1, from C2). There is **no Ch3 offset** in this version.

---

## 3. Data format

### 3.1 Songs

Each `PlaySongN` calls `StopAll`, starts the three channels from their order lists (`StartMusicChN`), selects the instrument and arpeggio tables and sets NR50 = `$77`. Order lists work as in version 1 (`dw pattern …, 0, loop_position`).

| Song | Routine | Ch1 / Ch2 / Ch3 order lists | Tables | Length (ticks) |
|---|---|---|---|---|
| 1 | `$60FB` | `$6134` / `$614A` / `$611E` | 1 | 640 + 3200 loop. Starts only while `hGameFF82` = 0 (it calls `StopAll` twice) |
| 2 | `$642E` | `$6451` / `$6459` / `$6449` | 1 | 420, ends |
| 3 | `$64E6` | `$6507` / `$650D` / `$6501` | 1 | 196, ends |
| 4 | `$6584` | `$65E3` / `$6627` / `$659F` | 1 | 196 + 13104 loop (the game plays it right after `SndInit`) |
| 5 | `$743E` | `$74B0` / `$748E` / `$7472` | 2 | Ch1 10368 + 2304, Ch2 9216 + 1152, Ch3 8064 + 1152 loop |

Tables 1: instruments `$7346`, arpeggios `$740C`. Tables 2: `$7932`, `$79E2`. (The code indexes the instrument table from 2 bytes before these addresses: `INSTR n` reads entry n + 1 of `table − 2`.) **SFX use whichever tables the last song set** (none of the 14 uses instruments or arpeggios).

### 3.2 Stream bytes

| Byte | Macro | Meaning |
|---|---|---|
| `$00–$5F` | `NOTE p, o` | note, ends the tick |
| `$60 n` | `GLIDE n` | note += n every tick (0 = off) |
| `$61`, `$63` | `WAIT2`, `WAIT` | wait one length (tie); identical |
| `$62 d, depth, speed` | `VIBRATO` | |
| `$64` | `REST` | volume 0 (pulse: also NRx2 = 0 via `$31/$32`), wait |
| `$65` | `STOP_ALL` | |
| `$66` | `END` | centre pan; SFX page: reload the music wave (§3.6); reset the page |
| `$67 n` | `TRANSPOSE n` | global, music only |
| `$68` | `NEXT` | return from `PAT_CALL` if one is pending, else next pattern |
| `$69 w` | `ORDER_JUMP w` | order position = w, then `NEXT` |
| `$6A n` | `LENGTH n` | |
| `$6B 0` / `$6B t, w` | `DRUMS` | drums off / drum pattern w, one step every t ticks (§4.1) |
| `$6C` / `$6D` / `$6E` | `PAN_C/R/L` | ignored on the SFX page |
| `$6F` / `$70` / `$71` | `DUTY_50/75/12` | CH1/CH2 only |
| `$72 e, 0` / `$72 e, t, e2` | `HWENV` | hardware envelope mode: NRx2 = e at each note; with t ≠ 0, NRx2 = e2 after t ticks. Only `VOLENV` and instruments switch back to software volume |
| `$73 n` | `AUTOPAN n` | |
| `$74 n` | `AUTODUTY n` | |
| `$75 w` | `WAVE w` | Ch3: remember w as the music wave and load it unless an SFX is playing. SFX page: load w |
| `$76 n` | `CH_TRANSPOSE n` | |
| `$77 0` / `$77 t, e` | `RELEASE` | off / release at t ticks left with env e |
| `$78` | `ARP_OFF` | |
| `$79 w` | `PAT_GOTO w` | continue the stream at w |
| `$7A w` | `PAT_CALL w` | goto w; the next `NEXT` returns after the call (one level) |
| `$7B` / `$7C` | `NOISE_SEQ2/3` | start noise sequence 2 / 3 |
| `$7D` | `NOISE_HIT7` | drum sound 7 |
| `$7E–$97` | `INSTR n` | instrument n of the current song's table |
| `$98–$A6` | `ARP n` | arpeggio n of the current song's table |
| `$A7–$B6` | `VOL v` | start volume |
| `$B7–$C6 a d r` | `VOLENV v, atk, dec, rates` | start volume + envelope, software volume mode |
| `$C7–$FF` | `LEN n` | length 1–57 |

### 3.3 Instruments

`INSTR n` first clears vibrato, arpeggio, glide, auto-pan, auto-duty and hardware-envelope mode, centres the pan and sets 50 % duty. Then it runs macro n until `$66` or `$68`. A macro uses commands only (`$60–$7D` and `$98–$FF`), no notes. Typical contents: `NOISE_SEQ2` + `HWENV` + `GLIDE` for drums, `VOLENV` + `VIBRATO` + `ARP` + `WAVE` for leads.

### 3.4 Arpeggios

Two tables of 5 pointers. Offsets are added to the note; `$68` = loop, `$FF` = hold.

### 3.5 Sound effects

`PlaySfx` (A = id 1–14):

- A request is **ignored while a lower id is playing** (lower id = higher priority; an equal id restarts).
- NR50: ids `$0B`, `$0C`, `$0E` set `$77`. Ids 1 and 4 set `$77`, or, while `hGameFF82` ≠ 0, `StereoNR50Table[hGameFFC0 >> 3]`. The other ids, while `hGameFF82` ≠ 0, set `StereoNR50Table[wGameC001 >> 3]`. This is stereo placement by an object's X position. It only lasts until the next tick (§6.6).
- A running SFX is reset, the new stream starts on the SFX page and its first tick is parsed **inside the call**.

SFX streams use `WAVE` (they play on CH3), `LEN`, `VOL`/`VOLENV`, notes, `GLIDE`, `VIBRATO` and end with `END`.

| Id | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks until `END` | 28 | 75 | 48 | 15 | 20 | 20 | 24 | 24 | 3 | 28 | 54 | 7 | 25 | 60 |

### 3.6 Waves

Five 16-byte waves at `$5EDF–$5F2E`. Loading one: NR30 = 0, copy to wave RAM, NR30 = NR34 = `$C31A` | `$80` (restart with Ch3's period-hi shadow). When an SFX ends, `RestoreMusicWave` reloads `wMusicWave` and also writes NR32 = Ch3's raw volume field (0–15, not converted; §6.7).

---

## 4. Noise and fades

### 4.1 Drum sequencer

`DRUMS t, w` (t ≠ 0): one byte of pattern w every t ticks. `$FF` loops, 0 = nothing, 1–7 = drum sounds:

| Drum | Sound |
|---|---|
| 1 / 2 / 3 | noise sequence 1 / 2 / 3 |
| 4 | NR41–44 = `$00 A2 03 80` |
| 5 | `$00 C1 00 80` |
| 6 | `$40 D1 01 80` |
| 7 | `$3A F1 00 C0` (also `NOISE_HIT7`, and called by the game) |

### 4.2 Noise sequences

Per tick: NR43 = `seq43[i]`, NR42 = `seq42[i]`, NR44 = `$80`, until `seq43[i]` = `$FF`.

| Seq | NR43 | NR42 |
|---|---|---|
| 1 | `00 51 61 71 91 71 60` | `F0 F0 D0 90 80 50 23` |
| 2 | `60 52 42 41 12 11 03` | `F0 E0 D0 B0 A0 90 81` |
| 3 | `07 16` | `F0 A1` |

A 4th one at `$598B` (`07 03 00 FF` / `70 60 41`) is unused.

### 4.3 NR50 fades

`StartFade(speed, table)`: one table byte every speed + 1 ticks into NR50; `$68` loops, `$FF` ends. The game always uses `FadeOutTable` (`77 66 55 44 33 22 11 00 FF`) with speed `$0F` or `$0A`. **While no fade is running and `hGameFF99` = 0, NR50 is forced back to `$77` every tick** (unless it is 0).

---

## 5. Timing

59.73 Hz. Song 4 (title) loops every 13104 ticks (3 min 39 s). Songs 2 and 3 are jingles of 420 and 196 ticks.

---

## 6. Quirks and bugs

1. **Pulse channels are retriggered every tick** in software volume mode (NRx2 rewritten + trigger bit). Only the hardware-envelope mode avoids this.
2. **The SFX page's period-hi shadow is `$C31B`, which is also the NR32 shadow** (`$C318` + 3). An SFX therefore disturbs the CH3 volume shadow; `ResetChannel` increments `$C31B` on Ch3/SFX so that the next volume write isn't skipped.
3. **`ResetChannel` always silences the channel** (NRx2 = 0, NRx4 = `$80`). On the SFX page it means to skip this while Ch3 is active, but it tests the Z flag after a `ld`, which doesn't set flags. The flag still holds the result of the earlier `cp $C7`, so the jump is always taken. As a result CH3 is always muted (NR32 = 0) when an SFX is reset.
4. **The envelope's release phase is dead:** `DoEnvelope` reads fields `$18/$19/$1E/$1F` but nothing sets `$19` (a leftover of version 1's `$61`). `RELEASE` works differently (§2).
5. **`HWENV` on CH3** (drum instruments 0 and 3 of table 1 are used on Ch3): the envelope byte goes to NR32 raw (only bits 5–6 count) and the retrigger goes to **NR24**, so CH2 restarts as well.
6. **SFX stereo placement lasts one tick:** `PlaySfx` writes NR50, but on the next tick `DoFade` sets it back to `$77` (unless `hGameFF99` ≠ 0 or a fade runs).
7. **`RestoreMusicWave` writes NR32 = Ch3's raw volume field** (0–15 in bits 0–3, so effectively mute). The reset that follows writes NR32 = 0 anyway, and Ch3's next output restores the level (the reset bumped `$C31B`).
8. **SFX on CH3 ignore `PAN_*`/`DUTY_*`**, and use the music's NR51 bits for CH3.
9. **The drum timer runs while the drums are off** and wraps every 256 ticks (harmless). `DrumStep`'s `ret z` after `cp $FF` / `jr z` can never be taken.
10. **Arpeggio `$FF` hold** re-reads the previous entry: a table starting with `$FF` would hang the driver (none does).
11. **One-level `PAT_CALL`**: a `PAT_CALL` inside a called block overwrites the return address. `ORDER_JUMP` goes through `NEXT` too, so a pending return takes priority over the jump.
12. **`PlaySong1` calls `StopAll` twice** and starts nothing while `hGameFF82` ≠ 0, but still selects the tables and sets NR50.
13. **Dead code/data:** the old `CHORUS_ON/OFF` handlers at `$56D3/$56D8` (not in the table), `$5E3D` (`pop hl` / `ret`), noise sequence 4 (`$598B`), pattern `$78BA` and drum pattern `$7435` (unreferenced), entry 0 of every instrument table (the code indexes `table − 2`), and the first word of the sound table.

---

## 7. Verification

- **Byte-exact rebuild** of all six ranges (`tools/cmp_ranges.py`).
- **Model vs emulator** (`verify/vmodel.py`). `tools/bombjack_model.py` is an independent Python model written from this document. The harness ROM (`verify/build_harness.py`, code at `$7A10`) calls `SndInit`, then loops: run a command from a RAM mailbox, call the real `SndUpdate`, stop at `TickDone`. On every tick these are compared: all four pages (`$00–$3F`), `$C318–$C338`, and the readable sound registers (NR11/21 duty, NR12, NR22, NR32 level, NR42, NR43, NR50, NR51).
  - All 5 songs (9000 ticks each), each of the 14 SFX alone, and three mixed scenarios: SFX over every song, priority refusals, SFX replacing SFX, fades (speeds 0–5), `StopAll`, song changes mid-SFX, and both `hGameFF82` paths with several positions. **0 mismatches**.
  - Synthetic test streams (`harness_bombjack.asm`) cover what the data never uses: `STOP_ALL`, `ORDER_JUMP`, `PAT_CALL` + return, `NOISE_HIT7`, `DRUMS 0`, `HWENV e, 0`, `HWENV` on CH3, `RELEASE 0`, `RELEASE` on CH3, `GLIDE 0`. **0 mismatches**. All 30 table commands were run at least once.
- **Not verified:** period registers and wave RAM can't be read back reliably, so the period writes are only checked through the page fields and the period-hi shadows. Trigger timing isn't compared. Nothing was checked on hardware or against emulator audio output.

## Files (in `GBAudioLab\AJG`)

- `BombJack_SoundDriver.asm`: labelled, commented RGBDS source with data macros, byte-exact
- `tools/`: `bombjack_data.py` (data walker), `gen_bombjack.py` + `comments_bombjack.py` (asm generator), `bombjack_model.py` (driver model), plus the shared helpers listed in `PopUp_SoundDriver.md`
- `verify/`: `harness_bombjack.asm`, `build_harness.py`, `vmodel.py`, `run_all.sh`, `run_all.log`

Regenerate: `python tools/gen_bombjack.py "Bomb Jack (U).gb" BombJack_SoundDriver.asm` (from the `AJG` folder).
