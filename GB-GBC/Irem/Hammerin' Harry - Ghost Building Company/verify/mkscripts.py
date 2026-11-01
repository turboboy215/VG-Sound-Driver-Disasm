import os,sys
sys.path.insert(0,os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),'tools'))
from paths import ROMS,ROOT
VERIFY=os.path.join(ROOT,'verify')+os.sep
import json
def each(g,nids,clr,mus_len=2500,sfx_len=600):
    pokes={}; u=50
    for i in range(1,nids):
        for setn,ln in (('sfx',sfx_len),('mus',mus_len)):
            pokes.setdefault(str(u),[]).append(['clr']+clr)
            pokes.setdefault(str(u+1),[]).append([setn,i])
            u+=ln
    return dict(pokes=pokes,drop_game=True,buttons=[['start',200,100]],progress=1),u
def combo(g,nids,clr,seed):
    import random; R=random.Random(seed); pokes={}; u=50
    while u<12000:
        k=R.random()
        if k<0.15: pokes.setdefault(str(u),[]).append(['mus',R.randrange(1,nids)])
        elif k<0.75: pokes.setdefault(str(u),[]).append(['sfx',R.randrange(1,nids)])
        elif k<0.8: pokes.setdefault(str(u),[]).append(['clr']+clr)
        u+=R.choice([3,10,30,60,120,300])
    return dict(pokes=pokes,drop_game=False,buttons=[['start',200,100],['a',37,5],['right',23,3],['b',91,40]],progress=1),u
for g,n,clr in (('kn',32,['c800','c892']),('hh',69,['de00','df00'])):
    s,u=each(g,n,clr); json.dump(s,open(VERIFY+'each_%s.json'%g,'w')); print(g,'each',u)
    for seed in (1,2,3):
        s,u=combo(g,n,clr,seed); json.dump(s,open(VERIFY+'combo%d_%s.json'%(seed,g),'w'))
