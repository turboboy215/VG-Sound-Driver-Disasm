"""Generate <Game>_SoundDriver.asm for AJG driver version 4 (byte-exact, the whole driver bank:
bank 6 for The Smurfs / Obelix, 15 for the Tintin games, Spirou, Die Maus and the Turok games,
12 for Lucky Luke, 2 for The Smurfs' Nightmare and Bugs Bunny, 7 for Hugo 2, 15 for Sylvester and Tweety).

usage: gen_v4.py <game> <rom> <out.asm>
       game = smurfs | obelixgb | obelixgbc | tibet | sun | spirou | luckyluke | smurfs3 | maus |
              hugo2 | turok | turok2 | otto | seabattle | vrally | vrallygbc | sylvester | bugs
"""
import sys, re, difflib, os, json
sys.path.insert(0, __file__.rsplit('/', 1)[0])
from asmgen import Gen
from bank import view
from sm83 import decode, fmt
from codetrace import trace
from notes import NOTE_MACRO, note_text, hx
from v4cfg import GAMES, GLOBALS
from v4data import walk, w16
from v4names import SMF_LABELS, GBC_LABELS, GB_LABELS, COMMENTS, COMMENT_OVERRIDES
import v4games

GAME = sys.argv[1]
cfg = dict(GAMES[GAME])
info = v4games.INFO[GAME]
cfg['drum_count_override'] = info['drum_count']
v = view(sys.argv[2], cfg['bank'])
STARTMUSIC = cfg['startmusic_list']


# ----------------------------------------------------------------------
def jt_entries(vv, a, fall=None):
    out = []
    while vv[a] == 0xC3:
        t = w16(vv, a + 1)
        out.append((fall or {}).get(t, t))     # jt_fall: slot jumps into data that runs into a routine
        a += 3
    return out


def is_song(vv, r):
    c, _, _ = trace(vv, [r])
    for x in c:
        f = decode(vv, x)[3]
        if f and f[0] in ('call', 'jp') and f[1] in STARTMUSIC:
            return True
    return False


def driver_entries(vv, c, inf):
    ents = [e for e in jt_entries(vv, inf['jt'], inf.get('jt_fall')) if e not in inf.get('jt_dead', ())]
    H = [w16(vv, c['cmd_table'] + 2 * i) for i in range(len(c['cmds']))]
    api = [e for e in ents if not is_song(vv, e)]
    return ents, H, api


JT, H, API = driver_entries(v, cfg, info)
SONG_SLOTS = [e for e in JT[8:] if is_song(v, e)]           # API song entries (may repeat a routine)
SONGS_JT = list(dict.fromkeys(SONG_SLOTS))                   # unique, in API order
EXTRA_API = [e for e in JT[8:] if not is_song(v, e)]         # PlaySfxNow; Sun: PlayCh1Tone
SONGS = SONGS_JT + info['jingles']


def init_arp():
    c, _, _ = trace(v, [JT[5]])
    regs, g = {}, {}
    for x in sorted(c):
        if v[x] == 0x3E:
            regs['a'] = v[x + 1]
        if v[x] == 0xEA and 'a' in regs:
            g[w16(v, x + 1)] = regs['a']
    ga = cfg['g_arp']
    return g[ga[0]] | (g[ga[1]] << 8)


def fade_tables():
    out = []
    for e in JT[6:8]:
        c, _, _ = trace(v, [e], stop=(JT[2],))         # don't follow SndResume (GBC-style SongFadeIn)
        for x in sorted(c):
            if v[x] == 0x21 and 0x4000 <= w16(v, x + 1) < 0x8000:
                out.append((e, w16(v, x + 1)))
    return out


FADES = fade_tables()
W = walk(cfg, v, SONGS, extra_code=info['extra_code'], init_arp=init_arp(), extra_fades=[f for _, f in FADES])
for p in W.problems:
    print('walker:', p)


# ----------------------------------------------------------------------
# reference listing (The Smurfs) for name transfer
def code_list(vv, ents, s, e):
    code, _, _ = trace(vv, ents)
    return [(a, fmt(*[decode(vv, a)[i] for i in (1, 2)])) for a in sorted(code) if s <= a <= e]


def norm(t):
    return re.sub(r'\$[0-9A-F]{4}', 'W', t)


ROMDIR = os.path.dirname(os.path.abspath(sys.argv[2]))
OWN_LABELS = {'obelixgb': GB_LABELS, 'obelixgbc': GBC_LABELS}


def game_view(game):
    c = GAMES[game]
    return view(os.path.join(ROMDIR, c['rom']), c['bank'])


def game_code(game, vv):
    j, h, _ = driver_entries(vv, GAMES[game], v4games.INFO[game])
    return code_list(vv, j + h, 0x4000, v4games.INFO[game]['code_end'])


def apply_overrides(lab, ov):
    for a, nm in ov.items():
        for b in [b for b, n2 in lab.items() if n2 == nm and b != a]:
            del lab[b]                   # an override moves a carried-over name
        lab[a] = nm


_LABEL_CACHE = {}


def final_labels(game):
    """Code labels of a game's driver: Smurfs names, carried along the reference chain
    (Smurfs -> Obelix GB -> Tibet; Smurfs -> Obelix GBC -> Sun, Spirou) by aligning the code,
    then each game's own names."""
    if game in _LABEL_CACHE:
        return _LABEL_CACHE[game]
    vv = game_view(game)
    if game == 'smurfs':
        lab = dict(SMF_LABELS)
    else:
        ref = v4games.INFO[game].get('ref', 'smurfs')
        rl = final_labels(ref)
        la = game_code(ref, game_view(ref))
        lb = game_code(game, vv)
        sm = difflib.SequenceMatcher(None, [norm(t) for _, t in la], [norm(t) for _, t in lb], autojunk=False)
        amap = {}
        for op, i1, i2, j1, j2 in sm.get_opcodes():
            if op == 'equal' or (op == 'replace' and i2 - i1 == j2 - j1):
                for k in range(i2 - i1):
                    amap[la[i1 + k][0]] = lb[j1 + k][0]
        lab = {amap[a]: nm for a, nm in rl.items() if a in amap}
    apply_overrides(lab, OWN_LABELS.get(game, {}))
    apply_overrides(lab, v4games.INFO[game].get('labels', {}))
    for nm in v4games.INFO[game].get('drop_labels', ()):
        for b in [b for b, n2 in lab.items() if n2 == nm]:
            del lab[b]
    _LABEL_CACHE[game] = lab
    return lab


def transfer(ents_here):
    lab = dict(final_labels(GAME))
    if GAME != 'smurfs':
        # data-ish labels at fixed relative spots
        lab[cfg['ch3vol']] = 'Ch3VolTable'
        lab[cfg['drum_base']] = 'DrumTable_m2'
        lab[cfg['drum_base'] + 2] = 'DrumTable'
    return lab


ents_driver = JT + H
g = Gen(v)
g.bank = cfg['bank']
g.sections = [('SoundDriver', 0x4000, 0x8000, '')]
_ALL = jt_entries(v, info['jt'])
JT_SLOTS = [info['jt'] + 3 * i for i, t in enumerate(_ALL) if t not in info.get('jt_dead', ())]
JT_DEAD = [info['jt'] + 3 * i for i, t in enumerate(_ALL) if t in info.get('jt_dead', ())]   # slots into data
JT_FALL = [info['jt'] + 3 * i for i, t in enumerate(_ALL) if t in info.get('jt_fall', {})]
g.entries = [a for a in JT_SLOTS if a not in JT_FALL] + ents_driver + sorted(W.code)
g.analyse()
API_NAMES = ['SndUpdate', 'SndPause', 'SndResume', 'StopAll', 'PlaySfx (A = id)', 'SndInit',
             'SongFadeIn (A = speed)', 'SongFadeOut (A = speed)']

labels = transfer(ents_driver)
# names that the alignment can't carry: SFX entry chain, fade entries
labels[JT[4]] = labels.get(JT[4], 'PlaySfxEntry')
for a, nm in labels.items():
    if g.in_sections(a):
        g.labels[a] = nm
g.labels[cfg['cmd_table']] = 'CmdTable'
for i, (cname, _) in enumerate(cfg['cmds']):
    if H[i] not in g.labels:
        g.labels[H[i]] = 'Cmd_' + ''.join(x.capitalize() for x in cname.split('_'))
p0 = cfg['pages']
for i, nm in enumerate(('wCh1', 'wCh2', 'wCh3', 'wSfx')):
    g.symbols[p0[i] << 8] = nm
gb = cfg['g']['base']
for off, nm in GLOBALS:
    if nm.startswith('wDuty') and not cfg.get('duty_shadows'):
        continue
    g.symbols[gb + off] = nm

# ---------------------------------------------------------------- data labels
song_no = {}
for i, r in enumerate(SONGS_JT):
    song_no[r] = 'Song%d' % (i + 1)
slot_song = {}                       # API slot index -> song number (by routine)
for k, r in enumerate(SONG_SLOTS):
    slot_song[k] = SONGS_JT.index(r) + 1
for i, r in enumerate(info['jingles']):
    song_no[r] = 'Jingle%d' % (i + 1)
songs = W.songs
for s in songs:
    nm = song_no[s['routine']]
    g.labels[s['routine']] = 'Play' + nm
    for ch, o in enumerate(s['orders']):
        if o:
            g.labels.setdefault(o, '%s_Ch%d' % (nm, ch + 1))
itab_no = {it: i + 1 for i, it in enumerate(sorted(W.instr_tables))}
atab_no = {at: i + 1 for i, at in enumerate(sorted(W.arp_tables))}
inst_name = {}
for it, ptrs in W.instr_tables.items():
    for k, p in enumerate(ptrs):
        inst_name.setdefault(p, 'Instr%d_%d' % (itab_no[it], k))
arp_name = {}
for at, ptrs in W.arp_tables.items():
    for k, p in enumerate(ptrs):
        arp_name.setdefault(p, ('Arp%d_%d' % (atab_no[at], k)) if len(W.arp_tables) > 1 else 'Arp%d' % k)

sfx_ptrs = [w16(v, cfg['sfx_base'] + 2 + 2 * i) for i in range(cfg['sfx_count'])]
SFX_REAL = [(i, a) for i, a in enumerate(sfx_ptrs) if i + 1 not in cfg['sfx_dummy']]
drum_ptrs = [w16(v, cfg['drum_base'] + 2 + 2 * i) for i in range(cfg['drum_count'])]


def data_label(a):
    if a in g.labels:
        return g.labels[a]
    r = W.refs.get(a, set())
    sfx = [int(k[3:]) for k in r if k.startswith('sfx')]
    if sfx:
        return 'Sfx%02d' % min(sfx)                  # shared streams: the first id (deterministic)
    drums = [int(k[4:]) for k in r if k.startswith('drum') and k != 'drumpat']
    if drums:
        return 'Drum%d' % max(drums)                 # shared routines: the last drum number
    if a in inst_name:
        return inst_name[a]
    if a in arp_name:
        return arp_name[a]
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
for i, a in SFX_REAL:
    g.labels.setdefault(a, 'Sfx%02d' % (i + 1))
g.labels[cfg['sfx_base'] + 2] = 'SfxTable'
g.labels.setdefault(cfg['sfx_base'], 'SfxTable_m2')
g.labels[cfg['drum_base'] + 2] = 'DrumTable'
g.labels.setdefault(cfg['drum_base'], 'DrumTable_m2')
for a in info['extra_code']:
    if not W.refs.get(a) or a not in g.labels:
        pass
sfx_noise = {}
if GAME == 'smurfs':
    for k, a in zip((30, 31, 32), (0x797A, 0x7A8B, 0x7910)):
        g.labels[a] = 'Sfx%02d_Noise' % k
        sfx_noise[a] = k
for k, a in info.get('noise_sfx', {}).items():
    g.labels[a] = 'Sfx%02d_Noise' % k
    sfx_noise[a] = k
for fe, ft in FADES:
    g.labels[ft] = 'FadeOutTable' if v[ft] == 0x77 else 'FadeInTable'

# ---------------------------------------------------------------- render items
cmdb = {name: cfg['cmd_first'] + i for i, (name, _) in enumerate(cfg['cmds'])}
NEXTB = cmdb['NEXT']


def stream_render(name, args):
    def r(ref):
        if name == 'NOTE':
            return [note_text(args[0][1])]
        if name == 'VOLENV':
            return ['VOLENV %d, %s, %s, %s' % (args[0][1], hx(args[1][1]), hx(args[2][1]), hx(args[3][1]))]
        if name in ('LEN', 'INSTR', 'ARP', 'REPEAT'):
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


TF = cfg['drum_tempo_first']


def drum_render(a, n):
    def r(ref):
        toks, k = [], 0
        while k < n:
            x = v[a + k]
            if x == 0x35:
                toks += ['DRUM_AUTOPAN', hx(v[a + k + 1])]
                k += 2
                continue
            if x == 0xFF:
                t = 'DRUM_LOOP'
            elif x == 0:
                t = '0'
            elif x < 0x32:
                t = '%d' % x                       # drum sound n
            elif x <= 0x36:
                t = {0x32: 'DRUM_PAN_C', 0x33: 'DRUM_PAN_R', 0x34: 'DRUM_PAN_L', 0x36: 'DRUM_REPEAT_END'}[x]
            elif x < 0x47:
                t = 'DRUM_LEVEL + %d' % (x - 0x37)
            elif x < 0x5B:
                t = 'DRUM_SPEED + %d' % (x - 0x47)
            elif x < TF:
                t = 'DRUM_REPEAT + %d' % (x - 0x5A)
            else:
                t = 'DRUM_TEMPO + %d' % (x - (TF - 1))
            toks.append(t)
            k += 1
        return ['db ' + ', '.join(toks)]
    return r


def drum_byte(x):
    return None


SMALL = {'drumpat': drum_byte,
         'fade': lambda x: 'FADE_LOOP' if x == NEXTB else 'FADE_END' if x == 0xFF else None,
         'arp': lambda x: 'ARP_LOOP' if x == NEXTB else 'ARP_HOLD' if x == 0xFF else None,
         'n43': None, 'n42': None}
done = set()
wave_in_code, overlap_waves = [], []
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
        g.items[a] = (b - a, drum_render(a, b - a) if kind == 'drumpat' else bytes_render(a, b - a, SMALL[kind]))
    elif kind == 'wave':
        if a in g.code:
            wave_in_code.append(a)          # a WAVE pointer into driver code (see the doc)
            continue
        nxt = [b for b in W.items if a < b < a + n and W.items[b][1] == 'wave']
        if nxt:
            overlap_waves.append((a, min(nxt)))
            n = min(nxt) - a                 # the rest is the next (overlapping) wave
        g.items[a] = (n, bytes_render(a, n))

for i in range(len(H)):
    g.items[cfg['cmd_table'] + 2 * i] = (2, dw_render(H[i]))
pt = cfg['period_table']
for i in range(81):
    g.items[pt + 2 * i] = (2, (lambda x: lambda ref: ['dw $%04X' % x])(w16(v, pt + 2 * i)))
for a, n in info.get('text_items', []):          # ASCII text left in the bank
    g.items[a] = (n, (lambda t: lambda ref: ['db "%s"' % t])(bytes(v[a:a + n]).decode('ascii')))
for a, n in info.get('raw_items', []):
    if any(x in g.items or x in W.items for x in range(a, a + n)):
        continue
    g.items[a] = (n, bytes_render(a, n))

# operands in song routines and noise routines: tables as LOW()/HIGH() of labels
gi, ga, gseq = cfg['g_instr'], cfg['g_arp'], cfg['g_seq']
pairs = [(gi[0], gi[1], 2), (ga[0], ga[1], 0), (gseq[1], gseq[0], 0), (gseq[3], gseq[2], 0)]   # (lo, hi, label offset)
for r0 in list(W.code) + JT[5:6]:
    code, _, _ = trace(v, [r0])
    st = {}
    for a in sorted(code):
        if v[a] == 0x3E and v[a + 2] in (0xEA, 0xE0):
            dst = w16(v, a + 3) if v[a + 2] == 0xEA else 0xFF00 + v[a + 3]
            st[dst] = a
    for lo, hi, off in pairs:
        if lo in st and hi in st:
            tgt = v[st[lo] + 1] | (v[st[hi] + 1] << 8)
            lab = g.labels.get(tgt + off)
            if lab:
                ex = lab + (' - %d' % off if off else '')
                g.operand[st[lo]] = 'LOW(%s)' % ex
                g.operand[st[hi]] = 'HIGH(%s)' % ex
for a in sorted(g.code):
    if v[a] in (0x11, 0x21) and w16(v, a + 1) in g.labels and 0x4000 <= w16(v, a + 1) < 0x8000:
        g.operand[a] = g.labels[w16(v, a + 1)]
    if v[a] == 0x01 and w16(v, a + 1) in info.get('bc_data', ()):
        g.operand[a] = g.labels[w16(v, a + 1)]

# ---------------------------------------------------------------- macros / header
T = cfg['cmds']
cmd_macros = []
for i, (name, spec) in enumerate(T):
    b = cfg['cmd_first'] + i
    if spec in ('hwenv', 'release', 'hook'):
        continue
    body = ['\tdb $%02X' % b]
    for k, t in enumerate(spec):
        body.append(('\tdb \\%d' if t == 'b' else '\tdw \\%d') % (k + 1))
    cmd_macros.append(f'MACRO {name}\n' + '\n'.join(body) + '\nENDM')
hook = ''
if 'NOTE_HOOK' in cmdb:
    hook = f'''MACRO NOTE_HOOK ; NOTE_HOOK 0 = off | NOTE_HOOK on_note, on_wait (code addresses)
\tdb ${cmdb['NOTE_HOOK']:02X}
\tIF _NARG > 1
\t\tdw \\1, \\2
\tELSE
\t\tdb \\1
\tENDC
ENDM
'''
macros = NOTE_MACRO + f'''
; ---- stream commands (patterns, SFX streams and instrument macros) ----
; notes are bytes $00-${cfg['note_max'] - 1:02X}
MACRO REPEAT    ; play the following bytes n times (up to REPEAT_END), n = 2-{0x100 - cfg['rep_first'] + 1}
\tdb ${cfg['rep_first'] - 2:02X} + \\1
ENDM
MACRO LEN       ; note length in ticks, 1-{cfg['rep_first'] - cfg['len_first']}
\tdb ${cfg['len_first'] - 1:02X} + \\1
ENDM
MACRO VOLENV    ; start volume + envelope (CH3/SFX): atk (lo=count hi=step), dec (lo=count hi=step), rates (hi=atk lo=dec)
\tdb ${cfg['volenv_first']:02X} + \\1, \\2, \\3, \\4
ENDM
MACRO INSTR     ; instrument n = entry n + 1 of the current instrument table
\tdb ${cfg['instr_first']:02X} + \\1
ENDM
MACRO ARP       ; arpeggio n of the current arpeggio table
\tdb ${cfg['arp_first']:02X} + \\1
ENDM
MACRO HWENV     ; HWENV env, 0 | HWENV env, ticks, env2  (pulse NRx2 at note on, env2 after ticks)
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
''' + hook + '\n'.join(cmd_macros) + f'''
; ---- order lists ----
MACRO ORDER_LOOP  ; end of an order list: 0, then the order position to continue from
\tdw 0, \\1
ENDM
; ---- arpeggio and NR50 tables ----
DEF ARP_LOOP EQU ${NEXTB:02X}   ; restart the table
DEF ARP_HOLD EQU $FF   ; stay on the previous entry
DEF FADE_LOOP EQU ${NEXTB:02X}
DEF FADE_END EQU $FF
; ---- drum patterns: one step per drum tick, read up to a 0 or a drum sound (1-49) ----
DEF DRUM_PAN_C EQU $32          ; noise pan centre / right / left
DEF DRUM_PAN_R EQU $33
DEF DRUM_PAN_L EQU $34
DEF DRUM_AUTOPAN EQU $35        ; + 1 byte: noise auto-pan every n noise steps
DEF DRUM_REPEAT_END EQU $36
DEF DRUM_LEVEL EQU $37          ; + 0-15: noise level (attenuation 15 - n)
DEF DRUM_SPEED EQU $47          ; + 0-19: noise sequence speed
DEF DRUM_REPEAT EQU $5A         ; + n: repeat the following bytes up to DRUM_REPEAT_END
DEF DRUM_TEMPO EQU ${TF - 1:02X}         ; + n: one step every n ticks
DEF DRUM_LOOP EQU $FF           ; restart the pattern
'''
m = v4games.META[GAME]
g.header = v4games.HDR.format(rom=cfg['rom'], bank=cfg['bank'], **m)
g.macros = macros

# ---------------------------------------------------------------- comments
CM = dict(COMMENTS)
chain, gg = [], GAME
while gg != 'smurfs':                 # overrides of the reference builds first, then this game's
    chain.insert(0, gg)
    gg = v4games.INFO[gg].get('ref', 'smurfs')
for gg in chain:
    CM.update({k: (COMMENTS.get(k) if x == 'SMURFS' else x) for k, x in COMMENT_OVERRIDES.get(gg, {}).items()})
for a, nm in list(g.labels.items()):
    if CM.get(nm):
        g.blocks.setdefault(a, CM[nm])
for a, txt in info.get('blocks', {}).items():
    g.blocks[a] = txt
for i, a in SFX_REAL:
    g.blocks.setdefault(a, 'Sound effect %d' % (i + 1))
for a, k in sfx_noise.items():
    g.blocks[a] = 'Sound effect %d (noise only; started by the game\'s glue, sets wDrumHold)' % k
for s in songs:
    nm = song_no[s['routine']]
    txt = '%s: instrument table %s, arpeggio table %s' % (
        nm.replace('Song', 'Song ').replace('Jingle', 'Jingle '), itab_no.get(s['itab'], '- (none set)'),
        ('%d' % atab_no[s['atab']] if s['atab'] in atab_no else '-') + (' (the one SndInit sets)' if s.get('atab_init') else ''))
    slots = [k for k, r in enumerate(SONG_SLOTS) if r == s['routine']]
    if len(slots) > 1:
        txt += '\nAPI song slots %s all start this routine' % ', '.join('%d' % (k + 1) for k in slots)
    if nm.startswith('Jingle'):
        k = int(nm[6:]) - 1
        txt += ('\nNot in the API song table: the game posts this address straight into its song\n'
                'mailbox ($D95A/$D95B) from bank 0 at $%04X.' % info['jingle_refs'][k])
    g.blocks.setdefault(s['routine'], txt)
for it, k in itab_no.items():
    g.blocks.setdefault(it + 2, 'Instrument table %d, entries 1..%d (the song routines point 2 bytes before:\nentry 0 is never read)' % (k, len(W.instr_tables[it])))
for a in wave_in_code:
    pass
slot = 0
for i, a in enumerate(JT_SLOTS):
    if i < 8:
        g.comments[a] = API_NAMES[i]
    elif JT[i] in song_no and is_song(v, JT[i]):
        g.comments[a] = 'song slot %d: song %d' % (slot + 1, slot_song[slot]) if len(SONG_SLOTS) != len(SONGS_JT) \
            else song_no[JT[i]].replace('Song', 'song ')
        slot += 1
    else:
        g.comments[a] = info.get('jt_names', {}).get(JT[i], 'PlaySfx without the SFX-29 test (A = id)')
for a in JT_DEAD:
    tgt = w16(v, a + 1)
    g.items[a] = (3, (lambda t: lambda ref: ['jp ' + ref(t)])(tgt))
    g.comments[a] = info.get('jt_dead_comment', 'unused song slot (points into data)')
for a in JT_FALL:
    tgt = w16(v, a + 1)
    g.items[a] = (3, (lambda t: lambda ref: ['jp ' + ref(t)])(tgt))
    g.comments[a] = g.comments.get(a, '') + '; ' + info['jt_fall_comment'].split('\n')[0] + ' ...'
    if a == JT_FALL[0]:
        g.blocks[a] = 'Song slot(s) %s: each ' % ', '.join('%d' % ((x - info['jt']) // 3 - 7) for x in JT_FALL) + info['jt_fall_comment']
for a, b in overlap_waves:
    g.comments[a] = '16-byte wave: continues into the next wave'
for a in W.unterminated:
    g.comments[a] = 'no DRUM_LOOP: the pattern runs into the next data'
g.blocks.setdefault(cfg['sfx_base'] + 2, 'SFX table (indexed from 2 bytes before: id 1 is the first entry)')

# unreferenced gaps
occ = set()
for a, nn in g.code.items():
    occ.update(range(a, a + nn))
for a, (nn, _) in g.items.items():
    occ.update(range(a, a + nn))
gaps = []
a = 0x4000
while a < 0x8000:
    if a not in occ:
        b = a
        while b < 0x8000 and b not in occ:
            b += 1
        gaps.append((a, b))
        if a not in g.blocks:
            g.blocks[a] = 'Unreferenced (%d bytes)' % (b - a)
        a = b
    else:
        a += 1

inner = set()
for a, nn in list(g.code.items()) + [(a, x[0]) for a, x in g.items.items()]:
    for i in range(1, nn):
        inner.add(a + i)
dropped = [(hex(a), nm) for a, nm in g.labels.items() if a in inner]
for a in [a for a in g.labels if a in inner]:
    del g.labels[a]
if dropped:
    print('labels inside items dropped:', dropped[:20])
for a in [a for a in g.operand if v[a] in (0x01, 0x11, 0x21) and g.operand[a] not in g.labels.values()]:
    del g.operand[a]

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
open(sys.argv[3], 'w').write(txt)
meta = dict(game=GAME, bank=cfg['bank'], pages=list(cfg['pages']), act=cfg.get('act', 0x27),
            ram={nm: a for a, nm in g.symbols.items()},
            labels={nm: a for a, nm in g.labels.items()},
            api=dict(update=JT[0], pause=JT[1], resume=JT[2], stopall=JT[3], playsfx=JT[4], init=JT[5]),
            songs=[[song_no[r], r] for r in SONGS],
            stream=sorted(a for a, it in W.items.items() if it[1] == 'stream'),
            order=sorted(a for a, it in W.items.items() if it[1] == 'order'),
            drumpat=sorted(a for a, it in W.items.items() if it[1] == 'drumpat'),
            drumpat2=sorted(a for a, it in W.items.items() if it[1] == 'drumpat' and it[0] == 2),
            sfx_count=cfg['sfx_count'] + (3 if GAME == 'smurfs' else 0),
            gaps=[[a, b - a] for a, b in gaps])
vdir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'verify')
os.makedirs(vdir, exist_ok=True)
json.dump(meta, open(os.path.join(vdir, m['short'] + '.json'), 'w'))
print('ok', len(g.code), 'instructions,', len(g.items), 'items,', len(gaps), 'unreferenced ranges')
