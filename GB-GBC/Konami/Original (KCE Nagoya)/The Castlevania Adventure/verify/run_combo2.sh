#!/bin/sh
cd "$(dirname "$0")/.."
V="python3 verify/vmodel2.py"
# Nemesis A: blocking + restore on CH1/CH2, noise SFX vs drums, $0F no-restart, pause jingle, fade to a
# sound, lockout ($2E refuses $0A, $13 passes), fade to StopAll, follow-ups $37->$34, $21->$36, $14->$34/$33
$V nem 9000 '33@30,0A@400,12@700,1B@1000,22@1300,0F@1500,0F@1510,!C013=01@1700,2C@1701,!C013=00@2000,!C1B6=34@2200,2E@3000,0A@3010,13@3020,0A@3500,!C1B6=01@3600,37@4000,21@6000,0@6500,!C081=02@6590,14@6600,!C081=00@7400,14@7500,0@8800' 2>&1 | grep -v SDL
# Nemesis B: other songs and SFX mixes, chained lockouts $30/$31/$32
$V nem 9000 '25@30,1D@600,2D@1000,08@1100,09@1150,2A@1200,2B@1500,16@1800,0D@2000,38@2500,1C@2600,28@2700,06@2800,39@3500,30@4500,24@4600,31@5100,32@5600,24@5700,35@6200,36@7000,26@7600,15@8000,13@8300' 2>&1 | grep -v SDL
# Belmont's Revenge A: blocking + restore, three SFX tracks, refused request leaving wReqRefused set (next
# SfxN-only request aborts), pause jingle, fade to a sound, fade with no target
$V cv2 9000 '56@30,07@300,16@600,4A@900,08@1500,0F@2000,08@2010,08@2030,!C88B=01@2500,06@2501,!C88B=00@2800,!C0C8=D5@3000,!C0C8=80@4500,2A@5000,13@5300,09@5400,0@6000,31@6100,5B@6500,0@8000,6B@8100' 2>&1 | grep -v SDL
# Belmont's Revenge B: more songs with SFX on top
$V cv2 9000 '5C@30,0B@200,0D@300,12@400,19@500,27@600,38@700,45@800,47@900,52@1000,60@2000,1A@2100,4B@2200,51@2300,62@4000,11@4100,2E@4200,69@6000,21@6100,3A@6200,6A@7500,43@7600' 2>&1 | grep -v SDL
