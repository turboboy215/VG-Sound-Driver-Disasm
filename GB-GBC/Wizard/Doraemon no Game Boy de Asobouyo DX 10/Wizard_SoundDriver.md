# Wizard Sound Driver — Doraemon DX 10 (J), Doraemon no Quiz Boy (J)

Disassembly and documentation of the sound driver in two Wizard Game Boy games. Everything here comes from the code. The format was checked by running every sound id through the reassembled driver in PyBoy and comparing all driver RAM and the readable sound registers, after every update call, against a Python model written from this document (§11).

| Game | ROM | Mapper | Driver | Driver + sound data | Instrument block |
|---|---|---|---|---|---|
| Doraemon DX 10 (J) [S] | 256 KB | MBC1 | **v1** | bank $04, $4000–$7D31 (15,666 bytes); then $FF padding | bank 0, $2846–$3045 (2,048 bytes) |
| Doraemon no Quiz Boy (J) (V1.0) [C][!] | 1 MB | MBC5 | **v2** | bank $04, $4000–$7C19 (15,386 bytes); then $FF padding | bank 0, $3270–$3A6F (2,048 bytes) |

## Summary

- **Same engine in both games.** The code is identical except for `Sound_Play` (6 bytes longer in Quiz Boy, §9). Everything after it moves by 6 bytes; RAM moves from $C6C6 to $C963.
- The bank-0 instrument block (pitch envelopes, volume envelopes, waves) is **byte-identical** apart from its pointer tables. 45 track bodies are identical between the two games; the rest of the music differs.
- **8 track structs**: 0–3 play music on ch1–ch4, 4–7 play SFX on ch1–ch4. A running SFX struct mutes the music struct of its channel; the music keeps ticking.
- **No tempo.** One row tick per `Sound_Update` call; the games call it once per frame, so lengths are in frames (1–192 in the data).
- Rows are **note + length** (2 bytes). Notes are indices into a 120-entry period table ($18 = C2; MIDI number = note + 12). On music ch4 the note byte is the NR43 value. $7E = tie, $7F = rest. Commands are $80–$93.
- Instruments are **software envelopes**: a volume envelope (a level per frame, scaled through a 16×16 volume table) and a pitch envelope (a signed period step added every frame). Square channels with a volume envelope are **retriggered every frame**.
- One table holds both music and SFX: each header has a struct mask. Bits 0–3 = music (replaces everything that runs, SFX included), bits 4–7 = SFX (added).
- Not used by either game: `Sound_Pause`/`Resume`, `Sound_SetVolOffset`, `Sound_StopExcept`, commands $86/$87 (call/return), $8A/$8B (pan left/right), $8D–$8F, $93 and the $7D prefix.

---

## 1. Interface

There is no jump table; the routines start at fixed addresses in bank 4.

| DX 10 | Quiz Boy | Label | Use |
|---|---|---|---|
| $4000 | $4000 | `Sound_Pause` | wSndPause = 1 (unused) |
| $4008 | $4008 | `Sound_Resume` | wSndPause = 0 (unused) |
| $400F | $400F | `Sound_Init` | boot |
| $4054 | $4054 | `Sound_FadeOut` | a = frames per fade step |
| $4061 | $4061 | `Sound_SetVolOffset` | a = value, b = struct mask (unused) |
| $4077 | $4077 | `Sound_StopAll` | |
| $4078 | $4078 | `Sound_StopExcept` | a = struct mask to keep (unused; StopAll falls into it with a = 0) |
| $40B0 | $40B0 | `Sound_Play` | c = sound id |
| $4136 | $413C | `Sound_Update` | once per frame |

**Call sites.**
- DX 10: Init at $01AF and Update at $0BCE, both through inline bank switches. Everything else goes through the game's far-call routine at $2442 (`call $2442` followed by `dw address, db bank`): `Sound_Play` 38 times (plus a wrapper at $2430 used about 170 times), `Sound_StopAll` 20 times, `Sound_FadeOut` once (bank 8). A second wrapper at $2437 waits until no SFX struct is running (`wSndActive & $F0`).
- Quiz Boy: Init at $01A3, Update at $0887 (in the per-frame joypad/main routine). Far-call routine at $268D: `Sound_Play` 125 times, `Sound_StopAll` 32 times.

**`Sound_Init`**: NR52 = $80, NR51 = 0, NR50 = wSndMasterVol = $77, NR30 |= $80 (the ch3 DAC stays on from here), wSndActive = 0, TRK_FLAGS of all 8 structs = 0, wSndPan = $11,$22,$44,$88,$11,$22,$44,$88.

**`Sound_Play`** (c = id):
1. reads the header at `Snd_SoundTable[c]`: a struct mask, then one track pointer per set bit (bit 0 first); stores the mask in `wSndLastMask`;
2. **v1**: if mask bit 7 (SFX on ch4) is clear, NR51 = 0. **v2**: if the mask has no SFX bit, returns at once when the game variable `[$C3F8]` ≠ 0, else NR51 = 0;
3. `Snd_InitTrack` on every struct in the mask: TRK_PTR = track, length = gate = 1, volume, duty and bytes 7–8 = 0, TRK_FLAGS = 6, loop stack empty, both envelopes off. `TRK_VOLOFS` and the pan byte are kept;
4. if the mask has an SFX bit, `wSndActive |= mask`; otherwise `wSndActive = mask` (music cancels all SFX).

There are no priorities: a new SFX on a channel simply restarts that struct.

**`Sound_StopAll` / `Sound_StopExcept`** (a = keep mask): `wSndActive &= a`; for each hardware channel whose music bit or SFX bit is not kept, NR51 loses that channel (an NR52 AND is also written, which does nothing). Then the fade stops and NR50 = wSndMasterVol = $77. Nothing else is cleared.

**`Sound_FadeOut`** (a): wSndFadeRate = a, wSndFadeOn = 1, counter 0. Every *a* frames both NR50 volumes drop by 1 (the VIN bits are kept) until they reach 0. The fade never ends by itself: NR50 stays 0 until `Sound_StopAll`.

**`Sound_Pause`**: while wSndPause ≠ 0, music structs neither tick nor write registers. Nothing is silenced; the channels keep their last register state.

**`Sound_SetVolOffset`** (a, b): TRK_VOLOFS = a for each struct whose bit is set in b. The offset is added to the channel volume (§6). Nothing clears it, and neither game calls this, so it is always 0.

## 2. RAM

| DX 10 | Quiz Boy | Name | Use |
|---|---|---|---|
| $C6C6 | $C963 | `wSndPause` | ≠ 0: music paused |
| $C6C7 | $C964 | `wSndPan` | 8 bytes: NR51 bits per struct |
| $C6CF | $C96C | `wSndMasterVol` | NR50 copy (fade) |
| $C6D0 | $C96D | `wSndFadeOn` | 1 = fading |
| $C6D1 | $C96E | `wSndFadeRate` | frames per step |
| $C6D2 | $C96F | `wSndFadeCount` | frame counter |
| $C6D3 | $C970 | — | 2 bytes, not used |
| $C6D5 | $C972 | `wSndChIdx` | struct being ticked (0–7; 8 after the tick loop) |
| $C6D6 | $C973 | `wSndLastMask` | mask of the last sound started |
| $C6D7 | $C974 | `wSndNote` | note byte being read |
| $C6D8 | $C975 | `wSndRawFlag` | compared with $7D; never written by the driver (§8) |
| $C6D9 | $C976 | `wSndActive` | bit n = struct n running |
| $C6DA | $C977 | `wSndTracks` | 8 structs of $22 bytes |

**Track struct:**

| Offset | Name | Meaning |
|---|---|---|
| $00 | `TRK_PTR` | next row |
| $02 | `TRK_LENGTH` | frames left in the row (word; high byte always 0) |
| $04 | `TRK_GATE` | frames until release (word; high byte always 0) |
| $06 | `TRK_VOLUME` | high nibble = channel volume (`$81`); low nibble never set |
| $07, $08 | — | cleared at start, never used |
| $09 | `TRK_DUTY` | NRx1 value (`$90`–`$93`) |
| $0A | `TRK_FLAGS` | bit 0 note sounding, bit 3 release pending; bits 1 and 2 are set (at start / at key-on) but never read |
| $0B | `TRK_PERIOD` | period; music ch4: NR43 value (high byte 0) |
| $0D | `TRK_SP` | loop stack pointer (absolute address) |
| $0F | `TRK_STACK` | 4 loop entries of 3 bytes (count, pointer) |
| $18 | `TRK_RETURN` | `$86`/`$87` return pointer — the same bytes as the 4th loop entry |
| $1B / $1C | `TRK_VOLENVPOS` / `TRK_VOLENV` | volume envelope position / pointer (0 = none) |
| $1E / $1F | `TRK_PITCHPOS` / `TRK_PITCHENV` | pitch envelope position / pointer (0 = none) |
| $21 | `TRK_VOLOFS` | volume offset (`Sound_SetVolOffset`) |

Only the high byte of an envelope pointer is tested, so a pointer of $00xx counts as "none" (the data has none).

## 3. Timing

**`Sound_Update`:**
1. Fade step if `wSndFadeOn` = 1 (§1).
2. **Tick pass**: for each struct 0–7 whose bit was set in `wSndActive` at the start of the pass, unless it is a music struct and `wSndPause` bit 0 is set, run `Snd_TickTrack`.
3. **Output pass**: for each struct 0–7, run `Snd_OutputChannel` (§7) with the *current* `wSndActive` (so a struct that ended in this tick no longer writes).

**One tick (`Snd_TickTrack`):**
- If `TRK_GATE` ≠ 0, it is decremented. If it reaches 0, the note is **released**: flags bit 0 cleared, bit 3 set, both envelope positions back to 0. Otherwise both envelope positions advance by 1.
- If `TRK_LENGTH` is 0, a row is read at once. Otherwise it is decremented, and a row is read when it reaches 0.

A row of length *L* therefore lasts *L* frames. The gate is also *L*, so a note is normally released in the same tick that reads the next row (the release is cancelled by that row's key-on, §5). Length 0 behaves as 1 frame with no release; the data never uses it.

## 4. Track format

Rows are read until a note, tie or rest:

| Bytes | Meaning |
|---|---|
| `nn LL` ($00–$7C) | note *nn* for *LL* frames |
| `$7E LL` | **tie**: keep the current note for *LL* frames |
| `$7F LL` | **rest** for *LL* frames |
| `$7D nn LL` | the byte after $7D is used as the note (§8); not in the data |
| $80–$93 | command (below) |

**Notes.** `TRK_PERIOD = Snd_FreqTable[note]`. The table has 120 entries; $00–$17 are period 0, $18 = C2 (period $002C) up to $77 = B9. The naming used in the .asm is `C_2` = $18, `C_4` = $30; MIDI number = note + 12. On ch3 the same period sounds an octave lower.

- **Music ch4 (struct 3)**: the note byte itself is stored as the period, i.e. it is the NR43 value.
- **SFX ch4 (struct 7)**: the note goes through the period table like a tone, and the low byte ends up in NR43. The data relies on this (e.g. `F_1` = period 0 → NR43 = $00). The .asm adds the resulting NR43 value as a comment on these rows.

**Commands:**

| Cmd | Args | Effect |
|---|---|---|
| $80 | – | **end**: struct stops (its `wSndActive` bit cleared), not sounding, channel taken out of NR51 |
| $81 | v | volume: `TRK_VOLUME` high nibble = v (the low nibble is kept; the code uses `swap`, so v > 15 would leak into it) |
| $82 | n | loop start: push (n, next row). The body plays n times. 4 levels (nesting depth 2 in the data) |
| $83 | – | loop end: count − 1; jump back while ≠ 0, else pop |
| $84 | n | load wave n (§6) |
| $85 | ptr | jump |
| $86 | ptr | call (`TRK_RETURN` = next row). One level, and it shares bytes with the 4th loop entry. Not used |
| $87 | – | return. Not used |
| $88 | n | volume envelope n, from its start |
| $89 | n | pitch envelope n, from its start |
| $8A | – | pan left: `wSndPan[struct] = Snd_PanTable[struct] & $F0`. Not used |
| $8B | – | pan right: `& $0F`. Not used |
| $8C | – | pan centre: `Snd_PanTable[struct]` |
| $8D–$8F | – | no effect. Not used |
| $90–$93 | – | duty 0–3: `TRK_DUTY = (cmd & 3) << 6` ($93 not used) |

Bytes $94–$FF in command position would jump through the bytes after `Snd_CmdTable` (code); the data never has one. Commands are executed in the same tick as the row that follows them; `$80` stops the reading.

**How tracks end.** Music loops with `$85` (59 jumps in DX 10, 60 in Quiz Boy); many are followed by an `$80` that is never reached. SFX end with `$80`.

## 5. Notes, ties and rests

When a note row is read:
1. `TRK_PTR` = the byte after the length. That byte is also **peeked**: if it is $7E (a tie row follows), `TRK_GATE` = length + 1, so the note is not released at the row change. Otherwise `TRK_GATE` = length.
2. `TRK_LENGTH` = length.
3. **Tie** ($7E): nothing else. The envelopes continue from where they are.
4. **Rest** ($7F): not sounding, release pending.
5. **Note**: `TRK_PERIOD` from the note (§4), flags bit 0 (sounding) and bit 2 set.

Releasing a note means taking the channel out of NR51 at the next output pass (§7). The channel itself keeps running.

Because the peek only looks at the byte right after the length, a tie that follows a command (e.g. `$83` then $7E) does not extend the gate; the data doesn't do this.

## 6. Instruments

All three tables live in **bank 0** (DX 10 $2846/$2CEB/$2FEC, Quiz Boy $3270/$3715/$3A16), each followed by its data. The contents are identical in both games.

**Volume envelopes** (`$88 n`, 17 entries): one byte per frame, the envelope value 0–15. **$80** = hold (repeat the previous value), **$81** = restart. The output level is

`level = Snd_VolumeTable[vol][value]`, with `vol = (TRK_VOLUME >> 4) + TRK_VOLOFS`, clamped: $10–$EF → 15, $F0–$FF → 0.

`Snd_VolumeTable` is 16×16; row 15 is the identity, row 0 all zeros, so `$81` acts as a master scale for the envelope. Envelope values above 15 would read into the next row; the data has none.

**Pitch envelopes** (`$89 n`, 24 entries): one signed byte per frame, **added to `TRK_PERIOD`** (so the period drifts; a key-on resets it). **$80** = repeat the previous step, **$81** = restart. A list ending `xx, $80` is therefore a continuous slide (e.g. entry 2: −5 per frame). Most entries are delayed vibratos of ±1 steps; entries $0C–$16 are larger arpeggio-like jumps.

**Waves** (`$84 n`, 5 waves of 16 bytes). If ch3 is running (NR52), it is first taken out of NR51 and NR32 set to 0; the 16 bytes are copied to wave RAM; then NR32 = (NR32 & $9F) | $20 (100%). The next output pass writes the real NR32.

**Pan** (`$8A`–`$8C`): `Snd_PanTable` = $11,$22,$44,$88 per struct (both sides of its channel). Pan bytes are per struct and survive new sounds.

Used by the data — DX 10: volume envelopes 0,2,5–10,12,13,15; pitch envelopes 3,4,5,7,8,13,14,15; waves 0,2,3,4. Quiz Boy: volume envelopes 0,2,3,5–10,12–14; pitch envelopes 3,4,5,7,8,12–15; waves 2,3,4.

## 7. Output (`Snd_OutputChannel`)

Skipped if the struct isn't running; for a music struct, also if paused or if the SFX struct of the same channel is running. Register base = `Snd_NRx2Table[struct]` ($12/$17/$1C/$21).

**Note not sounding** (flags bit 0 clear): if a release is pending, clear it and remove the channel from NR51. Nothing else.

**Note sounding:**
1. **Pitch envelope** (if any): add the step to `TRK_PERIOD` and write NRx3/NRx4 without trigger (overwritten below in the same frame, §8).
2. **With a volume envelope**: NR51 |= pan; NRx2 = level << 4 (ch3: NR32 = `Snd_WaveVolTable[level]`: 0–3 mute, 4–7 25%, 8–11 50%, 12–15 100%); NRx1 = duty on ch1/ch2; release flag cleared; NRx3 = period low; NRx4 = period high **with trigger**. On ch3/ch4 the trigger is left out while NR52 says the channel is still on. So **ch1/ch2 are retriggered every frame** for as long as a note sounds; this is how the software envelope reaches the hardware (NRx2 always has envelope period 0).
3. **Without a volume envelope** (one-shot): flags bits 0 and 3 cleared, NRx1 = duty (ch1/ch2), NR51 |= pan, NRx2 = vol << 4 (ch3: wave volume table), NRx3, NRx4 with trigger. Because bit 0 is cleared, this happens once per key-on; the pitch envelope is applied only once. 5 DX 10 tracks and 1 Quiz Boy track play notes before their first `$88`.

## 8. SFX, bugs and quirks

**SFX.** The SFX struct uses the same format. While it runs, the music struct of that channel keeps ticking (rows, loops, envelope positions) but writes nothing. When the SFX reaches `$80`, its channel is taken out of NR51; from the next frame the music struct writes again if its note has a volume envelope (it is retriggered every frame anyway), otherwise from its next key-on.

- **Sound_Play clears NR51**: v1 for every sound unless it has an SFX on ch4, v2 for music only. A channel playing a one-shot note (no volume envelope) stays out of NR51 until its next key-on.
- **Music cancels SFX**: starting music sets `wSndActive` to its mask, so running SFX stop at once.
- **Pitch envelope bug**: for a negative step the code computes the new high byte but doesn't copy it to d, so the NRx4 written by the envelope gets the old high byte. Harmless: `TRK_PERIOD` is right, and the rest of the output pass rewrites NRx3/NRx4 from it in the same frame.
- **$7D prefix**: meant to give a raw period (`wSndRawFlag` = $7D → period = byte). The flag is read from RAM that nothing writes, so the branch is dead; `$7D nn LL` just plays note *nn*.
- **SFX ch4 notes** go through the period table (§4); only music ch4 is raw.
- `$86` stores its return pointer in the 4th loop entry.
- `Sound_StopAll`'s per-channel test keeps a channel only if both its music and SFX bits are kept, and its NR52 writes do nothing.
- The wave load forces NR32 to 100% until the next output pass.
- Unreferenced RAM writes: bytes 7–8 of each struct and flags bits 1–2 are written but never read.

## 9. v1 → v2 differences (DX 10 → Quiz Boy)

| | DX 10 (v1) | Quiz Boy (v2) |
|---|---|---|
| RAM | $C6C6–$C7E9 | $C963–$CA86 |
| `Sound_Play`: NR51 = 0 | unless the mask has bit 7 (SFX ch4) | for music only |
| `Sound_Play`: music lock | — | music ignored while `[$C3F8]` ≠ 0 (a game variable; the game clears it briefly to force a song at $1C2E) |
| Addresses after $40BB | — | +6 (`Sound_Update` $413C, `Snd_CmdTable` $4440, `Snd_FreqTable` $463A, `Snd_SoundTable` $4852) |
| Instrument block | $2846–$3045 | $3270–$3A6F (same content, rebased pointers) |

Everything else, including all tables, is identical.

## 10. Sound data

| | DX 10 | Quiz Boy |
|---|---|---|
| Sound ids | 69 ($00–$44): 39 music, 30 SFX (counting the placeholder as music) | 60 ($00–$3B): 50 music, 10 SFX (same) |
| Headers / tracks | 51 / 122 | 34 / 94 |
| Placeholder | ids $16, $19–$26 (15) share one 2-channel sound: C7 beeped 10 times | ids $16, $18–$27, $2F, $33–$3B (27) share the same sound |
| Other shared headers | $00/$10/$12/$13; $29/$33 | — |
| Envelopes / waves | 24 pitch, 17 volume, 5 waves | same |
| Unreferenced | 1 header (2 tracks, $77CF); 2 header-less SFX tracks ($7AB4, $7B62); unreachable `$80`s (some after a rest) behind 20 jumps | 14 headers ($7281–$7B33, music and SFX); 3 header-less SFX tracks ($795D, $7A0B, and $7ACD which only sets up and ends); unreachable bytes behind 2 jumps |

The header-less tracks at DX 10 $7AB4/$7B62 and Quiz Boy $795D/$7A0B are four copies of the same short noise SFX. Every byte of both regions is reached from a table or listed above as unreferenced.

## 11. Files

In `Research\Wizard\`:

| File | Contents |
|---|---|
| `DX10_sound.asm` | bank 4 $4000–$7D31 (driver v1, tables, all sounds) + bank 0 instrument block $2846–$3045 |
| `QuizBoy_sound.asm` | bank 4 $4000–$7C19 (driver v2 + sounds) + bank 0 $3270–$3A6F |
| `wizard_sound.inc` | sound registers, `TRK_*` offsets, flag bits, note constants (`C_2`…), data macros. WRAM names are in each .asm |
| `tools\wiz_gen.py` | generator (`python wiz_gen.py dx10 > ..\DX10_sound.asm`, `quiz`) |
| `tools\wiz_cfg.py`, `wiz_parse.py`, `wiz_names.py`, `sm83.py`, `trace.py` | addresses per game, data walker, routine names/comments, SM83 disassembler, code tracer |
| `tools\wiz_verify.py` | reassembles both files and compares them with the ROMs |
| `tools\wiz_model.py`, `test\wiz_pyboy_check.py`, `test\harness.asm`, `test\build.sh` | the Python model and the PyBoy test |

**Code** uses plain instructions with EQU names (no macros); every line ends with its ROM address. **Data** uses macros (allowed for sound data):

```
Snd05_Ch1:
    snd_volenv 7                                ; 6533
    snd_volume 12                               ; 6535
    snd_pitchenv 3                              ; 6537
    snd_duty 2                                  ; 6539
    note C_6, 8                                 ; 653A
    ...
    snd_loop 2                                  ; 6592
```

Row macros: `note NAME, frames`, `noise $NR43, frames` (music ch4), `tie frames`, `rest frames`, `rawnote`. Commands: `snd_end`, `snd_volume`, `snd_loop`/`snd_endloop`, `snd_wave`, `snd_jump`, `snd_call`/`snd_ret`, `snd_volenv`, `snd_pitchenv`, `snd_panleft`/`snd_panright`/`snd_pancentre`, `snd_nop`, `snd_duty`. Envelopes are `db` lists with `ENV_HOLD`/`ENV_LOOP`; pitch steps are signed decimals.

Labels: the `Sound_*` entry points are exported (`::`); `SndHdr_NN` (first id using the header), `SndNN_Ch1`–`Ch4` / `SndNN_Sfx1`–`Sfx4`, `SndHdr_Unref_xxxx`, `Unreached_xxxx`, local `.lxxxx` jump targets, `PitchEnvNN`/`VolEnvNN`/`WaveNN`.

**Byte-identical** with RGBDS 1.0.0 (`python wiz_verify.py`; set `RGBDS` to the tools folder if they aren't on PATH). The overlay passed to rgblink has both regions zeroed, so every checked byte comes from the .asm:

| File | Bytes checked | Mismatches |
|---|---|---|
| DX 10 | 17,714 | 0 |
| Quiz Boy | 17,434 | 0 |

**PyBoy test.** `harness.asm` links the reassembled driver into a small MBC1 ROM whose loop runs a mailbox command and calls `Sound_Update`; a hook after each call compares all driver RAM ($124 bytes) and NR11/NR21 duty, NR12, NR22, NR32 volume, NR42, NR43, NR50, NR51 and the NR52 ch3/ch4 bits with `wiz_model.py`.

| Run | Length |
|---|---|
| every sound id after StopAll | 3,000 updates (music) / 800 (SFX) |
| the first music id with each SFX on top | 900 updates |
| 6 music ids: pause/resume, volume offsets (negative and positive), an SFX, StopExcept, fade, StopAll | 1,600 updates |

| Game | Runs | Updates | Mismatches |
|---|---|---|---|
| DX 10 | 105 | 180,475 | 0 |
| Quiz Boy | 76 | 179,206 | 0 |

As a sanity check, turning the pitch envelopes off in the model (`NOPITCH = True`) gives 12,269 mismatching updates on DX 10.

Paths the data never reaches (`$86`/`$87`, `$8A`/`$8B`, `$8D`–`$8F`, `$93`, `$7D`, the unreferenced sounds) are modelled from the code but not exercised. To run: `pip install pyboy`, `test\build.sh` (or the same rgbasm/rgblink/rgbfix commands on Windows), then `python test\wiz_pyboy_check.py dx10` (or `quiz`).
