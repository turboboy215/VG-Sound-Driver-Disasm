"""Minimal SM83 disassembler. dis(mem_read, addr) -> (length, mnemonic, operand_info)
operand_info: dict with optional keys 'imm8','imm16','rel','target','ldh'
mnemonic uses RGBDS syntax with placeholders {n8} {n16} {a16} {e8} {r8tgt} so a caller can label.
"""
R = ['b', 'c', 'd', 'e', 'h', 'l', '[hl]', 'a']
RP = ['bc', 'de', 'hl', 'sp']
RP2 = ['bc', 'de', 'hl', 'af']
CC = ['nz', 'z', 'nc', 'c']
ALU = ['add a,', 'adc a,', 'sub ', 'sbc a,', 'and ', 'xor ', 'or ', 'cp ']
ROT = ['rlc', 'rrc', 'rl', 'rr', 'sla', 'sra', 'swap', 'srl']


def decode(rd, pc):
    """returns (len, fmt, kind, value). fmt contains one of {n8},{n16},{a16},{e8},{h8},{s8} placeholder or none."""
    op = rd(pc)
    x, y, z = op >> 6, (op >> 3) & 7, op & 7
    p, q = y >> 1, y & 1
    n8 = lambda: rd(pc + 1)
    n16 = lambda: rd(pc + 1) | (rd(pc + 2) << 8)
    if op == 0xCB:
        o = rd(pc + 1)
        cx, cy, cz = o >> 6, (o >> 3) & 7, o & 7
        if cx == 0:
            return 2, f'{ROT[cy]} {R[cz]}', None, None
        return 2, f"{['', 'bit', 'res', 'set'][cx]} {cy},{R[cz]}", None, None
    if x == 0:
        if z == 0:
            if y == 0: return 1, 'nop', None, None
            if y == 1: return 3, 'ld [{a16}],sp', 'a16', n16()
            if y == 2: return 2, 'stop', None, None
            if y == 3: return 2, 'jr {e8}', 'rel', (pc + 2 + ((n8() ^ 0x80) - 0x80)) & 0xFFFF
            return 2, f'jr {CC[y-4]},{{e8}}', 'rel', (pc + 2 + ((n8() ^ 0x80) - 0x80)) & 0xFFFF
        if z == 1:
            if q == 0: return 3, f'ld {RP[p]},{{n16}}', 'n16', n16()
            return 1, f'add hl,{RP[p]}', None, None
        if z == 2:
            m = ['ld [bc],a', 'ld a,[bc]', 'ld [de],a', 'ld a,[de]', 'ld [hli],a', 'ld a,[hli]', 'ld [hld],a', 'ld a,[hld]']
            return 1, m[y], None, None
        if z == 3: return 1, f"{'inc' if q == 0 else 'dec'} {RP[p]}", None, None
        if z == 4: return 1, f'inc {R[y]}', None, None
        if z == 5: return 1, f'dec {R[y]}', None, None
        if z == 6: return 2, f'ld {R[y]},{{n8}}', 'n8', n8()
        return 1, ['rlca', 'rrca', 'rla', 'rra', 'daa', 'cpl', 'scf', 'ccf'][y], None, None
    if x == 1:
        if op == 0x76: return 1, 'halt', None, None
        return 1, f'ld {R[y]},{R[z]}', None, None
    if x == 2:
        return 1, f'{ALU[y]}{R[z]}', None, None
    # x==3
    if z == 0:
        if y < 4: return 1, f'ret {CC[y]}', None, None
        if y == 4: return 2, 'ldh [{h8}],a', 'h8', n8()
        if y == 5: return 2, 'add sp,{s8}', 's8', n8()
        if y == 6: return 2, 'ldh a,[{h8}]', 'h8', n8()
        return 2, 'ld hl,sp+{s8}', 's8', n8()
    if z == 1:
        if q == 0: return 1, f'pop {RP2[p]}', None, None
        return 1, ['ret', 'reti', 'jp hl', 'ld sp,hl'][p], None, None
    if z == 2:
        if y < 4: return 3, f'jp {CC[y]},{{a16}}', 'jp', n16()
        if y == 4: return 1, 'ldh [c],a', None, None
        if y == 5: return 3, 'ld [{a16}],a', 'a16', n16()
        if y == 6: return 1, 'ldh a,[c]', None, None
        return 3, 'ld a,[{a16}]', 'a16', n16()
    if z == 3:
        if y == 0: return 3, 'jp {a16}', 'jp', n16()
        if y == 6: return 1, 'di', None, None
        if y == 7: return 1, 'ei', None, None
        return 1, f'db ${op:02X}', None, None
    if z == 4:
        if y < 4: return 3, f'call {CC[y]},{{a16}}', 'call', n16()
        return 1, f'db ${op:02X}', None, None
    if z == 5:
        if q == 0: return 1, f'push {RP2[p]}', None, None
        if p == 0: return 3, 'call {a16}', 'call', n16()
        return 1, f'db ${op:02X}', None, None
    if z == 6: return 2, f'{ALU[y]}{{n8}}', 'n8', n8()
    return 1, f'rst ${y*8:02X}', None, None


def fmt(text, kind, val, label=None):
    if kind is None:
        return text
    if label:
        s = label
    elif kind in ('n8', 'h8', 's8'):
        s = f'${val:02X}'
    else:
        s = f'${val:04X}'
    return text.replace('{n8}', s).replace('{n16}', s).replace('{a16}', s).replace('{e8}', s).replace('{h8}', s).replace('{s8}', s)


def is_end(text):
    t = text.split()[0] if text else ''
    return text in ('ret', 'reti', 'jp hl') or text.startswith('jp $') or text.startswith('jp {') or text.startswith('jr {')
