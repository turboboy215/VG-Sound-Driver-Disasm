#!/bin/sh
# Model vs emulator for every song and sound effect, plus mixed scenarios. Needs: pip install pyboy
cd "$(dirname "$0")"
[ -f popup_harness.gb ] && [ -f bombjack_harness.gb ] || python3 build_harness.py
echo "== Pop Up"
for s in 0:1 0:2 0:6; do python3 vmodel.py popup $s 8000 --quiet 2>&1 | grep -v -i warn | tail -1; done
for i in 1 2 3 4 5 6 7; do python3 vmodel.py popup 0:5,1:3:$i 2000 --quiet 2>&1 | grep -v -i warn | tail -1; done
python3 vmodel.py popup 0:1,300:3:1,320:3:2,700:3:5,1500:3:7,1600:3:3,2600:4,2700:2,2900:3:6,3500:3:4,5000:1,6000:6,6100:3:5 7000 --quiet 2>&1 | grep -v -i warn | tail -1
python3 vmodel.py popup 0:2,100:3:3,104:3:3,500:3:1,900:4,950:3:2,1000:1,1010:3:7 4000 --quiet 2>&1 | grep -v -i warn | tail -1
echo "== Bomb Jack"
for s in 0:1 0:2 0:8 0:9 0:10; do python3 vmodel.py bombjack $s 9000 --quiet 2>&1 | grep -v -i warn | tail -1; done
for i in $(seq 1 14); do python3 vmodel.py bombjack 1:3:$i 1500 --quiet 2>&1 | grep -v -i warn | tail -1; done
python3 vmodel.py bombjack 0:9,200:3:9,260:3:12,262:3:13,600:3:1,900:3:5,903:3:2,1400:11:3,1800:3:14,2000:10,2300:3:11,2600:4,2700:8,3000:3:7,3500:12:1,3510:13:200,3520:3:1,3700:3:4,3900:3:6,4100:13:40,4110:3:8,4500:11:0,4700:6,5200:3:3 7000 --quiet 2>&1 | grep -v -i warn | tail -1
python3 vmodel.py bombjack 0:1,50:3:10,51:3:11,52:3:9,400:3:13,800:7,1200:3:5,1500:11:5,2500:3:14,2501:3:2 5000 --quiet 2>&1 | grep -v -i warn | tail -1
python3 vmodel.py bombjack 0:10,10:12:1,20:13:0,30:3:4,300:13:255,310:3:1,600:12:0,700:3:4,1000:11:2,1300:4,1310:3:6,1320:3:6 3000 --quiet 2>&1 | grep -v -i warn | tail -1
python3 vmodel.py bombjack 0:14,1500:14,1600:3:5,2000:14 3000 --quiet 2>&1 | grep -v -i warn | tail -1
