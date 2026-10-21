# Names and comments for mkasm.py. Keys are (bank, address).

ROUTINES = {
 (0,0x05B2):'SndTimerInit', (0,0x05C4):'PlaySongCold', (0,0x05D5):'PlaySong', (0,0x05E6):'SndUpdateFar',
 (0,0x05F0):'ReadSongByte', (0,0x0603):'ReadStreamByte', (0,0x0617):'ReadPeriodByte', (0,0x061B):'SndBankRestore',
 (0,0x0623):'BankHome', (0,0x0649):'FarPlaySong', (0,0x064E):'FarSndUpdate', (0,0x0651):'FarReturnHome',
 (9,0x67E0):'SndPlaySongCold', (9,0x67E7):'SndPlaySong', (9,0x691C):'SndUpdate', (9,0x69D3):'SndRowTick',
 (9,0x69F0):'SndRunChannels', (9,0x6A29):'SndUnusedRet', (9,0x6A2A):'SndChanRow', (9,0x6A3B):'SndReadEvent',
 (9,0x6A67):'SndEndRow', (9,0x6A71):'SndEventNote',
 (9,0x6ACE):'Cmd_Macro', (9,0x6AF8):'Cmd_AutoPWM', (9,0x6B21):'Cmd_AutoPan', (9,0x6B42):'Cmd_WaveDist',
 (9,0x6BAF):'Cmd_WaveMix', (9,0x6C40):'Cmd_StopSample', (9,0x6C52):'Cmd_ResetVib', (9,0x6C61):'Cmd_WavePreset',
 (9,0x6C95):'Cmd_FineTune', (9,0x6CAD):'Cmd_PlaySample', (9,0x6CD4):'Cmd_Arpeggio', (9,0x6CF7):'Cmd_Glissando',
 (9,0x6D11):'Cmd_PortaSrc', (9,0x6D30):'Cmd_PortaRate', (9,0x6D40):'Cmd_Vibrato', (9,0x6D68):'Cmd_RestartEnv',
 (9,0x6D82):'SndNoteOff', (9,0x6D91):'Cmd_RetrigDelay', (9,0x6DA0):'Cmd_TrigDelay', (9,0x6DAF):'Cmd_UseDuration',
 (9,0x6DD1):'Cmd_Pan', (9,0x6DFF):'Cmd_Sweep', (9,0x6E1F):'Cmd_EnvVolume', (9,0x6E43):'Cmd_EnvRate',
 (9,0x6E67):'Cmd_Duration', (9,0x6E8B):'Cmd_Duty', (9,0x6EAF):'Cmd_Shuffle', (9,0x6EE0):'Cmd_Transpose',
 (9,0x6EF2):'Cmd_Speed', (9,0x6EFD):'Cmd_End', (9,0x6F22):'SndReadSequence', (9,0x6F4F):'SndSeqNext',
 (9,0x6FE7):'SndLoadSongHeader', (9,0x701A):'SndStartPattern', (9,0x7081):'SndUpdateChannel',
 (9,0x70F2):'SndChanArpeggio', (9,0x7126):'SndChanPortamento', (9,0x7192):'SndChanWave',
 (9,0x71E1):'SndChanPan', (9,0x7293):'SndChanEnvelope', (9,0x72C6):'SndChanSweep', (9,0x72DA):'SndChanFreq',
 (9,0x7420):'SndChanNRx1',
}

BLOCKS = {
 (0,0x05B2): """=============================================================================
Bank 0 interface
=============================================================================
SndTimerInit: tracker leftover. Programs TMA/TAC for the tracker's sample
timer but disables the timer interrupt (the $50 vector is a bare RETI), and
clears hSamplePlaying. Called once at boot.""",
 (0,0x05C4): """PlaySongCold: a = song. Resets the APU (NR52 off/on) then starts the song.
Only called at boot (song 0, an empty "TEMPLATE" song).""",
 (0,0x05D5): """PlaySong: a = song. Starts a song without the NR52 reset. Used by the game
through FarPlaySong ($0649) for every song change.""",
 (0,0x05E6): """SndUpdateFar: one driver update. Called from the VBlank tail ($0244) on
every second frame (wSndTickToggle alternates), i.e. ~29.9 Hz.""",
 (0,0x05F0): """ReadSongByte: a = b = [hl+] from the song's bank, back to bank 9.""",
 (0,0x0603): """ReadStreamByte: a = b = [de], de++ from the song's bank (wSongBank).
ReadPeriodByte enters at $0606 with a = $0A to read the period table.""",
 (0,0x061B): """SndBankRestore: selects bank 9. In the tracker, the DC command and CH3
retrigger called a sample player here; this game left only the bank switch.""",
 (0,0x0623): """BankHome: game's home bank ($3F).""",
 (0,0x0649): """Far-call wrappers used by game code (they return with bank $3F selected).
FarSndUpdate has no callers.""",
 (9,0x67E0): """=============================================================================
SndPlaySongCold / SndPlaySong
Resets every channel and global, loads preset 0 into the wave buffer and
wave RAM, looks up the song's bank, reads the song header and the first
sequence entries (up to and including the first pattern number).
=============================================================================""",
 (9,0x691C): """=============================================================================
SndUpdate: one update (~29.9 Hz).
  inc = max(1, (wSpeed2 * ShuffleTable[ptr]) >> 5)   ; low byte only
  wTickAcc += inc; on carry a row is due:
    - advance the shuffle phase by ShuffleRateTable[rate]
    - every channel gets CH_ROWS += 1 and its trigger-delay counter reloaded
  Each channel is then updated (SndUpdateChannel), whether or not a row is
  due. If any channel hit FF (end of pattern) the sequence is read and the
  row is re-run at once for all four channels.
=============================================================================""",
 (9,0x6A2A): """SndChanRow: read one row of channel c's stream.
If CH_WAIT is nonzero the row is skipped. Otherwise events are read until a
note ($01-$48, CH4 $01-$7F), note off ($00), empty row ($49-$7F) or wait
($80-$BF). $C0-$FF go through CommandTable and continue at SndReadEvent.""",
 (9,0x6A71): """Note byte. CH4: bit 6 selects the 7-bit LFSR (stored in CH_CTRL bit 0) and
the low 6 bits are the noise index. CH1-3: $49-$7F only end the row.
Pitch = $4000 + n*$80. With portamento active only the target and the
note pitch are set and CH_PITCH keeps sliding.""",
 (9,0x6ACE): """D3 lo hi: call a macro at wPatTable + hi:lo, one level. The return address
is kept in CH_MACRO_RET; a second D3 inside a macro is ignored (its operand
is still skipped). No song uses macros.""",
 (9,0x6AF8): """D4 steps rate: auto-PWM (CH1/2). On CH3/CH4 only ONE operand byte is
skipped, so a D4 there would desync the stream (never happens in the data).""",
 (9,0x6B21): """D5 steps rate: auto-pan.""",
 (9,0x6B42): """D6 n: run every nibble of wWaveBuf through WaveDistTables[n] (CH3).
On other channels TWO bytes are skipped for this one-operand command
(desync; not in the data).""",
 (9,0x6BAF): """D7 preset step: average wWaveBuf with WavePresets[preset] resampled by
step/32 nibbles per output nibble (CH3). Reads can run past the preset;
WavePresetGuard covers the overrun.""",
 (9,0x6C40): """D8: stop sample. The tracker called its sample player here; now a no-op.""",
 (9,0x6C61): """DA n: copy WavePresets[n] to wWaveBuf and flag a wave reload (CH3).""",
 (9,0x6CAD): """DC n: play sample (CH3). Sets CH_CTRL bit 1 and calls SndBankRestore,
which no longer plays anything. While bit 1 is set, retriggers also go to
the stub instead of restarting the note. Not used by any song.""",
 (9,0x6CD4): """DD s12 s34 rate: arpeggio. rate 0 switches it off and resets the
effective transpose to the track transpose.""",
 (9,0x6D11): """DF n: portamento source. Sets the current and note pitch to note n
without triggering; the next note slides from there.""",
 (9,0x6D40): """E1 depth rate: vibrato. Depth selects a 128-byte table (low bit goes to
bit 7 of the pointer's low byte), rate is the phase step.""",
 (9,0x6D82): """$00: note off. Sets CH_DIRTY bit 7: this update writes the channel's NR51
bits as 0. The note keeps running underneath; the next note restores pan.""",
 (9,0x6DD1): """FB p: pan for this channel = p & ($11 << channel).""",
 (9,0x6EAF): """FC phase dr: shuffle (stream form; the sequence form is at $6F92).
Phase = phase<<4 (12-bit), rate = dr & $0F, depth = dr >> 4.""",
 (9,0x6EFD): """FF: end of pattern. Inside a macro: return. Otherwise flag the sequence
advance and end the row; the remaining channels still read this row.""",
 (9,0x6F22): """=============================================================================
SndReadSequence: clears every channel's macro return and wait count, then
reads sequence bytes:
  FB p      song pan        FC ph dr  shuffle      FD t  song transpose
  FE s      speed           FF        restart song (reload header, read again)
  00-FA n   start pattern n (sets all four stream pointers)
=============================================================================""",
 (9,0x6FE7): """SndLoadSongHeader: song header = dw seq-start, dw pattab-start, dw length,
db patterns, then a 3-byte-plus name block ending in $FF (ignored here).""",
 (9,0x701A): """Start pattern n: pattern table entry n = four words, each an offset from the
pattern table to that channel's stream.""",
 (9,0x7081): """=============================================================================
SndUpdateChannel: a = channel base (low byte). Runs every update.
  1. rows / trigger delay / retrigger
  2. arpeggio step          3. portamento
  4. CH3 wave upload        5. pan (note off, auto-pan, pan change)
  6. NRx2                   7. NR10 (CH1)
  8. frequency (transposes, glissando, vibrato, fine tune, period lookup;
     CH4: noise index -> NR43)
  9. NRx1 (auto-PWM or change)
 10. clear CH_DIRTY
=============================================================================""",
 (9,0x70F2): """Arpeggio: every CH_ARP_RATE updates rotate the four steps by one nibble;
CH_TRANSPOSE = CH_BASE_TRANSPOSE + top nibble.""",
 (9,0x7126): """Portamento: move CH_PITCH toward CH_PORTA_TGT by 2*rate per update.
Bug: the high-byte compare at $7148 is 'jr nc' where 'jr nz' was meant, so
when the high bytes are equal the slide always subtracts, lands below the
target and snaps to it. A rising slide therefore jumps to the target as soon
as the high bytes match: to an odd note (pitch low byte $80) the last
semitone is skipped in one update. Falling slides are unaffected.
(Confirmed in an emulator: $51F8, $5200, then $5280.)""",
 (9,0x7192): """CH3: upload wWaveBuf to wave RAM (NR30 off around it) when flagged.""",
 (9,0x71E1): """Pan: note off -> 0; auto-pan active -> next step; pan changed -> CH_PAN.""",
 (9,0x72DA): """Frequency write, done when the freq flag is set or arpeggio or vibrato is
active (both of those also set the NRx1 flag). Arpeggio is detected by
CH_ARP (the current and next step) being nonzero, so an update whose
current and next steps are both 0 writes nothing and the previous step's
pitch is held: steps 0,C,C,0 sound as 0,C,C,C (confirmed in an emulator).
Vibrato or portamento on the channel hides this.""",
 (9,0x7420): """NRx1: auto-PWM (CH1/2) or NRx1 change, then clear the dirty flags.""",
}

C = {}
def c(bank, addr, text): C[(bank, addr)] = text

# bank 0
c(0,0x05B2,'timer interrupt off'); c(0,0x05BC,'4096 Hz / ($100-$E0) = 128 Hz')
c(0,0x05C4,'wSongNum = a'); c(0,0x05C8,'hold off the next update')
c(0,0x05ED,'tail call'); c(0,0x0606,'ReadPeriodByte joins here')
c(0,0x0617,'bank $0A = PeriodTable')

# bank 9: init
c(9,0x67E1,'APU off/on'); c(9,0x67E7,'warm entry'); c(9,0x67E9,'NR50 = $77')
c(9,0x67EB,'NR51 = $DE'); c(9,0x67F0,'song transpose 0'); c(9,0x67F3,'row accumulator 0')
c(9,0x67F6,'clear $CA30-$CAFF (all four channel structs)')
c(9,0x680F,'CH_DELAY_CNT = $FF'); c(9,0x681D,'pitch = $4000 (CH1-3: note 0)')
c(9,0x683A,'CH4 pitch = $5000 (noise index 32)'); c(9,0x6845,'vibrato ptr = VibratoTables, phase 0')
c(9,0x6861,'CH_CTRL = $40: length enable'); c(9,0x686F,'NR10 = 0')
c(9,0x6876,'default pans: CH1 L, CH2 R, CH3/4 both'); c(9,0x688A,'default NRx1')
c(9,0x68A6,'default NRx2: $F3, $73, NR32 $20, $83'); c(9,0x68C2,'preset 0 -> wWaveBuf and wave RAM')
c(9,0x68DA,'wShufflePtr = ShuffleTable (depth 0, phase 0)'); c(9,0x68E4,'speed $30 (stored doubled)')
c(9,0x68EB,'wSongBank = SongBankTable[song]'); c(9,0x68F9,'header + first sequence entries')
c(9,0x68FC,'pre-subtract one shuffle step: the first row adds it back')

# update
c(9,0x6924,'c = shuffle multiplier ($20 = x1)'); c(9,0x6925,'b = speed*2')
c(9,0x692C,'hl = b * c (c < 64, shift-and-add)'); c(9,0x6992,'hl >>= 5')
c(9,0x69A6,'at least 1'); c(9,0x69AB,'wTickAcc += l'); c(9,0x69B2,'no carry: no row this update')
c(9,0x69B4,'advance the shuffle phase'); c(9,0x69D3,'clear sequence-advance flag')
c(9,0x69D7,'each channel: CH_ROWS++, CH_DELAY_CNT = CH_TRIG_DELAY')
c(9,0x69FA,'never set in this game'); c(9,0x6A1E,'a channel hit FF?')
c(9,0x6A24,'next sequence entry, then redo the row'); c(9,0x6A29,'unreachable')

# row reader
c(9,0x6A31,'CH_WAIT'); c(9,0x6A35,'skip this row'); c(9,0x6A3B,'a = b = next byte')
c(9,0x6A3E,'$00: note off'); c(9,0x6A42,'$01-$7F: note'); c(9,0x6A46,'$C0-$FF: command')
c(9,0x6A4A,'$80-$BF: CH_WAIT = n, end row'); c(9,0x6A66,'CommandTable[b-$C0]')
c(9,0x6A6D,'save stream pointer'); c(9,0x6A92,'CH1-3: $49-$7F end the row')
c(9,0x6A97,'portamento active?'); c(9,0x6AA1,'no: write the current pitch')
c(9,0x6AA6,'CH_NOTE_PITCH and (target or current) = $4000 + n*$80')
c(9,0x6AB8,'CH_CTRL: trigger, clear sample bit'); c(9,0x6AC2,'dirty: freq, pan, NRx1, (b4)')
c(9,0x6ADD,'already in a macro: ignore'); c(9,0x6AEA,'de = wPatTable + offset')
c(9,0x6AFF,'CH3/4: skips 1 of 2 operands (quirk)'); c(9,0x6B13,'rate 0: write duty now')
c(9,0x6B49,'non-CH3: skips 2 bytes for 1 operand (quirk)'); c(9,0x6B69,'hl = WaveDistTables + n*8')
c(9,0x6BD2,'hl = WavePresets + preset*16'); c(9,0x6C48,'tracker: call StopSample')
c(9,0x6C5A,'keep pointer bit 7, phase = 0'); c(9,0x6C83,'hl = WavePresets + n*16')
c(9,0x6C9C,'CH4: skip operand'); c(9,0x6CBE,'CH_CTRL bit 1: sample active')
c(9,0x6CCD,'tracker: call PlaySample'); c(9,0x6CEE,'rate 0: transpose = base')
c(9,0x6D04,'CH_CTRL bit 0 = glissando (CH4: LFSR width)')
c(9,0x6D1D,'pitch = $4000 + n*$80 -> CH_PITCH and CH_NOTE_PITCH')
c(9,0x6D4B,'depth bit 0 -> pointer bit 7'); c(9,0x6D56,'pointer high = $40 + depth/2')
c(9,0x6D71,'dirty |= $17'); c(9,0x6D7B,'trigger on next freq write')
c(9,0x6DB8,'0 = infinite, else length enable'); c(9,0x6DCA,'dirty: NRx2, b4')
c(9,0x6DE3,'mask $11 << channel'); c(9,0x6E02,'CH1 only')
c(9,0x6E2C,'CH3: whole byte to NR32'); c(9,0x6E33,'others: high nibble')
c(9,0x6E57,'others: low nibble'); c(9,0x6E7B,'others: keep duty'); c(9,0x6EA0,'keep length')
c(9,0x6EAF,'phase byte'); c(9,0x6EC3,'depth<<4 | rate'); c(9,0x6EF5,'stored doubled')
c(9,0x6F0D,'not in a macro: end of pattern'); c(9,0x6F19,'return from macro')

# sequence
c(9,0x6F52,'FB: song pan'); c(9,0x6F92,'FC: shuffle'); c(9,0x6FC7,'FD: song transpose')
c(9,0x6FD4,'FE: speed'); c(9,0x6FE3,'FF: loop'); c(9,0x6FE7,'hl = SongPtrTable[song]')
c(9,0x6FFB,'wSeqPtr = start + hdr[0]'); c(9,0x7009,'wPatTable = start + hdr[2]')
c(9,0x7017,'and read the sequence again'); c(9,0x701B,'save sequence pointer')
c(9,0x7023,'hl = wPatTable + n*8'); c(9,0x7073,'CH_ROWS = 0 on all channels')

# channel update
c(9,0x708B,'rows pending?'); c(9,0x7091,'trigger-delay countdown')
c(9,0x7096,'expired: reload with retrigger period, CH_ROWS--')
c(9,0x709A,'read the row'); c(9,0x709D,'pattern ended: stop here')
c(9,0x70AD,'retrigger period'); c(9,0x70B1,'count down'); c(9,0x70B4,'reload')
c(9,0x70BA,'sample active: replay the (stubbed) sample instead')
c(9,0x70D3,'retrigger the note'); c(9,0x70E0,'CH_PITCH = CH_NOTE_PITCH')
c(9,0x70F6,'arpeggio rate'); c(9,0x7101,'rotate the 16-bit step word left by 4')
c(9,0x7119,'current step = top nibble'); c(9,0x7124,'CH_TRANSPOSE = base + step')
c(9,0x712A,'portamento rate'); c(9,0x7131,'bc = rate*2')
c(9,0x7148,'BUG: always taken (should be jr nz)'); c(9,0x714A,'unreachable')
c(9,0x7152,'slide down'); c(9,0x7165,'slide up'); c(9,0x7177,'reached: pitch = target')
c(9,0x718A,'dirty: freq, NRx1'); c(9,0x719B,'wave flag'); c(9,0x719F,'always 0 here')
c(9,0x71E6,'note off: pan bits 0'); c(9,0x71F2,'auto-pan rate')
c(9,0x7203,'step bits 7,6 (L,R) -> NR51 bits 4,0'); c(9,0x724F,'pan changed?')
c(9,0x7298,'NRx2 changed?'); c(9,0x72CF,'CH1 sweep changed?')
c(9,0x72DF,'freq flag?'); c(9,0x72E7,'arpeggio active? (tests the step bytes)')
c(9,0x72EF,'vibrato active?'); c(9,0x72F1,'nothing to do: skip to NRx1')
c(9,0x72FC,'de = song transpose + track transpose (signed)'); c(9,0x7323,'de = semitones * $80')
c(9,0x732D,'+ CH_PITCH'); c(9,0x733C,'glissando: round to the nearest semitone')
c(9,0x734C,'vibrato: phase += rate (7 bits)'); c(9,0x7366,'+ VibratoTables entry')
c(9,0x736F,'CH4: noise'); c(9,0x7373,'index = (pitch - $4000) / $80, clamped 0-63')
c(9,0x738F,'NR43 = NoiseTable[index] | LFSR width'); c(9,0x7398,'NR44 = trigger | length enable')
c(9,0x739F,'+ fine tune * 2'); c(9,0x73BC,'clamp high: BUG, only when low byte >= $7E as well')
c(9,0x73CE,'clamp low to $4000'); c(9,0x73DD,'trigger and length-enable bits')
c(9,0x73E1,'period from PeriodTable (bank $0A)'); c(9,0x7403,'CH3 (skipped while a sample plays)')
c(9,0x7414,'retrigger period 0: clear the trigger bit')
c(9,0x7421,'CH1/2 with auto-PWM?'); c(9,0x7430,'step counter'); c(9,0x7433,'rotate steps by 2 bits')
c(9,0x744B,'NRx1 changed?'); c(9,0x747D,'clear CH_DIRTY')

COMMENTS = C

OPERAND_OVERRIDE = {
 (9,0x681D):'ld a,HIGH(PeriodTable)', (9,0x6853):'ld a,HIGH(VibratoTables)',
 (9,0x68DA):'ld a,LOW(ShuffleTable)', (9,0x68DF):'ld a,HIGH(ShuffleTable)',
 (9,0x6ED1):'add LOW(ShuffleTable)', (9,0x6ED6):'ld a,HIGH(ShuffleTable)',
 (9,0x6FB8):'add LOW(ShuffleTable)', (9,0x6FBD):'ld a,HIGH(ShuffleTable)',
 (9,0x6AB3):'add HIGH(PeriodTable)', (9,0x6D25):'add HIGH(PeriodTable)',
 (9,0x6D57):'add HIGH(VibratoTables)',
}
