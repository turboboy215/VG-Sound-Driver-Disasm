import sys
sys.path.insert(0, __file__.rsplit('/', 1)[0])
from sm83 import decode, fmt


def dis(rom, start, end):
    a = start
    out = []
    while a < end:
        n, t, v, f = decode(rom, a)
        out.append(f'{a:04X}: {rom[a:a+n].hex(" "):9s} {fmt(t, v)}')
        a += n
    return '\n'.join(out)


if __name__ == '__main__':
    rom = open(sys.argv[1], 'rb').read()
    print(dis(rom, int(sys.argv[2], 16), int(sys.argv[3], 16)))
