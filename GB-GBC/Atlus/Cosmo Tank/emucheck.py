"""Run the rebuilt driver (verify/harness.gb) in PyBoy and compare every sound-register write,
tick by tick, with tools/model.py.  usage: python emucheck.py <Cosmo Tank rom> [random_ticks=20000] [seed=1990]
(seed 1990 also runs the fixed cases)"""
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'tools'))
from pyboy import PyBoy
from sm83 import decode
from ct import Rom, headers
from model import Model

rom = Rom(sys.argv[1])
RANDOM_TICKS = int(sys.argv[2]) if len(sys.argv) > 2 else 20000
SEED = int(sys.argv[3]) if len(sys.argv) > 3 else 1990
CASES = SEED == 1990   # the fixed cases run only with the default seed
# PyBoy's sound buffer grows without bound, so long random runs are split: run more seeds instead.
CODE = [(0x4000, 0x4265), (0x4285, 0x4466)]
NR52_TEST = 0x4198  # `bit 2, a` right after `ldh a, [rNR52]`

# ---------- script: tick -> ids pushed (rst $30 order) ----------
hdr = headers(rom)
music = [s for s, a, tr in hdr if tr and all(t < 4 for t, p in tr)]
sfx = [s for s, a, tr in hdr if tr and all(t >= 4 for t, p in tr)]
allids = list(range(1, 36))


def dry_len(sid, cap):
    """frames until all tracks of sid end (model alone), capped"""
    m = Model(rom)
    m.init()
    m.queue.append(sid)
    for i in range(cap):
        m.update()
        if i > 2 and not any(t.flags & 1 for t in m.t):
            return i + 1
    return cap


script = {}
t = 5
cases = []
# A: every id alone
for sid in (allids if CASES else []):
    script.setdefault(t, []).append(0)
    n = dry_len(sid, 3000)
    script.setdefault(t + 1, []).append(sid)
    cases.append(('alone', sid, t + 1, n))
    t += n + 40
# B: every music id with every SFX on top, plus pile-ups
for mid in (music if CASES else []):
    script.setdefault(t, []).append(0)
    script.setdefault(t + 1, []).append(mid)
    tt = t + 30
    for s in sfx:
        script.setdefault(tt, []).append(s)
        tt += 37 + (s * 13) % 50
    script.setdefault(tt, []).extend([sfx[0], sfx[3], sfx[5], sfx[7], sfx[9]])  # 5 pushes: one dropped
    tt += 200
    cases.append(('music+sfx', mid, t + 1, tt - t))
    t = tt
# C: random
rng = random.Random(SEED)
t0 = t
while t < t0 + RANDOM_TICKS:
    t += rng.randint(1, 120)
    k = rng.choice([1, 1, 1, 2, 3, 5])
    script[t] = [rng.choice(allids + [0] + sfx * 2) for _ in range(k)]
cases.append(('random', None, t0, t - t0))
END = t + 600

# ---------- emulator + model, compared tick by tick ----------
pb = PyBoy(os.path.join(HERE, 'harness.gb'), window='null', sound_emulated=True)  # needed for the NR52 channel bits
m = Model(rom)
m.init()
m.ch3_dac, m.ch3_on = True, True   # SndInit at boot triggers CH3 with the DAC on
m.bank0 = open(os.path.join(HERE, 'harness.gb'), 'rb').read()[:0x4000]
m.fix_volbug = os.environ.get('FIXBUG') == '1'
RAMCHECK = os.environ.get('RAMCHECK', '1') != '0'
st = {'tick': -1, 'bad': 0, 'nw': 0, 'nr52': 0, 'ram_bad': 0, 'ram_checked': 0}
cur, reads, first, ramfirst = [], [], [], []


def ramcheck(i, ram):
    bad = []
    g = [ram[0x8B], ram[0x8C], ram[0x8D] | ram[0x8E] << 8, list(ram[0x90:0x98])]
    mg = [m.cur, m.sweep_save, m.wave_ptr, m.pan]
    if g != mg:
        bad.append(('globals', g, mg))
    for n, t in enumerate(m.t):
        b = list(ram[16 * n:16 * n + 16])
        if not b[0] & 1 and not t.flags & 1:
            continue
        mine = [t.flags, t.timer, t.envcount, t.envpos & 255, t.envpos >> 8, t.atten, t.fine, t.transpose & 255,
                t.ptr & 255, t.ptr >> 8, t.length, t.nrx1, t.plo, t.phi, t.env & 255, t.env >> 8]
        if b != mine:
            bad.append(('track', n, b, mine))
        stk = [ram[0xA0 + 2 * n] | ram[0xA1 + 2 * n] << 8, ram[0xB0 + 3 * n], ram[0xB1 + 3 * n] | ram[0xB2 + 3 * n] << 8]
        ms = [m.retp[n] & 0xFFFF, m.loopc[n], m.loopp[n]]
        for k in range(3):
            if ms[k] and stk[k] != ms[k]:
                bad.append(('stack', n, stk, ms))
    if list(ram[0x98:0xA0]) != m.vol:
        bad.append(('vol', list(ram[0x98:0xA0]), m.vol))
    st['ram_checked'] += 1
    if bad:
        st['ram_bad'] += 1
        if len(ramfirst) < 3:
            ramfirst.append((i, bad))


def push(ids):
    for b in ids:
        c = pb.memory[0xDF80]
        if c + 1 < 5:
            pb.memory[0xDF80] = c + 1
            pb.memory[0xDF80 + c + 1] = b
        if len(m.queue) < 4:
            m.queue.append(b)


def on_update(ctx):
    global cur, reads
    i = st['tick']
    if i >= 0:                       # finish tick i
        m.nr52_reads = []
        mw = m.update()
        st['nw'] += len(cur)
        if mw != cur:
            st['bad'] += 1
            if len(first) < 5:
                first.append((i, cur, mw))
        if m.nr52_reads != reads:
            st['nr52'] += 1
        if RAMCHECK:
            ramcheck(i, [pb.memory[0xDF00 + k] for k in range(0xC8)])
    cur, reads = [], []
    st['tick'] = i = i + 1
    if i in script:
        push(script[i])


def mk_store(reg):
    def f(ctx):
        r = reg if reg is not None else pb.register_file.C
        if len(cur) < 20000:
            cur.append((r, pb.register_file.A))
        else:
            st['hang'] = st['tick']
    return f


def on_nr52(ctx):
    reads.append(bool(pb.register_file.A & 4))


n_hooks = 0
for a0, a1 in CODE:
    pc = a0
    while pc < a1:
        n, s, _ = decode(rom.d, 4 * 0x4000 + pc - 0x4000, pc)
        if s.startswith('ldh [$'):
            pb.hook_register(4, pc, mk_store(int(s[6:8], 16)), None); n_hooks += 1
        elif s == 'ldh [c], a':
            pb.hook_register(4, pc, mk_store(None), None); n_hooks += 1
        pc += n
pb.hook_register(4, 0x407C, on_update, None)
pb.hook_register(4, NR52_TEST, on_nr52, None)
last, frames = -2, 0
while st['tick'] < END and 'hang' not in st:
    pb.tick(1, False, False)
    frames = frames + 1 if st['tick'] == last else 0
    last = st['tick']
    if frames == 0 and last % 1000 == 0 and last > 0:
        # partial result: PyBoy 2.9 can freeze inside a CH3 register write (see the doc), so keep a trail
        print(f'  progress: tick {last}, mismatching ticks {st["bad"]}, NR52 {st["nr52"]}, RAM {st["ram_bad"]}', flush=True)
    if frames > 30 and last >= 0:
        st['hang'] = st['tick']
        break
if 'hang' not in st:
    pb.stop(save=False)

if 'hang' in st:
    i = st['hang']
    print(f'HANG in SndUpdate at tick {i}; recent script:', {k: v for k, v in script.items() if i - 400 <= k <= i})
    rf = pb.register_file
    print('pc', hex(rf.PC), 'sp', hex(rf.SP), 'bank', pb.memory[0x2100] if False else '', 'stack', [hex(pb.memory[rf.SP + k]) for k in range(8)], 'ie', pb.memory[0xFFFF], 'if', pb.memory[0xFF0F], 'lcdc', hex(pb.memory[0xFF40]), 'ram', bytes(pb.memory[0xDF00 + k] for k in range(0xC8)).hex())
for x in ramfirst:
    print('RAM', x)
print(f'hooks: {n_hooks} stores + NR52 read + SndUpdate; ticks: {st["tick"]}; register writes: {st["nw"]}')
print(f'cases: {sum(1 for c in cases if c[0]=="alone")} ids alone, '
      f'{sum(1 for c in cases if c[0]=="music+sfx")} songs with all SFX on top, random {RANDOM_TICKS} ticks (seed {SEED})')
print(f'mismatching ticks: {st["bad"]}; NR52 read mismatches: {st["nr52"]}; '
      f'RAM state mismatches: {st["ram_bad"]} of {st["ram_checked"]} ticks checked')
for i, w, mw in first:
    print('tick', i)
    for k in range(max(len(w), len(mw))):
        a = w[k] if k < len(w) else None
        b = mw[k] if k < len(mw) else None
        print('   emu', a and ('%02X=%02X' % a), ' model', b and ('%02X=%02X' % b), '' if a == b else '<<<')
