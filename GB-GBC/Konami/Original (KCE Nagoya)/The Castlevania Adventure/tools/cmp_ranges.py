"""cmp_ranges.py built.gb original.gb bank:start-end ... -> byte compare"""
import sys
a = open(sys.argv[1], 'rb').read(); b = open(sys.argv[2], 'rb').read()
ok = True
for r in sys.argv[3:]:
    bk, rg = r.split(':'); s, e = (int(x, 16) for x in rg.split('-')); bk = int(bk, 16)
    o = lambda x: x if bk == 0 or x < 0x4000 else bk * 0x4000 + x - 0x4000
    bad = [x for x in range(s, e + 1) if o(x) >= len(a) or a[o(x)] != b[o(x)]]
    print(f'{bk:X}:{s:04X}-{e:04X}', 'OK' if not bad else f'{len(bad)} diffs, first {bad[0]:04X}')
    ok &= not bad
sys.exit(0 if ok else 1)
