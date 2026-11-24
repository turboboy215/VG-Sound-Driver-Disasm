"""Minimal SM83 (Game Boy CPU) disassembler.

disasm(rom, offset, addr) -> (length, text, info)
info: dict with 'target' (jump/call target), 'kind' in
      {'jp','jr','call','ret','reti','rst','other'}, 'cond' bool, 'imm16'.
"""
R8 = ['b', 'c', 'd', 'e', 'h', 'l', '[hl]', 'a']
R16 = ['bc', 'de', 'hl', 'sp']
R16S = ['bc', 'de', 'hl', 'af']
CC = ['nz', 'z', 'nc', 'c']
ALU = ['add a,', 'adc a,', 'sub ', 'sbc a,', 'and ', 'xor ', 'or ', 'cp ']
ROT = ['rlc', 'rrc', 'rl', 'rr', 'sla', 'sra', 'swap', 'srl']


def h8(v):
    return '$%02X' % v


def h16(v):
    return '$%04X' % v


def disasm(rom, off, addr):
    op = rom[off]
    b1 = rom[off + 1] if off + 1 < len(rom) else 0
    b2 = rom[off + 2] if off + 2 < len(rom) else 0
    w = b1 | (b2 << 8)
    info = {'kind': 'other', 'target': None, 'cond': False, 'imm16': None}

    def rel():
        return (addr + 2 + (b1 - 256 if b1 > 127 else b1)) & 0xFFFF

    x, y, z = op >> 6, (op >> 3) & 7, op & 7
    p, q = y >> 1, y & 1
    if op == 0xCB:
        x2, y2, z2 = b1 >> 6, (b1 >> 3) & 7, b1 & 7
        if x2 == 0:
            t = '%s %s' % (ROT[y2], R8[z2])
        else:
            t = '%s %d,%s' % (['', 'bit', 'res', 'set'][x2], y2, R8[z2])
        return 2, t, info
    if x == 1:
        if op == 0x76:
            return 1, 'halt', info
        return 1, 'ld %s,%s' % (R8[y], R8[z]), info
    if x == 2:
        return 1, ALU[y] + R8[z], info
    if x == 0:
        if z == 0:
            if y == 0:
                return 1, 'nop', info
            if y == 1:
                info['imm16'] = w
                return 3, 'ld [%s],sp' % h16(w), info
            if y == 2:
                return 2, 'stop', info
            t = rel()
            info.update(kind='jr', target=t, cond=(y >= 4))
            if y == 3:
                return 2, 'jr %s' % h16(t), info
            return 2, 'jr %s,%s' % (CC[y - 4], h16(t)), info
        if z == 1:
            if q == 0:
                info['imm16'] = w
                return 3, 'ld %s,%s' % (R16[p], h16(w)), info
            return 1, 'add hl,%s' % R16[p], info
        if z == 2:
            m = ['[bc]', '[de]', '[hli]', '[hld]'][p]
            if q == 0:
                return 1, 'ld %s,a' % m, info
            return 1, 'ld a,%s' % m, info
        if z == 3:
            return 1, ('inc ' if q == 0 else 'dec ') + R16[p], info
        if z == 4:
            return 1, 'inc ' + R8[y], info
        if z == 5:
            return 1, 'dec ' + R8[y], info
        if z == 6:
            return 2, 'ld %s,%s' % (R8[y], h8(b1)), info
        if z == 7:
            return 1, ['rlca', 'rrca', 'rla', 'rra', 'daa', 'cpl', 'scf', 'ccf'][y], info
    # x == 3
    if z == 0:
        if y < 4:
            info.update(kind='ret', cond=True)
            return 1, 'ret ' + CC[y], info
        if y == 4:
            return 2, 'ldh [%s],a' % h16(0xFF00 + b1), info
        if y == 5:
            return 2, 'add sp,%d' % (b1 - 256 if b1 > 127 else b1), info
        if y == 6:
            return 2, 'ldh a,[%s]' % h16(0xFF00 + b1), info
        return 2, 'ld hl,sp%+d' % (b1 - 256 if b1 > 127 else b1), info
    if z == 1:
        if q == 0:
            return 1, 'pop ' + R16S[p], info
        if p == 0:
            info['kind'] = 'ret'
            return 1, 'ret', info
        if p == 1:
            info['kind'] = 'reti'
            return 1, 'reti', info
        if p == 2:
            info['kind'] = 'jphl'
            return 1, 'jp hl', info
        return 1, 'ld sp,hl', info
    if z == 2:
        if y < 4:
            info.update(kind='jp', target=w, cond=True)
            return 3, 'jp %s,%s' % (CC[y], h16(w)), info
        if y == 4:
            return 1, 'ldh [c],a', info
        if y == 5:
            info['imm16'] = w
            return 3, 'ld [%s],a' % h16(w), info
        if y == 6:
            return 1, 'ldh a,[c]', info
        info['imm16'] = w
        return 3, 'ld a,[%s]' % h16(w), info
    if z == 3:
        if y == 0:
            info.update(kind='jp', target=w)
            return 3, 'jp %s' % h16(w), info
        if y == 6:
            return 1, 'di', info
        if y == 7:
            return 1, 'ei', info
        return 1, 'db $%02X' % op, info
    if z == 4:
        if y < 4:
            info.update(kind='call', target=w, cond=True)
            return 3, 'call %s,%s' % (CC[y], h16(w)), info
        return 1, 'db $%02X' % op, info
    if z == 5:
        if q == 0:
            return 1, 'push ' + R16S[p], info
        if p == 0:
            info.update(kind='call', target=w)
            return 3, 'call %s' % h16(w), info
        return 1, 'db $%02X' % op, info
    if z == 6:
        return 2, ALU[y] + h8(b1), info
    info.update(kind='rst', target=y * 8)
    return 1, 'rst $%02X' % (y * 8), info
