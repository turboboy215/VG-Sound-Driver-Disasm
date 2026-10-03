# C-lab Game Boy Sound Engine

Documentation for the sound driver used by C-lab in **Rampart** (GB, 1992, the only release outside Japan) and **Keitai Keiba 8 Special** (J). The engine is the same in both games, with a small number of changes in the later version. Everything described here comes from the code. The behaviour marked *verified* was also checked by running the game in an emulator with breakpoints set.

Companion files:

| File | Contents |
|---|---|
| `rampart_sound.asm` | Labelled disassembly of the Rampart engine, tables, SFX and music data. Rebuilds the whole ROM byte-for-byte. |
| `keiba_sound.asm` | The same for Keitai Keiba 8 Special (abbreviated **KK8S** below). |
| `clab_sound.inc` | Shared include: hardware registers, RAM layout, note names, one macro per byte-code. |
| `build.bat` / `Makefile` | Rebuild both ROMs with RGBDS 0.9.x and compare them with the originals in the parent folder. |

Everything outside the sound engine is `INCBIN`'d from the original ROMs, so the ROMs must sit in the parent folder under their usual names (`Rampart (U) [M][!].gb`, `Keitai Keiba 8 Special (J).gb`).

---

## 1. Where things are

| | Rampart (U) | KK8S (J) |
|---|---|---|
| Engine code | bank 0, `$2EBE-$34BF` | bank 0, `$1D8C-$2348` |
| Tables | bank 0, `$34C0-$35E3` | bank 0, `$1F84-$1F96` (masks and register table, in the middle of the code), `$2354-$247A` |
| SFX data | bank 0, `$362C-$379C` | bank 0, `$247B-$2502` |
| Music data | **bank 3**, `$6D10-$7B12` | bank 0, `$2503-$3C5E` |
| Work RAM (`SND_RAM`) | `$CF00-$CFD1` | `$C500-$C5D1` |
| Songs in table | 15 (`$00-$0E`) | 8 (`$00-$07`), plus 1 song that is not in the table |
| Sound effects | 24 (ids `$03-$48`) | 12 (ids `$03-$24`) |
| Update call | VBlank handler (`call z` at `$0382`): maps bank 3, calls `Sound_Update` unless `[$C205] != 0` | VBlank handler (`call z` at `$0293`): calls `Sound_Update` unless `[hFF9C] != 0` |

In Rampart, the music data is in ROM bank 3, which the VBlank handler maps before calling `Sound_Update`. `Sound_PlaySong` also maps bank 3 while it reads the song header. The engine code, all the pointer tables and the sound-effect data are in bank 0. Rampart finds out which bank is currently mapped by reading the bank-number byte that each of its ROMX banks stores at `$4000`, then saves it in `wCurROMBank` (`$C417`).

## 2. Public interface

| Routine | Rampart | KK8S | Use |
|---|---|---|---|
| `Sound_Init` | `$2EE3` | `$1D8C` | Full reset. Called once at boot. |
| `Sound_Update` | `$3009` | `$1E77` | Once per frame from VBlank. |
| `Sound_PlaySong` | `$2EBE` | `$1DEE` | `a` = song number × 2. Resets the engine (this also cuts any SFX), then starts the song. In Rampart the call does nothing if the player turned music off in the options (`wMusicOff`, `$C401`). |
| SFX request | write `$CF02` | write `$C502` | `wSndSFXRequest` = SFX id (a multiple of 3). The engine starts the effect on the next frame. |
| `Sound_Pause` | `$2F3E` | – | Rampart pause screen. Halts the music, plays SFX `$09`, and sets NR51 = `$11` so only ch1 is heard. |
| `Sound_Resume` | `$2FE8` | `$1E6F` | Rampart: restores NR51 and restarts the music where it stopped. KK8S: only the tail end of `Sound_InitSong`. |
| `Sound_StopSFXPulse1` | – | `$1E01` | KK8S only. Hands ch1 back from an SFX. Called once, from bank 7. |
| `Sound_StopSFXNoise` | – | `$1E18` | KK8S only. Not used (and buggy, see §8). |
| `Sound_MuteAll` | `$2FF6` | – | Not used. |
| `Sound_ResetAndResume` | `$2FAB` | `$1E32` | Not used. |

Rampart's game code also polls `wSndSFXPriority` (`$CF13`) to wait until an effect has finished, in the routine at `$2E5D`, before it turns the LCD off.

## 3. Architecture

### Tracks and channels

The engine runs **8 tracks**:

| Track | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|---|
| Role | music | music | music | music | SFX | SFX | SFX | SFX |
| Hardware | ch1 pulse | ch2 pulse | ch3 wave | ch4 noise | ch1 | ch2 | ch3 | ch4 |

Most per-track state is stored in arrays of 8 bytes (see §4). Masks name a channel with the same bit in both nibbles: `$11` = ch1, `$22` = ch2, `$44` = ch3, `$88` = ch4. The low nibble is tested against music state and the high nibble against SFX state.

Every track has a 4-entry pointer stack in `wSndTrackStack[track*4 + depth]`. The entry at the current depth is the read pointer. The entries below it hold return addresses for `snd_call`, or the loop start for `loop`.

### Frame update (`Sound_Update`)

1. If `wSndStatus` is 0, the engine is idle and nothing happens.
2. `Sound_UpdateSFX` runs **once per frame**, so sound effects are not affected by the tempo:
   * If `wSndSFXRequest` ≠ 0 **and** the id is ≥ `wSndSFXPriority` (the id of the effect already playing), the new effect starts. Higher ids therefore have priority, and requesting the same id again restarts it. The channel is marked in `wSndSFXActiveMask`, and the effect's pointer becomes the read pointer of SFX track 4+ch.
   * Each active SFX track counts down its duration, and reads events when the countdown runs out. When it reaches `sfx_end` (`$1A`), its channel is silenced and handed back to the music. Once no effect is left, `wSndSFXPriority` = 0.
3. If bit 0 of `wSndStatus` is set (music running), the tempo decides how many music ticks to run this frame:

   ```
   sum   = tempo_accum + tempo          (9-bit)
   ticks = sum >> 6                     (0-4)
   tempo_accum = sum & $3F
   ```

   So tempo `$40` (64) = exactly 1 tick per frame (~59.7 ticks/s), `$80` = 2 ticks per frame, `$55` ≈ 1.33 ticks per frame.

### Music tick (`Sound_MusicTick`)

For each music track from 3 down to 0 that is not stopped or waiting:

* If a gate is active (`wSndGateTimer`), count it down. At 0 the note is cut with `Sound_NoteOff`.
* Count down `wSndDurationTimer`. When it reaches 0, parse events until a note, a rest or a halting command is found.
* If the channel currently belongs to an SFX (`wSndSFXOverride` ≠ 0), the track **keeps running in the background** but writes nothing to the hardware. When the effect ends, the music is heard again from its current position. The channel's registers are only rewritten when the next note starts.

After all four tracks have run, the song-level state is checked:

| Condition | Result |
|---|---|
| every track has executed `stop_track` | music finished (`wSndStatus &= $0E`) |
| every track is at `song_loop` or stopped | `Sound_LoadSongHeader`: the song starts again from its header. Stopped tracks stay silent. |
| every track is at `sync`, `song_loop` or stopped | all `sync` waits are released and the tick is processed again immediately |

### Pitch

```
index = note + transpose (tracks 0-2 only) + 12 * octave
freq  = FrequencyTable[index]          ; GB period value, Hz = 131072 / (2048 - freq)
```

`FrequencyTable[0]` is C2 (65.4 Hz). The table has 83 entries (C2 to A#8). Notes above A#8 (octave 6 with a note ≥ `$0B`, or anything in octave 7) read past the end of the table.

### Hardware writes when a note starts (`Sound_PlayNote`)

| Channel | Rampart | KK8S |
|---|---|---|
| ch1/ch2 | NRx3 = lo, NRx2 = `envelope`, (ch1: NR10 = `sweep`), NRx4 = hi \| `$80` | same |
| ch3 | NR30 = 0, NR33 = lo, NR31 = `timbre`×2, NR32 = 0, NR34 = hi, NR30 = `$80`, NR32 = `$20`, NR34 = hi \| `$80` | NR33 = lo, NR31 = `timbre`×2, NR32 = `$20`, NR34 = hi \| `$80` |
| ch4 | NR43 = note << 4, NR42 = `timbre`, NR41 = 1, NR44 = **`$C0`** (length counter on, the note stops after ~0.25 s) | same, but NR44 = **`$80`** (no length counter, the note keeps sounding) |

The wave channel always plays at 100 % volume (NR32 = `$20`), and the length counter is never enabled for ch1-ch3, so `timbre` on ch3 has no audible effect. The duty of ch1/ch2 (NRx1) is written directly by the `timbre` command, not when a note starts.

## 4. Work RAM

The offsets are identical in both games. Base: Rampart `$CF00`, KK8S `$C500`. `Sound_Init` clears `+$02-+$D1`.

| Offset | Size | Name | Meaning |
|---|---|---|---|
| `$00` | 2 | `wSndSongPtr` | current song header |
| `$02` | 1 | `wSndSFXRequest` | SFX to start (the game writes it) |
| `$03` | 1 | `wSndLastLength` | length of the last note (written but never read) |
| `$04` | 2 | – | unused |
| `$06` | 1 | `wSndSFXOverride` | temporary: the music track being processed belongs to an SFX |
| `$07` | 1 | `wSndIdleMask` | temporary: stopped \| loop-wait \| sync-wait |
| `$08` | 1 | `wSndChanX4` | hardware channel × 4 |
| `$09` | 1 | `wSndHWChan` | hardware channel (0-3) |
| `$0A` | 1 | `wSndTrack` | track (0-7) |
| `$0B` | 1 | `wSndStatus` | 0 = off, bit 0 = music running (`$FF` when playing, `$10` while paused) |
| `$0C` | 1 | `wSndSFXUsedMask` | channels touched by an SFX (maintained but never read) |
| `$0D` | 1 | `wSndStoppedMask` | tracks that executed `stop_track` |
| `$0E` | 1 | `wSndLoopWaitMask` | tracks waiting at `song_loop` |
| `$0F` | 1 | `wSndSyncWaitMask` | tracks waiting at `sync`. The SFX code borrows it as its "effect ended" flag. |
| `$10` | 1 | `wSndCurMask` | mask of the channel being processed |
| `$11` | 1 | `wSndSFXActiveMask` | channels owned by an SFX |
| `$12` | 1 | `wSndTicksThisFrame` | music ticks left to run this frame |
| `$13` | 1 | `wSndSFXPriority` | id of the effect playing (0 = none) |
| `$14` | 1 | `wSndTempo` | tempo |
| `$15` | 1 | `wSndTempoAccum` | tempo fraction |
| `$16` | 8 | `wSndStackDepth` | call/loop depth per track |
| `$1E` | 4 | `wSndLoopCounter` | loop counter per hardware channel |
| `$22` | 8 | `wSndGateInit` | gate time (`gate`) |
| `$2A` | 8 | `wSndGateTimer` | ticks until the note is cut |
| `$32` | 8 | `wSndNoteLength` | current note length |
| `$3A` | 8 | `wSndDurationTimer` | ticks until the next event |
| `$42` | 8 | `wSndOctave` | octave |
| `$4A` | 8 | `wSndTimbre` | ch3 wave length, ch4 noise envelope |
| `$52` | 8 | `wSndSweep` | NR10 value (only `+0` and `+4` are read) |
| `$5A` | 8 | – | cleared, never used |
| `$62` | 8 | `wSndEnvelope` | NRx2 value (music tracks start at `$FF`) |
| `$6A` | 3 | `wSndTranspose` | transpose for hardware ch1-ch3 |
| `$6D` | 64 | `wSndTrackStack` | 8 tracks × 4 pointers |
| `$AD` | 4 | `wSndRegNRx2` | low bytes `$12 $17 $1C $21` |
| `$B1` | 4 | `wSndRegNRx3` | low bytes `$13 $18 $1D $22` |
| `$B5` | 4 | `wSndRegNRx4` | low bytes `$14 $19 $1E $23` |
| `$BB` | 1 | `wSndSavedNR51` | NR51 saved by `Sound_Pause` (Rampart only) |

## 5. Data format

### Song table and header

`SongTable` holds one `dw` per song and is indexed with `a` = song × 2. A song header is four `dw` pointers, one track each for ch1-ch4:

```
Song01:: song_header Song01_Ch1, Song01_Ch2, Song01_Ch3, Song01_Ch4
```

The track data usually follows the header directly. Every song ends with an extra `$1C` byte that the engine never reads.

### SFX table

`SFXTable` is indexed **directly by the id** (`SFXTable - 3 + id`). Ids are therefore 3, 6, 9, …, and each entry is 3 bytes:

```
db hardware_channel * 2     ; 0 = ch1, 6 = ch4 (both games only use ch1 and ch4)
dw data
```

An effect is a normal track and ends with `sfx_end` (`$1A`). For effects, the sweep, envelope and timer defaults are reset only for **track 4**, and only when the effect is not a noise effect.

### Byte codes

| Byte | Meaning |
|---|---|
| `$00-$11` | **Note.** Waits for the current length. `$00` = C of the current octave … `$0B` = B, `$0C-$11` = C-F one octave higher (named `HC_ … HF_` in the include file). On ch4 the value is the noise clock shift. |
| `$12` | **Rest.** Waits for the current length and silences the channel. |
| `$13-$27` | Commands (see below) |
| `$28-$FF` | **Length.** Sets the length of the following notes to `byte - $28` ticks (0-215; 0 and 1 both last one tick). Parsing continues. |

### Commands

"Halts" means the track stops reading events until its next tick. All other commands continue straight on to the next byte. The parameter counts shown are the ones each engine actually consumes.

| Byte | Macro | Params (Rampart / KK8S) | Effect |
|---|---|---|---|
| `$13` | `octave n` | 1 / 1 | octave = n (per track) |
| `$14` | `octave_up` | 0 / 0 | octave + 1 |
| `$15` | `octave_down` | 0 / 0 | octave − 1 |
| `$16` | `snd_call addr` | 2 / 2 | Call a subroutine. The stack has 4 entries per track, so calls can nest 3 deep. The stack is indexed by the hardware channel, so this **only works in music**. |
| `$17` | `snd_ret` | 0 / 0 | Return from a subroutine. |
| `$18` | `loop n` | 1 / 1 | Start of a loop body that plays n times (0 = 256). There is **only one counter per channel**, so loops cannot be nested (a loop may contain a `snd_call`). Music only. |
| `$19` | `endloop` | 0 / 0 | End of the loop body. |
| `$1A` | `sync` / `sfx_end` | 0 / 0 | **Halts.** In music, the track waits until every track is at a `sync` (or at `song_loop`, or stopped), then all tracks continue in the same tick. In an SFX, it ends the effect. |
| `$1B` | `song_loop` | 0 / 0 | **Halts.** End of the track. When all tracks are at `song_loop` or stopped, the song restarts from the header. Only KK8S uses it. |
| `$1C` | `stop_track` | 0 / 0 | **Halts.** Silences the channel (NRx2 = 0) and stops the track for good. When every track is stopped, the music ends. |
| `$1D` | `timbre x` | 1 / 1 | ch1/ch2 music tracks: NR11/NR21 = x (duty/length), written immediately. All other tracks store x: ch3 wave length (NR31 = x×2), ch4 NR42 envelope. **SFX cannot set the duty**, because the value is only stored for them. |
| `$1E` | `sweep x` | 1 / **1 on ch1 only** | NR10 value used when a ch1 note starts. KK8S only accepts it on ch1; on the other channels the parameter byte is not skipped (see §8). |
| `$1F` | `envelope x` | 1 / 1 | NRx2 value used when a ch1/ch2 note starts. |
| `$20` | `tempo x` | 1 / 1 | Global tempo; also clears the fraction accumulator. |
| `$21` | `unused21 x` | 1 / 1 | No effect. Rampart also stores x at `[de]`, a left-over pointer (see §6). |
| `$22` | `unused22 [x]` | **1 / 0** | No effect. |
| `$23` | `gate x` | 1 / 1 | Cut each note x ticks after it starts (0 = off). Music only, and buggy (§8). |
| `$24` | `transpose x` | 1 / 1 | Signed transpose in semitones for hardware ch1-ch3 (indexed by hardware channel). |
| `$25` | `snd_jump addr` | 2 / 2 | Continue reading at addr. In Rampart it also reloads the wave RAM when used on ch3. |
| `$26` | `panning x` | 1 / 1 | NR51 = x (affects all channels at once). |
| `$27` | `unused27 x [,y]` | **2 / 1** | No effect. |

## 6. Differences between the two versions

Command set:

* **`$21`**: Rampart's handler skips its parameter but also executes `ld [de], a`, writing the parameter to whatever `de` still points at. After `Sound_ReadMusicTrack`, that is `$0000-$0003` (MBC1 RAM-enable, harmless). After a `timbre`, it is that track's `wSndTimbre` slot. The only use is in SFX `$15` (`timbre $80`, `unused21 $00`), where it overwrites the stored timbre of track 4 with 0, which changes nothing. KK8S removed the store.
* **`$22`**: 1 parameter in Rampart, none in KK8S. In Rampart the handler already does nothing, but the data still contains it: every music track header has `$22 $FF` right after `envelope`, 42 times in all. It looks like the leftover of a real command from an earlier version of the driver. KK8S never uses it.
* **`$27`**: 2 parameters in Rampart, 1 in KK8S. It has no effect in either game. Rampart uses it once (song `$09`), KK8S never.
* **`$1E` (sweep)**: Rampart stores the value for any track. Rampart's handler even loads `wSndCurMask` and then ignores it, which looks like a missing check. KK8S adds that check (bit 0 of the mask = ch1) but forgets to skip the parameter on other channels.
* **`$25` (jump)**: Rampart reloads the wave RAM (`Sound_LoadWave`) when a ch3 track jumps. KK8S does not.

So between the two games, `$21`, `$22` and `$27` are the commands whose handlers were cut down or had their parameter count changed. None of the three does anything useful in either game.

Other code changes in KK8S:

* No bank switching, no music on/off option, no `Sound_Pause`, `Sound_MuteAll`, `Sound_LoadWave` or `wSndSavedNR51`. The wave RAM is loaded inline in `Sound_Init` without switching the ch3 DAC off first.
* Two new routines: `Sound_StopSFXPulse1` and the unused `Sound_StopSFXNoise`.
* `Sound_PlaySong` is the former `Sound_StartSong` (no wrapper).
* Hardware writes use `ld [hl]`/`ld [bc]` with `h`/`b` = `$FF` instead of `ldh [c]`. `Sound_PlayNote` takes the NRx2 address from `SoundRegTable` in ROM instead of the RAM copy.
* The ch3 note trigger is simplified (no DAC off/on). The ch3 note-off writes NR32 = 0 and NR34 = `$80`; Rampart instead brackets the NR32 write with two NR52 writes that have no effect.
* The ch4 trigger is `$80` instead of `$C0`, so the noise length counter is no longer used.
* Starting an effect no longer clears `wSndSweep+4`.
* `Sound_Resume` sets NR51 = `$FF` instead of restoring a saved value.
* The default wave is a lower-amplitude triangle (`00 11 22 … 88 88 … 31 10` instead of `01 23 45 … 21 00`).
* Style: Rampart loops with `snd_jump` and uses `stop_track` for one-shot songs, and has 2 subroutine calls. KK8S loops with `song_loop`, makes heavy use of subroutines (57 calls) and transposes ch1-ch3 by +12.

## 7. Content

### Rampart

| Song | Tempo | End | Notes |
|---|---|---|---|
| `$00` | – | stop | silence |
| `$01` | `$80` | loop | |
| `$02` | `$80` | loop | ch3 uses `gate $28` |
| `$03` | `$80` | loop | **The ch2 header pointer points at the song's final `$1C`, so ch2 is silent.** The real ch2 part (`Song03_Ch2_Unused`, bank 3 `$70F8-$713E`) is never played. |
| `$04` | `$66` | loop | |
| `$05` | `$99` | loop | |
| `$06` | `$80` | loop/stop | ch2 uses `gate $06` |
| `$07`, `$08` | `$80` | loop | |
| `$09`, `$0A` | `$80` | stop | ch3 uses `gate $C8` |
| `$0B` | `$55` | loop | the only song with subroutines |
| `$0C` | `$80` | stop | **unused** |
| `$0D` | `$80` | loop | **unused** |
| `$0E` | `$C0` | stop | **unused** |

The options screen (bank 3, around `$44A0`) has a sound test: `$C900` selects music (0) or SFX (1), `$C901` is the song (0-`$0B`) and `$C902` is the SFX number (id = n × 3, 0-`$18`). Neither the game nor the sound test ever requests songs `$0C-$0E`. Every SFX can be reached from the sound test. SFX `$09` is the pause jingle. SFX on ch1: `$03 $06 $09 $15 $1B $1E $21 $2D $33 $3F $42 $45 $48`. SFX on ch4: `$0C $0F $12 $18 $24 $27 $2A $30 $36 $39 $3C`.

### Keitai Keiba 8 Special

| Song | Tempo | End |
|---|---|---|
| `$00` | – | silence |
| `$01` | `$88` | song_loop |
| `$02` | `$77` | song_loop |
| `$03` | `$81` | song_loop |
| `$04` | `$7C` | song_loop |
| `$05` | `$81` | song_loop |
| `$06` | `$82` | song_loop |
| `$07` | `$A2` | stop |
| `$08` | `$81` | song_loop. **Not in `SongTable`** (header at `$3976`). It is an alternate mix of song `$03` with identical data except the ch1/ch2 envelopes (`$68`/`$78` instead of `$57`/`$68`). |

SFX: 12 effects, ids `$03-$24`. `$0F` and `$15` are on ch4, the rest on ch1. No code writes ids `$09` or `$1B`, so they are probably unused.

## 8. Bugs and quirks

1. **The gate cut drops the rest of the tick** (both games, *verified in Rampart*). `Sound_MusicTick` calls `Sound_NoteOff` with `call z`, but `Sound_NoteOff` is also the tail of the rest command and ends with `pop hl / ret`. When a gate expires, it pops `Sound_MusicTick`'s return address and returns straight to `Sound_Update`. For that tick, the channel's own duration countdown, every lower-numbered channel and the song-end checks are all skipped, so those channels fall one tick behind. Rampart songs `$02`, `$06`, `$09` and `$0A` use `gate`. KK8S never does.
2. **An SFX ending on ch4 does not silence ch4** (both games, *verified*). The channel is silenced through `wSndRegNRx2[ChanX4 >> 1]`, i.e. index = channel × 2. That is correct for ch1 (index 0), but for ch4 it reads `wSndRegNRx3+2`, so the engine writes 0 to **NR33** (ch3 frequency low byte) instead of NR42. In Rampart, the noise length counter hides this. In KK8S the noise keeps sounding until its envelope fades out.
3. **KK8S `sweep` on ch2** (*verified*). The new ch1-only check returns without advancing past the parameter. Every KK8S ch2 track begins (after an optional `transpose`) with `timbre $80, envelope $xx, $1E $00`, so the `$00` is executed as note C (octave 0, length 0 → 1 tick): a one-tick blip at the start of each ch2 part, repeated on every loop. The disassembly writes these as `db $1E` followed by `note C_`.
4. **SFX cannot change the pulse duty.** `timbre` only writes NR11/NR21 for tracks 0/1, so an effect plays with whatever duty the music last set. The ch1 effects of both games set a timbre (`$00`, `$40`, `$80` or `$C0`), and none of those values has any effect.
5. **`transpose` on ch4 would corrupt memory.** Only 3 transpose bytes exist, so `wSndTranspose+3` is the low byte of track 0's first stack pointer. `snd_call`, `loop` and `transpose` are also indexed by hardware channel, so they would disturb the music if used in an SFX. Neither game does either of these.
6. **`KK8S Sound_StopSFXNoise`** writes its `$08` to NR41 instead of NR42. The routine is never called.
7. **The SFX reset is hard-wired to track 4.** Starting any non-noise effect resets the timers of track 4, even if the effect were on ch2 or ch3. Starting a noise effect resets nothing, so a noise effect that interrupts another one waits for the rest of the old note.
8. `stop_track` silences its channel even while an SFX owns it.
9. `Sound_Init` clears `$D0` bytes (`+$02-+$D1`), which is 22 bytes more than the variables use.

## 9. Routine address map

| Label | Rampart | KK8S |
|---|---|---|
| `Sound_PlaySong` | `$2EBE` | `$1DEE` |
| `Sound_Init` | `$2EE3` | `$1D8C` |
| `Sound_MusicFinished` | `$2F35` | `$1DE5` |
| `Sound_Pause` | `$2F3E` | – |
| `Sound_LoadWave` | `$2F5C` | – |
| `Sound_StartSong` | `$2F98` | (= `Sound_PlaySong`) |
| `Sound_StopSFXPulse1` | – | `$1E01` |
| `Sound_StopSFXNoise` | – | `$1E18` |
| `Sound_ResetAndResume` | `$2FAB` | `$1E32` |
| `Sound_InitSong` | `$2FB1` | `$1E38` |
| `Sound_Resume` | `$2FE8` | `$1E6F` |
| `Sound_MuteAll` | `$2FF6` | – |
| `Sound_Update` | `$3009` | `$1E77` |
| `Sound_UpdateSFX` | `$303F` | `$1EAD` |
| `Sound_MusicTick` | `$3115` | `$1F97` |
| `Sound_LoadSongHeader` | `$31A7` | `$202A` |
| `Sound_ClearTranspose` | `$31D6` | `$2059` |
| `Sound_ReadMusicTrack` | `$31E9` | `$206C` |
| `Sound_ParseTrack` | `$31FE` | `$2082` |
| `Sound_SaveTrackPtr` | `$3208` | `$208C` |
| `Sound_PlayNote` | `$321F` | `$20A4` |
| `Sound_SetNoteLength` | `$32EA` | `$216F` |
| `Sound_DoCommand` | `$32FC` | `$2181` |
| `SndCmd_Rest` ($12) | `$330E` | `$2193` |
| `Sound_NoteOff` | `$331D` | `$21A3` |
| `SndCmd_Tempo` ($20) | `$334E` | `$21D6` |
| `SndCmd_Timbre` ($1D) | `$3359` | `$21E1` |
| `SndCmd_Sweep` ($1E) | `$337A` | `$2202` |
| `SndCmd_Panning` ($26) | `$338A` | `$2219` |
| `SndCmd_Octave` ($13) | `$3390` | `$221F` |
| `SndCmd_OctaveUp` ($14) | `$339D` | `$222C` |
| `SndCmd_OctaveDown` ($15) | `$33A9` | `$2238` |
| `SndCmd_Envelope` ($1F) | `$33B5` | `$2244` |
| `SndCmd_Call` ($16) | `$33C2` | `$2251` |
| `SndCmd_Jump` ($25) | `$33E4` | `$2273` |
| `SndCmd_Return` ($17) | `$33F6` | `$2279` |
| `SndCmd_LoopStart` ($18) | `$3410` | `$2294` |
| `SndCmd_LoopEnd` ($19) | `$3438` | `$22BC` |
| `SndCmd_StopTrack` ($1C) | `$3463` | `$22ED` |
| `SndCmd_SongLoop` ($1B) | `$347C` | `$2308` |
| `SndCmd_Sync` ($1A) | `$348A` | `$2316` |
| `SndCmd_Unused21` ($21) | `$3498` | `$2324` |
| `SndCmd_Gate` ($23) | `$349D` | `$2328` |
| `SndCmd_Transpose` ($24) | `$34AA` | `$2335` |
| `SndCmd_Unused27` ($27) | `$34B7` | `$2342` |
| `SndCmd_Unused22` ($22) | `$34BC` | `$2346` |
| `SoundCommandTable` | `$34C0` | `$2354` |
| `SFXChannelMasks` | `$34EC` | `$1F84` |
| `SoundRegTable` | `$34F3` | `$1F8B` |
| `OctaveOffsets` | `$34FF` | `$2380` |
| `FrequencyTable` | `$3507` | `$2388` |
| `DefaultWave` | `$35AD` | `$242E` |
| `SongTable` | `$35BD` | `$243E` |
| `SFXTable` (first entry, id 3) | `$35E4` | `$2457` |
