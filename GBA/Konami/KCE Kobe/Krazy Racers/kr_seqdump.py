#!/usr/bin/env python3
"""kr_seqdump.py - decoder for the Krazy Racers (GBA) KCE Kobe sound driver data.
usage: python3 kr_seqdump.py "Krazy Racers (E).gba" [out.txt]
Decodes all 397 sound-table entries with the PSG / drum / noise-SFX / PCM interpreters,
tracking the stateful opcodes (BE fixed length, FB/FC loops, FD call/return, FE loop point)."""
import struct,sys
from collections import Counter,defaultdict
import os
ROM=sys.argv[1] if len(sys.argv)>1 else 'Krazy Racers (E).gba'
d=open(ROM,'rb').read()
B=0x08000000
def u8(a): return d[a-B]
def u16(a): return struct.unpack_from('<H',d,a-B)[0]
def u32(a): return struct.unpack_from('<I',d,a-B)[0]
SNDTAB=0x080596DC; NSND=397
CHBITS=[(0x1,'ch00','psg','SQ1'),(0x2,'ch11','psg','SQ2'),(0x4,'ch22','psg','WAVE'),(0x8,'ch34','drum','DRUM'),
        (0x10,'ch40','psg','SQ1-SFX'),(0x20,'ch52','psg','WAVE-SFX'),(0x40,'ch63','noise','NOISE-SFX'),
        (0x80,'ch80','pcm','PCM0'),(0x100,'ch81','pcm','PCM1'),(0x200,'ch82','pcm','PCM2'),(0x400,'ch83','pcm','PCM3'),
        (0x800,'dyn','pcm','PCM2/3*'),(0x1000,'dyn','pcm','PCM2/3*')]
NOTES=['C','C#','D','D#','E','F','F#','G','G#','A','A#','B']
def notename(n,t='psg'):
    if n==0: return 'rest'
    if t=='psg': return '%s%d'%(NOTES[(n-1)%12],(n-1)//12+2)
    return '#%d'%n
opstat=Counter()
def sound_entries():
    out=[]
    for i in range(NSND):
        a=SNDTAB+36*i
        b0=u8(a); mask=u16(a+2); ptrs=[u32(a+4+4*k) for k in range(9)]
        chans=[];k=0
        for bit,nm,typ,lab in CHBITS:
            if mask&bit: chans.append((bit,nm,typ,lab,ptrs[k])); k+=1
        out.append(dict(id=i+1,addr=a,prio=b0&0x7f,music=bool(b0&0x80),b1=u8(a+1),mask=mask,chans=chans))
    return out

def decode_track(start,typ,is_sub=False,maxlen=20000):
    """returns list of (addr, bytes, text) and set of subroutine indices called"""
    lines=[];calls=set()
    p=start; fixed=False; fixlen=None; loopA=False; loopB=False; segno=False
    cmdmin={'psg':0x61,'drum':0xB9,'noise':0xC0,'pcm':0xBE}[typ]
    n=0
    while n<maxlen:
        n+=1
        a=p; b=u8(p)
        def emit(k,txt):
            nonlocal p
            lines.append((a,d[a-B:a-B+k].hex(' '),txt)); p+=k
        if b<cmdmin:
            # note
            if typ=='noise':
                emit(1,'NR43=%02X'%b); opstat[(typ,'note')]+=1; continue
            if typ=='pcm':
                if fixed: emit(1,'note %-6s (len %d)'%(notename(b,typ),fixlen))
                else:
                    ln=(u8(p+1)<<8)|u8(p+2); emit(3,'note %-6s len %d'%(notename(b,typ),ln))
            else:
                nm=notename(b,'psg' if typ=='psg' else 'drum')
                if typ=='drum' and b: nm='#%d -> snd %d'%(b,u16(0x0805deb0+2*(b-1)))
                if fixed: emit(1,'note %-6s (len %d)'%(nm,fixlen))
                else: emit(2,'note %-6s len %d'%(nm,u8(p+1)))
            opstat[(typ,'note')]+=1
            continue
        opstat[(typ,b if typ!='psg' or b>=0x61 else 'x')]+=1
        if typ=='pcm' and b<=0xFA and b>=0xBE:
            # PCM table
            if b==0xBE:
                if not fixed:
                    fixlen=(u8(p+1)<<8)|u8(p+2); fixed=True; emit(3,'FIXLEN on, len %d'%fixlen)
                else: fixed=False; emit(1,'FIXLEN off')
            elif b==0xBF: emit(1,'REPEAT last note')
            elif b<=0xD8:
                k=b-0xC0; emit(1,'VOL L=%d R=%d'%(k//5,k%5))
            elif b==0xD9: emit(2,'KIT %d'%u8(p+1))
            elif b==0xDA: emit(2,'BIAS res %d'%u8(p+1))
            elif b==0xDB: emit(2,'TEMPO %d'%u8(p+1))
            elif b<=0xEF:
                idx=b-0xDC; rl=u16(0x08059674+2*idx); emit(1,'RATE %d (%.0f Hz)'%(idx,16777216/64/(65536-rl)))
            else: emit(1,'nop')
            continue
        if b>=0xFB:
            if b==0xFB:
                if not loopA: loopA=True; emit(1,'LOOP_A start')
                else: loopA=False; emit(2,'LOOP_A end x%d'%u8(p+1))
            elif b==0xFC:
                if not loopB: loopB=True; emit(1,'LOOP_B start')
                else: loopB=False; emit(2,'LOOP_B end x%d'%u8(p+1))
            elif b==0xFD:
                if is_sub: emit(1,'RETURN'); break
                idx=u8(p+1); calls.add(idx); emit(2,'CALL sub %d'%idx)
            elif b==0xFE:
                if not segno: segno=True; emit(1,'SEGNO (loop point)')
                else: emit(1,'JUMP to SEGNO (loop forever)'); break
            elif b==0xFF: emit(1,'END'); break
            continue
        # psg table handlers (also drum/noise)
        if 0x61<=b<=0x6C: emit(1,'TRANSPOSE +%d'%(b&0xF))
        elif b in(0x6D,0x6E,0x6F) or 0x98<=b<=0x9F or b==0xA8 or 0xAC<=b<=0xAF or 0xB7<=b<=0xBC or 0xD7<=b<=0xDE or 0xE4<=b<=0xFA:
            emit(1,'nop')
        elif 0x70<=b<=0x7C: emit(1,'TRANSPOSE -%d'%(b&0xF))
        elif b==0x7D: emit(2,'DETUNE %d'%u8(p+1))
        elif b==0x7E:
            v=u8(p+1)
            if v: emit(3,'PITCHENV %d delay %d'%(v,u8(p+2)))
            else: emit(2,'PITCHENV off')
        elif b==0x7F: emit(2,'WAVE %d'%u8(p+1))
        elif 0x80<=b<=0x8F: emit(1,'WAVE %d'%(b&0xF))
        elif 0x90<=b<=0x93: emit(1,'DUTY %d'%(b&3))
        elif b==0x94: emit(2,'SWEEP %02X'%u8(p+1))
        elif b==0x95:
            if fixed: emit(1,'ENGINE-PITCH note (len %d)'%fixlen)
            else: emit(2,'ENGINE-PITCH note len %d'%u8(p+1))
        elif b==0x96: emit(3,'GATE %d ENV %02X'%(u8(p+1),u8(p+2)))
        elif b==0x97: emit(2,'AUTODECAY %02X'%u8(p+1))
        elif 0xA0<=b<=0xAB: emit(1,'PITCHENV scale %d'%(b&0xF))
        elif b==0xB0: emit(4,'TEMPO %d GATE %d ENV %02X'%(u8(p+1),u8(p+2),u8(p+3)))
        elif b==0xB1: emit(4,'VOLPAN %02X GATE %d ENV %02X'%(u8(p+1),u8(p+2),u8(p+3)))
        elif b==0xB2: emit(5,'TEMPO %d DUTY %d GATE %d ENV %02X'%(u8(p+1),u8(p+2)&3,u8(p+3),u8(p+4)))
        elif b==0xB3: emit(5,'TEMPO %d VOLPAN %02X GATE %d ENV %02X'%(u8(p+1),u8(p+2),u8(p+3),u8(p+4)))
        elif b==0xB4: emit(4,'TEMPO %d VOLPAN %02X DUTY %d'%(u8(p+1),u8(p+2),u8(p+3)&3))
        elif b==0xB5: emit(5,'VOLPAN %02X DUTY %d GATE %d ENV %02X'%(u8(p+1),u8(p+2)&3,u8(p+3),u8(p+4)))
        elif b==0xB6: emit(6,'TEMPO %d VOLPAN %02X DUTY %d GATE %d ENV %02X'%(u8(p+1),u8(p+2),u8(p+3)&3,u8(p+4),u8(p+5)))
        elif b==0xBD:
            k=u8(p+1); emit(2,'TIE x%d'%k)
            # next: note + len1, then k-1 raw lengths
            if typ in('psg','drum') and not fixed:
                a=p; nb=u8(p)
                nm=notename(nb) if typ=='psg' else '#%d'%nb
                lens=[u8(p+1+j) for j in range(k)]
                lines.append((a,d[a-B:a-B+1+k].hex(' '),'  note %s tied lens %s (total %d)'%(nm,lens,sum(lens)))); p+=1+k
        elif b==0xBE:
            if not fixed: fixlen=u8(p+1); fixed=True; emit(2,'FIXLEN on, len %d'%fixlen)
            else: fixed=False; emit(1,'FIXLEN off')
        elif b==0xBF: emit(1,'REPEAT last note')
        elif 0xC0<=b<=0xCF: emit(1,'VOL %d'%(b&0xF))
        elif b==0xD0: emit(2,'TEMPO %d'%u8(p+1))
        elif 0xD1<=b<=0xD3: emit(1,'PAN %s'%{1:'C',2:'L',3:'R'}[b&0xF])
        elif b==0xD4: emit(2,'NR50 %02X'%u8(p+1))
        elif b==0xD5: emit(2,'ENV %02X'%u8(p+1))
        elif b==0xD6: emit(2,'BIAS res %d'%u8(p+1))
        elif b==0xDF: emit(1,'NOISE OFF (rest 1 tick)')
        elif b==0xE0: emit(3,'TEMPO %d ENV %02X'%(u8(p+1),u8(p+2)))
        elif b==0xE1: emit(3,'TEMPO %d VOLPAN %02X'%(u8(p+1),u8(p+2)))
        elif b==0xE2: emit(3,'VOLPAN %02X ENV %02X'%(u8(p+1),u8(p+2)))
        elif b==0xE3: emit(4,'TEMPO %d VOLPAN %02X ENV %02X'%(u8(p+1),u8(p+2),u8(p+3)))
        else: emit(1,'??? %02X'%b)
    return lines,calls

def decode_pitchenv(idx, maxn=200):
    p=u32(0x083fc7c8+4*(idx-1)); out=[]; seen_fe=False; fbstate=False
    n=0
    while n<maxn:
        n+=1; b=u8(p)
        if b&0xF0==0xF0:
            if b==0xFB:
                if not fbstate: fbstate=True; out.append((p,'FB','loopB start')); p+=1
                else: fbstate=False; out.append((p,'FB %02X'%u8(p+1),'loopB end n=%d'%u8(p+1))); p+=2
                continue
            if b==0xFE:
                if not seen_fe: seen_fe=True; out.append((p,'FE','loop point')); p+=1; continue
                out.append((p,'FE','jump to loop point')); break
            out.append((p,'%02X'%b,'end (pitch env off)')); break
        if b&0xF0==0:
            hold=(b-1)&0xFF; v=u8(p+1)
            out.append((p,'%02X %02X'%(b,v),'hold %d  %s%d'%(hold,'-' if v&0x80 else '+',v&0x7f))); p+=2
        else:
            hold=(b>>4)-1; v=b&0xF
            mag=v&7 if v&8 else v; sg='-' if v&8 else '+'
            out.append((p,'%02X'%b,'hold %d  %s%d'%(hold,sg,mag))); p+=1
    return u32(0x083fc7c8+4*(idx-1)),out


def fmt_track(lab,tt,typ,ind='  '):
    o=[]
    ls,calls=decode_track(u32(tt),typ)
    o.append('%s-- %s  track table 0x%08X  start 0x%08X'%(ind,lab,tt,u32(tt)))
    for a,bb,t in ls: o.append('%s   %08X: %-24s %s'%(ind,a,bb,t))
    for c in sorted(calls):
        sa=u32(tt+4*c); sl,_=decode_track(sa,typ,True)
        o.append('%s   [sub %d @ 0x%08X]'%(ind,c,sa))
        for a,bb,t in sl: o.append('%s   %08X: %-24s %s'%(ind,a,bb,t))
    return o

if __name__=='__main__':
    out=sys.argv[2] if len(sys.argv)>2 else 'kr_sequences.txt'
    L=['KRAZY RACERS (GBA) - KCE Kobe sound driver - complete sequence disassembly',
       'Sound table 0x080596DC, %d entries x 36 bytes. Generated by kr_seqdump.py.'%NSND,
       'Note names: PSG note 1 = C2 (FreqTable[0]); drum notes show the triggered sound id; PCM notes are kit slots.',
       'Lengths are in sequencer steps; steps/sec = 119.455 * tempo / 256.','']
    for e in sound_entries():
        L.append('='*100)
        L.append('SOUND %d  @0x%08X  prio %d  %s  mask 0x%04X  [%s]'%(e['id'],e['addr'],e['prio'],'MUSIC(fade)' if e['music'] else 'sfx',e['mask'],' '.join(c[3] for c in e['chans'])))
        for bit,nm,typ,lab,tt in e['chans']:
            if not(0x08000000<=tt<0x08400000):
                L.append('  -- %s  track pointer 0x%08X is NOT a ROM address (read past the 8-slot entry) - see tech ref'%(lab,tt)); continue
            L+=fmt_track(lab,tt,typ)
    open(out,'w').write('\n'.join(L)+'\n')
    print('wrote',out)
