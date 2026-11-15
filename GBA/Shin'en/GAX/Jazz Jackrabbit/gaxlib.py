#!/usr/bin/env python3
"""Engine-faithful GAX (Shin'en) data parser, v1.99 - v3.x. Research tool."""
import struct, re, sys
ROM_BASE = 0x08000000

class Rom:
    def __init__(self, path):
        self.d = open(path, 'rb').read()
        self.n = len(self.d)
        m = re.search(rb"GAX Sound Engine [Vv]?([0-9]+)\.([0-9]+)([A-Za-z]?)\s*\(([^)]*)\)", self.d)
        self.version = None
        if m:
            self.version = (int(m.group(1)), int(m.group(2)), m.group(3).decode(), m.group(4).decode())
            self.verstr = m.group(0).decode('latin1')
    def u8(self, o): return self.d[o]
    def s8(self, o): return struct.unpack_from('<b', self.d, o)[0]
    def u16(self, o): return struct.unpack_from('<H', self.d, o)[0]
    def s16(self, o): return struct.unpack_from('<h', self.d, o)[0]
    def u32(self, o): return struct.unpack_from('<I', self.d, o)[0]
    def s32(self, o): return struct.unpack_from('<i', self.d, o)[0]
    def isptr(self, v): return ROM_BASE <= v < ROM_BASE + self.n
    def off(self, v): return v - ROM_BASE

# ---------------- pattern decoding (identical in 2.01D and 3.05A code) -------------
def decode_pattern(rom, o, nrows):
    """Returns (rows, end_offset, empty). Each row: dict or None. Reads exactly
    as GaxChannelDecodeRow / GAXTracker_process_step do."""
    empty = rom.u8(o)
    p = o + 1
    rows = []
    if empty:
        return [None] * nrows, p, True
    skip = 0
    for r in range(nrows):
        if skip:
            skip -= 1; rows.append(None); continue
        b = rom.u8(p)
        if b == 0xFF:
            n = rom.u8(p + 1)
            skip = (n - 1) & 0xFF
            p += 2; rows.append(None); continue
        if b & 0x80:
            k = b & 0x7F
            if k == 0:
                p += 1; rows.append(None); continue
            if k <= 121:
                rows.append(dict(note=k, ins=rom.u8(p + 1), fx=0, prm=0, raw=rom.d[p:p+2])); p += 2
            else:
                rows.append(dict(note=0, ins=0, fx=rom.u8(p + 1), prm=rom.u8(p + 2), raw=rom.d[p:p+3])); p += 3
        else:
            rows.append(dict(note=b, ins=rom.u8(p + 1), fx=rom.u8(p + 2), prm=rom.u8(p + 3), raw=rom.d[p:p+4])); p += 4
    return rows, p, False

NOTE_NAMES = ['C-','C#','D-','D#','E-','F-','F#','G-','G#','A-','A#','B-']
def note_name(n):
    if n == 0: return '...'
    if n == 1: return '==='
    v = n - 2
    return f"{NOTE_NAMES[v%12]}{v//12}"

# ---------------- song header (SongInfo / GAXSongData) ------------------
def songinfo_layout(ver):
    major, minor, sub = ver[0], ver[1], ver[2].lower()
    has_vol = major >= 2 or (major == 1 and minor == 99 and sub >= 'f')
    return has_vol

def parse_songinfo(rom, o, ver):
    has_vol = songinfo_layout(ver)
    si = dict(at=o)
    si['nch'], si['rows'], si['npat'], si['loop'] = struct.unpack_from('<4H', rom.d, o)
    q = o + 8
    if has_vol:
        si['vol'], si['u0a'] = struct.unpack_from('<2H', rom.d, q); q += 4
    si['seq'], si['ins'], si['smp'] = struct.unpack_from('<3I', rom.d, q); q += 12
    if ver[0] >= 2:
        si['rate'] = rom.u16(q); q += 2
        if ver[0] >= 3:
            si['fxrate'] = rom.u16(q); q += 2
        si['fxch'] = rom.u8(q); si['b1d'] = rom.u8(q + 1); q += 2
        if ver[0] >= 3:
            si['u1e'] = rom.u16(q); q += 2
    si['size'] = q - o
    return si

def plausible_songinfo(rom, o, ver, allow_zero_ch=False):
    if o + 0x20 > rom.n: return None
    try:
        si = parse_songinfo(rom, o, ver)
    except struct.error:
        return None
    if not (1 <= si['nch'] <= 32) and not (allow_zero_ch and si['nch'] == 0): return None
    if si['nch'] and not (1 <= si['rows'] <= 0x1FF): return None
    if si['nch'] and not (1 <= si['npat'] <= 0xFF): return None
    if si['nch'] and si['loop'] >= si['npat']: return None
    if si['nch'] and not rom.isptr(si['seq']): return None
    if not rom.isptr(si['ins']) or not rom.isptr(si['smp']): return None
    return si

# ---------------- GAX3 song (SongInfo + 32 channel ptrs + DSP block) ------------
def find_gax3_songs(rom):
    ver = rom.version
    out = []
    for o in range(0, rom.n - 0xC8, 4):
        nch = rom.u16(o)
        if not 1 <= nch <= 32: continue
        si = plausible_songinfo(rom, o, ver)
        if not si: continue
        chp = struct.unpack_from('<32I', rom.d, o + 0x20)
        if not all(rom.isptr(p) for p in chp[:nch]): continue
        if any(chp[nch:]): continue
        if si['rate'] and si['rate'] > 50000: continue
        si['chans'] = [rom.off(p) for p in chp[:nch]]
        si['dsp'] = struct.unpack_from('<10I', rom.d, o + 0xA0)
        out.append(si)
    return out

def read_orders(rom, o, npat):
    return [(rom.u16(o + 4*i), rom.s8(o + 4*i + 2), rom.u8(o + 4*i + 3)) for i in range(npat)]

# ---------------- GAX2 song (handler graph) ------------------
def parse_handler(rom, o):
    f = struct.unpack_from('<7I', rom.d, o)
    return dict(at=o, init=f[0], unk=f[1], play=f[2], nchild=f[3], children=f[4], isize=f[5], data=f[6])

def find_gax2_songs(rom):
    ver = rom.version
    out = []
    for o in range(0, rom.n - 0x40, 4):
        n = rom.u32(o)
        if not 4 <= n <= 35: continue
        ptrs = struct.unpack_from(f'<{n}I', rom.d, o + 4)
        if not (rom.isptr(ptrs[0]) and rom.isptr(ptrs[1])): continue
        if not all(rom.isptr(p) for p in ptrs[3:]): continue
        try:
            mix = parse_handler(rom, rom.off(ptrs[0])); info = parse_handler(rom, rom.off(ptrs[1]))
        except struct.error: continue
        if not all(rom.isptr(x) for x in (mix['init'], mix['play'], info['init'], info['play'], info['data'])): continue
        si = plausible_songinfo(rom, rom.off(info['data']), ver)
        if not si: continue
        if mix['nchild'] != si['nch'] or not rom.isptr(mix['children']): continue
        kids = struct.unpack_from(f"<{mix['nchild']}I", rom.d, rom.off(mix['children']))
        chans = []
        ok = True
        for k in kids:
            if not rom.isptr(k): ok = False; break
            h = parse_handler(rom, rom.off(k))
            if not rom.isptr(h['data']): ok = False; break
            chans.append(rom.off(h['data']))
        if not ok: continue
        si['chans'] = chans
        si['song_at'] = o
        si['nitems'] = n
        si['mixer'] = mix
        out.append(si)
    return out

def find_songs(rom):
    return find_gax3_songs(rom) if rom.version[0] >= 3 else find_gax2_songs(rom)

def song_patterns(rom, si):
    """decode every channel's every order entry; return list per channel of (order, pattern) and max end."""
    seq = rom.off(si['seq'])
    chans = []
    maxend = 0
    for c in si['chans']:
        orders = read_orders(rom, c, si['npat'])
        pats = []
        for (po, tr, r) in orders:
            rows, end, empty = decode_pattern(rom, seq + po, si['rows'])
            pats.append((po, tr, rows, end, empty))
            maxend = max(maxend, end)
        chans.append((orders, pats))
    return chans, maxend

def read_title(rom, o):
    e = o
    while e < rom.n and rom.d[e] != 0 and e - o < 200: e += 1
    return rom.d[o:e].decode('latin1')

# ---------------- instruments ------------------
def inst_layout(ver):
    """'v2' = 4 inline 28-byte wave params at +0x0C (GAX 1.99d-3.0);
       'v3' = header 0x18 + 24-byte wave params at +0x18 (GAX 3.01+)."""
    if ver[0] < 3: return 'v2'
    if ver[0] == 3 and ver[1] == 0: return 'v2'
    return 'v3'

def parse_envelope(rom, o):
    cnt, sus, ls, le = rom.d[o:o+4]
    pts = []
    for i in range(cnt):
        q = o + 4 + 8*i   # 8-byte points: u16 tick, s16 Q8 slope from previous point, u8 volume, 3 pad
        pts.append((rom.u16(q), rom.s16(q+2), rom.u8(q+4)))
    return dict(at=o, count=cnt, sustain=sus, loopStart=ls, loopEnd=le, points=pts)

def parse_seq(rom, o, n):
    out = []
    for i in range(n):
        q = o + 8*i
        out.append(dict(note=rom.u8(q), fixed=rom.u8(q+1), wave=rom.u8(q+2), pad=rom.u8(q+3),
                        fx=[(rom.u8(q+5), rom.u8(q+4)), (rom.u8(q+7), rom.u8(q+6))]))
    return out

def parse_wave_v2(rom, q):
    return dict(mod=rom.u8(q), pingpong=rom.u8(q+1), pad=rom.u16(q+2), start=rom.s32(q+4), min=rom.s32(q+8),
                max=rom.s32(q+12), modsize=rom.s32(q+16), modstep=rom.s32(q+20), modspeed=rom.u16(q+24), tune=rom.s16(q+26))
def parse_wave_v3(rom, q):
    return dict(tune=rom.s16(q), mod=rom.u8(q+2), pingpong=rom.u8(q+3), start=rom.s32(q+4), min=rom.s32(q+8),
                max=rom.s32(q+12), modsize=rom.s32(q+16), modstep=rom.u16(q+20), modspeed=rom.u16(q+22))

def parse_instrument(rom, o, ver):
    lay = inst_layout(ver)
    ins = dict(at=o, layout=lay, blank=rom.u8(o), waves=list(rom.d[o+1:o+5]), pad5=rom.d[o+5:o+8],
               vib_delay=rom.u8(o+8), vib_depth=rom.u8(o+9), vib_speed=rom.u8(o+10), pad0b=rom.u8(o+11))
    if lay == 'v2':
        ins['wp'] = [parse_wave_v2(rom, o + 0x0C + 28*i) for i in range(4)]
        h = o + 0x7C
        ins['env'] = rom.u32(h); ins['unkptr'] = rom.u32(h+4)
        ins['seq_speed'] = rom.u8(h+8); ins['seq_len'] = rom.u8(h+9); ins['u12'] = rom.u16(h+10)
        ins['seq'] = rom.u32(h+12)
        ins['size'] = 0x8C
    else:
        ins['env'] = rom.u32(o+0x0C)
        ins['seq_speed'] = rom.u8(o+0x10); ins['seq_len'] = rom.u8(o+0x11); ins['u12'] = rom.u16(o+0x12)
        ins['seq'] = rom.u32(o+0x14)
        ins['seqlist'] = parse_seq(rom, rom.off(ins['seq']), ins['seq_len']) if rom.isptr(ins['seq']) else []
        nw = max([e['wave'] for e in ins['seqlist']] + [1])
        ins['wp'] = [parse_wave_v3(rom, o + 0x18 + 24*i) for i in range(nw)]
        ins['size'] = 0x18 + 24*nw
    if 'seqlist' not in ins:
        ins['seqlist'] = parse_seq(rom, rom.off(ins['seq']), ins['seq_len']) if rom.isptr(ins['seq']) else []
    ins['envd'] = parse_envelope(rom, rom.off(ins['env'])) if rom.isptr(ins['env']) else None
    return ins

def used_instruments(rom, si):
    chans, _ = song_patterns(rom, si)
    used = set()
    for orders, pats in chans:
        for (po,tr,rows,end,empty) in pats:
            for row in rows:
                if row and row['ins']: used.add(row['ins'])
    return sorted(used)
