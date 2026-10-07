import sys; sys.path.insert(0,'.')
from main import build, verify
e, _ = build('cfg_jm', '/tmp/w/jm.nes', 0x16000, 0x8000, 0x2000, '.', None)
prg = open('/tmp/w/jm.nes','rb').read()[16:]
B = prg[0x1C000:0x1E000]
# who uses which sample
users = {}
for i in range(7):
    t = e.b(0x86A2+i) | e.b(0x86A9+i)<<8
    users.setdefault(0xC000+e.b(t+1)*64, []).append(('DmcSample_%d' % i, e.b(t+2)*16+1, 'DmcSampleDef_%d' % i))
for i in range(0x18):
    t = e.b(0x98D2+i) | e.b(0x98BA+i)<<8
    if e.b(t) >= 4:
        users.setdefault(0xC000+e.b(t+1)*64, []).append(('SfxSample_%02X' % i, e.b(t+2)*16+1, 'Sfx_%02X' % i))
start = 0xC000
end = max(a + n for a, l in users.items() for _, n, _ in l)
L = [';' + '='*78,
     ';  Joe & Mac - Caveman Ninja (E): DMC sample data used by the sound engine',
     ';  Fixed PRG bank at $C000 (8K bank 14, file offset $1C010), $%04X-$%04X.' % (start, end-1),
     ';  DMC_START = (address - $C000) / 64, DMC_LEN = (length - 1) / 16.',
     ';  Samples overlap: 5 starts inside 4, and the last byte of 1 is the first of 2.',
     ';  Bytes between samples are not referenced but are kept.',
     ';  Reassembles byte-identically with joe_and_mac_dmc_samples.cfg.',
     ';' + '='*78, '', '.segment "SAMPLES"', '']
ends = {}
for a, l in users.items():
    for nm, n, who in l:
        ends.setdefault(a + n, []).append(nm)
a = start
row = []
def flush():
    global row
    if row:
        L.append('        .byte ' + ','.join('$%02X' % v for v in row))
        row = []
while a < end:
    if a in users or a in ends:
        flush()
        for nm in ends.get(a, []):
            L.append('; end of %s' % nm)
        for nm, n, who in users.get(a, []):
            L.append('')
            L.append('; %s: %d bytes, $%04X-$%04X (used by %s)' % (nm, n, a, a+n-1, who))
            L.append('%s:' % nm)
    row.append(B[a-0xC000])
    if len(row) == 16: flush()
    a += 1
flush()
for nm in ends.get(end, []):
    L.append('; end of %s' % nm)
src = '\n'.join(L) + '\n'
src = src.replace('.segment "SAMPLES"', '.segment "SOUND"')
verify(src, start, end, B[:end-start], 'joe_and_mac_dmc_samples', '/tmp/w/out')
print({k:hex(a) for a,l in users.items() for k in [x[0] for x in l]}, hex(end))
