CMDS = [('CMD_REST', 'rest'), ('CMD_END', 'end'), ('CMD_CALL', 'call'),
        ('CMD_RETURN', 'ret'), ('CMD_JUMP', 'jump')]

RAM = {
    0x00: 'zPtr', 0x01: 'zPtr+1', 0x02: 'zDurTab', 0x03: 'zDurTab+1',
    0x04: 'zChan', 0x05: 'zRegOfs', 0x06: 'zTemp',
    0x0781: 'mTrkPtrLo', 0x0785: 'mTrkPtrHi', 0x0789: 'mDurTabLo', 0x078A: 'mDurTabHi',
    0x078B: 'mNoteTimer', 0x078F: 'mVolEnvTimer', 0x0793: 'mVolEnvHi', 0x0797: 'mVolEnvLo',
    0x079B: 'mPitchEnvTimer', 0x079F: 'mPitchEnvHi', 0x07A3: 'mPitchEnvLo',
    0x07A7: 'mArpEnvTimer', 0x07AB: 'mArpEnvHi', 0x07AF: 'mArpEnvLo',
    0x07B3: 'mInstTemp', 0x07B4: 'mTranspose', 0x07B8: 'mRetLo', 0x07BC: 'mRetHi',
    0x07C0: 'mLoopCount', 0x07C4: 'mLoopActive', 0x07C8: 'mChanFlags', 0x07CC: 'mRegDirty',
    0x07D0: 'mNote', 0x07D4: 'mReg3', 0x07D8: 'mReg2', 0x07DC: 'mReg0',
    0x07E0: 'mApuStatus', 0x07E1: 'mCmdVector', 0x07E2: 'mCmdVector+1',
    0x07E3: 'sPtrHi', 0x07E7: 'sPtrLo', 0x07EB: 'mChanFlagsSave', 0x07EF: 'sTimer',
    0x07F3: 'sSpeed', 0x07F7: 'sId', 0x07FB: 'sNewPriority', 0x07FC: 'sPriority',
}

CODE = {
    0x8000: 'SoundJumpTable', 0x800F: 'Music_Play', 0x8036: 'Music_LoadSong',
    0x80CF: 'Music_Update', 0x80EC: 'Music_UpdateChannel', 0x80F8: 'Music_TickNote',
    0x8106: 'Music_ReadEvent', 0x8131: 'Music_Note', 0x815B: 'Music_NoteSetInstrument',
    0x81B4: 'Music_InstNoVolEnv', 0x81FC: 'Music_InstVolEnv', 0x824E: 'Music_VolEnvTick',
    0x8292: 'Music_PitchEnvTick', 0x82EB: 'Music_ArpEnvTick', 0x8355: 'Music_Output',
    0x8361: 'WriteChannelRegs', 0x83AB: 'Music_Command', 0x8466: 'Cmd_ReadNextNow',
    0x8492: 'AdvanceTrackPtr', 0x84A8: 'SilenceChannel',
    0x95FE: 'Sfx_Init', 0x9628: 'Sfx_Play', 0x96AA: 'Sfx_Update', 0x96BF: 'Sfx_UpdateChannel',
    0x9699: 'Sfx_SetPtr', 0x974C: 'Sfx_Stop',
}

cfg = dict(
    title="Dragon's Lair (E)",
    start=0x8000, end=0xA029,
    ram=RAM, code_names=CODE,
    entries=[(0x8000, 'SoundJumpTable'), (0x8003, None), (0x8006, None), (0x8009, None), (0x800C, None)],
    cmds=CMDS,
    cmd_handlers=['Cmd_Rest', 'Cmd_End', 'Cmd_Call', 'Cmd_Return', 'Cmd_Jump'],
    cmd_table=dict(lo=0x83A6, hi=0x83A1),
    small_tables=[(0x95F0, 4, 'ChanRegOfs', 'APU register offset per channel'),
                  (0x95F4, 5, 'ChanEnableBit', 'APU_STATUS bit per channel'),
                  (0x95F9, 5, 'ChanDisableMask', 'APU_STATUS mask per channel')],
    period=dict(lo=0x84C1, nlo=0x60, hi=0x8521, nhi=0x21),
    instr=dict(lo=0x8542, hi=0x8559, n=0x17),
    songs=dict(lo=0x87CA, hi=0x879D, n=9, ntracks=4),
    patterns=dict(lo=0x9594, hi=0x95C2, n=0x2E),
    sfx=dict(lo=0x97A5, hi=0x9776, n=0x2F),
    sfx_format='dl',
    has_arp=True,
)
cfg['dead_code'] = [(0x848B, 'Unused_SetTimerAndAdvance')]
cfg['linec'] = {0x96A9: 'BUG: returns with X still pushed'}
