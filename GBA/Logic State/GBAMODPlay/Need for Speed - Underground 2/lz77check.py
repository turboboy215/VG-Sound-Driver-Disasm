"""lz77check.py packed.lz source.bin [...] -- unpack BIOS LZ77 images and compare."""
import sys
def unlz(d):
    assert d[0] == 0x10
    n = d[1] | d[2] << 8 | d[3] << 16; out = bytearray(); p = 4
    while len(out) < n:
        f = d[p]; p += 1
        for bit in range(8):
            if len(out) >= n: break
            if f & (0x80 >> bit):
                b1, b2 = d[p], d[p + 1]; p += 2
                for _ in range((b1 >> 4) + 3): out.append(out[-(((b1 & 15) << 8 | b2) + 1)])
            else: out.append(d[p]); p += 1
    return bytes(out)
ok = True
for lz, bin_ in zip(sys.argv[1::2], sys.argv[2::2]):
    a = unlz(open(lz, 'rb').read()); b = open(bin_, 'rb').read()
    same = b[:len(a)] == a and not any(b[len(a):])
    print(f'{bin_:28} {"identical to unpacked " + lz if same else "DIFFERENT"}'); ok &= same
sys.exit(0 if ok else 1)
