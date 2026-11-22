# Reassemble both .asm files and compare them with the ROMs.
# usage: python agenda_verify.py [dora2|poko]
import sys, subprocess, os, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from agenda_cfg import load
from agenda_cfg import ROOT
RG=os.environ.get('RGBDS','')   # folder holding rgbasm/rgblink, or empty to use PATH
if RG and not RG.endswith(os.sep): RG+=os.sep
TMP=tempfile.gettempdir()
def build(g, asm):
    o=os.path.join(TMP,'%s.o'%g); out=os.path.join(TMP,'%s.gb'%g)
    r=subprocess.run([RG+'rgbasm','-I',ROOT,'-o',o,asm],capture_output=True,text=True)
    if r.returncode: print(r.stderr[:3000]); return None
    r=subprocess.run([RG+'rgblink','-p','0xFF','-o',out,o],capture_output=True,text=True)
    if r.returncode: print(r.stderr[:3000]); return None
    return open(out,'rb').read()
for g,asm in (('dora2','Doraemon2_sound.asm'),('poko','Pokonyan_sound.asm')):
    if len(sys.argv)>1 and g not in sys.argv[1:]: continue
    c=load(g); d=build(g,os.path.join(ROOT,asm))
    if d is None: continue
    off=c['bank']*0x4000
    mism=[a for a in range(c['start'],c['end']) if d[off+a-0x4000]!=c['bin'][off+a-0x4000]]
    print(g,'bytes',c['end']-c['start'],'mismatches',len(mism),[hex(x) for x in mism[:10]])
