"""Play every song and effect of the rebuilt Sanrio Carnival 2 driver (harness.gb, PyBoy) and check
every stream read against the generator's parse:
  - note/command fetches must land on a 'note' or 'cmd' byte, packed length reads on a 'len' byte,
    command operand reads on an 'op' byte (music);
  - SFX interpreter reads must land inside a parsed effect;
  - envelope / pitch / drum macro reads must stay in the $6D00-$6DB1 page (drum 3 reads game data at
    $5E01+: counted apart, it is a bug of the song data).
Usage: verify.py [frames per song] [frames per effect]"""
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..')); sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
from pyboy import PyBoy
from gbdis import Region
from s2_streams import MusicWalk, sfx_tables, sfx_parse

FS = int(sys.argv[1]) if len(sys.argv) > 1 else 1800
FX = int(sys.argv[2]) if len(sys.argv) > 2 else 240
ROM = os.path.join(HERE, 'harness.gb')
rom = open(ROM, 'rb').read()
m = MusicWalk(rom).run()
sfx_bytes = set()
for tab in sfx_tables(rom):
    for s in tab:
        for a, k, bs in sfx_parse(rom, s): sfx_bytes.update(range(a, a + len(bs)))

r = Region(rom, 1, 0x6000, 0x8000)
r.trace([0x6000, 0x6003]); r.jumptable(0x688a, 32)
lde = sorted(pc for pc, d in r.code.items() if d[1] == 'ld a, [de]')
PLAYERS = [(0x64f8, 0x65e0), (0x65e0, 0x66c5), (0x66c5, 0x67a8), (0x67a8, 0x6877)]
kind = {}
for lo, hi in PLAYERS:
    ps = [pc for pc in lde if lo <= pc < hi]
    kind[ps[0]] = 'fetch'; kind[ps[1]] = 'len'; kind[ps[2]] = 'len'
    for pc in ps[3:]: kind[pc] = 'macro'
for pc in lde:
    if pc < 0x6480: kind[pc] = 'sfx'
    elif pc < 0x64f8: kind[pc] = 'songtab'
    elif 0x6877 <= pc < 0x687e: kind[pc] = 'macro'
    elif 0x688a <= pc < 0x69ef: kind[pc] = 'op'
    kind.setdefault(pc, '?')
assert '?' not in kind.values(), kind

pb = PyBoy(ROM, window='null', sound_emulated=False)
rf = pb.register_file
log = []
for pc, k in kind.items():
    pb.hook_register(1, pc, lambda ctx: log.append((ctx, rf.D << 8 | rf.E)), k)

def check(entries):
    bad = []; drum3 = 0; seen = set()
    for k, a in entries:
        if k == 'fetch': ok = m.role.get(a) in ('note', 'cmd')
        elif k == 'len': ok = m.role.get(a) == 'len'
        elif k == 'op': ok = m.role.get(a) == 'op'
        elif k == 'sfx': ok = a in sfx_bytes
        elif k == 'songtab': ok = 0x6db2 <= a < 0x6e32
        else:
            ok = 0x6d00 <= a < 0x6db2
            if not ok and 0x5e00 <= a < 0x5f00: drum3 += 1; ok = True
        if k in ('fetch', 'len', 'op'): seen.add(a)
        if not ok: bad.append((k, a))
    return bad, drum3, seen

for _ in range(150): pb.tick()
out = ['song  reads  outside  drum3-reads']
total_bad = 0; seen_all = set()
for s in range(16):
    log.clear()
    pb.memory[0xde00] = s
    for _ in range(FS): pb.tick()
    bad, d3, seen = check(log); seen_all |= seen
    total_bad += len(bad)
    out.append(f'{s:4x}  {len(log):5d}  {len(bad):7d}  {d3:11d}  ' + ' '.join(f'{k}:{a:04x}' for k, a in bad[:5]))
pb.memory[0xde00] = 0
for _ in range(5): pb.tick()
unread = sorted(a for a in m.role if a not in seen_all)
out.append(f'music bytes parsed {len(m.role)}, never read in {FS} frames/song: {len(unread)}')
sp = []
for a in unread:
    if sp and a == sp[-1][1]: sp[-1][1] = a + 1
    else: sp.append([a, a + 1])
out.append("  unread spans: " + " ".join(f"{a:04x}+{b-a}" for a, b in sp))
nfx = 0; fxbad = 0
for slot, tab in enumerate(sfx_tables(rom)):
    for i, s in enumerate(tab):
        if s == 0x6ad9: continue
        log.clear()
        pb.memory[0xde01 + slot] = 0x80 >> i
        for _ in range(FX): pb.tick()
        bad, d3, seen = check(log)
        nfx += 1; fxbad += len(bad); total_bad += len(bad)
        out.append(f'sfx slot {slot+1} effect {i}: {len(log)} reads, {len(bad)} outside ' + ' '.join(f'{k}:{a:04x}' for k, a in bad[:5]))
out.append(f'{nfx} effects, {fxbad} reads outside')
out.append(f'TOTAL problems: {total_bad}')
pb.stop()
print('\n'.join(out))
