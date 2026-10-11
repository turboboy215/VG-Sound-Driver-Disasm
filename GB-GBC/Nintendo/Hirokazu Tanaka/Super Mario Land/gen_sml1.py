"""Generate the Super Mario Land (GB) sound driver sources (bank 3, $6700-$7FFF)."""
import sys, os, json
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'tools'))
from gbdis import Region, decode
from tanaka import Songs, note_name
ROM = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', 'Super Mario Land (W) (V1.0) [!].gb')
OUT = sys.argv[2] if len(sys.argv) > 2 else HERE
rom = open(ROM, 'rb').read()
r = Region(rom, 3, 0x6700, 0x8000)

# ---------------------------------------------------------------- RAM
RAM = {
 0xdf00:'wTranspose', 0xdf01:'wLengthTable', 0xdf02:'wLengthTable+1',
 0xdfe0:'wSfx1Request', 0xdfe1:'wSfx1Playing', 0xdfe2:'wSfx1Timer', 0xdfe3:'wSfx1Period', 0xdfe4:'wSfx1Step', 0xdfe5:'wSfx1Var', 0xdfe6:'wSfx1Var2',
 0xdfe8:'wSongRequest', 0xdfe9:'wSongPlaying',
 0xdff0:'wSfx3Request', 0xdff1:'wSfx3Playing', 0xdff4:'wSfx3Step', 0xdff5:'wSfx3Pitch',
 0xdff8:'wSfx4Request', 0xdff9:'wSfx4Playing', 0xdffc:'wSfx4Step',
 0xffb3:'hGameState', 0xffd0:'hMusicChannel', 0xffd1:'hSfxId', 0xffd3:'hSfx08Request',
 0xffd5:'hPanTimer', 0xffd6:'hPanPeriod', 0xffd7:'hPanToggle', 0xffd8:'hPanMode', 0xffd9:'hPanNR51A', 0xffda:'hPanNR51B',
 0xffde:'hPauseTimer', 0xffdf:'hPauseRequest',
}
CHF = {0:'ListPtr',1:'ListPtr+1',2:'LenCounter',3:'Length',4:'PatPtr',5:'PatPtr+1',6:'InstrEnv',7:'InstrFlag',8:'InstrDuty',
       9:'Freq',10:'Freq+1',11:'Rest',12:'Unused_C',13:'Unused_D',14:'NoteFrames',15:'Flags'}
for n in range(4):
    for o, f in CHF.items(): RAM[0xdf10 + 0x10*n + o] = f'wCh{n+1}{f}'
r.ram = RAM

# ---------------------------------------------------------------- code
r.trace([0x6762, 0x6b26, 0x7ff0, 0x7ff3])
SFX1_INIT = r.jumptable(0x6700, 11, 'Sfx1_InitTable')
SFX1_PLAY = r.jumptable(0x6716, 11, 'Sfx1_PlayTable')
SFX4_INIT = r.jumptable(0x672c, 4, 'Sfx4_InitTable')
SFX4_PLAY = r.jumptable(0x6734, 4, 'Sfx4_PlayTable')
r.code_range(0x6f0b, 0x6f14)      # unreachable: the pitch-effect type test always jumps

N = {
 0x6762:'Sound_Update', 0x6787:'Sound_Update.main', 0x6799:'Sound_Update.done', 0x67b1:'Sound_Update.pause',
 0x67c2:'Sound_Update.jingleA', 0x67c5:'Sound_Update.writeJingle', 0x67ca:'Sound_Update.jingleB', 0x67cf:'Sound_Update.unpause',
 0x67d4:'Sound_Update.paused',
 0x67f4:'Sfx3_Update', 0x6808:'Sfx3_01_Init', 0x682d:'Sfx3_01_Play', 0x6840:'Sfx3_01_Play.write', 0x6848:'Sfx3_01_Play.down',
 0x6851:'Sfx3_01_Play.stop',
 0x6890:'Sfx1_IsBusy_468B', 0x6895:'Sfx1_IsBusy_34568B', 0x689b:'Sfx1_IsBusy_4568B', 0x68a1:'Sfx1_IsBusy_Check',
 0x68f4:'Sfx1_Stop', 0x68ef:'Sfx1_PlayOneStep', 0x6aa8:'Sfx4_PlayOneStep', 0x6a58:'Sfx4_IsBusy_1', 0x6aad:'Sfx4_Stop',
 0x6ab9:'Sfx_Start', 0x6ad8:'SetRegs_Ch1', 0x6adf:'SetRegs_Ch2', 0x6ae6:'SetRegs_Ch3', 0x6aed:'SetRegs_Ch4', 0x6af2:'SetRegs_Copy',
 0x6afa:'Sfx_GetInitPointer', 0x6afd:'GetPointer', 0x6b0c:'Sfx_Tick', 0x6b17:'Sfx_Tick.done', 0x6b19:'LoadWave', 0x6b1c:'LoadWave.loop',
 0x6b26:'Sound_Stop', 0x6b4b:'Sound_MuteChannels',
 0x6b59:'Sfx1_Update', 0x6b6c:'Sfx1_Update.playing', 0x6b78:'Sfx1_Update.done',
 0x6b79:'Sfx4_Update', 0x6b8c:'Sfx4_Update.playing', 0x6b98:'Sfx4_Update.done',
 0x6b99:'Music_StopSong', 0x6b9d:'Music_CheckRequest',
 0x6bb9:'Music_InitPanning', 0x6bc1:'Music_InitPanning.find', 0x6bca:'Music_InitPanning.found',
 0x6bdc:'Music_Sfx4Panning', 0x6beb:'Music_Sfx4Panning.write',
 0x6bef:'Music_UpdatePanning', 0x6c1f:'WriteNR51', 0x6c23:'WriteNR51_All', 0x6c27:'WriteNR51_A',
 0x6c2b:'SongPanTable',
 0x6c77:'CopyWordIndirect', 0x6c82:'CopyWord', 0x6c88:'Music_LoadHeader', 0x6cdf:'Music_LoadHeader.initCounters',
 0x6cf2:'Cmd_Instrument_wave', 0x6cfe:'Cmd_Instrument', 0x6d28:'Music_NextByte',
 0x6d2e:'IncPtr', 0x6d34:'IncPtr.store', 0x6d3a:'IncPtr2', 0x6d43:'ReadPtrByte',
 0x6d4a:'Music_Sustain_skip', 0x6d4d:'Music_Sustain', 0x6d63:'Music_Sustain.effects', 0x6d78:'Music_ChannelDone',
 0x6d7d:'Cmd_PatternEnd', 0x6d84:'Cmd_PatternEnd.loadPattern', 0x6d98:'Cmd_PatternEnd.loop', 0x6daf:'Cmd_PatternEnd.songEnd',
 0x6db8:'Music_Update', 0x6dc5:'Music_ChannelLoop', 0x6dcf:'Music_ReadPattern', 0x6dd1:'Music_ReadCommand',
 0x6dfe:'Music_Note', 0x6e29:'Music_Note.rest', 0x6e2e:'Music_NoiseNote', 0x6e36:'Music_NoiseNote.copy',
 0x6e45:'Music_Trigger', 0x6e5e:'Music_Trigger.ch3', 0x6e69:'Music_Trigger.ch2', 0x6e6d:'Music_Trigger.ch1',
 0x6e72:'Music_Trigger.readInstr', 0x6e7b:'Music_Trigger.readDuty', 0x6e7e:'Music_Trigger.write', 0x6e87:'Music_Trigger.notRest',
 0x6ea5:'Music_Trigger.done', 0x6eaa:'Music_NextChannel', 0x6ebb:'Music_NextChannel.allDone', 0x6ec8:'Music_Trigger_flagSet',
 0x6ecf:'Vibrato_GetStep', 0x6ed8:'Music_Vibrato', 0x6ef8:'Music_Vibrato.done', 0x6efa:'Music_Vibrato.apply',
 0x6f0b:'Music_Vibrato.unreachable', 0x6f0f:'Music_Vibrato.detune', 0x6f14:'Music_Vibrato.table', 0x6f20:'Music_Vibrato.nibble',
 0x6f2d:'Music_Vibrato.positive', 0x6f2f:'Music_Vibrato.signed', 0x6f30:'Music_Vibrato.add',
 0x6f39:'VibratoTable_Wobble', 0x6f70:'NoteTable', 0x7002:'NoiseTable',
 0x7ff0:'Sound_UpdateStub', 0x7ff3:'Sound_StopStub',
}
for a, n in N.items(): r.label(a, n)

SHARED = {0x68ef, 0x6aa8, 0x6ab9, 0x6ad8, 0x6adf, 0x6ae6, 0x6aed, 0x6b0c, 0x68f4, 0x6890, 0x6895, 0x689b, 0x68a1, 0x6a58, 0x6aad}
def owned(entries):
    seen = set(); work = list(entries)
    while work:
        pc = work.pop()
        while pc not in seen and pc in r.code and pc not in SHARED:
            seen.add(pc)
            l, fmt, args, k = r.code[pc]
            if args and args[0][0] in ('rel','jp','call'):
                t = args[0][1]
                if t in r.code and t not in SHARED: work.append(t)
                if k in ('jr','jp'): break
            if k in ('ret','jphl'): break
            pc += l
    return seen
def dblock(addr, size, name, comment=None, per=16):
    r.label(addr, name, comment)
    def em(rr, a, size=size, per=per):
        return ['\tdb ' + ', '.join(f'${rr.byte(a+i+k):02x}' for k in range(min(per, size-i))) for i in range(0, size, per)]
    r.block(addr, size, em)
def name_sfx(ch, i, init, play, data):
    tag = f'Sfx{ch}_{i:02X}'
    if init not in SHARED and init not in r.labels: r.label(init, f'{tag}_Init')
    if play not in SHARED and play not in r.labels: r.label(play, f'{tag}_Play')
    k = 0
    for pc in sorted(owned([init, play])):
        l, fmt, args, kind = r.code[pc]
        for t, v in args:
            if t in ('rel','jp','call') and v in r.code and v not in r.labels and v not in SHARED:
                par = f'{tag}_Play' if (play not in SHARED and v > play) else f'{tag}_Init'
                r.label(v, f'{par}.l{k}'); k += 1
CH1 = 'NR10-NR14 image'; CH2 = 'NR21-NR24 image'; CH3 = 'NR30-NR34 image'; CH4 = 'NR41-NR44 image'
SFXDATA = [   # (address, size, comment); SFX data is named after the effect whose code reads it
 (0x67ec, 4, CH2), (0x67f0, 4, CH2), (0x6803, 5, CH3),
 (0x6868, 5, CH1), (0x6875, 5, CH1), (0x6886, 5, CH1), (0x688b, 5, CH1), (0x6902, 5, CH1), (0x6907, 5, CH1),
 (0x692c, 5, CH1), (0x6931, 5, CH1), (0x695c, 5, CH1), (0x696e, 5, CH1), (0x6999, 5, CH1), (0x69aa, 5, CH1),
 (0x69af, 14, 'NR12 per step, 0 = end'),
 (0x69f1, 5, CH1), (0x69f6, 5, CH1), (0x69fb, 5, CH1), (0x6a00, 5, CH1), (0x6a05, 5, CH1), (0x6a0a, 5, CH1),
 (0x6a4c, 4, CH4), (0x6a5f, 4, CH4), (0x6a63, 6, 'NR43 per step, 0 = end'), (0x6a8c, 4, CH4), (0x6a98, 4, CH4),
]
FIXED = {0x67ec: 'PauseJingleA', 0x67f0: 'PauseJingleB', 0x6803: 'Sfx3_01_Regs'}
for i, (a, b) in enumerate(zip(SFX1_INIT, SFX1_PLAY)): name_sfx(1, i+1, a, b, None)
for i, (a, b) in enumerate(zip(SFX4_INIT, SFX4_PLAY)): name_sfx(4, i+1, a, b, None)
owner = {}
for ch, inits, plays in ((1, SFX1_INIT, SFX1_PLAY), (4, SFX4_INIT, SFX4_PLAY)):
    for i, (a, b) in enumerate(zip(inits, plays)):
        for pc in sorted(owned([a, b])):
            for t, v in r.code[pc][2]:
                if t in ('i16', 'a16') and r.inreg(v) and v not in r.code:
                    owner.setdefault(v, f'Sfx{ch}_{i+1:02X}')
cnt = {}
named = []
for a, n, c in SFXDATA:
    if a in FIXED: nm = FIXED[a]
    else:
        tag = owner[a]
        kind = 'Regs' if 'image' in c else ('Env' if 'NR12' in c else 'NR43' if 'NR43' in c else 'Data')
        cnt[(tag, kind)] = cnt.get((tag, kind), 0) + 1
        nm = f'{tag}_{kind}{cnt[(tag, kind)]}'
    named.append((a, n, nm, c))
# drop the "1" suffix where an effect has a single block of that kind
for i, (a, n, nm, c) in enumerate(named):
    base = nm[:-1]
    if nm.endswith('1') and (base[:base.rindex('_')], base[base.rindex('_')+1:]) in cnt and cnt[(base[:base.rindex('_')], base[base.rindex('_')+1:])] == 1:
        named[i] = (a, n, base, c)
SFXDATA = named
for a, n, nm, c in SFXDATA: dblock(a, n, nm, c)
RAM[0xdf00] = 'wTranspose'

C = {
 0x6700: 'SFX on ch1 (wSfx1Request = 1-11): init routine, then per-frame routine',
 0x672c: 'SFX on ch4 (wSfx4Request = 1-4)',
 0x673c: 'song number 1-19 -> header',
 0x6762: 'Stub at $7FF0. Called from the timer interrupt: it enables VBlank/STAT interrupts\nonly (IE = 3) while it runs and returns with IE = 7, reti.\nOrder: pause request -> pause jingle -> hSfx08Request -> SFX ch1 -> SFX ch4 -> SFX ch3\n-> song request -> music -> panning, then clear every request.',
 0x67b1: 'Pause: mute, cancel the effects and play a 4-note jingle on ch2 (frames $30, $28,\n$20, $18), then hold the timer at $10 until resumed.',
 0x67f4: 'The only ch3 effect: random start pitch (DIV), rises 14 steps, falls until step 30;\nthen the song\'s wave is reloaded (pointer kept in wCh3InstrEnv/Flag).',
 0x6890: 'Priority checks on the ch1 effect playing: Z = do not start.',
 0x68ef: 'Shared per-frame routine of one-image effects (2, 7, 9, 10): stop when the period elapses.',
 0x68ae: 'Effect 1: the period word in wSfx1Step/Var starts at $860A and rises by 15 every frame\nfor 16 frames.',
 0x6916: 'Effect 5: counts frames itself (no period): image 2 at frame 4, stop at 24.',
 0x6980: 'Effects 4 and 11: NR13 = wSfx1Var2 + $10 every 5 frames, until $E0.',
 0x6aa8: 'Shared per-frame routine of ch4 effects 1, 2, 4.',
 0x6a58: 'Z while ch4 effect 1 plays.',
 0x6ab9: 'Start an effect: a = frames per step, hl = register image, de = wSfxNRequest+2.',
 0x6b0c: 'Count frames: a = 0 once every wSfxNPeriod frames.',
 0x6b26: 'Stub at $7FF3. Stop everything; NR51 = $FF, panning mode 3.',
 0x6b4b: 'Envelope $01 on ch1/ch2/ch4 (no retrigger), sweep off, ch3 off.',
 0x6b9d: 'Start a requested song ($FF = stop). No range check.',
 0x6bdc: 'While ch4 effect 1 plays, NR51 alternates $F7 / $7F every 2 frames (noise\nbounces left/right).',
 0x6bef: 'Panning per song: mode 1 = fixed, 3 = all channels both sides, else alternate A/B\nevery period frames. hGameState 5 forces NR51 = $FF.',
 0x6c88: 'hl = song header: transpose (stored, never used), length table, four lists.',
 0x6cfe: '$9D: the only command. Three bytes to wChNInstrEnv/Flag/Duty; on ch3 the first two\nare a wave pointer, loaded now.',
 0x6d4d: 'Frame without a new note: ch3 with level bit 7 drops to 50% 6 frames before the end;\nthen the pitch effect, unless resting or taken by an effect.',
 0x6d7d: '$00: next entry of the section list. $00xx ends the song (music stops, channels are\nmuted with envelope $01); $FFxx loops to the address that follows.',
 0x6db8: 'Music: four 16-byte channel structures at wCh1ListPtr + $10*n.',
 0x6dd1: 'Commands: $00, $9D, $A0-$AF lengths; everything else is a note (rest = $01).\nThe header transpose is not applied.',
 0x6e45: 'Write the note: NRx1 = Duty (ch3: 0), NRx2 = Env (ch3: NR32 = level), period, NRx4 |\n$80 (trigger only, no length). A rest writes envelope $01. Clears bit 0 of Flags.',
 0x6ec8: 'Flag byte non-zero: NRx2 gets whatever e holds (unused by the songs).',
 0x6ed8: 'Pitch effect: any non-zero low nibble of the Duty byte selects the wobble table (the\ntype test jumps unconditionally; the detune path is unreachable).',
}
for a, t in C.items(): r.comments[a] = t
r.overrides[0x6f0f] = {0: '-1'}

# ---------------------------------------------------------------- data
r.block(0x673c, 38, lambda rr, a: ['\tdw ' + rr.sym_addr(rr.word(a+2*i)) for i in range(19)])
r.label(0x673c, 'SongTable')
def note_table(rr, a):
    out = ['\tdw $0f00\t; index 0: never played']
    for i in range(72): out.append(f'\tdw ${rr.word(a+2+2*i):04x}\t; {note_name(2+2*i)}')
    return out
r.block(0x6f70, 146, note_table)
def noise_table(rr, a):
    out = ['\tdb ' + ', '.join(f'${rr.byte(a+i):02x}' for i in range(6)) + '\t; (offsets 0-5: not a drum)']
    for k in range(1, 4):
        q = a+1+5*k
        out.append('\tdb ' + ', '.join(f'${rr.byte(q+i):02x}' for i in range(5)) + f'\t; NOISE{k} (pattern byte ${1+5*k:02x}): NR42, flag, NR41, NR43, NR44')
    return out
r.block(0x7002, 21, noise_table)
WAVES = [0x7017, 0x7027, 0x7037, 0x7047]
for wv in WAVES:
    r.label(wv, f'Wave_{wv:04X}')
    r.block(wv, 16, lambda rr, a: ['\tdb ' + ', '.join(f'${rr.byte(a+i):02x}' for i in range(16))])
r.comments[0x7047] = 'used by the ch3 effect'
def pan_table(rr, a):
    return [f'\tdb ${rr.byte(a+4*i):02x}, ${rr.byte(a+4*i+1):02x}, ${rr.byte(a+4*i+2):02x}, ${rr.byte(a+4*i+3):02x}\t; song {i+1:02d}: mode, period, NR51 A, NR51 B' for i in range(19)]
r.block(0x6c2b, 76, pan_table)
r.comments[0x6f39] = 'Signed nibbles, indexed by NoteFrames / 2 (high nibble on even frames).\nNot bounded: after 110 frames it reads NoteTable.'

LEN_NAMES = ['L32','L16','L8','L4','L2','L1','L8D','L4D','L2D','L8T','L4T','LEN11','LEN12','LEN13','LEN14','LEN15']
cmds = {0x9d:('INSTR',['instr'])}
songs = Songs(r, {'song_table':0x673c, 'song_count':19, 'cmds':cmds, 'len_names':LEN_NAMES,
                  'noise_names':{1+5*k: f'NOISE{k}' for k in range(1,4)}}).parse()
songs.register()
# length tables: bytewise block with labels
LT0, LT1 = 0x7057, 0x7094
def len_bytes(rr, a):
    out = []; cur = []
    for q in range(LT0, LT1):
        if q in rr.labels and q != LT0:
            if cur: out.append('\tdb ' + ', '.join(cur)); cur = []
            out.append(rr.labels[q] + ':')
        cur.append(f'${rr.byte(q):02x}')
    if cur: out.append('\tdb ' + ', '.join(cur))
    return out
r.block(LT0, LT1-LT0, len_bytes)
if LT0 not in r.labels: r.label(LT0, 'LengthTables')

r.collect_refs()
song_end = max(max(songs.pat_events[p][1] for p in songs.pat_events), max(a+2 for a in songs.list_words))
parts = r.emit_split([(0x6700, 0x6f39), (0x6f39, 0x7094), (0x7094, song_end), (song_end, 0x8000)])
def w(name, body): open(os.path.join(OUT, name), 'w').write(body)
w('SML_Driver.inc', '; Super Mario Land sound driver: tables, code and SFX data, bank 3 $6700-$6F38\n\n' + parts[0])
w('SML_Tables.inc', '; Super Mario Land sound driver: tables, bank 3 $6F39-$7093\n\n' + parts[1])
w('SML_Songs.inc', f'; Super Mario Land songs: headers, section lists, patterns, bank 3 $7094-${song_end-1:04X}\n\n' + parts[2])
w('SML_Tail.inc', f'; bank 3 ${song_end:04X}-$7FFF: free space and the driver entry stubs\n\n' + parts[3])
lines = ['; Super Mario Land sound RAM', 'IF !DEF(SML_RAM_INC)', 'DEF SML_RAM_INC EQU 1']
for a in sorted(RAM):
    if '+' not in RAM[a]: lines.append(f'DEF {RAM[a]:<20} EQU ${a:04X}')
lines.append('ENDC')
w('SML_RAM.inc', '\n'.join(lines) + '\n')
os.makedirs(os.path.join(OUT, 'harness'), exist_ok=True)
json.dump({'patterns': {f'{p:04x}': [p, songs.pat_events[p][1]] for p in songs.pat_events},
           'list_words': sorted(set(sum(([a, a+1] + ([a+2, a+3] if songs.list_words[a][0] == 'loop' else []) for a in songs.list_words), []))),
           'sfxdata': [[a, a+n, nm] for a, n, nm, c in SFXDATA] + [[wv, wv+16, 'wave'] for wv in WAVES]},
          open(os.path.join(OUT, 'harness', 'model.json'), 'w'))
print('songs', len(songs.headers), 'patterns', len(songs.patterns), 'lists', len(songs.lists), 'song data ends', hex(song_end),
      'waves', sorted(hex(x) for x in songs.waves), 'lentabs', sorted(hex(x) for x in songs.lentabs))
