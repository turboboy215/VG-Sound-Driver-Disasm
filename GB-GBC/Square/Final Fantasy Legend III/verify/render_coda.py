"""Render song 7 (credits) from 7:20 to its end with PyBoy's APU -> wav/song07_coda.wav."""
import os, wave, numpy as np
from pyboy import PyBoy
pb = PyBoy(os.environ.get('FFL3_ROM', 'Final Fantasy Legend III (U) [!].gb'), window='null', sound_emulated=True, sound_sample_rate=48000)
for f in range(600): pb.tick(1, False)
m = pb.memory
m[0xFFBA] = 0; pb.tick(2, False); m[0xFFBA] = 7
FPS = 4194304 / 70224
start = int(440 * FPS); frames = []
f = 0
while True:
    pb.tick(1, False, True); f += 1
    if f >= start: frames.append(pb.sound.ndarray.copy())
    if m[0xCB05] == 0xFF and m[0xCB1D] == 0xFF and m[0xCB35] == 0xFF and f > start: break
for _ in range(int(3 * FPS)):
    pb.tick(1, False, True); frames.append(pb.sound.ndarray.copy())
a = np.concatenate(frames).astype(np.int16)
print('end at frame', f, '= %.1f s' % (f / FPS), a.shape, a.dtype, int(np.abs(a).max()))
x = a.astype(np.float64)
y = np.zeros_like(x); R = 0.9974            # one-pole DC blocker (~20 Hz)
prev_x = x[0].copy(); prev_y = np.zeros(2)
for i in range(len(x)):
    prev_y = x[i] - prev_x + R * prev_y; prev_x = x[i]; y[i] = prev_y
a = (y / np.abs(y).max() * 28000).astype(np.int16)
w = wave.open('wav/song07_coda_from_7m20s.wav', 'wb'); w.setnchannels(2); w.setsampwidth(2); w.setframerate(48000)
w.writeframes(a.tobytes()); w.close()
