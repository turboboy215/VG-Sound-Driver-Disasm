"""Make Software NES sound engine (Duck Tales 2, Chip 'n Dale 2):
data format walkers shared by both versions."""
from core import Disasm, h2, h4

NOTE = ['C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-']
CHN = ['Sq1', 'Sq2', 'Tri', 'Noise', 'SfxSq2', 'SfxNoise']

# command byte -> (equate name, number of argument bytes, kind)
CMDS = {}
for o in range(7):
    CMDS[0xD0 + o] = ('CMD_OCTAVE%d' % o, 0, 'oct')
CMDS.update({
    0xD7: ('CMD_OCTAVE_UP', 0, 'octup'),
    0xD8: ('CMD_OCTAVE_DOWN', 0, 'octdn'),
    0xD9: ('CMD_TRANSPOSE', 1, 'arg'),
    0xDA: ('CMD_TRANSPOSE_ADD', 1, 'arg'),
    0xDB: ('CMD_DETUNE', 1, 'arg'),
    0xE0: ('CMD_SPEED', 1, 'speed'),
    0xE1: ('CMD_DUTY', 1, 'arg'),
    0xE2: ('CMD_ENVELOPE', 1, 'env'),
    0xE3: ('CMD_NOP_E3', 1, 'arg'),
    0xE4: ('CMD_NOP_E4', 1, 'arg'),
    0xE5: ('CMD_NOP_E5', 1, 'arg'),
    0xE8: ('CMD_TIE', 0, 'arg'),
    0xE9: ('CMD_VOLUME', 1, 'arg'),
    0xEA: ('CMD_VOLUME_ADD', 1, 'arg'),
    0xEB: ('CMD_SWEEP', 1, 'arg'),
    0xEC: ('CMD_SWEEP_OFF', 0, 'arg'),
    0xED: ('CMD_DRUM_SWAP', 1, 'arg'),
    0xF0: ('CMD_LOOP', 1, 'loop'),
    0xF1: ('CMD_LOOP_END', 0, 'next'),
    0xF2: ('CMD_CALL', 2, 'call'),
    0xF3: ('CMD_RETURN', 0, 'ret'),
    0xF8: ('CMD_JUMP', 2, 'jump'),
    0xFF: ('CMD_END', 0, 'end'),
})
CMD_HANDLERS = {
    0xD0: 'Cmd_Octave0', 0xD1: 'Cmd_Octave1', 0xD2: 'Cmd_Octave2', 0xD3: 'Cmd_Octave3',
    0xD4: 'Cmd_Octave4', 0xD5: 'Cmd_Octave5', 0xD6: 'Cmd_Octave6', 0xD7: 'Cmd_OctaveUp',
    0xD8: 'Cmd_OctaveDown', 0xD9: 'Cmd_Transpose', 0xDA: 'Cmd_TransposeAdd', 0xDB: 'Cmd_Detune',
    0xE0: 'Cmd_Speed', 0xE1: 'Cmd_Duty', 0xE2: 'Cmd_Envelope', 0xE3: 'Cmd_NopE3',
    0xE4: 'Cmd_NopE4', 0xE5: 'Cmd_NopE5', 0xE8: 'Cmd_Tie', 0xE9: 'Cmd_Volume',
    0xEA: 'Cmd_VolumeAdd', 0xEB: 'Cmd_Sweep', 0xEC: 'Cmd_SweepOff', 0xED: 'Cmd_DrumSwap',
    0xF0: 'Cmd_Loop', 0xF1: 'Cmd_LoopEnd', 0xF2: 'Cmd_Call', 0xF3: 'Cmd_Return',
    0xF8: 'Cmd_Jump', 0xFF: 'Cmd_End',
}

def sgn(v):
    return v - 256 if v > 127 else v


class Engine(Disasm):
    def __init__(self, cfg, data, base):
        super().__init__(data, base, cfg['start'], cfg['end'], cfg['title'])
        self.cfg = cfg
        self.ram = dict(cfg['ram'])
        self.imm = dict(cfg.get('imm', {}))
        self.env_used = set()
        self.drum_used = set()
        self.track_owner = {}      # stream start -> set of channels
        self.evstate = {}          # event addr -> set of (octave, speed)

    # ---------------------------------------------------------- code operands
    def fmt_code(self, it):
        mn, md, v = it.lines
        if md == 'imm' and it.addr in self.imm:
            return '%s #%s' % (mn, self.imm[it.addr])
        return super().fmt_code(it)

    # ---------------------------------------------------------- helpers
    def word_table(self, a, n, name, target, desc, per=4, rowc=None):
        """table of n little-endian words; target(i, t) -> label name or None"""
        tg = [self.w(a + 2 * i) for i in range(n)]
        names = []
        for i, t in enumerate(tg):
            nm = target(i, t) if t else None
            if nm:
                self.label(t, nm)
            names.append(nm)
        self.label(a, name, True)
        self.comment(a, ';')
        self.comment(a, '; ' + desc)
        def f(d):
            rows = []
            refs = [names[i] if names[i] and names[i] in d.labels.get(t, []) else d.wordref(t)
                    for i, t in enumerate(tg)]
            for i in range(0, n, per):
                ch = refs[i:i + per]
                c = rowc(i) if rowc else ('$%02X-$%02X' % (i, i + len(ch) - 1) if len(ch) > 1 else '$%02X' % i)
                rows.append(('.word ' + ', '.join(ch), c))
            return rows
        self.add(a, 2 * n, f)
        return tg

    def bytes_item(self, a, n, comment=None, per=16):
        vals = [self.b(a + i) for i in range(n)]
        rows = []
        for i in range(0, n, per):
            rows.append(('.byte ' + ','.join(h2(v) for v in vals[i:i + per]),
                         comment if i == 0 else None))
        self.add(a, n, rows)

    # ---------------------------------------------------------- envelopes
    def parse_env(self, a):
        """volume envelope: frames,dlo,dhi segments; $FE lo hi = set; $FF = end"""
        while True:
            v = self.b(a)
            if v == 0xFF:
                self.add(a, 1, [('.byte $FF', 'end: volume 0, envelope off')])
                return
            lo, hi = self.b(a + 1), self.b(a + 2)
            if v == 0xFE:
                ok = self.add(a, 3, [('.byte $FE,%s,%s' % (h2(lo), h2(hi)),
                                      'set volume %d (%s)' % (hi >> 4, h4(hi << 8 | lo)))])
            else:
                dv = hi << 8 | lo
                if dv >= 0x8000:
                    dv -= 0x10000
                ok = self.add(a, 3, [('.byte %s,%s,%s' % (h2(v), h2(lo), h2(hi)),
                                      '%3d frame(s), %+.4f per frame' % (v or 256, dv / 4096.0))])
            if not ok:
                return
            a += 3

    # ---------------------------------------------------------- drum macros
    def parse_drum(self, a):
        """noise drum macro: one step per frame (see header)"""
        while True:
            v = self.b(a)
            if v == 0xFF:
                self.add(a, 1, [('.byte $FF', 'end (stays here)')])
                return
            k = v & 0xE0
            if k == 0x00:
                ok = self.add(a, 1, [('.byte %s' % h2(v), 'noise period %d, next frame' % ((v & 0x1F) >> 1))])
            elif k == 0xE0:
                ok = self.add(a, 1, [('.byte %s' % h2(v), 'duty %d' % (v & 3))])
            elif k in (0x80, 0xA0):
                self.env_used.add(v & 0x3F)
                ok = self.add(a, 1, [('.byte %s' % h2(v), 'volume envelope $%02X' % (v & 0x3F))])
            elif k == 0x40:
                lo = self.b(a + 1)
                p = (v & 0x0F) << 8 | lo
                ok = self.add(a, 2, [('.byte %s,%s' % (h2(v), h2(lo)),
                                      'square 2 tone, period %s, next frame' % h4(p >> 1))])
                a += 1
            else:
                self.add(a, 1, [('.byte %s' % h2(v), 'end (any other value)')])
                return
            if not ok:
                return
            a += 1

    # ---------------------------------------------------------- tracks
    def parse_stream(self, a, ch):
        """mark every byte of a track; records call targets"""
        while True:
            self.track_owner.setdefault(a, set()).add(ch)
            v = self.b(a)
            if v < 0xD0:
                if not self.add(a, 1, lambda d, a=a, v=v, ch=ch: [('.byte %s' % h2(v), d.evcomment(a, v, ch))], 'ev'):
                    return
                a += 1
                continue
            if v not in CMDS:
                self.warn.append('unused command %02X at %04X' % (v, a))
                self.add(a, 1, [('.byte %s' % h2(v), 'UNUSED COMMAND (handler $0000)')])
                return
            name, n, kind = CMDS[v]
            if kind in ('call', 'jump'):
                t = self.w(a + 1)
                if kind == 'call':
                    if t not in self.labels:
                        self.label(t, 'Sub_%04X' % t)
                    self.calls.append((t, ch))
                else:
                    if t not in self.labels:
                        self.label(t, 'Loop_%04X' % t)
                if not self.add(a, 3, lambda d, t=t, name=name: [('.byte %s' % name, None), ('.word %s' % d.wordref(t), None)]):
                    return
                if kind == 'jump':
                    self.ends.append(a + 3)
                    if not self.claimed(t):
                        self.calls.append((t, ch))
                    return
                a += 3
                continue
            if n == 0:
                ok = self.add(a, 1, [('.byte %s' % name, None)])
            else:
                arg = self.b(a + 1)
                ok = self.add(a, 2, lambda d, a=a, arg=arg, name=name, kind=kind, ch=ch:
                              [('.byte %s,%s' % (name, h2(arg)), d.cmdcomment(a, name, arg, ch))])
                if kind == 'env':
                    self.env_used.add(arg & 0x7F)
            if not ok:
                return
            if kind in ('end', 'ret'):
                self.ends.append(a + 1)
                return
            a += 1 + n

    def cmdcomment(self, a, name, arg, ch):
        if name == 'CMD_SPEED':
            return 'note length x%d' % (arg or 1) if arg else 'note length x1 (0 = off)'
        if name == 'CMD_DUTY':
            return 'duty %d' % (arg & 3)
        if name == 'CMD_ENVELOPE':
            if (arg & 0x7F) in getattr(self, 'bad_envs', ()):
                t = self.w(self.cfg['envs'] + 2 * (arg & 0x7F))
                return 'BUG: envelope $%02X points at %s, read as an envelope' % (arg & 0x7F, self.name(t))
            return 'volume envelope $%02X (starts with the next note)' % (arg & 0x7F)
        if name in ('CMD_TRANSPOSE',):
            return '%+d semitones' % sgn(arg)
        if name == 'CMD_TRANSPOSE_ADD':
            return 'transpose %+d more' % sgn(arg)
        if name == 'CMD_DETUNE':
            return 'period %+d' % sgn(arg)
        if name == 'CMD_VOLUME':
            return 'volume -%d' % arg
        if name == 'CMD_VOLUME_ADD':
            return 'volume attenuation %+d' % sgn(arg)
        if name == 'CMD_SWEEP':
            return 'sweep register %s' % h2(arg)
        if name == 'CMD_DRUM_SWAP':
            return 'swap drum map entries %d and %d' % (arg >> 4, arg & 15)
        if name == 'CMD_LOOP':
            return 'repeat %dx' % (arg or 256)
        if name.startswith('CMD_NOP'):
            return 'does nothing (argument skipped)'
        return None

    def evcomment(self, a, v, ch):
        n, ln = v >> 4, (v & 15) + 1
        st = self.evstate.get(a, set())
        octs = set(o for o, s in st)
        spds = set(s for o, s in st)
        if len(spds) == 1:
            s = spds.pop()
            fr = ' = %d fr' % (ln * s if s else ln)
        else:
            fr = ''
        lt = 'len %d%s' % (ln, fr)
        if n == 0xC:
            return '%-8s %s' % ('rest', lt)
        chs = self.track_owner.get(a, set())
        if chs and all(c == 3 for c in chs):
            self.drum_used.add(n)
            return '%-8s %s' % ('drum %d' % n, lt)
        if chs and all(c == 5 for c in chs):
            return '%-8s %s' % ('noise %X' % n, lt)
        if n > 11:
            return '%-8s %s' % ('note %X?' % n, lt)
        if octs and len(octs) <= 3 and all(0 <= o < 10 for o in octs):
            return '%-8s %s' % ('/'.join('%s%d' % (NOTE[n], o) for o in sorted(octs)), lt)
        return '%-8s %s' % (NOTE[n] + '?', lt)

    def simulate(self, start):
        """follow one track with octave/speed state, to comment notes"""
        seen = set()
        work = [(start, 0, 0, ())]
        steps = 0
        while work:
            a, o, s, stk = work.pop()
            while steps < 400000:
                steps += 1
                key = (a, o, s, stk)
                if key in seen:
                    break
                seen.add(key)
                v = self.b(a)
                if v < 0xD0:
                    self.evstate.setdefault(a, set()).add((o, s))
                    a += 1
                    continue
                if v not in CMDS:
                    break
                name, n, kind = CMDS[v]
                if kind == 'oct':
                    o = v - 0xD0
                elif kind == 'octup':
                    o += 1
                elif kind == 'octdn':
                    o -= 1
                elif kind == 'speed':
                    s = self.b(a + 1)
                elif kind == 'loop':
                    stk = stk + (('L', a + 2, self.b(a + 1)),)
                elif kind == 'next':
                    if stk and stk[-1][0] == 'L':
                        _, la, cnt = stk[-1]
                        cnt = (cnt - 1) & 255
                        if cnt:
                            stk = stk[:-1] + (('L', la, cnt),)
                            a = la
                            continue
                        stk = stk[:-1]
                elif kind == 'call':
                    stk = stk + (('C', a + 3),)
                    a = self.w(a + 1)
                    continue
                elif kind == 'ret':
                    if stk and stk[-1][0] == 'C':
                        a = stk[-1][1]
                        stk = stk[:-1]
                        continue
                    break
                elif kind == 'jump':
                    a = self.w(a + 1)
                    continue
                elif kind == 'end':
                    break
                a += 1 + n
        if steps >= 400000:
            self.warn.append('simulation limit at %04X' % start)

    # ---------------------------------------------------------- top level
    def run(self):
        cfg = self.cfg
        self.calls = []
        self.ends = []
        for a, n in cfg['code_names'].items():
            self.label(a, n, True)
        for a, n in cfg['entries']:
            self.code(a, n)
        self.trace()
        # jump tables
        for key, n, base, names, desc in (
                ('out_table', 6, None, cfg['out_names'], 'Register output routine per channel (X = 0-5)'),
                ('req_table', 7, 0x79, cfg['req_names'], 'Special requests $79-$7F (zSoundReq)'),
                ('cmd_table', 48, 0xD0, None, 'Track command handlers, commands $D0-$FF ($0000 = not used)')):
            a = cfg[key]
            tg = [self.w(a + 2 * i) for i in range(n)]
            for i, t in enumerate(tg):
                if t:
                    nm = names[i] if names else CMD_HANDLERS[0xD0 + i]
                    self.code(t, nm)
            self.trace()
            label = {'out_table': 'OutputTable', 'req_table': 'RequestTable', 'cmd_table': 'CmdTable'}[key]
            def rowc(i, base=base, n=n):
                if base is None:
                    return 'channel %d (%s)' % (i, CHN[i])
                if base == 0xD0:
                    c = 0xD0 + i
                    return '$%02X %s' % (c, CMDS[c][0]) if c in CMDS else '$%02X (unused)' % c
                return '$%02X' % (base + i)
            self.word_table(a, n, label, lambda i, t: None, desc, per=1, rowc=rowc)
        # return address pushed by the track reader
        ra = cfg['ret_addr']
        tgt = (self.b(ra) | self.b(ra + 1) << 8) + 1
        self.label(ra, 'TrackLoopRet', True)
        self.comment(ra, '; return address (minus 1) pushed before a command handler runs,')
        self.comment(ra, '; so that its RTS reads the next track byte')
        self.add(ra, 2, lambda d, t=tgt: [('.byte <(%s-1), >(%s-1)' % (d.name(t), d.name(t)), None)])
        # small tables
        for (a, n, name, com) in cfg['small_tables']:
            self.label(a, name, True)
            self.bytes_item(a, n, com)
        # period table
        pt = cfg['period']
        self.label(pt, 'PeriodTable', True)
        self.comment(pt, ';')
        self.comment(pt, '; Note periods x 2 (the output routine shifts right once), 12 per octave.')
        self.comment(pt, '; Index 0 = C0; the entries below A0 are 0. Square: 1789773 / (16 * (value/2 + 1)) Hz;')
        self.comment(pt, '; the triangle sounds an octave lower.')
        rows = []
        for o in range(7):
            rows.append(('.word ' + ','.join(h4(self.w(pt + 2 * (o * 12 + k))) for k in range(12)), 'octave %d' % o))
        self.add(pt, 168, rows)
        # sound table
        st = cfg['sounds']
        n = cfg['nsounds']
        hdrs = [self.w(st + 2 * i) for i in range(n)]
        hname = {}
        for i, h in enumerate(hdrs):
            hname.setdefault(h, 'Sound_%02X' % i)
        self.word_table(st, n, 'SoundTable', lambda i, t: hname[t],
                        'Sound table, indexed by the request number (zSoundReq $01-$%02X; $00 = reset). '
                        'Requests $%02X-$78 would read past the end.' % (n - 1, n), per=1,
                        rowc=lambda i: '$%02X %s' % (i, self.sound_kind(hdrs[i])))
        self.headers = {}
        for i, h in enumerate(hdrs):
            if h in self.headers:
                continue
            m = self.b(h)
            chans = [k for k in range(4) if m >> k & 1] if not (m & 0x30) else [4 + k for k in range(2) if m >> (4 + k) & 1]
            ptrs = [self.w(h + 1 + 2 * j) for j in range(len(chans))]
            self.headers[h] = (m, chans, ptrs)
            same = [j for j, x in enumerate(hdrs) if x == h]
            self.comment(h, ';' + '=' * 70)
            self.comment(h, '; ' + ', '.join('Sound $%02X' % j for j in same) + ' (%s)' % self.sound_kind(h))
            self.comment(h, ';' + '=' * 70)
            for c, p in zip(chans, ptrs):
                self.label(p, 'Snd%02X_%s' % (same[0], CHN[c]))
            def f(d, h=h, m=m, chans=chans, ptrs=ptrs):
                rows = [('.byte %s' % h2(m), 'channels: ' + (', '.join(CHN[c] for c in chans) or 'none (stops the music)'))]
                for p in ptrs:
                    rows.append(('.word %s' % d.wordref(p), None))
                return rows
            self.add(h, 1 + 2 * len(chans), f)
        for h, (m, chans, ptrs) in self.headers.items():
            for c, p in zip(chans, ptrs):
                self.parse_stream(p, c)
                self.simulate(p)
        # default (silent) track used by Chan_Reset
        dt = cfg['silent_track']
        self.label(dt, 'SilentTrack', True)
        self.comment(dt, '; every channel points here after a reset')
        self.parse_stream(dt, 0)
        while self.calls:
            t, ch = self.calls.pop()
            self.parse_stream(t, ch)
        # drums
        dtab = cfg['drums']
        nd = cfg['ndrums']
        dtg = self.word_table(dtab, nd, 'DrumTable', lambda i, t: None,
                              'Noise drum macros, indexed by mDrumMap[note] (13 entries)', per=1)
        for i, t in enumerate(dtg):
            if t != cfg['silent_drum'] and not self.name(t):
                self.label(t, 'Drum_%02X' % i)
        self.label(cfg['silent_drum'], 'Drum_Silent', True)
        for t in dtg:
            self.parse_drum(t)
        self.parse_drum(cfg['silent_drum'])
        # envelopes
        et = cfg['envs']
        ne = cfg['nenvs']
        etw = [self.w(et + 2 * i) for i in range(ne)]
        bad = set(i for i, t in enumerate(etw) if self.claimed(t))
        self.bad_envs = bad
        def envc(i):
            if i in bad:
                return '$%02X (not an envelope: points at other data%s)' % (i, '' if i not in self.env_used else ' - USED')
            return '$%02X' % i + ('' if i in self.env_used else ' (not used by any track or drum)')
        etg = self.word_table(et, ne, 'EnvTable', lambda i, t: None,
                              'Volume envelopes (CMD_ENVELOPE n, drum $80+n)', per=1, rowc=envc)
        for i, t in enumerate(etg):
            if i not in bad and not self.name(t):
                self.label(t, 'Env_%02X' % i)
        for i, t in enumerate(etg):
            if i not in bad:
                self.parse_env(t)
        for e in sorted(self.env_used):
            if e >= ne:
                self.warn.append('envelope %02X used but outside the table' % e)
        # bytes left after a CMD_JUMP / CMD_END that nothing reaches
        for a in sorted(set(self.ends)):
            if not self.inside(a) or self.claimed(a) or a in self.labels:
                continue
            k = a
            while k < a + 8 and self.inside(k) and not self.claimed(k) and self.b(k) != 0xFF:
                k += 1
            if k < a + 8 and self.inside(k) and not self.claimed(k) and self.b(k) == 0xFF:
                self.comment(a, '; (never reached)')
                self.parse_stream(a, None)
        for x, n_ in cfg.get('dead_code', []):
            self.comment(x, ';' + '-' * 70)
            self.comment(x, '; unreferenced code (nothing jumps here)')
            self.code(x, n_)
        self.trace()
        for o in cfg.get('orphans', []):
            if o[0] == 'stream':
                self.comment(o[1], '; (not referenced: track data)')
                self.parse_stream(o[1], o[2])
        # immediate operands that are addresses of data in this file
        ims = cfg.get('imm_store', {})
        for a in sorted(self.items):
            it = self.items[a]
            if it.kind != 'code' or it.lines[:2] != ('lda', 'imm'):
                continue
            nx = self.items.get(a + 2)
            if nx and nx.kind == 'code' and nx.lines[0] == 'sta' and nx.lines[2] in ims:
                self.imm[a] = ims[nx.lines[2]]
        self.linec.update(cfg.get('linec', {}))
        from mkcomments import C
        C = dict(C); C.update(cfg.get('comments', {}))
        for a, ls in list(self.labels.items()):
            for l in ls:
                if l in C and self.items.get(a) and self.items[a].kind == 'code':
                    self.comment(a, ';' + '-' * 70)
                    for t in C[l]:
                        self.comment(a, '; ' + t)

    def sound_kind(self, h):
        m = self.b(h)
        if m & 0x30:
            return 'sound effect'
        if m & 0x0F:
            return 'music'
        return 'empty: stops the music'
