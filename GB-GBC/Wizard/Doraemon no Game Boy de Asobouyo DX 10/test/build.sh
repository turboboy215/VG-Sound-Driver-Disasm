#!/bin/sh
set -e
cd "$(dirname "$0")"
R=${RGBDS:-}
[ -n "$R" ] && R="$R/"
for n in DX10 QuizBoy; do
  sed "s/SOUNDFILE/..\/${n}_sound.asm/" harness.asm > /tmp/h_$n.asm
  ${R}rgbasm -I .. -o /tmp/h_$n.o /tmp/h_$n.asm
  ${R}rgblink -p 0 -n h_$n.sym -o h_$n.gb /tmp/h_$n.o
  ${R}rgbfix -v -m MBC1 -p 0 h_$n.gb
done
