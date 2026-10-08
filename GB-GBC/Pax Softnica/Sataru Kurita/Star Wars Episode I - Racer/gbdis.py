"""SM83 disassembler producing RGBDS 0.9 syntax with operand placeholders.
decode(get, pc) -> Ins(pc, size, text, kind, val, flow, target)
text contains '{}' where the operand symbol goes (if kind is not None)."""
from dataclasses import dataclass
R8=['b','c','d','e','h','l','[hl]','a']
R16=['bc','de','hl','sp']; R16S=['bc','de','hl','af']
CC=['nz','z','nc','c']
ALU=['add a, ','adc a, ','sub a, ','sbc a, ','and a, ','xor a, ','or a, ','cp a, ']
ALUs=['add a, ','adc a, ','sub ','sbc a, ','and ','xor ','or ','cp ']
def s8(v): return v-256 if v>=128 else v
@dataclass
class Ins:
    pc:int; size:int; text:str; kind:object; val:int; flow:str; target:object
def decode(get,pc):
    op=get(pc); b1=get(pc+1); w=get(pc+1)|get(pc+2)<<8
    def I(sz,t,kind=None,val=None,flow='next',target=None): return Ins(pc,sz,t,kind,val,flow,target)
    if op==0xCB:
        c=b1; r=R8[c&7]; x=c>>6; y=(c>>3)&7
        if x==0: return I(2,['rlc','rrc','rl','rr','sla','sra','swap','srl'][y]+' '+r)
        return I(2,['','bit','res','set'][x]+f' {y}, {r}')
    x=op>>6; y=(op>>3)&7; z=op&7; p=y>>1; q=y&1
    if op==0x00: return I(1,'nop')
    if op==0x08: return I(3,'ld [{}], sp','addr16',w)
    if op==0x10: return I(2,'stop') if b1==0 else I(1,'db $10',flow='stop')
    if op==0x18: t=(pc+2+s8(b1))&0xffff; return I(2,'jr {}','rel',t,'jump',t)
    if x==0 and z==0 and y>=4: t=(pc+2+s8(b1))&0xffff; return I(2,f'jr {CC[y-4]}, {{}}','rel',t,'cond',t)
    if x==0 and z==1:
        if q==0: return I(3,f'ld {R16[p]}, {{}}','imm16',w)
        return I(1,f'add hl, {R16[p]}')
    if x==0 and z==2:
        return I(1,['ld [bc], a','ld a, [bc]','ld [de], a','ld a, [de]','ld [hli], a','ld a, [hli]','ld [hld], a','ld a, [hld]'][p*2+q])
    if x==0 and z==3: return I(1,('inc ' if q==0 else 'dec ')+R16[p])
    if x==0 and z==4: return I(1,'inc '+R8[y])
    if x==0 and z==5: return I(1,'dec '+R8[y])
    if x==0 and z==6: return I(2,f'ld {R8[y]}, {{}}','imm8',b1)
    if x==0 and z==7: return I(1,['rlca','rrca','rla','rra','daa','cpl','scf','ccf'][y])
    if op==0x76: return I(1,'halt')
    if x==1: return I(1,f'ld {R8[y]}, {R8[z]}')
    if x==2: return I(1,f'{ALUs[y]}{R8[z]}')
    if z==0:
        if y<4: return I(1,f'ret {CC[y]}',flow='cond_ret')
        if y==4: return I(2,'ldh [{}], a','hram',0xff00|b1)
        if y==5: return I(2,f'add sp, {s8(b1)}')
        if y==6: return I(2,'ldh a, [{}]','hram',0xff00|b1)
        v=s8(b1); return I(2,f'ld hl, sp {"+" if v>=0 else "-"} {abs(v)}')
    if z==1:
        if q==0: return I(1,f'pop {R16S[p]}')
        return [I(1,'ret',flow='ret'),I(1,'reti',flow='ret'),I(1,'jp hl',flow='stop'),I(1,'ld sp, hl')][p]
    if z==2:
        if y<4: return I(3,f'jp {CC[y]}, {{}}','jp',w,'cond',w)
        if y==4: return I(1,'ldh [c], a')
        if y==5: return I(3,'ld [{}], a','addr16',w)
        if y==6: return I(1,'ldh a, [c]')
        return I(3,'ld a, [{}]','addr16',w)
    if z==3:
        if y==0: return I(3,'jp {}','jp',w,'jump',w)
        if y==6: return I(1,'di')
        if y==7: return I(1,'ei')
        return I(1,f'db ${op:02X}',flow='stop')
    if z==4:
        if y<4: return I(3,f'call {CC[y]}, {{}}','call',w,'call',w)
        return I(1,f'db ${op:02X}',flow='stop')
    if z==5:
        if q==0: return I(1,f'push {R16S[p]}')
        if p==0: return I(3,'call {}','call',w,'call',w)
        return I(1,f'db ${op:02X}',flow='stop')
    if z==6: return I(2,f'{ALUs[y]}{{}}','imm8',b1)
    return I(1,f'rst ${y*8:02X}',flow='call' if y*8 not in (0x28,) else 'call')
def trace(get,entries,lo,hi,stops=(),inline_rst=None,ret_rst=()):
    code={}; todo=list(entries)
    while todo:
        pc=todo.pop()
        while lo<=pc<hi and pc not in code:
            ins=decode(get,pc)
            if ins.text.startswith('rst '):
                v=int(ins.text[5:],16)
                if v==inline_rst:
                    ins=Ins(pc,4,'FARCALL',None,None,'next',None); ins.far=(get(pc+1)|get(pc+2)<<8,get(pc+3))
                elif v in ret_rst:
                    ins=Ins(pc,1,ins.text,None,None,'ret',None)
            code[pc]=ins
            if ins.target is not None and ins.flow in('jump','cond','call') and lo<=ins.target<hi: todo.append(ins.target)
            if ins.flow in('jump','ret','stop') or pc in stops: break
            pc+=ins.size
    return code
