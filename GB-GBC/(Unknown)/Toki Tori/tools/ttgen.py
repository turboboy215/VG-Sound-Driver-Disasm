"""Generate labelled RGBDS sources for the Toki Tori (GBC) sound driver.

usage: python ttgen.py <rom> <outdir>
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gbdis
from gbdis import decode, flow
import ttnames as N

ROM = None

def off_of(bank, pc):
    return pc if pc < 0x4000 else bank * 0x4000 + pc - 0x4000
def rb(bank, a): return ROM[off_of(bank, a)]
def rw(bank, a): return rb(bank, a) | rb(bank, a + 1) << 8
def rbytes(bank, a, n): o = off_of(bank, a); return ROM[o:o + n]

# ======================================================================== tracing
def trace(bank, entries, lo, hi):
    code = {}
    todo = list(entries)
    while todo:
        pc = todo.pop()
        while lo <= pc < hi and pc not in code:
            ln, m, v, k = decode(ROM, off_of(bank, pc), pc)
            assert m is not None, f'bad opcode {bank:02X}:{pc:04X}'
            code[pc] = (ln, m, v, k)
            f = flow(m)
            if k in ('a16', 'rel') and f in ('jump', 'cond', 'call') and lo <= v < hi:
                todo.append(v)
            if f in ('end', 'jump'):
                break
            pc += ln
    return code

def table(bank, a, n): return [rw(bank, a + 2 * i) for i in range(n)]

# ======================================================================== labels
class Labels:
    def __init__(self):
        self.glob = {}     # addr -> global name
        self.loc = {}      # addr -> local name ('.x')
    def add(self, a, n, force=False):
        if n.startswith('.'):
            self.loc.setdefault(a, n)
        elif force or a not in self.glob:
            self.glob[a] = n
    def scope_of(self, a):
        best = None
        for g in self.glob:
            if g <= a and (best is None or g > best):
                best = g
        return best
    def ref(self, a, from_pc):
        if a in self.glob:
            return self.glob[a]
        if a in self.loc:
            s_t = self.scope_of(a); s_f = self.scope_of(from_pc)
            if s_t == s_f:
                return self.loc[a]
            return self.glob[s_t] + self.loc[a]
        return None

RAMSYM = N.ram_symbols()

PAGE_SYMS = {  # (mnemonic prefix, value) -> expr
    ('ld h,', 0x40): 'HIGH(Ch1_RowFxTable)', ('ld h,', 0x41): 'HIGH(Ch1_TickFxTable)',
    ('ld h,', 0x42): 'HIGH(Ch2_RowFxTable)', ('ld h,', 0x43): 'HIGH(Ch2_TickFxTable)',
    ('ld h,', 0x44): 'HIGH(Ch3_RowFxTable)', ('ld h,', 0x45): 'HIGH(Ch3_TickFxTable)',
    ('ld h,', 0x46): 'HIGH(Ch4_RowFxTable)', ('ld h,', 0x47): 'HIGH(Ch4_TickFxTable)',
    ('ld h,', 0x58): 'HIGH(WaveTable)', ('ld d,', 0x59): 'HIGH(Ch3VolTable)',
    ('ld d,', 0x60): 'HIGH(SongTable)', ('ld b,', 0x3F): 'HIGH(RowLenTable_80)',
    ('add a,', 0x48): 'HIGH(FreqTables)', ('adc a,', 0x5C): 'HIGH(VibratoTables)',
    ('adc a,', 0x5A): 'HIGH(TremoloTables)',
}
FXA_ADDRS = {N.CH_BASE[c] + 6 for c in range(4)}
FXB_ADDRS = {N.CH_BASE[c] + 7 for c in range(4)}

def operand(pc, m, v, k, nxt, L, bank):
    if k is None:
        return m
    if k == 'n8':
        pre = m.split('{')[0].strip()
        if (pre, v) in PAGE_SYMS and not (pre == 'ld b,' and bank != 0):
            return m.replace('{n8}', PAGE_SYMS[(pre, v)])
        if m == 'ld a, {n8}' and nxt and nxt[1] == 'ld [{a16}], a' and (nxt[2] in FXA_ADDRS or nxt[2] in FXB_ADDRS):
            if v % 2 == 0 and v // 2 < len(N.TICK_FX):
                return m.replace('{n8}', 'TFX_' + N.TICK_FX[v // 2])
        return gbdis.fmt(m, v, k)
    if k == 's8':
        return gbdis.fmt(m, v, k)
    if k == 'ldh':
        return m.replace('{ldh}', N.HW.get(v, f'${v:04X}'))
    key = {'rel': '{rel}', 'n16': '{n16}', 'a16': '{a16}'}[k]
    s = None
    if k in ('rel', 'a16') and not m.startswith('ld'):
        s = L.ref(v, pc)
        assert s is not None, f'no label for {v:04X} at {pc:04X}'
    else:
        if v in RAMSYM: s = RAMSYM[v]
        elif v in N.HW: s = N.HW[v]
        elif v in L.glob and v >= 0x4000: s = L.glob[v]
    if s is None:
        s = f'${v:04X}'
    return m.replace(key, s)

def emit_code(out, bank, start, end, code, L, comments={}):
    pc = start
    pcs = sorted(p for p in code if start <= p < end)
    i = 0
    while pc < end:
        if pc in L.glob:
            out.append('')
            if pc in comments:
                for c in comments[pc]:
                    out.append(f'; {c}')
            out.append(f'{L.glob[pc]}::')
        elif pc in L.loc:
            out.append(f'{L.loc[pc]}')
        assert pc in code, f'not code {bank:02X}:{pc:04X}'
        ln, m, v, k = code[pc]
        nxt = code.get(pc + ln)
        txt = operand(pc, m, v, k, nxt, L, bank)
        raw = ' '.join(f'{x:02X}' for x in rbytes(bank, pc, ln))
        out.append(f'\t{txt:<34}; {pc:04X}: {raw}')
        pc += ln

def ds_ff(out, n, addr):
    if n:
        out.append(f'\tds {n}, $FF{"":<23}; {addr:04X}-{addr+n-1:04X} unused')

# ======================================================================== bank $2D
def build_driver_labels():
    B = N.SND_BANK
    L = Labels()
    for a, n in N.code_labels().items():
        L.add(a, n, force=True)
    tables = [(0x4000, 0x4100, 1), (0x4200, 0x4300, 2), (0x4400, 0x4500, 3), (0x4600, 0x4700, 4)]
    nop_handlers = {}
    for rt, tt, ch in tables:
        rows = table(B, rt, 32)
        ticks = table(B, tt, 12)
        # row handlers: a handler shared by >2 indices is the no-op
        from collections import Counter
        cnt = Counter(rows)
        for i, a in enumerate(rows):
            if a in L.glob and not L.glob[a].startswith(f'Ch{ch}_') and not L.glob[a].startswith('TickFx'):
                continue
            nm = f'Ch{ch}Fx_None' if cnt[a] > 2 else f'Ch{ch}Fx_{N.camel(N.ROW_FX[i])}'
            if a not in L.glob:
                L.add(a, nm)
        for i, a in enumerate(ticks):
            if a not in L.glob:
                L.add(a, f'Ch{ch}Tick_{N.camel(N.TICK_FX[i])}')
    for ch in range(3):
        base = 0x64B1 + 0x3A8 * ch
        for off, n in N.DECODER_LOCALS.items():
            L.add(base + off, n)
    for a, n in N.CH4_LOCALS.items():
        L.add(a, n)
    return L

DRIVER_COMMENTS = {
    0x6248: ['Driver_Init: reached through Sound_SelectBank (jp). Silences all channels and',
             'resets the four channel structures.'],
    0x62CB: ['Music_Update: on a row frame (wRowFrame != 0) decode the four buffered rows;',
             'otherwise run each channel\'s tick effects A (pitch) then B (volume).'],
    0x632B: ['Sfx_Claim: a new SFX step for channel wSfxNewChannel gives that channel to the SFX',
             '(SFXFLAG = 1); the channel it had before goes back to the music.'],
    0x636E: ['Sfx_ChanFlagPtr: a = channel 0-3 -> hl = its SFXFLAG'],
    0x6381: ['ChN_Output: SFXFLAG 1 -> write wSfxRegs once and set SFXFLAG $FF; $FF -> skip;',
             '0 -> music. RETRIG counts down every frame; at 0 the channel is retriggered with',
             'volume/instrument/period and RETRIG reloads to 110 frames. Other frames only',
             'write the period (NRx3/NRx4 without the trigger bit).'],
    0x640C: ['Ch3_Output has no SFX check: ch3 cannot be taken by an SFX.'],
    0x64B1: ['ChN_ReadRow: decode the row in ROWBUF (see the documentation for the format).',
             'Clears both tick effects first, so every effect lasts one row unless repeated.'],
    0x6704: ['ChN_SetFreq: a = note -> FREQ = FreqTables[FINETUNE][note].',
             'ChN_SetFreqFT: a = finetune, b = note.'],
    0x66AD: ['Not in the effect table: a vibrato setup that also resets VIBPHASE.'],
    0x6A55: ['Not in the effect table (see Ch1Fx_VibratoReset_Unused).'],
    0x6DFD: ['Not in the effect table (see Ch1Fx_VibratoReset_Unused).'],
    0x4118: ['Ch4_ReadRow: like ChN_ReadRow, but the note byte is skipped: INSTR is the',
             'NR43 value, so the noise pitch comes from the instrument column.'],
}

def gen_driver(outdir):
    B = N.SND_BANK
    L = build_driver_labels()
    entries = list(L.glob.keys()) + [a for a in L.loc]
    entries = [a for a in entries if (0x4040 <= a < 0x4100 or 0x4118 <= a < 0x4200 or 0x6248 <= a < 0x7000)]
    code = trace(B, entries, 0x4000, 0x8000)
    # register targets without names as locals
    for pc, (ln, m, v, k) in code.items():
        if k in ('rel', 'a16') and flow(m) in ('jump', 'cond', 'call') and v not in L.glob and v not in L.loc:
            L.add(v, f'.l{v:04X}')
    out = ['; Toki Tori (GBC) sound driver, bank $2D', '; generated by ttgen.py', '',
           'INCLUDE "GB_Hardware.inc"', 'INCLUDE "TT_RAM.inc"', 'INCLUDE "TT_Macros.inc"', '',
           'SECTION "Sound Driver", ROMX[$4000], BANK[$2D]']
    def jt(addr, n, title):
        out.append('')
        out.append(f'; {title}')
        out.append(f'{L.glob[addr]}::')
        for i, a in enumerate(table(B, addr, n)):
            idx = N.ROW_FX[i] if n == 32 else N.TICK_FX[i]
            val = f'${i:02X}' if n == 32 else f'TFX_{N.TICK_FX[i]}'
            out.append(f'\tdw {L.glob[a]:<30} ; {val} {idx}')
    def code_rng(s, e):
        emit_code(out, B, s, e, code, L, DRIVER_COMMENTS)
    jt(0x4000, 32, 'row effects, indexed by the effect byte ($00-$1F)')
    code_rng(0x4040, 0x40FE); ds_ff(out, 2, 0x40FE)
    jt(0x4100, 12, 'tick effects, indexed by FXA/FXB (byte offset)')
    code_rng(0x4118, 0x41FB); ds_ff(out, 5, 0x41FB)
    jt(0x4200, 32, 'ch2 row effects')
    gen_sfx_data(out, L)
    ds_ff(out, 0x4300 - 0x42CA, 0x42CA)
    jt(0x4300, 12, 'ch2 tick effects'); ds_ff(out, 0x4400 - 0x4318, 0x4318)
    jt(0x4400, 32, 'ch3 row effects'); ds_ff(out, 0x4500 - 0x4440, 0x4440)
    jt(0x4500, 12, 'ch3 tick effects'); ds_ff(out, 0x4600 - 0x4518, 0x4518)
    jt(0x4600, 32, 'ch4 row effects'); ds_ff(out, 0x4700 - 0x4640, 0x4640)
    jt(0x4700, 12, 'ch4 tick effects'); ds_ff(out, 0x4800 - 0x4718, 0x4718)
    # frequency tables
    out += ['', '; 16 period tables, one per FINETUNE (0-15, 8 = in tune), 72 notes C2-B7 each.',
            '; Table f is tuned (f-8)/16 semitone from equal temperament (A4 = 440 Hz).',
            'FreqTables::']
    for f in range(16):
        p = 0x4800 + f * 0x100
        out.append(f'.ft{f}\t; ${p:04X}')
        for o in range(6):
            vals = ', '.join(f'${rw(B, p + 2 * (12 * o + i)):04X}' for i in range(12))
            out.append(f'\tdw {vals} ; C{o+2}-B{o+2}')
        ds_ff(out, 112, p + 144)
    out += ['', '; ch3 waves: INSTR n uses bytes n*16..n*16+15 (INSTR is swapped, so only $00-$0F', '; are aligned)', 'WaveTable::']
    for i in range(16):
        out.append(f'\tdb {", ".join(f"${x:02X}" for x in rbytes(B, 0x5800 + 16 * i, 16))} ; wave {i}')
    out += ['', '; ch3 NR32 value for each VOLUME (0 mute, 1-16 25 %, 17-32 50 %, 33+ 100 %)', 'Ch3VolTable::']
    for i in range(16):
        out.append(f'\tdb {", ".join(f"${x:02X}" for x in rbytes(B, 0x5900 + 16 * i, 16))} ; ${16*i:02X}')
    out += ['', '; tremolo: 16 depths x 32 phases; volume = TREMBASE + 4 * (value - 8)', 'TremoloTables::']
    for i in range(16):
        out.append(f'\tdb {", ".join(f"${x:02X}" for x in rbytes(B, 0x5A00 + 32 * i, 32))} ; depth {i}')
    out += ['', '; vibrato: 16 depths x 64 phases, in 1/16 semitone, $10 = centre', 'VibratoTables::']
    for i in range(16):
        bs = rbytes(B, 0x5C00 + 64 * i, 64)
        out.append(f'\t; depth {i}')
        for h in range(2):
            out.append(f'\tdb {", ".join(f"${x:02X}" for x in bs[32*h:32*h+32])}')
    gen_song_table(out)
    ds_ff(out, 0x6200 - (0x6000 + 8 * NSONGS), 0x6000 + 8 * NSONGS)
    out += ['', '; SFX table: bank (relative to wSndBank), pointer, unused byte', 'SfxTable::']
    for i in range(NSFX):
        e = rbytes(B, 0x6200 + 4 * i, 4)
        assert e[0] == 0 and e[3] == 0
        out.append(f'\tSFX_ENTRY Sfx{i:02d} ; {i}')
    code_rng(0x6248, 0x6FA9)
    ds_ff(out, 0x8000 - 0x6FA9, 0x6FA9)
    write(outdir, 'TT_Driver.asm', out)
    return code, L

NSONGS = 11
NSFX = 18

def gen_sfx_data(out, L):
    B = N.SND_BANK
    out += ['', '; sound effects (all in this bank). SFX_STEP frames, channel, register values', '']
    for i in range(NSFX):
        e = rbytes(B, 0x6200 + 4 * i, 4)
        a = e[1] | e[2] << 8
        out.append(f'Sfx{i:02d}:: ; ${a:04X}')
        while True:
            n = rb(B, a)
            if n == 0:
                out.append('\tSFX_END'); a += 1; break
            c = rb(B, a + 1); k = c >> 4; ch = c & 15
            regs = ', '.join(f'${x:02X}' for x in rbytes(B, a + 2, k))
            out.append(f'\tSFX_STEP {n}, {ch}, {regs}')
            a += 2 + k

# ======================================================================== music data
POP = [bin(i & 0x1F).count('1') for i in range(256)]
def row_len(bk, a):
    c = rb(bk, a)
    return 1 + min(POP[c], 4) if c & 0x80 else 5

def songs():
    B = N.SND_BANK
    res = []
    for i in range(NSONGS):
        e = rbytes(B, 0x6000 + 8 * i, 8)
        res.append(dict(i=i, bank=B + e[0], ptr=e[1] | e[2] << 8, speed=e[3], loop=e[4] | e[5] << 8, pad=e[6:8]))
    return res

def orders(s):
    res = []; a = s['ptr']; bk = s['bank']
    while rb(bk, a) != 0xFF:
        e = rbytes(bk, a, 16)
        ch = [(N.SND_BANK + e[3 * k], e[3 * k + 1] | e[3 * k + 2] << 8) for k in range(4)]
        res.append(dict(addr=a, chans=ch, rows=e[12], pad=e[13:16]))
        a += 16
    return res, a

def pat_label(bk, a): return f'Pat_{bk:02X}_{a:04X}'

def gen_song_table(out):
    out += ['', '; song table: SONG order list, speed (frames per row), loop entry', 'SongTable::']
    for s in songs():
        assert s['pad'] == b'\0\0'
        loop = f'Song{s["i"]:02d}_Orders' if s['loop'] == s['ptr'] else f'${s["loop"]:04X}'
        out.append(f'\tSONG Song{s["i"]:02d}_Orders, {s["speed"]}, {loop} ; {s["i"]}')

def row_text(bk, a, n, ch_kinds):
    r = rbytes(bk, a, n)
    c = r[0]
    noten = (lambda x: N.note_name(x))
    def fxn(x): return f'FX_{N.ROW_FX[x]}' if x < 32 else f'${x:02X}'
    def ins(x): return f'${x:02X}'
    if not c & 0x80:
        return f'ROW {noten(c)}, {ins(r[1])}, {r[2]}, {fxn(r[3])}, ${r[4]:02X}'
    if c == 0x80:
        return '___'
    flags = ''.join(f for b, f in zip(range(5), 'NIVXP') if c >> b & 1)
    args = []; i = 1
    if c & 1: args.append(noten(r[i])); i += 1
    if c & 2: args.append(ins(r[i])); i += 1
    if c & 4: args.append(str(r[i])); i += 1
    if c & 8: args.append(fxn(r[i])); i += 1
    if c & 16 and i < n: args.append(f'${r[i]:02X}'); i += 1
    if POP[c] > 4:
        return f'R_{flags}_TRUNC ' + ', '.join(args)
    return f'R_{flags} ' + ', '.join(args)

def gen_music(outdir):
    uses = {}   # (bk,a) -> list of strings ; and rows
    prows = {}
    for s in songs():
        o, end = orders(s)
        for j, e in enumerate(o):
            for ch, (bk, p) in enumerate(e['chans']):
                uses.setdefault((bk, p), []).append((s['i'], j, ch + 1))
                prows[(bk, p)] = max(prows.get((bk, p), 0), e['rows'])
    banks = {}
    for (bk, p), nrows in prows.items():
        a = p
        for _ in range(nrows):
            a += row_len(bk, a)
        banks.setdefault(bk, []).append(('pat', p, a, nrows))
    order_banks = {}
    for s in songs():
        o, end = orders(s)
        banks.setdefault(s['bank'], []).append(('ord', s['ptr'], end + 16, s))
    files = []
    for bk in sorted(banks):
        items = sorted(banks[bk], key=lambda x: x[1])
        out = [f'; Toki Tori music data, bank ${bk:02X}', '; generated by ttgen.py', '',
               'INCLUDE "TT_Macros.inc"', '', f'SECTION "Music ${bk:02X}", ROMX[$4000], BANK[${bk:02X}]']
        a = 0x4000
        # end of real data
        tail = 0x8000
        while rb(bk, tail - 1) == 0xFF: tail -= 1
        def gap(a, e):
            # unreferenced bytes: try to parse as rows
            out.append('')
            x = a; n = 0
            while x < e:
                x += row_len(bk, x); n += 1
            if x == e:
                out.append(f'; ${a:04X}-${e-1:04X}: {n} rows of pattern data not referenced by any order entry')
                out.append(f'Unused_{bk:02X}_{a:04X}::')
                x = a; r = 0
                while x < e:
                    ln = row_len(bk, x)
                    cm = f' ; row {r}' if r % 16 == 0 else ''
                    out.append(f'\t{row_text(bk, x, ln, None)}{cm}')
                    x += ln; r += 1
            else:
                out.append(f'Unused_{bk:02X}_{a:04X}::')
                for y in range(a, e, 16):
                    out.append(f'\tdb {", ".join(f"${v:02X}" for v in rbytes(bk, y, min(16, e - y)))}')
        for it in items:
            kind, s, e = it[0], it[1], it[2]
            if s < a:
                raise ValueError(f'overlap {bk:02X}:{s:04X}')
            if s > a:
                gap(a, s)
            if kind == 'pat':
                us = uses[(bk, s)]
                chs = sorted(set(u[2] for u in us))
                sg = sorted(set(u[0] for u in us))
                out.append('')
                out.append(f'; {it[3]} rows; ch{"/".join(map(str, chs))}; song{"s" if len(sg)>1 else ""} {", ".join(map(str, sg))}')
                out.append(f'{pat_label(bk, s)}::')
                x = s
                for r in range(it[3]):
                    ln = row_len(bk, x)
                    cm = f' ; row {r}' if r % 16 == 0 else ''
                    out.append(f'\t{row_text(bk, x, ln, chs)}{cm}')
                    x += ln
                assert x == e
            else:
                sd = it[3]
                o, end = orders(sd)
                out.append('')
                out.append(f'; song {sd["i"]}: {len(o)} order entries, speed {sd["speed"]}')
                out.append(f'Song{sd["i"]:02d}_Orders::')
                for j, en in enumerate(o):
                    assert en['pad'] == b'\0\0\0'
                    ps = ', '.join(pat_label(b2, p2) for b2, p2 in en['chans'])
                    out.append(f'\tORDER {ps}, {en["rows"]} ; {j}')
                assert rbytes(bk, end, 16) == b'\xff' + b'\0' * 15
                out.append('\tORDER_END')
            a = e
        if a < tail:
            gap(a, tail)
            a = tail
        ds_ff(out, 0x8000 - a, a)
        fn = f'TT_Music_{bk:02X}.asm'
        write(outdir, fn, out)
        files.append(fn)
    return files

# ======================================================================== home bank
HOME_COMMENTS = {
    0x3D00: ['Sound_SelectBank: a = driver bank ($2D). Maps it and falls into Driver_Init.'],
    0x3D0A: ['Sound_APUOn: NR52 on, NR50 $77, NR51 $FF.'],
    0x3D1C: ['Sound_Stop: Driver_Init, APU off, sequencer off.'],
    0x3D2C: ['Sound_Update: once per frame (WRAM bank 7 selected). Sequencer and SFX streams',
             'here; the driver bank does the rest.'],
    0x3D4B: ['Sound_PlaySfx: a = SFX number. Starts it on the next Sfx_Update.'],
    0x3D6C: ['Sfx_Update: SFX steps are (frames, channel | count << 4, count register bytes);',
             'frames = 0 ends the effect.'],
    0x3D9E: ['Sound_PlaySong: a = song number. Copies the 8-byte song table entry, then',
             'arms the sequencer so the first order entry loads on the next frame.'],
    0x3DD8: ['Seq_NextOrder: hl = wRowsLeft. Order entry = 4 x (bank, pointer), row count,',
             '3 unused bytes; $FF = go to wLoopPtr.'],
    0x3E2D: ['Seq_Tick: counts the frames of a row. One frame before a row starts, it fetches',
             'that row for all four channels (Seq_FetchRow); on the row frame itself it sets',
             'wRowFrame and steps wRowsLeft / the order list.'],
    0x3E6F: ['Seq_FetchRow: hl = channel pattern pointer, de = channel ROWBUF. A row is one',
             'byte < $80 + 4 bytes, or a mask $80-$9F + one byte per set bit (at most 4 copied).'],
}

def gen_home(outdir):
    L = Labels()
    for a, n in N.code_labels().items():
        if a < 0x4000:
            L.add(a, n, force=True)
    L.add(0x3E7D, '.mask'); L.add(0x3E9D, '.done'); L.add(0x3EA3, '.full')
    code = trace(0, [a for a in L.glob if a < 0x3F00] + [0x3E7D, 0x3EA3], 0x3D00, 0x3F00)
    for pc, (ln, m, v, k) in code.items():
        if k in ('rel', 'a16') and flow(m) in ('jump', 'cond', 'call') and v not in L.glob and v not in L.loc and v < 0x4000:
            L.add(v, f'.l{v:04X}')
    # calls into the driver bank
    ext = {0x6248: 'Driver_Init', 0x62CB: 'Music_Update', 0x632B: 'Sfx_Claim', 0x6381: 'Ch1_Output',
           0x63CB: 'Ch2_Output', 0x640C: 'Ch3_Output', 0x6474: 'Ch4_Output', 0x6200: 'SfxTable'}
    for a, n in ext.items():
        L.glob[a] = n
    out = ['; Toki Tori (GBC) sound driver: home-bank part ($3D00-$3FFF)', '; generated by ttgen.py', '',
           'INCLUDE "GB_Hardware.inc"', 'INCLUDE "TT_RAM.inc"', '',
           'SECTION "Sound Home", ROM0[$3D00]']
    emit_code(out, 0, 0x3D00, 0x3EB5, code, L, HOME_COMMENTS)
    ds_ff(out, 0x3F80 - 0x3EB5, 0x3EB5)
    out += ['', '; number of bytes after a mask byte $80-$9F (popcount of bits 0-4)', 'RowLenTable_80::']
    for h in range(2):
        out.append(f'\tdb {", ".join(f"${x:02X}" for x in ROM[0x3F80 + 16*h:0x3F90 + 16*h])}')
    ds_ff(out, 0x4000 - 0x3FA0, 0x3FA0)
    write(outdir, 'TT_Home.asm', out)
    return code

# ======================================================================== includes
def gen_includes(outdir):
    hw = ['; Game Boy hardware registers used by the sources', '']
    for a, n in sorted(N.HW.items()):
        hw.append(f'DEF {n:<14} EQU ${a:04X}')
    write(outdir, 'GB_Hardware.inc', hw)
    r = ['; Toki Tori sound RAM: WRAM bank 7, $DF00-$DFA9', '']
    for a, n, ln, c in N.RAM:
        r.append(f'DEF {n:<16} EQU ${a:04X} ; {ln} {c}'.rstrip())
    r += ['', '; channel structures ($21 bytes each)', f'DEF CH_SIZE EQU ${N.CH_SIZE:02X}']
    for i, b in enumerate(N.CH_BASE):
        r.append(f'DEF wCh{i+1} EQU ${b:04X}')
    r += ['', '; ch1-ch3 fields']
    for off, n, ln, c in N.CH_FIELDS:
        r.append(f'DEF CH_{n:<12} EQU ${off:02X} ; {ln} {c}'.rstrip())
    r += ['', '; ch4 fields (same structure size, different layout)']
    for off, n, ln, c in N.CH4_FIELDS:
        r.append(f'DEF CH4_{n:<11} EQU ${off:02X} ; {ln} {c}'.rstrip())
    r.append('')
    for ch in range(4):
        flds = N.CH4_FIELDS if ch == 3 else N.CH_FIELDS
        pre = 'CH4_' if ch == 3 else 'CH_'
        for off, n, ln, c in flds:
            r.append(f'DEF wCh{ch+1}_{n:<12} EQU wCh{ch+1} + {pre}{n}')
        r.append('')
    write(outdir, 'TT_RAM.inc', r)
    m = ['; Toki Tori sound data macros', '', 'IF !DEF(TT_MACROS_INC)', 'DEF TT_MACROS_INC EQU 1', '',
         'DEF SND_BANK EQU $2D ; data banks are stored relative to this', '',
         '; ---- notes (index into a 72-entry period table, C2 = 0)']
    for n in range(72):
        m.append(f'DEF {N.note_name(n)} EQU {n}')
    m += ['', '; ---- row effects (effect byte)']
    for i, n in enumerate(N.ROW_FX):
        m.append(f'DEF FX_{n:<16} EQU ${i:02X}')
    m += ['', '; ---- tick effects (offsets into ChN_TickFxTable)']
    for i, n in enumerate(N.TICK_FX):
        m.append(f'DEF TFX_{n:<12} EQU ${2*i:02X}')
    m += ['', '; ---- pattern rows',
          '; ROW note, instrument, volume, effect, param: a full row (5 bytes, note < $80)',
          'MACRO ROW', '\tASSERT (\\1) < $80', '\tdb \\1, \\2, \\3, \\4, \\5', 'ENDM', '',
          '; masked rows: one byte $80 | bits, then one byte per bit:',
          ';   N note (bit 0), I instrument (1), V volume (2), X effect (3), P param (4)',
          '; X without P: param 0.  P without X: effect 0 (FX_ARPEGGIO) with that param.',
          '; A note without V sets the volume to $3F. ___ is an empty row ($80).',
          'MACRO ___', '\tdb $80', 'ENDM']
    for mask in range(1, 32):
        flags = ''.join(f for b, f in zip(range(5), 'NIVXP') if mask >> b & 1)
        cnt = POP[mask]
        if cnt <= 4:
            m += [f'MACRO R_{flags}', f'\tASSERT _NARG == {cnt}', f'\tdb ${0x80|mask:02X}, \\#', 'ENDM']
        else:
            m += [f'; ${0x80|mask:02X}: 5 bytes would follow, but Seq_FetchRow copies only 4',
                  f'MACRO R_{flags}_TRUNC', f'\tdb ${0x80|mask:02X}, \\#', 'ENDM']
    m += ['', '; ---- order list',
          '; ORDER ch1, ch2, ch3, ch4, rows: four pattern streams played together for "rows" rows',
          'MACRO ORDER',
          '\tREPT 4', '\t\tdb BANK(\\1) - SND_BANK, LOW(\\1), HIGH(\\1)', '\t\tSHIFT', '\tENDR',
          '\tdb \\1, 0, 0, 0', 'ENDM',
          'MACRO ORDER_END', '\tdb $FF', '\tds 15, 0', 'ENDM', '',
          '; ---- song table entry: SONG orders, speed, loop entry (same bank)',
          'MACRO SONG', '\tdb BANK(\\1) - SND_BANK, LOW(\\1), HIGH(\\1), \\2, LOW(\\3), HIGH(\\3), 0, 0', 'ENDM', '',
          '; ---- sound effects',
          'MACRO SFX_ENTRY', '\tdb BANK(\\1) - SND_BANK, LOW(\\1), HIGH(\\1), 0', 'ENDM',
          '; SFX_STEP frames, channel (0-3), register values. ch1 writes NR10-NR14 from the',
          '; 1st-5th values, ch2 NR21-NR24 from the 2nd-5th, ch4 NR41-NR44 from the 1st-4th;',
          '; ch3 has no SFX output. The next step (or SFX_END) is read after "frames" frames.',
          'MACRO SFX_STEP', '\tdb \\1, ((_NARG - 2) << 4) | (\\2)', '\tSHIFT 2', '\tdb \\#', 'ENDM',
          'MACRO SFX_END', '\tdb 0', 'ENDM', '', 'ENDC']
    write(outdir, 'TT_Macros.inc', m)

def write(outdir, fn, lines):
    with open(os.path.join(outdir, fn), 'w', newline='\n') as f:
        f.write('\n'.join(lines) + '\n')

def main():
    global ROM
    ROM = open(sys.argv[1], 'rb').read()
    outdir = sys.argv[2]
    os.makedirs(outdir, exist_ok=True)
    gen_includes(outdir)
    gen_home(outdir)
    gen_driver(outdir)
    files = gen_music(outdir)
    print('music files:', ' '.join(files))

if __name__ == '__main__':
    main()
