"""Minimal SM83 (Game Boy CPU) disassembler, RGBDS syntax."""
R8 = ['b', 'c', 'd', 'e', 'h', 'l', '[hl]', 'a']
R16 = ['bc', 'de', 'hl', 'sp']
R16S = ['bc', 'de', 'hl', 'af']
CC = ['nz', 'z', 'nc', 'c']
ALU = ['add a,', 'adc a,', 'sub a,', 'sbc a,', 'and a,', 'xor a,', 'or a,', 'cp a,']
CB = ['rlc', 'rrc', 'rl', 'rr', 'sla', 'sra', 'swap', 'srl']


def decode(mem, pc):
    """Return (length, mnemonic_template, operand_info).
    operand_info: None or (kind, value) where kind in 'imm8','imm16','addr16','rel','ldh','sp8'.
    Template uses {} for the operand."""
    op = mem[pc]
    def b1():
        return mem[pc + 1]
    def w1():
        return mem[pc + 1] | (mem[pc + 2] << 8)
    if op == 0x00: return 1, 'nop', None
    if op == 0x10: return 2, 'stop', None
    if op == 0x76: return 1, 'halt', None
    if op == 0xF3: return 1, 'di', None
    if op == 0xFB: return 1, 'ei', None
    if op == 0x07: return 1, 'rlca', None
    if op == 0x0F: return 1, 'rrca', None
    if op == 0x17: return 1, 'rla', None
    if op == 0x1F: return 1, 'rra', None
    if op == 0x27: return 1, 'daa', None
    if op == 0x2F: return 1, 'cpl', None
    if op == 0x37: return 1, 'scf', None
    if op == 0x3F: return 1, 'ccf', None
    if op == 0x08: return 3, 'ld [{}], sp', ('addr16', w1())
    if op == 0x18: return 2, 'jr {}', ('rel', (pc + 2 + ((b1() ^ 0x80) - 0x80)) & 0xFFFF)
    if op in (0x20, 0x28, 0x30, 0x38):
        return 2, 'jr ' + CC[(op >> 3) & 3] + ', {}', ('rel', (pc + 2 + ((b1() ^ 0x80) - 0x80)) & 0xFFFF)
    if op & 0xCF == 0x01: return 3, 'ld ' + R16[op >> 4] + ', {}', ('imm16', w1())
    if op & 0xCF == 0x09: return 1, 'add hl, ' + R16[op >> 4], None
    if op & 0xCF == 0x03: return 1, 'inc ' + R16[op >> 4], None
    if op & 0xCF == 0x0B: return 1, 'dec ' + R16[op >> 4], None
    if op == 0x02: return 1, 'ld [bc], a', None
    if op == 0x12: return 1, 'ld [de], a', None
    if op == 0x22: return 1, 'ld [hli], a', None
    if op == 0x32: return 1, 'ld [hld], a', None
    if op == 0x0A: return 1, 'ld a, [bc]', None
    if op == 0x1A: return 1, 'ld a, [de]', None
    if op == 0x2A: return 1, 'ld a, [hli]', None
    if op == 0x3A: return 1, 'ld a, [hld]', None
    if op & 0xC7 == 0x04: return 1, 'inc ' + R8[(op >> 3) & 7], None
    if op & 0xC7 == 0x05: return 1, 'dec ' + R8[(op >> 3) & 7], None
    if op & 0xC7 == 0x06: return 2, 'ld ' + R8[(op >> 3) & 7] + ', {}', ('imm8', b1())
    if 0x40 <= op < 0x80:
        return 1, 'ld ' + R8[(op >> 3) & 7] + ', ' + R8[op & 7], None
    if 0x80 <= op < 0xC0:
        return 1, ALU[(op >> 3) & 7] + ' ' + R8[op & 7], None
    if op in (0xC0, 0xC8, 0xD0, 0xD8): return 1, 'ret ' + CC[(op >> 3) & 3], None
    if op == 0xC9: return 1, 'ret', None
    if op == 0xD9: return 1, 'reti', None
    if op & 0xCF == 0xC1: return 1, 'pop ' + R16S[(op >> 4) & 3], None
    if op & 0xCF == 0xC5: return 1, 'push ' + R16S[(op >> 4) & 3], None
    if op in (0xC2, 0xCA, 0xD2, 0xDA): return 3, 'jp ' + CC[(op >> 3) & 3] + ', {}', ('addr16', w1())
    if op == 0xC3: return 3, 'jp {}', ('addr16', w1())
    if op == 0xE9: return 1, 'jp hl', None
    if op in (0xC4, 0xCC, 0xD4, 0xDC): return 3, 'call ' + CC[(op >> 3) & 3] + ', {}', ('addr16', w1())
    if op == 0xCD: return 3, 'call {}', ('addr16', w1())
    if op & 0xC7 == 0xC7: return 1, 'rst ${:02X}'.format(op & 0x38), None
    if op & 0xC7 == 0xC6: return 2, ALU[(op >> 3) & 7] + ' {}', ('imm8', b1())
    if op == 0xE0: return 2, 'ldh [{}], a', ('ldh', 0xFF00 | b1())
    if op == 0xF0: return 2, 'ldh a, [{}]', ('ldh', 0xFF00 | b1())
    if op == 0xE2: return 1, 'ldh [c], a', None
    if op == 0xF2: return 1, 'ldh a, [c]', None
    if op == 0xEA: return 3, 'ld [{}], a', ('addr16', w1())
    if op == 0xFA: return 3, 'ld a, [{}]', ('addr16', w1())
    if op == 0xE8: return 2, 'add sp, {}', ('sp8', b1())
    if op == 0xF8: return 2, 'ld hl, sp+{}', ('sp8', b1())
    if op == 0xF9: return 1, 'ld sp, hl', None
    if op == 0xCB:
        c = b1()
        r = R8[c & 7]
        if c < 0x40: return 2, CB[c >> 3] + ' ' + r, None
        return 2, ['bit', 'res', 'set'][(c >> 6) - 1] + ' {}, '.format((c >> 3) & 7) + r, None
    return 1, None, None  # illegal


def flow(mem, pc):
    """Return (length, targets, falls_through)."""
    n, m, o = decode(mem, pc)
    op = mem[pc]
    if m is None:
        return n, [], False
    t = []
    if o and o[0] in ('rel', 'addr16') and (m.startswith('j') or m.startswith('call')):
        t.append(o[1])
    ft = True
    if op in (0xC3, 0x18, 0xE9, 0xC9, 0xD9):
        ft = False
    return n, t, ft
