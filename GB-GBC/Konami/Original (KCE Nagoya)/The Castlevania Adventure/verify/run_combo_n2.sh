#!/bin/sh
cd "$(dirname "$0")/.."
V="python3 verify/vmodel3.py n2"
# A: bank-14 song with bank-13 SFX on top (CH1/CH2 blocking + restore, drum hits vs noise SFX), the
# refused-track pointer bug ($5C holds Sfx2, $12 arrives after Sfx1 ended: SfxN gets the Sfx2 stream),
# pause with $5D, music fade (wFadeReq = 1) through all steps, $96 (stop + play), $56 not restarted
$V 12000 '8F@30,0E@400,12@700,13@1200,1C@1600,5C@2000,12@2170,2A@2600,!C794=01@3000,5D@3001,!C794=00@3400,!C0CB=01@4000,90@6000,96@7500,56@8000,56@8010,55@8100,4A@8500,51@9500,32@10000,0@11000,D2@11010' 2>&1 | grep -v SDL
# B: bank-15 songs (fade pairing swapped, no fade attenuation on tone channels) with SFX, a fade, songs
# with tempo changes and the mis-nested loops of $D6/$D7
$V 12000 'CE@30,1A@300,19@500,2B@900,53@1500,!C0CB=01@2000,D6@4000,1D@4300,20@4500,D7@6000,48@6200,3D@6600,D0@8000,!C0CB=01@8200,95@10000,17@10200' 2>&1 | grep -v SDL
# C: raw streams ($27, $5D) over music, SFX refused by higher-priority SFX, drum-only SFX vs music drums
$V 9000 '91@30,27@200,5D@400,27@410,3D@800,0F@820,10@840,0B@1000,03@1010,94@3000,59@3100,58@3110,57@3120,D9@6000,27@6100,1C@6200' 2>&1 | grep -v SDL
