"""gen_asm config: Motocross Maniacs (E)"""
import re
import asmcommon as C

TRK = {0x80: 'TRK_ID', 0x81: 'TRK_PRIO', 0x82: 'TRK_PTR', 0x83: 'TRK_PTR + 1', 0x84: 'TRK_LEN',
       0x85: 'TRK_FLAGS', 0x86: 'TRK_LOOPCNT', 0x87: 'TRK_VIB', 0x88: 'TRK_TRANSP',
       0x89: 'TRK_ATTEN', 0x8A: 'TRK_VIBOFS', 0x8B: 'TRK_VIBOFS + 1', 0x8C: 'TRK_VIBLOOPCNT',
       0x8D: 'TRK_UNIT', 0x8E: 'TRK_OCTAVE', 0x8F: 'TRK_PERIOD', 0x90: 'TRK_PERIOD + 1',
       0x91: 'TRK_VOL', 0x92: 'TRK_DUTY', 0x93: 'TRK_ENV', 0x94: 'TRK_GATE', 0x95: 'TRK_RELTICK',
       0x96: 'TRK_VIBTIMER', 0x97: 'TRK_VIBRELOAD', 0x98: 'TRK_CH3TIMER', 0x99: 'TRK_CH3RELOAD',
       0x9B: 'TRK_LEVEL', 0x9C: 'TRK_SEGNO', 0x9D: 'TRK_SEGNO + 1', 0x9E: 'TRK_RET',
       0x9F: 'TRK_RET + 1', 0xA0: 'TRK_VIBPTR', 0xA1: 'TRK_VIBPTR + 1', 0xA2: 'TRK_VIBIDX',
       0xA3: 'TRK_VIBLOOPIDX'}

RAM = [
    (0xC008, 'wGameFlags', 1), (0xC00B, 'wIsrLock', 1), (0xC012, 'wPause', 1),
    (0xC018, 'wCourse', 1), (0xC01F, 'wPlayLock', 1),
    (0xC080, 'wTrkSfx1', 0x25), (0xC180, 'wTrkSfx2', 0x25), (0xC280, 'wTrkSfxN', 0x25),
    (0xC380, 'wTrkCh1', 0x25), (0xC480, 'wTrkCh2', 0x25), (0xC580, 'wTrkCh3', 0x25),
    (0xC680, 'wTrkDrm', 0x25),
    (0xC100, 'wTrackIdx', 1), (0xC101, 'wRegBase', 1), (0xC102, 'wTempo', 1),
    (0xC103, 'wTempoAcc', 1), (0xC104, 'wTempoSkip', 1), (0xC105, 'wQueuedSnd', 1),
    (0xC106, 'wNR51', 1), (0xC107, 'wSweepVal', 1), (0xC108, 'wReqId', 1),
    (0xC109, 'wReqPrio', 1), (0xC10A, 'wRegVal', 1), (0xC10B, 'wRegIdx', 1),
    (0xC10C, 'wMusicHold', 1), (0xC10D, 'wEnginePitch', 1),
    (0xC200, 'wShadow', 0x14),
]

_trkequ = ['; per-track fields: track n lives at $C080 + n*$100, so H = $C0 | n and L = field']
for k, v in TRK.items():
    if '+' not in v: _trkequ.append(f'DEF {v} EQU ${k:02X}')

HEADER = [
    '; ==========================================================================',
    '; Motocross Maniacs (E) - Konami sound driver (early GB version, 7-track variant)',
    '; Byte-exact RGBDS disassembly of the driver code and all sound data.',
    ';   ROM0 $0028 rst $28, $0038 rst $38, $0050 timer vector, $006D timer ISR,',
    ';        $0229/$0243-$0251/$02B2-$02D0 helpers, $0480-$04AC game pause toggle',
    ';   $6576-$7FFF driver code, tables, sound data, course tempo routine',
    '; Build: rgbasm -Wall -o mm.o MM_SoundDriver.asm && rgblink -o mm.gb mm.o',
    '; ==========================================================================',
    '',
] + C.HW_EQU.splitlines() + [''] + C.ram_equ(RAM) + [''] + _trkequ + [
    '',
    '; track flags (TRK_FLAGS)',
    'DEF TF_RELEASED EQU 0',
    'DEF TF_VIBNEG EQU 3',
    'DEF TF_FORCE EQU 6',
    'DEF TF_REST EQU 7',
    '',
] + C.MACROS.splitlines()

SEGMENTS = [
    (0x0028, 0x002C, 'code', {'section': 'SECTION "rst28", ROM0[$0028]'}),
    (0x0038, 0x003A, 'code', {'section': 'SECTION "rst38", ROM0[$0038]'}),
    (0x0050, 0x0052, 'code', {'section': 'SECTION "Timer vector", ROM0[$0050]'}),
    (0x006D, 0x008E, 'code', {'section': 'SECTION "Timer ISR", ROM0[$006D]'}),
    (0x0229, 0x022F, 'code', {'section': 'SECTION "Helpers 1", ROM0[$0229]'}),
    (0x0243, 0x0251, 'code', {'section': 'SECTION "Helpers 2", ROM0[$0243]'}),
    (0x02B2, 0x02D0, 'code', {'section': 'SECTION "Helpers 3", ROM0[$02B2]'}),
    (0x0480, 0x04AC, 'code', {'section': 'SECTION "Pause glue", ROM0[$0480]'}),
    (0x6576, 0x66E0, 'code', {'section': 'SECTION "Sound driver", ROMX[$6576], BANK[1]'}),
    (0x66E1, 0x66EA, 'dw', None),
    (0x66EB, 0x678C, 'code', None),
    (0x678D, 0x6794, 'db', {}),
    (0x6795, 0x67B3, 'code', None),
    (0x67B4, 0x67C5, 'dw', None),
    (0x67C6, 0x67FC, 'code', None),
    (0x67FD, 0x6806, 'dw', None),
    (0x6807, 0x688F, 'code', None),
    (0x6890, 0x6896, 'db', {}),
    (0x6897, 0x6897, 'db', {}),
    (0x6898, 0x6BC2, 'code', None),
    (0x6BC3, 0x6BC9, 'db', {}),
    (0x6BCA, 0x6DCD, 'code', None),
    (0x6DCE, 0x7FDD, 'data', None),
    (0x7FDE, 0x7FF6, 'code', None),
    (0x7FF7, 0x7FFA, 'db', {}),
    (0x7FFB, 0x7FFE, 'db', {}),
    (0x7FFF, 0x7FFF, 'db', {}),
]

NAMES = {
    0x0028: 'AddAToHL', 0x0038: 'Rst38', 0x0050: 'TimerVector', 0x006D: 'TimerISR',
    0x0229: 'JumpTableInline', 0x0243: 'NegateHL', 0x024D: 'SwapHLDE', 0x02B2: 'GetTrackPage',
    0x02B9: 'CopyBytes', 0x02C2: 'SwapHLBC', 0x02CB: 'LoadPtrFromTable', 0x0480: 'PauseToggle',
    0x6576: 'SndInit', 0x6591: 'SndUpdate', 0x6600: 'SndUpdateDone', 0x660E: 'TrackTick',
    0x6687: 'Ch3Decay', 0x66BE: 'VibratoTick', 0x66D3: 'ReadCmdsNext', 0x66D4: 'ReadCmds',
    0x66EB: 'Cmd_Segno', 0x66F3: 'Cmd_Ret', 0x66FB: 'Cmd_Call', 0x670B: 'Cmd_Repeat',
    0x672E: 'Cmd_End', 0x6774: 'QueueFollowUp', 0x678D: 'FollowUpTable', 0x6795: 'ReadCmdsLow',
    0x67C6: 'Cmd_LenUnit', 0x67CE: 'Cmd_Release', 0x67E0: 'Cmd_Sweep', 0x67F3: 'Cmd_Ext',
    0x6807: 'Ext_TransposeUp', 0x6811: 'Ext_TransposeDown', 0x681D: 'Ext_Vibrato',
    0x683C: 'Ext_Duty', 0x6849: 'Ext_Nop', 0x684D: 'Cmd_EB', 0x6851: 'Cmd_EC', 0x6855: 'Cmd_ED',
    0x6859: 'Cmd_Tempo', 0x6861: 'Cmd_Pan', 0x6890: 'PanMaskTable', 0x6897: 'StrayRet',
    0x6898: 'Cmd_Octave', 0x68A2: 'Cmd_Voice', 0x68F7: 'Cmd_Atten', 0x6925: 'NoiseNote',
    0x6932: 'Note', 0x6A29: 'VibratoStep', 0x6A90: 'WritePeriod', 0x6ACE: 'WritePeriodBC',
    0x6AE8: 'SavePtr', 0x6AEF: 'Rest', 0x6B10: 'DrumNote', 0x6B1E: 'WriteDuty',
    0x6B4D: 'IsBlocked', 0x6B68: 'WriteReg', 0x6B8B: 'Trigger', 0x6BA1: 'GetRegAddr',
    0x6BB8: 'GetRegBase', 0x6BC3: 'RegBaseTable', 0x6BCA: 'SndPause', 0x6BDF: 'SndUnpause',
    0x6C17: 'CopyRegs', 0x6C1F: 'PlaySound', 0x6C35: 'PlaySoundMain', 0x6C7B: 'StartSfx1',
    0x6C93: 'StartTrack', 0x6CC0: 'StartSfx2', 0x6CD1: 'StartCh1', 0x6CF2: 'StartCh2',
    0x6D03: 'StartCh3', 0x6D14: 'StartSfxN', 0x6D25: 'StartDrm', 0x6D2C: 'StopAll',
    0x6DCE: 'PeriodTable', 0x6E8E: 'WaveTable', 0x6F30: 'SoundTable', 0x7002: 'DrumMap',
    0x7061: 'VibratoTable', 0x79A1: 'Orphan_79A1',
    0x7FDE: 'SetCourseTempoB', 0x7FE3: 'SetCourseTempoA', 0x7FF7: 'CourseTempoA',
    0x7FFB: 'CourseTempoB', 0x7FFF: 'BankEndPad',
}
for i in range(9):
    NAMES[0x6EA0 + 16 * i] = f'Wave{i + 1}'

BLOCKS = {
    0x006D: ['Timer interrupt (64 Hz: TAC = %111, TMA = 0). Re-enables interrupts at once.',
             'The tick is skipped (lost) while PlaySound runs (wPlayLock) or the ISR is',
             'already inside SndUpdate (wIsrLock).'],
    0x0229: ['JumpTableInline: pop the return address, jump to word [ret + 2*A].'],
    0x0243: ['NegateHL (reached via rst $38).'],
    0x02B2: ['GetTrackPage: H = $C0 | wTrackIdx (tracks are $100 apart, fields at L = $80+).'],
    0x0480: ['Game pause toggle. Not driver code, kept as the only user of SndPause/Unpause.'],
    0x6576: ['SndInit: clear $C080-$C27F, NR52 = NR51 = $FF, NR50 = $77.'],
    0x6591: ['SndUpdate: one driver tick (64 Hz). Tracks 0-2 (SFX) run every tick, tracks',
             '3-6 (music) are skipped on ticks where wTempoAcc += wTempo carried (or while',
             'wMusicHold != 0, which nothing sets). If the engine sound ($09) owns track 3,',
             'track 3 runs every tick and the skip starts at track 4.',
             'While wPause != 0 only track 1 runs, and only for sound 8 (pause jingle).',
             'Finally a sound queued in wQueuedSnd (by the end of sound $11) is started.'],
    0x660E: ['TrackTick: one tick for track wTrackIdx (H = its page).'],
    0x6687: ['Ch3Decay: step the NR32 level 1 -> 2 -> 3 -> 0 after the release point.'],
    0x66BE: ['VibratoTick: advance the vibrato table every TRK_VIBRELOAD ticks.'],
    0x66D4: ['ReadCmds: execute commands until a note/rest (or $FF end).'],
    0x672E: ['$FF: end of track. For sound $11 queue the course music first. Silence via',
             'NRx2 = 0 + trigger. When an SFX on CH1/CH2 ends while music uses the channel,',
             'restore the music duty and period (CH1 also clears NR10).'],
    0x6774: ['QueueFollowUp: sound $11 queues FollowUpTable[wCourse - 1] ($1D-$20).'],
    0x67F3: ['$EA xy: extended commands, x = 0..4 (x >= 5 would jump into garbage).'],
    0x6861: ['$EF: NR51 bits. Ignored on music CH1 while the CH1 SFX plays (not on CH2).'],
    0x6890: ['NR51 masks per track, then a stray, unreachable ret.'],
    0x68A2: ['$E0 unit [voice] [env/gate]: drum track unit only, noise SFX one byte -> NR42',
             '+ retrigger, others vol/duty (+ WriteDuty) and env/gate.'],
    0x6932: ['Note: length = (lo nibble) * unit; hi 0 = rest; drum track plays a sound.'],
    0x6A29: ['VibratoStep: $FB loop point, $FE n repeat, $FF hold, else step.'],
    0x6A90: ['WritePeriod: NRx3/NRx4 = period + vibrato offset. For sound $09 (engine) the',
             'offset is replaced by wEnginePitch * 8, set by the game every frame.'],
    0x6B10: ['DrumNote: start sound DrumMap[hi - 1] immediately.'],
    0x6B1E: ['WriteDuty: NRx1 = duty << 4, or on CH3 copy wave (duty-1) into wave RAM.'],
    0x6B4D: ['IsBlocked: carry = music CH1 with the CH1 SFX active, or music CH2 with the',
             'CH2 SFX active.'],
    0x6B68: ['WriteReg: [FF10 + wRegBase + wRegIdx] = wRegVal via the shadow (wShadow).'],
    0x6BCA: ['SndPause: silence CH1/CH2/CH4 (vol 0, retrigger), CH3 level 0.'],
    0x6BDF: ['SndUnpause: copy shadows back (no retrigger). CH4 only for ids >= 8.',
             'wMusicHold is read but never written (always 0).'],
    0x6C1F: ['PlaySound: A = sound id (0 = stop everything). Sets wPlayLock meanwhile.'],
    0x6C35: ['Each mask bit starts one track if the new priority >= that track\'s priority.'],
    0x6D2C: ['StopAll: clear all 7 tracks, the shadows and $C100-$C10D, silence CH1-CH4.'],
    0x6DCE: ['96 periods (same values as Castlevania Adventure).'],
    0x6E8E: ['CH3 waves 1-9.'],
    0x6F30: ['Sound table: 32 ids ($01-$20). Id 0 = StopAll.'],
    0x7002: ['Drum map: DRUM n plays sound DrumMap[n-1] (13 entries).'],
    0x7061: ['Vibrato table: 15 entries (several share Vib01).'],
    0x79A1: ['Unreferenced data (41 bytes).'],
    0x7FDE: ['Course music tempo, called by the game: if a course song ($1D-$20) is on',
             'CH3, wTempo = table[id - $1D]. Two tables (A = $7FF7, B = $7FFB).'],
}

COMMENTS = {}
IMM8 = {}
EXTRA_SYM = {}


def imm8(pc, mn, ops):
    if not (0x6576 <= pc <= 0x7FFF) or mn != 'ld': return ops
    m = re.match(r'l,\$([0-9A-F]{2})$', ops)
    if m and int(m.group(1), 16) in TRK: return 'l,' + TRK[int(m.group(1), 16)]
    if ops == 'h,$C3': return 'h,HIGH(wTrkCh1)'
    if ops == 'h,$C4': return 'h,HIGH(wTrkCh2)'
    return ops


DATA_SPECIAL = {
    0x6DCE: (192, 'period', None),
    0x6E8E: (18, 'dw', None),
    0x6EA0: (0x6F30 - 0x6EA0, 'db', 16),
    0x6F30: (0x20 * 2, 'dw', lambda i: f'${i + 1:02X}'),
    0x7002: (13, 'db', 16),
    0x7061: (30, 'dw', lambda i: f'{i + 1}'),
}
