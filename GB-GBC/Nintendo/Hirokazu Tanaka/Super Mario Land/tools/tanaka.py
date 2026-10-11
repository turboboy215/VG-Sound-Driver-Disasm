"""Song data model of the Tanaka driver family (SML / Dr. Mario / SML2 / LA / SMBDX / MS2).

Song header : db transpose ; dw lengthTable ; dw ch1, ch2, ch3, ch4   (0 = unused)
Section list: dw pattern ... ; dw $0000 (end) | dw $FFFF, target (loop)
Pattern     : bytes; $00 ends.  The command set differs per version and is passed in `cmds`:
              {byte: (macro_name, [operand kinds])}  operand kinds: 'b' byte, 'w' word pointer (label), 'wave' word pointer to wave
"""
NOTE_NAMES = ['C','Cs','D','Ds','E','F','Fs','G','Gs','A','As','B']

def note_name(b, base=2):
    """note byte -> name; base = byte value of C2"""
    if b < base or (b-base) % 2: return None
    i = (b-base)//2
    if i >= 72: return None
    return f'{NOTE_NAMES[i%12]}{i//12+2}'

class Songs:
    def __init__(self, r, cfg):
        self.r = r; self.cfg = cfg
        self.headers = {}   # addr -> song number
        self.lists = {}     # addr -> channel index
        self.patterns = {}  # addr -> set(channels)
        self.list_words = {}  # addr of list word -> ('pat',p)|('end',)|('loop',tgt)
        self.waves = set(); self.lentabs = set(); self.envs = set()
        self.instr = []     # (addr, ch, bytes)

    def parse(self):
        r = self.r; c = self.cfg
        n = c['song_count']
        hdrs = [r.word(c['song_table']+2*i) for i in range(n)]
        self.hsize = c.get('hdr_size', 11); self.hch = c.get('hdr_ch', 3); self.hlen = c.get('hdr_len', [1])
        self.song_numbers = {}
        for i, h in enumerate(hdrs):
            self.headers.setdefault(h, i+1)
            self.song_numbers.setdefault(h, []).append(i+1)
            for lo in self.hlen: self.lentabs.add(r.word(h+lo))
            for ch in range(4):
                L = r.word(h+self.hch+2*ch)
                if L: self.lists.setdefault(L, set()).add(ch)
        for L, chs in c.get('extra_lists', {}).items(): self.lists.setdefault(L, set()).update(chs)
        list_starts = set(self.lists)
        # first entries are always patterns; iterate so that unterminated lists stop at known data
        for L, chs in self.lists.items():
            p = r.word(L)
            if p >> 8 not in (0, 0xff):
                for ch in chs: self.patterns.setdefault(p, set()).add(ch)
        for p, chs in c.get('extra_patterns', {}).items(): self.patterns.setdefault(p, set()).update(chs)
        first = {p: set(chs) for p, chs in self.patterns.items()}
        prev = None
        while True:
            known = set(self.patterns)
            self.list_words = {}
            pats = {p: set(c) for p, c in first.items()}
            for L, chs in self.lists.items():
                a = L
                while True:
                    if a != L and (a in list_starts or a in known or a in self.headers): break
                    p = r.word(a)
                    if p >> 8 == 0:
                        self.list_words[a] = ('end', p); break
                    if p >> 8 == 0xff:
                        self.list_words[a] = ('loop', r.word(a+2)); break
                    if not r.inreg(p): break
                    self.list_words[a] = ('pat', p)
                    for ch in chs: pats.setdefault(p, set()).add(ch)
                    a += 2
            self.patterns = pats
            key = (frozenset(pats), frozenset(self.list_words))
            if key == prev: break
            prev = key
        # patterns
        self.stops = set(list_starts) | set(self.headers) | set(self.list_words)
        self.unterminated = set()
        self.pat_events = {}
        for p in sorted(self.patterns):
            self.parse_pattern(p)
        return self

    def parse_pattern(self, p):
        r = self.r; cmds = self.cfg['cmds']
        chs = self.patterns[p]
        a = p; ev = []
        while True:
            if a != p and a in self.stops:
                self.unterminated.add(p); break
            b = r.byte(a)
            if b == 0:
                ev.append((a, 'end', [])); a += 1; break
            if b in cmds:
                name, ops = cmds[b]
                vals = []; q = a+1
                for k in ops:
                    if k == 'b': vals.append(('b', r.byte(q))); q += 1
                    elif k in ('w','lentab'):
                        v = r.word(q); vals.append((k, v)); q += 2
                        if k == 'lentab': self.lentabs.add(v)
                    elif k == 'instr_env':
                        # SMB Deluxe: ch3 wave pointer + level; others: envelope byte or table pointer (2nd byte != 0), duty
                        if 2 in chs and len(chs) == 1:
                            v = r.word(q); self.waves.add(v)
                            vals.append(('wave', v)); vals.append(('b', r.byte(q+2))); q += 3
                        elif r.byte(q+1):
                            v = r.word(q); self.envs.add(v)
                            vals.append(('env', v)); vals.append(('b', r.byte(q+2))); q += 3
                        else:
                            vals += [('b', r.byte(q)), ('b', r.byte(q+1)), ('b', r.byte(q+2))]; q += 3
                    elif k == 'instr':
                        # ch3: wave pointer + level; others: 3 bytes
                        if 2 in chs and len(chs) == 1:
                            v = r.word(q); self.waves.add(v)
                            vals.append(('wave', v)); vals.append(('b', r.byte(q+2))); q += 3
                        else:
                            vals += [('b', r.byte(q)), ('b', r.byte(q+1)), ('b', r.byte(q+2))]; q += 3
                            self.instr.append((a, tuple(chs), r.byte(q-3), r.byte(q-2), r.byte(q-1)))
                ev.append((a, name, vals)); a = q
                continue
            ev.append((a, 'byte', [b])); a += 1
        self.pat_events[p] = (ev, a)

    # ---------- emission
    def note_text(self, b, chs):
        c = self.cfg
        if b == 1: return 'REST'
        if 0xa0 <= b <= 0xaf: return c['len_names'][b-0xa0]
        if 3 in chs:
            return c.get('noise_names', {}).get(b, f'${b:02x}')
        n = note_name(b)
        return n if n else f'${b:02x}'

    def register(self):
        r = self.r; c = self.cfg; sl = c.get('song_label', lambda n: f'Song{n:02d}')
        # headers
        for h, num in self.headers.items():
            sl = c.get('song_label', lambda n: f'Song{n:02d}')
            r.label(h, f'{sl(num)}_Header')
            nums = self.song_numbers[h]
            if len(nums) > 1: r.comments[h] = 'songs ' + ', '.join(c.get('song_num_text', str)(x) for x in nums)
            def em(rr, a):
                lts = [rr.sym_addr(rr.word(a+lo)) for lo in self.hlen]
                chs = []
                for ch in range(4):
                    L = rr.word(a+self.hch+2*ch)
                    chs.append(rr.sym_addr(L) if L else '0')
                return [f'\tSONG ${rr.byte(a):02x}, ' + ', '.join(lts) + ', ' + ', '.join(chs)]
            r.block(h, self.hsize, em)
        # lists (each list word is its own block so shared tails keep labels)
        songof = {}
        for h, num in self.headers.items():
            for ch in range(4):
                L = r.word(h+self.hch+2*ch)
                if L: songof.setdefault(L, (num, ch))
        sl = c.get('song_label', lambda n: f'Song{n:02d}')
        for L, (num, ch) in songof.items():
            if L not in r.labels: r.label(L, f'{sl(num)}_Ch{ch+1}')
        for L in c.get('extra_lists', {}):
            if L not in r.labels: r.label(L, f'UnusedList_{L:04X}')
        for p in c.get('extra_patterns', {}):
            r.comments.setdefault(p, 'unreferenced')
        for a, (k, v) in self.list_words.items():
            if k == 'pat':
                r.block(a, 2, lambda rr, a, v=v: [f'\tdw {rr.sym_addr(v)}'])
            elif k == 'end':
                r.block(a, 2, lambda rr, a, v=v: ['\tLIST_END' if v == 0 else f'\tdw ${v:04x}'])
            else:
                r.block(a, 4, lambda rr, a, v=v: [f'\tLIST_LOOP {rr.sym_addr(v)}'])
                tnum = None
                if v not in r.labels:
                    # label loop target inside its list
                    base = max(x for x in songof if x <= v)
                    n2, ch2 = songof[base]
                    nm = f'{sl(n2)}_Ch{ch2+1}_Loop'; k = 2
                    while nm in r.labels.values(): nm = f'{sl(n2)}_Ch{ch2+1}_Loop{k}'; k += 1
                    r.label(v, nm)
        # patterns: one block per pattern span; overlapping spans get merged in the emitter
        spans = sorted((p, self.pat_events[p][1]) for p in self.pat_events)
        merged = []
        for p, e in spans:
            if merged and p < merged[-1][1]:
                merged[-1][1] = max(merged[-1][1], e); merged[-1][2].append(p)
            else:
                merged.append([p, e, [p]])
        for p, e, starts in merged:
            for s in starts:
                if s not in r.labels: r.label(s, f'Pattern_{s:04X}')
                if s in self.unterminated and s not in r.comments:
                    r.comments[s] = c.get('unterminated_comment', 'no PAT_END: the channel never gets this far (ch1 ends the song first)')
            evs = {}
            for s in starts:
                for ev in self.pat_events[s][0]: evs.setdefault(ev[0], (ev, self.patterns[s]))
            def em(rr, a, p=p, e=e, starts=starts, evs=evs):
                lines = []; cur = []
                q = p
                def flush():
                    if cur: lines.append('\tdb ' + ', '.join(cur)); cur.clear()
                while q < e:
                    if q != p and q in rr.labels:
                        flush(); lines.append(rr.labels[q] + ':')
                    ev, chs = evs[q]
                    _, kind, vals = ev
                    if kind == 'byte':
                        cur.append(self.note_text(vals[0], chs)); q += 1
                        if len(cur) >= 16: flush()
                        continue
                    if kind == 'end':
                        cur.append('PAT_END'); flush(); q += 1; continue
                    flush()
                    ops = []
                    size = 1
                    for k, v in vals:
                        if k == 'b': ops.append(f'${v:02x}'); size += 1
                        else: ops.append(rr.sym_addr(v)); size += 2
                    inner = [x for x in rr.labels if q < x < q + size]
                    if inner:   # another pattern starts inside this command's operands: raw bytes
                        lines.append('\tdb ' + ', '.join(f'${rr.byte(x):02x}' for x in range(q, min(inner))) + f'\t; {kind} (operands continue into the next pattern)')
                        q = min(inner)
                        continue
                    if vals and vals[0][0] == 'wave': kind = kind + '_WAVE'
                    if vals and vals[0][0] == 'env': kind = kind + '_ENV'
                    lines.append(f'\t{kind} ' + ', '.join(ops) if ops else f'\t{kind}')
                    q += size
                flush()
                return lines
            r.block(p, e-p, em)
        for w in self.waves:
            if w not in r.labels: r.label(w, f'Wave_{w:04X}')
        for w in self.envs:
            if w not in r.labels: r.label(w, f'Envelope_{w:04X}')
        for t in self.lentabs:
            if t not in r.labels: r.label(t, f'LengthTable_{t:04X}')
