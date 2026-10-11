# Sanrio Carnival 2 (GB): sound driver

The sound driver of *Sanrio Carnival 2* (`Sanrio Carnival 2 (J).gb`, 64 KB). Code and data fill bank 1 `$6000–$7BE4`, followed by `$FF` fill. The region `$6000–$7FFF` rebuilds **byte-exact** with RGBDS 0.9.1 (`-Wall` clean) from the sources in `Nint1\Sanrio2`.

It is **not related to the Tanaka driver family** in code, data format or tables (see `Tanaka_Lineage_Metroid2_WarioLand_Sanrio2.md`, §3). The full disassembly confirms that: it is a different, self-contained design.

| Range | Content | File |
|---|---|---|
| `$6000–$69EE` | entry stubs, SFX interpreter, music players, commands, register output | `S2_Driver.inc` |
| `$69EF–$6AD8` | note frequency table, SFX pointer tables | `S2_Tables.inc` |
| `$6AD9–$6CFF` | SFX streams (+ zero fill) | `S2_Sfx.inc` |
| `$6D00–$6E31` | macro page: envelope / pitch / drum macros, drum table, waves, length tables; song table | `S2_Data.inc` |
| `$6E32–$7FFF` | music streams (`$7BE5–` `$FF` fill) | `S2_Songs.inc` |

```
Sanrio2\build_check.sh            # assemble, link over the ROM, compare
Sanrio2\harness\build.sh          # test ROM with the rebuilt bank
Sanrio2\harness\verify.py [F] [X] # play every song (F frames) and effect (X frames), check every read
python Sanrio2\gen_sanrio2.py <rom> Sanrio2      (stream parser: s2_streams.py)
```

---

## 1. Entry points and frame

| Address | | |
|---|---|---|
| `$6000` | `jp` init | called from home `$018D` |
| `$6003` | update | called once per frame from home `$00D3` |

Init clears `$DE00–$DE81`, silences the APU, then sets NR50 = `$77` and the music's NR51 = `$FF` (written the next frame).

**Shadow registers.** Nothing writes the sound registers directly while it runs. The players and effects fill shadow registers (`$DE64–$DE7F`) and set a dirty byte per channel: bit 7 = write all registers and trigger, other bits = frequency only. The end of the update writes them out (`$600D–$60BD`), plus NR50 / NR51 when `wShadowMaster` asks. NR51 = the music's bits | the effects' bits.

**Per frame:** effects; the music, unless an effect holds it (`wMusicHold`); a pending wave load; then the register flush.

| Variable | | |
|---|---|---|
| `wSongRequest` | `$DE00` | bit 7 clear = start song `$01–$0D` |
| `wSfxRequest1–4` | `$DE01–$DE04` | bit masks: bit 7 = effect 0 (the most important) … bit 0 = effect 7 |
| `wSfxPending1–4` | `$DE05–$DE08` | requests collected per slot |
| `wMusicHold` | `$DE09` | set / cleared by effects |

---

## 2. Music

### 2.1 Song table and streams

`SongTable` (`$6DB2`): 8 bytes per song, a stream pointer per channel (`$00xx` = channel unused). Entries `$00`, `$0E` and `$0F` are empty. Song `$0C` uses song `$04`'s ch4 stream. Song `$0D`'s ch1 is song `$01` without its intro: after its setup commands it jumps into `Song01_Ch1_Loop`.

Each channel plays one byte stream with jumps and subroutine calls. Every channel has its own return stack (`wChNStack`: a count, then return addresses); `gosub` doesn't check the depth.

| Byte | Macro | |
|---|---|---|
| `$00–$7F` | `note PITCH[, index, count]` | 0 = rest, 1 = C2 …; on ch4 the pitch is a drum number. When the repeat counter has run out, a packed byte follows: high nibble = length-table index, low nibble + 1 = how many notes (this one included) use that length |
| `$80 ptr` | `wave` | load a 16-byte wave (next frame) |
| `$81 v` | `master_vol` | NR50 |
| `$82 v` | `music_pan` | the music's NR51 bits |
| `$83`–`$87 v` | `sweep1`, `duty1`, `duty2`, `len3`, `len4` | NR10, NR11, NR21, NR31, NR41 |
| `$88–$8B lo` | `env ch, macro` | envelope macro of a channel (in the `$6Dxx` page) |
| `$8C–$8E lo` | `pitch ch, macro` | pitch macro (ch1–3) |
| `$8F ptr` | `lengths` | length table |
| `$93 ptr` | `jump` | |
| `$94–$97 ptr` | `gosub ch, ptr` | call, on that channel's return stack |
| `$98–$9B` | `endsub ch` | return |
| `$9C–$9F` | `endch ch` | the channel stops and is silenced |
| `$90–$92` | | no handler |

Uses across the 13 songs: 1,972 notes, 76 `gosub`, 53 `env`, 38 `jump`, 36 `pitch`, 20 `endsub`, 12 each of `wave`, `master_vol`, `music_pan`, `lengths`, `sweep1`, `len3`, 8 `endch`.

### 2.2 Macros and tables

- **Envelope macros** (`EnvMacro_*`): rows of (frames, NRx2), or (frames, NR32) on ch3. A note restarts its channel's envelope macro; a new non-zero value retriggers. A row of frames 0 jumps to another row in the page.
- **Pitch macro:** there is one, `PitchMacro_2C`. It waits 510 frames before it starts alternating, so it is never heard.
- **Drums:** `DrumTable` has two entries, each a macro of NR43 values. Songs `$06` and `$07` also use **drum 3**, which has no entry: the driver reads the first bytes of `DrumMacro1` as its pointer and runs a "macro" at `$5E01` in game data (NR43 = `$F4`). The play check counts these reads separately (76 and 702).
- **`NoteFreqTable`** (`$69EF`): 85 entries, C2–C9; the last two are both `$07F0`. Its values deviate from exact rounding in its own way, not in the Tanaka table's (lineage note §2.2).
- **Length tables:** 16 entries each, in their own order (`05 0A 14 28 50 00 78 3C 64 32 1E …`).

---

## 3. Sound effects

Four slots, highest priority first; **slot 4 has no effects**. Effects are byte-code streams (`S2_Sfx.inc`):

| Byte | Macro | |
|---|---|---|
| `$00–$3F` | `sfx_regs ch, mask, …` | register writes for one channel: mask bits 0–2 = NRx0–NRx2, bit 3 = NRx3 + NRx4. Skipped (with their operands) when a higher slot owns the channel |
| `$40–$5F` | `sfx_music` | hold / resume the music |
| `$60–$6F` | `sfx_end mask` | end; silence the channels in the mask that no higher slot owns |
| `$70–$7F` | `sfx_channels mask` | the channels this effect takes |
| `$80–$FF` | `sfx_wait n` | wait n frames (`$80` = 128) |

Requests collect in the slot's pending mask and the highest pending bit plays. A new request for it restarts it; otherwise the running effect continues. An effect's end clears every pending bit of its slot.

| Slot | Effects |
|---|---|
| 1 | 0–7 |
| 2 | 0–2 |
| 3 | 0–4 |
| 4 | none (all entries `Sfx_None`) |

---

## 4. Verification

- **Byte-exact rebuild** of `$6000–$7FFF`.
- **Emulator harness** (PyBoy; rebuilt bank, init then update once per frame). Every stream read is checked against the generator's parse: note/command fetches must land on a note or command byte, packed-length reads on a length byte, operand reads on an operand byte, SFX reads inside a parsed effect, macro reads in the `$6D00` page.

  | | Reads | Outside the parse |
  |---|---|---|
  | Songs `$00–$0F`, 3,600 frames each | 77,982 | 0 (plus the drum-3 reads into game data, §2.2) |
  | 16 effects, 240 frames each | 447 | 0 |

  Of the 3,507 parsed music bytes, 228 are never read by a hooked instruction. All of them are the 2-byte operands of `jump` / `gosub`, which the driver reads through `hl` rather than the hooked `ld a, [de]`.
- **Not verified:** song titles and effect contexts; hardware.
