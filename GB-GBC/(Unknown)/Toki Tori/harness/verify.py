"""Play every song and SFX on the harness ROM (PyBoy, CGB mode) and check every byte the
driver reads from the music data against the parsed structures.

  * each row fetch must be exactly row k of the current order entry's pattern for that
    channel (k = fetches since the order entry was loaded), with the parsed length;
  * each order-list read must be a parsed entry (or the $FF terminator) of the song;
  * each SFX step read must be a parsed step.

usage: python verify.py <original rom> [harness.gbc]
"""
import os, sys
from pyboy import PyBoy

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'tools'))
import ttgen

orig = open(sys.argv[1], 'rb').read()
ttgen.ROM = orig
hrom = sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, 'harness.gbc')

# ---------------------------------------------------------------- parse model
songs = ttgen.songs()
def pattern_rows(bk, p, n):
    out = []; a = p
    for _ in range(n):
        ln = ttgen.row_len(bk, a); out.append((a, a + ln)); a += ln
    return out
song_orders = {}
for s in songs:
    o, end = ttgen.orders(s)
    song_orders[s['i']] = (o, end)

sfx_steps = {}
for i in range(ttgen.NSFX):
    e = ttgen.rbytes(0x2D, 0x6200 + 4 * i, 4)
    a = e[1] | e[2] << 8
    while True:
        n = ttgen.rb(0x2D, a)
        if n == 0:
            sfx_steps[a] = a + 1; break
        k = ttgen.rb(0x2D, a + 1) >> 4
        sfx_steps[a] = a + 2 + k
        a += 2 + k

# ---------------------------------------------------------------- emulator + hooks
pb = PyBoy(hrom, window='null', cgb=True, sound_emulated=False)
R = pb.register_file
mem = pb.memory
st = {}
def reset():
    st.update(bank=0, start=0, ch=0, reads=[], orders=[], obank=0, sfxbank=0, sfxstart=0,
              sfx=[], nr22=[], nr42=[], rowframes=[])
reset()

def h_patbank(c): st['bank'] = R.A
def h_rowstart(c): st['start'] = R.HL; st['ch'] = (((R.D << 8) | R.E) - 0xDF26) // 0x21
def h_rowend(c): st['reads'].append((st['ch'], st['bank'], st['start'], R.HL, len(st['orders'])))
def h_obank(c): st['obank'] = R.A
def h_order(c): st['orders'].append((st['obank'], R.HL, mem[R.HL]))
def h_rowframe(c):
    st['rowframes'].append((len(st['orders']),
                            [bytes(mem[0xDF26 + 0x21 * k + i] for i in range(5)) for k in range(4)]))
def h_sfxbank(c): st['sfxbank'] = R.A
def h_sfxstart(c): st['sfxstart'] = R.HL
def h_sfxend0(c):
    if R.A == 0: st['sfx'].append((st['sfxbank'], st['sfxstart'], st['sfxstart'] + 1))
def h_sfxend(c): st['sfx'].append((st['sfxbank'], st['sfxstart'], R.HL))
def h_nr22(c): st['nr22'].append((R.A, mem[0xDF53]))
def h_nr42(c): st['nr42'].append((R.A, mem[0xDF95]))

for addr, fn in [(0x3E73, h_patbank), (0x3E77, h_rowstart), (0x3E9D, h_rowend), (0x3EAF, h_rowend),
                 (0x3DDA, h_obank), (0x3DE0, h_order), (0x3D79, h_sfxbank), (0x3D7F, h_sfxstart),
                 (0x3D80, h_sfxend0), (0x3D95, h_sfxend)]:
    pb.hook_register(0, addr, fn, None)
pb.hook_register(0x2D, 0x62D1, h_rowframe, None)   # Music_Update, row frame
pb.hook_register(0x2D, 0x63DC, h_nr22, None)       # Ch2_Output: ldh [rNR22], a
pb.hook_register(0x2D, 0x648B, h_nr42, None)       # Ch4_Output: ldh [rNR42], a

pb.tick(400, False)   # boot

def run_song(i, cap=200000):
    reset()
    mem[0xFF80] = i
    f = 0; cnt = {}
    while f < cap:
        pb.tick(1, False); f += 1
        if st['orders']:
            last = st['orders'][-1]
            if last[2] != 0xFF and cnt.get(len(st['orders'])) is None:
                cnt[len(st['orders'])] = 1
                if sum(1 for x in st['orders'] if x[1] == last[1]) > 1:
                    break     # an order entry came round again: the song has looped
    return f

total_bad = 0
vol64 = []
print(f'{"song":>4} {"frames":>7} {"orders":>7} {"fetches":>8} {"wrong":>5} {"past end":>8}')
breaks_ok = breaks_n = 0
for s in songs:
    f = run_song(s['i'])
    o, end = song_orders[s['i']]
    by_addr = {e['addr']: e for e in o}
    bad = past = 0
    k = {}
    for ch, bk, a, e, n in st['reads']:
        if n == 0:
            bad += 1; continue
        ob, oa, ov = st['orders'][n - 1]
        if oa not in by_addr:
            bad += 1; continue
        ent = by_addr[oa]
        idx = k.get((n, ch), 0); k[(n, ch)] = idx + 1
        pbk, pp = ent['chans'][ch]
        rows = pattern_rows(pbk, pp, ent['rows'] + 1)
        if idx >= ent['rows']:
            past += 1
            if (bk, a, e) != (pbk,) + rows[idx]:
                bad += 1
            continue
        if (bk, a, e) != (pbk,) + rows[idx]:
            bad += 1
    obad = sum(1 for bk, a, v in st['orders'] if bk != s['bank'] or (a not in by_addr and a != end))
    total_bad += bad + obad
    vis = len({a for _, a, v in st['orders'] if v != 0xFF})
    print(f'{s["i"]:>4} {f:>7} {vis:>3}/{len(o):<3} {len(st["reads"]):>8} {bad + obad:>5} {past:>8}')
    vol64 += [x for x in st['nr22'] if x[1] >= 64] + [x for x in st['nr42'] if x[1] >= 64]
    # pattern break: the row frame after a D row re-decodes the other channels' rows
    rf = st['rowframes']
    for j in range(len(rf) - 1):
        bufs = rf[j][1]
        for ch, b in enumerate(bufs):
            if b[0] & 0x80 and b[0] & 8:
                i = 1 + (b[0] & 1) + (b[0] >> 1 & 1) + (b[0] >> 2 & 1)
                fx = b[i]
            elif not b[0] & 0x80:
                fx = b[3]
            else:
                continue
            if fx == 0x0D:
                breaks_n += 1
                nxt = rf[j + 1][1]
                same = all(nxt[c] == bufs[c] for c in range(4) if c != ch) and nxt[ch][0] == 0x80
                breaks_ok += same

# SFX
reset()
mem[0xFF80] = 0xFE
pb.tick(2, False)
for i in range(ttgen.NSFX):
    mem[0xFF81] = i
    pb.tick(30, False)
sbad = sum(1 for bk, a, e in st['sfx'] if bk != 0x2D or sfx_steps.get(a) != e)
print(f'SFX: {len(st["sfx"])} step reads, {len({a for _, a, _ in st["sfx"]})} / {len(sfx_steps)} distinct steps, wrong {sbad}')
total_bad += sbad
print(f'pattern breaks: {breaks_n}, next row frame re-decodes the other channels\' rows: {breaks_ok}')
print('NR22 / NR42 values written with VOLUME >= 64:', sorted(set(v for v, _ in vol64)), f'({len(vol64)} writes)')
pb.stop()
print('RESULT:', 'OK' if not total_bad else f'{total_bad} problems')
sys.exit(1 if total_bad else 0)
