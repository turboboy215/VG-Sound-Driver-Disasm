# The Legend of Zelda: Link's Awakening DX (GBC): sound driver

The Tanaka-family driver as used in *Link's Awakening DX* (`Legend of Zelda, The - Link's Awakening DX (U) (V1.0) [C][!].gbc`, MBC5, 1 MB). It takes three banks: two music banks, each holding **its own copy** of the music driver, and one SFX bank. All variables are in WRAM at `$D300–$D3FF`. The three banks rebuild **byte-exact** with RGBDS 0.9.1 from the sources in `Nint1\LADX`.

| Bank | Content | Files |
|---|---|---|
| `$1B` | music driver copy A; songs `$01–$10`, `$31–$40`, `$61–$6F` (33 headers) | `LA_Bank1B.asm`, `LA_1B_*.inc` |
| `$1E` | music driver copy B; songs `$11–$30`, `$41–$60` (62 headers) | `LA_Bank1E.asm`, `LA_1E_*.inc` |
| `$1F` | SFX: ch1 (65 effects), ch3 (35), ch4 (64); stop; DX volume code | `LA_Bank1F.asm`, `LA_1F_*.inc` |

```
LADX\build_check.sh              # assemble the three banks, link over the ROM, compare
LADX\harness\build.sh            # test ROM (MBC5) with the rebuilt banks
LADX\harness\verify_music.py     # play every song of $1B and $1E, check every pattern/list read
LADX\harness\verify_sfx.py       # play every effect, check every data read of the shared SFX routines
python LADX\gen_ladx.py <rom> LADX
```

The data model is the *SML2* one (`SuperMarioLand2_SoundDriver.md`): 16-byte channel structures, section lists, `$9B–$9F` commands, `$Ax` lengths, release envelopes. The header goes back to **11 bytes** (one length table, no fast mode).

---

## 1. Entry points and the per-frame order

Every bank starts with the same three stubs: `$4000 jp init`, `$4003 jp stop`, `$4006 jp update`. The game's home code (`$08A9–$08DA`) calls, each frame:

1. `$1F:$4006`: ch1, ch3 and ch4 effects, then clear the SFX requests;
2. `$1B:$4006`: start a song if it belongs here, play bank `$1B`'s music;
3. `$1E:$4006`: the same for bank `$1E`, then clear **all** request bytes.

It also calls `$1F:$7F80` every frame (§4.3) and `$1F:$4003` to stop everything.

**Which bank plays.** `wMusicIn1B` (`$D3CE`) decides. Bank `$1B` maps song numbers onto its table (`$01–$10` as is, `$31–$40 → $11–$20`, `$61–$6F → $21–$2F`). For any other number it clears the flag. Bank `$1E` ignores requests and does not play while the flag is set; it maps `$11–$30 → $01–$20` and `$41–$60 → $21–$40`. Each bank has its own table, pan table, note / noise / length tables and release envelopes.

| Variable | | Meaning |
|---|---|---|
| `wSongRequest` / `wSongPlaying` | `$D368` / `$D369` | song number, `$FF` = stop |
| `wSfx1Request` | `$D360` | ch1 effects 1–65 (may also use ch2) |
| `wSfx3Request` | `$D370` | ch3 (wave) effects 1–35 |
| `wSfx4Request` | `$D378` | ch4 effects 1–64; effect 1 is also the music's drum |
| `hResumeSong` | `$FFBF` | song restarted after jingles `$0F`, `$10`, `$25` (bank `$1E`: `$15`) |
| `hSfx1Request` … `hSfx4Request` | `$FFF2–$FFF4` | HRAM copies, moved into the request bytes by `$7F80` |

---

## 2. Music (banks `$1B`, `$1E`)

### 2.1 Pattern bytes

| Byte | Macro | Uses (both banks) |
|---|---|---|
| `$00` / `$01` / notes `$02–$90` / `$A0–$AF` | `PAT_END` / `REST` / `C2…B7` / lengths | |
| `$9B n` / `$9C` | `REPEAT` / `REPEAT_END` | 405 |
| `$9D` | `INSTR env, release, duty` / `INSTR_WAVE wave, level` | 372 / 70 |
| `$9E ptr` | `TEMPO` (length table) | 22 |
| `$9F n` | `TRANSPOSE` | 18 |
| `$99` / `$9A` | `CH3_FADEOUT_ON` / `_OFF`: NR32 50 % on frame 3, 25 % on 5, mute on 7, 25 % on 10, mute on 13 | 74 / 26 |
| `$94` | `CH3_FADEIN_ON`: NR32 25 % on frame 3, 50 % on 5, 100 % on 6 (no off command; `$9A` doesn't clear it) | 9 |
| `$97` / `$98` | `DROP_ON` / `_OFF`: period −100 per frame | 16 / 13 |
| `$96` / `$95` | `CH3_SFX_PAUSE` / `_RESUME`: the SFX bank skips its ch3 update while set | 8 / 5 |
| ch4 note byte | offset `1 + 5n` into `NoiseTable`: NR42, unused, NR41, NR43, NR44 | |
| ch4 `$FF` | `DRUM`: two-step noise drum (`wSfx4Request = 1`) unless an effect owns ch4 | |

`$95/$96` changed meaning since *SML2* (bend on/off there). Bend is gone.

**Length tables.** 15 entries: 1/32 … 1/1, three dotted values, then five entries that differ per table, then a dotted whole note (`L1D`). Bank `$1B` has 9 tables at `$4A8C`; bank `$1E` has a 12-entry noise table, so its tables start at `$4A8E`.

### 2.2 Per-note effects

| Effect | Bank `$1B` | Bank `$1E` |
|---|---|---|
| Duty low nibble 1 | vibrato from frame 25 (`VibratoTable`, as *SML2*) | same |
| Duty low nibble 5 | **vibrato 2**: 32 big-endian offsets (`Vibrato2Table`), from the first frame | not present (nibble 5 = detune) |
| other non-zero | period − 1 | same |
| release | `ReleaseEnvelopes[n − 1]` at the release point (*SML2*) | same |

**Ch3 wave reload.** When a ch3 effect ends it sets `wReloadWave`; the next music ch3 note reloads `wCh3WavePtr` before triggering (`Music_ReloadWave`).

**Stop exceptions.** Stopping the music or starting a song cancels the ch4 effect, unless it is `$05`, `$0C`, `$1A`, `$24`, `$2A`, `$2E` or `$3F`.

### 2.3 Song data quirks

- Bank `$1B`: table entries `$21–$30` (songs `$61–$6F`, plus an unreachable entry `$30`) all point to the one header at `$7100`.
- Bank `$1B`: unreferenced lists `$708F`, `$7095`, `$7129` (ch4 list of the `$7100` song, whose header has no ch4), patterns `$6F50`, `$7044`, `$705A`, `$7065`, `$7077`, wave `$4B26`.
- Bank `$1E`: ten unreferenced lists. Three groups (`$5531/$553B/$5545`, `$5745/$575F/$5791`) loop into the middle of real songs' lists: they look like alternative intros for songs whose headers point elsewhere.
- Bank `$1E`: `Pattern_6B78` has no `$00` of its own. It ends on the transpose byte (`$00`) of `Song4F_Header`, which follows it. The play check confirms the read.
- Bank `$1E`: song `$4F`'s ch3 list loops into its ch2 list.

---

## 3. Sound effects (bank `$1F`)

The design is *SML2*'s, now with three request slots of its own: ch1 (`$4100` init / `$4182` play, 65), ch3 (`$541B` / `$5461`, 35), ch4 (`$63EC` / `$646C`, 64). Each effect is an init routine and a per-frame routine; the shared helpers sit at `$7A64–$7B5B`:

| Helper | |
|---|---|
| `GetPointer` | `hl = table[a − 1]` |
| `Sfx_DecTimer` / `Sfx_IncStep` | `de` timer, `bc` step |
| `SetRegs_Ch1…Ch4`, `SetRegs_Copy` | write a register image (5/4/5/4 bytes) and store the next byte as the timer |
| `SfxN_DecCounter` | private counters (`$D3BC–$D3BF`); the ch2 one (`$7AA0`) is unreferenced |
| `SfxN_LoadPitch`, `SfxN_AddPitch` | running period + big-endian offset tables (ch1, ch2, ch3) |

**Starting and stopping.** `SfxN_Start` sets bit 7 of the music channel's Flags, so the music keeps reading notes without writing the registers. `SfxN_StartPriority` makes later requests on that slot refused (`SfxN_Refuse`) until it ends. Exceptions: ch1 request 1 and ch3 request `$14` always start. `Sfx4_StartWithCh2` also takes ch2 from the music. Ch1 effect 1 takes ch2 and ch3 as well (it writes all three).

**Waves.** Ch3 effects load one of six waves (`SfxWave_638C … 63DC`) through `Sfx3_LoadWaveXXXX`. Ending a ch3 effect sets `wReloadWave` for the music.

**Low-health beep.** With no ch4 effect playing, a non-zero `wLowHealthBeep` (`$C50E`, game RAM) keeps requesting ch4 effect `$1E`.

Data rows are grouped by the routine that reads them: 6 bytes (5 registers + frames), 5, 3 (2 registers + frames), 2 (pitch offsets), 16 (waves). Pointer tables are `dw`.

---

## 4. Stop and the DX additions

### 4.1 Stop routines

`$1B:$4E2C` / `$1E:` same: cancel the ch4 effect, fixed panning, stop the music, clear the effect state, mute ch1–ch3. `$1F:$7B5C` stops everything.

### 4.2 The `rP1` write and the nop slide

`$1F` `Sound_Stop` ends with `xor a / ldh [rNR10], a / ldh [rP1], a` and **no `ret`**: it runs through `$380` bytes of `nop` (`$7C00–$7F7F`) into `$7F80`. The write of 0 to `rP1` (joypad select) looks like a patch over the original routine's last instruction.

### 4.3 `$7F80`: master volume and HRAM requests

Called by the game every frame (home `$0364`), and reached from `Sound_Stop`:
- `hVolumeFadeOut` (`$FFA8`) counts down and every 4 frames lowers `hVolumeLeft` / `hVolumeRight` (`$FFA9/AA`);
- `hVolumeFadeIn` (`$FFAB`) every 2 frames raises them, up to 7;
- NR50 = the two volumes;
- non-zero `hSfx1/3/4Request` are moved into `wSfx1/3/4Request`.

---

## 5. Verification

- **Byte-exact rebuild** of all three banks (`ASSERT`s mark the file boundaries).
- **Emulator harness** (PyBoy). The test ROM contains the three rebuilt banks and calls them in the game's order. Requests go through WRAM mailboxes copied just before the updates.

  | | Reads | Outside the parse |
  |---|---|---|
  | Bank `$1B`, 46 songs × 3,600 frames (pattern / list) | 55,593 / 2,763 | 0 |
  | Bank `$1E`, 64 songs | 74,152 / 4,502 | 0 (after the `Pattern_6B78` end byte) |
  | ch1 effects 1–65 | 19,381 | 0 |
  | ch3 effects 1–35 | 12,232 | 0 |
  | ch4 effects 1–64 | 28,324 | 0 |

- **Not verified:** song and effect identities in the game; anything on hardware.

## Files (`Nint1\LADX`)

| File | Content |
|---|---|
| `LA_Bank1B/1E/1F.asm` | one section per bank; include the files below |
| `LA_1x_Driver.inc`, `_Stop.inc` | music code and tables with labels and comments |
| `LA_1x_Songs1/2.inc` | headers (`SongXX_Header`, `XX` = song number), lists, patterns |
| `LA_1F_Main/Sfx1/Sfx3/Sfx4/Common.inc` | SFX code and data (`Sfx1_01` … `Sfx4_40`) |
| `LA_Macros.inc`, `LA_RAM.inc` | macros and the `$D300` / HRAM map |
| `ladx_music.py`, `ladx_sfx.py`, `gen_ladx.py` | generators. Bank `$1E`'s names come from bank `$1B` by code alignment (`tools\transfer.py`) |
