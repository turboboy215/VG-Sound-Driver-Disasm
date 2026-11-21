"""Tick-by-tick comparison of a driver model with the real driver in PyBoy.

usage: vmodel.py popup|bombjack <schedule> <ticks> [--quiet] [--cov]
  schedule: comma list of tick:op[:arg]  e.g. 0:1  or 0:5,10:3:2,500:4
  ops (Pop Up):    1 title music, 2 song 2, 3 sound <id>, 4 StopAll, 5 sound on (hSndOn = 1),
                   6 synthetic test streams (harness_popup.asm) on Ch1/Ch2
  ops (Bomb Jack): 1/6 song 1, 2/7 song 2, 8 song 3, 9 song 4, 10 song 5, 3 sfx <id>, 4 StopAll,
                   11 StartFade <speed> (FadeOutTable), 12 hGameFF82 = <v>, 13 hGameFFC0 = wGameC001 = <v>
The harness ROMs (build_harness.py) call the real driver once per loop; at TickDone the model
runs the same tick and these are compared: all four channel pages ($00-$3F), the driver's
globals, and the readable sound registers (NR11/21 duty, NR12, NR22, NR32 level, NR42, NR43, NR50, NR51).
On a mismatch the model is resynchronised from the emulator so that one error is reported once.
"""
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'tools'))
import warnings
warnings.filterwarnings('ignore')
from pyboy import PyBoy

GAME = sys.argv[1]
if GAME == 'popup':
    from popup_model import PopUpModel as Model
    ROM = os.path.join(os.path.dirname(__file__), 'popup_harness.gb')
    PAGES = (0xC1, 0xC2, 0xC3, 0xC4)
    EXTRA = list(range(0xFFDF, 0xFFF6)) + [0xC339]
    REGS = {0x11: 0xC0, 0x12: 0xFF, 0x16: 0xC0, 0x17: 0xFF, 0x1C: 0x60, 0x21: 0xFF, 0x22: 0xFF,
            0x24: 0xFF, 0x25: 0xFF}
else:
    from bombjack_model import BombJackModel as Model
    ROM = os.path.join(os.path.dirname(__file__), 'bombjack_harness.gb')
    PAGES = (0xC4, 0xC5, 0xC6, 0xC7)
    EXTRA = list(range(0xC318, 0xC339))
    REGS = {0x11: 0xC0, 0x12: 0xFF, 0x16: 0xC0, 0x17: 0xFF, 0x1C: 0x60, 0x21: 0xFF, 0x22: 0xFF,
            0x24: 0xFF, 0x25: 0xFF}
    REGS.update({0x30 + i: 0xFF for i in range(16)})

COV = {}
if '--cov' in sys.argv:
    for _n in ('command', 'table_cmd'):
        _o = getattr(Model, _n)
        def _w(self, h, a, de, *rest, _o=_o):
            COV[a] = COV.get(a, 0) + 1
            return _o(self, h, a, de, *rest)
        setattr(Model, _n, _w)

TICKDONE = int(open(ROM + '.tickdone').read(), 16)
sched = {}
for item in sys.argv[2].split(','):
    p = [int(x, 0) for x in item.split(':')]
    sched.setdefault(p[0], []).append(p[1:])
NT = int(sys.argv[3])
quiet = '--quiet' in sys.argv

rom = open(ROM, 'rb').read()  # harness ROM = original + harness/test data in free space
pb = PyBoy(ROM, window='null')
mem = pb.memory

state = {'tick': -1, 'model': None, 'mism': 0, 'pending': None, 'done': False, 'firstbad': None}


def snapshot():
    return bytearray(mem[0:0x10000])


def compare(model, t):
    bad = []
    for pg in PAGES:
        base = pg << 8
        for o in range(0x40):
            a, b = mem[base + o], model.m[base + o]
            if a != b:
                bad.append('%04X emu=%02X model=%02X' % (base + o, a, b))
    for a in EXTRA:
        if mem[a] != model.m[a]:
            bad.append('%04X emu=%02X model=%02X' % (a, mem[a], model.m[a]))
    for r, msk in REGS.items():
        if r in model.hw:
            e = mem[0xFF00 + r] & msk
            m = model.hw[r] & msk
            if r >= 0x30 and r < 0x40:
                continue
            if e != m:
                bad.append('NR%02X emu=%02X model=%02X' % (r, e, m))
    return bad


def apply(model, ops):
    for op in ops:
        if op[0] == 1:
            model.play_song(1) if GAME == 'popup' else model.play_song(1)
            if GAME == 'popup':
                model.hs(0xF5, 1)
        elif op[0] == 2:
            model.play_song(2)
            if GAME == 'popup':
                model.hs(0xF5, 1)
        elif op[0] == 3:
            model.play_sound(op[1])
        elif op[0] == 4:
            model.stop_all()
        elif op[0] == 5:
            if GAME == 'popup':
                model.hs(0xF5, 1)
        elif op[0] == 6 and GAME == 'popup':
            model.stop_all()
            model.start_music_ch(0xC1, 0x7F40)
            model.start_music_ch(0xC2, 0x7F48)
            model.hw_(0x25, 0xFF); model.hs(0xF1, 0xFF); model.hs(0xF5, 1)
        elif op[0] == 14 and GAME == 'bombjack':
            model.stop_all()
            model.sg(0xC31F, 0x44); model.sg(0xC320, 0x73); model.sg(0xC321, 0x0C); model.sg(0xC322, 0x74)
            model.start_music_ch(0xC4, 0x7B00)
            model.start_music_ch(0xC5, 0x7B0C)
            model.start_music_ch(0xC6, 0x7B12)
        elif op[0] == 12:
            model.m[0xFF82] = op[1]
        elif op[0] == 13:
            model.m[0xFFC0] = op[1]; model.m[0xC001] = op[1]
        elif op[0] == 11:
            model.start_fade(op[1], 0x5B75)
        elif op[0] >= 6:
            model.play_song(op[0] - 5)


def write_mailbox(ops):
    # only one op per tick supported by the harness
    op = ops[0]
    mem[0xDF01] = op[1] if len(op) > 1 else 0
    mem[0xDF00] = op[0]


def hook(ctx):
    try:
        hook_(ctx)
    except Exception as ex:
        import traceback
        traceback.print_exc()
        state['mism'] += 1
        state['done'] = True
        state['firstbad'] = state['tick']


def hook_(ctx):
    t = state['tick']
    if t == -1:
        state['model'] = Model(rom, snapshot())
    else:
        model = state['model']
        ops = sched.get(t)
        if ops:
            apply(model, ops)
        model.snd_tick()
        bad = compare(model, t)
        if bad:
            state['mism'] += 1
            if state['firstbad'] is None:
                state['firstbad'] = t
            if not quiet or state['mism'] <= 3:
                print('tick %d: %d diffs: %s' % (t, len(bad), '; '.join(bad[:12])))
            # resync so that one error doesn't cascade
            state['model'].m = snapshot()
    state['tick'] = t + 1
    if state['tick'] in sched:
        write_mailbox(sched[state['tick']])
    if state['tick'] >= NT:
        state['done'] = True


pb.hook_register(0 if TICKDONE < 0x4000 else 1, TICKDONE, hook, None)
frames = 0
while not state['done'] and frames < 200000:
    pb.tick(1, False)
    frames += 1
pb.stop(save=False)
if COV:
    print('commands executed:', ' '.join('%02X:%d' % kv for kv in sorted(COV.items())))
if state['tick'] < NT:
    print('ERROR: harness did not reach the requested tick count')
print('%s %s: %d ticks, %d mismatching ticks%s' % (GAME, sys.argv[2], state['tick'], state['mism'],
      '' if state['firstbad'] is None else ' (first at %d)' % state['firstbad']))
sys.exit(1 if state['mism'] or state['tick'] < NT else 0)
