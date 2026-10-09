"""Small tracing 6502 disassembler that emits ca65 source which reassembles
byte-for-byte.  Game specific knowledge (data formats) lives in the game
config modules; this file only knows about bytes, labels, items and code."""

import sys

# ---------------------------------------------------------------- opcodes
# mode: imp acc imm zp zpx zpy abs abx aby ind izx izy rel
OPS = {}
def _op(code, mn, mode):
    OPS[code] = (mn, mode)
_tbl = """
00 brk imp|01 ora izx|05 ora zp|06 asl zp|08 php imp|09 ora imm|0a asl acc|0d ora abs|0e asl abs
10 bpl rel|11 ora izy|15 ora zpx|16 asl zpx|18 clc imp|19 ora aby|1d ora abx|1e asl abx
20 jsr abs|21 and izx|24 bit zp|25 and zp|26 rol zp|28 plp imp|29 and imm|2a rol acc|2c bit abs|2d and abs|2e rol abs
30 bmi rel|31 and izy|35 and zpx|36 rol zpx|38 sec imp|39 and aby|3d and abx|3e rol abx
40 rti imp|41 eor izx|45 eor zp|46 lsr zp|48 pha imp|49 eor imm|4a lsr acc|4c jmp abs|4d eor abs|4e lsr abs
50 bvc rel|51 eor izy|55 eor zpx|56 lsr zpx|58 cli imp|59 eor aby|5d eor abx|5e lsr abx
60 rts imp|61 adc izx|65 adc zp|66 ror zp|68 pla imp|69 adc imm|6a ror acc|6c jmp ind|6d adc abs|6e ror abs
70 bvs rel|71 adc izy|75 adc zpx|76 ror zpx|78 sei imp|79 adc aby|7d adc abx|7e ror abx
81 sta izx|84 sty zp|85 sta zp|86 stx zp|88 dey imp|8a txa imp|8c sty abs|8d sta abs|8e stx abs
90 bcc rel|91 sta izy|94 sty zpx|95 sta zpx|96 stx zpy|98 tya imp|99 sta aby|9a txs imp|9d sta abx
a0 ldy imm|a1 lda izx|a2 ldx imm|a4 ldy zp|a5 lda zp|a6 ldx zp|a8 tay imp|a9 lda imm|aa tax imp|ac ldy abs|ad lda abs|ae ldx abs
b0 bcs rel|b1 lda izy|b4 ldy zpx|b5 lda zpx|b6 ldx zpy|b8 clv imp|b9 lda aby|ba tsx imp|bc ldy abx|bd lda abx|be ldx aby
c0 cpy imm|c1 cmp izx|c4 cpy zp|c5 cmp zp|c6 dec zp|c8 iny imp|c9 cmp imm|ca dex imp|cc cpy abs|cd cmp abs|ce dec abs
d0 bne rel|d1 cmp izy|d5 cmp zpx|d6 dec zpx|d8 cld imp|d9 cmp aby|dd cmp abx|de dec abx
e0 cpx imm|e1 sbc izx|e4 cpx zp|e5 sbc zp|e6 inc zp|e8 inx imp|e9 sbc imm|ea nop imp|ec cpx abs|ed sbc abs|ee inc abs
f0 beq rel|f1 sbc izy|f5 sbc zpx|f6 inc zpx|f8 sed imp|f9 sbc aby|fd sbc abx|fe inc abx
"""
for chunk in _tbl.replace('\n', '|').split('|'):
    chunk = chunk.strip()
    if chunk:
        c, mn, md = chunk.split()
        _op(int(c, 16), mn, md)
SIZE = {'imp': 1, 'acc': 1, 'imm': 2, 'zp': 2, 'zpx': 2, 'zpy': 2, 'izx': 2,
        'izy': 2, 'rel': 2, 'abs': 3, 'abx': 3, 'aby': 3, 'ind': 3}

APU = {0x4000: 'SQ1_VOL', 0x4001: 'SQ1_SWEEP', 0x4002: 'SQ1_LO', 0x4003: 'SQ1_HI',
       0x4004: 'SQ2_VOL', 0x4005: 'SQ2_SWEEP', 0x4006: 'SQ2_LO', 0x4007: 'SQ2_HI',
       0x4008: 'TRI_LINEAR', 0x400A: 'TRI_LO', 0x400B: 'TRI_HI',
       0x400C: 'NOISE_VOL', 0x400E: 'NOISE_LO', 0x400F: 'NOISE_HI',
       0x4010: 'DMC_FREQ', 0x4011: 'DMC_RAW', 0x4012: 'DMC_START', 0x4013: 'DMC_LEN',
       0x4014: 'OAM_DMA', 0x4015: 'APU_STATUS', 0x4017: 'APU_FRAME'}


def h2(v): return '$%02X' % v
def h4(v): return '$%04X' % v


class Item:
    __slots__ = ('addr', 'size', 'lines', 'kind')
    def __init__(self, addr, size, lines, kind):
        self.addr, self.size, self.lines, self.kind = addr, size, lines, kind


class Disasm:
    def __init__(self, data, base, start, end, title=''):
        self.data, self.base = data, base      # data covers [base, base+len)
        self.start, self.end = start, end      # region that is emitted
        self.labels = {}                       # addr -> [names]
        self.items = {}                        # addr -> Item
        self.owner = {}                        # byte addr -> item start
        self.ram = {}                          # addr -> name (equates)
        self.blockc = {}                       # addr -> [comment lines]
        self.linec = {}                        # addr -> comment for code line
        self.code_todo = []
        self.title = title
        self.warn = []
        self.extern = {}                       # addr -> name for outside refs

    # ------------------------------------------------------------ bytes
    def b(self, a):
        return self.data[a - self.base]
    def w(self, a):
        return self.b(a) | self.b(a + 1) << 8
    def inside(self, a):
        return self.start <= a < self.end

    # ------------------------------------------------------------ labels
    def label(self, a, name, primary=False):
        if not self.inside(a):
            self.extern.setdefault(a, name)
            return
        l = self.labels.setdefault(a, [])
        if name not in l:
            if primary:
                l.insert(0, name)
            else:
                l.append(name)
    def name(self, a):
        if a in self.labels:
            return self.labels[a][0]
        return None
    def comment(self, a, text):
        self.blockc.setdefault(a, []).append(text)

    # ------------------------------------------------------------ items
    def add(self, addr, size, lines, kind='data'):
        """returns False if an identical item already exists there"""
        if addr in self.items:
            it = self.items[addr]
            if it.size == size and it.kind == kind:
                return False
            raise Exception('conflict at %04X: %s/%d vs %s/%d' % (addr, it.kind, it.size, kind, size))
        for a in range(addr, addr + size):
            if a in self.owner:
                o = self.items[self.owner[a]]
                raise Exception('overlap at %04X (%s item@%04X) adding %s@%04X' % (a, o.kind, o.addr, kind, addr))
            if not self.inside(a):
                raise Exception('item %s@%04X leaves region' % (kind, addr))
        for a in range(addr, addr + size):
            self.owner[a] = addr
        self.items[addr] = Item(addr, size, lines, kind)
        return True
    def claimed(self, a):
        return a in self.owner

    # ------------------------------------------------------------ code
    def code(self, a, name=None):
        if name:
            self.label(a, name, primary=True)
        self.code_todo.append(a)

    def trace(self):
        while self.code_todo:
            a = self.code_todo.pop()
            while True:
                if a in self.items:
                    if self.items[a].kind != 'code':
                        raise Exception('code runs into data at %04X' % a)
                    break
                op = self.b(a)
                if op not in OPS:
                    raise Exception('bad opcode %02X at %04X' % (op, a))
                mn, md = OPS[op]
                n = SIZE[md]
                opnd = None
                if n == 2:
                    opnd = self.b(a + 1)
                elif n == 3:
                    opnd = self.w(a + 1)
                if md == 'rel':
                    opnd = (a + 2 + (opnd ^ 0x80) - 0x80) & 0xFFFF
                self.add(a, n, (mn, md, opnd), 'code')
                if md in ('rel',) or (mn in ('jsr', 'jmp') and md == 'abs'):
                    if self.inside(opnd):
                        if opnd not in self.labels:
                            self.label(opnd, 'L%04X' % opnd)
                        self.code_todo.append(opnd)
                    else:
                        self.extern.setdefault(opnd, 'L%04X' % opnd)
                if mn in ('rts', 'rti', 'jmp', 'brk'):
                    break
                a += n

    # ------------------------------------------------------------ operands
    def ref(self, v, zp_ok):
        """symbolic name for an address operand"""
        if self.inside(v):
            if v in self.labels:
                return self.labels[v][0]
            if v in self.owner:
                st = self.owner[v]
                if st in self.labels:
                    return '%s+%d' % (self.labels[st][0], v - st)
            self.label(v, 'L%04X' % v)
            return self.labels[v][0]
        if v in self.ram:
            return self.ram[v]
        if v in APU:
            return APU[v]
        # offset from a known RAM base (e.g. RAM array + 1)
        for d in range(1, 5):
            if v - d in self.ram and self.ram[v - d][0] != '_':
                return '%s+%d' % (self.ram[v - d], d)
        if v in self.extern:
            return self.extern[v]
        return h4(v) if v > 0xFF else h2(v)

    def fmt_code(self, it):
        mn, md, v = it.lines
        if md in ('imp',):
            return mn
        if md == 'acc':
            return mn + ' a'
        if md == 'imm':
            return '%s #%s' % (mn, h2(v))
        if md == 'rel':
            return '%s %s' % (mn, self.ref(v, False))
        r = self.ref(v, md in ('zp', 'zpx', 'zpy', 'izx', 'izy'))
        if md in ('abs', 'abx', 'aby') and v < 0x100:
            r = 'a:' + r
        if md in ('zp', 'abs'):
            return '%s %s' % (mn, r)
        if md in ('zpx', 'abx'):
            return '%s %s,x' % (mn, r)
        if md in ('zpy', 'aby'):
            return '%s %s,y' % (mn, r)
        if md == 'izx':
            return '%s (%s,x)' % (mn, r)
        if md == 'izy':
            return '%s (%s),y' % (mn, r)
        if md == 'ind':
            return '%s (%s)' % (mn, r)
        raise Exception(md)

    # ------------------------------------------------------------ data helpers
    def wordref(self, v):
        """symbolic rendering of a 16-bit pointer value"""
        if v == 0:
            return '$0000'
        return self.ref(v, False)

    # ------------------------------------------------------------ output
    def render(self, header):
        out = list(header)
        # resolve symbolic references first (may create labels)
        rendered = {}
        for a in sorted(self.items):
            it = self.items[a]
            if it.kind == 'code':
                rendered[a] = [(self.fmt_code(it), self.linec.get(a))]
            else:
                ls = it.lines(self) if callable(it.lines) else it.lines
                rendered[a] = ls
        # externs/equates referenced
        a = self.start
        body = []
        pending_free = []
        def flush_free():
            if not pending_free:
                return
            s = pending_free[0]
            body.append('; ---- %d byte(s) not referenced by the sound engine ----' % len(pending_free))
            vals = [self.b(x) for x in pending_free]
            i = 0
            while i < len(vals):
                j = i
                while j < len(vals) and vals[j] == vals[i]:
                    j += 1
                if j - i >= 16:
                    body.append('        .res %d, %s' % (j - i, h2(vals[i])))
                    i = j
                    continue
                k = i
                chunk = []
                while k < len(vals) and len(chunk) < 16:
                    # stop before a long run
                    r = k
                    while r < len(vals) and vals[r] == vals[k]:
                        r += 1
                    if r - k >= 16:
                        break
                    chunk.append(vals[k]); k += 1
                body.append('        .byte ' + ','.join(h2(v) for v in chunk))
                i = k
            pending_free.clear()
        while a < self.end:
            labs = self.labels.get(a, [])
            if a not in self.items:
                if labs or a in self.blockc:
                    flush_free()
                    if body and body[-1] != '':
                        body.append('')
                for c in self.blockc.get(a, []):
                    body.append(c if c.startswith(';') or c == '' else '; ' + c)
                for l in labs:
                    body.append('%s:' % l)
                pending_free.append(a)
                a += 1
                continue
            flush_free()
            it = self.items[a]
            if (labs or a in self.blockc) and body and body[-1] != '':
                body.append('')
            for c in self.blockc.get(a, []):
                body.append(c if c.startswith(';') or c == '' else '; ' + c)
            for l in labs:
                body.append('%s:' % l)
            # labels pointing inside this item
            for off in range(1, it.size):
                for l in self.labels.get(a + off, []):
                    body.append('%s := * + %d' % (l, off))
            for text, com in rendered[a]:
                line = '        ' + text
                if com:
                    line = (line.ljust(44) if len(line) < 44 else line + ' ') + '; ' + com
                body.append(line.rstrip())
            if it.kind == 'code' and it.lines[0] in ('rts', 'rti', 'jmp'):
                body.append('')
            a += it.size
        flush_free()
        # collapse double blank lines
        res = []
        for l in body:
            if l == '' and res and res[-1] == '':
                continue
            res.append(l)
        return out, res
