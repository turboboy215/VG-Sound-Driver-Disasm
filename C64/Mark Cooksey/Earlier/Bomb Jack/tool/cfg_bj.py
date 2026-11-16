"""Bomb Jack (1986 Elite): the early Mark Cooksey C64 driver.

The player is written out three times, once per voice, and keeps all of its
variables inside the image at $73A0-$7447.  Each song is a separate "module"
($8400-$96FA) with its own init routine, three order lists and its patterns."""

from core import h2, h4
from common import var, bytes_item, words_item, lohi_item, code, name_cmp_chain

TITLE = 'Bomb Jack'
SEMI = ['---', 'C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-', '?D', '?E', '?F']


def notename(n):
    s = n & 15
    if s == 0:
        return 'rest'
    return '%s%d' % (SEMI[s], (n >> 4) & 7)


# ----------------------------------------------------------------- variables
VARS = [
    (0x73A0, 'mModeVol', 1, 'shadow SID_MODE_VOL', ['VARIABLES (the values are the ripper\'s snapshot).',
                                                     'Shadow SID registers, written every call by Output.']),
    (0x73A1, 'mResFilt', 1, 'shadow SID_RES_FILT (never changed by the driver)', None),
    (0x73A2, 'mCutoffHi', 1, 'shadow SID_FC_HI (never changed by the driver)', None),
    (0x73A3, 'mCutoffLo', 1, 'shadow SID_FC_LO (never changed by the driver)', None),
    (0x73A4, 'mV1FreqLo', 1, 'voice 1: frequency', ['Shadow voice registers, 7 bytes per voice in SID order:',
                                                   'freq lo/hi, pulse lo/hi, control, AD, SR.']),
    (0x73A5, 'mV1FreqHi', 1, None, None),
    (0x73A6, 'mV1PwLo', 1, 'voice 1: pulse width', None),
    (0x73A7, 'mV1PwHi', 1, None, None),
    (0x73A8, 'mV1Ctrl', 1, 'voice 1: control (waveform, gate on)', None),
    (0x73A9, 'mV1AD', 1, None, None),
    (0x73AA, 'mV1SR', 1, None, None),
    (0x73AB, 'mV2FreqLo', 1, 'voice 2', None),
    (0x73AC, 'mV2FreqHi', 1, None, None),
    (0x73AD, 'mV2PwLo', 1, None, None),
    (0x73AE, 'mV2PwHi', 1, None, None),
    (0x73AF, 'mV2Ctrl', 1, None, None),
    (0x73B0, 'mV2AD', 1, None, None),
    (0x73B1, 'mV2SR', 1, None, None),
    (0x73B2, 'mV3FreqLo', 1, 'voice 3', None),
    (0x73B3, 'mV3FreqHi', 1, None, None),
    (0x73B4, 'mV3PwLo', 1, None, None),
    (0x73B5, 'mV3PwHi', 1, None, None),
    (0x73B6, 'mV3Ctrl', 1, None, None),
    (0x73B7, 'mV3AD', 1, None, None),
    (0x73B8, 'mV3SR', 1, None, None),
    (0x73BE, 'mPwSweepOn', 1, 'pulse sweep: bit n = voice n+1', ['Pulse-width sweep (all voices share speed and range).']),
    (0x73BF, 'mPwSweepSpeed', 1, 'calls per step', None),
    (0x73C0, 'mPwSweepTimer', 1, None, None),
    (0x73C1, 'mPwSweepMin', 1, 'pulse high byte restarts here...', None),
    (0x73C2, 'mPwSweepMax', 1, '...when it reaches this', None),
    (0x73C8, 'mTrillOn', 1, 'octave trill: bit n = voice n+1', ['Octave trill: the frequency is doubled and halved in turn.']),
    (0x73C9, 'mTrillSpeed', 1, 'calls per flip (never set by songs)', None),
    (0x73CA, 'mTrillTimer', 1, None, None),
    (0x73CD, 'mTrillUp', 3, 'per voice: 1 = currently an octave up', None),
    (0x73D2, 'mSlideOn', 1, 'slide: bits 0-2 = on per voice, bits 3-5 = wait for the delay', ['Pitch slide.']),
    (0x73D3, 'mSlideTimer', 3, 'per voice', None),
    (0x73D6, 'mSlideSpeed', 2, 'voices 1, 2 (set by the song init)', None),
    (0x73D8, 'mSlideSpeed3', 1, 'voice 3', None),
    (0x73D9, 'mSlideDelay3', 1, 'voice 3: delay counter', None),
    (0x73DA, 'mSlideDelay3Set', 1, 'voice 3: delay at each note', None),
    (0x73DB, 'mSlideStepHi', 1, 'step added to / taken from the frequency (all voices)', None),
    (0x73DC, 'mSlideStepLo', 1, None, None),
    (0x73DD, 'mSlideFloor', 3, 'per voice: slide down stops at this freq high byte', None),
    (0x73E0, 'mSlideCeil', 2, 'voices 1, 2: slide up stops at this freq high byte', None),
    (0x73E6, 'mSlideCeil3', 1, 'voice 3 (not next to the others)', None),
    (0x73E7, 'mSlideUp', 1, 'bit n = 1: voice n+1 slides up (0 = down)', None),
    (0x73E8, 'mSlideDelay1', 1, 'voice 1: delay counter', None),
    (0x73E9, 'mSlideDelay1Set', 1, 'voice 1: delay at each note', None),
    (0x73EA, 'mSlideDelay2', 1, 'voice 2: delay counter', None),
    (0x73EB, 'mSlideDelay2Set', 1, 'voice 2: delay at each note', None),
    (0x7404, 'mTrackOn', 1, 'bit n = voice n+1 reads its track', ['Player state.']),
    (0x7405, 'mOutputOn', 1, 'bit n = voice n+1 writes the SID (0 = no SID writes at all)', None),
    (0x7406, 'mSpeed', 1, 'calls per tick', None),
    (0x7407, 'mSpeedCount', 1, None, None),
    (0x740E, 'mDrum', 3, 'per voice: drum command ($F6-$FA) playing, 0 = none', None),
    (0x7411, 'mFreqHi', 1, 'NoteToFreq result', None),
    (0x7412, 'mFreqLo', 1, None, None),
    (0x7418, 'mDuration', 3, 'per voice: ticks left of the note', None),
    (0x741B, 'mDrumCount', 3, 'per voice: ticks left of the drum', None),
    (0x7420, 'mNoteTemp', 1, None, None),
    (0x7421, 'mOrderIdx', 3, 'per voice: offset in the order list', None),
    (0x7424, 'mOrder1', 2, 'order list pointers', None),
    (0x7426, 'mOrder2', 2, None, None),
    (0x7428, 'mOrder3', 2, None, None),
]

V = [dict(n=1, zp=0x4B, reg=0x00, bit=1, start=0x746C, tick=0x7476, cnt=0x74AF, read=0x74B7,
          drum=0x74C2, note=0x7517, retrig=0x7545, adv=0x7559, nextpat=0x7A58, cmd=0x7AE2, cmddone=0x7C10),
     dict(n=2, zp=0x4D, reg=0x07, bit=2, start=0x7566, tick=0x7572, cnt=0x75AB, read=0x75B3,
          drum=0x75BE, note=0x7613, retrig=0x7641, adv=0x7650, nextpat=0x7A86, cmd=0x7C27, cmddone=0x7CC3),
     dict(n=3, zp=0x4F, reg=0x0E, bit=4, start=0x765D, tick=0x7669, cnt=0x76A2, read=0x76AA,
          drum=0x76B5, note=0x770A, retrig=0x7738, adv=0x7747, nextpat=0x7AB4, cmd=0x7CDA, cmddone=0x7D57)]

# command parameter count per voice (others: no parameter)
CMDV1 = {0xC8: 1, 0xC9: 1, 0xCA: 1, 0xCB: 1, 0xD8: 2, 0xD9: 1, 0xDA: 2}
CMDV23 = {0xC9: 1, 0xCA: 1, 0xCB: 1, 0xD8: 2}
CMDNAME = {0xC8: 'C_VOLUME', 0xC9: 'C_WAVE', 0xCA: 'C_AD', 0xCB: 'C_SR', 0xCC: 'C_TRACK_ON',
           0xCD: 'C_OUTPUT_ON', 0xCE: 'C_TRACK_OFF', 0xCF: 'C_OUTPUT_OFF', 0xD0: 'C_TRILL',
           0xD1: 'C_PWSWEEP', 0xD2: 'C_SLIDE', 0xD3: 'C_SLIDE_DELAY', 0xD4: 'C_TRILL_OFF',
           0xD5: 'C_PWSWEEP_OFF', 0xD6: 'C_SLIDE_OFF', 0xD7: 'C_DELAY_OFF', 0xD8: 'C_PULSE',
           0xD9: 'C_SPEED', 0xDA: 'C_PWRANGE', 0xF6: 'C_DRUM', 0xF7: 'C_DRUM_F7', 0xF8: 'C_DRUM_F8',
           0xF9: 'C_DRUM_F9', 0xFA: 'C_DRUM_FA'}
CMDDESC = {0xC8: 'mode/volume %s', 0xC9: 'waveform %s', 0xCA: 'attack/decay %s', 0xCB: 'sustain/release %s',
           0xCC: 'voice 1 track on', 0xCD: 'voice 1 SID output on', 0xCE: 'voice 1 track off',
           0xCF: 'voice 1 SID output off', 0xD0: 'octave trill on', 0xD1: 'pulse sweep on',
           0xD2: 'slide on', 0xD3: 'slide on, after the delay', 0xD4: 'octave trill off',
           0xD5: 'pulse sweep off', 0xD6: 'slide off', 0xD7: 'slide delay off', 0xD8: 'pulse width %s',
           0xD9: 'speed %s', 0xDA: 'pulse sweep range %s'}

SONGS = [(0x80F1, 0x8400), (0x80FF, 0x8C4F), (0x810E, 0x8D59), (0x811D, 0x8F25), (0x812C, 0x8FF5),
         (0x813B, 0x9119)]


def code_names(d):
    c = {
        0x7448: ('Play', ['PLAY: called twice per frame by the rip (see Rip_Play).',
                          'Copies the saved pattern pointers of voices 1 and 2 into zero page',
                          '(voice 3 keeps its pointer in $4F/$50 only). Patterns are read every',
                          'mSpeed calls; the effects and the SID writes run on every call.']),
        0x7466: ('Tick', None),
        0x7754: ('Output', ['Write the shadow registers to the SID (if mOutputOn is not 0):',
                            'filter/volume always, each voice unless its output bit is off or a',
                            'drum owns it. The control register is only written at note starts.']),
        0x7804: ('PwSweep', ['Pulse sweep: every mPwSweepSpeed calls, raise the pulse high byte;',
                             'past mPwSweepMax it restarts at mPwSweepMin.']),
        0x7857: ('Trill', ['Octave trill: every mTrillSpeed calls, shift the frequency one octave',
                           'up or back down.']),
        0x78E6: ('Slide1', ['Slide, voice 1: wait for the delay (if bit 3), then every',
                            'mSlideSpeed calls move the frequency by mSlideStep towards',
                            'mSlideFloor / mSlideCeil.']),
        0x7959: ('Slide2', ['Slide, voice 2.']),
        0x79CC: ('Slide3', ['Slide, voice 3 (no voice 3 command turns it on).']),
        0x7A3F: ('PlayDone', None),
        0x7A42: ('SavePtrs', ['Save the voice 1 and 2 pattern pointers.']),
        0x7A57: ('UnusedRts', None),
        0x7D6E: ('NoteToFreq', ['A = note: bits 0-3 semitone (1 = C .. 12 = B, 0 = frequency 0),',
                                'bits 4-6 octave. FreqTable holds octave 5; lower octaves are shifted',
                                'right, 6 and 7 left. Result in mFreqHi/mFreqLo.']),
        0x7DD6: ('Drum_Count', ['X = voice register offset: count the drum down; at 0 the voice goes',
                                'back to its pattern on the next tick.']),
        0x7E11: ('Drum_Noise', ['$F6 drum: noise, AD = $08, SR = $00, frequency high $FA, gate.']),
        0x7E2B: ('Drum_F7', ['$F7-$FA: empty drums. They never count down, so a voice that used', 'one would stop for good.']),
        0x7E2C: ('Drum_F8', None), 0x7E2D: ('Drum_F9', None), 0x7E2E: ('Drum_FA', None),
    }
    for v in V:
        n = v['n']
        p = 'V%d_' % n
        c[v['start']] = (p + 'Start', ['VOICE %d (pattern pointer $%02X/$%02X, SID registers +$%02X).' % (n, v['zp'], v['zp'] + 1, v['reg'])])
        c[v['tick']] = (p + 'Tick', ['A drum playing on this voice replaces the pattern.'])
        c[v['cnt']] = (p + 'Count', ['Count the note down; read the pattern when it reaches 0.'])
        c[v['read']] = (p + 'Read', ['$00 = end of pattern, $01-$C7 = length + note, $C8-$F5 = command,',
                                     '$F6-$FF = drum + count.'])
        c[v['drum']] = (p + 'DrumCmd', ['Drum: count byte, then start the drum.'])
        c[v['note']] = (p + 'Note', ['Length byte, then the note byte (0 = rest).'])
        c[v['retrig']] = (p + 'Gate', ['Gate off; on again unless the note is a rest.'])
        c[v['adv']] = (p + 'Advance', ['Pattern pointer += Y + 1.'])
        c[v['nextpat']] = (p + 'NextPattern', ['End of pattern: next pointer from the order list; a high byte of',
                                               '0 restarts the list.'])
        c[v['cmd']] = (p + 'Command', ['Commands $C8-$F5. Unknown ones are skipped as 1 byte.'])
        c[v['cmddone']] = (p + 'CmdDone', ['Pointer += Y + 1; read the next event in the same call.'])
    for a, (n, cm) in c.items():
        code(d, a, n, cm)


def pattern(d, a, voice, name, seen):
    """decode one pattern; voice decides the command lengths"""
    if a in seen:
        if seen[a] != voice:
            d.comment(a, 'also used by voice %d' % voice)
        return
    seen[a] = voice
    d.label(a, name, primary=True)
    pv = CMDV1 if voice == 1 else CMDV23
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
        if b >= 0xF6:
            cnt = d.b(a + 1)
            nm = CMDNAME.get(b, h2(b))
            d.add(a, 2, [('.byte %s,%s' % (nm, h2(cnt)), 'drum for %d ticks' % ((cnt - 1) & 0xFF if cnt != 1 else 255)
                          if b == 0xF6 else 'empty drum: hangs the voice')])
            a += 2
            continue
        n = pv.get(b, 0)
        args = [d.b(a + 1 + i) for i in range(n)]
        nm = CMDNAME.get(b, h2(b))
        if b in CMDDESC and (voice == 1 or b in CMDV23 or b in (0xD0, 0xD1, 0xD4, 0xD5) or
                             (voice == 2 and b in (0xD2, 0xD6))):
            ds = CMDDESC[b]
            if '%s' in ds:
                if b == 0xD8:
                    ds = ds % ('$%02X%02X' % (args[1], args[0]))
                elif b == 0xDA:
                    ds = ds % ('$%02X-$%02X' % (args[0], args[1]))
                else:
                    ds = ds % h2(args[0])
        else:
            ds = 'ignored on voice %d' % voice
        d.add(a, 1 + n, [('.byte ' + ','.join([nm] + [h2(x) for x in args]), ds)])
        a += 1 + n


def song(d, idx, stub, init):
    P = 'S%d_' % idx
    code(d, init, P + 'Init', ['SONG %d MODULE' % idx, 'Init: first pattern of each voice, order lists, speed,',
                               'counters (order index 2: entry 0 is the pattern loaded here).'])
    # parse the lda #/sta pairs
    a = init
    zp = {}
    order = {}
    ldas = {}
    while d.b(a) != 0x60:
        if d.b(a) == 0xA9:
            imm = d.b(a + 1)
            a2 = a + 2
            last = a
            # following STAs
            while d.b(a2) in (0x85, 0x8D):
                tgt = d.b(a2 + 1) if d.b(a2) == 0x85 else d.w(a2 + 1)
                ldas.setdefault(tgt, (last, imm))
                a2 += 2 if d.b(a2) == 0x85 else 3
            a = a2
        else:
            raise Exception('unexpected byte in song init %04X' % a)
    endinit = a
    ptr = lambda lo: (ldas[lo][1] | ldas[lo + 1][1] << 8)
    pats0 = [ptr(0x4B), ptr(0x4D), ptr(0x4F)]
    orders = [ptr(0x7424), ptr(0x7426), ptr(0x7428)]
    seen = {}
    pnames = {}
    # order lists
    allp = []
    for v in range(3):
        o = orders[v]
        lst = []
        x = o
        while True:
            w = d.w(x)
            lst.append(w)
            x += 2
            if w >> 8 == 0:
                break
        allp.append(lst)
    k = 0
    order_of = {}
    for v in range(3):
        for w in [pats0[v]] + allp[v][:-1]:
            if w not in pnames:
                pnames[w] = '%sPat%02d' % (P, k)
                k += 1
    for v in range(3):
        nm = '%sOrder%d' % (P, v + 1)
        o = orders[v]
        d.label(o, nm, primary=True)
        lst = allp[v]
        d.comment(o, 'Voice %d order list (pattern pointers; high byte 0 = restart).' % (v + 1))
        def lines(dd, lst=lst):
            out = []
            for i in range(0, len(lst) - 1, 4):
                out.append(('.word ' + ', '.join(pnames[w] for w in lst[i:min(i + 4, len(lst) - 1)]), None))
            out.append(('.word %s' % h4(lst[-1]), 'end: back to the start'))
            return out
        d.add(o, 2 * len(lst), lines)
    for v in range(3):
        for w in [pats0[v]] + allp[v][:-1]:
            pattern(d, w, v + 1, pnames[w], seen)
    # symbolic immediates
    for tgt, (la, imm) in ldas.items():
        for base, val in [(0x4B, pats0[0]), (0x4D, pats0[1]), (0x4F, pats0[2]),
                          (0x7424, orders[0]), (0x7426, orders[1]), (0x7428, orders[2])]:
            if tgt == base:
                d.opnd[la] = '<' + (pnames[val] if base < 0x100 else '%sOrder%d' % (P, [0x7424, 0x7426, 0x7428].index(base) + 1))
            elif tgt == base + 1:
                d.opnd[la] = '>' + (pnames[val] if base < 0x100 else '%sOrder%d' % (P, [0x7424, 0x7426, 0x7428].index(base) + 1))
    return pnames


LINEC = {
    0x7556: 'only voice 1 resets its trill state on a new note',
    0x7C6E: 'BUG: the timer is never stored (no STA mPwSweepTimer)',
    0x7C9E: 'BUG: no JMP: falls into the $D2 test with A = pulse high (harmless)',
    0x7E25: 'gate on',
    0x7DAC: 'second CLC (redundant)',
    0x7A3F: 'JMP to the next instruction',
}


def after_trace(d, s):
    d.linec.update(LINEC)
    def pre(n):
        for v in '123':
            if n.startswith('V%s_Command' % v) or n.startswith('V%s_Cmd' % v):
                return 'V%s_Cmd' % v
            if n.startswith('V%s_DrumCmd' % v) or n.startswith('V%s_Drum' % v):
                return 'V%s_Drum' % v
            if n.startswith('V%s_Tick' % v) or n.startswith('V%s_Busy' % v):
                return 'V%s_Busy' % v
        return None
    name_cmp_chain(d, pre)
    for a, n in EXTRA.items():
        d.labels[a][0] = n


EXTRA = {
    0x74AC: 'V1_BusyDone', 0x74BE: 'V1_NotEnd', 0x750D: 'V1_DrumIsFA', 0x751E: 'V1_NoteLen',
    0x75A8: 'V2_BusyDone', 0x75BA: 'V2_NotEnd', 0x7609: 'V2_DrumIsFA', 0x761A: 'V2_NoteLen',
    0x769F: 'V3_BusyDone', 0x76B1: 'V3_NotEnd', 0x7700: 'V3_DrumIsFA', 0x7711: 'V3_NoteLen',
    0x775C: 'Output_Write', 0x77A4: 'Output_V2', 0x77D4: 'Output_V3',
    0x7827: 'PwSweep_V2', 0x783F: 'PwSweep_V3',
    0x785F: 'Trill_Go', 0x7885: 'Trill_V1Down', 0x7890: 'Trill_V2', 0x78B0: 'Trill_V2Down',
    0x78BB: 'Trill_V3', 0x78DB: 'Trill_V3Down',
    0x78F0: 'Slide1_On', 0x7904: 'Slide1_Tick', 0x790C: 'Slide1_Step', 0x793E: 'Slide1_Up',
    0x7963: 'Slide2_On', 0x7977: 'Slide2_Tick', 0x797F: 'Slide2_Step', 0x79B1: 'Slide2_Up',
    0x79D6: 'Slide3_On', 0x79EA: 'Slide3_Tick', 0x79F2: 'Slide3_Step', 0x7A24: 'Slide3_Up',
    0x7A76: 'V1_SetPattern', 0x7AA4: 'V2_SetPattern', 0x7AD2: 'V3_SetPattern',
    0x7DA6: 'NoteToFreq_Down', 0x7DAB: 'NoteToFreq_Shift', 0x7DB6: 'NoteToFreq_Done',
    0x7DE0: 'Drum_Count1Done', 0x7DEB: 'Drum_Count2', 0x7DF5: 'Drum_Count2Done',
    0x7E00: 'Drum_Count3', 0x7E06: 'Drum_Count3Done',
}


def setup(d, s):
    hdr = [';' + '=' * 78]
    for l in HEADER.strip('\n').split('\n'):
        hdr.append((';  ' + l).rstrip())
    hdr.append(';' + '=' * 78)
    hdr.append('')
    for a, n, size, cm, blk in VARS:
        var(d, a, n, size, cm, blk)
    d.label(0x7E2F, 'SavedPtrs', primary=True)
    d.add(0x7E2F, 4, [('.word $%04X, $%04X' % (d.w(0x7E2F), d.w(0x7E31)), 'voice 1 and 2 pattern pointers between calls (snapshot)')])
    # frequency tables
    d.label(0x7DB7, 'FreqTable', primary=True)
    d.comment(0x7DB7, 'Octave 5 frequencies, big-endian (high byte first), index = semitone.')
    d.comment(0x7DB7, 'These are the NTSC values of the C64 Programmer\'s Reference Guide')
    d.comment(0x7DB7, 'table: C5 = $2187 = 523.2 Hz on NTSC, but 504.0 Hz on a PAL C64 (65 cents')
    d.comment(0x7DB7, 'flat). See the tuning notes.')
    names = ['(0)'] + ['%s5' % x for x in SEMI[1:13]]
    lines = []
    for i in range(13):
        v = d.b(0x7DB7 + 2 * i) << 8 | d.b(0x7DB8 + 2 * i)
        lines.append(('.dbyt $%04X' % v, names[i] + ('  %.1f Hz NTSC / %.1f Hz PAL' % (v * 1022727 / 16777216, v * 985248 / 16777216) if i else '  semitone 0: silent')))
    d.add(0x7DB7, 26, lines)
    bytes_item(d, 0x7DD1, 5, 'OctaveShift', 'octave 0-4: shift right this + 1 times')
    code_names(d)
    # rip wrapper
    code(d, 0x8000, 'Rip_Init', ['SID RIPPER WRAPPER (not part of the game).',
                                'Init: A = song; patches the JMP below with that song\'s stub.'])
    d.label(0x800D, 'Rip_InitJmp')
    bytes_item(d, 0x8010, 6, 'Rip_SongLo', None)
    bytes_item(d, 0x8018, 6, 'Rip_SongHi', None)
    code(d, 0x8020, 'Rip_Play', ['Play: calls the driver twice per frame.'])
    for i, (stub, init) in enumerate(SONGS):
        code(d, stub, 'Rip_Song%d' % i, ['Song %d: init its module, then save the pointers.' % i] if i == 0 else None)
    code(d, 0x8158, 'Rip_SongDone', ['Save the zero-page pointers like Play does, slides off.'])
    var(d, 0x814A, 'Rip_BitTarget', 1, 'the stubs BIT this byte (a no-op)')
    for i, (stub, init) in enumerate(SONGS):
        song(d, i, stub, init)
    # rip table: symbolic
    for t, kind in ((0x8010, '.lobytes'), (0x8018, '.hibytes')):
        d.items.pop(t)
        for a in range(t, t + 6):
            d.owner.pop(a)
        d.add(t, 6, [('%s %s' % (kind, ', '.join('Rip_Song%d' % i for i in range(6))), None)])
    eq = [(CMDNAME[k], '$%02X' % k, None) for k in sorted(CMDNAME)]
    d.ram.update({0x4B: 'zPat1', 0x4C: 'zPat1+1', 0x4D: 'zPat2', 0x4E: 'zPat2+1', 0x4F: 'zPat3',
                  0x50: 'zPat3+1', 0x51: 'zOrder', 0x52: 'zOrder+1'})
    zp = [('zPat1', '$4B', 'voice 1 pattern pointer'), ('zPat2', '$4D', 'voice 2 pattern pointer'),
          ('zPat3', '$4F', 'voice 3 pattern pointer (kept only here)'), ('zOrder', '$51', 'order list pointer (temporary)')]
    return dict(header=hdr, sym=dict(init='Rip_Init', play='Rip_Play'),
                equates=[('zero page', zp), ('pattern commands', eq)])


HEADER = r"""
Mark Cooksey C64 sound driver -- BOMB JACK (1986 Elite)
Early driver: one copy of the player code per voice, SID shadow registers,
duration + note byte pairs. Not the format of the NES driver.

Source: Bomb_Jack.sid (PSID v2, load $73A0-$96FA, 6 songs).
Reassembles byte-identically to the .sid file:
          ca65 bomb_jack_sound.s
          ld65 -C bomb_jack_sound.cfg -o out.sid bomb_jack_sound.o

MEMORY
  $73A0-$7447  variables (inside the image)
  $7448-$7E32  player
  $8000-$8171  SID ripper wrapper (not the game's)
  $8400-$96FA  six song modules: init routine, 3 order lists, patterns

TIMING
  Play runs the effects and the SID writes on every call, and reads the
  patterns every mSpeed calls (one "tick"). The rip calls Play twice per
  50 Hz frame.

ORDER LISTS: .word pattern pointers; a high byte of 0 restarts the list.

PATTERNS (read once per tick per voice)
  $00            end of pattern: next order list entry
  $01-$C7 nn     note: length in ticks, then the note byte
                   nn bits 0-3 = semitone (1 = C ... 12 = B), 0 = rest
                   nn bits 4-6 = octave. A rest turns the gate off; a note
                   turns it off and on again (retrigger) when the voice's
                   mOutputOn bit is set.
  $C8-$F5        commands (see the C_ equates). Voice 1 knows all of them;
                 voices 2 and 3 only C9-CB, D0, D1, D4, D5, D8 (+ D2, D6 on
                 voice 2). Other bytes are skipped as 1-byte commands.
    C8 v    SID_MODE_VOL        CC/CE  voice 1 track on/off
    C9 w    waveform (ctrl)     CD/CF  voice 1 SID output on/off
    CA ad   attack/decay        D0/D4  octave trill on/off
    CB sr   sustain/release     D1/D5  pulse sweep on/off
    D8 l h  pulse width         D2/D6  slide on/off
    D9 s    speed (calls/tick)  D3/D7  slide after delay on / delay off
    DA a b  pulse sweep range
  $F6 cnt        noise drum for cnt-1 ticks (the voice's pattern waits)
  $F7-$FA cnt    empty drums (would stop the voice for good; unused)

TUNING: FreqTable holds the NTSC note values from the C64 Programmer's
Reference Guide. On a PAL machine every note is about 65 cents (2/3 of a
semitone) flat. Paperboy, from the same year, already uses PAL values.

Bytes the driver never reads are kept (so the file reassembles) and are
marked "not referenced".
"""
