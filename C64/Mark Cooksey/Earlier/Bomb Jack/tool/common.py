"""Helpers shared by the C64 Mark Cooksey game configs: PSID loading, the PSID
header, variables that live inside the player image, and small table/data
emitters.  Items are added to a core.Disasm."""

import struct
from core import h2, h4

NOTE12 = ['C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-']


# ---------------------------------------------------------------- PSID file
def load_sid(fn):
    d = open(fn, 'rb').read()
    off = struct.unpack('>H', d[6:8])[0]
    load, init, play, songs, start = struct.unpack('>HHHHH', d[8:18])
    hdr = d[:off]
    if load == 0:
        load = d[off] | d[off + 1] << 8
        hdr = d[:off + 2]
        off += 2
    return dict(file=d, header=hdr, load=load, init=init, play=play, songs=songs,
                start=start, body=d[off:], end=load + len(d) - off,
                speed=struct.unpack('>I', d[18:22])[0],
                name=d[22:54].rstrip(b'\0').decode('latin-1'),
                author=d[54:86].rstrip(b'\0').decode('latin-1'),
                released=d[86:118].rstrip(b'\0').decode('latin-1'),
                flags=struct.unpack('>H', d[0x76:0x78])[0] if off >= 0x7C else 0)


def _str32(b):
    """32-byte PSID text field as .byte "text" plus zero padding"""
    t = b.rstrip(b'\0')
    out = []
    if t:
        out.append('"%s"' % t.decode('latin-1'))
    if len(t) < 32:
        out.append('%d dup' % (32 - len(t)))
    return t.decode('latin-1'), 32 - len(t)


def header_lines(s, sym):
    """PSID header as its own segment (so the build reproduces the .sid file).
    sym: dict with 'init', 'play' label names."""
    h = s['header']
    L = []
    L.append('.segment "PSIDHDR"')
    L.append('')
    L.append('; PSID v%d header (big-endian fields), written by the SID ripper,' % struct.unpack('>H', h[4:6])[0])
    L.append('; not by the game. The first two bytes after it are the load address.')
    L.append('PsidHeader:')
    L.append('        .byte "%s"                          ; magic' % h[0:4].decode())
    L.append('        .dbyt $%04X                         ; version' % struct.unpack('>H', h[4:6])[0])
    L.append('        .dbyt $%04X                         ; offset of the data' % struct.unpack('>H', h[6:8])[0])
    L.append('        .dbyt $%04X                         ; load address (0 = first 2 data bytes)' % struct.unpack('>H', h[8:10])[0])
    L.append('        .dbyt %-29s ; init (A = song - 1)' % sym['init'])
    L.append('        .dbyt %-29s ; play' % sym['play'])
    L.append('        .dbyt %-29s ; number of songs' % ('$%04X' % s['songs']))
    L.append('        .dbyt %-29s ; default song' % ('$%04X' % s['start']))
    L.append('        .dbyt $%04X, $%04X                  ; speed bits per song: 1 = CIA timer, 0 = VBI'
             % (s['speed'] >> 16, s['speed'] & 0xFFFF))
    for nm, a in (('name', 22), ('author', 54), ('released', 86)):
        t = h[a:a + 32].rstrip(b'\0').decode('latin-1')
        L.append('        .byte "%s"' % t)
        L.append('        .res %d, $00                       ; %s (32 bytes)' % (32 - len(t), nm))
    if len(h) >= 0x7C:
        fl = struct.unpack('>H', h[0x76:0x78])[0]
        clk = ['unknown', 'PAL', 'NTSC', 'PAL+NTSC'][(fl >> 2) & 3]
        mdl = ['unknown', '6581', '8580', '6581+8580'][(fl >> 4) & 3]
        L.append('        .dbyt $%04X                         ; flags: clock %s, SID %s' % (fl, clk, mdl))
        L.append('        .byte $%02X, $%02X                      ; start page, page length' % (h[0x78], h[0x79]))
        L.append('        .dbyt $%04X                         ; second/third SID' % struct.unpack('>H', h[0x7A:0x7C])[0])
    if len(h) > struct.unpack('>H', h[6:8])[0]:
        L.append('        .word LoadAddress                   ; load address (little-endian)')
    L.append('')
    return L


# ---------------------------------------------------------------- variables
def var(d, a, name, n=1, com=None, block=None):
    """a driver variable stored inside the image (its value is whatever the
    ripper's snapshot contained)."""
    d.label(a, name, primary=True)
    if block:
        for c in block:
            d.comment(a, c)
    vals = [d.b(a + i) for i in range(n)]
    d.add(a, n, [('.byte ' + ','.join(h2(v) for v in vals), com)], 'data')


def bytes_item(d, a, n, name=None, com=None, per=16, block=None, kind='data'):
    if name:
        d.label(a, name, primary=True)
    if block:
        for c in block:
            d.comment(a, c)
    lines = []
    for i in range(0, n, per):
        k = min(per, n - i)
        lines.append(('.byte ' + ','.join(h2(d.b(a + i + j)) for j in range(k)), com if i == 0 else None))
    d.add(a, n, lines, kind)


def words_item(d, a, n, name=None, com=None, per=4, block=None, comments=None):
    """n little-endian pointers, rendered symbolically"""
    if name:
        d.label(a, name, primary=True)
    if block:
        for c in block:
            d.comment(a, c)
    vals = [d.w(a + 2 * i) for i in range(n)]

    def lines(dd):
        out = []
        for i in range(0, n, per):
            chunk = vals[i:i + per]
            c = com if i == 0 else None
            if comments:
                c = comments[i // per]
            out.append(('.word ' + ', '.join(dd.wordref(v) for v in chunk), c))
        return out
    d.add(a, 2 * n, lines, 'data')
    return vals


def lohi_item(d, a, n, name, kind, targets, com=None, per=8, block=None):
    """table of n .lobytes/.hibytes of the given targets"""
    d.label(a, name, primary=True)
    if block:
        for c in block:
            d.comment(a, c)
    directive = '.lobytes' if kind == 'lo' else '.hibytes'

    def lines(dd):
        out = []
        for i in range(0, n, per):
            out.append(('%s ' % directive + ', '.join(
                t if isinstance(t, str) else dd.wordref(t) for t in targets[i:i + per]),
                com if i == 0 else None))
        return out
    d.add(a, n, lines, 'data')


def code(d, a, name, block=None):
    d.code(a, name)
    if block:
        for c in block:
            d.comment(a, c)


def name_cmp_chain(d, prefix_of):
    """rename auto labels (Lxxxx) that start with CMP #imm after the nearest
    named label: <prefix>_<imm>.  prefix_of(name) maps the enclosing label
    name to the prefix (or None to skip)."""
    named = sorted((a, l[0]) for a, l in d.labels.items() if not (l[0][0] == 'L' and len(l[0]) == 5))
    import bisect
    keys = [a for a, _ in named]
    for a in sorted(d.labels):
        l = d.labels[a]
        if not (l[0][0] == 'L' and len(l[0]) == 5):
            continue
        it = d.items.get(a)
        if not it or it.kind != 'code' or it.lines[0] != 'cmp' or it.lines[1] != 'imm':
            continue
        i = bisect.bisect_left(keys, a) - 1
        if i < 0:
            continue
        p = prefix_of(named[i][1])
        if p:
            l[0] = '%s_%02X' % (p, it.lines[2])
