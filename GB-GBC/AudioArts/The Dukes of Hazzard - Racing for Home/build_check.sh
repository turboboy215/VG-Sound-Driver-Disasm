#!/bin/sh
# Assemble + link every game's sources with RGBDS (0.9.1) and compare the result
# byte-for-byte with the original ROM (ROMs in the parent folder, or $QT_ROMS).
cd "$(dirname "$0")"
mkdir -p build
check() {  # key dir end
  ( cd $2 && rgbasm -Wall -I .. -o ../build/$1.o QT_$2.asm && rgblink -o ../build/$1.gb ../build/$1.o ) || return
  python3 tools/cmp.py $1 build/$1.gb $3
}
check carm    Carmageddon         53FA
check casperu CasperU             675D
check caspere CasperE             66CE
check chicken ChickenRun          7201
check gng     GhostsNGoblins      5BD8
check dukes   DukesOfHazzard      5CAB
check xgb     ExtremeGhostbusters 7B51
check cmr     ColinMcRae          57AE
check pinball Pinball3DUltra      7906
# Colin McRae's home-bank PCM interrupt
( cd ColinMcRae && rgbasm -I .. -o ../build/cmrirq.o ColinMcRae_PCMIrq.asm && rgblink -o ../build/cmrirq.gb ../build/cmrirq.o )
python3 - <<'PY'
import sys; sys.path.insert(0, 'tools')
from qtcfg import DIR, GAMES
a = open('build/cmrirq.gb', 'rb').read(); b = open(DIR + GAMES['cmr']['file'], 'rb').read()
ok = all(a[lo:hi] == b[lo:hi] for lo, hi in ((0x50, 0x53), (0x238, 0x2E0)))
print('cmr PCM interrupt ROM0 $0050-$0052, $0238-$02DF:', 'OK' if ok else 'DIFF')
PY
