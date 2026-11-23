"""Run the reassembled driver in PyBoy and compare it with wiz_model.py after every Sound_Update.
usage: python wiz_pyboy_check.py dx10|quiz   (build the harness ROMs first with build.sh)"""
import os, sys, warnings
warnings.filterwarnings('ignore')
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'tools'))
os.chdir(os.path.join(HERE, '..'))
from pyboy import PyBoy
from wiz_model import Model, SZ
from wiz_cfg import GAMES
from wiz_parse import Game

REGS = [(0x12, 0xFF), (0x17, 0xFF), (0x21, 0xFF), (0x22, 0xFF), (0x24, 0xFF), (0x25, 0xFF),
        (0x11, 0xC0), (0x16, 0xC0), (0x1C, 0x60)]


class Check:
    def __init__(self, key):
        self.key = key
        self.cfg = GAMES[key]
        name = {'dx10': 'DX10', 'quiz': 'QuizBoy'}[key]
        self.pb = PyBoy(os.path.join(HERE, f'h_{name}.gb'), window='null', sound_emulated=True,
                        symbols=os.path.join(HERE, f'h_{name}.sym'), cgb=False)
        self.rom = open(self.cfg['rom'], 'rb').read()
        self.model = Model(key, self.rom)
        self.model.init()
        self.pb.hook_register(None, 'HarnessHook', self.hook, None)
        self.count = 0
        self.updates = 0
        self.bad = 0
        self.first_bad = []
        self.pending = None
        self.remaining = 0
        self.skip_first = True
        self.mute_mask = 0

    def hook(self, _):
        self.model.update()
        self.compare()
        self.updates += 1
        self.remaining -= 1
        if self.pending and self.remaining <= 0:
            op = self.pending.pop(0)
            self.apply(op)
            if not self.pending:
                self.pending = None

    def apply(self, op):
        kind, *a = op
        mem = self.pb.memory
        if kind == 'play':
            mem[0xD801] = a[0]; mem[0xD800] = 1; self.model.play(a[0])
        elif kind == 'stop':
            mem[0xD800] = 2; self.model.stop(0)
        elif kind == 'fade':
            mem[0xD801] = a[0]; mem[0xD800] = 3; self.model.fade(a[0])
        elif kind == 'pause':
            mem[0xD800] = 4; self.model.pause()
        elif kind == 'resume':
            mem[0xD800] = 5; self.model.resume()
        elif kind == 'volofs':
            mem[0xD801] = a[0]; mem[0xD802] = a[1]; mem[0xD800] = 6; self.model.set_volofs(a[0], a[1])
        elif kind == 'keep':
            mem[0xD801] = a[0]; mem[0xD800] = 7; self.model.stop(a[0])
        self.remaining = a[-1] if kind not in ('stop', 'pause', 'resume') else a[0]

    def compare(self):
        mem = self.pb.memory
        m = self.model
        diffs = []
        for addr, v in m.ram.items():
            if mem[addr] != v:
                diffs.append(f'{addr:04X}: emu {mem[addr]:02X} model {v:02X}')
        for r, mask in REGS:
            e = mem[0xFF00 + r] & mask
            v = m.reg.get(r, None)
            if v is None:
                continue
            if r == 0x1C:
                v = v & 0x60
            else:
                v &= mask
            if e != v:
                diffs.append(f'NR {r:02X}: emu {e:02X} model {v:02X}')
        e52 = mem[0xFF26] & 0x0C
        m52 = m.rd(0x26) & 0x0C
        if e52 != m52:
            diffs.append(f'NR52 ch3/4: emu {e52:02X} model {m52:02X}')
        if diffs:
            self.bad += 1
            if len(self.first_bad) < 5:
                self.first_bad.append((self.updates, self.label, diffs[:8]))
            # resync so one difference doesn't cascade
            for addr in m.ram:
                m.ram[addr] = mem[addr]

    def run(self, label, ops):
        self.label = label
        self.pending = list(ops)
        self.remaining = 0
        while self.pending is not None:
            self.pb.tick(1, False, False)
        # drain the final wait
        while self.remaining > 0:
            self.pb.tick(1, False, False)


def main(key):
    c = Check(key)
    g = Game(key)
    n = len(g.sound_table())
    hdrs = [g.header(p) for p in g.sound_table()]
    music = [i for i, h in enumerate(hdrs) if h[0] & 0x0F]
    sfx = [i for i, h in enumerate(hdrs) if not h[0] & 0x0F]
    runs = []
    for i in range(n):
        runs.append((f'sound {i:02X}', [('stop', 1), ('play', i, 3000 if i in music else 800)]))
    m0 = music[0]
    for s in sfx:
        runs.append((f'music {m0:02X} + sfx {s:02X}', [('stop', 1), ('play', m0, 200), ('play', s, 700)]))
    for mid in music[:6]:
        runs.append((f'music {mid:02X}: fade, pause/resume, vol offsets, stop-except',
                     [('stop', 1), ('play', mid, 300), ('pause', 120), ('resume', 300),
                      ('volofs', 0xFD, 0x0F, 200), ('volofs', 3, 0x05, 200), ('volofs', 0, 0xFF, 50),
                      ('play', sfx[0], 100), ('keep', 0x0F, 200), ('fade', 4, 400), ('stop', 50)]))
    total_runs = 0
    for label, ops in runs:
        c.run(label, ops)
        total_runs += 1
    print(f'{key}: {total_runs} runs, {c.updates} updates, {c.bad} mismatching updates')
    for u, lab, d in c.first_bad:
        print('  at update', u, lab, d)
    c.pb.stop(save=False)
    return c.bad


if __name__ == '__main__':
    bad = 0
    for k in sys.argv[1:] or ['dx10', 'quiz']:
        bad += main(k)
    sys.exit(1 if bad else 0)
