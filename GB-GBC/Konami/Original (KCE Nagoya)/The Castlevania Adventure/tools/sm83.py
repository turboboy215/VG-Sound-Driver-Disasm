"""Minimal SM83 (Game Boy CPU) disassembler. Usage: sm83.py rom bank:addr [count]"""
import sys

R = ['b', 'c', 'd', 'e', 'h', 'l', '[hl]', 'a']
RP = ['bc', 'de', 'hl', 'sp']
RP2 = ['bc', 'de', 'hl', 'af']
CC = ['nz', 'z', 'nc', 'c']
ALU = ['add a,', 'adc a,', 'sub ', 'sbc a,', 'and ', 'xor ', 'or ', 'cp ']
ROT = ['rlc', 'rrc', 'rl', 'rr', 'sla', 'sra', 'swap', 'srl']


def decode(mem, pc):
    """Return (length, text, target) where target is a jump/call target or None.
    mem: callable addr->byte."""
    op = mem(pc)
    b1 = lambda: mem(pc + 1)
    w = lambda: mem(pc + 1) | (mem(pc + 2) << 8)
    x, y, z = op >> 6, (op >> 3) & 7, op & 7
    p, q = y >> 1, y & 1
    if op == 0xCB:
        o2 = mem(pc + 1)
        x2, y2, z2 = o2 >> 6, (o2 >> 3) & 7, o2 & 7
        if x2 == 0:
            return 2, f'{ROT[y2]} {R[z2]}', None
        return 2, f"{['', 'bit', 'res', 'set'][x2]} {y2},{R[z2]}", None
    if x == 1:
        if op == 0x76:
            return 1, 'halt', None
        return 1, f'ld {R[y]},{R[z]}', None
    if x == 2:
        return 1, f'{ALU[y]}{R[z]}', None
    if x == 0:
        if z == 0:
            if y == 0: return 1, 'nop', None
            if y == 1: return 3, f'ld [${w():04X}],sp', None
            if y == 2: return 2, 'stop', None
            d = b1(); d = d - 256 if d > 127 else d
            t = (pc + 2 + d) & 0xFFFF
            if y == 3: return 2, f'jr ${t:04X}', t
            return 2, f'jr {CC[y-4]},${t:04X}', t
        if z == 1:
            if q == 0: return 3, f'ld {RP[p]},${w():04X}', None
            return 1, f'add hl,{RP[p]}', None
        if z == 2:
            s = ['[bc]', '[de]', '[hl+]', '[hl-]'][p]
            return 1, (f'ld {s},a' if q == 0 else f'ld a,{s}'), None
        if z == 3:
            return 1, f"{['inc', 'dec'][q]} {RP[p]}", None
        if z == 4: return 1, f'inc {R[y]}', None
        if z == 5: return 1, f'dec {R[y]}', None
        if z == 6: return 2, f'ld {R[y]},${b1():02X}', None
        return 1, ['rlca', 'rrca', 'rla', 'rra', 'daa', 'cpl', 'scf', 'ccf'][y], None
    # x == 3
    if z == 0:
        if y < 4: return 1, f'ret {CC[y]}', None
        if y == 4: return 2, f'ldh [$FF{b1():02X}],a', None
        if y == 5:
            d = b1(); d = d - 256 if d > 127 else d
            return 2, f'add sp,{d}', None
        if y == 6: return 2, f'ldh a,[$FF{b1():02X}]', None
        d = b1(); d = d - 256 if d > 127 else d
        return 2, f'ld hl,sp{d:+d}', None
    if z == 1:
        if q == 0: return 1, f'pop {RP2[p]}', None
        return 1, ['ret', 'reti', 'jp hl', 'ld sp,hl'][p], None
    if z == 2:
        if y < 4: return 3, f'jp {CC[y]},${w():04X}', w()
        if y == 4: return 1, 'ld [$FF00+c],a', None
        if y == 5: return 3, f'ld [${w():04X}],a', None
        if y == 6: return 1, 'ld a,[$FF00+c]', None
        return 3, f'ld a,[${w():04X}]', None
    if z == 3:
        if y == 0: return 3, f'jp ${w():04X}', w()
        if y == 6: return 1, 'di', None
        if y == 7: return 1, 'ei', None
        return 1, f'db ${op:02X} ; illegal', None
    if z == 4:
        if y < 4: return 3, f'call {CC[y]},${w():04X}', w()
        return 1, f'db ${op:02X} ; illegal', None
    if z == 5:
        if q == 0: return 1, f'push {RP2[p]}', None
        if p == 0: return 3, f'call ${w():04X}', w()
        return 1, f'db ${op:02X} ; illegal', None
    if z == 6: return 2, f'{ALU[y]}${b1():02X}', None
    return 1, f'rst ${y*8:02X}', y * 8


def rommem(rom, bank):
    def m(a):
        a &= 0xFFFF
        if a < 0x4000: return rom[a]
        if a < 0x8000: return rom[bank * 0x4000 + a - 0x4000]
        return 0
    return m


if __name__ == '__main__':
    rom = open(sys.argv[1], 'rb').read()
    bank, addr = sys.argv[2].split(':')
    bank = int(bank, 16); addr = int(addr, 16)
    n = int(sys.argv[3]) if len(sys.argv) > 3 else 40
    m = rommem(rom, bank)
    for _ in range(n):
        l, t, _ = decode(m, addr)
        bs = ' '.join(f'{m(addr+i):02X}' for i in range(l))
        print(f'{bank:02X}:{addr:04X}  {bs:<9} {t}')
        addr += l
