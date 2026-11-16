"""Paperboy (1986 Elite): the middle Mark Cooksey C64 driver.

Same pattern idea as Bomb Jack (length + note byte pairs, commands from $C8),
but one player loop indexed by voice, a command jump table, per-voice
effects, drum macros ($F0+), PAL tuning, and a sound effect player."""

from core import h2, h4
from common import var, bytes_item, words_item, lohi_item, code, name_cmp_chain

TITLE = 'Paperboy'
SEMI = ['---', 'C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-', '?D', '?E', '?F']


def notename(n):
    s = n & 15
    if s == 0:
        return 'rest'
    return '%s%d' % (SEMI[s], (n >> 4) & 7)


A3 = '3 voices'
VARS = [
    (0xA5FE, 'mPwSweepOn', 1, 'pulse sweep: bit n = voice n+1 (C_PWSWEEP)', ['VARIABLES (values are the ripper\'s snapshot). Arrays hold voices 1-3.']),
    (0xA5FF, 'mPwSpeed', 3, 'pulse sweep: calls per step', None),
    (0xA602, 'mPwTimer', 3, None, None),
    (0xA605, 'mPwStartHi', 3, 'pulse sweep start (C_PWRANGE)', None),
    (0xA608, 'mPwStartLo', 3, None, None),
    (0xA60B, 'mPwLimitHi', 3, 'back to the start when the high byte reaches this', None),
    (0xA60E, 'mPwLimitLo', 3, '(never read)', None),
    (0xA611, 'mPwStepHi', 3, 'added each step', None),
    (0xA614, 'mPwStepLo', 3, None, None),
    (0xA617, 'mPwDelaySet', 3, 'delay at each note', None),
    (0xA61A, 'mPwDelay', 3, None, None),
    (0xA61D, 'mPwResetOn', 1, 'bit n: restart the pulse width at each note', None),
    (0xA61E, 'mTrillOn', 1, 'octave trill: bit n = voice n+1 (C_TRILL)', None),
    (0xA61F, 'mTrillSpeed', 3, None, None),
    (0xA622, 'mTrillTimer', 3, None, None),
    (0xA625, 'mTrillUp', 3, '1 = an octave up now', None),
    (0xA628, 'mTrillDelaySet', 3, None, None),
    (0xA62B, 'mTrillDelay', 3, None, None),
    (0xA62E, 'mVibOn', 1, 'vibrato: bit n = voice n+1 (C_VIBRATO)', None),
    (0xA62F, 'mVibSpeed', 3, 'calls per phase', None),
    (0xA632, 'mVibTimer', 3, None, None),
    (0xA635, 'mVibDepthHi', 3, None, None),
    (0xA638, 'mVibDepthLo', 3, None, None),
    (0xA63B, 'mVibDelaySet', 3, None, None),
    (0xA63E, 'mVibDelay', 3, None, None),
    (0xA641, 'mBaseFreqHi', 3, 'note frequency without vibrato', None),
    (0xA644, 'mBaseFreqLo', 3, None, None),
    (0xA647, 'mVibPhase', 3, '0 base, 1 +depth, 2 base, 3 -depth', None),
    (0xA64A, 'mSlideOn', 1, 'slide: bit n = voice n+1 (C_SLIDE)', None),
    (0xA64B, 'mSlideSpeed', 3, 'calls per step (C_SLIDESTEP)', None),
    (0xA64E, 'mSlideTimer', 3, None, None),
    (0xA651, 'mSlideStepHi', 3, None, None),
    (0xA654, 'mSlideStepLo', 3, None, None),
    (0xA657, 'mSlideDelaySet', 3, None, None),
    (0xA65A, 'mSlideDelay', 3, None, None),
    (0xA65D, 'mSlideUp', 3, '1 = slide up', None),
    (0xA660, 'mSlideToHi', 3, 'slide target', None),
    (0xA663, 'mSlideToLo', 3, None, None),
    (0xA666, 'mSlideArmed', 1, 'set by every note (any voice); the slide only snaps to the target and switches off while it is set', None),
    (0xA667, 'mWaveAltOn', 1, 'waveform alternation: bit n = voice n+1 (C_WAVEALT)', None),
    (0xA668, 'mWaveAltSpeed', 3, None, None),
    (0xA66B, 'mWaveAltTimer', 3, None, None),
    (0xA66E, 'mWaveAltDelaySet', 3, None, None),
    (0xA671, 'mWaveAltDelay', 3, None, None),
    (0xA674, 'mWaveA', 3, 'first waveform', None),
    (0xA677, 'mWaveB', 3, 'second waveform', None),
    (0xA67A, 'mWaveAltPhase', 3, None, None),
    (0xA67D, 'mCtrl', 3, 'last control value written (bit 0 = gate)', None),
    (0xA680, 'mModeVol', 1, 'shadow SID_MODE_VOL', None),
    (0xA681, 'mResFilt', 1, 'shadow SID_RES_FILT', None),
    (0xA682, 'mCutoffHi', 1, 'shadow SID_FC_HI', None),
    (0xA683, 'mCutoffLo', 1, 'shadow SID_FC_LO', None),
    (0xA684, 'mWave', 3, 'control register without the gate (C_WAVE)', None),
    (0xA687, 'mFreqHi', 3, 'frequency written to the SID', None),
    (0xA68A, 'mFreqLo', 3, None, None),
    (0xA68D, 'mAD', 3, None, None),
    (0xA690, 'mSR', 3, None, None),
    (0xA693, 'mPwHi', 3, None, None),
    (0xA696, 'mPwLo', 3, None, None),
    (0xA699, 'mOutputOn', 1, 'bit n: voice n+1 writes the SID', None),
    (0xA69A, 'mTrackOn', 1, 'bit n: voice n+1 reads its pattern', None),
    (0xA69B, 'mSpeed', 1, 'calls per tick (C_SPEED)', None),
    (0xA69C, 'mSpeedCount', 1, None, None),
    (0xA69D, 'mDuration', 3, 'ticks left of the note', None),
    (0xA6A0, 'mDrum', 3, 'drum playing: number + 1, 0 = none', None),
    (0xA6A3, 'mRegOfs', 1, 'current voice: SID register offset', None),
    (0xA6A4, 'mVoiceBit', 1, 'current voice: 1, 2, 4', None),
    (0xA6A5, 'mNoteHi', 1, 'NoteToFreq result', None),
    (0xA6A6, 'mNoteLo', 1, None, None),
    (0xA6A7, 'mReleaseAt', 3, 'gate off when this many ticks are left (C_RELEASE)', None),
    (0xA6AA, 'mSaveX', 1, None, None),
    (0xA6AB, 'mNoteTemp', 1, None, None),
    (0xA6AC, 'mOrderHi', 3, 'order list pointers', None),
    (0xA6AF, 'mOrderLo', 3, None, None),
    (0xA6B2, 'mOrderIdx', 3, None, None),
    (0xA6B5, 'mVoice', 1, 'current voice 0-2', None),
    (0xA6B6, 'mCmdByte', 1, None, None),
    (0xA6B7, 'mDrumOfs', 3, 'drum number * 2', None),
    (0xA6BB, 'mDrumPtrHi', 3, 'drum data', None),
    (0xA6BE, 'mDrumPtrLo', 3, None, None),
    (0xA6C1, 'mDrumLen', 3, 'ticks left of the drum', None),
    (0xA6C4, 'mDrumPos', 3, 'offset of the next drum step', None),
    (0xA6C7, 'mDrumSpeed', 1, 'calls per drum step (C_DRUMSPEED)', None),
    (0xA6C8, 'mDrumCount', 1, None, None),
    (0xA6C9, 'mSaveY', 1, None, None),
    (0xA6CA, 'mDrumStepping', 3, '1 while the drum steps run', None),
    (0xA6CD, 'mCmdVector', 2, 'JMP (mCmdVector)', None),
    (0xB108, 'sRequest', 1, 'effect to start (set by the game), 0 = none', ['SOUND EFFECT VARIABLES']),
    (0xB109, 'sActive', 1, 'effect number * 2 while one plays', None),
    (0xB10A, 'sPos', 1, 'offset of the next step', None),
    (0xB10B, 'sPtr', 2, 'effect data', None),
    (0xB10D, 'sTwoVoices', 1, '1 = the effect also uses voice 2', None),
    (0xB10E, 'sSpeed', 1, 'calls per step', None),
    (0xB10F, 'sCount', 1, None, None),
]

CMDS = [  # (constant, params, description)
    ('C_VOLUME', 1, 'volume %s (filter mode kept)'), ('C_SPEED', 1, 'speed %d calls/tick'),
    ('C_AD', 1, 'attack/decay %s'), ('C_SR', 1, 'sustain/release %s'), ('C_WAVE', 1, 'waveform %s'),
    ('C_PULSE', 2, 'pulse width $%02X%02X'), ('C_FILTER', 3, 'filter on: mode %s, cutoff $%02X%02X'),
    ('C_PWSWEEP', 5, 'pulse sweep: speed %d, delay %d, step $%02X%02X, reset %d'),
    ('C_TRILL', 2, 'octave trill: speed %d, delay %d'),
    ('C_VIBRATO', 4, 'vibrato: speed %d, delay %d, depth $%02X%02X'),
    ('C_SLIDE', 3, 'slide: delay %d, from %s to %s'),
    ('C_WAVEALT', 4, 'waveform alternation: speed %d, delay %d, waves %s/%s'),
    ('C_PWSWEEP_OFF', 0, 'pulse sweep off'), ('C_TRILL_OFF', 0, 'octave trill off'),
    ('C_VIBRATO_OFF', 0, 'vibrato off'), ('C_SLIDE_OFF', 0, 'nothing (slides stop by themselves)'),
    ('C_WAVEALT_OFF', 0, 'waveform alternation off'), ('C_FILTER_OFF', 0, 'filter off'),
    ('C_RELEASE', 1, 'release gate %d ticks before the end'),
    ('C_SLIDESTEP', 3, 'slide speed %d, step $%02X%02X'),
    ('C_PWRANGE', 4, 'pulse sweep from $%02X%02X, back at $%02X%02X'),
    ('C_DRUMSPEED', 1, 'drum step every %d calls'), ('C_STOP', 0, 'stop the music')]
HANDLERS = ['Cmd_Volume', 'Cmd_Speed', 'Cmd_AD', 'Cmd_SR', 'Cmd_Wave', 'Cmd_Pulse', 'Cmd_Filter',
            'Cmd_PwSweep', 'Cmd_Trill', 'Cmd_Vibrato', 'Cmd_Slide', 'Cmd_WaveAlt', 'Cmd_PwSweepOff',
            'Cmd_TrillOff', 'Cmd_VibratoOff', 'Cmd_SlideOff', 'Cmd_WaveAltOff', 'Cmd_FilterOff',
            'Cmd_Release', 'Cmd_SlideStep', 'Cmd_PwRange', 'Cmd_DrumSpeed', 'Cmd_Stop']

SONGS = [(0xB4E6, 'Song0'), (0xBA72, 'Song1'), (0xBC16, 'Song2'), (0xBD4C, 'Song3')]

CODE = {
    0xA6CF: ('Effects', ['EFFECTS: run the per-voice effects for voices 1, 2, 3.']),
    0xA6E2: ('Fx_PwSweep', ['X = voice. Pulse sweep: after the delay, every mPwSpeed calls add the',
                            'step; restart at mPwStart once the high byte reaches mPwLimitHi.',
                            'Every effect is skipped while the voice is muted or plays a drum.']),
    0xA71E: ('PwAddStep', None), 0xA732: ('PwRestart', None),
    0xA73F: ('Fx_Trill', ['Octave trill: after the delay, every mTrillSpeed calls shift the',
                          'frequency an octave up, then back down.']),
    0xA76A: ('TrillFlip', None),
    0xA78E: ('Fx_Vibrato', ['Vibrato: after the delay, every mVibSpeed calls step through',
                            'base, base+depth, base, base-depth (a square wave, not a sine).']),
    0xA7B9: ('VibNextPhase', None), 0xA815: ('VibBase', None),
    0xA822: ('Fx_Slide', ['Slide: after the delay, every mSlideSpeed calls move the frequency',
                          'by the step towards the target.']),
    0xA84D: ('SlideStep', None),
    0xA85C: ('SlideUpUnused', ['Never called.']),
    0xA860: ('SlideDown', None), 0xA88A: ('SlideUp', None),
    0xA8AF: ('SlideArrive', ['Target reached: snap to it and switch the slide off, but only if',
                             'mSlideArmed is set (any voice\'s note sets it, the first arrival',
                             'clears it).']),
    0xA8D1: ('Fx_WaveAlt', ['Waveform alternation: after the delay, every mWaveAltSpeed calls',
                            'write mWaveA / mWaveB (keeping the gate bit) to the control register.']),
    0xA8FC: ('WaveAltFlip', None), 0xA914: ('WaveAltWrite', None),
    0xA938: ('FxDone', None),
    0xA939: ('WriteRegs', ['Write frequency, pulse width, AD and SR of every voice whose output',
                           'is on and which is not playing a drum.']),
    0xA973: ('WriteVoice', ['X = voice, Y = register offset.']),
    0xA998: ('Patterns', ['PATTERNS: every mSpeed calls, run voices 1, 2, 3.']),
    0xA9AE: ('V1_Read', ['Voice 1 (pattern pointer zPat1).']),
    0xAA2E: ('V2_Start', ['Voice 2 (zPat2).']),
    0xAA38: ('V2_Read', None),
    0xAAB8: ('V3_Start', ['Voice 3 (zPat3).']),
    0xAAC0: ('V3_Read', None),
    0xAB3F: ('NoteToFreq', ['A = note (bits 0-3 semitone 1-12, bits 4-6 octave) -> mNoteHi/Lo.',
                            'FreqTable holds octave 5 (PAL tuned).']),
    0xAB8D: ('SetNoteFreq', ['Frequency and vibrato base = the note.']),
    0xABBF: ('CountNote', ['X = voice. Drum playing: run it, return C=1. Otherwise count the',
                           'note down, release the gate at mReleaseAt, return C=0 and Z=1 when',
                           'the next event is due.']),
    0xABF8: ('NoteResetFx', ['New note: restart the effect delays (and the pulse width if',
                             'mPwResetOn), arm the slide.']),
    0xAC3A: ('NextPattern', ['End of pattern: next pointer from the order list (high byte 0 =',
                             'restart the list).']),
    0xAC95: ('SetSlideTarget', ['A = target note: store it and pick the direction.']),
    0xACBB: ('Drum', ['A = $F0-$FF drum byte, Y = offset: start drum A-$F0 (first step from',
                      'the drum header), or count down the one playing.']),
    0xAD64: ('Drum_Count', None),
    0xAD79: ('Drum_Step', ['Every mDrumSpeed calls: next step of the drum (control, freq hi,',
                           'freq lo); $FF ends the steps and takes the voice out of the filter.']),
    0xADB7: ('Drum_WriteStep', None),
    0xADD1: ('Drum_Exit', None),
    0xADD5: ('Command', ['A = $C8-$DE: jump through CmdTable with zCmd = pattern pointer.',
                         'Bytes above $DE would jump to garbage.']),
    0xB02C: ('Cmd_Done', ['Pointer += Y + 1, next event in the same call (mDuration = 1).']),
    0xB06A: ('Play', ['PLAY (PSID play address). Patterns, registers, effects, registers again,',
                      'drum steps, sound effects.']),
    0xB097: ('SelectV1', ['Set mVoice, mRegOfs, mVoiceBit.']), 0xB0A5: ('SelectV2', None),
    0xB0B5: ('SelectV3', None),
    0xB110: ('Sfx_Update', ['SOUND EFFECTS (not used by the rip). The game writes an effect',
                            'number to sRequest; effects take voice 1 (and voice 2 if the header',
                            'says so). Only voice 1 of the music is muted while one plays.']),
    0xB11E: ('Sfx_Start', ['A = effect number: read the header, write the first step.']),
    0xB1E7: ('Sfx_Step', ['Every sSpeed calls: next step, $FF = end (restores the filter',
                          'registers and turns music voices 1 and 2 back on).']),
    0xB22F: ('Sfx_WriteStep', None),
    0xB4E6: ('Song0_Init', ['SONG INIT ROUTINES: order list pointers and the first pattern of',
                            'each voice, then the common part. They leave interrupts disabled', '(SEI).']),
    0xB51D: ('Song_InitCommon', ['Filter registers from the shadows, all voices on, durations 2,',
                                 'order index 2 (entry 0 is the pattern set above), speed 4.']),
    0xBA72: ('Song1_Init', None), 0xBC16: ('Song2_Init', None), 0xBD4C: ('Song3_Init', None),
    0xBFE0: ('Rip_Init', ['SID RIPPER WRAPPER (not part of the game). A = song: patch the JMP with',
                          'the song\'s init routine and set CIA 1 timer A from Rip_SongTable.']),
}
EXTRA = {
    0xA705: 'Fx_PwStep',
    0xA75F: 'Fx_TrillStep',
    0xA782: 'TrillDown',
    0xA7AB: 'Fx_VibSkip',
    0xA7AE: 'Fx_VibStep',
    0xA7CD: 'VibPhase1',
    0xA7EA: 'VibPhase2',
    0xA7F7: 'VibPhase3',
    0xA7FC: 'VibMinus',
    0xA83F: 'Fx_SlideSkip',
    0xA842: 'Fx_SlideTick',
    0xA86B: 'SlideDownCheck',
    0xA870: 'SlideDownGo',
    0xA895: 'SlideUpGo',
    0xA8D0: 'SlideArriveDone',
    0xA8F1: 'Fx_WaveAltTick',
    0xA91C: 'WaveAltV2',
    0xA924: 'WaveAltV3',
    0xA928: 'WaveAltB',
    0xA94C: 'WriteRegs_V2',
    0xA95F: 'WriteRegs_V3',
    0xA972: 'WriteRegs_Done',
    0xA99E: 'Patterns_Tick',
    0xA9C5: 'V1_Event',
    0xA9CF: 'V1_NotEnd',
    0xA9E3: 'V1_NotDrum',
    0xA9ED: 'V1_Note',
    0xAA08: 'V1_Gate',
    0xAA1E: 'V1_GateDone',
    0xAA20: 'V1_Nop',
    0xAA21: 'V1_Advance',
    0xAA4F: 'V2_Event',
    0xAA59: 'V2_NotEnd',
    0xAA6D: 'V2_NotDrum',
    0xAA77: 'V2_Note',
    0xAA92: 'V2_Gate',
    0xAAA8: 'V2_GateDone',
    0xAAAA: 'V2_Nop',
    0xAAAB: 'V2_Advance',
    0xAAD4: 'V3_Exit',
    0xAAD5: 'V3_Event',
    0xAADF: 'V3_NotEnd',
    0xAAF3: 'V3_NotDrum',
    0xAAFD: 'V3_Note',
    0xAB18: 'V3_Gate',
    0xAB2E: 'V3_GateDone',
    0xAB30: 'V3_Nop',
    0xAB31: 'V3_Advance',
    0xAB7A: 'NoteToFreq_Down',
    0xAB7F: 'NoteToFreq_Shift',
    0xAB89: 'NoteToFreq_Done',
    0xABC9: 'CountNote_Tick',
    0xABE1: 'CountNote_Release',
    0xABF3: 'CountNote_Done',
    0xAC1D: 'NoteResetFx_NoPw',
    0xAC5C: 'NextPattern_V1Set',
    0xAC61: 'NextPattern_V2',
    0xAC74: 'NextPattern_V2Set',
    0xAC79: 'NextPattern_V3',
    0xAC88: 'NextPattern_V3Set',
    0xAC8A: 'NextPattern_Done',
    0xACB5: 'SetSlideTarget_Down',
    0xACBA: 'SetSlideTarget_Done',
    0xACCC: 'Drum_Start',
    0xAD34: 'Drum_NoFilter',
    0xAD9C: 'Drum_End',
    0xADAF: 'Drum_EndDone',
    0xADFF: 'Command_V2',
    0xAE0E: 'Command_V3',
    0xAEE1: 'Cmd_PwSweep_Reset',
    0xB04F: 'Cmd_Done_V2',
    0xB05C: 'Cmd_Done_V3',
    0xB093: 'Play_Sfx',
    0xB11D: 'Sfx_UpdateDone',
    0xB180: 'Sfx_NoFilter',
    0xB1AA: 'Sfx_OneVoice',
    0xB1AF: 'Sfx_FirstStep',
    0xB1D8: 'Sfx_SavePos',
    0xB1ED: 'Sfx_StepGo',
    0xB255: 'Sfx_WriteDone',
}
LINEC = {
    0xA932: 'BUG: no ,x -- every voice uses voice 1\'s second waveform',
    0xAA20: 'NOP (also at the same place for voices 2 and 3)',
    0xB206: 'turns music voices 1 AND 2 back on',
    0xB134: 'mute music voice 1 only',
}


def pattern(d, a, name, seen):
    if a in seen:
        return
    seen.add(a)
    d.label(a, name, primary=True)
    while True:
        b = d.b(a)
        if b == 0:
            d.add(a, 1, [('.byte $00', 'end of pattern')])
            return
        if b < 0xC8:
            nb = d.b(a + 1)
            d.add(a, 2, [('.byte %s,%s' % (h2(b), h2(nb)), '%-5s %3d ticks' % (notename(nb), b))])
            a += 2
            continue
        if b >= 0xF0:
            ln = d.b(a + 1)
            d.add(a, 2, [('.byte C_DRUM+%d,%s' % (b - 0xF0, h2(ln)), 'drum %d for %d ticks' % (b - 0xF0, ln))])
            a += 2
            continue
        if b > 0xDE:
            raise Exception('bad command %02X at %04X' % (b, a))
        nm, n, ds = CMDS[b - 0xC8]
        args = [d.b(a + 1 + i) for i in range(n)]
        if b == 0xD2:
            ds = ds % (args[0], notename(args[1]), notename(args[2]))
        elif b == 0xC9:
            ds = ds % args[0]
        elif b in (0xC8, 0xCA, 0xCB, 0xCC):
            ds = ds % h2(args[0])
        elif b == 0xCD:
            ds = ds % (args[0], args[1])
        elif b == 0xCE:
            ds = ds % (h2(args[0]), args[1], args[2])
        elif b == 0xCF:
            ds = ds % (args[0], args[1], args[2], args[3], args[4])
        elif b == 0xD0:
            ds = ds % tuple(args)
        elif b == 0xD1:
            ds = ds % tuple(args)
        elif b == 0xD3:
            ds = ds % (args[0], args[1], h2(args[2]), h2(args[3]))
        elif b in (0xDA, 0xDD):
            ds = ds % args[0]
        elif b == 0xDB:
            ds = ds % tuple(args)
        elif b == 0xDC:
            ds = ds % tuple(args)
        d.add(a, 1 + n, [('.byte ' + ','.join([nm] + [h2(x) for x in args]), ds)])
        a += 1 + n


def song(d, idx, init):
    """parse the song init routine (lda #imm / sta pairs), decode the data"""
    P = 'S%d_' % idx
    a = init
    ldas = {}
    while d.b(a) not in (0x60, 0x4C, 0xAD):
        if d.b(a) == 0x78:
            a += 1
            continue
        assert d.b(a) == 0xA9, '%04X' % a
        imm = d.b(a + 1)
        a2 = a + 2
        while d.b(a2) in (0x85, 0x8D):
            tgt = d.b(a2 + 1) if d.b(a2) == 0x85 else d.w(a2 + 1)
            ldas.setdefault(tgt, (a, imm))
            a2 += 2 if d.b(a2) == 0x85 else 3
        a = a2
    pp = lambda lo, hi: ldas[lo][1] | ldas[hi][1] << 8
    pats0 = [pp(0x92, 0x93), pp(0x94, 0x95), pp(0x4B, 0x4C)]
    orders = [pp(0xA6AF + v, 0xA6AC + v) for v in range(3)]
    lists = []
    for v in range(3):
        x = orders[v]
        lst = []
        while True:
            w = d.w(x)
            lst.append(w)
            x += 2
            if w >> 8 == 0:
                break
        lists.append(lst)
    pnames = {}
    k = 0
    for v in range(3):
        for w in [pats0[v]] + lists[v][:-1]:
            if w not in pnames:
                pnames[w] = '%sPat%02d' % (P, k)
                k += 1
    for v in range(3):
        nm = '%sOrder%d' % (P, v + 1)
        o = orders[v]
        if o in d.items:
            d.label(o, nm)
            continue
        d.label(o, nm, primary=True)
        d.comment(o, 'Song %d, voice %d order list (high byte 0 = restart).' % (idx, v + 1))
        lst = lists[v]

        def lines(dd, lst=lst):
            out = []
            for i in range(0, len(lst) - 1, 4):
                out.append(('.word ' + ', '.join(pnames[w] for w in lst[i:min(i + 4, len(lst) - 1)]), None))
            out.append(('.word %s' % h4(lst[-1]), 'end: back to the start'))
            return out
        d.add(o, 2 * len(lst), lines)
    seen = set()
    for v in range(3):
        for w in [pats0[v]] + lists[v][:-1]:
            pattern(d, w, pnames[w], seen)
    zpn = {0x92: 0, 0x93: 0, 0x94: 1, 0x95: 1, 0x4B: 2, 0x4C: 2}
    for tgt, (la, imm) in ldas.items():
        if tgt in zpn:
            d.opnd[la] = ('<' if tgt in (0x92, 0x94, 0x4B) else '>') + pnames[pats0[zpn[tgt]]]
        for v in range(3):
            if tgt == 0xA6AF + v:
                d.opnd[la] = '<%sOrder%d' % (P, v + 1)
            if tgt == 0xA6AC + v:
                d.opnd[la] = '>%sOrder%d' % (P, v + 1)


def drum(d, a, name):
    d.label(a, name, primary=True)
    hd = [d.b(a + i) for i in range(8)]
    d.add(a, 8, [('.byte ' + ','.join(h2(x) for x in hd),
                  'AD %s SR %s pulse $%02X%02X filter %s, control %s, freq $%02X%02X'
                  % (h2(hd[0]), h2(hd[1]), hd[2], hd[3], 'yes' if hd[4] else 'no', h2(hd[5]), hd[6], hd[7]))])
    a += 8
    while d.b(a) != 0xFF:
        d.add(a, 3, [('.byte %s,%s,%s' % (h2(d.b(a)), h2(d.b(a + 1)), h2(d.b(a + 2))),
                      'control %s, freq $%02X%02X' % (h2(d.b(a)), d.b(a + 1), d.b(a + 2)))])
        a += 3
    d.add(a, 1, [('.byte $FF', 'end')])


def sfx(d, a, name):
    if a in d.items:
        d.label(a, name)
        return
    d.label(a, name, primary=True)
    sp = d.b(a)
    d.add(a, 5, [('.byte ' + ','.join(h2(d.b(a + i)) for i in range(5)),
                  'speed %d, voice 1 AD %s SR %s pulse $%02X%02X' % (sp, h2(d.b(a + 1)), h2(d.b(a + 2)), d.b(a + 3), d.b(a + 4)))])
    a += 5
    if d.b(a):
        d.add(a, 4, [('.byte ' + ','.join(h2(d.b(a + i)) for i in range(4)),
                      'filter: routing %s, mode %s, cutoff $%02X%02X' % (h2(d.b(a)), h2(d.b(a + 1) & 0xF0), d.b(a + 2), d.b(a + 3)))])
        a += 4
    else:
        d.add(a, 1, [('.byte $00', 'no filter')])
        a += 1
    two = d.b(a) != 0
    if two:
        d.add(a, 5, [('.byte ' + ','.join(h2(d.b(a + i)) for i in range(5)),
                      'voice 2: AD %s SR %s pulse $%02X%02X' % (h2(d.b(a + 1)), h2(d.b(a + 2)), d.b(a + 3), d.b(a + 4)))])
        a += 5
    else:
        d.add(a, 1, [('.byte $00', 'voice 1 only')])
        a += 1
    n = 6 if two else 3
    first = True
    while True:
        if not first and d.b(a) == 0xFF:
            d.add(a, 1, [('.byte $FF', 'end')])
            return
        v = [d.b(a + i) for i in range(n)]
        c = 'ctrl %s freq $%02X%02X' % (h2(v[0]), v[1], v[2])
        if two:
            c += ' | ctrl %s freq $%02X%02X' % (h2(v[3]), v[4], v[5])
        d.add(a, n, [('.byte ' + ','.join(h2(x) for x in v), c)])
        a += n
        first = False


def after_trace(d, s):
    def pre(n):
        return None
    d.linec.update(LINEC)
    for a, n in EXTRA.items():
        if a in d.labels:
            d.labels[a][0] = n


def setup(d, s):
    hdr = [';' + '=' * 78]
    for l in HEADER.strip('\n').split('\n'):
        hdr.append((';  ' + l).rstrip())
    hdr.append(';' + '=' * 78)
    hdr.append('')
    for a, n, size, cm, blk in VARS:
        var(d, a, n, size, cm, blk)
    for a, (n, cm) in CODE.items():
        code(d, a, n, cm)
    # command table
    tbl = [d.w(0xAE19 + 2 * i) for i in range(23)]
    d.label(0xAE19, 'CmdTable', primary=True)
    for i, t in enumerate(tbl):
        code(d, t, HANDLERS[i], ['$%02X %s' % (0xC8 + i, CMDS[i][0])] if t not in (0xB02C,) else None)
    d.add(0xAE19, 46, lambda dd: [('.word %s' % HANDLERS[i], '$%02X %s' % (0xC8 + i, CMDS[i][0])) for i in range(23)])
    # frequency table
    d.label(0xABA0, 'FreqTable', primary=True)
    d.comment(0xABA0, 'Octave 5 frequencies, big-endian, index = semitone. PAL values:')
    d.comment(0xABA0, 'C5 = $22D2 = 523.5 Hz on a PAL C64.')
    names = ['(0)'] + ['%s5' % x for x in SEMI[1:13]]
    lines = []
    for i in range(13):
        v = d.b(0xABA0 + 2 * i) << 8 | d.b(0xABA1 + 2 * i)
        lines.append(('.dbyt $%04X' % v, names[i] + ('  %.1f Hz PAL' % (v * 985248 / 16777216) if i else '  semitone 0: silent')))
    d.add(0xABA0, 26, lines)
    bytes_item(d, 0xABBA, 5, 'OctaveShift', 'octave 0-4: shift right this + 1 times')
    # drums
    dr = [d.w(0xB0C5 + 2 * i) for i in range(5)]
    d.label(0xB0C5, 'DrumTable', primary=True)
    d.comment(0xB0C5, 'DRUMS ($F0-$F4 in patterns; all five point at the same drum). Header:')
    d.comment(0xB0C5, 'AD, SR, pulse hi, pulse lo, filter flag, control, freq hi, freq lo; then')
    d.comment(0xB0C5, 'steps of control, freq hi, freq lo until $FF.')
    d.add(0xB0C5, 10, lambda dd: [('.word ' + ', '.join(dd.wordref(x) for x in dr), None)])
    drum(d, dr[0], 'Drum0')
    # sound effects
    sx = [d.w(0xB258 + 2 * i) for i in range(16)]
    d.label(0xB258, 'SfxTable', primary=True)
    d.comment(0xB258, 'SOUND EFFECT TABLE (sRequest 1-15; entry 0 is never used). Effect:')
    d.comment(0xB258, 'speed, AD, SR, pulse hi, pulse lo; filter (0, or routing, mode, cutoff')
    d.comment(0xB258, 'hi, lo); voice 2 (0, or nonzero, AD, SR, pulse hi, pulse lo); then steps')
    d.comment(0xB258, 'of control, freq hi, freq lo (+ the same for voice 2) until $FF.')
    seen = {}
    for i, a in enumerate(sx):
        if a not in seen:
            seen[a] = 'Sfx%02d' % i
    d.add(0xB258, 32, lambda dd: [('.word ' + ', '.join(seen[x] for x in sx[i:i + 4]), 'effects %d-%d' % (i, i + 3)) for i in range(0, 16, 4)])
    for a, n in seen.items():
        sfx(d, a, n)
    # songs
    for i, (a, n) in enumerate(SONGS):
        song(d, i, a)
    # rip wrapper
    d.label(0xBFFB, 'Rip_InitJmp')
    d.label(0xC000, 'Rip_SongTable', primary=True)
    tb = [(d.b(0xC000 + 4 * i) << 8 | d.b(0xC001 + 4 * i), d.b(0xC002 + 4 * i) << 8 | d.b(0xC003 + 4 * i)) for i in range(5)]
    d.add(0xC000, 20, lambda dd: [('.dbyt %s, $%04X' % (dd.ref(t, False), tm),
                                    'song %d: CIA timer %d cycles = %.1f Hz (PAL)' % (i + 1, tm, 985248.0 / tm))
                                   for i, (t, tm) in enumerate(tb)])
    d.ram.update({0x4B: 'zPat3', 0x4C: 'zPat3+1', 0x4D: 'zUnused4D', 0x4E: 'zUnused4D+1', 0x4F: 'zOrder',
                  0x50: 'zOrder+1', 0x51: 'zCmd', 0x52: 'zCmd+1', 0x92: 'zPat1', 0x93: 'zPat1+1',
                  0x94: 'zPat2', 0x95: 'zPat2+1', 0x96: 'zSfx', 0x97: 'zSfx+1'})
    zp = [('zPat1', '$92', 'voice 1 pattern pointer'), ('zPat2', '$94', 'voice 2 pattern pointer'),
          ('zPat3', '$4B', 'voice 3 pattern pointer'), ('zUnused4D', '$4D', 'written before every voice, never read'),
          ('zOrder', '$4F', 'order list pointer (temporary)'), ('zCmd', '$51', 'command / drum data pointer'),
          ('zSfx', '$96', 'sound effect data')]
    eq = [(n, '$%02X' % (0xC8 + i), None) for i, (n, _, _) in enumerate(CMDS)] + [('C_DRUM', '$F0', 'drum 0-15: C_DRUM+n, length')]
    return dict(header=hdr, sym=dict(init='Rip_Init', play='Play'),
                equates=[('zero page', zp), ('pattern commands', eq)])


HEADER = r"""
Mark Cooksey C64 sound driver -- PAPERBOY (1986 Elite)
Middle driver: Bomb Jack's pattern idea (length + note pairs, commands
from $C8) rewritten as one loop over the voices, with a command jump table,
per-voice effects, drum macros and a sound effect player.

Source: Paperboy.sid (PSID v2, load $A5FE-$C017, 5 songs, CIA timing, PAL,
6581). Reassembles byte-identically to the .sid file:
          ca65 paperboy_sound.s
          ld65 -C paperboy_sound.cfg -o out.sid paperboy_sound.o

MEMORY
  $A5FE-$A6CE  variables          $B108-$B10F  sound effect variables
  $A6CF-$B0C4  player             $B110-$B257  sound effect player
  $B0C5-$B107  drums              $B258-$B4E1  sound effects
  $B4E6-$BFDF  4 songs (init routine, order lists, patterns)
  $BFE0-$C017  SID ripper wrapper

ENTRY POINTS
  Song0_Init .. Song3_Init   start a song (the rip's songs 1+2 both use
                             Song0 at 150 Hz and 50 Hz)
  Play $B06A                 call at the song's rate (CIA timer)
  sRequest                   write 1-15 to start a sound effect

TIMING: Play runs the patterns every mSpeed calls (one tick); effects and
register writes run on every call, drum steps every mDrumSpeed calls.

ORDER LISTS: .word pattern pointers; a high byte of 0 restarts the list.

PATTERNS
  $00            end of pattern
  $01-$C7 nn     length in ticks, then the note byte: bits 0-3 semitone
                 (1 = C ... 12 = B, 0 = rest), bits 4-6 octave. The gate is
                 released when mReleaseAt ticks are left; a note retriggers
                 the gate (if the voice's output is on) and restarts the
                 effect delays.
  $C8-$DE        commands (C_ equates), parameters follow
  $F0-$FF ll     drum n for ll ticks (the voice's pattern waits)

Bytes the driver never reads are kept (so the file reassembles) and are
marked "not referenced".
"""
