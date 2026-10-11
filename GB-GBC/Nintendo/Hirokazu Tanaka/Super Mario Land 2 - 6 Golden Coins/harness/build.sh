#!/bin/sh
set -e
cd "$(dirname "$0")"
rgbasm -I ../../common -o harness.o harness.asm
(cd .. && rgbasm -I ../common -o harness/sml2.o SML2_Sound.asm)
rgblink -o harness.gb harness.o sml2.o
rgbfix -v -m 3 -r 2 -p 0 harness.gb
