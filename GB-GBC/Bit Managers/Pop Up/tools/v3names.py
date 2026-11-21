"""Astérix (reference for version 3) routine names, RAM names and comments.
Names are carried over to Pinocchio and Metal Masters by aligning the code (gen_v3.transfer)."""

AST_LABELS = {
    0x4A8C: 'SndResume', 0x4A91: 'SndPause', 0x4AAC: 'SndUpdate', 0x4AC1: 'TickMusic',
    0x4AD9: 'SetNR51', 0x4AED: 'SetNR51_Ch3', 0x4B2B: 'DrumTimerTick',
    0x4B78: 'NotePanLeft', 0x4B7E: 'NotePanRight', 0x4B84: 'NotePanEnd', 0x4B04: 'WriteNR51', 0x4B07: 'EnvDivider', 0x4B18: 'EnvDividerReload',
    0x4B21: 'DrumTick', 0x4B35: 'ChannelTick', 0x4B60: 'DoNotePan', 0x4B8D: 'ReadStream',
    0x4BD9: 'SplitNibbles', 0x4BE5: 'StreamCommand', 0x4C10: 'CallBC', 0x4C12: 'Cmd_Len',
    0x4C1A: 'Cmd_VolEnv', 0x4C45: 'Cmd_Vol', 0x4C4D: 'Cmd_Arp', 0x4C6F: 'Cmd_Instrument',
    0x4CAA: 'InstrLoop', 0x4CB9: 'InstrCommand', 0x4CE0: 'InstrDone', 0x4CE8: 'CmdTable',
    0x4D32: 'Cmd_NotePan', 0x4D38: 'Cmd_EnvDiv', 0x4D3E: 'Cmd_CallCode', 0x4D46: 'Unused_Ret',
    0x4D47: 'PatReturn', 0x4D54: 'Cmd_PatCall', 0x4D5D: 'Cmd_PatGoto', 0x4D68: 'Cmd_ArpOff',
    0x4D6D: 'CheckRelease', 0x4D7C: 'CheckRelease2', 0x4DA3: 'SetReleased', 0x4DA8: 'ReleaseCh3',
    0x4DB2: 'Cmd_Release', 0x4DC2: 'ReleaseOff', 0x4DC7: 'Cmd_ChTranspose', 0x4DCD: 'Cmd_Glide',
    0x4DD3: 'Cmd_GlideOff', 0x4DD8: 'DoGlide', 0x4DE4: 'Cmd_Wait2', 0x4DE6: 'Cmd_Vibrato',
    0x4DFF: 'Cmd_VibOff', 0x4E04: 'DoVibrato', 0x4E12: 'VibStep', 0x4E25: 'VibUp', 0x4E31: 'VibDownPhase',
    0x4E3E: 'VibDown', 0x4E4C: 'Cmd_Wait', 0x4E59: 'Cmd_Rest', 0x4E6F: 'StopAll', 0x4E9C: 'Cmd_End',
    0x4EA8: 'ResetChannel', 0x4EDD: 'ResetSilence0', 0x4EDE: 'ResetSilence', 0x4EE8: 'ResetBumpNR32',
    0x4EF1: 'BumpNR32Shadow',
    0x4EF9: 'Cmd_Transpose', 0x4EFF: 'Cmd_OrderJump', 0x4F07: 'Cmd_Next', 0x4F25: 'Next_OrderEnd',
    0x4F2D: 'Cmd_Length', 0x4F33: 'Cmd_DrumsOff', 0x4F38: 'Cmd_Drums', 0x4F5F: 'NoisePanCentre',
    0x4F65: 'DrumStep', 0x4F70: 'DrumRead', 0x4F84: 'DrumByte', 0x4FAB: 'DrumSound',
    0x4FB1: 'DrumTable_m2', 0x4FB3: 'DrumTable', 0x4FC7: 'DrumLoop', 0x4FCD: 'DrumAtten',
    0x4FD6: 'DrumNextByte', 0x4FD9: 'DrumNextByte2', 0x4FE1: 'DrumPanC', 0x4FE8: 'DrumPanR',
    0x4FF5: 'DrumPanL', 0x5002: 'DrumNoiseSpeed', 0x500D: 'DrumAutoPan', 0x5018: 'NoiseSeqTick',
    0x5028: 'NoiseSeqStep', 0x505E: 'NoiseWriteNR42', 0x5064: 'NoiseSeqNext', 0x5084: 'NoiseAutoPan2',
    0x508D: 'NoiseAutoPan3', 0x5096: 'NoiseAutoPan4', 0x509E: 'NoiseSeqEnd',
    0x50A8: 'Cmd_PanC', 0x50AD: 'Cmd_PanR', 0x50B2: 'Cmd_PanL', 0x50B7: 'Unused_50B7',
    0x50D6: 'Cmd_HwEnv', 0x50ED: 'HwEnvNoEnv2', 0x50F3: 'HwEnvNoteOn', 0x5105: 'Cmd_AutoPan',
    0x510F: 'Unused_510F', 0x5110: 'DoAutoPan', 0x511D: 'AutoPanStep', 0x5139: 'Cmd_AutoDuty',
    0x5143: 'DoAutoDuty', 0x5150: 'AutoDutyStep', 0x5165: 'Cmd_Duty50', 0x5169: 'Cmd_Duty75',
    0x516D: 'Cmd_Duty12', 0x516F: 'SetDuty', 0x5179: 'SetDutyCh1', 0x517D: 'SetDutyCh2',
    0x5181: 'StartFade', 0x518E: 'Cmd_Fade', 0x519D: 'FadeInit', 0x51A9: 'Cmd_FadeOff',
    0x51AE: 'DoFade', 0x51BD: 'FadeRun', 0x51C8: 'FadeStep', 0x51ED: 'FadeLoop',
    0x51F3: 'Unused_FadeTables', 0x522C: 'FadeOutTable', 0x5235: 'Cmd_Wave', 0x524D: 'WaveNow',
    0x524E: 'LoadWave', 0x5294: 'RestoreMusicWave', 0x52E3: 'SndInit', 0x5324: 'ClearChannelRest',
    0x532C: 'ChInit1', 0x5338: 'ChInit2', 0x5344: 'ChInit3', 0x5350: 'PeriodTable',
    0x53F2: 'DoArp', 0x53F7: 'ArpRead', 0x5401: 'ArpByte', 0x540A: 'ArpNotLoop', 0x5411: 'ArpApply',
    0x5415: 'SetNoteFreq', 0x5421: 'AddTranspose', 0x5426: 'SetFreqIndex',
    0x5440: 'DoEnvelope', 0x5457: 'SoftEnvelope', 0x5473: 'StoreVol', 0x5475: 'ClampVol',
    0x5479: 'EnvDecay', 0x5492: 'StoreVol2', 0x5496: 'EnvReleasePhase', 0x54AB: 'StoreVol3',
    0x54AF: 'StartMusicCh1', 0x54B3: 'StartMusicCh2', 0x54B7: 'StartMusicCh3', 0x54B9: 'StartMusicCh',
    0x54CE: 'OutputAll', 0x54DF: 'OutputChannel', 0x5502: 'OutputVolume', 0x5511: 'OutputHwEnv',
    0x552B: 'RetrigCh2', 0x5533: 'OutputDone', 0x5534: 'WriteVolume', 0x5554: 'WriteVolumeCh2',
    0x555C: 'WriteVolumeSame', 0x555E: 'WriteCh3Vol', 0x5576: 'WriteCh3VolDone', 0x5578: 'Ch3VolTable',
    0x5588: 'DoPorta', 0x5596: 'PortaRun', 0x55AC: 'PortaUpCheck', 0x55BB: 'PortaUpLo',
    0x55BF: 'PortaArrive', 0x55CF: 'PortaDown', 0x55D9: 'PortaDownCheck', 0x55E8: 'PortaDownLo',
    0x55F0: 'Unused_55F0', 0x55F4: 'Cmd_Porta', 0x5601: 'Cmd_PortaOff', 0x5606: 'PortaNoteOn',
    0x5612: 'PortaScan', 0x5625: 'PortaNoDelay', 0x5629: 'PortaScanCmd', 0x563F: 'PortaScanEnd',
    0x5649: 'PortaSkip2', 0x564D: 'PortaSkip3', 0x5652: 'PortaAddLength', 0x565C: 'PortaTarget',
    0x566B: 'PortaSetDown', 0x566D: 'PortaSetTarget', 0x5673: 'PortaNone', 0x5678: 'PortaNoneDir',
    0x567A: 'PortaScanDone', 0x567C: 'SetPortaTarget', 0x5688: 'PortaAddTranspose',
    0x568D: 'PortaFreqIndex',
    0x56A6: 'PlaySfx', 0x56D6: 'PlayOnCh1', 0x56DA: 'PlayOnCh2', 0x56DE: 'PlayOnCh3',
    0x56E0: 'PlayOnCh', 0x5709: 'SongFadeOut',
    # game (bank 0)
    0x0000: 'Rst00_MemCopy', 0x0008: 'Rst08_ReadWord', 0x0018: 'Rst18_AddHLA',
}

AST_RAM = {
    0xDB46: 'wShFreqHi1', 0xDB47: 'wShFreqHi2', 0xDB48: 'wShFreqHi3', 0xDB49: 'wShNR32',
    0xDB4A: 'wInInstr', 0xDB4B: 'wTranspose', 0xDB4C: 'wNoisePan', 0xDB4D: 'wDrumHold',
    0xDB4E: 'wInstrTable', 0xDB4F: 'wInstrTableHi', 0xDB50: 'wArpTable', 0xDB51: 'wArpTableHi',
    0xDB52: 'wMusicWave', 0xDB53: 'wMusicWaveHi', 0xDB54: 'wPaused', 0xDB55: 'wStereo',
    0xDB56: 'wNoiseAutoPan', 0xDB57: 'wDrumPatHi', 0xDB58: 'wDrumPatLo', 0xDB59: 'wDrumPos',
    0xDB5A: 'wDrumsOn', 0xDB5B: 'wDrumTempo', 0xDB5C: 'wDrumTimer', 0xDB5D: 'wNoiseNR43Hi',
    0xDB5E: 'wNoiseNR43Lo', 0xDB5F: 'wNoiseNR42Hi', 0xDB60: 'wNoiseNR42Lo', 0xDB61: 'wNoisePos',
    0xDB62: 'wNoiseOn', 0xDB63: 'wNoiseAtten', 0xDB64: 'wNoiseTimer', 0xDB65: 'wNoiseSpeed',
    0xDB66: 'wFadePtr', 0xDB67: 'wFadePtrHi', 0xDB68: 'wFadePos', 0xDB69: 'wFadeTimer',
    0xDB6A: 'wFadeSpeed', 0xDB6B: 'wFadeOn',
}

# block comments, keyed by label name (shared by all three games where the label exists)
COMMENTS = {
    'SndResume': 'SndResume / SndPause: wPaused = 0 / 1. Pausing silences CH1-CH4 (NRx2 = 0, trigger)\n'
                 'and jumps to RestoreMusicWave with whatever H the caller left (see the doc, quirks).\n'
                 'While paused only the SFX page is ticked and output.',
    'SndUpdate': 'SndUpdate (once per frame): NR50 fade, then tick the four pages (or only the SFX\n'
                 'page while paused), drums + noise sequence, output; finally NR51 from the pages\'\n'
                 'pan bytes (field $3D) and wNoisePan - or $FF while wStereo = 0.',
    'EnvDivider': 'EnvDivider (called from SoftEnvelope): field $3E = reload (hi) / counter (lo).\n'
                  'While the counter is non-zero it is decremented and the caller\'s caller resumes\n'
                  '(pop af): the software envelope then runs once every reload + 1 ticks.',
    'DrumTick': 'DrumTick: wDrumHold counts down; wDrumTimer - 1, at 0 one drum step; then the\n'
                'noise sequence.',
    'ChannelTick': 'ChannelTick (h = page, skipped while field $10 = 0): auto-duty, auto-pan, glide,\n'
                   'envelope, arpeggio, vibrato, portamento, release check, note-pan; then len - 1\n'
                   'and the stream when it reaches 0.',
    'DoNotePan': 'DoNotePan (NOTE_PAN n, field $3F = $80 + n while a note runs): elapsed = length - len;\n'
                 'elapsed 0 -> centre, n -> left, 2n -> right, 3n -> centre and stop.',
    'ReadStream': 'ReadStream (de = stream). Notes store the note and pointer, set the period,\n'
                  'restart the arpeggio, the hardware envelope and the portamento, reload the length,\n'
                  'arm the note-pan, reload vibrato, clear the released flag, volume = start volume,\n'
                  'split the attack/decay bytes. Commands go through StreamCommand and loop.',
    'StreamCommand': 'StreamCommand: LEN / VOLENV / VOL / ARP / INSTR ranges, else CmdTable.',
    'Cmd_Instrument': 'Cmd_Instrument: clears vibrato, arpeggio, glide, auto-pan, auto-duty, hardware\n'
                      'envelope (and the note-pan), centre pan, 50 % duty; then runs instrument macro n\n'
                      '(entry n + 1 of the song\'s table) until END or NEXT with wInInstr = $C9.',
    'CmdTable': 'Command jump table.',
    'Cmd_CallCode': 'CALL_CODE w: push w and return into it, i.e. call machine code at w (it returns\n'
                    'to StreamCommand\'s loop). The songs use it to start one-shot noise sounds.',
    'PatReturn': 'PatReturn (from Cmd_Next while field $3C is set): continue after the PAT_CALL.',
    'CheckRelease': 'CheckRelease (RELEASE t, env; t = min length (hi) / ticks left (lo)): skipped for\n'
                    'notes shorter than the minimum; on the tick where len = ticks left, unless the\n'
                    'next byte is WAIT: pulse NRx2 = env (via $31/$32); CH3/SFX: volume = env >> 4.',
    'DoVibrato': 'DoVibrato: after the delay, +/- depth on the period low byte every tick (with carry\n'
                 'into the high byte), switching direction every speed ticks.',
    'Cmd_Rest': 'REST: volume 0 (pulse pages also NRx2 = 0 through $31/$32), then wait one length.',
    'StopAll': 'StopAll: drums, noise sequence and fade off, reset all four pages, NR42 = 0,\n'
               'wTranspose = 0, noise pan centre.',
    'Cmd_End': 'END: centre pan; SFX page: reload the music wave; then reset the page.',
    'ResetChannel': 'ResetChannel: clear the fields, silence the channel (NRx2 = 0, NRx4 = $80).\n'
                    'On the SFX page the silence is meant to be skipped while Ch3 plays, but the test\n'
                    'reuses the Z flag of an earlier compare, so it is always done (as in Bomb Jack).',
    'Cmd_Next': 'NEXT: return from a PAT_CALL if one is pending, else the next order-list entry;\n'
                'a 0 entry is followed by the loop position (handled as ORDER_JUMP).',
    'Cmd_Drums': 'DRUMS t, pattern: one pattern byte every t ticks (DrumStep).',
    'DrumStep': 'DrumStep: read pattern bytes. $FF loops, 0 = nothing; $32/$33/$34 noise pan\n'
                'centre/right/left, $35 n noise auto-pan, $64-$73 noise attenuation, $74+ noise\n'
                'sequence speed (these modify and read on); others = drum sound n from DrumTable\n'
                '(skipped while wDrumHold is running).',
    'DrumTable_m2': 'Drum sound table (indexed from 2 bytes before; drum 1 is the first entry).',
    'NoiseSeqTick': 'NoiseSeqTick: every wNoiseSpeed + 1 ticks one step: NR43 = seq43[i]; if an NR42\n'
                    'table is set, NR42 = seq42[i] - attenuation << 4, NR44 = $80. $FF ends.',
    'SetDuty': 'SetDuty: CH1/CH2 only, written straight to NR11/NR21.',
    'StartFade': 'StartFade (A = speed, HL = table) / FADE speed, table: one byte into NR50 every\n'
                 'speed + 1 ticks; the NEXT byte loops, $FF ends.',
    'DoFade': 'DoFade: while no fade runs, NR50 is forced back to $77 every tick (unless it is 0).',
    'Unused_FadeTables': 'NR50 tables (only FadeOutTable is referenced).',
    'Cmd_Wave': 'WAVE w: Ch3 page: remember w and load it unless an SFX plays. SFX page: load w.',
    'LoadWave': 'LoadWave: NR30 = 0, copy 16 bytes, NR30 = NR34 = Ch3 period-hi shadow | $80.',
    'RestoreMusicWave': 'RestoreMusicWave: reload the music wave, NR32 = raw volume field of page h - 1.',
    'SndInit': 'SndInit: init blocks into each page (fields $00-$0B, NRx3/NRx4/NRx2 addresses),\n'
               'clear the rest, NR52 = $FF, noise pan centre, StopAll.',
    'PeriodTable': 'Period table: 81 entries from C2 (same values as versions 1 and 2).',
    'DoArp': 'DoArp: next arpeggio byte added to the note; NEXT byte = loop, $FF = hold.',
    'SetNoteFreq': 'SetNoteFreq: index = note - 12 + wTranspose (not on the SFX page) + field $0F.',
    'DoEnvelope': 'DoEnvelope: hardware mode: count down to the 2nd envelope value. Software mode\n'
                  '(through EnvDivider): attack, then decay; the release phase ($18/$19) is dead.',
    'StartMusicCh1': 'StartMusicChN (de = order list): reset the page, start its first pattern.',
    'OutputAll': 'OutputAll: Ch1, Ch2, then the SFX page if it plays, otherwise Ch3.',
    'OutputChannel': 'OutputChannel: NRx3 = period low; NRx4 = period high (no trigger) when it changed.\n'
                     'Software volume: pulse NRx2 = vol << 4 + retrigger only when the register value\n'
                     'differs; CH3 NR32 from Ch3VolTable when it changed. Hardware envelope: write\n'
                     'field $31 + retrigger when field $32 is set.',
    'Ch3VolTable': 'CH3 volume table (0-15 -> NR32).',
    'DoPorta': 'DoPorta (PORTA speed, delay): after the delay, slide the period by speed per tick\n'
               'towards the next note\'s period, then stay on it.',
    'PortaNoteOn': 'PortaNoteOn: look ahead in the stream for the next note: delay = this note\'s\n'
                   'length (+ one length per WAIT/REST) - the PORTA delay; direction and target from\n'
                   'the next note. NEXT/END stop the search (no slide). Only PORTA and VOLENV\n'
                   'arguments are skipped; other commands with arguments are misread.',
    'PlaySfx': 'PlaySfx (A = id): reset the SFX page if busy (no priority test: the game\'s mailbox\n'
               'does that), start the stream and run its first tick and output at once.',
    'EchoStore': 'Echo (ECHO_ON): notes go into an 8-entry ring buffer (fields $42-$49, write\n'
                 'index $41); on every WAIT/WAIT2 the note is stored again and the channel plays the\n'
                 'entry at read index $40 (4 ahead: the note stored three steps earlier).',
    'PlayOnCh1': 'PlayOnChN (A = id): the same, but the SFX stream replaces the music on page N.',
    'SongFadeOut': 'Fade the music out (speed 4, FadeOutTable).',
}
