"""Compare address ranges of two 32 KB ROMs.  usage: cmp_ranges.py built.gb orig.gb 0050-0052 50A0-6059 ..."""
import sys
a = open(sys.argv[1], 'rb').read()
b = open(sys.argv[2], 'rb').read()
bad = 0
for r in sys.argv[3:]:
    s, e = (int(x, 16) for x in r.split('-'))
    diffs = [i for i in range(s, e + 1) if a[i] != b[i]]
    print('%04X-%04X: %s' % (s, e, 'OK' if not diffs else '%d diffs, first at %04X' % (len(diffs), diffs[0])))
    bad += len(diffs)
sys.exit(1 if bad else 0)
