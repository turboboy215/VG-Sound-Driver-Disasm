"""Per-game configuration for AJG driver version 4 (The Smurfs, Obelix GB, Obelix GBC,
Tintin in Tibet, Tintin: Prisoners of the Sun, Spirou, Lucky Luke, The Smurfs' Nightmare,
Die Maus, Hugo 2, Turok, Turok 2, Otto's Ottifanten, Sea Battle, V-Rally,
Sylvester and Tweety, Bugs Bunny & Lola Bunny).

Command argument tokens: 'b' byte, 'P' pattern goto, 'C' pattern call, 'D' drum pattern,
'F' fade table, 'V' wave, 'X' code address (all words except 'b').
'hwenv' / 'release' / 'hook' have variable length.
"""

# canonical command set (The Smurfs, $60-$83)
SMURFS_CMDS = [
    ('GLIDE', 'b'), ('GLIDE_OFF', ''), ('WAIT2', ''), ('VIBRATO', 'bbb'), ('VIB_OFF', ''),
    ('WAIT', ''), ('REST', ''), ('STOP_ALL', ''), ('END', ''), ('TRANSPOSE', 'b'),
    ('NEXT', ''), ('LENGTH', 'b'), ('DRUMS', 'bD'), ('DRUMS_OFF', ''),
    ('PAN_C', ''), ('PAN_R', ''), ('PAN_L', ''), ('DUTY_50', ''), ('DUTY_75', ''), ('DUTY_12', ''),
    ('HWENV', 'hwenv'), ('AUTOPAN', 'b'), ('AUTODUTY', 'b'), ('FADE', 'bF'), ('FADE_OFF', ''),
    ('WAVE', 'V'), ('CH_TRANSPOSE', 'b'), ('RELEASE', 'release'), ('ARP_OFF', ''),
    ('PAT_GOTO', 'P'), ('PAT_CALL', 'C'), ('CALL_CODE', 'X'), ('REPEAT_END', ''), ('VOL', 'b'),
    ('SLIDE_UP', 'b'), ('SLIDE_DOWN', 'b'),
]
GBC_CMDS = SMURFS_CMDS + [('NOTE_HOOK', 'hook')]      # $84
# Die Maus: SLIDE_UP/SLIDE_DOWN dropped; NOTE_HOOK moves to $82, new PORTA/PORTA_OFF at $83/$84
MAUS_CMDS = SMURFS_CMDS[:-2] + [('NOTE_HOOK', 'hook'), ('PORTA', 'bb'), ('PORTA_OFF', '')]

FLOW_END = {'END', 'NEXT', 'STOP_ALL', 'PAT_GOTO'}
INSTR_END = {'END'}                                    # macros end only at END ($68)

_COMMON = dict(note_max=0x60, cmd_first=0x60, pages=(0xC1, 0xC2, 0xC3, 0xC4), bank=6,
               period_table=0x4800, startmusic=0x48F0)

GAMES = {
    'smurfs': dict(_COMMON,
        title='The Smurfs', rom='Smurfs, The (UE) (V1.0) (M4) [!].gb', cmds=SMURFS_CMDS,
        cmd_table=0x4400, instr_first=0x84, arp_first=0x8E, volenv_first=0xA9, len_first=0xB9, rep_first=0xE9,
        drum_tempo_first=0xB9, drum_base=0x49FB,
        sfx_base=0x769D, sfx_count=29, playsfx=0x491D, ch3vol=0x4166,
        g=dict(base=0xC196),
    ),
    'obelixgb': dict(_COMMON,
        title='Asterix & Obelix (GB)', rom='Obelix (E) (M2) (Eng-Spa) [S][!].gb', cmds=SMURFS_CMDS,
        cmd_table=0x4400, instr_first=0x84, arp_first=0x91, volenv_first=0xAD, len_first=0xBD, rep_first=0xED,
        drum_tempo_first=0xBD, drum_base=0x49F9,
        sfx_base=0x7595, sfx_count=29, playsfx=0x4925, ch3vol=0x414E,
        g=dict(base=0xC196),
    ),
    'obelixgbc': dict(_COMMON,
        title='Asterix & Obelix (GBC)', rom='Obelix (E) (M4) [C][!].gbc', cmds=GBC_CMDS,
        cmd_table=0x4000, instr_first=0x85, arp_first=0x96, volenv_first=0xB2, len_first=0xC2, rep_first=0xF2,
        drum_tempo_first=0xC2, drum_base=0x49F2,
        sfx_base=0x7596, sfx_count=29, playsfx=0x4919, ch3vol=0x41CA,
        g=dict(base=0xC142), duty_shadows=True,
    ),
    # bank 15 games: command table at $4000 (as Obelix GBC), API jump table after it
    'tibet': dict(_COMMON, bank=15,
        title='Tintin in Tibet', rom='Tintin in Tibet (E) (M4) (Eng-Fre-Ger-Dut) [S].gb', cmds=SMURFS_CMDS,
        cmd_table=0x4000, instr_first=0x84, arp_first=0x91, volenv_first=0xAD, len_first=0xBD, rep_first=0xED,
        drum_tempo_first=0xBD, drum_base=0x49F1,
        sfx_base=0x7663, sfx_count=28, playsfx=0x491D, ch3vol=0x4190,
        g=dict(base=0xC13C),
    ),
    'sun': dict(_COMMON, bank=15, pages=(0xDC, 0xDD, 0xDE, 0xDF),
        title='Tintin: Prisoners of the Sun', rom='Les Aventures De TinTin - Le Temple du Soleil (E) (M3) [M].gb',
        cmds=GBC_CMDS,
        cmd_table=0x4000, instr_first=0x85, arp_first=0x96, volenv_first=0xB2, len_first=0xC2, rep_first=0xF2,
        drum_tempo_first=0xC2, drum_base=0x49F2,
        sfx_base=0x7234, sfx_count=21, playsfx=0x4919, ch3vol=0x41D8,
        g=dict(base=0xDC42),
    ),
    'spirou': dict(_COMMON, bank=15,
        title='Spirou', rom='Spirou (E) (M4) [S][!].gb', cmds=GBC_CMDS,
        cmd_table=0x4000, instr_first=0x85, arp_first=0x92, volenv_first=0xAE, len_first=0xBE, rep_first=0xEE,
        drum_tempo_first=0xBE, drum_base=0x49F1,
        sfx_base=0x76AA, sfx_count=31, playsfx=0x491D, ch3vol=0x41AD,
        g=dict(base=0xC142),
    ),
    # ---- Lucky Luke family (Prisoners of the Sun output, Spirou pause/NR50 model)
    'luckyluke': dict(_COMMON, bank=12, pages=(0xDB, 0xDC, 0xDD, 0xDE),
        title='Lucky Luke', rom='Lucky Luke (E) (M4) [M].gb', cmds=GBC_CMDS,
        cmd_table=0x4000, instr_first=0x85, arp_first=0x94, volenv_first=0xB0, len_first=0xC0, rep_first=0xF0,
        drum_tempo_first=0xC0, drum_base=0x49F1,
        sfx_base=0x777C, sfx_count=40, playsfx=0x491D, ch3vol=0x41CB,
        g=dict(base=0xDB42),
    ),
    'smurfs3': dict(_COMMON, bank=2, pages=(0xDB, 0xDC, 0xDD, 0xDE),
        title="The Smurfs' Nightmare", rom='Smurfs 3, The (E) (M4) [!].gb', cmds=GBC_CMDS,
        cmd_table=0x4000, instr_first=0x85, arp_first=0x94, volenv_first=0xB0, len_first=0xC0, rep_first=0xF0,
        drum_tempo_first=0xC0, drum_base=0x49F1,
        sfx_base=0x7696, sfx_count=16, playsfx=0x491D, ch3vol=0x41CE,
        g=dict(base=0xDB42),
    ),
    'maus': dict(_COMMON, bank=15,
        title='Die Maus', rom='Maus, Die (E) (M4) [M].gb', cmds=MAUS_CMDS,
        cmd_table=0x4000, instr_first=0x85, arp_first=0x93, volenv_first=0xAC, len_first=0xBC, rep_first=0xEC,
        drum_tempo_first=0xBC, drum_base=0x49F1,
        sfx_base=0x6A4C, sfx_count=61, playsfx=0x491D, ch3vol=0x41BA,
        g=dict(base=0xC14B),
    ),
    # ---- Prisoners of the Sun group (Sun's driver, game-specific edits)
    'hugo2': dict(_COMMON, bank=7, pages=(0xDC, 0xDD, 0xDE, 0xDF),
        title='Hugo 2', rom='Hugo 2 (G) [S][!].gb', cmds=GBC_CMDS,
        cmd_table=0x4000, instr_first=0x85, arp_first=0x96, volenv_first=0xB2, len_first=0xC2, rep_first=0xF2,
        drum_tempo_first=0xC2, drum_base=0x49F2,
        sfx_base=0x63C9, sfx_count=16, sfx_dummy=(2, 3), playsfx=0x4919, ch3vol=0x41C4,
        g=dict(base=0xDC42),
    ),
    'turok': dict(_COMMON, bank=15, pages=(0xDC, 0xDD, 0xDE, 0xDF),
        title='Turok: Battle of the Bionosaurs', rom='Turok - Battle of the Bionosaurs (UE) (M4) [!].gb',
        cmds=GBC_CMDS, startmusic_list=(0x48F0, 0x48FE, 0x490C),
        cmd_table=0x4000, instr_first=0x85, arp_first=0x98, volenv_first=0xB4, len_first=0xC4, rep_first=0xF4,
        drum_tempo_first=0xC4, drum_base=0x4A10,
        sfx_base=0x73CA, sfx_count=39, playsfx=0x4937, ch3vol=0x41CC,
        g=dict(base=0xDC42),
    ),
    'turok2': dict(_COMMON, bank=15, pages=(0xDC, 0xDD, 0xDE, 0xDF),
        title='Turok 2: Seeds of Evil', rom='Turok 2 - Seeds of Evil (U) (M4) [C][!].gbc',
        cmds=GBC_CMDS, startmusic_list=(0x48F0, 0x48FE, 0x490C),
        cmd_table=0x4000, instr_first=0x85, arp_first=0x9B, volenv_first=0xB7, len_first=0xC7, rep_first=0xF7,
        drum_tempo_first=0xC7, drum_base=0x4A10,
        sfx_base=0x7514, sfx_count=31, playsfx=0x4937, ch3vol=0x41CC,
        g=dict(base=0xDC42),
    ),
    # ---- 1998-99 builds (this session)
    'otto': dict(_COMMON, bank=3,
        title="Otto's Ottifanten: Baby Bruno's Nightmare", rom="Otto's Ottifanten (E).gb", cmds=MAUS_CMDS,
        cmd_table=0x4000, instr_first=0x85, arp_first=0x93, volenv_first=0xAC, len_first=0xBC, rep_first=0xEC,
        drum_tempo_first=0xBC, drum_base=0x49F1,
        sfx_base=0x6D5F, sfx_count=25, playsfx=0x491D, ch3vol=0x41BA,
        g=dict(base=0xC14B),
    ),
    'seabattle': dict(_COMMON, bank=4, pages=(0xDC, 0xDD, 0xDE, 0xDF),
        title='Sea Battle', rom='Sea Battle (E) (M4).gb', cmds=GBC_CMDS,
        cmd_table=0x4000, instr_first=0x85, arp_first=0x94, volenv_first=0xB0, len_first=0xC0, rep_first=0xF0,
        drum_tempo_first=0xC0, drum_base=0x49F1,
        sfx_base=0x5574, sfx_count=13, playsfx=0x491D, ch3vol=0x41CE,
        g=dict(base=0xDC42),
    ),
    'vrally': dict(_COMMON, bank=2, pages=(0xDB, 0xDC, 0xDD, 0xDE),
        title='V-Rally: Championship Edition (GB)', rom='V-Rally - Championship Edition (U) (M3) [M][!].gb',
        cmds=GBC_CMDS, startmusic_list=(0x490E, 0x491C, 0x492A),
        cmd_table=0x4000, instr_first=0x85, arp_first=0x98, volenv_first=0xB4, len_first=0xC4, rep_first=0xF4,
        drum_tempo_first=0xC4, drum_base=0x4A2E,
        sfx_base=0x5D33, sfx_count=2, playsfx=0x4955, ch3vol=0x41E5,
        g=dict(base=0xDB42),
    ),
    'vrallygbc': dict(_COMMON, bank=16, pages=(0xDB, 0xDC, 0xDD, 0xDE),
        title='V-Rally: Championship Edition (GBC)', rom='V-Rally - Championship Edition (E) (M4) [C][!].gbc',
        cmds=GBC_CMDS, startmusic_list=(0x490E, 0x491C, 0x492A),
        cmd_table=0x4000, instr_first=0x85, arp_first=0x98, volenv_first=0xB4, len_first=0xC4, rep_first=0xF4,
        drum_tempo_first=0xC4, drum_base=0x4A2E,
        sfx_base=0x5DDE, sfx_count=2, playsfx=0x4955, ch3vol=0x41F2,
        g=dict(base=0xDB42), duty_shadows=True,
    ),
    # ---- Looney Tunes builds (1998)
    'sylvester': dict(_COMMON, bank=15,
        title='Sylvester and Tweety: Breakfast on the Run', rom='Sylvester and Tweety (E) (M6) [C][!].gbc', cmds=MAUS_CMDS,
        cmd_table=0x4000, instr_first=0x85, arp_first=0x94, volenv_first=0xAD, len_first=0xBD, rep_first=0xED,
        drum_tempo_first=0xBD, drum_base=0x49F1,
        sfx_base=0x7071, sfx_count=56, playsfx=0x491D, ch3vol=0x41BA,
        g=dict(base=0xC14B),
    ),
    'bugs': dict(_COMMON, bank=2, pages=(0xDB, 0xDC, 0xDD, 0xDE),
        title='Bugs Bunny & Lola Bunny: Operation Carrots', rom='Bugs Bunny & Lola Bunny - Operation Carrots (E) (M6) [C][!].gbc',
        cmds=GBC_CMDS,
        cmd_table=0x4000, instr_first=0x85, arp_first=0x94, volenv_first=0xB0, len_first=0xC0, rep_first=0xF0,
        drum_tempo_first=0xC0, drum_base=0x49F1,
        sfx_base=0x71A4, sfx_count=21, playsfx=0x491D, ch3vol=0x41CE,
        g=dict(base=0xDB42),
    ),
}

# global offsets relative to wPaused (Smurfs/Obelix GB $C196, Obelix GBC/Spirou $C142,
# Tintin in Tibet $C13C, Prisoners of the Sun $DC42)
GLOBALS = [
    (0x00, 'wPaused'), (0x01, 'wStereo'), (0x02, 'wShNR32'), (0x03, 'wInInstr'), (0x04, 'wNoisePan'),
    (0x05, 'wDrumHold'), (0x06, 'wInstrTable'), (0x07, 'wInstrTableHi'), (0x08, 'wArpTable'),
    (0x09, 'wArpTableHi'), (0x0A, 'wMusicWave'), (0x0B, 'wMusicWaveHi'), (0x0C, 'wNoiseAutoPan'),
    (0x0D, 'wDrumPatHi'), (0x0E, 'wDrumPat'), (0x0F, 'wDrumPos'), (0x10, 'wDrumsOn'),
    (0x11, 'wDrumTempo'), (0x12, 'wDrumTimer'), (0x13, 'wDrumLoopCount'), (0x14, 'wDrumLoopPos'),
    (0x15, 'wNoise43Hi'), (0x16, 'wNoise43'), (0x17, 'wNoise42Hi'), (0x18, 'wNoise42'),
    (0x19, 'wNoisePos'), (0x1A, 'wNoiseOn'), (0x1B, 'wNoiseAtten'), (0x1C, 'wNoiseTimer'),
    (0x1D, 'wNoiseSpeed'), (0x1E, 'wFadeTable'), (0x1F, 'wFadeTableHi'), (0x20, 'wFadePos'),
    (0x21, 'wFadeTimer'), (0x22, 'wFadeSpeed'), (0x23, 'wFadeOn'),
    (0x24, 'wDutyCh1'), (0x25, 'wDutyCh2'),                 # Obelix GBC only (duty_shadows)
]

for k, g in GAMES.items():
    assert len(g['cmds']) == g['instr_first'] - g['cmd_first'], (k, len(g['cmds']))
    b = g['g']['base']
    g['g_instr'] = (b + 6, b + 7)
    g['g_arp'] = (b + 8, b + 9)
    g['g_seq'] = (b + 0x15, b + 0x16, b + 0x17, b + 0x18)   # NR43 hi, lo; NR42 hi, lo
    sm = g['startmusic']
    g.setdefault('startmusic_list', (sm, sm + 4, sm + 8))  # StartMusicCh1/2/3 (Turok games: 14 bytes apart)
    g.setdefault('sfx_dummy', ())                         # ids handled by game glue (table entry not a stream)
