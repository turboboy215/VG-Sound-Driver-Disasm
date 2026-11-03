#!/usr/bin/env python3
"""Minimal SM83 disassembler. usage: dis.py rom bank start end   (addresses in CPU space)"""
import sys

R8 = ['b','c','d','e','h','l','[hl]','a']
R16 = ['bc','de','hl','sp']
R16S = ['bc','de','hl','af']
CC = ['nz','z','nc','c']
ALU = ['add a,','adc a,','sub ','sbc a,','and ','xor ','or ','cp ']
CB = ['rlc','rrc','rl','rr','sla','sra','swap','srl']

def decode(m, pc):
    """m: function addr->byte. returns (length, text, target or None)"""
    op = m(pc)
    b1 = m(pc+1); b2 = m(pc+2)
    w = b1 | (b2 << 8)
    def s8(x): return x-256 if x >= 128 else x
    if op == 0x00: return 1, 'nop', None
    if op == 0x08: return 3, 'ld [$%04X],sp' % w, None
    if op == 0x10: return 2, 'stop', None
    if op == 0x18: t=(pc+2+s8(b1))&0xFFFF; return 2, 'jr $%04X' % t, t
    if op in (0x20,0x28,0x30,0x38): t=(pc+2+s8(b1))&0xFFFF; return 2, 'jr %s,$%04X' % (CC[(op>>3)&3], t), t
    if op & 0xCF == 0x01: return 3, 'ld %s,$%04X' % (R16[op>>4], w), None
    if op & 0xCF == 0x09: return 1, 'add hl,%s' % R16[op>>4], None
    if op in (0x02,0x12): return 1, 'ld [%s],a' % R16[op>>4], None
    if op in (0x0A,0x1A): return 1, 'ld a,[%s]' % R16[op>>4], None
    if op == 0x22: return 1, 'ld [hli],a', None
    if op == 0x32: return 1, 'ld [hld],a', None
    if op == 0x2A: return 1, 'ld a,[hli]', None
    if op == 0x3A: return 1, 'ld a,[hld]', None
    if op & 0xCF == 0x03: return 1, 'inc %s' % R16[op>>4], None
    if op & 0xCF == 0x0B: return 1, 'dec %s' % R16[op>>4], None
    if op & 0xC7 == 0x04: return 1, 'inc %s' % R8[(op>>3)&7], None
    if op & 0xC7 == 0x05: return 1, 'dec %s' % R8[(op>>3)&7], None
    if op & 0xC7 == 0x06: return 2, 'ld %s,$%02X' % (R8[(op>>3)&7], b1), None
    if op < 0x40:
        return 1, ['rlca','rrca','rla','rra','daa','cpl','scf','ccf'][(op>>3)&7], None
    if op == 0x76: return 1, 'halt', None
    if op < 0x80: return 1, 'ld %s,%s' % (R8[(op>>3)&7], R8[op&7]), None
    if op < 0xC0: return 1, '%s%s' % (ALU[(op>>3)&7], R8[op&7]), None
    if op in (0xC0,0xC8,0xD0,0xD8): return 1, 'ret %s' % CC[(op>>3)&3], None
    if op & 0xCF == 0xC1: return 1, 'pop %s' % R16S[(op>>4)&3], None
    if op & 0xCF == 0xC5: return 1, 'push %s' % R16S[(op>>4)&3], None
    if op in (0xC2,0xCA,0xD2,0xDA): return 3, 'jp %s,$%04X' % (CC[(op>>3)&3], w), w
    if op == 0xC3: return 3, 'jp $%04X' % w, w
    if op in (0xC4,0xCC,0xD4,0xDC): return 3, 'call %s,$%04X' % (CC[(op>>3)&3], w), w
    if op == 0xCD: return 3, 'call $%04X' % w, w
    if op & 0xC7 == 0xC6: return 2, '%s$%02X' % (ALU[(op>>3)&7], b1), None
    if op & 0xC7 == 0xC7: return 1, 'rst $%02X' % (op & 0x38), None
    if op == 0xC9: return 1, 'ret', None
    if op == 0xD9: return 1, 'reti', None
    if op == 0xCB:
        x = b1
        if x < 0x40: return 2, '%s %s' % (CB[x>>3], R8[x&7]), None
        return 2, '%s %d,%s' % (['bit','res','set'][(x>>6)-1], (x>>3)&7, R8[x&7]), None
    if op == 0xE0: return 2, 'ldh [$FF%02X],a' % b1, None
    if op == 0xF0: return 2, 'ldh a,[$FF%02X]' % b1, None
    if op == 0xE2: return 1, 'ldh [c],a', None
    if op == 0xF2: return 1, 'ldh a,[c]', None
    if op == 0xE8: return 2, 'add sp,%d' % s8(b1), None
    if op == 0xF8: return 2, 'ld hl,sp%+d' % s8(b1), None
    if op == 0xE9: return 1, 'jp hl', None
    if op == 0xF9: return 1, 'ld sp,hl', None
    if op == 0xEA: return 3, 'ld [$%04X],a' % w, None
    if op == 0xFA: return 3, 'ld a,[$%04X]' % w, None
    if op == 0xF3: return 1, 'di', None
    if op == 0xFB: return 1, 'ei', None
    return 1, 'db $%02X ; ???' % op, None

def loadrom(path):
    return open(path,'rb').read()

def mapper(rom, bank):
    def m(a):
        a &= 0xFFFF
        if a < 0x4000: return rom[a]
        if a < 0x8000: return rom[bank*0x4000 + a - 0x4000]
        return 0
    return m

if __name__ == '__main__':
    rom = loadrom(sys.argv[1]); bank = int(sys.argv[2],16)
    s = int(sys.argv[3],16); e = int(sys.argv[4],16)
    m = mapper(rom, bank); pc = s
    while pc < e:
        n, t, _ = decode(m, pc)
        print('%02X:%04X  %-9s %s' % (bank, pc, ' '.join('%02X'%m(pc+i) for i in range(n)), t))
        pc += n
