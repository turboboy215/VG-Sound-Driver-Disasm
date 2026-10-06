"""Generate RGBDS sources for one QuickThunder GB(C) sound bank.

usage: qtgen.py <game> <outdir>
"""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qtcfg import GAMES
from qtparse import Data, fill_gaps, notename
from qtram import ram_names
from sm83 import decode
from trace import trace

HW = {0xFF10: 'rNR10', 0xFF11: 'rNR11', 0xFF12: 'rNR12', 0xFF13: 'rNR13', 0xFF14: 'rNR14',
      0xFF16: 'rNR21', 0xFF17: 'rNR22', 0xFF18: 'rNR23', 0xFF19: 'rNR24', 0xFF1A: 'rNR30',
      0xFF1B: 'rNR31', 0xFF1C: 'rNR32', 0xFF1D: 'rNR33', 0xFF1E: 'rNR34', 0xFF20: 'rNR41',
      0xFF21: 'rNR42', 0xFF22: 'rNR43', 0xFF23: 'rNR44', 0xFF24: 'rNR50', 0xFF25: 'rNR51',
      0xFF26: 'rNR52', 0xFF05: 'rTIMA', 0xFF06: 'rTMA', 0xFF07: 'rTAC', 0xFF0F: 'rIF', 0xFFFF: 'rIE',
      0xFF30: '_AUD3WAVERAM'}

PAT_KINDS = ('note', 'hold', 'keyoff', 'keyon', 'patend', 'songloop', 'sfxend', 'sfxloop')


class Gen:
    def __init__(s, g):
        s.g = g
        s.c = GAMES[g]
        D = s.D = Data(g)
        D.run()
        code, labels = trace(D.m, s.c['entries'], 0x4000, 0x8000)
        ce = 0x4000
        while ce in code:
            ce += 1
        fill_gaps(D, start=ce)
        s.m = D.m
        s.code = code
        from qtlabels import names as label_names
        nm = label_names(g)
        s.clabels = {}
        for a in sorted(labels):
            if 0x4000 <= a < 0x8000:
                s.clabels[a] = nm.get(a, 'L%04X' % a)
        s.ram, s.ramsize = ram_names(g)
        from qtlabels import NAMES
        s.names = NAMES.get(g, {})
        s.rambase = s.c['ram']
        # end of the rebuilt range
        s.end = max(max(code), D.region_end) + 1
        # the code may continue after the data (Carmageddon)
        if s.c.get('pcm'):
            s.end = max(s.end, s.c['pcm'] + 6 * 0x1F)
        s.out = []

    # ------------------------------------------------------------ symbols
    def ramsym(s, a):
        o = a - s.rambase
        if 0 <= o < s.ramsize + 2:
            if o in s.ram:
                return s.ram[o]
            if o - 1 in s.ram:
                return s.ram[o - 1] + '+1'
            return 'wQT+$%02X' % o
        return None

    def ref(s, a):
        """symbolic name for a ROM address"""
        D = s.D
        if a in s.clabels:
            return s.clabels[a]
        if a in D.labels and (a in D.items or a in s.code or a >= s.end or a not in D.owner):
            return D.labels[a]
        if a in D.owner:
            base = D.owner[a]
            if base in D.labels:
                return '%s+%d' % (D.labels[base], a - base)
        if a in s.code:
            # inside code: nearest code label
            b = max(x for x in s.clabels if x <= a)
            return '%s+%d' % (s.clabels[b], a - b)
        return '$%04X' % a

    def tref(s, ptr, off):
        """table pointer field: returns the expression E so that (E) - off == ptr"""
        t = (ptr + off) & 0xFFFF
        if 0x4000 <= t < 0x8000 and (t in s.D.labels or t in s.D.owner or t in s.code):
            r = s.ref(t)
            if not r.startswith('$'):
                return r
        return '$%04X' % t

    # ------------------------------------------------------------ code
    def fmt_ins(s, a, n, m, o, prev):
        if o is None:
            return m
        k, v = o
        if k in ('rel', 'addr16') and (m.startswith('j') or m.startswith('call')):
            return m.format(s.clabels.get(v, '$%04X' % v))
        if k == 'ldh':
            return m.format(HW.get(v, '$%04X' % v))
        if k == 'addr16':
            r = s.ramsym(v)
            if r:
                return m.format(r)
            if v in HW:
                return m.format(HW[v])
            if 0x4000 <= v < 0x8000:
                return m.format(s.ref(v))
            return m.format('$%04X' % v)
        if k == 'imm16':
            r = s.ramsym(v)
            if r:
                return m.format(r)
            if v in HW:
                return m.format(HW[v])
            if 0x4000 <= v < 0x8000 and (v in s.D.labels or v in s.D.owner or v in s.clabels):
                return m.format(s.ref(v))
            return m.format('$%04X' % v)
        if k == 'imm8':
            ov = s.imm8_over.get(a)
            if ov:
                return m.format(ov)
            return m.format('$%02X' % v)
        return m.format('$%02X' % v)

    def find_imm8_overrides(s):
        """ld a,LOW(x) / ld a,HIGH(x) pairs and cp LOW(channel) after noteechanadr loads."""
        s.imm8_over = {}
        seq = []
        a = 0x4000
        while a < s.end:
            if a in s.code:
                n, m, o = decode(s.m, a)
                seq.append((a, n, m, o))
                a += n
            else:
                a += 1
        for i, (a, n, m, o) in enumerate(seq):
            if m == 'ld a, {}' and o[0] == 'imm8':
                # look ahead for the matching high byte
                for j in range(i + 1, min(i + 4, len(seq))):
                    a2, n2, m2, o2 = seq[j]
                    if m2 == 'ld a, {}' and o2[0] == 'imm8':
                        v = o[1] | o2[1] << 8
                        if 0x4000 <= v < 0x8000 and (v in s.D.labels or v in s.D.owner):
                            r = s.ref(v)
                            s.imm8_over[a] = 'LOW(%s)' % r
                            s.imm8_over[a2] = 'HIGH(%s)' % r
                        break
            if m == 'cp a, {}' and o[0] == 'imm8':
                # cp LOW(tempoN) after ld a,[noteechanadr]
                for j in range(max(0, i - 8), i):
                    a0, n0, m0, o0 = seq[j]
                    if o0 and o0[0] == 'addr16' and s.ramsym(o0[1]) == 'noteechanadr' and \
                            all(not seq[k][2].startswith('ld a, ') or seq[k][2] == 'ld a, [{}]' and seq[k][3] == o0
                                for k in range(j + 1, i)):
                        v = (s.rambase & 0xFF00) | o[1]
                        r = s.ramsym(v)
                        if r and v >= s.rambase:
                            s.imm8_over[a] = 'LOW(%s)' % r
                # SoundFX: second compare after a branch, a still holds noteechanadr
                if a not in s.imm8_over:
                    v = (s.rambase & 0xFF00) | o[1]
                    if s.ramsym(v) in ('tempo2', 'tempo4') and v >= s.rambase and any(
                            seq[j][3] and seq[j][3][0] == 'addr16' and s.ramsym(seq[j][3][1]) == 'noteechanadr'
                            and seq[j][2] == 'ld a, [{}]' for j in range(max(0, i - 12), i)):
                        s.imm8_over[a] = 'LOW(%s)' % s.ramsym(v)
            if m in ('ld a, {}',) and o[0] == 'imm8' and a not in s.imm8_over:
                pass

    # ------------------------------------------------------------ data lines
    def data_lines(s, it):
        D = s.D
        a = it.addr
        k = it.kind
        f = it.f
        b = s.m[a:a + it.size]
        w = lambda x: s.m[x] | s.m[x + 1] << 8
        hx = lambda bs: ', '.join('$%02X' % x for x in bs)
        L = []
        if k == 'freqtab':
            for i in range(0, 72, 8):
                L.append('dw ' + ', '.join('$%04X' % w(a + 2 * j) for j in range(i, i + 8)) +
                         ' ; %s-%s' % (notename(i), notename(i + 7)))
        elif k == 'ptrtab':
            names = {'pat': 'Pat%03d', 'ins': 'Ins%02d', 'ins4': 'NoiseIns%02d'}
            for i in range(f['n']):
                p = w(a + 2 * i)
                r = s.ref(p) if 0x4000 <= p < 0x8000 else '$%04X' % p
                L.append('dw %-24s ; $%02X' % (r, i))
        elif k == 'song':
            nm = s.names.get('songs', [])
            if f['n'] < len(nm):
                L.append('; song $%02X: %s' % (f['n'], nm[f['n']]))
            L += s.song_lines(it)
        elif k == 'sfxent':
            p = f['ptr']
            r = s.ref(p) if 0x4000 <= p < 0x8000 else '$%04X' % p
            chn = 'ch2' if f['ch'] == 2 else 'ch4'
            nm = s.names.get('sfx', [])
            if f['n'] < len(nm):
                chn += ', ' + nm[f['n']]
            if f['pri'] is None:
                L.append('dw %s' % r)
                L.append('db %d ; %s  (SFX $%02X)' % (f['ch'], chn, f['n']))
            else:
                L.append('db %d ; priority' % f['pri'])
                L.append('dw %s' % r)
                L.append('db %d ; %s  (SFX $%02X)' % (f['ch'], chn, f['n']))
        elif k == 'step':
            pat = f['pat']
            pn = 'Pat%03d' % pat if pat < D.npat and D.w(D.c['tabs']['pattab'] + 2 * pat) in D.labels else '%d' % pat
            tr = f['tr']
            trs = '%d' % (tr - 256 if tr >= 128 else tr)
            com = ' ; (dead: after the song jump)' if f.get('dead') else ''
            if s.c['step'] == 4 and f['unused']:
                L.append('STEP %s, $%03X, $%02X%s' % (trs, pat, f['unused'], com))
            else:
                L.append('STEP %s, $%03X%s' % (trs, pat, com) if s.c['step'] == 4 else 'STEP %s, $%02X%s' % (trs, pat, com))
        elif k == 'note':
            ch = f['chans']
            if 4 in ch and len(ch) == 1:
                nm = '$%02X' % f['note']
            elif s.g == 'cmr' and ch == (3,):
                nm = '$%02X' % f['note']
            else:
                nm = notename(f['note']) if f['note'] < 84 else '$%02X' % f['note']
            com = ''
            if s.g == 'cmr' and 3 in ch:
                com = ' ; PCM sample $%02X' % f['ins']
            L.append('NOTE %d, %s, $%02X%s' % (f['dur'], nm, f['ins'], com))
        elif k == 'hold':
            L.append('HOLD %d' % f['dur'])
        elif k == 'keyoff':
            L.append('KEYOFF %d' % f['dur'])
        elif k == 'keyon':
            L.append('KEYON %d' % f['dur'])
        elif k == 'patend':
            if f.get('sfxover') is not None:
                L.append('PATEND ; SFX end: the driver reads the loop word ($%04X) from the next bytes' % f['sfxover'])
            else:
                L.append('PATEND')
        elif k == 'songloop':
            t = f['target']
            r = s.ref(t) if 0x4000 <= t < 0x8000 else '$%04X' % t
            L.append('SONGJUMP %s' % r)
        elif k == 'sfxend':
            lo = f['target'] & 0xFF
            L.append('SFXEND' + (' $%02X' % lo if lo else ''))
        elif k == 'sfxloop':
            t = f['target']
            r = s.ref(t) if 0x4000 <= t < 0x8000 else '$%04X' % t
            L.append('SFXLOOP %s' % r + ('' if 0x4000 <= t < 0x8000 else ' ; outside the bank!'))
        elif k.startswith('t2:'):
            kind = k[3:]
            v = b[1]
            com = ''
            if kind == 'arp':
                com = ' ; %+d' % (v - 256 if v >= 128 else v)
            elif kind == 'comb':
                com = {0: ' ; freq table only', 1: ' ; note only', 2: ' ; note + freq table'}.get(v, ' ; = note only')
            elif kind == 'vol':
                com = {0x00: ' ; mute', 0x20: ' ; 100%', 0x40: ' ; 50%', 0x60: ' ; 25%'}.get(v & 0x60, '')
            L.append('TB %d, $%02X%s' % (b[0], v, com))
        elif k.startswith('t3:'):
            kind = k[3:]
            if kind == 'morph':
                L.append('MORPH %d, $%02X, $%02X' % (b[0], b[1], b[2]))
            else:
                v = b[1] | b[2] << 8
                sv = v - 65536 if v >= 32768 else v
                L.append('TW %d, %d' % (b[0], sv))
        elif k == 'tend':
            t = f['target']
            r = s.ref(t) if 0x4000 <= t < 0x8000 else '$%04X' % t
            L.append('TLOOP %s' % r)
        elif k.startswith('ins:'):
            L += s.ins_lines(it)
        elif k == 'wave':
            L.append('db ' + hx(b) + ('' if f.get('full') else ' ; (wave continues into the next object)'))
        elif k == 'wavetail':
            L.append('db ' + hx(b) + ' ; rest of %s' % s.ref(f['of']))
        elif k == 'endmark':
            L.append('db "-- THE END --" ; end-of-data marker left by the converter')
        elif k == 'wordtab':
            for i in range(0, it.size // 2, 8):
                L.append('dw ' + ', '.join('$%04X' % w(a + 2 * j) for j in range(i, min(i + 8, it.size // 2))))
        elif k == 'pcmtab':
            for i in range(f['n']):
                e = a + 6 * i
                pc = D.pcm[i]
                L.append('db $%02X ; priority' % pc['pri'])
                L.append('dw %s' % s.pcm_label(pc))
                L.append('dw $%04X ; length in 16-byte blocks' % pc['blocks'])
                L.append('db BANK(%s) ; PCM $%02X' % (s.pcm_label(pc), i))
        else:
            L.append('db ' + hx(b) + ' ; ?? %s' % k)
        return L

    def pcm_label(s, pc):
        return 'Pcm%02X' % pc['n']

    def song_lines(s, it):
        f = it.f
        D = s.D
        a = it.addr
        w = lambda x: s.m[x] | s.m[x + 1] << 8
        L = []
        r = lambda p: s.ref(p) if 0x4000 <= p < 0x8000 else '$%04X' % p
        fmt = s.c['song']
        if f.get('invalid'):
            L.append('db ' + ', '.join('$%02X' % x for x in s.m[a:a + it.size]) + ' ; (not a valid song)')
            return L
        if fmt == 'c3':
            L.append('dw %s, %s, %s' % tuple(r(f['chans'][c]) for c in (1, 2, 4)))
        elif fmt in ('c4w', 'c4mw'):
            L.append('dw %s, %s, %s, %s' % tuple(r(f['chans'][c]) for c in (1, 2, 3, 4)))
            L.append('db %d ; tempo (frames per tick)' % f['tempo'])
            if fmt == 'c4mw':
                L.append('dw %s - 2 ; wave morph' % s.tref(f['morph'], 2))
            L.append('dw %s ; wave' % r(f['wave']))
        else:
            L.append('db %d, %%%s ; tempo, channel mask' % (f['tempo'], format(f['mask'], '04b')))
            ps = [r(f['chans'][c]) for c in (1, 2, 3, 4) if c in f['chans']]
            if ps:
                L.append('dw ' + ', '.join(ps))
            if f['morph'] is not None:
                L.append('dw %s - 2, %s ; wave morph, wave%s' % (s.tref(f['morph'], 2), r(f['wave']),
                                                                ' (not read by this driver)' if not s.c['wave'] else ''))
            pad = s.m[a + f['used']:a + it.size]
            if pad:
                L.append('db ' + ', '.join('$%02X' % x for x in pad) + ' ; (unused)')
        return L

    def ins_lines(s, it):
        typ = it.kind[4:]
        a = it.addr
        b = s.m[a:a + it.size]
        w = lambda x: s.m[x] | s.m[x + 1] << 8
        f = it.f
        com = ''
        if f.get('idx'):
            com = ' ; ' + ', '.join('$%02X' % i for i in f['idx'])
        if not f.get('used') and not f.get('orphan'):
            com += ' (unused)'
        if f.get('orphan'):
            com = ' ; not in the instrument table'
        if it.size < f.get('full', it.size):
            return ['db ' + ', '.join('$%02X' % x for x in b) + com + ' (record cut short: overlaps its own table)']
        if typ == 'tone':
            return ['INS_TONE $%02X, $%02X, $%02X, %s, %s, %s%s' % (b[0], b[1], b[2], s.tref(w(a + 3), 1),
                                                                   s.tref(w(a + 5), 2), s.tref(w(a + 7), 1), com)]
        if typ == 'wave':
            return ['INS_WAVE %s, %s, %s, %s, %s%s' % (s.tref(w(a), 1), s.tref(w(a + 2), 1), s.tref(w(a + 4), 1),
                                                      s.tref(w(a + 6), 2), s.tref(w(a + 8), 1), com)]
        return ['INS_NOISE $%02X, $%02X, $%02X, %s, %s%s' % (b[0], b[1], b[2], s.tref(w(a + 3), 1),
                                                            s.tref(w(a + 5), 1), com)]

    # ------------------------------------------------------------ emit
    def emit(s, outdir, name):
        s.find_imm8_overrides()
        return s.emit_range(0x4000)

    def emit_range(s, start):
        D = s.D
        lines = []
        P = lines.append
        a = start
        last_kind = None
        while a < s.end:
            lab_c = s.clabels.get(a)
            if a in s.code:
                if lab_c:
                    from qtlabels import COMMENTS
                    P('')
                    com = COMMENTS.get(lab_c)
                    if com:
                        P('; ' + '-' * 75)
                        for cl in com.split('\n'):
                            P('; ' + cl)
                    P('%s:' % lab_c + (':' if a in s.c['api'] else ''))
                n, m, o = decode(s.m, a)
                P('    ' + s.fmt_ins(a, n, m, o, None))
                a += n
                last_kind = 'code'
                continue
            if a in D.items:
                it = D.items[a]
                inner = [x for x in range(a + 1, a + it.size) if x in D.labels and D.labels[x] not in ('',)]
                inner = [x for x in inner if not s.ref(x).startswith(D.labels.get(a, '#') + '+')]
                lab = D.labels.get(a)
                if lab:
                    if it.kind not in ('step', 'tend') and it.kind[:2] not in ('t2', 't3') or \
                            last_kind not in (it.kind,) or True:
                        P('')
                    P('%s:' % lab)
                if inner:
                    # a label falls inside this item: emit raw bytes around it
                    x = a
                    for y in inner + [a + it.size]:
                        P('    db ' + ', '.join('$%02X' % v for v in s.m[x:y]) + ' ; part of %s' % it.kind)
                        if y < a + it.size:
                            P('%s:' % D.labels[y])
                        x = y
                else:
                    for l in s.data_lines(it):
                        P('    ' + l)
                a += it.size
                last_kind = it.kind
                continue
            # raw bytes until next item/code/label
            b = a
            while b < s.end and b not in D.items and b not in s.code and (b == a or b not in D.labels):
                b += 1
            if a in D.labels:
                P('')
                P('%s:' % D.labels[a])
            chunk = s.m[a:b]
            P('')
            P('    ; $%04X-$%04X: %d unreferenced byte%s' % (a, b - 1, b - a, 's' if b - a > 1 else ''))
            for i in range(0, len(chunk), 16):
                P('    db ' + ', '.join('$%02X' % v for v in chunk[i:i + 16]))
            a = b
            last_kind = 'raw'
        return lines


NAMES = {'carm': 'Carmageddon', 'casperu': 'CasperU', 'caspere': 'CasperE', 'chicken': 'ChickenRun',
         'gng': 'GhostsNGoblins', 'dukes': 'DukesOfHazzard', 'xgb': 'ExtremeGhostbusters', 'cmr': 'ColinMcRae', 'pinball': 'Pinball3DUltra'}


def write_game(g, outdir):
    G = Gen(g)
    c = G.c
    nm = NAMES[g]
    G.find_imm8_overrides()
    code_end = 0x4000
    while code_end in G.code:
        code_end += 1
    full_end = G.end
    G.end = code_end
    drv = G.emit_range(0x4000)
    G.end = full_end
    dat = G.emit_range(code_end)
    bank = c['bank'] if c['bank'] is not None else 1
    hdr = []
    H = hdr.append
    H('; ' + '=' * 77)
    H('; %s - AudioArts QuickThunder GB sound bank' % c['title'])
    if c['bank'] is not None:
        H('; source: %s, bank $%02X, $4000-$%04X' % (c['file'], bank, G.end - 1))
    else:
        H('; source: %s (raw image, linked at $4000), $4000-$%04X' % (c['file'], G.end - 1))
    H('; generated by qtgen.py; rebuilds byte-exact with RGBDS 0.9.1 (see build_check.sh)')
    H('; ' + '=' * 77)
    H('')
    H('DEF QT_STEP_SIZE EQU %d' % c['step'])
    H('INCLUDE "QT_Macros.inc"   ; in the parent folder (rgbasm -I ..)')
    H('')
    H('; ---------------------------------------------------------------- RAM')
    H('DEF wQT EQU $%04X' % G.rambase)
    for o in sorted(G.ram):
        H('DEF %-14s EQU wQT + $%02X' % (G.ram[o], o))
    H('')
    H('SECTION "QuickThunder %s", ROMX[$4000], BANK[$%02X]' % (nm, bank))
    H('')
    H('INCLUDE "%s_Driver.inc"' % nm)
    H('INCLUDE "%s_Data.inc"' % nm)
    if g == 'cmr':
        H('')
        H('INCLUDE "%s_PCM.inc"   ; PCM sample sections (banks $7D-$7F)' % nm)
    os.makedirs(outdir, exist_ok=True)
    open(os.path.join(outdir, 'QT_%s.asm' % nm), 'w').write('\n'.join(hdr) + '\n')
    open(os.path.join(outdir, '%s_Driver.inc' % nm), 'w').write(
        '; %s - driver code $4000-$%04X\n' % (c['title'], code_end - 1) + '\n'.join(drv) + '\n')
    open(os.path.join(outdir, '%s_Data.inc' % nm), 'w').write(
        '; %s - music/SFX data $%04X-$%04X\n' % (c['title'], code_end, G.end - 1) + '\n'.join(dat) + '\n')
    return G


if __name__ == '__main__':
    g = sys.argv[1]
    G = write_game(g, sys.argv[2])
    print(g, 'end $%04X' % G.end)
