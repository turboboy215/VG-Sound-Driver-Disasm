"""romcheck.py ROM file addr [file addr ...] -- compare rebuilt binaries with a ROM."""
import sys
rom = open(sys.argv[1], 'rb').read()
ok = True
for f, a in zip(sys.argv[2::2], sys.argv[3::2]):
    b = open(f, 'rb').read(); o = int(a, 16) - 0x08000000
    want = rom[o:o + len(b)]
    same = b == want or (b.rstrip(b'\0') == want.rstrip(b'\0') and len(b) - len(b.rstrip(b'\0')) <= 3)
    print(f'{f:24} {int(a, 16):08X}-{int(a, 16) + len(b):08X}  {"identical" if same else "DIFFERENT"}')
    ok &= same
sys.exit(0 if ok else 1)
