# The Castlevania Adventure (GB): sound driver

ROM: `Castlevania Adventure, The (E) [!].gb` (DMG, MBC1, 64 KB, internal title `CASTLEVANIA ADV`). Konami, 1989/1991 (E).

Part of the Konami family, see `Konami_SoundEngine_Family.md`. This is the **6-track variant**.

| | |
|---|---|
| API | bank 2 `$4040` `SndInit`, `$4706` `PlaySound` (A = id, 0 = stop all; keeps all registers), `$468F` `SndPause`, `$46A8` `SndUnpause`. ROM0 `$00BD` `PlaySoundFar` (bank-switching wrapper used by the game) |
| Tick | **timer IRQ only**, 64 Hz (TAC = `%111`, TMA = 0; measured 63.998 Hz in PyBoy). `$0050` → `$0092` `TimerISR` → `$405B` `SndUpdate` |
| Music rate | 32 Hz (every 2nd IRQ), less any tempo skips (§2.2) |
| Driver code | bank 2 `$4000–$481C` (~2 KB, including 4 unused helpers) |
| Tables + data | bank 2 `$481D–$663E` (7.7 KB) |
| RAM | `$C100–$C24D` (`$C100` working copy, six `$25`-byte slots `$C125–$C202`, shadows `$C228`), locks `$C00B`, pause flag `$C012` |
| Channels | Sfx1 (CH1 SFX), SfxN (CH4 SFX), Ch1, Ch2, Ch3 and Drm (music; the drum track triggers SFX ids 1–4 on SfxN) |
| Counts | 49 sound ids: 4 drum hits, 32 SFX (`$05–$24`), 13 music (`$25–$31`) |

`CVA_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over ROM0 `$0050–$0052`, `$0092–$00E3`, `$02EB–$034C` and bank 2 `$4000–$663E`. It assembles cleanly with `-Wall` and needs no `hardware.inc`.

```
rgbasm -Wall -o cva.o CVA_SoundDriver.asm
rgblink -o cva.gb cva.o
python tools/cmp_ranges.py cva.gb "Castlevania Adventure, The (E) [!].gb" 0:0050-0052 0:0092-00E3 0:02EB-034C 2:4000-663E
```

---

## 1. Structure

`SndUpdate` walks six tracks in order. Each track is a `$25`-byte slot. `LoadTrack` copies the slot to the working copy at `$C100`, `TrackTick` runs on the copy (all code addresses `wCur*` directly), and `StoreTrack` copies it back.

| # | Slot | Name | Channel (reg base) | NR51 bits at start | Runs |
|---|---|---|---|---|---|
| 0 | `$C125` | Sfx1 | CH1 (`$00`) | `$11` | every IRQ |
| 1 | `$C14A` | SfxN | CH4 (`$0F`) | `$88` | every IRQ |
| 2 | `$C16F` | Ch1 | CH1 (`$00`) | `$11` | music ticks |
| 3 | `$C194` | Ch2 | CH2 (`$05`) | `$22` | music ticks |
| 4 | `$C1B9` | Ch3 | CH3 (`$0A`) | `$44` | music ticks |
| 5 | `$C1DE` | Drm | CH4 regs (`$0F`), but notes only start SFX | – | music ticks |

**Channel sharing.** Music Ch1 and Sfx1 share CH1. While Sfx1 is active, every register write and trigger from Ch1 is dropped (`IsBlocked`), and so is a Ch1 `PAN`. Ch1 keeps running silently, so it stays in time. CH4 isn't arbitrated this way. The drum track doesn't write notes to CH4 itself: a `DRUM n` note calls `PlaySound(DrumMap[n-1])` (ids 1–4, priority 1) on SfxN, so a drum is refused while a higher-priority noise SFX plays.

**Register writes** go through `WriteReg` (`[$FF10 + base + idx]`), which keeps a 20-byte shadow at `$C228` and skips the write when the shadow already holds the value, unless flag 6 (`TF_FORCE`) is set. `Trigger` writes NRx4 = shadow | `$80`. A few writes bypass the shadow: NR10 (when tracks start or end), NR30 (DAC on/off around CH3 notes), NR51 and wave RAM.

### 1.1 Track fields (offset in slot / working copy address)

| Off | Addr | Name | Use |
|---|---|---|---|
| `$00` | `$C100` | id | sound id, 0 = idle |
| `$01` | `$C101` | prio | priority of the running sound |
| `$02` | `$C102` | ptr | stream pointer (saved only at notes) |
| `$04` | `$C104` | len | ticks left in the current note |
| `$05` | `$C105` | flags | b0 released, b1 autopan, b3 vibrato negate (sticky), b6 force write, b7 rest |
| `$06` | `$C106` | loopcnt | `SND_REPEAT` counter (one level) |
| `$07` | `$C107` | vib | vibrato table index, 0 = off |
| `$08` | `$C108` | transp | transpose (signed) |
| `$09` | `$C109` | atten | volume attenuation (`$Fx`) |
| `$0A` | `$C10A` | vibofs | current vibrato offset (11 bits) |
| `$0C` | `$C10C` | unit | length unit |
| `$0D` | `$C10D` | octave | 0–5 |
| `$0E` | `$C10E` | period | base period of the note |
| `$10`/`$11` | `$C110`/`$C111` | vol / duty | duty: NRx1 = duty << 4; on CH3 the wave number |
| `$12`/`$13` | `$C112`/`$C113` | env / gate | release envelope, gate fraction |
| `$14` | `$C114` | reltick | `len` value at which the release happens |
| `$15`/`$16` | | vibrato timer / reload | |
| `$17`/`$18`/`$1A` | | CH3 decay timer / reload / level | |
| `$1B` | `$C11B` | segno | loop start (`SND_SEGNO`) |
| `$1D` | `$C11D` | ret | return address (**one slot**) |
| `$1F`, `$21–$23` | | vibrato pointer, index, loop index, loop counter | |

`PlaySound` sets id, prio, ptr, `len = 1`, `flags = $40` and zeroes `$06–$0B`. **Everything from `$0C` up survives from the previous sound on that slot** (unit, octave, voice, envelope, gate, CH3 level, vibrato pointer...). All the game's streams set these before their first note, so this has no audible effect in this game.

### 1.2 Globals

`$C23C` NR51 shadow, `$C23D` tempo accumulator, `$C23E` tempo, `$C23F` skip flag, `$C240–$C246` temporaries, `$C24A` slot pointer, `$C24D` tick parity. `$C248` (`wNoRestore`) is tested by `SndUnpause` but never written.

---

## 2. Timing

### 2.1 Interrupt glue (ROM0)

- `TimerISR` (`$0092`) re-enables interrupts at once. If `wDrvLock` bit 0 is clear, it switches to bank 2 (the current bank is read from `$7FFF`, where every bank stores its own number), runs `SndUpdate` under the lock and switches back.
- `PlaySoundFar` (`$00BD`) takes the same lock. While the game is inside it, the timer tick is **skipped entirely** (one tick lost). Conversely, a request made from an interrupt nested inside `TimerISR` is **dropped**.

### 2.2 Music rate and tempo

Every IRQ: `wTempoAcc += wTempo`, and a carry sets `wTempoSkip`. Then:

- tracks 0–1 run;
- `wTickParity` is incremented; on even values tracks 2–5 are skipped;
- on odd values they're also skipped if `wTempoSkip` is set.

So music runs at **32 Hz** with `TEMPO 0`, and `TEMPO t` removes about t/256 of the odd ticks. Because the carry test only matters on odd IRQs, the effective rate depends on the phase between the accumulator and the parity:

| Tempo | Used by | Measured music rate |
|---|---|---|
| `$00` | most songs | 32.000 Hz |
| `$10` | `$2F` | 28.0 Hz: every carry lands on an odd IRQ (the song sets the tempo on a music tick with the accumulator at 0), so exactly every 8th music tick is dropped |
| `$30` | `$2C` | 24.0 Hz |
| `$33` | `$27`, `$2E` | 25.6 Hz |

The accumulator is cleared only by `StopAll`, so a tempo song started without a preceding stop can land on a different phase. With `$10` that makes the rate either 28 Hz or 32 Hz.

### 2.3 Pause

While `wPause` (`$C012`) ≠ 0, only track 0 runs, and only while it's playing sound `$05`. The game's `PauseToggle` (`$02EB`) calls `SndPause` (CH1/CH2/CH4 retriggered at volume 0, NR32 = 0, then plays `$05`) and, on unpause, `SndUnpause`. `SndUnpause` copies the shadows back to FF10–FF14/FF16–FF19/FF1A–FF1E, and to FF20–FF23 only if the SfxN id is ≥ 5 (i.e. not a drum). Nothing is retriggered, so each channel resumes at its next note. The toggle also writes `$C124`, which is the working copy's unused last byte and gets overwritten on the next track.

---

## 3. Data format

### 3.1 Tables

| Addr | Name | Content |
|---|---|---|
| `$481D` | `PeriodTable` | 96 periods, index 0 = `$020` (C2, 65.0 Hz) |
| `$48DD` | `WaveTable` | 3 pointers. The waves overlap: `$48E3` (ramp `11 22 … FF 01`), `$48F2` (triangle), `$4902` (rounded triangle). `$4912–$4915` are 4 stray bytes |
| `$4916` | `SoundTable` | 49 pointers to headers |
| `$4978–$4A69` | headers | `db prio, mask` + one `dw` per set mask bit (bit 0 first) |
| `$4A6A` | `DrumMap` | `01 02 03 04` |
| `$4A9F` | `VibratoTable` | 11 pointers. Entries 2–7 are the same table; entry 11 points into sound `$06`'s data and isn't used |
| `$4AB5–$4AEB` | vibrato data | |
| `$4A7E–$663E` | streams | SFX `$4A7E–$4DF5`, music `$4DF6–$663E` |

Higher priority wins: a track is taken if the new priority ≥ the slot's current priority. Music uses priority 1. **NR51 bits and NR10 are written for each masked channel even when the priority test fails.**

### 3.2 Commands

Notes are `$00–$DF`: hi nibble = pitch, lo nibble = length multiplier. Everything else is a command.

| Byte | Macro | Meaning |
|---|---|---|
| `$p l` (p = 1–13) | `NOTE p, l` | len = l × unit (mod 256; 0 means 256 ticks). Pitch index = (p−1) + transp + 12 × octave → `PeriodTable` |
| `$0 l` | `REST l` | NRx2 = 0, NRx4 = `$80`, flags b6/b7 set |
| (Drm) `$n l` | `DRUM n, l` | `PlaySound(DrumMap[n−1])` |
| (SfxN) `$xx` | `NOISE x` | NR43 = x, NR44 = 0 (**no retrigger**), len = unit |
| `$E0 u v e` | `VOICE u, vol, duty, env, gate` | unit; vol/duty (NRx1 or CH3 wave); env/gate. **SfxN:** `$E0 u v` (`NVOICE`), v → NR42 + retrigger. **Drm:** `$E0 u` (`DRUM_UNIT`) |
| `$E1–$E6` | `OCTAVE n` | octave = n − 1 |
| `$E7 u` | `LEN_UNIT u` | |
| `$E8 ge` | `RELEASE e, g` | |
| `$E9 x` | `SWEEP x` | NRx0 = x (only used on CH1) |
| `$EA 0n / 1n` | `TRANSPOSE_UP/DOWN n` | |
| `$EA 2n` | `VIBRATO n` | n = 0 off |
| `$EA 3n` | `DUTY n` / `WAVE n` | CH3: copy wave n to wave RAM |
| `$EA 4n` | `AUTOPAN n` | n ≠ 0: swap this channel's L/R bits in NR51 before every note |
| `$EB–$ED x` | `CMD_EB…` | no-op, skips x (unused in the data) |
| `$EE x` | `TEMPO x` | §2.2 |
| `$EF x` | `PAN x` | NR51 bits of this channel = swap(x). Masks per track: `EE 77 EE DD BB FF` (the drum track can't pan) |
| `$F0–$FA` | `ATTEN n` | volume = vol − n. SfxN: rewrite NR42 + retrigger |
| `$FB` | `SND_SEGNO` | loop start |
| `$FC` | `SND_RET` | |
| `$FD w` | `SND_CALL w` | one return slot |
| `$FE n` | `SND_REPEAT n` | jump back to segno until played n times |
| `$FE $FF w` | `SND_JUMP w` | |
| `$FF` | `SND_END` | |

**One return slot.** `SND_CALL` overwrites the only return address. The songs use this on purpose. A "call" whose target never reaches a `SND_RET` acts as a goto, and calling a block that itself contains calls makes its final `SND_RET` return to after the *last inner* call. For example, Ch1 of `$25` ends with `SND_CALL $501D`, and that target is itself a `SND_CALL`, so the song loops. The parser (`tools/kdata.py`) handles this by simulating `(pc, segno, loop counter, return)` states, not by treating calls as subroutines.

### 3.3 Envelope, gate and CH3

- **Note on:** NRx2 = (vol − atten) << 4 with **no envelope**, then trigger.
- **Release:** when `len` reaches `reltick` = len × gate / 16 (gate `$F`: len − 1; gate 0: never), NRx2 = (vol − atten) << 4 | env and retrigger. With env = 0, NRx2 = 0 (cut).
- **CH3:** NR30 = `$80` at every note, and NR30 = 0 whenever a note's length runs out (so the DAC is off while the next commands run, which makes the wave RAM writes of `WAVE` safe). Level code = (vol >> 1) & 3 + atten (1 = 100 %, 2 = 50 %, 3 = 25 %, ≥ 4 → off). After the release point `Ch3Decay` steps the code 1 → 2 → 3 → 0 every env ticks (env 0 = cut).

### 3.4 Vibrato

Table entries: `VIB_STEP delay, neg, offset` = `db delay<<4 | neg<<3 | hi3, lo`, then `$FB` (loop point), `$FE n` (repeat; `$FF` = forever), `$FF` (hold). At each note the index restarts. Every `delay` ticks the next entry sets the offset added to the base period (NRx3/NRx4 without trigger). The tables in this game bend upward only: `Vib01` holds +1, `Vib02` alternates +8/+0, `Vib08`–`Vib0A` +4/+2/+14.

---

## 4. Sounds

Lengths are in ticks: SFX at 64 Hz, music at the rate in §2.2. "a+b loop" is intro + loop period for that channel.

| Id | Prio | Tracks | Length |
|---|---|---|---|
| `$01`–`$04` | `$01` | SfxN | 1, 1, 65, 65 (drum hits, via `DrumMap`) |
| `$05` | `$FF` | Sfx1 | 42 (pause jingle) |
| `$06` | `$FE` | SfxN | `FE FD` repeat with unit 254: effectively endless (~2.9 h) |
| `$07`–`$24` | `$E3`–`$FD` | Sfx1 or SfxN | 8–1314 |
| `$25` | 1 | Ch1/Ch2/Ch3/Drm | 640+1600 / 128+1600 / 640+1600 / 128+1280 |
| `$26` | 1 | Ch1/Ch2/Ch3 | 60 / 28 / 32, ends |
| `$27` | 1 | Ch1/Ch2/Ch3 | 96, ends (tempo `$33`) |
| `$28` | 1 | Ch1/Ch2/Ch3 | 86+384 / 86+384 / 278+384 |
| `$29` | 1 | 4 tracks | 256+1024 / 256+1024 / 512+1024 / 0+1024 |
| `$2A` | 1 | 4 tracks | 256+1024 / 256+1024 / 768+1024 / 256+2560 |
| `$2B` | 1 | 4 tracks | 128+1024 / 128+1024 / 384+1024 / 128+1280 (shares the drum stream of `$25`) |
| `$2C` | 1 | Ch1/Ch2/Ch3 | 1982 / 1988 / 1982, ends (tempo `$30`) |
| `$2D` | 1 | Ch1/Ch2/Ch3 | 12+192 / 0+192 / 0+192 |
| `$2E` | 1 | Ch1/Ch2/Ch3 | 96, ends (tempo `$33`) |
| `$2F` | 1 | Ch1/Ch2/Ch3 | 331+640 / 123+640 / 123+640 (tempo `$10`) |
| `$30` | 1 | 4 tracks | 35+256 / 35+256 / 35+256 / 35+32 |
| `$31` | 1 | Ch1/Ch2/Ch3 | 131 / 131 / 130, ends |

The per-id table with stream addresses is in the asm (`SoundTable` / `SndHdrXX` comments). The stage music table at ROM0 `$05BC` (`$25 $2A $29 $2B` for stages 1–4) and the boss table at `$0A1E` (`$28 $28 $28 $30`) are game data and not part of the asm.

---

## 5. Quirks and bugs

1. **Half-rate music with a phase-dependent tempo** (§2.2).
2. **Lost ticks / dropped requests** around `wDrvLock` (§2.1).
3. **NR51/NR10 are set even when a sound loses the priority test.**
4. **One return slot**, used deliberately as a goto (§3.2).
5. **Fields from `$0C` up persist** across sounds on a slot (§1.1).
6. **Stale vibrato offset:** `VIBRATO 0` doesn't clear `vibofs`, and `WritePeriod` always adds it. Notes after `VIBRATO 1 … VIBRATO 0` (Ch1 of `$2B` and `$31`) keep +1 period.
7. **Vibrato negate is sticky** (flag b3 is only cleared when a sound starts). No table here uses it.
8. **End of Sfx1** restores only the music duty (from Ch1's slot) and clears NR10. The music Ch1 volume and frequency come back on its next note, so the channel is silent until then.
9. **A drum-track `REST` writes NR42 = 0 / NR44 = `$80`** and cuts any noise SFX (it uses the same registers without the SfxN check). There's one in the data. The end of the drum track does the same.
10. **SfxN notes don't retrigger.** Only `NVOICE` and `ATTEN` do.
11. **CH3 decay sets NR32 bit 4:** the carry from `cp $04` is rotated in (`$30/$50/$70` instead of `$20/$40/$60`). Harmless.
12. **`AUTOPAN` and drum-track releases aren't blocked** for Ch1 during Sfx1 (autopan rewrites NR51 directly).
13. **`EA x?` with x ≥ 5 jumps through garbage**, and so does `VIBRATO`/`WAVE` with out-of-range values (not in the data). `$EB–$ED` are no-ops with an argument.
14. **`StopAll` doesn't write NR51** (its shadow is cleared; the next sound sets only its own bits).
15. **Dead code/data:** unused helpers `$4009–$4032`, `jr nz,+0` at `$441C`, `wNoRestore`, the `$C124` write, vibrato entries 2–7 duplicated and entry 11 pointing into SFX data, stray wave bytes `$4912–$4915`, orphan stream bytes `$4B96–$4BA4` (after `$10`, looks like a cut echo tail) and `$4CC4–$4CC6`.

---

## 6. Verification

- **Byte-exact rebuild** of all four ranges (`tools/cmp_ranges.py`).
- **Timer rate:** 63.998 Hz measured (1.0715 IRQs per frame).
- **Model vs emulator** (`verify/vmodel.py`): `tools/kmodel.py` is an independent Python model of the driver. PyBoy injects `PlaySound` calls at chosen ticks. On every tick the following are compared: all six slots (every byte), the 20 register shadows, NR51 shadow and hardware NR51, tempo accumulator, tempo, skip flag, parity, wave RAM (while CH3 is off) and the exact set of triggers per tick.
  - Each of the 49 ids alone for 7000 ticks (`verify/run_all.sh`): **0 mismatches**.
  - Two mixed scenarios of 9000 ticks each (`verify/run_combo.sh`): music + Sfx1 (blocking and restore), noise SFX against drums, refused low-priority requests, `StopAll` mid-song, pause with `$05`: **0 mismatches**.
- **Not verified:** `SndPause`/`SndUnpause` were only read, not run (the pause test sets `wPause` directly). Nothing was checked on hardware or against emulator audio output.

## Files (in `GBAudioLab\Kon`)

- `CVA_SoundDriver.asm`: labelled, commented RGBDS source with data macros, byte-exact
- `tools/`: `sm83.py`, `trace.py` (code tracer), `kdata.py` (data decoder/walker), `gen_asm.py` + `cfg_cva.py` + `asmcommon.py` (asm generator), `kmodel.py` (driver model), `cmp_ranges.py`
- `verify/`: `vmodel.py`, `run_all.sh`, `run_combo.sh`, logs

Regenerate: `python tools/gen_asm.py cva CVA_SoundDriver.asm` (run from the `Kon` folder; the ROM is found by its file name, or set `KON_ROM_CVA`). The verify scripts need `pip install pyboy`.
