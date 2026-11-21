"""Per-game configuration for AJG driver version 3 (Astérix, Pinocchio, Metal Masters).

Command argument tokens: 'b' byte, 'P' pattern goto, 'C' pattern call, 'O' order position,
'D' drum pattern, 'F' fade table, 'V' wave, 'X' code address (all words except 'b').
'hwenv' / 'release' have variable length.
"""

# canonical command set (Astérix, $60-$84)
AST_CMDS = [
    ('GLIDE', 'b'), ('GLIDE_OFF', ''), ('WAIT2', ''), ('VIBRATO', 'bbb'), ('VIB_OFF', ''),
    ('WAIT', ''), ('REST', ''), ('STOP_ALL', ''), ('END', ''), ('TRANSPOSE', 'b'),
    ('NEXT', ''), ('ORDER_JUMP', 'O'), ('LENGTH', 'b'), ('DRUMS', 'bD'), ('DRUMS_OFF', ''),
    ('PAN_C', ''), ('PAN_R', ''), ('PAN_L', ''), ('DUTY_50', ''), ('DUTY_75', ''),
    ('DUTY_12', ''), ('HWENV', 'hwenv'), ('AUTOPAN', 'b'), ('AUTODUTY', 'b'), ('FADE', 'bF'),
    ('FADE_OFF', ''), ('WAVE', 'V'), ('PORTA', 'bb'), ('PORTA_OFF', ''), ('CH_TRANSPOSE', 'b'),
    ('RELEASE', 'release'), ('ARP_OFF', ''), ('PAT_GOTO', 'P'), ('PAT_CALL', 'C'), ('CALL_CODE', 'X'),
    ('ENV_DIV', 'b'), ('NOTE_PAN', 'b'),
]
PIN_CMDS = AST_CMDS[:-1]                       # $60-$83: no NOTE_PAN
MM_CMDS = AST_CMDS[:2] + [('WAIT2', ''), ('VIBRATO', 'bbb'), ('VIB_OFF', ''), ('WAIT', ''), ('REST', '')] + AST_CMDS[7:] + [('ECHO_ON', ''), ('ECHO_OFF', '')]

FLOW_END = {'END', 'NEXT', 'STOP_ALL', 'PAT_GOTO', 'ORDER_JUMP'}
INSTR_END = {'END', 'NEXT'}

GAMES = {
    'asterix': dict(
        title='Astérix', rom='Asterix (UE) (M5) [!].gb', bank=3,
        pages=(0xDC, 0xDD, 0xDE, 0xDF), note_max=0x60, cmd_first=0x60, cmds=AST_CMDS,
        cmd_table=0x4CE8, instr_first=0x85, arp_first=0x9E, vol_first=0xAD, volenv_first=0xBD, len_first=0xCD,
        sfx_base=0x700A, sfx_count=24, drum_base=0x4FB1, drum_count=10,
        startmusic=0x54AF, playsfx=0x56A6, playon=0x56D6, startfade=0x5181,
        g_instr=(0xDB4E, 0xDB4F), g_arp=(0xDB50, 0xDB51),
        g_seq=(0xDB5D, 0xDB5E, 0xDB5F, 0xDB60),   # NR43 table hi, lo; NR42 table hi, lo
        drum_ext=(0x32, 0x35),                     # drum-pattern byte $35 takes an argument (auto pan)
        drumpat_len={0x6F8D: 7},                   # unterminated pattern (runs into the SFX stubs)
    ),
    'pinocchio': dict(
        title='The Adventures of Pinocchio (prototype)', rom='Adventures of Pinocchio, The (J).gb', bank=2,
        pages=(0xC1, 0xC2, 0xC3, 0xC4), note_max=0x60, cmd_first=0x60, cmds=PIN_CMDS,
        cmd_table=0x4212, instr_first=0x84, arp_first=0x9E, vol_first=0xAD, volenv_first=0xBD, len_first=0xCD,
        sfx_base=0x4B91, sfx_count=11, drum_base=0x44AF, drum_count=9,
        startmusic=0x4937, playsfx=0x4B27, playon=0x4B57, startfade=0x4626,
        g_instr=(0xFF99, 0xFF9A), g_arp=(0xFF9B, 0xFF9C),
        g_seq=(0xFFA7, 0xFFA8, 0xFFA9, 0xFFAA),
        drum_ext=(0x32, None),                     # no $35 in this version
    ),
    'metalmasters': dict(
        title='Metal Masters', rom='Metal Masters (U).gb', bank=2,
        pages=(0xC6, 0xC7, 0xC8, 0xC9), note_max=0x5E, cmd_first=0x5E, cmds=MM_CMDS,
        cmd_table=0x5C7B, instr_first=0x85, arp_first=0x9E, vol_first=0xAD, volenv_first=0xBD, len_first=0xCD,
        sfx_base=0x70B0, sfx_count=24, drum_base=0x5F9B, drum_count=11,
        startmusic=0x6463, playsfx=0x6659, playon=0x6689, startfade=0x616C,
        g_instr=(0xC5C8, 0xC5C9), g_arp=(0xC5CA, 0xC5CB),
        g_seq=(0xC5D7, 0xC5D8, 0xC5D9, 0xC5DA), drum_ext=(0x32, 0x35),
    ),
}

for g in GAMES.values():
    assert len(g['cmds']) == g['instr_first'] - g['cmd_first'], (g['title'], len(g['cmds']))
