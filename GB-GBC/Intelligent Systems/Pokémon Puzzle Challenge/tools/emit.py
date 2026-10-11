"""RGBDS emitter: structured SM83 decoding, label resolution and bank listings."""

R8 = ['b', 'c', 'd', 'e', 'h', 'l', '[hl]', 'a']
R16 = ['bc', 'de', 'hl', 'sp']
R16S = ['bc', 'de', 'hl', 'af']
CC = ['nz', 'z', 'nc', 'c']
ALU = ['add a, ', 'adc a, ', 'sub ', 'sbc a, ', 'and ', 'xor ', 'or ', 'cp ']
CB = ['rlc', 'rrc', 'rl', 'rr', 'sla', 'sra', 'swap', 'srl']


def decode(buf, i, pc):
    """Return (length, fmt, kind, value).
    fmt contains {} where the operand goes; kind in None,'n8','imm16','mem16','ldh','rel','jp','call','rst'.
    flow in ('end','branch','cond','call',None) is derived by caller from mnemonic."""
    op = buf[i]
    x, y, z = op >> 6, (op >> 3) & 7, op & 7
    n8 = buf[i + 1] if i + 1 < len(buf) else 0
    n16 = n8 | ((buf[i + 2] if i + 2 < len(buf) else 0) << 8)
    rel = (pc + 2 + ((n8 ^ 0x80) - 0x80)) & 0xFFFF
    if op == 0x00: return 1, 'nop', None, None
    if op == 0x08: return 3, 'ld [{}], sp', 'mem16', n16
    if op == 0x10: return 2, 'stop', 'stop', n8
    if op == 0x18: return 2, 'jr {}', 'rel', rel
    if op in (0x20, 0x28, 0x30, 0x38): return 2, f'jr {CC[y-4]}, {{}}', 'rel', rel
    if x == 0:
        if z == 1:
            if y & 1: return 1, f'add hl, {R16[y>>1]}', None, None
            return 3, f'ld {R16[y>>1]}, {{}}', 'imm16', n16
        if z == 2:
            m = ['[bc]', '[de]', '[hl+]', '[hl-]'][y >> 1]
            return 1, (f'ld a, {m}' if y & 1 else f'ld {m}, a'), None, None
        if z == 3: return 1, (f'dec {R16[y>>1]}' if y & 1 else f'inc {R16[y>>1]}'), None, None
        if z == 4: return 1, f'inc {R8[y]}', None, None
        if z == 5: return 1, f'dec {R8[y]}', None, None
        if z == 6: return 2, f'ld {R8[y]}, {{}}', 'n8', n8
        if z == 7: return 1, ['rlca', 'rrca', 'rla', 'rra', 'daa', 'cpl', 'scf', 'ccf'][y], None, None
    if x == 1:
        if op == 0x76: return 1, 'halt', None, None
        return 1, f'ld {R8[y]}, {R8[z]}', None, None
    if x == 2: return 1, f'{ALU[y]}{R8[z]}', None, None
    if op == 0xC9: return 1, 'ret', None, None
    if op == 0xD9: return 1, 'reti', None, None
    if op in (0xC0, 0xC8, 0xD0, 0xD8): return 1, f'ret {CC[y]}', None, None
    if op == 0xE0: return 2, 'ldh [{}], a', 'ldh', 0xFF00 + n8
    if op == 0xF0: return 2, 'ldh a, [{}]', 'ldh', 0xFF00 + n8
    if op == 0xE2: return 1, 'ldh [c], a', None, None
    if op == 0xF2: return 1, 'ldh a, [c]', None, None
    if op == 0xE8: return 2, 'add sp, {}', 'n8s', n8
    if op == 0xF8: return 2, 'ld hl, sp + {}', 'n8s', n8
    if op == 0xE9: return 1, 'jp hl', None, None
    if op == 0xF9: return 1, 'ld sp, hl', None, None
    if op == 0xEA: return 3, 'ld [{}], a', 'mem16', n16
    if op == 0xFA: return 3, 'ld a, [{}]', 'mem16', n16
    if op == 0xF3: return 1, 'di', None, None
    if op == 0xFB: return 1, 'ei', None, None
    if op == 0xC3: return 3, 'jp {}', 'jp', n16
    if op in (0xC2, 0xCA, 0xD2, 0xDA): return 3, f'jp {CC[y]}, {{}}', 'jp', n16
    if op == 0xCD: return 3, 'call {}', 'call', n16
    if op in (0xC4, 0xCC, 0xD4, 0xDC): return 3, f'call {CC[y]}, {{}}', 'call', n16
    if z == 1: return 1, f'pop {R16S[y>>1]}', None, None
    if z == 5: return 1, f'push {R16S[y>>1]}', None, None
    if z == 6: return 2, f'{ALU[y]}{{}}', 'n8', n8
    if z == 7: return 1, f'rst ${y*8:02X}', None, None
    if op == 0xCB:
        c = n8
        cx, cy, cz = c >> 6, (c >> 3) & 7, c & 7
        if cx == 0: return 2, f'{CB[cy]} {R8[cz]}', None, None
        return 2, f"{['', 'bit', 'res', 'set'][cx]} {cy}, {R8[cz]}", None, None
    return 1, None, 'illegal', op


def flow(buf, i, pc):
    """(length, successors list, falls_through, targets) for tracing."""
    l, fmt, kind, v = decode(buf, i, pc)
    op = buf[i]
    if fmt is None:
        return l, False, []
    if op in (0xC9, 0xD9, 0xE9):
        return l, False, []
    if op in (0x18, 0xC3):
        return l, False, [v]
    if kind in ('rel', 'jp', 'call'):
        return l, True, [v]
    return l, True, []


class Listing:
    """Byte-accurate listing of one ROM region: items keyed by address."""

    def __init__(self, name, bank, start, end, rom):
        self.name, self.bank, self.start, self.end, self.rom = name, bank, start, end, rom
        self.items = {}       # addr -> (length, [lines])
        self.labels = {}      # addr -> [names] (first = primary)
        self.comments = {}    # addr -> [comment lines] before the item
        self.pre = {}         # addr -> [raw lines] emitted before labels (e.g. SFX_CH)
        self.post = {}        # addr -> [raw lines] emitted after labels, before item
        self.kinds = {}       # addr -> 'code' / 'data'

    def off(self, a):
        return a if self.bank == 0 else self.bank * 0x4000 + a - 0x4000

    def byte(self, a):
        return self.rom[self.off(a)]

    def add(self, a, length, lines, kind='data'):
        if isinstance(lines, str):
            lines = [lines]
        self.kinds[a] = kind
        for j in range(length):
            if a + j in self.items or any(a + j in rng for rng in []):
                raise ValueError(f'{self.name}: overlap at {a+j:04X}')
        self.items[a] = (length, lines)

    def label(self, a, name):
        lst = self.labels.setdefault(a, [])
        if name not in lst:
            lst.append(name)

    def covered(self):
        c = set()
        for a, (l, _) in self.items.items():
            c.update(range(a, a + l))
        return c

    def render(self):
        out = []
        # validate
        cov = {}
        for a, (l, _) in sorted(self.items.items()):
            for j in range(l):
                if a + j in cov:
                    raise ValueError(f'{self.name}: overlap {a+j:04X}')
                cov[a + j] = a
        for a in self.labels:
            if a in cov and cov[a] != a:
                raise ValueError(f'{self.name}: label {self.labels[a]} inside item at {cov[a]:04X}')
        a = self.start
        raw = []

        def flush():
            if raw:
                for k in range(0, len(raw), 16):
                    out.append('\tdb ' + ', '.join(f'${b:02X}' for b in raw[k:k + 16]))
                raw.clear()

        while a < self.end:
            if a in self.labels or a in self.items or a in self.comments or a in self.pre:
                flush()
            for c in self.pre.get(a, []):
                out.append(c)
            for c in self.comments.get(a, []):
                out.append(c)
            for n in self.labels.get(a, []):
                out.append(n if n.startswith('.') else n + '::')
            for c in self.post.get(a, []):
                out.append(c)
            if a in self.items:
                l, lines = self.items[a]
                out.extend(lines)
                a += l
            else:
                raw.append(self.byte(a))
                a += 1
                if len(raw) == 16:
                    flush()
        flush()
        return out
