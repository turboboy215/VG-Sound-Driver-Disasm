"""Names for code and tables."""
import struct

MUS_CMD_NAMES = ['Rest', 'Hold', 'PitchMac', 'PitchMacOff', 'Tempo', 'Transpose', 'Envelope', 'EnvelopeOff',
                 'MasterVol', 'PanRight', 'PanLeft', 'PanCentre', 'Duty0', 'Duty1', 'Duty2', 'Duty3', 'Wave',
                 'Detune', 'PitchDetune', 'Gate', 'NRx2', 'Goto', 'Loop1', 'Loop2', 'Loop3', 'Loop4', 'Gosub',
                 'Retsub'] + [f'Nudge{"M" if d < 0 else "P"}{abs(d)}' for d in list(range(-8, 0)) + list(range(1, 9))] + \
                ['Retrig', 'Slide']
assert len(MUS_CMD_NAMES) == 46

# channel-1 routine names (bank $20)
CH1 = {
    0x4000: 'Update', 0x4023: 'Read', 0x40DA: 'StartEvent', 0x40E7: 'TrackEnd', 0x40EF: 'SetLength',
    0x4099: 'Nudge', 0x40A9: 'Note', 0x40C1: 'Drum',
    0x4273: 'CmdTable',
    0x42CF: 'NoteOn', 0x42DE: 'Release', 0x42F4: 'NoteOff', 0x42FE: 'Silence', 0x4309: 'PrepTrigger',
    0x431E: 'PrepPitch', 0x4329: 'CalcPeriod', 0x4342: 'AddPitchDetune', 0x435B: 'AddDetune',
    0x4374: 'DrumStop', 0x4379: 'DrumStart', 0x438F: 'DrumUpdate', 0x43AD: 'PitchMacStart',
    0x43BD: 'PitchMacStop', 0x43C2: 'SetPitchMac', 0x43CD: 'PitchMacUpdate', 0x43E3: 'PitchMacRead',
    0x43E6: 'PitchMacByte', 0x4429: 'EnvAttack', 0x4439: 'EnvRelease', 0x4449: 'EnvStop',
    0x444E: 'SetEnvelope', 0x445A: 'EnvUpdate', 0x44B8: 'SlideUpdate',
}
CH3_MAP = {0x42FE: 0x4D48, 0x4309: 0x4D52, 0x44B8: 0x4F13}
CH4 = {
    0x4F80: 'Update', 0x4FA3: 'Read', 0x5050: 'StartEvent', 0x505D: 'TrackEnd', 0x5065: 'SetLength',
    0x5019: 'Nudge', 0x5029: 'Note', 0x5037: 'Drum', 0x51DE: 'CmdTable',
    0x523A: 'NoteOn', 0x5246: 'Release', 0x525C: 'NoteOff', 0x5263: 'Silence', 0x526E: 'PrepTrigger',
    0x5283: 'PrepPitch', 0x528E: 'CalcNoise', 0x52A2: 'AddDetune_Unused', 0x52BB: 'DrumStop',
    0x52C0: 'DrumStart', 0x52D6: 'DrumUpdate', 0x52F4: 'EnvAttack', 0x5304: 'EnvRelease',
    0x5314: 'EnvStop', 0x5319: 'SetEnvelope', 0x5325: 'EnvUpdate',
}
ENGINE20 = {
    0x5383: 'Music_Init', 0x53BA: 'Music_Play', 0x543E: 'Music_Stop', 0x5468: 'Music_Pause',
    0x5482: 'Music_Resume', 0x5490: 'Music_Save', 0x54A9: 'Music_Restore', 0x54C5: 'Music_Update',
    0x5521: 'Music_WriteRegs', 0x56FD: 'Music_FadeOut', 0x5711: 'Music_FadeUpdate',
    0x5735: 'FadeStepTable', 0x574B: 'Fade_Done', 0x575B: 'Fade_StopChannels', 0x57B4: 'Fade_KeepTopBits',
    0x57C5: 'Fade_VolumeDown', 0x57ED: 'Music_SilenceAll', 0x5817: 'Music_LoadWave',
    0x583C: 'Music_PitchToPeriod', 0x5857: 'Music_SoundTest', 0x590E: 'SongTable',
    0x5A31: 'DrumTable', 0x6230: 'EnvelopeTable', 0x6F71: 'MusicWaves', 0x7401: 'PitchMacroTable',
}

MUS_BASES = {1: 0x4000, 2: 0x4525, 3: 0x4A4A}
MUS_TABLES = {1: 0x4273, 2: 0x4798, 3: 0x4CBD, 4: 0x51DE}


def bank20_names(rom):
    o = 0x20 * 0x4000 - 0x4000
    names = {}
    for a, n in CH1.items():
        names[a] = f'MusCh1_{n}'
        names[a + 0x525] = f'MusCh2_{n}'
        if a in CH3_MAP:
            a3 = CH3_MAP[a]
        elif a <= 0x42F4 or a == 0x4273:
            a3 = a + 0xA4A
        else:
            a3 = a + 0xA4E
        names[a3] = f'MusCh3_{n}'
    for a, n in CH4.items():
        names[a] = f'MusCh4_{n}'
    names.update(ENGINE20)
    # command handlers
    for ch, t in MUS_TABLES.items():
        for k in range(46):
            h = struct.unpack('<H', rom[o + t + 2 * k:o + t + 2 * k + 2])[0]
            if h >= 0x4000 and h not in names:
                names[h] = f'MusCh{ch}_Cmd{MUS_CMD_NAMES[k]}'
    return names


SFXA_NAMES = {
    0x4000: 'SfxA_Init', 0x4012: 'SfxA_Update', 0x4064: 'SfxA_StartSingle', 0x4078: 'SfxA_StartMulti',
    0x40C0: 'SfxA_StopAll', 0x40E0: 'SfxA_Unused40E0', 0x40E1: 'SfxA_FindChannel_Unused',
    0x40FC: 'SfxA_ClearMem', 0x4102: 'SfxA_GetTableEntry', 0x4110: 'SfxA_JumpTable', 0x411A: 'SfxA_NoteToPeriod',
    0x4145: 'SfxA_SetupSlide', 0x4167: 'SfxA_MuteMusicCh', 0x4173: 'SfxA_UnmuteMusicCh',
    0x417F: 'MusicChFlagPtrs',
    0x4187: 'Sfx1_Request', 0x4192: 'Sfx1_Start', 0x41D6: 'Sfx1_Update', 0x4268: 'Sfx1_Stop', 0x4277: 'Sfx1_CmdTable',
    0x436C: 'Sfx2_Request', 0x4377: 'Sfx2_Start', 0x43BB: 'Sfx2_Update', 0x444A: 'Sfx2_Stop', 0x4459: 'Sfx2_CmdTable',
    0x4545: 'Sfx3_Request', 0x4550: 'Sfx3_Start', 0x4599: 'Sfx3_Update', 0x4629: 'Sfx3_Stop', 0x463B: 'Sfx3_CmdTable',
    0x4740: 'Sfx4_Request', 0x474B: 'Sfx4_Start', 0x4790: 'Sfx4_Update', 0x47EA: 'Sfx4_Stop', 0x47F9: 'Sfx4_CmdTable',
    0x48CF: 'Sfx4_NoteToNoise', 0x48E5: 'SfxWaves', 0x4925: 'SfxMultiTable',
    0x60A4: 'Sfx1_Table', 0x6EE5: 'Sfx2_Table', 0x6F28: 'Sfx3_Table', 0x7106: 'Sfx4_Table',
}
SFXA_TABLES = {1: 0x4277, 2: 0x4459, 3: 0x463B, 4: 0x47F9}

SFXB_NAMES = {
    0x4000: 'SfxB_Table', 0x4942: 'SfxB_Ch1Update', 0x4A1C: 'SfxB_Ch2Update', 0x4AEF: 'SfxB_Ch4Update',
    0x4B9E: 'SfxB_Start', 0x4C03: 'SfxB_Update', 0x4C5C: 'SfxB_Stop',
}

HOME_NAMES = {
    0x1543: 'Sound_Init', 0x156A: 'Sound_PlayMusic', 0x1589: 'Music_GetSongHeader', 0x15A0: 'Music_FetchHeaderByte',
    0x15B4: 'Sound_Update', 0x15DB: 'Music_FetchByte', 0x15EF: 'Sound_StopAll', 0x1616: 'Sound_FadeOut',
    0x162B: 'Sound_LoadWave', 0x163F: 'Music_CopyWave', 0x1656: 'Sound_PauseMusic', 0x166A: 'Sound_ResumeMusic',
    0x167E: 'Sound_SaveMusic', 0x1692: 'Sound_RestoreMusic', 0x16A6: 'Sound_IsIdle', 0x16C9: 'Sound_SoundTest',
    0x16DD: 'PeriodTable', 0x176D: 'FineTuneTable', 0x19AD: 'NoiseTable', 0x19E9: 'NoiseTable7',
    0x1A25: 'Pcm_Play', 0x1AA6: 'Pcm_Delay', 0x1ABA: 'Sound_PlayPCM', 0x1ADA: 'PcmTable',
    0x1AEE: 'SfxB_FarUpdate', 0x1B02: 'SfxB_FarStop',
}
_stub = ['FarGoto', 'LoadPitchMac', 'PitchMacFetch', 'PitchMacGoto', 'LoadEnvelope', 'EnvFetch', 'LoadDrum', 'CallDrum']
for _ch, _base in ((1, 0x128D), (2, 0x134C), (3, 0x140B)):
    _offs = [0x00, 0x18, 0x31, 0x46, 0x5E, 0x7F, 0x92, 0xAB]
    for _o, _n in zip(_offs, _stub):
        HOME_NAMES[_base + _o] = f'MusCh{_ch}_{_n}'
for _o, _n in zip([0x14CA, 0x14E2, 0x1503, 0x1516, 0x152F], ['FarGoto', 'LoadEnvelope', 'EnvFetch', 'LoadDrum', 'CallDrum']):
    HOME_NAMES[_o] = f'MusCh4_{_n}'
HOME_EXTERN = {0x09A6: 'FarCall', 0x01EF: 'Home_01EF'}

# routine header comments: (bank, addr) -> lines
COMMENTS = {
    (0, 0x128D): ['Bank $20 helpers. The music engine reads its track data from bank wMusicBank and its',
                  'instrument tables from bank $20 through these stubs (one set per channel).',
                  'FarGoto: read a 16-bit pointer at bc from the song bank, continue reading there.'],
    (0, 0x1543): ['Sound_Init: reset the music engine, then SFX engine A (which also stops engine B).'],
    (0, 0x156A): ['Sound_PlayMusic: a = song number (SongTable). Ignored while wSoundOff is set.'],
    (0, 0x1589): ['hl = SongTable entry + 2: wMusicBank = [hl], hl = song header address.'],
    (0, 0x15B4): ['Sound_Update: once per frame. Engines B and A (bank $21), then the music (bank $20).'],
    (0, 0x15DB): ['Music_FetchByte: e = [bc] in bank wMusicBank, bc++.'],
    (0, 0x15EF): ['Sound_StopAll: stop every effect (engine B, engine A) and the music.'],
    (0, 0x1616): ['Sound_FadeOut: a = frames per fade step (0 is ignored while wSoundOff is set).'],
    (0, 0x162B): ['Sound_LoadWave: load music wave wMusicWave into wave RAM.'],
    (0, 0x167E): ['Sound_SaveMusic / Sound_RestoreMusic: nothing in the game calls these.'],
    (0, 0x16A6): ['Sound_IsIdle: carry set when sound is off, or when no music channel is active and no fade runs.'],
    (0, 0x16C9): ['Sound_SoundTest: debug sound test (Music_SoundTest); nothing calls it.'],
    (0, 0x16DD): ['Period for each semitone C2-B7 (72 entries). Index = pitch >> 3.'],
    (0, 0x176D): ['Fine tune: 8 period offsets per semitone, added to PeriodTable. Index = pitch (semitone*8 + eighth).'],
    (0, 0x19AD): ['NR43 values for the ch4 note/noise index (music, and SFX engine A in 15-bit LFSR mode).'],
    (0, 0x19E9): ['Same with the 7-bit LFSR bit set (SFX engine A after SFX4_LFSR7).'],
    (0, 0x1A25): ['Pcm_Play: play bc bytes of 2-bit PCM from e:hl through ch3, blocking. The wave RAM is filled',
                  'with $FF, so NR32 (output level) is the sample value. Each byte holds two samples:',
                  'bits 5-4 level, bits 7-6 extra hold; bits 1-0 level, bits 3-2 extra hold.',
                  'On CGB (hConsoleType = $11) every delay is done twice.'],
    (0, 0x1ABA): ['Sound_PlayPCM: a = sample 0-3 (PcmTable). Ignored while wSfxDisable is set.'],
    (0, 0x1ADA): ['PCM samples: address, bank, length in bytes.'],
    (0, 0x1AEE): ['SfxB_FarUpdate: run engine B (bank $7F); e = number of active engine B channels.'],
    (0x20, 0x4000): ['Channel 1 tick: count the event down; at 0 read the next track bytes.',
                     'Channels 2-4 have their own copies of everything up to EnvUpdate/SlideUpdate.'],
    (0x20, 0x4023): ['Track byte: $00 end, $01-$6C length, $6D-$89 drum, $8A-$D1 note, $D2-$FF command.'],
    (0x20, 0x4202): ['GOSUB: push the return address. The stack holds 3 entries; a 4th overwrites StackPos',
                     'and Transpose (the songs nest at most 2 deep).'],
    (0x20, 0x41DD): ['LOOP 1-4: count, target. While the counter differs from count: counter++, jump.',
                     'On exit the engine skips 3 bytes after count, one more than the pointer (no song uses LOOP).'],
    (0x20, 0x42CF): ['Note on: trigger, stop any drum, restart the pitch macro and the attack envelope.'],
    (0x20, 0x42DE): ['Release: start the release envelope if there is one (once per note), else note off.'],
    (0x20, 0x42FE): ['Silence: NRx2 = $01 (DAC off) unless the channel is muted.'],
    (0x20, 0x4329): ['Period = PeriodTable[pitch>>3] + FineTuneTable[pitch], with PitchDetune before and Detune after.'],
    (0x20, 0x4379): ['Drum n: point the RAM trampoline (jp) at DrumTable[n]. ch1 uses the table from entry 0,',
                     'ch2-ch4 from entry 7.'],
    (0x20, 0x438F): ['Every frame: call the drum routine; it writes the registers itself and returns the next',
                     'routine in de (0 = finished).'],
    (0x20, 0x43E6): ['Pitch macro byte: $00 end (see quirk: the stop flag is never cleared), $01-$63 speed,',
                     '$64 lo hi goto, $65-$FF add (byte - $85)/8 semitone and wait.'],
    (0x20, 0x445A): ['Envelope step (every frame): $00 end; else NRx2 value (retrigger), then bytes with bit 7',
                     'set (NRx1 length, enables the length counter), then a frame count.'],
    (0x20, 0x44B8): ['SLIDE: move the pitch by SlideStep per tick, landing exactly on the target on the last tick.'],
    (0x20, 0x5383): ['Music_Init: clear $C5F0-$C6CD, reset the APU (NR52 off/on), NR50 $77, NR51 $FF, silence.'],
    (0x20, 0x53BA): ['Music_Play: l = song. Keeps the channel mute bits, re-inits, loads the 4 track pointers.'],
    (0x20, 0x54C5): ['Music_Update: tempo accumulator (ticks per frame = wMusicTempo/30). On tick frames:',
                     'tracks, pitch macros, slides. Every frame: envelopes, drums, fade, register writes.'],
    (0x20, 0x5521): ['Write the shadow registers marked in each channel\'s Update byte (skipped while muted).',
                     'NR50/NR52 are only written while engine B is idle.'],
    (0x20, 0x5711): ['Fade: every wFadeSpeed frames take the next step of FadeStepTable.'],
    (0x20, 0x5735): ['7 x NR50 volume -1, NR50 = 0, stop the channels, one idle step, music off.'],
    (0x20, 0x583C): ['de = pitch -> de = period (PeriodTable + FineTuneTable).'],
    (0x20, 0x5857): ['Debug sound test driven by hJoyPressed: A/B next/previous song (0-$60), Right/Down/Left/Up',
                     'mute ch1/ch2/ch3/ch4, Select fade out (speed 10), Start pause/resume.'],
    (0x20, 0x590E): ['97 entries: pointer, bank. Entry 0 and entries $21-$60 (except $4F/$50/$54) point at the',
                     'silent Song_00 header.'],
    (0x20, 0x5A31): ['Drum routines (code), called every frame through wMusChNDrumJp.'],
    (0x20, 0x6230): ['ENVELOPE n: attack sequence (at note on) and release sequence (at REST/GATE).'],
    (0x20, 0x6F71): ['73 waves of 16 bytes (WAVE n).'],
    (0x20, 0x7401): ['PITCHMAC n.'],
    (0x21, 0x4000): ['SfxA_Init: clear $C7CA-$C832 and stop engine B.'],
    (0x21, 0x4012): ['SfxA_Update: skipped (and requests dropped) while engine B plays or wSfxDisable is set.',
                     'Starts the multi request, then the two single requests, runs the 4 channels and writes',
                     'wMusicPan to NR51.'],
    (0x21, 0x4064): ['a = request: bits 7-6 channel (ch1-ch4), bits 5-0 effect number in that channel\'s table.'],
    (0x21, 0x4078): ['a = multi effect: start up to 4 channels from SfxMultiTable.'],
    (0x21, 0x4192): ['Start: pointer word bits 15-14 = priority. A lower priority than the running effect is',
                     'ignored. Mutes the music channel (flags bit 0).'],
    (0x21, 0x41D6): ['Per frame: count down; at 0 read: $01-$89 wait, $8A-$D1 note (period only), $E0-$FF',
                     'command, $00/$D2-$DF end.'],
    (0x21, 0x411A): ['e = note, a = fine (0-7, bit 7 set: negative) -> d:a = period.'],
    (0x7F, 0x4942): ['Engine B channel: rows of frames, NRx2, NRx3, NRx4 written straight to the hardware.',
                     '$FE duty sequence, $FD NR10, $FF end. Mutes the music channel every frame.'],
    (0x7F, 0x4B9E): ['SfxB_Start: a = effect. Clears engine A, resets the APU, loads ch1/ch2/ch4 streams.'],
    (0x7F, 0x4C03): ['SfxB_Update: multi effects $0A-$0C stop engine B; start a request; run the channels.'],
}
