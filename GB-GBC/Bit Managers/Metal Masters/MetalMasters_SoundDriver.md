# Metal Masters (GB): sound driver

ROM: `Metal Masters (U).gb` (DMG, MBC1, 128 KB, internal title `METAL MASTERS`). Bit Managers for Electro Brain, December 1993.

Part of the AJG family, see `AJG_SoundEngine_Family.md`. This is a **later variant of version 3**: Astérix's driver (`Asterix_SoundDriver.md`, the reference for everything not repeated here) with the note range cut by two to make room for an **echo** effect, and with sound effects that normally play **on the music channels**. Read this document as a list of differences plus this game's own data.

| | |
|---|---|
| Bank | driver and data in **ROM bank 2**, `$5A1C–$7544` (game code and data around it) |
| API | `$6295` `SndInit`, `$5A3C` `SndUpdate`, `$5E54` `StopAll`, `$6659` `PlaySfx` (SFX page), `$6689/$668D/$6691` `PlayOnCh1/2/3` (SFX on a music page), `$616C` `StartFade`, `$5A21` / `$5A1C` `SndPause` / `SndResume`, `$66BC` `SongFadeOut`. Songs: `$66C5`, `$66F4`, `$6738` |
| Tick | **VBlank** (59.73 Hz): the handler at `$3083` calls `$3200` → `SndUpdate` unless `hFFE9` = `$0D` |
| Game glue (bank 0) | each call is a small wrapper that switches to bank 2: `$31E9` `SndInit` + `wStereo` = 1; `$3222`/`$323C`/`$3256` songs 1–3; `$3270` `SongFadeOut`; `$328E` `StopAll` + NR50 = `$77` + fade off; SFX through the 27 stubs at `$702B–$70B1` (§4), reached from wrappers at `$32B0–$3485` and from a stub table at `$34DC` (`$3486`/`$34A9` reset the Ch1/Ch2 page first) |
| RAM | pages Ch1 `$C6xx`, Ch2 `$C7xx`, Ch3 `$C8xx`, SFX `$C9xx` (fields `$00–$49`); globals `$C5C0–$C5E5`, same order as Astérix's `$DB46–$DB6B` |
| Counts | 3 songs (all loop), 24 sound effects, 1 instrument table (3 used), 1 arpeggio table (3), 9 waves, 11 drum sounds + about 20 noise/sweep routines called with `CALL_CODE`, 3 drum patterns |

`MetalMasters_SoundDriver.asm` rebuilds **byte-exact** with RGBDS 0.9.1 over ROM0 `$0000–$0002`, `$0008–$000B`, `$0018–$001D`, `$1719–$1721` and bank 2 `$5A1C–$7544`. It assembles cleanly with `-Wall`.

```
rgbasm -Wall -o metalmasters.o MetalMasters_SoundDriver.asm
rgblink -o metalmasters.gb metalmasters.o
python tools/cmp_banked.py metalmasters.gb "Metal Masters (U).gb" 0000-0002 0008-000B 0018-001D 1719-1721 2:5A1C-7544
```

---

## 1. Differences from Astérix

| | Metal Masters | Astérix |
|---|---|---|
| Notes | `$00–$5D` | `$00–$5F` |
| Commands | `$5E–$84` (39): Astérix's 37 in the same order, **each byte 2 lower**, plus `$83` `ECHO_ON`, `$84` `ECHO_OFF` | `$60–$84` |
| Terminator bytes | `END` `$66`, `NEXT` `$68` (also the arpeggio/fade loop byte), `WAIT` `$63` | `$68`, `$6A`, `$65` |
| Echo | fields `$40–$49` (§2) | – |
| `NOTE_PAN` (`$82`) | also switches auto-pan off | – |
| `ResetChannel` | also clears the echo | – |
| Auto-duty cycle | 50 %, 75 %, 12.5 %, repeat | 50 % / 12.5 % alternating |
| Fade tables | only `FadeOutTable` (`$61DE`) | 4 |
| SFX | mostly `PlayOnChN` (§4) | `PlaySfx` (SFX page, CH3) |

`INSTR` `$85–$9D`, `ARP` `$9E–$AC`, `VOL` `$AD–$BC`, `VOLENV` `$BD–$CC`, `LEN` `$CD–$FF` are unchanged. Everything else (fields `$00–$3F`, envelope and divider, portamento, release, `CALL_CODE`, drums and noise with auto-pan, output, the quirks) is as in Astérix.

### 1.1 Stream bytes

| Byte | Macro | | Byte | Macro |
|---|---|---|---|---|
| `$5E n` / `$5F` | `GLIDE` / `GLIDE_OFF` | | `$72` | `DUTY_12` |
| `$60` | `WAIT2` | | `$73` | `HWENV` |
| `$61 d, depth, speed` / `$62` | `VIBRATO` / `VIB_OFF` | | `$74 n` / `$75 n` | `AUTOPAN` / `AUTODUTY` |
| `$63` | `WAIT` | | `$76 s, w` / `$77` | `FADE` / `FADE_OFF` |
| `$64` | `REST` | | `$78 w` | `WAVE` |
| `$65` | `STOP_ALL` | | `$79 s, d` / `$7A` | `PORTA` / `PORTA_OFF` |
| `$66` | `END` | | `$7B n` | `CH_TRANSPOSE` |
| `$67 n` | `TRANSPOSE` | | `$7C` | `RELEASE` |
| `$68` | `NEXT` | | `$7D` | `ARP_OFF` |
| `$69 w` | `ORDER_JUMP` | | `$7E w` / `$7F w` | `PAT_GOTO` / `PAT_CALL` |
| `$6A n` | `LENGTH` | | `$80 w` | `CALL_CODE` |
| `$6B t, w` / `$6C` | `DRUMS` / `DRUMS_OFF` | | `$81 n` | `ENV_DIV` |
| `$6D` / `$6E` / `$6F` | `PAN_C/R/L` | | `$82 n` | `NOTE_PAN` |
| `$70` / `$71` | `DUTY_50/75` | | `$83` / `$84` | `ECHO_ON` / `ECHO_OFF` |

Not used by the data: `STOP_ALL`, `FADE`, `FADE_OFF`, `ENV_DIV`. Used here but not in Astérix: `ORDER_JUMP`, `WAIT2` (55 times), `ECHO_ON/OFF`.

## 2. Echo

`ECHO_ON` sets field `$40` = 8 (read index) and `$41` = 4 (write index); `ECHO_OFF` (and any reset) clears both.

- At every note (before the period is set) the note is stored in an 8-entry ring buffer at fields `$42–$49` (entry i at `$41 + i`), and both indices step down (8 → 1, wrapping).
- At every `WAIT` and `WAIT2` the current note is stored the same way, then the note in the entry at the read index is made the channel's note (field `$0C`) and its period is set, without a retrigger. An empty entry (0) sets the note field to 0 and leaves the period alone.

With the read index 4 entries ahead of the write index, each tied tick plays the note stored three steps earlier (notes and tied ticks both count as steps), so held notes turn into a delayed copy of the melody. Song 1 uses it on Ch3 (pattern `$6B85`, `ECHO_ON` … `ECHO_OFF` in `$682F`).

## 3. Songs

| Song | Routine | Ch1 / Ch2 / Ch3 order lists | Length |
|---|---|---|---|
| 1 | `$66C5` | `$6782 / $67C2 / $67EC` | loops |
| 2 | `$66F4` | `$6723 / $6727 / $672B` | loops |
| 3 | `$6738` | `$6767 / $676B / $676F` | loops |

All three set NR50 = `$77`, stop the fade and use instrument table `$6D3A` (3 instruments) and arpeggio table `$7020` (3). Songs 2 and 3 have one-pattern order lists that loop with `ORDER_JUMP`.

## 4. Sound effects

`SfxTable` `$70B2` (24 entries). The game plays most effects with **`PlayOnChN`**, which resets music page N and runs the effect there; its `END` resets the page again, so **that music channel stays silent until the next song start**. Only the effects started with `PlaySfx` use the SFX page (CH3, replacing Ch3 while they play). The stubs (`ld a, id` / `jp …`):

| Stub | Id | Plays on | | Stub | Id | Plays on |
|---|---|---|---|---|---|---|
| `$702B` | 1 | Ch1 | | `$706C` | 12 | Ch3 |
| `$7030` | 2 | Ch1 | | `$7071`–`$7085` | 13–17 | Ch3 |
| `$7035` | 1 | Ch2 | | `$708A` | 18 | Ch2 |
| `$703A` | 2 | Ch2 | | `$708F` | 19 | Ch1 |
| `$703F` / `$7044` | 3 / 4 | Ch3 | | `$7094` / `$7099` | 20 | Ch1 / Ch2 |
| `$7049` | 5 | Ch1, then falls into `$704E` | | `$709E` / `$70A3` | 21 / 22 | SFX page |
| `$704E`–`$7058` | 6–8 | Ch3 | | `$70A8` | 23 | SFX page, then falls into `$70AD` |
| `$705D` / `$7062` | 9 / 10 | SFX page | | `$70AD` | 24 | Ch1 |
| `$7067` | 11 | Ch1 | | | | |

SFX streams here also use `DRUMS`, `DUTY_*`, `HWENV`, `CH_TRANSPOSE` and many `CALL_CODE` noise and sweep routines. Lengths through the SFX page (ticks):

| Id | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ticks | 18 | 18 | 35 | 35 | 13 | 15 | 261 | 13 | 4 | 4 | 4 | 13 | 14 | 19 | 25 | 17 | 13 | 22 | 9 | 14 | 9 | 199 | 26 | 26 |

## 5. Drums and noise routines

`DrumTable` `$5F9D` (11 entries). Drums 1–3 and 5–8 are Astérix's (same NR43/NR42 tables; drum 4 is `04 02 06 03` / `B0 A0 50 54`); drum 9 (`$6990`) is a 8-step sequence `70 71 72 73 71 72 73 74` / `80 60 40 20 80 60 40 21`; drums 10 and 11 are single steps (`61` with NR42 `0F` / `F7`).

The `CALL_CODE` routines include the Astérix-style "hold" drums (`$6EC1`, `$6F03`), a sweep effect that sets **NR10 = `$1E`** with a noise sequence (`$6913`) and one that clears NR10 (`$693D`; the driver itself never writes NR10), single noise hits written straight to NR42/NR43/NR44 (`$7306`, `$7313`, `$7320`, `$733A`), noise off (`$7347`), and longer noise sequences (`$7350`–`$74BC`).

## 6. Quirks (in addition to Astérix's)

1. **`PlayOnChN` effects end the music on their channel** (§4).
2. **An empty echo entry sets the note to 0** (§2); the next glide/arpeggio step would then use note 0.
3. `SndPause`/`SndResume` have no callers.

## 7. Verification (lighter)

Byte-exact rebuild; emulator trace of the 3 songs (6000 ticks) and the 24 SFX through `PlaySfx`, with the stream pointer, order position and drum position checked against the data walk on every tick: **0 problems** (`verify/run_v3.log`). `PlayOnChN` was not exercised separately (same stream format, different page). Routine names were carried over from Astérix by aligning the code; the echo, the auto-duty change and the SFX layout were read by hand. No independent driver model.

## Files

`MetalMasters_SoundDriver.asm`; tools and verification as listed in `Asterix_SoundDriver.md`. Regenerate: `python tools/gen_v3.py metalmasters "Metal Masters (U).gb" MetalMasters_SoundDriver.asm`.
