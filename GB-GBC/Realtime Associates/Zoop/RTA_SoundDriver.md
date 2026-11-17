# Realtime Associates Sound Driver: Zoop, Star Wars – Super Return of the Jedi

Disassembly and documentation of David Warhol's Realtime Associates Game Boy sound driver, from two games:

| ROM | Size | Driver bank(s) | Driver RAM |
|---|---|---|---|
| `Zoop (U) [!].gb` | 64 KB, MBC1 | bank 3 | WRAM `$DF00–$DF3D` |
| `Star Wars - Super Return of the Jedi (U) [S][!].gb` | 512 KB, MBC1 | banks 4 and 5 (two copies) | HRAM `$FF8A–$FFC7` |

SROTJ's credits read "Music Arrangements and Sound Effects … Realtime Associates" (bank 2 `$4C02`). Everything here comes from the code; the interfaces were checked in PyBoy.

## Summary

- **One driver, two builds.** The code is the same instruction for instruction. Zoop keeps its variables in WRAM (`ld [nnnn]`), SROTJ in HRAM (`ldh`), so SROTJ's copy is `$41` bytes shorter and its tables start at `$43D2` instead of `$4418`. The tables themselves (waves, periods, programs, the 97 patches) are **byte-identical** in both games.
- **Converted MIDI, type 0.** A song is a single stream for all 16 MIDI channels: note-on, release (note-off), program change and wait, one frame per tick. Note-ons are 1 byte: each song starts with a table of the (channel, key) pairs it uses, and an event is an index into that table.
- **Programs choose the hardware channel.** The program of a MIDI channel picks one of 74 driver instruments. Programs `$00–$1F` play on CH1, `$20–$3F` on CH2, `$40–$47` on CH3 and `$48+` on CH4, whatever the MIDI channel. Each hardware channel is one voice; the last note wins.
- **Instruments are patch chains.** A note-on starts the program's attack patch, a release its release patch. A patch is a 12-byte register image with a duration, a per-step period delta (vibrato, slides) and a link to the next patch.
- **SFX are register images too**, with waits and an optional random transpose. They play on top of the music and mute its voices on the channels they use until they end.
- **Shared sound table.** Songs and SFX share one 64-entry table; bit 7 of the id selects music.

---

## 1. Interface

The bank starts with a jump table. The game maps the bank, calls the entry and maps its bank back.

| Entry (both games) | Routine | Zoop | SROTJ | Effect |
|---|---|---|---|---|
| `$4001` | `SndUpdate` | `$403A` | `$4035` | `SfxUpdate`, then `MusicUpdate` |
| `$4004` | `SndPlay` | `$432E` | `$4307` | a = sound id |
| `$4007` | `SndStopAll` | `$402A` | `$4027` | music timer = 0, SFX timer = 0, `SndPowerCycle` |
| `$400A` | `SndPausePlay` | `$401C` | `$401A` | `wMusPaused` = 1, `SndPowerCycle`, `SndPlay(a)` |
| `$400D` | `SndInit` | – | – | `SndPowerCycle`, SFX timer = 0, `wMusPaused` = 0, NR50 = `$77`. Also the "resume" after a pause |

`SndPowerCycle` = `SndSilence` (NR12/NR22/NR32/NR42 = 0, NR14/24/34/44 = 0, the four voice timers = 0), then NR52 = 0, NR52 = `$FF`.

### 1.1 Sound ids

| Id | Meaning |
|---|---|
| `$80 \| n` | music: song n (`n` = id & `$3F`) |
| `$40 \| n` | high-priority SFX n: always starts, and normal SFX are ignored until it ends |
| `n` | SFX n (ignored while a high-priority SFX plays) |

**Starting a song**: `SndSilence`, then `MusicStart`: read the header, NR50 = `$77`, NR51 = `$FF`, music timer = 1. It also clears `wMusPaused`, so a new song ends a pause.

**Starting an SFX**: SFX timer, transpose and extra wait = 0. On each channel the previous SFX owned, NRx2 = 0 and the claim is dropped. Then the priority flag is set from bit 6, the pointer is loaded, NR50 = `$77`, NR51 = `$FF`, SFX timer = 1.

### 1.2 Zoop (game side)

| Address | Routine |
|---|---|
| `$02A3` | timer interrupt: TAC = 0, bank 3, `SndUpdate`. The VBlank handler (`$0247`) starts the timer each frame (TAC = `$06`, TIMA = `$02`), so the update runs **once per frame, ~3.9 ms after VBlank** (59.73 Hz, LCD on) |
| `$05C5` | reset: clear `$DF00–$DF3D`, `wSndRandom` = `$47`, then `$0630`. Called at boot (`$01F7`) |
| `$05D7` | `SndPlay(a)` |
| `$05F3` | `SndPlay(a)` if the music (`$C831`, ids with bit 7, id stored in `$DB08`) or SFX (`$C830`) option is on. 80 call sites |
| `$0630` | `SndStopAll`, `$DB08` = `$FF` |
| `$064F` | `SndUpdate` (two extra calls, 01:`$55A0`, 01:`$64E8`) |
| `$0663` | `SndPausePlay($63)`: high-priority SFX `$23` |
| `$067F` | `SndInit` (resume) |
| `$0699` / `$069E` | a = music timer / SFX timer (never called) |

### 1.3 Star Wars – Super Return of the Jedi (game side)

Banks 4 and 5 each hold a full copy of the driver, tables and SFX; only the songs differ. `$1715` is a trampoline: it saves the current bank (read from `$4000`: every bank of this ROM starts with its number), maps bank 5 if `$DDA4` = 5 and bank 4 otherwise, and returns into the caller. The caller's tail at `$16C9` restores the bank.

| Address | Routine |
|---|---|
| `$0050` → `$16C3` | timer interrupt: `SndUpdate`. TMA = `$BC`, TAC = `$04` (`$019B`): 4096 / 68 = **60.24 Hz**, free-running |
| `$164F` | reset: clear `$FF8A–$FFC7`, `hSndRandom` = `$47` (boot, `$01A5`) |
| `$165E` | SFX: a = id. Skipped if the SFX option `$DDA9` is off (except id `$30`). Priority table `$169C` indexed by id − `$0C` (`$28` for all, `$00` for `$0C`, `$0A` for `$30`): while an SFX plays, a lower value than the current one (`$DE6E`) is dropped |
| `$16D4` | music: a = `$80 \| n`, plus `$40` for bank 5. Skipped if the music option `$DDA8` is off or the id equals the current one (`$DA6C`). `$DDA4` = 5 if bit 6, else 4; then `SndPlay(id & $BF)` |
| `$16FD` | pause: `SndPausePlay($30)` (SFX `$30` is silence) |
| `$1707` | resume: `SndInit` if the music option is on |

SFX play in whichever bank `$DDA4` last selected, which is why both banks carry them. Ids seen as immediates: music `$80`, `$83`, `$8C` (stub, used to stop the music), `$C0`; SFX `$12`, `$13`, `$15`, `$1A`, `$1B`, `$27`, `$28`, `$30`, `$32`.

---

## 2. Music

### 2.1 Song header

```
db numDefs             ; n
db chan[n]             ; MIDI channel (0–15) of note def i
db key[n]              ; key of note def i: period index + 3
events…
```

`MusicStart` keeps `wMusNumDefs` = n, `wMusDefs` = the address of `chan[]`, `wMusPtr` = the first event.

**Keys.** A key k plays `Periods[k − 3]`, index 0 = C2 (65.4 Hz on CH1/CH2; CH3 sounds an octave lower). This is consistent with key = MIDI key − 33. `rta_sound.inc` names the keys `A_1` (0) … `Gs8` (83).

### 2.2 Events

The ranges move with n:

| Byte | Event | Effect |
|---|---|---|
| `0 … n−1` | **note** i | voice of `wChanProg[chan[i]]`: timer = 1, patch = `ProgAttack[prog]`, note = key[i] − 3, count = 1 |
| `n … n+15` | **release** c | prog = `wChanProg[c]`; if `ProgRelease[prog]` ≠ 0: voice timer = 1, patch = it, count = 1 (the note stays) |
| `n+16 … n+31`, p | **program** c, p | `wChanProg[c]` = p |
| `n+32 … $FD` | **wait** w = byte − n − 32 | music timer = w; run the voices; the next event is read w ticks later |
| `$FE`, id | **goto** | `MusicStart(id & $3F)`; the voices are not run this tick |
| `$FF` | **end** | run the voices; the pointer stays and the timer stays 0 |

Notes:

- **Voice choice.** Programs `$48+` use voice 4; otherwise `VoiceOfs[(prog >> 5) & 3]` gives voice 1–3. A release reaches whatever voice its program maps to, whatever note is playing there.
- **Timer 0.** After `end` (or `SndStopAll`), `MusicUpdate` only runs the voices while NR52 still shows a channel on.
- **No reset of programs.** `wChanProg` is only cleared by the game's reset; every song sets the programs it uses in its first frame.
- **Velocity** is not kept, and the longest wait is `$FD` − n − 32 frames.
- Every real song ends with `$FE` + `$80 | its own index`, so all songs loop from the start. The stub song (`01 00 00 FF`) plays nothing and is used to stop the music.

Songs use MIDI channels 0–3; Zoop songs 2, 3 and 5 put the noise on channel 9 (the GM drum channel).

### 2.3 Voices

`UpdateVoices` runs the four voice records (`wVoice1–4`, 6 bytes: timer, patch, note, period lo, period hi, count). For each voice whose timer is not 0:

1. Decrement the timer; if it is not 0, skip.
2. If an SFX owns the channel, timer = 0 and skip (the music stays silent there until the next note).
3. Run one step of patch `Patches[patch]` (§2.4).

A note-on sets the timer to 1, so it sounds in the same tick.

### 2.4 Patches

12 bytes. Macro `patch flags, ofs, delta, and, or, dur, next, cnt, reg, r1, r2`:

| Byte | Field | Use |
|---|---|---|
| 0 | flags | bit 7: trigger (OR'ed into the period's high byte); bit 0: (re)load the period from the note |
| 1 | ofs | added to the period's low byte when it is loaded |
| 2–3 | delta | signed, added to the period on every step |
| 4, 5 | and, or | NR51 = (NR51 & and) \| or |
| 6 | dur | voice timer: ticks to the next step (0 = last step) |
| 7, 8 | next, cnt | see below |
| 9 | reg | `$00–$FC`: NRx0 = reg, NRx1 = r1, NRx2 = r2, then NRx3/NRx4 = the period |
| | | `$FD`: noise. NR42 = r1, NR43 = r2 \| (note & 7) << 4, NR44 = `$80`; no period |
| | | `$FE`: CH3 wave r1 (byte offset into `Waves`): NR30 = 0, wave RAM, NR32 = `$20`, NR30 = `$80`, then NR33/NR34 = voice 3's period |
| | | `$FF`: period only |
| 10, 11 | r1, r2 | |

A step:

1. **Period.** With bit 0: period = `Periods[note] + ofs`, OR'ed with bit 7 of flags. Without it, only the trigger bit is OR'ed in. Then add delta. If the result has any of bits 11–13 set, the period becomes 0.
2. **Pan.** Write NR51.
3. **Timer and chain.** Timer = dur. If count ≠ 0, decrement it; when it reaches 0, patch = next and count = cnt. So a patch's `cnt` is how many steps its successor runs before following its own `next`. Count 0 stays on the current patch.
4. **Registers.** Write them by `reg`. After the period write, the trigger bit is cleared in the voice record.

The register block of voice k is `RegBase[k]` (`$FF10`, `$FF15`, `$FF1A`, `$FF1F`). CH2 and CH4 write their "NRx0" byte to the unused `$FF15` / `$FF1F`.

Most patches pan their channel to both sides (and/or `$EE/$11`, `$DD/$22`, `$BB/$44`, `$77/$88`). The exceptions: programs `$0E` and `$12` put CH1 on the left only (or = `$10`, patches 21, 31–34), and `$2E` puts CH2 on the right only (`$02`, patch 63).

**Example: vibrato** (programs `$10`/`$30`). Patch 25: trigger, period, +1, 1 tick, next 26 for 2 steps. Patch 26: −1 per tick, period only, next 27 for 2 steps. Patch 27: +1, next 26 for 2 steps. The period then swings by ±2 around the note.

### 2.5 Programs

`ProgAttack` / `ProgRelease`, 74 entries each (identical in both games):

| Programs | Voice | Instruments |
|---|---|---|
| `$00–$14` | CH1 | patches 0–41. `$00–$0B`: duty 12.5/25/50 % × NR12 `$70` (held, with a `$72` decay as release) or `$73`/`$75`/`$77` (decaying, no release). `$0C–$14`: duty change after 2 ticks, vibrato (`$10`, `$11`; delayed in `$12`), pitch drops on release (`$13`, `$14`) |
| `$15` | CH1 | attack 0, release 96 (the patch 93–96 group; 93 is never reached) |
| `$16–$1F` | CH1 | attack 0 (default), no release |
| `$20–$34` | CH2 | patches 42–83: copies of `$00–$14` (patch + 42) with CH2 pan; except the release of `$2D` (§7) |
| `$35–$3F` | CH2 | patch 42 |
| `$40–$43` | CH3 | waves 0–3 (patches 84, 88, 89, 90), release 85 → 86 (NR32 `$60`, then DAC off) |
| `$44–$47` | CH3 | attack 0 (a CH1 patch on voice 3), no release |
| `$48`, `$49` | CH4 | patches 91, 92: NR42 `$61` / `$65`, NR43 `$x7`; the key picks the shift clock |

Programs used by the songs: Zoop `$08 $0B $0C $13 $25 $41 $48`; SROTJ `$00–$04 $06–$09 $0B–$0E $10 $12 $20–$23 $26 $27 $29 $2A $2C $2D $2F $31 $32 $34 $40–$43 $48`.

---

## 3. Sound effects

`SfxUpdate` runs first in each tick. With the SFX timer at 0, it clears the four channel claims and the priority flag. Otherwise it decrements the timer and, at 0, reads events until a wait:

| Bytes | Macro | Effect |
|---|---|---|
| `$00` NR10 NR11 NR12 lo hi | `sfx_pulse1` | NR10 = 1, NR11 = NR12 = NR14 = 0 (reset), then NR10–NR12, NR13 = lo + transpose, NR14 = (hi + carry) & `$C7`. Claims CH1 |
| `$01` NR21 NR22 lo hi | `sfx_pulse2` | NR21, NR22, NR23/NR24 as above. Claims CH2 |
| `$02` | `sfx_wave` | nothing: there are no CH3 SFX |
| `$03` NR41 NR42 NR43 NR44 | `sfx_noise` | the four registers. Claims CH4 |
| `$FE` addr | `sfx_jump` | continue at addr |
| `$FF` m1 m2 | `sfx_random` | transpose = rnd & m1, extra wait = rnd & m2 |
| `$04` | `sfx_end` | timer = 0: the claims are dropped on the next tick |
| `$05–$FD` | `sfx_wait` w | timer = w + extra wait (w = byte − 4) |

- **Transpose** is added to the period's low byte, not in semitones.
- **Random.** `SndRandom` is a shift register: new = (x << 1) \| (bit 5 xor bit 6), seeded with `$47` by the game.
- **Claims.** A claimed channel mutes the music voice there (§2.3). Ending an SFX doesn't silence it, and the music comes back with its next note on that channel.
- **Extra wait wrap.** If w + extra wait = 256, the SFX ends early.

| | Zoop | SROTJ |
|---|---|---|
| Table entries | `$08–$2E` (`$26–$2E` = one silent SFX) | `$0D–$33` (same in both banks) |
| Data | `$4A84–$5250`, 31 SFX | `$4A48–$4E40`, 39 SFX |
| Chained | – | `$29` jumps to `$14` |

---

## 4. Sound table and songs

`SoundTable` (Zoop `$4A26`, 47 entries; SROTJ `$49E0`, 52 entries): pointers for ids 0–`$3F`. The SFX data comes first, then the songs.

| Game | Index | Address | Size | Defs | Events | Loop | |
|---|---|---|---|---|---|---|---|
| Zoop | `$00` | `$5251` | 1,044 | 31 | 976 | 2,293 f (38.4 s) | |
| | `$01` | `$5665` | 1,079 | 50 | 971 | 2,545 f (42.6 s) | |
| | `$02` | `$5A9C` | 1,732 | 35 | 1,657 | 3,546 f (59.4 s) | |
| | `$03` | `$6160` | 1,335 | 37 | 1,255 | 2,583 f (43.2 s) | |
| | `$04` | `$6697` | 1,933 | 61 | 1,805 | 2,940 f (49.2 s) | |
| | `$05` | `$6E24` | 1,460 | 50 | 1,354 | 2,822 f (47.2 s) | |
| | `$06` | `$73D8` | 1,452 | 38 | 1,370 | 2,493 f (41.7 s) | |
| | `$07` | `$7984` | 4 | 1 | – | – | stub |
| SROTJ bank 4 | `$00` | `$4E41` | 298 | 14 | 264 | 508 f (8.4 s) | |
| | `$01` | `$4F6B` | 456 | 17 | 416 | 1,036 f (17.2 s) | |
| | `$02` | `$5133` | 1,014 | 75 | 853 | 1,473 f (24.5 s) | |
| | `$03` | `$5529` | 2,921 | 80 | 2,744 | 3,684 f (61.2 s) | |
| | `$04` | `$6092` | 2,909 | 86 | 2,714 | 3,254 f (54.0 s) | |
| | `$05` | `$6BEF` | 242 | 21 | 194 | 1,234 f (20.5 s) | |
| | `$06` | `$6CE1` | 2,899 | 88 | 2,704 | 4,250 f (70.6 s) | |
| | `$07` | `$7834` | 1,302 | 46 | 1,194 | 2,979 f (49.5 s) | |
| | `$08–$0C` | `$7D4A` | 4 | 1 | – | – | stub |
| SROTJ bank 5 | `$00` | `$4E41` | 1,255 | 50 | 1,134 | 2,038 f (33.8 s) | id `$C0` |
| | `$01–$0C` | `$5328` | 4 | 1 | – | – | stub |

Seconds at 59.73 Hz (Zoop) and 60.24 Hz (SROTJ).

**After the data.** Zoop `$7988–$7FFF`, SROTJ bank 4 `$7D4E–$7FFD` and bank 5 `$532C–$7FFF` hold leftover bytes from the build: tile maps, graphics and menu text ("SELECT HERO", "EASY BRAVE JEDI"). The driver never reads them; the asm keeps them as `Leftover` for byte-exact banks.

---

## 5. Tables

| Table | Zoop | SROTJ | Contents |
|---|---|---|---|
| `Waves` | `$4418` | `$43D2` | 4 × 16: square, a "folded" ramp, a 4/`$FB` square, a sawtooth |
| `Periods` | `$4458` | `$4412` | 81 words, C2 (`$002C`)–G#8 |
| `RegBase` | `$44FA` | `$44B4` | `$FF10`, `$FF15`, `$FF1A`, `$FF1F` |
| `VoiceOfs` | `$4502` | `$44BC` | 0, 6, 12, 18 (the last is never used) |
| `ProgAttack` | `$4506` | `$44C0` | 74 bytes |
| `ProgRelease` | `$4550` | `$450A` | 74 bytes |
| `Patches` | `$459A` | `$4554` | 97 × 12 |
| `SoundTable` | `$4A26` | `$49E0` | 47 / 52 words |

## 6. RAM

Zoop at `$DF00`, SROTJ at `$FF8A` (+`$208A`), 62 bytes. Names `w…` / `h…` in `rta_wram.inc` / `rta_hram.inc`:

| Offset | Name | |
|---|---|---|
| `+$00` | `SndRandom` | shift register |
| `+$01` | – | unused |
| `+$02` | `SfxTranspose` | |
| `+$03` | `SfxTimer` | 0 = no SFX |
| `+$04` | `SfxPtr` | |
| `+$06` | `SfxWaitAdd` | random extra wait |
| `+$07–$0A` | `SfxOwnCh1–4` | `$FF` = claimed (CH3 is never claimed) |
| `+$0B` | `SfxHighPri` | `$40` while a high-priority SFX plays |
| `+$0C` | `MusNumDefs` | |
| `+$0D` | `MusDefs` | |
| `+$0F` | `MusPtr` | |
| `+$11` | `MusTimer` | 0 = stopped/ended |
| `+$12`, `+$13`, `+$15` | – | written (`$FF`, 0, wave), never read |
| `+$14` | `MusPaused` | |
| `+$16`, `+$1C`, `+$22`, `+$28` | `Voice1–4` | timer, patch, note, period lo, period hi, count |
| `+$2E` | `ChanProg` | 16 programs |

---

## 7. Quirks and bugs

1. **Keys below C2.** Key values 0–2 index the period table at −3…−1. `add a, a` drops the carry, so the period is read from `ProgRelease` instead. Zoop song 4 plays its CH3 bass A1/A♯1/B1 notes (28 note-ons) with periods `$0005`/`$0000`/`$0000`, a ~32 Hz rumble. Song 2 has one such CH1 note. Noise keys are not affected (no period is written).
2. **Program `$2D` never releases.** Its release patch is 44 (a CH2 *attack*: retrigger at constant volume 7) where the CH1 original `$0D` has 20 (a decay), so the CH2 copy should be 62. A release on `$2D` re-sounds the note and it holds until the next note on CH2. SROTJ uses `$2D` in bank 4 songs 2, 5 and 6. Probably a table typo.
3. **Stray byte in SROTJ SFX `$2D`** (`$4DEF`). After its `sfx_pulse2` there is an extra `$00`. The driver reads it as `sfx_pulse1` with the next 5 bytes, then reads SFX `$2E`/`$2F`/`$30` as more CH1 commands in the same tick, until the `sfx_end` at `$4E0D`. The last write is all zeros, so it ends silent. The asm keeps the bytes as `db`.
4. **Unreferenced byte** at SROTJ `$4E1C`, after SFX `$31`.
5. **`$FE` writes CH3's period** whatever the voice. Only CH3 programs use it.
6. **`$FD` returns from `UpdateVoices`** (`pop af` ×2, `ret`). That is fine because the noise voice is the last one.
7. **No CH3 SFX.** `$02` does nothing, and `SfxOwnCh3` is never set.
8. **Resume clears NR51.** `SndInit` power-cycles the APU, so NR51 is 0 and every voice is idle. Each channel comes back with its next note, whose patch step ORs its own pan bits back.
9. **SFX don't restore the music.** Claimed channels stay silent until a new note on that voice.
10. **Data limits.** A program ≥ 74 or a patch ≥ 97 would read past its table; no data does.
11. **Bank byte.** Zoop's `$4000` is `$01`, read by nothing. In SROTJ it is the bank number (`$04`/`$05`) that the trampoline reads.

---

## 8. Verification

**Rebuild.** `tools/verify.py` assembles the three files with `-Wall` (no warnings) and compares whole banks: Zoop bank 3, SROTJ banks 4 and 5, **3 × 16,384 bytes, 0 mismatches**.

**Emulator.** `verify/emucheck.py` links the generated asm with a small harness ROM (`verify/harness.asm`: one `SndUpdate` per VBlank, plus a script of `SndPlay` / `SndStopAll` / `SndPausePlay` / `SndInit` calls). It runs the harness in PyBoy, hooking every store and the NR51/NR52 reads in the driver code. `tools/model.py` is written from this document. Each sound-register write, tick by tick, was compared with the model's:

- every song alone for one loop + 300 ticks;
- every SFX alone and as high-priority;
- every song with SFX fired on top, then pause, resume and stop.

Result: **302 cases, 193,356 ticks, 253,464 register writes, 0 mismatches** (`verify/emucheck.log`). A deliberately broken model (period carry dropped) fails 14 cases, so the check is sensitive.

## 9. Files

In `GBAudioLab\RTA\`:

| File | Contents |
|---|---|
| `Zoop_SoundDriver.asm` | bank 3: driver, tables, SFX, songs, leftover |
| `SROTJ_SoundDriver_Bank4.asm`, `…_Bank5.asm` | banks 4 and 5 (each self-contained; labels are file-local) |
| `rta_sound.inc` | registers, voice fields, `patch`, song macros (`song_header`, `note`, `release`, `program`, `wait`, `song_goto`, `song_end`), SFX macros, key names |
| `rta_wram.inc`, `rta_hram.inc` | RAM for each game |
| `tools\gen_rta.py`, `tools\inc_static.txt` | generator |
| `tools\rta.py`, `tools\sm83.py`, `tools\disasm.py` | data parser, disassembler, listing helper |
| `tools\verify.py`, `tools\model.py` | rebuild check, reference model |
| `verify\harness.asm`, `verify\emucheck.py`, `verify\*.log` | emulator check |

RGBDS 0.9.1, PyBoy 2.9:

```
python tools\gen_rta.py "Zoop (U) [!].gb" "Star Wars - Super Return of the Jedi (U) [S][!].gb" .
python tools\verify.py "Zoop (U) [!].gb" "Star Wars - Super Return of the Jedi (U) [S][!].gb" .
python verify\emucheck.py "Zoop (U) [!].gb" "Star Wars - Super Return of the Jedi (U) [S][!].gb" .
```
