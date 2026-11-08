"""MusyX GBA research tool: find driver + project, disassemble macros, decode songs, export MIDI.
Usage: python3 musyx_gba.py ROM.gba PROJECT_ADDR   (prints object/macro listing)
Library: find_musyx(rom), Proj(rom,base), parse_song, decode_pattern, song_to_midi."""
import struct,sys
OPS={ # opcode: (name, size, fields)
0x00:('END',2,''),0x01:('STOP',2,''),0x02:('VOLUME',2,'B'),0x03:('KEYON',2,'B'),
0x04:('WAIT',4,'Bh'),0x05:('SILENCE',2,'B'),0x06:('LOOP',6,'BHh'),0x07:('PANNING',4,'BB'),
0x08:('SETPITCH',4,'xh'),0x09:('ADDPITCH',4,'Bh'),0x0A:('VIBRATO',4,'Bh'),0x0B:('PITCHSWEEP',6,'Bhh'),
0x0C:('PORTAMENTO',6,'BhH'),0x0D:('GOTO',6,'xi'),0x0E:('SETADSR',4,'BH'),0x0F:('STARTSAMPLE',8,'BHI'),
0x10:('TRAPKEYOFF',6,'xi'),0x11:('UNTRAPKEYOFF',2,'x'),0x12:('SAMPLEREGION',10,'BII'),0x13:('PULSESWEEP',6,'BbbH'),
0x14:('PULSEVEL',4,'bbb'),0x15:('FADE',4,'BH'),0x16:('RNDPITCH',6,'BHH'),0x17:('SPLITKEY',6,'Bi'),
0x18:('SPLITVEL',6,'Bi'),0x19:('SPLITRND',6,'Bi'),0x1A:('MODOFF',2,'B'),0x1B:('MODRESET',2,'B'),
0x1C:('LASTNOTE',4,'xh'),0x1D:('KEYMAP',6,'xHh'),0x1E:('PLAYMACRO',8,'xBbBBH'),0x1F:('NOP',2,'x'),
0x20:('PSGDUTY',2,'B'),0x21:('NOISEPARAM',2,'B'),0x22:('SENDKEYOFF',2,'B'),0x23:('KEYOFFMACRO',4,'xH'),
0x24:('PSGENV',2,'B'),0x25:('PSGENVOFF',2,'x'),0x26:('SETPRIO',2,'B'),0x27:('ADDPRIO',2,'b'),
0x28:('SETAGE',4,'xH'),0x29:('ADDAGE',4,'xh'),0x2A:('SETFLAG',4,'xBB'),0x2B:('IFFLAG',6,'Bi'),
0x2C:('REVERB',2,'B'),0x2D:('PANSWEEP',6,'BBBh'),0x2E:('KEYOFF',2,'x'),0x2F:('SCALEVOL',6,'BbH'),
0x30:('LOOPSCAN',8,'BhHB'),0x31:('SETWAVE',4,'xH'),0x32:('PORTAFROMLAST',6,'xhH'),0x33:('ADDLOOPLEN',4,'xh'),
0x34:('AGESPEED',2,'B'),0x35:('SETLOOPLEN',6,'xI'),
}
JUMPS={0x0D:'i',0x10:'i',0x17:'i',0x18:'i',0x19:'i',0x2B:'i'}
def rd(fmt,b,o):
    # little-endian, halfword-aligned packed operands
    out=[];
    for c in fmt:
        if c=='x': o+=1; continue
        if c in 'Bb': out.append(struct.unpack_from('<'+c,b,o)[0]); o+=1
        elif c in 'Hh':
            if o&1: o+=1
            out.append(struct.unpack_from('<'+c,b,o)[0]); o+=2
        elif c in 'Ii':
            if o&1: o+=1
            out.append(struct.unpack_from('<'+c,b,o)[0]); o+=4
    return out
class Proj:
    def __init__(s,rom,base):
        s.d=rom; s.b=base
        s.h=struct.unpack_from('<8I',rom,base)
    def u32(s,o): return struct.unpack_from('<I',s.d,s.b+o)[0]
    def table(s,idx,count=None):
        t=s.h[idx]
        return t
    def objects(s):
        t=s.h[0]; first=s.u32(t); n=(first-t)//4
        return [s.u32(t+4*i) for i in range(n)]
    def fx(s):
        t=s.h[3]; n=s.u32(t)
        return [struct.unpack_from('<HBBBBBB',s.d,s.b+t+4+8*i) for i in range(n)]
    def songs(s):
        t=s.h[6]; n=s.u32(t); return [s.u32(t+4+4*i) for i in range(n)]
    def samples(s,n=None):
        t=s.h[7]; out=[]
        first=s.u32(t); n=(first-t)//4
        for i in range(n):
            o=s.u32(t+4*i)
            ln,lp,rate,root,typ=struct.unpack_from('<IiHBB',s.d,s.b+o)
            out.append((o,ln,lp,rate,root,typ,s.d[s.b+o+12:s.b+o+16]))
        return out
    def disasm_macro(s,off,maxlen=4000,limit=None):
        d=s.d; a=s.b+off+4; lines=[]; end=a+maxlen if limit is None else s.b+limit; seen=set(); targets=set()
        while a<end:
            op=d[a]
            if op not in OPS: lines.append((a,'??? %02x'%op,d[a:a+2].hex())); break
            name,sz,fmt=OPS[op]
            args=rd(fmt,d,a+1)
            tgt=None
            if op in JUMPS: tgt=a+args[-1]; targets.add(tgt)
            if op==0x06: tgt=a+args[-1]; targets.add(tgt)
            lines.append((a,name,args,tgt,d[a:a+sz].hex()))
            a+=sz
            if op in (0,1,0x0D) and not any(a<=t<end for t in targets): break
        return lines
if __name__=='__main__':
    rom=open(sys.argv[1],'rb').read(); base=int(sys.argv[2],16)-0x08000000
    p=Proj(rom,base)
    print('header',[hex(x) for x in p.h])
    objs=p.objects(); print('objects',len(objs))
    bounds=sorted(set(objs))+[p.h[3]]
    for i,o in enumerate(objs):
        lim=bounds[bounds.index(o)+1]
        hdr=rom[base+o:base+o+4]
        if hdr[2]:
            n=struct.unpack_from('<H',rom,base+o+4)[0]
            print('OBJ %3d @%05x KEYMAP hdr=%s count=%d'%(i,o,hdr.hex(),n))
            for k in range(n):
                e=struct.unpack_from('<HhbBBB',rom,base+o+6+8*k)
                print('   key %3d: sample=%d pitch=%d pan=%d b5=%d nopitch=%d b7=%d'%(k,*e))
        else:
            print('OBJ %3d @%05x MACRO chan=%d flags=%02x %02x %02x'%(i,o,hdr[0],hdr[1],hdr[2],hdr[3]))
            for a,*rest in p.disasm_macro(o,limit=lim):
                if len(rest)==2: print('   %08x  %s %s'%(a+0x08000000,rest[0],rest[1])); continue
                name,args,tgt,raw=rest
                print('   %08x  %-14s %-28s %s%s'%(a+0x08000000,name,','.join(str(x) for x in args),raw,('  -> %08x'%(tgt+0x08000000)) if tgt else ''))

def parse_song(rom,base,soff,verbose=True,maxev=100000):
    S=base+soff
    u32=lambda o:struct.unpack_from('<I',rom,o)[0]
    s32=lambda o:struct.unpack_from('<i',rom,o)[0]
    out={}
    out['initprog']=list(rom[S:S+16])
    out['progmap']=[struct.unpack_from('<HBB',rom,S+0x10+4*i) for i in range(128)]
    out['drummap']=[struct.unpack_from('<HBB',rom,S+0x210+4*i) for i in range(128)]
    R=S+0x410
    trk=u32(R); pat=u32(R+4); bpm=struct.unpack_from('<H',rom,R+8)[0]
    out['bpm']=bpm; out['trk_off']=trk; out['pat_off']=pat; out['hdr_extra']=rom[R+8:R+16].hex()
    tracks=[]
    for i in range(17):
        o=u32(R+trk+4*i); tracks.append(o)
    out['tracks']=tracks
    # pattern table: count unknown; read until first pattern offset
    ptab=R+pat
    first=u32(ptab); npat=(first-pat)//4 if first>pat else 0
    out['npat']=npat
    pats=[u32(ptab+4*i) for i in range(npat)]
    out['pats']=pats
    # decode track lists
    tl=[]
    for i,o in enumerate(tracks):
        if o==0: tl.append(None); continue
        p=R+o; ents=[]
        while True:
            t,pi=struct.unpack_from('<Ii',rom,p)
            if pi==-1: ents.append((t,'END')); break
            if pi==-2:
                tgt,t2=struct.unpack_from('<II',rom,p+8); ents.append((t,'LOOP',tgt,t2)); break
            ents.append((t,pi)); p+=8
        tl.append(ents)
    out['tracklists']=tl
    return out
def decode_pattern(rom,addr,limit=200000):
    ev=[]; p=addr
    while True:
        dt,=struct.unpack_from('<H',rom,p)
        if dt==0xffff and struct.unpack_from('<H',rom,p+2)[0]==0xffff: ev.append((dt,'EOP')); break
        v=struct.unpack_from('<b',rom,p+2)[0]; b3=rom[p+3]
        if v<0: ev.append((dt,'STOP',v,b3)); break  # negative = end
        if v==0:
            if b3&0x80: ev.append((dt,'VOICES',b3&0x7f)); p+=4
            else: ev.append((dt,'PROG',b3)); p+=4
        else:
            if b3&0x80:
                pr,ln=struct.unpack_from('<HH',rom,p+4); ev.append((dt,'PROGNOTE',b3&0x7f,v,pr,ln)); p+=8
            else:
                ln,=struct.unpack_from('<H',rom,p+4); ev.append((dt,'NOTE',b3,v,ln)); p+=6
        if len(ev)>limit: break
    return ev,p

def song_to_events(rom,R):
    """Flatten a GBA MusyX song (R = address of the gm2song part, i.e. song+0x410).
    Returns (bpm, per-track list of absolute-time events, loop (start,end) or None, song_end)."""
    u32=lambda o:struct.unpack_from('<I',rom,o)[0]
    trk=u32(R); pat=u32(R+4); bpm=u32(R+8)
    pt=lambda i:R+u32(R+pat+4*i)
    tracks={}; loop=None; songend=0
    for ti in range(17):
        o=u32(R+trk+4*ti)
        if not o: continue
        p=R+o; t=0; evs=[]
        while True:
            dt,pi=struct.unpack_from('<Ii',rom,p); t+=dt
            if pi==-1: songend=max(songend,t); break
            if pi==-2:
                tgt,dt2=struct.unpack_from('<II',rom,p+8)
                # loop target entry: its absolute start time = loop start + dt2 offset
                # compute absolute time of target entry
                q=R+o; tt=0
                while q<=R+o+tgt:
                    tt+=u32(q); q+=8
                loop=(t, tt-dt2); songend=max(songend,t); break
            a=pt(pi)
            if ti==16:
                q=a; tt=t
                while True:
                    d,b=struct.unpack_from('<HH',rom,q)
                    if d==0xffff and b==0xffff: break
                    tt+=d; evs.append((tt,'TEMPO',b)); q+=4
            else:
                ev,_=decode_pattern(rom,a); tt=t
                for e in ev:
                    if e[1] in ('EOP','STOP'): break
                    tt+=e[0]; evs.append((tt,)+tuple(e[1:]))
            p+=8
        tracks[ti]=evs
    return bpm,tracks,loop,songend

def song_to_midi(rom,R,path,ppq=96,loopch=15,anchor=True):
    import mido
    bpm,tracks,loop,end=song_to_events(rom,R)
    mid=mido.MidiFile(type=1,ticks_per_beat=ppq)
    T=lambda b:int(60000000//b)
    abs0=[(0,mido.MetaMessage('set_tempo',tempo=T(bpm)))]
    for t,k,b in tracks.get(16,[]):
        if t>0 or b!=bpm: abs0.append((t,mido.MetaMessage('set_tempo',tempo=T(b))))
    def emit(lst):
        tr=mido.MidiTrack(); last=0
        for t,m in sorted(lst,key=lambda x:(x[0],x[2] if len(x)>2 else 0)):
            pass
        return tr
    def build(lst):
        tr=mido.MidiTrack(); last=0
        lst=sorted(lst,key=lambda x:(x[0],x[1]))
        for t,pri,m in lst:
            m=m.copy(time=t-last); last=t; tr.append(m)
        return tr
    LC=[]
    if loop and loopch is not None:
        LC=[(loop[1],1,mido.Message('control_change',channel=loopch,control=102,value=0)),(loop[0],8,mido.Message('control_change',channel=loopch,control=103,value=0))]
    mid.tracks.append(build([(t,0,m) for t,m in abs0]+[(end,9,mido.MetaMessage('marker',text='end'))]+LC))
    for ti in range(16):
        if ti not in tracks: continue
        ch=ti; L=[]
        first = (loopch is None and ti==min(k for k in tracks if k<16))
        if anchor: L.append((0,1,mido.Message('control_change',channel=ch,control=7,value=127)))
        if loop and first:
            L.append((loop[1],1,mido.Message('control_change',channel=ch,control=102,value=0)))
        for e in tracks[ti]:
            t=e[0]
            if e[1]=='NOTE':
                n,v,ln=e[2],e[3],e[4]
                L.append((t,3,mido.Message('note_on',channel=ch,note=n,velocity=v)))
                L.append((t+ln,0,mido.Message('note_off',channel=ch,note=n,velocity=0)))
            elif e[1]=='PROGNOTE':
                n,v,pr,ln=e[2],e[3],e[4],e[5]
                L.append((t,2,mido.Message('program_change',channel=ch,program=pr&0x7f)))
                L.append((t,3,mido.Message('note_on',channel=ch,note=n,velocity=v)))
                L.append((t+ln,0,mido.Message('note_off',channel=ch,note=n,velocity=0)))
            elif e[1]=='PROG':
                L.append((t,2,mido.Message('program_change',channel=ch,program=e[2]&0x7f)))
            elif e[1]=='VOICES':
                L.append((t,2,mido.Message('control_change',channel=ch,control=104,value=e[2])))
        if loop and first: L.append((loop[0],8,mido.Message('control_change',channel=ch,control=103,value=0)))
        mid.tracks.append(build(L))
    mid.save(path)
    return bpm,loop,end

SIG=struct.pack('<8I',0x04000064,0x0400006C,0x04000074,0x0400007C,0x04000062,0x04000068,0x04000072,0x04000078)
def find_musyx(rom):
    """Locate MusyX GBA in a ROM image. Works for Thumb builds (EWJ2) and ARM builds (I Spy Challenger).
    Returns dict with rodata/optable addresses, code mode and candidate project bases."""
    r={}
    i=rom.find(SIG)
    if i<0 or rom[i+0x40:i+0x40+128]!=b'\x7f'*64+b'\x80'*64: return None
    r['rodata']=0x08000000+i; r['optable']=0x08000000+i+0x2C0
    ops=[struct.unpack_from('<I',rom,i+0x2C0+4*k)[0] for k in range(54)]
    r['code_mode']='thumb' if all(o&1 for o in ops) else ('arm' if not any(o&1 for o in ops) else 'mixed')
    r['op_handlers']=(min(ops)&~1,max(ops)&~1)
    cands=[]
    for p in range(0,len(rom)-0x40,4):
        if struct.unpack_from('<I',rom,p)[0]!=0x20: continue
        h=struct.unpack_from('<8I',rom,p)
        if not (0x24<=h[1]<=h[3] and h[6]>h[3] and h[7]>h[6] and p+h[7]<len(rom)): continue
        v=struct.unpack_from('<I',rom,p+0x20)[0]
        if v<0x24 or (v-0x20)%4: continue
        cands.append(0x08000000+p)
    good=[]
    for c in cands:
        try:
            p=Proj(rom,c-0x08000000); sm=p.samples(); so=sm[-1]
            if abs((c+so[0]+16+so[1])-r['rodata'])<16: good.append(c)
        except Exception: pass
    r['projects']=good or cands  # in both known games the project ends exactly where the driver rodata begins
    return r
