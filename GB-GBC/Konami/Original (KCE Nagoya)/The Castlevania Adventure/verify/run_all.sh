#!/bin/sh
# every sound id alone, long enough to pass each loop point
cd "$(dirname "$0")/.."
for i in $(seq 1 49); do printf -v h '%02X' $i; python3 verify/vmodel.py cva 7000 $h 2>&1 | grep -v SDL; done
for i in $(seq 1 32); do printf -v h '%02X' $i; python3 verify/vmodel.py mm 7000 $h 2>&1 | grep -v SDL; done
