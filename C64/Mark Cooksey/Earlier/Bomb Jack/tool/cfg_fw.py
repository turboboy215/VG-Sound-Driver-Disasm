"""Forgotten Worlds (1989 US Gold/Capcom): two copies of the later Mark
Cooksey driver -- the one whose data format the NES driver uses.

  $E000-$E598  title driver (song 1): pulse-width modulation, vibrato, filter
               sweeps, 7 instruments, 21 patterns
  $EE00-$F246  in-game driver (song 2): a cut-down build (no PWM, no filter),
               3 instruments, 18 patterns.  The ripper moved it from $C000 to
               $EE00 and missed every address in code that the in-game tune
               never runs (RIP_RELOC = $2E00)."""

from core import h2, h4
from common import var, bytes_item, words_item, lohi_item, code, NOTE12

TITLE = 'Forgotten Worlds'
RIP_RELOC = 0x2E00


def notename(n):
    return '%s%d' % (NOTE12[n % 12], n // 12)


# --------------------------------------------------------------------------
# address maps of the two copies (P = prefix for every label)
T = dict(P='T_', base=0xE000, init=0xE4B2, play=0xE003, nins=7, npat=21,
         ninst_cols=11, has_pwm=True, has_filter=True,
         var0=0xE365, cmdlo=0xE3DC, cmdhi=0xE3E7, freqlo=0xE3F2, freqhi=0xE452,
         dur=0xE4E8, rel=0xE4F8, ins=0xE508, flt=0xE555, trklo=0xE569, trkhi=0xE56C,
         patlo=0xE56F, pathi=0xE584, data=0xE599)
G = dict(P='G_', base=0xEE00, init=0xF1CD, play=0xEE03, nins=3, npat=18,
         ninst_cols=11, has_pwm=False, has_filter=False,
         var0=0xF08B, cmdlo=0xF0F7, cmdhi=0xF102, freqlo=0xF10D, freqhi=0xF16D,
         dur=0xF200, rel=0xF210, ins=0xF220, flt=None, trklo=0xF241, trkhi=0xF244,
         patlo=0xFA2C, pathi=0xFA3E, data=0xF247)

CMDS = ['REST', 'TIE', 'NOP62', 'VOLUME', 'CALL', 'CALLN', 'RETURN', 'RESTART',
        'JUMP', 'FILTER', 'FILTER2', 'STOP']
CMDLEN = {0x60: 2, 0x61: 1, 0x62: 2, 0x63: 2, 0x64: 3, 0x65: 4, 0x66: 1, 0x67: 1,
          0x68: 3, 0x69: 2, 0x6A: 2, 0x6B: 1}
CMD_CONST = [('CMD_' + n, '$%02X' % (0x60 + i)) for i, n in enumerate(CMDS)]

INS_COLS = [('InsCtrl', 'control register at note start (waveform + gate)'),
            ('InsCtrlRel', 'control register at release (gate off)'),
            ('InsAD', 'attack / decay'),
            ('InsSR', 'sustain / release'),
            ('InsPwLo', 'pulse width low'),
            ('InsPwHi', 'pulse width high'),
            ('InsPwmStep', 'PWM: added to / taken from the pulse width every frame (0 = off)'),
            ('InsPwmLen', 'PWM: frames per direction'),
            ('InsVibDepth', 'vibrato depth (frequency units, 0 = off)'),
            ('InsVibLen', 'vibrato: frames per direction'),
            ('InsVibDelay', 'vibrato delay in frames')]


def var_map(c):
    """(offset from var0, name, size, comment) -- the variable block is laid
    out identically in both copies, the in-game copy just has no PWM and
    filter variables."""
    v0 = c['var0']
    L = [(0x00, 'zEvByte0', 1, 'byte 0 of the event being read (bit 7 = instrument bit 4)'),
         (0x01, 'Unused01', 1, None),
         (0x02, 'mEvLen', 1, 'Y: length of the event just read'),
         (0x03, 'mVoice', 1, 'current voice (2, 1, 0)'),
         (0x04, 'mRegOfs', 1, 'SID register offset of the current voice'),
         (0x05, 'mInst', 1, 'instrument of the current voice'),
         (0x06, 'mEnabled', 1, '0 = driver stopped (CMD_STOP)'),
         (0x07, 'VoiceRegOfs', 3, 'SID register offset per voice'),
         (0x0A, 'VoiceBit', 3, 'filter routing bit per voice'),
         (0x0D, 'mTrkLo', 3, 'track / pattern pointer'),
         (0x10, 'mTrkHi', 3, None),
         (0x13, 'mRetLo', 3, 'return address (after a CMD_CALL)'),
         (0x16, 'mRetHi', 3, None),
         (0x19, 'mTrkStartLo', 3, 'start of the track (CMD_RESTART)'),
         (0x1C, 'mTrkStartHi', 3, None),
         (0x1F, 'mPatLo', 3, 'start of the called pattern (for repeats)'),
         (0x22, 'mPatHi', 3, None),
         (0x25, 'mNote', 3, 'note playing (written, never read)'),
         (0x28, 'mNextNote', 3, 'note read ahead (transposed)'),
         (0x2B, 'mCurInst', 3, 'instrument playing'),
         (0x2E, 'mNextInst', 3, 'instrument read ahead'),
         (0x31, 'mTimer', 3, 'frames left of the note'),
         (0x34, 'mNextLen', 3, 'length of the next note (DurTable)'),
         (0x37, 'mRelTimer', 3, 'frames until the gate is released'),
         (0x3A, 'mNextRel', 3, 'release time of the next note (RelTable)'),
         (0x3D, 'mNextRest', 3, '1 = the next event is a rest'),
         (0x40, 'mRest', 3, 'rest flag of the current event (written, never read)'),
         (0x43, 'mTie', 3, 'toggled by CMD_TIE: no gate release, no retrigger'),
         (0x46, 'mPlaying', 3, 'set at each note start (written, never read)'),
         (0x49, 'mTranspose', 3, 'added to the notes of a called pattern'),
         (0x4C, 'mRepeat', 3, 'CMD_CALLN repeat count'),
         (0x4F, 'mVolume', 1, 'master volume (CMD_VOLUME)'),
         (0x50, 'mNop62', 1, 'CMD_NOP62 parameter (written, never read)'),
         (0x51, 'mFreqLo', 3, 'current frequency (with vibrato)'),
         (0x54, 'mFreqHi', 3, None),
         (0x57, 'mPwLo', 3, 'current pulse width'),
         (0x5A, 'mPwHi', 3, None)]
    if c['has_pwm']:
        L += [(0x5D, 'mPwmDir', 3, 'PWM direction (0 = up)'),
              (0x60, 'mPwmTimer', 3, 'frames left in this PWM direction')]
        o = 0x63
    else:
        o = 0x5D
    L += [(o + 0, 'mVibDepth', 3, 'vibrato step (doubled after the first half swing)'),
          (o + 3, 'mVibTimer', 3, 'frames left in this vibrato direction'),
          (o + 6, 'mVibDelay', 3, 'frames before the vibrato starts'),
          (o + 9, 'mVibDir', 3, 'vibrato direction (0 = up)'),
          (o + 12, 'mVibFull', 3, '1 once the depth has been doubled')]
    o += 15
    if c['has_filter']:
        L += [(o + 0, 'mFilter', 1, 'filter preset, $80+ = filter off'),
              (o + 1, 'mCutoff', 1, 'filter cutoff (high byte)'),
              (o + 2, 'mSweepDir', 1, 'cutoff sweep direction (0 = up)'),
              (o + 3, 'mSweepCount', 1, 'frames in this sweep direction'),
              (o + 4, 'mFilterMode', 1, 'filter mode bits for SID_MODE_VOL')]
        o += 5
    return [(v0 + a, c['P'] + n, s, cm) for a, n, s, cm in L]


def code_map(c):
    P = c['P']
    if c is T:
        m = {
            0xE000: ('Init', ['Entry points. Init: A = song (this driver holds one song: 0).']),
            0xE003: ('Play', ['Play: once per frame. Voices 2, 1, 0.']),
            0xE013: ('VoiceLoop', ['X = voice. Release the gate when the release timer runs out',
                                   '(unless tied).']),
            0xE03D: ('TickNote', ['Note timer: 0 = start the read-ahead note, 1 = read the next',
                                  'event (one frame early), otherwise run the effects.']),
            0xE04C: ('ReadEvent', None),
            0xE058: ('ParseEvent', ['Y = offset in the track. Notes are $00-$5F, or any byte with',
                                    'bit 7 set; $60-$7F are commands.']),
            0xE063: ('Note', ['Note: byte 0 = note (+ bit 7: instrument bit 4), byte 1 = instrument',
                              'bits 0-3 (high nibble), DurTable/RelTable index (low nibble).']),
            0xE096: ('AdvanceTrack', ['Track pointer += Y.']),
            0xE0A9: ('StartNote', ['Timer ran out: the read-ahead event becomes current.']),
            0xE0BB: ('LoadInstrument', ['Pulse width, PWM, vibrato from the instrument; frequency from the',
                                        'note; AD, SR, control (gate on).']),
            0xE11D: ('StartTimers', ['Note and rest: timers from the read-ahead event.']),
            0xE14F: ('StartDone', None),
            0xE152: ('Effects', ['Pulse-width modulation: step up / down, flip every InsPwmLen frames.']),
            0xE193: ('Vibrato', ['Vibrato: after InsVibDelay frames, swing the frequency by mVibDepth',
                                 'each frame, flipping direction every InsVibLen frames; the depth',
                                 'is doubled after the first flip so the swing is centred.']),
            0xE1E5: ('WriteVoice', ['Frequency and pulse width to the SID; next voice.']),
            0xE206: ('FilterSweep', ['Filter sweep (global): cutoff moves by FltStep for FltLen frames,',
                                     'then back.']),
            0xE24C: ('PlayExit', None),
            0xE253: ('Command', ['Command byte: $6B stops the driver, $60-$6A jump through',
                                 'CmdLo/CmdHi (the JMP operand below is patched).']),
            0xE26E: ('CmdJump', None),
            0xE271: ('Cmd_Stop', ['$6B CMD_STOP: silence and disable the driver.']),
            0xE282: ('Cmd_Rest', ['$60 CMD_REST len: rest (the gate stays off).']),
            0xE297: ('Cmd_Tie', ['$61 CMD_TIE: toggle tie/legato for this voice.']),
            0xE2A2: ('Cmd_Nop62', ['$62 x: stores x in mNop62, which nothing reads.']),
            0xE2AB: ('Cmd_Volume', ['$63 CMD_VOLUME v: master volume (filter mode bits kept).']),
            0xE2BA: ('Cmd_CallN', ['$65 CMD_CALLN count, pattern, transpose']),
            0xE2C0: ('Cmd_Call', ['$64 CMD_CALL pattern, transpose (enters Cmd_CallN here, so the',
                                  'count left over from the last call, normally 0, is kept: play once).']),
            0xE2EF: ('Cmd_Return', ['$66 CMD_RETURN: repeat the pattern while the count lasts, else',
                                    'continue after the call with transpose 0.']),
            0xE319: ('Cmd_Restart', ['$67 CMD_RESTART: back to the start of the track.']),
            0xE32D: ('Cmd_Jump', ['$68 CMD_JUMP .word address']),
            0xE33B: ('Cmd_Filter', ['$69/$6A CMD_FILTER preset: filter mode, routing, cutoff, sweep.']),
            0xE011: ('Run', None), 0xE16D: ('PwmApply', None), 0xE184: ('PwmDown', None),
            0xE1A2: ('VibTick', None), 0xE1C0: ('VibApply', None), 0xE1D6: ('VibDown', None),
            0xE20F: ('SweepTick', None), 0xE224: ('SweepStep', None), 0xE239: ('SweepDown', None),
            0xE243: ('SetCutoff', None), 0xE249: ('SetRouting', None), 0xE305: ('ReturnDone', None),
            0xE314: ('ReturnGo', None), 0xE4B5: ('InitLoop', None), 0xE4D6: ('ClearSid', None),
            0xE4B2: ('SongInit', ['Song A: track pointers (A indexes TrkLo/TrkHi, so only 0 is',
                                  'valid), timers = 2, clear the SID, volume 15, enable.']),
        }
    else:
        m = {
            0xEE00: ('Init', ['Entry points. Init: A = song (this driver holds one song: 0).']),
            0xEE03: ('Play', ['Play: once per frame. Voices 2, 1, 0.',
                              'If the driver is stopped it jumps to $C19F: the ripper did not',
                              'relocate this JMP (should be G_PlayExit). Only reachable after',
                              'CMD_STOP, which the in-game tune never uses.']),
            0xEE13: ('VoiceLoop', ['X = voice. Release the gate when the release timer runs out',
                                   '(unless tied).']),
            0xEE3D: ('TickNote', ['Note timer: 0 = start the read-ahead note, 1 = read the next',
                                  'event (one frame early), otherwise run the vibrato.']),
            0xEE4C: ('ReadEvent', None),
            0xEE58: ('ParseEvent', None),
            0xEE63: ('Note', ['Note: same 2-byte format as the title driver.']),
            0xEE96: ('AdvanceTrack', ['Track pointer += Y.']),
            0xEEA9: ('StartNote', None),
            0xEEBB: ('LoadInstrument', ['Pulse width and vibrato from the instrument (the PWM columns are',
                                        'still in the table but not read), frequency, AD, SR, control.']),
            0xEF14: ('StartTimers', None),
            0xEF29: ('Vibrato', ['Vibrato (as the title driver). The delay countdown below writes to',
                                 '$C2EE,x: not relocated by the ripper (should be G_mVibDelay); no',
                                 'instrument in this tune has a vibrato delay.']),
            0xEF7E: ('WriteVoice', ['Frequency and pulse width to the SID; next voice.']),
            0xEF9F: ('PlayExit', None),
            0xEFA6: ('Command', ['Command byte: $6B stops, $60-$6A jump through CmdLo/CmdHi.']),
            0xEFC1: ('CmdJump', None),
            0xEFC4: ('Cmd_Stop', ['$6B CMD_STOP (two unrelocated addresses: the STA should hit',
                                  'G_mEnabled, the JMP G_PlayExit).']),
            0xEFD5: ('Cmd_Rest', ['$60 CMD_REST len']),
            0xEFEA: ('Cmd_Tie', ['$61 CMD_TIE (unrelocated: $C2CE = G_mTie, $C058 = G_ParseEvent).']),
            0xEFF5: ('Cmd_Nop62', ['$62 x (unrelocated: $C2DB = G_mNop62, $C058 = G_ParseEvent).']),
            0xEFFE: ('Cmd_Volume', ['$63 CMD_VOLUME v (no filter in this build: plain volume).']),
            0xF00A: ('Cmd_CallN', ['$65 CMD_CALLN count, pattern, transpose']),
            0xF010: ('Cmd_Call', ['$64 CMD_CALL pattern, transpose']),
            0xF03F: ('Cmd_Return', ['$66 CMD_RETURN']),
            0xF069: ('Cmd_Restart', ['$67 CMD_RESTART (unrelocated: $C2xx = G_ variables, $C04C =',
                                     'G_ReadEvent).']),
            0xF07D: ('Cmd_Jump', ['$68 CMD_JUMP .word address']),
            0xEE11: ('Run', None), 0xEF3B: ('VibTick', None), 0xEF59: ('VibApply', None),
            0xEF6F: ('VibDown', None), 0xF055: ('ReturnDone', None), 0xF064: ('ReturnGo', None),
            0xF1D0: ('InitLoop', None), 0xF1F1: ('ClearSid', None),
            0xF1CD: ('SongInit', ['Song A: track pointers, timers = 2, clear the SID, volume 15, enable.']),
        }
    return {a: (P + n, cmt) for a, (n, cmt) in m.items()}


# operand overrides for the addresses the ripper did not relocate
def unreloc(d, c, vars_by_addr):
    if c is not G:
        return
    fix = {0xEE0E: 'G_PlayExit', 0xEF36: 'G_mVibDelay', 0xEFC1: None, 0xEFC6: 'G_mEnabled',
           0xEFD2: 'G_PlayExit', 0xEFEA: 'G_mTie', 0xEFEF: 'G_mTie', 0xEFF2: 'G_ParseEvent',
           0xEFF7: 'G_mNop62', 0xEFFB: 'G_ParseEvent',
           0xF069: 'G_mTrkStartLo', 0xF06C: 'G_mTrkLo', 0xF06F: 'G_mTrkStartHi',
           0xF072: 'G_mTrkHi', 0xF077: 'G_mTranspose', 0xF07A: 'G_ReadEvent'}
    for a, n in fix.items():
        if n:
            d.opnd[a] = '%s-RIP_RELOC' % n
            d.linec[a] = 'unrelocated ($%04X)' % (d.w(a + 1))
    d.opnd[0xEFC1] = 'G_Cmd_Rest-RIP_RELOC'
    d.linec[0xEFC1] = 'operand patched by Command (snapshot $C1D5: unrelocated)'


def stream(d, c, a, name, pats, kind):
    """decode a track / pattern starting at a; returns end address"""
    P = c['P']
    d.label(a, name, primary=True)
    d_start = a
    dur = [d.b(c['dur'] + i) for i in range(16)]
    rel = [d.b(c['rel'] + i) for i in range(16)]
    while True:
        b0 = d.b(a)
        if b0 < 0x60 or b0 >= 0x80:
            b1 = d.b(a + 1)
            ins = ((b0 >> 7) << 4) | (b1 >> 4)
            n = b0 & 0x7F
            com = '%-4s ins %2d  len[%2d] = %3d fr, release after %d' % (
                notename(n) if n < 96 else '?%02X' % n, ins, b1 & 15, dur[b1 & 15], rel[b1 & 15])
            d.add(a, 2, [('.byte %s,%s' % (h2(b0), h2(b1)), com)])
            a += 2
            continue
        ln = CMDLEN.get(b0, 1)
        cn = 'CMD_' + CMDS[b0 - 0x60] if b0 <= 0x6B else h2(b0)
        args = [d.b(a + i) for i in range(1, ln)]
        com = None
        txt = None
        if b0 == 0x60:
            com = 'rest  len[%2d] = %3d fr' % (args[0] & 15, dur[args[0] & 15])
        elif b0 == 0x61:
            com = 'toggle tie'
        elif b0 == 0x63:
            com = 'volume %d' % (args[0] & 15)
        elif b0 in (0x64, 0x65):
            if b0 == 0x64:
                p, t, cnt = args[0], args[1], None
            else:
                cnt, p, t = args
            pats.add(p)
            tt = t - 256 if t > 127 else t
            pn = '%sPattern%02d' % (P, p)
            if b0 == 0x64:
                txt = '.byte %s,%s_ID,%s' % (cn, pn, h2(t))
                com = '%s, transpose %+d' % (pn, tt)
            else:
                txt = '.byte %s,%s,%s_ID,%s' % (cn, h2(cnt), pn, h2(t))
                com = '%s, transpose %+d, play %dx' % (pn, tt, max(cnt, 1))
        elif b0 == 0x68:
            tgt = d.w(a + 1)
            if tgt != d_start and tgt < a:
                d.label(tgt, name + '_Loop', primary=True)
            d.add(a, 3, lambda dd, tgt=tgt: [('.byte CMD_JUMP', None), ('.word %s' % dd.wordref(tgt), 'loop')])
            return a + 3
        elif b0 in (0x69, 0x6A):
            com = 'filter preset %d' % args[0]
        if txt is None:
            txt = '.byte ' + ','.join([cn] + [h2(x) for x in args])
        d.add(a, ln, [(txt, com)])
        a += ln
        if b0 in (0x66, 0x67, 0x6B):
            return a


def driver(d, c, s):
    P = c['P']
    vmap = var_map(c)
    for a, n, size, cm in vmap:
        if size == 1 or True:
            var(d, a, n, size, cm)
    for a, (n, cmt) in code_map(c).items():
        code(d, a, n, cmt)
    unreloc(d, c, None)
    if c is T:
        d.linec[0xE031] = 'no ,x: always clears voice 0 (never read anyway)'
        d.linec[0xE1C5] = 'no CLC: a leftover carry adds 1'
    else:
        d.linec[0xEE31] = 'no ,x: always clears voice 0 (never read anyway)'
        d.linec[0xEF5E] = 'no CLC: a leftover carry adds 1'
    # self-modified JMP operand
    d.label(c['play'] + (0xE26F - 0xE003 if c is T else 0xEFC2 - 0xEE03), P + 'CmdJumpVec')
    # command table
    hl = [d.b(c['cmdlo'] + i) | d.b(c['cmdhi'] + i) << 8 for i in range(11)]
    names = []
    for i, t in enumerate(hl):
        if c['base'] <= t < c['base'] + 0x1000:
            names.append(t)
            d.code(t)
        else:
            names.append(t)
    tg = []
    for i, t in enumerate(hl):
        if c is G and not (0xEE00 <= t < 0xFA50):
            tg.append(None)
        else:
            tg.append(t)

    def cmdtab(kind, base):
        def lines(dd):
            out = []
            for i, t in enumerate(hl):
                if tg[i] is None:
                    rt = t + RIP_RELOC
                    nm = dd.ref(rt, False)
                    e = '%s-RIP_RELOC' % nm
                    cm = '$%02X CMD_%s  unrelocated ($%04X)' % (0x60 + i, CMDS[i], t)
                    if c is G and i in (9, 10):
                        cm += ': no filter command in this build, points at a variable'
                else:
                    e = dd.ref(t, False)
                    cm = '$%02X CMD_%s' % (0x60 + i, CMDS[i])
                out.append(('%s %s' % ('.lobytes' if kind == 'lo' else '.hibytes', e), cm))
            return out
        d.label(base, P + ('CmdLo' if kind == 'lo' else 'CmdHi'), primary=True)
        d.add(base, 11, lines)
    cmdtab('lo', c['cmdlo'])
    cmdtab('hi', c['cmdhi'])
    # frequency table
    fl = [d.b(c['freqlo'] + i) | d.b(c['freqhi'] + i) << 8 for i in range(96)]
    for kind, base in (('lo', c['freqlo']), ('hi', c['freqhi'])):
        d.label(base, P + ('FreqLo' if kind == 'lo' else 'FreqHi'), primary=True)
        if kind == 'lo':
            d.comment(base, 'SID frequency per note, C0..B7 (PAL tuned: A4 = $%04X = %.1f Hz on PAL).'
                      % (fl[57], fl[57] * 985248 / 16777216))
        lines = []
        for o in range(8):
            vals = fl[o * 12:o * 12 + 12]
            lines.append(('%s %s' % ('.lobytes' if kind == 'lo' else '.hibytes',
                                     ','.join('$%04X' % v for v in vals)), 'octave %d' % o))
        d.add(base, 96, lines)
    # durations
    bytes_item(d, c['dur'], 16, P + 'DurTable', 'frames per length index 0-15')
    bytes_item(d, c['rel'], 16, P + 'RelTable', 'frames before the gate is released, per length index')
    # instruments
    n = c['nins']
    for i, (cn, cm) in enumerate(INS_COLS):
        a = c['ins'] + i * n
        note = cm
        if not c['has_pwm'] and cn.startswith('InsPwm'):
            note = cm + ' -- not read by this build'
        bytes_item(d, a, n, P + cn, note)
    d.comment(c['ins'], 'INSTRUMENTS: %d instruments, stored as %d columns (one byte per' % (n, len(INS_COLS)))
    d.comment(c['ins'], 'instrument in each).')
    if c['has_filter']:
        f = c['flt']
        for i, (cn, cm) in enumerate([('FltMode', 'filter mode bits (SID_MODE_VOL high nibble)'),
                                      ('FltRoute', 'SID_RES_FILT: resonance / voices into the filter'),
                                      ('FltCutoff', 'start cutoff (SID_FC_HI)'),
                                      ('FltStep', 'cutoff change per frame'),
                                      ('FltLen', 'frames per sweep direction')]):
            bytes_item(d, f + i * 4, 4, P + cn, cm)
        d.comment(f, 'FILTER PRESETS 0-3 (CMD_FILTER), one column per field.')
    # song / tracks
    trk = [d.b(c['trklo'] + i) | d.b(c['trkhi'] + i) << 8 for i in range(3)]
    tnames = ['%sTrack_V%d' % (P, i + 1) for i in range(3)]
    lohi_item(d, c['trklo'], 3, P + 'TrkLo', 'lo', tnames, 'song 0: voice 1, 2, 3',
              block=['SONG: one track per voice.'])
    lohi_item(d, c['trkhi'], 3, P + 'TrkHi', 'hi', tnames)
    pats = set()
    for i, t in enumerate(trk):
        stream(d, c, t, tnames[i], pats, 'track')
    np_ = c['npat']
    pp = [d.b(c['patlo'] + i) | d.b(c['pathi'] + i) << 8 for i in range(np_)]
    pnames = ['%sPattern%02d' % (P, i) for i in range(np_)]
    lohi_item(d, c['patlo'], np_, P + 'PatLo', 'lo', pnames, block=['PATTERNS (CMD_CALL numbers).'])
    lohi_item(d, c['pathi'], np_, P + 'PatHi', 'hi', pnames)
    for i, p in enumerate(pp):
        if p in d.items:
            d.label(p, pnames[i])
            continue
        stream(d, c, p, pnames[i], set(), 'pattern')
    return pnames


def after_trace(d, s):
    for a in (0xC04C, 0xC058, 0xC19F, 0xC1D5):
        d.extern.pop(a, None)


def setup(d, s):
    hdr = [';' + '=' * 78]
    for l in HEADER.strip('\n').split('\n'):
        hdr.append((';  ' + l).rstrip())
    hdr.append(';' + '=' * 78)
    hdr.append('')
    # rip wrapper
    code(d, 0xEDD0, 'Rip_Init', ['SID ripper wrapper (not part of the game): song 1 = title driver at',
                                '$E000, song 2 = in-game driver at $EE00. Patches the high byte of',
                                'both JMPs, then inits the chosen driver with A = 0.'])
    code(d, 0xEDD3, 'Rip_Play')
    code(d, 0xEDD6, 'Rip_InitSong')
    d.label(0xEDD5, 'Rip_PlayHi')
    d.label(0xEDE4, 'Rip_InitHi')
    bytes_item(d, 0xEDE5, 2, 'Rip_DriverHi', 'high byte of each driver, per song')
    pn = []
    for c in (T, G):
        pn += driver(d, c, s)
    eq = [('RIP_RELOC', '$%04X' % RIP_RELOC, 'the in-game driver ran at $C000 in the game')]
    eq += [(n, v, None) for n, v in CMD_CONST]
    eq += [('zTrkPtr', '$FB', 'track pointer (saved and restored by Play)')]
    ids = []
    for c in (T, G):
        for i in range(c['npat']):
            ids.append(('%sPattern%02d_ID' % (c['P'], i), '$%02X' % i, None))
    d.ram[0xFB] = 'zTrkPtr'
    d.ram[0xFC] = 'zTrkPtr+1'
    return dict(header=hdr, sym=dict(init='Rip_Init', play='Rip_Play'),
                equates=[('constants', eq), ('pattern numbers', ids)])


HEADER = r"""
Mark Cooksey C64 sound driver -- FORGOTTEN WORLDS (1989 US Gold / Capcom)
Later driver: the data format the NES driver (Dragon's Lair, Joe & Mac,
Aladdin) was built on.

Source: Forgotten_Worlds.sid (PSID v2, load $E000-$FA4F, 2 songs).
Reassembles byte-identically to the .sid file:
          ca65 forgotten_worlds_sound.s
          ld65 -C forgotten_worlds_sound.cfg -o out.sid forgotten_worlds_sound.o

The file holds two separate copies of the driver, each with its own song:
  $E000  T_  title driver (song 1). Full build: PWM, vibrato, filter presets
             with a cutoff sweep, 7 instruments, 21 patterns.
  $EE00  G_  in-game driver (song 2). Cut-down build: no PWM, no filter, 3
             instruments, 18 patterns. The game ran it at $C000; the ripper
             moved it to $EE00 and only relocated addresses on code paths the
             tune executes. The rest still point into $C000-$C2FF and are
             written here as Label-RIP_RELOC (RIP_RELOC = $2E00).
  $EDD0      ripper wrapper (PSID init/play).

ENTRY POINTS (per driver)
  +$00  Init   A = song (only 0)        +$03  Play   once per frame (50 Hz)
  Play saves and restores zero page $FB/$FC (the track pointer).

TRACK / PATTERN DATA (2-byte events, same layout as the NES driver)
  byte 0  bit 7     = bit 4 of the instrument number
          bits 0-6  = note $00-$5F (C0-B7, index into FreqLo/FreqHi); the
                      transpose of the current CMD_CALL is added.
                      $60-$7F (with bit 7 clear) = command
  byte 1  bits 4-7  = instrument bits 0-3
          bits 0-3  = length index: DurTable gives the note length in frames,
                      RelTable the frame on which the gate is released
  An event is read one frame before it starts.
  Commands:
    $60 CMD_REST     len            rest (length index as above)
    $61 CMD_TIE                     toggle tie: no gate release and no
                                     retrigger (legato) until toggled back
    $62 CMD_NOP62    x              stores x; nothing reads it
    $63 CMD_VOLUME   v              master volume
    $64 CMD_CALL     pat,trn        play pattern pat once, transposed
    $65 CMD_CALLN    cnt,pat,trn    play pattern pat cnt times (1 level)
    $66 CMD_RETURN                  end of pattern
    $67 CMD_RESTART                 back to the start of the track
    $68 CMD_JUMP     .word addr     continue at addr (song loop)
    $69 CMD_FILTER   n              filter preset n (title driver only)
    $6A CMD_FILTER2  n              same handler as $69
    $6B CMD_STOP                    silence, stop the driver

INSTRUMENTS: one byte per instrument in each column table (InsCtrl ...
InsVibDelay). The in-game build keeps the two PWM columns but never reads
them.

DIFFERENCES FROM THE NES DRIVER
  Same event layout, same command idea ($60 rest, CALL with pattern number
  and transpose, RETURN, JUMP) and nearly the same 16-entry duration table.
  The NES version renumbers the commands ($60 rest, $61 end, $62 call,
  $63 return, $64 jump), moves the duration table pointer into the song,
  and replaces the SID instrument columns with envelope pointers.

Bytes the driver never reads are kept (so the file reassembles) and are
marked "not referenced".
"""
