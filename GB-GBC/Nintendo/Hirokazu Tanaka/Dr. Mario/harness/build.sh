#!/bin/sh
set -e
cd "$(dirname "$0")"
rgbasm -I ../../common -o harness.o harness.asm
(cd .. && rgbasm -I ../common -o harness/drm.o DrM_Sound.asm)
rgblink -o harness.gb harness.o drm.o
rgbfix -v -p 0 harness.gb
