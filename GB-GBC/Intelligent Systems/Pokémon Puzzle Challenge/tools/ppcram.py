"""RAM / HRAM / hardware symbols for the Pokemon Puzzle Challenge sound system."""

HW = {
    0xFF10: 'rNR10', 0xFF11: 'rNR11', 0xFF12: 'rNR12', 0xFF13: 'rNR13', 0xFF14: 'rNR14',
    0xFF16: 'rNR21', 0xFF17: 'rNR22', 0xFF18: 'rNR23', 0xFF19: 'rNR24',
    0xFF1A: 'rNR30', 0xFF1B: 'rNR31', 0xFF1C: 'rNR32', 0xFF1D: 'rNR33', 0xFF1E: 'rNR34',
    0xFF20: 'rNR41', 0xFF21: 'rNR42', 0xFF22: 'rNR43', 0xFF23: 'rNR44',
    0xFF24: 'rNR50', 0xFF25: 'rNR51', 0xFF26: 'rNR52', 0xFF30: '_AUD3WAVERAM',
    0x2100: 'rROMB0',
}
HRAM = {
    0xFFA3: 'hROMBank',      # shadow of the MBC5 ROM bank register
    0xFFA8: 'hConsoleType',  # $11 = CGB (compared by the PCM player)
    0xFFBE: 'hJoyPressed',   # newly pressed buttons (used by the sound test)
}

# music channel structure (base = wMusCh1 = $C602, stride $30)
MUS_FIELDS = [
    (0x00, 'Flags', 'bit0 muted (SFX owns the channel), bit1 release pending'),
    (0x01, 'Update', 'register-write mask: bit0-4 NRx0-NRx4, bit5 pan, bit6 pitch changed, bit7 trigger'),
    (0x02, 'NRx0', 'NRx0 shadow'), (0x03, 'NRx1', 'NRx1 shadow (duty/length)'),
    (0x04, 'NRx2', 'NRx2 shadow (volume envelope)'), (0x05, 'NRx3', 'NRx3 shadow (period low)'),
    (0x06, 'NRx4', 'NRx4 shadow (period high, trigger)'),
    (0x07, 'Ptr', 'track pointer (2), in bank wMusicBank'),
    (0x09, 'Length', 'current note length - 1 (ticks)'),
    (0x0A, 'Timer', 'ticks left on the current event'),
    (0x0B, 'Loop1', 'LOOP counter 1'), (0x0C, 'Loop2', 'LOOP counter 2'),
    (0x0D, 'Loop3', 'LOOP counter 3'), (0x0E, 'Loop4', 'LOOP counter 4'),
    (0x0F, 'Stack', 'GOSUB return stack (3 x 2 usable)'),
    (0x15, 'StackPos', 'GOSUB stack offset (0,2,4)'),
    (0x16, 'Transpose', 'semitones added to notes (noise index on ch4)'),
    (0x17, 'Detune', 'signed, added to the hardware period'),
    (0x18, 'PitchDetune', 'signed, added to the pitch before the period lookup'),
    (0x19, 'Gate', 'release when the timer reaches this value (0 = off)'),
    (0x1A, 'Pitch', 'pitch (2): semitone*8 + eighth (ch4: noise index)'),
    (0x1C, 'PMacBase', 'pitch macro start (2); high byte 0 = none'),
    (0x1E, 'PMacPtr', 'pitch macro position (2); high byte 0 = stopped'),
    (0x20, 'PMacSpeed', 'ticks between pitch macro deltas - 1'),
    (0x21, 'PMacTimer', 'pitch macro tick counter'),
    (0x22, 'EnvAttack', 'envelope sequence started at note-on (2)'),
    (0x24, 'EnvPtr', 'envelope position (2); high byte 0 = stopped'),
    (0x26, 'EnvTimer', 'frames left on the current envelope step'),
    (0x27, 'EnvRelease', 'envelope sequence started at release (2)'),
    (0x29, 'SlideTimer', 'SLIDE ticks left'),
    (0x2A, 'SlideLeft', 'SLIDE distance left (3, 16.8 fixed)'),
    (0x2D, 'SlideStep', 'SLIDE step per tick (2, 8.8 fixed)'),
    (0x2F, 'SlideFrac', 'SLIDE pitch fraction'),
]

SFXA_FIELDS = {  # per channel: list of (offset, name)
    1: [(0, 'Id'), (1, 'Ptr'), (3, 'Timer'), (4, 'Priority'), (5, 'Duty'), (6, 'Note'), (7, 'Length'),
        (8, 'LenEnable'), (9, 'Transpose'), (10, 'Fine'), (11, 'Return'), (13, 'LoopPtr'), (15, 'LoopCount'),
        (16, 'SlideAcc'), (18, 'SlideStep'), (20, 'SlideTimer')],
    3: [(0, 'Id'), (1, 'Ptr'), (3, 'Timer'), (4, 'Priority'), (5, 'LoadedWave'), (6, 'Wave'), (7, 'Note'),
        (8, 'Length'), (9, 'LenEnable'), (10, 'Transpose'), (11, 'Fine'), (12, 'Return'), (14, 'LoopPtr'),
        (16, 'LoopCount'), (17, 'SlideAcc'), (19, 'SlideStep'), (21, 'SlideTimer')],
    4: [(0, 'Id'), (1, 'Ptr'), (3, 'Timer'), (4, 'Priority'), (5, 'LFSR'), (6, 'Note'), (7, 'Length'),
        (8, 'LenEnable'), (9, 'Transpose'), (10, 'Return'), (12, 'LoopPtr'), (14, 'LoopCount')],
}
SFXA_BASE = {1: 0xC7CF, 2: 0xC7E4, 3: 0xC7F9, 4: 0xC80F}

SFXB_FIELDS = [(0, 'NRx0'), (1, 'NRx1'), (2, 'NRx2'), (3, 'NRx3'), (4, 'NRx4'), (5, 'Ptr'), (7, 'Timer'), (8, 'DutySeq')]
SFXB_BASE = {1: 0xC7AE, 2: 0xC7B7, 4: 0xC7C0}

GLOBALS = [
    (0xC5F0, 'wMusicFlags', 'bit7: music running'),
    (0xC5F1, 'wMusicHwUpdate', 'bit0: write NR50, bit1: write NR52 (cleared every frame)'),
    (0xC5F2, 'wMusicUnusedF2', 'cleared by Music_Init, never used'),
    (0xC5F3, 'wMusicUnusedF3', ''), (0xC5F4, 'wMusicUnusedF4', ''), (0xC5F5, 'wMusicUnusedF5', ''),
    (0xC5F6, 'wMusicNR50', 'master volume shadow'),
    (0xC5F7, 'wMusicPan', 'NR51 bits requested by the tracks'),
    (0xC5F8, 'wMusicNR52', 'NR52 shadow'),
    (0xC5F9, 'wMusicNR51', 'NR51 value last written by the music'),
    (0xC5FA, 'wMusicTempo', 'tempo: ticks per frame x 30'),
    (0xC5FB, 'wMusicTempoAcc', 'tempo accumulator'),
    (0xC5FC, 'wMusicBank', 'ROM bank of the current song'),
    (0xC5FD, 'wFadeSpeed', 'frames per fade step (0 = no fade)'),
    (0xC5FE, 'wFadeTimer', ''),
    (0xC5FF, 'wFadeStep', 'index into FadeStepTable'),
    (0xC600, 'wMusicWave', 'ch3 wave number (WAVE)'),
    (0xC601, 'wSoundOff', 'nonzero: Sound_PlayMusic and Sound_FadeOut are ignored, engine A is off'),
    (0xC6C2, 'wMusCh1DrumJp', 'drum trampoline: $C3 (jp) while a drum runs, else 0; then the routine address'),
    (0xC6C3, 'wMusCh1DrumPtr', ''),
    (0xC6C5, 'wMusCh2DrumJp', ''), (0xC6C6, 'wMusCh2DrumPtr', ''),
    (0xC6C8, 'wMusCh3DrumJp', ''), (0xC6C9, 'wMusCh3DrumPtr', ''),
    (0xC6CB, 'wMusCh4DrumJp', ''), (0xC6CC, 'wMusCh4DrumPtr', ''),
    (0xC6CE, 'wSoundTestSong', 'song number of the debug sound test'),
    (0xC6CF, 'wMusicSave', '$DF bytes: copy of $C5F0-$C6CE made by Music_Save'),
    (0xC7C9, 'wSfxBRequest', 'engine B effect number (1-26), consumed by SfxB_Update'),
    (0xC7CA, 'wSfxAUnusedCA', 'cleared by SfxA_Init only'),
    (0xC7CB, 'wSfxRequest1', 'engine A single-channel request: bits 7-6 channel, bits 5-0 effect'),
    (0xC7CC, 'wSfxRequest2', 'second request slot, same format'),
    (0xC7CD, 'wSfxMultiRequest', 'engine A multi-channel effect number (1-47)'),
    (0xC7CE, 'wSfxDisable', 'nonzero: engines A and B and the PCM player do nothing'),
    (0xC81E, 'wSfxFreqDirty', 'temp: a note set the period, write NRx3/NRx4'),
    (0xC81F, 'wSfxCurId', 'temp: request being started'),
    (0xC820, 'wSfx1NR10', ''), (0xC821, 'wSfx1NR11', ''), (0xC822, 'wSfx1NR12', ''), (0xC823, 'wSfx1NR13', ''), (0xC824, 'wSfx1NR14', ''),
    (0xC825, 'wSfx2NR21', ''), (0xC826, 'wSfx2NR22', ''), (0xC827, 'wSfx2NR23', ''), (0xC828, 'wSfx2NR24', ''),
    (0xC829, 'wSfx3NR30', ''), (0xC82A, 'wSfx3NR31', ''), (0xC82B, 'wSfx3NR32', ''), (0xC82C, 'wSfx3NR33', ''), (0xC82D, 'wSfx3NR34', ''),
    (0xC82E, 'wSfx4NR41', ''), (0xC82F, 'wSfx4NR42', ''), (0xC830, 'wSfx4NR43', ''), (0xC831, 'wSfx4NR44', ''),
    (0xC832, 'wSfxPan', 'NR51 bits set by the effects; never read (SfxA_Update writes wMusicPan to NR51)'),
]


def ram_symbols():
    """addr -> name (every byte of the sound RAM gets a name; multi-byte fields use name+1 style)."""
    sym = {}
    defs = []   # (name, addr, comment)
    for a, n, c in GLOBALS:
        defs.append((n, a, c))
    for ch in range(4):
        base = 0xC602 + 0x30 * ch
        if ch == 0:
            defs.append(('wMusCh1', base, 'music channel structures, $30 bytes each'))
        for off, n, c in MUS_FIELDS:
            defs.append((f'wMusCh{ch+1}{n}', base + off, c if ch == 0 else ''))
    for ch in (1, 2, 3, 4):
        flds = SFXA_FIELDS[1 if ch == 2 else ch]
        for off, n in flds:
            defs.append((f'wSfx{ch}{n}', SFXA_BASE[ch] + off, ''))
    for ch, base in SFXB_BASE.items():
        for off, n in SFXB_FIELDS:
            defs.append((f'wSfxB{ch}{n}', base + off, ''))
    for n, a, c in defs:
        sym.setdefault(a, n)
    # bytes inside multi-byte fields -> name + k
    widths = {}
    srt = sorted(set(a for _, a, _ in defs))
    for i, a in enumerate(srt):
        nxt = srt[i + 1] if i + 1 < len(srt) else a + 1
        widths[a] = nxt - a
    full = dict(sym)
    for a, w in widths.items():
        if 1 < w <= 3:
            for k in range(1, w):
                full.setdefault(a + k, f'{sym[a]} + {k}')
    full.update(HW)
    full.update(HRAM)
    return full, defs


def ram_inc():
    _, defs = ram_symbols()
    out = ['; Sound RAM map (Pokemon Puzzle Challenge). Generated by tools/ppcgen.py.', '']
    seen = set()
    for n, a, c in sorted(defs, key=lambda d: (d[1], d[0])):
        if n in seen:
            continue
        seen.add(n)
        out.append(f'DEF {n:<24} EQU ${a:04X}' + (f'  ; {c}' if c else ''))
    out.append('')
    for a, n in sorted(HRAM.items()):
        out.append(f'DEF {n:<24} EQU ${a:04X}')
    out.append(f'DEF {"rROMB0":<24} EQU $2100  ; MBC5 ROM bank (low 8 bits)')
    return '\n'.join(out) + '\n'


def hw_inc():
    out = ['; Game Boy sound registers', '']
    for a, n in sorted(HW.items()):
        if a >= 0xFF00:
            out.append(f'DEF {n:<12} EQU ${a:04X}')
    return '\n'.join(out) + '\n'
