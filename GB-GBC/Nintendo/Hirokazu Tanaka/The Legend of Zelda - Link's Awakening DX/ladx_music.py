"""Music half of the Link's Awakening DX sound driver (banks $1B and $1E).

Bank $1B is labelled by hand (NAMES_1B); every other copy of the music driver (bank $1E, and the
SMB Deluxe / Metal Slug 2 descendants) gets its names by aligning its code against bank $1B
(tools/transfer.py), plus a few hand-written names for the code it doesn't share."""
import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'tools'))
from gbdis import Region, decode
from tanaka import Songs, note_name
from transfer import align, transfer_labels

# ---------------------------------------------------------------- RAM ($D300-$D3FF, shared with the SFX bank)
RAM = {
 0xd300:'wTranspose', 0xd301:'wLengthTable', 0xd302:'wLengthTable+1',
 0xd307:'wReleaseFrame', 0xd308:'wReleaseFrame+1',
 0xd350:'wMusicChannel', 0xd351:'wPitchEffect',
 0xd355:'wPanMode', 0xd356:'wPanTimer', 0xd357:'wPanPeriod', 0xd358:'wPanStep', 0xd359:'wPanNR51',
 0xd35a:'wPanNR51+1', 0xd35b:'wPanNR51+2', 0xd35c:'wPanNR51+3',
 0xd360:'wSfx1Request', 0xd361:'wSfx1Playing', 0xd368:'wSongRequest', 0xd369:'wSongPlaying',
 0xd370:'wSfx3Request', 0xd371:'wSfx3Playing', 0xd378:'wSfx4Request', 0xd379:'wSfx4Playing',
 0xd390:'wSfx1Timer', 0xd391:'wSfxTimer2', 0xd392:'wSfx3Timer', 0xd393:'wSfx4Timer',
 0xd394:'wSfx1Step', 0xd395:'wSfxStep2', 0xd396:'wSfx3Step', 0xd398:'wSfx4Step',
 0xd39e:'wCh3FadeOut', 0xd39f:'wCh3FadeOutTimer',
 0xd3a0:'wSfx1Var', 0xd3a1:'wSfxVar2', 0xd3a2:'wSfx3Var', 0xd3a3:'wSfx4Var',
 0xd3a4:'wPitch', 0xd3b0:'wVibrato', 0xd3b6:'wDrop',
 0xd3ca:'wCurrentSong', 0xd3cb:'wPreviousSong', 0xd3cd:'wCh3SfxPaused', 0xd3ce:'wMusicIn1B',
 0xd3d0:'wVibrato2', 0xd3d9:'wCh3FadeIn', 0xd3da:'wCh3FadeInTimer',
 0xd3e7:'wReloadWave',
 0xffbf:'hResumeSong',
}
CHF = {0:'ListPtr',1:'ListPtr+1',2:'LenCounter',3:'Length',4:'PatPtr',5:'PatPtr+1',6:'InstrEnv',7:'InstrRelease',8:'InstrDuty',
       9:'Freq',10:'Freq+1',11:'Rest',12:'RepeatPtr',13:'RepeatPtr+1',14:'NoteFrames',15:'Flags'}
for n in range(4):
    for o, f in CHF.items(): RAM[0xd310 + 0x10*n + o] = f'wCh{n+1}{f}'
for k, base, n in (('wPitch', 0xd3a4, 6), ('wVibrato', 0xd3b0, 6), ('wDrop', 0xd3b6, 6), ('wVibrato2', 0xd3d0, 6)):
    for i in range(1, n):
        RAM.setdefault(base+i, f'{k}+{i}')
RAM[0xd336] = 'wCh3WavePtr'; RAM[0xd337] = 'wCh3WavePtr+1'     # ch3's InstrEnv/InstrRelease hold the wave pointer
RAM[0xd338] = 'wCh3Level'

LEN_NAMES = ['L32','L16','L8','L4','L2','L1','L8D','L4D','L2D','LEN9','LEN10','LEN11','LEN12','LEN13','L1D','LEN15']
CMDS = {0x9d:('INSTR',['instr']), 0x9e:('TEMPO',['lentab']), 0x9f:('TRANSPOSE',['b']), 0x9b:('REPEAT',['b']), 0x9c:('REPEAT_END',[]),
        0x99:('CH3_FADEOUT_ON',[]), 0x9a:('CH3_FADEOUT_OFF',[]), 0x94:('CH3_FADEIN_ON',[]),
        0x97:('DROP_ON',[]), 0x98:('DROP_OFF',[]), 0x96:('CH3_SFX_PAUSE',[]), 0x95:('CH3_SFX_RESUME',[])}

NAMES_1B = {
 0x4009:'Music_Init', 0x400c:'Music_Init.clear',
 0x401e:'Music_Update', 0x4028:'Music_Update.play', 0x402c:'Music_NotInThisBank', 0x4031:'Music_Update.start',
 0x4037:'MusicDrum_Update', 0x4048:'MusicDrum_Update.start', 0x4053:'MusicDrum_Update.playing',
 0x4060:'MusicDrum_StartRegs', 0x4065:'MusicDrum_EndRegs', 0x406a:'MusicDrum_WriteRegs', 0x406e:'MusicDrum_WriteRegs.loop',
 0x4077:'SongTable', 0x40d7:'GetPointer', 0x40e6:'LoadWave', 0x40e9:'LoadWave.loop',
 0x40f3:'StopSfx4', 0x410f:'Music_Stop', 0x413b:'Music_StartSong', 0x414f:'Music_StartSong.not1x',
 0x4156:'Music_StartSong.not2x', 0x415d:'Music_StartSong.not3x', 0x4166:'Music_StartSong.not4x', 0x4172:'Music_StartSong.inBank',
 0x418b:'SongPanTable', 0x42ab:'Music_ReloadWave', 0x42c4:'Music_ReloadWave.loop',
 0x42d5:'Music_InitPanning', 0x42db:'Music_InitPanning.find', 0x42e6:'Music_InitPanning.found',
 0x4303:'Music_UpdatePanning', 0x4327:'Music_UpdatePanning.write',
 0x432b:'CopyWordIndirect', 0x4336:'CopyWord', 0x433c:'Music_LoadHeader', 0x435e:'Music_LoadHeader.load', 0x43ae:'Music_LoadHeader.initCounters',
 0x43c1:'Cmd_Instrument_wave', 0x43d8:'Cmd_Instrument_wave.done', 0x43db:'Cmd_Instrument', 0x4405:'Music_NextByte',
 0x440b:'IncPtr', 0x4411:'IncPtr.store', 0x4417:'IncPtr2', 0x4420:'ReadPtrByte',
 0x4427:'Music_Sustain_skip', 0x442a:'Music_Sustain', 0x4441:'Music_Sustain.effects', 0x445b:'Music_ChannelDone',
 0x4460:'Cmd_PatternEnd', 0x4467:'Cmd_PatternEnd.loadPattern', 0x447b:'Cmd_PatternEnd.loop', 0x4492:'Cmd_PatternEnd.songEnd',
 0x44ad:'Cmd_Tempo', 0x44c1:'Cmd_Transpose', 0x44ca:'Cmd_SkipAndContinue', 0x44cf:'Cmd_RepeatStart', 0x44f3:'Cmd_RepeatEnd', 0x450c:'Cmd_RepeatEnd.done',
 0x450f:'Music_Play', 0x4525:'Music_ChannelLoop', 0x452f:'Music_ReadPattern', 0x4531:'Music_ReadCommand',
 0x459a:'Music_Length.release', 0x45ab:'Music_Length.store', 0x45b1:'Music_Length.storeRelease', 0x45bf:'Music_Length.done',
 0x45c8:'Music_Note', 0x45f8:'Music_Note.fadeIn', 0x4606:'Music_Note.effectsDone', 0x4607:'Music_Note.lookup',
 0x4634:'Music_Note.addTranspose', 0x4637:'Music_Note.table', 0x4644:'Music_Note.rest',
 0x4649:'Music_NoiseNote', 0x4656:'Music_NoiseNote.copy', 0x4667:'Music_NoiseNote.drum',
 0x467a:'Music_Trigger', 0x4696:'Music_Trigger.ch3', 0x46a1:'Music_Trigger.ch2', 0x46a5:'Music_Trigger.ch1', 0x46a8:'Music_Trigger.readInstr',
 0x46af:'Music_Trigger.checkRest', 0x46b8:'Music_Trigger.notRest', 0x46cb:'Music_Trigger.write', 0x46d9:'Music_Trigger.done',
 0x46de:'Music_NextChannel', 0x46ef:'Music_NextChannel.allDone',
 0x46fc:'Music_Effects_ret', 0x46fe:'Music_Effects', 0x4720:'Music_Effects.drop', 0x4749:'Music_Effects.ch3', 0x4762:'Music_Effects.pitch',
 0x4787:'Music_Release', 0x47ae:'Music_Release.ch2', 0x47d2:'Music_ReleaseWrite',
 0x47e5:'Music_ResumeSong', 0x47f1:'Cmd_Ch3SfxPause', 0x47f3:'Cmd_Ch3Sfx.store', 0x47fc:'Cmd_Ch3SfxResume',
 0x47ff:'Cmd_Ch3FadeOutOn', 0x4801:'Cmd_Ch3FadeOut.store', 0x480a:'Cmd_Ch3FadeOutOff',
 0x4810:'Music_Ch3FadeOut', 0x483d:'Music_Ch3Fade.write', 0x4842:'IncByteBC',
 0x4846:'Cmd_DropOn', 0x484e:'Cmd_Drop.store', 0x4855:'Cmd_DropOff', 0x485e:'Music_Drop', 0x486a:'Music_Drop.apply', 0x4874:'Music_Drop.next',
 0x4879:'GetNoteFreq', 0x4884:'WritePitch', 0x4895:'IndexByChannel', 0x489e:'ReadPitch',
 0x48ab:'Music_Vibrato', 0x48c3:'Music_Vibrato.apply', 0x48e4:'Music_Vibrato.wrap', 0x48eb:'Music_Vibrato.first', 0x48f0:'VibratoTable',
 0x4918:'Music_Vibrato2', 0x4927:'Music_Vibrato2.apply', 0x4946:'Music_Vibrato2.wrap', 0x494d:'Vibrato2Table',
 0x498d:'Cmd_Ch3FadeInOn', 0x4998:'Music_Ch3FadeIn',
 0x49c2:'NoteTable', 0x4a54:'NoiseTable', 0x4b13:'ReleaseEnvelopes',
 0x4e2c:'Sound_Stop', 0x4e4a:'Sound_StopMusic', 0x4e57:'Music_ClearState',
}
COMMENTS_1B = {
 0x4000: 'Entry points (same order as the SFX bank): init, stop, update.',
 0x4009: 'Clear $D300-$D3FF and switch the APU on.',
 0x401e: 'Called once per frame (after the SFX bank\'s update). A non-zero wSongRequest starts a\nsong; otherwise the music drum on ch4 and the music itself run.',
 0x402c: 'The requested song lives in the other music bank: drop this bank\'s music.',
 0x4037: 'Pattern byte $FF on ch4 plays this two-step noise drum (wSfx4Request = 1) unless an SFX\nowns ch4.',
 0x40d7: 'hl = table, a = 1-based index: hl = table[a-1] (and e = e+1, a = h).',
 0x40f3: 'Cancel the ch4 SFX and mute ch4.',
 0x410f: 'Song request $FF. Ch4 effects $05, $0C, $1A, $24, $2A, $2E and $3F keep playing; any\nother ch4 effect is cancelled.',
 0x413b: 'Map the song number onto this bank: $01-$10 as is, $31-$40 -> $11-$20,\n$61-$6F -> $21-$2F. Anything else belongs to bank $1E.',
 0x418b: 'Panning: mode (1 = fixed), period, NR51 x4 for each table entry. All entries are fixed $FF.',
 0x42ab: 'Ch3 trigger: reload the music wave first if an SFX overwrote wave RAM (wReloadWave).',
 0x433c: 'Same ch4 effect exceptions as Music_Stop, then load the 11-byte song header.',
 0x43db: '$9D: three bytes to Env/Release/Duty. ch3: wave pointer + level; the wave is loaded\nunless a ch3 SFX plays.',
 0x442a: 'Frame without a new note: ch3 drops to 50% (NR32 = $40) 6 frames before the end of a\nnote when bit 7 of the level is set; then pitch effects and the release envelope.',
 0x4460: '$00: next list entry; $0000 ends the song, $FFFF + address loops.',
 0x4492: 'Song end. Jingles $0F, $10 and $25 then restart the song saved in hResumeSong.',
 0x450f: 'Music: four 16-byte channel structures at wCh1ListPtr + $10*n.',
 0x4531: 'Commands $94-$9F, lengths $A0-$AF. A length also sets the release point when the\ninstrument\'s Release byte has a high nibble: bit 7 = half the length, bit 6 = a quarter,\notherwise three quarters (at least 2), stored in wReleaseFrame (ch1/ch2).',
 0x45c8: 'Note: restart the vibrato / drop state of the channel and the ch3 fades.',
 0x4649: 'ch4: the pattern byte is an offset into NoiseTable (5 bytes: NR42, unused, NR41, NR43,\nNR44); $FF plays the music drum instead.',
 0x467a: 'Write the note: NRx1 = Duty, NRx2 = Env (rest: $08), period, NRx4 | $80. Nothing is\nwritten while an SFX owns the channel (Flags bit 7).',
 0x46fe: 'Pitch effect from the low nibble of Duty: 1 = vibrato after 24 frames, 5 = vibrato 2,\nother non-zero = period - 1 per frame. Then drop and the ch3 fades.',
 0x4787: 'Release: at NoteFrames = wReleaseFrame, write ReleaseEnvelopes[low nibble - 1] to\nNRx2 and retrigger (ch1, ch2 only).',
 0x47f1: '$96 / $95: pause / resume the ch3 SFX (the SFX bank skips its ch3 update).',
 0x47ff: '$99 / $9A: ch3 fade-out on/off. NR32: 50% on frame 3, 25% on 5, mute on 7, 25% on 10,\nmute on 13, then stop.',
 0x4846: '$97 / $98: drop on/off: the period falls by 100 every frame.',
 0x48f0: 'vibrato (effect 1): 20 big-endian period offsets, from frame 25 of a note, cycled',
 0x494d: 'vibrato 2 (effect 5): 32 big-endian period offsets, cycled from the first frame',
 0x498d: '$94: ch3 fade-in: NR32 25% on frame 3, 50% on 5, 100% on 6, then stop.',
 0x4b13: 'NRx2 at the release point, index = low nibble of InstrRelease',
 0x4e2c: 'Stop everything this bank controls: ch4 effect, panning, music, mute.',
 0x4e57: 'Clear the music effect state and mute ch1-ch3.',
}


def song_id_1b(i):
    if i <= 0x10: return i
    if i <= 0x20: return i + 0x20
    if i <= 0x2f: return i + 0x40
    return None
def song_id_1e(i):
    if i <= 0x20: return i + 0x10
    if i <= 0x40: return i + 0x20
    return None


def zero_runs(r, lo, hi, minlen=32):
    out = []; a = lo
    while a < hi:
        if r.byte(a) == 0:
            b = a
            while b < hi and r.byte(b) == 0: b += 1
            if b - a >= minlen: out.append((a, b))
            a = b
        else: a += 1
    return out


def infer_list_channels(r, song_table, song_count, cmds, extra):
    """channel of an unreferenced list = channel of the list its loop jumps into"""
    pre = Songs(r, {'song_table': song_table, 'song_count': song_count, 'cmds': cmds, 'len_names': LEN_NAMES}).parse()
    owner = {}
    for L, chs in pre.lists.items():
        a = L
        while a in pre.list_words:
            owner[a] = chs
            if pre.list_words[a][0] != 'pat': break
            a += 2
    out = {}
    for L, chs in extra.items():
        if chs is not None: out[L] = chs; continue
        a = L
        while r.word(a) >> 8 not in (0, 0xff): a += 2
        t = r.word(a+2) if r.word(a) >> 8 == 0xff else None
        chs = owner.get(t)
        if chs is None:
            chs = set()
            for q in range(L, a, 2): chs |= pre.patterns.get(r.word(q), set())
        out[L] = set(chs or {0})
    return out


def build_music(rom, bank, game, names, comments, song_table, song_count, song_id, entries, note_table, noise_table,
                lentabs, release, vib, vib2, pan_table, extra_cmds=None, extra_code=(), drum_regs=(), fix=None, extra_lists={}, extra_patterns={}, extra_waves=(), ram=None, entry_names=None, cmds=None, pan_count=None):
    r = Region(rom, bank, 0x4000, 0x8000)
    r.ram = dict(RAM if ram is None else ram)
    r.trace(entries + list(extra_code))
    for a, n in names.items(): r.label(a, n)
    for a, t in comments.items(): r.comments[a] = t
    if fix: fix(r)
    # tables
    r.block(song_table, 2*song_count, lambda rr, a: [f'\tdw {rr.sym_addr(rr.word(a+2*i))}\t; ${i+1:02x}' + (f' = song ${song_id(i+1):02x}' if song_id(i+1) else ': not reachable') for i in range(song_count)])
    r.block(pan_table, 6*(pan_count or song_count), lambda rr, a: [f'\tdb ' + ', '.join(f'${rr.byte(a+6*i+k):02x}' for k in range(6)) + f'\t; ${i+1:02x}' for i in range(pan_count or song_count)])
    def be_words(rr, a, n):
        return ['\tdb ' + ', '.join(f'${rr.byte(a+2*i):02x}, ${rr.byte(a+2*i+1):02x}' for i in range(k, min(k+4, n))) for k in range(0, n, 4)]
    r.block(vib, 40, lambda rr, a: be_words(rr, a, 20))
    if vib2: r.block(vib2, 64, lambda rr, a: be_words(rr, a, 32))
    def nt(rr, a):
        out = [f'\tdw ${rr.word(a):04x}\t; index 0: never played']
        for i in range(72): out.append(f'\tdw ${rr.word(a+2+2*i):04x}\t; {note_name(2+2*i)}')
        return out
    r.block(note_table, 146, nt)
    n_noise = (lentabs[0] - noise_table - 1) // 5
    def noise(rr, a, n=n_noise):
        out = [f'\tdb ${rr.byte(a):02x}\t; offset 0']
        for k in range(n):
            q = a+1+5*k
            out.append('\tdb ' + ', '.join(f'${rr.byte(q+i):02x}' for i in range(5)) + f'\t; NOISE_{1+5*k:02X}: NR42, -, NR41, NR43, NR44')
        return out
    r.block(noise_table, 1+5*n_noise, noise)
    for t in lentabs:
        r.label(t, f'LengthTable_{t:04X}')
        r.block(t, 15, lambda rr, a: ['\tdb ' + ', '.join(f'${rr.byte(a+i):02x}' for i in range(15))])
    if release: r.block(release, 7, lambda rr, a: ['\tdb ' + ', '.join(f'${rr.byte(a+i):02x}' for i in range(7))])
    for a in drum_regs:
        r.block(a, 5, lambda rr, a: ['\tdb ' + ', '.join(f'${rr.byte(a+i):02x}' for i in range(5)) + '\t; NR41-NR44, frames'])
    cmds = dict(CMDS if cmds is None else cmds); cmds.update(extra_cmds or {})
    noise_names = {1+5*k: f'NOISE_{1+5*k:02X}' for k in range(n_noise)}; noise_names[0xff] = 'DRUM'
    def sl(n):
        g = song_id(n)
        return f'Song{g:02X}' if g else f'Song{bank:02X}x{n:02X}'
    if extra_lists == 'auto' or any(v is None for v in (extra_lists or {}).values()):
        extra_lists = infer_list_channels(r, song_table, song_count, cmds, extra_lists)
    songs = Songs(r, {'unterminated_comment': 'no PAT_END: continues into the next pattern', 'song_table': song_table, 'song_count': song_count, 'cmds': cmds, 'len_names': LEN_NAMES,
                      'noise_names': noise_names, 'song_label': sl, 'extra_lists': extra_lists, 'extra_patterns': extra_patterns,
                      'song_num_text': lambda n: f'${song_id(n):02x}' if song_id(n) else f'(index ${n:02x})'}).parse()
    for h, nums in songs.song_numbers.items():
        ok = [n for n in nums if song_id(n)]
        if ok: songs.headers[h] = ok[0]
    songs.register()
    for h, nums in songs.song_numbers.items():
        if len(nums) > 1:
            ok = [f'${song_id(n):02x}' for n in nums if song_id(n)]
            bad = [n for n in nums if not song_id(n)]
            t = (('songs ' if len(ok) > 1 else 'song ') + ', '.join(ok)) if ok else ''
            if bad: t += (('; ' if t else '') + f'{len(bad)} unreachable table entr' + ('y' if len(bad) == 1 else 'ies') + ' (' + ', '.join(f'${n:02x}' for n in bad[:4]) + (', ...' if len(bad) > 4 else '') + ')')
            r.comments[h] = t
    for t in songs.lentabs:
        if r.block_of(t) is None:
            r.block(t, 15, lambda rr, a: ['\tdb ' + ', '.join(f'${rr.byte(a+i):02x}' for i in range(15))])
    for w in extra_waves:
        if w not in r.labels: r.label(w, f'Wave_{w:04X}', 'unreferenced')
    for w in list(songs.waves) + list(extra_waves):
        r.block(w, 16, lambda rr, a: ['\tdb ' + ', '.join(f'${rr.byte(a+i):02x}' for i in range(16))])
    for e in sorted(songs.envs):
        if r.block_of(e) is not None: continue
        end = e + 1
        while end < e + 48 and end not in r.labels and r.block_of(end) is None and end not in r.code: end += 1
        r.block(e, end - e, lambda rr, a, n=end-e: ['\tdb ' + ', '.join(f'${rr.byte(a+i):02x}' for i in range(k, min(k+16, n))) for k in range(0, n, 16)])
    r.collect_refs()
    return r, songs


def gen_1b(rom):
    return build_music(rom, 0x1b, 'LADX', NAMES_1B, COMMENTS_1B, 0x4077, 48, song_id_1b, [0x4000, 0x4003, 0x4006], 0x49c2, 0x4a54,
                       [0x4a8c + 15*i for i in range(9)], 0x4b13, 0x48f0, 0x494d, 0x418b, drum_regs=[0x4060, 0x4065],
                       extra_lists={0x708f: {0}, 0x7095: {0}, 0x7129: {3}},
                       extra_patterns={0x6f50: {2}, 0x7044: {0}, 0x705a: {0}, 0x7065: {0}, 0x7077: {0}}, extra_waves=[0x4b26])


def finish(r, songs, lo_songs):
    """add ds blocks for zero runs in unclaimed space; returns end of code / song data boundaries"""
    cov = set()
    for pc, d in r.code.items(): cov.update(range(pc, pc+d[0]))
    for b, (sz, e) in r.blocks.items(): cov.update(range(b, b+sz))
    claimed = lambda a: a in cov
    for a, b in zero_runs(r, lo_songs, 0x8000):
        # trim to unclaimed bytes
        s = a
        while s < b and claimed(s): s += 1
        e = s
        while e < b and not claimed(e): e += 1
        if e - s >= 32 and not any(s < x < e for x in r.labels):
            r.block(s, e - s, lambda rr, a, n=e-s: [f'\tds {n}, 0\t; ${a:04X}-${a+n-1:04X} unused'])
    for b, (sz, e) in r.blocks.items(): cov.update(range(b, b+sz))
    unclaimed = []
    a = 0x4000
    while a < 0x8000:
        if not claimed(a):
            b = a
            while b < 0x8000 and not claimed(b): b += 1
            unclaimed.append((a, b)); a = b
        else: a += 1
    return unclaimed


def transferred_names(rom, bank, ref, entries, extra_code=(), manual={}):
    """names for another copy of the music driver, aligned against the labelled reference region"""
    r = Region(rom, bank, 0x4000, 0x8000)
    r.trace(entries + list(extra_code))
    pcmap, valmap, m, ns, nd = align(ref, r)
    code, ram = transfer_labels(ref, r, pcmap, valmap, ref.ram)
    names = {}
    used = set(manual.values())
    for a, n in sorted(code.items()):
        if a in manual or n in used or n.startswith(('Code_', 'Data_', 'Song', 'Pattern_', 'Wave_', 'LengthTable_', 'UnusedList_')):
            continue
        if a not in r.code and not n[0].isupper(): continue
        names[a] = n; used.add(n)
    names.update(manual)
    # local labels whose parent global did not transfer become globals
    stats = dict(matched=m, ref=ns, this=nd, ram=ram)
    return names, valmap, pcmap, stats


def comments_from_ref(ref_comments, pcmap, valmap, skip=()):
    out = {}
    for a, t in ref_comments.items():
        if a in skip: continue
        b = pcmap.get(a, valmap.get(a))
        if b is not None: out[b] = t
    return out


NAMES_1E_MANUAL = {
 0x4000: None,
 0x402b: 'Music_ClearRequests', 0x4163: 'Music_StartSong', 0x4177: 'Music_StartSong.not1x', 0x417f: 'Music_StartSong.not2x',
 0x4187: 'Music_StartSong.not3x', 0x4193: 'Music_StartSong.inBank', 0x48b8: 'Cmd_Ch3FadeInOn', 0x48c3: 'Music_Ch3FadeIn',
}


def gen_1e(rom, r1b):
    manual = {a: n for a, n in NAMES_1E_MANUAL.items() if n}
    names, valmap, pcmap, st = transferred_names(rom, 0x1e, r1b, [0x4000, 0x4003, 0x4006], manual=manual)
    com = comments_from_ref(COMMENTS_1B, pcmap, valmap, skip={0x401e, 0x402c, 0x413b, 0x46fe})
    com.update({
     0x4000: 'Entry points: init, stop, update.',
     0x401e: 'Called once per frame after bank $1B\'s update. Starts a song from this bank, plays\nthe music, then clears all four request bytes for the next frame.',
     0x402b: 'Clear the song and SFX requests. Also where requests for bank $1B\'s songs end up.',
     0x4163: 'Ignored while bank $1B plays (wMusicIn1B). Map the song number onto this bank:\n$11-$30 -> $01-$20, $41-$60 -> $21-$40.',
     0x4770 - 0x2: None,
    })
    com = {a: t for a, t in com.items() if t}
    com[0x6b78] = 'no PAT_END of its own: the $00 that ends it is the transpose byte of Song4F_Header'
    r, songs = build_music(rom, 0x1e, 'LADX', names, com, valmap[0x4077], 64, song_id_1e, [0x4000, 0x4003, 0x4006],
                           valmap[0x49c2], valmap[0x4a54], [0x4a8e + 15*i for i in range(9)], valmap[0x4b13], valmap[0x48f0], None,
                           valmap[0x418b], drum_regs=[valmap[0x4060], valmap[0x4065]],
                           extra_lists={a: None for a in (0x5531, 0x553b, 0x5545, 0x5745, 0x575f, 0x5791, 0x6792, 0x6d30, 0x78bb, 0x78c7)},
                           extra_patterns={0x6d1b: {0}, 0x6d36: {2}, 0x6dd7: {0}, 0x6ddc: {0}, 0x6e04: {0}, 0x6e36: {0}, 0x6e82: {0}})
    return r, songs, st
