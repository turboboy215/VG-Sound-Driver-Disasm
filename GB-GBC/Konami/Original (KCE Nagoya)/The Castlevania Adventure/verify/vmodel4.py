"""Update-by-update comparison of the TMNT II driver model (tools/kmodel4.py) against PyBoy.
usage: vmodel4.py TICKS id[@tick][,id@tick...][,!ADDR=VV@tick...]   (default first id at tick 30)
Ticks are driver updates (256 Hz timer). The game's own requests (PlaySoundFar $029A/$029D) are dropped
unless VGAME=1; sounds are injected through $029A from the timer ISR just before the update.
Compared every update: the seven track pages ($80-$C5), the driver globals $C0CA-$C0D9, and the exact
sequence of register writes (every ld [c],a / ldh [n],a in the driver code is hooked)."""
import sys, os
os.environ['SDL_VIDEODRIVER'] = 'dummy'
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'tools'))
from pyboy import PyBoy
from sm83 import decode
import kmodel4

ROMF = os.environ.get('KON_ROM_TM2', 'Teenage Mutant Hero Turtles - Back from the Sewers (E) [!].gb')
NT = int(sys.argv[1])
inj = []; pokes = []
for x in sys.argv[2].split(','):
    i, _, t = x.partition('@')
    if i.startswith('!'):
        a, v = i[1:].split('='); pokes.append((int(t), int(a, 16), int(v, 16))); continue
    inj.append((int(t) if t else 30, int(i, 16)))
pokes.sort(); inj.sort()
ISR_CALL, PLAYFAR, RET = 0x00B0, 0x029A, 0x0299
CODE = {0: [(0x02F7, 0x0303), (0x0340, 0x0344), (0x04D2, 0x0658), (0x0661, 0x07C7)],
        14: [(0x4000, 0x437E), (0x43B1, 0x43BE), (0x43F1, 0x447C), (0x4483, 0x44B4), (0x44C7, 0x48BD),
             (0x6990, 0x6A09)],
        15: [(0x4000, 0x4345), (0x4378, 0x43E2), (0x43E9, 0x4416), (0x4429, 0x47D6)]}
MIRROR = [0xC794, 0xC0D4]

rom = open(ROMF, 'rb').read()
def rb(bank, a): return rom[a if a < 0x4000 else bank * 0x4000 + a - 0x4000]
WRITERS = []           # (bank, addr, kind)  kind: None = ld [c],a, else the ldh register
for b, rngs in CODE.items():
    for s, e in rngs:
        pc = s
        while pc <= e:
            l, t, tg = decode(lambda a: rb(b, a), pc)
            op = rb(b, pc)
            if op == 0xE2: WRITERS.append((b, pc, None))
            elif op == 0xE0 and 0x00 <= rb(b, pc + 1) < 0x40: WRITERS.append((b, pc, rb(b, pc + 1)))
            pc += l

pb = PyBoy(ROMF, window='null', sound_emulated=True)
rf = pb.register_file; mem = pb.memory
M = kmodel4.Driver(ROMF)
st = dict(k=0, reinj=False, emuw=[], nerr=0, dropped=0, mine=False, seeded=False, bank=None, nw=0)

def seed():
    for a in range(0xC000, 0xE000): M.m[a] = mem[a]
    for r in range(0x00, 0x40): M.hw[r] = mem[0xFF00 + r]

def snap_compare():
    errs = []
    for c in range(7):
        a = 0xC080 + 0x100 * c
        for o in range(0x46):
            if mem[a + o] != M.m[a + o]: errs.append(f'trk{c}+{o + 0x80:02X} emu {mem[a + o]:02X} model {M.m[a + o]:02X}')
    for a in range(0xC0CA, 0xC0DA):
        if mem[a] != M.m[a]: errs.append(f'{a:04X} emu {mem[a]:02X} model {M.m[a]:02X}')
    return errs

def on_isr(ctx):
    if st['reinj']:
        st['reinj'] = False; return
    k = st['k']
    if not st['seeded']:
        seed(); st['seeded'] = True; st['emuw'] = []; M.writes = []
    for a in range(0xC000, 0xE000):        # game RAM outside the driver's fields follows the emulator
        if not (0x80 <= (a & 0xFF) <= 0xC5 and 0xC0 <= a >> 8 <= 0xC6) and not 0xC0CA <= a <= 0xC0D9:
            M.m[a] = mem[a]
    for a in MIRROR: M.m[a] = mem[a]
    M.hw[0] = mem[0xFF00]
    errs = snap_compare()
    ew = st['emuw']; mw = [(r, v) for t, r, v in M.writes]
    if ew != mw:
        i = next((j for j in range(min(len(ew), len(mw))) if ew[j] != mw[j]), min(len(ew), len(mw)))
        errs.append(f'writes differ at #{i}: emu {[f"{r:02X}={v:02X}" for r, v in ew[i:i + 4]]} '
                    f'model {[f"{r:02X}={v:02X}" for r, v in mw[i:i + 4]]} (emu {len(ew)}, model {len(mw)})')
    st['nw'] += len(ew)
    st['emuw'] = []; M.writes = []
    if errs:
        st['nerr'] += 1
        if st['nerr'] <= 5: print(f'tick {k}:', '; '.join(errs[:6]))
        for a in range(0xC000, 0xC800): M.m[a] = mem[a]          # resync so later ticks stay meaningful
    while pokes and pokes[0][0] <= k:
        _, a, v = pokes.pop(0); mem[a] = v; M.m[a] = v
    st['k'] = k + 1
    if inj and inj[0][0] <= k:
        _, sid = inj.pop(0)
        M.play(sid)
        sp = rf.SP - 2; mem[sp] = rf.PC & 255; mem[sp + 1] = rf.PC >> 8; rf.SP = sp
        rf.A = sid; rf.PC = PLAYFAR; st['reinj'] = True; st['mine'] = True
    M.update()

def on_playfar(ctx):
    if st['mine']:
        st['mine'] = False; return
    if os.environ.get('VGAME') != '1':
        st['dropped'] += 1; rf.PC = RET

def mk_writer(reg):
    if reg is None:
        def h(ctx):
            if st['seeded']: st['emuw'].append((rf.C, rf.A))
    else:
        def h(ctx):
            if st['seeded']: st['emuw'].append((reg, rf.A))
    return h

pb.hook_register(0, ISR_CALL, on_isr, None)
pb.hook_register(0, PLAYFAR, on_playfar, None)
pb.hook_register(0, 0x029D, on_playfar, None)
for b, a, reg in WRITERS: pb.hook_register(b, a, mk_writer(reg), None)
frames = 0
while st['k'] < NT:
    pb.tick(60); frames += 60
print(f'tm2 {sys.argv[2]}: {st["k"]} ticks, {st["nerr"]} ticks with mismatches, {st["nw"]} register writes, '
      f'{frames} frames, dropped {st["dropped"]}, RAM reads {M.ramreads}')
