#!/bin/sh
# Assemble each bank, link it over the original ROM and compare.
ROM=${1:-"../Super Mario Bros. Deluxe (U) (V1.0) [C][!].gbc"}
set -e
objs=""
for b in $(ls SMB_Bank*.asm | sed 's/SMB_Bank\(.*\)\.asm/\1/'); do
	rgbasm -Wall -I ../common -o smb_$b.o SMB_Bank$b.asm
	objs="$objs smb_$b.o"
done
rgblink -O "$ROM" -o smb_rebuilt.gbc $objs
cmp "$ROM" smb_rebuilt.gbc && echo "OK: byte-exact"
