# Mark Cooksey C64 sound drivers: overview

Disassemblies of three of Mark Cooksey's C64 SID rips, all arcade conversions:

| Game | Year / publisher | Rip | Driver | Songs |
|---|---|---|---|---|
| Bomb Jack | 1986 Elite | `Bomb_Jack.sid`, $73A0-$96FA | early | 6 |
| Paperboy | 1986 Elite | `Paperboy.sid`, $A5FE-$C017 | middle | 4 (5 rip entries) |
| Forgotten Worlds | 1989 US Gold / Capcom | `Forgotten_Worlds.sid`, $E000-$FA4F | late (two builds) | 2 |

The folder had **Paperboy.sid** rather than a Space Harrier rip, so Paperboy is the third game here. It is also a 1986 Elite arcade conversion and fits between the other two.

## Files

| File | What it is |
|---|---|
| `disasm/bomb_jack_sound.s` | ca65 source, labelled and commented |
| `disasm/paperboy_sound.s` | ca65 source |
| `disasm/forgotten_worlds_sound.s` | ca65 source (both driver builds) |
| `disasm/*.cfg` | ld65 configs |
| `disasm/tool/` | generator: `build.py`, `core.py`, `common.py`, `cfg_bj.py`, `cfg_pb.py`, `cfg_fw.py` |
| `docs/driver_bomb_jack.md` | early driver: format and notes |
| `docs/driver_paperboy.md` | middle driver: format, drums, sound effects |
| `docs/driver_forgotten_worlds.md` | late driver: format, the two builds, ripper relocation errors |
| `docs/lineage_and_nes.md` | how the three drivers relate, and to the NES driver |
| `docs/tuning_and_timing.md` | frequency tables, the Bomb Jack pitch problem, play rates |

Each `.s` file rebuilds the **whole .sid file** (PSID header included), byte for byte:

```
ca65 bomb_jack_sound.s
ld65 -C bomb_jack_sound.cfg -o bomb_jack_sound.sid bomb_jack_sound.o
```

`python3 disasm/tool/build.py <folder with the .sid files> <output folder>` regenerates all three and checks them (needs cc65 on the PATH). The tool is the C64 counterpart of `NESAudioLab\MC\disasm\tool` and reuses its `core.py` (SID/CIA names instead of APU names, plus operand overrides).

## Conventions in the sources

- Variables live inside the player image on the C64, so they appear as labelled `.byte` lines holding the ripper's snapshot values (`m` = music, `s` = sound effects, `z` = zero page equates).
- Pattern lines carry a comment with the note name and length. Notes are named from the driver's own octave numbering.
- Bytes the driver never reads are kept and marked `not referenced` (rip padding, leftovers, a second `$FF` after each Paperboy effect, and so on).
- The SID ripper's own wrapper code is labelled `Rip_...` and is not part of the game.

## Main findings

1. **Three generations.** Bomb Jack and Paperboy (1986) share a pattern idea: a length byte and a note byte, with commands from `$C8`. Forgotten Worlds (1989) is a different, later driver: 2-byte events with a 5-bit instrument, a 16-entry duration table and commands `$60-$6B`. That later format is the one the NES driver uses (see `lineage_and_nes.md`).
2. **Bomb Jack is tuned for NTSC.** Its frequency table is the NTSC table from the C64 Programmer's Reference Guide. On a PAL C64 (and in a PSID player's default PAL mode) every note is about 65 cents flat, so a G sounds like a slightly sharp F#. Paperboy already uses PAL values. Details in `tuning_and_timing.md`.
3. **Forgotten Worlds holds two separate driver builds.** The title tune has the full driver ($E000). The in-game tune has a cut-down build ($EE00) without PWM or filter. The ripper moved the in-game build from $C000 and missed every address on code paths the tune never runs: 15 instruction operands and 5 command table entries still point into $C000-$C2FF (written in the source as `Label-RIP_RELOC`).
4. **Paperboy contains a sound effect player** with 15 effects that the rip never triggers.
5. A few genuine bugs, each marked in the source (for example a missing `,x` in Paperboy's waveform alternation, a missing `STA` in Bomb Jack's voice-2 pulse sweep command, and missing `CLC`s in the Forgotten Worlds vibrato).
