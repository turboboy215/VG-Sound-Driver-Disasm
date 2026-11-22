# Baby Felix: Halloween: sound driver

ROM: `Baby Felix - Halloween (E) (M6) [C][!].gbc` (GBC-only, MBC5, 1 MB, internal title `BABY FELIX`). Sound bank **19**.

Part of the AJG family (Alberto José González / Bit Managers), see `AJG_SoundEngine_Family.md`. This is **version 4**, Rage Wars line, and **the latest build so far**: the bank names the driver right after its code (`$4C94`) as `(Music & Sound Driver by Alberto Jose Gonzalez, 2001)`, and the data ends with `Final de la rutina de musica` (`$794D`).

**The driver is Martian Alert's** (`MartianAlert_SoundDriver.md`), with its three differences from Rage Wars, revised again:

- the RAM is back in **WRAM bank 0**, pages `$C1–$C4`;
- **`SLIDE_UP`/`SLIDE_DOWN` are gone** and a new **`ARP_INLINE`** (an arpeggio written in the stream) is added at the end, so all ranges move;
- the vibrato speed is **signed** (as in Radikal Bikers, coded differently);
- `INSTR` also stops the release; `REST` writes NRx2 = `$08`; the page reset clears the `HWENV` fields;
- new output details in `SndInit`, `StopAll` and the fades;
- the game's **SFX glue sits inside the driver** (ids 26, 27, 38), and `PlaySfx` ignores ids ≥ 39.

| | |
|---|---|
| Bank | 19: driver `$4000–$4C93`, credit text, song data from `$4CC9` (an endless-wait pattern, then song 2's routine); sound data up to `$7968`, then zeros |
| Command table | `$4000`, **42 commands** (`$60–$89`): Rage Wars' set without `SLIDE_UP`/`SLIDE_DOWN`, plus `ARP_INLINE $89` |
| API jump table (`$4054`) | `SndUpdate $40EA`, `SndPause $40CF`, `SndResume $40C8`, `StopAll $456B`, `PlaySong $406F` (A = 0–10), `PlaySfx $4A16` (A = 1–38), `SndInit $4550`, `SongFadeIn $4A6A`, `SongFadeOut $4A64` |
| Song table | `$6F8B`, 11 entries |
| Default instrument table (`PlaySong`) | `$6EE0` (14 used); 7 songs set it again themselves, songs 6, 8 and 9 set their own (`$5538`, `$5E6E`, `$63DC`) |
| `StartMusicCh1/2/3` | `$49F0` / `$49F4` / `$49F8` |
| Tick | once per frame, in VBlank (bank-0 far call, return address `$3FF3`) |
| RAM | pages Ch1 `$C1xx`, Ch2 `$C2xx`, Ch3 `$C3xx`, SFX `$C4xx` (fields `$00–$3F`); globals `$C140–$C165` in Rage Wars' order (`wPaused $C140`, `wInstrTable $C145`, `wArpTable $C147`, duty shadows `$C163/$C164`, `wCurSong $C165`) |
| Ranges | **`INSTR $8A–$9E`** (21), **`ARP $9F–$AE`** (16), **`VOLENV $AF–$BE`**, **`LEN $BF–$EE`** (1–48), **`REPEAT $EF–$FF`** (2–18); drum bytes as Rage Wars except **tempo `$BF–$FE`** |
| Tables | arpeggios `$6F43` (16 used, set by `SndInit`), SFX `$6FC1` (38; entry 38 is a placeholder), CH3 volume `$41D6`, drums `$4B83` (14), period table `$4900`; fades `$793A` / `$7944` |
| Counts | 11 songs, 38 SFX (1 noise only), 14 waves, 14 drum sounds, 23 drum patterns |

It rebuilds **byte-exact** with RGBDS 0.9.1 over the whole sound bank:

```
rgbasm -Wall -o felix.o BabyFelix_SoundDriver.asm
rgblink -o felix.gb felix.o
python tools/cmp_banked.py felix.gb "Baby Felix - Halloween (E) (M6) [C][!].gbc" 19:4000-7FFF
```

---

## 1. Game side

The game calls `SndUpdate` once per frame from VBlank through a far call in bank 0. The driver's RAM is in WRAM bank 0, so the WRAM bank doesn't matter.

## 2. Changes from Martian Alert

### 2.1 Command set

| Byte | Martian Alert / Rage Wars | Baby Felix |
|---|---|---|
| `$60–$82` | `GLIDE` … `VOL` | unchanged |
| `$83` / `$84` | `SLIDE_UP` / `SLIDE_DOWN` | **`PINGPONG` / `PINGPONG_OFF`** (handlers gone) |
| `$85–$88` | `PINGPONG`, `PINGPONG_OFF`, `GLISS_1`, `GLISS_2` | `GLISS_1/2/3`, `GLISS_OFF` |
| `$89` | `GLISS_3` | **`ARP_INLINE`** (new) |
| `$8A` | `GLISS_OFF` | `INSTR` … |

The slide code itself stays (it is the vibrato's), so only the two commands that started a plain slide are gone.

### 2.2 `ARP_INLINE`

`$89` followed by arpeggio bytes: the handler stores the address after the command byte as the arpeggio pointer (fields `$1D/$1E`), sets the position (`$1F`) to 0 and turns the arpeggio on, as `ARP n` does with a table entry. Then it skips the bytes up to and including the first `$FF` (hold) or `$6A` (loop). So the bytes are in the same format as an arpeggio-table entry, written in place:

```
ARP_INLINE $0C, $0C, $10, $10, $15, $15, ARP_LOOP
ARP_INLINE $0C, $00, ARP_HOLD
```

The data uses it 39 times, next to 43 `ARP n`. **Converters:** the command has a variable length; read to the terminator.

### 2.3 Signed vibrato speed

As in Radikal Bikers (`RadikalBikers_SoundDriver.md` §2.3), a vibrato speed with bit 7 set is negated (the first half-cycle goes the other way). No `VIBRATO` in the data has a negative speed.

### 2.4 Other driver changes

- **`INSTR`** also clears the release flag (bit 1), so an instrument switch stops a `RELEASE`.
- **`REST`** on the pulse pages writes NRx2 = **`$08`** instead of 0 (volume 0 with an upward envelope, which keeps the channel's DAC on).
- **`ResetMusicPage`** also clears the `HWENV` fields `$2A–$2D`, so a new song doesn't inherit the old envelope. (It drops Rage Wars' second clear of field `$37`, which was redundant.)
- **`SndInit`** writes NR52 = `$80` (was `$FF`). **`StopAll`** zeroes NR12, NR22, NR42, NR32 (the last two twice) and then writes `$80` to NR14/24/34/44 (was 0).
- **`SongFadeIn`/`SongFadeOut`** no longer reload the music wave.
- **`PlaySfx`:** A ≥ 39 → return; otherwise it jumps to the game's glue (§4), which goes on to the priority test (ids 1–5 don't cut 6+, as Martian Alert).

In Rage Wars, Martian Alert and Radikal Bikers an unreferenced `jp PlaySfxStart` sits just before `SndResume`. In Baby Felix that spot holds the whole glue, which ends in a `jp` back into `PlaySfx`; the stray `jp` in the earlier builds is probably the tail of a removed glue.

## 3. Songs

| A | Routine | Instrument table | Length |
|---|---|---|---|
| 0 | `$6B78` | `$6EE0` (set by the song) | loops |
| 1 | `$4CCE` | `$6EE0` | loops |
| 2 | `$5045` | `$6EE0` | loops |
| 3 | `$50E1` | `$6EE0` | loops |
| 4 | `$5235` | `$6EE0` | loops |
| 5 | `$5305` | `$5538` (9) | loops |
| 6 | `$558F` | `$6EE0` | loops |
| 7 | `$5935` | `$5E6E` (9) | loops |
| 8 | `$5EC7` | `$63DC` (8) | loops |
| 9 | `$642F` | default `$6EE0` | loops |
| 10 | `$6738` | `$6EE0` | loops |

The asm numbers songs 1–11 in table order, so song 1 (A = 0) is the routine placed after all the others. All songs loop. Panning is heard (NR51 from the pan bits), but the data has only one `PAN_R` and one `PAN_L`.

## 4. Sound effects

`PlaySfx` (A = 1–38) goes through the glue at `$40B6`:

| Id | Glue |
|---|---|
| 26 | noise routine `$752F` (noise sequence, hold 43 ticks), then the stream as usual |
| 27 | noise routine `$756A` (hold 53 ticks), then the stream |
| 38 | noise routine `$738E` only (hold 4 ticks); its table entry is a placeholder |
| others | straight to the priority test and the stream |

SFX 1–5 are the drums' CH3 hits, using the wave right after the song table (`$6FA1`, the same wave as Martian Alert's). Lengths (ticks): 2, 2, 3, 3, 3, 6, 9, 9, 25, 51, 24, 24, 20, 58, 57, 32, 13, 9, 32, 67, 12, 15, 25, 13, 55, 24, 24, 25, 35, 15, 20, 40, 18, 30, 30, 40, 13, 6.

## 5. Data notes

- **Unreferenced:** `SetVolEnvBC` and the old noise auto-pan fragment (as before); two blocks in the drum-pattern format (`$502C`, `$6725`); six unreached 4-byte order-list ends (`dw 0, loop`, `$5067`–`$5263`); unused waves and noise-table bytes between `$7614` and `$7724`; zeros from `$7969` to the end of the bank. The 242 bytes before the period table are PC memory garbage (x86 code).
- **Not used by the data:** `VIB_OFF`, `STOP_ALL`, `PAN_C`, `DUTY_25`, `AUTOPAN`, `FADE`, `FADE_OFF`, `VOL`, `PINGPONG`, `PINGPONG_OFF`; no `WAVE_SEQ`.

## 6. Verification

`verify/v4trace.py` starts every song through `PlaySong` and every SFX through the `PlaySfx` API entry (so the glue and the noise-only SFX 38 are included): **49 tests, 66 938 ticks, 0 problems** (`verify/run_v4.log`).

## 7. Files

- `BabyFelix_SoundDriver.asm`;
- entry `felix` in `tools/v4cfg.py` (command set `FELIX_CMDS`, with the `arpinl` argument type in `v4data.py`) and `tools/v4games.py` (glue routines, `noise_sfx`; names carried from Martian Alert, `ref='martian'`).

Regenerate with `python tools/gen_v4.py felix <rom> BabyFelix_SoundDriver.asm`.
