"""Each SFX: model length (sum of frame counts, loops expanded) vs frames the real driver keeps CH1/CH4 busy."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'tools'))
from pyboy import PyBoy
import ffl1parse as P
import io
def model(a, noise):
    cnt = 0; t = 0
    for _ in range(10000):
        d = P.rb(a)
        if d & 0xF0 == 0xE0: cnt = d & 15; a += 1; continue
        if d >= 0xF0:
            cnt = (cnt - 1) & 0xFF
            a = P.rw(a + 1) if cnt else a + 3; continue
        if d == 0: return t
        t += d; a += 3 if noise else 6
pb = PyBoy(P.ROMF, window='null', sound_emulated=False)
m = pb.memory
for f in range(600): pb.tick(1, False)
m[0xFFE0] = 0; pb.tick(8, False)
st = io.BytesIO(); pb.save_state(st); ok = True
for i in range(1, 37):
    st.seek(0); pb.load_state(st)
    m[0xFFE4] = i
    pb.tick(1, False)
    tone = noise = None
    for f in range(1, 3000):
        if tone is None and not (m[0xCE00] & 1): tone = f
        if noise is None and not m[0xCEC7]: noise = f
        if tone and noise: break
        pb.tick(1, False)
    mt, mn = model(P.rw(0x6BC7 + 2 * i - 2), 0), model(P.rw(0x6C0F + 2 * i - 2), 1)
    good = (tone, noise) == (mt + 1, mn + 1)
    ok &= good
    print('sfx %2d tone %4d frames (model %4d)  noise %4d (model %4d) %s' % (i, tone - 1, mt, noise - 1, mn, '' if good else '<-- differs'))
print('ALL OK' if ok else 'FAIL')
