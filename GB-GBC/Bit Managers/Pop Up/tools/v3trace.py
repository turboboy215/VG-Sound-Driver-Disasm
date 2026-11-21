"""Version-3 check: run the real driver in PyBoy and check the data walk (lighter verification).

usage: v3trace.py <game> <asm-json> <rom> [ticks]

A harness (written over the game's bank-0 start-up code at $0150; the RST vectors stay) calls
SndInit, then per test: StopAll, start a song routine or PlaySfx, and SndUpdate once per loop.
At every tick it checks, for each active page, that the saved stream pointer (fields $02/$03)
and the order position ($00/$01) fall on items of the data walk, and that the drum position
falls on a drum-pattern byte. It also reports how long each song runs before all three music
pages stop (or that it is still running = it loops).
"""
import sys, os, json, subprocess, tempfile, warnings
warnings.filterwarnings('ignore')
from pyboy import PyBoy

game, jpath, rom_path = sys.argv[1], sys.argv[2], sys.argv[3]
NT = int(sys.argv[4]) if len(sys.argv) > 4 else 6000
M = json.load(open(jpath))
L, R = M['labels'], M['ram']
bank = M['bank']
pages = M['pages']
stream = set(M['stream'])
order = set(M['order'])
drumpat = set(M['drumpat']) | {a + 1 for a in M['drumpat2']}

HARN = f'''
SECTION "h", ROM0[$0150]
Harness:
\tdi
\tld sp, $CFF0
\txor a
\tldh [$FFFF], a
\tld [$D000], a
\tld a, {bank}
\tld [$2000], a
\tcall ${L['SndInit']:04X}
Loop:
\tld a, [$D000]
\tand a
\tjr z, .tick
\tcall ${L['StopAll']:04X}
\tld a, [$D000]
\tcp 1
\tjr nz, .sfx
\tld hl, $D002
\tld a, [hli]
\tld h, [hl]
\tld l, a
\tld de, .done
\tpush de
\tjp hl
.sfx\tld a, [$D001]
\tcall ${L['PlaySfx']:04X}
.done\txor a
\tld [$D000], a
\tld a, [$D004]
\tand a
\tjr z, .tick
\tld [${R.get('wStereo', 0xD010):04X}], a
.tick\tcall ${L['SndUpdate']:04X}
TickDone::
\tnop
\tjr Loop
'''
tmp = tempfile.mkdtemp()
open(os.path.join(tmp, 'h.asm'), 'w').write(HARN)
subprocess.check_call(['rgbasm', '-o', os.path.join(tmp, 'h.o'), os.path.join(tmp, 'h.asm')])
subprocess.check_call(['rgblink', '-t', '-n', os.path.join(tmp, 'h.sym'), '-o', os.path.join(tmp, 'h.gb'),
                       os.path.join(tmp, 'h.o')])
h = open(os.path.join(tmp, 'h.gb'), 'rb').read()
sym = {l.split()[1]: int(l.split()[0].split(':')[1], 16) for l in open(os.path.join(tmp, 'h.sym'))
       if l.strip() and not l.startswith(';')}
end = sym['TickDone'] + 4
r = bytearray(open(rom_path, 'rb').read())
r[0x150:end] = h[0x150:end]
r[0x100:0x104] = bytes([0x00, 0xC3, 0x50, 0x01])
hp = os.path.join(tmp, 'harness.gb')
open(hp, 'wb').write(r)

pb = PyBoy(hp, window='null')
mem = pb.memory
st = {'tick': -1, 'done': False}
problems = []


def w(a):
    return mem[a] | (mem[a + 1] << 8)


def check(test):
    for i, pg in enumerate(pages):
        base = pg << 8
        if mem[base + 0x10] == 0:
            continue
        p = w(base + 2)
        if p not in stream:
            problems.append('%s tick %d page %02X: stream pointer %04X not on an item' % (test, st['tick'], pg, p))
        if i < 3 and mem[base + 0x10] and test.startswith('song'):
            o = w(base + 0)
            if o not in order and (o - 2) not in order:
                problems.append('%s tick %d page %02X: order position %04X not in an order list' % (test, st['tick'], pg, o))
    if 'wDrumsOn' in R and mem[R['wDrumsOn']]:
        a = ((mem[R['wDrumPatHi']] << 8) | mem[R['wDrumPatLo']]) + mem[R['wDrumPos']]
        if a not in drumpat:
            problems.append('%s tick %d: drum pattern position %04X not on a pattern byte' % (test, st['tick'], a))


tests = [('song%d' % (i + 1), 1, a) for i, a in enumerate(M['songs'])] + \
        [('sfx%d' % (i + 1), 2, i + 1) for i in range(M['sfx_count'])]
cur = {'i': -1, 't0': 0, 'end': None, 'name': None}
results = []
TL = {}


def start_next():
    cur['i'] += 1
    if cur['i'] >= len(tests):
        st['done'] = True
        return
    name, op, arg = tests[cur['i']]
    cur.update(t0=st['tick'] + 1, end=None, name=name)
    if op == 1:
        mem[0xD002] = arg & 0xFF
        mem[0xD003] = arg >> 8
    else:
        mem[0xD001] = arg
    mem[0xD004] = 1
    mem[0xD000] = op


def hook(_):
    if st['done']:
        return
    st['tick'] += 1
    t = st['tick']
    if cur['name']:
        check(cur['name'])
        el = t - cur['t0']
        musical = cur['name'].startswith('song')
        idx = (0, 1, 2) if musical else (3,)
        busy = any(mem[(pages[k] << 8) + 0x10] for k in idx) or (musical and mem[(pages[3] << 8) + 0x10])
        lim = NT if musical else 1500
        if not busy or el >= lim:
            results.append((cur['name'], el if not busy else None))
            start_next()
    else:
        start_next()


pb.hook_register(0, sym['TickDone'], hook, None)
frames = 0
while not st['done'] and frames < 400000:
    pb.tick(1, False)
    frames += 1
pb.stop(save=False)
for p in problems[:30]:
    print('PROBLEM', p)
print('%s: %d tests, %d ticks, %d problems' % (game, len(results), st['tick'], len(problems)))
print('lengths:', ', '.join('%s %s' % (n, ('%d' % e) if e is not None else 'runs') for n, e in results))
sys.exit(1 if problems else 0)
