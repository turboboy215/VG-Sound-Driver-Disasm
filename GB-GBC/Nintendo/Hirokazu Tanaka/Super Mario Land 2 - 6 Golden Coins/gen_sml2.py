"""Generate the Super Mario Land 2 sound driver sources (bank 4, $4000-$7FFF)."""
import sys, os, json
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'tools'))
from gbdis import Region, decode
from tanaka import Songs, note_name
ROM = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', 'Super Mario Land 2 - 6 Golden Coins (UE) (V1.0) [!].gb')
OUT = sys.argv[2] if len(sys.argv) > 2 else HERE
rom = open(ROM, 'rb').read()
r = Region(rom, 4, 0x4000, 0x8000)

# ---------------------------------------------------------------- RAM (cartridge RAM $A400-$A5FF)
RAM = {
 0xa400:'wTranspose', 0xa401:'wLengthTable', 0xa402:'wLengthTable+1',
 0xa407:'wReleaseFrame', 0xa408:'wReleaseFrame+1',
 0xa450:'wMusicChannel', 0xa451:'wPitchEffect',
 0xa455:'wPanMode', 0xa456:'wPanTimer', 0xa457:'wPanPeriod', 0xa458:'wPanStep', 0xa459:'wPanNR51',
 0xa45d:'wPaused', 0xa45e:'wPauseRequest',
 0xa460:'wSfx1Request', 0xa461:'wSfx1Playing', 0xa468:'wSongRequest', 0xa469:'wSongPlaying',
 0xa470:'wSfx3Request', 0xa471:'wSfx3Playing', 0xa478:'wSfx4Request', 0xa479:'wSfx4Playing',
 0xa48d:'wInstrumentLock', 0xa490:'wSavedChannels', 0xa49f:'wSavedSong',
 0xa500:'wSfx1Timer', 0xa501:'wPauseTimer', 0xa502:'wSfx3Timer', 0xa503:'wSfx4Timer',
 0xa504:'wSfx1Step', 0xa505:'wPauseStep', 0xa506:'wSfx3Step', 0xa508:'wSfx4Step',
 0xa50d:'wFastMusic', 0xa50e:'wCh3Fade',
 0xa514:'wPitch', 0xa51a:'wBend', 0xa51f:'wCh3FadeTimer',
 0xa520:'wVibrato', 0xa526:'wDrop',
 0xa52d:'wSfx1Counter', 0xa52e:'wSfxCounter2', 0xa52f:'wSfx3Counter', 0xa530:'wSfx4Counter', 0xa531:'wSfxCounter5',
 0xa532:'wSfx1Pitch', 0xa533:'wSfx1Pitch+1', 0xa534:'wSfx3Pitch', 0xa535:'wSfx3Pitch+1',
 0xa536:'wSfx1Priority', 0xa537:'wSfxVar37', 0xa538:'wSfx3Priority', 0xa539:'wSfx4Priority',
 0xa53e:'wSfxVar3E', 0xa53f:'wQuietMusic', 0xa52c:'wSfxVar2C',
}
CHF = {0:'ListPtr',1:'ListPtr+1',2:'LenCounter',3:'Length',4:'PatPtr',5:'PatPtr+1',6:'InstrEnv',7:'InstrRelease',8:'InstrDuty',
       9:'Freq',10:'Freq+1',11:'Rest',12:'RepeatPtr',13:'RepeatPtr+1',14:'NoteFrames',15:'Flags'}
for n in range(4):
    for o, f in CHF.items(): RAM[0xa410 + 0x10*n + o] = f'wCh{n+1}{f}'
for k, base in (('wPitch',0xa514), ('wBend',0xa51a), ('wVibrato',0xa520), ('wDrop',0xa526)):
    for i in range(1, 6):
        if base+i not in RAM: RAM[base+i] = f'{k}+{i}'
for i in range(1, 4): RAM[0xa459+i] = f'wPanNR51+{i}'
r.ram = RAM

# ---------------------------------------------------------------- code
r.trace([0x4000, 0x4030, 0x402d])
I1 = r.jumptable(0x407e, 24, 'Sfx1_InitTable')
P1 = r.jumptable(0x40ae, 24, 'Sfx1_PlayTable')
I3 = r.jumptable(0x46fa, 24, 'Sfx3_InitTable')
P3 = r.jumptable(0x472a, 24, 'Sfx3_PlayTable')
I4 = r.jumptable(0x4e64, 11, 'Sfx4_InitTable')
P4 = r.jumptable(0x4e7a, 11, 'Sfx4_PlayTable')
r.code_range(0x515e, 0x5163)     # unreferenced: ch4 start with priority
r.code_range(0x51e2, 0x51e8)     # unreferenced counter helpers
r.code_range(0x51ee, 0x51f4)
r.code_range(0x51f9, 0x51ff)
r.code_range(0x52b4, 0x52dd)     # unreferenced: save / restore the music state

N = {
 0x4000:'Sound_Init', 0x4003:'Sound_Init.clearA4', 0x400b:'Sound_Init.clearA5',
 0x401d:'Unused_401D', 0x402d:'Sound_StopStub',
 0x4030:'Sound_Update', 0x4044:'Sound_Update.main', 0x4057:'Sound_Update.fullVolume', 0x405b:'Sound_Update.run',
 0x4064:'Sound_Update.music', 0x4067:'Sound_Update.clearRequests', 0x4078:'Sound_Update.startSong',
 0x40de:'Sfx1_Update', 0x4110:'Sfx1_Update.start', 0x4116:'Sfx1_Update.playing', 0x411d:'Sfx1_Update.dispatch',
 0x4680:'Sfx1_StartInterruptible', 0x4685:'Sfx1_StartPriority', 0x468a:'Sfx1_Start', 0x46a2:'Sfx1_StopWithRegs', 0x46a8:'Sfx1_Stop', 0x46cc:'Sfx1_WritePeriod',
 0x46d3:'Sfx3_Update', 0x46e3:'Sfx3_Update.start', 0x46e9:'Sfx3_Update.playing', 0x46f0:'Sfx3_Update.dispatch',
 0x4df3:'Sfx3_StartPriority', 0x4df8:'Sfx3_Start', 0x4e17:'Sfx3_StopWithRegs', 0x4e1d:'Sfx3_Stop',
 0x4e42:'Sfx3_Nothing', 0x4e43:'Sfx3_LoadWave', 0x4e49:'Sfx3_LoadWave5BD6', 0x4e4e:'Sfx3_LoadWave5BE6',
 0x4e53:'Sfx3_LoadWave5BF6', 0x4e58:'Sfx3_LoadWave5B96', 0x4e5d:'Sfx3_WritePeriod',
 0x4e90:'Sfx4_Update', 0x4ea2:'Sfx4_Update.playing', 0x4ea9:'Sfx4_Update.dispatch',
 0x515e:'Sfx4_StartPriority_Unused', 0x5163:'Sfx4_Start', 0x517b:'Sfx4_StopWithRegs', 0x5181:'Sfx4_Stop', 0x519f:'Sfx4_WriteNR43',
 0x51a6:'GetPointer', 0x51b3:'Sfx_DecTimer', 0x51b7:'Sfx_IncStep',
 0x51bb:'SetRegs_Ch1', 0x51c1:'SetRegs_Ch2', 0x51c7:'SetRegs_Ch3', 0x51cd:'SetRegs_Ch4', 0x51d3:'SetRegs_Copy', 0x51da:'SetRegs_Copy.storeTimer',
 0x51dc:'Sfx1_DecCounter', 0x51e2:'Sfx_DecCounter2_Unused', 0x51e8:'Sfx3_DecCounter', 0x51ee:'Sfx4_DecCounter_Unused',
 0x51f4:'Sfx_DecCounter', 0x51f9:'Sfx_LoadPitchA_Unused', 0x51ff:'Sfx3_LoadPitch', 0x5205:'Sfx_LoadPitch',
 0x5214:'Sfx1_AddPitch', 0x521e:'Sfx3_AddPitch', 0x5228:'Sfx_AddPitch',
 0x5244:'SongTable', 0x5298:'GetSongPointer', 0x52a7:'LoadWave', 0x52aa:'LoadWave.loop',
 0x52b4:'Music_SaveState_Unused', 0x52ba:'Music_SaveState_Unused.loop', 0x52c8:'Music_RestoreState_Unused', 0x52ce:'Music_RestoreState_Unused.loop',
 0x4e3c:'Sfx3_StopRegs', 0x519a:'Sfx4_StopRegs',
 0x52dd:'Music_StopSong', 0x52e0:'Music_StartSong', 0x52f7:'SongPanTable',
 0x53f3:'Music_InitPanning', 0x53f9:'Music_InitPanning.find', 0x5404:'Music_InitPanning.found',
 0x5421:'Music_UpdatePanning', 0x5445:'Music_UpdatePanning.write',
 0x5449:'CopyWordIndirect', 0x5454:'CopyWord', 0x545a:'Music_LoadHeader', 0x547f:'Music_LoadHeader.normal',
 0x5483:'Music_LoadHeader.copy', 0x5497:'Music_LoadHeader.lengthTable', 0x54a7:'Music_LoadHeader.skipFast', 0x54a9:'Music_LoadHeader.lists',
 0x54eb:'Music_LoadHeader.initCounters',
 0x54fe:'Cmd_Instrument_wave', 0x550d:'Cmd_Instrument_wave.done', 0x5510:'Cmd_Instrument', 0x5536:'Cmd_Instrument.locked',
 0x5540:'Music_NextByte', 0x5546:'IncPtr', 0x554c:'IncPtr.store', 0x5552:'IncPtr2', 0x555b:'ReadPtrByte',
 0x5562:'Music_Sustain_skip', 0x5565:'Music_Sustain', 0x557c:'Music_Sustain.effects', 0x5596:'Music_ChannelDone',
 0x559b:'Cmd_PatternEnd', 0x55a2:'Cmd_PatternEnd.loadPattern', 0x55b6:'Cmd_PatternEnd.loop', 0x55cd:'Cmd_PatternEnd.songEnd',
 0x55d6:'Cmd_Tempo', 0x55ea:'Cmd_Transpose', 0x55f3:'Cmd_SkipAndContinue', 0x55f8:'Cmd_RepeatStart', 0x561c:'Cmd_RepeatEnd', 0x5635:'Cmd_RepeatEnd.done',
 0x5638:'Music_Update', 0x5649:'Music_ChannelLoop', 0x5653:'Music_ReadPattern', 0x5655:'Music_ReadCommand',
 0x56b9:'Music_Length.release', 0x56ca:'Music_Length.store', 0x56d0:'Music_Length.storeRelease', 0x56de:'Music_Length.done',
 0x56e7:'Music_Note', 0x56ff:'Music_Note.resetEffects', 0x5727:'Music_Note.effectsDone', 0x5728:'Music_Note.lookup',
 0x5755:'Music_Note.addTranspose', 0x5758:'Music_Note.table', 0x5765:'Music_Note.rest',
 0x576a:'Music_NoiseNote', 0x5777:'Music_NoiseNote.copy', 0x5788:'Music_NoiseNote.sfxDrum',
 0x579b:'Music_Trigger', 0x57b7:'Music_Trigger.ch3', 0x57c2:'Music_Trigger.ch2', 0x57c6:'Music_Trigger.ch1', 0x57c9:'Music_Trigger.readInstr',
 0x57d0:'Music_Trigger.write', 0x57d9:'Music_Trigger.notRest', 0x57f2:'Music_Trigger.done',
 0x57f7:'Music_NextChannel', 0x5808:'Music_NextChannel.allDone',
 0x5815:'Music_Effects_ret', 0x5817:'Music_Effects', 0x5839:'Music_Effects.slides', 0x5851:'Music_Effects.channel', 0x5879:'Music_Effects.pitch',
 0x5899:'Music_Release', 0x58c0:'Music_Release.ch2', 0x58e4:'Music_ReleaseWrite',
 0x58f7:'Sound_Pause', 0x5914:'Sound_Pause.release', 0x5926:'Sound_Unpause', 0x5936:'Sound_Paused', 0x5959:'Sound_Paused.hold',
 0x5966:'PauseJingleTable', 0x5970:'PauseJingle',
 0x5989:'Cmd_Ch3FadeOn', 0x598b:'Cmd_Ch3Fade.store', 0x5994:'Cmd_Ch3FadeOff', 0x599a:'Music_Ch3Fade', 0x59c7:'Music_Ch3Fade.write',
 0x59cc:'Cmd_DropOn', 0x59d4:'Cmd_Drop.store', 0x59db:'Cmd_DropOff', 0x59e4:'Music_Drop', 0x59f0:'Music_Drop.apply', 0x59fa:'Music_Drop.next',
 0x59ff:'Cmd_BendOn', 0x5a07:'Cmd_Bend.store', 0x5a0e:'Cmd_BendOff', 0x5a18:'Music_Bend', 0x5a35:'Music_Bend.done', 0x5a44:'Music_Bend.start',
 0x5a55:'GetNoteFreq', 0x5a60:'WritePitch', 0x5a71:'IndexByChannel', 0x5a7a:'ReadPitch',
 0x5a87:'Music_Vibrato', 0x5a9f:'Music_Vibrato.apply', 0x5ac0:'Music_Vibrato.wrap', 0x5ac7:'Music_Vibrato.first',
 0x5acc:'VibratoTable', 0x5af4:'NoteTable', 0x5c06:'NoiseTable', 0x5c25:'LengthTables', 0x5cac:'ReleaseEnvelopes',
 0x7f5e:'Sound_Stop', 0x7f6b:'Sound_ClearState', 0x7fe7:'Sound_MuteChannels', 0x7ffd:'Unused_7FFD',
}
for a, n in N.items(): r.label(a, n)

# ---------------------------------------------------------------- SFX code and data naming
SHARED = {0x4680, 0x4685, 0x468a, 0x46a2, 0x46a8, 0x46cc, 0x4df3, 0x4df8, 0x4e17, 0x4e1d, 0x4e42, 0x4e43, 0x4e49, 0x4e4e, 0x4e53, 0x4e58,
          0x4e5d, 0x5163, 0x517b, 0x5181, 0x519f, 0x51a6, 0x51b3, 0x51b7, 0x51bb, 0x51c1, 0x51c7, 0x51cd, 0x51dc, 0x51e8, 0x51f9,
          0x51ff, 0x5214, 0x521e, 0x7f5e}
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
owner = {}; sfx_entries = {}
for ch, I, P in ((1, I1, P1), (3, I3, P3), (4, I4, P4)):
    for i, (a, b) in enumerate(zip(I, P)):
        tag = f'Sfx{ch}_{i+1:02X}'
        sfx_entries[tag] = (a, b)
        for e, kind in ((a, 'Init'), (b, 'Play')):
            if e not in SHARED and e not in r.labels: r.label(e, f'{tag}_{kind}')
for tag, (a, b) in sfx_entries.items():
    k = 0
    for pc in sorted(owned([a, b])):
        for t, v in r.code[pc][2]:
            if t in ('rel','jp','call') and v in r.code and v not in r.labels and v not in SHARED:
                par = f'{tag}_Play' if (b not in SHARED and v > b and r.labels.get(b, '').startswith(tag)) else f'{tag}_Init'
                r.label(v, f'{par}.l{k}'); k += 1
            if t in ('i16','a16') and r.inreg(v) and v not in r.code:
                owner.setdefault(v, (tag, pc))

# data typing: what consumes the pointer loaded by `ld hl, X`
STEP6 = {0x51bb, 0x468a, 0x4685, 0x4680, 0x51c7, 0x4df8, 0x4df3, 0x46a2, 0x4e17}
STEP5 = {0x51c1, 0x51cd, 0x5163, 0x517b}
def consumer(pc):
    q = pc + r.code[pc][0]; seen_getptr = False
    for _ in range(6):
        if q not in r.code: return None, seen_getptr
        l, fmt, args, k = r.code[q]
        if args and args[0][0] in ('jp', 'call', 'rel'):
            t = args[0][1]
            if t == 0x51a6: seen_getptr = True
            elif t in r.code and (k in ('jp', 'call')): return t, seen_getptr
        if k in ('ret', 'jp', 'jr') and not (args and args[0][1] in r.code): return None, seen_getptr
        q += l
    return None, seen_getptr

r.collect_refs()
datarefs = {}
for pc, (l, fmt, args, k) in r.code.items():
    if fmt.startswith('ld hl, ') and args[0][0] == 'i16' and r.inreg(args[0][1]) and args[0][1] not in r.code:
        datarefs[args[0][1]] = consumer(pc)
for a, (tag, pc) in owner.items():
    if a not in N and (a not in r.labels or r.labels[a].startswith('Data_')):
        r.label(a, f'{tag}_Data_{a:04X}')

# ---------------------------------------------------------------- SFX data spans
FMT3 = {0x46cc, 0x4e5d, 0x519f}          # 2 registers + frames
FMTBE = {0x5214, 0x521e}                 # big-endian period offsets
FMT6 = STEP6 | {0x51ff, 0x51f9, 0x5205, 0x51da}
FMTWAVE = {0x4e43, 0x52a7, 0x51d3}
def rowsize(cons):
    t, gp = cons
    if t in FMT6: return 6
    if t in STEP5: return 5
    if t in FMT3: return 3
    if t in FMTBE: return 2
    if t in FMTWAVE: return 16
    return 16
def make_span_blocks(lo, hi, extra_rows={}):
    starts = sorted(a for a in r.labels if lo <= a < hi and a not in r.code and r.block_of(a) is None)
    for s in starts:
        e = s + 1
        while e < hi and e not in r.code and e not in r.labels and r.block_of(e) is None: e += 1
        cons = datarefs.get(s, (None, False))
        if cons[1]:   # pointer table
            n = (e - s) // 2
            ents = [r.word(s + 2*i) for i in range(n)]
            if all(r.inreg(x) for x in ents) and (e - s) % 2 == 0:
                r.block(s, e - s, lambda rr, a, n=n: ['\tdw ' + ', '.join(rr.sym_addr(rr.word(a+2*i)) for i in range(n))])
                # targets: data rows formatted by the same consumer
                for x in ents:
                    if x not in datarefs: datarefs[x] = (cons[0], False)
                continue
        rs = extra_rows.get(s, rowsize(cons))
        def em(rr, a, size=e-s, rs=rs):
            out = []
            i = 0
            while i < size:
                n = min(rs, size - i)
                out.append('\tdb ' + ', '.join(f'${rr.byte(a+i+k):02x}' for k in range(n)))
                i += n
            return out
        r.block(s, e - s, em)
# pointer-table targets inside spans become labels only if they start a span; others are Label+n
make_span_blocks(0x401d, 0x5244)
make_span_blocks(0x5966, 0x5989, {0x5970: 5})
r.comments[0x5966] = 'pause jingle: 5 steps on ch2 (NR21-NR24, frames)'
r.comments[0x401d] = 'unreferenced'
r.comments[0x7ffd] = 'unreferenced'

# ---------------------------------------------------------------- music data
def be_words(rr, a, n):
    return ['\tdb ' + ', '.join(f'${rr.byte(a+2*i):02x}, ${rr.byte(a+2*i+1):02x}' for i in range(k, min(k+5, n))) for k in range(0, n, 5)]
r.block(0x5acc, 40, lambda rr, a: be_words(rr, a, 20))
r.comments[0x5acc] = 'vibrato (effect type 1): 20 big-endian period offsets, from frame 25 of a note, cycled'
def note_table(rr, a):
    out = [f'\tdw ${rr.word(a):04x}\t; index 0: never played']
    for i in range(72): out.append(f'\tdw ${rr.word(a+2+2*i):04x}\t; {note_name(2+2*i)}')
    return out
r.block(0x5af4, 146, note_table)
WAVES = [0x5b86 + 16*i for i in range(8)]
for wv in WAVES:
    if wv not in r.labels or r.labels[wv].startswith('Data_'): r.label(wv, f'Wave_{wv:04X}')
    r.block(wv, 16, lambda rr, a: ['\tdb ' + ', '.join(f'${rr.byte(a+i):02x}' for i in range(16))])
def noise_table(rr, a):
    out = ['\tdb ' + ', '.join(f'${rr.byte(a+i):02x}' for i in range(6)) + '\t; (offsets 0-5)']
    for k in range(1, 6):
        q = a+1+5*k
        out.append('\tdb ' + ', '.join(f'${rr.byte(q+i):02x}' for i in range(5)) + f'\t; pattern byte ${1+5*k:02x}: NR42, flag, NR41, NR43, NR44')
    return out
r.block(0x5c06, 31, noise_table)
r.comments[0x5c06] = 'ch4 drums. Pattern byte $1F is not looked up here: it plays ch4 effect 3.'
LT = [0x5c25 + 15*i for i in range(9)]
for t in LT:
    if t not in r.labels: r.label(t, f'LengthTable_{t:04X}')
    r.block(t, 15, lambda rr, a: ['\tdb ' + ', '.join(f'${rr.byte(a+i):02x}' for i in range(15))])
r.block(0x5cac, 7, lambda rr, a: ['\tdb ' + ', '.join(f'${rr.byte(a+i):02x}' for i in range(7)) + '\t; NRx2 at the release point, index = low nibble of InstrRelease'])
def pan_table(rr, a):
    return [f'\tdb ' + ', '.join(f'${rr.byte(a+6*i+k):02x}' for k in range(6)) + f'\t; song {i+1:02d}: mode, period, NR51 x4' for i in range(42)]
r.block(0x52f7, 252, pan_table)
r.block(0x5244, 84, lambda rr, a: ['\tdw ' + rr.sym_addr(rr.word(a+2*i)) for i in range(42)])

LEN_NAMES = ['L32','L16','L8','L4','L2','L1','L8D','L4D','L2D','L8T','L4T','LEN11','LEN12','LEN13','LEN14','LEN15']
cmds = {0x9d:('INSTR',['instr']), 0x9e:('TEMPO',['lentab']), 0x9f:('TRANSPOSE',['b']), 0x9b:('REPEAT',['b']), 0x9c:('REPEAT_END',[]),
        0x99:('CH3_FADE_ON',[]), 0x9a:('CH3_FADE_OFF',[]), 0x97:('DROP_ON',[]), 0x98:('DROP_OFF',[]), 0x95:('BEND_ON',[]), 0x96:('BEND_OFF',[])}
songs = Songs(r, {'song_table':0x5244, 'song_count':42, 'cmds':cmds, 'len_names':LEN_NAMES,
                  'hdr_size':13, 'hdr_len':[1, 3], 'hdr_ch':5,
                  'noise_names':{**{1+5*k: f'NOISE{k}' for k in range(1,6)}, 0x1f: 'SFX_DRUM'}}).parse()
songs.register()
r.collect_refs()
song_end = max(max(songs.pat_events[p][1] for p in songs.pat_events), max(a+2 for a in songs.list_words))
print('songs', len(songs.headers), 'patterns', len(songs.patterns), 'lists', len(songs.lists), 'song data ends', hex(song_end),
      'waves', sorted(hex(x) for x in songs.waves), 'lentabs', sorted(hex(x) for x in songs.lentabs), 'unterminated', sorted(hex(x) for x in songs.unterminated))

# ---------------------------------------------------------------- comments
C = {
 0x4000: 'Called once at boot. The game also calls $4003, inside the first clear loop: that\nclears from whatever hl holds to the end of its page, then $A500-$A5FF, and resets NR50-NR52.',
 0x402d: 'Stop entry: the stop routine itself sits after the song data, at $7F5E.',
 0x4030: 'Called once per frame. Order: pause request (1 pause, 2 resume) -> pause jingle ->\nsong request -> SFX ch1 -> SFX ch3 -> SFX ch4 -> music, then clear the requests.\nwQuietMusic non-zero sets NR50 = $33 instead of $77.',
 0x407e: 'SFX on ch1 (wSfx1Request = 1-24): init routine and per-frame routine',
 0x40de: 'Effects 9, 12, 15, 16, 17, 19, 20, 23 always start; the others are refused while a\npriority effect plays (wSfx1Priority), unless wVibrato is non-zero.',
 0x4680: 'Start a ch1 effect: hl = 5 register bytes + frames. Priority: ordinary effects are\nrefused until this one ends. Interruptible: priority, but sets wVibrato, which lets any\neffect through (wVibrato is also ch1\'s vibrato counter; a ch1 music note clears it).',
 0x46fa: 'SFX on ch3 (wSfx3Request = 1-24)',
 0x4e42: 'Effect 19 on ch3: init and per-frame routine are both this ret.',
 0x4e64: 'SFX on ch4 (wSfx4Request = 1-11)',
 0x51a6: 'hl = table, a = 1-based index: hl = table[a-1]',
 0x51b3: 'de = timer: decrement, Z when it reaches 0. bc = step: increment.',
 0x51bb: 'Write a register image and store the following byte as the new timer ([de]).',
 0x5214: 'Add a big-endian offset (table[step-1]) to the effect\'s period and write NRx3/NRx4.',
 0x52b4: 'Unreferenced: save $A410-$A449 to $A490 and restore it. Both loops test the wrong\nregister\'s low byte (e in the save, l in the restore) against $4A, so each copies\n186 bytes instead of 58.',
 0x52e0: 'a = wSongRequest (1-42, $FF = stop), hl = wSongPlaying.',
 0x5421: 'Panning: mode 1 = fixed; otherwise cycle through the four NR51 values every period\nframes. All 42 songs use mode 1, NR51 = $FF.',
 0x545a: 'Songs 2, 3, 12, 15, 24 clear wFastMusic, song 9 sets it, every other song keeps it.\nWith wFastMusic the header\'s transpose gets +4 (2 semitones) and the second length\ntable is used.',
 0x5510: '$9D: three bytes to Env/Release/Duty (ignored while wInstrumentLock is set).\nch3: wave pointer, loaded unless a ch3 effect plays.',
 0x5565: 'Frame without a new note: ch3 level-bit-7 release, pitch effects, release envelope.',
 0x559b: '$00: next list entry; $00xx ends the song (Sound_Stop), $FFxx loops.',
 0x5638: 'Music: four 16-byte channel structures at wCh1ListPtr + $10*n.',
 0x5655: 'Commands $95-$9F, lengths $A0-$AF. A length also sets the release point when the\ninstrument\'s Release byte has a high nibble: bit 7 = half the length, bit 6 = a quarter,\notherwise three quarters (at least 2), stored in wReleaseFrame (ch1/ch2).',
 0x56e7: 'Note: restart the bend / vibrato / drop / ch3-fade state of the channel.',
 0x5788: 'Noise byte $1F: start ch4 effect 3 instead of a drum (unless an effect owns ch4).',
 0x579b: 'Write the note: NRx1 = Duty, NRx2 = Env (rest: $08), period, NRx4 | $80 (trigger, no length).',
 0x5817: 'Pitch effect from the low nibble of Duty: 1 = vibrato table after 24 frames,\n2-15 = period - 1. Then bend, drop and ch3 fade.',
 0x5899: 'Release: at NoteFrames = wReleaseFrame, write ReleaseEnvelopes[low nibble - 1] to\nNRx2 and retrigger (ch1, ch2 only).',
 0x58f7: 'Pause: mute, cancel the effects and play a 5-step jingle on ch2.',
 0x5989: '$99/$9A: ch3 fade on/off. NR32: 50% on frame 3, 25% on 5, mute on 7, 25% on 10,\nmute on 13, then the fade stops.',
 0x59cc: '$97/$98: drop on/off: the period falls by 100 every frame.',
 0x59ff: '$95/$96: bend on/off: start 4 below the note and rise 1 per frame.',
 0x7f5e: 'Stop everything: NR51 = $FF, clear the music, effects, pause and effect state, mute.',
}
for a, t in C.items(): r.comments[a] = t

parts = r.emit_split([(0x4000, 0x5244), (0x5244, 0x5acc), (0x5acc, 0x5cb3), (0x5cb3, song_end), (song_end, 0x8000)])
def w(name, body): open(os.path.join(OUT, name), 'w').write(body)
w('SML2_SFX.inc', '; Super Mario Land 2 sound driver: init, update, SFX code and data, bank 4 $4000-$5243\n\n' + parts[0])
w('SML2_Music.inc', '; Super Mario Land 2 sound driver: song table, music code, bank 4 $5244-$5ACB\n\n' + parts[1])
w('SML2_Tables.inc', '; Super Mario Land 2 sound driver: tables, bank 4 $5ACC-$5CB2\n\n' + parts[2])
w('SML2_Songs.inc', f'; Super Mario Land 2 songs, bank 4 $5CB3-${song_end-1:04X}\n\n' + parts[3])
w('SML2_Stop.inc', f'; Super Mario Land 2 sound driver: stop routine, bank 4 ${song_end:04X}-$7FFF\n\n' + parts[4])
lines = ['; Super Mario Land 2 sound RAM (cartridge RAM)', 'IF !DEF(SML2_RAM_INC)', 'DEF SML2_RAM_INC EQU 1']
for a in sorted(RAM):
    if '+' not in RAM[a]: lines.append(f'DEF {RAM[a]:<20} EQU ${a:04X}')
lines.append('ENDC')
w('SML2_RAM.inc', '\n'.join(lines) + '\n')
os.makedirs(os.path.join(OUT, 'harness'), exist_ok=True)
sfxdata = [[a, a + s, r.labels.get(a, '')] for a, (s, e) in r.blocks.items() if 0x401d <= a < 0x5244 or 0x5966 <= a < 0x5989 or a in WAVES or 0x5acc <= a < 0x5cb3]
json.dump({'patterns': {f'{p:04x}': [p, songs.pat_events[p][1]] for p in songs.pat_events},
           'list_words': sorted(set(sum(([a, a+1] + ([a+2, a+3] if songs.list_words[a][0] == 'loop' else []) for a in songs.list_words), []))),
           'sfxdata': sfxdata}, open(os.path.join(OUT, 'harness', 'model.json'), 'w'))
