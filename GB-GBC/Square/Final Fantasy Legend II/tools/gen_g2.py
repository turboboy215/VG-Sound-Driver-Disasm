#!/usr/bin/env python3
"""Generate a byte-exact RGBDS disassembly of the FFA / FFL2 sound bank.

usage: python tools/gen_g2.py ffa|ffl2 <rom> <names-source> <outdir>
  names-source: FFA_bank0F_soundengine.asm (ffa) or FFL2_audio.s (ffl2) -- only used for label/RAM names.
"""
import sys, os, re, bisect
sys.path.insert(0, os.path.dirname(__file__))
from sm83 import decode
import g2

KEY, ROMF, SRC, OUT = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
os.environ['FFA_ROM' if KEY == 'ffa' else 'FFL2_ROM'] = ROMF
G = g2.Game(KEY)
rb, rw = G.rb, G.rw
ROM = G.r; BB = G.base; BANK = G.bank

# ------------------------------------------------------------------ names from the existing sources
CODE_NAMES = {}; RAM = {}
def clean(n): return n.replace('.', '_')
if KEY == 'ffa':
    lines = open(SRC).read().splitlines()
    for i, l in enumerate(lines):
        m = re.match(r'^([A-Za-z_]\w*):', l)
        if m:
            for l2 in lines[i + 1:i + 4]:
                mm = re.search(r';; 0f:([0-9a-f]{4})', l2)
                if mm: CODE_NAMES[int(mm.group(1), 16)] = m.group(1); break
    for l in lines:
        mm = re.search(r'\[(w\w+(?:\.high)?)\][^;]*;; 0f:[0-9a-f]{4} \$(?:fa|ea) \$([0-9a-f]{2}) \$([0-9a-f]{2})', l) or \
             re.search(r'ld\s+HL, (w\w+)\s*;; 0f:[0-9a-f]{4} \$21 \$([0-9a-f]{2}) \$([0-9a-f]{2})', l)
        if mm: RAM[int(mm.group(3) + mm.group(2), 16)] = mm.group(1).replace('.high', '_hi')
        mm = re.search(r'\[(h\w+(?:\.high)?)\][^;]*;; 0f:[0-9a-f]{4} \$(?:f0|e0) \$([0-9a-f]{2})', l) or \
             re.search(r'ld\s+HL, (h\w+)\s*;; 0f:[0-9a-f]{4} \$21 \$([0-9a-f]{2}) \$ff', l)
        if mm: RAM[0xFF00 + int(mm.group(2), 16)] = mm.group(1).replace('.high', '_hi')
    # the backup area
    RAM.setdefault(0xC15E, 'wMusicDataBackup')
else:
    from align_ffl2 import align
    end, labels, syms, problems = align(SRC, ROMF)
    assert not problems and end == 0x49F5
    for k, v in labels.items(): CODE_NAMES[v] = k.lstrip('_') if k.startswith('_L') else k
    for k, vs in syms.items():
        v = min(vs)
        if v >= 0xC000 and not k.startswith('NR'):
            n = k.replace('hram.audio.', 'h_').replace('mctrl.', 'mctrl')
            n = n.replace('.', '_')
            if n[0] != 'h': n = 'w_' + n
            RAM[v] = n
            if any(t in k for t in ('ptr', 'wave_sample', 'stream')) or k.endswith('freq_low'): pass
HW = {0xFF10: 'rNR10', 0xFF11: 'rNR11', 0xFF12: 'rNR12', 0xFF13: 'rNR13', 0xFF14: 'rNR14', 0xFF16: 'rNR21',
      0xFF17: 'rNR22', 0xFF18: 'rNR23', 0xFF19: 'rNR24', 0xFF1A: 'rNR30', 0xFF1B: 'rNR31', 0xFF1C: 'rNR32',
      0xFF1D: 'rNR33', 0xFF1E: 'rNR34', 0xFF20: 'rNR41', 0xFF21: 'rNR42', 0xFF22: 'rNR43', 0xFF23: 'rNR44',
      0xFF24: 'rNR50', 0xFF25: 'rNR51', 0xFF26: 'rNR52'}
def ramname(a):
    if a in HW: return HW[a]
    if a in RAM: return RAM[a]
    if a - 1 in RAM and not RAM[a - 1].endswith('_hi'): return RAM[a - 1] + '+1'
    return None

# ------------------------------------------------------------------ code
CMDT = list(G.cmdtabs)
handlers = {rw(t + 2 * i) for ch, t in enumerate(CMDT) for i in range(G.ncmd[ch])}
from trace import trace
CODE = trace(ROM, BB, [0x4000, 0x4003] + sorted(handlers))
CODE_END = G.songtab
assert max(CODE) < CODE_END
btargets = {v[2] for v in CODE.values() if v[3] in ('jmp', 'cjmp', 'call') and v[2] and v[2] >= 0x4000}
imm = {}
for pc, (l, m, t, k) in CODE.items():
    if k == 'imm16' and t and 0x4000 <= t < 0x8000: imm[t] = pc
# fixed driver tables, found from the code
INIT = min(a for a in imm if a < 0x41C0 and a not in CODE)          # musicChannelInitData / audio_init_data
FREQ = next(a for a in imm if rw(a) == 0x802C); LENT = FREQ + 170
assert rw(FREQ) == 0x802C and rb(LENT) == 0x60
G.LEN = [rb(LENT + i) for i in range(13)]
OCT = next(a for a in imm if rb(a) == 0x18 and rb(a + 1) == 0x30 and rb(a + 7) == 0xA0)
PANT = sorted(a for a in imm if a not in CODE and rb(a) == 0 and rb(a + 3) in (0x11, 0x22, 0x44) and a < CODE_END)
DPF, DVF = rw(INIT + 5), rw(INIT + 19)

# ------------------------------------------------------------------ streams
SONGS = G.songs
owner = {}; mlab = set()
def walk(start, ch, dynamic):
    a = start; A = 0; B = G.initB; seen = set(); todo = [start]
    if dynamic:
        while True:
            st = (a, A, B)
            if st in seen: return
            seen.add(st)
            b = rb(a); n = G.isize(a, ch)
            if n is None: return
            owner.setdefault(a, ch)
            if b < 0xE0 or b == 0xFF:
                if b == 0xFF: return
                a += 1; continue
            c = b & 15; arg = G.args[c][ch]
            if arg == g2.H:
                if KEY == 'ffa': return
                a += 1; continue
            if c == 1: mlab.add(rw(a + 1)); a = rw(a + 1); continue
            if c in (2, 9):
                mlab.add(rw(a + 1))
                if c == 2: A = (A - 1) & 255; z = A
                else: B = (B - 1) & 255; z = B
                a = rw(a + 1) if z else a + 3; continue
            if c == 3: A = rb(a + 1)
            if c == 10: B = rb(a + 1)
            if c == 11: mlab.add(rw(a + 2)); a = rw(a + 2) if rb(a + 1) == A else a + 4; continue
            a += n
    seen = set()
    while todo:
        a = todo.pop()
        while a not in seen:
            seen.add(a)
            n = G.isize(a, ch)
            if n is None: break
            if a in owner and owner[a] != ch: break
            owner.setdefault(a, ch)
            b = rb(a)
            if b == 0xFF: break
            if b < 0xE0: a += 1; continue
            c = b & 15; arg = G.args[c][ch]
            if arg == g2.H and KEY == 'ffa': break
            if c == 1: mlab.add(rw(a + 1)); a = rw(a + 1); continue
            if c in (2, 9): mlab.add(rw(a + 1)); todo.append(rw(a + 1))
            if c == 11: mlab.add(rw(a + 2)); todo.append(rw(a + 2))
            a += n
for s in SONGS:
    for ch in range(3): walk(s[ch], ch, True)
for s in SONGS:
    for ch in range(3): walk(s[ch], ch, False)
volrefs, pitchrefs, waverefs = {DVF}, {DPF}, set()
for a, ch in owner.items():
    b = rb(a)
    if b < 0xE0 or b == 0xFF: continue
    c = b & 15
    if c == 0 and ch < 2: volrefs.add(rw(a + 1))
    if c == 4: pitchrefs.add(rw(a + 1))
    if c == 8 and ch == 2: waverefs.add(rw(a + 1))
FX_START = min(x for x in volrefs | pitchrefs | waverefs if x >= CODE_END)
MUS_START = CODE_END + 6 * G.nsong

# ------------------------------------------------------------------ SFX
SFXT = [rw(G.sfxtone + 2 * i) for i in range(G.nsfx)]
SFXN = [rw(G.sfxnoise + 2 * i) for i in range(G.nsfx)]
sfx_own = {}; sfx_lab = set()
def sfx_walk(a, noise):
    todo = [a]
    while todo:
        a = todo.pop()
        while a not in sfx_own:
            sfx_own[a] = noise
            d = rb(a)
            if d == 0: break
            if d == 0xEF: sfx_lab.add(rw(a + 1)); todo.append(rw(a + 1)); a += 3; continue
            if d >= 0xF0: a += 1; continue
            a += 3 if noise else 6
for p in SFXT: sfx_walk(p, 0)
for p in SFXN: sfx_walk(p, 1)
SFX_START = G.sfxnoise + 2 * G.nsfx
def sfx_end_addr():
    a = SFX_START
    while a in sfx_own:
        d = rb(a); nz = sfx_own[a]
        a += 1 if (d == 0 or d >= 0xF0) else 3 if d == 0xEF else (3 if nz else 6)
    return a
END = max(sfx_end_addr(), max(sfx_own) + 1)
assert all(x < END for x in sfx_own)

# ------------------------------------------------------------------ labels
LABEL = {}
for a, n in CODE_NAMES.items():
    if 0x4000 <= a < END and not n.startswith('data_'): LABEL[a] = clean(n)
LABEL.setdefault(G.songtab, 'SongTable'); LABEL.setdefault(G.sfxtone, 'SfxToneTable'); LABEL.setdefault(G.sfxnoise, 'SfxNoiseTable')
for t, n in zip(CMDT, ('CmdTable_Ch2', 'CmdTable_Ch1', 'CmdTable_Ch3')): LABEL.setdefault(t, n)
for a, n in ((INIT, 'ChannelInitData'), (FREQ, 'NoteFreqTable'), (LENT, 'NoteLengthTable'), (OCT, 'OctaveDeltaTable'),
             (DPF, 'DefaultPitchFx'), (DVF, 'DefaultVolumeFx')): LABEL.setdefault(a, n)
for i, a in enumerate(PANT): LABEL.setdefault(a, 'PanTable%d' % i)
CHN = ['Ch2', 'Ch1', 'Ch3']
for i, s in enumerate(SONGS):
    for ch in range(3): LABEL.setdefault(s[ch], 'Song%02X_%s' % (i + 1, CHN[ch]))
for a in sorted(volrefs): LABEL.setdefault(a, 'VolFx_%04X' % a)
for a in sorted(pitchrefs): LABEL.setdefault(a, 'PitchFx_%04X' % a)
for a in sorted(waverefs): LABEL.setdefault(a, 'Wave_%04X' % a)
for i in range(G.nsfx):
    LABEL.setdefault(SFXT[i], 'Sfx%02X_Ch1' % (i + 1)); LABEL.setdefault(SFXN[i], 'Sfx%02X_Ch4' % (i + 1))
# effect-table internal jump targets
fx_targets = set()
GLOBALS = sorted(LABEL)
LOCALS = {a for a in btargets | mlab | sfx_lab if a not in LABEL and a >= 0x4000}
def parent(a): return GLOBALS[bisect.bisect_right(GLOBALS, a) - 1]
def ref(a):
    if a in LABEL: return LABEL[a]
    if a in LOCALS: return '%s.l%04X' % (LABEL[parent(a)], a)
    raise KeyError('%04X' % a)
def addlocal(a):
    if a not in LABEL: LOCALS.add(a)

# ------------------------------------------------------------------ emit
out = []; W = out.append
TITLE = G.title
W('''; =============================================================================
; %s (U) [!].gb - Square sound driver (FFL2/FFA generation)
; Bank $%02X $4000-$%04X.  Generated by tools/gen_g2.py; label and RAM names from %s.
; Rebuilds byte-exact with RGBDS 0.9.x:
;   rgbasm -Wall -o snd.o <this file> ; rgblink -o snd.gb snd.o ; python tools/cmp_bank.py <this file> <rom> snd.gb
; =============================================================================
''' % (TITLE, BANK, END - 1, os.path.basename(SRC)))
for a, n in sorted(HW.items()): W('DEF %-8s EQU $%04X' % (n, a))
W('')
for a, n in sorted(RAM.items()): W('DEF %-46s EQU $%04X' % (n, a))
NOTEN = ['C_', 'Cs_', 'D_', 'Ds_', 'E_', 'F_', 'Fs_', 'G_', 'Gs_', 'A_', 'As_', 'B_', 'C2_', 'Cs2_']
W('''
; ---------------------------------------------------------------- music macros
; note byte = length index << 4 | pitch;  pitch 0-B = C..B, C/D = C/C# one octave up, E = tie, F = rest''')
for i, n in enumerate(NOTEN): W('DEF %-4s EQU %d' % (n, i))
LNAMES = {}
for i, l in enumerate(G.LEN):
    nm = 'L%d' % l
    LNAMES[i] = nm
    W('DEF %-4s EQU %d' % (nm, i))
W(r'''MACRO note      ; pitch, ticks
    db L\2 << 4 | (\1)
ENDM
MACRO tie       ; ticks
    db L\1 << 4 | $E
ENDM
MACRO rest      ; ticks
    db L\1 << 4 | $F
ENDM
MACRO octave    ; 0-7
    db $D0 | (\1)
ENDM
MACRO oct_up    ; 1-4
    db $D8 | ((\1) - 1)
ENDM
MACRO oct_down  ; 1-4
    db $DC | ((\1) - 1)
ENDM
MACRO vol_fx    ; CH1/CH2
    db $E0
    dw \1
ENDM
MACRO volume    ; CH3: NR32
    db $E0, \1
ENDM
MACRO jump
    db $E1
    dw \1
ENDM
MACRO loop_a    ; --A != 0 -> jump
    db $E2
    dw \1
ENDM
MACRO set_a
    db $E3, \1
ENDM
MACRO pitch_fx
    db $E4
    dw \1
ENDM
MACRO duty      ; CH1/CH2
    db $E5, \1
ENDM
MACRO pan       ; 0 off, 1 right, 2 left, 3 both
    db $E6, \1
ENDM
MACRO tempo     ; CH2
    db $E7, \1
ENDM
MACRO wave      ; CH3
    db $E8
    dw \1
ENDM
MACRO loop_b
    db $E9
    dw \1
ENDM
MACRO set_b
    db $EA, \1
ENDM
MACRO if_a      ; A == n -> jump
    db $EB, \1
    dw \2
ENDM
MACRO doubletime ; FFA CH2 only: sets a flag the tick code never really tests
    db $EC, \1
ENDM
MACRO end_track
    db $FF
ENDM
MACRO fx        ; frames/3, value (NRx2, or signed period offset)
    db \1, (\2) & $FF
ENDM
MACRO fx_jump
    db 0
    dw \1
ENDM
MACRO sfx_tone  ; frames, NR10..NR14
    db \1, \2, \3, \4, \5, \6
ENDM
MACRO sfx_noise ; frames, NR42, NR43
    db \1, \2, \3
ENDM
MACRO sfx_count
    db $F0 | (\1)
ENDM
MACRO sfx_loop
    db $EF
    dw \1
ENDM
MACRO sfx_end
    db 0
ENDM
''')
W('SECTION "Sound", ROMX[$4000], BANK[$%02X]' % BANK)

def sym(m, kind, tgt):
    def rep(mm):
        v = int(mm.group(1), 16)
        if kind in ('jmp', 'cjmp', 'call') and v == tgt: return ref(v)
        if v >= 0xFF00 or 0xC000 <= v < 0xE000: return ramname(v) or mm.group(0)
        if 0x4000 <= v < 0x8000 and (v in LABEL or v in LOCALS): return ref(v)
        return mm.group(0)
    return re.sub(r'\$([0-9A-F]{4})', rep, m)
def lab(a):
    if a in LABEL: W(''); W('%s:' % LABEL[a])
    elif a in LOCALS: W('.l%04X:' % a)
def dbl(bs): return 'db ' + ', '.join('$%02X' % x for x in bs)

# fx tables inside code range need local jump targets too
def fx_pairs_targets(a, lim):
    while a < lim:
        if rb(a) == 0: addlocal(rw(a + 1)); return a + 3
        a += 2
    return a
fx_pairs_targets(DPF, DVF);
# collect fx targets in fx area
fxstarts = sorted(set(x for x in volrefs | pitchrefs | waverefs if x >= FX_START)) + [G.sfxtone]
KIND = {a: ('w' if a in waverefs else 'p' if a in pitchrefs else 'v') for a in fxstarts[:-1]}
for i, st in enumerate(fxstarts[:-1]):
    a = st; nxt = fxstarts[i + 1]
    if KIND[st] == 'w': continue
    while a + 1 < nxt:
        if rb(a) == 0 and a + 2 < nxt: addlocal(rw(a + 1)); a += 3
        else: a += 2
LOCALS -= set(LABEL)

a = 0x4000
while a < CODE_END:
    lab(a)
    if a in CODE:
        l, m, t, k = CODE[a]; W('    ' + sym(m, k, t)); a += l; continue
    if a == INIT:
        W('    db $%02X, $%02X ; +0 sfx timer, +1 note timer' % (rb(a), rb(a + 1)))
        W('    dw $%04X       ; +2 stream pointer' % rw(a + 2))
        W('    db $%02X        ; +4 pitch fx timer' % rb(a + 4))
        W('    dw %s, %s' % (ref(rw(a + 5)), ref(rw(a + 7))))
        W('    ' + dbl([rb(a + 9 + i) for i in range(9)]) + ' ; +9..+$11 (+$11 = ended flag)')
        W('    db $%02X        ; +$12 volume fx timer' % rb(a + 18))
        W('    dw %s, %s' % (ref(rw(a + 19)), ref(rw(a + 21))))
        if DPF - INIT == 24: W('    db $%02X        ; +$17 loop counter B' % rb(a + 23))
        else: W('    ; (23 bytes: the $18-byte copy also takes DefaultPitchFx\'s first byte ($%02X) as loop counter B)' % rb(a + 23))
        a = DPF; continue
    if a in (DPF, DVF):
        e = DVF if a == DPF else FREQ
        first = True
        while a < e:
            if not first: lab(a)
            first = False
            if rb(a) == 0: W('    fx_jump %s' % ref(rw(a + 1))); a += 3
            else: W('    fx $%02X, $%02X' % (rb(a), rb(a + 1))); a += 2
        continue
    if a == FREQ:
        W('    ; period | $8000 (trigger); index = octave*24 + pitch*2')
        for i in range(0, 85, 12): W('    dw ' + ', '.join('$%04X' % rw(a + 2 * j) for j in range(i, min(85, i + 12))))
        a += 170; continue
    if a == LENT: W('    ' + dbl([rb(a + i) for i in range(13)])); a += 13; continue
    if a in CMDT:
        ch = CMDT.index(a)
        for i in range(G.ncmd[ch]):
            h = rw(a + 2 * i)
            W('    dw %-40s ; $E%X%s' % (ref(h), i, '  (halt)' if h == G.halt and KEY == 'ffa' else '  (null)' if h == G.halt else ''))
        a += 2 * G.ncmd[ch]; continue
    # misc data until the next code/label
    e = a + 1
    while e < CODE_END and e not in CODE and e not in LABEL and e not in (INIT, DPF, DVF, FREQ, LENT) and e not in CMDT: e += 1
    W('    ' + dbl([rb(x) for x in range(a, e)])); a = e

W(''); W('%s:  ; %d songs x (CH2, CH1, CH3), id 1-based' % (LABEL[G.songtab], G.nsong))
for i, s in enumerate(SONGS): W('    dw %s ; $%02X' % (', '.join(ref(x) for x in s), i + 1))
a = MUS_START
while a < FX_START:
    lab(a)
    ch = owner.get(a)
    b = rb(a)
    if ch is None: W('    db $%02X ; (unreached)' % b); a += 1; continue
    if b < 0xE0 and b >= 0xD0:
        W('    ' + ('octave %d' % (b & 7) if not b & 8 else 'oct_up %d' % ((b & 7) + 1) if (b & 7) < 4 else 'oct_down %d' % ((b & 7) - 3))); a += 1; continue
    if b < 0xD0:
        p, l = b & 15, LNAMES[b >> 4][1:]
        W('    ' + ('tie %s' % l if p == 14 else 'rest %s' % l if p == 15 else 'note %s, %s' % (NOTEN[p], l))); a += 1; continue
    if b == 0xFF: W('    end_track'); a += 1; continue
    c = b & 15; n = G.args[c][ch]
    if b >= 0xF0 or n == g2.H or n is None:
        W('    db $%02X ; %s' % (b, 'halt/null slot' if n == g2.H else 'alias/invalid')); a += 1; continue
    A1 = rb(a + 1)
    s = {0: lambda: ('volume $%02X' % A1) if ch == 2 else 'vol_fx %s' % ref(rw(a + 1)), 1: lambda: 'jump %s' % ref(rw(a + 1)),
         2: lambda: 'loop_a %s' % ref(rw(a + 1)), 3: lambda: 'set_a %d' % A1, 4: lambda: 'pitch_fx %s' % ref(rw(a + 1)),
         5: lambda: 'duty $%02X' % A1, 6: lambda: 'pan %d' % A1, 7: lambda: 'tempo $%02X' % A1,
         8: lambda: 'wave %s' % ref(rw(a + 1)), 9: lambda: 'loop_b %s' % ref(rw(a + 1)), 10: lambda: 'set_b %d' % A1,
         11: lambda: 'if_a %d, %s' % (A1, ref(rw(a + 2))), 12: lambda: 'doubletime $%02X' % A1}[c]()
    W('    ' + s); a += 1 + n

W(''); W('; ---- effect tables: (frames/3, value) pairs, 0 = jump. Volume: value = NRx2, $FF frames = hold.')
for i, st in enumerate(fxstarts[:-1]):
    a = st; nxt = fxstarts[i + 1]
    if KIND[st] == 'w':
        lab(a); W('    ' + dbl([rb(a + j) for j in range(16)])); a += 16
        if a < nxt: W('    ' + dbl([rb(x) for x in range(a, nxt)]) + ' ; (unreferenced)')
        continue
    while a < nxt:
        lab(a)
        if a + 2 < nxt + (0 if KIND[st] else 0) and rb(a) == 0 and a + 3 <= nxt: W('    fx_jump %s' % ref(rw(a + 1))); a += 3
        elif a + 2 <= nxt:
            v = rb(a + 1)
            if KIND[st] == 'p': W('    fx $%02X, %d' % (rb(a), v - 256 if v > 127 else v))
            else: W('    fx $%02X, $%02X' % (rb(a), v))
            a += 2
        else: W('    db $%02X' % rb(a)); a += 1

W(''); W('%s:   ; %d SFX, CH1 part' % (LABEL[G.sfxtone], G.nsfx))
for p in SFXT: W('    dw %s' % ref(p))
W(''); W('%s:  ; CH4 part' % LABEL[G.sfxnoise])
for p in SFXN: W('    dw %s' % ref(p))
a = SFX_START
while a < END:
    lab(a)
    if a not in sfx_own: W('    db $%02X ; (unreached)' % rb(a)); a += 1; continue
    nz = sfx_own[a]; d = rb(a)
    if d == 0: W('    sfx_end'); a += 1
    elif d == 0xEF: W('    sfx_loop %s' % ref(rw(a + 1))); a += 3
    elif d >= 0xF0: W('    sfx_count %d' % (d & 15)); a += 1
    elif nz: W('    sfx_noise %d, $%02X, $%02X' % (d, rb(a + 1), rb(a + 2))); a += 3
    else: W('    sfx_tone %d, ' % d + ', '.join('$%02X' % rb(a + 1 + i) for i in range(5))); a += 6
W('')
name = {'ffa': 'FFA_SoundDriver.asm', 'ffl2': 'FFL2_SoundDriver.asm'}[KEY]
open(os.path.join(OUT, name), 'w', newline='\n').write('\n'.join(out))
print('wrote', name, len(out), 'lines; end $%04X; songs %d sfx %d; fx $%04X; unreached music bytes %d' %
      (END, G.nsong, G.nsfx, FX_START, sum(1 for l in out if l.endswith('(unreached)'))))
if os.environ.get('SHOWGAPS'):
    a = MUS_START; gaps = []
    while a < FX_START:
        if a not in owner:
            b = a
            while b < FX_START and b not in owner: b += 1
            # skip bytes inside owned instructions
            gaps.append((a, b)); a = b
        else:
            a += G.isize(a, owner[a]) or 1
    for x, y in gaps: print('%04X-%04X %3d %s' % (x, y - 1, y - x, ' '.join('%02X' % rb(z) for z in range(x, min(y, x + 10)))))
