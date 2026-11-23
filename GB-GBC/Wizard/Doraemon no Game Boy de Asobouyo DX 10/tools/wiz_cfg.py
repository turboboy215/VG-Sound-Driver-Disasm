"""Per-game addresses for the Wizard sound driver (bank 4) and its bank-0 instrument block."""

_DX = dict(jt=0x443A, pantab=0x44B7, actclr=0x462C, freq=0x4634, voltab=0x4724, nr52mask=0x4824,
           nr51clr=0x482C, nrx2=0x4834, wavevol=0x483C, sndtab=0x484C)

GAMES = {
    'dx10': dict(rom='Doraemon DX 10 (J) [S].gb', title='Doraemon DX 10 (J) [S]', short='DX10', bank=4,
                 wram=0xC6C6, update=0x4136, version=1,
                 pitchtab=0x2846, envtab=0x2CEB, wavetab=0x2FEC, b0end=0x3046,
                 farcall=0x2442, **_DX),
    'quiz': dict(rom='Doraemon no Quiz Boy (J) (V1.0) [C][!].gbc', title='Doraemon no Quiz Boy (J) (V1.0) [C][!]', short='QuizBoy', bank=4,
                 wram=0xC963, update=0x413C, version=2,
                 pitchtab=0x3270, envtab=0x3715, wavetab=0x3A16, b0end=0x3A70,
                 farcall=0x268D, **{k: v + 6 for k, v in _DX.items()}),
}

# WRAM layout, offsets from cfg['wram']
WRAM = [
    (0x00, 'wSndPause', 1, 'non-zero: music structs neither tick nor write registers'),
    (0x01, 'wSndPan', 8, 'NR51 bits per struct (cmds $8A-$8C)'),
    (0x09, 'wSndMasterVol', 1, 'NR50 copy (fade)'),
    (0x0A, 'wSndFadeOn', 1, '1 = fade running'),
    (0x0B, 'wSndFadeRate', 1, 'frames per fade step'),
    (0x0C, 'wSndFadeCount', 1, 'fade frame counter'),
    (0x0D, 'wSndUnused0D', 2, 'not used'),
    (0x0F, 'wSndChIdx', 1, 'struct being processed (0-7)'),
    (0x10, 'wSndLastMask', 1, 'channel mask of the last sound started'),
    (0x11, 'wSndNote', 1, 'note byte being read'),
    (0x12, 'wSndRawFlag', 1, 'compared with $7D, never written by the driver'),
    (0x13, 'wSndActive', 1, 'bit n = struct n running (0-3 music ch1-4, 4-7 SFX ch1-4)'),
    (0x14, 'wSndTracks', 8 * 0x22, '8 structs of $22 bytes'),
]
