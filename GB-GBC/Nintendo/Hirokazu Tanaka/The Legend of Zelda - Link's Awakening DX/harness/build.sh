#!/bin/sh
set -e
cd "$(dirname "$0")"
rgbasm -I ../../common -o harness.o harness.asm
objs=""
for b in $(cd .. && ls LA_Bank*.asm | sed 's/LA_Bank\(.*\)\.asm/\1/'); do
	(cd .. && rgbasm -I ../common -o harness/la_$b.o LA_Bank$b.asm)
	objs="$objs la_$b.o"
done
if [ ! -f ../LA_Bank1F.asm ]; then   # SFX bank not generated: use the original bytes
	printf 'SECTION "sfx", ROMX[$4000], BANK[$1F]\nINCBIN "%s", $7C000, $4000\n' "../../Legend of Zelda, The - Link's Awakening DX (U) (V1.0) [C][!].gbc" > sfxbin.asm
	rgbasm -o sfxbin.o sfxbin.asm; objs="$objs sfxbin.o"
fi
rgblink -o harness.gb harness.o $objs
rgbfix -v -m 0x19 -p 0 harness.gb
