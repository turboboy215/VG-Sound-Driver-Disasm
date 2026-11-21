"""Recursive code tracer for 32 KB GB ROMs.

trace(rom, entries) -> (code: dict addr->len, xrefs: dict tgt->set(src), jphl: list)
"""
import sys
sys.path.insert(0, __file__.rsplit('/', 1)[0])
from sm83 import decode


def trace(rom, entries, stop=()):
    code = {}
    xrefs = {}
    jphl = []
    work = list(entries)
    while work:
        a = work.pop()
        while True:
            if a in code or a >= 0x8000 or a in stop:
                break
            n, t, v, f = decode(rom, a)
            code[a] = n
            if f is None:
                a += n
                continue
            k = f[0]
            if k in ('jp', 'jr'):
                xrefs.setdefault(f[1], set()).add(a)
                work.append(f[1])
                break
            if k in ('jpc', 'jrc', 'call', 'callc', 'rst'):
                xrefs.setdefault(f[1], set()).add(a)
                work.append(f[1])
                a += n
                continue
            if k == 'retc':
                a += n
                continue
            if k == 'jphl':
                jphl.append(a)
            break
    return code, xrefs, jphl
