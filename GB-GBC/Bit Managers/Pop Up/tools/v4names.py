"""The Smurfs (reference for version 4) routine names and comments.
Names are carried over to Obelix GB / GBC by aligning the code (gen_v4.transfer)."""

SMF_LABELS = {
    0x4000: 'SndAPI', 0x4051: 'Unused_OldSfxGlue',
    0x4063: 'SndResume', 0x406A: 'SndPause', 0x407E: 'PauseTrigger', 0x4090: 'SndUpdate',
    0x40AB: 'OutputCh1', 0x40C3: 'OutputCh1Env', 0x40D4: 'OutputCh2', 0x40EA: 'OutputCh2Env',
    0x40FB: 'OutputCh3', 0x4103: 'OutputWaveCh', 0x4116: 'WriteCh3Vol', 0x412B: 'SetNR51',
    0x413D: 'SetNR51_Ch3', 0x4154: 'WriteNR51', 0x4159: 'UpdatePaused', 0x4166: 'Ch3VolTable',
    0x4176: 'ChannelTick', 0x419A: 'UpdatePeriod', 0x41A9: 'SetPeriod', 0x41C7: 'VibStep',
    0x41DA: 'VibUp', 0x41E4: 'VibDownPhase', 0x41F1: 'VibDown', 0x41FC: 'ArpLoop', 0x41FE: 'DoArp',
    0x4208: 'ArpByte', 0x4217: 'ReadStream', 0x421E: 'ReadByte', 0x424B: 'NoteOnRelease',
    0x4258: 'NoteOnEnvelope', 0x427A: 'NoteOnHwEnv', 0x4287: 'Cmd_RepeatEnd', 0x4291: 'Cmd_Repeat',
    0x429B: 'StreamCommand', 0x42C1: 'CallBC', 0x42C3: 'Cmd_Len', 0x42CB: 'Cmd_VolEnv',
    0x42F3: 'Cmd_Arp', 0x4312: 'Cmd_Instrument', 0x4331: 'InstrDutyCh2', 0x4335: 'InstrLookup',
    0x4352: 'InstrLoop', 0x4361: 'Unused_Garbage1', 0x4400: 'CmdTable',
    0x4448: 'Cmd_SlideUp', 0x445B: 'Cmd_SlideDown', 0x4470: 'Cmd_Vol', 0x4476: 'Cmd_CallCode',
    0x447E: 'Unused_Ret', 0x447F: 'Cmd_ArpOff', 0x4488: 'CheckRelease', 0x4497: 'CheckRelease2',
    0x44BE: 'SetReleased', 0x44C3: 'ReleaseCh3', 0x44D8: 'ReleaseSfx', 0x44ED: 'Cmd_Release',
    0x44FD: 'ReleaseOff', 0x4502: 'Cmd_ChTranspose', 0x450A: 'Cmd_Glide', 0x4510: 'Cmd_GlideOff',
    0x4515: 'Cmd_Vibrato', 0x4529: 'Cmd_VibOff', 0x4530: 'Cmd_Rest', 0x453F: 'Cmd_Wait',
    0x454A: 'SndInit', 0x4565: 'StopAll', 0x4594: 'Cmd_End', 0x4595: 'ResetChannel',
    0x45C4: 'ResetSfxPage', 0x45D8: 'Cmd_Transpose', 0x45E4: 'PatReturn', 0x45EC: 'Cmd_PatCall',
    0x45F9: 'Cmd_PatGoto', 0x4600: 'Cmd_Next', 0x4618: 'NextOrderEnd', 0x462F: 'Cmd_Length',
    0x4635: 'Cmd_HwEnv', 0x4649: 'HwEnvNoEnv2', 0x464D: 'Cmd_AutoPan', 0x4656: 'DoAutoPan',
    0x466F: 'Cmd_PanC', 0x4674: 'Cmd_PanR', 0x4679: 'Cmd_PanL', 0x467E: 'Cmd_AutoDuty',
    0x4687: 'DoAutoDuty', 0x46A0: 'Cmd_Duty50', 0x46A4: 'Cmd_Duty75', 0x46A8: 'Cmd_Duty12',
    0x46AA: 'SetDuty', 0x46B3: 'SetDutyCh2', 0x46B7: 'StartFade', 0x46C4: 'Cmd_Fade',
    0x46D3: 'FadeInit', 0x46DF: 'Cmd_FadeOff', 0x46E4: 'DoFade', 0x46F3: 'FadeRun',
    0x46FE: 'FadeStep', 0x4725: 'FadeLoop', 0x472B: 'Cmd_Wave', 0x4741: 'WaveRewind',
    0x4742: 'LoadWave', 0x4788: 'RestoreMusicWave', 0x47D1: 'Unused_Garbage2', 0x4800: 'PeriodTable',
    0x48A2: 'DoEnvelope', 0x48B7: 'SoftEnvelope', 0x48D2: 'StoreVol', 0x48D4: 'EnvDecay',
    0x48EC: 'StoreVol2', 0x48F0: 'StartMusicCh1', 0x48F4: 'StartMusicCh2', 0x48F8: 'StartMusicCh3',
    0x4905: 'StartMusicCh', 0x491A: 'PlaySfxEntry', 0x491D: 'PlaySfx', 0x4926: 'PlaySfxNow',
    0x4961: 'SongFadeOut', 0x4967: 'SongFadeIn', 0x496D: 'Cmd_DrumsOff', 0x4972: 'Cmd_Drums', 0x4998: 'NoisePanCentre',
    0x499E: 'DrumStep', 0x49A9: 'DrumRead', 0x49AC: 'DrumReadAt', 0x49BC: 'DrumByte',
    0x49FB: 'DrumTable_m2', 0x49FD: 'DrumTable', 0x4A13: 'DrumTempo', 0x4A1D: 'DrumLoop',
    0x4A23: 'DrumAtten', 0x4A2C: 'DrumNextByte', 0x4A2F: 'DrumNextByte2', 0x4A36: 'DrumPanC',
    0x4A3D: 'DrumPanR', 0x4A4A: 'DrumPanL', 0x4A57: 'DrumNoiseSpeed', 0x4A62: 'DrumAutoPan',
    0x4A6D: 'DrumRepeatEnd', 0x4A7C: 'DrumRepeat', 0x4A89: 'DrumTick', 0x4A93: 'DrumTimerTick',
    0x4AAA: 'NoiseSeqStep', 0x4AE2: 'NoiseWriteNR42', 0x4AEE: 'NoiseNR42', 0x4AF4: 'NoiseAutoPan',
    0x4B0B: 'NoiseAutoPan2', 0x4B14: 'NoiseAutoPan3', 0x4B1D: 'NoiseAutoPan4', 0x4B25: 'NoiseSeqEnd',
}

# names for Obelix GBC routines that have no Smurfs counterpart
GBC_LABELS = {
    0x40B7: 'Cmd_NoteHook', 0x40D0: 'NoteHookOff', 0x4289: 'NoteOnHook', 0x42A1: 'NoteOn',
    0x436E: 'Unused_SetVolEnvBC', 0x44FD: 'Cmd_Wait', 0x4513: 'WaitReload', 0x44EA: 'Cmd_Rest',
    0x4612: 'HwEnvAtten', 0x46A0: 'StartFade', 0x46CB: 'FadeEndPause', 0x46CE: 'FadeStop',
    0x4092: 'PlaySfxEntry2', 0x4916: 'PlaySfxEntry', 0x4919: 'PlaySfx',
    0x4953: 'SongFadeOut', 0x4959: 'SongFadeIn', 0x4095: 'SndResume', 0x409C: 'SndPause',
    0x40A2: 'SilenceAll', 0x453B: 'StopAll', 0x411C: 'OutputCh1Retrig', 0x4125: 'OutputCh1Hi',
    0x4151: 'OutputCh2Retrig', 0x415A: 'OutputCh2Hi', 0x4AEA: 'NoiseNR42',
}
GB_LABELS = {
    0x491A: 'PlaySfxIgnore', 0x491C: 'PlaySfx', 0x4925: 'PlaySfxNow',
    0x495F: 'SongFadeOut', 0x4965: 'SongFadeIn',
}

# block comments, keyed by label name
COMMENTS = {
    'SndAPI': 'Entry points (jump table at the start of the bank). The game calls these with the\n'
              'bank switched in: SndUpdate, SndPause, SndResume, StopAll, PlaySfx (A = id), SndInit,\n'
              'SongFadeIn, SongFadeOut (A = speed), then one entry per song.',
    'Unused_OldSfxGlue': 'Not reached: an older copy of the game\'s PlaySfx glue (ids $1E-$20 -> noise\n'
                         'routines), the same bytes as the live copy in the data area.',
    'SndResume': 'SndResume: wPaused = 0, reload the music wave.',
    'SndPause': 'SndPause: silence CH1, CH2, CH4 (and CH3 unless an SFX plays), wPaused = 1.\n'
                'While paused only the SFX page is ticked and output.',
    'SndUpdate': 'SndUpdate (once per frame): tick the four pages (or only the SFX page while paused),\n'
                 'drums + noise sequence, output, NR51, then the NR50 fade.',
    'OutputCh1': 'Output, pulse pages: NRx3 = period low + pitch offset (fields $25/$26, vibrato and\n'
                 'slides); NRx4 = high byte (no trigger) when it differs from the shadow ($07). When\n'
                 'the envelope flag ($33) is set: NRx2 = field $32, NRx4 = high | $80 (retrigger).\n'
                 'The pulse channels have no software volume in this version.',
    'OutputCh3': 'Output, wave channel: the SFX page if an SFX plays, else Ch3. Period as above;\n'
                 'NR32 = Ch3VolTable[volume] when it differs from wShNR32.',
    'SetNR51': 'NR51 = Ch1 pan | Ch2 pan << 1 | (SFX or Ch3) pan << 2 | wNoisePan; $FF while\n'
               'wStereo = 0 (the game sets it).',
    'UpdatePaused': 'Paused: NR50 fade, tick and output only the SFX page.',
    'Ch3VolTable': 'CH3 volume table (0-15 -> NR32).',
    'ChannelTick': 'ChannelTick (h = page, skipped while field $27 = 0): auto-duty, auto-pan; ticks\n'
                   'left - 1, at 0 read the stream; then arpeggio, glide + note -> period, envelope,\n'
                   'release check, vibrato / slide.',
    'UpdatePeriod': 'UpdatePeriod: note += glide (field $0B, every tick); index = note + channel\n'
                    'transpose ($0D, default -12) + arpeggio offset ($0E) + global transpose ($0F);\n'
                    'indexes of 80 and above wrap to 0.',
    'VibStep': 'Vibrato / slide (flag b3): after the delay ($21), the pitch offset ($25/$26) moves\n'
               'by depth ($22) per tick, up while b4 is set and down while it is clear; the\n'
               'direction flips every speed ($24) ticks (counter $23, half a speed after a note).',
    'DoArp': 'DoArp: next arpeggio byte into field $0E; $6A (the NEXT byte) loops, $FF holds.',
    'ReadStream': 'ReadStream (de = stream). A note: store the pointer and the note, restart the\n'
                  'arpeggio, ticks left = length, clear the pitch offset, restart vibrato (direction\n'
                  'down unless a slide is set), re-arm the release; CH3/SFX page: split the\n'
                  'envelope bytes and volume = start volume; pulse pages: NRx2 = HWENV value and\n'
                  'start the 2nd-envelope timer. The note ends the read.',
    'Cmd_RepeatEnd': 'REPEAT_END: count - 1; while not 0, jump back to the REPEAT position.',
    'Cmd_Repeat': 'REPEAT n (bytes from the top of the range): play the following bytes n times\n'
                  '(count field $39, position $3A/$3B; one level).',
    'StreamCommand': 'StreamCommand: REPEAT / LEN / VOLENV / ARP / INSTR ranges, else CmdTable.',
    'Cmd_Len': 'LEN n: note length in ticks.',
    'Cmd_VolEnv': 'VOLENV v, atk, dec, rates: start volume v; attack = lo nibble steps of hi nibble;\n'
                  'decay likewise; rates hi = ticks per attack step, lo = ticks per decay step.\n'
                  'Only the CH3 and SFX pages use it.',
    'Cmd_Arp': 'ARP n: arpeggio n of wArpTable.',
    'Cmd_Instrument': 'INSTR n: clear arpeggio, glide, arpeggio offset and auto-duty; pulse pages: 50 %\n'
                      'duty; then run macro n (entry n + 1 of wInstrTable) up to END with wInInstr = $C9.',
    'CmdTable': 'Command jump table ($60-...).',
    'Cmd_SlideUp': 'SLIDE_UP n / SLIDE_DOWN n: the vibrato machinery without delay and with speed 1:\n'
                   'from each note on, the pitch offset moves n per tick in one direction for 255\n'
                   'ticks (the counter starts at 1 >> 1 = 0). Flag b5 keeps the direction at note on.',
    'Cmd_Vol': 'VOL n: start volume (CH3/SFX pages).',
    'Cmd_CallCode': 'CALL_CODE w: call machine code at w; it returns into the command loop.',
    'Unused_Ret': 'Not reached.',
    'CheckRelease': 'CheckRelease (RELEASE t, env; t = min length (hi) / ticks left (lo)): skipped for\n'
                    'notes shorter than the minimum; on the tick where ticks left = lo nibble, unless\n'
                    'the next byte is WAIT: pulse NRx2 = env; CH3/SFX page: decay rate = env & $0F and,\n'
                    'if env >> 4 is not 0, volume = env >> 4.',
    'Cmd_Rest': 'REST: volume 0 (pulse pages also NRx2 = 0), then wait one length.',
    'Cmd_Wait': 'WAIT / WAIT2: wait one length (ends the read). The release check looks for WAIT\n'
                'only, so WAIT2 is a tie that lets the release happen.',
    'SndInit': 'SndInit: NR52 = $FF, default arpeggio table, clear flags; falls into StopAll.',
    'StopAll': 'StopAll: silence CH1-CH4, fade, drums and noise sequence off, noise pan centre,\n'
               'reset the four pages.',
    'Cmd_End': 'END: reset the page (the channel stops).',
    'ResetChannel': 'ResetChannel: centre pan, inactive, volume 0, flags, auto-pan/duty off, transposes\n'
                    '(channel transpose -12), glide, ticks left 1, NRx2 = 0 at the next output.\n'
                    'SFX page: id 0, volume 0, noise timers, NR32 shadow $FF, reload the music wave.',
    'Cmd_Next': 'NEXT: return from a PAT_CALL if one is pending, else the next order-list entry;\n'
                'a 0 entry is followed by the loop position.',
    'Cmd_HwEnv': 'HWENV env, t, env2: NRx2 value at each note on (pulse pages); if t is not 0,\n'
                 'NRx2 = env2 t ticks into the note. HWENV env, 0: no second value.',
    'DoAutoPan': 'Auto-pan: every n ticks the next of centre, right, centre, left, centre.',
    'DoAutoDuty': 'Auto-duty: every n ticks the next of 50, 75, 12.5, 75, 50 %. Written to NR11 on\n'
                  'the Ch1 page, NR21 on any other page.',
    'SetDuty': 'SetDuty: NR11 on the Ch1 page, NR21 on any other page (also Ch3/SFX).',
    'StartFade': 'StartFade (A = speed, HL = table) / FADE speed, table: one byte into NR50 every\n'
                 'speed + 1 ticks; $6A loops, $FF ends.',
    'DoFade': 'DoFade: while no fade runs, NR50 is forced back to $77 unless it is 0.',
    'Cmd_Wave': 'WAVE w: Ch3 page: remember w and load it unless an SFX plays; other pages: load w.',
    'LoadWave': 'LoadWave: NR30 = 0, copy 16 bytes, NR30 = NR34 = Ch3 period-hi shadow | $80.',
    'RestoreMusicWave': 'RestoreMusicWave: reload the music wave; unless paused, NR30 = NR34 = $80.',
    'Unused_Garbage1': 'Not reached: assembler leftovers (x86 code bytes) up to the command table.',
    'Unused_Garbage2': 'Not reached (leftover bytes before the aligned period table).',
    'PeriodTable': 'Period table: 81 entries from C2 (same values as all earlier versions), aligned\n'
                   'at $4800 so that only the low byte is computed.',
    'DoEnvelope': 'DoEnvelope: pulse pages: count down to the 2nd hardware envelope value.\n'
                  'CH3/SFX page: software envelope, attack then decay.',
    'StartMusicCh1': 'StartMusicChN (de = order list): reset the page, mark it active, start its first\n'
                     'pattern. StartMusicCh3 also stops the fade and the drums and sets NR50 = $77.',
    'PlaySfxEntry': 'API entry for PlaySfx: goes through the game\'s glue in the data area first.',
    'PlaySfx': 'PlaySfx (A = id): ignored while a lower id plays; reset the SFX page and start the\n'
               'stream from SfxTable. The first tick happens in the next SndUpdate.',
    'SongFadeOut': 'Fade the music out / in (A = speed).',
    'Cmd_Drums': 'DRUMS t, pattern: one drum step every t ticks.',
    'DrumStep': 'DrumStep: read pattern bytes until a 0 or a drum sound: $FF restart; $32/$33/$34\n'
                'noise pan C/R/L; $35 n noise auto-pan; $36 repeat end; $37-$46 noise level;\n'
                '$47-$5A noise speed; then a repeat-start range and a tempo range (see the doc);\n'
                '$01-$31 = drum sound n (skipped while wDrumHold runs).',
    'DrumTable_m2': 'Drum sound table (indexed from 2 bytes before; drum 1 is the first entry).',
    'DrumTick': 'DrumTick: wDrumHold counts down; drum timer; then one noise-sequence step every\n'
                'speed + 1 ticks: NR43 = seq43[i]; with an NR42 table NR42 = seq42[i] - level\n'
                '(not while held; $FF = no write) and NR44 = $80; $FF in the NR43 table ends.\n'
                'Auto-pan of the noise from the step count.',
}

COMMENT_OVERRIDES = {
    'obelixgb': {
        'PlaySfx': 'PlaySfx (A = id): ignored while SFX 29 plays (no other priority); reset the SFX\n'
                   'page and start the stream. The API\'s last entry (PlaySfxNow) skips the test.',
        'Cmd_SlideUp': COMMENTS['Cmd_SlideUp'],
    },
    'obelixgbc': {
        'PlaySfxEntry': 'API entry for PlaySfx: jumps to the last slot of the API table (PlaySfxEntry2),\n'
                        'which jumps to PlaySfx.',
        'SndResume': 'SndResume / SndPause: wPaused = 0 / 1; both silence CH1-CH4 and reset the SFX\n'
                     'page (which reloads the music wave). StopAll and SongFadeIn call SndResume.',
        'SndPause': None,
        'PlaySfx': 'PlaySfx (A = id): no priority test; reset the SFX page and start the stream.',
        'OutputCh1': 'Output, pulse pages: NR11/NR21 = duty shadows every tick; NRx3 = period low +\n'
                     'pitch offset; when the high byte changed or the envelope flag ($33) is set:\n'
                     'with the flag NRx2 = field $32 and NRx4 = high | $80, else NRx4 = high.',
        'Cmd_NoteHook': 'NOTE_HOOK on_note, on_wait / NOTE_HOOK 0 (new in this version, unused by the\n'
                        'data): at each note, field $3C = previous note, $3D = this note, then call\n'
                        'on_note; at each WAIT/WAIT2, call on_wait and play the note in $3C.',
        'Cmd_SlideUp': 'SLIDE_UP n / SLIDE_DOWN n: as in The Smurfs, but a note on always resets the\n'
                       'direction to down, so after the first note both slide down.',
        'DoFade': 'DoFade: a $80 byte in the table pauses the driver (SndPause) and ends the fade.\n'
                  'No NR50 = $77 forcing in this version.',
        'Unused_SetVolEnvBC': 'Not reached here: SetVolEnvBC, VOLENV from the four bytes at BC (start volume,\n'
                              'attack, decay, rates), then ret. A helper for NOTE_HOOK routines (Spirou\'s\n'
                              'song 3 uses it); nothing in this build calls it.',
        'Cmd_Instrument': 'INSTR n: clear arpeggio, glide and arpeggio offset (auto-duty keeps running);\n'
                          'pulse pages: duty shadow = 50 %; then run macro n (entry n + 1 of wInstrTable)\n'
                          'up to END with wInInstr = $C9.',
        'StartFade': 'StartFade (A = speed, HL = table) / FADE speed, table: one byte into NR50 every\n'
                     'speed + 1 ticks; $6A loops, $FF ends, $80 pauses (DoFade). StartFade also\n'
                     'reloads the music wave.',
        'HwEnvAtten': 'HwEnvAtten: a = a - 0 (stub; a place for an envelope attenuation).',
    },
    'tibet': {
        'PlaySfxEntry': 'API entry for PlaySfx: jumps to the last slot of the API table (PlaySfxEntry2),\n'
                        'which jumps to PlaySfx.',
        'PlaySfx': 'PlaySfx (A = id): no priority test (the SFX-29 test of Obelix GB is gone); reset\n'
                   'the SFX page and start the stream. Both API SFX entries lead here, through the\n'
                   'jp at the end of the API table (PlaySfxEntry2).',
    },
    'sun': {
        'OutputCh1': 'Output, pulse pages: NRx3 = period low + pitch offset; when the high byte changed\n'
                     'or the envelope flag ($33) is set: with the flag NRx2 = field $32 and NRx4 =\n'
                     'high | $80, else NRx4 = high. (Obelix GBC\'s duty shadows are gone: duty goes\n'
                     'straight to NR11/NR21.)',
        'Cmd_Instrument': 'INSTR n: clear arpeggio, glide and arpeggio offset (auto-duty keeps running);\n'
                          'pulse pages: NR11/NR21 = 50 % duty; then run macro n (entry n + 1 of\n'
                          'wInstrTable) up to END with wInInstr = $C9.',
        'PlayCh1Tone': 'PlayCh1Tone (BC = period; API entry 9, new in this build): Ch1 page period = BC,\n'
                       'NRx2 value $F0 with the write flag set, NR11 = $C0 (75 % duty). The next output\n'
                       'retriggers CH1 at volume 15 with no envelope; a playing Ch1 track overwrites it.\n'
                       'The game\'s VBlank glue calls it every frame while one game mode runs (period =\n'
                       'a game variable x 8). Song 10 starts no Ch1 track.',
        'Unused_SetVolEnvBC': 'Not reached: SetVolEnvBC, VOLENV from the four bytes at BC (start volume,\n'
                              'attack, decay, rates), then ret. A helper for NOTE_HOOK routines; nothing in\n'
                              'this game uses it.',
    },
    'spirou': {
        'PlaySfxEntry': 'API entry for PlaySfx: jumps to the last slot of the API table (PlaySfxEntry2),\n'
                        'which jumps to PlaySfx.',
        'SndResume': 'SMURFS', 'SndPause': 'SMURFS', 'OutputCh1': 'SMURFS', 'DoFade': 'SMURFS',
        'PlaySfx': 'PlaySfx (A = id): no priority test; reset the SFX page and start the stream. Both\n'
                   'API SFX entries lead here, through the jp at the end of the API table.',
        'Cmd_Instrument': 'INSTR n: clear arpeggio, glide and arpeggio offset (auto-duty keeps running);\n'
                          'pulse pages: NR11/NR21 = 50 % duty; then run macro n (entry n + 1 of\n'
                          'wInstrTable) up to END with wInInstr = $C9.',
        'NoteOn': 'Note on. The direction bit (b4, vibrato/slides) is cleared unless bit 4 of the\n'
                  'vibrato delay (field $20, in A here) is set: The Smurfs tests the slide bit\n'
                  '(bit 5, [hl]) at this point. Slides have delay 0, so they always restart\n'
                  'downwards; a vibrato with a delay of 16-31, 48-63 ... keeps its direction.',
        'Cmd_SlideUp': 'SLIDE_UP n / SLIDE_DOWN n: set b3 + b4 (up) / b3 (down), delay 0, speed 1. A note\n'
                       'on clears b4 (see NoteOn), so after the next note both slide down, n per tick\n'
                       'for 255 ticks.',
        'SetVolEnvBC': 'SetVolEnvBC: VOLENV from the four bytes at BC (start volume, attack, decay,\n'
                       'rates), then ret. Called by song 3\'s NOTE_HOOK routines.',
        'StartFade': 'StartFade (A = speed, HL = table) / FADE speed, table: one byte into NR50 every\n'
                     'speed + 1 ticks; $6A loops, $FF ends. (No music-wave reload, no $80 byte.)',
        'Song3HookNote': 'Song 3 NOTE_HOOK, at each Ch3 note: VOLENV 15, $11, $1F, $11 (Song3EnvNote).',
        'Song3HookWait': 'Song 3 NOTE_HOOK, at each Ch3 WAIT: VOLENV 10, $10, $1F, $11 (Song3EnvWait); the\n'
                         'driver then replays the previous note (field $3C): a quieter echo.',
    },
}

# ---- Lucky Luke family (chain: Obelix GBC -> Spirou -> Lucky Luke -> Smurfs' Nightmare / Die Maus)
COMMENT_OVERRIDES['luckyluke'] = {
    'OutputCh1': COMMENT_OVERRIDES['sun']['OutputCh1'],
    'NoteOn': 'Note on. The direction bit (b4, vibrato/slides) is always cleared, as in Prisoners\n'
              'of the Sun (Spirou tests bit 4 of the vibrato delay here).',
    'Cmd_SlideUp': COMMENT_OVERRIDES['obelixgbc']['Cmd_SlideUp'],
    'Unused_SetVolEnvBC': COMMENT_OVERRIDES['sun']['Unused_SetVolEnvBC'],
}
COMMENT_OVERRIDES['smurfs3'] = {
    'Cmd_Instrument': 'INSTR n: clear arpeggio, glide, arpeggio offset and auto-duty (field $2F; Lucky\n'
                      'Luke leaves auto-duty running); pulse pages: NR11/NR21 = 50 % duty; then run\n'
                      'macro n (entry n + 1 of wInstrTable) up to END with wInInstr = $C9.',
    'DriverVersionText': 'Not reached: the driver\'s version text (after the driver code, before the first song).',
}
COMMENT_OVERRIDES['maus'] = {
    'SndResume': 'SndResume / SndPause: wPaused = 0 / 1; both silence CH1-CH4 and reset the SFX\n'
                 'page (which reloads the music wave), as in Prisoners of the Sun. Nothing in the\n'
                 'driver calls them (StopAll, STOP_ALL and SongFadeIn do not).',
    'SndPause': None,
    'OutputCh1': 'Output, pulse pages: AddPortaOffset first moves the period fields ($05/$06) by the\n'
                 'porta offset; NRx3 = period low + pitch offset; when the high byte changed or the\n'
                 'envelope flag ($33) is set: with the flag NRx2 = field $32 and NRx4 = high | $80,\n'
                 'else NRx4 = high.',
    'NoteOn': 'Note on: clear the porta state (fields $48-$4A), ticks left = length, then\n'
              'PortaStart (look ahead for the next note). The direction bit (b4) is always cleared.',
    'Cmd_Instrument': 'INSTR n: clear arpeggio, vibrato (b3), glide, arpeggio offset and auto-duty\n'
                      '(field $2F); pulse pages: NR11/NR21 = 50 % duty; then run macro n (entry n + 1\n'
                      'of wInstrTable) up to END with wInInstr = $C9.',
    'Cmd_Vibrato': 'VIBRATO delay, depth, speed: fields $20-$24, set b3 (vibrato) and b4 (direction).',
    'Cmd_VibOff': 'VIB_OFF: clear b3 only (earlier builds clear b3 and b4).',
    'Cmd_Release': 'RELEASE minlen << 4 | ticks, env / RELEASE 0: an env byte of 0 is replaced by $11.',
    'Cmd_NoteHook': 'NOTE_HOOK on_note, on_wait / NOTE_HOOK 0 (moved to $82; unused by the data): at\n'
                    'each note, field $3C = previous note, $3D = this note, then call on_note; at each\n'
                    'WAIT/WAIT2, call on_wait and play the note in $3C.',
    'Cmd_Porta': 'PORTA step, lead (new, $83): field $42 = step, $43 = lead, set b6. From the next\n'
                 'note on, each note slides to the following note during the last `lead` ticks\n'
                 'before it, `step` period units per tick (PortaStart, PortaTick, AddPortaOffset).',
    'Cmd_PortaOff': 'PORTA_OFF (new, $84): clear b6.',
    'AddPortaOffset': 'AddPortaOffset (h = page): period fields $05/$06 += offset $48/$49, or -= when\n'
                      'field $4A is 1 (slide down).',
    'PortaTick': 'PortaTick (each tick while b6 is set): the delay $44 counts down first; then, while\n'
                 'a slide is pending ($45 = 1 down / 2 up), offset $48/$49 += step ($42) and\n'
                 '$4A = 1 for down; once the offset reaches the period distance $46/$47 it is\n'
                 'clamped there and $45 = 0.',
    'PortaStart': 'PortaStart (note on, while b6 is set): scan the stream after this note. Delay $44\n'
                  '= this note\'s length, + one length per WAIT/REST; VOLENV (4 bytes) and PORTA\n'
                  '(3 bytes) are skipped, every other byte counts as 1 (LEN and command arguments\n'
                  'are not followed); END or NEXT: no slide. At the next note: delay -= lead\n'
                  '(not below 0), direction from the two notes, distance = difference of their\n'
                  'periods (note + channel and global transpose; no arpeggio).',
    'Unused_SetVolEnvBC': COMMENT_OVERRIDES['sun']['Unused_SetVolEnvBC'],
}

# ---- Prisoners of the Sun group: Hugo 2, Turok, Turok 2
COMMENT_OVERRIDES['hugo2'] = {
    'StopAll': 'StopAll: as Prisoners of the Sun (calls SndResume), then sets the default\n'
               'instrument table ($6227, instrument table 2; songs 2-4 keep it, the others set\n'
               'their own), then silences CH1-CH4 and resets the pages.',
    'PlaySfxEntry': "API entry for PlaySfx: goes through the game's glue (GamePlaySfxGlue) first.",
}
COMMENT_OVERRIDES['turok'] = {
    'StartMusicCh1': 'StartMusicChN (de = order list): set wInstrTable to the one instrument table (in\n'
                     'all three entries, so every song plays with it; 14 bytes apart, not 4), reset\n'
                     'the page, mark it active, start its first pattern. StartMusicCh3 also stops the\n'
                     'fade and the drums.',
    'CheckRelease': 'CheckRelease (RELEASE t, env; t = min length (hi) / ticks left (lo)): new early\n'
                    'exit when RELEASE is off (bit 1 of $04; CheckRelease2 tests it again). Then as\n'
                    'before: skipped for notes shorter than the minimum; on the tick where ticks\n'
                    'left = lo nibble, unless the next byte is WAIT: pulse NRx2 = env; CH3/SFX page:\n'
                    'decay rate = env & $0F and, if env >> 4 is not 0, volume = env >> 4.',
    'PlayCh1Tone': 'PlayCh1Tone (BC = period; API entry 9, as Prisoners of the Sun): Ch1 page period =\n'
                   'BC, NRx2 value $F0 with the write flag set, NR11 = $C0 (75 % duty). Nothing in\n'
                   'the game calls it.',
}
COMMENT_OVERRIDES['turok2'] = {
    'SndInit': 'SndInit: NR52 = $FF, the instrument table (as StartMusicChN also sets it) and the\n'
               'default arpeggio table, clear flags; falls into StopAll.',
}
