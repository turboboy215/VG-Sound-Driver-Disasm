"""Minimal SM83 (GB CPU) disassembler.

decode(rom, off, pc) -> (length, mnemonic, operand_info)
operand_info: dict with optional keys 'target' (jump/call address),
'kind' ('jp','jr','call','ret','rst','jphl'), 'cond' (bool), 'imm16', 'addr'.
"""

R8 = ['b', 'c', 'd', 'e', 'h', 'l', '[hl]', 'a']
R16 = ['bc', 'de', 'hl', 'sp']
R16S = ['bc', 'de', 'hl', 'af']
CC = ['nz', 'z', 'nc', 'c']
ALU = ['add a,', 'adc a,', 'sub ', 'sbc a,', 'and ', 'xor ', 'or ', 'cp ']
CB = ['rlc', 'rrc', 'rl', 'rr', 'sla', 'sra', 'swap', 'srl']


def h8(v):
    return '$%02X' % v


def h16(v):
    return '$%04X' % v


def s8(v):
    return v - 256 if v >= 128 else v


def decode(rom, off, pc):
    """Decode instruction at file offset off, logical address pc."""
    op = rom[off]
    b1 = rom[off + 1] if off + 1 < len(rom) else 0
    b2 = rom[off + 2] if off + 2 < len(rom) else 0
    n16 = b1 | (b2 << 8)
    info = {}
    if op == 0xCB:
        x, y, z = b1 >> 6, (b1 >> 3) & 7, b1 & 7
        if x == 0:
            return 2, '%s %s' % (CB[y], R8[z]), info
        return 2, '%s %d,%s' % (['', 'bit', 'res', 'set'][x], y, R8[z]), info
    x, y, z = op >> 6, (op >> 3) & 7, op & 7
    p, q = y >> 1, y & 1
    if x == 1:
        if op == 0x76:
            return 1, 'halt', info
        return 1, 'ld %s,%s' % (R8[y], R8[z]), info
    if x == 2:
        return 1, '%s%s' % (ALU[y], R8[z]), info
    if x == 0:
        if z == 0:
            if y == 0:
                return 1, 'nop', info
            if y == 1:
                info['imm16'] = n16
                return 3, 'ld [%s],sp' % h16(n16), info
            if y == 2:
                return 2, 'stop', info
            t = (pc + 2 + s8(b1)) & 0xFFFF
            info.update(kind='jr', target=t, cond=(y != 3))
            if y == 3:
                return 2, 'jr %s' % h16(t), info
            return 2, 'jr %s,%s' % (CC[y - 4], h16(t)), info
        if z == 1:
            if q == 0:
                info['imm16'] = n16
                return 3, 'ld %s,%s' % (R16[p], h16(n16)), info
            return 1, 'add hl,%s' % R16[p], info
        if z == 2:
            m = ['[bc]', '[de]', '[hl+]', '[hl-]'][p]
            if q == 0:
                return 1, 'ld %s,a' % m, info
            return 1, 'ld a,%s' % m, info
        if z == 3:
            return 1, '%s %s' % (['inc', 'dec'][q], R16[p]), info
        if z == 4:
            return 1, 'inc %s' % R8[y], info
        if z == 5:
            return 1, 'dec %s' % R8[y], info
        if z == 6:
            return 2, 'ld %s,%s' % (R8[y], h8(b1)), info
        if z == 7:
            return 1, ['rlca', 'rrca', 'rla', 'rra', 'daa', 'cpl', 'scf', 'ccf'][y], info
    # x == 3
    if z == 0:
        if y < 4:
            info.update(kind='ret', cond=True)
            return 1, 'ret %s' % CC[y], info
        if y == 4:
            info['addr'] = 0xFF00 | b1
            return 2, 'ldh [%s],a' % h16(0xFF00 | b1), info
        if y == 5:
            return 2, 'add sp,%d' % s8(b1), info
        if y == 6:
            info['addr'] = 0xFF00 | b1
            return 2, 'ldh a,[%s]' % h16(0xFF00 | b1), info
        return 2, 'ld hl,sp%+d' % s8(b1), info
    if z == 1:
        if q == 0:
            return 1, 'pop %s' % R16S[p], info
        if p == 0:
            info.update(kind='ret', cond=False)
            return 1, 'ret', info
        if p == 1:
            info.update(kind='ret', cond=False)
            return 1, 'reti', info
        if p == 2:
            info.update(kind='jphl', cond=False)
            return 1, 'jp hl', info
        return 1, 'ld sp,hl', info
    if z == 2:
        if y < 4:
            info.update(kind='jp', target=n16, cond=True)
            return 3, 'jp %s,%s' % (CC[y], h16(n16)), info
        if y == 4:
            return 1, 'ldh [c],a', info
        if y == 5:
            info['addr'] = n16
            return 3, 'ld [%s],a' % h16(n16), info
        if y == 6:
            return 1, 'ldh a,[c]', info
        info['addr'] = n16
        return 3, 'ld a,[%s]' % h16(n16), info
    if z == 3:
        if y == 0:
            info.update(kind='jp', target=n16, cond=False)
            return 3, 'jp %s' % h16(n16), info
        if y == 6:
            return 1, 'di', info
        if y == 7:
            return 1, 'ei', info
        return 1, 'db %s' % h8(op), {'bad': True}
    if z == 4:
        if y < 4:
            info.update(kind='call', target=n16, cond=True)
            return 3, 'call %s,%s' % (CC[y], h16(n16)), info
        return 1, 'db %s' % h8(op), {'bad': True}
    if z == 5:
        if q == 0:
            return 1, 'push %s' % R16S[p], info
        if p == 0:
            info.update(kind='call', target=n16, cond=False)
            return 3, 'call %s' % h16(n16), info
        return 1, 'db %s' % h8(op), {'bad': True}
    if z == 6:
        return 2, '%s%s' % (ALU[y], h8(b1)), info
    info.update(kind='rst', target=y * 8, cond=False)
    return 1, 'rst %s' % h8(y * 8), info


def off_of(bank, addr):
    if addr < 0x4000:
        return addr
    return bank * 0x4000 + (addr - 0x4000)


def listing(rom, bank, start, end):
    pc = start
    out = []
    while pc < end:
        o = off_of(bank, pc)
        n, m, i = decode(rom, o, pc)
        out.append('%02X:%04X  %-9s %s' % (bank, pc, ' '.join('%02X' % rom[o + k] for k in range(n)), m))
        pc += n
    return '\n'.join(out)


if __name__ == '__main__':
    import sys
    rom = open(sys.argv[1], 'rb').read()
    bank = int(sys.argv[2], 16)
    s = int(sys.argv[3], 16)
    e = int(sys.argv[4], 16)
    print(listing(rom, bank, s, e))
