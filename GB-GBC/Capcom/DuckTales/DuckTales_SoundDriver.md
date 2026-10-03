# DuckTales (GB): sound driver

ROM: `Duck Tales (E) [!].gb` (MBC1, 64 KB, internal title `DUCK TALES`). Capcom, 1990.

| | |
|---|---|
| API | bank 2 jump table: `$4026` play stage song, `$4029` `SndUpdate`, `$402C` (menu code, not sound), `$402F` `SndInit`, `$4032` `SndRequest` (B = request) |
| Game glue | ROM0 `$0183` init, `$0212` update call inside the VBlank handler, `$0725` stage song, `$072B` `GamePlaySound` (A = request) |
| Driver code | bank 2 `$4026–$469A` (tables inside, see §3) |
| Songs / SFX | bank 2 `$469B–$5C96` / `$5C97–$60F8` |
| Glue in bank 2 | `$615F–$6197` (`StageMusicTable`, `SndPlayStageMusic`, `SndRequest`) |
| Tick | VBlank, once per frame |
| RAM | HRAM only: `$FFA9–$FFFD` |
| Counts | 11 songs, 33 SFX ids (29 distinct streams) |

`DuckTales_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 for all five ranges (0:`$0183–$0194`, 0:`$0212–$0220`, 0:`$0725–$0743`, 2:`$4026–$60F8`, 2:`$615F–$6197`) and assembles cleanly with `-Wall`.

```
rgbasm -Wall -o dt.o DuckTales_SoundDriver.asm
rgblink -p 0xFF -o dt.gb dt.o
```

---

## 1. What it is

The GB driver is new code (Z80-style, all state in HRAM), but the **music data format is Capcom's NES "Mega Man 2" engine**, the one the NES DuckTales used. It is not the later "6C80" engine in `capmusfrm.txt`. What carries over:

- Commands `$00–$09` with the MM2 meanings: `$02` duty, `$03` volume, `$04` loop, `$05` key/octave base, `$06` dotted, `$07` envelope, `$08` vibrato, `$09` end. `$00` (NES tempo) and `$01` are still in the data but the GB driver skips their argument.
- Note bytes: bits 7–5 = length index, bits 4–0 = pitch (0 = rest).
- `$21–$2F` "connect" bytes, which Infidelity described for MM2 (`$21` = 2 notes held as one, `$22` = 3 …).
- `$30` = triplet prefix for the next note.

SFX use a separate, simpler format (§2.4).

**Three things replace the NES mechanics:**

- **Tempo = dropped ticks.** On 7 of every 8 frames (game frame counter `& 7 ≠ 0`) a counter counts down from the song's tempo byte. When it reaches 0, the whole music tick is skipped. Speed = `1 − 7/(8·T)` ticks per frame: T = 2 → 56 %, T = 4 → 78 %, T = 32 → 97 %.
- **Note cut = hardware length counter.** Every note is triggered with length enable (`NRx4 = $C0`) and `NRx1 = duty | (timer / 2)`. For CH1/2/4 the sounding time is `(64 − timer/2)/256` s. **Longer notes are cut sooner**: a 12-tick note sounds for about 14 frames, a 48-tick note for about 9, a 96-tick note for about 4 (checked in PyBoy, §6). CH3's 8-bit NR31 gives about 1 s.
- **Envelope = hardware.** `VOLUME` (NRx2 bits 7–4) and `ENVELOPE` (bits 3–0) are ORed into NRx2 at every note.

### HRAM

| Addr | Name | Use |
|---|---|---|
| `$FFA9` | hSndRequest | `$01–$3F` SFX, `$40\|n` song n, `$80\|n` command (1 = stop SFX, 2 = stop music). One request per frame. |
| `$FFAA` / `$FFAB` | hMusicID / hSfxID | current song / SFX (0 = none) |
| `$FFAC` | hMusTrigger | NRx4 bits for the next write: `$C0` new note, `$80` vibrato update |
| `$FFAD–$FFAF` | tempo reload, counter, half-length flag | from the song header |
| `$FFB0–$FFB9` | 4 stream pointers + vibrato table pointer | copied from the song header |
| `$FFBA–$FFBD` | channel, last byte, triplet flag, tie count | |
| `$FFBE–$FFC5` | hNoteBase ×3 | pointer into FreqTable (`BASE`) |
| `$FFC6–$FFCD` | hMusFreq ×4 | current period |
| `$FFCE–$FFD5` | hMusVib ×4 | vibrato enable / phase |
| `$FFD6–$FFE9` | loop counter, duty, note timer, volume, envelope ×4 | |
| `$FFEA–$FFFD` | SFX state | mask, channels left, pointer, timer, NRx1/NRx2, loop, slide, 4 channel locks, periods, vibrato, end flag |

---

## 2. Data format

### 2.1 Song header (`SongTable` `$432F`, 11 pointers)

`tempo, half, ch1, ch2, ch3, ch4, vib` (bytes, then 5 little-endian words). A zero channel pointer = channel unused. `half` ≠ 0 halves every note length (songs 5, 10, 11). `vib` points to a small per-song table (1–5 bytes) that `VIBRATO n` indexes.

### 2.2 Music stream

| Byte | Macro | Meaning |
|---|---|---|
| `00 xx`, `01 xx` | `IGNORED` | argument skipped (tempo etc. on the NES). `$01` appears 6×, `$00` never. |
| `02 xx` | `DUTY` | NRx1 bits 7–6 (CH3: ORed into NR31) |
| `03 xx` | `VOLUME` | NRx2 bits 7–4 (CH3: NR32, `$20` 100 %, `$40` 50 %, `$60` 25 %) |
| `04 n lo hi` | `LOOP` / `GOTO` | n = 0: jump forever. Otherwise jump n times (the body plays n + 1 times). One counter per channel, so loops don't nest. |
| `05 n` | `BASE` | pitch p plays `FreqTable[n + p]` |
| `06 nn` | `DOTTED` | note byte nn, 1.5× length |
| `07 x` | `ENVELOPE` | NRx2 bits 3–0 |
| `08 n` | `VIBRATO` | on if `vibtable[n] & $E0` ≠ 0: period ±1 every 3 frames |
| `09` | `MUS_END` | stops the **whole song** |
| `0A–0F xx` | – | argument skipped (unused) |
| `10–20` | – | end the tick without a note (unused) |
| `21–2F` | `TIE n` | the next n = b − `$1F` notes become one: lengths add, only the last pitch plays |
| `30` | `TRIPLET` | next note uses the triplet lengths |
| `31–FF` | `NOTE len, p` / `REST len` | len = bits 7–5, p = bits 4–0 |

Lengths in ticks: index 1–7 → 1, 3, 6, 12, 24, 48, 96 (`NoteLengths`). After `TRIPLET`: 1, 2, 4, 8, 16, 32, 64. Length index 1 is only reachable for pitches ≥ 17, since `$21–$30` are commands.

**Pitch:** `FreqTable` (`$45F3`) has 84 entries. Entries 0–11 are 0 and entry 12 = C2 … entry 83 = B7. The asm comments give note names from the current `BASE`. **CH4:** `NR43 = $30 | (p & 7)`, so there are only 8 noise sounds, and NR42 = volume | envelope.

### 2.3 Channel output

A note writes NRx1 (duty | timer/2), NRx2, NRx3 and NRx4 = `$C0 | hi`. Nothing is written while an SFX owns the channel (`hSfxOwn`), but the timers keep running. Vibrato rewrites NRx3/NRx4 without trigger.

### 2.4 SFX stream (`SfxTable` `$411F`, ids `$01–$21`)

First byte = channel mask (bit 0 CH1 … bit 3 CH4). Then:

| Byte | Macro | Meaning |
|---|---|---|
| `1hhh hhhh ll` (hi < `$88`) | `SNOTE period` | trigger the next channel left in the mask. Refills the mask when it's empty. Locks the channel against the music for 32 frames. |
| hi ≥ `$88` | `SREPEAT` | replay the previous period (the second byte is read but ignored) |
| `00 n` | `SWAIT n` | wait n frames (ends this frame's events) |
| `01 s` / `07 s` | `SSLIDE` | signed period change per frame, until the next event |
| `02 x` / `03 x` | `SDUTY` / `SENV` | NRx1 / NRx2 for the following notes (shared by all channels) |
| `04 n lo hi` | `SLOOP` | same as the music `LOOP` |
| `05 x` | `SVIBRATO` | bits 7–5 ≠ 0: period ±1 every 3 frames |
| `06` | `SEND` | stop when the current wait runs out |

`SfxPriority` (`$4035`): a new SFX starts if its priority is ≥ the current one. SFX use CH2 and CH4 only, except `$21` (all four). Stopping an SFX silences its channels, but the 32-frame lock keeps running, so the music comes back at its next note after the lock ends.

---

## 3. Layout (bank 2)

| Address | Content |
|---|---|
| `$4000–$4025` | 19 pointers to game data (not sound) |
| `$4026` | jump table |
| `$4035` | `SfxPriority` (34 bytes, id 0 unused) |
| `$4057–$410E` | `SndInit`, `SndUpdate`, `SndHandleRequest` |
| `$410F` / `$411F` | command table / `SfxTable` |
| `$4161–$432E` | SFX engine, `SfxCmdTable` `$41F3` |
| `$432F` / `$4345` | `SongTable` / wave RAM image (triangle) |
| `$4355–$45DA` | music engine, `MusicCmdTable` `$4431` |
| `$45DB` / `$45E3` / `$45EB` / `$45F3` | NRx1 addresses / `NoteLengths` / `TripletLengths` / `FreqTable` |
| `$469B–$5C96` | 11 songs (headers, streams, vibrato tables) |
| `$5C97–$60F8` | SFX |
| `$60F9–$615E` | menu cursor routine (game) |
| `$615F–$6197` | `StageMusicTable`, `SndPlayStageMusic`, `SndRequest` |

Every byte from `$469B` to `$60F8` is reached by the parser (headers, vibrato tables, streams). There's no dead sound data.

### Songs

| # | Header | Tempo | Speed | Ch | End | Used for |
|---|---|---|---|---|---|---|
| 1 | `$469B` | 4 | 78 % | 4 | loops | The Amazon (confirmed in game) |
| 2 | `$4ABE` | 32 | 97 % | 4 | loops | Transylvania (StageMusicTable 1 and 5) |
| 3 | `$4DC0` | 12 | 93 % | 4 | loops | African Mines (table 2) |
| 4 | `$4FBB` | 5 | 83 % | 4 | loops | The Himalayas (table 3) |
| 5 | `$5342` | 2 | 56 %, half lengths | 4 | loops | The Moon (table 4) |
| 6 | `$5582` | 16 | 95 % | 3 | loops | Land select (confirmed) |
| 7 | `$55BB` | 7 | 88 % | 4 | loops | not identified (requested from event scripts, 0:`$1C14`) |
| 8 | `$577C` | 3 | 71 % | 4 | loops | Title (confirmed) |
| 9 | `$5B9F` | 7 | 88 % | 3 | loops | not identified (0:`$33A1`), 86 bytes |
| 10 | `$5BF6` | 3 | 71 %, half | 3 | ends | jingle (0:`$16FC`, when `$CA1A` = 0) |
| 11 | `$5C57` | 3 | 71 %, half | 3 | ends | jingle (0:`$16F4`, when `$CA1A` ≠ 0) |

The land names for songs 2–5 come from `StageMusicTable` (`41 42 43 44 45 42`) and the menu order. The sixth entry (Transylvania again) matches the NES game's return to Transylvania at the end.

### SFX

Confirmed in game: `$01` land-select confirm, `$06` pause. Ids `$0F`/`$10` and `$1B–$1F` share a stream (`$1E`/`$1F` with higher priority). `$0E` is requested from the VBlank handler every 8 frames while a game flag is set (0:`$0204`). `$21` is the 4-channel jingle requested at 0:`$33E6`/`$3400`. Durations (engine frames until the SFX ends) run from 1 (`$12`, `$18`: notes left ringing) to 195 (`$21`).

---

## 4. Game interface

- **Boot:** `GameSndInit` → `SndInit` (APU on, NR50 = `$77`, NR51 = `$FF`, all channels silenced).
- **VBlank:** maps bank 2, calls `SndUpdate`, restores the bank.
- **Requests:** `GamePlaySound` (A) → `SndRequest`. A song request is dropped if that song is already playing. An SFX request doesn't replace a pending SFX request of higher priority. Some code writes `hSndRequest` directly (0:`$0204`, `$33E6`).
- **Stage start:** `GamePlayStageMusic` → `SndPlayStageMusic`: requests `StageMusicTable[wStage]` unless a song is playing.

---

## 5. Quirks and bugs

1. **Starting a song while an SFX plays makes the SFX read ROM0 as data.** `MusicStart` clears `$FFAC–$FFFE`, which includes the SFX pointer, timer and mask, but not `hSfxID`. The next `SfxUpdate` reads "SFX events" from `$0000` onwards until it happens to hit an end byte. PyBoy: SFX `$08` then song `$41` two frames later. The SFX pointer walked `$0000` → `$0107` over about 17 frames, writing periods to CH4, then stopped. In normal play the song usually starts before the SFX.
2. **Longer notes sound shorter** (length counter = `(64 − timer/2)/256` s, §1). With `timer ≥ 128`, the bits spill into the duty: this happens once (song 1 CH1, `$4711`, dotted whole note = 144 ticks → duty 75 % instead of 50 %).
3. **Tempo by skipping ticks** makes rhythms uneven: the skipped tick lands on a different note each time.
4. **One loop counter per channel,** so `LOOP` can't nest (the data never does).
5. **`MUS_END` stops all four channels**, not just its own. The jingles end all channels together, so this doesn't show.
6. **Dead commands:** `$00`, `$01`, `$0A–$0F` skip an argument, `$10–$20` end the tick. Only `$01` appears (6×, all in songs 5, 10, 11).
7. **SFX parameters are global:** duty/envelope/slide apply to every channel of the SFX. The slide resets at every event.
8. **SFX lock without restore:** after an SFX (or `$81`), the music stays silent on that channel until its next note after the 32-frame lock.
9. **Requests are a single byte:** a second request in the same frame overwrites the first. `SndRequest` only protects SFX priority.
10. **A request frame skips the SFX pass:** while `hSndRequest` is set, `SndUpdate` handles it and runs the music, but not the SFX tick or the lock countdown.

## 6. Verification

- Byte-exact rebuild (`cmp` over all five ranges).
- **Pitches:** for all 11 songs (3000 frames each, started from land select in the real ROM), every note written to NRx3/NRx4 with trigger (CH1–CH3 periods, CH4 NR43) matches a walk of the decoded streams, including loops and TIE.
- **Length counter behaviour:** measured NR52 channel-on time after triggers (§1).
- **In game:** title → song 8, land select → song 6, The Amazon → song 1, SFX `$01` on confirm, `$06` on pause. Quirk 1 was reproduced as described.
- Not verified: roles of songs 7 and 9–11 and most SFX. Nothing was checked on hardware.

## Files (in `GBAudioLab\CAP\DuckTales`)

- `DuckTales_SoundDriver.asm`: labelled, commented RGBDS source with music/SFX macros, byte-exact
- `tools/`: `dtparse.py` (data parser), `gen_dt.py` (generates the `.asm`), shared `asmgen.py`/`sm83.py`
- `verify/`: PyBoy scripts used for §6
