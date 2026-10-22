#!/usr/bin/env python3
"""Generate FFL3_SoundDriver.asm (RGBDS) from 'Final Fantasy Legend III (U) [!].gb'.

usage: python tools/gen_ffl3.py <rom> <outdir>
Covers ROM0 $1F27-$1F44 (STAT ISR / far call) and bank $0F $4000-$6BAE (whole sound bank part).
"""
import sys, os, re
sys.path.insert(0, os.path.dirname(__file__))
from sm83 import decode

ROM = open(sys.argv[1], 'rb').read()
OUT = sys.argv[2] if len(sys.argv) > 2 else '.'
BANK = 0x0F
BB = BANK * 0x4000
def rb(a): return ROM[BB + a - 0x4000] if a >= 0x4000 else ROM[a]
def rw(a): return rb(a) | rb(a + 1) << 8

END = 0x6BAF                     # first byte after the sound data in bank $0F
NSONG, NSFX = 20, 65
LEN = [rb(0x41BE + i) for i in range(16)]
assert LEN == [144, 96, 72, 48, 36, 32, 24, 18, 16, 12, 9, 8, 6, 4, 3, 2]

# --------------------------------------------------------------------------- RAM
CHBASE = [0xCB02, 0xCB1A, 0xCB32, 0xCB4A]       # struct order: CH2, CH1, CH3, CH4
CHNAME = ['Ch2', 'Ch1', 'Ch3', 'Ch4']
FIELDS = [(0, 'LoopA'), (1, 'LoopB'), (2, 'SfxTimer'), (3, 'Stopped'), (4, 'Timer'), (5, 'Note'),
          (6, 'Octave'), (7, 'Ptr'), (9, 'Volume'), (10, 'Freq'), (12, 'PitchTimer'), (13, 'PitchStart'),
          (15, 'PitchCur'), (17, 'VolTimer'), (18, 'VolStart'), (20, 'VolCur'), (22, 'Duty'), (23, 'Pan')]
RAM = {0xCB00: 'wTempoAcc', 0xCB01: 'wTempo', 0xCB62: 'wSfxTonePtr', 0xCB64: 'wSfxNoisePtr',
       0xCB66: 'wSfxToneHeld', 0xCB67: 'wSfxNoiseHeld'}
RAMDOC = {}
for b, n in zip(CHBASE, CHNAME):
    for o, f in FIELDS:
        RAM[b + o] = 'w%s%s' % (n, f)
# two-byte fields: name the +1 as NAME+1
TWO = {'Ptr', 'Freq', 'PitchStart', 'PitchCur', 'VolStart', 'VolCur'}
HRAM = {0xFFBA: 'hSongRequest', 0xFFBB: 'hSongCurrent', 0xFFBC: 'hSfxRequest', 0xFFBD: 'hFxChannel',
        0xFFBE: 'hCh2TimerCopy', 0xFFBF: 'hCh1TimerCopy', 0xFFC0: 'hCh3TimerCopy', 0xFFC1: 'hCh4TimerCopy',
        0xFFC2: 'hWavePtr', 0xFFC4: 'hSfxToneCount', 0xFFC5: 'hSfxNoiseCount'}
HW = {0xFF10: 'rNR10', 0xFF11: 'rNR11', 0xFF12: 'rNR12', 0xFF13: 'rNR13', 0xFF14: 'rNR14',
      0xFF16: 'rNR21', 0xFF17: 'rNR22', 0xFF18: 'rNR23', 0xFF19: 'rNR24',
      0xFF1A: 'rNR30', 0xFF1B: 'rNR31', 0xFF1C: 'rNR32', 0xFF1D: 'rNR33', 0xFF1E: 'rNR34',
      0xFF20: 'rNR41', 0xFF21: 'rNR42', 0xFF22: 'rNR43', 0xFF23: 'rNR44',
      0xFF24: 'rNR50', 0xFF25: 'rNR51', 0xFF26: 'rNR52', 0xFF4A: 'rWY'}

def ramname(a):
    if a in RAM: return RAM[a]
    if a - 1 in RAM and any(RAM[a - 1].endswith(t) for t in TWO): return RAM[a - 1] + '+1'
    if a in HRAM: return HRAM[a]
    if a - 1 in HRAM and HRAM[a - 1] == 'hWavePtr': return 'hWavePtr+1'
    if a in HW: return HW[a]
    return None

# --------------------------------------------------------------------------- code labels
NAMES = {
    0x4000: 'SoundUpdate', 0x4003: 'SoundInit', 0x4006: 'SoundUpdate_Main', 0x402D: 'StartRequestedSong',
    0x4031: 'SoundReset', 0x4065: 'PlaySong', 0x40B1: 'ClearChannelState', 0x40B9: 'SilenceChannels',
    0x40DD: 'SfxTone_Release', 0x40FD: 'SfxNoise_Release', 0x41CE: 'MusicUpdate', 0x41F9: 'MusicTick',
    0x4260: 'MusicTick_Ch1', 0x42D3: 'MusicTick_Ch3', 0x4334: 'MusicTick_Ch4', 0x439B: 'RestartFx',
    0x43A4: 'Ch4_Command', 0x43AB: 'DispatchCommand', 0x43B6: 'Ch3_Command', 0x43C8: 'Ch1_Command',
    0x43DA: 'Ch2_Command', 0x43EA: 'OctaveCommand', 0x4408: 'SplitNoteByte', 0x4416: 'GetFreqPtr',
    0x44A8: 'Ch3_SetVolume', 0x44B0: 'Ch2_SetEnv', 0x44B5: 'Ch1_SetEnv', 0x44BA: 'Ch4_SetEnv',
    0x44BF: 'Ch2_SetPitchFx', 0x44C4: 'Ch1_SetPitchFx', 0x44C9: 'Ch3_SetPitchFx', 0x44CC: 'StorePointerArg',
    0x44D3: 'Ch2_SetLoopA', 0x44D9: 'Ch1_SetLoopA', 0x44DF: 'Ch3_SetLoopA', 0x44E5: 'Ch4_SetLoopA',
    0x44EB: 'Ch2_SetLoopB', 0x44F1: 'Ch1_SetLoopB', 0x44F7: 'Ch3_SetLoopB', 0x44FD: 'Ch4_SetLoopB',
    0x4503: 'Ch2_LoopA', 0x4508: 'Ch1_LoopA', 0x450D: 'Ch3_LoopA', 0x4512: 'Ch4_LoopA',
    0x4517: 'Ch2_LoopB', 0x451C: 'Ch1_LoopB', 0x4521: 'Ch3_LoopB', 0x4526: 'Ch4_LoopB',
    0x4529: 'LoopCommon', 0x452C: 'SkipPointerArg', 0x452F: 'Ch2_IfLoopA', 0x4534: 'Ch1_IfLoopA',
    0x4539: 'Ch3_IfLoopA', 0x453E: 'Ch4_IfLoopA', 0x4543: 'IfLoopACommon', 0x4548: 'Cmd_Jump',
    0x454E: 'Ch2_SetDuty', 0x4556: 'Ch1_SetDuty', 0x4565: 'Cmd_SetTempo', 0x456B: 'Ch3_LoadWave',
    0x458F: 'Ch2_Init', 0x459B: 'Ch2_SetPan', 0x45AC: 'Ch1_Init', 0x45B5: 'Ch1_SetPan',
    0x45CF: 'Ch3_Init', 0x45D8: 'Ch3_SetPan', 0x45E9: 'Ch4_SetPan', 0x4613: 'Cmd_IgnoreByte',
    0x4616: 'Cmd_Hang', 0x4625: 'Fx_Ch2', 0x467D: 'Fx_Ch1', 0x46DB: 'Fx_Ch3', 0x4718: 'Fx_Ch4',
    0x474B: 'FxNextEntry', 0x4759: 'PlaySfx', 0x478E: 'SfxUpdate', 0x47E0: 'SfxUpdate_Noise',
    # data
    0x4114: 'NoteFreqTable', 0x41BE: 'NoteLengthTable', 0x4420: 'OctaveDeltaTable',
    0x4428: 'CmdTable_Ch2', 0x4448: 'CmdTable_Ch1', 0x4468: 'CmdTable_Ch3', 0x4488: 'CmdTable_Ch4',
    0x4603: 'PanTable_Ch2', 0x4607: 'PanTable_Ch1', 0x460B: 'PanTable_Ch3', 0x460F: 'PanTable_Ch4',
    0x4619: 'NoiseNoteTable', 0x482F: 'SongTable', 0x66F2: 'SfxToneTable', 0x6774: 'SfxNoiseTable',
}
COMMENTS = {
    0x4000: 'entry vector (the game calls SoundUpdate_Main directly)',
    0x4003: 'entry vector: no caller found in the ROM; song 0 reaches the same code',
    0x400A: 'song changes wait until neither SFX channel is busy',
    0x4019: 'hSongRequest != hSongCurrent -> start it',
    0x401F: 'new SFX request?',
    0x402D: 'hSongCurrent = request; 0 = stop everything',
    0x4035: 'NR12/NR22 = vol 0 + env up (DAC on, silent); NR32 = $08 (output level 0)',
    0x4055: 'note: wCh4SfxTimer is NOT cleared here',
    0x4058: 'wTempo = 0 (no ticks until a song starts)',
    0x405B: 'clears hSongRequest..$FFC9',
    0x4066: 'ids 1-20 only; others just update hSongCurrent',
    0x4096: 'wTempoAcc = $FF, default tempo $3C (overridden by the song)',
    0x40B1: 'loopA = loopB = sfxTimer = stopped = 0, timer = 1',
    0x40E5: 'NR12 = 0: CH1 DAC off until the music plays its next note',
    0x40FD: 'NR42 = $08: vol 0, env up',
    0x41D4: 'tempo: wTempoAcc += wTempo each frame; on carry run TWO ticks',
    0x41DC: 'effects: one channel per frame (CH2, CH1, CH3+CH4)',
    0x420E: '$E0-$FF: octave / command',
    0x4212: '$FF = end of track',
    0x422A: 'A = length, E = note in low nibble',
    0x4235: '$C = tie (no retrigger), $D = rest',
    0x423B: 'freq = NoteFreqTable[octave + note*2]',
    0x4242: 'NR22 = 2nd byte of the envelope = first volume',
    0x4259: 'restart pitch fx, then volume fx',
    0x429D: 'SFX on CH1: stream advances, nothing is written',
    0x42CF: 'clear wSfxToneHeld: fx may run again',
    0x4311: 'tie: keep playing',
    0x4313: 'rest on CH3 = output level 0',
    0x4325: 'NR32 = channel volume; NR33/NR34 written without the trigger bit',
    0x4379: 'noise "pitch" = NR43 from NoiseNoteTable (octave unused)',
    0x43A4: 'CH4: every $E0-$FE byte is a command (low nibble)',
    0x43A7: 'handlers return to the stream-read loop',
    0x43EA: 'bit 3 clear: octave = n*24 (absolute); set: += OctaveDeltaTable[n&7]',
    0x4529: 'loop: --counter; != 0 -> jump, else skip the pointer',
    0x4543: 'if counter A == arg -> jump, else skip the pointer',
    0x4613: 'vestige of FFA\'s $EC "double-time" command: argument read and dropped',
    0x4616: 'undefined commands land here: infinite loop (freezes the game)',
    0x4618: 'orphan RET after the hang loop (also present in FFA)',
    0x462B: 'no effects while the timer copy is 0 (note started on the 2nd tick of a pair)',
    0x462F: 'no effects on rests',
    0x4650: 'pitch = base + signed offset (no trigger)',
    0x4670: 'volume step retriggers with the BASE frequency high byte',
    0x468D: 'held after an SFX until the next note',
    0x4751: 'entry: timer, value; timer 0 = jump to the following pointer',
    0x4759: 'A = SFX id (1-65), no range check, no priority',
    0x4765: 'pointer 0 = no part for that channel',
    0x47A5: 'duration 0 = end',
    0x47AC: '$EF ptr = loop to ptr while --count != 0',
    0x47BF: '$Fn = set loop count to n',
    0x47C9: 'tone frame: NR10..NR14',
}

MUSCOMMENTS = {
    0x4B9B: 'credits: the main theme runs 16 times (loop counter B)',
    0x4C0E: '16th pass falls through: the coda starts 18432 ticks = 7:34 in',
    0x4C11: '---- CODA (heard only after ~7.5 minutes): slows from tempo $68 to $44',
    0x4C63: 'one-shot: the song ends at 7:57',
    0x4C6B: 'credits: 16 passes', 0x4CD5: '-> coda', 0x4D2A: 'credits: 16 passes', 0x4DC2: '-> coda',
    0x4E13: 'credits: 32 passes (each 15 loop-A rounds)', 0x4E30: '-> drum coda',
}

def trace(entries):
    code = {}; todo = list(entries)
    while todo:
        pc = todo.pop()
        while pc not in code and 0x4000 <= pc < 0x8000:
            l, m, t, k = decode(ROM, BB + pc - 0x4000, pc)
            code[pc] = (l, m, t, k)
            if k in ('jmp', 'cjmp', 'call') and t is not None and t >= 0x4000: todo.append(t)
            if k in ('jmp', 'ret', 'jphl', 'bad'): break
            pc += l
    return code

CMDTABLES = [0x4428, 0x4448, 0x4468, 0x4488]
handlers = {rw(t + 2 * i) for t in CMDTABLES for i in range(16)}
CODE = trace([0x4000, 0x4003] + sorted(handlers))
assert max(CODE) < 0x482F
branch_targets = {v[2] for v in CODE.values() if v[3] in ('jmp', 'cjmp', 'call') and v[2] is not None}
# immediate loads of code addresses (pushed return addresses)
imm_code = set()
for pc, (l, m, t, k) in CODE.items():
    mm = re.match(r'ld hl, \$([0-9A-F]{4})$', m)
    if mm:
        v = int(mm.group(1), 16)
        if v in CODE: imm_code.add(v)

# --------------------------------------------------------------------------- music streams
SONGS = [[rw(0x482F + 8 * i + 2 * c) for c in range(4)] for i in range(NSONG)]
# per-channel arg counts for $F0-$FF (None = Cmd_Hang); CH4 uses the same table for $E0-$EF
ARGS = [[2, 2, 1, 2], [2, 2, 2, 2], [2, 2, 2, 2], [1, 1, 1, 1], [2, 2, 2, None], [1, 1, None, None],
        [1, 1, 1, 1], [1, None, None, None], [None, None, 2, None], [2, 2, 2, 2], [1, 1, 1, 1],
        [3, 3, 3, 3], [1, None, None, None], [None] * 4, [7, 6, 6, None], [0, 0, 0, 0]]
for ch, t in enumerate(CMDTABLES):          # cross-check against the jump tables
    for c in range(15):
        assert (rw(t + 2 * c) == 0x4616) == (ARGS[c][ch] is None), (ch, c)

def stream_instr(a, ch):
    b = rb(a)
    if b < 0xE0 or (ch < 3 and b < 0xF0): return 1
    n = ARGS[b & 15][ch]
    return None if n is None else 1 + n

def dyn_walk(start, ch, owner, labels, kinds):
    """Exact execution order (counters start at 0) -> owner map for bytes actually executed."""
    a = start; ca = cb = 0; seen = set()
    while True:
        st = (a, ca, cb)
        if st in seen: return
        seen.add(st)
        b = rb(a); n = stream_instr(a, ch)
        if n is None: return
        owner.setdefault(a, ch)
        c = b & 15
        if b < 0xE0 or (ch < 3 and b < 0xF0): a += 1; continue
        if c == 1: labels.add(rw(a + 1)); a = rw(a + 1); continue
        if c in (2, 9):
            labels.add(rw(a + 1))
            if c == 2: ca = (ca - 1) & 255; z = ca
            else: cb = (cb - 1) & 255; z = cb
            a = rw(a + 1) if z else a + 3; continue
        if c == 3: ca = rb(a + 1)
        if c == 10: cb = rb(a + 1)
        if c == 11:
            labels.add(rw(a + 2))
            a = rw(a + 2) if rb(a + 1) == ca else a + 4; continue
        if c == 15: return
        a += n

def static_walk(start, ch, owner, labels):
    todo = [start]; seen = set()
    while todo:
        a = todo.pop()
        while a not in seen:
            seen.add(a)
            n = stream_instr(a, ch)
            if n is None: break
            if a in owner and owner[a] != ch: break     # someone else's data (unreachable fall-through)
            owner.setdefault(a, ch)
            b = rb(a); c = b & 15
            if b < 0xE0 or (ch < 3 and b < 0xF0): a += 1; continue
            if c == 1: labels.add(rw(a + 1)); a = rw(a + 1); continue
            if c in (2, 9): labels.add(rw(a + 1)); todo.append(rw(a + 1))
            if c == 11: labels.add(rw(a + 2)); todo.append(rw(a + 2))
            if c == 15: break
            a += n

owner = {}; mlabels = set(); kinds = {}
for s in SONGS:
    for ch in range(4): dyn_walk(s[ch], ch, owner, mlabels, kinds)
for s in SONGS:
    for ch in range(4): static_walk(s[ch], ch, owner, mlabels)

# effect tables referenced from streams
volrefs, pitchrefs, waverefs = set(), set(), set()
for a, ch in owner.items():
    b = rb(a)
    if b < 0xF0 or (ch == 3 and b < 0xE0): continue
    c = b & 15
    if c == 0 and ch != 2: volrefs.add(rw(a + 1))
    if c == 4: pitchrefs.add(rw(a + 1))
    if c == 8: waverefs.add(rw(a + 1))
    if c == 14:
        if ch == 0: pitchrefs.add(rw(a + 2)); volrefs.add(rw(a + 4))
        if ch == 1: pitchrefs.add(rw(a + 1)); volrefs.add(rw(a + 3))
        if ch == 2: pitchrefs.add(rw(a + 1)); waverefs.add(rw(a + 4))
MUS_START = 0x48CF
MUS_END = min(volrefs | pitchrefs)                  # $65D7
VOL_END = min(pitchrefs)                            # $6663
WAVE_START = min(waverefs)                          # $66B2
assert MUS_START == 0x482F + 8 * NSONG and WAVE_START + 64 == 0x66F2
for a in range(MUS_START, MUS_END): assert a in owner or any(o < a < o + (stream_instr(o, owner[o]) or 1) for o in range(a - 8, a) if o in owner), hex(a)

# --------------------------------------------------------------------------- SFX
def sfx_walk(a, noise, own, labels):
    todo = [a]
    while todo:
        a = todo.pop()
        while a not in own:
            own[a] = noise
            d = rb(a)
            if d == 0: break
            if d == 0xEF: labels.add(rw(a + 1)); todo.append(rw(a + 1)); a += 3; continue
            if d >= 0xF0: a += 1; continue
            a += 3 if noise else 6
sfx_own = {}; sfx_labels = set()
SFXT = [rw(0x66F2 + 2 * i) for i in range(NSFX)]
SFXN = [rw(0x6774 + 2 * i) for i in range(NSFX)]
for p in SFXT:
    if p: sfx_walk(p, 0, sfx_own, sfx_labels)
for p in SFXN:
    if p: sfx_walk(p, 1, sfx_own, sfx_labels)
SFX_START = 0x6774 + 2 * NSFX
assert min(sfx_own) == SFX_START

# --------------------------------------------------------------------------- label naming
LABEL = dict(NAMES)
for i, s in enumerate(SONGS):
    for ch in range(4):
        LABEL.setdefault(s[ch], 'Song%02d_%s' % (i + 1, CHNAME[ch]))
for a in sorted(volrefs): LABEL.setdefault(a, 'VolEnv_%04X' % a)
for a in sorted(pitchrefs): LABEL.setdefault(a, 'PitchFx_%04X' % a)
for i, a in enumerate(sorted(waverefs)): LABEL.setdefault(a, 'Wave%d' % i)
for i in range(NSFX):
    if SFXT[i]: LABEL.setdefault(SFXT[i], 'Sfx%02d_Tone' % (i + 1))
    if SFXN[i]: LABEL.setdefault(SFXN[i], 'Sfx%02d_Noise' % (i + 1))
GLOBALS = sorted(LABEL)
# local labels: unnamed code branch targets, music branch targets, fx loop targets, sfx loop targets
LOCALS = set()
fx_targets = set()
_a = VOL_END
while _a < WAVE_START:
    if rb(_a) == 0: fx_targets.add(rw(_a + 1)); _a += 3
    else: _a += 2
for _a in range(MUS_END, VOL_END, 2): assert rb(_a) != 0
for a in branch_targets | imm_code | mlabels | sfx_labels | fx_targets:
    if a not in LABEL and a >= 0x4000: LOCALS.add(a)
import bisect
def parent(a):
    i = bisect.bisect_right(GLOBALS, a) - 1
    return GLOBALS[i]
def ref(a):
    if a in LABEL: return LABEL[a]
    if a in LOCALS: return '%s.l%04X' % (LABEL[parent(a)], a)
    raise KeyError('%04X' % a)

# --------------------------------------------------------------------------- emit
out = []
W = out.append

HEADER = r'''; =============================================================================
; Final Fantasy Legend III (U) [!].gb  (SaGa 3, Square 1993) - sound driver
; Bank $0F $4000-$6BAE + ROM0 caller $1F27-$1F44.  Generated by tools/gen_ffl3.py.
; Rebuilds byte-exact with RGBDS 0.9.x:
;   rgbasm -Wall -o ffl3snd.o FFL3_SoundDriver.asm
;   rgblink -o ffl3snd.gb ffl3snd.o ; then compare the two ranges (tools/cmp_ranges.py)
; =============================================================================

; ---------------------------------------------------------------- hardware
'''
W(HEADER)
for a, n in sorted(HW.items()): W('DEF %-8s EQU $%04X' % (n, a))
W('\n; ---------------------------------------------------------------- HRAM')
for a, n in sorted(HRAM.items()): W('DEF %-15s EQU $%04X' % (n, a))
W('''
; ---------------------------------------------------------------- WRAM
; Four channel structs of $18 bytes, in the driver's own order CH2, CH1, CH3, CH4.
;  +$00 LoopA      loop counter A          +$0A Freq (2)  current base period, hi has the trigger bit
;  +$01 LoopB      loop counter B                         (CH4: +$0A = NR43 copy)
;  +$02 SfxTimer   SFX frame timer (CH1/CH4) +$0C PitchTimer, +$0D PitchStart (2), +$0F PitchCur (2)
;  +$03 Stopped    $FF = track ended        +$11 VolTimer,   +$12 VolStart (2),   +$14 VolCur (2)
;  +$04 Timer      ticks left on this note  +$16 Duty       (CH1: NR11 copy for SFX restore)
;  +$05 Note       high nibble of the note  +$17 Pan        (CH1/CH4: NR51 bits for SFX restore)
;  +$06 Octave     octave*24 (byte offset into NoteFreqTable)
;  +$07 Ptr (2)    stream pointer           +$09 Volume     (CH3: NR32 value)
DEF wTempoAcc     EQU $CB00
DEF wTempo        EQU $CB01''')
for b, n in zip(CHBASE, CHNAME):
    for o, f in FIELDS:
        W('DEF %-17s EQU $%04X' % ('w%s%s' % (n, f), b + o))
W('''DEF wSfxTonePtr     EQU $CB62
DEF wSfxNoisePtr    EQU $CB64
DEF wSfxToneHeld    EQU $CB66   ; != 0: CH1 music effects held (set while/after a CH1 SFX)
DEF wSfxNoiseHeld   EQU $CB67   ; same for CH4

; ---------------------------------------------------------------- music macros
; note byte = pitch << 4 | length index; pitch $0-$B = C..B, $C = tie, $D = rest
DEF C_ EQU 0
DEF Cs_ EQU 1
DEF D_ EQU 2
DEF Ds_ EQU 3
DEF E_ EQU 4
DEF F_ EQU 5
DEF Fs_ EQU 6
DEF G_ EQU 7
DEF Gs_ EQU 8
DEF A_ EQU 9
DEF As_ EQU 10
DEF B_ EQU 11''')
for i, l in enumerate(LEN): W('DEF L%-3d EQU %d' % (l, i))
W(r'''
MACRO note      ; pitch, ticks
    db (\1) << 4 | L\2
ENDM
MACRO tie       ; ticks: extend the previous note (no retrigger)
    db $C0 | L\1
ENDM
MACRO rest      ; ticks
    db $D0 | L\1
ENDM
MACRO octave    ; n (0-7): absolute
    db $E0 | (\1)
ENDM
MACRO oct_up    ; n (1-4)
    db $E8 | ((\1) - 1)
ENDM
MACRO oct_down  ; n (1-4)
    db $EC | ((\1) - 1)
ENDM
MACRO env       ; volume envelope (CH1/CH2/CH4)
    db $F0
    dw \1
ENDM
MACRO volume    ; CH3 only: NR32 value
    db $F0, \1
ENDM
MACRO jump
    db $F1
    dw \1
ENDM
MACRO loop_a    ; --A != 0 -> jump
    db $F2
    dw \1
ENDM
MACRO set_a
    db $F3, \1
ENDM
MACRO pitch_fx  ; CH1-CH3
    db $F4
    dw \1
ENDM
MACRO duty      ; CH1/CH2: NRx1 value
    db $F5, \1
ENDM
MACRO pan       ; 0 off, 1 right, 2 left, 3 both
    db $F6, \1
ENDM
MACRO tempo     ; CH2 only
    db $F7, \1
ENDM
MACRO wave      ; CH3 only: load wave RAM and retrigger
    db $F8
    dw \1
ENDM
MACRO loop_b    ; --B != 0 -> jump
    db $F9
    dw \1
ENDM
MACRO set_b
    db $FA, \1
ENDM
MACRO if_a      ; A == n -> jump
    db $FB, \1
    dw \2
ENDM
MACRO ignored   ; CH2 only: argument dropped (FFA double-time vestige)
    db $FC, \1
ENDM
MACRO init_ch2  ; tempo, pitch_fx, env, duty, pan
    db $FE, \1
    dw \2, \3
    db \4, \5
ENDM
MACRO init_ch1  ; pitch_fx, env, duty, pan
    db $FE
    dw \1, \2
    db \3, \4
ENDM
MACRO init_ch3  ; pitch_fx, volume, wave, pan
    db $FE
    dw \1
    db \2
    dw \3
    db \4
ENDM
MACRO end_track
    db $FF
ENDM

; ---------------------------------------------------------------- effect / SFX macros
MACRO fx        ; effect ticks (1/3 frames), value (NRx2 or signed period offset)
    db \1, (\2) & $FF
ENDM
MACRO fx_jump
    db 0
    dw \1
ENDM
MACRO sfx_tone  ; frames, NR10, NR11, NR12, NR13, NR14
    db \1, \2, \3, \4, \5, \6
ENDM
MACRO sfx_noise ; frames, NR42, NR43
    db \1, \2, \3
ENDM
MACRO sfx_count ; n
    db $F0 | (\1)
ENDM
MACRO sfx_loop  ; --count != 0 -> jump
    db $EF
    dw \1
ENDM
MACRO sfx_end
    db 0
ENDM

; =============================================================================
SECTION "SoundCaller", ROM0[$1F27]
; STAT interrupt ($0048 -> $C0BC -> here). Runs the sound driver once per frame.
DEF BankPush EQU $38E1   ; A = bank: switch and push on the game's bank stack
DEF BankPop  EQU $38FC
DEF StatGameHook EQU $3549
DEF wStatHookOn EQU $CD3D
StatIsr::
    push af
    push bc
    push de
    push hl
    call SoundUpdateFar
    ld a, [wStatHookOn]
    or a
    call nz, StatGameHook
    pop hl
    pop de
    pop bc
    pop af
    reti
SoundUpdateFar::        ; also called directly at $11DC (with the LCD off)
    ld a, BANK(SoundUpdate)
    call BankPush
    call SoundUpdate_Main
    jp BankPop

; =============================================================================
SECTION "Sound", ROMX[$4000], BANK[$0F]
''')

def sym_operand(m, pc, kind, tgt):
    def rep(mm):
        v = int(mm.group(1), 16)
        txt = mm.group(0)
        if kind in ('jmp', 'cjmp', 'call') and v == tgt: return ref(v)
        if v >= 0xFF00 or 0xC000 <= v < 0xE000:
            n = ramname(v)
            if n: return n
            return txt
        if 0x4000 <= v < 0x8000 and (v in LABEL or v in LOCALS): return ref(v)
        return txt
    return re.sub(r'\$([0-9A-F]{4})', rep, m)

def emit_label(a):
    if a in LABEL:
        W(''); W('%s:' % LABEL[a])
    elif a in LOCALS:
        W('.l%04X:' % a)

def cm(a, s):
    c = COMMENTS.get(a)
    return ('    %-34s; %s' % (s, c)) if c else '    ' + s

# ---- code + inline data
def db_line(bs): return 'db ' + ', '.join('$%02X' % x for x in bs)
a = 0x4000
DATA = {0x4002: ('db', 1), 0x4005: ('db', 1), 0x4114: ('freq', 85), 0x41BE: ('db', 16), 0x4420: ('db', 8),
        0x4428: ('jt', 16), 0x4448: ('jt', 16), 0x4468: ('jt', 16), 0x4488: ('jt', 16),
        0x4603: ('db', 4), 0x4607: ('db', 4), 0x460B: ('db', 4), 0x460F: ('db', 4), 0x4618: ('db', 1),
        0x4619: ('db', 12)}
while a < 0x482F:
    emit_label(a)
    if a in DATA:
        k, n = DATA[a]
        if k == 'db':
            W(cm(a, db_line([rb(a + i) for i in range(n)]))); a += n
        elif k == 'jt':
            for i in range(n):
                W('    dw %-20s ; $%X' % (ref(rw(a + 2 * i)), 0xF0 + i if a != 0x4488 else i))
            a += 2 * n
        elif k == 'freq':
            W('    ; period | $8000 (trigger bit); 7 octaves of 12 + 1; index = octave*24 + note*2')
            for i in range(0, n, 12):
                W('    dw ' + ', '.join('$%04X' % rw(a + 2 * j) for j in range(i, min(n, i + 12))))
            a += 2 * n
        continue
    assert a in CODE, '%04X' % a
    l, m, t, k = CODE[a]
    s = sym_operand(m, a, k, t)
    s = s.replace('ldh [c], a', 'ldh [c], a').replace('ld [hli], a', 'ld [hli], a')
    W(cm(a, s))
    a += l

# ---- song table
W(''); W('SongTable:   ; 20 songs x (CH2, CH1, CH3, CH4)')
for i, s in enumerate(SONGS):
    W('    dw %s ; %d' % (', '.join(ref(x) for x in s), i + 1))

# ---- music streams
NOTEN = ['C_', 'Cs_', 'D_', 'Ds_', 'E_', 'F_', 'Fs_', 'G_', 'Gs_', 'A_', 'As_', 'B_']
a = MUS_START
while a < MUS_END:
    emit_label(a)
    ch = owner.get(a)
    if ch is None:
        W('    db $%02X ; (unreached)' % rb(a)); a += 1; continue
    b = rb(a)
    if b < 0xE0:
        p, l = b >> 4, LEN[b & 15]
        W('    ' + ('tie %d' % l if p == 12 else 'rest %d' % l if p == 13 else 'note %s, %d' % (NOTEN[p], l)))
        a += 1; continue
    if ch < 3 and b < 0xF0:
        if b & 8:
            d = b & 7
            W('    ' + ('oct_up %d' % (d + 1) if d < 4 else 'oct_down %d' % (d - 3)))
        else:
            W('    octave %d' % (b & 7))
        a += 1; continue
    c = b & 15; n = ARGS[c][ch]
    if b < 0xF0 or n is None:
        W('    db $%02X ; raw' % b); a += 1; continue
    A1 = rb(a + 1) if n >= 1 else None
    if c == 0: s = 'volume $%02X' % A1 if ch == 2 else 'env %s' % ref(rw(a + 1))
    elif c == 1: s = 'jump %s' % ref(rw(a + 1))
    elif c == 2: s = 'loop_a %s' % ref(rw(a + 1))
    elif c == 3: s = 'set_a %d' % A1
    elif c == 4: s = 'pitch_fx %s' % ref(rw(a + 1))
    elif c == 5: s = 'duty $%02X' % A1
    elif c == 6: s = 'pan %d' % A1
    elif c == 7: s = 'tempo $%02X' % A1
    elif c == 8: s = 'wave %s' % ref(rw(a + 1))
    elif c == 9: s = 'loop_b %s' % ref(rw(a + 1))
    elif c == 10: s = 'set_b %d' % A1
    elif c == 11: s = 'if_a %d, %s' % (A1, ref(rw(a + 2)))
    elif c == 12: s = 'ignored $%02X' % A1
    elif c == 14:
        if ch == 0: s = 'init_ch2 $%02X, %s, %s, $%02X, %d' % (A1, ref(rw(a + 2)), ref(rw(a + 4)), rb(a + 6), rb(a + 7))
        elif ch == 1: s = 'init_ch1 %s, %s, $%02X, %d' % (ref(rw(a + 1)), ref(rw(a + 3)), rb(a + 5), rb(a + 6))
        else: s = 'init_ch3 %s, $%02X, %s, %d' % (ref(rw(a + 1)), rb(a + 3), ref(rw(a + 4)), rb(a + 6))
    elif c == 15: s = 'end_track'
    W(('    %-34s; %s' % (s, MUSCOMMENTS[a])) if a in MUSCOMMENTS else '    ' + s); a += 1 + n

# ---- effect tables
W(''); W('; ---- volume envelopes: (fx ticks, NRx2) pairs; 99-tick steps simply run into the next table;')
W(';      ticks $FF = hold forever.  Effect ticks run every 3rd frame (19.9 Hz).')
a = MUS_END
while a < VOL_END:
    emit_label(a); W('    fx $%02X, $%02X' % (rb(a), rb(a + 1))); a += 2
W(''); W('; ---- pitch effects: (fx ticks, signed period offset) pairs, 0 = jump')
while a < WAVE_START:
    emit_label(a)
    if rb(a) == 0: W('    fx_jump %s' % ref(rw(a + 1))); a += 3
    else:
        o = rb(a + 1); W('    fx $%02X, %d' % (rb(a), o - 256 if o > 127 else o)); a += 2
W(''); W('; ---- CH3 waveforms (16 bytes each)')
while a < 0x66F2:
    emit_label(a); W('    ' + db_line([rb(a + i) for i in range(16)])); a += 16

# ---- SFX tables + streams
W(''); W('SfxToneTable:   ; 65 SFX: CH1 part (0 = none)')
for i in range(NSFX): W('    dw %s ; %d' % (ref(SFXT[i]) if SFXT[i] else '0', i + 1))
W(''); W('SfxNoiseTable:  ; CH4 part')
for i in range(NSFX): W('    dw %s ; %d' % (ref(SFXN[i]) if SFXN[i] else '0', i + 1))
a = SFX_START
while a < END:
    emit_label(a)
    if a not in sfx_own: W('    db $%02X ; (unreached)' % rb(a)); a += 1; continue
    noise = sfx_own[a]; d = rb(a)
    if d == 0: W('    sfx_end'); a += 1
    elif d == 0xEF: W('    sfx_loop %s' % ref(rw(a + 1))); a += 3
    elif d >= 0xF0: W('    sfx_count %d' % (d & 15)); a += 1
    elif noise: W('    sfx_noise %d, $%02X, $%02X' % (d, rb(a + 1), rb(a + 2))); a += 3
    else: W('    sfx_tone %d, ' % d + ', '.join('$%02X' % rb(a + 1 + i) for i in range(5))); a += 6
assert a == END
W('')
open(os.path.join(OUT, 'FFL3_SoundDriver.asm'), 'w', newline='\n').write('\n'.join(out))
print('wrote', os.path.join(OUT, 'FFL3_SoundDriver.asm'), len(out), 'lines')
