"""usage: cmp_bank.py <asm> <orig rom> <built rom>: compares the bank range named in the asm header."""
import sys, re
hdr = open(sys.argv[1]).read(2000)
m = re.search(r'Bank \$([0-9A-F]{2}) \$4000-\$([0-9A-F]{4})', hdr)
bank, end = int(m.group(1), 16), int(m.group(2), 16)
a = open(sys.argv[2], 'rb').read(); b = open(sys.argv[3], 'rb').read()
s = bank * 0x4000; e = s + end - 0x4000 + 1
d = [i for i in range(s, e) if a[i] != b[i]]
print('bank $%02X $4000-$%04X: %s' % (bank, end, 'OK' if not d else '%d diffs, first $%04X (%02X vs %02X)' % (len(d), d[0] - s + 0x4000, a[d[0]], b[d[0]])))
sys.exit(1 if d else 0)
