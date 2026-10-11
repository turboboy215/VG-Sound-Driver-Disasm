# Super Mario Bros. Deluxe (GBC): sound driver

*Super Mario Bros. Deluxe* (`Super Mario Bros. Deluxe (U) (V1.0) [C][!].gbc`, MBC5, 1 MB) uses a descendant of the *Link's Awakening DX* driver (`LinksAwakeningDX_SoundDriver.md`). It has one music bank (`$1D`) and one SFX bank (`$1F`); the variables are at `$DE00–$DEFF`, with the same layout as LA's `$D300` page. Both banks rebuild **byte-exact** from the sources in `Nint1\SMBDX`.

| Bank | Content |
|---|---|
| `$1D` | music driver, songs `$62–$7F` (30 headers), `$4000–$7FFF` |
| `$1F` | SFX: three request slots, a "note" request range, shared helpers; `$4000–$699F` (zeros after) |

```
SMBDX\build_check.sh   SMBDX\harness\build.sh   SMBDX\harness\verify.py
python SMBDX\gen_smbdx.py <rom> SMBDX      (uses ..\LADX\ladx_music.py / ladx_sfx.py)
```

**Order per frame** (home `$0F1A`): music `$1D:$4006`, then SFX `$1F:$4006`. The SFX update clears the requests. Entry stubs: `$4000` init, `$4003` stop, `$4006` update, as in LA.

---

## 1. Music (bank `$1D`)

1,006 of the 1,409 traced instructions align with LA bank `$1B`. The channel loop, note lookup, effects, drop, ch3 fades, panning and stop routines are LA's. These parts changed:

### 1.1 Commands

| Byte | Macro | |
|---|---|---|
| `$9D` | `INSTR env, $00, duty` or `INSTR_ENV table, duty` | second byte non-zero: the first two bytes are a pointer to a **per-frame envelope table** |
| `$9B n` / `$9C` | `REPEAT` / `REPEAT_END` | |
| `$97` / `$98` | `DROP_ON` / `_OFF` | the period now falls **32** per frame (LA: 100) |
| `$9A v` | `VOLUME` | NR50 = `v & $77` (new) |
| `$99 v` | `REST_ENV` | NRx2 written on rests, ch1 (`wCh1RestEnv`) or ch2 (new) |

LA's `$9E` (tempo), `$9F` (transpose), `$94`, `$95`, `$96`, `$99/$9A` (ch3 fades) are gone. Their handlers are still in the bank, unreferenced (`Unused_CmdTempo`, `Unused_CmdTranspose`, `Unused_CmdCh3*`). So are LA's song-range checks (`Unused_4198`), the "not in this bank" exit (`Unused_4058`) and LA's release envelopes (`$4D8F`). Every song's tempo comes from its header.

### 1.2 Envelopes instead of release

`Music_Envelope` replaces LA's release. For the first 48 frames of a note, a non-zero byte of the envelope table (indexed by `NoteFrames`) is written to NRx2 and the note retriggered (ch1, ch2). The trigger writes the table's first byte as the initial envelope. A rest writes the channel's `REST_ENV` once, after the channel has played a note (`wChannelsPlayed`); ch3 rests write level `$40`.

### 1.3 Pitch effects

Duty low nibble 1 = vibrato after 24 frames (LA's table); **2 = the same vibrato from frame 17**; other non-zero = period − 1. The LA `$1B` vibrato-2 table is gone. On ch3, the level counts up and mutes ch3 when it reaches 3.

### 1.4 Song control

- Requests `$62–$7F` = table entries `$22–$3F`; table entries `$01–$21` all point to song `$62`'s header and are unreachable. A request for the song already playing is ignored, except `$63`, `$65`, `$68`.
- **Hurry mode.** Song `$71` (hurry-up jingle) sets `wHurryMode` and saves the interrupted song in `wResumeSong`. Any other song clears it unless `HurryKeepTable` says otherwise. In hurry mode lengths come from `LengthTable_4D08`, or `4D17` (songs `$68`, `$7E`) / `4D80` (`$65`).
- **Resume.** When song `$71` ends:
  - a saved song `$62` or above is requested again;
  - a lower value is a **section number** of song `$62` (the overworld theme). `Music_ResumeLevelSong` rebuilds the channel state at that section of song `$62`'s lists (`Song62_ResumeLists`), without restarting the song.
- Stopping song `$2D` pauses it (`wPausedSong`); song `$6D` later restores it.
- In the update: ch1 effect `$6E` during song `$37` stops the music unless the previous song was `$7D`. NR31 is cleared every frame. `$4FFF` is an empty hook called whenever a request is pending.

### 1.5 Data quirks

- An unreferenced, self-contained header at `$5D3E`: no length table, three channels on the silent list.
- Unreferenced lists `$559A`, `$5973`, `$735A`. `Pattern_55B4`'s `INSTR` takes its third byte from the start of `Pattern_55B7`, so the source writes it as raw bytes.
- An unreferenced byte after the length tables at `$7AD7` and `$7D96`, and 30 unreferenced words at `$7F9E`.

---

## 2. Sound effects (bank `$1F`)

The machinery is LA's (helpers at `$6838–$68FA`: `GetPointer`, `Sfx_DecTimer/IncStep`, `SetRegs_Ch1–4`, counters, `LoadPitch`, `AddPitch`; several of them unreferenced here). The slots and numbering are new:

| Slot | Request | Effects | Channel |
|---|---|---|---|
| 1 | `wSfx1Request` `$DE60` | `$42–$78` | ch1 |
| 1 | same | `$80` stop, `$81` silence, `$82–$A6` **note**: NR10 = 8, NR11 = `$80`, NR12 = `$D2`, period from `SfxNoteTable` (a copy of the music note table at `$4100`), entry 25 on | ch1 |
| 2 | `wSfx2Request` `$DE70` | `$01–$04`, `$24–$3D` | **ch2** (LA: ch3) |
| 4 | `wSfx4Request` `$DE78` | `$3E–$48` | ch4, some on **ch3** (`Sfx4Wave_*`) |

Effect numbers are global: each slot's table covers every number up to its last effect. Numbers belonging to another slot point to a dummy (a real but unused effect body). Priority rules are per slot, with lists of effects allowed through (see the comments in `SMB_1F_Sfx1Start.inc` / `Sfx2Start.inc`).

New helpers: `SetRegsSkip0_Ch1/Ch2` (a zero byte leaves its register unchanged; the ch3/ch4 versions are unreferenced), `Sfx1_StopSilent`, and `Sfx_InitRegs` (a register list written by init: wave RAM cleared, NR10–14, NR21–24, NR30–34, NR41–44).

---

## 3. Verification

- **Byte-exact rebuild** of both banks.
- **Emulator harness** (PyBoy; game order, WRAM mailboxes):

  | | Reads | Outside |
  |---|---|---|
  | 30 songs × 3,600 frames (pattern / list) | 36,060 / 1,897 (with every song playing) | 0 |
  | slot 1, 55 effects + 39 note requests | 8,254 | 0 |
  | slot 2, 30 effects | 5,195 | 0 |
  | slot 4, 11 effects | 1,010 | 0 |

- **Not verified:** song and effect identities; hardware.
