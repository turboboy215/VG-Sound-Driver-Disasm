import sys, subprocess, os, importlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mkfmt import Engine, CMDS

def build(cfgname, rom, off, header_fn):
    cfg = importlib.import_module(cfgname).cfg
    data = open(rom, 'rb').read()[16:][off:off + 0x4000]
    e = Engine(cfg, data, 0x8000)
    e.run()
    head = header_fn(e) if header_fn else []
    h, body = e.render([])
    from mkcomments import RAMC
    from core import APU
    lines = list(head)
    lines.append('; ---------------------------------------------------------------- RAM')
    for a in sorted(e.ram):
        n = e.ram[a]
        if '+' in n:
            continue
        l = '%-20s = $%04X' % (n, a) if a > 0xFF else '%-20s = $%02X' % (n, a)
        if RAMC.get(n):
            l = l.ljust(36) + '; ' + RAMC[n]
        lines.append(l)
    lines.append('')
    lines.append('; ---------------------------------------------------------------- APU')
    for a in sorted(APU):
        lines.append('%-20s = $%04X' % (APU[a], a))
    lines.append('')
    lines.append('; ---------------------------------------------------------------- track commands')
    for c in sorted(CMDS):
        lines.append('%-20s = $%02X' % (CMDS[c][0], c))
    lines.append('')
    if e.extern:
        lines.append('; ---------------------------------------------------------------- outside this file')
        for a in sorted(e.extern):
            lines.append('%-20s = $%04X' % (e.extern[a], a))
        lines.append('')
    lines.append('.segment "SOUND"')
    lines.append('')
    lines += body
    return e, '\n'.join(lines) + '\n', data

def verify(src, start, end, original, name, wd):
    os.makedirs(wd, exist_ok=True)
    s = os.path.join(wd, name + '.s')
    open(s, 'w').write(src)
    cfg = os.path.join(wd, name + '.cfg')
    open(cfg, 'w').write('MEMORY { M: start=$%04X, size=$%04X, fill=no, file=%%O; }\nSEGMENTS { SOUND: load=M, type=ro; }\n' % (start, end - start))
    o = os.path.join(wd, name + '.o'); b = os.path.join(wd, name + '.bin')
    r = subprocess.run(['ca65', '-o', o, s], capture_output=True, text=True)
    if r.returncode:
        print(r.stderr[:3000]); return False
    r = subprocess.run(['ld65', '-C', cfg, '-o', b, o], capture_output=True, text=True)
    if r.returncode:
        print(r.stderr[:3000]); return False
    got = open(b, 'rb').read()
    os.remove(o); os.remove(b)
    if got == original:
        print(name, 'REASSEMBLY OK', len(got), 'bytes'); return True
    for i, (x, y) in enumerate(zip(got, original)):
        if x != y:
            print(name, 'MISMATCH at %04X: %02X vs %02X' % (start + i, x, y)); break
    print(len(got), len(original)); return False
