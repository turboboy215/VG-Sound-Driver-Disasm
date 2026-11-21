"""Pop Up (AJG / Bit Managers driver, version 1) data walker.

Stream format (patterns, SFX streams, instrument macros):
  $00-$5F note, $60-$7F commands (table), $80-$99 instrument, $9A-$AF SFX trigger,
  $B0-$BE arpeggio, $BF-$CE volume, $CF-$DE volume+envelope (3 args), $DF-$FF length.
"""

ROMNAME = 'Pop Up (U) [!].gb'

# command byte -> (macro name, arg kinds) ; kinds: 'b' byte, 'w' word (pointer)
CMDS = {
    0x60: ('GLIDE', 'b'),          # per-tick note step ([$15])
    0x61: ('RELEASE', 'bb'),       # at len-left = a, decay
    0x62: ('ARP_OFF', ''),
    0x63: ('SLIDE', 'bbb'),        # 16-bit step (lo, hi|sign) , count
    0x64: ('BEND', 'bbbbb'),       # start offset w, step w, count
    0x65: ('BEND_OFF', ''),
    0x66: ('VIBRATO', 'bbb'),      # delay, depth, speed
    0x67: ('VIBRATO_OFF', ''),
    0x68: ('MASK_A', ''),
    0x69: ('MASK_B', ''),
    0x6A: ('MASK_AB', ''),
    0x6B: ('WAIT', ''),
    0x6C: ('REST', ''),
    0x6D: ('STOP_ALL', ''),
    0x6E: ('CHORUS_ON', ''),
    0x6F: ('CHORUS_OFF', ''),
    0x70: ('END', ''),
    0x71: ('GLIDE_OFF', ''),
    0x72: ('TRANSPOSE', 'b'),
    0x73: ('NEXT', ''),
    0x74: ('ORDER_JUMP', 'w'),
    0x75: ('ATTEN', 'b'),
    0x76: ('LENGTH', 'b'),
    0x77: ('NOTE_OFF', ''),
    0x78: ('NOISE_HIT1', ''),
    0x79: ('PAN_C', ''),
    0x7A: ('PAN_R', ''),
    0x7B: ('PAN_L', ''),
    0x7C: ('DUTY_50', ''),
    0x7D: ('DUTY_75', ''),
    0x7E: ('DUTY_12', ''),
    0x7F: ('NOISE_HIT2', ''),
}

INSTR_TABLE = 0x5EC2   # entry (n-$7F); n = $80..$99 -> entries 1..26
ARP_TABLE = 0x5FAE     # entry n-$B0
SFX_TABLE = 0x5FD3     # entry id (id 1.. ) ; id 0 = garbage
N_SFX = 7
N_INSTR = 26
N_ARP = 15
FREQ_TABLE = 0x57AD
SONGS = [  # (name, ch1, ch2, ch3) as passed in de by the starters
    ('Title', 0x59CE, 0x5A2A, 0x59FC),
    ('Song2', 0x5E71, 0x5E6B, 0x5E65),
]


def w16(rom, a):
    return rom[a] | (rom[a + 1] << 8)


def decode_cmd(rom, a):
    """Decode one stream element at a -> (length, macro, args, kind)."""
    b = rom[a]
    if b < 0x60:
        return 1, 'NOTE', [b], 'note'
    if b < 0x80:
        name, kinds = CMDS[b]
        args = []
        p = a + 1
        for k in kinds:
            if k == 'b':
                args.append(rom[p]); p += 1
            else:
                args.append(w16(rom, p)); p += 2
        return p - a, name, args, 'cmd'
    if b < 0x9A:
        return 1, 'INSTR', [b - 0x80], 'cmd'
    if b < 0xB0:
        return 1, 'PLAY_SFX', [b - 0x9A], 'cmd'
    if b < 0xBF:
        return 1, 'ARP', [b - 0xB0], 'cmd'
    if b < 0xCF:
        return 1, 'VOL', [b - 0xBF], 'cmd'
    if b < 0xDF:
        return 4, 'VOLENV', [b - 0xCF, rom[a + 1], rom[a + 2], rom[a + 3]], 'cmd'
    return 1, 'LEN', [b - 0xDE], 'cmd'


class Walker:
    def __init__(self, rom):
        self.rom = rom
        self.items = {}      # addr -> (len, kind, payload)
        self.refs = {}       # addr -> label suggestion
        self.notes = []

    def mark(self, a, n, kind, payload=None):
        if a in self.items:
            return False
        self.items[a] = (n, kind, payload)
        return True

    def ref(self, a, name):
        self.refs.setdefault(a, name)

    def stream(self, a, ctx, name):
        """Walk a pattern / sfx stream. ctx: 'pat' | 'sfx' | 'instr'"""
        self.ref(a, name)
        rom = self.rom
        while True:
            if a in self.items:
                return
            n, m, args, k = decode_cmd(rom, a)
            self.mark(a, n, 'ev', (m, args, ctx))
            b = rom[a]
            a += n
            if ctx == 'instr' and b in (0x70, 0x73):
                return
            if b in (0x70, 0x73, 0x6D):
                return
            if b == 0x74:
                self.orders(args[0], None)
                return

    def orders(self, a, name):
        if name:
            self.ref(a, name)
        else:
            self.ref(a, 'Ord_%04X' % a)
        while True:
            if a in self.items:
                return
            p = w16(self.rom, a)
            if p == 0:
                self.mark(a, 4, 'ordend', w16(self.rom, a + 2))
                self.orders(w16(self.rom, a + 2), None)
                return
            self.mark(a, 2, 'ord', p)
            self.stream(p, 'pat', 'Pat_%04X' % p)
            a += 2

    def run(self):
        rom = self.rom
        for name, c1, c2, c3 in SONGS:
            self.orders(c1, f'{name}_Ch1')
            self.orders(c2, f'{name}_Ch2')
            self.orders(c3, f'{name}_Ch3')
        # SFX table
        self.ref(SFX_TABLE + 2, 'SfxTable')
        for i in range(1, N_SFX + 1):
            p = w16(rom, SFX_TABLE + 2 * i)
            self.mark(SFX_TABLE + 2 * i, 2, 'ptr', p)
            self.stream(p, 'sfx', 'Sfx%02X' % i)
        # instruments
        self.ref(INSTR_TABLE + 2, 'InstrTable')
        for i in range(1, N_INSTR + 1):
            p = w16(rom, INSTR_TABLE + 2 * i)
            self.mark(INSTR_TABLE + 2 * i, 2, 'ptr', p)
            self.stream(p, 'instr', 'Instr%02X' % (i - 1))
        self.ref(ARP_TABLE, 'ArpTable')
        for i in range(N_ARP):
            p = w16(rom, ARP_TABLE + 2 * i)
            self.mark(ARP_TABLE + 2 * i, 2, 'ptr', p)
            self.arp(p, 'Arp%02X' % i)
        return self

    def arp(self, a, name):
        self.ref(a, name)
        while a not in self.items:
            b = self.rom[a]
            self.mark(a, 1, 'arp', b)
            a += 1
            if b in (0x73, 0xFF):
                return


def coverage(items):
    r = []
    for a in sorted(items):
        e = a + items[a][0]
        if r and r[-1][1] >= a:
            r[-1][1] = max(r[-1][1], e)
        else:
            r.append([a, e])
    return r


if __name__ == '__main__':
    import sys
    rom = open(sys.argv[1], 'rb').read()
    w = Walker(rom).run()
    for s, e in coverage(w.items):
        print('%04X-%04X' % (s, e - 1))
