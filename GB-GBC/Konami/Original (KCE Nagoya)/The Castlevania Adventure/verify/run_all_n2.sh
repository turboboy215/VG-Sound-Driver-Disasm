#!/bin/bash
# Nemesis II: every sound id alone (bank 13: $01-$5D, bank 14: $81-$96, bank 15: $C1-$D9), 9000 updates (70 s)
cd "$(dirname "$0")/.."
for i in $(seq 1 93) $(seq 129 150) $(seq 193 217); do printf -v h '%02X' $i; python3 verify/vmodel3.py n2 9000 $h 2>&1 | grep -v SDL; done
