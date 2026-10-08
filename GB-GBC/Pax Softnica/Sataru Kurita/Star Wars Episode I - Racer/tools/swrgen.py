"""Generate RGBDS sources for the Star Wars Episode I: Racer sound driver."""
import sys, os, struct
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from gbdis import trace
from emit import CodeEmitter, hx
from swrparse import Bank3
from swrnames import NAMES, COMMENTS
import swrram, hwinc
ROM=sys.argv[1]; OUT=sys.argv[2]
rom=open(ROM,'rb').read()
RAM=swrram.build()
B=Bank3(rom)
def w(path,text):
    os.makedirs(os.path.dirname(os.path.join(OUT,path)) or OUT,exist_ok=True)
    open(os.path.join(OUT,path),'w',newline='\n').write(text)
NOTE=['_C','_Cs','_D','_Ds','_E','_F','_Fs','_G','_Gs','_A','_As','_B','_HiC','_HiCs','_HiD','_HiDs']
NOTE_NAMES=['C','C#','D','D#','E','F','F#','G','G#','A','A#','B']
def freqname(i): return f'{NOTE_NAMES[i%12]}{i//12+2}'
# ---------------------------------------------------------------- macros
def macros():
    o=['; Star Wars Episode I: Racer (GBC) sound driver: data constants and macros','',
       'IF !DEF(SWR_MACROS_INC)','DEF SWR_MACROS_INC EQU 1','',
       '; ---- one-byte events (music and SFX streams) ---------------------------',
       '; $0n note: semitone n above the channel octave (wOctave)']
    for i,n in enumerate(NOTE): o.append(f'DEF {n:<6} EQU ${i:02X}')
    o.append('; $1n length = length table[n] (then keep reading)')
    for i in range(16): o.append(f'DEF LEN{i:<3} EQU ${0x10+i:02X}')
    o.append('; $2n rest, length = length table[n]; $30 rest with the current length')
    for i in range(16): o.append(f'DEF REST{i:<2} EQU ${0x20+i:02X}')
    o+=['DEF RESTC  EQU $30','; $40 octave up, $41-$4F octave down','DEF OCT_UP EQU $40','DEF OCT_DN EQU $41',
        '; $5n octave n (semitone base 12 * n)']
    for i in range(8): o.append(f'DEF OCT{i}   EQU ${0x50+i:02X}')
    o+=['; $60 volume +1, $61-$6F volume -1; $7n volume n','DEF VOL_UP EQU $60','DEF VOL_DN EQU $61']
    for i in range(16): o.append(f'DEF VOL{i:<3} EQU ${0x70+i:02X}')
    o.append('; $8n duty, written at once: $80-$83 = ch1 duty 0-3, $84-$87 = ch2 duty 0-3 (any stream)')
    for i in range(4): o.append(f'DEF DUTY1_{i} EQU ${0x80+i:02X}')
    for i in range(4): o.append(f'DEF DUTY2_{i} EQU ${0x84+i:02X}')
    o+=['; $9n pan the stream\'s channel, written to NR51 at once','DEF PAN_L  EQU $90','DEF PAN_R  EQU $91','DEF PAN_LR EQU $92',
        '; $An (SFX) rumble pattern n','DEF RUMBLE_OFF EQU $A0']
    for i in range(1,5): o.append(f'DEF RUMBLE{i} EQU ${0xA0+i:02X}')
    o.append('; $Bn (music, ch4) drum n')
    for i in range(5): o.append(f'DEF DRUM{i}  EQU ${0xB0+i:02X}')
    o.append('; $Cn (music) gate: the last n frames of each note are silent')
    for i in range(16): o.append(f'DEF GATE{i:<2} EQU ${0xC0+i:02X}')
    o.append('; $Dn (music, ch1/ch2) pitch envelope n; $D0 off')
    o.append('DEF PENV_OFF EQU $D0')
    for i in range(1,16): o.append(f'DEF PENV{i:<2} EQU ${0xD0+i:02X}')
    o+=['','; ---- $Fx commands ------------------------------------------------------',
        'MACRO ENV ; NRx2; a value below $10 keeps the current volume','\tdb $F0, \\1','ENDM',
        'MACRO LOOP ; repeat to the matching ENDLOOP (4 levels per channel)','\tdb $F2','ENDM',
        'MACRO ENDLOOP ; total number of passes','\tdb $F3, \\1','ENDM',
        'MACRO JUMP_N ; count, target: jump back count times, then fall through','\tdb $F4, \\1','\tdw \\2','ENDM',
        'MACRO JUMP','\tdb $F5','\tdw \\1','ENDM',
        'MACRO STOP_MUSIC','\tdb $F6','ENDM',
        'MACRO FADE_STEP ; NR50 - $11','\tdb $F7','ENDM',
        'MACRO MASTER_RESET ; NR50 = $77','\tdb $F8','ENDM',
        'MACRO SFX_END','\tdb $FF','ENDM',
        '','; ---- structures ---------------------------------------------------------',
        'MACRO SONG ; length table, ch1, ch2, ch3, ch4','\tdw \\1, \\2, \\3, \\4, \\5','ENDM',
        'MACRO SFX_HEADER ; flags (bit 0: don\'t restart while playing), ?, chained SFX, ?','\tdb \\1, \\2, \\3, \\4','ENDM',
        'MACRO SFX_TRACK ; priority, ?, stream','\tdb \\1, \\2','\tdw \\3','ENDM',
        'MACRO SFX_NO_TRACK ; ?','\tdb $00, \\1','ENDM',
        'MACRO DRUMDEF ; frames, (unread), NR42=NR43 for the first hit, (unread), NR42, NR43','\tdb \\1, \\2, \\3, \\4, \\5, \\6','ENDM',
        '','ENDC','']
    return '\n'.join(o)
def evtok(b,kind,ch):
    hi,lo=b>>4,b&15
    if hi==0: return NOTE[lo]
    if hi==1: return f'LEN{lo}'
    if hi==2: return f'REST{lo}'
    if b==0x30: return 'RESTC'
    if b==0x40: return 'OCT_UP'
    if b==0x41: return 'OCT_DN'
    if hi==5 and lo<8: return f'OCT{lo}'
    if b==0x60: return 'VOL_UP'
    if b==0x61: return 'VOL_DN'
    if hi==7: return f'VOL{lo}'
    if hi==8 and lo<8: return f'DUTY{1+lo//4}_{lo%4}'
    if hi==9 and lo<3: return ['PAN_L','PAN_R','PAN_LR'][lo]
    if kind=='sfx' and hi==0xA and lo<5: return 'RUMBLE_OFF' if lo==0 else f'RUMBLE{lo}'
    if kind=='mus' and hi==0xB and lo<5: return f'DRUM{lo}'
    if kind=='mus' and hi==0xC: return f'GATE{lo}'
    if kind=='mus' and hi==0xD: return 'PENV_OFF' if lo==0 else f'PENV{lo}'
    return hx(b)
def label_of(a): return B.labels.get(a,hx(a,4))
def emit_data(start,end):
    out=[]; a=start; toks=[]; g,lw=B.g,B.lw
    def flush():
        if toks: out.append('\tdb '+', '.join(toks)); toks.clear()
    while a<end:
        if a in B.labels:
            flush(); lab=B.labels[a]
            if not lab.startswith('L_'): out.append('')
            out.append(f'{lab}:' if not lab.startswith('L_') else f'{lab}:')
        it=B.items.get(a)
        if it is None:
            flush(); e=a+1
            while e<end and e not in B.items and e not in B.labels: e+=1
            out.append('\tdb '+', '.join(hx(g(y)) for y in range(a,e))+' ; unreferenced'); a=e; continue
        sz,k,info=it
        if k in('musev','sfxev'):
            toks.append(evtok(g(a),k[:3],info))
            if len(toks)>=12: flush()
            a+=1; continue
        flush()
        b=g(a)
        if k in('muscmd','sfxcmd'):
            lo=b&15
            if k=='muscmd':
                t={0:lambda: f'ENV {hx(g(a+1))}',2:lambda:'LOOP',3:lambda: f'ENDLOOP {g(a+1)}',
                   4:lambda: f'JUMP_N {g(a+1)}, {label_of(lw(a+2))}',5:lambda: f'JUMP {label_of(lw(a+1))}',
                   6:lambda:'STOP_MUSIC',7:lambda:'FADE_STEP',8:lambda:'MASTER_RESET'}.get(lo)
            else:
                t={0:lambda: f'ENV {hx(g(a+1))}',5:lambda: f'JUMP {label_of(lw(a+1))}',15:lambda:'SFX_END'}.get(lo)
            out.append('\t'+(t() if t else f'db {hx(b)} ; no-op'))
        elif k=='ptr':
            v=lw(a); out.append(f'\tdw {label_of(v) if v else "0"}')
        elif k=='drum':
            out.append('\tDRUMDEF '+', '.join(hx(g(a+i)) for i in range(6)))
        elif k=='penv':
            out.append('\tdb '+', '.join(hx(g(x)) for x in range(a,a+sz)))
        elif k=='sfxhdr':
            out.append('\tSFX_HEADER '+', '.join(hx(g(a+i)) for i in range(4)))
        elif k=='sfxnone':
            out.append(f'\tSFX_NO_TRACK {hx(g(a+1))}')
        elif k=='sfxch':
            out.append(f'\tSFX_TRACK {hx(g(a))}, {hx(g(a+1))}, {label_of(lw(a+2))} ; {["ch1","ch2","ch3","ch4","rumble"][info]}')
        elif k=='wave':
            out.append('\tdb '+', '.join(hx(g(a+i)) for i in range(16)))
        elif k=='lentab':
            out.append('\tdb '+', '.join(str(g(x)) for x in range(a,a+sz)))
        elif k=='freq':
            for r in range(0,B.NFREQ,12):
                n=min(12,B.NFREQ-r)
                out.append('\tdw '+', '.join(hx(lw(a+2*(r+i)),4) for i in range(n))+f' ; {freqname(r)}-{freqname(r+n-1)}')
        elif k=='engine':
            for r in range(0,B.NENGINE,12):
                n=min(12,B.NENGINE-r)
                out.append('\tdw '+', '.join(hx(lw(a+2*(r+i)),4) for i in range(n)))
        else: raise Exception(k)
        a+=sz
    flush()
    return out
# ---------------------------------------------------------------- code
def driver():
    get=lambda a: rom[a] if a<0x4000 else B.g(a)
    lw=lambda a: get(a)|get(a+1)<<8
    jts={0x49A9:16,0x49C9:16,0x54C3:16,0x54E3:16}
    ents=[0x4000,0x420A,0x55BF,0x55C7,0x55CF,0x55D5,0x5649]+[lw(t+2*i) for t,n in jts.items() for i in range(n)]
    code=trace(get,ents,0x4000,0x5686,inline_rst=0x20,ret_rst=(0x28,))
    def sym16(v,ins):
        if v in RAM: return RAM[v]
        if v==0xFF30: return '_AUD3WAVERAM'
        if v==0xFF25: return 'rNR51'
        if v in swrram.ROM0: return swrram.ROM0[v]
        if 0x4000<=v<0x8000:
            if v in NAMES: return NAMES[v]
            if v in B.labels: return B.labels[v]
        return None
    def symh(v): return hwinc.HW.get(v,hx(v,4))
    data={}
    for t,n in jts.items(): data[t]=(2*n,[f'dw {NAMES.get(lw(t+2*i),hx(lw(t+2*i),4))}' for i in range(n)])
    for t,n in ((0x46FA,8),(0x475F,4),(0x4786,24),(0x529B,8),(0x52FE,4),(0x534C,5)):
        data[t]=(n,['db '+', '.join(hx(get(t+i)) for i in range(n))])
    ce=CodeEmitter(get,code,NAMES,sym16,symh,data,COMMENTS)
    ce.ext=dict(swrram.ROM0)
    def far(ins):
        t,bk=ins.far
        name={(0x5075,5):'Voice_PlaySample',(0x5138,5):'Voice_Silent'}[(t,bk)]
        return f'rst $20 ; far call\n\tdw {name}\n\tdb BANK({name})'
    ce.farcall=far
    return ce.emit(0x4000,0x5686)
# ---------------------------------------------------------------- voice (bank 5)
def voice():
    bk=5; get=lambda a: rom[a] if a<0x4000 else rom[bk*0x4000+a-0x4000]
    code=trace(get,[0x5075,0x5138],0x5075,0x5152,ret_rst=(0x28,))
    names={0x5075:'Voice_PlaySample',0x5138:'Voice_Silent',0x512D:'Voice_Delay',0x5147:'Voice_SilentDelay',0x5152:'VoiceCh3Level',0x5162:'VoiceSample'}
    def sym16(v,ins):
        if v in RAM: return RAM[v]
        if v==0xFF30: return '_AUD3WAVERAM'
        return names.get(v)
    data={0x5152:(16,['db '+', '.join(hx(get(0x5152+i)) for i in range(16))])}
    ce=CodeEmitter(get,code,names,sym16,lambda v: hwinc.HW.get(v,hx(v,4)),data,{
        0x5075:'Far entry (rst $20 from Voice_Play): play VoiceSample, 4 bits per sample,\nby rewriting the volume of all four channels; ends at the $80 byte.',
        0x5138:'Far entry when wSoundEnable is 0: the same delays without sound.'})
    lines=ce.emit(0x5075,0x5162)
    # export the two entry points
    lines=[l.replace('Voice_PlaySample:','Voice_PlaySample::').replace('Voice_Silent:','Voice_Silent::') for l in lines]
    a=0x5162
    while get(a)!=0x80: a+=1
    sample=bytes(get(x) for x in range(0x5162,a))
    return lines,sample
# ---------------------------------------------------------------- main
os.makedirs(OUT,exist_ok=True)
w('GB_Hardware.inc',hwinc.hw_inc())
w('SWR_RAM.inc',swrram.inc())
w('SWR_Macros.inc',macros())
hdr=lambda t: [f'; {t}','; Generated by tools/swrgen.py from the ROM; build_check.sh verifies.','']
w('SWR_Driver.inc','\n'.join(hdr('Star Wars Episode I: Racer sound driver code, bank $03:$4000-$5685')+driver())+'\n')
w('SWR_Data.inc','\n'.join(hdr('Sound data, bank $03:$5686-$76A9: drums, pitch envelopes, songs, SFX, tables')+emit_data(0x5686,B.END))+'\n')
vl,sample=voice()
w('pcm/VoiceSample.bin','')
open(os.path.join(OUT,'pcm','VoiceSample.bin'),'wb').write(sample)
w('SWR_Voice.asm','\n'.join(['; Voice sample player, bank $05:$5075-$6E21','',
    'INCLUDE "GB_Hardware.inc"','INCLUDE "SWR_RAM.inc"','',
    'SECTION "SWR voice", ROMX[$5075], BANK[$05]','']+vl+['','; 4-bit samples, high nibble first, about 8 kHz in double speed',
    'VoiceSample:','\tINCBIN "pcm/VoiceSample.bin"','\tdb $80 ; end','','ASSERT @ == $6E22',''])+'\n')
w('SWR_Bank03.asm','\n'.join(['; Star Wars Episode I: Racer sound driver, bank $03','',
    'INCLUDE "GB_Hardware.inc"','INCLUDE "SWR_RAM.inc"','INCLUDE "SWR_Macros.inc"','',
    'SECTION "SWR sound", ROMX[$4000], BANK[$03]','','INCLUDE "SWR_Driver.inc"','INCLUDE "SWR_Data.inc"',
    'ASSERT @ == $76AA','']))
# WAV of the sample: nibble n -> 8-bit (n*17), 2 samples per byte, rate from the loop timing
cyc=2092/2; rate=round(4194304*2/cyc)
pcm=bytes(v for b in sample for v in ((b>>4)*17,(b&15)*17))
hdrw=b'RIFF'+struct.pack('<I',36+len(pcm))+b'WAVEfmt '+struct.pack('<IHHIIHH',16,1,1,rate,rate,1,8)+b'data'+struct.pack('<I',len(pcm))
open(os.path.join(OUT,'pcm','VoiceSample.wav'),'wb').write(hdrw+pcm)
print('ok, sample',len(sample),'bytes, rate',rate)
