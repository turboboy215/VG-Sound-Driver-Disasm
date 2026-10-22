"""FFA song $03 never sets counter A before its outer loop_a: A starts at 0, so the body repeats 256 times (~122 min
for CH1/CH3), then CH1 falls through into CH3's data and executes $E8 (a halt slot on CH1): the driver spins in
musicOpCodeHalt ($4361) inside the frame interrupt and the game freezes.
  python verify/ffa_song03_hang.py          -> shortcut: set CH1's counter A to 1 so the last pass starts now
  python verify/ffa_song03_hang.py full     -> play from the start (about 7.3 million frames of emulation)"""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'tools'))
from pyboy import PyBoy
import g2
G = g2.Game('ffa')
pb = PyBoy(G.romfile, window='null', sound_emulated=False)
m = pb.memory
for f in range(900): pb.tick(1, False)
m[0xFF90] = 0; pb.tick(3, False); m[0xFF90] = 3; pb.tick(60, False)
FPS = 4194304 / 70224
full = len(sys.argv) > 1 and sys.argv[1] == 'full'
if not full:
    print('CH1 counter A was %d, ptr %04X -> forcing A = 1' % (m[0xC127], m[0xC11C] | m[0xC11D] << 8))
    m[0xC127] = 1
f = 0
while f < (500000 if full else 20000):
    pb.tick(30, False); f += 30
    if full and f % 36000 < 30: print('%5.1f min: CH1 counter A = %3d' % (f / FPS / 60, m[0xC127]), flush=True)
    pc = pb.register_file.PC
    if 0x4361 <= pc <= 0x4363:
        pb.tick(300, False)
        print('frozen in musicOpCodeHalt after %d frames (%.1f s): PC %04X, still %04X 5 s later; CH1 ptr %04X'
              % (f, f / FPS, pc, pb.register_file.PC, m[0xC11C] | m[0xC11D] << 8), flush=True)
        break
else: print('no freeze within %d frames' % f)
