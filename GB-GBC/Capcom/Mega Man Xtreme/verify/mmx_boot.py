from pyboy import PyBoy
import sys
p = PyBoy('../mmx.gbc', window='null', sound_emulated=False, cgb=True)
log = []
def on_play(ctx):
    log.append((p.frame_count, 'bank', p.memory[0xFFF8], 'id', '%02X' % p.register_file.A))
for b in (2, 3, 4):
    p.hook_register(b, 0x40F6, on_play, None)
N = int(sys.argv[1])
for f in range(N):
    if f % 240 == 200: p.button('start')
    p.tick()
    if f % 600 == 0: p.screen.image.save('mmx_%05d.png' % f)
for l in log: print(l)
