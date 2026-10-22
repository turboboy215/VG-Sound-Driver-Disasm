"""Square GB driver, 2nd generation (FFL2 / FFA): ROM model shared by the generator and the verifiers."""
import os
H = 'H'          # handler is the halt loop (FFA) / null "ret" (FFL2): no arguments
GAMES = {
    'ffa': dict(rom=os.environ.get('FFA_ROM', 'Final Fantasy Adventure (U) [!].gb'), alt='ffa.gb', bank=0x0F,
                songtab=0x4A12, cmdtabs=(0x4365, 0x45C7, 0x4722), ncmd=(13, 12, 12),
                sfxtone=0x7B3C, sfxnoise=0x7B86, title='Final Fantasy Adventure'),
    'ffl2': dict(rom=os.environ.get('FFL2_ROM', 'Final Fantasy Legend II (U) [!].gb'), alt='ffl2.gb', bank=0x0E,
                 songtab=0x49F5, cmdtabs=(0x4358, 0x45AB, 0x4706), ncmd=(12, 12, 12),
                 sfxtone=0x7AC5, sfxnoise=0x7B37, title='Final Fantasy Legend II'),
}
CHN = ['CH2', 'CH1', 'CH3']
# argument bytes per command (low nibble) and channel; H = halt/null slot
BASEARGS = [[2, 2, 1], [2, 2, 2], [2, 2, 2], [1, 1, 1], [2, 2, 2], [1, 1, H], [1, 1, 1], [1, H, H],
            [H, H, 2], [2, 2, 2], [1, 1, 1], [3, 3, 3], [1, None, None]]
class Game:
    def __init__(self, key):
        g = GAMES[key]; self.key = key; self.__dict__.update(g)
        path = next((p for p in (g['rom'], os.path.join('..', g['rom']), g['alt']) if os.path.exists(p)), g['alt'])
        self.romfile = path
        self.r = open(path, 'rb').read(); self.base = g['bank'] * 0x4000
        self.LEN = [self.rb(self.lentab + i) for i in range(13)] if hasattr(self, 'lentab') else None
        # find tables from the code itself
        self.halt = self.rw(self.cmdtabs[0] + 16)
        self.args = []
        for c in range(16):
            row = []
            for ch in range(3):
                if c >= self.ncmd[ch]: row.append(None); continue
                h = self.rw(self.cmdtabs[ch] + 2 * c)
                row.append(H if h == self.halt else BASEARGS[c][ch])
            self.args.append(row)
        sp = [self.rw(self.songtab + 2 * i) for i in range(3)]
        first = min(self.rw(self.songtab + 2 * i) for i in range(3 * 40) if self.rw(self.songtab + 2 * i) > self.songtab)
        self.nsong = (first - self.songtab) // 6
        self.songs = [[self.rw(self.songtab + 6 * i + 2 * c) for c in range(3)] for i in range(self.nsong)]
        self.nsfx = (self.sfxnoise - self.sfxtone) // 2
        self.playsfx = {'ffa': 0x493C, 'ffl2': 0x4920}[self.key]
        self.initB = 0 if self.key == 'ffa' else 0x0A   # FFL2: init copy runs 1 byte into DefaultPitchFx
    def rb(self, a): return self.r[self.base + a - 0x4000]
    def rw(self, a): return self.rb(a) | self.rb(a + 1) << 8
    def isize(self, a, ch):
        b = self.rb(a)
        if b < 0xE0: return 1
        if b == 0xFF: return 1
        n = self.args[b & 15][ch]
        if n is None: return None
        return 1 if n == H else 1 + n
    def play(self, start, ch, LEN, maxticks=100000, maxev=400000):
        """yield (t, addr, kind, val): note reads in order; counters start 0 (as after init)."""
        a = start; A = 0; B = self.initB; t = 0; ev = 0
        while t < maxticks and ev < maxev:
            ev += 1
            b = self.rb(a)
            if b < 0xD0:
                yield (t, a, 'note', b); t += LEN[b >> 4]; a += 1; continue
            if b < 0xE0: a += 1; continue
            if b == 0xFF: yield (t, a, 'end', None); return
            c = b & 15; n = self.args[c][ch]
            if n is None: yield (t, a, 'crash', b); return
            if n == H:
                if self.key == 'ffa': yield (t, a, 'hang', b); return
                a += 1; continue
            if c == 1: a = self.rw(a + 1); continue
            if c in (2, 9):
                if c == 2: A = (A - 1) & 255; z = A
                else: B = (B - 1) & 255; z = B
                a = self.rw(a + 1) if z else a + 3; continue
            if c == 3: A = self.rb(a + 1)
            if c == 10: B = self.rb(a + 1)
            if c == 11:
                a = self.rw(a + 2) if self.rb(a + 1) == A else a + 4; continue
            if c == 7 and ch == 0: yield (t, a, 'tempo', self.rb(a + 1))
            a += 1 + n
        yield (t, a, 'limit', None)
