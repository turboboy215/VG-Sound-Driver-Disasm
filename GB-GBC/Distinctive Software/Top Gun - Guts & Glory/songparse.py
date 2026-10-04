"""Stream walker for the Distinctive/Radical 'MIDI-style' GB music format.
Usage: songparse.py rom bank trackptr variant(bo|tg)"""
import sys
def rd(d,bank,a): return d[a] if a<0x4000 else d[bank*0x4000+a-0x4000]
def varlen(d,bank,p):
    a=rd(d,bank,p); p+=1
    if a&0x80:
        a=(((a&0x7f)>>1)|((a&1)<<7)); a=(a+rd(d,bank,p))&0xff; p+=1   # faithful: rrca then add (8-bit!)
    return a,p
def walk(d,bank,p,var,maxev=4000,verbose=False):
    ev=[];stats={}
    for _ in range(maxev):
        dl,p=varlen(d,bank,p); e=rd(d,bank,p); p+=1
        stats[e if e>=0xd9 else 'note']=stats.get(e if e>=0xd9 else 'note',0)+1
        if e<0xd9:
            vel=None
            if e&0x80: vel=rd(d,bank,p); p+=1
            prm,p=varlen(d,bank,p); ev.append((dl,'note',e&0x7f,vel,prm))
            continue
        if var=='bo':
            if e in (0xd9,0xda,0xdb,0xe3,0xea): ev.append((dl,'cmd%02X'%e)); return ev,stats,p,'end'
            if e in (0xdc,0xdf): a=rd(d,bank,p)|rd(d,bank,p+1)<<8; p+=2; ev.append((dl,'cmd%02X'%e,a)); continue
            if e in (0xdd,0xde,0xe2): ev.append((dl,'cmd%02X'%e,rd(d,bank,p))); p+=1; continue
            return ev,stats,p,'UNKNOWN %02X'%e
        else:
            if e in (0xd9,0xda,0xdb): ev.append((dl,'cmd%02X'%e)); return ev,stats,p,'end'
            if e==0xe3: ev.append((dl,'cmdE3')); continue
            if e in (0xdc,0xdd,0xde,0xe2): ev.append((dl,'cmd%02X'%e,rd(d,bank,p))); p+=1; continue
            ev.append((dl,'cmd%02X'%e,rd(d,bank,p+1))); p+=2   # DF and any other: 2 bytes, 2nd kept
            continue
    return ev,stats,p,'maxev'

def varlen_ww(d,bank,p):
    a=rd(d,bank,p); p+=1
    if a&0x80:
        hi=(a&0x7f)>>1; lo=(((a&1)<<7)+rd(d,bank,p))&0xff; p+=1
        return hi<<8|lo,p
    return a,p
def walk_ww(d,bank,p,maxev=4000):
    ev=[];stats={}
    for _ in range(maxev):
        dl,p=varlen_ww(d,bank,p); e=rd(d,bank,p); p+=1
        stats[e if e>=0xd9 else 'note']=stats.get(e if e>=0xd9 else 'note',0)+1
        if e<0xd9:
            vel=None
            if e&0x80: vel=rd(d,bank,p); p+=1
            prm,p=varlen_ww(d,bank,p); ev.append((dl,'note',e&0x7f,vel,prm)); continue
        if e in (0xd9,0xda,0xdb,0xe3,0xea):
            ev.append((dl,'cmd%02X'%e))
            if e!=0xe3 or True: return ev,stats,p,'end'
        if e in (0xdc,0xdf): a=rd(d,bank,p)|rd(d,bank,p+1)<<8; p+=2; ev.append((dl,'cmd%02X'%e,a)); continue
        if e in (0xdd,0xde,0xe2): ev.append((dl,'cmd%02X'%e,rd(d,bank,p))); p+=1; continue
        return ev,stats,p,'UNKNOWN %02X'%e
    return ev,stats,p,'maxev'
