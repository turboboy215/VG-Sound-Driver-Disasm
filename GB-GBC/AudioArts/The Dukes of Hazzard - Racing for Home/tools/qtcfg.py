"""Per-game configuration for the AudioArts QuickThunder GB(C) driver family."""

# ver keys:
#  step     bytes per step-list entry (2 = transpose,pat8 ; 3 = transpose,pat16 ; 4 = transpose,unused,pat16)
#  song     'c3'  : dw ch1,ch2,ch4                           (6 bytes)
#           'c4w' : dw ch1..ch4 ; db tempo ; dw wave          (11 bytes)
#           'c4mw': dw ch1..ch4 ; db tempo ; dw morph, wave   (13 bytes)
#           'mask': db tempo, mask ; dw <ptr per mask bit> [morph, wave] (14 bytes)
#  sfx      'p'   : dw ptr ; db chan       (3 bytes)
#           'pp'  : db prio ; dw ptr ; db chan (4 bytes)
#  sfxloop  True if an SFX pattern end is '00 lo hi' (hi != 0 -> loop)
#  wave     channel 3 is a music wave channel (wave instruments, vol tables, wave RAM)
#  morph    song carries a wave-morph table
#  pcm      CMR-style PCM table (6-byte entries)

GAMES = {
 'carm': dict(
    title='Carmageddon (GBC)', file='Carmageddon (UE) (M4) [C][!].gbc', bank=0x41,
    entries=[0x4000, 0x4522, 0x45C4, 0x532A, 0x5351, 0x5356],
    api={0x4000: 'Musicd', 0x4522: 'MusicInit', 0x45C4: 'SoundFX',
         0x532A: 'EngineOn', 0x5351: 'EngineOff', 0x5356: 'EnginePitch'},
    extra_items=[(0x536A, 16, 'wave', 'EngineWave'), (0x537A, 128, 'wordtab', 'EnginePitchTable')],
    ram=0xD800, step=2, song='c3', sfx='p', sfxloop=False, wave=False, morph=False,
    chans=[1, 2, 4],
    tabs=dict(blankpat=0x45F5, freq=0x45F6, sfxtab=0x4686, songtab=0x46B6, pattab=0x4A53, instab=0x4ACF, instab4=0x4B05),
 ),
 'casperu': dict(
    title='Casper (U) (GBC)', file='Casper (U) [C][!].gbc', bank=0x1F,
    entries=[0x4000, 0x474A, 0x481A, 0x4530], api={0x4000: 'Musicd', 0x474A: 'MusicInit', 0x481A: 'SoundFX'},
    ram=0xD000, step=4, song='c4w', sfx='p', sfxloop=True, wave=True, morph=False,
    chans=[1, 2, 3, 4],
    tabs=dict(blankvol=0x4867, blankpat=0x486D, freq=0x486E, sfxtab=0x48FE, songtab=0x4949, pattab=0x4985, instab=0x4A2D, instab4=0x4A99),
 ),
 'caspere': dict(
    title='Casper (E) (GBC)', file='Casper (E) (M3) (Eng-Fre-Ger) [C][!].gbc', bank=0x1F,
    entries=[0x4000, 0x473F, 0x481F], api={0x4000: 'Musicd', 0x473F: 'MusicInit', 0x481F: 'SoundFX'},
    ram=0xD000, step=2, song='c4mw', sfx='pp', sfxloop=True, wave=True, morph=True,
    chans=[1, 2, 3, 4],
    tabs=dict(blankvol=0x48D4, blankpat=0x48DA, freq=0x48DB, sfxtab=0x496B, songtab=0x49CF, pattab=0x4A13, instab=0x4AC5, instab4=0x4B35),
 ),
 'chicken': dict(
    title='Chicken Run sound test (GB, PD)', file='GB Audioarts Sounds - Chicken Run (PD).gb', bank=1,
    entries=[0x4000, 0x473F, 0x481F], api={0x4000: 'Musicd', 0x473F: 'MusicInit', 0x481F: 'SoundFX'},
    ram=0xC080, step=2, song='c4mw', sfx='pp', sfxloop=True, wave=True, morph=True,
    chans=[1, 2, 3, 4],
    tabs=dict(blankvol=0x4886, blankpat=0x488C, freq=0x488D, sfxtab=0x491D, songtab=0x4AF5, pattab=0x4B6A, instab=0x4CF4, instab4=0x4D7C),
 ),
 'gng': dict(
    title="Ghosts 'n Goblins sound test (GB, PD)", file='GB Audioarts Sounds - Ghosts n Goblins (PD).gb', bank=1,
    entries=[0x4000, 0x473F, 0x4819], api={0x4000: 'Musicd', 0x473F: 'MusicInit', 0x4819: 'SoundFX'},
    ram=0xC100, step=2, song='c4mw', sfx='p', sfxloop=True, wave=True, morph=True,
    chans=[1, 2, 3, 4],
    tabs=dict(blankvol=0x4865, blankpat=0x486B, freq=0x486C, sfxtab=0x48FC, songtab=0x4920, pattab=0x49AF, instab=0x4A7F, instab4=0x4AAF),
 ),
 'dukes': dict(
    title='Dukes of Hazzard sound test (GB, PD)', file='GB Audioarts Sounds - Dukes of Hazzard (PD).gb', bank=1,
    entries=[0x4000, 0x474B, 0x486B, 0x48CD, 0x48DB],
    api={0x4000: 'Musicd', 0x474B: 'MusicInit', 0x486B: 'SoundFX', 0x48CD: 'SirenVol', 0x48DB: 'EnginePitch'},
    ram=0xC100, step=2, song='mask', sfx='pp', sfxloop=True, wave=True, morph=True,
    chans=[1, 2, 3, 4],
    tabs=dict(blankvol=0x48E3, blankpat=0x48E9, freq=0x48EA, sfxtab=0x497A, songtab=0x4992, pattab=0x4B1A, instab=0x4BD0, instab4=0x4C4A),
 ),
 'xgb': dict(
    title='Extreme Ghostbusters (E) (GBC)', file='Extreme Ghostbusters (E) (M6) [C][!].gbc', bank=2,
    entries=[0x4000, 0x4003, 0x4006], api={0x4000: 'Snd_Init', 0x4003: 'Snd_FX', 0x4006: 'Musicd'},
    ram=0xC0A0, step=4, song='mask', sfx='pp', sfxloop=True, wave=True, morph=True,
    chans=[1, 2, 3, 4],
    tabs=dict(blankvol=0x48F8, blankpat=0x48FE, freq=0x48FF, sfxtab=0x498F, songtab=0x4BBE, pattab=0x4C4A, instab=0x4E8A, instab4=0x4F1C),
 ),
 'cmr': dict(
    title='Colin McRae Rally (E) (GBC)', file='Colin McRae Rally (E) [C][!].gbc', bank=0x7D,
    entries=[0x4000, 0x4003, 0x4006, 0x4009, 0x400C, 0x47A3],
    api={0x4000: 'Snd_Init', 0x4003: 'Snd_FX', 0x4006: 'Snd_Pitch', 0x4009: 'Snd_PCMInit', 0x400C: 'Musicd', 0x47A3: 'SirenVol'},
    ram=0xC100, step=2, song='mask', sfx='pp', sfxloop=True, wave=False, morph=False, pcm=0x56F4, song_mw=True,
    chans=[1, 2, 3, 4],
    tabs=dict(blankvol=0x47B9, blankpat=0x47BF, freq=0x47C0, sfxtab=0x4850, songtab=0x4866, pattab=0x4AEA, instab=0x4B54, instab4=0x4BBC),
 ),
 'pinball': dict(
    title='3-D Ultra Pinball: Thrillride (musicd.bin)', file='musicd.bin', bank=None,
    entries=[0x4000, 0x4003, 0x4006], api={0x4000: 'Snd_Init', 0x4003: 'Snd_FX', 0x4006: 'Musicd'},
    ram=0xC594, step=2, song='mask', sfx='pp', sfxloop=True, wave=True, morph=True,
    chans=[1, 2, 3, 4],
    tabs=dict(blankvol=0x48F5, blankpat=0x48FB, freq=0x48FC, sfxtab=0x498C, songtab=0x55A1, pattab=0x563B, instab=0x57F9, instab4=0x5893),
 ),
}

import os
# ROM folder: $QT_ROMS, else the folder two levels above this file (AA/QuickThunder/tools -> AA)
DIR = os.environ.get('QT_ROMS', os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')) + os.sep


def load(g):
    """Return a 32 KB CPU-view image (bank in $4000-$7FFF) and the full ROM bytes."""
    c = GAMES[g]
    d = open(DIR + c['file'], 'rb').read()
    if c['bank'] is None:
        m = bytearray(0x8000)
        m[0x4000:0x4000 + len(d)] = d
        return bytes(m), d
    b = c['bank'] * 0x4000
    return bytes(bytearray(0x4000) + d[b:b + 0x4000]), d
