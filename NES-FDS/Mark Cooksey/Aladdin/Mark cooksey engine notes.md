# Mark Cooksey NES sound engine: version notes

Disassemblies (ca65, byte-identical reassembly verified) are in the user's folder `NESAudioLab\MC\disasm\`, with the generator scripts in `disasm\tool\`.

| Game | Location | Channels | Songs | Instr. | Patterns | SFX |
|---|---|---|---|---|---|---|
| Dragon's Lair (E), first version | MMC3 PRG banks 0+1, $8000-$A028 | 4 | 9 | 23 | 46 | 47 |
| Joe & Mac (E), DMC version | MMC3 PRG bank 11, $8000-$9FFF; samples at $C000-$CFB0 (bank 14) | 5 (+DMC) | 8 | 18 | 50 | 24 |
| Aladdin (E), alternate without DMC | AxROM bank 0, $D05B-$EFD9 | 4 | 5 | 16 | 26 | 41 |

## Shared design
- Jump table of 5 JMPs: Sfx_Init, Sfx_Play (A = priority, X = effect number), Sfx_Update, Music_Play (A = song), Music_Update.
- Song = N track pointers + a duration-table pointer, stored in split lo/hi tables.
- 2-byte events: b0 bit 7 = instrument bit 4, bits 0-6 = note (C2 = 0) or command $60+; b1 = instrument bits 0-3 in the high nibble, a 16-entry duration index in the low nibble.
- Commands: $60 rest, $61 end, $62 call pattern (index, transpose, count; one level), $63 return, $64 jump.
- Instrument (9 bytes): flags (<2 = has a volume envelope), vol env ptr, pitch env ptr, reg0 OR, reg3 OR, arpeggio env ptr.
- Envelopes are (value, frames) pairs. Volume ends with $80; pitch and arpeggio loop with $80 + a word.

## Version differences
- **Joe & Mac**: adds a 5th DMC track (b0 low nibble = rate, b1 high nibble = sample number), $65 DMC end, $66 DMC rest, DMC sound effects (channel >= 4), Music_Play $81 = resume. Effect priority must be strictly greater (other versions accept equal). CMD_JUMP on the DMC track re-enters the tone routine; this is only safe because each jump target starts with CMD_CALL.
- **Aladdin**: RAM uses 5-wide arrays (taken from the DMC branch) but runs 4 channels. Adds a tempo accumulator (mTempo is only ever $FF; the ADC has no CLC before it). Arpeggio is removed: pointers are still read and the data is still in the ROM. Adds $65 CMD_DURTABLE (global, unused by songs). Sound effect steps carry their own delay byte, and a $FF step means end.
- Bugs in DL and Aladdin: Sfx_Play returns with X still pushed for channel >= 4. Aladdin's Sfx_Stop discards an AND result.
- Dragon's Lair bank 1 after $A029 holds leftover assembler source text ("B3B_END", "BANK $3B too long").