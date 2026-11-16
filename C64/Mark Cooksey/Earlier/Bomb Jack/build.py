"""Build the ca65 disassemblies of the Mark Cooksey C64 SID rips and check that
each one reassembles to the original .sid file byte for byte.

    python3 build.py <folder with the .sid files> <output folder>

Needs ca65/ld65 (cc65) on the PATH for the check."""

import sys, os, subprocess, importlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from core import Disasm, SIDREGS
from common import load_sid, header_lines

GAMES = [
    ('cfg_bj', 'Bomb_Jack.sid', 'bomb_jack_sound'),
    ('cfg_pb', 'Paperboy.sid', 'paperboy_sound'),
    ('cfg_fw', 'Forgotten_Worlds.sid', 'forgotten_worlds_sound'),
]


def build(cfgname, sidpath):
    cfg = importlib.import_module(cfgname)
    s = load_sid(sidpath)
    d = Disasm(s['body'], s['load'], s['load'], s['end'], cfg.TITLE)
    info = cfg.setup(d, s)
    d.trace()
    if hasattr(cfg, 'after_trace'):
        cfg.after_trace(d, s)
    d.label(s['load'], 'LoadAddress')
    _, body = d.render([])
    L = list(info['header'])
    # equates
    for title, eq in info.get('equates', []):
        L.append('; ---------------------------------------------------------------- ' + title)
        for n, v, c in eq:
            l = '%-20s = %s' % (n, v)
            if c:
                l = l.ljust(36) + '; ' + c
            L.append(l)
        L.append('')
    L.append('; ---------------------------------------------------------------- SID / CIA')
    used = set()
    for it in d.items.values():
        if it.kind == 'code' and isinstance(it.lines[2], int):
            v = it.lines[2]
            for k in range(0, 8):
                if v - k in SIDREGS:
                    used.add(v - k)
    for a in sorted(SIDREGS):
        L.append('%-20s = $%04X' % (SIDREGS[a], a))
    L.append('')
    if d.extern:
        L.append('; ---------------------------------------------------------------- outside this file')
        for a in sorted(d.extern):
            L.append('%-20s = $%04X' % (d.extern[a], a))
        L.append('')
    L += header_lines(s, info['sym'])
    L.append('.segment "PLAYER"')
    L.append('')
    L += body
    return s, '\n'.join(L) + '\n'


def write_and_verify(s, src, name, outdir):
    sp = os.path.join(outdir, name + '.s')
    open(sp, 'w', newline='\n').write(src)
    cp = os.path.join(outdir, name + '.cfg')
    hlen = len(s['header'])
    open(cp, 'w', newline='\n').write(
        'MEMORY {\n'
        '    HDR:  start = $0000, size = $%04X, file = %%O;\n'
        '    MAIN: start = $%04X, size = $%04X, file = %%O;\n'
        '}\n'
        'SEGMENTS {\n'
        '    PSIDHDR: load = HDR,  type = ro;\n'
        '    PLAYER:  load = MAIN, type = ro;\n'
        '}\n' % (hlen, s['load'], s['end'] - s['load']))
    tmp = os.path.join(outdir, '_build')
    os.makedirs(tmp, exist_ok=True)
    o = os.path.join(tmp, name + '.o')
    b = os.path.join(tmp, name + '.sid')
    r = subprocess.run(['ca65', '-o', o, sp], capture_output=True, text=True)
    if r.returncode:
        print(r.stderr[:4000]); return False
    r = subprocess.run(['ld65', '-C', cp, '-o', b, o], capture_output=True, text=True)
    if r.returncode:
        print(r.stderr[:4000]); return False
    got = open(b, 'rb').read()
    if got == s['file']:
        print('%-26s reassembles byte-identically (%d bytes)' % (name, len(got)))
        return True
    for i, (x, y) in enumerate(zip(got, s['file'])):
        if x != y:
            print(name, 'MISMATCH at file offset %04X: %02X vs %02X' % (i, x, y)); break
    print(len(got), len(s['file']))
    return False


if __name__ == '__main__':
    src_dir, out_dir = sys.argv[1], sys.argv[2]
    only = sys.argv[3:]
    ok = True
    for cfgname, fn, name in GAMES:
        if only and cfgname not in only:
            continue
        s, src = build(cfgname, os.path.join(src_dir, fn))
        ok &= write_and_verify(s, src, name, out_dir)
    sys.exit(0 if ok else 1)
