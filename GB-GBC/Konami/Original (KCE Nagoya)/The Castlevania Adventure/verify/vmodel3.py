"""Tick-by-tick comparison of the Nemesis II driver model (tools/kmodel3.py) against PyBoy.
usage: vmodel3.py n2 TICKS id[@tick][,id@tick...][,!ADDR=VV@tick...]   (default first id at tick 30)
Ticks are driver updates (128 Hz timer). The game's own sound requests (PlaySoundFar $0283) are dropped
unless VGAME=1. Sounds are injected through PlaySoundFar from the timer ISR just before the update.
Compared every update: all 7 tracks ($80-$B7) byte for byte, the register shadows, the driver globals
$C0BB-$C0DB, NR51, wave RAM (CH3 off) and the exact set of triggers per update."""
import sys, os
os.environ['SDL_VIDEODRIVER'] = 'dummy'
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'tools'))
from pyboy import PyBoy
import kdata3, kmodel3

game = sys.argv[1]; NT = int(sys.argv[2])
inj = []; pokes = []
for x in sys.argv[3].split(','):
    i, _, t = x.partition('@')
    if i.startswith('!'):
        a, v = i[1:].split('='); pokes.append((int(t), int(a, 16), int(v, 16))); continue
    inj.append((int(t) if t else 30, int(i, 16)))
pokes.sort(); inj.sort()
G = kdata3.PROFILES[game]
ISR_CALL = 0x00C1            # call SndUpdate in the timer ISR (after the lock test)
PLAYFAR, RET = 0x0283, 0x0259
TRIG = {13: 0x4F50, 14: 0x4D66, 15: 0x4D55}
MIRROR = [kmodel3.FADE, kmodel3.RFADE, kmodel3.HOLD, kmodel3.PAUSE, 0xCC0E]   # written by the game

pb = PyBoy(G['rom'], window='null', sound_emulated=True)
rf = pb.register_file; mem = pb.memory
M = kmodel3.Driver(G)
st = dict(k=0, reinj=False, emutrig=[], nerr=0, dropped=0, fades=0, mine=False, bank=None)

def snap_compare():
    errs = []
    for c in range(7):
        a = 0xC080 + 0x100 * c
        for o in range(0x38):
            e = mem[a + o]; m = M.m[a + o]
            if e != m: errs.append(f'trk{c}+{o + 0x80:02X} emu {e:02X} model {m:02X}')
    for i in range(0x14):
        a = kmodel3.SH + i
        if mem[a] != M.m[a]: errs.append(f'shadow+{i:02X} emu {mem[a]:02X} model {M.m[a]:02X}')
    for a in range(0xC0BB, 0xC0DC):
        if mem[a] != M.m[a]: errs.append(f'{a:04X} emu {mem[a]:02X} model {M.m[a]:02X}')
    if 0xFF25 in M.hw and mem[0xFF25] != M.hw[0xFF25]:
        errs.append(f'NR51 hw emu {mem[0xFF25]:02X} model {M.hw[0xFF25]:02X}')
    if any(M.wave) and not (M.hw.get(0xFF1A, 0) & 0x80):
        ew = bytes(mem[0xFF30 + i] for i in range(16))
        if ew != bytes(M.wave): errs.append(f'wave emu {ew.hex()} model {bytes(M.wave).hex()}')
    return errs

def on_isr(ctx):
    if st['reinj']:
        st['reinj'] = False
        mem[0xC7A4] = st['bank']          # PlaySoundFar left bank 1/2 in the shadow; the update restores it
        return
    k = st['k']
    for a in MIRROR:
        if mem[a] != M.m[a]:
            if a == kmodel3.FADE: st['fades'] += 1
            M.m[a] = mem[a]
    errs = snap_compare()
    et = sorted(st['emutrig']); mt = sorted(x for x in M.trig if x[0] == k)
    if k > 0 and et != mt: errs.append(f'triggers emu {et} model {mt}')
    st['emutrig'] = []
    if errs:
        st['nerr'] += 1
        if st['nerr'] <= 5: print(f'tick {k}:', '; '.join(errs[:8]))
    while pokes and pokes[0][0] <= k:
        _, a, v = pokes.pop(0); mem[a] = v; M.m[a] = v
    st['k'] = k + 1
    if inj and inj[0][0] <= k:
        _, sid = inj.pop(0)
        if not mem[0xCC0E] & 1: M.play(sid)
        st['bank'] = mem[0xC7A4]
        sp = rf.SP - 2; mem[sp] = rf.PC & 255; mem[sp + 1] = rf.PC >> 8; rf.SP = sp
        rf.A = sid; rf.PC = PLAYFAR; st['reinj'] = True; st['mine'] = True
    M.update()

QUIET = os.environ.get('VGAME') != '1'
def on_playfar(ctx):
    if st['mine']:
        st['mine'] = False; return
    if QUIET:
        st['dropped'] += 1; rf.PC = RET
    else:
        if not mem[0xCC0E] & 1 and not mem[0xC78D] & 2: M.play(rf.A)   # main thread request

def mk_trig(bank):
    def h(ctx): st['emutrig'].append((st['k'], mem[kmodel3.BASE]))
    return h

pb.hook_register(0, ISR_CALL, on_isr, None)
pb.hook_register(0, PLAYFAR, on_playfar, None)
for b, a in TRIG.items(): pb.hook_register(b, a, mk_trig(b), None)
frames = 0
while st['k'] < NT:
    pb.tick(60); frames += 60
print(f'{game} {sys.argv[3]}: {st["k"]} ticks, {st["nerr"]} ticks with mismatches, {len(M.trig)} triggers, '
      f'{frames} frames, game fades {st["fades"]}, dropped {st["dropped"]}')
