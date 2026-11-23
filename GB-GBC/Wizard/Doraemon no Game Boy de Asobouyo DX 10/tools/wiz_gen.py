"""Generate the Wizard sound driver disassembly for one game.
usage: python wiz_gen.py dx10|quiz > out.asm"""
import sys, struct
sys.path.insert(0, __file__.rsplit('/', 1)[0])
from sm83 import decode
from wiz_cfg import GAMES, WRAM
from wiz_parse import Game, collect, fill_gaps
from wiz_names import GLOBALS, C

REGS = {0x10: 'rNR10', 0x11: 'rNR11', 0x12: 'rNR12', 0x13: 'rNR13', 0x14: 'rNR14', 0x16: 'rNR21', 0x17: 'rNR22',
        0x18: 'rNR23', 0x19: 'rNR24', 0x1A: 'rNR30', 0x1B: 'rNR31', 0x1C: 'rNR32', 0x1D: 'rNR33', 0x1E: 'rNR34',
        0x20: 'rNR41', 0x21: 'rNR42', 0x22: 'rNR43', 0x23: 'rNR44', 0x24: 'rNR50', 0x25: 'rNR51', 0x26: 'rNR52'}
NOTE = ['C_', 'Cs', 'D_', 'Ds', 'E_', 'F_', 'Fs', 'G_', 'Gs', 'A_', 'As', 'B_']
STRUCT_FIELDS = {0x00: 'TRK_PTR', 0x02: 'TRK_LENGTH', 0x04: 'TRK_GATE', 0x06: 'TRK_VOLUME', 0x07: 'TRK_UNUSED7',
                 0x08: 'TRK_UNUSED8', 0x09: 'TRK_DUTY', 0x0A: 'TRK_FLAGS', 0x0B: 'TRK_PERIOD', 0x0D: 'TRK_SP',
                 0x0F: 'TRK_STACK', 0x18: 'TRK_RETURN', 0x1B: 'TRK_VOLENVPOS', 0x1C: 'TRK_VOLENV',
                 0x1E: 'TRK_PITCHPOS', 0x1F: 'TRK_PITCHENV', 0x21: 'TRK_VOLOFS'}
CMD = {0x80: 'snd_end', 0x81: 'snd_volume', 0x82: 'snd_loop', 0x83: 'snd_endloop', 0x84: 'snd_wave',
       0x85: 'snd_jump', 0x86: 'snd_call', 0x87: 'snd_ret', 0x88: 'snd_volenv', 0x89: 'snd_pitchenv',
       0x8A: 'snd_panleft', 0x8B: 'snd_panright', 0x8C: 'snd_pancentre'}
TRACKNAME = ['Ch1', 'Ch2', 'Ch3', 'Ch4', 'Sfx1', 'Sfx2', 'Sfx3', 'Sfx4']


def note_name(n):
    return f'{NOTE[n % 12]}{n // 12}'


class Gen:
    def __init__(self, key):
        self.key = key
        self.g = Game(key)
        self.cfg = GAMES[key]
        self.v2 = self.cfg['version'] == 2
        self.out = []

    # ---- address mapping DX10 -> this game ----
    def m(self, a):
        if not self.v2 or a < 0x40BB:
            return a
        return a + 6

    def emit(self, s=''):
        self.out.append(s)

    # ---- symbols ----
    def wram_name(self, a):
        base = self.cfg['wram']
        o = a - base
        for off, name, size, _ in WRAM:
            if off <= o < off + size:
                if name == 'wSndTracks':
                    k, f = divmod(o - off, 0x22)
                    fld = STRUCT_FIELDS.get(f)
                    if fld:
                        return f'wSndTracks + {k} * TRK_SIZE + {fld}'
                    return f'wSndTracks + {k} * TRK_SIZE + ${f:02X}'
                return name if o == off else f'{name} + {o - off}'
        return None

    def rom_name(self, a, here_scope=None):
        if a in self.glob:
            return self.glob[a]
        if a in self.local:
            scope, lab = self.local[a]
            return lab if scope == here_scope else f'{scope}{lab}'
        if a == self.cfg['pitchtab']: return 'PitchEnvTable'
        if a == self.cfg['envtab']: return 'VolEnvTable'
        if a == self.cfg['wavetab']: return 'WaveTable'
        return None

    def operand(self, kind, val, scope):
        if kind == 'h8':
            return REGS.get(val, f'${val:02X}')
        if kind in ('jp', 'call', 'rel'):
            return self.rom_name(val, scope) or f'${val:04X}'
        if kind in ('a16', 'n16'):
            if 0xC000 <= val < 0xE000:
                n = self.wram_name(val)
                if n: return n
            if kind == 'n16':
                if 0x2000 <= val < 0x8000:
                    n = self.rom_name(val, scope)
                    if n: return n
                if val == 0xFF30: return '_AUD3WAVERAM'
                if val == 0x0022: return 'TRK_SIZE'
            return f'${val:04X}'
        if kind == 'n8':
            return f'${val:02X}'
        return f'${val:02X}'

    # ---- code ----
    def code_ranges(self):
        c = self.cfg
        return [(0x4000, c['jt']), (c['jt'] + 40, c['pantab']), (c['pantab'] + 8, c['actclr'])]

    def build_code_labels(self):
        self.glob = {}
        self.gcomment = {}
        self.export = set()
        for a, (n, exp, com) in GLOBALS.items():
            self.glob[self.m(a)] = n
            self.gcomment[self.m(a)] = com
            if exp: self.export.add(self.m(a))
        self.comments = {self.m(a): t for a, t in C.items()}
        if self.v2:
            for a in range(0x40BB, 0x40CA):
                self.comments.pop(self.m(a), None)
            self.comments[0x40BC] = 'header byte 0: struct mask'
            self.comments[0x40BF] = 'any SFX struct in the mask?'
            self.comments[0x40C3] = 'music only: game flag (sound option?) set -> ignore the request'
            self.comments[0x40CA] = 'music only: NR51 = 0'
        else:
            self.comments[0x40BE] = 'SFX on ch4 (struct 7) in the mask? then keep NR51'
            self.comments[0x40C3] = 'else NR51 = 0'
        # linear decode
        rd = lambda a: self.g.b4(a)
        self.ins = {}
        targets = set()
        for lo, hi in self.code_ranges():
            pc = lo
            while pc < hi:
                ln, text, kind, val = decode(rd, pc)
                self.ins[pc] = (ln, text, kind, val)
                if kind in ('jp', 'call', 'rel') and val >= 0x4000:
                    targets.add(val)
                pc += ln
        # locals
        self.local = {}
        gl = sorted(self.glob)
        for t in sorted(targets):
            if t in self.glob:
                continue
            scope = max(a for a in gl if a <= t)
            self.local[t] = (self.glob[scope], f'.l{t:04X}')
        unused = [a for a in self.comments if 0x4000 <= a < self.cfg['actclr'] and a not in self.ins]
        if unused:
            print('WARNING comment keys not on instructions:', [hex(a) for a in unused], file=sys.stderr)

    def gen_code(self, lo, hi):
        scope = None
        pc = lo
        while pc < hi:
            if pc in self.glob:
                scope = self.glob[pc]
                com = self.gcomment.get(pc)
                self.emit()
                if com:
                    self.emit(f'; {com}')
                self.emit(f'{scope}{"::" if pc in self.export else ":"}')
            elif pc in self.local:
                self.emit(self.local[pc][1] + ':')
            ln, text, kind, val = self.ins[pc]
            if kind:
                op = self.operand(kind, val, scope)
                for ph in ('{n8}', '{n16}', '{a16}', '{e8}', '{h8}', '{s8}'):
                    text = text.replace(ph, op)
            com = self.comments.get(pc, '')
            line = f'    {text}'
            self.emit(f'{line:<52}; {pc:04X}' + (f'  {com}' if com else ''))
            pc += ln

    # ---- driver tables ----
    def gen_tables(self):
        c = self.cfg
        g = self.g
        self.emit()
        self.emit('; Command handlers for $80-$93')
        self.emit('Snd_CmdTable:')
        cmds = ['$80 end', '$81 volume', '$82 loop', '$83 end loop', '$84 wave', '$85 jump', '$86 call',
                '$87 return', '$88 volume envelope', '$89 pitch envelope', '$8A pan left', '$8B pan right',
                '$8C pan centre', '$8D', '$8E', '$8F', '$90 duty 0', '$91 duty 1', '$92 duty 2', '$93 duty 3']
        for i in range(20):
            t = g.w4(c['jt'] + 2 * i)
            self.emit(f'    dw {self.glob[t]:<28}; {cmds[i]}')
        # pan table emitted inside code ranges ordering
        return

    def gen_pantab(self):
        self.emit()
        self.emit('; NR51 bits per struct (both sides)')
        self.emit('Snd_PanTable:')
        self.emit('    db ' + ', '.join(f'${self.g.b4(self.cfg["pantab"] + i):02X}' for i in range(8)))

    def gen_tables2(self):
        c = self.cfg
        g = self.g
        def db8(label, addr, com):
            self.emit()
            self.emit(f'; {com}')
            self.emit(f'{label}:')
            self.emit('    db ' + ', '.join(f'${g.b4(addr + i):02X}' for i in range(8)))
        db8('Snd_ActiveClearMask', c['actclr'], 'wSndActive mask that clears the bit of struct n')
        self.emit()
        self.emit('; Period per note. Notes below $18 (C_2) have period 0. MIDI note = note + 12.')
        self.emit('Snd_FreqTable:')
        for i in range(0, 120, 4):
            vals = [g.w4(c['freq'] + 2 * (i + j)) for j in range(4)]
            self.emit(f'    dw ' + ', '.join(f'${v:04X}' for v in vals) + f'{"":4}; {note_name(i)}-{note_name(i + 3)}')
        self.emit()
        self.emit('; Output level = Snd_VolumeTable[channel volume][envelope value]')
        self.emit('Snd_VolumeTable:')
        for r in range(16):
            self.emit('    db ' + ', '.join(f'${g.b4(c["voltab"] + 16 * r + j):02X}' for j in range(16)) + f' ; volume {r}')
        db8('Snd_NR52Mask', c['nr52mask'], 'NR52 status bit per struct')
        db8('Snd_NR51ClearMask', c['nr51clr'], 'NR51 AND mask per struct')
        db8('Snd_NRx2Table', c['nrx2'], 'low byte of NRx2 per struct')
        self.emit()
        self.emit('; NR32 value per level 0-15 (mute, 25%, 50%, 100%)')
        self.emit('Snd_WaveVolTable:')
        self.emit('    db ' + ', '.join(f'${g.b4(c["wavevol"] + i):02X}' for i in range(16)))

    # ---- sound data ----
    def gen_sound(self):
        c = self.cfg
        g = self.g
        tab, headers, ts, rows, refs = collect(g)
        lo = c['sndtab'] + 2 * len(tab)
        hi = max(max(a + rows[a][0] for a in rows), max(e for _, _, e in headers.values()))
        extra, dead = fill_gaps(g, tab, headers, ts, rows, refs, lo, hi)
        self.data_end = hi
        self.ntab = len(tab)
        # header labels
        hlab = {}
        ids_of = {}
        for i, p in enumerate(tab):
            ids_of.setdefault(p, []).append(i)
        for p, ids in ids_of.items():
            hlab[p] = f'SndHdr_{ids[0]:02X}'
        for p in extra:
            hlab[p] = f'SndHdr_Unref_{p:04X}'
        # track labels
        tlab = {}
        tcom = {}
        bits = {}
        for p in sorted(list(headers) + list(extra)):
            m, tracks, e = headers.get(p) or extra[p]
            for bit, t in tracks:
                name = hlab[p].replace('SndHdr_', 'Snd') + f'_{TRACKNAME[bit]}'
                bits.setdefault(t, set()).add(bit)
                if t not in tlab:
                    tlab[t] = name
                else:
                    tcom.setdefault(t, []).append(name)
        for d in dead:
            tlab[d] = f'Unreached_{d:04X}'
        # jump targets that are not track starts
        targets = set()
        for a, (l, k, args) in rows.items():
            if k == 'cmd' and args[0] in (0x85, 0x86):
                targets.add(args[1])
        starts = sorted(tlab)
        loc = {}
        for t in targets:
            if t in tlab:
                continue
            sc = max(s for s in starts if s <= t)
            loc[t] = (tlab[sc], f'.l{t:04X}')
        # which struct bits reach each row (for noise vs note naming): propagate from track starts
        rowbits = {}
        order = sorted(rows)
        for t, bs in bits.items():
            stack = [t]
            seen = set()
            while stack:
                pc = stack.pop()
                while pc in rows and (pc, ) not in seen:
                    seen.add((pc,))
                    rowbits.setdefault(pc, set()).update(bs)
                    l, k, args = rows[pc]
                    if k == 'cmd':
                        if args[0] in (0x85, 0x86):
                            stack.append(args[1])
                        if args[0] in (0x80, 0x85, 0x87):
                            break
                    pc += l

        # sound table
        self.emit()
        self.emit('; Sound ids. Header: struct mask (bits 0-3 music ch1-4, 4-7 SFX ch1-4), then one track per set bit.')
        self.emit('Snd_SoundTable:')
        for i, p in enumerate(tab):
            self.emit(f'    dw {hlab[p]:<28}; ${i:02X}')

        allh = dict(headers)
        allh.update(extra)
        pc = lo
        scope = None
        while pc < hi:
            if pc in allh:
                m, tracks, e = allh[pc]
                self.emit()
                ids = ids_of.get(pc)
                if ids:
                    kind = 'music' if m & 0x0F else 'SFX'
                    self.emit(f'; sound {", ".join(f"${i:02X}" for i in ids)} ({kind})')
                else:
                    self.emit('; not in Snd_SoundTable')
                self.emit(f'{hlab[pc]}:')
                self.emit(f'    db %{m:08b}')
                for bit, t in tracks:
                    self.emit(f'    dw {tlab[t]:<28}; {TRACKNAME[bit]}')
                pc = e
                continue
            if pc in tlab:
                scope = tlab[pc]
                self.emit()
                if pc in dead:
                    self.emit('; not reachable from any pointer')
                for n in tcom.get(pc, []):
                    self.emit(f'; also {n}')
                self.emit(f'{scope}:')
            elif pc in loc:
                self.emit(loc[pc][1] + ':')
            l, k, args = rows[pc]
            rb = rowbits.get(pc, set())
            noise = 3 in rb
            extra_c = ''
            if 7 in rb and k == 'note' and args[0] < 0x7E:
                extra_c = f'  NR43 = ${g.w4(c["freq"] + 2 * args[0]) & 0xFF:02X}'
            self.emit(f'    {self.row_text(k, args, noise, scope, tlab, loc):<44}; {pc:04X}{extra_c}')
            pc += l
        assert pc == hi

    def row_text(self, k, args, noise, scope, tlab, loc):
        if k == 'note':
            n, L = args
            if n == 0x7E: return f'tie {L}'
            if n == 0x7F: return f'rest {L}'
            if noise: return f'noise ${n:02X}, {L}'
            return f'note {note_name(n)}, {L}'
        if k == 'raw':
            return f'rawnote ${args[0]:02X}, {args[1]}'
        cmd = args[0]
        if cmd in (0x85, 0x86):
            t = args[1]
            if t in tlab: lab = tlab[t]
            else:
                sc, l = loc[t]
                lab = l if sc == scope else sc + l
            return f'{CMD[cmd]} {lab}'
        if 0x90 <= cmd <= 0x93:
            return f'snd_duty {cmd - 0x90}'
        if 0x8D <= cmd <= 0x8F:
            return f'snd_nop ${cmd:02X}'
        if len(args) > 1:
            return f'{CMD[cmd]} {args[1]}'
        return CMD[cmd]

    # ---- bank 0 instrument block ----
    def gen_bank0(self):
        c = self.cfg
        g = self.g
        sec = [('PitchEnvTable', c['pitchtab'], 'PitchEnv'), ('VolEnvTable', c['envtab'], 'VolEnv'),
               ('WaveTable', c['wavetab'], 'Wave')]
        ptrs = {}
        lab = {}
        tabranges = []
        for tname, t, pfx in sec:
            n = 0
            lst = []
            while True:
                x = g.w0(t + 2 * n)
                if lst and t + 2 * n >= min(lst):
                    break
                lst.append(x); n += 1
            ptrs[tname] = lst
            tabranges.append((t, t + 2 * n, tname, pfx))
            for i, x in enumerate(lst):
                lab.setdefault(x, f'{pfx}{i:02X}')
        self.emit()
        self.emit(f'SECTION "Wizard sound instruments", ROM0[${c["pitchtab"]:04X}]')
        starts = sorted(lab)
        tabstart = {t: (e, tn, p) for t, e, tn, p in tabranges}
        pc = c['pitchtab']
        end = c['b0end']
        while pc < end:
            if pc in tabstart:
                e, tn, pfx = tabstart[pc]
                self.emit()
                desc = {'PitchEnvTable': 'Pitch envelopes ($89 n): signed period step added every frame; $80 = repeat the previous step, $81 = restart',
                        'VolEnvTable': 'Volume envelopes ($88 n): column of Snd_VolumeTable per frame; $80 = hold the previous value, $81 = restart',
                        'WaveTable': 'Waves ($84 n): 16 bytes for wave RAM'}[tn]
                self.emit(f'; {desc}')
                self.emit(f'{tn}:')
                for i, x in enumerate(ptrs[tn]):
                    self.emit(f'    dw {lab[x]:<20}; ${i:02X}')
                pc = e
                continue
            nxt = min([s for s in starts if s > pc] + [t for t in tabstart if t > pc] + [end])
            name = lab[pc]
            alias = [f'{p}{i:02X}' for tn, (t, e2, tn2, p) in [(x[2], x) for x in tabranges] for i, v in enumerate(ptrs[tn]) if v == pc and f'{p}{i:02X}' != name]
            self.emit()
            if alias:
                self.emit(f'; also {", ".join(alias)}')
            self.emit(f'{name}:')
            data = [g.b0(x) for x in range(pc, nxt)]
            if name.startswith('Wave'):
                self.emit('    db ' + ', '.join(f'${b:02X}' for b in data))
            else:
                signed = name.startswith('Pitch')
                vals = []
                for b in data:
                    if b == 0x80: vals.append('ENV_HOLD')
                    elif b == 0x81: vals.append('ENV_LOOP')
                    elif signed: vals.append(str(b - 256 if b >= 0x80 else b))
                    else: vals.append(str(b))
                for i in range(0, len(vals), 16):
                    self.emit('    db ' + ', '.join(vals[i:i + 16]))
            pc = nxt

    def run(self):
        c = self.cfg
        self.build_code_labels()
        self.emit(f'; Wizard sound driver - {c["title"]}')
        self.emit(f'; bank {c["bank"]} $4000-${self.dummy_end():04X} and bank 0 ${c["pitchtab"]:04X}-${c["b0end"] - 1:04X}')
        self.emit('; Generated by tools/wiz_gen.py. Assembles byte-identical with RGBDS 1.0.0.')
        self.emit()
        self.emit('INCLUDE "wizard_sound.inc"')
        self.emit()
        self.emit('; ---- WRAM ----')
        for off, name, size, com in WRAM:
            self.emit(f'DEF {name:<16} EQU ${c["wram"] + off:04X}   ; {size:>3} byte{"s" if size > 1 else ""}: {com}')
        self.emit()
        self.emit(f'SECTION "Wizard sound driver", ROMX[$4000], BANK[{c["bank"]}]')
        r = self.code_ranges()
        self.gen_code(*r[0])
        self.gen_tables()
        self.gen_code(*r[1])
        self.gen_pantab()
        self.gen_code(*r[2])
        self.gen_tables2()
        self.gen_sound()
        self.gen_bank0()
        return '\n'.join(self.out) + '\n'

    def dummy_end(self):
        return {'dx10': 0x7D31, 'quiz': 0x7C19}[self.key]


if __name__ == '__main__':
    key = sys.argv[1]
    import os
    os.chdir(os.path.dirname(os.path.abspath(__file__)) + '/..')
    sys.stdout.write(Gen(key).run())
