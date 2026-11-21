# Turok: Battle of the Bionosaurs and Turok 2: Seeds of Evil (GB): sound driver

ROMs:

- `Turok - Battle of the Bionosaurs (UE) (M4) [!].gb` (DMG, MBC1, 256 KB, internal title `TUROK BATTLE OF`);
- `Turok 2 - Seeds of Evil (U) (M4) [C][!].gbc` (GBC-compatible, also runs on DMG; MBC5, 1 MB, internal title `TUROK 2: SEEDS `).

Part of the AJG family (Alberto José González / Bit Managers), see `AJG_SoundEngine_Family.md`. This is **version 4**, documented in full in `Smurfs_SoundDriver.md`. Both games use **Prisoners of the Sun's driver** (`TintinSun_SoundDriver.md`), including `PlayCh1Tone`, the RAM layout and the pause/output model. They change four things:

- **more instruments**, so the command ranges shift: Turok +2, Turok 2 +3;
- **one fixed instrument table**, which every `StartMusicChN` sets (Turok 2's `SndInit` sets it too);
- an **early exit in `CheckRelease`**;
- **10 drum sounds** with a new kit, and many more `CALL_CODE` noise routines.

Turok 2 is Turok's driver with three more instruments. Its GBC release still uses the DMG driver: no duty shadows and no NR31/NR41 writes, unlike Astérix & Obélix GBC. Hugo 2 (`Hugo2_SoundDriver.md`) is the third member of the Prisoners of the Sun group.

| | Turok | Turok 2 |
|---|---|---|
| Bank | **15**: driver and data `$4000–$7F97`, then the text `Final de la rutina de musicaca` (`$7F98`) and leftovers | **15**: `$4000–$7FBF`, then `Final de la rutina de musica` (`$7FC0`) and leftovers |
| Command table | `$4000` (37 commands, `$60–$84`, with `NOTE_HOOK`) | as Turok |
| API jump table (`$404A`) | `SndUpdate $40E4`, `SndPause $40AB`, `SndResume $40A4`, `StopAll $453D`, `PlaySfx $4934`, `SndInit $4522`, `SongFadeIn $4977`, `SongFadeOut $4971`, `PlayCh1Tone $408F`, **13 song slots** (`$4065–$4089`), `PlaySfxNow $4937` (`$408C`) | as Turok, but `StopAll $4547` |
| `StartMusicCh1/2/3` | **`$48F0` / `$48FE` / `$490C`** (14 bytes apart; previously 4) | as Turok |
| Tick | VBlank, once per frame (59.73 Hz) | as Turok |
| RAM | pages `$DC–$DF`, globals `$DC42–$DC65` (as Prisoners of the Sun) | as Turok |
| Ranges | `INSTR $85–$97` (19), `ARP $98–$B3`, `VOLENV $B4–$C3`, `LEN $C4–$F3` (1–48), `REPEAT $F4–$FF` (2–13); drum tempo bytes `$C4–$FE` | `INSTR $85–$9A` (22), `ARP $9B–$B6`, `VOLENV $B7–$C6`, `LEN $C7–$F6` (1–48), `REPEAT $F7–$FF` (2–10); drum tempo bytes `$C7–$FE` |
| Instrument table (all songs) | `$721A` (19 entries, from `$721C`) | `$732A` (21 entries, from `$732C`) |
| Tables | SFX `$73CC` (39), arpeggios `$72DD` (28 entries, 20 used; set by `SndInit`), CH3 volume `$41CC`, drums `$4A12` (10) | SFX `$7516` (31), arpeggios `$73FC` (28 entries, 26 used), CH3 volume `$41CC`, drums `$4A12` (10) |
| Counts | 13 songs, 39 SFX, 22 waves, 10 drum sounds + 19 `CALL_CODE` noise routines, 28 drum patterns | 13 songs, 31 SFX, 23 waves, 10 drum sounds + 17 `CALL_CODE` noise routines, 27 drum patterns |

Both rebuild **byte-exact** with RGBDS 0.9.1 over the whole of bank 15:

```
rgbasm -Wall -o turok.o Turok_SoundDriver.asm
rgblink -o turok.gb turok.o
python tools/cmp_banked.py turok.gb "Turok - Battle of the Bionosaurs (UE) (M4) [!].gb" 15:4000-7FFF

rgbasm -Wall -o turok2.o Turok2_SoundDriver.asm
rgblink -o turok2.gb turok2.o
python tools/cmp_banked.py turok2.gb "Turok 2 - Seeds of Evil (U) (M4) [C][!].gbc" 15:4000-7FFF
```

---

## 1. Game glue (bank 0)

The VBlank handler (Turok `$0854`, Turok 2 `$0A60`) switches to bank 15 and does the following:

- **Songs:** a routine address posted in a mailbox (Turok `$C2DD/$C2DE`, Turok 2 `$C2EB/$C2EC`) is cleared and called.
- **SFX:** if the queue count (Turok `$C2D6`, Turok 2 `$C2E4`) is not 0, it is decremented and one queued id goes to `PlaySfx` (API slot 4). That is one SFX per frame.
- **Update:** then `SndUpdate`.

It is the same shape as Prisoners of the Sun's handler, but **without the CH1-tone branch**. Nothing in either ROM calls `PlayCh1Tone`; only the API slot points to it.

`wStereo` (`$DC43`) is never written, by the driver or the game, so NR51 is `$FF`. **The pan commands in the data have no effect.** Several songs in both games use `PAN_C/R/L` and `AUTOPAN`.

## 2. Differences from Prisoners of the Sun

| | Prisoners of the Sun | Turok | Turok 2 |
|---|---|---|---|
| Ranges (`INSTR` / `ARP` / `VOLENV` / `LEN` / `REPEAT`) | `$85` / `$96` / `$B2` / `$C2` / `$F2` | `$85` / **`$98`** / **`$B4`** / **`$C4`** / **`$F4`** | `$85` / **`$9B`** / **`$B7`** / **`$C7`** / **`$F7`** |
| `StartMusicChN` | 4 bytes apart (`ld h, page` + `jr`) | each first sets **`wInstrTable` = `$721A`** (14 bytes apart) | the same with `$732A` |
| `SndInit` | NR52, arpeggio table `$7145` | arpeggio table `$72DD` | also **`wInstrTable` = `$732A`**; arpeggio table `$73FC` |
| `CheckRelease` (`RELEASE`) | the minimum-length test, then `CheckRelease2` tests "release on" (bit 1 of field `$04`) | **"release on" tested first** (`$4442`); the rest is unchanged | as Turok |
| Drum table | 10 entries (11th slot → data) | 10 entries (11th slot `$4A26` → `$7F71`, inside a noise table) | 10 entries (11th slot → `$7F99`) |
| SFX table / CH3 volume table | `$7236` / `$41D8` | `$73CC` / `$41CC` | `$7516` / `$41CC` |

The `CheckRelease` change does not change the sound: with release off, both versions return without doing anything.

**One instrument table per game:** `StartMusicChN` overwrites `wInstrTable`, and no song routine writes it. So every song plays with the same table, whatever the song routine does. In Turok 2, `SndInit` sets the same value as well. A converter can use the fixed table directly.

Everything else is Prisoners of the Sun's code:

- `PlayCh1Tone` (`$408F`, API slot 9; unused, §1);
- the pause model (`SndPause` and `SndResume` silence and reset the SFX page; `StopAll` and `SongFadeIn` call `SndResume`);
- no SFX priority;
- the single NRx4 write;
- the `HwEnvAtten` stub (Turok `$4614`, Turok 2 `$461E`);
- note on always resets the slide direction;
- no NR50 forcing;
- unused `NOTE_HOOK`, with `SetVolEnvBC` unreferenced (`$4370`).

Turok and Turok 2's drivers differ only in the ranges and in the extra `wInstrTable` write in `SndInit`.

### 2.1 Songs: Turok

Songs are numbered by API slot. As in Prisoners of the Sun, slot 1's routine is the last one in the bank.

| Song | Routine | Ch1 / Ch2 / Ch3 order lists | Length (ticks) |
|---|---|---|---|
| 1 | `$6D3E` | `$6D53 / $6D8F / $6D71` | loops |
| 2 | `$4B42` | `$4B6A / $4B7C / $4B58` | loops |
| 3 | `$4D27` | `$4D3C / $4D58 / $4D4A` | loops |
| 4 | `$4EF9` | `$4F0F / $4F27 / $4F1B` | loops |
| 5 | `$5137` | `$514D / $516B / $5189` | loops |
| 6 | `$5585` | `$559B / $55B3 / $55A7` | loops |
| 7 | `$56E8` | `$56FD / $571F / $5741` | loops |
| 8 | `$5A79` | `$5A8E / $5AB2 / $5AA0` | loops |
| 9 | `$5F63` | `$5F78 / $5F7C / $5F7A` | 490, ends |
| 10 | `$6022` | `$6037 / $606B / $6051` | loops |
| 11 | `$62E6` | `$62FB / $6323 / $630F` | loops |
| 12 | `$64BF` | `$64D5 / $6515 / $64F5` | loops |
| 13 | `$6A3C` | `$6A51 / $6A89 / $6A6D` | loops |

Data usage: 74 `REPEAT`s, 35 `CALL_CODE`s, 24 `PAT_CALL`s, 4 `PAT_GOTO`s, one `SLIDE_DOWN`. Not used: `STOP_ALL`, `FADE`, `FADE_OFF`, `VOL`, `SLIDE_UP`, `NOTE_HOOK`.

### 2.2 Songs: Turok 2

| Song | Routine | Ch1 / Ch2 / Ch3 order lists | Length (ticks) |
|---|---|---|---|
| 1 | `$6F94` | `$6FA9 / $6FDD / $6FC3` | loops |
| 2 | `$4B42` | `$4B97 / $4B77 / $4B57` | loops |
| 3 | `$4EA1` | `$4EB7 / $4EC1 / $4ECB` | loops |
| 4 | `$50B4` | `$50C9 / $50ED / $50DB` | loops |
| 5 | `$55A7` | `$55C0 / $55BE / $55BC` | 448, ends |
| 6 | `$5662` | `$5678 / $56C8 / $56A0` | loops |
| 7 | `$5A53` | `$5A68 / $5AA4 / $5A86` | loops |
| 8 | `$5CE5` | `$5CFB / $5D11 / $5D27` | loops |
| 9 | `$5F43` | `$5F58 / $5F8C / $5F72` | loops |
| 10 | `$6316` | `$6337 / $6331 / $632B` | loops |
| 11 | `$66A1` | `$66B6 / $66D6 / $66C6` | loops |
| 12 | `$6A00` | `$6A15 / $6A2D / $6A45` | loops |
| 13 | `$6D1D` | `$6D32 / $6D62 / $6D4A` | loops |

Data usage: 77 `REPEAT`s, 32 `CALL_CODE`s, 21 `PAT_CALL`s, 7 `PAT_GOTO`s, one `SLIDE_DOWN`. Not used: `VIB_OFF`, `STOP_ALL`, `FADE`, `FADE_OFF`, `VOL`, `SLIDE_UP`, `NOTE_HOOK`.

### 2.3 Sound effects

CH3-page streams. **Turok 2's SFX 1–30 are Turok's SFX 1–30** (the same streams, re-encoded for the shifted ranges); only SFX 31 differs.

| Id | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 12 | 6 | 80 | 30 | 24 | 27 | 36 | 55 | 8 | 30 | 12 | 15 | 23 |

| Id | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 27 | 35 | 40 | 30 | 13 | 30 | 45 | 23 | 40 | 26 | 30 | 20 | 29 |

| Id | 27 | 28 | 29 | 30 | 31 | 32 | 33 | 34 | 35 | 36 | 37 | 38 | 39 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 40 | 7 | 5 | 12 | 25 (Turok 2: 12) | 11 | 12 | 16 | 11 | 27 | 28 | 5 | 9 |

SFX 32–39 exist only in Turok.

### 2.4 Noise

Turok's kit is Prisoners of the Sun's with drums 6, 8 and 9 changed and drum 7's last NR42 step (`$55` → `$57`). Drums 3 and 4 share one routine, as there. Turok 2 changes drums 3–6 and 9 again.

| Drum | Turok routine | NR43 sequence | NR42 sequence | Turok 2 |
|---|---|---|---|---|
| 1 | `$7E4D` | `02 61 71 A1 B1 B1 A1` | `C1 F0 A0 90 70 40 33` | same (`$7E63`) |
| 2 | `$7E92` | `60 52 42 41 22 11 04` | `F0 F0 F0 A0 70 40 51` | same |
| 3 = 4 | `$7EBE` | `04 02 01 01 01 01 01` | `70 40 40 40 40 43 FF` | `04 02 01` / `80 FF 63` |
| 5 | `$7EDB` | `04 02 01 01 01 01 01` | `A0 60 32 FF FF FF FF` | the first 4 steps |
| 6 | `$7EF8` | `04 02 01 01 01 01 01` | `60 40 33 FF FF FF FF` | the first 4 steps |
| 7 | `$7F15` | `06 04 03 03 07` | `F0 C0 80 60 57` | same |
| 8 | `$7E6A` | `04 02 01 00 00` | `30 40 60 43 42` | same |
| 9 | `$7F32` | `51 41` | `F0 62` | `51 41 42 42 42 42 42 42 43 44 45` / `F0 63 FF …` |
| 10 | `$7F54` | `51 32` | `90 61` | same |

`CALL_CODE` noise routines: Turok has 19 (`$7714–$7B74`), Turok 2 17 (`$781D–$7C7D`). Turok 2's are Turok's minus two: `$7800` (a duplicate of `$77CE`) and `$7950`. Each sets a hold time (4–60 ticks) and an NR43/NR42 sequence pair; some have no NR42 sequence.

---

## 3. Quirks

1. **Fixed instrument table**: `StartMusicChN` sets it, so a song routine couldn't choose another (§2).
2. **`PlayCh1Tone` is kept but unused** (§1).
3. **Panning is dead** even though the songs use `PAN_*` and `AUTOPAN` (§1).
4. **Different end text:** Turok's end marker reads `…de musicaca`, Turok 2's `…de musica` (as Prisoners of the Sun).
5. The Prisoners of the Sun quirks apply (slides lose their direction at every note, the `HwEnvAtten` stub, unused `NOTE_HOOK` and `$80` fade byte, the drum table's 11th slot pointing into data).
6. **Unreferenced (marked in the asm):**
   - `Unused_SetVolEnvBC` (`$4370`);
   - padding before the period table: PC memory garbage (x86 code bytes; Turok `$47BC`, Turok 2 `$47C6`);
   - stray `ret` bytes and the drum table's 11th slot (`$4A26`);
   - **orphan noise routines** no table or stream refers to (disassembled as code). Turok: `Unused_Noise_7832`, `Unused_Noise_7A93`. Turok 2: `Unused_Noise_793B`, `Unused_Noise_7A59`, `Unused_Noise_7B9C`, and `Unused_NoiseSfx_7909`. That last one calls `NoisePanCentre` and writes NR42 = `$F1` and NR44 = `$80` itself before setting up an NR43-only sequence, so it plays an immediate hit;
   - Turok: the last 8 arpeggio table entries (`$7305`) and the two arpeggios they point at (`$73C8`, `$73CC`);
   - Turok 2: an unreached pattern (`$5915`), an SFX-like stream not in the table (`$77A7`: `CALL_CODE $7C3A`, `END`) and two more unreached streams (`$77F6`);
   - wave-sized blocks, the rest of a noise table after the 11th drum slot's target, and the leftovers after the end text.

## 4. Verification (lighter)

- **Byte-exact rebuild** of bank 15 of both ROMs (`tools/cmp_banked.py`).
- **Emulator trace** (`verify/v4trace.py`): the 13 song routines of each game (6000 ticks) and all SFX (39 / 31). On every tick, stream pointers, order positions and every byte the drum sequencer reads must be on walked items. **0 problems** (`verify/run_v4.log`). The lengths above come from this run. `PlayCh1Tone` is not exercised.
- Not done: no independent model.

## Files (in `GBAudioLab\AJG`)

- `Turok_SoundDriver.asm`: labelled, commented RGBDS source (names carried from Prisoners of the Sun by code alignment), byte-exact
- `Turok2_SoundDriver.asm`: the same, names carried from Turok
- shared version-4 tools and verification: see `Smurfs_SoundDriver.md` and the family doc §4

Regenerate:

```
python tools/gen_v4.py turok "Turok - Battle of the Bionosaurs (UE) (M4) [!].gb" Turok_SoundDriver.asm
python tools/gen_v4.py turok2 "Turok 2 - Seeds of Evil (U) (M4) [C][!].gbc" Turok2_SoundDriver.asm
```
