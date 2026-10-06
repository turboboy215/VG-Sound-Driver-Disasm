"""RAM symbol names for the QuickThunder GB driver (offsets from the RAM base)."""


def _chan_tone(n, o):
    return {o + 0: 'tempo%d' % n, o + 1: 'notelen%d' % n, o + 2: 'seqadr%d' % n, o + 4: 'transp%d' % n,
            o + 5: 'patadr%d' % n, o + 7: 'note%dat' % n, o + 8: 'note%dde' % n, o + 9: 'noterset%d' % n,
            o + 10: 'duty%d' % n, o + 11: 'freqtim%d' % n, o + 12: 'freqtabadr%d' % n, o + 14: 'freqval%d' % n,
            o + 16: 'arptim%d' % n, o + 17: 'arptabadr%d' % n, o + 19: 'combtim%d' % n, o + 20: 'combtabadr%d' % n,
            o + 22: 'note%d' % n}


STD = {}
STD.update(_chan_tone(1, 0x00))
STD.update(_chan_tone(2, 0x17))
STD.update({0x2E: 'tempo3', 0x2F: 'notelen3', 0x30: 'seqadr3', 0x32: 'transp3', 0x33: 'patadr3',
            0x35: 'voltim3', 0x36: 'voltabadr3', 0x38: 'volreladr3', 0x3A: 'freqtim3', 0x3B: 'freqtabadr3',
            0x3D: 'freqval3', 0x3F: 'arptim3', 0x40: 'arptabadr3', 0x42: 'combtim3', 0x43: 'combtabadr3',
            0x45: 'note3',
            0x46: 'tempo4', 0x47: 'notelen4', 0x48: 'seqadr4', 0x4A: 'transp4', 0x4B: 'patadr4',
            0x4D: 'note4at', 0x4E: 'note4de', 0x4F: 'noterset4', 0x50: 'noisetim4', 0x51: 'noisetabadr4',
            0x53: 'noise2tim4', 0x54: 'noise2tabadr4',
            0x56: 'tempoe', 0x57: 'notelene', 0x58: 'seqadre', 0x5A: 'transpe', 0x5B: 'patadre',
            0x5F: 'noteechanadr', 0x61: 'effend'})
STD_SIZE = 0x6C

# version-specific tail of the RAM block
TAIL = {
    'tempstor': {0x62: 'tempstor1', 0x63: 'tempstor2', 0x64: 'tempstor3', 0x65: 'tempstor4', 0x66: 'effprio',
                 0x67: 'morphtim', 0x68: 'morphadr', 0x6A: 'wavefreqlo', 0x6B: 'wavefreqhi'},
    'casperu': {0x62: 'songtempo'},
    'caspere': {0x62: 'songtempo', 0x63: 'effprio', 0x64: 'morphtim', 0x65: 'morphadr', 0x67: 'wavefreqlo',
                0x68: 'wavefreqhi'},
    'gng': {0x62: 'songtempo', 0x63: 'morphtim', 0x64: 'morphadr', 0x66: 'wavefreqlo', 0x67: 'wavefreqhi'},
    'cmr': {0x62: 'tempstor1', 0x63: 'tempstor2', 0x64: 'tempstor3', 0x65: 'tempstor4', 0x66: 'effprio',
            0x67: 'pcmcount', 0x69: 'pcmactive', 0x6A: 'pcmbank', 0x6B: 'pcmadr', 0x6E: 'pcmprio'},
}

CARM = {}
for n, o in ((1, 0x00), (2, 0x16)):
    CARM.update({o + 0: 'tempo%d' % n, o + 1: 'notelen%d' % n, o + 2: 'seqadr%d' % n, o + 4: 'transp%d' % n,
                 o + 5: 'patadr%d' % n, o + 7: 'note%dat' % n, o + 8: 'note%dde' % n, o + 9: 'noterset%d' % n,
                 o + 10: 'freqtim%d' % n, o + 11: 'freqtabadr%d' % n, o + 13: 'freqval%d' % n,
                 o + 15: 'arptim%d' % n, o + 16: 'arptabadr%d' % n, o + 18: 'combtim%d' % n,
                 o + 19: 'combtabadr%d' % n, o + 21: 'note%d' % n})
CARM.update({0x2C: 'tempo4', 0x2D: 'notelen4', 0x2E: 'seqadr4', 0x30: 'transp4', 0x31: 'patadr4',
             0x33: 'note4at', 0x34: 'note4de', 0x35: 'noterset4', 0x36: 'noisetim4', 0x37: 'noisetabadr4',
             0x39: 'noise2tim4', 0x3A: 'noise2tabadr4', 0x3C: 'tempoe', 0x3D: 'notelene', 0x3E: 'seqadre',
             0x40: 'transpe', 0x41: 'patadre', 0x45: 'noteechanadr', 0x47: 'effend'})
CARM_SIZE = 0x48

TAILKEY = {'carm': None, 'casperu': 'casperu', 'caspere': 'caspere', 'chicken': 'caspere',
           'gng': 'gng', 'dukes': 'tempstor', 'xgb': 'tempstor', 'pinball': 'tempstor', 'cmr': 'cmr'}


def ram_names(g):
    """Return (dict offset->name, size)."""
    if g == 'carm':
        return dict(CARM), CARM_SIZE
    d = dict(STD)
    d.update(TAIL[TAILKEY[g]])
    return d, (0x6F if g == 'cmr' else STD_SIZE)
