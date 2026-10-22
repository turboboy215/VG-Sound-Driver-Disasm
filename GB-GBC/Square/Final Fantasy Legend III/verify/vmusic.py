"""Compare every note the real driver reads (PyBoy) with the model walk in tools/ffl3parse.py."""
import os, sys, io
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'tools'))
from pyboy import PyBoy
import ffl3parse as P
ROMF = os.environ.get('FFL3_ROM', 'Final Fantasy Legend III (U) [!].gb')
pb = PyBoy(ROMF, window='null', sound_emulated=False)
for f in range(600): pb.tick(1, False)
st = io.BytesIO(); pb.save_state(st)
m = pb.memory; R = pb.register_file
state = {'tick': 0, 'log': [[], [], [], []]}
def ontick(ctx): state['tick'] += 1
def onnote(ch):
    def h(ctx):
        de = (R.D << 8 | R.E) - 1
        state['log'][ch].append((state['tick'] - 1, de))
    return h
pb.hook_register(0x0F, 0x41F9, ontick, None)
for ch, a in enumerate((0x4224, 0x428B, 0x42FC, 0x435C)): pb.hook_register(0x0F, a, onnote(ch), None)
songs = P.songs()
TICKS = int(os.environ.get('VTICKS', '6000'))
allok = True
for n in range(1, 21):
    st.seek(0); pb.load_state(st)
    m[0xFFBA] = 0; pb.tick(2, False)
    state['tick'] = 0; state['log'] = [[], [], [], []]
    m[0xFFBA] = n
    f = 0
    while state['tick'] < TICKS and f < 200000:
        pb.tick(1, False); f += 1
    res = []
    for ch in range(4):
        model = [(t, a) for t, a, k, v, _ in P.play(songs[n - 1][ch], ch, maxticks=TICKS) if k == 'note']
        drv = [x for x in state['log'][ch] if x[0] < TICKS - 300]
        model = model[:len(drv)]
        ok = drv == model
        allok &= ok
        if not ok:
            i = next((i for i in range(min(len(drv), len(model))) if drv[i] != model[i]), None)
            res.append('%s MISMATCH at %s drv=%s model=%s' % (P.CHN[ch], i, drv[i] if i is not None else None, model[i] if i is not None else None))
        else:
            res.append('%s %d notes ok' % (P.CHN[ch], len(drv)))
    print('song %2d (%d ticks, %d frames): %s' % (n, state['tick'], f, ' | '.join(res)))
print('ALL OK' if allok else 'FAIL')
