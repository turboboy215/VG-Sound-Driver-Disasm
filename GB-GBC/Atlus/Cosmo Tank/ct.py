"""Cosmo Tank (Atlus, Tsukasa Masuko) sound data parser. Bank 4."""
BANK = 4
SOUND_TABLE = 0x450E
NUM_SOUNDS = 36
PERIODS = 0x4466
LENTAB = 0x4556
ENVTAB = 0x4596
REGTAB = 0x5A7C
PANTAB = 0x5A8C

# command byte (low nibble of $E0-$FF; the data uses $F0-$FF) -> (name, nargs)
CMDS = {
    0x0: ('env', 1), 0x1: ('duty', 1), 0x2: ('atten', 1), 0x3: ('transpose', 1),
    0x4: ('loop_start', 1), 0x5: ('loop_end', 0), 0x6: ('call', 2), 0x7: ('ret', 0),
    0x8: ('jump', 2), 0x9: ('fine', 1), 0xA: ('sweep', 1), 0xB: ('sweep_off', 0),
    0xC: ('wave', 2), 0xD: ('end_d', 0), 0xE: ('nop', 0), 0xF: ('end', 0),
}


class Rom:
    def __init__(self, path):
        self.d = open(path, 'rb').read()

    def b(self, a):
        return self.d[BANK * 0x4000 + a - 0x4000]

    def w(self, a):
        return self.b(a) | (self.b(a + 1) << 8)

    def bytes(self, a, n):
        o = BANK * 0x4000 + a - 0x4000
        return self.d[o:o + n]


def headers(rom):
    """-> list of (id, addr, [(track, ptr), ...])"""
    out = []
    for i in range(NUM_SOUNDS):
        a = rom.w(SOUND_TABLE + 2 * i)
        tr = []
        p = a
        while rom.b(p) != 0xFF:
            tr.append((rom.b(p), rom.w(p + 1)))
            p += 3
        out.append((i, a, tr))
    return out


def decode_stream(rom, start, track):
    """Static decode of one track stream, following jumps/calls.
    Returns dict addr -> (length, kind, args) for each event, and set of call/jump targets."""
    ev = {}
    labels = set([start])
    todo = [start]
    while todo:
        p = todo.pop()
        while p not in ev:
            c = rom.b(p)
            if c < 0x80:
                ev[p] = (1, 'rest' if c == 0x54 else 'note', (c,))
                p += 1
                continue
            if c < 0xC0:
                ev[p] = (1, 'len', (c & 0x3F,))
                p += 1
                continue
            if c < 0xE0:
                ev[p] = (1, 'pan', (c & 0x1F,))
                p += 1
                continue
            name, n = CMDS[c & 0x0F]
            args = tuple(rom.bytes(p + 1, n))
            ev[p] = (1 + n, name, args)
            if name in ('call', 'jump', 'wave'):
                t = args[0] | (args[1] << 8)
                if name != 'wave':
                    labels.add(t)
                    todo.append(t)
            if name in ('jump', 'end', 'end_d', 'ret'):
                break
            p += 1 + n
    return ev, labels
