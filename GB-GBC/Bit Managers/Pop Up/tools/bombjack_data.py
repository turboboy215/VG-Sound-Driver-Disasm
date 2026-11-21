"""Bomb Jack (AJG / Bit Managers driver, version 2) data walker.

Stream format:
  $00-$5F note, $60-$7D commands (table), $7E-$97 instrument (per-song table),
  $98-$A6 arpeggio (per-song table), $A7-$B6 volume, $B7-$C6 volume+envelope (3 args),
  $C7-$FF length 1-57.
"""

ROMNAME = 'Bomb Jack (U).gb'

# byte -> (macro, argspec). argspec: string of 'b'/'w', or a callable(rom, a) -> kinds
CMDS = {
    0x60: ('GLIDE', 'b'),
    0x61: ('WAIT2', ''),          # same as WAIT ($63)
    0x62: ('VIBRATO', 'bbb'),     # delay, depth, speed
    0x63: ('WAIT', ''),
    0x64: ('REST', ''),
    0x65: ('STOP_ALL', ''),
    0x66: ('END', ''),
    0x67: ('TRANSPOSE', 'b'),     # global (music only)
    0x68: ('NEXT', ''),           # next pattern / return from PAT_CALL
    0x69: ('ORDER_JUMP', 'w'),
    0x6A: ('LENGTH', 'b'),
    0x6B: ('DRUMS', None),        # 0 = off | tempo, pattern(w)
    0x6C: ('PAN_C', ''),
    0x6D: ('PAN_R', ''),
    0x6E: ('PAN_L', ''),
    0x6F: ('DUTY_50', ''),
    0x70: ('DUTY_75', ''),
    0x71: ('DUTY_12', ''),
    0x72: ('HWENV', None),        # env | env, 0 | env, ticks, env2
    0x73: ('AUTOPAN', 'b'),
    0x74: ('AUTODUTY', 'b'),
    0x75: ('WAVE', 'w'),
    0x76: ('CH_TRANSPOSE', 'b'),
    0x77: ('RELEASE', None),      # 0 = off | ticks-left, env
    0x78: ('ARP_OFF', ''),
    0x79: ('PAT_GOTO', 'w'),
    0x7A: ('PAT_CALL', 'w'),
    0x7B: ('NOISE_SEQ2', ''),
    0x7C: ('NOISE_SEQ3', ''),
    0x7D: ('NOISE_HIT7', ''),
}

SFX_TABLE = 0x5F3F
N_SFX = 14
FREQ_TABLE = 0x5C29
WAVE_TABLES = [0x5EDF, 0x5EEF, 0x5EFF, 0x5F0F, 0x5F1F]
# song starters: (name, routine, (C6 order, C4 order, C5 order), instr table, arp table)
SONGS = [
    ('Song1', 0x60FB, (0x611E, 0x6134, 0x614A), 0x7344, 0x740C),
    ('Song2', 0x642E, (0x6449, 0x6451, 0x6459), 0x7344, 0x740C),
    ('Song3', 0x64E6, (0x6501, 0x6507, 0x650D), 0x7344, 0x740C),
    ('Song4', 0x6584, (0x659F, 0x65E3, 0x6627), 0x7344, 0x740C),
    ('Song5', 0x743E, (0x7472, 0x74B0, 0x748E), 0x7930, 0x79E2),
]
INSTR_TABLES = {0x7344: 26, 0x7930: 26}
ARP_TABLES = {0x740C: 5, 0x79E2: 5}


def w16(rom, a):
    return rom[a] | (rom[a + 1] << 8)


def kinds_of(rom, a):
    b = rom[a]
    name, k = CMDS[b]
    if k is not None:
        return k
    if b == 0x6B:
        return 'b' if rom[a + 1] == 0 else 'bw'
    if b == 0x72:
        return 'bb' if rom[a + 2] == 0 else 'bbb'
    if b == 0x77:
        return 'b' if rom[a + 1] == 0 else 'bb'


def decode_cmd(rom, a):
    b = rom[a]
    if b < 0x60:
        return 1, 'NOTE', [b]
    if b < 0x7E:
        name = CMDS[b][0]
        args = []
        p = a + 1
        for k in kinds_of(rom, a):
            if k == 'b':
                args.append(rom[p]); p += 1
            else:
                args.append(w16(rom, p)); p += 2
        return p - a, name, args
    if b < 0x98:
        return 1, 'INSTR', [b - 0x7E]
    if b < 0xA7:
        return 1, 'ARP', [b - 0x98]
    if b < 0xB7:
        return 1, 'VOL', [b - 0xA7]
    if b < 0xC7:
        return 4, 'VOLENV', [b - 0xB7, rom[a + 1], rom[a + 2], rom[a + 3]]
    return 1, 'LEN', [b - 0xC6]


class Walker:
    def __init__(self, rom):
        self.rom = rom
        self.items = {}
        self.refs = {}
        self.instr_used = {}   # table -> set(n)
        self.arp_used = {}

    def mark(self, a, n, kind, payload=None):
        if a in self.items:
            return False
        self.items[a] = (n, kind, payload)
        return True

    def ref(self, a, name):
        self.refs.setdefault(a, name)

    def stream(self, a, ctx, name, tables):
        self.ref(a, name)
        rom = self.rom
        while a not in self.items:
            n, m, args = decode_cmd(rom, a)
            self.mark(a, n, 'ev', (m, args, ctx))
            b = rom[a]
            a += n
            if m == 'INSTR' and tables:
                self.instr_used.setdefault(tables[0], set()).add(args[0])
            if m == 'ARP' and tables:
                self.arp_used.setdefault(tables[1], set()).add(args[0])
            if b == 0x6B and args[0] != 0:
                self.drum(args[1])
            if b == 0x75:
                self.wave(args[0])
            if ctx == 'instr':
                if b in (0x66, 0x68):
                    return
                continue
            if b in (0x66, 0x68, 0x65):
                return
            if b == 0x69:
                self.orders(args[0], None, tables)
                return
            if b == 0x79:
                self.stream(args[0], ctx, 'Pat_%04X' % args[0], tables)
                return
            if b == 0x7A:
                self.stream(args[0], ctx, 'Sub_%04X' % args[0], tables)

    def drum(self, a):
        self.ref(a, 'Drums_%04X' % a)
        while a not in self.items:
            b = self.rom[a]
            self.mark(a, 1, 'drum', b)
            a += 1
            if b == 0xFF:
                return

    def wave(self, a):
        self.ref(a, 'Wave_%04X' % a)
        self.mark(a, 16, 'wave', None)

    def orders(self, a, name, tables):
        self.ref(a, name or 'Ord_%04X' % a)
        while a not in self.items:
            p = w16(self.rom, a)
            if p == 0:
                self.mark(a, 4, 'ordend', w16(self.rom, a + 2))
                self.orders(w16(self.rom, a + 2), None, tables)
                return
            self.mark(a, 2, 'ord', p)
            self.stream(p, 'pat', 'Pat_%04X' % p, tables)
            a += 2

    def run(self):
        rom = self.rom
        for name, routine, (o6, o4, o5), it, at in SONGS:
            self.orders(o4, f'{name}_Ch1', (it, at))
            self.orders(o5, f'{name}_Ch2', (it, at))
            self.orders(o6, f'{name}_Ch3', (it, at))
        for i in range(1, N_SFX + 1):
            p = w16(rom, SFX_TABLE + 2 * i)
            self.mark(SFX_TABLE + 2 * i, 2, 'ptr', p)
            self.stream(p, 'sfx', 'Sfx%02X' % i, None)
        for t, n in INSTR_TABLES.items():
            self.ref(t, 'InstrTable_%04X' % t)
            for i in range(n):
                p = w16(rom, t + 2 + 2 * i)
                self.mark(t + 2 + 2 * i, 2, 'ptr', p)
                self.stream(p, 'instr', 'Instr_%04X' % p, None)
        for t, n in ARP_TABLES.items():
            self.ref(t, 'ArpTable_%04X' % t)
            for i in range(n):
                p = w16(rom, t + 2 * i)
                self.mark(t + 2 * i, 2, 'ptr', p)
                self.arp(p)
        for wv in WAVE_TABLES:
            self.wave(wv)
        return self

    def arp(self, a):
        self.ref(a, 'Arp_%04X' % a)
        while a not in self.items:
            b = self.rom[a]
            self.mark(a, 1, 'arp', b)
            a += 1
            if b in (0x68, 0xFF):
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
    print({hex(k): sorted(v) for k, v in w.instr_used.items()})
    print({hex(k): sorted(v) for k, v in w.arp_used.items()})
