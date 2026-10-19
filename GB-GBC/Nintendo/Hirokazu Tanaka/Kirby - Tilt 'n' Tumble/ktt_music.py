"""Music half of the Kirby Tilt 'n' Tumble sound driver (banks $0E and $0F).

A descendant of the Super Mario Bros. Deluxe music driver (bank $1D): same RAM page ($DE00), channel
structures, song format, envelope tables, vibrato types and rest envelopes. Differences:
  - two music banks, like Link's Awakening DX: songs $01-$3F live in bank $0E, $40-$7F in bank $0F;
    both banks read every request and wMusicBank says which one plays
  - request $80 replays the previous song; no hurry-up resume / pause logic
  - commands: $9E (tempo) is back; new $96/$95 (per-channel transpose set/add), $94/$93 (volume of the
    instrument envelope set/add), $92 (drum kit pointer); the section lists accept $FF96/$FF95/$FF94/
    $FF93 + a word operand between patterns
  - ch4 notes are offsets into the current drum kit (default: the bank's NoiseTable); the music drum
    ($FF) and its update are gone
  - hurry mode (wHurryMode, set by the game) swaps in per-song length tables stored in front of the
    song headers
  - one panning entry for every song (the 64-entry table is still there)
  - the ch3 SFX slot is back (wSfx3Request $DE80), so the rest envelopes moved to $DE88/$DE89
Bank $0E is labelled by hand (on top of the names transferred from SMB DX bank $1D); bank $0F gets its
names by aligning its code against bank $0E."""
import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
for p in ('', '../SMBDX', '../LADX', '../tools'):
    sys.path.insert(0, os.path.join(HERE, p))
import ladx_music as LM
import smbdx_music as SM
from transfer import align, transfer_labels

# ---------------------------------------------------------------- RAM ($DE00-$DEFF in WRAM bank 7)
RAM = {a: n for a, n in SM.RAM.items() if n not in ('wCh1RestEnv', 'wCh2RestEnv', 'wDED3', 'wDEE5', 'wPausedSong', 'wResumeSong', 'wMusicActive')}
RAM.update({
 0xde60: 'wSfx1Request', 0xde61: 'wSfx1Playing', 0xde68: 'wSongRequest', 0xde69: 'wSongPlaying',
 0xde70: 'wSfx2Request', 0xde71: 'wSfx2Playing', 0xde78: 'wSfx4Request', 0xde79: 'wSfx4Playing',
 0xde80: 'wSfx3Request', 0xde81: 'wSfx3Playing',
 0xde88: 'wCh1RestEnv', 0xde89: 'wCh2RestEnv', 0xde8a: 'wSfxDE8A', 0xde8b: 'wPcmDone',
 0xde90: 'wSfx1Timer', 0xde91: 'wSfx2Timer', 0xde92: 'wSfx3Timer', 0xde93: 'wSfx4Timer',
 0xde94: 'wSfx1Step', 0xde95: 'wSfx2Step', 0xde96: 'wSfx3Step', 0xde98: 'wSfx4Step',
 0xde9e: 'wCh3FadeOut', 0xde9f: 'wCh3FadeOutTimer',
 0xdea0: 'wSfx1Var', 0xdea1: 'wSfx2Var', 0xdea2: 'wSfx3Var', 0xdea3: 'wSfx4Var',
 0xdebc: 'wSfx1Counter', 0xdebd: 'wSfx2Counter', 0xdebe: 'wSfx3Counter', 0xdebf: 'wSfx4Counter',
 0xdec0: 'wSfx1Pitch', 0xdec1: 'wSfx1Pitch+1', 0xdec2: 'wSfx2Pitch', 0xdec3: 'wSfx2Pitch+1', 0xdec4: 'wSfx3Pitch', 0xdec5: 'wSfx3Pitch+1',
 0xdec6: 'wSfx1Priority', 0xdec7: 'wSfx2Priority', 0xdec8: 'wSfx3Priority', 0xdec9: 'wSfx4Priority',
 0xdeca: 'wCurrentSong', 0xdecb: 'wPreviousSong', 0xdecd: 'wCh3SfxPaused', 0xdece: 'wMusicBank',
 0xded0: 'wHurryMode', 0xded2: 'wChannelsPlayed', 0xded5: 'wHurryJingle',
 0xded9: 'wCh3FadeIn', 0xdeda: 'wCh3FadeInTimer', 0xdee7: 'wReloadWave',
 0xdeeb: 'wSfx1Sweep', 0xdeec: 'wSfx2Sweep', 0xdeed: 'wSfx3Sweep',
 0xdef0: 'wChTranspose', 0xdef1: 'wChTranspose+1', 0xdef2: 'wChTranspose+2', 0xdef3: 'wChTranspose+3',
 0xdef4: 'wDrumKit', 0xdef5: 'wDrumKit+1',
})
for a in [a for a, n in RAM.items() if n.startswith(('wVibrato2', 'wSfxPitchB', 'wSfxCounter2', 'wSfxTimer2', 'wSfxStep2', 'wSfxVar2', 'wSfxPriority2', 'wSfx2Paused'))]:
    if a not in (0xde91, 0xde95, 0xdea1, 0xdebd, 0xdec7, 0xdec2, 0xdec3): del RAM[a]

CMDS = {0x9d: ('INSTR', ['instr_env']), 0x9e: ('TEMPO', ['lentab']), 0x9b: ('REPEAT', ['b']), 0x9c: ('REPEAT_END', []),
        0x97: ('DROP_ON', []), 0x98: ('DROP_OFF', []), 0x9a: ('VOLUME', ['b']), 0x99: ('REST_ENV', ['b']),
        0x96: ('TRANSPOSE', ['b']), 0x95: ('TRANSPOSE_ADD', ['b']), 0x94: ('ENV_SET', ['b']), 0x93: ('ENV_ADD', ['b']),
        0x92: ('DRUMKIT', ['w'])}
LIST_CMDS = {0x96: 'LIST_TRANSPOSE', 0x95: 'LIST_TRANSPOSE_ADD', 0x94: 'LIST_ENV_SET', 0x93: 'LIST_ENV_ADD'}

# ---------------------------------------------------------------- bank $0E: names on top of the SMB DX transfer
NAMES_0E = {
 0x4009: 'Music_Init', 0x400c: 'Music_Init.clear', 0x401e: 'Music_Update', 0x4037: 'Music_Update.play', 0x403e: 'Music_Update.request',
 0x4043: 'SongTable', 0x4141: 'GetPointer', 0x4150: 'LoadWave', 0x4153: 'LoadWave.loop',
 0x415d: 'Unused_StopSfx4', 0x4179: 'Music_Stop',
 0x4187: 'Music_StartSong', 0x418e: 'Music_StartSong.notReplay', 0x41a6: 'Music_StartSong.store',
 0x41c6: 'SongPanTable',
 0x4346: 'Music_ReloadWave', 0x435f: 'Music_ReloadWave.loop',
 0x4372: 'Music_InitPanning', 0x4395: 'Music_UpdatePanning', 0x43b9: 'Music_UpdatePanning.write',
 0x43bd: 'CopyWordIndirect', 0x43c8: 'CopyWord', 0x43ce: 'Music_LoadHeader', 0x441e: 'Music_LoadHeader.initCounters',
 0x4431: 'Cmd_Instrument_wave', 0x444a: 'Cmd_Instrument_wave.load', 0x4450: 'Cmd_Instrument_wave.done', 0x4453: 'Cmd_Instrument',
 0x447d: 'Music_NextByte', 0x4483: 'IncPtr', 0x4489: 'IncPtr.store', 0x448f: 'IncPtr2', 0x4498: 'ReadPtrByte',
 0x449f: 'Music_Sustain_skip', 0x44a2: 'Music_Sustain', 0x44c8: 'Music_Sustain.ch3Level', 0x44d8: 'Music_Sustain.effects',
 0x44f2: 'Music_ChannelDone', 0x44f7: 'Cmd_PatternEnd', 0x44fe: 'Cmd_PatternEnd.loadPattern', 0x4512: 'Cmd_PatternEnd.listCommand',
 0x452a: 'Cmd_PatternEnd.transposeAdd', 0x452e: 'Cmd_PatternEnd.transposeSet', 0x4530: 'Cmd_PatternEnd.transpose',
 0x453a: 'Cmd_PatternEnd.envAdd', 0x453e: 'Cmd_PatternEnd.envSet', 0x4540: 'Cmd_PatternEnd.env',
 0x4550: 'ReadListOperand', 0x4565: 'Cmd_PatternEnd.loop', 0x457c: 'Music_SongEnd',
 0x4585: 'Cmd_Tempo', 0x4599: 'Unused_CmdTranspose', 0x45a2: 'Music_SkipAndContinue',
 0x45a8: 'Cmd_RepeatStart', 0x45cd: 'Cmd_RepeatEnd', 0x45e7: 'Cmd_RepeatEnd.done',
 0x45ea: 'Cmd_Volume', 0x45fa: 'Cmd_RestEnv', 0x460c: 'Cmd_RestEnv.next', 0x4612: 'Cmd_RestEnv.ch1', 0x4618: 'Cmd_RestEnv.ch2',
 0x461e: 'Cmd_TransposeAdd', 0x4622: 'Cmd_TransposeSet', 0x4624: 'Cmd_TransposeSet.apply', 0x4636: 'SetChannelTranspose',
 0x4646: 'Cmd_EnvAdd', 0x464a: 'Cmd_EnvSet', 0x464c: 'Cmd_EnvSet.apply',
 0x465d: 'SetChannelEnv', 0x467a: 'SetChannelEnv.negative', 0x467c: 'SetChannelEnv.store', 0x467d: 'SetChannelEnv.done',
 0x4680: 'Cmd_DrumKit',
 0x4697: 'Music_Play', 0x46ae: 'Music_ChannelLoop', 0x46b8: 'Music_ReadPattern', 0x46ba: 'Music_ReadCommand',
 0x470a: 'Music_Length', 0x474b: 'Music_Length.hurry08', 0x4750: 'Music_Length.hurry09', 0x4755: 'Music_Length.hurry0A',
 0x475a: 'Music_Length.hurry0B', 0x475f: 'Music_Length.hurry0C', 0x4764: 'Music_Length.hurry0D', 0x4769: 'Music_Length.hurry06',
 0x476e: 'Music_Length.hurry02', 0x4771: 'Music_Length.lookup',
 0x4781: 'Music_Length.release', 0x4792: 'Music_Length.store', 0x4798: 'Music_Length.storeRelease', 0x47a6: 'Music_Length.done',
 0x47af: 'Music_Note', 0x47df: 'Music_Note.fadeIn', 0x47ed: 'Music_Note.effectsDone', 0x47ee: 'Music_Note.lookup',
 0x4825: 'Music_Note.addTranspose', 0x4828: 'Music_Note.table', 0x4835: 'Music_Note.rest', 0x483b: 'Music_Note.restDone',
 0x483e: 'Music_DrumNote', 0x4849: 'Music_DrumNote.copy',
 0x485a: 'Music_Trigger', 0x487e: 'Music_Trigger.ch3Off', 0x4880: 'Music_Trigger.ch3On', 0x4885: 'Music_Trigger.ch3',
 0x4890: 'Music_Trigger.ch2', 0x4894: 'Music_Trigger.ch1', 0x4897: 'Music_Trigger.readInstr', 0x48a5: 'Music_Trigger.duty',
 0x48a8: 'Music_Trigger.checkRest', 0x48ce: 'Music_Trigger.restCh2', 0x48d8: 'Music_Trigger.restEnv', 0x48de: 'Music_Trigger.silent',
 0x48e1: 'Music_Trigger.restCh3', 0x48e5: 'Music_Trigger.notRest', 0x48f8: 'Music_Trigger.write', 0x4914: 'Music_Trigger.playedCh2',
 0x491e: 'Music_Trigger.playedCh1', 0x4926: 'Music_Trigger.nrx4', 0x492a: 'Music_Trigger.writeNRx4', 0x492b: 'Music_Trigger.done',
 0x4930: 'Music_NextChannel', 0x4941: 'Music_NextChannel.allDone',
 0x494e: 'Music_Effects_ret', 0x4950: 'Music_Effects', 0x4972: 'Music_Effects.drop', 0x499b: 'Music_Effects.ch3', 0x49b4: 'Music_Effects.pitch',
 0x49d9: 'Music_Envelope', 0x4a1d: 'Music_Envelope.ch2',
 0x4a59: 'Unused_CmdCh3SfxPause', 0x4a5b: 'Unused_CmdCh3SfxPause.store', 0x4a64: 'Unused_CmdCh3SfxResume',
 0x4a67: 'Unused_CmdCh3FadeOutOn', 0x4a69: 'Unused_CmdCh3FadeOutOn.store', 0x4a72: 'Unused_CmdCh3FadeOutOff',
 0x4a78: 'Music_Ch3FadeOut', 0x4aa5: 'Music_Ch3Fade.write', 0x4aaa: 'IncByteBC',
 0x4aae: 'Cmd_DropOn', 0x4ab6: 'Cmd_Drop.store', 0x4abd: 'Cmd_DropOff', 0x4ac6: 'Music_Drop', 0x4ad2: 'Music_Drop.apply', 0x4adc: 'Music_Drop.next',
 0x4ae1: 'GetNoteFreq', 0x4aec: 'WritePitch', 0x4afd: 'IndexByChannel', 0x4b06: 'ReadPitch',
 0x4b13: 'Music_Vibrato2', 0x4b20: 'Music_Vibrato2.count', 0x4b25: 'Music_Vibrato', 0x4b30: 'Music_Vibrato.check',
 0x4b3d: 'Music_Vibrato.apply', 0x4b5e: 'Music_Vibrato.wrap', 0x4b65: 'Music_Vibrato.first', 0x4b6a: 'VibratoTable',
 0x4b92: 'Unused_CmdCh3FadeInOn', 0x4b9d: 'Music_Ch3FadeIn',
 0x4bc7: 'NoteTable', 0x4c59: 'NoiseTable',
 0x4d8f: 'Sound_Stop', 0x4da6: 'Music_MuteChannels', 0x4db6: 'Music_MuteChannels.ch2', 0x4dc4: 'Music_MuteChannels.ch3',
 0x4dd1: 'Music_MuteChannels.ch4', 0x4ddf: 'Music_MuteChannels.done',
 0x4de0: 'Music_ReleaseChannels', 0x4e01: 'Music_ClearState', 0x4fff: 'Music_RequestHook',
}
UNUSED_CODE_0E = ((0x415d, 0x4179), (0x4599, 0x45a2), (0x4a59, 0x4a78), (0x4b92, 0x4b9d))

COMMENTS_0E = {
 0x4000: 'Entry points (same order as the SFX banks): init, stop, update.',
 0x4009: 'Clear $DE00-$DEFF and switch the APU on. (The game only calls the init of SFX bank $11.)',
 0x401e: 'Called once per frame, before the other music bank and the two SFX banks. Any pending\nrequest calls the empty hook at $4FFF. NR31 is cleared every frame.',
 0x4043: '127 entries ($01-$7F) in both music banks; each bank only accepts its own half.',
 0x415d: 'unreferenced: cancel the ch4 effect',
 0x4179: 'Request $FF: remember the song for request $80, then stop.',
 0x4187: 'Request $80 replays wPreviousSong. This bank takes songs $01-$3F (bank $0F: $40-$7F) and\nclaims the music (wMusicBank = 0; bank $0F writes 1). A new song moves wCurrentSong to\nwPreviousSong.',
 0x41c6: 'Panning: mode (1 = fixed), period, NR51 x4. 64 entries as in SMB DX, but Music_InitPanning\nnow always reads the first one.',
 0x4346: 'Ch3 trigger: reload the music wave first if an SFX overwrote wave RAM (wReloadWave).',
 0x43ce: 'Reset the per-channel transposes and the drum kit, then load the 11-byte song header.',
 0x4453: '$9D: three bytes to Env/Release/Duty. Release non-zero: Env/Release are a pointer to a\nper-frame envelope table. ch3: wave pointer + level.',
 0x44a2: 'ch3: the level counts up from 1 and mutes ch3 (NR32 = 0) when it reaches 3; then LA\'s\n50% drop 6 frames before the end of a note.',
 0x44f7: '$00: next list entry. $0000 ends the song (no restart); $FFFF + address loops;\n$FF96 / $FF95 / $FF94 / $FF93 + a word: per-channel transpose set / add or envelope set /\nadd (low byte of the word), then the next entry. Any other $FFxx ends the song.',
 0x4550: 'Skip the command word and read the operand word of a list command into de.',
 0x457c: 'The song is over: clear wSongPlaying, remember it for request $80 and stop.',
 0x4585: '$9E: select a length table (back from LA; SMB DX had removed it).',
 0x4599: 'unreferenced: tail of LA\'s $9F (transpose) command',
 0x45ea: '$9A: master volume, NR50 = value & $77.',
 0x45fa: '$99: NRx2 written for rests on ch1 (wCh1RestEnv) or ch2 (wCh2RestEnv), once the channel\nhas played a note. Both default to $11 when a song starts.',
 0x461e: '$95 / $96: add to / set this channel\'s transpose (wChTranspose + channel; ch1-ch3 only,\nin bytes: 2 per semitone). It is added to the header transpose in Music_Note.',
 0x4646: '$93 / $94: add to / set the instrument\'s NRx2 byte (ch1/ch2, and only when it isn\'t an\nenvelope table pointer). The add is signed; an add that would wrap past $00 or $FF is ignored.',
 0x4680: '$92: drum kit pointer for ch4 notes (default NoiseTable).',
 0x4697: 'Nothing plays unless this bank owns the music (wMusicBank).',
 0x46ba: 'Commands $92-$9E, lengths $A0-$AF.',
 0x470a: 'In hurry mode (wHurryMode, set by the game) eight songs read their lengths from a table\nstored just before their header; the others keep the current table.',
 0x47af: 'Note: restart the vibrato / drop state of the channel and the ch3 fades, then add the\nheader transpose and the channel transpose.',
 0x483e: 'ch4: copy 5 bytes (NR42, -, NR41, NR43, NR44) from drum kit + note byte. No music drum.',
 0x48a8: 'Rest: the first rest of a run writes the rest envelope (ch1/ch2) or level $40 (ch3);\nlater rests write nothing.',
 0x4950: 'Pitch effect from the low nibble of Duty: 1 = vibrato after 24 frames, 2 = vibrato from\nframe 17, other non-zero = period - 1 per frame. Then drop and the ch3 fades.',
 0x49d9: 'Envelope tables: for the first 48 frames of a note, a non-zero byte of the table is\nwritten to NRx2 and the note retriggered (ch1/ch2).',
 0x4a59: 'unreferenced: LA\'s $96 / $95 / $99 / $9A commands',
 0x4ac6: 'Drop: the period falls by 32 every frame.',
 0x4b6a: 'vibrato: 20 big-endian period offsets, cycled',
 0x4b92: 'unreferenced: LA\'s $94 command',
 0x4c59: 'default drum kit: offset 0 unused, then 5 bytes per drum (NR42, -, NR41, NR43, NR44)',
 0x4d8f: 'Stop: release the channels, fixed panning, clear the song, mute the channels no SFX is\nusing.',
 0x4fff: 'Called whenever any request is pending: empty.',
}

HURRY_0E = {0x08: 0x6126, 0x09: 0x5e75, 0x0a: 0x5d38, 0x0b: 0x5c5d, 0x0c: 0x5986, 0x0d: 0x5553, 0x06: 0x65c4, 0x02: 0x68f2}
HURRY_0F = {0x64: 0x56e7, 0x41: 0x5014}
NAMES_0F_MANUAL = {0x4043: 'SongTable', 0x41c6: 'SongPanTable', 0x4733: 'Music_Length.hurry64', 0x4738: 'Music_Length.hurry41'}


def song_id_0e(i): return i if 1 <= i <= 0x3f else None
def song_id_0f(i): return i if 0x40 <= i <= 0x7f else None


def first_lentab(rom, bank, song_table, sid):
    """lowest length table referenced by a reachable header (bounds the drum kit)"""
    w = lambda a: rom[bank*0x4000 + a - 0x4000] | rom[bank*0x4000 + a - 0x3fff] << 8
    return min(w(w(song_table + 2*i) + 1) for i in range(127) if sid(i+1))


def make_fix(bank, hurry, unused_code, unused_names, kits_extra=()):
    def fix(r):
        for a, b in unused_code: r.code_range(a, b)
        for a, n in unused_names.items(): r.label(a, n)
        for song, t in hurry.items():
            r.label(t, f'Song{song:02X}_HurryLengths', f'hurry-mode length table of song ${song:02x}')
            r.block(t, 15, lambda rr, a: ['\tdb ' + ', '.join(f'${rr.byte(a+i):02x}' for i in range(15))])
    return fix


def list_patterns(songs, L):
    """patterns reached from list L, following jumps to other list fragments"""
    out = []; seen = set(); a = L
    while a in songs.list_words and a not in seen:
        seen.add(a)
        k, *v = songs.list_words[a]
        if k == 'pat': out.append(v[0]); a += 2
        elif k == 'cmd': a += 4
        elif k == 'loop': a = v[0]
        else: break
    return out


def drumkit_blocks(r, songs):
    """$92 operands: drum kits, offset 0 unused + 5 bytes per drum. Size: up to the highest ch4 note
    of the songs that select the kit."""
    kits = {}
    for p, (ev, end) in songs.pat_events.items():
        for a, kind, vals in ev:
            if kind == 'DRUMKIT': kits.setdefault(vals[0][1], set()).add(p)
    for k, pats in sorted(kits.items()):
        if r.block_of(k) is not None: continue
        top = 0
        for h in songs.headers:
            L = r.word(h + 3 + 6)
            if not L: continue
            pl = list_patterns(songs, L)
            if not pats & set(pl): continue
            for p in pl:
                for a, kind, vals in songs.pat_events[p][0]:
                    if kind == 'byte' and 1 < vals[0] < 0xa0: top = max(top, vals[0])
        n = top + 5
        end = k + 1
        while end < k + n and end not in r.labels and r.block_of(end) is None and end not in r.code: end += 1
        if end == k + n:
            e2 = end
            while e2 < end + 10 and e2 not in r.labels and r.block_of(e2) is None and e2 not in r.code: e2 += 1
            if e2 in r.labels and (e2 - end) % 5 == 0: end = e2
        n = end - k
        if k not in r.labels or r.labels[k].startswith(('Data_', 'Pattern_')): r.label(k, f'DrumKit_{k:04X}')
        def em(rr, a, n=n):
            out = [f'\tdb ${rr.byte(a):02x}\t; offset 0']
            for j in range(1, n, 5):
                out.append('\tdb ' + ', '.join(f'${rr.byte(a+i):02x}' for i in range(j, min(j+5, n))) + (f'\t; ${j:02x}: NR42, -, NR41, NR43, NR44' if j + 5 <= n else ''))
            return out
        r.block(k, n, em)
    return kits


def chained_lists(rom, bank, song_table, song_id):
    """$FFFF jumps that leave their list: the target is the continuation of that channel's list"""
    w = lambda a: rom[bank*0x4000 + a - 0x4000] | rom[bank*0x4000 + a - 0x3fff] << 8
    out = {}; seen = set(); work = []
    for i in range(127):
        h = w(song_table + 2*i)
        for ch in range(4):
            L = w(h + 3 + 2*ch)
            if L: work.append((L, ch, True))
    while work:
        L, ch, top = work.pop()
        if (L, ch) in seen: continue
        seen.add((L, ch))
        a = L; words = set()
        while True:
            words.add(a); v = w(a)
            if v >> 8 == 0: break
            if v == 0xffff:
                t = w(a + 2)
                if t not in words and not (L <= t <= a):
                    if not top or True: out.setdefault(t, set()).add(ch)
                    work.append((t, ch, False))
                break
            if v >> 8 == 0xff: a += 4; continue
            a += 2
    return out


def build_bank(rom, bank, names, comments, song_id, note_table, noise_table, vib, pan_table, hurry, unused_code, unused_names, extra_lists=None,
               extra_patterns=None, extra_waves=(), raw=(), orphans=()):
    song_table = 0x4043
    lentabs = [noise_table + 1 + 5*25 + 15*i for i in range(11)]
    release = lentabs[-1] + 15
    extra_lists = dict(extra_lists or {})
    w = lambda a: rom[bank*0x4000 + a - 0x4000] | rom[bank*0x4000 + a - 0x3fff] << 8
    for h in orphans:
        for ch in range(4):
            if w(h + 3 + 2*ch): extra_lists[w(h + 3 + 2*ch)] = {ch}
    for t, chs in chained_lists(rom, bank, song_table, song_id).items(): extra_lists.setdefault(t, chs)
    fix0 = make_fix(bank, hurry, unused_code, unused_names)
    def fix(r):
        fix0(r)
        for h in orphans:
            r.label(h, f'Unused_{h:04X}_Header', 'unreferenced song header (no song table entry)')
            r.block(h, 11, lambda rr, a: [f'\tSONG ${rr.byte(a):02x}, ' + ', '.join(rr.sym_addr(rr.word(a+1+2*i)) if rr.word(a+1+2*i) else '0' for i in range(5))])
            for ch in range(4):
                L = w(h + 3 + 2*ch)
                if L: r.label(L, f'Unused_{h:04X}_Ch{ch+1}')
            lt = w(h + 1)
            if lt >= 0x5000 and r.block_of(lt) is None:
                r.label(lt, f'LengthTable_{lt:04X}')
                r.block(lt, 15, lambda rr, a: ['\tdb ' + ', '.join(f'${rr.byte(a+i):02x}' for i in range(15))])
        for a, b, what in raw:
            r.label(a, f'Unused_{a:04X}', what)
            r.block(a, b - a, lambda rr, a, n=b-a: ['\tdb ' + ', '.join(f'${rr.byte(a+i):02x}' for i in range(j, min(j+16, n))) for j in range(0, n, 16)])
    saved = LM.Songs.__init__
    def init(self, r, cfg, _s=saved):
        cfg = dict(cfg); cfg['list_cmds'] = LIST_CMDS
        _s(self, r, cfg)
    LM.Songs.__init__ = init
    try:
        r, songs = LM.build_music(rom, bank, 'KTT', names, comments, song_table, 127, song_id, [0x4000, 0x4003, 0x4006],
                                  note_table, noise_table, lentabs, release, vib, None, pan_table, ram=RAM, cmds=CMDS, fix=fix,
                                  extra_code=[a for a, b in unused_code], pan_count=64, extra_lists=extra_lists or {},
                                  extra_patterns=extra_patterns or {}, extra_waves=list(extra_waves))
    finally:
        LM.Songs.__init__ = saved
    drumkit_blocks(r, songs)
    return r, songs


def gen_0e(rom, smb_rom=None):
    names = dict(NAMES_0E)
    r, songs = build_bank(rom, 0x0e, names, COMMENTS_0E, song_id_0e, 0x4bc7, 0x4c59, 0x4b6a, 0x41c6, HURRY_0E,
                          UNUSED_CODE_0E, {}, extra_patterns={0x53a9: {0}, 0x53c4: {0}, 0x53f1: {0}, 0x541a: {0}},
                          extra_waves=[0x6d46, 0x6d76, 0x6d86],
                          raw=[(0x5311, 0x5320, 'unreferenced length table'), (0x549e, 0x54a3, 'unreferenced'),
                               (0x5977, 0x5986, 'unreferenced length table'), (0x6da6, 0x6e76, 'unreferenced'), (0x5484, 0x5493, 'unreferenced length table'),
                               (0x6e90, 0x6e91, 'unreferenced')])
    return r, songs


def gen_0f(rom, r0e):
    from gbdis import Region
    rr = Region(rom, 0x0f, 0x4000, 0x8000)
    rr.trace([0x4000, 0x4003, 0x4006])
    pcmap, valmap, m, ns, nd = align(r0e, rr)
    def shift(a):
        p = max(x for x in pcmap if x < a)
        return a + pcmap[p] - p
    unused = [(shift(a), shift(a) + b - a) for a, b in UNUSED_CODE_0E]
    for (a, b), (a2, b2) in zip(UNUSED_CODE_0E, unused):
        assert rom[0xe*0x4000 + a - 0x4000] == rom[0xf*0x4000 + a2 - 0x4000], (hex(a), hex(a2))
    rr = Region(rom, 0x0f, 0x4000, 0x8000)
    rr.trace([0x4000, 0x4003, 0x4006] + [a for a, b in unused])
    pcmap, valmap, m, ns, nd = align(r0e, rr)
    names = {}
    used = set()
    for a, n in sorted(r0e.labels.items()):
        if n.startswith(('Code_', 'Data_', 'Song', 'Pattern_', 'Wave_', 'LengthTable_', 'UnusedList_', 'Envelope_', 'DrumKit_')): continue
        b = pcmap.get(a)
        if b is None and a not in r0e.code and a < 0x5000: b = valmap.get(a)
        if b is None or n in used: continue
        names[b] = n; used.add(n)
    for a in [a for a, n in names.items() if n.startswith('Music_Length.hurry')]: del names[a]
    names.update(NAMES_0F_MANUAL)
    comments = {}
    for a, t in COMMENTS_0E.items():
        b = pcmap.get(a, valmap.get(a) if a not in r0e.code else None)
        if b is not None: comments[b] = t
    for (a, b), (a2, b2) in zip(UNUSED_CODE_0E, unused):
        for x, n in r0e.labels.items():
            if a <= x < b: names[x - a + a2] = n
    comments[pcmap[0x4187]] = 'Request $80 replays wPreviousSong. This bank takes songs $40-$7F (bank $0E: $01-$3F) and\nclaims the music (wMusicBank = 1).'
    comments[pcmap[0x470a]] = 'In hurry mode (wHurryMode, set by the game) songs $64 and $41 read their lengths from a\ntable stored just before their header.'
    r, songs = build_bank(rom, 0x0f, names, comments, song_id_0f, valmap[0x4bc7], valmap[0x4bc7] + 146, valmap[0x4b6a], valmap[0x41c6],
                          HURRY_0F, unused, {}, extra_patterns={0x500a: {0}}, extra_waves=[0x5b12, 0x5b32, 0x5b42, 0x5b52],
                          raw=[(0x5701, 0x5703, 'unreferenced: pointer to Song64_HurryLengths'), (0x5b62, 0x5c32, 'unreferenced'),
                               (0x5c4c, 0x5c51, 'unreferenced'), (0x679c, 0x679d, 'unreferenced'), (0x6931, 0x6940, 'unreferenced length table')],
                          orphans=[0x51f8, 0x5278])
    return r, songs, (m, ns, nd)
