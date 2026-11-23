import sys
sys.path.insert(0, __file__.rsplit('/', 1)[0])
from sm83 import decode, fmt


def mkread(rom, bank):
    def rd(a):
        if a < 0x4000:
            return rom[a]
        if a < 0x8000:
            return rom[bank * 0x4000 + a - 0x4000]
        return 0
    return rd


def trace(rom, bank, starts, stop_at=None, jptables=()):
    """Follow code from starts. Returns dict addr->(len,text,kind,val), and set of call/jump targets"""
    rd = mkread(rom, bank)
    code = {}
    targets = set(starts)
    work = list(starts)
    while work:
        pc = work.pop()
        while pc not in code and pc < 0x8000:
            if stop_at and pc in stop_at and pc not in starts:
                pass
            ln, text, kind, val = decode(rd, pc)
            code[pc] = (ln, text, kind, val)
            if kind in ('jp', 'call', 'rel'):
                if val < 0x8000:
                    targets.add(val)
                    work.append(val)
            if text in ('ret', 'reti', 'jp hl') or (text.startswith(('jp {', 'jr {'))) or text.startswith('db $'):
                break
            pc += ln
    return code, targets


def listing(rom, bank, code, targets, lo=0, hi=0x8000):
    rd = mkread(rom, bank)
    out = []
    for a in sorted(code):
        if not lo <= a < hi:
            continue
        ln, text, kind, val = code[a]
        if a in targets:
            out.append(f'L{a:04X}:')
        b = ' '.join(f'{rd(a+i):02X}' for i in range(ln))
        out.append(f'  {a:04X}  {b:<9} {fmt(text, kind, val)}')
    return '\n'.join(out)


if __name__ == '__main__':
    rom = open(sys.argv[1], 'rb').read()
    bank = int(sys.argv[2], 16)
    starts = [int(x, 16) for x in sys.argv[3:]]
    code, t = trace(rom, bank, starts)
    print(listing(rom, bank, code, t))
