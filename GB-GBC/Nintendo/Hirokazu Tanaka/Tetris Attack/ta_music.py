"""Music driver of Tetris Attack (GB): two copies, bank $08 (songs $01-$1C) and bank $07 (songs $1D-$23).

The code is the Super Mario Land 2 version of the Tanaka driver (73 % of bank $08's instructions align with
SML2, 69 % with LA DX, 64 % with Dr. Mario): release envelopes and release point, 6-byte panning entries,
and SML2's save/restore-state routines (unreferenced, with SML2's loop bug fixed). The command set is cut
back to Dr. Mario's ($9B-$9F) and the header is 11 bytes. Several parts are Dr. Mario's: the pitch effect
and vibrato routine, the note table (C#7 = $7C4), packed length tables, and Dr. Mario's six waves (left
unreferenced). RAM is the $D300 page, as in LA DX. New: a song fade-out, and the ch3 wave is mirrored to
$D400 so the SFX engine can restore it."""
import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'LADX')); sys.path.insert(0, os.path.join(HERE, '..', 'tools'))
from gbdis import Region
from tanaka import Songs, note_name
import transfer
import ladx_music as LM

RAM = dict(LM.RAM)
RAM.update({0xd35d: 'wD35D', 0xd35e: 'wD35E', 0xd38c: 'wFadeTimer', 0xd38d: 'wFadeStep', 0xd39f: 'wSavedSong',
            0xd3f0: 'wPauseRequest', 0xd3f1: 'wPaused', 0xd3fb: 'wSfxChannels', 0xd3fe: 'wSfxActive', 0xd400: 'wWaveCopy'})
for k in ('wMusicIn1B', 'hResumeSong'): pass

CMDS = {0x9d: ('INSTR', ['instr']), 0x9e: ('TEMPO', ['lentab']), 0x9f: ('TRANSPOSE', ['b']), 0x9b: ('REPEAT', ['b']), 0x9c: ('REPEAT_END', [])}

NAMES_8 = {
 0x4000: 'Sound_StopMusic', 0x400d: 'Music_ClearState', 0x4035: 'Music_ClearState.ch2', 0x4048: 'Music_ClearState.ch3',
 0x405b: 'Music_ClearState.ch4', 0x4084: 'Sound_StopAll', 0x406e: 'Unused_MuteAll', 0x40d4: 'Music_StartFadeOut',
 0x40da: 'Music_FadeOut', 0x40e6: 'Music_FadeOut.start', 0x40ff: 'Music_FadeOut.step', 0x4123: 'Music_FadeOut.end',
 0x4134: 'FadeOutEnvelopes', 0x4153: 'SongTable', 0x4199: 'Unused_SetRegs', 0x41bb: 'Unused_SfxGetInitPointer',
 0x41bf: 'GetPointer', 0x41ce: 'LoadWave', 0x41d1: 'LoadWave.loop', 0x41de: 'LoadWave.copy',
 0x41e8: 'Music_SaveState_Unused', 0x41fc: 'Music_RestoreState_Unused',
 0x4211: 'Music_Stop', 0x4214: 'Music_StartSong', 0x422f: 'Music_InitPanning', 0x4235: 'Music_InitPanning.find',
 0x4240: 'Music_InitPanning.found', 0x425d: 'CopyWordIndirect', 0x4268: 'CopyWord', 0x426e: 'Music_LoadHeader',
 0x42be: 'Music_LoadHeader.initCounters', 0x42d1: 'SongPanTable', 0x4391: 'Music_UpdatePanning', 0x43b5: 'Music_UpdatePanning.write',
 0x43b9: 'Cmd_Instrument_wave', 0x43c2: 'Cmd_Instrument_wave.done', 0x43c5: 'Cmd_Instrument', 0x43eb: 'Cmd_Instrument.check3',
 0x43f5: 'Music_NextByte', 0x43fb: 'IncPtr', 0x4401: 'IncPtr.store', 0x4407: 'IncPtr2', 0x4410: 'ReadPtrByte',
 0x4417: 'Music_Sustain_skip', 0x441a: 'Music_Sustain', 0x4431: 'Music_Sustain.effects', 0x444b: 'Music_ChannelDone',
 0x4450: 'Cmd_PatternEnd', 0x4457: 'Cmd_PatternEnd.loadPattern', 0x446b: 'Cmd_PatternEnd.loop', 0x4482: 'Cmd_PatternEnd.songEnd',
 0x448b: 'Cmd_Tempo', 0x449f: 'Cmd_Transpose', 0x44a8: 'Cmd_SkipAndContinue', 0x44ad: 'Cmd_RepeatStart', 0x44d1: 'Cmd_RepeatEnd',
 0x44ea: 'Cmd_RepeatEnd.done', 0x44ed: 'Music_Play', 0x4501: 'Music_ChannelLoop', 0x450b: 'Music_ReadPattern', 0x450d: 'Music_ReadCommand',
 0x4553: 'Music_Length.release', 0x4564: 'Music_Length.store', 0x456a: 'Music_Length.storeRelease', 0x4578: 'Music_Length.done',
 0x4581: 'Music_Note', 0x45ae: 'Music_Note.addTranspose', 0x45b1: 'Music_Note.table', 0x45be: 'Music_Note.rest',
 0x45c3: 'Music_NoiseNote', 0x45cb: 'Music_NoiseNote.copy', 0x45dc: 'Music_Trigger', 0x45f8: 'Music_Trigger.ch3',
 0x4603: 'Music_Trigger.ch2', 0x4607: 'Music_Trigger.ch1', 0x460b: 'Music_Trigger.unused', 0x4612: 'Music_Trigger.ch1b', 0x4615: 'Music_Trigger.readInstr',
 0x461c: 'Music_Trigger.checkRest', 0x4625: 'Music_Trigger.notRest', 0x4630: 'Music_Trigger.write', 0x463e: 'Music_Trigger.done',
 0x4643: 'Music_NextChannel', 0x4654: 'Music_NextChannel.allDone', 0x4661: 'Vibrato_GetStep',
 0x466a: 'Music_Effects', 0x468c: 'Music_Effects.done', 0x468e: 'Music_Effects.pitch', 0x46a4: 'Music_Effects.detune',
 0x46a9: 'Music_Effects.vibrato', 0x46b5: 'Music_Effects.nibble', 0x46c2: 'Music_Effects.positive', 0x46c4: 'Music_Effects.signed',
 0x46c5: 'Music_Effects.add', 0x46ce: 'VibratoTable', 0x4773: 'Music_Release', 0x4793: 'Music_Release.ch2', 0x47b1: 'Music_ReleaseWrite',
 0x47c4: 'NoteTable', 0x4856: 'NoiseTable', 0x4955: 'ReleaseEnvelopes',
}
COMMENTS_8 = {
 0x4000: 'Stop the music. Music_ClearState leaves alone the channels an SFX stream is using\n(wSfxActive: bit 3 ch1, 2 ch2, 1 ch3, 0 ch4).',
 0x4084: 'Stop the music and mute all four channels.',
 0x406e: 'unreferenced: mute ch1, ch2, ch4 and switch ch3 off',
 0x40d4: 'unreferenced: start the fade-out (wFadeStep = 1). The game sets wFadeStep itself (home $0545).',
 0x460b: 'unreachable: ld b, $33 / ld a, $1D / write NR10',
 0x40da: 'Song fade-out (wFadeStep non-zero; the game sets it at home $0545): mute ch3 and ch4, then every 6 frames\nlower the ch1/ch2 envelopes (FadeOutEnvelopes); at the end stop and request song $22.',
 0x4134: 'ch1 envelope per fade step (0 = end), ch2 envelope 16 bytes later',
 0x4153: 'songs $01-$23; this bank plays $01-$1C, the others point at a dummy header',
 0x4199: 'unreferenced: the SFX register writers and Sfx_GetInitPointer of the LA-style SFX code',
 0x41ce: 'Load the ch3 wave and keep a copy at wWaveCopy ($D400) for the SFX engine.',
 0x41e8: 'unreferenced: save $D310-$D349 to $D390 (and wSavedSong = 5) / restore them and song 5. Unlike\nSML2\'s, both loops compare the right register.',
 0x4214: 'Song request: $FF = stop, $24 and above ignored.',
 0x42d1: 'Panning: mode (1 = fixed), period, NR51 x4',
 0x43c5: '$9D: ignored (operands skipped) while the song fades out.',
 0x450d: 'Commands $9B-$9F, lengths $A0-$AF (release point as in SML2 / LA).',
 0x466a: 'Pitch effect from the low nibble of InstrDuty: 1 = vibrato (VibratoTable, Dr. Mario / Tetris\nstyle: one signed nibble per frame), other = period - 1.',
 0x46ce: 'vibrato: signed nibbles, two per byte, read by NoteFrames (same table as Tetris)',
 0x4773: 'Release: at NoteFrames = wReleaseFrame, write ReleaseEnvelopes[low nibble - 1] (ch1, ch2).',
 0x4856: 'ch4: offsets 1 + 5n: NR42, unused, NR41, NR43, NR44',
}

LEN_NAMES = LM.LEN_NAMES


def song_id_8(i): return i if i <= 0x1c else None
def song_id_7(i): return i if 0x1d <= i <= 0x23 else None


def build(rom, bank, names, comments, entries, song_table, song_id, note_table, noise_table, noise_end, release, vib, vib_end,
          pan_table, pan_count, fade, extra_code=(), extra_lists={}, extra_patterns={}, region=None, first=1, count=35):
    r = region or Region(rom, bank, 0x4000, 0x8000)
    if not r.ram: r.ram = dict(RAM)
    r.trace(entries)
    for a, b in extra_code: r.code_range(a, b)
    for a, n in names.items(): r.label(a, n)
    for a, t in comments.items(): r.comments[a] = t
    hexb = lambda rr, a, n: '\tdb ' + ', '.join(f'${rr.byte(a+i):02x}' for i in range(n))
    for a, n in ((song_table, 'SongTable'), (pan_table, 'SongPanTable'), (fade, 'FadeOutEnvelopes'), (vib, 'VibratoTable'),
                 (note_table, 'NoteTable'), (noise_table, 'NoiseTable'), (release, 'ReleaseEnvelopes')):
        r.label(a, n)
    r.block(song_table, 70, lambda rr, a: [f'\tdw {rr.sym_addr(rr.word(a+2*i))}\t; ${i+1:02x}' + ('' if song_id(i+1) else ': other bank') for i in range(35)])
    r.block(pan_table, 6*pan_count, lambda rr, a: [hexb(rr, a+6*i, 6) + f'\t; ${i+1:02x}' for i in range(pan_count)])
    r.block(fade, 31, lambda rr, a: [hexb(rr, a, 16), hexb(rr, a+16, 15)])
    r.block(vib, vib_end - vib, lambda rr, a: [hexb(rr, a+k, min(16, vib_end - vib - k)) for k in range(0, vib_end - vib, 16)])
    r.block(note_table, 146, lambda rr, a: [f'\tdw ${rr.word(a):04x}\t; index 0'] + [f'\tdw ${rr.word(a+2+2*i):04x}\t; {note_name(2+2*i)}' for i in range(72)])
    n_noise = (noise_end - noise_table - 1) // 5
    r.block(noise_table, noise_end - noise_table, lambda rr, a: [hexb(rr, a, 1)] + [hexb(rr, a+1+5*k, 5) + f'\t; NOISE_{1+5*k:02X}' for k in range(n_noise)]
            + ([hexb(rr, a+1+5*n_noise, noise_end - noise_table - 1 - 5*n_noise)] if (noise_end - noise_table - 1) % 5 else []))
    r.block(release, 7, lambda rr, a: [hexb(rr, a, 7)])
    noise_names = {1+5*k: f'NOISE_{1+5*k:02X}' for k in range(n_noise)}; noise_names[0xff] = 'DRUM'
    sl = lambda n: f'Song{song_id(n):02X}' if song_id(n) else f'Song{bank:02X}x{n:02X}'
    sid = lambda n: song_id(n + first - 1)
    sl = lambda n: f'Song{sid(n):02X}'
    songs = Songs(r, {'song_table': song_table + 2*(first-1), 'song_count': count, 'cmds': CMDS, 'len_names': LEN_NAMES, 'noise_names': noise_names,
                      'song_label': sl, 'extra_lists': extra_lists, 'extra_patterns': extra_patterns}).parse()
    songs.register()
    for w in songs.waves:
        r.block(w, 16, lambda rr, a: [hexb(rr, a, 16)])
    lo = min(t for t in songs.lentabs)
    for t in songs.lentabs: r.label(t, f'LengthTable_{t:04X}')
    def lens(rr, a, lo=lo):
        out = []; cur = []
        for q in range(lo, release):
            if q in rr.labels and q != lo:
                if cur: out.append('\tdb ' + ', '.join(cur)); cur = []
                out.append(rr.labels[q] + ':')
            cur.append(f'${rr.byte(q):02x}')
            if len(cur) == 15: out.append('\tdb ' + ', '.join(cur)); cur = []
        if cur: out.append('\tdb ' + ', '.join(cur))
        return out
    r.block(lo, release - lo, lens)
    r.comments[lo] = 'length tables (they overlap: a table starts wherever a header or TEMPO points)'
    r.collect_refs()
    return r, songs


def gen_8(rom):
    return build(rom, 8, NAMES_8, COMMENTS_8, [0x4000, 0x4084, 0x44ed, 0x4214], 0x4153, song_id_8, 0x47c4, 0x4856, 0x488e,
                 0x4955, 0x46ce, 0x4755, 0x42d1, 32, 0x4134, extra_code=[(0x4199, 0x41bf), (0x41e8, 0x4211), (0x406e, 0x4084), (0x40d4, 0x40da), (0x460b, 0x4612)],
                 first=1, count=0x1c)
