#!/bin/sh
# Runs every verification of the Irem drivers (needs PyBoy). Logs go to verify/*.log.
cd "$(dirname "$0")/.."
python3 verify/mkscripts.py
python3 verify/patch_test.py
python3 verify/vrun.py kn 96200 verify/each_kn.json > verify/each_kn.log 2>&1
python3 verify/vrun.py hh 210900 verify/each_hh.json > verify/each_hh.log 2>&1
for s in 1 2 3; do
  python3 verify/vrun.py kn 12000 verify/combo${s}_kn.json > verify/combo${s}_kn.log 2>&1
  python3 verify/vrun.py hh 12000 verify/combo${s}_hh.json > verify/combo${s}_hh.log 2>&1
done
python3 verify/vrun.py kn 2400 verify/test_kn.json > verify/test_kn.log 2>&1
python3 verify/vrun.py hh 1600 verify/test_hh.json > verify/test_hh.log 2>&1
python3 verify/vpcm.py > verify/vpcm.log 2>&1
python3 verify/vpcm2.py > verify/vpcm2.log 2>&1
python3 tools/hhscript.py > verify/hhscript.log
grep -h "updates checked\|sample" verify/*.log
