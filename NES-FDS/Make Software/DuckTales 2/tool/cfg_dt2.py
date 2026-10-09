from mkram import RAM
RAM = dict(RAM); del RAM[0xFA]
CODE = {
    0x8000: 'SoundJumpTable', 0x8003: 'Sound_UpdateSfx', 0x800C: 'Sound_Update',
    0x802C: 'Sound_RunChannels', 0x8048: 'Env_Update', 0x8079: 'Env_SetValue', 0x8088: 'Env_NewSegment',
    0x809B: 'Env_Step', 0x80B2: 'Sound_Output', 0x80DD: 'Output_Channel', 0x80ED: 'Output_Done',
    0x8136: 'WriteVolume', 0x815D: 'WritePeriod', 0x819C: 'Out_Sq2Drum',
    0x81CB: 'Sound_Request', 0x8227: 'ResetChannels', 0x8296: 'Chan_Reset', 0x82E1: 'Sound_Start',
    0x8351: 'Track_Update', 0x835C: 'Track_Read', 0x8366: 'Track_NextByte', 0x8389: 'Track_Note',
    0x83C9: 'Track_NoteOn', 0x8446: 'Track_SavePtr', 0x85DF: 'Track_ReadByte',
    0x85EA: 'Stack_PushPtr', 0x85F1: 'Stack_Push', 0x85FB: 'Stack_PopPtr', 0x8606: 'Stack_Pop',
    0x8610: 'Drum_Start', 0x8623: 'Drum_Update', 0x8641: 'Drum_Step', 0x86AE: 'Drum_Stop',
}
cfg = dict(
    title="Duck Tales 2 (E)",
    start=0x8000, end=0xADEE,
    ram=RAM, code_names=CODE,
    entries=[(0x8000, 'SoundJumpTable'), (0x8003, 'Sound_UpdateSfx')],
    out_table=0x80EE, out_names=['Out_Sq1', 'Out_Sq2', 'Out_Tri', 'Out_Noise', 'Out_SfxSq2', 'Out_SfxNoise'],
    req_table=0x81EB, req_names=['Req_Resume', 'Req_Pause', 'Req_7B', 'Req_7C', 'Req_StopMusic', 'Req_StopSfx', 'Sound_Init'],
    cmd_table=0x8455, ret_addr=0x8387,
    small_tables=[(0x80D9, 4, 'OutputSkipMask', 'music channel muted while these sfx bits are set'),
                  (0x82DB, 6, 'StackBase', 'start of each channel\'s 16-byte area in mStack'),
                  (0x85CF, 8, 'ChanBit', None), (0x85D7, 8, 'ChanClearMask', None)],
    period=0x86C0, sounds=0x8768, nsounds=0x5E,
    silent_track=0x8FE3, drums=0x8FE6, ndrums=13, silent_drum=0x9018,
    envs=0x9019, nenvs=51,
    imm_store={0x0766: '<SilentTrack', 0x076C: '>SilentTrack', 0x07EA: '<Drum_Silent', 0x07EB: '>Drum_Silent'},
)
