"""Run the real driver code in PyBoy and compare every sound-register write
(and the NR51/NR52 reads it makes) with tools/model.py, tick by tick.

usage: python emucheck.py <Zoop ROM> <SROTJ ROM> [asmdir]
The driver banks come from the generated .asm files (linked with harness.asm),
so this also tests that the disassembly assembles into working code.
"""
import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'tools'))
from rta import Bank, parse_song  # noqa: E402
from sm83 import decode  # noqa: E402
from model import Model  # noqa: E402

os.environ.setdefault('PYSDL2_DLL_PATH', '')
from pyboy import PyBoy  # noqa: E402

WTICKS = 0xC010
SCRIPT = 0xC100


def build(asmdir, tmp, name, asms, defines):
    objs = []
    for f in asms:
        o = os.path.join(tmp, os.path.basename(f) + name + '.o')
        subprocess.run(['rgbasm', '-I', asmdir] + ['-D' + d for d in defines] + ['-o', o, f], check=True)
        objs.append(o)
    rom = os.path.join(tmp, name + '.gb')
    sym = os.path.join(tmp, name + '.sym')
    subprocess.run(['rgblink', '-p', '0xFF', '-n', sym, '-o', rom] + objs, check=True)
    subprocess.run(['rgbfix', '-v', '-m', '0x01', '-p', '0xFF', rom], check=True)
    syms = {}
    for ln in open(sym):
        ln = ln.split(';')[0].strip()
        if ln:
            ba, n = ln.split()
            b, a = ba.split(':')
            syms[n] = (int(b, 16), int(a, 16))
    return rom, syms


def hook_points(bk):
    """Store instructions and NR51/NR52 reads in the driver code."""
    t = bk.find_tables()
    pts = []
    a = 0x4001
    while a < t['Waves']:
        ln, txt, kind, tgt = decode(bk.b, a)
        op = bk.b(a)
        if op == 0xE0:
            pts.append((a, 'ldh', 0xFF00 | bk.b(a + 1)))
        elif op in (0x22, 0x32, 0x77):
            pts.append((a, 'hl', None))
        elif op == 0x02:
            pts.append((a, 'bc', None))
        elif op == 0x12:
            pts.append((a, 'de', None))
        elif op == 0xF0 and bk.b(a + 1) in (0x25, 0x26):
            pts.append((a + ln, 'read', 0xFF00 | bk.b(a + 1)))
        elif op == 0xEA and 0xFF00 <= bk.w(a + 1):
            raise SystemExit('unhandled store at %04X' % a)
        elif op in (0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x36, 0xE2):
            raise SystemExit('unhandled store at %04X' % a)
        a += ln
    return pts


class Run:
    def __init__(self, rom, syms, bank, bk):
        self.pb = PyBoy(rom, window='null', sound_emulated=True)
        self.pb.set_emulation_speed(0)
        self.log = []
        rf = self.pb.register_file
        for (a, kind, reg) in hook_points(bk):
            self.pb.hook_register(bank, a, self.cb, (kind, reg, rf))
        b, a = syms['TickPoint']
        self.pb.hook_register(b, a, self.tick, None)
        self.pb.memory[0xC002] = bank

    def cb(self, ctx):
        kind, reg, rf = ctx
        if kind == 'ldh':
            if 0xFF10 <= reg < 0xFF40:
                self.log.append(('w', reg, rf.A))
        elif kind == 'read':
            self.log.append(('r', {0xFF25: 'NR51', 0xFF26: 'NR52'}[reg], rf.A))
        else:
            addr = {'hl': rf.HL, 'bc': (rf.B << 8) | rf.C, 'de': (rf.D << 8) | rf.E}[kind]
            if 0xFF10 <= addr < 0xFF40:
                self.log.append(('w', addr, rf.A))

    def tick(self, ctx):
        self.log.append(('tick',))

    def run(self, script, nticks):
        m = self.pb.memory
        a = SCRIPT
        for (t, op, arg) in script + [(0xFFFF, 0, 0)]:
            m[a], m[a + 1], m[a + 2], m[a + 3] = t & 0xFF, t >> 8, op, arg
            a += 4
        m[0xC001] = 1
        while True:
            self.pb.tick(16, False, False)
            if m[WTICKS] | m[WTICKS + 1] << 8 >= nticks:
                break
        self.pb.stop(save=False)
        return self.log


def split_ticks(log):
    """[setup events, tick0 events (cmds before tick 0 are in setup), ...] -> list per call boundary."""
    out = [[]]
    for e in log:
        if e[0] == 'tick':
            out.append([])
        else:
            out[-1].append(e)
    return out


def model_run(bk, script, nticks, emu_ticks):
    reads = iter([e[1:] for blk in emu_ticks for e in blk if e[0] == 'r'])
    m = Model(bk, bk.find_tables(), reads)
    blocks = []
    m.init()
    pending = sorted(script)
    si = 0
    for t in range(nticks):
        while si < len(pending) and pending[si][0] == t:
            _, op, arg = pending[si]
            si += 1
            if op == 0:
                m.play(arg)
            elif op == 1:
                m.stop_all()
            elif op == 2:
                m.pause_play(arg)
            else:
                m.init()
        blocks.append(m.out)
        m.out = []
        m.update()
    blocks.append(m.out)
    return blocks


def compare(name, emu, mod, nticks):
    nw = 0
    for i in range(min(len(emu), len(mod), nticks + 1)):
        e = [x for x in emu[i]]
        d = [x for x in mod[i]]
        nw += sum(1 for x in e if x[0] == 'w')
        if e != d:
            j = next((k for k in range(min(len(e), len(d))) if e[k] != d[k]), min(len(e), len(d)))
            print('  MISMATCH %s at block %d, event %d: emu %s model %s' % (name, i, j, e[j:j + 3], d[j:j + 3]))
            return False, nw
    return True, nw


def song_len(bk, ptr):
    s = parse_song(bk, ptr)
    return sum(e[2][0] for e in s['events'] if e[1] == 'wait')


def cases(bk, bank, sfx_ids, song_ids):
    t = bk.find_tables()
    out = []
    for i in song_ids:
        n = song_len(bk, bk.w(t['Sounds'] + 2 * i)) + 300
        out.append(('song %02X' % i, [(0, 0, 0x80 | i)], n))
    for i in sfx_ids:
        out.append(('sfx %02X' % i, [(0, 0, i)], 400))
        out.append(('sfx %02X hi' % i, [(0, 0, i | 0x40), (3, 0, sfx_ids[0])], 400))
    # songs with SFX on top, pauses, stops
    for k, i in enumerate(song_ids):
        n = song_len(bk, bk.w(t['Sounds'] + 2 * i)) + 300
        sc = [(0, 0, 0x80 | i)]
        tt = 50
        j = k
        while tt < n - 200:
            sid = sfx_ids[j % len(sfx_ids)]
            sc.append((tt, 0, sid | (0x40 if j % 3 == 0 else 0)))
            j += 7
            tt += 37 + (j * 13) % 61
        sc.append((n - 180, 2, sfx_ids[(k + 3) % len(sfx_ids)]))   # pause + SFX
        sc.append((n - 120, 3, 0))                                  # resume
        sc.append((n - 60, 1, 0))                                   # stop all
        out.append(('song %02X + SFX' % i, sc, n))
    return out


def main():
    zrom, srom = sys.argv[1], sys.argv[2]
    asmdir = os.path.abspath(sys.argv[3] if len(sys.argv) > 3 else os.path.join(HERE, '..'))
    zd = open(zrom, 'rb').read()
    sd = open(srom, 'rb').read()
    total = dict(cases=0, ticks=0, writes=0, bad=0)
    with tempfile.TemporaryDirectory() as tmp:
        zr, zs = build(asmdir, tmp, 'hz', [os.path.join(HERE, 'harness.asm'),
                                            os.path.join(asmdir, 'Zoop_SoundDriver.asm')], [])
        sr, ss = build(asmdir, tmp, 'hs', [os.path.join(HERE, 'harness.asm'),
                                            os.path.join(asmdir, 'SROTJ_SoundDriver_Bank4.asm'),
                                            os.path.join(asmdir, 'SROTJ_SoundDriver_Bank5.asm')], ['SROTJ'])
        plan = []
        zb = Bank(zd, 3)
        plan.append(('Zoop', zr, zs, 3, zb, cases(zb, 3, list(range(0x08, 0x2F)), list(range(0, 8)))))
        s4 = Bank(sd, 4)
        plan.append(('SROTJ', sr, ss, 4, s4, cases(s4, 4, list(range(0x0D, 0x34)), list(range(0, 0x0D)))))
        s5 = Bank(sd, 5)
        plan.append(('SROTJ', sr, ss, 5, s5, cases(s5, 5, list(range(0x0D, 0x34)), list(range(0, 0x0D)))))
        for game, rom, syms, bank, bk, cs in plan:
            for name, script, n in cs:
                r = Run(rom, syms, bank, bk)
                log = r.run(script, n)
                emu = split_ticks(log)
                mod = model_run(bk, script, n, emu)
                ok, nw = compare('%s bank %d %s' % (game, bank, name), emu, mod, n)
                total['cases'] += 1
                total['ticks'] += n
                total['writes'] += nw
                total['bad'] += 0 if ok else 1
            print('%s bank %d: %d cases done' % (game, bank, len(cs)))
    print('cases %(cases)d, ticks %(ticks)d, register writes %(writes)d, failing cases %(bad)d' % total)
    sys.exit(1 if total['bad'] else 0)


if __name__ == '__main__':
    main()
