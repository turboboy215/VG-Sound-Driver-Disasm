import os
# Align the Pokonyan driver code to the Doraemon 2 code (instruction level)
import sys, re, difflib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from agenda_cfg import load
from trace import trace
def code_of(g):
    c=load(g); w=c['w']
    ent=[c['jumptab']+3*i for i in range(7)]+[w(c['cmd_tab']+2*i) for i in range(24)]
    return c, trace(c['bin'],c['bank'],ent)
def norm(t): return re.sub(r'\$[0-9A-F]{4}','ADDR',re.sub(r'\$FF[89AB][0-9A-F]','HRAM',t)).replace('$DD','$C1')
def align():
    _,dc=code_of('dora2'); _,pc=code_of('poko')
    a=sorted(dc); b=sorted(pc)
    sm=difflib.SequenceMatcher(None,[norm(dc[x][0]) for x in a],[norm(pc[x][0]) for x in b],autojunk=False)
    m={}
    for tag,i1,i2,j1,j2 in sm.get_opcodes():
        if tag=='equal' or (tag=='replace' and i2-i1==j2-j1):
            for k in range(i2-i1): m[a[i1+k]]=b[j1+k]
    return m
if __name__=='__main__':
    m=align(); print(len(m))
    for d in (0x41F5,0x4244,0x45F4,0x487A,0x491A,0x4824,0x485B): print('%04X -> %s'%(d, '%04X'%m[d] if d in m else '-'))
