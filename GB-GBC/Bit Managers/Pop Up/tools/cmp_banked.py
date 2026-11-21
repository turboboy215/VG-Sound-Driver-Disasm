"""Compare ranges of two (banked) ROMs.  usage: cmp_banked.py built.gb orig.gb 0000-0002 3:4A8C-7F1A ...
A range without a bank prefix is in bank 0 (or the file offset for $4000-$7FFF of a 32 KB ROM)."""
import sys
a = open(sys.argv[1], 'rb').read()
b = open(sys.argv[2], 'rb').read()
bad = 0
for r in sys.argv[3:]:
    bank = 0
    if ':' in r:
        bank, r = r.split(':')
        bank = int(bank)
    s, e = (int(x, 16) for x in r.split('-'))
    off = bank * 0x4000 - 0x4000 if bank else 0
    diffs = [i for i in range(s, e + 1) if a[off + i] != b[off + i]]
    print('%s%04X-%04X: %s' % ('%d:' % bank if bank else '', s, e, 'OK' if not diffs else '%d diffs, first at %04X' % (len(diffs), diffs[0])))
    bad += len(diffs)
sys.exit(1 if bad else 0)
