"""Assemble every generated bank file with RGBDS and compare it with the ROM.

python e2_verify.py SRCDIR [RGBDS_DIR]
Each bankXX.asm is assembled on its own (labels are file-local), linked, and
the bank is compared byte for byte over $4000..end of the file's data. The
rest of the bank must be padding ($FF Ohasuta, $00 Doraemon/Sylvanian), except
Sylvanian bank $7A, which holds unrelated data after the sound data.
"""
import os
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(__file__))
from e2_parse import GAMES, rom  # noqa: E402
from e2_gen import FOLDER  # noqa: E402


def run(cmd, cwd):
    r = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if r.returncode:
        raise RuntimeError(' '.join(cmd) + '\n' + r.stdout + r.stderr)


def main(src, rgbds=''):
    asm = os.path.join(rgbds, 'rgbasm')
    link = os.path.join(rgbds, 'rgblink')
    total_bad = 0
    total_bytes = 0
    with tempfile.TemporaryDirectory() as tmp:
        for game in GAMES:
            d = rom(game)
            for bank in [GAMES[game]['sfx']] + GAMES[game]['music']:
                path = os.path.join(src, FOLDER[game], 'bank%02X.asm' % bank)
                obj = os.path.join(tmp, 'b.o')
                out = os.path.join(tmp, 'b.gb')
                run([asm, '-I', src, '-o', obj, path], src)
                run([link, '-p', '0x%02X' % d[bank * 0x4000 + 0x3FFF], '-o', out, obj], src)
                o = open(out, 'rb').read()
                ob = o[bank * 0x4000:(bank + 1) * 0x4000]
                rb = d[bank * 0x4000:(bank + 1) * 0x4000]
                # extent of the assembled data = file length up to the last byte the asm wrote
                end = 0x4000
                for line in open(path):
                    if line.startswith('; $4000-$'):
                        end = int(line[9:13], 16) + 1
                        break
                n = end - 0x4000
                bad = sum(1 for i in range(n) if ob[i] != rb[i])
                pad = rb[-1]
                tail_ok = all(x == pad for x in rb[n:]) or (game == 'sylv' and bank == 0x7A)
                total_bad += bad
                total_bytes += n
                print('%-10s bank %02X  $4000-$%04X  %5d bytes  %d mismatches%s' % (
                    FOLDER[game], bank, end - 1, n, bad, '' if tail_ok else '  TAIL NOT PADDING'))
    print('total %d bytes, %d mismatches' % (total_bytes, total_bad))
    return total_bad


if __name__ == '__main__':
    sys.exit(1 if main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else '') else 0)
