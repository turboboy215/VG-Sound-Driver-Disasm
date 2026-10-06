#!/usr/bin/env python3
"""
ts_extract.py - dump songs from SPCs using the Toy Story (SNES) sound driver
(Allister Brimble's event-list driver, code $0200-$13F8).

Usage:  python3 ts_extract.py file.spc [--base XXXX] [--events N] [--no-events]

Prints: ID666 tags, driver state, song header, every track's event list
(4-byte events, 48 ticks per quarter at multiplier 1), loop lengths,
the programs/regions the song uses, the samples and pitch envelopes.
"""
import sys, argparse

NOTE = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
def nname(n):
    return '%s%d' % (NOTE[n % 12], n // 12 - 1)          # MIDI convention, 60 = C4

# per-region tables, 128 entries each, column-major ($80 stride from $15F9)
REGION_COLS = [
    (0x15F9, 'kdelay', 'key-on delay (frames)'),
    (0x1679, 'fine',   'fine tune (1/256 semitone)'),
    (0x16F9, 'xpose',  'transpose (semitones, signed)'),
    (0x1779, 'klo',    'key range low'),
    (0x17F9, 'khi',    'key range high'),
    (0x1879, 'smp',    'sample # (bit7 = synth wave)'),
    (0x18F9, 'syn1',   'synth param 1 (PWM step / noise mask)'),
    (0x1979, 'syn2',   'synth param 2 (PWM limit)'),
    (0x19F9, 'penv',   'pitch envelope # (bit7 = none)'),
    (0x1A79, 'poly*',  '(program) default polyphony'),
    (0x1AF9, 'prio*',  '(program) default priority'),
    (0x1B79, 'adsr1',  'ADSR1 (bit7 forced on)'),
    (0x1BF9, 'adsr2',  'ADSR2'),
    (0x1C79, 'rel',    'release GAIN rate (mode $A0 = exp. decrease)'),
    (0x1CF9, 'vsens',  'velocity sensitivity (signed)'),
    (0x1D79, 'pan',    'pan (bit7 = auto-pan mode n&15)'),
    (0x1DF9, 'vol',    'volume'),
    (0x1E79, 'next',   'next region in chain (bit7 = end)'),
]

CTRL = {
    0x80: 'LoopEnd',    0x82: 'LoopStart', 0x83: 'Volume',  0x84: 'Tempo',
    0x85: 'Program',    0x86: 'Polyphony', 0x87: 'Glide',   0x88: 'Priority',
    0x89: 'Pan',        0x8A: 'PitchEnvEnable',
}

def s8(v): return v - 256 if v >= 128 else v

class SPC:
    def __init__(self, path):
        d = open(path, 'rb').read()
        if not d.startswith(b'SNES-SPC700 Sound File Data'):
            raise SystemExit('not an SPC file')
        self.raw = d
        self.ram = d[0x100:0x10100]
        self.dsp = d[0x10100:0x10180]
    def b(self, a): return self.ram[a & 0xFFFF]
    def w(self, a): return self.ram[a & 0xFFFF] | self.ram[(a + 1) & 0xFFFF] << 8
    def tags(self):
        d = self.raw
        f = lambda a, n: d[a:a + n].split(b'\0')[0].decode('latin1').strip()
        return dict(song=f(0x2E, 32), game=f(0x4E, 32), dumper=f(0x6E, 16),
                    comment=f(0x7E, 32), length=f(0xA9, 3), fade=f(0xAC, 5),
                    artist=f(0xB1, 32))

SIGNATURE = bytes.fromhex('8F 07 1E F8 1E F5 39 1F'.replace(' ', ''))   # SeqTick @ $0675

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('spc')
    ap.add_argument('--base', help='song base address (hex); default = $27/$28')
    ap.add_argument('--events', type=int, default=100000, help='max events per track')
    ap.add_argument('--no-events', action='store_true')
    a = ap.parse_args()
    s = SPC(a.spc)
    if s.ram[0x0675:0x0675 + len(SIGNATURE)] != SIGNATURE:
        print('WARNING: driver signature not found at $0675 - different build?')
    t = s.tags()
    print('=== %s - %s ===' % (t['game'], t['song']))
    print('artist: %s | dumper: %s | ID666 length %s s, fade %s ms' % (t['artist'], t['dumper'], t['length'], t['fade']))

    base = int(a.base, 16) if a.base else s.w(0x27)
    fa = s.ram[0xFA]; mult = s.b(0x50)
    tick_ms = fa * 0.125
    print('\n-- driver state --')
    print('song base $%04X | upload ptr $%04X | mark $%04X | clock $%04X' % (base, s.w(0x14), s.w(0x16), s.w(0x2B)))
    print('timer0 target $%02X -> %.3f ms/tick (~%.1f BPM) | clock multiplier $50=%d | stereo $51=%d | master vol $19=$%02X'
          % (fa, tick_ms, (10000 / fa) if fa else 0, mult, s.b(0x51), s.b(0x19)))

    offs = [s.w(base + 2 * i) for i in range(16)]
    print('\n-- song header (16 track offsets, relative to base) --')
    print(' '.join('%04X' % o for o in offs))

    progs = set(); tempo_bpm = None; loops = {}
    for tr, o in enumerate(offs):
        if not o:
            continue
        p = base + o
        delay = s.b(p); p += 1
        time = delay; loop_t = None; loop_p = None; ev = 0; prog = None
        lines = []
        while ev < a.events:
            c, v1, v2, dl = s.b(p), s.b(p + 1), s.b(p + 2), s.b(p + 3)
            at = time
            if c == 0x00:
                txt = 'Wait      +%d*256' % v1
                time += v1 * 256
            elif c < 0x80:
                if v1 == 0:
                    txt = 'NoteOff   %-4s (%d)' % (nname(c), c)
                else:
                    txt = 'Note      %-4s (%3d) vel %3d dur %3d' % (nname(c), c, v1, v2)
            else:
                name = CTRL.get(c, 'Ignored$%02X' % c)
                txt = '%-9s %d' % (name, v1)
                if c == 0x85:
                    progs.add(v1); prog = v1
                if c == 0x84 and v1:
                    tempo_bpm = v1
                    txt += '  (timer0 = %d -> %.3f ms/tick)' % (10000 // v1, (10000 // v1) * 0.125)
                if c == 0x82:
                    loop_t, loop_p = time, p
                if c == 0x80:
                    txt += '  -> loop to $%04X' % loop_p if loop_p else '  (track end)'
            if c == 0x80 and loop_p:
                # a taken LoopEnd never reads its own delta: the driver jumps back and
                # re-reads the LoopStart event's delta instead
                lines.append('  %04X  t=%6d  bar %3d.%-5s  %-60s (+%d ignored)' % (p, at, at // 192 + 1, '%.2f' % ((at % 192) / 48 + 1), txt, dl))
                p += 4; ev += 1
                break
            lines.append('  %04X  t=%6d  bar %3d.%-5s  %-60s +%d' % (p, at, at // 192 + 1, '%.2f' % ((at % 192) / 48 + 1), txt, dl))
            time += dl; p += 4; ev += 1
            if c == 0x80:
                break
        loops[tr] = (loop_t, time)
        print('\n-- track %d @ $%04X  initial delay %d --' % (tr, base + o, delay))
        if not a.no_events:
            print('\n'.join(lines))
        if loop_t is not None:
            print('  loop: start t=%d, end t=%d, loop length %d ticks' % (loop_t, time, time - loop_t))
        else:
            print('  no loop; ends at t=%d' % time)

    print('\n-- timing summary --')
    lens = {tr: e - (st or 0) for tr, (st, e) in loops.items()}
    for tr, (st, e) in loops.items():
        print('  track %2d: intro %5d  loop %6d ticks' % (tr, st or 0, e - (st or 0)))
    if lens:
        L = max(lens.values())
        print('  longest loop %d ticks = %.2f quarter notes = %.3f s at %.3f ms/tick (multiplier %d)'
              % (L, L / 48, L * tick_ms / 1000 / max(mult, 1), tick_ms, mult))

    # programs -> region chains
    print('\n-- programs (region chains) --')
    hdr = ' '.join('%6s' % c[1] for c in REGION_COLS)
    print('  prog rgn ' + hdr)
    used_smp = set(); used_env = set()
    for pg in sorted(progs):
        r = pg; seen = set()
        while r < 0x80 and r not in seen:
            seen.add(r)
            vals = [s.b(c[0] + r) for c in REGION_COLS]
            print('  %4d %3d ' % (pg, r) + ' '.join('    %02X' % v for v in vals)
                  + '   keys %s-%s' % (nname(vals[3]), nname(vals[4])))
            if vals[5] < 0x80: used_smp.add(vals[5])
            else: used_smp.add(vals[5])
            if vals[8] < 0x80: used_env.add(vals[8])
            r = vals[17]
    print('\n  columns:')
    for c in REGION_COLS:
        print('    %-6s $%04X  %s' % (c[1], c[0], c[2]))

    print('\n-- samples --')
    for n in sorted(used_smp):
        if n & 0x80:
            k = n & 0x1F
            print('  $%02X: synth wave %d, type %d, BRR header select %d' % (n, k, k, (n >> 5) & 3))
            continue
        p = s.b(0x14F9 + n) | s.b(0x1579 + n) << 8
        lo, hi, lofs = s.b(p), s.b(p + 1), s.w(p + 2)
        start = p + 4; q = start
        while True:
            h = s.b(q); q += 9
            if h & 1 or q > 0xFFF0: break
        loops_ = bool(h & 2)
        print('  %3d: hdr $%04X  BRR $%04X-$%04X (%d blocks)  tune %+d.%03d  %s'
              % (n, p, start, q - 1, (q - start) // 9, s8(hi), lo,
                 'loop @ $%04X' % (start + lofs) if loops_ else 'one-shot'))

    print('\n-- pitch envelopes --')
    for e in sorted(used_env):
        p = s.b(0x1FD9 + e) | s.b(0x2019 + e) << 8
        end, loop = s.b(p), s.b(p + 2)
        segs = []
        for y in range(4, end, 5):
            segs.append('[val %+d slope %+d x%d]' % (
                s8(s.b(p + y + 1)) * 256 + s.b(p + y) if True else 0,
                (s.b(p + y + 3) << 8 | s.b(p + y + 2)) - (0x10000 if s.b(p + y + 3) & 0x80 else 0),
                s.b(p + y + 4)))
        print('  env %d @ $%04X  end %d loop %d  %s' % (e, p, end, loop, ' '.join(segs)))

if __name__ == '__main__':
    main()
