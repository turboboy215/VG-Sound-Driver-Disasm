#!/bin/sh
# Version 3 (Asterix, Pinocchio, Metal Masters): regenerate, rebuild byte-exact, then run the
# emulator trace check. Needs RGBDS 0.9.1 and pyboy. Run from anywhere; ROMs in the AJG folder.
cd "$(dirname "$0")/.."
mkdir -p verify/build
set -e
build() { # game asm short rom ranges...
  g=$1; asm=$2; short=$3; rom=$4; shift 4
  python3 tools/gen_v3.py $g "$rom" $asm
  rgbasm -Wall -o verify/build/$short.o $asm
  rgblink -o verify/build/$short.gb verify/build/$short.o
  python3 tools/cmp_banked.py verify/build/$short.gb "$rom" "$@"
}
echo "== rebuild"
build asterix Asterix_SoundDriver.asm asterix "Asterix (UE) (M5) [!].gb" 0000-0002 0008-000B 0018-001D 1A90-1A98 3:4A8C-7F1A
build pinocchio Pinocchio_SoundDriver.asm pinocchio "Adventures of Pinocchio, The (J).gb" 0000-0002 0008-000B 0018-001D 0BA4-0BAC 0BE7-0BE8 2:4000-66FC
build metalmasters MetalMasters_SoundDriver.asm metalmasters "Metal Masters (U).gb" 0000-0002 0008-000B 0018-001D 1719-1721 2:5A1C-7544
echo "== emulator trace"
python3 verify/v3trace.py asterix verify/asterix.json "Asterix (UE) (M5) [!].gb" 6000
python3 verify/v3trace.py pinocchio verify/pinocchio.json "Adventures of Pinocchio, The (J).gb" 6000
python3 verify/v3trace.py metalmasters verify/metalmasters.json "Metal Masters (U).gb" 6000
