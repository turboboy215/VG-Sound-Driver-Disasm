"""Minimal SM83 (Game Boy CPU) disassembler.

decode(data, off, pc) -> (length, mnemonic_template, operand_info)
The template uses {n8}, {n16}, {a16}, {r8}(relative target), {ldh}.
"""

R8 = ['b', 'c', 'd', 'e', 'h', 'l', '[hl]', 'a']
R16 = ['bc', 'de', 'hl', 'sp']
R16S = ['bc', 'de', 'hl', 'af']
CC = ['nz', 'z', 'nc', 'c']
ALU = ['add a,', 'adc a,', 'sub', 'sbc a,', 'and', 'xor', 'or', 'cp']
ROT = ['rlc', 'rrc', 'rl', 'rr', 'sla', 'sra', 'swap', 'srl']

def _alu(i, x):
    op = ALU[i]
    return f'{op} {x}' if op.endswith(',') else f'{op} {x}'

def table():
    t = {}
    for op in range(256):
        x, y, z = op >> 6, (op >> 3) & 7, op & 7
        p, q = y >> 1, y & 1
        m = None; ln = 1
        if x == 0:
            if z == 0:
                m, ln = {0: ('nop', 1), 1: ('ld [{a16}], sp', 3), 2: ('stop', 2), 3: ('jr {rel}', 2)}.get(y, (f'jr {CC[y-4]}, {{rel}}', 2))
            elif z == 1:
                m, ln = (f'ld {R16[p]}, {{n16}}', 3) if q == 0 else (f'add hl, {R16[p]}', 1)
            elif z == 2:
                tgt = ['[bc]', '[de]', '[hli]', '[hld]'][p]
                m = f'ld {tgt}, a' if q == 0 else f'ld a, {tgt}'
            elif z == 3:
                m = f'inc {R16[p]}' if q == 0 else f'dec {R16[p]}'
            elif z == 4: m = f'inc {R8[y]}'
            elif z == 5: m = f'dec {R8[y]}'
            elif z == 6: m, ln = f'ld {R8[y]}, {{n8}}', 2
            else: m = ['rlca', 'rrca', 'rla', 'rra', 'daa', 'cpl', 'scf', 'ccf'][y]
        elif x == 1:
            m = 'halt' if op == 0x76 else f'ld {R8[y]}, {R8[z]}'
        elif x == 2:
            m = _alu(y, R8[z])
        else:
            if z == 0:
                if y < 4: m = f'ret {CC[y]}'
                else: m, ln = {4: ('ldh [{ldh}], a', 2), 5: ('add sp, {s8}', 2), 6: ('ldh a, [{ldh}]', 2), 7: ('ld hl, sp+{s8}', 2)}[y]
            elif z == 1:
                if q == 0: m = f'pop {R16S[p]}'
                else: m = ['ret', 'reti', 'jp hl', 'ld sp, hl'][p]
            elif z == 2:
                if y < 4: m, ln = f'jp {CC[y]}, {{a16}}', 3
                else: m, ln = {4: ('ldh [c], a', 1), 5: ('ld [{a16}], a', 3), 6: ('ldh a, [c]', 1), 7: ('ld a, [{a16}]', 3)}[y]
            elif z == 3:
                if y == 0: m, ln = 'jp {a16}', 3
                elif y == 1: m, ln = 'CB', 2
                elif y == 6: m = 'di'
                elif y == 7: m = 'ei'
            elif z == 4:
                if y < 4: m, ln = f'call {CC[y]}, {{a16}}', 3
            elif z == 5:
                if q == 0: m = f'push {R16S[p]}'
                elif p == 0: m, ln = 'call {a16}', 3
            elif z == 6: m, ln = _alu(y, '{n8}'), 2
            else: m = f'rst ${y*8:02X}'
        t[op] = (m, ln)
    return t

T = table()

def cb(op):
    x, y, z = op >> 6, (op >> 3) & 7, op & 7
    if x == 0: return f'{ROT[y]} {R8[z]}'
    return f"{['bit', 'res', 'set'][x-1]} {y}, {R8[z]}"

def decode(d, off, pc):
    """Return (len, template, value, kind) where kind in None,'n8','n16','a16','rel','ldh','s8'."""
    op = d[off]
    m, ln = T[op]
    if m is None:
        return 1, None, None, None
    if m == 'CB':
        return 2, cb(d[off+1]), None, None
    if ln == 1 or op == 0x10:
        if op == 0x10: return 2, 'stop', None, None
        return 1, m, None, None
    if '{n8}' in m: return 2, m, d[off+1], 'n8'
    if '{ldh}' in m: return 2, m, 0xFF00 | d[off+1], 'ldh'
    if '{s8}' in m:
        v = d[off+1]; v = v - 256 if v > 127 else v
        return 2, m, v, 's8'
    if '{rel}' in m:
        v = d[off+1]; v = v - 256 if v > 127 else v
        return 2, m, (pc + 2 + v) & 0xFFFF, 'rel'
    v = d[off+1] | d[off+2] << 8
    if '{n16}' in m: return 3, m, v, 'n16'
    return 3, m, v, 'a16'

def fmt(m, v, kind, labels=None):
    if kind is None: return m
    labels = labels or {}
    if kind == 'n8': return m.replace('{n8}', f'${v:02X}')
    if kind == 's8': return m.replace('{s8}', str(v))
    key = {'ldh': '{ldh}', 'rel': '{rel}', 'n16': '{n16}', 'a16': '{a16}'}[kind]
    s = labels.get(v, f'${v:04X}')
    return m.replace(key, s)

def flow(m):
    """Return ('end'|'jump'|'cond'|'call'|None)."""
    if m is None: return 'end'
    w = m.split()
    if w[0] in ('ret', 'reti') and len(w) == 1: return 'end'
    if m in ('jp hl',): return 'end'
    if w[0] in ('jp', 'jr'): return 'cond' if ',' in m else 'jump'
    if w[0] == 'ret': return 'cond'
    if w[0] == 'call': return 'call'
    if w[0] == 'rst': return 'call'
    return None
