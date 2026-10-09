# Make Software NES sound engine: version notes

Disassemblies (ca65, byte-identical reassembly verified) are in the user's folder `NESAudioLab\Make\disasm\`, with the generator scripts in `disasm\tool\` (run `python mkfinal.py` there).

| Game | Location | Channels | Music | SFX | Envelopes | Drums | Subroutines |
|---|---|---|---|---|---|---|---|
| Duck Tales 2 (E) | UxROM PRG bank 0, $8000-$ADED | 4 music + 2 SFX | 19 | 62 | 51 | 8 (+ silent) | 150 |
| Chip 'n Dale Rescue Rangers 2 (E) | MMC1 PRG bank 6, $8000-$BEF3 | 4 music + 2 SFX | 33 | 83 | 18 (+3 placeholders) | 8 (+ silent) | 120 |

## Shared design
- The game writes a request number to `$F0` (bit 7 set = taken). $00 = init, $01-$78 = SoundTable, $79 resume, $7A pause, $7B/$7C fade (see below), $7D stop music, $7E stop SFX, $7F init.
- Six channels: 0-3 = Sq1, Sq2, Tri, Noise (music); 4 = Sq2 and 5 = Noise for sound effects. While 4/5 play, music Sq2/Noise keep running but aren't written.
- Sound header: a mask byte (bits 0-3 music channels, bits 4-5 SFX channels), then one track pointer per set bit. Mask $00 stops the music.
- One-byte events: $00-$BF note (high nibble C..B, low nibble length-1), $C0-$CF rest. Length = (n+1) x speed. Pitch = period[octave*12 + note + 2 transposes] + detune; the period table holds period x 2, index 0 = C0.
- Commands $D0-$FF: $D0-$D6 octave, $D7/$D8 octave up/down, $D9 transpose, $DA transpose add, $DB detune, $E0 speed, $E1 duty, $E2 envelope, $E3-$E5 no-op with argument, $E8 tie, $E9 volume, $EA volume add, $EB sweep, $EC sweep off, $ED drum-map swap (unused), $F0 n loop / $F1 loop end, $F2 call / $F3 return, $F8 jump, $FF end. Loops and calls share a 16-byte stack per channel. The other values have $0000 handlers.
- Volume envelopes: (frames, delta lo, delta hi) segments that add a signed 8.8 delta per frame; $FE lo hi sets the value; $FF ends (volume 0). Volume = high nibble minus CMD_VOLUME and a master attenuation.
- Noise channel: the note picks a drum macro through a 13-entry remap table. The macro runs one step per frame: $00-$1F noise period, $40-$4F lo plays a square-2 tone with the noise channel's volume instead, $80-$BF picks an envelope, $E0-$FE sets duty, $FF stops.
- SFX noise channel (5): the period is (note - transposes) & 15; it ignores octave.
- Command handlers run with a return address pushed that points back at the byte reader, so commands chain until a note or rest.

## Version differences
- **Duck Tales 2**: `JMP` table with two entries. $8000 handles the request, music channels and output; $8003 runs the SFX channels. Both are called from NMI. $7B/$7C are RTS. The fade variables are only cleared, but the master attenuation is still subtracted. Init resets all 6 channels.
- **Chip 'n Dale 2**: one entry at $8000 that runs all six channels (only 4-5 while paused). Adds Sound_Fade: $7B fades out (+1 attenuation every 4 frames, up to 16). $7C fade-in is broken: the `BEQ` that skips the fade-out goes to the RTS, so the fade-in code after it is unreachable. Init also clears the pause/fade state but resets only channels 0-3.
- Data bug in Chip 'n Dale 2: SFX $6C uses envelope $12. EnvTable entries $12-$14 are placeholders pointing at Sound_01's header, so header bytes get read as an envelope.
- Both ROMs have bytes left after CMD_JUMP/CMD_END (usually `C0 FF`). They are marked "never reached".
