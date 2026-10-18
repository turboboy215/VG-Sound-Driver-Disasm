"""Quick listing: python3 dis.py rom bank start [end|+n]  (linear) ; -t for trace from start"""
import sys
sys.path.insert(0, __file__.rsplit('/', 1)[0])
from sm83 import decode


def mk(rom, bank):
    def mem(a):
        if a < 0x4000: return rom[a]
        if a < 0x8000: return rom[bank * 0x4000 + a - 0x4000]
        return 0
    return mem


def listing(rom, bank, start, end):
    mem = mk(rom, bank)
    pc = start
    while pc < end:
        i = decode(mem, pc)
        bs = ' '.join('%02X' % mem(pc + k) for k in range(i.size if i else 1))
        if i is None:
            print('%02X:%04X  %-9s db' % (bank, pc, bs)); pc += 1; continue
        t = (' ; -> %04X' % i.target) if i.target is not None and i.kind in ('jr',) else ''
        print('%02X:%04X  %-9s %s %s%s%s' % (bank, pc, bs, i.mn, i.ops,
              ('%04X' % i.target if i.kind in ('jp', 'call', 'jr') and i.ops != 'hl' else ''), ''))
        pc += i.size
        if i.ends: print()


if __name__ == '__main__':
    rom = open(sys.argv[1], 'rb').read()
    bank = int(sys.argv[2], 16)
    s = int(sys.argv[3], 16)
    e = sys.argv[4]
    e = s + int(e[1:], 16) if e.startswith('+') else int(e, 16)
    listing(rom, bank, s, e)
