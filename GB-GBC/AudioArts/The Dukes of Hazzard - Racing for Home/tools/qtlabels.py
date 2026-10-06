"""Descriptive code labels for the QuickThunder drivers.

The labels are named by hand for the Dukes of Hazzard build (REF below). Every other
build gets them by aligning its instruction stream with the Dukes one (operands
normalised away), so a label that sits on the same instruction in the same routine
gets the same name. Labels that don't align take the name of the nearest named label
before them plus a suffix; a few build-specific routines are named in EXTRA."""
import difflib
import os
import re
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qtcfg import GAMES, load
from sm83 import decode
from trace import trace

REF_GAME = 'dukes'
REF = {
    0x4000: 'Musicd',
    # channel 1 (square)
    0x4009: 'Ch1_TempoReload', 0x4014: 'Ch1_NextEvent', 0x4028: 'Ch1_NotSongJump', 0x4034: 'Ch1_LoadStep',
    0x404B: 'Ch1_ReadLength', 0x405B: 'Ch1_NotHold', 0x406F: 'Ch1_NotKeyOff', 0x4084: 'Ch1_Note',
    0x40DD: 'Ch1_Update', 0x40F0: 'Ch1_Tables', 0x4109: 'Ch1_FreqApply', 0x412F: 'Ch1_ArpApply',
    0x414D: 'Ch1_CombApply', 0x4162: 'Ch1_NotePeriod', 0x4174: 'Ch1_AddFreqval', 0x417D: 'Ch1_WritePeriod',
    # channel 2 (square, SFX capable)
    0x4185: 'Ch2_Sequencer', 0x4196: 'Ch2_SfxTempo', 0x419A: 'Ch2_MusicTempo', 0x41A4: 'Ch2_TempoReload',
    0x41A7: 'Ch2_CountLength', 0x41AF: 'Ch2_NextEvent', 0x41C4: 'Ch2_NotSongJump', 0x41E3: 'Ch2_SfxEnd',
    0x41F3: 'Ch2_NextStep', 0x41FA: 'Ch2_LoadStep', 0x4211: 'Ch2_ReadLength', 0x4213: 'Ch2_StoreLength',
    0x4221: 'Ch2_NotHold', 0x4235: 'Ch2_NotKeyOff', 0x424A: 'Ch2_Note', 0x4257: 'Ch2_Transpose',
    0x425A: 'Ch2_AddTranspose', 0x42AE: 'Ch2_Update', 0x42C1: 'Ch2_Tables', 0x42DA: 'Ch2_FreqApply',
    0x4300: 'Ch2_ArpApply', 0x431E: 'Ch2_CombApply', 0x4333: 'Ch2_NotePeriod', 0x4345: 'Ch2_AddFreqval',
    0x434E: 'Ch2_WritePeriod',
    # channel 3 (wave)
    0x4356: 'Ch3_Sequencer', 0x435F: 'Ch3_TempoReload', 0x436A: 'Ch3_NextEvent', 0x437F: 'Ch3_NotSongJump',
    0x438B: 'Ch3_LoadStep', 0x43A2: 'Ch3_ReadLength', 0x43B2: 'Ch3_NotHold', 0x43CD: 'Ch3_Note',
    0x442B: 'Ch3_Update', 0x4442: 'Ch3_VolApply', 0x4467: 'Ch3_FreqApply', 0x448D: 'Ch3_ArpApply',
    0x44AB: 'Ch3_CombApply', 0x44C0: 'Ch3_NotePeriod', 0x44D2: 'Ch3_AddFreqval', 0x44DB: 'Ch3_WritePeriod',
    # channel 4 (noise, SFX capable)
    0x44ED: 'Ch4_Sequencer', 0x44FD: 'Ch4_SfxTempo', 0x4501: 'Ch4_MusicTempo', 0x450A: 'Ch4_TempoReload',
    0x450D: 'Ch4_CountLength', 0x4515: 'Ch4_NextEvent', 0x452A: 'Ch4_NotSongJump', 0x4549: 'Ch4_SfxEnd',
    0x4559: 'Ch4_NextStep', 0x4560: 'Ch4_LoadStep', 0x4577: 'Ch4_ReadLength', 0x4579: 'Ch4_StoreLength',
    0x4587: 'Ch4_NotHold', 0x459B: 'Ch4_NotKeyOff', 0x45AB: 'Ch4_Note', 0x45B8: 'Ch4_Transpose',
    0x45BB: 'Ch4_AddTranspose', 0x45FA: 'Ch4_Update', 0x460D: 'Ch4_Tables', 0x4624: 'Ch4_NoiseApply',
    0x4645: 'Ch4_NoiseCtlApply',
    # ghost stepper: keeps the music under a sound effect in time, without sound
    0x4651: 'Ghost_Step', 0x465E: 'Ghost_CountTempo', 0x4664: 'Ghost_TempoReload', 0x4670: 'Ghost_Ch4Tempo',
    0x4673: 'Ghost_CountLength', 0x467B: 'Ghost_NextEvent', 0x468F: 'Ghost_NotSongJump',
    0x469A: 'Ghost_LoadStep', 0x46B8: 'Ghost_Ch4Pattern', 0x46BB: 'Ghost_SetPattern',
    0x46C7: 'Ghost_ReadLength', 0x46D7: 'Ghost_NotHold', 0x46E2: 'Ghost_NotKeyOff', 0x46ED: 'Ghost_Note',
    0x4700: 'Sfx_FreeSlot',
    # wave morph
    0x470A: 'Morph_Step', 0x471A: 'Morph_NextEntry', 0x4725: 'Morph_Write', 0x474A: 'Musicd_Done',
    # MusicInit
    0x474B: 'MusicInit', 0x4795: 'Init_Ch2', 0x47C0: 'Init_Ch3', 0x47E5: 'Init_Ch4', 0x4810: 'Init_Wave',
    0x4828: 'Init_WaveCopy', 0x485A: 'Init_Mixer',
    # SoundFX
    0x486B: 'SoundFX', 0x4884: 'Sfx_Start', 0x4899: 'Sfx_MuteCh4', 0x48A5: 'Sfx_SetPattern',
    0x48B7: 'Sfx_UseCh4', 0x48BA: 'Sfx_SetChannel', 0x48CC: 'Sfx_Done',
    0x48CD: 'SirenVol', 0x48DB: 'EnginePitch',
}

# build-specific labels that have no Dukes counterpart (or align badly)
EXTRA = {
    'carm': {0x400A: 'Ch1_TempoReload', 0x4192: 'Ch2_CountTempo', 0x4199: 'Ch2_TempoReload',
             0x433D: 'Ch4_CountTempo', 0x4344: 'Ch4_TempoReload', 0x4432: 'Ch4_Tables',
             0x4489: 'Ghost_TempoReload', 0x5334: 'EngineOn_CopyWave'},
    'casperu': {0x4530: 'Ch4_DeadJump', 0x4536: 'Ch4_CountTempo', 0x4837: 'Sfx_SetPattern'},
    'gng': {0x4836: 'Sfx_SetPattern'},
    'caspere': {0x4745: 'Init_Start', 0x4825: 'Sfx_Begin'},
    'chicken': {0x4745: 'Init_Start', 0x4825: 'Sfx_Begin'},
    'pinball': {0x4751: 'MusicInit', 0x4757: 'Init_Start', 0x4877: 'SoundFX', 0x487D: 'Sfx_Begin'},
    'xgb': {},
    'cmr': {0x46B3: 'Init_Done', 0x46B4: 'SoundFX', 0x47B1: 'PitchCh1', 0x4724: 'PlayPcm',
            0x473C: 'Pcm_CheckPrio', 0x4743: 'Pcm_SetPrio', 0x4753: 'PcmTimerInit', 0x476C: 'Pcm_Start',
            0x47A3: 'SirenVol'},
}

NORM = [(re.compile(r'\binc hl\b'), 'inc l'), (re.compile(r'\bdec hl\b'), 'dec l'),
        (re.compile(r'ld a, \$00'), 'xor a, a')]


def stream(g):
    c = GAMES[g]
    mem, _ = load(g)
    code, labels = trace(mem, c['entries'], 0x4000, 0x8000)
    out = []
    a = 0x4000
    end = max(code) + 1
    while a < end:
        if a in code:
            n, m, o = decode(mem, a)
            t = m.replace('{}', 'X') if m else 'db'
            for r, s in NORM:
                t = r.sub(s, t)
            out.append((a, t))
            a += n
        else:
            a += 1
    return out, set(x for x in labels if 0x4000 <= x < 0x8000)


def names(g):
    """address -> descriptive label for game g"""
    c = GAMES[g]
    st, labels = stream(g)
    res = {}
    if g == REF_GAME:
        res = {a: n for a, n in REF.items() if a in labels or a in c['api']}
    else:
        ref, _ = stream(REF_GAME)
        sm = difflib.SequenceMatcher(None, [t for _, t in ref], [t for _, t in st], autojunk=False)
        amap = {}
        for i, j, n in sm.get_matching_blocks():
            for k in range(n):
                amap[st[j + k][0]] = ref[i + k][0]
        for a in labels:
            r = amap.get(a)
            if r in REF:
                res[a] = REF[r]
    for a, n in c['api'].items():
        res[a] = n
    for a, n in EXTRA.get(g, {}).items():
        res[a] = n
    # duplicates: keep the first, suffix the rest
    seen = {}
    for a in sorted(res):
        n = res[a]
        if n in seen:
            res[a] = '%s_%04X' % (n, a)
        seen[n] = a
    # unnamed labels: nearest named label before + address
    for a in sorted(labels):
        if a not in res:
            prev = [x for x in res if x < a]
            res[a] = ('%s_%04X' % (res[max(prev)], a)) if prev else 'L%04X' % a
    return res


# Song / SFX names: from the sound-test ROMs' menus and, for Pinball, the driver's Readme.txt
NAMES = {
 'dukes': dict(src='test ROM menu',
    songs=['Music off', 'TITLE', 'ENGINE', 'STOP ENGINE', 'SIREN', 'STOP SIREN', 'TUNE 2', 'SKID ON', 'SKID OFF',
           'CARHITCAR', 'TNT EXPLSN', 'Bridge on', 'Bridge off', 'Collision1', 'Collision2', 'Collision3',
           'Collision4', 'Arrows', 'Horn', 'Horn 2', 'Get Turbo', 'pickup 1', 'pickup 2', 'Siren down', 'skid v2',
           'skid v2 off', 'TRUCK ENGINE', 'STOP ENGINE'],
    sfx=['Blank', 'Menu beep', 'select']),
 'chicken': dict(src='test ROM menu',
    songs=['Music off', 'Title', 'Briefing', 'Daytime 1', 'Daytime 2', 'Pie 1', 'Pie 2', 'Success', 'Gameover'],
    sfx=['Blank', 'Pickup', 'Put down', 'Get Corn1', 'Get Corn2', 'Drop Corn1', 'Drop Corn2', 'Trafficlght', 'Spring',
         'Big spring', 'Hole Dig', 'Hole Drop', 'Hole up', 'Switch clk', 'Key ins', 'Trap open', 'Steam Vent', 'siren',
         'Ch. escape', 'Elec shock', 'land, soft', 'land hard', 'Dazed', 'move cursor', 'select', 'error']),
 'gng': dict(src='test ROM menu (its SFX list has 35 names; the menu and the data stop at $0B)',
    songs=['Music off', 'Levels 1&2', 'Levels 3&4', 'Levels 5&6', 'Level 7', 'Intro pt 1', 'Intro pt 2', 'Strt level',
           'Lose life', 'Game over', 'Win level'],
    sfx=['Thrw weapn', 'Obj Appear', 'KillEnemy1', 'Pickup 1', 'Player hit', 'Weap expld', 'Kill Devil', 'Intro Bang',
         'EnemyFire1', 'EnemyFire2', 'KillEnemy2', 'Pickup 2']),
 'pinball': dict(src='Readme.txt',
    songs=['Music off', 'Bumper cars', 'Multi ball', 'Flying falcon', 'River rapids', 'Lights out', 'Nite Time',
           'Thrill Ride', 'Shell', 'Daylite', 'Thrillzone'],
    sfx=['Blank', 'ball fire', 'menu move', 'menu -no', 'menuselect', 'menu back', 'awardlit', 'combo1', 'combo2',
         'combo3', 'combo4', 'careful', 'danger', 'tilt', 'light on', 'lit', 'fantasybit', 'lightsbit', 'multiball',
         'multi1', 'scoopout', 'lockopen', 'superjack', 'balldrain', 'ballsave', 'shootagian', 'flipper',
         'bonustone1', 'bonustone2', 'bonustone3', 'bonustone4', 'bonustone5', 'bonustone6', 'bonustone7',
         'bonustone8', 'finalscore', 'charge', 'happytone', 'happybonus', 'stophit', 'stophitvic', 'popbrief',
         'popbrief2', 'snack1', 'snack2', 'snack3', 'wildramp', 'wildjack', 'wildphoto', 'brassring', 'funtone',
         'funstart', 'funlock', 'kisshit', 'kissdown', 'kissbozo', 'kissvic', 'bumpcar', 'bumpscore', 'rocks',
         'rivervic', 'falcon 1', 'lightbozo', 'flac bozo', 'bear up', 'lighthit 2', 'spinner', 'orbit', 'fullboat',
         'slingshot', 'kickback', 'park disp', 'RlrCoaste', 'thrilltune', 'thrillfan', 'nightfan', 'yellowarrw',
         'nightvic', 'hidefan', 'yoohoo', 'magic', 'snackbonus', 'lightfan', 'lightbulb', 'powerup', 'victory',
         'scoopenter', 'bump pop 1', 'bump pop 2']),
}


if __name__ == '__main__':
    for g in sys.argv[1:]:
        r = names(g)
        auto = sum(1 for n in r.values() if re.search(r'_[0-9A-F]{4}$', n))
        print(g, len(r), 'labels,', auto, 'with address suffix')
        if len(sys.argv) == 2:
            for a in sorted(r):
                print('  $%04X %s' % (a, r[a]))

# one-line descriptions printed above these labels in the generated driver
COMMENTS = {
    'Musicd': 'Called once per frame: each channel block, the ghost stepper, then the wave morph (if the build has one).\n'
              'Channel 1: count the tempo; when a tick is due count the note length; at 0 read the next event.',
    'Ch1_NextEvent': 'Read the next pattern byte: $FF = song jump (word = step list), $00 = end of pattern.',
    'Ch1_LoadStep': 'Step = transpose, pattern number. Point seqadr at the pattern; its first byte is a length.',
    'Ch1_ReadLength': 'Store the length; the next byte is $FF hold, $FE key off, $FD key on, or a note.',
    'Ch1_Note': 'Note: add transpose, load the instrument (NRx1, envelopes, arp/freq/combine tables).',
    'Ch1_Update': 'Every frame: retrigger if noterset, then walk the freq, arp and combine tables.',
    'Ch1_FreqApply': 'Freq table entry: add the signed delta to freqval.',
    'Ch1_ArpApply': 'Arp table entry: semitone offset for this frame.',
    'Ch1_CombApply': 'Combine: 0 = freqval only, 1 = note, 2 = note + freqval.',
    'Ch1_WritePeriod': 'Write the period (no restart bit).',
    'Ch2_Sequencer': 'Channel 2. While noteechanadr = tempo2 the SFX struct (tempoe...) runs here instead of the music.',
    'Ch2_SfxEnd': 'SFX end ($00 + word, high byte 0): mute the channel and free the slot next frame.',
    'Ch3_Sequencer': 'Channel 3 (wave). Key off switches to the release volume table.',
    'Ch3_Update': 'Every frame: volume table -> NR32, then freq/arp/combine as on channel 1.',
    'Ch4_Sequencer': 'Channel 4 (noise). Like channel 2 (SFX capable); the note value is ignored.',
    'Ch4_Update': 'Every frame: noise table -> NR43, second table -> NR44.',
    'Ghost_Step': 'Ghost stepper: steps the music struct displaced by a sound effect, without sound,\n'
                  'so it is in the right place when the effect ends.',
    'Sfx_FreeSlot': 'effend = $FF -> noteechanadr = $FF: the channel goes back to the music.',
    'Morph_Step': 'Wave morph table (frames, wave RAM register, value): write one wave byte and restart ch3.',
    'MusicInit': 'E = song. Load the song entry, reset the channels it uses, copy the wave to wave RAM.',
    'SoundFX': 'E = id. Start the effect if the slot is free or its priority is >= the current one.',
    'SirenVol': 'A = volume: becomes channel 1\'s key-off envelope.',
    'EnginePitch': 'DE -> freqval3 (added to the ch3 note by combine mode 2).',
    'PitchCh1': 'DE -> freqval1.',
    'PlayPcm': 'E = PCM sample: priority check, then start it on the timer interrupt (ch3).',
    'PcmTimerInit': 'Timer: TMA = $E0, TAC = 4096 Hz (256 Hz interrupts in double speed).',
    'EngineOn': 'Engine drone: load a sawtooth into wave RAM and start ch3.',
    'EngineOff': 'Stop ch3.',
}
