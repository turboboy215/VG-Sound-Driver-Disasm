# Driver lineage, and the link to the NES driver

## The three C64 generations

| | Bomb Jack (1986) | Paperboy (1986) | Forgotten Worlds (1989) |
|---|---|---|---|
| Code layout | one copy per voice | one loop, X = voice | one loop, X = voice |
| Variables | shadow SID registers + flags | per-voice arrays of 3 | per-voice arrays of 3 |
| Song layout | init routine + order lists of pattern pointers | same | 3 track pointers; tracks call numbered patterns |
| Event | length byte + note byte | length byte + note byte | note + instrument/length byte |
| Note byte | octave in bits 4-6, semitone 1-12 | same | 0-95 index |
| Pitch table | octave 5 + shifts, **NTSC** | octave 5 + shifts, PAL | 96 entries, PAL |
| Lengths | ticks (calls / mSpeed) | ticks | frames, from a 16-entry table |
| Instruments | none: commands set waveform, AD, SR, pulse | none: commands | 7 / 3 instruments in column tables |
| Commands | $C8-$DA (+ drums $F6-$FA), voice-specific | $C8-$DE via jump table (+ drums $F0-$FF) | $60-$6B |
| Pattern reuse | order list only | order list only | CALL with transpose and repeat count |
| Effects | pulse sweep, octave trill, slide | + vibrato, waveform alternation, release point | PWM, vibrato, filter sweep, tie |
| Sound effects | not in the rip | yes ($B110) | not in the rip |

Bomb Jack and Paperboy are clearly the same design at two stages. The pattern bytes, the octave-5 table with shifts, the `$00` end marker, the order lists with a zero high byte, the song init routines that preload the first pattern and start the order index at 2, the octave trill and the pulse sweep all carry over. Paperboy generalises the code (one loop, a jump table, every command on every voice) and fixes the tuning.

Forgotten Worlds shares almost nothing with them at the data level. It is a new design rather than a further revision of the 1986 driver: instruments instead of register commands, frame lengths from a table, a note index instead of octave/semitone, and pattern calls with transpose.

## Forgotten Worlds and the NES driver

The NES driver documented in `NESAudioLab\MC\Mark cooksey engine notes.md` uses the Forgotten Worlds event format almost unchanged:

| | Forgotten Worlds (C64) | NES (Dragon's Lair, Joe & Mac, Aladdin) |
|---|---|---|
| byte 0 | bit 7 = instrument bit 4, bits 0-6 = note, $60+ = command | identical |
| byte 1 | high nibble = instrument bits 0-3, low nibble = length index | identical |
| Length index | 16-entry table, one per driver build | 16-entry table, pointer per song |
| Duration values | `03 04 06 09 0C 12 18 24 30 48 60 90 C0 08 10 20` (title) | `03 04 06 09 0C 12 18 24 30 48 60 90 C0 08 10 3C` (Dragon's Lair `DurTable_87F7`) |
| Rest | $60 len | $60 len |
| Pattern call | $64 pat,trn / $65 cnt,pat,trn | $62 pat,trn,cnt |
| Return | $66 | $63 |
| Jump | $68 .word | $64 .word |
| Call depth | 1 level, one return address per voice | same |
| Track end | $6B stop (all voices) | $61 end (one channel) |
| Instrument | SID columns: ctrl, release ctrl, AD, SR, pulse, PWM, vibrato | 9 bytes: volume / pitch / arpeggio envelope pointers, reg0/reg3 bits |
| Gate release | RelTable per length index | volume envelope |

The first 15 duration values are the same, which is hard to explain by chance. So the NES driver comes from the **late** C64 driver, not from the Bomb Jack / Paperboy one. The NES version renumbers and trims the command set, moves the duration table into the song header, and replaces the SID-specific instrument fields with envelopes, which the NES APU needs because it has no ADSR.

The in-game Forgotten Worlds build also shows the driver being cut down to fit: PWM and filter code removed, the PWM columns and the filter command numbers left behind.

## Open questions

- Where the change happened between 1986 and 1989: a Cooksey rip from 1987-88 (for example Space Harrier, 1986/87, or Ghosts 'n Goblins) would show whether there is an intermediate version.
- Whether the Game Boy driver follows the NES one or the C64 one directly.
