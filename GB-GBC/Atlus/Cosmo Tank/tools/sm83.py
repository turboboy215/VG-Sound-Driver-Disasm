"""Minimal SM83 (Game Boy CPU) disassembler. decode(buf, off, pc) -> (length, mnemonic, operand_info)
operand_info: dict with optional 'target' (jump/call address), 'imm16', 'kind'."""
R8 = ['b', 'c', 'd', 'e', 'h', 'l', '[hl]', 'a']
R16 = ['bc', 'de', 'hl', 'sp']
R16S = ['bc', 'de', 'hl', 'af']
CC = ['nz', 'z', 'nc', 'c']
ALU = ['add a,', 'adc a,', 'sub', 'sbc a,', 'and', 'xor', 'or', 'cp']
ROT = ['rlc', 'rrc', 'rl', 'rr', 'sla', 'sra', 'swap', 'srl']


def decode(m, i, pc):
    """m: bytes, i: offset into m, pc: address of instruction."""
    op = m[i]
    n8 = lambda: m[i + 1]
    n16 = lambda: m[i + 1] | (m[i + 2] << 8)
    info = {}
    x, y, z = op >> 6, (op >> 3) & 7, op & 7
    if op == 0xCB:
        o = m[i + 1]
        cx, cy, cz = o >> 6, (o >> 3) & 7, o & 7
        if cx == 0:
            return 2, f'{ROT[cy]} {R8[cz]}', info
        return 2, f"{['', 'bit', 'res', 'set'][cx]} {cy}, {R8[cz]}", info
    if x == 1:
        if op == 0x76:
            return 1, 'halt', info
        return 1, f'ld {R8[y]}, {R8[z]}', info
    if x == 2:
        return 1, f'{ALU[y]} {R8[z]}', info
    if x == 0:
        if z == 0:
            if y == 0: return 1, 'nop', info
            if y == 1: info['imm16'] = n16(); return 3, 'ld [${:04X}], sp'.format(n16()), info
            if y == 2: return 2, 'stop', info
            d = n8(); d = d - 256 if d > 127 else d
            t = (pc + 2 + d) & 0xFFFF
            info['target'] = t; info['kind'] = 'jr'
            if y == 3: return 2, 'jr ${:04X}'.format(t), info
            return 2, 'jr {}, ${:04X}'.format(CC[y - 4], t), info
        if z == 1:
            if y & 1: return 1, f'add hl, {R16[y >> 1]}', info
            info['imm16'] = n16()
            return 3, 'ld {}, ${:04X}'.format(R16[y >> 1], n16()), info
        if z == 2:
            p = ['[bc]', '[de]', '[hli]', '[hld]'][y >> 1]
            return 1, (f'ld a, {p}' if y & 1 else f'ld {p}, a'), info
        if z == 3:
            return 1, ('dec ' if y & 1 else 'inc ') + R16[y >> 1], info
        if z == 4: return 1, f'inc {R8[y]}', info
        if z == 5: return 1, f'dec {R8[y]}', info
        if z == 6: return 2, 'ld {}, ${:02X}'.format(R8[y], n8()), info
        return 1, ['rlca', 'rrca', 'rla', 'rra', 'daa', 'cpl', 'scf', 'ccf'][y], info
    # x == 3
    if z == 0:
        if y < 4: info['kind'] = 'ret'; return 1, f'ret {CC[y]}', info
        if y == 4: return 2, 'ldh [${:02X}], a'.format(n8()), info
        if y == 5:
            d = n8(); d = d - 256 if d > 127 else d
            return 2, f'add sp, {d}', info
        if y == 6: return 2, 'ldh a, [${:02X}]'.format(n8()), info
        d = n8(); d = d - 256 if d > 127 else d
        return 2, f'ld hl, sp{d:+d}', info
    if z == 1:
        if y & 1 == 0: return 1, f'pop {R16S[y >> 1]}', info
        if y == 1: info['kind'] = 'end'; return 1, 'ret', info
        if y == 3: info['kind'] = 'end'; return 1, 'reti', info
        if y == 5: info['kind'] = 'end'; return 1, 'jp hl', info
        return 1, 'ld sp, hl', info
    if z == 2:
        if y < 4:
            info['target'] = n16(); info['kind'] = 'jp'
            return 3, 'jp {}, ${:04X}'.format(CC[y], n16()), info
        if y == 4: return 1, 'ldh [c], a', info
        if y == 5: info['imm16'] = n16(); return 3, 'ld [${:04X}], a'.format(n16()), info
        if y == 6: return 1, 'ldh a, [c]', info
        info['imm16'] = n16(); return 3, 'ld a, [${:04X}]'.format(n16()), info
    if z == 3:
        if y == 0:
            info['target'] = n16(); info['kind'] = 'jpu'
            return 3, 'jp ${:04X}'.format(n16()), info
        if y == 1: return 2, 'CB?', info
        if y == 6: return 1, 'di', info
        if y == 7: return 1, 'ei', info
        return 1, 'db ${:02X}'.format(op), {'kind': 'bad'}
    if z == 4:
        if y < 4:
            info['target'] = n16(); info['kind'] = 'call'
            return 3, 'call {}, ${:04X}'.format(CC[y], n16()), info
        return 1, 'db ${:02X}'.format(op), {'kind': 'bad'}
    if z == 5:
        if y & 1 == 0: return 1, f'push {R16S[y >> 1]}', info
        if y == 1:
            info['target'] = n16(); info['kind'] = 'call'
            return 3, 'call ${:04X}'.format(n16()), info
        return 1, 'db ${:02X}'.format(op), {'kind': 'bad'}
    if z == 6: return 2, '{} ${:02X}'.format(ALU[y], n8()), info
    info['target'] = y * 8; info['kind'] = 'rst'
    return 1, 'rst ${:02X}'.format(y * 8), info


def listing(m, start, end, base):
    """Linear listing m[start:end] as addresses base+offset."""
    out = []
    i = start
    while i < end:
        n, s, _ = decode(m, i, base + i - start if False else base + (i - start))
        out.append((base + (i - start), m[i:i + n].hex(), s))
        i += n
    return out
