import os
# Generator: Agenda sound driver disassembly (RGBDS) for Doraemon 2 / Pokonyan
# usage: python agenda_gen.py dora2|poko > out.asm
import sys, re
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from agenda_cfg import load
from agenda_parse import Walker, fill_gaps
from agenda_align import code_of, align
import agenda_names as N

NOTE = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
HRAM = ['hSndChannel', 'hSndStructOfs', 'hSndTempo', 'hSndTempoCount', 'hSndFlags', 'hSndMarker',
        'hSndSlur', 'hSndMasterVol', 'hSndSfxChannel', 'hSndMuted', 'hSndRetrigger', 'hSndSfxId',
        'hSndSfxPriority', 'hSndMusicId', 'hSndUnused', 'hSndSfxFrame']
HRAM_DESC = ['hardware channel being processed (0-3)', 'struct offset ($00/$30/$60/$90, $C0 = SFX)',
             'frames per tick - 1', 'frame counter for the tempo', 'bits 0-3 channel on, bit 4 SFX, bit 7 no-loop',
             'last $B4 argument (read by the game)', '1 = $A4 seen in this row', 'NR50 copy ($B6)',
             'channel of the playing SFX', '1 = channel in use by the SFX: no register writes',
             '1 = write NRx4 with trigger at the end of the tick', 'last SFX id', 'priority of the playing SFX',
             'last music id', 'not used by the driver', 'SFX frame divider']
REG = {0x10: 'rNR10', 0x11: 'rNR11', 0x12: 'rNR12', 0x13: 'rNR13', 0x14: 'rNR14', 0x16: 'rNR21', 0x17: 'rNR22',
       0x18: 'rNR23', 0x19: 'rNR24', 0x1A: 'rNR30', 0x1B: 'rNR31', 0x1C: 'rNR32', 0x1D: 'rNR33', 0x1E: 'rNR34',
       0x20: 'rNR41', 0x21: 'rNR42', 0x22: 'rNR43', 0x23: 'rNR44', 0x24: 'rNR50', 0x25: 'rNR51', 0x26: 'rNR52',
       0xFF: 'rIE'}
TRK = {0x00: 'TRK_START', 0x02: 'TRK_PTR', 0x04: 'TRK_ENVBASE', 0x06: 'TRK_CALLRET', 0x08: 'TRK_LOOPPTR',
       0x0A: 'TRK_FREQ', 0x0B: 'TRK_FREQ+1', 0x0C: 'TRK_SEQTABLE', 0x0E: 'TRK_FLAGS', 0x0F: 'TRK_DEFLEN',
       0x10: 'TRK_LENGTH', 0x11: 'TRK_VOLUME', 0x12: 'TRK_DUTY', 0x13: 'TRK_PAN', 0x14: 'TRK_NOTE',
       0x15: 'TRK_TRANSPOSE', 0x16: 'TRK_DETUNE', 0x17: 'TRK_PREVNOTE', 0x18: 'TRK_GATE', 0x19: 'TRK_GATECOUNT',
       0x1A: 'TRK_LOOPCOUNT', 0x1B: 'TRK_CALLCOUNT', 0x1C: 'TRK_ENVPTR', 0x1E: 'TRK_SEQPTR', 0x20: 'TRK_SEQCOUNT',
       0x21: 'TRK_SEQVALUE', 0x22: 'TRK_ENVCOUNT', 0x23: 'TRK_ENVVALUE', 0x24: 'TRK_VIBSTEP', 0x25: 'TRK_VIBMODE',
       0x26: 'TRK_VIBDELAY', 0x27: 'TRK_VIBDELAYR', 0x28: 'TRK_VIBHALF', 0x29: 'TRK_VIBHALFR', 0x2A: 'TRK_VIBRATE',
       0x2B: 'TRK_VIBRATER', 0x2C: 'TRK_VIBDEPTH'}
CHNAME = ['ch1 (pulse+sweep)', 'ch2 (pulse)', 'ch3 (wave)', 'ch4 (noise)']


def note_name(n):
    return '%s%d' % (NOTE[n % 12], n // 12 - 1)


class Gen:
    def __init__(s, g):
        s.g = g
        s.c = c = load(g)
        s.b, s.w = c['b'], c['w']
        s.wk = fill_gaps(Walker(g).run())
        s.cc, s.code = code_of(g)
        s.out = []
        s.labels = {}      # addr -> name (global or .local)
        s.parent = {}      # addr of local -> global name owning it (filled at emission)
        s.comments = {}
        s.blocks = {}
        s.lentab = [s.b(c['len_tab'] + i) for i in range(c['len_n'])]

    # ---------------------------------------------------------------- labels
    def build_labels(s):
        c, b, w = s.c, s.b, s.w
        L = s.labels
        if s.g == 'dora2':
            m = {k: k for k in s.code}
        else:
            m = align()
        for d, n in N.GLOBALS.items():
            if d in m: L[m[d]] = n
        for d, n in N.LOCALS.items():
            if d in m: L[m[d]] = n
        for d, t in N.C.items():
            if d in m and t: s.comments[m[d]] = t
        for d, t in N.BLOCKS.items():
            if d in m: s.blocks[m[d]] = t
        if s.g == 'poko':
            L.update(N.P_GLOBALS); L.update(N.P_LOCALS)
            L[0x486E] = '.start'; L[0x4889] = '.done'
            s.blocks.update(N.P_BLOCKS)
            for k, v in N.P_C.items(): s.comments[k] = v
            # comments whose code moved
            s.comments[0x462B] = 'SFX off'
            s.comments[0x486B] = 'end it first'
            s.comments[0x486F] = 'priority'; s.comments[0x4872] = 'target channel'
            s.comments[0x487C] = 'mark the music track as SFX-owned'
            s.comments[0x4881] = 'struct 4 = the SFX'; s.comments[0x4887] = 'SFX on'
            s.comments[0x48E1] = 'stop the SFX as well (falls through from Sound_Init too)'
        # jump table entries
        for i, n in enumerate(c['jt_order']):
            for a in [a for a, x in L.items() if x == n]: del L[a]
            L[w(c['jumptab'] + 3 * i + 1)] = n
        L[c['jumptab']] = 'Sound_JumpTable'
        # unnamed code targets
        for a, (t, l, tg, k) in s.code.items():
            if tg is not None and k in ('jp', 'jpc', 'jr', 'jrc', 'call') and tg not in L:
                L[tg] = ('Snd_%04X' if k == 'call' else '.l%04X') % tg
        # driver tables
        L[c['init_regs']] = 'InitRegs'
        L[c['silent_tab']] = 'SilentSong'
        L[w(c['silent_tab'])] = 'SilentTrack'
        L[c['wavevol_tab']] = 'WaveVolTable'
        L[c['len_tab']] = 'LengthTable'
        L[c['freq_tab']] = 'FreqTable'
        L[c['cmd_tab']] = 'CommandTable'
        L[c['music_tab']] = 'MusicTable'
        L[c['sfx_tab']] = 'SfxTable'
        if c['remap']:
            L[c['remap'][0]] = 'MusicRemap'; L[c['remap'][0] + 0x20] = 'SfxRemap'
        # sound data
        wk = s.wk
        s.track_owner = {}
        for i in range(c['music_n']):
            for ch in range(4):
                a = w(c['music_tab'] + 8 * i + 2 * ch)
                if a not in L: L[a] = 'Music%02X_Ch%d' % (i, ch + 1)
        s.sfx_ids = {}
        for i in range(c['sfx_n']):
            h = w(c['sfx_tab'] + 2 * i)
            s.sfx_ids.setdefault(h, []).append(i)
            if h not in L: L[h] = 'Sfx%02X' % i
        for kind, arg in c.get('extra', []):
            if kind == 'song':
                for ch, a in enumerate(arg): L[a] = 'MusicUnused_Ch%d' % (ch + 1)
            else:
                L[arg] = 'SfxUnused_%04X' % arg
        # references from track data
        for a, (n, k, ch) in wk.rows.items():
            if k != 'cmd': continue
            op = b(a)
            if op == 0xAC:
                t = w(a + 2)
                if t not in L: L[t] = 'Sub_%04X' % t
            elif op == 0xB3:
                t = w(a + 1)
                if t not in L: L[t] = '.l%04X' % t
        names = {'env': 'Env', 'sweep': 'Sweep', 'noiseseq': 'Noise', 'kit': 'DrumKit', 'waveptr': 'WavePtr',
                 'wave': 'Wave', 'pairs': 'Pairs'}
        seen = set()
        for a in sorted(wk.region):
            kind, start, _ = wk.region[a]
            if start in seen: continue
            seen.add(start)
            if kind in names and start not in L:
                L[start] = '%s_%04X' % (names[kind], start)
        # kit bases (only the base is a label; entries are 4 bytes each)
        for k in wk.kits:
            L[k] = 'DrumKit_%04X' % k
        for a in list(L):
            if L[a].startswith('DrumKit_') and a not in wk.kits: del L[a]
        # pointer targets inside lists etc.
        for a, (n, k, ch) in wk.rows.items():
            if k == 'cmd' and b(a) in (0xA8, 0xAB, 0xAD):
                t = w(a + 1)
                if t not in L: L[t] = '%s_%04X' % ('Env' if b(a) == 0xA8 else 'Seq', t)

    def ref(s, addr, scope):
        n = s.labels[addr]
        if n.startswith('.'):
            p = s.parent.get(addr)
            if p is None:
                # find owning global: last global label below addr
                gl = [a for a, x in s.labels.items() if not x.startswith('.') and a <= addr]
                p = s.labels[max(gl)]
            if p != scope: return p + n
        return n

    # ---------------------------------------------------------------- output
    def emit(s, line=''):
        s.out.append(line)

    def comment_pad(s, text, com, addr=None):
        t = '    ' + text
        tail = []
        if com: tail.append(com)
        if addr is not None:
            t = (t.ljust(36) if len(t) < 36 else t + ' ') + '; $%04X' % addr + ((' ' + '; '.join(tail)) if tail else '')
        elif tail:
            t = (t.ljust(36) if len(t) < 36 else t + ' ') + '; ' + '; '.join(tail)
        return t

    def put_label(s, a):
        if a in s.labels:
            n = s.labels[a]
            if n.startswith('.'):
                s.parent[a] = s.scope
                s.emit(n)
            else:
                s.scope = n
                exported = n.startswith('Sound_')
                s.emit(n + ('::' if exported else ':'))

    def operand(s, a, t, l, tg, k):
        c = s.c
        hb = c['hram'] & 0xFF
        # branch targets
        if tg is not None and k in ('jp', 'jpc', 'jr', 'jrc', 'call'):
            return re.sub(r'\$[0-9A-F]{4}$', s.ref(tg, s.scope), t)
        def hsub(m):
            v = int(m.group(1), 16)
            lo = v & 0xFF
            if 0xFF00 <= v and hb <= lo < hb + 16: return HRAM[lo - hb]
            if 0xFF00 <= v and lo in REG: return REG[lo]
            return m.group(0)
        if t.startswith('ldh'):
            return re.sub(r'\$([0-9A-F]{4})', hsub, t)
        m = re.match(r'ld (hl|de|bc),\$([0-9A-F]{4})$', t)
        if m:
            v = int(m.group(2), 16)
            if v in s.labels and 0x4000 <= v < 0x8000 and not s.labels[v].startswith('.'):
                return 'ld %s,%s' % (m.group(1), s.labels[v])
            if v == c['wram']: return 'ld %s,wSndTracks' % m.group(1)
            if v == c['save_wram']: return 'ld %s,wSndSave' % m.group(1)
            if v == c['save_wram'] + 0xF0: return 'ld %s,wSndSaveHram' % m.group(1)
            if 0xFF00 <= v and hb <= (v & 0xFF) < hb + 16: return 'ld %s,%s' % (m.group(1), HRAM[(v & 0xFF) - hb])
            return t
        m = re.match(r'ld l,\$([0-9A-F]{2})$', t)
        if m and int(m.group(1), 16) in TRK: return 'ld l,' + TRK[int(m.group(1), 16)]
        if t == 'ld h,$%02X' % (c['wram'] >> 8): return 'ld h,HIGH(wSndTracks)'
        return t

    def code_range(s, lo, hi):
        a = lo
        while a < hi:
            if a in s.blocks:
                s.emit()
                for x in s.blocks[a]: s.emit('; ' + x)
            s.put_label(a)
            t, l, tg, k = s.code[a]
            txt = s.operand(a, t, l, tg, k)
            s.emit(s.comment_pad(txt, s.comments.get(a), a))
            a += l

    # ---------------------------------------------------------------- data rows
    def row_text(s, a, ch, is_sfx):
        b, w, c = s.b, s.w, s.c
        op = b(a)
        if op < 0x80:
            n = s.wk.rows[a][0]
            bytes_ = [op] + ([b(a + 1)] if n == 2 else [])
            if op == c['rest']: what = 'rest'
            elif ch == 3: what = 'drum %d' % ((op - 0x0A) & 7)
            elif op < 0x24: what = 'note $%02X (period 0)' % op
            else: what = note_name(op)
            if n == 2:
                li = b(a + 1) - 0x80
                if li < len(s.lentab): what += ', %d' % s.lentab[li]
                else: what += ', length $%02X (past LengthTable)' % b(a + 1)
            return ['db ' + ', '.join('$%02X' % x for x in bytes_)], what
        args = [b(a + 1 + i) for i in range(s.wk.rows[a][0] - 1)]
        db = lambda *x: 'db ' + ', '.join('$%02X' % v for v in x)
        if op == 0xA0: return [db(op)], 'end' + ('' if is_sfx else ' (loop to start; stop if $A2)')
        if op == 0xA1: return [db(op)], 'loop mode on'
        if op == 0xA2: return [db(op)], 'loop mode off: tracks stop at $A0'
        if op == 0xA3: return [db(op)], 'loop start'
        if op == 0xA4: return [db(op)], 'slur into the next note'
        if op == 0xA5:
            li = args[0] - 0x80
            v = s.lentab[li] if 0 <= li < len(s.lentab) else None
            return [db(op, *args)], 'default length %s' % (v if v is not None else '?')
        if op == 0xA6:
            if ch == 2:
                lv = s.b(c['wavevol_tab'] + (args[0] & 0xFF)) if args[0] < 16 else None
                return [db(op, *args)], 'volume %d (NR32 $%02X)' % (args[0], lv) if lv is not None else 'volume %d' % args[0]
            return [db(op, *args)], 'volume %d' % args[0]
        if op == 0xA7: return [db(op, *args)], 'pan ' + {1: 'right', 2: 'left'}.get(args[0] & 3, 'centre')
        if op == 0xA8: return [db(op), 'dw ' + s.ref(w(a + 1), s.scope)], 'envelope'
        if op == 0xA9: return [db(op, *args)], 'loop end: %d passes' % args[0] + (' (endless)' if args[0] == 0xFF else '')
        if op == 0xAA: return [db(op, *args)], 'duty %s' % ['12.5%', '25%', '50%', '75%'][args[0] & 3]
        if op in (0xAB, 0xAD):
            kind = {0: 'sweep list', 3: 'drum kit'}.get(ch, 'table (no effect on this channel)')
            return [db(op), 'dw ' + s.ref(w(a + 1), s.scope)], kind
        if op == 0xAC: return [db(op, args[0]), 'dw ' + s.ref(w(a + 2), s.scope)], 'call %d time%s' % (args[0], '' if args[0] == 1 else 's')
        if op == 0xAE: return [db(op, args[0]), 'dw ' + s.ref(w(a + 2), s.scope)], 'wave (first byte unused)'
        if op == 0xAF: return [db(op, *args)], 'tempo: %d frame%s per tick' % (args[0] + 1, '' if args[0] == 0 else 's')
        if op == 0xB0: return [db(op, *args)], 'detune %+d' % (args[0] - 256 if args[0] > 127 else args[0])
        if op == 0xB1: return [db(op, *args)], 'transpose %+d' % (args[0] - 256 if args[0] > 127 else args[0])
        if op == 0xB2: return [db(op, *args)], 'gate %s' % ('off' if (args[0] & 7) == 0 else '%d/8' % (args[0] & 7))
        if op == 0xB3: return [db(op), 'dw ' + s.ref(w(a + 1), s.scope)], 'jump'
        if op == 0xB4: return [db(op, *args)], 'marker $%02X' % args[0]
        if op == 0xB5: return [db(op)], 'return'
        if op == 0xB6: return [db(op, *args)], 'master volume (NR50 $%02X)' % args[0]
        if op == 0xB7:
            mode = args[0] >> 6
            return [db(op, *args)], 'vibrato: %s, step %d, delay %d, rate %d, half %d' % (
                ['off', 'triangle', 'slide down', 'slide up'][mode], args[0] & 0x3F, args[1], args[2], args[3])
        return [db(op)], 'invalid command'

    def data_range(s, lo, hi):
        b, w, c = s.b, s.w, s.c
        wk = s.wk
        a = lo
        cur_ch, cur_sfx = 0, False
        while a < hi:
            s.put_label(a)
            kind = wk.region[a][0] if a in wk.region else None
            if kind == 'musictab':
                for i in range(c['music_n']):
                    p = [w(a + 2 * k) for k in range(4)]
                    s.emit(s.comment_pad('dw ' + ', '.join(s.ref(x, s.scope) for x in p), '$%02X' % i))
                    a += 8
                continue
            if kind == 'sfxtab':
                for i in range(c['sfx_n']):
                    s.emit(s.comment_pad('dw ' + s.ref(w(a), s.scope), '$%02X' % i)); a += 2
                continue
            if kind == 'sfxhdr':
                ch, pr = b(a), b(a + 1)
                ids = s.sfx_ids.get(a)
                hdr = 'SFX %s' % (', '.join('$%02X' % i for i in ids) if ids else '(unreferenced)')
                s.emit(s.comment_pad('db $%02X, $%02X' % (ch, pr), '%s: %s, priority %d' % (hdr, CHNAME[ch & 3], pr)))
                cur_ch, cur_sfx = ch, True
                a += 2
                continue
            if kind in ('track', 'deadend'):
                if a in s.track_ch: cur_ch, cur_sfx = s.track_ch[a]
                if kind == 'deadend':
                    s.emit(s.comment_pad('db $A0', 'end (never reached)')); a += 1; continue
                n, k, ch = wk.rows[a]
                lines, com = s.row_text(a, cur_ch, cur_sfx)
                for i, ln in enumerate(lines):
                    s.emit(s.comment_pad(ln, com if i == 0 else None))
                a += n
                continue
            if kind in ('env', 'sweep', 'noiseseq', 'pairs'):
                v, d = b(a), b(a + 1)
                if kind == 'env': vt = 'NRx2 $%02X' % v
                elif kind == 'sweep': vt = 'NR10 $%02X' % v
                elif kind == 'noiseseq': vt = 'NR43 $%02X' % v
                else: vt = 'value $%02X' % v
                dt = {0xFE: 'restart', 0xFF: 'stop'}.get(d, '%d tick%s' % (d, '' if d == 1 else 's'))
                if d >= 0xFE: com = dt
                else: com = '%s, %s' % (vt, dt)
                if kind == 'pairs' and a == wk.region[a][1]: com += '  (unreferenced)'
                s.emit(s.comment_pad('db $%02X, $%02X' % (v, d), com))
                a += 2
                continue
            if kind == 'kit':
                base = max(k for k in wk.kits if k <= a)
                s.emit(s.comment_pad('dw %s, %s' % (s.ref(w(a), s.scope), s.ref(w(a + 2), s.scope)),
                                     'drum %d: noise list, envelope (note $%02X)' % ((a - base) // 4, 0x0A + (a - base) // 4)))
                a += 4
                continue
            if kind == 'waveptr':
                s.emit(s.comment_pad('dw ' + s.ref(w(a), s.scope), None))
                s.emit(s.comment_pad('db $%02X, $%02X' % (b(a + 2), b(a + 3)), 'not read by the driver'))
                a += 4
                continue
            if kind == 'wave':
                s.emit(s.comment_pad('db ' + ', '.join('$%02X' % b(a + i) for i in range(16)), None))
                a += 16
                continue
            # raw
            e = a + 1
            while e < hi and e not in s.labels and wk.region.get(e, (None, None))[1] == wk.region.get(a, (None, None))[1]: e += 1
            for x in range(a, e, 16):
                s.emit(s.comment_pad('db ' + ', '.join('$%02X' % b(y) for y in range(x, min(e, x + 16))), None))
            a = e

    # ---------------------------------------------------------------- whole file
    def run(s):
        c, b, w = s.c, s.b, s.w
        s.build_labels()
        s.scope = None
        # channel/sfx context at track starts
        s.track_ch = {}
        for (a, ch), own in s.wk.tracks.items():
            sfx = own[0] in ('S', 'US')
            s.track_ch.setdefault(a, (ch, sfx))
        E = s.emit
        game = c['name']
        E('; ' + '=' * 76)
        E('; %s - sound driver (Agenda) and sound data' % game)
        E('; ROM bank %d, $%04X-$%04X. Generated by tools/agenda_gen.py; reassembles' % (c['bank'], c['start'], c['end'] - 1))
        E('; byte-identical with RGBDS 1.0.0. See Agenda_SoundDriver.md for the format.')
        E('; ' + '=' * 76)
        E()
        E('INCLUDE "agenda_sound.inc"')
        E()
        E('; ---- HRAM ----')
        for i, n in enumerate(HRAM):
            E('DEF %-16s EQU $%04X ; %s' % (n, c['hram'] + i, HRAM_DESC[i]))
        E()
        E('; ---- WRAM ----')
        E('DEF wSndTracks      EQU $%04X ; 5 track structs of TRK_SIZEOF: ch1-ch4, SFX' % c['wram'])
        E('DEF wSndSave        EQU $%04X ; copy of wSndTracks (Sound_SaveMusic)' % c['save_wram'])
        E('DEF wSndSaveHram    EQU $%04X ; copy of the 16 HRAM bytes' % (c['save_wram'] + 0xF0))
        E()
        E('SECTION "Sound driver", ROMX[$4000], BANK[%d]' % c['bank'])
        E()
        if s.g == 'dora2':
            hdr = [(0x4000, 0x4015, 'code'), (0x4015, 0x4020, 'pad'), (0x4020, 0x405F, 'remap'), (0x405F, 0x40D3, 'code')]
        else:
            hdr = [(0x4000, 0x4002, 'bankid'), (0x4002, 0x4017, 'code'), (0x4017, 0x4018, 'zero'), (0x4018, 0x4080, 'pad'),
                   (0x4080, 0x40F4, 'code')]
        for lo, hi, k in hdr:
            if k == 'code':
                if lo == c['jumptab']:
                    if lo != 0x4000: E()
                    E('; Jump table, called from bank 0.')
                    for i, n in enumerate(c['jt_order']):
                        a = lo + 3 * i
                        if a == lo: s.put_label(a)
                        E(s.comment_pad('jp ' + n, None, a))
                else:
                    s.code_range(lo, hi)
            elif k == 'pad':
                E(); E(s.comment_pad('ds $%02X, $FF' % (hi - lo), 'unused'))
            elif k == 'bankid':
                E(s.comment_pad('db $%02X, $%02X' % (b(lo), b(lo + 1)), 'bank number (every bank of this ROM starts with it twice)'))
            elif k == 'zero':
                E(s.comment_pad('db $%02X' % b(lo), 'unused'))
            elif k == 'remap':
                E()
                E('; Id remap tables. Not used by the driver: bank-0 code reads them when')
                E('; [$D128] != 0 (music) or [$FFBA] = 1 (SFX) and plays the id found here.')
                s.put_label(lo)
                for x in range(lo, lo + 0x20, 8):
                    E(s.comment_pad('db ' + ', '.join('$%02X' % b(y) for y in range(x, x + 8)), 'music $%02X-$%02X' % (x - lo, x - lo + 7)))
                s.put_label(lo + 0x20)
                for x in range(lo + 0x20, hi, 8):
                    e = min(hi, x + 8)
                    E(s.comment_pad('db ' + ', '.join('$%02X' % b(y) for y in range(x, e)), 'SFX $%02X-$%02X' % (x - lo - 0x20, e - lo - 0x21)))
        # driver tables
        E()
        E('; Register values written by Sound_Init to NR10-NR23 ($FF10-$FF23)')
        s.put_label(c['init_regs'])
        for x in range(c['init_regs'], c['init_regs'] + 20, 5):
            E(s.comment_pad('db ' + ', '.join('$%02X' % b(y) for y in range(x, x + 5)), None))
        E()
        E('; Sound_StopMusic: the silent song (4 x the same track)')
        s.put_label(c['silent_tab'])
        E(s.comment_pad('dw ' + ', '.join(s.ref(w(c['silent_tab'] + 2 * i), s.scope) for i in range(4)), None))
        a = w(c['silent_tab'])
        s.track_ch[a] = (0, False)
        sil_end = c['wavevol_tab']
        s.data_range(a, sil_end)
        E()
        E('; $A6 on ch3: volume 0-15 -> NR32 output level')
        s.put_label(c['wavevol_tab'])
        E(s.comment_pad('db ' + ', '.join('$%02X' % b(c['wavevol_tab'] + i) for i in range(16)), None))
        E()
        E('; Length codes $80-$%02X (ticks)' % (0x80 + c['len_n'] - 1))
        s.put_label(c['len_tab'])
        for i in range(c['len_n']):
            E(s.comment_pad('db %d' % b(c['len_tab'] + i), '$%02X' % (0x80 + i)))
        E()
        E('; Periods for notes $24 (C2) and up')
        s.put_label(c['freq_tab'])
        for i in range(c['freq_n']):
            E(s.comment_pad('dw $%04X' % w(c['freq_tab'] + 2 * i), 'note $%02X %s' % (0x24 + i, note_name(0x24 + i))))
        E()
        E('; Commands $A0-$B7')
        s.put_label(c['cmd_tab'])
        for i in range(24):
            E(s.comment_pad('dw ' + s.ref(w(c['cmd_tab'] + 2 * i), s.scope), '$%02X' % (0xA0 + i)))
        code_lo = c['cmd_tab'] + 48
        s.code_range(code_lo, c['music_tab'])
        E()
        E('; ' + '=' * 76)
        E('; Sound data')
        E('; ' + '=' * 76)
        E()
        E('; MusicTable: 4 track pointers (ch1-ch4) per song')
        s.data_range(c['music_tab'], c['end'])
        return '\n'.join(s.out) + '\n'


if __name__ == '__main__':
    sys.stdout.write(Gen(sys.argv[1]).run())
