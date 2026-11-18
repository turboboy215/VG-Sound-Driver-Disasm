# build the test harness ROM: bank 0 = harness.asm, bank 4 = ../CosmoTank_SoundDriver.asm
# RGBDS = folder with rgbasm/rgblink/rgbfix (default: on PATH)
set -e
cd "$(dirname "$0")"
R=${RGBDS:+$RGBDS/}
${R}rgbasm -Wall -I .. -o harness.o harness.asm
${R}rgbasm -Wall -I .. -o driver.o ../CosmoTank_SoundDriver.asm
${R}rgblink -o harness.gb harness.o driver.o
${R}rgbfix -v -m 0x01 -p 0xFF harness.gb
