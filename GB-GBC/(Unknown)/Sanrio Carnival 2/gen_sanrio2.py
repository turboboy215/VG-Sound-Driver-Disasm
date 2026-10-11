"""Generate the Sanrio Carnival 2 (J) sound sources: bank $01 $6000-$7FFF.

  $6000-$69EE  driver code (init / update stubs, SFX interpreter, music player, commands)
  $69EF-$6AD8  note frequency table, SFX pointer tables
  $6AD9-$6CFF  SFX streams (+ zero fill)
  $6D00-$6E31  macro page: envelope / pitch / drum macros, drum table, waves, length tables; song table
  $6E32-$7BE4  music streams ($7BE5- $FF fill)
"""
import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, '..', 'tools'))
from gbdis import Region
from s2_streams import MusicWalk, sfx_tables, sfx_parse, OPS, SONG_TABLE, NSONGS

ROM = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', 'Sanrio Carnival 2 (J).gb')
OUT = sys.argv[2] if len(sys.argv) > 2 else HERE
rom = open(ROM, 'rb').read()
def w(name, body): open(os.path.join(OUT, name), 'w').write(body)

# ---------------------------------------------------------------- RAM
RAM = {
 0xde00: 'wSongRequest', 0xde01: 'wSfxRequest1', 0xde02: 'wSfxRequest2', 0xde03: 'wSfxRequest3', 0xde04: 'wSfxRequest4',
 0xde05: 'wSfxPending1', 0xde06: 'wSfxPending2', 0xde07: 'wSfxPending3', 0xde08: 'wSfxPending4',
 0xde09: 'wMusicHold', 0xde0a: 'wLengthTable', 0xde0b: 'wLengthTable+1',
 0xde64: 'wShadowCh1', 0xde6a: 'wShadowCh2', 0xde70: 'wShadowCh3', 0xde76: 'wShadowCh4',
 0xde7c: 'wShadowMaster', 0xde7d: 'wShadowNR50', 0xde7e: 'wMusicNR51', 0xde7f: 'wSfxNR51',
 0xde80: 'wWavePtr', 0xde81: 'wWavePtr+1', 0xde82: 'wSfxSlotChannels', 0xde83: 'wSfxChannels',
 0xde84: 'wSfxSlot1', 0xde88: 'wSfxSlot2', 0xde8c: 'wSfxSlot3', 0xde90: 'wSfxSlot4',
}
CHS = ['wMusicCh1', 'wMusicCh2', 'wMusicCh3', 'wMusicCh4']
CHF = ['Ptr', 'Ptr+1', 'Timer', 'Note', 'Length', 'Count']
for c in range(4):
    for i, f in enumerate(CHF): RAM[0xde0c + 6*c + i] = f'{CHS[c]}{f}' if '+' not in f else f'{CHS[c]}Ptr+1'
CPF = ['SfxOwned', 'EnvPtr', 'EnvTimer', 'PitchPtr', 'PitchTimer', 'Reg0', 'Reg1', 'EnvMacro', 'PitchMacro', 'Depth', 'Stack']
for c in range(4):
    for i, f in enumerate(CPF): RAM[0xde24 + 16*c + i] = f'wCh{c+1}{f}'
RAM[0xde5c] = 'wCh4DrumPage'      # ch4's 'PitchMacro' byte holds the page of the drum macro
REGS = [('NR10', 'NR11', 'NR12', 'NR13', 'NR14'), ('NR20', 'NR21', 'NR22', 'NR23', 'NR24'),
        ('NR30', 'NR31', 'NR32', 'NR33', 'NR34'), ('NR40', 'NR41', 'NR42', 'NR43', 'NR44')]
for c in range(4):
    for i, n in enumerate(REGS[c]): RAM[0xde64 + 6*c + 1 + i] = f'wShadow{n}'
for s in range(4):
    for i, f in enumerate(['Ptr', 'Ptr+1', 'Channels', 'Wait']): RAM[0xde84 + 4*s + i] = f'wSfxSlot{s+1}{f}' if '+' not in f else f'wSfxSlot{s+1}Ptr+1'

# ---------------------------------------------------------------- code names / comments
NAMES = {
 0x6000: 'Sound_Init', 0x6003: 'Sound_Update', 0x60be: 'Sound_Reset', 0x60ef: 'Sfx_Update',
 0x61ac: 'Sfx_Slot1', 0x6233: 'Sfx_Slot2', 0x62ba: 'Sfx_Slot3', 0x6341: 'Sfx_Slot4',
 0x63c8: 'Sfx_Silence', 0x6410: 'Sfx_RegsCh1', 0x641c: 'Sfx_RegsCh2', 0x6428: 'Sfx_RegsCh3', 0x6434: 'Sfx_RegsCh4',
 0x643e: 'Sfx_WriteRegs', 0x646a: 'Sfx_SkipRegs',
 0x6480: 'Music_Update', 0x64cf: 'Music_Update.play', 0x64f8: 'Music_Ch1', 0x65e0: 'Music_Ch2', 0x66c5: 'Music_Ch3', 0x67a8: 'Music_Ch4',
 0x6877: 'Macro_Jump', 0x687e: 'Music_Command', 0x688a: 'MusicCommandTable',
 0x68ca: 'Cmd_Wave', 0x68d5: 'Cmd_MasterVolume', 0x68e3: 'Cmd_MusicPan', 0x68f1: 'Cmd_Sweep1', 0x68f7: 'Cmd_Duty1',
 0x68fd: 'Cmd_Duty2', 0x6903: 'Cmd_Length3', 0x6909: 'Cmd_Length4',
 0x690f: 'Cmd_Env1', 0x6915: 'Cmd_Env2', 0x691b: 'Cmd_Env3', 0x6921: 'Cmd_Env4', 0x6927: 'Cmd_Pitch1', 0x692d: 'Cmd_Pitch2', 0x6933: 'Cmd_Pitch3',
 0x6939: 'Cmd_LengthTable', 0x6944: 'Cmd_Jump', 0x694a: 'Cmd_Call1', 0x694f: 'Cmd_Call2', 0x6954: 'Cmd_Call3', 0x6959: 'Cmd_Call4', 0x695c: 'Cmd_Call',
 0x6971: 'Cmd_Return1', 0x6976: 'Cmd_Return2', 0x697b: 'Cmd_Return3', 0x6980: 'Cmd_Return4', 0x6983: 'Cmd_Return',
 0x698f: 'Cmd_End1', 0x69a8: 'Cmd_End2', 0x69c1: 'Cmd_End3', 0x69d6: 'Cmd_End4',
 0x69ef: 'NoteFreqTable', 0x6a99: 'SfxTable1', 0x6aa9: 'SfxTable2', 0x6ab9: 'SfxTable3', 0x6ac9: 'SfxTable4',
}
COMMENTS = {
 0x6000: 'Entry points: init (called from home $018D), update once per frame (home $00D3).',
 0x6003: ('Per frame: SFX, then the music unless an effect holds it (wMusicHold), a pending wave load\n'
          '(wWavePtr high byte <> 0), then the shadow registers are written out. Each channel has a\n'
          'dirty byte: bit 7 = write all registers and trigger, other bits = frequency only.\n'
          'wShadowMaster bit 0 = write NR50, bit 1 = NR51 = wMusicNR51 | wSfxNR51.'),
 0x60be: 'Clear $DE00-$DE81, silence the APU, then NR50 = $77 and music NR51 = $FF (written next frame).',
 0x60ef: ('Four SFX slots, highest priority first. wSfxRequestN is a bit mask of effects (bit 7 = effect 0,\n'
          'the most important); requests collect in wSfxPendingN and the highest pending bit plays: a new\n'
          'request for it starts it, otherwise the running effect continues. An effect\'s end clears every\n'
          'pending bit of its slot. A slot only writes channels a higher slot has not taken this frame.'),
 0x617a: 'wSfxChannels = channels taken by an effect: refresh NR51 when it changed, set the per-channel flags.',
 0x61ac: ('Slot 1. Stream bytes: $00-$3F register writes (Sfx_RegsChN), $40-$5F hold / resume the music,\n'
          '$60-$6F end, $70-$7F new channel set, $80-$FF wait n frames ($80 = 128).'),
 0x63c8: 'End of an effect: silence the channels in a (bits 0-3) that no higher slot owns.',
 0x6410: ('Register writes for one channel: c bits 0-2 = NRx0-NRx2, bit 3 = NRx3 and NRx4. Skipped (with\n'
          'their operands) when a higher slot owns the channel.'),
 0x6480: ('wSongRequest bit 7 clear = a new song: load the four stream pointers (8 bytes per song at\n'
          'SongTable; a $00xx pointer = channel unused and silenced), clear the call stacks.'),
 0x64f8: ('Channel players (one copy per channel). A note byte < $80: pitch*2 -> wMusicChNNote; when the\n'
          'repeat counter runs out, a packed length byte follows: high nibble = index into the length\n'
          'table, low nibble+1 = how many notes use that length. A note restarts the envelope and pitch\n'
          'macros (rest: volume 0). Each frame the envelope macro may give a new NRx2 (retrigger) and the\n'
          'pitch macro an offset; commands $80-$9F go through Music_Command (carry = channel done for\n'
          'this frame).'),
 0x6593: ('Pitch: base = NoteFreqTable entry pitch-1. The offset is the macro value\'s bits 6-0 as a binary\n'
          'fraction of the low byte of the next entry (up) or minus the high byte of the base entry (bit 7\n'
          'set, down). The only pitch macro waits 510 frames before it moves, so this is never heard.'),
 0x67fa: ('Drum: DrumTable entry (macro low byte, page) gives the NR43 macro; the envelope macro comes from\n'
          'Cmd_Env4. Only drums 1 and 2 have entries: drum 3 (used by songs $06 and $07) reads the first\n'
          'bytes of DrumMacro1 as its entry and runs a "macro" at $5E01 in game data (NR43 $F4).'),
 0x6877: 'Macro row with frames = 0: jump to the low byte that follows, read the new frames.',
 0x687e: 'a = command*2 (low byte): jump through MusicCommandTable.',
 0x688a: 'commands $80-$9F; $90-$92 have no handler',
 0x698f: 'Channel end: silence the channel (unless an effect owns it) and stop it (pointer high byte 0).',
 0x69ef: ('85 frequencies, C2-C9 (note 1 = entry 0); the last two are both $07F0. Note n reads entry n-1\n'
          'at NoteFreqTable+2n-2.'),
 0x6a99: 'SFX slot tables: 8 effects each (bit 7 of the request = effect 0). Unused entries -> Sfx_None.',
}

r = Region(rom, 1, 0x6000, 0x8000)
r.ram = dict(RAM)
r.trace([0x6000, 0x6003])
r.jumptable(0x688a, 32)
for a, n in NAMES.items(): r.label(a, n)
for a, t in COMMENTS.items(): r.comments[a] = t

# operands that are table addresses split in two bytes
def ovr(lo, hi, fmt, val, text):
    pcs = [pc for pc in sorted(r.code) if lo <= pc < hi and r.code[pc][1] == fmt and r.code[pc][2][0][1] == val]
    assert len(pcs) == 1, (hex(lo), fmt, pcs)
    r.overrides[pcs[0]] = {0: text}
ovr(0x6480, 0x6499, 'add a, {0}', 0xb2, 'LOW(SongTable)')
ovr(0x6480, 0x6499, 'ld a, {0}', 0x6d, 'HIGH(SongTable)')
ovr(0x687e, 0x688a, 'add a, {0}', 0x8a, 'LOW(MusicCommandTable)')
ovr(0x687e, 0x688a, 'ld a, {0}', 0x68, 'HIGH(MusicCommandTable)')
ovr(0x67fa, 0x6802, 'add a, {0}', 0x36, 'LOW(DrumTable - 2)')
ovr(0x67fa, 0x6802, 'ld a, {0}', 0x6d, 'HIGH(DrumTable - 2)')
for pc in sorted(r.code):
    l, fmt, args, k = r.code[pc]
    if fmt == 'ld d, {0}' and args[0][1] == 0x6d: r.overrides[pc] = {0: 'HIGH(EnvMacro_00)'}

# ---------------------------------------------------------------- data blocks
def hexrows(rr, a, n, per=16):
    return ['\tdb ' + ', '.join(f'${rr.byte(a+i+k):02x}' for k in range(min(per, n-i))) for i in range(0, n, per)]

NOTE_NAMES = ['C_', 'Cs', 'D_', 'Ds', 'E_', 'F_', 'Fs', 'G_', 'Gs', 'A_', 'As', 'B_']
def note_name(n):
    if n == 0: return 'REST'
    k = n - 1
    return f'{NOTE_NAMES[k % 12]}{k // 12 + 2}'

def nt_emit(rr, a):
    out = []
    for i in range(0, 85, 8):
        ws = [rr.word(a + 2*j) for j in range(i, min(i + 8, 85))]
        out.append('\tdw ' + ', '.join(f'${v:04x}' for v in ws) + f'\t; {note_name(i+1)}-')
    return out
r.block(0x69ef, 170, nt_emit)

tabs = sfx_tables(rom)
SFXNAME = {0x6ad9: 'Sfx_None'}
for t, tab in enumerate(tabs):
    for i, s in enumerate(tab):
        SFXNAME.setdefault(s, f'Sfx{t+1}_{i}')
for t, tab in enumerate(tabs):
    r.block(0x6a99 + 16*t, 16, lambda rr, a, tab=tab: ['\tdw ' + ', '.join(SFXNAME[s] for s in tab[:4]),
                                                        '\tdw ' + ', '.join(SFXNAME[s] for s in tab[4:])])

def sfx_lines(start):
    out = []
    for a, kind, bs in sfx_parse(rom, start):
        if kind == 'mask': out.append(f'\tsfx_channels %{bs[0]:04b}')
        elif kind == 'regs':
            c = bs[0]; ch = (c >> 4) + 1; vals = bs[1:]
            names = [n for bit, n in ((1, 0), (2, 1), (4, 2)) if c & bit]
            desc = []; q = 0
            for bit, ri in ((1, 0), (2, 1), (4, 2)):
                if c & bit: desc.append(f'{REGS[ch-1][ri]}=${vals[q]:02x}'); q += 1
            if c & 8:
                if ch == 4: desc.append(f'NR43=${vals[q]:02x} NR44=${vals[q+1]:02x}')
                else: desc.append(f'freq ${(vals[q] | vals[q+1] << 8) & 0x7ff:03x}')
                q += 2
            out.append(f'\tsfx_regs {ch}, %{c & 15:04b}, ' + ', '.join(f'${v:02x}' for v in vals) + '\t; ' + ' '.join(desc))
        elif kind == 'music': out.append(f'\tsfx_music ${bs[0] & 0x1f:02x}' + ('\t; hold the music' if bs[0] & 1 else '\t; resume the music'))
        elif kind == 'end': out.append(f'\tsfx_end %{bs[0] & 15:04b}')
        elif kind == 'chmask': out.append(f'\tsfx_take %{bs[0] & 15:04b}')
        elif kind == 'wait': out.append(f'\tsfx_wait {(bs[0] & 0x7f) or 128}')
    return out, a + len(bs)

starts = sorted(set(sum(tabs, [])))
for s in starts:
    lines, e = sfx_lines(s)
    users = [f'slot {t+1} effect {i}' for t, tab in enumerate(tabs) for i, x in enumerate(tab) if x == s]
    r.label(s, SFXNAME[s], ', '.join(users) if s != 0x6ad9 else 'every unused table entry')
    r.block(s, e - s, lambda rr, a, lines=lines: lines)

# macro page $6D00-$6DB1

def mrows(a, e, loop_names=None):
    out = []; q = a
    while q < e:
        if rom[q] == 0: out.append(f'\tmloop {loop_names[rom[q+1]]}'); q += 2
        else: out.append(f'\tmrow ${rom[q]:02x}, ${rom[q+1]:02x}'); q += 2
    return out
MAC = [(0x6d00, 0x6d08, 'EnvMacro_00', 'envelope macros (frames, NRx2; NRx2 0 = no change). Rows of $FF frames\nrun on into the next macro, but they last 255 frames per note. ch1/ch2'),
       (0x6d08, 0x6d0e, 'EnvMacro_08', 'ch1/ch2'), (0x6d0e, 0x6d14, 'EnvMacro_0E', 'ch1/ch2'), (0x6d14, 0x6d18, 'EnvMacro_14', 'ch2'),
       (0x6d18, 0x6d1a, 'EnvMacro_18', 'ch3: frames, NR32'), (0x6d1a, 0x6d1e, 'EnvMacro_1A', 'ch3'), (0x6d1e, 0x6d24, 'EnvMacro_1E', 'ch3'),
       (0x6d24, 0x6d28, 'EnvMacro_24', 'ch4'), (0x6d28, 0x6d2c, 'EnvMacro_28', 'ch4'),
       (0x6d2c, 0x6d32, 'PitchMacro_2C', 'pitch macro (frames, offset), the only one: 510 frames flat, then alternates $80 / $90'),
       (0x6d32, 0x6d38, 'PitchMacro_2C.vibrato', None)]
loopn = {0x32: 'PitchMacro_2C.vibrato', 0x3e: 'DrumMacro1.hold', 0x44: 'DrumMacro2.hold', 0x48: 'DrumMacro3_Unused'}
for a, e, n, c in MAC:
    r.label(a, n, c)
    r.block(a, e - a, lambda rr, a, e=e: mrows(a, e, loopn))
r.label(0x6d38, 'DrumTable', 'drums 1-2: macro low byte, page (the code reads DrumTable-2 + 2*drum)')
r.block(0x6d38, 4, lambda rr, a: ['\tdb LOW(DrumMacro1), HIGH(DrumMacro1)', '\tdb LOW(DrumMacro2), HIGH(DrumMacro2)'])
for a, e, n, c in [(0x6d3c, 0x6d3e, 'DrumMacro1', 'drum macros: frames, NR43'), (0x6d3e, 0x6d42, 'DrumMacro1.hold', None),
                   (0x6d42, 0x6d44, 'DrumMacro2', None), (0x6d44, 0x6d48, 'DrumMacro2.hold', None),
                   (0x6d48, 0x6d4e, 'DrumMacro3_Unused', 'not in DrumTable')]:
    r.label(a, n, c); r.block(a, e - a, lambda rr, a, e=e: mrows(a, e, loopn))
for i, a in enumerate((0x6d4e, 0x6d5e, 0x6d6e)):
    r.label(a, f'Wave{i+1}', 'waves (Cmd_Wave)' if i == 0 else None)
    r.block(a, 16, lambda rr, a: hexrows(rr, a, 16))
for i, a in enumerate((0x6d7e, 0x6d8b, 0x6d98, 0x6da5)):
    r.label(a, f'LengthTable{i+1}', 'length tables, frames (Cmd_LengthTable); packed length bytes use index 0-12' if i == 0 else None)
    r.block(a, 13, lambda rr, a: ['\tdb ' + ', '.join(str(rr.byte(a+k)) for k in range(13))])
WAVE = {0x6d4e: 'Wave1', 0x6d5e: 'Wave2', 0x6d6e: 'Wave3'}
LT = {0x6d7e: 'LengthTable1', 0x6d8b: 'LengthTable2', 0x6d98: 'LengthTable3', 0x6da5: 'LengthTable4'}
ENVN = {a & 0xff: n for a, e, n, c in MAC if n.startswith('Env')}

# ---------------------------------------------------------------- music
m = MusicWalk(rom).run()
SNAME = {}
for s, ptrs in enumerate(m.songs):
    for c, p in enumerate(ptrs):
        if p >> 8 and p not in SNAME: SNAME[p] = f'Song{s:02X}_Ch{c+1}'
cnt = {}
for t in sorted(m.targets):
    if t in SNAME: continue
    s, c = m.owner[t]
    kind = 'Loop' if 'jump' in m.targets[t] and 'call' not in m.targets[t] else 'Sub'
    base = f'Song{s:02X}_Ch{c+1}_{kind}'
    cnt[base] = cnt.get(base, 0) + 1
    SNAME[t] = base + (str(cnt[base]) if cnt[base] > 1 or True else '')
# tidy: a single Loop/Sub per channel drops the number
for base, n in cnt.items():
    if n == 1:
        for t, v in SNAME.items():
            if v == base + '1': SNAME[t] = base

r.label(SONG_TABLE, 'SongTable', 'songs $00-$0F: ch1-ch4 streams (0 = channel unused); $00, $0E, $0F are silence.\n$0A, $0B, $0D start songs $02, $03, $01 at their loop (no intro; $0A and $0B with a faster\nlength table), $0C = jingle $04 followed by song $05')
def songtab(rr, a):
    out = []
    for s, ptrs in enumerate(m.songs):
        out.append('\tdw ' + ', '.join(SNAME[p] if p >> 8 else '0' for p in ptrs) + f'\t; ${s:02X}')
    return out
r.block(SONG_TABLE, 8 * NSONGS, songtab)

def stream_lines(a, e):
    out = []; q = a
    while q < e:
        rl = m.role[q]; c = rom[q]
        ch = min(m.chan_of[q])
        if rl == 'note':
            nm = note_name(c) if ch < 3 else (str(c) if c else 'REST')
            if q + 1 < e and m.role.get(q + 1) == 'len':
                l = rom[q+1]; out.append(f'\tnote {nm}, {l >> 4}, {(l & 15) + 1}'); q += 2
            else:
                out.append(f'\tnote {nm}'); q += 1
            continue
        assert rl == 'cmd', hex(q)
        n = OPS[c]; ops = rom[q+1:q+1+n]; v = ops[0] | ops[1] << 8 if n == 2 else (ops[0] if n else None)
        if c == 0x80: t = f'wave {WAVE[v]}'
        elif c == 0x81: t = f'master_vol ${v:02x}'
        elif c == 0x82: t = f'music_pan ${v:02x}'
        elif c == 0x83: t = f'sweep1 ${v:02x}'
        elif c == 0x84: t = f'duty1 ${v:02x}'
        elif c == 0x85: t = f'duty2 ${v:02x}'
        elif c == 0x86: t = f'len3 ${v:02x}'
        elif c == 0x87: t = f'len4 ${v:02x}'
        elif c <= 0x8b: t = f'env {c - 0x87}, {ENVN[v]}'
        elif c <= 0x8e: t = f'pitch {c - 0x8b}, PitchMacro_2C' if v == 0x2c else None
        elif c == 0x8f: t = f'lengths {LT[v]}'
        elif c == 0x93: t = f'jump {SNAME[v]}'
        elif c <= 0x97: t = f'gosub {c - 0x93}, {SNAME[v]}'
        elif c <= 0x9b: t = f'endsub {c - 0x97}'
        else: t = f'endch {c - 0x9b}'
        out.append('\t' + t); q += 1 + n
    return out

lo, hi = 0x6e32, 0x7be5
cuts = sorted(set([lo, hi] + [t for t in m.targets if lo <= t < hi]))
for a, e in zip(cuts, cuts[1:]):
    r.label(a, SNAME[a])
    r.block(a, e - a, lambda rr, a, e=e: stream_lines(a, e))

# fills
r.block(0x6c9a, 0x6d00 - 0x6c9a, lambda rr, a: [f'\tds ${0x6d00 - 0x6c9a:02x}, $00'])
r.block(0x7be5, 0x8000 - 0x7be5, lambda rr, a: [f'\tds ${0x8000 - 0x7be5:03x}, $ff'])

# coverage check
cov = set()
for pc, d in r.code.items(): cov.update(range(pc, pc + d[0]))
for b, (s, e) in r.blocks.items(): cov.update(range(b, b + s))
miss = [a for a in range(0x6000, 0x8000) if a not in cov]
print('unclaimed', len(miss), [hex(a) for a in miss[:20]])

def local_names(r):
    cnt = {}; parent = None
    for a in sorted(r.labels):
        n = r.labels[a]
        if n.startswith('Code_') and parent:
            cnt[parent] = cnt.get(parent, -1) + 1
            r.labels[a] = f'{parent}.l{cnt[parent]}'
        elif '.' not in n and a in r.code:
            parent = n
        elif a not in r.code:
            parent = None
r._emit(r.start, r.end)
local_names(r)

SPLITS = [(0x6000, 0x69ef, 'S2_Driver.inc', 'driver code'), (0x69ef, 0x6ad9, 'S2_Tables.inc', 'note table, SFX tables'),
          (0x6ad9, 0x6d00, 'S2_Sfx.inc', 'SFX streams'), (0x6d00, 0x6e32, 'S2_Data.inc', 'macros, drums, waves, length tables, song table'),
          (0x6e32, 0x8000, 'S2_Songs.inc', 'music streams')]
parts = r.emit_split([(a, b) for a, b, _, _ in SPLITS])
for (a, b, f, what), body in zip(SPLITS, parts):
    w(f, f'; Sanrio Carnival 2 sound, bank $01: {what}, ${a:04X}-${b-1:04X}\n\n' + body)
w('S2_Sound.asm', '; Sanrio Carnival 2 (J): sound driver and data, bank $01 $6000-$7FFF\n'
  'INCLUDE "GB_Hardware.inc"\nINCLUDE "S2_RAM.inc"\nINCLUDE "S2_Macros.inc"\n\n'
  'SECTION "Sanrio Carnival 2 sound", ROMX[$6000], BANK[1]\n' +
  ''.join(f'\tASSERT @ == ${a:04X}\nINCLUDE "{f}"\n' for a, b, f, _ in SPLITS) + '\tASSERT @ == $8000\n')

lines = ['; Sanrio Carnival 2 sound RAM ($DE00-$DE93)', 'IF !DEF(S2_RAM_INC)', 'DEF S2_RAM_INC EQU 1']
for a in sorted(RAM):
    if '+' not in RAM[a]: lines.append(f'DEF {RAM[a]:<22} EQU ${a:04X}')
lines.append('ENDC')
w('S2_RAM.inc', '\n'.join(lines) + '\n')

print('ok')
