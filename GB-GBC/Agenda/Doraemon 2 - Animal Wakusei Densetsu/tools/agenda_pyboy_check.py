# Compare the real driver (in PyBoy) with agenda_model.py after every update.
# usage: python agenda_pyboy_check.py dora2|poko   (needs: pip install pyboy)
import sys, os, subprocess, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from agenda_model import Model
from agenda_cfg import load
from pyboy import PyBoy

from agenda_cfg import ROOT
HERE = os.path.dirname(os.path.abspath(__file__))
RG = os.environ.get('RGBDS', '')   # folder holding the RGBDS tools, or empty to use PATH
if RG and not RG.endswith(os.sep): RG += os.sep
ASM = {'dora2': 'Doraemon2_sound.asm', 'poko': 'Pokonyan_sound.asm'}
STARTMUSIC = {'dora2': 0x48B2, 'poko': 0x48E7}
UNUSED = {'dora2': (0x40EF,) * 4, 'poko': (0x5F21, 0x5FDE, 0x6088, 0x60FF)}
CHECK_REGS = [0x10, 0x12, 0x17, 0x21, 0x22, 0x24, 0x25]   # fully readable registers the driver writes

def build(g):
    d = os.path.join(tempfile.gettempdir(), 'h_' + g)
    os.makedirs(d, exist_ok=True)
    defs = ['-D', 'SND_STARTMUSIC=$%04X' % STARTMUSIC[g]] + sum([['-D', 'UNUSED%d=$%04X' % (i + 1, a)] for i, a in enumerate(UNUSED[g])], [])
    subprocess.run([RG + 'rgbasm', '-I', ROOT] + defs + ['-o', d + '/h.o', os.path.join(HERE, 'harness.asm')], check=True)
    subprocess.run([RG + 'rgbasm', '-I', ROOT, '-o', d + '/s.o', os.path.join(ROOT, ASM[g])], check=True)
    subprocess.run([RG + 'rgblink', '-n', d + '/h.sym', '-o', d + '/h.gb', d + '/h.o', d + '/s.o'], check=True)
    subprocess.run([RG + 'rgbfix', '-v', '-m', 'MBC1', '-p', '0xFF', d + '/h.gb'], check=True)
    syms = {}
    for ln in open(d + '/h.sym'):
        if ln.startswith(';') or not ln.strip(): continue
        a, n = ln.split()
        bk, ad = a.split(':')
        syms[n] = (int(bk, 16), int(ad, 16))
    return d + '/h.gb', syms

class Checker:
    def __init__(s, g, regs=True):
        s.g = g; s.c = load(g)
        rom, s.syms = build(g)
        s.pb = PyBoy(rom, window='null', sound_emulated=True)
        s.pb.set_emulation_speed(0)
        s.m = Model(g)
        s.hook_hit = False
        s.regs = regs
        s.pb.hook_register(0, s.syms['HookPoint'][1], s.on_hook, None)
        s.pb.hook_register(0, s.syms['InitDone'][1], s.on_init, None)
        s.errors = []; s.count = 0
        s.queue = []; s.pending = None; s.script = []; s.next_at = 1 << 30
        s.label = ''
    def ram(s):
        mem = s.pb.memory
        w = s.c['wram']; sv = s.c['save_wram']; h = s.c['hram']
        page = bytes(mem[w + i] for i in range(0x100))
        save = bytes(mem[sv + i] for i in range(0x100))
        hr = bytes(mem[h + i] for i in range(16))
        return page, save, hr
    def compare(s, where):
        page, save, hr = s.ram()
        m = s.m
        bad = []
        for i in range(0x100):
            if page[i] != m.page[i]: bad.append('trk[%02X] %02X/%02X' % (i, page[i], m.page[i]))
            if save[i] != m.save[i]: bad.append('save[%02X] %02X/%02X' % (i, save[i], m.save[i]))
        for i in range(16):
            if hr[i] != m.h[i]: bad.append('h[%X] %02X/%02X' % (i, hr[i], m.h[i]))
        if s.regs:
            for r in CHECK_REGS:
                if r in m.reg:
                    v = s.pb.memory[0xFF00 + r]
                    mv = m.reg[r]
                    if r == 0x10: v &= 0x7F; mv &= 0x7F
                    if v != mv: bad.append('NR %02X %02X/%02X' % (r, v, mv))
        if bad:
            s.errors.append((s.label, where, s.count, bad[:8]))
            # resync so one difference doesn't flood the log
            s.m.page[:] = page; s.m.save[:] = save; s.m.h[:] = hr
    def on_init(s, ctx):
        s.m.init(); s.compare('init')
    def on_hook(s, ctx):
        # the update that just ran: apply the command issued before it, then update
        if s.pending is not None:
            cmd, arg = s.pending
            m = s.m
            if cmd == 1: m.play_music(arg)
            elif cmd == 2: m.play_sfx(arg)
            elif cmd == 3: m.stop_music()
            elif cmd == 4: m.save_music()
            elif cmd == 5: m.restore_music()
            elif cmd == 6: m.start_music_ptrs(UNUSED[s.g])
            s.pending = None
        s.m.update()
        s.count += 1
        s.compare('update')
        s.hook_hit = True
        # issue the next scripted command now: the loop reads wCmd right after the hook
        if s.count >= s.next_at and s.script:
            cmd, arg, n, label = s.script.pop(0)
            s.label = label
            s.next_at = s.count + n
            if cmd:
                s.pb.memory[0xC001] = arg; s.pb.memory[0xC000] = cmd
                s.pending = (cmd, arg)
    def run(s, script):
        """script: list of (cmd, arg, updates, label)"""
        s.script = list(script); s.next_at = 0
        total = sum(x[2] for x in script)
        while s.count < total + 1:
            s.pb.tick(1, False)
        return s.errors

if __name__ == '__main__':
    g = sys.argv[1]
    c = load(g)
    script = []
    for i in range(c['music_n']):
        script.append((1, i, 3000, 'music %02X' % i))
    for i in range(c['sfx_n']):
        script.append((3, 0, 5, 'stop')); script.append((2, i, 600, 'sfx %02X' % i))
    for i in range(c['sfx_n']):
        script.append((1, 0, 200, 'music 00')); script.append((2, i, 900, 'music 00 + sfx %02X' % i))
    for i in range(c['music_n']):
        script.append((1, i, 300, 'music %02X' % i)); script.append((2, (i * 7) % c['sfx_n'], 150, 'sfx over %02X' % i))
        script.append((4, 0, 200, 'save')); script.append((2, (i * 5) % c['sfx_n'], 300, 'sfx while saved'))
        script.append((5, 0, 600, 'restore'))
    script.append((6, 0, 3000, 'unused song'))
    ck = Checker(g)
    err = ck.run(script)
    print(g, 'updates', ck.count, 'mismatching updates', len(err))
    seen = set()
    for e in err[:30]:
        print(' ', e)
