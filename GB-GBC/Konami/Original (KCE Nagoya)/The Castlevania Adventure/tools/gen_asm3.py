"""Generate a byte-exact RGBDS disassembly of a multi-bank Konami GB sound driver (Nemesis II, TMNT II).
usage: gen_asm3.py n2|tm2 out.asm
Like gen_asm.py, but every segment, label and data analysis belongs to a bank (0 = ROM0). The data
decoder module comes from the config (DECODER, default kdata3)."""
import sys, re, os
sys.path.insert(0, os.path.dirname(__file__))
from sm83 import decode
game = sys.argv[1]
cfg = __import__('cfg_' + game)
kdata3 = __import__(getattr(cfg, 'DECODER', 'kdata3'))
G = kdata3.PROFILES[game]
ROM = open(G['rom'], 'rb').read()
BANKS = sorted(G['banks'])
AN = {b: kdata3.analyse(G, b) for b in BANKS}

def rb(bank, a): return ROM[a if a < 0x4000 else bank * 0x4000 + a - 0x4000]
def rw(bank, a): return rb(bank, a) | rb(bank, a + 1) << 8

HW = {0xFF00 + i: n for i, n in {
    0x05: 'rTIMA', 0x06: 'rTMA', 0x07: 'rTAC', 0x0F: 'rIF',
    0x10: 'rNR10', 0x11: 'rNR11', 0x12: 'rNR12', 0x13: 'rNR13', 0x14: 'rNR14',
    0x16: 'rNR21', 0x17: 'rNR22', 0x18: 'rNR23', 0x19: 'rNR24',
    0x1A: 'rNR30', 0x1B: 'rNR31', 0x1C: 'rNR32', 0x1D: 'rNR33', 0x1E: 'rNR34',
    0x20: 'rNR41', 0x21: 'rNR42', 0x22: 'rNR43', 0x23: 'rNR44',
    0x24: 'rNR50', 0x25: 'rNR51', 0x26: 'rNR52', 0x30: '_AUD3WAVERAM', 0xFF: 'rIE'}.items()}

names = dict(cfg.NAMES)          # (bank, addr) -> label
blocks = dict(cfg.BLOCKS)        # (bank, addr) -> comment lines
comments = dict(cfg.COMMENTS)    # (bank, addr) -> line comment
ram = cfg.RAM

def ramsym(v):
    for a, n, s in ram:
        if v == a: return n
    for a, n, s in ram:
        if a < v < a + s: return f'{n} + ${v - a:02X}'
    return None

TRKN = G['trkname']
streamlab = {}
for b in BANKS:
    A = AN[b]; pre = cfg.PREFIX[b]
    for sid, s in A['snd'].items():
        for st in s['streams']:
            streamlab.setdefault((b, st['ptr']), f"Snd{sid:02X}_{TRKN[st['t']]}")
        names.setdefault((b, s['hdr']), f'SndHdr{sid:02X}')
    for i, p in A['vib'].items():
        names.setdefault((b, p), f'{pre}Vib{i:02X}')
for k, n in streamlab.items(): names.setdefault(k, n)

def owner_of(b, a):
    o = sorted(x for x in AN[b]['own'].get(a, ()) if isinstance(x[0], int))
    return o[0] if o else None
for b in BANKS:
    for a in sorted(AN[b]['labels']):
        if (b, a) in names: continue
        o = owner_of(b, a)
        names[(b, a)] = f"Snd{o[0]:02X}_{TRKN[o[1]]}_{a:04X}" if o else f'{cfg.PREFIX[b]}Data_{a:04X}'

segs = cfg.SEGMENTS   # (bank, start, end, kind, extra)
def inrom(b, v):
    return any(sb == (0 if v < 0x4000 else b) and s <= v <= e for sb, s, e, k, x in segs)

local = set()
for sb, s, e, k, x in segs:
    if k != 'code': continue
    pc = s
    while pc <= e:
        l, t, tg = decode(lambda a: rb(sb, a), pc)
        if tg is not None and not t.startswith('rst'):
            tb = cfg.XREF.get((sb, pc), 0 if tg < 0x4000 else sb)
            if (tb, tg) not in names and inrom(tb, tg): local.add((tb, tg))
        pc += l
for sb, s, e, k, x in segs:
    if k == 'dw':
        for a in range(s, e + 1, 2):
            v = rw(sb, a); tb = 0 if v < 0x4000 else sb
            if (tb, v) not in names and inrom(tb, v): local.add((tb, v))

glob_sorted = sorted(names)
def scope_of(b, a):
    best = None
    for k in glob_sorted:
        if k[0] == b and k[1] <= a: best = k
    return best

def ref(v, b, here):
    """symbolic reference to ROM address v (seen from bank b, address here)"""
    tb = cfg.XREF.get((b, here), 0 if v < 0x4000 else b)
    if (tb, v) in names: return names[(tb, v)]
    if (tb, v) in local:
        sc = scope_of(tb, v)
        if sc == scope_of(b, here) and tb == b: return f'.l{v:04X}'
        return names[sc] + f'.l{v:04X}'
    return None

def render(b, pc, l, t):
    m = re.match(r'(\w+)\s*(.*)', t)
    mn, ops = m.group(1), m.group(2)
    if t == 'ld [$FF00+c],a': return 'ldh [c], a'
    if t == 'ld a,[$FF00+c]': return 'ldh a, [c]'
    branch = mn in ('jr', 'jp', 'call')
    def sub16(mo):
        v = int(mo.group(1), 16)
        if branch:
            r = ref(v, b, pc)
            if r is None:
                if inrom(b, v): raise SystemExit(f'no label for branch {v:04X} at {b:X}:{pc:04X}')
                return f'${v:04X}'
            return r
        if 0xFF00 <= v and v in HW: return HW[v]
        if v in cfg.EXTRA_SYM.get(b, {}): return cfg.EXTRA_SYM[b][v]
        if v in cfg.EXTRA_SYM.get('all', {}): return cfg.EXTRA_SYM['all'][v]
        r = ramsym(v)
        if r: return r
        if inrom(b, v) or (0 if v < 0x4000 else b, v) in names:
            r = ref(v, b, pc)
            if r: return r
        return f'${v:04X}'
    ops2 = re.sub(r'\$([0-9A-F]{4})', sub16, ops)
    ops2 = cfg.imm8(b, pc, mn, ops2)
    ops2 = ops2.replace(',', ', ')
    return f'{mn} {ops2}'.strip()

def fmtarg(a):
    if isinstance(a, str): return a
    return f'${a:02X}' if a > 9 else str(a)

def emit_event(b, pc, n, mac, args, out):
    if hasattr(cfg, 'emit'):
        line = cfg.emit(mac, args, lambda a: names[(b, a)])
        if line is not None: out.append(line); return
    if mac == 'SND_CALL':
        out.append(f'\t{mac} {names[(b, args[0])]}')
    elif mac == 'RAW':
        out.append('\tdb ' + ', '.join(f'${x:02X}' for x in args))
    elif mac in ('PAN', 'SWEEP', 'TEMPO', 'NOISE', 'RAW_UNIT', 'VIBRATO_OFF') or mac.startswith('CMD_'):
        out.append(f'\t{mac} ${args[0]:02X}')
    elif mac == 'VIBRATO':
        out.append(f'\tVIBRATO ${args[0]:02X}, {args[1]}, {args[2]}' if args[0] > 15 else f'\tVIBRATO {args[0]}, {args[1]}, {args[2]}')
    elif mac == 'RAW_HEADER':
        out.append(f'\tRAW_HEADER {args[0]}, ${args[1]:02X}, ${args[2]:02X}')
    elif mac == 'RAW_NOTE':
        out.append(f'\tRAW_NOTE {args[0]}, ${args[1]:03X}')
    elif mac == 'VIB_STEP':
        out.append(f'\tVIB_STEP {args[0]}, {args[1]}, {args[2]}')
    else:
        out.append(f'\t{mac} ' + ', '.join(fmtarg(a) for a in args) if args else f'\t{mac}')

def rawdb(bs, per=16):
    return ['\tdb ' + ', '.join(f'${x:02X}' for x in bs[i:i + per]) for i in range(0, len(bs), per)]

def blk(out, k):
    if k in blocks:
        out.append('')
        out.extend('; ' + x if x else ';' for x in blocks[k])

def gen_data(b, s, e, out):
    A = AN[b]; ev = A['events']; vibev = A['vibev']; own = A['own']
    hdrs = {v['hdr']: k for k, v in A['snd'].items()}
    special = cfg.DATA_SPECIAL.get(b, {})
    raw = []
    def flushraw():
        nonlocal raw
        if raw: out.extend(rawdb(bytes(raw))); raw = []
    pc = s
    while pc <= e:
        if (b, pc) in blocks: flushraw(); blk(out, (b, pc))
        if (b, pc) in names:
            flushraw()
            if (b, pc) in streamlab or pc in hdrs or pc in A['vib'].values(): out.append('')
            out.append(f'{names[(b, pc)]}:')
        if pc in special:
            flushraw()
            n, kind, extra = special[pc]
            if kind == 'dw':
                for i in range(0, n, 2):
                    v = rw(b, pc + i)
                    c = extra(i // 2) if callable(extra) else ''
                    out.append(f'\tdw {names.get((b, v), f"${v:04X}")}' + (f' ; {c}' if c else ''))
            elif kind == 'period':
                for i in range(0, n, 24):
                    row = [rw(b, pc + j) for j in range(i, min(n, i + 24), 2)]
                    out.append('\tdw ' + ', '.join(f'${x:03X}' for x in row) + f' ; octave index {i // 24}')
            elif kind == 'db':
                cur = []
                for i in range(n):
                    if i and (b, pc + i) in names:
                        out.extend(rawdb(bytes(cur), extra or 16)); cur = []
                        out.append(f'{names[(b, pc + i)]}:')
                    cur.append(rb(b, pc + i))
                out.extend(rawdb(bytes(cur), extra or 16))
            pc += n; continue
        if pc in hdrs:
            flushraw()
            sid = hdrs[pc]; h = A['snd'][sid]
            tr = [TRKN[x['t']] for x in h['streams']]
            out.append(f"\tSND_HEADER ${h['prio']:02X}, ${h['mask']:02X} ; tracks: {', '.join(tr)}")
            for x in h['streams']: out.append(f"\tdw {names[(b, x['ptr'])]}")
            pc += 2 + 2 * len(h['streams']); continue
        if pc in ev:
            flushraw()
            n, mac, args, cls = ev[pc]
            for i in range(1, n):
                if (b, pc + i) in names: print(f'!! label inside event at {b:X}:{pc + i:04X}')
            emit_event(b, pc, n, mac, args, out)
            c = comments.get((b, pc)) or ('loop byte read both as a start and as an end (see doc)'
                                         if (b, pc) in kdata3.CONFLICTS else None)
            if c: out[-1] += ' ; ' + c
            pc += n; continue
        if pc in vibev and not any(isinstance(x[0], int) for x in own.get(pc, ())):
            flushraw()
            n, mac, args = vibev[pc]
            emit_event(b, pc, n, mac, args, out); pc += n; continue
        raw.append(rb(b, pc))
        if (b, pc) in comments: flushraw(); out[-1] += ' ; ' + comments[(b, pc)]
        pc += 1
    flushraw()

def code_listing(b, s, e, out):
    pc = s
    while pc <= e:
        if (b, pc) in blocks: blk(out, (b, pc))
        if (b, pc) in names:
            if (b, pc) not in blocks: out.append('')
            out.append(f'{names[(b, pc)]}:')
        elif (b, pc) in local:
            out.append(f'.l{pc:04X}:')
        l, t, tg = decode(lambda a: rb(b, a), pc)
        line = '\t' + render(b, pc, l, t)
        if (b, pc) in comments: line += ' ; ' + comments[(b, pc)]
        out.append(line)
        pc += l
    if pc != e + 1: raise SystemExit(f'code segment {b:X}:{s:04X}-{e:04X} overruns to {pc:04X}')

out = list(cfg.HEADER)
for sb, s, e, k, x in segs:
    if isinstance(x, dict) and 'section' in x:
        out.append(''); out.append(x['section'])
    if k == 'code': code_listing(sb, s, e, out)
    elif k == 'dw':
        blk(out, (sb, s))
        if (sb, s) in names: out.append(f'{names[(sb, s)]}:')
        for a in range(s, e + 1, 2):
            v = rw(sb, a)
            r = ref(v, sb, a) or f'${v:04X}'
            out.append(f'\tdw {r}')
    elif k == 'db':
        blk(out, (sb, s))
        if (sb, s) in names: out.append(f'{names[(sb, s)]}:')
        out.extend(rawdb(bytes(rb(sb, a) for a in range(s, e + 1)), (x or {}).get('per', 16) if isinstance(x, dict) else 16))
    elif k == 'data': gen_data(sb, s, e, out)
open(sys.argv[2], 'w').write('\n'.join(out) + '\n')
print('lines', len(out))
