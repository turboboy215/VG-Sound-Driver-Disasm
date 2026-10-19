# Kirby Tilt 'n' Tumble (GBC): sound driver

*Kirby Tilt 'n' Tumble* (`Kirby's Tilt 'n' Tumble (U) [C][!].gbc`, MBC7 with the tilt sensor, 1 MB, CGB only) uses a descendant of the *Super Mario Bros. Deluxe* driver (`SMBDeluxe_SoundDriver.md`). It has two music banks again, as in *Link's Awakening DX*, and two SFX banks. The variables are at `$DE00–$DEFF` in WRAM bank 7, with SMB DX's layout. The game also plays 3-bit PCM samples through the master volume, from a player in the home bank (§3).

All four banks and the home-bank PCM routines rebuild **byte-exact** from the sources in `Nint1\KTT`.

| Bank | Content |
|---|---|
| `$0E` | music driver, songs `$01–$3F` (18 songs) |
| `$0F` | the same driver, songs `$40–$7F` (21 songs) |
| `$11` | SFX: four slots, effects `$01–$7F`; the shared priority table; the per-frame PCM / hurry hook |
| `$14` | SFX: the same helper library, effects `$80–$97` |
| `$19`, `$1A` | PCM sample data (8 samples) |
| home | PCM player: timer handlers `$0353–$03BC`, tables and start routine `$0DAC–$0E60` |

```
KTT\build_check.sh   KTT\harness\build.sh   KTT\harness\verify.py
python KTT\gen_ktt.py <rom> KTT      (uses ..\SMBDX, ..\LADX and ..\tools; also writes pcm\*.wav)
```

**Order per frame** (home `$02DD`, and `$0A55` on another path): bank `$03:$4000` copies the game's mailboxes `$C106–$C10A` into the request bytes. Then, with WRAM bank 7 mapped, the updates run in this order: `$0E:$4006`, `$0F:$4006`, `$11:$4006`, `$14:$4006`. The game reads the playing bytes back into `$C10B–$C10F`. Only bank `$11`'s init is called (at boot). While a PCM sample plays, the sound driver isn't called at all.

| Mailbox | Request byte | |
|---|---|---|
| `$C10A` | `wSongRequest` `$DE68` | |
| `$C106` | `wSfx1Request` `$DE60` | ch1 |
| `$C107` | `wSfx2Request` `$DE70` | ch2 |
| `$C108` | `wSfx3Request` `$DE80` | ch3 (new; SMB DX had no ch3 slot) |
| `$C109` | `wSfx4Request` `$DE78` | ch4 |

---

## 1. Music (banks `$0E`, `$0F`)

1,127 of bank `$0E`'s 1,383 instructions align with SMB DX bank `$1D` (923 with LA bank `$1B`). Envelope tables, the two vibrato types, the drop of 32 per frame, the rest envelopes, the ch3 level handling and the panning code are SMB DX's. The note table, the vibrato table and SMB DX's nine length tables are identical. Bank `$0F` is the same code shifted by `$36` bytes from `Music_Length` on. 1,340 of its 1,350 traced instructions align with bank `$0E`. The ones that don't are the hurry-table selection and the bank checks.

### 1.1 Two banks

- Both banks read every request. Bank `$0E` takes `$01–$3F` and bank `$0F` takes `$40–$7F`. The bank that accepts the request sets `wMusicBank` (`$DECE`: 0 or 1), and `Music_Play` does nothing in the other bank. Both banks have a full 127-entry song table, and each one ignores the half that belongs to the other bank.
- Request `$80` replays `wPreviousSong`. Request `$FF` stops the music and moves the current song to `wPreviousSong`. A song that reaches `$0000` in a list stops the same way (no restart, `wSongPlaying` = 0). The game uses `$80` to bring a song back after a jingle.
- SMB DX's hurry-up resume, pause/restore of song `$2D` and song-range exceptions are gone.

### 1.2 Commands

| Byte | Macro | |
|---|---|---|
| `$9D` | `INSTR` / `INSTR_ENV` / `INSTR_WAVE` | as SMB DX: second byte non-zero = pointer to a per-frame envelope table |
| `$9E w` | `TEMPO` | back (SMB DX had removed it); its handler is LA's |
| `$9B n` / `$9C` | `REPEAT` / `REPEAT_END` | |
| `$97` / `$98` | `DROP_ON` / `_OFF` | −32 per frame |
| `$9A v` | `VOLUME` | NR50 = `v & $77` |
| `$99 v` | `REST_ENV` | ch1 / ch2 rest envelope, now at `$DE88` / `$DE89` (default `$11` at song start) |
| `$96 n` | `TRANSPOSE` | **new**: set this channel's transpose (`wChTranspose+ch`, ch1–ch3; 2 per semitone) |
| `$95 n` | `TRANSPOSE_ADD` | **new**: add to it |
| `$94 v` | `ENV_SET` | **new**: set the instrument's NRx2 byte (ch1/ch2, not when it is an envelope-table pointer) |
| `$93 v` | `ENV_ADD` | **new**: add to it, signed; an add that would wrap past `$00`/`$FF` is ignored |
| `$92 w` | `DRUMKIT` | **new**: drum kit for ch4 notes |

`Music_Note` adds the header transpose and the channel transpose. Both channel transposes and the drum kit are reset when a song starts. LA's `$9F` tail, LA's `$94–$96` / `$99`/`$9A` ch3 commands and SMB DX's `StopSfx4` are still in the bank, unreferenced.

### 1.3 Section lists

Between two patterns a list may hold `$FF96`, `$FF95`, `$FF94` or `$FF93` followed by an operand word. These are the transpose and envelope commands above; only the low byte of the operand is used. The source writes them as `LIST_TRANSPOSE n`, `LIST_TRANSPOSE_ADD n`, `LIST_ENV_SET v` and `LIST_ENV_ADD v`. Any other `$FFxx` ends the song.

Some bank `$0F` songs split their lists into fragments (17 of them): a `$FFFF` + address jumps forward into another list instead of looping back. The generator follows these jumps (`chained_lists`). This is the change in `tools\tanaka.py`: an optional `list_cmds` key. Without the key the parser behaves as before; SMB DX's sources regenerate unchanged.

### 1.4 Drum kits

A ch4 note byte is an offset into the current drum kit. The driver copies 5 bytes from that offset (NR42, unused, NR41, NR43, NR44), the same entry layout as LA's noise table. The default kit is the bank's `NoiseTable`: 25 drums of its own, 8 of them the same as SMB DX's. Most songs select their own kit with `$92` (`DrumKit_xxxx` in the song files). The music drum (`$FF`) and its two-step update are gone.

### 1.5 Hurry mode

`wHurryMode` (`$DED0`) is set and cleared by the game (and by SFX `$52`, §2.4). While it is set, some songs take their lengths from a 15-byte table stored right before their header (`SongXX_HurryLengths`):

- bank `$0E`: songs `$02`, `$06`, `$08`–`$0D`;
- bank `$0F`: songs `$41`, `$64`.

Other songs keep their table. SMB DX instead had three shared hurry tables in the driver.

### 1.6 Other changes

- One panning entry for every song: `Music_InitPanning` always reads the first entry of the 64-entry table, which is still there.
- `Sound_Stop` (`$4003`) mutes only the channels no SFX is using. It checks the ch3 slot too.
- `Music_Update` no longer calls the music drum, and SMB DX's ch1-effect-`$6E` exception is gone. NR31 is still cleared every frame, and `$4FFF` is still an empty hook.

### 1.7 Song data

| | Bank `$0E` | Bank `$0F` |
|---|---|---|
| distinct songs | `$01–$12` | `$40–$4C`, `$50`, `$51`, `$55`, `$64–$67` |
| filler entries | `$13` → song `$01`; `$14–$3F` (and the unreachable half) → song `$08` | `$4D–$4F`, `$52–$54`, `$56–$63`, `$68–$7F` (and the unreachable half) → song `$4D` |
| length tables | one per song, right after its header | mostly the driver's tables (`$9E` switches too) |

Unreferenced material, all kept in the source as such:

- two complete songs in bank `$0F` with no song-table entry: `Unused_51F8_Header` (3 channels) and `Unused_5278_Header` (4 channels, own length table);
- SMB DX's silent list and release envelopes in both driver areas, and 11 length tables there: SMB DX's nine, one before them (SMB DX's source reads it as noise-table entries) and one after;
- unused waves (3 in bank `$0E`, 4 in `$0F`); in both banks the wave area ends in a 208-byte block of leftover bytes;
- extra length tables in front of some headers, the pointer `$56E7` (to song `$64`'s hurry table) between song `$64`'s header and its length table, and a few unreferenced patterns.

---

## 2. Sound effects (banks `$11`, `$14`)

The machinery is LA's: effects are code, and each slot has an init and a per-frame jump table. The shared helpers are those of LA and SMB DX: `GetPointer`, `Sfx_DecTimer/IncStep`, `SetRegs_Ch1–4`, private counters, `LoadPitch`/`AddPitch`, and SMB DX's `SetRegsSkip0_Ch1–4`. The slot layout and the priority rule are new.

### 2.1 Slots

| Slot | Request | Bank `$11` | Bank `$14` | Channel |
|---|---|---|---|---|
| 1 | `$DE60` | `$01–$7F` (100 effects) | `$80–$97` (18) | ch1 |
| 2 | `$DE70` | `$01–$3F` (35) | `$80–$8F` (10) | ch2 |
| 3 | `$DE80` | `$01–$08` (6) | `$80–$87` (6) | ch3 (wave) |
| 4 | `$DE78` | `$01–$28` (36) | `$80–$90` (16) | ch4 |

Bank `$11` handles requests below `$80` and bank `$14` the rest (bank `$14` indexes its tables with `request & $7F`). Bank `$14`'s update clears the four requests. Unused numbers point to a stub that refuses the request. Slot 1 `$53`, slot 2 `$06`, slot 3 `$03` and slot 4 `$05` each just stop their slot's effect. In slot 2, one routine serves fourteen requests (`$10–$1E` except `$17`) and checks the request number while it plays.

### 2.2 Priority

`SfxPriorityTable` gives every effect a priority byte. A request starts if its priority is at least the playing effect's, and is dropped otherwise. Stopping clears the slot's priority. The table is one 303-byte block covering both banks: slot 1 `$01–$97`, slot 2 `$01–$8F`, slot 3 `$01–$87`, slot 4 `$01–$90`. Both banks contain it byte for byte. Bank `$11` reads the entries below `$80`, bank `$14` the rest. SMB DX had no table; its per-slot code listed the effects allowed through.

### 2.3 New helpers

- **Software sweep** for ch1 and ch2 (`Sfx1_SweepStart/Sweep`, `Sfx2_…`), used by `Sfx1_StartSweep` / `Sfx2_StartSweep`. Byte 0 of the register image is an NR10-style byte: bits 5–4 are the period in frames, bit 3 is the direction, bits 2–0 the shift. Every period, the code adds `($7FF − period) >> shift` to the period, or subtracts it when bit 3 is set. The step is a fraction of 2048 − period, i.e. of the wave length, so the glide is even in pitch like the hardware sweep's but works from the other side. The hardware sweep is switched off (NR10 = 8). An unreferenced ch3 version follows.
- **`SetRegsPartial_Ch1/Ch4`**: skip zero bytes in some registers only (NR10–NR12; NR41, NR42, NR44).
- Effects call a slot's update (`Sfx2_Update` etc.) after writing a new request, to chain into another effect at once. They also jump to `SfxN_Refuse` / `SfxN_Continue`.
- Unreferenced: `Sfx1_StartVar`, LA's `WritePeriod` for ch1/ch2/ch4, `SetRegsSkip0_Ch3`, a ch2 `SetRegsPartial`, `Sfx4_DecCounter`, and a copy of the music note table at `$11:$44B8` / `$14:$4204`.

Bank `$14` holds a relocated copy of the whole helper library (600 of 628 traced instructions align). Helpers that no `$14` effect uses are dead code there.

### 2.4 Bank `$11`'s update: PCM end and the hurry jingle

Before the slots run:

- **`wPcmDone`** (`$DE8B`, set by the PCM player when a sample ends, and by the game on a few other paths): request slot-1 `$53`, which stops all four effect slots. Stopping the ch3 effect also makes the music reload its wave. If a hurry jingle was pending (`wHurryJingle` = 1), the code sets `wHurryMode` and requests the playing song again. `wHurryJingle` is then cleared.
- Otherwise, while `wHurryJingle` = 1, effect `$52` is requested every frame. `$52` is the hurry-up jingle on all four channels: it requests slot-2 `$09`, slot-3 `$04` and slot-4 `$08`, and sets `wHurryMode` and `wHurryJingle` = 2. After 24 steps it restarts the playing song, which now plays with its hurry length table.

Other effects start songs or stop the music themselves (e.g. `$26` requests song `$FF` together with three more effects).

---

## 3. PCM samples (home bank)

The game plays **3-bit samples through the master volume**. Ch3 outputs a constant level: wave RAM is all `$FF`, NR32 = 100 % and the period is `$7DB`. A timer interrupt writes each sample value to both halves of NR50. Each byte holds two samples, bits 6–4 first, then bits 2–0. Bits 7 and 3 are never set in the data.

```
PlayPcm ($0DDC), a = 3 × sample:
  PcmStartTable / PcmEndTable ($0DAC / $0DC4): address, bank per sample
  build an HRAM trampoline at $FFE5:  ld hl, <start>   jp PcmIrq_High
  mute ch1 / ch2 / ch4 (not for sample 0), wave RAM = $FF, ch3 on
  hPcmState = 1, TAC = 7, TMA = $FC (samples 0–5) or $FB (samples 6, 7)
timer vector $0050: push af / push hl / jp $FFE5
  PcmIrq_High ($0356): NR50 = bits 6-4 (both sides), retarget the jump to PcmIrq_Low
  PcmIrq_Low  ($0370): NR50 = bits 2-0, next byte, store hl in the trampoline's `ld hl`,
                       retarget to PcmIrq_High; past the end: hPcmState = 2, timer off,
                       wPcmDone = 1, NR50 = $77
```

The trampoline holds the play position, so the handlers don't need RAM for it. They map the sample's bank for the read and restore the game's bank (`hRomBank`) before `reti`. The main loop enables the timer interrupt while `hPcmState` = 1 and skips the sound driver until the sample has ended. Then it resets `hPcmState`, and on the next update bank `$11` sees `wPcmDone` (§2.4).

**Rate.** TAC = 7 selects the 16384 Hz timer clock, and the game runs in CGB double speed (switched on at boot), so the timer counts at 32768 Hz. TMA `$FC` → **8192 Hz**, TMA `$FB` → **6553.6 Hz**.

| # | Request `a` | Data | Rate | Length | Called from |
|---|---|---|---|---|---|
| 0 | `$00` | `$19:$4000–$58C2` | 8192 Hz | 1.55 s | `$10:$5EA5` |
| 1 | `$03` | `$19:$58C2–$7395` | 8192 Hz | 1.68 s | `$00:$1449`, `$17:$638A` |
| 2 | `$06` | `$19:$7395–$7EAD` | 8192 Hz | 0.69 s | `$01:$512A`, `$01:$71DC` |
| 3 | `$09` | `$1A:$4060–$4A16` | 8192 Hz | 0.61 s | `$00:$12A3`, `$01:$42F0` |
| 4 | `$0C` | `$1A:$4A16–$5B2E` | 8192 Hz | 1.07 s | `$00:$1454`, `$01:$42B7` |
| 5 | `$0F` | `$1A:$5B2E–$6239` | 8192 Hz | 0.44 s | `$01:$5C54`, `$01:$5D24`, `$09:$58A1`, `$09:$6580`, `$09:$7735` |
| 6 | `$12` | `$1A:$6239–$650D` | 6553.6 Hz | 0.22 s | `$01:$6173`, `$06:$6908`, `$16:$73AF`, `$16:$742C` |
| 7 | `$15` | `$1A:$650D–$67F4` | 6553.6 Hz | 0.23 s | `$00:$129C`, `$03:$40D1` (end of a countdown) |

`$10:$6DB6` also calls the player, with the sample number from a table.

- The end test is "pointer > end" after the increment, so a sample also plays the byte at its end address, which is the first byte of the next sample.
- `$1A:$4000–$405F` holds other data (`$FF/$00` patterns), not samples.
- `gen_ktt.py` writes all eight samples to `KTT\pcm\ktt_pcmN_BB_AAAA.wav` (8-bit mono at the sample's rate, level *n* → `n × 255 / 7`). They haven't been identified by ear yet.

---

## 4. Verification

- **Byte-exact rebuild** of banks `$0E`, `$0F`, `$11`, `$14` and the home-bank PCM routines (`KTT_Home.asm`), linked over the original ROM.
- **Emulator harness** (PyBoy). The test ROM runs the four updates in the game's order, with WRAM mailboxes `$C000–$C004`; `$C005` forces hurry mode. Results are in `harness\result.txt`.

  | | Reads | Outside the parsed data |
  |---|---|---|
  | bank `$0E`, songs `$01–$3F` × 3,600 frames (pattern / list) | 116,760 / 5,766 | 0 |
  | bank `$0F`, songs `$40–$7F` | 112,643 / 2,802 | 0 |
  | the same in hurry mode (`$0E` / `$0F` pattern reads) | 124,133 / 113,870 | 0 |
  | bank `$11`: slots 1–4, all 238 requests | 167,150 | 0 |
  | bank `$14`: slots 1–4, all 65 requests | 12,968 | 0 |

- **Not verified:** song and effect identities, what the samples say, and the PCM timing on hardware.
