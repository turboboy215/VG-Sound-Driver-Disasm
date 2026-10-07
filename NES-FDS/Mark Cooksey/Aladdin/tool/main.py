import sys, subprocess, os, importlib
sys.path.insert(0, os.path.dirname(__file__))
from mcfmt import Engine

def load(rom, off, size):
    d = open(rom, 'rb').read()[16:]
    return d[off:off + size]

def build(cfgname, rom, off, base, size, outdir, header_fn):
    cfg = importlib.import_module(cfgname).cfg
    data = load(rom, off, size)
    e = Engine(cfg, data, base)
    e.run()
    head = header_fn(e) if header_fn else []
    h, body = e.render([])
    lines = list(head)
    # equates
    lines.append('; ---------------------------------------------------------------- RAM')
    for a in sorted(e.ram):
        n = e.ram[a]
        if '+' in n:
            continue
        from comments import RAMC
        l = '%-20s = $%04X' % (n, a) if a > 0xFF else '%-20s = $%02X' % (n, a)
        if RAMC.get(n):
            l = l.ljust(36) + '; ' + RAMC[n]
        lines.append(l)
    lines.append('')
    lines.append('; ---------------------------------------------------------------- APU')
    from core import APU
    for a in sorted(APU):
        lines.append('%-20s = $%04X' % (APU[a], a))
    lines.append('')
    lines.append('; ---------------------------------------------------------------- track commands')
    for i, (n, k) in enumerate(cfg['cmds']):
        lines.append('%-20s = $%02X' % (n, 0x60 + i))
    lines.append('')
    if e.extern:
        lines.append('; ---------------------------------------------------------------- outside this file')
        for a in sorted(e.extern):
            lines.append('%-20s = $%04X' % (e.extern[a], a))
        lines.append('')
    lines.append('.segment "SOUND"')
    lines.append('')
    lines += body
    src = '\n'.join(lines) + '\n'
    return e, src

def verify(src, start, end, original, name, wd):
    s = os.path.join(wd, name + '.s')
    open(s, 'w').write(src)
    cfg = os.path.join(wd, name + '.cfg')
    open(cfg, 'w').write('MEMORY { M: start=$%04X, size=$%04X, fill=no, file=%%O; }\nSEGMENTS { SOUND: load=M, type=ro; }\n' % (start, end - start))
    o = os.path.join(wd, name + '.o')
    b = os.path.join(wd, name + '.bin')
    r = subprocess.run(['ca65', '-o', o, s], capture_output=True, text=True)
    if r.returncode:
        print(r.stderr[:3000]); return False
    r = subprocess.run(['ld65', '-C', cfg, '-o', b, o], capture_output=True, text=True)
    if r.returncode:
        print(r.stderr[:3000]); return False
    got = open(b, 'rb').read()
    if got == original:
        print(name, 'REASSEMBLY OK', len(got), 'bytes')
        return True
    for i, (x, y) in enumerate(zip(got, original)):
        if x != y:
            print(name, 'MISMATCH at %04X: %02X vs %02X' % (start + i, x, y)); break
    print(len(got), len(original))
    return False
