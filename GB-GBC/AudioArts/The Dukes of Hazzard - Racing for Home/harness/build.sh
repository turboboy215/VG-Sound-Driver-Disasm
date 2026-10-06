#!/bin/sh
# build.sh <game key>  -> harness_<key>.gb, linking the rebuilt bank (../build/<key>.o from build_check.sh)
set -e
g=$1
cd "$(dirname "$0")"
python3 - $g > hconf.inc <<'PY'
import sys; sys.path.insert(0, '../tools')
from qtcfg import GAMES
c = GAMES[sys.argv[1]]
api = {v: k for k, v in c['api'].items()}
print('DEF QT_BANK EQU $%02X' % (c['bank'] if c['bank'] is not None else 1))
print('DEF QT_INIT EQU $%04X' % api.get('MusicInit', api.get('Snd_Init')))
print('DEF QT_SFX EQU $%04X' % api.get('SoundFX', api.get('Snd_FX')))
print('DEF QT_UPDATE EQU $%04X' % api['Musicd'])
PY
rgbasm -o h.o harness.asm
rgblink -o harness_$g.gb h.o ../build/$g.o
rgbfix -v -m 0x19 -p 0 harness_$g.gb 2>/dev/null
