"""Minimal SM83 (Game Boy CPU) disassembler.

decode(rom, addr) -> (length, mnemonic_template, operand_value, flow)
  mnemonic_template uses {} for a formatted operand.
  flow: None | ('jp', tgt) | ('jpc', tgt) | ('call', tgt) | ('callc', tgt) |
        ('jr', tgt) | ('jrc', tgt) | ('ret',) | ('retc',) | ('jphl',) | ('rst', tgt) | ('stop',)
"""
R8 = ['b', 'c', 'd', 'e', 'h', 'l', '[hl]', 'a']
R16 = ['bc', 'de', 'hl', 'sp']
R16S = ['bc', 'de', 'hl', 'af']
CC = ['nz', 'z', 'nc', 'c']
ALU = ['add a,', 'adc a,', 'sub', 'sbc a,', 'and', 'xor', 'or', 'cp']
ROT = ['rlc', 'rrc', 'rl', 'rr', 'sla', 'sra', 'swap', 'srl']


def _s8(v):
    return v - 256 if v >= 128 else v


def decode(b, a):
    """b: bytes-like indexed by CPU address (callable or sequence)."""
    op = b[a]
    def n8():
        return b[a + 1]
    def n16():
        return b[a + 1] | (b[a + 2] << 8)
    if op == 0x00: return 1, 'nop', None, None
    if op == 0x10: return 2, 'stop', None, ('stop',)
    if op == 0x76: return 1, 'halt', None, None
    if op == 0xF3: return 1, 'di', None, None
    if op == 0xFB: return 1, 'ei', None, None
    if op == 0xCB:
        x = b[a + 1]
        r = R8[x & 7]
        g = x >> 6
        if g == 0: return 2, f'{ROT[(x >> 3) & 7]} {r}', None, None
        return 2, f"{['', 'bit', 'res', 'set'][g]} {(x >> 3) & 7}, {r}", None, None
    if 0x40 <= op < 0x80:
        return 1, f'ld {R8[(op >> 3) & 7]}, {R8[op & 7]}', None, None
    if 0x80 <= op < 0xC0:
        return 1, f'{ALU[(op >> 3) & 7]} {R8[op & 7]}', None, None
    lo3 = op & 7
    if op < 0x40:
        y = (op >> 3) & 7
        p = (op >> 4) & 3
        if lo3 == 0:
            if op == 0x08: return 3, 'ld [{}], sp', n16(), None
            if op == 0x18:
                t = (a + 2 + _s8(n8())) & 0xFFFF
                return 2, 'jr {}', t, ('jr', t)
            if op in (0x20, 0x28, 0x30, 0x38):
                t = (a + 2 + _s8(n8())) & 0xFFFF
                return 2, f'jr {CC[y - 4]}, ' + '{}', t, ('jrc', t)
        if lo3 == 1:
            if op & 8: return 1, f'add hl, {R16[p]}', None, None
            return 3, f'ld {R16[p]}, ' + '{}', n16(), None
        if lo3 == 2:
            m = ['[bc]', '[de]', '[hli]', '[hld]'][p]
            if op & 8: return 1, f'ld a, {m}', None, None
            return 1, f'ld {m}, a', None, None
        if lo3 == 3:
            return 1, f"{'dec' if op & 8 else 'inc'} {R16[p]}", None, None
        if lo3 == 4: return 1, f'inc {R8[y]}', None, None
        if lo3 == 5: return 1, f'dec {R8[y]}', None, None
        if lo3 == 6: return 2, f'ld {R8[y]}, ' + '{b}', n8(), None
        if lo3 == 7: return 1, ['rlca', 'rrca', 'rla', 'rra', 'daa', 'cpl', 'scf', 'ccf'][y], None, None
    y = (op >> 3) & 7
    p = (op >> 4) & 3
    if op in (0xC0, 0xC8, 0xD0, 0xD8): return 1, f'ret {CC[y]}', None, ('retc',)
    if op == 0xC9: return 1, 'ret', None, ('ret',)
    if op == 0xD9: return 1, 'reti', None, ('ret',)
    if op == 0xE0: return 2, 'ldh [{h}], a', n8(), None
    if op == 0xF0: return 2, 'ldh a, [{h}]', n8(), None
    if op == 0xE8: return 2, 'add sp, {s}', n8(), None
    if op == 0xF8: return 2, 'ld hl, sp+{s}', n8(), None
    if op in (0xC1, 0xD1, 0xE1, 0xF1): return 1, f'pop {R16S[p]}', None, None
    if op in (0xC5, 0xD5, 0xE5, 0xF5): return 1, f'push {R16S[p]}', None, None
    if op == 0xE9: return 1, 'jp hl', None, ('jphl',)
    if op == 0xF9: return 1, 'ld sp, hl', None, None
    if op in (0xC2, 0xCA, 0xD2, 0xDA):
        t = n16(); return 3, f'jp {CC[y]}, ' + '{}', t, ('jpc', t)
    if op == 0xC3:
        t = n16(); return 3, 'jp {}', t, ('jp', t)
    if op == 0xE2: return 1, 'ldh [c], a', None, None
    if op == 0xF2: return 1, 'ldh a, [c]', None, None
    if op == 0xEA: return 3, 'ld [{}], a', n16(), None
    if op == 0xFA: return 3, 'ld a, [{}]', n16(), None
    if op in (0xC4, 0xCC, 0xD4, 0xDC):
        t = n16(); return 3, f'call {CC[y]}, ' + '{}', t, ('callc', t)
    if op == 0xCD:
        t = n16(); return 3, 'call {}', t, ('call', t)
    if lo3 == 6: return 2, f'{ALU[y]} ' + '{b}', n8(), None
    if lo3 == 7:
        t = y * 8; return 1, f'rst ${t:02X}', None, ('rst', t)
    return 1, f'db ${op:02X} ; illegal', None, ('ill',)


def fmt(tmpl, val, name=None):
    if '{}' in tmpl:
        return tmpl.replace('{}', name if name else f'${val:04X}')
    if '{b}' in tmpl:
        return tmpl.replace('{b}', f'${val:02X}')
    if '{h}' in tmpl:
        return tmpl.replace('{h}', name if name else f'$FF{val:02X}')
    if '{s}' in tmpl:
        v = _s8(val)
        return tmpl.replace('{s}', str(v))
    return tmpl
