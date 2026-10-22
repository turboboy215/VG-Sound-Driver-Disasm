# Minimal SM83 disassembler: decode(rom_bytes, offset, pc) -> (length, mnemonic, target or None, kind)
R8=['b','c','d','e','h','l','[hl]','a']
R16=['bc','de','hl','sp']; R16S=['bc','de','hl','af']
CC=['nz','z','nc','c']
ALU=['add a,','adc a,','sub','sbc a,','and','xor','or','cp']
CB=['rlc','rrc','rl','rr','sla','sra','swap','srl']
def h8(v): return '$%02X'%v
def h16(v): return '$%04X'%v
def decode(b, o, pc):
    op=b[o]
    n8=lambda: b[o+1]
    n16=lambda: b[o+1]|(b[o+2]<<8)
    def rel(): d=b[o+1]; d=d-256 if d>127 else d; return (pc+2+d)&0xFFFF
    x,y,z=op>>6,(op>>3)&7,op&7
    if op==0x00: return 1,'nop',None,''
    if op==0x08: return 3,'ld [%s], sp'%h16(n16()),None,''
    if op==0x10: return 2,'stop',None,''
    if op==0x18: t=rel(); return 2,'jr %s'%h16(t),t,'jmp'
    if x==0 and z==0 and y>=4: t=rel(); return 2,'jr %s, %s'%(CC[y-4],h16(t)),t,'cjmp'
    if x==0 and z==1:
        if y%2==0: return 3,'ld %s, %s'%(R16[y//2],h16(n16())),n16(),'imm16'
        return 1,'add hl, %s'%R16[y//2],None,''
    if x==0 and z==2:
        m=['ld [bc], a','ld a, [bc]','ld [de], a','ld a, [de]','ld [hli], a','ld a, [hli]','ld [hld], a','ld a, [hld]']
        return 1,m[y],None,''
    if x==0 and z==3: return 1,('inc ' if y%2==0 else 'dec ')+R16[y//2],None,''
    if x==0 and z==4: return 1,'inc '+R8[y],None,''
    if x==0 and z==5: return 1,'dec '+R8[y],None,''
    if x==0 and z==6: return 2,'ld %s, %s'%(R8[y],h8(n8())),None,''
    if x==0 and z==7: return 1,['rlca','rrca','rla','rra','daa','cpl','scf','ccf'][y],None,''
    if op==0x76: return 1,'halt',None,''
    if x==1: return 1,'ld %s, %s'%(R8[y],R8[z]),None,''
    if x==2: return 1,'%s %s'%(ALU[y],R8[z]),None,''
    if x==3:
        if z==0:
            if y<4: return 1,'ret '+CC[y],None,'cret'
            if y==4: return 2,'ldh [%s], a'%h16(0xFF00|n8()),None,''
            if y==5: d=b[o+1]; d=d-256 if d>127 else d; return 2,'add sp, %d'%d,None,''
            if y==6: return 2,'ldh a, [%s]'%h16(0xFF00|n8()),None,''
            if y==7: d=b[o+1]; d=d-256 if d>127 else d; return 2,'ld hl, sp%+d'%d,None,''
        if z==1:
            if y%2==0: return 1,'pop '+R16S[y//2],None,''
            return 1,['ret','reti','jp hl','ld sp, hl'][y//2],None,['ret','ret','jphl',''][y//2]
        if z==2:
            if y<4: return 3,'jp %s, %s'%(CC[y],h16(n16())),n16(),'cjmp'
            if y==4: return 1,'ldh [c], a',None,''
            if y==5: return 3,'ld [%s], a'%h16(n16()),None,''
            if y==6: return 1,'ldh a, [c]',None,''
            return 3,'ld a, [%s]'%h16(n16()),None,''
        if z==3:
            if y==0: return 3,'jp %s'%h16(n16()),n16(),'jmp'
            if y==1:
                c=b[o+1]; xx,yy,zz=c>>6,(c>>3)&7,c&7
                if xx==0: return 2,'%s %s'%(CB[yy],R8[zz]),None,''
                return 2,'%s %d, %s'%(['','bit','res','set'][xx],yy,R8[zz]),None,''
            if y==6: return 1,'di',None,''
            if y==7: return 1,'ei',None,''
            return 1,'db $%02X'%op,None,'bad'
        if z==4:
            if y<4: return 3,'call %s, %s'%(CC[y],h16(n16())),n16(),'call'
            return 1,'db $%02X'%op,None,'bad'
        if z==5:
            if y%2==0: return 1,'push '+R16S[y//2],None,''
            if y==1: return 3,'call %s'%h16(n16()),n16(),'call'
            return 1,'db $%02X'%op,None,'bad'
        if z==6: return 2,'%s %s'%(ALU[y],h8(n8())),None,''
        if z==7: return 1,'rst $%02X'%(y*8),y*8,'call'
