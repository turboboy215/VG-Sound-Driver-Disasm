"""gen_asm config: Blades of Steel (E)"""
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
       0xA7: 'TRK_GLLEN', 0xA8: 'TRK_GLOCTAVE', 0xA9: 'TRK_GLTARGET', 0xAA: 'TRK_GLTARGET + 1',
       0xAB: 'TRK_GLPERIOD', 0xAC: 'TRK_GLPERIOD + 1', 0xAD: 'TRK_GLSTART', 0xAE: 'TRK_GLDIR',
       0xAF: 'TRK_GLDELTA', 0xB0: 'TRK_GLDELTA + 1', 0xB1: 'TRK_GLTIMER', 0xB2: 'TRK_GLRELOAD',
       0xB3: 'TRK_GLSTEP', 0xB4: 'TRK_GLLOOPCNT'}

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
    (0xD805, 'wSndLock', 1), (0xD81D, 'wPauseFlags', 1),
]

_trkequ = ['; per-track fields: track n lives at $C080 + n*$100, so H = $C0 + n and L = field']
for k, v in TRK.items():
    if '+' not in v: _trkequ.append(f'DEF {v} EQU ${k:02X}')

HEADER = [
    '; ==========================================================================',
    '; Blades of Steel (E) - Konami sound driver (later GB version)',
    '; Byte-exact RGBDS disassembly of the driver code and all sound data.',
    ';   ROM0 $0F01-$0F80 VBlank update call, far wrappers',
    ';   bank 7 $4000-$6C2E driver code, tables, sound data ($6C2F-$7FFF: graphics, not included)',
    '; Build: rgbasm -Wall -o bos.o BOS_SoundDriver.asm && rgblink -o bos.gb bos.o',
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
    'DEF TF_GLIDE EQU 5',
    'DEF TF_FORCE EQU 6',
    'DEF TF_REST EQU 7',
    '',
] + C.MACROS.splitlines() + [
    '; $ED xy: duty step. Each note starts with duty \\1 for \\2 ticks, then the voice duty',
    'MACRO DUTY_STEP',
    '\tdb $ED, (\\2 << 4) | \\1',
    'ENDM',
    '; $EA 5n (new here, unused by the data): glide to the next note over its last n units; 0 = off',
    'MACRO GLIDE',
    '\tdb $EA, $50 | \\1',
    'ENDM',
]

SEGMENTS = [
    (0x0F01, 0x0F80, 'code', {'section': 'SECTION "Sound glue", ROM0[$0F01]'}),
    (0x4000, 0x4024, 'code', {'section': 'SECTION "Sound driver", ROMX[$4000], BANK[7]'}),
    (0x4025, 0x40CE, 'data', None),
    (0x40CF, 0x447D, 'code', None),
    (0x447E, 0x4487, 'dw', None),
    (0x4488, 0x4528, 'code', None),
    (0x4529, 0x453A, 'dw', None),
    (0x453B, 0x4571, 'code', None),
    (0x4572, 0x457D, 'dw', None),
    (0x457E, 0x464F, 'code', None),
    (0x4650, 0x4656, 'db', {}),
    (0x4657, 0x4B41, 'code', None),
    (0x4B42, 0x6C2E, 'data', None),
]

NAMES = {
    0x0F01: 'SndUpdateFar', 0x0F1F: 'PlaySoundFar', 0x0F46: 'SndPauseFar', 0x0F57: 'SndUnpauseFar',
    0x0F68: 'StartFadeFar',
    0x4000: 'CopyBytes', 0x4009: 'LoadPtrIndexed', 0x4013: 'JumpTableInline', 0x4018: 'SndInit',
    0x4025: 'PeriodTable', 0x40CF: 'PlaySound', 0x40D5: 'StopSound', 0x40DD: 'StartFade',
    0x40E3: 'PlaySoundMain', 0x4131: 'PlaySoundAbort', 0x4136: 'StartCh1', 0x4151: 'StartCh2',
    0x415F: 'StartCh3', 0x416D: 'StartSfxN', 0x417B: 'StartDrm', 0x4181: 'StartSfx2',
    0x418F: 'StartSfx1', 0x41A2: 'StartTrack', 0x41CE: 'StopAll', 0x4251: 'SndPause',
    0x425C: 'SndUnpause', 0x42AD: 'CopyRegs', 0x42B4: 'FadeTick', 0x42E3: 'TempoTick',
    0x42F7: 'SndUpdate', 0x433D: 'SndUpdateRun', 0x434A: 'SndUpdateNext', 0x4352: 'SndUpdateDone',
    0x4360: 'TrackTick', 0x43B7: 'TrackTickTail', 0x43D9: 'Ch3Decay', 0x4410: 'GlideTick',
    0x4454: 'GlideOrVibrato', 0x445B: 'VibratoTick', 0x4470: 'ReadCmdsNext',
    0x4471: 'ReadCmds', 0x4488: 'Cmd_Segno', 0x4490: 'Cmd_Ret', 0x4498: 'Cmd_Call',
    0x44A8: 'Cmd_Repeat', 0x44CB: 'Cmd_End', 0x450A: 'ReadCmdsLow', 0x453B: 'Cmd_LenUnit',
    0x4543: 'Cmd_Release', 0x4555: 'Cmd_Sweep', 0x4568: 'Cmd_Ext', 0x457E: 'Ext_TransposeUp',
    0x4588: 'Ext_TransposeDown', 0x4594: 'Ext_Vibrato', 0x45BE: 'Ext_Duty', 0x45CB: 'Ext_Autopan',
    0x45D8: 'Ext_Glide', 0x45F5: 'Cmd_EB_EC', 0x45F9: 'Cmd_DutyStep', 0x4617: 'Cmd_Tempo',
    0x461F: 'Cmd_Pan', 0x4650: 'PanKeepMask', 0x4657: 'AutoPan', 0x4679: 'Cmd_Octave',
    0x4686: 'Cmd_Voice', 0x46DB: 'Cmd_Atten', 0x4709: 'NoiseNote', 0x4716: 'Note',
    0x47BE: 'NoteGlideDone', 0x47BF: 'NoteStart', 0x47E0: 'GlideSetup', 0x47ED: 'GlideScan',
    0x486D: 'GlideTarget', 0x4905: 'GlideStep',
    0x496C: 'NoteVolume', 0x49BD: 'VibratoStep', 0x4A28: 'WritePeriod', 0x4A4A: 'WritePeriodBC',
    0x4A64: 'SavePtr', 0x4A6B: 'Rest', 0x4A7E: 'DrumNote', 0x4A90: 'WriteDuty',
    0x4ABE: 'IsBlocked', 0x4AD9: 'WriteReg', 0x4B02: 'Trigger', 0x4B1B: 'GetRegAddr',
    0x4B33: 'GetRegBase', 0x4B42: 'RegBaseTable', 0x4B49: 'SoundTable', 0x513B: 'WaveTable',
    0x5229: 'DrumMap', 0x5267: 'VibratoTable',
    0x4D0C: 'Orphan_4D0C', 0x6270: 'Orphan_6270', 0x637E: 'Orphan_637E', 0x63FB: 'Orphan_63FB',
}
for i in range(13):
    NAMES[0x5159 + 16 * i] = f'WaveData{i + 1}'

BLOCKS = {
    0x0F01: ['SndUpdateFar: called from the VBlank handler on every frame. Skipped (tick',
             'lost) while the main thread is inside PlaySoundFar (wSndLock).'],
    0x0F1F: ['PlaySoundFar: A = sound id. Dropped if wSndLock is already held. Keeps HL/BC;',
             'the lock is only set once bank 7 is mapped.'],
    0x0F46: ['SndPauseFar / SndUnpauseFar: the game sets/clears wPauseFlags itself.'],
    0x0F68: ['StartFadeFar: A = sound to start when the fade-out ends (< 5 = stop). No lock.'],
    0x4009: ['LoadPtrIndexed: HL = word at [HL + 2*A].'],
    0x4013: ['JumpTableInline: called with A = index; jumps to word [ret + 2*A].',
             'The handlers start with pop hl (the caller pushed HL before the call).'],
    0x4018: ['SndInit: NR52 = NR51 = $FF, NR50 = $77.'],
    0x4025: ["85 periods, the same table as Belmont's Revenge."],
    0x40CF: ['PlaySound: A = sound id, 0 = StopSound. Keeps DE.'],
    0x40DD: ['StartFade: wFadeReq = A | $80 (A = sound to start when the fade ends).'],
    0x40E3: ["As in Belmont's Revenge: the check after Sfx1 and after Sfx2/SfxN aborts the",
             'rest of the request (and the NR51 write) when wReqRefused is set, and the flag',
             'is never cleared by a new request.'],
    0x41CE: ['StopAll: clear all 7 tracks ($37 bytes each), the shadows and the globals,',
             'wNR51 = $FF (not written to NR51), then fall into SndPause.'],
    0x4251: ['SndPause: NR12/NR17/NR21/NR1C = 0.'],
    0x425C: ['SndUnpause: copy the shadows back (no retrigger), per channel only if one of',
             'its tracks is active. Not while wPauseFlags or wMusicHold is non-zero.'],
    0x42B4: ['FadeTick: while wFadeReq bit 7 is set, wFadeLevel goes up by one every 16',
             'ticks. At level 5 bits 0-6 are queued; a target below 5 (0 included) calls',
             'StopAll instead, which also clears the queue. Frozen while paused.'],
    0x42E3: ['TempoTick: wTempoAcc += wTempo; a carry skips the music tracks this tick.'],
    0x42F7: ['SndUpdate: one driver tick (VBlank, 59.7 Hz). Tracks 0-2 (SFX) run every tick,',
             'tracks 3-6 (music) are skipped on tempo-skip ticks. While paused (wPauseFlags',
             'bit 0) only track 1 runs, and only for sound $06. Then wQueuedSnd is started.'],
    0x4360: ['TrackTick: one tick for track wTrackIdx (H = its page).'],
    0x43B7: ['TrackTickTail: CH3 decay, or the release (env write + retrigger) at TRK_RELTICK.',
             'GlideTick and GlideOrVibrato jump here with their return address still on the',
             'stack, so with TF_GLIDE set this runs twice per tick (three times while the',
             'glide timer is counting): CH3 decays two or three times as fast and the',
             'release retriggers more than once.'],
    0x43D9: ['Ch3Decay: step the NR32 level code up (1 -> 2 -> 3 -> off) every env ticks',
             'after the release point (the attenuation is counted twice).'],
    0x4410: ['GlideTick: once the note has TRK_GLSTART ticks or fewer left, every',
             'TRK_GLRELOAD ticks move TRK_GLPERIOD by TRK_GLSTEP towards the target and write',
             'it (no vibrato). It doesn\'t stop at the target.'],
    0x4454: ['GlideOrVibrato: vibrato only without TF_GLIDE.'],
    0x4471: ['ReadCmds: execute commands until a note/rest (or $FF end).'],
    0x44CB: ['$FF: end of track. NRx2 = 0 (no trigger). When an SFX on CH1/CH2 ends while',
             'music uses the channel, restore the music duty and period (CH1 also clears',
             'NR10). CH3: NR30 = 0.'],
    0x4568: ['$EA xy: extended commands, x = 0..5.'],
    0x45CB: ['$EA 4n: stores n | TF_AUTOPAN into the whole flags byte (0 for n = 0), which also',
             'clears TF_DUTYSTEP, TF_GLIDE and TF_FORCE.'],
    0x45D8: ['$EA 5n (new): TF_GLIDE on with TRK_GLLEN = n, or off for n = 0. Not used by the',
             'data.'],
    0x45F9: ['$ED xy: duty step. y = duty for the first x ticks of each note; 0 = off.'],
    0x461F: ['$EF x: NR51 bits for this track = swap(x), as in Nemesis (Belmont\'s Revenge',
             'stored raw bits per track). Dropped on music CH1 while the CH1 SFX plays (not',
             'on CH2).'],
    0x4650: ['NR51 bits each track keeps when it pans (the others come from the argument).'],
    0x4657: ['AutoPan: swap the halves of this track\'s NR51 bits (every track, no blocking).'],
    0x4679: ['$E1-$E6: octave (also the look-ahead octave TRK_GLOCTAVE).'],
    0x4686: ['$E0 unit [voice] [env/gate]: drum track unit only, noise SFX one byte -> NR42',
             '+ retrigger, others vol/duty (+ WriteDuty) and env/gate.'],
    0x4716: ['Note: length = (lo nibble) * unit; hi 0 = rest; drum track plays a sound.'],
    0x47E0: ['GlideSetup: TRK_GLPERIOD = the new period. With TF_GLIDE, read ahead (following',
             'calls, returns, loops and jumps, and writing TRK_SEGNO/TRK_RET on the way, with',
             'its own loop counter TRK_GLLOOPCNT) to the next note, whose period is the target.',
             'An $FF ahead turns TF_GLIDE off. The glide starts TRK_GLLEN units before the',
             'note ends; TRK_GLSTEP/TRK_GLRELOAD are set so it covers the distance in that time.'],
    0x496C: ['NoteVolume: NRx2 for a note-on = (vol - atten - wFadeLevel) << 4, floored at 0',
             '(CH3: level code from vol/2 + atten + wFadeLevel/2, NR30 on).'],
    0x49BD: ['VibratoStep: $FB loop point, $FE n repeat, $FF hold, else step. The negate',
             'flag is now set or cleared by every step.'],
    0x4A28: ['WritePeriod: NRx3/NRx4 = period + vibrato offset (negated if TF_VIBNEG).'],
    0x4A6B: ['Rest: NRx2 = 0 only.'],
    0x4A7E: ['DrumNote: start sound DrumMap[hi - 1] at once.'],
    0x4A90: ['WriteDuty: NRx1 = duty << 4, or on CH3 copy wave (duty-1) into wave RAM.'],
    0x4ABE: ['IsBlocked: carry = music CH1 with the CH1 SFX active, or music CH2 with the',
             'CH2 SFX active.'],
    0x4AD9: ['WriteReg: [FF10 + wRegBase + wRegIdx] = wRegVal via the shadow (wShadow).'],
    0x4B42: ['NR register base per track.'],
    0x4B49: ['Sound table: 51 ids ($01-$33). The code indexes it as SoundTable - 2 + 2*id.'],
    0x513B: ['CH3 wave pointers 1-15 (9-11 share a wave).'],
    0x5229: ['Drum map: DRUM n plays sound DrumMap[n-1] (11 entries).'],
    0x5267: ['Vibrato table: 15 entries.'],
    0x4D0C: ['Unreferenced noise stream.'],
    0x6270: ['Unreferenced music subroutines.'],
}

COMMENTS = {}
IMM8 = {}
EXTRA_SYM = {0x2180: 'rROMB', 0x7FFF: 'hBankId', 0x4B47: 'SoundTable - 2'}


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
    0x4B42: (7, 'db', 16),
    0x4B49: (0x33 * 2, 'dw', lambda i: f'${i + 1:02X}'),
    0x513B: (30, 'dw', None),
    0x5159: (13 * 16, 'db', 16),
    0x5229: (11, 'db', 16),
    0x5267: (30, 'dw', lambda i: f'{i + 1}'),
}
