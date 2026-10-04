#!/usr/bin/env python3
"""Mario vs. Donkey Kong (E) (M5) sound data tool.

usage:
  mvdk_tool.py dump ROM OUT.txt     human-readable decode of every song, instrument, sample, SFX and pattern
  mvdk_tool.py summary ROM OUT.txt  the same without the pattern listings
  mvdk_tool.py wav  ROM OUTDIR      every music sample and SFX as WAV (with loop points)
  mvdk_tool.py xm   ROM OUTDIR      every module converted to a standard FastTracker 2 .xm file

All addresses are for the European ROM (game code "BM5P").
"""
import struct, sys, os, re, wave

# --------------------------------------------------------------------------- ROM access
B = 0x08000000
ROM = b''
def load(path):
    global ROM
    ROM = open(path, 'rb').read()
    if ROM[0xAC:0xB0] != b'BM5P':
        print('warning: game code is %r, expected BM5P' % ROM[0xAC:0xB0])
def u8(a):  return ROM[a - B]
def s8(a):  return struct.unpack_from('<b', ROM, a - B)[0]
def u16(a): return struct.unpack_from('<H', ROM, a - B)[0]
def s16(a): return struct.unpack_from('<h', ROM, a - B)[0]
def u32(a): return struct.unpack_from('<I', ROM, a - B)[0]
def blob(a, n): return ROM[a - B:a - B + n]
def cstr(a, n): return blob(a, n).split(b'\0')[0].decode('latin1')

SONG_COUNT, SONG_TAB = 0x08DDD85C, 0x08DDD860
INS_BANK, INS_SIZE, INS_COUNT = 0x08F035BC, 0x13C, 156
SFX_COUNT, SFX_TAB, SFX_SIZE = 0x08B92E20, 0x08B92E24, 28
OUT_RATE = 16384

# --------------------------------------------------------------------------- parsers
def songs():
    out = []
    for i in range(u16(SONG_COUNT)):
        a = SONG_TAB + 12 * i
        out.append(dict(idx=i, addr=a, module=u32(a), vol=u16(a + 4), map=list(blob(a + 6, 3)), flag=u8(a + 9)))
    return out

def module(a):
    m = dict(addr=a, name=cstr(a, 32), tracker=cstr(a + 0x20, 20), songlen=u16(a + 0x34), restart=u16(a + 0x36),
             nch=u16(a + 0x38), npat=u16(a + 0x3A), nins=u16(a + 0x3C), speed=u16(a + 0x3E), bpm=u16(a + 0x40),
             flags=u16(a + 0x42))
    m['orders'] = list(blob(a + 0x44, 256))
    m['insmap'] = [s16(a + 0x144 + 2 * i) for i in range(128)]
    m['chset'] = [(u8(a + 0x244 + 2 * i), u8(a + 0x245 + 2 * i)) for i in range(32)]
    m['pats'] = [dict(rows=u32(a + 0x284 + 8 * p), off=u32(a + 0x288 + 8 * p)) for p in range(m['npat'])]
    return m

def envelope(a):
    return dict(points=[(u16(a + 4 * i), u16(a + 4 * i + 2)) for i in range(12)], n=u8(a + 0x30), sus=u8(a + 0x31),
                ls=u8(a + 0x33), le=u8(a + 0x34), type=u8(a + 0x35), slope=[s16(a + 0x36 + 2 * i) for i in range(12)])

def sample(a):
    return dict(addr=a, len=u32(a), ls=u32(a + 4), ll=u32(a + 8), vol=u8(a + 0xC), amp=u8(a + 0xD), fine=s8(a + 0xE),
                type=u8(a + 0xF), pan=u8(a + 0x10), rel=s8(a + 0x11), name=cstr(a + 0x12, 22), vtype=u8(a + 0x28),
                vrate=u8(a + 0x29), vdepth=u8(a + 0x2A), vsweep=u8(a + 0x2B), data=u32(a + 0x2C))

def instrument(i):
    a = INS_BANK + INS_SIZE * i
    I = dict(idx=i, addr=a, name=cstr(a, 22), vol=u8(a + 0x16), pan=u8(a + 0x17), nsmp=u16(a + 0x18),
             keymap=list(blob(a + 0x1C, 120)), venv=envelope(a + 0x94), penv=envelope(a + 0xE4),
             fade=u16(a + 0x134), smp=u32(a + 0x138))
    I['samples'] = [sample(I['smp'] + 0x30 * k) for k in range(I['nsmp'])]
    return I

def sfx(i):
    a = SFX_TAB + SFX_SIZE * i
    return dict(idx=i, addr=a, len=u32(a), data=u32(a + 4), rate=u32(a + 8), name=cstr(u32(a + 0xC), 32),
                vol=u16(a + 0x10), prio=u8(a + 0x12), flag=u8(a + 0x13), ls=u32(a + 0x14), le=u32(a + 0x18))

def decode_pattern(m, p):
    """Decode one packed pattern exactly like musReadRow. Returns (rows, end address).
    rows[r] = {channel: cell}; cell fields are None when absent from the cell."""
    a = m['addr'] + m['pats'][p]['off']
    last = [dict(mask=0, note=0, ins=0, vol=0, pan=0, cmd=0, par=0) for _ in range(16)]
    rows = []
    for r in range(m['pats'][p]['rows']):
        row = {}
        while True:
            b = u8(a); a += 1
            if b == 0: break
            ch = (b & 0x3F) - 1
            if ch < 0 or ch > 15: continue
            L = last[ch]
            if b & 0x80: L['mask'] = u8(a); a += 1
            mask = L['mask']
            c = dict(mask=mask, note=None, ins=None, vol=None, pan=None, cmd=None, par=None)
            if mask & 0x02: L['ins'] = u8(a); a += 1; c['ins'] = L['ins']
            elif mask & 0x20: c['ins'] = L['ins']
            if mask & 0x04: L['vol'], L['pan'] = u8(a), u8(a + 1); a += 2; c['vol'], c['pan'] = L['vol'], L['pan']
            elif mask & 0x40: c['vol'], c['pan'] = L['vol'], L['pan']
            if mask & 0x08: L['cmd'], L['par'] = u8(a), u8(a + 1); a += 2; c['cmd'], c['par'] = L['cmd'], L['par']
            elif mask & 0x80: c['cmd'], c['par'] = L['cmd'], L['par']
            if mask & 0x01: L['note'] = u8(a); a += 1; c['note'] = L['note']
            elif mask & 0x10: c['note'] = L['note']
            row[ch] = c
        rows.append(row)
    return rows, a

# --------------------------------------------------------------------------- text helpers
NOTES = ['C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-']
def notename(n):
    """Driver note byte: 1..120 notes (13 = C-0, i.e. XM note = n - 12), 121 key off, >121 cut."""
    if n is None: return '...'
    if n == 121: return '==='
    if n > 121: return '^^^'
    x = n - 13
    return '%s%d' % (NOTES[x % 12], x // 12) if x >= 0 else 'n%02X' % n
FXNAME = {0: 'arpeggio', 1: 'porta up', 2: 'porta down', 3: 'tone porta', 4: 'vibrato', 5: 'tone porta+vol slide',
          6: 'vibrato+vol slide', 7: 'tremolo', 8: 'set pan', 9: 'sample offset', 0xA: 'volume slide',
          0xB: 'position jump', 0xC: 'set volume', 0xD: 'pattern break', 0xF: 'speed/tempo', 0x17: 'X1x extra fine porta up',
          0x18: 'X2x extra fine porta down', 0x1A: 'E1x', 0x1B: 'E2x', 0x1D: 'E4x', 0x20: 'E7x', 0x21: 'E8x',
          0x22: 'E9x retrig', 0x23: 'EAx', 0x24: 'EBx', 0x25: 'ECx note cut', 0x26: 'EDx note delay'}
def fxtext(c):
    if c['cmd'] is None: return '...'
    return '%s%02X' % ('%X' % c['cmd'] if c['cmd'] < 16 else 'x%02X' % c['cmd'], c['par'])
def cell(c):
    if c is None: return '... .. .. .. ...'
    return '%s %s %s %s %s' % (notename(c['note']), '%02X' % c['ins'] if c['ins'] is not None else '..',
                                 '%02X' % c['vol'] if c['vol'] is not None else '..',
                                 ('%02X' % c['pan'] if c['pan'] < 0x80 else '--') if c['pan'] is not None else '..',
                                 fxtext(c))
def c4_rate(s):
    return 8363 * 2 ** ((s['rel'] + s['fine'] / 128) / 12)

# --------------------------------------------------------------------------- dump
def dump(path, patterns=True):
    S = songs(); ins = [instrument(i) for i in range(INS_COUNT)]
    o = open(path, 'w')
    w = lambda *a: o.write(' '.join(str(x) for x in a) + '\n')
    w('Mario vs. Donkey Kong (E) (M5) - sound data decode (mvdk_tool.py)')
    w('=' * 100)
    w('\nSONG TABLE 0x%08X, %d songs' % (SONG_TAB, len(S)))
    w('  #  name                 module     vol  voices(sfx0..2) flag  ch pat ord ins  speed/BPM')
    mods = {}
    for s in S:
        m = module(s['module']); mods[s['module']] = m
        vm = ','.join(str(x) if x else '-' for x in s['map'])
        w('%3d  %-20s 0x%08X %3d  %-15s %d    %2d %3d %3d %3d  %d/%d' % (s['idx'], m['name'], s['module'], s['vol'], vm,
          s['flag'], m['nch'], m['npat'], m['songlen'], m['nins'], m['speed'], m['bpm']))
    w('  voices: mixing voice (1-8) each SFX voice takes while it plays; "-" = default (8, 7, 6)')

    w('\n' + '=' * 100 + '\nINSTRUMENTS 0x%08X, %d' % (INS_BANK, INS_COUNT))
    users = {}
    for s in S:
        m = mods[s['module']]
        for k in range(m['nins']): users.setdefault(m['insmap'][k], []).append('%s:%02X' % (m['name'][:-2], k + 1))
    for I in ins:
        w('\nins %3d  0x%08X  "%s"  vol %d  pan %s  fadeout %d  samples %d' % (I['idx'], I['addr'], I['name'].rstrip(),
          I['vol'], ('override %d' % (I['pan'] & 0x7F)) if I['pan'] & 0x80 else '-', I['fade'], I['nsmp']))
        w('    used by: ' + ' '.join(users.get(I['idx'], ['(none)'])))
        # keymap as ranges
        km = I['keymap']; rng = []; st = 0
        for n in range(1, 121):
            if n == 120 or km[n] != km[st]:
                rng.append('%s-%s:%d' % (notename(st + 1), notename(n), km[st])); st = n
        w('    keymap: ' + ' '.join(rng))
        for nm, e in (('vol', I['venv']), ('pan', I['penv'])):
            if e['type'] & 1:
                t = '+'.join(x for b, x in ((1, 'on'), (2, 'sus'), (4, 'loop')) if e['type'] & b)
                w('    %s env (%s): %s  sus %d loop %d-%d' % (nm, t, ' '.join('%d:%d' % p for p in e['points'][:e['n']]),
                  e['sus'], e['ls'], e['le']))
        for k, s in enumerate(I['samples']):
            lt = {0: 'one-shot', 1: 'loop', 2: 'ping-pong'}.get(s['type'], '?%d' % s['type'])
            w('    smp %d 0x%08X "%s" len %d loop %d+%d %s vol %d amp %d fine %d rel %d pan %s C-4=%.0f Hz%s' % (
                k, s['addr'], s['name'].rstrip(), s['len'] >> 8, s['ls'] >> 8, s['ll'] >> 8, lt, s['vol'], s['amp'],
                s['fine'], s['rel'], ('%d' % s['pan']) if s['pan'] < 0x80 else '-', c4_rate(s),
                '' if s['vtype'] > 2 else '  autovib type %d rate %d depth %d sweep %d' % (s['vtype'], s['vrate'], s['vdepth'], s['vsweep'])))

    w('\n' + '=' * 100 + '\nSFX TABLE 0x%08X, %d entries (rate in Hz, vol x/128, prio 0-15)' % (SFX_TAB, u32(SFX_COUNT)))
    for i in range(u32(SFX_COUNT)):
        x = sfx(i)
        if x['len'] == 1:
            w('%3d  %-14s  (1 byte: plays as "stop looping SFX of priority %d")  flag %d' % (i, x['name'], x['prio'], x['flag']))
        else:
            w('%3d  %-14s 0x%08X %6d bytes %5d Hz %.3f s vol %3d prio %2d flag %d%s' % (i, x['name'], x['data'], x['len'],
              x['rate'], x['len'] / x['rate'], x['vol'], x['prio'], x['flag'],
              '  loop %d-%d' % (x['ls'], x['le']) if (x['ls'] or x['le'] != x['len']) else ''))

    w('\n' + '=' * 100 + '\nMODULES (pattern cells: note instrument volcol pancol effect; pancol "--" = none)')
    for ma in sorted(mods):
        m = mods[ma]
        w('\n' + '-' * 100)
        w('%s  0x%08X  %d channels, %d patterns, %d instruments, speed %d, %d BPM, restart %d' % (m['name'], ma,
          m['nch'], m['npat'], m['nins'], m['speed'], m['bpm'], m['restart']))
        w('orders: ' + ' '.join('%d' % x for x in m['orders'][:m['songlen']]))
        w('instruments: ' + ' '.join('%02X=%d(%s)' % (k + 1, m['insmap'][k], ins[m['insmap'][k]]['name'].strip())
                                    for k in range(m['nins'])))
        for p in range(m['npat'] if patterns else 0):
            rows, _ = decode_pattern(m, p)
            w('\n  pattern %d (%d rows) at 0x%08X' % (p, m['pats'][p]['rows'], ma + m['pats'][p]['off']))
            for r, row in enumerate(rows):
                w('  %02X | ' % r + ' | '.join(cell(row.get(ch)) for ch in range(m['nch'])))
    o.close()

# --------------------------------------------------------------------------- wav
def write_wav(path, pcm8, rate, loop=None):
    data = bytes((b + 128) & 0xFF for b in pcm8)   # signed -> unsigned
    chunks = b'fmt ' + struct.pack('<IHHIIHH', 16, 1, 1, rate, rate, 1, 8) + b'data' + struct.pack('<I', len(data)) + data
    if len(data) & 1: chunks += b'\0'
    if loop:
        smpl = struct.pack('<9I', 0, 0, int(1e9 / rate), 60, 0, 0, 0, 1, 0) + struct.pack('<6I', 0, 0, loop[0], loop[1] - 1, 0, 0)
        chunks += b'smpl' + struct.pack('<I', len(smpl)) + smpl
    open(path, 'wb').write(b'RIFF' + struct.pack('<I', 4 + len(chunks)) + b'WAVE' + chunks)

def safe(s): return re.sub(r'[^A-Za-z0-9_.-]+', '_', s.strip()) or 'noname'

def wavs(outdir):
    os.makedirs(os.path.join(outdir, 'music'), exist_ok=True); os.makedirs(os.path.join(outdir, 'sfx'), exist_ok=True)
    seen = set(); n = 0
    for I in (instrument(i) for i in range(INS_COUNT)):
        for k, s in enumerate(I['samples']):
            L = s['len'] >> 8
            key = (s['data'], L, s['ls'], s['ll'])
            if L <= 1 or key in seen: continue
            seen.add(key)
            pcm = struct.unpack('%db' % L, blob(s['data'], L))
            loop = ((s['ls'] >> 8), (s['ls'] + s['ll']) >> 8) if s['type'] else None
            write_wav(os.path.join(outdir, 'music', 'ins%03d_%d_%s.wav' % (I['idx'], k, safe(s['name']))), pcm,
                      int(round(c4_rate(s))), loop)
            n += 1
    m = 0
    for i in range(u32(SFX_COUNT)):
        x = sfx(i)
        if x['len'] <= 1: continue
        pcm = struct.unpack('%db' % x['len'], blob(x['data'], x['len']))
        loop = (x['ls'], x['le']) if (x['ls'] or x['le'] != x['len']) else None
        write_wav(os.path.join(outdir, 'sfx', 'sfx%03d_%s.wav' % (i, safe(x['name']))), pcm, x['rate'], loop)
        m += 1
    print('%d music samples (C-4 rate), %d SFX written' % (n, m))

# --------------------------------------------------------------------------- xm
def xm_module(s, report):
    """Convert one song to a FastTracker 2 XM. Returns bytes."""
    m = module(s['module'])
    nch = m['nch'] + (m['nch'] & 1)                      # FT2 wants an even channel count
    ins = [instrument(m['insmap'][k]) for k in range(m['nins'])]
    out = bytearray()
    out += b'Extended Module: ' + m['name'][:20].ljust(20).encode('latin1') + b'\x1a'
    out += b'MvDK driver->XM'.ljust(20) + struct.pack('<H', 0x0104)
    out += struct.pack('<IHHHHHHHH', 276, m['songlen'], m['restart'], nch, m['npat'], m['nins'], 1, m['speed'], m['bpm'])
    out += bytes(m['orders'])
    dropped = keyoffs = 0
    cur = [0] * 16                                      # instrument last used on each channel
    for p in range(m['npat']):
        rows, _ = decode_pattern(m, p)
        pd = bytearray()
        for row in rows:
            for ch in range(nch):
                c = row.get(ch)
                note = insn = vol = fx = par = 0
                if c:
                    if c['ins'] is not None: cur[ch] = c['ins']
                    if c['note'] == 121 and cur[ch] and not (ins[cur[ch] - 1]['venv']['type'] & 1):
                        keyoffs += 1          # FT2 cuts such notes at key-off; the driver only starts the
                        c = dict(c, note=None)  # fadeout (which advances only on rows with cells): drop it
                    if c['note'] is not None:
                        note = 97 if c['note'] == 121 else (0 if c['note'] > 121 else max(1, min(96, c['note'] - 12)))
                        if c['note'] > 121: fx, par = 0xE, 0xC0            # note cut -> EC0
                    if c['ins'] is not None: insn = c['ins']
                    if c['vol'] is not None: vol = c['vol']
                    cmd = c['cmd']
                    if cmd is not None and (cmd or c['par']):
                        if cmd <= 0xF: fx, par = cmd, c['par']
                        elif cmd in (0x17, 0x18): fx, par = 33, (0x10 if cmd == 0x17 else 0x20) | (c['par'] & 15)
                        elif 0x19 <= cmd <= 0x27: fx, par = 0xE, (cmd - 0x19) << 4 | (c['par'] & 15)
                        else: fx, par = cmd, c['par']                      # 0x10-0x16: meaning unknown
                    if c['pan'] is not None and c['pan'] < 0x80:
                        pv = min(255, c['pan'] * 4)
                        if fx == 0 and par == 0: fx, par = 8, pv
                        elif vol == 0: vol = 0xC0 | (pv >> 4)
                        else: dropped += 1
                bits = (1 if note else 0) | (2 if insn else 0) | (4 if vol else 0) | (8 if fx else 0) | (16 if par else 0)
                pd.append(0x80 | bits)
                for flag, v in ((1, note), (2, insn), (4, vol), (8, fx), (16, par)):
                    if bits & flag: pd.append(v)
        out += struct.pack('<IBHH', 9, 0, m['pats'][p]['rows'], len(pd)) + pd
    for I in ins:
        smps = I['samples']
        hdr = bytearray(I['name'][:22].ljust(22).encode('latin1')) + b'\0' + struct.pack('<H', len(smps))
        if smps:
            hdr += struct.pack('<I', 40)
            hdr += bytes(I['keymap'][n + 11] for n in range(96))    # XM note n+1 = driver note n+13
            for e in (I['venv'], I['penv']):
                hdr += b''.join(struct.pack('<HH', x, y) for x, y in e['points'])
            v, pn = I['venv'], I['penv']
            s0 = smps[0]
            vt = s0['vtype'] if s0['vtype'] <= 2 else 0
            hdr += bytes([v['n'], pn['n'], v['sus'], v['ls'], v['le'], pn['sus'], pn['ls'], pn['le'], v['type'], pn['type'],
                          vt, s0['vsweep'] if s0['vtype'] <= 2 else 0, s0['vdepth'] if s0['vtype'] <= 2 else 0,
                          s0['vrate'] if s0['vtype'] <= 2 else 0])
            hdr += struct.pack('<HH', I['fade'], 0) + bytes(20)
        out += struct.pack('<I', 4 + len(hdr)) + hdr
        datas = []
        for sm in smps:
            L = sm['len'] >> 8
            pcm = struct.unpack('%db' % L, blob(sm['data'], L)) if L else ()
            pcm = [max(-128, min(127, round(x * sm['amp'] / 64))) for x in pcm]   # bake in the amplitude scale
            pan = sm['pan'] if sm['pan'] < 0x80 else 32
            if I['pan'] & 0x80: pan = I['pan'] & 0x7F
            lt = sm['type'] if sm['type'] <= 2 else 0
            out += struct.pack('<IIIBbBBbB', L, sm['ls'] >> 8 if lt else 0, sm['ll'] >> 8 if lt else 0, sm['vol'],
                               sm['fine'], lt, min(255, pan * 4), sm['rel'], 0)
            out += sm['name'][:22].ljust(22).encode('latin1')
            prev = 0; d = bytearray()
            for x in pcm: d.append((x - prev) & 0xFF); prev = x
            datas.append(bytes(d))
        for d in datas: out += d
    if keyoffs: report.append('%s: %d key-offs on instruments without a volume envelope removed' % (m['name'], keyoffs))
    if dropped: report.append('%s: %d pan-column values dropped (cell had both an effect and a volume)' % (m['name'], dropped))
    return bytes(out)

def xms(outdir):
    os.makedirs(outdir, exist_ok=True); report = []
    for s in songs():
        m = module(s['module'])
        name = '%02d_%s.xm' % (s['idx'], safe(re.sub(r'XM$', '', m['name'])))
        open(os.path.join(outdir, name), 'wb').write(xm_module(s, report))
    print('%d modules written' % len(songs()))
    for r in report: print(' ', r)

if __name__ == '__main__':
    if len(sys.argv) != 4 or sys.argv[1] not in ('dump', 'summary', 'wav', 'xm'):
        print(__doc__); sys.exit(1)
    load(sys.argv[2])
    {'dump': dump, 'summary': lambda p: dump(p, False), 'wav': wavs, 'xm': xms}[sys.argv[1]](sys.argv[3])
