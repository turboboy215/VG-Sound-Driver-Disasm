"""Minimal SM83 (Game Boy CPU) disassembler producing RGBDS syntax."""

R8 = ['b', 'c', 'd', 'e', 'h', 'l', '[hl]', 'a']
R16 = ['bc', 'de', 'hl', 'sp']
R16S = ['bc', 'de', 'hl', 'af']
CC = ['nz', 'z', 'nc', 'c']
ALU = ['add a, ', 'adc a, ', 'sub ', 'sbc a, ', 'and ', 'xor ', 'or ', 'cp ']
ROT = ['rlc', 'rrc', 'rl', 'rr', 'sla', 'sra', 'swap', 'srl']


def build():
    t = {}
    # (mnemonic template, length, kind)  kind: None, 'jr', 'jp', 'call', 'ret', 'jpend', 'rst'
    t[0x00] = ('nop', 1, None)
    t[0x08] = ('ld [{w}], sp', 3, None)
    t[0x10] = ('stop', 2, None)
    t[0x18] = ('jr {r}', 2, 'jrend')
    for i, c in enumerate(CC):
        t[0x20 + i * 8] = ('jr %s, {r}' % c, 2, 'jr')
    for i, r in enumerate(R16):
        t[0x01 + i * 16] = ('ld %s, {w}' % r, 3, None)
        t[0x09 + i * 16] = ('add hl, %s' % r, 1, None)
        t[0x03 + i * 16] = ('inc %s' % r, 1, None)
        t[0x0B + i * 16] = ('dec %s' % r, 1, None)
    t[0x02] = ('ld [bc], a', 1, None)
    t[0x12] = ('ld [de], a', 1, None)
    t[0x22] = ('ld [hli], a', 1, None)
    t[0x32] = ('ld [hld], a', 1, None)
    t[0x0A] = ('ld a, [bc]', 1, None)
    t[0x1A] = ('ld a, [de]', 1, None)
    t[0x2A] = ('ld a, [hli]', 1, None)
    t[0x3A] = ('ld a, [hld]', 1, None)
    for i, r in enumerate(R8):
        t[0x04 + i * 8] = ('inc %s' % r, 1, None)
        t[0x05 + i * 8] = ('dec %s' % r, 1, None)
        t[0x06 + i * 8] = ('ld %s, {b}' % r, 2, None)
    for i, m in enumerate(['rlca', 'rrca', 'rla', 'rra', 'daa', 'cpl', 'scf', 'ccf']):
        t[0x07 + i * 8] = (m, 1, None)
    for d in range(8):
        for s in range(8):
            op = 0x40 + d * 8 + s
            if op == 0x76:
                t[op] = ('halt', 1, None)
            else:
                t[op] = ('ld %s, %s' % (R8[d], R8[s]), 1, None)
    for i, a in enumerate(ALU):
        for s in range(8):
            t[0x80 + i * 8 + s] = (a + R8[s], 1, None)
        t[0xC6 + i * 8] = (a + '{b}', 2, None)
    for i, c in enumerate(CC):
        t[0xC0 + i * 8] = ('ret %s' % c, 1, None)
        t[0xC2 + i * 8] = ('jp %s, {w}' % c, 3, 'jp')
        t[0xC4 + i * 8] = ('call %s, {w}' % c, 3, 'call')
    for i, r in enumerate(R16S):
        t[0xC1 + i * 16] = ('pop %s' % r, 1, None)
        t[0xC5 + i * 16] = ('push %s' % r, 1, None)
    t[0xC3] = ('jp {w}', 3, 'jpend')
    t[0xC9] = ('ret', 1, 'end')
    t[0xD9] = ('reti', 1, 'end')
    t[0xCD] = ('call {w}', 3, 'call')
    for i in range(8):
        t[0xC7 + i * 8] = ('rst ${:02X}'.format(i * 8), 1, 'rst')
    t[0xE0] = ('ldh [{h}], a', 2, None)
    t[0xF0] = ('ldh a, [{h}]', 2, None)
    t[0xE2] = ('ldh [c], a', 1, None)
    t[0xF2] = ('ldh a, [c]', 1, None)
    t[0xE8] = ('add sp, {s}', 2, None)
    t[0xF8] = ('ld hl, sp{s+}', 2, None)
    t[0xE9] = ('jp hl', 1, 'end')
    t[0xF9] = ('ld sp, hl', 1, None)
    t[0xEA] = ('ld [{w}], a', 3, None)
    t[0xFA] = ('ld a, [{w}]', 3, None)
    t[0xF3] = ('di', 1, None)
    t[0xFB] = ('ei', 1, None)
    t[0xCB] = ('CB', 2, None)
    return t


OPS = build()


def cb(op):
    r = R8[op & 7]
    if op < 0x40:
        return '%s %s' % (ROT[op >> 3], r)
    n = (op >> 3) & 7
    return '%s %d, %s' % (['bit', 'res', 'set'][(op >> 6) - 1], n, r)


def decode(mem, pc, label=None):
    """mem(addr)->byte.  Returns (length, text, kind, target)."""
    op = mem(pc)
    if op not in OPS:
        return 1, 'db ${:02X} ; invalid'.format(op), 'end', None
    tmpl, ln, kind = OPS[op]
    target = None
    if op == 0xCB:
        return 2, cb(mem(pc + 1)), None, None
    txt = tmpl
    if '{w}' in txt:
        w = mem(pc + 1) | mem(pc + 2) << 8
        if kind in ('jp', 'jpend', 'call'):
            target = w
        txt = txt.replace('{w}', label(w, kind) if label else '${:04X}'.format(w))
    if '{b}' in txt:
        txt = txt.replace('{b}', '${:02X}'.format(mem(pc + 1)))
    if '{h}' in txt:
        a = 0xFF00 | mem(pc + 1)
        txt = txt.replace('{h}', label(a, 'h') if label else '${:04X}'.format(a))
    if '{r}' in txt:
        o = mem(pc + 1)
        o = o - 256 if o > 127 else o
        target = (pc + 2 + o) & 0xFFFF
        txt = txt.replace('{r}', label(target, 'jr') if label else '${:04X}'.format(target))
    if '{s}' in txt:
        o = mem(pc + 1)
        o = o - 256 if o > 127 else o
        txt = txt.replace('{s}', str(o))
    if '{s+}' in txt:
        o = mem(pc + 1)
        o = o - 256 if o > 127 else o
        txt = txt.replace('{s+}', ' + %d' % o if o >= 0 else ' - %d' % -o)
    return ln, txt, kind, target
