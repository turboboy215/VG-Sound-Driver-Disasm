"""Compare every note byte the real FFL1 driver reads (PyBoy) with the model walk in tools/ffl1parse.py."""
import os, sys, io
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'tools'))
from pyboy import PyBoy
import ffl1parse as P
pb = PyBoy(P.ROMF, window='null', sound_emulated=False)
for f in range(600): pb.tick(1, False)
st = io.BytesIO(); pb.save_state(st)
m = pb.memory
S = {'tick': 0, 'log': [[], [], []]}
def ontick(ctx): S['tick'] += 1
def onnote(ctx):
    ch = m[0xFFE9]; base = 0xCE00 + 0x20 * ch
    p = (m[base + 2] | m[base + 3] << 8) - 1
    S['log'][ch].append((S['tick'], p))
pb.hook_register(7, 0x40CD, ontick, None)
pb.hook_register(7, 0x44F7, onnote, None)
TICKS = int(os.environ.get('VTICKS', '6000'))
songs = P.songs(); allok = True; total = 0
for n in range(1, P.NSONG):
    st.seek(0); pb.load_state(st)
    m[0xFFE0] = 0; pb.tick(8, False)
    m[0xFFE0] = n
    S['tick'] = 0; S['log'] = [[], [], []]
    f = 0
    while S['tick'] < TICKS and f < 400000:
        pb.tick(1, False); f += 1
        if m[0xFFE0] != n: print('  game changed song at frame', f); break
    res = []
    for ch in range(3):
        drv = S['log'][ch]
        if not drv: res.append('%s none' % P.CHN[ch]); continue
        t0 = drv[0][0]
        drv = [(t - t0, a) for t, a in drv if t - t0 < TICKS - 200]
        model = [(t, a) for t, a, k, v in P.play(songs[n][ch], maxticks=TICKS) if k == 'note'][:len(drv)]
        ok = drv == model and len(drv) > 0; allok &= ok; total += len(drv)
        if ok: res.append('%s %d ok' % (P.CHN[ch], len(drv)))
        else:
            i = next((i for i in range(min(len(drv), len(model))) if drv[i] != model[i]), min(len(drv), len(model)))
            res.append('%s MISMATCH #%d drv=%s model=%s' % (P.CHN[ch], i, drv[i] if i < len(drv) else None, model[i] if i < len(model) else None))
    print('song %2d (%d frames): %s' % (n, f, ' | '.join(res)))
print('ALL OK' if allok else 'FAIL', total, 'notes')
