"""Version-4 check: run the real driver in PyBoy and check the data walk (lighter verification).

usage: v4trace.py <asm-json> <rom> [ticks]

A harness (written over the game's bank-0 start-up code at $0150; the RST vectors stay) calls
SndInit (and sets wStereo), then per test: StopAll, start a song routine or PlaySfx (through the
API entry, so the game's glue in the bank is included), and SndUpdate once per loop.
At every tick it checks, for each active page, that the saved stream pointer (fields $02/$03)
and the order position ($00/$01) fall on items of the data walk, and that the drum position
falls on a drum-pattern byte. It also reports how long each song runs before all three music
pages stop (or that it is still running = it loops).
"""
import sys, os, json, subprocess, tempfile, warnings
warnings.filterwarnings('ignore')
from pyboy import PyBoy

jpath, rom_path = sys.argv[1], sys.argv[2]
NT = int(sys.argv[3]) if len(sys.argv) > 3 else 6000
M = json.load(open(jpath))
game = M['game']
A = M['api']
TAIL = 600                     # ticks checked after a one-shot song ends (drums keep running)
ACT = 0x27                     # field: page active (SFX page: SFX id)
L, R = M['labels'], M['ram']
bank = M['bank']
pages = M['pages']
stream = set(M['stream'])
order = set(M['order'])
drumpat = set(M['drumpat']) | {a + 1 for a in M['drumpat2']}
drumcover = drumpat

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
\tcall ${A['init']:04X}
Loop:
\tld a, [$D000]
\tand a
\tjr z, .tick
\tcall ${A['stopall']:04X}
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
\tcall ${A['playsfx']:04X}
.done\txor a
\tld [$D000], a
\tld a, [$D004]
\tand a
\tjr z, .tick
\tld [${R.get('wStereo', 0xD010):04X}], a
.tick\tcall ${A['update']:04X}
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
        if mem[base + ACT] == 0:
            continue
        p = w(base + 2)
        if p not in stream:
            problems.append('%s tick %d page %02X: stream pointer %04X not on an item' % (test, st['tick'], pg, p))
        if i < 3 and mem[base + ACT] and not test.startswith('sfx'):
            o = w(base + 0)
            if o not in order and (o - 2) not in order:
                problems.append('%s tick %d page %02X: order position %04X not in an order list' % (test, st['tick'], pg, o))
    # drum sequencer: every byte it has read since the last tick must be a pattern byte
    base = (mem[R['wDrumPatHi']] << 8) | mem[R['wDrumPat']]
    pos = mem[R['wDrumPos']]
    last = st.get('drum')
    st['drum'] = (base, pos)
    if mem[R['wDrumsOn']] and last and last != (base, pos) and pos:
        lb, lp = last
        rng = range(base + lp, base + pos) if (lb == base and pos > lp) else range(base, base + pos)
        for a in rng:
            if a not in drumcover:
                problems.append('%s tick %d: drum sequencer read %04X, not a pattern byte' % (test, st['tick'], a))
                break


tests = [(nm.lower(), 1, a) for nm, a in M['songs']] + \
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
    cur.update(t0=st['tick'] + 1, end=None, name=name, tail=None, ended=None, drums_after=False)
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
        musical = not cur['name'].startswith('sfx')
        idx = (0, 1, 2) if musical else (3,)
        busy = any(mem[(pages[k] << 8) + ACT] for k in idx) or (musical and mem[(pages[3] << 8) + ACT])
        if not musical and mem[R['wNoiseOn']]:
            busy = True                # noise-only SFX: until the noise sequence ends
        lim = NT if musical else 1500
        if cur.get('tail') is not None:
            # a one-shot song has ended: keep ticking (no StopAll) while the drums may still run
            cur['tail'] -= 1
            if mem[R['wDrumsOn']]:
                cur['drums_after'] = True
            if cur['tail'] <= 0:
                results.append((cur['name'], cur['ended'], cur.get('drums_after', False)))
                start_next()
        elif not busy and musical:
            cur['ended'] = el
            cur['tail'] = TAIL
        elif not busy or el >= lim:
            results.append((cur['name'], el if not busy else None, False))
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
print('lengths:', ', '.join('%s %s' % (n, ('%d' % e) if e is not None else 'runs') for n, e, _ in results))
da = [n for n, e, d in results if d]
if da:
    print('drums still running after the end (checked for %d ticks):' % TAIL, ', '.join(da))
sys.exit(1 if problems else 0)
