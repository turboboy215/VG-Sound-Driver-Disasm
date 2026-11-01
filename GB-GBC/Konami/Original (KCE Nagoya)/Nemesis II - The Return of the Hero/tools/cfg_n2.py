"""gen_asm3 config: Nemesis II - The Return of the Hero (E)"""
import re
import asmcommon as C

PREFIX = {0: '', 13: 'B13_', 14: 'B14_', 15: 'B15_'}

TRK = {0x80: 'TRK_ID', 0x81: 'TRK_PRIO', 0x82: 'TRK_PTR', 0x83: 'TRK_PTR + 1', 0x84: 'TRK_LEN',
       0x85: 'TRK_FLAGS', 0x86: 'TRK_FLAGS2', 0x87: 'TRK_LOOPCNT', 0x88: 'TRK_LOOP2CNT', 0x89: 'TRK_VIB',
       0x8A: 'TRK_TRANSP', 0x8B: 'TRK_ATTEN', 0x8C: 'TRK_VIBOFS', 0x8D: 'TRK_VIBOFS + 1',
       0x8E: 'TRK_VIBLOOPCNT', 0x8F: 'TRK_FLOW', 0x90: 'TRK_UNIT', 0x91: 'TRK_OCTAVE', 0x92: 'TRK_PERIOD',
       0x93: 'TRK_PERIOD + 1', 0x94: 'TRK_RAWLO', 0x95: 'TRK_RAWHI', 0x96: 'TRK_VOL', 0x97: 'TRK_DUTY',
       0x98: 'TRK_ENV', 0x99: 'TRK_GATE', 0x9A: 'TRK_RELTICK', 0x9B: 'TRK_VIBTIMER', 0x9C: 'TRK_VIBRELOAD',
       0x9D: 'TRK_CH3TIMER', 0x9E: 'TRK_CH3RELOAD', 0xA0: 'TRK_LEVEL', 0xA1: 'TRK_LOOPPTR',
       0xA2: 'TRK_LOOPPTR + 1', 0xA3: 'TRK_LOOP2PTR', 0xA4: 'TRK_LOOP2PTR + 1', 0xA5: 'TRK_RET',
       0xA6: 'TRK_RET + 1', 0xA7: 'TRK_SEGNO', 0xA8: 'TRK_SEGNO + 1', 0xA9: 'TRK_VIBPTR',
       0xAA: 'TRK_VIBPTR + 1', 0xAB: 'TRK_VIBIDX', 0xAC: 'TRK_VIBLOOPIDX', 0xAD: 'TRK_VIBDEPTH',
       0xAE: 'TRK_VIBDELAYUNITS', 0xAF: 'TRK_VIBDELAY', 0xB0: 'TRK_VIBDELAYRELOAD', 0xB2: 'TRK_DUTYSTEP',
       0xB3: 'TRK_VOICEDUTY', 0xB4: 'TRK_DUTYTICKS', 0xB5: 'TRK_DUTYRELOAD', 0xB6: 'TRK_PAN'}

RAM = [
    (0xC080, 'wTrkSfx1', 0x38), (0xC180, 'wTrkSfx2', 0x38), (0xC280, 'wTrkSfxN', 0x38),
    (0xC380, 'wTrkCh1', 0x38), (0xC480, 'wTrkCh2', 0x38), (0xC580, 'wTrkCh3', 0x38),
    (0xC680, 'wTrkDrm', 0x38),
    (0xC0BB, 'wTrackIdx', 1), (0xC0BC, 'wRegBase', 1), (0xC0BD, 'wTempo', 1), (0xC0BE, 'wTempoAcc', 1),
    (0xC0BF, 'wTempoPhase', 1), (0xC0C0, 'wTempoOn', 1), (0xC0C1, 'wTempoSkip', 1), (0xC0C3, 'wNR51', 1),
    (0xC0C4, 'wSweepVal', 1), (0xC0C5, 'wReqId', 1), (0xC0C6, 'wReqPrio', 1), (0xC0C7, 'wRegVal', 1),
    (0xC0C8, 'wRegIdx', 1), (0xC0C9, 'wMusicHold', 1), (0xC0CB, 'wFadeReq', 1), (0xC0CC, 'wFadeStep', 1),
    (0xC0CD, 'wFadeTimer', 1), (0xC0CE, 'wFadeLevel', 1), (0xC0CF, 'wReqRefused', 1), (0xC0D0, 'wHalfPhase', 1),
    (0xC0D3, 'wFade2Req', 1), (0xC0D4, 'wFade2Timer', 1), (0xC0D5, 'wFade2Level', 1),
    (0xC1B7, 'wShadow', 0x14),
    (0xC78D, 'wSndLock', 1), (0xC794, 'wPauseFlags', 1), (0xC7A4, 'wRomBank', 1), (0xC7C6, 'wRomBankSave', 1),
    (0xCC0E, 'wSndDisable', 1),
]

_trkequ = ['; per-track fields: track n lives at $C080 + n*$100, so H = $C0 + n and L = field']
for k, v in TRK.items():
    if '+' not in v: _trkequ.append(f'DEF {v} EQU ${k:02X}')

MACROS = """\
; ---------------------------------------------------------------- sound data macros
DEF C_ EQU 1
DEF C# EQU 2
DEF D_ EQU 3
DEF D# EQU 4
DEF E_ EQU 5
DEF F_ EQU 6
DEF F# EQU 7
DEF G_ EQU 8
DEF G# EQU 9
DEF A_ EQU 10
DEF A# EQU 11
DEF B_ EQU 12
DEF C_HI EQU 13

; sound header: priority, track mask, then one dw per set mask bit (low bit first)
MACRO SND_HEADER
	db \\1, \\2
ENDM
; $00-$DF: note. hi = pitch 1-13 (0 = rest), lo = length multiplier (x LEN_UNIT; 0 = (unit & 15) * 16)
MACRO NOTE
	db (\\1 << 4) | \\2
ENDM
MACRO REST
	db \\1
ENDM
MACRO DRUM
	db (\\1 << 4) | \\2
ENDM
; noise SFX track: whole byte -> NR43 (NR44 = $80), length = LEN_UNIT
MACRO NOISE
	db \\1
ENDM
; $E0 unit, vol|duty<<4, env|gate<<4 (tone tracks; on CH3: vol = level code, duty = wave #)
MACRO VOICE
	db $E0, \\1, (\\3 << 4) | \\2, (\\5 << 4) | \\4
ENDM
MACRO NVOICE
	db $E0, \\1, (\\2 << 4) | \\3
ENDM
MACRO DRUM_UNIT
	db $E0, \\1
ENDM
MACRO OCTAVE
	db $E0 | \\1
ENDM
MACRO LEN_UNIT
	db $E7, \\1
ENDM
MACRO RELEASE
	db $E8, (\\2 << 4) | \\1
ENDM
MACRO SWEEP
	db $E9, \\1
ENDM
MACRO TRANSPOSE_UP
	db $EA, $00 | \\1
ENDM
MACRO TRANSPOSE_DOWN
	db $EA, $10 | \\1
ENDM
; $EA 2n: no-op
MACRO EXT_NOP
	db $EA, $20 | \\1
ENDM
MACRO DUTY
	db $EA, $30 | \\1
ENDM
MACRO WAVE
	db $EA, $30 | \\1
ENDM
; $EA 4n: autopan on (n != 0) / off
MACRO AUTOPAN
	db $EA, $40 | \\1
ENDM
; $EB n, xy: vibrato table n (low nibble only), delay (x + 1) * unit ticks (x = 0: none), depth y (0 = 1)
MACRO VIBRATO
	db $EB, \\1, (\\2 << 4) | \\3
ENDM
; $EB n with n & 15 = 0: vibrato off
MACRO VIBRATO_OFF
	db $EB, \\1
ENDM
MACRO CMD_EC
	db $EC, \\1
ENDM
; $ED xy: duty step. Each note starts with duty \\1, the voice duty comes back after \\2 ticks; \\2 = 0: off
MACRO DUTY_STEP
	db $ED, (\\2 << 4) | \\1
ENDM
; $EE: tempo (the tempo accumulator is reset to it too)
MACRO TEMPO
	db $EE, \\1
ENDM
; $EF: TRK_PAN = raw NR51 bits (this track's bits are used)
MACRO PAN
	db $EF, \\1
ENDM
MACRO ATTEN
	db $F0 | \\1
ENDM
; flow: $FB/$FC are loop markers. The first one met marks the start, the next one (with a count) loops.
MACRO LOOP_START
	db $FB
ENDM
MACRO LOOP_END
	db $FB, \\1
ENDM
MACRO LOOP2_START
	db $FC
ENDM
MACRO LOOP2_END
	db $FC, \\1
ENDM
; $FD addr = call; the next $FD (no argument) returns
MACRO SND_CALL
	db $FD
	dw \\1
ENDM
MACRO SND_RET
	db $FD
ENDM
; $FE: first one marks, the next one jumps back to the mark (forever)
MACRO SND_SEGNO
	db $FE
ENDM
MACRO SND_LOOP
	db $FE
ENDM
MACRO SND_END
	db $FF
ENDM
; raw streams (first byte $E1): header unit, duty (low nibble), NR10 value; then frames
MACRO RAW_HEADER
	db $E1, \\1, \\2, \\3
ENDM
; frame: NRx2 = vol << 4 (no envelope), NRx3/NRx4 = period (bit 11 unused), for one unit
MACRO RAW_NOTE
	db (\\1 << 4) | HIGH(\\2), LOW(\\2)
ENDM
MACRO RAW_REST
	db $00
ENDM
; $EB in a raw stream sets the unit
MACRO RAW_UNIT
	db $EB, \\1
ENDM
; vibrato table: one byte per step: delay (ticks), negate flag, offset 0-7 (x depth)
MACRO VIB_STEP
	db (\\1 << 4) | (\\2 << 3) | \\3
ENDM
MACRO VIB_SEGNO
	db $FB
ENDM
MACRO VIB_REPEAT
	db $FE, \\1
ENDM
MACRO VIB_HOLD
	db $FF
ENDM
"""

HEADER = [
    '; ==========================================================================',
    '; Nemesis II - The Return of the Hero (E) - Konami sound driver (third GB version)',
    '; Byte-exact RGBDS disassembly of the driver code and all sound data.',
    ';   ROM0: rst $28, timer vector/ISR, bank helpers, PlaySound/StopAll/update ($09AE-$0C6C), CopyBytes',
    ';   banks 13, 14, 15: each holds a copy of the track code, its tables and its sounds',
    ';     (ids $01-$5D, $81-$96, $C1-$D9)',
    '; Build: rgbasm -Wall -o n2.o N2_SoundDriver.asm && rgblink -o n2.gb n2.o',
    '; ==========================================================================',
    '',
] + C.HW_EQU.splitlines() + [
    'DEF rTMA EQU $FF06',
    'DEF rTAC EQU $FF07',
    '',
] + C.ram_equ(RAM) + [
    'DEF rROMB EQU $2000 ; MBC1 bank select',
    'DEF SOUND_TABLE_M2 EQU $3FFE ; every sound bank has its sound table at $4000 (index from 1)',
    '',
] + _trkequ + [
    '',
    '; TRK_FLAGS',
    'DEF TF_AUTOPAN EQU 1',
    'DEF TF_VIBRATO EQU 2',
    'DEF TF_VIBNEG EQU 3',
    'DEF TF_DUTYSTEP EQU 4',
    'DEF TF_FORCE EQU 6',
    '; TRK_FLAGS2',
    'DEF TF2_RELEASED EQU 2',
    'DEF TF2_REST EQU 3',
    'DEF TF2_RAW EQU 4 ; 4 and 5: the stream starts with $E1',
    '; TRK_FLOW: bit 0/1 loop open, bit 2 in a call, bit 3 segno set',
    '',
] + MACROS.splitlines()

SEG = []
SEG += [
    (0, 0x0028, 0x002C, 'code', {'section': 'SECTION "rst28", ROM0[$0028]'}),
    (0, 0x0050, 0x0053, 'code', {'section': 'SECTION "Timer vector", ROM0[$0050]'}),
    (0, 0x00B3, 0x00CD, 'code', {'section': 'SECTION "Timer ISR", ROM0[$00B3]'}),
    (0, 0x0254, 0x0259, 'code', {'section': 'SECTION "LoadPtrIndexed0", ROM0[$0254]'}),
    (0, 0x0283, 0x0307, 'code', {'section': 'SECTION "PlaySoundFar", ROM0[$0283]'}),
    (0, 0x09AE, 0x0C6C, 'code', {'section': 'SECTION "Sound ROM0", ROM0[$09AE]'}),
    (0, 0x0D85, 0x0D8D, 'code', {'section': 'SECTION "CopyBytes0", ROM0[$0D85]'}),
]
def _bank(b, data0, code0, tabs, jts, regbase, code_end):
    out = [(b, 0x4000, data0 - 1, 'data', {'section': f'SECTION "Sound bank {b}", ROMX[$4000], BANK[{b}]'}),
           (b, data0, code0 - 1, 'code', None),
           (b, code0, tabs - 1, 'data', None)]
    pc = tabs
    for s, n in sorted(jts + [(regbase, -7)]):
        if n < 0:
            out.append((b, pc, s - 1, 'code', None)); out.append((b, s, s + 6, 'db', {})); pc = s + 7
        else:
            out.append((b, pc, s - 1, 'code', None)); out.append((b, s, s + 2 * n - 1, 'dw', None)); pc = s + 2 * n
    out.append((b, pc, code_end, 'code', None))
    out.append((b, code_end + 1, 0x7FFF, 'data', None))
    return out
# (bank, first code byte, first table byte after the helpers, first driver code byte, jump tables, regbase, last code byte)
SEG += _bank(13, 0x43C3, 0x43D7, 0x461A, [(0x490E, 5), (0x4A39, 9), (0x4A82, 5), (0x4B82, 7), (0x4FD0, 9)], 0x4F88, 0x503A)
SEG += _bank(14, 0x41D9, 0x41ED, 0x4437, [(0x4724, 5), (0x484F, 9), (0x4898, 5), (0x4998, 7), (0x4DE6, 9)], 0x4D9E, 0x4E50)
SEG += _bank(15, 0x41FD, 0x4211, 0x4443, [(0x4730, 5), (0x485B, 9), (0x48A4, 5), (0x49A4, 7), (0x4DD5, 9)], 0x4D8D, 0x4E3F)
SEGMENTS = SEG

BANKNAMES = {
    13: {
        0x43C3: 'CopyBytes', 0x43CC: 'LoadPtrIndexed', 0x43D2: 'JumpTableInline', 0x461A: 'PlayDrumSound',
        0x4641: 'StartSfxN', 0x4657: 'StartSfx1', 0x4672: 'StartTrack', 0x46C0: 'StopAll',
        0x46FD: 'FadeStep', 0x4710: 'FadeCount', 0x471D: 'FadeNextStep', 0x4793: 'TrackEntry',
        0x47FF: 'HalfRate', 0x482B: 'TrackTick', 0x4900: 'ReadCmdsNext', 0x4901: 'ReadCmds',
        0x4918: 'Cmd_Loop', 0x4942: 'Cmd_Loop2', 0x496F: 'Cmd_Call', 0x4996: 'Cmd_Segno',
        0x49B1: 'Cmd_End', 0x4A13: 'ReadCmdsLow', 0x4A4B: 'Cmd_LenUnit', 0x4A53: 'Cmd_Release',
        0x4A65: 'Cmd_Sweep', 0x4A78: 'Cmd_Ext', 0x4A8C: 'Ext_TransposeUp', 0x4A96: 'Ext_TransposeDown',
        0x4AA2: 'Ext_Nop', 0x4AA6: 'Ext_Duty', 0x4AB6: 'Ext_Autopan', 0x4ACA: 'Cmd_Vibrato',
        0x4B1E: 'Cmd_EC', 0x4B22: 'Cmd_DutyStep', 0x4B4C: 'Cmd_Tempo', 0x4B57: 'Cmd_Pan',
        0x4B7B: 'GetPanBits', 0x4B90: 'PanBits22', 0x4B9D: 'PanBits44', 0x4BAA: 'PanBits88',
        0x4BB7: 'PanBits11', 0x4BC4: 'AutoPan', 0x4BE0: 'Cmd_Octave', 0x4BF1: 'Cmd_Voice',
        0x4C50: 'Cmd_Atten', 0x4C86: 'NoiseNote', 0x4C93: 'Note', 0x4D6A: 'VibratoTick',
        0x4D78: 'VibratoStep', 0x4DF7: 'NoteFinish', 0x4E08: 'NoteVolume', 0x4E76: 'WritePeriod',
        0x4E98: 'WritePeriodBC', 0x4EB2: 'SavePtr', 0x4EB9: 'Rest', 0x4ECC: 'DrumNote',
        0x4EDA: 'WriteDuty', 0x4F08: 'IsBlocked', 0x4F23: 'WriteReg', 0x4F4C: 'Trigger',
        0x4F65: 'GetRegAddr', 0x4F7D: 'GetRegBase', 0x4F8F: 'RawReader', 0x4FB5: 'RawNext',
        0x4FE2: 'RawNoteBack', 0x4FE3: 'RawNote', 0x5020: 'RawRest',
    },
    14: {
        0x41D9: 'CopyBytes', 0x41E2: 'LoadPtrIndexed', 0x41E8: 'JumpTableInline', 0x4437: 'PlayDrumSound',
        0x445E: 'StartSfxN', 0x4474: 'StartSfx1', 0x448F: 'StartTrack', 0x44DD: 'StopAll',
        0x451A: 'FadeStep', 0x452D: 'FadeCount', 0x453A: 'FadeNextStep', 0x45B0: 'TrackEntry',
        0x4615: 'HalfRate', 0x4641: 'TrackTick', 0x4716: 'ReadCmdsNext', 0x4717: 'ReadCmds',
        0x472E: 'Cmd_Loop', 0x4758: 'Cmd_Loop2', 0x4785: 'Cmd_Call', 0x47AC: 'Cmd_Segno',
        0x47C7: 'Cmd_End', 0x4829: 'ReadCmdsLow', 0x4861: 'Cmd_LenUnit', 0x4869: 'Cmd_Release',
        0x487B: 'Cmd_Sweep', 0x488E: 'Cmd_Ext', 0x48A2: 'Ext_TransposeUp', 0x48AC: 'Ext_TransposeDown',
        0x48B8: 'Ext_Nop', 0x48BC: 'Ext_Duty', 0x48CC: 'Ext_Autopan', 0x48E0: 'Cmd_Vibrato',
        0x4934: 'Cmd_EC', 0x4938: 'Cmd_DutyStep', 0x4962: 'Cmd_Tempo', 0x496D: 'Cmd_Pan',
        0x4991: 'GetPanBits', 0x49A6: 'PanBits22', 0x49B3: 'PanBits44', 0x49C0: 'PanBits88',
        0x49CD: 'PanBits11', 0x49DA: 'AutoPan', 0x49F6: 'Cmd_Octave', 0x4A07: 'Cmd_Voice',
        0x4A66: 'Cmd_Atten', 0x4A9C: 'NoiseNote', 0x4AA9: 'Note', 0x4B80: 'VibratoTick',
        0x4B8E: 'VibratoStep', 0x4C0D: 'NoteFinish', 0x4C1E: 'NoteVolume', 0x4C8C: 'WritePeriod',
        0x4CAE: 'WritePeriodBC', 0x4CC8: 'SavePtr', 0x4CCF: 'Rest', 0x4CE2: 'DrumNote',
        0x4CF0: 'WriteDuty', 0x4D1E: 'IsBlocked', 0x4D39: 'WriteReg', 0x4D62: 'Trigger',
        0x4D7B: 'GetRegAddr', 0x4D93: 'GetRegBase', 0x4DA5: 'RawReader', 0x4DCB: 'RawNext',
        0x4DF8: 'RawNoteBack', 0x4DF9: 'RawNote', 0x4E36: 'RawRest',
    },
    15: {
        0x41FD: 'CopyBytes', 0x4206: 'LoadPtrIndexed', 0x420C: 'JumpTableInline', 0x4443: 'PlayDrumSound',
        0x446A: 'StartSfxN', 0x4480: 'StartSfx1', 0x449B: 'StartTrack', 0x44E9: 'StopAll',
        0x4526: 'FadeStep', 0x4539: 'FadeCount', 0x4546: 'FadeNextStep', 0x45BC: 'TrackEntry',
        0x4621: 'HalfRate', 0x464D: 'TrackTick', 0x4722: 'ReadCmdsNext', 0x4723: 'ReadCmds',
        0x473A: 'Cmd_Loop', 0x4764: 'Cmd_Loop2', 0x4791: 'Cmd_Call', 0x47B8: 'Cmd_Segno',
        0x47D3: 'Cmd_End', 0x4835: 'ReadCmdsLow', 0x486D: 'Cmd_LenUnit', 0x4875: 'Cmd_Release',
        0x4887: 'Cmd_Sweep', 0x489A: 'Cmd_Ext', 0x48AE: 'Ext_TransposeUp', 0x48B8: 'Ext_TransposeDown',
        0x48C4: 'Ext_Nop', 0x48C8: 'Ext_Duty', 0x48D8: 'Ext_Autopan', 0x48EC: 'Cmd_Vibrato',
        0x4940: 'Cmd_EC', 0x4944: 'Cmd_DutyStep', 0x496E: 'Cmd_Tempo', 0x4979: 'Cmd_Pan',
        0x499D: 'GetPanBits', 0x49B2: 'PanBits22', 0x49BF: 'PanBits44', 0x49CC: 'PanBits88',
        0x49D9: 'PanBits11', 0x49E6: 'AutoPan', 0x4A02: 'Cmd_Octave', 0x4A13: 'Cmd_Voice',
        0x4A72: 'Cmd_Atten', 0x4AA8: 'NoiseNote', 0x4AB5: 'Note', 0x4B8C: 'VibratoTick',
        0x4B9A: 'VibratoStep', 0x4C19: 'NoteFinish', 0x4C2A: 'NoteVolume', 0x4C7B: 'WritePeriod',
        0x4C9D: 'WritePeriodBC', 0x4CB7: 'SavePtr', 0x4CBE: 'Rest', 0x4CD1: 'DrumNote',
        0x4CDF: 'WriteDuty', 0x4D0D: 'IsBlocked', 0x4D28: 'WriteReg', 0x4D51: 'Trigger',
        0x4D6A: 'GetRegAddr', 0x4D82: 'GetRegBase', 0x4D94: 'RawReader', 0x4DBA: 'RawNext',
        0x4DE7: 'RawNoteBack', 0x4DE8: 'RawNote', 0x4E25: 'RawRest',
    },
}

NAMES = {
    (0, 0x0028): 'AddAToHL', (0, 0x0050): 'TimerVector', (0, 0x00B3): 'TimerISR',
    (0, 0x0254): 'LoadPtrIndexed0', (0, 0x0283): 'PlaySoundFar', (0, 0x02B5): 'SetBank1',
    (0, 0x02B8): 'SetBankA', (0, 0x02C2): 'SetBank2',
    (0, 0x09AE): 'StartMusicFade', (0, 0x09B2): 'PlaySound', (0, 0x0A0C): 'PlaySoundHeader',
    (0, 0x0A48): 'PlaySoundAbort', (0, 0x0A4D): 'StartCh1', (0, 0x0A68): 'StartCh2', (0, 0x0A8A): 'StartCh3',
    (0, 0x0A98): 'StartSfxN', (0, 0x0AAF): 'StartDrm', (0, 0x0ABD): 'StartSfx2', (0, 0x0ACB): 'StartSfx1',
    (0, 0x0AE7): 'StartTrack', (0, 0x0B3A): 'StopAll', (0, 0x0B76): 'SndPause', (0, 0x0B80): 'SndUnpause',
    (0, 0x0BD4): 'CopyRegs', (0, 0x0BDB): 'SndUpdate', (0, 0x0C1C): 'SndUpdateNext', (0, 0x0C2B): 'Fade2Tick',
    (0, 0x0C57): 'HalfPhaseTick', (0, 0x0D85): 'CopyBytes0',
}
for _i, _b in enumerate(range(3, 13)):
    NAMES[(0, 0x02C7 + 5 * _i)] = f'SetBank{_b}'
NAMES[(0, 0x02F9)] = 'SetBank13'; NAMES[(0, 0x02FE)] = 'SetBank14'; NAMES[(0, 0x0303)] = 'SetBank15'
for _b, _d in BANKNAMES.items():
    for _a, _n in _d.items(): NAMES[(_b, _a)] = PREFIX[_b] + _n

import kdata3 as _K
DATA_SPECIAL = {}
for _b, _B in _K.N2['banks'].items():
    _p = PREFIX[_b]
    NAMES[(_b, 0x4000)] = _p + 'SoundTable'
    NAMES[(_b, _B['drummap'])] = _p + 'DrumMap'
    NAMES[(_b, _B['period'])] = _p + 'PeriodTable'
    NAMES[(_b, _B['waves'])] = _p + 'WaveTable'
    NAMES[(_b, _B['vibtab'])] = _p + 'VibratoTable'
    NAMES[(_b, _B['regbase'])] = _p + 'RegBaseTable'
    _r = open(_K.N2['rom'], 'rb').read()
    _w = lambda a: _r[_b * 0x4000 + a - 0x4000] | _r[_b * 0x4000 + a - 0x3FFF] << 8
    _wv = sorted({_w(_B['waves'] + 2 * i) for i in range(_B['wavecount'])})
    for _i, _a in enumerate(_wv): NAMES[(_b, _a)] = f'{_p}WaveData{_i + 1}'
    _wend = _B['vibtab']
    _base = {13: 0x4310, 14: 0x4126, 15: 0x414A}[_b]
    for _o in (0, 7, 0x16, 0x1D, 0x2C, 0x33): NAMES[(_b, _base + _o)] = f'{_p}Orphan_{_base + _o:04X}'
    DATA_SPECIAL[_b] = {
        0x4000: (_B['count'] * 2, 'dw', lambda i, b=_b: f'${_K.N2["banks"][b]["idbase"] | (i + 1):02X}'),
        _B['drummap']: (_B['drumcount'], 'db', 16),
        _B['period']: (170, 'period', None),
        _B['waves']: (_B['wavecount'] * 2, 'dw', None),
        _wv[0]: (_wend - _wv[0], 'db', 16),
        _B['vibtab']: (_B['vibcount'] * 2, 'dw', lambda i: f'{i + 1}'),
    }

# ROM0 calls into the bank copies
XREF = {(0, 0x0BF3): 13, (0, 0x0C03): 15, (0, 0x0C13): 14}

BLOCKS = {
    (0, 0x0028): ['rst $28: HL += A.'],
    (0, 0x0050): ['Timer interrupt (TMA $80, TAC 16384 Hz -> 128 Hz). Interrupts are enabled at once.'],
    (0, 0x00B3): ['TimerISR: one driver update unless wSndLock bit 0 (update running) or bit 1',
                  '(PlaySoundFar running) is set.'],
    (0, 0x0283): ['PlaySoundFar: A = sound id. Ignored while wSndDisable bit 0 is set. Sets wSndLock',
                  'bit 1 around PlaySound and maps bank 2 afterwards if the caller was in bank 2,',
                  'else bank 1. The helpers below map bank n and record it in wRomBank.'],
    (0, 0x09AE): ['StartMusicFade: wFadeReq = A (the game writes wFadeReq directly instead).'],
    (0, 0x09B2): ['PlaySound: A = sound id, 0 = StopAll. $96 stops everything first, $56 is not',
                  'restarted while it plays on Sfx1. Bits 7-6 of the id pick the bank (0x/40: 13,',
                  '80: 14, C0: 15) whose sound table is read.'],
    (0, 0x0A0C): ["As in Belmont's Revenge, wReqRefused after Sfx1 and after Sfx2/SfxN aborts the",
                  'rest of the request and is never cleared by a new one.'],
    (0, 0x0A68): ['StartCh2 also clears the tempo state and wFadeReq.'],
    (0, 0x0AE7): ['StartTrack: a refused track leaves DE unchanged, so the next track of the mask',
                  'is started with the refused track\'s pointer; it also gets TRK_PAN = $FF. An',
                  'accepted track whose stream starts with $E1 is a raw stream (TF2_RAW).'],
    (0, 0x0B3A): ['StopAll: clear the 7 tracks ($38 bytes), the shadows and the globals, wNR51 =',
                  '$FF (not written), then SndPause (NR12/NR17/NR21/NR1C = 0).'],
    (0, 0x0B80): ['SndUnpause: copy the shadows back per active channel, then NR10 = 0.'],
    (0, 0x0BDB): ['SndUpdate: run each track in the bank of its sound id (id 0: bank 13). Then the',
                  'unused second fade (wFade2Req) and, unless paused, the half-rate phase.'],
    (14, 0x4437): ['PlayDrumSound: the drum track\'s PlaySound. Only Sfx1 (when the mask is 5) and',
                   'SfxN are started, from this bank\'s table, without wReqRefused.'],
    (14, 0x44DD): ['StopAll (bank copy): clears only Sfx1 and SfxN, then falls into FadeStep.'],
    (14, 0x451A): ['FadeStep: while wFadeReq is set, every $70 calls one step (wFadeLevel + 1, one',
                   'more step of attenuation on new music notes). Step 5 stops the drums, 7 CH3,',
                   '9 CH1/CH2 (NRx2 = 8 + trigger if their SFX is idle) and ends the fade.'],
    (14, 0x45B0): ['TrackEntry: called for every track on every update. Paused: nothing (bank 13: only',
                   'the track playing $5D). Music tracks: every call advances wTempoPhase; on every',
                   'fourth call wTempoAcc += wTempo, and a carry skips the next four music calls.',
                   'Then only one pair of music tracks runs per update (wHalfPhase 0: Ch1/Ch2,',
                   '1: Ch3/Drm; bank 15: 0: Drm/Ch2, 1: Ch3/Ch1), calling FadeStep first.'],
    (14, 0x4641): ['TrackTick: one tick for track wTrackIdx (H = its page).'],
    (14, 0x4717): ['ReadCmds: execute commands until a note/rest (or $FF end).'],
    (14, 0x472E): ['$FB: the first one marks the loop start, the next one (FB n) loops n times.',
                   '$FC: the same with the second loop level.'],
    (14, 0x4785): ['$FD addr: call; the next $FD (no argument) returns.'],
    (14, 0x47AC): ['$FE: the first one marks, the next one jumps back to the mark.'],
    (14, 0x47C7): ['$FF: end of track. When an SFX on CH1/CH2 ends while music uses the channel,',
                   'restore the music duty, its PAN bits and its period. CH3: NR30 = 0.'],
    (14, 0x48E0): ['$EB n xy: vibrato table n & 15 (0 = off, no second byte), delay (x + 1) * unit',
                   'ticks before it starts (x = 0: none), depth y multiplies the offsets.'],
    (14, 0x4938): ['$ED xy: duty step: notes start with duty y, the voice duty comes back after x',
                   'ticks (also on CH3, where it means a wave). ED 0y: off.'],
    (14, 0x496D): ['$EF: TRK_PAN = raw NR51 bits. On the drum track it skips one byte too many.'],
    (14, 0x4A66): ['$F0-$FA: attenuation. On the noise SFX track it ends the command reading without',
                   'saving the pointer, so the track would hang (not in the data).'],
    (14, 0x4AA9): ['Note: length = (lo nibble) * unit, lo = 0: (unit & 15) * 16; hi 0 = rest; drum',
                   'track plays a sound of this bank. Noise SFX: NR43 = byte, NR44 = $80.'],
    (14, 0x4B80): ['VibratoTick: wait TRK_VIBTIMER ticks, then step. Steps are one byte now.'],
    (14, 0x4C1E): ['NoteVolume: (vol - atten - wFadeLevel) << 4 on music tracks, vol - atten on SFX',
                   '(bank 15 still fades the SFX tracks too); CH3: level code as before.'],
    (14, 0x4DA5): ['RawReader: raw streams. $E1 unit duty sweep, then 2-byte frames (vol << 4 |',
                   'period high, period low) of one unit each, 00 = rest. $E9/$EA/$EF work as',
                   'usual, $EB sets the unit. $E7/$E8/$EC/$ED/$EE would jump to RawNoteBack without',
                   'popping HL (not in the data).'],
}
for _b, _a in ((13, 0x4640), (13, 0x47FA), (13, 0x4CF0), (13, 0x4E75), (14, 0x445D), (14, 0x4610),
               (14, 0x4B06), (15, 0x4469), (15, 0x461C), (15, 0x4B12)):
    BLOCKS[(_b, _a)] = ['(unreachable)']

COMMENTS = {}
EXTRA_SYM = {'all': {0x2000: 'rROMB', 0x3FFE: 'SOUND_TABLE_M2'}}


def imm8(b, pc, mn, ops):
    if mn == 'ld':
        m = re.match(r'l,\$([0-9A-F]{2})$', ops)
        if m and int(m.group(1), 16) in TRK: return 'l,' + TRK[int(m.group(1), 16)]
        if ops == 'h,$C3': return 'h,HIGH(wTrkCh1)'
        if ops == 'h,$C4': return 'h,HIGH(wTrkCh2)'
        if ops == 'h,$C2': return 'h,HIGH(wTrkSfxN)'
    if mn == 'add' and ops == 'a,$C0': return 'a,HIGH(wTrkSfx1)'
    return ops
