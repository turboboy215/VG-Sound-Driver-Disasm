# Jaleco Game Boy sound engine — command reference

One sound engine, three revisions, reverse-engineered from:

| Game | Released | ROM | Bank | Driver code | Sequence data |
|---|---|---|---|---|---|
| Hero Shuugou!! Pinball Party (J) [!] | Jan 1990 | 64 KiB, MBC1 | `$2` | `$4000`–`$4DB4` | `$4DB5`–`$6E9D` |
| Avenging Spirit (UE) [!] | 1992 | 256 KiB, MBC1 | `$7` | `$4000`–`$4ABA` | `$4ABB`–`$7FFF` |
| Soldam (J) | 1992 | 128 KiB, MBC1 | `$7` | `$4000`–`$4ADE` | `$4ADF`–`$7FFF` |

All three disassemblies reassemble byte-for-byte with RGBDS (`rgbasm` +
`rgblink`), so everything below is checked against the actual code rather than
inferred.

Other titles reuse these command sets unchanged: Banishing Racer follows the
Avenging Spirit set, Lazlos' Leap (Solitaire in Japan) the Pinball Party set.
Soldam appears to be the last game to use the engine; no Game Boy Color title
does.

## Lineage

**Pinball Party (1990) is the oldest** and carries the earliest form of the
engine. **Avenging Spirit (1992)** carries the second revision, shared with
**Fortified Zone**, **Ikari no Yousai 2** and **Banishing Racer**. **Soldam
(1992)** carries the third and last, a small variation on Avenging Spirit's.

All three share a skeleton, a stream format, and a byte-for-byte identical note
table. What changed between 1990 and 1992:

* **The command set was renumbered wholesale.** Only `$0B` kept its id.
  Pinball Party leaves `$00` unused; the later revision compacted the numbering
  so `$00` became panning and everything from `$0C` up shifted by one. This is
  why a decoder written for one game produces garbage on the other.
* **Envelopes went from parametric to table-driven.** Pinball Party's
  `SCMD_SW_ENVELOPE` (start / step / rate / target) and `SCMD_TREMOLO`
  (delay / depth / rate) were dropped. The later revision replaced them with
  `SCMD_VOL_ENVELOPE` and `SCMD_PITCH_ENVELOPE`, which take a pointer to a table
  of `value, hold` pairs — less compact per use, but able to express shapes the
  parametric version cannot, such as multi-tap echoes and delayed vibrato.
* **Channel arbitration was simplified.** Pinball Party has twelve channel
  slots in three groups: music plus *two* independently prioritised SFX groups,
  so two effects can sound at once and a third displaces the lower-priority one.
  The later revision cut this to eight slots in two groups, one music and one
  SFX.
* **The sound-test program was dropped.** Pinball Party still ships a small
  in-bank test menu at `$6E9E`; the later revision has none.

So the engine did not simply grow — it traded runtime flexibility in the
channel allocator for expressive power in the envelope system.

**Soldam** then made two further changes to Avenging Spirit's driver and nothing
else; the two are 95 % identical instruction for instruction.

* **Nestable loops.** `$0C`/`$0D` stopped being "load counter slot *n*" and
  "jump to this address if slot *n* is non-zero" and became a `LOOP_START` /
  `LOOP_END` pair that records the loop address itself. `$0C` drops from two
  operands to one and `$0D` from three to none, which on its own is enough to
  desynchronise a parser written for Avenging Spirit.
* **A larger per-frame command budget**, 5 instead of 2 — the three extra
  `inc a` at `$4002` are why the rest of the bank sits three bytes higher than
  the equivalent Avenging Spirit code.

---

## 1. Architecture (common to both)

### Channel slots

The driver does not talk to the four hardware channels directly. It maintains a
set of **channel slots**, arranged in groups of four; slot *n* maps to hardware
channel `n & 3` (0 = pulse 1, 1 = pulse 2, 2 = wave, 3 = noise).

* **Pinball Party** — 12 slots: 0–3 = music, 4–7 = SFX group A, 8–11 = SFX group B.
* **Avenging Spirit** — 8 slots: 0–3 = music, 4–7 = sound effects.

In both games the music slots are 0–3 and the SFX slots sit above them, and in
both the SFX masks are applied so that an effect takes a hardware channel away
from the music, never the reverse.

Each group owns a pair of HRAM bitmasks (`…Mask` / `…MaskLatch`). When a group
claims a hardware channel it sets its bit; `Sound_UpdateChannels` walks the
groups in priority order and only the highest-priority claimant of each hardware
channel is actually written out. Pinball Party additionally arbitrates between
its two SFX groups by effect id (`Sound_ArbitrateGroups`).

### Song and SFX headers

Both games have two pointer tables of 16-bit addresses:

| | Pinball Party | Avenging Spirit |
|---|---|---|
| Music table | `$4DB5`, 13 songs | `$4ABB`, 20 songs |
| SFX table | `$4DCF`, 18 effects | `$4AE3`, 19 effects |

Each entry points at a **header of four 16-bit stream pointers**, one per
hardware channel, in order pulse 1, pulse 2, wave, noise. A pointer of `$0000`
means that channel is unused by this piece. Pinball Party's SFX path also reads
a flag byte at header + 8 (it is `$FF` in all 18 headers, so the branch it
guards is dead code).

### Stream format

A stream is a flat byte sequence of two kinds of item:

```
<note byte> <length byte>          ; a note or rest, always 2 bytes
$FF <command> <operands…>          ; a command, 2 + n bytes
```

`$FF` is the escape byte, so `$FF` can never be a note. Any number of commands
may sit back to back; the driver runs them all until it reaches a note event.

### Note bytes

```
note byte = semitone * 15 + octave + 2
```

`semitone` is 0–12 (C, C♯, D … B, C). The note table is a flat array of 16-bit
period words (`NR13`/`NR14` value with the trigger bit already set) indexed by
this byte — `NoteTable` at `$401E` in Pinball Party, `$411E` in Avenging Spirit.
Both games contain the **same** 195-entry table.

Each 15-entry semitone row holds the playable octaves 2–8 in slots 4–10, with
slots 0–3 duplicating octave 2 and slots 11–14 duplicating octave 8. Those
duplicates are the reason for the odd stride: they let `SCMD_TRANSPOSE`
(which shifts the index, i.e. transposes in **octave steps**) run off either end
of a row and clamp to the nearest playable octave instead of sliding into the
neighbouring semitone.

* `$B8` is the **rest** sentinel (it is an unreachable clamp slot of the 13th row).
* On the noise channel the note byte is written straight to `NR43` — it is a
  noise polynomial setting, not a pitch.

The length byte is multiplied by the current tempo multiplier
(`SCMD_TEMPO`, default 3) to produce the note's frame count.

### Gate length

How much of a note actually sounds is the *gate*, and each slot carries **three**
separate variables for it, all initialised by `Sound_ResetChannelGroup`:

| Variable | Reset value | Formula when selected |
|---|---|---|
| fractional numerator | `$08` | `gate = (note_frames * n) / 8 + 1` |
| absolute value | `$20` | `gate = n * tempo_multiplier` |
| mode flag | `0` | `0` selects the fractional formula, non-zero the absolute one |

Only the absolute formula names the tempo multiplier, because only it starts
from a raw operand. The fractional formula scales `note_frames`, which the
driver has already computed as `length_byte * tempo_multiplier` and written to
the note timer a few instructions earlier — so it picks the tempo up
transitively. Both gate modes therefore track tempo changes; they just reach it
by different routes.

Two arithmetic details if you are reimplementing it. The fractional path
accumulates `note_frames * n` in a 16-bit register pair, shifts right by 3, then
keeps **only the low byte** before the `+1`, so a very long note at full gate
(`255 * 8 / 8 = 255`, `+1` → `0`) wraps to an instant cut. The absolute path is
8-bit throughout, so `n * tempo` above 255 wraps as well.

The two reset values are therefore not two defaults for one variable — both are
stored, and the flag decides which is read. Because the flag starts at 0, the
effective gate at startup is `8/8` of the note, i.e. fully legato, and the `$20`
is never consulted until something sets the flag.

**What sets that flag differs between the two games, and neither is obvious.**

In *Avenging Spirit* only the two gate commands touch it, and they are
cross-wired: `SCMD_GATE_FRAC` stores the fractional numerator and then selects
**absolute** mode, while `SCMD_GATE_ABS` stores the absolute value and selects
**fractional** mode. The data is written around this — 55 of the 68
`SCMD_GATE_FRAC` in the music are immediately followed by a `SCMD_GATE_ABS`, so
the pair reads as "load numerator *n*, then switch to fractional mode", and the
second operand lands in an array nothing subsequently reads:

```
db $ff, SCMD_GATE_FRAC, $06   ; numerator := 6
db $ff, SCMD_GATE_ABS,  $08   ; ...and now select fractional mode
```

In *Pinball Party* the gate commands do **not** touch the flag at all; they only
store their value. The flag is written by the volume commands instead:
`SCMD_ENVELOPE` and `SCMD_SW_ENVELOPE` select absolute mode, `SCMD_VOLUME` and
`SCMD_TREMOLO` select fractional mode. The gate is in effect tied to the volume
mode — a note under a hardware or software envelope gets an absolute gate, one
at constant volume or under tremolo gets a fractional one.

When the gate timer reaches 0 the channel's volume register is zeroed while the
note timer keeps running; that is what produces staccato. The gate is not
clamped to the note length, so a large value simply means legato. Measured over
all the music, 56 % of Avenging Spirit's notes end up shortened against 1 % of
Pinball Party's.

### Load shedding (both games)

A per-frame counter is initialised to 2 at the top of `Sound_Update`. Each
executed command decrements it, *except* for the ids the dispatcher tests before
it reaches `ld b,a` — `$00`–`$02` in Avenging Spirit (panning, envelope, volume)
and `$01`–`$06` in Pinball Party (both gate commands, transpose, panning, tempo,
goto). If the counter reaches 0, the entire channel-output pass is skipped for
that frame — including the note timers — and the per-slot "already advanced"
flags are deliberately *not* cleared, so no slot double-advances. The music
simply loses a frame rather than glitching.

Measured over every song in both games, this fires on **about 1 % of active
frames** (1.1 % in Avenging Spirit, 1.1 % in Pinball Party), so a converter can
safely ignore it.

---

## 2. Hero Shuugou!! Pinball Party — command set (bank `$2`, 1990)

Dispatcher: `Sound_ExecCommand` at `$41A4`. Valid ids are `$01`–`$12`;
`$00` and anything `$13` or above fall through to the sweep-off handler.

| Id | Name | Operands | Effect |
|---|---|---|---|
| `$01` | `SCMD_GATE_FRAC` | 1 | Stores the fractional gate numerator (reset value 8). Does **not** change the gate mode. |
| `$02` | `SCMD_GATE_ABS` | 1 | Stores the absolute gate value (reset value `$20`). Does **not** change the gate mode. |
| `$03` | `SCMD_TRANSPOSE` | 1 | Signed offset added to the note byte — one unit is **one octave**, not one semitone. Clamps at octave 2 / octave 8. |
| `$04` | `SCMD_PANNING` | 1 | `1` = left, `2` = right, anything else = both. Written into `NR51` when the note is keyed on. Default 3. |
| `$05` | `SCMD_TEMPO` | 1 | Note-length multiplier, 0–7 (only the low 3 bits are used). Default 3. |
| `$06` | `SCMD_GOTO` | 2 (pointer) | Unconditional jump. Ends the current run of commands. |
| `$07` | `SCMD_SW_ENVELOPE` | **4** | Software volume envelope: start volume, signed step, rate (ticks between steps), target volume. The engine ramps the register nibble by *step* every *rate* ticks until it reaches *target*. On the wave channel the four operands are remapped into the channel's 2-bit volume field. Selects volume mode 2 **and absolute gate mode**. |
| `$08` | `SCMD_ENVELOPE` | 3 | Hardware envelope: volume 0–15, direction (0 = decay, non-zero = attack), period 0–7. Composed into `NRx2`. Selects volume mode 1 **and absolute gate mode**. |
| `$09` | `SCMD_SWEEP` | 3 | Pulse-1 frequency sweep. Ignored (operands skipped) on any other channel. |
| `$0A` | `SCMD_TREMOLO` | 3 | Tremolo: initial delay, depth, rate. A rotating `$AA` phase byte alternates the output volume between the base level and base + depth. Selects volume mode 3 **and fractional gate mode**. |
| `$0B` | `SCMD_TIMBRE` | 2 | Pulse channels: the **first** operand is rotated right twice into `NR11`/`NR21`, so 0–3 select duty 12.5/25/50/75 %; the **second operand is stored but never read**. Wave channel: the two bytes are a pointer to a 16-byte wave pattern. Noise channel: **neither** operand is read. |
| `$0C` | `SCMD_VOLUME` | 1 | Constant volume, no envelope. On the wave channel the values 1/2/3 are translated to the `NR32` shift codes `$60`/`$40`/`$20`. Selects volume mode 0 **and fractional gate mode**. |
| `$0D` | `SCMD_SET_LOOP` | 2 | Load loop counter *slot* (0–3) with *count*. Stored as count − 1. |
| `$0E` | `SCMD_LOOP` | 3 | If loop slot *n* is non-zero, decrement it and jump to the 16-bit address; otherwise skip the address and continue. |
| `$0F` | `SCMD_STOP` | 0 | Release this channel: clear the group's mask bits, silence the hardware channel, hand it back to a lower-priority group. |
| `$10` | `SCMD_CALL` | 2 (pointer) | Push the address of the next item and jump. Stack is 3 levels deep per slot. |
| `$11` | `SCMD_RET` | 0 | Pop and resume. |
| `$12` | `SCMD_DETUNE` | 1 | Signed, in 1/8 of a semitone. Bit 7 set = flat. The engine interpolates towards the adjacent semitone's period. |
| `$00`, `≥ $13` | `SCMD_SWEEP_OFF` | 0 | Clear `NR10`. Pulse 1 only. |

### Wave patterns

Three 16-byte patterns: `$4DF3` (descending ramp), `$4E03` (stepped ramp),
`$4E13` (square).

---

## 3. Avenging Spirit — command set (bank `$7`, 1992)

Dispatcher: `Sound_ExecCommand` at `$42A4`. Valid ids are `$00`–`$12`;
anything `$13` or above falls through to a catch-all.

| Id | Name | Operands | Effect |
|---|---|---|---|
| `$00` | `SCMD_PANNING` | 1 | `1` = left, `2` = right, anything else = both. Default 3. |
| `$01` | `SCMD_ENVELOPE` | 3 | Hardware envelope: volume, direction (0 = decay), period 0–7. Selects volume mode 1. |
| `$02` | `SCMD_VOLUME` | 1 | Constant volume 0–15, no envelope. Selects volume mode 0. |
| `$03` | `SCMD_VOL_ENVELOPE` | 2 (pointer) | **New in this revision.** Pointer to a software volume-envelope table. Selects volume mode 2. |
| `$04` | `SCMD_PITCH_ENVELOPE` | 2 (pointer) | **New in this revision.** Pointer to a pitch-envelope (vibrato / bend) table. Selects volume mode 3. |
| `$05` | `SCMD_GATE_FRAC` | 1 | Stores the fractional gate numerator (reset value 8) **and selects absolute mode** — see Gate length. |
| `$06` | `SCMD_GATE_ABS` | 1 | Stores the absolute gate value (reset value `$20`) **and selects fractional mode**. |
| `$07` | `SCMD_TRANSPOSE` | 1 | Octave-step transpose, clamped at octave 2 / 8. |
| `$08` | `SCMD_TEMPO` | 1 | Note-length multiplier, 0–7. Default 3. |
| `$09` | `SCMD_GOTO` | 2 (pointer) | Unconditional jump. |
| `$0A` | `SCMD_SWEEP` | 3 | Pulse-1 frequency sweep; skipped on other channels. |
| `$0B` | `SCMD_TIMBRE` | 2 | Duty (pulse, first operand only — the second is stored and never read) or wave-pattern pointer (wave). Nothing is read on the noise channel. Identical to Pinball Party's `$0B`. |
| `$0C` | `SCMD_SET_LOOP` | 2 | Loop slot *n* = *count*. |
| `$0D` | `SCMD_LOOP` | 3 | Conditional loop back. |
| `$0E` | `SCMD_STOP` | 0 | Release this channel. |
| `$0F` | `SCMD_CALL` | 2 (pointer) | Call subroutine. |
| `$10` | `SCMD_RET` | 0 | Return. |
| `$11` | `SCMD_DETUNE` | 1 | Signed, 1/8 semitone. |
| `$12` | `SCMD_SWEEP_OFF` | 0 | Clear `NR10`. Pulse 1 only. |
| `≥ $13` | — | 0 | Catch-all: switches the slot back to constant-volume mode. Not used by any shipped data. |

### Software envelope tables (this revision only)

**Volume envelope** (`SCMD_VOL_ENVELOPE`) — pairs of `volume, hold`. If the
*next* pair's first byte is `$F0`, its second byte is a byte index to loop to.
The single table in the ROM is at `$4B58` and produces a triple echo:
`15,2 · 0,1 · 8,1 · 0,1 · 5,1 · 0,1 · 3,1 · 0,255`.

**Pitch envelope** (`SCMD_PITCH_ENVELOPE`) — pairs of `delta, hold`, terminated
by a pair whose first byte is `$80`, whose second byte is the loop index.
`delta` is added to the note's period each step. Five tables live at
`$4B29`, `$4B31`, `$4B3B`, `$4B43`, `$4B4B` — delayed vibratos and, in the last
case, a laser-style downward sweep.

> **Quirk:** negative deltas are applied with a *one's* complement
> (`period -= ~delta`), not a two's complement, so a delta of `$FF` moves the
> pitch by 0 and `$FD` moves it by −2. Upward and downward deltas are therefore
> not symmetric.

### Wave patterns

Two 16-byte patterns: `$4B09` (triangle) and `$4B19` (a decaying pulse shape).

---


## 3a. Soldam — the two deltas from Avenging Spirit (bank `$7`, 1992)

Dispatcher: `Sound_ExecCommand` at `$42A7`. Every id from `$00` to `$12` has the
same meaning, operand count and handler as Avenging Spirit **except** the two
loop commands:

| Id | Avenging Spirit | Soldam |
|---|---|---|
| `$0C` | `SCMD_SET_LOOP`, 2 operands: slot, count | `SCMD_LOOP_START`, **1 operand**: count |
| `$0D` | `SCMD_LOOP`, 3 operands: slot, address lo, hi | `SCMD_LOOP_END`, **0 operands** |

`SCMD_LOOP_START` pushes a new level onto a per-channel loop stack: it stores the
count at `wChanLoopCtr[chan][depth]`, records the address of the byte *after* its
own operand as the loop start in `wChanLoopStart[chan][depth]` (big-endian), and
increments `wChanLoopDepth[chan]`. `SCMD_LOOP_END` decrements the innermost
counter; if it has not reached 0 it jumps to the recorded address, otherwise it
pops a level. The stack is **four levels deep per channel**, so loops genuinely
nest — something Avenging Spirit's four independent counter slots could only
approximate.

A body written `LOOP_START n … LOOP_END` plays *n* times, the same as Avenging
Spirit's `SET_LOOP slot,n … LOOP slot,addr`.

Because `LOOP_END` carries no address, a static parser cannot resolve the jump
from the command alone — it has to track the position recorded by the matching
`LOOP_START`. For linear disassembly that is harmless: the loop body has already
been walked, so `LOOP_END` can simply be treated as a two-byte no-op.

Soldam's tables: music `$4ADF` (9 songs), SFX `$4AF1` (19 effects), three
16-byte wave patterns at `$4B17`, `$4B27` and `$4B37`, and `NoteTable` at `$4121`.

---

## 4. Side-by-side opcode map

Reading this table is the fastest way to retarget a decoder from one game to the
other. Operand counts in parentheses.

| Function | Pinball Party (1990) | Avenging Spirit (1992) | Soldam (1992) |
|---|---|---|---|
| Gate, fractional | `$01` (1) | `$05` (1) | as AS |
| Gate, absolute | `$02` (1) | `$06` (1) | as AS |
| Transpose | `$03` (1) | `$07` (1) | as AS |
| Panning | `$04` (1) | `$00` (1) | as AS |
| Tempo multiplier | `$05` (1) | `$08` (1) | as AS |
| Jump | `$06` (2) | `$09` (2) | as AS |
| Software volume envelope | `$07` (4) | — | — |
| Hardware envelope | `$08` (3) | `$01` (3) | as AS |
| Sweep | `$09` (3) | `$0A` (3) | as AS |
| Tremolo | `$0A` (3) | — | — |
| Duty / wave pattern | `$0B` (2) | `$0B` (2) | as AS |
| Constant volume | `$0C` (1) | `$02` (1) | as AS |
| Set loop counter | `$0D` (2) | `$0C` (2) | `$0C` (1) `LOOP_START` |
| Loop | `$0E` (3) | `$0D` (3) | `$0D` (0) `LOOP_END` |
| Stop channel | `$0F` (0) | `$0E` (0) | as AS |
| Call | `$10` (2) | `$0F` (2) | as AS |
| Return | `$11` (0) | `$10` (0) | as AS |
| Detune | `$12` (1) | `$11` (1) | as AS |
| Sweep off | `$00` / `≥ $13` (0) | `$12` (0) | as AS |
| Volume-envelope table | — | `$03` (2) | as AS |
| Pitch-envelope table | — | `$04` (2) | as AS |

---

## 5. Entry points

### Hero Shuugou!! Pinball Party, bank `$2`

| Address | Name | In | Notes |
|---|---|---|---|
| `$4890` | `Sound_Update` | — | Per-frame tick, reached through the `$05AF` thunk in bank 0. |
| `$453C` | `Sound_Unmute` | — | Restore the saved `NR51`. |
| `$454B` | `Sound_Mute` | — | Save `NR51`, silence output. |
| `$455C` | `Sound_RestoreMusic` | — | Unreferenced inside bank `$2`. |
| `$4581` | `Sound_BackupMusic` | — | Unreferenced inside bank `$2`. |
| `$45A5` | `Sound_StopMusic` | — | Clear music slots 0–3. |
| `$45BB` | `Sound_StopSfx` | — | Clear both SFX groups. |
| `$45DC` | `Sound_Init` | — | Cold start. |
| `$4685` | `Sound_PlayMusic` | `a` = song 0–12 | Always loads slots 0–3. |
| `$46F6` | `Sound_PlaySfx` | `a` = effect 0–17 | Chooses SFX group A or B by priority. |

Bank 0 reaches these through thunks at `$0599`, `$05A4`, `$05AF`, `$05B7`,
`$05BF`, `$05C7`, `$05CF`, `$05D7`, which switch to bank `$2` via `$39D1` and
back via `$39C9`.

Bank `$2` also still contains a **sound-test program** at `$6E9E`–`$7EF2`: a
small menu that calls `Sound_Init`, starts song 7, prints strings, stops the
music and then demos effect 2. It is unreachable from the shipped game, and its
call pattern is useful confirmation of which entry point is which.

### Avenging Spirit, bank `$7`

| Address | Name | In | Notes |
|---|---|---|---|
| `$4000` | `Sound_Update` | — | Per-frame tick. Called from `$05CF` in bank 0. |
| `$4574` | `Sound_Unmute` | — | |
| `$4584` | `Sound_Mute` | — | |
| `$4594` | `Sound_StopMusic` | — | Clear music slots 0–3. |
| `$45AA` | `Sound_StopSfx` | — | Clear SFX slots 4–7. |
| `$45C4` | `Sound_Init` | — | Cold start. |
| `$4662` | `Sound_PlayMusic` | `a` = song 0–19 | |
| `$46CF` | `Sound_PlaySfx` | `a` = effect 0–18 | |

Bank 0 pages bank `$7` in, dispatches, and pages back; the per-frame path also
reads a pending-SFX byte from `$FFB6`.

### Soldam, bank `$7`

| Address | Name | In | Notes |
|---|---|---|---|
| `$4000` | `Sound_Update` | — | Per-frame tick. Called from `$04B2` in bank 0. |
| `$4590` | `Sound_Unmute` | — | |
| `$45A0` | `Sound_Mute` | — | |
| `$45B0` | `Sound_StopMusic` | — | Clear music slots 0–3. |
| `$45C6` | `Sound_StopSfx` | — | Clear SFX slots 4–7. |
| `$45E0` | `Sound_Init` | — | Cold start. |
| `$4686` | `Sound_PlayMusic` | `a` = song 0–8 | |
| `$46F3` | `Sound_PlaySfx` | `a` = effect 0–18 | |

Same pattern as Avenging Spirit, and the per-frame path likewise polls `$FFB6`
for a pending effect id.

---

## 6. Notes, quirks and loose ends

* **`$CCA6` is aliased in Avenging Spirit.** The per-slot hardware-envelope
  volume array starts at `$CCA4`, so slot 2 — the music group's wave channel —
  writes to `$CCA6`, which is also the driver's sound-enabled flag. Using
  `SCMD_ENVELOPE` on the music wave channel would therefore corrupt it, and a
  value with both low bits clear would mute the driver entirely. No shipped song
  does this, so the bug never fires. Pinball Party has exactly the same
  collision: its flag is `$D068`, which is slot 2 of the 12-wide array starting
  at `$D066` — again the music group's wave channel. The bug was inherited, not
  introduced, and neither game's data triggers it (`SCMD_ENVELOPE` appears only
  on channels 0, 1 and 3 in Pinball Party's music).
* **Duty operands above 3.** Avenging Spirit's data uses `SCMD_TIMBRE` operands
  `$04` and `$09` on pulse channels (40 times). After the two rotates these
  become `NR11 = $01` and `NR11 = $42`, i.e. duty 0 and duty 1 with a small
  length-counter value. Since the length-enable bit in `NR14` is never set, the
  length value has no audible effect.
* **Pitch-envelope table `$4B29`** loops back to byte index 1, an odd offset, so
  after its first pass it reads pairs straddling the intended boundaries. Two
  other tables (`$4B43`, `$4B4B`) run past their own end into the following
  table; the notes using them are short enough that it is rarely heard. These
  look like authoring mistakes preserved in the shipped ROM.
* **Pinball Party's SFX-header flag byte** (header + 8) is `$FF` in all 18
  headers, so the branch testing for 1 is dead.
* Every command id `$01`–`$12` is exercised by real sequence data in both games,
  on the channels you would expect (sweep only on pulse 1, Pinball Party's
  software envelope only on the wave channel), which corroborates the decoding.

---

## 7. Note timing, and notes for converter authors

### The timing model

The two games compute note length with **byte-identical code** — the instruction
sequence in `Sound_DoChannel` is the same in both, only the RAM addresses differ:

```
note_frames = length_byte * (tempo_multiplier & 7)      ; 8-bit, wraps at 256
if note_frames == 0: note_frames = 1
```

`tempo_multiplier` is per-slot, set by `SCMD_TEMPO`, and defaults to 3. The
multiply is done by testing bits 0, 1 and 2 of the multiplier and adding
`length`, `length*2` and `length*4`, so values above 7 are masked off and the
result is truncated to 8 bits.

`Sound_Update` is called once per frame in both games, and a note occupies
exactly `note_frames` frames: on the frame it starts, the timer is loaded and
immediately decremented in the same pass, and the next event is fetched on the
frame the timer reaches 0. There is no extra divider anywhere.

**Gate is not duration.** `note_frames` is the note's *slot* — the spacing to
the next event. How long it actually sounds is the gate, which is a separate
three-variable affair described under **Gate length** in section 1. The command
that stores a gate value is not the command that selects the mode, and which
command selects it differs between the two games, so read that section before
implementing it. For MIDI, note-on spacing comes from `note_frames` and note-off
from the gate, clamped to `note_frames`.

### Default multiplier: the trap that makes Pinball Party run fast

The multiplier defaults to **3**, set by `Sound_ResetChannelGroup` before any
stream byte is read. Whether a track relies on that default differs sharply
between the two games:

| | Pinball Party | Avenging Spirit |
|---|---|---|
| Music streams that set `SCMD_TEMPO` before their first note | 19 of 47 | 73 of 74 |
| Music streams that rely on the default 3 | **28 of 47** | 1 of 74 |
| `SCMD_TEMPO` values used | 2 (23×), 3 (8×) | 3 (54×), 4 (11×), 5 (7×), 2, 1 |

Avenging Spirit's composer wrote an explicit tempo at the top of almost every
channel, so a decoder that initialises its own multiplier to the wrong value
never notices. Over half of Pinball Party's music channels never set it at all.
**Initialise the multiplier to 3, not to 0 or 1** — starting at 1 makes most
Pinball Party tracks play exactly three times too fast while Avenging Spirit
sounds correct, which is a confusing symptom to chase.

Once the default is right, the two games sit on comparable grids: the median
note event is 12 frames in Pinball Party and 10 in Avenging Spirit, with 6, 8
and 12 frames being the common values in both.

### Turning envelope levels into MIDI velocity

Two things decide what a level byte means: **which channel it is on**, and
**which revision's command wrote it**.

* **Pulse 1, pulse 2 and noise** take a 4-bit level in `NRx2`, 0–15, and the
  Game Boy's DAC is linear in that value. `velocity = round(level * 127 / 15)`
  is the honest mapping. Multiplying by `$10` and halving gives 0–120 → 0–60 and
  makes everything half as loud as it should be.
* **The wave channel is not 4-bit.** `NR32` holds a 2-bit *shift* code with only
  four possible outputs — mute, 25 %, 50 %, 100 % — so the useful velocities are
  0, 32, 64 and 127.

Avenging Spirit and Soldam write plain 0–15 levels: `SCMD_ENVELOPE`'s first
operand, and each `value` byte of a `SCMD_VOL_ENVELOPE` table, are already the
nibble that reaches `NRx2`.

Pinball Party's `SCMD_SW_ENVELOPE` is the one that misleads, because it is used
**only on the wave channel** (all 30 occurrences), and the handler *inverts* its
operands on the way in:

| `SCMD_SW_ENVELOPE` start operand | stored | `NR32` | level |
|---|---|---|---|
| 0 | 0 | `$00` | mute |
| 1 | 6 | `$60` | 25 % |
| 2 | 4 | `$40` | 50 % |
| 3 | 2 | `$20` | **100 %** |

So a start operand of 3 is the *loudest* setting, not a quiet one. Twenty-nine
of the thirty uses in the game are `(3, $FF, rate, 0)` — start at full volume,
step one level quieter every *rate* ticks, fade to silence — and the thirtieth,
`(0, 1, 1, 3)`, is the same shape inverted into a fade-in.

Because the envelope evolves *during* the note and MIDI velocity is fixed at
note-on, the practical split is: take the **starting** level for velocity, and
emit the decay as CC #11 (Expression) events if you want it represented at all.
Trying to reproduce the ramp exactly is not worth it — the driver reads `NR32`
back, adds the step and writes it again, and the unused bits of `NR32` read as
1s on hardware, so the tail of a long wave-channel envelope is emulator-dependent.

### Operand lengths that will desynchronise a shared parser

Reusing Avenging Spirit's operand table on Pinball Party data breaks the stream
outright — once the parser is off by a byte, note and length bytes swap roles and
the output is both scrambled and far too fast. The ids that differ in *length*:

| Id | Avenging Spirit | Pinball Party | Byte drift |
|---|---|---|---|
| `$07` | `SCMD_TRANSPOSE`, 1 | `SCMD_SW_ENVELOPE`, **4** | −3 |
| `$0C` | `SCMD_SET_LOOP`, 2 | `SCMD_VOLUME`, 1 | +1 |
| `$0E` | `SCMD_STOP`, 0 | `SCMD_LOOP`, 3 | −3 |
| `$0F` | `SCMD_CALL`, 2 | `SCMD_STOP`, 0 | +2 |
| `$03` | `SCMD_VOL_ENVELOPE`, 2 | `SCMD_TRANSPOSE`, 1 | +1 |
| `$04` | `SCMD_PITCH_ENVELOPE`, 2 | `SCMD_PANNING`, 1 | +1 |

No Avenging Spirit command takes four operands, so `SCMD_SW_ENVELOPE` is the
most destructive of these.

### Which table is which

Pinball Party's two pointer tables are easy to swap, and getting them the wrong
way round looks exactly like a timing bug: the `$4DCF` table is **sound effects**,
and 16 of its 18 entries are one-channel stingers of 14–120 frames, several of
them deliberately one frame per note. Feed those to a MIDI converter as music
and the output is a fraction of a second of nonsense.

Three independent checks fix the roles:

* **Priority.** `Sound_PlayMusic` loads slots 0–3, and every arbitration path
  masks that group off with the other two (`music = claim AND NOT (sfxA | sfxB)`).
  A driver always lets effects interrupt music, never the reverse.
* **Allocation shape.** The `$4DCF` entry point manages a pool of two groups,
  reuses a group already playing the requested id, prefers a free group and
  otherwise displaces by id — a textbook effect allocator. The `$4DB5` entry
  point loads one fixed group unconditionally, which is what a music call does.
* **Content.** 10 of the 13 `$4DB5` entries loop forever on three or four
  channels at 8–24 frames per note. None of the `$4AE3` / `$4DCF` effect entries
  in either game loop.

Avenging Spirit follows the same pattern: `$4ABB` is music (15 of 20 loop
forever), `$4AE3` is effects (0 of 19 loop).

---

## 7. Rebuilding and checking

```sh
rgbasm  -o pp.o  pinball_party_bank2.asm
rgblink -o pp.gb pp.o
# bytes $08000-$0BFFF of pp.gb == bank $2 of the original ROM

rgbasm  -o as.o  avenging_spirit_bank7.asm
rgblink -o as.gb as.o
# bytes $1C000-$1FFFF of as.gb == bank $7 of the original ROM
```

Both files were verified this way against the original ROMs: all 16384 bytes of
each bank match exactly.
