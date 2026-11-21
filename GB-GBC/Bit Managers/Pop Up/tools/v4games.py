"""Per-game generator info for gen_v4.py (AJG driver version 4)."""

HDR = r'''; =====================================================================
; {title}
; Sound driver by Alberto Jose Gonzalez (Bit Managers): "AJG driver", version 4{variant}
;
; Rebuilds byte-exact with RGBDS 0.9.1:
;   rgbasm -Wall -o {short}.o {asm}
;   rgblink -o {short}.gb {short}.o
;   python tools/cmp_banked.py {short}.gb "{rom}" {bank}:4000-7FFF
; (driver and data fill ROM bank {bank}; the linked file only matches in that range)
;
; Documentation: {doc} / AJG_SoundEngine_Family.md
; =====================================================================
'''

INFO = {
    'smurfs': dict(
        jt=0x4000, code_end=0x4B2C,
        jingles=[0x7DF3, 0x7ECD],            # song routines outside the API table
        jingle_refs=[0x1A1E, 0x1DB1],        # bank-0 code that posts them into the song mailbox ($D95A)
        extra_code=[0x7910, 0x797A, 0x7A8B],  # noise SFX 30-32 (reached through the game's glue at $7F82)
        glue=0x7F82,
        drum_count=11,
        raw_items=[(0x4166, 16)],
        labels={0x7F82: 'GamePlaySfxGlue', 0x7F99: 'GlueForceSfx', 0x7F9D: 'Unused_Garbage3'},
        blocks={0x7F82: 'The game\'s PlaySfx glue (reached from PlaySfxEntry): ids $1E/$1F/$20 start noise\n'
                        'routines (SFX 30-32), id $1C skips the priority test, others go to PlaySfx.',
                0x7F9D: 'Not reached: assembler leftovers to the end of the bank.'},
    ),
    'obelixgb': dict(
        jt=0x4000, code_end=0x4B2A,
        jingles=[], extra_code=[], glue=None, drum_count=11,
        raw_items=[(0x414E, 16)],
        labels={},
        blocks={},
    ),
    'obelixgbc': dict(
        jt=0x404A, code_end=0x4B2B,
        jingles=[], extra_code=[], glue=None, drum_count=11,
        raw_items=[(0x41CA, 16)],
        labels={},
        blocks={},
    ),
    # ---- bank 15 games (names carried from the reference build given by 'ref')
    'tibet': dict(
        ref='obelixgb', jt=0x4048, code_end=0x4B22,
        jingles=[], extra_code=[], glue=None, drum_count=11,
        raw_items=[(0x4190, 16)],
        labels={0x408A: 'PlaySfxEntry2', 0x491A: 'PlaySfxEntry', 0x491D: 'PlaySfx'},
        jt_names={0x491D: 'PlaySfxNow (A = id; the same code as PlaySfx)'},
        blocks={},
    ),
    'sun': dict(
        ref='obelixgbc', jt=0x404A, code_end=0x4B23,
        jingles=[], extra_code=[], glue=None, drum_count=10,
        raw_items=[(0x41D8, 16)],
        labels={0x409B: 'PlayCh1Tone', 0x4AE5: 'NoiseNR42', 0x437C: 'Unused_SetVolEnvBC'},
        jt_names={0x409B: 'PlayCh1Tone (BC = period; new)', 0x4919: 'PlaySfxNow (A = id; the same code as PlaySfx)'},
        blocks={},
    ),
    'spirou': dict(
        ref='obelixgbc', jt=0x404A, code_end=0x4B22,
        jingles=[], extra_code=[], glue=None, drum_count=10,
        raw_items=[(0x41AD, 16), (0x554F, 4), (0x5553, 4)],
        labels={0x4093: 'SndPause', 0x451F: 'StopAll', 0x495D: 'SongFadeIn', 0x4357: 'SetVolEnvBC',
                0x4AE4: 'NoiseNR42', 0x5543: 'Song3HookNote', 0x5549: 'Song3HookWait',
                0x554F: 'Song3EnvNote', 0x5553: 'Song3EnvWait',
                0x7DF9: 'Drum2', 0x7E7C: 'Drum9'},   # shared drum routines: keep the published names
        drop_labels=['SilenceAll'],
        bc_data=[0x554F, 0x5553],
        jt_names={0x491D: 'PlaySfxNow (A = id; the same code as PlaySfx)'},
        blocks={},
    ),
    # ---- Lucky Luke family
    'luckyluke': dict(
        ref='spirou', jt=0x404A, code_end=0x4B22,
        jingles=[], extra_code=[], glue=None, drum_count=None,
        raw_items=[(0x41CB, 16)],
        labels={0x436F: 'Unused_SetVolEnvBC'},
        jt_names={0x491D: 'PlaySfxNow (A = id; the same code as PlaySfx)'},
        blocks={},
    ),
    'smurfs3': dict(
        ref='luckyluke', jt=0x404A, code_end=0x4B22,
        jingles=[], extra_code=[], glue=None, drum_count=None,
        raw_items=[(0x41CE, 16)],
        text_items=[(0x4B23, 65), (0x7D05, 28), (0x7D22, 28)],
        labels={0x4372: 'Unused_SetVolEnvBC', 0x4B23: 'DriverVersionText'},
        jt_names={0x491D: 'PlaySfxNow (A = id; the same code as PlaySfx)'},
        blocks={},
    ),
    'maus': dict(
        ref='luckyluke', jt=0x404A, code_end=0x4C73,
        jingles=[], extra_code=[], glue=None, drum_count=None,
        raw_items=[(0x41BA, 16)],
        labels={0x4B23: 'AddPortaOffset', 0x4B40: 'PortaTick', 0x4BAE: 'PortaStart', 0x436E: 'Unused_SetVolEnvBC',
                0x4090: 'SndPause', 0x4BBA: 'PortaScan', 0x4C04: 'PortaTarget', 0x4C66: 'PortaNone'},
        jt_names={0x491D: 'PlaySfxNow (A = id; the same code as PlaySfx)'},
        blocks={},
    ),
    # ---- Prisoners of the Sun group
    'hugo2': dict(
        ref='sun', jt=0x404A, code_end=0x4B23,
        jt_dead=(0x5F8E,),
        jt_dead_comment='unused song slot: jumps into pattern data (never called)',
        jingles=[], extra_code=[0x64F1, 0x6561], glue=0x408F, drum_count=11,
        noise_sfx={2: 0x64F1, 3: 0x6561},
        raw_items=[(0x41C4, 16)],
        labels={0x408F: 'GamePlaySfxGlue', 0x4368: 'Unused_SetVolEnvBC'},
        jt_names={},
        blocks={0x408F: "The game's PlaySfx glue (PlaySfxEntry jumps here): ids 2 and 3 start noise\n"
                        "routines (SFX 2-3, their table entries are placeholders), others go to PlaySfx."},
    ),
    'turok': dict(
        ref='sun', jt=0x404A, code_end=0x4B41,
        jingles=[], extra_code=[0x7832, 0x7A93], glue=None, drum_count=10,
        raw_items=[(0x41CC, 16)],
        text_items=[(0x7F98, 30)],
        labels={0x408F: 'PlayCh1Tone', 0x4370: 'Unused_SetVolEnvBC', 0x4442: 'CheckRelease', 0x7832: 'Unused_Noise_7832', 0x7A93: 'Unused_Noise_7A93',
                0x7F98: 'DriverEndText'},
        jt_names={0x408F: 'PlayCh1Tone (BC = period)', 0x4937: 'PlaySfxNow (A = id; the same code as PlaySfx)'},
        blocks={},
    ),
    'turok2': dict(
        ref='turok', jt=0x404A, code_end=0x4B41,
        jingles=[], extra_code=[0x7909, 0x793B, 0x7A59, 0x7B9C], glue=None, drum_count=10,
        raw_items=[(0x41CC, 16)],
        text_items=[(0x7FC0, 28)],
        labels={0x408F: 'PlayCh1Tone', 0x4370: 'Unused_SetVolEnvBC', 0x4442: 'CheckRelease',
                0x7909: 'Unused_NoiseSfx_7909', 0x793B: 'Unused_Noise_793B',
                0x7A59: 'Unused_Noise_7A59', 0x7B9C: 'Unused_Noise_7B9C', 0x7FC0: 'DriverEndText'},
        blocks={0x7909: 'Unreferenced noise-SFX starter: wNoiseOn = 1, noise pan $88, hold 19, then\n'
                        'NoisePanCentre, NR42 = $F1 and NR44 = $80 written directly (an immediate hit),\n'
                        'then an NR43 sequence with no NR42 sequence.'},
        jt_names={0x408F: 'PlayCh1Tone (BC = period)', 0x4937: 'PlaySfxNow (A = id; the same code as PlaySfx)'},
    ),
    # ---- 1998-99 builds
    'otto': dict(
        ref='maus', jt=0x404A, code_end=0x4C73,
        jt_dead=(0x6888,),
        jt_dead_comment='unused song slot: jumps into the instrument table (never called)',
        jingles=[], extra_code=[], glue=None, drum_count=None,
        raw_items=[(0x41BA, 16)],
        labels={0x6888: 'InstrTable1'},
        jt_names={0x491D: 'PlaySfxNow (A = id; the same code as PlaySfx)'},
        blocks={},
    ),
    'seabattle': dict(
        ref='smurfs3', jt=0x404A, code_end=0x4B22,
        jt_dead=(0x53A9,),
        jt_dead_comment='unused song slot: jumps into pattern data (never called)',
        jingles=[], extra_code=[], glue=None, drum_count=None,
        raw_items=[(0x41CE, 16)],
        text_items=[(0x4B23, 65), (0x60EC, 37)],
        labels={0x4B23: 'DriverVersionText', 0x453D: 'StopAll', 0x60EC: 'DriverEndText',
                0x48F0: 'StartMusicCh1', 0x48F4: 'StartMusicCh2', 0x48F8: 'StartMusicCh3'},
        jt_names={0x491D: 'PlaySfxNow (A = id; the same code as PlaySfx)'},
        blocks={},
    ),
    'vrally': dict(
        ref='turok', jt=0x404A, code_end=0x4B5F,
        jt_dead=(0x5BCD,),
        jt_dead_comment='unused song slot: jumps into the instrument table (never called)',
        jingles=[], extra_code=[], glue=None, drum_count=None,
        raw_items=[(19950, 6), (19956, 17), (19973, 4), (19977, 3), (19980, 8), (19988, 7), (19995, 62), (20057, 61), (20118, 38), (20156, 48), (20227, 5), (20232, 16), (20248, 16)] + [(0x41E5, 16)],
        text_items=[(0x48A2, 30), (0x4B60, 53)],
        labels={**{19510: 'EngineStart', 19679: 'EngineUpdate', 19696: 'EngineTick', 19349: 'EngineWaveA', 19369: 'EngineWaveB', 19389: 'EngineHit1', 19407: 'EngineHit2', 19425: 'EngineHit3', 19506: 'EngineCh1Off', 19443: 'EngineNoise1', 19464: 'EngineNoise2', 19485: 'EngineNoise3', 20204: 'EngineCh2Seq', 19565: 'EngineStop', 19594: 'EngineLoadWave', 19653: 'EngineRandCh3', 19666: 'EngineRandCh1', 19796: 'EngineCh2Step', 19890: 'EngineNoiseStep', 17750: 'StopAll', 19950: 'EngineCh2SeqTable', 19956: 'EngineCh2Seq0', 19973: 'EngineCh2Seq1', 19977: 'EngineCh2Seq2', 19980: 'EngineNoise3_NR43', 19988: 'EngineNoise3_NR42', 19995: 'EngineNoise2_NR43', 20057: 'EngineNoise2_NR42', 20118: 'EngineNoise1_NR43', 20156: 'EngineNoise1_NR42', 20227: 'Unused_EngineCh2Seq0', 20232: 'EngineWaveA_Data', 20248: 'EngineWaveB_Data'}, **{0x48A2: 'DriverDateText', 0x4B60: 'DriverCreditText', 0x490E: 'StartMusicCh1', 0x491C: 'StartMusicCh2', 0x492A: 'StartMusicCh3', 0x5BCD: 'InstrTable1'}},
        jt_names={**{19510: 'EngineStart (game: race-engine sound on)', 19679: 'EngineUpdate (rpm in $DC87)', 19696: 'EngineTick', 19349: 'EngineWaveA', 19369: 'EngineWaveB', 19389: 'EngineHit1 (CH1)', 19407: 'EngineHit2 (CH1)', 19425: 'EngineHit3 (CH1)', 19506: 'EngineCh1Off', 19443: 'EngineNoise1', 19464: 'EngineNoise2', 19485: 'EngineNoise3', 20204: 'EngineCh2Seq (A = id)', 19565: 'EngineStop'}, 0x4955: 'PlaySfxNow (A = id; the same code as PlaySfx)'},
        blocks={19510: 'Game code in the sound bank: the race-engine sound (API slot 9). Sets EngineOn ($DC91),\nwhich makes SndUpdate run EngineUpdate instead of the music; silences all four channels.', 19679: 'EngineUpdate (API slot 10, and SndUpdate while $DC91 is set): base CH3 period = rpm ($DC87) * 8,\nthen EngineTick.', 19696: 'EngineTick (API slot 11): CH3 drone at the base period + a pseudo-random 0-31 (EngineRandCh3),\nCH1 NR13 = $FA + random (EngineRandCh1), then one step of the CH2 sequence and of the noise sequence.', 19349: 'Load engine wave A (if the B wave is loaded), CH3 volume $20', 19369: 'Load engine wave B (if wave A is loaded)', 19389: 'CH1 hit: duty 75 %, NR12 $A0, trigger; random-pitch seed 7', 19407: 'CH1 hit: NR12 $70; seed 3', 19425: 'CH1 hit: NR12 $90; seed 10', 19506: 'CH1 volume off', 19443: 'Start a noise sequence (NR43 table, NR42 table; $FF ends / $FF in NR42 = no write)', 20204: "A = sequence id: start a CH2 tone sequence from EngineCh2SeqTable. The streams use the driver's\nnote bytes ($00-$5F, period table at $4800), lengths from $C4, WAIT $65, REST $66, END $68.", 19565: 'EngineStop (API slot 22, also called by StopAll): silence, clear $DC91/$DC93/$DC8C', 20227: 'Unreferenced: ld a, 0 / jp EngineCh2Seq', 20248: '16-byte wave. The 10 bytes after it are unreferenced leftover SM83 code: ld a, [$DC91] /\n'
                   'and a / jp z, $4062 / jp $4089 (an older form of the SndUpdate engine hook)'},
    ),
    'vrallygbc': dict(
        ref='vrally', jt=0x404A, code_end=0x4B62,
        jt_dead=(0x5C6E,),
        jt_dead_comment='unused song slot: jumps into the instrument table (never called)',
        jingles=[], extra_code=[], glue=None, drum_count=None,
        raw_items=[(19962, 6), (19968, 17), (19985, 4), (19989, 3), (19992, 8), (20000, 7), (20007, 62), (20069, 61), (20130, 38), (20168, 48), (20239, 5), (20244, 16), (20260, 16)] + [(0x41F2, 16)],
        text_items=[(0x48A2, 30), (0x4B63, 53)],
        labels={**{19513: 'EngineStart', 19690: 'EngineUpdate', 19707: 'EngineTick', 19352: 'EngineWaveA', 19372: 'EngineWaveB', 19392: 'EngineHit1', 19410: 'EngineHit2', 19428: 'EngineHit3', 19509: 'EngineCh1Off', 19446: 'EngineNoise1', 19467: 'EngineNoise2', 19488: 'EngineNoise3', 20216: 'EngineCh2Seq', 19570: 'EngineStop', 19599: 'EngineLoadWave', 19664: 'EngineRandCh3', 19677: 'EngineRandCh1', 19805: 'EngineCh2Step', 19899: 'EngineNoiseStep', 17765: 'StopAll', 19962: 'EngineCh2SeqTable', 19968: 'EngineCh2Seq0', 19985: 'EngineCh2Seq1', 19989: 'EngineCh2Seq2', 19992: 'EngineNoise3_NR43', 20000: 'EngineNoise3_NR42', 20007: 'EngineNoise2_NR43', 20069: 'EngineNoise2_NR42', 20130: 'EngineNoise1_NR43', 20168: 'EngineNoise1_NR42', 20239: 'Unused_EngineCh2Seq0', 20244: 'EngineWaveA_Data', 20260: 'EngineWaveB_Data'}, **{0x48A2: 'DriverDateText', 0x4B63: 'DriverCreditText', 0x490E: 'StartMusicCh1', 0x491C: 'StartMusicCh2', 0x492A: 'StartMusicCh3', 0x5C6E: 'InstrTable1'}},
        jt_names={**{19513: 'EngineStart (game: race-engine sound on)', 19690: 'EngineUpdate (rpm in $DC87)', 19707: 'EngineTick', 19352: 'EngineWaveA', 19372: 'EngineWaveB', 19392: 'EngineHit1 (CH1)', 19410: 'EngineHit2 (CH1)', 19428: 'EngineHit3 (CH1)', 19509: 'EngineCh1Off', 19446: 'EngineNoise1', 19467: 'EngineNoise2', 19488: 'EngineNoise3', 20216: 'EngineCh2Seq (A = id)', 19570: 'EngineStop'}, 0x4955: 'PlaySfxNow (A = id; the same code as PlaySfx)'},
        blocks={19513: 'Game code in the sound bank: the race-engine sound (API slot 9). Sets EngineOn ($DC91),\nwhich makes SndUpdate run EngineUpdate instead of the music; silences all four channels.', 19690: 'EngineUpdate (API slot 10, and SndUpdate while $DC91 is set): base CH3 period = rpm ($DC87) * 8,\nthen EngineTick.', 19707: 'EngineTick (API slot 11): CH3 drone at the base period + a pseudo-random 0-31 (EngineRandCh3),\nCH1 NR13 = $FA + random (EngineRandCh1), then one step of the CH2 sequence and of the noise sequence.', 19352: 'Load engine wave A (if the B wave is loaded), CH3 volume $20', 19372: 'Load engine wave B (if wave A is loaded)', 19392: 'CH1 hit: duty 75 %, NR12 $A0, trigger; random-pitch seed 7', 19410: 'CH1 hit: NR12 $70; seed 3', 19428: 'CH1 hit: NR12 $90; seed 10', 19509: 'CH1 volume off', 19446: 'Start a noise sequence (NR43 table, NR42 table; $FF ends / $FF in NR42 = no write)', 20216: "A = sequence id: start a CH2 tone sequence from EngineCh2SeqTable. The streams use the driver's\nnote bytes ($00-$5F, period table at $4800), lengths from $C4, WAIT $65, REST $66, END $68.", 19570: 'EngineStop (API slot 22, also called by StopAll): silence, clear $DC91/$DC93/$DC8C', 20239: 'Unreferenced: ld a, 0 / jp EngineCh2Seq', 20260: '16-byte wave. The 10 bytes after it are unreferenced leftover SM83 code: ld a, [$DC91] /\n'
                   'and a / jp z, $4062 / jp $4089 (an older form of the SndUpdate engine hook)'},
    ),
    # ---- Looney Tunes builds
    'sylvester': dict(
        ref='maus', jt=0x404A, code_end=0x4C73,
        jt_fall={0x6B85: 0x6B8E},
        jt_fall_comment='jumps 9 bytes early, into three TRANSPOSE patterns; they run as code\n'
                        '(ld l, c / ld [bc], a / ld l, d / ld l, c / ld bc, $696A / nop / ld l, d)\n'
                        'and fall through into the song routine',
        jingles=[], extra_code=[0x7510, 0x7539], glue=None, drum_count=11,
        raw_items=[(0x41BA, 16)],
        text_items=[(0x7AFA, 28)],
        labels={0x7510: 'Unused_Noise_7510', 0x7539: 'Unused_Noise_7539', 0x7AFA: 'DriverEndText'},
        jt_names={0x491D: 'PlaySfxNow (A = id; the same code as PlaySfx)'},
        blocks={},
    ),
    'bugs': dict(
        ref='seabattle', jt=0x404A, code_end=0x4B22,
        jt_dead=(0x6F8F,),
        jt_dead_comment='unused song slot: jumps into pattern data (never called)',
        jingles=[], extra_code=[0x7650], glue=None, drum_count=11,
        raw_items=[(0x41CE, 16)],
        labels={0x4B26: 'Song1Routine', 0x4CBD: 'Song2Routine', 0x7650: 'Unused_Noise_7650', 0x453D: 'StopAll', 0x48F0: 'StartMusicCh1', 0x48F4: 'StartMusicCh2', 0x48F8: 'StartMusicCh3'},
        jt_names={0x491D: 'PlaySfxNow (A = id; the same code as PlaySfx)'},
        blocks={0x4CBD: 'Song 2 (the long version of song 1: its order lists start with song 1\'s two patterns per\n'
                        'channel, then continue with new ones). Reached only through the jp at PlaySong2 ($513F),\n'
                        'which sits after song 2\'s data, just before song 3; the instrument table is StopAll\'s.',
                0x4B26: 'Song 1 proper (PlaySong1 is a jp to the next instruction)',
                0x7800: 'Not sound data: the rest of the bank (2 KB) holds game data, compressed graphics\n'
                        'that the game\'s loader lists in bank 6 read from bank 2 (from $7908, $7BD3-$7C61,\n'
                        '$7C00, $7E1D, $7E7C, $7EB1, $7F07, $7F6C).'},
    ),
}

META = {
    'smurfs': dict(title='The Smurfs (UE) (V1.0) (M4) - Game Boy', variant=' (reference)', short='smurfs',
                   asm='Smurfs_SoundDriver.asm', doc='Smurfs_SoundDriver.md'),
    'obelixgb': dict(title='Asterix & Obelix (E) (M2) (Eng-Spa) [S] - Game Boy', variant='',
                     short='obelixgb', asm='ObelixGB_SoundDriver.asm', doc='Obelix_SoundDriver.md'),
    'obelixgbc': dict(title='Asterix & Obelix (E) (M4) [C] - Game Boy Color', variant=' (GBC revision)',
                      short='obelixgbc', asm='ObelixGBC_SoundDriver.asm', doc='Obelix_SoundDriver.md'),
    'tibet': dict(title='Tintin in Tibet (E) (M4) (Eng-Fre-Ger-Dut) [S] - Game Boy', variant='',
                  short='tibet', asm='TintinTibet_SoundDriver.asm', doc='TintinTibet_SoundDriver.md'),
    'sun': dict(title='Les Aventures de Tintin: Le Temple du Soleil / Prisoners of the Sun (E) (M3) - Game Boy',
                variant='', short='sun', asm='TintinSun_SoundDriver.asm', doc='TintinSun_SoundDriver.md'),
    'spirou': dict(title='Spirou (E) (M4) [S] - Game Boy', variant='',
                   short='spirou', asm='Spirou_SoundDriver.asm', doc='Spirou_SoundDriver.md'),
    'luckyluke': dict(title='Lucky Luke (E) (M4) - Game Boy', variant='', short='luckyluke',
                      asm='LuckyLuke_SoundDriver.asm', doc='LuckyLuke_SoundDriver.md'),
    'smurfs3': dict(title="The Smurfs' Nightmare / Smurfs 3 (E) (M4) - Game Boy", variant='', short='smurfs3',
                    asm='Smurfs3_SoundDriver.asm', doc='Smurfs3_SoundDriver.md'),
    'maus': dict(title='Die Maus (E) (M4) - Game Boy', variant='', short='maus',
                 asm='Maus_SoundDriver.asm', doc='Maus_SoundDriver.md'),
    'hugo2': dict(title='Hugo 2 (G) [S] - Game Boy', variant='', short='hugo2',
                  asm='Hugo2_SoundDriver.asm', doc='Hugo2_SoundDriver.md'),
    'turok': dict(title='Turok: Battle of the Bionosaurs (UE) (M4) - Game Boy', variant='', short='turok',
                  asm='Turok_SoundDriver.asm', doc='Turok_SoundDriver.md'),
    'turok2': dict(title='Turok 2: Seeds of Evil (U) (M4) [C] - Game Boy Color', variant='', short='turok2',
                   asm='Turok2_SoundDriver.asm', doc='Turok_SoundDriver.md'),
    'otto': dict(title="Otto's Ottifanten: Baby Bruno's Nightmare (E) - Game Boy", variant='', short='otto',
                 asm='Otto_SoundDriver.asm', doc='Otto_SoundDriver.md'),
    'seabattle': dict(title='Sea Battle (E) (M4) - Game Boy', variant='', short='seabattle',
                      asm='SeaBattle_SoundDriver.asm', doc='SeaBattle_SoundDriver.md'),
    'vrally': dict(title='V-Rally: Championship Edition (U) (M3) - Game Boy', variant='', short='vrally',
                   asm='VRallyGB_SoundDriver.asm', doc='VRally_SoundDriver.md'),
    'vrallygbc': dict(title='V-Rally: Championship Edition (E) (M4) [C] - Game Boy Color', variant=' (GBC revision)',
                      short='vrallygbc', asm='VRallyGBC_SoundDriver.asm', doc='VRally_SoundDriver.md'),
    'sylvester': dict(title='Sylvester and Tweety: Breakfast on the Run (E) (M6) [C] - Game Boy Color', variant='',
                      short='sylvester', asm='Sylvester_SoundDriver.asm', doc='Sylvester_SoundDriver.md'),
    'bugs': dict(title='Bugs Bunny & Lola Bunny: Operation Carrots (E) (M6) [C] - Game Boy Color', variant='',
                 short='bugs', asm='BugsBunny_SoundDriver.asm', doc='BugsBunny_SoundDriver.md'),
}
