# Radikal Bikers (prototype): sound driver

ROM: `Radikal Bikers (E) (M4) (Prototype) [C].gbc` (GBC-only, MBC5, 2 MB, internal title `NONAME`). Sound bank **63**.

Part of the AJG family (Alberto José González / Bit Managers), see `AJG_SoundEngine_Family.md`. This is **version 4**, Rage Wars line. The bank names the driver right after its code (`$4C78`): `(Music & Sound Driver by Alberto Jose Gonzalez, 2000)`; the data ends with `Final de la rutina de musica` twice (`$783C`, `$7876`).

**The driver is Martian Alert's** (`MartianAlert_SoundDriver.md`), so it shares that build's three differences from Rage Wars (no glissando reset on the SFX page, `WAVE` doesn't stop `WAVE_SEQ`, SFX 1–5 don't cut 6+). On top of that:

- the RAM moves to **`$D0–$D3`** (WRAM bank 3) and every page gets one more field, `$40`;
- the command table has a **44th entry, `$8B`, which points at `PlaySong`**, so `INSTR` and `ARP` start one byte later;
- the vibrato/slide speed is **signed**;
- an **unfinished per-note duty reset** in the note on (never enabled);
- `PlaySong` also sets the arpeggio table;
- the driver runs from the **timer interrupt**.

| | |
|---|---|
| Bank | 63: driver `$4000–$4C77`, credit text, song data from `$4CAD`; sound data up to `$7891`, then PC memory garbage |
| Command table | `$4000`, **44 entries** (`$60–$8B`): Rage Wars' 43 commands + `$8B` → `PlaySong` (§2.2) |
| API jump table (`$4058`) | `SndUpdate $40E9`, `SndPause $40CE`, `SndResume $40C7`, `StopAll $45BA`, `PlaySong $4073` (A = 0–8), `PlaySfx $4A16` (A = 1–18), `SndInit $459F`, `SongFadeIn $4A64`, `SongFadeOut $4A5E` |
| Song table | `$6BA7`, 9 entries |
| Default tables (`PlaySong`) | instruments `$6A8D` (17 used), arpeggios `$6B32` (16 used; `SndInit` sets the same one); songs 1, 5 and 8 set their own instrument table (`$50A1`, `$5DC9`, `$656A`) |
| `StartMusicCh1/2/3` | `$49F0` / `$49F4` / `$49F8` |
| Tick | **timer interrupt** (vector `$0050` → RAM trampoline `$C0A8`): TMA `$77`, TAC `$FC`, double speed → **59.80 Hz** |
| RAM | **WRAM bank 3** (SVBK = 3 at every call): pages Ch1 `$D0xx`, Ch2 `$D1xx`, Ch3 `$D2xx`, SFX `$D3xx` (fields **`$00–$40`**); globals **`$D041–$D066`** in Rage Wars' order (`wPaused $D041`, `wShNR32 $D042`, `wInstrTable $D046`, `wArpTable $D048`, `wMusicWave $D04A`, drums `$D04D–$D054`, noise `$D055–$D05D`, fade `$D05E–$D063`, duty shadows `$D064/$D065`, `wCurSong $D066`) |
| Ranges | **`INSTR $8C–$A0`** (21), **`ARP $A1–$B7`** (23), `VOLENV $B8–$C7`, `LEN $C8–$F7` (1–48), `REPEAT $F8–$FF` (2–9); drum bytes as Rage Wars (tempo `$C8–$FE`) |
| Tables | SFX `$6BC9` (18), CH3 volume `$41D5`, drums `$4B7D` (14), period table `$4900`; fades `$7829` / `$7833` |
| Counts | 9 songs, 18 SFX, 11 waves, 14 drum sounds, 24 drum patterns |

It rebuilds **byte-exact** with RGBDS 0.9.1 over the whole sound bank:

```
rgbasm -Wall -o radikal.o RadikalBikers_SoundDriver.asm
rgblink -o radikal.gb radikal.o
python tools/cmp_banked.py radikal.gb "Radikal Bikers (E) (M4) (Prototype) [C].gbc" 63:4000-7FFF
```

---

## 1. Game side

The game runs the GBC in double speed and calls `SndUpdate` from its timer interrupt through a bank-0 far call (return address `$02CC`), with WRAM bank 3 selected. Timer: input 4096 Hz (8192 Hz in double speed), TMA `$77` (137 counts), so 8192 / 137 = **59.80 Hz**.

## 2. Changes from Martian Alert

### 2.1 RAM

All page addresses move down by two pages (`$D2–$D5` → `$D0–$D3`), and the pages get a new field **`$40`** (note-on duty, §2.4), cleared by `ResetMusicPage`. The globals follow it at `$D041` in the same order as Rage Wars (so each is 1 byte after Rage Wars' offset from the page start).

### 2.2 Command table entry `$8B`

The command table has 44 words: Rage Wars' 43 handlers, then **`$4073`, the address of `PlaySong`**. The dispatcher was changed to match (`INSTR` from `$8C`, `ARP` from `$A1`, so the arpeggio range is one shorter); `VOLENV`, `LEN` and `REPEAT` are unchanged. A `$8B` byte in a stream would run `PlaySong` with A = `$8B`: `StopAll` (all four pages reset), the default tables set, then `A ≥ 9` → return into the stream loop with H on the SFX page. **The data never uses it**; it is probably an unfinished command whose handler was never written. The asm calls it `CMD_8B`.

### 2.3 Signed vibrato and slide speed

The vibrato/slide step (field `$22`, the second `VIBRATO` byte or the `SLIDE_UP`/`SLIDE_DOWN` byte) is now **signed**: with bit 7 set, the step is negated, so the period moves the other way in each half-cycle. Martian Alert and Rage Wars add the byte as unsigned.

The data uses it once: `Pat_53A0` (song 2, Ch1) plays a 128-tick D2 with `VIBRATO $42, $F8, $01`: after 66 ticks the period moves by 8 in alternate directions every tick (a fast warble). On the earlier builds the same bytes would add 248 per step.

`SLIDE_UP`/`SLIDE_DOWN` are rewritten with `set`/`res` on `[hl]` (same effect); neither is used by the data.

### 2.4 Per-note duty (unfinished)

The note on of the pulse pages has a new step: **if bit 6 of the flags (field `$04`) is set**, the low 2 bits of field `$40` are written as duty bits 6–7 to the channel's duty shadow (`$D064` / `$D065`). Nothing in the driver sets bit 6 or writes field `$40` (only `ResetMusicPage` clears it), so this code never runs. Possibly it was meant for the `$8B` command.

### 2.5 Other

- **`PlaySong`** also sets `wArpTable` = `$6B32` (as `SndInit` does), and there are 9 songs (A ≥ 9 → silence).
- The 167 bytes before the period table are PC memory garbage (x86 code), as in Martian Alert (Rage Wars has zeros there).

## 3. Songs

| A | Routine | Instrument table | Length |
|---|---|---|---|
| 0 | `$4CAD` | `$50A1` (3) | loops |
| 1 | `$50C7` | default `$6A8D` | loops |
| 2 | `$54C9` | default | 920, ends with `STOP_ALL` |
| 3 | `$564A` | default | loops |
| 4 | `$5A6A` | `$5DC9` (13) | loops |
| 5 | `$5E2F` | default | loops |
| 6 | `$61B1` | default | loops |
| 7 | `$62E5` | `$656A` (8) | loops |
| 8 | `$65AF` | default | loops |

The asm numbers songs 1–9 in table order. Song 3 (A = 2) is the only song that uses `STOP_ALL` (once per channel), which stops the whole driver, SFX included. Panning is heard (3 `PAN_R`, 3 `PAN_L`, 1 `AUTOPAN`, 1 `PINGPONG`).

## 4. Sound effects

`PlaySfx` (A = 1–18). SFX 1–5 are the drums' CH3 hits, using the wave right after the song table (`$6BB9`, the same wave as Martian Alert's). Lengths (ticks): 3, 3, 4, 4, 4, 47, 19, 52, 30, 36, 40, 90, 40, 24, 24, 27, 8, 13.

## 5. Data notes

- **Unreferenced:** as Martian Alert, `SetVolEnvBC`, the `jp` before `SndResume` and the old noise auto-pan fragment; then several larger blocks after the SFX streams: `$6D5C` (506 bytes, mostly stream bytes in the SFX format whose `CALL_CODE` targets are in the next block), `$6FDE` (813 bytes) and `$7382` (438 bytes), which hold noise routines in the drum-routine format with their NR43/NR42 tables, and a few smaller gaps. These look like the leftover sound effects of an earlier SFX set (this is a prototype). After the second end text, `$7892–$7FFF` is PC memory garbage.
- **Unterminated drum pattern:** `$5642`.
- **Not used by the data:** `PAN_C`, `DUTY_25`, `FADE`, `FADE_OFF`, `SLIDE_UP`, `SLIDE_DOWN`, `PINGPONG_OFF`, `GLISS_1`, `CMD_8B`; no `WAVE_SEQ`.

## 6. Verification

`verify/v4trace.py` starts every song through `PlaySong` and every SFX through `PlaySfx`: **27 tests, 50 015 ticks, 0 problems** (`verify/run_v4.log`). The harness mailbox moves to `$CF00` for this game (`mailbox` in `v4cfg.py`), because the driver's Ch1 page is at `$D000`.

## 7. Files

- `RadikalBikers_SoundDriver.asm`;
- entry `radikal` in `tools/v4cfg.py` (command set `RADIKAL_CMDS`, `mailbox`) and `tools/v4games.py` (names carried from Martian Alert, `ref='martian'`).

Regenerate with `python tools/gen_v4.py radikal <rom> RadikalBikers_SoundDriver.asm`.
