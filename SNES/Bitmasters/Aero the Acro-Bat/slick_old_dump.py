#!/usr/bin/env python3
"""slick_old_dump.py - dump the data of the OLDER SLICK driver (Aero the Acro-Bat,
1993) from an SPC snapshot: BankTable, sounds, 7-byte track headers, instrument
records ($0500), drum map ($06d0), and a check of every sequence (event counts;
any byte that is not a note/bend/known command is reported).

usage: python3 slick_old_dump.py file.spc
"""
import sys
spc=open(sys.argv[1],'rb').read(); ram=spc[0x100:0x10100]
b=lambda a: ram[a&0xffff]; w=lambda a: b(a)|b(a+1)<<8
def vlq(p):
    v=b(p);p+=1
    if v<0x80: return v,p
    v&=0x7f;c=b(p);p+=1
    if c<0x80: return v<<7|c,p
    d=b(p);p+=1; return v<<14|(c&0x7f)<<7|d,p
stats={}
for e in range(8):
    fid,ptr=b(0x1cab+3*e),w(0x1cac+3*e)
    if fid==0xff: continue
    cnt=b(ptr); print('bank first ID $%02x @%04x count %d'%(fid,ptr,cnt))
    for i in range(cnt):
        h=(ptr+w(ptr+2+2*i))&0xffff
        pl=(h+w(h))&0xffff; npt=b(h+2); ntr=b(h+3); fl=b(h+4); tempo=b(h+5); echo=b(h+6)
        base=pl+2*npt
        print(' sound $%02x @%04x ptrs=%d tracks=%d flags=$%02x tempo=%d echo=%d'%(fid+i,h,npt,ntr,fl,tempo,echo))
        y=7+(12 if echo else 0)
        for t in range(ntr):
            th=[b(h+y+7*t+k) for k in range(7)]
            tf=th[5]|fl
            p=(w(pl+2*th[4])+h)&0xffff
            print('  trk%d vel=%02x pan=%02x prog=%02x prio=%02x idx=%d flags=%02x transp=%02x data=%04x'%(t+1,*th,p))
            lp=p
            if tf&4:
                p=(w(lp)+base+1)&0xffff
            d,p=vlq(p); n=0
            for _ in range(3000):
                c=b(p);p+=1
                if c<0xc0:
                    if not tf&1: p+=1
                    g,p=vlq(p); k='note'
                elif c<0xe0: p+=1; k='bend'
                else:
                    k='E%X'%(c&15) if c>=0xe0 else '?'
                    if c in(0xe1,0xeb,0xe3,0xe8): pass
                    elif c==0xe2: 
                        if b(p)==0: p+=1
                        else: stats['E2']=stats.get('E2',0)+1; break
                    elif c in(0xe6,0xe7): p+=1
                    elif c in(0xe9,0xea): p+=2
                    else: k='ILLEGAL%02x'%c
                    if c==0xe3: stats['E3']=stats.get('E3',0)+1; break
                    if c==0xe8:
                        lp+=2; n+=1
                        if n>200: break
                        p=(w(lp)+base+1)&0xffff
                stats[k]=stats.get(k,0)+1
                d,p=vlq(p)
print('\nsequence event counts:', stats)
bad=[k for k in stats if k.startswith('ILLEGAL')]
print('unknown bytes:', bad if bad else 'none')
print('\ninstruments ($0500, 8 bytes: SRCN ADSR1 ADSR2 flags transp fine flags2 veltrem):')
for i in range(58):
    r=ram[0x500+8*i:0x508+8*i]
    if r[0]!=0xff: print('  %02x: %s'%(i,' '.join('%02x'%x for x in r)))
print('\ndrum map ($06d0: instrument, key, flags):')
for z in range(16):
    r=ram[0x6d0+3*z:0x6d3+3*z]; print('  zone %2d: %s'%(z,' '.join('%02x'%x for x in r)))
