"""Generate Paperboy_SoundDriver.asm (RGBDS) from the ROM. Byte-exact.
usage: python3 gen_pb.py <rom> <outdir>
Writes <outdir>/Paperboy_SoundDriver.asm and <outdir>/samples/sample_XX.bin (+ bank data bins)."""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
if len(sys.argv) > 1: os.environ['PB_ROM'] = sys.argv[1]
from sm83 import decode
import pbparse
from pbparse import ROM, off, w, songs, samples, tone_stream, noise_stream

OUT = sys.argv[2] if len(sys.argv) > 2 else '.'

# ---------------------------------------------------------------- symbols
RAM = {
    0xC0A2: 'wCurBank', 0xC8D2: 'wMusicEnable', 0xC8D3: 'wSampleEnable', 0xC8D7: 'wSampleMute',
    0xD0A5: 'wCh1PeriodLo', 0xD0A6: 'wCh1PeriodHi', 0xD0A7: 'wCh2PeriodLo', 0xD0A8: 'wCh2PeriodHi',
    0xD0A9: 'wCh1Timer', 0xD0AA: 'wCh2Timer',
    0xD0AB: 'wCh1Ptr', 0xD0AC: 'wCh1Ptr+1', 0xD0AD: 'wCh2Ptr', 0xD0AE: 'wCh2Ptr+1',
    0xD0AF: 'wCh1Start', 0xD0B0: 'wCh1Start+1', 0xD0B1: 'wCh2Start', 0xD0B2: 'wCh2Start+1',
    0xD0B3: 'wMusicBank', 0xD0B4: 'wMusicDivider',
    0xD0B5: 'wCh4Ptr', 0xD0B6: 'wCh4Ptr+1', 0xD0B7: 'wCh4Start', 0xD0B8: 'wCh4Start+1', 0xD0B9: 'wCh4Timer',
    0xD0BB: 'wSampPtr', 0xD0BC: 'wSampPtr+1', 0xD0BF: 'wSampStart', 0xD0C0: 'wSampStart+1',
    0xD0C1: 'wSampEnd', 0xD0C2: 'wSampEnd+1', 0xD0C3: 'wSampBank', 0xD0C4: 'wSampPrio',
    0xD0C5: 'wSampSlot1', 0xD0CD: 'wSampSlot2',
    0x2000: 'MBC5_ROMB', 0x0025: 'ROM_0025', 0x0026: 'ROM_0026',
}
HW = {0x05: 'rTIMA', 0x06: 'rTMA', 0x07: 'rTAC', 0x10: 'rNR10', 0x11: 'rNR11', 0x12: 'rNR12', 0x13: 'rNR13',
      0x14: 'rNR14', 0x16: 'rNR21', 0x17: 'rNR22', 0x18: 'rNR23', 0x19: 'rNR24', 0x1A: 'rNR30', 0x1B: 'rNR31',
      0x1C: 'rNR32', 0x1D: 'rNR33', 0x1E: 'rNR34', 0x20: 'rNR41', 0x21: 'rNR42', 0x22: 'rNR43', 0x23: 'rNR44',
      0x24: 'rNR50', 0x25: 'rNR51', 0x26: 'rNR52', 0xFF: 'rIE'}
EXT = {0x1836: 'SubHLDE', 0x1848: 'CopyBytes', 0x18CD: 'FillBytes'}
IMM16 = {0xD0C5: 'wSampSlot1', 0xD0CD: 'wSampSlot2', 0xD0A5: 'wCh1PeriodLo', 0xD0A7: 'wCh2PeriodLo',
         0x34E4: 'SampleTable', 0x33D4: 'SongTable', 0xFF30: '_AUD3WAVERAM'}

LABELS = {
    0x3095: 'PlaySample', 0x30F4: 'SndInit', 0x3114: 'PlaySong', 0x3189: 'SndTimerISR',
    0x3318: 'SndStop', 0x332E: 'SndResume', 0x3335: 'PlaySong0F', 0x333B: 'SampSlotAdvance',
    0x3367: 'SampQueue', 0x337C: 'MusicRestartAll', 0x33AE: 'SampClearSlots', 0x33C3: 'SampClearWave',
    # locals
    0x30B1: '.checkPrio', 0x30BC: '.start', 0x30EF: '.done',
    0x31A9: '.ch1', 0x31E5: '.ch2', 0x3221: '.ch4', 0x3247: '.ch4Hit', 0x3252: '.ch4Next', 0x323A: '.ch4NotEnd',
    0x3260: '.samples', 0x3294: '.sampEnded', 0x32C0: '.resumeSlot2', 0x32D3: '.nextBlock',
    0x330D: '.exit', 0x335C: '.store', 0x3365: '.skip', 0x3375: '.copy', 0x337B: '.full',
}
COMMENTS = {
    0x0050: 'timer IRQ: interrupts re-enabled first, so VBlank/STAT can nest inside the sound ISR',
    0x3095: 'A = sample id (0-13), or $FF with HL -> an 8-byte slot (resume). Preserves all registers.',
    0x309D: 'HL = SampleTable + id*8',
    0x30B1: 'new sample plays only if its priority is strictly higher than the current one',
    0x30B7: 'otherwise park it in a background slot (dropped if both are busy)',
    0x30C2: 'entry byte 1 is skipped (always 0)',
    0x30C6: 'wSampPtr = start (the ISR adds 16 BEFORE copying: block 0 is never heard)',
    0x30E0: 'CH3 DAC off until the next timer tick copies the first block',
    0x30E7: 'NR32 = $20: 100 % volume',
    0x30F7: 'TIMA = 0 then $AC (the 0 write is dead)',
    0x30FF: 'TMA = $AC: 84 counts per overflow',
    0x3103: 'TAC = %100: 4096 Hz (8192 Hz in CGB double speed) -> 97.52 Hz IRQ',
    0x3114: 'A = song id (0-16). Entries are 16 bytes: ch1, ch2, ch4 pointers, bank, 9 bytes padding',
    0x3160: 'all three channel timers = 1: first notes load on the next music tick',
    0x316B: 'divider: music runs on every 3rd timer IRQ (32.5 Hz)',
    0x3170: 'NR10 = $08: sweep off',
    0x3174: 'NR12/NR22 = $80: volume 8, no envelope, for the whole song',
    0x317C: 'NR11/NR21 = $80: 50 % duty',
    0x3184: 'NR41 = 1 (length not enabled, so unused)',
    0x318D: 'music disabled -> samples only',
    0x31A3: 'music tick: map the music bank',
    0x31BD: 'CH1 event: period hi, period lo, duration (ticks, 0 = 256)',
    0x31BE: '$BB in the first byte of ANY channel restarts all three channels',
    0x31E1: 'trigger every note. Rest = $FF,$FF: period $7FF (inaudible) and length enable on -> channel off after 250 ms',
    0x3238: 'jr nz,+0: does nothing',
    0x323D: 'CH4 event: NR43 value, duration. $FF = rest (NR42 = 0)',
    0x3247: 'hit: NR42 = $79 (volume 7, decay step 1)',
    0x3263: 'samples disabled -> done',
    0x3267: 'background slots advance 16 bytes per tick like a playing sample',
    0x3281: 'next block = ptr + 16; it is checked against the end BEFORE use',
    0x3294: 'sample over: CH3 off, priority 0, then resume the higher-priority parked slot (slot 1 on ties)',
    0x32D3: 'bug: ld a,[$0026] reads ROM (=$00), not NR52; harmless because of the OR',
    0x32DA: 'bug: same with [$0025] -> NR51 = $FF',
    0x32E9: '16 bytes = 32 4-bit samples into wave RAM, DAC off while copying',
    0x32FD: 'NR33/NR34 = $5CB: 2097152/565 = 3711.8 Hz sample clock',
    0x3301: 'wSampleMute != 0: block copied but CH3 not retriggered (DAC stays on, channel off)',
    0x330D: 'restore the bank from the game\'s shadow copy',
    0x3318: 'IE timer bit off, CH1/CH2 retriggered at period $7FF, CH3/CH4 DACs off',
    0x333B: 'BC -> slot. bug: ld a,[bc] sets no flags, so the jr z tests the flags left by the caller',
    0x3357: 'slot reached its end: free it',
    0x3367: 'copy the 8-byte table entry at HL into the first free slot (slot 2 only if slot 1 is busy)',
    0x337C: 'reload all three stream pointers, timers = 1, and re-run the tick from CH1',
}
CODE_RANGE = (0x3095, 0x33D4)

def fmt_op(text, info, pc, l):
    rd = lambda a: ROM[a]
    op = ROM[pc]
    # ldh [$FFxx]
    if op in (0xE0, 0xF0):
        n = ROM[pc + 1]
        name = HW.get(n, f'$FF{n:02X}')
        return f'ldh [{name}], a' if op == 0xE0 else f'ldh a, [{name}]'
    if op in (0xEA, 0xFA):
        a = w(pc + 1)
        name = RAM.get(a, f'${a:04X}')
        return f'ld [{name}], a' if op == 0xEA else f'ld a, [{name}]'
    if info.get('kind') in ('call', 'jp', 'jr') and info.get('target') is not None:
        t = info['target']
        name = LABELS.get(t) or EXT.get(t) or f'${t:04X}'
        if name.startswith('.'):
            # local labels belong to the preceding global
            pass
        return text.replace(f'${t:04X}', name)
    if 'imm16' in info and info['imm16'] in IMM16:
        return text.replace(f'${info["imm16"]:04X}', IMM16[info['imm16']])
    return text

def owner(addr):
    g = None
    for a in sorted(LABELS):
        if a > addr: break
        if not LABELS[a].startswith('.'): g = LABELS[a]
    return g

def gen_code(lines, start, end):
    pc = start
    while pc < end:
        if pc in LABELS:
            lab = LABELS[pc]
            lines.append('')
            lines.append(f'{lab}:' if lab.startswith('.') else f'{lab}::')
        l, text, info = decode(lambda a: ROM[a], pc)
        t = fmt_op(text, info, pc, l)
        # local label references across globals need full name
        for a, lab in LABELS.items():
            if lab.startswith('.') and t.endswith(lab) and owner(a) != owner(pc):
                t = t[: -len(lab)] + owner(a) + lab
        c = COMMENTS.get(pc)
        raw = ' '.join(f'{ROM[pc+k]:02X}' for k in range(l))
        lines.append(f'\t{t:<34}; {pc:04X}: {raw}' + (f'  {c}' if c else ''))
        pc += l

NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
def note_name(period):
    f = 131072 / (2048 - (period & 0x7FF))
    n = 12 * math.log2(f / 440) + 69
    r = round(n); c = round((n - r) * 100)
    return f'{NOTE_NAMES[r % 12]}{r // 12 - 1}' + (f' {c:+d}c' if abs(c) > 5 else '')

def gen_music(lines):
    sl = songs()
    stream_names = {}
    for i, s in enumerate(sl):
        for k in ('ch1', 'ch2', 'ch4'):
            stream_names.setdefault(s[k], f'Song{i:02d}_{k.capitalize()}' if s[k] != 0x5A3D else 'SharedNoise')
    lines.append('\nSECTION "Music data", ROMX[$4000], BANK[$3B]\n')
    a = 0x4000; end = 0x5AB6
    kinds = {}
    for i, s in enumerate(sl):
        kinds[s['ch1']] = 'tone'; kinds[s['ch2']] = 'tone'; kinds[s['ch4']] = 'noise'
    while a < end:
        if a in stream_names:
            lines.append(f'\n{stream_names[a]}:')
            ev, e = (tone_stream if kinds[a] == 'tone' else noise_stream)(a)
            t = 0
            for x in ev:
                if x[0] == 'end':
                    lines.append(f'\tSONG_END{"":<26}; {x[1]:04X}  total {t} ticks'); continue
                if kinds[a] == 'tone':
                    if x[2] == 0xFFFF:
                        lines.append(f'\tREST {x[3]:<29}; {x[1]:04X}')
                    else:
                        lines.append(f'\tNOTE ${x[2]:03X}, {x[3]:<22}; {x[1]:04X}  {note_name(x[2])}')
                else:
                    if x[2] == 0xFF: lines.append(f'\tNREST {x[3]:<28}; {x[1]:04X}')
                    else: lines.append(f'\tNHIT ${x[2]:02X}, {x[3]:<23}; {x[1]:04X}')
                t += x[3] or 256
            a = e
        else:
            assert ROM[off(0x3B, a)] == 0, hex(a)
            lines.append(f'\tdb $00{"":<28}; {a:04X}  padding')
            a += 1

def gen_tables(lines):
    lines.append('\n; 17 songs, 16 bytes each: CH1, CH2, CH4 streams, bank, 9 unused bytes')
    lines.append('SongTable::')
    for i, s in enumerate(songs()):
        n = lambda p: 'SharedNoise' if p == 0x5A3D else None
        names = [f'Song{i:02d}_Ch1', f'Song{i:02d}_Ch2', n(s['ch4']) or f'Song{i:02d}_Ch4']
        lines.append(f'\tSONG {names[0]}, {names[1]}, {names[2]}{"":<4}; {i:2d}  {0x33D4+16*i:04X}')
    lines.append('\n; 14 samples, 8 bytes each: priority, 0, start, end, bank, 0')
    lines.append('SampleTable::')
    for i, s in enumerate(samples()):
        nb = len([k for k in range(1, 9999) if s['start'] + 16 * k < s['end']])
        lines.append(f'\tSAMPLE {s["prio"]}, Sample{i:02d}, Sample{i:02d}_End{"":<10}; {i:2d}  {0x34E4+8*i:04X}  '
                     f'bank ${s["bank"]:02X}, {s["end"]-s["start"]} bytes, {nb} blocks heard')

def gen_samples(lines):
    os.makedirs(os.path.join(OUT, 'samples'), exist_ok=True)
    sm = samples()
    for bank in (0x3C, 0x3D, 0x3E):
        inb = sorted([(s['start'], i, s) for i, s in enumerate(sm) if s['bank'] == bank])
        lines.append(f'\nSECTION "Samples bank ${bank:02X}", ROMX[$4000], BANK[${bank:02X}]\n')
        a = 0x4000
        for st, i, s in inb:
            assert st == a, (hex(st), hex(a))
            for j, t in enumerate(sm):
                if t['bank'] == bank and t['end'] == st: lines.append(f'Sample{j:02d}_End:')
            data = ROM[off(bank, s['start']):off(bank, s['end'])]
            fn = f'samples/sample_{i:02d}.bin'
            open(os.path.join(OUT, fn), 'wb').write(data)
            lines.append(f'Sample{i:02d}:{"":<4}; {st:04X}-{s["end"]-1:04X}  4-bit PCM, 2 samples per byte, high nibble first')
            lines.append(f'\tINCBIN "{fn}"')
            a = s['end']
        for j, t in enumerate(sm):
            if t['bank'] == bank and t['end'] == a: lines.append(f'Sample{j:02d}_End:')

HEADER = r'''; Paperboy (GBC) - sound driver
; ROM: "Paperboy (U) [C][!].gbc"  (CGB-only, MBC5, 1 MB, internal title PAPERBOY)
; Generated by tools/gen_pb.py, then left as is. Rebuilds byte-exact:
;   rgbasm -Wall -o pb.o Paperboy_SoundDriver.asm && rgblink -p 0x00 -o pb.gbc pb.o
; Ranges: 0:$0050-$0054, 0:$3095-$3553, $3B:$4000-$5AB5, $3C:$4000-$5545, $3D:$4000-$6568, $3E:$4000-$6697
;
; Everything runs from the timer interrupt. The game is in CGB double speed from boot,
; so TAC=4/TMA=$AC gives 8192/84 = 97.52 Hz. Every tick copies one 16-byte block of
; 4-bit sample data to wave RAM and retriggers CH3 at period $5CB (3711.8 Hz);
; every 3rd tick (32.5 Hz) is a music tick for CH1, CH2 and CH4.

; ---------------------------------------------------------------- hardware
DEF rTIMA EQU $FF05
DEF rTMA  EQU $FF06
DEF rTAC  EQU $FF07
DEF rNR10 EQU $FF10
DEF rNR11 EQU $FF11
DEF rNR12 EQU $FF12
DEF rNR13 EQU $FF13
DEF rNR14 EQU $FF14
DEF rNR21 EQU $FF16
DEF rNR22 EQU $FF17
DEF rNR23 EQU $FF18
DEF rNR24 EQU $FF19
DEF rNR30 EQU $FF1A
DEF rNR31 EQU $FF1B
DEF rNR32 EQU $FF1C
DEF rNR33 EQU $FF1D
DEF rNR34 EQU $FF1E
DEF rNR41 EQU $FF20
DEF rNR42 EQU $FF21
DEF rNR43 EQU $FF22
DEF rNR44 EQU $FF23
DEF rNR50 EQU $FF24
DEF rNR51 EQU $FF25
DEF rNR52 EQU $FF26
DEF rIE   EQU $FFFF
DEF _AUD3WAVERAM EQU $FF30

; ---------------------------------------------------------------- RAM
DEF wCurBank      EQU $C0A2   ; game's shadow of the ROM bank (restored at ISR exit)
DEF wMusicEnable  EQU $C8D2   ; 0 = skip music tick
DEF wSampleEnable EQU $C8D3   ; 0 = skip sample tick
DEF wSampleMute   EQU $C8D7   ; != 0: blocks still advance but CH3 is not retriggered
DEF wCh1PeriodLo  EQU $D0A5
DEF wCh1PeriodHi  EQU $D0A6
DEF wCh2PeriodLo  EQU $D0A7
DEF wCh2PeriodHi  EQU $D0A8
DEF wCh1Timer     EQU $D0A9
DEF wCh2Timer     EQU $D0AA
DEF wCh1Ptr       EQU $D0AB   ; word
DEF wCh2Ptr       EQU $D0AD   ; word
DEF wCh1Start     EQU $D0AF   ; word, loop point = stream start
DEF wCh2Start     EQU $D0B1   ; word
DEF wMusicBank    EQU $D0B3
DEF wMusicDivider EQU $D0B4   ; counts 3,2,1
DEF wCh4Ptr       EQU $D0B5   ; word
DEF wCh4Start     EQU $D0B7   ; word
DEF wCh4Timer     EQU $D0B9
DEF wSampPtr      EQU $D0BB   ; word, last block copied
DEF wSampStart    EQU $D0BF   ; word, written, never read
DEF wSampEnd      EQU $D0C1   ; word
DEF wSampBank     EQU $D0C3
DEF wSampPrio     EQU $D0C4   ; 0 = idle
DEF wSampSlot1    EQU $D0C5   ; 8 bytes, copy of a SampleTable entry (ptr advances)
DEF wSampSlot2    EQU $D0CD   ; 8 bytes
DEF MBC5_ROMB     EQU $2000
DEF ROM_0025      EQU $0025   ; read by mistake instead of rNR51
DEF ROM_0026      EQU $0026   ; read by mistake instead of rNR52

; ---------------------------------------------------------------- game routines used
DEF SubHLDE   EQU $1836       ; HL -= DE, carry if HL < DE (Z from the high byte only)
DEF CopyBytes EQU $1848       ; copy BC bytes HL -> DE
DEF FillBytes EQU $18CD       ; fill BC bytes at HL with A

; ---------------------------------------------------------------- data macros
MACRO NOTE      ; period (11 bit), duration in music ticks (0 = 256)
\tdb HIGH(\1), LOW(\1), \2
ENDM
MACRO REST      ; period $FFFF: retrigger at $7FF (ultrasonic)
\tdb $FF, $FF, \1
ENDM
MACRO NHIT      ; NR43 value, duration. NR42 = $79
\tdb \1, \2
ENDM
MACRO NREST     ; NR42 = 0
\tdb $FF, \1
ENDM
MACRO SONG_END  ; restarts ALL channels of the song
\tdb $BB
ENDM
MACRO SONG      ; ch1, ch2, ch4 (all in bank $3B)
\tdw \1, \2, \3
\tdb BANK(\1)
\tds 9, 0
ENDM
MACRO SAMPLE    ; priority, start label, end label
\tdb \1, 0
\tdw \2, \3
\tdb BANK(\2), 0
ENDM

SECTION "Timer vector", ROM0[$0050]
\tei                                ; 0050: FB  timer IRQ: interrupts re-enabled first, so VBlank/STAT can nest inside the sound ISR
\tcall SndTimerISR                  ; 0051: CD 89 31
\treti                              ; 0054: D9

SECTION "Sound driver", ROM0[$3095]'''.replace('\\t', '\t')

def main():
    lines = [HEADER]
    gen_code(lines, *CODE_RANGE)
    gen_tables(lines)
    gen_music(lines)
    gen_samples(lines)
    open(os.path.join(OUT, 'Paperboy_SoundDriver.asm'), 'w').write('\n'.join(lines) + '\n')

if __name__ == '__main__':
    main()
