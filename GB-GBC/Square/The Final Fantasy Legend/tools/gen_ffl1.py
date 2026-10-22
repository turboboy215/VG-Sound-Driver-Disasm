#!/usr/bin/env python3
"""Generate FFL1_SoundDriver.asm (RGBDS) from 'Final Fantasy Legend, The (U) [!].gb'.

usage: python tools/gen_ffl1.py <rom> <outdir>
Covers ROM0 $06D0-$06E4 (LCD ISR / far call) and bank $07 $4000-$6DF9 (all sound code and data).
"""
import sys, os, re, bisect
sys.path.insert(0, os.path.dirname(__file__))
from sm83 import decode

ROM = open(sys.argv[1], 'rb').read()
OUT = sys.argv[2] if len(sys.argv) > 2 else '.'
BANK = 7
BB = BANK * 0x4000
def rb(a): return ROM[BB + a - 0x4000]
def rw(a): return rb(a) | rb(a + 1) << 8

END = 0x6DFA
NSONG, NSFX = 18, 36
LEN = [rb(0x4403 + i) for i in range(16)]
assert LEN == [96, 72, 48, 36, 32, 24, 18, 16, 12, 9, 8, 6, 4, 3, 2, 0x2C]

# ----------------------------------------------------------------------------- RAM
CHBASE = [0xCE00, 0xCE20, 0xCE40]
CHNAME = ['Ch1', 'Ch2', 'Ch3']
FIELDS = [(0x00, 'Flags'), (0x01, 'Timer'), (0x02, 'Ptr'), (0x04, 'Event'), (0x05, 'Octave'), (0x06, 'LoopCount'),
          (0x09, 'Freq'), (0x0B, 'Volume'), (0x0C, 'VolEnv'), (0x0D, 'VolEnvPos'), (0x0E, 'VolEnvTimer'),
          (0x0F, 'Pitch'), (0x10, 'PitchPos'), (0x11, 'PitchTimer'), (0x12, 'Duty'), (0x13, 'DutyPos'),
          (0x14, 'DutyTimer'), (0x15, 'Pan'), (0x16, 'PanPos'), (0x17, 'PanTimer'), (0x18, 'NRx1'),
          (0x19, 'NRx2'), (0x1A, 'NRx3'), (0x1B, 'NRx4'), (0x1C, 'PanByte')]
OFFS = {o: f for o, f in FIELDS}
OFFS[3] = 'Ptr+1'
RAM = {0xCEC0: 'wSavedTempo', 0xCEC1: 'wSavedSong', 0xCEC2: 'wTempoAcc', 0xCEC3: 'wSfxToneTimer',
       0xCEC4: 'wSfxNoiseTimer', 0xCEC5: 'wSfxToneCount', 0xCEC6: 'wSfxNoiseCount', 0xCEC7: 'wSfxNoiseOn',
       0xCE60: 'wSavedChannels'}
for b, n in zip(CHBASE, CHNAME):
    for o, f in FIELDS: RAM[b + o] = 'w%s%s' % (n, f)
TWO = ('Ptr', 'Freq')
HRAM = {0xFFE0: 'hSongRequest', 0xFFE1: 'hSongCurrent', 0xFFE2: 'hSpecialSong', 0xFFE3: 'hSpecialActive',
        0xFFE4: 'hSfxRequest', 0xFFE6: 'hEvent', 0xFFE7: 'hChannelBase', 0xFFE9: 'hChannel', 0xFFEA: 'hTempo',
        0xFFEB: 'hSfxTonePtr', 0xFFED: 'hSfxNoisePtr'}
HW = {0xFF10: 'rNR10', 0xFF11: 'rNR11', 0xFF12: 'rNR12', 0xFF13: 'rNR13', 0xFF14: 'rNR14',
      0xFF16: 'rNR21', 0xFF17: 'rNR22', 0xFF18: 'rNR23', 0xFF19: 'rNR24', 0xFF1A: 'rNR30',
      0xFF1B: 'rNR31', 0xFF1C: 'rNR32', 0xFF1D: 'rNR33', 0xFF1E: 'rNR34', 0xFF20: 'rNR41',
      0xFF21: 'rNR42', 0xFF22: 'rNR43', 0xFF23: 'rNR44', 0xFF24: 'rNR50', 0xFF25: 'rNR51', 0xFF26: 'rNR52'}
def ramname(a):
    for d in (0, 1):
        n = RAM.get(a - d)
        if n and (d == 0 or n.endswith(TWO)): return n + ('+1' if d else '')
        n = HRAM.get(a - d)
        if n and (d == 0 or n in ('hChannelBase', 'hSfxTonePtr', 'hSfxNoisePtr')): return n + ('+1' if d else '')
    return HW.get(a)

# ----------------------------------------------------------------------------- code
NAMES = {
    0x4000: 'SoundInit', 0x4003: 'SoundUpdate', 0x4006: 'SoundInit_Main', 0x4030: 'SoundUpdate_Main',
    0x4053: 'CopyWord', 0x4059: 'StartSong', 0x40CD: 'MusicTick', 0x40FC: 'ChannelOutput',
    0x4134: 'ProcessEvent', 0x418B: 'VolumeEnvStep', 0x425C: 'PitchFxStep', 0x42DF: 'DutyStep',
    0x4338: 'PanStep', 0x4381: 'ReadWordAtHLDE', 0x4386: 'ApplyPan', 0x43D9: 'IsChannelFree',
    0x44BC: 'StreamTick', 0x44D7: 'PopAllRet', 0x44DC: 'ChannelReadStream', 0x4546: 'Cmd_Octave',
    0x454D: 'Cmd_SetNRx1', 0x4555: 'Cmd_SetLoop', 0x455C: 'StoreChannelField', 0x4563: 'Cmd_Loop',
    0x457A: 'Cmd_IfLoopDone', 0x458E: 'Cmd_Jump', 0x45A4: 'DispatchCommand', 0x45B5: 'ChannelField',
    0x45C1: 'ReadStreamByte', 0x45D8: 'Cmd_Wave', 0x4608: 'Cmd_Instrument', 0x6A3D: 'CopyBytes',
    0x6A44: 'SpecialSongUpdate', 0x6AA8: 'SfxUpdate', 0x6AF0: 'SfxToneStep', 0x6B51: 'SfxNoiseStep',
    0x6BC0: 'WriteRegs',
    # data
    0x43EA: 'Ch3VolumeTable', 0x43FA: 'RegNRx3', 0x43FD: 'RegNRx2', 0x4400: 'RegNRx1', 0x4403: 'NoteLengthTable',
    0x4412: 'NoteFreqTable', 0x4528: 'CmdTable', 0x45A0: 'RegStop', 0x4629: 'InstrFieldTable',
    0x462F: 'SongTable', 0x6870: 'VolEnvTable', 0x68D3: 'PitchFxTable', 0x692F: 'PanTable', 0x69AE: 'DutyTable',
    0x69BD: 'WaveTable', 0x6BC7: 'SfxToneTable', 0x6C0F: 'SfxNoiseTable',
}
COMMENTS = {
    0x4000: 'called once at boot ($02D5)',
    0x4003: 'called every frame from the LCD ISR ($06DB)',
    0x400A: 'APU on; volumes, NR51 = 0',
    0x4021: 'all three channels stopped, tempo $FF',
    0x4034: 'special-song push/pop first',
    0x403A: 'wTempoAcc += hTempo; one tick per 60 -> tempo = ticks per second',
    0x4045: 'output first (uses the event read on the previous tick), then read the streams',
    0x404D: 'SFX run once per frame, outside the tempo loop',
    0x4059: 'hSongCurrent = id (0 = silence; no range check)',
    0x405E: 'clear all three channel structs',
    0x4068: 'SongTable + id*6',
    0x4085: 'Event = $0F (none), Timer = 1, VolEnvTimer = PitchTimer = DutyTimer = PanTimer = 1',
    0x40B6: 'Flags = 0. Note: hTempo is NOT reset (inherited from the previous song)',
    0x40C4: 'NR30 = $FF: wave DAC on',
    0x40D9: 'song request differs -> start it',
    0x40E0: 'NR10 = 0 every tick unless an SFX owns CH1',
    0x4104: 'Event low nibble -> note length (also for ties/rests)',
    0x410C: '$0F = "no event this tick" (so a C with length index 15 can never play)',
    0x4122: 'stopped channel: nothing',
    0x4139: '$D0-$DF tie: keep everything, effects not restarted',
    0x413E: '$C0-$CF rest: Freq = $FFFF',
    0x4143: 'pitch nibble * 2',
    0x4154: 'Octave * 24',
    0x416E: 'new note: restart the volume envelope',
    0x418B: 'rest: NRx2 = $08 (silent, DAC on), retrigger CH1/CH2',
    0x41DC: 'pair: timer, value; timer 0 = jump to the position in the next byte',
    0x41F6: 'level = (env level * Volume + 16) >> 4  (env 0 still gives level 1)',
    0x421C: 'CH3: level -> NR32 via Ch3VolumeTable',
    0x4246: 'skipped while an SFX owns CH1',
    0x4253: 'every envelope step retriggers CH1/CH2 (with the cached NRx4)',
    0x425C: 'new note: restart pitch effect',
    0x42A9: 'Freq + signed offset; NRx3/NRx4 written only when they change (no trigger)',
    0x42DF: 'new note: restart duty sequence',
    0x4320: 'byte: duty << 6 | ticks',
    0x4335: 'NRx1 = duty (CH3: lands in NR31)',
    0x4338: 'pan sequence is NOT restarted by notes',
    0x4367: 'byte: R << 7 | L << 6 | ticks',
    0x437B: 'event consumed',
    0x4392: 'CH1 pan is not touched while an SFX owns CH1',
    0x44E5: 'stopped?',
    0x44E8: '--Timer; read only when it reaches 0',
    0x44ED: '$00-$DF: note/rest/tie -> Event, handled on the next tick',
    0x44FD: '$E0 tempo, $E1-$EF volume',
    0x4513: '$FF: stop the channel, NRx2 = 0',
    0x4546: '$F0-$F4: octave 0-4',
    0x4555: '$F9-$FB: loop count 1-3',
    0x4563: '$FC: count 0 -> fall through; else --count and jump',
    0x457A: '$FD: count 0 -> jump (last pass), else skip',
    0x45D8: '$F8 n: load wave n (16 bytes at WaveTable + n*16) and retrigger CH3',
    0x4608: '$F7 kk iiiiii: select instrument sequence k (vol/pitch/duty/pan) = i, restart it',
    0x6A44: '$FFE2 = song to play "on top" (e.g. a fanfare); the current song resumes when it stops',
    0x6A5E: 'save all channel structs to wSavedChannels',
    0x6A84: 'resume when all three channels are stopped',
    0x6AA8: 'A = SFX id 1-36, no range check, no priority; always claims CH1 and CH4',
    0x6B02: '$En = set loop count n',
    0x6B10: '$Fx ptr = loop while --count != 0',
    0x6B2A: 'duration 0 = end',
    0x6B39: 'CH1 removed from NR51 until the music\'s pan sequence steps again',
    0x6B3F: 'restore NR11-NR14 from the CH1 struct copies',
    0x6B9B: 'noise frame: NR41 = 0, NR42, NR43, NR44 = $80',
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
CMDS = [rw(0x4528 + 2 * i) for i in range(15)]
CODE = trace([0x4000, 0x4003] + [c for c in CMDS if c])
branch_targets = {v[2] for v in CODE.values() if v[3] in ('jmp', 'cjmp', 'call') and v[2] is not None and v[2] >= 0x4000}

# ----------------------------------------------------------------------------- music streams
SONGS = [[rw(0x462F + 6 * i + 2 * c) for c in range(3)] for i in range(NSONG)]
def ssize(b):
    if b < 0xE0: return 1
    if b == 0xE0: return 2
    if b < 0xF0: return 1
    return [1, 1, 1, 1, 1, 2, None, 2, 2, 1, 1, 1, 3, 3, 3, 1][b & 15]
SOWN = set(); MLAB = set(); INSTR_USED = {0: set(), 1: set(), 2: set(), 3: set()}; WAVES_USED = set()
for s in SONGS:
    for st in s:
        todo = [st]
        while todo:
            a = todo.pop()
            while a not in SOWN:
                b = rb(a); n = ssize(b); assert n
                SOWN.add(a)
                if b == 0xF7: INSTR_USED[rb(a + 1) >> 6].add(rb(a + 1) & 63)
                if b == 0xF8: WAVES_USED.add(rb(a + 1))
                if b == 0xFE: MLAB.add(rw(a + 1)); a = rw(a + 1); continue
                if b in (0xFC, 0xFD): MLAB.add(rw(a + 1)); todo.append(rw(a + 1))
                if b == 0xFF: break
                a += n
MUS_START, MUS_END = 0x469B, 0x6870
assert min(SOWN) == MUS_START

# instrument tables
VOLP = [rw(0x6870 + 2 * i) for i in range(13)]
PITP = [rw(0x68D3 + 2 * i) for i in range(9)]
PANP = [rw(0x692F + 2 * i) for i in range(14)]
DUTP = [rw(0x69AE + 2 * i) for i in range(3)]
assert VOLP[0] == 0x688A and PITP[0] == 0x68E5 and PANP[0] == 0x694B and DUTP[0] == 0x69B4

# ----------------------------------------------------------------------------- SFX
SFXT = [rw(0x6BC7 + 2 * i) for i in range(NSFX)]
SFXN = [rw(0x6C0F + 2 * i) for i in range(NSFX)]
SFX_OWN = {}; SFX_LAB = set()
def sfx_walk(a, noise):
    todo = [a]
    while todo:
        a = todo.pop()
        while a not in SFX_OWN:
            d = rb(a); SFX_OWN[a] = noise
            if d & 0xF0 == 0xE0: a += 1; continue
            if d >= 0xF0: SFX_LAB.add(rw(a + 1)); todo.append(rw(a + 1)); a += 3; continue
            if d == 0: break
            a += 3 if noise else 6
for p in SFXT: sfx_walk(p, 0)
for p in SFXN: sfx_walk(p, 1)
SFX_START = 0x6C0F + 2 * NSFX
assert min(SFX_OWN) == SFX_START

# ----------------------------------------------------------------------------- labels
LABEL = dict(NAMES)
for i, s in enumerate(SONGS):
    for ch in range(3): LABEL.setdefault(s[ch], 'Song%02d_%s' % (i, CHNAME[ch]))
for i, p in enumerate(VOLP): LABEL.setdefault(p, 'VolEnv%02d' % i)
for i, p in enumerate(PITP): LABEL.setdefault(p, 'PitchFx%d' % i)
for i, p in enumerate(PANP): LABEL.setdefault(p, 'PanSeq%02d' % i)
for i, p in enumerate(DUTP): LABEL.setdefault(p, 'DutySeq%d' % i)
for i in range(8): LABEL.setdefault(0x69BD + 16 * i, 'Wave%d' % i)
for i in range(NSFX):
    LABEL.setdefault(SFXT[i], 'Sfx%02d_Tone' % (i + 1))
    LABEL.setdefault(SFXN[i], 'Sfx%02d_Noise' % (i + 1))
GLOBALS = sorted(LABEL)
LOCALS = {a for a in branch_targets | MLAB | SFX_LAB if a not in LABEL}
def parent(a): return GLOBALS[bisect.bisect_right(GLOBALS, a) - 1]
def ref(a):
    if a in LABEL: return LABEL[a]
    if a in LOCALS: return '%s.l%04X' % (LABEL[parent(a)], a)
    raise KeyError('%04X' % a)

# ----------------------------------------------------------------------------- emit
out = []; W = out.append
W(r'''; =============================================================================
; Final Fantasy Legend, The (U) [!].gb  (SaGa / Makai Toushi SaGa, Square 1989) - sound driver
; Bank $07 $4000-$6DF9 + ROM0 caller fragment $06D0-$06E4.  Generated by tools/gen_ffl1.py.
; Rebuilds byte-exact with RGBDS 0.9.x:
;   rgbasm -Wall -o ffl1snd.o FFL1_SoundDriver.asm
;   rgblink -o ffl1snd.gb ffl1snd.o ; python tools/cmp_ranges.py <rom> ffl1snd.gb
; =============================================================================
''')
for a, n in sorted(HW.items()): W('DEF %-8s EQU $%04X' % (n, a))
W('DEF rIF     EQU $FF0F\nDEF rLYC    EQU $FF45\n')
for a, n in sorted(HRAM.items()): W('DEF %-15s EQU $%04X' % (n, a))
W('''
; Three channel structs of $20 bytes: CH1 $CE00, CH2 $CE20, CH3 $CE40 (saved copy at $CE60 during a special song)
;  +$00 Flags      bit 7 = stopped, bit 0 = an SFX owns the channel (CH1 only)
;  +$01 Timer      ticks until the next stream read      +$02 Ptr (2)  stream pointer
;  +$04 Event      last note/rest/tie byte read, $0F = none   +$05 Octave (0-4)   +$06 LoopCount
;  +$09 Freq (2)   period of the current note, $FFFF = rest   +$0B Volume (1-15)
;  +$0C/$0D/$0E    volume envelope id / position / timer
;  +$0F/$10/$11    pitch effect id / position / timer
;  +$12/$13/$14    duty sequence id / position / timer
;  +$15/$16/$17    pan sequence id / position / timer
;  +$18-$1B        NRx1-NRx4 copies (NRx1 only set by $F5; used to restore CH1 after an SFX)
;  +$1C            last pan byte''')
for b, n in zip(CHBASE, CHNAME):
    for o, f in FIELDS: W('DEF %-19s EQU $%04X' % ('w%s%s' % (n, f), b + o))
for a in (0xCE60, 0xCEC0, 0xCEC1, 0xCEC2, 0xCEC3, 0xCEC4, 0xCEC5, 0xCEC6, 0xCEC7):
    W('DEF %-19s EQU $%04X' % (RAM[a], a))
W('''
; ---------------------------------------------------------------- music macros
; event byte = pitch << 4 | length index;  pitch 0-B = C..B, C = rest, D = tie
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
for i, l in enumerate(LEN[:15]): W('DEF L%-3d EQU %d' % (l, i))
W('DEF L44  EQU 15   ; index 15 reads NoteFreqTable\'s first byte ($2C); unused')
W(r'''DEF INS_VOL   EQU 0
DEF INS_PITCH EQU 1
DEF INS_DUTY  EQU 2
DEF INS_PAN   EQU 3
MACRO note      ; pitch, ticks
    db (\1) << 4 | L\2
ENDM
MACRO rest      ; ticks
    db $C0 | L\1
ENDM
MACRO tie       ; ticks
    db $D0 | L\1
ENDM
MACRO tempo     ; ticks per second (global)
    db $E0, \1
ENDM
MACRO volume    ; 1-15
    db $E0 | (\1)
ENDM
MACRO octave    ; 0-4
    db $F0 | (\1)
ENDM
MACRO set_nrx1  ; (unused by the songs)
    db $F5, \1
ENDM
MACRO instr     ; kind, id
    db $F7, (\1) << 6 | (\2)
ENDM
MACRO wave      ; n
    db $F8, \1
ENDM
MACRO loop_count ; 1-3
    db $F8 + (\1)
ENDM
MACRO loop      ; count 0 -> fall through, else --count and jump
    db $FC
    dw \1
ENDM
MACRO if_done   ; count 0 -> jump
    db $FD
    dw \1
ENDM
MACRO jump
    db $FE
    dw \1
ENDM
MACRO end_track
    db $FF
ENDM
; instrument sequences
MACRO env       ; ticks, level << 4 | NRx2 low nibble
    db \1, \2
ENDM
MACRO pfx       ; ticks, signed period offset
    db \1, (\2) & $FF
ENDM
MACRO seq_goto  ; position (byte offset from the sequence start)
    db 0, \1
ENDM
MACRO duty_step ; duty 0-3, ticks
    db (\1) << 6 | (\2)
ENDM
MACRO pan_step  ; right, left, ticks
    db (\1) << 7 | (\2) << 6 | (\3)
ENDM
; SFX
MACRO sfx_tone  ; frames, NR10, NR11, NR12, NR13, NR14
    db \1, \2, \3, \4, \5, \6
ENDM
MACRO sfx_noise ; frames, NR42, NR43
    db \1, \2, \3
ENDM
MACRO sfx_count ; n
    db $E0 | (\1)
ENDM
MACRO sfx_loop  ; --count != 0 -> jump
    db $F0
    dw \1
ENDM
MACRO sfx_end
    db 0
ENDM

; =============================================================================
SECTION "SoundCaller", ROM0[$06D0]
; LCD (LYC) interrupt handler fragment. rst $28 = switch ROM bank to A, returning the old one.
LcdIsrSound::
    call SoundUpdateFar
    push af
    xor a
    ldh [rLYC], a
    ldh [rIF], a
    pop af
    reti
SoundUpdateFar::                      ; continues at $06E5 with non-sound ISR work
    push af
    ld a, BANK(SoundUpdate)
    rst $28
    push af
    call SoundUpdate
    pop af
    rst $28

; =============================================================================
SECTION "Sound", ROMX[$4000], BANK[$07]''')

def sym(m, kind, tgt):
    def rep(mm):
        v = int(mm.group(1), 16)
        if kind in ('jmp', 'cjmp', 'call') and v == tgt: return ref(v)
        if v >= 0xFF00 or 0xC000 <= v < 0xE000:
            return ramname(v) or mm.group(0)
        if 0x4000 <= v < 0x8000 and (v in LABEL or v in LOCALS): return ref(v)
        return mm.group(0)
    s = re.sub(r'\$([0-9A-F]{4})', rep, m)
    # struct field offsets: ld hl, $00xx before call ChannelField
    return s
def emit_label(a):
    if a in LABEL: W(''); W('%s:' % LABEL[a])
    elif a in LOCALS: W('.l%04X:' % a)
def cm(a, s, extra=None):
    c = COMMENTS.get(a) or extra
    return ('    %-34s; %s' % (s, c)) if c else '    ' + s
def dbl(bs): return 'db ' + ', '.join('$%02X' % x for x in bs)

DATA = {0x43EA: ('db', 16), 0x43FA: ('db', 3), 0x43FD: ('db', 3), 0x4400: ('db', 3), 0x4403: ('db', 15),
        0x4412: ('freq', 85), 0x4528: ('jt', 15), 0x45A0: ('db', 4), 0x4629: ('db', 4), 0x462D: ('db', 2)}
DCOM = {0x43EA: 'level 0-15 -> NR32', 0x43FA: 'NR13, NR23, NR33', 0x43FD: 'NR12, NR22, NR32',
        0x4400: 'NR11, NR21, NR31', 0x4403: '15 lengths (index 15 falls into NoteFreqTable: 44)',
        0x45A0: '"end of track" volume registers (NR12, NR22, NR32, NR42)',
        0x4629: 'struct offsets for $F7 kinds 0-3: VolEnv, Pitch, Duty, Pan', 0x462D: 'unused bytes'}
a = 0x4000
while a < 0x462F:
    emit_label(a)
    if a in DATA:
        k, n = DATA[a]
        if k == 'db': W(cm(a, dbl([rb(a + i) for i in range(n)]), DCOM.get(a))); a += n
        elif k == 'jt':
            W('    ; $F0-$FE (the 16th slot would be the first bytes of Cmd_Octave; $FF never gets here)')
            for i in range(n):
                v = rw(a + 2 * i)
                W('    dw %-22s ; $%X%s' % (ref(v) if v else '$0000', 0xF0 + i, '  <- jumps to $0000 (reset vector): crash' if not v else ''))
            a += 2 * n
        else:
            W('    ; plain periods (no trigger bit); index = octave*24 + note*2')
            for i in range(0, n, 12): W('    dw ' + ', '.join('$%04X' % rw(a + 2 * j) for j in range(i, min(n, i + 12))))
            a += 2 * n
        continue
    assert a in CODE, '%04X' % a
    l, m, t, k = CODE[a]
    s = sym(m, k, t)
    extra = None
    mm = re.match(r'ld (hl|de), \$00([0-9A-F]{2})$', s)
    if mm and a + 3 in CODE and CODE[a + 3][1] == 'call $45B5':
        extra = '+$%s %s' % (mm.group(2), OFFS.get(int(mm.group(2), 16), '?'))
    W(cm(a, s, extra)); a += l

W(''); W('SongTable:   ; 18 songs x (CH1, CH2, CH3); song 0 = silence')
for i, s in enumerate(SONGS): W('    dw %s ; %d' % (', '.join(ref(x) for x in s), i))

NOTEN = ['C_', 'Cs_', 'D_', 'Ds_', 'E_', 'F_', 'Fs_', 'G_', 'Gs_', 'A_', 'As_', 'B_']
def L(i): return '44' if i == 15 else str(LEN[i])
a = MUS_START
while a < MUS_END:
    emit_label(a)
    assert a in SOWN, '%04X' % a
    b = rb(a)
    if b < 0xC0: s = 'note %s, %s' % (NOTEN[b >> 4], L(b & 15)); n = 1
    elif b < 0xD0: s = 'rest %s' % L(b & 15); n = 1
    elif b < 0xE0: s = 'tie %s' % L(b & 15); n = 1
    elif b == 0xE0: s = 'tempo %d' % rb(a + 1); n = 2
    elif b < 0xF0: s = 'volume %d' % (b & 15); n = 1
    elif b <= 0xF4: s = 'octave %d' % (b & 15); n = 1
    elif b == 0xF5: s = 'set_nrx1 $%02X' % rb(a + 1); n = 2
    elif b == 0xF7:
        v = rb(a + 1); s = 'instr %s, %d' % (['INS_VOL', 'INS_PITCH', 'INS_DUTY', 'INS_PAN'][v >> 6], v & 63); n = 2
    elif b == 0xF8: s = 'wave %d' % rb(a + 1); n = 2
    elif b <= 0xFB: s = 'loop_count %d' % (b - 0xF8); n = 1
    elif b == 0xFC: s = 'loop %s' % ref(rw(a + 1)); n = 3
    elif b == 0xFD: s = 'if_done %s' % ref(rw(a + 1)); n = 3
    elif b == 0xFE: s = 'jump %s' % ref(rw(a + 1)); n = 3
    elif b == 0xFF: s = 'end_track'; n = 1
    else: raise ValueError('%04X %02X' % (a, b))
    W('    ' + s); a += n

# ---- instrument tables
def ptrtable(base, ptrs, title):
    W(''); W('%s:   ; %s' % (LABEL[base], title))
    for p in ptrs: W('    dw %s' % ref(p))
W(''); W('; ---- instrument sequences (stepped once per music tick)')
ptrtable(0x6870, VOLP, 'volume envelopes: (ticks, level<<4 | NRx2 low) pairs')
a = 0x688A; starts = sorted(set(VOLP)) + [0x68D3]
for i, st in enumerate(starts[:-1]):
    emit_label(st); a = st; nxt = starts[i + 1]
    while a + 1 < nxt: W('    env $%02X, $%02X' % (rb(a), rb(a + 1))); a += 2
    if a < nxt: W('    db $%02X                            ; end byte: would only be read after a $FF hold expires (never in the songs)' % rb(a)); a += 1
ptrtable(0x68D3, PITP, 'pitch effects: (ticks, signed offset) pairs, 0 = goto')
a = 0x68E5
while a < 0x692F:
    emit_label(a)
    if rb(a) == 0: W('    seq_goto %d' % rb(a + 1)); a += 2
    else:
        o = rb(a + 1); W('    pfx %d, %d' % (rb(a), o - 256 if o > 127 else o)); a += 2
ptrtable(0x692F, PANP, 'pan sequences: right<<7 | left<<6 | ticks, 0 = goto')
a = 0x694B
while a < 0x69AE:
    emit_label(a)
    v = rb(a)
    if v == 0: W('    seq_goto %d' % rb(a + 1)); a += 2
    else: W('    pan_step %d, %d, %d' % (v >> 7, (v >> 6) & 1, v & 63)); a += 1
ptrtable(0x69AE, DUTP, 'duty sequences: duty<<6 | ticks, 0 = goto')
a = 0x69B4
while a < 0x69BD:
    emit_label(a)
    v = rb(a)
    if v == 0: W('    seq_goto %d' % rb(a + 1)); a += 2
    else: W('    duty_step %d, %d' % (v >> 6, v & 63)); a += 1
W(''); W('WaveTable:  ; 8 CH3 waveforms')
for i in range(8):
    a = 0x69BD + 16 * i
    if i: emit_label(a)
    W('    ' + dbl([rb(a + j) for j in range(16)]))
a = 0x6A3D
# ---- code 2
while a < 0x6BC7:
    emit_label(a)
    l, m, t, k = CODE[a]
    W(cm(a, sym(m, k, t))); a += l
W(''); W('SfxToneTable:   ; 36 SFX: CH1 part')
for p in SFXT: W('    dw %s' % ref(p))
W(''); W('SfxNoiseTable:  ; CH4 part')
for p in SFXN: W('    dw %s' % ref(p))
a = SFX_START
while a < END:
    emit_label(a)
    assert a in SFX_OWN, '%04X' % a
    nz = SFX_OWN[a]; d = rb(a)
    if d & 0xF0 == 0xE0: W('    sfx_count %d' % (d & 15)); a += 1
    elif d >= 0xF0:
        W('    sfx_loop %s' % ref(rw(a + 1)) if d == 0xF0 else '    db $%02X\n    dw %s' % (d, ref(rw(a + 1)))); a += 3
    elif d == 0: W('    sfx_end'); a += 1
    elif nz: W('    sfx_noise %d, $%02X, $%02X' % (d, rb(a + 1), rb(a + 2))); a += 3
    else: W('    sfx_tone %d, ' % d + ', '.join('$%02X' % rb(a + 1 + i) for i in range(5))); a += 6
assert a == END
W('')
open(os.path.join(OUT, 'FFL1_SoundDriver.asm'), 'w', newline='\n').write('\n'.join(out))
print('wrote', len(out), 'lines; instruments used:', {k: sorted(v) for k, v in INSTR_USED.items()}, 'waves', sorted(WAVES_USED))
