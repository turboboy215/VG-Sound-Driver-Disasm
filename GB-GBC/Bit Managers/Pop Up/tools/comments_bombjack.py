# executed inside gen_bombjack.py (g = Gen)
B = g.blocks
C = g.comments
O = g.operand

g.labels.pop(0x5F3F, None)
g.labels[0x5F41] = 'SfxTable'
g.labels[0x598B] = 'NoiseSeq4_unused'
g.labels[0x5E3D] = 'Unused_5E3D'
g.labels.pop(0x5E35, None)
g.labels[0x5E35] = 'WriteVolume_Ch2'
g.labels[0x7346] = 'InstrTable1'
g.labels[0x7932] = 'InstrTable2'
g.labels.pop(0x7344, None)
g.labels.pop(0x7930, None)
g.labels[0x740C] = 'ArpTable1'
g.labels[0x79E2] = 'ArpTable2'

O.update({
    0x55B0: 'LOW(CmdTable)', 0x55B3: 'HIGH(CmdTable)',
    0x5680: 'LOW(CmdTable)', 0x5683: 'HIGH(CmdTable)',
    0x5D05: 'LOW(PeriodTable)', 0x5D08: 'HIGH(PeriodTable)',
    0x5E44: 'LOW(Ch3VolTable)', 0x5E47: 'HIGH(Ch3VolTable)',
    0x5EC7: 'LOW(SfxTable - 2)', 0x5ECA: 'HIGH(SfxTable - 2)',
    0x5998: 'HIGH(NoiseSeq1_NR43)', 0x599D: 'LOW(NoiseSeq1_NR43)',
    0x59A2: 'HIGH(NoiseSeq1_NR42)', 0x59A7: 'LOW(NoiseSeq1_NR42)',
    0x59B0: 'HIGH(NoiseSeq2_NR43)', 0x59B5: 'LOW(NoiseSeq2_NR43)',
    0x59BA: 'HIGH(NoiseSeq2_NR42)', 0x59BF: 'LOW(NoiseSeq2_NR42)',
    0x59CE: 'HIGH(NoiseSeq3_NR43)', 0x59D3: 'LOW(NoiseSeq3_NR43)',
    0x59D8: 'HIGH(NoiseSeq3_NR42)', 0x59DD: 'LOW(NoiseSeq3_NR42)',
    0x608E: 'LOW(InstrTable1 - 2)', 0x6093: 'HIGH(InstrTable1 - 2)',
    0x6098: 'LOW(ArpTable1)', 0x609D: 'HIGH(ArpTable1)',
    0x7457: 'LOW(InstrTable2 - 2)', 0x745C: 'HIGH(InstrTable2 - 2)',
    0x7461: 'LOW(ArpTable2)', 0x7466: 'HIGH(ArpTable2)',
})

B[0x0316] = 'Game VBlank handler (from $025F): SndUpdate runs once per frame (59.73 Hz).'
B[0x54EE] = '''SndUpdate: NR52 = $80, NR50 fade, tick the four pages (Ch1 $C4xx, Ch2 $C5xx,
Ch3 $C6xx, Sfx $C7xx), drum sequencer, noise sequence, then output.'''
B[0x5517] = '''DrumTick: every wDrumTempo ticks one drum pattern step; then the noise sequence.'''
B[0x5521] = '''ChannelTick (h = page): skipped while field $10 = 0. Effects run before the
length counter; ReadStream runs when it reaches 0.'''
B[0x5544] = '''ReadStream (de = stream): wInInstr = $C9 while an instrument macro runs.
Bytes < $60 are notes: store the note, the stream pointer, set the period, restart
the arpeggio, hardware envelope, length, vibrato, flags and volume, split the envelope.'''
B[0x5597] = '''Command ranges: $C7+ length, $B7+ vol/env, $A7+ volume, $98+ arpeggio,
$7E+ instrument, $60-$7D table.'''
B[0x5620] = '''Cmd_Instrument ($7E-$97): clears vibrato/arpeggio/glide/auto-pan/auto-duty/
hw envelope, centres the pan and sets 50 % duty, then runs the macro from the
song's instrument table (wInstrTable - 2 + 2*(byte - $7D)) until $66 or $68.'''
B[0x56D3] = '''Not in CmdTable (left over from version 1: CHORUS_ON / CHORUS_OFF). The
byte at Unused_ChorusOff-1 is the last byte of Unused_ChorusOn.'''
B[0x56DD] = '''PatReturn: NEXT inside a PAT_CALL returns to the saved pointer (fields $3B/$3C, one level).'''
B[0x5705] = '''CheckRelease: when RELEASE is set and the ticks left = field $39 (and the next
byte isn't WAIT): pulse channels load env2 = field $3A into NRx2 (via $31/$32);
CH3 takes the hi nibble of $3A as its volume. Happens once per note (flag bit 2).'''
B[0x57F0] = '''StopAll: drums, noise sequence and fade off, reset all four pages, wTranspose = 0, NR42 = 0.'''
B[0x581B] = '''Cmd_End ($66): centre pan, reload the music wave if this is the SFX page, reset the page.'''
B[0x5827] = '''ResetChannel (h = page): clear the page and write NRx2 = 0 / NRx4 = $80.
The test at $584A-$5853 was meant to skip the write on the SFX page while Ch3
plays, but "ld a,[hl]" sets no flags: Z still holds "h = $C7", so it never skips.
Resetting Ch3 or Sfx bumps wShNR32 (so the next CH3 volume write isn't skipped).'''
B[0x58DB] = '''DrumStep: next byte of the drum pattern: $FF loops, 0 = nothing,
1-7 = drum sounds (1-3 noise sequences, 4-7 single noise hits).'''
B[0x5927] = '''NoiseSeqTick: one step per tick of a noise sequence (NR43 / NR42 pairs,
$FF ends), NR44 = $80 each step.'''
B[0x5A74] = '''Cmd_HwEnv ($72): hardware envelope mode: env is written to NRx2 at note on;
optionally after `ticks` ticks env2 is written.'''
B[0x5AA8] = '''Cmd_AutoPan ($73 n): every n ticks cycle the pan C, R, C, L.'''
B[0x5ADD] = '''Cmd_AutoDuty ($74 n): every n ticks cycle the duty 75, 12.5, 75, 50 %.'''
B[0x5B0E] = '''StartFade (a = speed, hl = NR50 table): one table byte every speed+1 ticks,
$68 loops, $FF ends. While no fade runs (and hGameFF99 = 0) NR50 is forced back
to $77 every tick unless it is 0.'''
B[0x5B7E] = '''Cmd_Wave ($75 w): Ch3: remember the wave, load it unless the SFX page is playing.
SFX page: load it. The load turns the DAC off, copies 16 bytes, and restarts
CH3 with wShFreqHi3 | $80.'''
B[0x5BE2] = '''SndInit: copy the register indices into the pages, clear the rest, NR51 = $FF, StopAll.'''
B[0x5C29] = '''Period table: 81 entries from C2 (same as version 1).'''
B[0x5CCB] = '''DoArp: next arpeggio table entry added to the note; $68 restarts, $FF holds.'''
B[0x5CEE] = '''SetNoteFreq (a = note): index = note - 12 + wTranspose (not on the SFX page) +
field $0F (channel transpose) -> PeriodTable.'''
B[0x5D19] = '''DoEnvelope: hardware mode: count down field $29 then write env2. Software mode:
attack ($12/$13/$1A/$1B), decay ($15/$16/$1C/$1D), release ($19/$18/$1E/$1F).'''
B[0x5D85] = '''StartMusicChN (de = order list).'''
B[0x5DA5] = '''OutputAll: Ch1, Ch2, then the SFX page if active, else Ch3 - all to the register
addresses in fields $06/$08/$0A (CH1/CH2/CH3 only).'''
B[0x5DB9] = '''OutputChannel: NRx3 = period lo; NRx4 = period hi (no trigger) when it changed
(shadow wShFreqHi + page - $C4; the SFX page uses wShNR32 as its shadow!).
Software volume: pulse channels get NRx2 = vol << 4 and a retrigger on EVERY tick;
CH3 gets NR32 from Ch3VolTable when it changed. Hardware envelope: NRx2 and a
trigger only when field $32 is set.'''
B[0x5E69] = '''PlaySfx (a = id 1-14): lower ids have priority (a request is ignored while a
lower id plays). Ids 1 and 4 pan with NR50 by an object position when hGameFF82 != 0;
ids $0B, $0C, $0E (and 1/4 when hGameFF82 = 0) set NR50 = $77. The stream starts
on the SFX page and its first tick is parsed inside the call.'''
B[0x5EDF] = '''Wave tables (16 bytes each).'''
B[0x5F2F] = '''NR50 values by position for the panned SFX (left .. right).'''
B[0x5F41] = '''Sound table: ids 1-14 (code reads SfxTable - 2 + 2*id).'''
B[0x6069] = '''Channel init blocks copied to fields $00-$0B: fields $06/$08/$0A = register
addresses of NRx3/NRx4/NRx2. Ch3's block is used for the SFX page too.'''
B[0x608D] = '''Shared tail of PlaySong1-4: instrument table 1, arpeggio table 1, NR50 = $77.'''
B[0x60F2] = '''Song entry points used by the game.'''
B[0x60FB] = '''PlaySong1: StopAll (twice); the channels only start while hGameFF82 = 0.'''
B[0x7346] = '''Instrument table 1 (songs 1-4): instrument n = entry n.'''
B[0x740C] = '''Arpeggio table 1.'''
B[0x743E] = '''PlaySong5: uses instrument table 2 / arpeggio table 2.'''
B[0x7932] = '''Instrument table 2 (song 5).'''
B[0x79E2] = '''Arpeggio table 2.'''
B[0x78BA] = '''Pattern that no order list uses.'''
B[0x7435] = '''Drum pattern that nothing uses.'''
B[0x598B] = '''Unused (looks like a 4th noise sequence: NR43 07 03 00 FF, NR42 70 60 41).'''
B[0x5E3D] = '''Dead bytes (pop hl / ret).'''

for _k in list(O):
    if _k not in g.code and (_k - 1) in g.code:
        O[_k - 1] = O.pop(_k)
    elif _k not in g.code:
        print('operand override not on an instruction:', hex(_k))
