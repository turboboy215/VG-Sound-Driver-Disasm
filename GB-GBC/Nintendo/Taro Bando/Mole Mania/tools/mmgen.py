"""Generate RGBDS sources for the Mole Mania sound banks from the ROM."""
import sys, os
sys.path.insert(0,os.path.dirname(__file__))
from gbdis import trace
from emit import CodeEmitter, hx
from mmparse import Bank, ARGS
from mmnames import NAMES, COMMENTS
import mmram, hwinc
ROM=sys.argv[1]; OUT=sys.argv[2]
rom=open(ROM,'rb').read()
RAM=mmram.build()
BANKS=[0x07,0x0B,0x1A]
REGION_END={0x07:0x8000,0x0B:0x8000,0x1A:0x6900}
DATA_END={0x07:0x7FFF,0x0B:0x7FDF,0x1A:0x6831}   # end of the song data; the rest is padding / the credit text
NOTES=['C','Cs','D','Ds','E','F','Fs','G','Gs','A','As','B']
def notename(i):  # table index 1 = C2
    i-=1; return f'{NOTES[i%12]}{i//12+2}'
LENNAMES=['L32','L16','L8','L4','L2','L1','L8D','L4D','L2D','L8T','L4T','L11']
def w(path,text):
    open(os.path.join(OUT,path),'w',newline='\n').write(text)

# ---------------------------------------------------------------- macros
def macros():
    o=['; Mole Mania (Taro Bando) sound driver: data macros and constants','',
       'IF !DEF(MM_MACROS_INC)','DEF MM_MACROS_INC EQU 1','',
       '; The driver stores every pointer big-endian.',
       'MACRO dwb','\tREPT _NARG','\t\tdb HIGH(\\1), LOW(\\1)','\t\tSHIFT','\tENDR','ENDM','',
       '; ---- pattern bytes ----------------------------------------------------',
       '; $20-$2B: note length, an index into the length table chosen by TEMPO',
       '; (lengths in frames; 11 = past the 11-byte table, reads the next table)']
    for i,n in enumerate(LENNAMES): o.append(f'DEF {n:<6} EQU ${0x20+i:02X}')
    o+=['; $2C-$2F: ch3 output level 0-3 (global, read by ch3)']
    for i in range(4): o.append(f'DEF CH3LVL{i} EQU ${0x2C+i:02X}')
    o+=['; $30-$6F: gate, GATEnn = nn/64 of the note length before the release']
    for i in range(64): o.append(f'DEF GATE{i:02d} EQU ${0x30+i:02X}')
    o+=['; $70 rest, $71-$B9 notes C2-C8 (index into the frequency tables), $BA tie',
        'DEF REST   EQU $70']
    for i in range(1,74): o.append(f'DEF {notename(i):<6} EQU ${0x70+i:02X}')
    o+=['DEF TIE    EQU $BA','; ch4: $BC+ = noise NOISEnn (index into NoiseTable)']
    for i in range(0x44): o.append(f'DEF NOISE{i:02d} EQU ${0xBC+i:02X}')
    o+=['','; ---- pattern commands ($00-$13) -----------------------------------------']
    cmds=[('PATEND','',0,'end of pattern: every channel moves to the next step'),
          ('TEMPO','t',1,'length table t (global)'),('WAVE','w',1,'ch3 wave (global)'),
          ('VIBRATO','delay, rate, depth',3,'square vibrato: +-depth, rate frames per phase, after delay frames'),
          ('VIBRATO_OFF','',0,''),('RELEASE','frames, env',2,'at gate end: retrigger with env, cut after frames'),
          ('RELEASE_OFF','',0,''),('PORTA','delay, frames, note',3,'glide to note over frames, after delay frames'),
          ('FRAMES','n',1,'next notes last n frames'),('TRANSPOSE','n',1,'semitones'),
          ('PAN_CENTRE','',0,''),('PAN_RIGHT','',0,''),('PAN_LEFT','',0,''),('FRAMES_0D','n',1,'same as FRAMES'),
          ('CH3DECAY','n',1,'ch3: level drops by one every n frames'),('SCOOP','xy',1,'start x*y period units low, rise over y frames'),
          ('DUTYSEQ','n',1,'ch1/ch2 duty sequence'),('ENVSEQ','n',1,'ch1/ch2/ch4 envelope sequence'),
          ('PORTA_OFF','',0,''),('SCOOP_OFF','',0,'')]
    for i,(n,a,na,c) in enumerate(cmds):
        o.append(f'MACRO {n}'+(f' ; {a}' if a else ''))
        o.append(f'\tdb ${i:02X}'+''.join(f', \\{k+1}' for k in range(na))+(f' ; {c}' if c else ''))
        o.append('ENDM')
    o+=['','; ---- song structure ----------------------------------------------------',
        'MACRO STEP ; frame','\tdwb \\1','ENDM',
        'MACRO SONG_END','\tdb $00, $00','ENDM',
        'MACRO SONG_LOOP ; n: go back n steps','\tdb $00, \\1','ENDM',
        'MACRO FRAME ; ch1, ch2, ch3, ch4 patterns (0 = channel unused)','\tdwb \\1, \\2, \\3, \\4','ENDM',
        '','; ---- sequences: value, frames ($FF = hold) ------------------------------',
        'MACRO SEQ','\tdb \\1, \\2','ENDM','MACRO SEQ_HOLD','\tdb \\1, $FF','ENDM',
        '','; ---- sound effects ------------------------------------------------------',
        'MACRO SFX_CHANNEL ; 0-3','\tdb \\1','ENDM',
        '; a byte $00-$6F: play for n+1 frames (retriggers unless SFX_LEGATO came first)',
        'MACRO SFX_LEN','\tdb \\1','ENDM',
        '; a byte $70-$EF: period = FreqTable_DMG[n - $70]; the note constants are the same values',
        'MACRO SFX_FREQ ; table index','\tdb $70 + \\1','ENDM']
    sc=[('SFX_END','',0),('SFX_DUTY','d',1),('SFX_ENV','nrx2',1),('SFX_WAVE','w',1),('SFX_NOISE','nr43',1),
        ('SFX_CH3LVL','l',1),('SFX_SWEEP','delta',1),('SFX_PAN_CENTRE','',0),('SFX_PAN_RIGHT','',0),('SFX_PAN_LEFT','',0),('SFX_LEGATO','',0)]
    for i,(n,a,na) in enumerate(sc):
        o.append(f'MACRO {n}'+(f' ; {a}' if a else ''))
        o.append(f'\tdb ${0xF0+i:02X}'+''.join(f', \\{k+1}' for k in range(na)))
        o.append('ENDM')
    o+=['MACRO SFX_NOP','\tdb $FF','ENDM','','ENDC','']
    return '\n'.join(o)

# ---------------------------------------------------------------- data lines
def pat_tokens(B,a,size,kind,ch):
    g=B.g; b=g(a)
    if kind=='cmd':
        args=[g(a+1+i) for i in range(size-1)]
        name=['PATEND','TEMPO','WAVE','VIBRATO','VIBRATO_OFF','RELEASE','RELEASE_OFF','PORTA','FRAMES','TRANSPOSE',
              'PAN_CENTRE','PAN_RIGHT','PAN_LEFT','FRAMES_0D','CH3DECAY','SCOOP','DUTYSEQ','ENVSEQ','PORTA_OFF','SCOOP_OFF']
        if b>=0x14: return ('db',f'${b:02X} ; command ${b:02X}: no effect')
        if b==0x07: args=[hx(args[0]),hx(args[1]),bytetok(args[2],0)]
        elif b==0x0F: args=[hx(args[0])]
        else: args=[hx(x) for x in args]
        return ('macro',name[b]+(' '+', '.join(args) if args else ''))
    return ('byte',bytetok(b,ch))
def bytetok(b,ch):
    if 0x20<=b<=0x2B: return LENNAMES[b-0x20]
    if 0x2C<=b<=0x2F: return f'CH3LVL{b-0x2C}'
    if 0x30<=b<=0x6F: return f'GATE{b-0x30:02d}'
    if b==0x70: return 'REST'
    if ch==3:
        if b>=0xBC: return f'NOISE{b-0xBC:02d}'
        if b==0xBA: return 'TIE'
        return hx(b)
    if 0x71<=b<=0xB9: return notename(b-0x70)
    if b==0xBA: return 'TIE'
    return hx(b)
def flush(out,toks):
    if toks: out.append('\tdb '+', '.join(toks)); toks.clear()

def emit_data(B,start,end,skipcheck=None):
    out=[]; a=start; toks=[]; cur_kind=None
    inner=set()
    for x,(sz,k,i) in B.items.items():
        for y in range(x+1,x+sz):
            if y in B.labels: inner.add(y)
    assert not inner, [hex(x) for x in inner]
    g=B.g
    while a<end:
        if a in B.labels:
            flush(out,toks); lab=B.labels[a]
            if lab.startswith(('Song','Sfx','EnvSeq0','DutySeq0','Wave0')) or lab.endswith('Table') or lab.startswith('Frame') and False:
                pass
            if not lab.startswith(('Pat_','Frame_')) or True: out.append('')
            out.append(f'{lab}:')
        it=B.items.get(a)
        if it is None:
            flush(out,toks)
            e=a+1
            while e<end and e not in B.items and e not in B.labels: e+=1
            if e-a>1 and orphan_pattern(B,a,e):
                B.parse_pat_orphan(a,e); out.append('; unreferenced pattern'); continue
            for x in range(a,e,16):
                out.append('\tdb '+', '.join(hx(g(y)) for y in range(x,min(e,x+16)))+(' ; unreferenced' if x==a else ''))
            a=e; continue
        sz,k,info=it
        if k in('ev','cmd'):
            kind,t=pat_tokens(B,a,sz,k,info)
            if kind=='byte':
                toks.append(t)
                if len(toks)>=8: flush(out,toks)
            else:
                flush(out,toks); out.append(('\t'+t) if kind=='macro' else '\tdb '+t)
            a+=sz; continue
        flush(out,toks)
        if k=='ptr':
            v=B.w(a); out.append(f'\tdwb {B.labels.get(v,hx(v,4))}')
        elif k=='lentab':
            out.append('\tdb '+', '.join(str(g(a+i)) for i in range(11))+f' ; TEMPO {info}')
        elif k=='freqtab':
            for r in range(0,74,12):
                vals=[B.w(a+2*i) for i in range(r,min(74,r+12))]
                names=['--' if i==0 else notename(i) for i in range(r,min(74,r+12))]
                out.append('\tdwb '+', '.join(hx(v,4) for v in vals)+f' ; {names[0]}-{names[-1]}')
        elif k=='step':
            v=B.w(a); out.append(f'\tSTEP {B.labels[v]}')
        elif k=='stepend':
            out.append('\tSONG_END' if info==0 else f'\tSONG_LOOP {info}')
        elif k=='frame':
            ps=[B.w(a+2*c) for c in range(4)]
            out.append('\tFRAME '+', '.join(B.labels[p] if p else '0' for p in ps))
        elif k=='noisetab':
            out.append('\tdb '+', '.join(hx(g(a+i)) for i in range(16))+' ; NR43 for NOISE00-NOISE15')
        elif k=='wave':
            out.append('\tdb '+', '.join(hx(g(a+i)) for i in range(16)))
        elif k in('envseq','dutyseq'):
            v,f=g(a),g(a+1)
            out.append(f'\tSEQ_HOLD {hx(v)}' if f==0xFF else f'\tSEQ {hx(v)}, {f}')
        elif k=='sfxchan':
            out.append(f'\tSFX_CHANNEL {g(a)}')
        elif k=='sfxwait':
            out.append(f'\tSFX_LEN {g(a)}')
        elif k=='sfxnote':
            i=g(a)-0x70
            out.append(f'\tdb {notename(i)} ; SFX note' if 1<=i<=73 else f'\tSFX_FREQ {i}')
        elif k=='sfxcmd':
            b=g(a); names={0xF0:'SFX_END',0xF1:'SFX_DUTY',0xF2:'SFX_ENV',0xF3:'SFX_WAVE',0xF4:'SFX_NOISE',0xF5:'SFX_CH3LVL',
                0xF6:'SFX_SWEEP',0xF7:'SFX_PAN_CENTRE',0xF8:'SFX_PAN_RIGHT',0xF9:'SFX_PAN_LEFT',0xFA:'SFX_LEGATO',0xFF:'SFX_NOP'}
            out.append('\t'+names[b]+(' '+hx(g(a+1)) if sz==2 else ''))
        else: raise Exception(k)
        a+=sz
    flush(out,toks)
    return out

# ---------------------------------------------------------------- driver code
def driver(B):
    get=lambda a: rom[a] if a<0x4000 else B.g(a)
    jt1=[B.w(0x4344+2*i) for i in range(32)]; jt2=[B.w(0x4D36+2*i) for i in range(11)]
    code=trace(get,[0x4000,0x4002]+jt1+jt2,0x4000,0x4F37)
    labels={0x50FB:'SongTable'}
    for a,n in B.labels.items(): labels[a]=n
    def sym16(v,ins):
        if v in RAM: return RAM[v]
        if v==0xFF30: return '_AUD3WAVERAM'
        if 0x4000<=v<0x8000:
            if v in NAMES: return NAMES[v]
            if v in labels: return labels[v]
        return None
    def symh(v): return hwinc.HW.get(v,hx(v,4))
    data={0x4344:(64,[f'dwb {NAMES.get(t, "Music_NextByte")}' for t in jt1]),
          0x4D36:(22,[f'dwb {NAMES[t]}' for t in jt2]),
          0x495F:(16,['db '+', '.join(hx(B.g(0x495F+i)) for i in range(16))]),
          0x496F:(16,['db '+', '.join(hx(B.g(0x496F+i)) for i in range(16))])}
    ce=CodeEmitter(get,code,NAMES,sym16,symh,data,COMMENTS)
    return ce.emit(0x4000,0x4F37)

def tail(B,bk):
    a=DATA_END[bk]; end=REGION_END[bk]; o=['']
    if bk==0x1A:
        z=a
        while B.g(z)==0: z+=1
        o+=[f'\tds {z-a}, $00 ; padding','','; Credit text (not read by the driver)','CreditText:']
        for x in range(z,end,16):
            o.append('\tdb "'+bytes(B.g(y) for y in range(x,x+16)).decode('ascii')+'"')
        return o
    n=end-a; assert all(B.g(x)==0xFF for x in range(a,end))
    return o+[f'\tds {n}, $FF ; end of bank']
def orphan_pattern(B,a,e):
    # does [a,e) parse as one complete pattern?
    x=a
    while x<e:
        b=B.g(x)
        if b<0x20:
            if b>=0x14: return False
            x+=1+ARGS[b]
            if b==0: return x==e
        else: x+=1
    return False
# ---------------------------------------------------------------- main
os.makedirs(OUT,exist_ok=True)
w('GB_Hardware.inc',hwinc.hw_inc())
w('MM_RAM.inc',mmram.inc())
w('MM_Macros.inc',macros())
banks={bk:Bank(rom,bk,DATA_END[bk]) for bk in BANKS}
B7=banks[7]
hdr=lambda t: [f'; {t}','; Generated by tools/mmgen.py from the ROM; edit freely, build_check.sh verifies.','']
w('MM_Driver.inc','\n'.join(hdr('Mole Mania sound driver code, $4000-$4F36 (identical in banks $07, $0B and $1A).\n; Every table address it uses is a label, so the three banks assemble from this one file.')+driver(B7))+'\n')
w('MM_Tables.inc','\n'.join(hdr('Length tables and the two frequency tables ($4F37-$50FA), identical in all banks.\n; FreqTable_SGB is used for music when wSystemFlags bit 7 (SGB) is set; its periods\n; are ~2.4 % lower to cancel the SGB\'s faster clock.')+emit_data(B7,0x4F37,0x50FB))+'\n')
# common block: SfxTable .. NoiseTable end
def common_range(B):
    first_song=min(a for a,(sz,k,i) in B.items.items() if k in('step','stepend','frame') or (k in('ev','cmd') ))
    return B.sfxtab, B.noisetab+16
cs,ce_=common_range(B7)
w('MM_Common.inc','\n'.join(hdr('Sound effects, envelope/duty sequences, waves and the noise table:\n; the same data in all three banks (only its address differs).')+emit_data(B7,cs,ce_))+'\n')
for bk,B in banks.items():
    s,e=common_range(B)
    w(f'MM_Bank{bk:02X}_Songs.inc','\n'.join(hdr(f'Bank ${bk:02X}: song data ${e:04X}-${DATA_END[bk]-1:04X}')+emit_data(B,e,DATA_END[bk])+tail(B,bk))+'\n')
    w(f'MM_Bank{bk:02X}_SongTable.inc','\n'.join(hdr(f'Bank ${bk:02X}: song table ({B.nsongs} entries; song n = entry n-1)')+emit_data(B,0x50FB,B.sfxtab))+'\n')
    w(f'MM_Bank{bk:02X}.asm','\n'.join([f'; Mole Mania sound bank ${bk:02X}','',
        'INCLUDE "GB_Hardware.inc"','INCLUDE "MM_RAM.inc"','INCLUDE "MM_Macros.inc"','',
        f'SECTION "Mole Mania sound bank ${bk:02X}", ROMX[$4000], BANK[${bk:02X}]','',
        'INCLUDE "MM_Driver.inc"','INCLUDE "MM_Tables.inc"',f'INCLUDE "MM_Bank{bk:02X}_SongTable.inc"',
        'INCLUDE "MM_Common.inc"',f'INCLUDE "MM_Bank{bk:02X}_Songs.inc"',
        f'ASSERT @ == ${REGION_END[bk]:04X}','']))
print('ok')
