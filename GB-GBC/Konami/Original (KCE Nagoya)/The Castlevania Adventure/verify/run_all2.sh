#!/bin/bash
# every sound id alone, long enough to pass each loop point (later variant: Nemesis, Belmont's Revenge)
cd "$(dirname "$0")/.."
for i in $(seq 1 57); do printf -v h '%02X' $i; python3 verify/vmodel2.py nem 7000 $h 2>&1 | grep -v SDL; done
for i in $(seq 1 107); do printf -v h '%02X' $i; python3 verify/vmodel2.py cv2 7000 $h 2>&1 | grep -v SDL; done
