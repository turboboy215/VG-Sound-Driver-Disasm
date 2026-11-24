"""Compare the model (e2_model.py) with the driver code from the ROM run by
the interpreter (e2_cpu.py), frame by frame: driver RAM, sound registers and
the exact sequence of register writes.

python e2_check.py [game ...]
Runs per game:
  * every music header in every music bank, MUSIC_FRAMES frames
  * every SFX header, SFX_FRAMES frames
  * every SFX started at frame 120 on top of each bank's first song (game order
    of the two update calls), COMBO_FRAMES frames
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from e2_parse import analyze, GAMES, rom  # noqa: E402
from e2_cpu import CPU, Halt  # noqa: E402
from e2_model import Machine, Driver, Hang  # noqa: E402

MUSIC_FRAMES = 4000
SFX_FRAMES = 600
COMBO_FRAMES = 900
SFX_FIRST = {'oha': False, 'dora3': True, 'sylv': True}   # call order per frame


def tables(B):
    t = {k: B.tables[k][0] for k in ('inst1', 'inst2', 'wave', 'noise')}
    t['freq'] = B.freq_start
    return t


class Pair:
    def __init__(self, game):
        self.game = game
        d = rom(game)
        g = GAMES[game]
        self.ram = g['ram'] << 8
        self.cpu = CPU(d)
        self.cpu.sp = 0xC100
        self.cpu.io[0x26] = 0x80
        self.mach = Machine(self.ram)
        self.drv = {}
        self.ver = g['ver']
        self.d = d

    def driver(self, bank):
        if bank not in self.drv:
            B = analyze(self.game, bank)
            self.drv[bank] = (B, Driver(self.mach, self.d, bank, tables(B), self.ver, B.is_sfx))
        return self.drv[bank]

    def set_id(self, off, v):
        self.cpu.wram[self.ram - 0xC000 + off] = v
        self.mach.ram[off] = v

    def run(self, bank, entry):
        B, drv = self.driver(bank)
        self.cpu.bank = bank
        err = []
        try:
            self.cpu.call(B.init if entry == 'init' else B.update, getattr(self, 'cpu_max', 2000000))
        except Halt as e:
            err.append('cpu: %s' % e)
        try:
            (drv.init if entry == 'init' else drv.update)()
        except Hang as e:
            err.append('model: %s' % e)
        return err

    def compare(self):
        cr = self.cpu.wram[self.ram - 0xC000:self.ram - 0xC000 + 0x100]
        mr = self.mach.ram[:0x100]
        diffs = []
        for i in range(0x100):
            if cr[i] != mr[i]:
                diffs.append('RAM+%02X cpu %02X model %02X' % (i, cr[i], mr[i]))
        for r in range(0x10, 0x40):
            if self.cpu.io[r] != self.mach.io[r]:
                diffs.append('FF%02X cpu %02X model %02X' % (r, self.cpu.io[r], self.mach.io[r]))
        if self.cpu.log != self.mach.log:
            diffs.append('log cpu %s model %s' % (fmt(self.cpu.log), fmt(self.mach.log)))
        self.cpu.log = []
        self.mach.log = []
        return diffs


def fmt(log):
    return ' '.join('%02X=%02X' % (a & 0xFF, v) for a, v in log)


def check_run(game, steps, label):
    """steps: list of (bank, 'init'|'update', setid) per frame-call"""
    P = Pair(game)
    frame = 0
    for item in steps:
        if item == 'frame':
            frame += 1
            continue
        if item[0] == 'setid':
            P.set_id(*item[1])
            continue
        bank, entry, setid = item
        if setid:
            P.set_id(*setid)
        err = P.run(bank, entry)
        diffs = P.compare()
        if err or diffs:
            return '%s: frame %d, bank %02X %s: %s %s' % (label, frame, bank, entry, err, diffs[:6])
    return None


def plans(game):
    g = GAMES[game]
    sb = g['sfx']
    S = analyze(game, sb)
    sfx_ids = sorted(set(s['ids'][0] for s in S.songs.values()))
    out = []
    first_song = {}
    for mb in g['music']:
        B = analyze(game, mb)
        for h, s in sorted(B.songs.items()):
            i = s['ids'][0]
            first_song.setdefault(mb, i)
            steps = [('setid', (0x01, 0xFF)), (mb, 'init', (0x00, i))]
            for f in range(MUSIC_FRAMES):
                steps += [(mb, 'update', None), 'frame']
            out.append(('music bank %02X id %02X' % (mb, i), steps))
    for i in sfx_ids:
        steps = [(sb, 'init', (0x01, i))]
        for f in range(SFX_FRAMES):
            steps += [(sb, 'update', None), 'frame']
        out.append(('sfx id %02X' % i, steps))
    # combos: SFX over music; use the bank's largest song
    for mb in g['music']:
        B = analyze(game, mb)
        h = max(B.songs, key=lambda h: B.songs[h]['ptrs'][4] - h if B.songs[h]['ptrs'][4] > h else 0)
        mid = B.songs[h]['ids'][0]
        for i in sfx_ids:
            steps = [('setid', (0x01, 0xFF)), (mb, 'init', (0x00, mid))]
            for f in range(COMBO_FRAMES):
                if f == 120:
                    steps.append((sb, 'init', (0x01, i)))
                pair = [(mb, 'update', None), (sb, 'update', None)]
                if SFX_FIRST[game]:
                    pair.reverse()
                steps += pair + ['frame']
            out.append(('music bank %02X id %02X + sfx %02X' % (mb, mid, i), steps))
            steps = [('setid', (0x01, 0xFF)), (mb, 'init', (0x00, mid))]
            for f in range(300):
                if f == 30:
                    steps.append((sb, 'init', (0x01, i)))
                if f == 32:
                    steps.append((mb, 'init', (0x00, mid)))
                pair = [(mb, 'update', None), (sb, 'update', None)]
                if SFX_FIRST[game]:
                    pair.reverse()
                steps += pair + ['frame']
            out.append(('music restarted during sfx %02X, bank %02X' % (i, mb), steps))
    return out


def main(games):
    total = fails = 0
    for game in games:
        n = f = 0
        frames = 0
        for label, steps in plans(game):
            n += 1
            frames += steps.count('frame')
            r = check_run(game, steps, label)
            if r:
                f += 1
                if f <= 8:
                    print(game, r)
        print('%s: %d runs, %d frames, %d with differences' % (game, n, frames, f))
        total += n
        fails += f
    print('total: %d runs, %d with differences' % (total, fails))
    return fails


if __name__ == '__main__':
    sys.exit(1 if main(sys.argv[1:] or list(GAMES)) else 0)
