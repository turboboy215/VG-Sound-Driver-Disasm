"""Play every song and effect on the harness ROM (built from the rebuilt sources) and check that
every ROM byte the sound code reads lies inside an item of the generated sources' data model.

usage: python3 harness/verify.py [frames_per_song]
needs: build/harness.gbc (harness/build.sh), build/model.json (tools/ppcgen.py)
"""
import json
import os
import sys
from collections import defaultdict

os.environ.setdefault('PYSDL2_DLL_PATH', '')
from pyboy import PyBoy

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(ROOT, 'tools'))
import ppcparse as P

FRAMES = int(sys.argv[1]) if len(sys.argv) > 1 else 3600
SFX_FRAMES = 600
ROMFILE = os.path.join(ROOT, 'build', 'harness.gbc')
model = json.load(open(os.path.join(ROOT, 'build', 'model.json')))
rom = open(ROMFILE, 'rb').read()
P.ROM = rom

BOX = 0xDE00
# which register holds the pointer for each read opcode
READ_OPS = {0x0A: 'BC', 0x1A: 'DE', 0x2A: 'HL', 0x3A: 'HL', 0x7E: 'HL', 0x46: 'HL', 0x4E: 'HL',
            0x56: 'HL', 0x5E: 'HL', 0x66: 'HL', 0x6E: 'HL', 0xBE: 'HL', 0x86: 'HL', 0x8E: 'HL'}
HOOK_RANGES = {'home': [(0x128D, 0x1B16)], '20': [(0x583C, 0x5857), (0x528E, 0x52A2)],
               '21': [(0x4000, 0x48E5)], '7F': [(0x4942, 0x4CCF)]}

# data-item lookup: (bank, addr) -> item start
item_of = {}
for key, L in model.items():
    bk = L['bank']
    for a, l, kind in L['items']:
        if kind == 'code':
            continue
        for j in range(l):
            item_of[(bk, a + j)] = a

pyboy = PyBoy(ROMFILE, window='null', sound_emulated=False)
pyboy.set_emulation_speed(0)
reads = defaultdict(set)          # test name -> set of (bank, addr)
current = ['boot']


def make_cb(reg):
    def cb(_):
        rf = pyboy.register_file
        if reg == 'HL':
            a = rf.HL
        elif reg == 'BC':
            a = (rf.B << 8) | rf.C
        else:
            a = (rf.D << 8) | rf.E
        if a < 0x4000:
            reads[current[0]].add((0, a))
        elif a < 0x8000:
            reads[current[0]].add((pyboy.memory[0xFFA3], a))
    return cb


nhooks = 0
for key, ranges in HOOK_RANGES.items():
    L = model[key]
    bk = L['bank']
    for a, l, kind in L['items']:
        if kind != 'code' or not any(s <= a < e for s, e in ranges):
            continue
        off = a if bk == 0 else bk * 0x4000 + a - 0x4000
        op = rom[off]
        if op in READ_OPS:
            pyboy.hook_register(bk if a >= 0x4000 else 0, a, make_cb(READ_OPS[op]), None)
            nhooks += 1

for _ in range(30):
    pyboy.tick()
import io
base = io.BytesIO()
pyboy.save_state(base)


def run(name, cmd, arg, frames, ptr=None, ctype=0):
    base.seek(0)
    pyboy.load_state(base)
    current[0] = name
    pyboy.memory[BOX + 4] = ctype
    pyboy.memory[BOX + 1] = arg
    if ptr is not None:
        pyboy.memory[BOX + 2] = ptr & 0xFF
        pyboy.memory[BOX + 3] = ptr >> 8
    pyboy.memory[BOX + 5] = 0
    pyboy.memory[BOX] = cmd
    last = 0
    progress = 0
    for f in range(frames):
        pyboy.tick()
        fc = pyboy.memory[BOX + 5]
        progress += (fc - last) & 0xFF
        last = fc
    return frames - progress     # frames in which Sound_Update did not run


def check(names):
    bad = []
    for n in names:
        for (bk, a) in reads[n]:
            if (bk, a) not in item_of:
                bad.append((n, bk, a))
    return bad


results = []
# ---- songs in the table
table = P.song_table() if False else None
songs = []
o = 0x20 * 0x4000 - 0x4000
seen = {}
for i in range(P.NUM_SONGS):
    a = P.SONG_TABLE + 3 * i
    key = (rom[o + a + 2], rom[o + a] | rom[o + a + 1] << 8)
    if key in seen:
        continue
    seen[key] = i
    songs.append((i, key))
print(f'{nhooks} read hooks; {len(songs)} distinct songs in the table')
for i, (bk, ad) in songs:
    st = run(f'song{i:02X}', 1, i, FRAMES)
    results.append((f'song{i:02X}', st))
# ---- unreferenced songs
unref = []
for key, L in model.items():
    pass
import re
for fn in sorted(os.listdir(ROOT)):
    if fn.startswith('PPC_Bank') and fn.endswith('.asm'):
        for line in open(os.path.join(ROOT, fn)):
            m = re.match(r'Unused([0-9A-F]{2})_([0-9A-F]{4})::', line)
            if m:
                unref.append((int(m.group(1), 16), int(m.group(2), 16)))
for bk, ad in unref:
    st = run(f'unused{bk:02X}_{ad:04X}', 6, bk, FRAMES, ptr=ad)
    results.append((f'unused{bk:02X}_{ad:04X}', st))
# ---- SFX engine A
for ch, (t, n) in enumerate(P.SFXA_TABLES):
    for k in range(1, n):
        a, pr = P.sfxa_ptr(P.rw(0x21, t + 2 * k))
        if a:
            st = run(f'sfx{ch+1}_{k:02}', 2, (ch << 6) | k, SFX_FRAMES)
            results.append((f'sfx{ch+1}_{k:02}', st))
for k in range(1, P.SFXA_MULTI_N + 1):
    st = run(f'sfxm{k:02}', 3, k, SFX_FRAMES)
    results.append((f'sfxm{k:02}', st))
# ---- SFX engine B
nb = P.sfxb_count()
for k in range(1, nb):
    st = run(f'sfxb{k:02}', 4, k, SFX_FRAMES)
    results.append((f'sfxb{k:02}', st))
# ---- PCM
for k in range(4):
    for ct in (0, 0x11):
        st = run(f'pcm{k}_{ct:02X}', 5, k, 240, ctype=ct)
        results.append((f'pcm{k}_{ct:02X}', st))

bad = check([n for n, _ in results])
print(f'{len(results)} runs')
allreads = set().union(*[reads[n] for n, _ in results])
print(f'distinct ROM bytes read: {len(allreads)}')
byreg = defaultdict(int)
for bk, a in allreads:
    byreg[bk] += 1
print('per bank:', {f'{k:02X}': v for k, v in sorted(byreg.items())})
stalled = [(n, s) for n, s in results if s > 40 and not n.startswith('pcm')]  # 35 = start-up frames
print('runs where Sound_Update stopped running:', stalled)
print('reads outside the data model:', len(bad))
for b in bad[:40]:
    print('  ', b[0], f'{b[1]:02X}:{b[2]:04X}')
json.dump({'reads': {n: sorted(reads[n]) for n, _ in results}}, open(os.path.join(ROOT, 'build', 'reads.json'), 'w'))

# coverage of the parsed items: an item counts as read if any of its bytes was read
kinds = defaultdict(lambda: [0, 0])
for key, L in model.items():
    bk = L['bank']
    for a, l, kind in L['items']:
        if kind == 'code':
            continue
        hit = any((bk, a + j) in allreads for j in range(l))
        kinds[kind][0] += hit
        kinds[kind][1] += 1
for k, (h, n) in sorted(kinds.items()):
    print(f'  {k:12s} items read {h:6d} / {n:6d}')
