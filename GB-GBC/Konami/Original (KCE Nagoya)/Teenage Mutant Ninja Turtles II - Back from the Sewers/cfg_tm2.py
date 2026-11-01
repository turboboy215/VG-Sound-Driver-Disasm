"""gen_asm3 config: Teenage Mutant Hero Turtles - Back from the Sewers (E)"""
import re
import asmcommon as C

DECODER = 'kdata4'
PREFIX = {0: '', 14: 'B14_', 15: 'B15_'}

TRK = {0x80: 'TRK_PRIO', 0x81: 'TRK_ID', 0x82: 'TRK_PTR', 0x83: 'TRK_PTR + 1', 0x84: 'TRK_LEN',
       0x85: 'TRK_FLAGS', 0x86: 'TRK_PANFLAGS', 0x87: 'TRK_FLOW', 0x88: 'TRK_VIB', 0x8A: 'TRK_DETUNE',
       0x8B: 'TRK_DETUNE + 1', 0x8C: 'TRK_ATTEN', 0x8D: 'TRK_TRANSP', 0x8E: 'TRK_DUTYTICKS',
       0x8F: 'TRK_DUTYCNT', 0x90: 'TRK_SWEEP', 0x91: 'TRK_ED_HI', 0x92: 'TRK_UNIT', 0x93: 'TRK_OCTAVE',
       0x94: 'TRK_PERIOD', 0x95: 'TRK_PERIOD + 1', 0x96: 'TRK_CURPERIOD', 0x97: 'TRK_CURPERIOD + 1',
       0x98: 'TRK_VOL', 0x99: 'TRK_LEVEL', 0x9A: 'TRK_DUTY', 0x9B: 'TRK_CURDUTY', 0x9C: 'TRK_GATE',
       0x9D: 'TRK_RELTICK', 0x9E: 'TRK_ENV', 0x9F: 'TRK_CH3TIMER', 0xA0: 'TRK_PAN', 0xA1: 'TRK_VIBPTR',
       0xA2: 'TRK_VIBPTR + 1', 0xA3: 'TRK_VIBCUR', 0xA4: 'TRK_VIBCUR + 1', 0xA5: 'TRK_VIBTIMER',
       0xA6: 'TRK_VIBDELAY', 0xA7: 'TRK_VIBDELAYCNT', 0xA8: 'TRK_VIBDEPTH', 0xA9: 'TRK_VIBLOOPPTR',
       0xAA: 'TRK_VIBLOOPPTR + 1', 0xAB: 'TRK_VIBLOOPCNT', 0xAC: 'TRK_VIBSEGNO', 0xAD: 'TRK_VIBSEGNO + 1',
       0xB8: 'TRK_LOOPPTR', 0xB9: 'TRK_LOOPPTR + 1', 0xBA: 'TRK_LOOPCNT', 0xBB: 'TRK_LOOP2PTR',
       0xBC: 'TRK_LOOP2PTR + 1', 0xBD: 'TRK_LOOP2CNT', 0xBE: 'TRK_SEGNO', 0xBF: 'TRK_SEGNO + 1',
       0xC0: 'TRK_RET', 0xC1: 'TRK_RET + 1', 0xC2: 'TRK_REG1', 0xC3: 'TRK_REG2', 0xC4: 'TRK_REG3',
       0xC5: 'TRK_REG4'}

RAM = [
    (0xC080, 'wTrkSfx1', 0x46), (0xC180, 'wTrkSfx2', 0x46), (0xC280, 'wTrkSfxN', 0x46),
    (0xC380, 'wTrkCh1', 0x46), (0xC480, 'wTrkCh2', 0x46), (0xC580, 'wTrkCh3', 0x46),
    (0xC680, 'wTrkDrm', 0x46),
    (0xC0CA, 'wTrackDesc', 1), (0xC0CB, 'wMusicSlot', 1), (0xC0CC, 'wTempo', 1), (0xC0CD, 'wTempoAcc', 1),
    (0xC0CE, 'wReqPrio', 1), (0xC0CF, 'wReqId', 1), (0xC0D1, 'wPauseLast', 1), (0xC0D2, 'wFadeTimer', 1),
    (0xC0D3, 'wFadeLevel', 1), (0xC0D4, 'wFadeRate', 1), (0xC0D5, 'wWaveId', 1), (0xC0D6, 'wC0D6', 1),
    (0xC0D8, 'wPcmPtr', 2),
    (0xC78D, 'wSndLock', 1), (0xC794, 'wPauseFlags', 1), (0xC7A7, 'wRomBank', 1), (0xC7BF, 'wRomBankSave', 1),
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

; sound header: priority, track mask (Sfx1, Sfx2 (CH3), SfxN, Ch1, Ch2, Ch3, Drm), one dw per set bit
MACRO SND_HEADER
	db \\1, \\2
ENDM
; note: hi = pitch 1-13 (0 = rest), lo = length multiplier (x unit; 0 = (unit & 15) * 16)
MACRO NOTE
	db (\\1 << 4) | \\2
ENDM
MACRO REST
	db \\1
ENDM
; drum track: hi = sound index 1-13 of this bank, lo = length multiplier
MACRO DRUM
	db (\\1 << 4) | \\2
ENDM
; noise SFX track: NR43 value (no retrigger), length = unit; 0 = rest
MACRO NOISE
	db \\1
ENDM
MACRO NOISE_REST
	db $00
ENDM
; noise SFX track in hold mode: volume (NR42 = vol << 4, retriggered if it changed), NR43
MACRO NOISE_HOLD
	db \\1, \\2
ENDM
; $E0 unit, duty|vol, gate|env (tone/wave tracks; on CH3 duty = wave)
MACRO VOICE
	db $E0, \\1, (\\2 << 4) | \\3, (\\4 << 4) | \\5
ENDM
; $E0 unit, NR42 (noise SFX track)
MACRO NVOICE
	db $E0, \\1, \\2
ENDM
; $E0 unit | $80 on the noise SFX track: hold mode (2-byte notes)
MACRO NVOICE_HOLD
	db $E0, $80 | \\1
ENDM
; $E0 unit | $80, NRx1, NR10 (bank 14 tone/wave tracks): raw frames follow
MACRO RAW_VOICE
	db $E0, $80 | \\1, \\2, \\3
ENDM
; $E0 unit | $80 on a bank 15 tone track: only the unit
MACRO VOICE_FLAG
	db $E0, $80 | \\1
ENDM
; raw frame: NRx2 = vol << 4, NRx3/NRx4 = period, for one unit
MACRO RAW_NOTE
	db (\\1 << 4) | HIGH(\\2), LOW(\\2)
ENDM
MACRO RAW_REST
	db $00
ENDM
; $E1-$E6: octave
MACRO OCTAVE
	db $E0 | \\1
ENDM
MACRO LEN_UNIT
	db $E7, \\1
ENDM
; $E8: gate (release point = length * gate / 16), env (NRx2 low nibble at the release; 0 = cut)
MACRO RELEASE
	db $E8, (\\1 << 4) | \\2
ENDM
; $E9: NR10 (written at once)
MACRO SWEEP
	db $E9, \\1
ENDM
; $EA xy
MACRO DUTY
	db $EA, $00 | \\1
ENDM
MACRO WAVE
	db $EA, $00 | \\1
ENDM
MACRO PAN_BOTH
	db $EA, $10 | \\1
ENDM
MACRO PAN_RIGHT
	db $EA, $20 | \\1
ENDM
MACRO PAN_LEFT
	db $EA, $30 | \\1
ENDM
MACRO AUTOPAN_R
	db $EA, $40 | \\1
ENDM
MACRO AUTOPAN_L
	db $EA, $50 | \\1
ENDM
MACRO AUTOPAN_OFF
	db $EA, $60 | \\1
ENDM
MACRO TRANSPOSE_UP
	db $EA, $70 | \\1
ENDM
MACRO TRANSPOSE_DOWN
	db $EA, $80 | \\1
ENDM
; $EB n, xy: vibrato table n & $7F, delay x * unit ticks, depth y (0 = 1)
MACRO VIBRATO
	db $EB, \\1, (\\2 << 4) | \\3
ENDM
MACRO VIBRATO_OFF
	db $EB, $00
ENDM
MACRO CMD_EC
	db $EC, \\1
ENDM
; $ED x: TRK_SWEEP = TRK_DUTYCNT = x & 15, TRK_ED_HI = x & $F0 (see the doc)
MACRO CMD_ED
	db $ED, \\1
ENDM
; $EE: tempo
MACRO TEMPO
	db $EE, \\1
ENDM
; $EF: signed period offset
MACRO DETUNE
	db $EF, \\1
ENDM
MACRO ATTEN
	db $F0 | \\1
ENDM
; $F8 x / $F9 x: TRK_VOL = swap(x)
MACRO VOLUME
	db $F8, \\1
ENDM
MACRO VOLUME_F9
	db $F9, \\1
ENDM
MACRO SND_JUMP
	db $FA
	dw \\1
ENDM
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
MACRO SND_CALL
	db $FD
	dw \\1
ENDM
MACRO SND_RET
	db $FD
ENDM
MACRO SND_SEGNO
	db $FE
ENDM
MACRO SND_LOOP
	db $FE
ENDM
MACRO SND_END
	db $FF
ENDM
; vibrato tables: one byte per step: time << 4 | negative << 3 | offset (x depth); $FB loop, $FE mark, $FF end
MACRO VIB_STEP
	db (\\1 << 4) | (\\2 << 3) | \\3
ENDM
MACRO VIB_LOOP_START
	db $FB
ENDM
MACRO VIB_LOOP_END
	db $FB, \\1
ENDM
MACRO VIB_MARK
	db $FE
ENDM
MACRO VIB_END
	db $FF
ENDM
"""

HEADER = [
    '; ==========================================================================',
    '; Teenage Mutant Hero Turtles - Back from the Sewers (E) - Konami sound driver (fourth GB version)',
    '; Byte-exact RGBDS disassembly of the driver code and all sound data.',
    ';   ROM0: sound init at boot, timer ISR, PlaySoundFar, bank helpers, PlaySound/update ($04D2-$07C7)',
    ';   bank 14: track code, StopAll, tables, SFX/jingles, the PCM player and 4 PCM samples',
    ';   bank 15: track code (no raw frames), tables, drum hits, music',
    '; Build: rgbasm -Wall -o tm2.o TM2_SoundDriver.asm && rgblink -o tm2.gb tm2.o',
    '; ==========================================================================',
    '',
] + C.HW_EQU.splitlines() + ['DEF rP1 EQU $FF00', ''] + C.ram_equ(RAM) + [
    'DEF rROMB EQU $2000 ; MBC1 bank select',
    '',
] + _trkequ + [
    '',
    '; TRK_FLAGS: 0 rest, 1 raw frames, 2 retrigger long notes, 3 noise hold, 4 tempo skip, 5 reload duty',
    '; TRK_PANFLAGS: 0 autopan, 1 autopan side, 2 vibrato running',
    '; TRK_FLOW: 0/1 loop open, 2 in a call, 3 mark set, 4 vibrato loop open, 5 vibrato mark set',
    '; track descriptors (wTrackDesc): hi = track, lo = channel: Ch1 $00, Ch2 $11, Ch3 $22, Drm $34,',
    '; Sfx1 $40, Sfx2 $52 (CH3), SfxN $63',
    '',
] + MACROS.splitlines()

SEG = [
    (0, 0x0050, 0x0052, 'code', {'section': 'SECTION "Timer vector", ROM0[$0050]'}),
    (0, 0x00A1, 0x00BC, 'code', {'section': 'SECTION "Timer ISR", ROM0[$00A1]'}),
    (0, 0x0168, 0x0196, 'code', {'section': 'SECTION "Sound init", ROM0[$0168]'}),
    (0, 0x021A, 0x0224, 'code', {'section': 'SECTION "SetRegAddrs", ROM0[$021A]'}),
    (0, 0x029A, 0x0349, 'code', {'section': 'SECTION "PlaySoundFar", ROM0[$029A]'}),
    (0, 0x04D2, 0x0658, 'code', {'section': 'SECTION "Sound ROM0", ROM0[$04D2]'}),
    (0, 0x0659, 0x0660, 'dw', None),
    (0, 0x0661, 0x07C7, 'code', None),
    (14, 0x4000, 0x437E, 'code', {'section': 'SECTION "Sound bank 14", ROMX[$4000], BANK[14]'}),
    (14, 0x437F, 0x43B0, 'dw', None),
    (14, 0x43B1, 0x43BE, 'code', None),
    (14, 0x43BF, 0x43F0, 'dw', None),
    (14, 0x43F1, 0x447C, 'code', None),
    (14, 0x447D, 0x4482, 'db', {}),
    (14, 0x4483, 0x44B4, 'code', None),
    (14, 0x44B5, 0x44C6, 'dw', None),
    (14, 0x44C7, 0x48BD, 'code', None),
    (14, 0x48BE, 0x698F, 'data', None),
    (14, 0x6990, 0x6A09, 'code', None),
    (14, 0x6A0A, 0x7FFF, 'data', None),
    (15, 0x4000, 0x4345, 'code', {'section': 'SECTION "Sound bank 15", ROMX[$4000], BANK[15]'}),
    (15, 0x4346, 0x4377, 'dw', None),
    (15, 0x4378, 0x43E2, 'code', None),
    (15, 0x43E3, 0x43E8, 'db', {}),
    (15, 0x43E9, 0x4416, 'code', None),
    (15, 0x4417, 0x4428, 'dw', None),
    (15, 0x4429, 0x47D6, 'code', None),
    (15, 0x47D7, 0x7FFF, 'data', None),
]
SEGMENTS = SEG

BANKNAMES = {
    14: {
        0x4000: 'TrackTick', 0x4012: 'TrackCount', 0x401D: 'ReadCmds', 0x411D: 'Sustain',
        0x416B: 'SustainRelease', 0x418D: 'ReleasePoint', 0x41AC: 'Ch3Release', 0x41C7: 'Ch3Decay',
        0x41DC: 'VibratoStep', 0x422B: 'VibBase', 0x4231: 'VibEnd', 0x423B: 'VibLoop',
        0x4269: 'VibMark', 0x4283: 'Rest', 0x428B: 'DrumNote', 0x42B7: 'StartDrumTrack',
        0x42FF: 'SkipDrumTrack', 0x4302: 'RawNoteBack', 0x4303: 'RawNote', 0x4323: 'NoiseNote',
        0x433E: 'NoiseNoteHold', 0x4364: 'Command', 0x43B1: 'CommandRaw', 0x43F1: 'Cmd_Voice',
        0x4412: 'VoiceTone', 0x443F: 'VoiceFlag', 0x444C: 'VoiceRaw', 0x4469: 'RawAtten',
        0x446D: 'Cmd_Octave', 0x4483: 'Cmd_LenUnit', 0x448B: 'Cmd_Release', 0x449D: 'Cmd_Sweep',
        0x44A9: 'Cmd_Ext', 0x44C7: 'Ext_Duty', 0x44D6: 'Ext_PanBoth', 0x44DE: 'PanBoth',
        0x44F9: 'Ext_PanRight', 0x4501: 'Ext_PanLeft', 0x4509: 'AutoPan', 0x4515: 'PanRight',
        0x4536: 'PanLeft', 0x4557: 'Ext_AutopanR', 0x4562: 'Ext_AutopanL', 0x456D: 'Ext_AutopanOff',
        0x4579: 'Ext_TransposeUp', 0x4584: 'Ext_TransposeDown', 0x4594: 'Cmd_Vibrato', 0x45DC: 'Cmd_EC',
        0x45E1: 'Cmd_ED', 0x45F7: 'Cmd_Tempo', 0x4603: 'Cmd_Detune', 0x4615: 'Cmd_Atten',
        0x4623: 'Cmd_Volume', 0x4648: 'Cmd_Jump', 0x4651: 'Cmd_Loop', 0x467E: 'Cmd_Loop2',
        0x46AB: 'Cmd_Call', 0x46CD: 'Cmd_Segno', 0x46E7: 'Cmd_End', 0x4711: 'EndSfx1',
        0x4728: 'EndSfx2', 0x473A: 'SavePtr', 0x4741: 'RestoreMusic', 0x4767: 'LoadPtrIndexed',
        0x4773: 'WritePeriod', 0x4789: 'Silence', 0x47A3: 'SilenceCh3', 0x47A9: 'WriteVolume',
        0x47C5: 'WriteVolumeTrigger', 0x47DC: 'WriteNoiseVolume', 0x47ED: 'WriteDuty', 0x4802: 'LoadWave',
        0x484C: 'WriteRegChecked',
    },
    15: {
        0x4000: 'TrackTick', 0x4012: 'TrackCount', 0x401D: 'ReadCmds', 0x410F: 'Sustain',
        0x4158: 'SustainRelease', 0x417A: 'ReleasePoint', 0x4199: 'Ch3Release', 0x41B4: 'Ch3Decay',
        0x41C9: 'VibratoStep', 0x4218: 'VibBase', 0x421E: 'VibEnd', 0x4228: 'VibLoop',
        0x4256: 'VibMark', 0x4270: 'Rest', 0x4278: 'DrumNote', 0x42A4: 'StartDrumTrack',
        0x42EE: 'SkipDrumTrack', 0x42F1: 'NoiseNote', 0x430C: 'NoiseNoteHold', 0x4332: 'Command',
        0x4338: 'CommandRaw', 0x4378: 'Cmd_Voice', 0x4399: 'VoiceTone', 0x43C6: 'VoiceFlag',
        0x43D3: 'Cmd_Octave', 0x43E9: 'Cmd_LenUnit', 0x43F1: 'Cmd_Release', 0x4403: 'Cmd_Sweep',
        0x440B: 'Cmd_Ext', 0x4429: 'Ext_Duty', 0x4438: 'Ext_PanBoth', 0x4440: 'PanBoth',
        0x445B: 'Ext_PanRight', 0x4463: 'Ext_PanLeft', 0x446B: 'AutoPan', 0x4477: 'PanRight',
        0x4499: 'PanLeft', 0x44BA: 'Ext_AutopanR', 0x44C5: 'Ext_AutopanL', 0x44D0: 'Ext_AutopanOff',
        0x44DC: 'Ext_TransposeUp', 0x44E7: 'Ext_TransposeDown', 0x44F7: 'Cmd_Vibrato', 0x453F: 'Cmd_EC',
        0x4544: 'Cmd_ED', 0x455A: 'Cmd_Tempo', 0x4566: 'Cmd_Detune', 0x4578: 'Cmd_Atten',
        0x4586: 'Cmd_Volume', 0x45AB: 'Cmd_Jump', 0x45B4: 'Cmd_Loop', 0x45E1: 'Cmd_Loop2',
        0x460E: 'Cmd_Call', 0x4630: 'Cmd_Segno', 0x464A: 'Cmd_End', 0x466E: 'EndSfx1',
        0x4685: 'EndSfx2', 0x4697: 'SavePtr', 0x469E: 'RestoreMusic', 0x46C4: 'LoadPtrIndexed',
        0x46D0: 'WritePeriod', 0x46E6: 'Silence', 0x4700: 'SilenceCh3', 0x4706: 'WriteVolume',
        0x4724: 'WriteVolumeTrigger', 0x473B: 'WriteNoiseVolume', 0x474C: 'WriteDuty', 0x4761: 'LoadWave',
        0x47AB: 'WriteRegChecked',
    },
}

NAMES = {
    (0, 0x0050): 'TimerVector', (0, 0x00A1): 'TimerISR', (0, 0x0168): 'SoundInit', (0, 0x021A): 'SetRegAddrs',
    (0, 0x029A): 'PlaySoundFar', (0, 0x029D): 'PlaySoundFarChecked', (0, 0x02F7): 'SetBank1', (0, 0x02FA): 'SetBankA',
    (0, 0x0340): 'SetBank14',
    (0, 0x04D2): 'PlaySound', (0, 0x04E1): 'PlayPcmVoice', (0, 0x0520): 'PlaySoundTable', (0, 0x05BB): 'StartMusicTrack',
    (0, 0x05C3): 'StartTrackData', (0, 0x05E1): 'CheckSfxPrio', (0, 0x05E6): 'StartSfxTrack', (0, 0x0610): 'SndUpdate',
    (0, 0x0622): 'SndUpdateMusic', (0, 0x0636): 'SndUpdateSfx', (0, 0x0652): 'MusicSlot', (0, 0x0659): 'MusicSlotTable',
    (0, 0x0661): 'MusicSlotCh1', (0, 0x066F): 'MusicSlotCh2', (0, 0x0676): 'MusicSlotCh3', (0, 0x067D): 'MusicSlotDrm',
    (0, 0x0681): 'RunTrack', (0, 0x069E): 'PauseEdge', (0, 0x06BD): 'UnpauseRestore', (0, 0x0727): 'TempoTick',
    (0, 0x0754): 'FadeTick', (0, 0x07B4): 'FadeStopDrums', (0, 0x07BC): 'LoadPtrIndexed0',
    (14, 0x437F): 'B14_CommandTable', (14, 0x43BF): 'B14_CommandTableRaw', (14, 0x447D): 'B14_OctaveTable',
    (14, 0x44B5): 'B14_ExtTable', (14, 0x4878): 'B14_StopAll', (14, 0x48BE): 'B14_PeriodTable',
    (14, 0x4968): 'B14_WaveTable', (14, 0x49C8): 'B14_SoundTable', (14, 0x4E71): 'B14_VibratoTable',
    (14, 0x6990): 'B14_PlayPcm', (14, 0x69CD): 'B14_PcmByte', (14, 0x69D9): 'B14_PcmBit', (14, 0x6A00): 'B14_PcmEnd',
    (14, 0x6A0A): 'B14_PcmWave', (14, 0x6A1A): 'PcmSample9A', (14, 0x6FFB): 'PcmSample9B', (14, 0x74DC): 'PcmSample9C',
    (14, 0x77ED): 'PcmSample9D', (14, 0x7FD3): 'B14_BankEnd',
    (15, 0x4346): 'B15_CommandTable', (15, 0x43E3): 'B15_OctaveTable', (15, 0x4417): 'B15_ExtTable',
    (15, 0x47D7): 'B15_PeriodTable', (15, 0x4867): 'B15_WaveTable', (15, 0x4975): 'B15_SoundTable',
    (15, 0x4C2D): 'B15_VibratoTable', (15, 0x7FD1): 'B15_BankEnd',
}
for _b, _d in BANKNAMES.items():
    for _a, _n in _d.items(): NAMES[(_b, _a)] = PREFIX[_b] + _n
for _i, _a in enumerate((0x498A, 0x499A, 0x49AA, 0x49BA)): NAMES[(14, _a)] = f'B14_WaveData{_i + 1}'
for _i in range(15): NAMES[(15, 0x4887 + 16 * _i)] = f'B15_WaveData{_i + 1}'

XREF = {(0, 0x04DE): 14, (0, 0x051A): 14, (0, 0x0693): 14, (0, 0x069B): 15}

DATA_SPECIAL = {
    14: {0x48BE: (170, 'period', None), 0x4968: (34, 'dw', None), 0x498A: (62, 'db', 16),
         0x49CA: (0x9E * 2, 'dw', lambda i: f'${i + 1:02X}'), 0x4E71: (4, 'dw', lambda i: f'{i + 1}'),
         0x6A0A: (16, 'db', 16), 0x6A1A: (0x7FD3 - 0x6A1A, 'db', 16), 0x7FD3: (45, 'db', 16)},
    15: {0x47D7: (144, 'period', None), 0x4867: (32, 'dw', None), 0x4887: (240, 'db', 16),
         0x4977: (0x33 * 2, 'dw', lambda i: f'${0xC1 + i:02X}'), 0x4C2D: (28, 'dw', lambda i: f'{i + 1}'),
         0x7FD1: (47, 'db', 16)},
}

BLOCKS = {
    (0, 0x0050): ['Timer interrupt (TMA $C0, 16384 Hz -> 256 Hz); interrupts are enabled at once.'],
    (0, 0x00A1): ['TimerISR: one driver update unless wSndLock bit 0 (update running) or bit 1',
                  '(PlaySoundFar running) is set.'],
    (0, 0x0168): ['Part of the boot code: NR50 = $77, NR51 = $FF, NR52 = $80, and the register',
                  'address fields TRK_REG1-4 of the six tracks with a channel (the drum track has',
                  'none, so they stay 0 = rP1).'],
    (0, 0x029A): ['PlaySoundFar: A = sound id. PlaySoundFarChecked drops the request in one game',
                  'state ([$C788] = 6, [$CB80] = 1, [$C7B3] = 0). wSndLock bit 1 is set around',
                  'PlaySound; the caller\'s bank is restored afterwards.'],
    (0, 0x04D2): ['PlaySound: 0 = StopAll (bank 14). $9A-$9D: PCM voice (bank 14, blocking, interrupts',
                  'off). Else the header from bank 14 (id < $C0, index id) or bank 15 (index id - $C0).',
                  'If any SFX track of the mask holds a higher priority, nothing is started at all.',
                  'Music needs the Ch1 bit and a priority >= Ch1\'s; it resets tempo, fade and the',
                  'music slot, and starts Ch2/Ch3/Drm without a priority test.'],
    (0, 0x05C3): ['Track start: TRK_LEN = 1, TRK_FLAGS..TRK_SWEEP = 0, wWaveId = 0, NRx2 = 0 on the',
                  'track\'s channel (on the drum track: rP1 = 0).'],
    (0, 0x0610): ['SndUpdate (256 Hz): pause edges, then one music track per update in turn (Ch1, Ch2,',
                  'Ch3, Drm; fade and tempo before Ch1), then SfxN, Sfx2, Sfx1. Each runs in the',
                  'bank its id came from (>= $C0: 15).'],
    (0, 0x069E): ['Pause: stop SfxN, mute CH4 and CH2. Unpause: stop all SFX, mute CH1/CH4, NR32 = 0,',
                  'give CH1 and CH3 back to the music (NR51 bits, period) and mark Ch1-Ch3 for a',
                  'retrigger on long notes.'],
    (0, 0x0727): ['TempoTick: wTempoAcc += wTempo once per four updates; a carry sets TRK_FLAGS bit 4',
                  'on all four music tracks, so each skips its next tick.'],
    (0, 0x0754): ['FadeTick: the game sets wFadeRate. Every wFadeRate calls wFadeLevel += $10 (taken',
                  'off new notes); at $40 the drums stop, at $70 all music stops and the fade ends.'],
    (14, 0x4000): ['TrackTick: one tick for track H with descriptor wTrackDesc.'],
    (14, 0x401D): ['ReadCmds. Notes: length = lo * unit (lo = 0: (unit & 15) * 16), release tick =',
                   'length * gate / 16. The note-on volume is TRK_VOL - TRK_ATTEN - wFadeLevel, but only',
                   'the second subtraction\'s borrow is tested (a large TRK_ATTEN wraps to loud).'],
    (14, 0x411D): ['Sustain: duty restore (never active: nothing sets TRK_DUTYTICKS), vibrato, the',
                   'release (NRx2 = TRK_ENV | level + retrigger; env 0 = cut), CH3 decay one level',
                   'every TRK_ENV ticks, and the retrigger of a long note (>= 128 ticks left) after an',
                   'SFX gave the channel back.'],
    (14, 0x41DC): ['VibratoStep: one byte per step: time << 4 | negative << 3 | offset, offset x depth',
                   'added to TRK_PERIOD. $FB loop markers, $FE mark/jump, $FF ends the vibrato.'],
    (14, 0x428B): ['DrumNote: start sound (hi nibble) of this bank on the SFX tracks it uses, each with',
                   'its own priority test. In bank 14 all 13 drum sounds are an empty stream.'],
    (14, 0x4364): ['Command: $E0 voice; in raw mode $E1-$E6 and $F0-$F7 are raw frames; $E1-$E6 octave;',
                   '$E7-$FF through the table (the argument byte in A, DE pointing at it).'],
    (14, 0x4594): ['$EB n xy: vibrato table n & $7F. Bank 14 has only entries 1 and 2: song $41 uses',
                   '$8A, whose pointer ($E0FE) reads echo RAM.'],
    (14, 0x45E1): ['$ED x: TRK_ED_HI = x & $F0, TRK_SWEEP = TRK_DUTYCNT = x & 15; with 0 the duty is',
                   'rewritten. In bank 14 a non-zero TRK_SWEEP is written to NR10 at every note-on.'],
    (14, 0x46E7): ['$FF: end. Sfx1/Sfx2 ending give CH1/CH3 back to the music; id $9E only silences.'],
    (14, 0x47A9): ['WriteVolume: NRx2 = A, compared with what the register reads back: unchanged means',
                   'no write and no retrigger (except on CH1 while TRK_SWEEP is not 8). CH3 is never',
                   'retriggered here.'],
    (14, 0x47ED): ['WriteDuty: NRx1, or on CH3 load wave (A >> 4) unless it is already loaded.'],
    (14, 0x484C): ['WriteRegChecked: music Ch1 is blocked while Sfx1 plays and music Ch3 while Sfx2',
                   'plays; carry = written.'],
    (14, 0x4878): ['StopAll: clear all tracks\' priority/id, mute every channel, NR51 = $FF.'],
    (14, 0x48BE): ['Periods from C of octave 1 (TRK_OCTAVE + 2 * pitch indexes from $48A4).'],
    (14, 0x4968): ['CH3 wave pointers by duty >> 4 (entry 0 is the last period; 14-15 point into the',
                   'sound table).'],
    (14, 0x6990): ['PlayPcm: 1-bit PCM. CH3 plays a fixed wave at the lowest frequency and every sample',
                   'bit (LSB first) sets NR32 to 100% or mute, ~10.5 kHz, with interrupts off, until a',
                   '$DD byte.'],
}

COMMENTS = {}
EXTRA_SYM = {'all': {0x2000: 'rROMB'}, 14: {0x48A4: 'B14_PeriodTable - 26', 0x4E6F: 'B14_VibratoTable - 2',
                                             0x447C: 'B14_OctaveTable - 1'},
             15: {0x47BD: 'B15_PeriodTable - 26', 0x4C2B: 'B15_VibratoTable - 2', 0x43E2: 'B15_OctaveTable - 1'}}
EXTRA_SYM[14][0x4371] = 'B14_CommandTable - 14'
EXTRA_SYM[15][0x4338] = 'B15_CommandTable - 14'


def imm8(b, pc, mn, ops):
    if mn == 'ld':
        m = re.match(r'l,\$([0-9A-F]{2})$', ops)
        if m and int(m.group(1), 16) in TRK: return 'l,' + TRK[int(m.group(1), 16)]
        mh = re.match(r'h,\$(C[0-6])$', ops)
        if mh: return 'h,HIGH(' + ['wTrkSfx1', 'wTrkSfx2', 'wTrkSfxN', 'wTrkCh1', 'wTrkCh2', 'wTrkCh3', 'wTrkDrm'][int(mh.group(1), 16) - 0xC0] + ')'
    return ops


def emit(mac, args, lab):
    if mac in ('SND_CALL', 'SND_JUMP'): return f'\t{mac} {lab(args[0])}'
    if mac in ('NVOICE', 'RAW_VOICE'): return f'\t{mac} ' + ', '.join(f'${a:02X}' for a in args)
    if mac == 'VOICE': return f'\tVOICE ${args[0]:02X}, {args[1]}, {args[2]}, {args[3]}, {args[4]}'
    if mac in ('NVOICE_HOLD', 'VOICE_FLAG', 'NOISE', 'CMD_ED', 'CMD_EC', 'DETUNE', 'VOLUME', 'VOLUME_F9',
               'TEMPO', 'SWEEP'): return f'\t{mac} ${args[0]:02X}'
    if mac == 'NOISE_HOLD': return f'\tNOISE_HOLD {args[0]}, ${args[1]:02X}'
    if mac == 'VIBRATO': return f'\tVIBRATO ${args[0]:02X}, {args[1]}, {args[2]}'
    if mac == 'VIBRATO_OFF': return '\tVIBRATO_OFF'
    return None
