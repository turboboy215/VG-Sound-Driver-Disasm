"""Structure parser for QuickThunder GB(C) sound data.

Builds a map of 'items' (address -> Item) covering the sound data of one bank, and a
label map, following the data the way the driver reads it."""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qtcfg import GAMES, load

NOTE = ['C', 'Cs', 'D', 'Ds', 'E', 'F', 'Fs', 'G', 'Gs', 'A', 'As', 'B']


def notename(n):
    return '%s%d' % (NOTE[n % 12], n // 12 + 2)


class Item:
    __slots__ = ('addr', 'size', 'kind', 'f')

    def __init__(s, addr, size, kind, **f):
        s.addr, s.size, s.kind, s.f = addr, size, kind, f


class Data:
    def __init__(s, g):
        s.g = g
        s.c = GAMES[g]
        s.m, s.rom = load(g)
        s.items = {}
        s.owner = {}          # byte -> item start
        s.labels = {}         # addr -> name
        s.warn = []
        s.songs = []
        s.sfx = []
        s.pat_uses = {}       # pattern index -> set of channels
        s.ins_uses = {}       # instrument index -> set of channels (1-3 instab, 4 instab4)
        s.pcm = []
        s.bad_ins = []
        s.notes = []
        s.dbg = None
        s.datalo = 0x4000
        s.lo, s.hi = 0x4000, 0x8000

    # ---------------------------------------------------------------- helpers
    def b(s, a):
        return s.m[a] if 0 <= a < len(s.m) else 0

    def w(s, a):
        return s.b(a) | s.b(a + 1) << 8

    def add(s, addr, size, kind, **f):
        if not (s.lo <= addr and addr + size <= s.hi):
            s.warn.append('out of range %s at $%04X' % (kind, addr))
            return False
        if addr in s.items:
            it = s.items[addr]
            if it.size == size and it.kind.split(':')[0] == kind.split(':')[0]:
                return False      # already parsed (shared data)
            s.warn.append('conflict at $%04X: %s(%d) vs existing %s(%d)' % (addr, kind, size, it.kind, it.size))
            return False
        for a in range(addr, addr + size):
            if a in s.owner:
                o = s.items[s.owner[a]]
                s.warn.append('overlap at $%04X: %s@$%04X(%d) vs %s@$%04X(%d)' % (a, kind, addr, size, o.kind, o.addr, o.size))
                return False
        it = Item(addr, size, kind, **f)
        s.items[addr] = it
        for a in range(addr, addr + size):
            s.owner[a] = addr
        return True

    def label(s, addr, name, force=False):
        if addr not in s.labels or force:
            s.labels[addr] = name
        return s.labels[addr]

    # ---------------------------------------------------------------- tables
    def parse_table(s, ptr, esize, kind, name):
        """Instrument/song table pointer -> walker table. Returns label of first entry."""
        start = (ptr + esize - 1) & 0xFFFF
        if s.dbg and start == s.dbg:
            import traceback; traceback.print_stack()
        s._table(start, esize, kind, name)
        return start

    def _table(s, start, esize, kind, name):
        todo = [start]
        s.label(start, name)
        while todo:
            a = todo.pop()
            n = 0
            while True:
                if not (s.lo <= a < s.hi - 2):
                    s.warn.append('%s runs out of range' % name)
                    break
                d = s.b(a)
                if d == 0:
                    tgt = s.w(a + 1)
                    if a in s.items:
                        break
                    if any((a + k) in s.owner for k in range(3)):
                        s.notes.append('%s: terminator at $%04X overlaps the next object' % (name, a))
                        break
                    s.add(a, 3, 'tend', target=tgt)
                    if tgt not in s.labels:
                        s.label(tgt, name + '_L%d' % len(todo) if tgt != start else name)
                    if s.lo <= tgt < s.hi and tgt not in s.items:
                        todo.append(tgt)
                    break
                if a in s.items:
                    break            # joined an already parsed table
                if any((a + k) in s.owner for k in range(esize)):
                    s.notes.append('%s: no terminator, runs into %s at $%04X' % (name, s.items[s.owner[[a + k for k in range(esize) if (a + k) in s.owner][0]]].kind, a))
                    s.items[s.owner.get(a - 1, a - 1)].f['runs_into'] = True if (a - 1) in s.owner else None
                    break
                ok = s.add(a, esize, 't%d:%s' % (esize, kind))
                if not ok:
                    break
                a += esize
                n += 1
                if n > 400:
                    s.warn.append('%s too long' % name)
                    break

    # ---------------------------------------------------------------- patterns
    def parse_pattern(s, addr, name, sfx=False, chans=()):
        s.label(addr, name)
        a = addr
        res = None
        if not (s.lo <= addr < s.hi):
            s.warn.append('pattern %s at $%04X outside' % (name, addr))
            return ('end', None)
        if addr in s.owner and s.owner[addr] != addr or (addr in s.items and s.items[addr].kind not in
                ('note', 'hold', 'keyoff', 'keyon', 'patend', 'songloop', 'sfxend', 'sfxloop')):
            if s.b(addr) == 0 and sfx:
                return ('end', None)
            (s.warn if chans else s.notes).append('%s: pattern start $%04X lies inside other data' % (name, addr))
            return ('end', None)
        while True:
            if not (s.lo <= a < s.hi - 2):
                s.warn.append('pattern %s runs out of range' % name)
                return ('end', None)
            if a in s.items and a != addr:
                # running into already parsed pattern data (shared tail)
                res = s.parse_pat_end(a) or ('end', None)
                break
            d = s.b(a)
            first = (a == addr and not sfx)   # music: the driver loads a pattern's first byte as a length unchecked
            if d == 0 and not first:
                if sfx and s.c['sfxloop']:
                    tgt = s.w(a + 1)
                    if any((a + k) in s.owner for k in (1, 2)):
                        s.add(a, 1, 'patend', sfxover=tgt)
                        s.notes.append('%s: SFX end at $%04X reads its loop word $%04X from the next object' % (name, a, tgt))
                    elif (tgt >> 8) == 0:
                        s.add(a, 3, 'sfxend', target=tgt)
                    else:
                        s.add(a, 3, 'sfxloop', target=tgt)
                        if s.lo <= tgt < s.hi:
                            s.label(tgt, name + '_Loop')
                        else:
                            s.notes.append('%s: SFX end at $%04X jumps to $%04X (outside the bank)' % (name, a, tgt))
                else:
                    s.add(a, 1, 'patend')
                res = ('end', None)
                break
            if d == 0xFF and not first:
                tgt = s.w(a + 1)
                s.add(a, 3, 'songloop', target=tgt)
                res = ('jump', tgt)
                break
            n = s.b(a + 1)
            if n in (0xFF, 0xFE, 0xFD) and not (s.g == 'cmr' and 3 in chans and n != 0xFF):
                s.add(a, 2, {0xFF: 'hold', 0xFE: 'keyoff', 0xFD: 'keyon'}[n], dur=d)
                a += 2
            else:
                ins = s.b(a + 2)
                s.add(a, 3, 'note', dur=d, note=n, ins=ins, chans=tuple(chans))
                for ch in chans:
                    s.ins_uses.setdefault((4 if ch == 4 else (5 if (s.g == 'cmr' and ch == 3) else 1), ins), set()).add(ch)
                a += 3
            if a - addr > 4000:
                s.warn.append('pattern %s too long' % name)
                break
        return res

    def parse_pat_end(s, addr):
        """walk a parsed pattern to its terminator"""
        a = addr
        while True:
            it = s.items.get(a)
            if it is None:
                return None
            if it.kind == 'songloop':
                return ('jump', it.f['target'])
            if it.kind in ('patend', 'sfxend', 'sfxloop'):
                return ('end', None)
            a += it.size

    # ---------------------------------------------------------------- step lists
    def pattab_entry(s, n):
        return s.w(s.c['tabs']['pattab'] + 2 * n)

    def parse_steps(s, addr, name, ch):
        st = s.c['step']
        todo = [(addr, name)]
        s.label(addr, name)
        while todo:
            a, nm = todo.pop()
            k = 0
            while True:
                if a in s.items or not (s.lo <= a < s.hi - st):
                    break
                tr = s.b(a)
                if st == 2:
                    pat = s.b(a + 1)
                elif st == 3:
                    pat = s.w(a + 1)
                else:
                    pat = s.w(a + 2)
                ok = s.add(a, st, 'step', tr=tr, pat=pat, unused=(s.b(a + 1) if st == 4 else None))
                if not ok:
                    break
                s.pat_uses.setdefault(pat, set()).add(ch)
                pa = s.pattab_entry(pat)
                r = s.parse_pat_end(pa)
                if r is None:
                    r = s.parse_pattern(pa, 'Pat%03d' % pat, chans=[ch])
                else:
                    # re-walk to register instrument uses for this channel
                    s._uses(pa, ch)
                a += st
                k += 1
                if r[0] == 'jump':
                    tgt = r[1]
                    if tgt not in s.labels:
                        s.label(tgt, nm + '_Loop')
                    if tgt not in s.items:
                        todo.append((tgt, nm + '_J'))
                    break
                if k > 1000:
                    s.warn.append('steps %s too long' % nm)
                    break

    def _uses(s, pa, ch):
        a = pa
        while True:
            it = s.items.get(a)
            if it is None or it.kind in ('songloop', 'patend', 'sfxend', 'sfxloop'):
                return
            if it.kind == 'note':
                t = 4 if ch == 4 else (5 if (s.g == 'cmr' and ch == 3) else 1)
                s.ins_uses.setdefault((t, it.f['ins']), set()).add(ch)
                if ch not in it.f['chans']:
                    it.f['chans'] = tuple(it.f['chans']) + (ch,)
            a += it.size

    # ---------------------------------------------------------------- top level
    def run(s):
        c = s.c
        t = c['tabs']
        g = s.g
        # fixed small objects
        s.label(t['freq'], 'FreqTable')
        s.add(t['freq'], 144, 'freqtab')
        s.label(t['blankpat'], 'BlankPattern')
        s.add(t['blankpat'], 1, 'patend')
        if 'blankvol' in t:
            # ch3 starts on blankvol with timer 2: the first tick reads the byte AT blankvol
            s.parse_table(t['blankvol'], 2, 'vol', 'BlankVol')
        for a, n, k, nm in c.get('extra_items', []):
            s.label(a, nm)
            s.add(a, n, k, full=True)
        for a, k in c.get('extra_data', {}).items():
            es = 3 if k == 'freq' else 2
            s.label(a, 'Blank' + k.capitalize() + 'Ptr')
            s.parse_table(a, es, k, 'Blank' + k.capitalize())

        # songs
        st = t['songtab']
        esz = {'c3': 6, 'c4w': 11, 'c4mw': 13, 'mask': 14}[c['song']]
        lim = t['pattab']
        for a0 in (t['sfxtab'],):
            if a0 > st:
                lim = min(lim, a0)
        nsongs = 0
        while st + (nsongs + 1) * esz <= lim:
            a0 = st + nsongs * esz
            for k in range(0, esz - 1):
                v = s.w(a0 + k)
                if st < v < lim and k % 1 == 0 and (c['song'] != 'mask' or k >= 2):
                    pass
            nsongs += 1
            # pointers of this entry bound the table
            if c['song'] == 'c3':
                ps = [s.w(a0), s.w(a0 + 2), s.w(a0 + 4)]
            elif c['song'] in ('c4w', 'c4mw'):
                ps = [s.w(a0 + 2 * i) for i in range(4)]
            else:
                ps = [s.w(a0 + 2 + 2 * i) for i in range(bin(s.b(a0 + 1) & 15).count('1'))]
            for v in ps:
                if st < v < lim:
                    lim = v
        if c['sfx'] in ('p', 'pp'):
            sa0 = t['sfxtab']
            ssz0 = 3 if c['sfx'] == 'p' else 4
            k = 0
            while sa0 + k * ssz0 < st:
                v = s.w(sa0 + k * ssz0 + (0 if ssz0 == 3 else 1))
                if st < v < st + nsongs * esz:
                    nsongs = (v - st) // esz
                k += 1
        s.label(st, 'SongTable')
        s.nsongs = nsongs
        s.label(t['pattab'], 'PatternTable')
        s.label(t['instab'], 'InstrumentTable')
        s.label(t['instab4'], 'NoiseInstrumentTable')
        s.label(t['sfxtab'], 'SfxTable')
        for n in range(nsongs):
            a = st + n * esz
            song = dict(n=n, at=a, chans={}, tempo=None, mask=None, morph=None, wave=None)
            if c['song'] == 'c3':
                for i, ch in enumerate((1, 2, 4)):
                    song['chans'][ch] = s.w(a + 2 * i)
                used = 6
            elif c['song'] in ('c4w', 'c4mw'):
                for i, ch in enumerate((1, 2, 3, 4)):
                    song['chans'][ch] = s.w(a + 2 * i)
                song['tempo'] = s.b(a + 8)
                if c['song'] == 'c4w':
                    song['wave'] = s.w(a + 9)
                    used = 11
                else:
                    song['morph'] = s.w(a + 9)
                    song['wave'] = s.w(a + 11)
                    used = 13
            else:
                song['tempo'] = s.b(a)
                mask = s.b(a + 1)
                song['mask'] = mask
                p = a + 2
                for bit, ch in ((1, 1), (2, 2), (4, 3), (8, 4)):
                    if mask & bit:
                        song['chans'][ch] = s.w(p)
                        p += 2
                if mask & 4 and (c['wave'] or c.get('song_mw')):
                    song['morph'] = s.w(p)
                    song['wave'] = s.w(p + 2)
                    p += 4
                used = p - a
            song['used'] = used
            s.add(a, esz, 'song', **song)
            s.songs.append(song)
        for song in s.songs:
            n = song['n']
            if not all(s.lo <= p < s.hi for p in song['chans'].values()):
                song['invalid'] = True
                if song['at'] in s.items:
                    s.items[song['at']].f['invalid'] = True
                continue
            for ch, p in song['chans'].items():
                if s.lo <= p < s.hi:
                    s.parse_steps(p, 'Song%02d_Ch%d' % (n, ch), ch)
                else:
                    s.warn.append('song %d ch%d ptr $%04X outside' % (n, ch, p))

        # sfx table
        sa = t['sfxtab']
        ssz = 3 if c['sfx'] == 'p' else 4
        ptrs = []
        a = sa
        while True:
            if c['sfx'] == 'p':
                ptr, ch, pri = s.w(a), s.b(a + 2), None
            else:
                pri, ptr, ch = s.b(a), s.w(a + 1), s.b(a + 3)
            ptrs.append((ptr, ch, pri))
            a += ssz
            lim = min([p for p, _, _ in ptrs if p > sa] + [st])
            if a + ssz > lim:
                break
        s.nsfx = len(ptrs)
        for i, (ptr, ch, pri) in enumerate(ptrs):
            s.add(sa + i * ssz, ssz, 'sfxent', ptr=ptr, ch=ch, pri=pri, n=i)
            chn = 2 if ch == 2 else 4
            s.sfx.append(dict(n=i, ptr=ptr, ch=chn, raw=ch, pri=pri))

        # instrument uses of the sound effects (dry walk; the patterns are parsed later)
        for e in s.sfx:
            a = e['ptr']
            for _ in range(500):
                if not (s.lo <= a < s.hi - 2):
                    break
                d = s.b(a)
                if d in (0, 0xFF):
                    break
                n = s.b(a + 1)
                if n in (0xFF, 0xFE, 0xFD):
                    a += 2
                    continue
                t4 = 4 if e['ch'] == 4 else 1
                s.ins_uses.setdefault((t4, s.b(a + 2)), set()).add(e['ch'])
                a += 3

        # pattern table: every entry
        pt = t['pattab']
        npat = (t['instab'] - pt) // 2
        s.npat = npat
        s.add(pt, npat * 2, 'ptrtab', n=npat, what='pat')
        for i in range(npat):
            pa = s.w(pt + 2 * i)
            if s.parse_pat_end(pa) is None:
                s.parse_pattern(pa, 'Pat%03d' % i, chans=sorted(s.pat_uses.get(i, ())))
            else:
                s.label(pa, 'Pat%03d' % i)

        # instrument tables (records only)
        it_ = t['instab']
        nins = (t['instab4'] - it_) // 2
        s.nins = nins
        s.add(it_, nins * 2, 'ptrtab', n=nins, what='ins')
        it4 = t['instab4']
        n4 = 0
        while True:
            nxt = it4 + 2 * n4
            p = s.w(nxt)
            if nxt in s.owner or nxt + 1 in s.owner:
                break
            n4 += 1
            lowp = [s.w(it4 + 2 * k) for k in range(n4) if s.w(it4 + 2 * k) > it4]
            if lowp and it4 + 2 * n4 >= min(lowp):
                break
        s.nins4 = n4
        s.add(it4, n4 * 2, 'ptrtab', n=n4, what='ins4')
        s.datalo = min(t.values())
        recs = []
        for i in range(nins):
            p = s.w(it_ + 2 * i)
            chs = s.ins_uses.get((1, i), set())
            if 3 in chs and chs & {1, 2}:
                s.warn.append('instrument %d used on ch3 and tone channels' % i)
            if chs:
                recs.append((p, i, 'wave' if 3 in chs else 'tone', True))
        for i in range(n4):
            if s.ins_uses.get((4, i)):
                recs.append((s.w(it4 + 2 * i), i, 'noise', True))
        for i in range(nins):
            if not s.ins_uses.get((1, i)):
                p = s.w(it_ + 2 * i)
                recs.append((p, i, s.guess_ins(p), False))
        for i in range(n4):
            if not s.ins_uses.get((4, i)):
                recs.append((s.w(it4 + 2 * i), i, 'noise', False))
        good = []
        for p, i, typ, used in recs:
            if s.ins_record(p, i, typ, used):
                good.append((p, typ))

        # sfx patterns
        for e in s.sfx:
            nm = 'Sfx%02X' % e['n']
            if e['ptr'] in s.items and s.items[e['ptr']].kind == 'patend':
                s.label(e['ptr'], nm)
                continue
            s.parse_pattern(e['ptr'], nm, sfx=True, chans=[e['ch']])
        for it in list(s.items.values()):
            if it.kind == 'sfxloop' and it.f['target'] not in s.items and s.lo <= it.f['target'] < s.hi:
                s.parse_pattern(it.f['target'], s.labels.get(it.f['target'], 'SfxLoop_%04X' % it.f['target']), sfx=True)

        # instrument tables
        for p, typ in good:
            s.ins_tables(p, typ)
        # song waves / morph tables
        for song in s.songs:
            if song.get('invalid'):
                continue
            if song['morph'] is not None and s.lo <= song['morph'] < s.hi:
                s.parse_table(song['morph'], 3, 'morph', 'Morph_%04X' % ((song['morph'] + 2) & 0xFFFF))
        for song in s.songs:
            if song.get('invalid'):
                continue
            wv = song['wave']
            if wv is not None and s.lo <= wv < s.hi and wv not in s.items:
                s.label(wv, 'Wave_%04X' % wv)
                n = 0
                while n < 16 and (wv + n) not in s.owner:
                    n += 1
                if n == 0 and wv in s.owner and s.items[s.owner[wv]].kind in ('wave', 'wavetail'):
                    prev = s.items[s.owner[wv]]
                    pe = prev.addr + prev.size
                    s.notes.append('wave $%04X starts inside wave $%04X (shares %d bytes)' % (wv, prev.addr, pe - wv))
                    m = 0
                    while pe + m < wv + 16 and (pe + m) not in s.owner:
                        m += 1
                    if m:
                        s.add(pe, m, 'wavetail', of=wv)
                    continue
                s.add(wv, n, 'wave', full=(n == 16))
                if n < 16:
                    s.notes.append('wave $%04X overlaps the next object after %d bytes' % (wv, n))
        for e in s.sfx:
            s._uses(e['ptr'], e['ch'])
        if c.get('pcm'):
            s.parse_pcm(c['pcm'])

    def guess_ins(s, p):
        if not c_ok(s, p):
            return 'tone'
        if not (s.c['wave'] or s.c.get('song_mw')):
            return 'tone'
        b0 = s.b(p)
        okp = lambda a: 0x4000 <= s.w(a) < 0x8000
        tone_ok = (b0 & 0x3F) == 0 and okp(p + 3) and okp(p + 5) and okp(p + 7)
        wave_ok = all(okp(p + k) for k in (0, 2, 4, 6, 8))
        if wave_ok and not tone_ok:
            return 'wave'
        return 'tone'

    def ins_record(s, p, i, typ, used):
        nm = ('NoiseIns%02d' if typ == 'noise' else 'Ins%02d') % i
        size = {'tone': 9, 'wave': 10, 'noise': 7}[typ]
        offs = {'tone': (3, 5, 7), 'wave': (0, 2, 4, 6, 8), 'noise': (3, 5)}[typ]
        if p in s.items and s.items[p].kind == 'ins:' + typ:
            s.label(p, nm) if p not in s.labels else None
            s.items[p].f['idx'].append(i)
            if used:
                s.items[p].f['used'] = True
            return False
        if not used:
            if not (s.datalo <= p < s.hi) or not all(s.datalo <= s.w(p + o) < s.hi for o in offs):
                s.bad_ins.append((typ, i, p))
                return False
            if any((p + k) in s.owner for k in range(size)):
                s.bad_ins.append((typ, i, p))
                return False
        tg = [(s.w(p + o) + (2 if (typ != 'noise' and o == (5 if typ == 'tone' else 6)) else 1)) & 0xFFFF for o in offs]
        inner = [x for x in tg if p < x < p + size]
        if inner:
            size = min(inner) - p
            s.notes.append('Ins %s %d at $%04X: record overlaps its own table at $%04X (%d bytes kept)' % (typ, i, p, min(inner), size))
        if not s.add(p, size, 'ins:' + typ, idx=[i], used=used, full={'tone': 9, 'wave': 10, 'noise': 7}[typ]):
            s.bad_ins.append((typ, i, p))
            return False
        s.label(p, nm)
        return True

    def ins_tables(s, p, typ):
        w = s.w
        if typ == 'tone':
            s.parse_table(w(p + 3), 2, 'arp', 'Arp_%04X' % ((w(p + 3) + 1) & 0xFFFF))
            s.parse_table(w(p + 5), 3, 'freq', 'Freq_%04X' % ((w(p + 5) + 2) & 0xFFFF))
            s.parse_table(w(p + 7), 2, 'comb', 'Comb_%04X' % ((w(p + 7) + 1) & 0xFFFF))
        elif typ == 'wave':
            s.parse_table(w(p), 2, 'vol', 'Vol_%04X' % ((w(p) + 1) & 0xFFFF))
            s.parse_table(w(p + 2), 2, 'vol', 'Vol_%04X' % ((w(p + 2) + 1) & 0xFFFF))
            s.parse_table(w(p + 4), 2, 'arp', 'Arp_%04X' % ((w(p + 4) + 1) & 0xFFFF))
            s.parse_table(w(p + 6), 3, 'freq', 'Freq_%04X' % ((w(p + 6) + 2) & 0xFFFF))
            s.parse_table(w(p + 8), 2, 'comb', 'Comb_%04X' % ((w(p + 8) + 1) & 0xFFFF))
        else:
            s.parse_table(w(p + 3), 2, 'noise', 'Noise_%04X' % ((w(p + 3) + 1) & 0xFFFF))
            s.parse_table(w(p + 5), 2, 'noise2', 'NoiseCtl_%04X' % ((w(p + 5) + 1) & 0xFFFF))

    def parse_pcm(s, a):
        s.label(a, 'PcmTable')
        n = 0x1F
        s.add(a, n * 6, 'pcmtab', n=n)
        for i in range(n):
            e = a + 6 * i
            s.pcm.append(dict(n=i, pri=s.b(e), addr=s.w(e + 1), blocks=s.w(e + 3), bank=s.b(e + 5)))


def c_ok(s, p):
    return 0x4000 <= p < 0x7FF0


def fill_gaps(D, start=None):
    """Heuristic pass over unreferenced bytes: dead steps, orphan instruments and tables."""
    s = D
    if not s.owner:
        return
    lo, end = min(s.owner), max(a for a in s.owner if s.items[s.owner[a]].kind != 'pcmtab')
    if s.c.get('pcm'):
        end = max(a for a in s.owner if a < s.c['pcm'])
    mk = s.m.find(b'-- THE END --', 0x4000)
    if mk > 0:
        s.add(mk, 13, 'endmark')
        s.label(mk, 'TheEnd')
        end = max(end, mk + 12)
    extra = [x[0] + x[1] - 1 for x in s.c.get('extra_items', [])]
    if extra:
        end = max([end] + extra)
    s.region_end = end
    hi0 = s.hi
    s.hi = end + 1
    if start is not None and start < lo:
        lo = start
    a = lo
    st = s.c['step']
    okp = lambda v: s.datalo <= v < s.hi

    def gap_end(x):
        y = x
        while y <= end and y not in s.owner:
            y += 1
        return y

    while a <= end:
        if a in s.owner:
            a += 1
            continue
        ge = gap_end(a)
        prev = s.items.get(s.owner.get(a - 1, -1))
        # dead steps after a step list
        if prev is not None and prev.kind == 'step':
            ok = a + st <= ge
            if ok:
                pat = s.b(a + 1) if st == 2 else s.w(a + 2)
                if st == 4 and s.b(a + 1) != 0:
                    ok = False
                if pat >= s.npat:
                    ok = False
            if ok:
                s.add(a, st, 'step', tr=s.b(a), pat=pat, unused=(s.b(a + 1) if st == 4 else None), dead=True)
                a += st
                continue
        b0 = s.b(a)
        # orphan instruments
        cand = []
        if (b0 & 0x3F) == 0 and a + 9 <= ge and all(okp(s.w(a + o)) for o in (3, 5, 7)):
            cand.append(('tone', 9))
        if (s.c['wave'] or s.c.get('song_mw')) and a + 10 <= ge and all(okp(s.w(a + o)) for o in (0, 2, 4, 6, 8)):
            cand.append(('wave', 10))
        if a + 7 <= ge and all(okp(s.w(a + o)) for o in (3, 5)) and (s.b(a + 1) & 0x07 or s.b(a + 1) & 0xF0):
            cand.append(('noise', 7))
        if cand:
            typ, sz = cand[0]
            s.add(a, sz, 'ins:' + typ, idx=[], used=False, orphan=True)
            s.label(a, 'OrphanIns_%04X' % a)
            s.ins_tables(a, typ)
            a += sz
            continue
        # orphan tables
        done = False
        for es in (3, 2):
            x = a
            ents = []
            while x + 3 <= ge:
                if s.b(x) == 0:
                    tgt = s.w(x + 1)
                    if a <= tgt <= x and (tgt - a) % es == 0 and ents:
                        hi_ok = es == 2 or all(s.b(e + 2) in (0, 0xFF) for e in ents) or \
                            all(0x30 <= s.b(e + 1) <= 0x3F for e in ents)
                        if hi_ok:
                            done = (es, x)
                    break
                ents.append(x)
                x += es
            if done:
                break
        if done:
            es, x = done
            kind = 'orphan'
            if es == 3 and all(0x30 <= s.b(e + 1) <= 0x3F for e in range(a, x, 3)):
                kind = 'morph'
            nm = s.label(a, 'Orphan%s_%04X' % ('Morph' if kind == 'morph' else 'Tab', a))
            for e in range(a, x, es):
                s.add(e, es, 't%d:%s' % (es, kind), orphan=True)
            s.add(x, 3, 'tend', target=s.w(x + 1))
            tgt = s.w(x + 1)
            if tgt not in s.labels:
                s.label(tgt, nm + '_Loop')
            a = x + 3
            continue
        a += 1
    s.hi = hi0


if __name__ == '__main__':
    g = sys.argv[1]
    D = Data(g)
    D.run()
    fill_gaps(D)
    cov = sorted(D.owner)
    print(g, 'songs', D.nsongs, 'sfx', D.nsfx, 'pats', D.npat, 'ins', D.nins, 'noise ins', D.nins4)
    print('items', len(D.items), 'bytes', len(cov), 'range $%04X-$%04X' % (cov[0], cov[-1]))
    for w in D.warn[:40]:
        print('  W', w)
    # gaps
    gaps = []
    a = min(D.owner)
    end = max(D.owner)
    while a <= end:
        if a not in D.owner:
            b = a
            while b <= end and b not in D.owner:
                b += 1
            gaps.append((a, b - a))
            a = b
        else:
            a += 1
    print('gaps', len(gaps), sum(x[1] for x in gaps))
    for a, n in gaps[:60]:
        print('  $%04X %4d: %s' % (a, n, D.m[a:a + min(n, 24)].hex(' ')))

