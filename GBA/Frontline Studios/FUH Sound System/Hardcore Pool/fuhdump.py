#!/usr/bin/env python3
"""FUH Sound System (Frontline Studios) data dumper.

Usage: fuhdump.py ROM.gba OUTDIR TAG
Finds every FUH module in the ROM, writes OUTDIR/TAG_data_dump.txt, OUTDIR/TAG_patterns/*.txt and
OUTDIR/TAG_wav/*.wav.  Module format (all little-endian u32 unless stated):

  module  +00 nch  +04 norders  +08 (unread, 50/59)  +0C speed  +10 ins_table  +14 order_table
  order_table[norders] -> pattern header {u32 rows, u32 data}
  ins_table[n]  -> instrument {u32 loop_start, u32 loop_end (0 = one-shot), u32 volume, u32 pcm_hdr}
  pcm_hdr       -> {u32 length, u32 data}   8-bit signed PCM
  pattern data: rows x nch events; event = u8 flags
      flags&01  -> u16 note (XM linear period, 0..7679), u8 instrument (0 = previous)
      flags&80  -> u8 volume (0..64)
      flags&7E  -> u8 parameter; effect number = (flags>>2)&31
"""
import os, sys, struct, wave, collections

B = 0x8000000
STEP_RATE = 18157           # mix rate the step table is built for

EFFECT_NAMES = {
    1: 'store param only (no effect; data looks like XM 8xx panning)',
    2: 'portamento up (period -= p*4 per tick)',
    3: 'portamento down (period += p*4 per tick)',
    4: 'tone portamento (p*4 per tick toward the note)',
    5: 'set channel volume',
    6: 'volume slide (x up, y down, per tick)',
    7: 'vibrato (speed x, depth y)',
    8: 'vibrato (same handler as 7)',
    9: 'set speed (ticks per row)',
    10: 'no effect', 11: 'no effect',
    12: 'vibrato (memory) + volume slide',
    13: 'no effect',
    14: 'position jump (order p, row 0)',
    15: 'sample offset (p*256; memory shared with instrument number)',
}
for i in range(16, 31):
    EFFECT_NAMES[i] = 'no effect'
EFFECT_NAMES[31] = 'jumps to address 0 (crash)'


class Rom:
    def __init__(self, path):
        self.d = open(path, 'rb').read()

    def ok(self, a):
        return B <= a < B + len(self.d)

    def u32(self, a):
        return struct.unpack_from('<I', self.d, a - B)[0]

    def u8(self, a):
        return self.d[a - B]


def find_modules(r):
    out = []
    d = r.d
    for off in range(0, len(d) - 24, 4):
        nch, nord, x8, spd, ins, ords = struct.unpack_from('<6I', d, off)
        if not (1 <= nch <= 32 and nord <= 256 and 1 <= spd <= 31):
            continue
        if not (r.ok(ins) and r.ok(ords)) or ins % 4 or ords % 4:
            continue
        good = True
        for i in range(nord):
            p = r.u32(ords + 4 * i)
            if not r.ok(p) or p % 4:
                good = False
                break
            rows, dp = struct.unpack_from('<2I', d, p - B)
            if not (rows <= 256 and r.ok(dp)):
                good = False
                break
        if not good:
            continue
        p = r.u32(ins + 4)
        if not r.ok(p):
            continue
        ls, le, vol, ph = struct.unpack_from('<4I', d, p - B)
        if vol > 64 or not r.ok(ph):
            continue
        out.append(B + off)
    return out


def decode_pattern(r, dp, rows, nch):
    a = dp
    out = []
    for _ in range(max(rows, 1)):          # a 0-row pattern still plays one row
        cells = []
        for _c in range(nch):
            f = r.u8(a); a += 1
            ev = {'f': f}
            if f & 1:
                ev['note'] = r.u8(a) | r.u8(a + 1) << 8; a += 2
                ev['ins'] = r.u8(a); a += 1
                ev['tp'] = (f & 0xFE) == 0x10
            if f & 0x80:
                ev['vol'] = r.u8(a); a += 1
            if f & 0x7E:
                ev['fx'] = (f >> 2) & 31
                ev['bit1'] = bool(f & 2)
                ev['par'] = r.u8(a); a += 1
            cells.append(ev)
        out.append(cells)
    return out, a


def parse_instruments(r, table):
    res = []
    i = 0
    while True:
        p = r.u32(table + 4 * i)
        if p == 0:
            if i == 0:
                i += 1
                continue
            break
        if not r.ok(p):
            break
        ls, le, vol, ph = (r.u32(p + 4 * k) for k in range(4))
        if vol > 255 or not r.ok(ph):
            break
        ln, dat = r.u32(ph), r.u32(ph + 4)
        res.append(dict(n=i, addr=p, ls=ls, le=le, vol=vol, hdr=ph, len=ln, data=dat))
        i += 1
        if i > 512:
            break
    return res


def parse_module(r, a):
    nch, nord, x8, spd, ins, ords = (r.u32(a + 4 * i) for i in range(6))
    m = dict(addr=a, nch=nch, nord=nord, x8=x8, speed=spd, ins=ins, ords=ords)
    m['order'] = [r.u32(ords + 4 * i) for i in range(nord)]
    m['pat'] = {}
    for idx, p in enumerate(sorted(set(m['order']))):
        rows, dp = r.u32(p), r.u32(p + 4)
        data, end = decode_pattern(r, dp, rows, nch)
        m['pat'][p] = dict(idx=idx, hdr=p, rows=rows, data_addr=dp, end=end, data=data)
        if rows == 0:
            # a 256-row pattern whose count wrapped to 0: the engine plays only row 0
            full, fend = decode_pattern(r, dp, 256, nch)
            m['pat'][p].update(full=full, end=fend)
    m['instruments'] = parse_instruments(r, ins)
    return m


def note_name(period):
    # XM linear: period = 7680 - note*64 ; XM note 0 = C-0 ; 4608 = C-4? (period 4608 -> 8363 Hz)
    n = (7680 - period) / 64.0
    ni = int(round(n))
    names = ['C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-']
    s = names[ni % 12] + str(ni // 12)
    fine = period - (7680 - ni * 64)
    if fine:
        s += '(%+d)' % (-fine)
    return s


def step_hz(period):
    return 8363 * 2 ** ((4608 - period) / 768.0)


def cell_str(ev):
    s = ''
    if 'note' in ev:
        s += '%-7s %02X' % (note_name(ev['note']), ev['ins'])
        s += '*' if ev['tp'] else ' '
    else:
        s += '...        '
    s += ' v%02d' % ev['vol'] if 'vol' in ev else ' ...'
    s += ' %02d:%02X' % (ev['fx'], ev['par']) if 'fx' in ev else ' .....'
    return s


def walk_song(m, entry, maxrows=200000):
    """Follow the order list from `entry` like the player does; yield (order, row, cells).
    Stops when an (order,row) is revisited."""
    seen = set()
    order, row = entry, 0
    n = 0
    while n < maxrows:
        if (order, row) in seen:
            return
        seen.add((order, row))
        pat = m['pat'][m['order'][order]]
        cells = pat['data'][row]
        yield order, row, cells
        jump = None
        for ev in cells:
            if ev.get('fx') == 14:
                jump = ev['par']
        n += 1
        if jump is not None:
            order, row = jump, 0
            if order >= m['nord']:
                return
            continue
        row += 1
        if row >= pat['rows']:
            row = 0
            order += 1
            if order >= m['nord']:
                order = 0


def bug_stats(m, entries):
    """Count events whose meaning differs because of shared memory fields."""
    st = collections.Counter()
    visited = set()
    for e in entries:
        ch_ins = [None] * m['nch']        # engine: +38 field
        ch_ins_ok = [None] * m['nch']     # intended: last instrument
        ch_off_ok = [0] * m['nch']        # intended: last offset
        mem = [None] * m['nch']           # +24 field: (writer fx, value)
        for order, row, cells in walk_song(m, e):
            key = (order, row)
            first = key not in visited
            visited.add(key)
            for c, ev in enumerate(cells):
                if 'note' in ev and not ev['tp']:
                    i = ev['ins']
                    if i:
                        ch_ins[c] = i; ch_ins_ok[c] = i
                    else:
                        if ch_ins[c] is None and first:
                            st['note with instrument 0 before any instrument (reads table entry 0 = NULL)'] += 1
                        elif ch_ins[c] != ch_ins_ok[c] and first:
                            st['note with instrument 0 that plays a different instrument (9xx overwrote it)'] += 1
                if 'note' in ev and ev['tp'] is False and ev.get('fx') == 4 and first:
                    st['tone-porta note that retriggers because a volume byte is present'] += 1
                fx = ev.get('fx'); p = ev.get('par')
                if fx == 15:
                    if p:
                        ch_ins[c] = p; ch_off_ok[c] = p
                    else:
                        if first and ch_ins[c] != ch_off_ok[c]:
                            st['15:00 (offset with memory) that uses the instrument number as the offset'] += 1
                if fx in (2, 3, 4, 7, 8) and p == 0 and first:
                    w = mem[c]
                    if w is not None and w[0] != fx and not (fx in (7, 8) and w[0] in (7, 8)):
                        st['effect %d with parameter 0 that reuses a parameter left by effect %d' % (fx, w[0])] += 1
                if fx in (1, 6, 12) or (fx in (2, 3, 4, 7, 8) and p):
                    mem[c] = (fx, p)
                if fx == 6 and p == 0 and first:
                    st['effect 6 with parameter 0 (XM would repeat the last slide; FUH slides nothing)'] += 1
                if fx == 12 and p == 0 and first:
                    st['effect 12 with parameter 0 (vibrato continues, volume slide does nothing)'] += 1
                if fx == 16 and first:
                    st['effect 16 (no handler) reached during playback'] += 1
    return st


def write_wav(path, pcm, rate):
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(1); w.setframerate(rate)
        w.writeframes(bytes((b + 128) & 0xFF for b in pcm))


def dump(rom_path, outdir, tag, entries_by_module=None, title=''):
    r = Rom(rom_path)
    mods = find_modules(r)
    os.makedirs(outdir, exist_ok=True)
    L = []
    P = L.append
    P('%s -- FUH Sound System data, %s' % (tag, title))
    P('modules found: ' + ', '.join('%08X' % a for a in mods))
    P('')
    allfx = collections.Counter()
    for mi, a in enumerate(mods):
        m = parse_module(r, a)
        ins = m['instruments']
        P('=' * 100)
        P('module %d @%08X  channels %d  orders %d  +08 field %d (unread)  speed %d' %
          (mi, a, m['nch'], m['nord'], m['x8'], m['speed']))
        P('  order table %08X  pattern headers %d unique  instrument table %08X (%d instruments)' %
          (m['ords'], len(m['pat']), m['ins'], len(ins)))
        if m['pat']:
            pa = sorted(p['data_addr'] for p in m['pat'].values())
            pe = max(p['end'] for p in m['pat'].values())
            ph = sorted(m['pat'])
            P('  pattern headers %08X-%08X, pattern data %08X-%08X (%d bytes)' %
              (ph[0], ph[-1] + 8, pa[0], pe, pe - pa[0]))
        if ins:
            P('  instrument structs %08X-%08X, PCM headers %08X-%08X' % (
                min(i['addr'] for i in ins), max(i['addr'] for i in ins) + 16,
                min(i['hdr'] for i in ins), max(i['hdr'] for i in ins) + 8))
            real = [i for i in ins if i['data']]
            if real:
                P('  PCM %08X-%08X, %d bytes' % (min(i['data'] for i in real),
                                                   max(i['data'] + i['len'] for i in real),
                                                   sum(i['len'] for i in real)))
        P('')
        P('  -- instruments --')
        P('   #   struct    pcm hdr   data      length  loop          vol')
        for i in ins:
            loop = 'one-shot' if not i['le'] else '%d-%d' % (i['ls'], i['le'])
            P('  %3d  %08X  %08X  %08X %7d  %-13s %3d%s' % (
                i['n'], i['addr'], i['hdr'], i['data'], i['len'], loop, i['vol'],
                '   <- NULL data pointer' if i['data'] == 0 else ''))
        # wav export
        wd = os.path.join(outdir, '%s_wav' % tag)
        os.makedirs(wd, exist_ok=True)
        for i in ins:
            if not i['data'] or not r.ok(i['data']) or i['len'] > 2_000_000:
                continue
            pcm = struct.unpack_from('%db' % i['len'], r.d, i['data'] - B)
            loop = 'oneshot' if not i['le'] else 'loop%d-%d' % (i['ls'], i['le'])
            # natural pitch: C-5 in XM terms (period 3840) = 16726 Hz, the pitch the SFX code uses
            write_wav(os.path.join(wd, 'm%d_ins%02d_%08X_%s.wav' % (mi, i['n'], i['data'], loop)),
                      pcm, 16726)
        if not m['nord']:
            P('')
            P('  (no orders: used only as a sample bank)')
            P('')
            continue
        P('')
        P('  -- order list (pattern index; * = row count 0: 256 rows stored, engine plays 1) --')
        line = '  '
        for o, p in enumerate(m['order']):
            pat = m['pat'][p]
            s = '%3d:%03d%s' % (o, pat['idx'], '*' if pat['rows'] == 0 else ' ')
            line += s + ' '
            if (o + 1) % 10 == 0:
                P(line); line = '  '
        if line.strip():
            P(line)
        rows = collections.Counter(p['rows'] for p in m['pat'].values())
        P('  pattern lengths: ' + ', '.join('%d rows x%d' % kv for kv in sorted(rows.items())))
        # B effects
        P('')
        P('  -- position jumps (effect 14) --')
        bj = []
        for o, p in enumerate(m['order']):
            for rr, cells in enumerate(m['pat'][p]['data']):
                for c, ev in enumerate(cells):
                    if ev.get('fx') == 14:
                        bj.append((o, rr, c, ev['par']))
        seen = set()
        for o, rr, c, t in bj:
            P('    order %3d row %3d ch %d -> order %d' % (o, rr, c, t))
        # entries / sub-songs
        code_entries = set((entries_by_module or {}).get(a, []))
        covered = set()
        for e in code_entries:
            for o, rr, cells in walk_song(m, e):
                covered.add(o)
        extra = sorted(set(t for (_o, _r, _c, t) in bj if t not in covered and t < m['nord']))
        entries = sorted(code_entries | set(extra))
        if entries:
            P('')
            P('  -- tunes (entry orders used by the game code) --')
            for e in entries:
                orders = []
                last = None
                n = 0
                loopto = None
                for o, rr, cells in walk_song(m, e):
                    n += 1
                    if o != last:
                        orders.append(o); last = o
                # loop target = order of revisited position
                seq = list(walk_song(m, e))
                o_last, r_last, c_last = seq[-1]
                tgt = None
                for ev in c_last:
                    if ev.get('fx') == 14:
                        tgt = ev['par']
                wrapped = any(orders[k+1] < orders[k] and tgt is None for k in range(len(orders)-1))
                P('    entry %3d%s: orders %s, %d rows until it repeats%s' % (
                    e, '' if e in code_entries else ' (no call site; reached only as a jump target)',
                    ('%d-%d' % (orders[0], orders[-1])) if orders == sorted(orders) else
                    ' '.join('%d' % x for x in orders[:3]) + ' ... ' + ' '.join('%d' % x for x in orders[-2:]),
                    n, (', loops to order %d' % tgt) if tgt is not None else ''))
        # effects
        fx = collections.Counter(); par = collections.defaultdict(collections.Counter)
        volbytes = 0; notes = []; tpn = 0; insu = collections.Counter()
        for p in m['pat'].values():
            for cells in p['data']:
                for ev in cells:
                    if 'fx' in ev:
                        fx[ev['fx']] += 1; par[ev['fx']][ev['par']] += 1
                    if 'vol' in ev:
                        volbytes += 1
                    if 'note' in ev:
                        notes.append(ev['note']); insu[ev['ins']] += 1
                        tpn += ev['tp']
        allfx.update(fx)
        P('')
        P('  -- event statistics (all patterns) --')
        if notes:
            P('    notes %d (period %d-%d = %s..%s), tone-porta notes %d, volume bytes %d' % (
                len(notes), min(notes), max(notes), note_name(max(notes)), note_name(min(notes)),
                tpn, volbytes))
            P('    instruments used: ' + ' '.join('%d' % k for k in sorted(insu)))
        for k in sorted(fx):
            top = ', '.join('%02X x%d' % kv for kv in par[k].most_common(8))
            P('    fx %2d %-58s x%-5d  params: %s' % (k, EFFECT_NAMES.get(k, ''), fx[k], top))
        if entries:
            st = bug_stats(m, entries)
            P('')
            P('  -- events affected by engine quirks (counted once per row reached from the entries) --')
            if not st:
                P('    none')
            for k, v in sorted(st.items()):
                P('    %5d  %s' % (v, k))
        # pattern text
        pdir = os.path.join(outdir, '%s_patterns' % tag)
        os.makedirs(pdir, exist_ok=True)
        with open(os.path.join(pdir, 'module%d_%08X.txt' % (mi, a)), 'w') as f:
            f.write('module %d @%08X  (cell = note ins [*=tone porta, no retrigger] vNN fx:PP)\n' % (mi, a))
            f.write('note names: XM linear period -> XM note (C-4 = period 4608 = 8363 Hz)\n\n')
            for p in sorted(m['pat'].values(), key=lambda x: x['idx']):
                uses = [o for o, q in enumerate(m['order']) if q == p['hdr']]
                f.write('pattern %03d  hdr %08X  data %08X-%08X  rows %d  orders %s\n' % (
                    p['idx'], p['hdr'], p['data_addr'], p['end'], p['rows'], uses))
                if p['rows'] == 0:
                    f.write('  (row count 0 = 256 rows of data; the engine plays row 000 only and skips the rest)\n')
                for rr, cells in enumerate(p.get('full', p['data'])):
                    f.write('  %03d%s| %s\n' % (rr, 'x' if p['rows'] == 0 and rr else ' ',
                                               ' | '.join(cell_str(ev) for ev in cells)))
                f.write('\n')
        P('')
    open(os.path.join(outdir, '%s_data_dump.txt' % tag), 'w').write('\n'.join(L) + '\n')
    return '\n'.join(L)


if __name__ == '__main__':
    print(dump(sys.argv[1], sys.argv[2], sys.argv[3]))
