"""Music half of the Super Mario Bros. Deluxe sound driver (bank $1D).

A descendant of the Link's Awakening DX music driver (bank $1B): same channel structures, song
format and most routines, with RAM moved to $DE00 and these changes:
  - commands: $9E/$9F (tempo, transpose) and $94-$96 removed; $99 = rest envelope (ch1/ch2),
    $9A = master volume (NR50)
  - INSTR: the first two bytes are either an envelope byte + $00 or a pointer to a per-frame
    envelope table (replaces the release envelopes)
  - "hurry up" mode: alternative length tables, and song $71 resumes the interrupted song
  - vibrato type 2 (the LA bank $1B type 5 table is gone), drop -32 per frame"""
import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'LADX')); sys.path.insert(0, os.path.join(HERE, '..', 'tools'))
import ladx_music as LM

RAM = {a - 0xd300 + 0xde00: n for a, n in LM.RAM.items() if 0xd300 <= a < 0xd400}
RAM.update({
 0xde80:'wCh1RestEnv', 0xde81:'wCh2RestEnv', 0xdeca:'wCurrentSong', 0xdecb:'wPreviousSong', 0xdece:'wMusicActive',
 0xded0:'wHurryMode', 0xded1:'wPausedSong', 0xded2:'wChannelsPlayed', 0xded3:'wDED3', 0xded5:'wResumeSong',
 0xdee5:'wDEE5',
})
for k in [a for a, n in RAM.items() if n in ('wMusicIn1B', 'wCh3SfxPaused', 'wReloadWave')]: pass
RAM[0xdece] = 'wMusicActive'

CMDS = {0x9d:('INSTR',['instr_env']), 0x9b:('REPEAT',['b']), 0x9c:('REPEAT_END',[]),
        0x97:('DROP_ON',[]), 0x98:('DROP_OFF',[]), 0x9a:('VOLUME',['b']), 0x99:('REST_ENV',['b'])}

NAMES = {
 0x4009:'Music_Init', 0x400c:'Music_Init.clear',
 0x401e:'Music_Update', 0x4047:'Music_Update.storeRequest', 0x404a:'Music_Update.checkRequest', 0x4051:'Music_Update.play',
 0x4058:'Unused_4058', 0x405d:'Music_Update.start',
 0x4062:'MusicDrum_Update', 0x4073:'MusicDrum_Update.start', 0x407e:'MusicDrum_Update.playing',
 0x408b:'MusicDrum_StartRegs', 0x4090:'MusicDrum_EndRegs', 0x4095:'MusicDrum_WriteRegs', 0x4099:'MusicDrum_WriteRegs.loop',
 0x40a2:'SongTable', 0x4120:'GetPointer', 0x412f:'LoadWave', 0x4132:'LoadWave.loop', 0x413c:'StopSfx4',
 0x4158:'Music_Stop', 0x4172:'Music_Stop.pause', 0x418b:'Music_RestorePausedSong',
 0x4192:'Music_StartSong', 0x4198:'Unused_4198', 0x41b7:'Music_StartSong.checkRange', 0x41c1:'Music_StartSong.refuse',
 0x41c6:'Music_StartSong.inRange', 0x41dd:'Music_StartSong.start', 0x41ea:'Music_StartSong.notResume',
 0x4214:'Music_StartSong.resumePoint', 0x421a:'HurryKeepTable', 0x4238:'Music_StartSong.normal', 0x424a:'Music_StartSong.keepHurry',
 0x424e:'Music_StartSong.load',
 0x4267:'SongPanTable', 0x43e7:'Music_ReloadWave', 0x4400:'Music_ReloadWave.loop',
 0x4411:'Music_InitPanning', 0x4417:'Music_InitPanning.found', 0x4434:'Music_UpdatePanning', 0x4458:'Music_UpdatePanning.write',
 0x445c:'CopyWordIndirect', 0x4467:'CopyWord', 0x446d:'Music_LoadHeader', 0x448f:'Music_LoadHeader.load',
 0x44b5:'Music_LoadPatterns', 0x44df:'Music_LoadPatterns.initCounters',
 0x44f2:'Cmd_Instrument_wave', 0x450b:'Cmd_Instrument_wave.load', 0x4511:'Cmd_Instrument_wave.done', 0x4514:'Cmd_Instrument',
 0x453e:'Music_NextByte', 0x4544:'IncPtr', 0x454a:'IncPtr.store', 0x4550:'IncPtr2', 0x4559:'ReadPtrByte',
 0x4560:'Music_Sustain_skip', 0x4563:'Music_Sustain', 0x4589:'Music_Sustain.ch3Level', 0x4599:'Music_Sustain.effects',
 0x45b3:'Music_ChannelDone',
 0x45b8:'Cmd_PatternEnd', 0x45bf:'Cmd_PatternEnd.loadPattern', 0x45d3:'Cmd_PatternEnd.loop', 0x45ea:'Cmd_PatternEnd.songEnd',
 0x4603:'Music_ResumeLevelSong', 0x460e:'Music_ResumeLevelSong.lists', 0x46a1:'StoreHL', 0x46a7:'Music_SongEnd',
 0x46cd:'Music_SkipAndContinue', 0x46d3:'Cmd_RepeatStart', 0x46f7:'Cmd_RepeatEnd', 0x4710:'Cmd_RepeatEnd.done',
 0x4713:'Cmd_Volume', 0x4722:'Cmd_RestEnv', 0x4734:'Cmd_RestEnv.next', 0x4739:'Cmd_RestEnv.ch1', 0x473f:'Cmd_RestEnv.ch2',
 0x4745:'Music_Play', 0x475b:'Music_ChannelLoop', 0x4765:'Music_ReadPattern', 0x4767:'Music_ReadCommand',
 0x47c1:'Music_Length.hurry68', 0x47c6:'Music_Length.hurry7E', 0x47cb:'Music_Length.hurry65', 0x47ce:'Music_Length.lookup',
 0x47de:'Music_Length.release', 0x47ef:'Music_Length.store', 0x47f5:'Music_Length.storeRelease', 0x4803:'Music_Length.done',
 0x480c:'Music_Note', 0x483c:'Music_Note.fadeIn', 0x484a:'Music_Note.effectsDone', 0x484b:'Music_Note.lookup',
 0x4878:'Music_Note.addTranspose', 0x487b:'Music_Note.table', 0x4888:'Music_Note.rest', 0x488c:'Music_Note.firstRest', 0x488e:'Music_Note.restDone',
 0x4891:'Music_NoiseNote', 0x489e:'Music_NoiseNote.copy', 0x48af:'Music_NoiseNote.drum',
 0x48c2:'Music_Trigger', 0x48e6:'Music_Trigger.ch3Off', 0x48e8:'Music_Trigger.ch3On', 0x48ed:'Music_Trigger.ch3',
 0x48f8:'Music_Trigger.ch2', 0x48fc:'Music_Trigger.ch1', 0x48ff:'Music_Trigger.readInstr', 0x490d:'Music_Trigger.duty',
 0x4910:'Music_Trigger.checkRest', 0x4936:'Music_Trigger.restCh2', 0x4940:'Music_Trigger.restEnv', 0x4946:'Music_Trigger.silent',
 0x4949:'Music_Trigger.restCh3', 0x494d:'Music_Trigger.notRest', 0x4960:'Music_Trigger.write', 0x497c:'Music_Trigger.playedCh2',
 0x4986:'Music_Trigger.playedCh1', 0x498e:'Music_Trigger.nrx4', 0x4992:'Music_Trigger.writeNRx4', 0x4993:'Music_Trigger.done',
 0x4998:'Music_NextChannel', 0x49a9:'Music_NextChannel.allDone',
 0x49b6:'Music_Effects_ret', 0x49b8:'Music_Effects', 0x49da:'Music_Effects.drop', 0x4a03:'Music_Effects.ch3', 0x4a1c:'Music_Effects.pitch',
 0x4a41:'Music_Envelope', 0x4a85:'Music_Envelope.ch2',
 0x4ae0:'Music_Ch3FadeOut', 0x4b0d:'Music_Ch3Fade.write', 0x4b12:'IncByteBC',
 0x4b16:'Cmd_DropOn', 0x4b1e:'Cmd_Drop.store', 0x4b25:'Cmd_DropOff', 0x4b2e:'Music_Drop', 0x4b3a:'Music_Drop.apply', 0x4b44:'Music_Drop.next',
 0x4b49:'GetNoteFreq', 0x4b54:'WritePitch', 0x4b65:'IndexByChannel', 0x4b6e:'ReadPitch',
 0x4b7b:'Music_Vibrato2', 0x4b88:'Music_Vibrato2.count', 0x4b8d:'Music_Vibrato', 0x4b98:'Music_Vibrato.check',
 0x4ba5:'Music_Vibrato.apply', 0x4bc6:'Music_Vibrato.wrap', 0x4bcd:'Music_Vibrato.first', 0x4bd2:'VibratoTable',
 0x4c05:'Music_Ch3FadeIn', 0x4c2f:'NoteTable', 0x4cc1:'NoiseTable',
 0x4da2:'Sound_Stop', 0x4dc0:'Sound_StopMusic', 0x4dd0:'Music_ClearState', 0x4fff:'Music_RequestHook',
}

COMMENTS = {
 0x4000: 'Entry points (same order as LA): init, stop, update.',
 0x4009: 'Clear $DE00-$DEFF and switch the APU on.',
 0x401e: 'Called once per frame, before the SFX bank. Any pending request calls the empty hook at\n$4FFF. Ch1 effect $6E during song $37 stops the music unless the previous song was $7D.\nEvery frame NR31 is cleared.',
 0x4058: 'unreferenced: LA\'s "song not in this bank" exit',
 0x4062: 'Pattern byte $FF on ch4 plays this two-step noise drum (wSfx4Request = 1) unless an SFX\nowns ch4. Unchanged from LA.',
 0x4120: 'hl = table, a = 1-based index: hl = table[a-1] (and e = e+1, a = h).',
 0x4158: 'Song request $FF. Stopping song $2D pauses it instead (wPausedSong); song $6D later\nrestores it.',
 0x4192: 'Songs $62-$7F (table entries $22-$3F). The song already playing is not restarted, except\n$63, $65 and $68.',
 0x4198: 'unreferenced: LA\'s bank range checks',
 0x41ea: 'Song $71 (hurry up) sets wHurryMode and remembers the interrupted song in wResumeSong. Any\nother song clears wHurryMode unless HurryKeepTable says otherwise.',
 0x421a: 'one byte per song $62-$7F: 1 = keep hurry mode',
 0x4267: 'Panning: mode (1 = fixed), period, NR51 x4 for each table entry. All entries are fixed $FF.',
 0x44f2: 'ch3 wave: not loaded while a ch3 SFX plays; ch3 is switched off first if it is on.',
 0x4514: '$9D: three bytes to Env/Release/Duty. Release non-zero: Env/Release are a pointer to a\nper-frame envelope table. ch3: wave pointer + level.',
 0x4563: 'ch3: the level counts up from 1 and mutes ch3 (NR32 = 0) when it reaches 3; then LA\'s\n50% drop 6 frames before the end of a note.',
 0x45ea: 'Song end. After song $31 (index; song $71, hurry up) the interrupted song restarts: songs\n$62 and above are requested again, the level song (below $62) resumes at its section via\nMusic_ResumeLevelSong.',
 0x4603: 'Rebuild the music state of song $62 (the overworld theme, played as $22) at the section\nsaved in wResumeSong, without restarting it from the top.',
 0x4713: '$9A: master volume, NR50 = value & $77.',
 0x4722: '$99: NRx2 written for rests on ch1 (wCh1RestEnv) or ch2 (wCh2RestEnv), once the channel\nhas played a note.',
 0x4767: 'Commands $97-$9D, lengths $A0-$AF. In hurry mode songs use faster length tables:\n$68 and $7E LengthTable_4D17, $65 LengthTable_4D80, every other song LengthTable_4D08.',
 0x4910: 'Rest: the first rest of a run writes the rest envelope (ch1/ch2) or level $40 (ch3);\nlater rests write nothing.',
 0x49b8: 'Pitch effect from the low nibble of Duty: 1 = vibrato after 24 frames, 2 = vibrato from\nframe 17, other non-zero = period - 1 per frame. Then drop and the ch3 fades.',
 0x4a41: 'Envelope tables: for the first 48 frames of a note, a non-zero byte of the table is\nwritten to NRx2 and the note retriggered (ch1/ch2).',
 0x4b2e: 'Drop: the period falls by 32 every frame.',
 0x4bd2: 'vibrato: 20 big-endian period offsets, cycled',
 0x4da2: 'Stop everything this bank controls: ch4 effect, panning, music, mute.',
 0x4fff: 'Called whenever any request is pending: empty.',
}


def song_id(i):
    return i + 0x40 if 0x22 <= i <= 0x3f else None


def fix(r):
    for a, b in ((0x46b0, 0x46cd), (0x4ac1, 0x4ae0), (0x4bfa, 0x4c05)): r.code_range(a, b)
    for a, n in {0x46b0: 'Unused_CmdTempo', 0x46c4: 'Unused_CmdTranspose', 0x4ac1: 'Unused_CmdCh3SfxPause',
                 0x4ac3: 'Unused_CmdCh3SfxPause.store', 0x4acc: 'Unused_CmdCh3SfxResume', 0x4acf: 'Unused_CmdCh3FadeOutOn',
                 0x4ad1: 'Unused_CmdCh3FadeOutOn.store', 0x4ada: 'Unused_CmdCh3FadeOutOff',
                 0x419f: 'Unused_4198.not1x', 0x41a6: 'Unused_4198.not2x', 0x41ad: 'Unused_4198.not3x',
                 0x4bfa: 'Unused_CmdCh3FadeInOn', 0x4d8f: 'Unused_ReleaseEnvelopes', 0x5d3e: 'Unused_SongHeader',
                 0x7f9e: 'Unused_7F9E'}.items():
        r.label(a, n)
    r.comments[0x46b0] = 'unreferenced: LA\'s $9E (tempo) and $9F (transpose) commands'
    r.comments[0x4ac1] = 'unreferenced: LA\'s $96 / $95 / $99 / $9A commands'
    r.comments[0x4bfa] = 'unreferenced: LA\'s $94 command'
    r.comments[0x4d8f] = 'unreferenced: LA\'s release envelopes'
    r.comments[0x5d3e] = 'unreferenced song header: no length table, three silent channels'
    r.comments[0x7f9e] = 'unreferenced: 30 words'
    r.label(0x5132, 'Song62_ResumeLists', 'Music_ResumeLevelSong indexes the lists of song $62 from here (ch2 entry 2;\nch1, ch3, ch4 at +$22, +$44, +$64)')
    r.block(0x4d8f, 7, lambda rr, a: ['\tdb ' + ', '.join(f'${rr.byte(a+i):02x}' for i in range(7))])
    r.block(0x5d3e, 11, lambda rr, a: [f'\tSONG $00, $0000, {rr.sym_addr(0x4d96)}, {rr.sym_addr(0x4d96)}, {rr.sym_addr(0x4d96)}, 0'])
    r.block(0x421a, 30, lambda rr, a: ['\tdb ' + ', '.join(f'${rr.byte(a+i):02x}' for i in range(k, k+10)) + f'\t; songs ${0x62+k:02x}-${0x62+k+9:02x}' for k in range(0, 30, 10)])
    r.block(0x7f9e, 60, lambda rr, a: ['\tdw ' + ', '.join(f'${rr.word(a+2*i):04x}' for i in range(k, k+10)) for k in range(0, 30, 10)])
    for a in (0x7ad7, 0x7d96):
        r.comments[a] = 'unreferenced byte after the length table'
        r.block(a, 1, lambda rr, a: [f'\tdb ${rr.byte(a):02x}'])


def gen_1d(rom):
    r, songs = LM.build_music(rom, 0x1d, 'SMBDX', NAMES, COMMENTS, 0x40a2, 63, song_id, [0x4000, 0x4003, 0x4006],
                              0x4c2f, 0x4cc1, [0x4d08 + 15*i for i in range(9)], None, 0x4bd2, None, 0x4267,
                              drum_regs=[0x408b, 0x4090], ram=RAM, extra_code=[0x4058, 0x4198], cmds=CMDS, fix=fix,
                              extra_lists={0x559a: None, 0x5973: None, 0x735a: None}, pan_count=64)
    return r, songs
