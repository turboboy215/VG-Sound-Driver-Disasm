#!/usr/bin/env python3
"""Animorphs (GBC) sound-driver data walker (Jeremy Evers' Fatass tracker player).
Usage: faparse.py ROM [--json out.json] > SongData.txt"""
import sys, json
ROM = open(sys.argv[1], 'rb').read()
def rb(bank, addr): return ROM[bank*0x4000 + addr - 0x4000]
def rw(bank, addr): return rb(bank, addr) | rb(bank, addr+1) << 8
SONGTAB, BANKTAB, NSONGS = 0x7480, 0x74A8, 20
CHN = ['CH1', 'CH2', 'CH3', 'CH4']
NOTE = ['C','C#','D','D#','E','F','F#','G','G#','A','A#','B']
def notename(n):  # note 1 = C2
    n -= 1; return '%s%d' % (NOTE[n % 12], 2 + n // 12)
# command name, arg count (as read by the driver for the channel that executes it)
CMDS = {0xD3:('macro',2),0xD4:('auto_pwm',2),0xD5:('auto_pan',2),0xD6:('wave_dist',1),0xD7:('wave_mix',2),
 0xD8:('stop_sample',0),0xD9:('reset_vib',0),0xDA:('wave_preset',1),0xDB:('fine_tune',1),0xDC:('play_sample',1),
 0xDD:('arpeggio',3),0xDE:('glissando',1),0xDF:('porta_src',1),0xE0:('porta_rate',1),0xE1:('vibrato',2),
 0xE2:('restart_env',0),0xE3:('retrig_delay',1),0xE4:('trig_delay',1),0xE5:('use_duration',1),0xE6:('sweep',1),
 0xE7:('env_volume',1),0xE8:('env_rate',1),0xE9:('duration',1),0xEA:('duty',1),0xFB:('pan',1),0xFC:('shuffle',2),
 0xFD:('transpose',1),0xFE:('speed',1),0xFF:('end',0)}
def argcount(cmd, ch):
    """bytes actually consumed after the command byte on channel ch (0-3)"""
    if cmd == 0xD4 and ch >= 2: return 1     # driver skips only 1 of 2 args (quirk)
    if cmd == 0xD6 and ch != 2: return 2     # driver skips 2 for a 1-arg cmd (quirk)
    return CMDS.get(cmd, (None, 0))[1]

def walk_stream(bank, addr, ch, ptbase, macros, cov, tag):
    """Decode one channel stream until FF. Returns list of (addr, bytes, text) and row count."""
    ev = []; rows = 0; a = addr
    while True:
        b = rb(bank, a)
        if b == 0x00:
            ev.append((a, [b], 'off')); a += 1; rows += 1; continue
        if b < 0x80:
            if ch == 3:
                n = b & 0x3F; ev.append((a, [b], 'noise %d%s' % (n, ',7bit' if b & 0x40 else ''))); rows += 1
            elif b <= 0x48:
                ev.append((a, [b], 'note %s' % notename(b))); rows += 1
            else:
                ev.append((a, [b], 'empty_row $%02X' % b)); rows += 1
            a += 1; continue
        if b < 0xC0:
            n = b & 0x3F; ev.append((a, [b], 'wait %d' % n)); rows += 1 + n; a += 1; continue
        name, _ = CMDS.get(b, ('nop_$%02X' % b, 0))
        n = argcount(b, ch)
        args = [rb(bank, a+1+i) for i in range(n)]
        if b == 0xFF:
            ev.append((a, [b], 'end')); a += 1; break
        if b == 0xD3:
            off = args[0] | args[1] << 8; tgt = ptbase + off
            macros.setdefault((tgt, ch), None)
            ev.append((a, [b]+args, 'macro $%04X' % tgt))
        else:
            if b == 0xDF: txt = 'porta_src %s' % notename(args[0])
            elif b == 0xFD: txt = 'transpose %+d' % ((args[0] ^ 0x80) - 0x80)
            else: txt = ('%s %s' % (name, ','.join('$%02X' % x for x in args))).rstrip()
            ev.append((a, [b]+args, txt))
        a += 1 + n
    for x in range(addr, a): cov.add(x)
    return ev, rows

def parse_song(i):
    bank = rb(9, BANKTAB + i); start = rw(9, SONGTAB + 2*i)
    seqoff = rw(bank, start); ptoff = rw(bank, start+2)
    seq = start + seqoff; pt = start + ptoff
    cov = set(range(start, start+4))
    # name block: 3 bytes + text + $FF (between header and sequence)
    nb = [rb(bank, x) for x in range(start+4, seq)]
    for x in range(start+4, seq): cov.add(x)
    import re as _re
    s = {'num': i, 'bank': bank, 'start': start, 'seq': seq, 'pt': pt, 'hdrlen': rw(bank, start+4),
         'hdrnpat': rb(bank, start+6),
         'name': _re.split(rb'[\x00\xff]', bytes(nb[3:]))[0].decode('latin1'), 'namebytes': nb[3:]}
    # sequence
    items = []; a = seq; pats = []
    while True:
        b = rb(bank, a)
        if b == 0xFB: items.append((a, [b, rb(bank,a+1)], 'pan $%02X' % rb(bank,a+1))); a += 2
        elif b == 0xFC: items.append((a, [b, rb(bank,a+1), rb(bank,a+2)], 'shuffle $%02X,$%02X' % (rb(bank,a+1), rb(bank,a+2)))); a += 3
        elif b == 0xFD: items.append((a, [b, rb(bank,a+1)], 'song_transpose %d' % ((rb(bank,a+1)^0x80)-0x80))); a += 2
        elif b == 0xFE: items.append((a, [b, rb(bank,a+1)], 'speed $%02X' % rb(bank,a+1))); a += 2
        elif b == 0xFF: items.append((a, [b], 'loop')); a += 1; break
        else: items.append((a, [b], 'pattern %d' % b)); pats.append(b); a += 1
    for x in range(seq, a): cov.add(x)
    s['seqitems'] = items; s['seqend'] = a
    npat = max(pats) + 1 if pats else 0
    s['npat'] = npat
    for x in range(pt, pt + 8*npat): cov.add(x)
    macros = {}
    s['patterns'] = []
    for p in range(npat):
        chs = []
        for c in range(4):
            ptr = pt + rw(bank, pt + 8*p + 2*c)
            ev, rows = walk_stream(bank, ptr, c, pt, macros, cov, 'p%d' % p)
            chs.append({'addr': ptr, 'events': ev, 'rows': rows})
        s['patterns'].append({'num': p, 'used': p in pats, 'ch': chs})
    s['macros'] = []
    done = set()
    while True:
        todo = [k for k in macros if k not in done]
        if not todo: break
        for k in todo:
            done.add(k)
            ev, rows = walk_stream(bank, k[0], k[1], pt, macros, cov, 'm')
            s['macros'].append({'addr': k[0], 'ch': k[1], 'events': ev, 'rows': rows})
    s['cov'] = cov
    s['lo'] = min(cov); s['hi'] = max(cov)
    return s

def row_lines(events, played):
    """Group events into rows: 'rr  NOTE  commands' (rows past the played length are marked)."""
    out = []; row = 0; cmds = []
    for a, b, t in events:
        k = t.split()[0]
        if k in ('note', 'noise', 'off', 'empty_row', 'wait'):
            if k == 'wait':
                n = int(t.split()[1]); cell = '...'
                span = 1 + n
            else:
                cell = {'note': lambda: t[5:], 'noise': lambda: 'N' + t[6:], 'off': lambda: 'OFF',
                        'empty_row': lambda: '---'}[k](); span = 1
            mark = '' if row < played else '  (not reached)'
            line = '%3d  %-9s %s' % (row, cell, ', '.join(cmds))
            if k == 'wait': line = '%3d  %-9s %s' % (row, '(%d)' % span if not cmds else '(%d)' % span, ', '.join(cmds))
            out.append(line.rstrip() + mark)
            row += span; cmds = []
        elif k == 'end':
            out.append('%3d  end%s' % (row, '' if not cmds else '  ' + ', '.join(cmds)))
        else:
            cmds.append(t)
    return out

def main():
    songs = [parse_song(i) for i in range(NSONGS)]
    out = []
    P = out.append
    P('Animorphs (GBC) - F.A. tracker player song data')
    P('Generated by tools/faparse.py from "Animorphs (E) (M5) [C][!].gbc"')
    P('Note numbering: note 1 = C2 (period table bank $0A). Updates run at ~29.9 Hz (every other VBlank);')
    P('with no shuffle a row happens every 256/(2*speed) updates, i.e. speed*0.2333 rows/s.')
    P('Row lines: "row  cell  commands". cell = note (C2-B7), Nn / Nn,7bit (noise index, CH4), OFF (note off),')
    P('--- (empty row), or (n) = n rows with no new note (a wait, $80+n-1). A pattern ends when its shortest stream')
    P('reaches FF; rows after that are marked "(not reached)".')
    P('')
    P('== Song table (bank 9 $7480 pointers, $74A8 banks) ==')
    for s in songs:
        P('%2d  %02X:%04X-%04X  seq %04X  pattab %04X  %2d patterns %2d macros  header len $%04X%s npat %d%s  name "%s"' % (
            s['num'], s['bank'], s['lo'], s['hi'], s['seq'], s['pt'], s['npat'], len(s['macros']),
            s['hdrlen'], '' if s['hdrlen'] == s['hi'] - s['lo'] + 1 else '(!)', s['hdrnpat'],
            '' if s['hdrnpat'] == s['npat'] else '(!)', s['name']))
    for s in songs:
        P(''); P('=' * 78)
        P('Song %d  bank %02X  start %04X  "%s"' % (s['num'], s['bank'], s['start'], s['name']))
        P('=' * 78)
        P('Sequence @%04X:' % s['seq'])
        P('  ' + ' | '.join(t for _, _, t in s['seqitems']))
        for p in s['patterns']:
            P('')
            rl = [c['rows'] for c in p['ch']]
            P('-- Pattern %d%s: plays %d rows (stream lengths %s)' % (p['num'], '' if p['used'] else ' [UNUSED by sequence]',
                                             min(rl), '/'.join(str(x) for x in rl)))
            for c, ch in enumerate(p['ch']):
                P('  %s @%04X' % (CHN[c], ch['addr']))
                for line in row_lines(ch['events'], min(rl)): P('    ' + line)
        for m in s['macros']:  # (no song uses macros; kept for completeness)
            P('')
            P('-- Macro @%04X (called from %s, %d rows): %s' % (m['addr'], CHN[m['ch']], m['rows'],
                                                             '; '.join(t for _, _, t in m['events'])))
    # coverage per bank
    P(''); P('== Coverage ==')
    bybank = {}
    for s in songs: bybank.setdefault(s['bank'], set()).update(s['cov'])
    for b in sorted(bybank):
        cov = sorted(bybank[b]); runs = []; st = cov[0]; pv = st
        for x in cov[1:]:
            if x != pv + 1: runs.append((st, pv)); st = x
            pv = x
        runs.append((st, pv))
        P('bank %02X: %s' % (b, ', '.join('%04X-%04X' % r for r in runs)))
    print('\n'.join(out))
    if '--json' in sys.argv:
        js = []
        for s in songs:
            t = dict(s); t['cov'] = sorted(s['cov']); js.append(t)
        json.dump(js, open(sys.argv[sys.argv.index('--json')+1], 'w'))
if __name__ == '__main__': main()
