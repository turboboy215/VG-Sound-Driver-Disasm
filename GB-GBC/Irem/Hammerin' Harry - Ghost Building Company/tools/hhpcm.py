# Hammerin' Harry PCM bitstream decoder (transliteration of ROM0 $261A)
def decode(d,p,count):
    """d: bytes, p: offset of bitstream; returns (nibbles, end offset)"""
    st={'rep':0,'reg':0}; bits=[0,1]  # b, c
    pos=[p]
    def bit():
        bits[1]-=1
        if bits[1]==0:
            bits[0]=d[pos[0]]; pos[0]+=1; bits[1]=8
        bits[0]=((bits[0]<<1)|(bits[0]>>7))&0xff
        return bits[0]&1
    def rd(n):
        h=0
        for _ in range(n): h=(h<<1)|bit()
        return h
    out=[]
    for _ in range(count):
        if st['rep']:
            st['rep']-=1; out.append(rd(3)); continue
        if bit(): out.append(st['reg']); continue
        h=rd(3)
        if h!=st['reg']: out.append(h); continue
        h=rd(3)
        if h!=st['reg']: st['reg']=h; out.append(h); continue
        n=rd(4); st['rep']=(12+n-1)&0xff; out.append(rd(3))
    return out,pos[0]

# every script opcode $1A (found by tools/hhscript.py): bank, address, name
SAMPLES=[(0x6,0x4000,'HH_PCM_06_4000'),(0xe,0x402e,'HH_PCM_0E_402E'),(0xe,0x4413,'HH_PCM_0E_4413'),(0xe,0x468f,'HH_PCM_0E_468F'),(0xe,0x48c6,'HH_PCM_0E_48C6')]
RATE=4228   # 262144 Hz / (256 - $C2)
def extract(rom):
    """returns [(name, levels 0-7)] for the three samples"""
    res=[]
    for bank,a,name in SAMPLES:
        off=bank*0x4000+a-0x4000
        assert rom[off]==0x1a
        cnt=0x10000-(rom[off+1]|rom[off+2]<<8)
        out,end=decode(rom,off+3,cnt)
        res.append((name,out))
    return res
if __name__=='__main__':
    import sys,wave
    rom=open(sys.argv[1],'rb').read(); outdir=sys.argv[2] if len(sys.argv)>2 else '.'
    for name,lv in extract(rom):
        # NR50 level v gives (v+1)/8 of full scale on a constant (DC) channel output
        data=bytes(max(0,min(255,round(128+(v-3.5)*36))) for v in lv)
        w=wave.open('%s/%s.wav'%(outdir,name),'wb'); w.setnchannels(1); w.setsampwidth(1); w.setframerate(RATE); w.writeframes(data); w.close()
        print('%s.wav: %d samples, %.3f s'%(name,len(lv),len(lv)/RATE))
        if name=='HH_PCM_0E_402E':   # also played at TMA $D9 (6721 Hz) when hFFA4 = $0C
            w=wave.open('%s/%s_6721Hz.wav'%(outdir,name),'wb'); w.setnchannels(1); w.setsampwidth(1); w.setframerate(6721); w.writeframes(data); w.close()
            print('%s_6721Hz.wav: %.3f s'%(name,len(lv)/6721))
    # the three back-to-back parts joined
    lv=sum((l for n,l in extract(rom) if n.startswith('HH_PCM_0E_4') and n!='HH_PCM_0E_402E'),[])
    w=wave.open('%s/HH_PCM_0E_4413-48C6_joined.wav'%outdir,'wb'); w.setnchannels(1); w.setsampwidth(1); w.setframerate(RATE)
    w.writeframes(bytes(max(0,min(255,round(128+(v-3.5)*36))) for v in lv)); w.close()
    print('HH_PCM_0E_4413-48C6_joined.wav: %.3f s'%(len(lv)/RATE))
