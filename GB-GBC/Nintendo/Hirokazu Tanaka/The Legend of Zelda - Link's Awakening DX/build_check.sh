#!/bin/sh
# Assemble each bank, link it over the original ROM and compare.
ROM=${1:-"../Legend of Zelda, The - Link's Awakening DX (U) (V1.0) [C][!].gbc"}
set -e
objs=""
for b in $(ls LA_Bank*.asm | sed 's/LA_Bank\(.*\)\.asm/\1/'); do
	rgbasm -Wall -I ../common -o la_$b.o LA_Bank$b.asm
	objs="$objs la_$b.o"
done
rgblink -O "$ROM" -o la_rebuilt.gbc $objs
cmp "$ROM" la_rebuilt.gbc && echo "OK: byte-exact"
