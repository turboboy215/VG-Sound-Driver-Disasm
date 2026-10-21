#!/usr/bin/env python3
"""Generate Animorphs_SoundDriver.asm (byte-exact RGBDS source) from the ROM.
Usage: mkasm.py ROM > Animorphs_SoundDriver.asm"""
import sys, os, json, re
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from z80tab import instructions, cb_instructions
from comments import ROUTINES, COMMENTS, BLOCKS, OPERAND_OVERRIDE
import faparse as FP

ROM = open(sys.argv[1], 'rb').read()
FP.ROM = ROM
def rb(bank, addr): return ROM[bank*0x4000 + addr - (0x4000 if bank else 0)]
def rw(bank, addr): return rb(bank, addr) | rb(bank, addr+1) << 8

HW = {0x10:'rNR10',0x11:'rNR11',0x12:'rNR12',0x13:'rNR13',0x14:'rNR14',0x16:'rNR21',0x17:'rNR22',0x18:'rNR23',
      0x19:'rNR24',0x1a:'rNR30',0x1b:'rNR31',0x1c:'rNR32',0x1d:'rNR33',0x1e:'rNR34',0x20:'rNR41',0x21:'rNR42',
      0x22:'rNR43',0x23:'rNR44',0x24:'rNR50',0x25:'rNR51',0x26:'rNR52',0x06:'rTMA',0x07:'rTAC',0xff:'rIE',
      0x86:'hCurBank',0x89:'hSamplePlaying'}
for i in range(16): HW[0x30+i] = '_AUD3WAVERAM+%d' % i if i else '_AUD3WAVERAM'

# ---------------- RAM symbols ----------------
GLOBALS = {0xCA00:'wSongNum',0xCA01:'wSongBank',0xCA02:'wPatTable',0xCA03:'wPatTable+1',0xCA04:'wSeqPtr',
 0xCA05:'wSeqPtr+1',0xCA06:'wTickAcc',0xCA07:'wSpeed2',0xCA08:'wSongTranspose',0xCA09:'wCurChan',
 0xCA0A:'wShuffleRate',0xCA0B:'wShufflePtr',0xCA0C:'wShufflePtr+1',0xCA0D:'wShufflePhase',0xCA0E:'wShufflePhase+1',
 0xCA0F:'wSeqAdvance',0xCA10:'wCh3Reload',0xCA11:'wMixStep',0xCA12:'wSampleNum',0xCA20:'wWaveBuf',
 0xC320:'wSndTickToggle'}
CHBASE = [0x30, 0x64, 0x98, 0xCC]
CHOFF = {0x00:'CH_PTR',0x01:'CH_PTR+1',0x02:'CH_PITCH',0x03:'CH_PITCH+1',0x04:'CH_PORTA_TGT',0x05:'CH_PORTA_TGT+1',
 0x06:'CH_NOTE_PITCH',0x07:'CH_NOTE_PITCH+1',0x08:'CH_PAN',0x09:'CH_NRX1',0x0A:'CH_NRX2',0x0B:'CH_CTRL',0x0C:'CH_NR10',
 0x0D:'CH_TRANSPOSE',0x0E:'CH_BASE_TRANSPOSE',0x0F:'CH_ROWS',0x10:'CH_TRIG_DELAY',0x11:'CH_DELAY_CNT',0x12:'CH_RETRIG',
 0x13:'CH_VIB_PTR',0x14:'CH_VIB_PTR+1',0x15:'CH_VIB_RATE',0x16:'CH_ARP',0x17:'CH_ARP+1',0x18:'CH_ARP_CNT',
 0x19:'CH_ARP_RATE',0x1A:'CH_PORTA_RATE',0x1B:'CH_FINE',0x1C:'CH_APAN',0x1D:'CH_APAN_RATE',0x1E:'CH_APAN_CNT',
 0x1F:'CH_APWM',0x20:'CH_APWM_RATE',0x21:'CH_APWM_CNT',0x22:'CH_MACRO_RET',0x23:'CH_MACRO_RET+1',0x24:'CH_WAIT',
 0x27:'CH_DIRTY'}
def ramsym(a):
    if a in GLOBALS: return GLOBALS[a]
    if 0xCA30 <= a <= 0xCAFF:
        lo = a & 0xFF
        for n, b in reversed(list(enumerate(CHBASE))):
            if lo >= b:
                off = lo - b
                return 'wCh%d+%s' % (n+1, CHOFF.get(off, '$%02X' % off))
    if 0xCA13 <= a <= 0xCA1F or 0xCA21 <= a <= 0xCA2F:
        return 'wWaveBuf%+d' % (a - 0xCA20) if a > 0xCA20 else '$%04X' % a
    return None

# ---------------- labels ----------------
LABELS = {}   # (bank, addr) -> name
for (b, a), name in ROUTINES.items(): LABELS[(b, a)] = name
DATA9 = {0x4000:'VibratoTables',0x5000:'NoiseTable',0x5040:'ShuffleTable',0x5140:'ShuffleRateTable',
         0x5160:'WaveDistTables',0x5560:'WavePresets',0x6560:'WavePresetGuard',0x6760:'CommandTable',
         0x7480:'SongPtrTable',0x74A8:'SongBankTable'}
for a, n in DATA9.items(): LABELS[(9, a)] = n
LABELS[(0x0A, 0x4000)] = 'PeriodTable'
EXTERN = {0x0603:'ReadStreamByte',0x05F0:'ReadSongByte',0x0617:'ReadPeriodByte',0x061B:'SndBankRestore',
          0x0623:'BankHome', 0x67E0:'SndPlaySongCold',0x67E7:'SndPlaySong',0x691C:'SndUpdate'}

CODE = {0: (0x05B2, 0x062B), 9: (0x67E0, 0x7480)}
CODE0B = (0x0649, 0x0655)

def decode(bank, pc):
    op = rb(bank, pc)
    if op == 0xCB: return cb_instructions[rb(bank, pc+1)], 2, None
    t = instructions.get(op)
    if 'd16' in t or 'a16' in t: return t, 3, rw(bank, pc+1)
    if 'r8' in t:
        r = rb(bank, pc+1); r = r - 256 if r > 127 else r; return t, 2, pc + 2 + r
    if 'a8' in t or 'd8' in t: return t, 2, rb(bank, pc+1)
    return t, 1, None

def collect_targets(bank, s, e, tg):
    pc = s
    while pc < e:
        t, n, v = decode(bank, pc)
        if any(t.startswith(k) for k in ('jp ', 'jr ', 'call ')) and v is not None and t != 'jp hl':
            if s <= v < e or (bank == 0 and CODE0B[0] <= v < CODE0B[1]): tg.add((bank, v))
        pc += n

TARGETS = set()
collect_targets(0, *CODE[0], TARGETS); collect_targets(0, *CODE0B, TARGETS); collect_targets(9, *CODE[9], TARGETS)
for i in range(64):
    v = rw(9, 0x6760 + 2*i); TARGETS.add((9, v))
for t in TARGETS:
    if t not in LABELS: LABELS[t] = None   # local

def parent(bank, a):
    best = None
    for (b, x), n in LABELS.items():
        if b == bank and n and not n.startswith('.') and x <= a and (best is None or x > best[0]):
            best = (x, n)
    return best[1] if best else None

def labelname(bank, a, frm=None):
    n = LABELS.get((bank, a))
    if n: return n
    loc = '.l%04X' % a
    if frm is not None and parent(bank, a) != parent(bank, frm):
        return parent(bank, a) + loc
    return loc

def operand_text(bank, pc, t, v):
    ov = OPERAND_OVERRIDE.get((bank, pc))
    if ov: return ov
    if v is None: return t
    if 'a8' in t:
        return t.replace('a8', HW.get(v, '$FF%02X' % v))
    if 'r8' in t or t.startswith(('jp ', 'call ')):
        if t.startswith(('jp ', 'call ', 'jr ')):
            if (bank, v) in LABELS or (bank == 0 and v in EXTERN) or (bank == 9 and v < 0x4000 and v in EXTERN):
                if (bank, v) in LABELS: s = labelname(bank, v, pc)
                else: s = EXTERN[v]
            elif v in EXTERN: s = EXTERN[v]
            else: s = '$%04X' % v
            return t.replace('pc+r8', s).replace('a16', s)
    if 'a16' in t:
        s = ramsym(v) or ('MBC5_ROMB0' if v == 0x2666 else None) or EXTERN.get(v) or '$%04X' % v
        return t.replace('a16', s)
    if 'd16' in t:
        s = ramsym(v)
        if bank == 9 and (9, v) in LABELS: s = labelname(9, v)
        return t.replace('d16', s or '$%04X' % v)
    if 'd8' in t:
        return t.replace('d8', '$%02X' % v)
    return t

def fix_syntax(t):
    t = t.replace('ld [c],a', 'ldh [c],a').replace('ld a,[c]', 'ldh a,[c]')
    return t

CHB = {0x30:'LOW(wCh1)', 0x64:'LOW(wCh2)', 0x98:'LOW(wCh3)', 0xCC:'LOW(wCh4)'}
def auto_operand(bank, pc, t, v, prev, nxt):
    """symbolise channel-structure immediates"""
    if v is None or 'd8' not in t: return None
    if t == 'ld a,d8' and nxt and nxt[0] == 'add c' and v in CHOFF: return 'ld a,' + CHOFF[v]
    if t == 'add d8' and prev and prev[0] == 'ld a,[a16]' and prev[2] == 0xCA09 and v in CHOFF: return 'add ' + CHOFF[v]
    if t == 'cp d8' and v in CHB and bank == 9: return 'cp ' + CHB[v]
    if t == 'ld a,d8' and v in CHB and nxt and nxt[0] == 'call a16' and nxt[2] == 0x7081: return 'ld a,' + CHB[v]
    if t in ('ld h,d8', 'ld b,d8') and v == 0xCA: return t.replace('d8', 'HIGH(wCh1)')
    if t == 'ld l,d8' and bank == 9 and v >= 0x30:
        return 'ld l,LOW(%s)' % ramsym(0xCA00 + v)
    return None

def emit_code(out, bank, s, e):
    seq = []
    pc = s
    while pc < e:
        t, n, v = decode(bank, pc); seq.append((pc, t, n, v)); pc += n
    for i, (pc, t, n, v) in enumerate(seq):
        prev = (seq[i-1][1], 0, seq[i-1][3]) if i else None
        nxt = (seq[i+1][1], 0, seq[i+1][3]) if i + 1 < len(seq) else None
        ao = None if (bank, pc) in OPERAND_OVERRIDE else auto_operand(bank, pc, t, v, prev, nxt)
        if ao: OPERAND_OVERRIDE[(bank, pc)] = ao
    pc = s
    while pc < e:
        if (bank, pc) in BLOCKS:
            out.append('')
            for l in BLOCKS[(bank, pc)].strip('\n').split('\n'): out.append('; ' + l if l else ';')
        if (bank, pc) in LABELS:
            n = labelname(bank, pc)
            out.append(('%s:' % n) if not n.startswith('.') else n)
        t, n, v = decode(bank, pc)
        txt = fix_syntax(operand_text(bank, pc, t, v))
        c = COMMENTS.get((bank, pc))
        raw = ' '.join('%02X' % rb(bank, pc+i) for i in range(n))
        line = '\t%-28s' % txt
        line += ' ; %02X:%04X  %-9s' % (bank, pc, raw)
        if c: line += ' ' + c
        out.append(line.rstrip())
        pc += n

# ---------------- data helpers ----------------
def db_line(bs): return '\tdb ' + ','.join('$%02X' % x for x in bs)
def dw_line(ws): return '\tdw ' + ','.join('$%04X' % x for x in ws)

NOTE = ['C_','Cs','D_','Ds','E_','F_','Fs','G_','Gs','A_','As','B_']
def notesym(n):
    if 1 <= n <= 72: n -= 1; return '%s%d' % (NOTE[n % 12], 2 + n // 12)
    return '$%02X' % n

def emit_bank9_tables(out):
    out.append('')
    out.append('; ---------------------------------------------------------------------------')
    out.append('; VibratoTables: 32 depths x 64 signed words, added to the pitch (1 semitone = $80).')
    out.append('; Depth d is selected by command E1; phase steps by the vibrato rate each update.')
    out.append('; ---------------------------------------------------------------------------')
    out.append('VibratoTables:')
    for d in range(32):
        out.append('; depth $%02X' % d)
        for r in range(8):
            out.append(dw_line([rw(9, 0x4000 + d*128 + r*16 + 2*i) for i in range(8)]))
    out.append('')
    out.append('; NoiseTable: NR43 value per noise index 0-63 (index = noise note + transposes).')
    out.append('NoiseTable:')
    for r in range(4): out.append(db_line([rb(9, 0x5000 + r*16 + i) for i in range(16)]))
    out.append('')
    out.append('; ShuffleTable: 16 depths x 16 phase steps; tempo multiplier in 1/32 ($20 = x1).')
    out.append('ShuffleTable:')
    for r in range(16): out.append(db_line([rb(9, 0x5040 + r*16 + i) for i in range(16)]) + ' ; depth %d' % r)
    out.append('')
    out.append('; ShuffleRateTable: per-row phase increment for shuffle rate n = $1000/(n+1) (12-bit phase).')
    out.append('ShuffleRateTable:')
    out.append(dw_line([rw(9, 0x5140 + 2*i) for i in range(8)]))
    out.append(dw_line([rw(9, 0x5150 + 2*i) for i in range(8)]))
    out.append('')
    out.append('; WaveDistTables: 128 x 16-nibble lookup tables (8 bytes each) for command D6.')
    out.append('; Index = type*16 + gain (type 0-7 per the tracker help: magneto, SF dirt, SF fuzz,')
    out.append('; SF hard clip, lofi, HKN, wavewarm, mangle; gain 8 = unity).')
    out.append('WaveDistTables:')
    for t in range(128):
        out.append(db_line([rb(9, 0x5160 + t*8 + i) for i in range(8)]) + ' ; $%02X type %d gain %X' % (t, t >> 4, t & 15))
    out.append('')
    out.append('; WavePresets: 256 x 16-byte CH3 waveforms (command DA loads, D7 mixes).')
    out.append('WavePresets:')
    for p in range(256):
        out.append(db_line([rb(9, 0x5560 + p*16 + i) for i in range(16)]) + ' ; $%02X' % p)
    out.append('')
    out.append('; WavePresetGuard: exact copy of presets $00-$1F. D7 (mix) resamples the preset and can')
    out.append('; read up to ~0x200 bytes past it; this keeps the read in waveform data for high presets.')
    out.append('WavePresetGuard:')
    for p in range(32):
        out.append(db_line([rb(9, 0x6560 + p*16 + i) for i in range(16)]) + ' ; = preset $%02X' % p)
    out.append('')
    out.append('; CommandTable: handlers for event bytes $C0-$FF (unlisted ones are 1-byte no-ops).')
    out.append('CommandTable:')
    for i in range(64):
        v = rw(9, 0x6760 + 2*i)
        out.append('\tdw %-24s ; $%02X' % (labelname(9, v), 0xC0 + i))

# ---------------- songs ----------------
CMDMAC = {0xD3:'call_macro',0xD4:'auto_pwm',0xD5:'auto_pan',0xD6:'wave_dist',0xD7:'wave_mix',0xD8:'stop_sample',
 0xD9:'reset_vib',0xDA:'wave_preset',0xDB:'fine_tune',0xDC:'play_sample',0xDD:'arpeggio',0xDE:'glissando',
 0xDF:'porta_src',0xE0:'porta_rate',0xE1:'vibrato',0xE2:'restart_env',0xE3:'retrig_delay',0xE4:'trig_delay',
 0xE5:'use_duration',0xE6:'sweep',0xE7:'env_volume',0xE8:'env_rate',0xE9:'duration',0xEA:'duty',0xFB:'pan',
 0xFC:'shuffle',0xFD:'transpose',0xFE:'speed',0xFF:'end_pattern'}

def song_items(s, lbl):
    """Return list of (addr, size, [lines], labels) for a song, in address order."""
    bank, st = s['bank'], s['start']
    items = []
    L = {}   # addr -> label list
    def addlabel(a, n):
        L.setdefault(a, [])
        if n not in L[a]: L[a].append(n)
    addlabel(st, lbl)
    addlabel(s['seq'], lbl + '_Seq')
    addlabel(s['pt'], lbl + '_PatTable')
    # header
    hdr = ['\tdw %s_Seq - %s' % (lbl, lbl), '\tdw %s_PatTable - %s' % (lbl, lbl),
           '\tdw %s_End - %s           ; song length' % (lbl, lbl),
           '\tdb %d                      ; number of patterns' % rb(bank, st+6)]
    items.append((st, 7, hdr))
    nb = [rb(bank, x) for x in range(st+7, s['seq'])]
    txt = bytes(nb[:-1]).decode('latin1')
    if all(32 <= c < 127 and c != 34 for c in nb[:-1]) and nb[-1] in (0x00, 0xFF):
        items.append((st+7, len(nb), ['\tdb "%s", $%02X          ; song name' % (txt, nb[-1])]))
    else:
        items.append((st+7, len(nb), [db_line(nb) + ' ; song name']))
    # sequence
    seql = []
    for a, b, t in s['seqitems']:
        k = b[0]
        if k == 0xFB: seql.append('\tseq_pan $%02X' % b[1])
        elif k == 0xFC: seql.append('\tseq_shuffle $%02X, $%02X' % (b[1], b[2]))
        elif k == 0xFD: seql.append('\tseq_transpose $%02X' % b[1])
        elif k == 0xFE: seql.append('\tseq_speed $%02X' % b[1])
        elif k == 0xFF: seql.append('\tseq_loop')
        else: seql.append('\tseq_pattern %d' % k)
    items.append((s['seq'], s['seqend'] - s['seq'], seql))
    # stream labels
    streams = {}   # addr -> (ch, name)
    for p in s['patterns']:
        for c, ch in enumerate(p['ch']):
            if ch['addr'] not in streams:
                streams[ch['addr']] = (c, '%s_P%d_CH%d' % (lbl, p['num'], c+1))
    for m in s['macros']:
        if m['addr'] not in streams: streams[m['addr']] = (m['ch'], '%s_Macro_%04X' % (lbl, m['addr']))
    # pattern table
    ptl = []
    for p in s['patterns']:
        ptl.append('\tdw ' + ', '.join('%s - %s_PatTable' % (streams[ch['addr']][1], lbl) for ch in p['ch'])
                   + ' ; pattern %d' % p['num'])
    items.append((s['pt'], 8*s['npat'], ptl))
    for a, (c, n) in streams.items(): addlabel(a, n)
    # stream events (merge by address; check consistency)
    ev = {}
    def addev(c, events):
        for a, b, t in events:
            if a in ev and ev[a][0] != b: raise SystemExit('overlap mismatch at %X' % a)
            ev[a] = (b, c)
    for p in s['patterns']:
        for c, ch in enumerate(p['ch']): addev(c, ch['events'])
    for m in s['macros']: addev(m['ch'], m['events'])
    for a in sorted(ev):
        b, c = ev[a]
        items.append((a, len(b), [event_line(b, c, bank, s)]))
    items.sort()
    # contiguity check
    pos = st
    for a, n, _ in items:
        if a != pos: raise SystemExit('gap/overlap in song %d at %X (expected %X)' % (s['num'], a, pos))
        pos += n
    return items, L, pos

def event_line(b, c, bank, s):
    k = b[0]
    if k == 0: return '\tnote_off'
    if k < 0x80:
        if c == 3: return '\tnoise%s %d' % ('7' if k & 0x40 else '', k & 0x3F)
        if k <= 0x48: return '\tnote %s' % notesym(k)
        return '\tempty_row $%02X' % k
    if k < 0xC0: return '\twait %d' % (k & 0x3F)
    if k == 0xD3:
        tgt = s['pt'] + (b[1] | b[2] << 8)
        return '\tcall_macro %s_Macro_%04X' % ('Song%02d' % s['num'], tgt)
    if k not in CMDMAC: return '\tdb $%02X ; no-op command' % k
    if k == 0xDF: return '\tporta_src %s' % notesym(b[1])
    args = ', '.join('$%02X' % x for x in b[1:])
    return ('\t%s %s' % (CMDMAC[k], args)).rstrip()

def emit_song_bank(out, bank, start, end, songs):
    out.append('')
    out.append('SECTION "Songs bank $%02X", ROMX[$%04X], BANK[$%02X]' % (bank, start, bank))
    pos = start
    for s in sorted(songs, key=lambda x: x['start']):
        if s['start'] != pos: raise SystemExit('bank %X song gap' % bank)
        lbl = 'Song%02d' % s['num']
        items, L, endpos = song_items(s, lbl)
        out.append('')
        out.append('; ===========================================================================')
        out.append('; Song %d "%s"  (%02X:%04X-%04X, %d patterns)' % (s['num'], s['name'].strip(), bank, s['start'], endpos-1, s['npat']))
        out.append('; ===========================================================================')
        for a, n, lines in items:
            for l in L.get(a, []): out.append(l + ':')
            out.extend(lines)
        out.append(lbl + '_End:')
        pos = endpos
    if pos < end:
        out.append('')
        out.append('\tds $%04X - @, $FF      ; unused ($FF) to end of bank' % end)

def main():
    songs = [FP.parse_song(i) for i in range(FP.NSONGS)]
    out = []
    P = out.append
    P(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'asm_header.inc')).read().rstrip('\n'))
    # bank 0
    P('')
    P('SECTION "Sound API (bank 0)", ROM0[$05B2]')
    emit_code(out, 0, *CODE[0])
    P('')
    P('SECTION "Sound far-call wrappers (bank 0)", ROM0[$0649]')
    emit_code(out, 0, *CODE0B)
    # bank 9
    P('')
    P('SECTION "Sound driver (bank 9)", ROMX[$4000], BANK[9]')
    emit_bank9_tables(out)
    emit_code(out, 9, *CODE[9])
    P('')
    P('; SongPtrTable / SongBankTable: 20 songs, indexed by wSongNum.')
    P('SongPtrTable:')
    for i in range(20): P('\tdw Song%02d' % i)
    P('SongBankTable:')
    for i in range(20): P('\tdb BANK(Song%02d)' % i)
    # songs in bank 9 continue in same section
    b9 = [s for s in songs if s['bank'] == 9]
    pos = 0x74BC
    for s in sorted(b9, key=lambda x: x['start']):
        lbl = 'Song%02d' % s['num']
        items, L, endpos = song_items(s, lbl)
        P(''); P('; ===========================================================================')
        P('; Song %d "%s"  (09:%04X-%04X, %d patterns)' % (s['num'], s['name'].strip(), s['start'], endpos-1, s['npat']))
        P('; ===========================================================================')
        for a, n, lines in items:
            for l in L.get(a, []): P(l + ':')
            out.extend(lines)
        P(lbl + '_End:')
    P('')
    P('\tds $8000 - @, $FF      ; unused ($FF) to end of bank')
    # bank A
    P('')
    P('SECTION "Period table (bank $0A)", ROMX[$4000], BANK[$0A]')
    P('; PeriodTable: GB period for every even pitch value $4000-$647E (pitch = $4000 + note*$80')
    P('; + transposes + vibrato + fine tune; 64 entries per semitone). Note 1 = C2.')
    P('PeriodTable:')
    for r in range(0x2480 // 16):
        a = 0x4000 + r*16
        line = dw_line([rw(0x0A, a + 2*i) for i in range(8)])
        n = (a - 0x4000) // 0x80
        if (a - 0x4000) % 0x80 == 0: line += ' ; note %d%s' % (n, ' (%s)' % notesym(n) if n else '')
        P(line)
    sA = [s for s in songs if s['bank'] == 0x0A]
    emit_song_bank_inline(out, 0x0A, 0x6480, sA)
    for bank, start in [(0x0B, 0x4000), (0x0C, 0x4000), (0x0D, 0x4000), (0x0E, 0x4000), (0x0F, 0x6990)]:
        emit_song_bank(out, bank, start, 0x8000, [s for s in songs if s['bank'] == bank])
    print('\n'.join(out))

def emit_song_bank_inline(out, bank, start, songs):
    pos = start
    for s in sorted(songs, key=lambda x: x['start']):
        lbl = 'Song%02d' % s['num']
        items, L, endpos = song_items(s, lbl)
        out.append(''); out.append('; ===========================================================================')
        out.append('; Song %d "%s"  (%02X:%04X-%04X, %d patterns)' % (s['num'], s['name'].strip(), bank, s['start'], endpos-1, s['npat']))
        out.append('; ===========================================================================')
        for a, n, lines in items:
            for l in L.get(a, []): out.append(l + ':')
            out.extend(lines)
        out.append(lbl + '_End:')
    out.append('')
    out.append('\tds $8000 - @, $FF      ; unused ($FF) to end of bank')

if __name__ == '__main__': main()
