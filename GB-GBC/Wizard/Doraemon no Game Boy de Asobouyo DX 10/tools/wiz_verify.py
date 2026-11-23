"""Reassemble both files and compare the driver regions with the ROMs.
The overlay given to rgblink has those regions filled with $00, so every checked byte comes from the .asm.
Run from anywhere; set RGBDS to the folder with rgbasm/rgblink if they aren't on PATH."""
import os, subprocess, tempfile
os.chdir(os.path.dirname(os.path.abspath(__file__)) + '/..')
R = os.environ.get('RGBDS', '')
tool = lambda t: os.path.join(R, t) if R else t
T = lambda n: os.path.join(tempfile.gettempdir(), n)
for name, rom, b4end, b0 in [('DX10', 'Doraemon DX 10 (J) [S].gb', 0x7D32, (0x2846, 0x3046)),
                             ('QuizBoy', 'Doraemon no Quiz Boy (J) (V1.0) [C][!].gbc', 0x7C1A, (0x3270, 0x3A70))]:
    orig = open(rom, 'rb').read()
    blank = bytearray(orig)
    regions = [(0x10000, 0x10000 + b4end - 0x4000), b0]
    for lo, hi in regions:
        blank[lo:hi] = bytes(hi - lo)
    open(T(f'{name}_blank'), 'wb').write(blank)
    subprocess.run([tool('rgbasm'), '-o', T(f'{name}.o'), f'{name}_sound.asm'], check=True)
    subprocess.run([tool('rgblink'), '-O', T(f'{name}_blank'), '-o', T(f'{name}.gb'), T(f'{name}.o')], check=True)
    out = open(T(f'{name}.gb'), 'rb').read()
    n = sum(hi - lo for lo, hi in regions)
    bad = sum(1 for lo, hi in regions for i in range(lo, hi) if out[i] != orig[i])
    rest = sum(1 for i in range(len(orig)) if out[i] != orig[i]) - bad
    print(f'{name}: {n} bytes checked, {bad} mismatches, {rest} differences elsewhere')
