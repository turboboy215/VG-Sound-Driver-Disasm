"""Quick flow-tracing disassembly listing for exploration.
usage: python da.py rom bank start_addr [start_addr...]   (addresses hex, banked $4000-$7FFF)
"""
import sys
sys.path.insert(0, __import__('os').path.dirname(__file__))
from sm83 import disasm


def trace(rom, bank, starts, lo=0x4000, hi=0x8000):
    base = bank * 0x4000 - 0x4000 if bank else 0
    seen = {}
    todo = list(starts)
    labels = set(starts)
    while todo:
        a = todo.pop()
        while lo <= a < hi and a not in seen:
            n, t, info = disasm(rom, base + a, a)
            seen[a] = (n, t)
            if info['target'] is not None and info['kind'] in ('jp', 'jr', 'call') and lo <= info['target'] < hi:
                labels.add(info['target'])
                todo.append(info['target'])
            if info['kind'] in ('ret', 'reti', 'jphl') and not info['cond']:
                break
            if info['kind'] in ('jp', 'jr') and not info['cond']:
                break
            a += n
    return seen, labels


if __name__ == '__main__':
    rom = open(sys.argv[1], 'rb').read()
    bank = int(sys.argv[2], 16)
    starts = [int(x, 16) for x in sys.argv[3:]]
    seen, labels = trace(rom, bank, starts)
    base = bank * 0x4000 - 0x4000 if bank else 0
    prev = None
    for a in sorted(seen):
        if prev is not None and a != prev:
            print('        ; ---- gap %04X-%04X' % (prev, a - 1))
        n, t = seen[a]
        lab = 'L%04X:' % a if a in labels else ''
        print('%-7s %04X  %-12s %s' % (lab, a, rom[base + a:base + a + n].hex(' '), t))
        prev = a + n
