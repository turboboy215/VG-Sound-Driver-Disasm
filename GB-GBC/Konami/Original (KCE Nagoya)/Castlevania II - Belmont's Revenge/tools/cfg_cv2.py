"""gen_asm config: Castlevania II - Belmont's Revenge (U)"""
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
       0xA3: 'TRK_VIBLOOPIDX', 0xA4: 'TRK_DUTYCNT', 0xA5: 'TRK_DUTYSTEP', 0xA6: 'TRK_DUTYTICKS',
       0xB5: 'TRK_PAN'}

RAM = [
    (0xC080, 'wTrkSfx1', 0x37), (0xC180, 'wTrkSfx2', 0x37), (0xC280, 'wTrkSfxN', 0x37),
    (0xC380, 'wTrkCh1', 0x37), (0xC480, 'wTrkCh2', 0x37), (0xC580, 'wTrkCh3', 0x37),
    (0xC680, 'wTrkDrm', 0x37),
    (0xC0B9, 'wTrackIdx', 1), (0xC0BA, 'wRegBase', 1), (0xC0BB, 'wTempo', 1),
    (0xC0BC, 'wTempoAcc', 1), (0xC0BD, 'wTempoSkip', 1), (0xC0BE, 'wQueuedSnd', 1),
    (0xC0BF, 'wNR51', 1), (0xC0C0, 'wSweepVal', 1), (0xC0C1, 'wReqId', 1),
    (0xC0C2, 'wReqPrio', 1), (0xC0C3, 'wRegVal', 1), (0xC0C4, 'wRegIdx', 1),
    (0xC0C5, 'wMusicHold', 1), (0xC0C8, 'wFadeReq', 1), (0xC0C9, 'wFadeTimer', 1),
    (0xC0CA, 'wFadeLevel', 1), (0xC0CB, 'wReqRefused', 1),
    (0xC1B6, 'wShadow', 0x14),
    (0xC885, 'wSndLock', 1), (0xC88B, 'wPauseFlags', 1), (0xC8C0, 'wStage', 1),
    (0xC8CE, 'wStageMusicOvr', 1),
]

_trkequ = ['; per-track fields: track n lives at $C080 + n*$100, so H = $C0 + n and L = field']
for k, v in TRK.items():
    if '+' not in v: _trkequ.append(f'DEF {v} EQU ${k:02X}')

HEADER = [
    '; ==========================================================================',
    "; Castlevania II - Belmont's Revenge (U) - Konami sound driver (later GB version)",
    '; Byte-exact RGBDS disassembly of the driver code and all sound data.',
    ';   ROM0 $0028 rst $28, $3537-$35C6 VBlank update call, far wrappers, bank helpers',
    ';   bank 7 $4000-$7FFF driver code, tables, sound data',
    '; Build: rgbasm -Wall -o cv2.o CV2_SoundDriver.asm && rgblink -o cv2.gb cv2.o',
    '; ==========================================================================',
    '',
] + C.HW_EQU.splitlines() + [''] + C.ram_equ(RAM) + [
    'DEF rROMB EQU $2180 ; MBC1 bank select as written by this game',
    'DEF hBankId EQU $7FFF ; every bank stores its own number in its last byte',
    '',
] + _trkequ + [
    '',
    '; track flags (TRK_FLAGS)',
    'DEF TF_RELEASED EQU 0',
    'DEF TF_AUTOPAN EQU 1',
    'DEF TF_VIBNEG EQU 3',
    'DEF TF_DUTYSTEP EQU 4',
    'DEF TF_FORCE EQU 6',
    'DEF TF_REST EQU 7',
    '',
] + C.MACROS.splitlines() + [
    '; $ED xy (new here): duty step. Each note starts with duty \\1 for \\2 ticks, then the voice duty',
    'MACRO DUTY_STEP',
    '\tdb $ED, (\\2 << 4) | \\1',
    'ENDM',
]

SEGMENTS = [
    (0x0028, 0x002C, 'code', {'section': 'SECTION "rst28", ROM0[$0028]'}),
    (0x3537, 0x3584, 'code', {'section': 'SECTION "Sound glue", ROM0[$3537]'}),
    (0x3585, 0x358C, 'db', {}),
    (0x358D, 0x35C6, 'code', None),
    (0x4000, 0x4024, 'code', {'section': 'SECTION "Sound driver", ROMX[$4000], BANK[7]'}),
    (0x4025, 0x40CE, 'data', None),
    (0x40CF, 0x4432, 'code', None),
    (0x4433, 0x443C, 'dw', None),
    (0x443D, 0x44DF, 'code', None),
    (0x44E0, 0x44F1, 'dw', None),
    (0x44F2, 0x4528, 'code', None),
    (0x4529, 0x4532, 'dw', None),
    (0x4533, 0x45ED, 'code', None),
    (0x45EE, 0x45FB, 'dw', None),
    (0x45FC, 0x498B, 'code', None),
    (0x498C, 0x7FFF, 'data', None),
]

NAMES = {
    0x0028: 'AddAToHL', 0x3537: 'SndUpdateFar', 0x3553: 'PlaySoundFar', 0x356A: 'PlayStageMusic',
    0x3585: 'StageMusicTable', 0x358D: 'StartFadeFar', 0x35A4: 'StopSoundFar',
    0x35A9: 'SetBank1', 0x35AF: 'SetBank2', 0x35B5: 'SetBank6', 0x35BB: 'SetBank7', 0x35C1: 'SetBank3',
    0x4000: 'CopyBytes', 0x4009: 'LoadPtrIndexed', 0x4013: 'JumpTableInline', 0x4018: 'SndInit',
    0x4025: 'PeriodTable', 0x40CF: 'PlaySound', 0x40D5: 'StopSound', 0x40DD: 'StartFade',
    0x40E3: 'PlaySoundMain', 0x4131: 'PlaySoundAbort', 0x4136: 'StartCh1', 0x4151: 'StartCh2',
    0x415F: 'StartCh3', 0x416D: 'StartSfxN', 0x417B: 'StartDrm', 0x4181: 'StartSfx2',
    0x418F: 'StartSfx1', 0x41A2: 'StartTrack', 0x41CE: 'StopAll', 0x4251: 'SndPause',
    0x425C: 'SndUnpause', 0x42AF: 'CopyRegs', 0x42B6: 'FadeTick', 0x42E0: 'TempoTick',
    0x42F6: 'SndUpdate', 0x433B: 'SndUpdateRun', 0x434A: 'SndUpdateNext', 0x4352: 'SndUpdateDone',
    0x4360: 'TrackTick', 0x43D9: 'Ch3Decay', 0x4410: 'VibratoTick', 0x4425: 'ReadCmdsNext',
    0x4426: 'ReadCmds', 0x443D: 'Cmd_Segno', 0x4445: 'Cmd_Ret', 0x444D: 'Cmd_Call',
    0x445D: 'Cmd_Repeat', 0x4480: 'Cmd_End', 0x44C1: 'ReadCmdsLow', 0x44F2: 'Cmd_LenUnit',
    0x44FA: 'Cmd_Release', 0x450C: 'Cmd_Sweep', 0x451F: 'Cmd_Ext', 0x4533: 'Ext_TransposeUp',
    0x453D: 'Ext_TransposeDown', 0x4549: 'Ext_Vibrato', 0x4574: 'Ext_Duty', 0x4581: 'Ext_Autopan',
    0x4595: 'Cmd_EB', 0x4599: 'Cmd_EC', 0x459D: 'Cmd_DutyStep', 0x45BB: 'Cmd_Tempo',
    0x45C3: 'Cmd_Pan', 0x45E7: 'GetPanBits', 0x45FC: 'PanBits22', 0x4609: 'PanBits44',
    0x4616: 'PanBits88', 0x4623: 'PanBits11', 0x4630: 'AutoPan', 0x464C: 'Cmd_Octave',
    0x4656: 'Cmd_Voice', 0x46AB: 'Cmd_Atten', 0x46D9: 'NoiseNote', 0x46E6: 'Note',
    0x47B0: 'NoteVolume', 0x4801: 'VibratoStep', 0x4868: 'WritePeriod', 0x4892: 'WritePeriodBC',
    0x48AC: 'SavePtr', 0x48B3: 'Rest', 0x48C7: 'DrumNote', 0x48D9: 'WriteDuty',
    0x4908: 'IsBlocked', 0x4923: 'WriteReg', 0x494C: 'Trigger', 0x4965: 'GetRegAddr',
    0x497D: 'GetRegBase', 0x498C: 'RegBaseTable', 0x4993: 'WaveTable', 0x4A0B: 'VibratoTable',
    0x4A7B: 'SoundTable', 0x4DC3: 'DrumMap', 0x5412: 'Orphan_5412', 0x6C4D: 'Orphan_6C4D',
    0x7FF3: 'BankEndPad', 0x7FFF: 'BankId',
}
for i in range(6):
    NAMES[0x49AB + 16 * i] = f'WaveData{i + 1}'

BLOCKS = {
    0x0028: ['rst $28: HL += A.'],
    0x3537: ['SndUpdateFar: called from the VBlank handler (after ei) on every frame. Skipped',
             '(tick lost) while the main thread is inside PlaySoundFar (wSndLock).'],
    0x3553: ['PlaySoundFar: A = sound id. Dropped if wSndLock is already held (a request',
             'from an interrupt during the update). Restores the caller\'s bank via hBankId.'],
    0x356A: ['Game: stage music from StageMusicTable[wStage] (or $5F instead of $5E when',
             'wStageMusicOvr is set). Not driver code.'],
    0x358D: ['StartFadeFar: A = sound to start when the fade-out ends (0 = none).'],
    0x35A9: ['Bank helpers (no bank shadow in RAM; hBankId tells the current bank).'],
    0x4009: ['LoadPtrIndexed: HL = word at [HL + 2*A].'],
    0x4013: ['JumpTableInline: called with A = index; jumps to word [ret + 2*A].',
             'The handlers start with pop hl (the caller pushed HL before the call).'],
    0x4018: ['SndInit: NR52 = NR51 = $FF, NR50 = $77 (the game then calls StopSound).'],
    0x4025: ['85 periods: the same values as the earlier 96-entry table, cut after B-6.'],
    0x40CF: ['PlaySound: A = sound id, 0 = StopSound. Keeps DE.'],
    0x40DD: ['StartFade: wFadeReq = A | $80 (A = sound to start when the fade ends).'],
    0x40E3: ['Each mask bit starts one track if the new priority >= that track\'s priority',
             '(else wReqRefused = 1, and a later accepted track clears it again). The check',
             'after Sfx1 and after Sfx2/SfxN aborts the rest of the request (and skips the',
             'NR51 write) when the flag is set. The flag is never cleared by a new request,',
             'so a music track refused at the end of one request makes the next request',
             'abort at the first check.'],
    0x41CE: ['StopAll: clear all 7 tracks ($37 bytes each), the shadows and the globals,',
             'wNR51 = $FF (not written to NR51), then fall into SndPause.'],
    0x4251: ['SndPause: NR12/NR17/NR21/NR1C = 0.'],
    0x425C: ['SndUnpause: copy the shadows back (no retrigger), per channel only if one of',
             'its tracks is active. Not while paused or wMusicHold.'],
    0x42B6: ['FadeTick: while wFadeReq bit 7 is set, wFadeLevel goes up by one every 32',
             'ticks. Every new note is wFadeLevel quieter (CH3: half). At level 5 the',
             'requested sound (bits 0-6) is queued and the fade cleared. With 0 nothing is',
             'queued, so the music jumps back to full volume. Frozen while paused.'],
    0x42E0: ['TempoTick: wTempoAcc += wTempo; a carry skips the music tracks this tick.'],
    0x42F6: ['SndUpdate: one driver tick (VBlank, 59.7 Hz). Tracks 0-2 (SFX) run every tick,',
             'tracks 3-6 (music) are skipped on tempo-skip ticks (or while wMusicHold != 0,',
             'which nothing sets). While paused (wPauseFlags bit 0) only track 1 runs, and',
             'only for sound $06. Finally a sound in wQueuedSnd (fade target) is started.'],
    0x4360: ['TrackTick: one tick for track wTrackIdx (H = its page). With TF_DUTYSTEP the',
             'voice duty is restored after TRK_DUTYTICKS ticks of a note.'],
    0x43D9: ['Ch3Decay: step the NR32 level code up (1 -> 2 -> 3 -> off) every env ticks',
             'after the release point (the attenuation is counted twice, as in Nemesis).'],
    0x4426: ['ReadCmds: execute commands until a note/rest (or $FF end).'],
    0x4480: ['$FF: end of track. NRx2 = 0 (no trigger). When an SFX on CH1/CH2 ends while',
             'music uses the channel, restore the music duty and period (CH1 also clears',
             'NR10). CH3: NR30 = 0.'],
    0x451F: ['$EA xy: extended commands, x = 0..4 (x >= 5 would jump into garbage).'],
    0x4581: ['$EA 4n: stores n | TF_AUTOPAN into the whole flags byte (0 for n = 0). The',
             'data uses EA 42 / EA 40, which also clears TF_DUTYSTEP and TF_FORCE.'],
    0x459D: ['$ED xy: duty step. y = duty for the first x ticks of each note; 0 = off.'],
    0x45C3: ['$EF: TRK_PAN = NR51 bits for this track (not nibble-swapped any more). Dropped',
             'while the channel is blocked. On the drum track it skips one byte too many.'],
    0x45E7: ['GetPanBits: C = TRK_PAN & this track\'s NR51 bits, A = wNR51 without them.'],
    0x4630: ['AutoPan: swap TRK_PAN\'s nibbles and apply it (not on the noise SFX track).'],
    0x4656: ['$E0 unit [voice] [env/gate]: drum track unit only, noise SFX one byte -> NR42',
             '+ retrigger, others vol/duty (+ WriteDuty) and env/gate.'],
    0x46E6: ['Note: length = (lo nibble) * unit; hi 0 = rest; drum track plays a sound.'],
    0x47B0: ['NoteVolume: NRx2 for a note-on = (vol - atten - wFadeLevel) << 4, floored at 0',
             '(CH3: level code from vol/2 + atten + wFadeLevel/2, NR30 on).'],
    0x4801: ['VibratoStep: $FB loop point, $FE n repeat, $FF hold, else step.'],
    0x4868: ['WritePeriod: NRx3/NRx4 = period + vibrato offset (negated if TF_VIBNEG).'],
    0x48B3: ['Rest: NRx2 = 0 only.'],
    0x48C7: ['DrumNote: start sound DrumMap[hi - 1] at once.'],
    0x48D9: ['WriteDuty: NRx1 = duty << 4, or on CH3 copy wave (duty-1) into wave RAM.'],
    0x4908: ['IsBlocked: carry = music CH1 with the CH1 SFX active, or music CH2 with the',
             'CH2 SFX active.'],
    0x4923: ['WriteReg: [FF10 + wRegBase + wRegIdx] = wRegVal via the shadow (wShadow).'],
    0x498C: ['NR register base per track.'],
    0x4993: ['CH3 wave pointers 1-12 (pairs share a wave).'],
    0x4A0B: ['Vibrato table: 15 entries.'],
    0x4A7B: ['Sound table: 107 ids ($01-$6B). The code indexes it as SoundTable - 2 + 2*id.'],
    0x4DC3: ['Drum map: DRUM n plays sound DrumMap[n-1] (13 entries).'],
    0x5412: ['Unreferenced noise stream.'],
    0x6C4D: ['Unreferenced SND_CALL.'],
}

COMMENTS = {}
IMM8 = {}
EXTRA_SYM = {0x2180: 'rROMB', 0x7FFF: 'hBankId', 0x4A79: 'SoundTable - 2'}


def imm8(pc, mn, ops):
    if not (0x4000 <= pc <= 0x7FFF): return ops
    if mn == 'ld':
        m = re.match(r'l,\$([0-9A-F]{2})$', ops)
        if m and int(m.group(1), 16) in TRK: return 'l,' + TRK[int(m.group(1), 16)]
        if ops == 'h,$C3': return 'h,HIGH(wTrkCh1)'
        if ops == 'h,$C4': return 'h,HIGH(wTrkCh2)'
    if mn == 'add' and ops == 'a,$C0': return 'a,HIGH(wTrkSfx1)'
    return ops


DATA_SPECIAL = {
    0x4025: (170, 'period', None),
    0x498C: (7, 'db', 16),
    0x4993: (24, 'dw', None),
    0x49AB: (96, 'db', 16),
    0x4A0B: (30, 'dw', lambda i: f'{i + 1}'),
    0x4A7B: (0x6B * 2, 'dw', lambda i: f'${i + 1:02X}'),
    0x4DC3: (13, 'db', 16),
    0x7FF3: (12, 'db', 16),
    0x7FFF: (1, 'db', 16),
}
