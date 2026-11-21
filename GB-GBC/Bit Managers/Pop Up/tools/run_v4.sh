#!/bin/sh
# Version 4 (The Smurfs, Asterix & Obelix GB and GBC, Tintin in Tibet, Tintin: Prisoners of the Sun,
# Spirou, Lucky Luke, The Smurfs' Nightmare, Die Maus, Hugo 2, Turok, Turok 2, Otto's Ottifanten,
# Sea Battle, V-Rally GB and GBC, Sylvester and Tweety, Bugs Bunny & Lola Bunny): regenerate, rebuild byte-exact, then run the emulator trace check.
# Needs RGBDS 0.9.1 and pyboy. Run from anywhere; ROMs in the AJG folder.
cd "$(dirname "$0")/.."
mkdir -p verify/build
set -e
build() { # game asm short rom bank
  g=$1; asm=$2; short=$3; rom=$4; bank=$5
  python3 tools/gen_v4.py $g "$rom" $asm
  rgbasm -Wall -o verify/build/$short.o $asm
  rgblink -o verify/build/$short.gb verify/build/$short.o
  python3 tools/cmp_banked.py verify/build/$short.gb "$rom" $bank:4000-7FFF
}
GAMES="smurfs:Smurfs_SoundDriver.asm:Smurfs, The (UE) (V1.0) (M4) [!].gb:6
obelixgb:ObelixGB_SoundDriver.asm:Obelix (E) (M2) (Eng-Spa) [S][!].gb:6
obelixgbc:ObelixGBC_SoundDriver.asm:Obelix (E) (M4) [C][!].gbc:6
tibet:TintinTibet_SoundDriver.asm:Tintin in Tibet (E) (M4) (Eng-Fre-Ger-Dut) [S].gb:15
sun:TintinSun_SoundDriver.asm:Les Aventures De TinTin - Le Temple du Soleil (E) (M3) [M].gb:15
spirou:Spirou_SoundDriver.asm:Spirou (E) (M4) [S][!].gb:15
luckyluke:LuckyLuke_SoundDriver.asm:Lucky Luke (E) (M4) [M].gb:12
smurfs3:Smurfs3_SoundDriver.asm:Smurfs 3, The (E) (M4) [!].gb:2
maus:Maus_SoundDriver.asm:Maus, Die (E) (M4) [M].gb:15
hugo2:Hugo2_SoundDriver.asm:Hugo 2 (G) [S][!].gb:7
turok:Turok_SoundDriver.asm:Turok - Battle of the Bionosaurs (UE) (M4) [!].gb:15
turok2:Turok2_SoundDriver.asm:Turok 2 - Seeds of Evil (U) (M4) [C][!].gbc:15
otto:Otto_SoundDriver.asm:Otto's Ottifanten (E).gb:3
seabattle:SeaBattle_SoundDriver.asm:Sea Battle (E) (M4).gb:4
vrally:VRallyGB_SoundDriver.asm:V-Rally - Championship Edition (U) (M3) [M][!].gb:2
vrallygbc:VRallyGBC_SoundDriver.asm:V-Rally - Championship Edition (E) (M4) [C][!].gbc:16
sylvester:Sylvester_SoundDriver.asm:Sylvester and Tweety (E) (M6) [C][!].gbc:15
bugs:BugsBunny_SoundDriver.asm:Bugs Bunny & Lola Bunny - Operation Carrots (E) (M6) [C][!].gbc:2"
echo "== rebuild"
echo "$GAMES" | while IFS=: read g asm rom bank; do build $g $asm $g "$rom" $bank; done
echo "== emulator trace"
echo "$GAMES" | while IFS=: read g asm rom bank; do python3 verify/v4trace.py verify/$g.json "$rom" 6000; done
