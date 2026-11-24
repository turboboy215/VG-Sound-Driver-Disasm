"""Generate the RGBDS sources for every sound bank of the three games.

python e2_gen.py OUTDIR      writes OUTDIR/<Game>/bankXX.asm, OUTDIR/driver/*.inc,
                             OUTDIR/epoch2_sound.inc
"""
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from e2_parse import analyze, GAMES, rom  # noqa: E402
from e2_code import render, table_labels  # noqa: E402
from e2_names import RAM, HW  # noqa: E402

FOLDER = {'oha': 'Ohasuta', 'dora3': 'Doraemon', 'sylv': 'Sylvanian'}
NOTE = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
MODE = {1: 'add, repeat', 2: 'add, repeat', 3: 'subtract, repeat', 4: 'add, once', 5: 'subtract, once'}
PAN = {0: 'both', 1: 'left only', 2: 'right only'}


def note_name(i):
    return '%s%d' % (NOTE[i % 12], 2 + i // 12)


def hx(v):
    return '$%02X' % v


def dbline(bs, comment=None, indent=4):
    s = ' ' * indent + 'db ' + ', '.join(hx(b) for b in bs)
    if comment:
        s = '%-40s ; %s' % (s, comment)
    return s


class Gen:
    def __init__(self, game, bank, stale_src=None):
        self.B = B = analyze(game, bank)
        self.game, self.bank = game, bank
        self.sfx = B.is_sfx
        self.pfx = 'SFX' if self.sfx else 'Music'
        self.labels_at = {}
        self.items = []   # (start, end, emitter)
        self.tl = table_labels(B)
        self.freq = [B.byte(B.freq_start + 2 * i) | (B.byte(B.freq_start + 2 * i + 1) << 8) for i in range(72)]

    def add_label(self, a, name):
        self.labels_at.setdefault(a, [])
        if name not in self.labels_at[a]:
            self.labels_at[a].append(name)

    # ------------------------------------------------------------ naming
    def song_names(self):
        B = self.B
        self.song_name = {}
        for h, s in B.songs.items():
            self.song_name[h] = '%s_%02X' % (self.pfx, s['ids'][0])
        self.track_name = {}
        for h in sorted(B.songs):
            s = B.songs[h]
            for ch in range(4):
                p = s['ptrs'][ch]
                if p not in self.track_name:
                    self.track_name[p] = '%s_Ch%d' % (self.song_name[h], ch + 1)

    # ------------------------------------------------------------ comments
    def tone_name(self, n):
        if not self.sfx:
            if n < 72:
                return note_name(n)
            return 'note $%02X (past FreqTable)' % n
        if n == 0:
            return 'note 0 (reads 2 code bytes before FreqTable: $%04X)' % (
                self.B.byte(self.B.freq_start - 2) | (self.B.byte(self.B.freq_start - 1) << 8))
        if n <= 72:
            return note_name(n - 1)
        return 'note $%02X (past FreqTable)' % n

    def row_comment(self, ch, row):
        a, n, kind, v = row
        B = self.B
        if kind == 'note':
            nt, vol, ln = v
            vs = 'vol %d' % (vol & 15) + (' (high nibble ignored)' if vol > 15 else '')
            if ch == 3:
                return 'drum %d  %s  %df' % (nt, vs, ln or 256)
            if ch == 2:
                return '%-4s %df' % (self.tone_name(nt), ln or 256)
            return '%-4s %s  %df' % (self.tone_name(nt), vs, ln or 256)
        if kind == 'rest':
            return 'rest %df' % (v or 256)
        if kind == 'pan':
            return 'pan: %s' % PAN.get(v, 'both')
        if kind == 'inst':
            if ch == 3:
                return 'ignored on ch4 (and hangs the driver)'
            if ch == 2:
                cnt = self.table_count('wave')
                if v >= cnt:
                    return 'wave instrument %d: past the table, reads $%04X' % (v, B.tables['wave'][0] + 18 * v)
                return 'wave instrument %d' % v
            role = 'inst1' if ch == 0 else 'inst2'
            cnt = self.table_count(role)
            if v >= cnt:
                return 'instrument %d: past the table' % v
            return 'instrument %d' % v
        if kind == 'ctl':
            return {0x00: 'loop point (next row)', 0x01: 'jump to loop point', 0xFF: 'end of track'}.get(v, '$FF $%02X: hangs' % v)
        raise ValueError(kind)

    def table_count(self, role):
        x, size = self.B.tables[role]
        return (self.table_end(x) - x) // size

    def table_end(self, x):
        cands = [s for s, e, f in self.items if s > x]
        return min(cands)

    # ------------------------------------------------------------ build item list
    def build(self):
        B = self.B
        self.song_names()
        self.items.append((0x4000, 0x4006, self.emit_jumps))
        self.items.append((0x4006, B.song_tbl_end, self.emit_songtable))
        for h in B.songs:
            self.items.append((h, h + 10, lambda h=h: self.emit_header(h)))
        for p, t in B.tracks.items():
            self.items.append((p, t['end'], lambda p=p: self.emit_track(p)))
        self.items.append((B.code_lo, B.code_hi, self.emit_code))
        self.items.append((B.freq_start, B.freq_start + 144, self.emit_freq))
        # tables: one item per distinct address, end = next item start
        for x in sorted(set(self.tl) - {0x4006, B.freq_start}):
            self.items.append((x, None, x))
        self.items.sort(key=lambda i: i[0])
        fixed = []
        for i, (s, e, f) in enumerate(self.items):
            if e is None:
                e = min(it[0] for it in self.items if it[0] > s)
                f = (lambda x=s, e=e: self.emit_table(x, e))
            fixed.append((s, e, f))
        self.items = fixed
        for x, nm in self.tl.items():
            self.add_label(x, nm)
        for h in B.songs:
            self.add_label(h, self.song_name[h])
        for p in B.tracks:
            self.add_label(p, self.track_name[p])
        # header word 5 labels
        self.endlabel = {}
        bounds = set(s for s, e, f in self.items) | set(e for s, e, f in self.items)
        rowstarts = set(r[0] for t in B.tracks.values() for r in t['rows'])
        for h, s in B.songs.items():
            p = s['ptrs'][4]
            if p in bounds or p in rowstarts:
                nm = self.song_name[h] + '_End'
                self.add_label(p, nm)
                self.endlabel[h] = nm
        # region end and stale tail
        end = max(e for s, e, f in self.items)
        self.region_end = end
        d = rom(self.game)
        bk = d[self.bank * 0x4000:(self.bank + 1) * 0x4000]
        self.pad = bk[-1]
        last = 0x4000 + max(i for i in range(0x4000) if bk[i] != self.pad)
        self.tail = None
        if last >= end and not (self.game == 'sylv' and self.bank == 0x7A):
            self.tail = (end, last + 1)
        self.check_cover()

    def check_cover(self):
        a = 0x4000
        for s, e, f in self.items:
            if s != a:
                raise ValueError('bank %02X: gap/overlap at %04X (next item %04X)' % (self.bank, a, s))
            a = e

    # ------------------------------------------------------------ emitters
    def emit_labels(self, a, out):
        names = self.labels_at.get(a, [])
        for nm in sorted(names, key=lambda n: not n.endswith('_End')):
            out.append('%s:' % nm)

    def emit_jumps(self):
        k = 'Sfx' if self.sfx else 'Mus'
        return ['    jp %s_Init' % k, '    jp %s_Update' % k]

    def emit_songtable(self):
        B = self.B
        out = []
        what = 'SFX' if self.sfx else 'music'
        out.append('; %s id -> header (indexed by the global id; ids stored in other banks are %s)' %
                   (what, 'unused (0)' if 0 in B.song_tbl else 'filled with the silent entry'))
        for i, h in enumerate(B.song_tbl):
            if h == 0:
                out.append('    %-36s ; $%02X' % ('dw 0', i))
            else:
                out.append('    %-36s ; $%02X' % ('dw ' + self.song_name[h], i))
        return out

    def emit_header(self, h):
        B = self.B
        s = B.songs[h]
        nm = self.song_name[h]
        out = []
        for ch in range(4):
            out.append('    dw %s - %s' % (self.track_name[s['ptrs'][ch]], nm))
        if h in self.endlabel:
            out.append('    %-36s ; end of the data (never read)' % ('dw %s - %s' % (self.endlabel[h], nm)))
        else:
            out.append('    %-36s ; end offset (never read)' % ('dw $%04X' % s['offs'][4]))
        return out

    def emit_track(self, p):
        B = self.B
        t = B.tracks[p]
        ch = t['ch']
        out = []
        jumped = False
        first = True
        for row in t['rows']:
            a, n, kind, v = row
            if not first:
                self.emit_labels(a, out)
            first = False
            bs = [B.byte(a + k) for k in range(n)]
            if kind == 'mod':
                mode, delay, cnt, vals = v
                if mode == 0:
                    out.append(dbline(bs, 'pitch mod off' + (' (not reached)' if jumped else '')))
                else:
                    c = 'pitch mod: %s, delay %d, %d steps' % (MODE.get(mode, 'add, repeat'), delay, cnt)
                    if cnt > 18:
                        c += ' (overruns the 18-byte buffer)'
                    out.append(dbline(bs[:4], c + (' (not reached)' if jumped else '')))
                    for k in range(0, len(vals), 16):
                        out.append(dbline(vals[k:k + 16], None, 8))
                continue
            c = self.row_comment(ch, row)
            if jumped:
                c += ' (not reached)'
            out.append(dbline(bs, c))
            if kind == 'ctl' and v == 0x01:
                jumped = True
        return out

    def emit_code(self):
        k = 'sfx' if self.sfx else 'mus'
        return ['', '    INCLUDE "driver/%s_%s.inc"' % (k, self.B.ver), '']

    def emit_freq(self):
        out = ['; 72 frequencies, C2..B7. Music note n plays entry n, SFX note n plays entry n-1.']
        for i, f in enumerate(self.freq):
            out.append('    %-36s ; %s' % ('dw $%04X' % f, note_name(i)))
        return out

    def emit_table(self, x, e):
        B = self.B
        nm = self.tl[x]
        roles = [r for r in ('inst1', 'inst2', 'wave', 'noise') if B.tables[r][0] == x]
        out = []
        by = [B.byte(a) for a in range(x, e)]
        if nm == 'Ch1InstTable':
            out.append('; ch1 instruments: NR10, NR11, NR12, NR14 value for $E0')
            for i in range(len(by) // 4):
                b = by[4 * i:4 * i + 4]
                out.append(dbline(b, '%d' % i))
            rest = by[len(by) // 4 * 4:]
        elif nm == 'Ch2InstTable':
            out.append('; ch2 instruments: NR21, NR22, NR24 value for $E0')
            for i in range(len(by) // 3):
                out.append(dbline(by[3 * i:3 * i + 3], '%d' % i))
            rest = by[len(by) // 3 * 3:]
        elif nm == 'WaveTable':
            out.append('; wave instruments: NR32, rest flag, 16 bytes of wave RAM')
            for i in range(len(by) // 18):
                b = by[18 * i:18 * i + 18]
                out.append(dbline(b[:2], '%d' % i))
                out.append(dbline(b[2:], None, 8))
            rest = by[len(by) // 18 * 18:]
        else:
            if roles == ['noise']:
                out.append('; drums: NR42, NR43, NR44')
            else:
                out.append('; drums: NR42, NR43, NR44. The SFX driver also reads this table for $F0')
                out.append('; on %s, which have no table of their own here.' %
                           ' and '.join({'inst2': 'ch2', 'wave': 'ch3'}[r] for r in roles if r != 'noise'))
            for i in range(len(by) // 3):
                out.append(dbline(by[3 * i:3 * i + 3], '%d' % i))
            rest = by[len(by) // 3 * 3:]
        if rest:
            out.append(dbline(rest, 'unused'))
        return out

    # ------------------------------------------------------------ file
    def render(self):
        g = GAMES[self.game]
        B = self.B
        out = []
        kind = 'SFX' if self.sfx else 'music'
        out.append('; %s' % g['title'])
        out.append('; Sound bank $%02X (%s): Epoch sound driver type 2, version %s.' % (self.bank, kind, B.ver))
        out.append('; Generated by tools/e2_gen.py. Assembles byte-identical to ROM bank $%02X,' % self.bank)
        out.append('; $4000-$%04X%s.' % ((self.tail[1] if self.tail else self.region_end) - 1,
                                         '' if not self.tail else ' (sound data ends at $%04X)' % (self.region_end - 1)))
        out.append(';')
        out.append('; Rows: note, volume, length (frames). See Epoch2_SoundDriver.md.')
        out.append('')
        out.append('DEF SOUND_RAM EQU $%04X' % B.ram)
        out.append('    INCLUDE "epoch2_sound.inc"')
        out.append('')
        out.append('SECTION "Sound bank $%02X", ROMX[$4000], BANK[$%02X]' % (self.bank, self.bank))
        out.append('')
        for s, e, f in self.items:
            if s in self.B.songs:
                ends = [n for n in self.labels_at.get(s, []) if n.endswith('_End')]
                for n in ends:
                    out.append('%s:' % n)
                ids = self.B.songs[s]['ids']
                out.append('; %s id%s %s' % ('SFX' if self.sfx else 'music', 's' if len(ids) > 1 else '',
                                             ', '.join('$%02X' % i for i in ids)))
                for n in self.labels_at.get(s, []):
                    if n not in ends:
                        out.append('%s:' % n)
            else:
                self.emit_labels(s, out)
            out += f()
            out.append('')
        self.emit_labels(self.region_end, out)
        if self.tail:
            s, e = self.tail
            d = rom(self.game)
            src = self.stale_source(s, e)
            out.append('; $%04X-$%04X: bytes left over from an earlier build, never read.' % (s, e - 1))
            if src is not None:
                out.append('; They are identical to bank $%02X at the same addresses.' % src)
            bs = d[self.bank * 0x4000 + s - 0x4000:self.bank * 0x4000 + e - 0x4000]
            for k in range(0, len(bs), 16):
                out.append(dbline(bs[k:k + 16]))
        return '\n'.join(out) + '\n'

    def stale_source(self, s, e):
        d = rom(self.game)
        g = GAMES[self.game]
        mine = d[self.bank * 0x4000 + s - 0x4000:self.bank * 0x4000 + e - 0x4000]
        for b2 in [g['sfx']] + g['music']:
            if b2 == self.bank:
                continue
            o = d[b2 * 0x4000 + s - 0x4000:b2 * 0x4000 + e - 0x4000]
            if o == mine:
                return b2
        return None


def inc_file():
    out = ['; Epoch sound driver type 2: register and RAM names.',
           '; The including file defines SOUND_RAM first ($CC00 Ohasuta, $DF00 Doraemon,',
           '; $CF00 Sylvanian). EQUs only.',
           '']
    for a in sorted(HW):
        if a < 0xFF30:
            out.append('DEF %-14s EQU $%04X' % (HW[a], a))
    out.append('DEF %-14s EQU $FF30' % '_AUD3WAVERAM')
    out.append('')
    for o, n, c in RAM:
        line = 'DEF %-22s EQU SOUND_RAM + $%02X' % (n, o)
        if c:
            line = '%-48s ; %s' % (line, c)
        out.append(line)
    return '\n'.join(out) + '\n'


def generate(outdir):
    os.makedirs(os.path.join(outdir, 'driver'), exist_ok=True)
    with open(os.path.join(outdir, 'epoch2_sound.inc'), 'w', newline='\n') as f:
        f.write(inc_file())
    for v in 'ABC':
        for k in ('mus', 'sfx'):
            txt, r = render(v, k)
            with open(os.path.join(outdir, 'driver', '%s_%s.inc' % (k, v)), 'w', newline='\n') as f:
                f.write(txt)
    made = []
    for game in GAMES:
        os.makedirs(os.path.join(outdir, FOLDER[game]), exist_ok=True)
        for bank in [GAMES[game]['sfx']] + GAMES[game]['music']:
            G = Gen(game, bank)
            G.build()
            path = os.path.join(outdir, FOLDER[game], 'bank%02X.asm' % bank)
            with open(path, 'w', newline='\n') as f:
                f.write(G.render())
            made.append((game, bank, path, G))
    return made


if __name__ == '__main__':
    for game, bank, path, G in generate(sys.argv[1]):
        print(path, '$4000-$%04X' % ((G.tail[1] if G.tail else G.region_end) - 1))
