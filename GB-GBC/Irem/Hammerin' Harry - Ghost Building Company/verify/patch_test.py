# Builds copies of the ROMs whose spare space holds test streams for features the game data never uses.
import os,sys
sys.path.insert(0,os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),'tools'))
from paths import ROMS,ROOT
VERIFY=os.path.join(ROOT,'verify')+os.sep
import json
def w16(b,o,v): b[o]=v&0xff; b[o+1]=v>>8
# ---------------- Kid Niki: streams at bank 1 $74F4 (unused $FF fill), ids $1F and $1E repointed
kn=bytearray(open(ROMS['kn'],'rb').read())
A=0x74f4; s=[]
def put(lst):
    global A
    a=A
    for x in lst: kn[A]=x; A+=1
    return a
sub2=put([0x1c,0x86])
sub1=put([0x85,sub2&0xff,sub2>>8,0x18,0x86])
ch1=put([0x84,0x12,0x8d,0x34,0x8e,0x55,0x80,0x80,0x83,0xf0,0x92,0x50,0x82,0x20,0x30,0x82,0x00,0x85,sub1&0xff,sub1>>8,0x24,0x86])
ch2=put([0x91,0x83,0xa0,0x20,0x20,0x90,0x20])
ch3=put([0x8c,0x40,0x83,0x20,0x91,0x10,0x8f,0x77,0x87])
ch4=put([0x91,0x83,0x81,0x55]); kn[A]=0x8b; w16(kn,A+1,ch4); A+=3
loop=[put([0xd0,0x10,0x8b,0,0]) for _ in range(4)]
for a in loop: w16(kn,a+3,a)
for k,p in enumerate((ch1,ch2,ch3,ch4)): w16(kn,0x7d00+8*0x1f+2*k,p)
for k,p in enumerate(loop): w16(kn,0x7d00+8*0x1e+2*k,p)
open(VERIFY+'kn_test.gb','wb').write(kn)
pk={'10':[['mus',3]],'60':[['sfx',0x1f]],'400':[['sfx',0x1e]],'700':[['clr','c800','c840']],'701':[['sfx',0x21]],
    '900':[['sfx',0x1f]],'950':[['mus',0x29]],'1300':[['clr','c800','c892']],'1301':[['mus',0x1f]],'1700':[['sfx',0x1e],['mus',4]]}
json.dump(dict(rom='kn_test.gb',pokes=pk,drop_game=True,buttons=[['start',200,100]]),open(VERIFY+'test_kn.json','w'))
# ---------------- Hammerin' Harry: streams at bank 1 $7FBF (65 spare bytes), id $44 repointed
hh=bytearray(open(ROMS['hh'],'rb').read())
A=0x7fbf
def put(lst):
    global A
    a=A
    for x in lst: hh[A]=x; A+=1
    return a
subC=put([0x30,0x86])
subB=put([0x85,subC&0xff,subC>>8,0x86])
subA=put([0x85,subB&0xff,subB>>8,0x86])
c1=put([0x84,0x33,0x83,0xf1,0x80,0x80,0x8d,0x87,0x8e,0x85,0x93,0x60,0x85,subA&0xff,subA>>8,0x87])
c4=put([0x8d,0x83,0x8e,0x82,0x83,0xa1,0x92,0x25,0x25,0x86])
c3=put([0x8d,0x85,0x8e,0x81,0x83,0x20,0x8c,0x20,0x92,0x30,0x86])
assert A<=0x8000, hex(A)
for k,p in enumerate((c1,0x4c54,c3,c4)): w16(hh,0x4a2b+8*0x44+2*k,p)
open(VERIFY+'hh_test.gb','wb').write(hh)
ph={'10':[['mus',4]],'60':[['sfx',0x44]],'300':[['sfx',0x44]],'302':[['sfx',0x12]],'600':[['clr','de00','df00']],'601':[['mus',0x44]],
    '900':[['sfx',0x44],['mus',0x0c]]}
json.dump(dict(rom='hh_test.gb',pokes=ph,drop_game=True,buttons=[['start',200,100]]),open(VERIFY+'test_hh.json','w'))
print('test ROMs written: verify/kn_test.gb, verify/hh_test.gb')
