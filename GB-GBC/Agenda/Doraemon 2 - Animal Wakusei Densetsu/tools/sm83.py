# Minimal SM83 disassembler
R=['b','c','d','e','h','l','[hl]','a']
RP=['bc','de','hl','sp']; RP2=['bc','de','hl','af']
CC=['nz','z','nc','c']
ALU=['add a,','adc a,','sub ','sbc a,','and ','xor ','or ','cp ']
CB=['rlc','rrc','rl','rr','sla','sra','swap','srl']
def dis(mem, pc, base=0):
    """mem: bytes; pc: offset into mem; base: address of mem[0]. returns (text, length, target or None, kind)"""
    o=mem[pc]; a=pc+base
    def b1(): return mem[pc+1]
    def w(): return mem[pc+1]|mem[pc+2]<<8
    x=o>>6; y=(o>>3)&7; z=o&7; p=y>>1; q=y&1
    if o==0xCB:
        c=mem[pc+1]; cx=c>>6; cy=(c>>3)&7; cz=c&7
        if cx==0: return (f'{CB[cy]} {R[cz]}',2,None,'')
        return (f"{['','bit','res','set'][cx]} {cy},{R[cz]}",2,None,'')
    if x==0:
        if z==0:
            if y==0: return ('nop',1,None,'')
            if y==1: return (f'ld [${w():04X}],sp',3,None,'')
            if y==2: return ('stop',2,None,'')
            d=b1(); d=d-256 if d>127 else d; t=(a+2+d)&0xFFFF
            if y==3: return (f'jr ${t:04X}',2,t,'jr')
            return (f'jr {CC[y-4]},${t:04X}',2,t,'jrc')
        if z==1:
            if q==0: return (f'ld {RP[p]},${w():04X}',3,w(),'imm16')
            return (f'add hl,{RP[p]}',1,None,'')
        if z==2:
            m=['[bc]','[de]','[hl+]','[hl-]'][p]
            return ((f'ld {m},a' if q==0 else f'ld a,{m}'),1,None,'')
        if z==3: return ((f'inc {RP[p]}' if q==0 else f'dec {RP[p]}'),1,None,'')
        if z==4: return (f'inc {R[y]}',1,None,'')
        if z==5: return (f'dec {R[y]}',1,None,'')
        if z==6: return (f'ld {R[y]},${b1():02X}',2,None,'')
        return (['rlca','rrca','rla','rra','daa','cpl','scf','ccf'][y],1,None,'')
    if x==1:
        if o==0x76: return ('halt',1,None,'')
        return (f'ld {R[y]},{R[z]}',1,None,'')
    if x==2: return (f'{ALU[y]}{R[z]}',1,None,'')
    # x==3
    if z==0:
        if y<4: return (f'ret {CC[y]}',1,None,'retc')
        if y==4: return (f'ldh [${0xFF00+b1():04X}],a',2,None,'')
        if y==5:
            d=b1(); d=d-256 if d>127 else d; return (f'add sp,{d}',2,None,'')
        if y==6: return (f'ldh a,[${0xFF00+b1():04X}]',2,None,'')
        d=b1(); d=d-256 if d>127 else d; return (f'ld hl,sp{d:+d}',2,None,'')
    if z==1:
        if q==0: return (f'pop {RP2[p]}',1,None,'')
        return (['ret','reti','jp hl','ld sp,hl'][p],1,None,['ret','ret','jphl',''][p])
    if z==2:
        if y<4: return (f'jp {CC[y]},${w():04X}',3,w(),'jpc')
        return (['ldh [c],a',f'ld [${w():04X}],a','ldh a,[c]',f'ld a,[${w():04X}]'][y-4],[1,3,1,3][y-4],None,'')
    if z==3:
        if y==0: return (f'jp ${w():04X}',3,w(),'jp')
        if y==6: return ('di',1,None,'')
        if y==7: return ('ei',1,None,'')
        return (f'db ${o:02X}',1,None,'bad')
    if z==4:
        if y<4: return (f'call {CC[y]},${w():04X}',3,w(),'call')
        return (f'db ${o:02X}',1,None,'bad')
    if z==5:
        if q==0: return (f'push {RP2[p]}',1,None,'')
        if p==0: return (f'call ${w():04X}',3,w(),'call')
        return (f'db ${o:02X}',1,None,'bad')
    if z==6: return (f'{ALU[y]}${b1():02X}',2,None,'')
    return (f'rst ${y*8:02X}',1,y*8,'rst')
