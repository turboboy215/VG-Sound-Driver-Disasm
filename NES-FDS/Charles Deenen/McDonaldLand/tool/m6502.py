# Minimal 6502 opcode table + recursive-descent tracer.
OPS = {}
def _a(mode, names):
    for op, n in names.items(): OPS[op] = (n, mode)
_a('imp',{0x00:'brk',0x08:'php',0x0a:'asl a',0x18:'clc',0x28:'plp',0x2a:'rol a',0x38:'sec',0x40:'rti',0x48:'pha',0x4a:'lsr a',0x58:'cli',0x60:'rts',0x68:'pla',0x6a:'ror a',0x78:'sei',0x88:'dey',0x8a:'txa',0x98:'tya',0x9a:'txs',0xa8:'tay',0xaa:'tax',0xb8:'clv',0xba:'tsx',0xc8:'iny',0xca:'dex',0xd8:'cld',0xe8:'inx',0xea:'nop',0xf8:'sed'})
_a('imm',{0x09:'ora',0x29:'and',0x49:'eor',0x69:'adc',0xa0:'ldy',0xa2:'ldx',0xa9:'lda',0xc0:'cpy',0xc9:'cmp',0xe0:'cpx',0xe9:'sbc'})
_a('zp',{0x05:'ora',0x06:'asl',0x24:'bit',0x25:'and',0x26:'rol',0x45:'eor',0x46:'lsr',0x65:'adc',0x66:'ror',0x84:'sty',0x85:'sta',0x86:'stx',0xa4:'ldy',0xa5:'lda',0xa6:'ldx',0xc4:'cpy',0xc5:'cmp',0xc6:'dec',0xe4:'cpx',0xe5:'sbc',0xe6:'inc'})
_a('zpx',{0x15:'ora',0x16:'asl',0x35:'and',0x36:'rol',0x55:'eor',0x56:'lsr',0x75:'adc',0x76:'ror',0x94:'sty',0x95:'sta',0xb4:'ldy',0xb5:'lda',0xd5:'cmp',0xd6:'dec',0xf5:'sbc',0xf6:'inc'})
_a('zpy',{0x96:'stx',0xb6:'ldx'})
_a('abs',{0x0d:'ora',0x0e:'asl',0x20:'jsr',0x2c:'bit',0x2d:'and',0x2e:'rol',0x4c:'jmp',0x4d:'eor',0x4e:'lsr',0x6d:'adc',0x6e:'ror',0x8c:'sty',0x8d:'sta',0x8e:'stx',0xac:'ldy',0xad:'lda',0xae:'ldx',0xcc:'cpy',0xcd:'cmp',0xce:'dec',0xec:'cpx',0xed:'sbc',0xee:'inc'})
_a('abx',{0x1d:'ora',0x1e:'asl',0x3d:'and',0x3e:'rol',0x5d:'eor',0x5e:'lsr',0x7d:'adc',0x7e:'ror',0x9d:'sta',0xbc:'ldy',0xbd:'lda',0xdd:'cmp',0xde:'dec',0xfd:'sbc',0xfe:'inc'})
_a('aby',{0x19:'ora',0x39:'and',0x59:'eor',0x79:'adc',0x99:'sta',0xb9:'lda',0xbe:'ldx',0xd9:'cmp',0xf9:'sbc'})
_a('ind',{0x6c:'jmp'})
_a('izx',{0x01:'ora',0x21:'and',0x41:'eor',0x61:'adc',0x81:'sta',0xa1:'lda',0xc1:'cmp',0xe1:'sbc'})
_a('izy',{0x11:'ora',0x31:'and',0x51:'eor',0x71:'adc',0x91:'sta',0xb1:'lda',0xd1:'cmp',0xf1:'sbc'})
_a('rel',{0x10:'bpl',0x30:'bmi',0x50:'bvc',0x70:'bvs',0x90:'bcc',0xb0:'bcs',0xd0:'bne',0xf0:'beq'})
SIZE = {'imp':1,'imm':2,'zp':2,'zpx':2,'zpy':2,'izx':2,'izy':2,'rel':2,'abs':3,'abx':3,'aby':3,'ind':3}

def decode(mem, base, pc):
    op = mem[pc-base]
    if op not in OPS: return None
    n, m = OPS[op]; s = SIZE[m]
    arg = None
    if s == 2: arg = mem[pc-base+1]
    if s == 3: arg = mem[pc-base+1] | mem[pc-base+2] << 8
    if m == 'rel': arg = (pc + 2 + (arg - 256 if arg > 127 else arg)) & 0xffff
    return n, m, s, arg

def trace(mem, base, entries):
    code = {}  # pc -> (n,m,s,arg)
    todo = list(entries)
    while todo:
        pc = todo.pop()
        while base <= pc < base + len(mem) and pc not in code:
            r = decode(mem, base, pc)
            if r is None: print('bad op at %04x' % pc); break
            code[pc] = r; n, m, s, arg = r
            if m == 'rel': todo.append(arg)
            if n == 'jsr' and base <= arg < base+len(mem): todo.append(arg)
            if n == 'jmp' and m == 'abs': pc = arg; continue
            if n in ('rts', 'rti', 'brk') or (n == 'jmp'): break
            pc += s
    return code

def fmt(n, m, arg, lab=lambda a, w: ('$%04X' if w else '$%02X') % a):
    if m == 'imp': return n
    if m == 'imm': return '%s #$%02X' % (n, arg)
    if m == 'zp': return '%s %s' % (n, lab(arg, 0))
    if m == 'zpx': return '%s %s,x' % (n, lab(arg, 0))
    if m == 'zpy': return '%s %s,y' % (n, lab(arg, 0))
    if m == 'izx': return '%s (%s,x)' % (n, lab(arg, 0))
    if m == 'izy': return '%s (%s),y' % (n, lab(arg, 0))
    if m == 'ind': return '%s (%s)' % (n, lab(arg, 1))
    if m in ('abs', 'rel'): return '%s %s' % (n, lab(arg, 1))
    if m == 'abx': return '%s %s,x' % (n, lab(arg, 1))
    if m == 'aby': return '%s %s,y' % (n, lab(arg, 1))
