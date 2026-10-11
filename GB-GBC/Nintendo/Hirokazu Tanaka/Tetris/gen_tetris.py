"""Generate the Tetris (GB, V1.1) sound driver sources ($6480-$7FFF of the 32 KB ROM)."""
import sys, os, json, re
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'tools'))
from gbdis import Region
from tanaka import Songs, note_name
ROM = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', 'Tetris (W) (V1.1) [!].gb')
OUT = sys.argv[2] if len(sys.argv) > 2 else HERE
rom = open(ROM, 'rb').read()
r = Region(rom, 1, 0x4000, 0x8000)      # 32 KB ROM: $4000-$7FFF is file offset $4000-$7FFF

# ---------------------------------------------------------------- RAM ($DF70-$DFFF)
RAM = {
 0xdf70: 'wMusicChannel', 0xdf71: 'wSfxId',
 0xdf75: 'wPanTimer', 0xdf76: 'wPanPeriod', 0xdf77: 'wPanToggle', 0xdf78: 'wPanMode', 0xdf79: 'wPanNR51A', 0xdf7a: 'wPanNR51B',
 0xdf7e: 'wPauseTimer', 0xdf7f: 'wPauseRequest',
 0xdf80: 'wTranspose', 0xdf81: 'wLengthTable', 0xdf82: 'wLengthTable+1',
 0xdfe0: 'wSfx1Request', 0xdfe1: 'wSfx1Playing', 0xdfe2: 'wSfx1Timer', 0xdfe3: 'wSfx1Length', 0xdfe4: 'wSfx1Step',
 0xdfe8: 'wSongRequest', 0xdfe9: 'wSongPlaying',
 0xdff0: 'wSfx3Request', 0xdff1: 'wSfx3Playing', 0xdff2: 'wSfx3Timer', 0xdff3: 'wSfx3Length', 0xdff4: 'wSfx3Step',
 0xdff5: 'wSfx3Var', 0xdff6: 'wSfx3Var2',
 0xdff8: 'wSfx4Request', 0xdff9: 'wSfx4Playing', 0xdffa: 'wSfx4Timer', 0xdffb: 'wSfx4Length', 0xdffc: 'wSfx4Step',
 0xffe4: 'hDemoMode',
}
CHF = {0: 'ListPtr', 1: 'ListPtr+1', 2: 'LenCounter', 3: 'Length', 4: 'PatPtr', 5: 'PatPtr+1', 6: 'InstrEnv', 7: 'InstrFlag', 8: 'InstrDuty',
       9: 'Freq', 10: 'Freq+1', 11: 'Rest', 12: 'Unused12', 13: 'Unused13', 14: 'NoteFrames', 15: 'Flags'}
for n in range(4):
    for o, f in CHF.items(): RAM[0xdf90 + 0x10*n + o] = f'wCh{n+1}{f}'
r.ram = RAM

# ---------------------------------------------------------------- code
r.trace([0x7ff0, 0x7ff3])
I1 = r.jumptable(0x6480, 8, 'Sfx1_InitTable'); P1 = r.jumptable(0x6490, 8, 'Sfx1_PlayTable')
I4 = r.jumptable(0x64a0, 4, 'Sfx4_InitTable'); P4 = r.jumptable(0x64a8, 4, 'Sfx4_PlayTable')

N = {
 0x64b0: 'SongTable', 0x64d2: 'Sound_Hook',
 0x64d3: 'Sound_Update', 0x64e8: 'Sound_Update.requests', 0x64fa: 'Sound_Update.run', 0x650f: 'Sound_Update.clearRequests',
 0x6524: 'Sound_Pause', 0x6550: 'Sound_Pause.jingleA', 0x6553: 'Sound_Pause.writeJingle', 0x6558: 'Sound_Pause.jingleB',
 0x655d: 'Sound_Unpause', 0x6563: 'Sound_Paused', 0x657b: 'PauseJingleA', 0x657f: 'PauseJingleB',
 0x6583: 'Sfx3_Is01', 0x6589: 'Sfx1_Is05', 0x658f: 'Sfx1_Is07', 0x6595: 'Sfx1_Is08',
 0x65d3: 'Sfx1_Stop', 0x660e: 'Sfx1_07_Play.requestSfx3', 0x66e1: 'Sfx1_WriteEnvPeriod',
 0x67e9: 'Sfx4_Stop',
 0x6800: 'Sfx3_02_Init', 0x6817: 'Sfx3_02_Play', 0x682a: 'Sfx3_02_Play.write', 0x6832: 'Sfx3_02_Play.fall',
 0x683c: 'Sfx3_Update', 0x686b: 'Sfx3_01_Init', 0x6880: 'Sfx3_01_Init.write', 0x6883: 'Sfx3_01_Play.step9',
 0x6894: 'Sfx3_01_Play.step13', 0x68a5: 'Sfx3_01_Play.step17', 0x68b6: 'Sfx3_01_Play', 0x68d8: 'Sfx3_01_Play.up',
 0x68dc: 'Sfx3_01_Play.down', 0x68de: 'Sfx3_01_Play.write',
 0x68e2: 'Sfx3_Stop', 0x6908: 'Sfx3_Stop.song05', 0x690d: 'Sfx3_Start', 0x6932: 'Sfx3_LoadWave',
 0x6936: 'Sfx_Start', 0x6956: 'SetRegs_Ch1', 0x695d: 'SetRegs_Ch2', 0x6964: 'SetRegs_Ch3', 0x696b: 'SetRegs_Ch4', 0x6970: 'SetRegs_Copy',
 0x6978: 'Sfx_GetInitPointer', 0x697c: 'GetPointer', 0x698b: 'Sfx_Tick', 0x6996: 'Sfx_Tick.done',
 0x6998: 'LoadWave', 0x699b: 'LoadWave.loop',
 0x69a5: 'Sound_Stop', 0x69c7: 'Sound_MuteChannels',
 0x69dd: 'Sfx1_Update', 0x69f0: 'Sfx1_Update.playing', 0x69fc: 'Sfx1_Update.done',
 0x69fd: 'Sfx4_Update', 0x6a10: 'Sfx4_Update.playing', 0x6a1c: 'Sfx4_Update.done',
 0x6a1d: 'Music_Stop', 0x6a21: 'Music_StartSong', 0x6a3c: 'Music_InitPanning', 0x6a44: 'Music_InitPanning.find', 0x6a4d: 'Music_InitPanning.found',
 0x6a65: 'Music_UpdatePanning', 0x6a8f: 'Music_UpdatePanning.addSfx', 0x6a9a: 'Music_UpdatePanning.ch4', 0x6aa4: 'Music_UpdatePanning.write',
 0x6aa5: 'Music_UpdatePanning.store', 0x6aa8: 'Music_UpdatePanning.all', 0x6aac: 'Music_UpdatePanning.fixed', 0x6ab1: 'Music_UpdatePanning.idle',
 0x6abe: 'SongPanTable',
 0x6b02: 'CopyWordIndirect', 0x6b0d: 'CopyWord', 0x6b13: 'Music_LoadHeader', 0x6b6a: 'Music_LoadHeader.initCounters',
 0x6b7d: 'Cmd_Instrument_wave', 0x6b89: 'Cmd_Instrument', 0x6bb3: 'Music_NextByte', 0x6bb9: 'IncPtr', 0x6bbf: 'IncPtr.store',
 0x6bc5: 'IncPtr2', 0x6bce: 'ReadPtrByte', 0x6bd5: 'Music_Sustain_skip', 0x6bd8: 'Music_Sustain', 0x6bef: 'Music_Sustain.effects',
 0x6c04: 'Music_ChannelDone', 0x6c09: 'Cmd_PatternEnd', 0x6c10: 'Cmd_PatternEnd.loadPattern', 0x6c24: 'Cmd_PatternEnd.loop',
 0x6c3b: 'Cmd_PatternEnd.songEnd', 0x6c3e: 'Cmd_PatternEnd.stop',
 0x6c44: 'Music_Update', 0x6c52: 'Music_ChannelLoop', 0x6c5c: 'Music_ReadPattern', 0x6c5e: 'Music_ReadCommand',
 0x6c8b: 'Music_Note', 0x6caa: 'Music_Note.lookup', 0x6cb7: 'Music_Note.rest', 0x6cbc: 'Music_NoiseNote', 0x6cc4: 'Music_NoiseNote.copy',
 0x6cd3: 'Music_Trigger', 0x6ced: 'Music_Trigger.ch3', 0x6cf8: 'Music_Trigger.ch2', 0x6cfc: 'Music_Trigger.ch1', 0x6d01: 'Music_Trigger.readInstr',
 0x6d0a: 'Music_Trigger.readDuty', 0x6d0d: 'Music_Trigger.write', 0x6d16: 'Music_Trigger.notRest', 0x6d34: 'Music_Trigger.done',
 0x6d39: 'Music_NextChannel', 0x6d4a: 'Music_NextChannel.allDone', 0x6d57: 'Music_Trigger_flagSet',
 0x6d5e: 'Vibrato_GetStep', 0x6d67: 'Music_Vibrato', 0x6d89: 'Music_Vibrato.done', 0x6d8b: 'Music_Vibrato.apply',
 0x6da6: 'Music_Vibrato.type1', 0x6da9: 'Music_Vibrato.readTable', 0x6db2: 'Music_Vibrato.nibble', 0x6dbf: 'Music_Vibrato.positive',
 0x6dc1: 'Music_Vibrato.signed', 0x6dc2: 'Music_Vibrato.add',
 0x6dcb: 'VibratoTable', 0x6e02: 'NoteTable', 0x6e94: 'NoiseTable', 0x6ef9: 'LengthTables',
}
COMMENTS = {
 0x7ff0: 'Entry points: update, stop (Dr. Mario adds init at $7FF6).',
 0x6480: 'ch1 effects 1-8: init routine and per-frame routine',
 0x64a0: 'ch4 effects 1-4',
 0x64b0: 'songs 1-17 (wSongRequest & $1F)',
 0x64d2: 'Called first in every update: empty.',
 0x64d3: 'Called once per frame from the game\'s main loop ($02CA); saves all registers. wPauseRequest\n1 = pause, 2 = resume. While hDemoMode (game flag $FFE4, apparently the attract-mode demo)\nis set every request is dropped. Order: ch1 SFX, ch4 SFX, ch3 SFX, song request, music,\npanning; then clear the requests.',
 0x6524: 'Pause: mute, cancel effects, reload wave $6EE9, then a 4-frame jingle on ch2 at timer\n$28/$20/$18 (two alternating register images); hold at $10 until resumed.',
 0x6583: 'Z if the named effect is playing (used by effects that must not interrupt it).',
 0x65d3: 'End a ch1 effect and give ch1 back to the music.',
 0x660e: 'Effect 7 requests ch3 effect 1 on its last step.',
 0x683c: 'ch3 effects (wSfx3Request 1-2) are code here, not a table: 1 and 2 use their own wave.',
 0x68e2: 'End a ch3 effect: the music gets ch1-ch4 back; reload the song\'s wave (song 5 uses\n$6EC9, others $6EE9).',
 0x690d: 'Start a ch3 effect: take ch1, ch2, ch3 and ch4 from the music and load the effect\'s wave.',
 0x6936: 'Start an effect: a = frames per step, hl = first register image, de = &request.\nStores the effect id as playing, the frame count, clears the timer and step, and writes\nthe image to ch1 / ch3 / ch4 (chosen by e).',
 0x698b: 'Count the frame timer up to the step length; a = 0 when a step ends.',
 0x69a5: 'Stop everything: effects, music, panning; mute.',
 0x6a21: 'a = song 1-17, $FF = stop. Loads the header and the panning.',
 0x6a3c: 'Panning per song: mode (1 fixed A, 2 alternate A/B every period frames, 3 = $FF), period,\nNR51 A, NR51 B. While an SFX plays on ch3 or ch4 those channels stay on both sides.',
 0x6c5e: 'Commands: only $9D. Lengths $A0-$AF, notes, rest $01, $00 = next list entry.',
 0x6c8b: 'No transpose: the header\'s first byte is stored in wTranspose but never read.',
 0x6d67: 'Pitch effect from the low nibble of InstrDuty (third INSTR byte). Any non-zero value gives\nthe vibrato: VibratoTable, one signed nibble per frame, indexed by NoteFrames / 2 (the type\ntest is followed by an unconditional jr). wSfxId is borrowed as scratch for the type.',
 0x6dcb: 'vibrato: offsets as nibbles (bit 3 = negative)',
 0x6e94: 'ch4: pattern byte = offset 1 + 5n; 5 bytes: NR42, flag (always 0), NR41, NR43, NR44,\ncopied into wCh4InstrEnv-wCh4Freq+1 by Music_NoiseNote',
}

r.code_range(0x6d9d, 0x6da6)    # unreachable: Dr. Mario's effect type 3 (fixed offset)
for a, n in N.items(): r.label(a, n)
r.label(0x6d9d, 'Music_Vibrato.unusedType3', 'unreachable (the jr above always jumps): a fixed offset of -1 for type 3\n(Dr. Mario has the same code with -2 and makes it reachable)')
for a, t in COMMENTS.items(): r.comments[a] = t

# SFX naming
SHARED = {0x65d3, 0x66e1, 0x67e9, 0x6936, 0x6956, 0x695d, 0x6964, 0x696b, 0x6970, 0x6978, 0x697c, 0x698b, 0x6998, 0x68e2,
          0x690d, 0x6932, 0x6583, 0x6589, 0x658f, 0x6595}
entries = {}
for ch, I, P in ((1, I1, P1), (4, I4, P4)):
    for i, (a, b) in enumerate(zip(I, P)):
        tag = f'Sfx{ch}_{i+1:02X}'
        entries[tag] = (a, b)
        for e, kind in ((a, 'Init'), (b, 'Play')):
            if e not in SHARED and e not in r.labels: r.label(e, f'{tag}_{kind}')
            elif e not in SHARED and r.labels[e].startswith('Sfx') and kind == 'Play':
                r.comments[e] = (r.comments.get(e, '') + f'\nalso the per-frame routine of {tag}').strip()
r.collect_refs()

# data blocks
def rows(rr, a, n, per):
    return ['\tdb ' + ', '.join(f'${rr.byte(a+i+k):02x}' for k in range(min(per, n-i))) for i in range(0, n, per)]
def data_span(a, per, name=None):
    e = a + 1
    while e not in r.code and e not in r.labels and r.block_of(e) is None and e < 0x8000: e += 1
    if name: r.label(a, name)
    r.block(a, e - a, lambda rr, a, n=e-a, per=per: rows(rr, a, n, per))
owner = {}
for tag, (a, b) in entries.items():
    for pc in sorted(r.code):
        pass
# label each data block after the effect whose code references it
refs = {}
for pc, (l, fmt, args, k) in r.code.items():
    for t, v in args:
        if t == 'i16' and r.inreg(v) and v not in r.code and 0x6500 <= v < 0x6e00:
            refs.setdefault(v, pc)
def tag_of(pc):
    best = None
    for a in sorted(r.labels):
        if a <= pc and a in r.code and r.labels[a][:3] == 'Sfx' and '.' not in r.labels[a]: best = r.labels[a]
    return best
for v, pc in sorted(refs.items()):
    t = tag_of(pc)
    if v not in N and t: r.label(v, (t.rsplit('_', 1)[0] if t.endswith(('_Init', '_Play')) else t) + f'_Data_{v:04X}')
STEP5 = {0x657b, 0x657f}
for v in sorted(refs):
    if v in (0x6dcb, 0x6e02, 0x6e94) or r.block_of(v) is not None: continue
    data_span(v, 5 if v not in (0x6857, 0x685c, 0x6861, 0x6866, 0x67fb) else 5)
r.block(0x64b0, 34, lambda rr, a: [f'\tdw {rr.sym_addr(rr.word(a+2*i))}\t; song {i+1}' for i in range(17)])
r.block(0x6abe, 68, lambda rr, a: ['\tdb ' + ', '.join(f'${rr.byte(a+4*i+k):02x}' for k in range(4)) + f'\t; song {i+1}: mode, period, NR51 A, NR51 B' for i in range(17)])
r.block(0x6dcb, 0x6e02 - 0x6dcb, lambda rr, a: rows(rr, a, 0x6e02 - 0x6dcb, 16))
def note_table(rr, a):
    return [f'\tdw ${rr.word(a):04x}\t; index 0: never played'] + [f'\tdw ${rr.word(a+2+2*i):04x}\t; {note_name(2+2*i)}' for i in range(72)]
r.block(0x6e02, 146, note_table)
r.block(0x6e94, 21, lambda rr, a: ['\tdb $00'] + [rows(rr, a+1+5*k, 5, 5)[0] + f'\t; NOISE{k}' for k in range(4)])
WAVES = [0x6ea9, 0x6eb9, 0x6ec9, 0x6ed9, 0x6ee9]
for wv in WAVES:
    if wv not in r.labels or r.labels[wv].startswith('Data_'): r.label(wv, f'Wave_{wv:04X}')
    r.block(wv, 16, lambda rr, a: rows(rr, a, 16, 16))

LEN_NAMES = ['L32', 'L16', 'L8', 'L4', 'L2', 'L1', 'L8D', 'L4D', 'L2D', 'L8T', 'L4T', 'LEN11', 'LEN12', 'LEN13', 'LEN14', 'LEN15']
cmds = {0x9d: ('INSTR', ['instr'])}
songs = Songs(r, {'song_table': 0x64b0, 'song_count': 17, 'cmds': cmds, 'len_names': LEN_NAMES,
                  'noise_names': {1+5*k: f'NOISE{k}' for k in range(4)}}).parse()
songs.register()
def len_bytes(rr, a):
    out = []; cur = []
    for q in range(0x6ef9, 0x6f3f):
        if q in rr.labels and q != 0x6ef9:
            if cur: out.append('\tdb ' + ', '.join(cur)); cur = []
            out.append(rr.labels[q] + ':')
        cur.append(f'${rr.byte(q):02x}')
    if cur: out.append('\tdb ' + ', '.join(cur))
    return out
r.block(0x6ef9, 0x6f3f - 0x6ef9, len_bytes)
r.label(0x6ef9, 'LengthTables')
r.collect_refs()
r.label(0x753e, 'Unused_753E', 'unreferenced')
r.block(0x753e, 5, lambda rr, a: rows(rr, a, 5, 5))
r.block(0x7fc6, 42, lambda rr, a: ['\tds 42, 0\t; unused'])
r.label(0x6da1, 'Music_Vibrato.unusedFixed')
cnt = {}; parent = None
for a in sorted(r.labels):
    n = r.labels[a]
    if n.startswith('Code_') and parent:
        cnt[parent] = cnt.get(parent, -1) + 1
        r.labels[a] = f'{parent}.l{cnt[parent]}'
    elif '.' not in n and a in r.code:
        parent = n
r.block(0x7ff6, 10, lambda rr, a: ['\tds 10, 0\t; unused'])

cov = set()
for pc, d in r.code.items(): cov.update(range(pc, pc + d[0]))
for b, (s, e) in r.blocks.items(): cov.update(range(b, b + s))
gaps = []; a = 0x6480
while a < 0x8000:
    if a not in cov:
        b = a
        while b < 0x8000 and b not in cov: b += 1
        gaps.append((hex(a), b - a)); a = b
    else: a += 1
print('gaps', gaps, 'unterminated', [hex(x) for x in songs.unterminated])

song_end = max(max(songs.pat_events[p][1] for p in songs.pat_events), max(a+2 for a in songs.list_words))
parts = r.emit_split([(0x6480, 0x6dcb), (0x6dcb, 0x6f3f), (0x6f3f, 0x7ff0), (0x7ff0, 0x8000)])
def w(name, body): open(os.path.join(OUT, name), 'w').write(body)
w('Tet_Driver.inc', '; Tetris sound driver: code and SFX data, $6480-$6DCA\n\n' + parts[0])
w('Tet_Tables.inc', '; Tetris sound driver: tables, $6DCB-$6F3E\n\n' + parts[1])
w('Tet_Songs.inc', '; Tetris songs, $6F3F-$7FEF\n\n' + parts[2])
w('Tet_Stubs.inc', '; Tetris sound driver: entry points, $7FF0-$7FFF\n\n' + parts[3])
lines = ['; Tetris sound RAM', 'IF !DEF(TET_RAM_INC)', 'DEF TET_RAM_INC EQU 1']
for a in sorted(RAM):
    if '+' not in RAM[a]: lines.append(f'DEF {RAM[a]:<20} EQU ${a:04X}')
lines.append('ENDC')
w('Tet_RAM.inc', '\n'.join(lines) + '\n')
w('Tet_Sound.asm', '; Tetris (GB, V1.1) sound driver, $6480-$7FFF\nINCLUDE "GB_Hardware.inc"\nINCLUDE "Tet_RAM.inc"\nINCLUDE "Tet_Macros.inc"\n\n'
  'SECTION "Tetris sound", ROMX[$6480], BANK[1]\n\tASSERT @ == $6480\nINCLUDE "Tet_Driver.inc"\n\tASSERT @ == $6DCB\nINCLUDE "Tet_Tables.inc"\n'
  '\tASSERT @ == $6F3F\nINCLUDE "Tet_Songs.inc"\n\tASSERT @ == $7FF0\nINCLUDE "Tet_Stubs.inc"\n')
os.makedirs(os.path.join(OUT, 'harness'), exist_ok=True)
lab = {n: a for a, n in r.labels.items()}
hooks = sorted(pc for pc, (l, fmt, args, k) in r.code.items() if (0x6970 <= pc < 0x6978) and re.match(r'ld [abcdelh], \[hl', fmt))
json.dump({'patterns': {f'{p:04x}': [p, songs.pat_events[p][1]] for p in songs.pat_events},
           'list_words': sorted(set(sum(([a, a+1] + ([a+2, a+3] if songs.list_words[a][0] == 'loop' else []) for a in songs.list_words), []))),
           'sfxdata': sorted([a, a + sz, r.labels.get(a, '')] for a, (sz, e) in r.blocks.items()),
           'pat_pc': lab['ReadPtrByte'] + 4, 'list_pc': lab['CopyWordIndirect'] + 4, 'hl_pcs': hooks},
          open(os.path.join(OUT, 'harness', 'model.json'), 'w'))
