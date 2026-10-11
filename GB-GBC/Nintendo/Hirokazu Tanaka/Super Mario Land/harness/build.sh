#!/bin/sh
set -e
cd "$(dirname "$0")"
rgbasm -I ../../common -o harness.o harness.asm
(cd .. && rgbasm -I ../common -o harness/sml.o SML_Sound.asm)
rgblink -o harness.gb harness.o sml.o
rgbfix -v -m 1 -p 0 harness.gb
