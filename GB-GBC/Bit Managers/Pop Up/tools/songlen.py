"""Static intro+loop lengths (ticks) per channel.  usage: songlen.py popup|bombjack <rom>"""
import sys
sys.path.insert(0, __file__.rsplit('/', 1)[0])
game = sys.argv[1]
if game == 'popup':
    import popup_data as D
    rom = open(sys.argv[2], 'rb').read()
    LEN0, LENN = 0xDF, 0xDE
    CONSUME = {0x6B, 0x6C, 0x77}
    END = {0x70, 0x6D}
    NEXT, OJ, LENGTH = 0x73, 0x74, 0x76
    INSTR_LO, INSTR_HI = 0x80, 0x9A
    def instr_ptr(b, tabs):
        return D.w16(rom, 0x5EC2 + 2 * (b - 0x7F))
    IEND = {0x70, 0x73}
else:
    import bombjack_data as D
    rom = open(sys.argv[2], 'rb').read()
    LEN0, LENN = 0xC7, 0xC6
    CONSUME = {0x61, 0x63, 0x64}
    END = {0x66, 0x65}
    NEXT, OJ, LENGTH = 0x68, 0x69, 0x6A
    INSTR_LO, INSTR_HI = 0x7E, 0x98
    def instr_ptr(b, tabs):
        return D.w16(rom, tabs + 2 * (b - 0x7D))
    IEND = {0x66, 0x68}


def chan(order, tabs=None):
    pos = order
    length = 1
    t = 0
    seen = {}
    ret = None
    while True:
        if pos in seen:
            return seen[pos], t - seen[pos], 'loop'
        seen[pos] = t
        p = D.w16(rom, pos)
        pos += 2
        if p == 0:
            pos = D.w16(rom, pos)
            continue
        a = p
        while True:
            n, m, args = D.decode_cmd(rom, a)[:3]
            b = rom[a]
            a += n
            if b < 0x60:
                t += length
            elif b >= LEN0:
                length = b - LENN
            elif b == LENGTH:
                length = args[0]
            elif b in CONSUME:
                t += length
            elif INSTR_LO <= b < INSTR_HI:
                ip = instr_ptr(b, tabs)
                while rom[ip] not in IEND:
                    nn, mm, aa = D.decode_cmd(rom, ip)[:3]
                    if rom[ip] >= LEN0:
                        length = rom[ip] - LENN
                    elif rom[ip] == LENGTH:
                        length = aa[0]
                    ip += nn
            elif game == 'popup' and 0x9A <= b < 0xB0:
                t += length
            elif b in END:
                return t, 0, 'end'
            elif b == NEXT:
                if ret is not None:
                    a, ret = ret, None
                    continue
                break
            elif b == OJ:
                pos = args[0]
                break
            elif game != 'popup' and b == 0x79:
                a = args[0]
            elif game != 'popup' and b == 0x7A:
                ret, a = a, args[0]


if game == 'popup':
    for name, c1, c2, c3 in D.SONGS:
        print(name, [chan(o) for o in (c1, c2, c3)])
    for i in range(1, 8):
        print('Sfx%d' % i)
else:
    for name, r, (o6, o4, o5), it, at in D.SONGS:
        print(name, [chan(o, it) for o in (o4, o5, o6)])
