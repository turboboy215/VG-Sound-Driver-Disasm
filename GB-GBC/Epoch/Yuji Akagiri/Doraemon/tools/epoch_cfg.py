"""Per-game layout of the Epoch sound driver (Doraemon / Dragon Slayer I).
ROMs are read from the folder above tools (override with EPOCH_ROMDIR)."""
import os
ROMDIR = os.environ.get('EPOCH_ROMDIR', os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

GAMES = {
    'dora': dict(
        name='Doraemon (J)', rom='Doraemon (J).gb', bank=7, ver=1,
        start=0x4000, end=0x5AB6,          # end = first byte after the sound block
        wave=(0x4041, 0x4051),
        code_end=0x472B,
        freq=0x472B, inst=0x47E5, drum=0x4928, music=0x4958, sfx=0x596A,
        ram=0xC700, struct=0x1E, volsteps=8,
    ),
    'ds': dict(
        name='Dragon Slayer I (J)', rom='Dragon Slayer I (J).gb', bank=0, ver=2,
        start=0x7038, end=0x7FFE,
        wave=(0x7079, 0x7089),
        code_end=0x7788,
        freq=0x7788, inst=0x7842, drum=0x78E9, music=0x7919, sfx=0x7E7A,
        ram=0xD100, struct=0x20, volsteps=4,
    ),
}


def load(key):
    g = dict(GAMES[key])
    data = open(os.path.join(ROMDIR, g['rom']), 'rb').read()
    base = 0 if g['bank'] == 0 else (g['bank'] - 1) * 0x4000
    g['rd'] = lambda a, n=1: data[base + a: base + a + n]
    g['b'] = lambda a: data[base + a]
    g['w'] = lambda a: data[base + a] | (data[base + a + 1] << 8)
    g['data'] = data
    g['base'] = base
    return g
