CMDS = [('CMD_REST', 'rest'), ('CMD_END', 'end'), ('CMD_CALL', 'call'),
        ('CMD_RETURN', 'ret'), ('CMD_JUMP', 'jump'), ('CMD_DMC_END', 'end'), ('CMD_DMC_REST', 'rest')]

RAM = {
    0x00: 'zPtr', 0x01: 'zPtr+1', 0x02: 'zDurTab', 0x03: 'zDurTab+1',
    0x04: 'zChan', 0x05: 'zRegOfs', 0x06: 'zTemp',
    0x0300: 'mTrkPtrLo', 0x0305: 'mTrkPtrHi', 0x030A: 'mDurTabLo', 0x030B: 'mDurTabHi',
    0x030C: 'mNoteTimer', 0x0310: 'mDmcTimer', 0x0311: 'mVolEnvTimer', 0x0315: 'mVolEnvHi', 0x0319: 'mVolEnvLo',
    0x031D: 'mPitchEnvTimer', 0x0321: 'mPitchEnvHi', 0x0325: 'mPitchEnvLo',
    0x0329: 'mArpEnvTimer', 0x032D: 'mArpEnvHi', 0x0331: 'mArpEnvLo',
    0x0335: 'mInstTemp', 0x0336: 'mTranspose', 0x033B: 'mRetLo', 0x0340: 'mRetHi',
    0x0345: 'mLoopCount', 0x034A: 'mLoopActive', 0x034F: 'mChanFlags', 0x0353: 'mDmcFlags',
    0x0354: 'mRegDirty', 0x0358: 'mDmcDirty',
    0x0359: 'mNote', 0x035D: 'mReg3', 0x0361: 'mReg2', 0x0365: 'mReg0',
    0x0369: 'mDmcFreq', 0x036A: 'mDmcRaw', 0x036B: 'mDmcStart', 0x036C: 'mDmcLen',
    0x036D: 'mApuStatus', 0x036E: 'mCmdVector', 0x036F: 'mCmdVector+1',
    0x0370: 'sPtrHi', 0x0375: 'sPtrLo', 0x037A: 'mChanFlagsSave', 0x037E: 'mDmcFlagsSave',
    0x037F: 'sDmcActive', 0x0380: 'sTimer',
    0x0384: 'sSpeed', 0x0388: 'sId', 0x038C: 'sNewPriority', 0x038D: 'sPriority', 0x0391: 'sDmcPriority',
}

CODE = {
    0x8000: 'SoundJumpTable', 0x800F: 'Music_Play', 0x8029: 'Music_Stop', 0x8052: 'Music_LoadSong',
    0x8106: 'Music_Update', 0x812A: 'Music_UpdateChannel', 0x8136: 'Music_TickNote',
    0x8144: 'Music_ReadEvent', 0x816F: 'Music_Note', 0x8199: 'Music_NoteSetInstrument',
    0x81F2: 'Music_InstNoVolEnv', 0x823A: 'Music_InstVolEnv', 0x828C: 'Music_VolEnvTick',
    0x82D0: 'Music_PitchEnvTick', 0x8329: 'Music_ArpEnvTick', 0x8393: 'Music_Output',
    0x839F: 'WriteChannelRegs', 0x83ED: 'Music_Command', 0x84A8: 'Cmd_ReadNextNow',
    0x84FD: 'AdvanceTrackPtr', 0x8513: 'SilenceChannel',
    0x852C: 'Dmc_UpdateChannel', 0x853E: 'Dmc_ReadEvent', 0x8580: 'Dmc_Note',
    0x85D4: 'Dmc_AdvancePtr', 0x85E6: 'Dmc_Silence', 0x85FB: 'Dmc_Output', 0x8603: 'Dmc_WriteRegs',
    0x96B6: 'Sfx_Init', 0x96E6: 'Sfx_Play', 0x975C: 'Sfx_SetPtr', 0x976C: 'Sfx_PlayDmc',
    0x97C3: 'Sfx_Update', 0x9809: 'Sfx_UpdateChannel', 0x9896: 'Sfx_Stop',
}

cfg = dict(
    title="Joe & Mac - Caveman Ninja (E)",
    start=0x8000, end=0xA000,
    ram=RAM, code_names=CODE,
    entries=[(0x8000, 'SoundJumpTable'), (0x8003, None), (0x8006, None), (0x8009, None), (0x800C, None)],
    cmds=CMDS,
    cmd_handlers=['Cmd_Rest', 'Cmd_End', 'Cmd_Call', 'Cmd_Return', 'Cmd_Jump', 'Cmd_DmcEnd', 'Cmd_DmcRest'],
    cmd_table=dict(lo=0x83E6, hi=0x83DF),
    small_tables=[(0x96A8, 4, 'ChanRegOfs', 'APU register offset per channel'),
                  (0x96AC, 5, 'ChanEnableBit', 'APU_STATUS bit per channel'),
                  (0x96B1, 5, 'ChanDisableMask', 'APU_STATUS mask per channel')],
    period=dict(lo=0x8621, nlo=0x60, hi=0x8681, nhi=0x21),
    instr=dict(lo=0x86C5, hi=0x86D7, n=0x12),
    dmc=dict(lo=0x86A2, hi=0x86A9, n=7),
    songs=dict(lo=0x88E0, hi=0x88B0, n=8, ntracks=5),
    patterns=dict(lo=0x9644, hi=0x9676, n=0x32),
    sfx=dict(lo=0x98D2, hi=0x98BA, n=0x18),
    sfx_format='jm',
    has_arp=True,
)
cfg['dead_code'] = [(0x84F6, 'Unused_SetTimerAndAdvance'), (0x85CF, 'Unused_DmcSetTimerAndAdvance'), (0x9779, 'Unused_PullReturn')]
cfg['orphans'] = [('env', 0x885A, 0x88B0), ('durtab', 0x8910, 0x8920), ('durtab', 0x8930, 0x8970)]
cfg['linec'] = {0x84F3: 'also reached from the DMC track (see header)'}
cfg['comments'] = {'Music_Play': ['Start song A. $81 = re-enable all channels (resume), $80/$82+ = stop.']}
