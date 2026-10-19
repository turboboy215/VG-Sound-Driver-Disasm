#!/bin/sh
# Assemble the Toki Tori sound sources, link them over the original ROM and compare.
# usage: sh build_check.sh "<path to Toki Tori (U) (M5) [C][!].gbc>"
set -e
ROM="${1:-../Toki Tori (U) (M5) [C][!].gbc}"
cd "$(dirname "$0")"
mkdir -p obj
OBJS=""
for f in TT_Home TT_Driver TT_Music_2E TT_Music_2F TT_Music_30 TT_Music_31 TT_Music_32 TT_Music_33; do
    rgbasm -Wall -o obj/$f.o $f.asm
    OBJS="$OBJS obj/$f.o"
done
# 1) overlay link: every byte the sources emit replaces the ROM's
rgblink -O "$ROM" -o obj/overlay.gbc $OBJS
cmp "$ROM" obj/overlay.gbc && echo "overlay: identical to the original ROM"
# 2) the regions on their own (link without the overlay, compare each region)
rgblink -o obj/alone.gbc $OBJS
python3 - "$ROM" obj/alone.gbc <<'PY'
import sys
a = open(sys.argv[1], 'rb').read(); b = open(sys.argv[2], 'rb').read()
regions = [(0x3D00, 0x4000, 'home $3D00-$3FFF')] + \
          [(k * 0x4000, (k + 1) * 0x4000, f'bank ${k:02X}') for k in range(0x2D, 0x34)]
bad = 0
for s, e, n in regions:
    ok = a[s:e] == b[s:e]
    bad += not ok
    print(f'{n:<18} {"ok" if ok else "DIFFERENT"}')
sys.exit(bad)
PY
