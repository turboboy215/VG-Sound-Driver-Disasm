"""Generate the RGBDS disassembly of Xantera's sound engine in
4x4 World Trophy (E) (M5).

usage: python gen_xan.py <ROM> [outdir]

Writes 4x4WorldTrophy_sound.asm, xantera_sound.inc and hardware.inc.
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sm83 import decode  # noqa: E402

ROM = open(sys.argv[1], 'rb').read()
OUT = sys.argv[2] if len(sys.argv) > 2 else '.'

MUS_BANK = 0x3C
CODE_START, CODE_END = 0x33FC, 0x385D

# --------------------------------------------------------------------------
# symbols
# --------------------------------------------------------------------------
HW = {
    0xFF10: 'rNR10', 0xFF11: 'rNR11', 0xFF12: 'rNR12', 0xFF13: 'rNR13', 0xFF14: 'rNR14',
    0xFF16: 'rNR21', 0xFF17: 'rNR22', 0xFF18: 'rNR23', 0xFF19: 'rNR24',
    0xFF1A: 'rNR30', 0xFF1B: 'rNR31', 0xFF1C: 'rNR32', 0xFF1D: 'rNR33', 0xFF1E: 'rNR34',
    0xFF20: 'rNR41', 0xFF21: 'rNR42', 0xFF22: 'rNR43', 0xFF23: 'rNR44',
    0xFF24: 'rNR50', 0xFF25: 'rNR51', 0xFF26: 'rNR52', 0xFF30: 'rWAVE',
    0x2000: 'rROMB0',
}

# RAM: (address, name, size, description)
RAM = [
    (0xC37B, 'wXMusPlaying', 1, 'nonzero while a song is running'),
    (0xC37C, 'wXMusTime', 2, 'song clock in frames, big-endian (hi, lo)'),
    (0xC37E, 'wXMusPtr', 2, 'next event, big-endian'),
    (0xC380, 'wXQueuedPtr', 2, 'song queued by XSnd_QueueSong, big-endian'),
    (0xC382, 'wXQueuedBank', 1, ''),
    (0xC383, 'wXSndFlags', 1, 'bits 0-3 SFX owns ch1-4, bit 4 engine on, bit 7 song queued'),
    (0xC384, 'wXSfxTimer1', 1, 'SFX repeat timers ch1, ch2, ch3, ch4'),
    (0xC385, 'wXSfxTimer2', 1, ''),
    (0xC386, 'wXSfxTimer3', 1, ''),
    (0xC387, 'wXSfxTimer4', 1, ''),
    (0xC388, 'wXSfxPtr1', 2, 'SFX record pointers ch1-4, big-endian (set by the game)'),
    (0xC38A, 'wXSfxPtr2', 2, 'never written by the game'),
    (0xC38C, 'wXSfxPtr3', 2, ''),
    (0xC38E, 'wXSfxPtr4', 2, ''),
    (0xC390, 'wXWaveCur', 2, 'wave last loaded by XSnd_LoadWave, big-endian'),
    (0xC392, 'wXWaveSave', 2, 'music wave to restore after a ch3 SFX, big-endian'),
    (0xC394, 'wXMusBank', 1, 'ROM bank of the song'),
    (0xC396, 'wXSavedBank', 1, 'game bank saved during XSnd_Update'),
    (0xC398, 'wXEngineRpm', 1, 'engine pitch input (written by the game)'),
    (0xC399, 'wXEngineRpmLast', 1, ''),
    (0xC39A, 'wXCurBank', 1, "game's shadow of the mapped ROM bank"),
]
RAMSYM = {}
for a, n, s, _ in RAM:
    RAMSYM[a] = n
    for k in range(1, s):
        RAMSYM[a + k] = '%s+%d' % (n, k)

GLOBALS = {
    0x33FC: 'XSnd_Init',
    0x341D: 'XSnd_LoadWave',
    0x343B: 'XSnd_PlaySong',
    0x3473: 'XSnd_StopMusic',
    0x348F: 'XSnd_QueueSong',
    0x34A0: 'XSnd_Update',
    0x3530: 'XSnd_SfxTimers',
    0x3580: 'XSnd_EvNote',
    0x366A: 'XSnd_EvCh3Off',
    0x3676: 'XSnd_EvCh3Vol',
    0x3685: 'XSnd_EvWave',
    0x36AA: 'XSnd_EvPitch',
    0x36F4: 'XSnd_EvEnd',
    0x3717: 'XSnd_SfxCh2Start',
    0x372E: 'XSnd_PlaySfxCh3',
    0x3749: 'XSnd_SfxCh3Start',
    0x3766: 'XSnd_SfxCh4Start',
    0x377D: 'XSnd_SfxCh1Start',
    0x3791: 'XSnd_SfxCopy5',
    0x3794: 'XSnd_SfxCopy4',
    0x37A0: 'XSnd_SfxCh1Stop',
    0x37AD: 'XSnd_SfxCh2Stop',
    0x37BE: 'XSnd_SfxCh3Stop',
    0x37CD: 'XSnd_SfxCh4Stop',
    0x37DE: 'XSnd_EngineUpdate',
    0x382A: 'XSnd_EngineOn',
    0x384D: 'XSnd_EngineOff',
}
LOCALS = {
    0x341D + 0x14: '.copy',
    0x34BA: '.savePtr', 0x34C1: '.check', 0x34D9: '.wait', 0x34EB: '.late',
    0x34EC: '.dispatch', 0x34FA: '.not1', 0x3504: '.not2', 0x350E: '.not3',
    0x3518: '.not4', 0x3522: '.end',
    0x346F: '.noSfx3', 0x348E: '.ret', 0x34A7: '.playing',
    0x3542: '.ch2', 0x3554: '.ch4', 0x3566: '.ch3', 0x357F: '.done',
    0x359A: '.ch1Free', 0x359E: '.ch1Play', 0x35BA: '.ch2', 0x35D1: '.ch2Free',
    0x35D5: '.ch2Play', 0x35ED: '.ch3', 0x3604: '.ch3Free', 0x3613: '.ch3Play',
    0x362C: '.ch4', 0x363F: '.ch4Free', 0x3643: '.ch4Play', 0x3652: '.find',
    0x365B: '.found',
    0x3675: '.ret', 0x3684: '.ret', 0x3694: '.load', 0x369C: '.find', 0x36A5: '.found',
    0x36BD: '.ch1', 0x36C6: '.notCh1', 0x36D6: '.ch2', 0x36DF: '.ch3', 0x36EB: '.ch3Write',
    0x3716: '.ret', 0x3736: '.notEngine', 0x3746: '.load',
    0x37E6: '.on', 0x37F4: '.changed', 0x3801: '.mul', 0x380A: '.gear',
    0x3810: '.find', 0x381B: '.found', 0x3821: '.write',
    0x384C: '.ret', 0x385C: '.ret',
}

# data labels (bank 0)
DATA_LABELS = {
    0x3343: 'XWaveTable', 0x3363: 'XWave_Engine', 0x33A3: 'XNoiseTable',
    0x385D: 'XEngineGearBase', 0x3865: 'XSfx_Engine',
}

# --------------------------------------------------------------------------
# SFX records
# --------------------------------------------------------------------------
SFX_LEN = {1: 6, 2: 5, 3: 6, 4: 5}
# (address, channel)  -- referenced records first, then the unreferenced ones
SFX = [
    (0x33CB, 1), (0x33D1, 1), (0x33D7, 2), (0x33DC, 2), (0x33E1, 3), (0x33E7, 3),
    (0x33ED, 4), (0x33F2, 4), (0x33F7, 4),
    (0x3865, 3), (0x386B, 4), (0x3870, 4), (0x3875, 1), (0x387B, 1), (0x3881, 1),
    (0x3887, 1), (0x388D, 1), (0x3893, 1), (0x3899, 1), (0x389F, 1), (0x38A5, 1),
    (0x38AB, 1), (0x38B1, 1), (0x38B7, 1), (0x38BD, 1), (0x38C3, 1), (0x38C9, 1),
    (0x38CF, 4), (0x38D4, 4), (0x38D9, 1), (0x38DF, 1), (0x38E5, 4), (0x38EA, 4),
    (0x38EF, 4), (0x38F4, 4), (0x38F9, 4), (0x38FE, 4), (0x3903, 4), (0x3908, 4),
    (0x390D, 1), (0x3913, 1),
]


def la(o):
    return '%02X:%04X' % (o // 0x4000, o if o < 0x4000 else 0x4000 + o % 0x4000)


def find_all(pat):
    r, i = [], ROM.find(pat)
    while i >= 0:
        r.append(i)
        i = ROM.find(pat, i + 1)
    return r


def sfx_callers(addr):
    """game code sites: ld hl,addr / ld a,h / ld [wXSfxPtrN],a"""
    out = []
    for o in find_all(bytes([0x21, addr & 0xFF, addr >> 8, 0x7C, 0xEA])):
        if ROM[o + 6] == 0xC3 and ROM[o + 5] in (0x88, 0x8A, 0x8C, 0x8E):
            if not (CODE_START <= o < CODE_END):
                out.append(la(o))
    return out


for a, ch in SFX:
    if a not in DATA_LABELS:
        DATA_LABELS[a] = 'XSfx%d_%04X' % (ch, a)

# --------------------------------------------------------------------------
# notes (period values as found in the song data)
# --------------------------------------------------------------------------
NAMES = ['C_', 'Cs', 'D_', 'Ds', 'E_', 'F_', 'Fs', 'G_', 'Gs', 'A_', 'As', 'B_']


def note_of(p):
    hz = 131072 / (2048 - p)
    n = round(12 * math.log2(hz / 440) + 69)
    return '%s%d' % (NAMES[n % 12], n // 12 - 1), n


def parse_song(addr):
    o = MUS_BANK * 0x4000 + addr - 0x4000
    ev = []
    while True:
        t = ROM[o] << 8 | ROM[o + 1]
        c = ROM[o + 2]
        ty, n = c >> 4, c & 15
        if ty == 1:
            ln = 3 if n < 2 else 2 if n == 2 else 1
        elif ty in (2, 3, 4):
            ln = 0
        elif ty == 5:
            ln = 2
        else:
            ev.append((o, t, c, b''))
            return ev, (o + 3) - MUS_BANK * 0x4000 + 0x4000
        ev.append((o, t, c, ROM[o + 3:o + 3 + ln]))
        o += 3 + ln


SONGS = [(0x4000, 'XSong_Title'), (0x661A, 'XSong_Jingle')]
song_ev = []
periods = {}
for a, n in SONGS:
    ev, end = parse_song(a)
    song_ev.append((a, n, ev, end))
    for o, t, c, dat in ev:
        if c in (0x10, 0x11):
            assert dat[1] < 8, 'duty bits in note data'
            p = dat[1] << 8 | dat[2]
        elif c == 0x12:
            assert dat[0] & 0x9F == dat[0] & 0x07
            p = (dat[0] & 7) << 8 | dat[1]
        else:
            continue
        if p:
            nm, mid = note_of(p)
            assert periods.get(nm, p) == p, ('two periods for', nm)
            periods[nm] = p
assert song_ev[0][3] == 0x661A, 'songs are contiguous'
MUS_END = song_ev[-1][3]
PER2NAME = {p: n for n, p in periods.items()}

# --------------------------------------------------------------------------
# hardware.inc
# --------------------------------------------------------------------------
hw = ['; Game Boy register names used by the Xantera sound disassembly', '']
for a in sorted(HW):
    hw.append('DEF %-7s EQU $%04X' % (HW[a], a))
open(os.path.join(OUT, 'hardware.inc'), 'w', newline='\n').write('\n'.join(hw) + '\n')

# --------------------------------------------------------------------------
# xantera_sound.inc
# --------------------------------------------------------------------------
inc = r'''; Xantera sound engine (4x4 World Trophy) - RAM, macros, constants
;
; Song events are time-stamped: every event starts with the absolute song
; time (frames since the song started) as a big-endian word, then a command
; byte whose high nibble is the event type and low nibble the channel or
; argument.

IF !DEF(XANTERA_SOUND_INC)
DEF XANTERA_SOUND_INC EQU 1

; ---- RAM -------------------------------------------------------------------
'''
for a, n, s, desc in RAM:
    inc += 'DEF %-16s EQU $%04X%s\n' % (n, a, ('  ; ' + desc) if desc else '')
inc += r'''
; wXSndFlags bits
DEF XSNDB_SFX1   EQU 0   ; SFX owns ch1 (music notes skipped)
DEF XSNDB_SFX2   EQU 1
DEF XSNDB_SFX3   EQU 2
DEF XSNDB_SFX4   EQU 3
DEF XSNDB_ENGINE EQU 4   ; engine voice owns ch3
DEF XSNDB_QUEUED EQU 7   ; wXQueuedPtr/Bank hold a song to start

; ---- helpers ---------------------------------------------------------------
MACRO bigw   ; big-endian word
    REPT _NARG
        db HIGH(\1), LOW(\1)
        SHIFT
    ENDR
ENDM

; ---- song events -----------------------------------------------------------
; time = absolute frame count from song start (0-65535)

MACRO _ev    ; time, command
    db HIGH(\1), LOW(\1), \2
ENDM

; $10 / $11: pulse note. env = NRx2. Byte 2 is NRx1|$80 and NRx4 bits 0-2,
; so the duty is always 50% unless bit 6 is set (never used).
MACRO ch1_note   ; time, env, period
    _ev \1, $10
    db \2, HIGH(\3), LOW(\3)
ENDM
MACRO ch2_note   ; time, env, period
    _ev \1, $11
    db \2, HIGH(\3), LOW(\3)
ENDM
; $12: wave note. vol = NR32 value ($20 100%, $40 50%, $60 25%)
MACRO ch3_note   ; time, vol, period
    _ev \1, $12
    db (\2) | HIGH(\3), LOW(\3)
ENDM
; $13: noise note. vol = NR42 high nibble, inst = XNoiseTable index
MACRO ch4_note   ; time, vol, inst
    _ev \1, $13
    db ((\2) << 4) | (\3)
ENDM
; $2x: ch3 off (NR30 = 0). Low nibble ignored; the data always uses $22.
MACRO ch3_off    ; time
    _ev \1, $22
ENDM
; $3n: NR32 = n << 4 (unused in the data)
MACRO ch3_vol    ; time, n
    _ev \1, $30 | (\2)
ENDM
; $4n: load wave n (16 bytes from XWaveTable + n*16)
MACRO wave       ; time, n
    _ev \1, $40 | (\2)
ENDM
; $5c: new period for channel c (0-2) without retrigger (unused in the data)
MACRO pitch      ; time, channel, period
    _ev \1, $50 | (\2)
    db LOW(\3), HIGH(\3)
ENDM
; any other command ends the song; the data uses $60
MACRO song_end   ; time
    _ev \1, $60
ENDM

; ---- instrument / SFX records ----------------------------------------------
MACRO noise_inst ; NR41, NR42 low nibble, NR43, NR44
    db \1, \2, \3, \4
ENDM
; first byte = repeat timer: 0/1 one-shot, n>1 retrigger every n-1 frames
MACRO sfx1  ; timer, NR10, NR11, NR12, NR13, NR14
    db \1, \2, \3, \4, \5, \6
ENDM
MACRO sfx2  ; timer, NR21, NR22, NR23, NR24
    db \1, \2, \3, \4, \5
ENDM
MACRO sfx3  ; timer, NR30, NR31, NR32, NR33, NR34
    db \1, \2, \3, \4, \5, \6
ENDM
MACRO sfx4  ; timer, NR41, NR42, NR43, NR44
    db \1, \2, \3, \4, \5
ENDM

; ---- note periods ----------------------------------------------------------
; The driver has no frequency table: songs store raw 11-bit periods. These
; are the values the data uses (one per note; C_2 = MIDI 36). Names give the
; pulse-channel pitch: the same period on ch3 sounds one octave lower.
'''
for nm, p in sorted(periods.items(), key=lambda x: x[1]):
    inc += 'DEF %-3s EQU %4d\n' % (nm, p)
inc += '\nENDC\n'
open(os.path.join(OUT, 'xantera_sound.inc'), 'w', newline='\n').write(inc)

# --------------------------------------------------------------------------
# code
# --------------------------------------------------------------------------
COMMENTS = {
    0x33FC: 'NR50 = $77',
    0x3402: 'NR51 = $FF',
    0x3405: 'NR52 = $8F',
    0x3408: 'wave 0',
    0x340E: 'NR32 = 100%',
    0x3414: 'clear flags and the four SFX timers',
    0x341D: 'remember the wave (big-endian)',
    0x3426: 'DAC off while writing wave RAM',
    0x343B: 'a = bank, de = song',
    0x343E: 'b = SFX bits | $80 ...',
    0x3446: '... ANDed into NR52: only bit 7 is writable, so no effect',
    0x3453: 'clock = 0',
    0x3458: 'playing = 1',
    0x345F: 'ch3 owned by an SFX?',
    0x3466: 'BUG: means wXWaveSave = XWaveTable, but stores',
    0x346A: 'h twice: wXWaveSave = $3333',
    0x3473: 'playing = 0',
    0x3478: 'same no-op NR52 write as above',
    0x3485: 'ch1/ch2/ch4 are left sounding',
    0x348F: 'de = song, b = bank',
    0x34A0: 'called from VBlank',
    0x34A7: 'save the game bank, map the song bank',
    0x34B0: 'padding no-op',
    0x34C1: 'bc = clock',
    0x34CD: 'event time hi - clock hi',
    0x34CF: 'already late: process',
    0x34D1: 'future: wait',
    0x34D3: 'lo byte',
    0x34D9: 'clock++ only on frames where nothing more is due',
    0x34EC: 'd = command',
    0x34F4: '$1c note',
    0x34FE: '$2x ch3 off',
    0x3508: '$3n ch3 volume',
    0x3512: '$4n wave',
    0x351C: '$5c pitch',
    0x3522: 'anything else ends the song',
    0x3530: 'called from VBlank after XSnd_Update',
    0x353B: 'reaching 1 retriggers the SFX (timer reloads)',
    0x3575: 'not while the engine owns ch3',
    0x358F: 'SFX still sounding? (NR52 status)',
    0x3595: 'yes: skip the 3 data bytes',
    0x359A: 'SFX finished: give ch1 back to music',
    0x359E: 'sweep off',
    0x35A7: 'unused (leftover from length handling)',
    0x35AB: 'NR11: duty from bit 6, bit 7 forced',
    0x35B2: 'trigger, no length',
    0x35F9: 'NR30 DAC still on?',
    0x3608: 'restore the music wave',
    0x3613: 'NR34 = 0, NR30 = on',
    0x361B: 'NR32 = high nibble',
    0x363A: 'BUG: the note is 1 byte, but 2 are skipped',
    0x3643: 'd = volume (high nibble)',
    0x364C: 'hl = XNoiseTable + 4 * index',
    0x365E: 'NR42 = volume | envelope',
    0x367D: 'NR32 = n << 4',
    0x3685: 'BUG: stores the index in the high byte of the',
    0x3689: 'saved wave pointer',
    0x3695: 'hl = XWaveTable + 16 * n',
    0x36B1: 'ch1 has no NR52 check here',
    0x36C1: 'no trigger',
    0x36F7: 'queue XSong_Title, then start it at once',
    0x36FF: 'always set: just queued',
    0x3721: 'wXSfxPtr2 is never set by the game',
    0x372E: 'hl = wave for the SFX',
    0x373A: 'save the music wave',
    0x3759: 'DAC off, NR34 = 0',
    0x37DE: 'called from the timer interrupt',
    0x37F5: 'rpm 0: period 0',
    0x37FC: 'hl = 32 * (rpm & $0F)',
    0x380D: 'de = XEngineGearBase[rpm >> 4] (no bound check)',
    0x3821: 'retrigger ch3 with the new period',
    0x3832: 'ch3 SFX = XSfx_Engine with XWave_Engine',
    0x3859: 'the music wave is not restored',
}


def sym_for(addr, ctx):
    if addr in HW:
        return HW[addr]
    if addr in RAMSYM:
        return RAMSYM[addr]
    if addr in GLOBALS:
        return GLOBALS[addr]
    if addr in DATA_LABELS:
        return DATA_LABELS[addr]
    return None


def owner(addr):
    best = None
    for a in sorted(GLOBALS):
        if a <= addr:
            best = a
    return best


# collect branch targets for auto locals
labels = {}
pc = CODE_START
insns = []
while pc < CODE_END:
    n, m, info = decode(ROM, pc, pc)
    insns.append((pc, n, m, info))
    t = info.get('target')
    if t is not None and info.get('kind') in ('jp', 'jr', 'call') and CODE_START <= t < CODE_END:
        if t not in GLOBALS and t not in LOCALS:
            LOCALS[t] = '.l%04X' % t
    pc += n
assert pc == CODE_END


def label_ref(t):
    if t in GLOBALS:
        return GLOBALS[t]
    return GLOBALS[owner(t)] + LOCALS[t]


def fix_operand(pc, m, info):
    t = info.get('target')
    if t is not None and info.get('kind') in ('jp', 'jr', 'call'):
        if t == 0x36F9:  # never
            pass
        return m.replace('$%04X' % t, label_ref(t))
    if 'addr' in info:
        a = info['addr']
        s = sym_for(a, pc)
        if s:
            return m.replace('$%04X' % a, s)
        return m
    if 'imm16' in info:
        v = info['imm16']
        s = None
        if v == 0x4000 and pc == 0x36F9:
            s = 'XSong_Title'
        elif v in HW or v in RAMSYM or v in DATA_LABELS:
            s = sym_for(v, pc)
        if s:
            return m.replace('$%04X' % v, s)
    if pc == 0x36F7:
        return 'ld b,BANK(XSong_Title)'
    return m


code = []
for pc, n, m, info in insns:
    if pc in GLOBALS:
        code.append('')
        code.append('%s::' % GLOBALS[pc] if pc in (0x33FC, 0x343B, 0x3473, 0x348F, 0x34A0, 0x3530,
                                                    0x372E, 0x3717, 0x3749, 0x3766, 0x377D,
                                                    0x37A0, 0x37AD, 0x37BE, 0x37CD, 0x37DE,
                                                    0x382A, 0x384D) else '%s:' % GLOBALS[pc])
    elif pc in LOCALS:
        code.append('%s:' % LOCALS[pc])
    txt = fix_operand(pc, m, info)
    c = COMMENTS.get(pc)
    if c:
        code.append('    %-28s ; %s' % (txt, c))
    else:
        code.append('    %s' % txt)

# --------------------------------------------------------------------------
# data emitters
# --------------------------------------------------------------------------


def hx(v):
    return '$%02X' % v


def emit_sfx(a, ch):
    b = ROM[a:a + SFX_LEN[ch]]
    callers = sfx_callers(a)
    cm = ('used by ' + ', '.join(callers)) if callers else 'unreferenced'
    if a == 0x3865:
        cm = 'engine voice: XSnd_EngineOn'
    return ['%s:' % DATA_LABELS[a],
            '    sfx%d %s   ; %s' % (ch, ', '.join(hx(x) for x in b), cm)]


body = []
body.append('SECTION "Xantera sound (bank 0)", ROM0[$3343]')
body.append('')
body.append('; 16-byte waves, selected by the $4n event (XWaveTable + n*16).')
body.append('; Only waves 0 (song start) and 2 (songs, engine) are used. n > 5')
body.append('; would read on into XNoiseTable and beyond.')
wave_desc = ['default (loaded at init and song start)', 'unused', 'songs ($42) and the engine voice',
             'unused (ramp)', 'unused (square)', 'unused (looks like random bytes)']
for i in range(6):
    a = 0x3343 + 16 * i
    if a in DATA_LABELS:
        body.append('%s:' % DATA_LABELS[a])
    body.append('XWave%d:  ; %s' % (i, wave_desc[i]))
    body.append('    db ' + ', '.join(hx(x) for x in ROM[a:a + 16]))
body.append('')
body.append('; ch4 instruments: NR41, NR42 envelope bits (ORed with the note volume),')
body.append('; NR43, NR44. Indexed by the low nibble of a $13 note (no bound check).')
body.append('XNoiseTable:')
for i in range(10):
    a = 0x33A3 + 4 * i
    body.append('    noise_inst %s   ; %d' % (', '.join(hx(x) for x in ROM[a:a + 4]), i))
body.append('')
body.append('; Older SFX set: nothing points here (includes the only ch2 records).')
a = 0x33CB
for sa, ch in SFX:
    if sa < 0x3400:
        assert sa == a
        body += emit_sfx(sa, ch)
        a += SFX_LEN[ch]
assert a == 0x33FC
body += code
body.append('')
body.append('; engine period base per rpm high nibble, big-endian')
body.append('XEngineGearBase:')
body.append('    bigw ' + ', '.join('$%04X' % (ROM[0x385D + 2 * i] << 8 | ROM[0x385E + 2 * i]) for i in range(4)))
body.append('')
body.append('; SFX records. The game sets wXSfxPtrN and calls XSnd_SfxChNStart.')
a = 0x3865
for sa, ch in SFX:
    if sa >= 0x3400:
        assert sa == a, hex(sa)
        body += emit_sfx(sa, ch)
        a += SFX_LEN[ch]
assert a == 0x3919
body.append('; $3919: game code')
body.append('')

# ---- songs
body.append('')
body.append('SECTION "Xantera music (bank $%02X)", ROMX[$4000], BANK[$%02X]' % (MUS_BANK, MUS_BANK))
desc = {
    'XSong_Title': 'title / menus; started from 00:3C75, 0B:4085 and 0B:7A84; '
                   'its end event restarts it',
    'XSong_Jingle': 'started from 0B:60E7; when it ends XSnd_EvEnd starts XSong_Title',
}
for a, name, ev, end in song_ev:
    body.append('')
    body.append('; %s' % desc[name])
    body.append('; %d events, %d frames' % (len(ev), ev[-1][1]))
    body.append('%s::' % name)
    for o, t, c, dat in ev:
        if c in (0x10, 0x11):
            p = dat[1] << 8 | dat[2]
            ps = PER2NAME.get(p, str(p))
            line = 'ch%d_note %d, %s, %s' % (c - 0x0F, t, hx(dat[0]), ps)
        elif c == 0x12:
            p = (dat[0] & 7) << 8 | dat[1]
            ps = PER2NAME.get(p, str(p))
            line = 'ch3_note %d, %s, %s' % (t, hx(dat[0] & 0xF0), ps)
        elif c == 0x13:
            line = 'ch4_note %d, %d, %d' % (t, dat[0] >> 4, dat[0] & 15)
        elif c == 0x22:
            line = 'ch3_off %d' % t
        elif c >> 4 == 3:
            line = 'ch3_vol %d, %d' % (t, c & 15)
        elif c >> 4 == 4:
            line = 'wave %d, %d' % (t, c & 15)
        elif c >> 4 == 5:
            line = 'pitch %d, %d, $%04X' % (t, c & 15, dat[0] | dat[1] << 8)
        elif c == 0x60:
            line = 'song_end %d' % t
        else:
            raise ValueError(hex(c))
        body.append('    ' + line)
body.append('; $%04X: unrelated data' % MUS_END)

head = r'''; Xantera sound engine - 4x4 World Trophy (E) (M5) [C][!].gbc
;
; Generated by tools/gen_xan.py. Assembles byte-identical with RGBDS 1.0.0:
;   bank 0  $3343-$3918  waves, noise table, driver, SFX records
;   bank $3C $4000-$%04X  two songs
;
; Hooks in the game (bank 0):
;   $01AF  call XSnd_Init                (boot)
;   $025F  call XSnd_Update              (VBlank)
;   $0262  call XSnd_SfxTimers           (VBlank)
;   $03D7  call XSnd_EngineUpdate        (timer interrupt)

INCLUDE "hardware.inc"
INCLUDE "xantera_sound.inc"

''' % (MUS_END - 1)
open(os.path.join(OUT, '4x4WorldTrophy_sound.asm'), 'w', newline='\n').write(head + '\n'.join(body) + '\n')
print('ok: music ends $%04X, %d note names' % (MUS_END, len(periods)))
