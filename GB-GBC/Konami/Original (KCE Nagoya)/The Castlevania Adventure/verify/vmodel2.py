"""Tick-by-tick comparison of the later-variant driver model (tools/kmodel2.py) against PyBoy.
usage: vmodel2.py nem|cv2|bos TICKS id[@tick][,id@tick...][,!ADDR=VV@tick...]   (default first id at tick 30)
The game's own sound requests (PlaySoundFar, and StartFadeFar in Belmont's Revenge) are dropped so the
injected sounds run undisturbed; set VGAME=1 to let them through (the model then mirrors them).
Injects PlaySound calls at the given driver ticks (and pokes game RAM), then compares every tick:
all 7 tracks byte for byte, register shadows, driver globals, NR51, wave RAM (CH3 off) and the
exact set of triggers per tick."""
import sys, os
os.environ['SDL_VIDEODRIVER'] = 'dummy'
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'tools'))
from pyboy import PyBoy
import kdata, kmodel2

game = sys.argv[1]; NT = int(sys.argv[2])
inj = []; pokes = []
for x in sys.argv[3].split(','):
    i, _, t = x.partition('@')
    if i.startswith('!'):
        a, v = i[1:].split('='); pokes.append((int(t), int(a, 16), int(v, 16))); continue
    inj.append((int(t) if t else 30, int(i, 16)))
pokes.sort(); inj.sort()
G = kdata.PROFILES[game]
if game == 'nem':
    BANK, UPD, PLAY, TRIG, ISR_AFTER = 7, 0x41BD, 0x5B6E, 0x47AE, 0x023F
    TRK = 0xC180; NCMP = 0x24; SH = 0xC2A4; BASE = 0xC1A8
    GL = dict(nr51=0xC1AD, acc=0xC1AA, tempo=0xC1A9, skip=0xC1AB, queue=0xC1AC, sweep=0xC1AE,
              lock=0xC1B4, lockhi=0xC1B5, fadeid=0xC1B6, fadecnt=0xC1B7, fadelvl=0xC1B8,
              reqid=0xC1AF, reqprio=0xC1B0, hold=0xC1B3)
    PAUSE = lambda m: m[0xC013]
    FADE = 0xC1B6
    GAMEREQ = [(0, 0x035F)]; RET = 0x0340      # PlaySoundFar -> a ret
elif game == 'bos':
    BANK, UPD, PLAY, TRIG, ISR_AFTER = 7, 0x42F7, 0x40E3, 0x4B06, 0x0F15
    TRK = 0xC080; NCMP = 0x36; SH = 0xC1B6; BASE = 0xC0BA
    GL = dict(nr51=0xC0BF, acc=0xC0BC, tempo=0xC0BB, skip=0xC0BD, queue=0xC0BE, sweep=0xC0C0,
              fadeid=0xC0C8, fadecnt=0xC0C9, fadelvl=0xC0CA, reject=0xC0CB, reqid=0xC0C1,
              reqprio=0xC0C2, hold=0xC0C5)
    PAUSE = lambda m: m[0xD81D] & 1
    FADE = 0xC0C8
    GAMEREQ = [(0, 0x0F1F), (0, 0x0F68)]; RET = 0x0F00   # PlaySoundFar, StartFadeFar -> a ret
else:
    BANK, UPD, PLAY, TRIG, ISR_AFTER = 7, 0x42F6, 0x40E3, 0x4950, 0x3549
    TRK = 0xC080; NCMP = 0x36; SH = 0xC1B6; BASE = 0xC0BA
    GL = dict(nr51=0xC0BF, acc=0xC0BC, tempo=0xC0BB, skip=0xC0BD, queue=0xC0BE, sweep=0xC0C0,
              fadeid=0xC0C8, fadecnt=0xC0C9, fadelvl=0xC0CA, reject=0xC0CB, reqid=0xC0C1,
              reqprio=0xC0C2, hold=0xC0C5)
    PAUSE = lambda m: m[0xC88B] & 1
    FADE = 0xC0C8
    GAMEREQ = [(0, 0x3553), (0, 0x358D)]; RET = 0x3552   # PlaySoundFar, StartFadeFar -> a ret

pb = PyBoy(G['rom'], window='null', sound_emulated=True)
rf = pb.register_file; mem = pb.memory
M = kmodel2.Driver(G)
st = dict(extlog=[], k=0, inupd=False, reinj=False, ext=[], emutrig=[], nerr=0, intplays=[], fades=0)

def mval(k):
    if k == 'lock': return M.lock & 0xFF
    if k == 'lockhi': return M.lock >> 8
    return getattr(M, k)

def snap_compare():
    errs = []
    for c in range(7):
        a = TRK + 0x100 * c
        for o in range(NCMP):
            e = mem[a + o]; m = M.t[c].m[o]
            if e != m: errs.append(f'trk{c}+{o + 0x80:02X} emu {e:02X} model {m:02X}')
    for i in range(0x14):
        if mem[SH + i] != M.sh[i]: errs.append(f'shadow+{i:02X} emu {mem[SH + i]:02X} model {M.sh[i]:02X}')
    for k, a in GL.items():
        if mem[a] != mval(k): errs.append(f'{k} emu {mem[a]:02X} model {mval(k):02X}')
    if 0xFF25 in M.hw and mem[0xFF25] != M.hw[0xFF25]:
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
    for sid in st['ext']: M.play(sid); st['extlog'].append((k, sid))   # the game's own requests
    st['ext'] = []
    f = mem[FADE]
    if f and f != M.fadeid:                  # fade started by the game (direct RAM write)
        M.fadeid = f; st['fades'] += 1
    errs = snap_compare()
    et = sorted(st['emutrig']); mt = sorted(x for x in M.trig if x[0] == k)
    if k > 0 and et != mt: errs.append(f'triggers emu {et} model {mt}')
    st['emutrig'] = []
    if errs:
        st['nerr'] += 1
        if st['nerr'] <= 5: print(f'tick {k}:', '; '.join(errs[:8]))
    while pokes and pokes[0][0] <= k:
        _, a, v = pokes.pop(0); mem[a] = v
        if os.environ.get("VDEBUG"): print("poke", hex(a), hex(v), "->", hex(mem[a]), "tick", k)
        if a == FADE: M.fadeid = v
    M.pause = PAUSE(mem)
    if game == 'nem': M.gamevar = mem[0xC081]
    st['k'] = k + 1
    if inj and inj[0][0] <= k:
        _, sid = inj.pop(0)
        M.play(sid)
        sp = rf.SP - 2; mem[sp] = rf.PC & 255; mem[sp + 1] = rf.PC >> 8; rf.SP = sp
        rf.A = sid; rf.PC = PLAY; st['reinj'] = True; st['skipreq'] = True
    M.update()

def on_play(ctx):
    if st.get('skipreq'):
        st['skipreq'] = False; return
    if st['inupd']: st['intplays'].append((st['k'], rf.A))
    else: st['ext'].append(rf.A)

QUIET = os.environ.get('VGAME') != '1'   # by default the game's own sound requests are dropped
def on_gamereq(ctx):
    if QUIET: st['dropped'] = st.get('dropped', 0) + 1; rf.PC = RET

def on_after(ctx): st['inupd'] = False
def on_trig(ctx): st['emutrig'].append((st['k'], mem[BASE]))

pb.hook_register(BANK, UPD, on_update, None)
pb.hook_register(BANK, PLAY, on_play, None)
pb.hook_register(BANK, TRIG, on_trig, None)
pb.hook_register(0, ISR_AFTER, on_after, None)
for bk, a in GAMEREQ: pb.hook_register(bk, a, on_gamereq, None)
frames = 0
while st['k'] < NT:
    pb.tick(60); frames += 60
print(f'{game} {sys.argv[3]}: {st["k"]} ticks, {st["nerr"]} ticks with mismatches, '
      f'{len(st["intplays"])} internal plays, {len(M.trig)} triggers, {frames} frames, game fades {st["fades"]}, dropped {st.get("dropped", 0)}, '
      f'game requests {" ".join(f"{s:02X}@{t}" for t, s in st["extlog"][:6])}')
