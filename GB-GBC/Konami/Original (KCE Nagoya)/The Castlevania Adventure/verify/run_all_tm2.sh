#!/bin/bash
# TMNT II: every sound id alone (bank 14 $01-$9E incl. the PCM voices $9A-$9D, bank 15 $C1-$F3), 8000 updates (31 s)
cd "$(dirname "$0")/.."
for i in $(seq 1 158) $(seq 193 243); do printf -v h '%02X' $i; python3 verify/vmodel4.py 8000 $h 2>&1 | grep -v SDL | grep -v "^ \|Traceback\|Error" ; done
