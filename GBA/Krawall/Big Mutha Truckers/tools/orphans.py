import sys,json,struct
sys.path.insert(0,__import__('os').path.dirname(__file__))
from kverify import decode_pattern
rom=open(sys.argv[1],'rb').read(); scan=json.load(open(sys.argv[2])); old=sys.argv[3]=='old'
pk='new' if not old else 'old_be'
nsamp=scan['sampleList']['count']
owned=set(p for m in scan['modules'] for p,_ in m['patterns'])
found=[]
for o in range(0,len(rom)-0x40,4):
    if rom[o] or rom[o+1]: continue
    rows = rom[o+32] if old else struct.unpack_from('<H',rom,o+32)[0]
    if rows!=64: continue
    idx=struct.unpack_from('<16H',rom,o)
    n=16
    if any(idx[k]<=idx[k-1] for k in range(1,n)): continue
    if n>1 and idx[1]>rows*0x80: continue
    try: d=decode_pattern(rom,o,old,nsamp,pk)
    except Exception: continue
    if d['bad']==0 and len(d["cells"])>=24: found.append(o)
orph=[o for o in found if o not in owned]
print(sys.argv[1],'valid patterns',len(found),'owned',len(owned),'orphans',len(orph),[hex(x) for x in orph[:20]])
