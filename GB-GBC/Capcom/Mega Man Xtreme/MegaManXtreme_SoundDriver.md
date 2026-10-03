# Mega Man Xtreme (GBC): sound driver

ROM: `Megaman Xtreme (U) [C][!].gbc` (MBC5, 1 MB, GBC only). Capcom / Tose, 2000.

| | |
|---|---|
| Sound banks | **2, 3, 4**: each holds a full copy of the driver, the same instruments/waves, all 96 SFX and its own set of songs |
| API (each bank) | `$4000` `SndUpdate`, `$4003` `SndPlay` (A = id or command) |
| Game glue | ROM0 `$2A14` `GamePlaySound` (id in `hSndID` `$FFF7`, bank in `hSndBank` `$FFF8`), `$2A27` `GameSelectSoundBank`, `$0B39` VBlank update |
| Driver code | `$4000–$4B38` + header `$4B40` (identical in the 3 banks) |
| Pointer table | `$4B45`, 126 big-endian pointers (ids `$00–$7D`), per bank |
| Instruments / waves | `$4C41` (59 × 8 bytes) / `$4E19` (19 × 16 bytes), identical in the 3 banks |
| Data | bank 2 `$4F49–$7D3E`, bank 3 `$4F49–$7BE3`, bank 4 `$4F49–$7886` |
| RAM | WRAM `$CD00–$CDC9` |
| Tick | VBlank, once per frame; music at 8.8 fixed-point ticks per frame |
| Counts | 25 songs (8 + 7 + 10), 96 SFX (in every bank) |

The sources rebuild **byte-exact** with RGBDS 0.9.1 for 2:`$4000–$7D3E`, 3:`$4000–$7BE3`, 4:`$4000–$7886` and the glue (0:`$0B39–$0B44`, 0:`$2A14–$2A41`). They assemble cleanly with `-Wall`. The rest of each bank is `$00`, with the bank number at `$7FFE`.

```
./build_check.sh      # 4 objects -> mmx_snd.gbc
```

| File | Content |
|---|---|
| `MMX_Sound.inc` | hardware/WRAM names, channel-state offsets (`CHN_*`), all data macros |
| `MMX_SoundDriver.inc` | driver code and tables `$4000–$4B44` (shared source) |
| `MMX_SoundCommon.inc` | instruments and waves `$4C41–$4F48` (shared source) |
| `MMX_SoundBank2/3/4.asm` | `SECTION` for the bank: INCLUDE driver, pointer table, INCLUDE common, songs, SFX |
| `MMX_SoundGlue.asm` | ROM0 glue |

Each bank is its own assembly unit, so the shared driver source can be included three times without label clashes.

---

## 1. Relation to Capcom's NES "6C80" engine

The music format is the `capmusfrm.txt` format almost unchanged. The NES code was translated rather than rewritten: same channel variables, loop/break logic, instrument layout and big-endian pointers.

| NES 6C80 | Mega Man Xtreme |
|---|---|
| Address table `$8A43`, instrument pointer `$8A41` | `SndPointerTable` `$4B45`, instrument pointer `$4B41` (+ wave pointer `$4B43`), id count `$4B40` |
| Commands `$00–$18` | same meaning for `$00–$18`; **`$19` = panning** (NR51 bits for the channel) |
| `$18` duty | `DUTY`: NRx1 on CH1/2, NR43 low bits on CH4 (width/divisor) |
| Instrument: ADSR, vibrato, tremolo, noise-random bit | ADSR, vibrato speed/depth, **byte 6 = NRx1/noise bits, byte 7 = CH3 wave** (tremolo dropped) |
| Software volume envelope per frame | **hardware envelope**: each phase writes NRx2 and retriggers; the driver keeps a copy of the level so it knows when to switch (§3) |
| Periods from a period table | **logarithmic pitch table** (84 notes, C2–B8) converted to GB periods by shifting (`PitchToPeriod`). Vibrato, slides and detune are uniform across octaves. |
| Loops 1–4 with 4 counters | **LOOP3/LOOP4 and BREAK3/BREAK4 use LOOP1's counter** (only 2 counters in the GB channel struct) |
| SFX segments: first byte bit 7 set = end; channel bits 7–4 | first byte = **NR51 panning** of the segment, **0 = end**; channel mask bits 0–3; per-channel settings b0 instrument, b1 duty, b2 volume, b3 slide, b4 detune; note 0 = key off, `$FF` = hold |
| Bank switching per data address | none: the whole sound set of a bank is in that bank, and the game switches banks |

### Three banks

Each bank holds songs for different parts of the game plus every SFX, with bank-specific addresses. The driver takes the id modulo `$7E` and ignores ids whose pointer is 0 in the current bank. The game switches banks with `GameSelectSoundBank`: it stops all sound (command `$F0`), sets `hSndBank`, then plays in the new bank. All three copies share the WRAM state, so switching banks mid-song would run the new bank's code on the old pointers, which is why the game stops first.

| Bank | Songs |
|---|---|
| 2 | `$01 $02 $03 $06 $07 $08 $09 $0A` |
| 3 | `$0B $0C $0D $0E $0F $1C $1D` |
| 4 | `$10 $11 $13 $15 $16 $17 $18 $19 $1A $1B` |

Ids `$04`, `$05`, `$12`, `$14` and `$1E`+ as songs don't exist. `$1E–$7D` are the SFX.

---

## 2. Music format

Header: `$00`, then 4 big-endian channel pointers (CH1–CH4). A channel whose stream starts with `END` stays off.

| Byte | Macro | Meaning |
|---|---|---|
| `00` | `TRIPLET` | toggle triplet lengths |
| `01` | `CONNECT` | toggle; a note after a connected one isn't retriggered |
| `02` | `DOTTED` | next note 1.5× |
| `03` | `OCTUP` | toggle +2 octaves |
| `04 x` | `FLAGS` | `CHN_FLAGS = (CHN_FLAGS & $97) \| x` |
| `05 hi lo` | `TEMPO` | ticks per frame, 8.8 (default `$0199` = 1.6) |
| `06 x` | `HOLD` | key-off at x/256 of the note |
| `07 x` | `VOLUME` | 0–15 (CH3: converted to NR32) |
| `08 n` | `INSTR` | instrument n |
| `09 n` | `OCTAVE` | 0–7 |
| `0A x` / `0B x` | `GTRANSP` / `TRANSP` | signed semitones (all channels / this channel) |
| `0C x` | `DETUNE` | signed, added to the period |
| `0D x` | `SLIDE` | portamento speed; the note starts at the previous pitch |
| `0E–11 n hi lo` | `LOOP1–4` | n = 0: forever. Otherwise the body plays n + 1 times. |
| `12–15 f hi lo` | `BREAK1–4` | on the last pass: `FLAGS f` and jump |
| `16 hi lo` | `JUMP` | |
| `17` | `END` | channel off |
| `18 x` | `DUTY` | |
| `19 x` | `PAN` | `$11` both, `$10` left, `$01` right |
| `20–FF` | `NOTE len, p` / `REST len` | len = bits 7–5 (1–7 → 3, 6, 12, 24, 48, 96, 192 ticks), p = 1–31 |

**Pitch** = p + 12 × octave (+24 with `OCTUP`) + `GTRANSP` + `TRANSP`, capped at 84. 1 = C2. **CH4:** `NR43 = (15 − (p & 15)) << 4 | CHN_DUTY`.

Tempos in the data: `$010B`–`$0266` (1.04–2.40 ticks per frame). A quarter note (48 ticks) at `$022E` lasts 22 frames (about 163 BPM).

## 3. Instruments and envelope

`INSTRUMENT attack, decay, sustain, release, vibspeed, vibdepth, duty, wave`

- **Attack:** index into `EnvRateTable`: an NRx2 value that ramps up from a low volume, or `$FF` = start at full volume. Attack index 0 gives a silent note.
- **Decay:** `~(d − 1) & 7` = hardware step, down to the sustain level.
- **Sustain:** `sustain/16 − (15 − VOLUME)`, minimum 0. 0 = the note ends after the decay.
- **Release** (at key-off): step `~(r − 1) & 7`. Bit 3 set = cut. CH3 is always cut.
- **Vibrato:** speed = byte 4 bits 6–0 (bit 7 = restart per note), depth = byte 5 (bit 7 = centred).
- **Byte 6:** NRx1 / NR43 bits. **Byte 7:** CH3 wave (1-based, 0 = keep).

Every phase change rewrites NRx2 and **retriggers** the channel. That's the only way to change a GB envelope. The driver tracks the volume in `CHN_ENVLEVEL` to time the switches.

34 of 59 instruments are used (music 0, 2–14, 16, 22, 28–30, 37; SFX 21–36, 47, 58). 53–56 are all zero. Waves used on CH3: 2, 6, 8–12 of 19.

## 4. SFX

`SFX_PRIORITY p, loop`, then segments:

```
SEGMENT pan, flags        ; pan = NR51 bits (0 = end), flags b0 loop, b1 hold, b2 transpose
[SEG_LOOP n, label]       ; n = 0: forever
[SEG_HOLD x] [SEG_TRANSP x]
SEG_FRAMES frames, mask   ; mask bits 0-3 = CH1-CH4
db flags, values..., note ; per channel in the mask (the asm comments decode it)
```

A new SFX needs priority ≥ the current one (equal priority also cancels a looping SFX). When an SFX gives a channel back, `ReleaseChannel` restores the music's NRx1, panning and CH3 wave and restarts the music's current note at its current envelope level (or silences it if its envelope has finished), so the music comes back immediately. No SFX in this game uses the loop flag. All 96 SFX end exactly at their decoded end marker (§8). Durations: 3 (`$26`, `$67`) to 468 frames (`$68`).

## 5. Commands (`SndPlay` with A ≥ `$F0`)

`$F0` stop all, `$F1` stop SFX, `$F2` stop music, `$F3` pause music, `$F4` resume, `$F5` fade in (B = speed), `$F6` fade out, `$F7` pitch of a looping SFX (B). The fades take B from the caller, but `GamePlaySound` doesn't set B. The game only uses `$F0` (in `GameSelectSoundBank`).

## 6. Songs

Uses found in game code (bank:address of the call). Only the title was identified on screen.

| Id | Bank | Addr | Bytes | Tempo | End | Requested from |
|---|---|---|---|---|---|---|
| `$01` | 2 | `$4F49` | 282 | `$022E` | loops | `$1C:76FA`, `$33:6FEC` |
| `$02` | 2 | `$5067` | 170 | `$0180` | loops | `$09:6715`, `$09:673C`, `$33:701A` |
| `$03` | 2 | `$5115` | 1021 | `$022E` | loops | `$09:6763`, `$09:6793` |
| `$06` | 2 | `$5516` | 422 | `$0199` | loops | `$11:73CB` and 5 more in bank `$11` (menu code) |
| `$07` | 2 | `$56C0` | 1364 | `$01C7` | loops | stage table, stage 0 |
| `$08` | 2 | `$5C18` | 999 | `$022E` | loops | stage 3 |
| `$09` | 2 | `$6003` | 1992 | `$022E` | loops | stage 1 |
| `$0A` | 2 | `$67CF` | 1901 | `$01C7` | loops | stage 2 |
| `$0B` | 3 | `$4F49` | 1060 | `$022E` | loops | stage 4 |
| `$0C` | 3 | `$5371` | 2528 | `$0216` | loops | stage 7, `$3F:78C2` |
| `$0D` | 3 | `$5D55` | 859 | `$0249` | loops | stage 5, `$10:6E7A` |
| `$0E` | 3 | `$60B4` | 311 | `$022E` | ends | `$15:57BF` |
| `$0F` | 3 | `$61EB` | 970 | `$0266` | loops | stage 6 |
| `$1C` | 3 | `$65B9` | 620 | `$0249` | ends | `$0A:633B`, `$33:66E2`, `$33:672D`; after Start on the title |
| `$1D` | 3 | `$6825` | 1472 | `$010B` | ends | `$33:6EB9` |
| `$10` | 4 | `$4F49` | 1684 | `$0249` | loops | stage 9 |
| `$11` | 4 | `$55E1` | 302 | `$0216` | ends | `$30:706A` |
| `$13` | 4 | `$570F` | 422 | `$0143` | loops | stages 10–11, `$10:6C64`, `$10:6CE8` |
| `$15` | 4 | `$58B9` | 1386 | `$0200` | loops | stage 8, `$10:6E58`, `$3F:78E4` |
| `$16` | 4 | `$5E27` | 501 | `$0266` | loops | stage 12 |
| `$17` | 4 | `$6020` | 375 | `$0266` | loops | `$09:67F3` |
| `$18` | 4 | `$619B` | 411 | `$01C7` | loops | `$09:67C3` |
| `$19` | 4 | `$633A` | 342 | `$0266` | loops | `$2F:591A`, `$2F:5AB1`, `$2F:5D1D` |
| `$1A` | 4 | `$6494` | 836 | `$01B6` | loops | **title** (confirmed), `$2E:738F`, `$33:664D`, `$35:*` |
| `$1B` | 4 | `$67DC` | 680 | `$01D8` | loops | `$33:66B3`, `$35:5BA1` |

"Stage n" is an entry of the game's stage table at `$11:7453` (id, bank pairs indexed by `$D35F`): `07 09 0A 08 0B 0D 0F 0C 15 10 13 13 16`. The stage names behind the indexes weren't identified.

SFX confirmed on screen: `$30` text blip, `$4D` menu select.

---

## 7. Quirks and bugs

1. **Three copies of the driver** (2,885 bytes of code/tables, 776 bytes of instruments/waves and 3,583 bytes of SFX, about 7.2 KB per bank), identical apart from addresses. Bank switching costs a full stop of all sound.
2. **Loops 3/4 share LOOP1's counter** (and BREAK3/4 break on it). Nesting LOOP1 and LOOP3 would corrupt both. The data never nests them.
3. **`DottedLengths` has 0 for 64ths and whole notes,** so a dotted whole note would last 0 ticks (the NES doc notes that dotted whole notes don't work). The data never dots those lengths.
4. **`DOTTED` during `TRIPLET` is postponed:** triplet lengths win and the dotted flag stays set until the next non-triplet note. It occurs in the data (about 49 places in a linear scan).
5. **Commands `$1A–$1F` aren't in the table** (26 entries) and would jump to data. Unused.
6. **Every envelope phase change retriggers the note** (attack → decay → sustain → release), which resets the pulse phase. That's inherent in using the hardware envelope.
7. **Attack index 0 gives a silent note** (`EnvRateTable[0] = 0` → `ChannelSilence`). No instrument has attack 0 except the empty 53–56.
8. **The fade commands read B/C from the caller,** and the only API path (`GamePlaySound`) doesn't set them. They're unused by the game. After a finished fade-out the driver writes NR51 = 0 and skips all music writes until a new song.
9. **Ids ≥ `$7E` wrap** (modulo `$7E`), and a song missing from the current bank is silently ignored.
10. **Unreachable data:** an `END` byte after every `JUMP` (32 + 16 + 36 bytes) and 7 bytes at `$4B39` (`10 83 7E F6 00 74 0A`) that nothing reads.

## 8. Verification

- Byte-exact rebuild of the three banks and the glue (`build_check.sh` + range compare).
- **Test harness** (`harness/`): a small GBC ROM linking the **rebuilt** banks. Python writes bank/id to `$C001–$C003`; the VBlank handler calls `SndPlay`/`SndUpdate`.
- **Music:** for all 25 songs, 3600 frames each, the pitch passed to `PlayNote` on every channel matches a walk of the decoded streams (octave/OCTUP/transposes, both loop counters, breaks, connect, slides). Timing wasn't compared.
- **SFX:** all 96 SFX in each of the 3 banks end exactly at their decoded end marker. Their frame counts are the same in all banks, and a structural compare shows the three copies are identical apart from addresses.
- **Real ROM:** boot → title plays `$1A` (bank 4); Start → `$1C` (bank 3).
- Not verified: roles of most songs and SFX, envelope timing against hardware. Nothing was checked on hardware.

## Files (in `GBAudioLab\CAP\MegaManXtreme`)

- the `.inc`/`.asm` sources above and `build_check.sh`
- `harness/`: `harness.asm`, `build.sh`
- `tools/`: `mmxparse.py`, `gen_mmx.py` (+ shared `asmgen.py`, `sm83.py`); `verify/`: PyBoy scripts
