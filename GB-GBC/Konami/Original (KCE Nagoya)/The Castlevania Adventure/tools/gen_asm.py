"""Generate a byte-exact RGBDS disassembly of the Konami early GB sound driver.
usage: gen_asm.py cva|mm|nem|cv2 out.asm"""
import sys, re, collections, os
sys.path.insert(0, os.path.dirname(__file__))
from sm83 import decode
import kdata

game = sys.argv[1]
cfg = __import__('cfg_' + game)
G = kdata.PROFILES[game]
A = kdata.analyse(G)
rom = A['rom']

HW = {0xFF00 + i: n for i, n in {
    0x05: 'rTIMA', 0x06: 'rTMA', 0x07: 'rTAC', 0x0F: 'rIF',
    0x10: 'rNR10', 0x11: 'rNR11', 0x12: 'rNR12', 0x13: 'rNR13', 0x14: 'rNR14',
    0x16: 'rNR21', 0x17: 'rNR22', 0x18: 'rNR23', 0x19: 'rNR24',
    0x1A: 'rNR30', 0x1B: 'rNR31', 0x1C: 'rNR32', 0x1D: 'rNR33', 0x1E: 'rNR34',
    0x20: 'rNR41', 0x21: 'rNR42', 0x22: 'rNR43', 0x23: 'rNR44',
    0x24: 'rNR50', 0x25: 'rNR51', 0x26: 'rNR52', 0x30: '_AUD3WAVERAM', 0x40: 'rLCDC', 0x44: 'rLY',
    0xFF: 'rIE'}.items()}

# ------------------------------------------------------------------ labels
names = dict(cfg.NAMES)          # addr -> global label
comments = dict(cfg.COMMENTS)    # addr -> line comment
blocks = dict(cfg.BLOCKS)        # addr -> block comment (lines) before label
ram = cfg.RAM                    # list of (addr, name, size)

def ramsym(v):
    for a, n, s in ram:
        if v == a: return n
    for a, n, s in ram:
        if a < v < a + s: return f'{n} + ${v - a:02X}'
    return None

snd = A['snd']
# stream labels
streamlab = {}
for sid, s in snd.items():
    for st in s['streams']:
        streamlab.setdefault(st['ptr'], f"Snd{sid:02X}_{G['trkname'][st['t']]}")
    names.setdefault(s['hdr'], f'SndHdr{sid:02X}')
for p, n in streamlab.items(): names.setdefault(p, n)
# vibrato labels
for i, p in A['vib'].items():
    if p not in names: names[p] = f'Vib{i:02X}'
# other stream-internal labels: name after the owner whose stream contains them
own = A['own']
def owner_of(a):
    o = sorted(x for x in own.get(a, ()) if isinstance(x[0], int))
    return o[0] if o else None
for a in sorted(A['labels']):
    if a in names: continue
    o = owner_of(a)
    if o: names[a] = f"Snd{o[0]:02X}_{G['trkname'][o[1]]}_{a:04X}"
    else: names[a] = f'SndData_{a:04X}'

# ------------------------------------------------------------------ code pass: collect branch targets
segs = cfg.SEGMENTS  # list of (start, end_inclusive, kind, extra)
inrom = lambda v: any(s <= v <= e for s, e, k, x in segs)
local = {}
for s, e, k, x in segs:
    if k != 'code': continue
    pc = s
    while pc <= e:
        l, t, tg = decode(rom.b, pc)
        if tg is not None and not t.startswith('rst') and tg not in names and inrom(tg):
            local[tg] = True
        pc += l
for s, e, k, x in segs:
    if k == 'dw':
        for a in range(s, e + 1, 2):
            v = rom.w(a)
            if v not in names and inrom(v): local[v] = True

# assign scopes
glob_sorted = sorted(names)
def scope_of(a):
    best = None
    for g_ in glob_sorted:
        if g_ <= a: best = g_
        else: break
    return best
locname = {}
for a in local:
    locname[a] = f'.l{a:04X}'

def ref(v, here):
    """symbolic reference to ROM address v from address 'here'"""
    if v in names: return names[v]
    if v in locname:
        if scope_of(v) == scope_of(here): return locname[v]
        return names[scope_of(v)] + locname[v]
    return None

# ------------------------------------------------------------------ instruction rendering
def render(pc, l, t):
    m = re.match(r'(\w+)\s*(.*)', t)
    mn, ops = m.group(1), m.group(2)
    if t == 'ld [$FF00+c],a': return 'ldh [c], a'
    if t == 'ld a,[$FF00+c]': return 'ldh a, [c]'
    branch = mn in ('jr', 'jp', 'call')
    def sub16(mo):
        v = int(mo.group(1), 16)
        if branch:
            r = ref(v, pc)
            if r is None:
                if inrom(v): raise SystemExit(f'no label for branch {v:04X} at {pc:04X}')
                return f'${v:04X}'
            return r
        if 0xFF00 <= v and v in HW: return HW[v]
        if v in getattr(cfg, 'EXTRA_SYM', {}): return cfg.EXTRA_SYM[v]
        r = ram_override.get(pc) or ramsym(v)
        if r: return r
        if inrom(v) or v in names:
            r = ref(v, pc)
            if r: return r
        return f'${v:04X}'
    ops2 = re.sub(r'\$([0-9A-F]{4})', sub16, ops)
    # 8-bit immediates with configured symbols
    if pc in cfg.IMM8:
        ops2 = re.sub(r'\$([0-9A-F]{2})\b', cfg.IMM8[pc], ops2, count=1)
    elif hasattr(cfg, 'imm8'):
        ops2 = cfg.imm8(pc, mn, ops2)
    ops2 = ops2.replace(',', ', ')
    # RGBDS needs explicit ldh for $FFxx only when it was ldh
    out = f'{mn} {ops2}'.strip()
    return out

ram_override = getattr(cfg, 'RAMOVR', {})

# ------------------------------------------------------------------ data emitters
ev = A['events']; vibev = A['vibev']
def fmtarg(a):
    if isinstance(a, str): return a
    return f'${a:02X}' if a > 9 else str(a)

def emit_event(pc, n, mac, args, out):
    if mac in ('SND_CALL', 'SND_JUMP'):
        out.append(f'\t{mac} {names[args[0]]}')
    elif mac == 'RAW':
        out.append('\tdb ' + ', '.join(f'${x:02X}' for x in args))
    elif mac in ('PAN', 'SWEEP', 'TEMPO', 'NOISE') or mac.startswith('CMD_'):
        out.append(f'\t{mac} ${args[0]:02X}')
    elif mac == 'VIB_STEP':
        out.append(f'\tVIB_STEP {args[0]}, {args[1]}, ${args[2]:03X}')
    else:
        out.append(f'\t{mac} ' + ', '.join(fmtarg(a) for a in args) if args else f'\t{mac}')

def rawdb(bs, per=16):
    out = []
    for i in range(0, len(bs), per):
        out.append('\tdb ' + ', '.join(f'${x:02X}' for x in bs[i:i + per]))
    return out

def gen_data(s, e, out):
    """sound data region: headers, tables, streams, vib, raw."""
    hdrs = {v['hdr']: k for k, v in snd.items()}
    special = cfg.DATA_SPECIAL  # addr -> (len, kind, extra)
    pc = s
    pend = []
    def flush():
        if pend:
            out.extend(rawdb(bytes(pend[1]), 16) if False else [])
    raw = []
    def flushraw():
        nonlocal raw
        if raw:
            out.extend(rawdb(bytes(raw)))
            raw = []
    while pc <= e:
        if pc in blocks:
            flushraw(); out.append('')
            out.extend('; ' + x if x else ';' for x in blocks[pc])
        if pc in names and not (pc in hdrs and False):
            flushraw()
            if pc in streamlab or pc in hdrs or pc in A['vib'].values(): out.append('')
            out.append(f'{names[pc]}:')
        if pc in special:
            flushraw()
            n, kind, extra = special[pc]
            if kind == 'dw':
                for i in range(0, n, 2):
                    v = rom.w(pc + i)
                    c = extra(i // 2) if callable(extra) else ''
                    out.append(f'\tdw {names.get(v, f"${v:04X}")}' + (f' ; {c}' if c else ''))
            elif kind == 'period':
                for i in range(0, n, 2 * 12):
                    row = [rom.w(pc + j) for j in range(i, min(n, i + 24), 2)]
                    out.append('\tdw ' + ', '.join(f'${x:03X}' for x in row) + f' ; octave index {i // 24}')
            elif kind == 'db':
                per = extra or 16
                bs = [rom.b(pc + i) for i in range(n)]
                # split at labels inside
                cur = []
                for i, x in enumerate(bs):
                    if i and (pc + i) in names:
                        out.extend(rawdb(bytes(cur), per)); cur = []
                        out.append(f'{names[pc + i]}:')
                    cur.append(x)
                out.extend(rawdb(bytes(cur), per))
            elif kind == 'code':
                code_listing(pc, pc + n - 1, out, skip_first_label=True)
            pc += n; continue
        if pc in hdrs:
            flushraw()
            sid = hdrs[pc]; h = snd[sid]
            tr = [G['trkname'][x['t']] for x in h['streams']]
            out.append(f"\tSND_HEADER ${h['prio']:02X}, ${h['mask']:02X} ; tracks: {', '.join(tr)}")
            for x in h['streams']:
                out.append(f"\tdw {names[x['ptr']]}")
            pc += 2 + 2 * len(h['streams']); continue
        if pc in ev:
            flushraw()
            n, mac, args, cls = ev[pc]
            # a label strictly inside this event would break exactness
            for i in range(1, n):
                if pc + i in names: print(f'!! label inside event at {pc + i:04X}')
            emit_event(pc, n, mac, args, out)
            if pc in comments: out[-1] += ' ; ' + comments[pc]
            pc += n; continue
        if pc in vibev and not own_stream(pc):
            flushraw()
            n, mac, args = vibev[pc]
            emit_event(pc, n, mac, args, out)
            pc += n; continue
        raw.append(rom.b(pc))
        if pc in comments: flushraw(); out[-1] += ' ; ' + comments[pc]
        pc += 1
    flushraw()

def own_stream(a):
    return any(isinstance(x[0], int) for x in own.get(a, ()))

def code_listing(s, e, out, skip_first_label=False):
    pc = s
    while pc <= e:
        if pc in blocks:
            out.append('')
            out.extend('; ' + x if x else ';' for x in blocks[pc])
        if pc in names and not (skip_first_label and pc == s):
            if pc not in blocks: out.append('')
            out.append(f'{names[pc]}:')
        elif pc in locname:
            out.append(f'{locname[pc]}:')
        l, t, tg = decode(rom.b, pc)
        line = '\t' + render(pc, l, t)
        if pc in comments: line += ' ; ' + comments[pc]
        out.append(line)
        pc += l
    if pc != e + 1: raise SystemExit(f'code segment {s:04X}-{e:04X} overruns to {pc:04X}')

out = []
out.extend(cfg.HEADER)
for s, e, k, x in segs:
    sec = x['section'] if isinstance(x, dict) and 'section' in x else None
    if sec:
        out.append('')
        out.append(sec)
    if k == 'code':
        code_listing(s, e, out)
    elif k == 'dw':
        if s in names: out.append(f'{names[s]}:')
        for a in range(s, e + 1, 2):
            v = rom.w(a)
            c = comments.get(a, '')
            r = ref(v, a) or ramsym(v) or f'${v:04X}'
            out.append(f'\tdw {r}' + (f' ; {c}' if c else ''))
    elif k == 'db':
        if s in blocks:
            out.append(''); out.extend('; ' + y if y else ';' for y in blocks[s])
        if s in names: out.append(f'{names[s]}:')
        per = x.get('per', 16) if isinstance(x, dict) else 16
        bs = bytes(rom.b(a) for a in range(s, e + 1))
        lines = rawdb(bs, per)
        if s in comments: lines[0] += ' ; ' + comments[s]
        out.extend(lines)
    elif k == 'data':
        gen_data(s, e, out)
open(sys.argv[2], 'w').write('\n'.join(out) + '\n')
print('lines', len(out))
