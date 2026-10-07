CMDS = [('CMD_REST', 'rest'), ('CMD_END', 'end'), ('CMD_CALL', 'call'),
        ('CMD_RETURN', 'ret'), ('CMD_JUMP', 'jump'), ('CMD_DURTABLE', 'durtab')]

RAM = {
    0xF6: 'zPtr', 0xF7: 'zPtr+1', 0xF8: 'zDurTab', 0xF9: 'zDurTab+1',
    0xFA: 'zChan', 0xFB: 'zRegOfs', 0xFC: 'zTemp',
    0x013E: 'mTrkPtrLo', 0x0143: 'mTrkPtrHi', 0x0148: 'mDurTabLo', 0x0149: 'mDurTabHi',
    0x014A: 'mNoteTimer', 0x014F: 'mVolEnvTimer', 0x0153: 'mVolEnvHi', 0x0157: 'mVolEnvLo',
    0x015B: 'mPitchEnvTimer', 0x015F: 'mPitchEnvHi', 0x0163: 'mPitchEnvLo',
    0x0168: 'mInstTemp', 0x0169: 'mTranspose', 0x016E: 'mRetLo', 0x0173: 'mRetHi',
    0x0178: 'mLoopCount', 0x017D: 'mLoopActive', 0x0182: 'mChanFlags', 0x0187: 'mRegDirty',
    0x018C: 'mNote', 0x0190: 'mReg3', 0x0194: 'mReg2', 0x0198: 'mReg0',
    0x019C: 'mApuStatus', 0x019D: 'mCmdVector', 0x019E: 'mCmdVector+1',
    0x019F: 'sPtrHi', 0x01A4: 'sPtrLo', 0x01A9: 'mChanFlagsSave', 0x01AF: 'sTimer',
    0x01B3: 'sSpeed', 0x01B7: 'sId', 0x01BB: 'sNewPriority', 0x01BC: 'sPriority',
    0x01C0: 'mTempo', 0x01C1: 'mTempoAcc',
}

CODE = {
    0xD05B: 'SoundJumpTable', 0xD06A: 'Music_Play', 0xD091: 'Music_LoadSong',
    0xD134: 'Music_Update', 0xD140: 'Music_UpdateAll', 0xD15D: 'Music_UpdateChannel', 0xD169: 'Music_TickNote',
    0xD177: 'Music_ReadEvent', 0xD1A2: 'Music_Note', 0xD1CC: 'Music_NoteSetInstrument',
    0xD225: 'Music_InstNoVolEnv', 0xD264: 'Music_InstVolEnv', 0xD2AD: 'Music_VolEnvTick',
    0xD2F1: 'Music_PitchEnvTick', 0xD34A: 'Music_Output',
    0xD356: 'WriteChannelRegs', 0xD3A2: 'Music_Command', 0xD45D: 'Cmd_ReadNextNow',
    0xD496: 'AdvanceTrackPtr', 0xD4AC: 'SilenceChannel',
    0xE94C: 'Sfx_Init', 0xE976: 'Sfx_Play', 0xE9E7: 'Sfx_SetPtr',
    0xE9F8: 'Sfx_Update', 0xEA0D: 'Sfx_UpdateChannel', 0xEAA2: 'Sfx_Stop',
}

cfg = dict(
    title="Aladdin (E)",
    start=0xD05B, end=0xF000,
    ram=RAM, code_names=CODE,
    entries=[(0xD05B, 'SoundJumpTable'), (0xD05E, None), (0xD061, None), (0xD064, None), (0xD067, None)],
    cmds=CMDS,
    cmd_handlers=['Cmd_Rest', 'Cmd_End', 'Cmd_Call', 'Cmd_Return', 'Cmd_Jump', 'Cmd_SetDurTable'],
    cmd_table=dict(lo=0xD39C, hi=0xD396),
    small_tables=[(0xE93E, 4, 'ChanRegOfs', 'APU register offset per channel'),
                  (0xE942, 5, 'ChanEnableBit', 'APU_STATUS bit per channel'),
                  (0xE947, 5, 'ChanDisableMask', 'APU_STATUS mask per channel')],
    period=dict(lo=0xD4C5, nlo=0x60, hi=0xD525, nhi=0x21),
    instr=dict(lo=0xD546, hi=0xD556, n=0x10),
    songs=dict(lo=0xD72F, hi=0xD716, n=5, ntracks=4),
    patterns=dict(lo=0xE90A, hi=0xE924, n=0x1A),
    sfx=dict(lo=0xEAF2, hi=0xEAC9, n=0x29),
    sfx_format='al',
    has_arp=False,
)
cfg['end'] = 0xEFDA
cfg['orphans'] = [('env', 0xD604, 0xD700), ('durtab', 0xD748, 0xD758), ('durtab', 0xD768, 0xD798)]
cfg['linec'] = {0xE9F7: 'BUG: returns with X still pushed', 0xEAAB: 'result discarded (no STA)',
                0xD137: 'no CLC before this ADC'}
