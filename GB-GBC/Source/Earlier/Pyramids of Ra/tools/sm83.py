# Minimal SM83 disassembler: decode(rom, addr_in_file) -> (length, mnemonic_template, operand_info)
R8=['b','c','d','e','h','l','[hl]','a']
R16=['bc','de','hl','sp']; R16S=['bc','de','hl','af']
CC=['nz','z','nc','c']
ALU=['add a,','adc a,','sub ','sbc a,','and ','xor ','or ','cp ']
CB=['rlc','rrc','rl','rr','sla','sra','swap','srl']
def decode(b, p):
    """returns (len, text, target) ; target = abs 16-bit addr for jumps/calls or None.
    text uses {n8},{n16},{e8} placeholders resolved here."""
    op=b[p]
    def n8(): return b[p+1]
    def n16(): return b[p+1]|(b[p+2]<<8)
    x,y,z=op>>6,(op>>3)&7,op&7
    if op==0x00: return 1,'nop',None
    if op==0x08: return 3,'ld [${:04X}],sp'.format(n16()),None
    if op==0x10: return 2,'stop',None
    if op==0x18: return 2,'jr',('jr',None,(n8()^0x80)-0x80)
    if x==0 and z==0 and y>=4: return 2,'jr',('jr',CC[y-4],(n8()^0x80)-0x80)
    if x==0 and z==1:
        if y&1==0: return 3,'ld {},${:04X}'.format(R16[y>>1],n16()),('imm16',n16())
        return 1,'add hl,{}'.format(R16[y>>1]),None
    if x==0 and z==2:
        t=['ld [bc],a','ld a,[bc]','ld [de],a','ld a,[de]','ld [hli],a','ld a,[hli]','ld [hld],a','ld a,[hld]']
        return 1,t[y],None
    if x==0 and z==3: return 1,('inc ' if y&1==0 else 'dec ')+R16[y>>1],None
    if x==0 and z==4: return 1,'inc '+R8[y],None
    if x==0 and z==5: return 1,'dec '+R8[y],None
    if x==0 and z==6: return 2,'ld {},${:02X}'.format(R8[y],n8()),None
    if x==0 and z==7: return 1,['rlca','rrca','rla','rra','daa','cpl','scf','ccf'][y],None
    if op==0x76: return 1,'halt',None
    if x==1: return 1,'ld {},{}'.format(R8[y],R8[z]),None
    if x==2: return 1,ALU[y]+R8[z],None
    if x==3:
        if z==0:
            if y<4: return 1,'ret '+CC[y],None
            if y==4: return 2,'ldh [${:02X}],a'.format(n8()),('ldh',n8())
            if y==5: return 2,'add sp,${:02X}'.format(n8()),None
            if y==6: return 2,'ldh a,[${:02X}]'.format(n8()),('ldh',n8())
            if y==7: return 2,'ld hl,sp+${:02X}'.format(n8()),None
        if z==1:
            if y&1==0: return 1,'pop '+R16S[y>>1],None
            return 1,['ret','reti','jp hl','ld sp,hl'][y>>1],None
        if z==2:
            if y<4: return 3,'jp',('jp',CC[y],n16())
            return [(1,'ldh [c],a',None),(3,'ld [${:04X}],a'.format(n16()),('mem',n16())),(1,'ldh a,[c]',None),(3,'ld a,[${:04X}]'.format(n16()),('mem',n16()))][y-4]
        if z==3:
            if y==0: return 3,'jp',('jp',None,n16())
            if y==1:
                c=b[p+1]; cx,cy,cz=c>>6,(c>>3)&7,c&7
                if cx==0: return 2,'{} {}'.format(CB[cy],R8[cz]),None
                return 2,'{} {},{}'.format(['','bit','res','set'][cx],cy,R8[cz]),None
            if y==6: return 1,'di',None
            if y==7: return 1,'ei',None
            return 1,'db ${:02X}'.format(op),'bad'
        if z==4:
            if y<4: return 3,'call',('call',CC[y],n16())
            return 1,'db ${:02X}'.format(op),'bad'
        if z==5:
            if y&1==0: return 1,'push '+R16S[y>>1],None
            if y==1: return 3,'call',('call',None,n16())
            return 1,'db ${:02X}'.format(op),'bad'
        if z==6: return 2,ALU[y]+'${:02X}'.format(n8()),None
        if z==7: return 1,'rst ${:02X}'.format(y*8),('rst',y*8)
    return 1,'db ${:02X}'.format(op),'bad'
