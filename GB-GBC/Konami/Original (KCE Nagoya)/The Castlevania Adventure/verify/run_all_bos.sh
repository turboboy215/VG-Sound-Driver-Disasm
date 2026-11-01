#!/bin/bash
# Blades of Steel: every sound id alone, 7000 ticks
cd "$(dirname "$0")/.."
for i in $(seq 1 51); do printf -v h '%02X' $i; python3 verify/vmodel2.py bos 7000 $h 2>&1 | grep -v SDL; done
