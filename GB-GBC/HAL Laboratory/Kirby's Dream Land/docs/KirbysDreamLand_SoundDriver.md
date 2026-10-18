# Kirby's Dream Land (GB): sound driver

This is HAL Laboratory's sound driver in *Kirby's Dream Land* (`Kirby's Dream Land (UE) [!].gb`, MBC1, 256 KB). Everything lives in bank 5, from `$4C4A` to `$7ABF`. Game code fills the bank before `$4C4A`, and `$FF` fill follows `$7AC0`. The region rebuilds **byte-exact** with RGBDS 0.9.1 (`-Wall` clean) from the sources in `HAL\KDL`.

This is the reference version of the "KDL family" format: *Adventures of Lolo* and *Kirby's Dream Land 2* use the same command set (`AdventuresOfLolo_SoundDriver.md`, `KirbysDreamLand2_SoundDriver.md`). *Ghostbusters II* uses a different branch of the engine (`GhostbustersII_SoundDriver.md`). The family overview is in `HAL_SoundEngine_Family.md`.

| Range | Content | File |
|---|---|---|
| `$4C4A–$54DE` | driver code; default register image, period, noise and stack tables; 3 waves | `KDL_Driver.inc` |
| `$54DF–$78D2` | 19 song headers, 36 SFX headers, streams, envelopes | `KDL_Data.inc` |
| `$78D3–$7ABF` | 54 instruments, 12 length sets, song/SFX tables, SFX masks and priorities, initial wave, padding | `KDL_Data.inc` |

```
python tools\gen_kdl.py <rom> KDL           # regenerate the sources
sh KDL\build_check.sh <rom>                  # assemble, link over the ROM, compare
python tools\verify_kdl.py KDL [song frames] [sfx frames]   # harness ROM + PyBoy read check
```

---

## 1. API

| Address | Routine | |
|---|---|---|
| `$4C4A` | `Sound_Init` | called once at boot (`$017C`) |
| `$4C9E` | `Sound_PlaySfx` | a = SFX 0–35, `$FF` = stop all SFX |
| `$4DC5` | `Sound_PlaySong` | a = song 0–18, `$FF` = stop |
| `$4E0B` | `Sound_Update` | once per tick, from the VBlank handler (`$1D8E`) and the timer handler (`$1E58`) |

The game reaches them through bank-0 wrappers that map bank 5: `$1E96` (SFX; also stores the number in `$D02E`) and `$1EB4` (song). The song wrapper skips a request for the song already playing (`$D02D`), except for song 5 or while `$D02E` = `$21`.

**RAM** (`$DE00–$DF80`). All per-track variables are 8-byte arrays indexed by track. Tracks 0–3 are SFX and tracks 4–7 are music.

| | | |
|---|---|---|
| `wSoundSync` `$DE00` | set by command `$E1` | `wTrkWait` `$DE52` | main-stream frame counter (0 = track off) |
| `wSfxAttenuation` / `wMusicAttenuation` `$DE01/02` | master volume (`$FF` = full) | `wTrkPtrLo/Hi` `$DE5A/62` | main-stream pointer |
| `wSfxChannels` `$DE03` | channels owned by SFX | `wTrkEnvWait`, `wTrkEnvPtrLo/Hi` `$DE6A/72/7A` | envelope stream |
| `wHwRegs` `$DE06` | shadow of NR10–NR44 (20 bytes) | `wTrkRelease` `$DE82` | release countdown (`$FF` = none) |
| `wSfxRegs` / `wMusicRegs` `$DE1A/2E` | two register images | `wTrkBaseNote` `$DE8A` | base note (start `$24` = A4) |
| `wTrkPan` `$DE42` | NR51 bits per track | `wTrkGate`, `wTrkVolume`, `wTrkInstrument` | `$DE92/9A/A2` |
| `wTrkHwOffset` `$DE4A` | register offset 0/5/10/15 | `wTrkLengthSet`, `wTrkTuning`, `wTrkStack`, `wTrkEnvStack` | `$DEAA/B2/BA/C2` |
| `wSfxMask`, `wSfxPriority` `$DECA/CE` | per SFX track | `wCurWave` `$DED2` | loaded CH3 wave |
| `wSoundStacks` `$DF00` | call/loop stacks | `wRegImage` `$DF80` | low byte of the image in use |

`$DED3` and `$DED4` are written by the init (`$13`, `$24`) and never read.

---

## 2. Data

### Headers

```
SongNN:  db n                ; number of tracks
         track Pointer, CHx  ; dw pointer, db channel  (CH1 $00, CH2 $04, CH4 $0C, CH3 $10)
```

Songs fill tracks 7, 6, 5, 4 in header order. SFX take free tracks from 3 downward. The channel byte / 4 is also the bit of that channel in the SFX masks (CH1 bit 0, CH2 bit 1, CH4 bit 3, CH3 bit 4).

### Main stream

| Byte | Macro | Meaning |
|---|---|---|
| `LLLNNNNN`, LLL 0–5 | `note n, L` | n = −15…15 from the base note; L = entry of the current length set |
| `$C0+n`, frames | `note_x n, f` | explicit length |
| `LLL10000` / `$D0` | `rest L` / `rest_x f` | |
| CH4 tracks | `drum n, L`, `drum_x`, `drest` | n 0–14 = `NoiseTable` entry; +16 = keep the previous NR43; `$0F` = rest |
| `$E1 xx` | `sync` | `wSoundSync` = xx (unused in KDL) |
| `$E2 llhh` | `frequency` | set the period directly, restart the envelope (unused) |
| `$E3 xx` | `detune` | period −= xx (signed) |
| `$F0 v` / `$F1 s` | `volume` / `volume_add` | channel volume (high nibble of `wTrkVolume`), clamped 0–15 |
| `$F2 n` | `length_set` | length set n (6 entries) |
| `$F3 f` | `hold` | wait f frames without a new note |
| `$F4 g` | `gate` | release after length × g / 256 frames (0 = never) |
| `$F5 n` | `base_note` | |
| `$F6 i` | `instrument i[, STATIC]` | bit 7: run the attack envelope once now instead of at every note |
| `$F7 n` | `tuning` | `TuningTable` entry (only entry 0 exists; unused) |
| `$F8 ptr` / `$FA ptr` / `$FB` | `snd_jump` / `snd_call` / `snd_ret` | |
| `$FC n` / `$FD` | `snd_loop` / `snd_endloop` | nestable, on the track's stack |
| `$FE p` | `pan` | bit 0 left, bit 1 right (`PAN_L/R/LR`) |
| `$FF` | `snd_end` | track off, volume 0 |

`$E0`, `$E4–$EF` and `$F9` are not handled. The flow-control code ignores them, so the same byte is read again forever.

A note sets the wait to the length and the release countdown to `$FF` or length × gate / 256 (the multiply uses the game's floor(i²/2) table at `$DC00`), then restarts the instrument's attack envelope. A rest sets an active release countdown to 1, so the release starts on the next frame. The note index is base note + offset. `PeriodTable` (72 big-endian periods, C2–B7) is entered through `TuningTable` 6 bytes early, so index 3 = C2 and the default base `$24` = A4.

### Envelope (instrument) stream

Each instrument is two pointers: an attack envelope started at every note, and a release envelope started when the release countdown expires.

| Byte | Macro | |
|---|---|---|
| `000wwwww` | `env_wait w` | |
| `001Wssss` | `env_pitch s[, WAIT]` | period += s (signed); W = then wait 1 frame |
| `010Wvvvv` | `env_vol v[, WAIT]` | envelope volume (low nibble of `wTrkVolume`) |
| `011Wssss` | `env_vol_add s[, WAIT]` | clamped 0–15 |
| `100Wxxxx` | `env_timbre x[, WAIT]` | duty (CH1/2/4, NRx1 bits 6–7) or wave number (CH3: reloads wave RAM if it changed) |
| `$F0 xx` | `env_reg0` | register 0 of the channel (NR10 sweep, NR30) |
| `$F8 $FA $FB $FC $FD` | `env_jump/call/ret/loop/endloop` | own stack |
| `$FF` | `env_end` | |

Output volume = envelope volume − (15 − channel volume) − (15 − master), clamped at 0. It goes to the NRx2 high nibble, or through `Ch3VolumeTable` (16 entries) to NR32.

### Tables

| | |
|---|---|
| `InstrumentTable` `$78D3` | 54 × (attack, release). 23 are not used by any song or SFX: 1, 31–45, 47–53 |
| `LengthSets` `$79AB` | 12 × 6 frame counts (sets 6–11 repeat sets 0–5) |
| `SongTable` / `SfxTable` | 19 / 36 pointers |
| `SfxChannelMasks` / `SfxPriorities` | 36 bytes each |
| `InitialWave` `$7AA9` | loaded by `Sound_Init`; `Wave0–2` (`$54AF`) are selected by `env_timbre` |

---

## 3. Engine

**Update**:
1. For tracks 7 to 0 that are active, it selects the music image (tracks 4–7) or the SFX image, then runs the main stream, the release check and the envelope stream.
2. SFX tracks that have ended free their channels (priority `$FF`, mask 0), and `wSfxChannels` is recomputed.
3. For each channel, the SFX image is written if an SFX owns the channel, otherwise the music image. Only bytes that differ from `wHwRegs` are written. On CH1, CH2 and CH4 a changed NRx2 retriggers the channel (NRx4 bit 7); CH3 is retriggered when a new wave is loaded.
4. NR51 is the OR of the four pan bytes, each taken from the SFX or the music set.

Music keeps running underneath an SFX and takes the channel back when it ends.

**SFX priority.** A new SFX that shares a channel with a playing SFX is refused when its priority number is higher than the playing one's. Otherwise the old SFX track is stopped. Lower numbers are more important; free tracks hold `$FF`.

**Init.** NR52 = `$80`, NR50 = `$77`, NR51 = `$FF`. The shadow registers are set to `$AA` (all invalid), the initial wave is loaded, music and SFX are stopped, the registers are written, and the 4 channels are retriggered.

---

## 4. Verification

- **Byte-exact rebuild** of `$4C4A–$7ABF` (`build_check.sh`).
- **Emulator harness.** `verify_kdl.py` builds a test ROM: the rebuilt ROM with the interrupt vectors replaced by `reti` and the game's init at `$0150` replaced by a loop that calls `Sound_Update` once per frame. A WRAM byte at `$C000` requests a song or SFX. The `$DC00` multiply table is copied in from a computed `floor(i²/2)` table. PyBoy hooks every `ld a,[de]` in the driver (39 sites: headers, main and envelope streams, flow control, instrument table) and checks each ROM address read against the parse.

  | Run (12,000 frames per song, 3,600 per SFX) | |
  |---|---|
  | Addresses read | 9,065 |
  | Outside the parse | **0** |
  | Parsed header/stream/envelope bytes read | 8,947 of 9,201 |

  The 254 unread bytes are the envelopes of the 23 unused instruments, plus a few envelope branches that never run.
- **Unreachable bytes**, kept as data: `$6B6D–$6B6E` (`$F0 $DE` after a `snd_ret`), `$6DB3` (`snd_end` after a `snd_jump`), and zero padding at `$7AB9–$7ABF`.
- **Not verified:** song and SFX titles, and anything on hardware.

## Files (`HAL\KDL`, generator in `HAL\tools`)

| File | Content |
|---|---|
| `KDL_Sound.asm` | the section; includes the files below |
| `KDL_Driver.inc` | code `$4C4A–$54DE`, labelled and commented, with the driver tables |
| `KDL_Data.inc` | headers, streams, envelopes and tables `$54DF–$7ABF` |
| `KDL_Macros.inc`, `KDL_RAM.inc` | data macros (shared with Lolo/KDL2); RAM and hardware symbols |
| `build_check.sh` | rebuild and compare |
| `tools\gen_kdl.py`, `tools\verify_kdl.py` | generator, harness check (use `sm83.py`, `asmgen.py`, `halsnd.py`, `halcommon.py`, `harness.py`, `verify_common.py`) |
