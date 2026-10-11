#!/bin/sh
set -e
cd "$(dirname "$0")"
rgbasm -I ../../common -o harness.o harness.asm
objs=""
for b in $(cd .. && ls SMB_Bank*.asm | sed 's/SMB_Bank\(.*\)\.asm/\1/'); do
	(cd .. && rgbasm -I ../common -o harness/smb_$b.o SMB_Bank$b.asm)
	objs="$objs smb_$b.o"
done
rgblink -o harness.gb harness.o $objs
rgbfix -v -m 0x19 -p 0 harness.gb
