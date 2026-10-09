from mkram import RAM
CODE = {
    0x8000: 'Sound_Update', 0x8013: 'Sound_RunChannels', 0x803F: 'Env_Update', 0x8070: 'Env_SetValue',
    0x807F: 'Env_NewSegment', 0x8092: 'Env_Step', 0x80A9: 'Sound_Output', 0x80D4: 'Output_Channel',
    0x80E4: 'Output_Done', 0x812D: 'WriteVolume', 0x8154: 'WritePeriod', 0x8193: 'Out_Sq2Drum',
    0x81C2: 'Sound_Fade', 0x81E5: 'Sound_FadeInUnused',
    0x8200: 'Sound_Request', 0x826C: 'ResetChannels', 0x82E3: 'Chan_Reset', 0x832E: 'Sound_Start',
    0x839E: 'Track_Update', 0x83A9: 'Track_Read', 0x83B3: 'Track_NextByte', 0x83D6: 'Track_Note',
    0x8416: 'Track_NoteOn', 0x8493: 'Track_SavePtr', 0x862C: 'Track_ReadByte',
    0x8637: 'Stack_PushPtr', 0x863E: 'Stack_Push', 0x8648: 'Stack_PopPtr', 0x8653: 'Stack_Pop',
    0x865D: 'Drum_Start', 0x8670: 'Drum_Update', 0x868E: 'Drum_Step', 0x86FB: 'Drum_Stop',
}
cfg = dict(
    title="Chip 'n Dale Rescue Rangers 2 (E)",
    start=0x8000, end=0xBEF4,
    ram=RAM, code_names=CODE,
    entries=[(0x8000, 'Sound_Update')],
    out_table=0x80E5, out_names=['Out_Sq1', 'Out_Sq2', 'Out_Tri', 'Out_Noise', 'Out_SfxSq2', 'Out_SfxNoise'],
    req_table=0x8220, req_names=['Req_Resume', 'Req_Pause', 'Req_FadeOut', 'Req_FadeIn', 'Req_StopMusic', 'Req_StopSfx', 'Sound_Init'],
    cmd_table=0x84A2, ret_addr=0x83D4,
    small_tables=[(0x80D0, 4, 'OutputSkipMask', 'music channel muted while these sfx bits are set'),
                  (0x8328, 6, 'StackBase', 'start of each channel\'s 16-byte area in mStack'),
                  (0x861C, 8, 'ChanBit', None), (0x8624, 8, 'ChanClearMask', None)],
    period=0x870D, sounds=0x87B5, nsounds=0x75,
    silent_track=0x9280, drums=0x9283, ndrums=13, silent_drum=0x92B5,
    envs=0x92B6, nenvs=21,
    imm_store={0x0766: '<SilentTrack', 0x076C: '>SilentTrack', 0x07EA: '<Drum_Silent', 0x07EB: '>Drum_Silent'},
    dead_code=[(0x81E5, 'Sound_FadeInUnused')],
)
