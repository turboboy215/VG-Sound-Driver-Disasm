import sys
rom = open(sys.argv[1], 'rb').read()
ok = True
for path, start in ((sys.argv[2], 0x0805B564), (sys.argv[3], 0x080C2044)):
    b = open(path, 'rb').read()
    r = rom[start - 0x08000000: start - 0x08000000 + len(b)]
    diff = [i for i in range(len(b)) if b[i] != r[i]]
    print(f'{path}: {len(b)} bytes at 0x{start:08X}, {len(diff)} differences')
    for i in diff[:20]:
        print(f'  0x{start+i:08X}: built {b[i]:02X} rom {r[i]:02X}')
    ok &= not diff
sys.exit(0 if ok else 1)
