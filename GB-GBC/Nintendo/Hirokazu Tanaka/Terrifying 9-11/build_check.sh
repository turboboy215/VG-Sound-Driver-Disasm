#!/bin/sh
# Assemble each bank, link it over the original ROM and compare.
ROM=${1:-"../Metal Slug 2 (Unl) [C][f1].gbc"}
set -e
objs=""
for b in $(ls MS2_Bank*.asm | sed 's/MS2_Bank\(.*\)\.asm/\1/'); do
	rgbasm -Wall -I ../common -o ms2_$b.o MS2_Bank$b.asm
	objs="$objs ms2_$b.o"
done
rgblink -O "$ROM" -o ms2_rebuilt.gbc $objs
cmp "$ROM" ms2_rebuilt.gbc && echo "OK: byte-exact"
