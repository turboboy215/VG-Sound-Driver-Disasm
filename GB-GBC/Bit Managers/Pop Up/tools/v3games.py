"""Per-game generator info (entries, songs, sections, header) for gen_v3.py."""

HDR = r'''; =====================================================================
; {title} - Game Boy
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 3{variant}
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o {short}.o {asm}
;   rgblink -o {short}.gb {short}.o
;   python tools/cmp_banked.py {short}.gb "{rom}" <ranges listed in the doc>
; (the driver lives in ROM bank {bank}; the linked file only matches in the listed ranges)
;
; Documentation: {doc} / AJG_SoundEngine_Family.md
; =====================================================================
'''

INFO = {
    'asterix': dict(
        entries=[0x4A8C, 0x4A91, 0x4AAC, 0x4E6F, 0x52E3, 0x54AF, 0x54B3, 0x54B7, 0x56A6,
                 0x56D6, 0x56DA, 0x56DE, 0x5709, 0x5181],
        songs=[0x5712, 0x585F, 0x5D42, 0x5E3C, 0x60B8, 0x61FC, 0x654B, 0x66AF, 0x676B, 0x6A95,
               0x6E62, 0x76CB, 0x7C65, 0x5709],
        code_start=0x4A8C, code_end=0x5711,
        sections=[
            ('RST00', 0x0000, 0x0003, 'rst $00: jp MemCopy (game code; copy bc bytes hl -> de)'),
            ('RST08', 0x0008, 0x000C, 'rst $08: hl = [hl] (read a word)'),
            ('RST18', 0x0018, 0x001E, 'rst $18: hl += a'),
            ('MemCopy', 0x1A90, 0x1A99, 'Game MemCopy: copy bc bytes hl -> de'),
            ('SoundDriver', 0x4A8C, 0x7F1B, ''),
        ],
        rom0_entries=[0x0000, 0x0008, 0x0018, 0x1A90],
        period_table=0x5350,
        raw_items=[(0x532C, 12), (0x5338, 12), (0x5344, 12), (0x5578, 16), (0x51F3, 13), (0x5200, 17),
                   (0x5211, 27)],
        labels={0x1A90: 'MemCopy', 0x5709: 'SongFadeOut', 0x51F3: 'Unused_FadeTables', 0x522C: 'FadeOutTable'},
        game_ram={},
    ),
    'pinocchio': dict(
        entries=[0x4000, 0x4004, 0x401E, 0x4391, 0x476D, 0x4937, 0x493B, 0x493F, 0x4B27,
                 0x4B57, 0x4B5B, 0x4B5F, 0x4B8A, 0x4626],
        songs=[0x4C77, 0x552B, 0x5859, 0x5BF4, 0x6117, 0x4B8A],
        code_start=0x4000, code_end=0x4B92,
        sections=[
            ('RST00', 0x0000, 0x0003, 'rst $00: jp MemCopy (game code; copy bc bytes hl -> de)'),
            ('RST08', 0x0008, 0x000C, 'rst $08: hl = [hl] (read a word)'),
            ('RST18', 0x0018, 0x001E, 'rst $18: hl += a'),
            ('MemCopy', 0x0BA4, 0x0BAD, 'Game MemCopy: copy bc bytes hl -> de'),
            ('CallBC', 0x0BE7, 0x0BE9, 'Game helper: push bc / ret (jump to bc); the driver calls it to run a command handler'),
            ('SoundDriver', 0x4000, 0x66FD, ''),
        ],
        rom0_entries=[0x0000, 0x0008, 0x0018, 0x0BA4, 0x0BE7],
        period_table=0x47D9,
        raw_items=[(0x47B5, 12), (0x47C1, 12), (0x47CD, 12), (0x49FA, 16), (0x4683, 13), (0x4690, 17),
                   (0x46A1, 27)],
        labels={0x0BA4: 'MemCopy', 0x0BE7: 'CallBC_Bank0', 0x4B8A: 'SongFadeOut', 0x40C8: 'ReadStream', 0x44FE: 'NoiseSeqTick', 0x47B5: 'ChInit1', 0x47C1: 'ChInit2', 0x47CD: 'ChInit3',
                0x47D9: 'PeriodTable', 0x49FA: 'Ch3VolTable', 0x4683: 'Unused_FadeTables', 0x46BC: 'FadeOutTable'},
        game_ram={},
    ),
    'metalmasters': dict(
        entries=[0x5A1C, 0x5A21, 0x5A3C, 0x5E54, 0x6295, 0x6463, 0x6467, 0x646B, 0x6659,
                 0x6689, 0x668D, 0x6691, 0x66BC, 0x616C],
        songs=[0x66C5, 0x66F4, 0x6738, 0x66BC],
        code_start=0x5A1C, code_end=0x66C4,
        sections=[
            ('RST00', 0x0000, 0x0003, 'rst $00: jp MemCopy (game code; copy bc bytes hl -> de)'),
            ('RST08', 0x0008, 0x000C, 'rst $08: hl = [hl] (read a word)'),
            ('RST18', 0x0018, 0x001E, 'rst $18: hl += a'),
            ('MemCopy', 0x1719, 0x1722, 'Game MemCopy: copy bc bytes hl -> de'),
            ('SoundDriver', 0x5A1C, 0x7545, ''),
        ],
        rom0_entries=[0x0000, 0x0008, 0x0018, 0x1719],
        period_table=0x6302,
        raw_items=[(0x62DE, 12), (0x62EA, 12), (0x62F6, 12), (0x652B, 16)],
        labels={0x1719: 'MemCopy', 0x66BC: 'SongFadeOut', 0x5E2E: 'Cmd_Wait', 0x5E31: 'WaitReload', 0x5CE3: 'EchoStore',
                0x5CEC: 'EchoPut', 0x5CF7: 'EchoAdvance', 0x5CFE: 'EchoTick', 0x6143: 'AutoDutyStep2',
                0x64E6: 'OutputDone', 0x62DE: 'ChInit1', 0x62EA: 'ChInit2', 0x62F6: 'ChInit3',
                0x6302: 'PeriodTable', 0x652B: 'Ch3VolTable', 0x61DE: 'FadeOutTable'},
        game_ram={},
    ),
}

META = {
    'asterix': dict(title='Asterix (UE) (M5)', variant='', short='asterix', asm='Asterix_SoundDriver.asm',
                    doc='Asterix_SoundDriver.md'),
    'pinocchio': dict(title='The Adventures of Pinocchio (J) - 1993 prototype, internal title "INFREY QUEST"',
                      variant=' (early variant)', short='pinocchio', asm='Pinocchio_SoundDriver.asm',
                      doc='Pinocchio_SoundDriver.md'),
    'metalmasters': dict(title='Metal Masters (U)', variant=' (late variant)', short='metalmasters',
                         asm='MetalMasters_SoundDriver.asm', doc='MetalMasters_SoundDriver.md'),
}

COMMENT_OVERRIDES = {
    'pinocchio': {
        'ChannelTick': 'ChannelTick (h = page, skipped while field $10 = 0): auto-duty, auto-pan, glide,\n'
                       'envelope, arpeggio, vibrato, portamento, release check; then len - 1 and the\n'
                       'stream when it reaches 0. (No note-pan in this version.)',
        'ReadStream': 'ReadStream (de = stream). Notes store the note and pointer, set the period,\n'
                      'restart the arpeggio, the hardware envelope and the portamento, reload the length,\n'
                      'reload vibrato, clear the released flag, volume = start volume, split the\n'
                      'attack/decay bytes. Commands go through StreamCommand and loop.',
        'Cmd_Instrument': 'Cmd_Instrument: clears vibrato, arpeggio, glide, auto-pan, auto-duty and the\n'
                          'hardware envelope, centre pan, 50 % duty; then runs instrument macro n (entry\n'
                          'n + 1 of the song\'s table) until END or NEXT with wInInstr = $C9.',
        'DrumStep': 'DrumStep: read pattern bytes. $FF loops, 0 = nothing; $32/$33/$34 noise pan\n'
                    'centre/right/left, $64-$73 noise attenuation, $74+ noise sequence speed (these\n'
                    'modify and read on); others = drum sound n from DrumTable (skipped while\n'
                    'wDrumHold is running). No $35 auto-pan in this version.',
        'SndUpdate': 'SndUpdate (timer interrupt, 53.89 Hz): NR50 fade, then tick the four pages (or only\n'
                     'the SFX page while paused), drums + noise sequence, output; finally NR51 from the\n'
                     'pages\' pan bytes and wNoisePan - or $FF while wStereo = 0 (always, in this game).',
    },
    'metalmasters': {
        'ReadStream': 'ReadStream (de = stream). Notes are first stored in the echo buffer (EchoStore),\n'
                      'then as in Asterix: note and pointer, period, arpeggio, hardware envelope,\n'
                      'portamento, length, note-pan, vibrato, released flag, start volume, envelope.',
    },
}
