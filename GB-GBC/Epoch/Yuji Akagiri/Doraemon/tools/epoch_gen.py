"""Generates byte-exact RGBDS disassemblies of the Epoch sound driver
(Doraemon (J) bank 7, Dragon Slayer I (J) bank 0) with no macros.

usage: python3 epoch_gen.py dora|ds  > file.asm
"""
import re
import sys
sys.path.insert(0, __file__.rsplit('/', 1)[0])
import sm83
from epoch_cfg import load
from epoch_parse import parse, note_name
from epoch_align import amap, code_ranges

KEY = sys.argv[1]
g = load(KEY)
V2 = g['ver'] == 2
B, W = g['b'], g['w']
R = parse(g)
DSMAP = amap()                       # DS addr -> Doraemon addr
S = g['struct']
RAM = g['ram']

# ---------------------------------------------------------------- RAM names
TRACKS = ['wSndCh1', 'wSndCh2', 'wSndCh3', 'wSndCh4', 'wSndSfxCh1', 'wSndSfxCh4']
FIELDS = {0: 'TRK_STATUS', 1: 'TRK_PTR', 3: 'TRK_COUNT', 5: 'TRK_NOTE',
          6: 'TRK_NR0', 7: 'TRK_NR1', 8: 'TRK_NR2', 9: 'TRK_NR3', 0xA: 'TRK_NR4',
          0xB: 'TRK_ENVMODE', 0xC: 'TRK_ENVPARAM', 0xD: 'TRK_ENVCOUNT',
          0xE: 'TRK_ENVPTR', 0x10: 'TRK_ENVINDEX', 0x11: 'TRK_LOOPDEPTH',
          0x12: 'TRK_LOOPSTACK'}
if V2:
    FIELDS[0x1E] = 'TRK_START'
TRK_BASE = RAM + 9
CMDBYTE = TRK_BASE + 6 * S
RAMNAMES = {RAM + 0: 'wSndMusicId', RAM + 1: 'wSndSfxId', RAM + 2: 'wSndMusicTracks',
            RAM + 3: 'wSndSfxTracks', RAM + 4: 'wSndMusicTempo', RAM + 5: 'wSndSfxTempo',
            RAM + 6: 'wSndPan', RAM + 7: 'wSndPanFlag', RAM + 8: 'wSndTrackIndex',
            CMDBYTE: 'wSndRowByte', CMDBYTE + 8: 'wSndMusicLengths',
            CMDBYTE + 10: 'wSndSfxLengths'}

HW = {0xFF10: 'rNR10', 0xFF11: 'rNR11', 0xFF12: 'rNR12', 0xFF13: 'rNR13', 0xFF14: 'rNR14',
      0xFF16: 'rNR21', 0xFF17: 'rNR22', 0xFF18: 'rNR23', 0xFF19: 'rNR24',
      0xFF1A: 'rNR30', 0xFF1B: 'rNR31', 0xFF1C: 'rNR32', 0xFF1D: 'rNR33', 0xFF1E: 'rNR34',
      0xFF20: 'rNR41', 0xFF21: 'rNR42', 0xFF22: 'rNR43', 0xFF23: 'rNR44',
      0xFF24: 'rNR50', 0xFF25: 'rNR51', 0xFF26: 'rNR52'}


def ramsym(a):
    if a in RAMNAMES:
        return RAMNAMES[a]
    if a - 1 in RAMNAMES and RAMNAMES[a - 1] in ('wSndMusicLengths', 'wSndSfxLengths'):
        return RAMNAMES[a - 1] + ' + 1'
    if TRK_BASE <= a < TRK_BASE + 6 * S:
        t, o = divmod(a - TRK_BASE, S)
        f = max(k for k in FIELDS if k <= o)
        s = f'{TRACKS[t]} + {FIELDS[f]}'
        if o - f:
            s += f' + {o - f}'
        return s if o else TRACKS[t]
    return None


# ---------------------------------------------------------------- code labels
def X(ds_addr):
    """DS address -> this game's address."""
    return ds_addr if V2 else DSMAP.get(ds_addr)


GLOBALS_DS = {
    0x7038: 'Sound_Update', 0x703B: 'Sound_Output', 0x703E: 'Sound_Init',
    0x7041: 'Sound_PlayMusic', 0x7044: 'Sound_PlaySfx', 0x7047: 'Sound_StopMusic',
    0x704A: 'Sound_StopSfx', 0x704D: 'SndInit', 0x706B: 'SndLoadWave',
    0x7079: 'SndWave', 0x7089: 'SndPlayMusic', 0x70EF: 'SndPlaySfx',
    0x7155: 'SndStopMusic', 0x7167: 'SndStopSfx', 0x7175: 'SndUpdate',
    0x7189: 'SndTrackLoop', 0x71AF: 'SndParse', 0x722A: 'SndParseRow',
    0x735E: 'SndParseCmd', 0x7423: 'SndTrackEnvelope', 0x74A3: 'SndNextTrack',
    0x74B5: 'SndOutput', 0x75F9: 'SndOutputWithSfx',
}
LOCALS_DS = {
    0x71B5: 'instrument', 0x71F9: 'notMode1', 0x7203: 'gateMode', 0x7225: 'instDone',
    0x7240: 'tableLength', 0x726C: 'addLength', 0x728F: 'notTie', 0x729B: 'relative',
    0x72A2: 'setNote', 0x72AF: 'toneNote', 0x72EE: 'notMode1', 0x72F5: 'gate',
    0x730E: 'rest', 0x7313: 'drumMusic', 0x7327: 'drumSfx', 0x7339: 'copyDrum',
    0x7344: 'keyOn', 0x7346: 'setStatus', 0x7349: 'savePtr',
    0x736C: 'restart', 0x7380: 'notEnd', 0x73A3: 'notLoopStart', 0x73C4: 'exitLoop',
    0x73C5: 'popLoop', 0x73D0: 'notLoopEnd', 0x73E6: 'scan', 0x73F3: 'scanNotPass',
    0x73FE: 'scanRow', 0x7404: 'scanNoteByte', 0x740D: 'found', 0x7415: 'pan',
    0x7460: 'notVolSteps', 0x746F: 'gateCount', 0x748E: 'retrigger', 0x7490: 'store',
    0x74A4: 'noPop',
    0x74CD: 'ch1', 0x74F7: 'ch1Release', 0x7505: 'ch1Write', 0x7518: 'ch2',
    0x7542: 'ch2Release', 0x7550: 'ch2Write', 0x7560: 'ch3', 0x7586: 'ch3Release',
    0x758C: 'ch3Write', 0x75A8: 'ch3Legato', 0x75B4: 'ch4', 0x75DB: 'ch4Release',
    0x75E8: 'ch4Write',
    0x760C: 'musCh1', 0x761D: 'musCh1End', 0x762F: 'sfxCh1', 0x765E: 'sfxCh1Release',
    0x766C: 'sfxCh1Write', 0x767F: 'ch2', 0x76A9: 'ch2Release', 0x76B7: 'ch2Write',
    0x76C7: 'ch3', 0x76ED: 'ch3Release', 0x76F3: 'ch3Write', 0x770F: 'ch3Legato',
    0x771B: 'musCh4', 0x772C: 'musCh4End', 0x773E: 'sfxCh4', 0x776A: 'sfxCh4Release',
    0x7777: 'sfxCh4Write', 0x70E0: 'noTrack', 0x7141: 'noTrack', 0x714F: 'done',
    0x70B8: 'trackLoop', 0x7118: 'trackLoop', 0x7181: 'go',
}
# Doraemon-only labels (code that has no DS counterpart)
LOCALS_DORA = {0x40A2: 'noTrack', 0x40F9: 'noTrack', 0x435F: 'loopAgain'}

# ---------------------------------------------------------------- comments
# block comments (before the line) and end-of-line comments, keyed by DS address
BLOCK = {
 0x7038: ['Entry points (jump table at the start of the driver).',
          'The game calls Sound_Output, then Sound_Update, once per frame.'],
 0x704D: ['SndInit: APU on, master volume max, all channels on both sides,',
          'loads the fixed wave and stops everything.'],
 0x706B: ['Copies the 16-byte SndWave into wave RAM. This is the only wave the',
          'driver ever uses.'],
 0x7089: ['SndPlayMusic: a = music id.',
          'Header: tempo (1 byte), length table (word), then 4 track pointers',
          '(ch1, ch2, ch3, ch4). A null pointer means the channel is unused.'],
 0x70EF: ['SndPlaySfx: a = SFX id.',
          'Header: tempo, length table, then 2 track pointers. The first runs on',
          'hardware ch1 (tone), the second on ch4 (noise).'],
 0x7155: ['SndStopMusic: marks all 4 music tracks "ending" (status 4). The next',
          'SndOutput silences them.'],
 0x7167: ['SndStopSfx: same for the 2 SFX tracks.'],
 0x7175: ['SndUpdate: the sequencer tick. Runs the 6 tracks in order',
          '(music ch1-ch4, SFX ch1, SFX ch4).',
          'Each track: counter -= tempo. While it has not underflowed, only the',
          'instrument envelope runs. When it underflows, rows are parsed until',
          'the next note/rest/tie.'],
 0x7189: ['hl = track struct'],
 0x71AF: ['de = data pointer, hl = TRK_NOTE, track struct on the stack.'],
 0x71B5: ['$F0 nn: instrument. Ignored on noise tracks (ch4 / SFX ch4).',
          'Copies 5 register bytes to TRK_NR0..TRK_NR4 and the mode byte,',
          'then mode-specific parameters.'],
 0x71E4: ['mode 1: volume steps. TRK_ENVPARAM = TRK_ENVCOUNT = rate,',
          'TRK_ENVPTR = address of the step list, TRK_ENVINDEX = 0.'],
 0x71F9: ['mode 2: TRK_ENVPARAM = TRK_ENVCOUNT = frames (broken, see SndTrackEnvelope)'],
 0x7203: ['mode 3 and up: TRK_ENVPARAM = n * current tempo (gate, in counter units).'],
 0x722A: ['Row byte < $E0: hi nibble = length, lo nibble = pitch.',
          'hi nibble 0-C: length = lengths[hi] (song length table).',
          'hi nibble D:   length = next 2 bytes (little-endian).'],
 0x726C: ['counter += length * 8'],
 0x7280: ['lo nibble: 9 = tie (keep sounding, status unchanged), 8 = rest,',
          '6 = absolute note in the next byte, 0-5/7 = note + n, A-F = note - (16-n).'],
 0x72AF: ['tone channels: frequency = FreqTable[note - $10]. Only the low 3 bits',
          'of TRK_NR4 are replaced, so the instrument keeps its trigger/length bits.'],
 0x72CA: ['note start for the instrument mode'],
 0x72D3: ['mode 1: restart the step counter and load step 0 as NRx2 volume'],
 0x72F5: ['mode 3: TRK_ENVPTR (used as a word here) = counter - gate.'],
 0x730E: ['rest: status 5 = release'],
 0x7313: ['noise tracks: NR41-NR44 from DrumTable[note - $34]'],
 0x7344: ['status 6 = key on (full register write in SndOutput)'],
 0x735E: ['Commands $E0-$FF'],
 0x7380: ['$E0 n: loop start. Pushes a 4-byte frame (pass = 1, n, return address).'],
 0x73A3: ['$E1: loop end. pass += 1; repeat while pass <= n.'],
 0x73D0: ['$E2 p: pass marker (alternate ending). Scans forward from the $E2',
          'itself to the first "$E2 p" whose p equals the current pass, and',
          'continues after it. If that pass is the last one, the loop frame is',
          'dropped (the last ending has no $E1).'],
 0x7415: ['any other command ($E3-$EF, $F1-$FD) xx: NR51 = xx (global pan),',
          'written by the next SndOutput.'],
 0x7423: ['No new row this tick: run the instrument envelope (only while a',
          'note is sounding, status 2).'],
 0x7437: ['mode 1: every TRK_ENVPARAM frames, the next volume step goes to the',
          'NRx2 high nibble and the note is retriggered (status 6).'],
 0x7460: ['mode 2: decrements the counter, but "dec" leaves carry clear after the',
          '"cp $02", so "jp nc" is always taken and the note is never released.'],
 0x746F: ['mode 3: gate countdown -= tempo; on underflow, release (status 5).',
          'This cuts the note about n frames before its row ends.'],
 0x74B5: ['SndOutput: writes the registers decided by the last SndUpdate.',
          'Status after SndUpdate: 6 = key on, 5 = release, 4 = ending.',
          'Each is reduced by 4 here (2 = sounding, 1 = released, 0 = off).'],
 0x74F7: ['release: NRx2 keeps only its low nibble (volume 0) + retrigger'],
 0x74DF: ['ending: silence the channel, one track fewer; at 0 the song is over'],
 0x758C: ['ch3 key on: if ch3 is already running only the frequency is updated',
          '(no retrigger). Otherwise NR31-NR34 are written with NR30 = $80.'],
 0x75F9: ['Same as SndOutput while an SFX runs. Music ch1/ch4 are held at',
          'status 1 (parsed but not written); hardware ch1/ch4 play the SFX.',
          'On the first frame NR51 gets $99 ORed in so ch1/ch4 are audible.'],
 0x7652: ['SFX over: restore the music NR51 on the next SndOutput'],
}
EOL = {
 0x7038: 'once per frame, after SndOutput', 0x703B: 'once per frame',
 0x703E: 'boot', 0x7041: 'a = music id', 0x7044: 'a = SFX id',
 0x7047: '', 0x704A: '',
 0x70A0: 'dead load', 0x70A2: 'active music tracks',
 0x70B8: 'TRK_STATUS = 1',
 0x70BB: 'TRK_PTR', 0x70C5: 'TRK_COUNT = 0', 0x70CB: 'TRK_LOOPDEPTH = 0',
 0x70D2: '', 0x70D6: 'TRK_START = TRK_PTR' if V2 else '',
 0x70C0: 'reads the high byte and steps back, so the pointer can be re-read for TRK_START' if V2 else '',
 0x7118: 'TRK_STATUS = 1', 0x711B: 'TRK_PTR', 0x7125: 'TRK_COUNT = 0', 0x712B: 'TRK_LOOPDEPTH = 0',
 0x7136: 'TRK_START = TRK_PTR' if V2 else '',
 0x714F: '2 = SFX just started (SndUpdate turns it into 1)', 0x70E4: 'status 4: silenced and counted down by SndOutput',
 0x7175: '2 = SFX just started', 0x7198: 'tracks 4/5 are SFX',
 0x71C8: 'noise tracks ignore instruments',
 0x728C: 'tie: only the pointer is saved',
 0x7353: '', 0x7365: '$FF: end of track',
}
if V2:
    BLOCK[0x736C] = ['$FE: restart the track from its first byte (TRK_START), loop depth 0']
BLOCK_DORA = {
    0x4359: ['n = 0: loop forever (Doraemon only)'],
}
EOL_DORA = {}

# ---------------------------------------------------------------- data objects
labels = {}            # rom addr -> label (global)
objs = {}              # addr -> (kind, info)


def setlab(a, name):
    if a not in labels:
        labels[a] = name


setlab(g['freq'], 'FreqTable')
setlab(g['inst'], 'InstTable')
setlab(g['drum'], 'DrumTable')
setlab(g['music'], 'MusicTable')
setlab(g['sfx'], 'SfxTable')
for i, p in enumerate(R['inst_ptrs']):
    if p:
        setlab(p, f'Inst{i:02X}')
inst_of_trk = {}
for kind, tab, nm in (('music', R['music'], 'Music'), ('sfx', R['sfx'], 'Sfx')):
    for i, p in enumerate(tab):
        setlab(p, f'{nm}{i:02X}')
    for p, (t, lt, ch) in sorted(R[kind + '_hdrs'].items()):
        base = labels[p]
        setlab(lt, base + '_Lengths')
        objs[p] = ('hdr', kind)
        objs[lt] = ('len', (kind, t))
        names = ['Ch1', 'Ch2', 'Ch3', 'Ch4'] if kind == 'music' else ['Ch1', 'Ch4']
        for j, c in enumerate(ch):
            if c:
                setlab(c, f'{base}_{names[j]}')
                noise = names[j] == 'Ch4'
                objs[c] = ('trk', (kind, noise, t, lt))
objs[g['freq']] = ('freq', None)
objs[g['inst']] = ('insttab', None)
for p in R['insts']:
    objs[p] = ('inst', None)
objs[g['drum']] = ('drum', None)
objs[g['music']] = ('mtab', None)
objs[g['sfx']] = ('stab', None)

# ---------------------------------------------------------------- code
code_labels = {}       # addr -> (name, is_global)
for ds_a, n in GLOBALS_DS.items():
    a = X(ds_a)
    if a:
        code_labels[a] = (n, True)
for ds_a, n in LOCALS_DS.items():
    a = X(ds_a)
    if a and a not in code_labels:
        code_labels[a] = (n, False)
if not V2:
    for a, n in LOCALS_DORA.items():
        code_labels[a] = (n, False)

ins_list = []
for (s, e) in code_ranges(g):
    pc = s
    while pc < e:
        l, t, k, tg = sm83.ins(g['data'], pc, g['base'])
        ins_list.append((pc, l, t, k, tg))
        if k in ('jr', 'jrc', 'jp', 'jpc', 'call') and tg not in code_labels:
            code_labels[tg] = (f'l{tg:04X}', False)
        pc += l
# parent of each code label
glob_sorted = sorted(a for a, (n, gl) in code_labels.items() if gl)


def parent(a):
    p = None
    for x in glob_sorted:
        if x <= a:
            p = x
    return p


def code_ref(a, here):
    n, gl = code_labels[a]
    if gl:
        return n
    pa, ph = parent(a), parent(here)
    if pa == ph:
        return '.' + n
    return f'{code_labels[pa][0]}.{n}'


def rom_ref(a):
    if a in labels:
        return labels[a]
    if a + 0x20 == g['freq']:
        return 'FreqTable - $20'
    return None


def render(pc, t, k, tg):
    if k in ('jr', 'jrc', 'jp', 'jpc', 'call') and tg is not None:
        return re.sub(r'\$[0-9A-F]{4}$', code_ref(tg, pc), t)

    def rep(m):
        v = int(m.group(1), 16)
        if v in HW:
            return HW[v]
        r = ramsym(v)
        if r:
            return r
        r = rom_ref(v)
        if r:
            return r
        if v in code_labels:
            return code_ref(v, pc)
        return m.group(0)
    t = re.sub(r'\$([0-9A-F]{4})', rep, t)
    t = t.replace('ldh [rNR', 'ldh [rNR').replace('ldh a,[rNR', 'ldh a,[rNR')
    return t


def hb(a, n):
    return ', '.join(f'${x:02X}' for x in g['rd'](a, n))


out = []
P = out.append
title = g['name']
bank = g['bank']
P(f'; Epoch sound driver -- {title}')
P(f'; ROM bank ${bank if bank else 1:02X}, ${g["start"]:04X}-${g["end"]-1:04X}. Assembles byte-identical with RGBDS 1.0.')
P('; Generated by tools/epoch_gen.py. No macros: data is plain db/dw with a')
P('; comment on each row. See Epoch_SoundDriver.md for the format.')
P('')
P('INCLUDE "epoch_sound.inc"')
P('')
P(f'DEF SND_RAM EQU ${RAM:04X}')
P(f'DEF TRK_SIZE EQU ${S:02X}')
P('')
P('; driver RAM')
for a in sorted(RAMNAMES):
    P(f'DEF {RAMNAMES[a]:<17} EQU ${a:04X}')
for i, n in enumerate(TRACKS):
    P(f'DEF {n:<17} EQU ${TRK_BASE + i * S:04X}  ; {"music" if i < 4 else "SFX"} track struct')
P('')
sbank = bank if bank else 1   # 32 KB no-mapper ROM: $4000-$7FFF is bank 1
P(f'SECTION "Epoch sound", ROMX[${g["start"]:04X}], BANK[${sbank:X}]')
P('')

wave_s, wave_e = g['wave']
for (pc, l, t, k, tg) in ins_list:
    ds_pc = pc if V2 else next((d for d, o in DSMAP.items() if o == pc), None)
    if pc == wave_s + (wave_e - wave_s) and False:
        pass
    # wave data sits between the two code ranges
    if pc == wave_e:
        pass
    blk = BLOCK.get(ds_pc) if ds_pc else None
    if not V2 and pc in BLOCK_DORA:
        blk = BLOCK_DORA[pc]
    if pc in code_labels:
        n, gl = code_labels[pc]
        if gl:
            if blk:
                P('')
                for c in blk:
                    P('; ' + c)
            P(f'{n}::' if n.startswith('Sound_') else f'{n}:')
            blk = None
        else:
            if blk:
                for c in blk:
                    P('; ' + c)
                blk = None
            P(f'.{n}')
    if blk:
        for c in blk:
            P('    ; ' + c)
    txt = render(pc, t, k, tg)
    eol = EOL.get(ds_pc) if ds_pc else None
    if not V2 and pc in EOL_DORA:
        eol = EOL_DORA[pc]
    P(f'    {txt:<40}; ${pc:04X}' + (f'  {eol}' if eol else ''))
    if pc + l == wave_s:
        P('')
        P('; the only wave: a fixed, roughly sine-like shape')
        P('SndWave:')
        P(f'    db {hb(wave_s, 8)}')
        P(f'    db {hb(wave_s + 8, 8)}')
        P('')

# ---------------------------------------------------------------- data
dobjs = sorted(objs)
dobjs.append(g['end'])


def frames(v, tempo):
    f = v * 8 / tempo
    return f'{f:g}' if f == int(f) else f'{f:.2f}'


NOTE_TONE = lambda n: note_name(n)


def emit_track(a, end, info):
    kind, noise, tempo, lt = info
    nlen = (min(x for x in dobjs if x > lt) - lt) // 2
    lens = [W(lt + 2 * i) for i in range(nlen)]
    x = a
    cur = None
    depth = 0
    while x < end:
        c = B(x)
        ind = '    ' + '  ' * depth
        if c == 0xFF:
            P(f'{ind}db $FF{"":<18}; end of track'); x += 1; continue
        if c == 0xFE and V2:
            P(f'{ind}db $FE{"":<18}; restart from the first byte'); x += 1; continue
        if c >= 0xE0:
            if c == 0xE1:
                depth = max(0, depth - 1)
                ind = '    ' + '  ' * depth
                P(f'{ind}db $E1{"":<18}; loop end'); x += 1; continue
            p = B(x + 1)
            if c == 0xF0:
                txt = f'instrument {p}' + (' (ignored on noise)' if noise else '')
            elif c == 0xE0:
                txt = f'loop start: {p} passes' if p else ('loop start: forever' if not V2 else 'loop start: 0 = 1 pass')
            elif c == 0xE2:
                txt = f'pass {p} continues here'
            else:
                txt = f'NR51 = ${p:02X}'
            P(f'{ind}db ${c:02X}, ${p:02X}{"":<13}; {txt}')
            if c == 0xE0:
                depth += 1
            x += 2
            continue
        hi, lo = c >> 4, c & 15
        bs = [c]
        if hi == 0xD:
            v = B(x + 1) | B(x + 2) << 8
            bs += [B(x + 1), B(x + 2)]
            ltxt = f'len ${v:X} ({frames(v, tempo)}f)'
        else:
            v = lens[hi] if hi < len(lens) else None
            ltxt = f'L{hi} ({frames(v, tempo)}f)' if v is not None else f'L{hi} (past table!)'
        if lo == 9:
            ptxt = 'tie'
        elif lo == 8:
            ptxt = 'rest'
        else:
            if lo == 6:
                cur = B(x + 1 + (2 if hi == 0xD else 0))
                bs.append(cur)
                rel = ''
            else:
                d = lo if lo < 8 else lo - 16
                cur = (cur + d) & 0xFF
                rel = f'{d:+d} '
            ptxt = rel + (f'drum {cur - 0x34}' if noise else NOTE_TONE(cur))
        body = ', '.join(f'${q:02X}' for q in bs)
        P(f'{ind}db {body:<20}; {ltxt} {ptxt}')
        x += len(bs)
    return


for i, a in enumerate(dobjs[:-1]):
    kind, info = objs[a]
    end = dobjs[i + 1]
    P('')
    if kind == 'freq':
        P('; tone frequencies (GB period values), index 0 = note $10 = C2')
        P('FreqTable:')
        n = (end - a) // 2
        for r in range(0, n, 12):
            ws = [W(a + 2 * j) for j in range(r, min(n, r + 12))]
            P('    dw ' + ', '.join(f'${v:04X}' for v in ws) + f'  ; {note_name(0x10 + r)}..')
        continue
    if kind == 'insttab':
        P('; instrument pointers ($F0 nn), 0 = unused slot')
        P('InstTable:')
        for j, p in enumerate(R['inst_ptrs']):
            P(f'    dw {labels[p] if p else "0":<10}  ; {j}')
        continue
    if kind == 'inst':
        regs, mode, par = R['insts'][a]
        P(f'{labels[a]}:')
        P(f'    db {hb(a, 5)}  ; NRx0..NRx4 (NRx2 = ${regs[2]:02X})')
        if mode == 0:
            P('    db $00                 ; mode 0: plain')
        elif mode == 1:
            P(f'    db $01, ${par[0]:02X}            ; mode 1: next volume step every {par[0]} frames')
            P(f'    db {", ".join(f"${q:02X}" for q in par[1:])}  ; volume steps (NRx2 high nibble)')
        elif mode == 2:
            P(f'    db $02, ${par[0]:02X}            ; mode 2 (broken, never releases)')
        else:
            P(f'    db ${mode:02X}, ${par[0]:02X}            ; mode {mode}: release {par[0]} frames before the next row')
        ln = 6 + (0 if mode == 0 else (1 + g['volsteps'] if mode == 1 else 1))
        if a + ln != end:
            P(f'    db {hb(a + ln, end - a - ln):<22} ; unused (a mode-0 entry needs no parameter)')
        continue
    if kind == 'drum':
        P('; noise "notes" $34+: NR41, NR42, NR43, NR44')
        P('DrumTable:')
        for j in range((end - a) // 4):
            P(f'    db {hb(a + 4 * j, 4)}  ; drum {j} (note ${0x34 + j:02X})')
        continue
    if kind in ('mtab', 'stab'):
        lst = R['music'] if kind == 'mtab' else R['sfx']
        P('; header pointers, indexed by ' + ('music' if kind == 'mtab' else 'SFX') + ' id')
        P(labels[a] + ':')
        for j, p in enumerate(lst):
            P(f'    dw {labels[p]:<10}  ; ${j:02X}')
        continue
    if kind == 'hdr':
        mk = info
        tempo, lt, ch = R[mk + '_hdrs'][a]
        ids = [j for j, p in enumerate(R[mk]) if p == a]
        P(f'; {"music" if mk == "music" else "SFX"} id(s) ' + ', '.join(f'${j:02X}' for j in ids))
        P(f'{labels[a]}:')
        P(f'    db ${tempo:02X}                 ; tempo (counter units per frame)')
        P(f'    dw {labels[lt]}')
        names = ['ch1', 'ch2', 'ch3', 'ch4 (noise)'] if mk == 'music' else ['ch1', 'ch4 (noise)']
        for j, c in enumerate(ch):
            P(f'    dw {labels[c] if c else "0":<16}  ; {names[j]}')
        continue
    if kind == 'len':
        mk, tempo = info
        P(f'{labels[a]}:  ; row length = value * 8 / tempo frames')
        for j in range((end - a) // 2):
            v = W(a + 2 * j)
            P(f'    dw ${v:04X}  ; L{j} = {frames(v, tempo)} frames')
        if (end - a) % 2:
            P(f'    db {hb(end - 1, 1)}')
        continue
    if kind == 'trk':
        P(f'{labels[a]}:')
        emit_track(a, end, info)
        continue

print('\n'.join(out))
