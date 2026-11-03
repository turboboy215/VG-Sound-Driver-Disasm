#!/usr/bin/env python3
"""Generate RGBDS source for Biox sound driver A (Noobow / Pocket Bowling)."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from asmgen import Gen
from engA import walk

NOTE = ['C', 'Cs', 'D', 'Ds', 'E', 'F', 'Fs', 'G', 'Gs', 'A', 'As', 'B', 'Bs']

def notename(v):
    if v == 0x0D: return 'REST'
    lo = v & 15; hi = v >> 4
    if lo <= 12: return '%s_%d' % (NOTE[lo], hi + 1)
    return '$%02X' % v

# ---------------------------------------------------------------- RAM symbols
def ram_symbols():
    ram = {}
    def blk(base, name, size):
        for i in range(size):
            ram[base + i] = name if i == 0 else '%s+%d' % (name, i)
    blk(0xFFC0, 'hSndPtrCh1', 2); blk(0xFFC2, 'hSndPtrCh2', 2); blk(0xFFC4, 'hSndPtrCh3', 2)
    blk(0xFFC6, 'hSndPtrCh4', 2); blk(0xFFC8, 'hSndPtrSfx2', 2); blk(0xFFCA, 'hSndPtrSfx4', 2)
    blk(0xFFCC, 'hSndTempo', 1); blk(0xFFCD, 'hSndUnusedCD', 1); blk(0xFFCE, 'hSndUnusedCE', 2)
    blk(0xFFD0, 'hSndLastNote', 6); blk(0xFFD6, 'hSndLastLen', 6); blk(0xFFDC, 'hSndLenCount', 6)
    blk(0xFFE2, 'hSndInst', 6); blk(0xFFED, 'hSndCurMusic', 1); blk(0xFFEE, 'hSndCurSfx', 1)
    for n, base in enumerate([0xDE00, 0xDE1E, 0xDE3C, 0xDE5A, 0xDE78, 0xDE96]):
        nm = ['wSndCh1', 'wSndCh2', 'wSndCh3', 'wSndCh4', 'wSndSfx2', 'wSndSfx4'][n]
        for i in range(0x1E):
            ram[base + i] = nm if i == 0 else '%s+$%02X' % (nm, i)
    names = {0xDEC8: 'wSndLastByte', 0xDEC9: 'wSndSfxOwns', 0xDECA: 'wSndSlur', 0xDECB: 'wSndVibNew',
             0xDECC: 'wSndInstNew', 0xDECD: 'wSndChanOfs', 0xDECE: 'wSndChanOfs+1', 0xDECF: 'wSndRegOfs',
             0xDED0: 'wSndProfStart', 0xDED1: 'wSndProfEnd', 0xDED2: 'wSndProfAvg', 0xDED3: 'wSndProfValid',
             0xDED4: 'wSndProfMax', 0xDEE7: 'wSndTrigger', 0xDEE8: 'wSndNewRow'}
    ram.update(names)
    blk(0xDED5, 'wSndEnvPtr', 12); blk(0xDEE1, 'wSndEnvCount', 6)
    return ram

RAM_EQU = '''; ---- RAM (identical in Noobow and Pocket Bowling) ----
DEF hSndPtrCh1    EQU $FFC0   ; track pointers, $FFFF = channel off
DEF hSndPtrCh2    EQU $FFC2
DEF hSndPtrCh3    EQU $FFC4
DEF hSndPtrCh4    EQU $FFC6
DEF hSndPtrSfx2   EQU $FFC8   ; SFX track on hardware ch2
DEF hSndPtrSfx4   EQU $FFCA   ; SFX track on hardware ch4
DEF hSndTempo     EQU $FFCC   ; TMA value for the music timer
DEF hSndUnusedCD  EQU $FFCD   ; written by $E6, never read
DEF hSndUnusedCE  EQU $FFCE   ; word written by $E6/$E7/$E8, never read
DEF hSndLastNote  EQU $FFD0   ; [6] last note byte per track (index c = 0-5)
DEF hSndLastLen   EQU $FFD6   ; [6] last length in ticks
DEF hSndLenCount  EQU $FFDC   ; [6] ticks left on the current row
DEF hSndInst      EQU $FFE2   ; [6] $E2 value (envelope sequence / wave)
DEF hSndCurMusic  EQU $FFED   ; last music id started
DEF hSndCurSfx    EQU $FFEE   ; last SFX id started
DEF wSndCh1       EQU $DE00   ; 6 track structs of $1E bytes
DEF wSndCh2       EQU $DE1E
DEF wSndCh3       EQU $DE3C
DEF wSndCh4       EQU $DE5A
DEF wSndSfx2      EQU $DE78
DEF wSndSfx4      EQU $DE96
DEF wSndLastByte  EQU $DEC8   ; last track byte parsed (checked for $F3)
DEF wSndSfxOwns   EQU $DEC9   ; $FF while the SFX track owns the channel being updated
DEF wSndSlur      EQU $DECA   ; set by $F5
DEF wSndVibNew    EQU $DECB   ; set by $E4
DEF wSndInstNew   EQU $DECC   ; set by $E2
DEF wSndChanOfs   EQU $DECD   ; word: offset of current struct from wSndCh1
DEF wSndRegOfs    EQU $DECF   ; NRx0 offset of current channel (0/5/10/15)
DEF wSndProfStart EQU $DED0   ; LY at start of the timer update
DEF wSndProfEnd   EQU $DED1   ; LY at end
DEF wSndProfAvg   EQU $DED2   ; running average of lines used
DEF wSndProfValid EQU $DED3   ; 0 until the first measurement
DEF wSndProfMax   EQU $DED4   ; maximum lines used
DEF wSndEnvPtr    EQU $DED5   ; [6 words] envelope-sequence pointers
DEF wSndEnvCount  EQU $DEE1   ; [6] envelope-sequence step counters
DEF wSndTrigger   EQU $DEE7   ; $80 when the envelope stepper rewrote NRx2
DEF wSndNewRow    EQU $DEE8   ; $FF when a new row was parsed this tick
'''

def build(cfg):
    rom = open(cfg['rom'], 'rb').read()
    bank = cfg['bank']
    g = Gen(rom, bank, 0x4000, cfg['end'])
    g.ram = ram_symbols()
    rw = g.rw
    # ---- driver labels
    for a, n in cfg['names'].items():
        g.lab(a, n)
    for a in cfg['tables']:
        g.ptr_ok.add(a)
    g.ptr_ok.update(cfg['names'].keys())
    code = cfg['code']
    for s, e in code:
        g.code_pass1(s, e)
    # ---- song / sfx table walking
    starts = []
    tracknames = {}
    headers = []   # (addr, [ptrs], name)
    for i in range(cfg['nsongs']):
        h = cfg['song_hdr'](g, i)
        ptrs = [rw(h + 2 * j) for j in range(4)]
        headers.append((h, ptrs, 'Mus%02X' % i, 4))
        for j, p in enumerate(ptrs):
            if p != 0xFFFF:
                starts.append((p, j))
                tracknames.setdefault(p, 'Mus%02X_Ch%d' % (i, j + 1))
    for i in range(cfg['nsfx']):
        sid = cfg['sfx_first'] + i
        h = cfg['sfx_hdr'](g, i)
        ptrs = [rw(h + 2 * j) for j in range(2)]
        headers.append((h, ptrs, 'Sfx%02X' % sid, 2))
        for j, p in enumerate(ptrs):
            if p != 0xFFFF:
                starts.append((p, 4 + j))
                tracknames.setdefault(p, 'Sfx%02X_Ch%d' % (sid, [2, 4][j]))
    items, labels = walk(rom, bank, starts, cfg['ver'])
    # unreferenced streams in the data area
    ds, de = cfg['data']
    covered = set()
    def recov():
        covered.clear()
        for a, (n, k, i) in items.items():
            for x in range(n): covered.add(a + x)
    recov()
    tabs = cfg['data_tables']   # list of (s,e) table ranges inside data area
    def intab(a): return any(s <= a < e for s, e in tabs)
    unused = []
    dead = set()
    a = ds
    while a < de:
        if a in covered or intab(a) or a in dead:
            a += 1; continue
        # single $FF right after covered data = unreachable terminator
        if g.rb(a) == 0xFF and (a - 1) in covered:
            dead.add(a); a += 1; continue
        unused.append(a)
        it2, lb2 = walk(rom, bank, [(a, -1)], cfg['ver'])
        for k, v in it2.items():
            if k not in items: items[k] = v
        for k, v in lb2.items(): labels.setdefault(k, set()).update(v)
        tracknames.setdefault(a, 'SndUnused_%04X' % a)
        recov()
        a += 1
    # ---- labels for data
    for a, n in tracknames.items(): g.lab(a, n)
    for a in labels:
        if a not in g.labels: g.lab(a, 'Trk_%04X' % a)
    if not cfg.get('direct'):
        for h, ptrs, nm, n in headers:
            g.lab(h, nm)
    # ---- emit code
    for s, e in code:
        g.code(s, e)
    for s, e, kind in cfg['code_data']:
        if kind == 'dw': g.dw(s, e, per=4)
        else: g.db(s, e)
    cfg['emit_tables'](g)
    # headers
    for h, ptrs, nm, n in headers:
        if h in g.items: continue
        g.line(h, 2 * n, '\tdw ' + ', '.join('SND_NONE' if p == 0xFFFF else g.ref(p) for p in ptrs) + (('\t; ' + nm) if cfg.get('direct') else ''))
    # tracks
    for a in sorted(items):
        n, k, info = items[a]
        if a in g.items: continue
        if k == 'note':
            v, ch = info
            nxt = a + 1
            isnoise = ch in (3, 5) or ch == -1 and False
            txt = ('$%02X' % v) if (ch in (3, 5) or ch == -1) else notename(v)
            if nxt in items and items[nxt][1] == 'len' and nxt not in g.labels:
                g.line(a, 2, '\tsnd_note %s, %d' % (txt, items[nxt][2]))
            else:
                g.line(a, 1, '\tsnd_note %s' % txt)
        elif k == 'len':
            g.line(a, 1, '\tsnd_len %d' % info)
        elif k == 'rawnote':
            pass
        elif k in ('end', 'endbad'):
            g.line(a, 1, '\tsnd_end' if info == 0xFF else ('\tsnd_end_e0' if info == 0xE0 else '\tdb $%02X\t; end of track (no handler)' % info))
        elif k == 'cmd':
            b, name, args, kind = info
            if kind in ('call', 'jump'):
                t = args[0] | args[1] << 8
                g.line(a, n, '\t%s %s' % (name.replace('sA_', 'snd_'), g.ref(t)))
            elif kind == 'loop':
                t = args[2] | args[3] << 8
                g.line(a, n, '\tsnd_loop %d, %d, %s' % (args[0], args[1], g.ref(t)))
            elif kind == 'raw':
                v, ch = items[a + 1][2]
                nxt = a + 2
                if nxt in items and items[nxt][1] == 'len' and nxt not in g.labels:
                    g.line(a, 3, '\tsnd_rawnote $%02X, %d' % (v, items[nxt][2]))
                else:
                    g.line(a, 2, '\tsnd_rawnote $%02X' % v)
            elif kind == 'end':
                g.line(a, 1, '\tsnd_end_e0')
            elif name == 'sA_tempodelta_neg':
                g.line(a, n, '\tsnd_unused_e7 $%04X' % (args[0] | args[1] << 8))
            elif name == 'sA_tempodelta':
                g.line(a, n, '\tsnd_unused_e8 $%04X' % (args[0] | args[1] << 8))
            else:
                g.line(a, n, '\t%s%s' % (name.replace('sA_', 'snd_'), (' ' + ', '.join('$%02X' % x for x in args)) if args else ''))
    for a in dead:
        g.line(a, 1, '\tsnd_end\t; unreachable')
    for a, txt in cfg.get('notes', {}).items():
        g.note(a, txt)
    hdr = cfg['header'] + '\nINCLUDE "hardware.inc"\nINCLUDE "bioxA_sound.inc"\n\n' + RAM_EQU
    src = g.render(cfg['section'], hdr)
    open(cfg['out'], 'w').write(src)
    return g, items, unused

# ------------------------------------------------------------------ helpers
def emit_freq(g, s, e):
    a = s
    while a < e:
        n = min(16, (e - a) // 2)
        g.line(a, 2 * n, '\tdw ' + ', '.join('$%04X' % g.rw(a + 2 * i) for i in range(n)))
        a += 2 * n

def emit_waves(g, s, e):
    for a in range(s, e, 16):
        g.line(a, 16, '\tdb ' + ', '.join('$%02X' % g.rb(a + i) for i in range(16)) + '\t; wave $%02X' % ((a - s) // 16))

def emit_vib(g, s, e):
    for a in range(s, e, 4):
        d, c, lo, hi = (g.rb(a + i) for i in range(4))
        g.line(a, 4, '\tdb $%02X, $%02X\n\tdw $%04X\t; vibrato $%02X: delay, half-period, step' % (d, c, lo | hi << 8, (a - s) // 4))
