"""Mark Cooksey NES sound engine: data format walkers shared by all versions."""
from core import Disasm, h2, h4

NOTE = ['C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-']
def notename(n):
    return '%s%d' % (NOTE[n % 12], 2 + n // 12)

CHN = ['Sq1', 'Sq2', 'Tri', 'Noise', 'DMC']


class Engine(Disasm):
    def __init__(self, cfg, data, base):
        super().__init__(data, base, cfg['start'], cfg['end'], cfg['title'])
        self.cfg = cfg
        self.ram = dict(cfg['ram'])
        self.instr_used = set()
        self.durtables = {}   # addr -> max index used
        self.dmc_samples = {}
        self.stream_chan = {}

    # ---------------------------------------------------------- tables
    def split_table(self, lo, hi, n, lname, hname, target_name, desc):
        """lo/hi split pointer table; returns list of targets"""
        tg = [self.b(lo + i) | self.b(hi + i) << 8 for i in range(n)]
        names = [target_name(i, t) for i, t in enumerate(tg)]
        for i, t in enumerate(tg):
            self.label(t, names[i])
        self.label(lo, lname, True)
        self.label(hi, hname, True)
        self.comment(min(lo, hi), ';')
        self.comment(min(lo, hi), '; ' + desc + ' (%d entries, split low/high byte tables)' % n)
        def mk(isl, tg=tg, names=names):
            def f(d):
                rows = []
                refs = [names[i] if names[i] in d.labels.get(t, []) else d.wordref(t) for i, t in enumerate(tg)]
                for i in range(0, len(refs), 4):
                    ch = refs[i:i + 4]
                    rows.append(('%s %s' % ('.lobytes' if isl else '.hibytes', ', '.join(ch)),
                                 '%d-%d' % (i, i + len(ch) - 1) if len(ch) > 1 else '%d' % i))
                return rows
            return f
        self.add(lo, n, mk(True))
        self.add(hi, n, mk(False))
        return tg

    def bytes_item(self, a, n, comment=None, per=16):
        vals = [self.b(a + i) for i in range(n)]
        rows = []
        for i in range(0, n, per):
            rows.append(('.byte ' + ','.join(h2(v) for v in vals[i:i + per]),
                         comment if i == 0 else None))
        self.add(a, n, rows)

    # ---------------------------------------------------------- envelopes
    def env_name(self, kind, a):
        return '%s_%04X' % (kind, a)

    def parse_volenv(self, a, kind='VolEnv'):
        self.label(a, self.env_name(kind, a))
        while True:
            v = self.b(a)
            if v == 0x80:
                if not self.add(a, 1, [('.byte $80', 'end (hold last volume)')]):
                    return
                return
            d = self.b(a + 1)
            if not self.add(a, 2, [('.byte %s,%s' % (h2(v), h2(d)), 'volume %d for %d frame(s)' % (v & 15, d or 256)
                                     + ('' if v < 16 else ' (raw $%02X)' % v))]):
                return
            a += 2

    def parse_loopenv(self, a, kind, what):
        """pitch / arpeggio envelope: (value,frames) pairs, $80 lo hi = jump"""
        self.label(a, self.env_name(kind, a))
        todo = [a]
        while todo:
            a = todo.pop()
            while True:
                v = self.b(a)
                if v == 0x80:
                    t = self.w(a + 1)
                    self.label(t, self.env_name(kind, t) if t not in self.labels else self.labels[t][0])
                    if self.add(a, 3, lambda d, t=t: [('.byte $80', 'jump'), ('.word %s' % d.wordref(t), None)]):
                        todo.append(t)
                    break
                d = self.b(a + 1)
                sv = v - 256 if v >= 128 else v
                if what == 'period':
                    com = ('period %+d, ' % sv if v else '') + 'wait %d' % (d or 256)
                else:
                    com = '%s %+d for %d fr' % (what, sv, d or 256)
                if not self.add(a, 2, [('.byte %s,%s' % (h2(v), h2(d)), com)]):
                    break
                a += 2

    # ---------------------------------------------------------- instruments
    def parse_instrument(self, i, a):
        cfg = self.cfg
        t = self.b(a)
        vol = self.w(a + 1)
        pit = self.w(a + 3)
        duty = self.b(a + 5)
        hi = self.b(a + 6)
        arp = self.w(a + 7)
        has_arp = cfg['has_arp']
        def f(d, t=t, vol=vol, pit=pit, duty=duty, hi=hi, arp=arp):
            rows = [('.byte %s' % h2(t), 'flags: %s' % ('volume envelope' if t < 2 else 'no volume envelope'))]
            if t < 2:
                rows.append(('.word %s' % d.wordref(vol), 'volume envelope'))
            else:
                rows.append(('.byte %s,%s' % (h2(vol & 255), h2(vol >> 8)), '(unused)'))
            rows.append(('.word %s' % d.wordref(pit), 'pitch envelope' + (' (none)' if pit >> 8 == 0 else '')))
            rows.append(('.byte %s' % h2(duty), 'reg0 bits (duty/const/halt): %02X' % duty))
            rows.append(('.byte %s' % h2(hi), 'reg3 bits (length counter)'))
            if has_arp:
                rows.append(('.word %s' % d.wordref(arp), 'arpeggio envelope' + (' (none)' if arp >> 8 == 0 else '')))
            else:
                rows.append(('.word %s' % d.wordref(arp), '(read but ignored in this version)'))
            return rows
        self.add(a, 9, f)
        if t < 2 and vol >> 8:
            self.parse_volenv(vol)
        if pit >> 8:
            self.parse_loopenv(pit, 'PitchEnv', 'period')
        if arp >> 8:
            if has_arp:
                self.parse_loopenv(arp, 'ArpEnv', 'note')
            else:
                if arp not in self.labels:
                    self.comment(arp, '; (arpeggio envelope format - ignored by this engine version)')
                self.parse_loopenv(arp, 'ArpEnv', 'note')

    # ---------------------------------------------------------- streams
    def parse_stream(self, a, ch):
        cfg = self.cfg
        cmds = cfg['cmds']
        while True:
            self.stream_chan.setdefault(a, ch)
            b0 = self.b(a)
            c = b0 & 0x7F
            if c < 0x60:
                b1 = self.b(a + 1)
                if ch == 4:
                    smp = b1 >> 4
                    self.dmc_samples.setdefault(smp, None)
                    com = 'sample %d, rate %d, len[%d]' % (smp, b0 & 15, b1 & 15)
                else:
                    ins = (b0 >> 7) << 4 | b1 >> 4
                    self.instr_used.add(ins)
                    if ch == 3:
                        com = 'noise %s' % h2(c)
                    else:
                        com = notename(c)
                    com = '%-6s ins %2d  len[%d]' % (com, ins, b1 & 15)
                if not self.add(a, 2, lambda d, a=a, b0=b0, b1=b1, com=com: [('.byte %s,%s' % (h2(b0), h2(b1)), com + d.durc(a, b1 & 15))]):
                    return
                a += 2
                continue
            name, kind = cmds[c - 0x60]
            cn = name if not (b0 & 0x80) else name + '|$80'
            if kind == 'rest':
                b1 = self.b(a + 1)
                if not self.add(a, 2, lambda d, a=a, b1=b1, cn=cn: [('.byte %s,%s' % (cn, h2(b1)), 'rest len[%d]' % (b1 & 15) + d.durc(a, b1 & 15))]):
                    return
                a += 2
            elif kind in ('end', 'ret'):
                self.add(a, 1, [('.byte %s' % cn, None)])
                self.stream_ends.append(a + 1)
                return
            elif kind == 'call':
                p, tr, n = self.b(a + 1), self.b(a + 2), self.b(a + 3)
                self.pattern_calls.append((p, ch))
                if not self.add(a, 4, lambda d, p=p, tr=tr, n=n, cn=cn: [
                        ('.byte %s,%s,%s,%s' % (cn, h2(p), h2(tr), h2(n)),
                         '%s, transpose %+d, play %dx' % (d.pattern_name(p), tr - 256 if tr > 127 else tr, n or 256))]):
                    return
                a += 4
            elif kind == 'jump':
                t = self.w(a + 1)
                if t not in self.labels:
                    self.label(t, 'Loop_%04X' % t)
                if not self.add(a, 3, lambda d, t=t, cn=cn: [('.byte %s' % cn, None), ('.word %s' % d.wordref(t), None)]):
                    return
                self.stream_ends.append(a + 3)
                a = t
            elif kind == 'durtab':
                t = self.w(a + 1)
                self.durtables.setdefault(t, set())
                self.label(t, 'DurTable_%04X' % t)
                self.cur_durtab = t
                if not self.add(a, 3, lambda d, t=t, cn=cn: [('.byte %s' % cn, None), ('.word %s' % d.wordref(t), None)]):
                    return
                a += 3
            else:
                raise Exception(kind)

    def pattern_name(self, p):
        return 'Pattern_%02X' % p


    def durc(self, a, idx):
        ts = self.evt_dt.get(a)
        if not ts or None in ts:
            return ''
        fr = set()
        for t in ts:
            fr.add(self.b(t + idx) or 256)
        if len(fr) == 1:
            return ' = %d fr' % fr.pop()
        return ''

    def walk_song(self, start, dt):
        """follow a track statically, recording which duration table is in
        effect at each note/rest event"""
        cmds = self.cfg['cmds']
        seen = set()
        a, ret = start, None
        evs = []
        while True:
            if (a, ret, dt) in seen:
                return evs
            seen.add((a, ret, dt))
            evs.append((a, dt))
            b0 = self.b(a)
            c = b0 & 0x7F
            if c < 0x60:
                a += 2
                continue
            kind = cmds[c - 0x60][1]
            if kind == 'rest':
                a += 2
            elif kind == 'end':
                return evs
            elif kind == 'ret':
                if ret is None:
                    return evs
                a, ret = ret, None
            elif kind == 'call':
                p = self.b(a + 1)
                ret = a + 4
                a = self.ptg[p]
            elif kind == 'jump':
                a = self.w(a + 1)
            elif kind == 'durtab':
                dt = None          # global table pointer changed at run time: ambiguous
                a += 3

    # ---------------------------------------------------------- SFX
    def parse_sfx(self, i, a):
        self._parse_sfx(i, a)
        while a in self.items:
            a += self.items[a].size
        self.sfx_ends.append(a)

    def _parse_sfx(self, i, a):
        fmt = self.cfg['sfx_format']
        chn = self.b(a)
        if chn >= 4:
            if fmt == 'jm':
                vals = [self.b(a + k) for k in range(4)]
                self.add(a, 4, [('.byte %s' % h2(vals[0]), 'channel: DMC'),
                                ('.byte %s,%s,%s' % tuple(h2(v) for v in vals[1:]),
                                 'DMC_START ($%04X), DMC_LEN (%d bytes), DMC_FREQ' % (0xC000 + vals[1] * 64, vals[2] * 16 + 1))])
                self.sample_at(0xC000 + vals[1] * 64, vals[2] * 16 + 1)
            else:
                self.add(a, 1, [('.byte %s' % h2(chn), 'channel >= 4: ignored by Sfx_Play')])
            return
        hd = [self.b(a + k) for k in range(5)]
        if not self.add(a, 5, [('.byte %s' % h2(hd[0]), 'channel: %s' % CHN[chn]),
                               ('.byte %s' % h2(hd[1]), 'speed (frames per step - 1)' if fmt != 'al' else 'delay before the first step'),
                               ('.byte %s,%s,%s' % tuple(h2(v) for v in hd[2:]), 'reg0, reg3, reg2')]):
            return
        a += 5
        while True:
            if fmt == 'al':
                dur = self.b(a)
                if dur == 0xFF:
                    self.add(a, 1, [('.byte $FF', 'end')])
                    return
                v = self.b(a + 1)
                r = self.b(a + 2)
                if r == 0xFF:
                    self.add(a, 3, [('.byte %s,%s,$FF' % (h2(dur), h2(v)), 'restart effect')])
                    return
                if chn == 3:
                    self.add(a, 3, [('.byte %s,%s,%s' % (h2(dur), h2(v), h2(r)),
                                     'delay %d, reg0, period' % dur + (' -> end' if r == 0 else ''))])
                    if r == 0:
                        return
                    a += 3
                else:
                    r2 = self.b(a + 3)
                    self.add(a, 4, [('.byte %s,%s,%s,%s' % (h2(dur), h2(v), h2(r), h2(r2)),
                                     'delay %d, reg0, reg3, reg2' % dur + (' -> end' if r == 0 and r2 == 0 else ''))])
                    if r == 0 and r2 == 0:
                        return
                    a += 4
            else:
                v = self.b(a)
                r = self.b(a + 1)
                if r == 0xFF:
                    self.add(a, 2, [('.byte %s,$FF' % h2(v), 'restart effect')])
                    return
                if chn == 3:
                    self.add(a, 2, [('.byte %s,%s' % (h2(v), h2(r)), 'reg0, period' + (' -> end' if r == 0 else ''))])
                    if r == 0:
                        return
                    a += 2
                else:
                    r2 = self.b(a + 2)
                    self.add(a, 3, [('.byte %s,%s,%s' % (h2(v), h2(r), h2(r2)),
                                     'reg0, reg3, reg2' + (' -> end' if r == 0 and r2 == 0 else ''))])
                    if r == 0 and r2 == 0:
                        return
                    a += 3

    def sample_at(self, addr, length):
        self.samples.setdefault(addr, set()).add(length)


    # ---------------------------------------------------------- unreferenced data
    def orphan_env_scan(self, s, e):
        a = s
        while a < e:
            if self.claimed(a):
                a += 1
                continue
            # try a looping envelope
            p = a
            ok = None
            while p < e and p - a < 128:
                if self.b(p) == 0x80:
                    if p + 2 < e + 1 and p + 2 <= e and self.w(p + 1) >= a and self.w(p + 1) <= p:
                        ok = ('loop', p + 3)
                    else:
                        ok = ('vol', p + 1)
                    break
                p += 2
            if not ok:
                self.warn.append('could not classify %04X-%04X' % (a, e))
                return
            if ok[0] == 'loop':
                self.comment(a, '; (unreferenced envelope - pitch or arpeggio format)')
                self.parse_loopenv(a, 'UnusedEnv', 'value')
            else:
                self.comment(a, '; (unreferenced volume envelope)')
                self.parse_volenv(a, 'UnusedVolEnv')
            a = ok[1]

    def tails(self):
        for a in self.stream_ends:
            if self.inside(a) and not self.claimed(a) and a not in self.labels and self.b(a) & 0x7F == 0x61:
                self.add(a, 1, [('.byte %s' % h2(self.b(a)), 'CMD_END - never reached')])
        for a in self.sfx_ends:
            n = 0
            while n < 4 and self.inside(a + n) and not self.claimed(a + n) and (a + n) not in self.labels:
                n += 1
            if 0 < n < 4:
                self.add(a, n, [('.byte ' + ','.join(h2(self.b(a + k)) for k in range(n)), 'never read')])

    def do_orphans(self):
        cfg = self.cfg
        self.tails()
        for a, n in cfg.get('dead_code', []):
            self.comment(a, ';' + '-' * 70)
            self.comment(a, '; unreferenced code (nothing jumps here)')
            self.code(a, n)
        self.trace()
        for o in cfg.get('orphans', []):
            kind = o[0]
            if kind == 'env':
                self.orphan_env_scan(o[1], o[2])
            elif kind == 'durtab':
                for t in range(o[1], o[2], 16):
                    self.label(t, 'UnusedDurTable_%04X' % t)
                    self.comment(t, '; (unreferenced duration table)')
                    nb = min(16, o[2] - t)
                    vals = [self.b(t + k) for k in range(nb)]
                    self.add(t, nb, [('.byte ' + ','.join(h2(v) for v in vals), None)])
            elif kind == 'stream':
                self.comment(o[1], '; (unreachable)')
                self.parse_stream(o[1], o[2])
            elif kind == 'note':
                self.comment(o[1], '; ' + o[2])
    # ---------------------------------------------------------- top level
    def run(self):
        cfg = self.cfg
        self.pattern_calls = []
        self.stream_ends = []
        self.sfx_ends = []
        self.samples = {}
        for a, n in cfg['code_names'].items():
            self.label(a, n, True)
        for a, n in cfg['entries']:
            self.code(a, n)
        self.trace()
        # command dispatch table
        c = cfg['cmd_table']
        n = len(cfg['cmds'])
        tg = [self.b(c['lo'] + i) | self.b(c['hi'] + i) << 8 for i in range(n)]
        for i, t in enumerate(tg):
            self.code(t, cfg['cmd_handlers'][i])
        self.trace()
        self.split_table(c['lo'], c['hi'], n, 'CmdHandlerLo', 'CmdHandlerHi',
                         lambda i, t: cfg['cmd_handlers'][i], 'Track command handlers, commands $60-$%02X' % (0x60 + n - 1))
        # small tables
        for (a, n, name, com) in cfg['small_tables']:
            self.label(a, name, True)
            self.bytes_item(a, n, com)
        # period tables
        pt = cfg['period']
        self.label(pt['lo'], 'PeriodLo', True)
        self.comment(pt['lo'], ';')
        self.comment(pt['lo'], '; Note period table, low bytes. Index 0 = C2 (65.4 Hz on a square channel).')
        rows = []
        for i in range(0, pt['nlo'], 12):
            rows.append(('.byte ' + ','.join(h2(self.b(pt['lo'] + k)) for k in range(i, min(i + 12, pt['nlo']))),
                         'octave %d' % (2 + i // 12)))
        self.add(pt['lo'], pt['nlo'], rows)
        self.label(pt['hi'], 'PeriodHi', True)
        self.comment(pt['hi'], '; Note period table, high bytes (notes >= $21 use 0)')
        rows = []
        for i in range(0, pt['nhi'], 12):
            rows.append(('.byte ' + ','.join(h2(self.b(pt['hi'] + k)) for k in range(i, min(i + 12, pt['nhi']))),
                         'octave %d' % (2 + i // 12)))
        self.add(pt['hi'], pt['nhi'], rows)
        # instruments
        it = cfg['instr']
        tg = self.split_table(it['lo'], it['hi'], it['n'], 'InstrumentLo', 'InstrumentHi',
                              lambda i, t: 'Instrument_%02X' % i, 'Instrument pointers')
        for i, t in enumerate(tg):
            self.parse_instrument(i, t)
        # DMC samples (JM)
        if 'dmc' in cfg:
            dm = cfg['dmc']
            tg = self.split_table(dm['lo'], dm['hi'], dm['n'], 'DmcSampleLo', 'DmcSampleHi',
                                  lambda i, t: 'DmcSampleDef_%d' % i, 'DMC sample definitions')
            for i, t in enumerate(tg):
                v = [self.b(t + k) for k in range(3)]
                self.add(t, 3, [('.byte %s' % h2(v[0]), 'nonzero = loop sample'),
                                ('.byte %s' % h2(v[1]), 'DMC_START: $%04X' % (0xC000 + v[1] * 64)),
                                ('.byte %s' % h2(v[2]), 'DMC_LEN: %d bytes' % (v[2] * 16 + 1))])
                self.sample_at(0xC000 + v[1] * 64, v[2] * 16 + 1)
        # songs
        sg = cfg['songs']
        nt = sg['ntracks']
        n = sg['n']
        lo, hi = sg['lo'], sg['hi']
        per = nt + 1
        ptrs = [self.b(lo + i) | self.b(hi + i) << 8 for i in range(n * per)]
        self.label(lo, 'SongLo', True)
        self.label(hi, 'SongHi', True)
        self.comment(min(lo, hi), ';')
        self.comment(min(lo, hi), '; Song table: %d songs x %d pointers (%s, duration table)' %
                     (n, per, ', '.join(CHN[:nt])))
        for s in range(n):
            for k in range(nt):
                self.label(ptrs[s * per + k], 'Song%02X_%s' % (s, CHN[k]))
            dt = ptrs[s * per + nt]
            self.durtables.setdefault(dt, set())
            self.label(dt, 'DurTable_%04X' % dt)
        def songtab(isl):
            def f(d):
                rows = []
                for s in range(n):
                    refs = []
                    for k_, p in enumerate(ptrs[s * per:(s + 1) * per]):
                        nm = 'Song%02X_%s' % (s, CHN[k_]) if k_ < nt else None
                        refs.append(nm if nm and nm in d.labels.get(p, []) else d.wordref(p))
                    rows.append(('%s %s' % ('.lobytes' if isl else '.hibytes', ', '.join(refs)), 'song $%02X' % s))
                return rows
            return f
        self.add(lo, n * per, songtab(True))
        self.add(hi, n * per, songtab(False))
        # patterns table
        pt = cfg['patterns']
        ptg = self.split_table(pt['lo'], pt['hi'], pt['n'], 'PatternLo', 'PatternHi',
                               lambda i, t: self.pattern_name(i), 'Pattern (subroutine) pointers, used by CMD_CALL')
        self.ptg = ptg
        for s in range(n):
            for k in range(nt):
                p = ptrs[s * per + k]
                if k == 0 and p not in self.blockc:
                    self.comment(p, ';' + '=' * 70)
                    self.comment(p, '; Song $%02X' % s)
                    self.comment(p, ';' + '=' * 70)
                self.parse_stream(p, k)
        done = set()
        while self.pattern_calls:
            p, ch = self.pattern_calls.pop()
            if (p, ch) in done:
                continue
            done.add((p, ch))
            if p >= len(ptg):
                self.warn.append('pattern index %d out of table' % p)
                continue
            self.parse_stream(ptg[p], ch)
        for p in range(len(ptg)):
            if not self.claimed(ptg[p]):
                self.warn.append('pattern %02X never called; parsed as tone channel' % p)
                self.comment(ptg[p], '; (not called by any song)')
                self.parse_stream(ptg[p], 0)
                while self.pattern_calls:
                    q, ch = self.pattern_calls.pop()
                    if not self.claimed(ptg[q]):
                        self.parse_stream(ptg[q], ch)
        self.evt_dt = {}
        for s_ in range(n):
            dt = ptrs[s_ * per + nt]
            allev = []
            for k in range(nt):
                allev += self.walk_song(ptrs[s_ * per + k], dt)
            if any(d_ is None for _, d_ in allev):   # song switches tables: frames unknown
                allev = [(x, None) for x, _ in allev]
            for x, d_ in allev:
                self.evt_dt.setdefault(x, set()).add(d_)
        # sfx
        sx = cfg['sfx']
        stg = self.split_table(sx['lo'], sx['hi'], sx['n'], 'SfxLo', 'SfxHi',
                               lambda i, t: 'Sfx_%02X' % i, 'Sound effect pointers (index passed in X to Sfx_Play)')
        for i, t in enumerate(stg):
            self.parse_sfx(i, t)
        # duration tables: 16 entries each, may be cut by following data
        for t in sorted(self.durtables):
            nb = 16
            for k in range(1, 16):
                if self.claimed(t + k) or (t + k) in self.labels:
                    nb = k
                    break
            if not self.claimed(t):
                vals = [self.b(t + k) for k in range(nb)]
                self.add(t, nb, [('.byte ' + ','.join(h2(v) for v in vals), 'frames for len[0..%d]' % (nb - 1))])
        self.do_orphans()
        self.linec.update(cfg.get('linec', {}))
        from comments import C
        C = dict(C); C.update(cfg.get('comments', {}))
        for a, ls in list(self.labels.items()):
            for l in ls:
                if l in C and self.items.get(a) and self.items[a].kind == 'code':
                    self.comment(a, ';' + '-' * 70)
                    for t in C[l]:
                        self.comment(a, '; ' + t)
        for f in cfg.get('extra', []):
            f(self)
