"""Recursive code tracer: returns sorted list of code instruction addresses and jump tables."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from sm83dis import decode

def trace(rom, bank, entries, jtables, lo=0x4000, hi=0x8000, extra_stop=()):
    """jtables: {addr_of_rst_insn: n_entries}  (table follows the 1-byte rst).
    returns (insn dict addr->len, tables dict addr->n)"""
    base = bank * 0x4000 - 0x4000
    m = lambda x: rom[base + x] if 0x4000 <= x < 0x8000 else rom[x]
    insn = {}; tabs = {}
    todo = list(entries)
    while todo:
        a = todo.pop()
        while lo <= a < hi and a not in insn:
            n, t, tgt = decode(m, a)
            insn[a] = n
            if a in jtables:
                cnt = jtables[a]
                ta = a + 1
                tabs[ta] = cnt
                for i in range(cnt):
                    todo.append(m(ta + 2 * i) | m(ta + 2 * i + 1) << 8)
                break
            if tgt is not None:
                todo.append(tgt)
            op = m(a)
            if op in (0xC3, 0x18, 0xC9, 0xD9, 0xE9) or a in extra_stop:
                break
            a += n
    return insn, tabs

def ranges(insn):
    out = []
    for a in sorted(insn):
        e = a + insn[a]
        if out and out[-1][1] == a:
            out[-1][1] = e
        else:
            out.append([a, e])
    return [tuple(x) for x in out]
