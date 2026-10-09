#!/usr/bin/env python3
"""Generate labeled ca65 disassemblies of the Rare NES sound engine
(Battletoads / Battletoads & Double Dragon).

usage: gen_disasm.py <game> <rom.nes> <out.asm>
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from m6502 import decode
from rareparse import TrackParser, SfxParser, note_name
import games

def main():
    game, romfile, outfile = sys.argv[1:4]
    cfg = games.CONFIGS[game]
    rom = open(romfile, 'rb').read()[16:]
    bank = cfg['bank']
    mem = rom[bank * 0x8000:(bank + 1) * 0x8000]
    D = Disasm(cfg, mem)
    D.build()
    open(outfile, 'w', newline='\n').write(D.render())
    # linker config
    cfgfile = os.path.splitext(outfile)[0] + '.cfg'
    open(cfgfile, 'w', newline='\n').write(D.linker_cfg())

B = 0x8000

class Item:
    __slots__ = ('addr', 'size', 'lines', 'kind')
    def __init__(s, addr, size, lines, kind):
        s.addr, s.size, s.lines, s.kind = addr, size, lines, kind

class Disasm:
    def __init__(s, cfg, mem):
        s.cfg, s.mem = cfg, mem
        s.items = {}          # addr -> Item
        s.owner = {}          # byte addr -> item addr
        s.labels = dict(cfg['labels'])   # addr -> name
        s.comments = dict(cfg.get('comments', {}))
        s.blocks = dict(cfg.get('blocks', {}))   # addr -> block comment text (before label)
        s.ram = cfg['ram']
        s.want_label = set()
        s.equates = []
    def b(s, a): return s.mem[a - B]
    def w(s, a): return s.b(a) | s.b(a + 1) << 8
    def in_region(s, a):
        return any(lo <= a < hi for lo, hi in s.cfg['regions'])
    def add_item(s, addr, size, lines, kind):
        for j in range(size):
            if addr + j in s.owner:
                o = s.owner[addr + j]
                if o == addr and s.items[o].kind == kind and s.items[o].size == size:
                    return
                raise Exception('overlap at %04X (item %04X %s vs new %04X %s)' %
                                (addr + j, o, s.items[o].kind, addr, kind))
        it = Item(addr, size, lines, kind)
        s.items[addr] = it
        for j in range(size): s.owner[addr + j] = addr

    # ------------------------------------------------------------------ labels
    def label_for(s, a, prefix='L_'):
        """Name for address a inside the region; registers need for a label."""
        if a in s.labels: return s.labels[a]
        s.labels[a] = '%s%04X' % (prefix, a)
        return s.labels[a]
    def sym(s, a, size=2):
        """Operand text for an absolute/zp address."""
        if a in s.ram: return s.ram[a]
        for base, name, span, stride in s.cfg.get('ram_arrays', ()):
            off = a - base
            if 0 < off < span and off % stride == 0: return '%s+%d' % (name, off)
        if B <= a <= 0xFFFF and s.in_region(a):
            return s.label_for(a)
        if a in s.cfg.get('extern', {}): return s.cfg['extern'][a]
        return ('$%02X' % a) if size == 1 else ('$%04X' % a)

    # -------------------------------------------------------------------- code
    def trace_code(s):
        todo = list(s.cfg['code_entries'])
        ct = s.cfg.get('cmd_table')
        if ct:
            todo += [s.w(ct + 2 * i) for i in range(s.cfg['ncmd'])]
        code = {}
        stop = set(s.cfg.get('code_stops', ()))
        while todo:
            pc = todo.pop()
            while True:
                if pc in code or not s.in_region(pc): break
                r = decode(s.mem, pc, B)
                if r is None: raise Exception('bad opcode at %04X' % pc)
                mn, md, v, n = r
                code[pc] = r
                if md == 'rel' or (mn in ('jsr', 'jmp') and md == 'abs'):
                    if s.in_region(v): todo.append(v)
                if mn in ('rts', 'rti', 'brk') or mn == 'jmp' or pc in stop: break
                pc += n
        s.code = code
        for pc, r in code.items():
            mn, md, v, n = r
            if md == 'rel' or (mn in ('jsr', 'jmp') and md == 'abs'):
                if s.in_region(v): s.label_for(v)

    def fmt_ins(s, pc, r):
        mn, md, v, n = r
        ov = s.cfg.get('operand', {}).get(pc)
        if ov is not None:
            return '%s %s' % (mn, ov) if ov else mn
        if md == 'imp': return mn
        if md == 'acc': return mn + ' a'
        if md == 'imm': return '%s #$%02X' % (mn, v)
        if md in ('zp', 'zpx', 'zpy', 'izx', 'izy'):
            t = s.sym(v, 1)
            return mn + ' ' + {'zp': '%s', 'zpx': '%s,x', 'zpy': '%s,y',
                               'izx': '(%s,x)', 'izy': '(%s),y'}[md] % t
        if md == 'rel': return '%s %s' % (mn, s.sym(v))
        t = s.sym(v)
        if v < 0x100 and md in ('abs', 'abx', 'aby'): t = 'a:' + t
        return mn + ' ' + {'abs': '%s', 'abx': '%s,x', 'aby': '%s,y', 'ind': '(%s)'}[md] % t

    def emit_code(s):
        for pc in sorted(s.code):
            r = s.code[pc]
            s.add_item(pc, r[3], None, 'code')   # lines rendered later (labels known)

    # -------------------------------------------------------------------- data
    def hexb(s, a, n): return ', '.join('$%02X' % s.b(a + j) for j in range(n))

    def emit_bytes(s, a, n, comment=None, kind='data', per=16):
        lines = []
        for j in range(0, n, per):
            k = min(per, n - j)
            lines.append('.byte ' + s.hexb(a + j, k))
        if comment: lines[0] += '  ; ' + comment
        s.add_item(a, n, lines, kind)

    def emit_raw_unreferenced(s):
        for lo, hi, name, text in s.cfg.get('foreign', ()):
            s.labels[lo] = name
            s.add_item(lo, hi - lo, ['.byte ' + s.hexb(lo + j, min(16, hi - lo - j))
                                     for j in range(0, hi - lo, 16)], 'foreign')
            s.blocks[lo] = text
        notes = s.cfg.get('unref_notes', {})
        for a, t in notes.items(): s.blocks[a] = t
        for lo, hi in s.cfg['regions']:
            a = lo
            while a < hi:
                if a in s.owner: a += 1; continue
                st = a
                while a < hi and a not in s.owner: a += 1
                s.label_for(st, 'Unref_')
                s.add_item(st, a - st, ['.byte ' + s.hexb(st + j, min(16, a - st - j))
                                        for j in range(0, a - st, 16)], 'unref')
                s.blocks.setdefault(st, 'Unreferenced bytes (never read by the engine)')

    def build(s):
        cfg = s.cfg
        s.trace_code()
        s.emit_code()
        for fn in cfg['data_builders']:
            fn(s)
        s.emit_raw_unreferenced()

    # ------------------------------------------------------------------ render
    def render(s):
        cfg = s.cfg
        out = []
        out.append(cfg['header'].rstrip('\n'))
        out.append('')
        out.append('.setcpu "6502"')
        out.append('')
        out.append(';' + '-' * 77)
        out.append('; RAM')
        out.append(';' + '-' * 77)
        for a in sorted(cfg['ram_defs']):
            name, cmt = cfg['ram_defs'][a]
            out.append('%-22s = $%04X%s' % (name, a, ('    ; ' + cmt) if cmt else '') if a >= 0x100 else
                       '%-22s = $%02X%s' % (name, a, ('    ; ' + cmt) if cmt else ''))
        out.append('')
        out.append(';' + '-' * 77)
        out.append('; Hardware and code outside the disassembled range')
        out.append(';' + '-' * 77)
        for a in sorted(cfg['extern']):
            out.append('%-22s = $%04X' % (cfg['extern'][a], a))
        out.append('')
        out.append(cfg['constants'].rstrip('\n'))
        out.append('')
        # pre-render code lines now that labels are complete (sym() may add labels)
        for a in sorted(s.items):
            it = s.items[a]
            if it.kind == 'code':
                it.lines = [s.fmt_ins(a, s.code[a])]
        # mid-item labels -> aliases
        aliases = []
        for a, name in sorted(s.labels.items()):
            if a in s.items: continue
            if a in s.owner:
                o = s.owner[a]
                aliases.append((name, '%s+%d' % (s.label_for(o), a - o)))
            elif s.in_region(a):
                raise Exception('label %s at %04X not owned' % (name, a))
        # second pass in case alias creation added labels to item starts
        for ri, (lo, hi) in enumerate(cfg['regions']):
            out.append(';' + '=' * 77)
            out.append('.segment "%s"    ; $%04X-$%04X (bank %d)' % (cfg['segments'][ri], lo, hi - 1, cfg['bank']))
            out.append(';' + '=' * 77)
            out.append('')
            a = lo
            prevkind = None
            while a < hi:
                it = s.items[a]
                if a in s.blocks and s.blocks[a] == '':
                    out.append('')
                elif a in s.blocks:
                    out.append('')
                    for ln in s.blocks[a].split('\n'):
                        out.append(('; ' + ln) if ln else ';')
                if a in s.labels:
                    if a not in s.blocks and prevkind is not None and (
                            (it.kind == 'code' and prevkind == 'code' and not s.labels[a].startswith('L_'))
                            or it.kind != prevkind):
                        out.append('')
                    out.append('%s:' % s.labels[a])
                cmt = s.comments.get(a)
                for i, ln in enumerate(it.lines):
                    if it.kind == 'code':
                        txt = '        %-28s; $%04X' % (ln, a)
                        if cmt: txt += '  ' + cmt
                    else:
                        txt = '        ' + ln
                        if i == 0 and cmt: txt = '        %-40s ; %s' % (ln, cmt) if ';' not in ln else txt + '  ' + cmt
                    out.append(txt.rstrip())
                prevkind = it.kind
                a += it.size
            out.append('')
        aliases += s.equates
        if aliases:
            out.append(';' + '-' * 77)
            out.append('; Labels that point inside other items (overlapping code/data)')
            out.append(';' + '-' * 77)
            for n, e in aliases:
                out.append('%s = %s' % (n, e))
            out.append('')
        for ln in cfg.get('trailer', []): out.append(ln)
        return '\n'.join(out) + '\n'

    def linker_cfg(s):
        cfg = s.cfg
        m = ['MEMORY {']
        for i, (lo, hi) in enumerate(cfg['regions']):
            m.append('    R%d: start = $%04X, size = $%04X, file = "%%O.%d.bin", fill = no;' % (i, lo, hi - lo, i))
        m.append('}')
        m.append('SEGMENTS {')
        for i, sg in enumerate(cfg['segments']):
            m.append('    %s: load = R%d, type = ro;' % (sg, i))
        m.append('}')
        return '\n'.join(m) + '\n'

if __name__ == '__main__':
    main()
