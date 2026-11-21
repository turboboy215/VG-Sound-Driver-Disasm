# Pop Up (GB): sound driver

ROM: `Pop Up (U) [!].gb` (DMG, no MBC, 32 KB, internal title `POP UP`). Infogrames, 1991.

Part of the AJG family (Alberto José González / Bit Managers), see `AJG_SoundEngine_Family.md`. This is **version 1**, the earliest one looked at so far.

| | |
|---|---|
| API | `$50E4` `PlaySound` (A = id 1–7, keeps bc/de/hl), `$51D2` `StopAll` (also the init), `$59A6` `PlayTitleMusic`, `$5E43` `PlaySong2`. The game sets `hSndOn` (`$FFF5`) = 1 after starting music. Unused: `$50BC` `PlaySoundChecked` → `$50D1` `PlaySoundLock` |
| Tick | **VBlank** (59.73 Hz) while the LCD is on: the game's VBlank handler calls `SndUpdate` (`$5135`) at `$1613` if `hSndOn` ≠ 0. While the LCD is off (`hLCDOff` `$FFCD` = 0) the **timer IRQ** does it instead: TMA = `$B4`, TAC = 4 → 4096 / 76 = 53.89 Hz |
| Driver code + data | `$50B6–$6059` (code `$50B6–$59CD` with tables in between, songs `$59CE–$5EC3`, instruments/arpeggios/SFX `$5EC4–$6059`), plus 22 unreferenced bytes at `$50A0` |
| RAM | four `$100`-byte pages: Ch1 `$C1xx`, Ch2 `$C2xx`, Ch3 `$C3xx`, SFX `$C4xx` (fields `$00–$3D`); `$C339`; HRAM `$FFDF–$FFF5` |
| Channels | music on CH1, CH2, CH3; SFX on CH1 only (the SFX page replaces Ch1 in the output). CH4 only gets fixed noise hits |
| Counts | 2 songs, 7 sound effects, 26 instrument slots, 15 arpeggio slots (3 real) |

`PopUp_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over ROM0 `$0008–$000B`, `$0010`, `$0020–$0026`, `$0028–$002C`, `$0050–$0052`, `$06FE–$075F`, `$1610–$161A`, `$4903–$4904` and `$50A0–$6059`. It assembles cleanly with `-Wall` and needs no `hardware.inc`.

```
rgbasm -Wall -o popup.o PopUp_SoundDriver.asm
rgblink -t -o popup.gb popup.o
python tools/cmp_ranges.py popup.gb "Pop Up (U) [!].gb" 0008-000B 0010-0010 0020-0026 0028-002C 0050-0052 06FE-075F 1610-161A 4903-4904 50A0-6059
```

(`-t` because the cart has no MBC, so `$4000–$7FFF` is plain ROM.)

---

## 1. Structure

`SndUpdate` writes NR50 = `$FF` and NR52 = `$8F`, then runs `ChannelTick` on the four pages in order (Ch1, Ch2, Ch3, SFX). If `hSndOn` is still set, it writes the "registers 6/7" (no-ops, §5.6) and outputs Ch2, Ch3, and then **either the SFX page (while `wSfxId` ≠ 0) or Ch1** to CH1. Ch1 keeps running silently under an SFX, so it stays in time.

The driver never writes the register-index fields `$06/$08/$0A` or the NR51 bits `$1F/$20`. The game sets them once at boot (`GameSndInit`, `$06FE`, included in the asm): it zeroes `$C100–$C4FF`, fills in Ch1–Ch3, and copies the Ch1 page to the SFX page. It also fills wave RAM with `0F 0F …` (a square wave), sets 50 % duty on CH1/CH2, NR50/NR52, clears FF10–FF23, sets NR30 = `$80` and calls `StopAll`.

| Page | Fields `$06/$08/$0A` | `$1F/$20` |
|---|---|---|
| Ch1 `$C1` | 0, 1, 8 | `$01`, `$10` |
| Ch2 `$C2` | 2, 3, 9 | `$02`, `$20` |
| Ch3 `$C3` | 4, 5, 10 | `$04`, `$40` |
| SFX `$C4` | copy of Ch1 | copy of Ch1 |

### 1.1 Register writes (`WriteReg`, A = index, C = value)

All channel output goes through `WriteReg` and `RegHandlerTable` (indices ≥ 13 are ignored):

| Index | Register | Behaviour |
|---|---|---|
| 0 / 2 / 4 | NR13 / NR23 / NR33 | always written |
| 1 / 3 / 5 | NR14 / NR24 / NR34 | value & 7. Written **with the trigger bit** only when it differs from the shadow (`$FFE5–$FFE7`) |
| 8 / 9 | NR12 / NR22 | value & 15. Only when it differs from the shadow (`$FFE0/$FFE1`): NRx2 = v << 4 (**no envelope**), then retrigger with the period-hi shadow |
| 10 | NR32 | `Ch3VolTable[v & 15]` (`00 ×4, 60 ×4, 40 ×4, 20 ×4` = mute/25/50/100 %). When it differs from the shadow `$FFE2`: write and retrigger NR34 |
| 6, 7, 11, 12 | – | `ret` |

So a channel is only retriggered when its volume or its period-hi bits change. A new note with the same volume and the same top 3 period bits as the previous output isn't retriggered: it just changes pitch (legato).

### 1.2 Channel fields (offset in each page)

| Off | Name | Use |
|---|---|---|
| `$00/$01` | order | position in the order list (word after the current pattern pointer) |
| `$02/$03` | ptr | stream pointer, saved at notes and waits |
| `$04` | flags | b0 arpeggio, b1 slide, b2 bend, b3 vibrato, b4 (tested, dead), b5 chorus, b6 vibrato direction |
| `$05` | len | ticks left |
| `$06/$07` | | WriteReg index / value of the period low byte |
| `$08/$09` | | WriteReg index / value of the period high byte (16 bits are kept: slides can carry into `$09`) |
| `$0A/$0B` | | WriteReg index of the volume / current volume 0–15 |
| `$0C` | note | current note (glide changes it) |
| `$0D` | length | note length in ticks |
| `$0E`, `$0F/$10` | attack | `VOLENV` byte; lo nibble → step count, hi nibble → step size |
| `$11`, `$12/$13` | decay | same for the decay |
| `$14` | vol0 | start volume of each note |
| `$15` | glide | added to the note every tick (`GLIDE`) |
| `$16` | relpt | ticks-left value at which the release starts (`RELEASE`), reset value 1 |
| `$17`, `$18` | | release step, release active |
| `$19/$1A`, `$1B/$1C`, `$1D/$1E` | | attack / decay / release rate counter and reload |
| `$1F/$20` | | this channel's NR51 bits (used only by the dead mask commands) |
| `$21/$22`, `$23` | | arpeggio pointer, index |
| `$24/$25`, `$26` | | slide step (bit 15 = negative), slide counter |
| `$27/$28`, `$29` | | bend start offset, bend counter reload |
| `$2A`–`$2D` | | vibrato delay, depth, counter, speed |
| `$2E` | | arpeggio hold flag |
| `$2F`, `$35–$37` | | cleared, never set (`$37` would override the volume) |
| `$30` | active | 0 = idle. On the SFX page this is `wSfxId` (`$C430`) |
| `$31/$32`, `$33`, `$34` | | volume table pointer, index, enable |
| `$38` | atten | subtracted from the volume (`ATTEN`) |
| `$39` | | set when this channel started an SFX (`PLAY_SFX`): its next note or `REST` stops the SFX again |
| `$3A–$3D` | | saved volume table pointer/enable for `NOTE_OFF`, restore flag `$3C` |

### 1.3 Globals

`hSfxLock` `$FFDF`, shadows `$FFE0–$FFE7`, `hInInstr` `$FFE8` (`$C9` while an instrument macro runs), `hTranspose` `$FFE9`, `hReg6`/`hMask`/`hMaskSaved` `$FFEC–$FFEE`, `hSfxAtten` `$FFEF` and `hMusAtten` `$FFF0` (subtracted from the SFX / music volume; the game never writes them), `hShNR51` `$FFF1`, duty shadows `$FFF2/$FFF3`, `hCh1NoteFlag` `$FFF4` (set at every Ch1 note), `hSndOn` `$FFF5`, `wSfxLockedVol` `$C339` (picks which attenuation the SFX page uses).

---

## 2. One tick

`ChannelTick` (page active only):

1. If `hMask & $20` = 0: `hReg6` = period low (dead, §5.6).
2. Arpeggio step (if on).
3. `len` − 1. If it reaches 0, **read the stream** (§3) and stop here.
4. Otherwise run, in this order: glide, release check, envelope, slide, bend, vibrato, chorus.

The effects don't run on the tick a new note is read.

- **Glide:** note += `$15`, period recomputed.
- **Release check:** when `len` = `$16` and the next stream byte isn't `WAIT`: release on (`$18` = 1), and **slide off** (flag b1 cleared).
- **Envelope** (one phase per tick): attack while `$0F` > 0 (every `$1A` ticks: vol += step, max 15), then decay while `$12` > 0 (vol −= step, min 0), then release while `$18` (vol −= `$17` every `$1E` ticks).
- **Slide / bend:** while the counter `$26` > 0, the 16-bit step is added to the period every tick (subtracted if bit 15 is set). Slide and bend share the step and counter, so with both flags on, the step happens twice per tick.
- **Vibrato:** starts once `len` ≤ length − delay (immediately if the current event is a `WAIT`). It alternates −depth / +depth on the period low byte (with carry into the high byte), switching direction every `speed` ticks. Each note restarts the counter at speed / 2.
- **Chorus:** copies Ch1's volume and period into this channel, + (volume & 7) on the period.

**Output** (`OutputChannel`): period low, period high, then the volume = vol − volume-table entry (§3.6), minus `ATTEN`, minus `hSfxAtten` (SFX page while `wSfxLockedVol` = 0) or `hMusAtten` (others), each floored at 0.

---

## 3. Data format

### 3.1 Songs: order lists

`StartMusicChN` (de = order list) resets the page, marks it active, loads the first pattern pointer and stores the order position. An order list is a list of pattern pointers ending with `dw 0, loop_position` (`ORDER_LOOP`). The game starts music with two fixed routines:

| Routine | Ch1 | Ch2 | Ch3 | Length (ticks) |
|---|---|---|---|---|
| `PlayTitleMusic` `$59A6` | `$59CE` | `$5A2A` | `$59FC` | 0 + 9408 loop (all channels) |
| `PlaySong2` `$5E43` | `$5E71` | `$5E6B` | `$5E65` | 384: Ch1 ends with `STOP_ALL`, which stops everything |

Both routines also set NR51 = `$FF`. `PlayTitleMusic` disables interrupts while it runs.

### 3.2 Stream bytes

| Byte | Macro | Meaning |
|---|---|---|
| `$00–$5F` | `NOTE p, o` | note. Period index = note − 12 (− 36 more on **Ch3**, so Ch3 data is written 3 octaves up) + `hTranspose` (the SFX page ignores the transpose) → `PeriodTable` (81 entries from C2 = 65.4 Hz). Ends the tick |
| `$60 n` | `GLIDE n` | note += n every tick (signed) |
| `$61 t, ss` | `RELEASE t, rs` | release point t; s hi = rate, lo = step |
| `$62` | `ARP_OFF` | also turns the volume table off |
| `$63 lo, hi, n` | `SLIDE` | period += step (hi bit 7 = negative) for n ticks |
| `$64 o.lo, o.hi, s.lo, s.hi, n` | `BEND` | each note starts at period + o, then slides by s for n ticks |
| `$65` | `BEND_OFF` | |
| `$66 d, depth, speed` | `VIBRATO` | |
| `$67` | `VIBRATO_OFF` | |
| `$68` / `$69` / `$6A` | `MASK_A/B/AB` | dead NR51 masks (§5.6) |
| `$6B` | `WAIT` | wait one length without a new note (tie). Ends the tick |
| `$6C` | `REST` | volume 0 (and stop an SFX this channel started), then wait |
| `$6D` | `STOP_ALL` | `StopAll` from the stream, `hSndOn` = 0 |
| `$6E` / `$6F` | `CHORUS_ON/OFF` | §2 |
| `$70` | `END` | channel off (also unlocks the SFX and restores `hMask`) |
| `$71` | `GLIDE_OFF` | |
| `$72 n` | `TRANSPOSE n` | global transpose |
| `$73` | `NEXT` | next pattern from the order list |
| `$74 w` | `ORDER_JUMP w` | order position = w, then next pattern |
| `$75 n` | `ATTEN n` | |
| `$76 n` | `LENGTH n` | length = n (any value) |
| `$77` | `NOTE_OFF` | volume table = `NoteOffVolTable` (a decay), then wait. The next note restores the previous table |
| `$78` | `NOISE_HIT1` | NR41–44 = `$39 F1 0A C0` |
| `$79` / `$7A` / `$7B` | `PAN_C/R/L` | this channel's NR51 bits: both / right / left |
| `$7C` / `$7D` / `$7E` | `DUTY_50/75/12` | CH1/CH2 only (ignored on Ch3 and on the SFX page) |
| `$7F` | `NOISE_HIT2` | NR42–44 = `$F2 80 80` |
| `$80–$99` | `INSTR n` | run instrument macro n (§3.3) |
| `$9A–$AF` | `PLAY_SFX n` | start sound n, mark the channel, wait. **Stack bug** (§5.1) |
| `$B0–$BE` | `ARP n` | arpeggio table n |
| `$BF–$CE` | `VOL v` | start volume (no envelope change) |
| `$CF–$DE a d r` | `VOLENV v, atk, dec, rates` | start volume v; atk/dec = lo count, hi step; rates = hi attack, lo decay |
| `$DF–$FF` | `LEN n` | length 1–33 |

### 3.3 Instruments

`INSTR n` reads `InstrTable[n]` and runs that macro to its `$70` or `$73`. A macro may use the `$60–$7F` table commands and `$B0–$FF`, but no notes. Before it runs, vibrato, arpeggio, glide and the volume table are switched off. `INSTR 2` and `INSTR 3` also fire a noise hit (NR42–44 = `$F1 60 80`). The macros mostly set duty, `VOLENV`, vibrato and the NR51 bits.

### 3.4 Arpeggios

`ArpTable` has 15 pointers, but only entries 0–2 point to arpeggio data (`0C 00 00 FF`, `0C 07 00 04 73`; entry 2 = entry 1). Entries 3–14 point into the sound table. Each tick (while on) the next byte is added to the note. `$FF` holds (offset 0 from then on). `$73` loops, but **to entry 1, not entry 0** (§5.4).

### 3.5 Sound effects

`PlaySound` (A = id): if `hSfxLock` is set the request is dropped. Otherwise a running SFX is stopped, `wSfxId` = id, `hMaskSaved` = `hMask`, the pointer comes from `SfxTable` (id 1–7), and the stream is parsed for its first tick **inside the call**. SFX streams use the same format and end with `END`.

| Id | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|
| Ticks until `END` | 32 | 14 | 7 | 24 | 24 | 4 | 0 (only a `NOISE_HIT2`, done inside `PlaySound`) |

### 3.6 Volume table

When field `$34` is set (only `NOTE_OFF` does it), each output subtracts the next byte of the table from the volume. `$FF` holds, `$73` loops. The only table is `NoteOffVolTable` (0, 1, 3, 4, 4, 4, 5, … 15, 16, `$FF`).

---

## 4. Timing

- 59.73 Hz with the LCD on, 53.89 Hz while the game has the LCD off.
- Song 2 runs 384 ticks (6.4 s). The title music loops every 9408 ticks (2 min 37 s).

---

## 5. Quirks and bugs

1. **`PLAY_SFX` stack bug:** `Cmd_PlaySfx` is reached by `jp` (not by `call` like the table commands) but finishes through `Cmd_Wait`, which starts with `pop af`. That pop removes `ChannelTick`'s return address, so the final `ret` goes straight back to `SndUpdate`'s caller. The rest of that `SndUpdate` is skipped: later pages aren't ticked and nothing is output that tick. The game's data never uses `PLAY_SFX`; the synthetic test confirms the behaviour (§6).
2. **Locked `PlaySound`** (only reachable through the unused `PlaySoundLock`) clears byte `$39` of page **h**, where h is whatever the caller left in H. From game code that's an arbitrary RAM write.
3. **The SFX page isn't reset when an SFX starts:** only the stream pointer and id are set. Instrument, envelope, transposition, duty etc. carry over from the previous SFX, and an SFX that used `NEXT` would read a stale order list (none does).
4. **Arpeggio loop to entry 1:** `$73` sets the index to 1 and re-reads, so the first entry only plays once.
5. **Legato by accident:** retriggers happen only when the volume or period-hi bits change (§1.1).
6. **Registers 6 and 7 are no-ops:** `hReg6` (period low, written every tick) and `hMask` (`MASK_A/B/AB`, `StopAll` sets it to `$BF`) go nowhere. NR51 is handled by `PAN_C/R/L` instead. `MASK_A` appears in most instruments.
7. **`DUTY_*` is ignored on the SFX page**, so SFX on CH1 use the music's duty.
8. **Bend and arpeggio:** every arpeggio step and every glide step recomputes the period with the bend offset and restarts the bend counter.
9. **`STOP_ALL` in a stream** clears `hSndOn` but the stream reader keeps going until the next note/wait (here: `NEXT` and the next pattern's first note), so that channel's page gets new values that are never played.
10. **`END` on a music channel** also copies `hMaskSaved` to `hMask` and clears `hSfxLock`, as if an SFX had ended.
11. **Dead code/data:** `jr z,+0` at `$524C` (flag b4), fields `$2F/$35–$37`, `PlaySoundChecked`/`PlaySoundLock`, `$55CB` (2 bytes), `$560C` (a `res 4` handler not in the table), 22 bytes at `$50A0`, pattern `$5DB1` (no order list uses it), arpeggio entries 3–14, the 14th `RegHandlerTable` entry (index 13 can't be reached), `$5EC3` (a `NEXT` after the `STOP_ALL` that ends song 2's Ch1), and the first word of the instrument table.
12. **Period table:** 81 entries (C2 to G#8). Near the top it isn't monotonic: `$07E6` is followed by `$07E2`.
13. **`hCh1NoteFlag`** (`$FFF4`) is set at every Ch1 note. I found no read of it in the game code.

---

## 6. Verification

- **Byte-exact rebuild** of all nine ranges (`tools/cmp_ranges.py`).
- **Model vs emulator** (`verify/vmodel.py`). `tools/popup_model.py` is an independent Python model of the driver written from this document. `verify/build_harness.py` builds a copy of the ROM whose boot jump goes to a small harness in free space (`$7E60`). The harness runs the game's sound init, then loops: execute a command from a RAM mailbox, call the real `SndUpdate`, stop at `TickDone`. PyBoy hooks `TickDone`, the model runs the same tick, and these are compared on every tick: all four pages (`$00–$3F`), `$FFDF–$FFF5`, `$C339`, and the readable sound registers (NR11/21 duty, NR12, NR22, NR32 level, NR42, NR43, NR50, NR51).
  - Both songs (8000 ticks), each of the 7 SFX alone, and two mixed scenarios (SFX over music, SFX interrupting SFX, `StopAll` mid-song, song changes): **0 mismatches**.
  - Synthetic test streams in the harness (`harness_popup.asm`) cover the 15 commands the game data never uses (`RELEASE`, `SLIDE`, `BEND`, `BEND_OFF`, `ARP_OFF`, `VIBRATO_OFF`, `MASK_B/AB`, `CHORUS_ON/OFF`, `GLIDE_OFF`, `ORDER_JUMP`, `ATTEN`, `NOISE_HIT1`, `PLAY_SFX` with its stack bug): **0 mismatches**. Every command was run at least once.
  - A deliberately broken model (envelope off by one on Ch2) is caught on the first tick, so the comparison is live.
- **Not verified:** period writes can't be read back from the APU (NR13/14 etc. are write-only), so they're checked only through the page fields they're written from. Trigger timing and wave RAM aren't compared. The timer path (LCD off) was only read; the harness calls `SndUpdate` directly. Nothing was checked on hardware or against emulator audio output.

## Files (in `GBAudioLab\AJG`)

- `PopUp_SoundDriver.asm`: labelled, commented RGBDS source with data macros, byte-exact
- `tools/`: `sm83.py`, `disasm.py`, `codetrace.py`, `listing.py` (disassembly helpers), `asmgen.py`, `notes.py`, `popup_data.py` (data walker), `gen_popup.py` + `comments_popup.py` (asm generator), `popup_model.py` (driver model), `songlen.py`, `cmp_ranges.py`
- `verify/`: `harness_popup.asm`, `build_harness.py`, `vmodel.py`, `run_all.sh`, `run_all.log`

Regenerate: `python tools/gen_popup.py "Pop Up (U) [!].gb" PopUp_SoundDriver.asm` (from the `AJG` folder). Verify: `sh verify/run_all.sh` (needs `pip install pyboy` and RGBDS on PATH).
