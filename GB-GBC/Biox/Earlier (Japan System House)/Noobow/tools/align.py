import sys,os,re,difflib
sys.path.insert(0,os.path.dirname(__file__))
from sm83dis import decode
def stream(rom,bank,s,e):
    base=bank*0x4000-0x4000
    m=lambda x: rom[base+x] if 0x4000<=x<0x8000 else rom[x]
    a=s; L=[]
    while a<e:
        n,t,_=decode(m,a)
        L.append((a,re.sub(r'\$[4-7][0-9A-F]{3}','ADDR',t)))
        a+=n
    return L
def amap(romA,bankA,sA,eA,romB,bankB,sB,eB):
    A=stream(romA,bankA,sA,eA); B=stream(romB,bankB,sB,eB)
    sm=difflib.SequenceMatcher(None,[x[1] for x in A],[x[1] for x in B],autojunk=False)
    M={}
    for i,j,n in sm.get_matching_blocks():
        for k in range(n): M[A[i+k][0]]=B[j+k][0]
    return M
