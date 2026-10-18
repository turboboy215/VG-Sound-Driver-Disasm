"""Minimal SM83 (Game Boy CPU) decoder for driver tracing / source generation."""

R8 = ['b', 'c', 'd', 'e', 'h', 'l', '[hl]', 'a']
R16 = ['bc', 'de', 'hl', 'sp']
R16S = ['bc', 'de', 'hl', 'af']
CC = ['nz', 'z', 'nc', 'c']
ALU = ['add a,', 'adc a,', 'sub ', 'sbc a,', 'and ', 'xor ', 'or ', 'cp ']
CB = ['rlc', 'rrc', 'rl', 'rr', 'sla', 'sra', 'swap', 'srl']


class Ins:
    __slots__ = ('addr', 'size', 'mn', 'ops', 'kind', 'target', 'imm', 'immkind')

    def __init__(self, addr, size, mn, ops='', kind=None, target=None, imm=None, immkind=None):
        self.addr, self.size, self.mn, self.ops = addr, size, mn, ops
        self.kind = kind          # None, 'jp','jr','call','ret','reti','rst','jphl'
        self.target = target      # branch target
        self.imm = imm            # 16-bit immediate (for symbolization)
        self.immkind = immkind    # 'n16' (ld rr,n16), 'a16' (memory addr)

    @property
    def cond(self):
        return ',' in self.ops if self.kind in ('jp', 'jr', 'call') else (self.kind == 'ret' and self.ops != '')

    @property
    def ends(self):
        if self.kind in ('jp', 'jr') and not self.cond:
            return True
        if self.kind == 'ret' and not self.ops:
            return True
        return self.kind in ('reti', 'jphl')


def decode(mem, pc):
    """mem: callable addr->byte. Returns Ins or None for invalid."""
    op = mem(pc)
    b1 = lambda: mem(pc + 1)
    w1 = lambda: mem(pc + 1) | (mem(pc + 2) << 8)
    x, y, z = op >> 6, (op >> 3) & 7, op & 7
    if op == 0x00: return Ins(pc, 1, 'nop')
    if op == 0x08: return Ins(pc, 3, 'ld', '[${:04X}],sp'.format(w1()), imm=w1(), immkind='a16')
    if op == 0x10: return Ins(pc, 2, 'stop')
    if op == 0x18:
        t = (pc + 2 + ((b1() ^ 0x80) - 0x80)) & 0xFFFF
        return Ins(pc, 2, 'jr', '', 'jr', t)
    if x == 0 and z == 0 and y >= 4:
        t = (pc + 2 + ((b1() ^ 0x80) - 0x80)) & 0xFFFF
        return Ins(pc, 2, 'jr', CC[y - 4] + ',', 'jr', t)
    if x == 0 and z == 1:
        p, q = y >> 1, y & 1
        if q == 0:
            return Ins(pc, 3, 'ld', R16[p] + ',${:04X}'.format(w1()), imm=w1(), immkind='n16')
        return Ins(pc, 1, 'add', 'hl,' + R16[p])
    if x == 0 and z == 2:
        t = ['ld [bc],a', 'ld a,[bc]', 'ld [de],a', 'ld a,[de]',
             'ld [hli],a', 'ld a,[hli]', 'ld [hld],a', 'ld a,[hld]'][y]
        m, o = t.split(' ', 1)
        return Ins(pc, 1, m, o)
    if x == 0 and z == 3:
        return Ins(pc, 1, 'inc' if y % 2 == 0 else 'dec', R16[y >> 1])
    if x == 0 and z == 4: return Ins(pc, 1, 'inc', R8[y])
    if x == 0 and z == 5: return Ins(pc, 1, 'dec', R8[y])
    if x == 0 and z == 6: return Ins(pc, 2, 'ld', R8[y] + ',${:02X}'.format(b1()))
    if x == 0 and z == 7:
        return Ins(pc, 1, ['rlca', 'rrca', 'rla', 'rra', 'daa', 'cpl', 'scf', 'ccf'][y])
    if op == 0x76: return Ins(pc, 1, 'halt')
    if x == 1: return Ins(pc, 1, 'ld', R8[y] + ',' + R8[z])
    if x == 2:
        a = ALU[y]
        m, o = (a.split(' ', 1) + [''])[:2]
        return Ins(pc, 1, m, o + R8[z])
    # x == 3
    if op in (0xC0, 0xC8, 0xD0, 0xD8): return Ins(pc, 1, 'ret', CC[y], 'ret')
    if op == 0xE0: return Ins(pc, 2, 'ldh', '[${:02X}],a'.format(b1()), imm=0xFF00 | b1(), immkind='h8w')
    if op == 0xE8: return Ins(pc, 2, 'add', 'sp,${:02X}'.format(b1()))
    if op == 0xF0: return Ins(pc, 2, 'ldh', 'a,[${:02X}]'.format(b1()), imm=0xFF00 | b1(), immkind='h8r')
    if op == 0xF8: return Ins(pc, 2, 'ld', 'hl,sp+${:02X}'.format(b1()))
    if z == 1:
        if y % 2 == 0: return Ins(pc, 1, 'pop', R16S[y >> 1])
        return {1: Ins(pc, 1, 'ret', '', 'ret'), 3: Ins(pc, 1, 'reti', '', 'reti'),
                5: Ins(pc, 1, 'jp', 'hl', 'jphl'), 7: Ins(pc, 1, 'ld', 'sp,hl')}[y]
    if z == 2:
        if y < 4: return Ins(pc, 3, 'jp', CC[y] + ',', 'jp', w1())
        if y == 4: return Ins(pc, 1, 'ldh', '[c],a')
        if y == 5: return Ins(pc, 3, 'ld', '[${:04X}],a'.format(w1()), imm=w1(), immkind='a16w')
        if y == 6: return Ins(pc, 1, 'ldh', 'a,[c]')
        if y == 7: return Ins(pc, 3, 'ld', 'a,[${:04X}]'.format(w1()), imm=w1(), immkind='a16r')
    if op == 0xC3: return Ins(pc, 3, 'jp', '', 'jp', w1())
    if op == 0xCB:
        c = b1()
        cx, cy, cz = c >> 6, (c >> 3) & 7, c & 7
        if cx == 0: return Ins(pc, 2, CB[cy], R8[cz])
        return Ins(pc, 2, ['', 'bit', 'res', 'set'][cx], '{},{}'.format(cy, R8[cz]))
    if op == 0xF3: return Ins(pc, 1, 'di')
    if op == 0xFB: return Ins(pc, 1, 'ei')
    if z == 4 and y < 4: return Ins(pc, 3, 'call', CC[y] + ',', 'call', w1())
    if z == 5:
        if y % 2 == 0: return Ins(pc, 1, 'push', R16S[y >> 1])
        if y == 1: return Ins(pc, 3, 'call', '', 'call', w1())
    if z == 6:
        a = ALU[y]
        m, o = (a.split(' ', 1) + [''])[:2]
        return Ins(pc, 2, m, o + '${:02X}'.format(b1()))
    if z == 7: return Ins(pc, 1, 'rst', '${:02X}'.format(y * 8), 'rst', y * 8)
    return None
