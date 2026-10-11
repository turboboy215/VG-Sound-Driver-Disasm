"""Generate the Dr. Mario (GB) sound driver sources (bank 1, $6000-$7FFF)."""
import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'tools'))
from gbdis import Region, decode
from tanaka import Songs, note_name

ROM = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', 'Dr. Mario (W) (V1.0) [!].gb')
OUT = sys.argv[2] if len(sys.argv) > 2 else HERE
rom = open(ROM, 'rb').read()
r = Region(rom, 1, 0x6000, 0x8000)

# ---------------------------------------------------------------- RAM
RAM = {
 0xdf70:'wMusicChannel', 0xdf71:'wSfxId',
 0xdf78:'wPanMode', 0xdf79:'wPanTimer', 0xdf7a:'wPanPeriod', 0xdf7b:'wPanToggle', 0xdf7c:'wPanNR51A', 0xdf7d:'wPanNR51B',
 0xdf7e:'wPauseTimer', 0xdf7f:'wPauseRequest',
 0xdf80:'wTranspose', 0xdf81:'wLengthTable', 0xdf82:'wLengthTable+1',
 0xdf88:'wSongDanceSpeed', 0xdf89:'wSong0AEnded', 0xdf8a:'wDangerBeep', 0xdf8b:'wForceSfx0A',
 0xdf8d:'wPitchUpTimer', 0xdf8e:'wPitchUpTimer+1', 0xdf8f:'wPitchUpLevel',
 0xdfe0:'wSfx1Request', 0xdfe1:'wSfx1Playing', 0xdfe2:'wSfx1Timer', 0xdfe3:'wSfx1Period', 0xdfe4:'wSfx1Step', 0xdfe5:'wSfx1Var',
 0xdfe6:'wSfx1PtrA', 0xdfe7:'wSfx1PtrA+1', 0xdfee:'wSfx1PtrB', 0xdfef:'wSfx1PtrB+1',
 0xdfe8:'wSongRequest', 0xdfe9:'wSongPlaying',
 0xdff0:'wSfx3Request', 0xdff1:'wSfx3Playing', 0xdff4:'wSfx3Step', 0xdff5:'wSfx3Var', 0xdff6:'wSfx3Var2',
 0xdff8:'wSfx4Request', 0xdff9:'wSfx4Playing', 0xdffc:'wSfx4Step',
}
CHF = {0:'ListPtr',1:'ListPtr+1',2:'LenCounter',3:'Length',4:'PatPtr',5:'PatPtr+1',6:'InstrEnv',7:'InstrFlag',8:'InstrDuty',
       9:'Freq',10:'Freq+1',11:'Rest',12:'RepeatPtr',13:'RepeatPtr+1',14:'NoteFrames',15:'Flags'}
for n in range(4):
    base = 0xdf90 + 0x10*n
    for o, f in CHF.items(): RAM[base+o] = f'wCh{n+1}{f}'
r.ram = RAM

# ---------------------------------------------------------------- code
r.trace([0x65c0, 0x6507, 0x66a4, 0x7ff0, 0x7ff3, 0x7ff6])
SFX1_INIT = r.jumptable(0x6000, 14, 'Sfx1_InitTable')
SFX1_PLAY = r.jumptable(0x601c, 14, 'Sfx1_PlayTable')
SFX4_INIT = r.jumptable(0x6038, 3, 'Sfx4_InitTable')
SFX4_PLAY = r.jumptable(0x603e, 3, 'Sfx4_PlayTable')
r.code_range(0x641d, 0x6471)   # ch3 SFX start/stop: nothing calls it

N = {
 0x6058:'Sfx1_IsBusy_8ABD', 0x605d:'Sfx1_IsBusy_C8ABD', 0x6063:'Sfx1_IsBusy_C8ABD.check', 0x6070:'Sfx1_IsBusy_456', 0x6076:'Sfx1_IsBusy_56',
 0x614e:'Sfx1_PlayOneStep', 0x6153:'Sfx1_Stop', 0x6285:'Sfx1_PlayTwoChannelSequence', 0x62cb:'Sfx1_PlayTwoChannelSequence.end',
 0x62d2:'Sfx1_PlayTwoChannelSequence.stop', 0x62d8:'Sfx1_PlayTwoChannelSequence.requestSong0A', 0x62b4:'Sfx1_PlayTwoChannelSequence.write',
 0x625b:'Sfx1_SetSequencePtrB_hi', 0x6323:'Sfx1_WriteEnvFreq',
 0x640b:'Sfx4_Stop', 0x641d:'Sfx3_Stop_Unused', 0x6443:'Sfx3_Stop_Unused.song05', 0x6448:'Sfx3_Start_Unused', 0x646d:'Sfx3_LoadWave_Unused',
 0x6471:'Sfx_ReleaseCh2', 0x647f:'Sfx_Start', 0x64a0:'Sfx_Start.ch1', 0x64a8:'Sfx_Start.ch3', 0x64b0:'Sfx_Start.ch4',
 0x64b8:'SetRegs_Ch1', 0x64bf:'SetRegs_Ch2', 0x64c6:'SetRegs_Ch3', 0x64cd:'SetRegs_Ch4', 0x64d2:'SetRegs_Copy',
 0x64da:'Sfx_GetInitPointer', 0x64de:'GetPointer', 0x64ed:'Sfx_Tick', 0x64f8:'Sfx_Tick.done',
 0x64fa:'LoadWave', 0x64fd:'LoadWave.loop',
 0x6507:'Sound_Stop', 0x6514:'Sound_ClearState', 0x653f:'Sound_MuteChannels',
 0x6555:'Sfx1_Update', 0x6563:'Sfx1_Update.playing', 0x656f:'Sfx1_Update.done',
 0x6570:'Sfx4_Update', 0x657e:'Sfx4_Update.playing', 0x658a:'Sfx4_Update.done',
 0x658b:'SongDanceSpeedTable', 0x6596:'Music_StopSong', 0x6599:'Music_StartSong',
 0x65c0:'Sound_Update', 0x65d3:'Sound_Update.main', 0x65e5:'Sound_Update.dangerBeep', 0x6614:'Sound_Update.setBeep',
 0x6618:'Sound_Update.sfx', 0x6625:'Sound_Update.music', 0x6628:'Sound_Update.clearRequests', 0x663c:'Sound_Update.startSong',
 0x6641:'Sound_Update.pause', 0x666d:'Sound_Update.jingleA', 0x6670:'Sound_Update.writeJingle', 0x6675:'Sound_Update.jingleB',
 0x667a:'Sound_Update.unpause', 0x6684:'Sound_Update.paused',
 0x669c:'PauseJingleA', 0x66a0:'PauseJingleB',
 0x66a4:'Sound_Init', 0x66b3:'Sound_Init.clear', 0x66b8:'Sound_Init.ret',
 0x66b9:'Music_InitPanning', 0x66bf:'Music_InitPanning.find', 0x66c8:'Music_InitPanning.found',
 0x66e2:'Music_UpdatePanning', 0x66fd:'Music_UpdatePanning.write',
 0x6700:'CopyWordIndirect', 0x670b:'CopyWord', 0x6711:'Music_LoadHeader', 0x6761:'Music_LoadHeader.initCounters',
 0x6774:'Cmd_Instrument.wave', 0x6780:'Cmd_Instrument', 0x67aa:'Music_NextByte',
 0x67b0:'IncPtr', 0x67b6:'IncPtr.store', 0x67bc:'IncPtr2', 0x67c5:'ReadPtrByte',
 0x67cc:'Music_Sustain.skip', 0x67cf:'Music_Sustain', 0x67e6:'Music_Sustain.effects', 0x67fb:'Music_ChannelDone',
 0x6800:'Cmd_PatternEnd', 0x6807:'Cmd_PatternEnd.loadPattern', 0x681b:'Cmd_PatternEnd.loop', 0x6832:'Cmd_PatternEnd.songEnd',
 0x683f:'Cmd_PatternEnd.stop',
 0x6845:'Cmd_Tempo', 0x6859:'Cmd_Transpose', 0x6862:'Cmd_SkipAndContinue', 0x6867:'Cmd_RepeatStart', 0x688b:'Cmd_RepeatEnd', 0x68a4:'Cmd_RepeatEnd.done',
 0x68a7:'Music_Update', 0x68be:'Music_Update.notPitchUp3', 0x68c1:'Music_Update.channels', 0x68cc:'Music_ChannelLoop',
 0x68d6:'Music_ReadPattern', 0x68d8:'Music_ReadCommand',
 0x6919:'Music_Note', 0x6946:'Music_Note.addTranspose', 0x6949:'Music_Note.pitchUp', 0x696d:'Music_Note.pitchUpLoop', 0x6972:'Music_Note.lookup',
 0x697f:'Music_Note.rest', 0x6984:'Music_NoiseNote', 0x698c:'Music_NoiseNote.copy',
 0x699b:'Music_Trigger', 0x69b5:'Music_Trigger.ch3', 0x69c9:'Music_Trigger.ch2', 0x69cd:'Music_Trigger.ch1', 0x69d2:'Music_Trigger.readInstr',
 0x69db:'Music_Trigger.readDuty', 0x69de:'Music_Trigger.write', 0x69e7:'Music_Trigger.notRest', 0x69ff:'Music_Trigger.done',
 0x6a04:'Music_NextChannel', 0x6a15:'Music_NextChannel.allDone', 0x6a22:'Music_Trigger.flagSet',
 0x6a29:'Vibrato_GetStep', 0x6a32:'Music_Vibrato', 0x6a54:'Music_Vibrato.done', 0x6a56:'Music_Vibrato.apply',
 0x6a70:'Music_Vibrato.detune', 0x6a75:'Music_Vibrato.type2', 0x6a7a:'Music_Vibrato.type1', 0x6a7d:'Music_Vibrato.readTable',
 0x6a86:'Music_Vibrato.nibble', 0x6a93:'Music_Vibrato.positive', 0x6a95:'Music_Vibrato.signed', 0x6a96:'Music_Vibrato.add',
 0x6a9f:'VibratoTable_Fall', 0x6abd:'VibratoTable_Wobble', 0x6af4:'VibratoTable_Wobble.tail',
 0x6b12:'NoteTable', 0x6ba4:'NoiseTable',
 0x6c80:'SongPanTable',
 0x7ff0:'Sound_UpdateStub', 0x7ff3:'Sound_StopStub', 0x7ff6:'Sound_InitStub',
}
for a, n in N.items(): r.label(a, n)

# SFX naming: trace each effect separately and name its private code and data
SHARED = {0x647f, 0x64b8, 0x64bf, 0x64c6, 0x64cd, 0x64ed, 0x6153, 0x614e, 0x6058, 0x605d, 0x6070, 0x6076, 0x6471, 0x6285, 0x640b, 0x66b8, 0x6323, 0x625b}
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
def name_sfx(ch, i, init, play):
    tag = f'Sfx{ch}_{i:02X}'
    if init not in SHARED and init not in N: r.label(init, f'{tag}_Init')
    if play not in SHARED and play not in N and play not in r.labels: r.label(play, f'{tag}_Play')
    k = 0
    for pc in sorted(owned([init, play])):
        l, fmt, args, kind = r.code[pc]
        for t, v in args:
            if t in ('rel','jp','call') and v in r.code and v not in r.labels and v not in SHARED:
                r.label(v, f'{tag}_Play.l{k}' if v > play and play not in SHARED else f'{tag}_Init.l{k}'); k += 1
            pass
for i, (a, b) in enumerate(zip(SFX1_INIT, SFX1_PLAY)): name_sfx(1, i+1, a, b)
RAM[0xdf00] = 'wSoundRAM'
for i, (a, b) in enumerate(zip(SFX4_INIT, SFX4_PLAY)): name_sfx(4, i+1, a, b)

# ---------------------------------------------------------------- SFX data blocks
def dblock(addr, size, name, comment=None, per=16):
    r.label(addr, name, comment)
    def em(rr, a, size=size, per=per):
        out = []
        for i in range(0, size, per):
            n = min(per, size-i)
            out.append('\tdb ' + ', '.join(f'${rr.byte(a+i+k):02x}' for k in range(n)))
        return out
    r.block(addr, size, em)
CH1 = 'NR10-NR14 image'; CH2 = 'NR21-NR24 image'; CH4 = 'NR41-NR44 image'
SFXDATA = [
 (0x6080, 5, 'Sfx1_03_Regs', CH1), (0x6095, 5, 'Sfx1_0A_Regs', CH1), (0x60bc, 5, 'Sfx1_07_Regs', CH1),
 (0x60d1, 5, 'Sfx1_0E_Regs1', CH1), (0x60d6, 5, 'Sfx1_0E_Regs2', CH1),
 (0x60f7, 5, 'Sfx1_01_Regs1', CH1), (0x60fc, 5, 'Sfx1_01_Regs2', CH1), (0x6125, 5, 'Sfx1_02_Regs', CH1),
 (0x6167, 5, 'Sfx1_09_Regs1', CH1), (0x616c, 5, 'Sfx1_09_Regs2', CH1),
 (0x61a6, 5, 'Sfx1_08_Regs1', CH1+' (its NR14 byte is also read by Sfx1_PlayTwoChannelSequence)'),
 (0x61ab, 16, 'Sfx1_08_SeqA', 'ch1 NR13 per step, $FF = end'),
 (0x61bb, 4, 'Sfx1_08_Regs2', CH2), (0x61bf, 16, 'Sfx1_08_SeqB', 'ch2 NR23 per step (0 = both channels silent)'),
 (0x61cf, 5, 'Sfx1_0B_Regs1', CH1+' (its NR13 byte is read as the NR24 value of every sequence step)'),
 (0x61d4, 8, 'Sfx1_0B_SeqA', 'ch1 NR13 per step, $FF = end'),
 (0x61dc, 4, 'Sfx1_0B_Regs2', CH2), (0x61e0, 8, 'Sfx1_0B_SeqB', 'ch2 NR23 per step'),
 (0x61e8, 5, 'Sfx1_0D_Regs1', CH1), (0x61ed, 4, 'Sfx1_0D_Regs2', CH2),
 (0x61f1, 16, 'Sfx1_0D_SeqA', 'ch1 NR13 per step, $FF = end'), (0x6201, 16, 'Sfx1_0D_SeqB', 'ch2 NR23 per step'),
 (0x62df, 5, 'Sfx1_06_Regs', CH1), (0x62e4, 11, 'Sfx1_06_Env', 'NR12 per step, 0 = end'), (0x62ef, 10, 'Sfx1_06_Freq', 'NR13 per step'),
 (0x632e, 5, 'Sfx1_05_Regs', CH1), (0x6333, 9, 'Sfx1_05_Env', 'NR12 per step, 0 = end'), (0x633c, 8, 'Sfx1_05_Freq', 'NR13 per step'),
 (0x6370, 5, 'Sfx1_0C_Regs', CH1), (0x6375, 9, 'Sfx1_0C_Env', 'NR12 per step, 0 = end'), (0x637e, 8, 'Sfx1_0C_Freq', 'NR13 per step'),
 (0x63b3, 5, 'Sfx1_04_Regs', CH1),
 (0x63cb, 4, 'Sfx4_02_Regs', CH4), (0x63cf, 8, 'Sfx4_02_NR43', 'NR43 per step, cycled'), (0x63fa, 4, 'Sfx4_01_Regs', CH4),
 (0x669c, 4, 'PauseJingleA', CH2), (0x66a0, 4, 'PauseJingleB', CH2),
]
for a, n, nm, c in SFXDATA: dblock(a, n, nm, c)
# split pointers loaded as two immediates
for pc, sym in [(0x6224,'LOW(Sfx1_0D_SeqA)'), (0x6229,'HIGH(Sfx1_0D_SeqA)'), (0x622e,'LOW(Sfx1_0D_SeqB)'), (0x6233,'HIGH(Sfx1_0D_SeqB)'),
                (0x624a,'LOW(Sfx1_08_SeqA)'), (0x624f,'HIGH(Sfx1_08_SeqA)'), (0x6254,'LOW(Sfx1_08_SeqB)'), (0x6259,'HIGH(Sfx1_08_SeqB)'),
                (0x6272,'LOW(Sfx1_0B_SeqA)'), (0x6277,'HIGH(Sfx1_0B_SeqA)'), (0x627c,'LOW(Sfx1_0B_SeqB)'), (0x6281,'HIGH(Sfx1_0B_SeqB)')]:
    r.overrides[pc] = {0: sym}
r.overrides[0x6a70] = {0: '-2'}

# ---------------------------------------------------------------- comments
C = {
 0x6000: 'SFX on ch1 (request wSfx1Request = 1-14): init routine, then per-frame routine',
 0x6038: 'SFX on ch4 (request wSfx4Request = 1-3)',
 0x6044: 'song number 1-10 -> header',
 0x6058: 'Priority checks on the SFX playing on ch1. Each returns Z (= do not start) when\na protected effect is playing.',
 0x614e: 'Shared per-frame routine of one-image effects: stop when the period elapses.',
 0x6153: 'Stop the ch1 effect and give the channel back to the music.',
 0x6285: 'Effects 8, 11 and 13 play two square channels in step: each step sets NR13 from\nsequence A and NR23 from sequence B. Both envelopes are $F2, or $08 (off) where\nsequence B is 0. Sequence A $FF ends the effect; effect 13 then requests song 10.',
 0x6323: 'Effects 5, 6, 12: NR12 = e, NR13 = d, NR14 = b (no length, trigger).',
 0x63fe: 'ch4 effects',
 0x641d: 'Unreferenced: ch3 effect support. Sfx3_Start_Unused takes every channel (bit 7 of\nwChNFlags) and loads a wave; Sfx3_Stop_Unused releases them and reloads the wave of the\nsong (song 5 uses a different one). Sound_Update never reads wSfx3Request.',
 0x6471: 'Release ch2 after a two-channel effect.',
 0x647f: 'Start an effect. a = frames per step, hl = register image, de = wSfxNRequest+2.\nSets Playing = wSfxId, Period = a, clears Timer/Step/Var, marks the channel as taken\n(bit 7 of wChNFlags: the music stops writing it) and writes the image.',
 0x64b8: 'Write a register image: ch1 NR10-NR14, ch2 NR21-NR24, ch3 NR30-NR34, ch4 NR41-NR44.',
 0x64da: 'a = SFX number, hl = table: hl = table[a-1] (de advanced to the channel variables).',
 0x64ed: 'Count frames: returns a = 0 once every wSfxNPeriod frames (de = wSfxNTimer).',
 0x64fa: 'Copy 16 bytes from hl to wave RAM.',
 0x6507: 'Stop everything: sound RAM state, music, effects, pause; mute the channels.',
 0x653f: 'Mute ch1, ch2, ch4 (envelope 0 + trigger), clear the sweep and turn ch3 off.',
 0x6555: 'Start a requested ch1 effect, or run the one playing.',
 0x658b: 'Copied to wSongDanceSpeed when a song starts. The game reads it as the speed of\nthe dancing viruses.',
 0x6599: 'a = wSongRequest ($FF = stop), hl = wSongPlaying.',
 0x65c0: 'Called once per frame (stub at $7FF0).\nOrder: pause request -> pause jingle -> song request -> SFX ch1 -> SFX ch4 -> music,\nthen clear every request. Pause requests: wPauseRequest = 1 pause, 2 resume.',
 0x65da: 'wForceSfx0A: one-shot request of effect 10. wDangerBeep: keep requesting effect 9\n(as long as effects 8, 10, 11 are not requested or playing).',
 0x6641: 'Pause: mute, cancel the effects, load the default wave and play a 4-note jingle on\nch2 (frames $30, $28, $20, $18), then hold the timer at $10 until resumed.',
 0x66a4: 'Called once at boot (stub at $7FF6). Its final ret doubles as the "no-op" entry of\nSfx4_PlayTable.',
 0x66b9: 'Song panning: mode 1 = fixed NR51; other modes alternate NR51 A/B every period frames.',
 0x6711: 'hl = song header. Copy transpose, length table and the four list pointers, then\nload each channel\'s first pattern pointer.',
 0x6780: '$9D: three bytes to wChNInstrEnv/Flag/Duty. On ch3 the first two are a wave\npointer, loaded now.',
 0x67b0: 'Pointer helpers on the 16-bit pointer at hl.',
 0x67cf: 'Frame without a new note: ch3 with level bit 7 drops to 50% 6 frames before the\nend; then vibrato, unless the channel is resting or taken by an effect.',
 0x6800: '$00: next entry of the section list. $0000 ends the song (song 10 also sets\nwSong0AEnded); $FFxx loops the list to the address that follows.',
 0x6845: '$9E: length table pointer.',
 0x6859: '$9F: transpose (in note-table bytes, 2 per semitone).',
 0x6867: '$9B n: repeat from here n times. The count lives in bits 0-6 of wChNFlags.',
 0x688b: '$9C: end of the repeated block.',
 0x68a7: 'Music: run the four channels (structure of 16 bytes at wCh1ListPtr + $10*n).',
 0x68d8: 'Read pattern bytes until a note or rest: commands, $A0-$AF lengths.',
 0x6919: 'Note or rest (c = byte). Adds the transpose and the game\'s pitch-up level (+1, +2\nor +3 semitones, plus one more every 256 frames at level 3).',
 0x6984: 'ch4: copy 5 bytes of NoiseTable (env, flag, NR41, NR43, NR44) into the channel.',
 0x699b: 'Write the note: NRx1 = Duty (ch3: 0, or $EF when level bit 7), NRx2 = Env (ch3: NR32\n= level), period, NRx4 | $C0 (trigger + length enable). A rest writes envelope $08.\nNothing is written while an effect owns the channel.',
 0x6a22: 'Flag byte non-zero: the envelope register keeps whatever e holds (the low byte of the\nchannel\'s Freq address, or $CB on ch4). No song uses it.',
 0x6a32: 'Pitch effect from the low nibble of the Duty byte: 1 = wobble table, 2 = fall table\n(both indexed by NoteFrames / 2, one signed nibble per frame), 3-15 = period - 2.\nWrites NRx3/NRx4 without the length-enable bit.',
}
for a, t in C.items(): r.comments[a] = t
E = {
 0x6a54: None,
}
# ---------------------------------------------------------------- data
r.block(0x6044, 20, lambda rr, a: ['\tdw ' + rr.sym_addr(rr.word(a+2*i)) for i in range(10)])
r.label(0x6044, 'SongTable')
r.block(0x658b, 11, lambda rr, a: ['\tdb ' + ', '.join(f'${rr.byte(a+i):02x}' for i in range(11)) + '\t; frames per dance step, index = song (0 unused)'])

def note_table(rr, a):
    out = ['\tdw $0f00\t; index 0: never played ($00 ends a pattern)']
    for i in range(72):
        out.append(f'\tdw ${rr.word(a+2+2*i):04x}\t; {note_name(2+2*i)}')
    return out
r.block(0x6b12, 2+144, note_table)

# noise table: byte $00 + 6 entries of 5 bytes (NR42, flag, NR41, NR43, NR44), indexed by the pattern byte (6, 11, 16 ...)
def noise_table(rr, a):
    out = [f'\tdb ${rr.byte(a):02x}, ${rr.byte(a+1):02x}, ${rr.byte(a+2):02x}, ${rr.byte(a+3):02x}, ${rr.byte(a+4):02x}, ${rr.byte(a+5):02x}\t; (offsets 0-5: not a drum)']
    for k in range(1, 6):
        q = a+1+5*k
        out.append('\tdb ' + ', '.join(f'${rr.byte(q+i):02x}' for i in range(5)) + f'\t; NOISE{k} (pattern byte ${1+5*k:02x})')
    return out
r.block(0x6ba4, 0x6bc3-0x6ba4, noise_table)

# waves: 16-byte patterns between $6BC3 and $6C23
WAVES = [0x6bc3, 0x6bd3, 0x6be3, 0x6bf3, 0x6c03, 0x6c13]
for w in WAVES:
    r.label(w, f'Wave_{w:04X}')
    r.block(w, 16, lambda rr, a: ['\tdb ' + ', '.join(f'${rr.byte(a+i):02x}' for i in range(16))])

# length tables: overlapping; emit $6C23-$6C80 bytewise with labels where songs point
def len_bytes(rr, a):
    out = []; cur = []
    for q in range(0x6c23, 0x6c80):
        if q in rr.labels and q != 0x6c23:
            if cur: out.append('\tdb ' + ', '.join(cur)); cur = []
            out.append(rr.labels[q] + ':')
        cur.append(f'${rr.byte(q):02x}')
    if cur: out.append('\tdb ' + ', '.join(cur))
    return out
r.block(0x6c23, 0x6c80-0x6c23, len_bytes)

def pan_table(rr, a):
    return [f'\tdb ${rr.byte(a+4*i):02x}, ${rr.byte(a+4*i+1):02x}, ${rr.byte(a+4*i+2):02x}, ${rr.byte(a+4*i+3):02x}\t; song {i+1:02d}: mode, period, NR51 A, NR51 B' for i in range(10)]
r.block(0x6c80, 40, pan_table)

LEN_NAMES = ['L32','L16','L8','L4','L2','L1','L8D','L4D','L2D','L8T','L4T','LEN11','LEN12','LEN13','LEN14','LEN15']
cmds = {0x9d:('INSTR',['instr']), 0x9e:('TEMPO',['lentab']), 0x9f:('TRANSPOSE',['b']), 0x9b:('REPEAT',['b']), 0x9c:('REPEAT_END',[])}
songs = Songs(r, {'song_table':0x6044, 'song_count':10, 'cmds':cmds, 'len_names':LEN_NAMES,
                  'noise_names':{1+5*k: f'NOISE{k}' for k in range(1,6)}}).parse()
songs.register()
r.label(0x6c23, 'LengthTables')

r.collect_refs()
# split output files
parts = r.emit_split([(0x6000, 0x6a9f), (0x6a9f, 0x6ca8), (0x6ca8, 0x7fd1), (0x7fd1, 0x8000)])
def w(name, body): open(os.path.join(OUT, name), 'w').write(body)
w('DrM_Driver.inc', '; Dr. Mario sound driver: code and SFX data, bank 1 $6000-$6A9E\n\n' + parts[0])
w('DrM_Tables.inc', '; Dr. Mario sound driver: tables, bank 1 $6A9F-$6CA7\n\n' + parts[1])
w('DrM_Songs.inc', '; Dr. Mario songs: headers, section lists, patterns, bank 1 $6CA8-$7FD0\n\n' + parts[2])
w('DrM_Stubs.inc', '; padding and the driver entry stubs, bank 1 $7FD1-$7FFF\n\n' + parts[3])
print('patterns', len(songs.patterns), 'lists', len(songs.lists), 'waves', sorted(hex(x) for x in songs.waves), 'instr flags', sorted(set((i[3]) for i in songs.instr)))

# RAM include
lines = ['; Dr. Mario sound RAM ($DF00 page)', 'IF !DEF(DRM_RAM_INC)', 'DEF DRM_RAM_INC EQU 1']
for a in sorted(RAM):
    n = RAM[a]
    if '+' in n: continue
    lines.append(f'DEF {n:<20} EQU ${a:04X}')
lines.append('ENDC')
w('DrM_RAM.inc', '\n'.join(lines) + '\n')

# parse model for the harness
import json
model = {
 'patterns': {f'{p:04x}': [p, songs.pat_events[p][1]] for p in songs.pat_events},
 'list_words': sorted(set(sum(([a, a+1] + ([a+2, a+3] if songs.list_words[a][0] == 'loop' else []) for a in songs.list_words), []))),
 'lists': sorted(songs.lists),
 'sfxdata': [[a, a+n, nm] for a, n, nm, c in SFXDATA] + [[wv, wv+16, 'wave'] for wv in WAVES],
}
json.dump(model, open(os.path.join(OUT, 'harness', 'model.json'), 'w'))
