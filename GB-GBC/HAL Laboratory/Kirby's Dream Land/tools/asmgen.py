"""Generic RGBDS source builder for a byte-exact region of a GB ROM.

Usage pattern (per game generator):
    g = AsmGen(rom, bank, start, end)
    g.ram.update({...}); g.ext.update({...})
    g.trace(entry, 'Name')
    g.data(addr, size, 'db ...')       # or parsers that call g.item()
    text = g.emit(start, end)
"""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from sm83 import decode

HWREG = {
    0xFF00: 'rP1', 0xFF04: 'rDIV', 0xFF05: 'rTIMA', 0xFF06: 'rTMA', 0xFF07: 'rTAC', 0xFF0F: 'rIF',
    0xFF10: 'rNR10', 0xFF11: 'rNR11', 0xFF12: 'rNR12', 0xFF13: 'rNR13', 0xFF14: 'rNR14',
    0xFF16: 'rNR21', 0xFF17: 'rNR22', 0xFF18: 'rNR23', 0xFF19: 'rNR24',
    0xFF1A: 'rNR30', 0xFF1B: 'rNR31', 0xFF1C: 'rNR32', 0xFF1D: 'rNR33', 0xFF1E: 'rNR34',
    0xFF20: 'rNR41', 0xFF21: 'rNR42', 0xFF22: 'rNR43', 0xFF23: 'rNR44',
    0xFF24: 'rNR50', 0xFF25: 'rNR51', 0xFF26: 'rNR52', 0xFF30: '_AUD3WAVERAM',
    0xFF40: 'rLCDC', 0xFF41: 'rSTAT', 0xFF44: 'rLY', 0xFF46: 'rDMA', 0xFFFF: 'rIE',
}


class Item:
    __slots__ = ('addr', 'size', 'text', 'comment', 'kind')

    def __init__(self, addr, size, text, comment=None, kind='data'):
        self.addr, self.size, self.text, self.comment, self.kind = addr, size, text, comment, kind


class AsmGen:
    def __init__(self, rom, bank, start, end):
        self.rom, self.bank, self.start, self.end = rom, bank, start, end
        self.items = {}
        self.owner = {}          # byte addr -> item start
        self.labels = {}         # addr -> name
        self.label_comments = {}
        self.ram = {}            # RAM / HRAM address -> name (exact)
        self.ext = {}            # external code/data address -> name
        self.hints = {}          # code addr -> replacement instruction text
        self.block_comments = {} # addr -> list of comment lines before item
        self.code_entries = set()
        self.jumptables = {}     # addr of 'jp hl' or dispatcher -> handled by caller
        self.errors = []

    # ---------- memory ----------
    def off(self, a):
        if a < 0x4000:
            return a
        return self.bank * 0x4000 + (a - 0x4000)

    def b(self, a):
        return self.rom[self.off(a)]

    def w(self, a):
        return self.b(a) | (self.b(a + 1) << 8)

    def mem(self, a):
        return self.rom[self.off(a)] if a < 0x8000 else 0

    def inside(self, a):
        return self.start <= a < self.end

    # ---------- labels / items ----------
    def label(self, addr, name=None, prefix='Snd', override=False):
        if addr in self.labels and not override:
            return self.labels[addr]
        if name is None:
            name = '%s_%04X' % (prefix, addr)
        if name in self.labels.values() and self.labels.get(addr) != name:
            raise ValueError('duplicate label name %s' % name)
        self.labels[addr] = name
        return name

    def is_free(self, addr, size):
        return all((addr + k) not in self.owner for k in range(size))

    def item(self, addr, size, text, comment=None, kind='data', allow_same=True):
        if addr in self.items:
            it = self.items[addr]
            if allow_same and it.size == size and it.text == text:
                return False
            if allow_same and it.size == size:
                return False
            self.errors.append('overlap at %04X: %r vs %r' % (addr, it.text, text))
            return False
        for k in range(size):
            if (addr + k) in self.owner:
                o = self.items[self.owner[addr + k]]
                self.errors.append('overlap at %04X (+%d): new %r, old %04X %r' % (addr, k, text, o.addr, o.text))
                return False
        it = Item(addr, size, text, comment, kind)
        self.items[addr] = it
        for k in range(size):
            self.owner[addr + k] = addr
        return True

    def data(self, addr, size, text=None, comment=None):
        if text is None:
            text = 'db ' + ', '.join('$%02X' % self.b(addr + k) for k in range(size))
        return self.item(addr, size, text, comment)

    def bytes_rows(self, addr, size, per=16, comment=None):
        a = addr
        first = True
        while a < addr + size:
            n = min(per, addr + size - a)
            self.data(a, n, comment=comment if first else None)
            first = False
            a += n

    def words(self, addr, count, target_prefix=None, comment=None, per=1):
        for i in range(count):
            a = addr + 2 * i
            v = self.w(a)
            self.item(a, 2, 'dw ' + self.sym(v), comment if i == 0 else None)

    def parent(self, a):
        best = None
        for x, n in self.labels.items():
            if x <= a and not n.startswith('.') and self.inside(x):
                if best is None or x > best:
                    best = x
        return best

    def full(self, v, at=None):
        n = self.labels[v]
        if not n.startswith('.'):
            return n
        pv = self.parent(v)
        if at is not None and self.parent(at) == pv:
            return n
        return self.labels[pv] + n

    def sym(self, v, want_label=True, at=None):
        """Symbolic expression for address v."""
        if v in self.labels:
            return self.full(v, at)
        if self.inside(v) and want_label:
            # nearest preceding label
            cands = [a for a in self.labels if a <= v and self.inside(a) and not self.labels[a].startswith('.')]
            if cands:
                a = max(cands)
                if v - a < 0x100 and a in self.labels:
                    return '%s + %d' % (self.labels[a], v - a)
            return '$%04X' % v
        if v in self.ext:
            return self.ext[v]
        if v in self.ram:
            return self.ram[v]
        return '$%04X' % v

    def ramsym(self, v):
        if v in self.ram:
            return self.ram[v]
        # within a known array: name+off
        best = None
        for a, n in self.ram.items():
            if a <= v < a + 8 and (best is None or a > best[0]) and not n.startswith('r'):
                best = (a, n)
        if best and best[0] != v and v >= 0xC000:
            return '%s + %d' % (best[1], v - best[0])
        if v in HWREG:
            return HWREG[v]
        return '$%04X' % v

    # ---------- code ----------
    def trace(self, entry, name=None, prefix='Snd'):
        if entry not in self.labels or self.labels[entry].startswith('.'):
            self.labels[entry] = name or '%s_%04X' % (prefix, entry)
        self.code_entries.add(entry)
        todo = [entry]
        while todo:
            pc = todo.pop()
            while True:
                if not self.inside(pc):
                    break
                if pc in self.items:
                    if self.items[pc].kind != 'code':
                        self.errors.append('code flows into data at %04X' % pc)
                    break
                ins = decode(self.mem, pc)
                if ins is None:
                    self.errors.append('invalid opcode at %04X' % pc)
                    break
                if not self.item(pc, ins.size, None, kind='code'):
                    break
                self.items[pc].text = ins
                if ins.kind in ('jp', 'jr', 'call') and ins.ops != 'hl':
                    t = ins.target
                    if self.inside(t):
                        if t not in self.labels:
                            self.labels[t] = '.l_%04X' % t
                        todo.append(t)
                    elif t not in self.ext:
                        self.ext[t] = 'Ext_%04X' % t
                if ins.kind == 'rst':
                    pass
                if ins.ends:
                    break
                pc += ins.size

    def ins_text(self, ins):
        if ins.addr in self.hints:
            return self.hints[ins.addr]
        mn, ops = ins.mn, ins.ops
        if ins.kind in ('jp', 'jr', 'call'):
            if ops == 'hl':
                return 'jp hl'
            t = ins.target
            s = (self.full(t, ins.addr) if t in self.labels else None) or self.ext.get(t) or ('$%04X' % t)
            return '%s %s%s' % (mn, ops.replace(',', ', '), s)
        if ins.kind == 'rst':
            return 'rst %s' % ops
        if ins.kind == 'ret':
            return 'ret' + (' ' + ops if ops else '')
        if ins.immkind == 'n16':
            r = ops.split(',')[0]
            v = ins.imm
            if self.inside(v) or v in self.ext:
                s = self.sym(v)
            elif v in self.ram or (0xC000 <= v < 0xE000 and self.ramsym(v) != '$%04X' % v):
                s = self.ramsym(v)
            elif v in HWREG:
                s = HWREG[v]
            else:
                s = '$%04X' % v
            return 'ld %s, %s' % (r, s)
        if ins.immkind in ('a16r', 'a16w', 'a16'):
            v = ins.imm
            if 0xC000 <= v < 0xE000 or v >= 0xFF00:
                s = self.ramsym(v)
            elif v < 0x8000 and (self.inside(v) or v in self.ext):
                s = self.sym(v)
            elif 0x2000 <= v < 0x4000:
                s = '$%04X' % v
            else:
                s = '$%04X' % v
            if ins.immkind == 'a16w':
                return 'ld [%s], a' % s
            if ins.immkind == 'a16r':
                return 'ld a, [%s]' % s
            return 'ld [%s], sp' % s
        if ins.immkind in ('h8w', 'h8r'):
            v = ins.imm
            s = HWREG.get(v) or self.ram.get(v) or ('$%04X' % v)
            return 'ldh [%s], a' % s if ins.immkind == 'h8w' else 'ldh a, [%s]' % s
        if mn == 'ld' and ops.startswith('hl,sp+'):
            v = int(ops[7:], 16)
            v = v - 256 if v >= 128 else v
            return 'ld hl, sp%+d' % v
        if mn == 'add' and ops.startswith('sp,'):
            v = int(ops[4:], 16)
            v = v - 256 if v >= 128 else v
            return 'add sp, %d' % v
        if mn == 'stop':
            return 'stop'
        o = ops.replace(',', ', ')
        return (mn + ' ' + o).strip()

    def fix_labels(self):
        for a in list(self.labels):
            if self.inside(a) and a in self.owner and self.owner[a] != a:
                del self.labels[a]

    # ---------- emit ----------
    def emit(self, start=None, end=None, gap_comment='unreferenced', per=16):
        self.fix_labels()
        start = self.start if start is None else start
        end = self.end if end is None else end
        out = []
        a = start
        prev_kind = None
        while a < end:
            if a in self.block_comments:
                for line in self.block_comments[a]:
                    out.append(line)
            if a in self.labels:
                if prev_kind == 'code' or (a in self.items and self.items[a].kind == 'code'):
                    pass
                lc = self.label_comments.get(a)
                out.append('%s::%s' % (self.labels[a], ('  ; ' + lc) if lc else '') if a in self.code_entries and False else
                           '%s:%s' % (self.labels[a], ('  ; ' + lc) if lc else ''))
            if a in self.items:
                it = self.items[a]
                if it.kind == 'code':
                    txt = self.ins_text(it.text)
                    if it.text.mn == 'stop' and it.size == 2 and self.b(a + 1) != 0:
                        txt = 'db $10, $%02X ; stop' % self.b(a + 1)
                    c = it.comment
                    out.append('\t%-28s; %04X%s' % (txt, a, ('  ' + c) if c else ''))
                    if it.text.ends:
                        out.append('')
                else:
                    c = it.comment
                    out.append('\t%s%s' % (it.text, ('  ; ' + c) if c else ''))
                prev_kind = it.kind
                a += it.size
                continue
            # gap: gather bytes until next label/item
            g = a
            while g < end and g not in self.items and (g == a or g not in self.labels) and (g == a or g not in self.block_comments):
                g += 1
            first = True
            while a < g:
                n = min(per, g - a)
                out.append('\tdb %s%s' % (', '.join('$%02X' % self.b(a + k) for k in range(n)),
                                          ('  ; %04X %s' % (a, gap_comment)) if first and gap_comment else ''))
                first = False
                a += n
            prev_kind = 'gap'
        return '\n'.join(out) + '\n'

    def gaps(self, start=None, end=None):
        start = self.start if start is None else start
        end = self.end if end is None else end
        res = []
        a = start
        while a < end:
            if a in self.owner:
                a += 1
                continue
            g = a
            while g < end and g not in self.owner:
                g += 1
            res.append((a, g))
            a = g
        return res
