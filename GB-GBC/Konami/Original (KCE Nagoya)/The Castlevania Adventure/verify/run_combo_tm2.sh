#!/bin/sh
cd "$(dirname "$0")/.."
V="python3 verify/vmodel4.py"
# A: bank-15 song with bank-14 SFX on CH1 (Sfx1), CH3 (Sfx2) and CH4 (blocking, restore, the long-note
# retrigger), pause and unpause, a fade (wFadeRate = 4) to the end, a PCM voice over a song, StopAll, the
# song with the mis-nested loop
$V 10000 'D9@30,10@500,4C@900,12@1300,1E@1700,!C794=01@2500,!C794=00@3000,!C0D4=04@4000,E4@5000,9A@5600,20@6500,0@8000,DA@8100' 2>&1 | grep -v SDL
# B: jingles of bank 14 (the vibrato that reads echo RAM in $41), all-track jingles, looping SFX on all
# three SFX tracks, the $9E special end, the other PCM voices
$V 10000 'CE@30,41@1000,0E@2000,E6@3000,9E@4000,64@5000,99@6000,7C@7000,9B@8000,9C@8600,9D@9200' 2>&1 | grep -v SDL
# C: songs with tempo, drum hits on SfxN against noise SFX, priority refusals (a lower-priority SFX while
# a higher one holds Sfx1: nothing starts), autopan songs
$V 10000 'D0@30,63@400,6F@450,29@800,10@820,F2@1200,E1@3000,8A@3100,79@3200,E8@6000,16@6100,73@6500' 2>&1 | grep -v SDL
