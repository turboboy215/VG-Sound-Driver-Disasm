"""gen_asm config: Nemesis (E)"""
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
    (0xC00D, 'wIsrLock', 1), (0xC00F, 'wJoyPressed', 1), (0xC013, 'wPause', 1),
    (0xC018, 'wCurBank', 1), (0xC025, 'wSndCallLock', 1), (0xC081, 'wGameC081', 1),
    (0xC180, 'wTrkSfx1', 0x25), (0xC280, 'wTrkSfx2', 0x25), (0xC380, 'wTrkSfxN', 0x25),
    (0xC480, 'wTrkCh1', 0x25), (0xC580, 'wTrkCh2', 0x25), (0xC680, 'wTrkCh3', 0x25),
    (0xC780, 'wTrkDrm', 0x25),
    (0xC1A7, 'wTrackIdx', 1), (0xC1A8, 'wRegBase', 1), (0xC1A9, 'wTempo', 1),
    (0xC1AA, 'wTempoAcc', 1), (0xC1AB, 'wTempoSkip', 1), (0xC1AC, 'wQueuedSnd', 1),
    (0xC1AD, 'wNR51', 1), (0xC1AE, 'wSweepVal', 1), (0xC1AF, 'wReqId', 1),
    (0xC1B0, 'wReqPrio', 1), (0xC1B1, 'wRegVal', 1), (0xC1B2, 'wRegIdx', 1),
    (0xC1B3, 'wMusicHold', 1), (0xC1B4, 'wLockout', 2), (0xC1B6, 'wFadeTarget', 1),
    (0xC1B7, 'wFadeTimer', 1), (0xC1B8, 'wFadeLevel', 1),
    (0xC2A4, 'wShadow', 0x14),
    (0xCE13, 'wGameCE13', 1),
]

_trkequ = ['; per-track fields: track n lives at $C180 + n*$100, so H = $C1 + n and L = field']
for k, v in TRK.items():
    if '+' not in v: _trkequ.append(f'DEF {v} EQU ${k:02X}')

HEADER = [
    '; ==========================================================================',
    '; Nemesis (E) - Konami sound driver (later GB version: fade-out, lockout, follow-ups)',
    '; Byte-exact RGBDS disassembly of the driver code and all sound data.',
    ';   ROM0 $0008 rst $08, $0028 rst $28, $0050 timer vector, $0222 timer ISR,',
    ';        $0334-$037C bank helpers + PlaySoundFar, $0441-$0478 game pause toggle',
    ';   bank 7 $4000-$7404 driver code, tables, sound data (then $FF up to $7FFF)',
    '; Build: rgbasm -Wall -o nem.o NEM_SoundDriver.asm && rgblink -o nem.gb nem.o',
    '; ==========================================================================',
    '',
] + C.HW_EQU.splitlines() + [''] + C.ram_equ(RAM) + [
    'DEF rROMB EQU $2000 ; MBC1 bank select',
    '',
] + _trkequ + [
    '',
    '; track flags (TRK_FLAGS)',
    'DEF TF_RELEASED EQU 0',
    'DEF TF_AUTOPAN EQU 1',
    'DEF TF_VIBNEG EQU 3',
    'DEF TF_FORCE EQU 6',
    'DEF TF_REST EQU 7',
    '',
] + C.MACROS.splitlines()

SEGMENTS = [
    (0x0008, 0x000B, 'code', {'section': 'SECTION "rst08", ROM0[$0008]'}),
    (0x0028, 0x002C, 'code', {'section': 'SECTION "rst28", ROM0[$0028]'}),
    (0x0050, 0x0052, 'code', {'section': 'SECTION "Timer vector", ROM0[$0050]'}),
    (0x0222, 0x024E, 'code', {'section': 'SECTION "Timer ISR", ROM0[$0222]'}),
    (0x0334, 0x037C, 'code', {'section': 'SECTION "Bank helpers", ROM0[$0334]'}),
    (0x0441, 0x0478, 'code', {'section': 'SECTION "Pause glue", ROM0[$0441]'}),
    (0x4000, 0x403F, 'code', {'section': 'SECTION "Sound driver", ROMX[$4000], BANK[7]'}),
    (0x4040, 0x40FF, 'data', None),
    (0x4100, 0x42E6, 'code', None),
    (0x42E7, 0x42F0, 'dw', None),
    (0x42F1, 0x43BD, 'code', None),
    (0x43BE, 0x43CF, 'dw', None),
    (0x43D0, 0x4406, 'code', None),
    (0x4407, 0x4410, 'dw', None),
    (0x4411, 0x44B2, 'code', None),
    (0x44B3, 0x44B9, 'db', {}),
    (0x44BA, 0x47E1, 'code', None),
    (0x47E2, 0x5B13, 'data', None),
    (0x5B14, 0x5B63, 'code', None),
    (0x5B64, 0x5B6D, 'dw', None),
    (0x5B6E, 0x5D4E, 'code', None),
    (0x5D4F, 0x7404, 'data', None),
]

NAMES = {
    0x0008: 'LoadHLFromHL', 0x0028: 'AddAToHL', 0x0050: 'TimerVector', 0x0222: 'TimerISR',
    0x0334: 'SetBank1', 0x0337: 'SetBankA', 0x0341: 'SetBank2', 0x0346: 'SetBank3',
    0x034B: 'SetBank4', 0x0350: 'SetBank5', 0x0355: 'SetBank6', 0x035A: 'SetBank7',
    0x035F: 'PlaySoundFar', 0x0441: 'PauseToggle',
    0x4000: 'GetTrackPage', 0x4009: 'CopyBytes', 0x4012: 'NegateHL', 0x401A: 'SwapHLBC',
    0x401F: 'SwapHLDE', 0x4024: 'LoadPtrFromTable', 0x4028: 'JumpTableInline',
    0x4040: 'PeriodTable', 0x4100: 'SndInit', 0x416F: 'FadeTick', 0x419A: 'TempoTick',
    0x41B0: 'LockoutTick', 0x41BD: 'SndUpdate', 0x4204: 'SndUpdateRun', 0x4210: 'SndUpdateNext', 0x4218: 'SndUpdateDone',
    0x4226: 'TrackTick', 0x428D: 'Ch3Decay', 0x42C4: 'VibratoTick', 0x42D9: 'ReadCmdsNext',
    0x42DA: 'ReadCmds', 0x42F1: 'Cmd_Segno', 0x42F9: 'Cmd_Ret', 0x4301: 'Cmd_Call',
    0x4311: 'Cmd_Repeat', 0x4334: 'Cmd_End', 0x4378: 'QueueFollowUp', 0x439F: 'ReadCmdsLow',
    0x43D0: 'Cmd_LenUnit', 0x43D8: 'Cmd_Release', 0x43EA: 'Cmd_Sweep', 0x43FD: 'Cmd_Ext',
    0x4411: 'Ext_TransposeUp', 0x441B: 'Ext_TransposeDown', 0x4427: 'Ext_Vibrato',
    0x4451: 'Ext_Duty', 0x445E: 'Ext_Autopan', 0x4472: 'Cmd_EB', 0x4476: 'Cmd_EC',
    0x447A: 'Cmd_ED', 0x447E: 'Cmd_Tempo', 0x4486: 'Cmd_Pan', 0x44B3: 'PanMaskTable',
    0x44BA: 'AutoPan', 0x44D8: 'Cmd_Octave', 0x44E2: 'Cmd_Voice', 0x4537: 'Cmd_Atten',
    0x4565: 'NoiseNote', 0x4572: 'Note', 0x4620: 'NoteVolume', 0x4671: 'VibratoStep',
    0x46D8: 'WritePeriod', 0x46FA: 'WritePeriodBC', 0x4714: 'SavePtr', 0x471B: 'Rest',
    0x472F: 'DrumNote', 0x473D: 'WriteDuty', 0x476C: 'IsBlocked', 0x4787: 'WriteReg',
    0x47AA: 'Trigger', 0x47C0: 'GetRegAddr', 0x47D7: 'GetRegBase', 0x47E2: 'RegBaseTable',
    0x47E9: 'VibratoTable',
    0x5B14: 'PlaySoundSafe', 0x5B20: 'StartFade', 0x5B2C: 'CheckLockout', 0x5B64: 'LockoutTable',
    0x5B6E: 'PlaySound', 0x5BB9: 'StartSfx1', 0x5BD2: 'StartSfx2', 0x5BE1: 'StartSfxN',
    0x5BF0: 'StartCh1', 0x5C0F: 'StartCh2', 0x5C1E: 'StartCh3', 0x5C2D: 'StartDrm',
    0x5C34: 'StartTrack', 0x5C61: 'StopAll', 0x5CE4: 'SndPause', 0x5CEF: 'SndUnpause',
    0x5D47: 'CopyRegs',
    0x5FBC: 'Orphan_5FBC', 0x67CE: 'SoundTable', 0x6984: 'DrumMap', 0x69EE: 'WaveTable',
}
for i in range(10):
    NAMES[0x6A02 + 16 * i] = f'Wave{i + 1}'

BLOCKS = {
    0x0008: ['rst $08: HL = word at [HL].'],
    0x0028: ['rst $28: HL += A.'],
    0x0222: ['Timer interrupt (64 Hz). Re-enables interrupts at once. The tick is skipped',
             '(lost) while PlaySoundFar runs (wSndCallLock) or the ISR is already inside',
             'SndUpdate (wIsrLock). Bank 7 is mapped for the update, then wCurBank again.'],
    0x0334: ['Bank helpers: SetBankN maps bank N and records it in wCurBank.'],
    0x035F: ['PlaySoundFar: the game\'s entry. A = sound id. Holds wSndCallLock (so a timer',
             'tick arriving meanwhile is lost), maps bank 7 for PlaySound, then maps bank 1',
             '(not the caller\'s bank).'],
    0x0441: ['Game pause toggle (START). Not driver code; kept as the only user of',
             'SndPause / SndUnpause. Pausing plays $2C, the pause jingle.'],
    0x4000: ['GetTrackPage: H = $C1 + wTrackIdx (tracks are $100 apart, fields at L = $80+).'],
    0x4028: ['JumpTableInline: called with A = index; jumps to word [ret + 2*A] with HL',
             'preserved (via $C026/$C027, outside the driver\'s RAM).'],
    0x4040: ['96 periods (same values as the earlier games).'],
    0x4100: ['SndInit: clear $C180-$C800, NR52 = NR51 = $FF, NR50 = $77.'],
    0x416F: ['FadeTick: while wFadeTarget != 0 (written by the game), wFadeLevel goes up',
             'by one every 64 ticks. Every new note is wFadeLevel quieter (CH3: half).',
             'At level 5: targets < 7 stop everything; others start the target sound',
             '(via wQueuedSnd) and clear the fade. Frozen while paused.'],
    0x419A: ['TempoTick: wTempoAcc += wTempo; a carry skips the music tracks this tick.'],
    0x41B0: ['LockoutTick: count wLockout down to 0 (see CheckLockout).'],
    0x41BD: ['SndUpdate: one driver tick (64 Hz). Tracks 0-2 (SFX) run every tick, tracks',
             '3-6 (music) are skipped on tempo-skip ticks (or while wMusicHold != 0, which',
             'nothing sets). While wPause != 0 only track 1 runs, and only for sound $2C.',
             'Finally a sound in wQueuedSnd (fade target or follow-up) is started.'],
    0x41F3: ['Unreachable: the old Motocross Maniacs check that moved the skip to track 4',
             'while the engine sound held track 3.'],
    0x4226: ['TrackTick: one tick for track wTrackIdx (H = its page).'],
    0x428D: ['Ch3Decay: step the NR32 level code up (1 -> 2 -> 3 -> off) every env ticks',
             'after the release point. The stored level already contains the attenuation',
             'and fade, and the attenuation is added again here.'],
    0x42C4: ['VibratoTick: advance the vibrato table every TRK_VIBRELOAD ticks.'],
    0x42DA: ['ReadCmds: execute commands until a note/rest (or $FF end).'],
    0x4334: ['$FF: end of track. Sounds $37, $21 and $14 queue a follow-up first. NRx2 = 0',
             '(no trigger). When an SFX on CH1/CH2 ends while music uses the channel,',
             'restore the music duty and period (CH1 also clears NR10). CH3: NR30 = 0.'],
    0x4378: ['QueueFollowUp: $37 -> $34, $21 -> $36, $14 -> $34 if wGameC081 = 2, else $33.'],
    0x43FD: ['$EA xy: extended commands, x = 0..4 (x >= 5 would jump into garbage).'],
    0x445E: ['$EA 4n: meant to set/clear TF_AUTOPAN, but stores n (| TF_AUTOPAN) into the',
             'whole flags byte. Not used by this game\'s data.'],
    0x4486: ['$EF: NR51 bits (nibble-swapped). Ignored on music CH1 while the CH1 SFX plays.'],
    0x44B3: ['NR51 bits each track keeps when it pans.'],
    0x44E2: ['$E0 unit [voice] [env/gate]: drum track unit only, noise SFX one byte -> NR42',
             '+ retrigger, others vol/duty (+ WriteDuty) and env/gate.'],
    0x4572: ['Note: length = (lo nibble) * unit; hi 0 = rest; drum track plays a sound.'],
    0x4620: ['NoteVolume: NRx2 for a note-on = (vol - atten - wFadeLevel) << 4, floored at 0',
             '(CH3: level code from vol/2 + atten + wFadeLevel/2, NR30 on).'],
    0x4671: ['VibratoStep: $FB loop point, $FE n repeat, $FF hold, else step.'],
    0x46D8: ['WritePeriod: NRx3/NRx4 = period + vibrato offset (negated if TF_VIBNEG).'],
    0x471B: ['Rest: NRx2 = 0 only (no NRx4 write, unlike the earlier games).'],
    0x472F: ['DrumNote: start sound DrumMap[hi - 1] at once (through the full PlaySound).'],
    0x473D: ['WriteDuty: NRx1 = duty << 4, or on CH3 copy wave (duty-1) into wave RAM.'],
    0x476C: ['IsBlocked: carry = music CH1 with the CH1 SFX active, or music CH2 with the',
             'CH2 SFX active.'],
    0x4787: ['WriteReg: [FF10 + wRegBase + wRegIdx] = wRegVal via the shadow (wShadow).'],
    0x47E2: ['NR register base per track.'],
    0x47E9: ['Vibrato table: 15 entries.'],
    0x5B14: ['PlaySoundSafe: PlaySound keeping all registers (used for drums and the queue).'],
    0x5B20: ['StartFade: wFadeTarget = A. Unreferenced: the game writes wFadeTarget itself.'],
    0x5B2C: ['CheckLockout: carry = refuse the request. $2C (pause) and $13 always pass.',
             'Everything else is refused while wLockout != 0. Ids >= $2E cancel a fade, and',
             'ids $2E-$32 also start the lockout from LockoutTable.'],
    0x5B64: ['Lockout ticks for ids $2E-$32.'],
    0x5B6E: ['PlaySound: A = sound id (0 = stop everything). $0F does not restart itself.',
             'Each mask bit starts one track if the new priority >= that track\'s priority.'],
    0x5C61: ['StopAll: clear all 7 tracks, the shadows and the globals, wNR51 = $FF (not',
             'written to NR51), then fall into SndPause.'],
    0x5CE4: ['SndPause: NR12/NR17/NR1C/NR21 = 0.'],
    0x5CEF: ['SndUnpause: copy the shadows back (no retrigger), per channel only if one of',
             'its tracks is active. CH4 only for SfxN ids >= 8 (not a drum).'],
    0x5FBC: ['Unreferenced stream bytes.'],
    0x67CE: ['Sound table: 57 ids ($01-$39). The code indexes it as SoundTable - 2 + 2*id.'],
    0x6984: ['Drum map: DRUM n plays sound DrumMap[n-1] (13 entries; 13 = sound $22).'],
    0x69EE: ['CH3 waves 1-10.'],
}

COMMENTS = {}
IMM8 = {
    0x4004: lambda m: 'HIGH(wTrkSfx1)',
}
EXTRA_SYM = {0x2000: 'rROMB', 0x67CC: 'SoundTable - 2'}


def imm8(pc, mn, ops):
    if not (0x4000 <= pc <= 0x7FFF): return ops
    if mn == 'ld':
        m = re.match(r'l,\$([0-9A-F]{2})$', ops)
        if m and int(m.group(1), 16) in TRK: return 'l,' + TRK[int(m.group(1), 16)]
        if ops == 'h,$C4': return 'h,HIGH(wTrkCh1)'
        if ops == 'h,$C5': return 'h,HIGH(wTrkCh2)'
    return ops


DATA_SPECIAL = {
    0x4040: (192, 'period', None),
    0x47E2: (7, 'db', 16),
    0x47E9: (30, 'dw', lambda i: f'{i + 1}'),
    0x67CE: (0x39 * 2, 'dw', lambda i: f'${i + 1:02X}'),
    0x6984: (13, 'db', 16),
    0x69EE: (20, 'dw', None),
    0x6A02: (160, 'db', 16),
}
