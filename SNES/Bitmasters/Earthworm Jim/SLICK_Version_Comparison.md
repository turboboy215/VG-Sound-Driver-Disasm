# SLICK driver generations: Home Alone (1991), Aero the Acro-Bat (1993), Earthworm Jim v1.01 (1994)

This compares three versions of the Bitmasters SLICK SPC700 driver:

* **Home Alone** (1991), `01 - Main Theme.spc`. The earliest version, described in §11.
* **Aero the Acro-Bat** (1993), `01 - Circus 1 (Main Theme).spc`, SPC tagged "Rick Fox". Sections 1-10 compare it with v1.01.
* **SLICK/Audio v1.01** from Earthworm Jim (1994).

Files:
* `SLICK_HomeAlone_labeled.s`: labeled disassembly of the Home Alone driver. It reproduces `$0322-$1096` of the SPC exactly.
* `SLICK_Aero_Circus_labeled.s`: labeled disassembly of the Aero driver. It reproduces `$0700-$1E01` exactly. Labels match the v1.01 listing wherever a routine has a counterpart.
* `SLICK_EarthwormJim_labeled.s` and `SLICK_Engine_Notes.md`: the v1.01 reference.
* `slick_ha_dump.py`, `slick_old_dump.py`, `slick_dump.py`: data dumpers for the three versions.

Aero and v1.01 are clearly one engine: the same structure, variable layout style and many byte-identical routines. v1.01 is still a substantial rewrite of the interface and data formats; those two share no CPU protocol and no data format. Home Alone is an earlier, much smaller ancestor. It has fixed channels, no track allocation, hard-wired sound effects and a hardware-timer tempo, but the instrument record, DSP handling and several command codes carry straight through to 1994.

### Three-way overview

| | Home Alone 1991 | Aero 1993 | EWJ v1.01 1994 |
|---|---|---|---|
| Code | `$0322-$1096` survives (reset code self-erased) | `$0700-$1E01` | `$0580-$1D78` |
| Sequencer channels | 8 fixed, 9-byte DP records | 22 tracks | 22 tracks |
| Voice choice | written in each note (or = channel) | dynamic allocation, priority | + mono mode |
| Music at once | one song, 16 patterns at fixed `$1400` | banks, many sounds | banks, many sounds |
| Sound effects | hard-coded list (`$10-$20`) on voice 7 | sequenced sounds (handles < `$E0`) | same |
| Tempo | hardware timer 0 divisor (global) | byte per track | BPM per track |
| Delta / gate | VLQ, max 2 bytes; gate in timer ticks | VLQ 3 bytes; gate converted to ticks | VLQ 3 bytes; gate follows tempo |
| Commands | `E1` rest, `E3` end, `E4` goto pattern, `E5` sync all channels | `E1 E2 E3 E6 E7 E8 E9 EA EB` | `E0-EF` via jump table |
| Instrument | 8 bytes: SRCN ADSR1 ADSR2 flags transp – table – | 8 bytes (+ fine, flags2, vel/trem) | 10 bytes in split tables |
| Pitch | 2 global tables, no fine tune | 3 global tables + interpolation | per-sample tables |
| Volume | L/R nibbles × velocity (8-15) | vel × scale × volume, pan | + channel/master, surround |
| Echo | fixed at init (EDL 4, ESA `$70`) | per song | per song |
| Drums | hard-wired note→sample hack | global 16-zone drum map | per-instrument key split |
| CPU protocol | `$AB`/`$BA` magic in APUIO1 + command | flag byte + 3 words | numbered chainable commands |

---

## 1. At a glance

| | Aero (older) | EWJ v1.01 |
|---|---|---|
| Signature string | none | `SLICK/Audio v1.01 Copyright(C)1994 Bitmasters,Inc.` |
| Driver image | `$0700-$1E01` (5,890 bytes), entry `$0700` | `$0580-$1D78` (6,137 bytes), entry `$0878` |
| Tracks / voices | 22 / 8 | 22 / 8 |
| Instruments | 58 × 8-byte records at `$0500` | 128 × 10 bytes, split tables at `$1E00` |
| Drum map | one **global** 16-zone map at `$06D0` | per-instrument key-split records |
| Sample directory | `$1F00` | `$2300` |
| Pitch | 3 **global pitch tables** in the driver (`$1314`) | 27-byte pitch header in front of each sample |
| Sound lookup | 8-slot BankTable {first ID, pointer}, consecutive IDs | up to 8 banks of linked entries with explicit IDs |
| CPU protocol | one flag-bit command byte + 3 parameter words | numbered commands `$02-$16`, chainable |
| Event queue | `$0492`, **written directly by the CPU** | `$0204`, filled by I/O `$0A` |
| CPU feedback | notification buffer (sound finished / chained) | 16 sync flags set from the sequence (`EC/ED/EE`) |
| Tempo | raw byte, `125·T/16` ticks/s (BPM ≈ 0.98·T at 480 PPQN) | `(T+40)/60` in 8.8 fixed point, BPM = T+40 at 125 PPQN |
| Gate | converted to 8 ms ticks at note start | counted down with the live track tempo |
| Modulation | tremolo / auto-pan only | vibrato (pitch) **and** tremolo |
| Volume chain | velocity × vel. scale × volume, pan | + channel volume, master volume, surround mode |
| Fade-out | system `$01` (works) | removed (the code is still there, nothing sets the bit) |
| Chained sounds | implemented (`ChainNext`) | stubbed out (`RET`) |
| MIDI input | code present but **unreachable** | queue event type 0, with CC7/CC10 |
| Pause | – | system `$06` |
| Reboot to IPL | – | I/O `$0C` |
| Sample streaming | system `$08` (moves DIR entry, patches BRR end flags) | – |

## 2. Memory map

| Aero | Contents | EWJ equivalent |
|---|---|---|
| `$00-$E2` | direct page (timers `$2D/$43/$59/$6F`, voice state `$85-$BD`) | `$00-$EB` (timers `$4B/$61/$77/$8D`, voice state `$A3-$E3`) |
| `$0200-$0208` | voice status for the CPU (`ENVX`, mask) | `$FF08-$FF10` |
| `$020A-$0426` | voice/track arrays, start params, chain list, echo | `$0278-$057E` |
| `$0490-$04D1` | event ring (write index `$0490` set by the CPU) | `$0202-$0243` |
| `$04E8-$04F9` | notification count + 8 × {type, ID} | sync flags `$0264` |
| `$0500-$06CF` | instrument records | `$1E00-$22FF` |
| `$06D0-$06FF` | drum map | (key-split records anywhere) |
| `$0D9A-$0DB9` | TrackPtrTable: 16 words **inside the code area** | – |
| `$1F00` | DIR | `$2300` |
| `$FF08-$FFF5` | voice/track arrays | `$FF08-$FFA9` |

Both drivers set CONTROL = `$03`, which hides the IPL ROM. The old driver depends on this, because `TrkPatBaseLo` (`$FFE0+x`) reaches `$FFF5`.

## 3. CPU ↔ APU interface

### Aero (`IoCommand`, `$1A3A`)

The main loop polls APUIO0 itself; there is no separate poll routine. APUIO2 shows the state: `$01` = waiting, `$FF` = handling a command, `$00` = processing a frame. APUIO0 holds **flag bits**:

| APUIO0 bit | Meaning |
|---|---|
| bit3 | Send the notification buffer (16 bytes) and clear it. No parameter words. |
| otherwise | Receive 3 words through APUIO2/3, one per APUIO1 counter step: **IoWord1** = address, **IoWord2** = install type, **IoWord3** = parameters |
| bit5 | Stop all audio first |
| bit7 | Upload a block to IoWord1 (2 bytes per step), then install by IoWord2: `1` samples, `3` sound bank, `4` instruments, `8` send notifications. Other values mean raw upload, e.g. of events into the queue |
| bit7=0, bit6=1 | Voice status to `$0200-$0208`, then send the block at IoWord1 |
| bit7=0, bit6=0 | Immediate system command IoWord3-hi. Only `$01` (stop all) and `$08` (stream) are usable this way; the others read `$04/$05`, which this path does not set |

APUIO3 = **NotifyStatus**: bit3 = notifications pending, bits0-2 = count.

### v1.01

Numbered, chainable commands through `PollCPU` (Engine Notes §4). The notification buffer was replaced by sync flags plus Status bit0. Install commands exit the command chain early. Uploads evict any overlapping bank.

## 4. Event queue

| | Aero `$1BFB` | v1.01 `$1BAE` |
|---|---|---|
| Written by | CPU upload to `$0490-$04D1` (index + data) | I/O `$0A` |
| Type 0 | – (falls into "restart") | MIDI message |
| Type 1 | system | system |
| Type 2 | start sound | start sound |
| Type 3 | restart (stop handle first) | nop |
| Type ≥ 4 | restart | 4 = restart |
| Parameter entry | {–, pan, volume (bit7 = **notify on end**), tempo offset} | {pan, volume, tempo offset, –} |

The start-sound event is the same in both: {type, sound ID, key offset, handle}. Handles ≥ `$E0` count as music in both.

## 5. System commands (queue type 1)

p0 is either a direct command or `$80` + a sub-command. p1 is usually the sound handle and p2 the value.

| Aero | v1.01 | Function |
|---|---|---|
| p0 `$01` | p0 `$01` | stop everything |
| p0 `$08` | – | stream sample segment (IoWord1/2 = offsets, IoWord3-lo = DIR slot) |
| – | p0 `$20-$3F` | pitch bend of a sound |
| sub `$01` | – | **fade out** sound p1 (TrkStatus/VoiceState bit3, −1 volume per tick) |
| sub `$02` | sub `$02` | stop sound p1 |
| – | sub `$04` | write DSP register |
| – | sub `$05` | stop all tracks |
| – | sub `$06` | pause / resume |
| – | sub `$07` | clear instrument table and banks |
| sub `$10` | sub `$10` | tempo offset |
| sub `$11` | sub `$5n` | key offset. Aero: whole sound. v1.01: per track, and also transpose |
| sub `$12` | – | nop |
| sub `$13` | – | stop request: at loop end only (bit2) |
| sub `$14` | sub `$14` | stop request: at loop end or `EB` (bit1), + chain p2 |
| – | sub `$15` | master volume |
| sub `$16` | sub `$7n` | volume. Aero: whole sound. v1.01: track n |
| sub `$17` | sub `$6n` | pan. Aero: whole sound. v1.01: track n |
| sub `$20` | sub `$20` | stereo mode. Aero: 0 mono / other stereo. v1.01 adds 2 = surround |
| sub `$22` | sub `$22` | mute track p2&$0F. Aero: p2 high nibble `1` = unmute, anything else = mute. v1.01: p2 bit4 = mute |
| – | sub `$4n` | program / flag change per track |

v1.01 routes every parameter change through `TrkParamTable`/`VoiceParamTable` (13 indexes). Aero uses if-chains with parameter codes: `0` volume, `1` pan, `$FF` tempo offset, `$FE` velocity, `$FD` bend (voices only), other negative values = key offset.

## 6. Data formats

### Sound bank / sound header

**Aero**:
* The bank is registered in BankTable as {first ID, pointer}. It holds `count, –, word offset × count`, so the IDs in a bank are consecutive.
* Sound header:
  * `word`: offset of the track-pointer list
  * `n` pointers
  * number of tracks
  * flags
  * tempo
  * echo flag [+12 echo bytes, same order as v1.01]
  * 7-byte track headers
* The pointer list is copied into `TrackPtrTable`, and the pattern base follows the list.
* Installing a bank adds IoWord3-hi to every **program** number in its track headers (instrument relocation).

**v1.01**: size-linked entries with explicit IDs, 8-byte track headers carrying a direct data offset. Installing adds LoadID to the **sound IDs**.

| Track header byte | Aero (7 bytes) | v1.01 (8 bytes) |
|---|---|---|
| 0 | velocity | flags |
| 1 | pan | priority |
| 2 | program | velocity |
| 3 | priority (&$3F) | pan |
| 4 | index into the pointer list | transpose |
| 5 | flags | program |
| 6 | transpose | data offset (word) |

The track flags have the same meaning: bit0 no velocity, bit1 keep weak notes, bit2 order list, bit7 loop at `E3`. v1.01 adds bit3 (monophonic), bit4 (never used safely) and bit5 (surround).

### Instruments

| Byte | Aero record (8 bytes) | v1.01 (10 tables) |
|---|---|---|
| 0 | SRCN. bit7 = drum map; `$FF` or ≥ `$3A` = use record 0 | SRCN, `$F8-$FE` = key-split record |
| 1/2 | ADSR1 / GAIN, ADSR2 | same |
| 3 | flags (same bits 0-6) | same |
| 4 | transpose | same |
| 5 | fine tune | same |
| 6 | flags2: **bits0-1 = pitch table**, bits4-7 tremolo rate | flags2: bit0 coarse P(L), **bit3 vibrato**, bits4-7 tremolo rate |
| 7 | velocity sensitivity / tremolo depth | same |
| 8 | – | vibrato |
| 9 | – | modulation delay |

The release/GAIN logic is the same, but the bits in the voice flags moved: old bit4 = one-shot became `VRelFlags` bit0.

### Drum map vs key split

* **Aero** has one table for everything: 16 × {instrument, key, flags}.
  * A hit plays at note **36** (+3…+6 when triggered from key+1).
  * Zone 14 can also cover key…key+3 with offsets {0, 6, 11, 14}.
* **v1.01** uses a per-instrument record with its own ADSR and any number of zones.
  * Base note **60**.
  * The two near-miss range modes use the table {0, 6, 11, 15 / 0, 6, 9, 12, 15}.
  * The one-key-too-wide range noted in the v1.01 bug list was introduced by this redesign.

### Pitch

* **Aero**: `index = (base note + key offset + bend) × 2` into one of three global word tables (`$1314` 108 entries, `$13EC` 96, `$14AC` 96), linearly interpolated. Setting flags2 bits0-1 = 3 would read a "table pointer" from the code bytes at `$1572`.
* **v1.01**: every sample carries its own 12-note octave table and base octave, shifted by octave. Tuning moved from the driver into the sample data.

## 7. Sequence format

The event framing is identical: note / bend / command, each followed by a MIDI VLQ delta, a gate VLQ per note, stored halved. The order-list mechanism (`E8`, first pattern byte skipped) and loop mechanism (`E2 00` / `E2 nn`, `EB`) are also the same.

| Byte | Aero `$0A4E` | v1.01 `$0CC2` |
|---|---|---|
| `00-7F` | note | note |
| `80-BF` | **note** | ignored + 1 data byte |
| `C0-DF` | bend | bend |
| `E0` | (treated as a note!) | nop |
| `E1` | nop | nop |
| `E2` | loop | loop |
| `E3` | end (the pointer stays on `E3`); chain + notify | end |
| `E4`/`E5` | (note!) | nop |
| `E6` | program | program |
| `E7` | tempo: **raw byte, overwrites the tempo offset** | tempo = byte + 40 + offset |
| `E8` | next pattern | next pattern |
| `E9 cc vv` | 1 = volume, 2 = pan | 1 = **channel** volume, 2 = pan |
| `EA xx yy` | skip 2 bytes | nop, no parameters |
| `EB` | stop point | stop point |
| `EC/ED/EE` | (note!) | sync flags |
| `EF` | (note!) | nop |
| decoding | CMP chain | jump table (`$F0-$FF` illegal) |

The Aero data in the SPC uses only `E2 E3 E6 E8 E9 EB` and bends. `slick_old_dump.py` counts 1,114 notes, 881 bends and no unknown bytes.

Converting old data to v1.01 would need:
* new tempo values,
* the `EA` two-byte skips removed,
* velocity handling checked (`E9 01` now means channel volume, not track volume),
* no notes ≥ `$80`.

## 8. Playback engine

| Topic | Aero | v1.01 |
|---|---|---|
| Voice allocation | free/oldest → lower → equal priority | same + monophonic flag |
| Key-on | state 2: waits one frame after the old voice is cut with GAIN `$9F` | state 1: next voice pass |
| Note end detection | ENDX, or ENVX falling below **`$10`** | below **8** |
| Gate | 8 ms ticks: gate × 32 / tempo when the note starts (`GateToTicks`) | tempo-scaled countdown |
| Volume | vel' × f(vel scale) × f(volume); pan < `$40` attenuates R, > `$40` attenuates L | 2p/255−2p pan law, channel + master volume, surround |
| Tremolo | VTremL/VTremR moved in opposite directions (auto-pan) | depth-scaled triangle on both sides |
| Vibrato | – | triangle on the pitch fraction |
| Echo start-up | identical code | identical (the `EchoDelayCur = $FF` quirk is in both) |
| FLG after init | unmuted immediately | muted until the first sound starts |
| Sequencer stop | `SeqDisable` (`$E1`, only set by dead MidiReset) | per-track timer `$80` |
| Chain | `ChainNext` pushes {2, next, key offset, handle} + {3, $FF, volume, tempo} into the queue | list still written, hook is `RET` |
| End notification | `NotifySoundEnded`: posts {1, ID} if volume bit7 was set and no other track of the ID is active | – |

## 9. Routine map

| Aero | v1.01 | Notes |
|---|---|---|
| `$0700` Reset | `$0878` | same, except the instrument/drum area is not cleared |
| `$0743` MainLoop | `$08D0` | polls APUIO0 inline |
| `$0810` VoiceLoop | `$0988` | key-on countdown from 2 |
| `$0888` TrackLoop | `$0A47` | tempo × ticks × 16 |
| `$08E0` VoiceGateCountdown | `$0AA9` | ticks, not tempo |
| `$092F` AllocVoice | `$0B38` | no mono mode |
| `$09D5` InitDSP | `$0BED` | identical DSP part |
| `$0A4D` NullSub | `$0C64` UnmuteDSP | |
| `$0A4E` ProcessTrackEvents | `$0CC2` | CMP chain → jump table |
| `$0C4F` ReadDeltaAndAdvance | `$0D51` | identical |
| `$0C72` VoiceKeyOn | `$0EBA` | |
| `$0CB3` ReadVLQ | `$0F04` | identical |
| `$0CFC` GateToTicks | – | removed |
| `$0D3A` ChainNext | `$0F3B` ChainHookStub | reduced to `RET` |
| `$0DBA` AllocTrack | `$0F3C` | |
| `$0E84` StealTrack | `$1025` | identical logic |
| `$0F18` VoiceNoteOn | `$05F2` | |
| `$10D1` DrumMapLookup | `$07AD` KeySplitLookup | redesigned |
| `$1157` QEv_System | `$10A8` | |
| `$117A` StartSound | `$113D` | new bank/header format |
| `$1293` FindNextTrackByID | `$1228` | identical |
| `$12B9` StreamSampleSegment | – | removed |
| `$1572` SystemSubCommand | `$126F` | |
| `$1675` StopAllAudio | `$139E` | |
| `$16A6` ProcessFades | `$13D3` | identical, unused in v1.01 |
| `$16ED`/`$1746` ApplyParam… | `$141A`/`$145F` + tables | |
| `$17B7` CalcVoiceVolume | `$1584` | |
| `$1821` CalcVoicePitch | `$163F` | global table → per-sample table |
| `$18A0` StopSound | `$1718` | |
| `$18E2` TremoloUpdate | `$1763`/`$17AC` | new algorithm; `$17E2` VibratoUpdate added |
| `$1974-$1A39` echo setters | `$1868-$192D` | byte-identical logic |
| `$1A3A` IoCommand | `$192E` PollCPU + IoCmdTable | protocol replaced |
| `$1ACF`/`$1B14` notifications/send | `$1993` read stream | |
| `$1B3E`/`$1BA6`/`$1BCB` installs | `$1A8D`/`$1A33`/`$1ADE` | |
| `$1BFB` ProcessEventQueue | `$1BAE` | |
| `$1C59`/`$1C83` notifications | `$1C02` SignalSyncFlag | |
| `$1CC3-$1E01` MIDI (dead) | `$1C17-$1D78` | CC handling added, reachable |

## 10. Quirks in the older driver

* Bytes `$E0`, `$E4`, `$E5` and `$EC-$FF` in sequence data are played as notes (the CMP chain falls through to the note handler).
* `E7` stores the raw tempo and drops the start-event tempo offset.
* Instrument flags2 bits0-1 = 3 picks a pitch-table pointer made of code bytes (`$FF8F`).
* `InstallBank` with all 8 BankTable slots taken by other IDs writes at `$1CAB+$FD` = `$1DA8`, which is inside the dead MIDI code.
* Immediate system commands through IoCommand use stale `$04/$05`.
* `E9 01 vv` writes TrkVolume, whose bit7 is the "notify when finished" flag from the start event. Setting the volume from the sequence clears that request.
* The MIDI section (`$1CC3-$1E01`), the leftovers at `$0B12`, `$0B4C`, `$0CEA`, `$0CF4` and the masks `$DE/$DF` are unreferenced or unused. MIDI Bn (controllers) is a bare `RET`.
* PMON is written on every note from a shadow that is never set.


## 11. The earliest version: Home Alone (1991)

`01 - Main Theme.spc` (SPC tags: game "Home Alone", artist "Slick Mandela") holds a much simpler predecessor. It has no version string.

### 11.1 Image and memory

* **Code.** The driver code survives from `$0322` to `$1096`. Everything from the start of RAM clearing up to `$0323` is zero. The init loop at `$0322` clears memory up to `$04FF` with a store instruction that sits inside the cleared range. Once it overwrites itself with `00 00` (`nop nop`), the loop only counts the pointer to `$0500` and falls through into the surviving code. The entry point and reset code are therefore not in the snapshot. The driver was probably loaded at `$0200`; `$0200` is later reused as a variable.
* **Direct page.** Globals, 8 channel records of 9 bytes at `$22` (timer lo/hi, pointer, instrument, volume, flags, transpose, status), an SFX pseudo record at `$6A`, and per-voice gate/flags at `$79/$81/$89`.
* **Data inside the image:**
  * PatternTable `$062F` (16 words)
  * InstTable `$06B6` (32 × 8 bytes)
  * voice tables `$07B7/$07BF`
  * BuiltinSongTable `$0991`
  * pitch tables `$0B6E` and `$0C46` (108 words each)
* **Outside the image:**
  * song at `$1400`
  * DIR at `$2800`
  * echo buffer `$7000-$8FFF` (ESA `$70`, EDL 4 = 8 KB, EFB `$20`, FIR `$7F,0,…`, all fixed in InitDSP)

### 11.2 CPU interface (`MainLoop` `$0333`, `IoDispatch` `$09BE`)

The CPU writes the command to APUIO0, parameters to APUIO2/3, and the magic value **`$AB`** to APUIO1. With **`$BA`** instead, the driver additionally waits for `$CC` before it executes. The driver clears the input ports and acknowledges.

| Cmd | Function |
|---|---|
| `$00` | play built-in song `$02` (the only table entry is a leftover that points past PatternTable) |
| `$01` | stop all |
| `$02` | tempo: T0DIV = `$02` |
| `$04` | play the song uploaded at `$1400` |
| `$05` | stop all, then upload a block (handshake `$AA/$BB/$CC`, address in APUIO2/3, 1 byte per counter step, counter `$FF` = end) |
| `$06` | VolSelect = `$02`: use the second volume byte of each track (e.g. an alternative mix) |
| `$07` | report status in APUIO0: bit0 fade running, bit1 music active, bit2 SFX voice busy. APUIO1 = `$CD`, and the driver waits for `$EF` |
| `$81` | fade out music (timer 1, rate `$02`), then stop |
| `$80+n` | sound effect n. APUIO3 bits0-5 = priority, bit6 = keep volume, bit7 = repeat/echo mode |

**Sound effects** are not sequenced. `SfxStart` (`$0E45`) is a list of compares that picks an instrument, a volume and optionally a pitch sweep (up/down on timer 1) and plays one note on **voice 7** through the pseudo channel. Repeat mode replays the note at half volume each time until silent.

### 11.3 Song format (I/O `$04`, data at `$1400`)

```
+0  word  offset of the pattern list (+$1400)
+2  byte  n  (2n words are copied into PatternTable; only the first n are pointers)
+3  byte  number of tracks
+4  byte  flags (OR-ed into every track's flags)
+5  byte  T0DIV = tempo: tick = value x 125 us (Home Alone theme: $48 = 9 ms)
+6  tracks x 7 bytes:
      volume A, volume B   (hi nibble = left, lo nibble = right; VolSelect picks one)
      instrument, (unused), start pattern, flags, transpose
```

The built-in songs for I/O `$00` use the same layout with a single volume byte (6-byte tracks).

**Channel flags:**
* `0`: events carry no gate and play on the voice with the channel's number.
* Non-zero: every note carries a gate and names its own voice in the high nibble of the velocity byte.
* bit2: force voice = channel.
* bit1: no gate countdown (sustain).

There is no priority and no voice stealing. `StartChannel` simply takes the lowest free channel.

### 11.4 Sequence events (`ProcessChannelEvents` `$0423`)

| Bytes | Event |
|---|---|
| `nn vv [gate] delta` | note: any byte except the four below. vv low nibble = velocity (→ 8…15), high nibble = voice when the flags are non-zero |
| `E1 delta` | rest |
| `E3` | end of channel |
| `E4 pp delta` | continue at pattern pp. This is how songs loop |
| `E5` | **sync**: the channel waits until every active channel is parked on an `E5`, then all continue together. No delta follows |

Gate and delta are 1 byte, or 2 bytes when bit7 of the first is set (a two-byte MIDI VLQ). Channel timers lose `2 × ticks` per tick, so a delta unit is half a timer tick. Gates count whole ticks. Note numbers go straight into the pitch table: `(instrument transpose + note + channel transpose) × 2`, table 0 or 1 by instrument byte 6. There is no fine tune, bend or interpolation.

`slick_ha_dump.py` decodes the Home Alone theme: 4 patterns, 7 tracks, 1,046 notes, with each track looping back through `E5`, `E1` and `E4`.

### 11.5 Instruments and the percussion hack

The 8-byte instrument record already has the layout later used by Aero: `SRCN, ADSR1/GAIN, ADSR2, flags, transpose, –, table, –`. The flags byte has the same meaning (bit0 echo, bit2 ADSR vs GAIN, bit3 noise), except that bit1 is **PMON** here and tremolo in Aero.

SRCN bit7 enables `PercussionHack` (`$0908`). For the notes `$15`, `$1C`, `$1D`, `$1A` and `$21`, it rewrites the instrument's sample (8-11) and flags inside the table, forces a fixed pitch and doubles the volume. It is a hard-wired drum kit, and the ancestor of Aero's drum map.

### 11.6 What carried over

* The same DSP idioms: KOF before each note, EON/NON/PMON shadows set with or/eor per voice, ADSR1|`$80` vs GAIN selection by flags bit2, release with GAIN `$B7` when the gate expires.
* Global pitch tables selected per instrument (Aero keeps them and adds interpolation). v1.01 moves the tables into the samples.
* VLQ deltas and gates (2 bytes → 3 bytes), with the gate following the note in the event.
* Command numbers `E1` and `E3` keep their meaning in all three versions. `E4`/`E5` (goto, sync) were replaced by `E8` order lists and `E2` loops in Aero.
* The instrument's velocity nibble grows into Aero's velocity sensitivity. The L/R volume nibbles become a pan byte.

### 11.7 Quirks

* The reset code destroys itself (by design or by accident), which makes the driver impossible to restart without re-uploading.
* BuiltinSongTable references patterns `$20-$26`, which would read pointers from code at `$066F+`.
* I/O `$04` copies `2n` pattern words instead of `n`.
* Channel header byte 3 is read and pushed, then discarded (`StartChannel` pops it).
* Pitch table 1 ends with 12 junk values.
* `KeyOnHistory` (`$0200`) is only ever written.
* Two dead JMPs (`$038C`, `$0E36`).

### 11.8 Routine map (Home Alone → Aero → v1.01)

| Home Alone | Aero | v1.01 |
|---|---|---|
| `$0333` MainLoop | `$0743` MainLoop | `$08D0` MainLoop |
| `$0398` gate loop | `$08E0` VoiceGateCountdown | `$0AA9` |
| `$03E3` ChannelLoop | `$0888` TrackLoop | `$0A47` |
| `$0423` ProcessChannelEvents | `$0A4E` ProcessTrackEvents | `$0CC2` |
| `$052A` ReadDelta | `$0C4F` ReadDeltaAndAdvance | `$0D51` |
| `$0561` InitDSP | `$09D5` InitDSP | `$0BED` |
| `$064F` StartChannel | `$0DBA` AllocTrack | `$0F3C` |
| `$07C7` NoteOn | `$0F18` VoiceNoteOn | `$05F2` |
| `$0908` PercussionHack | `$10D1` DrumMapLookup | `$07AD` KeySplitLookup |
| `$09BE` IoDispatch | `$1A3A` IoCommand | `$192E` PollCPU |
| `$0A80` play uploaded song | `$117A` StartSound | `$113D` |
| `$0D1E` SfxTick (fade) | `$16A6` ProcessFades | `$13D3` |
| `$0DB1`/`$0E45` SFX | (sequenced sounds) | (sequenced sounds) |
| `$0FE5` StopAll | `$1675` StopAllAudio | `$139E` |
| `$1005` UploadBlock | `$1A7D` upload | `$19CB` FastReceive |
