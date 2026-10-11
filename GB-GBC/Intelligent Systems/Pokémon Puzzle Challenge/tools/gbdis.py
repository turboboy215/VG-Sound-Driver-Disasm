"""Minimal SM83 disassembler: decode(rom, addr_in_rom, cpu_addr) -> (length, mnemonic, operand info)."""
R8 = ['b', 'c', 'd', 'e', 'h', 'l', '[hl]', 'a']
R16 = ['bc', 'de', 'hl', 'sp']
R16S = ['bc', 'de', 'hl', 'af']
CC = ['nz', 'z', 'nc', 'c']
ALU = ['add a,', 'adc a,', 'sub', 'sbc a,', 'and', 'xor', 'or', 'cp']
CB = ['rlc', 'rrc', 'rl', 'rr', 'sla', 'sra', 'swap', 'srl']


def decode(buf, i, pc):
    """Return (len, text, target) where target is a branch/jump address or None, kind in text."""
    op = buf[i]
    n8 = lambda: buf[i + 1]
    n16 = lambda: buf[i + 1] | (buf[i + 2] << 8)
    rel = lambda: (pc + 2 + ((buf[i + 1] ^ 0x80) - 0x80)) & 0xFFFF
    x, y, z = op >> 6, (op >> 3) & 7, op & 7
    if op == 0x00: return 1, 'nop', None
    if op == 0x08: return 3, f'ld [${n16():04X}], sp', None
    if op == 0x10: return 2, 'stop', None
    if op == 0x18: return 2, f'jr ${rel():04X}', ('jr', rel())
    if op in (0x20, 0x28, 0x30, 0x38): return 2, f'jr {CC[y-4]}, ${rel():04X}', ('jrc', rel())
    if x == 0:
        if z == 1:
            if y & 1: return 1, f'add hl, {R16[y>>1]}', None
            return 3, f'ld {R16[y>>1]}, ${n16():04X}', ('imm', n16())
        if z == 2:
            m = ['[bc]', '[de]', '[hl+]', '[hl-]'][y >> 1]
            return 1, (f'ld a, {m}' if y & 1 else f'ld {m}, a'), None
        if z == 3: return 1, (f'dec {R16[y>>1]}' if y & 1 else f'inc {R16[y>>1]}'), None
        if z == 4: return 1, f'inc {R8[y]}', None
        if z == 5: return 1, f'dec {R8[y]}', None
        if z == 6: return 2, f'ld {R8[y]}, ${n8():02X}', None
        if z == 7: return 1, ['rlca', 'rrca', 'rla', 'rra', 'daa', 'cpl', 'scf', 'ccf'][y], None
    if x == 1:
        if op == 0x76: return 1, 'halt', None
        return 1, f'ld {R8[y]}, {R8[z]}', None
    if x == 2: return 1, f'{ALU[y]} {R8[z]}', None
    # x == 3
    if op == 0xC9: return 1, 'ret', ('ret', None)
    if op == 0xD9: return 1, 'reti', ('ret', None)
    if op in (0xC0, 0xC8, 0xD0, 0xD8): return 1, f'ret {CC[y]}', None
    if op == 0xE0: return 2, f'ldh [${0xFF00+n8():04X}], a', None
    if op == 0xF0: return 2, f'ldh a, [${0xFF00+n8():04X}]', None
    if op == 0xE2: return 1, 'ldh [c], a', None
    if op == 0xF2: return 1, 'ldh a, [c]', None
    if op == 0xE8: return 2, f'add sp, ${n8():02X}', None
    if op == 0xF8: return 2, f'ld hl, sp+${n8():02X}', None
    if op == 0xE9: return 1, 'jp hl', ('jphl', None)
    if op == 0xF9: return 1, 'ld sp, hl', None
    if op == 0xEA: return 3, f'ld [${n16():04X}], a', None
    if op == 0xFA: return 3, f'ld a, [${n16():04X}]', None
    if op == 0xF3: return 1, 'di', None
    if op == 0xFB: return 1, 'ei', None
    if op == 0xC3: return 3, f'jp ${n16():04X}', ('jp', n16())
    if op in (0xC2, 0xCA, 0xD2, 0xDA): return 3, f'jp {CC[y]}, ${n16():04X}', ('jpc', n16())
    if op == 0xCD: return 3, f'call ${n16():04X}', ('call', n16())
    if op in (0xC4, 0xCC, 0xD4, 0xDC): return 3, f'call {CC[y]}, ${n16():04X}', ('call', n16())
    if z == 1: return 1, f'pop {R16S[y>>1]}', None
    if z == 5: return 1, f'push {R16S[y>>1]}', None
    if z == 6: return 2, f'{ALU[y]} ${n8():02X}', None
    if z == 7: return 1, f'rst ${y*8:02X}', ('rst', y * 8)
    if op == 0xCB:
        c = buf[i + 1]
        cx, cy, cz = c >> 6, (c >> 3) & 7, c & 7
        if cx == 0: return 2, f'{CB[cy]} {R8[cz]}', None
        return 2, f"{['', 'bit', 'res', 'set'][cx]} {cy}, {R8[cz]}", None
    return 1, f'db ${op:02X} ; illegal', ('ill', None)


def listing(buf, base_off, cpu, end):
    i = base_off
    pc = cpu
    out = []
    while pc < end:
        l, t, _ = decode(buf, i, pc)
        out.append(f'{pc:04X}: {buf[i:i+l].hex(" "):9s} {t}')
        i += l
        pc += l
    return '\n'.join(out)


if __name__ == '__main__':
    import sys
    rom = open(sys.argv[1], 'rb').read()
    bank = int(sys.argv[2], 16)
    a = int(sys.argv[3], 16)
    e = int(sys.argv[4], 16)
    off = bank * 0x4000 + (a - (0x4000 if bank else 0))
    print(listing(rom, off, a, e))
