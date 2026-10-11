#!/bin/sh
set -e
cd "$(dirname "$0")"
rgbasm -I ../../common -o harness.o harness.asm
(cd .. && rgbasm -I ../common -o harness/ta_home.o TA_Home.asm && rgbasm -I ../common -o harness/ta_07.o TA_Bank07.asm && rgbasm -I ../common -o harness/ta_08.o TA_Bank08.asm)
rgblink -o harness.gb harness.o ta_home.o ta_07.o ta_08.o
rgbfix -v -m 1 -p 0 harness.gb
