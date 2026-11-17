"""Parser for the Realtime Associates (David Warhol) Game Boy sound driver data.

Used by Zoop (U) and Star Wars - Super Return of the Jedi (U).
"""

GAMES = {
    'zoop': dict(rom='Zoop (U) [!].gb', banks=[3]),
    'srotj': dict(rom='Star Wars - Super Return of the Jedi (U) [S][!].gb', banks=[4, 5]),
}


class Bank:
    def __init__(self, data, bank):
        self.d = data
        self.bank = bank
        self.base = bank * 0x4000 - 0x4000 if bank else 0

    def b(self, a):
        return self.d[self.base + a]

    def w(self, a):
        return self.b(a) | self.b(a + 1) << 8

    def find_tables(self):
        """Read the table addresses from the driver code's ld hl,nnnn operands."""
        ops = []
        for a in range(0x4001, 0x4440):
            if self.b(a) == 0x21:
                ops.append(self.w(a + 1))
        # order in the code: attack, slotofs, release, slotofs, regbase, patches,
        # periods, waves, songs, songs ($5F1A is a false hit inside 'ldh [rNR42], a / ld e, a')
        hl = [v for v in ops if 0x4300 <= v < 0x8000 and v != 0x5F1A]
        t = dict(Attack=hl[0], SlotOfs=hl[1], Release=hl[2], RegBase=hl[4],
                 Patches=hl[5], Periods=hl[6], Waves=hl[7], Sounds=hl[8])
        return t

    def sound_table(self, addr):
        ptrs = []
        a = addr
        lo = 0x10000
        while a < lo:
            p = self.w(a)
            ptrs.append(p)
            lo = min(lo, p)
            a += 2
        return ptrs


def parse_song(bk, addr):
    """Return dict(n, chan, note, events, end) ; events = list of (addr, kind, args)."""
    n = bk.b(addr)
    chan = [bk.b(addr + 1 + i) for i in range(n)]
    note = [bk.b(addr + 1 + n + i) for i in range(n)]
    a = addr + 1 + 2 * n
    ev = []
    while True:
        c = bk.b(a)
        if c == 0xFE:
            ev.append((a, 'goto', [bk.b(a + 1)]))
            a += 2
            break
        if c == 0xFF:
            ev.append((a, 'end', []))
            a += 1
            break
        if c < n:
            ev.append((a, 'note', [c]))
            a += 1
        elif c < n + 16:
            ev.append((a, 'off', [c - n]))
            a += 1
        elif c < n + 32:
            ev.append((a, 'prog', [c - n - 16, bk.b(a + 1)]))
            a += 2
        else:
            ev.append((a, 'wait', [c - n - 32]))
            a += 1
    return dict(addr=addr, n=n, chan=chan, note=note, start=addr + 1 + 2 * n,
                events=ev, end=a)


def parse_sfx(bk, addr, stop=None):
    """SFX stream.  Follows the stream linearly; a $FE jump ends the linear block
    and its target is returned so the caller can parse it too."""
    ev = []
    a = addr
    targets = []
    while True:
        if stop is not None and a >= stop and ev:
            break
        c = bk.b(a)
        if c == 0x00:
            ev.append((a, 'sq1', [bk.b(a + i) for i in range(1, 6)]))
            a += 6
        elif c == 0x01:
            ev.append((a, 'sq2', [bk.b(a + i) for i in range(1, 5)]))
            a += 5
        elif c == 0x02:
            ev.append((a, 'wav', []))
            a += 1
        elif c == 0x03:
            ev.append((a, 'noi', [bk.b(a + i) for i in range(1, 5)]))
            a += 5
        elif c == 0xFE:
            t = bk.w(a + 1)
            ev.append((a, 'jump', [t]))
            targets.append(t)
            a += 3
            break
        elif c == 0xFF:
            ev.append((a, 'rand', [bk.b(a + 1), bk.b(a + 2)]))
            a += 3
        elif c == 0x04:
            ev.append((a, 'end', []))
            a += 1
            break
        else:
            ev.append((a, 'wait', [c - 4]))
            a += 1
    return dict(addr=addr, events=ev, end=a, targets=targets)
