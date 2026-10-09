def _box(lines):
    out = [';' + '=' * 78]
    for l in lines:
        out.append((';  ' + l).rstrip())
    out.append(';' + '=' * 78)
    out.append('')
    return out

FORMAT = r"""
CHANNELS
  0 Sq1, 1 Sq2, 2 Tri, 3 Noise (music)   4 Sq2, 5 Noise (sound effects)
  While channel 4 or 5 runs, the music's square 2 / noise keep running but
  are not written to the APU (OutputSkipMask).

REQUESTS (zSoundReq = $F0; the game writes a number, bit 7 is set when
  the engine has taken it; one request per frame)
  $00        Sound_Init (silence and reset everything)
  $01-$78    Sound_Start: SoundTable entry
  $79 resume  $7A pause  $7B / $7C see below  $7D stop music  $7E stop
  sound effects  $7F Sound_Init

SOUND HEADER (SoundTable entry)
  byte    bits 0-3 = music channels 0-3, bits 4-5 = sound effect channels
          4-5 (if bits 4-5 are set, bits 0-3 are not loaded)
  .word   one track pointer per set bit, lowest channel first
  A music header with no bits ($00) stops the music.

TRACK DATA (one byte per event; commands may have arguments)
  $00-$BF  note: high nibble = note C..B (0-11), low nibble = length - 1
  $C0-$CF  rest, low nibble = length - 1
           length in frames = (n + 1) * speed (CMD_SPEED; speed 0 = x1)
  Pitch = PeriodTable[octave*12 + note + CMD_TRANSPOSE + CMD_TRANSPOSE_ADD]
  + CMD_DETUNE. On channel 3 the note picks drum macro mDrumMap[note]
  (mDrumMap = 0-12 when a song starts). On channel 5 the noise period is
  (note - both transposes) & 15; the octave is ignored.
  Comment notation: note names use the octave command in effect (C-4 =
  octave 4), before transposes; "a/b" = more than one octave reaches it.
  "= n fr" is shown when only one speed can be in effect.
  Commands:
    $D0-$D6 CMD_OCTAVE0-6        octave
    $D7 CMD_OCTAVE_UP / $D8 CMD_OCTAVE_DOWN
    $D9 CMD_TRANSPOSE n          transpose = n (signed)
    $DA CMD_TRANSPOSE_ADD n      second transpose += n
    $DB CMD_DETUNE n             signed period offset
    $E0 CMD_SPEED n              length multiplier
    $E1 CMD_DUTY n               duty n & 3
    $E2 CMD_ENVELOPE n           volume envelope n, starts with the next note
    $E3-$E5 n                    argument skipped (no effect)
    $E8 CMD_TIE                  next note keeps the envelope and period
    $E9 CMD_VOLUME n             attenuation = n (subtracted from the volume)
    $EA CMD_VOLUME_ADD n         attenuation += n
    $EB CMD_SWEEP n / $EC CMD_SWEEP_OFF (= $08)
    $ED CMD_DRUM_SWAP xy         swap mDrumMap[x] and mDrumMap[y] (unused)
    $F0 CMD_LOOP n ... $F1 CMD_LOOP_END     play the block n times
    $F2 CMD_CALL .word sub ... $F3 CMD_RETURN
    $F8 CMD_JUMP .word addr
    $FF CMD_END                  stop the channel
    Loops and calls share a 16-byte stack per channel (nesting allowed).
    $DC-$DF, $E6, $E7, $EE, $EF, $F4-$F7, $F9-$FE have no handler
    ($0000 in CmdTable) and would crash.

VOLUME ENVELOPES (EnvTable)
  frames, delta lo, delta hi   add the signed 16-bit delta to mVol:mVolFrac
                               every frame, for 'frames' frames (0 = 256)
  $FE, lo, hi                  set mVol:mVolFrac = hi:lo
  $FF                          end: volume 0, envelope off
  The APU volume is the high nibble of mVol, minus CMD_VOLUME and
  zMasterAtten. A rest turns the envelope off (volume 0).

DRUM MACROS (DrumTable, channel 3; one step per frame while the envelope
  is on)
  $00-$1F      noise period (value >> 1); ends this frame
  $40-$4F lo   square 2 plays a tone instead: period ((n&15)<<8 | lo) >> 1,
               with the noise channel's volume and duty; ends this frame
  $80-$BF      volume envelope n & $3F (keep reading)
  $E0-$FE      duty n & 3 (keep reading; used by the square 2 tone)
  $FF / other  stop (the macro stays on this byte)

Bytes nothing reads are kept so the file reassembles; they are marked
"never reached" or "not used".
"""

def stats(e):
    st = e.cfg['sounds']; n = e.cfg['nsounds']
    hdrs = [e.w(st + 2 * i) for i in range(n)]
    mus = [i for i in range(1, n) if e.b(hdrs[i]) & 0x0F and not e.b(hdrs[i]) & 0x30]
    sfx = [i for i in range(1, n) if e.b(hdrs[i]) & 0x30]
    return mus, sfx

def cfg_dt2(e):
    mus, sfx = stats(e)
    return _box([
        "Make Software NES sound engine - DUCK TALES 2 (E)",
        "Version with two entry points and no fade.",
        "",
        "Source: Duck Tales 2 (E) [!].nes, UxROM, 16K PRG bank 0 (file offset $0010)",
        "at $8000-$ADED. $ADEE-$ADFF is $FF fill and game data starts at $AE00.",
        "The fixed bank switches bank 0 in before each call.",
        "Reassembles byte-identically:  ca65 duck_tales_2_sound.s",
        "             ld65 -C duck_tales_2_sound.cfg -o out.bin duck_tales_2_sound.o",
        "",
        "ENTRY POINTS (both called from the NMI handler)",
        "  $8000 Sound_Update     request, music channels 0-3, APU output",
        "  $8003 Sound_UpdateSfx  sound effect channels 4-5 (called earlier in NMI)",
        "",
        "%d music tracks ($%02X-$%02X), %d sound effects ($%02X-$%02X); entries $10 and"
        % (len(mus), mus[0], mus[-1], len(sfx), sfx[0], sfx[-1]),
        "$15-$1F point at the empty header. Requests $7B/$7C do nothing; the",
        "fade variables zFadeIn/zFadeOut/zMasterAtten are only ever cleared.",
    ] + FORMAT.split('\n'))

def cfg_cnd2(e):
    mus, sfx = stats(e)
    return _box([
        "Make Software NES sound engine - CHIP 'N DALE RESCUE RANGERS 2 (E)",
        "Differences from Duck Tales 2:",
        "  * one entry point: Sound_Update runs all six channels (only 4-5",
        "    while paused)",
        "  * fade: request $7B = fade out (zMasterAtten + 1 every 4 frames, up",
        "    to 16), $7C = fade in. BUG: the fade-in code is unreachable (the",
        "    BEQ before it goes to the RTS), so $7C only sets a flag",
        "  * Sound_Init also clears pause/fade state and resets only channels",
        "    0-3 (Duck Tales 2: 0-5)",
        "  * data BUG: sound $6C uses envelope $12, whose EnvTable entry",
        "    ($12-$14 are placeholders) points at Sound_01's header",
        "",
        "Source: Chip 'n Dale Rescue Rangers 2 (E).nes, MMC1, 16K PRG bank 6",
        "(file offset $18010) at $8000-$BEF3. $BEF4-$BFDF is $FF fill, the",
        "MMC1 reset stub follows.",
        "Reassembles byte-identically:  ca65 chip_n_dale_2_sound.s",
        "             ld65 -C chip_n_dale_2_sound.cfg -o out.bin chip_n_dale_2_sound.o",
        "",
        "ENTRY POINT: $8000 Sound_Update, called from the NMI handler with bank 6",
        "switched in.",
        "",
        "%d music tracks ($%02X-$%02X), %d sound effects ($%02X-$%02X)."
        % (len(mus), mus[0], mus[-1], len(sfx), sfx[0], sfx[-1]),
    ] + FORMAT.split('\n'))
