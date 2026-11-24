"""Random-data check of the model against the real driver code.

Random tracks (every command, every modulation mode, loops, pans, notes,
rests, instruments, drums, 1-40 byte modulation lists) are written into a
scratch copy of the ROM after the sound data of one music bank and of the
SFX bank, and the copy's drum tables get non-zero NR44 bytes so drum rests do
something. Then music and SFX are run together (SFX started and music
restarted at random frames) through e2_cpu and e2_model and compared like
e2_check. Hangs ($FF xx, $F0 on ch4, an empty repeating modulation list) are
checked separately: both sides must hang.

python e2_fuzz.py [runs per game]
"""
import os
import random
import sys

sys.path.insert(0, os.path.dirname(__file__))
from e2_parse import analyze, GAMES, rom  # noqa: E402
from e2_cpu import CPU, Halt  # noqa: E402
from e2_model import Machine, Driver, Hang  # noqa: E402
import e2_check  # noqa: E402

SPOT = {  # game -> (music bank, free address), (sfx bank, free address)
    'oha': ((0x09, 0x7A90), (0x08, 0x4D10)),
    'dora3': ((0x07, 0x7800), (0x05, 0x4F50)),
    'sylv': ((0x71, 0x7560), (0x7A, 0x7800)),
}


def rand_track(rng, ch, sfx, ninst, nwave, ndrum, length):
    out = []
    if rng.random() < 0.7:
        out += [0xFF, 0x00]
    # a loop body needs at least one row that takes time
    out += [0xE0, rng.randrange(1, 10)]
    while len(out) < length:
        r = rng.random()
        if r < 0.45:
            if ch == 3:
                n = rng.randrange(ndrum)
            elif sfx:
                n = rng.randrange(0, 73)
            else:
                n = rng.randrange(0, 72)
            out += [n, rng.randrange(256), rng.randrange(1, 12)]
        elif r < 0.6:
            out += [0xE0, rng.randrange(1, 10)]
        elif r < 0.7:
            out += [0xF1, rng.choice([0, 0, 1, 2, 3])]
        elif r < 0.8 and ch != 3:
            mode = rng.choice([0, 1, 2, 3, 4, 5, 6])
            if mode == 0:
                out += [0xF2, 0]
            else:
                cnt = rng.choice([1, 2, 3, 5, 8, 18, rng.randrange(1, 41)])
                if ch == 2 and cnt > 18:
                    cnt = 18     # ch3 buffer overrun would leave the page
                out += [0xF2, mode, rng.randrange(0, 4), cnt] + [rng.randrange(256) for _ in range(cnt)]
        elif r < 0.9 and ch != 3:
            lim = nwave if ch == 2 else ninst[ch]
            out += [0xF0, rng.randrange(lim)]
    out += [0xFF, 0x01] if rng.random() < 0.6 else [0xFF, 0xFF]
    return out


def build_rom(game, rng):
    d = bytearray(rom(game))
    (mb, ma), (sb, sa) = SPOT[game]
    info = {}
    for bank, addr, sfx in ((mb, ma, False), (sb, sa, True)):
        B = analyze(game, bank)
        t = B.tables
        ninst = [max(1, (t['inst2'][0] - t['inst1'][0]) // 4) if t['inst2'][0] > t['inst1'][0] else 1,
                 max(1, (t['wave'][0] - t['inst2'][0]) // 3) if t['wave'][0] > t['inst2'][0] else 1]
        nwave = max(1, (t['noise'][0] - t['wave'][0]) // 18) if t['noise'][0] > t['wave'][0] else 1
        ndrum = 8
        # drum NR44 bytes: make some non-zero (scratch copy only)
        for i in range(ndrum):
            d[bank * 0x4000 + t['noise'][0] - 0x4000 + 3 * i + 2] = rng.choice([0x00, 0x40, 0x80, 0xC0])
        # rest bytes of ch1/ch2 instruments: some zero, some not
        for i in range(ninst[0]):
            d[bank * 0x4000 + t['inst1'][0] - 0x4000 + 4 * i + 3] = rng.choice([0x00, 0x40, 0x80])
        # one header + 4 tracks per id slot 1..3
        a = addr
        ids = []
        for slot in range(3):
            tracks = [rand_track(rng, ch, sfx, ninst, nwave, ndrum, rng.randrange(16, 60)) for ch in range(4)]
            hdr = a
            a += 10
            ptrs = []
            for tr in tracks:
                ptrs.append(a)
                d[bank * 0x4000 + a - 0x4000:bank * 0x4000 + a - 0x4000 + len(tr)] = bytes(tr)
                a += len(tr)
            offs = [p - hdr for p in ptrs] + [a - hdr]
            for k, o in enumerate(offs):
                d[bank * 0x4000 + hdr - 0x4000 + 2 * k] = o & 0xFF
                d[bank * 0x4000 + hdr - 0x4000 + 2 * k + 1] = o >> 8
            sid = slot + 1
            d[bank * 0x4000 + 2 * sid + 6] = hdr & 0xFF
            d[bank * 0x4000 + 2 * sid + 7] = hdr >> 8
            ids.append(sid)
            assert a < 0x8000
        info[bank] = ids
    return bytes(d), mb, sb, info


class FPair(e2_check.Pair):
    def __init__(self, game, d):
        self.game = game
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
            B = analyze(self.game, bank)   # code/table addresses from the real ROM
            self.drv[bank] = (B, Driver(self.mach, self.d, bank, e2_check.tables(B), self.ver, B.is_sfx))
        return self.drv[bank]


def one_run(game, seed, cov=None):
    rng = random.Random(seed)
    d, mb, sb, info = build_rom(game, rng)
    P = FPair(game, d)
    P.cpu.cov = cov
    P.set_id(0x01, 0xFF)
    P.set_id(0x00, rng.choice(info[mb]))
    steps = [(mb, 'init')]
    sfx_at = set(rng.sample(range(10, 1200), 4))
    mus_at = set(rng.sample(range(10, 1200), 2))
    for f in range(1200):
        if f in sfx_at:
            steps.append(('sfx', rng.choice(info[sb])))
        if f in mus_at:
            steps.append(('mus', rng.choice(info[mb])))
        pair = [(mb, 'update'), (sb, 'update')]
        if e2_check.SFX_FIRST[game]:
            pair.reverse()
        steps += pair + ['frame']
    frame = 0
    for it in steps:
        if it == 'frame':
            frame += 1
            continue
        if it[0] == 'sfx':
            P.set_id(0x01, it[1])
            it = (sb, 'init')
        elif it[0] == 'mus':
            P.set_id(0x00, it[1])
            it = (mb, 'init')
        err = P.run(*it)
        diffs = [x[:200] for x in P.compare()]
        if len(err) == 2:
            return None          # both hang: the run ends here
        if err or diffs:
            return 'seed %d frame %d %02X %s: %s %s' % (seed, frame, it[0], it[1], err, diffs[:5])
    return None


def hang_tests(game):
    """$FF $xx, $F0 on ch4 and an empty repeating modulation list must hang both sides."""
    res = []
    (mb, ma), (sb, sa) = SPOT[game]
    cases = [('$FF $05 on ch1', 0, [0xFF, 0x05]),
             ('$F0 on ch4', 3, [0xF0, 0x00])]
    for bank in (mb, sb):
        for name, ch, data in cases:
            d = bytearray(rom(game))
            hdr = ma if bank == mb else sa
            base = bank * 0x4000 - 0x4000
            silent = [0xFF, 0xFF]
            tracks = [silent[:] for _ in range(4)]
            tracks[ch] = data
            a = hdr + 10
            offs = []
            for tr in tracks:
                offs.append(a - hdr)
                d[base + a:base + a + len(tr)] = bytes(tr)
                a += len(tr)
            offs.append(a - hdr)
            for k, o in enumerate(offs):
                d[base + hdr + 2 * k] = o & 0xFF
                d[base + hdr + 2 * k + 1] = o >> 8
            d[base + 0x4008] = hdr & 0xFF
            d[base + 0x4009] = hdr >> 8
            P = FPair(game, bytes(d))
            P.cpu_max = 20000
            idoff = 0x01 if bank == sb else 0x00
            P.set_id(idoff, 1)
            P.run(bank, 'init')
            P.compare()
            err = P.run(bank, 'update')
            ok = len(err) == 2
            res.append('%s bank %02X %s: %s' % (game, bank, name, 'both hang' if ok else 'MISMATCH %s' % err))
    return res


if __name__ == '__main__':
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 50
    games = sys.argv[2:] or list(GAMES)
    bad = 0
    for game in games:
        cov = set()
        f = 0
        for seed in range(n):
            r = one_run(game, seed, cov)
            if r:
                f += 1
                if f <= 5:
                    print(game, r)
        print('%s: %d random runs x 1200 frames, %d with differences' % (game, n, f))
        bad += f
        for line in hang_tests(game):
            print('  ' + line)
            if 'MISMATCH' in line:
                bad += 1
        # coverage of driver code
        for kind, banks in (('mus', [SPOT[game][0][0]]), ('sfx', [SPOT[game][1][0]])):
            B = analyze(game, banks[0])
            hit = {pc for (bk, pc) in cov if bk == banks[0]}
            miss = [a for a in B.code if a not in hit]
            print('  %s driver: %d of %d instructions executed; not executed: %s' % (
                kind, len(B.code) - len(miss), len(B.code), ' '.join('%04X' % a for a in sorted(miss))[:300]))
    sys.exit(1 if bad else 0)
