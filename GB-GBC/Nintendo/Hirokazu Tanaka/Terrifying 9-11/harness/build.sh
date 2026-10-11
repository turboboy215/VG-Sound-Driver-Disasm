#!/bin/sh
set -e
cd "$(dirname "$0")"
rgbasm -I ../../common -o harness.o harness.asm
objs=""
for b in $(cd .. && ls MS2_Bank*.asm | sed 's/MS2_Bank\(.*\)\.asm/\1/'); do
	(cd .. && rgbasm -I ../common -o harness/ms2_$b.o MS2_Bank$b.asm)
	objs="$objs ms2_$b.o"
done
rgblink -o harness.gb harness.o $objs
rgbfix -v -m 0x19 -p 0 harness.gb
