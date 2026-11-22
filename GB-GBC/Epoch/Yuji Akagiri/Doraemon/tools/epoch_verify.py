"""Assembles both .asm files (run from the folder holding them) and compares
them with the ROMs."""
import subprocess,sys
import os
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from epoch_cfg import load
for k,f in [('ds','DragonSlayer_sound'),('dora','Doraemon_sound')]:
  r=subprocess.run(f'rgbasm -o {f}.o {f}.asm && rgblink -p 0xFF -o {f}.gb {f}.o',shell=True,capture_output=True,text=True)
  print(k,r.returncode,r.stderr[:3000])
  if r.returncode: continue
  g=load(k); out=open(f'{f}.gb','rb').read()
  s,e=g['start'],g['end']
  off = 0 if g['bank']<=1 else g['bank']*0x4000-0x4000
  a=out[off+s:off+e]; b=g['rd'](s,e-s)
  mm=[i for i in range(len(b)) if i>=len(a) or a[i]!=b[i]]
  print(k,'bytes',len(b),'mismatch',len(mm), [hex(s+i) for i in mm[:10]])
