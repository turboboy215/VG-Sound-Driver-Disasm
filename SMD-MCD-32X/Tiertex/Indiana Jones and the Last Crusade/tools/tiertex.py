"""Tiertex / Donald Campbell Mega Drive sound engine - data parser & sample ripper.
Usage: python3 tiertex.py <rom> <game: ij|s2> <outdir>
"""
import struct, sys, os, wave

NOTE = ['C','C#','D','D#','E','F','F#','G','G#','A','A#','B']
def notename(n):
    if n == 0: return 'rest'
    n -= 1
    return '%s%d' % (NOTE[n % 12], n // 12)

GAMES = {
 'ij': dict(song_tbl=0xFB14, n_songs=19, inst_tbl=0x16F5C, cue_flag=0xFDC0, cue_tbl=0xFDD0,
            sfx_tbl=0xFE18, n_sfx=0x2B, dac_tbl=0xFEC4, n_dac=13, def_inst=0xFEF8,
            silent=0xF05A, z80=0xF0E2, z80len=0x616, glide=False),
 's2': dict(song_tbl=0x33480, n_songs=19, ext_tbl=0x3372C,
            sfx_tbl=0x337E8, n_sfx=0x40, dac_tbl=0x338E8, n_dac=9, def_inst=0x3390C,
            silent=0x32766, z80=0x327D8, z80len=0x73C, glide=True,
            speech_tbl=0x3AAA, n_speech=17),
}

class Rom:
    def __init__(s, path): s.d = open(path, 'rb').read()
    def b(s, a): return s.d[a]
    def w(s, a): return struct.unpack('>H', s.d[a:a+2])[0]
    def l(s, a): return struct.unpack('>I', s.d[a:a+4])[0]

def parse_track(data, glide, base=0, maxlen=None, start=0, sub=False):
    """Disassemble a sequence. data = bytes as they would sit in Z80 RAM. Returns list of lines & set of errors."""
    out = []; i = start; errs = []; calls = []
    fixed_dur = 0
    seen_end = False
    n = len(data) if maxlen is None else min(maxlen, len(data))
    while i < n:
        a = i; c = data[i]
        def rd(k): return data[i+1:i+1+k]
        if c < 0x80:
            i += 1
            txt = 'note %-4s' % notename(c)
            if fixed_dur:
                txt += ' (dur %d fixed)' % fixed_dur
            else:
                dur = data[i]; i += 1
                while i < n and data[i] == 0x7F:
                    dur += data[i+1]; i += 2
                txt += ' dur %d' % dur
            out.append((a, data[a:i], txt)); continue
        if c == 0xA0:
            out.append((a, data[a:a+33], 'inline_voice ' + data[a+1:a+33].hex())); i += 33; continue
        if 0x80 <= c <= 0x9E:
            out.append((a, data[a:a+1], 'voice %d' % (c & 0x1F))); i += 1; continue
        if c == 0x9F:
            p = data[i+1:i+6]
            out.append((a, data[a:a+6], 'keysplit split=%s lo:voice %d tr %+d  hi:voice %d tr %+d' % (
                notename(p[0]), p[1], struct.unpack('b', p[2:3])[0], p[3], struct.unpack('b', p[4:5])[0])))
            i += 6; continue
        if c < 0xEF or (0xF0 <= c <= 0xF2) or (c == 0xF3 and not glide):
            out.append((a, data[a:a+1], 'nop_%02X' % c)); i += 1; continue
        if c == 0xEF:
            v = data[i+1] | data[i+2] << 8
            out.append((a, data[a:a+3], 'set_freq_base $%04X' % v)); i += 3; continue
        if c == 0xF3:
            out.append((a, data[a:a+2], 'glide %d (over %d ticks)' % (data[i+1], 1 << data[i+1]))); i += 2; continue
        if c == 0xF4:
            out.append((a, data[a:a+1], 'cue_68k')); i += 1; continue
        if c == 0xF5:
            out.append((a, data[a:a+1], 'legato_toggle')); i += 1; continue
        if c == 0xF6:
            fixed_dur = data[i+1]
            out.append((a, data[a:a+2], 'fixed_dur %d' % data[i+1])); i += 2; continue
        if c == 0xF7:
            v = data[i+1] | data[i+2] << 8
            out.append((a, data[a:a+3], 'dur_frac $%04X' % v)); i += 3; continue
        if c == 0xF8:
            out.append((a, data[a:a+1], 'call_return')); i += 1
            if sub: seen_end = True; break
            continue
        if c == 0xF9:
            cnt, tr = data[i+1], struct.unpack('b', data[i+2:i+3])[0]
            off = struct.unpack('<h', data[i+3:i+5])[0]
            tgt = i + 3 + off
            calls.append(tgt)
            out.append((a, data[a:a+5], 'call_loop x%d tr %+d -> sub_%04X' % (cnt, tr, base + tgt))); i += 5; continue
        if c == 0xFA:
            out.append((a, data[a:a+1], 'dur_frac_clear')); i += 1; continue
        if c == 0xFB:
            v = data[i+1] | data[i+2] << 8
            out.append((a, data[a:a+4], 'dur_frac $%04X + loop_start x%d' % (v, data[i+3]))); i += 4; continue
        if c == 0xFC:
            out.append((a, data[a:a+2], 'loop_start x%d' % data[i+1])); i += 2; continue
        if c == 0xFD:
            out.append((a, data[a:a+1], 'loop_end')); i += 1; continue
        if c == 0xFE:
            out.append((a, data[a:a+1], 'track_end')); i += 1; seen_end = True; break
        if c == 0xFF:
            out.append((a, data[a:a+1], 'track_restart')); i += 1; seen_end = True; break
    parse_track.calls = calls
    return out, i, seen_end

def fmt_track(lines, base):
    return '\n'.join('  %04X: %-16s %s' % (base + a, b.hex(' ') if len(b) <= 6 else b[:6].hex(' ') + '..', t) for a, b, t in lines)

def write_wav(path, pcm, rate, bits8=True):
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(1); w.setframerate(int(round(rate))); w.writeframes(bytes(pcm))

NTSC_BASE = 7670453 / 144
PAL_BASE = 7600489 / 144
def timer_a(rate):
    ta = 0x400 - (0xCE2A // rate)
    return ta, NTSC_BASE / (1024 - ta), PAL_BASE / (1024 - ta)

# ---- Strider II Huffman decoders ----
class BitSrc:
    def __init__(s, get_byte): s.get = get_byte; s.bit = 8; s.cur = 0
    def next(s):
        if s.bit == 8: s.cur = s.get(); s.bit = 0
        v = (s.cur >> s.bit) & 1; s.bit += 1; return v

def huff_decode(rom, a0, nibble):
    d = rom.d
    if nibble:
        def mk(p):
            st = {'p': p}
            def g():
                v = (d[st['p']] & 0xF0) | (d[st['p'] + 2] >> 4); st['p'] += 4; return v
            return g, st
        tb, _ = mk(a0); lv, lst = mk(a0 + 0x100)
        ln = 0
        for k in range(8): ln = (ln << 4) | (d[a0 + 0x500 + 2 * k] >> 4)
        ds, dst = mk(a0 + 0x520)
    else:
        def mk(p):
            st = {'p': p}
            def g():
                v = d[st['p']]; st['p'] += 1; return v
            return g, st
        tb, _ = mk(a0); lv, lst = mk(a0 + 0x40)
        ln = struct.unpack('>I', d[a0 + 0x140:a0 + 0x144])[0]
        ds, dst = mk(a0 + 0x148)
    bits = BitSrc(tb)
    def build():
        if bits.next() == 0: return lv()
        l = build(); r = build(); return (l, r)
    tree = build()
    count = (ln & 0xFFFF) + 1
    out = bytearray(); bs = BitSrc(ds)
    for _ in range(count):
        n = tree
        while isinstance(n, tuple): n = n[bs.next()]
        out.append(n)
    return out, ln, (dst['p'] - a0)

def speech_delta(buf):
    """68k post-process at $3A7A: first word = length, then running sum of bytes, x4."""
    ln = struct.unpack('>H', buf[0:2])[0]
    body = buf[2:]
    acc = 0; pcm = bytearray()
    for i in range(ln):
        if i >= len(body): break
        acc = (acc + body[i]) & 0xFF
        pcm.append((acc << 2) & 0xFF)
    return ln, pcm

def fmt_voice(v):
    alg = v[0] & 7; fb = (v[0] >> 3) & 7
    r = v[1:29]; pan = v[29]
    names = ['DT/MUL','TL','RS/AR','AM/D1R','D2R','D1L/RR','SSG-EG']
    s = 'ALG %d FB %d  pan/AMS/FMS $%02X%s\n' % (alg, fb, pan, ' (=>$C0)' if pan == 0 else '')
    s += '        %-8s %s\n' % ('', '  '.join('%-4s' % o for o in ('op1', 'op3', 'op2', 'op4')))
    for k, n in enumerate(names):
        s += '        %-8s %s\n' % (n, '  '.join('$%02X ' % x for x in r[k*4:k*4+4]))
    return s

S2_SFX_NAMES = None
def main():
    rom = Rom(sys.argv[1]); g = GAMES[sys.argv[2]]; od = sys.argv[3]
    os.makedirs(od, exist_ok=True); os.makedirs(od + '/samples', exist_ok=True)
    rep = []; P = rep.append
    glide = g['glide']
    global S2_SFX_NAMES
    if sys.argv[2] == 's2':
        S2_SFX_NAMES = [rom.d[0x2B72 + 16*k:0x2B82 + 16*k].decode().rstrip() for k in range(64)]
    # ---------- songs ----------
    P('==== MUSIC ====')
    bad = 0
    for s in range(g['song_tbl'] and g['n_songs']):
        e = g['song_tbl'] + s * 36
        ptrs = [rom.l(e + 4 * i) for i in range(6)]; lens = [rom.w(e + 0x18 + 2 * i) for i in range(6)]
        if 'inst_tbl' in g:
            inst = rom.l(g['inst_tbl'] + 4 * s); isz = 0x3E0; cue = None
            if s:
                if rom.b(g['cue_flag'] + s - 1): cue = rom.l(g['cue_tbl'] + 4 * (s - 1))
        else:
            if s:
                x = g['ext_tbl'] + (s - 1) * 10
                cue = rom.l(x) or None; inst = rom.l(x + 4); isz = rom.w(x + 8) + 1
            else:
                inst = None; isz = 0; cue = None
        P('\nSong %02X: voice bank $%s (%s bytes)%s' % (s, '%06X' % inst if inst else '-', isz,
            ('  cue list $%06X' % cue) if cue else ''))
        if cue:
            q = []; a = cue
            while rom.w(a) != 0xFFFF and len(q) < 64: q.append('%02X' % rom.w(a)); a += 2
            P('  cue SFX list: ' + ' '.join(q))
        z = 0x0E00; blob = bytearray(); entries = []
        for ch in range(6):
            p = ptrs[ch]
            if p & 0x80000000: entries.append((ch, None, None, 0)); continue
            if p == 0:
                entries.append((ch, z, g['silent'], 0x28)); blob += rom.d[g['silent']:g['silent'] + 0x28]; z += 0x28; continue
            ln = lens[ch]; entries.append((ch, z, p, ln)); blob += rom.d[p:p + ln]; z += ln
        cov = bytearray(len(blob))
        subs = set(); done = set()
        for ch, za, p, ln in entries:
            if za is None: P('  FM%d: (left unchanged)' % (ch + 1)); continue
            if p == g['silent']:
                P('  FM%d: silent stub copied from $%06X -> Z80 $%04X' % (ch + 1, p, za))
                for k in range(0x28): cov[za - 0xE00 + k] = 1
                continue
            P('  FM%d: ROM $%06X len $%04X -> Z80 $%04X' % (ch + 1, p, ln, za))
            lines, used, end = parse_track(blob, glide, base=0xE00, start=za - 0xE00)
            for a, b, t in lines:
                for k in range(len(b)): cov[a + k] = 1
            subs |= set(parse_track.calls)
            P(fmt_track(lines, 0xE00))
        todo = sorted(subs)
        while todo:
            t = todo.pop(0)
            if t in done: continue
            done.add(t)
            lines, used, end = parse_track(blob, glide, base=0xE00, start=t, sub=True)
            for a, b, tt in lines:
                for k in range(len(b)): cov[a + k] = 1
            for c in parse_track.calls:
                if c not in done: todo.append(c)
            P(' sub_%04X:%s' % (0xE00 + t, '' if end else '  <-- no terminator'))
            if not end: bad += 1
            P(fmt_track(lines, 0xE00))
        unc = [i for i in range(len(blob)) if not cov[i]]
        if unc:
            P('  ** %d uncovered bytes, first at Z80 $%04X' % (len(unc), 0xE00 + unc[0])); bad += 1
        if z > 0x1B00: P('  !! overflows into SFX area: end $%04X' % z)
    # ---------- voice banks ----------
    P('\n==== VOICE BANKS (32 bytes per voice, voice n at Z80 $0A00 + n*32) ====')
    banks = {}
    if 'inst_tbl' in g:
        for s_ in range(1, g['n_songs']): banks.setdefault(rom.l(g['inst_tbl'] + 4 * s_), (0x3E0, []))[1].append(s_)
    else:
        for s_ in range(1, g['n_songs']):
            x = g['ext_tbl'] + (s_ - 1) * 10
            banks.setdefault(rom.l(x + 4), (rom.w(x + 8) + 1, []))[1].append(s_)
    banks.setdefault(g['def_inst'], (0x3E0, []))
    for addr in sorted(banks):
        size, users = banks[addr]
        P('\nBank $%06X, $%X bytes, used by songs %s' % (addr, size, ' '.join('%02X' % u for u in users) or '(default bank, loaded at boot)'))
        for n in range(size // 32):
            v = rom.d[addr + n * 32: addr + n * 32 + 32]
            if not any(v): continue
            P('  voice %02d ($%06X): ' % (n, addr + n * 32) + fmt_voice(v).rstrip())
    # ---------- sfx ----------
    P('\n==== SFX ====')
    for i in range(g['n_sfx']):
        v = rom.l(g['sfx_tbl'] + 4 * i); smp = v >> 24; p = v & 0xFFFFFF
        if smp:
            ln = rom.w(g['dac_tbl'] + 4 * smp); rt = rom.w(g['dac_tbl'] + 4 * smp + 2)
            nm = (' "%s"' % S2_SFX_NAMES[i]) if (S2_SFX_NAMES and sys.argv[2] == 's2') else ''
            P('\nSFX %02X%s: DAC sample #%d at $%06X (plays on FM6/DAC)' % (i, nm, smp, p)); continue
        data = rom.d[p:p + 256]
        lines, used, end = parse_track(data, glide, base=0)
        nm = (' "%s"' % S2_SFX_NAMES[i]) if (S2_SFX_NAMES and sys.argv[2] == 's2') else ''
        P('\nSFX %02X%s: FM track $%06X (%d bytes)%s' % (i, nm, p, used, '' if end else '  <-- no end in 256 bytes'))
        if not end: bad += 1
        P(fmt_track(lines, 0))
    # ---------- samples ----------
    P('\n==== DAC SAMPLE TABLE ====')
    users = {}
    for i in range(g['n_sfx']):
        v = rom.l(g['sfx_tbl'] + 4 * i)
        if v >> 24: users.setdefault(v >> 24, []).append((i, v & 0xFFFFFF))
    for k in range(1, g['n_dac']):
        ln = rom.w(g['dac_tbl'] + 4 * k); rt = rom.w(g['dac_tbl'] + 4 * k + 2)
        if ln == 0: P('#%d: empty' % k); continue
        ta, fn, fp = timer_a(rt)
        us = users.get(k, [])
        P('#%-2d len $%04X  nominal %5d Hz  TA=%d  NTSC %.0f Hz  PAL %.0f Hz  used by SFX %s' % (k, ln, rt, ta, fn, fp,
            ', '.join('%02X@$%06X' % u for u in us) or '(none)'))
        for (sid, p) in us[:1]:
            pcm = rom.d[p:p + ln]
            write_wav('%s/samples/dac%02d_sfx%02X_%06X.wav' % (od, k, sid, p), pcm, fp if sys.argv[2]=='s2' else fp)
    if 'speech_tbl' in g:
        P('\n==== SPEECH TABLE ($%06X) ====' % g['speech_tbl'])
        for k in range(g['n_speech']):
            a = g['speech_tbl'] + 6 * k; p = rom.l(a); rt = rom.w(a + 4)
            if p == 0:
                sid = rt; v = rom.l(g['sfx_tbl'] + 4 * sid); smp = v >> 24
                ln = rom.w(g['dac_tbl'] + 4 * smp); rt2 = rom.w(g['dac_tbl'] + 4 * smp + 2)
                ta, fn, fp = timer_a(rt2)
                P('Speech %02X: uncompressed, = SFX %02X (DAC #%d $%06X len $%04X %d Hz nominal, NTSC %.0f / PAL %.0f)' % (k, sid, smp, v & 0xFFFFFF, ln, rt2, fn, fp))
                write_wav('%s/samples/speech%02X_raw_%06X.wav' % (od, k, v & 0xFFFFFF), rom.d[(v & 0xFFFFFF):(v & 0xFFFFFF) + ln], fp)
                continue
            nib = bool(p & 0x80000000); src = p & 0x7FFFFFFF
            buf, rawlen, consumed = huff_decode(rom, src, nib)
            ln, pcm = speech_delta(buf)
            ta, fn, fp = timer_a(rt)
            P('Speech %02X: %s Huffman at $%06X (packed span $%X bytes) -> %d bytes, %d samples, nominal %d Hz, TA=%d NTSC %.0f / PAL %.0f Hz' % (
                k, 'nibble-interleaved' if nib else 'byte', src, consumed, rawlen, ln, rt, ta, fn, fp))
            write_wav('%s/samples/speech%02X_%s_%06X.wav' % (od, k, 'huffN' if nib else 'huff', src), pcm, fp)
    open(od + '/report.txt', 'w').write('\n'.join(rep) + '\n')
    print('parse problems:', bad)

if __name__ == '__main__':
    main()
