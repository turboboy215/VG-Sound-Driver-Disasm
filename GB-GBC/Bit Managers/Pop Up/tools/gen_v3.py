"""Generate <Game>_SoundDriver.asm for AJG driver version 3 (byte-exact).

usage: gen_v3.py <game> <rom> <out.asm>      game = asterix | pinocchio | metalmasters
"""
import sys, re, difflib
sys.path.insert(0, __file__.rsplit('/', 1)[0])
from asmgen import Gen
from bank import view
from sm83 import decode, fmt
from codetrace import trace
from notes import NOTE_MACRO, note_text, hx
from v3cfg import GAMES
from v3data import walk, w16
from v3names import AST_LABELS, AST_RAM, COMMENTS
import v3games

GAME = sys.argv[1]
cfg = GAMES[GAME]
info = v3games.INFO[GAME]
v = view(sys.argv[2], cfg['bank'])


# ----------------------------------------------------------------------
# reference listing (Astérix) for name transfer
def code_list(vv, ents, s, e):
    code, _, _ = trace(vv, ents)
    return [(a, fmt(*[decode(vv, a)[i] for i in (1, 2)])) for a in sorted(code) if s <= a <= e]


def norm(t):
    t = re.sub(r'\$[0-9A-F]{4}', 'W', t)
    t = re.sub(r'ldh? (\[)\$FF[0-9A-F]{2}\]', r'ld [W]', t)
    t = re.sub(r'ldh? a, \[\$FF[0-9A-F]{2}\]', 'ld a, [W]', t)
    t = re.sub(r'\$(DC|DD|DE|DF|C1|C2|C3|C4|C6|C7|C8|C9)\b', 'PG', t)
    return t


def ast_entries(c, vv):
    return list(v3games.INFO['asterix']['entries']) + [w16(vv, c['cmd_table'] + 2 * i) for i in range(len(c['cmds']))]


def transfer():
    """Map Astérix addresses -> this game's addresses through aligned code."""
    if GAME == 'asterix':
        return dict(AST_LABELS), dict(AST_RAM)
    ac = GAMES['asterix']
    import os
    av = view(os.path.join(os.path.dirname(os.path.abspath(sys.argv[2])), ac['rom']), ac['bank'])
    la = code_list(av, ast_entries(ac, av), 0x4A8C, 0x5711)
    lb = code_list(v, ents_driver, info['code_start'], info['code_end'])
    na = [norm(t) for _, t in la]
    nb = [norm(t) for _, t in lb]
    sm = difflib.SequenceMatcher(None, na, nb, autojunk=False)
    amap, rmap = {}, {}
    for op, i1, i2, j1, j2 in sm.get_opcodes():
        if op == 'equal' or (op == 'replace' and i2 - i1 == j2 - j1):
            for k in range(i2 - i1):
                aa, ab = la[i1 + k][0], lb[j1 + k][0]
                amap[aa] = ab
                # RAM operands
                ta, tb = la[i1 + k][1], lb[j1 + k][1]
                ma = re.search(r'\[\$(DB[0-9A-F]{2})\]', ta)
                mb = re.search(r'\[\$([0-9A-F]{4})\]', tb)
                if ma and mb and int(ma.group(1), 16) in AST_RAM:
                    rmap[int(mb.group(1), 16)] = AST_RAM[int(ma.group(1), 16)]
    lab = {}
    for a, nm in AST_LABELS.items():
        if a in amap:
            lab[amap[a]] = nm
    return lab, rmap


# ----------------------------------------------------------------------
H = [w16(v, cfg['cmd_table'] + 2 * i) for i in range(len(cfg['cmds']))]
ents_driver = list(info['entries']) + H
W = walk(cfg, v, info['songs'])
for p in W.problems:
    print('walker:', p)

# SFX stubs in the data area (ld a, id / jp or call PlaySfx / PlayOnChN)
wcov = set()
for a0, it in W.items.items():
    wcov.update(range(a0, a0 + it[0]))
_c, _, _ = trace(v, sorted(W.code))
for a0, nn in _c.items():
    wcov.update(range(a0, a0 + nn))
stub_tgt = {cfg['playsfx']: 'Sfx', cfg['playon']: 'Ch1Sfx', cfg['playon'] + 4: 'Ch2Sfx', cfg['playon'] + 8: 'Ch3Sfx'}
stubs = {}
for a0 in range(info['code_end'], info['sections'][-1][2] - 4):
    if (v[a0] == 0x3E and v[a0 + 2] in (0xC3, 0xCD) and w16(v, a0 + 3) in stub_tgt
            and not (wcov & set(range(a0, a0 + 5)))):
        stubs[a0] = '%s%02d' % (stub_tgt[w16(v, a0 + 3)], v[a0 + 1])
stub_entries = sorted(stubs)

g = Gen(v)
g.bank = cfg['bank']
g.sections = info['sections']
g.entries = ents_driver + sorted(W.code) + list(info.get('rom0_entries', [])) + stub_entries
g.analyse()

labels, ram = transfer()
labels.update(info.get('labels', {}))
for a0, nm in stubs.items():
    labels.setdefault(a0, 'Stub_' + nm)
ram.update(info.get('ram', {}))
for a, nm in labels.items():
    if g.in_sections(a):
        g.labels[a] = nm
g.labels[cfg['cmd_table']] = 'CmdTable'
for a0, nm in ((0x0000, 'Rst00_MemCopy'), (0x0008, 'Rst08_ReadWord'), (0x0018, 'Rst18_AddHLA')):
    g.labels[a0] = nm
for i, (cname, _) in enumerate(cfg['cmds']):
    if H[i] not in g.labels:
        g.labels[H[i]] = 'Cmd_' + ''.join(x.capitalize() for x in cname.split('_'))
p0 = cfg['pages']
for i, nm in enumerate(('wCh1', 'wCh2', 'wCh3', 'wSfx')):
    g.symbols[p0[i] << 8] = nm
g.symbols.update(ram)
g.symbols.update(info.get('game_ram', {}))

# ---------------------------------------------------------------- data labels
songs = W.songs
song_no = {}
n = 0
for s in songs:
    if any(s['orders']):
        n += 1
        song_no[s['routine']] = n
        g.labels[s['routine']] = 'PlaySong%d' % n
        for ch, o in enumerate(s['orders']):
            if o:
                g.labels.setdefault(o, 'Song%d_Ch%d' % (n, ch + 1))
    else:
        g.labels.setdefault(s['routine'], info.get('labels', {}).get(s['routine'], 'SongCode_%04X' % s['routine']))
itab_no = {}
for i, it in enumerate(sorted(W.instr_tables)):
    itab_no[it] = i + 1
atab_no = {}
for i, at in enumerate(sorted(W.arp_tables)):
    atab_no[at] = i + 1
inst_name = {}
for it, ptrs in W.instr_tables.items():
    for k, p in enumerate(ptrs):
        inst_name.setdefault(p, 'Instr%d_%d' % (itab_no[it], k))
arp_name = {}
for at, ptrs in W.arp_tables.items():
    for k, p in enumerate(ptrs):
        arp_name.setdefault(p, ('Arp%d_%d' % (atab_no[at], k)) if len(W.arp_tables) > 1 else 'Arp%d' % k)

sfx_ptrs = [w16(v, cfg['sfx_base'] + 2 + 2 * i) for i in range(cfg['sfx_count'])]
drum_ptrs = [w16(v, cfg['drum_base'] + 2 + 2 * i) for i in range(cfg['drum_count'])] if cfg['drum_base'] else []


def data_label(a):
    if a in g.labels:
        return g.labels[a]
    r = W.refs.get(a, set())
    for k in r:
        if k.startswith('sfx'):
            return 'Sfx%02d' % int(k[3:])
    for k in r:
        if k.startswith('drum') and k != 'drumpat':
            return 'Drum%d' % int(k[4:])
    if a in inst_name:
        return inst_name[a]
    if a in arp_name:
        return arp_name[a]
    if 'itab1' in r:
        for it in W.instr_tables:
            if it + 2 == a:
                return 'InstrTable%d_1' % itab_no[it]
    if 'atab' in r:
        return 'ArpTable%d' % atab_no[a] if len(W.arp_tables) > 1 else 'ArpTable'
    if 'orderlist' in r:
        return 'Order_%04X' % a
    if 'order' in r:
        return 'Loop_%04X' % a
    if 'pat' in r:
        return 'Pat_%04X' % a
    if 'wave' in r:
        return 'Wave_%04X' % a
    if 'drumpat' in r:
        return 'DrumPat_%04X' % a
    if 'fade' in r:
        return 'FadeTable_%04X' % a
    if 'n43' in r:
        return 'Noise43_%04X' % a
    if 'n42' in r:
        return 'Noise42_%04X' % a
    if 'code' in r:
        return 'Code_%04X' % a
    return None


for a in W.refs:
    nm = data_label(a)
    if nm and g.in_sections(a):
        g.labels[a] = nm
for i, a in enumerate(sfx_ptrs):
    g.labels.setdefault(a, 'Sfx%02d' % (i + 1))
g.labels[cfg['sfx_base'] + 2] = 'SfxTable'
if cfg['drum_base']:
    g.labels[cfg['drum_base'] + 2] = 'DrumTable'
    g.labels.setdefault(cfg['drum_base'], 'DrumTable_m2')

# ---------------------------------------------------------------- render items
cmdb = {name: cfg['cmd_first'] + i for i, (name, _) in enumerate(cfg['cmds'])}
NEXTB = cmdb['NEXT']


def stream_render(name, args):
    def r(ref):
        if name == 'NOTE':
            return [note_text(args[0][1])]
        if name == 'VOLENV':
            return ['VOLENV %d, %s, %s, %s' % (args[0][1], hx(args[1][1]), hx(args[2][1]), hx(args[3][1]))]
        if name in ('LEN', 'VOL', 'INSTR', 'ARP'):
            return ['%s %d' % (name, args[0][1])]
        parts = [hx(val) if t == 'b' else ref(val) for t, val in args]
        return [name + (' ' + ', '.join(parts) if parts else '')]
    return r


def dw_render(p):
    return lambda ref: ['dw ' + ref(p)]


def bytes_render(a, n, special=None):
    def r(ref):
        out = []
        for k in range(0, n, 8):
            out.append('db ' + ', '.join((special(x) if special else None) or hx(x) for x in v[a + k:a + min(n, k + 8)]))
        return out
    return r


SMALL = {'drumpat': lambda x: 'DRUM_LOOP' if x == 0xFF else None,
         'fade': lambda x: 'FADE_LOOP' if x == NEXTB else 'FADE_END' if x == 0xFF else None,
         'arp': lambda x: 'ARP_LOOP' if x == NEXTB else 'ARP_HOLD' if x == 0xFF else None,
         'n43': None, 'n42': None}
done = set()
for a in sorted(W.items):
    n, kind, inf = W.items[a]
    if kind == 'stream':
        name, args, ctx = inf
        g.items[a] = (n, stream_render(name, args))
    elif kind == 'order':
        k, val = inf
        if k == 'pat':
            g.items[a] = (2, dw_render(val))
        else:
            g.items[a] = (4, (lambda p: lambda ref: ['ORDER_LOOP ' + ref(p)])(val))
    elif kind in ('itab', 'atab', 'ptrtab'):
        for k in range(n // 2):
            g.items[a + 2 * k] = (2, dw_render(w16(v, a + 2 * k)))
    elif kind in SMALL:
        if a in done:
            continue
        # coalesce a run of small items of the same kind (no label inside, max 8 bytes)
        b = a
        while True:
            done.add(b)
            b += W.items[b][0]
            if b - a >= 8 or b in g.labels or b not in W.items or W.items[b][1] != kind or b in done:
                break
            if kind == 'drumpat' and v[b - 1] == 0xFF:
                break
            if kind in ('fade', 'arp') and v[b - 1] in (0xFF, NEXTB):
                break
            if kind == 'n43' and v[b - 1] == 0xFF:
                break
        g.items[a] = (b - a, bytes_render(a, b - a, SMALL[kind]))
    elif kind == 'wave':
        g.items[a] = (n, bytes_render(a, n))

# command table, period table, init blocks, CH3 volume table
for i in range(len(H)):
    g.items[cfg['cmd_table'] + 2 * i] = (2, dw_render(H[i]))
pt = info['period_table']
for i in range(81):
    g.items[pt + 2 * i] = (2, (lambda x: lambda ref: ['dw $%04X' % x])(w16(v, pt + 2 * i)))
for a, n in info.get('raw_items', []):
    if any(x in g.items or x in W.items for x in range(a, a + n)):
        continue
    g.items[a] = (n, bytes_render(a, n))

# table symbols: InstrTableN = entry 1 - 2 (entry 0 is never read)
extra_defs = []

# operands of the song routines: tables as HIGH()/LOW(), order lists as labels
gi, ga = cfg['g_instr'], cfg['g_arp']
gseq = cfg['g_seq'] or ()
for a in sorted(g.code):
    op = v[a]
    if op == 0x3E:
        nxt = a + 2
        if v[nxt] in (0xEA, 0xE0):
            dst = w16(v, nxt + 1) if v[nxt] == 0xEA else 0xFF00 + v[nxt + 1]
            pair = None
            for lo, hi in ((gi[0], gi[1]), (ga[0], ga[1])):
                if dst in (lo, hi):
                    pair = (lo, hi)
            if pair:
                # find the partner store within this routine
                pass
# simple approach: rebuild table addresses per routine from the walker's songs
for s in songs:
    code, _, _ = trace(v, [s['routine']])
    for a in sorted(code):
        if v[a] == 0x3E and v[a + 2] in (0xEA, 0xE0):
            dst = w16(v, a + 3) if v[a + 2] == 0xEA else 0xFF00 + v[a + 3]
            if s['itab'] and dst in gi:
                nm = 'InstrTable%d_1 - 2' % itab_no.get(s['itab'], 0)
                if s['itab'] in itab_no:
                    g.operand[a] = ('LOW(%s)' if dst == gi[0] else 'HIGH(%s)') % nm
            if s['atab'] and dst in ga and s['atab'] in atab_no:
                nm = g.labels.get(s['atab'], 'ArpTable')
                g.operand[a] = ('LOW(%s)' if dst == ga[0] else 'HIGH(%s)') % nm
for a in sorted(W.code):
    code, _, _ = trace(v, [a])
    for b in sorted(code):
        if v[b] == 0x3E and v[b + 2] in (0xEA, 0xE0) and gseq:
            dst = w16(v, b + 3) if v[b + 2] == 0xEA else 0xFF00 + v[b + 3]
            if dst in gseq:
                # partner byte
                idx = gseq.index(dst)
                hi_i = idx - (idx % 2)
                # locate the other store of the pair in this routine
                other = None
                for c2 in sorted(code):
                    if v[c2] == 0x3E and v[c2 + 2] in (0xEA, 0xE0):
                        d2 = w16(v, c2 + 3) if v[c2 + 2] == 0xEA else 0xFF00 + v[c2 + 3]
                        if d2 == gseq[hi_i + (1 - idx % 2)]:
                            other = c2
                if other is not None:
                    hi_v = v[b + 1] if idx % 2 == 0 else v[other + 1]
                    lo_v = v[other + 1] if idx % 2 == 0 else v[b + 1]
                    tgt = (hi_v << 8) | lo_v
                    if tgt in g.labels:
                        g.operand[b] = ('HIGH(%s)' if idx % 2 == 0 else 'LOW(%s)') % g.labels[tgt]

# ---------------------------------------------------------------- macros / header
T = cfg['cmds']
cmd_macros = []
for i, (name, spec) in enumerate(T):
    b = cfg['cmd_first'] + i
    if spec in ('hwenv', 'release'):
        continue
    body = ['\tdb $%02X' % b]
    for k, t in enumerate(spec):
        body.append(('\tdb \\%d' if t == 'b' else '\tdw \\%d') % (k + 1))
    cmd_macros.append(f'MACRO {name}\n' + '\n'.join(body) + '\nENDM')

macros = NOTE_MACRO + f'''
; ---- stream commands (patterns, SFX streams and instrument macros) ----
; notes are bytes $00-${cfg['note_max'] - 1:02X}
MACRO LEN       ; note length in ticks, 1-{0x100 - cfg['len_first']}
\tdb ${cfg['len_first'] - 1:02X} + \\1
ENDM
MACRO VOL       ; start volume of following notes, 0-15 (software envelope mode)
\tdb ${cfg['vol_first']:02X} + \\1
ENDM
MACRO VOLENV    ; start volume + envelope: atk (lo=count hi=step), dec (lo=count hi=step), rates (hi=atk lo=dec)
\tdb ${cfg['volenv_first']:02X} + \\1, \\2, \\3, \\4
ENDM
MACRO INSTR     ; instrument n = entry n + 1 of the current song's instrument table
\tdb ${cfg['instr_first']:02X} + \\1
ENDM
MACRO ARP       ; arpeggio n of the current song's arpeggio table
\tdb ${cfg['arp_first']:02X} + \\1
ENDM
MACRO HWENV     ; HWENV env, 0 | HWENV env, ticks, env2  (hardware envelope mode)
\tdb ${cmdb['HWENV']:02X}, \\1, \\2
\tIF _NARG > 2
\t\tdb \\3
\tENDC
ENDM
MACRO RELEASE   ; RELEASE 0 = off | RELEASE minlen << 4 | ticks_left, env
\tdb ${cmdb['RELEASE']:02X}, \\1
\tIF _NARG > 1
\t\tdb \\2
\tENDC
ENDM
''' + '\n'.join(cmd_macros) + f'''
; ---- order lists ----
MACRO ORDER_LOOP  ; end of an order list: 0, then the order position to continue from
\tdw 0, \\1
ENDM
; ---- arpeggio and NR50 tables ----
DEF ARP_LOOP EQU ${NEXTB:02X}   ; restart the table
DEF ARP_HOLD EQU $FF   ; stay on the previous entry
DEF FADE_LOOP EQU ${NEXTB:02X}
DEF FADE_END EQU $FF
; ---- drum patterns (one step per drum tick) ----
DEF DRUM_LOOP EQU $FF
'''
m = v3games.META[GAME]
g.header = v3games.HDR.format(rom=cfg['rom'], bank=cfg['bank'], **m)
g.macros = macros

# ---------------------------------------------------------------- comments
CM = dict(COMMENTS)
CM.update(v3games.COMMENT_OVERRIDES.get(GAME, {}))
for a, nm in list(g.labels.items()):
    if nm in CM:
        g.blocks.setdefault(a, CM[nm])
for a, txt in info.get('blocks', {}).items():
    g.blocks[a] = txt
for i, a in enumerate(sfx_ptrs):
    g.blocks.setdefault(a, 'Sound effect %d' % (i + 1))
for s in songs:
    if s['routine'] in song_no:
        k = song_no[s['routine']]
        txt = 'Song %d: instrument table %s, arpeggio table %s' % (
            k, itab_no.get(s['itab'], '-'), atab_no.get(s['atab'], '-'))
        if s['sfx']:
            txt += '; also starts SFX ' + ', '.join(str(x) for x in s['sfx'])
        g.blocks.setdefault(s['routine'], txt)
for it, k in itab_no.items():
    g.blocks.setdefault(it + 2, 'Instrument table %d, entries 1..%d (the song routines point 2 bytes before:\nentry 0 is never read)' % (k, len(W.instr_tables[it])))

# unreferenced gaps
occ = set()
for a, nn in g.code.items():
    occ.update(range(a, a + nn))
for a, (nn, _) in g.items.items():
    occ.update(range(a, a + nn))
for name, s0, e0, _ in g.sections:
    a = s0
    while a < e0:
        if a not in occ:
            b = a
            while b < e0 and b not in occ:
                b += 1
            if a not in g.blocks:
                g.blocks[a] = 'Unreferenced (%d bytes)' % (b - a)
            a = b
        else:
            a += 1

# drop labels that fall inside instructions/items
inner = set()
for a, nn in list(g.code.items()) + [(a, x[0]) for a, x in g.items.items()]:
    for i in range(1, nn):
        inner.add(a + i)
dropped = [(hex(a), nm) for a, nm in g.labels.items() if a in inner]
for a in [a for a in g.labels if a in inner]:
    del g.labels[a]
if dropped:
    print('labels inside items dropped:', dropped[:20])

# unique label names
seen_names = {}
for a in sorted(g.labels):
    nm = g.labels[a]
    if nm in seen_names:
        g.labels[a] = '%s_%04X' % (nm, a)
    seen_names[g.labels[a]] = a

bad = g.check_overlaps()
if bad:
    print('OVERLAPS', bad[:10])
txt = g.emit()
# insert extra DEFs after the macros
txt = txt.replace('; ---- hardware registers', '\n'.join(extra_defs) + '\n\n; ---- hardware registers', 1)
open(sys.argv[3], 'w').write(txt)
import json, os
meta = dict(game=GAME, bank=cfg['bank'], pages=list(cfg['pages']),
            ram={nm: a for a, nm in g.symbols.items()},
            labels={nm: a for a, nm in g.labels.items()},
            songs=[s['routine'] for s in songs if s['routine'] in song_no],
            stream=sorted(a for a, it in W.items.items() if it[1] == 'stream'),
            order=sorted(a for a, it in W.items.items() if it[1] == 'order'),
            drumpat=sorted(a for a, it in W.items.items() if it[1] == 'drumpat'),
            drumpat2=sorted(a for a, it in W.items.items() if it[1] == 'drumpat' and it[0] == 2),
            sfx_count=cfg['sfx_count'])
vdir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'verify')
os.makedirs(vdir, exist_ok=True)
json.dump(meta, open(os.path.join(vdir, m['short'] + '.json'), 'w'))
print('ok', len(g.code), 'instructions,', len(g.items), 'items')
