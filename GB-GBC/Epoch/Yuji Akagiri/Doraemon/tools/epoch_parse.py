"""Walks the Epoch driver's tables and tracks and reports the structure."""
import sys
from epoch_cfg import load

NOTE = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']


def note_name(n):
    s = n - 0x10
    if s < 0:
        return f'?{n:02X}'
    return f'{NOTE[s % 12]}{2 + s // 12}'


def table_count(g, tab, first_target):
    """number of words from tab up to first_target (the lowest pointer)."""
    return (first_target - tab) // 2


def parse(g):
    w, b = g['w'], g['b']
    res = {}
    # --- instrument pointer table: runs until the first instrument entry
    ptrs = []
    a = g['inst']
    lo = 0x10000
    while a < lo:
        p = w(a)
        ptrs.append(p)
        if p:
            lo = min(lo, p)
        a += 2
    res['inst_ptrs'] = ptrs
    insts = {}
    for p in sorted(set(x for x in ptrs if x)):
        regs = list(g['rd'](p, 5))
        mode = b(p + 5)
        if mode == 0:
            par = []
        elif mode == 1:
            par = list(g['rd'](p + 6, 1 + g['volsteps']))
        else:
            par = [b(p + 6)]
        insts[p] = (regs, mode, par)
    res['insts'] = insts
    # --- song tables
    for kind, tab in (('music', g['music']), ('sfx', g['sfx'])):
        ptrs = []
        a = tab
        lo = 0x10000
        while a < lo:
            p = w(a)
            ptrs.append(p)
            lo = min(lo, p)
            a += 2
        res[kind] = ptrs
        hdrs = {}
        nch = 4 if kind == 'music' else 2
        for p in sorted(set(ptrs)):
            tempo = b(p)
            lt = w(p + 1)
            ch = [w(p + 3 + 2 * i) for i in range(nch)]
            hdrs[p] = (tempo, lt, ch)
        res[kind + '_hdrs'] = hdrs
    return res


def walk(g, ptr, noise, stop_at=None):
    """Return list of (addr, bytes, text) rows until end of the track."""
    b = g['b']
    a = ptr
    rows = []
    depth = 0
    cur = None
    while True:
        c = b(a)
        if c == 0xFF:
            rows.append((a, [c], 'end'))
            return rows, a + 1
        if c == 0xFE and g['ver'] == 2:
            rows.append((a, [c], 'restart'))
            return rows, a + 1
        if c == 0xF0:
            rows.append((a, [c, b(a + 1)], f'instrument {b(a+1)}'))
            a += 2
            continue
        if c == 0xE0:
            depth += 1
            n = b(a + 1)
            rows.append((a, [c, n], f'loop start x{n}'))
            a += 2
            continue
        if c == 0xE1:
            depth -= 1
            rows.append((a, [c], 'loop end'))
            a += 1
            if depth < 0 or (stop_at and a >= stop_at):
                return rows, a
            continue
        if c == 0xE2:
            rows.append((a, [c, b(a + 1)], f'pass {b(a+1)}'))
            a += 2
            continue
        if c >= 0xE0:
            rows.append((a, [c, b(a + 1)], f'cmd {c:02X} (NR51)'))
            a += 2
            continue
        hi, lo = c >> 4, c & 15
        bs = [c]
        if hi == 0xD:
            bs += [b(a + 1), b(a + 2)]
            ln = f'len ${b(a+1) | b(a+2) << 8:04X}'
        else:
            ln = f'len#{hi}'
        if lo == 9:
            t = 'tie'
        elif lo == 8:
            t = 'rest'
        elif lo == 6:
            n = b(a + len(bs))
            bs.append(n)
            cur = n
            t = f'note {n:02X}'
        else:
            d = lo if lo < 8 else lo - 16
            if cur is not None:
                cur = (cur + d) & 0xFF
            t = f'{d:+d}' + (f' -> {cur:02X}' if cur is not None else '')
        rows.append((a, bs, f'{ln} {t}'))
        a += len(bs)
        if stop_at and a >= stop_at:
            return rows, a


if __name__ == '__main__':
    g = load(sys.argv[1])
    r = parse(g)
    print('inst ptrs', [f'{p:04X}' for p in r['inst_ptrs']])
    for p, (regs, m, par) in r['insts'].items():
        print(f'  inst {p:04X}: {bytes(regs).hex(" ")} mode {m} {bytes(par).hex(" ")}')
    for kind in ('music', 'sfx'):
        print(kind, len(r[kind]), [f'{p:04X}' for p in r[kind]])
        for p, (t, lt, ch) in r[kind + '_hdrs'].items():
            print(f'  hdr {p:04X}: tempo {t:02X} lentab {lt:04X} ch {[f"{c:04X}" for c in ch]}')
