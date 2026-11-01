"""Tick-by-tick comparison of the driver model (tools/kmodel.py) against PyBoy.
usage: vmodel.py cva|mm TICKS id[@tick][,id@tick...]   (default first id at tick 30)
Injects PlaySound calls at the given driver ticks, compares every tick:
all 7/6 track slots, register shadows, NR51/tempo/parity/queue globals, wave RAM, triggers."""
import sys, os
os.environ['SDL_VIDEODRIVER'] = 'dummy'
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'tools'))
from pyboy import PyBoy
import kdata, kmodel

game = sys.argv[1]; NT = int(sys.argv[2])
inj = []
pokes = []
for x in sys.argv[3].split(','):
    i, _, t = x.partition('@')
    if i.startswith('!'):   # !ADDR=VV@tick : poke game RAM (pause flag, engine pitch, course)
        a, v = i[1:].split('='); pokes.append((int(t), int(a, 16), int(v, 16))); continue
    inj.append((int(t) if t else 30, int(i, 16)))
pokes.sort()
inj.sort()
G = kdata.CVA if game == 'cva' else kdata.MM
ROM = G['rom']
if game == 'cva':
    BANK, UPD, PLAY, TRIG, ISR_AFTER, PLAYEXT = 2, 0x405B, 0x4712, 0x464C, 0x00AC, 0x00BD
    SLOTS = [0xC125, 0xC14A, 0xC16F, 0xC194, 0xC1B9, 0xC1DE]; SH = 0xC228
    GL = dict(nr51=0xC23C, acc=0xC23D, tempo=0xC23E, skip=0xC23F, parity=0xC24D)
    BASE = 0xC245; SKIPB = {0x24}
else:
    BANK, UPD, PLAY, TRIG, ISR_AFTER, PLAYEXT = 1, 0x6591, 0x6C35, 0x6B8F, 0x0085, None
    SLOTS = [0xC080 + 0x100 * i for i in range(7)]; SH = 0xC200
    GL = dict(nr51=0xC106, acc=0xC103, tempo=0xC102, skip=0xC104, queue=0xC105)
    BASE = 0xC101; SKIPB = {0x1A, 0x24}

pb = PyBoy(ROM, window='null', sound_emulated=True)
rf = pb.register_file; mem = pb.memory
M = kmodel.Driver(G)
st = dict(k=0, inupd=False, reinj=False, ext=[], emutrig=[], nerr=0, intplays=[])

def snap_compare():
    errs = []
    for c, a in enumerate(SLOTS):
        for o in range(0x25):
            if o in SKIPB: continue
            e = mem[a + o]; m = M.t[c].m[o]
            if e != m: errs.append(f'slot{c}+{o:02X} emu {e:02X} model {m:02X}')
    for i in range(0x14):
        if mem[SH + i] != M.sh[i]: errs.append(f'shadow+{i:02X} emu {mem[SH + i]:02X} model {M.sh[i]:02X}')
    for k, a in GL.items():
        mv = {'nr51': M.nr51, 'acc': M.acc, 'tempo': M.tempo, 'skip': M.skip,
              'parity': M.parity, 'queue': M.queue}[k]
        if mem[a] != mv: errs.append(f'{k} emu {mem[a]:02X} model {mv:02X}')
    if mem[0xFF25] != M.nr51 and 0xFF25 in M.hw and mem[0xFF25] != M.hw[0xFF25]:
        errs.append(f'NR51 hw emu {mem[0xFF25]:02X} model {M.hw[0xFF25]:02X}')
    if any(M.wave) and not (M.hw.get(0xFF1A, 0) & 0x80):
        ew = bytes(mem[0xFF30 + i] for i in range(16))
        if ew != bytes(M.wave): errs.append(f'wave emu {ew.hex()} model {bytes(M.wave).hex()}')
    return errs

def on_update(ctx):
    if st['reinj']:
        st['reinj'] = False; return
    st['inupd'] = True
    k = st['k']
    # game's own requests since the last tick
    for sid in st['ext']: M.play(sid)
    st['ext'] = []
    errs = snap_compare()
    et = sorted(st['emutrig']); mt = sorted(x for x in M.trig if x[0] == k)
    if k > 0 and et != mt: errs.append(f'triggers emu {et} model {mt}')
    st['emutrig'] = []
    if errs:
        st['nerr'] += 1
        if st['nerr'] <= 5: print(f'tick {k}:', '; '.join(errs[:8]))
    while pokes and pokes[0][0] <= k:
        _, a, v = pokes.pop(0); mem[a] = v
    M.pause = mem[0xC012]
    if game == 'mm': M.engine = mem[0xC10D]; M.course = mem[0xC018]
    st['k'] = k + 1
    if inj and inj[0][0] <= k:
        _, sid = inj.pop(0)
        if game == 'mm' and sid == 0x11 and mem[0xC018] == 0: mem[0xC018] = 1; M.course = 1
        M.play(sid)
        sp = rf.SP - 2; mem[sp] = rf.PC & 255; mem[sp + 1] = rf.PC >> 8; rf.SP = sp
        rf.A = sid; rf.PC = PLAY; st['reinj'] = True; st['skipreq'] = True
    M.update()

def on_play(ctx):
    if st.get('skipreq'):
        st['skipreq'] = False; return
    if st['inupd']: st['intplays'].append((st['k'], rf.A))
    else: st['ext'].append(rf.A)

def on_after(ctx): st['inupd'] = False
def on_trig(ctx): st['emutrig'].append((st['k'], mem[BASE]))

pb.hook_register(BANK, UPD, on_update, None)
pb.hook_register(BANK, PLAY, on_play, None)
pb.hook_register(BANK, TRIG, on_trig, None)
pb.hook_register(0, ISR_AFTER, on_after, None)
while st['k'] < NT:
    pb.tick(60)
print(f'{game} {sys.argv[3]}: {st["k"]} ticks, {st["nerr"]} ticks with mismatches, '
      f'{len(st["intplays"])} internal plays, {len(M.trig)} triggers')
