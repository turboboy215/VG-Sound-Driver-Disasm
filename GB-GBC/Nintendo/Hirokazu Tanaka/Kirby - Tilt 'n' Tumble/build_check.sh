#!/bin/sh
# Assemble each bank, link it over the original ROM and compare.
ROM=${1:-"../Kirby's Tilt 'n' Tumble (U) [C][!].gbc"}
set -e
objs=""
for b in $(ls KTT_Bank*.asm KTT_Home.asm 2>/dev/null | sed 's/KTT_\(.*\)\.asm/\1/'); do
	rgbasm -Wall -I ../common -o ktt_$b.o KTT_$b.asm
	objs="$objs ktt_$b.o"
done
rgblink -O "$ROM" -o ktt_rebuilt.gbc $objs
cmp "$ROM" ktt_rebuilt.gbc && echo "OK: byte-exact"
