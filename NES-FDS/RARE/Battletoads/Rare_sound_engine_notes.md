# Rare NES sound engine: Battletoads and Battletoads & Double Dragon

Labeled ca65 disassemblies of the sound engine in two Rare games, plus notes on how the engine works. Both disassemblies reassemble to the original ROM bytes.

| Game | ROM | Sound code and data | Songs | SFX | Patterns |
|---|---|---|---|---|---|
| Battletoads (E) | AxROM, 8 x 32 KB, PRG bank 3 | `$851F-$CCCF` (18,353 bytes) | 21 ($00-$14) | 85 (ids $00-$A8) | 229 |
| Battletoads & Double Dragon (E) | AxROM, 8 x 32 KB, PRG bank 3 | `$8952-$B360` and `$C05E-$CFDF` (`$B361-$C05D` is game code) | 24 ($00-$17) | 127 (ids $00-$FC) | 193 |

The music is by David Wise. The BT&DD driver is a later revision of the Battletoads driver (see "Differences" below).

## Files

```
RARE\disasm\
  bt_sound.asm, bt_sound.cfg     Battletoads, bank 3 $851F-$CCCF
  dd_sound.asm, dd_sound.cfg     BT&DD, bank 3 $8952-$B360 + $C05E-$CFDF
  tool\gen_disasm.py             generator (python gen_disasm.py <bt|dd> <rom> <out.asm>)
  tool\games.py                  per-game labels, comments, RAM names, table locations
  tool\rareparse.py              track/SFX parsers (follow jumps, calls and repeat-calls)
  tool\m6502.py                  opcode table
  tool\build_and_verify.py       assemble with ca65/ld65 and compare with the ROMs
  tool\pcm_render.py             runs the PCM generators in py65 and writes WAVs
  tool\nesemu.py                 minimal AxROM harness (py65) used for tracing
  pcm_renders\*.wav, *.csv, pcm_waveforms.png
```

To rebuild and check, run `python tool\build_and_verify.py [--regen] <folder with the two .nes files> <disasm folder>` from the `disasm` folder. It needs cc65 (ca65/ld65) on PATH. `--regen` reruns the generator first, which is plain Python 3. `pcm_render.py` and `nesemu.py` need `pip install py65`.

How the data is shown in the listings:
- Tracks are parsed by following the data like the engine does (jumps, both call types, repeat-calls, fixed-duration and note-volume state). Notes use `N_C2`...`N_B6` (`$81`-`$BC`), `REST` (`$80`), and `NZ+n` for noise-channel notes.
- Commands are `CMD_*` constants. Jump, call and repeat-call targets get labels: `SongNN_Sq1/Sq2/Tri/Noise`, `Pat_xxxx` (call targets), `Lp_xxxx` (jump targets). Songs that share tracks get alias labels.
- Bytes the engine never reads are labelled `Unref_xxxx` with a comment.
- Where code and data overlap, the label is defined as an offset at the end of the file (for example `PcmStartIdx = PcmDisp_Tone+2`).

## Interface

Both games use a bank-0 far-call stub at `$FFCB`: X = offset into the target bank's jump table at `$8000` (`jmp ($0013)` with `$14` = `$80`), Y = bank (plus nametable bit 4). The sound bank's entries:

| X | Battletoads | BT&DD | Inputs |
|---|---|---|---|
| $03 | `Music_Init` $87F8 | `Music_Init` $8C54 | song number in `$32` (BT) / `$39` (DD) |
| $06 | `Music_Update` $884F | `Music_Update` $8CC6 | once per frame |
| $09 | `Pcm_PlayFullVol` $851F | $8952 (also X=$27/$3F/$42) | game PCM effect, parameters already in zero page |
| $0C/$0F/$12/$15 | `Sfx_PlaySq1/Sq2/Tri/Noise` | same | effect id in `$39` (BT) / `$3F` (DD) |
| $18, $1B | `Pcm_Play` $852B | $895E | plays a pending PCM request from the music |

Each frame the NMI calls `$FF84` (present in every bank). It switches to bank 3 and runs `jsr $8006`, which is the jump-table entry for `Music_Update`. In BT&DD the value passed in A is kept in `UpdateMode` (`$44`); `$10` means the in-level raster mode (see below).

## Driver

### Timing
- `Tempo` is added to `TempoAcc` every frame. A carry is a tick, so ticks per second = 60 x tempo / 256. Battletoads tempos are $62-$DC (23-52 ticks/s). BT&DD tempos are $40-$A6, and bit 0 of the table byte has another meaning (LagMode, below).
- The update loops over the four channels (X = 0, 4, 8, 12 = Sq1, Sq2, Triangle, Noise). Every per-channel variable is a `$03x1-$03x4` array with stride 4.
- On a tick frame a channel decrements its duration counter. When it reaches 0 the channel reads events until it finds a note. On non-tick frames the channel runs its effects (pitch slide, vibrato, volume envelope) and writes the APU. A frame that ticks without reaching a new note runs no effects for that channel.
- `$4003`-type writes are skipped when the value hasn't changed, except at note-on, so long notes don't restart the pulse phase.

### Notes
- `$80` = rest (period 0). `$81`-`$BC` = C2-B6, plus the channel transpose, looked up in `PeriodTbl`. The period table is identical in both games: 61 words, NTSC, with the triangle sounding an octave lower.
- Noise channel: the period register gets `(note*2 - $82)/2`. In effect that is `(note - 1) AND 15` with the transpose included, and short (looped) mode is never set. Battletoads writes noise notes in both the `$81` and `$C1` ranges. BT&DD only uses `$C0`-`$CF` (shown as `NZ-1`...`NZ+14`).
- A note is followed by an optional volume byte (Battletoads note-volume mode) and a duration byte, unless a fixed duration is set.
- The duration byte counts ticks. 0 means 256.

### Track commands, Battletoads (`$00`-`$26`, table `CmdTbl` $8B65)

| Op | Name | Params | Effect |
|---|---|---|---|
| 00 | END | - | channel off, silence it |
| 01 | JUMP | addr | |
| 02 | SFX_CLRFLAG | - | SFX only: clear bit 0 of `SfxId` (see SFX) |
| 03 | INSTR | reg0, sweep, reg3 | duty/flags + volume (low 5 bits), sweep, length bits |
| 04 | HOLD | - | SFX only: keep the current step for one more step |
| 05 | REPEAT_END | - | end of a repeat-called block: repeat it or return |
| 06 | FIXDUR | n | all following notes last n ticks, with no duration byte |
| 07 | FIXDUR_OFF | - | |
| 08 | VIBRATO | width, speed, depth | triangle vibrato: every speed+1 frames add depth to the period; the direction reverses every width steps (starting from the middle) |
| 09 | VIBRATO_OFF | - | |
| 0A | SLIDE_UP | delay, speed, count, step, rev | after delay frames, count steps of `step` every speed+1 frames, the first `rev` steps in reverse |
| 0B | SLIDE_DOWN | same | same with a positive step (period up) |
| 0C | VOLUME | v | constant volume v, envelope off |
| 0D | VOL_ENV | delay, speed, target | ramp the volume to target, one step every speed+1 frames, after delay frames |
| 0E | TREMOLO | period, speed, delta | add delta to the volume every speed+1 frames, reversing every `period` steps (first after period/2) |
| 0F | VOL_ENV_OFF | - | |
| 10 / 11 | TEMPO / TEMPO_ADD | n | global tempo |
| 12 / 13 | TRANSPOSE / TRANSPOSE_ADD | n | this channel |
| 14 | TRANSPOSE_ALL | n | all four channels |
| 15 | ATTACK_OFF | - | |
| 16 | ATTACK_ENV | delay, speed, target | each note restarts at the current volume and runs VOL_ENV (a decay envelope) |
| 17 | VIBRATO_DLY | width, speed, depth, delay | VIBRATO with the first step delayed (the delay is applied once, not per note) |
| 18 | PCM_TONE | rate | request PCM generator 1 |
| 19 | PCM_NOISE | rate | generator 2 |
| 1A | PCM_WAVE_A | rate | generator 3 |
| 1B | PCM_WAVE_B | rate | generator 4 |
| 1C | PCM_SETUP | flip, limit, vol | `PcmFlipRate`, `PcmSegLimit`, output volume 0-3 |
| 1D | PCM_WAVE_C | rate | generator 5 |
| 1E | REPEAT_CALL | count, addr | call addr count times (one level per channel, no nesting) |
| 1F | ECHO | xor, vol | each note alternates between vol and vol XOR xor. If xor has bit 7 set, note-volume mode instead |
| 20 | ECHO_OFF | - | also ends note-volume mode |
| 21 | FIXDUR_ECHO_OFF | - | FIXDUR_OFF + ECHO_OFF |
| 22 | NOTEVOL_ON | - | each note carries a volume byte |
| 23 / 24 | CALL_A / CALL_B | addr | subroutine call; the return addresses are two global slots (`$03A4/$03A8`, `$03AC/$03B0`) shared by all channels |
| 25 / 26 | RET_A / RET_B | - | |

A new event (on a tick) cancels any pitch slide, so slide commands go immediately before the note they bend. Several effect parameters are stored +1 (speed, delay), as listed in the code.

### Track commands, BT&DD (`$00`-`$53`, table `CmdTbl` $902D)

`$00`-`$1D` are the same as in Battletoads, except:

| Op | Name | Params | Effect |
|---|---|---|---|
| 0C | (VOLUME) | - | broken leftover: computes `(op - $34) OR $10` from the opcode itself; unused |
| 0D | ENV_PRESET | n | volume ramp from preset n (`EnvPresetDelay/Speed/Target`); unused |
| 16 | ATTACK_PRESET | n | attack envelope from preset n; unused (the one-byte forms below are used) |
| 1E | REPEAT_CALL | count, addr | now nestable: outer levels are pushed onto `LoopStack` ($0600, 15 bytes per channel) |
| 1F | CALL | addr | per-channel call. The return address is stored in `ChEchoVol/ChEchoXor` ($03A4/$03A3), so echo is off during a call. Echo commands inside called patterns would corrupt the return; the data never does this |
| 20 | RET | - | |
| 21 | ECHO | a, b | notes alternate between volume b and volume a (stored as `a EOR b`) |
| 22 | ECHO_OFF | - | |
| 23 | FIXDUR_ECHO_OFF | - | |
| 24 | ECHO_TOGGLE | - | switch echo on/off without new parameters (99 uses) |
| 25-33 | ATTACK_P+n | - | attack envelope preset n (0-14) in one byte (419 uses) |
| 34-43 | VOL+n | - | constant volume n in one byte (340 uses) |
| 44-4C | HWLEN+n | - | reg0 = $1F, sweep $43, reg3 from `HwLenTbl`: notes are cut by the APU length counter |
| 4D-53 | HWLEN+n | reg0 | same with an explicit reg0 byte (entry $53 reads past the 15-byte table into code) |

Note-volume mode (Battletoads `$22`) was removed. `$03A2` is now the REPEAT_CALL depth.

### Sound effects

`SfxTbl` is indexed by id/2. Sfx_Play* take an id whose bit 0 is a flag. The pointer table ignores that bit, but the "same effect already playing?" check compares the full id. So:
- An even id is never restarted while it plays.
- An odd id can't be restarted until the effect reaches a `$02` (SFX_CLRFLAG) step, which clears bit 0.

Format: a 3-byte header (`reg0 high nibble | frames per step - 1`, sweep, reg3), then 2-byte steps (`volume << 4 | period bits 8-10`, `period bits 0-7`). `$04` holds a step and `$00` ends the effect. While an effect plays it owns the channel. At the end it either silences the channel or rewrites the music's registers.

- Battletoads: the request is stored and set up on the next update (`SfxReg1 = $55` marks this). Effects `$7A/$7B` can't be interrupted.
- BT&DD: the header is read immediately, using `$1D/$1E` saved on the stack. There are no protected ids.

## The "digital" (PCM) drums and effects

Neither game contains sample data. Every PCM sound is generated in real time by a small CPU routine and written to `$4011` (DMC direct load) in a timed busy loop. All the data is in a few short tables. The tables and the generators are byte-identical between the two games.

### Triggering
- From music: a `PCM_*` command stores `PcmRequest = $80 | id` and `PcmDelay = rate`. The track keeps running; the sound plays later outside the music update.
  - **Battletoads:** the game logic runs in the NMI and the main thread is an idle loop (bank 0 `$870B`). At the end of the NMI work in non-level modes (`$10` negative, e.g. the title), a pending request makes the handler:
    1. drop its return frame (`pla/pla`),
    2. re-enable NMI and call `Pcm_Play` (bank 0 `$E572`),
    3. jump back into the idle loop.

    The next NMIs interrupt the PCM loop and keep the music and game running, at the cost of gaps in the sample stream. A second caller, bank 0 `$8415`, plays requests while waiting for a song to finish.
  - **BT&DD:** the NMI path at bank 0 `$FEB2` arms the raster split (`SplitMask`/`SplitWait = 64`) and, if a request is pending, starts it the same way (bank 0 `$D1D8`).
- From game code (punches, smashes): the Battletoads sound queue (bank 0 `$84AB`, `$DC` = index into 4-byte rows at `$84FF`) plays a row immediately from the game logic.
  - If byte 0 is nonzero, the row is a PCM effect: request, rate, flip rate, segment limit. It is played through X=$09 at full volume. These rows use rate 1 (~18 kHz).
  - Otherwise the row is an ordinary sound effect: (unused, SFX entry X, SFX id, unused).
  - BT&DD uses the same scheme (PCM branch at bank 0 `$84B7`, rows around `$84DC`) and lowers the segment limit on level 5.
- `PcmSegLimit` caps the number of table entries read (n-1 segments; 0 = 255). Volume 0-3 picks an entry point into `PcmOut` that does 3, 2, 1 or 0 right shifts before `sta $4011`. The volume is set to 3 at every `Music_Init`.

### The output routine
`PcmOut_Vol0..3` ($855D BT / $8990 DD): optional `lsr`s, `sta $4011`, `ldx PcmDelay / dex / bne` (5 cycles per count), `inc Rng3`. Including the generator's own work, a sample takes about **100 + 5 x rate** CPU cycles. That is ~17-18 kHz at rate 1-2, ~10 kHz at rate $11 and ~8.6 kHz at rate $16. The BT&DD versions are 3-6% slower because of the extra raster-split check.

### Generator 1: tone (kick/tom), `PcmGen_Tone`
1. 84 samples of `Random AND 15 + $3C` (a click).
2. A second-order oscillator. Each sample, `PcmLevel += PcmVel` (8.8). For the first `len` samples of a segment, `PcmVel += PcmAccel`.
3. A new segment is read from `PcmToneTbl` each time the level crosses a multiple of 64. Entries alternate the sign of the acceleration, so the output is made of parabolic arcs: a sine-like wave. Its period lengthens and its amplitude changes along the table, giving a falling-pitch drum.
4. Table entry: byte 0 = `accel bit 0 << 7 | len`, byte 1 = sign-magnitude acceleration bits 1-7. The value added is `+/-((b1 & $7F)*2 + b0.7)*4`.
5. `PcmFlipRate` is added to an accumulator per segment. Each carry increments `PcmMask`, which is XORed into the output to dirty the tone (music uses $00 or $1E; game hits use $30-$C0).

### Generator 2: noise (snare/crash), `PcmGen_Noise`
Each table entry is (amplitude, decay, samples). Each sample: `Random AND (smallest 2^k-1 >= amp)`, reduced mod amp, plus `(127 - amp)/2` so it stays centred. Then `amp:frac -= decay` (8.8). 11 entries.

### Generators 3-5: ramp-segment waves, `PcmGen_Wave`
The level moves in straight lines, with each segment going the opposite direction from the previous one. Each sample also XORs in `Random AND noisemask`. Table bytes:
- `len | slope`. Id 3 uses 5-bit len and 3-bit slope; ids 4/5 use 4/4.
- `$00, m` sets the noise mask.
- `$00, $00` ends the sound.

The three ids share one table through a start-index table that overlaps code: `PcmStartIdx` = the operand byte of a `jmp` (id 0, unused), then `$00,$00,$00,$44` (ids 1-4), and id 5 reads the `clc` opcode (`$18`) of the next routine. So:
- id 3 starts at offset 0 with 5-bit lengths.
- id 5 starts inside id 3's data at $18 with 4-bit lengths, so the same bytes give a different sound.
- id 4 has its own data at $44.

`PcmGen_Wave` has a leftover `inx` in its sample loop.

### Cost
Each sound monopolises the CPU for roughly 12-230 ms (1-14 frames). In Battletoads the music's PCM drums appear only in songs `$10` and `$14`. Song `$10` (tempo $DC) is the first music after the intro screens in an emulator run, most likely the title theme. The game's own PCM effects are short and fast (12-110 ms at rate 1).
- **BT&DD** handles this better. The output routine calls `Pcm_SplitPoll`: after 64 samples it polls `$2002 AND SplitMask` (sprite-0 hit) and performs the game's status-bar split (`PPU_CTRL = $80`) at the right moment. When the sound ends, `Pcm_Exit` keeps polling until the split has happened before returning. PCM drums are used in songs `$02/$03`, `$08` (started at the title stage in an emulator run) and `$09`.

### Renders
`pcm_renders\` has WAVs from `pcm_render.py`, which runs the real ROM code in py65 and timestamps every `$4011` write at the CPU clock. They cover the parameter sets used by the songs and the Battletoads in-game rows. `bt_pcm_stats.csv` lists the sample counts, durations and average sample rates. `pcm_waveforms.png` shows the shapes: the sine-like tone, the decaying noise and the triangle-ish waves.

## Battletoads to BT&DD differences
- **Zero page moved.** Most driver variables moved up by 6-7 bytes (`$32`->`$39`, `$37`->`$3D`, `$40`->`$46` ...). The `$03xx` arrays are unchanged.
- **Raster-safe update.** With `UpdateMode = $10`, `Music_Update` loads `RasterBudget` from a per-level table (indexed `level-2`, so levels 0/1 would read code bytes). `ExecCommand` subtracts 3 per command. The remainder is burned in `DelayYX` so the update takes constant time and doesn't disturb mid-frame raster effects.
- **LagMode.** Tempo bit 0 = 1 makes Square 2 and Noise tick one frame after Square 1 and Triangle, for a slap-back/flam feel. Only song `$16` uses it (tempo $51). It is only safe with tempos below $80, because otherwise an even-channel tick on the lag frame would be lost.
- **Commands.** Nestable REPEAT_CALL; per-channel CALL/RET instead of the two global slots; one-byte volume, attack-preset and hardware-length commands; ECHO_TOGGLE; note-volume mode removed.
- **SFX.** Started immediately instead of on the next update; no protected ids.
- **PCM.** The output routine performs the sprite-0 split, and the exit waits for it.
- Data: 127 sound effects, 24 songs (several aliases: $03=$02, $05=$00, $0B=$0A, $0D=$07, $11/$15/$17 reuse tracks). Only 3 Battletoads effects are byte-identical in BT&DD.

## Quirks
- Battletoads, song `$0E`, pattern `Pat_971C`: a stray `$02` (SFX_CLRFLAG) in music data. It is harmless because `Cmd_SfxClrFlag` continues in the SFX reader, which sees the next byte (`$06` FIXDUR) as a command below `$10` and dispatches it back into the music command table.
- The SFX reader can dispatch any of `$01-$0F` through the music table, but only `$02` and `$04` return to the SFX reader.
- A music `$04` would write the SFX pointer. It is never used in songs.
- `PcmStartIdx` and BT&DD's `RasterBudgetTbl-2` / `HwLenTbl` entry 15 read code bytes as data.
- BT&DD has game code embedded in the music data at `$C67D-$C6CC` (jump-table entry X=$2D) and a pointer at X=$24 that targets `CmdTbl` (data).
- Unreferenced data:
  - Battletoads: a duplicate terminator after `PcmToneTbl`, one byte at `$CB23`, and one at `$CCCF`.
  - BT&DD: an orphaned sound effect at `$9798` and orphaned track fragments at `$A08B`, `$C245`, `$C7E3` and `$CED8`.

## RAM (Battletoads; BT&DD in parentheses where different)

| Address | Name | Use |
|---|---|---|
| $25-$28 ($2C-$2F) | Rng0-3 | PRNG, `Rng3` bumped each PCM sample |
| $32 ($39) | TempoAcc | also the song number input |
| $33 ($3A) | Tempo | |
| $34 ($3B) | TickFlag | bit 7 = tick |
| ($3C) | LagMode | BT&DD only |
| $37/$38 ($3D/$3E) | DataPtr | |
| $3F ($45) | PcmDelay | |
| $40 ($46) | PcmRequest | `$80 | id` |
| $41-$50 ($47-$56) | Pcm* | generator state (see the listing) |
| ($57/$59) | SplitMask/SplitWait | BT&DD raster split during PCM |
| ($FA) | RasterBudget | BT&DD |
| $0301-$0304 | ChActive, ChDurCnt, ChPtrLo/Hi | |
| $0311-$0314 | SfxId, SfxTimer, SfxPtrLo/Hi | |
| $0321-$0324 | ChReg0, ChReg1, ChPerLo, ChPerHi | APU shadows |
| $0331-$0334 | SfxReg0-3 | |
| $0341-$0344 | ChRepPtrLo/Hi, ChRepCount, ChVibDelta | |
| $0351-$0354 | ChFixDur, ChVolume, ChEnvDelay, ChTranspose | |
| $0361-$0364 | ChVibWidth, ChVibCount, ChVibSpeed, ChVibTimer | |
| $0371, $0373, $0374 | ChAttack, ChEnvTimer, ChSlideTimer | |
| $0381-$0384 | ChSlideCount, ChSlideDelay, ChSlideStep, ChSlideRev | |
| $0391-$0394 | ChEnvTarget, ChEnvCount, ChEnvMode, ChEnvSpeed | |
| $03A1-$03A4 | ChSlideSpeed, ChVolMode (DD: ChLoopDepth), ChEchoVol (DD: ChEchoXor), ChRetSlot (DD: ChEchoVol) | |
| ($0600-$063B) | LoopStack | BT&DD REPEAT_CALL nesting |
