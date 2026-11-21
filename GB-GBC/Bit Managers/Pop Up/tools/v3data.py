"""Data walker for AJG driver version 3 (Astérix / Pinocchio / Metal Masters).

walk(cfg, v, extra_code) -> Walk with:
  items  : addr -> (len, kind, info)      kind in stream/order/itab/atab/arp/drumpat/fade/wave/n43/n42/ptrtab
  code   : set of code entry points found in data (song routines, drum routines, CALL_CODE targets)
  songs  : list of dict(routine, orders[3], itab, atab, sfx, fade)
  refs   : addr -> set of (kind) for labelling
"""
import sys
sys.path.insert(0, __file__.rsplit('/', 1)[0])
from sm83 import decode
from codetrace import trace
from v3cfg import FLOW_END, INSTR_END


def w16(v, a):
    return v[a] | (v[a + 1] << 8)


class Walk:
    def __init__(self, cfg, v):
        self.cfg = cfg
        self.v = v
        self.items = {}
        self.code = set()
        self.songs = []
        self.refs = {}
        self.max_instr = {}      # itab -> max index used
        self.max_arp = {}
        self.cmdbyte = {name: cfg['cmd_first'] + i for i, (name, _) in enumerate(cfg['cmds'])}
        self.next_byte = self.cmdbyte['NEXT']
        self.problems = []
        self.cur_tables = None

    # ------------------------------------------------------------------
    def ref(self, a, kind):
        self.refs.setdefault(a, set()).add(kind)

    def put(self, a, n, kind, info=None):
        old = self.items.get(a)
        if old:
            if old[1] != kind or old[0] != n:
                self.problems.append('item clash at %04X: %s vs %s' % (a, old[:2], (n, kind)))
            return False
        self.items[a] = (n, kind, info)
        return True

    # ------------------------------------------------------------------
    def decode_cmd(self, a):
        """-> (length, name, args list of (token, value))"""
        c, v = self.cfg, self.v
        b = v[a]
        if b < c['note_max']:
            return 1, 'NOTE', [('n', b)]
        if b >= c['len_first']:
            return 1, 'LEN', [('n', b - c['len_first'] + 1)]
        if b >= c['volenv_first']:
            return 4, 'VOLENV', [('n', b - c['volenv_first']), ('b', v[a + 1]), ('b', v[a + 2]), ('b', v[a + 3])]
        if b >= c['vol_first']:
            return 1, 'VOL', [('n', b - c['vol_first'])]
        if b >= c['arp_first']:
            return 1, 'ARP', [('n', b - c['arp_first'])]
        if b >= c['instr_first']:
            return 1, 'INSTR', [('n', b - c['instr_first'])]
        name, spec = c['cmds'][b - c['cmd_first']]
        args = []
        p = a + 1
        if spec == 'hwenv':
            args.append(('b', v[p])); p += 1
            args.append(('b', v[p])); p += 1
            if v[p - 1] != 0:
                args.append(('b', v[p])); p += 1
        elif spec == 'release':
            args.append(('b', v[p])); p += 1
            if v[p - 1] != 0:
                args.append(('b', v[p])); p += 1
        else:
            for t in spec:
                if t == 'b':
                    args.append(('b', v[p])); p += 1
                else:
                    args.append((t, w16(v, p))); p += 2
        return p - a, name, args

    def walk_stream(self, a, ctx, instr=False):
        """Walk one stream; PAT_GOTO is followed, PAT_CALL bodies are walked separately.
        Returns the set of terminators that end the main flow (END/NEXT/STOP_ALL/ORDER_JUMP)."""
        terms = set()
        seen = set()
        start = a
        while True:
            if a in seen:
                break
            seen.add(a)
            if a in self.items:
                if self.items[a][1] != 'stream':
                    self.problems.append('stream (%s, from %04X) runs into %s at %04X' % (ctx, start, self.items[a][1], a))
                    break
                # already walked: follow it anyway to learn its terminators (no re-put)
            if not (0x4000 <= a < 0x8000):
                self.problems.append('stream leaves bank at %04X' % a)
                break
            n, name, args = self.decode_cmd(a)
            self.put(a, n, 'stream', (name, args, ctx))
            nxt = a + n
            for t, val in args:
                if t == 'P':
                    self.ref(val, 'pat'); nxt = val
                elif t == 'C':
                    self.ref(val, 'pat')
                    if val not in self.items:
                        self.walk_stream(val, ctx)
                elif t == 'O':
                    self.ref(val, 'order')
                elif t == 'D':
                    self.ref(val, 'drumpat'); self.walk_drumpat(val)
                elif t == 'F':
                    self.ref(val, 'fade'); self.walk_fade(val)
                elif t == 'V':
                    self.ref(val, 'wave'); self.put(val, 16, 'wave')
                elif t == 'X':
                    self.ref(val, 'code'); self.code.add(val)
            if name == 'INSTR' and self.cur_tables:
                it = self.cur_tables[0]
                self.max_instr[it] = max(self.max_instr.get(it, -1), args[0][1])
            if name == 'ARP' and self.cur_tables:
                at = self.cur_tables[1]
                self.max_arp[at] = max(self.max_arp.get(at, -1), args[0][1])
            if instr and name in INSTR_END:
                terms.add(name)
                break
            if name in FLOW_END and name != 'PAT_GOTO':
                terms.add(name)
                if name == 'ORDER_JUMP':
                    terms.add(('jump', args[0][1]))
                break
            a = nxt
        return terms

    def walk_order(self, a):
        """Read the order list only as far as the patterns' NEXTs take it."""
        self.ref(a, 'orderlist')
        seen = set()
        while a not in seen:
            seen.add(a)
            w = w16(self.v, a)
            if w == 0:
                loop = w16(self.v, a + 2)
                self.put(a, 4, 'order', ('loop', loop))
                self.ref(loop, 'order')
                a = loop
                continue
            self.put(a, 2, 'order', ('pat', w))
            self.ref(w, 'pat')
            terms = self.walk_stream(w, 'music')
            jumps = [t[1] for t in terms if isinstance(t, tuple)]
            if jumps:
                a = jumps[0]
                continue
            if 'NEXT' in terms:
                a += 2
                continue
            break

    def walk_drumpat(self, a):
        if a in self.items:
            return
        if not 0x4000 <= a < 0x8000:
            self.problems.append('drum pattern outside bank: %04X' % a)
            return
        c = self.cfg
        p = a
        ext = c['drum_ext']
        stop = c.get('drumpat_len', {}).get(a)
        while True:
            if p in self.items and p != a:
                break                      # shared tail
            if stop is not None and p - a >= stop:
                break
            b = self.v[p]
            if ext and ext[1] is not None and b == ext[1]:
                self.put(p, 2, 'drumpat')
                p += 2
                continue
            self.put(p, 1, 'drumpat')
            p += 1
            if b == 0xFF:
                break

    def walk_fade(self, a):
        if a in self.items:
            return
        if not 0x4000 <= a < 0x8000:
            self.problems.append('fade table outside bank: %04X' % a)
            return
        p = a
        while True:
            if p in self.items and p != a:
                break
            b = self.v[p]
            self.put(p, 1, 'fade')
            p += 1
            if b in (0xFF, self.next_byte):
                break

    def walk_noise(self, a43, a42):
        p = a43
        while True:
            self.put(p, 1, 'n43')
            if self.v[p] == 0xFF:
                break
            p += 1
        n = p - a43
        if a42:
            for k in range(n):
                if a42 + k not in self.items:
                    self.put(a42 + k, 1, 'n42')

    def walk_table(self, a, count, kind, entry_kind):
        """pointer table, entries 0..count-1"""
        self.put(a, 2 * count, kind, entry_kind)
        out = []
        for i in range(count):
            out.append(w16(self.v, a + 2 * i))
        return out

    # ------------------------------------------------------------------
    def scan_code(self, entry):
        """Trace code in the data area and pick up the data it points at."""
        c, v = self.cfg, self.v
        code, xr, _ = trace(v, [entry])
        song = dict(routine=entry, orders=[None, None, None], itab=None, atab=None, sfx=[], fade=None, playon=[])
        regs = {}
        g = {}
        found_song = False
        for a in sorted(code):
            if a < 0x4000:
                continue
            n, t, val, f = decode(v, a)
            op = v[a]
            if op == 0x3E:
                regs['a'] = v[a + 1]
            elif op == 0x11:
                regs['de'] = w16(v, a + 1)
            elif op == 0x21:
                regs['hl'] = w16(v, a + 1)
            elif op in (0xEA, 0xE0):
                addr = w16(v, a + 1) if op == 0xEA else 0xFF00 + v[a + 1]
                if 'a' in regs:
                    g[addr] = regs['a']
            elif op == 0xAF:
                regs['a'] = 0
            elif op == 0x3C and 'a' in regs:
                regs['a'] = (regs['a'] + 1) & 0xFF
            elif f and f[0] in ('call', 'jp'):
                tgt = f[1]
                sm = c['startmusic']
                if tgt in (sm, sm + 4, sm + 8):
                    song['orders'][(tgt - sm) // 4] = regs.get('de')
                    found_song = True
                elif tgt == c['playsfx'] and 'a' in regs:
                    song['sfx'].append(regs['a'])
                elif tgt in (c['playon'], c['playon'] + 4, c['playon'] + 8) and 'a' in regs:
                    song['playon'].append(((tgt - c['playon']) // 4 + 1, regs['a']))
                elif tgt == c['startfade'] and 'hl' in regs:
                    song['fade'] = regs['hl']
        gi, ga = c['g_instr'], c['g_arp']
        if gi[0] in g and gi[1] in g:
            song['itab'] = g[gi[0]] | (g[gi[1]] << 8)
        if ga[0] in g and ga[1] in g:
            song['atab'] = g[ga[0]] | (g[ga[1]] << 8)
        if c['g_seq'] and c['g_seq'][0] in g:
            s = c['g_seq']
            a43 = (g[s[0]] << 8) | g[s[1]]
            a42 = ((g[s[2]] << 8) | g[s[3]]) if g.get(s[2]) else None
            song['noise'] = (a43, a42)
        return song, found_song


def walk(cfg, v, song_routines, extra_code=()):
    W = Walk(cfg, v)
    # drum routines
    if cfg['drum_base']:
        W.put(cfg['drum_base'] + 2, 2 * cfg['drum_count'], 'ptrtab', 'drum')
        for i in range(cfg['drum_count']):
            a = w16(v, cfg['drum_base'] + 2 + 2 * i)
            W.code.add(a)
            W.ref(a, 'drum%d' % (i + 1))
            s, _ = W.scan_code(a)
            if s.get('noise'):
                a43, a42 = s['noise']
                W.ref(a43, 'n43'); W.walk_noise(a43, a42)
                if a42:
                    W.ref(a42, 'n42')
    # songs
    for r in song_routines:
        W.code.add(r)
        s, ok = W.scan_code(r)
        W.songs.append(s)
        if s['fade']:
            W.ref(s['fade'], 'fade'); W.walk_fade(s['fade'])
        W.cur_tables = (s['itab'], s['atab'])
        for o in s['orders']:
            if o:
                W.walk_order(o)
    # SFX streams (use the tables of whatever song ran last: no instruments expected)
    W.cur_tables = None
    sb = cfg['sfx_base']
    W.put(sb + 2, 2 * cfg['sfx_count'], 'ptrtab', 'sfx')
    for i in range(cfg['sfx_count']):
        a = w16(v, sb + 2 + 2 * i)
        W.ref(a, 'sfx%d' % (i + 1))
        W.walk_stream(a, 'sfx')
    # instrument / arpeggio tables: sizes from the streams each song can reach
    def reach(starts):
        seen, work, out = set(), list(starts), []
        while work:
            p = work.pop()
            while p not in seen and p in W.items and W.items[p][1] == 'stream':
                seen.add(p)
                n, kind, (name, args, ctx) = W.items[p]
                out.append((name, args))
                nxt = p + n
                for t, val in args:
                    if t == 'P':
                        nxt = val
                    elif t == 'C':
                        work.append(val)
                if name in FLOW_END and name != 'PAT_GOTO':
                    break
                if ctx == 'instr' and name in INSTR_END:
                    break
                p = nxt
        return out

    def order_pats(o):
        pats, seen = [], set()
        while o and o not in seen and o in W.items and W.items[o][1] == 'order':
            seen.add(o)
            kind, val = W.items[o][2]
            if kind == 'pat':
                pats.append(val); o += 2
            else:
                o = val
        return pats

    imax, amax = {}, {}
    for s in W.songs:
        it, at = s['itab'], s['atab']
        starts = [p for o in s['orders'] if o for p in order_pats(o)]
        for name, args in reach(starts):
            if name == 'INSTR' and it:
                imax[it] = max(imax.get(it, -1), args[0][1])
            if name == 'ARP' and at:
                amax[at] = max(amax.get(at, -1), args[0][1])
    W.instr_tables = {}
    for s in W.songs:
        it, at = s['itab'], s['atab']
        if it and it not in W.instr_tables and it in imax:
            cnt = imax[it] + 1                     # INSTR n reads entry n + 1
            W.put(it + 2, 2 * cnt, 'itab', 'instr')
            W.ref(it + 2, 'itab1')
            ptrs = [w16(v, it + 2 + 2 * k) for k in range(cnt)]
            W.instr_tables[it] = ptrs
            for p in ptrs:
                W.ref(p, 'instr')
                W.walk_stream(p, 'instr', instr=True)
            for name, args in reach([]):
                pass
            # arpeggios used inside the instruments
            for p in ptrs:
                q = p
                while q in W.items and W.items[q][1] == 'stream':
                    n, kind, (name, args, ctx) = W.items[q]
                    if name == 'ARP' and at:
                        amax[at] = max(amax.get(at, -1), args[0][1])
                    if name in INSTR_END:
                        break
                    q += n
    W.arp_tables = {}
    for s in W.songs:
        at = s['atab']
        if at and at not in W.arp_tables and at in amax:
            cnt = amax[at] + 1
            W.put(at, 2 * cnt, 'atab', 'arp')
            W.ref(at, 'atab')
            ptrs = [w16(v, at + 2 * k) for k in range(cnt)]
            W.arp_tables[at] = ptrs
            for p in ptrs:
                W.ref(p, 'arp')
                q = p
                while True:
                    if q in W.items and q != p:
                        break
                    W.put(q, 1, 'arp')
                    if v[q] in (0xFF, W.next_byte):
                        break
                    q += 1
    # noise tables set up by CALL_CODE routines
    for a in sorted(W.code):
        s, _ = W.scan_code(a)
        if s.get('noise'):
            a43, a42 = s['noise']
            W.ref(a43, 'n43'); W.walk_noise(a43, a42)
            if a42:
                W.ref(a42, 'n42')
    return W
