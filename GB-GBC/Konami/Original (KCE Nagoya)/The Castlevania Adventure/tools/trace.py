"""Recursive-descent code tracer. trace.py rom bank entry,entry,... [--jt addr ...]
Handles 'call JT' where JT pops hl and indexes an inline word table following the call
(pass JT routine addresses with --jtfn). Prints code ranges and a listing."""
import sys, argparse
sys.path.insert(0, __file__.rsplit('/', 1)[0])
from sm83 import decode, rommem

ap = argparse.ArgumentParser()
ap.add_argument('rom'); ap.add_argument('bank'); ap.add_argument('entries')
ap.add_argument('--jtfn', default='')      # inline jumptable routines
ap.add_argument('--jt', default='')
ap.add_argument('--inl', default='')  # addr:count inline tables after call        # addr:count explicit jump tables
ap.add_argument('--lo', default='0'); ap.add_argument('--hi', default='8000')
ap.add_argument('--list', action='store_true')
a = ap.parse_args()
rom = open(a.rom, 'rb').read()
bank = int(a.bank, 16)
m = rommem(rom, bank)
lo, hi = int(a.lo, 16), int(a.hi, 16)
jtfn = {int(x, 16) for x in a.jtfn.split(',') if x}
inl = {int(x.split(':')[0],16): int(x.split(':')[1]) for x in a.inl.split(',') if x}
todo = [int(x, 16) for x in a.entries.split(',')]
code = {}
data = {}
for t in a.jt.split(','):
    if t:
        ad, n = t.split(':'); ad = int(ad, 16)
        for i in range(int(n)):
            data[ad + 2*i] = 2
            todo.append(m(ad+2*i) | m(ad+2*i+1) << 8)
labels = set(todo)
outside = set()
while todo:
    pc = todo.pop()
    while True:
        if pc in code: break
        if not (lo <= pc < hi):
            outside.add(pc); break
        l, t, tg = decode(m, pc)
        code[pc] = (l, t)
        op = m(pc)
        if tg is not None and not t.startswith('rst'):
            labels.add(tg)
            if tg in jtfn and t.startswith('call'):
                # inline table: entries until a non-plausible word
                p = pc + 3; n = 0
                while True:
                    wv = m(p) | m(p+1) << 8
                    if (pc+3) in inl:
                        if n >= inl[pc+3]: break
                    elif not (lo <= wv < hi) or p in code: break
                    data[p] = 2; todo.append(wv); labels.add(wv); p += 2; n += 1
                print(f'; inline JT at {pc+3:04X}: {n} entries', file=sys.stderr)
                break
            todo.append(tg)
        if op in (0xC3, 0x18, 0xC9, 0xD9, 0xE9): break
        pc += l
rng = []
for ad in sorted(code):
    e = ad + code[ad][0]
    if rng and rng[-1][1] == ad: rng[-1][1] = e
    else: rng.append([ad, e])
for s, e in rng: print(f'code {s:04X}-{e-1:04X}')
print('outside:', ' '.join(f'{x:04X}' for x in sorted(outside)))
if a.list:
    for ad in sorted(code):
        l, t = code[ad]
        lab = f'L{ad:04X}:' if ad in labels else ''
        print(f'{lab:<7}{ad:04X} {" ".join(f"{m(ad+i):02X}" for i in range(l)):<9} {t}')
