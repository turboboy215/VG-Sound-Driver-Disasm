"""Minimal SM83 (Game Boy CPU) disassembler."""
R8 = ['b', 'c', 'd', 'e', 'h', 'l', '[hl]', 'a']
R16 = ['bc', 'de', 'hl', 'sp']
R16P = ['bc', 'de', 'hl', 'af']
CC = ['nz', 'z', 'nc', 'c']
ALU = ['add a,', 'adc a,', 'sub ', 'sbc a,', 'and ', 'xor ', 'or ', 'cp ']
ROT = ['rlc', 'rrc', 'rl', 'rr', 'sla', 'sra', 'swap', 'srl']


def ins(rom, pc, base=0):
    """Return (length, text, kind, target). pc is a CPU address; base is file
    offset of CPU address (file = base + pc)."""
    def b(i):
        return rom[base + pc + i]
    op = b(0)
    n8 = lambda: b(1)
    n16 = lambda: b(1) | (b(2) << 8)
    x, y, z = op >> 6, (op >> 3) & 7, op & 7
    if op == 0xCB:
        o = b(1)
        x2, y2, z2 = o >> 6, (o >> 3) & 7, o & 7
        if x2 == 0:
            return 2, f'{ROT[y2]} {R8[z2]}', None, None
        return 2, f'{["", "bit", "res", "set"][x2]} {y2},{R8[z2]}', None, None
    t = {
        0x00: (1, 'nop'), 0x07: (1, 'rlca'), 0x0F: (1, 'rrca'), 0x17: (1, 'rla'),
        0x1F: (1, 'rra'), 0x27: (1, 'daa'), 0x2F: (1, 'cpl'), 0x37: (1, 'scf'),
        0x3F: (1, 'ccf'), 0x76: (1, 'halt'), 0x10: (2, 'stop'), 0xF3: (1, 'di'),
        0xFB: (1, 'ei'), 0xC9: (1, 'ret'), 0xD9: (1, 'reti'), 0xE9: (1, 'jp hl'),
        0xF9: (1, 'ld sp,hl'), 0x02: (1, 'ld [bc],a'), 0x12: (1, 'ld [de],a'),
        0x22: (1, 'ld [hli],a'), 0x32: (1, 'ld [hld],a'), 0x0A: (1, 'ld a,[bc]'),
        0x1A: (1, 'ld a,[de]'), 0x2A: (1, 'ld a,[hli]'), 0x3A: (1, 'ld a,[hld]'),
        0xE2: (1, 'ldh [c],a'), 0xF2: (1, 'ldh a,[c]'),
    }
    if op in t:
        l, s = t[op]
        kind = 'ret' if op in (0xC9, 0xD9) else ('jphl' if op == 0xE9 else None)
        return l, s, kind, None
    if op == 0x08:
        return 3, f'ld [${n16():04X}],sp', None, None
    if op == 0x18:
        d = n8(); d = d - 256 if d > 127 else d
        return 2, f'jr ${pc + 2 + d:04X}', 'jr', pc + 2 + d
    if x == 0 and z == 0 and y >= 4:
        d = n8(); d = d - 256 if d > 127 else d
        return 2, f'jr {CC[y - 4]},${pc + 2 + d:04X}', 'jrc', pc + 2 + d
    if x == 0 and z == 1:
        if y & 1:
            return 1, f'add hl,{R16[y >> 1]}', None, None
        return 3, f'ld {R16[y >> 1]},${n16():04X}', 'ld16', n16()
    if x == 0 and z == 3:
        return 1, f'{"dec" if y & 1 else "inc"} {R16[y >> 1]}', None, None
    if x == 0 and z == 4:
        return 1, f'inc {R8[y]}', None, None
    if x == 0 and z == 5:
        return 1, f'dec {R8[y]}', None, None
    if x == 0 and z == 6:
        return 2, f'ld {R8[y]},${n8():02X}', None, None
    if x == 1:
        return 1, f'ld {R8[y]},{R8[z]}', None, None
    if x == 2:
        return 1, f'{ALU[y]}{R8[z]}', None, None
    if x == 3:
        if z == 0:
            if y < 4:
                return 1, f'ret {CC[y]}', 'retc', None
            if y == 4:
                return 2, f'ldh [$FF{n8():02X}],a', None, None
            if y == 6:
                return 2, f'ldh a,[$FF{n8():02X}]', None, None
            if y == 5:
                d = n8(); d = d - 256 if d > 127 else d
                return 2, f'add sp,{d}', None, None
            d = n8(); d = d - 256 if d > 127 else d
            return 2, f'ld hl,sp{d:+d}', None, None
        if z == 1:
            return 1, f'pop {R16P[y >> 1]}', None, None
        if z == 2:
            if y < 4:
                return 3, f'jp {CC[y]},${n16():04X}', 'jpc', n16()
            if y == 5:
                return 3, f'ld [${n16():04X}],a', None, None
            if y == 7:
                return 3, f'ld a,[${n16():04X}]', None, None
        if z == 3 and y == 0:
            return 3, f'jp ${n16():04X}', 'jp', n16()
        if z == 4 and y < 4:
            return 3, f'call {CC[y]},${n16():04X}', 'call', n16()
        if z == 5:
            if y == 1:
                return 3, f'call ${n16():04X}', 'call', n16()
            if not (y & 1):
                return 1, f'push {R16P[y >> 1]}', None, None
        if z == 6:
            return 2, f'{ALU[y]}${n8():02X}', None, None
        if z == 7:
            return 1, f'rst ${y * 8:02X}', 'rst', y * 8
    return 1, f'db ${op:02X} ; ???', 'bad', None


def dis(rom, start, end, base=0):
    pc = start
    out = []
    while pc < end:
        l, s, k, t = ins(rom, pc, base)
        hexb = ' '.join(f'{rom[base + pc + i]:02X}' for i in range(l))
        out.append(f'{pc:04X}: {hexb:<9} {s}')
        pc += l
    return '\n'.join(out)


if __name__ == '__main__':
    import sys
    rom = open(sys.argv[1], 'rb').read()
    bank = int(sys.argv[2], 16)
    s, e = int(sys.argv[3], 16), int(sys.argv[4], 16)
    base = 0 if bank == 0 else (bank - 1) * 0x4000
    print(dis(rom, s, e, base))
