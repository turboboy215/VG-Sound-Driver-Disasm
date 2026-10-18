"""Minimal SM83 (Game Boy CPU) disassembler. decode(rom_bytes_func, addr) -> (length, mnemonic, info)"""
R8 = ['b', 'c', 'd', 'e', 'h', 'l', '[hl]', 'a']
R16 = ['bc', 'de', 'hl', 'sp']
R16S = ['bc', 'de', 'hl', 'af']
CC = ['nz', 'z', 'nc', 'c']
ALU = ['add a,', 'adc a,', 'sub', 'sbc a,', 'and', 'xor', 'or', 'cp']
CB_OPS = ['rlc', 'rrc', 'rl', 'rr', 'sla', 'sra', 'swap', 'srl']

def decode(rd, pc):
    """rd(addr)->byte. returns (len, text, dict(kind, target))"""
    op = rd(pc)
    n8 = lambda: rd(pc + 1)
    n16 = lambda: rd(pc + 1) | (rd(pc + 2) << 8)
    s8 = lambda: (rd(pc + 1) ^ 0x80) - 0x80
    info = {}
    if op == 0x00: return 1, 'nop', info
    if op == 0x10: return 2, 'stop', info
    if op == 0x76: return 1, 'halt', info
    if op == 0xCB:
        c = rd(pc + 1); r = R8[c & 7]; y = (c >> 3) & 7
        if c < 0x40: return 2, f'{CB_OPS[y]} {r}', info
        return 2, f"{['bit','res','set'][(c >> 6) - 1]} {y}, {r}", info
    x = op >> 6; y = (op >> 3) & 7; z = op & 7
    if x == 1: return 1, f'ld {R8[y]}, {R8[z]}', info
    if x == 2: return 1, f'{ALU[y]} {R8[z]}', info
    if x == 0:
        if z == 0:
            if op == 0x08: return 3, f'ld [${n16():04X}], sp', info
            if op == 0x18:
                t = (pc + 2 + s8()) & 0xFFFF; info.update(kind='jr', target=t, cond=False)
                return 2, f'jr ${t:04X}', info
            if op >= 0x20:
                t = (pc + 2 + s8()) & 0xFFFF; info.update(kind='jr', target=t, cond=True)
                return 2, f'jr {CC[y-4]}, ${t:04X}', info
        if z == 1:
            if y & 1: return 1, f'add hl, {R16[y>>1]}', info
            v = n16(); info['imm16'] = v
            return 3, f'ld {R16[y>>1]}, ${v:04X}', info
        if z == 2:
            m = ['[bc]', '[de]', '[hli]', '[hld]'][y >> 1]
            return 1, (f'ld a, {m}' if y & 1 else f'ld {m}, a'), info
        if z == 3: return 1, f"{'dec' if y&1 else 'inc'} {R16[y>>1]}", info
        if z == 4: return 1, f'inc {R8[y]}', info
        if z == 5: return 1, f'dec {R8[y]}', info
        if z == 6: return 2, f'ld {R8[y]}, ${n8():02X}', info
        if z == 7: return 1, ['rlca', 'rrca', 'rla', 'rra', 'daa', 'cpl', 'scf', 'ccf'][y], info
    # x == 3
    if z == 0:
        if y < 4: info.update(kind='ret', cond=True); return 1, f'ret {CC[y]}', info
        if y == 4: return 2, f'ldh [$FF{n8():02X}], a', info
        if y == 5: return 2, f'add sp, {s8()}', info
        if y == 6: return 2, f'ldh a, [$FF{n8():02X}]', info
        if y == 7: return 2, f'ld hl, sp{s8():+d}', info
    if z == 1:
        if y & 1 == 0: return 1, f'pop {R16S[y>>1]}', info
        if y == 1: info.update(kind='ret', cond=False); return 1, 'ret', info
        if y == 3: info.update(kind='ret', cond=False); return 1, 'reti', info
        if y == 5: info.update(kind='jp', cond=False, target=None); return 1, 'jp hl', info
        if y == 7: return 1, 'ld sp, hl', info
    if z == 2:
        if y < 4:
            t = n16(); info.update(kind='jp', target=t, cond=True); return 3, f'jp {CC[y]}, ${t:04X}', info
        if y == 4: return 1, 'ldh [c], a', info
        if y == 5: return 3, f'ld [${n16():04X}], a', info
        if y == 6: return 1, 'ldh a, [c]', info
        if y == 7: return 3, f'ld a, [${n16():04X}]', info
    if z == 3:
        if y == 0:
            t = n16(); info.update(kind='jp', target=t, cond=False); return 3, f'jp ${t:04X}', info
        if y == 6: return 1, 'di', info
        if y == 7: return 1, 'ei', info
        return 1, f'db ${op:02X}', {'kind': 'bad'}
    if z == 4:
        if y < 4:
            t = n16(); info.update(kind='call', target=t, cond=True); return 3, f'call {CC[y]}, ${t:04X}', info
        return 1, f'db ${op:02X}', {'kind': 'bad'}
    if z == 5:
        if y & 1 == 0: return 1, f'push {R16S[y>>1]}', info
        if y == 1:
            t = n16(); info.update(kind='call', target=t, cond=False); return 3, f'call ${t:04X}', info
        return 1, f'db ${op:02X}', {'kind': 'bad'}
    if z == 6: return 2, f'{ALU[y]} ${n8():02X}', info
    if z == 7:
        info.update(kind='rst', target=y * 8); return 1, f'rst ${y*8:02X}', info
