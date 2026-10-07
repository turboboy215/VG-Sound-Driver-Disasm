def _box(lines):
    out = [';' + '=' * 78]
    for l in lines:
        out.append((';  ' + l).rstrip())
    out.append(';' + '=' * 78)
    out.append('')
    return out

TRACK_FMT = r"""
TRACK / PATTERN DATA
  Each channel reads a stream of 2-byte events (some commands are longer).
    byte 0  bit 7     = bit 4 of the instrument number
            bits 0-6  = note number $00-$5F (index into PeriodLo/PeriodHi;
                        $00 = C2 on a square channel, the triangle sounds an
                        octave lower). The channel transpose (set by
                        CMD_CALL) is added to it. Values $60-$7F are commands.
    byte 1  bits 4-7  = instrument number bits 0-3
            bits 0-3  = length index into the current duration table
                        (16 entries, frames per note)
  Note names in the comments are the untransposed values; "= n fr" is the
  length in frames, shown when only one duration table can apply.
  Commands (byte 0 & $7F):
    $60 CMD_REST    len            rest (volume -> 0 if reg0 bit 4, constant
                                    volume, is set); byte 1 low nibble =
                                    length index
    $61 CMD_END                    stop this channel
    $62 CMD_CALL    pat,trn,cnt    play pattern #pat (PatternLo/Hi), adding
                                    trn to every note, cnt times, then
                                    continue after this command (one level
                                    only: one return address per channel)
    $63 CMD_RETURN                 end of pattern
    $64 CMD_JUMP    .word addr     continue at addr (song loop)"""

INSTR_FMT = r"""
INSTRUMENTS (9 bytes, InstrumentLo/Hi)
    +0      flags: 0 or 1 = uses a volume envelope, >= 2 = no volume envelope
    +1,+2   volume envelope pointer (only if flags < 2)
    +3,+4   pitch envelope pointer (high byte 0 = none)
    +5      OR'ed into register 0 (duty, length-halt, constant volume)
    +6      OR'ed into register 3 (length counter load)
    +7,+8   arpeggio envelope pointer (high byte 0 = none)%s

ENVELOPES  (each step is a value and a frame count; count 0 = 256)
  Volume:    vol,frames ... $80            $80 = stop, keep the last volume
  Pitch:     delta,frames ... $80 .word a  delta is added to the low period
                                          byte (no carry), 0 = just wait,
                                          $80 = jump to a (loop)
  Arpeggio:  semis,frames ... $80 .word a  note offset from the played note,
                                          $80 = jump to a (loop)"""

SFX_DL = r"""
SOUND EFFECTS (SfxLo/SfxHi, Sfx_Play: A = priority, X = effect number)
  header: channel (0-3), speed, reg0, reg3, reg2
          An effect only starts if its priority >= the one playing on that
          channel. While it plays, the music on that channel keeps running
          but stops writing to the APU.
  then every (speed+1) frames one step:
    square/triangle:  reg0, reg3, reg2     reg3 = reg2 = 0  -> end
    noise:            reg0, period         period = 0       -> end
    any channel:      reg0, $FF                             -> restart effect
  Channels >= 4 are rejected, but Sfx_Play returns without pulling the X it
  pushed (stack bug; no effect in the table uses that path)."""

SFX_JM = r"""
SOUND EFFECTS (SfxLo/SfxHi, Sfx_Play: A = priority, X = effect number)
  header: channel (0-3), speed, reg0, reg3, reg2
          An effect only starts if its priority > the one playing on that
          channel (Dragon's Lair: >=). While it plays, the music on that
          channel keeps running but stops writing to the APU.
  then every (speed+1) frames one step:
    square/triangle:  reg0, reg3, reg2     reg3 = reg2 = 0  -> end
    noise:            reg0, period         period = 0       -> end
    any channel:      reg0, $FF                             -> restart effect
  channel >= 4 = DMC effect: DMC_START, DMC_LEN, DMC_FREQ values. It plays
          once; Sfx_Update gives the DMC back to the music when the sample
          has finished."""

SFX_AL = r"""
SOUND EFFECTS (SfxLo/SfxHi, Sfx_Play: A = priority, X = effect number)
  header: channel (0-3), initial delay, reg0, reg3, reg2
          An effect only starts if its priority >= the one playing on that
          channel. While it plays, the music on that channel keeps running
          but stops writing to the APU.
  then steps that carry their own delay (a step lasts delay+1 frames;
  different from Dragon's Lair):
    square/triangle:  delay, reg0, reg3, reg2   reg3 = reg2 = 0 -> end
    noise:            delay, reg0, period       period = 0      -> end
    any channel:      $FF                                       -> end
                      delay, reg0, $FF                          -> restart
  Sfx_Play: channel >= 4 returns without pulling X (stack bug, unused).
  Sfx_Stop: "lda mApuStatus / and ChanDisableMask,x" - result discarded."""

UNREF = r"""
Bytes the engine never reads are kept (so the file reassembles) and are
marked "unreferenced", "never read" or "never reached"."""


def cfg_dl(e):
    return _box([
        "Mark Cooksey NES sound engine - DRAGON'S LAIR (E)",
        "First version: 4 channels (2 squares, triangle, noise), no DMC.",
        "",
        "Source: Dragon's Lair (E) [!].nes, MMC3, PRG 8K banks 0 and 1",
        "(file offset $0010) at $8000-$A028. The last sound effect runs 41",
        "bytes into bank 1; the rest of bank 1 is leftover assembler source",
        "text, not included here.",
        "Reassembles byte-identically:  ca65 dragons_lair_sound.s",
        "                  ld65 -C dragons_lair_sound.cfg -o out.bin dragons_lair_sound.o",
        "",
        "ENTRY POINTS (SoundJumpTable, $8000)",
        "  $8000 Sfx_Init      silence/reset all sound effects",
        "  $8003 Sfx_Play      A = priority, X = effect number",
        "  $8006 Sfx_Update    once per frame",
        "  $8009 Music_Play    A = song number; A >= $80 stops the music",
        "  $800C Music_Update  once per frame",
        "",
        "SONG TABLE: SongLo/SongHi, 5 pointers per song:",
        "  Sq1, Sq2, Tri, Noise track, duration table.",
    ] + TRACK_FMT.split('\n') + (INSTR_FMT % '').split('\n') + SFX_DL.split('\n') + UNREF.split('\n'))


def cfg_jm(e):
    return _box([
        "Mark Cooksey NES sound engine - JOE & MAC: CAVEMAN NINJA (E)",
        "Later version: adds a 5th track for DMC (PCM samples) and DMC effects.",
        "",
        "Source: Joe & Mac - Caveman Ninja (E) [!].nes, MMC3, PRG 8K bank 11",
        "(file offset $16010) at $8000-$9FFF. The samples live in the fixed",
        "bank at $C000 (file offset $1C010): see joe_and_mac_dmc_samples.s.",
        "Reassembles byte-identically:  ca65 joe_and_mac_sound.s",
        "                  ld65 -C joe_and_mac_sound.cfg -o out.bin joe_and_mac_sound.o",
        "",
        "ENTRY POINTS (SoundJumpTable, $8000)",
        "  $8000 Sfx_Init      silence/reset all sound effects",
        "  $8003 Sfx_Play      A = priority, X = effect number",
        "  $8006 Sfx_Update    once per frame",
        "  $8009 Music_Play    A = song; $80 or $82+ = stop, $81 = re-enable",
        "                      all channels (resume)",
        "  $800C Music_Update  once per frame",
        "",
        "SONG TABLE: SongLo/SongHi, 6 pointers per song:",
        "  Sq1, Sq2, Tri, Noise, DMC track, duration table.",
    ] + TRACK_FMT.split('\n') + [
        "    $65 CMD_DMC_END                stop the DMC track",
        "    $66 CMD_DMC_REST  len          DMC rest (the sample is cut",
        "                                    whenever a DMC event is read)",
        "",
        "DMC TRACK: same 2-byte events, but",
        "    byte 0  bits 0-3 = DMC rate (DMC_FREQ); bit 6 is set from the",
        "                       sample's loop flag",
        "    byte 1  bits 4-7 = sample number (DmcSampleLo/Hi)",
        "            bits 0-3 = length index",
        "  CMD_CALL/CMD_RETURN work on the DMC track. CMD_JUMP re-enters the",
        "  tone channel routine; this is only safe because every DMC jump",
        "  target in this game starts with a command (CMD_CALL).",
        "  Sample definition: loop flag, DMC_START value, DMC_LEN value.",
    ] + (INSTR_FMT % '').split('\n') + SFX_JM.split('\n') + UNREF.split('\n'))


def cfg_al(e):
    return _box([
        "Mark Cooksey NES sound engine - ALADDIN (E)",
        "Alternate version without DMC: 4 channels, but the RAM layout keeps",
        "5-byte arrays like the DMC version. Differences from Dragon's Lair:",
        "  * tempo: Music_Update adds mTempo to mTempoAcc and only runs the",
        "    tracks on carry. There is no CLC before the add, and mTempo is",
        "    only ever set to $FF (by Music_Play).",
        "  * no arpeggio envelopes (instrument bytes +7/+8 are read and",
        "    dropped; the data they point at is still in the ROM)",
        "  * new command $65 CMD_DURTABLE .word table (the duration table",
        "    pointer is shared by all channels; no song here uses it)",
        "  * new sound effect step format with a delay per step",
        "",
        "Source: Aladdin (E) [!].nes, AxROM, 32K PRG bank 0 (file offset $506B)",
        "at $D05B-$EFD9. $D000-$D05A belongs to the game, and unrelated",
        "code starts at $EFDA.",
        "Reassembles byte-identically:  ca65 aladdin_sound.s",
        "                  ld65 -C aladdin_sound.cfg -o out.bin aladdin_sound.o",
        "",
        "ENTRY POINTS (SoundJumpTable, $D05B)",
        "  $D05B Sfx_Init      silence/reset all sound effects",
        "  $D05E Sfx_Play      A = priority, X = effect number",
        "  $D061 Sfx_Update    once per frame",
        "  $D064 Music_Play    A = song number; A >= $80 stops the music",
        "  $D067 Music_Update  once per frame",
        "",
        "SONG TABLE: SongLo/SongHi, 5 pointers per song:",
        "  Sq1, Sq2, Tri, Noise track, duration table.",
    ] + TRACK_FMT.split('\n') + [
        "    $65 CMD_DURTABLE .word table   switch the duration table",
    ] + (INSTR_FMT % '\n    (Aladdin: +7,+8 still present but ignored)').split('\n')
      + SFX_AL.split('\n') + UNREF.split('\n'))
